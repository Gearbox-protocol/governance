// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {AbstractFactory} from "./AbstractFactory.sol";
import {MarketHookFactory} from "./MarketHookFactory.sol";
import {IInterestRateModelFactory} from "../interfaces/IInterestRateModelFactory.sol";
import {AP_INTEREST_MODEL_FACTORY, DOMAIN_IRM} from "../libraries/ContractLiterals.sol";
import {Call, DeployParams, DeployResult} from "../interfaces/Types.sol";
import {IBytecodeRepository} from "../interfaces/IBytecodeRepository.sol";
import {IMarketConfigurator} from "../interfaces/IMarketConfigurator.sol";

contract InterestRateModelFactory is AbstractFactory, MarketHookFactory, IInterestRateModelFactory {
    /// @notice Contract version
    uint256 public constant override version = 3_10;

    /// @notice Contract type
    bytes32 public constant override contractType = AP_INTEREST_MODEL_FACTORY;

    error InvalidConstructorParamsException();

    constructor(address _addressProvider) AbstractFactory(_addressProvider) {}

    // @dev Deploy new interest rate model
    // @param acl - ACL address
    // @param postfix - postfix for the interest rate model
    // @param encodedParams - encoded parameters for the interest rate model
    // @return result - deploy result
    function deployInterestRateModel(address pool, DeployParams calldata params)
        external
        override
        returns (DeployResult memory)
    {
        if (params.postfix != "IRM_LINEAR") {
            (address decodedAddressProvider, address decodedPool) =
                abi.decode(params.constructorParams[:64], (address, address));
            if (decodedAddressProvider != addressProvider || decodedPool != pool) {
                revert InvalidConstructorParamsException();
            }
        }

        address irm = _deployByDomain({
            domain: DOMAIN_IRM,
            postfix: params.postfix,
            version_: version,
            constructorParams: params.constructorParams,
            salt: bytes32(bytes20(msg.sender))
        });

        address[] memory accessList = new address[](1);
        accessList[0] = irm;

        // TODO:
        // if (_isVotingContract()) add onInstallOps

        return DeployResult({newContract: irm, accessList: accessList, onInstallOps: new Call[](0)});
    }

    // @dev Hook which is called when interest rate model is configured
    // @param irm - interest rate model address
    // @param callData - call data to be executed
    // @return calls - array of calls to be executed
    function configure(address irm, bytes calldata callData) external view returns (Call[] memory calls) {
        // TODO: implement
        // just forbid setController?
    }
}
