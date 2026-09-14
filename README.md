# Archive-Driven Avalanche DApp Suite

Avalanche C-Chain / Fuji flash-loan deployment and assurance control plane.

## Engagement boundary

**Remix (`remix.ethereum.org`) remains the deployment and contract-engagement environment.** This DApp does not replace Remix or silently submit transactions. It houses the archive, wallet/network checks, deployment assurance, monitoring and a first-class Remix launch/workspace entry point.

Flow:

`DApp control plane -> Remix IDE -> connected wallet -> Avalanche C-Chain -> deployed flash-loan contract`

## Safety and operating model

- Mainnet chain ID: `43114`; Fuji: `43113`.
- Browser deployment requires an EIP-1193 wallet explicitly on the selected Avalanche network.
- Contract execution entry points are owner-gated.
- Automation is opt-in and should be tested on Fuji first.
- The cloud daemon is monitoring/cache only; database state can never grant spending authority.
- `checkUpkeep` is a simulation/read path. Do not treat it as execution authorization.
- Mainnet LIVE status is only valid after verified deployment, route/liquidity validation, repayment evidence and explicit owner authorization.

## Layout

See `contracts/`, `frontend/`, and `cloud-engine/`.

## Frontend

The Next.js control plane provides wallet/network state, production gates and a direct Remix IDE engagement path. The static landing page remains available as a lightweight fallback.

## Environment

Frontend:

```bash
cd frontend
npm install
npm run dev
```

Cloud engine:

```bash
cd cloud-engine
npm install
cp .env.example .env
npm run daemon
```

Required cloud variables include `AVAX_RPC_URL`, `SUPABASE_URL`, and `SUPABASE_SERVICE_ROLE_KEY`. Never expose the Supabase service-role key to the browser.

## Remix

For local contract synchronization:

```bash
remixd -s ./contracts --remix-ide https://remix.ethereum.org
```

For the actual deployment/engagement workspace, open Remix, connect the wallet, select the approved Solidity `0.8.10` contract, compile, and deploy only after the assurance gates pass.

## Fuji validation

1. Configure wallet/network to Avalanche Fuji (`43113`).
2. Deploy `Registry`, then the selected receiver/strategy contract through Remix.
3. Record deployment address, owner, chain ID and bytecode hash.
4. Confirm Aave market/pool addresses from the maintained Aave address book rather than copying an unverified address.
5. Test token decimals explicitly; never assume 18 decimals.
6. Confirm the receiver can cover flash-loan premium and repayment.
7. Validate the complete route and minimum-profit accounting before any live execution.
8. Confirm events are observed and persisted by the cloud engine.
9. Exercise `checkUpkeep` with `eth_call`; only then consider separately authorized automation.

## Mainnet release gate

A deployment is **not LIVE** merely because Remix compiles or a contract is deployed. Mainnet LIVE requires: verified contract, verified Aave/route configuration, controlled transaction evidence, repayment evidence, event continuity, funded gas, emergency pause capability and explicit owner authorization.

## Persistent cloud operation

Run `cloud-engine/daemon.js` as a long-lived worker/container. Vercel/Netlify hosts the frontend; it is not the long-lived daemon. Use health checks, restart-on-failure, structured logs and secret environment variables.

## Contract archive

The archive is explicit: deployment records should include contract type, owner, network, bytecode hash, status and timestamps. The frontend should select known archive entries rather than accept arbitrary bytecode from untrusted input.
