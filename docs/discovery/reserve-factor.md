# Implementation Discovery — Reserve Factor for `LendingMarket`

Status: discovery only. No code, no test files produced by this document.

## Goal

Let the protocol retain a configurable share of borrower-paid interest as **reserves**:
a flat accumulator in base-token units, an accrued protocol claim that earns nothing.
Borrowers are unaffected. Suppliers receive the remainder. Default behaviour (factor `0`)
must be byte-for-byte identical to today.

Scope constraints (from the brief, restated so the implementer does not have to re-derive them):

- Flat accumulator, **not** an index.
- No new role — `admin` owns the new controls.
- Append-only storage; existing slots unchanged.
- No unrelated fixes (pre-existing patterns are flagged here, not changed).
- `initialize()` is **not** modified.

---

## 1. Current `accrueInterest()` trace

Source: `src/LendingMarket.sol:133-150`.

```solidity
function accrueInterest() public {
    uint256 elapsed = block.timestamp - lastAccrualTime;          // L134
    if (elapsed == 0) return;                                     // L135  early-out

    uint256 interest = borrowRatePerSecond * elapsed;             // L137  simple (non-compounding) rate * time, 1e18

    uint256 borrowsBefore  = presentValueBorrow(totalBorrowPrincipal);   // L139  = totalBorrowPrincipal * baseBorrowIndex / 1e18
    uint256 suppliesBefore = presentValueSupply(totalSupplyPrincipal);   // L140  = totalSupplyPrincipal * baseSupplyIndex / 1e18

    baseBorrowIndex += (baseBorrowIndex * interest) / FACTOR;     // L142  BORROW INDEX UPDATE — unchanged by this work

    if (suppliesBefore > 0) {                                     // L144  "zero suppliers" guard
        uint256 accruedToSuppliers = (borrowsBefore * interest) / FACTOR;          // L145  <-- borrower-side interest amount
        baseSupplyIndex += (baseSupplyIndex * accruedToSuppliers) / suppliesBefore;// L146  <-- folded 100% into supply index
    }

    lastAccrualTime = block.timestamp;                            // L149
}
```

### The two indices

| Index | Update | Meaning |
|---|---|---|
| `baseBorrowIndex` (slot 5) | `+= baseBorrowIndex * interest / 1e18` (L142) | Grows every accrual whenever `interest > 0`. Drives `borrowBalanceOf` via `presentValueBorrow`. **This document does not touch it.** |
| `baseSupplyIndex` (slot 6) | `+= baseSupplyIndex * accruedToSuppliers / suppliesBefore` (L146), only inside the `suppliesBefore > 0` guard | Grows so that the aggregate supplier present value increases by exactly `accruedToSuppliers`. |

The two are **independent**. There is no exchange-rate identity binding them (no `cash + borrows == supplies` invariant enforced in code). Conservation of interest between the borrow and supply legs is *manual*: L145 computes an amount from the borrow side and L146 hands the same amount to the supply side. Reserves will insert a split at exactly this point.

### The exact line where borrower interest becomes supplier interest

**Line 145.** `accruedToSuppliers = (borrowsBefore * interest) / FACTOR` is the borrower-side
interest amount for this window (call it `borrowerInterest`). It is computed once, and line 146
immediately distributes 100% of it to suppliers through the supply-index bump. Today
`supplierInterest == borrowerInterest`. The reserve split is a wedge between L145 and L146.

Note `borrowerInterest` is *not* exactly the increase in `presentValueBorrow(totalBorrowPrincipal)`
produced by L142 — L142 rounds when it scales the index, then `presentValueBorrow` rounds again
when it scales principal. `borrowerInterest` is the existing rounded intermediate the brief tells
us to split, and it is what suppliers already receive today. This work changes nothing about that
approximation.

### Behaviour when `suppliesBefore == 0`

