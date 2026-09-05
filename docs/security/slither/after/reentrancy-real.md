**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
 - [reentrancy-no-eth](#reentrancy-no-eth) (3 results) (Medium)
## reentrancy-no-eth
Impact: Medium
Confidence: Medium
 - [ ] ID-0
Reentrancy in [LendingMarket.repay(uint256)](src/LendingMarket.sol#L246-L265):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L254)
	State variables written after the call(s):
	- [borrowPrincipal[msg.sender] -= principal](src/LendingMarket.sol#L261)
	[LendingMarket.borrowPrincipal](src/LendingMarket.sol#L54) can be used in cross function reentrancies:
	- [LendingMarket.borrow(uint256)](src/LendingMarket.sol#L231-L244)
	- [LendingMarket.borrowBalanceOf(address)](src/LendingMarket.sol#L313-L315)
	- [LendingMarket.borrowPrincipal](src/LendingMarket.sol#L54)
	- [LendingMarket.liquidate(address,uint256)](src/LendingMarket.sol#L277-L307)
	- [LendingMarket.repay(uint256)](src/LendingMarket.sol#L246-L265)
	- [totalBorrowPrincipal -= principal](src/LendingMarket.sol#L262)
	[LendingMarket.totalBorrowPrincipal](src/LendingMarket.sol#L44) can be used in cross function reentrancies:
	- [LendingMarket.accrueInterest()](src/LendingMarket.sol#L139-L160)
	- [LendingMarket.borrow(uint256)](src/LendingMarket.sol#L231-L244)
	- [LendingMarket.liquidate(address,uint256)](src/LendingMarket.sol#L277-L307)
	- [LendingMarket.repay(uint256)](src/LendingMarket.sol#L246-L265)
	- [LendingMarket.totalBorrowPrincipal](src/LendingMarket.sol#L44)
	- [LendingMarket.utilization()](src/LendingMarket.sol#L337-L341)

src/LendingMarket.sol#L246-L265


 - [ ] ID-1
Reentrancy in [LendingMarket.supply(uint256)](src/LendingMarket.sol#L166-L181):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L171)
	State variables written after the call(s):
	- [totalSupplyPrincipal += principal](src/LendingMarket.sol#L178)
	[LendingMarket.totalSupplyPrincipal](src/LendingMarket.sol#L43) can be used in cross function reentrancies:
	- [LendingMarket.accrueInterest()](src/LendingMarket.sol#L139-L160)
	- [LendingMarket.supply(uint256)](src/LendingMarket.sol#L166-L181)
	- [LendingMarket.totalSupplyPrincipal](src/LendingMarket.sol#L43)
	- [LendingMarket.utilization()](src/LendingMarket.sol#L337-L341)
	- [LendingMarket.withdraw(uint256)](src/LendingMarket.sol#L183-L196)

src/LendingMarket.sol#L166-L181


 - [ ] ID-2
Reentrancy in [LendingMarket.liquidate(address,uint256)](src/LendingMarket.sol#L277-L307):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),repayAmount)](src/LendingMarket.sol#L287)
	State variables written after the call(s):
	- [borrowPrincipal[borrower] -= principal](src/LendingMarket.sol#L298)
	[LendingMarket.borrowPrincipal](src/LendingMarket.sol#L54) can be used in cross function reentrancies:
	- [LendingMarket.borrow(uint256)](src/LendingMarket.sol#L231-L244)
	- [LendingMarket.borrowBalanceOf(address)](src/LendingMarket.sol#L313-L315)
	- [LendingMarket.borrowPrincipal](src/LendingMarket.sol#L54)
	- [LendingMarket.liquidate(address,uint256)](src/LendingMarket.sol#L277-L307)
	- [LendingMarket.repay(uint256)](src/LendingMarket.sol#L246-L265)
	- [collateralBalance[borrower] -= seizeAmount](src/LendingMarket.sol#L301)
	[LendingMarket.collateralBalance](src/LendingMarket.sol#L55) can be used in cross function reentrancies:
	- [LendingMarket.collateralBalance](src/LendingMarket.sol#L55)
	- [LendingMarket.isHealthy(address)](src/LendingMarket.sol#L344-L352)
	- [LendingMarket.liquidate(address,uint256)](src/LendingMarket.sol#L277-L307)
	- [LendingMarket.supplyCollateral(uint256)](src/LendingMarket.sol#L202-L215)
	- [LendingMarket.withdrawCollateral(uint256)](src/LendingMarket.sol#L217-L229)
	- [totalBorrowPrincipal -= principal](src/LendingMarket.sol#L299)
	[LendingMarket.totalBorrowPrincipal](src/LendingMarket.sol#L44) can be used in cross function reentrancies:
	- [LendingMarket.accrueInterest()](src/LendingMarket.sol#L139-L160)
	- [LendingMarket.borrow(uint256)](src/LendingMarket.sol#L231-L244)
	- [LendingMarket.liquidate(address,uint256)](src/LendingMarket.sol#L277-L307)
	- [LendingMarket.repay(uint256)](src/LendingMarket.sol#L246-L265)
	- [LendingMarket.totalBorrowPrincipal](src/LendingMarket.sol#L44)
	- [LendingMarket.utilization()](src/LendingMarket.sol#L337-L341)

src/LendingMarket.sol#L277-L307


