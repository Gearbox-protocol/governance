// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IVersion} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IVersion.sol";
import {ICreditManagerV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import {CreditManagerV3} from "@gearbox-protocol/core-v3/contracts/credit/CreditManagerV3.sol";
import {IBytecodeRepository} from "../interfaces/IBytecodeRepository.sol";

import {AbstractFactory} from "./AbstractFactory.sol";
import {
    AP_CREDIT_MANAGER,
    AP_CREDIT_FACADE,
    AP_CREDIT_CONFIGURATOR,
    AP_CREDIT_FACTORY
} from "../libraries/ContractLiterals.sol";
import {IBytecodeRepository} from "../interfaces/IBytecodeRepository.sol";

contract CreditFactoryV3 is AbstractFactory, IVersion {
    /// @notice Contract version
    uint256 public constant override version = 3_10;
    bytes32 public constant override contractType = AP_CREDIT_FACTORY;

    constructor(address _addressProvider) AbstractFactory(_addressProvider) {}

    function deployCreditManager(
        address _pool,
        address _accountFactory,
        address _priceOracle,
        string memory _name,
        uint256 _version,
        bytes32 _salt
    ) external returns (address) {
        bytes memory constructorParams = abi.encode(_pool, _accountFactory, _priceOracle, _pool, _name);

        // FEE_TOKEN_CM

        return IBytecodeRepository(bytecodeRepository).deploy(AP_CREDIT_MANAGER, _version, constructorParams, _salt);
    }

    function deployCreditFacade(
        address _creditManager,
        address _degenNFT,
        bool _expirable,
        uint256 _version,
        bytes32 _salt
    ) external returns (address) {
        bytes memory constructorParams = abi.encode(_creditManager, _degenNFT, _expirable);
        return IBytecodeRepository(bytecodeRepository).deploy(AP_CREDIT_FACADE, _version, constructorParams, _salt);
    }

    function deployCreditConfigurator(address _creditManager, address _creditFacade, uint256 _version, bytes32 _salt)
        external
        returns (address)
    {
        bytes memory constructorParams = abi.encode(_creditManager, _creditFacade); //, CreditManagerOpts memory opts
        address creditConfiguratorAddr = IBytecodeRepository(bytecodeRepository).getAddress(
            AP_CREDIT_CONFIGURATOR, _version, constructorParams, _salt
        );
        if (ICreditManagerV3(_creditManager).creditConfigurator() == address(this)) {
            CreditManagerV3(_creditManager).setCreditConfigurator(creditConfiguratorAddr);
        }

        return
            IBytecodeRepository(bytecodeRepository).deploy(AP_CREDIT_CONFIGURATOR, _version, constructorParams, _salt);
    }
}
