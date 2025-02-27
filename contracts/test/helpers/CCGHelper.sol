// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {SignatureHelper} from "./SignatureHelper.sol";
import {CrossChainMultisig} from "../../../contracts/global/CrossChainMultisig.sol";
import {CrossChainCall, SignedBatch} from "../../../contracts/interfaces/ICrossChainMultisig.sol";

import {console} from "forge-std/console.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

import {console2} from "forge-std/console2.sol";

contract CCGHelper is SignatureHelper {
    using LibString for bytes;
    using LibString for uint256;
    // Core contracts

    bytes32 constant COMPACT_BATCH_TYPEHASH = keccak256("CompactBatch(string name,bytes32 batchHash,bytes32 prevHash)");

    CrossChainMultisig internal multisig;

    uint256 internal signer1Key;
    uint256 internal signer2Key;

    address internal signer1;
    address internal signer2;

    address internal dao;

    bytes32 prevBatchHash;

    constructor() {
        signer1Key = _generatePrivateKey("SIGNER_1");
        signer2Key = _generatePrivateKey("SIGNER_2");
        signer1 = vm.rememberKey(signer1Key);
        signer2 = vm.rememberKey(signer2Key);
        dao = vm.rememberKey(_generatePrivateKey("DAO"));

        if (!_isTestMode()) {
            // Print debug info
            console.log("Cross chain multisig setup:");
            console.log("Signer 1:", signer1, "Key:", signer1Key.toHexString());
            console.log("Signer 2:", signer2, "Key:", signer2Key.toHexString());
            console.log("DAO:", dao);
        }
    }

    function _isTestMode() internal pure virtual returns (bool) {
        return false;
    }

    function _setUpCCG() internal {
        // Deploy initial contracts
        address[] memory initialSigners = new address[](2);
        initialSigners[0] = signer1;
        initialSigners[1] = signer2;

        // Deploy CrossChainMultisig with 2 signers and threshold of 2
        multisig = new CrossChainMultisig{salt: "SALT"}(
            initialSigners,
            2, // threshold
            dao
        );

        prevBatchHash = 0;
    }

    function _attachCCG() internal {
        address ccg = computeCCGAddress();

        if (ccg.code.length == 0) {
            revert("CCG not deployed");
        }
        multisig = CrossChainMultisig(ccg);

        prevBatchHash = multisig.lastBatchHash();
    }

    function computeCCGAddress() internal view returns (address) {
        address[] memory initialSigners = new address[](2);
        initialSigners[0] = signer1;
        initialSigners[1] = signer2;

        bytes memory creationCode =
            abi.encodePacked(type(CrossChainMultisig).creationCode, abi.encode(initialSigners, 2, dao));

        return Create2.computeAddress(
            bytes32("SALT"), keccak256(creationCode), address(0x4e59b44847b379578588920cA78FbF26c0B4956C)
        );
    }

    function _submitBatch(string memory name, CrossChainCall[] memory calls) internal {
        _startPrankOrBroadcast(dao);
        multisig.submitBatch(name, calls, prevBatchHash);
        _stopPrankOrBroadcast();
    }

    function _signCurrentBatch() internal {
        bytes32[] memory currentBatchHashes = multisig.getCurrentBatchHashes();

        SignedBatch memory currentBatch = multisig.getBatch(currentBatchHashes[0]);

        bytes32 batchHash = multisig.computeBatchHash(currentBatch.name, currentBatch.calls, currentBatch.prevHash);

        bytes32 structHash = multisig.computeCompactBatchHash(currentBatch.name, batchHash, currentBatch.prevHash);

        if (!_isTestMode()) {
            console.log("tt");
            console.logBytes32(structHash);
        }

        bytes memory signature1 = _sign(signer1Key, ECDSA.toTypedDataHash(_ccmDomainSeparator(), structHash));

        multisig.signBatch(batchHash, signature1);
        if (!_isTestMode()) {
            console.log("== SIGNER 1 ==");
            console.log("name", currentBatch.name);
            console.log("batchHash");
            console.logBytes32(batchHash);
            console.log("prevHash");
            console.logBytes32(currentBatch.prevHash);
            console.log(signature1.toHexString());
        }

        bytes memory signature2 = _sign(signer2Key, ECDSA.toTypedDataHash(_ccmDomainSeparator(), structHash));
        multisig.signBatch(batchHash, signature2);

        if (!_isTestMode()) {
            console.log("== SIGNER 2==");
            console.log("name", currentBatch.name);
            console.log(signature2.toHexString());
        }

        prevBatchHash = batchHash;
    }

    function _submitBatchAndSign(string memory name, CrossChainCall[] memory calls) internal {
        _submitBatch(name, calls);
        _signCurrentBatch();
    }

    function _ccmDomainSeparator() internal view returns (bytes32) {
        // Get domain separator from BytecodeRepository contract
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("CROSS_CHAIN_MULTISIG")),
                keccak256(bytes("310")),
                1,
                address(multisig)
            )
        );
    }
}
