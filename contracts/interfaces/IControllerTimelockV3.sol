// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

struct QueuedTransactionData {
    bool queued;
    address initiator;
    address target;
    uint40 eta;
    string signature;
    bytes data;
    uint256 sanityCheckValue;
    bytes sanityCheckCallData;
}

interface IControllerTimelockV3Events {
    /// @notice Emitted when the veto admin of the controller is updated
    event SetVetoAdmin(address indexed newAdmin);

    /// @notice Emitted when an address' status as executor is changed
    event SetExecutor(address indexed executor, bool status);

    /// @notice Emitted when a transaction is queued
    event QueueTransaction(
        bytes32 indexed txHash, address indexed initiator, address target, string signature, bytes data, uint40 eta
    );

    /// @notice Emitted when a transaction is executed
    event ExecuteTransaction(address indexed target, string signature, bytes data);

    /// @notice Emitted when a transaction is cancelled
    event CancelTransaction(bytes32 indexed txHash);
}

interface IControllerTimelockV3Exceptions {
    /// @notice Thrown when the new parameter values do not satisfy required conditions
    error ParameterChecksFailedException();

    /// @notice Thrown when attempting to execute a non-queued transaction
    error TxNotQueuedException();

    /// @notice Thrown when attempting to execute a transaction that is either immature or stale
    error TxExecutedOutsideTimeWindowException();

    /// @notice Thrown when execution of a transaction fails
    error TxExecutionRevertedException();

    /// @notice Thrown when the value of a parameter on execution is different from the value on queue
    error ParameterChangedAfterQueuedTxException();

    /// @notice Thrown when an address that is not the designated executor attempts to execute a transaction
    error CallerNotExecutorException();

    /// @notice Thrown on attempting to call an access restricted function not as veto admin
    error CallerNotVetoAdminException();
}

/// @title Controller timelock V3 interface
interface IControllerTimelockV3 is IControllerTimelockV3Events, IControllerTimelockV3Exceptions, IVersion {
    // -------- //
    // QUEUEING //
    // -------- //

    function setExpirationDate(address creditManager, uint40 expirationDate) external;

    function setMaxDebtPerBlockMultiplier(address creditManager, uint8 multiplier) external;

    function setMinDebtLimit(address creditManager, uint128 minDebt) external;

    function setMaxDebtLimit(address creditManager, uint128 maxDebt) external;

    function setCreditManagerDebtLimit(address creditManager, uint256 debtLimit) external;

    function rampLiquidationThreshold(
        address creditManager,
        address token,
        uint16 liquidationThresholdFinal,
        uint40 rampStart,
        uint24 rampDuration
    ) external;

    function forbidAdapter(address creditManager, address adapter) external;

    function setTotalDebtLimit(address pool, uint256 newLimit) external;

    function setTokenLimit(address pool, address token, uint96 limit) external;

    function setTokenQuotaIncreaseFee(address pool, address token, uint16 quotaIncreaseFee) external;

    function setMinQuotaRate(address pool, address token, uint16 rate) external;

    function setMaxQuotaRate(address pool, address token, uint16 rate) external;

    function setWithdrawFee(address pool, uint256 newFee) external;

    function setLPPriceFeedLimiter(address priceFeed, uint256 lowerBound) external;

    function forbidBoundsUpdate(address priceFeed) external;

    function setPriceFeed(address priceOracle, address token, address priceFeed, uint32 stalenessPeriod) external;

    function allowTemporaryPublicLiquidations(address emergencyLiquidator, uint256 duration) external;

    function allowTemporaryPolicyWaive(address emergencyLiquidator, uint256 duration) external;

    // --------- //
    // EXECUTION //
    // --------- //

    function GRACE_PERIOD() external view returns (uint256);

    function queuedTransactions(bytes32 txHash)
        external
        view
        returns (
            bool queued,
            address initiator,
            address target,
            uint40 eta,
            string memory signature,
            bytes memory data,
            uint256 sanityCheckValue,
            bytes memory sanityCheckCallData
        );

    function executeTransaction(bytes32 txHash) external;

    function cancelTransaction(bytes32 txHash) external;

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function vetoAdmin() external view returns (address);

    function isExecutor(address addr) external view returns (bool);

    function setVetoAdmin(address newAdmin) external;

    function setExecutor(address executor, bool status) external;
}
