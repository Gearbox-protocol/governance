// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

struct Call {
    address target;
    bytes callData;
}

struct DeployParams {
    bytes32 postfix;
    bytes constructorParams;
}

struct DeployResult {
    address newContract;
    address[] accessList;
    Call[] onInstallOps;
}

// The `BytecodeInfo` struct holds metadata about a bytecode in BytecodeRepository
//
// - `author`: A person who first upload smart-contract to BCR
// - `contractType`: A bytes32 identifier representing the type of the contract.
// - `version`: A uint256 indicating the version of the contract.
// - `sources`: An array of `Source` structs, each containing a comment and a link related to the contract's source.
// - `auditors`: An array of addresses representing the auditors who have reviewed the contract.
// - `reports`: An array of `SecurityReport` structs, each containing information about security audits conducted on the contract.
struct BytecodeInfo {
    address author;
    bytes32 contractType;
    uint256 version;
    Source[] sources;
    address[] auditors;
    SecurityReport[] reports;
}

struct SecurityReport {
    address auditor;
    string url;
}

struct Source {
    string comment;
    string link;
}

struct AuditorInfo {
    string name;
    bool forbidden;
}
