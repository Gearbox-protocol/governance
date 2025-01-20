// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";

import {CCGHelper} from "../contracts/test/helpers/CCGHelper.sol";
import {GlobalSetup} from "../contracts/test/helpers/GlobalSetup.sol";

import {AP_POOL_FACTORY} from "../contracts/libraries/ContractLiterals.sol";
import {CrossChainCall} from "../contracts/interfaces/Types.sol";

contract CCGTestScript is Script, GlobalSetup {
    function run() public {
        vm.startBroadcast(vm.envUint("DEPLOYER_PRIVATE_KEY"));

        _attachGlobalContracts();

        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = _generateDeploySystemContractCall(AP_POOL_FACTORY, 3_10, true);

        _submitProposal("Testtt", calls);
    }
}
