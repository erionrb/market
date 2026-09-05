**THIS CHECKLIST IS NOT COMPLETE**. Use `--show-ignored-findings` to show all the results.
Summary
 - [unchecked-transfer](#unchecked-transfer) (9 results) (High)
 - [divide-before-multiply](#divide-before-multiply) (2 results) (Medium)
 - [incorrect-equality](#incorrect-equality) (3 results) (Medium)
 - [reentrancy-no-eth](#reentrancy-no-eth) (3 results) (Medium)
 - [unused-return](#unused-return) (1 results) (Medium)
 - [events-access](#events-access) (1 results) (Low)
 - [missing-zero-check](#missing-zero-check) (3 results) (Low)
 - [reentrancy-benign](#reentrancy-benign) (3 results) (Low)
 - [reentrancy-events](#reentrancy-events) (8 results) (Low)
 - [timestamp](#timestamp) (5 results) (Low)
 - [assembly](#assembly) (4 results) (Informational)
 - [low-level-calls](#low-level-calls) (1 results) (Informational)
## unchecked-transfer
Impact: High
Confidence: Medium
 - [ ] ID-0
[LendingMarket.supplyCollateral(uint256)](src/LendingMarket.sol#L202-L215) ignores return value by [collateralToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L206)

src/LendingMarket.sol#L202-L215


 - [ ] ID-1
[LendingMarket.withdrawReserves(address,uint256)](src/LendingMarket.sol#L405-L412) ignores return value by [baseToken.transfer(recipient,amount)](src/LendingMarket.sol#L410)

src/LendingMarket.sol#L405-L412


 - [ ] ID-2
[LendingMarket.liquidate(address,uint256)](src/LendingMarket.sol#L277-L307) ignores return value by [baseToken.transferFrom(msg.sender,address(this),repayAmount)](src/LendingMarket.sol#L287)

src/LendingMarket.sol#L277-L307


 - [ ] ID-3
[LendingMarket.withdrawCollateral(uint256)](src/LendingMarket.sol#L217-L229) ignores return value by [collateralToken.transfer(msg.sender,amount)](src/LendingMarket.sol#L226)

src/LendingMarket.sol#L217-L229


 - [ ] ID-4
[LendingMarket.repay(uint256)](src/LendingMarket.sol#L246-L265) ignores return value by [baseToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L254)

src/LendingMarket.sol#L246-L265


 - [ ] ID-5
[LendingMarket.borrow(uint256)](src/LendingMarket.sol#L231-L244) ignores return value by [baseToken.transfer(msg.sender,amount)](src/LendingMarket.sol#L241)

src/LendingMarket.sol#L231-L244


 - [ ] ID-6
[LendingMarket.withdraw(uint256)](src/LendingMarket.sol#L183-L196) ignores return value by [baseToken.transfer(msg.sender,amount)](src/LendingMarket.sol#L193)

src/LendingMarket.sol#L183-L196


 - [ ] ID-7
[LendingMarket.liquidate(address,uint256)](src/LendingMarket.sol#L277-L307) ignores return value by [collateralToken.transfer(msg.sender,seizeAmount)](src/LendingMarket.sol#L304)

src/LendingMarket.sol#L277-L307


 - [ ] ID-8
[LendingMarket.supply(uint256)](src/LendingMarket.sol#L166-L181) ignores return value by [baseToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L171)

src/LendingMarket.sol#L166-L181


## divide-before-multiply
Impact: Medium
Confidence: Medium
 - [ ] ID-9
[LendingMarket.accrueInterest()](src/LendingMarket.sol#L139-L160) performs a multiplication on the result of a division:
	- [borrowerInterest = (borrowsBefore * interest) / FACTOR](src/LendingMarket.sol#L150)
	- [reserveAccrued = (borrowerInterest * reserveFactor) / FACTOR](src/LendingMarket.sol#L151)

src/LendingMarket.sol#L139-L160


 - [ ] ID-10
[LendingMarket.isHealthy(address)](src/LendingMarket.sol#L344-L352) performs a multiplication on the result of a division:
	- [collateralValue = (collateralBalance[account] * getPrice()) / FACTOR](src/LendingMarket.sol#L348)
	- [borrowingPower = (collateralValue * collateralFactor) / FACTOR](src/LendingMarket.sol#L349)

src/LendingMarket.sol#L344-L352


## incorrect-equality
Impact: Medium
Confidence: High
 - [ ] ID-11
[LendingMarket.utilization()](src/LendingMarket.sol#L337-L341) uses a dangerous strict equality:
	- [supplied == 0](src/LendingMarket.sol#L339)

src/LendingMarket.sol#L337-L341


 - [ ] ID-12
[LendingMarket.accrueInterest()](src/LendingMarket.sol#L139-L160) uses a dangerous strict equality:
	- [elapsed == 0](src/LendingMarket.sol#L141)

src/LendingMarket.sol#L139-L160


 - [ ] ID-13
[LendingMarket.isHealthy(address)](src/LendingMarket.sol#L344-L352) uses a dangerous strict equality:
	- [debt == 0](src/LendingMarket.sol#L346)

src/LendingMarket.sol#L344-L352


## reentrancy-no-eth
Impact: Medium
Confidence: Medium
 - [ ] ID-14
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


 - [ ] ID-15
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


 - [ ] ID-16
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


## unused-return
Impact: Medium
Confidence: Medium
 - [ ] ID-17
[LendingMarket.getPrice()](src/LendingMarket.sol#L355-L358) ignores return value by [(None,answer,None,None,None) = oracle.latestRoundData()](src/LendingMarket.sol#L356)

src/LendingMarket.sol#L355-L358


## events-access
Impact: Low
Confidence: Medium
 - [ ] ID-18
[LendingMarket.setAdmin(address)](src/LendingMarket.sol#L419-L422) should emit an event for: 
	- [admin = newAdmin](src/LendingMarket.sol#L421) 
	- [admin = newAdmin](src/LendingMarket.sol#L421) 

src/LendingMarket.sol#L419-L422


## missing-zero-check
Impact: Low
Confidence: Medium
 - [ ] ID-19
[LendingMarket.initialize(address,address,address,address,address,uint256,uint256,uint256).admin_](src/LendingMarket.sol#L107) lacks a zero-check on :
		- [admin = admin_](src/LendingMarket.sol#L119)

src/LendingMarket.sol#L107


 - [ ] ID-20
[TransparentUpgradeableProxy.constructor(address,address,bytes).implementation_](src/TransparentUpgradeableProxy.sol#L21) lacks a zero-check on :
		- [(ok,ret) = implementation_.delegatecall(initData)](src/TransparentUpgradeableProxy.sol#L26)

src/TransparentUpgradeableProxy.sol#L21


 - [ ] ID-21
[LendingMarket.initialize(address,address,address,address,address,uint256,uint256,uint256).pauseGuardian_](src/LendingMarket.sol#L108) lacks a zero-check on :
		- [pauseGuardian = pauseGuardian_](src/LendingMarket.sol#L120)

src/LendingMarket.sol#L108


## reentrancy-benign
Impact: Low
Confidence: Medium
 - [ ] ID-22
Reentrancy in [LendingMarket.liquidate(address,uint256)](src/LendingMarket.sol#L277-L307):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),repayAmount)](src/LendingMarket.sol#L287)
	State variables written after the call(s):
	- [totalCollateral -= seizeAmount](src/LendingMarket.sol#L302)

src/LendingMarket.sol#L277-L307


 - [ ] ID-23
Reentrancy in [LendingMarket.supplyCollateral(uint256)](src/LendingMarket.sol#L202-L215):
	External calls:
	- [collateralToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L206)
	State variables written after the call(s):
	- [collateralBalance[msg.sender] += transferedAmount](src/LendingMarket.sol#L211)
	- [totalCollateral += transferedAmount](src/LendingMarket.sol#L212)

src/LendingMarket.sol#L202-L215


 - [ ] ID-24
Reentrancy in [LendingMarket.supply(uint256)](src/LendingMarket.sol#L166-L181):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L171)
	State variables written after the call(s):
	- [supplyPrincipal[msg.sender] += principal](src/LendingMarket.sol#L177)

src/LendingMarket.sol#L166-L181


## reentrancy-events
Impact: Low
Confidence: Medium
 - [ ] ID-25
Reentrancy in [LendingMarket.supplyCollateral(uint256)](src/LendingMarket.sol#L202-L215):
	External calls:
	- [collateralToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L206)
	Event emitted after the call(s):
	- [SupplyCollateral(msg.sender,transferedAmount)](src/LendingMarket.sol#L214)

src/LendingMarket.sol#L202-L215


 - [ ] ID-26
Reentrancy in [LendingMarket.supply(uint256)](src/LendingMarket.sol#L166-L181):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L171)
	Event emitted after the call(s):
	- [Supply(msg.sender,transferedAmount)](src/LendingMarket.sol#L180)

src/LendingMarket.sol#L166-L181


 - [ ] ID-27
Reentrancy in [LendingMarket.withdrawCollateral(uint256)](src/LendingMarket.sol#L217-L229):
	External calls:
	- [collateralToken.transfer(msg.sender,amount)](src/LendingMarket.sol#L226)
	Event emitted after the call(s):
	- [WithdrawCollateral(msg.sender,amount)](src/LendingMarket.sol#L228)

src/LendingMarket.sol#L217-L229


 - [ ] ID-28
Reentrancy in [LendingMarket.liquidate(address,uint256)](src/LendingMarket.sol#L277-L307):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),repayAmount)](src/LendingMarket.sol#L287)
	- [collateralToken.transfer(msg.sender,seizeAmount)](src/LendingMarket.sol#L304)
	Event emitted after the call(s):
	- [Liquidate(msg.sender,borrower,transferedAmount,seizeAmount)](src/LendingMarket.sol#L306)

src/LendingMarket.sol#L277-L307


 - [ ] ID-29
Reentrancy in [LendingMarket.withdrawReserves(address,uint256)](src/LendingMarket.sol#L405-L412):
	External calls:
	- [baseToken.transfer(recipient,amount)](src/LendingMarket.sol#L410)
	Event emitted after the call(s):
	- [ReservesWithdrawn(recipient,amount)](src/LendingMarket.sol#L411)

src/LendingMarket.sol#L405-L412


 - [ ] ID-30
Reentrancy in [LendingMarket.repay(uint256)](src/LendingMarket.sol#L246-L265):
	External calls:
	- [baseToken.transferFrom(msg.sender,address(this),amount)](src/LendingMarket.sol#L254)
	Event emitted after the call(s):
	- [Repay(msg.sender,transferedAmount)](src/LendingMarket.sol#L264)

src/LendingMarket.sol#L246-L265


 - [ ] ID-31
Reentrancy in [LendingMarket.borrow(uint256)](src/LendingMarket.sol#L231-L244):
	External calls:
	- [baseToken.transfer(msg.sender,amount)](src/LendingMarket.sol#L241)
	Event emitted after the call(s):
	- [Borrow(msg.sender,amount)](src/LendingMarket.sol#L243)

src/LendingMarket.sol#L231-L244


 - [ ] ID-32
Reentrancy in [LendingMarket.withdraw(uint256)](src/LendingMarket.sol#L183-L196):
	External calls:
	- [baseToken.transfer(msg.sender,amount)](src/LendingMarket.sol#L193)
	Event emitted after the call(s):
	- [Withdraw(msg.sender,amount)](src/LendingMarket.sol#L195)

src/LendingMarket.sol#L183-L196


## timestamp
Impact: Low
Confidence: Medium
 - [ ] ID-33
[LendingMarket.liquidate(address,uint256)](src/LendingMarket.sol#L277-L307) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(repayAmount > 0,zero amount)](src/LendingMarket.sol#L278)
	- [repayAmount > owed](src/LendingMarket.sol#L284)

src/LendingMarket.sol#L277-L307


 - [ ] ID-34
[LendingMarket.isHealthy(address)](src/LendingMarket.sol#L344-L352) uses timestamp for comparisons
	Dangerous comparisons:
	- [debt == 0](src/LendingMarket.sol#L346)
	- [borrowingPower >= debt](src/LendingMarket.sol#L351)

src/LendingMarket.sol#L344-L352


 - [ ] ID-35
[LendingMarket.repay(uint256)](src/LendingMarket.sol#L246-L265) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(amount > 0,zero amount)](src/LendingMarket.sol#L247)
	- [amount > owed](src/LendingMarket.sol#L251)

src/LendingMarket.sol#L246-L265


 - [ ] ID-36
[LendingMarket.accrueInterest()](src/LendingMarket.sol#L139-L160) uses timestamp for comparisons
	Dangerous comparisons:
	- [elapsed == 0](src/LendingMarket.sol#L141)
	- [reserveAccrued != 0](src/LendingMarket.sol#L152)

src/LendingMarket.sol#L139-L160


 - [ ] ID-37
[LendingMarket.withdrawReserves(address,uint256)](src/LendingMarket.sol#L405-L412) uses timestamp for comparisons
	Dangerous comparisons:
	- [require(bool,string)(amount <= totalReserves,amount exceeds reserves)](src/LendingMarket.sol#L407)

src/LendingMarket.sol#L405-L412


## assembly
Impact: Informational
Confidence: High
 - [ ] ID-38
[TransparentUpgradeableProxy._revertReason(bytes)](src/TransparentUpgradeableProxy.sol#L76-L82) uses assembly
	- [INLINE ASM](src/TransparentUpgradeableProxy.sol#L78-L80)

src/TransparentUpgradeableProxy.sol#L76-L82


 - [ ] ID-39
[TransparentUpgradeableProxy.fallback()](src/TransparentUpgradeableProxy.sol#L50-L60) uses assembly
	- [INLINE ASM](src/TransparentUpgradeableProxy.sol#L52-L59)

src/TransparentUpgradeableProxy.sol#L50-L60


 - [ ] ID-40
[TransparentUpgradeableProxy._setSlot(bytes32,address)](src/TransparentUpgradeableProxy.sol#L70-L74) uses assembly
	- [INLINE ASM](src/TransparentUpgradeableProxy.sol#L71-L73)

src/TransparentUpgradeableProxy.sol#L70-L74


 - [ ] ID-41
[TransparentUpgradeableProxy._getSlot(bytes32)](src/TransparentUpgradeableProxy.sol#L64-L68) uses assembly
	- [INLINE ASM](src/TransparentUpgradeableProxy.sol#L65-L67)

src/TransparentUpgradeableProxy.sol#L64-L68


## low-level-calls
Impact: Informational
Confidence: High
 - [ ] ID-42
Low level call in [TransparentUpgradeableProxy.constructor(address,address,bytes)](src/TransparentUpgradeableProxy.sol#L21-L31):
	- [(ok,ret) = implementation_.delegatecall(initData)](src/TransparentUpgradeableProxy.sol#L26)

src/TransparentUpgradeableProxy.sol#L21-L31


