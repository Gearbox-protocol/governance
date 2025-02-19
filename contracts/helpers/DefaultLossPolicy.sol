// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {ILossPolicy} from "@gearbox-protocol/core-v3/contracts/interfaces/base/ILossPolicy.sol";
import {ACLTrait} from "@gearbox-protocol/core-v3/contracts/traits/ACLTrait.sol";
import {AP_LOSS_POLICY_DEFAULT} from "../libraries/ContractLiterals.sol";

contract DefaultLossPolicy is ILossPolicy, ACLTrait {
    uint256 public constant override version = 3_10;
    bytes32 public constant override contractType = AP_LOSS_POLICY_DEFAULT;
    AccessMode public override accessMode = AccessMode.Permissioned;
    bool public override checksEnabled = false;

    // QUESTION: shouldn't it take pool address and AP so that it can be used with loss policy factory?
    // that would make it hard to use in legacy market configurator
    constructor(address acl_) ACLTrait(acl_) {}

    function serialize() external view override returns (bytes memory) {
        return abi.encode(accessMode, checksEnabled);
    }

    function isLiquidatableWithLoss(address, address caller, Params calldata) external view override returns (bool) {
        AccessMode accessMode_ = accessMode;
        if (accessMode_ == AccessMode.Forbidden) return false;
        if (accessMode_ == AccessMode.Permissioned && !_hasRole("LOSS_LIQUIDATOR", caller)) return false;
        return !checksEnabled;
    }

    function setAccessMode(AccessMode mode) external override configuratorOnly {
        if (accessMode == mode) return;
        accessMode = mode;
        emit SetAccessMode(mode);
    }

    function setChecksEnabled(bool enabled) external override configuratorOnly {
        if (checksEnabled == enabled) return;
        checksEnabled = enabled;
        emit SetChecksEnabled(enabled);
    }
}
