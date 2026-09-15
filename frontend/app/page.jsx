'use client';

import {useEffect,useMemo,useState} from 'react';

const CHAIN_ID=43114;
const STORAGE='avax-control-session-v1';
const GITHUB_ROOT='https://github.com/Samoolino/DAPP-REMIX-AVAX/blob/main/';
const RAW_ROOT='https://raw.githubusercontent.com/Samoolino/DAPP-REMIX-AVAX/main/';
const contracts=[
 {id:'aave-v3-flash',name:'AaveV3FlashArbitrage.sol',family:'Aave V3 · Flashloan',file:'contracts/AaveV3FlashArbitrage.sol',compiler:'0.8.10',constructorArgs:'poolAddress, minimumProfit',status:'REVIEW_REQUIRED',description:'Single-provider round-trip flashloan template. Borrows one asset, swaps through one approved router, repays premium, then enforces a minimum-profit floor.'},
 {id:'aave-v3-two-router',name:'AaveV3TwoRouterArbitrage.sol',family:'Aave V3 · Two routers',file:'contracts/archive/AaveV3TwoRouterArbitrage.sol',compiler:'0.8.10',constructorArgs:'poolAddress, minimumProfit',status:'ARCHIVED_REVIEWED',description:'Borrows one asset, swaps through router A into an intermediate token, reverses through router B, repays Aave and enforces the minimum-profit floor.'},
 {id:'pangolin-two-router',name:'PangolinTwoRouterArbitrage.sol',family:'Pangolin · V2 flash swap',file:'contracts/archive/external/PangolinTwoRouterArbitrage.sol',compiler:'0.8.20',constructorArgs:'pairAddress, minimumProfit',status:'RECONSTRUCTED_REVIEW_REQUIRED',description:'V2-style pair flash swap followed by two allowlisted router swaps and same-token repayment. The pair fee model must be verified before controlled execution.'},
 {id:'pangolin-safe-adapter',name:'AVAXFlashLoanSafeAdapter.sol',family:'Pangolin · Safe adapter',file:'contracts/archive/external/AVAXFlashLoanSafeAdapter.sol',compiler:'0.8.20',constructorArgs:'pair_, wrappedNative_, minProfit_',status:'REVIEW_REQUIRED',description:'Transparent reconstructed repayment adapter. It deliberately excludes the legacy opaque recipient decoder and whole-balance transfer, and does not execute arbitrage by itself.'},
 {id:'liquidity-funded',name:'LiquidityFundedExecutor.sol',family:'Owner-funded · No flashloan',file:'contracts/archive/LiquidityFundedExecutor.sol',compiler:'0.8.10',constructorArgs:'minimumProfit',status:'REPAIR_REQUIRED',description:'Inventory-funded route executor. Current deposit and cross-token profit semantics require repair before production use.'}
];

