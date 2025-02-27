// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {CrossChainMultisigHarness} from "./CrossChainMultisigHarness.sol";
import {CrossChainCall, SignedBatch, SignedRecoveryModeMessage} from "../../interfaces/ICrossChainMultisig.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ICrossChainMultisig} from "../../interfaces/ICrossChainMultisig.sol";
import {console} from "forge-std/console.sol";
import {SignatureHelper} from "../helpers/SignatureHelper.sol";
import {GeneralMock} from "@gearbox-protocol/core-v3/contracts/test/mocks/GeneralMock.sol";

contract CrossChainMultisigTest is Test, SignatureHelper {
    CrossChainMultisigHarness multisig;

    uint256 signer0PrivateKey = _generatePrivateKey("SIGNER_1");
    uint256 signer1PrivateKey = _generatePrivateKey("SIGNER_2");
    address[] signers;
    uint8 constant THRESHOLD = 2;
    address owner;

    bytes32 COMPACT_BATCH_TYPEHASH = keccak256("CompactBatch(string name,bytes32 batchHash,bytes32 prevHash)");
    bytes32 RECOVERY_MODE_TYPEHASH = keccak256("RecoveryMode(bytes32 startingBatchHash)");

    function setUp() public {
        // Setup initial signers
        signers = new address[](3);
        signers[0] = vm.addr(signer0PrivateKey);
        signers[1] = vm.addr(signer1PrivateKey);
        signers[2] = makeAddr("signer3");

        owner = makeAddr("owner");

        // Deploy contract
        multisig = new CrossChainMultisigHarness(signers, THRESHOLD, owner);
    }

    function _getDigest(bytes32 structHash) internal view returns (bytes32) {
        bytes32 domainSeparator = multisig.domainSeparatorV4();
        return ECDSA.toTypedDataHash(domainSeparator, structHash);
    }

    function _signBatch(uint256 privateKey, CrossChainCall[] memory calls, bytes32 prevHash)
        internal
        view
        returns (bytes memory)
    {
        bytes32 batchHash = multisig.computeBatchHash("test", calls, prevHash);
        bytes32 structHash = _getDigest(batchHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, structHash);
        return abi.encodePacked(r, s, v);
    }

    function _signBatchHash(uint256 privateKey, bytes32 structHash) internal view returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, _getDigest(structHash));
        return abi.encodePacked(r, s, v);
    }

    /// @dev U:[SM-1]: Initial state is correct
    function test_CCG_01_InitialState() public {
        assertEq(multisig.confirmationThreshold(), THRESHOLD);
        assertEq(multisig.lastBatchHash(), bytes32(0));
        assertEq(multisig.owner(), owner);

        // Verify all signers were added
        for (uint256 i = 0; i < signers.length; i++) {
            assertTrue(multisig.isSigner(signers[i]));
        }

        // Check events emitted during deployment
        vm.expectEmit(true, false, false, false);
        emit ICrossChainMultisig.AddSigner(signers[0]);

        vm.expectEmit(true, false, false, false);
        emit ICrossChainMultisig.AddSigner(signers[1]);

        vm.expectEmit(true, false, false, false);
        emit ICrossChainMultisig.AddSigner(signers[2]);

        vm.expectEmit(false, false, false, true);
        emit ICrossChainMultisig.SetConfirmationThreshold(THRESHOLD);

        // Re-deploy to verify events
        new CrossChainMultisigHarness(signers, THRESHOLD, owner);
    }

    /// @dev U:[SM-2]: Access modifiers work correctly
    function test_CCG_02_AccessModifiers() public {
        // Test onlyOnMainnet modifier
        vm.chainId(5); // Set to non-mainnet chain
        vm.startPrank(owner);
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 1, target: address(0x123), callData: hex"1234"});
        vm.expectRevert(ICrossChainMultisig.CantBeExecutedOnCurrentChainException.selector);
        multisig.submitBatch("test", calls, bytes32(0));

        vm.expectRevert(ICrossChainMultisig.CantBeExecutedOnCurrentChainException.selector);
        multisig.signBatch(bytes32(0), new bytes(65));
        vm.stopPrank();

        // Test onlyOnNotMainnet modifier
        vm.chainId(1);
        vm.expectRevert(ICrossChainMultisig.CantBeExecutedOnCurrentChainException.selector);
        multisig.executeBatch(
            SignedBatch({name: "test", calls: calls, prevHash: bytes32(0), signatures: new bytes[](0)})
        );

        // Test onlySelf modifier
        vm.expectRevert(abi.encodeWithSelector(ICrossChainMultisig.CallerIsNotSelfException.selector, address(this)));
        multisig.addSigner(address(0x123));

        vm.expectRevert(abi.encodeWithSelector(ICrossChainMultisig.CallerIsNotSelfException.selector, address(this)));
        multisig.removeSigner(signers[0]);

        vm.expectRevert(abi.encodeWithSelector(ICrossChainMultisig.CallerIsNotSelfException.selector, address(this)));
        multisig.setConfirmationThreshold(3);

        vm.expectRevert(abi.encodeWithSelector(ICrossChainMultisig.CallerIsNotSelfException.selector, address(this)));
        multisig.disableRecoveryMode();

        // Test onlyOwner modifier
        vm.prank(makeAddr("notOwner"));
        vm.expectRevert("Ownable: caller is not the owner");
        multisig.submitBatch("test", calls, bytes32(0));
    }

    /// @dev U:[SM-3]: Submit batch works correctly
    function test_CCG_03_SubmitBatch() public {
        vm.chainId(1); // Set to mainnet

        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 1, target: address(0x123), callData: hex"1234"});

        bytes32 expectedBatchHash = multisig.computeBatchHash("test", calls, bytes32(0));

        vm.expectEmit(true, true, true, true);
        emit ICrossChainMultisig.SubmitBatch(expectedBatchHash);

        vm.prank(owner);
        multisig.submitBatch("test", calls, bytes32(0));

        SignedBatch memory batch = multisig.getBatch(expectedBatchHash);
        assertEq(batch.calls.length, 1);
        assertEq(batch.prevHash, bytes32(0));
        assertEq(batch.signatures.length, 0);

        // submit the same batch again doesn't change calls
        vm.prank(owner);
        multisig.submitBatch("test", calls, bytes32(0));

        batch = multisig.getBatch(expectedBatchHash);
        assertEq(batch.calls.length, 1);
        assertEq(batch.prevHash, bytes32(0));
        assertEq(batch.signatures.length, 0);
    }

    function test_CCG_04_RevertOnInvalidPrevHash() public {
        vm.chainId(1);
        vm.startPrank(owner);

        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 1, target: address(0x123), callData: hex"1234"});

        vm.expectRevert(ICrossChainMultisig.InvalidPrevHashException.selector);
        multisig.submitBatch("test", calls, bytes32(uint256(1))); // Invalid prevHash
    }

    function test_CCG_05_RevertOnEmptyCalls() public {
        vm.chainId(1);
        vm.startPrank(owner);

        CrossChainCall[] memory calls = new CrossChainCall[](0);

        vm.expectRevert(ICrossChainMultisig.InvalidBatchException.selector);
        multisig.submitBatch("test", calls, bytes32(0));
    }

    /// @dev U:[SM-6]: Sign batch works correctly with single signature
    function test_CCG_06_SignBatch() public {
        vm.chainId(1); // Set to mainnet

        // Submit batch
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 1, target: address(0x123), callData: hex"1234"});

        vm.prank(owner);
        multisig.submitBatch("test", calls, bytes32(0));
        bytes32 batchHash = multisig.computeBatchHash("test", calls, bytes32(0));

        console.log(signers[0]);
        console.logBytes32(batchHash);

        bytes32 structHash =
            keccak256(abi.encode(COMPACT_BATCH_TYPEHASH, keccak256(bytes("test")), batchHash, bytes32(0)));

        // Generate EIP-712 signature
        bytes memory signature = _signBatchHash(signer0PrivateKey, structHash);

        // Sign with first signer
        multisig.signBatch(batchHash, signature);

        // Verify batch state after signing
        SignedBatch memory batch = multisig.getBatch(batchHash);
        assertEq(batch.signatures.length, 1);
        assertEq(batch.signatures[0], signature);

        // Verify batch was not executed since threshold not met
        assertEq(multisig.lastBatchHash(), bytes32(0));
    }

    /// @dev U:[SM-7]: Sign batch reverts when signing with invalid signature
    function test_CCG_07_SignBatchInvalidSignature() public {
        vm.chainId(1);

        // Submit batch
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 1, target: address(0x123), callData: hex"1234"});

        vm.prank(owner);
        multisig.submitBatch("test", calls, bytes32(0));
        bytes32 batchHash = multisig.computeBatchHash("test", calls, bytes32(0));

        // Try to sign with invalid signature
        bytes memory invalidSig = hex"1234";
        vm.expectRevert("ECDSA: invalid signature length");
        multisig.signBatch(batchHash, invalidSig);
    }

    /// @dev U:[SM-8]: Sign batch reverts when signing non-existent batch
    function test_CCG_08_SignBatchNonExistentBatch() public {
        vm.chainId(1);

        // Set last batch hash to 1, to avoid ambiguity that default value of 0 is a valid batch hash
        multisig.setLastBatchHash(bytes32(uint256(1)));

        bytes32 nonExistentHash = keccak256("non-existent");
        bytes memory signature = _signBatchHash(signer0PrivateKey, nonExistentHash);

        vm.expectRevert(
            abi.encodeWithSelector(ICrossChainMultisig.BatchIsNotSubmittedException.selector, nonExistentHash)
        );
        multisig.signBatch(nonExistentHash, signature);
    }

    /// @dev U:[SM-9]: Sign batch reverts when same signer signs twice
    function test_CCG_09_SignBatchDuplicateSigner() public {
        vm.chainId(1);

        // Submit batch
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 1, target: address(0x123), callData: hex"1234"});

        vm.prank(owner);
        multisig.submitBatch("test", calls, bytes32(0));
        bytes32 batchHash = multisig.computeBatchHash("test", calls, bytes32(0));

        bytes32 structHash =
            keccak256(abi.encode(COMPACT_BATCH_TYPEHASH, keccak256(bytes("test")), batchHash, bytes32(0)));

        // Sign first time
        bytes memory signature = _signBatchHash(signer0PrivateKey, structHash);
        multisig.signBatch(batchHash, signature);

        // Try to sign again with same signer
        vm.expectRevert(abi.encodeWithSelector(ICrossChainMultisig.DuplicateSignatureException.selector, signers[0]));
        multisig.signBatch(batchHash, signature);
    }

    /// @dev U:[SM-10]: Sign and execute proposal works correctly
    function test_CCG_11_SignAndExecuteProposal() public {
        vm.chainId(1); // Set to mainnet

        // Submit proposal
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({
            chainId: 0,
            target: address(multisig),
            callData: abi.encodeWithSelector(ICrossChainMultisig.setConfirmationThreshold.selector, 3)
        });

        vm.prank(owner);
        multisig.submitBatch("test", calls, bytes32(0));
        bytes32 batchHash = multisig.computeBatchHash("test", calls, bytes32(0));

        bytes32 structHash =
            keccak256(abi.encode(COMPACT_BATCH_TYPEHASH, keccak256(bytes("test")), batchHash, bytes32(0)));

        // Sign with first signer
        bytes memory sig0 = _signBatchHash(signer0PrivateKey, structHash);
        multisig.signBatch(batchHash, sig0);

        // Sign with second signer which should trigger execution
        // Check events emitted during execution
        vm.expectEmit(true, true, true, true);
        emit ICrossChainMultisig.SignBatch(batchHash, vm.addr(signer1PrivateKey));

        vm.expectEmit(true, true, true, true);
        emit ICrossChainMultisig.ExecuteBatch(batchHash);
        bytes memory sig1 = _signBatchHash(signer1PrivateKey, structHash);
        multisig.signBatch(batchHash, sig1);

        // Verify batch was executed
        assertEq(multisig.lastBatchHash(), batchHash, "lastBatchHash");
        assertEq(multisig.getExecutedBatchHashes()[0], batchHash, "executedBatchHashes");
    }

    /// @dev U:[SM-12]: _verifyBatch reverts if prevHash doesn't match lastBatchHash
    function test_CCG_12_VerifyBatchInvalidPrevHash() public {
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 1, target: address(0x123), callData: hex"1234"});

        bytes32 invalidPrevHash = keccak256("invalid");
        vm.expectRevert(ICrossChainMultisig.InvalidPrevHashException.selector);
        multisig.exposed_verifyBatch(calls, invalidPrevHash);
    }

    /// @dev U:[SM-13]: _verifyBatch reverts if calls array is empty
    function test_CCG_13_VerifyBatchEmptyCalls() public {
        CrossChainCall[] memory calls = new CrossChainCall[](0);

        vm.expectRevert(ICrossChainMultisig.InvalidBatchException.selector);
        multisig.exposed_verifyBatch(calls, bytes32(0));
    }

    /// @dev U:[SM-14]: _verifyBatch reverts if trying to call self on other chain
    function test_CCG_14_VerifyBatchSelfCallOtherChain() public {
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        // Try to call the multisig contract itself on another chain
        calls[0] = CrossChainCall({
            chainId: 5, // Goerli chain ID
            target: address(multisig),
            callData: hex"1234"
        });

        vm.expectRevert(ICrossChainMultisig.InvalidBatchException.selector);
        multisig.exposed_verifyBatch(calls, bytes32(0));
    }

    /// @dev U:[SM-15]: _verifyBatch succeeds with valid calls
    function test_CCG_15_VerifyBatchValidCalls() public view {
        CrossChainCall[] memory calls = new CrossChainCall[](3);

        // Valid call on same chain
        calls[0] = CrossChainCall({chainId: 0, target: address(multisig), callData: hex"1234"});

        // Valid call to different contract on another chain
        calls[1] = CrossChainCall({chainId: 5, target: address(0x123), callData: hex"5678"});

        // Valid call to different contract on same chain
        calls[2] = CrossChainCall({chainId: 0, target: address(0x456), callData: hex"9abc"});

        // Should not revert
        multisig.exposed_verifyBatch(calls, bytes32(0));
    }

    /// @dev U:[SM-16]: _verifySignatures returns 0 for empty signatures array
    function test_CCG_16_VerifySignaturesEmptyArray() public view {
        bytes[] memory signatures = new bytes[](0);
        bytes32 batchHash = keccak256("test");

        uint256 validCount = multisig.exposed_verifySignatures(signatures, batchHash);
        assertEq(validCount, 0);
    }

    /// @dev U:[SM-17]: _verifySignatures correctly counts valid signatures
    function test_CCG_17_VerifySignaturesValidSignatures() public {
        vm.chainId(1); // Set to mainnet
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 1, target: address(0x123), callData: hex"1234"});

        vm.prank(owner);
        multisig.submitBatch("test", calls, bytes32(0));
        bytes32 batchHash = multisig.computeBatchHash("test", calls, bytes32(0));

        bytes32 structHash =
            keccak256(abi.encode(COMPACT_BATCH_TYPEHASH, keccak256(bytes("test")), batchHash, bytes32(0)));

        // Create array with 2 valid signatures
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = _signBatchHash(signer0PrivateKey, structHash);
        signatures[1] = _signBatchHash(signer1PrivateKey, structHash);

        uint256 validCount = multisig.exposed_verifySignatures(signatures, _getDigest(structHash));
        assertEq(validCount, 2);
    }

    /// @dev U:[SM-18]: _verifySignatures ignores invalid signatures
    function test_CCG_18_VerifySignaturesInvalidSignatures() public {
        vm.chainId(1); // Set to mainnet
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 1, target: address(0x123), callData: hex"1234"});

        vm.prank(owner);
        multisig.submitBatch("test", calls, bytes32(0));
        bytes32 batchHash = multisig.computeBatchHash("test", calls, bytes32(0));

        bytes32 structHash =
            keccak256(abi.encode(COMPACT_BATCH_TYPEHASH, keccak256(bytes("test")), batchHash, bytes32(0)));

        // Create array with 1 valid and 1 invalid signature
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = _signBatchHash(signer0PrivateKey, structHash);

        // Create invalid signature by signing different hash
        signatures[1] = _signBatchHash(signer1PrivateKey, keccak256("wrong hash"));

        uint256 validCount = multisig.exposed_verifySignatures(signatures, _getDigest(structHash));
        assertEq(validCount, 1);
    }
    /// @dev U:[SM-19]: _verifySignatures reverts with DuplicateSignatureException on duplicate signatures from same signer

    function test_CCG_19_VerifySignaturesDuplicateSigner() public {
        vm.chainId(1); // Set to mainnet
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 1, target: address(0x123), callData: hex"1234"});

        vm.prank(owner);
        multisig.submitBatch("test", calls, bytes32(0));
        bytes32 batchHash = multisig.computeBatchHash("test", calls, bytes32(0));

        bytes32 structHash =
            keccak256(abi.encode(COMPACT_BATCH_TYPEHASH, keccak256(bytes("test")), batchHash, bytes32(0)));

        // Create array with 2 signatures from same signer
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = _signBatchHash(signer0PrivateKey, structHash);
        signatures[1] = _signBatchHash(signer0PrivateKey, structHash);

        bytes32 digest = _getDigest(structHash);

        vm.expectRevert(abi.encodeWithSelector(ICrossChainMultisig.DuplicateSignatureException.selector, signers[0]));
        multisig.exposed_verifySignatures(signatures, digest);
    }

    /// @dev U:[SM-20]: _verifySignatures ignores signatures from non-signers
    function test_CCG_20_VerifySignaturesNonSigner() public {
        vm.chainId(1); // Set to mainnet
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 1, target: address(0x123), callData: hex"1234"});

        vm.prank(owner);
        multisig.submitBatch("test", calls, bytes32(0));
        bytes32 batchHash = multisig.computeBatchHash("test", calls, bytes32(0));

        bytes32 structHash =
            keccak256(abi.encode(COMPACT_BATCH_TYPEHASH, keccak256(bytes("test")), batchHash, bytes32(0)));

        // Create random non-signer private key
        uint256 nonSignerKey = uint256(keccak256("non-signer"));

        bytes[] memory signatures = new bytes[](2);
        signatures[0] = _signBatchHash(signer0PrivateKey, structHash); // Valid signer
        signatures[1] = _signBatchHash(nonSignerKey, structHash); // Non-signer

        uint256 validCount = multisig.exposed_verifySignatures(signatures, _getDigest(structHash));
        assertEq(validCount, 1);
    }

    /// @dev U:[SM-21]: _verifySignatures reverts on malformed signatures
    function test_CCG_21_VerifySignaturesMalformedSignature() public {
        bytes32 batchHash = keccak256("test");

        bytes[] memory signatures = new bytes[](2);
        signatures[0] = _signBatchHash(signer0PrivateKey, batchHash); // Valid signature
        signatures[1] = hex"1234"; // Malformed signature

        vm.expectRevert("ECDSA: invalid signature length");
        multisig.exposed_verifySignatures(signatures, batchHash);
    }

    /// @dev U:[SM-22]: Recovery mode can be enabled with valid signatures
    function test_CCG_22_EnableRecoveryMode() public {
        vm.chainId(5); // Set to non-mainnet chain

        address payable calledContract = payable(new GeneralMock());

        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 5, target: calledContract, callData: hex"1234"});

        SignedBatch memory batch =
            SignedBatch({name: "test", calls: calls, prevHash: bytes32(0), signatures: new bytes[](2)});

        bytes32 batchHash = multisig.computeBatchHash("test", calls, bytes32(0));
        bytes32 structHash =
            keccak256(abi.encode(COMPACT_BATCH_TYPEHASH, keccak256(bytes("test")), batchHash, bytes32(0)));

        batch.signatures[0] = _signBatchHash(signer0PrivateKey, structHash);
        batch.signatures[1] = _signBatchHash(signer1PrivateKey, structHash);

        multisig.executeBatch(batch);

        bytes32 recoveryHash = keccak256(abi.encode(RECOVERY_MODE_TYPEHASH, batchHash));

        bytes[] memory signatures = new bytes[](2);
        signatures[0] = _signBatchHash(signer0PrivateKey, recoveryHash);
        signatures[1] = _signBatchHash(signer1PrivateKey, recoveryHash);

        vm.expectEmit(true, false, false, false);
        emit ICrossChainMultisig.EnableRecoveryMode(batchHash);

        multisig.enableRecoveryMode(SignedRecoveryModeMessage({startingBatchHash: batchHash, signatures: signatures}));

        assertTrue(multisig.isRecoveryModeEnabled());
    }

    /// @dev U:[SM-23]: Recovery mode skips batch execution except for lastBatchHash update
    function test_CCG_23_RecoveryModeSkipsExecution() public {
        vm.chainId(5); // Set to non-mainnet chain

        address payable calledContract = payable(new GeneralMock());

        // First submit and execute a batch to have non-zero lastBatchHash
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 5, target: calledContract, callData: hex"1234"});

        SignedBatch memory batch =
            SignedBatch({name: "test", calls: calls, prevHash: bytes32(0), signatures: new bytes[](2)});

        bytes32 batchHash = multisig.computeBatchHash("test", calls, bytes32(0));
        bytes32 structHash =
            keccak256(abi.encode(COMPACT_BATCH_TYPEHASH, keccak256(bytes("test")), batchHash, bytes32(0)));

        batch.signatures[0] = _signBatchHash(signer0PrivateKey, structHash);
        batch.signatures[1] = _signBatchHash(signer1PrivateKey, structHash);

        multisig.executeBatch(batch);

        // Enable recovery mode
        bytes32 recoveryHash = keccak256(abi.encode(RECOVERY_MODE_TYPEHASH, batchHash));
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = _signBatchHash(signer0PrivateKey, recoveryHash);
        signatures[1] = _signBatchHash(signer1PrivateKey, recoveryHash);

        multisig.enableRecoveryMode(SignedRecoveryModeMessage({startingBatchHash: batchHash, signatures: signatures}));

        calledContract = payable(new GeneralMock());

        CrossChainCall[] memory calls2 = new CrossChainCall[](1);
        calls2[0] = CrossChainCall({chainId: 5, target: calledContract, callData: hex"5678"});

        SignedBatch memory batch2 =
            SignedBatch({name: "test2", calls: calls2, prevHash: batchHash, signatures: new bytes[](2)});

        bytes32 batchHash2 = multisig.computeBatchHash("test2", calls2, batchHash);
        bytes32 structHash2 =
            keccak256(abi.encode(COMPACT_BATCH_TYPEHASH, keccak256(bytes("test2")), batchHash2, batchHash));

        batch2.signatures[0] = _signBatchHash(signer0PrivateKey, structHash2);
        batch2.signatures[1] = _signBatchHash(signer1PrivateKey, structHash2);

        multisig.executeBatch(batch2);

        // Verify lastBatchHash was updated but call wasn't executed
        assertEq(multisig.lastBatchHash(), batchHash2);
        assertTrue(multisig.isRecoveryModeEnabled());
        assertEq(GeneralMock(calledContract).data().length, 0);
    }

    /// @dev U:[SM-24]: Recovery mode can be disabled through a batch with correct first call
    function test_CCG_24_DisableRecoveryMode() public {
        vm.chainId(5); // Set to non-mainnet chain

        address payable calledContract = payable(new GeneralMock());

        // First submit and execute a batch to have non-zero lastBatchHash
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 5, target: calledContract, callData: hex"1234"});

        SignedBatch memory batch =
            SignedBatch({name: "test", calls: calls, prevHash: bytes32(0), signatures: new bytes[](2)});

        bytes32 batchHash = multisig.computeBatchHash("test", calls, bytes32(0));
        bytes32 structHash =
            keccak256(abi.encode(COMPACT_BATCH_TYPEHASH, keccak256(bytes("test")), batchHash, bytes32(0)));

        batch.signatures[0] = _signBatchHash(signer0PrivateKey, structHash);
        batch.signatures[1] = _signBatchHash(signer1PrivateKey, structHash);

        multisig.executeBatch(batch);

        // Enable recovery mode
        bytes32 recoveryHash = keccak256(abi.encode(RECOVERY_MODE_TYPEHASH, batchHash));
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = _signBatchHash(signer0PrivateKey, recoveryHash);
        signatures[1] = _signBatchHash(signer1PrivateKey, recoveryHash);

        multisig.enableRecoveryMode(SignedRecoveryModeMessage({startingBatchHash: batchHash, signatures: signatures}));

        calledContract = payable(new GeneralMock());

        // Now submit a batch that disables recovery mode
        CrossChainCall[] memory calls2 = new CrossChainCall[](2);
        calls2[0] = CrossChainCall({
            chainId: 0,
            target: address(multisig),
            callData: abi.encodeWithSelector(ICrossChainMultisig.disableRecoveryMode.selector)
        });
        calls2[1] = CrossChainCall({chainId: 5, target: calledContract, callData: hex"1234"});

        SignedBatch memory batch2 =
            SignedBatch({name: "test2", calls: calls2, prevHash: batchHash, signatures: new bytes[](2)});

        bytes32 batchHash2 = multisig.computeBatchHash("test2", calls2, batchHash);
        bytes32 structHash2 =
            keccak256(abi.encode(COMPACT_BATCH_TYPEHASH, keccak256(bytes("test2")), batchHash2, batchHash));

        batch2.signatures[0] = _signBatchHash(signer0PrivateKey, structHash2);
        batch2.signatures[1] = _signBatchHash(signer1PrivateKey, structHash2);

        vm.expectEmit(false, false, false, true);
        emit ICrossChainMultisig.DisableRecoveryMode();

        multisig.executeBatch(batch2);

        // Verify recovery mode was disabled and both calls were executed
        assertFalse(multisig.isRecoveryModeEnabled());
        assertEq(multisig.lastBatchHash(), batchHash2);
        assertEq(GeneralMock(calledContract).data(), hex"1234");
    }

    /// @dev U:[SM-25]: Recovery mode cannot be enabled with invalid starting batch hash
    function test_CCG_25_EnableRecoveryModeInvalidStartingHash() public {
        vm.chainId(5); // Set to non-mainnet chain

        // Try to enable recovery mode with wrong starting hash
        bytes32 wrongHash = keccak256("wrong");
        bytes32 recoveryHash = keccak256(abi.encode(RECOVERY_MODE_TYPEHASH, wrongHash));

        bytes[] memory signatures = new bytes[](2);
        signatures[0] = _signBatchHash(signer0PrivateKey, recoveryHash);
        signatures[1] = _signBatchHash(signer1PrivateKey, recoveryHash);

        vm.expectRevert(ICrossChainMultisig.InvalidRecoveryModeMessageException.selector);
        multisig.enableRecoveryMode(SignedRecoveryModeMessage({startingBatchHash: wrongHash, signatures: signatures}));
    }

    /// @dev U:[SM-26]: Recovery mode cannot be enabled with insufficient signatures
    function test_CCG_26_EnableRecoveryModeInsufficientSignatures() public {
        vm.chainId(5); // Set to non-mainnet chain

        address payable calledContract = payable(new GeneralMock());

        // First submit and execute a batch to have non-zero lastBatchHash
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 5, target: calledContract, callData: hex"1234"});

        SignedBatch memory batch =
            SignedBatch({name: "test", calls: calls, prevHash: bytes32(0), signatures: new bytes[](2)});

        bytes32 batchHash = multisig.computeBatchHash("test", calls, bytes32(0));
        bytes32 structHash =
            keccak256(abi.encode(COMPACT_BATCH_TYPEHASH, keccak256(bytes("test")), batchHash, bytes32(0)));

        batch.signatures[0] = _signBatchHash(signer0PrivateKey, structHash);
        batch.signatures[1] = _signBatchHash(signer1PrivateKey, structHash);

        multisig.executeBatch(batch);

        // Try to enable recovery mode with only one signature
        bytes32 recoveryHash = keccak256(abi.encode(RECOVERY_MODE_TYPEHASH, batchHash));

        bytes[] memory signatures = new bytes[](1);
        signatures[0] = _signBatchHash(signer0PrivateKey, recoveryHash);

        vm.expectRevert(ICrossChainMultisig.InsufficientNumberOfSignaturesException.selector);
        multisig.enableRecoveryMode(SignedRecoveryModeMessage({startingBatchHash: batchHash, signatures: signatures}));
    }

    function test_CCG_27_cannot_reduce_signers_below_threshold() public {
        vm.prank(address(multisig));
        multisig.removeSigner(signers[0]);

        vm.expectRevert(ICrossChainMultisig.InvalidConfirmationThresholdException.selector);
        vm.prank(address(multisig));
        multisig.removeSigner(signers[1]);
    }
}
