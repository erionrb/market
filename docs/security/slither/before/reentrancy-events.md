**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
 - [reentrancy-events](#reentrancy-events) (7 results) (Low)
## reentrancy-events
Impact: Low
Confidence: Medium
 - [ ] ID-0
Reentrancy in [LendingMarket.borrow(uint256)](src/LendingMarket.sol#L213-L226):
	External calls:
	- [baseToken.transfer(msg.sender,amount)](src/LendingMarket.sol#L223)
	Event emitted after the call(s):
	- [Borrow(msg.sender,amount)](src/LendingMarket.sol#L225)

src/LendingMarket.sol#L213-L226


 - [ ] ID-1
Reentrancy in [LendingMarket.supplyCollateral(uint256)](src/LendingMarket.sol#L188-L197):
	External calls:
	- [collateralToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L191)
	Event emitted after the call(s):
	- [SupplyCollateral(msg.sender,amount)](src/LendingMarket.sol#L196)

src/LendingMarket.sol#L188-L197


 - [ ] ID-2
Reentrancy in [LendingMarket.withdraw(uint256)](src/LendingMarket.sol#L169-L182):
	External calls:
	- [baseToken.transfer(msg.sender,amount)](src/LendingMarket.sol#L179)
	Event emitted after the call(s):
	- [Withdraw(msg.sender,amount)](src/LendingMarket.sol#L181)

src/LendingMarket.sol#L169-L182


 - [ ] ID-3
Reentrancy in [LendingMarket.withdrawCollateral(uint256)](src/LendingMarket.sol#L199-L211):
	External calls:
	- [collateralToken.transfer(msg.sender,amount)](src/LendingMarket.sol#L208)
	Event emitted after the call(s):
	- [WithdrawCollateral(msg.sender,amount)](src/LendingMarket.sol#L210)

src/LendingMarket.sol#L199-L211


 - [ ] ID-4
Reentrancy in [LendingMarket.repay(uint256)](src/LendingMarket.sol#L228-L243):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L237)
	Event emitted after the call(s):
	- [Repay(msg.sender,amount)](src/LendingMarket.sol#L242)

src/LendingMarket.sol#L228-L243


 - [ ] ID-5
Reentrancy in [LendingMarket.supply(uint256)](src/LendingMarket.sol#L156-L167):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L160)
	Event emitted after the call(s):
	- [Supply(msg.sender,amount)](src/LendingMarket.sol#L166)

src/LendingMarket.sol#L156-L167


 - [ ] ID-6
Reentrancy in [LendingMarket.liquidate(address,uint256)](src/LendingMarket.sol#L255-L280):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),repayAmount)](src/LendingMarket.sol#L276)
	- [collateralToken.transfer(msg.sender,seizeAmount)](src/LendingMarket.sol#L277)
	Event emitted after the call(s):
	- [Liquidate(msg.sender,borrower,repayAmount,seizeAmount)](src/LendingMarket.sol#L279)

src/LendingMarket.sol#L255-L280


