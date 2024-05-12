// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IACL} from "./interfaces/IACL.sol";
import {ACLTrait} from "@gearbox-protocol/core-v3/contracts/traits/ACLTrait.sol";

import {
    IControllerTimelockV3,
    QueuedTransactionData,
    Policy,
    UintRange,
    PolicyType,
    PolicyState,
    PolicyUintRange,
    PolicyAddressSet,
    AddressSet
} from "./interfaces/IControllerTimelockV3.sol";
import {ICreditManagerV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import {ICreditFacadeV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditFacadeV3.sol";
import {IPoolV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPoolV3.sol";
import {IPoolQuotaKeeperV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPoolQuotaKeeperV3.sol";
import {IGaugeV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IGaugeV3.sol";
import {IPriceOracleV3, PriceFeedParams} from "@gearbox-protocol/core-v3/contracts/interfaces/IPriceOracleV3.sol";
import {ILPPriceFeedV2} from "@gearbox-protocol/core-v2/contracts/interfaces/ILPPriceFeedV2.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Controller timelock V3
/// @notice Controller timelock is a governance contract that allows special actors less trusted than Gearbox Governance
///         to modify system parameters within set boundaries. This is mostly related to risk parameters that should be
///         adjusted frequently or periodic tasks (e.g., updating price feed limiters) that are too trivial to employ
///         the full governance for.
/// @dev The contract uses `PolicyManager` as its underlying engine to set parameter change boundaries and conditions.
///      In order to schedule a change for a particular contract / function combination, a policy needs to be defined
///      for it. The policy also determines the address that can change a particular parameter.
contract ControllerTimelockV3 is ACLTrait, IControllerTimelockV3 {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Contract version
    uint256 public constant override version = 3_10;

    error PolicyNotExistsException();
    error CallerIsNotPolicyAdminException();
    error UintIsNotInRange(uint256, uint256);
    error AddressIsNotInSet(address[]);

    mapping(string => Policy) public policies;
    mapping(string => UintRange) public allowedRanges;
    mapping(string => mapping(address => EnumerableSet.AddressSet)) internal allowedAddressSets;

    mapping(string => EnumerableSet.AddressSet) internal allowedAddressSetKeys;

    // set all policies for this contract
    string[17] public keys = [
        "setExpirationDate",
        "setLPPriceFeedLimiter",
        "setMaxDebtPerBlockMultiplier",
        "setMinDebtLimit",
        "setMaxDebtLimit",
        "setCreditManagerDebtLimit",
        "rampLiquidationThreshold",
        "rampLiquidationThreshold_rampDuration",
        "forbidAdapter",
        "setTokenLimit",
        "setTotalDebtLimit",
        "setTokenQuotaIncreaseFee",
        "setWithdrawFee",
        "setMinQuotaRate",
        "setMaxQuotaRate",
        "forbidBoundsUpdate",
        "setPriceFeed"
    ];

    /// @dev Minimum liquidation threshold ramp duration
    uint256 constant MIN_LT_RAMP_DURATION = 7 days;

    /// @notice Period before a mature transaction becomes stale
    uint256 public constant override GRACE_PERIOD = 14 days;

    /// @notice Admin address that can cancel transactions
    address public override vetoAdmin;

    /// @notice Mapping from address to their status as executor
    EnumerableSet.AddressSet internal _executors;

    /// @notice Mapping from transaction hashes to their data
    mapping(bytes32 => QueuedTransactionData) public override queuedTransactions;

    /// @notice Constructor
    /// @param _acl Address of acl contract
    /// @param _vetoAdmin Admin that can cancel transactions
    constructor(address _acl, address _vetoAdmin) ACLTrait(_acl) {
        vetoAdmin = _vetoAdmin;

        uint256 len = keys.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                policies[keys[i]].admin = IACL(_acl).owner();
                policies[keys[i]].policyType = PolicyType.UintRange;
            }
        }

        policies["setPriceFeed"].policyType = PolicyType.AddressInSet;
    }

    /// @dev Ensures that function caller is the veto admin
    modifier vetoAdminOnly() {
        _revertIfCallerIsNotVetoAdmin();
        _;
    }

    /// @dev Reverts if `msg.sender` is not the veto admin
    function _revertIfCallerIsNotVetoAdmin() internal view {
        if (msg.sender != vetoAdmin) {
            revert CallerNotVetoAdminException();
        }
    }

    /// @dev Performs parameter checks, with policy retrieved based on policy UID
    modifier existingPolicyOnly(string memory policyID) {
        _ensurePolicyExists(policyID);
        _;
    }

    /// @dev Performs parameter checks, with policy retrieved based on policy UID
    modifier policyAdminOnly(string memory policyID) {
        _ensurePolicyAdmin(policyID);
        _;
    }

    modifier policyCheckAdminValueInRange(string memory policyID, uint256 value) {
        _ensurePolicyAdmin(policyID);
        _ensureUintInRange(policyID, value);
        _;
    }

    modifier checkAdditionalValueInRange(string memory policyID, uint256 value) {
        _ensureUintInRange(policyID, value);
        _;
    }

    modifier policyCheckAdminValueInList(string memory policyID, address key, address value) {
        _ensurePolicyAdmin(policyID);
        _ensureAddressInList(policyID, key, value);
        _;
    }

    function _ensurePolicyExists(string memory policyID) internal view {
        if (policies[policyID].admin == address(0)) {
            revert PolicyNotExistsException();
        }
    }

    function _ensurePolicyAdmin(string memory policyID) internal view {
        address admin = policies[policyID].admin;
        if (admin == address(0)) {
            revert PolicyNotExistsException();
        }

        if (msg.sender != admin) {
            revert CallerIsNotPolicyAdminException();
        }
    }

    function _ensureUintInRange(string memory policyID, uint256 value) internal view {
        UintRange storage range = allowedRanges[policyID];
        if (value < range.minValue || value > range.maxValue) {
            revert UintIsNotInRange(range.minValue, range.maxValue);
        }
    }

    function _ensureAddressInList(string memory policyID, address key, address value) internal view {
        EnumerableSet.AddressSet storage set = allowedAddressSets[policyID][key];
        if (!set.contains(value)) {
            revert AddressIsNotInSet(set.values());
        }
    }

    // -------- //
    // QUEUEING //
    // -------- //

    /// @notice Queues a transaction to set a new expiration date in the Credit Facade
    /// @dev Requires the policy for keccak(group(creditManager), "EXPIRATION_DATE") to be enabled,
    ///      otherwise auto-fails the check
    /// @param creditManager Adress of CM to update the expiration date for
    /// @param expirationDate The new expiration date
    function setExpirationDate(address creditManager, uint40 expirationDate)
        external
        override
        policyCheckAdminValueInRange("setExpirationDate", uint256(expirationDate))
    {
        address creditConfigurator = ICreditManagerV3(creditManager).creditConfigurator();
        IPoolV3 pool = IPoolV3(ICreditManagerV3(creditManager).pool());

        uint256 totalBorrowed = pool.creditManagerBorrowed(address(creditManager));

        if (totalBorrowed != 0) {
            revert ParameterChecksFailedException(); // U:[CT-1]
        }

        _queueTransaction({
            policy: "setExpirationDate",
            target: creditConfigurator,
            signature: "setExpirationDate(uint40)",
            data: abi.encode(expirationDate),
            sanityCheckCallData: abi.encodeCall(this.getExpirationDate, (creditManager))
        }); // U:[CT-1]
    }

    /// @dev Retrieves current expiration date for a credit manager
    function getExpirationDate(address creditManager) public view returns (uint40) {
        return ICreditFacadeV3(ICreditManagerV3(creditManager).creditFacade()).expirationDate();
    }

    /// @notice Queues a transaction to set a new limiter value in a price feed
    /// @dev Requires the policy for keccak(group(priceFeed), "LP_PRICE_FEED_LIMITER") to be enabled,
    ///      otherwise auto-fails the check
    /// @param priceFeed The price feed to update the limiter in
    /// @param lowerBound The new limiter lower bound value
    function setLPPriceFeedLimiter(address priceFeed, uint256 lowerBound)
        external
        override
        policyCheckAdminValueInRange("setLPPriceFeedLimiter", lowerBound)
    {
        _queueTransaction({
            policy: "setLPPriceFeedLimiter",
            target: priceFeed,
            signature: "setLimiter(uint256)",
            data: abi.encode(lowerBound),
            sanityCheckCallData: abi.encodeCall(this.getPriceFeedLowerBound, (priceFeed))
        }); // U:[CT-2]
    }

    /// @dev Retrieves current lower bound for a price feed
    function getPriceFeedLowerBound(address priceFeed) public view returns (uint256) {
        return ILPPriceFeedV2(priceFeed).lowerBound();
    }

    /// @notice Queues a transaction to set a new max debt per block multiplier
    /// @dev Requires the policy for keccak(group(creditManager), "MAX_DEBT_PER_BLOCK_MULTIPLIER") to be enabled,
    ///      otherwise auto-fails the check
    /// @param creditManager Adress of CM to update the multiplier for
    /// @param multiplier The new multiplier value
    function setMaxDebtPerBlockMultiplier(address creditManager, uint8 multiplier)
        external
        override
        policyCheckAdminValueInRange("setMaxDebtPerBlockMultiplier", uint256(multiplier))
    {
        _queueTransaction({
            policy: "setMaxDebtPerBlockMultiplier",
            target: ICreditManagerV3(creditManager).creditConfigurator(),
            signature: "setMaxDebtPerBlockMultiplier(uint8)",
            data: abi.encode(multiplier),
            sanityCheckCallData: abi.encodeCall(this.getMaxDebtPerBlockMultiplier, (creditManager))
        }); // U:[CT-3]
    }

    /// @dev Retrieves current max debt per block multiplier for a Credit Facade
    function getMaxDebtPerBlockMultiplier(address creditManager) public view returns (uint8) {
        return ICreditFacadeV3(ICreditManagerV3(creditManager).creditFacade()).maxDebtPerBlockMultiplier();
    }

    /// @notice Queues a transaction to set a new min debt per account
    /// @dev Requires the policy for keccak(group(creditManager), "MIN_DEBT") to be enabled,
    ///      otherwise auto-fails the check
    /// @param creditManager Adress of CM to update the limits for
    /// @param minDebt The new minimal debt amount
    function setMinDebtLimit(address creditManager, uint128 minDebt)
        external
        override
        policyCheckAdminValueInRange("setMinDebtLimit", uint256(minDebt))
    {
        _queueTransaction({
            policy: "setMinDebtLimit",
            target: ICreditManagerV3(creditManager).creditConfigurator(),
            signature: "setMinDebtLimit(uint128)",
            data: abi.encode(minDebt),
            sanityCheckCallData: abi.encodeCall(this.getMinDebtLimit, (creditManager))
        }); // U:[CT-4A]
    }

    /// @dev Retrieves the current min debt limit for a Credit Manager
    function getMinDebtLimit(address creditManager) public view returns (uint128) {
        (uint128 minDebtCurrent,) = ICreditFacadeV3(ICreditManagerV3(creditManager).creditFacade()).debtLimits();
        return minDebtCurrent;
    }

    /// @notice Queues a transaction to set a new max debt per account
    /// @dev Requires the policy for keccak(group(creditManager), "MAX_DEBT") to be enabled,
    ///      otherwise auto-fails the check
    /// @param creditManager Adress of CM to update the limits for
    /// @param maxDebt The new maximal debt amount
    function setMaxDebtLimit(address creditManager, uint128 maxDebt)
        external
        override
        policyCheckAdminValueInRange("setMaxDebtLimit", uint256(maxDebt))
    {
        _queueTransaction({
            policy: "setMinDebtLimit",
            target: ICreditManagerV3(creditManager).creditConfigurator(),
            signature: "setMaxDebtLimit(uint128)",
            data: abi.encode(maxDebt),
            sanityCheckCallData: abi.encodeCall(this.getMaxDebtLimit, (creditManager))
        }); // U:[CT-4B]
    }

    /// @dev Retrieves the current max debt limit for a Credit Manager
    function getMaxDebtLimit(address creditManager) public view returns (uint128) {
        (, uint128 maxDebtCurrent) = ICreditFacadeV3(ICreditManagerV3(creditManager).creditFacade()).debtLimits();
        return maxDebtCurrent;
    }

    /// @notice Queues a transaction to set a new debt limit for a Credit Manager
    /// @dev Requires the policy for keccak(group(creditManager), "CREDIT_MANAGER_DEBT_LIMIT") to be enabled,
    ///      otherwise auto-fails the check
    /// @param creditManager Adress of CM to update the debt limit for
    /// @param debtLimit The new debt limit
    function setCreditManagerDebtLimit(address creditManager, uint256 debtLimit)
        external
        override
        policyCheckAdminValueInRange("setCreditManagerDebtLimit", uint256(debtLimit))
    {
        _queueTransaction({
            policy: "setCreditManagerDebtLimit",
            target: ICreditManagerV3(creditManager).pool(),
            signature: "setCreditManagerDebtLimit(address,uint256)",
            data: abi.encode(address(creditManager), debtLimit),
            sanityCheckCallData: abi.encodeCall(this.getCreditManagerDebtLimit, (creditManager))
        }); // U:[CT-5]
    }

    /// @dev Retrieves the current total debt limit for Credit Manager from its pool
    function getCreditManagerDebtLimit(address creditManager) public view returns (uint256) {
        address pool = ICreditManagerV3(creditManager).pool();
        return IPoolV3(pool).creditManagerDebtLimit(creditManager);
    }

    /// @notice Queues a transaction to start a liquidation threshold ramp
    /// @dev Requires the policy for keccak(group(creditManager), group(token), "TOKEN_LT") to be enabled,
    ///      otherwise auto-fails the check
    /// @param creditManager Adress of CM to update the LT for
    /// @param token Token to ramp the LT for
    /// @param liquidationThresholdFinal The liquidation threshold value after the ramp
    /// @param rampDuration Duration of the ramp
    function rampLiquidationThreshold(
        address creditManager,
        address token,
        uint16 liquidationThresholdFinal,
        uint40 rampStart,
        uint24 rampDuration
    )
        external
        override
        policyCheckAdminValueInRange("rampLiquidationThreshold", liquidationThresholdFinal)
        checkAdditionalValueInRange("rampLiquidationThreshold_rampDuration", rampDuration)
    {
        _queueTransaction({
            policy: "rampLiquidationThreshold",
            target: ICreditManagerV3(creditManager).creditConfigurator(),
            signature: "rampLiquidationThreshold(address,uint16,uint40,uint24)",
            data: abi.encode(token, liquidationThresholdFinal, rampStart, rampDuration),
            sanityCheckCallData: abi.encodeCall(this.getLTRampParamsHash, (creditManager, token))
        }); // U: [CT-6]
    }

    /// @dev Retrives the keccak of liquidation threshold params for a token
    function getLTRampParamsHash(address creditManager, address token) public view returns (bytes32) {
        (uint16 ltInitial, uint16 ltFinal, uint40 timestampRampStart, uint24 rampDuration) =
            ICreditManagerV3(creditManager).ltParams(token);
        return keccak256(abi.encode(ltInitial, ltFinal, timestampRampStart, rampDuration));
    }

    /// @notice Queues a transaction to forbid a third party contract adapter
    /// @dev Requires the policy for keccak(group(creditManager), "FORBID_ADAPTER") to be enabled,
    ///      otherwise auto-fails the check
    /// @param creditManager Adress of CM to forbid an adapter for
    /// @param adapter Address of adapter to forbid
    function forbidAdapter(address creditManager, address adapter) external override policyAdminOnly("forbidAdapter") {
        _queueTransaction({
            policy: "forbidAdapter",
            target: ICreditManagerV3(creditManager).creditConfigurator(),
            signature: "forbidAdapter(address)",
            data: abi.encode(adapter),
            sanityCheckCallData: ""
        }); // U: [CT-10]
    }

    /// @notice Queues a transaction to set a new limit on quotas for particular pool and token
    /// @dev Requires the policy for keccak(group(pool), group(token), "TOKEN_LIMIT") to be enabled,
    ///      otherwise auto-fails the check
    /// @param pool Pool to update the limit for
    /// @param token Token to update the limit for
    /// @param limit The new value of the limit
    function setTokenLimit(address pool, address token, uint96 limit)
        external
        override
        policyCheckAdminValueInRange("setTokenLimit", limit)
    {
        _queueTransaction({
            policy: "setTokenLimit",
            target: IPoolV3(pool).poolQuotaKeeper(),
            signature: "setTokenLimit(address,uint96)",
            data: abi.encode(token, limit),
            sanityCheckCallData: abi.encodeCall(this.getTokenLimit, (pool, token))
        }); // U: [CT-11]
    }

    /// @dev Retrieves the per-token quota limit from pool quota keeper
    function getTokenLimit(address pool, address token) public view returns (uint96) {
        address poolQuotaKeeper = IPoolV3(pool).poolQuotaKeeper();
        (,,,, uint96 oldLimit,) = IPoolQuotaKeeperV3(poolQuotaKeeper).getTokenQuotaParams(token);
        return oldLimit;
    }

    /// @notice Queues a transaction to set a new quota increase (trading) fee for a particular pool and token
    /// @dev Requires the policy for keccak(group(pool), group(token), "TOKEN_QUOTA_INCREASE_FEE") to be enabled,
    ///      otherwise auto-fails the check
    /// @param pool Pool to update the limit for
    /// @param token Token to update the limit for
    /// @param quotaIncreaseFee The new value of the fee in bp
    function setTokenQuotaIncreaseFee(address pool, address token, uint16 quotaIncreaseFee)
        external
        override
        policyCheckAdminValueInRange("setTokenQuotaIncreaseFee", quotaIncreaseFee)
    {
        _queueTransaction({
            policy: "setTokenQuotaIncreaseFee",
            target: IPoolV3(pool).poolQuotaKeeper(),
            signature: "setTokenQuotaIncreaseFee(address,uint16)",
            data: abi.encode(token, quotaIncreaseFee),
            sanityCheckCallData: abi.encodeCall(this.getTokenQuotaIncreaseFee, (pool, token))
        }); // U: [CT-12]
    }

    /// @dev Retrieves the quota increase fee for a token
    function getTokenQuotaIncreaseFee(address pool, address token) public view returns (uint16) {
        address poolQuotaKeeper = IPoolV3(pool).poolQuotaKeeper();
        (,, uint16 quotaIncreaseFee,,,) = IPoolQuotaKeeperV3(poolQuotaKeeper).getTokenQuotaParams(token);
        return quotaIncreaseFee;
    }

    /// @notice Queues a transaction to set a new total debt limit for the entire pool
    /// @dev Requires the policy for keccak(group(pool), "TOTAL_DEBT_LIMIT") to be enabled,
    ///      otherwise auto-fails the check
    /// @param pool Pool to update the limit for
    /// @param newLimit The new value of the limit
    function setTotalDebtLimit(address pool, uint256 newLimit)
        external
        override
        policyCheckAdminValueInRange("setTotalDebtLimit", uint256(newLimit))
    {
        _queueTransaction({
            policy: "setTotalDebtLimit",
            target: pool,
            signature: "setTotalDebtLimit(uint256)",
            data: abi.encode(newLimit),
            sanityCheckCallData: abi.encodeCall(this.getTotalDebtLimit, (pool))
        }); // U: [CT-13]
    }

    /// @dev Retrieves the total debt limit for a pool
    function getTotalDebtLimit(address pool) public view returns (uint256) {
        return IPoolV3(pool).totalDebtLimit();
    }

    /// @notice Queues a transaction to set a new withdrawal fee in a pool
    /// @dev Requires the policy for keccak(group(pool), "WITHDRAW_FEE") to be enabled,
    ///      otherwise auto-fails the check
    /// @param pool Pool to update the limit for
    /// @param newFee The new value of the fee in bp
    function setWithdrawFee(address pool, uint256 newFee)
        external
        override
        policyCheckAdminValueInRange("setWithdrawFee", newFee)
    {
        _queueTransaction({
            policy: "setWithdrawFee",
            target: pool,
            signature: "setWithdrawFee(uint256)",
            data: abi.encode(newFee),
            sanityCheckCallData: abi.encodeCall(this.getWithdrawFee, (pool))
        }); // U: [CT-14]
    }

    /// @dev Retrieves the withdrawal fee for a pool
    function getWithdrawFee(address pool) public view returns (uint256) {
        return IPoolV3(pool).withdrawFee();
    }

    /// @notice Queues a transaction to set a new minimal quota interest rate for particular pool and token
    /// @dev Requires the policy for keccak(group(pool), group(token), "TOKEN_QUOTA_MIN_RATE") to be enabled,
    ///      otherwise auto-fails the check
    /// @param pool Pool to update the limit for
    /// @param token Token to set the new fee for
    /// @param rate The new minimal rate
    function setMinQuotaRate(address pool, address token, uint16 rate)
        external
        override
        policyCheckAdminValueInRange("setMinQuotaRate", uint256(rate))
    {
        _queueTransaction({
            policy: "setMinQuotaRate",
            target: IPoolQuotaKeeperV3(IPoolV3(pool).poolQuotaKeeper()).gauge(),
            signature: "changeQuotaMinRate(address,uint16)",
            data: abi.encode(token, rate),
            sanityCheckCallData: abi.encodeCall(this.getMinQuotaRate, (pool, token))
        }); // U: [CT-15A]
    }

    /// @dev Retrieves the current minimal quota rate for a token in a gauge
    function getMinQuotaRate(address pool, address token) public view returns (uint16) {
        address gauge = IPoolQuotaKeeperV3(IPoolV3(pool).poolQuotaKeeper()).gauge();
        (uint16 minRate,,,) = IGaugeV3(gauge).quotaRateParams(token);
        return minRate;
    }

    /// @notice Queues a transaction to set a new maximal quota interest rate for particular pool and token
    /// @dev Requires the policy for keccak(group(pool), group(token), "TOKEN_QUOTA_MAX_RATE") to be enabled,
    ///      otherwise auto-fails the check
    /// @param pool Pool to update the limit for
    /// @param token Token to set the new fee for
    /// @param rate The new maximal rate
    function setMaxQuotaRate(address pool, address token, uint16 rate)
        external
        override
        policyCheckAdminValueInRange("setMaxQuotaRate", uint256(rate))
    {
        _queueTransaction({
            policy: "setMaxQuotaRate",
            target: IPoolQuotaKeeperV3(IPoolV3(pool).poolQuotaKeeper()).gauge(),
            signature: "changeQuotaMaxRate(address,uint16)",
            data: abi.encode(token, rate),
            sanityCheckCallData: abi.encodeCall(this.getMaxQuotaRate, (pool, token))
        }); // U: [CT-15B]
    }

    /// @dev Retrieves the current maximal quota rate for a token in a gauge
    function getMaxQuotaRate(address pool, address token) public view returns (uint16) {
        address gauge = IPoolQuotaKeeperV3(IPoolV3(pool).poolQuotaKeeper()).gauge();
        (, uint16 maxRate,,) = IGaugeV3(gauge).quotaRateParams(token);
        return maxRate;
    }

    /// @notice Queues a transaction to forbid permissionless bounds update in an LP price feed
    /// @dev Requires the policy for keccak(group(priceFeed), "UPDATE_BOUNDS_ALLOWED") to be enabled,
    ///      otherwise auto-fails the check
    /// @param priceFeed The price feed to forbid bounds update for
    function forbidBoundsUpdate(address priceFeed) external override policyAdminOnly("forbidBoundsUpdate") {
        _queueTransaction({
            policy: "forbidBoundsUpdate",
            target: priceFeed,
            signature: "forbidBoundsUpdate()",
            data: "",
            sanityCheckCallData: ""
        }); // U:[CT-16]
    }

    /// @notice Queues a transaction to change a price feed for a token
    /// @dev Requires the policy for keccak(group(priceOracle), group(token), "PRICE_FEED") to be enabled,
    ///      otherwise auto-fails the check
    function setPriceFeed(address priceOracle, address token, address priceFeed, uint32 stalenessPeriod)
        external
        override
        policyCheckAdminValueInList("setPriceFeed", token, priceFeed)
    {
        _queueTransaction({
            policy: "setPriceFeed",
            target: priceOracle,
            signature: "setPriceFeed(address,address,uint32)",
            data: abi.encode(token, priceFeed, stalenessPeriod),
            sanityCheckCallData: abi.encodeCall(this.getCurrentPriceFeedHash, (priceOracle, token))
        });
    }

    function getCurrentPriceFeedHash(address priceOracle, address token) public view returns (uint256) {
        PriceFeedParams memory pfParams = IPriceOracleV3(priceOracle).priceFeedParams(token);
        return uint256(keccak256(abi.encode(pfParams.priceFeed, pfParams.stalenessPeriod)));
    }

    /// @dev Internal function that stores the transaction in the queued tx map
    /// @param target The contract to call
    /// @param signature The signature of the called function
    /// @param data The call data
    /// @return Hash of the queued transaction
    function _queueTransaction(
        string memory policy,
        address target,
        string memory signature,
        bytes memory data,
        bytes memory sanityCheckCallData
    ) internal returns (bytes32) {
        uint256 eta = block.timestamp + policies[policy].delay;

        bytes32 txHash = keccak256(abi.encode(msg.sender, target, signature, data));
        uint256 sanityCheckValue;

        if (sanityCheckCallData.length != 0) {
            (, bytes memory returndata) = address(this).staticcall(sanityCheckCallData);
            sanityCheckValue = abi.decode(returndata, (uint256));
        }

        queuedTransactions[txHash] = QueuedTransactionData({
            queued: true,
            initiator: msg.sender,
            target: target,
            eta: uint40(eta),
            signature: signature,
            data: data,
            sanityCheckValue: sanityCheckValue,
            sanityCheckCallData: sanityCheckCallData
        });

        emit QueueTransaction({
            txHash: txHash,
            initiator: msg.sender,
            target: target,
            signature: signature,
            data: data,
            eta: uint40(eta)
        });

        return txHash;
    }

    // --------- //
    // EXECUTION //
    // --------- //

    /// @notice Sets the transaction's queued status as false, effectively cancelling it
    /// @param txHash Hash of the transaction to be cancelled
    function cancelTransaction(bytes32 txHash)
        external
        override
        vetoAdminOnly // U: [CT-7]
    {
        queuedTransactions[txHash].queued = false;
        emit CancelTransaction(txHash);
    }

    /// @notice Executes a queued transaction
    /// @param txHash Hash of the transaction to be executed
    function executeTransaction(bytes32 txHash) external override {
        QueuedTransactionData memory qtd = queuedTransactions[txHash];

        if (!qtd.queued) {
            revert TxNotQueuedException(); // U: [CT-7]
        }

        if (msg.sender != qtd.initiator && !_executors.contains(msg.sender)) {
            revert CallerNotExecutorException(); // U: [CT-9]
        }

        address target = qtd.target;
        uint40 eta = qtd.eta;
        string memory signature = qtd.signature;
        bytes memory data = qtd.data;

        if (block.timestamp < eta || block.timestamp > eta + GRACE_PERIOD) {
            revert TxExecutedOutsideTimeWindowException(); // U: [CT-9]
        }

        // In order to ensure that we do not accidentally override a change
        // made by configurator or another admin, the current value of the parameter
        // is compared to the value at the moment of tx being queued
        if (qtd.sanityCheckCallData.length != 0) {
            (, bytes memory returndata) = address(this).staticcall(qtd.sanityCheckCallData);

            if (abi.decode(returndata, (uint256)) != qtd.sanityCheckValue) {
                revert ParameterChangedAfterQueuedTxException();
            }
        }

        queuedTransactions[txHash].queued = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success,) = target.call(callData);

        if (!success) {
            revert TxExecutionRevertedException(); // U: [CT-9]
        }

        emit ExecuteTransaction(txHash); // U: [CT-9]
    }

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    /// @notice Sets a new veto admin address
    function setVetoAdmin(address newAdmin)
        external
        override
        configuratorOnly // U: [CT-8]
    {
        if (vetoAdmin != newAdmin) {
            vetoAdmin = newAdmin; // U: [CT-8]
            emit SetVetoAdmin(newAdmin); // U: [CT-8]
        }
    }

    /// @notice Changes status of an address as an executor
    function addExecutor(address executorAddress) external override configuratorOnly {
        if (!_executors.contains(executorAddress)) {
            _executors.add(executorAddress);
            emit AddExecutor(executorAddress);
        }
    }

    function removeExecutor(address executorAddress) external override configuratorOnly {
        if (_executors.contains(executorAddress)) {
            _executors.remove(executorAddress);
            emit RemoveExecutor(executorAddress);
        }
    }

    function isExecutor(address addr) external view override returns (bool) {
        return _executors.contains(addr);
    }

    function executors() external view override returns (address[] memory) {
        return _executors.values();
    }

    function setRange(string memory policyID, uint256 min, uint256 max)
        external
        existingPolicyOnly(policyID)
        configuratorOnly
    {
        allowedRanges[policyID].minValue = min;
        allowedRanges[policyID].maxValue = max;

        emit UpdatePolicyRange(policyID, min, max);
    }

    function addAddressToSet(string memory policyID, address key, address newValue)
        external
        existingPolicyOnly(policyID)
        configuratorOnly
    {
        EnumerableSet.AddressSet storage set = allowedAddressSets[policyID][key];
        set.add(newValue);

        EnumerableSet.AddressSet storage keySet = allowedAddressSetKeys[policyID];
        keySet.add(key);

        emit AddToPolicyList(policyID, key, newValue);
    }

    function removeAddressFromSet(string memory policyID, address key, address value)
        external
        existingPolicyOnly(policyID)
        configuratorOnly
    {
        EnumerableSet.AddressSet storage set = allowedAddressSets[policyID][key];
        set.remove(value);

        if (set.length() == 0) {
            EnumerableSet.AddressSet storage keySet = allowedAddressSetKeys[policyID];
            keySet.remove(key);
        }

        emit RemoveFromPolicyList(policyID, key, value);
    }

    function policyState() external view returns (PolicyState memory result) {
        uint256 uintPolicyCount;
        uint256 addressSetPolicyCount;
        uint256 len = keys.length;

        result.policiesInRange = new PolicyUintRange[](len);
        result.policiesAddressSet = new PolicyAddressSet[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                string memory id = keys[i];
                Policy storage p = policies[id];
                if (p.policyType == PolicyType.UintRange) {
                    UintRange storage range = allowedRanges[id];
                    result.policiesInRange[uintPolicyCount] = PolicyUintRange({
                        id: id,
                        admin: p.admin,
                        delay: p.delay,
                        minValue: range.minValue,
                        maxValue: range.maxValue
                    });

                    ++uintPolicyCount;
                } else {
                    EnumerableSet.AddressSet storage keys_ = allowedAddressSetKeys[id];
                    uint256 keysLen = keys_.length();
                    AddressSet[] memory addressSet = new AddressSet[](keysLen);
                    for (uint256 j; j < keysLen; ++j) {
                        address key = keys_.at(j);
                        addressSet[j] = AddressSet({key: key, values: allowedAddressSets[id][key].values()});
                    }

                    result.policiesAddressSet[addressSetPolicyCount] =
                        PolicyAddressSet({id: id, admin: p.admin, delay: p.delay, addressSet: addressSet});

                    ++addressSetPolicyCount;
                }
            }
        }
    }
}