- L142 still runs: `baseBorrowIndex` advances, borrowers are still charged.
- The entire L144 block is skipped: `baseSupplyIndex` is **not** updated.
- Consequence today: any interest borrowers accrue during a zero-supply window is credited to
  **no one**. It is not stored, not deferred, not paid to the next supplier (who starts at the
  un-bumped `baseSupplyIndex`). It simply does not exist on the supply side.
- `suppliesBefore == 0` while `borrowsBefore > 0` is reachable: a sole supplier withdraws their
  full balance (cash permitting) while a borrower still owes. Then `totalSupplyPrincipal == 0` but
  `totalBorrowPrincipal > 0`.

---

## 2. Storage additions

### Baseline layout (captured now, `forge inspect src/LendingMarket.sol:LendingMarket storage-layout`)

| Slot | Off | Bytes | Name | Type |
|---|---|---|---|---|
| 0 | 0 | 20 | `admin` | address |
| 1 | 0 | 20 | `pauseGuardian` | address |
| 2 | 0 | 20 | `oracle` | contract IPriceOracle |
| 3 | 0 | 20 | `baseToken` | contract IERC20 |
| 4 | 0 | 20 | `collateralToken` | contract IERC20 |
| 5 | 0 | 32 | `baseBorrowIndex` | uint256 |
| 6 | 0 | 32 | `baseSupplyIndex` | uint256 |
| 7 | 0 | 32 | `lastAccrualTime` | uint256 |
| 8 | 0 | 32 | `totalSupplyPrincipal` | uint256 |
| 9 | 0 | 32 | `totalBorrowPrincipal` | uint256 |
| 10 | 0 | 32 | `totalCollateral` | uint256 |
| 11 | 0 | 32 | `collateralFactor` | uint256 |
| 12 | 0 | 32 | `liquidationIncentive` | uint256 |
| 13 | 0 | 32 | `borrowRatePerSecond` | uint256 |
| 14 | 0 | 32 | `supplyPrincipal` | mapping(address => uint256) |
| 15 | 0 | 32 | `borrowPrincipal` | mapping(address => uint256) |
| 16 | 0 | 32 | `collateralBalance` | mapping(address => uint256) |
| 17 | 0 | 1 | `paused` | bool |
| 17 | 1 | 1 | `_initialized` | bool |

### New variables

Appended immediately after `_initialized`, in the `--- circuit breaker ---` block or a new
`--- reserves ---` block below it:

```solidity
// --- reserves (appended; zero-initialised on the live proxy) ---
uint256 public   reserveFactor;   // 1e18-scaled fraction of borrower interest retained; 0 = disabled
uint256 internal totalReserves;   // flat accumulator, base-token units; read via reserves()
```

| Slot | Off | Bytes | Name | Type | Notes |
|---|---|---|---|---|---|
| 18 | 0 | 32 | `reserveFactor` | uint256 | `public` → auto getter `reserveFactor()` (satisfies the required view) |
| 19 | 0 | 32 | `totalReserves` | uint256 | `internal`; exposed through an explicit `reserves()` view (see §4) |

Design notes:

- Both are full 32-byte words. They cannot pack into slot 17 (30 free bytes) — a `uint256`
  always starts a fresh slot. Slots 18 and 19 are the first free slots.
- Order (`reserveFactor` then `totalReserves`) matches the brief. Either order is layout-safe;
  do not interleave them with anything else.
- `totalReserves` is `internal`, not `public`, on purpose: a `public totalReserves` would emit a
  getter named `totalReserves()`, but the required accessor is `reserves()`. One explicit view is
  cheaper than carrying a second, unspecified selector. `forge inspect ... storage-layout` still
  lists `internal` variables, so the verification below is unaffected.
- Zero-init: the live proxy has never written slots 18/19, so both read as `0` after the upgrade
  with no migration call. `reserveFactor == 0` is the "disabled" state.

### Verification procedure (append-only proof)

```bash
# before the change (on current HEAD)
forge inspect src/LendingMarket.sol:LendingMarket storage-layout > /tmp/layout.before.txt

# after the change
forge inspect src/LendingMarket.sol:LendingMarket storage-layout > /tmp/layout.after.txt

diff /tmp/layout.before.txt /tmp/layout.after.txt
```

