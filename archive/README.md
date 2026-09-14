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

### 03 — Pangolin / V2-style flash-swap two-router arbitrage
**File:** `contracts/archive/external/PangolinTwoRouterArbitrage.sol`

This is the new reconstructed implementation for the supplied legacy AVAX flash-loan concept. It uses an explicitly configured pair, an owner-controlled router allowlist, bounded swap paths/minimum outputs, a deadline, a same-token repayment check and a minimum profit floor.

**Important provenance and safety boundary:** the supplied legacy source is **not** ported verbatim. Its opaque address decoder and whole-balance transfer behavior are intentionally excluded. The new implementation is a transparent template that must be verified against the actual deployed pair and routers before use.

**Core functions**
- `flashSwap(...)` — starts the pair flash swap and defines both router routes.
- `pangolinCall(...)` — pair-only callback; executes the two swaps and repays the pair.
- `setRouter(...)` — owner allowlists routers.
- `setMinProfit(...)` — establishes the profit floor.
- `setPaused(...)` — emergency stop.
- `rescueToken(...)` — recovery.

**Required gates before controlled execution**
1. Verify the exact Avalanche pair address.
2. Verify `token0()` and `token1()`.
3. Verify the pair callback selector and flash-swap semantics.
4. Verify the pair fee/invariant model; the template currently assumes the common V2-style 0.3% formula and must not be treated as universal.
5. Verify exact router addresses and `swapExactTokensForTokens` behavior.
6. Verify token decimals and route assets.
7. Compile the source in Remix.
8. Run Fuji or a controlled-fork test and prove callback, swaps, repayment, events, pause and rescue.
9. Only after those gates should a bounded mainnet transaction be considered.

**Manifest:** `contracts/archive/external/PangolinTwoRouterArbitrage.manifest.json`

### 04 — Pangolin flash-swap safe adapter
**File:** `contracts/archive/external/AVAXFlashLoanSafeAdapter.sol`

A lower-level repayment adapter reconstructed from the same legacy source. It removes the opaque destination decoder and does not perform arbitrary arbitrage itself. It is useful for interface/callback testing, but it is **not** a complete arbitrage engine.

**Status:** `REVIEW_REQUIRED` until the configured pair and fee model are verified.

### 05 — Liquidity-funded / no-flashloan contract
**File:** `contracts/archive/LiquidityFundedExecutor.sol`

Uses tokens already deposited into the contract rather than borrowing them during execution. This is useful for treasury-funded market making, inventory arbitrage, or manually funded route execution.

**Status:** `REPAIR_REQUIRED` because its generalized cross-token profit assertion and deposit accounting require correction before production use.

### 06 — Mixed-liquidity executor
**File:** `contracts/archive/MixedLiquidityExecutor.sol`

Combines pre-funded inventory with an optional external liquidity adapter. This family is intended for future integrations where a route may use internal capital first and a provider-specific liquidity source second.

**Important:** this is an adapter architecture, not a claim that every external provider is interchangeable. Each provider must have its own verified interface, addresses and repayment rules.

### 07 — Multi-provider flashloan adapter
**File:** `contracts/archive/MultiProviderFlashAdapter.sol`

Provides a common control surface for multiple provider adapters. The archive records the provider selection, but each provider implementation remains isolated because callback signatures, fees, supported assets and deployment addresses differ.

## Remix execution states

**OBSERVE** → compile, inspect ABI and addresses.

**CONFIGURE** → set provider, router, asset, paths, minimum outputs and profit floor.

**CONTROLLED TEST** → Fuji or a controlled fork; prove callback, swaps and repayment.

**READY** → deployment, ownership, bytecode, liquidity and route evidence are recorded.

**LIVE** → explicit owner authorization only. The DApp/cloud database cannot grant spending authority.

## Quarantine rule for supplied legacy source

The original `AVAX FLASH LOAN UPDATED v2.0` source remains quarantined. It contains an opaque destination-address construction and a function that can transfer the contract's entire AVAX balance to that decoded destination. It must not be imported as executable production logic.

## Why multiple families are archived

The DApp should not force every user into one flashloan provider. Remix users may need:
- provider-supplied temporary liquidity;
- already-funded contract inventory;
- two-venue arbitrage;
- multi-hop routing;
- mixed internal/external liquidity;
- provider-specific adapters.

The archive therefore acts as a selectable strategy library while the DApp remains the control plane and Remix remains the actual Solidity compile/deploy/interaction environment.
