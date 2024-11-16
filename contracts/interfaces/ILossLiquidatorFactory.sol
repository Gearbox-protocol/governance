// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {IConfiguratingFactory} from "./IConfiguratingFactory.sol";
import {IMarketHooks} from "./IMarketHooks.sol";
import {DeployParams, DeployResult} from "./Types.sol";

interface ILossLiquidatorFactory is IMarketHooks, IConfiguratingFactory {
    function deployLossLiquidator(address pool, DeployParams calldata params) external returns (DeployResult memory);
}
