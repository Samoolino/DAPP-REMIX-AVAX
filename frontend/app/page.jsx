'use client';

import {useEffect,useMemo,useState} from 'react';

const CHAIN_ID=43114;
const STORAGE='avax-control-session-v1';
const contracts=[
 {id:'aave-v3-flash',name:'Aave V3 Flash Arbitrage',family:'Flashloan provider',file:'contracts/AaveV3FlashArbitrage.sol',description:'Single-provider round-trip flashloan template with repayment and profit-floor checks.',status:'REVIEW_REQUIRED'},
 {id:'aave-v3-two-router',name:'Aave V3 Two-Router Arbitrage',family:'Flashloan + mixed venues',file:'contracts/archive/AaveV3TwoRouterArbitrage.sol',description:'Borrow one asset, swap through router A, reverse through router B, repay and enforce minimum profit.',status:'ARCHIVED_REVIEWED'},
 {id:'pangolin-two-router',name:'Pangolin Two-Router Flash-Swap Arbitrage',family:'Pangolin / V2-style flash swap',file:'contracts/archive/external/PangolinTwoRouterArbitrage.sol',manifest:'contracts/archive/external/PangolinTwoRouterArbitrage.manifest.json',description:'Controlled-test flash-swap template: borrow from a verified pair, execute two allowlisted router swaps, repay and enforce a same-token profit floor.',status:'RECONSTRUCTED_REVIEW_REQUIRED'},
 {id:'pangolin-safe-adapter',name:'Pangolin Flash-Swap Safe Adapter',family:'Pangolin / Flash-Swap',file:'contracts/archive/external/AVAXFlashLoanSafeAdapter.sol',description:'Reconstructed repayment adapter with the legacy opaque recipient/decoder removed. It does not perform arbitrage by itself.',status:'REVIEW_REQUIRED'},
 {id:'liquidity-funded',name:'Liquidity Funded Executor',family:'No flashloan',file:'contracts/archive/LiquidityFundedExecutor.sol',description:'Owner-funded inventory executor for routes where capital is supplied by the contract owner.',status:'REPAIR_REQUIRED'},
 {id:'mixed-provider',name:'Mixed Liquidity / Multi-Provider',family:'Archive extension',file:'archive/README.md',description:'Architecture reserved for mixed funding and multiple flashloan-provider adapters; provider addresses must be verified before deployment.',status:'ARCHIVE'}
];

