# Avalanche Production Assurance & Deployment Guide

## Network
- Mainnet: Avalanche C-Chain, chain ID 43114.
- Fuji: chain ID 43113.
- Use an actual JSON-RPC endpoint in `AVAX_RPC_URL`; do not use the Avalanche website URL as an RPC endpoint.

## Release gates
1. Compile and review Solidity 0.8.10 artifacts.
2. Deploy Registry and the selected strategy from the approved archive.
3. Record address, owner, chain ID and bytecode hash.
4. Verify contracts on the appropriate Avalanche explorer.
5. Configure exact Aave V3 assets and approved DEX routers.
6. Validate token decimals explicitly (6 vs 18 decimal assets).
7. Validate flash-loan premium coverage and repayment.
8. Execute a controlled Fuji transaction and confirm emitted logs.
9. Confirm cloud ingestion and idempotent persistence.
10. Simulate `checkUpkeep`; do not treat simulation as authorization.
11. Configure Chainlink Automation only after the above gates pass.
12. On mainnet, begin with a bounded transaction and conservative profit floor.
13. Enable live execution only after owner-controlled authorization and emergency pause are verified.

## Live execution assurance
The UI must distinguish OBSERVING, READY, ARMED and LIVE. Database state can never grant spending authority. Contract owner controls remain authoritative. Every live route must enforce deadline, minimum output, pause state and profit floor. Keep a rescue/emergency procedure and monitor failed transactions, gas usage and event continuity.

## Cloud uptime
Run `cloud-engine/daemon.js` as a persistent worker/container. Supply secrets through the hosting provider. Add restart-on-failure, health checks, structured logs and alerting. Never expose `SUPABASE_SERVICE_ROLE_KEY` to the browser.

## Remixd
`remixd -s ./contracts --remix-ide https://remix.ethereum.org`

## Rollback
Pause the execution contract, disable automation, preserve logs, investigate the failing route, and only re-arm after a new controlled validation. Never use a database flag as a substitute for an on-chain pause.