Pass criteria:

1. Every row present in `layout.before.txt` appears in `layout.after.txt` with an **identical
   `Slot` and `Offset`** — `admin`..`_initialized` unchanged, slots 0–17 untouched.
2. The only new rows are `reserveFactor` at slot 18 offset 0 and `totalReserves` at slot 19
   offset 0.
3. No existing `uint256`/`address`/`bool`/mapping changed type or size.

Also confirm proxy safety: `TransparentUpgradeableProxy` keeps its own state in EIP-1967 hashed
slots (`0x3608...bbc`, `0xb531...103`), which do not collide with sequential slots 18/19. The
proxy declares no variables in the implementation's sequential layout range.

---

## 3. Accounting — current vs. new

Let `r = reserveFactor` (1e18-scaled), and within one `accrueInterest()` call:

```
borrowerInterest = (borrowsBefore * interest) / FACTOR      // existing L145 intermediate, unchanged
```

| Quantity | Current | New |
|---|---|---|
| `baseBorrowIndex` update | `+= baseBorrowIndex * interest / FACTOR` | **identical** |
| Reserve accrual | *(none)* | `reserveAccrued = (borrowerInterest * r) / FACTOR` (truncates); `totalReserves += reserveAccrued` — **outside** the `suppliesBefore > 0` guard |
| Supplier interest amount | `borrowerInterest` | `supplierInterest = borrowerInterest - reserveAccrued` |
| `baseSupplyIndex` update (inside `suppliesBefore > 0`) | `+= baseSupplyIndex * borrowerInterest / suppliesBefore` | `+= baseSupplyIndex * supplierInterest / suppliesBefore` |

New `accrueInterest()` body (from `baseBorrowIndex` update onward):

```solidity
baseBorrowIndex += (baseBorrowIndex * interest) / FACTOR;

uint256 borrowerInterest = (borrowsBefore * interest) / FACTOR;
uint256 reserveAccrued   = (borrowerInterest * reserveFactor) / FACTOR;
if (reserveAccrued != 0) totalReserves += reserveAccrued;

if (suppliesBefore > 0) {
    uint256 supplierInterest = borrowerInterest - reserveAccrued;
    baseSupplyIndex += (baseSupplyIndex * supplierInterest) / suppliesBefore;
}

lastAccrualTime = block.timestamp;
```

The `borrowerInterest` computation is **hoisted out** of the guard (today it lives at L145 inside
the `if`) because reserves must accrue even with zero suppliers.

### Proof that `r == 0` preserves current accounting

Substitute `reserveFactor = 0`:

- `reserveAccrued = (borrowerInterest * 0) / FACTOR = 0`.
- `if (reserveAccrued != 0)` is false → `totalReserves` is never written, stays `0`. No extra
  SSTORE, so gas is also unchanged.
- `supplierInterest = borrowerInterest - 0 = borrowerInterest` — exactly the old `accruedToSuppliers`.
- `baseSupplyIndex` update is then `+= baseSupplyIndex * borrowerInterest / suppliesBefore`,
  identical to L146.
- `baseBorrowIndex` update and `lastAccrualTime` write are untouched in every branch.

Every storage slot receives the same value it does today. ∎

(The `if (reserveAccrued != 0)` guard is semantically equivalent to an unconditional
`totalReserves += reserveAccrued` — it only skips a `+= 0` write. It is recommended for exact gas
parity in the disabled state. If the implementer prefers the literal brief wording, an
unconditional `totalReserves += reserveAccrued;` is also correct.)

### Behaviour at `r == 1e18`

- `reserveAccrued = borrowerInterest`.
- `supplierInterest = borrowerInterest - borrowerInterest = 0`.
- `baseSupplyIndex += baseSupplyIndex * 0 / suppliesBefore = 0` → supply index frozen for that
  accrual; suppliers earn nothing.
