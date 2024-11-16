// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {IVersion} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IVersion.sol";
import {DeployParams} from "./Types.sol";

interface IMarketConfigurator is IVersion {
    // ------ //
    // ERRORS //
    // ------ //

    // Thrown if hook attempting to call a contract which is node in accessList
    error ContractNotAssignedToFactoryException(address);

    // Thrown if factory attempting to overwrite exsting addess in accessList
    error ContractAlreadyInAccessListException(address);

    function addressProvider() external view returns (address);
    function marketConfiguratorFactory() external view returns (address);
    function acl() external view returns (address);
    function contractsRegister() external view returns (address);
    function treasury() external view returns (address);

    function emergencyLiquidators() external view returns (address[] memory);

    // ----------------- //
    // MARKET MANAGEMENT //
    // ----------------- //

    function createMarket(
        address underlying,
        address underlyingPriceFeed,
        string calldata name,
        string calldata symbol,
        DeployParams calldata interestRateModelParams,
        DeployParams calldata rateKeeperParams
    ) external returns (address pool);

    function shutdownMarket(address pool) external;

    function addToken(address pool, address token, address priceFeed) external;

    function configurePool(address pool, bytes calldata data) external;

    // ----------------------- //
    // CREDIT SUITE MANAGEMENT //
    // ----------------------- //

    // TODO: probably remove postfix
    function createCreditSuite(address pool, bytes calldata encdodedParams) external returns (address creditManager);

    function shutdownCreditSuite(address creditManager) external;

    function configureCreditSuite(address creditManager, bytes calldata data) external;

    // ----------------------- //
    // PRICE ORACLE MANAGEMENT //
    // ----------------------- //

    function updatePriceOracle(address pool) external returns (address priceOracle);

    function setPriceFeed(address pool, address token, address priceFeed) external;

    function setReservePriceFeed(address pool, address token, address priceFeed) external;

    // -------------- //
    // IRM MANAGEMENT //
    // -------------- //

    function updateInterestRateModel(address pool, DeployParams calldata params) external returns (address irm);

    function configureInterestRateModel(address pool, bytes calldata data) external;

    // ---------------------- //
    // RATE KEEPER MANAGEMENT //
    // ---------------------- //

    function updateRateKeeper(address pool, DeployParams calldata params) external returns (address rateKeeper);

    function configureRateKeeper(address pool, bytes calldata data) external;

    // -–------------------------ //
    // LOSS LIQUIDATOR MANAGEMENT //
    // -–------------------------ //

    function updateLossLiquidator(address pool, DeployParams calldata params)
        external
        returns (address lossLiqudiator);

    function configureLossLiquidator(address pool, bytes calldata data) external;

    // ---------------- //
    // ROLES MANAGEMENT //
    // ---------------- //

    function addPausableAdmin(address admin) external;

    function addUnpausableAdmin(address admin) external;

    function removePausableAdmin(address admin) external;

    function removeUnpausableAdmin(address admin) external;

    function addEmergencyLiquidator(address liquidator) external;

    function removeEmergencyLiquidator(address liquidator) external;
}
