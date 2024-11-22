// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {SanityCheckTrait} from "@gearbox-protocol/core-v3/contracts/traits/SanityCheckTrait.sol";
import {PriceFeedValidationTrait} from "@gearbox-protocol/core-v3/contracts/traits/PriceFeedValidationTrait.sol";
import {IPriceFeed} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IPriceFeed.sol";

import {IPriceFeedStore} from "../interfaces/IPriceFeedStore.sol";
import {AP_PRICE_FEED_STORE} from "../libraries/ContractLiterals.sol";
import {SecurityReport, PriceFeedInfo, AuditorInfo} from "../interfaces/Types.sol";

contract PriceFeedStore is Ownable2Step, SanityCheckTrait, PriceFeedValidationTrait, IPriceFeedStore {
    using EnumerableSet for EnumerableSet.AddressSet;

    //
    // CONSTANTS
    //

    /// @notice Meta info about contract type & version
    uint256 public constant override version = 3_10;
    bytes32 public constant override contractType = AP_PRICE_FEED_STORE;

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

    /// @notice Returns the list of price feeds available for a token
    function getPriceFeeds(address token) external view returns (address[] memory) {
        address[] memory priceFeeds = _allowedPriceFeeds[token].values();
        address[] memory equivalentPriceFeeds = _allowedPriceFeeds[equivalentTokens[token]].values();

        return _mergeArrays(priceFeeds, equivalentPriceFeeds);
    }

    /// @dev Merges two address arrays so that there are no repetitions
    function _mergeArrays(address[] memory a0, address[] memory a1) internal pure returns (address[] memory result) {
        uint256 len0 = a0.length;
        uint256 len1 = a1.length;

        address[] memory _res = new address[](len0 + len1);

        for (uint256 i = 0; i < len0;) {
            _res[i] = a0[i];

            unchecked {
                ++i;
            }
        }

        uint256 k = len0;

        for (uint256 i = 0; i < len1;) {
            for (uint256 j = 0; j <= k;) {
                if (j == k) {
                    _res[k] = a1[i];
                    ++k;
                    break;
                }

                if (_res[j] == a1[i]) break;

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        result = new address[](k);

        for (uint256 i = 0; i < k;) {
            result[i] = _res[i];

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Returns whether a price feed is allowed to be used for a token
    function isAllowedPriceFeed(address token, address priceFeed) external view returns (bool) {
        return _allowedPriceFeeds[equivalentTokens[token]].contains(priceFeed)
            || _allowedPriceFeeds[token].contains(priceFeed);
    }

    /// @notice Returns the staleness period for a price feed
    function getStalenessPeriod(address priceFeed) external view returns (uint32) {
        return priceFeedInfo[priceFeed].stalenessPeriod;
    }

    /**
     * @notice Adds a new price feed
     * @param priceFeed The address of the new price feed
     * @param stalenessPeriod Staleness period of the new price feed
     * @dev Reverts if the price feed's result is stale based on the staleness period
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
     * @notice Forbids a price feed for use with a particular token
     * @param token Address of the token
     * @param priceFeed Address of the price feed
     * @dev Reverts if the price feed is not added to the global list or the per-token list
     */
    function forbidPriceFeed(address token, address priceFeed) external onlyOwner nonZeroAddress(token) {
        if (!_knownPriceFeeds.contains(priceFeed)) revert PriceFeedNotKnownException(priceFeed);
        if (!_allowedPriceFeeds[token].contains(priceFeed)) revert PriceFeedIsNotAllowedException(token, priceFeed);

        _allowedPriceFeeds[token].remove(priceFeed);

        emit ForbidPriceFeed(token, priceFeed);
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
}
