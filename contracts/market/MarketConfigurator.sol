// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {IVersion} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IVersion.sol";
import {ICreditManagerV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import {IPoolQuotaKeeperV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPoolQuotaKeeperV3.sol";
import {IPoolV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPoolV3.sol";

import "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";

import {IACL} from "../interfaces/extensions/IACL.sol";
import {IContractsRegister} from "../interfaces/extensions/IContractsRegister.sol";

import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {IRateKeeperFactory} from "../interfaces/IRateKeeperFactory.sol";
import {IMarketConfigurator} from "../interfaces/IMarketConfigurator.sol";
import {ILossLiquidatorFactory} from "../interfaces/ILossLiquidatorFactory.sol";
import {IInterestRateModelFactory} from "../interfaces/IInterestRateModelFactory.sol";
import {IPriceOracleFactory} from "../interfaces/IPriceOracleFactory.sol";
import {ICreditFactory} from "../interfaces/ICreditFactory.sol";
import {IPoolFactory} from "../interfaces/IPoolFactory.sol";

import {
    AP_MARKET_CONFIGURATOR,
    AP_MARKET_CONFIGURATOR_FACTORY,
    NO_VERSION_CONTROL
} from "../libraries/ContractLiterals.sol";

import {ICreditHooks} from "../interfaces/ICreditHooks.sol";
import {IMarketHooks} from "../interfaces/IMarketHooks.sol";
import {Call, DeployParams, DeployResult} from "../interfaces/Types.sol";
import {IConfiguratingFactory} from "../interfaces/IConfiguratingFactory.sol";

import {IHook, HookCheck, HookExecutor} from "../libraries/Hook.sol";

import {ContractsRegister} from "./ContractsRegister.sol";

// TODO:
// - degen NFT management
// - migration to new market configurator
// - rescue

/// @title Market configurator
contract MarketConfigurator is Ownable2Step, IMarketConfigurator {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using HookExecutor for IHook;

    uint256 public constant override version = 3_10;
    bytes32 public constant override contractType = AP_MARKET_CONFIGURATOR;

    address public immutable override addressProvider;
    address public immutable override marketConfiguratorFactory;
    address public immutable override acl;
    address public immutable override contractsRegister;
    address public immutable override treasury;

    address latestInterestRateModelFactory;
    address latestPoolFactory;
    address latestRateKeeperFactory;
    address latestPriceOracleFactory;
    address latestLossLiquidatorFactory;

    address latestCreditFactory;

    // TODO: potentially move to contracts register as well
    // ACL seems to be a better place for it though since this list is the same for all markets
    EnumerableSet.AddressSet internal _emergencyLiquidators;

    // Access list is additional protection measure to restrict contracts
    // which could be called via hooks.

    /// @notice
    mapping(address contract_ => address factory) public accessList;

    modifier onlySelf() {
        if (msg.sender != address(this)) revert();
        _;
    }

    // ----------- //
    // CONSTRUCTOR //
    // ----------- //

    /// @notice Initializes the MarketConfigurator with the provided parameters.
    /// @param riskCurator_ The address of the risk curator.
    /// @param addressProvider_ The address of the address provider.
    /// @param acl_ The address of the access control list.
    /// @param treasury_ The address of the treasury.
    constructor(address riskCurator_, address addressProvider_, address acl_, address treasury_) {
        _transferOwnership(riskCurator_);
        addressProvider = addressProvider_;
        marketConfiguratorFactory = _getContract(AP_MARKET_CONFIGURATOR_FACTORY, NO_VERSION_CONTROL);

        acl = acl_;
        treasury = treasury_;

        contractsRegister = address(new ContractsRegister(acl));
    }

    // QUESTION: switch to role model?
    function emergencyLiquidators() external view override returns (address[] memory) {
        return _emergencyLiquidators.values();
    }

    // ----------------- //
    // MARKET MANAGEMENT //
    // ----------------- //

    function createMarket(
        address underlying,
        address underlyingPriceFeed,
        string calldata name,
        string calldata symbol,
        DeployParams calldata interestRateModelParams,
        DeployParams calldata rateKeeperParams
    ) external override onlyOwner returns (address pool) {
        pool = _deployPool(underlying, name, symbol);
        address priceOracle = _deployPriceOracle(pool);
        address interestRateModel = _deployInterestRateModel(pool, interestRateModelParams);
        address rateKeeper = _deployRateKeeper(pool, rateKeeperParams);

        IContractsRegister(contractsRegister).createMarket(pool, priceOracle);
        _setPoolFactory(pool, latestPoolFactory);
        _setPriceOracleFactory(pool, latestPriceOracleFactory);
        _setInterestRateModelFactory(pool, latestInterestRateModelFactory);
        _setRateKeeperFactory(pool, latestRateKeeperFactory);

        // yes, it's november 2024 and we still get stack too deep; no, we're not gonna use IR
        address underlyingPriceFeed_ = underlyingPriceFeed;
        _executeMarketHooks(
            pool,
            abi.encodeCall(
                IMarketHooks.onCreateMarket, (pool, priceOracle, interestRateModel, rateKeeper, underlyingPriceFeed_)
            )
        );
    }

    function shutdownMarket(address pool) external override onlyOwner {
        _ensureRegisteredPool(pool);

        _executeMarketHooks(pool, abi.encodeCall(IMarketHooks.onShutdownMarket, (pool)));
        IContractsRegister(contractsRegister).shutdownMarket(pool);
    }

    function addToken(address pool, address token, address priceFeed) external override onlyOwner {
        _ensureRegisteredPool(pool);

        _executeMarketHooks(pool, abi.encodeCall(IMarketHooks.onAddToken, (pool, token, priceFeed)));
    }

    function configurePool(address pool, bytes calldata data) external override onlyOwner {
        _ensureRegisteredPool(pool);
        _configureContract(_getPoolFactory(pool), pool, data);
    }

    function _deployPool(address underlying, string calldata name, string calldata symbol) internal returns (address) {
        DeployResult memory deployResult = IPoolFactory(latestPoolFactory).deployPool(underlying, name, symbol);
        _executeOnDeploy(latestPoolFactory, deployResult);
        return deployResult.newContract;
    }

    // ----------------------- //
    // CREDIT SUITE MANAGEMENT //
    // ----------------------- //

    function createCreditSuite(address pool, bytes calldata encodedParams)
        public
        virtual
        override
        onlyOwner
        returns (address creditManager)
    {
        _ensureRegisteredPool(pool);

        creditManager = _deployCreditSuite(pool, encodedParams);
        _setCreditFactory(creditManager, latestCreditFactory);

        IContractsRegister(contractsRegister).createCreditSuite(pool, creditManager);
        _executeMarketHooks(pool, abi.encodeCall(IMarketHooks.onCreateCreditSuite, (pool, creditManager)));
    }

    function shutdownCreditSuite(address creditManager) external override onlyOwner {
        _ensureRegisteredCreditManager(creditManager);

        _executeMarketHooks(
            ICreditManagerV3(creditManager).pool(), abi.encodeCall(IMarketHooks.onShutdownCreditSuite, (creditManager))
        );
        IContractsRegister(contractsRegister).shutdownCreditSuite(creditManager);
    }

    function configureCreditSuite(address creditManager, bytes calldata data) external override onlyOwner {
        _ensureRegisteredCreditManager(creditManager);
        _configureContract(_getCreditFactory(creditManager), creditManager, data);
    }

    function _deployCreditSuite(address pool, bytes calldata encodedParams) internal returns (address) {
        DeployResult memory deployResult = ICreditFactory(latestCreditFactory).deployCreditSuite(pool, encodedParams);
        _executeOnDeploy(latestCreditFactory, deployResult);
        return deployResult.newContract;
    }

    // ----------------------- //
    // PRICE ORACLE MANAGEMENT //
    // ----------------------- //

    function updatePriceOracle(address pool) external override onlyOwner returns (address priceOracle) {
        _ensureRegisteredPool(pool);
        address oldPriceOracle = IContractsRegister(contractsRegister).getPriceOracle(pool);

        priceOracle = _deployPriceOracle(pool);
        _setPriceOracleFactory(pool, latestPriceOracleFactory);

        IContractsRegister(contractsRegister).setPriceOracle(pool, priceOracle);
        _executeMarketHooks(pool, abi.encodeCall(IMarketHooks.onUpdatePriceOracle, (pool, priceOracle, oldPriceOracle)));

        address[] memory creditManagers = _creditManagers(pool);
        uint256 numManagers = creditManagers.length;
        for (uint256 i; i < numManagers; ++i) {
            address creditManager = creditManagers[i];
            _executeHook(
                IHook(_getCreditFactory(creditManager)).onUpdatePriceOracle(creditManager, priceOracle, oldPriceOracle)
            );
        }
    }

    function setPriceFeed(address pool, address token, address priceFeed) external override onlyOwner {
        _ensureRegisteredPool(pool);
        _executeMarketHooks(pool, abi.encodeCall(IMarketHooks.onSetPriceFeed, (pool, token, priceFeed)));
    }

    function setReservePriceFeed(address pool, address token, address priceFeed) external override onlyOwner {
        _ensureRegisteredPool(pool);
        _executeMarketHooks(pool, abi.encodeCall(IMarketHooks.onSetReservePriceFeed, (pool, token, priceFeed)));
    }

    function _deployPriceOracle(address pool) internal returns (address) {
        DeployResult memory deployResult = IPriceOracleFactory(latestPriceOracleFactory).deployPriceOracle(pool);
        _executeOnDeploy(latestPriceOracleFactory, deployResult);
        return deployResult.newContract;
    }

    // -------------- //
    // IRM MANAGEMENT //
    // -------------- //

    function updateInterestRateModel(address pool, DeployParams calldata params)
        external
        override
        onlyOwner
        returns (address interestRateModel)
    {
        _ensureRegisteredPool(pool);
        address oldInterestRateModel = _interestRateModel(pool);

        interestRateModel = _deployInterestRateModel(pool, params);
        _setInterestRateModelFactory(pool, latestInterestRateModelFactory);

        _executeMarketHooks(
            pool,
            abi.encodeCall(IMarketHooks.onUpdateInterestRateModel, (pool, interestRateModel, oldInterestRateModel))
        );
    }

    function configureInterestRateModel(address pool, bytes calldata data) external override onlyOwner {
        _ensureRegisteredPool(pool);
        _configureContract(_getInterestRateModelFactory(pool), _interestRateModel(pool), data);
    }

    function _deployInterestRateModel(address pool, DeployParams calldata params) internal returns (address) {
        DeployResult memory deployResult =
            IInterestRateModelFactory(latestInterestRateModelFactory).deployInterestRateModel(pool, params);
        _executeOnDeploy(latestInterestRateModelFactory, deployResult);
        return deployResult.newContract;
    }

    // ---------------------- //
    // RATE KEEPER MANAGEMENT //
    // ---------------------- //

    function updateRateKeeper(address pool, DeployParams calldata params)
        external
        override
        onlyOwner
        returns (address rateKeeper)
    {
        _ensureRegisteredPool(pool);
        address oldRateKeeper = _rateKeeper(pool);

        rateKeeper = _deployRateKeeper(pool, params);
        _setRateKeeperFactory(pool, latestRateKeeperFactory);

        _executeMarketHooks(pool, abi.encodeCall(IMarketHooks.onUpdateRateKeeper, (pool, rateKeeper, oldRateKeeper)));
    }

    function configureRateKeeper(address pool, bytes calldata data) external onlyOwner {
        _ensureRegisteredPool(pool);
        _configureContract(_getRateKeeperFactory(pool), _rateKeeper(pool), data);
    }

    function _deployRateKeeper(address pool, DeployParams calldata params) internal returns (address) {
        DeployResult memory deployResult = IRateKeeperFactory(latestRateKeeperFactory).deployRateKeeper(pool, params);
        _executeOnDeploy(latestRateKeeperFactory, deployResult);
        return deployResult.newContract;
    }

    // -------------------------- //
    // LOSS LIQUIDATOR MANAGEMENT //
    // -------------------------- //

    function updateLossLiquidator(address pool, DeployParams calldata params)
        external
        override
        onlyOwner
        returns (address lossLiquidator)
    {
        _ensureRegisteredPool(pool);
        address oldLossLiquidator = IContractsRegister(contractsRegister).getLossLiquidator(pool);

        lossLiquidator = _deployLossLiquidator(pool, params);
        _setLossLiquidatorFactory(pool, latestLossLiquidatorFactory);

        IContractsRegister(contractsRegister).setLossLiquidator(pool, lossLiquidator);
        _executeMarketHooks(
            pool, abi.encodeCall(IMarketHooks.onUpdateLossLiquidator, (pool, lossLiquidator, oldLossLiquidator))
        );

        address[] memory creditManagers = _creditManagers(pool);
        uint256 numManagers = creditManagers.length;
        for (uint256 i; i < numManagers; ++i) {
            address creditManager = creditManagers[i];
            _executeHook(
                IHook(_getCreditFactory(creditManager)).onUpdateLossLiquidator(
                    creditManager, lossLiquidator, oldLossLiquidator
                )
            );
        }
    }

    function configureLossLiquidator(address pool, bytes calldata data) external override onlyOwner {
        _ensureRegisteredPool(pool);
        address lossLiquidator = IContractsRegister(pool).getLossLiquidator(pool);
        _configureContract(_getLossLiquidatorFactory(pool), lossLiquidator, data);
    }

    function _deployLossLiquidator(address pool, DeployParams calldata params) internal returns (address) {
        DeployResult memory deployResult =
            ILossLiquidatorFactory(latestLossLiquidatorFactory).deployLossLiquidator(pool, params);
        _executeOnDeploy(latestLossLiquidatorFactory, deployResult);
        return deployResult.newContract;
    }

    // ---------------- //
    // ROLES MANAGEMENT //
    // ---------------- //

    function addPausableAdmin(address admin) external onlyOwner {
        IACL(acl).addPausableAdmin(admin);
    }

    function addUnpausableAdmin(address admin) external onlyOwner {
        IACL(acl).addUnpausableAdmin(admin);
    }

    function removePausableAdmin(address admin) external onlyOwner {
        IACL(acl).removePausableAdmin(admin);
    }

    function removeUnpausableAdmin(address admin) external onlyOwner {
        IACL(acl).removeUnpausableAdmin(admin);
    }

    // QUESTION: rewrite using role model?
    function addEmergencyLiquidator(address liquidator) external onlyOwner {
        if (!_emergencyLiquidators.add(liquidator)) return;
        address[] memory creditManagers = _creditManagers();
        uint256 numManagers = creditManagers.length;
        for (uint256 i; i < numManagers; ++i) {
            address creditManager = creditManagers[i];
            _executeHook(IHook(_getCreditFactory(creditManager)).onAddEmergencyLiquidator(creditManager, liquidator));
        }
    }

    function removeEmergencyLiquidator(address liquidator) external onlyOwner {
        if (!_emergencyLiquidators.remove(liquidator)) return;
        address[] memory creditManagers = _creditManagers();
        uint256 numManagers = creditManagers.length;
        for (uint256 i; i < numManagers; ++i) {
            address creditManager = creditManagers[i];
            _executeHook(IHook(_getCreditFactory(creditManager)).onRemoveEmergencyLiquidator(creditManager, liquidator));
        }
    }

    // --------- //
    // INTERNALS //
    // --------- //

    function _getContract(bytes32 key, uint256 version_) internal view returns (address) {
        return IAddressProvider(addressProvider).getAddressOrRevert(key, version_);
    }

    function _ensureRegisteredPool(address pool) internal view {
        if (!IContractsRegister(contractsRegister).isPool(pool)) {
            revert RegisteredPoolOnlyException();
        }
    }

    function _ensureRegisteredCreditManager(address creditManager) internal view {
        if (!IContractsRegister(contractsRegister).isCreditManager(creditManager)) {
            revert RegisteredCreditManagerOnlyException();
        }
    }

    function _addToAccessList(address factory, address[] memory contracts) internal {
        for (uint256 i; i < contracts.length; ++i) {
            if (accessList[contracts[i]] != address(0)) revert ContractAlreadyInAccessListException(contracts[i]);
            // QUESTION: what happens when we upgrade factory?
            accessList[contracts[i]] = factory;
        }
    }

    function _executeOnDeploy(address factory, DeployResult memory deployResult) internal {
        _addToAccessList(factory, deployResult.accessList);
        _executeHook(HookCheck({factory: factory, calls: deployResult.onInstallOps}));
    }

    function _executeMarketHooks(address pool, bytes memory data) internal {
        // TODO: implement
    }

    function _executeHook(HookCheck memory hookCheck) internal virtual {
        uint256 len = hookCheck.calls.length;
        for (uint256 i; i < len; ++i) {
            // TODO: override in MCLegacy to forbid calling gear staking
            Call memory call = hookCheck.calls[i];
            if (accessList[call.target] != hookCheck.factory) revert ContractNotAssignedToFactoryException(call.target);
            call.target.functionCall(call.callData);
        }
    }

    function _configureContract(address factory, address target, bytes calldata callData) internal {
        _executeHook(HookCheck({factory: factory, calls: IConfiguratingFactory(factory).configure(target, callData)}));
    }

    function _creditManagers() internal view returns (address[] memory) {
        return IContractsRegister(contractsRegister).getCreditManagers();
    }

    function _creditManagers(address pool) internal view returns (address[] memory creditManagers) {
        return IContractsRegister(contractsRegister).getCreditManagers(pool);
    }

    function _interestRateModel(address pool) internal view returns (address) {
        return IPoolV3(pool).interestRateModel();
    }

    function _rateKeeper(address pool) internal view returns (address) {
        return IPoolQuotaKeeperV3(IPoolV3(pool).poolQuotaKeeper()).gauge();
    }

    function _getPoolFactory(address pool) internal view returns (address) {
        return IContractsRegister(contractsRegister).getPoolFactory(pool);
    }

    function _getCreditFactory(address creditManager) internal view returns (address) {
        return IContractsRegister(contractsRegister).getCreditFactory(creditManager);
    }

    function _getPriceOracleFactory(address pool) internal view returns (address) {
        return IContractsRegister(contractsRegister).getPriceOracleFactory(pool);
    }

    function _getLossLiquidatorFactory(address pool) internal view returns (address) {
        return IContractsRegister(contractsRegister).getLossLiquidatorFactory(pool);
    }

    function _getRateKeeperFactory(address pool) internal view returns (address) {
        return IContractsRegister(contractsRegister).getRateKeeperFactory(pool);
    }

    function _getInterestRateModelFactory(address pool) internal view returns (address) {
        return IContractsRegister(contractsRegister).getInterestRateModelFactory(pool);
    }

    function _setPoolFactory(address pool, address factory) internal {
        IContractsRegister(contractsRegister).setPoolFactory(pool, factory);
    }

    function _setCreditFactory(address creditManager, address factory) internal {
        IContractsRegister(contractsRegister).setCreditFactory(creditManager, factory);
    }

    function _setPriceOracleFactory(address pool, address factory) internal {
        IContractsRegister(contractsRegister).setPriceOracleFactory(pool, factory);
    }

    function _setLossLiquidatorFactory(address pool, address factory) internal {
        IContractsRegister(contractsRegister).setLossLiquidatorFactory(pool, factory);
    }

    function _setInterestRateModelFactory(address pool, address factory) internal {
        IContractsRegister(contractsRegister).setInterestRateModelFactory(pool, factory);
    }

    function _setRateKeeperFactory(address pool, address factory) internal {
        IContractsRegister(contractsRegister).setRateKeeperFactory(pool, factory);
    }
}
