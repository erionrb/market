**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
 - [reentrancy-no-eth](#reentrancy-no-eth) (2 results) (Medium)
## reentrancy-no-eth
Impact: Medium
Confidence: Medium
 - [ ] ID-0
Reentrancy in [LendingMarket.repay(uint256)](src/LendingMarket.sol#L228-L243):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L237)
	State variables written after the call(s):
	- [borrowPrincipal[msg.sender] -= principal](src/LendingMarket.sol#L239)
	[LendingMarket.borrowPrincipal](src/LendingMarket.sol#L54) can be used in cross function reentrancies:
	- [LendingMarket.borrow(uint256)](src/LendingMarket.sol#L213-L226)
	- [LendingMarket.borrowBalanceOf(address)](src/LendingMarket.sol#L286-L288)
	- [LendingMarket.borrowPrincipal](src/LendingMarket.sol#L54)
	- [LendingMarket.liquidate(address,uint256)](src/LendingMarket.sol#L255-L280)
	- [LendingMarket.repay(uint256)](src/LendingMarket.sol#L228-L243)
	- [totalBorrowPrincipal -= principal](src/LendingMarket.sol#L240)
	[LendingMarket.totalBorrowPrincipal](src/LendingMarket.sol#L44) can be used in cross function reentrancies:
	- [LendingMarket.accrueInterest()](src/LendingMarket.sol#L133-L150)
	- [LendingMarket.borrow(uint256)](src/LendingMarket.sol#L213-L226)
	- [LendingMarket.liquidate(address,uint256)](src/LendingMarket.sol#L255-L280)
	- [LendingMarket.repay(uint256)](src/LendingMarket.sol#L228-L243)
	- [LendingMarket.totalBorrowPrincipal](src/LendingMarket.sol#L44)
	- [LendingMarket.utilization()](src/LendingMarket.sol#L305-L309)

src/LendingMarket.sol#L228-L243


 - [ ] ID-1
Reentrancy in [LendingMarket.supply(uint256)](src/LendingMarket.sol#L156-L167):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L160)
	State variables written after the call(s):
	- [totalSupplyPrincipal += principal](src/LendingMarket.sol#L164)
	[LendingMarket.totalSupplyPrincipal](src/LendingMarket.sol#L43) can be used in cross function reentrancies:
	- [LendingMarket.accrueInterest()](src/LendingMarket.sol#L133-L150)
	- [LendingMarket.supply(uint256)](src/LendingMarket.sol#L156-L167)
	- [LendingMarket.totalSupplyPrincipal](src/LendingMarket.sol#L43)
	- [LendingMarket.utilization()](src/LendingMarket.sol#L305-L309)
	- [LendingMarket.withdraw(uint256)](src/LendingMarket.sol#L169-L182)

src/LendingMarket.sol#L156-L167


