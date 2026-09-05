// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {LendingMarket} from "../src/LendingMarket.sol";
import {TransparentUpgradeableProxy} from "../src/TransparentUpgradeableProxy.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockOracle} from "../src/mocks/MockOracle.sol";

/**
 * @notice Reserve-factor behaviour. Covers the unit cases and the solvency invariant from
 *         docs/discovery/reserve-factor.md (sections 7 and 8).
 */
contract ReserveFactorTest is Test {
    uint256 internal constant FACTOR = 1e18;
    uint256 internal constant RATE_PER_SECOND = uint256(0.05e18) / 365 days;

    address internal admin = makeAddr("admin");
    address internal guardian = makeAddr("guardian");
    address internal supplier = makeAddr("supplier");
    address internal borrower = makeAddr("borrower");
    address internal recipient = makeAddr("recipient");

    MockERC20 internal base;
    MockERC20 internal weth;
    MockOracle internal wethOracle;

    LendingMarket internal market;

    event ReserveFactorSet(uint256 reserveFactor);
    event ReservesWithdrawn(address indexed recipient, uint256 amount);

    function setUp() public {
        base = new MockERC20("Base USD", "bUSD", 18);
        weth = new MockERC20("Wrapped Ether", "WETH", 18);
        wethOracle = new MockOracle(2_000e18);

        market = _deployMarket();

        base.mint(supplier, 1_000_000e18);
        vm.startPrank(supplier);
        base.approve(address(market), type(uint256).max);
        market.supply(1_000_000e18);
        vm.stopPrank();
    }

    function _deployMarket() internal returns (LendingMarket) {
        LendingMarket impl = new LendingMarket();
        bytes memory initData = abi.encodeCall(
            LendingMarket.initialize,
            (admin, guardian, address(wethOracle), address(base), address(weth), 0.80e18, 1.10e18, RATE_PER_SECOND)
        );
        return LendingMarket(address(new TransparentUpgradeableProxy(address(impl), admin, initData)));
    }

    function _postCollateral(address who, uint256 amount) internal {
        weth.mint(who, amount);
        vm.startPrank(who);
        weth.approve(address(market), type(uint256).max);
        market.supplyCollateral(amount);
        vm.stopPrank();
    }

    function _openBorrow(uint256 amount) internal {
        _postCollateral(borrower, 1_000e18); // 2,000,000 collateral value, ample power
        vm.prank(borrower);
        market.borrow(amount);
    }

    // --- defaults -------------------------------------------------------------------------

    function test_reserveFactorDefaultsToZero() public view {
        assertEq(market.reserveFactor(), 0);
        assertEq(market.reserves(), 0);
    }

    function test_factorZeroDoesNotWriteReserves() public {
        _openBorrow(100_000e18);
        for (uint256 i; i < 5; ++i) {
            vm.warp(block.timestamp + 30 days);
            market.accrueInterest();
        }
        assertEq(market.reserves(), 0);
    }

    // --- setReserveFactor --------------------------------------------------------------------

    function test_setReserveFactorRejectsAboveOne() public {
        vm.prank(admin);
        vm.expectRevert("reserve factor too high");
        market.setReserveFactor(FACTOR + 1);

        vm.prank(admin);
        market.setReserveFactor(FACTOR); // exactly 1e18 is allowed
        assertEq(market.reserveFactor(), FACTOR);
    }

    function test_setReserveFactorOnlyAdmin() public {
        vm.prank(guardian);
        vm.expectRevert("not admin");
        market.setReserveFactor(0.1e18);

        vm.prank(supplier);
        vm.expectRevert("not admin");
        market.setReserveFactor(0.1e18);
    }

    function test_setReserveFactorWorksWhilePaused() public {
        vm.prank(guardian);
        market.setPaused(true);

        vm.prank(admin);
        market.setReserveFactor(0.2e18);
        assertEq(market.reserveFactor(), 0.2e18);
    }

    function test_setReserveFactorEmitsEvent() public {
        vm.expectEmit(false, false, false, true, address(market));
        emit ReserveFactorSet(0.3e18);
        vm.prank(admin);
        market.setReserveFactor(0.3e18);
    }

    function test_setReserveFactorAccruesUnderOldFactorFirst() public {
        _openBorrow(100_000e18);
        vm.warp(block.timestamp + 365 days);

        // factor is still 0 while this interest window accrues => reserves stay 0,
        // the whole window goes to suppliers, and only *future* interest is split.
        vm.prank(admin);
        market.setReserveFactor(0.5e18);

        assertEq(market.reserves(), 0);
    }

    // --- accrual split ---------------------------------------------------------------------

    function test_reserveAccruesShareOfBorrowerInterest() public {
        vm.prank(admin);
        market.setReserveFactor(0.1e18);

        _openBorrow(100_000e18);

        uint256 supplyBefore = market.supplyBalanceOf(supplier);

        uint256 interest = market.borrowRatePerSecond() * 365 days;
        uint256 borrowsBefore = market.presentValueBorrow(market.totalBorrowPrincipal());
        uint256 borrowerInterest = (borrowsBefore * interest) / FACTOR;
        uint256 expectedReserve = (borrowerInterest * 0.1e18) / FACTOR;

        vm.warp(block.timestamp + 365 days);
        market.accrueInterest();

        assertEq(market.reserves(), expectedReserve);

        // suppliers get the remaining ~90%
        uint256 supplierGain = market.supplyBalanceOf(supplier) - supplyBefore;
        assertApproxEqAbs(supplierGain, borrowerInterest - expectedReserve, 2);
    }

    function test_factorOneSendsAllInterestToReserves() public {
        vm.prank(admin);
        market.setReserveFactor(FACTOR);

        _openBorrow(100_000e18);

        uint256 supplyIndexBefore = market.baseSupplyIndex();
        uint256 supplyBefore = market.supplyBalanceOf(supplier);

        vm.warp(block.timestamp + 365 days);
        market.accrueInterest();

        assertEq(market.baseSupplyIndex(), supplyIndexBefore); // frozen
        assertEq(market.supplyBalanceOf(supplier), supplyBefore); // suppliers earn nothing
        assertGt(market.reserves(), 0);
    }

    function test_borrowersUnaffectedByReserveFactor() public {
        // A parallel market with a non-zero factor must charge borrowers identically.
        LendingMarket other = _deployMarket();
        base.mint(supplier, 1_000_000e18);
        vm.startPrank(supplier);
        base.approve(address(other), type(uint256).max);
        other.supply(1_000_000e18);
        vm.stopPrank();

        vm.prank(admin);
        other.setReserveFactor(0.4e18);

        weth.mint(borrower, 2_000e18);
        vm.startPrank(borrower);
        weth.approve(address(market), type(uint256).max);
        weth.approve(address(other), type(uint256).max);
        market.supplyCollateral(1_000e18);
        other.supplyCollateral(1_000e18);
        market.borrow(100_000e18);
        other.borrow(100_000e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 200 days);
        market.accrueInterest();
        other.accrueInterest();

        assertEq(other.baseBorrowIndex(), market.baseBorrowIndex());
        assertEq(other.borrowBalanceOf(borrower), market.borrowBalanceOf(borrower));
    }

    function test_reserveSplitConservesBorrowerInterest() public {
        vm.prank(admin);
        market.setReserveFactor(0.333333333333333333e18); // odd factor => truncation

        _openBorrow(123_457e18);

        uint256 interest = market.borrowRatePerSecond() * 111 days;
        uint256 borrowsBefore = market.presentValueBorrow(market.totalBorrowPrincipal());
        uint256 borrowerInterest = (borrowsBefore * interest) / FACTOR;
        uint256 reserveAccrued = (borrowerInterest * market.reserveFactor()) / FACTOR;

        uint256 supplyBefore = market.supplyBalanceOf(supplier);

        vm.warp(block.timestamp + 111 days);
        market.accrueInterest();

        uint256 supplierGain = market.supplyBalanceOf(supplier) - supplyBefore;

        // reserve share is the exact floor(borrowerInterest * r / 1e18)
        assertEq(market.reserves(), reserveAccrued);
        // suppliers get the remainder; the protocol never over-credits suppliers
        assertLe(supplierGain, borrowerInterest - reserveAccrued);
        // the only shortfall is pre-existing supply-index truncation dust (<1e-12 relative)
        assertApproxEqRel(supplierGain + reserveAccrued, borrowerInterest, 1e6);
    }

    function test_reservesAccrueWithZeroSuppliers() public {
        vm.prank(admin);
        market.setReserveFactor(0.25e18);

        _openBorrow(100_000e18);

        // top up liquidity from outside so the supplier can exit while the borrow stays open
        base.mint(address(market), 100_000e18);

        // supplier exits entirely; a borrow is still open, so suppliesBefore == 0 next accrual
        uint256 supplierBal = market.supplyBalanceOf(supplier);
        vm.prank(supplier);
        market.withdraw(supplierBal);
        assertEq(market.totalSupplyPrincipal(), 0);
        assertGt(market.totalBorrowPrincipal(), 0);

        uint256 supplyIndexBefore = market.baseSupplyIndex();

        vm.warp(block.timestamp + 60 days);
        market.accrueInterest();

        assertGt(market.reserves(), 0);
        assertEq(market.baseSupplyIndex(), supplyIndexBefore); // supply index still guarded
    }

    function test_reservesEarnNothing() public {
        vm.prank(admin);
        market.setReserveFactor(0.5e18);

        _openBorrow(100_000e18);
        vm.warp(block.timestamp + 90 days);
        market.accrueInterest();
        uint256 snap = market.reserves();
        assertGt(snap, 0);

        // clear all debt, then let time pass: reserves are a flat accumulator
        base.mint(borrower, 1_000_000e18);
        vm.startPrank(borrower);
        base.approve(address(market), type(uint256).max);
        market.repay(type(uint256).max);
        vm.stopPrank();

        vm.warp(block.timestamp + 3650 days);
        market.accrueInterest();
        assertEq(market.reserves(), snap);
    }

    function test_reservesViewIsStaleBetweenAccruals() public {
        vm.prank(admin);
        market.setReserveFactor(0.3e18);
        _openBorrow(100_000e18);

        vm.warp(block.timestamp + 100 days);
        assertEq(market.reserves(), 0); // not yet accrued

        market.accrueInterest();
        assertGt(market.reserves(), 0);
    }

    // --- withdrawReserves ----------------------------------------------------------------

    function _accrueSomeReserves() internal returns (uint256) {
        vm.prank(admin);
        market.setReserveFactor(0.5e18);
        _openBorrow(100_000e18);
        vm.warp(block.timestamp + 365 days);
        market.accrueInterest();
        return market.reserves();
    }

    function test_withdrawReservesTransfersAndReduces() public {
        uint256 r = _accrueSomeReserves();
        assertGt(r, 0);

        vm.prank(admin);
        market.withdrawReserves(recipient, r);

        assertEq(market.reserves(), 0);
        assertEq(base.balanceOf(recipient), r);
    }

    function test_withdrawReservesPartial() public {
        uint256 r = _accrueSomeReserves();
        vm.prank(admin);
        market.withdrawReserves(recipient, r / 3);
        assertEq(market.reserves(), r - r / 3);
        assertEq(base.balanceOf(recipient), r / 3);
    }

    function test_withdrawReservesRejectsAboveReserves() public {
        uint256 r = _accrueSomeReserves();
        vm.prank(admin);
        vm.expectRevert("amount exceeds reserves");
        market.withdrawReserves(recipient, r + 1);
    }

    function test_withdrawReservesRejectsAboveLiquidity() public {
        vm.prank(admin);
        market.setReserveFactor(0.5e18);

        // borrow out essentially all cash, then accrue a large reserve claim
        _postCollateral(borrower, 10_000e18);
        vm.prank(borrower);
        market.borrow(999_000e18);

        vm.warp(block.timestamp + 365 days);
        market.accrueInterest();

        uint256 cash = base.balanceOf(address(market));
        uint256 r = market.reserves();
        assertGt(r, cash);

        vm.prank(admin);
        vm.expectRevert("insufficient liquidity");
        market.withdrawReserves(recipient, cash + 1);
    }

    function test_withdrawReservesOnlyAdmin() public {
        _accrueSomeReserves();
        vm.prank(guardian);
        vm.expectRevert("not admin");
        market.withdrawReserves(recipient, 1);
    }

    function test_withdrawReservesWorksWhilePaused() public {
        uint256 r = _accrueSomeReserves();
        vm.prank(guardian);
        market.setPaused(true);

        vm.prank(admin);
        market.withdrawReserves(recipient, r);
        assertEq(base.balanceOf(recipient), r);
    }

    function test_withdrawReservesEmitsEvent() public {
        uint256 r = _accrueSomeReserves();
        vm.expectEmit(true, false, false, true, address(market));
        emit ReservesWithdrawn(recipient, r);
        vm.prank(admin);
        market.withdrawReserves(recipient, r);
    }

    function test_withdrawReservesAccruesFirst() public {
        vm.prank(admin);
        market.setReserveFactor(0.5e18);
        _openBorrow(100_000e18);
        vm.warp(block.timestamp + 365 days);
        // reserves() still 0 here; the call must accrue then let us pull the freshly accrued amount
        uint256 interest = market.borrowRatePerSecond() * 365 days;
        uint256 borrowsBefore = market.presentValueBorrow(market.totalBorrowPrincipal());
        uint256 expected = ((borrowsBefore * interest) / FACTOR) * 0.5e18 / FACTOR;

        vm.prank(admin);
        market.withdrawReserves(recipient, expected);
        assertEq(base.balanceOf(recipient), expected);
        assertEq(market.reserves(), 0);
    }
}