- 100% of borrower interest flows to `totalReserves`.
- Borrowers still pay the same (`baseBorrowIndex` unchanged). Allowed by `require(r <= 1e18)`.
  This is a valid but aggressive governance setting — see §9.

### Behaviour at zero suppliers (`suppliesBefore == 0`)

- `baseBorrowIndex` advances (borrowers charged) — unchanged.
- `reserveAccrued` is added to `totalReserves` when `r > 0` (the accrual is now outside the guard).
- The `suppliesBefore > 0` block is still skipped, so the `supplierInterest` remainder in that
  window is credited to no one — exactly as the full amount is dropped today.
- With `r == 0`: `reserveAccrued == 0`, nothing is written, behaviour is identical to today.
- **This is a real behaviour change vs. today, but only when `r > 0`**: the protocol now captures
  its share of interest during zero-supply windows that previously benefited nobody. It is
  consistent with the manual-conservation model (two independent indices). Documented here, not
  silent. See §9.

---

## 4. API

All four are added; none is `whenNotPaused` (reserve management must work during an incident,
matching `setParameters` / `setOracle` / `setPaused`, none of which gate on `paused`).

Access-control note / brief inconsistency: the brief says "matching `setParameters`/`setOracle`",
but `setParameters` is `onlyAdmin` while `setOracle` is `onlyGuardian`. Reserves are protocol
funds and protocol economics, so **both mutating functions are `onlyAdmin`** (aligned with
`setParameters`). Flagged rather than silently chosen.

### `reserveFactor() view` — auto getter

`public` state variable `reserveFactor` generates it. Returns the stored 1e18-scaled factor. No
modifiers.

### `reserves() external view returns (uint256)`

Returns stored `totalReserves` verbatim. **Deliberately stale** between accruals — it does not
call `accrueInterest()` and does not project pending reserve accrual. No modifiers. Callers who
want a fresh figure call `accrueInterest()` first (consistent with how `borrowBalanceOf` /
`supplyBalanceOf` read stale indices).

### `setReserveFactor(uint256 newReserveFactor) external onlyAdmin`

| # | Step | Detail |
|---|---|---|
| 1 | **accrue** | `accrueInterest();` — pending interest is split under the **old** factor before the new one takes effect. Prevents a factor change from retroactively re-taxing already-earned interest. |
| 2 | **validate** | `require(newReserveFactor <= FACTOR, "reserve factor too high");` |
| 3 | **write** | `reserveFactor = newReserveFactor;` |
| 4 | **emit** | `emit ReserveFactorSet(newReserveFactor);` |

Ordering is accrue → validate → write → emit. Accrue precedes validate per the brief; a
validate-first variant would save one accrual SSTORE on a reverting call but the brief is explicit
("accrue first"). No `whenNotPaused`.

### `withdrawReserves(address recipient, uint256 amount) external onlyAdmin`

| # | Step | Detail |
|---|---|---|
| 1 | **accrue** | `accrueInterest();` — realise pending reserve accrual so a withdrawal can draw against the up-to-date balance. |
| 2 | **validate** | `require(amount <= totalReserves, "amount exceeds reserves");` |
| 3 | **validate** | `require(amount <= baseToken.balanceOf(address(this)), "insufficient liquidity");` — reserves are an accrued claim, not segregated cash; the market may not hold enough. |
| 4 | **write** | `totalReserves -= amount;` — state effect **before** the external call (checks-effects-interactions). |
| 5 | **transfer** | `baseToken.transfer(recipient, amount);` |
| 6 | **emit** | `emit ReservesWithdrawn(recipient, amount);` |

Ordering is accrue → validate → validate → write → transfer → emit.

