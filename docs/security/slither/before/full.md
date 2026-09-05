**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
 - [unchecked-transfer](#unchecked-transfer) (8 results) (High)
 - [divide-before-multiply](#divide-before-multiply) (2 results) (Medium)
 - [incorrect-equality](#incorrect-equality) (2 results) (Medium)
 - [reentrancy-no-eth](#reentrancy-no-eth) (2 results) (Medium)
 - [unused-return](#unused-return) (1 results) (Medium)
 - [events-access](#events-access) (1 results) (Low)
 - [missing-zero-check](#missing-zero-check) (3 results) (Low)
 - [reentrancy-benign](#reentrancy-benign) (2 results) (Low)
 - [reentrancy-events](#reentrancy-events) (7 results) (Low)
 - [timestamp](#timestamp) (5 results) (Low)
 - [assembly](#assembly) (4 results) (Informational)
 - [low-level-calls](#low-level-calls) (1 results) (Informational)
## unchecked-transfer
Impact: High
Confidence: Medium
 - [ ] ID-0
[LendingMarket.supply(uint256)](src/LendingMarket.sol#L156-L167) ignores return value by [baseToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L160)

src/LendingMarket.sol#L156-L167


 - [ ] ID-1
[LendingMarket.repay(uint256)](src/LendingMarket.sol#L228-L243) ignores return value by [baseToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L237)

src/LendingMarket.sol#L228-L243


 - [ ] ID-2
[LendingMarket.supplyCollateral(uint256)](src/LendingMarket.sol#L188-L197) ignores return value by [collateralToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L191)

src/LendingMarket.sol#L188-L197


 - [ ] ID-3
[LendingMarket.borrow(uint256)](src/LendingMarket.sol#L213-L226) ignores return value by [baseToken.transfer(msg.sender,amount)](src/LendingMarket.sol#L223)

src/LendingMarket.sol#L213-L226


 - [ ] ID-4
[LendingMarket.liquidate(address,uint256)](src/LendingMarket.sol#L255-L280) ignores return value by [collateralToken.transfer(msg.sender,seizeAmount)](src/LendingMarket.sol#L277)

src/LendingMarket.sol#L255-L280


 - [ ] ID-5
[LendingMarket.withdrawCollateral(uint256)](src/LendingMarket.sol#L199-L211) ignores return value by [collateralToken.transfer(msg.sender,amount)](src/LendingMarket.sol#L208)

src/LendingMarket.sol#L199-L211


 - [ ] ID-6
[LendingMarket.withdraw(uint256)](src/LendingMarket.sol#L169-L182) ignores return value by [baseToken.transfer(msg.sender,amount)](src/LendingMarket.sol#L179)

src/LendingMarket.sol#L169-L182


 - [ ] ID-7
[LendingMarket.liquidate(address,uint256)](src/LendingMarket.sol#L255-L280) ignores return value by [baseToken.transferFrom(msg.sender,address(this),repayAmount)](src/LendingMarket.sol#L276)

src/LendingMarket.sol#L255-L280


## divide-before-multiply
Impact: Medium
Confidence: Medium
 - [ ] ID-8
[LendingMarket.accrueInterest()](src/LendingMarket.sol#L133-L150) performs a multiplication on the result of a division:
	- [accruedToSuppliers = (borrowsBefore * interest) / FACTOR](src/LendingMarket.sol#L145)
	- [baseSupplyIndex += (baseSupplyIndex * accruedToSuppliers) / suppliesBefore](src/LendingMarket.sol#L146)

src/LendingMarket.sol#L133-L150


 - [ ] ID-9
[LendingMarket.isHealthy(address)](src/LendingMarket.sol#L312-L320) performs a multiplication on the result of a division:
	- [collateralValue = (collateralBalance[account] * getPrice()) / FACTOR](src/LendingMarket.sol#L316)
	- [borrowingPower = (collateralValue * collateralFactor) / FACTOR](src/LendingMarket.sol#L317)

src/LendingMarket.sol#L312-L320


## incorrect-equality
Impact: Medium
Confidence: High
 - [ ] ID-10
[LendingMarket.accrueInterest()](src/LendingMarket.sol#L133-L150) uses a dangerous strict equality:
	- [elapsed == 0](src/LendingMarket.sol#L135)

src/LendingMarket.sol#L133-L150


 - [ ] ID-11
[LendingMarket.isHealthy(address)](src/LendingMarket.sol#L312-L320) uses a dangerous strict equality:
	- [debt == 0](src/LendingMarket.sol#L314)

src/LendingMarket.sol#L312-L320


## reentrancy-no-eth
Impact: Medium
Confidence: Medium
 - [ ] ID-12
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


 - [ ] ID-13
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


## unused-return
Impact: Medium
Confidence: Medium
 - [ ] ID-14
[LendingMarket.getPrice()](src/LendingMarket.sol#L323-L326) ignores return value by [(None,answer,None,None,None) = oracle.latestRoundData()](src/LendingMarket.sol#L324)

src/LendingMarket.sol#L323-L326


## events-access
Impact: Low
Confidence: Medium
 - [ ] ID-15
[LendingMarket.setAdmin(address)](src/LendingMarket.sol#L371-L374) should emit an event for: 
	- [admin = newAdmin](src/LendingMarket.sol#L373) 
	- [admin = newAdmin](src/LendingMarket.sol#L373) 

src/LendingMarket.sol#L371-L374


## missing-zero-check
Impact: Low
Confidence: Medium
 - [ ] ID-16
[LendingMarket.initialize(address,address,address,address,address,uint256,uint256,uint256).admin_](src/LendingMarket.sol#L101) lacks a zero-check on :
		- [admin = admin_](src/LendingMarket.sol#L113)

src/LendingMarket.sol#L101


 - [ ] ID-17
[LendingMarket.initialize(address,address,address,address,address,uint256,uint256,uint256).pauseGuardian_](src/LendingMarket.sol#L102) lacks a zero-check on :
		- [pauseGuardian = pauseGuardian_](src/LendingMarket.sol#L114)

src/LendingMarket.sol#L102


 - [ ] ID-18
[TransparentUpgradeableProxy.constructor(address,address,bytes).implementation_](src/TransparentUpgradeableProxy.sol#L21) lacks a zero-check on :
		- [(ok,ret) = implementation_.delegatecall(initData)](src/TransparentUpgradeableProxy.sol#L26)

src/TransparentUpgradeableProxy.sol#L21


## reentrancy-benign
Impact: Low
Confidence: Medium
 - [ ] ID-19
Reentrancy in [LendingMarket.supply(uint256)](src/LendingMarket.sol#L156-L167):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L160)
	State variables written after the call(s):
	- [supplyPrincipal[msg.sender] += principal](src/LendingMarket.sol#L163)

src/LendingMarket.sol#L156-L167


 - [ ] ID-20
Reentrancy in [LendingMarket.supplyCollateral(uint256)](src/LendingMarket.sol#L188-L197):
	External calls:
	- [collateralToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L191)
	State variables written after the call(s):
	- [collateralBalance[msg.sender] += amount](src/LendingMarket.sol#L193)
	- [totalCollateral += amount](src/LendingMarket.sol#L194)

src/LendingMarket.sol#L188-L197


## reentrancy-events
Impact: Low
Confidence: Medium
 - [ ] ID-21
Reentrancy in [LendingMarket.borrow(uint256)](src/LendingMarket.sol#L213-L226):
	External calls:
	- [baseToken.transfer(msg.sender,amount)](src/LendingMarket.sol#L223)
	Event emitted after the call(s):
	- [Borrow(msg.sender,amount)](src/LendingMarket.sol#L225)

src/LendingMarket.sol#L213-L226


 - [ ] ID-22
Reentrancy in [LendingMarket.supplyCollateral(uint256)](src/LendingMarket.sol#L188-L197):
	External calls:
	- [collateralToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L191)
	Event emitted after the call(s):
	- [SupplyCollateral(msg.sender,amount)](src/LendingMarket.sol#L196)

src/LendingMarket.sol#L188-L197


 - [ ] ID-23
Reentrancy in [LendingMarket.withdraw(uint256)](src/LendingMarket.sol#L169-L182):
	External calls:
	- [baseToken.transfer(msg.sender,amount)](src/LendingMarket.sol#L179)
	Event emitted after the call(s):
	- [Withdraw(msg.sender,amount)](src/LendingMarket.sol#L181)

src/LendingMarket.sol#L169-L182


 - [ ] ID-24
Reentrancy in [LendingMarket.withdrawCollateral(uint256)](src/LendingMarket.sol#L199-L211):
	External calls:
	- [collateralToken.transfer(msg.sender,amount)](src/LendingMarket.sol#L208)
	Event emitted after the call(s):
	- [WithdrawCollateral(msg.sender,amount)](src/LendingMarket.sol#L210)

src/LendingMarket.sol#L199-L211


 - [ ] ID-25
Reentrancy in [LendingMarket.repay(uint256)](src/LendingMarket.sol#L228-L243):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L237)
	Event emitted after the call(s):
	- [Repay(msg.sender,amount)](src/LendingMarket.sol#L242)

src/LendingMarket.sol#L228-L243


 - [ ] ID-26
Reentrancy in [LendingMarket.supply(uint256)](src/LendingMarket.sol#L156-L167):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L160)
	Event emitted after the call(s):
	- [Supply(msg.sender,amount)](src/LendingMarket.sol#L166)

src/LendingMarket.sol#L156-L167


 - [ ] ID-27
Reentrancy in [LendingMarket.liquidate(address,uint256)](src/LendingMarket.sol#L255-L280):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),repayAmount)](src/LendingMarket.sol#L276)
	- [collateralToken.transfer(msg.sender,seizeAmount)](src/LendingMarket.sol#L277)
	Event emitted after the call(s):
	- [Liquidate(msg.sender,borrower,repayAmount,seizeAmount)](src/LendingMarket.sol#L279)

src/LendingMarket.sol#L255-L280


## timestamp
Impact: Low
Confidence: Medium
 - [ ] ID-28
[LendingMarket.accrueInterest()](src/LendingMarket.sol#L133-L150) uses timestamp for comparisons
	Dangerous comparisons:
	- [elapsed == 0](src/LendingMarket.sol#L135)

src/LendingMarket.sol#L133-L150


 - [ ] ID-29
[LendingMarket.repay(uint256)](src/LendingMarket.sol#L228-L243) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(amount > 0,zero amount)](src/LendingMarket.sol#L229)
	- [amount > owed](src/LendingMarket.sol#L233)

src/LendingMarket.sol#L228-L243


 - [ ] ID-30
[LendingMarket.liquidate(address,uint256)](src/LendingMarket.sol#L255-L280) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(repayAmount > 0,zero amount)](src/LendingMarket.sol#L256)
	- [repayAmount > owed](src/LendingMarket.sol#L262)
	- [seizeAmount > collateralBalance[borrower]](src/LendingMarket.sol#L265)

src/LendingMarket.sol#L255-L280


 - [ ] ID-31
[LendingMarket.isHealthy(address)](src/LendingMarket.sol#L312-L320) uses timestamp for comparisons
	Dangerous comparisons:
	- [debt == 0](src/LendingMarket.sol#L314)
	- [borrowingPower >= debt](src/LendingMarket.sol#L319)

src/LendingMarket.sol#L312-L320


 - [ ] ID-32
[LendingMarket.withdrawCollateral(uint256)](src/LendingMarket.sol#L199-L211) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(collateralBalance[msg.sender] >= amount,insufficient collateral)](src/LendingMarket.sol#L201)

src/LendingMarket.sol#L199-L211


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-33
[TransparentUpgradeableProxy._revertReason(bytes)](src/TransparentUpgradeableProxy.sol#L76-L82) uses assembly
	- [INLINE ASM](src/TransparentUpgradeableProxy.sol#L78-L80)

src/TransparentUpgradeableProxy.sol#L76-L82


 - [ ] ID-34
[TransparentUpgradeableProxy.fallback()](src/TransparentUpgradeableProxy.sol#L50-L60) uses assembly
	- [INLINE ASM](src/TransparentUpgradeableProxy.sol#L52-L59)

src/TransparentUpgradeableProxy.sol#L50-L60


 - [ ] ID-35
[TransparentUpgradeableProxy._setSlot(bytes32,address)](src/TransparentUpgradeableProxy.sol#L70-L74) uses assembly
	- [INLINE ASM](src/TransparentUpgradeableProxy.sol#L71-L73)

src/TransparentUpgradeableProxy.sol#L70-L74


 - [ ] ID-36
[TransparentUpgradeableProxy._getSlot(bytes32)](src/TransparentUpgradeableProxy.sol#L64-L68) uses assembly
	- [INLINE ASM](src/TransparentUpgradeableProxy.sol#L65-L67)

src/TransparentUpgradeableProxy.sol#L64-L68


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-37
Low level call in [TransparentUpgradeableProxy.constructor(address,address,bytes)](src/TransparentUpgradeableProxy.sol#L21-L31):
	- [(ok,ret) = implementation_.delegatecall(initData)](src/TransparentUpgradeableProxy.sol#L26)

src/TransparentUpgradeableProxy.sol#L21-L31


