// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {ICreditManagerV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import {IMarketConfiguratorV3} from "../interfaces/IMarketConfiguratorV3.sol";
import {IContractsRegister} from "../interfaces/IContractsRegister.sol";

import {IAddressProviderV3} from "../interfaces/IAddressProviderV3.sol";
import {
    AddressNotFoundException,
    CallerNotConfiguratorException
} from "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";

import {IBotListV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IBotListV3.sol";
import {IAccountFactoryV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IAccountFactoryV3.sol";
import {IVersion} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IVersion.sol";

import {
    AP_ADDRESS_PROVIDER,
    AP_MARKET_CONFIGURATOR_FACTORY,
    AP_BOT_LIST,
    AP_ACCOUNT_FACTORY,
    NO_VERSION_CONTROL
} from "../libraries/ContractLiterals.sol";

import {LibString} from "@solady/utils/LibString.sol";

/// @title Address provider V3
/// @notice Stores addresses of important contracts
contract AddressProviderV3_1 is Ownable2Step, IAddressProviderV3 {
    using EnumerableSet for EnumerableSet.AddressSet;
    // using LibString for string;
    using LibString for bytes32;

    /// @notice Contract version
    uint256 public constant override version = 3_10;
    bytes32 public constant override contractType = AP_ADDRESS_PROVIDER;

    error MarketConfiguratorsOnlyException();
    error CantRemoveMarketConfiguratorWithExistingPoolsException();
    error MarketConfiguratorNotFoundException();

    /// @notice Keeps market confifgurators
    EnumerableSet.AddressSet internal _marketConfigurators;

    /// @notice Mapping pool => MarketConfigurator
    mapping(address => address) public override marketConfiguratorByPool;

    /// @notice Mapping from (contract key, version) to contract addresses
    mapping(string => mapping(uint256 => address)) public override addresses;

    mapping(string => uint256) public latestVersions;

    modifier marketConfiguratorFactoryOnly() {
        if (msg.sender != getAddressOrRevert(AP_MARKET_CONFIGURATOR_FACTORY, NO_VERSION_CONTROL)) {
            revert MarketConfiguratorsOnlyException();
        }
        _;
    }

    constructor() {
        // The first event is emitted for the address provider itself to aid in contract discovery
        emit SetAddress(AP_ADDRESS_PROVIDER.fromSmallString(), address(this), version);
    }

    /// @notice Returns the address of a contract with a given key and version
    function getAddressOrRevert(string memory key, uint256 _version)
        public
        view
        virtual
        override
        returns (address result)
    {
        result = addresses[key][_version];
        if (result == address(0)) revert AddressNotFoundException();
    }

    /// @notice Returns the address of a contract with a given key and version
    function getAddressOrRevert(bytes32 key, uint256 _version) public view virtual override returns (address result) {
        return getAddressOrRevert(key.fromSmallString(), _version);
    }

    /// @notice Returns the address of a contract with a given key and version
    function getLatestAddressOrRevert(string memory key) public view virtual returns (address result) {
        return getAddressOrRevert(key, latestVersions[key]);
    }

    /// @notice Returns the address of a contract with a given key and version
    function getLatestAddressOrRevert(bytes32 _key) public view virtual returns (address result) {
        string memory key = _key.fromSmallString();
        return getAddressOrRevert(key, latestVersions[key]);
    }

    /// @notice Sets the address for the passed contract key
    /// @param key Contract key
    /// @param value Contract address
    /// @param saveVersion Whether to save contract's version
    function setAddress(string memory key, address value, bool saveVersion) external override onlyOwner {
        _setAddress(key, value, saveVersion ? IVersion(value).version() : NO_VERSION_CONTROL);
    }

    /// @notice Sets the address for the passed contract key
    /// @param addr Contract address
    /// @param saveVersion Whether to save contract's version
    function setAddress(address addr, bool saveVersion) external override onlyOwner {
        _setAddress(
            IVersion(addr).contractType().fromSmallString(),
            addr,
            saveVersion ? IVersion(addr).version() : NO_VERSION_CONTROL
        );
    }

    /// @dev Implementation of `setAddress`

    function _setAddress(string memory key, address value, uint256 _version) internal virtual {
        addresses[key][_version] = value;
        uint256 latestVersion = latestVersions[key];

        if (_version > latestVersion) {
            latestVersions[key] = _version;
        }

        emit SetAddress(key, value, _version);
    }

    modifier marketConfiguratorsOnly() {
        if (!_marketConfigurators.contains(msg.sender)) revert MarketConfiguratorsOnlyException();
        _;
    }

    function addMarketConfigurator(address _marketConfigurator) external override marketConfiguratorFactoryOnly {
        if (!_marketConfigurators.contains(_marketConfigurator)) {
            _marketConfigurators.add(_marketConfigurator);
            emit AddMarketConfigurator(_marketConfigurator);
        }
    }

    function removeMarketConfigurator(address _marketConfigurator) external override marketConfiguratorFactoryOnly {
        if (_marketConfigurators.contains(_marketConfigurator)) {
            _marketConfigurators.add(_marketConfigurator);
            emit RemoveMarketConfigurator(_marketConfigurator);
        }
    }

    function marketConfigurators() external view override returns (address[] memory) {
        return _marketConfigurators.values();
    }

    function isMarketConfigurator(address riskCurator) external view override returns (bool) {
        return _marketConfigurators.contains(riskCurator);
    }

    function registerPool(address pool) external override marketConfiguratorsOnly {
        marketConfiguratorByPool[pool] = msg.sender;
    }

    function registerCreditManager(address creditManager) external override marketConfiguratorsOnly {
        // TODO: make method names more consistent?
        IBotListV3(getLatestAddressOrRevert(AP_BOT_LIST)).approvedCreditManager(creditManager);
        IAccountFactoryV3(getLatestAddressOrRevert(AP_ACCOUNT_FACTORY)).addCreditManager(creditManager);
    }

    // Getters

    function marketConfiguratorByCreditManager(address creditManager) external view override returns (address) {
        address pool = ICreditManagerV3(creditManager).pool();
        address marketConfigurator = marketConfiguratorByPool[pool];
        if (marketConfigurator == address(0)) revert MarketConfiguratorNotFoundException();
        if (
            IContractsRegister(IMarketConfiguratorV3(marketConfigurator).contractsRegister()).isCreditManager(
                creditManager
            )
        ) {
            revert MarketConfiguratorNotFoundException();
        }

        return marketConfigurator;
    }

    function owner() public view override(Ownable, IAddressProviderV3) returns (address) {
        return Ownable.owner();
    }
}
