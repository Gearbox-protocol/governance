// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ICreditManagerV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import {IPoolQuotaKeeperV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPoolQuotaKeeperV3.sol";
import {IPoolV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPoolV3.sol";
import {IPriceOracleV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPriceOracleV3.sol";
import {
    IncorrectPriceException,
    InsufficientBalanceException
} from "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";

import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {IBytecodeRepository} from "../interfaces/IBytecodeRepository.sol";
import {IMarketConfigurator} from "../interfaces/IMarketConfigurator.sol";

import {AbstractFactory} from "./AbstractFactory.sol";
import {MarketHookFactory} from "./MarketHookFactory.sol";
import {
    AP_POOL_QUOTA_KEEPER,
    AP_POOL_FACTORY,
    AP_DEFAULT_IRM,
    NO_VERSION_CONTROL,
    DOMAIN_POOL
} from "../libraries/ContractLiterals.sol";

import {CallBuilder} from "../libraries/CallBuilder.sol";
import {DeployResult} from "../interfaces/Types.sol";
import {IPoolFactory} from "../interfaces/IPoolFactory.sol";
import {Call, DeployResult} from "../interfaces/Types.sol";
import {IMarketHooks} from "../interfaces/IMarketHooks.sol";
import {IContractsRegister} from "../interfaces/extensions/IContractsRegister.sol";

contract PoolFactory is AbstractFactory, MarketHookFactory, IPoolFactory {
    using SafeERC20 for IERC20;
    using CallBuilder for Call;

    /// @notice Contract version
    uint256 public constant override version = 3_10;

    /// @notice Contract type
    bytes32 public constant override contractType = AP_POOL_FACTORY;

    address public immutable defaultInterestRateModel;

    //
    // ERRORS
    //

    // Thrown if attempting to remove a market that still has active positions
    error CantShutdownNonEmptyMarketException(address pool);

    // Thrown if a credit manager with non-zero borrowed amount is attempted to be removed
    error CantShutdownNonEmptyCreditSuiteException(address creditManager);

    constructor(address addressProvider_) AbstractFactory(addressProvider_) {
        defaultInterestRateModel = _getContract(AP_DEFAULT_IRM, NO_VERSION_CONTROL);
    }

    function deployPool(address underlying, string calldata name, string calldata symbol)
        external
        override
        marketConfiguratorsOnly
        returns (DeployResult memory)
    {
        address acl = IMarketConfigurator(msg.sender).acl();
        address contractsRegister = IMarketConfigurator(msg.sender).contractsRegister();
        address treasury = IMarketConfigurator(msg.sender).treasury();

        address pool = _deployPool({
            marketConfigurator: msg.sender,
            underlying: underlying,
            contractsRegister: contractsRegister,
            acl: acl,
            treasury: treasury,
            interestRateModel: defaultInterestRateModel,
            name: name,
            symbol: symbol,
            version_: version
        });

        address quotaKeeper = _deployQuotaKeeper({marketConfigurator: msg.sender, pool: pool, version_: version});

        // Inflation attack protection
        if (IERC20(underlying).balanceOf(address(this)) < 1e5) revert InsufficientBalanceException();
        IERC20(underlying).forceApprove(pool, 1e5);
        IPoolV3(pool).deposit(1e5, address(0xdead));

        address[] memory accessList = new address[](2);
        accessList[0] = pool;
        accessList[1] = quotaKeeper;

        return DeployResult({
            newContract: pool,
            accessList: accessList,
            onInstallOps: CallBuilder.build(_setQuotaKeeper(pool, quotaKeeper))
        });
    }

    // ------------ //
    // MARKET HOOKS //
    // ------------ //

    function onCreateMarket(address pool, address, address interestRateModel, address rateKeeper, address)
        external
        view
        override(IMarketHooks, MarketHookFactory)
        returns (Call[] memory calls)
    {
        calls = CallBuilder.build(
            _setInterestRateModel(pool, interestRateModel), _setRateKeeper(_quotaKeeper(pool), rateKeeper)
        );
    }

    function onShutdownMarket(address pool)
        external
        view
        override(IMarketHooks, MarketHookFactory)
        returns (Call[] memory calls)
    {
        if (IPoolV3(pool).totalBorrowed() != 0) {
            revert CantShutdownNonEmptyMarketException(pool);
        }

        calls = CallBuilder.build(_setTotalDebtLimit(pool, 0), _setWithdrawFee(pool, 0));
    }

    function onCreateCreditSuite(address pool, address creditManager)
        external
        view
        override(IMarketHooks, MarketHookFactory)
        returns (Call[] memory)
    {
        return CallBuilder.build(
            _setCreditManagerDebtLimit(pool, creditManager, 0), _addCreditManager(_quotaKeeper(pool), creditManager)
        );
    }

    /**
     * @notice Hook that executes when a creditManager is removed from the market.
     * It checks
     * @param creditManager The address of the creditManager being removed.
     * @return calls An array of Call structs to be executed, setting the credit manager's debt limit to zero.
     */
    function onShutdownCreditSuite(address creditManager)
        external
        view
        override(IMarketHooks, MarketHookFactory)
        returns (Call[] memory calls)
    {
        address pool = ICreditManagerV3(creditManager).pool();

        if (IPoolV3(pool).creditManagerBorrowed(creditManager) != 0) {
            revert CantShutdownNonEmptyCreditSuiteException(creditManager);
        }

        return CallBuilder.build(_setCreditManagerDebtLimit(pool, creditManager, 0));
    }

    // @dev Hook which is called when interest model is updated
    // @param pool - pool address
    // @param newModel - new interest model address
    // @return calls - array of calls to be executed
    function onUpdateInterestRateModel(address pool, address newInterestRateModel, address)
        external
        pure
        override(IMarketHooks, MarketHookFactory)
        returns (Call[] memory)
    {
        return CallBuilder.build(_setInterestRateModel(pool, newInterestRateModel));
    }

    /**
     * @notice Hook that executes when the rate keeper is updated for a pool
     * @dev This hook is used to update the rate keeper in the pool quota keeper
     * @param pool The address of the pool
     * @param newRateKeeper The address of the new rate keeper
     * @return calls An array of Call structs to be executed
     */
    function onUpdateRateKeeper(address pool, address newRateKeeper, address)
        external
        view
        override(IMarketHooks, MarketHookFactory)
        returns (Call[] memory)
    {
        return CallBuilder.build(_setRateKeeper(_quotaKeeper(pool), newRateKeeper));
    }

    // @dev Hook which is called when price feed is updated
    // Used as verification for price oracle, to prove that price is not zero
    // for underlying or any other collateral token with non-zero quota
    // @param pool - pool address
    // @param token - token address
    // @param priceFeed - price feed address
    // @return calls - array of calls to be executed
    function onSetPriceFeed(address pool, address token, address priceFeed)
        external
        view
        override(IMarketHooks, MarketHookFactory)
        returns (Call[] memory calls)
    {
        // FIXME: seems like we must validate `priceFeed`'s price, not price oracle's
        address contractsRegister = IMarketConfigurator(msg.sender).contractsRegister();
        address priceOracle = IContractsRegister(contractsRegister).getPriceOracle(pool);
        if (
            IPriceOracleV3(priceOracle).getPrice(token) == 0
                && (token == IPoolV3(pool).asset() || _quota(pool, token) != 0)
        ) revert IncorrectPriceException();
    }

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function configure(address pool, bytes calldata callData) external view returns (Call[] memory) {
        bytes4 selector = bytes4(callData);
        if (
            selector == IPoolV3.setTotalDebtLimit.selector || selector == IPoolV3.setCreditManagerDebtLimit.selector
                || selector == IPoolV3.setWithdrawFee.selector
        ) {
            return CallBuilder.build(Call({target: pool, callData: callData}));
        } else if (
            selector == IPoolQuotaKeeperV3.setTokenLimit.selector
                || selector == IPoolQuotaKeeperV3.setTokenQuotaIncreaseFee.selector
        ) {
            return CallBuilder.build(Call({target: _quotaKeeper(pool), callData: callData}));
        } else {
            revert ForbiddenConfigurationCallException(selector);
        }
    }

    // --------- //
    // INTERNALS //
    // --------- //

    function _deployPool(
        address marketConfigurator,
        address underlying,
        address contractsRegister,
        address acl,
        address treasury,
        address interestRateModel,
        string calldata name,
        string calldata symbol,
        uint256 version_
    ) internal returns (address) {
        bytes32 postfix = IBytecodeRepository(bytecodeRepository).getTokenSpecificPostfix(underlying);
        bytes memory constructorParams =
            abi.encode(acl, contractsRegister, underlying, treasury, interestRateModel, uint256(0), name, symbol);
        bytes32 salt = bytes32(bytes20(marketConfigurator));
        return _deployByDomain({
            domain: DOMAIN_POOL,
            postfix: postfix,
            version_: version_,
            constructorParams: constructorParams,
            salt: salt
        });
    }

    function _deployQuotaKeeper(address marketConfigurator, address pool, uint256 version_)
        internal
        returns (address)
    {
        return _deploy({
            type_: AP_POOL_QUOTA_KEEPER,
            version_: version_,
            constructorParams: abi.encode(pool),
            salt: bytes32(bytes20(marketConfigurator))
        });
    }

    function _quotaKeeper(address pool) internal view returns (address) {
        return IPoolV3(pool).poolQuotaKeeper();
    }

    function _quota(address pool, address token) internal view returns (uint96 quota) {
        (,,, quota,,) = IPoolQuotaKeeperV3(_quotaKeeper(pool)).getTokenQuotaParams(token);
    }

    function _setQuotaKeeper(address pool, address quotaKeeper) internal pure returns (Call memory) {
        return Call({target: pool, callData: abi.encodeCall(IPoolV3.setPoolQuotaKeeper, quotaKeeper)});
    }

    function _setRateKeeper(address quotaKeeper, address rateKeeper) internal pure returns (Call memory) {
        return Call({target: quotaKeeper, callData: abi.encodeCall(IPoolQuotaKeeperV3.setGauge, (rateKeeper))});
    }

    function _setInterestRateModel(address pool, address interestRateModel) internal pure returns (Call memory) {
        return Call({target: pool, callData: abi.encodeCall(IPoolV3.setInterestRateModel, (interestRateModel))});
    }

    function _setTotalDebtLimit(address pool, uint256 limit) internal pure returns (Call memory) {
        return Call({target: pool, callData: abi.encodeCall(IPoolV3.setTotalDebtLimit, (limit))});
    }

    function _setCreditManagerDebtLimit(address pool, address creditManager, uint256 limit)
        internal
        pure
        returns (Call memory)
    {
        return Call({target: pool, callData: abi.encodeCall(IPoolV3.setCreditManagerDebtLimit, (creditManager, limit))});
    }

    function _setWithdrawFee(address pool, uint256 fee) internal pure returns (Call memory) {
        return Call({target: pool, callData: abi.encodeCall(IPoolV3.setWithdrawFee, (fee))});
    }

    function _addCreditManager(address quotaKeeper, address creditManager) internal pure returns (Call memory) {
        return
            Call({target: quotaKeeper, callData: abi.encodeCall(IPoolQuotaKeeperV3.addCreditManager, (creditManager))});
    }
}
