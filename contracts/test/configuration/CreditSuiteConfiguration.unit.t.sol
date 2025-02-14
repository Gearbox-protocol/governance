// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.23;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

import {MockCreditConfiguratorPatch} from "../mocks/MockCreditConfiguratorPatch.sol";
import {ConfigurationTestHelper} from "./ConfigurationTestHelper.sol";
import {CreditFactory} from "../../factories/CreditFactory.sol";
import {ICreditConfigureActions} from "../../interfaces/factories/ICreditConfigureActions.sol";
import {ICreditEmergencyConfigureActions} from "../../interfaces/factories/ICreditEmergencyConfigureActions.sol";
import {IPriceOracleConfigureActions} from "../../interfaces/factories/IPriceOracleConfigureActions.sol";
import {ICreditConfiguratorV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditConfiguratorV3.sol";
import {ICreditFacadeV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditFacadeV3.sol";
import {ICreditManagerV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import {DeployParams} from "../../interfaces/Types.sol";
import {IAddressProvider} from "../../interfaces/IAddressProvider.sol";
import {IContractsRegister} from "../../interfaces/IContractsRegister.sol";
import {IBytecodeRepository} from "../../interfaces/IBytecodeRepository.sol";
import {IMarketConfigurator} from "../../interfaces/IMarketConfigurator.sol";
import {
    NO_VERSION_CONTROL,
    AP_BYTECODE_REPOSITORY,
    AP_CREDIT_FACTORY,
    AP_WETH_TOKEN,
    AP_CREDIT_CONFIGURATOR
} from "../../libraries/ContractLiterals.sol";
import {CreditFacadeParams} from "../../factories/CreditFactory.sol";
import {CrossChainCall} from "../helpers/GlobalSetup.sol";

import {GeneralMock} from "@gearbox-protocol/core-v3/contracts/test/mocks/GeneralMock.sol";
import {PERCENTAGE_FACTOR} from "@gearbox-protocol/core-v3/contracts/libraries/Constants.sol";
import {UploadableContract} from "../helpers/GlobalSetup.sol";

import {
    IUniswapV3Adapter,
    UniswapV3PoolStatus
} from "@gearbox-protocol/integrations-v3/contracts/interfaces/uniswap/IUniswapV3Adapter.sol";

contract CreditSuiteConfigurationUnitTest is ConfigurationTestHelper {
    address target;
    address creditFactory;

    function setUp() public override {
        super.setUp();

        target = address(new GeneralMock());
        creditFactory = IAddressProvider(addressProvider).getAddressOrRevert(AP_CREDIT_FACTORY, 3_10);
    }

    function _uploadCreditConfiguratorPatch() internal {
        CrossChainCall[] memory calls = new CrossChainCall[](1);

        bytes32 bytecodeHash =
            _uploadByteCodeAndSign(type(MockCreditConfiguratorPatch).creationCode, AP_CREDIT_CONFIGURATOR, 3_11);

        calls[0] = _generateAllowSystemContractCall(bytecodeHash);

        _submitProposalAndSign("Allow system contracts", calls);
    }

    /// REGULAR CONFIGURATION TESTS ///

    function test_CS_01_allowAdapter() public {
        DeployParams memory params = DeployParams({
            postfix: "BALANCER_VAULT",
            salt: 0,
            constructorParams: abi.encode(address(creditManager), target)
        });

        address bytecodeRepository =
            IAddressProvider(addressProvider).getAddressOrRevert(AP_BYTECODE_REPOSITORY, NO_VERSION_CONTROL);

        address expectedAdapter = IBytecodeRepository(bytecodeRepository).computeAddress(
            "ADAPTER::BALANCER_VAULT",
            3_10,
            params.constructorParams,
            keccak256(abi.encode(0, address(marketConfigurator))),
            creditFactory
        );

        // Expect factory authorization and adapter allowance
        vm.expectCall(
            address(marketConfigurator),
            abi.encodeCall(
                IMarketConfigurator.authorizeFactory, (creditFactory, address(creditManager), expectedAdapter)
            )
        );
        vm.expectCall(
            address(creditConfigurator), abi.encodeCall(ICreditConfiguratorV3.allowAdapter, (expectedAdapter))
        );

        vm.prank(admin);
        marketConfigurator.configureCreditSuite(
            address(creditManager), abi.encodeCall(ICreditConfigureActions.allowAdapter, (params))
        );

        // Verify adapter is allowed and factory is authorized
        assertEq(ICreditManagerV3(creditManager).adapterToContract(expectedAdapter), target, "Adapter must be allowed");
        assertTrue(
            IMarketConfigurator(marketConfigurator).getAuthorizedFactory(expectedAdapter) == creditFactory,
            "Factory must be authorized"
        );
    }

    function test_CS_02_forbidAdapter() public {
        DeployParams memory params = DeployParams({
            postfix: "BALANCER_VAULT",
            salt: 0,
            constructorParams: abi.encode(address(creditManager), target)
        });

        // First allow adapter
        vm.prank(admin);
        marketConfigurator.configureCreditSuite(
            address(creditManager), abi.encodeCall(ICreditConfigureActions.allowAdapter, (params))
        );

        address adapter = ICreditManagerV3(creditManager).contractToAdapter(target);

        // Expect factory unauthorized and adapter forbidden
        vm.expectCall(
            address(marketConfigurator),
            abi.encodeCall(IMarketConfigurator.unauthorizeFactory, (creditFactory, address(creditManager), adapter))
        );
        vm.expectCall(address(creditConfigurator), abi.encodeCall(ICreditConfiguratorV3.forbidAdapter, (adapter)));

        vm.prank(admin);
        marketConfigurator.configureCreditSuite(
            address(creditManager), abi.encodeCall(ICreditConfigureActions.forbidAdapter, (adapter))
        );

        // Verify adapter is forbidden and factory is unauthorized
        assertEq(ICreditManagerV3(creditManager).contractToAdapter(target), address(0), "Adapter must be forbidden");
        assertTrue(
            IMarketConfigurator(marketConfigurator).getAuthorizedFactory(adapter) == address(0),
            "Factory must be unauthorized"
        );
    }

    function test_CS_03_setFees() public {
        uint16 feeLiquidation = 100;
        uint16 liquidationPremium = 200;
        uint16 feeLiquidationExpired = 100;
        uint16 liquidationPremiumExpired = 200;

        vm.expectCall(
            address(creditConfigurator),
            abi.encodeCall(
                ICreditConfiguratorV3.setFees,
                (feeLiquidation, liquidationPremium, feeLiquidationExpired, liquidationPremiumExpired)
            )
        );

        vm.prank(admin);
        marketConfigurator.configureCreditSuite(
            address(creditManager),
            abi.encodeCall(
                ICreditConfigureActions.setFees,
                (feeLiquidation, liquidationPremium, feeLiquidationExpired, liquidationPremiumExpired)
            )
        );

        (, uint16 fl, uint16 lp, uint16 fle, uint16 lpe) = ICreditManagerV3(creditManager).fees();
        assertEq(fl, feeLiquidation, "Incorrect feeLiquidation");
        assertEq(lp, PERCENTAGE_FACTOR - liquidationPremium, "Incorrect liquidationPremium");
        assertEq(fle, feeLiquidationExpired, "Incorrect feeLiquidationExpired");
        assertEq(lpe, PERCENTAGE_FACTOR - liquidationPremiumExpired, "Incorrect liquidationPremiumExpired");
    }

    function test_CS_04_addCollateralToken() public {
        _addUSDC();

        address token = USDC;
        uint16 liquidationThreshold = 8000;

        vm.expectCall(
            address(creditConfigurator),
            abi.encodeCall(ICreditConfiguratorV3.addCollateralToken, (token, liquidationThreshold))
        );

        vm.prank(admin);
        marketConfigurator.configureCreditSuite(
            address(creditManager),
            abi.encodeCall(ICreditConfigureActions.addCollateralToken, (token, liquidationThreshold))
        );

        ICreditManagerV3(creditManager).getTokenMaskOrRevert(token);
        assertEq(
            ICreditManagerV3(creditManager).liquidationThresholds(token),
            liquidationThreshold,
            "Incorrect liquidation threshold"
        );
    }

    function test_CS_05_forbidToken() public {
        _addUSDC();

        address token = USDC;
        uint16 liquidationThreshold = 8000;

        vm.prank(admin);
        marketConfigurator.configureCreditSuite(
            address(creditManager),
            abi.encodeCall(ICreditConfigureActions.addCollateralToken, (token, liquidationThreshold))
        );

        vm.expectCall(address(creditConfigurator), abi.encodeCall(ICreditConfiguratorV3.forbidToken, (token)));

        vm.prank(admin);
        marketConfigurator.configureCreditSuite(
            address(creditManager), abi.encodeCall(ICreditConfigureActions.forbidToken, (token))
        );

        assertTrue(
            ICreditFacadeV3(creditFacade).forbiddenTokenMask()
                & ICreditManagerV3(creditManager).getTokenMaskOrRevert(token) != 0,
            "Token must be forbidden"
        );
    }

    function test_CS_06_allowToken() public {
        _addUSDC();

        address token = USDC;
        uint16 liquidationThreshold = 8000;

        vm.startPrank(admin);
        marketConfigurator.configureCreditSuite(
            address(creditManager),
            abi.encodeCall(ICreditConfigureActions.addCollateralToken, (token, liquidationThreshold))
        );

        marketConfigurator.configureCreditSuite(
            address(creditManager), abi.encodeCall(ICreditConfigureActions.forbidToken, (token))
        );

        vm.expectCall(address(creditConfigurator), abi.encodeCall(ICreditConfiguratorV3.allowToken, (token)));

        marketConfigurator.configureCreditSuite(
            address(creditManager), abi.encodeCall(ICreditConfigureActions.allowToken, (token))
        );
        vm.stopPrank();

        assertTrue(
            ICreditFacadeV3(creditFacade).forbiddenTokenMask()
                & ICreditManagerV3(creditManager).getTokenMaskOrRevert(token) == 0,
            "Token must be allowed"
        );
    }

    function test_CS_07_upgradeCreditConfigurator() public {
        _uploadCreditConfiguratorPatch();

        address bytecodeRepository =
            IAddressProvider(addressProvider).getAddressOrRevert(AP_BYTECODE_REPOSITORY, NO_VERSION_CONTROL);

        // Compute expected new configurator address
        address expectedNewConfigurator = IBytecodeRepository(bytecodeRepository).computeAddress(
            "CREDIT_CONFIGURATOR",
            3_11,
            abi.encode(address(creditManager)),
            bytes32(bytes20(address(marketConfigurator))),
            creditFactory
        );

        // Expect factory authorization/unauthorized and configurator upgrade
        vm.expectCall(
            address(marketConfigurator),
            abi.encodeCall(
                IMarketConfigurator.unauthorizeFactory,
                (creditFactory, address(creditManager), address(creditConfigurator))
            )
        );
        vm.expectCall(
            address(marketConfigurator),
            abi.encodeCall(
                IMarketConfigurator.authorizeFactory, (creditFactory, address(creditManager), expectedNewConfigurator)
            )
        );
        vm.expectCall(
            address(creditConfigurator),
            abi.encodeCall(ICreditConfiguratorV3.upgradeCreditConfigurator, (expectedNewConfigurator))
        );

        vm.prank(admin);
        marketConfigurator.configureCreditSuite(
            address(creditManager), abi.encodeCall(ICreditConfigureActions.upgradeCreditConfigurator, ())
        );

        // Verify configurator was upgraded and factory authorization was transferred
        assertEq(
            ICreditManagerV3(creditManager).creditConfigurator(),
            expectedNewConfigurator,
            "Credit configurator must be upgraded"
        );
        assertTrue(
            IMarketConfigurator(marketConfigurator).getAuthorizedFactory(expectedNewConfigurator) == creditFactory,
            "Factory must be authorized for new configurator"
        );
        assertTrue(
            IMarketConfigurator(marketConfigurator).getAuthorizedFactory(address(creditConfigurator)) == address(0),
            "Factory must be unauthorized for old configurator"
        );
    }

    function test_CS_08_upgradeCreditFacade() public {
        address bytecodeRepository =
            IAddressProvider(addressProvider).getAddressOrRevert(AP_BYTECODE_REPOSITORY, NO_VERSION_CONTROL);

        CreditFacadeParams memory params =
            CreditFacadeParams({degenNFT: address(0), expirable: true, migrateBotList: true});

        address contractsRegister = marketConfigurator.contractsRegister();
        address lossPolicy = IContractsRegister(contractsRegister).getLossPolicy(address(pool));
        address oldFacade = ICreditManagerV3(creditManager).creditFacade();

        // Compute expected new facade address
        address expectedNewFacade = IBytecodeRepository(bytecodeRepository).computeAddress(
            "CREDIT_FACADE",
            3_10,
            abi.encode(
                addressProvider,
                address(creditManager),
                lossPolicy,
                ICreditFacadeV3(oldFacade).botList(),
                WETH,
                params.degenNFT,
                params.expirable
            ),
            bytes32(bytes20(address(marketConfigurator))),
            creditFactory
        );

        // Expect factory authorization/unauthorized and facade upgrade
        vm.expectCall(
            address(marketConfigurator),
            abi.encodeCall(IMarketConfigurator.unauthorizeFactory, (creditFactory, address(creditManager), oldFacade))
        );
        vm.expectCall(
            address(marketConfigurator),
            abi.encodeCall(
                IMarketConfigurator.authorizeFactory, (creditFactory, address(creditManager), expectedNewFacade)
            )
        );
        vm.expectCall(
            address(creditConfigurator),
            abi.encodeCall(ICreditConfiguratorV3.setCreditFacade, (expectedNewFacade, true))
        );

        vm.prank(admin);
        marketConfigurator.configureCreditSuite(
            address(creditManager), abi.encodeCall(ICreditConfigureActions.upgradeCreditFacade, (params))
        );

        // Verify facade was upgraded and factory authorization was transferred
        assertEq(ICreditManagerV3(creditManager).creditFacade(), expectedNewFacade, "Credit facade must be upgraded");
        assertTrue(
            IMarketConfigurator(marketConfigurator).getAuthorizedFactory(expectedNewFacade) == creditFactory,
            "Factory must be authorized for new facade"
        );
        assertTrue(
            IMarketConfigurator(marketConfigurator).getAuthorizedFactory(oldFacade) == address(0),
            "Factory must be unauthorized for old facade"
        );

        // Verify it reverts when trying to use unregistered degenNFT
        params.degenNFT = address(1);
        vm.expectRevert(abi.encodeWithSelector(CreditFactory.DegenNFTIsNotRegisteredException.selector, address(1)));
        vm.prank(admin);
        marketConfigurator.configureCreditSuite(
            address(creditManager), abi.encodeCall(ICreditConfigureActions.upgradeCreditFacade, (params))
        );
    }

    function test_CS_09_configureAdapter() public {
        _addUSDC();

        vm.prank(admin);
        marketConfigurator.configureCreditSuite(
            address(creditManager), abi.encodeCall(ICreditConfigureActions.addCollateralToken, (USDC, 8000))
        );

        // First deploy Uniswap V3 adapter
        DeployParams memory params = DeployParams({
            postfix: "UNISWAP_V3_ROUTER",
            salt: 0,
            constructorParams: abi.encode(address(creditManager), target)
        });

        vm.prank(admin);
        marketConfigurator.configureCreditSuite(
            address(creditManager), abi.encodeCall(ICreditConfigureActions.allowAdapter, (params))
        );

        address adapter = ICreditManagerV3(creditManager).contractToAdapter(target);

        // Configure pool status
        UniswapV3PoolStatus[] memory pools = new UniswapV3PoolStatus[](1);
        pools[0] = UniswapV3PoolStatus({token0: WETH, token1: USDC, fee: 500, allowed: true});

        vm.expectCall(adapter, abi.encodeCall(IUniswapV3Adapter.setPoolStatusBatch, (pools)));

        vm.prank(admin);
        marketConfigurator.configureCreditSuite(
            address(creditManager),
            abi.encodeCall(
                ICreditConfigureActions.configureAdapterFor,
                (target, abi.encodeCall(IUniswapV3Adapter.setPoolStatusBatch, (pools)))
            )
        );

        // Verify pool was allowed
        assertTrue(IUniswapV3Adapter(adapter).isPoolAllowed(WETH, USDC, 500), "Pool must be allowed");

        // Verify it reverts when trying to configure non-existent adapter
        address nonExistentTarget = address(1);
        vm.expectRevert(
            abi.encodeWithSelector(CreditFactory.TargetContractIsNotAllowedException.selector, nonExistentTarget)
        );
        vm.prank(admin);
        marketConfigurator.configureCreditSuite(
            address(creditManager),
            abi.encodeCall(
                ICreditConfigureActions.configureAdapterFor,
                (nonExistentTarget, abi.encodeCall(IUniswapV3Adapter.setPoolStatusBatch, (pools)))
            )
        );
    }

    function test_CS_10_pause_unpause() public {
        vm.startPrank(admin);

        // Expect call to creditFacade.pause
        vm.expectCall(address(creditFacade), abi.encodeCall(ICreditFacadeV3.pause, ()));

        marketConfigurator.configureCreditSuite(
            address(creditManager), abi.encodeCall(ICreditConfigureActions.pause, ())
        );

        assertTrue(Pausable(address(creditFacade)).paused(), "Credit facade must be paused");

        vm.expectCall(address(creditFacade), abi.encodeCall(ICreditFacadeV3.unpause, ()));

        marketConfigurator.configureCreditSuite(
            address(creditManager), abi.encodeCall(ICreditConfigureActions.unpause, ())
        );
        vm.stopPrank();

        assertFalse(Pausable(address(creditFacade)).paused(), "Credit facade must be unpaused");
    }

    /// EMERGENCY CONFIGURATION TESTS ///

    function test_CS_11_emergency_forbidAdapter() public {
        DeployParams memory params = DeployParams({
            postfix: "BALANCER_VAULT",
            salt: 0,
            constructorParams: abi.encode(address(creditManager), target)
        });

        vm.prank(admin);
        marketConfigurator.configureCreditSuite(
            address(creditManager), abi.encodeCall(ICreditConfigureActions.allowAdapter, (params))
        );

        address adapter = ICreditManagerV3(creditManager).contractToAdapter(target);

        vm.expectCall(address(creditConfigurator), abi.encodeCall(ICreditConfiguratorV3.forbidAdapter, (adapter)));

        vm.prank(emergencyAdmin);
        marketConfigurator.emergencyConfigureCreditSuite(
            address(creditManager), abi.encodeCall(ICreditEmergencyConfigureActions.forbidAdapter, (adapter))
        );

        assertEq(ICreditManagerV3(creditManager).contractToAdapter(target), address(0), "Adapter must be forbidden");
    }

    function test_CS_12_emergency_forbidToken() public {
        _addUSDC();

        address token = USDC;
        uint16 liquidationThreshold = 8000;

        vm.prank(admin);
        marketConfigurator.configureCreditSuite(
            address(creditManager),
            abi.encodeCall(ICreditConfigureActions.addCollateralToken, (token, liquidationThreshold))
        );

        vm.expectCall(address(creditConfigurator), abi.encodeCall(ICreditConfiguratorV3.forbidToken, (token)));

        vm.prank(emergencyAdmin);
        marketConfigurator.emergencyConfigureCreditSuite(
            address(creditManager), abi.encodeCall(ICreditEmergencyConfigureActions.forbidToken, (token))
        );

        assertTrue(
            ICreditFacadeV3(creditFacade).forbiddenTokenMask()
                & ICreditManagerV3(creditManager).getTokenMaskOrRevert(token) != 0,
            "Token must be forbidden"
        );
    }

    function test_CS_13_emergency_forbidBorrowing() public {
        vm.expectCall(address(creditConfigurator), abi.encodeCall(ICreditConfiguratorV3.forbidBorrowing, ()));

        vm.prank(emergencyAdmin);
        marketConfigurator.emergencyConfigureCreditSuite(
            address(creditManager), abi.encodeCall(ICreditEmergencyConfigureActions.forbidBorrowing, ())
        );

        assertEq(ICreditFacadeV3(creditFacade).maxDebtPerBlockMultiplier(), 0, "Borrowing must be forbidden");
    }

    function test_CS_14_emergency_pause() public {
        vm.expectCall(address(creditFacade), abi.encodeCall(ICreditFacadeV3.pause, ()));

        vm.prank(emergencyAdmin);
        marketConfigurator.emergencyConfigureCreditSuite(
            address(creditManager), abi.encodeCall(ICreditEmergencyConfigureActions.pause, ())
        );

        assertTrue(Pausable(address(creditFacade)).paused(), "Credit facade must be paused");
    }
}
