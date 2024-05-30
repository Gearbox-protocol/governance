// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ACLNonReentrantTrait} from "@gearbox-protocol/core-v3/contracts/traits/ACLNonReentrantTrait.sol";
import {BitMask} from "@gearbox-protocol/core-v3/contracts/libraries/BitMask.sol";
import {
    PERCENTAGE_FACTOR, RAY, UNDERLYING_TOKEN_MASK
} from "@gearbox-protocol/core-v3/contracts/libraries/Constants.sol";

import {
    ICreditManagerV3,
    CollateralDebtData,
    CollateralCalcTask
} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import {ICreditFacadeV3, MultiCall} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditFacadeV3.sol";
import {ICreditFacadeV3Multicall} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditFacadeV3Multicall.sol";
import {IPriceOracleV3, PriceUpdate} from "@gearbox-protocol/core-v3/contracts/interfaces/IPriceOracleV3.sol";
import {IPoolQuotaKeeperV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPoolQuotaKeeperV3.sol";

interface IEmergencyLiquidatorExceptions {
    /// @dev Thrown when a bad-debt liquidation violates policy
    error PolicyViolatingLiquidationException();

    /// @dev Thrown when liquidation calls contain withdrawals to an address other than emergency liquidator contract
    error WithdrawalToExternalAddressException();

    /// @dev Thrown when a non-whitelisted address attempts to call an access-restricted function
    error CallerNotWhitelistedException();
}

interface IEmergencyLiquidatorEvents {
    /// @dev Emitted when a new account is added to / removed from the whitelist
    event SetWhitelistedStatus(address indexed account, bool newStatus);

    /// @dev Emitted when whitelist-only mode is temporarily disabled
    event DisableWhitelistMode(uint256 indexed start, uint256 duration);

    /// @dev Emitted when policy enforcement is temporarily disabled for whitelisted accounts
    event DisableWhitelistPolicyEnforcement(uint256 indexed start, uint256 duration);
}

contract EmergencyLiquidator is ACLNonReentrantTrait, IEmergencyLiquidatorExceptions, IEmergencyLiquidatorEvents {
    using BitMask for uint256;
    using SafeERC20 for IERC20;

    /// @dev Thrown when the access-restricted function's caller is not treasury
    error CallerNotTreasuryException();

    /// @notice Whether the address is a trusted account capable of doing whitelist-only actions
    mapping(address => bool) public isWhitelisted;

    /// @notice Time when whitelist-only liquidations were last disabled
    uint64 public lastWhitelistDisabledTimestamp;

    /// @notice Duration for which whitelist-only liquidations are disabled
    uint64 public whitelistDisabledDuration;

    /// @notice Time when the whitelisted addresses were last allowed to liquidate
    ///         disregarding policy
    uint64 public lastWhitelistedPolicyWaivedTimestamp;

    /// @notice Durations for which whitelisted address can liquidate disregarding policy
    uint64 public whitelistedPolicyWaiveDuration;

    /// @notice Map to substitute prices of tokens with other tokens, for policy checks
    mapping(address => address) public priceAlias;

    constructor(address _addressProvider) ACLNonReentrantTrait(_addressProvider) {}

    modifier whitelistedOnly() {
        if (!isWhitelisted[msg.sender]) revert CallerNotWhitelistedException();
        _;
    }

    /// @dev Checks that either the temporary non-whitelisted mode is enabled, or the msg.sender is whitelised
    modifier timedNonWhitelistedOnly() {
        if (block.timestamp > lastWhitelistDisabledTimestamp + whitelistDisabledDuration && !isWhitelisted[msg.sender])
        {
            revert CallerNotWhitelistedException();
        }
        _;
    }

    /// @dev Checks that all withdrawals are sent to this contract, reverts if not
    modifier checkWithdrawalDestinations(address creditFacade, MultiCall[] calldata calls) {
        _;
    }

    /// @notice Liquidates a credit account, while checking restrictions on liquidations during pause
    function liquidateCreditAccount(address creditManager, address creditAccount, MultiCall[] calldata calls)
        external
        timedNonWhitelistedOnly
    {
        address creditFacade = ICreditManagerV3(creditManager).creditFacade();
        _checkWithdrawalsDestination(creditFacade, calls);
        MultiCall[] memory mCalls = _applyPriceFeedUpdates(creditManager, calls);

        CollateralDebtData memory cdd =
            ICreditManagerV3(creditManager).calcDebtAndCollateral(creditAccount, CollateralCalcTask.DEBT_COLLATERAL);
        if (
            _hasBadDebt(creditManager, cdd)
                && !(_isPolicyWaived(msg.sender) || _isLiquidatableAliased(creditManager, creditAccount, cdd))
        ) {
            revert PolicyViolatingLiquidationException();
        }

        ICreditFacadeV3(creditFacade).liquidateCreditAccount(creditAccount, address(this), mCalls);
    }

    /// @notice Liquidates a credit account with max underlying approval, allowing to buy collateral with DAO funds
    /// @dev Can be exploited by account owners when open to everyone, and thus is only allowed for whitelisted addresses
    function liquidateCreditAccountWithApproval(
        address creditManager,
        address creditAccount,
        MultiCall[] calldata calls
    ) external whitelistedOnly {
        address creditFacade = ICreditManagerV3(creditManager).creditFacade();
        _checkWithdrawalsDestination(creditFacade, calls);

        address underlying = ICreditManagerV3(creditManager).underlying();

        IERC20(underlying).forceApprove(creditManager, type(uint256).max);
        ICreditFacadeV3(creditFacade).liquidateCreditAccount(creditAccount, address(this), calls);
        IERC20(underlying).forceApprove(creditManager, 1);
    }

    /// @dev Returns whether the msg.sender can liquidate in lieu of policy
    function _isPolicyWaived(address account) internal view returns (bool) {
        return isWhitelisted[account]
            && block.timestamp > lastWhitelistedPolicyWaivedTimestamp + whitelistedPolicyWaiveDuration;
    }

    /// @dev Returns whether the account is in bad debt
    function _hasBadDebt(address creditManager, CollateralDebtData memory cdd) internal view returns (bool) {
        (,, uint16 liquidationPremium,,) = ICreditManagerV3(creditManager).fees();
        return cdd.totalValue * liquidationPremium < (cdd.debt + cdd.accruedInterest) * PERCENTAGE_FACTOR;
    }

    /// @dev Returns whether the account is liquidatable after replacing collateral token prices with their
    ///      respective alias prices
    function _isLiquidatableAliased(address creditManager, address creditAccount, CollateralDebtData memory cdd)
        internal
        view
        returns (bool)
    {
        uint256 remainingTokensMask = cdd.enabledTokensMask.disable(UNDERLYING_TOKEN_MASK);
        if (remainingTokensMask == 0) return cdd.twvUSD < cdd.totalDebtUSD;

        uint256 twvUSDAliased = cdd.twvUSD;
        address priceOracle = ICreditManagerV3(creditManager).priceOracle();

        uint256 underlyingPriceRAY = _convertToUSD(priceOracle, ICreditManagerV3(creditManager).underlying(), RAY);
        IPriceOracleV3(priceOracle).convertToUSD(RAY, ICreditManagerV3(creditManager).underlying());

        while (remainingTokensMask != 0) {
            uint256 tokenMask = remainingTokensMask & uint256(-int256(remainingTokensMask));
            remainingTokensMask ^= tokenMask;

            (address token, uint16 tokenLT) = ICreditManagerV3(creditManager).collateralTokenByMask(tokenMask);
            address aliasToken = priceAlias[token];

            if (aliasToken == address(0)) continue;

            uint256 balance = IERC20(token).safeBalanceOf({account: creditAccount});
            uint256 quotaUSD;
            {
                (uint256 quota,) = IPoolQuotaKeeperV3(cdd._poolQuotaKeeper).getQuota(creditAccount, token);
                quotaUSD = quota * underlyingPriceRAY / RAY;
            }

            twvUSDAliased = _adjustForAlias(priceOracle, token, aliasToken, twvUSDAliased, quotaUSD, balance, tokenLT);
        }

        return twvUSDAliased < cdd.totalDebtUSD;
    }

    /// @dev Checks that the provided calldata has all withdrawals sent to this contract
    function _checkWithdrawalsDestination(address creditFacade, MultiCall[] calldata calls) internal view {
        uint256 len = calls.length;

        for (uint256 i = 0; i < len;) {
            if (
                calls[i].target == creditFacade
                    && bytes4(calls[i].callData) == ICreditFacadeV3Multicall.withdrawCollateral.selector
            ) {
                (,, address to) = abi.decode(calls[i].callData[4:], (address, uint256, address));

                if (to != address(this)) revert WithdrawalToExternalAddressException();
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Applies price feed updates and removes the corresponding call from the array
    function _applyPriceFeedUpdates(address creditManager, MultiCall[] calldata calls)
        internal
        returns (MultiCall[] memory newCalls)
    {
        address creditFacade = ICreditManagerV3(creditManager).creditFacade();
        address priceOracle = ICreditManagerV3(creditManager).priceOracle();

        newCalls = calls;

        if (
            calls[0].target == creditFacade
                && bytes4(calls[0].callData) == ICreditFacadeV3Multicall.onDemandPriceUpdates.selector
        ) {
            PriceUpdate[] memory updates = abi.decode(calls[0].callData[4:], (PriceUpdate[]));
            IPriceOracleV3(priceOracle).updatePrices(updates);
            newCalls = _removeCall0(newCalls);
        }

        return newCalls;
    }

    /// @dev Removes a MultiCall struct at index 0 from array
    function _removeCall0(MultiCall[] memory calls) internal pure returns (MultiCall[] memory newCalls) {
        uint256 len = calls.length;

        newCalls = new MultiCall[](len - 1);

        for (uint256 i = 1; i < len; ++i) {
            newCalls[i - 1] = calls[i];
        }
    }

    function _convertToUSD(address priceOracle, address token, uint256 amount) internal view returns (uint256) {
        return IPriceOracleV3(priceOracle).convertToUSD(amount, token);
    }

    function _adjustForAlias(
        address priceOracle,
        address token,
        address aliasToken,
        uint256 twvUSD,
        uint256 quotaUSD,
        uint256 balance,
        uint16 tokenLT
    ) internal view returns (uint256) {
        uint256 vwNormal = Math.min(_convertToUSD(priceOracle, token, balance) * tokenLT / PERCENTAGE_FACTOR, quotaUSD);
        uint256 vwAliased = Math.min(
            _convertToUSD(priceOracle, aliasToken, _getEquivalentAmount(token, aliasToken, balance)) * tokenLT
                / PERCENTAGE_FACTOR,
            quotaUSD
        );

        return twvUSD + vwAliased - vwNormal;
    }

    function _getEquivalentAmount(address token0, address token1, uint256 amount) internal view returns (uint256) {
        uint256 decimals0 = 10 ** IERC20Metadata(token0).decimals();
        uint256 decimals1 = 10 ** IERC20Metadata(token1).decimals();

        return amount * decimals1 / decimals0;
    }

    /// @notice Sends funds accumulated from liquidations to a specified address
    function withdrawFunds(address token, address to) external configuratorOnly {
        uint256 bal = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(to, bal);
    }

    /// @notice Sets the status of an account as whitelisted
    function setWhitelistedAccount(address account, bool newStatus) external configuratorOnly {
        bool whitelistedStatus = isWhitelisted[account];

        if (newStatus != whitelistedStatus) {
            isWhitelisted[account] = newStatus;
            emit SetWhitelistedStatus(account, newStatus);
        }
    }

    /// @notice Allows non-whitelisted actors to liquidate accounts during pause for a given duration
    function allowTemporaryNonWhitelistedLiquidations(uint256 duration) external configuratorOnly {
        lastWhitelistDisabledTimestamp = uint64(block.timestamp);
        whitelistDisabledDuration = uint64(duration);
        emit DisableWhitelistMode(block.timestamp, duration);
    }

    /// @notice Allows whitelisted actors to liquidate bad debt accounts even when the policy is not satisfied, for a given duration
    function allowTemporaryPolicyWaive(uint256 duration) external configuratorOnly {
        lastWhitelistedPolicyWaivedTimestamp = uint64(block.timestamp);
        whitelistedPolicyWaiveDuration = uint64(duration);
        emit DisableWhitelistPolicyEnforcement(block.timestamp, duration);
    }
}
