// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {IPriceFeed, IUpdatablePriceFeed} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IPriceFeed.sol";
import {IPoolV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPoolV3.sol";
import {IPriceOracleV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPriceOracleV3.sol";

import {IContractsRegister} from "../interfaces/extensions/IContractsRegister.sol";
import {IMarketConfigurator} from "../interfaces/IMarketConfigurator.sol";
import {IMarketHooks} from "../interfaces/IMarketHooks.sol";
import {IPriceFeedStore} from "../interfaces/IPriceFeedStore.sol";
import {IPriceOracleFactory} from "../interfaces/IPriceOracleFactory.sol";
import {Call, DeployResult} from "../interfaces/Types.sol";

import {CallBuilder} from "../libraries/CallBuilder.sol";
import {
    AP_PRICE_ORACLE,
    AP_PRICE_ORACLE_FACTORY,
    AP_PRICE_FEED_STORE,
    NO_VERSION_CONTROL
} from "../libraries/ContractLiterals.sol";
import {NestedPriceFeeds} from "../libraries/NestedPriceFeeds.sol";

import {AbstractFactory} from "./AbstractFactory.sol";
import {MarketHookFactory} from "./MarketHookFactory.sol";

contract PriceOracleFactory is IPriceOracleFactory, AbstractFactory, MarketHookFactory {
    using CallBuilder for Call[];
    using NestedPriceFeeds for IPriceFeed;

    /// @notice Contract version
    uint256 public constant override version = 3_10;

    /// @notice Contract type
    bytes32 public constant override contractType = AP_PRICE_ORACLE_FACTORY;

    /// @notice TODO
    address public immutable priceFeedStore;

    /// @notice Thrown if an unauthorized price feed is used for a token
    error PriceFeedNotAllowedException(address token, address priceFeed);

    /// @notice Constructor
    /// @param addressProvider_ Address provider contract address
    constructor(address addressProvider_) AbstractFactory(addressProvider_) {
        priceFeedStore = _getContract(AP_PRICE_FEED_STORE, NO_VERSION_CONTROL);
    }

    function deployPriceOracle(address pool) external override marketConfiguratorsOnly returns (DeployResult memory) {
        address acl = IPoolV3(pool).acl();

        address priceOracle = _deploy({
            type_: AP_PRICE_ORACLE,
            version_: version,
            constructorParams: abi.encode(acl),
            salt: bytes32(bytes20(msg.sender))
        });

        address[] memory accessList = new address[](1);
        accessList[0] = priceOracle;

        return DeployResult({newContract: priceOracle, accessList: accessList, onInstallOps: new Call[](0)});
    }

    // ------------ //
    // MARKET HOOKS //
    // ------------ //

    function onCreateMarket(address pool, address priceOracle, address, address, address underlyingPriceFeed)
        external
        view
        override(IMarketHooks, MarketHookFactory)
        returns (Call[] memory)
    {
        return _setPriceFeed(priceOracle, IPoolV3(pool).underlyingToken(), underlyingPriceFeed, false);
    }

    function onUpdatePriceOracle(address, address newPriceOracle, address oldPriceOracle)
        external
        view
        override(IMarketHooks, MarketHookFactory)
        marketConfiguratorsOnly
        returns (Call[] memory calls)
    {
        // QUESTION: how come pool never pops up in this function?
        // seems like either `priceOracle` or `prevOracle` is redundant as it can be read from the contracts register
        address[] memory tokens = IPriceOracleV3(oldPriceOracle).getTokens();

        uint256 numTokens = tokens.length;
        for (uint256 i; i < numTokens; ++i) {
            // FIXME: reallocating the whole array is not the most optimal solution
            // this one might actually be quite bad because the number of operations is not negligible
            calls = calls.extend(
                _setPriceFeed(newPriceOracle, tokens[i], _getPriceFeed(oldPriceOracle, tokens[i], false), false)
            );

            address reserve = _getPriceFeed(oldPriceOracle, tokens[i], true);
            if (reserve != address(0)) {
                calls = calls.extend(_setPriceFeed(newPriceOracle, tokens[i], reserve, true));
            }
        }
    }

    function onAddToken(address pool, address token, address priceFeed)
        external
        view
        override(IMarketHooks, MarketHookFactory)
        marketConfiguratorsOnly
        returns (Call[] memory)
    {
        // TODO: reconsider, maybe should add other checks
        address contractsRegister = IMarketConfigurator(msg.sender).contractsRegister();
        address priceOracle = IContractsRegister(contractsRegister).getPriceOracle(pool);
        return _setPriceFeed(priceOracle, token, priceFeed, false);
    }

    function onSetPriceFeed(address pool, address token, address priceFeed)
        external
        view
        override(IMarketHooks, MarketHookFactory)
        marketConfiguratorsOnly
        returns (Call[] memory)
    {
        address contractsRegister = IMarketConfigurator(msg.sender).contractsRegister();
        address priceOracle = IContractsRegister(contractsRegister).getPriceOracle(pool);
        return _setPriceFeed(priceOracle, token, priceFeed, false);
    }

    function onSetReservePriceFeed(address pool, address token, address priceFeed)
        external
        view
        override(IMarketHooks, MarketHookFactory)
        marketConfiguratorsOnly
        returns (Call[] memory)
    {
        address contractsRegister = IMarketConfigurator(msg.sender).contractsRegister();
        address priceOracle = IContractsRegister(contractsRegister).getPriceOracle(pool);
        return _setPriceFeed(priceOracle, token, priceFeed, true);
    }

    // --------- //
    // INTERNALS //
    // --------- //

    function _getPriceFeed(address priceOracle, address token, bool reserve) internal view returns (address) {
        return reserve
            ? IPriceOracleV3(priceOracle).reservePriceFeeds(token)
            : IPriceOracleV3(priceOracle).priceFeeds(token);
    }

    function _setPriceFeed(address priceOracle, address token, address priceFeed, bool reserve)
        internal
        view
        returns (Call[] memory)
    {
        if (!IPriceFeedStore(priceFeedStore).isAllowedPriceFeed(token, priceFeed)) {
            revert PriceFeedNotAllowedException(token, priceFeed);
        }
        uint32 stalenessPeriod = IPriceFeedStore(priceFeedStore).getStalenessPeriod(priceFeed);

        Call[] memory calls = new Call[](1);
        calls[0] = reserve
            ? _setReservePriceFeed(priceOracle, token, priceFeed, stalenessPeriod)
            : _setPriceFeed(priceOracle, token, priceFeed, stalenessPeriod);

        return _addUpdatableFeeds(priceOracle, priceFeed, calls);
    }

    function _addUpdatableFeeds(address priceOracle, address priceFeed, Call[] memory calls)
        internal
        view
        returns (Call[] memory)
    {
        try IUpdatablePriceFeed(priceFeed).updatable() returns (bool updatable) {
            // FIXME: reallocating the whole array is not the most optimal solution
            // although not as bad unless we use extraordinarily nested updatable price feeds
            if (updatable) calls = calls.append(_addUpdatablePriceFeed(priceOracle, priceFeed));
        } catch {}
        address[] memory underlyingFeeds = IPriceFeed(priceFeed).getUnderlyingFeeds();
        uint256 numFeeds = underlyingFeeds.length;
        for (uint256 i; i < numFeeds; ++i) {
            calls = _addUpdatableFeeds(priceOracle, underlyingFeeds[i], calls);
        }
        return calls;
    }

    function _setPriceFeed(address priceOracle, address token, address priceFeed, uint32 stalenessPeriod)
        internal
        pure
        returns (Call memory)
    {
        return Call({
            target: priceOracle,
            callData: abi.encodeCall(IPriceOracleV3.setPriceFeed, (token, priceFeed, stalenessPeriod))
        });
    }

    function _setReservePriceFeed(address priceOracle, address token, address priceFeed, uint32 stalenessPeriod)
        internal
        pure
        returns (Call memory)
    {
        return Call({
            target: priceOracle,
            callData: abi.encodeCall(IPriceOracleV3.setReservePriceFeed, (token, priceFeed, stalenessPeriod))
        });
    }

    function _addUpdatablePriceFeed(address priceOracle, address priceFeed) internal pure returns (Call memory) {
        return Call({target: priceOracle, callData: abi.encodeCall(IPriceOracleV3.addUpdatablePriceFeed, (priceFeed))});
    }
}
