// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {IVersion} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IVersion.sol";

interface IPriceFeedStore is IVersion {
    //
    // ERRORS
    //

    /// @notice Thrown when attempting to use a price feed that is not known by the price feed store
    error PriceFeedNotKnownException(address priceFeed);

    /// @notice Thrown when attempting to add a price feed that is already known by the price feed store
    error PriceFeedAlreadyAddedException(address priceFeed);

    /// @notice Thrown when attempting to remove a price feed that is not allowed for a token
    error PriceFeedIsNotAllowedException(address token, address priceFeed);

    //
    // EVENTS
    //

    /// @notice Emitted when a new security audit is added for a price feed
    event AuditPriceFeed(address auditor, address priceFeed);

    /// @notice Emitted when a new price feed is added to PriceFeedStore
    event AddPriceFeed(address priceFeed, uint32 stalenessPeriod);

    /// @notice Emitted when the staleness period is changed in an existing price feed
    event SetStalenessPeriod(address priceFeed, uint32 stalenessPeriod);

    /// @notice Emitted when a price feed is allowed for a token
    event AllowPriceFeed(address token, address priceFeed);

    /// @notice Emitted when a price feed is forbidden for a token
    event ForbidPriceFeed(address token, address priceFeed);

    /// @notice Emitted when an equivalent is set for a token
    event SetEquivalentToken(address token, address equivalent);

    //
    // GETTERS
    //
    function getPriceFeeds(address token) external view returns (address[] memory);
    function isAllowedPriceFeed(address token, address priceFeed) external view returns (bool);
    function getStalenessPeriod(address priceFeed) external view returns (uint32);

    //
    // CONFIGURATION
    //
    function addPriceFeed(address priceFeed, uint32 stalenessPeriod) external;
    function setStalenessPeriod(address priceFeed, uint32 stalenessPeriod) external;
    function allowPriceFeed(address token, address priceFeed) external;
    function forbidPriceFeed(address token, address priceFeed) external;
    function setEquivalentToken(address token, address equivalentToken) external;
}
