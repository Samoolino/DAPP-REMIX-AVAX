# Remix Contract Workflow — Avalanche Flashloan Control Plane

## Purpose

The control plane is the contract library and execution guide. Remix remains the authoritative Solidity IDE for loading, editing, compiling, deploying, and interacting with contracts.

The DApp must expose every contract with:

1. A stable contract name and family.
2. The exact repository source path.
3. A full-source copy area.
4. A direct **Open in Remix** deep link that loads that exact GitHub file into Remix's `code-sample` workspace.
5. A GitHub source link.
6. Compiler/version information.
7. Constructor inputs.
8. Required provider/pair/router/token configuration.
9. A controlled execution procedure.
10. Explicit assurance status.

## Important distinction

`Open in Remix` loads the source file into a temporary Remix workspace. It does not mean the contract is deployed, verified, funded, profitable, or ready for mainnet execution. Save/rename the Remix workspace if you want to preserve the imported file.

## Current contract library

### 1. AaveV3FlashArbitrage

- File: `contracts/AaveV3FlashArbitrage.sol`
- Compiler: Solidity `0.8.10`
- Family: Aave V3 flashloan + one approved V2-style router
- Constructor: `poolAddress`, `minimumProfit`
- Procedure:
  1. Open the exact source in Remix.
  2. Select compiler `0.8.10`.
  3. Compile `AaveV3FlashArbitrage.sol`.
  4. Verify the exact Avalanche Aave V3 pool address for the target network.
  5. Deploy with the verified pool and minimum-profit floor.
  6. Add only verified router addresses with `setRouter`.
  7. Verify token decimals, asset support, route, `minAmountOut`, deadline and premium.
  8. Run on Fuji or a controlled fork first.
  9. Confirm callback repayment and `FlashLoanSettled` event.
  10. Only then consider a bounded mainnet transaction.

### 2. AaveV3TwoRouterArbitrage

- File: `contracts/archive/AaveV3TwoRouterArbitrage.sol`
- Compiler: Solidity `0.8.10`
- Family: Aave V3 flashloan + two-router round trip
- Constructor: `poolAddress`, `minimumProfit`
- Procedure:
  1. Open the exact source in Remix.
  2. Compile with `0.8.10`.
  3. Verify the Aave V3 pool and both DEX routers on Avalanche.
  4. Deploy with the verified pool and minimum-profit floor.
  5. Approve exactly two verified routers through `setRouter`.
  6. Build `pathA` from borrowed asset to intermediate token and `pathB` back to borrowed asset.
  7. Set both minimum outputs and a short valid deadline.
  8. Test repayment + premium + minimum profit on Fuji/controlled fork.
  9. Confirm events, gas, balances and pause/rescue paths.
  10. Mainnet use remains gated until all addresses and economics are verified.

### 3. PangolinTwoRouterArbitrage

- File: `contracts/archive/external/PangolinTwoRouterArbitrage.sol`
- Compiler: Solidity `0.8.20` or the exact compatible compiler selected by the source pragma.
- Family: Pangolin/V2-style pair flash swap + two routers
- Constructor: `pairAddress`, `minimumProfit`
- Procedure:
  1. Open the exact source in Remix.
  2. Verify the actual deployed pair implements the expected `swap` callback pattern.
  3. Verify `token0`, `token1`, router addresses and fee model.
  4. Compile and deploy with the verified pair.
  5. Allowlist only the two verified routers.
  6. Configure a borrowed asset that is actually one side of the pair.
  7. Configure path A and path B so the route returns to the borrowed asset.
  8. Set conservative minimum outputs and deadline.
  9. Validate the pair's actual repayment formula before any controlled test. The template currently assumes a V2-style 0.3% fee and explicitly marks this assumption for verification.
  10. Execute only in a controlled environment first and verify the pair callback, repayment and profit assertion.

### 4. AVAXFlashLoanSafeAdapter

- File: `contracts/archive/external/AVAXFlashLoanSafeAdapter.sol`
- Compiler: Solidity `0.8.20`
- Family: reconstructed Pangolin-style repayment adapter
- Constructor: `pair_`, `wrappedNative_`, `minProfit_`
- Status: review required
- Important: this adapter intentionally does **not** perform arbitrage swaps. It is a transparent repayment template derived from the supplied legacy source. The legacy opaque recipient decoder and whole-balance transfer are not used.
- Procedure:
  1. Open the source in Remix.
  2. Verify pair and wrapped-native addresses.
  3. Compile with `0.8.20`.
  4. Confirm the pair callback ABI and fee model.
  5. Deploy only for controlled testing.
  6. Do not treat `flashLoan` as an arbitrage strategy; it requires sufficient repayment/profit balance unless a separate explicit strategy implementation is added.
  7. Verify callback, repayment and pause/rescue behavior.

### 5. LiquidityFundedExecutor

- File: `contracts/archive/LiquidityFundedExecutor.sol`
- Compiler: Solidity `0.8.10`
- Family: owner-funded/no-flashloan executor
- Constructor: `minimumProfit`
- Status: repair required
- Important: the current `depositToken` function records an expected inventory event but does not transfer tokens into the contract. Also, its profit assertion compares `amountOut` and `amountIn` directly even for cross-token routes. Do not treat this as production-ready.
- Procedure after repair:
  1. Require an actual ERC-20 transferFrom deposit or explicitly document wallet-to-contract funding.
  2. Restrict routes to same-token round trips or replace the raw token-unit profit check with a value-normalized assertion.
  3. Compile and test in Remix.
  4. Verify router allowlist, inventory, slippage, deadline and withdrawal controls.
  5. Controlled-test before mainnet.

## Universal Remix procedure

`DApp → Select contract → Review full source → Open in Remix → Compile → Inspect ABI/constructor → Connect wallet → Select Avalanche network → Configure exact verified addresses → Controlled test → Verify result/events → Only then deploy/interact on mainnet.`

## Assurance states

- `ARCHIVED`: reference only.
- `REVIEW_REQUIRED`: source exists but requires technical/address verification.
- `REPAIR_REQUIRED`: known production blocker exists.
- `CONTROLLED_TEST`: all required configuration is prepared for a controlled environment.
- `READY`: source, deployment, configuration and controlled tests have passed.
- `LIVE`: only after explicit wallet authorization and final execution gates.

## No automatic signing

The DApp may prepare links, source, manifests and transaction parameters. It must never claim that a cloud state, scan result, quote, or Remix link authorizes a blockchain write. The connected wallet remains the signing authority.
