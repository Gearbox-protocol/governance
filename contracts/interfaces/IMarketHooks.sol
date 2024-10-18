// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IVersion} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IVersion.sol";

/// @notice Interface for market hooks
/// @dev These hooks are called by the MarketConfigurator during various configuration events
/// Each hook returns an array of Call structs, allowing for flexible actions to be executed
/// Actions are executed by the MarketConfigurator on behalf of configurator role.

interface IMarketHooks {
    //
    // MARKET
    //

    /// @notice Hook that executes when a market is removed
    /// @param pool The address of the pool (represents market) being removed
    /// @return calls An array of Call structs to be executed
    function onRemoveMarket(address pool) external returns (Call[] memory calls);

    /// @notice Hook that executes when a new token is added to the market
    /// @param pool The address of the pool (represents market)
    /// @param token The address of the token being added
    /// @param priceFeed The address of the price feed for the token
    /// @return calls An array of Call structs to be executed
    function onAddToken(address pool, address token, address priceFeed) external returns (Call[] memory calls);

    /// @notice Hook that executes when the interest model is updated
    /// @param pool The address of the pool (represents market)
    /// @param newModel The address of the new interest model
    /// @return calls An array of Call structs to be executed
    function onUpdateInterestModel(address pool, address newModel) external returns (Call[] memory calls);

    //
    // CREDIT MANAGER
    //

    /// @notice Hook that executes when a new credit manager is added
    /// @param newCreditManager The address of the new credit manager
    /// @return calls An array of Call structs to be executed
    function onAddCreditManager(address newCreditManager) external returns (Call[] memory calls);

    /// @notice Hook that executes when a credit manager is removed
    /// @param _creditManager The address of the credit manager being removed
    /// @return calls An array of Call structs to be executed
    function onRemoveCreditManager(address _creditManager) external view returns (Call[] memory calls);

    //
    // PRICE ORACLE
    //

    /// @notice Hook that executes when the price oracle is updated
    /// @param newPriceOracle The address of the new price oracle
    /// @return calls An array of Call structs to be executed
    function onUpdatePriceOracle(address pool, address priceOracle, address prevOracle)
        external
        returns (Call[] memory calls);

    /// @notice Hook that executes when a price feed is set for a token
    /// @param pool The address of the pool (represents market)
    /// @param token The address of the token
    /// @param priceFeed The address of the price feed being set
    /// @return calls An array of Call structs to be executed
    function onSetPriceFeed(address pool, address token, address priceFeed) external returns (Call[] memory calls);

    /// @notice Hook that executes when a reserve price feed is set for a token
    /// @param pool The address of the pool (represents market)
    /// @param token The address of the token
    /// @param priceFeed The address of the reserve price feed being set
    /// @return calls An array of Call structs to be executed
    function onSetReservePriceFeed(address pool, address token, address priceFeed)
        external
        returns (Call[] memory calls);
}
