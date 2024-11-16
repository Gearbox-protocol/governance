// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {AccountFactoryV3} from "@gearbox-protocol/core-v3/contracts/core/AccountFactoryV3.sol";
import {BotListV3} from "@gearbox-protocol/core-v3/contracts/core/BotListV3.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ICreditFactory} from "../interfaces/ICreditFactory.sol";

import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {IPoolV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPoolV3.sol";

import {ICreditManagerV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import {CreditManagerV3} from "@gearbox-protocol/core-v3/contracts/credit/CreditManagerV3.sol";
import {ICreditConfiguratorV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditConfiguratorV3.sol";
import {IBytecodeRepository} from "../interfaces/IBytecodeRepository.sol";
import {IMarketConfigurator} from "../interfaces/IMarketConfigurator.sol";

import {AbstractFactory} from "./AbstractFactory.sol";
import {
    DOMAIN_CREDIT_MANAGER,
    DOMAIN_ADAPTER,
    DOMAIN_DEGEN_NFT,
    AP_CREDIT_FACADE,
    AP_CREDIT_CONFIGURATOR,
    AP_CREDIT_FACTORY,
    AP_WETH_TOKEN,
    AP_BYTECODE_REPOSITORY,
    NO_VERSION_CONTROL
} from "../libraries/ContractLiterals.sol";
import {IBytecodeRepository} from "../interfaces/IBytecodeRepository.sol";
import {IContractsRegister} from "../interfaces/extensions/IContractsRegister.sol";
import {Call, DeployParams, DeployResult} from "../interfaces/Types.sol";
import {CallBuilder} from "../libraries/CallBuilder.sol";

interface ICreditConfig {
    function deployAdapter(bytes32 postfix, bytes calldata constructorParams) external;

    function deployDegenNFT(bytes32 postfix, bytes calldata specificParams) external;
}

struct CreditSuiteDeployParams {
    uint8 maxEnabledTokens;
    uint16 feeInterest;
    string name;
    address degenNFT;
    bool expirable;
    uint256 debtLimit;
    uint128 minDebt;
    uint128 maxDebt;
    uint16 feeLiquidation;
    uint16 liquidationPremium;
    uint16 feeLiquidationExpired;
    uint16 liquidationPremiumExpired;
}

// CreditFactoryV3 is responsible for deploying the entire credit suite and managing specific management functions.
contract CreditFactory is AbstractFactory, ICreditFactory {
    using CallBuilder for Call;
    /// @notice Contract version

    uint256 public constant override version = 3_10;
    bytes32 public constant override contractType = AP_CREDIT_FACTORY;

    // AccountFactory instance which is used for all deployed creditManagers by this factory
    address public immutable accountFactory;

    // Address of the BotList contract
    address public immutable botList;

    // Address of the WETH token
    address public immutable weth;

    constructor(address _addressProvider) AbstractFactory(_addressProvider) {
        // shouldn't factory be the owner?
        // FIXME: all credit factories of version 3_1x should be able to access these two contracts
        accountFactory = address(new AccountFactoryV3(msg.sender));
        botList = address(new BotListV3(msg.sender));
        weth = IAddressProvider(_addressProvider).getAddressOrRevert(AP_WETH_TOKEN, NO_VERSION_CONTROL);
    }

    /// @notice Deploys a new credit suite for the specified pool with provided parameters.
    /// @param pool The address of the pool for which to create the credit suite.
    /// @param encodedParams The encoded deployment parameters for the credit suite.
    /// @return creditManager The address of the deployed credit manager.
    function deployCreditSuite(address pool, bytes calldata encodedParams)
        external
        override
        marketConfiguratorsOnly
        returns (DeployResult memory)
    {
        // Control pool version
        CreditSuiteDeployParams memory params = abi.decode(encodedParams, (CreditSuiteDeployParams));

        address contractsRegister = IMarketConfigurator(msg.sender).contractsRegister();
        address priceOracle = IContractsRegister(contractsRegister).getPriceOracle(pool);
        address[] memory emergencyLiquidators = IMarketConfigurator(msg.sender).emergencyLiquidators();

        address creditManager = _deployCreditManager({
            marketConfigurator: msg.sender,
            _pool: pool,
            _priceOracle: priceOracle,
            _maxEnabledTokens: params.maxEnabledTokens,
            _feeInterest: params.feeInterest,
            _name: params.name,
            _version: version
        });

        address creditConfigurator =
            _deployCreditConfigurator({marketConfigurator: msg.sender, creditManager: creditManager});

        // QUESTION: can we set degenNFT to address(0) and  update it later?
        // QUESTION: can we remove expirable parameter and update it later?
        address creditFacade = _deployCreditFacade({
            marketConfigurator: msg.sender,
            creditManager: creditManager,
            _degenNFT: params.degenNFT,
            _expirable: params.expirable
        });

        // Execute on behalf of factory
        ICreditManagerV3(creditManager).setCreditConfigurator(creditConfigurator);

        AccountFactoryV3(accountFactory).addCreditManager(creditManager);
        BotListV3(botList).approveCreditManager(creditManager);

        address[] memory accessList = new address[](1);
        accessList[0] = creditConfigurator;

        return DeployResult({
            newContract: creditManager,
            accessList: accessList,
            onInstallOps: CallBuilder.build(_setCreditFacade(creditConfigurator, creditFacade, false))
        });
    }

    /// @notice Single endpoint for configuring credit managers
    /// @dev This function serves as a unified entry point for various configuration operations on credit managers
    /// @param creditManager The address of the credit manager to configure
    /// @param callData Encoded configuration data, specific to the operation being performed
    /// @return calls An array of Call structs representing the configuration operations to be executed
    function configure(address creditManager, bytes calldata callData)
        external
        override
        marketConfiguratorsOnly
        returns (Call[] memory calls)
    {
        bytes4 selector = bytes4(callData);
        if (selector == ICreditConfig.deployAdapter.selector) {
            (bytes32 postfix, bytes memory constructorParams) = abi.decode(callData[4:], (bytes32, bytes));

            // TODO: verify, that the first parameter in constructorParams is creditManager
            address newAdapter = IBytecodeRepository(bytecodeRepository).deployByDomain(
                DOMAIN_ADAPTER, postfix, version, constructorParams, bytes32(bytes20(msg.sender))
            );

            calls = CallBuilder.build(_allowAdapter(creditManager, newAdapter));
        } else if (selector == ICreditConfig.deployDegenNFT.selector) {
            (bytes32 postfix, bytes memory constructorParams) = abi.decode(callData[4:], (bytes32, bytes));

            IBytecodeRepository(bytecodeRepository).deployByDomain(
                DOMAIN_DEGEN_NFT, postfix, version, constructorParams, bytes32(bytes20(msg.sender))
            );
        }

        // QUESTION: mapping for other functions of if..else statements?
    }

    // // add as subfuncton of creditManager
    // function _configureAdapter(address creditManager, address targetContract, bytes calldata data) internal {
    //     _ensureRegisteredCreditManager(creditManager);

    //     address adapter = _getAdapterOrRevert(creditManager, targetContract);
    //     adapter.functionCall(data);
    // }

    // function _getAdapterOrRevert(address creditManager, address targetContract) internal view returns (address) {
    //     address adapter = ICreditManagerV3(creditManager).contractToAdapter(targetContract);
    //     if (adapter == address(0)) revert AdapterNotInitializedException(creditManager, targetContract);
    //     return adapter;
    // }

    //
    // CREDIT HOOKS
    //
    function onUpdatePriceOracle(address creditManager, address newPriceOracle, address)
        external
        view
        returns (Call[] memory calls)
    {
        calls = CallBuilder.build(_updatePriceOracle(creditManager, newPriceOracle));
    }

    function onAddEmergencyLiquidator(address creditManager, address liquidator)
        external
        view
        returns (Call[] memory calls)
    {
        calls = CallBuilder.build(_addEmergencyLiquidator(creditManager, liquidator));
    }

    function onRemoveEmergencyLiquidator(address creditManager, address liquidator)
        external
        view
        returns (Call[] memory calls)
    {
        calls = CallBuilder.build(_removeEmergencyLiquidator(creditManager, liquidator));
    }

    function onUpdateLossLiquidator(address creditManager, address newLossLiquidator, address)
        external
        view
        returns (Call[] memory calls)
    {
        calls = CallBuilder.build(_updateLossLiquidator(creditManager, newLossLiquidator));
    }

    //
    // DEPLOYMENTS

    function _deployCreditManager(
        address marketConfigurator,
        address _pool,
        address _priceOracle,
        uint8 _maxEnabledTokens,
        uint16 _feeInterest,
        string memory _name,
        uint256 _version
    ) internal returns (address) {
        // TODO: move mapping back to factory
        bytes32 postfix;
        {
            // check postfix
            address underlying = IPoolV3(_pool).asset();
            postfix = IBytecodeRepository(bytecodeRepository).getTokenSpecificPostfix(underlying);
        }

        // CreditManager  constructor parameters:
        //   (
        //     address _pool,
        //     address _accountFactory,
        //     address _priceOracle,
        //     uint8 _maxEnabledTokens,
        //     uint16 _feeInterest,
        //     string memory _name
        //   )
        bytes memory constructorParams =
            abi.encode(_pool, accountFactory, _priceOracle, _maxEnabledTokens, _feeInterest, _name);

        bytes32 salt = bytes32(bytes20(marketConfigurator));

        return IBytecodeRepository(bytecodeRepository).deployByDomain(
            DOMAIN_CREDIT_MANAGER, postfix, _version, constructorParams, salt
        );
    }

    function _deployCreditConfigurator(address marketConfigurator, address creditManager) internal returns (address) {
        bytes memory constructorParams = abi.encode(creditManager);

        return IBytecodeRepository(bytecodeRepository).deploy(
            AP_CREDIT_CONFIGURATOR, version, constructorParams, bytes32(bytes20(marketConfigurator))
        );
    }

    function _deployCreditFacade(address marketConfigurator, address creditManager, address _degenNFT, bool _expirable)
        internal
        returns (address)
    {
        bytes memory constructorParams = abi.encode(creditManager, botList, weth, _degenNFT, _expirable);

        return IBytecodeRepository(bytecodeRepository).deploy(
            AP_CREDIT_FACADE, version, constructorParams, bytes32(bytes20(marketConfigurator))
        );
    }

    //
    // Function Call Generators
    //
    function _creditConfigurator(address creditManager) internal view returns (address) {
        return ICreditManagerV3(creditManager).creditConfigurator();
    }

    function _setCreditFacade(address creditManager, address newCreditFacade, bool migrateParams)
        internal
        view
        returns (Call memory call)
    {
        call = Call({
            target: _creditConfigurator(creditManager),
            callData: abi.encodeCall(ICreditConfiguratorV3.setCreditFacade, (newCreditFacade, migrateParams))
        });
    }

    function _addEmergencyLiquidator(address creditManager, address liquidator)
        internal
        view
        returns (Call memory call)
    {
        call = Call({
            target: _creditConfigurator(creditManager),
            callData: abi.encodeCall(ICreditConfiguratorV3.addEmergencyLiquidator, liquidator)
        });
    }

    function _removeEmergencyLiquidator(address creditManager, address liquidator)
        internal
        view
        returns (Call memory call)
    {
        call = Call({
            target: _creditConfigurator(creditManager),
            callData: abi.encodeCall(ICreditConfiguratorV3.removeEmergencyLiquidator, liquidator)
        });
    }

    function _updateLossLiquidator(address creditManager, address lossLiquidator)
        internal
        view
        returns (Call memory call)
    {
        // TODO: fix import V3_1

        // call = Call({
        //     target: _creditConfigurator(creditManager),
        //     callData: abi.encodeCall(ICreditConfiguratorV3.updateLossLiquidator, lossLiquidator)
        // });
    }

    function _updatePriceOracle(address creditManager, address priceOracle) internal view returns (Call memory call) {
        call = Call({
            target: _creditConfigurator(creditManager),
            callData: abi.encodeCall(ICreditConfiguratorV3.setPriceOracle, priceOracle)
        });
    }

    function _allowAdapter(address creditManager, address newAdapter) internal view returns (Call memory call) {
        call = Call({
            target: _creditConfigurator(creditManager),
            callData: abi.encodeCall(ICreditConfiguratorV3.allowAdapter, newAdapter)
        });
    }
}
