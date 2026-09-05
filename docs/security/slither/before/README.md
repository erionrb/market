# Slither Commands used

```sh
forge clean

forge build --force

slither . --compile-force-framework foundry --filter-paths "test|mocks|lib" --checklist > docs/security/slither/before/full.md

slither . --compile-force-framework foundry --filter-paths "test|mocks|lib" --json docs/security/slither/before/full.json

slither . --compile-force-framework foundry --filter-paths "test|mocks|lib" --detect reentrancy-eth,reentrancy-no-eth --checklist > docs/security/slither/before/reentrancy-real.md

slither . --compile-force-framework foundry --filter-paths "test|mocks|lib" --detect reentrancy-events --checklist > docs/security/slither/before/reentrancy-events.md

slither-check-upgradeability . LendingMarket --proxy-name TransparentUpgradeableProxy > docs/security/slither/before/upgradeability.md
```

```sh
forge clean

forge build --force

slither . --compile-force-framework foundry --filter-paths "test|mocks|lib" --checklist > docs/security/slither/after/full.md

slither . --compile-force-framework foundry --filter-paths "test|mocks|lib" --json docs/security/slither/after/full.json

slither . --compile-force-framework foundry --filter-paths "test|mocks|lib" --detect reentrancy-eth,reentrancy-no-eth --checklist > docs/security/slither/after/reentrancy-real.md

slither . --compile-force-framework foundry --filter-paths "test|mocks|lib" --detect reentrancy-events --checklist > docs/security/slither/after/reentrancy-events.md

slither-check-upgradeability . LendingMarket --proxy-name TransparentUpgradeableProxy > docs/security/slither/after/upgradeability.md
```