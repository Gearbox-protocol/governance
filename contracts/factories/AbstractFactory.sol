// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {IVersion} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IVersion.sol";
import {IVotingContract} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IVotingContract.sol";

import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {IBytecodeRepository} from "../interfaces/IBytecodeRepository.sol";
import {IMarketConfiguratorFactory} from "../interfaces/IMarketConfiguratorFactory.sol";

import {
    AP_BYTECODE_REPOSITORY,
    AP_MARKET_CONFIGURATOR_FACTORY,
    NO_VERSION_CONTROL
} from "../libraries/ContractLiterals.sol";

abstract contract AbstractFactory is IVersion {
    address public immutable addressProvider;
    address public immutable bytecodeRepository;
    address public immutable marketConfiguratorFactory;

    error CallerIsNotMarketConfiguratorException();

    modifier marketConfiguratorsOnly() {
        _ensureCallerIsMarketConfigurator();
        _;
    }

    constructor(address addressProvider_) {
        addressProvider = addressProvider_;
        bytecodeRepository = _getContract(AP_BYTECODE_REPOSITORY, NO_VERSION_CONTROL);
        marketConfiguratorFactory = _getContract(AP_MARKET_CONFIGURATOR_FACTORY, NO_VERSION_CONTROL);
    }

    function _ensureCallerIsMarketConfigurator() internal view {
        if (IMarketConfiguratorFactory(marketConfiguratorFactory).isMarketConfigurator(msg.sender)) {
            revert CallerIsNotMarketConfiguratorException();
        }
    }

    function _getLatestContract(bytes32 key) internal view returns (address) {
        return IAddressProvider(addressProvider).getLatestAddressOrRevert(key);
    }

    function _getContract(bytes32 key, uint256 version_) internal view returns (address) {
        return IAddressProvider(addressProvider).getAddressOrRevert(key, version_);
    }

    function _deploy(bytes32 type_, uint256 version_, bytes memory constructorParams, bytes32 salt)
        internal
        returns (address)
    {
        return IBytecodeRepository(bytecodeRepository).deploy(type_, version_, constructorParams, salt);
    }

    function _deployByDomain(
        bytes32 domain,
        bytes32 postfix,
        uint256 version_,
        bytes memory constructorParams,
        bytes32 salt
    ) internal returns (address) {
        return
            IBytecodeRepository(bytecodeRepository).deployByDomain(domain, postfix, version_, constructorParams, salt);
    }

    function _isVotingContract(address contract_) internal view returns (bool) {
        try IVotingContract(contract_).voter() returns (address) {
            return true;
        } catch {
            return false;
        }
    }
}