export default function Page(){
 const [wallet,setWallet]=useState('');
 const [chain,setChain]=useState(null);
 const [selectedId,setSelectedId]=useState('aave-v3-flash');
 const [gate,setGate]=useState('OBSERVE');
 const [installable,setInstallable]=useState(false);
 const [source,setSource]=useState('');
 const [sourceState,setSourceState]=useState('idle');
 const selected=useMemo(()=>contracts.find(c=>c.id===selectedId)||contracts[0],[selectedId]);
 const githubUrl=GITHUB_ROOT+selected.file;
 const rawUrl=RAW_ROOT+selected.file;
 const remixUrl=`https://app.remix.live/#url=${githubUrl}`;

 useEffect(()=>{
  try{const saved=JSON.parse(localStorage.getItem(STORAGE)||'{}'); if(saved.selectedId)setSelectedId(saved.selectedId); if(saved.gate)setGate(saved.gate)}catch{}
  if(window.matchMedia?.('(display-mode: standalone)').matches || window.navigator.standalone) setInstallable(true);
 },[]);
 useEffect(()=>{try{localStorage.setItem(STORAGE,JSON.stringify({wallet,chain,selectedId,gate,updatedAt:new Date().toISOString()}))}catch{}},[wallet,chain,selectedId,gate]);
 useEffect(()=>{
  let cancelled=false;
  setSource(''); setSourceState('loading');
  fetch(rawUrl).then(r=>{if(!r.ok)throw new Error(`HTTP ${r.status}`);return r.text()}).then(text=>{if(!cancelled){setSource(text);setSourceState('ready')}}).catch(()=>{if(!cancelled)setSourceState('error')});
  return()=>{cancelled=true};
 },[rawUrl]);

 const sync=async()=>{if(!window.ethereum)return; try{const accounts=await window.ethereum.request({method:'eth_accounts'}); const cid=await window.ethereum.request({method:'eth_chainId'}); setWallet(accounts[0]||''); setChain(parseInt(cid,16));}catch(e){console.warn(e)}};
 useEffect(()=>{sync(); if(window.ethereum){window.ethereum.on?.('accountsChanged',sync);window.ethereum.on?.('chainChanged',sync)} return()=>{window.ethereum?.removeListener?.('accountsChanged',sync);window.ethereum?.removeListener?.('chainChanged',sync)}},[]);
 const connect=async()=>{if(!window.ethereum){alert('Open this web app inside a supported wallet browser or use an injected EIP-1193 wallet.');return} try{await window.ethereum.request({method:'eth_requestAccounts'}); try{await window.ethereum.request({method:'wallet_switchEthereumChain',params:[{chainId:'0xA86A'}]})}catch(e){console.warn(e)} await sync()}catch(e){console.warn(e)}};
 const prepareRemix=()=>{setGate('CONFIGURE');window.open(remixUrl,'_blank','noopener,noreferrer')};
 const copySource=async()=>{if(!source)return;try{await navigator.clipboard.writeText(source);setSourceState('copied');setTimeout(()=>setSourceState('ready'),1500)}catch(e){console.warn(e)}};
 const setLifecycle=(name,i)=>{if(i===0||gate===name)setGate(name)};
 return <main className="shell">
  <header className="topbar"><div><div className="eyebrow">AVALANCHE · C-CHAIN · 43114</div><strong>AVAX CONTROL</strong></div><div className="topstate">{installable?'INSTALLED WEB APP':'WEB APP'} · {wallet?'WALLET CONNECTED':'WALLET DISCONNECTED'}</div></header>
  <section className="hero"><div className="eyebrow">DAPP CLOUD CONTROL PLANE</div><h1>Named Contracts → Full Source → Remix</h1><p className="muted">Every strategy is now identified by its real Solidity filename, exposes the complete copyable source, and provides a direct Remix deep link that loads that exact file. Remix remains the authoritative IDE for compilation, deployment and interaction.</p><div className="actions"><button className="btn" onClick={connect}>{wallet?`Connected ${wallet.slice(0,6)}…${wallet.slice(-4)}`:'Connect Wallet'}</button><button className="btn secondary" onClick={prepareRemix}>Open Selected Contract in Remix ↗</button></div></section>
  <section className="grid"><div className="panel"><span className="pill">WALLET</span><h2>{wallet?'CONNECTED':'NOT CONNECTED'}</h2><p className="muted">{wallet?wallet:'Use injected EIP-1193 or a wallet in-app browser.'}</p></div><div className="panel"><span className="pill">NETWORK</span><h2 className={chain===CHAIN_ID?'live':'gated'}>{chain===CHAIN_ID?'AVALANCHE MAINNET':'CHAIN NOT CONFIRMED'}</h2><p className="muted">Detected: {chain??'—'} · Required: {CHAIN_ID}</p></div><div className="panel"><span className="pill">EXECUTION GATE</span><h2 className="gated">{gate}</h2><p className="muted">Cloud state is descriptive; only wallet signatures authorize writes.</p></div><div className="panel"><span className="pill">REMIX WORKSPACE</span><h2>DIRECT FILE PORT</h2><p className="muted">Open Selected Contract loads the exact GitHub source into Remix's temporary code-sample workspace.</p></div></section>

  <section className="workspace"><div className="panel"><div className="eyebrow">CONTRACT LIBRARY</div><h2>1. Choose the exact Solidity contract</h2><p className="muted">The filename is the contract identity. Select it first; then the full source, compiler, constructor and procedure below all follow the selection.</p><div className="grid">{contracts.map(c=><button key={c.id} className={`panel strategy ${selected.id===c.id?'selected':''}`} onClick={()=>{setSelectedId(c.id);setGate('OBSERVE')}}><span className="pill">{c.family}</span><strong>{c.name}</strong><span className="muted">{c.description}</span><span className="mono">{c.file}</span><span className="pill">SOLIDITY {c.compiler} · {c.status}</span></button>)}</div></div>
   <div className="panel selected-panel"><div className="eyebrow">2. CONTRACT NOTE / MANIFEST</div><h2>{selected.name}</h2><p>{selected.description}</p><div className="manifest"><div><span>Exact source</span><b>{selected.file}</b></div><div><span>Compiler</span><b>Solidity {selected.compiler}</b></div><div><span>Constructor</span><b>{selected.constructorArgs}</b></div><div><span>Network</span><b>Avalanche C-Chain · 43114 / Fuji · 43113</b></div><div><span>Lifecycle</span><b>{selected.status}</b></div><div><span>Authority</span><b>Connected wallet + on-chain owner</b></div></div><div className="actions"><button className="btn" onClick={prepareRemix}>Open Exact File in Remix ↗</button><a className="btn secondary" href={githubUrl} target="_blank" rel="noreferrer">GitHub Source ↗</a><button className="btn secondary" onClick={copySource}>{sourceState==='copied'?'Copied ✓':'Copy Full Contract'}</button></div></div></section>

  <section className="panel source-panel"><div className="eyebrow">3. FULL COPYABLE CONTRACT NOTE</div><h2>{selected.name} — complete source</h2><p className="muted">This pane is populated from the exact repository source above. Copying it gives the complete Solidity file, including interfaces, contract body, modifiers, events and functions. Nothing is intentionally abbreviated in this view.</p><textarea className="codebox" value={sourceState==='loading'?'Loading exact repository source…':sourceState==='error'?'Source could not be loaded from GitHub. Use GitHub Source ↗ or Open Exact File in Remix ↗.':source} readOnly spellCheck="false" aria-label={`Full source for ${selected.name}`}/><div className="source-meta"><span className="mono">RAW: {rawUrl}</span><span className="pill">{sourceState==='ready'?'FULL SOURCE LOADED':sourceState==='copied'?'COPIED':'SOURCE '+sourceState.toUpperCase()}</span></div></section>

  <section className="panel"><div className="eyebrow">4. DESCRIPTIONAL REMIX PROCEDURE</div><h2>From contract note to execution</h2><div className="steps">
   {[
    ['SELECT','Choose the named `.sol` file above. Read its status and contract note before doing anything on-chain.'],
    ['OPEN IN REMIX','Use the direct Remix link. Remix loads the exact GitHub file into its temporary `code-sample` workspace. Rename/save the workspace if you need persistence.'],
    ['COMPILE','Select the compiler shown in the contract note and compile the exact filename. Resolve every warning/error before continuing.'],
    ['CONFIGURE','Confirm provider/pair, token addresses, routers, decimals, minimum outputs, deadline, fee/premium and constructor arguments from independently verified network data.'],
    ['CONTROLLED TEST','Run on Fuji or a controlled fork. Verify callback authorization, repayment, events, balances, gas, pause/rescue and profit-floor behavior.'],
    ['MAINNET','Only after all assurance gates pass should the connected wallet sign a bounded deployment or interaction transaction. Cloud state never signs or authorizes spending.']
   ].map(([name,desc],i)=><div key={name} className="step"><span className="stepno">{i+1}</span><span><strong>{name}</strong><span className="muted">{desc}</span></span></div>)}
  </div><div className="notice small">The direct Remix link is a source-loading convenience, not a deployment link. `IMPORTABLE` ≠ `CONTROLLED TEST` ≠ `READY` ≠ `LIVE`.</div></section>

  <section className="panel"><div className="eyebrow">5. CONTROLLED EXECUTION LIFECYCLE</div><div className="steps">{[['OBSERVE','Confirm wallet, chain, provider, liquidity, token decimals, routes and current quotes.'],['CONFIGURE','Compile in Remix and configure exact deployed addresses, routers, assets and minimum outputs.'],['CONTROLLED TEST','Validate on Fuji or a controlled fork; verify repayment, events, gas and profit-floor behavior.'],['READY','Verify bytecode/source, owner, pause path, funding and monitoring before a mainnet write.'],['LIVE','Only the connected wallet signs a bounded transaction; cloud automation cannot authorize spending.']].map(([name,desc],i)=><button key={name} className={`step ${gate===name?'active':''}`} onClick={()=>setLifecycle(name,i)}><span className="stepno">{i+1}</span><span><strong>{name}</strong><span className="muted">{desc}</span></span></button>)}</div><div className="notice small">Safety gate: templates do not guarantee profit. Provider addresses, pair fee model, liquidity, routes, slippage, gas and repayment must be independently verified at execution time.</div></section>
  <footer className="footer muted small">Vercel hosts the responsive control plane. Remix performs Solidity compilation/deployment/interaction. Avalanche C-Chain performs the actual transaction. Wallets retain signing authority. The cloud stores non-secret session state only. Full workflow: <a href="https://github.com/Samoolino/DAPP-REMIX-AVAX/blob/main/docs/REMIX-CONTRACT-WORKFLOW.md" target="_blank" rel="noreferrer">REMIX-CONTRACT-WORKFLOW.md ↗</a></footer>
 </main>
}
