// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {IVersion} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IVersion.sol";
import {ICreditFacadeV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditFacadeV3.sol";
import {ICreditManagerV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import {IGearStakingV3, VotingContractStatus} from "@gearbox-protocol/core-v3/contracts/interfaces/IGearStakingV3.sol";
import {IPoolV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPoolV3.sol";

import {IContractsRegister} from "../../interfaces/extensions/IContractsRegister.sol";
import {IContractsRegisterLegacy} from "../../interfaces/extensions/IContractsRegisterLegacy.sol";

import {AP_GEAR_STAKING, NO_VERSION_CONTROL} from "../../libraries/ContractLiterals.sol";
import {HookCheck} from "../../libraries/Hook.sol";

import {MarketConfigurator} from "../MarketConfigurator.sol";

contract MarketConfiguratorLegacy is MarketConfigurator {
    address public immutable gearStaking;
    address public immutable contractsRegisterLegacy;

    error CallerIsNotMarketConfiguratorFactoryException();

    error CreditManagerMisconfiguredException(address creditManager);

    modifier marketConfiguratorFactoryOnly() {
        if (msg.sender != marketConfiguratorFactory) revert CallerIsNotMarketConfiguratorFactoryException();
        _;
    }

    constructor(
        address riskCurator_,
        address addressProvider_,
        address acl_,
        address treasury_,
        address contractsRegisterLegacy_
    ) MarketConfigurator(riskCurator_, addressProvider_, acl_, treasury_) {
        gearStaking = _getContract(AP_GEAR_STAKING, NO_VERSION_CONTROL);
        contractsRegisterLegacy = contractsRegisterLegacy_;

        address[] memory pools = IContractsRegisterLegacy(contractsRegisterLegacy).getPools();
        uint256 numPools = pools.length;
        for (uint256 i; i < numPools; ++i) {
            address pool = pools[i];
            if (!_matchVersion(pool)) continue;

            address[] memory creditManagers = IPoolV3(pool).creditManagers();
            uint256 numCreditManagers = creditManagers.length;
            if (numCreditManagers == 0) continue;

            address priceOracle = _priceOracle(creditManagers[0]);
            IContractsRegister(contractsRegister).createMarket(pool, priceOracle);

            address lossLiquidator = _lossLiquidator(creditManagers[0]);
            if (lossLiquidator != address(0)) {
                IContractsRegister(contractsRegister).setLossLiquidator(pool, lossLiquidator);
            }

            for (uint256 j; j < numCreditManagers; ++j) {
                address creditManager = creditManagers[j];
                if (
                    !_matchVersion(creditManager) || _priceOracle(creditManager) != priceOracle
                        || _lossLiquidator(creditManager) != lossLiquidator
                ) {
                    revert CreditManagerMisconfiguredException(creditManager);
                }

                IContractsRegister(contractsRegister).createCreditSuite(pool, creditManagers[j]);

                // question: check all tokens are quoted etc?
            }

            // TODO: set factories, access lists etc
        }
    }

    function createCreditSuite(address pool, bytes calldata encodedParams)
        public
        override
        onlyOwner
        returns (address)
    {
        address creditManager = super.createCreditSuite(pool, encodedParams);
        IContractsRegisterLegacy(contractsRegisterLegacy).addCreditManager(creditManager);
        return creditManager;
    }

    function setVotingContractStatus(address votingContract, VotingContractStatus status)
        external
        marketConfiguratorFactoryOnly
    {
        // QUESTION: can we check that `votingContract` belongs to caller (it might not even implement `ACLTrait` though)
        IGearStakingV3(gearStaking).setVotingContractStatus(votingContract, status);
    }

    // TODO: add proxy fn for DAO to manage gear staking (e.g., migration etc.)

    // --------- //
    // INTERNALS //
    // --------- //

    function _executeHook(HookCheck memory hookCheck) internal override {
        // TODO: prevent calling gear staking (maybe some other contracts that are managed by old ACL?)
        super._executeHook(hookCheck);
    }

    function _matchVersion(address contract_) internal view returns (bool) {
        try IVersion(contract_).version() returns (uint256 version_) {
            return version_ >= 300 && version_ < 400;
        } catch {
            return false;
        }
    }

    function _priceOracle(address creditManager) internal view returns (address) {
        return ICreditManagerV3(creditManager).priceOracle();
    }

    function _lossLiquidator(address creditManager) internal view returns (address) {
        return ICreditFacadeV3(ICreditManagerV3(creditManager).creditFacade()).lossLiquidator();
    }
}
