// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {IMarketHooks} from "./IMarketHooks.sol";
import {DeployResult} from "./Types.sol";

interface IPriceOracleFactory is IMarketHooks {
    function deployPriceOracle(address pool) external returns (DeployResult memory);
}
