// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

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

    /// @dev Emitted when an alias for a token is set
    event SetAlias(address indexed token, address indexed aliasToken);

    /// @dev Emitted when public liquidations are temporarily allowed
    event AllowPublicLiquidations(uint256 indexed start, uint256 indexed end);

    /// @dev Emitted when policy enforcement is temporarily disabled for whitelisted accounts
    event AllowPolicyWaiveForWhitelisted(uint256 indexed start, uint256 indexed end);
}

contract EmergencyLiquidator is ACLNonReentrantTrait, IEmergencyLiquidatorExceptions, IEmergencyLiquidatorEvents {
    using BitMask for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Timestamp until which liquidations by non-whitelisted addresses are allowed
    uint40 public publicLiquidationsAllowedUntil;

    /// @notice Timestamp until which liquidations by whitelisted accounts are not checked against policy
    uint40 public policyWaivedForWhitelistUntil;

    /// @notice Whether the address is a trusted account capable of doing whitelist-only actions
    mapping(address => bool) public isWhitelisted;

    /// @notice Map to substitute prices of tokens with other tokens, for policy checks
    mapping(address => address) public priceAlias;

    /// @dev Set of all tokens that have aliases set for them
    EnumerableSet.AddressSet internal aliasedTokens;

    /// @dev Set of all whitelisted accounts in the contract
    EnumerableSet.AddressSet internal whitelistedAccounts;

    constructor(address _addressProvider) ACLNonReentrantTrait(_addressProvider) {}

    modifier whitelistedOnly() {
        if (!isWhitelisted[msg.sender]) revert CallerNotWhitelistedException();
        _;
    }

    /// @dev Checks that either the temporary non-whitelisted mode is enabled, or the msg.sender is whitelised
    modifier timedNonWhitelistedOnly() {
        if (block.timestamp > publicLiquidationsAllowedUntil && !isWhitelisted[msg.sender]) {
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
        whenNotPaused
        timedNonWhitelistedOnly
    {
        address creditFacade = ICreditManagerV3(creditManager).creditFacade();
        _checkWithdrawalsDestination(creditFacade, calls);
        MultiCall[] memory mCalls = _applyPriceFeedUpdates(creditManager, calls);

        CollateralDebtData memory cdd =
            ICreditManagerV3(creditManager).calcDebtAndCollateral(creditAccount, CollateralCalcTask.DEBT_COLLATERAL);

        /// The general policy for liquidations is that when the CF is paused and there is bad debt -
        /// we check whether the account is liquidatable with prices computed from aliases. I.e. when an
        /// alias is set for a token, we use the price of the alias to compute the TWV instead of the token's own price.
        /// This allows to, for example, set a pegged assets price feed (only for the purposes of bad debt liquidations) to
        /// the feed of its peg target (e.g., ETH for LRTs). This allows to avoid immediately liquidating accounts that went
        /// unhealthy due to a short-term peg. This policy can be overriden if bad debt liquidations are
        /// deemed to be actually justified.
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
    /// @dev This can be used to liquidate accounts when there is bad on-chain liquidity for the asset in the moment, but it is
    ///      expected that collateral can be disposed of off-chain or liquidity restores in the future
    function liquidateCreditAccountWithApproval(
        address creditManager,
        address creditAccount,
        MultiCall[] calldata calls
    ) external whenNotPaused whitelistedOnly {
        address creditFacade = ICreditManagerV3(creditManager).creditFacade();
        _checkWithdrawalsDestination(creditFacade, calls);

        address underlying = ICreditManagerV3(creditManager).underlying();

        IERC20(underlying).forceApprove(creditManager, type(uint256).max);
        ICreditFacadeV3(creditFacade).liquidateCreditAccount(creditAccount, address(this), calls);
        IERC20(underlying).forceApprove(creditManager, 1);
    }

    /// @dev Returns whether the msg.sender can liquidate in lieu of policy
    function _isPolicyWaived(address account) internal view returns (bool) {
        return isWhitelisted[account] && block.timestamp <= policyWaivedForWhitelistUntil;
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

    /// @notice Returns current whitelisted accounts
    function getWhitelistedAccounts() external view returns (address[] memory) {
        return whitelistedAccounts.values();
    }

    /// @notice Returns aliased tokens and their respective aliases
    function getAliasedTokens() external view returns (address[] memory tokens, address[] memory aliases) {
        tokens = aliasedTokens.values();

        uint256 len = tokens.length;

        aliases = new address[](len);
        for (uint256 i = 0; i < len; ++i) {
            aliases[i] = priceAlias[tokens[i]];
        }
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
            if (newStatus) {
                whitelistedAccounts.add(account);
            } else {
                whitelistedAccounts.remove(account);
            }
            emit SetWhitelistedStatus(account, newStatus);
        }
    }

    /// @notice Sets alias for a token and adds/removes it from the set of aliased tokens
    function setPriceAlias(address token, address aliasToken) external configuratorOnly {
        address currentAlias = priceAlias[token];

        if (aliasToken != currentAlias) {
            priceAlias[token] = aliasToken;
            emit SetAlias(token, aliasToken);
            if (aliasToken != address(0)) {
                aliasedTokens.add(token);
            } else {
                aliasedTokens.remove(token);
            }
        }
    }

    /// @notice Allows non-whitelisted actors to liquidate accounts during pause for a given duration
    function allowTemporaryPublicLiquidations(uint256 duration) external controllerOnly {
        publicLiquidationsAllowedUntil = uint40(block.timestamp + duration);
        emit AllowPublicLiquidations(block.timestamp, block.timestamp + duration);
    }

    /// @notice Allows whitelisted actors to liquidate bad debt accounts even when the policy is not satisfied, for a given duration
    function allowTemporaryPolicyWaive(uint256 duration) external controllerOnly {
        policyWaivedForWhitelistUntil = uint40(block.timestamp + duration);
        emit AllowPolicyWaiveForWhitelisted(block.timestamp, block.timestamp + duration);
    }
}
