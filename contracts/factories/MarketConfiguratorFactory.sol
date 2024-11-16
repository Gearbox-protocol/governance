// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {AbstractFactory} from "./AbstractFactory.sol";
import {MarketConfigurator} from "../market/MarketConfigurator.sol";
import {ACL} from "../market/ACL.sol";
import {ContractsRegister} from "../market/ContractsRegister.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";

import {IBytecodeRepository} from "../interfaces/IBytecodeRepository.sol";
import {IMarketConfiguratorFactory} from "../interfaces/IMarketConfiguratorFactory.sol";

import {AP_MARKET_CONFIGURATOR, AP_MARKET_CONFIGURATOR_FACTORY} from "../libraries/ContractLiterals.sol";

contract MarketConfiguratorFactory is AbstractFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Contract version
    uint256 public constant override version = 3_10;
    bytes32 public constant override contractType = AP_MARKET_CONFIGURATOR_FACTORY;

    uint256 public latestMCversion;

    error CantRemoveMarketConfiguratorWithExistingPoolsException();

    mapping(address => uint8) public targetTypes;
    mapping(uint8 => mapping(uint256 => address)) public adapterDeployers;

    constructor(address addressProvider_) AbstractFactory(addressProvider_) {
        // deploy legacy?
    }

    function createMarketConfigurator(string calldata name) external {
        ACL acl = new ACL();
        // TODO: deploy treasury splitter
        address treasury;

        address marketConfigurator = _deploy({
            type_: AP_MARKET_CONFIGURATOR,
            version_: latestMCversion,
            constructorParams: abi.encode(msg.sender, addressProvider, acl, treasury),
            salt: bytes32(bytes20(msg.sender))
        });

        acl.transferOwnership(marketConfigurator);
    }
}
