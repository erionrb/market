# Execution Plan — LendingMarket Exercise

Working checklist. Phases are adaptive with no fixed durations.
Focused time is recorded per phase as the work progresses.

---
## 1. Discovery

- [x] Read `README.md` end to end (accounting model, scaling, borrowing power, liquidation, roles, deployment topology)
- [x] Read `src/TransparentUpgradeableProxy.sol` — proxy/admin pattern, storage slots, upgrade path
- [x] Read `src/LendingMarket.sol` in full — implementation, storage layout, all external/public functions
- [x] Read `src/interfaces/IERC20.sol` and `src/interfaces/IPriceOracle.sol` — assumed external contracts
- [x] Read `src/mocks/*.sol` — note `FeeOnTransferERC20.sol`, likely a hint about a transfer-accounting edge case
- [x] Read `test/LendingMarket.t.sol` — what's already covered vs. not
- [x] Read `script/Deploy.s.sol` — staging topology, listed markets, deployed parameters
- [x] Run `forge build` — confirm clean compile
    - Build succeeded with one test mutability warning.
- [x] Run `forge test` — confirm current suite passes, note gaps
    -  8/8 tests passing.
- [x] Run Slither — record raw output
    - Found multiple potential issues. Need to validate which ones are actually relevant.
- [x] Run Aderyn — record raw output
    - Found fewer issues than Slither, including 3 High findings.
    - Results differ from Slither and need manual validation.
- [x] Cross check Slither and Aderyn findings with manual and AI Review
- [x] Manually trace financially sensitive paths: supply, borrow, repay, withdraw, liquidate, accrueInterest(), index math, health check
    - Prioritized paths with direct user/protocol financial impact
    - Confirmed transfer accounting and liquidation pricing defects
    - Remaining lower-confidence hypotheses deferred to final review if time permits
- [x] Record security hypotheses (one line each: path,  suspectedissue, why) — no severity/classification yet
- [x] Note what "reserve factor" requirement implies given current accounting (no reserve logic found yet in README) — capture as open question, not a decision

### Security hypotheses

- supplyCollateral: looks like it is accounting the requested amount instead of what the contract actually receives
- supply / repay: the same assumption exists for the base token, need to check if it affects the current markets
- getPrice: need to check what happens with invalid oracle data
- accrueInterest: check rounding and what happens there when no supply
- liquidate: need to go deep into the liquidation math and what happens with bad debt
- ERC20 transfers: return values are not checked
- Reentrancy: some external calls happen before state updates, need to check if there is an actual exploitable path
- Proxy: still need to check storage layout and initializer

### Validation status

- `supplyCollateral / supply / repay / liquidate transfers`: Confirmed, was using the requested amount instead of the amount received by the market, fixed and tested.
- `liquidate`: Confirmed, was not using the collateral price to convert the repaid base amount into collateral units, fixed and tested.
- `Reentrancy`: the currently listed assets do not expose this behavior as per does not have callback function.
- Other potential issues left for later if still have time.

---

## 2. Validation

- [x] Rank hypotheses from Discovery by potential financial/protocol impact
- [ ] For each hypothesis (highest impact first): write a Foundry test/PoC that attempts to reproduce it
- [ ] Mark each hypothesis Confirmed (reproduced) or Rejected (could not demonstrate) — keep rejected ones with a one-line reason, don't delete
- [ ] Classify each confirmed finding by severity (Critical / High / Medium / Low / Info)
- [ ] Confirm scope of the reserve factor requirement (what accounting change it demands) before touching implementation

**Exit criteria:** every hypothesis has a verdict; confirmed findings have severity and a reproducing test.

---

## 3. Implementation

- [x] Fix confirmed findings, one at a time, minimal diff per fix
- [x] Implement the reserve factor accounting
- [x] Preserve all external interfaces (function signatures, events, roles)
- [x] Preserve storage layout / upgrade compatibility (append-only, no reordering/resizing existing slots)
- [x] No unrelated refactoring — resist drive-by cleanup
- [x] Run the relevant test subset after each individual change (`forge test --match-test` / `--match-contract`)

**Exit criteria:** all confirmed findings addressed, reserve factor implemented, each change independently test-verified.

---

## 4. Verification

- [ ] For each fix, confirm the reproducing test fails on pre-fix code and passes on post-fix code
- [ ] Add fuzz test(s) for the changed paths
- [ ] Add invariant test(s) covering the reserve/accounting invariant
- [ ] Verify storage/upgrade safety (layout diff / slot check against the proxy)
- [ ] Run the full Foundry suite (`forge test`)
- [ ] Re-run Slither and Aderyn on final code, compare against Discovery baseline

**Exit criteria:** full suite green, storage safety confirmed, static analysis re-run shows no new issues.

---

## 5. Review and QA

- [ ] Review the complete diff top to bottom
- [ ] Check every requirement from the exercise brief against the diff
- [ ] Finalize findings list and severities (Discovery → Validation → final state)
- [ ] Document reserve accounting decisions (why this design, alternatives considered)
- [ ] Document trade-offs, uncertainties, and intentionally omitted work
- [ ] Finalize `README.md` (reflect any new behavior, params, roles)
- [ ] Confirm repository is ready for submission (build, test, lint/static analysis all clean)

**Exit criteria:** diff reviewed, requirements checked off, findings + decisions documented, README current, repo clean.

---

## Time log

| Phase | Focused time |
|---|---|
| Discovery | 2h |
| Validation | |
| Implementation | |
| Verification | |
| Review and QA | |
| **Total** | |
