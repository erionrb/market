// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {LendingMarket} from "../src/LendingMarket.sol";
import {TransparentUpgradeableProxy} from "../src/TransparentUpgradeableProxy.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {FeeOnTransferERC20} from "../src/mocks/FeeOnTransferERC20.sol";
import {MockOracle} from "../src/mocks/MockOracle.sol";

contract FeeOnTransferCollateralTest is Test {
    uint256 internal constant RATE_PER_SECOND = uint256(0.05e18) / 365 days;
    uint256 internal constant FEE_BPS = 200; // 200 bps as per defined at Deploy.s.sol

    address internal admin = makeAddr("admin");
    address internal guardian = makeAddr("guardian");
    address internal borrower = makeAddr("borrower");
    address internal supplier = makeAddr("supplier");
    address internal liquidator = makeAddr("liquidator");

    MockERC20 internal base;
    FeeOnTransferERC20 internal strm;

    MockOracle internal strmOracle;
    MockOracle internal baseOracle;

    LendingMarket internal market;
    LendingMarket internal feeBaseMarket;

    function setUp() public {
        base = new MockERC20("Base USD", "bUSD", 18);
        strm = new FeeOnTransferERC20("Stream Reward", "STRM", FEE_BPS);
        strmOracle = new MockOracle(5e18);
        baseOracle = new MockOracle(5e18);

        LendingMarket lendingMarket = new LendingMarket();

        bytes memory data = abi.encodeCall(
            LendingMarket.initialize,
            (
                admin,
                guardian,
                address(strmOracle),
                address(base),
                address(strm),
                0.50e18,
                1.15e18,
                RATE_PER_SECOND
            )
        );

        market = LendingMarket(
            address(
                new TransparentUpgradeableProxy(
                    address(lendingMarket),
                    admin,
                    data
                )
            )
        );

        bytes memory feeBaseData = abi.encodeCall(
            LendingMarket.initialize,
            (
                admin,
                guardian,
                address(baseOracle),
                address(strm),
                address(base),
                0.50e18,
                1.15e18,
                RATE_PER_SECOND
            )
        );

        feeBaseMarket = LendingMarket(
            address(
                new TransparentUpgradeableProxy(
                    address(lendingMarket),
                    admin,
                    feeBaseData
                )
            )
        );
    }

    function test_collateralMatchTokensReceived() public {
        uint256 amount = 100e18;
        uint256 expectedAmount = amount - (amount * FEE_BPS) / 10_000;

        strm.mint(borrower, amount);

        vm.startPrank(borrower);

        strm.approve(address(market), type(uint256).max);
        market.supplyCollateral(amount);

        vm.stopPrank();

        assertEq(
            strm.balanceOf(address(market)),
            expectedAmount,
            "received 98"
        );

        assertEq(
            market.collateralBalance(borrower),
            expectedAmount,
            "credited more than received"
        );

        assertEq(
            market.totalCollateral(),
            strm.balanceOf(address(market)),
            "collateral is not backed"
        );
    }

    function test_baseMatchTokensReceived() public {
        uint256 amount = 100e18;
        uint256 expectedAmount = amount - (amount * FEE_BPS) / 10_000;

        strm.mint(supplier, amount);

        vm.startPrank(supplier);

        strm.approve(address(feeBaseMarket), type(uint256).max);
        feeBaseMarket.supply(amount);

        vm.stopPrank();

        assertEq(
            strm.balanceOf(address(feeBaseMarket)),
            expectedAmount,
            "received 98"
        );

        assertEq(
            feeBaseMarket.supplyBalanceOf(supplier),
            expectedAmount,
            "credited more than received"
        );

        assertEq(
            feeBaseMarket.presentValueSupply(feeBaseMarket.totalSupplyPrincipal()),
            strm.balanceOf(address(feeBaseMarket)),
            "supply is not backed"
        );
    }

    function test_repayMatchTokensReceived() public {
        uint256 amount = 50e18;
        uint256 expectedAmount = amount - (amount * FEE_BPS) / 10_000;

        strm.mint(supplier, 200e18);

        vm.startPrank(supplier);
        strm.approve(address(feeBaseMarket), type(uint256).max);
        feeBaseMarket.supply(200e18);
        vm.stopPrank();

        base.mint(borrower, 100e18);

        vm.startPrank(borrower);

        base.approve(address(feeBaseMarket), type(uint256).max);
        strm.approve(address(feeBaseMarket), type(uint256).max);

        feeBaseMarket.supplyCollateral(100e18);
        feeBaseMarket.borrow(100e18);

        uint256 debtBefore = feeBaseMarket.borrowBalanceOf(borrower);
        uint256 balanceBefore = strm.balanceOf(address(feeBaseMarket));

        feeBaseMarket.repay(amount);

        vm.stopPrank();

        assertEq(
            strm.balanceOf(address(feeBaseMarket)) - balanceBefore,
            expectedAmount,
            "received 49"
        );

        assertEq(
            debtBefore - feeBaseMarket.borrowBalanceOf(borrower),
            expectedAmount,
            "debt cleared beyond what was received"
        );

        assertEq(
            feeBaseMarket.presentValueSupply(feeBaseMarket.totalSupplyPrincipal())
                - feeBaseMarket.presentValueBorrow(feeBaseMarket.totalBorrowPrincipal()),
            strm.balanceOf(address(feeBaseMarket)),
            "base is not backed"
        );
    }

    function test_liquidateMatchTokensReceived() public {
        uint256 amount = 50e18;
        uint256 expectedAmount = amount - (amount * FEE_BPS) / 10_000;

        strm.mint(supplier, 400e18);

        vm.startPrank(supplier);
        strm.approve(address(feeBaseMarket), type(uint256).max);
        feeBaseMarket.supply(400e18);
        vm.stopPrank();

        base.mint(borrower, 100e18);

        vm.startPrank(borrower);
        base.approve(address(feeBaseMarket), type(uint256).max);
        feeBaseMarket.supplyCollateral(100e18);
        feeBaseMarket.borrow(200e18);
        vm.stopPrank();

        baseOracle.setPrice(3e18);
        assertFalse(feeBaseMarket.isHealthy(borrower), "borrower should be liquidatable");

        strm.mint(liquidator, amount);

        uint256 debtBefore = feeBaseMarket.borrowBalanceOf(borrower);
        uint256 balanceBefore = strm.balanceOf(address(feeBaseMarket));

        vm.startPrank(liquidator);

        strm.approve(address(feeBaseMarket), type(uint256).max);
        feeBaseMarket.liquidate(borrower, amount);

        vm.stopPrank();

        assertEq(
            strm.balanceOf(address(feeBaseMarket)) - balanceBefore,
            expectedAmount,
            "received 49"
        );

        assertEq(
            debtBefore - feeBaseMarket.borrowBalanceOf(borrower),
            expectedAmount,
            "debt cleared beyond what was received"
        );

        assertEq(
            feeBaseMarket.presentValueSupply(feeBaseMarket.totalSupplyPrincipal())
                - feeBaseMarket.presentValueBorrow(feeBaseMarket.totalBorrowPrincipal()),
            strm.balanceOf(address(feeBaseMarket)),
            "base is not backed"
        );
    }
}
