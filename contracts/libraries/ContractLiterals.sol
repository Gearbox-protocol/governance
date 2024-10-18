// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

uint256 constant NO_VERSION_CONTROL = 0;

bytes32 constant AP_ACL = "ACL";
bytes32 constant AP_CONTRACTS_REGISTER = "CONTRACTS_REGISTER";

bytes32 constant AP_ADDRESS_PROVIDER = "ADDRESS_PROVIDER";
bytes32 constant AP_CONTROLLER_TIMELOCK = "CONTROLLER_TIMELOCK";

bytes32 constant AP_POOL = "LP";
bytes32 constant AP_POOL_QUOTA_KEEPER = "POOL_QUOTA_KEEPER";
bytes32 constant AP_POOL_RATE_KEEPER = "POOL_RATE_KEEPER";

bytes32 constant AP_PRICE_ORACLE = "PRICE_ORACLE";
bytes32 constant AP_ACCOUNT_FACTORY = "ACCOUNT_FACTORY";

// bytes32 constant AP_DATA_COMPRESSOR = "DATA_COMPRESSOR";
bytes32 constant AP_TREASURY = "TREASURY";
bytes32 constant AP_GEAR_TOKEN = "GEAR_TOKEN";
bytes32 constant AP_WETH_TOKEN = "WETH_TOKEN";
// bytes32 constant AP_WETH_GATEWAY = "WETH_GATEWAY";
bytes32 constant AP_ROUTER = "ROUTER";
bytes32 constant AP_BOT_LIST = "BOT_LIST";
bytes32 constant AP_GEAR_STAKING = "GEAR_STAKING";
bytes32 constant AP_ZAPPER_REGISTER = "ZAPPER_REGISTER";

bytes32 constant AP_INFLATION_ATTACK_BLOCKER = "INFLATION_ATTACK_BLOCKER";
bytes32 constant AP_ZERO_PRICE_FEED = "ZERO_PRICE_FEED";
bytes32 constant AP_DEGEN_DISTRIBUTOR = "DEGEN_DISTRIBUTOR";
bytes32 constant AP_MULTI_PAUSE = "MULTI_PAUSE";

bytes32 constant AP_BYTECODE_REPOSITORY = "BYTECODE_REPOSITORY";
bytes32 constant AP_PRICE_FEED_STORE = "PRICE_FEED_STORE";

bytes32 constant AP_CREDIT_MANAGER = "CREDIT_MANAGER";
bytes32 constant AP_CREDIT_FACADE = "CREDIT_FACADE";
bytes32 constant AP_CREDIT_CONFIGURATOR = "CREDIT_CONFIGURATOR";
bytes32 constant AP_DEGEN_NFT = "DEGEN_NFT";
bytes32 constant AP_MARKET_CONFIGURATOR = "MARKET_CONFIGURATOR";
bytes32 constant AP_MARKET_CONFIGURATOR_FACTORY = "MARKET_CONFIGURATOR_FACTORY";

bytes32 constant AP_INTEREST_MODEL_FACTORY = "INTEREST_MODEL_FACTORY";
bytes32 constant AP_ADAPTER_FACTORY = "ADAPTER_FACTORY";

bytes32 constant AP_POOL_FACTORY = "POOL_FACTORY";
bytes32 constant AP_CREDIT_FACTORY = "CREDIT_FACTORY";
bytes32 constant AP_PRICE_ORACLE_FACTORY = "PRICE_ORACLE_FACTORY";
bytes32 constant AP_RATE_FACTORY = "RATE_FACTORY";

// DOMAINS

bytes32 constant DOMAIN_POOL = "POOL";
bytes32 constant DOMAIN_CREDIT_MANAGER = "CREDIT_MANAGER";
bytes32 constant DOMAIN_ADAPTER = "ADAPTER";
bytes32 constant DOMAIN_DEGEN_NFT = "DEGEN_NFT";
bytes32 constant DOMAIN_RATE_KEEPER = "RK";
