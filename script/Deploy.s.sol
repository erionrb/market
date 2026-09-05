// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {LendingMarket} from "../src/LendingMarket.sol";
import {TransparentUpgradeableProxy} from "../src/TransparentUpgradeableProxy.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {FeeOnTransferERC20} from "../src/mocks/FeeOnTransferERC20.sol";
import {MockOracle} from "../src/mocks/MockOracle.sol";

/**
 * @notice Deployment used for staging. Mirrors the production topology: one implementation
 *         behind a transparent proxy per market, sharing an admin and a pause guardian.
 *
 *         Two markets are listed today:
 *           - WETH  : plain 18-decimal collateral, priced at 2,000 base
 *           - STRM  : a partner reward token that takes a 2% fee on transfer, priced at 5 base
 */
contract Deploy {
    uint256 internal constant FACTOR = 1e18;

    address public admin = address(0xA11CE);
    address public pauseGuardian = address(0x6DA12D);

    LendingMarket public wethMarket;
    LendingMarket public strmMarket;

    MockERC20 public base;
    MockERC20 public weth;
    FeeOnTransferERC20 public strm;

    MockOracle public wethOracle;
    MockOracle public strmOracle;

    function run() external {
        base = new MockERC20("Base USD", "bUSD", 18);
        weth = new MockERC20("Wrapped Ether", "WETH", 18);
        strm = new FeeOnTransferERC20("Stream Reward", "STRM", 200);

        wethOracle = new MockOracle(2_000e18);
        strmOracle = new MockOracle(5e18);

        wethMarket = _deployMarket(address(weth), address(wethOracle), 0.80e18, 1.10e18);
        strmMarket = _deployMarket(address(strm), address(strmOracle), 0.50e18, 1.15e18);
    }

    function _deployMarket(address collateral, address oracle, uint256 collateralFactor, uint256 incentive)
        internal
        returns (LendingMarket)
    {
        LendingMarket impl = new LendingMarket();

        bytes memory initData = abi.encodeCall(
            LendingMarket.initialize,
            (
                admin,
                pauseGuardian,
                oracle,
                address(base),
                collateral,
                collateralFactor,
                incentive,
                // ~5% APR expressed per second
                uint256(0.05e18) / 365 days
            )
        );

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(impl), admin, initData);

        return LendingMarket(address(proxy));
    }
}
