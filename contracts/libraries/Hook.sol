// SPDX-License-Identifier: UNLICENSED
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {Call} from "../interfaces/Types.sol";
import {IMarketHooks} from "../interfaces/IMarketHooks.sol";
import {ICreditHooks} from "../interfaces/ICreditHooks.sol";

interface IHook {}

struct HookCheck {
    address factory;
    Call[] calls;
}

// TODO: refactor this thing and `IMarketHooks` / `ICreditHooks`, it all seems so redundant

library HookExecutor {
    function onCreateMarket(
        IHook factory,
        address pool,
        address priceOracle,
        address interestRateModel,
        address rateKeeper,
        address underlyingPriceFeed
    ) internal returns (HookCheck memory) {
        return HookCheck({
            factory: address(factory),
            calls: IMarketHooks(address(factory)).onCreateMarket(
                pool, priceOracle, interestRateModel, rateKeeper, underlyingPriceFeed
            )
        });
    }

    function onShutdownMarket(IHook factory, address pool) internal returns (HookCheck memory) {
        return HookCheck({factory: address(factory), calls: IMarketHooks(address(factory)).onShutdownMarket(pool)});
    }

    function onAddToken(IHook factory, address pool, address token, address priceFeed)
        internal
        returns (HookCheck memory)
    {
        return HookCheck({
            factory: address(factory),
            calls: IMarketHooks(address(factory)).onAddToken(pool, token, priceFeed)
        });
    }

    function onUpdateInterestRateModel(
        IHook factory,
        address pool,
        address newInterestRateModel,
        address oldInterestRateModel
    ) internal returns (HookCheck memory) {
        return HookCheck({
            factory: address(factory),
            calls: IMarketHooks(address(factory)).onUpdateInterestRateModel(
                pool, newInterestRateModel, oldInterestRateModel
            )
        });
    }

    function onUpdateRateKeeper(IHook factory, address pool, address newRateKeeper, address oldRateKeeper)
        internal
        returns (HookCheck memory)
    {
        return HookCheck({
            factory: address(factory),
            calls: IMarketHooks(address(factory)).onUpdateRateKeeper(pool, newRateKeeper, oldRateKeeper)
        });
    }

    function onCreateCreditSuite(IHook factory, address pool, address newCreditManager)
        internal
        returns (HookCheck memory)
    {
        return HookCheck({
            factory: address(factory),
            calls: IMarketHooks(address(factory)).onCreateCreditSuite(pool, newCreditManager)
        });
    }

    function onShutdownCreditSuite(IHook factory, address _creditManager) internal returns (HookCheck memory) {
        return HookCheck({
            factory: address(factory),
            calls: IMarketHooks(address(factory)).onShutdownCreditSuite(_creditManager)
        });
    }

    function onUpdatePriceOracle(IHook factory, address pool, address newPriceOracle, address oldPriceOracle)
        internal
        returns (HookCheck memory)
    {
        return HookCheck({
            factory: address(factory),
            calls: IMarketHooks(address(factory)).onUpdatePriceOracle(pool, newPriceOracle, oldPriceOracle)
        });
    }

    function onSetPriceFeed(IHook factory, address pool, address token, address priceFeed)
        internal
        returns (HookCheck memory)
    {
        return HookCheck({
            factory: address(factory),
            calls: IMarketHooks(address(factory)).onSetPriceFeed(pool, token, priceFeed)
        });
    }

    function onSetReservePriceFeed(IHook factory, address pool, address token, address priceFeed)
        internal
        returns (HookCheck memory)
    {
        return HookCheck({
            factory: address(factory),
            calls: IMarketHooks(address(factory)).onSetReservePriceFeed(pool, token, priceFeed)
        });
    }

    function onAddEmergencyLiquidator(IHook factory, address creditManager, address emergencyLiquidator)
        internal
        returns (HookCheck memory)
    {
        return HookCheck({
            factory: address(factory),
            calls: ICreditHooks(address(factory)).onAddEmergencyLiquidator(creditManager, emergencyLiquidator)
        });
    }

    function onRemoveEmergencyLiquidator(IHook factory, address creditManager, address emergencyLiquidator)
        internal
        returns (HookCheck memory)
    {
        return HookCheck({
            factory: address(factory),
            calls: ICreditHooks(address(factory)).onRemoveEmergencyLiquidator(creditManager, emergencyLiquidator)
        });
    }

    function onUpdateLossLiquidator(
        IHook factory,
        address creditManager,
        address newLossLiquidator,
        address oldLossLiquidator
    ) internal returns (HookCheck memory) {
        return HookCheck({
            factory: address(factory),
            calls: ICreditHooks(address(factory)).onUpdateLossLiquidator(
                creditManager, newLossLiquidator, oldLossLiquidator
            )
        });
    }
}
