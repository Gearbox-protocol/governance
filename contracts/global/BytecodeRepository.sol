// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {IBytecodeRepository} from "../interfaces/IBytecodeRepository.sol";
import {AP_BYTECODE_REPOSITORY} from "../libraries/ContractLiterals.sol";
import {IVersion} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IVersion.sol";
import {SanityCheckTrait} from "@gearbox-protocol/core-v3/contracts/traits/SanityCheckTrait.sol";

import {SecurityReport, Source, BytecodeInfo, AuditorInfo} from "../interfaces/Types.sol";

// EXCEPTIONS
import "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";

import {LibString} from "@solady/utils/LibString.sol";

/**
 * @title BytecodeRepository
 *
 * @notice
 * The `BytecodeRepository` is a singleton contract responsible for deploying all contracts in the system for risk curators.
 *
 * Each contract is identified by two parameters:
 * - ContractType: bytes32. Can be further split into two parts:
 *   - Domain: Represents the fundamental category or name of the smart contract. For example,
 *     contracts like `Pools` or `CreditManagers` use the contract name as the domain.
 *   - Postfix: For contracts that offer different implementations under the same interface
 *     (such as interest rate models, adapters, or price feeds), the domain remains fixed.
 *     Variations are distinguished using a postfix. This is established by convention.
 * - Version: uint256: Specifies the version of the contract in semver. (example: 3_10)
 *
 * ContractType Convention:
 *  - The contract type follows a capitalized snake_case naming convention
 *    without any version information (example: "POOL", "CREDIT_MANAGER")
 *  - List of domains:
 *    RK_ - rate keepers. Supports IRateKeeperBase interface.
 *    IRM_ - interest rate models
 *
 * This structure ensures consistency and clarity when deploying and managing contracts within the system.
 */