/* --------------------------------------------------------------------------------------------
 * Solvency invariant (docs/discovery/reserve-factor.md section 8)
 * ------------------------------------------------------------------------------------------ */

contract ReserveFactorHandler is Test {
    LendingMarket public market;
    MockERC20 public base;
    MockERC20 public weth;
    address public admin;

    address[3] public actors = [makeAddr("a0"), makeAddr("a1"), makeAddr("a2")];

    uint256 public reservesSnapshot;
    bool public reservesDropWasWithdraw;

    constructor(LendingMarket _market, MockERC20 _base, MockERC20 _weth, address _admin) {
        market = _market;
        base = _base;
        weth = _weth;
        admin = _admin;

        for (uint256 i; i < actors.length; ++i) {
            address a = actors[i];
            weth.mint(a, 1_000_000e18);
            vm.startPrank(a);
            weth.approve(address(market), type(uint256).max);
            base.approve(address(market), type(uint256).max);
            market.supplyCollateral(500_000e18);
            vm.stopPrank();
        }
        reservesSnapshot = market.reserves();
    }

    function _actor(uint256 seed) internal view returns (address) {
        return actors[seed % actors.length];
    }

    function _preOp() internal {
        reservesSnapshot = market.reserves();
        reservesDropWasWithdraw = false;
    }

    function _postOp() internal view {
        if (market.reserves() < reservesSnapshot) {
            require(reservesDropWasWithdraw, "reserves dropped outside withdrawReserves");
        }
    }

    function warp(uint256 dt) external {
        _preOp();
        vm.warp(block.timestamp + bound(dt, 0, 45 days));
        market.accrueInterest();
        _postOp();
    }

    function setReserveFactor(uint256 f) external {
        _preOp();
        vm.prank(admin);
        market.setReserveFactor(bound(f, 0, 1e18));
        _postOp();
    }

    function supply(uint256 seed, uint256 amt) external {
        _preOp();
        address a = _actor(seed);
        amt = bound(amt, 1e18, 200_000e18);
        base.mint(a, amt);
        vm.prank(a);
        market.supply(amt);
        _postOp();
    }

    function withdraw(uint256 seed, uint256 amt) external {
        _preOp();
        address a = _actor(seed);
        uint256 bal = market.supplyBalanceOf(a);
        uint256 cash = base.balanceOf(address(market));
        uint256 cap = bal < cash ? bal : cash;
        if (cap == 0) return;
        vm.prank(a);
        market.withdraw(bound(amt, 1, cap));
        _postOp();
    }

    function borrow(uint256 seed, uint256 amt) external {
        _preOp();
        address a = _actor(seed);
        uint256 cash = base.balanceOf(address(market));
        if (cash == 0) return;
        // stay well within borrowing power: 500k collateral * 2000 * 0.8 = huge; cap by cash
        uint256 cap = cash / 4;
        if (cap == 0) return;
        vm.prank(a);
        market.borrow(bound(amt, 1, cap));
        _postOp();
    }

    function repay(uint256 seed, uint256 amt) external {
        _preOp();
        address a = _actor(seed);
        uint256 owed = market.borrowBalanceOf(a);
        if (owed == 0) return;
        uint256 pay = bound(amt, 1, owed);
        base.mint(a, pay);
        vm.prank(a);
        market.repay(pay);
        _postOp();
    }

    function withdrawReserves(uint256 amt) external {
        _preOp();
        uint256 r = market.reserves();
        uint256 cash = base.balanceOf(address(market));
        uint256 cap = r < cash ? r : cash;
        if (cap == 0) return;
        reservesDropWasWithdraw = true;
        vm.prank(admin);
        market.withdrawReserves(admin, bound(amt, 1, cap));
        _postOp();
    }
}

