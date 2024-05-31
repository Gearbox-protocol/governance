// SPDX-License-Identifier: UNLICENSED
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {ControllerTimelockV3} from "../ControllerTimelockV3.sol";
import {Policy} from "../PolicyManagerV3.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {GeneralMock} from "@gearbox-protocol/core-v3/contracts/test/mocks/GeneralMock.sol";

import {ICreditManagerV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import {ICreditFacadeV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditFacadeV3.sol";
import {ICreditConfiguratorV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditConfiguratorV3.sol";
import {IPriceOracleV3, PriceFeedParams} from "@gearbox-protocol/core-v3/contracts/interfaces/IPriceOracleV3.sol";
import {IPoolV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPoolV3.sol";
import {IPoolQuotaKeeperV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPoolQuotaKeeperV3.sol";
import {IGaugeV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IGaugeV3.sol";
import {PoolV3} from "@gearbox-protocol/core-v3/contracts/pool/PoolV3.sol";
import {PoolQuotaKeeperV3} from "@gearbox-protocol/core-v3/contracts/pool/PoolQuotaKeeperV3.sol";
import {GaugeV3} from "@gearbox-protocol/core-v3/contracts/pool/GaugeV3.sol";
import {ILPPriceFeed} from "@gearbox-protocol/oracles-v3/contracts/interfaces/ILPPriceFeed.sol";
import {IControllerTimelockV3Events} from "../interfaces/IControllerTimelockV3.sol";
import "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";

// TEST
import "@gearbox-protocol/core-v3/contracts/test/lib/constants.sol";

// MOCKS
import {AddressProviderV3ACLMock} from
    "@gearbox-protocol/core-v3/contracts/test/mocks/core/AddressProviderV3ACLMock.sol";

contract ControllerTimelockV3UnitTest is Test, IControllerTimelockV3Events {
    AddressProviderV3ACLMock public addressProvider;

    ControllerTimelockV3 public controllerTimelock;

    address admin;
    address vetoAdmin;

    function setUp() public {
        admin = makeAddr("ADMIN");
        vetoAdmin = makeAddr("VETO_ADMIN");

        vm.prank(CONFIGURATOR);
        addressProvider = new AddressProviderV3ACLMock();
        controllerTimelock = new ControllerTimelockV3(address(addressProvider), vetoAdmin);
    }

    function _makeMocks()
        internal
        returns (
            address creditManager,
            address creditFacade,
            address creditConfigurator,
            address pool,
            address poolQuotaKeeper
        )
    {
        creditManager = address(new GeneralMock());
        creditFacade = address(new GeneralMock());
        creditConfigurator = address(new GeneralMock());
        pool = address(new GeneralMock());
        poolQuotaKeeper = address(new GeneralMock());

        vm.mockCall(
            creditManager, abi.encodeWithSelector(ICreditManagerV3.creditFacade.selector), abi.encode(creditFacade)
        );

        vm.mockCall(
            creditManager,
            abi.encodeWithSelector(ICreditManagerV3.creditConfigurator.selector),
            abi.encode(creditConfigurator)
        );

        vm.mockCall(creditManager, abi.encodeWithSelector(ICreditManagerV3.pool.selector), abi.encode(pool));

        vm.mockCall(pool, abi.encodeCall(IPoolV3.poolQuotaKeeper, ()), abi.encode(poolQuotaKeeper));

        vm.label(creditManager, "CREDIT_MANAGER");
        vm.label(creditFacade, "CREDIT_FACADE");
        vm.label(creditConfigurator, "CREDIT_CONFIGURATOR");
        vm.label(pool, "POOL");
        vm.label(poolQuotaKeeper, "PQK");
    }

    ///
    ///
    ///  TESTS
    ///
    ///

    /// @dev U:[CT-1]: setExpirationDate works correctly
    function test_U_CT_01_setExpirationDate_works_correctly() public {
        (address creditManager, address creditFacade, address creditConfigurator, address pool,) = _makeMocks();

        string memory policyID = "setExpirationDate";

        uint256 initialExpirationDate = block.timestamp;

        vm.mockCall(
            creditFacade,
            abi.encodeWithSelector(ICreditFacadeV3.expirationDate.selector),
            abi.encode(initialExpirationDate)
        );

        vm.mockCall(
            pool, abi.encodeWithSelector(IPoolV3.creditManagerBorrowed.selector, creditManager), abi.encode(1234)
        );

        uint256[] memory setValues = new uint256[](1);
        setValues[0] = block.timestamp + 5;

        Policy memory policy = Policy({
            enabled: false,
            admin: admin,
            delay: 1 days,
            checkInterval: false,
            checkSet: true,
            intervalMinValue: 0,
            intervalMaxValue: 0,
            setValues: setValues
        });

        // VERIFY THAT THE FUNCTION CANNOT BE CALLED WITHOUT RESPECTIVE POLICY
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setExpirationDate(creditManager, uint40(block.timestamp + 5));

        vm.prank(CONFIGURATOR);
        controllerTimelock.setPolicy(policyID, policy);

        // VERIFY THAT THE FUNCTION IS ONLY CALLABLE BY ADMIN
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(USER);
        controllerTimelock.setExpirationDate(creditManager, uint40(block.timestamp + 5));

        // VERIFY THAT POLICY CHECKS ARE PERFORMED
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setExpirationDate(creditManager, uint40(block.timestamp + 4));

        // VERIFY THAT EXTRA CHECKS ARE PERFORMED
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setExpirationDate(creditManager, uint40(block.timestamp + 5));

        vm.mockCall(pool, abi.encodeWithSelector(IPoolV3.creditManagerBorrowed.selector, creditManager), abi.encode(0));

        // VERIFY THAT THE FUNCTION IS QUEUED AND EXECUTED CORRECTLY
        bytes32 txHash = keccak256(
            abi.encode(admin, creditConfigurator, "setExpirationDate(uint40)", abi.encode(block.timestamp + 5))
        );

        vm.expectEmit(true, false, false, true);
        emit QueueTransaction(
            txHash,
            admin,
            creditConfigurator,
            "setExpirationDate(uint40)",
            abi.encode(block.timestamp + 5),
            uint40(block.timestamp + 1 days)
        );

        vm.prank(admin);
        controllerTimelock.setExpirationDate(creditManager, uint40(block.timestamp + 5));

        (,,,,,, uint256 sanityCheckValue, bytes memory sanityCheckCallData) =
            controllerTimelock.queuedTransactions(txHash);

        assertEq(sanityCheckValue, initialExpirationDate, "Sanity check value written incorrectly");

        assertEq(sanityCheckCallData, abi.encodeCall(ControllerTimelockV3.getExpirationDate, (creditManager)));

        vm.expectCall(
            creditConfigurator,
            abi.encodeWithSelector(ICreditConfiguratorV3.setExpirationDate.selector, block.timestamp + 5)
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(admin);
        controllerTimelock.executeTransaction(txHash);

        (bool queued,,,,,,,) = controllerTimelock.queuedTransactions(txHash);

        assertTrue(!queued, "Transaction is still queued after execution");
    }

    /// @dev U:[CT-2]: setLPPriceFeedLimiter works correctly
    function test_U_CT_02_setLPPriceFeedLimiter_works_correctly() public {
        address lpPriceFeed = address(new GeneralMock());

        vm.mockCall(lpPriceFeed, abi.encodeWithSelector(ILPPriceFeed.lowerBound.selector), abi.encode(5));

        string memory policyID = "setLPPriceFeedLimiter";

        uint256[] memory setValues = new uint256[](1);
        setValues[0] = 7;

        Policy memory policy = Policy({
            enabled: false,
            admin: admin,
            delay: 1 days,
            checkInterval: false,
            checkSet: true,
            intervalMinValue: 0,
            intervalMaxValue: 0,
            setValues: setValues
        });

        // VERIFY THAT THE FUNCTION CANNOT BE CALLED WITHOUT RESPECTIVE POLICY
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setLPPriceFeedLimiter(lpPriceFeed, 7);

        vm.prank(CONFIGURATOR);
        controllerTimelock.setPolicy(policyID, policy);

        // VERIFY THAT THE FUNCTION IS ONLY CALLABLE BY ADMIN
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(USER);
        controllerTimelock.setLPPriceFeedLimiter(lpPriceFeed, 7);

        // VERIFY THAT POLICY CHECKS ARE PERFORMED
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setLPPriceFeedLimiter(lpPriceFeed, 8);

        // VERIFY THAT THE FUNCTION IS QUEUED AND EXECUTED CORRECTLY
        bytes32 txHash = keccak256(abi.encode(admin, lpPriceFeed, "setLimiter(uint256)", abi.encode(7)));

        vm.expectEmit(true, false, false, true);
        emit QueueTransaction(
            txHash, admin, lpPriceFeed, "setLimiter(uint256)", abi.encode(7), uint40(block.timestamp + 1 days)
        );

        vm.prank(admin);
        controllerTimelock.setLPPriceFeedLimiter(lpPriceFeed, 7);

        (,,,,,, uint256 sanityCheckValue, bytes memory sanityCheckCallData) =
            controllerTimelock.queuedTransactions(txHash);

        assertEq(sanityCheckValue, 5, "Sanity check value written incorrectly");

        assertEq(sanityCheckCallData, abi.encodeCall(ControllerTimelockV3.getPriceFeedLowerBound, (lpPriceFeed)));

        vm.expectCall(lpPriceFeed, abi.encodeWithSelector(ILPPriceFeed.setLimiter.selector, 7));

        vm.warp(block.timestamp + 1 days);

        vm.prank(admin);
        controllerTimelock.executeTransaction(txHash);

        (bool queued,,,,,,,) = controllerTimelock.queuedTransactions(txHash);

        assertTrue(!queued, "Transaction is still queued after execution");
    }

    /// @dev U:[CT-3]: setMaxDebtPerBlockMultiplier works correctly
    function test_U_CT_03_setMaxDebtPerBlockMultiplier_works_correctly() public {
        (address creditManager, address creditFacade, address creditConfigurator,,) = _makeMocks();

        string memory policyID = "setMaxDebtPerBlockMultiplier";

        vm.mockCall(
            creditFacade, abi.encodeWithSelector(ICreditFacadeV3.maxDebtPerBlockMultiplier.selector), abi.encode(3)
        );

        uint256[] memory setValues = new uint256[](1);
        setValues[0] = 4;

        Policy memory policy = Policy({
            enabled: false,
            admin: admin,
            delay: 2 days,
            checkInterval: false,
            checkSet: true,
            intervalMinValue: 0,
            intervalMaxValue: 0,
            setValues: setValues
        });

        // VERIFY THAT THE FUNCTION CANNOT BE CALLED WITHOUT RESPECTIVE POLICY
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setMaxDebtPerBlockMultiplier(creditManager, 4);

        vm.prank(CONFIGURATOR);
        controllerTimelock.setPolicy(policyID, policy);

        // VERIFY THAT THE FUNCTION IS ONLY CALLABLE BY ADMIN
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(USER);
        controllerTimelock.setMaxDebtPerBlockMultiplier(creditManager, 4);

        // VERIFY THAT POLICY CHECKS ARE PERFORMED
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setMaxDebtPerBlockMultiplier(creditManager, 5);

        // VERIFY THAT THE FUNCTION IS QUEUED AND EXECUTED CORRECTLY
        bytes32 txHash =
            keccak256(abi.encode(admin, creditConfigurator, "setMaxDebtPerBlockMultiplier(uint8)", abi.encode(4)));

        vm.expectEmit(true, false, false, true);
        emit QueueTransaction(
            txHash,
            admin,
            creditConfigurator,
            "setMaxDebtPerBlockMultiplier(uint8)",
            abi.encode(4),
            uint40(block.timestamp + 2 days)
        );

        vm.prank(admin);
        controllerTimelock.setMaxDebtPerBlockMultiplier(creditManager, 4);

        (,,,,,, uint256 sanityCheckValue, bytes memory sanityCheckCallData) =
            controllerTimelock.queuedTransactions(txHash);

        assertEq(sanityCheckValue, 3, "Sanity check value written incorrectly");

        assertEq(
            sanityCheckCallData, abi.encodeCall(ControllerTimelockV3.getMaxDebtPerBlockMultiplier, (creditManager))
        );

        vm.expectCall(
            creditConfigurator, abi.encodeWithSelector(ICreditConfiguratorV3.setMaxDebtPerBlockMultiplier.selector, 4)
        );

        vm.warp(block.timestamp + 2 days);

        vm.prank(admin);
        controllerTimelock.executeTransaction(txHash);

        (bool queued,,,,,,,) = controllerTimelock.queuedTransactions(txHash);

        assertTrue(!queued, "Transaction is still queued after execution");
    }

    /// @dev U:[CT-4A]: setMinDebtLimit works correctly
    function test_U_CT_04A_setMinDebtLimit_works_correctly() public {
        (address creditManager, address creditFacade, address creditConfigurator,,) = _makeMocks();

        string memory policyID = "setMinDebtLimit";

        vm.mockCall(creditFacade, abi.encodeWithSelector(ICreditFacadeV3.debtLimits.selector), abi.encode(10, 20));

        uint256[] memory setValues = new uint256[](1);
        setValues[0] = 15;

        Policy memory policy = Policy({
            enabled: false,
            admin: admin,
            delay: 3 days,
            checkInterval: false,
            checkSet: true,
            intervalMinValue: 0,
            intervalMaxValue: 0,
            setValues: setValues
        });

        // VERIFY THAT THE FUNCTION CANNOT BE CALLED WITHOUT RESPECTIVE POLICY
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setMinDebtLimit(creditManager, 15);

        vm.prank(CONFIGURATOR);
        controllerTimelock.setPolicy(policyID, policy);

        // VERIFY THAT THE FUNCTION IS ONLY CALLABLE BY ADMIN
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(USER);
        controllerTimelock.setMinDebtLimit(creditManager, 15);

        // VERIFY THAT POLICY CHECKS ARE PERFORMED
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setMinDebtLimit(creditManager, 5);

        // VERIFY THAT THE FUNCTION IS QUEUED AND EXECUTED CORRECTLY
        bytes32 txHash = keccak256(abi.encode(admin, creditConfigurator, "setMinDebtLimit(uint128)", abi.encode(15)));

        vm.expectEmit(true, false, false, true);
        emit QueueTransaction(
            txHash,
            admin,
            creditConfigurator,
            "setMinDebtLimit(uint128)",
            abi.encode(15),
            uint40(block.timestamp + 3 days)
        );

        vm.prank(admin);
        controllerTimelock.setMinDebtLimit(creditManager, 15);

        (,,,,,, uint256 sanityCheckValue, bytes memory sanityCheckCallData) =
            controllerTimelock.queuedTransactions(txHash);

        assertEq(sanityCheckValue, 10, "Sanity check value written incorrectly");

        assertEq(sanityCheckCallData, abi.encodeCall(ControllerTimelockV3.getMinDebtLimit, (creditManager)));

        vm.expectCall(creditConfigurator, abi.encodeWithSelector(ICreditConfiguratorV3.setMinDebtLimit.selector, 15));

        vm.warp(block.timestamp + 3 days);

        vm.prank(admin);
        controllerTimelock.executeTransaction(txHash);

        (bool queued,,,,,,,) = controllerTimelock.queuedTransactions(txHash);

        assertTrue(!queued, "Transaction is still queued after execution");
    }

    /// @dev U:[CT-4B]: setMaxDebtLimit works correctly
    function test_U_CT_04B_setMaxDebtLimit_works_correctly() public {
        (address creditManager, address creditFacade, address creditConfigurator,,) = _makeMocks();

        string memory policyID = "setMaxDebtLimit";

        vm.mockCall(creditFacade, abi.encodeWithSelector(ICreditFacadeV3.debtLimits.selector), abi.encode(10, 20));

        uint256[] memory setValues = new uint256[](1);
        setValues[0] = 25;

        Policy memory policy = Policy({
            enabled: false,
            admin: admin,
            delay: 1 days,
            checkInterval: false,
            checkSet: true,
            intervalMinValue: 0,
            intervalMaxValue: 0,
            setValues: setValues
        });

        // VERIFY THAT THE FUNCTION CANNOT BE CALLED WITHOUT RESPECTIVE POLICY
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setMaxDebtLimit(creditManager, 25);

        vm.prank(CONFIGURATOR);
        controllerTimelock.setPolicy(policyID, policy);

        // VERIFY THAT THE FUNCTION IS ONLY CALLABLE BY ADMIN
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(USER);
        controllerTimelock.setMaxDebtLimit(creditManager, 25);

        // VERIFY THAT POLICY CHECKS ARE PERFORMED
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setMaxDebtLimit(creditManager, 5);

        // VERIFY THAT THE FUNCTION IS QUEUED AND EXECUTED CORRECTLY
        bytes32 txHash = keccak256(abi.encode(admin, creditConfigurator, "setMaxDebtLimit(uint128)", abi.encode(25)));

        vm.expectEmit(true, false, false, true);
        emit QueueTransaction(
            txHash,
            admin,
            creditConfigurator,
            "setMaxDebtLimit(uint128)",
            abi.encode(25),
            uint40(block.timestamp + 1 days)
        );

        vm.prank(admin);
        controllerTimelock.setMaxDebtLimit(creditManager, 25);

        (,,,,,, uint256 sanityCheckValue, bytes memory sanityCheckCallData) =
            controllerTimelock.queuedTransactions(txHash);

        assertEq(sanityCheckValue, 20, "Sanity check value written incorrectly");

        assertEq(sanityCheckCallData, abi.encodeCall(ControllerTimelockV3.getMaxDebtLimit, (creditManager)));

        vm.expectCall(creditConfigurator, abi.encodeWithSelector(ICreditConfiguratorV3.setMaxDebtLimit.selector, 25));

        vm.warp(block.timestamp + 1 days);

        vm.prank(admin);
        controllerTimelock.executeTransaction(txHash);

        (bool queued,,,,,,,) = controllerTimelock.queuedTransactions(txHash);

        assertTrue(!queued, "Transaction is still queued after execution");
    }

    /// @dev U:[CT-5]: setCreditManagerDebtLimit works correctly
    function test_U_CT_05_setCreditManagerDebtLimit_works_correctly() public {
        (address creditManager, /* address creditFacade */,, address pool,) = _makeMocks();

        string memory policyID = "setCreditManagerDebtLimit";

        vm.mockCall(
            pool, abi.encodeWithSelector(IPoolV3.creditManagerDebtLimit.selector, creditManager), abi.encode(1e18)
        );

        uint256[] memory setValues = new uint256[](1);
        setValues[0] = 2e18;

        Policy memory policy = Policy({
            enabled: false,
            admin: admin,
            delay: 1 days,
            checkInterval: false,
            checkSet: true,
            intervalMinValue: 0,
            intervalMaxValue: 0,
            setValues: setValues
        });

        // VERIFY THAT THE FUNCTION CANNOT BE CALLED WITHOUT RESPECTIVE POLICY
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setCreditManagerDebtLimit(creditManager, 2e18);

        vm.prank(CONFIGURATOR);
        controllerTimelock.setPolicy(policyID, policy);

        // VERIFY THAT THE FUNCTION IS ONLY CALLABLE BY ADMIN
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(USER);
        controllerTimelock.setCreditManagerDebtLimit(creditManager, 2e18);

        // VERIFY THAT POLICY CHECKS ARE PERFORMED
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setCreditManagerDebtLimit(creditManager, 1e18);

        // VERIFY THAT THE FUNCTION IS QUEUED AND EXECUTED CORRECTLY
        bytes32 txHash = keccak256(
            abi.encode(admin, pool, "setCreditManagerDebtLimit(address,uint256)", abi.encode(creditManager, 2e18))
        );

        vm.expectEmit(true, false, false, true);
        emit QueueTransaction(
            txHash,
            admin,
            pool,
            "setCreditManagerDebtLimit(address,uint256)",
            abi.encode(creditManager, 2e18),
            uint40(block.timestamp + 1 days)
        );

        vm.prank(admin);
        controllerTimelock.setCreditManagerDebtLimit(creditManager, 2e18);

        (,,,,,, uint256 sanityCheckValue, bytes memory sanityCheckCallData) =
            controllerTimelock.queuedTransactions(txHash);

        assertEq(sanityCheckValue, 1e18, "Sanity check value written incorrectly");

        assertEq(
            sanityCheckCallData, abi.encodeCall(ControllerTimelockV3.getCreditManagerDebtLimit, (pool, creditManager))
        );

        vm.expectCall(pool, abi.encodeWithSelector(PoolV3.setCreditManagerDebtLimit.selector, creditManager, 2e18));

        vm.warp(block.timestamp + 1 days);

        vm.prank(admin);
        controllerTimelock.executeTransaction(txHash);

        (bool queued,,,,,,,) = controllerTimelock.queuedTransactions(txHash);

        assertTrue(!queued, "Transaction is still queued after execution");
    }

    /// @dev U:[CT-6]: rampLiquidationThreshold works correctly
    function test_U_CT_06_rampLiquidationThreshold_works_correctly() public {
        (address creditManager,, address creditConfigurator,,) = _makeMocks();

        address token = makeAddr("TOKEN");

        string memory policyID = "rampLiquidationThreshold";

        vm.mockCall(
            creditManager, abi.encodeWithSelector(ICreditManagerV3.liquidationThresholds.selector), abi.encode(5000)
        );

        vm.mockCall(
            creditManager,
            abi.encodeWithSelector(ICreditManagerV3.ltParams.selector),
            abi.encode(uint16(5000), uint16(5000), type(uint40).max, uint24(0))
        );

        uint256[] memory setValues = new uint256[](1);
        setValues[0] = 6000;

        Policy memory policy = Policy({
            enabled: false,
            admin: admin,
            delay: 1 days,
            checkInterval: false,
            checkSet: true,
            intervalMinValue: 0,
            intervalMaxValue: 0,
            setValues: setValues
        });

        // VERIFY THAT THE FUNCTION CANNOT BE CALLED WITHOUT RESPECTIVE POLICY
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.rampLiquidationThreshold(
            creditManager, token, 6000, uint40(block.timestamp + 14 days), 7 days
        );

        vm.prank(CONFIGURATOR);
        controllerTimelock.setPolicy(policyID, policy);

        // VERIFY THAT THE FUNCTION IS ONLY CALLABLE BY ADMIN
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(USER);
        controllerTimelock.rampLiquidationThreshold(
            creditManager, token, 6000, uint40(block.timestamp + 14 days), 7 days
        );

        // VERIFY THAT POLICY CHECKS ARE PERFORMED
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.rampLiquidationThreshold(
            creditManager, token, 5000, uint40(block.timestamp + 14 days), 7 days
        );

        // VERIFY THAT EXTRA CHECKS ARE PERFORMED
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.rampLiquidationThreshold(
            creditManager, token, 6000, uint40(block.timestamp + 14 days), 1 days
        );

        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.rampLiquidationThreshold(
            creditManager, token, 6000, uint40(block.timestamp + 1 days / 2), 7 days
        );

        // VERIFY THAT THE FUNCTION IS QUEUED AND EXECUTED CORRECTLY
        bytes32 txHash = keccak256(
            abi.encode(
                admin,
                creditConfigurator,
                "rampLiquidationThreshold(address,uint16,uint40,uint24)",
                abi.encode(token, 6000, block.timestamp + 14 days, 7 days)
            )
        );

        vm.expectEmit(true, false, false, true);
        emit QueueTransaction(
            txHash,
            admin,
            creditConfigurator,
            "rampLiquidationThreshold(address,uint16,uint40,uint24)",
            abi.encode(token, 6000, block.timestamp + 14 days, 7 days),
            uint40(block.timestamp + 1 days)
        );

        vm.prank(admin);
        controllerTimelock.rampLiquidationThreshold(
            creditManager, token, 6000, uint40(block.timestamp + 14 days), 7 days
        );

        (,,,,,, uint256 sanityCheckValue, bytes memory sanityCheckCallData) =
            controllerTimelock.queuedTransactions(txHash);

        assertEq(
            sanityCheckValue,
            uint256(keccak256(abi.encode(uint16(5000), uint16(5000), type(uint40).max, uint24(0)))),
            "Sanity check value written incorrectly"
        );

        assertEq(sanityCheckCallData, abi.encodeCall(ControllerTimelockV3.getLTRampParamsHash, (creditManager, token)));

        vm.expectCall(
            creditConfigurator,
            abi.encodeWithSelector(
                ICreditConfiguratorV3.rampLiquidationThreshold.selector,
                token,
                6000,
                uint40(block.timestamp + 14 days),
                7 days
            )
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(admin);
        controllerTimelock.executeTransaction(txHash);

        (bool queued,,,,,,,) = controllerTimelock.queuedTransactions(txHash);

        assertTrue(!queued, "Transaction is still queued after execution");
    }

    /// @dev U:[CT-7]: cancelTransaction works correctly
    function test_U_CT_07_cancelTransaction_works_correctly() public {
        (address creditManager, address creditFacade, address creditConfigurator, address pool,) = _makeMocks();

        string memory policyID = "setExpirationDate";

        vm.mockCall(
            creditFacade, abi.encodeWithSelector(ICreditFacadeV3.expirationDate.selector), abi.encode(block.timestamp)
        );

        vm.mockCall(pool, abi.encodeWithSelector(IPoolV3.creditManagerBorrowed.selector, creditManager), abi.encode(0));

        uint256[] memory setValues = new uint256[](1);
        setValues[0] = block.timestamp + 5;

        Policy memory policy = Policy({
            enabled: false,
            admin: admin,
            delay: 1 days,
            checkInterval: false,
            checkSet: true,
            intervalMinValue: 0,
            intervalMaxValue: 0,
            setValues: setValues
        });

        vm.prank(CONFIGURATOR);
        controllerTimelock.setPolicy(policyID, policy);

        // VERIFY THAT THE FUNCTION IS QUEUED AND EXECUTED CORRECTLY
        bytes32 txHash = keccak256(
            abi.encode(admin, creditConfigurator, "setExpirationDate(uint40)", abi.encode(block.timestamp + 5))
        );

        vm.prank(admin);
        controllerTimelock.setExpirationDate(creditManager, uint40(block.timestamp + 5));

        vm.expectRevert(CallerNotVetoAdminException.selector);

        vm.prank(admin);
        controllerTimelock.cancelTransaction(txHash);

        vm.expectEmit(true, false, false, false);
        emit CancelTransaction(txHash);

        vm.prank(vetoAdmin);
        controllerTimelock.cancelTransaction(txHash);

        (bool queued,,,,,,,) = controllerTimelock.queuedTransactions(txHash);

        assertTrue(!queued, "Transaction is still queued after cancelling");

        vm.expectRevert(TxNotQueuedException.selector);
        vm.prank(admin);
        controllerTimelock.executeTransaction(txHash);
    }

    /// @dev U:[CT-8]: configuration functions work correctly
    function test_U_CT_08_configuration_works_correctly() public {
        vm.expectRevert(CallerNotConfiguratorException.selector);
        vm.prank(USER);
        controllerTimelock.setVetoAdmin(DUMB_ADDRESS);

        vm.expectEmit(true, false, false, false);
        emit SetVetoAdmin(DUMB_ADDRESS);

        vm.prank(CONFIGURATOR);
        controllerTimelock.setVetoAdmin(DUMB_ADDRESS);

        assertEq(controllerTimelock.vetoAdmin(), DUMB_ADDRESS, "Veto admin address was not set");
    }

    /// @dev U:[CT-9]: executeTransaction works correctly
    function test_U_CT_09_executeTransaction_works_correctly() public {
        (address creditManager, address creditFacade, address creditConfigurator, address pool,) = _makeMocks();

        string memory policyID = "setExpirationDate";

        uint40 initialExpirationDate = uint40(block.timestamp);

        vm.mockCall(
            creditFacade,
            abi.encodeWithSelector(ICreditFacadeV3.expirationDate.selector),
            abi.encode(initialExpirationDate)
        );

        vm.mockCall(pool, abi.encodeWithSelector(IPoolV3.creditManagerBorrowed.selector, creditManager), abi.encode(0));

        uint40 expirationDate = uint40(block.timestamp + 2 days);

        uint256[] memory setValues = new uint256[](1);
        setValues[0] = expirationDate;

        Policy memory policy = Policy({
            enabled: false,
            admin: FRIEND,
            delay: 2 days,
            checkInterval: false,
            checkSet: true,
            intervalMinValue: 0,
            intervalMaxValue: 0,
            setValues: setValues
        });

        vm.prank(CONFIGURATOR);
        controllerTimelock.setPolicy(policyID, policy);

        // VERIFY THAT THE FUNCTION IS QUEUED AND EXECUTED CORRECTLY
        bytes32 txHash =
            keccak256(abi.encode(FRIEND, creditConfigurator, "setExpirationDate(uint40)", abi.encode(expirationDate)));

        vm.prank(FRIEND);
        controllerTimelock.setExpirationDate(creditManager, expirationDate);

        vm.expectRevert(CallerNotExecutorException.selector);
        vm.prank(USER);
        controllerTimelock.executeTransaction(txHash);

        vm.expectRevert(TxExecutedOutsideTimeWindowException.selector);
        vm.prank(FRIEND);
        controllerTimelock.executeTransaction(txHash);

        vm.warp(block.timestamp + 20 days);

        vm.expectRevert(TxExecutedOutsideTimeWindowException.selector);
        vm.prank(FRIEND);
        controllerTimelock.executeTransaction(txHash);

        vm.warp(block.timestamp - 10 days);

        vm.mockCallRevert(
            creditConfigurator,
            abi.encodeWithSelector(ICreditConfiguratorV3.setExpirationDate.selector, expirationDate),
            abi.encode("error")
        );

        vm.expectRevert(TxExecutionRevertedException.selector);
        vm.prank(FRIEND);
        controllerTimelock.executeTransaction(txHash);

        vm.clearMockedCalls();

        vm.mockCall(
            creditManager, abi.encodeWithSelector(ICreditManagerV3.creditFacade.selector), abi.encode(creditFacade)
        );

        vm.mockCall(
            creditFacade,
            abi.encodeWithSelector(ICreditFacadeV3.expirationDate.selector),
            abi.encode(block.timestamp + 2 days)
        );

        vm.expectRevert(ParameterChangedAfterQueuedTxException.selector);
        vm.prank(FRIEND);
        controllerTimelock.executeTransaction(txHash);

        vm.mockCall(
            creditFacade,
            abi.encodeWithSelector(ICreditFacadeV3.expirationDate.selector),
            abi.encode(initialExpirationDate)
        );

        vm.expectEmit(true, false, false, false);
        emit ExecuteTransaction(txHash);

        vm.prank(FRIEND);
        controllerTimelock.executeTransaction(txHash);
    }

    /// @dev U:[CT-10]: forbidAdapter works correctly
    function test_U_CT_10_forbidAdapter_works_correctly() public {
        (address creditManager,, address creditConfigurator,,) = _makeMocks();

        string memory policyID = "forbidAdapter";

        uint256[] memory setValues = new uint256[](0);

        Policy memory policy = Policy({
            enabled: false,
            admin: admin,
            delay: 1 days,
            checkInterval: false,
            checkSet: false,
            intervalMinValue: 0,
            intervalMaxValue: 0,
            setValues: setValues
        });

        // VERIFY THAT THE FUNCTION CANNOT BE CALLED WITHOUT RESPECTIVE POLICY
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.forbidAdapter(creditManager, DUMB_ADDRESS);

        vm.prank(CONFIGURATOR);
        controllerTimelock.setPolicy(policyID, policy);

        // VERIFY THAT THE FUNCTION IS ONLY CALLABLE BY ADMIN
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(USER);
        controllerTimelock.forbidAdapter(creditManager, DUMB_ADDRESS);

        // VERIFY THAT THE FUNCTION IS QUEUED AND EXECUTED CORRECTLY
        bytes32 txHash =
            keccak256(abi.encode(admin, creditConfigurator, "forbidAdapter(address)", abi.encode(DUMB_ADDRESS)));

        vm.expectEmit(true, false, false, true);
        emit QueueTransaction(
            txHash,
            admin,
            creditConfigurator,
            "forbidAdapter(address)",
            abi.encode(DUMB_ADDRESS),
            uint40(block.timestamp + 1 days)
        );

        vm.prank(admin);
        controllerTimelock.forbidAdapter(creditManager, DUMB_ADDRESS);

        (,,,,,, uint256 sanityCheckValue, bytes memory sanityCheckCallData) =
            controllerTimelock.queuedTransactions(txHash);

        assertEq(sanityCheckValue, 0, "Sanity check value written incorrectly");

        assertEq(sanityCheckCallData, "");

        vm.expectCall(
            creditConfigurator, abi.encodeWithSelector(ICreditConfiguratorV3.forbidAdapter.selector, DUMB_ADDRESS)
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(admin);
        controllerTimelock.executeTransaction(txHash);

        (bool queued,,,,,,,) = controllerTimelock.queuedTransactions(txHash);

        assertTrue(!queued, "Transaction is still queued after execution");
    }

    /// @dev U:[CT-11]: setTokenLimit works correctly
    function test_U_CT_11_setTokenLimit_works_correctly() public {
        (,,, address pool, address poolQuotaKeeper) = _makeMocks();

        address token = makeAddr("TOKEN");

        vm.mockCall(
            poolQuotaKeeper,
            abi.encodeCall(IPoolQuotaKeeperV3.getTokenQuotaParams, (token)),
            abi.encode(uint16(10), uint192(1e27), uint16(15), uint96(1e17), uint96(1e18), true)
        );

        string memory policyID = "setTokenLimit";

        uint256[] memory setValues = new uint256[](1);
        setValues[0] = 1e19;

        Policy memory policy = Policy({
            enabled: false,
            admin: admin,
            delay: 1 days,
            checkInterval: false,
            checkSet: true,
            intervalMinValue: 0,
            intervalMaxValue: 0,
            setValues: setValues
        });

        // VERIFY THAT THE FUNCTION CANNOT BE CALLED WITHOUT RESPECTIVE POLICY
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setTokenLimit(pool, token, 1e19);

        vm.prank(CONFIGURATOR);
        controllerTimelock.setPolicy(policyID, policy);

        // VERIFY THAT THE FUNCTION IS ONLY CALLABLE BY ADMIN
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(USER);
        controllerTimelock.setTokenLimit(pool, token, 1e19);

        // VERIFY THAT THE FUNCTION PERFORMS POLICY CHECKS
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setTokenLimit(pool, token, 1e20);

        // VERIFY THAT THE FUNCTION IS QUEUED AND EXECUTED CORRECTLY
        bytes32 txHash = keccak256(
            abi.encode(admin, poolQuotaKeeper, "setTokenLimit(address,uint96)", abi.encode(token, uint96(1e19)))
        );

        vm.expectEmit(true, false, false, true);
        emit QueueTransaction(
            txHash,
            admin,
            poolQuotaKeeper,
            "setTokenLimit(address,uint96)",
            abi.encode(token, uint96(1e19)),
            uint40(block.timestamp + 1 days)
        );

        vm.prank(admin);
        controllerTimelock.setTokenLimit(pool, token, 1e19);

        (,,,,,, uint256 sanityCheckValue, bytes memory sanityCheckCallData) =
            controllerTimelock.queuedTransactions(txHash);

        assertEq(sanityCheckValue, 1e18, "Sanity check value written incorrectly");

        assertEq(sanityCheckCallData, abi.encodeCall(ControllerTimelockV3.getTokenLimit, (poolQuotaKeeper, token)));

        vm.expectCall(poolQuotaKeeper, abi.encodeCall(PoolQuotaKeeperV3.setTokenLimit, (token, 1e19)));

        vm.warp(block.timestamp + 1 days);

        vm.prank(admin);
        controllerTimelock.executeTransaction(txHash);

        (bool queued,,,,,,,) = controllerTimelock.queuedTransactions(txHash);

        assertTrue(!queued, "Transaction is still queued after execution");
    }

    /// @dev U:[CT-12]: setQuotaIncreaseFee works correctly
    function test_U_CT_12_setTokenQuotaIncreaseFee_works_correctly() public {
        (,,, address pool, address poolQuotaKeeper) = _makeMocks();

        address token = makeAddr("TOKEN");

        vm.mockCall(
            poolQuotaKeeper,
            abi.encodeCall(IPoolQuotaKeeperV3.getTokenQuotaParams, (token)),
            abi.encode(uint16(10), uint192(1e27), uint16(15), uint96(1e17), uint96(1e18), false)
        );

        string memory policyID = "setTokenQuotaIncreaseFee";

        uint256[] memory setValues = new uint256[](1);
        setValues[0] = 20;

        Policy memory policy = Policy({
            enabled: false,
            admin: admin,
            delay: 1 days,
            checkInterval: false,
            checkSet: true,
            intervalMinValue: 0,
            intervalMaxValue: 0,
            setValues: setValues
        });

        // VERIFY THAT THE FUNCTION CANNOT BE CALLED WITHOUT RESPECTIVE POLICY
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setTokenQuotaIncreaseFee(pool, token, 20);

        vm.prank(CONFIGURATOR);
        controllerTimelock.setPolicy(policyID, policy);

        // VERIFY THAT THE FUNCTION IS ONLY CALLABLE BY ADMIN
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(USER);
        controllerTimelock.setTokenQuotaIncreaseFee(pool, token, 20);

        // VERIFY THAT THE FUNCTION PERFORMS POLICY CHECKS
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setTokenQuotaIncreaseFee(pool, token, 30);

        // VERIFY THAT THE FUNCTION IS QUEUED AND EXECUTED CORRECTLY
        bytes32 txHash = keccak256(
            abi.encode(
                admin, poolQuotaKeeper, "setTokenQuotaIncreaseFee(address,uint16)", abi.encode(token, uint16(20))
            )
        );

        vm.expectEmit(true, false, false, true);
        emit QueueTransaction(
            txHash,
            admin,
            poolQuotaKeeper,
            "setTokenQuotaIncreaseFee(address,uint16)",
            abi.encode(token, uint16(20)),
            uint40(block.timestamp + 1 days)
        );

        vm.prank(admin);
        controllerTimelock.setTokenQuotaIncreaseFee(pool, token, 20);

        (,,,,,, uint256 sanityCheckValue, bytes memory sanityCheckCallData) =
            controllerTimelock.queuedTransactions(txHash);

        assertEq(sanityCheckValue, 15, "Sanity check value written incorrectly");

        assertEq(
            sanityCheckCallData, abi.encodeCall(ControllerTimelockV3.getTokenQuotaIncreaseFee, (poolQuotaKeeper, token))
        );

        vm.expectCall(poolQuotaKeeper, abi.encodeCall(PoolQuotaKeeperV3.setTokenQuotaIncreaseFee, (token, 20)));

        vm.warp(block.timestamp + 1 days);

        vm.prank(admin);
        controllerTimelock.executeTransaction(txHash);

        (bool queued,,,,,,,) = controllerTimelock.queuedTransactions(txHash);

        assertTrue(!queued, "Transaction is still queued after execution");
    }

    /// @dev U:[CT-13]: setTotalDebt works correctly
    function test_U_CT_13_setTotalDebtLimit_works_correctly() public {
        (,,, address pool,) = _makeMocks();

        vm.mockCall(pool, abi.encodeCall(IPoolV3.totalDebtLimit, ()), abi.encode(1e18));

        string memory policyID = "setTotalDebtLimit";

        uint256[] memory setValues = new uint256[](1);
        setValues[0] = 2e18;

        Policy memory policy = Policy({
            enabled: false,
            admin: admin,
            delay: 1 days,
            checkInterval: false,
            checkSet: true,
            intervalMinValue: 0,
            intervalMaxValue: 0,
            setValues: setValues
        });

        // VERIFY THAT THE FUNCTION CANNOT BE CALLED WITHOUT RESPECTIVE POLICY
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setTotalDebtLimit(pool, 2e18);

        vm.prank(CONFIGURATOR);
        controllerTimelock.setPolicy(policyID, policy);

        // VERIFY THAT THE FUNCTION IS ONLY CALLABLE BY ADMIN
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(USER);
        controllerTimelock.setTotalDebtLimit(pool, 2e18);

        // VERIFY THAT THE FUNCTION PERFORMS POLICY CHECKS
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setTotalDebtLimit(pool, 3e18);

        // VERIFY THAT THE FUNCTION IS QUEUED AND EXECUTED CORRECTLY
        bytes32 txHash = keccak256(abi.encode(admin, pool, "setTotalDebtLimit(uint256)", abi.encode(2e18)));

        vm.expectEmit(true, false, false, true);
        emit QueueTransaction(
            txHash, admin, pool, "setTotalDebtLimit(uint256)", abi.encode(2e18), uint40(block.timestamp + 1 days)
        );

        vm.prank(admin);
        controllerTimelock.setTotalDebtLimit(pool, 2e18);

        (,,,,,, uint256 sanityCheckValue, bytes memory sanityCheckCallData) =
            controllerTimelock.queuedTransactions(txHash);

        assertEq(sanityCheckValue, 1e18, "Sanity check value written incorrectly");

        assertEq(sanityCheckCallData, abi.encodeCall(ControllerTimelockV3.getTotalDebtLimit, (pool)));

        vm.expectCall(pool, abi.encodeCall(PoolV3.setTotalDebtLimit, (2e18)));

        vm.warp(block.timestamp + 1 days);

        vm.prank(admin);
        controllerTimelock.executeTransaction(txHash);

        (bool queued,,,,,,,) = controllerTimelock.queuedTransactions(txHash);

        assertTrue(!queued, "Transaction is still queued after execution");
    }

    /// @dev U:[CT-14]: setWithdrawFee works correctly
    function test_U_CT_14_setWithdrawFee_works_correctly() public {
        (,,, address pool,) = _makeMocks();

        vm.mockCall(pool, abi.encodeCall(IPoolV3.withdrawFee, ()), abi.encode(10));

        string memory policyID = "setWithdrawFee";

        uint256[] memory setValues = new uint256[](1);
        setValues[0] = 20;

        Policy memory policy = Policy({
            enabled: false,
            admin: admin,
            delay: 1 days,
            checkInterval: false,
            checkSet: true,
            intervalMinValue: 0,
            intervalMaxValue: 0,
            setValues: setValues
        });

        // VERIFY THAT THE FUNCTION CANNOT BE CALLED WITHOUT RESPECTIVE POLICY
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setWithdrawFee(pool, 20);

        vm.prank(CONFIGURATOR);
        controllerTimelock.setPolicy(policyID, policy);

        // VERIFY THAT THE FUNCTION IS ONLY CALLABLE BY ADMIN
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(USER);
        controllerTimelock.setWithdrawFee(pool, 20);

        // VERIFY THAT THE FUNCTION PERFORMS POLICY CHECKS
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setWithdrawFee(pool, 30);

        // VERIFY THAT THE FUNCTION IS QUEUED AND EXECUTED CORRECTLY
        bytes32 txHash = keccak256(abi.encode(admin, pool, "setWithdrawFee(uint256)", abi.encode(20)));

        vm.expectEmit(true, false, false, true);
        emit QueueTransaction(
            txHash, admin, pool, "setWithdrawFee(uint256)", abi.encode(20), uint40(block.timestamp + 1 days)
        );

        vm.prank(admin);
        controllerTimelock.setWithdrawFee(pool, 20);

        (,,,,,, uint256 sanityCheckValue, bytes memory sanityCheckCallData) =
            controllerTimelock.queuedTransactions(txHash);

        assertEq(sanityCheckValue, 10, "Sanity check value written incorrectly");

        assertEq(sanityCheckCallData, abi.encodeCall(ControllerTimelockV3.getWithdrawFee, (pool)));

        vm.expectCall(pool, abi.encodeCall(PoolV3.setWithdrawFee, (20)));

        vm.warp(block.timestamp + 1 days);

        vm.prank(admin);
        controllerTimelock.executeTransaction(txHash);

        (bool queued,,,,,,,) = controllerTimelock.queuedTransactions(txHash);

        assertTrue(!queued, "Transaction is still queued after execution");
    }

    /// @dev U:[CT-15A]: setMinQuotaRate works correctly
    function test_U_CT_15A_setMinQuotaRate_works_correctly() public {
        (,,, address pool, address poolQuotaKeeper) = _makeMocks();

        address gauge = address(new GeneralMock());

        vm.mockCall(poolQuotaKeeper, abi.encodeCall(IPoolQuotaKeeperV3.gauge, ()), abi.encode(gauge));

        address token = makeAddr("TOKEN");

        vm.mockCall(
            gauge,
            abi.encodeCall(IGaugeV3.quotaRateParams, (token)),
            abi.encode(uint16(10), uint16(20), uint96(100), uint96(200))
        );

        string memory policyID = "setMinQuotaRate";

        uint256[] memory setValues = new uint256[](1);
        setValues[0] = 15;

        Policy memory policy = Policy({
            enabled: false,
            admin: admin,
            delay: 1 days,
            checkInterval: false,
            checkSet: true,
            intervalMinValue: 0,
            intervalMaxValue: 0,
            setValues: setValues
        });

        // VERIFY THAT THE FUNCTION CANNOT BE CALLED WITHOUT RESPECTIVE POLICY
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setMinQuotaRate(pool, token, 15);

        vm.prank(CONFIGURATOR);
        controllerTimelock.setPolicy(policyID, policy);

        // VERIFY THAT THE FUNCTION IS ONLY CALLABLE BY ADMIN
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(USER);
        controllerTimelock.setMinQuotaRate(pool, token, 15);

        // VERIFY THAT THE FUNCTION PERFORMS POLICY CHECKS
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setMinQuotaRate(pool, token, 25);

        // VERIFY THAT THE FUNCTION IS QUEUED AND EXECUTED CORRECTLY
        bytes32 txHash =
            keccak256(abi.encode(admin, gauge, "changeQuotaMinRate(address,uint16)", abi.encode(token, uint16(15))));

        vm.expectEmit(true, false, false, true);
        emit QueueTransaction(
            txHash,
            admin,
            gauge,
            "changeQuotaMinRate(address,uint16)",
            abi.encode(token, uint16(15)),
            uint40(block.timestamp + 1 days)
        );

        vm.prank(admin);
        controllerTimelock.setMinQuotaRate(pool, token, 15);

        (,,,,,, uint256 sanityCheckValue, bytes memory sanityCheckCallData) =
            controllerTimelock.queuedTransactions(txHash);

        assertEq(sanityCheckValue, 10, "Sanity check value written incorrectly");

        assertEq(sanityCheckCallData, abi.encodeCall(ControllerTimelockV3.getMinQuotaRate, (gauge, token)));

        vm.expectCall(gauge, abi.encodeCall(GaugeV3.changeQuotaMinRate, (token, 15)));

        vm.warp(block.timestamp + 1 days);

        vm.prank(admin);
        controllerTimelock.executeTransaction(txHash);

        (bool queued,,,,,,,) = controllerTimelock.queuedTransactions(txHash);

        assertTrue(!queued, "Transaction is still queued after execution");
    }

    /// @dev U:[CT-15B]: setMaxQuotaRate works correctly
    function test_U_CT_15B_setMaxQuotaRate_works_correctly() public {
        (,,, address pool, address poolQuotaKeeper) = _makeMocks();

        address gauge = address(new GeneralMock());

        vm.mockCall(poolQuotaKeeper, abi.encodeCall(IPoolQuotaKeeperV3.gauge, ()), abi.encode(gauge));

        address token = makeAddr("TOKEN");

        vm.mockCall(
            gauge,
            abi.encodeCall(IGaugeV3.quotaRateParams, (token)),
            abi.encode(uint16(10), uint16(20), uint96(100), uint96(200))
        );

        string memory policyID = "setMaxQuotaRate";

        uint256[] memory setValues = new uint256[](1);
        setValues[0] = 25;

        Policy memory policy = Policy({
            enabled: false,
            admin: admin,
            delay: 1 days,
            checkInterval: false,
            checkSet: true,
            intervalMinValue: 0,
            intervalMaxValue: 0,
            setValues: setValues
        });

        // VERIFY THAT THE FUNCTION CANNOT BE CALLED WITHOUT RESPECTIVE POLICY
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setMaxQuotaRate(pool, token, 25);

        vm.prank(CONFIGURATOR);
        controllerTimelock.setPolicy(policyID, policy);

        // VERIFY THAT THE FUNCTION IS ONLY CALLABLE BY ADMIN
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(USER);
        controllerTimelock.setMaxQuotaRate(pool, token, 25);

        // VERIFY THAT THE FUNCTION PERFORMS POLICY CHECKS
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setMaxQuotaRate(pool, token, 35);

        // VERIFY THAT THE FUNCTION IS QUEUED AND EXECUTED CORRECTLY
        bytes32 txHash =
            keccak256(abi.encode(admin, gauge, "changeQuotaMaxRate(address,uint16)", abi.encode(token, uint16(25))));

        vm.expectEmit(true, false, false, true);
        emit QueueTransaction(
            txHash,
            admin,
            gauge,
            "changeQuotaMaxRate(address,uint16)",
            abi.encode(token, uint16(25)),
            uint40(block.timestamp + 1 days)
        );

        vm.prank(admin);
        controllerTimelock.setMaxQuotaRate(pool, token, 25);

        (,,,,,, uint256 sanityCheckValue, bytes memory sanityCheckCallData) =
            controllerTimelock.queuedTransactions(txHash);

        assertEq(sanityCheckValue, 20, "Sanity check value written incorrectly");

        assertEq(sanityCheckCallData, abi.encodeCall(ControllerTimelockV3.getMaxQuotaRate, (gauge, token)));

        vm.expectCall(gauge, abi.encodeCall(GaugeV3.changeQuotaMaxRate, (token, 25)));

        vm.warp(block.timestamp + 1 days);

        vm.prank(admin);
        controllerTimelock.executeTransaction(txHash);

        (bool queued,,,,,,,) = controllerTimelock.queuedTransactions(txHash);

        assertTrue(!queued, "Transaction is still queued after execution");
    }

    /// @dev U:[CT-16]: forbidBoundsUpdate works correctly
    function test_U_CT_16_forbidBoundsUpdate_works_correctly() public {
        address priceFeed = makeAddr("PRICE_FEED");
        vm.mockCall(priceFeed, abi.encodeWithSignature("forbidBoundsUpdate()"), "");

        string memory policyID = "forbidBoundsUpdate";

        uint256[] memory setValues = new uint256[](0);

        Policy memory policy = Policy({
            enabled: false,
            admin: admin,
            delay: 1 days,
            checkInterval: false,
            checkSet: false,
            intervalMinValue: 0,
            intervalMaxValue: 0,
            setValues: setValues
        });

        // VERIFY THAT THE FUNCTION CANNOT BE CALLED WITHOUT RESPECTIVE POLICY
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.forbidBoundsUpdate(priceFeed);

        vm.prank(CONFIGURATOR);
        controllerTimelock.setPolicy(policyID, policy);

        // VERIFY THAT THE FUNCTION IS ONLY CALLABLE BY ADMIN
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(USER);
        controllerTimelock.forbidBoundsUpdate(priceFeed);

        // VERIFY THAT THE FUNCTION IS QUEUED AND EXECUTED CORRECTLY
        bytes32 txHash = keccak256(abi.encode(admin, priceFeed, "forbidBoundsUpdate()", ""));

        vm.expectEmit(true, false, false, true);
        emit QueueTransaction(txHash, admin, priceFeed, "forbidBoundsUpdate()", "", uint40(block.timestamp + 1 days));

        vm.prank(admin);
        controllerTimelock.forbidBoundsUpdate(priceFeed);

        (,,,,,, uint256 sanityCheckValue, bytes memory sanityCheckCallData) =
            controllerTimelock.queuedTransactions(txHash);

        assertEq(sanityCheckValue, 0, "Sanity check value written incorrectly");

        assertEq(sanityCheckCallData, "");

        vm.expectCall(priceFeed, abi.encodeWithSignature("forbidBoundsUpdate()"));

        vm.warp(block.timestamp + 1 days);

        vm.prank(admin);
        controllerTimelock.executeTransaction(txHash);

        (bool queued,,,,,,,) = controllerTimelock.queuedTransactions(txHash);

        assertTrue(!queued, "Transaction is still queued after execution");
    }

    /// @dev U:[CT-18]: setPriceFeed works correctly
    function test_U_CT_18_setPriceFeed_works_correctly() public {
        address token = makeAddr("TOKEN");
        address priceFeed = makeAddr("PRICE_FEED");
        address priceOracle = makeAddr("PRICE_ORACLE");
        vm.mockCall(priceOracle, abi.encodeCall(IPriceOracleV3.setPriceFeed, (token, priceFeed, 4500)), "");
        vm.mockCall(
            priceOracle,
            abi.encodeCall(IPriceOracleV3.priceFeedParams, (token)),
            abi.encode(PriceFeedParams(priceFeed, 3000, false, 18))
        );

        string memory policyID = string(abi.encodePacked("setPriceFeed_", Strings.toHexString(token)));

        uint256 pfKeccak = uint256(keccak256(abi.encode(priceFeed, uint32(4500))));
        uint256[] memory setValues = new uint256[](1);
        setValues[0] = pfKeccak;

        Policy memory policy = Policy({
            enabled: false,
            admin: admin,
            delay: 1 days,
            checkInterval: false,
            checkSet: true,
            intervalMinValue: 0,
            intervalMaxValue: 0,
            setValues: setValues
        });

        // VERIFY THAT THE FUNCTION CANNOT BE CALLED WITHOUT RESPECTIVE POLICY
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(admin);
        controllerTimelock.setPriceFeed(priceOracle, token, priceFeed, 4500);

        vm.prank(CONFIGURATOR);
        controllerTimelock.setPolicy(policyID, policy);

        // VERIFY THAT THE FUNCTION IS ONLY CALLABLE BY ADMIN
        vm.expectRevert(ParameterChecksFailedException.selector);
        vm.prank(USER);
        controllerTimelock.setPriceFeed(priceOracle, token, priceFeed, 4500);

        // VERIFY THAT THE FUNCTION IS QUEUED AND EXECUTED CORRECTLY
        bytes32 txHash = keccak256(
            abi.encode(admin, priceOracle, "setPriceFeed(address,address,uint32)", abi.encode(token, priceFeed, 4500))
        );

        vm.expectEmit(true, false, false, true);
        emit QueueTransaction(
            txHash,
            admin,
            priceOracle,
            "setPriceFeed(address,address,uint32)",
            abi.encode(token, priceFeed, 4500),
            uint40(block.timestamp + 1 days)
        );

        vm.prank(admin);
        controllerTimelock.setPriceFeed(priceOracle, token, priceFeed, 4500);

        (,,,,,, uint256 sanityCheckValue, bytes memory sanityCheckCallData) =
            controllerTimelock.queuedTransactions(txHash);

        assertEq(
            sanityCheckValue, uint256(keccak256(abi.encode(priceFeed, 3000))), "Sanity check value written incorrectly"
        );

        assertEq(
            sanityCheckCallData, abi.encodeCall(ControllerTimelockV3.getCurrentPriceFeedHash, (priceOracle, token))
        );

        vm.expectCall(priceOracle, abi.encodeCall(IPriceOracleV3.setPriceFeed, (token, priceFeed, 4500)));

        vm.warp(block.timestamp + 1 days);

        vm.prank(admin);
        controllerTimelock.executeTransaction(txHash);

        (bool queued,,,,,,,) = controllerTimelock.queuedTransactions(txHash);

        assertTrue(!queued, "Transaction is still queued after execution");
    }

    /// @dev U:[CT-19]: executor logic is correct
    function test_U_CT_19_executor_logic_is_correct() public {
        (,,, address pool, address poolQuotaKeeper) = _makeMocks();

        address token = makeAddr("TOKEN");

        vm.startPrank(CONFIGURATOR);

        vm.expectEmit(true, false, false, true);
        emit SetExecutor(FRIEND2, true);

        controllerTimelock.setExecutor(FRIEND2, true);

        vm.stopPrank();

        vm.mockCall(
            poolQuotaKeeper,
            abi.encodeCall(IPoolQuotaKeeperV3.getTokenQuotaParams, (token)),
            abi.encode(uint16(10), uint192(1e27), uint16(15), uint96(1e17), uint96(1e18), true)
        );

        string memory policyID = "setTokenLimit";

        uint256[] memory setValues = new uint256[](1);
        setValues[0] = 2e18;

        Policy memory policy = Policy({
            enabled: false,
            admin: FRIEND,
            delay: 1 days,
            checkInterval: false,
            checkSet: true,
            intervalMinValue: 0,
            intervalMaxValue: 0,
            setValues: setValues
        });

        vm.prank(CONFIGURATOR);
        controllerTimelock.setPolicy(policyID, policy);

        vm.prank(FRIEND);
        controllerTimelock.setTokenLimit(pool, token, 2e18);

        bytes32 txHash = keccak256(
            abi.encode(FRIEND, poolQuotaKeeper, "setTokenLimit(address,uint96)", abi.encode(token, uint96(2e18)))
        );

        vm.warp(block.timestamp + 1 days);

        vm.prank(FRIEND2);
        controllerTimelock.executeTransaction(txHash);
    }
}
