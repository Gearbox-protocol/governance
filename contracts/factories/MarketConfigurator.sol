// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {ACLTrait} from "@gearbox-protocol/core-v3/contracts/traits/ACLTrait.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {PriceOracleFactoryV3} from "../factories/PriceOracleFactoryV3.sol";
import {InterestModelFactory} from "../factories/InterestModelFactory.sol";
import {PoolFactoryV3} from "../factories/PoolFactoryV3.sol";
import {CreditFactoryV3} from "../factories/CreditFactoryV3.sol";
import {AdapterFactoryV3} from "../factories/AdapterFactoryV3.sol";

import {PoolV3} from "@gearbox-protocol/core-v3/contracts/pool/PoolV3.sol";

import {IMarketConfiguratorV3} from "../interfaces/IMarketConfiguratorV3.sol";

import {
    IPriceOracleV3,
    PriceFeedParams,
    PriceUpdate
} from "@gearbox-protocol/core-v3/contracts/interfaces/IPriceOracleV3.sol";
import {ICreditManagerV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import {ICreditConfiguratorV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditConfiguratorV3.sol";
import {IContractsRegister} from "../interfaces/IContractsRegister.sol";
import {IPoolV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPoolV3.sol";
import {IPoolQuotaKeeperV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPoolQuotaKeeperV3.sol";

import {IAddressProviderV3} from "../interfaces/IAddressProviderV3.sol";
import {IContractsRegister} from "../interfaces/IContractsRegister.sol";
import {IACL} from "../interfaces/IACL.sol";

import {ACLOwner} from "./ACLOwner.sol";

import {
    AP_ACCOUNT_FACTORY,
    AP_POOL,
    AP_POOL_QUOTA_KEEPER,
    AP_POOL_RATE_KEEPER,
    AP_PRICE_ORACLE,
    AP_CREDIT_MANAGER,
    AP_CREDIT_FACADE,
    AP_CREDIT_CONFIGURATOR
} from "./ContractLiterals.sol";

contract MarketConfigurator is ACLTrait, IMarketConfiguratorV3 {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Contract version
    uint256 public constant override version = 3_10;

    error InterestModelNotAllowedException(address);

    error PriceFeedIsNotAllowedException(address, address);

    error CantRemoveNonEmptyMarket();

    error DegenNFTNotExistsException(address);

    error DeployAddressCollisionException(address);

    event SetPriceFeedFromStore(address indexed token, address indexed priceFeed, bool trusted);

    event SetReservePriceFeedFromStore(address indexed token, address indexed priceFeedd);

    event SetName(string name);

    event CreateMarket(address indexed pool, address indexed underlying, string _name, string _symbol);

    event RemoveMarket(address indexed pool);

    event DeployDegenNFT(address);

    string public name;

    EnumerableSet.AddressSet internal _adapters;
    EnumerableSet.AddressSet internal _degenNFTs;

    // TODO: should it be pool related?
    EnumerableSet.AddressSet internal _emergencyLiquidators;

    // Mapping: market -> priceOracle
    mapping(address => address) public priceOracles;

    address public immutable override addressProvider;

    address public override treasury;

    address public immutable override contractsRegister;

    address public override interestModelFactory;
    address public override poolFactory;
    address public override creditFactory;
    address public override priceOracleFactory;
    address public override adapterFactory;
    address public override controller;

    mapping(string => uint256) public latestVersions;

    constructor(
        address _addressProvider,
        address _acl,
        address _contractsRegister,
        address _treasury,
        string memory _name,
        address _vetoAdmin
    ) ACLTrait(_acl) {
        addressProvider = _addressProvider;
        acl = _acl;

        contractsRegister = _contractsRegister;
        name = _name;
        treasury = _treasury;

        // controller = new ControllerTimelockV3(_vetoAdmin);
    }

    //
    // POOLS
    //
    function createMarket(
        address underlying,
        uint256 totalLimit,
        address interestModel,
        string memory rateKeeperType,
        string calldata _name,
        string calldata _symbol
    ) external configuratorOnly {
        bytes32 salt = bytes32(uint256(uint160(address(this))));

        if (InterestModelFactory(interestModelFactory).isRegisteredInterestModel(interestModel)) {
            revert InterestModelNotAllowedException(interestModel);
        }
        address pool = PoolFactoryV3(poolFactory).deploy(
            underlying, interestModel, totalLimit, _name, _symbol, latestVersions[AP_POOL], salt
        );

        address pqk = PoolFactoryV3(poolFactory).deployPoolQuotaKeeper(pool, latestVersions[AP_POOL_QUOTA_KEEPER], salt);

        address rateKeeper = PoolFactoryV3(poolFactory).deployRateKeeper(
            pool, rateKeeperType, latestVersions[string.concat(AP_POOL_RATE_KEEPER, "_", rateKeeperType)], salt
        );

        IContractsRegister(contractsRegister).addPool(pool);

        PoolV3(pool).setController(controller);
        PoolV3(pool).setPoolQuotaKeeper(pqk);

        IPoolQuotaKeeperV3(pqk).setGauge(rateKeeper);

        priceOracles[pool] =
            PriceOracleFactoryV3(priceOracleFactory).deployPriceOracle(acl, latestVersions[AP_PRICE_ORACLE], salt);

        emit CreateMarket(pool, underlying, _name, _symbol);
    }

    function removeMarket(address pool) external configuratorOnly {
        if (IPoolV3(pool).totalBorrowed() != 0) revert CantRemoveNonEmptyMarket();
        address[] memory cms = IPoolV3(pool).creditManagers();
        uint256 len = cms.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                IPoolV3(pool).setCreditManagerDebtLimit(cms[i], 0);
            }
        }

        IPoolV3(pool).setTotalDebtLimit(0);
        IPoolV3(pool).setWithdrawFee(0);
        IContractsRegister(contractsRegister).removePool(pool);
        emit RemoveMarket(pool);
    }

    function updateInterestRateModel(address pool, address interestModel) external configuratorOnly {
        // Check that pool is realted to here
        if (InterestModelFactory(interestModelFactory).isRegisteredInterestModel(interestModel)) {
            revert InterestModelNotAllowedException(interestModel);
        }
        IPoolV3(pool).setInterestRateModel(interestModel);
    }

    //
    // CREDIT MANAGER
    //
    function deployCreditManager(address pool, address _degenNFT, uint40 expirationDate, string memory _name)
        external
        configuratorOnly
    {
        if (_degenNFTs.contains(_degenNFT)) {
            revert DegenNFTNotExistsException(_degenNFT);
        }

        bytes32 salt = bytes32(uint256(uint160(address(this))));

        address creditManager = CreditFactoryV3(creditFactory).deployCreditManager(
            pool,
            IAddressProviderV3(addressProvider).getLaterstAddressOrRevert(AP_ACCOUNT_FACTORY),
            priceOracles[pool],
            _name,
            latestVersions[AP_CREDIT_MANAGER], // TODO: Fee token case(?)
            salt
        );

        IAddressProviderV3(addressProvider).addCreditManager(creditManager);

        bool expirable = expirationDate != 0;

        address creditFacade = CreditFactoryV3(creditFactory).deployCreditFacade(
            creditManager, _degenNFT, expirable, latestVersions[AP_CREDIT_FACADE], salt
        );

        address creditConfigurator = CreditFactoryV3(creditFactory).deployCreditConfigurator(
            creditManager, creditFacade, latestVersions[AP_CREDIT_CONFIGURATOR], salt
        );

        address[] memory emergencyLiquidators = _emergencyLiquidators.values();

        // adding emergency liquidators
        uint256 len = emergencyLiquidators.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                _creditConfigurator(creditManager).addEmergencyLiquidator(emergencyLiquidators[i]);
            }
        }

        address pqk = IPoolV3(pool).poolQuotaKeeper();
        IPoolQuotaKeeperV3(pqk).addCreditManager(creditManager);
        IAddressProviderV3(addressProvider).addCreditManager(creditManager);
    }

    function updateCreditFacade(address creditManager, address _degenNFT, bool _expirable, uint256 _version)
        external
        configuratorOnly
    {
        bytes32 salt = bytes32(uint256(uint160(address(this))));
        // Check that credit manager is reristered
        ICreditConfiguratorV3 creditConfigurator = _creditConfigurator(creditManager);
        address newCreditFacade =
            CreditFactoryV3(creditFactory).deployCreditFacade(creditManager, _degenNFT, _expirable, _version, salt);
        creditConfigurator.setCreditFacade(newCreditFacade, true);
    }

    function updateCreditConfigurator(address creditManager, uint256 _version, bytes32 _salt)
        external
        configuratorOnly
    {
        // Check that credit manager is reristered
        ICreditConfiguratorV3 creditConfigurator = _creditConfigurator(creditManager);
        address newCreditConfigurator = CreditFactoryV3(creditFactory).deployCreditConfigurator(
            creditManager, ICreditManagerV3(creditManager).creditFacade(), _version, _salt
        );

        creditConfigurator.upgradeCreditConfigurator(newCreditConfigurator);
    }

    //
    // CREDIT MANAGER
    //
    function addCollateralToken(address creditManager, address token, uint16 liquidationThreshold)
        external
        configuratorOnly
    {
        _creditConfigurator(creditManager).addCollateralToken(token, liquidationThreshold);
    }

    // function setBotList(uint256 newVersion)
    function addEmergencyLiquidator(address pool, address liquidator) external configuratorOnly {
        address[] memory cms = IPoolV3(pool).creditManagers();
        uint256 len = cms.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                _creditConfigurator(cms[i]).addEmergencyLiquidator(liquidator);
            }
        }
    }

    function removeEmergencyLiquidator(address pool, address liquidator) external configuratorOnly {
        address[] memory cms = IPoolV3(pool).creditManagers();
        uint256 len = cms.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                _creditConfigurator(cms[i]).removeEmergencyLiquidator(liquidator);
            }
        }
    }

    function deployDegenNFT() external configuratorOnly {
        // address degenNFT = CreditFactoryV3(creditFactory).deployDegenNFT(acl(), contractsRegister);
        // if (_degenNFTs.contains(degenNFT)) {
        //     revert DeployAddressCollisionException(degenNFT);
        // }
        // _degenNFTs.add(degenNFT);

        // emit DeployDegenNFT(degenNFT);
    }

    //
    // PRICE ORACLE
    //
    function setPriceFeedFromStore(address pool, address token, address priceFeed, bool trusted)
        external
        configuratorOnly
    {
        // Check that pool exists
        if (!PriceOracleFactoryV3(priceOracleFactory).isRegisteredOracle(token, priceFeed)) {
            revert PriceFeedIsNotAllowedException(token, priceFeed);
        }

        IPriceOracleV3(priceOracles[pool]).setPriceFeed(
            token, priceFeed, PriceOracleFactoryV3(priceOracleFactory).stalenessPeriod(priceFeed)
        );

        emit SetPriceFeedFromStore(token, priceFeed, trusted);
    }

    function setReservePriceFeedFromStore(address pool, address token, address priceFeed) external configuratorOnly {
        // Check that pool exists
        if (!PriceOracleFactoryV3(priceOracleFactory).isRegisteredOracle(token, priceFeed)) {
            revert PriceFeedIsNotAllowedException(token, priceFeed);
        }

        IPriceOracleV3(priceOracles[pool]).setReservePriceFeed(
            token, priceFeed, PriceOracleFactoryV3(priceOracleFactory).stalenessPeriod(priceFeed)
        );

        emit SetReservePriceFeedFromStore(token, priceFeed);
    }

    function changePriceOracle(address pool) external configuratorOnly {
        bytes32 salt = bytes32(uint256(uint160(address(this))));

        // Check that prices for all tokens exists
        address oldOracle = priceOracles[pool];
        address newPriceOracle =
            PriceOracleFactoryV3(priceOracleFactory).deployPriceOracle(acl, latestVersions[AP_PRICE_ORACLE], salt);
        address[] memory collateralTokens = IPoolQuotaKeeperV3(IPoolV3(pool).poolQuotaKeeper()).quotedTokens();
        uint256 len = collateralTokens.length;

        unchecked {
            for (uint256 i; i < len; ++i) {
                address token = collateralTokens[i];
                try IPriceOracleV3(oldOracle).priceFeedParams(token) returns (PriceFeedParams memory pfp) {
                    IPriceOracleV3(newPriceOracle).setPriceFeed(token, pfp.priceFeed, pfp.stalenessPeriod);
                } catch {}

                try IPriceOracleV3(oldOracle).reservePriceFeedParams(token) returns (PriceFeedParams memory pfp) {
                    IPriceOracleV3(newPriceOracle).setReservePriceFeed(token, pfp.priceFeed, pfp.stalenessPeriod);
                } catch {}
            }
        }

        address[] memory cms = IPoolV3(pool).creditManagers();
        len = cms.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                _creditConfigurator(cms[i]).setPriceOracle(newPriceOracle);
            }
        }
    }

    /// @dev Adds new adapter from factory to credit manager
    function addAdapter(address creditManager, address target, uint256 _version, bytes calldata specificParams)
        external
        configuratorOnly
    {
        address newAdapter =
            AdapterFactoryV3(adapterFactory).deployAdapter(creditManager, target, _version, specificParams);
        _adapters.add(newAdapter);

        _creditConfigurator(creditManager).allowAdapter(newAdapter);
    }

    //
    // CONTRACT REGISTER
    //

    // Internal functions
    function _creditConfigurator(address creditManager) internal view returns (ICreditConfiguratorV3) {
        return ICreditConfiguratorV3(ICreditManagerV3(creditManager).creditConfigurator());
    }

    function setName(string calldata _newName) external configuratorOnly {
        name = _newName;
        emit SetName(_newName);
    }

    //
    function pools() external view returns (address[] memory) {
        return IContractsRegister(acl).getPools();
    }

    //
    function owner() external view returns (address) {
        return IACL(acl).owner();
    }
}
