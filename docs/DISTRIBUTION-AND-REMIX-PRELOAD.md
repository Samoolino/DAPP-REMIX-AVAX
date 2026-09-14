# Distribution, Cloud Deployment & Remix Preload Architecture

## 1. Deployment model

The application is distributed as a web control plane and optional local package:

`DApp control plane -> Wallet -> Remix IDE -> Avalanche C-Chain -> deployed contract`

Vercel hosts the Next.js control plane. It does not hold private keys and cannot authorize a blockchain transaction. The wallet remains the signing authority.

## 2. Downloadable formats

### A. PWA / installable web app

Preferred first distribution. Add a web manifest, icons and service-worker/offline shell. Users can install the DApp from a supported browser. The UI remains connected to the hosted control plane when online.

### B. Desktop package

A future Electron or Tauri wrapper can package the same frontend for Windows/macOS/Linux. The wrapper should not contain private keys or privileged signing credentials. Wallet signing should continue through an injected wallet or an explicit wallet bridge.

### C. Source/developer bundle

GitHub remains the canonical source distribution. A release archive can contain the frontend, contract archive, Remix workspace metadata, deployment manifests, ABIs and documentation.

### D. Mobile

A later Capacitor/native wrapper can package the control plane, but wallet compatibility must be validated separately. Do not assume browser wallet APIs behave identically inside a native WebView.

## 3. Remix preload roadmap

The DApp should evolve from a contract selector into a **Remix Workspace Launcher**.

Each archived contract should have a manifest containing:

- contract ID and version
- Solidity source path
- compiler version
- optimizer settings
- required constructor arguments
- interface/ABI metadata
- provider family
- network/chain ID
- required token/router/pool addresses
- safety gates
- deployment checklist
- verification metadata
- source provenance / Git commit

The DApp can then offer:

`Select contract -> Review manifest -> Open Remix workspace -> Load source -> Compile -> Connect wallet -> Deploy/interact`

## 4. What 'preload into Remix' means

Do not depend on an undocumented private Remix API. The robust implementation is to generate a Remix-compatible workspace/project payload and launch Remix with a supported workspace/import mechanism where available.

If direct workspace injection is not available, the DApp should provide a one-click **Open in Remix + Import Contract** workflow and a downloadable workspace archive. This preserves Remix as the execution IDE rather than pretending the DApp is Remix.

## 5. Contract archive structure

```text
contract-library/
  aave-v3-flash/
    manifest.json
    AaveV3FlashArbitrage.sol
    README.md
  aave-v3-two-router/
    manifest.json
    AaveV3TwoRouterArbitrage.sol
    README.md
  liquidity-funded/
    manifest.json
    LiquidityFundedExecutor.sol
    README.md
```

## 6. Required safety boundary

A manifest may configure a deployment; it must never grant signing authority. The following remain wallet-controlled:

- deployment transaction
- token approvals
- flashloan request
- router configuration
- inventory transfer
- live execution

Cloud flags and database records cannot authorize spending.

## 7. Release gates

`ARCHIVED -> REVIEWED -> IMPORTABLE -> COMPILE-VALIDATED -> CONTROLLED-TESTED -> READY -> LIVE`

`LIVE` requires explicit wallet authorization and verified on-chain configuration. Scanner discovery alone never changes the state to LIVE.
