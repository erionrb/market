# LendingMarket

Single-collateral money market. Suppliers deposit the base asset and earn interest, borrowers post
collateral and draw the base asset against it, and positions that fall below their borrowing power
can be liquidated.

## Running it

The project is self-contained. `forge-std` is vendored under `lib/`, so no network access or
`forge install` is needed.

```bash
forge build
forge test
forge test -vvv --match-test <name>     # a single test, with traces
```

Requires Foundry. If you do not have it: `curl -L https://foundry.paradigm.xyz | bash && foundryup`

## Layout

```
src/
  LendingMarket.sol                 the implementation
  TransparentUpgradeableProxy.sol   the proxy the market is deployed behind
  interfaces/                       IERC20, IPriceOracle (Chainlink-style aggregator)
  mocks/                            test doubles for the base asset, collateral and oracle
script/
  Deploy.s.sol                      staging deployment, mirrors the production topology
test/
  LendingMarket.t.sol               the suite the market ships with today
  ReserveFactor.t.sol               reserve-factor unit tests + solvency invariant
docs/
  discovery/reserve-factor.md       implementation discovery doc for the reserve factor
```

## How it works

**Accounting.** Supplier and borrower balances are stored as *principal* and scaled by two global
indices, `baseSupplyIndex` and `baseBorrowIndex`. `accrueInterest()` advances both to the current
timestamp. Present value is `principal * index / 1e18`.

**Scaling.** Everything is 1e18 fixed point unless stated otherwise. The oracle quotes collateral
in base-asset terms, also 1e18.

**Borrowing power.** `collateralBalance * price * collateralFactor`, all 1e18 scaled. A position is
healthy while its borrowing power covers its debt. `isHealthy()` is the single source of truth for
this and is checked on any path that increases risk.

**Liquidation.** Once a position is unhealthy, anyone may repay part of its debt and receive
collateral in exchange, plus the liquidation incentive.

**Reserves.** `accrueInterest()` splits the interest borrowers pay: a `reserveFactor` fraction
(1e18-scaled) is retained by the protocol as `totalReserves`, the rest goes to suppliers through
`baseSupplyIndex` as before. Borrowers are unaffected — `baseBorrowIndex` is untouched. Reserves
are a flat accumulator in base-token units (not an index, they earn nothing). `reserveFactor`
defaults to `0`, which reproduces the original accounting exactly. The admin sets the factor with
`setReserveFactor()` and pulls accrued reserves with `withdrawReserves()`; both accrue first and
are callable while the market is paused. `reserves()` returns the stored total (stale between
accruals by design).

**Deployment.** Each market is an implementation behind its own `TransparentUpgradeableProxy`. All
market state lives in the proxy's storage. The admin address owns upgrades and risk parameters. A
separate pause guardian exists so the market can be stopped quickly without reaching for the admin
key.

## Roles

| Role | Held by | Remit |
|---|---|---|
| `admin` | governance timelock | upgrades, risk parameters, wiring, reserve factor, reserve withdrawals |
| `pauseGuardian` | operations multisig | stopping the market in an incident |

## Listed markets

See `script/Deploy.s.sol` for the current staging configuration and the collateral assets listed
against the base asset.

## Dev notes

## Findings

### High — Incorrect accounting for fee-on-transfer tokens

Incoming token transfers were accounted using the requested amount instead of the
amount actually received by the market. With fee-on-transfer assets this could
overstate collateral, supply or repayment balances and break the market accounting,
potentially leaving the protocol with liabilities that are not fully backed by tokens.

The affected pull paths now account using the actual balance delta received by the market.

### High — Incorrect collateral amount seized during liquidation

`liquidate()` calculated the seized collateral directly from the repaid base amount
and liquidation incentive, without converting that value using the collateral price.
This could cause a liquidator to seize more collateral than the repayment economically
entitles them to, directly causing losses to borrowers during liquidation.

The liquidation calculation now converts the repaid base value into collateral units
using the oracle price before applying the collateral balance cap.

### Reserve-factor

Verification procedure ran before and after the storage changes:
```bash
forge inspect src/LendingMarket.sol:LendingMarket storage-layout
```

`reserveFactor` (slot 18) and `totalReserves` (slot 19) were appended after `_initialized`.

**Layout before the reserve-factor change**

```
╭----------------------+-----------------------------+------+--------+-------+-------------------------------------╮
| Name                 | Type                        | Slot | Offset | Bytes | Contract                            |
+==================================================================================================================+
| admin                | address                     | 0    | 0      | 20    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| pauseGuardian        | address                     | 1    | 0      | 20    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| oracle               | contract IPriceOracle       | 2    | 0      | 20    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| baseToken            | contract IERC20             | 3    | 0      | 20    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| collateralToken      | contract IERC20             | 4    | 0      | 20    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| baseBorrowIndex      | uint256                     | 5    | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| baseSupplyIndex      | uint256                     | 6    | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| lastAccrualTime      | uint256                     | 7    | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| totalSupplyPrincipal | uint256                     | 8    | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| totalBorrowPrincipal | uint256                     | 9    | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| totalCollateral      | uint256                     | 10   | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| collateralFactor     | uint256                     | 11   | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| liquidationIncentive | uint256                     | 12   | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| borrowRatePerSecond  | uint256                     | 13   | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| supplyPrincipal      | mapping(address => uint256) | 14   | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| borrowPrincipal      | mapping(address => uint256) | 15   | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| collateralBalance    | mapping(address => uint256) | 16   | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| paused               | bool                        | 17   | 0      | 1     | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| _initialized         | bool                        | 17   | 1      | 1     | src/LendingMarket.sol:LendingMarket |
╰----------------------+-----------------------------+------+--------+-------+-------------------------------------╯
```

**Layout after the reserve-factor change**

```
╭----------------------+-----------------------------+------+--------+-------+-------------------------------------╮
| Name                 | Type                        | Slot | Offset | Bytes | Contract                            |
+==================================================================================================================+
| admin                | address                     | 0    | 0      | 20    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| pauseGuardian        | address                     | 1    | 0      | 20    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| oracle               | contract IPriceOracle       | 2    | 0      | 20    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| baseToken            | contract IERC20             | 3    | 0      | 20    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| collateralToken      | contract IERC20             | 4    | 0      | 20    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| baseBorrowIndex      | uint256                     | 5    | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| baseSupplyIndex      | uint256                     | 6    | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| lastAccrualTime      | uint256                     | 7    | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| totalSupplyPrincipal | uint256                     | 8    | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| totalBorrowPrincipal | uint256                     | 9    | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| totalCollateral      | uint256                     | 10   | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| collateralFactor     | uint256                     | 11   | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| liquidationIncentive | uint256                     | 12   | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| borrowRatePerSecond  | uint256                     | 13   | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| supplyPrincipal      | mapping(address => uint256) | 14   | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| borrowPrincipal      | mapping(address => uint256) | 15   | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| collateralBalance    | mapping(address => uint256) | 16   | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| paused               | bool                        | 17   | 0      | 1     | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| _initialized         | bool                        | 17   | 1      | 1     | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| reserveFactor        | uint256                     | 18   | 0      | 32    | src/LendingMarket.sol:LendingMarket |
|----------------------+-----------------------------+------+--------+-------+-------------------------------------|
| totalReserves        | uint256                     | 19   | 0      | 32    | src/LendingMarket.sol:LendingMarket |
╰----------------------+-----------------------------+------+--------+-------+-------------------------------------╯
```
