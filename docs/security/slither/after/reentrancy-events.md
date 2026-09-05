**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
 - [reentrancy-events](#reentrancy-events) (8 results) (Low)
## reentrancy-events
Impact: Low
Confidence: Medium
 - [ ] ID-0
Reentrancy in [LendingMarket.supplyCollateral(uint256)](src/LendingMarket.sol#L202-L215):
	External calls:
	- [collateralToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L206)
	Event emitted after the call(s):
	- [SupplyCollateral(msg.sender,transferedAmount)](src/LendingMarket.sol#L214)

src/LendingMarket.sol#L202-L215


 - [ ] ID-1
Reentrancy in [LendingMarket.supply(uint256)](src/LendingMarket.sol#L166-L181):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L171)
	Event emitted after the call(s):
	- [Supply(msg.sender,transferedAmount)](src/LendingMarket.sol#L180)

src/LendingMarket.sol#L166-L181


 - [ ] ID-2
Reentrancy in [LendingMarket.withdrawCollateral(uint256)](src/LendingMarket.sol#L217-L229):
	External calls:
	- [collateralToken.transfer(msg.sender,amount)](src/LendingMarket.sol#L226)
	Event emitted after the call(s):
	- [WithdrawCollateral(msg.sender,amount)](src/LendingMarket.sol#L228)

src/LendingMarket.sol#L217-L229


 - [ ] ID-3
Reentrancy in [LendingMarket.liquidate(address,uint256)](src/LendingMarket.sol#L277-L307):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),repayAmount)](src/LendingMarket.sol#L287)
	- [collateralToken.transfer(msg.sender,seizeAmount)](src/LendingMarket.sol#L304)
	Event emitted after the call(s):
	- [Liquidate(msg.sender,borrower,transferedAmount,seizeAmount)](src/LendingMarket.sol#L306)

src/LendingMarket.sol#L277-L307


 - [ ] ID-4
Reentrancy in [LendingMarket.withdrawReserves(address,uint256)](src/LendingMarket.sol#L405-L412):
	External calls:
	- [baseToken.transfer(recipient,amount)](src/LendingMarket.sol#L410)
	Event emitted after the call(s):
	- [ReservesWithdrawn(recipient,amount)](src/LendingMarket.sol#L411)

src/LendingMarket.sol#L405-L412


 - [ ] ID-5
Reentrancy in [LendingMarket.repay(uint256)](src/LendingMarket.sol#L246-L265):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L254)
	Event emitted after the call(s):
	- [Repay(msg.sender,transferedAmount)](src/LendingMarket.sol#L264)

src/LendingMarket.sol#L246-L265


 - [ ] ID-6
Reentrancy in [LendingMarket.borrow(uint256)](src/LendingMarket.sol#L231-L244):
	External calls:
	- [baseToken.transfer(msg.sender,amount)](src/LendingMarket.sol#L241)
	Event emitted after the call(s):
	- [Borrow(msg.sender,amount)](src/LendingMarket.sol#L243)

src/LendingMarket.sol#L231-L244


 - [ ] ID-7
Reentrancy in [LendingMarket.withdraw(uint256)](src/LendingMarket.sol#L183-L196):
	External calls:
	- [baseToken.transfer(msg.sender,amount)](src/LendingMarket.sol#L193)
	Event emitted after the call(s):
	- [Withdraw(msg.sender,amount)](src/LendingMarket.sol#L195)

src/LendingMarket.sol#L183-L196


