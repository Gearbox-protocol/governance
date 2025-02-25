// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {IVersion} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IVersion.sol";
import {IImmutableOwnableTrait} from "./base/IImmutableOwnableTrait.sol";
import {AuditReport, Bytecode} from "./Types.sol";

/// @title Bytecode repository interface
interface IBytecodeRepository is IVersion, IImmutableOwnableTrait {
    // ------ //
    // EVENTS //
    // ------ //

    event AddAuditor(address indexed auditor, string name);
    event AddPublicDomain(bytes32 indexed domain);
    event AuditBytecode(bytes32 indexed bytecodeHash, address indexed auditor, string reportUrl);
    event DeployContract(
        bytes32 indexed bytecodeHash, bytes32 indexed cType, uint256 indexed ver, address contractAddress
    );
    event ForbidInitCode(bytes32 indexed initCodeHash);
    event RemoveAuditor(address indexed auditor);
    event RemovePublicDomain(bytes32 indexed domain);
    event SetTokenSpecificPostfix(address indexed token, bytes32 indexed postfix);
    event UploadBytecode(
        bytes32 indexed bytecodeHash, bytes32 indexed cType, uint256 indexed ver, address author, string source
    );

    // ------ //
    // ERRORS //
    // ------ //

    error AuditorIsNotApprovedException(address auditor);
    error AuthorIsNotContractTypeOwnerException(bytes32 cType, address author);
    error BytecodeIsAlreadyAllowedException(bytes32 cType, uint256 ver);
    error BytecodeIsAlreadySignedByAuditorException(bytes32 bytecodeHash, address auditor);
    error BytecodeIsNotAllowedException(bytes32 cType, uint256 ver);
    error BytecodeIsNotUploadedException(bytes32 bytecodeHash);
    error CallerIsNotBytecodeAuthorException(address caller);
    error ContractIsAlreadyDeployedException(address deployedContract);
    error InitCodeIsForbiddenException(bytes32 initCodeHash);
    error InvalidAuditorSignatureException(address auditor);
    error InvalidAuthorSignatureException(address author);
    error InvalidBytecodeException(bytes32 bytecodeHash);
    error InvalidVersionException(bytes32 cType, uint256 ver);
    error VersionNotFoundException(bytes32 cType);

    // --------------- //
    // EIP-712 GETTERS //
    // --------------- //

    function BYTECODE_TYPEHASH() external view returns (bytes32);
    function AUDIT_REPORT_TYPEHASH() external view returns (bytes32);
    function domainSeparatorV4() external view returns (bytes32);
    function computeBytecodeHash(Bytecode calldata bytecode) external view returns (bytes32);
    function computeAuditReportHash(bytes32 bytecodeHash, address auditor, string calldata reportUrl)
        external
        view
        returns (bytes32);

    // ------------------- //
    // DEPLOYING CONTRACTS //
    // ------------------- //

    function isDeployedFromRepository(address deployedContract) external view returns (bool);
    function getDeployedContractBytecodeHash(address deployedContract) external view returns (bytes32);
    function computeAddress(
        bytes32 cType,
        uint256 ver,
        bytes calldata constructorParams,
        bytes32 salt,
        address deployer
    ) external view returns (address);
    function deploy(bytes32 cType, uint256 ver, bytes calldata constructorParams, bytes32 salt)
        external
        returns (address);

    // ------------------ //
    // UPLOADING BYTECODE //
    // ------------------ //

    function getBytecode(bytes32 bytecodeHash) external view returns (Bytecode memory);
    function isBytecodeUploaded(bytes32 bytecodeHash) external view returns (bool);
    function uploadBytecode(Bytecode calldata bytecode) external;

    // ----------------- //
    // AUDITING BYTECODE //
    // ----------------- //

    function isBytecodeAudited(bytes32 bytecodeHash) external view returns (bool);
    function getAuditReports(bytes32 bytecodeHash) external view returns (AuditReport[] memory);
    function getAuditReport(bytes32 bytecodeHash, uint256 index) external view returns (AuditReport memory);
    function getNumAuditReports(bytes32 bytecodeHash) external view returns (uint256);
    function submitAuditReport(bytes32 bytecodeHash, AuditReport calldata auditReport) external;

    // ----------------- //
    // ALLOWING BYTECODE //
    // ----------------- //

    // TODO: rework this section

    event AllowBytecode(bytes32 indexed bytecodeHash, bytes32 indexed cType, uint256 indexed ver);
    event ForbidBytecode(bytes32 indexed bytecodeHash, bytes32 indexed cType, uint256 indexed ver);
    event SetContractTypeOwner(bytes32 indexed cType, address indexed owner);
    event RemoveContractTypeOwner(bytes32 indexed cType);

    function getAllowedBytecodeHash(bytes32 cType, uint256 ver) external view returns (bytes32);
    function isAllowedSystemContract(bytes32 bytecodeHash) external view returns (bool);
    function getContractTypeOwner(bytes32 cType) external view returns (address);
    function allowSystemContract(bytes32 bytecodeHash) external;
    function revokeApproval(bytes32 cType, uint256 ver, bytes32 bytecodeHash) external;
    function removeContractTypeOwner(bytes32 cType) external;

    // ------------------------- //
    // PUBLIC DOMAINS MANAGEMENT //
    // ------------------------- //

    function isInPublicDomain(bytes32 cType) external view returns (bool);
    function isPublicDomain(bytes32 domain) external view returns (bool);
    function getPublicDomains() external view returns (bytes32[] memory);
    function addPublicDomain(bytes32 domain) external;
    function removePublicDomain(bytes32 domain) external;

    // ------------------- //
    // AUDITORS MANAGEMENT //
    // ------------------- //

    function isAuditor(address auditor) external view returns (bool);
    function getAuditors() external view returns (address[] memory);
    function getAuditorName(address auditor) external view returns (string memory);
    function addAuditor(address auditor, string calldata name) external;
    function removeAuditor(address auditor) external;

    // ------------------- //
    // FORBIDDING INITCODE //
    // ------------------- //

    function isInitCodeForbidden(bytes32 initCodeHash) external view returns (bool);
    function forbidInitCode(bytes32 initCodeHash) external;

    // ------------------------ //
    // TOKENS WITH CUSTOM LOGIC //
    // ------------------------ //

    function getTokenSpecificPostfix(address token) external view returns (bytes32);
    function setTokenSpecificPostfix(address token, bytes32 postfix) external;

    // --------------- //
    // VERSION CONTROL //
    // --------------- //

    function getLatestVersion(bytes32 cType) external view returns (uint256);
    function getLatestMinorVersion(bytes32 cType, uint256 majorVersion) external view returns (uint256);
    function getLatestPatchVersion(bytes32 cType, uint256 minorVersion) external view returns (uint256);
}
