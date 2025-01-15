// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {CrossChainMultisigHarness} from "./CrossChainMultisigHarness.sol";
import {CrossChainCall, SignedProposal} from "../../interfaces/ICrossChainMultisig.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ICrossChainMultisig} from "../../interfaces/ICrossChainMultisig.sol";
import {console} from "forge-std/console.sol";

contract CrossChainMultisigTest is Test {
    CrossChainMultisigHarness multisig;

    uint256 signer0PrivateKey = vm.randomUint();
    uint256 signer1PrivateKey = vm.randomUint();
    address[] signers;
    uint8 constant THRESHOLD = 2;
    address owner;

    bytes32 constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 constant CROSS_CHAIN_CALL_TYPEHASH =
        keccak256("CrossChainCall(uint256 chainId,address target,bytes callData)");
    bytes32 constant PROPOSAL_TYPEHASH = keccak256("Proposal(bytes32 proposalHash,bytes32 prevHash)");

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
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

    function _signProposal(uint256 privateKey, CrossChainCall[] memory calls, bytes32 prevHash)
        internal
        view
        returns (bytes memory)
    {
        bytes32 proposalHash = multisig.hashProposal("test", calls, prevHash);
        bytes32 digest = _getDigest(proposalHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        return abi.encodePacked(r, s, v);
    }

    function _signProposalHash(uint256 privateKey, bytes32 proposalHash) internal view returns (bytes memory) {
        bytes32 digest = _getDigest(proposalHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        return abi.encodePacked(r, s, v);
    }

    /// @dev U:[SM-1]: Initial state is correct
    function test_CCG_01_InitialState() public {
        assertEq(multisig.confirmationThreshold(), THRESHOLD);
        assertEq(multisig.lastProposalHash(), bytes32(0));
        assertEq(multisig.owner(), owner);

        // Verify all signers were added
        for (uint256 i = 0; i < signers.length; i++) {
            assertTrue(multisig.isSigner(signers[i]));
        }

        // Check events emitted during deployment
        vm.expectEmit(true, false, false, false);
        emit ICrossChainMultisig.SignerAdded(signers[0]);

        vm.expectEmit(true, false, false, false);
        emit ICrossChainMultisig.SignerAdded(signers[1]);

        vm.expectEmit(true, false, false, false);
        emit ICrossChainMultisig.SignerAdded(signers[2]);

        vm.expectEmit(false, false, false, true);
        emit ICrossChainMultisig.ConfirmationThresholdSet(THRESHOLD);

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
        multisig.submitProposal("test", calls, bytes32(0));

        vm.expectRevert(ICrossChainMultisig.CantBeExecutedOnCurrentChainException.selector);
        multisig.signProposal(bytes32(0), new bytes(65));
        vm.stopPrank();

        // Test onlyOnNotMainnet modifier
        vm.chainId(1);
        vm.expectRevert(ICrossChainMultisig.CantBeExecutedOnCurrentChainException.selector);
        multisig.executeProposal(
            SignedProposal({name: "test", calls: calls, prevHash: bytes32(0), signatures: new bytes[](0)})
        );

        // Test onlySelf modifier
        vm.expectRevert(ICrossChainMultisig.OnlySelfException.selector);
        multisig.addSigner(address(0x123));

        vm.expectRevert(ICrossChainMultisig.OnlySelfException.selector);
        multisig.removeSigner(signers[0]);

        vm.expectRevert(ICrossChainMultisig.OnlySelfException.selector);
        multisig.setConfirmationThreshold(3);

        // Test onlyOwner modifier
        vm.prank(makeAddr("notOwner"));
        vm.expectRevert("Ownable: caller is not the owner");
        multisig.submitProposal("test", calls, bytes32(0));
    }

    /// @dev U:[SM-3]: Submit proposal works correctly
    function test_CCG_03_SubmitProposal() public {
        vm.startPrank(owner);
        vm.chainId(1); // Set to mainnet

        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 1, target: address(0x123), callData: hex"1234"});

        multisig.submitProposal("test", calls, bytes32(0));

        bytes32 proposalHash = multisig.hashProposal("test", calls, bytes32(0));
        SignedProposal memory proposal = multisig.signedProposals(proposalHash);

        assertEq(proposal.calls.length, 1);
        assertEq(proposal.prevHash, bytes32(0));
        assertEq(proposal.signatures.length, 0);
    }

    function test_CCG_04_RevertOnInvalidPrevHash() public {
        vm.chainId(1);
        vm.startPrank(owner);

        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 1, target: address(0x123), callData: hex"1234"});

        vm.expectRevert(ICrossChainMultisig.InvalidPrevHashException.selector);
        multisig.submitProposal("test", calls, bytes32(uint256(1))); // Invalid prevHash
    }

    function test_CCG_05_RevertOnEmptyCalls() public {
        vm.chainId(1);
        vm.startPrank(owner);

        CrossChainCall[] memory calls = new CrossChainCall[](0);

        vm.expectRevert(ICrossChainMultisig.NoCallsInProposalException.selector);
        multisig.submitProposal("test", calls, bytes32(0));
    }

    /// @dev U:[SM-6]: Sign proposal works correctly with single signature
    function test_CCG_06_SignProposal() public {
        vm.chainId(1); // Set to mainnet

        // Submit proposal
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 1, target: address(0x123), callData: hex"1234"});

        vm.prank(owner);
        multisig.submitProposal("test", calls, bytes32(0));
        bytes32 proposalHash = multisig.hashProposal("test", calls, bytes32(0));

        // Generate EIP-712 signature
        bytes32 domainSeparator = multisig.domainSeparatorV4();
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, proposalHash));

        bytes memory signature = _signProposalHash(signer0PrivateKey, proposalHash);

        // Sign with first signer
        multisig.signProposal(proposalHash, signature);

        // Verify proposal state after signing
        SignedProposal memory proposal = multisig.signedProposals(proposalHash);
        assertEq(proposal.signatures.length, 1);
        assertEq(proposal.signatures[0], signature);

        // Verify proposal was not executed since threshold not met
        assertEq(multisig.lastProposalHash(), bytes32(0));
    }

    /// @dev U:[SM-7]: Sign proposal reverts when signing with invalid signature
    function test_CCG_07_SignProposalInvalidSignature() public {
        vm.chainId(1);

        // Submit proposal
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 1, target: address(0x123), callData: hex"1234"});

        vm.prank(owner);
        multisig.submitProposal("test", calls, bytes32(0));
        bytes32 proposalHash = multisig.hashProposal("test", calls, bytes32(0));

        // Try to sign with invalid signature
        bytes memory invalidSig = hex"1234";
        vm.expectRevert("ECDSA: invalid signature length");
        multisig.signProposal(proposalHash, invalidSig);
    }

    /// @dev U:[SM-8]: Sign proposal reverts when signing non-existent proposal
    function test_CCG_08_SignProposalNonExistentProposal() public {
        vm.chainId(1);

        // Set last proposal hash to 1, to avoid ambiguity that default value of 0 is a valid proposal hash
        multisig.setLastProposalHash(bytes32(uint256(1)));

        bytes32 nonExistentHash = keccak256("non-existent");
        bytes memory signature = _signProposalHash(signer0PrivateKey, nonExistentHash);

        vm.expectRevert(ICrossChainMultisig.InvalidPrevHashException.selector);
        multisig.signProposal(nonExistentHash, signature);
    }

    /// @dev U:[SM-9]: Sign proposal reverts when same signer signs twice
    function test_CCG_09_SignProposalDuplicateSigner() public {
        vm.chainId(1);

        // Submit proposal
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 1, target: address(0x123), callData: hex"1234"});

        vm.prank(owner);
        multisig.submitProposal("test", calls, bytes32(0));
        bytes32 proposalHash = multisig.hashProposal("test", calls, bytes32(0));

        // Sign first time
        bytes memory signature = _signProposalHash(signer0PrivateKey, proposalHash);
        multisig.signProposal(proposalHash, signature);

        // Try to sign again with same signer
        vm.expectRevert(ICrossChainMultisig.AlreadySignedException.selector);
        multisig.signProposal(proposalHash, signature);
    }

    /// @dev U:[SM-10]: Sign proposal reverts when non-signer tries to sign
    function test_CCG_10_SignProposalNonSigner() public {
        vm.chainId(1);

        // Submit proposal
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 1, target: address(0x123), callData: hex"1234"});

        vm.prank(owner);
        multisig.submitProposal("test", calls, bytes32(0));
        bytes32 proposalHash = multisig.hashProposal("test", calls, bytes32(0));

        // Try to sign with non-signer private key
        uint256 nonSignerKey = 999;
        bytes memory signature = _signProposalHash(nonSignerKey, proposalHash);

        vm.expectRevert(ICrossChainMultisig.SignerDoesNotExistException.selector);
        multisig.signProposal(proposalHash, signature);
    }

    /// @dev U:[SM-11]: Sign and execute proposal works correctly
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
        multisig.submitProposal("test", calls, bytes32(0));
        bytes32 proposalHash = multisig.hashProposal("test", calls, bytes32(0));

        // Sign with first signer
        bytes memory sig0 = _signProposalHash(signer0PrivateKey, proposalHash);
        multisig.signProposal(proposalHash, sig0);

        // Sign with second signer which should trigger execution
        // Check events emitted during execution
        vm.expectEmit(true, true, true, true);
        emit ICrossChainMultisig.ProposalSigned(proposalHash, vm.addr(signer1PrivateKey));

        vm.expectEmit(true, true, true, true);
        emit ICrossChainMultisig.ProposalExecuted(proposalHash);
        bytes memory sig1 = _signProposalHash(signer1PrivateKey, proposalHash);
        multisig.signProposal(proposalHash, sig1);

        // Verify proposal was executed
        assertEq(multisig.lastProposalHash(), proposalHash, "lastProposalHash");
        assertEq(multisig.executedProposalHashes(0), proposalHash, "executedProposalHashes");
    }

    /// @dev U:[SM-12]: _verifyProposal reverts if prevHash doesn't match lastProposalHash
    function test_CCG_12_VerifyProposalInvalidPrevHash() public {
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        calls[0] = CrossChainCall({chainId: 1, target: address(0x123), callData: hex"1234"});

        bytes32 invalidPrevHash = keccak256("invalid");
        vm.expectRevert(ICrossChainMultisig.InvalidPrevHashException.selector);
        multisig.exposed_verifyProposal(calls, invalidPrevHash);
    }

    /// @dev U:[SM-13]: _verifyProposal reverts if calls array is empty
    function test_CCG_13_VerifyProposalEmptyCalls() public {
        CrossChainCall[] memory calls = new CrossChainCall[](0);

        vm.expectRevert(ICrossChainMultisig.NoCallsInProposalException.selector);
        multisig.exposed_verifyProposal(calls, bytes32(0));
    }

    /// @dev U:[SM-14]: _verifyProposal reverts if trying to call self on other chain
    function test_CCG_14_VerifyProposalSelfCallOtherChain() public {
        CrossChainCall[] memory calls = new CrossChainCall[](1);
        // Try to call the multisig contract itself on another chain
        calls[0] = CrossChainCall({
            chainId: 5, // Goerli chain ID
            target: address(multisig),
            callData: hex"1234"
        });

        vm.expectRevert(ICrossChainMultisig.InconsistentSelfCallOnOtherChainException.selector);
        multisig.exposed_verifyProposal(calls, bytes32(0));
    }

    /// @dev U:[SM-15]: _verifyProposal succeeds with valid calls
    function test_CCG_15_VerifyProposalValidCalls() public {
        CrossChainCall[] memory calls = new CrossChainCall[](3);

        // Valid call on same chain
        calls[0] = CrossChainCall({chainId: 0, target: address(multisig), callData: hex"1234"});

        // Valid call to different contract on another chain
        calls[1] = CrossChainCall({chainId: 5, target: address(0x123), callData: hex"5678"});

        // Valid call to different contract on same chain
        calls[2] = CrossChainCall({chainId: 0, target: address(0x456), callData: hex"9abc"});

        // Should not revert
        multisig.exposed_verifyProposal(calls, bytes32(0));
    }

    /// @dev U:[SM-16]: _verifySignatures returns 0 for empty signatures array
    function test_CCG_16_VerifySignaturesEmptyArray() public {
        bytes[] memory signatures = new bytes[](0);
        bytes32 proposalHash = keccak256("test");

        uint256 validCount = multisig.exposed_verifySignatures(signatures, proposalHash);
        assertEq(validCount, 0);
    }

    /// @dev U:[SM-17]: _verifySignatures correctly counts valid signatures
    function test_CCG_17_VerifySignaturesValidSignatures() public {
        bytes32 proposalHash = keccak256("test");

        // Create array with 2 valid signatures
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = _signProposalHash(signer0PrivateKey, proposalHash);
        signatures[1] = _signProposalHash(signer1PrivateKey, proposalHash);

        uint256 validCount = multisig.exposed_verifySignatures(signatures, proposalHash);
        assertEq(validCount, 2);
    }

    /// @dev U:[SM-18]: _verifySignatures ignores invalid signatures
    function test_CCG_18_VerifySignaturesInvalidSignatures() public {
        bytes32 proposalHash = keccak256("test");

        // Create array with 1 valid and 1 invalid signature
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = _signProposalHash(signer0PrivateKey, proposalHash);

        // Create invalid signature by signing different hash
        signatures[1] = _signProposalHash(signer1PrivateKey, keccak256("wrong hash"));

        uint256 validCount = multisig.exposed_verifySignatures(signatures, proposalHash);
        assertEq(validCount, 1);
    }
    /// @dev U:[SM-19]: _verifySignatures reverts with AlreadySignedException on duplicate signatures from same signer

    function test_CCG_19_VerifySignaturesDuplicateSigner() public {
        bytes32 proposalHash = keccak256("test");

        // Create array with 2 signatures from same signer
        bytes[] memory signatures = new bytes[](2);
        signatures[0] = _signProposalHash(signer0PrivateKey, proposalHash);
        signatures[1] = _signProposalHash(signer0PrivateKey, proposalHash);

        vm.expectRevert(ICrossChainMultisig.AlreadySignedException.selector);
        multisig.exposed_verifySignatures(signatures, proposalHash);
    }

    /// @dev U:[SM-20]: _verifySignatures ignores signatures from non-signers
    function test_CCG_20_VerifySignaturesNonSigner() public {
        bytes32 proposalHash = keccak256("test");

        // Create random non-signer private key
        uint256 nonSignerKey = uint256(keccak256("non-signer"));

        bytes[] memory signatures = new bytes[](2);
        signatures[0] = _signProposalHash(signer0PrivateKey, proposalHash); // Valid signer
        signatures[1] = _signProposalHash(nonSignerKey, proposalHash); // Non-signer

        uint256 validCount = multisig.exposed_verifySignatures(signatures, proposalHash);
        assertEq(validCount, 1);
    }

    /// @dev U:[SM-21]: _verifySignatures reverts on malformed signatures
    function test_CCG_21_VerifySignaturesMalformedSignature() public {
        bytes32 proposalHash = keccak256("test");

        bytes[] memory signatures = new bytes[](2);
        signatures[0] = _signProposalHash(signer0PrivateKey, proposalHash); // Valid signature
        signatures[1] = hex"1234"; // Malformed signature

        vm.expectRevert("ECDSA: invalid signature length");
        uint256 validCount = multisig.exposed_verifySignatures(signatures, proposalHash);
    }
}