Guards intentionally **not** added (brief lists exactly the five operations above; "no new
decisions"):

- No `amount > 0` check — a zero withdraw transfers 0 and emits; harmless. Sibling functions guard
  it; noted in §9 as optional hardening.
- No `recipient != address(0)` check — `setOracle` / `setAdmin` zero-check, this does not. A
  zero-address transfer burns reserves and still decrements `totalReserves`; admin error, not a
  protocol vulnerability. Noted in §9.
- `baseToken.transfer` return value not checked — consistent with every other transfer in the
  contract (§9, pre-existing pattern, out of scope).

---

## 5. Events

```solidity
event ReserveFactorSet(uint256 reserveFactor);
event ReservesWithdrawn(address indexed recipient, uint256 amount);
```

| Event | Emitted in | Emit point | Args |
|---|---|---|---|
| `ReserveFactorSet` | `setReserveFactor` | last statement, after the state write | new factor, not indexed (matches `ParametersUpdated`, which indexes none of its `uint256`s) |
| `ReservesWithdrawn` | `withdrawReserves` | last statement, after the transfer | `recipient` indexed, `amount` not indexed (matches `Withdraw(address indexed, uint256)`) |

`ReserveFactorSet` is named by the brief. `ReservesWithdrawn` is **not** in the brief — it is
recommended here for parity (every other state-mutating function emits) and marked as a
recommendation. If the implementer wants to stay strictly literal, omitting it is defensible but
worsens observability of reserve outflows.

No new event is needed in `accrueInterest()` — it emits nothing today and the reserve split is an
internal bookkeeping change.

---

## 6. Implementation map

### Existing code that changes

| Location | Change | Size |
|---|---|---|
| Storage block (`src/LendingMarket.sol` after `_initialized`, ~L60) | Append `reserveFactor` (public) and `totalReserves` (internal). | +2 lines |
| Events block (~L64-75) | Add `ReserveFactorSet`, `ReservesWithdrawn`. | +2 lines |
| `accrueInterest()` (L133-150) | Hoist `borrowerInterest` above the `suppliesBefore > 0` guard; add `reserveAccrued` + guarded `totalReserves +=`; inside the guard replace `accruedToSuppliers` with `supplierInterest = borrowerInterest - reserveAccrued`. Delete the old L145 line. | ~4 net lines |

Nothing else in the existing contract is edited. `initialize()`, `supply`, `withdraw`, `borrow`,
`repay`, `liquidate`, all views, `_principalFor*`, `setParameters`, `setOracle`, `setPaused`,
`setAdmin` are untouched.

### Functions to add

| Function | Where | Notes |
|---|---|---|
| `reserves()` | Views section (near `supplyBalanceOf`, ~L307) | `external view`, returns `totalReserves` |
| `setReserveFactor(uint256)` | Administration section, right after `setParameters` (~L381) | `onlyAdmin`, steps per §4 |
| `withdrawReserves(address,uint256)` | Administration section, after `setReserveFactor` | `onlyAdmin`, steps per §4 |
| `reserveFactor()` | — | no code; generated by the `public` variable |

### Out of scope for this change (note, do not do)

- `script/Deploy.s.sol` — unchanged. Markets deploy with `reserveFactor == 0`. A post-deploy
  `setReserveFactor` call could be added later by governance; not part of this work.
- `README.md` / `docs/execution-plan.md` — updated in the Review/QA phase, not here.
- The existing `test/LendingMarket.t.sol` suite — must pass **unmodified** (factor defaults to 0).

---

## 7. Unit tests (names + what each proves)

Discovery only — these are specified, not written.

| Test | Proves |
|---|---|
| `test_reserveFactorDefaultsToZero` | After `initialize`, `reserveFactor() == 0` and `reserves() == 0`; no migration needed. |
| `test_factorZeroLeavesSupplyAndBorrowAccountingUnchanged` | With factor 0, borrow/supply balances after `warp + accrueInterest` equal a baseline market instance to the wei; `reserves() == 0`. Guards the "identical behaviour" requirement. |
| `test_factorZeroDoesNotWriteReserves` | `reserves()` stays 0 across many accruals with borrows outstanding and factor 0. |
| `test_setReserveFactorAccruesUnderOldFactorFirst` | Interest pending when `setReserveFactor` is called is split under the previous factor, not the new one (set 0 → 0.5e18 after a warp; the just-accrued chunk went 100% to suppliers). |
| `test_setReserveFactorRejectsAboveOne` | Reverts `"reserve factor too high"` at `1e18 + 1`; succeeds at exactly `1e18`. |
| `test_setReserveFactorOnlyAdmin` | Non-admin (guardian, supplier, random) reverts `"not admin"`. |
| `test_setReserveFactorWorksWhilePaused` | Guardian pauses; admin still sets the factor. |
| `test_reserveAccruesShareOfBorrowerInterest` | Factor `0.1e18`, borrow, warp, accrue: `reserves()` increased by `borrowerInterest * 0.1e18 / 1e18` exactly; supplier present value increased by the remaining ~90%. |
| `test_factorOneSendsAllInterestToReserves` | Factor `1e18`: `baseSupplyIndex` unchanged across an accrual with suppliers present; `reserves()` grew by full `borrowerInterest`; borrower debt grew the same as with factor 0. |
| `test_reservesAccrueWithZeroSuppliers` | Sole supplier withdraws everything, borrow remains, factor `0.2e18`, warp, accrue: `totalReserves` increases; `baseSupplyIndex` unchanged. |
| `test_reservesDoNotAccrueWithZeroSuppliersWhenFactorZero` | Same setup, factor 0: `reserves()` stays 0 (behaviour identical to today). |
| `test_reserveSplitConservesBorrowerInterest` | Fuzzed odd `borrowsBefore`/`interest`/factor: `supplierInterest + reserveAccrued == borrowerInterest`, and the truncation remainder is on the supplier side (`supplierInterest >= borrowerInterest * (1e18 - r) / 1e18`). |
| `test_reservesEarnNothing` | Accrue, record `reserves()`, warp far, accrue again with **no borrows**: `reserves()` unchanged (flat accumulator, not an index). |
| `test_reserves_viewIsStaleBetweenAccruals` | After a warp but before `accrueInterest`, `reserves()` returns the old value; after `accrueInterest` it jumps. Documents the deliberate staleness. |
| `test_withdrawReservesTransfersAndReduces` | Accrue reserves, `withdrawReserves(recipient, x)`: `totalReserves` down by `x`, `recipient` base balance up by `x`. |
| `test_withdrawReservesAccruesFirst` | Pending reserve accrual is realised, then withdrawn in one call (withdraw an amount only valid post-accrual). |
| `test_withdrawReservesRejectsAboveReserves` | `amount = reserves() + 1` reverts `"amount exceeds reserves"`. |
| `test_withdrawReservesRejectsAboveLiquidity` | Reserves accrued but cash borrowed out so `balanceOf(market) < reserves()`: reverts `"insufficient liquidity"`. |
| `test_withdrawReservesOnlyAdmin` | Non-admin reverts. |
| `test_withdrawReservesWorksWhilePaused` | Paused market; admin still withdraws. |
| `test_withdrawReservesEmitsEvent` / `test_setReserveFactorEmitsEvent` | Event signature and args. |
| `test_withdrawReservesToArbitraryRecipient` | `recipient` need not be admin; funds land at the passed address. |

---

## 8. Invariant / fuzz test (required)

### The invariant to enforce

**Protocol solvency:**

```
baseToken.balanceOf(address(market))
    + presentValueBorrow(totalBorrowPrincipal)
>=  presentValueSupply(totalSupplyPrincipal)
    + totalReserves
```

Cash on hand plus everything owed to the market covers everything the market owes to suppliers
**plus the protocol's reserve claim**. This is the one property that catches a reserve-accounting
bug: if the split double-counts interest (credits suppliers *and* reserves the same amount), or
carves reserves without shrinking the supplier share, or lets `withdrawReserves` pay out more than
is backed, this inequality breaks. Name it `invariant_protocolSolvency`.

### Handler

Bounded-fuzz actions over a pool of actors, each optionally preceded by a `vm.warp`:
`supply`, `withdraw`, `supplyCollateral`, `withdrawCollateral`, `borrow`, `repay`, `liquidate`
(with oracle moves), `accrueInterest`, `setReserveFactor` (0..1e18), `withdrawReserves`.

### Supporting properties (secondary invariants / assertions)

1. **`totalReserves` is non-decreasing except in `withdrawReserves`.** Track `reserves()` before
   and after every handler call; the value may only drop when the call was `withdrawReserves`, and
   then by exactly the withdrawn `amount`.
2. **Factor 0 tracks baseline `baseSupplyIndex`.** Run a shadow `LendingMarket` instance driven by
   the same supply/borrow/time actions but with `reserveFactor` pinned at 0. Assert
   `market.baseSupplyIndex() == shadow.baseSupplyIndex()` and
   `market.baseBorrowIndex() == shadow.baseBorrowIndex()` whenever the primary market's factor has
   been 0 for the whole run.
3. **Reserves earn nothing.** Between two consecutive `accrueInterest` calls with
   `totalBorrowPrincipal == 0`, `reserves()` is unchanged.
4. **`baseBorrowIndex` is factor-independent.** For a fixed action/time sequence, the borrow index
   series is identical for any `reserveFactor` schedule.

### Fuzz (stateless) test

`testFuzz_reserveSplitConserves(uint256 borrowsBefore, uint256 interest, uint256 r)` — bound
inputs to realistic ranges, compute `borrowerInterest`, `reserveAccrued`, `supplierInterest` with
the production formulas, assert `supplierInterest + reserveAccrued == borrowerInterest` and
`reserveAccrued == borrowerInterest * r / 1e18` and `0 <= supplierInterest <= borrowerInterest`.

---

## 9. Risks

### Rounding

- `reserveAccrued = (borrowerInterest * reserveFactor) / FACTOR` truncates toward zero.
- `supplierInterest = borrowerInterest - reserveAccrued` is a **subtraction**, not an independent
  division. Therefore `supplierInterest + reserveAccrued == borrowerInterest` holds **exactly**,
  for every input. No wei is created or destroyed by the split.
- The truncation remainder (`borrowerInterest * reserveFactor mod FACTOR`, scaled) stays on the
  **supplier** side. The protocol rounds itself down; users are never shorted by the split.
- `borrowerInterest` is itself the pre-existing rounded intermediate (`borrowsBefore * interest /
  FACTOR`) and is already an approximation of the true `baseBorrowIndex`-driven debt increase.
  This work does not change that approximation — it only divides the same number two ways.

### Insufficient liquidity on withdrawal

Reserves are an **accrued claim**, not ring-fenced cash. When utilisation is high, `balanceOf(market)`
can be below `totalReserves` and `withdrawReserves` reverts on the step-3 check. The admin must
wait for repayments or new supply. This is the same liquidity constraint a supplier faces at 100%
utilisation and is intended, not a bug.

### Reserve claim vs. cash trade-off

Every unit in `totalReserves` is a claim on the *same* base-token pool suppliers withdraw from,
and it is effectively senior (a fixed base-token amount, not subject to the supply index). Two
effects:

- Accruing reserves slows `baseSupplyIndex` growth — suppliers earn strictly less than today when
  `r > 0`. Intended.
- `withdrawReserves` removes cash, raising utilisation and the chance a supplier cannot withdraw.
  Governance should size withdrawals against current liquidity.

### Zero-suppliers window with `r > 0`

Reserves capture their share during windows where `suppliesBefore == 0`; the supplier remainder in
those windows is still credited to nobody (the supply-index bump stays behind the
`suppliesBefore > 0` guard, per the brief). This is a genuine behaviour change from today (where
the whole amount vanishes) but only activates when `r > 0`. Consistent with the manual-conservation
model. Not silent — see §3.

### `reserveFactor == 1e18`

Permitted by `require(r <= FACTOR)`. Suppliers then earn **zero** interest while still bearing
counterparty risk. Not a solvency risk, but a severe economic setting; treat the bound as
"governance can do this on purpose", and consider a lower operational cap in deployment docs.

### Storage compatibility

Append-only at slots 18/19; slots 0–17 provably unchanged via the `forge inspect` diff in §2.
Proxy uses hashed EIP-1967 slots that do not collide. The main failure mode would be a future
upgrade that inserts a variable *before* `reserveFactor` — the layout diff in CI guards against
that.

### Pre-existing patterns left untouched (brief: no unrelated fixes)

- `baseToken.transfer` return value ignored in `withdrawReserves`, matching `withdraw` / `borrow`
  / `liquidate`. A base token that returns `false` instead of reverting would desync
  `totalReserves` from cash. Pre-existing repo-wide; flag only.
- No `amount > 0` / `recipient != address(0)` guards on `withdrawReserves` (sibling functions have
  the equivalents). Optional hardening; not added because the brief enumerates the exact steps.

---

## 10. Ordered implementation checklist

No open decisions remain; follow in order.

1. Branch from current `main` (or the working branch with the confirmed bug fixes).
2. Capture baseline layout: `forge inspect src/LendingMarket.sol:LendingMarket storage-layout > /tmp/layout.before.txt`.
3. **Storage:** after `_initialized`, append
   `uint256 public reserveFactor;` then `uint256 internal totalReserves;`. Move nothing else.
4. **Events:** in the events block add
   `event ReserveFactorSet(uint256 reserveFactor);` and
   `event ReservesWithdrawn(address indexed recipient, uint256 amount);`.
5. **`accrueInterest()`:** after the `baseBorrowIndex += ...` line:
   - add `uint256 borrowerInterest = (borrowsBefore * interest) / FACTOR;`
   - add `uint256 reserveAccrued = (borrowerInterest * reserveFactor) / FACTOR;`
   - add `if (reserveAccrued != 0) totalReserves += reserveAccrued;`
   - inside `if (suppliesBefore > 0)`: replace the two lines with
     `uint256 supplierInterest = borrowerInterest - reserveAccrued;`
     `baseSupplyIndex += (baseSupplyIndex * supplierInterest) / suppliesBefore;`
   - delete the old `uint256 accruedToSuppliers = ...;` line.
6. Do **not** edit `initialize()`.
7. **Views:** add
   `function reserves() external view returns (uint256) { return totalReserves; }`
   in the Views section.
8. **Administration:** after `setParameters`, add:
   ```solidity
   function setReserveFactor(uint256 newReserveFactor) external onlyAdmin {
       accrueInterest();
       require(newReserveFactor <= FACTOR, "reserve factor too high");
       reserveFactor = newReserveFactor;
       emit ReserveFactorSet(newReserveFactor);
   }

   function withdrawReserves(address recipient, uint256 amount) external onlyAdmin {
       accrueInterest();
       require(amount <= totalReserves, "amount exceeds reserves");
       require(amount <= baseToken.balanceOf(address(this)), "insufficient liquidity");
       totalReserves -= amount;
       baseToken.transfer(recipient, amount);
       emit ReservesWithdrawn(recipient, amount);
   }
   ```
9. `forge build` — clean compile.
10. `forge test` — the existing suite passes **unmodified** (factor defaults to 0).
11. Capture new layout: `forge inspect ... storage-layout > /tmp/layout.after.txt`; `diff` against
    `/tmp/layout.before.txt`; confirm slots 0–17 identical, only slots 18/19 added.
12. Add the unit tests from §7 and the solvency invariant + supporting properties from §8 in a new
    test file (e.g. `test/ReserveFactor.t.sol`); do not modify `test/LendingMarket.t.sol`.
13. `forge test` full suite green.
14. Re-run Slither and Aderyn; diff against the discovery baseline in `docs/security/`; confirm no
    new findings on `accrueInterest` / the new functions.
15. Update `README.md` (reserves concept, `reserveFactor` param, `admin` remit) and tick the
    reserve-factor boxes in `docs/execution-plan.md`.
