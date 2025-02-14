// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

import {SanityCheckTrait} from "@gearbox-protocol/core-v3/contracts/traits/SanityCheckTrait.sol";
import {PriceFeedValidationTrait} from "@gearbox-protocol/core-v3/contracts/traits/PriceFeedValidationTrait.sol";
import {IPriceFeed, IUpdatablePriceFeed} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IPriceFeed.sol";

import {IPriceFeedStore} from "../interfaces/IPriceFeedStore.sol";
import {
    AP_PRICE_FEED_STORE,
    AP_INSTANCE_MANAGER_PROXY,
    AP_BYTECODE_REPOSITORY,
    NO_VERSION_CONTROL
} from "../libraries/ContractLiterals.sol";
import {IAddressProvider} from "../interfaces/IAddressProvider.sol";
import {ConnectedPriceFeed, PriceFeedInfo, PriceUpdate} from "../interfaces/Types.sol";
import {NestedPriceFeeds} from "../libraries/NestedPriceFeeds.sol";
import {ImmutableOwnableTrait} from "../traits/ImmutableOwnableTrait.sol";
import {IBytecodeRepository} from "../interfaces/IBytecodeRepository.sol";

contract PriceFeedStore is ImmutableOwnableTrait, SanityCheckTrait, PriceFeedValidationTrait, IPriceFeedStore {
    using EnumerableSet for EnumerableSet.AddressSet;
    using NestedPriceFeeds for IPriceFeed;

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

    /// @dev Set of all known price feeds
    EnumerableSet.AddressSet internal _knownTokens;

    /// @dev Set of all updatable price feeds
    EnumerableSet.AddressSet internal _updatablePriceFeeds;

    /// @dev Mapping from token address to its set of allowed price feeds
    mapping(address token => EnumerableSet.AddressSet) internal _allowedPriceFeeds;

    /// @dev Mapping from a (token, priceFeed) pair to a timestamp when price feed was allowed for token
    mapping(address token => mapping(address priceFeed => uint256)) _allowanceTimestamps;

    /// @notice Mapping from price feed address to its data
    mapping(address => PriceFeedInfo) internal _priceFeedInfo;

    address immutable bytecodeRepository;

    constructor(address _addressProvider)
        ImmutableOwnableTrait(
            IAddressProvider(_addressProvider).getAddressOrRevert(AP_INSTANCE_MANAGER_PROXY, NO_VERSION_CONTROL)
        )
    {
        bytecodeRepository =
            IAddressProvider(_addressProvider).getAddressOrRevert(AP_BYTECODE_REPOSITORY, NO_VERSION_CONTROL);
    }

    /// @notice Returns the list of price feeds available for a token
    function getPriceFeeds(address token) public view returns (address[] memory) {
        return _allowedPriceFeeds[token].values();
    }

    /// @notice Returns whether a price feed is allowed to be used for a token
    function isAllowedPriceFeed(address token, address priceFeed) external view returns (bool) {
        return _allowedPriceFeeds[token].contains(priceFeed);
    }

    /// @notice Returns the staleness period for a price feed
    function getStalenessPeriod(address priceFeed) external view returns (uint32) {
        return _priceFeedInfo[priceFeed].stalenessPeriod;
    }

    /// @notice Returns the timestamp when priceFeed was allowed for token
    function getAllowanceTimestamp(address token, address priceFeed) external view returns (uint256) {
        if (!_allowedPriceFeeds[token].contains(priceFeed)) revert PriceFeedIsNotAllowedException(token, priceFeed);
        return _allowanceTimestamps[token][priceFeed];
    }

    function isKnownToken(address token) external view returns (bool) {
        return _knownTokens.contains(token);
    }

    function getKnownTokens() external view returns (address[] memory) {
        return _knownTokens.values();
    }

    function getTokenPriceFeedsMap() external view returns (ConnectedPriceFeed[] memory) {
        address[] memory tokens = _knownTokens.values();
        ConnectedPriceFeed[] memory connectedPriceFeeds = new ConnectedPriceFeed[](tokens.length);

        uint256 len = tokens.length;
        for (uint256 i = 0; i < len; ++i) {
            connectedPriceFeeds[i].token = tokens[i];
            connectedPriceFeeds[i].priceFeeds = getPriceFeeds(tokens[i]);
        }
        return connectedPriceFeeds;
    }

    function isKnownPriceFeed(address priceFeed) external view returns (bool) {
        return _knownPriceFeeds.contains(priceFeed);
    }

    function getKnownPriceFeeds() external view returns (address[] memory) {
        return _knownPriceFeeds.values();
    }

    /**
     * @notice Adds a new price feed
     * @param priceFeed The address of the new price feed
     * @param stalenessPeriod Staleness period of the new price feed
     * @dev Reverts if the price feed's result is stale based on the staleness period
     */
    function addPriceFeed(address priceFeed, uint32 stalenessPeriod, string calldata _name)
        external
        onlyOwner
        nonZeroAddress(priceFeed)
    {
        if (!_knownPriceFeeds.add(priceFeed)) revert PriceFeedAlreadyAddedException(priceFeed);

        _validatePriceFeed(priceFeed, stalenessPeriod);
        bool isExternal = _validatePriceFeedTree(priceFeed);

        _priceFeedInfo[priceFeed] = PriceFeedInfo({
            author: msg.sender,
            stalenessPeriod: stalenessPeriod,
            priceFeedType: isExternal ? bytes32("PRICE_FEED::EXTERNAL") : IPriceFeed(priceFeed).contractType(),
            version: isExternal ? 0 : IPriceFeed(priceFeed).version(),
            name: _name
        });

        emit AddPriceFeed(priceFeed, stalenessPeriod, _name);
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
        uint32 oldStalenessPeriod = _priceFeedInfo[priceFeed].stalenessPeriod;

        if (stalenessPeriod != oldStalenessPeriod) {
            _validatePriceFeed(priceFeed, stalenessPeriod);
            _priceFeedInfo[priceFeed].stalenessPeriod = stalenessPeriod;
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
        if (!_allowedPriceFeeds[token].add(priceFeed)) return;

        _allowanceTimestamps[token][priceFeed] = block.timestamp;
        _knownTokens.add(token);

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
        _allowanceTimestamps[token][priceFeed] = 0;

        emit ForbidPriceFeed(token, priceFeed);
    }

    function priceFeedInfo(address priceFeed) external view returns (PriceFeedInfo memory) {
        return _priceFeedInfo[priceFeed];
    }

    function getUpdatablePriceFeeds() external view returns (address[] memory) {
        return _updatablePriceFeeds.values();
    }

    function updatePrices(PriceUpdate[] calldata updates) external {
        uint256 numUpdates = updates.length;
        for (uint256 i; i < numUpdates; ++i) {
            if (!_updatablePriceFeeds.contains(updates[i].priceFeed)) {
                revert PriceFeedIsNotUpdatableException(updates[i].priceFeed);
            }
            IUpdatablePriceFeed(updates[i].priceFeed).updatePrice(updates[i].data);
        }
    }

    function _validatePriceFeedTree(address priceFeed) internal returns (bool) {
        if (_validatePriceFeedDeployment(priceFeed)) return true;

        if (_isUpdatable(priceFeed) && _updatablePriceFeeds.add(priceFeed)) emit AddUpdatablePriceFeed(priceFeed);
        address[] memory underlyingFeeds = IPriceFeed(priceFeed).getUnderlyingFeeds();
        uint256 numFeeds = underlyingFeeds.length;
        for (uint256 i; i < numFeeds; ++i) {
            _validatePriceFeedTree(underlyingFeeds[i]);
        }

        return false;
    }

    function _validatePriceFeedDeployment(address priceFeed) internal view returns (bool) {
        if (IBytecodeRepository(bytecodeRepository).deployedContracts(priceFeed) == 0) return true;

        try Ownable2Step(priceFeed).owner() returns (address owner_) {
            if (owner_ != address(this)) revert PriceFeedIsNotOwnedByStore(priceFeed);
            try Ownable2Step(priceFeed).pendingOwner() returns (address pendingOwner_) {
                if (pendingOwner_ != address(0)) revert PriceFeedIsNotOwnedByStore(priceFeed);
            } catch {}
        } catch {}

        return false;
    }

    function _isUpdatable(address priceFeed) internal view returns (bool) {
        try IUpdatablePriceFeed(priceFeed).updatable() returns (bool updatable) {
            return updatable;
        } catch {
            return false;
        }
    }
}
