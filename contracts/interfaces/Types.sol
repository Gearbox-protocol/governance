// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

struct AddressProviderEntry {
    bytes32 key;
    uint256 ver;
    address value;
}

struct Call {
    address target;
    bytes callData;
}

struct CrossChainCall {
    uint256 chainId; // 0 means to be executed on all chains
    address target;
    bytes callData;
}

struct SignedBatch {
    string name;
    bytes32 prevHash;
    CrossChainCall[] calls;
    bytes[] signatures;
}

struct SignedRecoveryModeMessage {
    bytes32 startingBatchHash;
    bytes[] signatures;
}

struct DeployParams {
    bytes32 postfix;
    bytes32 salt;
    bytes constructorParams;
}

struct DeployResult {
    address newContract;
    Call[] onInstallOps;
}

struct MarketFactories {
    address poolFactory;
    address priceOracleFactory;
    address interestRateModelFactory;
    address rateKeeperFactory;
    address lossPolicyFactory;
}

struct PriceFeedInfo {
    string name;
    uint32 stalenessPeriod;
    bytes32 priceFeedType;
    uint256 version;
}

struct ConnectedPriceFeed {
    address token;
    address[] priceFeeds;
}

struct Bytecode {
    bytes32 contractType;
    uint256 version;
    bytes initCode;
    address author;
    string source;
    bytes authorSignature;
}

struct BytecodePointer {
    bytes32 contractType;
    uint256 version;
    address initCodePointer;
    address author;
    string source;
    bytes authorSignature;
}

struct AuditorSignature {
    string reportUrl;
    address auditor;
    bytes signature;
}

struct Split {
    bool initialized;
    address[] receivers;
    uint16[] proportions;
}

struct TwoAdminProposal {
    bytes callData;
    bool confirmedByAdmin;
    bool confirmedByTreasuryProxy;
}