contract ReserveFactorInvariantTest is Test {
    uint256 internal constant RATE_PER_SECOND = uint256(0.05e18) / 365 days;

    address internal admin = makeAddr("admin");
    address internal guardian = makeAddr("guardian");

    MockERC20 internal base;
    MockERC20 internal weth;
    MockOracle internal wethOracle;
    LendingMarket internal market;
    ReserveFactorHandler internal handler;

    function setUp() public {
        base = new MockERC20("Base USD", "bUSD", 18);
        weth = new MockERC20("Wrapped Ether", "WETH", 18);
        wethOracle = new MockOracle(2_000e18);

        LendingMarket impl = new LendingMarket();
        bytes memory initData = abi.encodeCall(
            LendingMarket.initialize,
            (admin, guardian, address(wethOracle), address(base), address(weth), 0.80e18, 1.10e18, RATE_PER_SECOND)
        );
        market = LendingMarket(address(new TransparentUpgradeableProxy(address(impl), admin, initData)));

        address seedSupplier = makeAddr("seedSupplier");
        base.mint(seedSupplier, 2_000_000e18);
        vm.startPrank(seedSupplier);
        base.approve(address(market), type(uint256).max);
        market.supply(2_000_000e18);
        vm.stopPrank();

        vm.prank(admin);
        market.setReserveFactor(0.15e18);

        handler = new ReserveFactorHandler(market, base, weth, admin);
        targetContract(address(handler));
    }

    /// @notice Cash + all debt owed to the market covers supplier claims plus the reserve claim.
    function invariant_protocolSolvency() public view {
        uint256 cash = base.balanceOf(address(market));
        uint256 borrows = market.presentValueBorrow(market.totalBorrowPrincipal());
        uint256 supplies = market.presentValueSupply(market.totalSupplyPrincipal());
        uint256 reserves = market.reserves();

        // small tolerance for pre-existing index/principal truncation dust
        assertGe(cash + borrows + 1e6, supplies + reserves);
    }
}