export default function Page(){
 const [wallet,setWallet]=useState('');
 const [chain,setChain]=useState(null);
 const [selectedId,setSelectedId]=useState('aave-v3-flash');
 const [gate,setGate]=useState('OBSERVE');
 const [installable,setInstallable]=useState(false);
 const selected=useMemo(()=>contracts.find(c=>c.id===selectedId)||contracts[0],[selectedId]);

 useEffect(()=>{
  try{const saved=JSON.parse(localStorage.getItem(STORAGE)||'{}'); if(saved.selectedId)setSelectedId(saved.selectedId); if(saved.gate)setGate(saved.gate)}catch{}
  if(window.matchMedia?.('(display-mode: standalone)').matches || window.navigator.standalone) setInstallable(true);
 },[]);
 useEffect(()=>{try{localStorage.setItem(STORAGE,JSON.stringify({wallet,chain,selectedId,gate,updatedAt:new Date().toISOString()}))}catch{}},[wallet,chain,selectedId,gate]);

 const sync=async()=>{if(!window.ethereum)return; try{const accounts=await window.ethereum.request({method:'eth_accounts'}); const cid=await window.ethereum.request({method:'eth_chainId'}); setWallet(accounts[0]||''); setChain(parseInt(cid,16));}catch(e){console.warn(e)}};
 useEffect(()=>{sync(); if(window.ethereum){window.ethereum.on?.('accountsChanged',sync);window.ethereum.on?.('chainChanged',sync)} return()=>{window.ethereum?.removeListener?.('accountsChanged',sync);window.ethereum?.removeListener?.('chainChanged',sync)}},[]);
 const connect=async()=>{if(!window.ethereum){alert('Open this web app inside a supported wallet browser or use an injected EIP-1193 wallet.');return} try{await window.ethereum.request({method:'eth_requestAccounts'}); try{await window.ethereum.request({method:'wallet_switchEthereumChain',params:[{chainId:'0xA86A'}]})}catch(e){console.warn(e)} await sync()}catch(e){console.warn(e)}};
 const remix='https://remix.ethereum.org/';
 const source=`https://github.com/Samoolino/DAPP-REMIX-AVAX/blob/main/${selected.file}`;
 const prepareRemix=()=>{setGate('CONFIGURE'); window.open(remix,'_blank','noopener,noreferrer')};
 return <main className="shell">
  <header className="topbar"><div><div className="eyebrow">AVALANCHE · C-CHAIN · 43114</div><strong>AVAX CONTROL</strong></div><div className="topstate">{installable?'INSTALLED WEB APP':'WEB APP'} · {wallet?'WALLET CONNECTED':'WALLET DISCONNECTED'}</div></header>
  <section className="hero"><div className="eyebrow">DAPP CLOUD CONTROL PLANE</div><h1>Flashloan + Remix Workspace</h1><p className="muted">One responsive web interface for wallet state, contract selection, Remix preparation and execution gates. No separate mobile page and no private-key custody.</p><div className="actions"><button className="btn" onClick={connect}>{wallet?`Connected ${wallet.slice(0,6)}…${wallet.slice(-4)}`:'Connect Wallet'}</button><button className="btn secondary" onClick={prepareRemix}>Prepare + Open Remix ↗</button></div></section>
  <section className="grid"><div className="panel"><span className="pill">WALLET</span><h2>{wallet?'CONNECTED':'NOT CONNECTED'}</h2><p className="muted">{wallet?wallet:'Use injected EIP-1193 or a wallet in-app browser.'}</p></div><div className="panel"><span className="pill">NETWORK</span><h2 className={chain===CHAIN_ID?'live':'gated'}>{chain===CHAIN_ID?'AVALANCHE MAINNET':'CHAIN NOT CONFIRMED'}</h2><p className="muted">Detected: {chain??'—'} · Required: {CHAIN_ID}</p></div><div className="panel"><span className="pill">EXECUTION GATE</span><h2 className="gated">{gate}</h2><p className="muted">Cloud state is descriptive; only wallet signatures authorize writes.</p></div><div className="panel"><span className="pill">REMIX</span><h2>WORKSPACE BRIDGE</h2><p className="muted">Selected manifest → prepared source → Remix IDE.</p></div></section>
  <section className="workspace"><div className="panel"><div className="eyebrow">CONTRACT LIBRARY</div><h2>Select a strategy</h2><div className="grid">{contracts.map(c=><button key={c.id} className={`panel strategy ${selected.id===c.id?'selected':''}`} onClick={()=>{setSelectedId(c.id);setGate('OBSERVE')}}><span className="pill">{c.family}</span><strong>{c.name}</strong><span className="muted">{c.description}</span><span className="mono">{c.file}</span><span className="pill">{c.status}</span></button>)}</div></div>
   <div className="panel selected-panel"><div className="eyebrow">SELECTED MANIFEST</div><h2>{selected.name}</h2><p>{selected.description}</p><div className="manifest"><div><span>Source</span><b>{selected.file}</b></div><div><span>Network</span><b>Avalanche C-Chain · 43114 / Fuji · 43113</b></div><div><span>Lifecycle</span><b>{selected.status}</b></div><div><span>Execution gate</span><b>{gate}</b></div><div><span>Authority</span><b>Connected wallet + on-chain owner</b></div></div><div className="actions"><button className="btn" onClick={prepareRemix}>Prepare Workspace</button><a className="btn secondary" href={source} target="_blank" rel="noreferrer">View Source ↗</a></div></div></section>
  <section className="panel"><div className="eyebrow">CONTROLLED EXECUTION LIFECYCLE</div><div className="steps">{[['OBSERVE','Confirm wallet, chain, provider, liquidity, token decimals, routes and current quotes.'],['CONFIGURE','Compile in Remix and configure exact deployed addresses, routers, assets and minimum outputs.'],['CONTROLLED TEST','Validate on Fuji or a controlled fork; verify repayment, events, gas and profit-floor behavior.'],['READY','Verify bytecode/source, owner, pause path, funding and monitoring before a mainnet write.'],['LIVE','Only the connected wallet signs a bounded transaction; cloud automation cannot authorize spending.']].map(([name,desc],i)=><button key={name} className={`step ${gate===name?'active':''}`} onClick={()=>i===0||gate===name?setGate(name):null}><span className="stepno">{i+1}</span><span><strong>{name}</strong><span className="muted">{desc}</span></span></button>)}</div><div className="notice small">Safety gate: templates do not guarantee profit. Provider addresses, pair fee model, liquidity, routes, slippage, gas and repayment must be independently verified at execution time.</div></section>
  <footer className="footer muted small">Vercel hosts the responsive control plane. Remix performs Solidity compilation/deployment/interaction. Avalanche C-Chain performs the actual transaction. Wallets retain signing authority. The cloud stores non-secret session state only.</footer>
 </main>
}
