// SPDX-License-Identifier: BUSL-1.1
// Gearbox. Generalized leverage protocol that allows to take leverage and then use it across other DeFi protocols and platforms in a composable way.
// (c) Gearbox Holdings, 2022

import "@openzeppelin/contracts/utils/Create2.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity 0.8.17;

/// @title Create2Factory
/// @notice Deploys contract from bytecode and salt using create2
contract Create2Factory is Ownable {
    function callExternal(address target, bytes calldata data) external onlyOwner {
        (bool success,) = target.call(data);
        require(success, "External call failed");
    }

    function deploy(bytes32 salt, bytes calldata bytecode) external onlyOwner {
        Create2.deploy(0, salt, bytecode);
    }
}