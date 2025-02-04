// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

/// @title Alias Loss Policy Interface
/// @notice Interface for loss policy that allows setting price feed aliases for tokens
interface IAliasLossPolicy {
    /// @notice Sets a price feed alias for a token
    /// @param token Token address to set alias for
    /// @param priceFeed New price feed address to use as alias
    function setAlias(address token, address priceFeed) external;
}
