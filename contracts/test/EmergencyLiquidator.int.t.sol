// SPDX-License-Identifier: UNLICENSED
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {
    EmergencyLiquidator, IEmergencyLiquidatorEvents, IEmergencyLiquidatorExceptions
} from "../EmergencyLiquidator.sol";

import {
    ICreditManagerV3,
    CollateralDebtData,
    CollateralCalcTask
} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import {ICreditFacadeV3, MultiCall} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditFacadeV3.sol";
import {ICreditFacadeV3Multicall} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditFacadeV3Multicall.sol";
import {ICreditConfiguratorV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditConfiguratorV3.sol";
import {
    IPriceOracleV3,
    PriceFeedParams,
    PriceUpdate
} from "@gearbox-protocol/core-v3/contracts/interfaces/IPriceOracleV3.sol";
import {IPoolV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPoolV3.sol";
import {IPoolQuotaKeeperV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPoolQuotaKeeperV3.sol";
import {IGaugeV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IGaugeV3.sol";
import {PoolV3} from "@gearbox-protocol/core-v3/contracts/pool/PoolV3.sol";
import {PoolQuotaKeeperV3} from "@gearbox-protocol/core-v3/contracts/pool/PoolQuotaKeeperV3.sol";
import {GaugeV3} from "@gearbox-protocol/core-v3/contracts/pool/GaugeV3.sol";
import {ILPPriceFeedV2} from "@gearbox-protocol/core-v2/contracts/interfaces/ILPPriceFeedV2.sol";
import "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";

// TEST
import {Tokens} from "@gearbox-protocol/sdk-gov/contracts/Tokens.sol";
import "@gearbox-protocol/core-v3/contracts/test/lib/constants.sol";
import {IntegrationTestHelper} from "@gearbox-protocol/core-v3/contracts/test/helpers/IntegrationTestHelper.sol";

// MOCKS
import {AddressProviderV3ACLMock} from
    "@gearbox-protocol/core-v3/contracts/test/mocks/core/AddressProviderV3ACLMock.sol";
import {PriceFeedMock} from "@gearbox-protocol/core-v3/contracts/test/mocks/oracles/PriceFeedMock.sol";
import {GeneralMock} from "@gearbox-protocol/core-v3/contracts/test/mocks/GeneralMock.sol";
import {ERC20Mock} from "@gearbox-protocol/core-v3/contracts/test/mocks/token/ERC20Mock.sol";
import {AdapterMock} from "@gearbox-protocol/core-v3/contracts/test/mocks/core/AdapterMock.sol";

contract UpdatablePriceFeedMock is PriceFeedMock {
    bool public updatable = true;

    constructor(int256 price, uint8 decimals) PriceFeedMock(price, decimals) {
        updatedAt = block.timestamp;
    }

    function updatePrice(bytes calldata data) external {
        this.setPrice(abi.decode(data, (int256)));
        updatedAt = block.timestamp;
    }
}

contract SimpleSwapMock {
    function swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut) public {
        ERC20Mock(tokenIn).burn(msg.sender, amountIn);
        ERC20Mock(tokenOut).mint(msg.sender, amountOut);
    }
}

contract EmergencyLiquidatorIntegrationTest is
    IntegrationTestHelper,
    IEmergencyLiquidatorEvents,
    IEmergencyLiquidatorExceptions
{
    EmergencyLiquidator public emergencyLiquidator;

    address simpleSwap;
    address simpleSwapAdapter;

    address dai;
    address link;
    address usdt;

    address updatableLinkFeed;
    address updatableUsdtFeed;

    uint256 daiAmount = 10_000e18;
    uint256 linkAmount = 1_000e18;

    int256 daiPrice = 1e8;
    int256 linkPrice = 15e8;
    int256 newLinkPrice = 12e8;
    int256 usdtPrice = 50e8;

    address creditAccount;

    function _setUp() public {
        vm.prank(CONFIGURATOR);
        emergencyLiquidator = new EmergencyLiquidator(address(acl));

        dai = tokenTestSuite.addressOf(Tokens.DAI);
        link = tokenTestSuite.addressOf(Tokens.LINK);
        usdt = tokenTestSuite.addressOf(Tokens.USDT);

        updatableLinkFeed = address(new UpdatablePriceFeedMock(linkPrice, 8));
        updatableUsdtFeed = address(new UpdatablePriceFeedMock(usdtPrice, 8));

        vm.startPrank(CONFIGURATOR);
        priceOracle.setPriceFeed(link, updatableLinkFeed, 240);
        priceOracle.addUpdatablePriceFeed(updatableLinkFeed);

        priceOracle.setPriceFeed(usdt, updatableUsdtFeed, 240);
        priceOracle.addUpdatablePriceFeed(updatableUsdtFeed);
        vm.stopPrank();

        simpleSwap = address(new SimpleSwapMock());
        simpleSwapAdapter = address(new AdapterMock(address(creditManager), simpleSwap));

        vm.prank(CONFIGURATOR);
        creditConfigurator.allowAdapter(simpleSwapAdapter);

        ERC20Mock(dai).set_minter(simpleSwap);
        ERC20Mock(link).set_minter(simpleSwap);

        creditAccount = _openCreditAccount();
    }

    function _openCreditAccount() internal returns (address _creditAccount) {
        deal(dai, USER, daiAmount);
        tokenTestSuite.approve(dai, USER, address(creditManager), type(uint256).max);

        uint96 quotaAmount = uint96(6 * daiAmount / 5);

        MultiCall[] memory calls = new MultiCall[](3);
        calls[0] = MultiCall({
            target: address(creditFacade),
            callData: abi.encodeCall(ICreditFacadeV3Multicall.increaseDebt, (daiAmount))
        });
        calls[1] = MultiCall({
            target: address(creditFacade),
            callData: abi.encodeCall(ICreditFacadeV3Multicall.addCollateral, (dai, daiAmount))
        });
        calls[2] = MultiCall({
            target: address(creditFacade),
            callData: abi.encodeCall(ICreditFacadeV3Multicall.updateQuota, (link, int96(uint96(daiAmount * 2)), 0))
        });

        vm.prank(USER);
        _creditAccount = creditFacade.openCreditAccount(USER, calls, 0);

        /// Removing setting dai balance to 102% of debt should bring the account underwater
        deal(dai, _creditAccount, daiAmount * 102 / 100, false);

        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 12);
    }

    ///
    ///
    ///  TESTS
    ///
    ///

    /// @dev U:[EL-1]: all liquidations are blocked when the contract is paused
    function test_EL_01_liquidation_reverts_when_paused() public creditTest {
        _setUp();

        vm.prank(CONFIGURATOR);
        emergencyLiquidator.pause();

        vm.expectRevert("Pausable: paused");
        emergencyLiquidator.liquidateCreditAccount(DUMB_ADDRESS, DUMB_ADDRESS2, new MultiCall[](0));

        vm.expectRevert("Pausable: paused");
        emergencyLiquidator.liquidateCreditAccountWithApproval(DUMB_ADDRESS, DUMB_ADDRESS2, new MultiCall[](0));
    }

    /// @dev U:[EL-2]: normal liquidations are blocked for public addresses (when public mode is not enabled) and liquidations with approval
    function test_EL_02_liquidation_reverts_for_public_addresses() public creditTest {
        _setUp();

        vm.expectRevert(CallerNotWhitelistedException.selector);
        emergencyLiquidator.liquidateCreditAccount(DUMB_ADDRESS, DUMB_ADDRESS2, new MultiCall[](0));

        vm.expectRevert(CallerNotWhitelistedException.selector);
        emergencyLiquidator.liquidateCreditAccountWithApproval(DUMB_ADDRESS, DUMB_ADDRESS2, new MultiCall[](0));
    }

    /// @dev U:[EL-3]: liquidations revert with unauthorized withdrawals
    function test_EL_03_liquidation_reverts_with_unauthorized_withdrawals() public creditTest {
        _setUp();

        vm.prank(CONFIGURATOR);
        emergencyLiquidator.setWhitelistedAccount(LIQUIDATOR, true);

        MultiCall[] memory calls = new MultiCall[](1);
        calls[0] = MultiCall({
            target: address(creditFacade),
            callData: abi.encodeCall(ICreditFacadeV3Multicall.withdrawCollateral, (DUMB_ADDRESS, 100, LIQUIDATOR))
        });

        vm.expectRevert(WithdrawalToExternalAddressException.selector);
        vm.prank(LIQUIDATOR);
        emergencyLiquidator.liquidateCreditAccount(address(creditManager), creditAccount, calls);

        vm.expectRevert(WithdrawalToExternalAddressException.selector);
        vm.prank(LIQUIDATOR);
        emergencyLiquidator.liquidateCreditAccountWithApproval(address(creditManager), creditAccount, calls);
    }

    /// @dev U:[EL-4]: liquidations apply price updates and remove them from calls array
    function test_EL_04_liquidations_apply_price_updates_and_remove_call() public creditTest {
        _setUp();

        vm.prank(CONFIGURATOR);
        emergencyLiquidator.setWhitelistedAccount(LIQUIDATOR, true);

        PriceUpdate[] memory updates = new PriceUpdate[](1);
        updates[0] = PriceUpdate({priceFeed: updatableLinkFeed, data: abi.encode(newLinkPrice)});

        MultiCall[] memory calls = new MultiCall[](1);
        calls[0] = MultiCall({
            target: address(creditFacade),
            callData: abi.encodeCall(ICreditFacadeV3Multicall.onDemandPriceUpdates, (updates))
        });

        vm.expectCall(address(priceOracle), abi.encodeCall(IPriceOracleV3.updatePrices, (updates)));
        vm.expectCall(
            address(creditFacade),
            abi.encodeCall(
                ICreditFacadeV3.liquidateCreditAccount,
                (creditAccount, address(emergencyLiquidator), new MultiCall[](0))
            )
        );

        vm.prank(LIQUIDATOR);
        emergencyLiquidator.liquidateCreditAccount(address(creditManager), creditAccount, calls);
    }

    /// @dev U:[EL-5]: liquidations with bad debt are prevented when account is not liquidatable with alias
    function test_EL_05_bad_debt_liquidations_uphold_policy() public creditTest {
        _setUp();

        vm.prank(CONFIGURATOR);
        emergencyLiquidator.setWhitelistedAccount(LIQUIDATOR, true);

        vm.prank(CONFIGURATOR);
        emergencyLiquidator.setPriceAlias(link, usdt);

        deal(dai, creditAccount, 1, false);
        deal(link, creditAccount, linkAmount / 2, false);

        vm.expectRevert(PolicyViolatingLiquidationException.selector);

        vm.prank(LIQUIDATOR);
        emergencyLiquidator.liquidateCreditAccount(address(creditManager), creditAccount, new MultiCall[](0));

        vm.expectRevert(PolicyViolatingLiquidationException.selector);

        vm.prank(LIQUIDATOR);
        emergencyLiquidator.liquidateCreditAccountWithApproval(address(creditManager), creditAccount, new MultiCall[](0));
    }

    /// @dev U:[EL-6]: normal liquidations work correctly
    function test_EL_06_liquidations_work_correctly() public creditTest {
        _setUp();

        vm.prank(CONFIGURATOR);
        emergencyLiquidator.setWhitelistedAccount(LIQUIDATOR, true);

        deal(dai, creditAccount, 1, false);
        deal(link, creditAccount, 650e18, false);

        bytes memory adapterCD = abi.encodeCall(SimpleSwapMock.swap, (link, dai, 650e18, 12_000e18));

        MultiCall[] memory calls = new MultiCall[](1);
        calls[0] = MultiCall({
            target: address(simpleSwapAdapter),
            callData: abi.encodeCall(AdapterMock.executeSwapSafeApprove, (link, dai, adapterCD, false))
        });

        vm.expectCall(
            address(creditFacade),
            abi.encodeCall(ICreditFacadeV3.liquidateCreditAccount, (creditAccount, address(emergencyLiquidator), calls))
        );

        vm.prank(LIQUIDATOR);
        emergencyLiquidator.liquidateCreditAccount(address(creditManager), creditAccount, calls);

        assertEq(ERC20Mock(dai).balanceOf(LIQUIDATOR), 0, "Liquidator received funds");

        assertGe(
            ERC20Mock(dai).balanceOf(address(emergencyLiquidator)), 1, "Emergency liquidator did not receive premium"
        );
    }

    /// @dev U:[EL-7]: liquidations with approval work correctly
    function test_EL_07_liquidations_with_approval_work_correctly() public creditTest {
        _setUp();

        vm.prank(CONFIGURATOR);
        emergencyLiquidator.setWhitelistedAccount(LIQUIDATOR, true);

        deal(dai, creditAccount, 1, false);
        deal(link, creditAccount, 650e18, false);

        deal(dai, address(emergencyLiquidator), 12_000e18, false);

        MultiCall[] memory calls = new MultiCall[](2);
        calls[0] = MultiCall({
            target: address(creditFacade),
            callData: abi.encodeCall(ICreditFacadeV3Multicall.addCollateral, (dai, 12_000e18))
        });
        calls[1] = MultiCall({
            target: address(creditFacade),
            callData: abi.encodeCall(
                ICreditFacadeV3Multicall.withdrawCollateral, (link, 650e18, address(emergencyLiquidator))
            )
        });

        vm.expectCall(
            address(creditFacade),
            abi.encodeCall(ICreditFacadeV3.liquidateCreditAccount, (creditAccount, address(emergencyLiquidator), calls))
        );

        vm.prank(LIQUIDATOR);
        emergencyLiquidator.liquidateCreditAccountWithApproval(address(creditManager), creditAccount, calls);

        assertGe(
            ERC20Mock(link).balanceOf(address(emergencyLiquidator)), 1, "Emergency liquidator did not receive premium"
        );
    }

    /// @dev U:[EL-8]: public liquidation mode works correctly
    function test_EL_08_public_liquidations_work_correctly() public creditTest {
        _setUp();

        deal(dai, creditAccount, 1, false);
        deal(link, creditAccount, 650e18, false);

        bytes memory adapterCD = abi.encodeCall(SimpleSwapMock.swap, (link, dai, 650e18, 12_000e18));

        MultiCall[] memory calls = new MultiCall[](1);
        calls[0] = MultiCall({
            target: address(simpleSwapAdapter),
            callData: abi.encodeCall(AdapterMock.executeSwapSafeApprove, (link, dai, adapterCD, false))
        });

        vm.expectCall(
            address(creditFacade),
            abi.encodeCall(ICreditFacadeV3.liquidateCreditAccount, (creditAccount, address(emergencyLiquidator), calls))
        );

        uint256 snapshot = vm.snapshot();

        vm.prank(CONFIGURATOR);
        emergencyLiquidator.allowTemporaryPublicLiquidations(3600);

        vm.prank(USER);
        emergencyLiquidator.liquidateCreditAccount(address(creditManager), creditAccount, calls);

        vm.revertTo(snapshot);

        vm.prank(CONFIGURATOR);
        emergencyLiquidator.allowTemporaryPublicLiquidations(3600);

        vm.warp(block.timestamp + 3601);

        vm.expectRevert(CallerNotWhitelistedException.selector);
        vm.prank(USER);
        emergencyLiquidator.liquidateCreditAccount(address(creditManager), creditAccount, calls);
    }

    /// @dev U:[EL-9]: temporary policy waiver works correctly
    function test_EL_09_policy_waiver_works_correctly() public creditTest {
        _setUp();

        vm.prank(CONFIGURATOR);
        emergencyLiquidator.setWhitelistedAccount(LIQUIDATOR, true);

        vm.prank(CONFIGURATOR);
        emergencyLiquidator.setPriceAlias(link, usdt);

        deal(dai, creditAccount, 1, false);
        deal(link, creditAccount, linkAmount / 2, false);

        vm.startPrank(CONFIGURATOR);
        emergencyLiquidator.allowTemporaryPolicyWaive(3600);
        emergencyLiquidator.allowTemporaryPublicLiquidations(3600);
        vm.stopPrank();

        uint256 snapshot = vm.snapshot();

        bytes memory adapterCD = abi.encodeCall(SimpleSwapMock.swap, (link, dai, linkAmount / 2, 12_000e18));

        PriceUpdate[] memory updates = new PriceUpdate[](2);
        updates[0] = PriceUpdate({priceFeed: updatableLinkFeed, data: abi.encode(newLinkPrice)});
        updates[1] = PriceUpdate({priceFeed: updatableUsdtFeed, data: abi.encode(usdtPrice)});

        MultiCall[] memory calls = new MultiCall[](2);
        calls[0] = MultiCall({
            target: address(creditFacade),
            callData: abi.encodeCall(ICreditFacadeV3Multicall.onDemandPriceUpdates, (updates))
        });
        calls[1] = MultiCall({
            target: address(simpleSwapAdapter),
            callData: abi.encodeCall(AdapterMock.executeSwapSafeApprove, (link, dai, adapterCD, false))
        });

        vm.expectRevert(PolicyViolatingLiquidationException.selector);
        vm.prank(USER);
        emergencyLiquidator.liquidateCreditAccount(address(creditManager), creditAccount, calls);

        vm.prank(LIQUIDATOR);
        emergencyLiquidator.liquidateCreditAccount(address(creditManager), creditAccount, calls);

        vm.revertTo(snapshot);

        vm.warp(block.timestamp + 3601);

        vm.expectRevert(PolicyViolatingLiquidationException.selector);
        vm.prank(LIQUIDATOR);
        emergencyLiquidator.liquidateCreditAccount(address(creditManager), creditAccount, calls);
    }
}
