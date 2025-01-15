// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";

import {CCGHelper} from "../contracts/test/helpers/CCGHelper.sol";
import {GlobalSetup} from "../contracts/test/helpers/GlobalSetup.sol";

contract PermissionlessScript is Script, GlobalSetup {
    function setUp() public {}

    function run() public {
        vm.broadcast();

        _setUpGlobalContracts();

        vm.stopBroadcast();

        // Store address manager state as JSON
        string memory json = vm.serializeAddress("addresses", "instanceManager", address(instanceManager));
        json = vm.serializeAddress("addresses", "bytecodeRepository", address(bytecodeRepository));
        json = vm.serializeAddress("addresses", "multisig", address(multisig));

        vm.writeJson(json, "./deployments/addresses.json");
    }
}
