# Remix Contract Archive

This archive is the contract-selection layer for the DApp's Remix workflow. It intentionally separates **contract type**, **liquidity model**, **execution procedure**, and **assurance status**.

> No archived strategy guarantees profit. A strategy is executable only after its exact provider, asset, liquidity, router, quote, gas cost, fee/premium and repayment conditions have been validated.

## Contract families

### 01 — Provider flashloan: Aave V3
**File:** `contracts/AaveV3FlashArbitrage.sol`

Uses Aave V3 `flashLoanSimple` as the temporary liquidity source. The contract borrows an asset, executes a round-trip swap through an approved router, then requires enough balance to repay principal + premium + `minProfit`.

**Core functions**
- `requestFlashLoan(...)` — owner starts a flashloan attempt.
- `executeOperation(...)` — Aave callback; validates the pool and initiator, executes the route and authorizes repayment.
- `setRouter(...)` — owner allowlists a router.
- `setMinProfit(...)` — sets the hard profit floor.
- `setPaused(...)` — emergency stop.
- `rescueToken(...)` — owner recovery of tokens held by the contract.

**Procedure in Remix**
1. Compile with Solidity 0.8.10.
2. Deploy with the verified provider pool address and a conservative minimum profit.
3. Confirm the deployed owner and pool.
4. Approve only the exact router addresses intended for the test.
5. Confirm asset decimals and the round-trip path starts and ends in the borrowed asset.
6. Test on Fuji/controlled fork first.
7. Call `requestFlashLoan` only after an independently verified route quote covers premium, slippage and gas.
8. Inspect callback and settlement events before any mainnet authorization.

### 02 — Provider flashloan: two-router arbitrage
**File:** `contracts/archive/AaveV3TwoRouterArbitrage.sol`

Borrows one asset from Aave V3, swaps asset A → asset B on router A, then asset B → asset A on router B. The final balance must cover principal + premium + `minProfit`.

**Core functions**
- `requestFlashLoan(...)` — selects both routers, both minimum outputs, both paths and deadline.
- `executeOperation(...)` — executes the two sequential swaps and enforces repayment/profit.
- `setRouter(...)` — allowlists routers.
- `setMinProfit(...)` — hard profit floor.
- `setPaused(...)` — emergency stop.
- `rescueToken(...)` — recovery.

**Procedure**
1. Deploy against the verified Aave V3 pool.
2. Allowlist router A and router B.
3. Prepare path A: borrowed asset → intermediate asset.
4. Prepare path B: intermediate asset → borrowed asset.
5. Set realistic `minOutA` and `minOutB` from fresh quotes.
6. Use a short deadline.
7. Test the complete callback on Fuji/controlled fork.
8. Only proceed when the returned borrowed-asset balance exceeds principal + premium + required profit.

### 03 — Liquidity-funded / no-flashloan contract
**File:** `contracts/archive/LiquidityFundedExecutor.sol`

Uses tokens already deposited into the contract rather than borrowing them during execution. This is useful for treasury-funded market making, inventory arbitrage, or manually funded route execution.

**Core functions**
- `depositToken(...)` — owner deposits execution inventory.
- `executeRoute(...)` — owner executes an approved route against an approved router.
- `setRouter(...)` — allowlists execution venues.
- `setMinProfit(...)` — establishes the route profit floor.
- `setPaused(...)` — emergency stop.
- `withdrawToken(...)` — owner withdrawal/recovery.

**Procedure**
1. Deploy and verify ownership.
2. Allowlist the intended router.
3. Transfer the execution token into the contract.
4. Verify available inventory and token decimals.
5. Obtain a fresh quote and set a protective minimum output.
6. Execute the route from Remix.
7. Verify resulting balances and events.
8. Withdraw only after accounting for retained operating inventory.

### 04 — Mixed-liquidity executor
**File:** `contracts/archive/MixedLiquidityExecutor.sol`

Combines pre-funded inventory with an optional external liquidity adapter. This family is intended for future integrations where a route may use internal capital first and a provider-specific liquidity source second.

**Important:** this is an adapter architecture, not a claim that every external provider is interchangeable. Each provider must have its own verified interface, addresses and repayment rules.

### 05 — Multi-provider flashloan adapter
**File:** `contracts/archive/MultiProviderFlashAdapter.sol`

Provides a common control surface for multiple provider adapters. The archive records the provider selection, but each provider implementation remains isolated because callback signatures, fees, supported assets and deployment addresses differ.

**Procedure**
1. Select provider adapter.
2. Verify provider pool/address for the selected network.
3. Verify supported asset and fee model.
4. Select route and repayment constraints.
5. Run controlled test.
6. Review emitted provider and settlement events.
7. Only then authorize the mainnet route.

## Remix execution states

**OBSERVE** → compile, inspect ABI and addresses.

**CONFIGURE** → set provider, router, asset, paths, minimum outputs and profit floor.

**CONTROLLED TEST** → Fuji or a controlled fork; prove callback, swaps and repayment.

**READY** → deployment, ownership, bytecode, liquidity and route evidence are recorded.

**LIVE** → explicit owner authorization only. The DApp/cloud database cannot grant spending authority.

## Why multiple families are archived

The DApp should not force every user into one flashloan provider. Remix users may need:
- provider-supplied temporary liquidity;
- already-funded contract inventory;
- two-venue arbitrage;
- multi-hop routing;
- mixed internal/external liquidity;
- provider-specific adapters.

The archive therefore acts as a selectable strategy library while the DApp remains the control plane and Remix remains the actual Solidity compile/deploy/interaction environment.
