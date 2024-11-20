// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {PriceFeedValidationTrait} from "@gearbox-protocol/core-v3/contracts/traits/PriceFeedValidationTrait.sol";
import {IPriceFeed} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IPriceFeed.sol";

import {AuditManager} from "./AuditManager.sol";
import {IPriceFeedStore} from "../interfaces/IPriceFeedStore.sol";
import {AP_PRICE_FEED_STORE} from "../libraries/ContractLiterals.sol";
import {SecurityReport, PriceFeedInfo, AuditorInfo} from "../interfaces/Types.sol";

contract PriceFeedStore is PriceFeedValidationTrait, AuditManager, IPriceFeedStore {
    using EnumerableSet for EnumerableSet.AddressSet;

    //
    // CONSTANTS
    //

    /// @notice Meta info about contract type & version
    uint256 public constant override version = 3_10;
    bytes32 public constant override contractType = AP_PRICE_FEED_STORE;

    /// @notice Threshold on number of auditors required to add a price feed
    uint256 public constant AUDITOR_THRESHOLD = 2;

    //
    // VARIABLES
    //

    /// @dev Set of all known price feeds
    EnumerableSet.AddressSet internal _knownPriceFeeds;

    /// @dev Mapping from token address to its set of allowed price feeds
    mapping(address => EnumerableSet.AddressSet) internal _allowedPriceFeeds;

    /// @notice Mapping from token address to its equivalent token. A token can use any price feeds of its equivalent.
    mapping(address => address) public equivalentTokens;

    /// @notice Mapping from price feed address to its data
    mapping(address => PriceFeedInfo) public priceFeedInfo;

    constructor(address owner) {
        _transferOwnership(owner);
    }

    /// @notice Returns the list of price feeds available for a token
    function getPriceFeeds(address token) external view returns (address[] memory priceFeeds) {
        return _allowedPriceFeeds[token].values();
    }

    /// @notice Returns whether a price feed is allowed to be used for a token
    function isAllowedPriceFeed(address token, address priceFeed) external view returns (bool) {
        return _priceFeedVerified(priceFeed)
            && (
                _allowedPriceFeeds[equivalentTokens[token]].contains(priceFeed)
                    || _allowedPriceFeeds[token].contains(priceFeed)
            );
    }

    /// @notice Returns the staleness period for a price feed
    function getStalenessPeriod(address priceFeed) external view returns (uint32) {
        return priceFeedInfo[priceFeed].stalenessPeriod;
    }

    function computePriceFeedHash(address priceFeed) public pure returns (bytes32) {
        return keccak256(abi.encode(priceFeed));
    }

    /**
     * @notice Adds a security report for a price feed.
     * @param priceFeed The price feed for which an audit is added.
     * @param reportUrl The URL of the security report.
     * @dev Reverts if the caller is not a registered auditor or if the auditor is forbidden.
     *      The corresponding access control logic is implemented in AuditManager
     *      Emits an AuditPriceFeed event upon successful addition of the report.
     */
    function addSecurityReport(address priceFeed, string calldata reportUrl) external {
        bytes32 priceFeedHash = computePriceFeedHash(priceFeed);

        _addSecurityReport(priceFeedHash, msg.sender, reportUrl);

        emit AuditPriceFeed(msg.sender, priceFeed);
    }

    /**
     * @notice Adds a new price feed
     * @param priceFeed The address of the new price feed
     * @param stalenessPeriod Staleness period of the new price feed
     * @dev Reverts if the price feed's latest value is not current based on the staleness period
     */
    function addPriceFeed(address priceFeed, uint32 stalenessPeriod) external onlyOwner nonZeroAddress(priceFeed) {
        if (_knownPriceFeeds.contains(priceFeed)) revert PriceFeedAlreadyAddedException(priceFeed);

        _validatePriceFeed(priceFeed, stalenessPeriod);

        bytes32 priceFeedType;
        uint256 priceFeedVersion;

        try IPriceFeed(priceFeed).contractType() returns (bytes32 _cType) {
            priceFeedType = _cType;
            priceFeedVersion = IPriceFeed(priceFeed).version();
        } catch {
            priceFeedType = "PF_EXTERNAL_ORACLE";
            priceFeedVersion = 0;
        }

        _knownPriceFeeds.add(priceFeed);
        priceFeedInfo[priceFeed].author = msg.sender;
        priceFeedInfo[priceFeed].priceFeedType = priceFeedType;
        priceFeedInfo[priceFeed].stalenessPeriod = stalenessPeriod;
        priceFeedInfo[priceFeed].version = priceFeedVersion;

        emit AddPriceFeed(priceFeed, stalenessPeriod);
    }

    /**
     * @notice Sets the staleness period for an existing price feed
     * @param priceFeed The address of the price feed
     * @param stalenessPeriod New staleness period for the price feed
     * @dev Reverts if the price feed is not added to the global list
     */
    function setStalenessPeriod(address priceFeed, uint32 stalenessPeriod)
        external
        onlyOwner
        nonZeroAddress(priceFeed)
    {
        if (!_knownPriceFeeds.contains(priceFeed)) revert PriceFeedNotKnownException(priceFeed);
        uint32 oldStalenessPeriod = priceFeedInfo[priceFeed].stalenessPeriod;

        if (stalenessPeriod != oldStalenessPeriod) {
            _validatePriceFeed(priceFeed, stalenessPeriod);
            priceFeedInfo[priceFeed].stalenessPeriod = stalenessPeriod;
            emit SetStalenessPeriod(priceFeed, stalenessPeriod);
        }
    }

    /**
     * @notice Allows a price feed for use with a particular token
     * @param token Address of the token
     * @param priceFeed Address of the price feed
     * @dev Reverts if the price feed is not added to the global list
     */
    function allowPriceFeed(address token, address priceFeed) external onlyOwner nonZeroAddress(token) {
        if (!_knownPriceFeeds.contains(priceFeed)) revert PriceFeedNotKnownException(priceFeed);

        _allowedPriceFeeds[token].add(priceFeed);

        emit AllowPriceFeed(token, priceFeed);
    }

    /**
     * @notice Sets an equivalent for a token
     * @param token Address of the token
     * @param equivalentToken Address of the equivalent token
     * @dev A token can use all of the price feeds of its equivalent token (as long as they are verified). A typical use case is a token being staked
     *      into a pool with a strictly 1:1 ratio - in this case the same price feed can be used for both the token and the staked position.
     */
    function setEquivalentToken(address token, address equivalentToken)
        external
        onlyOwner
        nonZeroAddress(token)
        nonZeroAddress(equivalentToken)
    {
        if (equivalentTokens[token] != equivalentToken) {
            equivalentTokens[token] = equivalentToken;
            emit SetEquivalentToken(token, equivalentToken);
        }
    }

    /// @dev Returns whether a price feed has enough audits to be used in production
    function _priceFeedVerified(address priceFeed) internal view returns (bool) {
        uint256 numAuditors = _getUniqueNonForbiddenAuditorCount(computePriceFeedHash(priceFeed));

        return numAuditors >= AUDITOR_THRESHOLD;
    }
}
