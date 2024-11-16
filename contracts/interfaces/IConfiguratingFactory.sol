// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {Call} from "./Types.sol";

interface IConfiguratingFactory {
    error ForbiddenConfigurationCallException(bytes4 selector);

    function configure(address target, bytes calldata callData) external returns (Call[] memory calls);

    // NOTE: can do less harm but can be called by less trusted party
    // can be used instead of controller
    // function manage(address target, bytes calldata callData) external returns (Call[] memory calls);
}
