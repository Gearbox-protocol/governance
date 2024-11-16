// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {Call} from "./Types.sol";

// TODO: consider moving to libraries/Hook.sol

/// @notice Interface for market hooks
/// @dev These hooks are called by the MarketConfigurator during various configuration events
/// Each hook returns an array of Call structs, allowing for flexible actions to be executed
/// Actions are executed by the MarketConfigurator on behalf of configurator role.

interface ICreditHooks {
    //
    // PRICE ORACLE
    //

    /// @notice Hook that executes when the price oracle is updated for a credit manager
    /// @param creditManager The address of the credit manager being updated
    /// @param priceOracle The address of the new price oracle
    /// @param prevOracle The address of the previous price oracle
    /// @return calls An array of Call structs representing actions to be executed
    function onUpdatePriceOracle(address creditManager, address priceOracle, address prevOracle)
        external
        returns (Call[] memory calls);

    // Change to Role PlaceHolder?
    function onAddEmergencyLiquidator(address creditManager, address emergencyLiquidator)
        external
        returns (Call[] memory calls);

    function onRemoveEmergencyLiquidator(address creditManager, address emergencyLiquidator)
        external
        returns (Call[] memory calls);

    function onUpdateLossLiquidator(address creditManager, address newLossLiquidator, address oldLossLiquidator)
        external
        returns (Call[] memory calls);
}
