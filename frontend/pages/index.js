import Head from 'next/head';
import WalletConnection from '../components/WalletConnection';

export default function Home() {
  return (
    <>
      <Head><title>AVAX Flashloan Control Plane</title><meta name="description" content="Remix-integrated Avalanche flashloan deployment and assurance control plane" /></Head>
      <main className="shell">
        <header className="hero">
          <p className="eyebrow">AVALANCHE · C-CHAIN · 43114</p>
          <h1>Flashloan deployment control plane.</h1>
          <p className="muted">Remix is the deployment and contract-engagement environment. This DApp provides the archive, assurance, wallet and monitoring layer around it.</p>
          <div className="actions"><a className="primary" href="https://remix.ethereum.org/" target="_blank" rel="noreferrer">Open Remix IDE</a><a className="secondary" href="https://github.com/Samoolino/DAPP-REMIX-AVAX" target="_blank" rel="noreferrer">Repository</a></div>
        </header>
        <WalletConnection />
        <section className="grid">
          <article className="card"><small>DEPLOYMENT</small><h2>Remix</h2><p>Compile, deploy and engage contracts through the approved Remix workspace.</p></article>
          <article className="card"><small>NETWORK</small><h2>43114</h2><p>Avalanche C-Chain mainnet. Fuji remains the validation environment.</p></article>
          <article className="card"><small>EXECUTION</small><h2 className="warn">GATED</h2><p>Owner authorization, route validation and repayment checks are required.</p></article>
          <article className="card"><small>MONITORING</small><h2>Cloud</h2><p>Telemetry can observe deployments and events without granting spending authority.</p></article>
        </section>
        <section className="card roadmap"><h2>Release gates</h2><ol><li>Compile and review Solidity artifacts.</li><li>Deploy and record contract address, owner and bytecode.</li><li>Validate Aave liquidity, premium and repayment on Fuji.</li><li>Validate approved DEX routes and profit accounting.</li><li>Verify events and cloud telemetry.</li><li>Only then authorize bounded mainnet execution.</li></ol></section>
        <section className="card"><h2>Remix engagement</h2><p className="muted">The DApp does not impersonate Remix or silently submit transactions. The wallet and Remix environment remain the explicit deployment/transaction boundary.</p><a className="primary" href="https://remix.ethereum.org/" target="_blank" rel="noreferrer">Launch Remix</a></section>
      </main>
    </>
  );
}
