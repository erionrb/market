// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";

import {LendingMarket} from "../src/LendingMarket.sol";
import {TransparentUpgradeableProxy} from "../src/TransparentUpgradeableProxy.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockOracle} from "../src/mocks/MockOracle.sol";

contract LiquidationPricingTest is Test {
    uint256 internal constant FACTOR = 1e18;
    uint256 internal constant RATE_PER_SECOND = uint256(0.05e18) / 365 days;

    address internal admin = makeAddr("admin");
    address internal guardian = makeAddr("guardian");
    address internal supplier = makeAddr("supplier");
    address internal borrower = makeAddr("borrower");
    address internal liquidator = makeAddr("liquidator");

    MockERC20 internal base;
    MockERC20 internal weth;
    MockOracle internal wethOracle;

    LendingMarket internal market;

    function setUp() public {
        base = new MockERC20("Base USD", "bUSD", 18);
        weth = new MockERC20("Wrapped Ether", "WETH", 18);
        wethOracle = new MockOracle(2_000e18);

        LendingMarket impl = new LendingMarket();
        bytes memory initData = abi.encodeCall(
            LendingMarket.initialize,
            (
                admin,
                guardian,
                address(wethOracle),
                address(base),
                address(weth),
                0.80e18,
                1.10e18,
                RATE_PER_SECOND
            )
        );
        market = LendingMarket(
            address(
                new TransparentUpgradeableProxy(address(impl), admin, initData)
            )
        );

        base.mint(supplier, 1_000_000e18);
        vm.startPrank(supplier);
        base.approve(address(market), type(uint256).max);
        market.supply(1_000_000e18);
        vm.stopPrank();
    }

    function test_seizeAmountIgnoresCollateralPrice() public {
        // isHealthy() at 2000:
        // collateralValue = 100 * 2_000 / 1 = 200000
        // borrowingPower = 200000 * 0.80 / 1 = 160000
        // 160000 covers the 150000 borrow, so this opens healthy.
        weth.mint(borrower, 100e18);
        vm.startPrank(borrower);
        weth.approve(address(market), type(uint256).max);
        market.supplyCollateral(100e18);
        market.borrow(150_000e18);
        vm.stopPrank();

        // isHealthy() at 1800:
        // collateralValue = 100 * 1_800 / 1 = 180000
        // borrowingPower = 180000 * 0.80 / 1 = 144000
        // 144000 no longer covers the 150000 owed, so this turns unhealthy.
        wethOracle.setPrice(1_800e18);
        assertFalse(market.isHealthy(borrower));

        uint256 repayAmount = 1_000e18;

        // liquidator is paying 1000 bUSD and the incentive is 10% => 1100
        // 1 wETH == 1,800 bUSD => 1100 / 1800 = 0.611 WETH (expected amount)
        uint256 expectedSeize = (repayAmount * market.liquidationIncentive()) /
            market.getPrice();

        base.mint(liquidator, repayAmount);

        vm.startPrank(liquidator);
        base.approve(address(market), type(uint256).max);
        market.liquidate(borrower, repayAmount);
        vm.stopPrank();

        uint256 currentSeize = weth.balanceOf(liquidator);

        console2.log("repaid:", repayAmount);
        console2.log("expected seize:", expectedSeize);
        console2.log("actual seize:", currentSeize);
        console2.log(
            "value seized:",
            (currentSeize * market.getPrice()) / FACTOR
        );

        assertEq(currentSeize, expectedSeize);
    }

    // Fuzz: whatever the liquidator repays, the collateral they walk away with
    // must not be worth more than their repayment plus the incentive. The bug
    // (dividing by FACTOR instead of the price) breaks this for any price != 1e18.
    function testFuzz_seizedValueNeverExceedsRepayPlusIncentive(uint256 repayAmount) public {
        weth.mint(borrower, 100e18);
        vm.startPrank(borrower);
        weth.approve(address(market), type(uint256).max);
        market.supplyCollateral(100e18);
        market.borrow(150_000e18);
        vm.stopPrank();

        wethOracle.setPrice(1_800e18);
        assertFalse(market.isHealthy(borrower));

        repayAmount = bound(repayAmount, 1e18, 150_000e18);
        base.mint(liquidator, repayAmount);

        vm.startPrank(liquidator);
        base.approve(address(market), type(uint256).max);
        market.liquidate(borrower, repayAmount);
        vm.stopPrank();

        uint256 seizedValue = (weth.balanceOf(liquidator) * market.getPrice()) / FACTOR;
        uint256 maxValue = (repayAmount * market.liquidationIncentive()) / FACTOR;

        assertLe(seizedValue, maxValue, "seized collateral worth more than repay + incentive");
    }
}
