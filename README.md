# Archive-Driven Avalanche DApp Suite

Avalanche C-Chain / Fuji flash-loan and automation reference architecture.

## Safety and operating model

- Mainnet chain ID: `43114`; Fuji: `43113`.
- Browser deployment requires an EIP-1193 wallet explicitly on the selected Avalanche network.
- Contract execution entry points are owner-gated.
- Automation is opt-in and should be tested on Fuji first.
- The cloud daemon is a monitoring/cache service; it must never infer permission to spend funds from database state.
- `checkUpkeep` is a simulation/read path; `performUpkeep` remains protected by contract conditions.

## Layout

See `contracts/`, `frontend/`, and `cloud-engine/`.

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

## Remixd

From the repository root:

```bash
remixd -s ./contracts --remix-ide https://remix.ethereum.org
```

Then open Remix and connect the shared workspace. Compile with Solidity `0.8.10`.

## Fuji validation

1. Configure wallet/network to Avalanche Fuji (`43113`).
2. Deploy `Registry`, then the selected receiver/strategy contract.
3. Register the deployment in the Registry and mirror it into Supabase.
4. Test 6-decimal versus 18-decimal amount conversion using explicit token decimals; never assume 18 decimals.
5. Confirm the receiver can cover the Aave flash-loan premium (the configured test amount plus the protocol premium) before calling a flash-loan path.
6. Confirm emitted events are observed by `cloud-engine/daemon.js` and persisted to Supabase.
7. Exercise `checkUpkeep` with `eth_call`; only then consider `performUpkeep`.

## Persistent cloud operation

Run `cloud-engine/daemon.js` as a long-lived worker/container (Render, AWS ECS/App Runner, Fly.io, etc.). Use health checks, restart-on-failure, structured logs, and secret environment variables. Vercel/Netlify hosts the frontend; it is not the long-lived daemon.

## Contract archive

The archive is deliberately explicit: each deployment records contract type, owner, network, bytecode hash, status, and timestamps. The frontend selects known archive entries rather than accepting arbitrary bytecode from untrusted input.

## Supabase schema

Apply `cloud-engine/supabase.sql`. The schema includes deployments, execution metrics, and observed contract events with uniqueness constraints for idempotent log ingestion.
