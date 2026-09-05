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

**Deployment.** Each market is an implementation behind its own `TransparentUpgradeableProxy`. All
market state lives in the proxy's storage. The admin address owns upgrades and risk parameters. A
separate pause guardian exists so the market can be stopped quickly without reaching for the admin
key.

## Roles

| Role | Held by | Remit |
|---|---|---|
| `admin` | governance timelock | upgrades, risk parameters, wiring |
| `pauseGuardian` | operations multisig | stopping the market in an incident |

## Listed markets

See `script/Deploy.s.sol` for the current staging configuration and the collateral assets listed
against the base asset.
