// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IVersion} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IVersion.sol";
import {ICreditConfiguratorV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditConfiguratorV3.sol";
import {ICreditFacadeV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditFacadeV3.sol";
import {ICreditManagerV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import {IPoolQuotaKeeperV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPoolQuotaKeeperV3.sol";
import {IPoolV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPoolV3.sol";

import {DefaultLossPolicy} from "../../helpers/DefaultLossPolicy.sol";

import {IACL} from "../../interfaces/IACL.sol";
import {IContractsRegister} from "../../interfaces/IContractsRegister.sol";
import {Call, MarketFactories} from "../../interfaces/Types.sol";

import {
    AP_MARKET_CONFIGURATOR_LEGACY,
    AP_CROSS_CHAIN_GOVERNANCE_PROXY,
    DOMAIN_ZAPPER,
    NO_VERSION_CONTROL,
    ROLE_EMERGENCY_LIQUIDATOR,
    ROLE_PAUSABLE_ADMIN,
    ROLE_UNPAUSABLE_ADMIN
} from "../../libraries/ContractLiterals.sol";

import {MarketConfigurator} from "../MarketConfigurator.sol";

interface IACLLegacy {
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function transferOwnership(address newOwner) external;
    function claimOwnership() external;

    function isPausableAdmin(address account) external view returns (bool);
    function addPausableAdmin(address account) external;
    function removePausableAdmin(address account) external;

    function isUnpausableAdmin(address account) external view returns (bool);
    function addUnpausableAdmin(address account) external;
    function removeUnpausableAdmin(address account) external;
}

interface IContractsRegisterLegacy {
    function getPools() external view returns (address[] memory);
    function addPool(address pool) external;
    function getCreditManagers() external view returns (address[] memory);
    function addCreditManager(address creditManager) external;
}

interface IZapperRegisterLegacy {
    function zappers(address pool) external view returns (address[] memory);
}

struct PeripheryContract {
    bytes32 domain;
    address addr;
}

struct LegacyParams {
    address acl;
    address contractsRegister;
    address gearStaking;
    address zapperRegister;
    address[] pausableAdmins;
    address[] unpausableAdmins;
    address[] emergencyLiquidators;
    PeripheryContract[] peripheryContracts;
}

contract MarketConfiguratorLegacy is MarketConfigurator {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Contract version
    uint256 public constant override version = 3_10;

    /// @notice Contract type
    bytes32 public constant override contractType = AP_MARKET_CONFIGURATOR_LEGACY;

    address public immutable crossChainGovernanceProxy;

    address public immutable aclLegacy;
    address public immutable contractsRegisterLegacy;
    address public immutable gearStakingLegacy;

    error ACLOwnershipNotTransferredException();
    error AddressIsNotPausableAdminException(address admin);
    error AddressIsNotUnpausableAdminException(address admin);
    error CallerIsNotCrossChainGovernanceProxyException(address caller);
    error CallsToLegacyContractsAreForbiddenException();
    error CollateralTokenIsNotQuotedException(address creditManager, address token);
    error CreditSuiteAlreadyInitializedException(address creditManager);
    error CreditSuiteIsNotInitializedException(address creditManager);
    error InconsistentPriceOracleException(address creditManager);
    error MarketAlreadyInitializedException(address pool);
    error MarketIsNotInitializedException(address pool);

    modifier onlyCrossChainGovernanceProxy() {
        _ensureCallerIsCrossChainGovernanceProxy();
        _;
    }

    /// @dev There's no way to validate that `legacyParams_.pausableAdmins` and `legacyParams_.unpausableAdmins` are
    ///      exhaustive because the legacy ACL contract doesn't provide needed getters, so don't screw up :)
    constructor(
        address addressProvider_,
        address admin_,
        address emergencyAdmin_,
        string memory curatorName_,
        bool deployGovernor_,
        LegacyParams memory legacyParams_
    ) MarketConfigurator(addressProvider_, admin_, emergencyAdmin_, address(0), curatorName_, deployGovernor_) {
        crossChainGovernanceProxy = _getAddressOrRevert(AP_CROSS_CHAIN_GOVERNANCE_PROXY, NO_VERSION_CONTROL);

        aclLegacy = legacyParams_.acl;
        contractsRegisterLegacy = legacyParams_.contractsRegister;
        gearStakingLegacy = legacyParams_.gearStaking;

        uint256 num = legacyParams_.pausableAdmins.length;
        for (uint256 i; i < num; ++i) {
            address pausableAdmin = legacyParams_.pausableAdmins[i];
            if (!IACLLegacy(aclLegacy).isPausableAdmin(pausableAdmin)) {
                revert AddressIsNotPausableAdminException(pausableAdmin);
            }
            IACL(acl).grantRole(ROLE_PAUSABLE_ADMIN, pausableAdmin);
            emit GrantRole(ROLE_PAUSABLE_ADMIN, pausableAdmin);
        }
        num = legacyParams_.unpausableAdmins.length;
        for (uint256 i; i < num; ++i) {
            address unpausableAdmin = legacyParams_.unpausableAdmins[i];
            if (!IACLLegacy(aclLegacy).isUnpausableAdmin(unpausableAdmin)) {
                revert AddressIsNotUnpausableAdminException(unpausableAdmin);
            }
            IACL(acl).grantRole(ROLE_UNPAUSABLE_ADMIN, unpausableAdmin);
            emit GrantRole(ROLE_UNPAUSABLE_ADMIN, unpausableAdmin);
        }
        num = legacyParams_.emergencyLiquidators.length;
        for (uint256 i; i < num; ++i) {
            address liquidator = legacyParams_.emergencyLiquidators[i];
            IACL(acl).grantRole(ROLE_EMERGENCY_LIQUIDATOR, liquidator);
            emit GrantRole(ROLE_EMERGENCY_LIQUIDATOR, liquidator);
        }

        address[] memory pools = IContractsRegisterLegacy(contractsRegisterLegacy).getPools();
        uint256 numPools = pools.length;
        for (uint256 i; i < numPools; ++i) {
            address pool = pools[i];
            if (!_isV3Contract(pool)) continue;

            address[] memory creditManagers = IPoolV3(pool).creditManagers();
            uint256 numCreditManagers = creditManagers.length;
            if (numCreditManagers == 0) continue;

            address quotaKeeper = _quotaKeeper(pool);
            address priceOracle = _priceOracle(creditManagers[0]);
            address lossPolicy = address(new DefaultLossPolicy(acl));
            IContractsRegister(contractsRegister).registerMarket(pool, priceOracle, lossPolicy);

            for (uint256 j; j < numCreditManagers; ++j) {
                address creditManager = creditManagers[j];
                if (!_isV3Contract(creditManager)) continue;

                if (_priceOracle(creditManager) != priceOracle) {
                    revert InconsistentPriceOracleException(creditManager);
                }

                uint256 numTokens = ICreditManagerV3(creditManager).collateralTokensCount();
                uint256 quotedTokensMask = ICreditManagerV3(creditManager).quotedTokensMask();
                for (uint256 k = 1; k < numTokens; ++k) {
                    uint256 tokenMask = 1 << k;
                    address token = ICreditManagerV3(creditManager).getTokenByMask(tokenMask);
                    if (!IPoolQuotaKeeperV3(quotaKeeper).isQuotedToken(token) || quotedTokensMask & tokenMask == 0) {
                        revert CollateralTokenIsNotQuotedException(creditManager, token);
                    }
                }

                IContractsRegister(contractsRegister).registerCreditSuite(creditManager);
            }

            address[] memory zappers = IZapperRegisterLegacy(legacyParams_.zapperRegister).zappers(pool);
            uint256 numZappers = zappers.length;
            for (uint256 j; j < numZappers; ++j) {
                _peripheryContracts[DOMAIN_ZAPPER].add(zappers[j]);
                emit AddPeripheryContract(DOMAIN_ZAPPER, zappers[j]);
            }
        }

        uint256 numPeripheryContracts = legacyParams_.peripheryContracts.length;
        for (uint256 i; i < numPeripheryContracts; ++i) {
            PeripheryContract memory pc = legacyParams_.peripheryContracts[i];
            _peripheryContracts[pc.domain].add(pc.addr);
            emit AddPeripheryContract(pc.domain, pc.addr);
        }
    }

    function initializeMarket(address pool) external {
        _ensureRegisteredMarket(pool);
        if (_marketFactories[pool].poolFactory != address(0)) revert MarketAlreadyInitializedException(pool);

        MarketFactories memory factories = _getLatestMarketFactories(3_10);
        _marketFactories[pool] = factories;
        address quotaKeeper = _quotaKeeper(pool);
        address priceOracle = IContractsRegister(contractsRegister).getPriceOracle(pool);
        address interestRateModel = _interestRateModel(pool);
        address rateKeeper = _rateKeeper(quotaKeeper);
        address lossPolicy = IContractsRegister(contractsRegister).getLossPolicy(pool);
        _authorizeFactory(factories.poolFactory, pool, pool);
        _authorizeFactory(factories.poolFactory, pool, quotaKeeper);
        _authorizeFactory(factories.priceOracleFactory, pool, priceOracle);
        _authorizeFactory(factories.interestRateModelFactory, pool, interestRateModel);
        _authorizeFactory(factories.rateKeeperFactory, pool, rateKeeper);
        _authorizeFactory(factories.lossPolicyFactory, pool, lossPolicy);

        emit CreateMarket(pool, priceOracle, interestRateModel, rateKeeper, lossPolicy, factories);
    }

    function initializeCreditSuite(address creditManager) external {
        _ensureRegisteredCreditSuite(creditManager);
        if (_creditFactories[creditManager] != address(0)) revert CreditSuiteAlreadyInitializedException(creditManager);

        address factory = _getLatestCreditFactory(3_10);
        _creditFactories[creditManager] = factory;
        address creditConfigurator = ICreditManagerV3(creditManager).creditConfigurator();
        _authorizeFactory(factory, creditManager, creditConfigurator);
        _authorizeFactory(factory, creditManager, ICreditManagerV3(creditManager).creditFacade());
        address[] memory adapters = ICreditConfiguratorV3(creditConfigurator).allowedAdapters();
        uint256 numAdapters = adapters.length;
        for (uint256 k; k < numAdapters; ++k) {
            _authorizeFactory(factory, creditManager, adapters[k]);
        }

        emit CreateCreditSuite(creditManager, factory);
    }

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function finalizeMigration() external onlyCrossChainGovernanceProxy {
        address[] memory pools = IContractsRegister(contractsRegister).getPools();
        uint256 numPools = pools.length;
        for (uint256 i; i < numPools; ++i) {
            if (_marketFactories[pools[i]].poolFactory == address(0)) {
                revert MarketIsNotInitializedException(pools[i]);
            }
        }
        address[] memory creditManagers = IContractsRegister(contractsRegister).getCreditManagers();
        uint256 numCreditManagers = creditManagers.length;
        for (uint256 i; i < numCreditManagers; ++i) {
            if (_creditFactories[creditManagers[i]] == address(0)) {
                revert CreditSuiteIsNotInitializedException(creditManagers[i]);
            }
        }

        // NOTE: on some chains, legacy ACL implements a 2-step ownership transfer
        try IACLLegacy(aclLegacy).pendingOwner() returns (address pendingOwner) {
            if (pendingOwner != address(this)) revert ACLOwnershipNotTransferredException();
            IACLLegacy(aclLegacy).claimOwnership();
        } catch {
            if (IACLLegacy(aclLegacy).owner() != address(this)) revert ACLOwnershipNotTransferredException();
        }

        IACLLegacy(aclLegacy).addPausableAdmin(address(this));
        IACLLegacy(aclLegacy).addUnpausableAdmin(address(this));
    }

    function configureGearStaking(bytes calldata data) external onlyCrossChainGovernanceProxy {
        gearStakingLegacy.functionCall(data);
    }

    function removeLegacyPeripheryContract(bytes32 domain, address peripheryContract) external onlyAdmin {
        if (_peripheryContracts[domain].remove(peripheryContract)) {
            emit RemovePeripheryContract(domain, peripheryContract);
        }
    }

    // --------- //
    // INTERNALS //
    // --------- //

    function _ensureCallerIsCrossChainGovernanceProxy() internal view {
        if (msg.sender != crossChainGovernanceProxy) revert CallerIsNotCrossChainGovernanceProxyException(msg.sender);
    }

    function _grantRole(bytes32 role, address account) internal override {
        super._grantRole(role, account);
        if (role == ROLE_PAUSABLE_ADMIN) IACLLegacy(aclLegacy).addPausableAdmin(account);
        else if (role == ROLE_UNPAUSABLE_ADMIN) IACLLegacy(aclLegacy).addUnpausableAdmin(account);
    }

    function _revokeRole(bytes32 role, address account) internal override {
        super._revokeRole(role, account);
        if (role == ROLE_PAUSABLE_ADMIN) IACLLegacy(aclLegacy).removePausableAdmin(account);
        else if (role == ROLE_UNPAUSABLE_ADMIN) IACLLegacy(aclLegacy).removeUnpausableAdmin(account);
    }

    function _registerMarket(address pool, address priceOracle, address lossPolicy) internal override {
        super._registerMarket(pool, priceOracle, lossPolicy);
        IContractsRegisterLegacy(contractsRegisterLegacy).addPool(pool);
    }

    function _registerCreditSuite(address creditManager) internal override {
        super._registerCreditSuite(creditManager);
        IContractsRegisterLegacy(contractsRegisterLegacy).addCreditManager(creditManager);
    }

    function _validateCallTarget(address target, address factory) internal override {
        super._validateCallTarget(target, factory);
        if (target == aclLegacy || target == contractsRegisterLegacy || target == gearStakingLegacy) {
            revert CallsToLegacyContractsAreForbiddenException();
        }
    }

    function _isV3Contract(address contract_) internal view returns (bool) {
        try IVersion(contract_).version() returns (uint256 version_) {
            return version_ >= 300 && version_ < 400;
        } catch {
            return false;
        }
    }

    function _priceOracle(address creditManager) internal view returns (address) {
        return ICreditManagerV3(creditManager).priceOracle();
    }
}