contract BytecodeRepository is Ownable2Step, SanityCheckTrait, IBytecodeRepository {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using LibString for bytes32;
    using LibString for string;

    //
    // CONSTANTS
    //

    /// @notice Meta info about contract type & version
    uint256 public constant override version = 3_10;
    bytes32 public constant override contractType = AP_BYTECODE_REPOSITORY;

    uint256 public constant AUDITOR_THRESHOLD = 2;

    //
    // ERRORS
    //

    // Thrown if the deployed contract has a different contractType/version than it's indexed in the repository
    error IncorrectBytecodeException();

    // Thrown if the bytecode provided is empty
    error EmptyBytecodeException();

    // Thrown if someone tries to deploy the contract with the same address
    error BytecodeAlreadyExistsAtAddressException(address);

    // Thrown if domain + postfix length is more than 30 symbols (doesn't fit into bytes32)
    error TooLongContractTypeException(string);

    //  Thrown if requested bytecode wasn't found in the repository
    error BytecodeNotFoundException(bytes32 contractType, uint256 version);

    // Thrown if someone tries to replace existing bytecode with the same contact type & version
    error BytecodeAllreadyExistsException(bytes32 contractType, uint256 version);

    // Thrown if someone tries to deploy a contract which wasn't audited enough
    error ContractIsNotAuditedException();

    // Thrown when an attempt is made to add an auditor that already exists
    error AuditorAlreadyAddedException();

    // Thrown when an auditor is not found in the repository
    error AuditorNotFoundException();

    // Thrown if the caller is not the deployer of the bytecode
    error NotDeployerException();

    // Thrown if the caller does not have valid auditor permissions
    error NoValidAuditorPermissionsAException();

    //
    // EVENTS
    //

    // Emitted when new smart contract was deployed
    event DeployContact(address indexed addr, bytes32 indexed contractType, uint256 indexed version);

    // Event emitted when a contract is audited by an auditor
    event AuditContract(address indexed auditor, bytes32 indexed contractType, uint256 indexed version);

    // Event emitted when a new auditor is added to the repository
    event AddAuditor(address indexed auditor, string name);

    // Event emitted when an auditor is forbidden from the repository
    event ForbidAuditor(address indexed auditor, string name);

    // Event emitted when a new source is added to the bytecode information
    event SourceAdded(bytes32 indexed contractType, uint256 indexed version, string comment, string linkToSource);

    //
    // VARIABLES
    //

    // Maps hashes (keccak256(contractType, version)) to bytecodeInfo struct
    // Motivation: store hashes to make possible to list all store contracts inside
    mapping(bytes32 => BytecodeInfo) public bytecodeInfo;

    mapping(bytes32 => bytes) internal _bytecode;

    EnumerableSet.UintSet internal _hashStorage;

    // Auditors

    // Keep all audtors joined the repository
    EnumerableSet.AddressSet internal _auditors;

    // Store auditors info
    mapping(address => AuditorInfo) public auditorInfo;

    // Postfixes are used to deploy unique contract versions inherited from
    // the base contract but differ when used with specific tokens.
    // For example, the USDT pool, which supports fee computation without errors
    mapping(address => bytes32) public specificPostfixes;

    //
    // FUNCTIONS
    //

    /**
     * @notice Deploys a contract using the stored bytecode and provided constructor parameters.
     * @param _contractType The type of the contract to be deployed.
     * @param _version The version of the contract to be deployed.
     * @param constructorParams The constructor parameters to be passed to the contract.
     * @param salt A salt used for the Create2 deployment to ensure a unique address. Conventionally it
     *        represents market configurator address to avoid possible collisions
     * @return newContract The address of the newly deployed contract.
     * @dev Reverts if the bytecode for the specified contract type and version is not found.
     *      Reverts if the deployed contract's type or version does not match the expected values.
     *      If the deployed contract is ownable, ownership is automatically transferred to the caller.
     */
    function deploy(bytes32 _contractType, uint256 _version, bytes memory constructorParams, bytes32 salt)
        public
        override
        returns (address newContract)
    {
        // TODO: add check that contract is audited
        if (!isDeployPermitted(_contractType, _version)) {
            revert ContractIsNotAuditedException();
        }

        bytes memory bytecodeWithParams = _getBytecodeWithParamsOrRevert(_contractType, _version, constructorParams);

        // Check if a contract already exists at the address
        newContract = Create2.computeAddress(salt, keccak256(bytecodeWithParams));
        if (newContract.code.length != 0) {
            revert BytecodeAlreadyExistsAtAddressException(newContract);
        }

        // Deploy smart contract and return the address
        Create2.deploy(0, salt, bytecodeWithParams);

        // additional check that deployed contract has desired contractType & version
        if (IVersion(newContract).contractType() != _contractType || IVersion(newContract).version() != _version) {
            revert IncorrectBytecodeException();
        }

        emit DeployContact(newContract, _contractType, _version);

        // Is contract is ownable its automaticalle transfer onwership to caller
        try Ownable(newContract).transferOwnership(msg.sender) {} catch {}
    }

    /**
     * @notice Deploys a contract the same as deploy(...), getting domain & postfix as params
     * @param _domain The domain of contract
     * @param _postfix The postfix of contract
     * @param _version The version of the contract to be deployed.
     * @param constructorParams The constructor parameters to be passed to the contract.
     * @param salt A salt used for the Create2 deployment to ensure a unique address. Conventionally it
     *        represents market configurator address to avoid possible collisions
     * @return newContract The address of the newly deployed contract.
     * @dev Reverts if the bytecode for the specified contract type and version is not found.
     *      Reverts if the deployed contract's type or version does not match the expected values.
     *      If the deployed contract is ownable, ownership is automatically transferred to the caller.
     */
    function deployByDomain(
        bytes32 _domain,
        bytes32 _postfix,
        uint256 _version,
        bytes memory constructorParams,
        bytes32 salt
    ) external override returns (address newContract) {
        return deploy(_getContractType(_domain, _postfix), _version, constructorParams, salt);
    }

    function uploadByteCode(
        bytes32 _contractType,
        uint256 _version,
        bytes calldata bytecode,
        string calldata comment,
        string calldata linkToSource
    ) external {
        if (bytecode.length == 0) {
            revert EmptyBytecodeException();
        }

        bytes32 _hash = computeBytecodeHash(_contractType, _version);

        // TODO: develop the protection against griefing attack, when someone can use popular
        // contract types and futher versions and provide a lot of garbage here (like cybersquatting)
        // One of potential solution could be stake (deposit ~10M GEAR) which is paid back
        // when the first audit is passed. Probably alternative solutions are also possible

        // Ensure that the bytecode does not already exist for the given contract type and version
        // It is essential to refrain from altering the code after receiving approval from the auditors
        if (_hashStorage.contains(uint256(_hash))) {
            revert BytecodeAllreadyExistsException(_contractType, _version);
        }

        // Update bytecode storage
        _bytecode[_hash] = bytecode;

        // Update bytecodeInfo
        bytecodeInfo[_hash].author = msg.sender;
        bytecodeInfo[_hash].sources.push(Source({comment: comment, link: linkToSource}));

        bytecodeInfo[_hash].contractType = _contractType;
        bytecodeInfo[_hash].version = version;

        // Store hash
        _hashStorage.add(uint256(_hash));
    }

    function addSource(bytes32 _contractType, uint256 _version, string calldata comment, string calldata linkToSource)
        external
    {
        bytes32 _hash = computeBytecodeHash(_contractType, _version);

        // Check if the caller is the deployer of the bytecode
        if (msg.sender != bytecodeInfo[_hash].author) {
            revert NotDeployerException();
        }

        // Add the new source to the bytecodeInfo
        bytecodeInfo[_hash].sources.push(Source({comment: comment, link: linkToSource}));

        // Emit event after adding the source
        emit SourceAdded(_contractType, _version, comment, linkToSource);
    }

    //
    // GETTERS
    //
    function computeBytecodeHash(bytes32 _contractType, uint256 _version) public pure returns (bytes32) {
        return keccak256(abi.encode(_contractType, _version));
    }

    // TODO: add offset / limit functionality to avoid DDoS
    function allBytecodeHashes() public view returns (bytes32[] memory result) {
        uint256[] memory poiner = _hashStorage.values();

        /// @solidity memory-safe-assembly
        assembly {
            result := poiner
        }
    }

    // TODO: add offset / limit functionality to avoid DDoS
    function allBytecodeInfo() external view returns (BytecodeInfo[] memory result) {
        bytes32[] memory _hashes = allBytecodeHashes();
        uint256 len = _hashes.length;
        result = new BytecodeInfo[](len);
        unchecked {
            for (uint256 i; i < len; ++i) {
                result[i] = bytecodeInfo[_hashes[i]];
            }
        }
    }

    function computeAddress(bytes32 _contractType, uint256 _version, bytes memory constructorParams, bytes32 salt)
        external
        view
        override
        returns (address)
    {
        return Create2.computeAddress(
            salt, keccak256(_getBytecodeWithParamsOrRevert(_contractType, _version, constructorParams))
        );
    }

    function computeAddressByDomain(
        bytes32 _domain,
        bytes32 _postfix,
        uint256 _version,
        bytes memory constructorParams,
        bytes32 salt
    ) external view override returns (address) {
        return Create2.computeAddress(
            salt,
            keccak256(_getBytecodeWithParamsOrRevert(_getContractType(_domain, _postfix), _version, constructorParams))
        );
    }

    /**
     * @notice Check if the contract has enough audits to be deployed by RiskCurators.
     * @param _contractType The type of the contract to check.
     * @param _version The version of the contract to check.
     * @return bool True if the contract has been audited by at least AUDITOR_THRESHOLD auditors, false otherwise.
     */
    function isDeployPermitted(bytes32 _contractType, uint256 _version) public view returns (bool) {
        BytecodeInfo memory info = bytecodeInfo[computeBytecodeHash(_contractType, _version)];

        // QUESTION: should we have more complex rules depending on domain?
        return info.auditors.length >= AUDITOR_THRESHOLD;
    }

    //
    // AUDITOR MANAGEMENT
    //
    function addAuditor(address auditor, string memory _name) external onlyOwner nonZeroAddress(auditor) {
        if (bytes(_name).length == 0) {
            revert IncorrectParameterException();
        }
        if (_auditors.contains(auditor)) {
            revert AuditorAlreadyAddedException();
        }

        _auditors.add(auditor);
        auditorInfo[auditor].name = _name;
        emit AddAuditor(auditor, _name);
    }

    function forbidAuditor(address auditor) external onlyOwner nonZeroAddress(auditor) {
        if (!_auditors.contains(auditor)) {
            revert AuditorNotFoundException();
        }

        auditorInfo[auditor].forbidden = true;
        emit ForbidAuditor(auditor, auditorInfo[auditor].name);
    }

    /**
     * @notice Adds a security report for a specific contract type and version.
     * @param _contractType The type of the contract for which the security report is being added.
     * @param _version The version of the contract for which the security report is being added.
     * @param auditor The address of the auditor adding the security report.
     * @param reportUrl The URL of the security report.
     * @dev Reverts if the caller is not a registered auditor or if the auditor is forbidden.
     *      If the auditor is not already associated with the contract, they are added to the list of auditors.
     *      Emits an AuditContract event upon successful addition of the report.
     */
    function addSecurityReport(bytes32 _contractType, uint256 _version, address auditor, string calldata reportUrl)
        external
    {
        if (!_auditors.contains(msg.sender) || auditorInfo[msg.sender].forbidden) {
            revert NoValidAuditorPermissionsAException();
        }

        bytes32 bytecodeHash = computeBytecodeHash(_contractType, _version);
        BytecodeInfo storage info = bytecodeInfo[bytecodeHash];

        bool found;
        for (uint256 i = 0; i < info.auditors.length; i++) {
            if (info.auditors[i] == auditor) {
                found = true;
            }
        }

        if (!found) {
            info.auditors.push(msg.sender);
        }

        info.reports.push(SecurityReport({auditor: msg.sender, url: reportUrl}));

        emit AuditContract(msg.sender, _contractType, _version);
    }

    //
    // INTERNALS
    //

    /**
     * @dev Fetches the bytecode for a specific contract type and version, then append the provided
     * constructor parameters to enable deployment.
     * If the bytecode does not exist, the function will be reverted. .
     * @param _contractType The type of the contract for which bytecode is being fetched.
     * @param _version The version of the contract bytecode.
     * @param constructorParams The parameters to be appended to the bytecode to make it deployable.
     * @return bytecodeWithParams The deployable bytecode with appended constructor parameters.
     */
    function _getBytecodeWithParamsOrRevert(bytes32 _contractType, uint256 _version, bytes memory constructorParams)
        internal
        view
        returns (bytes memory bytecodeWithParams)
    {
        bytes memory bytecode = _bytecode[computeBytecodeHash(_contractType, _version)];
        if (bytecode.length == 0) {
            revert BytecodeNotFoundException(_contractType, _version);
        }

        bytecodeWithParams = abi.encodePacked(bytecode, constructorParams);
    }

    function _getContractType(bytes32 domain, bytes32 postfix) internal pure returns (bytes32) {
        // Ignores postfix if it's empty; otherwise, concatenate domain_postfix
        if (postfix == 0) return domain;
        string memory contractType_ = string.concat(domain.fromSmallString(), "_", postfix.fromSmallString());
        // FIXME: check is redundant since it is also present in `toSmallString`
        if (bytes(contractType_).length > 31) {
            revert TooLongContractTypeException(contractType_);
        }
        return contractType_.toSmallString();
    }

    // TODO:
    function getTokenSpecificPostfix(address) external view returns (bytes32) {}
}
