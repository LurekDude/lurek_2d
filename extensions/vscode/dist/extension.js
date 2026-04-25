"use strict";var Ds=Object.create;var Wt=Object.defineProperty;var As=Object.getOwnPropertyDescriptor;var _s=Object.getOwnPropertyNames;var Bs=Object.getPrototypeOf,Fs=Object.prototype.hasOwnProperty;var Tt=(n,e)=>()=>(n&&(e=n(n=0)),e);var Oe=(n,e)=>()=>(e||n((e={exports:{}}).exports,e),e.exports),Gt=(n,e)=>{for(var t in e)Wt(n,t,{get:e[t],enumerable:!0})},Ma=(n,e,t,r)=>{if(e&&typeof e=="object"||typeof e=="function")for(let a of _s(e))!Fs.call(n,a)&&a!==t&&Wt(n,a,{get:()=>e[a],enumerable:!(r=As(e,a))||r.enumerable});return n};var C=(n,e,t)=>(t=n!=null?Ds(Bs(n)):{},Ma(e||!n||!n.__esModule?Wt(t,"default",{value:n,enumerable:!0}):t,n)),Ht=n=>Ma(Wt({},"__esModule",{value:!0}),n);function qe(n){return[nt.join(n,"docs","api","lurek.lua"),nt.join(n,"docs","api","lurek.md"),nt.join(n,"docs","lurek.lua"),nt.join(n,"docs","lua-api.md")].find(t=>Sa.existsSync(t))}function Ca(n,e){return hr(e)?zs(n):Ns(n)}function gr(n,e,t){return hr(e)?Os(n,t):Ws(n,t)}function ja(n,e,t){return hr(e)?Gs(n,t):Hs(n,t)}function hr(n){return nt.basename(n).toLowerCase()==="lurek.lua"}function zs(n){let e=n.split(`
`),t=new Map;for(let r=0;r<e.length;r++){let a=e[r].trim(),i=a.match(/^---@class\s+(lurek\.[A-Za-z0-9_]+)\s*$/);if(i){let p=i[1];t.has(p)||t.set(p,{label:p,line:r,kind:"module"});continue}let s=a.match(/^function\s+(lurek\.[A-Za-z0-9_]+\.[A-Za-z0-9_]+)\(/);if(s){let p=s[1];t.has(p)||t.set(p,{label:p,line:r,kind:"function"});continue}let o=a.match(/^function\s+(lurek\.[A-Za-z0-9_]+)\(/);if(o&&o[1].split(".").length===2){let p=o[1];t.has(p)||t.set(p,{label:p,line:r,kind:"callback"});continue}let l=a.match(/^function\s+([A-Za-z_][A-Za-z0-9_]*)[:.]([A-Za-z0-9_]+)\(/);if(l){let p=`${l[1]}:${l[2]}`;t.has(p)||t.set(p,{label:p,line:r,kind:"method"})}}return Array.from(t.values()).sort((r,a)=>r.label.localeCompare(a.label))}function Ns(n){return n.split(`
`).map((e,t)=>({line:e,index:t})).filter(({line:e})=>e.startsWith("## ")||e.startsWith("### ")).map(({line:e,index:t})=>({label:e.replace(/^#+\s*/,""),line:t,kind:"section"}))}function Os(n,e){let t=n.split(`
`),r=[`function ${e}(`,`---@class ${e}`];for(let a=0;a<t.length;a++){let i=t[a].trim();if(r.some(s=>i.startsWith(s)))return a}return-1}function Ws(n,e){let t=e.replace(/^lurek\./,"");return n.split(`
`).findIndex(r=>r.startsWith("##")&&(r.includes(e)||r.includes(t)))}function Gs(n,e){let t=e.toLowerCase(),a=Vs(n).filter(o=>o.text.toLowerCase().includes(t)).map(o=>o.text.trim()).filter(Boolean);if(a.length>0)return mr(a);let i=n.split(`
`),s=[];for(let o=0;o<i.length;o++){if(!i[o].toLowerCase().includes(t))continue;let l=Math.max(0,o-3),p=Math.min(i.length,o+4);s.push(i.slice(l,p).join(`
`).trim())}return mr(s.filter(Boolean))}function Hs(n,e){let t=n.split(`
`),r=e.toLowerCase(),a=[],i=[],s=!1;for(let o of t){if(o.startsWith("##")){s&&i.length>0&&a.push(i.join(`
`).trim()),i=[o],s=o.toLowerCase().includes(r);continue}i.push(o),o.toLowerCase().includes(r)&&(s=!0)}return s&&i.length>0&&a.push(i.join(`
`).trim()),mr(a.filter(Boolean))}function Vs(n){let e=n.split(`
`),t=[];for(let a=0;a<e.length;a++){let i=e[a].trim();if(!qs(i))continue;let s=a;for(;s>0&&e[s-1].trim().startsWith("---");)s--;t.push(s)}let r=Array.from(new Set(t)).sort((a,i)=>a-i);return r.map((a,i)=>{let s=i+1<r.length?r[i+1]:e.length;return{startLine:a,text:e.slice(a,s).join(`
`)}})}function qs(n){return/^---@class\s+lurek\./.test(n)||/^function\s+lurek\.[A-Za-z0-9_]+\.[A-Za-z0-9_]+\(/.test(n)||/^function\s+lurek\.[A-Za-z0-9_]+\(/.test(n)||/^function\s+[A-Za-z_][A-Za-z0-9_]*[:.][A-Za-z0-9_]+\(/.test(n)}function mr(n){return Array.from(new Set(n))}var Sa,nt,Vt=Tt(()=>{"use strict";Sa=C(require("fs")),nt=C(require("path"))});function $s(n){return n.length===0?'""':/[\s"]/u.test(n)?`"${n.replace(/"/g,'\\"')}"`:n}function yr(n,e=[]){return[n,...e].map($s).join(" ")}function ct(n){return yr(Ea,[La,...n])}function qt(n,e){e&&n.push("--verbose")}function fr(n,e={}){qt(n,e.verbose),e.nocapture&&n.push("--nocapture"),e.warmBuild&&n.push("--warm-build"),e.outerJobs!==void 0&&n.push("--outer-jobs",String(e.outerJobs)),e.testThreads!==void 0&&n.push("--test-threads",String(e.testThreads))}function Ia(n,e=!1){let t=["build",n];return qt(t,e),ct(t)}function Da(n=!1){let e=["check"];return qt(e,n),ct(e)}function Aa(n,e=[],t=!1){let r=["run",n];return qt(r,t),e.length>0&&r.push("--",...e),ct(r)}function $t(n={}){let e=["test","all"];return fr(e,n),ct(e)}function xt(n={}){let e=["test","lua"];return fr(e,n),ct(e)}function Us(n){return n.endsWith("_tests")?n:`${n}_tests`}function mt(n,e={}){let t=["test","target",Us(n)];return fr(t,e),ct(t)}function Ut(n,e,t=6e4){return new Promise(r=>{Ra.execFile(Ea,[La,...e],{cwd:n,timeout:t,maxBuffer:1024*1024,encoding:"utf-8"},(a,i,s)=>{let o=`${i||""}${s||""}`;if(a){r(`${o}
[exit code: ${a.code??"unknown"}]`);return}r(o||"(no output)")})})}var Ra,Ea,La,gt=Tt(()=>{"use strict";Ra=C(require("child_process")),Ea="python",La="tools/dev/parallel_cargo.py"});var br={};Gt(br,{getToolDefinitions:()=>Ys,handleCheckBuild:()=>Zs,handleGetApiDoc:()=>Qs,handleGetLogs:()=>eo,handleListExamples:()=>Js,handleRunExample:()=>Xs,handleRunLuaTest:()=>Ks});function Ys(){return[{name:"lurek2d.runExample",description:"Build and run a named Lurek2D example, returning its output.",inputSchema:{type:"object",properties:{name:{type:"string",description:'Name of the example directory (e.g. "hello_world").'}},required:["name"]}},{name:"lurek2d.getApiDoc",description:"Search the Lurek2D Lua API documentation for a query string.",inputSchema:{type:"object",properties:{query:{type:"string",description:'Search query (e.g. "lurek.graphics.draw" or "physics").'}},required:["query"]}},{name:"lurek2d.listExamples",description:"List all available Lurek2D example directories.",inputSchema:{type:"object",properties:{}}},{name:"lurek2d.runLuaTest",description:"Run a Lua test file against a debug build of Lurek2D.",inputSchema:{type:"object",properties:{file:{type:"string",description:"Path to the Lua test file, relative to workspace root."}},required:["file"]}},{name:"lurek2d.checkBuild",description:"Run the wrapper-backed repo check flow and return compiler diagnostics.",inputSchema:{type:"object",properties:{}}},{name:"lurek2d.getLogs",description:"Return the last N lines of Lurek2D engine log output.",inputSchema:{type:"object",properties:{lines:{type:"number",description:"Number of log lines to return (default: 50)."}}}}]}function Xs(n){return async e=>{let t=e.name;if(!t)return"Error: 'name' parameter is required.";let r=Le.join(n,"content","games","showcase",t);if(!Ie.existsSync(r)){let i=_a(n);return`Showcase game "${t}" not found. Available: ${i.join(", ")}`}let a=Le.posix.join("content","games","showcase",t);return Ut(n,["run","debug","--",a],12e4)}}function Qs(n){return async e=>{let t=e.query;if(!t)return"Error: 'query' parameter is required.";let r=qe(n);if(!r||!Ie.existsSync(r))return"API reference not found. Expected docs/api/lurek.lua or docs/api/lurek.md.";let a=Ie.readFileSync(r,"utf-8"),i=ja(a,r,t);return i.length===0?`No documentation found for "${t}".`:r.endsWith(".lua")?i.map(s=>`\`\`\`lua
${s}
\`\`\``).join(`

---

`):i.join(`

---

`)}}function Js(n){return async()=>{let e=_a(n);return e.length===0?"No showcase games found in content/games/showcase/.":e.join(`
`)}}function Ks(n){return async e=>{let t=e.file;if(!t)return"Error: 'file' parameter is required.";let r=Le.resolve(n,t);if(!r.startsWith(n))return"Error: file path must be within the workspace.";if(!Ie.existsSync(r))return`Test file not found: ${t}`;let a=Le.relative(n,r).replace(/\\/g,"/");return Ut(n,["run","debug","--",a],12e4)}}function Zs(n){return async()=>Ut(n,["check"],12e4)}function eo(n){return async e=>{let t=e.lines||50,r=[Le.join(n,"lurek2d.log"),Le.join(n,"target","lurek2d.log")];for(let a of r)if(Ie.existsSync(a))return Ie.readFileSync(a,"utf-8").split(`
`).slice(-t).join(`
`);return"No log file found. Engine logs are written to stdout by default. Use RUST_LOG=lurek2d=debug to enable verbose logging."}}function _a(n){let e=Le.join(n,"content","games","showcase");if(!Ie.existsSync(e))return[];try{return Ie.readdirSync(e,{withFileTypes:!0}).filter(t=>t.isDirectory()).map(t=>t.name)}catch{return[]}}var Ie,Le,vr=Tt(()=>{"use strict";Ie=C(require("fs")),Le=C(require("path"));Vt();gt()});var ci={};Gt(ci,{clearHistory:()=>di,openPerfDashboard:()=>Cr,recordSample:()=>Al});function Cr(n){if(De){De.reveal(Ct.ViewColumn.Two);return}De=Ct.window.createWebviewPanel("lurek.perfDashboard","Lurek2D Performance",Ct.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0}),De.webview.html=_l(),De.onDidDispose(()=>{De=void 0},null,n.subscriptions),De.webview.onDidReceiveMessage(e=>{e.type==="clear"&&di()},null,n.subscriptions),jr()}function Al(n,e,t){St.push({timestamp:Date.now(),fps:n,frameMs:e,luaHeapKb:t}),St.length>Dl&&St.shift(),De?.visible&&jr()}function di(){St.length=0,De?.visible&&jr()}function jr(){De&&De.webview.postMessage({type:"data",samples:[...St]})}function _l(){return`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline';">
<style>
  body { font-family: var(--vscode-font-family); color: var(--vscode-foreground); background: var(--vscode-editor-background); padding: 12px; margin: 0; }
  h2 { margin: 0 0 8px; font-size: 15px; }
  .stats { display: flex; gap: 24px; margin-bottom: 12px; }
  .stat { background: var(--vscode-editorWidget-background); border-radius: 4px; padding: 8px 14px; text-align: center; }
  .stat-value { font-size: 22px; font-weight: 700; color: var(--vscode-charts-green); }
  .stat-label { font-size: 11px; opacity: 0.7; }
  canvas { display: block; width: 100%; height: 120px; margin-bottom: 8px; background: var(--vscode-editorWidget-background); border-radius: 4px; }
  .chart-label { font-size: 11px; opacity: 0.6; margin-bottom: 4px; }
  button { background: var(--vscode-button-background); color: var(--vscode-button-foreground); border: none; padding: 4px 10px; border-radius: 3px; cursor: pointer; font-size: 12px; margin-top: 8px; }
  button:hover { background: var(--vscode-button-hoverBackground); }
  .empty { opacity: 0.5; font-size: 13px; margin-top: 20px; }
</style>
</head>
<body>
<h2>\u{1F3AE} Lurek2D Performance Dashboard</h2>
<div class="stats">
  <div class="stat"><div class="stat-value" id="fps">\u2013</div><div class="stat-label">FPS</div></div>
  <div class="stat"><div class="stat-value" id="frame">\u2013</div><div class="stat-label">Frame ms</div></div>
  <div class="stat"><div class="stat-value" id="heap">\u2013</div><div class="stat-label">Lua Heap</div></div>
  <div class="stat"><div class="stat-value" id="samples">0</div><div class="stat-label">Samples</div></div>
</div>

<p class="chart-label">FPS over time</p>
<canvas id="fpsChart" width="600" height="120"></canvas>
<p class="chart-label">Frame time (ms)</p>
<canvas id="msChart" width="600" height="120"></canvas>

<div id="empty" class="empty">No data yet \u2014 run your game with lurek.debug.connect() to stream performance data.</div>

<button onclick="clearData()">Clear History</button>

<script>
const vscode = acquireVsCodeApi();

let samples = [];

function clearData() {
  vscode.postMessage({ type: 'clear' });
}

function drawChart(canvasId, data, color) {
  const canvas = document.getElementById(canvasId);
  const ctx = canvas.getContext('2d');
  const W = canvas.offsetWidth || 600;
  const H = canvas.offsetHeight || 120;
  canvas.width = W;
  canvas.height = H;
  ctx.clearRect(0, 0, W, H);
  if (data.length < 2) return;
  const max = Math.max(...data) * 1.1 || 1;
  ctx.strokeStyle = color;
  ctx.lineWidth = 1.5;
  ctx.beginPath();
  for (let i = 0; i < data.length; i++) {
    const x = (i / (data.length - 1)) * W;
    const y = H - (data[i] / max) * (H - 4) - 2;
    i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
  }
  ctx.stroke();
  // Target line (FPS chart only)
  if (canvasId === 'fpsChart') {
    const target60y = H - (60 / max) * (H - 4) - 2;
    ctx.strokeStyle = 'rgba(255,200,0,0.4)';
    ctx.setLineDash([4, 4]);
    ctx.beginPath(); ctx.moveTo(0, target60y); ctx.lineTo(W, target60y); ctx.stroke();
    ctx.setLineDash([]);
  }
}

function updateUI() {
  if (samples.length === 0) {
    document.getElementById('empty').style.display = 'block';
    return;
  }
  document.getElementById('empty').style.display = 'none';
  const last = samples[samples.length - 1];
  document.getElementById('fps').textContent = last.fps.toFixed(0);
  document.getElementById('frame').textContent = last.frameMs.toFixed(2);
  document.getElementById('heap').textContent = last.luaHeapKb ? (last.luaHeapKb + ' KB') : '\u2013';
  document.getElementById('samples').textContent = samples.length;

  // Color-code FPS
  const fpsEl = document.getElementById('fps');
  fpsEl.style.color = last.fps >= 55 ? '#4ec9b0' : last.fps >= 30 ? '#dcdcaa' : '#f44747';

  drawChart('fpsChart', samples.map(s => s.fps), '#4ec9b0');
  drawChart('msChart', samples.map(s => s.frameMs), '#569cd6');
}

window.addEventListener('message', (event) => {
  const msg = event.data;
  if (msg.type === 'data') {
    samples = msg.samples;
    updateUI();
  }
});

// Redraw on resize
window.addEventListener('resize', updateUI);
</script>
</body>
</html>`}var Ct,De,St,Dl,Rr=Tt(()=>{"use strict";Ct=C(require("vscode")),St=[],Dl=300});var rs={};Gt(rs,{DebugBridge:()=>Bt});var ze,ns,ts,ap,ip,Bt,Gr=Tt(()=>{"use strict";ze=C(require("vscode")),ns=C(require("net")),ts=19740,ap=5e3,ip=1e4,Bt=class{socket=null;outputChannel;connected=!1;requestId=0;pending=new Map;buffer="";statsItem=null;statsInterval=null;constructor(){this.outputChannel=ze.window.createOutputChannel("Lurek2D Debug")}get isConnected(){return this.connected}async connect(e){if(this.connected)return this.outputChannel.appendLine("[debug] Already connected."),!0;let t=e??ze.workspace.getConfiguration("lurek.debugBridge").get("port",ts);return new Promise(r=>{let a=new ns.Socket,i=setTimeout(()=>{a.destroy(),this.outputChannel.appendLine(`[debug] Connection timed out on port ${t}`),r(!1)},ap);a.connect(t,"127.0.0.1",()=>{clearTimeout(i),this.socket=a,this.connected=!0,this.buffer="",this.outputChannel.appendLine(`[debug] Connected to Lurek2D on port ${t}`),r(!0)}),a.on("data",s=>this.onData(s)),a.on("error",s=>{clearTimeout(i),this.outputChannel.appendLine(`[debug] Connection error: ${s.message}`),this.cleanup(),r(!1)}),a.on("close",()=>{this.outputChannel.appendLine("[debug] Connection closed."),this.cleanup()})})}disconnect(){this.socket&&this.socket.destroy(),this.cleanup(),this.outputChannel.appendLine("[debug] Disconnected.")}async evaluate(e){let t=await this.sendRequest("evaluate",{expression:e});if(t.error)throw new Error(t.error);return String(t.data?.result??"nil")}async getVariables(){let e=await this.sendRequest("getVariables",{});if(e.error)throw new Error(e.error);let t=e.data?.variables;if(t&&typeof t=="object"){let r={};for(let[a,i]of Object.entries(t))r[a]=String(i);return r}return{}}async setBreakpoint(e,t){return!(await this.sendRequest("setBreakpoint",{file:e,line:t})).error}async removeBreakpoint(e,t){return!(await this.sendRequest("removeBreakpoint",{file:e,line:t})).error}async step(){await this.sendRequest("step",{})}async stepInto(){await this.sendRequest("stepInto",{})}async stepOut(){await this.sendRequest("stepOut",{})}async continueExecution(){await this.sendRequest("continue",{})}async hotReload(e){let r=(await ze.workspace.openTextDocument(e)).getText(),a=ze.workspace.asRelativePath(e,!1);return!(await this.sendRequest("hotReload",{file:a,content:r})).error}async getStats(){let e=await this.sendRequest("getStats",{});if(e.error)throw new Error(e.error);return{fps:Number(e.data?.fps??0),drawCalls:Number(e.data?.drawCalls??0),memory:Number(e.data?.memory??0)}}async getCallStack(){let e=await this.sendRequest("getCallStack",{});if(e.error)throw new Error(e.error);let t=e.data?.frames;return Array.isArray(t)?t.map((r,a)=>({level:a,source:String(r.source??"?"),line:Number(r.line??0),name:String(r.name??"?")})):[]}async takeScreenshot(){let e=await this.sendRequest("screenshot",{});if(e.error)throw new Error(e.error);return String(e.data?.png_base64??"")}getStatusInfo(){return{connected:this.connected,port:ze.workspace.getConfiguration("lurek.debugBridge").get("port",ts)}}startStatsPolling(){this.statsItem||(this.statsItem=ze.window.createStatusBarItem(ze.StatusBarAlignment.Right,50),this.statsItem.text="$(pulse) FPS: --",this.statsItem.tooltip="Lurek2D Engine Stats",this.statsItem.show(),this.statsInterval=setInterval(async()=>{if(!this.connected){this.stopStatsPolling();return}try{let e=await this.getStats();this.statsItem&&(this.statsItem.text=`$(pulse) FPS: ${e.fps} | Draw: ${e.drawCalls} | Mem: ${(e.memory/1024/1024).toFixed(1)}MB`)}catch{}},1e3))}stopStatsPolling(){this.statsInterval&&(clearInterval(this.statsInterval),this.statsInterval=null),this.statsItem&&(this.statsItem.dispose(),this.statsItem=null)}showOutput(){this.outputChannel.show()}dispose(){this.disconnect(),this.stopStatsPolling(),this.outputChannel.dispose()}sendRequest(e,t){return new Promise((r,a)=>{if(!this.connected||!this.socket){a(new Error("Not connected to Lurek2D engine."));return}let i=++this.requestId,s=JSON.stringify({id:i,type:e,data:t})+`
`,o=setTimeout(()=>{this.pending.delete(i),a(new Error(`Request ${e} timed out.`))},ip);this.pending.set(i,{resolve:r,reject:a,timer:o}),this.socket.write(s,l=>{l&&(clearTimeout(o),this.pending.delete(i),a(new Error(`Failed to send request: ${l.message}`)))})})}onData(e){this.buffer+=e.toString("utf-8");let t=this.buffer.split(`
`);this.buffer=t.pop()??"";for(let r of t){let a=r.trim();if(a)try{let i=JSON.parse(a),s=this.pending.get(i.id);s?(clearTimeout(s.timer),this.pending.delete(i.id),s.resolve(i)):this.outputChannel.appendLine(`[engine] ${a}`)}catch{this.outputChannel.appendLine(`[engine] ${a}`)}}}cleanup(){this.connected=!1,this.socket=null;for(let[,e]of this.pending)clearTimeout(e.timer),e.reject(new Error("Connection lost."));this.pending.clear(),this.stopStatsPolling()}}});var Jn=Oe(Ke=>{"use strict";Object.defineProperty(Ke,"__esModule",{value:!0});Ke.Event=Ke.Response=Ke.Message=void 0;var Ft=class{constructor(e){this.seq=0,this.type=e}};Ke.Message=Ft;var qr=class extends Ft{constructor(e,t){super("response"),this.request_seq=e.seq,this.command=e.command,t?(this.success=!1,this.message=t):this.success=!0}};Ke.Response=qr;var $r=class extends Ft{constructor(e,t){super("event"),this.event=e,t&&(this.body=t)}};Ke.Event=$r});var us=Oe(Zn=>{"use strict";Object.defineProperty(Zn,"__esModule",{value:!0});Zn.ProtocolServer=void 0;var hp=require("events"),zt=Jn(),Ur=class{get event(){return this._event||(this._event=(e,t)=>{this._listener=e,this._this=t;let r;return r={dispose:()=>{this._listener=void 0,this._this=void 0}},r}),this._event}fire(e){if(this._listener)try{this._listener.call(this._this,e)}catch{}}hasListener(){return!!this._listener}dispose(){this._listener=void 0,this._this=void 0}},Kn=class n extends hp.EventEmitter{constructor(){super(),this._sendMessage=new Ur,this._sequence=1,this._pendingRequests=new Map,this.onDidSendMessage=this._sendMessage.event}dispose(){}handleMessage(e){if(e.type==="request")this.dispatchRequest(e);else if(e.type==="response"){let t=e,r=this._pendingRequests.get(t.request_seq);r&&(this._pendingRequests.delete(t.request_seq),r(t))}}_isRunningInline(){return this._sendMessage&&this._sendMessage.hasListener()}start(e,t){this._writableStream=t,this._rawData=Buffer.alloc(0),e.on("data",r=>this._handleData(r)),e.on("close",()=>{this._emitEvent(new zt.Event("close"))}),e.on("error",r=>{this._emitEvent(new zt.Event("error","inStream error: "+(r&&r.message)))}),t.on("error",r=>{this._emitEvent(new zt.Event("error","outStream error: "+(r&&r.message)))}),e.resume()}stop(){this._writableStream&&this._writableStream.end()}sendEvent(e){this._send("event",e)}sendResponse(e){e.seq>0?console.error(`attempt to send more than one response for command ${e.command}`):this._send("response",e)}sendRequest(e,t,r,a){let i={command:e};if(t&&Object.keys(t).length>0&&(i.arguments=t),this._send("request",i),a){this._pendingRequests.set(i.seq,a);let s=setTimeout(()=>{clearTimeout(s);let o=this._pendingRequests.get(i.seq);o&&(this._pendingRequests.delete(i.seq),o(new zt.Response(i,"timeout")))},r)}}dispatchRequest(e){}_emitEvent(e){this.emit(e.event,e)}_send(e,t){if(t.type=e,t.seq=this._sequence++,this._writableStream){let r=JSON.stringify(t);this._writableStream.write(`Content-Length: ${Buffer.byteLength(r,"utf8")}\r
\r
${r}`,"utf8")}this._sendMessage.fire(t)}_handleData(e){for(this._rawData=Buffer.concat([this._rawData,e]);;){if(this._contentLength>=0){if(this._rawData.length>=this._contentLength){let t=this._rawData.toString("utf8",0,this._contentLength);if(this._rawData=this._rawData.slice(this._contentLength),this._contentLength=-1,t.length>0)try{let r=JSON.parse(t);this.handleMessage(r)}catch(r){this._emitEvent(new zt.Event("error","Error handling data: "+(r&&r.message)))}continue}}else{let t=this._rawData.indexOf(n.TWO_CRLF);if(t!==-1){let a=this._rawData.toString("utf8",0,t).split(`\r
`);for(let i=0;i<a.length;i++){let s=a[i].split(/: +/);s[0]=="Content-Length"&&(this._contentLength=+s[1])}this._rawData=this._rawData.slice(t+n.TWO_CRLF.length);continue}}break}}};Zn.ProtocolServer=Kn;Kn.TWO_CRLF=`\r
\r
`});var ds=Oe(er=>{"use strict";Object.defineProperty(er,"__esModule",{value:!0});er.runDebugAdapter=void 0;var yp=require("net");function fp(n){let e=0;if(process.argv.slice(2).forEach(function(r,a,i){let s=/^--server=(\d{4,5})$/.exec(r);s&&(e=parseInt(s[1],10))}),e>0)console.error(`waiting for debug protocol on port ${e}`),yp.createServer(r=>{console.error(">> accepted connection from client"),r.on("end",()=>{console.error(`>> client connection closed
`)});let a=new n(!1,!0);a.setRunAsServer(!0),a.start(r,r)}).listen(e);else{let r=new n(!1);process.on("SIGTERM",()=>{r.shutdown()}),r.start(process.stdin,process.stdout)}}er.runDebugAdapter=fp});var nr=Oe(_=>{"use strict";Object.defineProperty(_,"__esModule",{value:!0});_.DebugSession=_.ErrorDestination=_.MemoryEvent=_.InvalidatedEvent=_.ProgressEndEvent=_.ProgressUpdateEvent=_.ProgressStartEvent=_.CapabilitiesEvent=_.LoadedSourceEvent=_.ModuleEvent=_.BreakpointEvent=_.ThreadEvent=_.OutputEvent=_.ExitedEvent=_.TerminatedEvent=_.InitializedEvent=_.ContinuedEvent=_.StoppedEvent=_.CompletionItem=_.Module=_.Breakpoint=_.Variable=_.Thread=_.StackFrame=_.Scope=_.Source=void 0;var bp=us(),ce=Jn(),vp=ds(),cs=require("url"),Yr=class{constructor(e,t,r=0,a,i){this.name=e,this.path=t,this.sourceReference=r,a&&(this.origin=a),i&&(this.adapterData=i)}};_.Source=Yr;var Xr=class{constructor(e,t,r=!1){this.name=e,this.variablesReference=t,this.expensive=r}};_.Scope=Xr;var Qr=class{constructor(e,t,r,a=0,i=0){this.id=e,this.source=r,this.line=a,this.column=i,this.name=t}};_.StackFrame=Qr;var Jr=class{constructor(e,t){this.id=e,t?this.name=t:this.name="Thread #"+e}};_.Thread=Jr;var Kr=class{constructor(e,t,r=0,a,i){this.name=e,this.value=t,this.variablesReference=r,typeof i=="number"&&(this.namedVariables=i),typeof a=="number"&&(this.indexedVariables=a)}};_.Variable=Kr;var Zr=class{constructor(e,t,r,a){this.verified=e;let i=this;typeof t=="number"&&(i.line=t),typeof r=="number"&&(i.column=r),a&&(i.source=a)}setId(e){this.id=e}};_.Breakpoint=Zr;var ea=class{constructor(e,t){this.id=e,this.name=t}};_.Module=ea;var ta=class{constructor(e,t,r=0){this.label=e,this.start=t,this.length=r}};_.CompletionItem=ta;var na=class extends ce.Event{constructor(e,t,r){super("stopped"),this.body={reason:e},typeof t=="number"&&(this.body.threadId=t),typeof r=="string"&&(this.body.text=r)}};_.StoppedEvent=na;var ra=class extends ce.Event{constructor(e,t){super("continued"),this.body={threadId:e},typeof t=="boolean"&&(this.body.allThreadsContinued=t)}};_.ContinuedEvent=ra;var aa=class extends ce.Event{constructor(){super("initialized")}};_.InitializedEvent=aa;var ia=class extends ce.Event{constructor(e){if(super("terminated"),typeof e=="boolean"||e){let t=this;t.body={restart:e}}}};_.TerminatedEvent=ia;var sa=class extends ce.Event{constructor(e){super("exited"),this.body={exitCode:e}}};_.ExitedEvent=sa;var oa=class extends ce.Event{constructor(e,t="console",r){super("output"),this.body={category:t,output:e},r!==void 0&&(this.body.data=r)}};_.OutputEvent=oa;var la=class extends ce.Event{constructor(e,t){super("thread"),this.body={reason:e,threadId:t}}};_.ThreadEvent=la;var pa=class extends ce.Event{constructor(e,t){super("breakpoint"),this.body={reason:e,breakpoint:t}}};_.BreakpointEvent=pa;var ua=class extends ce.Event{constructor(e,t){super("module"),this.body={reason:e,module:t}}};_.ModuleEvent=ua;var da=class extends ce.Event{constructor(e,t){super("loadedSource"),this.body={reason:e,source:t}}};_.LoadedSourceEvent=da;var ca=class extends ce.Event{constructor(e){super("capabilities"),this.body={capabilities:e}}};_.CapabilitiesEvent=ca;var ma=class extends ce.Event{constructor(e,t,r){super("progressStart"),this.body={progressId:e,title:t},typeof r=="string"&&(this.body.message=r)}};_.ProgressStartEvent=ma;var ga=class extends ce.Event{constructor(e,t){super("progressUpdate"),this.body={progressId:e},typeof t=="string"&&(this.body.message=t)}};_.ProgressUpdateEvent=ga;var ha=class extends ce.Event{constructor(e,t){super("progressEnd"),this.body={progressId:e},typeof t=="string"&&(this.body.message=t)}};_.ProgressEndEvent=ha;var ya=class extends ce.Event{constructor(e,t,r){super("invalidated"),this.body={},e&&(this.body.areas=e),t&&(this.body.threadId=t),r&&(this.body.stackFrameId=r)}};_.InvalidatedEvent=ya;var fa=class extends ce.Event{constructor(e,t,r){super("memory"),this.body={memoryReference:e,offset:t,count:r}}};_.MemoryEvent=fa;var dt;(function(n){n[n.User=1]="User",n[n.Telemetry=2]="Telemetry"})(dt=_.ErrorDestination||(_.ErrorDestination={}));var tr=class n extends bp.ProtocolServer{constructor(e,t){super();let r=typeof e=="boolean"?e:!1;this._debuggerLinesStartAt1=r,this._debuggerColumnsStartAt1=r,this._debuggerPathsAreURIs=!1,this._clientLinesStartAt1=!0,this._clientColumnsStartAt1=!0,this._clientPathsAreURIs=!1,this._isServer=typeof t=="boolean"?t:!1,this.on("close",()=>{this.shutdown()}),this.on("error",a=>{this.shutdown()})}setDebuggerPathFormat(e){this._debuggerPathsAreURIs=e!=="path"}setDebuggerLinesStartAt1(e){this._debuggerLinesStartAt1=e}setDebuggerColumnsStartAt1(e){this._debuggerColumnsStartAt1=e}setRunAsServer(e){this._isServer=e}static run(e){(0,vp.runDebugAdapter)(e)}shutdown(){this._isServer||this._isRunningInline()||setTimeout(()=>{process.exit(0)},100)}sendErrorResponse(e,t,r,a,i=dt.User){let s;typeof t=="number"?(s={id:t,format:r},a&&(s.variables=a),i&dt.User&&(s.showUser=!0),i&dt.Telemetry&&(s.sendTelemetry=!0)):s=t,e.success=!1,e.message=n.formatPII(s.format,!0,s.variables),e.body||(e.body={}),e.body.error=s,this.sendResponse(e)}runInTerminalRequest(e,t,r){this.sendRequest("runInTerminal",e,t,r)}dispatchRequest(e){let t=new ce.Response(e);try{if(e.command==="initialize"){var r=e.arguments;if(typeof r.linesStartAt1=="boolean"&&(this._clientLinesStartAt1=r.linesStartAt1),typeof r.columnsStartAt1=="boolean"&&(this._clientColumnsStartAt1=r.columnsStartAt1),r.pathFormat!=="path")this.sendErrorResponse(t,2018,"debug adapter only supports native paths",null,dt.Telemetry);else{let a=t;a.body={},this.initializeRequest(a,r)}}else e.command==="launch"?this.launchRequest(t,e.arguments,e):e.command==="attach"?this.attachRequest(t,e.arguments,e):e.command==="disconnect"?this.disconnectRequest(t,e.arguments,e):e.command==="terminate"?this.terminateRequest(t,e.arguments,e):e.command==="restart"?this.restartRequest(t,e.arguments,e):e.command==="setBreakpoints"?this.setBreakPointsRequest(t,e.arguments,e):e.command==="setFunctionBreakpoints"?this.setFunctionBreakPointsRequest(t,e.arguments,e):e.command==="setExceptionBreakpoints"?this.setExceptionBreakPointsRequest(t,e.arguments,e):e.command==="configurationDone"?this.configurationDoneRequest(t,e.arguments,e):e.command==="continue"?this.continueRequest(t,e.arguments,e):e.command==="next"?this.nextRequest(t,e.arguments,e):e.command==="stepIn"?this.stepInRequest(t,e.arguments,e):e.command==="stepOut"?this.stepOutRequest(t,e.arguments,e):e.command==="stepBack"?this.stepBackRequest(t,e.arguments,e):e.command==="reverseContinue"?this.reverseContinueRequest(t,e.arguments,e):e.command==="restartFrame"?this.restartFrameRequest(t,e.arguments,e):e.command==="goto"?this.gotoRequest(t,e.arguments,e):e.command==="pause"?this.pauseRequest(t,e.arguments,e):e.command==="stackTrace"?this.stackTraceRequest(t,e.arguments,e):e.command==="scopes"?this.scopesRequest(t,e.arguments,e):e.command==="variables"?this.variablesRequest(t,e.arguments,e):e.command==="setVariable"?this.setVariableRequest(t,e.arguments,e):e.command==="setExpression"?this.setExpressionRequest(t,e.arguments,e):e.command==="source"?this.sourceRequest(t,e.arguments,e):e.command==="threads"?this.threadsRequest(t,e):e.command==="terminateThreads"?this.terminateThreadsRequest(t,e.arguments,e):e.command==="evaluate"?this.evaluateRequest(t,e.arguments,e):e.command==="stepInTargets"?this.stepInTargetsRequest(t,e.arguments,e):e.command==="gotoTargets"?this.gotoTargetsRequest(t,e.arguments,e):e.command==="completions"?this.completionsRequest(t,e.arguments,e):e.command==="exceptionInfo"?this.exceptionInfoRequest(t,e.arguments,e):e.command==="loadedSources"?this.loadedSourcesRequest(t,e.arguments,e):e.command==="dataBreakpointInfo"?this.dataBreakpointInfoRequest(t,e.arguments,e):e.command==="setDataBreakpoints"?this.setDataBreakpointsRequest(t,e.arguments,e):e.command==="readMemory"?this.readMemoryRequest(t,e.arguments,e):e.command==="writeMemory"?this.writeMemoryRequest(t,e.arguments,e):e.command==="disassemble"?this.disassembleRequest(t,e.arguments,e):e.command==="cancel"?this.cancelRequest(t,e.arguments,e):e.command==="breakpointLocations"?this.breakpointLocationsRequest(t,e.arguments,e):e.command==="setInstructionBreakpoints"?this.setInstructionBreakpointsRequest(t,e.arguments,e):this.customRequest(e.command,t,e.arguments,e)}catch(a){this.sendErrorResponse(t,1104,"{_stack}",{_exception:a.message,_stack:a.stack},dt.Telemetry)}}initializeRequest(e,t){e.body.supportsConditionalBreakpoints=!1,e.body.supportsHitConditionalBreakpoints=!1,e.body.supportsFunctionBreakpoints=!1,e.body.supportsConfigurationDoneRequest=!0,e.body.supportsEvaluateForHovers=!1,e.body.supportsStepBack=!1,e.body.supportsSetVariable=!1,e.body.supportsRestartFrame=!1,e.body.supportsStepInTargetsRequest=!1,e.body.supportsGotoTargetsRequest=!1,e.body.supportsCompletionsRequest=!1,e.body.supportsRestartRequest=!1,e.body.supportsExceptionOptions=!1,e.body.supportsValueFormattingOptions=!1,e.body.supportsExceptionInfoRequest=!1,e.body.supportTerminateDebuggee=!1,e.body.supportsDelayedStackTraceLoading=!1,e.body.supportsLoadedSourcesRequest=!1,e.body.supportsLogPoints=!1,e.body.supportsTerminateThreadsRequest=!1,e.body.supportsSetExpression=!1,e.body.supportsTerminateRequest=!1,e.body.supportsDataBreakpoints=!1,e.body.supportsReadMemoryRequest=!1,e.body.supportsDisassembleRequest=!1,e.body.supportsCancelRequest=!1,e.body.supportsBreakpointLocationsRequest=!1,e.body.supportsClipboardContext=!1,e.body.supportsSteppingGranularity=!1,e.body.supportsInstructionBreakpoints=!1,e.body.supportsExceptionFilterOptions=!1,this.sendResponse(e)}disconnectRequest(e,t,r){this.sendResponse(e),this.shutdown()}launchRequest(e,t,r){this.sendResponse(e)}attachRequest(e,t,r){this.sendResponse(e)}terminateRequest(e,t,r){this.sendResponse(e)}restartRequest(e,t,r){this.sendResponse(e)}setBreakPointsRequest(e,t,r){this.sendResponse(e)}setFunctionBreakPointsRequest(e,t,r){this.sendResponse(e)}setExceptionBreakPointsRequest(e,t,r){this.sendResponse(e)}configurationDoneRequest(e,t,r){this.sendResponse(e)}continueRequest(e,t,r){this.sendResponse(e)}nextRequest(e,t,r){this.sendResponse(e)}stepInRequest(e,t,r){this.sendResponse(e)}stepOutRequest(e,t,r){this.sendResponse(e)}stepBackRequest(e,t,r){this.sendResponse(e)}reverseContinueRequest(e,t,r){this.sendResponse(e)}restartFrameRequest(e,t,r){this.sendResponse(e)}gotoRequest(e,t,r){this.sendResponse(e)}pauseRequest(e,t,r){this.sendResponse(e)}sourceRequest(e,t,r){this.sendResponse(e)}threadsRequest(e,t){this.sendResponse(e)}terminateThreadsRequest(e,t,r){this.sendResponse(e)}stackTraceRequest(e,t,r){this.sendResponse(e)}scopesRequest(e,t,r){this.sendResponse(e)}variablesRequest(e,t,r){this.sendResponse(e)}setVariableRequest(e,t,r){this.sendResponse(e)}setExpressionRequest(e,t,r){this.sendResponse(e)}evaluateRequest(e,t,r){this.sendResponse(e)}stepInTargetsRequest(e,t,r){this.sendResponse(e)}gotoTargetsRequest(e,t,r){this.sendResponse(e)}completionsRequest(e,t,r){this.sendResponse(e)}exceptionInfoRequest(e,t,r){this.sendResponse(e)}loadedSourcesRequest(e,t,r){this.sendResponse(e)}dataBreakpointInfoRequest(e,t,r){this.sendResponse(e)}setDataBreakpointsRequest(e,t,r){this.sendResponse(e)}readMemoryRequest(e,t,r){this.sendResponse(e)}writeMemoryRequest(e,t,r){this.sendResponse(e)}disassembleRequest(e,t,r){this.sendResponse(e)}cancelRequest(e,t,r){this.sendResponse(e)}breakpointLocationsRequest(e,t,r){this.sendResponse(e)}setInstructionBreakpointsRequest(e,t,r){this.sendResponse(e)}customRequest(e,t,r,a){this.sendErrorResponse(t,1014,"unrecognized request",null,dt.Telemetry)}convertClientLineToDebugger(e){return this._debuggerLinesStartAt1?this._clientLinesStartAt1?e:e+1:this._clientLinesStartAt1?e-1:e}convertDebuggerLineToClient(e){return this._debuggerLinesStartAt1?this._clientLinesStartAt1?e:e-1:this._clientLinesStartAt1?e+1:e}convertClientColumnToDebugger(e){return this._debuggerColumnsStartAt1?this._clientColumnsStartAt1?e:e+1:this._clientColumnsStartAt1?e-1:e}convertDebuggerColumnToClient(e){return this._debuggerColumnsStartAt1?this._clientColumnsStartAt1?e:e-1:this._clientColumnsStartAt1?e+1:e}convertClientPathToDebugger(e){return this._clientPathsAreURIs!==this._debuggerPathsAreURIs?this._clientPathsAreURIs?n.uri2path(e):n.path2uri(e):e}convertDebuggerPathToClient(e){return this._debuggerPathsAreURIs!==this._clientPathsAreURIs?this._debuggerPathsAreURIs?n.uri2path(e):n.path2uri(e):e}static path2uri(e){process.platform==="win32"&&(/^[A-Z]:/.test(e)&&(e=e[0].toLowerCase()+e.substr(1)),e=e.replace(/\\/g,"/")),e=encodeURI(e);let t=new cs.URL("file:");return t.pathname=e,t.toString()}static uri2path(e){let t=new cs.URL(e),r=decodeURIComponent(t.pathname);return process.platform==="win32"&&(/^\/[a-zA-Z]:/.test(r)&&(r=r[1].toLowerCase()+r.substr(2)),r=r.replace(/\//g,"\\")),r}static formatPII(e,t,r){return e.replace(n._formatPIIRegexp,function(a,i){return t&&i.length>0&&i[0]!=="_"?a:r[i]&&r.hasOwnProperty(i)?r[i]:a})}};_.DebugSession=tr;tr._formatPIIRegexp=/{([^}]+)}/g});var ys=Oe(ar=>{"use strict";Object.defineProperty(ar,"__esModule",{value:!0});ar.InternalLogger=void 0;var ms=require("fs"),gs=require("path"),ke=ir(),ba=class{constructor(e,t){this.beforeExitCallback=()=>this.dispose(),this._logCallback=e,this._logToConsole=t,this._minLogLevel=ke.LogLevel.Warn,this.disposeCallback=(r,a)=>{this.dispose(),a=a||2,a+=128,process.exit(a)}}async setup(e){if(this._minLogLevel=e.consoleMinLogLevel,this._prependTimestamp=e.prependTimestamp,e.logFilePath)if(!gs.isAbsolute(e.logFilePath))this.log(`logFilePath must be an absolute path: ${e.logFilePath}`,ke.LogLevel.Error);else{let t=r=>this.sendLog(`Error creating log file at path: ${e.logFilePath}. Error: ${r.toString()}
`,ke.LogLevel.Error);try{await ms.promises.mkdir(gs.dirname(e.logFilePath),{recursive:!0}),this.log(`Verbose logs are written to:
`,ke.LogLevel.Warn),this.log(e.logFilePath+`
`,ke.LogLevel.Warn),this._logFileStream=ms.createWriteStream(e.logFilePath),this.logDateTime(),this.setupShutdownListeners(),this._logFileStream.on("error",r=>{t(r)})}catch(r){t(r)}}}logDateTime(){let e=new Date,r=e.getUTCFullYear()+`-${e.getUTCMonth()+1}-`+e.getUTCDate()+", "+hs();this.log(r+`
`,ke.LogLevel.Verbose,!1)}setupShutdownListeners(){process.on("beforeExit",this.beforeExitCallback),process.on("SIGTERM",this.disposeCallback),process.on("SIGINT",this.disposeCallback)}removeShutdownListeners(){process.removeListener("beforeExit",this.beforeExitCallback),process.removeListener("SIGTERM",this.disposeCallback),process.removeListener("SIGINT",this.disposeCallback)}dispose(){return new Promise(e=>{this.removeShutdownListeners(),this._logFileStream?(this._logFileStream.end(e),this._logFileStream=null):e()})}log(e,t,r=!0){if(this._minLogLevel!==ke.LogLevel.Stop){if(t>=this._minLogLevel&&this.sendLog(e,t),this._logToConsole){let a=t===ke.LogLevel.Error?console.error:t===ke.LogLevel.Warn?console.warn:null;a&&a((0,ke.trimLastNewline)(e))}t===ke.LogLevel.Error&&(e=`[${ke.LogLevel[t]}] ${e}`),this._prependTimestamp&&r&&(e="["+hs()+"] "+e),this._logFileStream&&this._logFileStream.write(e)}}sendLog(e,t){if(e.length>1500){let r=!!e.match(/(\n|\r\n)$/);e=e.substr(0,1500)+"[...]",r&&(e=e+`
`)}if(this._logCallback){let r=new ke.LogOutputEvent(e,t);this._logCallback(r)}}};ar.InternalLogger=ba;function hs(){let n=new Date,e=rr(2,String(n.getUTCHours())),t=rr(2,String(n.getUTCMinutes())),r=rr(2,String(n.getUTCSeconds())),a=rr(3,String(n.getUTCMilliseconds()));return e+":"+t+":"+r+"."+a+" UTC"}function rr(n,e){return e.length>=n?e:String("0".repeat(n)+e).slice(-n)}});var ir=Oe(Me=>{"use strict";Object.defineProperty(Me,"__esModule",{value:!0});Me.trimLastNewline=Me.LogOutputEvent=Me.logger=Me.Logger=Me.LogLevel=void 0;var Tp=ys(),xp=nr(),Ze;(function(n){n[n.Verbose=0]="Verbose",n[n.Log=1]="Log",n[n.Warn=2]="Warn",n[n.Error=3]="Error",n[n.Stop=4]="Stop"})(Ze=Me.LogLevel||(Me.LogLevel={}));var sr=class{constructor(){this._pendingLogQ=[]}log(e,t=Ze.Log){e=e+`
`,this._write(e,t)}verbose(e){this.log(e,Ze.Verbose)}warn(e){this.log(e,Ze.Warn)}error(e){this.log(e,Ze.Error)}dispose(){if(this._currentLogger){let e=this._currentLogger.dispose();return this._currentLogger=null,e}else return Promise.resolve()}_write(e,t=Ze.Log){e=e+"",this._pendingLogQ?this._pendingLogQ.push({msg:e,level:t}):this._currentLogger&&this._currentLogger.log(e,t)}setup(e,t,r=!0){let a=typeof t=="string"?t:t&&this._logFilePathFromInit;if(this._currentLogger){let i={consoleMinLogLevel:e,logFilePath:a,prependTimestamp:r};this._currentLogger.setup(i).then(()=>{if(this._pendingLogQ){let s=this._pendingLogQ;this._pendingLogQ=null,s.forEach(o=>this._write(o.msg,o.level))}})}}init(e,t,r){this._pendingLogQ=this._pendingLogQ||[],this._currentLogger=new Tp.InternalLogger(e,r),this._logFilePathFromInit=t}};Me.Logger=sr;Me.logger=new sr;var va=class extends xp.OutputEvent{constructor(e,t){let r=t===Ze.Error?"stderr":t===Ze.Warn?"console":"stdout";super(e,r)}};Me.LogOutputEvent=va;function wp(n){return n.replace(/(\n|\r\n)$/,"")}Me.trimLastNewline=wp});var vs=Oe(or=>{"use strict";Object.defineProperty(or,"__esModule",{value:!0});or.LoggingDebugSession=void 0;var bs=ir(),vt=bs.logger,fs=nr(),Ta=class extends fs.DebugSession{constructor(e,t,r){super(t,r),this.obsolete_logFilePath=e,this.on("error",a=>{vt.error(a.body)})}start(e,t){super.start(e,t),vt.init(r=>this.sendEvent(r),this.obsolete_logFilePath,this._isServer)}sendEvent(e){if(!(e instanceof bs.LogOutputEvent)){let t=e;e instanceof fs.OutputEvent&&e.body&&e.body.data&&e.body.data.doNotLogOutput&&(delete e.body.data.doNotLogOutput,t={...e},t.body={...e.body,output:"<output not logged>"}),vt.verbose(`To client: ${JSON.stringify(t)}`)}super.sendEvent(e)}sendRequest(e,t,r,a){vt.verbose(`To client: ${JSON.stringify(e)}(${JSON.stringify(t)}), timeout: ${r}`),super.sendRequest(e,t,r,a)}sendResponse(e){vt.verbose(`To client: ${JSON.stringify(e)}`),super.sendResponse(e)}dispatchRequest(e){vt.verbose(`From client: ${e.command}(${JSON.stringify(e.arguments)})`),super.dispatchRequest(e)}};or.LoggingDebugSession=Ta});var Ts=Oe(lr=>{"use strict";Object.defineProperty(lr,"__esModule",{value:!0});lr.Handles=void 0;var xa=class{constructor(e){this.START_HANDLE=1e3,this._handleMap=new Map,this._nextHandle=typeof e=="number"?e:this.START_HANDLE}reset(){this._nextHandle=this.START_HANDLE,this._handleMap=new Map}create(e){var t=this._nextHandle++;return this._handleMap.set(t,e),t}get(e,t){return this._handleMap.get(e)||t}};lr.Handles=xa});var Ps=Oe(R=>{"use strict";Object.defineProperty(R,"__esModule",{value:!0});R.Handles=R.Response=R.Event=R.ErrorDestination=R.CompletionItem=R.Module=R.Source=R.Breakpoint=R.Variable=R.Scope=R.StackFrame=R.Thread=R.MemoryEvent=R.InvalidatedEvent=R.ProgressEndEvent=R.ProgressUpdateEvent=R.ProgressStartEvent=R.CapabilitiesEvent=R.LoadedSourceEvent=R.ModuleEvent=R.BreakpointEvent=R.ThreadEvent=R.OutputEvent=R.ContinuedEvent=R.StoppedEvent=R.ExitedEvent=R.TerminatedEvent=R.InitializedEvent=R.logger=R.Logger=R.LoggingDebugSession=R.DebugSession=void 0;var K=nr();Object.defineProperty(R,"DebugSession",{enumerable:!0,get:function(){return K.DebugSession}});Object.defineProperty(R,"InitializedEvent",{enumerable:!0,get:function(){return K.InitializedEvent}});Object.defineProperty(R,"TerminatedEvent",{enumerable:!0,get:function(){return K.TerminatedEvent}});Object.defineProperty(R,"ExitedEvent",{enumerable:!0,get:function(){return K.ExitedEvent}});Object.defineProperty(R,"StoppedEvent",{enumerable:!0,get:function(){return K.StoppedEvent}});Object.defineProperty(R,"ContinuedEvent",{enumerable:!0,get:function(){return K.ContinuedEvent}});Object.defineProperty(R,"OutputEvent",{enumerable:!0,get:function(){return K.OutputEvent}});Object.defineProperty(R,"ThreadEvent",{enumerable:!0,get:function(){return K.ThreadEvent}});Object.defineProperty(R,"BreakpointEvent",{enumerable:!0,get:function(){return K.BreakpointEvent}});Object.defineProperty(R,"ModuleEvent",{enumerable:!0,get:function(){return K.ModuleEvent}});Object.defineProperty(R,"LoadedSourceEvent",{enumerable:!0,get:function(){return K.LoadedSourceEvent}});Object.defineProperty(R,"CapabilitiesEvent",{enumerable:!0,get:function(){return K.CapabilitiesEvent}});Object.defineProperty(R,"ProgressStartEvent",{enumerable:!0,get:function(){return K.ProgressStartEvent}});Object.defineProperty(R,"ProgressUpdateEvent",{enumerable:!0,get:function(){return K.ProgressUpdateEvent}});Object.defineProperty(R,"ProgressEndEvent",{enumerable:!0,get:function(){return K.ProgressEndEvent}});Object.defineProperty(R,"InvalidatedEvent",{enumerable:!0,get:function(){return K.InvalidatedEvent}});Object.defineProperty(R,"MemoryEvent",{enumerable:!0,get:function(){return K.MemoryEvent}});Object.defineProperty(R,"Thread",{enumerable:!0,get:function(){return K.Thread}});Object.defineProperty(R,"StackFrame",{enumerable:!0,get:function(){return K.StackFrame}});Object.defineProperty(R,"Scope",{enumerable:!0,get:function(){return K.Scope}});Object.defineProperty(R,"Variable",{enumerable:!0,get:function(){return K.Variable}});Object.defineProperty(R,"Breakpoint",{enumerable:!0,get:function(){return K.Breakpoint}});Object.defineProperty(R,"Source",{enumerable:!0,get:function(){return K.Source}});Object.defineProperty(R,"Module",{enumerable:!0,get:function(){return K.Module}});Object.defineProperty(R,"CompletionItem",{enumerable:!0,get:function(){return K.CompletionItem}});Object.defineProperty(R,"ErrorDestination",{enumerable:!0,get:function(){return K.ErrorDestination}});var Pp=vs();Object.defineProperty(R,"LoggingDebugSession",{enumerable:!0,get:function(){return Pp.LoggingDebugSession}});var xs=ir();R.Logger=xs;var ws=Jn();Object.defineProperty(R,"Event",{enumerable:!0,get:function(){return ws.Event}});Object.defineProperty(R,"Response",{enumerable:!0,get:function(){return ws.Response}});var kp=Ts();Object.defineProperty(R,"Handles",{enumerable:!0,get:function(){return kp.Handles}});var Mp=xs.logger;R.logger=Mp});var jp={};Gt(jp,{activate:()=>Sp,deactivate:()=>Cp});module.exports=Ht(jp);var M=C(require("vscode")),dr=C(require("path")),Is=C(require("fs"));var Fa=C(require("readline"));function za(n){return{kill:()=>{}}}function to(n){let e=ro(n),t=ao(n);Fa.createInterface({input:process.stdin,output:void 0,terminal:!1}).on("line",a=>{let i=a.trim();if(!i)return;let s;try{s=JSON.parse(i)}catch{Ba({jsonrpc:"2.0",id:0,error:{code:-32700,message:"Parse error"}});return}no(s,e,t).then(o=>{Ba(o)})})}function Ba(n){let e=JSON.stringify(n);process.stdout.write(e+`
`)}async function no(n,e,t){let{id:r,method:a,params:i}=n;switch(a){case"initialize":return{jsonrpc:"2.0",id:r,result:{protocolVersion:"2024-11-05",capabilities:{tools:{}},serverInfo:{name:"lurek2d-mcp",version:"0.1.0"}}};case"notifications/initialized":return{jsonrpc:"2.0",id:r,result:{}};case"tools/list":return{jsonrpc:"2.0",id:r,result:{tools:t}};case"tools/call":{let s=i?.name,o=i?.arguments??{},l=e.get(s);if(!l)return{jsonrpc:"2.0",id:r,error:{code:-32601,message:`Unknown tool: ${s}`}};try{let p=await l(o);return{jsonrpc:"2.0",id:r,result:{content:[{type:"text",text:p}]}}}catch(p){return{jsonrpc:"2.0",id:r,result:{content:[{type:"text",text:`Error: ${p instanceof Error?p.message:String(p)}`}],isError:!0}}}}default:return{jsonrpc:"2.0",id:r,error:{code:-32601,message:`Method not found: ${a}`}}}}function ro(n){let{handleRunExample:e,handleGetApiDoc:t,handleListExamples:r,handleRunLuaTest:a,handleCheckBuild:i,handleGetLogs:s}=(vr(),Ht(br)),o=new Map;return o.set("lurek2d.runExample",e(n)),o.set("lurek2d.getApiDoc",t(n)),o.set("lurek2d.listExamples",r(n)),o.set("lurek2d.runLuaTest",a(n)),o.set("lurek2d.checkBuild",i(n)),o.set("lurek2d.getLogs",s(n)),o}function ao(n){let{getToolDefinitions:e}=(vr(),Ht(br));return e()}if(require.main===module){let n=process.argv.slice(2),e=process.cwd(),t=n.indexOf("--workspace");t!==-1&&n[t+1]&&(e=n[t+1]),to(e)}var xe=C(require("vscode")),wt=C(require("path")),Yt=C(require("fs"));gt();var Xt=class{terminal=null;_onStatusChange=new xe.EventEmitter;onStatusChange=this._onStatusChange.event;async findLurekBinary(){let e=xe.workspace.getConfiguration("lurek").get("enginePath","");if(e&&Yt.existsSync(e))return e;let t=process.platform==="win32"?"lurek2d.exe":"lurek2d",r=(process.env.PATH??"").split(wt.delimiter);for(let i of r){let s=wt.join(i,t);if(Yt.existsSync(s))return s}let a=Na();if(a){let i=wt.join(a,"Cargo.toml");if(Yt.existsSync(i))return}throw new Error("Lurek2D binary not found. Install it or set lurek.lurekPath in settings.")}async run(e,t=[]){if(this.isRunning()){xe.window.showWarningMessage("Lurek2D is already running.");return}xe.workspace.getConfiguration("lurek").get("saveOnRun",!0)&&await xe.workspace.saveAll(!1);let a=await this.findLurekBinary(),i=[e,...t],s=a?yr(a,i):Aa("debug",i);this.terminal=xe.window.createTerminal({name:"Lurek2D",cwd:Na()}),this.terminal.show(),this.terminal.sendText(s),this._onStatusChange.fire(!0),xe.commands.executeCommand("setContext","lurek.gameRunning",!0)}stop(){this.terminal&&(this.terminal.dispose(),this.terminal=null),this._onStatusChange.fire(!1),xe.commands.executeCommand("setContext","lurek.gameRunning",!1)}isRunning(){return this.terminal!==null}dispose(){this.stop(),this._onStatusChange.dispose()}};function Na(){return xe.workspace.workspaceFolders?.[0]?.uri.fsPath}var rt=C(require("vscode")),Qt=class{item;constructor(){this.item=rt.window.createStatusBarItem(rt.StatusBarAlignment.Left,100),this.setStopped(),this.item.show()}setRunning(){this.item.text="$(play) Lurek2D: Running",this.item.tooltip="Lurek2D game is running \u2014 click to stop",this.item.command="lurek.stopGame",this.item.backgroundColor=new rt.ThemeColor("statusBarItem.warningBackground")}setStopped(){this.item.text="$(rocket) Lurek2D",this.item.tooltip="Lurek2D Toolkit \u2014 click to run game",this.item.command="lurek.runGame",this.item.backgroundColor=void 0}setDebugConnected(){this.item.text="$(debug-alt) Lurek2D: Debug",this.item.tooltip="Lurek2D debug bridge connected",this.item.command="lurek.debug.status",this.item.backgroundColor=new rt.ThemeColor("statusBarItem.prominentBackground")}dispose(){this.item.dispose()}};var Kt=C(require("fs")),Oa=C(require("path")),io={string:{common:[{name:"byte",signature:"string.byte(s, i, j)",description:"Returns the internal numeric codes of the characters s[i], s[i+1], ..., s[j].",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"i",type:"number",description:"Start index",optional:!0,default:"1"},{name:"j",type:"number",description:"End index",optional:!0,default:"i"}],returns:"number..."},{name:"char",signature:"string.char(...)",description:"Returns a string with characters with the given internal numeric codes.",params:[{name:"...",type:"number",description:"Byte values",optional:!1}],returns:"string"},{name:"find",signature:"string.find(s, pattern, init, plain)",description:"Looks for the first match of pattern in the string.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"pattern",type:"string",description:"Search pattern",optional:!1},{name:"init",type:"number",description:"Start position",optional:!0,default:"1"},{name:"plain",type:"boolean",description:"Plain text search",optional:!0,default:"false"}],returns:"number, number, ...string"},{name:"format",signature:"string.format(formatstring, ...)",description:"Returns a formatted string following the description given in its arguments.",params:[{name:"formatstring",type:"string",description:"Format string",optional:!1},{name:"...",type:"any",description:"Format arguments",optional:!0}],returns:"string"},{name:"gmatch",signature:"string.gmatch(s, pattern)",description:"Returns an iterator function that returns the next captures from pattern over string s.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"pattern",type:"string",description:"Pattern",optional:!1}],returns:"function"},{name:"gsub",signature:"string.gsub(s, pattern, repl, n)",description:"Returns a copy of s in which all (or the first n) occurrences of the pattern are replaced.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"pattern",type:"string",description:"Pattern",optional:!1},{name:"repl",type:"string|table|function",description:"Replacement",optional:!1},{name:"n",type:"number",description:"Max replacements",optional:!0}],returns:"string, number"},{name:"len",signature:"string.len(s)",description:"Returns the length of the string.",params:[{name:"s",type:"string",description:"Input string",optional:!1}],returns:"number"},{name:"lower",signature:"string.lower(s)",description:"Returns a copy of this string with all uppercase letters changed to lowercase.",params:[{name:"s",type:"string",description:"Input string",optional:!1}],returns:"string"},{name:"match",signature:"string.match(s, pattern, init)",description:"Looks for the first match of pattern in the string.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"pattern",type:"string",description:"Pattern",optional:!1},{name:"init",type:"number",description:"Start position",optional:!0,default:"1"}],returns:"string..."},{name:"rep",signature:"string.rep(s, n, sep)",description:"Returns a string that is the concatenation of n copies of the string s.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"n",type:"number",description:"Repetitions",optional:!1},{name:"sep",type:"string",description:"Separator",optional:!0,default:'""'}],returns:"string"},{name:"reverse",signature:"string.reverse(s)",description:"Returns a string that is the string s reversed.",params:[{name:"s",type:"string",description:"Input string",optional:!1}],returns:"string"},{name:"sub",signature:"string.sub(s, i, j)",description:"Returns the substring from i to j.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"i",type:"number",description:"Start index",optional:!1},{name:"j",type:"number",description:"End index",optional:!0,default:"-1"}],returns:"string"},{name:"upper",signature:"string.upper(s)",description:"Returns a copy of this string with all lowercase letters changed to uppercase.",params:[{name:"s",type:"string",description:"Input string",optional:!1}],returns:"string"},{name:"dump",signature:"string.dump(function, strip)",description:"Returns a string containing a binary representation of the given function.",params:[{name:"function",type:"function",description:"Function to dump",optional:!1},{name:"strip",type:"boolean",description:"Strip debug info",optional:!0}],returns:"string"}]},table:{common:[{name:"concat",signature:"table.concat(list, sep, i, j)",description:"Concatenates elements of a table into a string.",params:[{name:"list",type:"table",description:"Input table",optional:!1},{name:"sep",type:"string",description:"Separator",optional:!0,default:'""'},{name:"i",type:"number",description:"Start index",optional:!0,default:"1"},{name:"j",type:"number",description:"End index",optional:!0,default:"#list"}],returns:"string"},{name:"insert",signature:"table.insert(list, pos, value)",description:"Inserts element value at position pos in list.",params:[{name:"list",type:"table",description:"Target table",optional:!1},{name:"pos",type:"number",description:"Position",optional:!0},{name:"value",type:"any",description:"Value to insert",optional:!1}],returns:"nil"},{name:"remove",signature:"table.remove(list, pos)",description:"Removes from list the element at position pos.",params:[{name:"list",type:"table",description:"Target table",optional:!1},{name:"pos",type:"number",description:"Position",optional:!0,default:"#list"}],returns:"any"},{name:"sort",signature:"table.sort(list, comp)",description:"Sorts list elements in-place using the given comparison function.",params:[{name:"list",type:"table",description:"Table to sort",optional:!1},{name:"comp",type:"function",description:"Comparison function",optional:!0}],returns:"nil"},{name:"unpack",signature:"table.unpack(list, i, j)",description:"Returns the elements from the given table.",params:[{name:"list",type:"table",description:"Input table",optional:!1},{name:"i",type:"number",description:"Start index",optional:!0,default:"1"},{name:"j",type:"number",description:"End index",optional:!0,default:"#list"}],returns:"any..."}],lua54Only:[{name:"move",signature:"table.move(a1, f, e, t, a2)",description:"Moves elements from table a1 into table a2.",params:[{name:"a1",type:"table",description:"Source table",optional:!1},{name:"f",type:"number",description:"From index",optional:!1},{name:"e",type:"number",description:"End index",optional:!1},{name:"t",type:"number",description:"Target start",optional:!1},{name:"a2",type:"table",description:"Dest table",optional:!0,default:"a1"}],returns:"table"},{name:"pack",signature:"table.pack(...)",description:"Returns a new table with all arguments stored into keys 1, 2, etc.",params:[{name:"...",type:"any",description:"Values to pack",optional:!1}],returns:"table"}],luajitOnly:[{name:"new",signature:"table.new(narray, nhash)",description:"Pre-allocates a table with the given number of array and hash slots.",params:[{name:"narray",type:"number",description:"Array slots",optional:!1},{name:"nhash",type:"number",description:"Hash slots",optional:!1}],returns:"table"},{name:"clear",signature:"table.clear(tab)",description:"Clears all keys and values from a table.",params:[{name:"tab",type:"table",description:"Table to clear",optional:!1}],returns:"nil"}]},math:{common:[{name:"abs",signature:"math.abs(x)",description:"Returns the absolute value of x.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"acos",signature:"math.acos(x)",description:"Returns the arc cosine of x (in radians).",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"asin",signature:"math.asin(x)",description:"Returns the arc sine of x (in radians).",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"atan",signature:"math.atan(y, x)",description:"Returns the arc tangent of y/x (in radians).",params:[{name:"y",type:"number",description:"Y value",optional:!1},{name:"x",type:"number",description:"X value",optional:!0,default:"1"}],returns:"number"},{name:"ceil",signature:"math.ceil(x)",description:"Returns the smallest integer larger than or equal to x.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"cos",signature:"math.cos(x)",description:"Returns the cosine of x (in radians).",params:[{name:"x",type:"number",description:"Angle in radians",optional:!1}],returns:"number"},{name:"deg",signature:"math.deg(x)",description:"Converts angle x from radians to degrees.",params:[{name:"x",type:"number",description:"Angle in radians",optional:!1}],returns:"number"},{name:"exp",signature:"math.exp(x)",description:"Returns the value e^x.",params:[{name:"x",type:"number",description:"Exponent",optional:!1}],returns:"number"},{name:"floor",signature:"math.floor(x)",description:"Returns the largest integer smaller than or equal to x.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"fmod",signature:"math.fmod(x, y)",description:"Returns the remainder of the division of x by y.",params:[{name:"x",type:"number",description:"Dividend",optional:!1},{name:"y",type:"number",description:"Divisor",optional:!1}],returns:"number"},{name:"huge",signature:"math.huge",description:"The value HUGE_VAL, representing positive infinity.",params:[],returns:"number"},{name:"log",signature:"math.log(x, base)",description:"Returns the logarithm of x in the given base.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"base",type:"number",description:"Log base",optional:!0,default:"e"}],returns:"number"},{name:"max",signature:"math.max(x, ...)",description:"Returns the maximum value among its arguments.",params:[{name:"x",type:"number",description:"First value",optional:!1},{name:"...",type:"number",description:"More values",optional:!0}],returns:"number"},{name:"min",signature:"math.min(x, ...)",description:"Returns the minimum value among its arguments.",params:[{name:"x",type:"number",description:"First value",optional:!1},{name:"...",type:"number",description:"More values",optional:!0}],returns:"number"},{name:"modf",signature:"math.modf(x)",description:"Returns the integral and fractional parts of x.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number, number"},{name:"pi",signature:"math.pi",description:"The value of pi.",params:[],returns:"number"},{name:"rad",signature:"math.rad(x)",description:"Converts angle x from degrees to radians.",params:[{name:"x",type:"number",description:"Angle in degrees",optional:!1}],returns:"number"},{name:"random",signature:"math.random(m, n)",description:"Returns a pseudo-random number.",params:[{name:"m",type:"number",description:"Lower bound",optional:!0},{name:"n",type:"number",description:"Upper bound",optional:!0}],returns:"number"},{name:"randomseed",signature:"math.randomseed(x)",description:"Sets x as the seed for the pseudo-random generator.",params:[{name:"x",type:"number",description:"Seed value",optional:!1}],returns:"nil"},{name:"sin",signature:"math.sin(x)",description:"Returns the sine of x (in radians).",params:[{name:"x",type:"number",description:"Angle in radians",optional:!1}],returns:"number"},{name:"sqrt",signature:"math.sqrt(x)",description:"Returns the square root of x.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"tan",signature:"math.tan(x)",description:"Returns the tangent of x (in radians).",params:[{name:"x",type:"number",description:"Angle in radians",optional:!1}],returns:"number"}],lua54Only:[{name:"maxinteger",signature:"math.maxinteger",description:"An integer with the maximum value for an integer.",params:[],returns:"integer"},{name:"mininteger",signature:"math.mininteger",description:"An integer with the minimum value for an integer.",params:[],returns:"integer"},{name:"tointeger",signature:"math.tointeger(x)",description:"If x is convertible to an integer, returns that integer.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"integer|nil"},{name:"type",signature:"math.type(x)",description:"Returns 'integer', 'float', or false.",params:[{name:"x",type:"any",description:"Value to check",optional:!1}],returns:"string|false"},{name:"ult",signature:"math.ult(m, n)",description:"Returns true if m < n when compared as unsigned integers.",params:[{name:"m",type:"integer",description:"First value",optional:!1},{name:"n",type:"integer",description:"Second value",optional:!1}],returns:"boolean"}]},os:{common:[{name:"clock",signature:"os.clock()",description:"Returns CPU time used by the program in seconds.",params:[],returns:"number"},{name:"date",signature:"os.date(format, time)",description:"Returns a string or table with date and time.",params:[{name:"format",type:"string",description:"Date format",optional:!0,default:'"%c"'},{name:"time",type:"number",description:"Time value",optional:!0}],returns:"string|table"},{name:"difftime",signature:"os.difftime(t2, t1)",description:"Returns the difference in seconds between two times.",params:[{name:"t2",type:"number",description:"End time",optional:!1},{name:"t1",type:"number",description:"Start time",optional:!1}],returns:"number"},{name:"time",signature:"os.time(table)",description:"Returns the current time or converts the given table to a timestamp.",params:[{name:"table",type:"table",description:"Date table",optional:!0}],returns:"number"}]},io:{common:[{name:"close",signature:"io.close(file)",description:"Closes file, or the default output file.",params:[{name:"file",type:"file",description:"File handle",optional:!0}],returns:"boolean"},{name:"lines",signature:"io.lines(filename, ...)",description:"Opens the given file and returns an iterator function.",params:[{name:"filename",type:"string",description:"File path",optional:!0},{name:"...",type:"string|number",description:"Read formats",optional:!0}],returns:"function"},{name:"open",signature:"io.open(filename, mode)",description:"Opens a file in the given mode.",params:[{name:"filename",type:"string",description:"File path",optional:!1},{name:"mode",type:"string",description:"Open mode",optional:!0,default:'"r"'}],returns:"file|nil, string"},{name:"read",signature:"io.read(...)",description:"Reads from the default input file.",params:[{name:"...",type:"string|number",description:"Read formats",optional:!0}],returns:"string|number|nil"},{name:"write",signature:"io.write(...)",description:"Writes to the default output file.",params:[{name:"...",type:"string|number",description:"Values to write",optional:!1}],returns:"file|nil, string"},{name:"type",signature:"io.type(obj)",description:"Checks whether obj is a valid file handle.",params:[{name:"obj",type:"any",description:"Value to check",optional:!1}],returns:"string|nil"}]},coroutine:{common:[{name:"create",signature:"coroutine.create(f)",description:"Creates a new coroutine with body f.",params:[{name:"f",type:"function",description:"Coroutine body",optional:!1}],returns:"thread"},{name:"resume",signature:"coroutine.resume(co, ...)",description:"Starts or continues the execution of coroutine co.",params:[{name:"co",type:"thread",description:"Coroutine",optional:!1},{name:"...",type:"any",description:"Arguments",optional:!0}],returns:"boolean, any..."},{name:"yield",signature:"coroutine.yield(...)",description:"Suspends the execution of the calling coroutine.",params:[{name:"...",type:"any",description:"Values to yield",optional:!0}],returns:"any..."},{name:"status",signature:"coroutine.status(co)",description:"Returns the status of coroutine co.",params:[{name:"co",type:"thread",description:"Coroutine",optional:!1}],returns:"string"},{name:"wrap",signature:"coroutine.wrap(f)",description:"Creates a coroutine and returns a resume function.",params:[{name:"f",type:"function",description:"Coroutine body",optional:!1}],returns:"function"},{name:"isyieldable",signature:"coroutine.isyieldable()",description:"Returns true if the running coroutine can yield.",params:[],returns:"boolean"},{name:"running",signature:"coroutine.running()",description:"Returns the running coroutine plus a boolean.",params:[],returns:"thread, boolean"}]},debug:{common:[{name:"getinfo",signature:"debug.getinfo(f, what)",description:"Returns a table with information about a function.",params:[{name:"f",type:"function|number",description:"Function or stack level",optional:!1},{name:"what",type:"string",description:"Info selector",optional:!0}],returns:"table"},{name:"getlocal",signature:"debug.getlocal(f, local)",description:"Returns name and value of local variable.",params:[{name:"f",type:"function|number",description:"Function or stack level",optional:!1},{name:"local",type:"number",description:"Local index",optional:!1}],returns:"string, any"},{name:"sethook",signature:"debug.sethook(hook, mask, count)",description:"Sets the given function as a hook.",params:[{name:"hook",type:"function",description:"Hook function",optional:!1},{name:"mask",type:"string",description:"Hook mask",optional:!1},{name:"count",type:"number",description:"Instruction count",optional:!0}],returns:"nil"},{name:"traceback",signature:"debug.traceback(message, level)",description:"Returns a string with a traceback of the call stack.",params:[{name:"message",type:"string",description:"Prefix message",optional:!0},{name:"level",type:"number",description:"Stack level",optional:!0,default:"1"}],returns:"string"}]},package:{common:[{name:"loaded",signature:"package.loaded",description:"A table of already-loaded modules.",params:[],returns:"table"},{name:"path",signature:"package.path",description:"The path used by require to search for a Lua loader.",params:[],returns:"string"},{name:"preload",signature:"package.preload",description:"A table to store loaders for specific modules.",params:[],returns:"table"},{name:"searchpath",signature:"package.searchpath(name, path, sep, rep)",description:"Searches for the given name in the given path.",params:[{name:"name",type:"string",description:"Module name",optional:!1},{name:"path",type:"string",description:"Search path",optional:!1},{name:"sep",type:"string",description:"Name separator",optional:!0,default:'"."'},{name:"rep",type:"string",description:"Replacement",optional:!0,default:'"/"'}],returns:"string|nil, string"}]},utf8:{common:[],lua54Only:[{name:"char",signature:"utf8.char(...)",description:"Returns a UTF-8 string from one or more codepoints.",params:[{name:"...",type:"number",description:"Codepoints",optional:!1}],returns:"string"},{name:"codepoint",signature:"utf8.codepoint(s, i, j)",description:"Returns the codepoints of all characters in s between positions i and j.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"i",type:"number",description:"Start",optional:!0,default:"1"},{name:"j",type:"number",description:"End",optional:!0,default:"i"}],returns:"number..."},{name:"codes",signature:"utf8.codes(s)",description:"Returns an iterator for all codepoints in string s.",params:[{name:"s",type:"string",description:"Input string",optional:!1}],returns:"function"},{name:"len",signature:"utf8.len(s, i, j)",description:"Returns the number of UTF-8 characters in string s.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"i",type:"number",description:"Start byte",optional:!0,default:"1"},{name:"j",type:"number",description:"End byte",optional:!0,default:"-1"}],returns:"number|nil, number"},{name:"offset",signature:"utf8.offset(s, n, i)",description:"Returns the byte position where the n-th character starts.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"n",type:"number",description:"Character offset",optional:!1},{name:"i",type:"number",description:"Start byte",optional:!0}],returns:"number"},{name:"charpattern",signature:"utf8.charpattern",description:"The pattern that matches exactly one UTF-8 byte sequence.",params:[],returns:"string"}]},bit:{common:[],luajitOnly:[{name:"tobit",signature:"bit.tobit(x)",description:"Normalizes a number to the numeric range of a 32-bit integer.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"tohex",signature:"bit.tohex(x, n)",description:"Converts x to a hex string with n digits.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"n",type:"number",description:"Number of digits",optional:!0}],returns:"string"},{name:"bnot",signature:"bit.bnot(x)",description:"Returns the bitwise NOT of x.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"band",signature:"bit.band(x1, ...)",description:"Returns the bitwise AND of all arguments.",params:[{name:"x1",type:"number",description:"First value",optional:!1},{name:"...",type:"number",description:"More values",optional:!0}],returns:"number"},{name:"bor",signature:"bit.bor(x1, ...)",description:"Returns the bitwise OR of all arguments.",params:[{name:"x1",type:"number",description:"First value",optional:!1},{name:"...",type:"number",description:"More values",optional:!0}],returns:"number"},{name:"bxor",signature:"bit.bxor(x1, ...)",description:"Returns the bitwise XOR of all arguments.",params:[{name:"x1",type:"number",description:"First value",optional:!1},{name:"...",type:"number",description:"More values",optional:!0}],returns:"number"},{name:"lshift",signature:"bit.lshift(x, n)",description:"Returns x logically shifted left by n bits.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"n",type:"number",description:"Shift amount",optional:!1}],returns:"number"},{name:"rshift",signature:"bit.rshift(x, n)",description:"Returns x logically shifted right by n bits.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"n",type:"number",description:"Shift amount",optional:!1}],returns:"number"},{name:"arshift",signature:"bit.arshift(x, n)",description:"Returns x arithmetically shifted right by n bits.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"n",type:"number",description:"Shift amount",optional:!1}],returns:"number"},{name:"rol",signature:"bit.rol(x, n)",description:"Returns x rotated left by n bits.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"n",type:"number",description:"Rotation amount",optional:!1}],returns:"number"},{name:"ror",signature:"bit.ror(x, n)",description:"Returns x rotated right by n bits.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"n",type:"number",description:"Rotation amount",optional:!1}],returns:"number"},{name:"bswap",signature:"bit.bswap(x)",description:"Swaps the bytes of x (byte-reverse).",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"}]},jit:{common:[],luajitOnly:[{name:"on",signature:"jit.on(func, recursive)",description:"Enables JIT compilation.",params:[{name:"func",type:"function",description:"Function or true for all",optional:!0},{name:"recursive",type:"boolean",description:"Include sub-functions",optional:!0}],returns:"nil"},{name:"off",signature:"jit.off(func, recursive)",description:"Disables JIT compilation.",params:[{name:"func",type:"function",description:"Function or true for all",optional:!0},{name:"recursive",type:"boolean",description:"Include sub-functions",optional:!0}],returns:"nil"},{name:"flush",signature:"jit.flush(func, recursive)",description:"Flushes the compiled code cache.",params:[{name:"func",type:"function",description:"Function to flush",optional:!0},{name:"recursive",type:"boolean",description:"Include sub-functions",optional:!0}],returns:"nil"},{name:"status",signature:"jit.status()",description:"Returns the current JIT status and architecture.",params:[],returns:"boolean, string..."},{name:"version",signature:"jit.version",description:"The LuaJIT version string.",params:[],returns:"string"},{name:"version_num",signature:"jit.version_num",description:"The LuaJIT version number.",params:[],returns:"number"},{name:"os",signature:"jit.os",description:"The target OS name.",params:[],returns:"string"},{name:"arch",signature:"jit.arch",description:"The target architecture name.",params:[],returns:"string"}]},ffi:{common:[],luajitOnly:[{name:"cdef",signature:"ffi.cdef(def)",description:"Adds C declarations.",params:[{name:"def",type:"string",description:"C declarations",optional:!1}],returns:"nil"},{name:"new",signature:"ffi.new(ctype, ...)",description:"Creates a C data object of the given type.",params:[{name:"ctype",type:"string|ctype",description:"C type",optional:!1},{name:"...",type:"any",description:"Initializers",optional:!0}],returns:"cdata"},{name:"cast",signature:"ffi.cast(ctype, init)",description:"Creates a scalar C data object with ctype and init.",params:[{name:"ctype",type:"string|ctype",description:"Target type",optional:!1},{name:"init",type:"any",description:"Initial value",optional:!1}],returns:"cdata"},{name:"typeof",signature:"ffi.typeof(ctype)",description:"Creates a C type object.",params:[{name:"ctype",type:"string",description:"C type declaration",optional:!1}],returns:"ctype"},{name:"sizeof",signature:"ffi.sizeof(ctype, nelem)",description:"Returns the size of a C type in bytes.",params:[{name:"ctype",type:"string|ctype|cdata",description:"C type",optional:!1},{name:"nelem",type:"number",description:"Number of elements",optional:!0}],returns:"number"},{name:"alignof",signature:"ffi.alignof(ctype)",description:"Returns the minimum required alignment of a C type.",params:[{name:"ctype",type:"string|ctype",description:"C type",optional:!1}],returns:"number"},{name:"istype",signature:"ffi.istype(ctype, obj)",description:"Returns true if obj has the given C type.",params:[{name:"ctype",type:"string|ctype",description:"C type",optional:!1},{name:"obj",type:"any",description:"Object to check",optional:!1}],returns:"boolean"},{name:"load",signature:"ffi.load(name, global)",description:"Loads a shared library.",params:[{name:"name",type:"string",description:"Library name",optional:!1},{name:"global",type:"boolean",description:"Export symbols globally",optional:!0}],returns:"clib"},{name:"string",signature:"ffi.string(ptr, len)",description:"Creates a Lua string from a C char pointer.",params:[{name:"ptr",type:"cdata",description:"Char pointer",optional:!1},{name:"len",type:"number",description:"Length",optional:!0}],returns:"string"},{name:"copy",signature:"ffi.copy(dst, src, len)",description:"Copies data between C objects.",params:[{name:"dst",type:"cdata",description:"Destination",optional:!1},{name:"src",type:"cdata|string",description:"Source",optional:!1},{name:"len",type:"number",description:"Byte count",optional:!0}],returns:"nil"},{name:"fill",signature:"ffi.fill(dst, len, c)",description:"Fills a memory region with a byte value.",params:[{name:"dst",type:"cdata",description:"Destination",optional:!1},{name:"len",type:"number",description:"Byte count",optional:!1},{name:"c",type:"number",description:"Fill byte",optional:!0,default:"0"}],returns:"nil"},{name:"gc",signature:"ffi.gc(cdata, finalizer)",description:"Associates a finalizer with a C data object.",params:[{name:"cdata",type:"cdata",description:"C data object",optional:!1},{name:"finalizer",type:"function",description:"Finalizer function",optional:!1}],returns:"cdata"}]}},Jt=class{modules=new Map;allFunctions=new Map;enums=new Map;methodsByObjectType=new Map;callbackList=[];keyNames=[];gamepadButtons=[];gamepadAxes=[];loaded=!1;async load(e){if(this.loaded)return;let t=Oa.join(e,"data","lurek-api.json");if(Kt.existsSync(t))try{let r=Kt.readFileSync(t,"utf-8");this.loadFromJson(JSON.parse(r))}catch{}this.loaded=!0}getModuleNames(){return Array.from(this.modules.keys())}getModule(e){return this.modules.get(e)}getFunctions(e){return this.modules.get(e)?.functions??[]}getFunction(e){return this.allFunctions.get(e)}getAllFunctions(){return Array.from(this.allFunctions.values())}searchFunctions(e){let t=e.toLowerCase(),r=[];for(let a of this.allFunctions.values())(a.fullPath.toLowerCase().includes(t)||a.name.toLowerCase().includes(t)||a.description.toLowerCase().includes(t))&&r.push(a);return r}getMethods(e){return this.methodsByObjectType.get(e)??[]}getMethod(e,t){return this.methodsByObjectType.get(e)?.find(a=>a.name===t)}getFactoryTypes(){let e=new Set(["nil","any","string","number","boolean","table","function","multiple","integer","thread","userdata"]),t=new Map;for(let r of this.allFunctions.values())if(!r.isMethod&&r.returnType){let a=r.returnType.trim();a.length>0&&!e.has(a.toLowerCase())&&t.set(r.fullPath,a)}return t}getEnumValues(e){return this.enums.get(e)?.values??[]}getEnum(e){return this.enums.get(e)}getCallbacks(){return this.callbackList}getKeyNames(){return this.keyNames}getGamepadButtons(){return this.gamepadButtons}getGamepadAxes(){return this.gamepadAxes}getLuaStdlib(e){let t=[];for(let[r,a]of Object.entries(io)){for(let i of a.common)t.push(this.stdlibToApiFunction(r,i));if(e==="5.4"&&a.lua54Only)for(let i of a.lua54Only)t.push(this.stdlibToApiFunction(r,i));if(e==="luajit"&&a.luajitOnly)for(let i of a.luajitOnly)t.push(this.stdlibToApiFunction(r,i))}return t}getStats(){let e=0,t=0,r=0;for(let a of this.modules.values())e+=a.functions.length,t+=a.methods.length,r+=a.documentedEntries;return{modules:this.modules.size,functions:e,methods:t,documented:r}}loadFromJson(e){if(!e||typeof e!="object")return;let t=e;if(Array.isArray(t.modules))for(let i of t.modules){let s=String(i.name??""),o={name:s,fullPath:`lurek.${s}`,description:String(i.description??""),functions:[],methods:[],totalEntries:0,documentedEntries:0},l=Array.isArray(i.functions)?i.functions:[];for(let u of l){let d=this.rawToApiFunction(s,u);d.isMethod?(o.methods.push(d),this.indexMethod(d)):o.functions.push(d),this.allFunctions.set(d.fullPath,d)}let p=Array.isArray(i.methods)?i.methods:[];for(let u of p){let d=this.rawToApiFunction(s,u);d.isMethod=!0,o.methods.push(d),this.indexMethod(d),this.allFunctions.set(d.fullPath,d)}o.totalEntries=o.functions.length+o.methods.length,o.documentedEntries=[...o.functions,...o.methods].filter(u=>u.description.length>0).length,this.modules.set(s,o)}let r=t.enums;if(r&&typeof r=="object"&&!Array.isArray(r))for(let[i,s]of Object.entries(r))Array.isArray(s)&&this.enums.set(i,{name:i,values:s,descriptions:new Map});let a=Array.isArray(t.callbacks)?t.callbacks:[];if(this.callbackList=a.map(i=>({module:"",name:String(i.name??""),fullPath:`lurek.${i.name??""}`,signature:String(i.signature??""),description:String(i.description??""),parameters:Array.isArray(i.parameters)?i.parameters.map(s=>({name:String(s.name??""),type:String(s.type??"any"),description:String(s.description??""),optional:!!s.optional})):[],isMethod:!1})),Array.isArray(t.classes))for(let i of t.classes){let s=String(i.name??""),o=Array.isArray(i.methods)?i.methods:[];for(let l of o){let p=this.rawToApiFunction(s,l);p.isMethod=!0,p.objectType||(p.objectType=s),this.allFunctions.has(p.fullPath)||(this.allFunctions.set(p.fullPath,p),this.indexMethod(p))}}this.keyNames=Array.isArray(t.keyNames)?t.keyNames:[],this.gamepadButtons=Array.isArray(t.gamepadButtons)?t.gamepadButtons:[],this.gamepadAxes=Array.isArray(t.gamepadAxes)?t.gamepadAxes:[]}rawToApiFunction(e,t){let r=String(t.name??""),a=String(t.fullPath??`lurek.${e}.${r}`),i=Array.isArray(t.parameters)?t.parameters.map(s=>({name:String(s.name??""),type:String(s.type??"any"),description:String(s.description??""),optional:!!s.optional,default:s.default!=null?String(s.default):void 0})):[];return{module:e,name:r,fullPath:a,signature:String(t.signature??`${a}(${i.map(s=>s.name).join(", ")})`),description:String(t.description??""),parameters:i,returns:t.returns!=null?String(t.returns):void 0,returnType:t.returnType!=null?String(t.returnType):void 0,since:t.since!=null?String(t.since):void 0,deprecated:t.deprecated!=null?String(t.deprecated):void 0,isMethod:!!t.isMethod,objectType:t.objectType!=null?String(t.objectType):void 0,sourceFile:t.sourceFile!=null?String(t.sourceFile):void 0}}indexMethod(e){let t=e.objectType;if(!t)return;let r=this.methodsByObjectType.get(t);r||(r=[],this.methodsByObjectType.set(t,r)),r.push(e)}stdlibToApiFunction(e,t){return{module:e,name:t.name,fullPath:`${e}.${t.name}`,signature:t.signature,description:t.description,parameters:t.params,returns:t.returns,returnType:t.returns,isMethod:!1}}};var T=C(require("vscode")),$e=C(require("fs")),at=C(require("path")),w=class extends T.TreeItem{constructor(t,r,a,i,s){super(t,r);this.label=t;this.collapsibleState=r;this.commandId=a;this.icon=i;this.statusDescription=s;a&&(this.command={command:a,title:t}),i&&(this.iconPath=new T.ThemeIcon(i)),s&&(this.description=s)}},Zt=class{_onDidChangeTreeData=new T.EventEmitter;onDidChangeTreeData=this._onDidChangeTreeData.event;refresh(){this._onDidChangeTreeData.fire(void 0)}getTreeItem(e){return e}getChildren(e){if(!e)return[new w("Project Health",T.TreeItemCollapsibleState.Expanded,void 0,"heart"),new w("Create",T.TreeItemCollapsibleState.Expanded,void 0,"new-folder"),new w("Package",T.TreeItemCollapsibleState.Collapsed,void 0,"package"),new w("Libraries",T.TreeItemCollapsibleState.Collapsed,void 0,"library")];switch(e.label){case"Project Health":return this.getProjectHealthItems();case"Create":return[new w("New Project from Template",T.TreeItemCollapsibleState.None,"lurek.scaffold.project","file-add"),new w("New File from Template",T.TreeItemCollapsibleState.None,"lurek.scaffold.file","new-file")];case"Package":return[new w("Package .zip",T.TreeItemCollapsibleState.None,"lurek.package.zip","file-zip"),new w("Package for Windows",T.TreeItemCollapsibleState.None,"lurek.package.windows","desktop-download"),new w("Package for Linux",T.TreeItemCollapsibleState.None,"lurek.package.linux","terminal-linux")];case"Libraries":return[new w("Browse Pattern Library",T.TreeItemCollapsibleState.None,"lurek.library.browse","search"),new w("Insert Code Snippet",T.TreeItemCollapsibleState.None,"lurek.library.insertSnippet","code"),new w("Save Selection as Pattern",T.TreeItemCollapsibleState.None,"lurek.library.newPattern","save")];default:return[]}}getProjectHealthItems(){let e=T.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!e)return[new w("No workspace open",T.TreeItemCollapsibleState.None,void 0,"warning")];let t=[],r=$e.existsSync(at.join(e,"main.lua"));t.push(new w("main.lua",T.TreeItemCollapsibleState.None,r?void 0:"lurek.scaffold.file",r?"pass":"error",r?"found":"missing"));let a=$e.existsSync(at.join(e,"conf.lua"));t.push(new w("conf.lua",T.TreeItemCollapsibleState.None,void 0,a?"pass":"warning",a?"found":"optional"));let i=0;try{let o=l=>{let p=$e.readdirSync(l,{withFileTypes:!0});for(let u of p){if(u.name.startsWith(".")||u.name==="node_modules")continue;let d=at.join(l,u.name);u.isDirectory()?o(d):u.name.endsWith(".lua")&&i++}};o(e)}catch{}t.push(new w("Lua files",T.TreeItemCollapsibleState.None,void 0,"file-code",`${i}`));let s=$e.existsSync(at.join(e,"tests"))||$e.existsSync(at.join(e,"test"))||$e.existsSync(at.join(e,"tests.lua"));return t.push(new w("Tests",T.TreeItemCollapsibleState.None,void 0,s?"pass":"warning",s?"detected":"none found")),t}},en=class{_onDidChangeTreeData=new T.EventEmitter;onDidChangeTreeData=this._onDidChangeTreeData.event;_gameStatus="stopped";_lastTestResult;setGameStatus(e){this._gameStatus=e,this._onDidChangeTreeData.fire(void 0)}setTestResult(e){this._lastTestResult=e,this._onDidChangeTreeData.fire(void 0)}refresh(){this._onDidChangeTreeData.fire(void 0)}getTreeItem(e){return e}getChildren(e){if(!e)return[new w("Run",T.TreeItemCollapsibleState.Expanded,void 0,"play"),new w("Testing",T.TreeItemCollapsibleState.Collapsed,void 0,"beaker"),new w("Editors",T.TreeItemCollapsibleState.Collapsed,void 0,"window"),new w("Debug",T.TreeItemCollapsibleState.Collapsed,void 0,"bug"),new w("Reference",T.TreeItemCollapsibleState.Collapsed,void 0,"book"),new w("Assets",T.TreeItemCollapsibleState.Collapsed,void 0,"file-media"),new w("Dependencies",T.TreeItemCollapsibleState.Collapsed,void 0,"list-tree"),new w("Performance",T.TreeItemCollapsibleState.Collapsed,void 0,"dashboard")];switch(e.label){case"Run":return[new w("Game Status",T.TreeItemCollapsibleState.None,void 0,this._gameStatus==="running"?"debug-start":this._gameStatus==="crashed"?"error":"debug-stop",this._gameStatus),new w("Run Game",T.TreeItemCollapsibleState.None,"lurek.runGame","play"),new w("Stop Game",T.TreeItemCollapsibleState.None,"lurek.stopGame","debug-stop"),new w("Run with Arguments",T.TreeItemCollapsibleState.None,"lurek.runWithArgs","terminal"),new w("Run Example",T.TreeItemCollapsibleState.None,"lurek.runExample","file-code")];case"Testing":return[...this._lastTestResult?[new w("Last Result",T.TreeItemCollapsibleState.None,void 0,this._lastTestResult.includes("fail")?"error":"pass",this._lastTestResult)]:[],new w("Open Test Runner",T.TreeItemCollapsibleState.None,"lurek.editor.testRunner","beaker"),new w("Run All Tests",T.TreeItemCollapsibleState.None,"lurek.test.all","testing-run-all-icon"),new w("Run Lua Tests",T.TreeItemCollapsibleState.None,"lurek.test.lua.all","test-view-icon"),new w("Run Golden Tests",T.TreeItemCollapsibleState.None,"lurek.test.lua.golden","file-media"),new w("Generate Tests for File",T.TreeItemCollapsibleState.None,"lurek.test.generateForFile","wand")];case"Editors":return[new w("Tile Map Editor",T.TreeItemCollapsibleState.None,"lurek.editor.tileMap","symbol-misc"),new w("Tileset Editor",T.TreeItemCollapsibleState.None,"lurek.editor.tileset","layers"),new w("Tilemap Script Editor",T.TreeItemCollapsibleState.None,"lurek.editor.tilemapScript","code"),new w("World Map Editor",T.TreeItemCollapsibleState.None,"lurek.editor.worldMap","map"),new w("Procedural Map Generator",T.TreeItemCollapsibleState.None,"lurek.editor.procMap","globe"),new w("Pixel Art Editor",T.TreeItemCollapsibleState.None,"lurek.editor.pixelArt","paintcan"),new w("Sprite Animation Editor",T.TreeItemCollapsibleState.None,"lurek.editor.spriteAnim","play-circle"),new w("Shader Preview",T.TreeItemCollapsibleState.None,"lurek.editor.shaderPreview","wand"),new w("Color Palette",T.TreeItemCollapsibleState.None,"lurek.editor.colorPalette","symbol-color"),new w("Font Preview",T.TreeItemCollapsibleState.None,"lurek.editor.fontPreview","text-size"),new w("Scene Flow Editor",T.TreeItemCollapsibleState.None,"lurek.editor.sceneFlow","type-hierarchy"),new w("Entity Designer",T.TreeItemCollapsibleState.None,"lurek.editor.entity","symbol-class"),new w("Dialog Editor",T.TreeItemCollapsibleState.None,"lurek.editor.dialog","comment-discussion"),new w("Quest Tree Editor",T.TreeItemCollapsibleState.None,"lurek.editor.questTree","git-merge"),new w("GUI Widget Editor",T.TreeItemCollapsibleState.None,"lurek.editor.guiWidget","symbol-interface"),new w("Timeline / Cutscene",T.TreeItemCollapsibleState.None,"lurek.editor.timeline","history"),new w("Input Mapper",T.TreeItemCollapsibleState.None,"lurek.editor.inputMapper","keyboard"),new w("Localization Editor",T.TreeItemCollapsibleState.None,"lurek.editor.localization","book"),new w("Particle Designer",T.TreeItemCollapsibleState.None,"lurek.editor.particle","sparkle"),new w("Physics Materials",T.TreeItemCollapsibleState.None,"lurek.editor.physicsMaterials","settings-gear"),new w("AI Behavior Tree",T.TreeItemCollapsibleState.None,"lurek.editor.aiBehavior","hubot"),new w("Voxel Editor",T.TreeItemCollapsibleState.None,"lurek.editor.voxel","layers"),new w("Audio Mixer",T.TreeItemCollapsibleState.None,"lurek.editor.audioMixer","unmute"),new w("Sound DSP Panel",T.TreeItemCollapsibleState.None,"lurek.editor.soundDsp","radio-tower"),new w("PostFX & Overlay Designer",T.TreeItemCollapsibleState.None,"lurek.editor.postfxOverlay","color-mode"),new w("Database Browser",T.TreeItemCollapsibleState.None,"lurek.editor.database","database"),new w("Graph Editor",T.TreeItemCollapsibleState.None,"lurek.editor.graph","graph")];case"Debug":return[new w("Debug Run + Connect",T.TreeItemCollapsibleState.None,"lurek.debug.runAndConnect","debug-start"),new w("Connect",T.TreeItemCollapsibleState.None,"lurek.debug.connect","plug"),new w("Disconnect",T.TreeItemCollapsibleState.None,"lurek.debug.disconnect","debug-disconnect"),new w("Evaluate Lua",T.TreeItemCollapsibleState.None,"lurek.debug.evaluate","terminal"),new w("Watchers Panel",T.TreeItemCollapsibleState.None,"lurek.debug.openWatchers","eye"),new w("Variable Inspector",T.TreeItemCollapsibleState.None,"lurek.debug.openInspector","symbol-variable"),new w("Call Stack",T.TreeItemCollapsibleState.None,"lurek.debug.openCallStack","list-tree"),new w("Performance",T.TreeItemCollapsibleState.None,"lurek.debug.performance","dashboard"),new w("Screenshot",T.TreeItemCollapsibleState.None,"lurek.debug.screenshot","device-camera"),new w("Status",T.TreeItemCollapsibleState.None,"lurek.debug.status","info")];case"Reference":return[new w("Browse API",T.TreeItemCollapsibleState.None,"lurek.browseApi","search"),new w("Open API Docs",T.TreeItemCollapsibleState.None,"lurek.openApiDocs","book"),new w("Open Wiki",T.TreeItemCollapsibleState.None,"lurek.openWiki","globe"),new w("Dependency Graph",T.TreeItemCollapsibleState.None,"lurek.depGraph","graph"),new w("Dependency List",T.TreeItemCollapsibleState.None,"lurek.depList","list-tree"),new w("API Coverage",T.TreeItemCollapsibleState.None,"lurek.apiCoverage","graph-line")];case"Assets":return[new w("Refresh Assets",T.TreeItemCollapsibleState.None,"lurek.assets.refresh","refresh"),new w("Open Asset Explorer",T.TreeItemCollapsibleState.None,"lurek.assets.openPanel","file-media"),new w("Find Missing Assets",T.TreeItemCollapsibleState.None,"lurek.assets.findMissing","warning")];case"Dependencies":return[new w("Show Module Graph",T.TreeItemCollapsibleState.None,"lurek.deps.showGraph","type-hierarchy"),new w("Find Circular Deps",T.TreeItemCollapsibleState.None,"lurek.deps.findCircular","warning"),new w("Show Orphan Modules",T.TreeItemCollapsibleState.None,"lurek.deps.findOrphans","question")];case"Performance":return[new w("Open Performance Dashboard",T.TreeItemCollapsibleState.None,"lurek.perf.openDashboard","dashboard"),new w("System Monitor",T.TreeItemCollapsibleState.None,"lurek.runtime.openMonitor","pulse"),new w("API Usage Report",T.TreeItemCollapsibleState.None,"lurek.api.usageReport","graph"),new w("Open Hot Reload History",T.TreeItemCollapsibleState.None,"lurek.perf.openHotReload","history"),new w("Clear History",T.TreeItemCollapsibleState.None,"lurek.perf.clearHistory","clear-all")];default:return[]}}},tn=class{_onDidChangeTreeData=new T.EventEmitter;onDidChangeTreeData=this._onDidChangeTreeData.event;refresh(){this._onDidChangeTreeData.fire(void 0)}getTreeItem(e){return e}getChildren(e){if(!e)return[new w("CAG (AI Config)",T.TreeItemCollapsibleState.Expanded,void 0,"hubot"),new w("MCP Server",T.TreeItemCollapsibleState.Collapsed,void 0,"server"),new w("Game Jam",T.TreeItemCollapsibleState.Collapsed,void 0,"flame")];switch(e.label){case"CAG (AI Config)":return[new w("Install AI Config",T.TreeItemCollapsibleState.None,"lurek.cag.install","cloud-download"),new w("Select Agent",T.TreeItemCollapsibleState.None,"lurek.cag.selectAgent","person"),new w("Select Skill",T.TreeItemCollapsibleState.None,"lurek.cag.selectSkill","mortar-board"),new w("Select Prompt",T.TreeItemCollapsibleState.None,"lurek.cag.selectPrompt","comment"),new w("Update CAG Files",T.TreeItemCollapsibleState.None,"lurek.cag.update","sync")];case"MCP Server":return[new w("Install MCP Server",T.TreeItemCollapsibleState.None,"lurek.mcp.install","cloud-download"),new w("MCP Status",T.TreeItemCollapsibleState.None,"lurek.mcp.status","info")];case"Game Jam":return[new w("Game Jam Quick Start",T.TreeItemCollapsibleState.None,"lurek.gameJam.quickStart","rocket"),new w("Add Game Module",T.TreeItemCollapsibleState.None,"lurek.gameJam.addModule","add"),new w("Game Jam Timer",T.TreeItemCollapsibleState.None,"lurek.gameJam.timer","watch"),new w("Quick Build",T.TreeItemCollapsibleState.None,"lurek.jam.quickBuild","zap"),new w("Submission Checklist",T.TreeItemCollapsibleState.None,"lurek.jam.checklist","checklist")];default:return[]}}};var re=C(require("vscode")),Pt=C(require("path")),so={scheme:"file",language:"lua"},Wa="lurek-api",Tr=class{constructor(e){this.apiData=e}provideTextDocumentContent(e){let t=e.path.replace(/^\//,""),r=this.apiData.getFunction(t);if(r)return this.renderFunction(r);let a=t.replace("lurek.",""),i=this.apiData.getModule(a);return i?this.renderModule(i):`-- No API definition found for: ${t}`}renderFunction(e){let t=[];if(t.push("-- Lurek2D API Definition"),t.push(`-- ${e.fullPath}`),t.push("--"),e.description&&(t.push(`-- ${e.description}`),t.push("--")),e.parameters.length>0){t.push("-- Parameters:");for(let a of e.parameters){let i=a.optional?" (optional)":"",s=a.default?` [default: ${a.default}]`:"",o=a.description?` -- ${a.description}`:"";t.push(`--   ${a.name}: ${a.type}${i}${s}${o}`)}t.push("--")}e.returns&&(t.push(`-- Returns: ${e.returns}`),t.push("--")),e.deprecated&&(t.push(`-- DEPRECATED: ${e.deprecated}`),t.push("--")),e.sourceFile&&t.push(`-- Source: ${e.sourceFile}`),t.push("");let r=e.parameters.map(a=>a.name).join(", ");return e.isMethod?t.push(`function ${e.objectType??"Object"}:${e.name}(${r})`):t.push(`function ${e.fullPath}(${r})`),t.push("  -- Implemented in Rust (native)"),t.push("end"),t.join(`
`)}renderModule(e){let t=[];t.push(`-- Lurek2D API Module: ${e.fullPath}`),e.description&&t.push(`-- ${e.description}`),t.push(`-- ${e.functions.length} functions, ${e.methods.length} methods`),t.push(""),t.push(`${e.name} = {}`),t.push("");for(let r of e.functions){let a=r.parameters.map(i=>i.name).join(", ");r.description&&t.push(`--- ${r.description}`),t.push(`function ${r.fullPath}(${a}) end`),t.push("")}for(let r of e.methods){let a=r.parameters.map(i=>i.name).join(", ");r.description&&t.push(`--- ${r.description}`),t.push(`function ${r.objectType??"Object"}:${r.name}(${a}) end`),t.push("")}return t.join(`
`)}};async function oo(n,e){let t=e.replace(/\./g,"/"),r=[t+".lua",t+"/init.lua"],a=Pt.dirname(n.uri.fsPath);for(let i of r){let s=re.Uri.file(Pt.resolve(a,i));try{return await re.workspace.fs.stat(s),new re.Location(s,new re.Position(0,0))}catch{}let o=re.workspace.workspaceFolders?.[0]?.uri.fsPath;if(o){let p=re.Uri.file(Pt.resolve(o,i));try{return await re.workspace.fs.stat(p),new re.Location(p,new re.Position(0,0))}catch{}}let l=await re.workspace.findFiles(`**/${i}`,"**/node_modules/**",1);if(l.length>0)return new re.Location(l[0],new re.Position(0,0))}}function Ga(n,e){let t=new Tr(e);n.subscriptions.push(re.workspace.registerTextDocumentContentProvider(Wa,t));let r=re.languages.registerDefinitionProvider(so,{async provideDefinition(a,i){let s=a.lineAt(i).text,o=s.match(/require\s*\(\s*["']([^"']+)["']\s*\)/);if(o){let m=o[1],h=s.indexOf(m),f=h+m.length;if(i.character>=h&&i.character<=f)return oo(a,m)}let l=a.getWordRangeAtPosition(i,/lurek\.\w+\.\w+/);if(l){let m=a.getText(l);if(e.getFunction(m)){let f=re.Uri.parse(`${Wa}:/${m}`);return new re.Location(f,new re.Position(0,0))}}let p=a.getWordRangeAtPosition(i,/\w+/);if(!p)return;let u=a.getText(p),d=s.substring(0,p.start.character)}});n.subscriptions.push(r)}var F=C(require("vscode")),qa=C(require("fs")),Ue=C(require("path"));var We=new Set(["load","update","draw","keypressed","keyreleased","textinput","mousepressed","mousereleased","mousemoved","wheelmoved","gamepadpressed","gamepadreleased","gamepadaxis","joystickadded","joystickremoved","focus","visible","resize","quit"]);var po=new Set(["and","break","do","else","elseif","end","false","for","function","goto","if","in","local","nil","not","or","repeat","return","then","true","until","while"]),Ha=new Set(["+","-","*","/","%","^","#","==","~=","<",">","<=",">=","=","..","...","//"]),uo=new Set(["(",")","{","}","[","]",";",":",",","."]),Se=class{tokenize(e){let t=[],r=e.length,a=0,i=0,s=0;for(;a<r;){let o=e[a];if(o===" "||o==="	"||o==="\r"||o===`
`){let l=a,p=i,u=s;for(;a<r&&(e[a]===" "||e[a]==="	"||e[a]==="\r"||e[a]===`
`);)e[a]===`
`?(i++,s=0):s++,a++;t.push({type:7,value:e.slice(l,a),line:p,column:u,length:a-l});continue}if(o==="-"&&a+1<r&&e[a+1]==="-"){let l=i,p=s;if(a+2<r&&e[a+2]==="["){let h=this.countLongBracketLevel(e,a+2);if(h>=0){let f="]"+"=".repeat(h)+"]",S=e.indexOf(f,a+4+h),y=S>=0?S+f.length:r,P=e.slice(a,y),v=xr(P);t.push({type:4,value:P,line:l,column:p,length:y-a});for(let x=a;x<y;x++)e[x]===`
`?(i++,s=0):s++;a=y;continue}}let u=e.indexOf(`
`,a),d=u>=0?u:r,m=e.slice(a,d);t.push({type:4,value:m,line:l,column:p,length:d-a}),s+=d-a,a=d;continue}if(o==="["){let l=this.countLongBracketLevel(e,a);if(l>=0){let p="]"+"=".repeat(l)+"]",u=a+2+l,d=e.indexOf(p,u),m=d>=0?d+p.length:r,h=e.slice(a,m),f=i,S=s;for(let y=a;y<m;y++)e[y]===`
`?(i++,s=0):s++;t.push({type:2,value:h,line:f,column:S,length:m-a}),a=m;continue}}if(o==='"'||o==="'"){let l=i,p=s,u=o,d=a+1;for(;d<r;){if(e[d]==="\\"){d+=2;continue}if(e[d]===u){d++;break}if(e[d]===`
`)break;d++}let m=e.slice(a,d);t.push({type:2,value:m,line:l,column:p,length:d-a}),s+=d-a,a=d;continue}if(it(o)||o==="."&&a+1<r&&it(e[a+1])){let l=i,p=s,u=a;if(o==="0"&&u+1<r&&(e[u+1]==="x"||e[u+1]==="X"))for(u+=2;u<r&&co(e[u]);)u++;else if(o==="0"&&u+1<r&&(e[u+1]==="b"||e[u+1]==="B"))for(u+=2;u<r&&(e[u]==="0"||e[u]==="1");)u++;else{for(;u<r&&it(e[u]);)u++;if(u<r&&e[u]===".")for(u++;u<r&&it(e[u]);)u++;if(u<r&&(e[u]==="e"||e[u]==="E"))for(u++,u<r&&(e[u]==="+"||e[u]==="-")&&u++;u<r&&it(e[u]);)u++}let d=e.slice(a,u);t.push({type:3,value:d,line:l,column:p,length:u-a}),s+=u-a,a=u;continue}if(Va(o)){let l=s,p=a+1;for(;p<r&&kt(e[p]);)p++;let u=e.slice(a,p),d=po.has(u)?0:1;t.push({type:d,value:u,line:i,column:l,length:p-a}),s+=p-a,a=p;continue}if(a+2<r){let l=e.slice(a,a+3);if(l==="..."){t.push({type:5,value:l,line:i,column:s,length:3}),s+=3,a+=3;continue}}if(a+1<r){let l=e.slice(a,a+2);if(Ha.has(l)){t.push({type:5,value:l,line:i,column:s,length:2}),s+=2,a+=2;continue}}if(Ha.has(o)){t.push({type:5,value:o,line:i,column:s,length:1}),s++,a++;continue}if(uo.has(o)){t.push({type:6,value:o,line:i,column:s,length:1}),s++,a++;continue}s++,a++}return t.push({type:8,value:"",line:i,column:s,length:0}),t}analyze(e){let t=this.tokenize(e),r=[],a=[],i=[],s=[],o=[];for(let y of t)if(y.type===4){let P=y.value.replace(/^--\[=*\[/,"").replace(/\]=*\]$/,"").replace(/^--/,"").trim();o.push({text:P,line:y.line,isBlock:y.value.startsWith("--["),isLuaCATS:y.value.startsWith("---@")})}let l=t.filter(y=>y.type!==7&&y.type!==4),p=[],u=0,d=(y=0)=>l[u+y],m=(y,P)=>{let v=d();return!(!v||v.type!==y||P!==void 0&&v.value!==P)},h=()=>l[u++],f=y=>{for(let P=o.length-1;P>=0;P--)if(o[P].line===y-1||o[P].line===y)return o[P].text};for(;u<l.length&&d()?.type!==8;){let y=d();if(m(0,"local")){let P=h();if(m(0,"function")){if(h(),d()?.type===1){let v=h(),x=this.parseParamList(l,u);u=x.nextIndex;let B=f(P.line),j={name:v.value,kind:"function",line:v.line,column:v.column,scope:p.length>0?p[p.length-1].name:void 0,parameters:x.names,isLocal:!0,description:B};r.push(j);for(let H of x.names)r.push({name:H,kind:"parameter",line:v.line,column:v.column,scope:v.value,isLocal:!0});p.push({name:v.value,startLine:v.line,kind:"function"})}continue}if(d()?.type===1){let v=h();if(m(5,"=")){if(h(),d()?.type===1&&d()?.value==="require"&&(h(),m(6,"(")&&(h(),d()?.type===2))){let B=h().value.slice(1,-1);a.push({modulePath:B,localName:v.value,line:v.line,column:v.column})}if(d()?.type===6&&d()?.value==="{"){r.push({name:v.value,kind:"table",line:v.line,column:v.column,scope:p.length>0?p[p.length-1].name:void 0,isLocal:!0,description:f(v.line)});continue}}for(r.push({name:v.value,kind:"local",line:v.line,column:v.column,scope:p.length>0?p[p.length-1].name:void 0,isLocal:!0,description:f(v.line)});m(6,",");)if(h(),d()?.type===1){let x=h();r.push({name:x.value,kind:"local",line:x.line,column:x.column,scope:p.length>0?p[p.length-1].name:void 0,isLocal:!0})}}continue}if(m(0,"function")){let P=h();if(d()?.type===1){let x=h().value,B=!1,j;for(;;)if(m(6,"."))h(),d()?.type===1&&(x+="."+h().value);else if(m(6,":")){if(h(),B=!0,j=x,d()?.type===1){let cr=h();x+=":"+cr.value}}else break;let H=this.parseParamList(l,u);u=H.nextIndex;let Z=x.lastIndexOf("."),Re=x.lastIndexOf(":"),Ee=Math.max(Z,Re),tt=Ee>=0?x.slice(Ee+1):x,Ot={name:tt,kind:B?"method":"function",line:P.line,column:P.column,scope:p.length>0?p[p.length-1].name:void 0,type:j,parameters:H.names,isLocal:!1,description:f(P.line)};r.push(Ot),x.startsWith("lurek.")&&We.has(tt)&&i.push(Ot);for(let cr of H.names)r.push({name:cr,kind:"parameter",line:P.line,column:P.column,scope:tt,isLocal:!0});p.push({name:tt,startLine:P.line,kind:"function"});continue}p.push({name:"<anonymous>",startLine:P.line,kind:"function"}),m(6,"(")&&(u=this.parseParamList(l,u).nextIndex);continue}if(y.type===1){let P=u,v=y.value,x=u+1,B=!1;for(;x<l.length;)if(l[x]?.value==="."&&l[x+1]?.type===1)v+="."+l[x+1].value,x+=2;else if(l[x]?.value===":"&&l[x+1]?.type===1)v+=":"+l[x+1].value,B=!0,x+=2;else break;if(x<l.length&&l[x]?.value==="="){let j=x,H=l[j+1];if(H?.type===0&&H.value==="function"){u=j+2;let Z=this.parseParamList(l,u);u=Z.nextIndex;let Re=v.lastIndexOf("."),Ee=Re>=0?v.slice(Re+1):v,tt={name:Ee,kind:"function",line:y.line,column:y.column,parameters:Z.names,isLocal:!1,description:f(y.line)};r.push(tt),v.startsWith("lurek.")&&We.has(Ee)&&i.push(tt);for(let Ot of Z.names)r.push({name:Ot,kind:"parameter",line:y.line,column:y.column,scope:Ee,isLocal:!0});p.push({name:Ee,startLine:y.line,kind:"function"});continue}if(v.endsWith(".__index")&&H?.type===1){u=j+2;continue}}h();continue}if(y.type===0){if(y.value==="do"){p.push({name:"do",startLine:y.line,kind:"do"}),h();continue}if(y.value==="if"||y.value==="elseif"){y.value==="if"&&p.push({name:"if",startLine:y.line,kind:"if"}),h();continue}if(y.value==="for"){p.push({name:"for",startLine:y.line,kind:"for"}),h();continue}if(y.value==="while"){p.push({name:"while",startLine:y.line,kind:"while"}),h();continue}if(y.value==="repeat"){p.push({name:"repeat",startLine:y.line,kind:"repeat"}),h();continue}if(y.value==="end"||y.value==="until"){let P=p.pop();if(P){s.push({name:P.name,startLine:P.startLine,endLine:y.line,kind:P.kind});for(let v=r.length-1;v>=0;v--)if(r[v].kind==="function"&&r[v].name===P.name&&r[v].line===P.startLine){r[v].endLine=y.line;break}}h();continue}}h()}let S=e.split(`
`).length-1;for(;p.length>0;){let y=p.pop();s.push({name:y.name,startLine:y.startLine,endLine:S,kind:y.kind})}return{symbols:r,requires:a,callbacks:i,scopes:s,comments:o}}getSymbolAt(e,t,r){for(let a of e.symbols)if(a.line===t&&r>=a.column&&r<a.column+a.name.length)return a}getScopeAt(e,t){let r;for(let a of e.scopes)t>=a.startLine&&t<=a.endLine&&(!r||a.startLine>r.startLine)&&(r=a);return r}findReferencesInDocument(e,t){let r=[],a=this.tokenize(e);for(let i of a)i.type===1&&i.value===t&&r.push({line:i.line,column:i.column});return r}getVisibleLocals(e,t){let r=this.getScopeAt(e,t);return e.symbols.filter(a=>!a.isLocal||a.line>t?!1:a.scope&&r?a.scope===r.name||!a.scope:!0)}detectClasses(e){let t=[],r=new Set;for(let a of e.symbols)a.kind==="method"&&a.type&&r.add(a.type);for(let a of r){let i=e.symbols.filter(l=>l.kind==="method"&&l.type===a),s=e.symbols.filter(l=>l.kind==="field"&&l.scope===a).map(l=>l.name),o=i[0];o&&t.push({name:a,methods:i,fields:s,line:o.line})}return t}getWordAtPosition(e,t,r){let a=e.split(`
`);if(t<0||t>=a.length)return"";let i=a[t];if(r<0||r>=i.length)return"";let s=r,o=r;for(;s>0&&kt(i[s-1]);)s--;for(;o<i.length&&kt(i[o]);)o++;for(;s>0&&(i[s-1]==="."||i[s-1]===":");)for(s--;s>0&&kt(i[s-1]);)s--;return i.slice(s,o)}getFunctionCallContext(e,t,r){let a=e.split(`
`);if(t<0||t>=a.length)return;let i=a[t],s=0,o=0,l=t,p=Math.min(r,i.length)-1;for(;l>=0;){let u=a[l],d=l===t?p:u.length-1;for(let m=d;m>=0;m--){let h=u[m];if(h===")"){s++;continue}if(h==="("){if(s===0){let f=m-1;for(;f>=0&&u[f]===" ";)f--;let S=f;for(;S>0&&(kt(u[S-1])||u[S-1]==="."||u[S-1]===":");)S--;let y=u.slice(S,f+1);return y.length>0?{functionName:y,paramIndex:o}:void 0}s--;continue}h===","&&s===0&&o++}l--,l>=0&&(p=a[l].length-1)}}isInsideString(e,t,r){let a=this.tokenize(e);for(let i of a){if(i.type!==2)continue;let s=i.line+xr(i.value);if(i.line===s){if(i.line===t&&r>=i.column&&r<i.column+i.length)return!0}else{if(t>i.line&&t<s||t===i.line&&r>=i.column)return!0;if(t===s){let o=i.value.lastIndexOf(`
`),l=i.value.length-o-1;if(r<l)return!0}}}return!1}isInsideComment(e,t,r){let a=this.tokenize(e);for(let i of a){if(i.type!==4)continue;let s=i.line+xr(i.value);if(i.line===s){if(i.line===t&&r>=i.column)return!0}else{if(t>i.line&&t<s||t===i.line&&r>=i.column)return!0;if(t===s){let o=i.value.lastIndexOf(`
`),l=i.value.length-o-1;if(r<l)return!0}}}return!1}countLongBracketLevel(e,t){if(e[t]!=="[")return-1;let r=0,a=t+1;for(;a<e.length&&e[a]==="=";)r++,a++;return a<e.length&&e[a]==="["?r:-1}parseParamList(e,t){let r=[],a=t;if(a>=e.length||e[a]?.value!=="(")return{names:r,nextIndex:a};for(a++;a<e.length&&e[a]?.value!==")";)e[a]?.type===1?r.push(e[a].value):e[a]?.value==="..."&&r.push("..."),a++;return a<e.length&&e[a]?.value===")"&&a++,{names:r,nextIndex:a}}};function it(n){return n>="0"&&n<="9"}function co(n){return it(n)||n>="a"&&n<="f"||n>="A"&&n<="F"}function Va(n){return n>="a"&&n<="z"||n>="A"&&n<="Z"||n==="_"}function kt(n){return Va(n)||it(n)}function xr(n){let e=0;for(let t=0;t<n.length;t++)n[t]===`
`&&e++;return e}var $a=new Se;function Ua(n,e){let t=F.languages.createDiagnosticCollection("lurek");n.subscriptions.push(t);let r=new Map,a=s=>{if(s.languageId==="lua")try{let o=s.getText(),l=$a.analyze(o),p=[];p.push(...mo(o,e)),p.push(...go(o)),ho(o,s,p),p.push(...yo(o,l)),p.push(...fo(o,s,l)),p.push(...To(o,e)),wo(o,s,p),p.push(...Po(o,l,e)),p.push(...ko(o,s)),p.push(...Mo(o)),t.set(s.uri,p)}catch{}},i=s=>{let o=s.uri.toString(),l=r.get(o);l&&clearTimeout(l),r.set(o,setTimeout(()=>{r.delete(o),a(s)},300))};n.subscriptions.push(F.window.onDidChangeVisibleTextEditors(s=>{for(let o of s)a(o.document)}),F.workspace.onDidSaveTextDocument(a),F.workspace.onDidChangeTextDocument(s=>i(s.document)),F.workspace.onDidCloseTextDocument(s=>{t.delete(s.uri);let o=s.uri.toString(),l=r.get(o);l&&(clearTimeout(l),r.delete(o))}));for(let s of F.window.visibleTextEditors)a(s.document)}function mo(n,e){let t=[],r=e.getAllFunctions().filter(i=>i.deprecated);if(r.length===0)return t;let a=n.split(`
`);for(let i of r){let s=i.fullPath.replace(/\./g,"\\."),o=new RegExp(s,"g");for(let l=0;l<a.length;l++){let p=a[l];if(p.trimStart().startsWith("--"))continue;let u;for(;(u=o.exec(p))!==null;){let d=new F.Range(l,u.index,l,u.index+i.fullPath.length),m=new F.Diagnostic(d,`${i.fullPath} is deprecated. ${i.deprecated}`,F.DiagnosticSeverity.Warning);m.code="lurek.deprecated",m.source="Lurek2D Toolkit",m.tags=[F.DiagnosticTag.Deprecated],t.push(m)}}}return t}function go(n){let e=[],t=n.split(`
`),r=/lurek\.render\.(?:setColor|setBackgroundColor|clear)\s*\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)/g;for(let a=0;a<t.length;a++){let i=t[a].split("--",1)[0];if(i.trimStart().startsWith("--"))continue;let s;for(;(s=r.exec(i))!==null;){let o=[parseFloat(s[1]),parseFloat(s[2]),parseFloat(s[3])];if(s[4]!==void 0&&o.push(parseFloat(s[4])),!o.some(m=>m>1))continue;let p=o.slice(0,3).map(m=>(m/255).toFixed(2)),u=new F.Range(a,s.index,a,s.index+s[0].length),d=new F.Diagnostic(u,`Color values should be in 0-1 range. Did you mean ${p.join(", ")}?`,F.DiagnosticSeverity.Warning);d.code="lurek.colorRange",d.source="Lurek2D Toolkit",e.push(d)}}return e}function ho(n,e,t){if(!F.workspace.workspaceFolders?.length)return;let r=F.workspace.asRelativePath(e.uri.fsPath,!1);if(r.startsWith("content/examples/")||r.startsWith("content\\examples\\"))return;let a=n.split(`
`),i=/lurek\.(?:render\.newImage|audio\.newSource|fs\.read)\s*\(\s*["']([^"']+)["']/g,s=Ue.dirname(e.uri.fsPath),o=F.workspace.workspaceFolders[0].uri.fsPath;for(let l=0;l<a.length;l++){let p=a[l];if(p.trimStart().startsWith("--"))continue;let u;for(;(u=i.exec(p))!==null;){let d=u[1];if(d.includes("://")||!d.includes("."))continue;if(![Ue.resolve(s,d),Ue.resolve(o,d)].some(f=>{try{return qa.existsSync(f)}catch{return!1}})){let f=p.indexOf(d,u.index),S=new F.Range(l,f,l,f+d.length),y=new F.Diagnostic(S,`Asset file '${d}' not found in workspace`,F.DiagnosticSeverity.Warning);y.code="lurek.assetNotFound",y.source="Lurek2D Toolkit",t.push(y)}}}}function yo(n,e){let t=[];if(!n.includes("lurek.thread"))return t;let r=n.split(`
`),a=/\bmath\.random\s*\(/g;for(let i=0;i<r.length;i++){let s=r[i];if(s.trimStart().startsWith("--"))continue;let o;for(;(o=a.exec(s))!==null;){let l=$a.getScopeAt(e,i);if(!l||!r.slice(l.startLine,l.endLine+1).join(`
`).includes("lurek.thread"))continue;let u=new F.Range(i,o.index,i,o.index+11),d=new F.Diagnostic(u,"math.random in threads may produce identical sequences. Consider seeding with thread ID.",F.DiagnosticSeverity.Information);d.code="lurek.threadRandom",d.source="Lurek2D Toolkit",t.push(d)}}return t}function fo(n,e,t){let r=[];if(Ue.basename(e.uri.fsPath)!=="main.lua"||!e.uri.fsPath.replace(/\\/g,"/").includes("/content/games/"))return r;let s=We.has("process")?"process":"update",o="draw",l=t.callbacks.some(u=>u.name===s)||new RegExp(`lurek\\.${s}\\s*=\\s*function`).test(n),p=t.callbacks.some(u=>u.name===o)||/lurek\.draw\s*=\s*function/.test(n);if(!l&&!p){let u=n.split(`
`),d=new F.Range(0,0,0,u[0]?.length??0),m=new F.Diagnostic(d,`main.lua should define lurek.${s}(dt) and/or lurek.${o}()`,F.DiagnosticSeverity.Information);m.code="lurek.missingCallback",m.source="Lurek2D Toolkit",r.push(m)}return r}var bo=[{pattern:/lurek\.render\.(?:rectangle|circle|arc|polygon|ellipse)\s*\(\s*["']([^"']+)["']/g,valid:["fill","line"],label:"draw mode"},{pattern:/lurek\.render\.setBlendMode\s*\(\s*["']([^"']+)["']/g,valid:["alpha","add","subtract","multiply","replace","screen","darken","lighten","none"],label:"blend mode"},{pattern:/lurek\.render\.setLineStyle\s*\(\s*["']([^"']+)["']/g,valid:["smooth","rough"],label:"line style"},{pattern:/lurek\.render\.setFilter\s*\([^,]*,\s*["']([^"']+)["']/g,valid:["linear","nearest"],label:"texture filter"},{pattern:/lurek\.render\.setFilter\s*\(\s*["']([^"']+)["']/g,valid:["linear","nearest"],label:"texture filter"},{pattern:/lurek\.audio\.newSource\s*\([^,]*,\s*["']([^"']+)["']/g,valid:["static","stream"],label:"audio source type"},{pattern:/lurek\.physics\.newBody\s*\([^,]*,[^,]*,[^,]*,\s*["']([^"']+)["']/g,valid:["dynamic","static","kinematic"],label:"body type"},{pattern:/lurek\.render\.printf\s*\([^)]*,[^)]*,[^)]*,[^)]*,\s*["']([^"']+)["']/g,valid:["left","center","right","justify"],label:"text alignment"}];function vo(n,e){for(let t of e){if(t===n)return;if(Math.abs(t.length-n.length)<=2){let r=0,a=Math.max(t.length,n.length);for(let i=0;i<a;i++)(t[i]??"")!==(n[i]??"")&&r++;if(r<=2)return t}}}function To(n,e){let t=[],r=n.split(`
`);for(let a of bo)for(let i=0;i<r.length;i++){let s=r[i];if(s.trimStart().startsWith("--"))continue;a.pattern.lastIndex=0;let o;for(;(o=a.pattern.exec(s))!==null;){let l=o[1];if(a.valid.includes(l))continue;let p=vo(l,a.valid),u=s.indexOf(`"${l}"`,o.index)!==-1?s.indexOf(`"${l}"`,o.index)+1:s.indexOf(`'${l}'`,o.index)+1,d=new F.Range(i,u,i,u+l.length),m=p?`Unknown ${a.label} "${l}". Did you mean "${p}"? Valid: ${a.valid.join(", ")}`:`Unknown ${a.label} "${l}". Valid values: ${a.valid.join(", ")}`,h=new F.Diagnostic(d,m,F.DiagnosticSeverity.Warning);h.code="lurek.wrongEnumValue",h.source="Lurek2D Toolkit",t.push(h)}}return t}var xo={window:["title","width","height","vsync","fullscreen","resizable","highdpi","minwidth","minheight","x","y","borderless","displayindex","icon"],performance:["target_fps","fixed_dt"],modules:["physics","audio","graphics","input","timer","filesystem","math","thread"],log:["file","append","level"]};function wo(n,e,t){if(Ue.basename(e.uri.fsPath)!=="conf.lua")return;let r=n.split(`
`),a=/\bt\.(\w+)\.(\w+)\s*=/g;for(let i=0;i<r.length;i++){let s=r[i];if(s.trimStart().startsWith("--"))continue;a.lastIndex=0;let o;for(;(o=a.exec(s))!==null;){let l=o[1],p=o[2],u=xo[l];if(!u||u.includes(p))continue;let d=o.index+`t.${l}.`.length,m=new F.Range(i,d,i,d+p.length),h=new F.Diagnostic(m,`"${p}" is not a recognised conf.lua key in t.${l}. Valid: ${u.join(", ")}`,F.DiagnosticSeverity.Warning);h.code="lurek.confKey",h.source="Lurek2D Toolkit",t.push(h)}}}function Po(n,e,t){let r=[],a=n.split(`
`),i=/lurek\.(?:render\.(?:newImage|newFont|newCanvas|newShader)|audio\.(?:newSource)|image\.load)\s*\(/g,s=t.getCallbacks().map(l=>l.name).filter(l=>["process","process_late","process_physics","fixedUpdate","draw","draw_ui"].includes(l));s.length===0&&s.push("process","process_late","process_physics","draw","draw_ui");function o(l){for(let p=l;p>=0;p--){let u=a[p].match(/function\s+lurek\.([A-Za-z_][\w]*)\s*\(/)||a[p].match(/lurek\.([A-Za-z_][\w]*)\s*=\s*function\s*\(/);if(u)return u[1]}}for(let l=0;l<a.length;l++){let p=a[l];if(p.trimStart().startsWith("--"))continue;i.lastIndex=0;let u;for(;(u=i.exec(p))!==null;){let d=o(l);if(!d||!s.includes(d))continue;let m=u[0].replace(/\s*\($/,""),h=new F.Range(l,u.index,l,u.index+m.length),f=new F.Diagnostic(h,`${m} called inside a per-frame callback. This allocates every frame \u2014 move to lurek.init() or lurek.ready().`,F.DiagnosticSeverity.Warning);f.code="lurek.perFrameAlloc",f.source="Lurek2D Toolkit",r.push(f)}}return r}function ko(n,e){let t=[],r=e.uri.fsPath.replace(/\\/g,"/");if(!r.includes("tests/lua/")&&!r.includes("tests\\lua\\")||!r.endsWith(".lua")||r.endsWith("init.lua"))return t;if(!/\btest_summary\s*\(\s*\)/.test(n)){let i=n.split(`
`),s=i.length-1,o=new F.Range(s,0,s,i[s]?.length??0),l=new F.Diagnostic(o,"Lua test file is missing test_summary() call at the end. Required by the Lurek2D test harness.",F.DiagnosticSeverity.Warning);l.code="lurek.missingTestSummary",l.source="Lurek2D Toolkit",t.push(l)}return t}function Mo(n){let e=[],t=n.split(`
`),r=/\blocal\s+(\w+)\s*=\s*lurek\.entity\.find\s*\(/g;for(let a=0;a<t.length;a++){let i=t[a];if(i.trimStart().startsWith("--"))continue;r.lastIndex=0;let s;for(;(s=r.exec(i))!==null;){let o=s[1],l=!1;for(let p=a+1;p<Math.min(a+6,t.length);p++){let u=t[p].trim();if(u.startsWith("--"))continue;if(u.includes(`if ${o}`)||u.includes(`if not ${o}`)){l=!0;break}if(new RegExp(`\\b${o}\\s*[:.:]\\s*\\w+`).test(u)&&!l){let m=u.indexOf(o),h=new F.Range(p,m,p,m+o.length),f=new F.Diagnostic(h,`'${o}' from lurek.ecs.find() may be nil. Consider adding: if ${o} then`,F.DiagnosticSeverity.Information);f.code="lurek.entityNilAccess",f.source="Lurek2D Toolkit",e.push(f);break}}}}return e}var ge=C(require("vscode")),Co={scheme:"file",language:"lua"},jo=["setColor","setBackgroundColor","clear","newColor"];function Ya(n,e){let t=ge.languages.registerColorProvider(Co,{provideDocumentColors(r){try{return Eo(r)}catch{return[]}},provideColorPresentations(r,a){try{return Lo(r,a)}catch{return[]}}});n.subscriptions.push(t)}var Ro=new RegExp(`lurek\\.graphics\\.(?:${jo.join("|")})\\s*\\(\\s*([\\d.]+)\\s*,\\s*([\\d.]+)\\s*,\\s*([\\d.]+)(?:\\s*,\\s*([\\d.]+))?\\s*\\)`,"g");function Eo(n){let e=[],t=n.getText(),r=new RegExp(Ro.source,"g"),a;for(;(a=r.exec(t))!==null;){let i=parseFloat(a[1]),s=parseFloat(a[2]),o=parseFloat(a[3]),l=a[4]!==void 0?parseFloat(a[4]):1;if(i>1||s>1||o>1||l>1)continue;let p=a[0],u=p.indexOf("(")+1,d=p.lastIndexOf(")"),m=a.index+u,h=d-u,f=n.positionAt(m),S=n.positionAt(m+h),y=new ge.Range(f,S);e.push(new ge.ColorInformation(y,new ge.Color(i,s,o,l)))}return e}function Lo(n,e){let t=nn(n.red),r=nn(n.green),a=nn(n.blue),i=nn(n.alpha),s=[],o=new ge.ColorPresentation(`${t}, ${r}, ${a}, ${i}`);if(o.textEdit=new ge.TextEdit(e.range,`${t}, ${r}, ${a}, ${i}`),s.push(o),Math.abs(n.alpha-1)<.005){let m=new ge.ColorPresentation(`${t}, ${r}, ${a}`);m.textEdit=new ge.TextEdit(e.range,`${t}, ${r}, ${a}`),s.push(m)}let l=Math.round(n.red*255).toString(16).padStart(2,"0"),p=Math.round(n.green*255).toString(16).padStart(2,"0"),u=Math.round(n.blue*255).toString(16).padStart(2,"0"),d=new ge.ColorPresentation(`${t}, ${r}, ${a} --[[ #${l}${p}${u} ]]`);return d.textEdit=new ge.TextEdit(e.range,`${t}, ${r}, ${a} --[[ #${l}${p}${u} ]]`),s.push(d),s}function nn(n){return n.toFixed(2).replace(/\.?0+$/,"")||"0"}var we=C(require("vscode")),st=C(require("path"));var Do={scheme:"file",language:"lua"},$p=new Se,Xa={"lurek.graphics.newImage":[".png",".jpg",".jpeg",".bmp",".gif"],"lurek.audio.newSource":[".ogg",".wav",".mp3",".flac"],"lurek.filesystem.read":[],"lurek.filesystem.write":[],"lurek.filesystem.exists":[]},Ao=[".lua"];function Qa(n,e){let t=we.languages.registerCompletionItemProvider(Do,{async provideCompletionItems(r,a){try{return await _o(r,a)}catch{return}}},'"',"'","/");n.subscriptions.push(t)}async function _o(n,e){let r=n.lineAt(e).text.substring(0,e.character),a=r.match(/(lurek\.\w+\.\w+)\s*\(\s*["']([^"']*)$/),i=r.match(/require\s*\(\s*["']([^"']*)$/);if(!a&&!i)return;let s=a?a[1]:"require",o=a?a[2]:i[1],l=[];if(s==="require")l=Ao;else if(s in Xa)l=Xa[s];else return;let p=we.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!p)return;let u=o.includes("/")?st.dirname(o):"",d=u?`${u}/**/*`:"**/*",m=await we.workspace.findFiles(d,"**/node_modules/**",200),h=[],f=new Set;for(let S of m){let y=st.extname(S.fsPath).toLowerCase();if(l.length>0&&!l.includes(y))continue;let P=st.relative(p,S.fsPath).replace(/\\/g,"/");if(s==="require"){let j=P.replace(/\.lua$/,"").replace(/\//g,"."),H=new we.CompletionItem(j,we.CompletionItemKind.Module);H.detail="Lua module",H.insertText=j;let Z=j.split(".").length;H.sortText=String(Z).padStart(3,"0")+j,h.push(H);continue}let v=st.dirname(P);if(v!=="."&&!f.has(v)&&(f.add(v),!o||v.startsWith(o.split("/")[0]))){let j=new we.CompletionItem(v+"/",we.CompletionItemKind.Folder);j.sortText="0"+v,h.push(j)}let x=new we.CompletionItem(P,we.CompletionItemKind.File);x.detail=y.toUpperCase().substring(1)+" file",x.insertText=P;let B=P.split("/").length;x.sortText=String(B).padStart(3,"0")+P,h.push(x)}return h}var Ye=C(require("vscode"));var Fo={scheme:"file",language:"lua"},Yp=new Se;function Ja(n,e){let t=Ye.languages.registerInlayHintsProvider(Fo,{provideInlayHints(r,a){try{return Ye.workspace.getConfiguration("lurek").get("inlayHints.enabled")===!1?[]:zo(r,a,e)}catch{return[]}}});n.subscriptions.push(t)}function zo(n,e,t){let r=[],a=n.getText(e),i=n.offsetAt(e.start),s=/(lurek\.\w+\.\w+)\s*\(/g,o;for(;(o=s.exec(a))!==null;){let l=o[1],p=t.getFunction(l);if(!p||p.parameters.length===0)continue;let u=o.index+o[0].length-1,d=No(a,u);if(!d)continue;let m=Oo(d);if(m.length<=1)continue;let f=i+u+1;for(let S=0;S<m.length&&S<p.parameters.length;S++){let y=m[S],P=y.trimStart(),v=y.length-P.length;if(/^\w+\s*=/.test(P)){f+=y.length+1;continue}let x=p.parameters[S];if(P===x.name){f+=y.length+1;continue}if(Wo(P,x.name)){f+=y.length+1;continue}let B=n.positionAt(f+v),j=new Ye.InlayHint(B,`${x.name}:`,Ye.InlayHintKind.Parameter);j.paddingRight=!0,r.push(j),f+=y.length+1}}return r}function No(n,e){if(n[e]!=="(")return;let t=1,r=e+1;for(;r<n.length&&t>0;){let a=n[r];a==="("?t++:a===")"&&t--,r++}if(t===0)return n.slice(e+1,r-1)}function Oo(n){if(!n.trim())return[];let e=[],t="",r=0,a=null;for(let i=0;i<n.length;i++){let s=n[i];if(a&&s==="\\"){t+=s,i+1<n.length&&(t+=n[i+1],i++);continue}if(!a&&(s==='"'||s==="'")){a=s,t+=s;continue}if(a&&s===a){a=null,t+=s;continue}if(a){t+=s;continue}s==="("||s==="{"||s==="["?(r++,t+=s):s===")"||s==="}"||s==="]"?(r--,t+=s):s===","&&r===0?(e.push(t),t=""):t+=s}return t&&e.push(t),e}function Wo(n,e){return(n==="true"||n==="false"||n==="nil")&&e.length<=4}var z=C(require("vscode"));var Ho={scheme:"file",language:"lua"},Qp=new Se;function Ka(n,e){let t=z.languages.registerCodeActionsProvider(Ho,{provideCodeActions(r,a,i){try{return Vo(r,a,i)}catch{return[]}}},{providedCodeActionKinds:[z.CodeActionKind.QuickFix,z.CodeActionKind.RefactorExtract]});n.subscriptions.push(t)}function Vo(n,e,t){let r=[];for(let l of t.diagnostics)switch(l.code){case"lurek.unusedRequire":r.push(...qo(n,l));break;case"lurek.missingCallback":r.push(...$o(n,l));break;case"lurek.colorRange":r.push(...Uo(n,l));break}let a=n.lineAt(e.start.line).text;e.isEmpty||(r.push(Yo(n,e)),r.push(Jo(n,e)));let i=a.match(/^(\s*)(\w+)\s*=\s*(.+)/);i&&!a.trimStart().startsWith("local ")&&!a.trimStart().startsWith("function ")&&!a.trimStart().startsWith("--")&&!a.includes("lurek.")&&!a.includes(".")&&!a.includes(":")&&r.push(Xo(n,e.start.line,i)),/\brequire\s*\(/.test(a)&&!/pcall/.test(a)&&r.push(Qo(n,e.start.line));let s=a.match(/^(\s*)local\s+(\w+)\s*=\s*(.+)/);if(s&&!e.isEmpty&&r.push(Ko(n,e.start.line,s)),/^\s*if\s+/.test(a)){let l=Zo(n,e.start.line);l&&r.push(l)}let o=a.match(/^(\s*)local\s+(\w+)\s*=/);if(o&&!a.includes("---@type")&&r.push(el(n,e.start.line,o[2])),/(\w+)\.__index\s*=\s*\1/.test(a)||/setmetatable\s*\(\s*{/.test(a)){let l=a.match(/(\w+)\.__index/)?.[1];l&&r.push(tl(n,e.start.line,l))}return r}function qo(n,e){let t=new z.CodeAction("Remove unused require",z.CodeActionKind.QuickFix);t.edit=new z.WorkspaceEdit;let r=e.range.start.line,a=new z.Range(r,0,r+1,0);return t.edit.delete(n.uri,a),t.diagnostics=[e],t.isPreferred=!0,[t]}function $o(n,e){let t=n.getText(),r=[];if(!/function\s+lurek\.load\s*\(/.test(t)&&!/lurek\.load\s*=\s*function/.test(t)&&r.push("load"),!/function\s+lurek\.update\s*\(/.test(t)&&!/lurek\.update\s*=\s*function/.test(t)&&r.push("update"),!/function\s+lurek\.draw\s*\(/.test(t)&&!/lurek\.draw\s*=\s*function/.test(t)&&r.push("draw"),r.length===0)return[];let a=new z.CodeAction("Generate Lurek2D callbacks",z.CodeActionKind.QuickFix);a.edit=new z.WorkspaceEdit;let i=[];r.includes("load")&&i.push(`function lurek.load()
    -- Initialize game
end`),r.includes("update")&&i.push(`function lurek.update(dt)
    -- Update game logic
end`),r.includes("draw")&&i.push(`function lurek.draw()
    -- Draw game objects
end`);let s=n.lineAt(n.lineCount-1).range.end;return a.edit.insert(n.uri,s,`

`+i.join(`

`)+`
`),a.diagnostics=[e],[a]}function Uo(n,e){let r=n.getText(e.range).match(/(lurek\.graphics\.(?:setColor|setBackgroundColor|clear))\s*\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)/);if(!r)return[];let a=r[1],i=d=>(parseFloat(d)/255).toFixed(2).replace(/\.?0+$/,"")||"0",s=i(r[2]),o=i(r[3]),l=i(r[4]),p;if(r[5]!==void 0){let d=i(r[5]);p=`${a}(${s}, ${o}, ${l}, ${d})`}else p=`${a}(${s}, ${o}, ${l})`;let u=new z.CodeAction("Convert to 0-1 color range",z.CodeActionKind.QuickFix);return u.edit=new z.WorkspaceEdit,u.edit.replace(n.uri,e.range,p),u.diagnostics=[e],u.isPreferred=!0,[u]}function Yo(n,e){let t=new z.CodeAction("Extract to local function",z.CodeActionKind.RefactorExtract);t.edit=new z.WorkspaceEdit;let r=n.getText(e),a=n.lineAt(e.start.line).text.match(/^(\s*)/)?.[1]??"",i="extracted_function",s=r.split(`
`).map((l,p)=>p===0?l:a+"    "+l),o=`${a}local function ${i}()
${a}    ${s.join(`
`)}
${a}end

`;return t.edit.insert(n.uri,new z.Position(e.start.line,0),o),t.edit.replace(n.uri,e,`${i}()`),t}function Xo(n,e,t){let r=new z.CodeAction("Convert to local variable",z.CodeActionKind.QuickFix);r.edit=new z.WorkspaceEdit;let a=n.lineAt(e).range,i=`${t[1]}local ${t[2]} = ${t[3]}`;return r.edit.replace(n.uri,a,i),r}function Qo(n,e){let t=n.lineAt(e).text,r=t.match(/^(\s*)/)?.[1]??"",a=new z.CodeAction("Wrap require in pcall",z.CodeActionKind.QuickFix);a.edit=new z.WorkspaceEdit;let i=t.match(/^(\s*)local\s+(\w+)\s*=\s*require\s*\(\s*["']([^"']+)["']\s*\)/);if(i){let s=i[2],o=i[3],l=[`${r}local ok, ${s} = pcall(require, "${o}")`,`${r}if not ok then`,`${r}    error("Failed to load module: " .. tostring(${s}))`,`${r}end`].join(`
`);a.edit.replace(n.uri,n.lineAt(e).range,l)}else{let s=t.match(/require\s*\(\s*["']([^"']+)["']\s*\)/);if(s){let o=s[1],l=[`${r}local ok, module = pcall(require, "${o}")`,`${r}if not ok then`,`${r}    error("Failed to load module: " .. tostring(module))`,`${r}end`].join(`
`);a.edit.replace(n.uri,n.lineAt(e).range,l)}}return a}function Jo(n,e){let t=new z.CodeAction("Extract selection to new module file",z.CodeActionKind.RefactorExtract);return t.command={command:"lurek.extractToModuleFile",title:"Extract to new module file",arguments:[n.uri,e]},t}function Ko(n,e,t){let r=new z.CodeAction(`Inline variable '${t[2]}'`,z.CodeActionKind.RefactorInline);r.edit=new z.WorkspaceEdit;let a=t[1],i=t[3].trim();return r.edit.replace(n.uri,n.lineAt(e).range,`${a}-- TODO: inline '${t[2]}' = ${i}`),r}function Zo(n,e){let t=[],r=n.lineAt(e).text.match(/if\s+(\w+)\s*==\s*['"]/)?.[1];if(!r)return;for(let d=e;d<Math.min(e+40,n.lineCount)&&(t.push(n.lineAt(d).text),n.lineAt(d).text.trimStart()!=="end");d++);let a=[],i=0;for(;i<t.length;){let d=t[i].match(/(?:if|elseif)\s+\w+\s*==\s*['"](\w+)['"]\s*then/);if(d){let m=d[1],h=[];for(i++;i<t.length&&!/(?:elseif|else|end)/.test(t[i].trimStart());)h.push(t[i].replace(/^\s{4}/,"    ")),i++;a.push({key:m,body:h.join(`
`)})}else i++}if(a.length<2)return;let s=(n.lineAt(e).text.match(/^(\s*)/)??["",""])[1],o=`${r}Handlers`,l=[`${s}local ${o} = {`,...a.map(d=>`${s}  ${d.key} = function()
${d.body}
${s}  end,`),`${s}}`,`${s}local _handler = ${o}[${r}]`,`${s}if _handler then _handler() end`],p=new z.CodeAction(`Convert if/elseif chain to state-map (${o})`,z.CodeActionKind.RefactorRewrite);p.edit=new z.WorkspaceEdit;let u=new z.Range(e,0,e+t.length-1,n.lineAt(e+t.length-1).range.end.character);return p.edit.replace(n.uri,u,l.join(`
`)),p}function el(n,e,t){let r=new z.CodeAction(`Add ---@type annotation for '${t}'`,z.CodeActionKind.RefactorRewrite);r.edit=new z.WorkspaceEdit;let a=(n.lineAt(e).text.match(/^(\s*)/)??["",""])[1],i=new z.Position(e,0);return r.edit.insert(n.uri,i,`${a}---@type any
`),r}function tl(n,e,t){let r=new z.CodeAction(`Generate __tostring for ${t}`,z.CodeActionKind.QuickFix);r.edit=new z.WorkspaceEdit;let a=(n.lineAt(e).text.match(/^(\s*)/)??["",""])[1],i=new z.Position(e+1,0);return r.edit.insert(n.uri,i,`
${a}function ${t}:__tostring()
${a}  return "${t}()"  -- TODO: fill in fields
${a}end
`),r}var Y=C(require("vscode"));var rl=[{code:"lurek.perf.tableAllocHotPath",pattern:/\{\s*\}/,message:"Table allocation `{}` in hot path \u2014 consider pre-allocating or using an object pool.",severity:Y.DiagnosticSeverity.Hint,hotPathOnly:!0},{code:"lurek.perf.newInHotPath",pattern:/lurek\.\w+\.new\w*\s*\(/,message:"Resource creation (lurek.*.new*) in hot path \u2014 move to lurek.load() or cache the result.",severity:Y.DiagnosticSeverity.Warning,hotPathOnly:!0},{code:"lurek.perf.globalInLoop",pattern:/\bfor\b.+\bdo\b/,message:"Loop detected \u2014 ensure frequently accessed globals are cached as locals above the loop.",severity:Y.DiagnosticSeverity.Hint,hotPathOnly:!1},{code:"lurek.perf.stringConcatLoop",pattern:/\.\.\s*["']/,message:"String concatenation in loop \u2014 consider table.insert + table.concat for better performance.",severity:Y.DiagnosticSeverity.Hint,hotPathOnly:!0},{code:"lurek.perf.pcallHotPath",pattern:/\bpcall\s*\(/,message:"pcall in hot path adds overhead \u2014 consider error handling outside the frame loop.",severity:Y.DiagnosticSeverity.Hint,hotPathOnly:!0},{code:"lurek.perf.mathFloor",pattern:/math\.floor\s*\(/,message:"Consider bit.tobit() or x%1 for faster integer conversion in LuaJIT.",severity:Y.DiagnosticSeverity.Hint,hotPathOnly:!0},{code:"lurek.perf.mathRandom",pattern:/math\.random\s*\(/,message:"Use lurek.math.random() for deterministic, seedable RNG consistent across platforms.",severity:Y.DiagnosticSeverity.Information,hotPathOnly:!0},{code:"lurek.perf.unpackInLoop",pattern:/\bunpack\s*\(/,message:"unpack() in hot path creates temporary values \u2014 prefer indexed access for known structures.",severity:Y.DiagnosticSeverity.Hint,hotPathOnly:!0}],al=[{code:"lurek.compat.constAttribute",pattern:/\blocal\s+\w+\s*<\s*const\s*>/,message:"Lua 5.4 `<const>` attribute is not supported in LuaJIT. Remove the attribute \u2014 LuaJIT inlines constants automatically."},{code:"lurek.compat.closeAttribute",pattern:/\blocal\s+\w+\s*<\s*close\s*>/,message:"Lua 5.4 `<close>` (to-be-closed variable) is not supported in LuaJIT. Use explicit :close() or defer via a wrapper."},{code:"lurek.compat.utf8Library",pattern:/\butf8\s*\.\s*\w+\s*\(/,message:"The `utf8` standard library is not available in LuaJIT. Use lurek.utf8.* instead or the luajit-utf8 binding."},{code:"lurek.compat.tableMove",pattern:/\btable\s*\.\s*move\s*\(/,message:"`table.move` behaviour differs between Lua 5.4 and LuaJIT. Test carefully, or use a manual loop for portability."},{code:"lurek.compat.bitwiseTilde",pattern:/(?<![=<>~])\s*~(?!\s*=)\s*(?![-\\/])/,message:"Lua 5.4 bitwise `~` (XOR / NOT) operator is not supported in LuaJIT. Use `bit.bxor(a, b)` or `bit.bnot(a)` instead."},{code:"lurek.compat.intDivOp",pattern:/\/\//,message:"Floor-division operator `//` is a LuaJIT extension that matches Lua 5.4. Behaviour is consistent \u2014 no action needed. (Hint only.)"},{code:"lurek.compat.warnLevel",pattern:/(?<!\.)(?<!\w)\bwarn\s*\(/,message:"`warn()` is a Lua 5.4-only function and is not available in LuaJIT. Use `print()` or `lurek.log.warn()` instead."}];function il(n){let e=new Set,t=n.split(`
`),r=0,a=!1;for(let i=0;i<t.length;i++){let s=t[i];if(/^\s*function\s+lurek\.(update|draw)\s*\(/.test(s)&&(a=!0,r=0),a){let o=(s.match(/\b(function|do|then|repeat)\b/g)||[]).length,l=(s.match(/\b(end|until)\b/g)||[]).length;r+=o-l,e.add(i),r<=0&&i>0&&(a=!1)}}return e}function Za(n,e){let t=[],r=Y.languages.createDiagnosticCollection("lurek.luajit");t.push(r);let a=Y.languages.createDiagnosticCollection("lurek.compat");t.push(a);function i(o){if(o.languageId!=="lua")return;let l=o.getText(),p=il(l),u=[],d=l.split(`
`);for(let m=0;m<d.length;m++){let h=d[m];if(!/^\s*--/.test(h))for(let f of rl){if(f.hotPathOnly&&!p.has(m))continue;let S=f.pattern.exec(h);if(S){let y=S.index,P=S.index+S[0].length,v=new Y.Range(m,y,m,P),x=new Y.Diagnostic(v,f.message,f.severity);x.code=f.code,x.source="Lurek2D LuaJIT",u.push(x)}}}r.set(o.uri,u)}function s(o){if(o.languageId!=="lua")return;let l=o.getText(),p=[],u=l.split(`
`);for(let d=0;d<u.length;d++){let m=u[d];if(/^\s*--/.test(m))continue;let h=m.replace(/--.*$/,"");for(let f of al){let S=f.pattern.exec(h);if(S){let y=S.index,P=S.index+S[0].length,v=new Y.Range(d,y,d,P),x=f.code==="lurek.compat.intDivOp"?Y.DiagnosticSeverity.Hint:Y.DiagnosticSeverity.Warning,B=new Y.Diagnostic(v,f.message,x);B.code=f.code,B.source="Lurek2D Compat",p.push(B)}}}a.set(o.uri,p)}Y.window.activeTextEditor&&(i(Y.window.activeTextEditor.document),s(Y.window.activeTextEditor.document)),t.push(Y.window.onDidChangeActiveTextEditor(o=>{o&&(i(o.document),s(o.document))}),Y.workspace.onDidChangeTextDocument(o=>{i(o.document),s(o.document)}),Y.workspace.onDidCloseTextDocument(o=>{r.delete(o.uri),a.delete(o.uri)})),n.subscriptions.push(...t)}var $=C(require("vscode")),Xe=null;function ol(n){Xe=n}function ei(n){if(Xe){let e=Xe.getFactoryTypes().get(n);if(e)return e}return rn[n]?.typeName}function kr(n){if(Xe){let e=Xe.getMethods(n);if(e.length>0){let t=Object.values(rn).find(r=>r.typeName===n);return{typeName:n,methods:e.map(r=>({name:r.name,sig:r.signature,desc:r.description})),...t?.fields?{fields:t.fields}:{}}}}return Object.values(rn).find(e=>e.typeName===n)}function ll(){let n=new Set(Object.keys(rn));if(Xe)for(let e of Xe.getFactoryTypes().keys())n.add(e);return Array.from(n)}var wr={scheme:"file",language:"lua"},rn={"lurek.graphics.newImage":{typeName:"Image",methods:[{name:"getDimensions",sig:":getDimensions()",desc:"Returns width, height"},{name:"getWidth",sig:":getWidth()",desc:"Returns pixel width"},{name:"getHeight",sig:":getHeight()",desc:"Returns pixel height"},{name:"getFilter",sig:":getFilter()",desc:"Returns min, mag filter modes"},{name:"setFilter",sig:":setFilter(min, mag)",desc:"Set texture filter"},{name:"setWrap",sig:":setWrap(horiz, vert)",desc:"Set texture wrap mode"},{name:"getWrap",sig:":getWrap()",desc:"Returns horizontal, vertical wrap"},{name:"release",sig:":release()",desc:"Free GPU resources"},{name:"type",sig:":type()",desc:"Returns 'Image'"}]},"lurek.graphics.newCanvas":{typeName:"Canvas",methods:[{name:"getDimensions",sig:":getDimensions()",desc:"Returns width, height"},{name:"getWidth",sig:":getWidth()",desc:"Returns pixel width"},{name:"getHeight",sig:":getHeight()",desc:"Returns pixel height"},{name:"getFilter",sig:":getFilter()",desc:"Returns min, mag filter modes"},{name:"setFilter",sig:":setFilter(min, mag)",desc:"Set texture filter"},{name:"renderTo",sig:":renderTo(fn)",desc:"Render to this canvas"},{name:"release",sig:":release()",desc:"Free GPU resources"},{name:"type",sig:":type()",desc:"Returns 'Canvas'"}]},"lurek.graphics.newFont":{typeName:"Font",methods:[{name:"getWidth",sig:":getWidth(text)",desc:"Width of text in pixels"},{name:"getHeight",sig:":getHeight()",desc:"Font height in pixels"},{name:"getLineHeight",sig:":getLineHeight()",desc:"Returns line height multiplier"},{name:"setLineHeight",sig:":setLineHeight(h)",desc:"Set line height multiplier"},{name:"getAscent",sig:":getAscent()",desc:"Returns font ascent"},{name:"getDescent",sig:":getDescent()",desc:"Returns font descent"},{name:"hasGlyphs",sig:":hasGlyphs(text)",desc:"Check if font has glyphs"},{name:"release",sig:":release()",desc:"Free resources"},{name:"type",sig:":type()",desc:"Returns 'Font'"}]},"lurek.graphics.newShader":{typeName:"Shader",methods:[{name:"send",sig:":send(name, value)",desc:"Set uniform value"},{name:"hasUniform",sig:":hasUniform(name)",desc:"Check if uniform exists"},{name:"release",sig:":release()",desc:"Free GPU resources"},{name:"type",sig:":type()",desc:"Returns 'Shader'"}]},"lurek.graphics.newMesh":{typeName:"Mesh",methods:[{name:"setVertices",sig:":setVertices(verts)",desc:"Set vertex data"},{name:"setTexture",sig:":setTexture(tex)",desc:"Set texture for mesh"},{name:"getVertexCount",sig:":getVertexCount()",desc:"Returns vertex count"},{name:"release",sig:":release()",desc:"Free GPU resources"},{name:"type",sig:":type()",desc:"Returns 'Mesh'"}]},"lurek.graphics.newSpriteBatch":{typeName:"SpriteBatch",methods:[{name:"add",sig:":add(quad, x, y, r, sx, sy)",desc:"Add sprite to batch"},{name:"clear",sig:":clear()",desc:"Remove all sprites"},{name:"getCount",sig:":getCount()",desc:"Returns current sprite count"},{name:"set",sig:":set(id, quad, x, y, r, sx, sy)",desc:"Update sprite at index"},{name:"flush",sig:":flush()",desc:"Upload data to GPU"},{name:"release",sig:":release()",desc:"Free GPU resources"},{name:"type",sig:":type()",desc:"Returns 'SpriteBatch'"}]},"lurek.graphics.newQuad":{typeName:"Quad",methods:[{name:"getViewport",sig:":getViewport()",desc:"Returns x, y, w, h"},{name:"setViewport",sig:":setViewport(x, y, w, h)",desc:"Set viewport rect"},{name:"getTextureDimensions",sig:":getTextureDimensions()",desc:"Returns ref width, height"},{name:"type",sig:":type()",desc:"Returns 'Quad'"}]},"lurek.audio.newSource":{typeName:"Source",methods:[{name:"play",sig:":play()",desc:"Start or resume playback"},{name:"pause",sig:":pause()",desc:"Pause playback"},{name:"stop",sig:":stop()",desc:"Stop and rewind"},{name:"isPlaying",sig:":isPlaying()",desc:"Returns true if playing"},{name:"setVolume",sig:":setVolume(v)",desc:"Set volume (0-1)"},{name:"getVolume",sig:":getVolume()",desc:"Returns current volume"},{name:"setPitch",sig:":setPitch(p)",desc:"Set pitch multiplier"},{name:"getPitch",sig:":getPitch()",desc:"Returns pitch"},{name:"setLooping",sig:":setLooping(loop)",desc:"Enable/disable loop"},{name:"isLooping",sig:":isLooping()",desc:"Returns loop state"},{name:"seek",sig:":seek(seconds)",desc:"Seek to position"},{name:"tell",sig:":tell()",desc:"Returns current position"},{name:"getDuration",sig:":getDuration()",desc:"Returns duration in seconds"},{name:"release",sig:":release()",desc:"Free audio resources"},{name:"type",sig:":type()",desc:"Returns 'Source'"}]},"lurek.physics.newWorld":{typeName:"World",methods:[{name:"update",sig:":update(dt)",desc:"Step the simulation"},{name:"setGravity",sig:":setGravity(gx, gy)",desc:"Set gravity vector"},{name:"getGravity",sig:":getGravity()",desc:"Returns gx, gy"},{name:"getBodyCount",sig:":getBodyCount()",desc:"Number of bodies"},{name:"queryBoundingBox",sig:":queryBoundingBox(x1, y1, x2, y2, fn)",desc:"Query AABB"},{name:"rayCast",sig:":rayCast(x1, y1, x2, y2, fn)",desc:"Cast a ray"},{name:"setCallbacks",sig:":setCallbacks(begin, end, pre, post)",desc:"Set collision callbacks"},{name:"destroy",sig:":destroy()",desc:"Destroy physics world"},{name:"type",sig:":type()",desc:"Returns 'World'"}]},"lurek.physics.newBody":{typeName:"Body",methods:[{name:"getPosition",sig:":getPosition()",desc:"Returns x, y"},{name:"setPosition",sig:":setPosition(x, y)",desc:"Set position"},{name:"getAngle",sig:":getAngle()",desc:"Returns rotation in radians"},{name:"setAngle",sig:":setAngle(angle)",desc:"Set rotation"},{name:"getLinearVelocity",sig:":getLinearVelocity()",desc:"Returns vx, vy"},{name:"setLinearVelocity",sig:":setLinearVelocity(vx, vy)",desc:"Set velocity"},{name:"applyForce",sig:":applyForce(fx, fy)",desc:"Apply force at center"},{name:"applyLinearImpulse",sig:":applyLinearImpulse(ix, iy)",desc:"Apply impulse"},{name:"setMass",sig:":setMass(mass)",desc:"Set body mass"},{name:"getMass",sig:":getMass()",desc:"Returns body mass"},{name:"setType",sig:":setType(type)",desc:"Set body type"},{name:"getType",sig:":getType()",desc:"Returns body type string"},{name:"isAwake",sig:":isAwake()",desc:"Returns true if body is awake"},{name:"destroy",sig:":destroy()",desc:"Remove body from world"},{name:"type",sig:":type()",desc:"Returns 'Body'"}]},"lurek.graphics.newParticleSystem":{typeName:"ParticleSystem",methods:[{name:"emit",sig:":emit(count)",desc:"Emit particles"},{name:"update",sig:":update(dt)",desc:"Update particle system"},{name:"start",sig:":start()",desc:"Start emitting"},{name:"stop",sig:":stop()",desc:"Stop emitting"},{name:"pause",sig:":pause()",desc:"Pause system"},{name:"reset",sig:":reset()",desc:"Reset and clear particles"},{name:"getCount",sig:":getCount()",desc:"Returns active particle count"},{name:"setEmissionRate",sig:":setEmissionRate(rate)",desc:"Particles per second"},{name:"setLifetime",sig:":setLifetime(min, max)",desc:"Set particle lifetime range"},{name:"setPosition",sig:":setPosition(x, y)",desc:"Set emitter position"},{name:"setSpeed",sig:":setSpeed(min, max)",desc:"Set speed range"},{name:"setDirection",sig:":setDirection(angle)",desc:"Set emission direction"},{name:"setSpread",sig:":setSpread(spread)",desc:"Set emission cone angle"},{name:"release",sig:":release()",desc:"Free resources"},{name:"type",sig:":type()",desc:"Returns 'ParticleSystem'"}]},"lurek.cardgame.clone":{typeName:"Card",fields:[{name:"card_type",type:"string",desc:"The registered card type name"},{name:"name",type:"string",desc:"Card display name"},{name:"category",type:"string",desc:"Category (creature, spell, etc.)"},{name:"face_up",type:"boolean",desc:"Whether the card is face-up"},{name:"tapped",type:"boolean",desc:"Whether the card is tapped/exhausted"},{name:"owner",type:"string",desc:"Owner player identifier"},{name:"controller",type:"string",desc:"Controller player identifier"},{name:"zone",type:"string",desc:"Current zone name"}],methods:[{name:"hasTag",sig:":hasTag(tag)",desc:"Returns true if card has the tag"},{name:"addTag",sig:":addTag(tag)",desc:"Add a tag (deduplicated)"},{name:"removeTag",sig:":removeTag(tag)",desc:"Remove a tag by value"},{name:"getStat",sig:":getStat(name)",desc:"Get a numeric stat value"},{name:"setStat",sig:":setStat(name, value)",desc:"Set a numeric stat value"},{name:"addCounter",sig:":addCounter(kind, amount)",desc:"Add to a counter, returns new total"},{name:"getCounter",sig:":getCounter(kind)",desc:"Get a counter value"},{name:"tap",sig:":tap()",desc:"Tap the card (exhausted)"},{name:"untap",sig:":untap()",desc:"Untap the card"},{name:"getMeta",sig:":getMeta(key)",desc:"Get metadata value"},{name:"setMeta",sig:":setMeta(key, value)",desc:"Set metadata value"}]},"lurek.cardgame.newCard":{typeName:"Card",fields:[{name:"card_type",type:"string",desc:"The registered card type name"},{name:"name",type:"string",desc:"Card display name"},{name:"category",type:"string",desc:"Category (creature, spell, etc.)"},{name:"face_up",type:"boolean",desc:"Whether the card is face-up"},{name:"tapped",type:"boolean",desc:"Whether the card is tapped/exhausted"},{name:"owner",type:"string",desc:"Owner player identifier"},{name:"controller",type:"string",desc:"Controller player identifier"},{name:"zone",type:"string",desc:"Current zone name"}],methods:[{name:"hasTag",sig:":hasTag(tag)",desc:"Returns true if card has the tag"},{name:"addTag",sig:":addTag(tag)",desc:"Add a tag (deduplicated)"},{name:"removeTag",sig:":removeTag(tag)",desc:"Remove a tag by value"},{name:"getStat",sig:":getStat(name)",desc:"Get a numeric stat value"},{name:"setStat",sig:":setStat(name, value)",desc:"Set a numeric stat value"},{name:"addCounter",sig:":addCounter(kind, amount)",desc:"Add to a counter, returns new total"},{name:"getCounter",sig:":getCounter(kind)",desc:"Get a counter value"},{name:"removeCounters",sig:":removeCounters(kind)",desc:"Remove all counters of a type"},{name:"getMeta",sig:":getMeta(key)",desc:"Get metadata value"},{name:"setMeta",sig:":setMeta(key, value)",desc:"Set metadata value"},{name:"tap",sig:":tap()",desc:"Tap the card (exhausted)"},{name:"untap",sig:":untap()",desc:"Untap the card"},{name:"getAllCounters",sig:":getAllCounters()",desc:"Returns all (kind, count) counter pairs"}]},"lurek.cardgame.newDeck":{typeName:"Deck",fields:[{name:"name",type:"string",desc:"Deck display name"}],methods:[{name:"shuffle",sig:":shuffle()",desc:"Shuffle using Fisher-Yates"},{name:"draw",sig:":draw()",desc:"Draw from the top; returns Card or nil"},{name:"drawBottom",sig:":drawBottom()",desc:"Draw from the bottom"},{name:"pushTop",sig:":pushTop(card)",desc:"Add a card to the top"},{name:"pushBottom",sig:":pushBottom(card)",desc:"Add a card to the bottom"},{name:"peek",sig:":peek()",desc:"Peek at the top card without removing"},{name:"insertAt",sig:":insertAt(index, card)",desc:"Insert a card at a 0-based position"},{name:"removeAt",sig:":removeAt(index)",desc:"Remove and return card at index"},{name:"moveWithin",sig:":moveWithin(from, to)",desc:"Move card at from_index to to_index"},{name:"size",sig:":size()",desc:"Returns card count"},{name:"isEmpty",sig:":isEmpty()",desc:"Returns true if empty"},{name:"searchByTag",sig:":searchByTag(tag)",desc:"Returns indices of cards with tag"},{name:"searchByType",sig:":searchByType(card_type)",desc:"Returns indices of matching type"},{name:"countByType",sig:":countByType(card_type)",desc:"Count cards of a specific type"},{name:"revealTop",sig:":revealTop(n)",desc:"Peek at top n cards, returns type strings"},{name:"reset",sig:":reset()",desc:"Reset to original state"}]},"lurek.cardgame.newDeckBuilder":{typeName:"DeckBuilder",fields:[{name:"min_cards",type:"integer",desc:"Minimum total cards required"},{name:"max_cards",type:"integer",desc:"Maximum total cards allowed (0 = no limit)"},{name:"max_copies",type:"integer",desc:"Maximum copies of a single card type"}],methods:[{name:"validate",sig:":validate(deck)",desc:"Validate a deck, returns list of violation messages"}]},"lurek.cardgame.newStackManager":{typeName:"StackManager",methods:[{name:"push",sig:":push(entry)",desc:"Push an entry onto the stack"},{name:"resolve",sig:":resolve()",desc:"Pop and return the top entry"},{name:"peek",sig:":peek()",desc:"Peek at the top entry"},{name:"isEmpty",sig:":isEmpty()",desc:"Whether the stack has anything to resolve"},{name:"size",sig:":size()",desc:"Number of entries on the stack"},{name:"clear",sig:":clear()",desc:"Clear all entries"},{name:"findByKind",sig:":findByKind(kind)",desc:"Find first entry matching a kind"}]},"lurek.cardgame.newZone":{typeName:"Zone",fields:[{name:"name",type:"string",desc:"Zone name"},{name:"capacity",type:"integer",desc:"Max capacity (0 = unlimited)"}],methods:[{name:"canAdd",sig:":canAdd()",desc:"Returns true if zone accepts one more card"},{name:"add",sig:":add(card)",desc:"Add a card (returns error if zone full)"},{name:"removeAt",sig:":removeAt(index)",desc:"Remove card at 0-based index"},{name:"size",sig:":size()",desc:"Number of cards in zone"},{name:"isEmpty",sig:":isEmpty()",desc:"True if empty"},{name:"findByType",sig:":findByType(card_type)",desc:"Find first card by type"},{name:"countByType",sig:":countByType(card_type)",desc:"Count cards of a specific type"},{name:"getAllTypes",sig:":getAllTypes()",desc:"Return type strings of all cards"}]},"lurek.cardgame.newCardPool":{typeName:"CardPool",fields:[{name:"name",type:"string",desc:"Pool name"}],methods:[{name:"add",sig:":add(card_type, weight)",desc:"Add a card type with weight (default 1)"},{name:"remove",sig:":remove(card_type)",desc:"Remove a card type from pool"},{name:"draw",sig:":draw(n)",desc:"Draw n cards (with replacement), returns type names"},{name:"size",sig:":size()",desc:"Number of entries"},{name:"getTypes",sig:":getTypes()",desc:"Returns all card types in pool"},{name:"totalWeight",sig:":totalWeight()",desc:"Total weight of all entries"}]},"lurek.ecs.new":{typeName:"Entity",methods:[{name:"getId",sig:":getId()",desc:"Returns entity ID"},{name:"getTag",sig:":getTag()",desc:"Returns entity tag"},{name:"setTag",sig:":setTag(tag)",desc:"Set entity tag"},{name:"getPosition",sig:":getPosition()",desc:"Returns x, y"},{name:"setPosition",sig:":setPosition(x, y)",desc:"Set position"},{name:"getComponent",sig:":getComponent(name)",desc:"Get component by name"},{name:"addComponent",sig:":addComponent(name, data)",desc:"Add component"},{name:"removeComponent",sig:":removeComponent(name)",desc:"Remove component"},{name:"hasComponent",sig:":hasComponent(name)",desc:"Returns true if entity has component"},{name:"destroy",sig:":destroy()",desc:"Destroy entity"},{name:"isAlive",sig:":isAlive()",desc:"Returns true if entity is alive"},{name:"type",sig:":type()",desc:"Returns 'Entity'"}]},"lurek.timer.after":{typeName:"Timer",methods:[{name:"cancel",sig:":cancel()",desc:"Cancel the timer"},{name:"pause",sig:":pause()",desc:"Pause the timer"},{name:"resume",sig:":resume()",desc:"Resume the timer"},{name:"isActive",sig:":isActive()",desc:"Returns true if still active"},{name:"type",sig:":type()",desc:"Returns 'Timer'"}]},"lurek.timer.every":{typeName:"Timer",methods:[{name:"cancel",sig:":cancel()",desc:"Cancel the timer"},{name:"pause",sig:":pause()",desc:"Pause the timer"},{name:"resume",sig:":resume()",desc:"Resume the timer"},{name:"isActive",sig:":isActive()",desc:"Returns true if still active"},{name:"type",sig:":type()",desc:"Returns 'Timer'"}]},"lurek.timer.tween":{typeName:"Tween",methods:[{name:"cancel",sig:":cancel()",desc:"Cancel the tween"},{name:"pause",sig:":pause()",desc:"Pause the tween"},{name:"resume",sig:":resume()",desc:"Resume the tween"},{name:"isActive",sig:":isActive()",desc:"Returns true if still active"},{name:"getProgress",sig:":getProgress()",desc:"Returns progress 0-1"},{name:"type",sig:":type()",desc:"Returns 'Tween'"}]},"lurek.tilemap.load":{typeName:"Tilemap",methods:[{name:"draw",sig:":draw()",desc:"Draw the tilemap"},{name:"getWidth",sig:":getWidth()",desc:"Returns width in tiles"},{name:"getHeight",sig:":getHeight()",desc:"Returns height in tiles"},{name:"getTileAt",sig:":getTileAt(x, y)",desc:"Get tile at grid position"},{name:"setTileAt",sig:":setTileAt(x, y, tile)",desc:"Set tile at grid position"},{name:"getLayer",sig:":getLayer(name)",desc:"Get layer by name"},{name:"getLayerCount",sig:":getLayerCount()",desc:"Returns number of layers"},{name:"getProperty",sig:":getProperty(name)",desc:"Get map property"},{name:"type",sig:":type()",desc:"Returns 'Tilemap'"}]},"lurek.scene.new":{typeName:"Scene",methods:[{name:"enter",sig:":enter()",desc:"Called when scene becomes active"},{name:"exit",sig:":exit()",desc:"Called when scene is deactivated"},{name:"update",sig:":update(dt)",desc:"Update scene"},{name:"draw",sig:":draw()",desc:"Draw scene"},{name:"getName",sig:":getName()",desc:"Returns scene name"},{name:"type",sig:":type()",desc:"Returns 'Scene'"}]},"lurek.data.newStore":{typeName:"DataStore",methods:[{name:"get",sig:":get(key)",desc:"Get value by key"},{name:"set",sig:":set(key, value)",desc:"Set a key-value pair"},{name:"delete",sig:":delete(key)",desc:"Delete a key"},{name:"has",sig:":has(key)",desc:"Returns true if key exists"},{name:"keys",sig:":keys()",desc:"Returns all keys"},{name:"values",sig:":values()",desc:"Returns all values"},{name:"clear",sig:":clear()",desc:"Remove all entries"},{name:"size",sig:":size()",desc:"Returns number of entries"},{name:"type",sig:":type()",desc:"Returns 'DataStore'"}]},"lurek.event.on":{typeName:"EventHandle",methods:[{name:"cancel",sig:":cancel()",desc:"Unsubscribe from event"},{name:"type",sig:":type()",desc:"Returns 'EventHandle'"}]},"lurek.camera.new":{typeName:"Camera",methods:[{name:"getPosition",sig:":getPosition()",desc:"Returns x, y"},{name:"setPosition",sig:":setPosition(x, y)",desc:"Set camera position"},{name:"getZoom",sig:":getZoom()",desc:"Returns zoom level"},{name:"setZoom",sig:":setZoom(zoom)",desc:"Set zoom level"},{name:"getRotation",sig:":getRotation()",desc:"Returns rotation in radians"},{name:"setRotation",sig:":setRotation(angle)",desc:"Set rotation"},{name:"lookAt",sig:":lookAt(x, y)",desc:"Center camera on position"},{name:"shake",sig:":shake(intensity, duration)",desc:"Apply screen shake"},{name:"attach",sig:":attach()",desc:"Apply camera transform"},{name:"detach",sig:":detach()",desc:"Reset camera transform"},{name:"worldToScreen",sig:":worldToScreen(wx, wy)",desc:"Convert world to screen coords"},{name:"screenToWorld",sig:":screenToWorld(sx, sy)",desc:"Convert screen to world coords"},{name:"type",sig:":type()",desc:"Returns 'Camera'"}]}},pl=["render","audio","physics","input","timer","filesystem","compute","data","image","ecs","window","thread","animation","camera","automation","event","math","particle","tilemap","scene","save","mods","graph","pathfind","ai","dataframe","ui","minimap","effect","postfx","terminal","cardgame","tween"];function Pr(n){let e=[],t=[],r=[],a=new Map,s=n.getText().split(`
`);for(let o=0;o<s.length;o++){let l=s[o],p=l.match(/\blocal\s+(\w+)\s*=\s*(lurek\.\w+\.\w+)\s*\(/);if(p){let[,P,v]=p,x=ei(v);x&&e.push({varName:P,typeName:x,factoryCall:v,line:o})}let u=l.match(/\blocal\s+(\w+)\s*=\s*(lurek\.(\w+))\s*(?:$|--)/);if(u){let[,P,v,x]=u;(Xe?.getModuleNames()??pl).includes(x)&&r.push({varName:P,modulePath:v,line:o})}let d=l.match(/\blocal\s+(\w+)\s*=\s*(\w+)\s*(?:$|--)/);if(d){let[,P,v]=d,x=e.find(B=>B.varName===v&&B.line<o);x&&e.push({varName:P,typeName:x.typeName,factoryCall:x.factoryCall,line:o})}let m=l.match(/\b(?:local\s+)?(\w+)\s*=\s*\{\s*\}/);if(m){let P=m[1];if(o+1<s.length){let v=s[o+1];(v.includes(`${P}.__index`)||v.includes(`__index = ${P}`))&&(a.has(P)||a.set(P,{name:P,methods:[],instances:[]}))}}let h=l.match(/\b(\w+)\.__index\s*=\s*\1\b/);if(h){let P=h[1];a.has(P)||a.set(P,{name:P,methods:[],instances:[]})}let f=l.match(/\bfunction\s+(\w+):(\w+)\s*\(/);if(f){let[,P,v]=f,x=a.get(P);x||(x={name:P,methods:[],instances:[]},a.set(P,x)),x.methods.find(B=>B.name===v)||x.methods.push({name:v,sig:`:${v}(...)`,desc:`Method of ${P}`})}let S=l.match(/\blocal\s+(\w+)\s*=\s*(\w+)[:.](new|create)\s*\(/);if(S){let[,P,v]=S,x=a.get(v);x&&x.instances.push({varName:P,line:o})}let y=l.match(/\blocal\s+(\w+)\s*=\s*setmetatable\s*\([^,]*,\s*(\w+)\s*\)/)??l.match(/\blocal\s+(\w+)\s*=\s*setmetatable\s*\([^,]*,\s*\{[^}]*__index\s*=\s*(\w+)[^}]*\}\s*\)/);if(y){let[,P,v]=y,x=a.get(v);x&&x.instances.push({varName:P,line:o})}}for(let o of a.values())t.push(o);return{varTypes:e,classes:t,moduleAliases:r}}function ul(n,e,t,r){let a=t.find(i=>i.varName===n&&i.line<e.line);if(a){let i=kr(a.typeName);if(i)return{typeInfo:i,factoryCall:a.factoryCall}}}function dl(n,e,t,r){let a=t.find(i=>i.varName===n&&i.line<e.line);if(a){let i=kr(a.typeName);if(i)return i.methods}for(let i of r)if(i.instances.find(o=>o.varName===n&&o.line<e.line)&&i.methods.length>0)return i.methods}function ti(n,e){ol(e);let t=$.languages.registerCompletionItemProvider(wr,{provideCompletionItems(i,s){let p=i.lineAt(s).text.substring(0,s.character).match(/\b(\w+):(\w*)$/);if(!p)return;let u=p[1],d=p[2].toLowerCase(),{varTypes:m,classes:h}=Pr(i),f=dl(u,s,m,h);if(f)return f.filter(S=>!d||S.name.toLowerCase().startsWith(d)).map(S=>{let y=new $.CompletionItem(S.name,$.CompletionItemKind.Method);return y.detail=S.sig,y.documentation=new $.MarkdownString(S.desc),y.sortText=`0${S.name}`,y})}},":"),r=$.languages.registerCompletionItemProvider(wr,{provideCompletionItems(i,s){let p=i.lineAt(s).text.substring(0,s.character).match(/\b(\w+)\.(\w*)$/);if(!p)return;let u=p[1];if(u==="lurek")return;let d=p[2].toLowerCase(),{varTypes:m,classes:h,moduleAliases:f}=Pr(i),S=f.find(v=>v.varName===u&&v.line<s.line);if(S){let v=S.modulePath+".",x=[];for(let B of ll())if(B.startsWith(v)){let j=B.substring(v.length);if(!d||j.toLowerCase().startsWith(d)){let H=ei(B);if(!H)continue;let Z=new $.CompletionItem(j,$.CompletionItemKind.Function);Z.detail=`\u2192 ${H}`,Z.documentation=new $.MarkdownString(`Factory from \`${B}\``),Z.sortText=`0${j}`,x.push(Z)}}if(x.length>0)return x}let y=[],P=m.find(v=>v.varName===u&&v.line<s.line);if(P){let v=kr(P.typeName);if(v){if(v.fields)for(let x of v.fields){if(d&&!x.name.toLowerCase().startsWith(d))continue;let B=new $.CompletionItem(x.name,$.CompletionItemKind.Field);B.detail=x.type,B.documentation=new $.MarkdownString(x.desc),B.sortText=`0a${x.name}`,y.push(B)}for(let x of v.methods){if(d&&!x.name.toLowerCase().startsWith(d))continue;let B=new $.CompletionItem(x.name,$.CompletionItemKind.Method);B.detail=x.sig,B.documentation=new $.MarkdownString(x.desc),B.sortText=`0b${x.name}`,y.push(B)}}}if(y.length===0){for(let v of h)if(v.instances.find(B=>B.varName===u&&B.line<s.line)&&v.methods.length>0){for(let B of v.methods){if(d&&!B.name.toLowerCase().startsWith(d))continue;let j=new $.CompletionItem(B.name,$.CompletionItemKind.Method);j.detail=B.sig,j.documentation=new $.MarkdownString(B.desc),j.sortText=`0${B.name}`,y.push(j)}break}}return y.length>0?y:void 0}},"."),a=$.languages.registerHoverProvider(wr,{provideHover(i,s){let o=i.getWordRangeAtPosition(s,/\w+/);if(!o)return;let l=i.getText(o),{varTypes:p,classes:u,moduleAliases:d}=Pr(i),m=d.find(f=>f.varName===l&&f.line<s.line);if(m){let f=new $.MarkdownString;return f.appendCodeblock(`${l}: module (${m.modulePath})`,"lua"),f.appendMarkdown(`Alias for \`${m.modulePath}\``),new $.Hover(f,o)}let h=ul(l,s,p,u);if(h){let{typeInfo:f,factoryCall:S}=h,y=new $.MarkdownString;return y.appendCodeblock(`${l}: ${f.typeName}`,"lua"),y.appendMarkdown(`Created by \`${S}()\`

`),f.fields&&f.fields.length>0&&y.appendMarkdown(`**Fields:** ${f.fields.map(P=>`\`${P.name}\``).join(", ")}

`),y.appendMarkdown(`**Methods:** ${f.methods.map(P=>`\`${P.name}\``).join(", ")}`),new $.Hover(y,o)}for(let f of u)if(f.instances.find(y=>y.varName===l&&y.line<s.line)&&f.methods.length>0){let y=new $.MarkdownString;return y.appendCodeblock(`${l}: ${f.name}`,"lua"),y.appendMarkdown(`**Methods:** ${f.methods.map(P=>`\`${P.name}\``).join(", ")}`),new $.Hover(y,o)}}});n.subscriptions.push(t,r,a)}var ae=C(require("vscode")),an=C(require("path"));var ml=new Set(["tests/lua/init","tests.lua.init","socket"]);function ni(n,e){let r=n.substring(0,e).split(`
`);return new ae.Position(r.length-1,r[r.length-1].length)}function gl(n){let e=[],t=n.replace(/--\[\[[\s\S]*?\]\]/g,i=>" ".repeat(i.length)).replace(/--[^\n]*/g,i=>" ".repeat(i.length)),r=/\brequire\s*\(\s*["']([^"']+)["']\s*\)/g,a;for(;(a=r.exec(t))!==null;){let i=a[1],s=a.index,o=a.index+a[0].length,l=ni(n,s),p=ni(n,o);e.push({moduleName:i,range:new ae.Range(l,p)})}return e}function hl(n,e){let t=n.replace(/\./g,"/"),r=[`${t}.lua`,`${t}/init.lua`];for(let a of r)return ae.Uri.joinPath(e,a)}function yl(n){let a=new Map,i=new Map,s=[];for(let l of n.keys())a.set(l,0);function o(l,p){a.set(l,1);let u=n.get(l)||[];for(let d of u)if(a.has(d))if(a.get(d)===1){let m=p.indexOf(d);if(m>=0){let h=p.slice(m);h.push(d),s.push(h)}}else a.get(d)===0&&(i.set(d,l),o(d,[...p,d]));a.set(l,2)}for(let l of n.keys())a.get(l)===0&&o(l,[l]);return s}function ri(n){let e=ae.languages.createDiagnosticCollection("lurek.requireGraph");n.subscriptions.push(e);let t=new Map,r;function a(){r&&clearTimeout(r),r=setTimeout(()=>{r=void 0,i()},500)}async function i(){let o=ae.workspace.workspaceFolders?.[0]?.uri;if(!o)return;t.clear();let l=await ae.workspace.findFiles("**/*.lua","{**/node_modules/**,ideas/**,work/**,.github/**,**/build/**,**/save/**,**/assets/**,**/logs/**,**/cag/**}");for(let p of l)try{let u=await ae.workspace.fs.readFile(p),d=new TextDecoder().decode(u),m=gl(d);for(let h of m)h.resolvedUri=hl(h.moduleName,o);t.set(p.toString(),{uri:p,requires:m})}catch{}s(o)}function s(o){let l=new Map,p=new Map;for(let[h,f]of t){let S=an.relative(o.fsPath,f.uri.fsPath).replace(/\\/g,"/").replace(/\.lua$/,"").replace(/\/init$/,"");p.set(S,h),l.set(h,[])}for(let[h,f]of t){let S=[];for(let y of f.requires){let P=y.moduleName.replace(/\./g,"/"),v=p.get(P);v&&S.push(v)}l.set(h,S)}let u=yl(l),d=new Set;for(let h of u)for(let f of h)d.add(f);e.clear();let m=new Map;for(let[h,f]of t){let S=[];for(let y of f.requires){if(y.resolvedUri){let x=y.moduleName.replace(/\./g,"/"),B=p.get(x),j=ae.workspace.asRelativePath(f.uri.fsPath).replace(/\\/g,"/"),H=j.includes("/")?j.replace(/\/[^/]+$/,""):"",Z=H?`${H}/${x}`:x,Re=p.get(Z);if(!B&&!Re&&!ml.has(y.moduleName)){let Ee=new ae.Diagnostic(y.range,`Cannot resolve module "${y.moduleName}" \u2014 file not found in workspace.`,ae.DiagnosticSeverity.Warning);Ee.code="lurek.requireMissing",Ee.source="Lurek2D Require Graph",S.push(Ee)}}let P=y.moduleName.replace(/\./g,"/"),v=p.get(P);if(v&&d.has(h)&&d.has(v)){for(let x of u)if(x.includes(h)&&x.includes(v)){let B=x.map(H=>{let Z=t.get(H);return Z?an.basename(Z.uri.fsPath,".lua"):"?"}),j=new ae.Diagnostic(y.range,`Circular dependency detected: ${B.join(" \u2192 ")}`,ae.DiagnosticSeverity.Warning);j.code="lurek.requireCycle",j.source="Lurek2D Require Graph",S.push(j);break}}}S.length>0&&m.set(h,S)}for(let[h,f]of m){let S=t.get(h);S&&e.set(S.uri,f)}}i(),n.subscriptions.push(ae.workspace.onDidSaveTextDocument(o=>{o.languageId==="lua"&&a()}),ae.workspace.onDidCreateFiles(()=>a()),ae.workspace.onDidDeleteFiles(()=>a()))}var U=C(require("vscode")),bl=[{regex:/\bfunction\s+(\w+\.\w+)\s*\(/g,kind:U.SymbolKind.Function,group:1},{regex:/\bfunction\s+(\w+)\s*\(/g,kind:U.SymbolKind.Function,group:1},{regex:/\blocal\s+function\s+(\w+)\s*\(/g,kind:U.SymbolKind.Function,group:1},{regex:/\bfunction\s+(\w+:\w+)\s*\(/g,kind:U.SymbolKind.Method,group:1},{regex:/^(\w+)\s*=\s*\{\s*\}/gm,kind:U.SymbolKind.Class,group:1},{regex:/\blocal\s+(\w+)\s*=\s*\{\s*\}/g,kind:U.SymbolKind.Class,group:1},{regex:/^([A-Z][A-Z_0-9]+)\s*=/gm,kind:U.SymbolKind.Constant,group:1},{regex:/\b(lurek\.\w+)\s*=\s*function/g,kind:U.SymbolKind.Function,group:1},{regex:/\bfunction\s+(lurek\.\w+)\s*\(/g,kind:U.SymbolKind.Function,group:1}],Mr=class{symbols=new Map;fileSymbols=new Map;building=!1;async buildIndex(){if(!this.building){this.building=!0;try{this.symbols.clear(),this.fileSymbols.clear();let e=await U.workspace.findFiles("**/*.lua","{**/node_modules/**,ideas/**,work/**,.github/**,**/build/**,**/save/**,**/assets/**,**/logs/**}");for(let t of e)try{let r=await U.workspace.fs.readFile(t),a=new TextDecoder().decode(r);this.indexText(t,a)}catch{}}finally{this.building=!1}}}async updateFile(e){try{let t=await U.workspace.openTextDocument(e);this.indexDocument(t)}catch{this.removeFile(e)}}removeFile(e){let t=e.toString(),r=this.fileSymbols.get(t)||[];for(let a of r){let i=this.symbols.get(a.name);if(i){let s=i.filter(o=>o.uri.toString()!==t);s.length>0?this.symbols.set(a.name,s):this.symbols.delete(a.name)}}this.fileSymbols.delete(t)}findDefinition(e){let t=this.symbols.get(e);if(!(!t||t.length===0))return t.find(r=>r.kind===U.SymbolKind.Function)||t.find(r=>r.kind===U.SymbolKind.Method)||t[0]}findReferences(e){return this.symbols.get(e)||[]}getWorkspaceSymbols(e){let t=e.toLowerCase(),r=[];for(let[a,i]of this.symbols)if(!t||a.toLowerCase().includes(t))for(let s of i)r.push(new U.SymbolInformation(s.name,s.kind,s.containerName||"",new U.Location(s.uri,s.range)));return r}getFileSymbols(e){return this.fileSymbols.get(e.toString())||[]}positionFromOffset(e,t){let a=e.substring(0,t).split(`
`);return new U.Position(a.length-1,a[a.length-1].length)}indexText(e,t){let r=e.toString();this.removeFile(e);let a=[];for(let i of bl){i.regex.lastIndex=0;let s;for(;(s=i.regex.exec(t))!==null;){let o=s[i.group],l=this.positionFromOffset(t,s.index),p=this.positionFromOffset(t,s.index+s[0].length),u;o.includes(":")?u=o.split(":")[0]:o.includes(".")&&!o.startsWith("lurek.")&&(u=o.split(".")[0]);let d={name:o,kind:i.kind,uri:e,range:new U.Range(l,p),containerName:u};a.push(d);let m=this.symbols.get(o)||[];m.push(d),this.symbols.set(o,m)}}this.fileSymbols.set(r,a)}indexDocument(e){this.indexText(e.uri,e.getText())}};function ai(n){let e=new Mr;e.buildIndex(),n.subscriptions.push(U.workspace.onDidSaveTextDocument(r=>{r.languageId==="lua"&&e.updateFile(r.uri)}),U.workspace.onDidDeleteFiles(r=>{for(let a of r.files)e.removeFile(a)}),U.workspace.onDidCreateFiles(r=>{for(let a of r.files)a.fsPath.endsWith(".lua")&&e.updateFile(a)}));let t=U.languages.registerWorkspaceSymbolProvider({provideWorkspaceSymbols(r){return e.getWorkspaceSymbols(r)}});return n.subscriptions.push(t),e}var ot=C(require("vscode"));var Tl={scheme:"file",language:"lua"},xl=new Se,si=["namespace","function","enumMember","lurekCallback"],oi=["declaration","definition","readonly","deprecated","modification","documentation","defaultLibrary"],Sr=new ot.SemanticTokensLegend(si,oi),ii=new Map;function li(n,e){n.subscriptions.push(ot.languages.registerDocumentSemanticTokensProvider(Tl,{provideDocumentSemanticTokens(t){try{return wl(t,e)}catch{return new ot.SemanticTokensBuilder(Sr).build()}}},Sr))}function wl(n,e){let t=n.uri.toString(),r=ii.get(t);if(r&&r.version===n.version)return r.tokens;let a=n.getText(),i=xl.tokenize(a),s=new ot.SemanticTokensBuilder(Sr),o=new Set(e.getAllFunctions().map(d=>d.name)),l=new Set(e.getAllFunctions().filter(d=>d.deprecated).map(d=>d.name)),p=new Set;for(let d of e.getModuleNames()){let m=e.getModule(d);if(m){for(let h of[...m.functions,...m.methods])for(let f of h.parameters)if(f.type.includes("|"))for(let S of f.type.split("|")){let y=S.trim().replace(/^["']|["']$/g,"");y&&!y.includes(" ")&&p.add(y)}}}for(let d=0;d<i.length;d++){let m=i[d];if(m.type===2){let y=Pl(m.value);y&&p.has(y)&&Mt(s,m,"enumMember",[]);continue}if(m.type!==1)continue;let h=m.value,f=kl(i,d),S=Ml(i,d);if(h==="lurek"){Mt(s,m,"namespace",[]);continue}if(f?.value==="."||f?.value===":"){let y=Sl(i,d);if(y.startsWith("lurek.")){let v=y.slice(6).split(".");if(v.length===1&&We.has(h)){Mt(s,m,"lurekCallback",[]);continue}if(v.length===1&&e.getModule(h)){Mt(s,m,"namespace",[]);continue}if(o.has(h)){let x=["defaultLibrary"];l.has(h)&&x.push("deprecated"),Mt(s,m,"function",x);continue}}}}let u=s.build();return ii.set(t,{version:n.version,tokens:u}),u}function Pl(n){return n.startsWith('"')&&n.endsWith('"')||n.startsWith("'")&&n.endsWith("'")?n.slice(1,-1):""}function Mt(n,e,t,r){let i=e.value.split(`
`)[0].length;if(i===0)return;let s=si.indexOf(t);if(s<0)return;let o=0;for(let l of r){let p=oi.indexOf(l);p>=0&&(o|=1<<p)}n.push(e.line,e.column,i,s,o)}function kl(n,e){for(let t=e-1;t>=0;t--)if(n[t].type!==7)return n[t]}function Ml(n,e){for(let t=e+1;t<n.length;t++)if(n[t].type!==7)return n[t]}function Sl(n,e){let t=n[e].value,r=e-1;for(;r>=0;){if(n[r].type===7){r--;continue}if(n[r].type===6&&(n[r].value==="."||n[r].value===":")){for(r--;r>=0&&n[r].type===7;)r--;if(r>=0&&n[r].type===1){t=n[r].value+"."+t,r--;continue}}break}return t}var ee=C(require("vscode")),he=C(require("path")),Pe=C(require("fs")),lt=class n extends ee.TreeItem{constructor(t,r,a,i,s){super(t,r);this.label=t;this.collapsibleState=r;this.resourceUri=a;this.assetType=i;this.sizeBytes=s;a&&(this.resourceUri=a,this.tooltip=a.fsPath),this.iconPath=i?new ee.ThemeIcon(n.iconFor(i)):void 0,s!==void 0&&(this.description=n.formatSize(s)),i&&i!=="folder"&&a&&(this.command={command:"vscode.open",title:"Open File",arguments:[a]})}static iconFor(t){switch(t){case"image":return"file-media";case"audio":return"unmute";case"font":return"text-size";case"shader":return"symbol-color";case"folder":return"folder";default:return"file"}}static formatSize(t){return t<1024?`${t} B`:t<1024*1024?`${(t/1024).toFixed(1)} KB`:`${(t/1024/1024).toFixed(1)} MB`}},jl=new Set([".png",".jpg",".jpeg",".bmp",".gif",".tga",".tiff",".webp"]),Rl=new Set([".wav",".ogg",".mp3",".flac",".aiff"]),El=new Set([".ttf",".otf"]),Ll=new Set([".glsl",".vert",".frag",".wgsl"]);function Il(n){if(jl.has(n))return"image";if(Rl.has(n))return"audio";if(El.has(n))return"font";if(Ll.has(n))return"shader"}var sn=class{_onDidChangeTreeData=new ee.EventEmitter;onDidChangeTreeData=this._onDidChangeTreeData.event;categories=[];_missingAssets=[];constructor(){this.refresh()}refresh(){this.categories=[{label:"Images",type:"image",icon:"file-media",root:this._newFolder("",""),totalCount:0},{label:"Audio",type:"audio",icon:"unmute",root:this._newFolder("",""),totalCount:0},{label:"Fonts",type:"font",icon:"text-size",root:this._newFolder("",""),totalCount:0},{label:"Shaders",type:"shader",icon:"symbol-color",root:this._newFolder("",""),totalCount:0}],this._missingAssets=[],this._scanGameRoot(),this._onDidChangeTreeData.fire(void 0)}get missingAssets(){return this._missingAssets}_findGameRoot(){let e=ee.workspace.workspaceFolders;if(!e?.length)return;let t=e[0].uri.fsPath;if(Pe.existsSync(he.join(t,"main.lua")))return t;let r=["content/demos","content/examples","examples","game","src"];for(let a of r){let i=he.join(t,a);if(Pe.existsSync(i))try{let s=Pe.readdirSync(i,{withFileTypes:!0});for(let o of s)if(o.isDirectory()){let l=he.join(i,o.name);if(Pe.existsSync(he.join(l,"main.lua")))return l}}catch{}}return t}_scanGameRoot(){let e=this._findGameRoot();e&&this._walk(e,e)}_newFolder(e,t){return{name:e,relPath:t,children:new Map,files:[]}}_ensureFolder(e,t){if(!t||t===".")return e;let r=t.split("/"),a=e,i="";for(let s of r){i=i?`${i}/${s}`:s;let o=a.children.get(s);o||(o=this._newFolder(s,i),a.children.set(s,o)),a=o}return a}_walk(e,t){let r;try{r=Pe.readdirSync(e,{withFileTypes:!0})}catch{return}for(let a of r){let i=he.join(e,a.name);if(!(a.name.startsWith(".")||a.name==="node_modules"||a.name==="target"||a.name==="build")){if(a.isDirectory())this._walk(i,t);else if(a.isFile()){let s=he.extname(a.name).toLowerCase(),o=Il(s);if(!o)continue;let l=this.categories.find(h=>h.type===o);if(!l)continue;let p=0;try{p=Pe.statSync(i).size}catch{}let u=he.relative(t,i).replace(/\\/g,"/"),d=he.dirname(u);this._ensureFolder(l.root,d==="."?"":d).files.push({name:a.name,relPath:u,uri:ee.Uri.file(i),size:p,type:o}),l.totalCount++}}}}getTreeItem(e){return e}getChildren(e){if(!e)return this.categories.filter(i=>i.totalCount>0).map(i=>{let s=new lt(`${i.label} (${i.totalCount})`,ee.TreeItemCollapsibleState.Collapsed,void 0,"folder",void 0);return s.contextValue=`assetCategory.${i.type}`,s._catType=i.type,s});let t=e._catType;if(t){let i=this.categories.find(s=>s.type===t);return i?this._folderChildren(i.root,i.type):[]}let r=e._folderNode,a=e._fileType;return r?this._folderChildren(r,a||"image"):[]}_folderChildren(e,t){let r=[],a=Array.from(e.children.entries()).sort((s,o)=>s[0].localeCompare(o[0]));for(let[s,o]of a){let l=this._countFiles(o),p=new lt(`${s} (${l})`,ee.TreeItemCollapsibleState.Collapsed,void 0,"folder",void 0);p._folderNode=o,p._fileType=t,r.push(p)}let i=[...e.files].sort((s,o)=>s.name.localeCompare(o.name));for(let s of i){let o=new lt(s.name,ee.TreeItemCollapsibleState.None,s.uri,s.type,s.size);o.contextValue="assetItem",r.push(o)}return r}_countFiles(e){let t=e.files.length;for(let r of e.children.values())t+=this._countFiles(r);return t}};async function pi(){let n=ee.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!n){ee.window.showWarningMessage("No workspace folder open.");return}let e=await ee.workspace.findFiles("**/*.lua","{**/node_modules/**,ideas/**,work/**,.github/**}"),t=/lurek\.(?:graphics\.newImage|audio\.newSource)\s*\(\s*["']([^"']+)["']/g,r=[];for(let s of e){let o;try{o=Pe.readFileSync(s.fsPath,"utf8")}catch{continue}let l=o.split(`
`);for(let p=0;p<l.length;p++){t.lastIndex=0;let u;for(;(u=t.exec(l[p]))!==null;){let d=u[1];if(!d.includes("."))continue;let m=he.resolve(he.dirname(s.fsPath),d),h=he.resolve(n,d);!Pe.existsSync(m)&&!Pe.existsSync(h)&&r.push({file:ee.workspace.asRelativePath(s),line:p+1,asset:d})}}}if(r.length===0){ee.window.showInformationMessage("No missing assets found.");return}let a=r.map(s=>`${s.file}:${s.line}  \u2192  ${s.asset}`).join(`
`),i=await ee.workspace.openTextDocument({content:`Missing assets:

${a}`,language:"plaintext"});ee.window.showTextDocument(i)}function ui(n){let e=ee.window.activeTextEditor;if(!e||!n.resourceUri)return;let t=ee.workspace.workspaceFolders?.[0]?.uri.fsPath??"",r=n.resourceUri.fsPath;t&&r.startsWith(t)&&(r=r.substring(t.length+1)),r=r.replace(/\\/g,"/"),e.edit(a=>a.replace(e.selection,`"${r}"`))}Rr();var X=C(require("vscode"));var Bl={scheme:"file",language:"lua"},Er=class{_onDidChange=new X.EventEmitter;onDidChangeCodeLenses=this._onDidChange.event;provideCodeLenses(e){let t=[],r=e.getText(),a=r.split(`
`),i=/^(?:local\s+function\s+(\w+)|function\s+([\w.:]+))/;function s(o){let l=o.replace(/[.]/g,"\\."),p=new RegExp(`\\b${l}\\b`,"g"),u=r.match(p)??[];return Math.max(0,u.length-1)}for(let o=0;o<a.length;o++){let l=a[o],p=i.exec(l.trimStart());if(!p)continue;let u=p[1]??p[2];if(!u)continue;let d=new X.Range(o,0,o,0),h=u.match(/^lurek\.(\w+)$/)?.[1];if(h&&zl.has(h))t.push(new X.CodeLens(d,{title:`\u26A1 lurek.${h} callback`,command:"lurek.browseApi",arguments:[`lurek.${h}`],tooltip:`Open API documentation for lurek.${h}`}));else{let f=s(u.split(".").pop()??u),S=f===1?"1 reference":`${f} references`;t.push(new X.CodeLens(d,{title:f===0?"\u26A0 unused":S,command:"lurek.codelens.findRefs",arguments:[e.uri,new X.Position(o,l.indexOf(u)),u],tooltip:f===0?`"${u}" is never called`:`Find all references to "${u}"`}))}/^test_|_test\b/.test(u)&&t.push(new X.CodeLens(d,{title:"\u25B6 Run test",command:"lurek.test.runSingleLua",arguments:[e.uri,u],tooltip:`Run Lua test "${u}"`}))}return t}refresh(){this._onDidChange.fire()}};function Fl(n){let e=X.window.createStatusBarItem(X.StatusBarAlignment.Right,95);e.name="Lurek2D Variable Type",e.tooltip="Type of the Lua symbol under the cursor",e.command="lurek.debug.openInspector",n.subscriptions.push(e);let t=[{pattern:/=\s*\d+(?:\.\d+)?(?!\w)/,type:"number"},{pattern:/=\s*["']/,type:"string"},{pattern:/=\s*(?:true|false)\b/,type:"boolean"},{pattern:/=\s*\{/,type:"table"},{pattern:/=\s*function\s*\(/,type:"function"},{pattern:/=\s*nil\b/,type:"nil"},{pattern:/lurek\.graphics\.newImage\s*\(/,type:"Image"},{pattern:/lurek\.graphics\.newCanvas\s*\(/,type:"Canvas"},{pattern:/lurek\.graphics\.newFont\s*\(/,type:"Font"},{pattern:/lurek\.graphics\.newShader\s*\(/,type:"Shader"},{pattern:/lurek\.graphics\.newMesh\s*\(/,type:"Mesh"},{pattern:/lurek\.graphics\.newSpriteBatch\s*\(/,type:"SpriteBatch"},{pattern:/lurek\.graphics\.newParticleSystem\s*\(/,type:"ParticleSystem"},{pattern:/lurek\.audio\.newSource\s*\(/,type:"Source"},{pattern:/lurek\.physics\.newWorld\s*\(/,type:"World"},{pattern:/lurek\.physics\.newBody\s*\(/,type:"Body"},{pattern:/lurek\.physics\.newFixture\s*\(/,type:"Fixture"},{pattern:/lurek\.physics\.newRectangleShape\s*\(/,type:"PolygonShape"},{pattern:/lurek\.physics\.newCircleShape\s*\(/,type:"CircleShape"},{pattern:/lurek\.math\.newTransform\s*\(/,type:"Transform"},{pattern:/lurek\.cardgame\.newCard\s*\(/,type:"Card"},{pattern:/lurek\.cardgame\.newDeck\s*\(/,type:"Deck"}];function r(a,i){let o=a.getText().split(`
`);for(let l=o.length-1;l>=0;l--){let p=o[l];if(new RegExp(`\\blocal\\s+${i}\\s*=|\\b${i}\\s*=(?!=)`,"g").test(p)){for(let{pattern:d,type:m}of t)if(d.test(p))return m;return"?"}}}n.subscriptions.push(X.window.onDidChangeTextEditorSelection(a=>{let i=a.textEditor;if(i.document.languageId!=="lua"){e.hide();return}let s=i.selection.active,o=i.document.getWordRangeAtPosition(s,/\w+/);if(!o){e.hide();return}let l=i.document.getText(o);if(/^(local|function|return|end|if|then|else|for|while|do|and|or|not|nil|true|false|repeat|until|break|goto|in)$/.test(l)){e.hide();return}let p=r(i.document,l);p?(e.text=`$(symbol-variable) ${l}: ${p}`,e.show()):e.hide()}))}var zl=We;function mi(n,e){let t=new Er;n.subscriptions.push(X.languages.registerCodeLensProvider(Bl,t)),n.subscriptions.push(X.workspace.onDidChangeTextDocument(r=>{r.document.languageId==="lua"&&t.refresh()})),n.subscriptions.push(X.commands.registerCommand("lurek.codelens.findRefs",async(r,a)=>{await X.commands.executeCommand("editor.action.referenceSearch.trigger",a)})),Fl(n),n.subscriptions.push(X.commands.registerCommand("lurek.codeLens.toggle",()=>{let r=X.workspace.getConfiguration("lurek"),a=r.get("codeLens.enabled",!0);r.update("codeLens.enabled",!a,X.ConfigurationTarget.Global),X.window.showInformationMessage(`Lurek2D Code Lens ${a?"disabled":"enabled"}`)}))}var Rt=C(require("vscode")),Ge,He=[],Ol=1,ln=!1,jt,Lr;function gi(n){Lr=n}function Ir(n){ln=n,n||He.forEach(e=>{e.value="\u2013",e.type="?",e.error=void 0}),pt(),n?hi():yi()}function hi(){jt||(jt=setInterval(()=>{on()},1500))}function yi(){jt&&(clearInterval(jt),jt=void 0)}async function on(){if(!(!Lr||!ln||He.length===0)){for(let n of He){try{let e=await Lr(n.expression);e?(n.value=e.value,n.type=e.type,n.error=void 0):(n.value="nil",n.type="nil")}catch(e){n.value="\u2013",n.type="error",n.error=e instanceof Error?e.message:String(e)}n.lastUpdated=Date.now()}pt()}}function fi(n){if(Ge){Ge.reveal(Rt.ViewColumn.Two);return}Ge=Rt.window.createWebviewPanel("lurek.debugWatchers","Lurek2D Watchers",Rt.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0}),Ge.webview.html=Gl(),Ge.onDidDispose(()=>{Ge=void 0,yi()},null,n.subscriptions),Ge.webview.onDidReceiveMessage(async e=>{switch(e.type){case"add":bi(e.expression),await on();break;case"remove":He=He.filter(t=>t.id!==e.id),pt();break;case"edit":Wl(e.id,e.expression),await on();break;case"refresh":await on();break;case"clear":He=[],pt();break}},null,n.subscriptions),pt(),ln&&hi()}function bi(n){n.trim()&&(He.push({id:Ol++,expression:n.trim(),value:"\u2013",type:"?",lastUpdated:0}),pt())}function Wl(n,e){let t=He.find(r=>r.id===n);t&&(t.expression=e.trim(),t.value="\u2013",t.type="?"),pt()}function pt(){Ge&&Ge.webview.postMessage({type:"update",watches:He,connected:ln})}function Gl(){return`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline';">
<style>
  *, *::before, *::after { box-sizing: border-box; }
  body { font-family: var(--vscode-font-family); font-size: var(--vscode-font-size); color: var(--vscode-foreground); background: var(--vscode-editor-background); padding: 8px; margin: 0; }
  h2 { margin: 0 0 8px; font-size: 14px; display: flex; align-items: center; gap: 6px; }
  .status { font-size: 11px; padding: 2px 8px; border-radius: 10px; }
  .status.connected { background: #1e5630; color: #4ec9b0; }
  .status.disconnected { background: #5a1a1a; color: #f88070; }
  .add-row { display: flex; gap: 6px; margin-bottom: 10px; }
  .add-row input { flex: 1; background: var(--vscode-input-background); color: var(--vscode-input-foreground); border: 1px solid var(--vscode-input-border, #555); padding: 4px 8px; border-radius: 3px; font-family: var(--vscode-editor-font-family); font-size: 13px; }
  .add-row input:focus { outline: 1px solid var(--vscode-focusBorder); }
  button { background: var(--vscode-button-background); color: var(--vscode-button-foreground); border: none; padding: 4px 10px; border-radius: 3px; cursor: pointer; font-size: 12px; }
  button:hover { background: var(--vscode-button-hoverBackground); }
  button.icon { background: transparent; padding: 2px 5px; opacity: 0.7; }
  button.icon:hover { opacity: 1; background: var(--vscode-toolbar-hoverBackground); border-radius: 3px; }
  table { width: 100%; border-collapse: collapse; font-size: 13px; }
  th { text-align: left; padding: 4px 8px; border-bottom: 1px solid var(--vscode-panel-border); font-size: 11px; opacity: 0.7; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; }
  td { padding: 5px 8px; border-bottom: 1px solid var(--vscode-panel-border, rgba(255,255,255,0.06)); vertical-align: middle; }
  tr:hover td { background: var(--vscode-list-hoverBackground); }
  .expr { font-family: var(--vscode-editor-font-family); color: var(--vscode-symbolIcon-variableForeground, #9cdcfe); }
  .expr input { width: 100%; background: transparent; border: 1px solid var(--vscode-focusBorder); color: inherit; font-family: inherit; font-size: inherit; padding: 1px 4px; }
  .value { font-family: var(--vscode-editor-font-family); max-width: 260px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .value.string { color: #ce9178; }
  .value.number { color: #b5cea8; }
  .value.boolean { color: #569cd6; }
  .value.table { color: #4ec9b0; }
  .value.function { color: #dcdcaa; }
  .value.nil { opacity: 0.5; }
  .value.error { color: #f44747; }
  .type { font-size: 11px; opacity: 0.6; font-family: var(--vscode-editor-font-family); }
  .toolbar { display: flex; gap: 4px; justify-content: flex-end; margin-bottom: 6px; }
  .empty { opacity: 0.5; font-size: 13px; padding: 12px 8px; }
  .age { font-size: 10px; opacity: 0.4; }
</style>
</head>
<body>
<h2>\u{1F50D} Lua Watchers
  <span class="status disconnected" id="status">Disconnected</span>
</h2>

<div class="add-row">
  <input id="newExpr" placeholder='Add expression\u2026  e.g.  player.x  or  #bullets' onkeydown="onKey(event)">
  <button onclick="addWatch()">Add</button>
</div>

<div class="toolbar">
  <button onclick="refresh()" title="Refresh all">\u27F3 Refresh</button>
  <button onclick="clearAll()" title="Clear all watches">\u2715 Clear</button>
</div>

<table id="table">
  <thead><tr><th>Expression</th><th>Value</th><th>Type</th><th>Age</th><th></th></tr></thead>
  <tbody id="tbody"><tr><td colspan="5" class="empty">No watches yet \u2014 type an expression and press Add</td></tr></tbody>
</table>

<script>
const vscode = acquireVsCodeApi();
let _watches = [];
let _editingId = null;

function onKey(e) { if (e.key === 'Enter') addWatch(); }

function addWatch() {
  const input = document.getElementById('newExpr');
  const expr = input.value.trim();
  if (!expr) return;
  vscode.postMessage({ type: 'add', expression: expr });
  input.value = '';
}

function removeWatch(id) { vscode.postMessage({ type: 'remove', id }); }

function startEdit(id, currentExpr) {
  _editingId = id;
  render();
  const input = document.querySelector('[data-edit-id="' + id + '"]');
  if (input) { input.focus(); input.select(); }
}

function commitEdit(id) {
  const input = document.querySelector('[data-edit-id="' + id + '"]');
  if (input && input.value.trim()) {
    vscode.postMessage({ type: 'edit', id, expression: input.value.trim() });
  }
  _editingId = null;
}

function refresh() { vscode.postMessage({ type: 'refresh' }); }
function clearAll() { vscode.postMessage({ type: 'clear' }); }

function timeAgo(ms) {
  if (!ms) return '\u2013';
  const s = Math.floor((Date.now() - ms) / 1000);
  if (s < 2) return 'just now';
  if (s < 60) return s + 's ago';
  return Math.floor(s / 60) + 'm ago';
}

function render() {
  const tbody = document.getElementById('tbody');
  if (_watches.length === 0) {
    tbody.innerHTML = '<tr><td colspan="5" class="empty">No watches yet \u2014 type an expression and press Add</td></tr>';
    return;
  }
  tbody.innerHTML = _watches.map(w => {
    const isEditing = _editingId === w.id;
    const exprCell = isEditing
      ? '<input data-edit-id="' + w.id + '" value="' + escHtml(w.expression) + '" onblur="commitEdit(' + w.id + ')" onkeydown="if(event.key==='Enter')commitEdit(' + w.id + ')">'
      : '<span class="expr" ondblclick="startEdit(' + w.id + ', '' + escHtml(w.expression) + '')">' + escHtml(w.expression) + '</span>';
    const valClass = 'value ' + (w.error ? 'error' : w.type);
    const displayVal = w.error ? '\u26A0 ' + escHtml(w.error) : escHtml(w.value);
    return '<tr>' +
      '<td class="expr">' + exprCell + '</td>' +
      '<td><span class="' + valClass + '" title="' + displayVal + '">' + displayVal + '</span></td>' +
      '<td><span class="type">' + escHtml(w.type) + '</span></td>' +
      '<td><span class="age">' + timeAgo(w.lastUpdated) + '</span></td>' +
      '<td><button class="icon" onclick="removeWatch(' + w.id + ')" title="Remove">\u2715</button></td>' +
      '</tr>';
  }).join('');
}

function escHtml(s) {
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

// Relative time auto-update
setInterval(() => {
  document.querySelectorAll('.age').forEach((el, i) => {
    if (_watches[i]) el.textContent = timeAgo(_watches[i].lastUpdated);
  });
}, 5000);

window.addEventListener('message', (e) => {
  const msg = e.data;
  if (msg.type === 'update') {
    _watches = msg.watches;
    document.getElementById('status').textContent = msg.connected ? 'Connected' : 'Disconnected';
    document.getElementById('status').className = 'status ' + (msg.connected ? 'connected' : 'disconnected');
    render();
  }
});
</script>
</body>
</html>`}function vi(n){let e=n.selection,t=n.document.getText(e.isEmpty?n.document.getWordRangeAtPosition(e.active,/[\w.:\[\]"']+/):e);t&&bi(t)}var Lt=C(require("vscode")),wi=require("child_process"),Pi=require("util"),pn=(0,Pi.promisify)(wi.execFile),Fe,ht=[],Hl=120,Et;async function Vl(){let n={timestamp:Date.now(),cpuPercent:0,ramUsedMb:0,ramTotalMb:0,lurekProcessCpu:0,lurekProcessRamMb:0};return process.platform==="win32"?await ql(n):await $l(n),n}async function ql(n){let e=`
$ErrorActionPreference = 'SilentlyContinue'
$mem = Get-CimInstance Win32_OperatingSystem | Select-Object FreePhysicalMemory, TotalVisibleMemorySize
$cpu = (Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$lurekProc = Get-Process -Name 'lurek2d*','lurek2d' -ErrorAction SilentlyContinue | Sort-Object CPU -Descending | Select-Object -First 1
$disk = Get-CimInstance Win32_PerfFormattedData_PerfDisk_LogicalDisk -Filter "Name='_Total'" | Select-Object DiskReadBytesPersec, DiskWriteBytesPersec
$net = Get-CimInstance Win32_PerfFormattedData_Tcpip_NetworkInterface | Measure-Object -Property BytesSentPersec,BytesReceivedPersec -Sum
[PSCustomObject]@{
  CPU = [int]$cpu
  MemFreeKB = [long]$mem.FreePhysicalMemory
  MemTotalKB = [long]$mem.TotalVisibleMemorySize
  LurekCPU = if($lurekProc){ [math]::Round($lurekProc.CPU,1) } else { 0 }
  LurekRAMMB = if($lurekProc){ [math]::Round($lurekProc.WorkingSet64 / 1MB, 1) } else { 0 }
  DiskReadBps = if($disk){ [long]$disk.DiskReadBytesPersec } else { 0 }
  DiskWriteBps = if($disk){ [long]$disk.DiskWriteBytesPersec } else { 0 }
  NetSentBps = [long]$net.Sum[0]
  NetRecvBps = [long]$net.Sum[1]
} | ConvertTo-Json -Compress`.trim();try{let{stdout:t}=await pn("powershell",["-NoProfile","-NonInteractive","-Command",e],{timeout:4e3}),r=JSON.parse(t.trim());n.cpuPercent=r.CPU??0,n.ramTotalMb=Math.round((r.MemTotalKB??0)/1024);let a=Math.round((r.MemFreeKB??0)/1024);n.ramUsedMb=n.ramTotalMb-a,n.lurekProcessCpu=r.LurekCPU??0,n.lurekProcessRamMb=r.LurekRAMMB??0;let i=r.DiskReadBps??0,s=r.DiskWriteBps??0;n.diskReadKbs=Math.round(i/1024),n.diskWriteKbs=Math.round(s/1024);let o=r.NetSentBps??0,l=r.NetRecvBps??0;n.netSentKbs=Math.round(o/1024),n.netRecvKbs=Math.round(l/1024)}catch{}try{let{stdout:t}=await pn("nvidia-smi",["--query-gpu=utilization.gpu,memory.used","--format=csv,noheader,nounits"],{timeout:2e3}),r=t.trim().split(",");n.gpuPercent=parseInt(r[0]??"0",10),n.gpuVramMb=parseInt(r[1]?.trim()??"0",10)}catch{}}async function $l(n){try{let{stdout:e}=await pn("sh",["-c",`top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1; free -m | grep Mem | awk '{print $3" "$2}'`],{timeout:3e3}),t=e.trim().split(`
`);n.cpuPercent=parseFloat(t[0]??"0");let r=(t[1]??"").split(" ");n.ramUsedMb=parseInt(r[0]??"0",10),n.ramTotalMb=parseInt(r[1]??"0",10)}catch{}try{let{stdout:e}=await pn("sh",["-c","ps -C lurek2d -o %cpu=,rss= 2>/dev/null || ps aux | grep '[l]urek2d' | awk '{print $3, $6}' | head -1"],{timeout:2e3}),t=e.trim().split(/\s+/);n.lurekProcessCpu=parseFloat(t[0]??"0"),n.lurekProcessRamMb=Math.round(parseInt(t[1]??"0",10)/1024)}catch{}}function Ti(){Et||(Et=setInterval(async()=>{let n=await Vl();ht.push(n),ht.length>Hl&&ht.shift(),Fe?.visible&&Fe.webview.postMessage({type:"data",samples:ht})},2e3))}function xi(){Et&&(clearInterval(Et),Et=void 0)}function ki(n){if(Fe){Fe.reveal(Lt.ViewColumn.Two);return}Fe=Lt.window.createWebviewPanel("lurek.systemMonitor","Lurek2D System Monitor",Lt.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0}),Fe.webview.html=Ul(),Fe.onDidDispose(()=>{Fe=void 0,xi()},null,n.subscriptions),Fe.webview.onDidReceiveMessage(e=>{e.type==="start"&&Ti(),e.type==="stop"&&xi()},null,n.subscriptions),Ti(),ht.length&&Fe.webview.postMessage({type:"data",samples:ht})}function Ul(){return`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline';">
<style>
  *, *::before, *::after { box-sizing: border-box; }
  body { font-family: var(--vscode-font-family); color: var(--vscode-foreground); background: var(--vscode-editor-background); padding: 10px; margin: 0; }
  h2 { margin: 0 0 10px; font-size: 14px; }
  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
  .card { background: var(--vscode-editorWidget-background, #1e1e1e); border-radius: 5px; padding: 10px; }
  .card-title { font-size: 11px; text-transform: uppercase; letter-spacing: .05em; opacity: 0.6; margin-bottom: 4px; display: flex; justify-content: space-between; align-items: center; }
  .big { font-size: 26px; font-weight: 700; line-height: 1; margin-bottom: 2px; }
  .sub { font-size: 11px; opacity: 0.6; margin-bottom: 6px; }
  canvas { display: block; width: 100%; height: 60px; }
  .lurek-card { grid-column: 1 / -1; }
  .row { display: flex; gap: 24px; }
  .row .stat { }
  .row .stat .big { font-size: 20px; }
  .badge { font-size: 10px; padding: 1px 6px; border-radius: 8px; }
  .badge.run { background: #1e5630; color: #4ec9b0; }
  .badge.idle { background: #3a3a3a; color: #888; }
  .status-row { display: flex; align-items: center; gap: 8px; margin-bottom: 10px; }
  .dot { width: 8px; height: 8px; border-radius: 50%; }
  .dot.active { background: #4ec9b0; box-shadow: 0 0 6px #4ec9b0; animation: pulse 1.5s infinite; }
  .dot.idle { background: #888; }
  @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.4} }
  .no-gpu { opacity: 0.4; font-size: 12px; margin-top: 4px; }
</style>
</head>
<body>
<h2>\u{1F5A5} System Monitor</h2>
<div class="status-row">
  <div class="dot idle" id="pollDot"></div>
  <span id="pollStatus" style="font-size:12px;opacity:.7">Starting\u2026</span>
  <span id="lurekStatus" class="badge idle">lurek2d: not running</span>
</div>

<div class="grid">
  <!-- CPU -->
  <div class="card">
    <div class="card-title">CPU <span id="cpuPct">\u2013%</span></div>
    <canvas id="cpuChart"></canvas>
  </div>

  <!-- RAM -->
  <div class="card">
    <div class="card-title">RAM <span id="ramPct">\u2013</span></div>
    <canvas id="ramChart"></canvas>
  </div>

  <!-- GPU -->
  <div class="card">
    <div class="card-title">GPU <span id="gpuPct">\u2013</span></div>
    <div id="gpuContent"><div class="no-gpu">No NVIDIA GPU detected (nvidia-smi required)</div></div>
    <canvas id="gpuChart"></canvas>
  </div>

  <!-- Disk -->
  <div class="card">
    <div class="card-title">Disk I/O</div>
    <div class="row">
      <div class="stat"><div class="big" id="diskR">\u2013</div><div class="sub">Read KB/s</div></div>
      <div class="stat"><div class="big" id="diskW">\u2013</div><div class="sub">Write KB/s</div></div>
    </div>
    <canvas id="diskChart"></canvas>
  </div>

  <!-- Network -->
  <div class="card">
    <div class="card-title">Network</div>
    <div class="row">
      <div class="stat"><div class="big" id="netS">\u2013</div><div class="sub">Sent KB/s</div></div>
      <div class="stat"><div class="big" id="netR">\u2013</div><div class="sub">Recv KB/s</div></div>
    </div>
    <canvas id="netChart"></canvas>
  </div>

  <!-- Lurek2D process -->
  <div class="card lurek-card">
    <div class="card-title">Lurek2D Process</div>
    <div class="row">
      <div class="stat"><div class="big" id="lurekCpu">\u2013</div><div class="sub">CPU %</div></div>
      <div class="stat"><div class="big" id="lurekRam">\u2013</div><div class="sub">RAM MB</div></div>
    </div>
    <canvas id="lurekChart"></canvas>
  </div>
</div>

<script>
const vscode = acquireVsCodeApi();
vscode.postMessage({ type: 'start' });

let _samples = [];

const COLOR = {
  cpu:   '#569cd6',
  ram:   '#4ec9b0',
  gpu:   '#dcdcaa',
  diskR: '#9cdcfe',
  diskW: '#ce9178',
  net:   '#c586c0',
  lurek:  '#f48771',
};

function drawLine(canvasId, values, color, maxVal) {
  const canvas = document.getElementById(canvasId);
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  const W = canvas.offsetWidth || 400; canvas.width = W;
  const H = canvas.offsetHeight || 60; canvas.height = H;
  ctx.clearRect(0, 0, W, H);
  if (values.length < 2) return;
  const mx = maxVal || (Math.max(...values) * 1.1) || 1;
  ctx.strokeStyle = color; ctx.lineWidth = 1.5;
  ctx.beginPath();
  for (let i = 0; i < values.length; i++) {
    const x = (i / (values.length - 1)) * W;
    const y = H - (Math.min(values[i], mx) / mx) * (H - 3) - 1;
    i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
  }
  ctx.stroke();
  // Fill gradient
  ctx.lineTo(W, H); ctx.lineTo(0, H); ctx.closePath();
  const g = ctx.createLinearGradient(0, 0, 0, H);
  g.addColorStop(0, color + '33'); g.addColorStop(1, color + '00');
  ctx.fillStyle = g; ctx.fill();
}

function updateUI() {
  if (_samples.length === 0) return;
  const last = _samples[_samples.length - 1];
  const hasLurek = last.lurekProcessCpu > 0 || last.lurekProcessRamMb > 0;
  const hasGpu = last.gpuPercent !== undefined && last.gpuPercent !== null;

  // Poll status
  document.getElementById('pollDot').className = 'dot active';
  document.getElementById('pollStatus').textContent = 'Polling every 2s  \xB7  ' + _samples.length + ' samples';
  document.getElementById('lurekStatus').textContent = hasLurek ? 'lurek2d: running' : 'lurek2d: not detected';
  document.getElementById('lurekStatus').className = 'badge ' + (hasLurek ? 'run' : 'idle');

  // CPU
  const cpuPct = last.cpuPercent;
  document.getElementById('cpuPct').textContent = cpuPct + '%';
  document.getElementById('cpuPct').style.color = cpuPct > 80 ? '#f44747' : cpuPct > 50 ? '#dcdcaa' : '#4ec9b0';
  drawLine('cpuChart', _samples.map(s => s.cpuPercent), COLOR.cpu, 100);

  // RAM
  const ramPct = last.ramTotalMb ? Math.round(last.ramUsedMb / last.ramTotalMb * 100) : 0;
  document.getElementById('ramPct').textContent = last.ramUsedMb + ' / ' + last.ramTotalMb + ' MB  (' + ramPct + '%)';
  drawLine('ramChart', _samples.map(s => s.ramUsedMb), COLOR.ram);

  // GPU
  if (hasGpu) {
    document.getElementById('gpuContent').innerHTML =
      '<div class="big">' + last.gpuPercent + '%</div><div class="sub">VRAM: ' + (last.gpuVramMb || 0) + ' MB</div>';
    document.getElementById('gpuPct').textContent = last.gpuPercent + '%';
    drawLine('gpuChart', _samples.map(s => s.gpuPercent || 0), COLOR.gpu, 100);
  }

  // Disk
  document.getElementById('diskR').textContent = (last.diskReadKbs || 0);
  document.getElementById('diskW').textContent = (last.diskWriteKbs || 0);
  drawLine('diskChart', _samples.map(s => (s.diskReadKbs||0) + (s.diskWriteKbs||0)), COLOR.diskR);

  // Network
  document.getElementById('netS').textContent = (last.netSentKbs || 0);
  document.getElementById('netR').textContent = (last.netRecvKbs || 0);
  drawLine('netChart', _samples.map(s => (s.netSentKbs||0) + (s.netRecvKbs||0)), COLOR.net);

  // Lurek2D
  document.getElementById('lurekCpu').textContent = last.lurekProcessCpu;
  document.getElementById('lurekRam').textContent = last.lurekProcessRamMb;
  document.getElementById('lurekCpu').style.color = last.lurekProcessCpu > 50 ? '#f44747' : 'inherit';
  drawLine('lurekChart', _samples.map(s => s.lurekProcessCpu), COLOR.lurek, 100);
}

window.addEventListener('resize', updateUI);
window.addEventListener('message', (e) => {
  if (e.data.type === 'data') { _samples = e.data.samples; updateUI(); }
});
</script>
</body>
</html>`}var oe=C(require("vscode")),Mi=C(require("fs")),Si=C(require("path"));async function Yl(){let n=await oe.workspace.findFiles("**/*.lua","{**/node_modules/**,ideas/**,work/**,.github/**}"),e=new Map;for(let t of n){let r;try{r=Mi.readFileSync(t.fsPath,"utf8")}catch{continue}let a=oe.workspace.asRelativePath(t),i=r.split(`
`);for(let s=0;s<i.length;s++){let o=i[s];if(o.trimStart().startsWith("--"))continue;let l=/lurek\.(\w+)\.(\w+)\s*\(/g,p;for(;(p=l.exec(o))!==null;){let u=`lurek.${p[1]}.${p[2]}`;e.has(u)||e.set(u,{func:u,count:0,files:new Set,lines:[]});let d=e.get(u);d.count++,d.files.add(a),d.lines.length<5&&d.lines.push({file:a,line:s+1,text:o.trim()})}}}return Array.from(e.values()).sort((t,r)=>r.count-t.count)}var Ve;async function Ci(n){if(Ve){Ve.reveal(oe.ViewColumn.Two),await Dr();return}Ve=oe.window.createWebviewPanel("lurek.apiUsage","Lurek2D API Usage",oe.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0}),Ve.onDidDispose(()=>{Ve=void 0},null,n.subscriptions),Ve.webview.onDidReceiveMessage(async e=>{if(e.type==="refresh"&&await Dr(),e.type==="open"){let t=oe.Uri.file(Si.join(oe.workspace.workspaceFolders?.[0]?.uri.fsPath??"",e.file));await oe.window.showTextDocument(t,{selection:new oe.Range(e.line-1,0,e.line-1,0)})}},null,n.subscriptions),await Dr()}async function Dr(){if(!Ve)return;Ve.webview.postMessage({type:"loading"});let n=await Yl();Ve.webview.html=Xl(n)}function Xl(n){let e=n.reduce((l,p)=>l+p.count,0),t=n.length,r=n.slice(0,10),a=new Map;for(let l of n){let p=l.func.split(".")[1]??"?";a.has(p)||a.set(p,[]),a.get(p).push(l)}let i=Array.from(a.entries()).sort((l,p)=>p[1].reduce((u,d)=>u+d.count,0)-l[1].reduce((u,d)=>u+d.count,0)).map(([l,p])=>{let u=p.reduce((d,m)=>d+m.count,0);return`<tr><td><code>lurek.${It(l)}</code></td><td>${p.length}</td><td>${u}</td></tr>`}).join(""),s=r.map(l=>{let p=l.lines.map(u=>`<a href="#" data-file="${It(u.file)}" data-line="${u.line}" class="loc">${It(u.file)}:${u.line}</a>`).join(", ");return`<tr>
      <td><code>${It(l.func)}</code></td>
      <td>${l.count}</td>
      <td>${l.files.size}</td>
      <td style="font-size:11px;opacity:.7">${p}</td>
    </tr>`}).join(""),o=n.filter(l=>l.count===0).map(l=>`<tr><td><code>${It(l.func)}</code></td></tr>`).join("");return`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline';">
<style>
  body { font-family: var(--vscode-font-family); color: var(--vscode-foreground); background: var(--vscode-editor-background); padding: 12px; margin: 0; }
  h2 { margin: 0 0 10px; font-size: 14px; }
  h3 { font-size: 12px; text-transform: uppercase; letter-spacing: .05em; opacity: 0.6; margin: 16px 0 6px; }
  .stats { display: flex; gap: 20px; margin-bottom: 16px; flex-wrap: wrap; }
  .stat { background: var(--vscode-editorWidget-background); border-radius: 4px; padding: 8px 16px; text-align: center; }
  .stat-val { font-size: 24px; font-weight: 700; color: var(--vscode-charts-blue, #569cd6); }
  .stat-lbl { font-size: 11px; opacity: 0.7; }
  table { width: 100%; border-collapse: collapse; font-size: 13px; margin-bottom: 16px; }
  th { text-align: left; padding: 4px 8px; border-bottom: 1px solid var(--vscode-panel-border); font-size: 11px; opacity: 0.6; }
  td { padding: 4px 8px; border-bottom: 1px solid var(--vscode-panel-border, rgba(255,255,255,0.05)); }
  code { font-family: var(--vscode-editor-font-family); color: #9cdcfe; }
  a.loc { color: var(--vscode-textLink-foreground); text-decoration: none; font-family: var(--vscode-editor-font-family); font-size: 11px; }
  a.loc:hover { text-decoration: underline; }
  button { background: var(--vscode-button-background); color: var(--vscode-button-foreground); border: none; padding: 4px 10px; border-radius: 3px; cursor: pointer; font-size: 12px; margin-bottom: 10px; }
</style>
</head>
<body>
<h2>\u{1F4CA} Lurek2D API Usage Report</h2>
<button onclick="vscode.postMessage({type:'refresh'})">\u27F3 Re-scan</button>

<div class="stats">
  <div class="stat"><div class="stat-val">${e}</div><div class="stat-lbl">Total Calls</div></div>
  <div class="stat"><div class="stat-val">${t}</div><div class="stat-lbl">Unique Functions</div></div>
  <div class="stat"><div class="stat-val">${a.size}</div><div class="stat-lbl">Modules Used</div></div>
</div>

<h3>By Module</h3>
<table>
  <thead><tr><th>Module</th><th>Functions</th><th>Total Calls</th></tr></thead>
  <tbody>${i}</tbody>
</table>

<h3>Top 10 Most Called</h3>
<table>
  <thead><tr><th>Function</th><th>Calls</th><th>Files</th><th>Locations</th></tr></thead>
  <tbody>${s}</tbody>
</table>

${o?`<h3>Called 0 times</h3><table><thead><tr><th>Function</th></tr></thead><tbody>${o}</tbody></table>`:""}

<script>
const vscode = acquireVsCodeApi();
document.querySelectorAll('a.loc').forEach(a => {
  a.addEventListener('click', e => {
    e.preventDefault();
    vscode.postMessage({ type: 'open', file: a.dataset.file, line: parseInt(a.dataset.line) });
  });
});
</script>
</body>
</html>`}function It(n){return n.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;")}async function ji(n){let e=oe.window.activeTextEditor;if(!e){oe.window.showWarningMessage("Open a Lua file first.");return}let t=n.getAllFunctions(),r=t.filter(o=>o.fullPath.startsWith("lurek.")).map(o=>({label:o.fullPath,description:o.description??"",detail:o.parameters?.map(l=>`${l.name}: ${l.type}`).join(", ")})),a=await oe.window.showQuickPick(r,{placeHolder:"Search lurek.* function to insert\u2026",matchOnDescription:!0,matchOnDetail:!0});if(!a)return;let i=t.find(o=>o.fullPath===a.label);if(!i)return;let s=i.fullPath+"(";if(i.parameters?.length){let o=i.parameters.filter(l=>!l.optional).map((l,p)=>`\${${p+1}:${l.name}}`).join(", ");s+=o}s+=")$0",e.insertSnippet(new oe.SnippetString(s))}var de=C(require("vscode")),Dt=C(require("path")),un=C(require("fs"));async function Ar(n){let e=_r();if(!e){de.window.showErrorMessage("No workspace folder open.");return}let t=de.workspace.getConfiguration("lurek").get("srcDir",""),r=t?Dt.join(e,t):e;try{await n.run(r)}catch(a){let i=a instanceof Error?a.message:String(a);de.window.showErrorMessage(`Failed to run Lurek2D: ${i}`)}}function Ri(n){if(!n.isRunning()){de.window.showInformationMessage("No Lurek2D game is running.");return}n.stop(),de.window.showInformationMessage("Lurek2D game stopped.")}async function Ei(n){let e=await de.window.showInputBox({prompt:"Enter arguments for Lurek2D",placeHolder:"e.g. --debug --fps-cap 60"});if(e===void 0)return;let t=_r();if(!t){de.window.showErrorMessage("No workspace folder open.");return}let r=de.workspace.getConfiguration("lurek").get("srcDir",""),a=r?Dt.join(t,r):t;try{await n.run(a,e.split(/\s+/).filter(Boolean))}catch(i){let s=i instanceof Error?i.message:String(i);de.window.showErrorMessage(`Failed to run Lurek2D: ${s}`)}}async function dn(n){let e=_r();if(!e){de.window.showErrorMessage("No workspace folder open.");return}let t=Dt.join(e,"content","games","showcase");if(!un.existsSync(t)){de.window.showWarningMessage("No content/games/showcase/ directory found.");return}let r=un.readdirSync(t,{withFileTypes:!0}).filter(i=>i.isDirectory()).map(i=>i.name);if(r.length===0){de.window.showWarningMessage("No examples found.");return}let a=await de.window.showQuickPick(r,{placeHolder:"Select a demo to run"});if(a)try{await n.run(Dt.join(t,a))}catch(i){let s=i instanceof Error?i.message:String(i);de.window.showErrorMessage(`Failed to run example: ${s}`)}}function _r(){return de.workspace.workspaceFolders?.[0]?.uri.fsPath}var fe=C(require("vscode")),Br=C(require("path")),yt=C(require("fs")),Li=[{label:"Minimal",description:"Empty main.lua with gameloop stubs",files:{"main.lua":["function lurek.load()","end","","function lurek.update(dt)","end","","function lurek.draw()","end",""].join(`
`),"conf.lua":["function lurek.conf(t)",'  t.window.title = "My Game"',"  t.window.width = 800","  t.window.height = 600","end"].join(`
`)}},{label:"Game Loop",description:"Full game loop with player movement",files:{"main.lua":["local x, y = 400, 300","local speed = 200","","function lurek.load()",'  lurek.window.setTitle("Game Loop Demo")',"end","","function lurek.update(dt)",'  if lurek.input.keyboard.isDown("left") then x = x - speed * dt end','  if lurek.input.keyboard.isDown("right") then x = x + speed * dt end','  if lurek.input.keyboard.isDown("up") then y = y - speed * dt end','  if lurek.input.keyboard.isDown("down") then y = y + speed * dt end',"end","","function lurek.draw()","  lurek.graphics.clear(0.1, 0.1, 0.2)","  lurek.graphics.setColor(1, 1, 1)",'  lurek.graphics.circle("fill", x, y, 20)',"end",""].join(`
`),"conf.lua":["function lurek.conf(t)",'  t.window.title = "Game Loop Demo"',"  t.window.width = 800","  t.window.height = 600","end"].join(`
`)}},{label:"Physics",description:"Physics world with falling objects",files:{"main.lua":["local world","local ground, ball","","function lurek.load()","  world = lurek.physics.newWorld(0, 981)",'  ground = lurek.physics.newBody(world, 400, 580, "static")',"  lurek.physics.newRectangleShape(ground, 800, 40)",'  ball = lurek.physics.newBody(world, 400, 100, "dynamic")',"  lurek.physics.newCircleShape(ball, 20)","end","","function lurek.update(dt)","  world:update(dt)","end","","function lurek.draw()","  lurek.graphics.clear(0.1, 0.1, 0.2)","  lurek.graphics.setColor(0.3, 0.3, 0.3)",'  lurek.graphics.rectangle("fill", 0, 560, 800, 40)',"  lurek.graphics.setColor(1, 0.3, 0.3)","  local bx, by = ball:getPosition()",'  lurek.graphics.circle("fill", bx, by, 20)',"end",""].join(`
`),"conf.lua":["function lurek.conf(t)",'  t.window.title = "Physics Demo"',"  t.window.width = 800","  t.window.height = 600","end"].join(`
`)}},{label:"Platformer",description:"Simple platformer with gravity and jumping",files:{"main.lua":["local player = { x = 100, y = 400, vy = 0, w = 32, h = 48, onGround = false }","local gravity = 900","local jumpForce = -400","local moveSpeed = 200","local groundY = 500","","function lurek.update(dt)","  -- Horizontal movement",'  if lurek.input.keyboard.isDown("left") then player.x = player.x - moveSpeed * dt end','  if lurek.input.keyboard.isDown("right") then player.x = player.x + moveSpeed * dt end',"","  -- Gravity","  player.vy = player.vy + gravity * dt","  player.y = player.y + player.vy * dt","","  -- Ground collision","  if player.y + player.h >= groundY then","    player.y = groundY - player.h","    player.vy = 0","    player.onGround = true","  else","    player.onGround = false","  end","end","","function lurek.keypressed(key)",'  if key == "space" and player.onGround then',"    player.vy = jumpForce","  end","end","","function lurek.draw()","  lurek.graphics.clear(0.2, 0.3, 0.4)","  lurek.graphics.setColor(0.4, 0.4, 0.4)",'  lurek.graphics.rectangle("fill", 0, groundY, 800, 100)',"  lurek.graphics.setColor(0.2, 0.8, 0.4)",'  lurek.graphics.rectangle("fill", player.x, player.y, player.w, player.h)',"end",""].join(`
`),"conf.lua":["function lurek.conf(t)",'  t.window.title = "Platformer"',"  t.window.width = 800","  t.window.height = 600","end"].join(`
`)}},{label:"Top-Down",description:"Top-down view with WASD movement",files:{"main.lua":["local player = { x = 400, y = 300, speed = 200, size = 16 }","","function lurek.update(dt)",'  if lurek.input.keyboard.isDown("w") then player.y = player.y - player.speed * dt end','  if lurek.input.keyboard.isDown("s") then player.y = player.y + player.speed * dt end','  if lurek.input.keyboard.isDown("a") then player.x = player.x - player.speed * dt end','  if lurek.input.keyboard.isDown("d") then player.x = player.x + player.speed * dt end',"end","","function lurek.draw()","  lurek.graphics.clear(0.15, 0.15, 0.2)","  lurek.graphics.setColor(0.3, 0.7, 1)",'  lurek.graphics.rectangle("fill", player.x - player.size/2, player.y - player.size/2, player.size, player.size)',"end",""].join(`
`),"conf.lua":["function lurek.conf(t)",'  t.window.title = "Top-Down"',"  t.window.width = 800","  t.window.height = 600","end"].join(`
`)}},{label:"ECS",description:"Entity Component System with lurek.ecs",files:{"main.lua":["local universe","","function lurek.load()","  universe = lurek.ecs.newUniverse()","","  for i = 1, 10 do","    local e = universe:spawn()",'    e:set("position", { x = math.random(50, 750), y = math.random(50, 550) })','    e:set("velocity", { x = math.random(-100, 100), y = math.random(-100, 100) })','    e:set("radius", math.random(5, 20))',"  end","end","","function lurek.update(dt)",'  for _, e in universe:query("position", "velocity") do','    local pos = e:get("position")','    local vel = e:get("velocity")',"    pos.x = pos.x + vel.x * dt","    pos.y = pos.y + vel.y * dt","    if pos.x < 0 or pos.x > 800 then vel.x = -vel.x end","    if pos.y < 0 or pos.y > 600 then vel.y = -vel.y end","  end","end","","function lurek.draw()","  lurek.graphics.clear(0.1, 0.1, 0.15)",'  for _, e in universe:query("position", "radius") do','    local pos = e:get("position")','    local r = e:get("radius")',"    lurek.graphics.setColor(0.4, 0.8, 1)",'    lurek.graphics.circle("fill", pos.x, pos.y, r)',"  end","end",""].join(`
`),"conf.lua":["function lurek.conf(t)",'  t.window.title = "ECS Demo"',"  t.window.width = 800","  t.window.height = 600","end"].join(`
`)}}],Ii={"main.lua":`function lurek.load()
end

function lurek.update(dt)
end

function lurek.draw()
end
`,"conf.lua":`function lurek.conf(t)
  t.window.title = "My Game"
  t.window.width = 800
  t.window.height = 600
end
`,"class.lua":`local MyClass = {}
MyClass.__index = MyClass

function MyClass.new()
  return setmetatable({}, MyClass)
end

function MyClass:update(dt)
end

function MyClass:draw()
end

return MyClass
`,"scene.lua":`local Scene = {}
Scene.__index = Scene

function Scene.new()
  return setmetatable({}, Scene)
end

function Scene:enter()
end

function Scene:update(dt)
end

function Scene:draw()
end

function Scene:leave()
end

return Scene
`};async function Di(){let n=Li.map(s=>({label:s.label,description:s.description})),e=await fe.window.showQuickPick(n,{placeHolder:"Select a project template"});if(!e)return;let t=await fe.window.showOpenDialog({canSelectFolders:!0,canSelectFiles:!1,canSelectMany:!1,openLabel:"Select Project Folder"});if(!t||t.length===0)return;let r=t[0].fsPath,a=Li.find(s=>s.label===e.label);if(!a)return;for(let[s,o]of Object.entries(a.files)){let l=Br.join(r,s);yt.existsSync(l)||yt.writeFileSync(l,o,"utf-8")}let i=fe.Uri.file(r);await fe.commands.executeCommand("vscode.openFolder",i)}async function Ai(){let n=Object.keys(Ii),e=await fe.window.showQuickPick(n,{placeHolder:"Select a file template"});if(!e)return;let t=fe.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!t){fe.window.showErrorMessage("No workspace folder open.");return}let r=await fe.window.showInputBox({prompt:"Enter file name",value:e});if(!r)return;let a=Br.join(t,r);if(yt.existsSync(a)){fe.window.showWarningMessage(`File already exists: ${r}`);return}yt.writeFileSync(a,Ii[e],"utf-8");let i=await fe.workspace.openTextDocument(a);await fe.window.showTextDocument(i)}var cn=C(require("vscode"));gt();function _i(){let n=mn("Lurek2D Tests");n.show(),n.sendText($t())}function Bi(n){let e=mn("Lurek2D Tests");e.show(),e.sendText(mt(n))}function Fi(){let n=mn("Lurek2D Tests");n.show(),n.sendText(xt())}function zi(){let n=mn("Lurek2D Tests");n.show(),n.sendText(mt("golden_tests"))}function mn(n){let e=cn.window.terminals.find(t=>t.name===n);return e||cn.window.createTerminal(n)}var Fr=C(require("vscode"));function Ni(){let n=zr("Lurek2D Package");n.show(),process.platform==="win32"?n.sendText("powershell -ExecutionPolicy Bypass -File tools/dist.ps1"):n.sendText("bash tools/dist.sh")}function Oi(){let n=zr("Lurek2D Package");n.show(),n.sendText("powershell -ExecutionPolicy Bypass -File tools/dist.ps1")}function Wi(){let n=zr("Lurek2D Package");n.show(),n.sendText("bash tools/dist.sh")}function zr(n){let e=Fr.window.terminals.find(t=>t.name===n);return e||Fr.window.createTerminal(n)}var Gi=C(require("vscode"));var le=C(require("vscode"));function L(){let n="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",e="";for(let t=0;t<32;t++)e+=n.charAt(Math.floor(Math.random()*n.length));return e}var c={save:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M13.354 1.146l1.5 1.5A.5.5 0 0115 3v11a1 1 0 01-1 1H2a1 1 0 01-1-1V2a1 1 0 011-1h10.5a.5.5 0 01.354.146zM4 2H2v12h1V9.5A.5.5 0 013.5 9h9a.5.5 0 01.5.5V14h1V3.207l-1-1V5.5A.5.5 0 0112.5 6h-7A.5.5 0 015 5.5V2H4zm9 12v-4H4v4h9zM6 2v3h6V2H6z"/></svg>',undo:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M5.5 7H2v3h1V8.414l1.243 1.243a5.5 5.5 0 117.514 0l-.707-.707a4.5 4.5 0 10-6.172 0L6.5 10.414V7h-1z"/></svg>',redo:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M10.5 7H14v3h-1V8.414l-1.243 1.243a5.5 5.5 0 11-7.514 0l.707-.707a4.5 4.5 0 106.172 0L9.5 10.414V7h1z"/></svg>',exportFile:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M8 1l4 4h-3v5H7V5H4l4-4zM2 12h12v2H2v-2z"/></svg>',importFile:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M8 10L4 6h3V1h2v5h3l-4 4zM2 12h12v2H2v-2z"/></svg>',copy:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M4 4h8v10H4V4zm1 1v8h6V5H5zM2 2h8v1H3v9H2V2z"/></svg>',insert:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M7 2h2v5h5v2H9v5H7V9H2V7h5V2z"/></svg>',play:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M4 2l10 6-10 6V2z"/></svg>',stop:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><rect x="3" y="3" width="10" height="10" rx="1"/></svg>',refresh:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M13 3a7 7 0 00-10.95 1.7L3.5 6H1v-2.5l1.12 1.12A8 8 0 0114 3.07V3zM3 13a7 7 0 0010.95-1.7L12.5 10H15v2.5l-1.12-1.12A8 8 0 012 12.93V13z"/></svg>',trash:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M5.5 1h5l.5.5V3h4v1h-1v10l-.5.5h-11L2 14V4H1V3h4V1.5l.5-.5zM6 2v1h4V2H6zM3 4v10h10V4H3zm2 2h1v7H5V6zm3 0h1v7H8V6zm3 0h1v7h-1V6z"/></svg>',zoomIn:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M7 1a6 6 0 014.472 10.058l3.235 3.235-.707.707-3.235-3.235A6 6 0 117 1zm0 1a5 5 0 100 10A5 5 0 007 2zm.5 2v2.5H10v1H7.5V10h-1V7.5H4v-1h2.5V4h1z"/></svg>',zoomOut:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M7 1a6 6 0 014.472 10.058l3.235 3.235-.707.707-3.235-3.235A6 6 0 117 1zm0 1a5 5 0 100 10A5 5 0 007 2zm3 4v1H4v-1h6z"/></svg>',settings:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M9.1 2L9 1H7l-.1 1-.9.4-.7-.7-1.4 1.4.7.7-.4.9-1 .1V6l1 .1.4.9-.7.7 1.4 1.4.7-.7.9.4.1 1h2l.1-1 .9-.4.7.7 1.4-1.4-.7-.7.4-.9 1-.1V4l-1-.1-.4-.9.7-.7-1.4-1.4-.7.7-.9-.4zM8 6a2 2 0 110 4 2 2 0 010-4z"/></svg>',grid:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M1 1h4v4H1V1zm5 0h4v4H6V1zm5 0h4v4h-4V1zM1 6h4v4H1V6zm5 0h4v4H6V6zm5 0h4v4h-4V6zM1 11h4v4H1v-4zm5 0h4v4H6v-4zm5 0h4v4h-4v-4z"/></svg>',eye:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M8 3C4.36 3 1.26 5.28 0 8.5c1.26 3.22 4.36 5.5 8 5.5s6.74-2.28 8-5.5C14.74 5.28 11.64 3 8 3zm0 9a3.5 3.5 0 110-7 3.5 3.5 0 010 7zm0-5.5a2 2 0 100 4 2 2 0 000-4z"/></svg>',eyeOff:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M1.5 1.1l13.4 13.4-.7.7L.8 1.8l.7-.7zM8 3c3.64 0 6.74 2.28 8 5.5a9.77 9.77 0 01-2.43 3.53l-.71-.71A8.77 8.77 0 0015 8.5C13.82 5.7 11.11 4 8 4c-.82 0-1.62.12-2.37.34l-.8-.8C5.7 3.19 6.83 3 8 3zM1 8.5C2.18 11.3 4.89 13 8 13c.82 0 1.62-.12 2.37-.34l.8.8C10.3 13.81 9.17 14 8 14c-3.64 0-6.74-2.28-8-5.5.44-1.13 1.08-2.14 1.87-2.97l.71.71A8.77 8.77 0 001 8.5z"/></svg>',lock:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M4 7V5a4 4 0 118 0v2h1v7H3V7h1zm1-2a3 3 0 116 0v2H5V5zm-1 3v5h8V8H4z"/></svg>',unlock:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M11 1a4 4 0 00-4 4v2H3v7h10V7H8V5a3 3 0 016 0v1h1V5a4 4 0 00-4-4zM4 8h8v5H4V8z"/></svg>',add:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M7 2h2v5h5v2H9v5H7V9H2V7h5V2z"/></svg>',remove:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M2 7h12v2H2V7z"/></svg>',moveUp:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M8 3l5 5h-3v5H6V8H3l5-5z"/></svg>',moveDown:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M8 13l-5-5h3V3h4v5h3l-5 5z"/></svg>',pen:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M13.23.71a1 1 0 00-1.41 0L10 2.54l3 3 1.83-1.83a1 1 0 000-1.41l-1.6-1.6zM9.13 3.4L2 10.54V13.5h2.96l7.13-7.14-3-2.96z"/></svg>',eraser:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M8.09 2L14 7.91l-5.5 5.5-1.5.59H2v-1l.59-1.5L8.09 2zM3.5 13h3.09l5-5L8.5 4.91l-5 5V13z"/></svg>',bucket:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M6 1l7 7-4.5 4.5L2 6l4-5zm.5 1.71L3.71 6 9 11.29l3.29-3.29L6.5 2.71zM12 10s2 2.5 2 3.5a2 2 0 01-4 0c0-1 2-3.5 2-3.5z"/></svg>',rect:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M1 3h14v10H1V3zm1 1v8h12V4H2z"/></svg>',line:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M13.5 2.5l.7.7-11.3 11.3-.7-.7L13.5 2.5z"/></svg>',select:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M2 2h4v1H3v3H2V2zm8 0h4v4h-1V3h-3V2zM2 10h1v3h3v1H2v-4zm11 0h1v4h-4v-1h3v-3z" opacity=".7"/><rect x="1" y="1" width="14" height="14" fill="none" stroke="currentColor" stroke-dasharray="2 2"/></svg>',pick:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M7 1a6 6 0 014.47 10.06l3.24 3.23-.71.71-3.23-3.24A6 6 0 117 1zm0 1a5 5 0 100 10A5 5 0 007 2z"/></svg>',hand:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M8 1a2 2 0 012 2v3a2 2 0 012 2v1a2 2 0 012 2v1c0 2.21-1.79 4-4 4H8c-2.21 0-4-1.79-4-4V5a2 2 0 014 0V3a2 2 0 012-2zm1 2a1 1 0 10-2 0v5h-1V5a1 1 0 10-2 0v7c0 1.66 1.34 3 3 3h2c1.66 0 3-1.34 3-3v-1a1 1 0 10-2 0v-1h-1V8a1 1 0 10-2 0V6h-1V3a1 1 0 011-1z"/></svg>',stamp:'<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M6 1h4v4h2l-1 4H5L4 5h2V1zm-4 10h12v1H2v-1zm0 3h12v1H2v-1z"/></svg>',dirty:'<svg width="10" height="10" viewBox="0 0 10 10"><circle cx="5" cy="5" r="4" fill="#e2b340"/></svg>',clean:'<svg width="10" height="10" viewBox="0 0 10 10"><circle cx="5" cy="5" r="4" fill="#4caf50"/></svg>'};function Ql(){return`
    /* \u2500\u2500 Reset & Theme \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    :root {
      /* Map to VS Code theme tokens with game-editor fallbacks */
      --bg:        var(--vscode-editor-background, #1e1e2e);
      --surface:   var(--vscode-sideBar-background, #232334);
      --surface-2: var(--vscode-editorGroupHeader-tabsBackground, #2a2a3d);
      --surface-3: #31314a;
      --border:    var(--vscode-panel-border, #3c3c5c);
      --text:      var(--vscode-editor-foreground, #cdd6f4);
      --text-dim:  var(--vscode-descriptionForeground, #7f849c);
      --text-bright: #ffffff;
      --accent:    var(--vscode-focusBorder, #89b4fa);
      --accent-2:  #a6e3a1;
      --accent-dim: rgba(137,180,250,0.15);
      --success:   #a6e3a1;
      --warning:   #f9e2af;
      --danger:    #f38ba8;
      --selection: var(--vscode-editor-selectionBackground, #2a4070);
      --hover:     rgba(255,255,255,0.04);
      --radius:    4px;
      --radius-lg: 6px;
      --font-mono: var(--vscode-editor-font-family, 'Cascadia Code', 'Fira Code', 'Consolas', monospace);
      --font-ui:   var(--vscode-font-family, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif);
      --z-toolbar: 100;
      --z-dropdown: 200;
      --z-modal:   300;
      --z-toast:   400;
    }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: var(--font-ui);
      font-size: 12px;
      color: var(--text); background: var(--bg);
      overflow: hidden; height: 100vh;
      -webkit-font-smoothing: antialiased;
    }

    /* \u2500\u2500 Typography \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    h1 { font-size: 16px; font-weight: 600; color: var(--text-bright); }
    h2 { font-size: 13px; font-weight: 600; color: var(--text); }
    h3 { font-size: 11px; font-weight: 600; text-transform: uppercase; color: var(--text-dim); letter-spacing: 0.8px; }
    code, .mono { font-family: var(--font-mono); font-size: 11px; }

    /* \u2500\u2500 Buttons \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    button, .btn {
      display: inline-flex; align-items: center; justify-content: center; gap: 4px;
      background: var(--surface-2); color: var(--text); border: 1px solid var(--border);
      padding: 4px 10px; border-radius: var(--radius); cursor: pointer; font-size: 11px;
      font-family: var(--font-ui); transition: all 0.12s ease; user-select: none;
      line-height: 1.4; white-space: nowrap;
    }
    button:hover { background: var(--surface-3); border-color: var(--accent); color: var(--text-bright); }
    button:active { transform: scale(0.97); }
    button.active, button[aria-pressed="true"] {
      background: var(--accent); border-color: var(--accent); color: var(--bg);
    }
    button:disabled { opacity: 0.4; cursor: not-allowed; pointer-events: none; }
    button.primary { background: var(--accent); border-color: var(--accent); color: var(--bg); font-weight: 600; }
    button.primary:hover { filter: brightness(1.15); }
    button.danger { border-color: var(--danger); color: var(--danger); }
    button.danger:hover { background: var(--danger); color: var(--bg); }
    button.ghost { background: transparent; border-color: transparent; }
    button.ghost:hover { background: var(--hover); border-color: transparent; }
    button svg { width: 14px; height: 14px; flex-shrink: 0; }

    /* \u2500\u2500 Icon Button (square, toolbar-style) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    .icon-btn {
      width: 28px; height: 28px; padding: 0; display: flex;
      align-items: center; justify-content: center;
      background: transparent; border: 1px solid transparent;
      border-radius: var(--radius); cursor: pointer; color: var(--text-dim);
      transition: all 0.12s ease;
    }
    .icon-btn:hover { background: var(--surface-3); color: var(--text-bright); border-color: var(--border); }
    .icon-btn.active, .icon-btn[aria-pressed="true"] {
      background: var(--accent); color: var(--bg); border-color: var(--accent);
    }
    .icon-btn svg { width: 16px; height: 16px; }
    .icon-btn[title]::after { content: none; }

    /* \u2500\u2500 Form Controls \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    input, select, textarea {
      background: var(--surface); color: var(--text); border: 1px solid var(--border);
      padding: 4px 8px; border-radius: var(--radius); font-size: 12px;
      font-family: var(--font-ui); transition: border-color 0.12s ease;
    }
    input:focus, select:focus, textarea:focus {
      outline: none; border-color: var(--accent); box-shadow: 0 0 0 1px var(--accent-dim);
    }
    input[type="range"] {
      -webkit-appearance: none; height: 4px; background: var(--border);
      border-radius: 2px; border: none; padding: 0;
    }
    input[type="range"]::-webkit-slider-thumb {
      -webkit-appearance: none; width: 14px; height: 14px;
      background: var(--accent); border-radius: 50%; cursor: pointer;
      border: 2px solid var(--bg);
    }
    input[type="checkbox"] {
      appearance: none; width: 14px; height: 14px; border: 1px solid var(--border);
      border-radius: 3px; background: var(--surface); cursor: pointer;
      display: inline-flex; align-items: center; justify-content: center;
      padding: 0; vertical-align: middle;
    }
    input[type="checkbox"]:checked {
      background: var(--accent); border-color: var(--accent);
    }
    input[type="checkbox"]:checked::after {
      content: ''; display: block; width: 8px; height: 5px;
      border-left: 2px solid var(--bg); border-bottom: 2px solid var(--bg);
      transform: rotate(-45deg) translateY(-1px);
    }
    input[type="number"] { width: 60px; text-align: center; }
    select { padding-right: 20px; cursor: pointer; }
    label {
      font-size: 11px; color: var(--text-dim); user-select: none;
      display: inline-flex; align-items: center; gap: 4px;
    }
    textarea { font-family: var(--font-mono); resize: vertical; }

    /* \u2500\u2500 Toolbar (Godot-style top bar) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    .toolbar {
      display: flex; align-items: center; gap: 4px; padding: 4px 8px;
      background: var(--surface); border-bottom: 1px solid var(--border);
      z-index: var(--z-toolbar); flex-shrink: 0; min-height: 36px;
    }
    .toolbar .group {
      display: flex; align-items: center; gap: 2px;
      padding: 0 2px;
    }
    .toolbar .sep {
      width: 1px; height: 20px; background: var(--border); margin: 0 4px; flex-shrink: 0;
    }
    .toolbar .spacer { flex: 1; }
    .toolbar label { margin: 0 2px 0 4px; }

    /* \u2500\u2500 Tool Sidebar (Godot-style left rail) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    .tool-rail {
      display: flex; flex-direction: column; align-items: center;
      padding: 4px 2px; gap: 2px; background: var(--surface);
      border-right: 1px solid var(--border); overflow-y: auto;
      width: 38px; flex-shrink: 0;
    }
    .tool-rail .tool-group {
      display: flex; flex-direction: column; gap: 1px; width: 100%;
      padding: 2px 0;
    }
    .tool-rail .tool-group + .tool-group {
      border-top: 1px solid var(--border); padding-top: 4px; margin-top: 2px;
    }
    .tool-rail .icon-btn { width: 32px; height: 32px; border-radius: var(--radius); }
    .tool-rail .icon-btn svg { width: 16px; height: 16px; }

    /* \u2500\u2500 Panel (Godot-style properties dock) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    .panel {
      background: var(--surface); border-right: 1px solid var(--border);
      overflow-y: auto; padding: 0; flex-shrink: 0;
    }
    .panel-section {
      border-bottom: 1px solid var(--border);
    }
    .panel-header {
      display: flex; align-items: center; justify-content: space-between;
      padding: 6px 10px; cursor: pointer; user-select: none;
      background: var(--surface-2); transition: background 0.12s;
    }
    .panel-header:hover { background: var(--surface-3); }
    .panel-header h3 { margin: 0; pointer-events: none; }
    .panel-header .toggle-icon {
      width: 14px; color: var(--text-dim); transition: transform 0.15s ease;
    }
    .panel-header .toggle-icon.collapsed { transform: rotate(-90deg); }
    .panel-body { padding: 8px 10px; }
    .panel-body.collapsed { display: none; }

    /* \u2500\u2500 Collapsible section helper \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    .section { margin-bottom: 8px; }
    .section-title {
      font-size: 11px; text-transform: uppercase; color: var(--text-dim);
      letter-spacing: 0.5px; margin-bottom: 6px; display: flex;
      align-items: center; gap: 4px; cursor: default;
    }

    /* \u2500\u2500 Property Fields (Godot inspector style) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    .field { display: flex; flex-direction: column; gap: 2px; margin-bottom: 6px; }
    .field > label { font-size: 10px; text-transform: uppercase; letter-spacing: 0.5px; }
    .field-row {
      display: flex; align-items: center; gap: 6px; margin-bottom: 4px;
    }
    .field-row > label { min-width: 70px; text-align: right; flex-shrink: 0; }
    .field-row > input, .field-row > select { flex: 1; }
    .field-inline {
      display: grid; grid-template-columns: 80px 1fr; gap: 4px; align-items: center;
      margin-bottom: 4px; font-size: 12px;
    }
    .field-inline > label { text-align: right; color: var(--text-dim); font-size: 11px; }

    /* \u2500\u2500 List Items \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    .list-item {
      padding: 4px 8px; cursor: pointer; border-radius: var(--radius); font-size: 12px;
      display: flex; align-items: center; gap: 6px; transition: background 0.08s;
    }
    .list-item:hover { background: var(--hover); }
    .list-item.selected { background: var(--selection); }
    .list-item .item-icon { width: 14px; height: 14px; color: var(--text-dim); flex-shrink: 0; }
    .list-item .item-label { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .list-item .item-badge {
      font-size: 10px; padding: 1px 5px; border-radius: 8px;
      background: var(--surface-2); color: var(--text-dim);
    }

    /* \u2500\u2500 Tabs (Godot-style docked tabs) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    .tabs {
      display: flex; gap: 0; border-bottom: 1px solid var(--border);
      background: var(--surface); padding: 0 4px; flex-shrink: 0;
    }
    .tab {
      padding: 6px 14px; font-size: 11px; cursor: pointer; border: none;
      background: transparent; color: var(--text-dim); position: relative;
      transition: color 0.12s; user-select: none; white-space: nowrap;
      border-radius: 0;
    }
    .tab:hover { color: var(--text); background: var(--hover); }
    .tab.active {
      color: var(--accent); font-weight: 600;
    }
    .tab.active::after {
      content: ''; position: absolute; bottom: -1px; left: 4px; right: 4px;
      height: 2px; background: var(--accent); border-radius: 1px;
    }

    /* \u2500\u2500 Status Bar (Godot-style bottom info strip) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    .status-bar {
      display: flex; align-items: center; gap: 8px; padding: 3px 10px;
      background: var(--surface); border-top: 1px solid var(--border);
      font-size: 11px; color: var(--text-dim); flex-shrink: 0;
      min-height: 24px; z-index: var(--z-toolbar);
    }
    .status-bar .spacer { flex: 1; }
    .status-bar .status-group {
      display: flex; align-items: center; gap: 4px;
    }
    .status-bar .sep { width: 1px; height: 14px; background: var(--border); }
    .status-bar .badge {
      font-size: 10px; padding: 1px 6px; border-radius: 8px;
      background: var(--accent-dim); color: var(--accent);
    }
    .status-bar .badge.warn { background: rgba(249,226,175,0.15); color: var(--warning); }
    .status-bar .badge.error { background: rgba(243,139,168,0.15); color: var(--danger); }
    .status-bar .badge.ok { background: rgba(166,227,161,0.15); color: var(--success); }

    /* \u2500\u2500 Toast Notifications \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    .toast-container {
      position: fixed; bottom: 32px; right: 12px; z-index: var(--z-toast);
      display: flex; flex-direction: column-reverse; gap: 4px;
    }
    .toast {
      padding: 8px 14px; border-radius: var(--radius-lg);
      font-size: 12px; color: var(--text-bright);
      background: var(--surface-3); border: 1px solid var(--border);
      box-shadow: 0 4px 16px rgba(0,0,0,0.3);
      animation: toastIn 0.2s ease; max-width: 320px;
    }
    .toast.info { border-left: 3px solid var(--accent); }
    .toast.success { border-left: 3px solid var(--success); }
    .toast.warn { border-left: 3px solid var(--warning); }
    .toast.error { border-left: 3px solid var(--danger); }
    @keyframes toastIn { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: translateY(0); } }

    /* \u2500\u2500 Modal / Dialog \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    .modal-overlay {
      position: fixed; inset: 0; background: rgba(0,0,0,0.5);
      z-index: var(--z-modal); display: flex; align-items: center; justify-content: center;
    }
    .modal {
      background: var(--surface); border: 1px solid var(--border);
      border-radius: var(--radius-lg); padding: 16px; min-width: 320px; max-width: 500px;
      box-shadow: 0 8px 32px rgba(0,0,0,0.4);
    }
    .modal h2 { margin-bottom: 12px; }
    .modal-actions { display: flex; gap: 8px; justify-content: flex-end; margin-top: 16px; }

    /* \u2500\u2500 Context Menu \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    .context-menu {
      position: fixed; z-index: var(--z-dropdown); background: var(--surface);
      border: 1px solid var(--border); border-radius: var(--radius);
      padding: 4px 0; min-width: 160px; box-shadow: 0 4px 16px rgba(0,0,0,0.3);
    }
    .context-menu-item {
      padding: 5px 12px; font-size: 12px; cursor: pointer; display: flex;
      align-items: center; gap: 8px; transition: background 0.08s;
    }
    .context-menu-item:hover { background: var(--accent); color: var(--bg); }
    .context-menu-item.disabled { opacity: 0.4; pointer-events: none; }
    .context-menu-sep { height: 1px; background: var(--border); margin: 4px 0; }

    /* \u2500\u2500 Drag Handles \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    .drag-handle { cursor: grab; color: var(--text-dim); }
    .drag-handle:active { cursor: grabbing; }

    /* \u2500\u2500 Canvas Area \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    .canvas-area {
      position: relative; overflow: hidden; background: var(--bg);
      flex: 1; display: flex; align-items: center; justify-content: center;
    }
    .canvas-area canvas { display: block; image-rendering: pixelated; }

    /* \u2500\u2500 Splitter / Resize Handle \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    .splitter-h {
      width: 3px; cursor: col-resize; background: transparent;
      transition: background 0.15s; flex-shrink: 0;
    }
    .splitter-h:hover, .splitter-h.dragging { background: var(--accent); }
    .splitter-v {
      height: 3px; cursor: row-resize; background: transparent;
      transition: background 0.15s; flex-shrink: 0;
    }
    .splitter-v:hover, .splitter-v.dragging { background: var(--accent); }

    /* \u2500\u2500 Scrollbar Styling \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    ::-webkit-scrollbar { width: 8px; height: 8px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb { background: var(--border); border-radius: 4px; }
    ::-webkit-scrollbar-thumb:hover { background: var(--text-dim); }
    ::-webkit-scrollbar-corner { background: transparent; }

    /* \u2500\u2500 Utility \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    .hidden { display: none !important; }
    .truncate { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .flex { display: flex; }
    .flex-col { display: flex; flex-direction: column; }
    .flex-1 { flex: 1; min-width: 0; min-height: 0; }
    .gap-2 { gap: 2px; } .gap-4 { gap: 4px; } .gap-8 { gap: 8px; }
    .p-4 { padding: 4px; } .p-8 { padding: 8px; }
    .items-center { align-items: center; }
    .justify-between { justify-content: space-between; }

    /* \u2500\u2500 Tooltip \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    [data-tooltip] { position: relative; }
    [data-tooltip]:hover::after {
      content: attr(data-tooltip); position: absolute; bottom: calc(100% + 4px);
      left: 50%; transform: translateX(-50%); padding: 4px 8px;
      background: var(--surface-3); color: var(--text-bright); font-size: 11px;
      border-radius: var(--radius); white-space: nowrap; pointer-events: none;
      border: 1px solid var(--border); z-index: var(--z-dropdown);
      box-shadow: 0 2px 8px rgba(0,0,0,0.3);
    }

    /* \u2500\u2500 Loading Spinner \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    .spinner {
      width: 16px; height: 16px; border: 2px solid var(--border);
      border-top-color: var(--accent); border-radius: 50%;
      animation: spin 0.6s linear infinite;
    }
    @keyframes spin { to { transform: rotate(360deg); } }

    /* \u2500\u2500 Empty State \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 */
    .empty-state {
      display: flex; flex-direction: column; align-items: center; justify-content: center;
      gap: 8px; padding: 32px; color: var(--text-dim); text-align: center;
    }
    .empty-state svg { width: 48px; height: 48px; opacity: 0.3; }
    .empty-state p { max-width: 280px; line-height: 1.5; }
  `}function Jl(){return`
    // \u2500\u2500 Undo / Redo Stack \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    class UndoStack {
      constructor(maxSize = 100) {
        this._stack = []; this._idx = -1; this._max = maxSize;
        this._onChange = null;
      }
      push(state) {
        this._stack = this._stack.slice(0, this._idx + 1);
        this._stack.push(JSON.parse(JSON.stringify(state)));
        if (this._stack.length > this._max) this._stack.shift();
        else this._idx++;
        this._notify();
      }
      undo() {
        if (this._idx <= 0) return null;
        this._idx--;
        this._notify();
        return JSON.parse(JSON.stringify(this._stack[this._idx]));
      }
      redo() {
        if (this._idx >= this._stack.length - 1) return null;
        this._idx++;
        this._notify();
        return JSON.parse(JSON.stringify(this._stack[this._idx]));
      }
      get canUndo() { return this._idx > 0; }
      get canRedo() { return this._idx < this._stack.length - 1; }
      onChange(fn) { this._onChange = fn; }
      _notify() { if (this._onChange) this._onChange(this.canUndo, this.canRedo); }
    }

    // \u2500\u2500 Toast Notifications \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    const _toastContainer = document.createElement('div');
    _toastContainer.className = 'toast-container';
    document.body.appendChild(_toastContainer);

    function showToast(message, type = 'info', duration = 3000) {
      const t = document.createElement('div');
      t.className = 'toast ' + type;
      t.textContent = message;
      _toastContainer.appendChild(t);
      setTimeout(() => { t.style.opacity = '0'; setTimeout(() => t.remove(), 200); }, duration);
    }

    // \u2500\u2500 Keyboard Shortcuts \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    const _keyHandlers = {};
    function registerShortcut(key, fn) { _keyHandlers[key.toLowerCase()] = fn; }

    document.addEventListener('keydown', (e) => {
      const parts = [];
      if (e.ctrlKey || e.metaKey) parts.push('ctrl');
      if (e.shiftKey) parts.push('shift');
      if (e.altKey) parts.push('alt');
      parts.push(e.key.toLowerCase());
      const combo = parts.join('+');
      if (_keyHandlers[combo]) { e.preventDefault(); _keyHandlers[combo](e); }
    });

    // \u2500\u2500 Collapsible Panel Sections \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    function initCollapsibleSections() {
      document.querySelectorAll('.panel-header').forEach(header => {
        header.addEventListener('click', () => {
          const body = header.nextElementSibling;
          const icon = header.querySelector('.toggle-icon');
          if (body) body.classList.toggle('collapsed');
          if (icon) icon.classList.toggle('collapsed');
        });
      });
    }

    // \u2500\u2500 Context Menu \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    let _activeCtxMenu = null;
    function showContextMenu(x, y, items) {
      hideContextMenu();
      const menu = document.createElement('div');
      menu.className = 'context-menu';
      menu.style.left = x + 'px'; menu.style.top = y + 'px';
      items.forEach(item => {
        if (item === 'sep') {
          const sep = document.createElement('div');
          sep.className = 'context-menu-sep';
          menu.appendChild(sep);
        } else {
          const el = document.createElement('div');
          el.className = 'context-menu-item' + (item.disabled ? ' disabled' : '');
          el.textContent = item.label;
          if (item.icon) el.insertAdjacentHTML('afterbegin', item.icon);
          el.addEventListener('click', () => { hideContextMenu(); if (item.action) item.action(); });
          menu.appendChild(el);
        }
      });
      document.body.appendChild(menu);
      _activeCtxMenu = menu;
      // Clamp to viewport
      const rect = menu.getBoundingClientRect();
      if (rect.right > window.innerWidth) menu.style.left = (window.innerWidth - rect.width - 4) + 'px';
      if (rect.bottom > window.innerHeight) menu.style.top = (window.innerHeight - rect.height - 4) + 'px';
    }
    function hideContextMenu() { if (_activeCtxMenu) { _activeCtxMenu.remove(); _activeCtxMenu = null; } }
    document.addEventListener('click', hideContextMenu);
    document.addEventListener('contextmenu', (e) => { if (!_activeCtxMenu) return; });

    // \u2500\u2500 Resizable Splitter \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    function initSplitter(splitterEl, beforeEl, afterEl, direction = 'horizontal', minPx = 120) {
      let startPos, startBeforeSize;
      splitterEl.addEventListener('mousedown', (e) => {
        e.preventDefault();
        splitterEl.classList.add('dragging');
        startPos = direction === 'horizontal' ? e.clientX : e.clientY;
        startBeforeSize = direction === 'horizontal' ? beforeEl.offsetWidth : beforeEl.offsetHeight;
        const onMove = (ev) => {
          const delta = (direction === 'horizontal' ? ev.clientX : ev.clientY) - startPos;
          const newSize = Math.max(minPx, startBeforeSize + delta);
          beforeEl.style[direction === 'horizontal' ? 'width' : 'height'] = newSize + 'px';
        };
        const onUp = () => {
          splitterEl.classList.remove('dragging');
          document.removeEventListener('mousemove', onMove);
          document.removeEventListener('mouseup', onUp);
        };
        document.addEventListener('mousemove', onMove);
        document.addEventListener('mouseup', onUp);
      });
    }

    // \u2500\u2500 Export Dropdown \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    function createExportDropdown(buttonEl, options) {
      buttonEl.addEventListener('click', (e) => {
        e.stopPropagation();
        const rect = buttonEl.getBoundingClientRect();
        showContextMenu(rect.left, rect.bottom + 2, options.map(o => ({
          label: o.label,
          icon: o.icon || '',
          action: o.action,
        })));
      });
    }

    // \u2500\u2500 Dirty State Helper \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
    let _isDirty = false;
    function markDirty() {
      _isDirty = true;
      document.querySelectorAll('.dirty-indicator').forEach(el => {
        el.innerHTML = '${c.dirty}';
        el.setAttribute('data-tooltip', 'Unsaved changes');
      });
      vscode.postMessage({ type: 'stateChanged', dirty: true });
    }
    function markClean() {
      _isDirty = false;
      document.querySelectorAll('.dirty-indicator').forEach(el => {
        el.innerHTML = '${c.clean}';
        el.setAttribute('data-tooltip', 'All changes saved');
      });
      vscode.postMessage({ type: 'stateChanged', dirty: false });
    }

    // Register default keyboard shortcuts
    registerShortcut('ctrl+z', () => { document.getElementById('btnUndo')?.click(); });
    registerShortcut('ctrl+shift+z', () => { document.getElementById('btnRedo')?.click(); });
    registerShortcut('ctrl+y', () => { document.getElementById('btnRedo')?.click(); });
    registerShortcut('ctrl+s', () => { document.getElementById('btnExport')?.click(); });

    // Init collapsible sections when DOM ready
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', initCollapsibleSections);
    } else {
      initCollapsibleSections();
    }
  `}function I(n,e,t,r,a){return`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta http-equiv="Content-Security-Policy"
    content="default-src 'none'; style-src 'nonce-${n}'; script-src 'nonce-${n}'; img-src data:;">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${e}</title>
  <style nonce="${n}">${Ql()}${t}</style>
</head>
<body>
${r}
<script nonce="${n}">
const vscode = acquireVsCodeApi();
${Jl()}
${a}
</script>
</body>
</html>`}function k(){return'<div class="sep"></div>'}function A(){return'<div class="spacer"></div>'}function g(n,e={}){let t=["icon-btn",e.className||""].filter(Boolean).join(" "),r=e.ariaPressed?' aria-pressed="true"':"",a=e.id?` id="${e.id}"`:"",i=e.title?` title="${e.title}" data-tooltip="${e.title}"`:"";return`<button class="${t}"${a}${i}${r}>${c[n]}</button>`}function b(n,e,t=!1){let r=t?" collapsed":"";return`
    <div class="panel-section">
      <div class="panel-header">
        <h3>${n}</h3>
        <svg class="toggle-icon${r}" width="14" height="14" viewBox="0 0 16 16" fill="currentColor">
          <path d="M5.7 13.7L4.3 12.3 8.6 8 4.3 3.7 5.7 2.3 11.4 8z"/>
        </svg>
      </div>
      <div class="panel-body${r}">${e}</div>
    </div>`}function N(n,e){return`<div class="field-inline"><label>${n}</label>${e}</div>`}var E=class{constructor(e,t,r,a={}){this.context=e;this.data=a;this.stateKey=`lurek.editorState.${t}`,this.panel=le.window.createWebviewPanel(t,r,le.ViewColumn.One,{enableScripts:!0,retainContextWhenHidden:!0}),this.panel.iconPath=le.Uri.joinPath(e.extensionUri,"media","icon.png"),this.panel.webview.onDidReceiveMessage(s=>this.onMessage(s),void 0,this.disposables),this.panel.onDidDispose(()=>this.dispose(),void 0,this.disposables),this.panel.webview.html=this.getHtml();let i=this.context.workspaceState.get(this.stateKey);i&&this.panel.webview.postMessage({type:"restoreState",data:i})}panel;isDirty=!1;disposables=[];stateKey;onMessage(e){switch(e.type){case"stateChanged":this.isDirty=e.dirty;break;case"persistState":this.context.workspaceState.update(this.stateKey,e.data);break;case"exportLua":this.exportLua(e.content,e.name||"export.lua");break;case"exportToml":this.exportToml(e.content,e.name||"export.toml");break;case"exportJson":this.exportFile(e.content,e.name||"export.json","JSON","json");break;case"exportPng":this.exportFile(e.content,e.name||"export.png","PNG","png");break;case"copyToClipboard":le.env.clipboard.writeText(e.content).then(()=>{le.window.showInformationMessage("Copied to clipboard")});break;case"insertToEditor":{let t=le.window.activeTextEditor;t?t.edit(r=>{r.insert(t.selection.active,e.content)}):le.window.showWarningMessage("No active text editor to insert into");break}case"showToast":e.level==="error"?le.window.showErrorMessage(e.message):e.level==="warn"?le.window.showWarningMessage(e.message):le.window.showInformationMessage(e.message);break;default:this.handleMessage(e)}}async exportFile(e,t,r,a){let i=await le.window.showSaveDialog({defaultUri:le.Uri.file(t),filters:{[r]:[a]}});i&&(await le.workspace.fs.writeFile(i,Buffer.from(e,"utf-8")),le.window.showInformationMessage(`Exported to ${i.fsPath}`))}async exportLua(e,t){return this.exportFile(e,t,"Lua","lua")}async exportToml(e,t){return this.exportFile(e,t,"TOML","toml")}dispose(){this.isDirty&&this.panel.webview.postMessage({type:"requestState"});for(let e of this.disposables)e.dispose()}};var gn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.tileMap","Tile Map Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"tilemap.lua");break;case"exportToml":this.exportToml(e.content,"tilemap.toml");break}}getHtml(){let e=L();return I(e,"Tile Map Editor",`
      .editor-layout {
        display: grid; grid-template-columns: 38px 1fr 220px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: var(--bg); }
      .canvas-area canvas { display: block; image-rendering: pixelated; }
      .properties { grid-row: 2; background: var(--surface); border-left: 1px solid var(--border); overflow-y: auto; }

      .palette-grid {
        display: grid; grid-template-columns: repeat(4, 1fr); gap: 2px;
      }
      .palette-tile {
        aspect-ratio: 1; cursor: pointer; border-radius: var(--radius);
        border: 1px solid transparent; transition: border-color 0.1s, transform 0.1s;
        position: relative;
      }
      .palette-tile:hover { border-color: var(--text); transform: scale(1.08); z-index: 1; }
      .palette-tile.selected { border-color: var(--accent); border-width: 2px; }
      .palette-tile .tile-id {
        position: absolute; bottom: 0; right: 0; font-size: 8px;
        background: rgba(0,0,0,0.6); color: var(--text-dim); padding: 0 3px;
        border-radius: 2px 0 2px 0; line-height: 1.4;
      }

      .layer-item {
        display: flex; align-items: center; gap: 4px; padding: 3px 6px;
        font-size: 11px; cursor: pointer; border-radius: var(--radius);
        transition: background 0.08s;
      }
      .layer-item:hover { background: var(--hover); }
      .layer-item.sel { background: var(--selection); }
      .layer-item .vis-btn {
        width: 18px; height: 18px; background: none; border: none;
        cursor: pointer; color: var(--text-dim); padding: 0;
        display: flex; align-items: center; justify-content: center;
      }
      .layer-item .vis-btn:hover { color: var(--accent); background: transparent; border: none; }
      .layer-item .vis-btn svg { width: 12px; height: 12px; }
      .layer-item .name { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
      .layer-actions { display: flex; gap: 2px; margin-bottom: 4px; }
      .layer-actions button { flex: 1; font-size: 10px; padding: 3px 0; }
    `,`
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            <label>Map</label>
            <input type="number" id="mapWidth" value="20" min="1" max="256" style="width:48px" title="Width">
            <span style="color:var(--text-dim)">\xD7</span>
            <input type="number" id="mapHeight" value="15" min="1" max="256" style="width:48px" title="Height">
            <button id="btnResize" title="Apply size" data-tooltip="Resize map">Apply</button>
          </div>
          ${k()}
          <div class="group">
            <label>Tile</label>
            <input type="number" id="tileSize" value="32" min="8" max="128" style="width:48px" title="Tile pixel size">
          </div>
          ${k()}
          <div class="group">
            ${g("undo",{id:"btnUndo",title:"Undo (Ctrl+Z)"})}
            ${g("redo",{id:"btnRedo",title:"Redo (Ctrl+Y)"})}
          </div>
          ${k()}
          <div class="group">
            ${g("grid",{id:"btnGrid",title:"Toggle Grid",className:"active"})}
          </div>
          ${A()}
          <div class="group">
            ${g("copy",{id:"btnCopyLua",title:"Copy Lua Code"})}
            ${g("insert",{id:"btnInsert",title:"Insert to Editor"})}
          </div>
          ${k()}
          <button id="btnExport" class="primary">${c.exportFile} Export \u25BE</button>
        </div>

        <!-- Tool Rail -->
        <div class="tool-rail" id="tools">
          <div class="tool-group">
            <button class="icon-btn active" data-tool="paint" title="Paint (B)" data-tooltip="Paint">${c.pen}</button>
            <button class="icon-btn" data-tool="erase" title="Eraser (E)" data-tooltip="Eraser">${c.eraser}</button>
            <button class="icon-btn" data-tool="fill" title="Fill (G)" data-tooltip="Fill">${c.bucket}</button>
          </div>
          <div class="tool-group">
            <button class="icon-btn" data-tool="rect" title="Rectangle (R)" data-tooltip="Rect Fill">${c.rect}</button>
            <button class="icon-btn" data-tool="stamp" title="Stamp (S)" data-tooltip="Stamp">${c.stamp}</button>
          </div>
          <div class="tool-group">
            <button class="icon-btn" data-tool="pick" title="Pick Tile (I)" data-tooltip="Pick">${c.pick}</button>
            <button class="icon-btn" data-tool="hand" title="Pan (H / Middle Mouse)" data-tooltip="Pan">${c.hand}</button>
          </div>
        </div>

        <!-- Canvas -->
        <div class="canvas-area"><canvas id="mapCanvas"></canvas></div>

        <!-- Properties Panel -->
        <div class="properties">
          ${b("Layers",`
            <div class="layer-actions">
              <button id="btnAddLayer">${c.add} Add</button>
              <button id="btnDelLayer">${c.trash} Del</button>
              <button id="btnMoveLayerUp">${c.moveUp}</button>
              <button id="btnMoveLayerDown">${c.moveDown}</button>
            </div>
            <div id="layerList"></div>
          `)}
          ${b("Tile Palette",`
            <div class="palette-grid" id="palette"></div>
          `)}
          ${b("View",`
            <div class="field-row"><input type="checkbox" id="showGrid" checked><label for="showGrid">Grid overlay</label></div>
            <div class="field-row"><input type="checkbox" id="showIds"><label for="showIds">Tile IDs</label></div>
            <div class="field-row"><input type="checkbox" id="showAllLayers" checked><label for="showAllLayers">Show all layers</label></div>
          `)}
          ${b("Tile Properties",`
            <div id="tileProps">
              ${N("Selected",'<span id="selectedTileId">1</span>')}
              ${N("Color",'<span id="selectedTileColor" style="display:inline-block;width:14px;height:14px;border-radius:2px;vertical-align:middle;border:1px solid var(--border)"></span>')}
              ${N("Name",'<input id="tileName" value="" placeholder="unnamed" style="width:100%">')}
              ${N("Solid",'<input type="checkbox" id="tileSolid">')}
            </div>
          `,!0)}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group"><span id="statusPos">0, 0</span></span>
          <div class="sep"></div>
          <span id="statusTool">Paint</span>
          <div class="sep"></div>
          <span id="statusTile">Tile: 1</span>
          <div class="sep"></div>
          <span id="statusLayer">ground</span>
          <div class="spacer"></div>
          <span id="statusSize">20\xD715</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${c.clean}</span>
        </div>
      </div>
    `,`
      // \u2500\u2500 Constants \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      const TILE_COLORS = [
        '#1a1a2e','#16213e','#0f3460','#533483','#e94560','#4ec9b0',
        '#007acc','#ff9800','#4caf50','#f44336','#9c27b0','#00bcd4',
        '#795548','#607d8b','#ffeb3b','#8bc34a','#e91e63','#673ab7',
        '#2196f3','#009688','#ff5722','#3f51b5','#cddc39','#ffc107',
        '#1b5e20','#bf360c','#0d47a1','#4a148c','#263238','#f5f5f5',
        '#424242','#e0e0e0'
      ];

      // \u2500\u2500 State \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      const canvas = document.getElementById('mapCanvas');
      const ctx = canvas.getContext('2d');
      const undoStack = new UndoStack(80);

      let mapW = 20, mapH = 15, tileSize = 32;
      let currentTile = 1, currentTool = 'paint';
      let showGrid = true, showIds = false, showAllLayers = true;
      let offsetX = 0, offsetY = 0, zoom = 1;
      let isPanning = false, panStartX = 0, panStartY = 0;
      let isDrawing = false, rectStartX = -1, rectStartY = -1;

      const LAYER_NAMES = ['ground', 'walls', 'objects', 'decor', 'collision'];
      let layerData = {};
      let layerVisible = {};
      let currentLayer = 'ground';
      let tileNames = {};
      let tileSolid = {};

      function initLayer(name) { layerData[name] = new Array(mapW * mapH).fill(0); }
      function initAllLayers() {
        LAYER_NAMES.forEach(n => { initLayer(n); layerVisible[n] = true; });
      }
      initAllLayers();

      function getState() {
        const ld = {};
        for (const k in layerData) ld[k] = [...layerData[k]];
        return { layerData: ld, currentLayer };
      }
      function pushUndo() { undoStack.push(getState()); markDirty(); }

      undoStack.onChange((canUndo, canRedo) => {
        document.getElementById('btnUndo').disabled = !canUndo;
        document.getElementById('btnRedo').disabled = !canRedo;
      });
      document.getElementById('btnUndo').addEventListener('click', () => {
        const prev = undoStack.undo();
        if (prev) { for (const k in prev.layerData) layerData[k] = prev.layerData[k]; render(); }
      });
      document.getElementById('btnRedo').addEventListener('click', () => {
        const next = undoStack.redo();
        if (next) { for (const k in next.layerData) layerData[k] = next.layerData[k]; render(); }
      });
      undoStack.push(getState());

      // \u2500\u2500 Canvas Rendering \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth;
        canvas.height = area.clientHeight;
        render();
      }

      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.save();
        ctx.translate(offsetX, offsetY);
        ctx.scale(zoom, zoom);

        // Background
        ctx.fillStyle = '#1a1a2e';
        ctx.fillRect(0, 0, mapW * tileSize, mapH * tileSize);

        // Render layers
        const layersToShow = showAllLayers ? LAYER_NAMES : [currentLayer];
        for (const lName of layersToShow) {
          if (!layerVisible[lName]) continue;
          const layer = layerData[lName];
          if (!layer) continue;
          const alpha = (lName !== currentLayer && showAllLayers) ? 0.5 : 1;
          ctx.globalAlpha = alpha;
          for (let y = 0; y < mapH; y++) {
            for (let x = 0; x < mapW; x++) {
              const t = layer[y * mapW + x];
              if (t > 0) {
                ctx.fillStyle = TILE_COLORS[(t - 1) % TILE_COLORS.length];
                ctx.fillRect(x * tileSize, y * tileSize, tileSize, tileSize);
              }
            }
          }
          ctx.globalAlpha = 1;
        }

        // Grid
        if (showGrid) {
          ctx.strokeStyle = 'rgba(255,255,255,0.06)';
          ctx.lineWidth = 0.5 / zoom;
          for (let x = 0; x <= mapW; x++) { ctx.beginPath(); ctx.moveTo(x * tileSize, 0); ctx.lineTo(x * tileSize, mapH * tileSize); ctx.stroke(); }
          for (let y = 0; y <= mapH; y++) { ctx.beginPath(); ctx.moveTo(0, y * tileSize); ctx.lineTo(mapW * tileSize, y * tileSize); ctx.stroke(); }
        }

        // Tile IDs
        if (showIds) {
          ctx.fillStyle = '#fff';
          ctx.font = Math.max(8, 10 / zoom) + 'px monospace';
          ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
          const layer = layerData[currentLayer];
          for (let y = 0; y < mapH; y++)
            for (let x = 0; x < mapW; x++) {
              const t = layer[y * mapW + x];
              if (t > 0) ctx.fillText(String(t), x * tileSize + tileSize/2, y * tileSize + tileSize/2);
            }
        }

        // Map border
        ctx.strokeStyle = 'rgba(137,180,250,0.3)';
        ctx.lineWidth = 1 / zoom;
        ctx.strokeRect(0, 0, mapW * tileSize, mapH * tileSize);

        // Rect preview
        if (isDrawing && currentTool === 'rect' && rectStartX >= 0) {
          const { tx, ty } = lastHover;
          const x0 = Math.min(rectStartX, tx), y0 = Math.min(rectStartY, ty);
          const x1 = Math.max(rectStartX, tx), y1 = Math.max(rectStartY, ty);
          ctx.strokeStyle = 'rgba(137,180,250,0.6)';
          ctx.lineWidth = 1 / zoom;
          ctx.setLineDash([4 / zoom, 4 / zoom]);
          ctx.strokeRect(x0 * tileSize, y0 * tileSize, (x1 - x0 + 1) * tileSize, (y1 - y0 + 1) * tileSize);
          ctx.setLineDash([]);
        }

        ctx.restore();
      }
      let lastHover = { tx: 0, ty: 0 };

      // \u2500\u2500 Tile Operations \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function screenToTile(sx, sy) {
        const tx = Math.floor((sx - offsetX) / (tileSize * zoom));
        const ty = Math.floor((sy - offsetY) / (tileSize * zoom));
        return { tx, ty };
      }

      function setTile(tx, ty, value) {
        if (tx >= 0 && tx < mapW && ty >= 0 && ty < mapH) {
          layerData[currentLayer][ty * mapW + tx] = value;
        }
      }

      function floodFill(tx, ty, target, replacement) {
        if (target === replacement) return;
        const layer = layerData[currentLayer];
        const stack = [[tx, ty]];
        const visited = new Set();
        while (stack.length) {
          const [x, y] = stack.pop();
          const key = x + ',' + y;
          if (visited.has(key)) continue;
          visited.add(key);
          if (x < 0 || x >= mapW || y < 0 || y >= mapH) continue;
          if (layer[y * mapW + x] !== target) continue;
          layer[y * mapW + x] = replacement;
          stack.push([x-1,y],[x+1,y],[x,y-1],[x,y+1]);
        }
      }

      // \u2500\u2500 Input Handlers \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || currentTool === 'hand' || (e.altKey && e.button === 0)) {
          isPanning = true; panStartX = e.clientX - offsetX; panStartY = e.clientY - offsetY;
          canvas.style.cursor = 'grabbing'; e.preventDefault(); return;
        }
        if (e.button === 0) {
          pushUndo(); isDrawing = true;
          const { tx, ty } = screenToTile(e.offsetX, e.offsetY);
          if (currentTool === 'paint') { setTile(tx, ty, currentTile); render(); }
          else if (currentTool === 'erase') { setTile(tx, ty, 0); render(); }
          else if (currentTool === 'fill') {
            const layer = layerData[currentLayer];
            if (tx >= 0 && tx < mapW && ty >= 0 && ty < mapH) {
              floodFill(tx, ty, layer[ty*mapW+tx], currentTile); render();
            }
          }
          else if (currentTool === 'pick') {
            const layer = layerData[currentLayer];
            if (tx >= 0 && tx < mapW && ty >= 0 && ty < mapH) {
              currentTile = layer[ty*mapW+tx];
              updateTileDisplay();
            }
          }
          else if (currentTool === 'rect') { rectStartX = tx; rectStartY = ty; }
          else if (currentTool === 'stamp') { setTile(tx, ty, currentTile); render(); }
        }
      });

      canvas.addEventListener('mousemove', (e) => {
        const { tx, ty } = screenToTile(e.offsetX, e.offsetY);
        lastHover = { tx, ty };
        document.getElementById('statusPos').textContent = tx + ', ' + ty;
        if (isPanning) { offsetX = e.clientX - panStartX; offsetY = e.clientY - panStartY; render(); return; }
        if (isDrawing) {
          if (currentTool === 'paint' || currentTool === 'stamp') { setTile(tx, ty, currentTile); render(); }
          else if (currentTool === 'erase') { setTile(tx, ty, 0); render(); }
          else if (currentTool === 'rect') { render(); }
        }
      });

      canvas.addEventListener('mouseup', (e) => {
        canvas.style.cursor = '';
        if (isPanning) { isPanning = false; return; }
        if (isDrawing && currentTool === 'rect') {
          const { tx, ty } = screenToTile(e.offsetX, e.offsetY);
          const x0 = Math.min(rectStartX, tx), x1 = Math.max(rectStartX, tx);
          const y0 = Math.min(rectStartY, ty), y1 = Math.max(rectStartY, ty);
          for (let ry = y0; ry <= y1; ry++)
            for (let rx = x0; rx <= x1; rx++) setTile(rx, ry, currentTile);
          render();
        }
        isDrawing = false;
      });

      canvas.addEventListener('contextmenu', (e) => e.preventDefault());

      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const oldZoom = zoom;
        zoom *= e.deltaY < 0 ? 1.1 : 0.9;
        zoom = Math.max(0.1, Math.min(5, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / oldZoom;
        offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / oldZoom;
        render();
      }, { passive: false });

      // \u2500\u2500 Tool Selection \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      const toolKeys = { b: 'paint', e: 'erase', g: 'fill', r: 'rect', s: 'stamp', i: 'pick', h: 'hand' };
      Object.entries(toolKeys).forEach(([key, tool]) => {
        registerShortcut(key, () => { selectTool(tool); });
      });

      function selectTool(tool) {
        currentTool = tool;
        document.querySelectorAll('#tools .icon-btn').forEach(b => {
          b.classList.toggle('active', b.dataset.tool === tool);
        });
        document.getElementById('statusTool').textContent = tool.charAt(0).toUpperCase() + tool.slice(1);
      }

      document.getElementById('tools').addEventListener('click', (e) => {
        const btn = e.target.closest('[data-tool]');
        if (btn) selectTool(btn.dataset.tool);
      });

      // \u2500\u2500 Palette \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      const paletteEl = document.getElementById('palette');
      for (let i = 0; i <= 31; i++) {
        const el = document.createElement('div');
        el.className = 'palette-tile' + (i === 1 ? ' selected' : '');
        if (i === 0) {
          el.style.background = 'repeating-conic-gradient(#333 0% 25%, #222 0% 50%) 50% / 8px 8px';
        } else {
          el.style.background = TILE_COLORS[(i-1) % TILE_COLORS.length];
        }
        el.innerHTML = '<span class="tile-id">' + i + '</span>';
        el.title = 'Tile ' + i;
        el.addEventListener('click', () => { currentTile = i; updateTileDisplay(); });
        paletteEl.appendChild(el);
      }

      function updateTileDisplay() {
        paletteEl.querySelectorAll('.palette-tile').forEach((t, idx) => {
          t.classList.toggle('selected', idx === currentTile);
        });
        document.getElementById('statusTile').textContent = 'Tile: ' + currentTile;
        document.getElementById('selectedTileId').textContent = currentTile;
        const color = currentTile > 0 ? TILE_COLORS[(currentTile-1) % TILE_COLORS.length] : 'transparent';
        document.getElementById('selectedTileColor').style.background = color;
        document.getElementById('tileName').value = tileNames[currentTile] || '';
        document.getElementById('tileSolid').checked = !!tileSolid[currentTile];
      }
      updateTileDisplay();

      document.getElementById('tileName').addEventListener('change', (e) => { tileNames[currentTile] = e.target.value; });
      document.getElementById('tileSolid').addEventListener('change', (e) => { tileSolid[currentTile] = e.target.checked; });

      // \u2500\u2500 Grid / View \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      document.getElementById('btnGrid').addEventListener('click', function() {
        showGrid = !showGrid; this.classList.toggle('active', showGrid); render();
      });
      document.getElementById('showGrid').addEventListener('change', (e) => {
        showGrid = e.target.checked;
        document.getElementById('btnGrid').classList.toggle('active', showGrid);
        render();
      });
      document.getElementById('showIds').addEventListener('change', (e) => { showIds = e.target.checked; render(); });
      document.getElementById('showAllLayers').addEventListener('change', (e) => { showAllLayers = e.target.checked; render(); });

      // \u2500\u2500 Resize \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      document.getElementById('btnResize').addEventListener('click', () => {
        const nw = Math.min(256, Math.max(1, parseInt(document.getElementById('mapWidth').value) || 20));
        const nh = Math.min(256, Math.max(1, parseInt(document.getElementById('mapHeight').value) || 15));
        const newTs = parseInt(document.getElementById('tileSize').value) || 32;
        pushUndo();
        // Preserve existing data where possible
        for (const k of LAYER_NAMES) {
          const oldData = layerData[k] || [];
          const newData = new Array(nw * nh).fill(0);
          const copyW = Math.min(mapW, nw), copyH = Math.min(mapH, nh);
          for (let y = 0; y < copyH; y++)
            for (let x = 0; x < copyW; x++)
              newData[y * nw + x] = oldData[y * mapW + x] || 0;
          layerData[k] = newData;
        }
        mapW = nw; mapH = nh; tileSize = newTs;
        document.getElementById('statusSize').textContent = mapW + '\xD7' + mapH;
        render();
        showToast('Resized to ' + mapW + '\xD7' + mapH, 'info');
      });

      // \u2500\u2500 Layers \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function refreshLayers() {
        const el = document.getElementById('layerList');
        el.innerHTML = '';
        LAYER_NAMES.forEach(name => {
          const div = document.createElement('div');
          div.className = 'layer-item' + (name === currentLayer ? ' sel' : '');
          const visIcon = layerVisible[name] ? '${c.eye}' : '${c.eyeOff}';
          div.innerHTML = '<button class="vis-btn" title="Toggle">' + visIcon + '</button>' +
            '<span class="name">' + name + '</span>';
          div.querySelector('.vis-btn').addEventListener('click', (ev) => {
            ev.stopPropagation();
            layerVisible[name] = !layerVisible[name]; refreshLayers(); render();
          });
          div.addEventListener('click', () => {
            currentLayer = name; refreshLayers();
            document.getElementById('statusLayer').textContent = name;
            render();
          });
          el.appendChild(div);
        });
      }

      document.getElementById('btnAddLayer').addEventListener('click', () => {
        const name = 'layer_' + LAYER_NAMES.length;
        LAYER_NAMES.push(name);
        layerData[name] = new Array(mapW * mapH).fill(0);
        layerVisible[name] = true;
        currentLayer = name;
        refreshLayers(); render();
        showToast('Added layer: ' + name, 'info');
      });
      document.getElementById('btnDelLayer').addEventListener('click', () => {
        if (LAYER_NAMES.length <= 1) { showToast('Cannot delete last layer', 'warn'); return; }
        pushUndo();
        const idx = LAYER_NAMES.indexOf(currentLayer);
        delete layerData[currentLayer]; delete layerVisible[currentLayer];
        LAYER_NAMES.splice(idx, 1);
        currentLayer = LAYER_NAMES[Math.min(idx, LAYER_NAMES.length - 1)];
        refreshLayers(); render();
      });
      document.getElementById('btnMoveLayerUp').addEventListener('click', () => {
        const idx = LAYER_NAMES.indexOf(currentLayer);
        if (idx >= LAYER_NAMES.length - 1) return;
        [LAYER_NAMES[idx], LAYER_NAMES[idx+1]] = [LAYER_NAMES[idx+1], LAYER_NAMES[idx]];
        refreshLayers(); render();
      });
      document.getElementById('btnMoveLayerDown').addEventListener('click', () => {
        const idx = LAYER_NAMES.indexOf(currentLayer);
        if (idx <= 0) return;
        [LAYER_NAMES[idx], LAYER_NAMES[idx-1]] = [LAYER_NAMES[idx-1], LAYER_NAMES[idx]];
        refreshLayers(); render();
      });
      refreshLayers();

      // \u2500\u2500 Export \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function generateExportData() {
        const data = { width: mapW, height: mapH, tileSize: tileSize, layers: {} };
        for (const k of LAYER_NAMES) data.layers[k] = Array.from(layerData[k]);
        return data;
      }

      function buildLuaCode() {
        const d = generateExportData();
        const lines = ['-- Generated by Lurek2D Tile Map Editor'];
        lines.push('-- Usage: local map = lurek.tilemap.new(data)');
        lines.push('');
        lines.push('return {');
        lines.push('  width = ' + d.width + ',');
        lines.push('  height = ' + d.height + ',');
        lines.push('  tile_size = ' + d.tileSize + ',');

        // Tile properties
        const solidTiles = Object.entries(tileSolid).filter(([,v]) => v).map(([k]) => k);
        if (solidTiles.length > 0) {
          lines.push('  solid_tiles = {' + solidTiles.join(', ') + '},');
        }

        lines.push('  layers = {');
        for (const k of LAYER_NAMES) {
          // Row-by-row for readability
          lines.push('    ' + k + ' = {');
          for (let y = 0; y < d.height; y++) {
            const row = d.layers[k].slice(y * d.width, (y + 1) * d.width);
            const comma = y < d.height - 1 ? ',' : '';
            lines.push('      {' + row.join(',') + '}' + comma);
          }
          lines.push('    },');
        }
        lines.push('  }');
        lines.push('}');
        return lines.join('\\n');
      }

      function buildToml() {
        const d = generateExportData();
        let toml = '# Generated by Lurek2D Tile Map Editor\\n';
        toml += 'width = ' + d.width + '\\n';
        toml += 'height = ' + d.height + '\\n';
        toml += 'tile_size = ' + d.tileSize + '\\n\\n';
        for (const k of LAYER_NAMES) {
          toml += '[layers.' + k + ']\\n';
          toml += 'data = [' + d.layers[k].join(', ') + ']\\n\\n';
        }
        return toml;
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export Lua', action: () => vscode.postMessage({ type: 'exportLua', content: buildLuaCode() }) },
        { label: 'Export TOML', action: () => vscode.postMessage({ type: 'exportToml', content: buildToml() }) },
        { label: 'Copy Lua Code', action: () => vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() }) },
        { label: 'Insert Lua to Editor', action: () => vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() }) },
      ]);

      document.getElementById('btnCopyLua').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() });
      });

      // \u2500\u2500 Init \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function centerCanvas() {
        const area = canvas.parentElement;
        const totalW = mapW * tileSize * zoom, totalH = mapH * tileSize * zoom;
        offsetX = (area.clientWidth - totalW) / 2;
        offsetY = (area.clientHeight - totalH) / 2;
      }
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
      centerCanvas();
      render();
    `)}};var hn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.sceneFlow","Scene Flow Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"scenes.lua");break}}getHtml(){let e=L();return I(e,"Scene Flow Editor",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 240px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .canvas-area { position: relative; overflow: hidden; background: var(--bg); }
      .canvas-area canvas { display: block; }
      .props-panel { grid-row: 2; overflow-y: auto; background: var(--surface); border-left: 1px solid var(--border); }

      .scene-prop { margin-bottom: 3px; }
      .scene-prop label {
        font-size: 10px; text-transform: uppercase; letter-spacing: 0.3px;
        color: var(--text-dim); display: block; margin-bottom: 1px;
      }
      .scene-prop input, .scene-prop textarea {
        width: 100%; font-size: 12px;
      }
      .scene-prop textarea { height: 48px; resize: vertical; font-family: var(--font-mono); font-size: 11px; }

      .transition-item {
        display: flex; align-items: center; gap: 4px; font-size: 11px;
        padding: 3px 6px; border-radius: var(--radius); margin-bottom: 2px;
      }
      .transition-item:hover { background: var(--hover); }
      .transition-item .arrow { color: var(--accent); }
      .transition-item .target { flex: 1; }

      .minimap {
        border: 1px solid var(--border); border-radius: var(--radius); background: var(--bg);
        margin: 0 8px; height: 100px; position: relative; overflow: hidden;
      }
    `,`
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            ${g("add",{id:"btnAdd",title:"Add Scene (A)"})}
            ${g("link",{id:"btnConnect",title:"Connect Mode (C)"})}
            ${g("trash",{id:"btnDelete",title:"Delete Selected (Del)",cls:"danger"})}
          </div>
          ${k()}
          <div class="group">
            ${g("undo",{id:"btnUndo",title:"Undo (Ctrl+Z)"})}
            ${g("redo",{id:"btnRedo",title:"Redo (Ctrl+Y)"})}
          </div>
          ${k()}
          <div class="group">
            <button id="btnAutoLayout" title="Auto-arrange nodes">Auto Layout</button>
            <button id="btnFitView" title="Fit all nodes in view">Fit View</button>
          </div>
          ${A()}
          <div class="group">
            ${g("copy",{id:"btnCopyLua",title:"Copy Lua Code"})}
            ${g("insert",{id:"btnInsert",title:"Insert to Editor"})}
          </div>
          ${k()}
          <button id="btnExport" class="primary">${c.exportFile} Export \u25BE</button>
        </div>

        <!-- Canvas -->
        <div class="canvas-area"><canvas id="flowCanvas"></canvas></div>

        <!-- Properties Panel -->
        <div class="props-panel">
          ${b("Scene Properties",'<div id="propsContent"><p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:8px;">Select a scene node.</p></div>')}
          ${b("Transitions",'<div id="transContent"></div>',!0)}
          ${b("Minimap",'<div class="minimap"><canvas id="minimapCanvas" width="200" height="100"></canvas></div>',!0)}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusScenes" class="badge">0 scenes</span>
          </span>
          <div class="sep"></div>
          <span id="statusTransitions">0 transitions</span>
          <div class="sep"></div>
          <span id="statusMode">Select</span>
          <div class="spacer"></div>
          <span id="statusZoom">100%</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${c.clean}</span>
        </div>
      </div>
    `,`
      const canvas = document.getElementById('flowCanvas');
      const ctx = canvas.getContext('2d');
      let nodes = [], edges = [];
      let selectedNode = null, dragNode = null, dragOff = {x:0,y:0};
      let connectMode = false, connectFrom = null;
      let offsetX = 0, offsetY = 0, zoom = 1;
      let isPanning = false, panSX = 0, panSY = 0;
      let nextId = 1;
      const undo = new UndoStack(60);

      const NODE_W = 140, NODE_H = 54;
      const NODE_COLORS = ['#264f78','#2d4a22','#4a3222','#3c2244','#443322','#224a4a'];

      function snapshot() { return JSON.parse(JSON.stringify({ nodes, edges, nextId })); }
      function restoreSnap(s) { nodes = s.nodes; edges = s.edges; nextId = s.nextId; selectedNode = null; showProps(null); updateStatus(); render(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      function addNode(name, x, y) {
        pushUndo();
        nodes.push({
          id: nextId++, name: name || 'Scene_' + nodes.length,
          x: x !== undefined ? x : 100 + nodes.length * 40, y: y !== undefined ? y : 100 + nodes.length * 40,
          onEnter: '', onExit: '', onProcess: '', onRender: '',
          color: NODE_COLORS[nodes.length % NODE_COLORS.length]
        });
        updateStatus(); render();
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight;
        render();
      }

      // \u2500\u2500 Rendering \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // Grid dots
        ctx.fillStyle = 'rgba(137,180,250,0.06)';
        const gs = 40 * zoom, sx = offsetX % gs, sy = offsetY % gs;
        for (let y = sy; y < canvas.height; y += gs)
          for (let x = sx; x < canvas.width; x += gs)
            ctx.fillRect(x - 1, y - 1, 2, 2);

        ctx.save(); ctx.translate(offsetX, offsetY); ctx.scale(zoom, zoom);

        // Edges
        for (const e of edges) {
          const from = nodes.find(n => n.id === e.from);
          const to = nodes.find(n => n.id === e.to);
          if (!from || !to) continue;
          const fx = from.x + NODE_W/2, fy = from.y + NODE_H/2;
          const tx = to.x + NODE_W/2, ty = to.y + NODE_H/2;

          // Curved line
          const mx = (fx+tx)/2, my = (fy+ty)/2;
          const dx = tx-fx, dy = ty-fy;
          const len = Math.sqrt(dx*dx+dy*dy);
          const cx = mx + (fy-ty)*0.15, cy = my + (tx-fx)*0.15;

          ctx.beginPath(); ctx.moveTo(fx, fy); ctx.quadraticCurveTo(cx, cy, tx, ty);
          ctx.strokeStyle = 'rgba(137,180,250,0.4)'; ctx.lineWidth = 2; ctx.stroke();

          // Arrow
          const t = 0.85;
          const px = (1-t)*(1-t)*fx + 2*(1-t)*t*cx + t*t*tx;
          const py = (1-t)*(1-t)*fy + 2*(1-t)*t*cy + t*t*ty;
          const px2 = (1-0.84)*(1-0.84)*fx + 2*(1-0.84)*0.84*cx + 0.84*0.84*tx;
          const py2 = (1-0.84)*(1-0.84)*fy + 2*(1-0.84)*0.84*cy + 0.84*0.84*ty;
          const angle = Math.atan2(py-py2, px-px2);
          ctx.beginPath();
          ctx.moveTo(px + 6*Math.cos(angle), py + 6*Math.sin(angle));
          ctx.lineTo(px - 8*Math.cos(angle-0.5), py - 8*Math.sin(angle-0.5));
          ctx.lineTo(px - 8*Math.cos(angle+0.5), py - 8*Math.sin(angle+0.5));
          ctx.closePath(); ctx.fillStyle = 'rgba(137,180,250,0.5)'; ctx.fill();
        }

        // Connection preview
        if (connectMode && connectFrom) {
          ctx.strokeStyle = 'rgba(250,179,135,0.5)'; ctx.lineWidth = 2; ctx.setLineDash([6,4]);
          ctx.beginPath(); ctx.moveTo(connectFrom.x+NODE_W/2, connectFrom.y+NODE_H/2);
          // We'll draw to mouse in render \u2014 but we don't track mouse in render directly, skip
          ctx.setLineDash([]);
        }

        // Nodes
        for (const n of nodes) {
          const isSel = n === selectedNode;

          // Shadow
          ctx.fillStyle = 'rgba(0,0,0,0.3)';
          ctx.beginPath(); ctx.roundRect(n.x+2, n.y+2, NODE_W, NODE_H, 6); ctx.fill();

          // Body
          ctx.fillStyle = n.color;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.fill();

          // Border
          ctx.strokeStyle = isSel ? '#89b4fa' : 'rgba(255,255,255,0.1)';
          ctx.lineWidth = isSel ? 2.5 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.stroke();

          // Title
          ctx.fillStyle = '#e0e0e0'; ctx.font = 'bold 12px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
          ctx.fillText(n.name, n.x + NODE_W/2, n.y + NODE_H/2 - 6);

          // Subtitle (connection count)
          const outCount = edges.filter(e => e.from === n.id).length;
          const inCount = edges.filter(e => e.to === n.id).length;
          ctx.fillStyle = 'rgba(255,255,255,0.35)'; ctx.font = '10px sans-serif';
          ctx.fillText(inCount + ' in / ' + outCount + ' out', n.x + NODE_W/2, n.y + NODE_H/2 + 10);

          // Connect indicator
          if (connectMode) {
            ctx.fillStyle = 'rgba(250,179,135,0.6)';
            ctx.beginPath(); ctx.arc(n.x + NODE_W, n.y + NODE_H/2, 5, 0, Math.PI*2); ctx.fill();
          }
        }
        ctx.restore();
        renderMinimap();
      }

      function renderMinimap() {
        const mc = document.getElementById('minimapCanvas');
        if (!mc) return;
        const mctx = mc.getContext('2d');
        mctx.clearRect(0, 0, 200, 100);
        if (nodes.length === 0) return;
        let minX=Infinity,minY=Infinity,maxX=-Infinity,maxY=-Infinity;
        for (const n of nodes) { minX=Math.min(minX,n.x); minY=Math.min(minY,n.y); maxX=Math.max(maxX,n.x+NODE_W); maxY=Math.max(maxY,n.y+NODE_H); }
        const pad=20, w=maxX-minX+pad*2, h=maxY-minY+pad*2;
        const s = Math.min(200/w, 100/h);
        const ox = (200-w*s)/2 - minX*s + pad*s, oy = (100-h*s)/2 - minY*s + pad*s;
        for (const e of edges) {
          const from=nodes.find(n=>n.id===e.from), to=nodes.find(n=>n.id===e.to);
          if(!from||!to)continue;
          mctx.beginPath(); mctx.moveTo(from.x*s+ox+NODE_W*s/2, from.y*s+oy+NODE_H*s/2);
          mctx.lineTo(to.x*s+ox+NODE_W*s/2, to.y*s+oy+NODE_H*s/2);
          mctx.strokeStyle='rgba(137,180,250,0.3)'; mctx.lineWidth=1; mctx.stroke();
        }
        for (const n of nodes) {
          mctx.fillStyle = n===selectedNode ? '#89b4fa' : n.color;
          mctx.fillRect(n.x*s+ox, n.y*s+oy, NODE_W*s, NODE_H*s);
        }
      }

      // \u2500\u2500 Hit Test & Interaction \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function hitTest(sx, sy) {
        const wx = (sx - offsetX) / zoom, wy = (sy - offsetY) / zoom;
        for (let i = nodes.length - 1; i >= 0; i--) {
          const n = nodes[i];
          if (wx >= n.x && wx <= n.x + NODE_W && wy >= n.y && wy <= n.y + NODE_H) return n;
        }
        return null;
      }

      function showProps(node) {
        const el = document.getElementById('propsContent');
        const tel = document.getElementById('transContent');
        if (!node) {
          el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:8px;">Select a scene node.</p>';
          tel.innerHTML = '';
          return;
        }
        el.innerHTML =
          '<div class="scene-prop"><label>Name</label><input id="pName" value="' + node.name + '"></div>' +
          '<div class="scene-prop"><label>Color</label><input type="color" id="pColor" value="' + node.color + '" style="width:28px;height:22px;border:1px solid var(--border);border-radius:var(--radius);padding:0"></div>' +
          '<div class="scene-prop"><label>onEnter</label><textarea id="pEnter">' + node.onEnter + '</textarea></div>' +
          '<div class="scene-prop"><label>onExit</label><textarea id="pExit">' + node.onExit + '</textarea></div>' +
          '<div class="scene-prop"><label>onProcess</label><textarea id="pProcess">' + node.onProcess + '</textarea></div>' +
          '<div class="scene-prop"><label>onRender</label><textarea id="pRender">' + node.onRender + '</textarea></div>';

        const bind = (id, key) => {
          document.getElementById(id).addEventListener('input', (e) => {
            pushUndo(); node[key] = e.target.value;
            if (key === 'name' || key === 'color') render();
          });
        };
        bind('pName','name'); bind('pColor','color'); bind('pEnter','onEnter');
        bind('pExit','onExit'); bind('pProcess','onProcess'); bind('pRender','onRender');

        // Transitions list
        const outEdges = edges.filter(e => e.from === node.id);
        const inEdges = edges.filter(e => e.to === node.id);
        let thtml = '';
        if (outEdges.length) {
          thtml += '<div style="font-size:10px;color:var(--text-dim);margin-bottom:2px">OUTGOING</div>';
          for (const e of outEdges) {
            const t = nodes.find(n => n.id === e.to);
            thtml += '<div class="transition-item"><span class="arrow">\u2192</span><span class="target">' + (t ? t.name : '?') + '</span><button class="icon-btn" data-del-edge="' + e.from + '-' + e.to + '">${c.trash}</button></div>';
          }
        }
        if (inEdges.length) {
          thtml += '<div style="font-size:10px;color:var(--text-dim);margin:4px 0 2px">INCOMING</div>';
          for (const e of inEdges) {
            const f = nodes.find(n => n.id === e.from);
            thtml += '<div class="transition-item"><span class="arrow">\u2190</span><span class="target">' + (f ? f.name : '?') + '</span></div>';
          }
        }
        if (!outEdges.length && !inEdges.length) thtml = '<p style="color:var(--text-dim);font-size:11px">No transitions</p>';
        tel.innerHTML = thtml;

        tel.querySelectorAll('[data-del-edge]').forEach(btn => {
          btn.addEventListener('click', (e) => {
            const [from, to] = e.currentTarget.dataset.delEdge.split('-').map(Number);
            pushUndo();
            edges = edges.filter(ed => !(ed.from === from && ed.to === to));
            showProps(node); updateStatus(); render();
          });
        });
      }

      function updateStatus() {
        document.getElementById('statusScenes').textContent = nodes.length + ' scenes';
        document.getElementById('statusTransitions').textContent = edges.length + ' transitions';
        document.getElementById('statusMode').textContent = connectMode ? 'Connect' : 'Select';
        document.getElementById('statusZoom').textContent = Math.round(zoom * 100) + '%';
      }

      // \u2500\u2500 Canvas Events \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) {
          isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY;
          canvas.style.cursor = 'grabbing'; return;
        }
        const node = hitTest(e.offsetX, e.offsetY);
        if (connectMode && e.button === 0) {
          if (!connectFrom && node) { connectFrom = node; }
          else if (connectFrom && node && node !== connectFrom) {
            if (!edges.find(ed => ed.from === connectFrom.id && ed.to === node.id)) {
              pushUndo();
              edges.push({ from: connectFrom.id, to: node.id });
            }
            connectFrom = null; updateStatus(); render();
          } else { connectFrom = null; }
          return;
        }
        if (node) {
          selectedNode = node; showProps(node);
          dragNode = node; dragOff = { x: (e.offsetX - offsetX)/zoom - node.x, y: (e.offsetY - offsetY)/zoom - node.y };
        } else { selectedNode = null; showProps(null); }
        render();
      });

      canvas.addEventListener('mousemove', (e) => {
        if (isPanning) { offsetX = e.clientX - panSX; offsetY = e.clientY - panSY; render(); return; }
        if (dragNode) {
          pushUndo();
          dragNode.x = Math.round(((e.offsetX - offsetX) / zoom - dragOff.x) / 20) * 20;
          dragNode.y = Math.round(((e.offsetY - offsetY) / zoom - dragOff.y) / 20) * 20;
          render();
        }
      });

      canvas.addEventListener('mouseup', () => { isPanning = false; dragNode = null; canvas.style.cursor = ''; });

      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const old = zoom;
        zoom *= e.deltaY < 0 ? 1.1 : 0.9;
        zoom = Math.max(0.2, Math.min(4, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / old;
        offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / old;
        updateStatus(); render();
      }, { passive: false });

      // \u2500\u2500 Toolbar \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      document.getElementById('btnAdd').addEventListener('click', () => addNode());
      document.getElementById('btnConnect').addEventListener('click', () => {
        connectMode = !connectMode; connectFrom = null;
        document.getElementById('btnConnect').classList.toggle('active', connectMode);
        updateStatus();
      });
      document.getElementById('btnDelete').addEventListener('click', () => {
        if (!selectedNode) return;
        pushUndo();
        edges = edges.filter(e => e.from !== selectedNode.id && e.to !== selectedNode.id);
        nodes = nodes.filter(n => n !== selectedNode);
        selectedNode = null; showProps(null); updateStatus(); render();
      });
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      document.getElementById('btnAutoLayout').addEventListener('click', () => {
        if (nodes.length === 0) return;
        pushUndo();
        // Simple left-to-right layout by topological order
        const placed = new Set();
        let col = 0;
        function placeFrom(id, row) {
          if (placed.has(id)) return;
          placed.add(id);
          const n = nodes.find(nd => nd.id === id);
          if (!n) return;
          n.x = col * (NODE_W + 60) + 40; n.y = row * (NODE_H + 40) + 40;
          const outs = edges.filter(e => e.from === id);
          outs.forEach((e, i) => { col++; placeFrom(e.to, i); });
        }
        // Start from nodes with no incoming edges
        const hasIncoming = new Set(edges.map(e => e.to));
        const roots = nodes.filter(n => !hasIncoming.has(n.id));
        if (roots.length === 0 && nodes.length > 0) roots.push(nodes[0]);
        roots.forEach((r, i) => { col = 0; placeFrom(r.id, i * 3); });
        // Place any remaining
        nodes.forEach((n, i) => { if (!placed.has(n.id)) { n.x = 40; n.y = (placed.size + i) * (NODE_H + 40) + 40; placed.add(n.id); } });
        render();
      });
      document.getElementById('btnFitView').addEventListener('click', () => {
        if (nodes.length === 0) return;
        let minX=Infinity,minY=Infinity,maxX=-Infinity,maxY=-Infinity;
        for (const n of nodes) { minX=Math.min(minX,n.x); minY=Math.min(minY,n.y); maxX=Math.max(maxX,n.x+NODE_W); maxY=Math.max(maxY,n.y+NODE_H); }
        const pad=60, w=maxX-minX+pad*2, h=maxY-minY+pad*2;
        zoom = Math.min(canvas.width/w, canvas.height/h, 2);
        offsetX = (canvas.width - w*zoom)/2 - minX*zoom + pad*zoom;
        offsetY = (canvas.height - h*zoom)/2 - minY*zoom + pad*zoom;
        updateStatus(); render();
      });

      registerShortcut('a', () => addNode());
      registerShortcut('c', () => { connectMode = !connectMode; connectFrom = null; document.getElementById('btnConnect').classList.toggle('active', connectMode); updateStatus(); });
      registerShortcut('delete', () => document.getElementById('btnDelete').click());
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });

      // \u2500\u2500 Export \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Scene Flow Editor', '-- Usage: lurek.scene.load(scenes)', ''];
        lines.push('return {');
        for (const n of nodes) {
          let line = '  { name = "' + n.name + '"';
          if (n.onEnter) line += ', on_enter = function() ' + n.onEnter + ' end';
          if (n.onExit) line += ', on_exit = function() ' + n.onExit + ' end';
          if (n.onProcess) line += ', on_process = function(dt) ' + n.onProcess + ' end';
          if (n.onRender) line += ', on_render = function() ' + n.onRender + ' end';
          const trans = edges.filter(e => e.from === n.id).map(e => {
            const target = nodes.find(nd => nd.id === e.to);
            return target ? '"' + target.name + '"' : '';
          }).filter(Boolean);
          if (trans.length) line += ', transitions = { ' + trans.join(', ') + ' }';
          line += ' },';
          lines.push(line);
        }
        lines.push('}');
        return lines.join('\\n');
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export Lua File', action: () => vscode.postMessage({ type: 'exportLua', content: buildLuaCode() }) },
        { label: 'Copy Lua Code', action: () => vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() }) },
        { label: 'Insert to Editor', action: () => vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() }) },
      ]);

      document.getElementById('btnCopyLua').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() });
      });

      // \u2500\u2500 Init \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      addNode('Title', 80, 80);
      addNode('Gameplay', 300, 80);
      addNode('GameOver', 520, 80);
      edges.push({ from: 1, to: 2 }, { from: 2, to: 3 });
      undo.clear();
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `)}};var yn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.entity","Entity Designer")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"entities.lua");break}}getHtml(){let e=L();return I(e,"Entity Designer",`
      .editor-layout {
        display: grid; grid-template-columns: 200px 1fr 220px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .entity-list { grid-row: 2; background: var(--surface); border-right: 1px solid var(--border); overflow-y: auto; }
      .component-editor { grid-row: 2; padding: 10px; overflow-y: auto; }
      .preview-panel { grid-row: 2; border-left: 1px solid var(--border); overflow-y: auto; background: var(--surface); }

      .entity-item {
        padding: 5px 10px; cursor: pointer; border-radius: var(--radius); margin: 1px 4px;
        font-size: 12px; display: flex; align-items: center; gap: 6px; transition: background 0.08s;
      }
      .entity-item:hover { background: var(--hover); }
      .entity-item.selected { background: var(--selection); }
      .entity-item .icon { opacity: 0.5; }

      .comp-card {
        background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius);
        margin-bottom: 6px; overflow: hidden;
      }
      .comp-card-header {
        display: flex; align-items: center; justify-content: space-between;
        padding: 5px 8px; background: var(--surface-2); font-size: 11px; font-weight: 600;
        text-transform: uppercase; letter-spacing: 0.3px;
        border-bottom: 1px solid var(--border); cursor: grab;
      }
      .comp-card-header .actions { display: flex; gap: 2px; }
      .comp-card-body { padding: 6px 8px; }
      .comp-card-body .field-row { display: flex; align-items: center; gap: 4px; margin-bottom: 3px; }
      .comp-card-body .field-row label { font-size: 10px; width: 70px; text-align: right; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.3px; }
      .comp-card-body .field-row input[type=text],
      .comp-card-body .field-row input[type=number] { flex: 1; }
      .comp-card-body .field-row select { flex: 1; }

      .template-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 4px; }
      .template-grid button { font-size: 11px; padding: 6px 4px; text-align: center; }

      .preview-canvas-wrap {
        background: var(--bg); border: 1px solid var(--border); border-radius: var(--radius);
        margin: 0 8px; overflow: hidden; aspect-ratio: 1;
      }
      .preview-canvas-wrap canvas { display: block; width: 100%; height: 100%; }

      .stat-row { display: flex; justify-content: space-between; font-size: 10px; padding: 2px 0; color: var(--text-dim); }
      .stat-row .val { color: var(--text); font-family: var(--font-mono); }
    `,`
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            ${g("add",{id:"btnNewEntity",title:"New Entity (N)"})}
            ${g("copy",{id:"btnDuplicate",title:"Duplicate (Ctrl+D)"})}
            ${g("trash",{id:"btnDeleteEntity",title:"Delete Entity (Del)",cls:"danger"})}
          </div>
          ${k()}
          <div class="group">
            ${g("undo",{id:"btnUndo",title:"Undo (Ctrl+Z)"})}
            ${g("redo",{id:"btnRedo",title:"Redo (Ctrl+Y)"})}
          </div>
          ${A()}
          <div class="group">
            ${g("copy",{id:"btnCopyLua",title:"Copy Lua Code"})}
            ${g("insert",{id:"btnInsert",title:"Insert to Editor"})}
          </div>
          ${k()}
          <button id="btnExport" class="primary">${c.exportFile} Export \u25BE</button>
        </div>

        <!-- Entity List -->
        <div class="entity-list">
          ${b("Entities",'<div id="entityList"></div>')}
          ${b("Templates",`
            <div class="template-grid">
              <button data-tpl="player">${c.entity} Player</button>
              <button data-tpl="enemy">${c.entity} Enemy</button>
              <button data-tpl="pickup">${c.entity} Pickup</button>
              <button data-tpl="projectile">${c.entity} Projectile</button>
              <button data-tpl="npc">${c.entity} NPC</button>
              <button data-tpl="trigger">${c.entity} Trigger</button>
            </div>
          `,!0)}
        </div>

        <!-- Component Editor (center) -->
        <div class="component-editor" id="compEditor">
          <p style="color:var(--text-dim); text-align:center; margin-top:40px;">Select or create an entity to begin editing.</p>
        </div>

        <!-- Preview Panel -->
        <div class="preview-panel">
          ${b("Preview",`
            <div class="preview-canvas-wrap"><canvas id="previewCanvas" width="180" height="180"></canvas></div>
          `)}
          ${b("Stats",'<div id="statsArea"></div>')}
          ${b("Quick Add",`
            <select id="addCompSelect" style="width:100%; margin-bottom:4px;">
              <option value="">Add Component...</option>
            </select>
          `,!0)}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusEntCount" class="badge">0 entities</span>
          </span>
          <div class="sep"></div>
          <span id="statusCompCount">0 components</span>
          <div class="spacer"></div>
          <span id="statusSelected">None selected</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${c.clean}</span>
        </div>
      </div>
    `,`
      // \u2500\u2500 Component Definitions \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      const COMPONENT_DEFS = {
        Transform: { x: 0, y: 0, rotation: 0, scaleX: 1, scaleY: 1 },
        Sprite:    { image: '', width: 32, height: 32, color: '#ffffff', layer: 0 },
        Physics:   { bodyType: 'dynamic', mass: 1, friction: 0.3, restitution: 0.2, fixedRotation: false },
        Collider:  { shape: 'rectangle', width: 32, height: 32, isSensor: false },
        AI:        { behavior: 'idle', speed: 100, detectionRange: 200, attackRange: 50 },
        Health:    { maxHp: 100, currentHp: 100, invincible: false },
        Tag:       { tag: '' },
        Custom:    { key: '', value: '' },
      };

      const TEMPLATES = {
        player:     { name: 'Player', components: { Transform: {...COMPONENT_DEFS.Transform}, Sprite: {...COMPONENT_DEFS.Sprite, width:32, height:48, color:'#4ec9b0'}, Physics: {...COMPONENT_DEFS.Physics}, Collider: {...COMPONENT_DEFS.Collider, height:48}, Health: {...COMPONENT_DEFS.Health} }},
        enemy:      { name: 'Enemy', components: { Transform: {...COMPONENT_DEFS.Transform}, Sprite: {...COMPONENT_DEFS.Sprite, color:'#f44336'}, Physics: {...COMPONENT_DEFS.Physics}, Collider: {...COMPONENT_DEFS.Collider}, AI: {...COMPONENT_DEFS.AI, behavior:'chase'}, Health: {...COMPONENT_DEFS.Health, maxHp:50, currentHp:50} }},
        pickup:     { name: 'Pickup', components: { Transform: {...COMPONENT_DEFS.Transform}, Sprite: {...COMPONENT_DEFS.Sprite, width:16, height:16, color:'#ffeb3b'}, Collider: {...COMPONENT_DEFS.Collider, width:16, height:16, isSensor:true} }},
        projectile: { name: 'Projectile', components: { Transform: {...COMPONENT_DEFS.Transform}, Sprite: {...COMPONENT_DEFS.Sprite, width:8, height:8, color:'#ff9800'}, Physics: {...COMPONENT_DEFS.Physics, mass:0.1}, Collider: {...COMPONENT_DEFS.Collider, width:8, height:8} }},
        npc:        { name: 'NPC', components: { Transform: {...COMPONENT_DEFS.Transform}, Sprite: {...COMPONENT_DEFS.Sprite, width:32, height:48, color:'#89b4fa'}, AI: {...COMPONENT_DEFS.AI, behavior:'idle'}, Health: {...COMPONENT_DEFS.Health, maxHp:80, currentHp:80}, Tag: { tag: 'npc' } }},
        trigger:    { name: 'Trigger', components: { Transform: {...COMPONENT_DEFS.Transform}, Collider: {...COMPONENT_DEFS.Collider, width:64, height:64, isSensor:true}, Tag: { tag: 'trigger' } }},
      };

      const COMP_COLORS = {
        Transform: '#89b4fa', Sprite: '#a6e3a1', Physics: '#fab387', Collider: '#f9e2af',
        AI: '#cba6f7', Health: '#f38ba8', Tag: '#94e2d5', Custom: '#9399b2',
      };

      let entities = [], selectedIdx = -1;
      const undo = new UndoStack(80);

      function snapshot() { return JSON.parse(JSON.stringify({ entities, selectedIdx })); }
      function restore(s) { entities = s.entities; selectedIdx = s.selectedIdx; refreshAll(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      function createEntity(name, comps) {
        pushUndo();
        entities.push({ name: name || 'Entity_' + entities.length, components: comps || { Transform: {...COMPONENT_DEFS.Transform} } });
        selectedIdx = entities.length - 1;
        refreshAll();
      }

      // \u2500\u2500 List Rendering \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function refreshList() {
        const el = document.getElementById('entityList');
        el.innerHTML = '';
        entities.forEach((ent, i) => {
          const div = document.createElement('div');
          div.className = 'entity-item' + (i === selectedIdx ? ' selected' : '');
          const compCount = Object.keys(ent.components).length;
          div.innerHTML = '<span class="icon">${c.entity}</span><span style="flex:1">' + ent.name + '</span><span style="font-size:10px;color:var(--text-dim)">' + compCount + '</span>';
          div.addEventListener('click', () => { selectedIdx = i; refreshAll(); });
          el.appendChild(div);
        });
      }

      // \u2500\u2500 Component Editor \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function refreshEditor() {
        const el = document.getElementById('compEditor');
        if (selectedIdx < 0 || selectedIdx >= entities.length) {
          el.innerHTML = '<p style="color:var(--text-dim); text-align:center; margin-top:40px;">Select or create an entity.</p>';
          return;
        }
        const ent = entities[selectedIdx];
        let html = '<div class="comp-card"><div class="comp-card-header">Identity</div><div class="comp-card-body">';
        html += '<div class="field-row"><label>Name</label><input id="entName" type="text" value="' + ent.name + '"></div>';
        html += '</div></div>';

        // Add component dropdown
        const addSel = document.getElementById('addCompSelect');
        if (addSel) {
          addSel.innerHTML = '<option value="">Add Component...</option>';
          for (const k in COMPONENT_DEFS) {
            if (!ent.components[k]) addSel.innerHTML += '<option value="' + k + '">' + k + '</option>';
          }
        }

        for (const [name, data] of Object.entries(ent.components)) {
          const clr = COMP_COLORS[name] || '#9399b2';
          html += '<div class="comp-card"><div class="comp-card-header"><span style="display:flex;align-items:center;gap:4px"><span style="display:inline-block;width:8px;height:8px;border-radius:50%;background:' + clr + '"></span>' + name + '</span>';
          html += '<span class="actions"><button class="icon-btn" data-remove="' + name + '" title="Remove">${c.trash}</button></span></div>';
          html += '<div class="comp-card-body">';
          for (const [key, val] of Object.entries(data)) {
            if (typeof val === 'boolean') {
              html += '<div class="field-row"><label>' + key + '</label><input type="checkbox" data-comp="' + name + '" data-key="' + key + '" ' + (val ? 'checked' : '') + '></div>';
            } else if (key === 'bodyType') {
              html += '<div class="field-row"><label>' + key + '</label><select data-comp="' + name + '" data-key="' + key + '"><option value="dynamic"' + (val==='dynamic'?' selected':'') + '>Dynamic</option><option value="static"' + (val==='static'?' selected':'') + '>Static</option><option value="kinematic"' + (val==='kinematic'?' selected':'') + '>Kinematic</option></select></div>';
            } else if (key === 'shape') {
              html += '<div class="field-row"><label>' + key + '</label><select data-comp="' + name + '" data-key="' + key + '"><option value="rectangle"' + (val==='rectangle'?' selected':'') + '>Rectangle</option><option value="circle"' + (val==='circle'?' selected':'') + '>Circle</option></select></div>';
            } else if (key === 'behavior') {
              html += '<div class="field-row"><label>' + key + '</label><select data-comp="' + name + '" data-key="' + key + '"><option value="idle"' + (val==='idle'?' selected':'') + '>Idle</option><option value="chase"' + (val==='chase'?' selected':'') + '>Chase</option><option value="patrol"' + (val==='patrol'?' selected':'') + '>Patrol</option><option value="flee"' + (val==='flee'?' selected':'') + '>Flee</option></select></div>';
            } else if (key === 'color') {
              html += '<div class="field-row"><label>' + key + '</label><input type="color" data-comp="' + name + '" data-key="' + key + '" value="' + val + '" style="width:28px;height:22px;border:1px solid var(--border);border-radius:var(--radius);padding:0"></div>';
            } else {
              const t = typeof val === 'number' ? 'number' : 'text';
              html += '<div class="field-row"><label>' + key + '</label><input type="' + t + '" data-comp="' + name + '" data-key="' + key + '" value="' + val + '"></div>';
            }
          }
          html += '</div></div>';
        }
        el.innerHTML = html;

        // Bindings
        document.getElementById('entName').addEventListener('input', (e) => { pushUndo(); ent.name = e.target.value; refreshList(); updateStatus(); });
        el.querySelectorAll('[data-remove]').forEach(btn => {
          btn.addEventListener('click', (e) => { pushUndo(); delete ent.components[e.currentTarget.dataset.remove]; refreshAll(); });
        });
        el.querySelectorAll('[data-comp]').forEach(inp => {
          const handler = (e) => {
            pushUndo();
            const comp = e.target.dataset.comp, key = e.target.dataset.key;
            const orig = COMPONENT_DEFS[comp] && COMPONENT_DEFS[comp][key];
            if (e.target.type === 'checkbox') ent.components[comp][key] = e.target.checked;
            else if (typeof orig === 'number') ent.components[comp][key] = parseFloat(e.target.value) || 0;
            else ent.components[comp][key] = e.target.value;
            refreshPreview();
          };
          inp.addEventListener(inp.type === 'checkbox' || inp.tagName === 'SELECT' ? 'change' : 'input', handler);
        });
      }

      // \u2500\u2500 Preview \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function refreshPreview() {
        const canvas = document.getElementById('previewCanvas');
        const ctx = canvas.getContext('2d');
        ctx.clearRect(0, 0, 180, 180);

        // Grid
        ctx.strokeStyle = 'rgba(137,180,250,0.08)'; ctx.lineWidth = 1;
        for (let i = 0; i <= 180; i += 18) { ctx.beginPath(); ctx.moveTo(i, 0); ctx.lineTo(i, 180); ctx.stroke(); ctx.beginPath(); ctx.moveTo(0, i); ctx.lineTo(180, i); ctx.stroke(); }

        if (selectedIdx < 0 || selectedIdx >= entities.length) return;
        const ent = entities[selectedIdx];

        // Origin
        ctx.strokeStyle = 'rgba(137,180,250,0.3)'; ctx.lineWidth = 0.5;
        ctx.beginPath(); ctx.moveTo(90, 0); ctx.lineTo(90, 180); ctx.stroke();
        ctx.beginPath(); ctx.moveTo(0, 90); ctx.lineTo(180, 90); ctx.stroke();

        const sprite = ent.components.Sprite;
        if (sprite) {
          ctx.fillStyle = sprite.color || '#ccc';
          ctx.fillRect(90 - sprite.width/2, 90 - sprite.height/2, sprite.width, sprite.height);
        }
        const collider = ent.components.Collider;
        if (collider) {
          ctx.strokeStyle = collider.isSensor ? '#f9e2af' : '#a6e3a1';
          ctx.lineWidth = 1.5; ctx.setLineDash([4, 3]);
          if (collider.shape === 'circle') {
            ctx.beginPath(); ctx.arc(90, 90, collider.width/2, 0, Math.PI*2); ctx.stroke();
          } else {
            ctx.strokeRect(90 - collider.width/2, 90 - collider.height/2, collider.width, collider.height);
          }
          ctx.setLineDash([]);
        }
        if (ent.components.AI && ent.components.AI.detectionRange) {
          ctx.strokeStyle = 'rgba(203,166,247,0.2)'; ctx.lineWidth = 1; ctx.setLineDash([2, 4]);
          ctx.beginPath(); ctx.arc(90, 90, Math.min(ent.components.AI.detectionRange/2, 85), 0, Math.PI*2); ctx.stroke();
          ctx.setLineDash([]);
        }

        updateStatus();
      }

      function updateStatus() {
        const ent = selectedIdx >= 0 && selectedIdx < entities.length ? entities[selectedIdx] : null;
        const compCount = ent ? Object.keys(ent.components).length : 0;
        document.getElementById('statusEntCount').textContent = entities.length + ' entities';
        document.getElementById('statusCompCount').textContent = compCount + ' components';
        document.getElementById('statusSelected').textContent = ent ? ent.name : 'None selected';

        const statsEl = document.getElementById('statsArea');
        if (ent) {
          let html = '';
          html += '<div class="stat-row"><span>Components</span><span class="val">' + compCount + '</span></div>';
          html += '<div class="stat-row"><span>Physics</span><span class="val">' + (ent.components.Physics ? ent.components.Physics.bodyType : '\u2014') + '</span></div>';
          html += '<div class="stat-row"><span>AI</span><span class="val">' + (ent.components.AI ? ent.components.AI.behavior : '\u2014') + '</span></div>';
          html += '<div class="stat-row"><span>Health</span><span class="val">' + (ent.components.Health ? ent.components.Health.currentHp + '/' + ent.components.Health.maxHp : '\u2014') + '</span></div>';
          html += '<div class="stat-row"><span>Sensor</span><span class="val">' + (ent.components.Collider && ent.components.Collider.isSensor ? 'Yes' : 'No') + '</span></div>';
          statsEl.innerHTML = html;
        } else { statsEl.innerHTML = ''; }
      }

      function refreshAll() { refreshList(); refreshEditor(); refreshPreview(); }

      // \u2500\u2500 Toolbar \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      document.getElementById('btnNewEntity').addEventListener('click', () => createEntity());
      document.getElementById('btnDuplicate').addEventListener('click', () => {
        if (selectedIdx < 0) return;
        const src = entities[selectedIdx];
        createEntity(src.name + '_copy', JSON.parse(JSON.stringify(src.components)));
      });
      document.getElementById('btnDeleteEntity').addEventListener('click', () => {
        if (selectedIdx < 0) return;
        pushUndo();
        entities.splice(selectedIdx, 1);
        selectedIdx = Math.min(selectedIdx, entities.length - 1);
        refreshAll();
      });
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restore(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restore(s); });
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restore(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restore(s); });
      registerShortcut('n', () => createEntity());
      registerShortcut('delete', () => {
        if (selectedIdx < 0) return;
        pushUndo(); entities.splice(selectedIdx, 1);
        selectedIdx = Math.min(selectedIdx, entities.length - 1);
        refreshAll();
      });

      document.querySelectorAll('[data-tpl]').forEach(btn => {
        btn.addEventListener('click', (e) => {
          const tpl = TEMPLATES[e.currentTarget.dataset.tpl];
          if (tpl) createEntity(tpl.name, JSON.parse(JSON.stringify(tpl.components)));
        });
      });

      document.getElementById('addCompSelect').addEventListener('change', (e) => {
        if (selectedIdx < 0 || !e.target.value) return;
        if (COMPONENT_DEFS[e.target.value]) {
          pushUndo();
          entities[selectedIdx].components[e.target.value] = {...COMPONENT_DEFS[e.target.value]};
          refreshAll();
        }
        e.target.value = '';
      });

      // \u2500\u2500 Export \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Entity Designer', '-- Usage: local factory = require("entities")', ''];
        lines.push('local entities = {}');
        lines.push('');
        for (const ent of entities) {
          const fn = ent.name.replace(/[^a-zA-Z0-9_]/g, '');
          lines.push('function entities.create_' + fn + '(x, y)');
          lines.push('  local e = lurek.ecs.spawn()');
          for (const [comp, data] of Object.entries(ent.components)) {
            lines.push('  lurek.ecs.addComponent(e, "' + comp.toLowerCase() + '", {');
            for (const [k, v] of Object.entries(data)) {
              if (comp === 'Transform' && (k === 'x' || k === 'y')) {
                lines.push('    ' + k + ' = ' + (k === 'x' ? 'x or 0' : 'y or 0') + ',');
              } else if (typeof v === 'string') {
                lines.push('    ' + k + ' = "' + v + '",');
              } else if (typeof v === 'boolean') {
                lines.push('    ' + k + ' = ' + v + ',');
              } else {
                lines.push('    ' + k + ' = ' + v + ',');
              }
            }
            lines.push('  })');
          }
          lines.push('  return e');
          lines.push('end');
          lines.push('');
        }
        lines.push('return entities');
        return lines.join('\\n');
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export Lua File', action: () => vscode.postMessage({ type: 'exportLua', content: buildLuaCode() }) },
        { label: 'Copy Lua Code', action: () => vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() }) },
        { label: 'Insert to Editor', action: () => vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() }) },
      ]);

      document.getElementById('btnCopyLua').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() });
      });

      // \u2500\u2500 Init \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      refreshAll();
    `)}};var fn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.pixelArt","Pixel Art Editor")}handleMessage(e){switch(e.type){case"exportPng":this.exportFile(e.content,"sprite.png","PNG Image","png");break;case"exportSpriteSheet":this.exportFile(e.content,"spritesheet.png","PNG Image","png");break}}getHtml(){let e=L();return I(e,"Pixel Art Editor",`
      .editor-layout {
        display: grid;
        grid-template-columns: 38px 1fr 220px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .canvas-area {
        grid-row: 2; position: relative; overflow: hidden;
        background: var(--bg);
      }
      .canvas-area canvas { display: block; image-rendering: pixelated; }
      .properties { grid-row: 2; background: var(--surface); border-left: 1px solid var(--border); overflow-y: auto; }

      /* Color section */
      .color-wells {
        display: flex; gap: 4px; margin-bottom: 8px; align-items: center;
      }
      .color-well {
        width: 30px; height: 30px; border: 2px solid var(--border);
        border-radius: var(--radius); cursor: pointer; position: relative;
        transition: border-color 0.12s;
      }
      .color-well.active { border-color: var(--accent); }
      .color-well .label {
        position: absolute; bottom: -1px; right: -1px;
        font-size: 8px; background: var(--surface-2); color: var(--text-dim);
        padding: 0 3px; border-radius: 2px 0 2px 0; line-height: 1.4;
      }
      .swap-btn { background: none; border: none; color: var(--text-dim); cursor: pointer; padding: 2px; font-size: 14px; }
      .swap-btn:hover { color: var(--text-bright); background: transparent; border: none; }

      .palette-grid {
        display: grid; grid-template-columns: repeat(8, 1fr); gap: 1px;
      }
      .palette-grid .swatch {
        aspect-ratio: 1; cursor: pointer; border-radius: 2px;
        border: 1px solid transparent; transition: border-color 0.1s, transform 0.1s;
      }
      .palette-grid .swatch:hover { border-color: var(--text); transform: scale(1.15); z-index: 1; }
      .palette-grid .swatch.selected { border-color: var(--accent); border-width: 2px; }

      /* Layer list */
      .layer-item {
        display: flex; align-items: center; gap: 4px; padding: 3px 6px;
        font-size: 11px; cursor: pointer; border-radius: var(--radius);
        transition: background 0.08s;
      }
      .layer-item:hover { background: var(--hover); }
      .layer-item.sel { background: var(--selection); }
      .layer-item .vis-btn {
        width: 18px; height: 18px; background: none; border: none;
        cursor: pointer; color: var(--text-dim); padding: 0;
        display: flex; align-items: center; justify-content: center;
      }
      .layer-item .vis-btn:hover { color: var(--accent); background: transparent; border: none; }
      .layer-item .vis-btn svg { width: 12px; height: 12px; }
      .layer-item .name { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
      .layer-actions { display: flex; gap: 2px; margin-bottom: 4px; }
      .layer-actions button { flex: 1; font-size: 10px; padding: 3px 0; }

      /* Frame strip */
      .frame-strip {
        display: flex; gap: 3px; overflow-x: auto; padding: 2px 0;
      }
      .frame-thumb {
        width: 36px; height: 36px; border: 1px solid var(--border); cursor: pointer;
        border-radius: var(--radius); background: var(--bg); display: flex;
        align-items: center; justify-content: center; flex-shrink: 0;
        font-size: 9px; color: var(--text-dim); transition: border-color 0.1s;
        image-rendering: pixelated; position: relative;
      }
      .frame-thumb:hover { border-color: var(--text); }
      .frame-thumb.sel { border-color: var(--accent); border-width: 2px; }
      .frame-actions { display: flex; gap: 2px; margin-top: 4px; }
      .frame-actions button { flex: 1; font-size: 10px; padding: 3px 0; }

      /* Preview */
      .preview-wrap {
        background: var(--bg); border: 1px solid var(--border); border-radius: var(--radius);
        padding: 4px; display: flex; align-items: center; justify-content: center;
      }
      .preview-wrap canvas { image-rendering: pixelated; width: 100%; height: auto; }

      /* Symmetry indicator */
      .symmetry-indicator {
        display: flex; gap: 4px; font-size: 10px; align-items: center;
      }
      .symmetry-indicator button { font-size: 10px; padding: 2px 6px; }
    `,`
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            <label>Size</label>
            <select id="sizeSelect">
              <option value="8">8\xD78</option>
              <option value="16" selected>16\xD716</option>
              <option value="32">32\xD732</option>
              <option value="64">64\xD764</option>
              <option value="128">128\xD7128</option>
            </select>
          </div>
          ${k()}
          <div class="group">
            ${g("undo",{id:"btnUndo",title:"Undo (Ctrl+Z)"})}
            ${g("redo",{id:"btnRedo",title:"Redo (Ctrl+Y)"})}
          </div>
          ${k()}
          <div class="group">
            ${g("grid",{id:"btnGrid",title:"Toggle Grid",className:"active"})}
          </div>
          <div class="group symmetry-indicator">
            <label>Mirror:</label>
            <button id="btnMirrorH" title="Mirror Horizontal" data-tooltip="Mirror H">H</button>
            <button id="btnMirrorV" title="Mirror Vertical" data-tooltip="Mirror V">V</button>
          </div>
          ${A()}
          <div class="group">
            ${g("copy",{id:"btnCopyLua",title:"Copy Lua Code"})}
            ${g("insert",{id:"btnInsert",title:"Insert to Editor"})}
          </div>
          ${k()}
          <button id="btnExport" class="primary">${c.exportFile} Export \u25BE</button>
        </div>

        <!-- Tool Rail -->
        <div class="tool-rail" id="tools">
          <div class="tool-group">
            <button class="icon-btn active" data-tool="pen" title="Pen (B)" data-tooltip="Pen">${c.pen}</button>
            <button class="icon-btn" data-tool="eraser" title="Eraser (E)" data-tooltip="Eraser">${c.eraser}</button>
            <button class="icon-btn" data-tool="bucket" title="Fill (G)" data-tooltip="Fill">${c.bucket}</button>
          </div>
          <div class="tool-group">
            <button class="icon-btn" data-tool="rect" title="Rectangle (R)" data-tooltip="Rectangle">${c.rect}</button>
            <button class="icon-btn" data-tool="line" title="Line (L)" data-tooltip="Line">${c.line}</button>
            <button class="icon-btn" data-tool="select" title="Select (M)" data-tooltip="Select">${c.select}</button>
          </div>
          <div class="tool-group">
            <button class="icon-btn" data-tool="pick" title="Color Pick (I)" data-tooltip="Pick">${c.pick}</button>
            <button class="icon-btn" data-tool="hand" title="Pan (H / Middle Mouse)" data-tooltip="Pan">${c.hand}</button>
          </div>
        </div>

        <!-- Canvas -->
        <div class="canvas-area"><canvas id="artCanvas"></canvas></div>

        <!-- Properties Panel -->
        <div class="properties">
          ${b("Color",`
            <div class="color-wells">
              <div class="color-well active" id="leftColor" title="Primary color (left click)">
                <span class="label">L</span>
              </div>
              <button class="swap-btn" id="btnSwapColor" title="Swap colors (X)">\u21C4</button>
              <div class="color-well" id="rightColor" title="Secondary color (right click)">
                <span class="label">R</span>
              </div>
            </div>
            ${N("Hex",'<input id="hexInput" value="#000000" maxlength="7" style="width:100%">')}
            ${N("Opacity",'<input type="range" id="opacitySlider" min="0" max="100" value="100" style="width:100%"><span id="opacityVal" style="width:28px;text-align:right;font-size:10px;color:var(--text-dim)">100%</span>')}
          `)}
          ${b("Palette",`
            <div class="palette-grid" id="palette"></div>
          `)}
          ${b("Layers",`
            <div class="layer-actions">
              <button id="btnAddLayer">${c.add} Add</button>
              <button id="btnDelLayer">${c.trash} Del</button>
              <button id="btnMoveLayerUp">${c.moveUp}</button>
              <button id="btnMoveLayerDown">${c.moveDown}</button>
            </div>
            <div id="layerList"></div>
          `)}
          ${b("Animation",`
            <div class="frame-strip" id="frameStrip"></div>
            <div class="frame-actions">
              <button id="btnAddFrame">${c.add} Frame</button>
              <button id="btnDupFrame">${c.copy} Dup</button>
              <button id="btnDelFrame">${c.trash}</button>
            </div>
            <div style="margin-top:6px">
              ${N("FPS",'<input type="number" id="fpsInput" value="8" min="1" max="60" style="width:50px">')}
              <div style="display:flex;gap:4px;margin-top:4px">
                <button id="btnPlay" style="flex:1">${c.play} Play</button>
                <button id="btnOnionSkin" style="flex:1" data-tooltip="Onion skin">${c.eye} Onion</button>
              </div>
            </div>
          `)}
          ${b("Preview",`
            <div class="preview-wrap">
              <canvas id="previewCanvas" width="64" height="64"></canvas>
            </div>
            <div style="display:flex;gap:4px;margin-top:4px">
              <button id="btnPreviewBg" style="flex:1;font-size:10px">BG: Checker</button>
            </div>
          `)}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusPos">0, 0</span>
          </span>
          <div class="sep"></div>
          <span id="statusTool">Pen</span>
          <div class="sep"></div>
          <span id="statusSize">16\xD716</span>
          <div class="spacer"></div>
          <span class="status-group">
            <span id="statusFrameInfo">Frame 1/1</span>
            <div class="sep"></div>
            <span id="statusLayerInfo">Layer 1/1</span>
          </span>
          <div class="sep"></div>
          <span class="dirty-indicator">${c.clean}</span>
        </div>
      </div>
    `,`
      // \u2500\u2500 Constants \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      const PICO8 = [
        '#000000','#1d2b53','#7e2553','#008751','#ab5236','#5f574f','#c2c3c7','#fff1e8',
        '#ff004d','#ffa300','#ffec27','#00e436','#29adff','#83769c','#ff77a8','#ffccaa'
      ];
      const ENDESGA32 = [
        '#be4a2f','#d77643','#ead4aa','#e4a672','#b86f50','#733e39','#3e2731','#a22633',
        '#e43b44','#f77622','#feae34','#fee761','#63c74d','#3e8948','#265c42','#193c3e',
        '#124e89','#0099db','#2ce8f5','#ffffff','#c0cbdc','#8b9bb4','#5a6988','#3a4466',
        '#262b44','#181425','#ff0044','#68386c','#b55088','#f6757a','#e8b796','#c28569'
      ];

      // \u2500\u2500 State \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      const canvas = document.getElementById('artCanvas');
      const ctx = canvas.getContext('2d');
      const previewCanvas = document.getElementById('previewCanvas');
      const previewCtx = previewCanvas.getContext('2d');
      const undoStack = new UndoStack(100);

      let gridSize = 16, currentTool = 'pen';
      let leftColor = '#1d2b53', rightColor = '#ffffff';
      let layers = [{ name: 'Background', visible: true, data: null }];
      let currentLayer = 0;
      let frames = [null];
      let currentFrame = 0, playing = false, animTimer = null, fps = 8;
      let offsetX = 0, offsetY = 0, zoom = 16;
      let showGrid = true, showOnionSkin = false;
      let mirrorH = false, mirrorV = false;
      let isPanning = false, panSX = 0, panSY = 0;
      let isDrawing = false, lineStartX = -1, lineStartY = -1;
      let previewBg = 'checker'; // checker, black, white, transparent
      let selecting = false, selection = null; // {x,y,w,h}

      function initData() {
        for (const l of layers) l.data = new Array(gridSize * gridSize).fill(null);
        frames = [null]; currentFrame = 0;
      }
      initData();

      function getState() {
        return { layers: layers.map(l => ({ ...l, data: [...l.data] })), currentLayer };
      }
      function pushUndo() {
        undoStack.push(getState());
        markDirty();
      }

      // \u2500\u2500 Undo / Redo wiring \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      undoStack.onChange((canUndo, canRedo) => {
        document.getElementById('btnUndo').disabled = !canUndo;
        document.getElementById('btnRedo').disabled = !canRedo;
      });

      document.getElementById('btnUndo').addEventListener('click', () => {
        const prev = undoStack.undo();
        if (prev) { restoreState(prev); render(); }
      });
      document.getElementById('btnRedo').addEventListener('click', () => {
        const next = undoStack.redo();
        if (next) { restoreState(next); render(); }
      });

      function restoreState(state) {
        state.layers.forEach((sl, i) => {
          if (layers[i]) { layers[i].data = sl.data; layers[i].name = sl.name; layers[i].visible = sl.visible; }
        });
        currentLayer = state.currentLayer;
        refreshLayers();
      }

      // Push initial state
      undoStack.push(getState());

      // \u2500\u2500 Canvas Rendering \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight;
        render();
      }

      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.save(); ctx.translate(offsetX, offsetY);
        const pxSize = zoom;
        const totalPx = gridSize * pxSize;

        // Checkerboard background
        for (let y = 0; y < gridSize; y++) {
          for (let x = 0; x < gridSize; x++) {
            ctx.fillStyle = ((x + y) % 2 === 0) ? '#2a2a3d' : '#232334';
            ctx.fillRect(x * pxSize, y * pxSize, pxSize, pxSize);
          }
        }

        // Onion skin (previous frame ghost)
        if (showOnionSkin && currentFrame > 0 && frames[currentFrame - 1]) {
          ctx.globalAlpha = 0.25;
          const prevData = frames[currentFrame - 1];
          for (let li = 0; li < prevData.length; li++) {
            if (!layers[li] || !layers[li].visible) continue;
            for (let y = 0; y < gridSize; y++)
              for (let x = 0; x < gridSize; x++) {
                const c = prevData[li][y * gridSize + x];
                if (c) { ctx.fillStyle = c; ctx.fillRect(x * pxSize, y * pxSize, pxSize, pxSize); }
              }
          }
          ctx.globalAlpha = 1;
        }

        // Layers
        for (let li = 0; li < layers.length; li++) {
          const l = layers[li];
          if (!l.visible) continue;
          for (let y = 0; y < gridSize; y++) {
            for (let x = 0; x < gridSize; x++) {
              const c = l.data[y * gridSize + x];
              if (c) { ctx.fillStyle = c; ctx.fillRect(x * pxSize, y * pxSize, pxSize, pxSize); }
            }
          }
        }

        // Grid overlay
        if (showGrid && zoom >= 6) {
          ctx.strokeStyle = 'rgba(255,255,255,0.06)';
          ctx.lineWidth = 0.5;
          for (let x = 0; x <= gridSize; x++) { ctx.beginPath(); ctx.moveTo(x * pxSize, 0); ctx.lineTo(x * pxSize, totalPx); ctx.stroke(); }
          for (let y = 0; y <= gridSize; y++) { ctx.beginPath(); ctx.moveTo(0, y * pxSize); ctx.lineTo(totalPx, y * pxSize); ctx.stroke(); }
        }

        // Border around sprite
        ctx.strokeStyle = 'rgba(137,180,250,0.3)';
        ctx.lineWidth = 1;
        ctx.strokeRect(-0.5, -0.5, totalPx + 1, totalPx + 1);

        // Selection overlay
        if (selection) {
          ctx.strokeStyle = 'var(--accent, #89b4fa)';
          ctx.lineWidth = 1;
          ctx.setLineDash([4, 4]);
          ctx.strokeRect(selection.x * pxSize, selection.y * pxSize, selection.w * pxSize, selection.h * pxSize);
          ctx.setLineDash([]);
        }

        // Mirror guide lines
        if (mirrorH) {
          ctx.strokeStyle = 'rgba(166,227,161,0.4)'; ctx.lineWidth = 1;
          ctx.beginPath(); ctx.moveTo(totalPx / 2, 0); ctx.lineTo(totalPx / 2, totalPx); ctx.stroke();
        }
        if (mirrorV) {
          ctx.strokeStyle = 'rgba(249,226,175,0.4)'; ctx.lineWidth = 1;
          ctx.beginPath(); ctx.moveTo(0, totalPx / 2); ctx.lineTo(totalPx, totalPx / 2); ctx.stroke();
        }

        ctx.restore();
        renderPreview();
      }

      function renderPreview() {
        const sz = 64;
        previewCtx.clearRect(0, 0, sz, sz);
        if (previewBg === 'checker') {
          const s = sz / gridSize;
          for (let y = 0; y < gridSize; y++) for (let x = 0; x < gridSize; x++) {
            previewCtx.fillStyle = ((x+y)%2===0) ? '#2a2a3d' : '#232334';
            previewCtx.fillRect(x*s, y*s, s, s);
          }
        } else if (previewBg === 'black') {
          previewCtx.fillStyle = '#000'; previewCtx.fillRect(0,0,sz,sz);
        } else if (previewBg === 'white') {
          previewCtx.fillStyle = '#fff'; previewCtx.fillRect(0,0,sz,sz);
        }
        const s = sz / gridSize;
        for (const l of layers) {
          if (!l.visible) continue;
          for (let y = 0; y < gridSize; y++)
            for (let x = 0; x < gridSize; x++) {
              const c = l.data[y * gridSize + x];
              if (c) { previewCtx.fillStyle = c; previewCtx.fillRect(x*s, y*s, s, s); }
            }
        }
      }

      // \u2500\u2500 Pixel Operations \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function screenToPixel(sx, sy) {
        return { x: Math.floor((sx - offsetX) / zoom), y: Math.floor((sy - offsetY) / zoom) };
      }

      function setPixel(x, y, color) {
        if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
          layers[currentLayer].data[y * gridSize + x] = color;
          // Symmetry
          if (mirrorH) {
            const mx = gridSize - 1 - x;
            if (mx >= 0 && mx < gridSize) layers[currentLayer].data[y * gridSize + mx] = color;
          }
          if (mirrorV) {
            const my = gridSize - 1 - y;
            if (my >= 0 && my < gridSize) layers[currentLayer].data[my * gridSize + x] = color;
          }
          if (mirrorH && mirrorV) {
            const mx = gridSize - 1 - x, my = gridSize - 1 - y;
            if (mx >= 0 && mx < gridSize && my >= 0 && my < gridSize)
              layers[currentLayer].data[my * gridSize + mx] = color;
          }
        }
      }

      function getPixel(x, y) {
        if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) return layers[currentLayer].data[y * gridSize + x];
        return undefined;
      }

      function floodFill(x, y, target, fill) {
        if (target === fill) return;
        const stack = [[x, y]];
        const visited = new Set();
        while (stack.length) {
          const [cx, cy] = stack.pop();
          const key = cx + ',' + cy;
          if (visited.has(key)) continue;
          visited.add(key);
          if (cx < 0 || cx >= gridSize || cy < 0 || cy >= gridSize) continue;
          if (getPixel(cx, cy) !== target) continue;
          setPixel(cx, cy, fill);
          stack.push([cx-1,cy],[cx+1,cy],[cx,cy-1],[cx,cy+1]);
        }
      }

      function drawLine(x0, y0, x1, y1, color) {
        const dx = Math.abs(x1 - x0), dy = Math.abs(y1 - y0);
        const sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1;
        let err = dx - dy;
        while (true) {
          setPixel(x0, y0, color);
          if (x0 === x1 && y0 === y1) break;
          const e2 = 2 * err;
          if (e2 > -dy) { err -= dy; x0 += sx; }
          if (e2 < dx) { err += dx; y0 += sy; }
        }
      }

      function applyTool(px, py, button) {
        const color = button === 2 ? rightColor : leftColor;
        switch (currentTool) {
          case 'pen': setPixel(px, py, color); break;
          case 'eraser': setPixel(px, py, null); break;
          case 'bucket': floodFill(px, py, getPixel(px, py), color); break;
          case 'pick': {
            const c = getPixel(px, py);
            if (c) { if (button === 2) { rightColor = c; } else { leftColor = c; } updateColorDisplay(); }
            break;
          }
          case 'select': {
            if (!selecting) { selecting = true; lineStartX = px; lineStartY = py; }
            break;
          }
        }
      }

      // \u2500\u2500 Input Handlers \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || currentTool === 'hand' || (e.altKey && e.button === 0)) {
          isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY;
          canvas.style.cursor = 'grabbing'; return;
        }
        if (e.button === 0 || e.button === 2) {
          pushUndo(); isDrawing = true;
          const { x, y } = screenToPixel(e.offsetX, e.offsetY);
          if (currentTool === 'line' || currentTool === 'rect' || currentTool === 'select') {
            lineStartX = x; lineStartY = y;
          } else {
            applyTool(x, y, e.button); render();
          }
        }
      });

      canvas.addEventListener('mousemove', (e) => {
        const { x, y } = screenToPixel(e.offsetX, e.offsetY);
        document.getElementById('statusPos').textContent = x + ', ' + y;
        if (isPanning) { offsetX = e.clientX - panSX; offsetY = e.clientY - panSY; render(); return; }
        if (isDrawing && (currentTool === 'pen' || currentTool === 'eraser')) {
          applyTool(x, y, e.buttons & 2 ? 2 : 0); render();
        }
        if (isDrawing && currentTool === 'select') {
          selection = {
            x: Math.min(lineStartX, x), y: Math.min(lineStartY, y),
            w: Math.abs(x - lineStartX) + 1, h: Math.abs(y - lineStartY) + 1
          };
          render();
        }
      });

      canvas.addEventListener('mouseup', (e) => {
        canvas.style.cursor = '';
        if (isPanning) { isPanning = false; return; }
        if (isDrawing) {
          const { x, y } = screenToPixel(e.offsetX, e.offsetY);
          const color = e.button === 2 ? rightColor : leftColor;
          if (currentTool === 'line') drawLine(lineStartX, lineStartY, x, y, color);
          else if (currentTool === 'rect') {
            const x0 = Math.min(lineStartX, x), x1 = Math.max(lineStartX, x);
            const y0 = Math.min(lineStartY, y), y1 = Math.max(lineStartY, y);
            for (let ry = y0; ry <= y1; ry++) for (let rx = x0; rx <= x1; rx++) {
              if (ry === y0 || ry === y1 || rx === x0 || rx === x1) setPixel(rx, ry, color);
            }
          }
          isDrawing = false; render();
        }
      });

      canvas.addEventListener('contextmenu', (e) => e.preventDefault());

      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const oldZoom = zoom;
        zoom = Math.max(2, Math.min(64, zoom + (e.deltaY < 0 ? 2 : -2)));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / oldZoom;
        offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / oldZoom;
        render();
      }, { passive: false });

      // \u2500\u2500 Tool Shortcuts \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      const toolKeys = { b: 'pen', e: 'eraser', g: 'bucket', r: 'rect', l: 'line', m: 'select', i: 'pick', h: 'hand' };
      Object.entries(toolKeys).forEach(([key, tool]) => {
        registerShortcut(key, () => { selectTool(tool); });
      });
      registerShortcut('x', () => {
        [leftColor, rightColor] = [rightColor, leftColor]; updateColorDisplay();
      });

      function selectTool(tool) {
        currentTool = tool;
        document.querySelectorAll('#tools .icon-btn').forEach(b => {
          b.classList.toggle('active', b.dataset.tool === tool);
        });
        document.getElementById('statusTool').textContent = tool.charAt(0).toUpperCase() + tool.slice(1);
      }

      document.getElementById('tools').addEventListener('click', (e) => {
        const btn = e.target.closest('[data-tool]');
        if (!btn) return;
        selectTool(btn.dataset.tool);
      });

      // \u2500\u2500 Color \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      const paletteEl = document.getElementById('palette');
      const allColors = [...PICO8, ...ENDESGA32];
      allColors.forEach((c) => {
        const div = document.createElement('div');
        div.className = 'swatch';
        div.style.background = c; div.title = c;
        div.addEventListener('click', () => { leftColor = c; updateColorDisplay(); markDirty(); });
        div.addEventListener('contextmenu', (ev) => { ev.preventDefault(); rightColor = c; updateColorDisplay(); });
        paletteEl.appendChild(div);
      });

      function updateColorDisplay() {
        document.getElementById('leftColor').style.background = leftColor;
        document.getElementById('rightColor').style.background = rightColor;
        document.getElementById('hexInput').value = leftColor;
        // Highlight selected swatch
        paletteEl.querySelectorAll('.swatch').forEach(s => {
          s.classList.toggle('selected', s.style.background === leftColor ||
            s.title === leftColor);
        });
      }
      updateColorDisplay();

      document.getElementById('hexInput').addEventListener('change', (e) => {
        if (/^#[0-9a-fA-F]{6}$/.test(e.target.value)) { leftColor = e.target.value; updateColorDisplay(); }
      });
      document.getElementById('btnSwapColor').addEventListener('click', () => {
        [leftColor, rightColor] = [rightColor, leftColor]; updateColorDisplay();
      });
      document.getElementById('opacitySlider').addEventListener('input', (e) => {
        document.getElementById('opacityVal').textContent = e.target.value + '%';
      });

      // \u2500\u2500 Grid / Mirror \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      document.getElementById('btnGrid').addEventListener('click', function() {
        showGrid = !showGrid;
        this.classList.toggle('active', showGrid);
        render();
      });
      document.getElementById('btnMirrorH').addEventListener('click', function() {
        mirrorH = !mirrorH;
        this.classList.toggle('active', mirrorH);
        render();
      });
      document.getElementById('btnMirrorV').addEventListener('click', function() {
        mirrorV = !mirrorV;
        this.classList.toggle('active', mirrorV);
        render();
      });

      // \u2500\u2500 Size \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      document.getElementById('sizeSelect').addEventListener('change', (e) => {
        gridSize = parseInt(e.target.value);
        initData(); refreshLayers(); refreshFrames();
        offsetX = 0; offsetY = 0; zoom = Math.max(2, Math.floor(320 / gridSize));
        document.getElementById('statusSize').textContent = gridSize + '\xD7' + gridSize;
        resizeCanvas();
      });

      // \u2500\u2500 Layers \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function refreshLayers() {
        const el = document.getElementById('layerList');
        el.innerHTML = '';
        layers.forEach((l, i) => {
          const div = document.createElement('div');
          div.className = 'layer-item' + (i === currentLayer ? ' sel' : '');
          const visIcon = l.visible ? '${c.eye}' : '${c.eyeOff}';
          div.innerHTML = '<button class="vis-btn" title="Toggle visibility">' + visIcon + '</button>' +
            '<span class="name">' + l.name + '</span>';
          div.querySelector('.vis-btn').addEventListener('click', (ev) => {
            ev.stopPropagation();
            l.visible = !l.visible; refreshLayers(); render();
          });
          div.addEventListener('click', () => { currentLayer = i; refreshLayers(); });
          el.appendChild(div);
        });
        document.getElementById('statusLayerInfo').textContent = 'Layer ' + (currentLayer+1) + '/' + layers.length;
      }

      document.getElementById('btnAddLayer').addEventListener('click', () => {
        pushUndo();
        layers.push({ name: 'Layer ' + layers.length, visible: true, data: new Array(gridSize * gridSize).fill(null) });
        currentLayer = layers.length - 1; refreshLayers();
      });
      document.getElementById('btnDelLayer').addEventListener('click', () => {
        if (layers.length <= 1) { showToast('Cannot delete last layer', 'warn'); return; }
        pushUndo();
        layers.splice(currentLayer, 1);
        currentLayer = Math.min(currentLayer, layers.length - 1);
        refreshLayers(); render();
      });
      document.getElementById('btnMoveLayerUp').addEventListener('click', () => {
        if (currentLayer >= layers.length - 1) return;
        pushUndo();
        [layers[currentLayer], layers[currentLayer+1]] = [layers[currentLayer+1], layers[currentLayer]];
        currentLayer++; refreshLayers(); render();
      });
      document.getElementById('btnMoveLayerDown').addEventListener('click', () => {
        if (currentLayer <= 0) return;
        pushUndo();
        [layers[currentLayer], layers[currentLayer-1]] = [layers[currentLayer-1], layers[currentLayer]];
        currentLayer--; refreshLayers(); render();
      });
      refreshLayers();

      // \u2500\u2500 Frames \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function refreshFrames() {
        const el = document.getElementById('frameStrip');
        el.innerHTML = '';
        frames.forEach((_, i) => {
          const div = document.createElement('div');
          div.className = 'frame-thumb' + (i === currentFrame ? ' sel' : '');
          div.textContent = (i + 1);
          div.addEventListener('click', () => { currentFrame = i; refreshFrames(); });
          el.appendChild(div);
        });
        document.getElementById('statusFrameInfo').textContent = 'Frame ' + (currentFrame+1) + '/' + frames.length;
      }

      document.getElementById('btnAddFrame').addEventListener('click', () => {
        frames.push(JSON.parse(JSON.stringify(layers.map(l => l.data))));
        currentFrame = frames.length - 1; refreshFrames(); markDirty();
      });
      document.getElementById('btnDupFrame').addEventListener('click', () => {
        const dup = JSON.parse(JSON.stringify(layers.map(l => l.data)));
        frames.splice(currentFrame + 1, 0, dup);
        currentFrame++; refreshFrames(); markDirty();
      });
      document.getElementById('btnDelFrame').addEventListener('click', () => {
        if (frames.length <= 1) { showToast('Cannot delete last frame', 'warn'); return; }
        frames.splice(currentFrame, 1);
        currentFrame = Math.min(currentFrame, frames.length - 1);
        refreshFrames(); markDirty();
      });

      document.getElementById('fpsInput').addEventListener('change', (e) => {
        fps = Math.max(1, Math.min(60, parseInt(e.target.value) || 8));
        e.target.value = fps;
      });

      document.getElementById('btnPlay').addEventListener('click', function() {
        playing = !playing;
        this.innerHTML = playing ? '${c.stop} Stop' : '${c.play} Play';
        if (playing && frames.length > 1) {
          let fi = currentFrame;
          animTimer = setInterval(() => {
            // Save current frame data
            if (frames[fi]) {
              layers.forEach((l, i) => { if (frames[fi][i]) l.data = [...frames[fi][i]]; });
            }
            fi = (fi + 1) % frames.length;
            currentFrame = fi; refreshFrames(); render();
          }, Math.round(1000 / fps));
        } else { clearInterval(animTimer); }
      });

      document.getElementById('btnOnionSkin').addEventListener('click', function() {
        showOnionSkin = !showOnionSkin;
        this.classList.toggle('active', showOnionSkin);
        render();
      });
      refreshFrames();

      // \u2500\u2500 Preview Background \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      const bgModes = ['checker', 'black', 'white', 'transparent'];
      let bgIdx = 0;
      document.getElementById('btnPreviewBg').addEventListener('click', function() {
        bgIdx = (bgIdx + 1) % bgModes.length;
        previewBg = bgModes[bgIdx];
        this.textContent = 'BG: ' + previewBg.charAt(0).toUpperCase() + previewBg.slice(1);
        renderPreview();
      });

      // \u2500\u2500 Export \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function buildPng() {
        const tmpCanvas = document.createElement('canvas');
        tmpCanvas.width = gridSize; tmpCanvas.height = gridSize;
        const tmpCtx = tmpCanvas.getContext('2d');
        for (const l of layers) {
          if (!l.visible) continue;
          for (let y = 0; y < gridSize; y++)
            for (let x = 0; x < gridSize; x++) {
              const c = l.data[y * gridSize + x];
              if (c) { tmpCtx.fillStyle = c; tmpCtx.fillRect(x, y, 1, 1); }
            }
        }
        return tmpCanvas.toDataURL('image/png');
      }

      function buildSpriteSheet() {
        const cols = Math.ceil(Math.sqrt(frames.length));
        const rows = Math.ceil(frames.length / cols);
        const tmpCanvas = document.createElement('canvas');
        tmpCanvas.width = gridSize * cols; tmpCanvas.height = gridSize * rows;
        const tmpCtx = tmpCanvas.getContext('2d');
        frames.forEach((fData, fi) => {
          const fx = (fi % cols) * gridSize, fy = Math.floor(fi / cols) * gridSize;
          const layerData = fData || layers.map(l => l.data);
          for (let li = 0; li < layerData.length; li++) {
            if (layers[li] && !layers[li].visible) continue;
            for (let y = 0; y < gridSize; y++)
              for (let x = 0; x < gridSize; x++) {
                const c = layerData[li] ? layerData[li][y * gridSize + x] : null;
                if (c) { tmpCtx.fillStyle = c; tmpCtx.fillRect(fx + x, fy + y, 1, 1); }
              }
          }
        });
        return tmpCanvas.toDataURL('image/png');
      }

      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Pixel Art Editor'];
        lines.push('-- Load sprite:');
        lines.push('local sprite = lurek.render.newImage("sprites/mysprite.png")');
        if (frames.length > 1) {
          const cols = Math.ceil(Math.sqrt(frames.length));
          lines.push('');
          lines.push('-- Sprite sheet quads (' + frames.length + ' frames, ' + gridSize + 'x' + gridSize + ')');
          lines.push('local quads = {}');
          lines.push('local sheet = lurek.render.newImage("sprites/mysprite_sheet.png")');
          frames.forEach((_, fi) => {
            const qx = (fi % cols) * gridSize, qy = Math.floor(fi / cols) * gridSize;
            lines.push('quads[' + (fi+1) + '] = lurek.render.newQuad(' + qx + ', ' + qy + ', ' + gridSize + ', ' + gridSize + ', sheet:getWidth(), sheet:getHeight())');
          });
          lines.push('');
          lines.push('-- Draw a frame:');
          lines.push('-- lurek.render.drawq(sheet, quads[frameIndex], x, y)');
        }
        return lines.join('\\n');
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export PNG (current frame)', action: () => vscode.postMessage({ type: 'exportPng', content: buildPng() }) },
        { label: 'Export Sprite Sheet (all frames)', action: () => vscode.postMessage({ type: 'exportSpriteSheet', content: buildSpriteSheet() }) },
        { label: 'Copy Lua Code', action: () => vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() }) },
        { label: 'Insert Lua to Editor', action: () => vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() }) },
      ]);

      document.getElementById('btnCopyLua').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() });
      });

      // \u2500\u2500 Center canvas & init \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function centerCanvas() {
        const area = canvas.parentElement;
        const totalPx = gridSize * zoom;
        offsetX = (area.clientWidth - totalPx) / 2;
        offsetY = (area.clientHeight - totalPx) / 2;
      }
      zoom = Math.max(2, Math.floor(320 / gridSize));
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
      centerCanvas();
      render();
    `)}};var bn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.particle","Particle Designer")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"particles.lua");break}}getHtml(){let e=L();return I(e,"Particle Designer",`
      .editor-layout {
        display: grid; grid-template-columns: 180px 1fr 240px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .presets { grid-row: 2; background: var(--surface); border-right: 1px solid var(--border); overflow-y: auto; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: var(--bg); }
      .canvas-area canvas { display: block; }
      .params { grid-row: 2; background: var(--surface); border-left: 1px solid var(--border); overflow-y: auto; }

      .preset-item {
        padding: 6px 10px; cursor: pointer; border-radius: var(--radius); font-size: 12px;
        margin: 1px 4px; display: flex; align-items: center; gap: 6px;
        transition: background 0.08s;
      }
      .preset-item:hover { background: var(--hover); }
      .preset-item.selected { background: var(--selection); }
      .preset-item .dot { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; }

      .slider-row {
        display: grid; grid-template-columns: 70px 1fr 36px; gap: 4px;
        align-items: center; margin-bottom: 3px;
      }
      .slider-row label { font-size: 10px; text-align: right; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.3px; }
      .slider-row input[type=range] { width: 100%; }
      .slider-row .val { font-size: 10px; text-align: right; color: var(--text-dim); font-family: var(--font-mono); }

      .color-row {
        display: grid; grid-template-columns: 70px 28px 1fr; gap: 4px;
        align-items: center; margin-bottom: 4px;
      }
      .color-row label { font-size: 10px; text-align: right; color: var(--text-dim); text-transform: uppercase; }
      .color-row input[type=color] { width: 28px; height: 22px; border: 1px solid var(--border); border-radius: var(--radius); cursor: pointer; padding: 0; background: none; }
      .color-row .hex { font-size: 10px; color: var(--text-dim); font-family: var(--font-mono); }

      .emitter-shape-btns { display: flex; gap: 2px; }
      .emitter-shape-btns button { flex: 1; font-size: 10px; padding: 3px 0; }
    `,`
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            ${g("refresh",{id:"btnReset",title:"Reset (R)"})}
            <button id="btnPause">${c.play} Pause</button>
          </div>
          ${k()}
          <div class="group">
            <label>BG:</label>
            <select id="bgSelect">
              <option value="dark">Dark</option>
              <option value="black">Black</option>
              <option value="checker">Checker</option>
              <option value="white">White</option>
            </select>
          </div>
          ${k()}
          <div class="group">
            <label>Blend:</label>
            <select id="blendSelect">
              <option value="lighter">Additive</option>
              <option value="source-over" selected>Normal</option>
            </select>
          </div>
          ${A()}
          <div class="group">
            ${g("copy",{id:"btnCopyLua",title:"Copy Lua Code"})}
            ${g("insert",{id:"btnInsert",title:"Insert to Editor"})}
          </div>
          ${k()}
          <button id="btnExport" class="primary">${c.exportFile} Export \u25BE</button>
        </div>

        <!-- Presets Panel -->
        <div class="presets">
          ${b("Presets",'<div id="presetList"></div>')}
          ${b("Emitter Shape",`
            <div class="emitter-shape-btns">
              <button class="active" data-shape="point">Point</button>
              <button data-shape="line">Line</button>
              <button data-shape="circle">Circle</button>
              <button data-shape="rect">Rect</button>
            </div>
            ${N("Radius",'<input type="number" id="emitRadius" value="0" min="0" max="200" style="width:50px">')}
          `,!0)}
        </div>

        <!-- Canvas -->
        <div class="canvas-area"><canvas id="particleCanvas"></canvas></div>

        <!-- Parameters Panel -->
        <div class="params">
          ${b("Emission",'<div id="emissionParams"></div>')}
          ${b("Motion",'<div id="motionParams"></div>')}
          ${b("Appearance",'<div id="appearanceParams"></div>')}
          ${b("Colors",'<div id="colorControls"></div>')}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusParticles" class="badge">0 particles</span>
          </span>
          <div class="sep"></div>
          <span id="statusPreset">Fire</span>
          <div class="spacer"></div>
          <span id="statusFps">60 FPS</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${c.clean}</span>
        </div>
      </div>
    `,`
      // \u2500\u2500 Constants & Presets \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      const canvas = document.getElementById('particleCanvas');
      const ctx = canvas.getContext('2d');
      let paused = false, blendMode = 'source-over', bgMode = 'dark';
      let emitterShape = 'point', emitRadius = 0;

      const PRESETS = {
        Fire:     { max:200, rate:40, speed:80, lifetime:1.0, direction:-90, spread:30, sizeMin:2, sizeMax:6, gravityX:0, gravityY:-20, damping:0, spin:0, colorStart:'#ff4400', colorMid:'#ff8800', colorEnd:'#ffcc00' },
        Smoke:    { max:100, rate:15, speed:30, lifetime:2.0, direction:-90, spread:20, sizeMin:4, sizeMax:12, gravityX:0, gravityY:-10, damping:0.02, spin:0.5, colorStart:'#666666', colorMid:'#888888', colorEnd:'#aaaaaa' },
        Sparks:   { max:150, rate:50, speed:200, lifetime:0.5, direction:-90, spread:180, sizeMin:1, sizeMax:3, gravityX:0, gravityY:100, damping:0, spin:0, colorStart:'#ffee00', colorMid:'#ff8800', colorEnd:'#ff4400' },
        Snow:     { max:300, rate:20, speed:40, lifetime:4.0, direction:90, spread:40, sizeMin:2, sizeMax:4, gravityX:10, gravityY:20, damping:0, spin:1, colorStart:'#ffffff', colorMid:'#ddddff', colorEnd:'#bbbbff' },
        Rain:     { max:400, rate:80, speed:300, lifetime:1.0, direction:100, spread:5, sizeMin:1, sizeMax:2, gravityX:0, gravityY:200, damping:0, spin:0, colorStart:'#6699cc', colorMid:'#4488bb', colorEnd:'#336699' },
        Burst:    { max:100, rate:100, speed:150, lifetime:0.8, direction:0, spread:180, sizeMin:2, sizeMax:5, gravityX:0, gravityY:50, damping:0.03, spin:0, colorStart:'#ff0055', colorMid:'#ff44aa', colorEnd:'#ffaaff' },
        Magic:    { max:80, rate:10, speed:50, lifetime:1.5, direction:-90, spread:360, sizeMin:2, sizeMax:5, gravityX:0, gravityY:-5, damping:0.01, spin:2, colorStart:'#aa44ff', colorMid:'#4488ff', colorEnd:'#44ffaa' },
        Hearts:   { max:30, rate:5, speed:40, lifetime:2.0, direction:-90, spread:30, sizeMin:4, sizeMax:8, gravityX:0, gravityY:-15, damping:0, spin:0, colorStart:'#ff2266', colorMid:'#ff6699', colorEnd:'#ffaacc' },
        Confetti: { max:200, rate:30, speed:120, lifetime:2.0, direction:-60, spread:120, sizeMin:3, sizeMax:6, gravityX:0, gravityY:80, damping:0, spin:3, colorStart:'#ff4444', colorMid:'#44ff44', colorEnd:'#4444ff' },
        Firefly:  { max:40, rate:3, speed:20, lifetime:3.0, direction:0, spread:360, sizeMin:2, sizeMax:4, gravityX:0, gravityY:-5, damping:0, spin:0, colorStart:'#aaff44', colorMid:'#88cc22', colorEnd:'#446600' },
        Bubbles:  { max:60, rate:8, speed:30, lifetime:3.0, direction:-90, spread:20, sizeMin:3, sizeMax:8, gravityX:0, gravityY:-20, damping:0.01, spin:0, colorStart:'#88ccff', colorMid:'#aaddff', colorEnd:'#cceeff' },
        Dust:     { max:80, rate:10, speed:15, lifetime:2.5, direction:0, spread:360, sizeMin:1, sizeMax:3, gravityX:5, gravityY:-2, damping:0, spin:0.3, colorStart:'#aa9977', colorMid:'#886644', colorEnd:'#664422' },
      };

      let cfg = { ...PRESETS.Fire };
      let particles = [], emitAccum = 0;

      // \u2500\u2500 Parameter Groups \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      const EMISSION_PARAMS = [
        { key:'max', label:'Max', min:1, max:1000, step:1 },
        { key:'rate', label:'Rate', min:1, max:200, step:1 },
        { key:'lifetime', label:'Life', min:0.1, max:10, step:0.1 },
      ];
      const MOTION_PARAMS = [
        { key:'speed', label:'Speed', min:1, max:500, step:1 },
        { key:'direction', label:'Dir (\xB0)', min:-180, max:180, step:1 },
        { key:'spread', label:'Spread', min:0, max:360, step:1 },
        { key:'gravityX', label:'Grav X', min:-200, max:200, step:1 },
        { key:'gravityY', label:'Grav Y', min:-200, max:200, step:1 },
        { key:'damping', label:'Damping', min:0, max:0.2, step:0.005 },
        { key:'spin', label:'Spin', min:0, max:10, step:0.1 },
      ];
      const APPEARANCE_PARAMS = [
        { key:'sizeMin', label:'Size Min', min:1, max:20, step:1 },
        { key:'sizeMax', label:'Size Max', min:1, max:40, step:1 },
      ];

      function buildSliderGroup(containerId, params) {
        const el = document.getElementById(containerId);
        el.innerHTML = '';
        for (const p of params) {
          const row = document.createElement('div');
          row.className = 'slider-row';
          row.innerHTML = '<label>' + p.label + '</label>' +
            '<input type="range" min="' + p.min + '" max="' + p.max + '" step="' + p.step + '" value="' + cfg[p.key] + '" data-key="' + p.key + '">' +
            '<span class="val">' + cfg[p.key] + '</span>';
          el.appendChild(row);
          row.querySelector('input').addEventListener('input', (e) => {
            cfg[p.key] = parseFloat(e.target.value);
            row.querySelector('.val').textContent = e.target.value;
            markDirty();
          });
        }
      }

      function buildColorControls() {
        const cel = document.getElementById('colorControls');
        cel.innerHTML = '';
        for (const ck of ['colorStart', 'colorMid', 'colorEnd']) {
          const row = document.createElement('div');
          row.className = 'color-row';
          const label = ck.replace('color', '');
          row.innerHTML = '<label>' + label + '</label>' +
            '<input type="color" value="' + cfg[ck] + '" data-key="' + ck + '">' +
            '<span class="hex">' + cfg[ck] + '</span>';
          cel.appendChild(row);
          row.querySelector('input').addEventListener('input', (e) => {
            cfg[ck] = e.target.value;
            row.querySelector('.hex').textContent = e.target.value;
            markDirty();
          });
        }
      }

      function buildAllControls() {
        buildSliderGroup('emissionParams', EMISSION_PARAMS);
        buildSliderGroup('motionParams', MOTION_PARAMS);
        buildSliderGroup('appearanceParams', APPEARANCE_PARAMS);
        buildColorControls();
      }

      // \u2500\u2500 Presets \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      const presetList = document.getElementById('presetList');
      let activePreset = 'Fire';
      for (const name of Object.keys(PRESETS)) {
        const div = document.createElement('div');
        div.className = 'preset-item' + (name === activePreset ? ' selected' : '');
        const dotColor = PRESETS[name].colorStart;
        div.innerHTML = '<span class="dot" style="background:' + dotColor + '"></span>' + name;
        div.addEventListener('click', () => {
          activePreset = name;
          cfg = { ...PRESETS[name] };
          particles = []; emitAccum = 0;
          presetList.querySelectorAll('.preset-item').forEach(d => d.classList.remove('selected'));
          div.classList.add('selected');
          document.getElementById('statusPreset').textContent = name;
          buildAllControls();
          markDirty();
        });
        presetList.appendChild(div);
      }

      // \u2500\u2500 Emitter Shape \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      document.querySelectorAll('[data-shape]').forEach(btn => {
        btn.addEventListener('click', function() {
          document.querySelectorAll('[data-shape]').forEach(b => b.classList.remove('active'));
          this.classList.add('active');
          emitterShape = this.dataset.shape;
        });
      });
      document.getElementById('emitRadius').addEventListener('input', (e) => { emitRadius = parseInt(e.target.value) || 0; });

      // \u2500\u2500 Simulation \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function hexToRgb(hex) {
        return { r: parseInt(hex.slice(1,3),16), g: parseInt(hex.slice(3,5),16), b: parseInt(hex.slice(5,7),16) };
      }
      function lerpColor(c1, c2, t) {
        const a = hexToRgb(c1), b = hexToRgb(c2);
        return 'rgb(' + Math.round(a.r+(b.r-a.r)*t) + ',' + Math.round(a.g+(b.g-a.g)*t) + ',' + Math.round(a.b+(b.b-a.b)*t) + ')';
      }

      function emitOffset() {
        if (emitterShape === 'point') return { x: 0, y: 0 };
        if (emitterShape === 'circle') {
          const a = Math.random() * Math.PI * 2, r = Math.random() * emitRadius;
          return { x: Math.cos(a) * r, y: Math.sin(a) * r };
        }
        if (emitterShape === 'line') {
          return { x: (Math.random() - 0.5) * emitRadius * 2, y: 0 };
        }
        if (emitterShape === 'rect') {
          return { x: (Math.random() - 0.5) * emitRadius * 2, y: (Math.random() - 0.5) * emitRadius * 2 };
        }
        return { x: 0, y: 0 };
      }

      function emitParticle(cx, cy) {
        const off = emitOffset();
        const angle = (cfg.direction + (Math.random() - 0.5) * cfg.spread) * Math.PI / 180;
        const speed = cfg.speed * (0.8 + Math.random() * 0.4);
        particles.push({
          x: cx + off.x, y: cy + off.y,
          vx: Math.cos(angle) * speed, vy: Math.sin(angle) * speed,
          life: 0, maxLife: cfg.lifetime * (0.8 + Math.random() * 0.4),
          size: cfg.sizeMin + Math.random() * (cfg.sizeMax - cfg.sizeMin),
          rotation: 0, spinRate: (Math.random() - 0.5) * cfg.spin,
        });
      }

      let lastTime = performance.now();
      let frameCount = 0, fpsTimer = 0;

      function update() {
        if (paused) { requestAnimationFrame(update); return; }
        const now = performance.now();
        const dt = Math.min((now - lastTime) / 1000, 0.05);
        lastTime = now;

        frameCount++; fpsTimer += dt;
        if (fpsTimer >= 1) {
          document.getElementById('statusFps').textContent = frameCount + ' FPS';
          frameCount = 0; fpsTimer = 0;
        }

        const cx = canvas.width / 2, cy = canvas.height / 2;

        emitAccum += cfg.rate * dt;
        while (emitAccum >= 1 && particles.length < cfg.max) {
          emitParticle(cx, cy); emitAccum--;
        }

        for (let i = particles.length - 1; i >= 0; i--) {
          const p = particles[i];
          p.vx += cfg.gravityX * dt; p.vy += cfg.gravityY * dt;
          if (cfg.damping > 0) {
            p.vx *= (1 - cfg.damping); p.vy *= (1 - cfg.damping);
          }
          p.x += p.vx * dt; p.y += p.vy * dt;
          p.rotation += p.spinRate * dt;
          p.life += dt;
          if (p.life >= p.maxLife) particles.splice(i, 1);
        }

        // Render
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // Background
        if (bgMode === 'checker') {
          const s = 16;
          for (let y = 0; y < canvas.height; y += s)
            for (let x = 0; x < canvas.width; x += s) {
              ctx.fillStyle = ((Math.floor(x/s) + Math.floor(y/s)) % 2 === 0) ? '#2a2a3d' : '#232334';
              ctx.fillRect(x, y, s, s);
            }
        } else if (bgMode === 'black') {
          ctx.fillStyle = '#000'; ctx.fillRect(0, 0, canvas.width, canvas.height);
        } else if (bgMode === 'white') {
          ctx.fillStyle = '#fff'; ctx.fillRect(0, 0, canvas.width, canvas.height);
        }

        // Emitter indicator
        ctx.strokeStyle = 'rgba(137,180,250,0.3)'; ctx.lineWidth = 1;
        if (emitterShape === 'point') {
          ctx.beginPath(); ctx.arc(cx, cy, 4, 0, Math.PI * 2); ctx.stroke();
        } else if (emitterShape === 'circle') {
          ctx.beginPath(); ctx.arc(cx, cy, emitRadius, 0, Math.PI * 2); ctx.stroke();
        } else if (emitterShape === 'line') {
          ctx.beginPath(); ctx.moveTo(cx - emitRadius, cy); ctx.lineTo(cx + emitRadius, cy); ctx.stroke();
        } else if (emitterShape === 'rect') {
          ctx.strokeRect(cx - emitRadius, cy - emitRadius, emitRadius * 2, emitRadius * 2);
        }

        // Particles
        ctx.globalCompositeOperation = blendMode;
        for (const p of particles) {
          const t = p.life / p.maxLife;
          const color = t < 0.5 ? lerpColor(cfg.colorStart, cfg.colorMid, t * 2) : lerpColor(cfg.colorMid, cfg.colorEnd, (t - 0.5) * 2);
          ctx.globalAlpha = 1 - t;
          ctx.fillStyle = color;
          ctx.save();
          ctx.translate(p.x, p.y);
          ctx.rotate(p.rotation);
          ctx.beginPath();
          ctx.arc(0, 0, p.size * (1 - t * 0.3), 0, Math.PI * 2);
          ctx.fill();
          ctx.restore();
        }
        ctx.globalAlpha = 1;
        ctx.globalCompositeOperation = 'source-over';

        document.getElementById('statusParticles').textContent = particles.length + ' particles';
        requestAnimationFrame(update);
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight;
      }

      // \u2500\u2500 Controls \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      document.getElementById('btnPause').addEventListener('click', function() {
        paused = !paused;
        this.innerHTML = paused ? '${c.play} Resume' : '${c.stop} Pause';
        if (!paused) { lastTime = performance.now(); }
      });
      document.getElementById('btnReset').addEventListener('click', () => { particles = []; emitAccum = 0; });
      registerShortcut('r', () => { particles = []; emitAccum = 0; });
      registerShortcut('space', () => {
        paused = !paused;
        document.getElementById('btnPause').innerHTML = paused ? '${c.play} Resume' : '${c.stop} Pause';
        if (!paused) { lastTime = performance.now(); }
      });

      document.getElementById('bgSelect').addEventListener('change', (e) => { bgMode = e.target.value; });
      document.getElementById('blendSelect').addEventListener('change', (e) => { blendMode = e.target.value; });

      // \u2500\u2500 Export \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Particle Designer'];
        lines.push('-- Usage: local emitter = lurek.particle.newEmitter(config)');
        lines.push('');
        lines.push('return {');
        lines.push('  max_particles = ' + cfg.max + ',');
        lines.push('  emit_rate = ' + cfg.rate + ',');
        lines.push('  speed = ' + cfg.speed + ',');
        lines.push('  lifetime = ' + cfg.lifetime + ',');
        lines.push('  direction = ' + cfg.direction + ',');
        lines.push('  spread = ' + cfg.spread + ',');
        lines.push('  size = { min = ' + cfg.sizeMin + ', max = ' + cfg.sizeMax + ' },');
        lines.push('  gravity = { x = ' + cfg.gravityX + ', y = ' + cfg.gravityY + ' },');
        lines.push('  damping = ' + cfg.damping + ',');
        lines.push('  spin = ' + cfg.spin + ',');
        if (emitterShape !== 'point') {
          lines.push('  emitter_shape = "' + emitterShape + '",');
          lines.push('  emitter_radius = ' + emitRadius + ',');
        }
        lines.push('  colors = {');
        lines.push('    start  = "' + cfg.colorStart + '",');
        lines.push('    mid    = "' + cfg.colorMid + '",');
        lines.push('    finish = "' + cfg.colorEnd + '",');
        lines.push('  },');
        if (blendMode === 'lighter') lines.push('  blend = "additive",');
        lines.push('}');
        return lines.join('\\n');
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export Lua', action: () => vscode.postMessage({ type: 'exportLua', content: buildLuaCode() }) },
        { label: 'Copy Lua Code', action: () => vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() }) },
        { label: 'Insert Lua to Editor', action: () => vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() }) },
      ]);

      document.getElementById('btnCopyLua').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() });
      });

      // \u2500\u2500 Init \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      buildAllControls();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
      requestAnimationFrame(update);
    `)}};var vn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.dialog","Dialog Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"dialog.lua");break}}getHtml(){let e=L();return I(e,"Dialog Editor",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 260px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: var(--bg); }
      .canvas-area canvas { display: block; }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); overflow-y: auto; background: var(--surface); }

      .choice-item {
        display: flex; gap: 4px; margin-bottom: 3px; align-items: center;
      }
      .choice-item input { flex: 1; font-size: 11px; }

      .prop-field { margin-bottom: 4px; }
      .prop-field label {
        font-size: 10px; text-transform: uppercase; letter-spacing: 0.3px;
        color: var(--text-dim); display: block; margin-bottom: 1px;
      }
      .prop-field input, .prop-field textarea, .prop-field select { width: 100%; font-size: 12px; }
      .prop-field textarea { height: 56px; resize: vertical; font-family: var(--font-mono); font-size: 11px; }

      .type-badge {
        display: inline-flex; align-items: center; gap: 4px; padding: 2px 8px;
        border-radius: var(--radius); font-size: 10px; font-weight: 600;
        text-transform: uppercase; letter-spacing: 0.3px;
      }

      .conn-item {
        display: flex; align-items: center; gap: 4px; font-size: 11px;
        padding: 3px 6px; border-radius: var(--radius); margin-bottom: 2px;
      }
      .conn-item:hover { background: var(--hover); }
      .conn-item .arrow { color: var(--accent); }
      .conn-item .target { flex: 1; }

      .node-type-btn { display: flex; align-items: center; gap: 4px; font-size: 11px; padding: 4px 8px; }
      .node-type-btn .dot { width: 8px; height: 8px; border-radius: 50%; }
    `,`
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            <button class="node-type-btn" id="btnAddNpc"><span class="dot" style="background:#4488bb"></span>NPC</button>
            <button class="node-type-btn" id="btnAddChoice"><span class="dot" style="background:#44aa66"></span>Choice</button>
            <button class="node-type-btn" id="btnAddCondition"><span class="dot" style="background:#bbaa44"></span>Condition</button>
            <button class="node-type-btn" id="btnAddAction"><span class="dot" style="background:#bb6644"></span>Action</button>
          </div>
          ${k()}
          <div class="group">
            ${g("link",{id:"btnConnect",title:"Connect Mode (C)"})}
            ${g("trash",{id:"btnDelete",title:"Delete Selected (Del)",cls:"danger"})}
          </div>
          ${k()}
          <div class="group">
            ${g("undo",{id:"btnUndo",title:"Undo (Ctrl+Z)"})}
            ${g("redo",{id:"btnRedo",title:"Redo (Ctrl+Y)"})}
          </div>
          ${k()}
          <div class="group">
            <button id="btnAutoLayout" title="Auto-arrange nodes">Auto Layout</button>
            <button id="btnFitView" title="Fit all nodes in view">Fit View</button>
          </div>
          ${A()}
          <div class="group">
            ${g("copy",{id:"btnCopyLua",title:"Copy Lua Code"})}
            ${g("insert",{id:"btnInsert",title:"Insert to Editor"})}
          </div>
          ${k()}
          <button id="btnExport" class="primary">${c.exportFile} Export \u25BE</button>
        </div>

        <!-- Canvas -->
        <div class="canvas-area"><canvas id="dialogCanvas"></canvas></div>

        <!-- Properties Panel -->
        <div class="props-panel">
          ${b("Node Properties",'<div id="propsContent"><p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:8px;">Select a dialog node.</p></div>')}
          ${b("Connections",'<div id="connsContent"></div>',!0)}
          ${b("Preview",`
            <div id="previewArea" style="background:var(--bg);border:1px solid var(--border);border-radius:var(--radius);padding:8px;margin:0 8px;font-size:12px;min-height:60px;color:var(--text-dim);text-align:center;">
              Select a node to preview dialog.
            </div>
          `,!0)}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusNodes" class="badge">0 nodes</span>
          </span>
          <div class="sep"></div>
          <span id="statusConns">0 connections</span>
          <div class="sep"></div>
          <span id="statusMode">Select</span>
          <div class="spacer"></div>
          <span id="statusZoom">100%</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${c.clean}</span>
        </div>
      </div>
    `,`
      const canvas = document.getElementById('dialogCanvas');
      const ctx = canvas.getContext('2d');
      let nodes = [], edges = [];
      let selectedNode = null, dragNode = null, dragOff = { x: 0, y: 0 };
      let connectMode = false, connectFrom = null;
      let offsetX = 0, offsetY = 0, zoom = 1;
      let isPanning = false, panSX = 0, panSY = 0;
      let nextId = 1;
      const NODE_W = 170, NODE_H = 64;
      const undo = new UndoStack(60);

      const NODE_TYPES = {
        npc:       { color: '#1e3a5f', border: '#4488bb', label: 'NPC' },
        choice:    { color: '#1e4a2e', border: '#44aa66', label: 'Choice' },
        condition: { color: '#4a3e1e', border: '#bbaa44', label: 'Condition' },
        action:    { color: '#4a2e1e', border: '#bb6644', label: 'Action' },
      };

      function snapshot() { return JSON.parse(JSON.stringify({ nodes, edges, nextId })); }
      function restoreSnap(s) { nodes = s.nodes; edges = s.edges; nextId = s.nextId; selectedNode = null; showProps(null); updateStatus(); render(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      function addNode(type, x, y) {
        pushUndo();
        nodes.push({
          id: nextId++, type,
          x: x !== undefined ? x : 100 + nodes.length * 50,
          y: y !== undefined ? y : 100 + nodes.length * 50,
          speaker: type === 'npc' ? 'NPC' : '', text: '',
          choices: type === 'choice' ? ['Yes', 'No'] : [],
          condition: type === 'condition' ? 'has_item("key")' : '',
          action: type === 'action' ? 'give_item("reward")' : '',
        });
        updateStatus(); render();
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight; render();
      }

      // \u2500\u2500 Rendering \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // Grid dots
        ctx.fillStyle = 'rgba(137,180,250,0.06)';
        const gs = 40 * zoom, sx = offsetX % gs, sy = offsetY % gs;
        for (let y = sy; y < canvas.height; y += gs)
          for (let x = sx; x < canvas.width; x += gs)
            ctx.fillRect(x - 1, y - 1, 2, 2);

        ctx.save(); ctx.translate(offsetX, offsetY); ctx.scale(zoom, zoom);

        // Edges with bezier curves
        for (const e of edges) {
          const from = nodes.find(n => n.id === e.from);
          const to = nodes.find(n => n.id === e.to);
          if (!from || !to) continue;
          const fx = from.x + NODE_W / 2, fy = from.y + NODE_H;
          const tx = to.x + NODE_W / 2, ty = to.y;
          ctx.beginPath(); ctx.moveTo(fx, fy);
          ctx.bezierCurveTo(fx, fy + 50, tx, ty - 50, tx, ty);
          ctx.strokeStyle = e.label ? 'rgba(78,201,176,0.6)' : 'rgba(137,180,250,0.4)';
          ctx.lineWidth = 2; ctx.stroke();
          // Arrow
          ctx.beginPath(); ctx.moveTo(tx, ty);
          ctx.lineTo(tx - 6, ty - 10); ctx.lineTo(tx + 6, ty - 10); ctx.closePath();
          ctx.fillStyle = e.label ? 'rgba(78,201,176,0.6)' : 'rgba(137,180,250,0.4)'; ctx.fill();
          // Edge label
          if (e.label) {
            ctx.fillStyle = 'rgba(255,255,255,0.6)'; ctx.font = '10px sans-serif'; ctx.textAlign = 'center';
            const mx = (fx + tx) / 2, my = (fy + ty) / 2;
            ctx.fillText(e.label, mx, my);
          }
        }

        // Nodes
        for (const n of nodes) {
          const nt = NODE_TYPES[n.type];
          const isSel = n === selectedNode;

          // Shadow
          ctx.fillStyle = 'rgba(0,0,0,0.25)';
          ctx.beginPath(); ctx.roundRect(n.x + 2, n.y + 2, NODE_W, NODE_H, 6); ctx.fill();

          // Body
          ctx.fillStyle = nt.color;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.fill();

          // Border
          ctx.strokeStyle = isSel ? '#89b4fa' : nt.border;
          ctx.lineWidth = isSel ? 2.5 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.stroke();

          // Type bar
          ctx.fillStyle = nt.border + '30';
          ctx.fillRect(n.x + 1, n.y + 1, NODE_W - 2, 18);

          // Type label + speaker
          ctx.fillStyle = nt.border; ctx.font = 'bold 10px sans-serif'; ctx.textAlign = 'left';
          ctx.fillText(nt.label + (n.speaker ? ': ' + n.speaker : ''), n.x + 8, n.y + 13);

          // Text preview
          ctx.fillStyle = '#ccc'; ctx.font = '11px sans-serif'; ctx.textAlign = 'center';
          const preview = n.text || n.condition || n.action || (n.choices.length ? n.choices.join(' / ') : '...');
          ctx.fillText(preview.substring(0, 24), n.x + NODE_W / 2, n.y + 38);

          // Connection count
          const outC = edges.filter(e => e.from === n.id).length;
          const inC = edges.filter(e => e.to === n.id).length;
          ctx.fillStyle = 'rgba(255,255,255,0.25)'; ctx.font = '9px sans-serif';
          ctx.fillText(inC + ' in / ' + outC + ' out', n.x + NODE_W / 2, n.y + 54);

          // Connect dot
          if (connectMode) {
            ctx.fillStyle = 'rgba(250,179,135,0.6)';
            ctx.beginPath(); ctx.arc(n.x + NODE_W / 2, n.y + NODE_H, 5, 0, Math.PI * 2); ctx.fill();
          }
        }
        ctx.restore();
      }

      function hitTest(sx, sy) {
        const wx = (sx - offsetX) / zoom, wy = (sy - offsetY) / zoom;
        for (let i = nodes.length - 1; i >= 0; i--) {
          const n = nodes[i];
          if (wx >= n.x && wx <= n.x + NODE_W && wy >= n.y && wy <= n.y + NODE_H) return n;
        }
        return null;
      }

      // \u2500\u2500 Properties \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function showProps(node) {
        const el = document.getElementById('propsContent');
        const cel = document.getElementById('connsContent');
        const prev = document.getElementById('previewArea');
        if (!node) {
          el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:8px;">Select a dialog node.</p>';
          cel.innerHTML = '';
          prev.innerHTML = 'Select a node to preview dialog.';
          return;
        }

        const nt = NODE_TYPES[node.type];
        let html = '<div style="margin-bottom:6px"><span class="type-badge" style="background:' + nt.border + '30;color:' + nt.border + '">' + nt.label + '</span></div>';

        if (node.type === 'npc' || node.type === 'choice') {
          html += '<div class="prop-field"><label>Speaker</label><input id="pSpeaker" value="' + node.speaker + '"></div>';
          html += '<div class="prop-field"><label>Dialog Text</label><textarea id="pText">' + node.text + '</textarea></div>';
        }
        if (node.type === 'choice') {
          html += '<div class="prop-field"><label>Choices</label><div id="choiceList">';
          node.choices.forEach((c, i) => {
            html += '<div class="choice-item"><input value="' + c + '" data-ci="' + i + '"><button class="icon-btn" data-delc="' + i + '" title="Remove">${c.trash}</button></div>';
          });
          html += '</div><button id="btnAddChoiceItem" style="width:100%;margin-top:4px;font-size:11px;">${c.add} Add Choice</button></div>';
        }
        if (node.type === 'condition') {
          html += '<div class="prop-field"><label>Condition Expression</label><textarea id="pCondition">' + node.condition + '</textarea></div>';
        }
        if (node.type === 'action') {
          html += '<div class="prop-field"><label>Action Script</label><textarea id="pAction">' + node.action + '</textarea></div>';
        }
        el.innerHTML = html;

        // Bind property inputs
        const bind = (id, key) => {
          const inp = document.getElementById(id);
          if (inp) inp.addEventListener('input', (ev) => { pushUndo(); node[key] = ev.target.value; render(); updatePreview(node); });
        };
        bind('pSpeaker', 'speaker'); bind('pText', 'text'); bind('pCondition', 'condition'); bind('pAction', 'action');

        el.querySelectorAll('[data-ci]').forEach(inp => {
          inp.addEventListener('input', (ev) => { pushUndo(); node.choices[parseInt(ev.target.dataset.ci)] = ev.target.value; render(); });
        });
        el.querySelectorAll('[data-delc]').forEach(btn => {
          btn.addEventListener('click', (ev) => { pushUndo(); node.choices.splice(parseInt(ev.currentTarget.dataset.delc), 1); showProps(node); render(); });
        });
        const addBtn = document.getElementById('btnAddChoiceItem');
        if (addBtn) addBtn.addEventListener('click', () => { pushUndo(); node.choices.push('Option'); showProps(node); render(); });

        // Connections
        const outEdges = edges.filter(e => e.from === node.id);
        const inEdges = edges.filter(e => e.to === node.id);
        let chtml = '';
        if (outEdges.length) {
          chtml += '<div style="font-size:10px;color:var(--text-dim);margin-bottom:2px">OUTGOING</div>';
          for (const e of outEdges) {
            const t = nodes.find(n => n.id === e.to);
            chtml += '<div class="conn-item"><span class="arrow">\u2192</span><span class="target">' + (t ? (NODE_TYPES[t.type].label + ': ' + (t.speaker || t.text || '...').substring(0, 16)) : '?') + '</span>';
            if (e.label) chtml += '<span style="font-size:9px;color:var(--accent-2)">' + e.label + '</span>';
            chtml += '<button class="icon-btn" data-del-edge="' + e.from + '-' + e.to + '">${c.trash}</button></div>';
          }
        }
        if (inEdges.length) {
          chtml += '<div style="font-size:10px;color:var(--text-dim);margin:4px 0 2px">INCOMING</div>';
          for (const e of inEdges) {
            const f = nodes.find(n => n.id === e.from);
            chtml += '<div class="conn-item"><span class="arrow">\u2190</span><span class="target">' + (f ? (NODE_TYPES[f.type].label + ': ' + (f.speaker || f.text || '...').substring(0, 16)) : '?') + '</span></div>';
          }
        }
        if (!outEdges.length && !inEdges.length) chtml = '<p style="color:var(--text-dim);font-size:11px">No connections</p>';
        cel.innerHTML = chtml;

        cel.querySelectorAll('[data-del-edge]').forEach(btn => {
          btn.addEventListener('click', (ev) => {
            const [from, to] = ev.currentTarget.dataset.delEdge.split('-').map(Number);
            pushUndo();
            edges = edges.filter(ed => !(ed.from === from && ed.to === to));
            showProps(node); updateStatus(); render();
          });
        });

        updatePreview(node);
      }

      function updatePreview(node) {
        const prev = document.getElementById('previewArea');
        if (!node) { prev.innerHTML = ''; return; }
        if (node.type === 'npc' || node.type === 'choice') {
          let h = '<div style="text-align:left">';
          if (node.speaker) h += '<div style="font-weight:600;color:var(--accent);margin-bottom:2px">' + node.speaker + '</div>';
          h += '<div style="color:var(--text);font-style:italic">"' + (node.text || '...') + '"</div>';
          if (node.type === 'choice' && node.choices.length) {
            h += '<div style="margin-top:6px;border-top:1px solid var(--border);padding-top:4px">';
            node.choices.forEach((c, i) => { h += '<div style="color:var(--accent-2);cursor:pointer;padding:2px 0">' + (i+1) + '. ' + c + '</div>'; });
            h += '</div>';
          }
          h += '</div>';
          prev.innerHTML = h;
        } else if (node.type === 'condition') {
          prev.innerHTML = '<div style="text-align:left;font-family:var(--font-mono);font-size:11px">if ' + (node.condition || '...') + ' then<br>&nbsp;&nbsp;\u2192 true branch<br>else<br>&nbsp;&nbsp;\u2192 false branch</div>';
        } else if (node.type === 'action') {
          prev.innerHTML = '<div style="text-align:left;font-family:var(--font-mono);font-size:11px">' + (node.action || '-- no action') + '</div>';
        }
      }

      function updateStatus() {
        document.getElementById('statusNodes').textContent = nodes.length + ' nodes';
        document.getElementById('statusConns').textContent = edges.length + ' connections';
        document.getElementById('statusMode').textContent = connectMode ? 'Connect' : 'Select';
        document.getElementById('statusZoom').textContent = Math.round(zoom * 100) + '%';
      }

      // \u2500\u2500 Canvas Events \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) { isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY; canvas.style.cursor = 'grabbing'; return; }
        const node = hitTest(e.offsetX, e.offsetY);
        if (connectMode && e.button === 0) {
          if (!connectFrom && node) { connectFrom = node; }
          else if (connectFrom && node && node !== connectFrom) {
            if (!edges.find(ed => ed.from === connectFrom.id && ed.to === node.id)) {
              const label = connectFrom.type === 'choice' && connectFrom.choices.length > 0
                ? connectFrom.choices[edges.filter(ed => ed.from === connectFrom.id).length] || ''
                : '';
              pushUndo();
              edges.push({ from: connectFrom.id, to: node.id, label });
            }
            connectFrom = null; updateStatus(); render();
          } else { connectFrom = null; }
          return;
        }
        if (node) {
          selectedNode = node; showProps(node);
          dragNode = node;
          dragOff = { x: (e.offsetX - offsetX) / zoom - node.x, y: (e.offsetY - offsetY) / zoom - node.y };
        } else { selectedNode = null; showProps(null); }
        render();
      });

      canvas.addEventListener('mousemove', (e) => {
        if (isPanning) { offsetX = e.clientX - panSX; offsetY = e.clientY - panSY; render(); return; }
        if (dragNode) {
          dragNode.x = Math.round(((e.offsetX - offsetX) / zoom - dragOff.x) / 20) * 20;
          dragNode.y = Math.round(((e.offsetY - offsetY) / zoom - dragOff.y) / 20) * 20;
          render();
        }
      });
      canvas.addEventListener('mouseup', () => { isPanning = false; dragNode = null; canvas.style.cursor = ''; });

      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const old = zoom; zoom *= e.deltaY < 0 ? 1.1 : 0.9; zoom = Math.max(0.2, Math.min(4, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / old;
        offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / old;
        updateStatus(); render();
      }, { passive: false });

      // \u2500\u2500 Toolbar \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      document.getElementById('btnAddNpc').addEventListener('click', () => addNode('npc'));
      document.getElementById('btnAddChoice').addEventListener('click', () => addNode('choice'));
      document.getElementById('btnAddCondition').addEventListener('click', () => addNode('condition'));
      document.getElementById('btnAddAction').addEventListener('click', () => addNode('action'));
      document.getElementById('btnConnect').addEventListener('click', () => {
        connectMode = !connectMode; connectFrom = null;
        document.getElementById('btnConnect').classList.toggle('active', connectMode);
        updateStatus();
      });
      document.getElementById('btnDelete').addEventListener('click', () => {
        if (!selectedNode) return;
        pushUndo();
        edges = edges.filter(e => e.from !== selectedNode.id && e.to !== selectedNode.id);
        nodes = nodes.filter(n => n !== selectedNode);
        selectedNode = null; showProps(null); updateStatus(); render();
      });
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restoreSnap(s); });

      document.getElementById('btnAutoLayout').addEventListener('click', () => {
        if (nodes.length === 0) return;
        pushUndo();
        const placed = new Set();
        function placeTree(id, col, row) {
          if (placed.has(id)) return row;
          placed.add(id);
          const n = nodes.find(nd => nd.id === id);
          if (!n) return row;
          n.x = col * (NODE_W + 60) + 40;
          n.y = row * (NODE_H + 50) + 40;
          const outs = edges.filter(e => e.from === id);
          let nextRow = row;
          for (const e of outs) { nextRow = placeTree(e.to, col + 1, nextRow); nextRow++; }
          return Math.max(row, nextRow);
        }
        const hasIncoming = new Set(edges.map(e => e.to));
        const roots = nodes.filter(n => !hasIncoming.has(n.id));
        if (roots.length === 0) roots.push(nodes[0]);
        let row = 0;
        for (const r of roots) { row = placeTree(r.id, 0, row); row++; }
        nodes.forEach((n, i) => { if (!placed.has(n.id)) { n.x = 40; n.y = (placed.size + i) * (NODE_H + 50) + 40; placed.add(n.id); } });
        render();
      });

      document.getElementById('btnFitView').addEventListener('click', () => {
        if (nodes.length === 0) return;
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        for (const n of nodes) { minX = Math.min(minX, n.x); minY = Math.min(minY, n.y); maxX = Math.max(maxX, n.x + NODE_W); maxY = Math.max(maxY, n.y + NODE_H); }
        const pad = 60, w = maxX - minX + pad * 2, h = maxY - minY + pad * 2;
        zoom = Math.min(canvas.width / w, canvas.height / h, 2);
        offsetX = (canvas.width - w * zoom) / 2 - minX * zoom + pad * zoom;
        offsetY = (canvas.height - h * zoom) / 2 - minY * zoom + pad * zoom;
        updateStatus(); render();
      });

      registerShortcut('c', () => { connectMode = !connectMode; connectFrom = null; document.getElementById('btnConnect').classList.toggle('active', connectMode); updateStatus(); });
      registerShortcut('delete', () => document.getElementById('btnDelete').click());
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('1', () => addNode('npc'));
      registerShortcut('2', () => addNode('choice'));
      registerShortcut('3', () => addNode('condition'));
      registerShortcut('4', () => addNode('action'));

      // \u2500\u2500 Export \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Dialog Editor', '-- Usage: local dialog = require("dialog")', ''];
        lines.push('return {');
        for (const n of nodes) {
          let line = '  { id = ' + n.id + ', type = "' + n.type + '"';
          if (n.speaker) line += ', speaker = "' + n.speaker + '"';
          if (n.text) line += ', text = "' + n.text + '"';
          if (n.choices.length) line += ', choices = { "' + n.choices.join('", "') + '" }';
          if (n.condition) line += ', condition = function() return ' + n.condition + ' end';
          if (n.action) line += ', action = function() ' + n.action + ' end';
          const conns = edges.filter(e => e.from === n.id);
          if (conns.length === 1) {
            line += ', next = ' + conns[0].to;
          } else if (conns.length > 1) {
            line += ', next = { ' + conns.map(e => {
              const label = e.label ? '["' + e.label + '"] = ' + e.to : e.to;
              return label;
            }).join(', ') + ' }';
          }
          line += ' },';
          lines.push(line);
        }
        lines.push('}');
        return lines.join('\\n');
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export Lua File', action: () => vscode.postMessage({ type: 'exportLua', content: buildLuaCode() }) },
        { label: 'Copy Lua Code', action: () => vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() }) },
        { label: 'Insert to Editor', action: () => vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() }) },
      ]);

      document.getElementById('btnCopyLua').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() });
      });

      // \u2500\u2500 Init \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      addNode('npc', 100, 50); nodes[0].speaker = 'Guard'; nodes[0].text = 'Halt! Who goes there?';
      addNode('choice', 100, 180); nodes[1].text = 'Response'; nodes[1].choices = ['I am a friend', 'None of your business'];
      addNode('npc', 50, 310); nodes[2].speaker = 'Guard'; nodes[2].text = 'Welcome, friend.';
      addNode('action', 300, 310); nodes[3].action = 'start_combat()';
      edges.push({ from: 1, to: 2, label: '' }, { from: 2, to: 3, label: 'Friend' }, { from: 2, to: 4, label: 'Hostile' });
      undo.clear();
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `)}};var xn=C(require("vscode"));var Tn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.database","Database Browser")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"data.lua");break;case"exportToml":this.exportToml(e.content,"data.toml");break;case"importCsv":this.importCsv();break}}async importCsv(){let e=await xn.window.showOpenDialog({filters:{"CSV Files":["csv"],"TOML Files":["toml"]}});if(e&&e[0]){let t=await xn.workspace.fs.readFile(e[0]),r=new globalThis.TextDecoder().decode(t);this.panel.webview.postMessage({type:"csvData",content:r,name:e[0].fsPath})}}getHtml(){let e=L();return I(e,"Database Browser",`
      .editor-layout {
        display: grid; grid-template-columns: 180px 1fr;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .table-list { grid-row: 2; background: var(--surface); border-right: 1px solid var(--border); overflow-y: auto; }
      .data-area { grid-row: 2; overflow: auto; display: flex; flex-direction: column; }

      .table-item {
        padding: 5px 10px; cursor: pointer; border-radius: var(--radius); margin: 1px 4px;
        font-size: 12px; display: flex; align-items: center; gap: 6px; transition: background 0.08s;
      }
      .table-item:hover { background: var(--hover); }
      .table-item.selected { background: var(--selection); }
      .table-item .count { font-size: 10px; color: var(--text-dim); margin-left: auto; font-family: var(--font-mono); }

      .filter-bar {
        display: flex; gap: 4px; padding: 6px 8px; border-bottom: 1px solid var(--border);
        background: var(--surface); align-items: center;
      }
      .filter-bar input { flex: 1; }
      .filter-bar label { font-size: 10px; color: var(--text-dim); text-transform: uppercase; }

      .data-grid { width: 100%; border-collapse: collapse; font-size: 12px; }
      .data-grid th {
        background: var(--surface-2); border: 1px solid var(--border); padding: 4px 8px;
        text-align: left; cursor: pointer; user-select: none; position: sticky; top: 0; z-index: 1;
        font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.3px;
      }
      .data-grid th:hover { background: var(--accent); color: var(--bg); }
      .data-grid td { border: 1px solid var(--border); padding: 3px 6px; font-family: var(--font-mono); font-size: 11px; }
      .data-grid tr:hover td { background: var(--hover); }
      .data-grid tr.selected td { background: var(--selection); }
      .data-grid td.editing { padding: 0; }
      .data-grid td.editing input { width: 100%; border: none; background: var(--selection); color: var(--text); padding: 3px 6px; font-family: var(--font-mono); font-size: 11px; }
      .data-grid .type-hint { font-size: 9px; color: var(--text-dim); font-weight: 400; text-transform: none; }
      .data-grid .sort-indicator { margin-left: 2px; }

      .col-type-select { font-size: 10px; padding: 1px 4px; margin-left: 4px; }
    `,`
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            ${g("add",{id:"btnNewTable",title:"New Table"})}
            ${g("trash",{id:"btnDeleteTable",title:"Delete Table",cls:"danger"})}
          </div>
          ${k()}
          <div class="group">
            ${g("add",{id:"btnAddRow",title:"Add Row"})}
            <button id="btnAddCol" title="Add Column">+ Col</button>
            ${g("trash",{id:"btnDeleteRow",title:"Delete Selected Row",cls:"danger"})}
          </div>
          ${k()}
          <div class="group">
            ${g("undo",{id:"btnUndo",title:"Undo (Ctrl+Z)"})}
            ${g("redo",{id:"btnRedo",title:"Redo (Ctrl+Y)"})}
          </div>
          ${k()}
          <button id="btnImport">${c.importFile} Import</button>
          ${A()}
          <div class="group">
            ${g("copy",{id:"btnCopyLua",title:"Copy Lua Code"})}
            ${g("insert",{id:"btnInsert",title:"Insert to Editor"})}
          </div>
          ${k()}
          <button id="btnExport" class="primary">${c.exportFile} Export \u25BE</button>
        </div>

        <!-- Table List -->
        <div class="table-list">
          ${b("Tables",'<div id="tableList"></div>')}
        </div>

        <!-- Data Area -->
        <div class="data-area">
          <div class="filter-bar"><label>Filter:</label><input id="filterInput" placeholder="column:value or free text"></div>
          <div style="flex:1;overflow:auto">
            <table class="data-grid"><thead id="gridHead"></thead><tbody id="gridBody"></tbody></table>
          </div>
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusTables" class="badge">0 tables</span>
          </span>
          <div class="sep"></div>
          <span id="statusRows">0 rows</span>
          <div class="sep"></div>
          <span id="statusCols">0 columns</span>
          <div class="spacer"></div>
          <span id="statusSelected">No selection</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${c.clean}</span>
        </div>
      </div>
    `,`
      let tables = {
        items: {
          columns: ['id', 'name', 'type', 'value'],
          types: ['number', 'string', 'string', 'number'],
          rows: [
            [1, 'Sword', 'weapon', 10],
            [2, 'Shield', 'armor', 8],
            [3, 'Potion', 'consumable', 5],
          ]
        },
        enemies: {
          columns: ['id', 'name', 'hp', 'damage', 'hostile'],
          types: ['number', 'string', 'number', 'number', 'boolean'],
          rows: [
            [1, 'Goblin', 30, 5, true],
            [2, 'Merchant', 50, 0, false],
          ]
        }
      };
      let currentTable = 'items';
      let sortCol = -1, sortAsc = true;
      let selectedRow = -1;
      const undo = new UndoStack(80);

      function snapshot() { return JSON.parse(JSON.stringify({ tables, currentTable, selectedRow })); }
      function restoreSnap(s) { tables = s.tables; currentTable = s.currentTable; selectedRow = s.selectedRow; refreshAll(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      function refreshTableList() {
        const el = document.getElementById('tableList');
        el.innerHTML = '';
        for (const name of Object.keys(tables)) {
          const div = document.createElement('div');
          div.className = 'table-item' + (name === currentTable ? ' selected' : '');
          div.innerHTML = '<span style="flex:1">' + name + '</span><span class="count">' + tables[name].rows.length + '</span>';
          div.addEventListener('click', () => { currentTable = name; selectedRow = -1; sortCol = -1; refreshAll(); });
          el.appendChild(div);
        }
      }

      function refreshGrid() {
        const t = tables[currentTable];
        if (!t) { document.getElementById('gridHead').innerHTML = ''; document.getElementById('gridBody').innerHTML = ''; updateStatus(); return; }
        const th = document.getElementById('gridHead');
        th.innerHTML = '<tr><th style="width:30px">#</th>' + t.columns.map((c, i) =>
          '<th data-col="' + i + '">' + c + ' <span class="type-hint">' + t.types[i] + '</span>' +
          (sortCol === i ? '<span class="sort-indicator">' + (sortAsc ? '\u25B2' : '\u25BC') + '</span>' : '') + '</th>'
        ).join('') + '</tr>';

        th.querySelectorAll('th[data-col]').forEach(thEl => {
          thEl.addEventListener('click', () => {
            const ci = parseInt(thEl.dataset.col);
            if (sortCol === ci) sortAsc = !sortAsc; else { sortCol = ci; sortAsc = true; }
            t.rows.sort((a, b) => {
              const va = a[ci], vb = b[ci];
              const cmp = typeof va === 'string' ? va.localeCompare(vb) : (va < vb ? -1 : va > vb ? 1 : 0);
              return sortAsc ? cmp : -cmp;
            });
            refreshGrid();
          });
        });

        const filter = document.getElementById('filterInput').value.trim();
        let rows = t.rows;
        if (filter) {
          if (filter.includes(':')) {
            const [col, val] = filter.split(':').map(s => s.trim());
            const ci = t.columns.indexOf(col);
            if (ci >= 0) rows = rows.filter(r => String(r[ci]).toLowerCase().includes(val.toLowerCase()));
          } else {
            rows = rows.filter(r => r.some(v => String(v).toLowerCase().includes(filter.toLowerCase())));
          }
        }

        const tb = document.getElementById('gridBody');
        tb.innerHTML = '';
        rows.forEach((row, ri) => {
          const tr = document.createElement('tr');
          if (ri === selectedRow) tr.classList.add('selected');
          tr.innerHTML = '<td style="color:var(--text-dim);text-align:center;font-size:10px">' + ri + '</td>' +
            row.map((v, ci) => {
              let display = String(v);
              if (typeof v === 'boolean') display = v ? '\u2713' : '\u2717';
              return '<td data-r="' + ri + '" data-c="' + ci + '">' + display + '</td>';
            }).join('');
          tr.addEventListener('click', () => { selectedRow = ri; updateStatus(); tb.querySelectorAll('tr').forEach(r => r.classList.remove('selected')); tr.classList.add('selected'); });
          tb.appendChild(tr);
        });

        tb.querySelectorAll('td[data-r]').forEach(td => {
          td.addEventListener('dblclick', () => {
            const ri = parseInt(td.dataset.r), ci = parseInt(td.dataset.c);
            td.classList.add('editing');
            const inp = document.createElement('input');
            inp.value = String(t.rows[ri][ci]);
            td.textContent = '';
            td.appendChild(inp);
            inp.focus(); inp.select();
            const commit = () => {
              pushUndo();
              const type = t.types[ci];
              if (type === 'number') t.rows[ri][ci] = parseFloat(inp.value) || 0;
              else if (type === 'boolean') t.rows[ri][ci] = inp.value === 'true' || inp.value === '1';
              else t.rows[ri][ci] = inp.value;
              refreshGrid();
            };
            inp.addEventListener('blur', commit);
            inp.addEventListener('keydown', (e) => {
              if (e.key === 'Enter') inp.blur();
              if (e.key === 'Escape') { refreshGrid(); }
            });
          });
        });

        updateStatus();
      }

      function updateStatus() {
        const t = tables[currentTable];
        document.getElementById('statusTables').textContent = Object.keys(tables).length + ' tables';
        document.getElementById('statusRows').textContent = (t ? t.rows.length : 0) + ' rows';
        document.getElementById('statusCols').textContent = (t ? t.columns.length : 0) + ' columns';
        document.getElementById('statusSelected').textContent = selectedRow >= 0 ? 'Row ' + selectedRow : 'No selection';
      }

      function refreshAll() { refreshTableList(); refreshGrid(); }

      document.getElementById('filterInput').addEventListener('input', () => refreshGrid());

      document.getElementById('btnNewTable').addEventListener('click', () => {
        pushUndo();
        const name = 'table_' + Object.keys(tables).length;
        tables[name] = { columns: ['id', 'name'], types: ['number', 'string'], rows: [] };
        currentTable = name; refreshAll();
      });
      document.getElementById('btnDeleteTable').addEventListener('click', () => {
        if (!currentTable) return;
        pushUndo();
        delete tables[currentTable];
        const keys = Object.keys(tables);
        currentTable = keys.length > 0 ? keys[0] : '';
        refreshAll();
      });
      document.getElementById('btnAddRow').addEventListener('click', () => {
        const t = tables[currentTable]; if (!t) return;
        pushUndo();
        const row = t.columns.map((_, i) => t.types[i] === 'number' ? 0 : t.types[i] === 'boolean' ? false : '');
        row[0] = t.rows.length;
        t.rows.push(row); refreshGrid();
      });
      document.getElementById('btnAddCol').addEventListener('click', () => {
        const t = tables[currentTable]; if (!t) return;
        pushUndo();
        t.columns.push('col_' + t.columns.length); t.types.push('string');
        t.rows.forEach(r => r.push(''));
        refreshGrid();
      });
      document.getElementById('btnDeleteRow').addEventListener('click', () => {
        const t = tables[currentTable]; if (!t || selectedRow < 0) return;
        pushUndo();
        t.rows.splice(selectedRow, 1); selectedRow = -1; refreshGrid();
      });
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });

      document.getElementById('btnImport').addEventListener('click', () => vscode.postMessage({ type: 'importCsv' }));

      window.addEventListener('message', (e) => {
        if (e.data.type === 'csvData') {
          const lines = e.data.content.split('\\n').filter(l => l.trim());
          if (lines.length < 2) return;
          pushUndo();
          const cols = lines[0].split(',').map(s => s.trim());
          const rows = lines.slice(1).map(l => l.split(',').map(s => {
            const v = s.trim();
            if (v === 'true' || v === 'false') return v === 'true';
            const n = parseFloat(v);
            return isNaN(n) ? v : n;
          }));
          const types = cols.map((_, i) => typeof rows[0][i] === 'number' ? 'number' : typeof rows[0][i] === 'boolean' ? 'boolean' : 'string');
          const name = 'imported_' + Object.keys(tables).length;
          tables[name] = { columns: cols, types, rows };
          currentTable = name; refreshAll();
        }
      });

      // \u2500\u2500 Export \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function buildLuaCode() {
        const t = tables[currentTable];
        if (!t) return '-- No table selected';
        const lines = ['-- Generated by Lurek2D Database Browser', '-- Table: ' + currentTable, ''];
        lines.push('return {');
        for (const row of t.rows) {
          let items = [];
          t.columns.forEach((c, i) => {
            if (typeof row[i] === 'string') items.push(c + ' = "' + row[i] + '"');
            else items.push(c + ' = ' + row[i]);
          });
          lines.push('  { ' + items.join(', ') + ' },');
        }
        lines.push('}');
        return lines.join('\\n');
      }

      function buildTomlCode() {
        const t = tables[currentTable];
        if (!t) return '# No table selected';
        let toml = '# Table: ' + currentTable + '\\n\\n';
        for (const row of t.rows) {
          toml += '[[' + currentTable + ']]\\n';
          t.columns.forEach((c, i) => {
            if (typeof row[i] === 'string') toml += c + ' = "' + row[i] + '"\\n';
            else toml += c + ' = ' + row[i] + '\\n';
          });
          toml += '\\n';
        }
        return toml;
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export Lua File', action: () => vscode.postMessage({ type: 'exportLua', content: buildLuaCode() }) },
        { label: 'Export TOML File', action: () => vscode.postMessage({ type: 'exportToml', content: buildTomlCode() }) },
        { label: 'Copy Lua Code', action: () => vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() }) },
        { label: 'Insert to Editor', action: () => vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() }) },
      ]);

      document.getElementById('btnCopyLua').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() });
      });

      // \u2500\u2500 Init \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      refreshAll();
    `)}};var wn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.procMap","Procedural Map Generator")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"mapgen.lua");break}}getHtml(){let e=L();return I(e,"Procedural Map Generator",`
      .editor-layout {
        display: grid; grid-template-columns: 260px 1fr;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .pipeline-panel { grid-row: 2; overflow-y: auto; background: var(--surface); border-right: 1px solid var(--border); }
      .preview-area { grid-row: 2; display: flex; align-items: center; justify-content: center; background: var(--bg); overflow: hidden; }

      .step-card {
        background: var(--surface-2); border: 1px solid var(--border); border-radius: var(--radius);
        margin: 0 4px 6px 4px; overflow: hidden;
      }
      .step-card-header {
        display: flex; align-items: center; justify-content: space-between;
        padding: 5px 8px; font-size: 11px; font-weight: 600;
        text-transform: uppercase; letter-spacing: 0.3px;
        border-bottom: 1px solid var(--border); cursor: grab;
      }
      .step-card-header .num { color: var(--accent); margin-right: 6px; font-family: var(--font-mono); }
      .step-card-header .actions { display: flex; gap: 2px; }
      .step-card-body { padding: 6px 8px; }
      .step-card-body .param-row {
        display: grid; grid-template-columns: 80px 1fr; gap: 4px;
        align-items: center; margin-bottom: 3px;
      }
      .step-card-body .param-row label { font-size: 10px; text-align: right; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.3px; }

      .config-field {
        display: grid; grid-template-columns: 60px 1fr; gap: 4px;
        align-items: center; margin-bottom: 4px;
      }
      .config-field label { font-size: 10px; text-align: right; color: var(--text-dim); text-transform: uppercase; }

      .add-step-btn { width: calc(100% - 16px); margin: 4px 8px; font-size: 11px; }
    `,`
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            <button id="btnGenerate" class="primary">${c.refresh} Generate</button>
            <button id="btnRandomSeed">${c.dice} Random Seed</button>
          </div>
          ${k()}
          <div class="group">
            ${g("undo",{id:"btnUndo",title:"Undo (Ctrl+Z)"})}
            ${g("redo",{id:"btnRedo",title:"Redo (Ctrl+Y)"})}
          </div>
          ${A()}
          <div class="group">
            ${g("copy",{id:"btnCopyLua",title:"Copy Lua Code"})}
            ${g("insert",{id:"btnInsert",title:"Insert to Editor"})}
          </div>
          ${k()}
          <button id="btnExport" class="primary">${c.exportFile} Export \u25BE</button>
        </div>

        <!-- Pipeline Panel -->
        <div class="pipeline-panel">
          ${b("Map Config",`
            <div class="config-field"><label>Width</label><input type="number" id="mapW" value="60" min="10" max="200" style="width:60px"></div>
            <div class="config-field"><label>Height</label><input type="number" id="mapH" value="40" min="10" max="200" style="width:60px"></div>
            <div class="config-field"><label>Seed</label><input type="number" id="seed" value="42" style="width:80px"></div>
          `)}
          ${b("Pipeline Steps",'<div id="stepList"></div>')}
          <select id="addStepSelect" class="add-step-btn">
            <option value="">+ Add Step...</option>
            <option value="fill">Fill</option>
            <option value="noise">Noise</option>
            <option value="cellular">Cellular Automata</option>
            <option value="rooms">Room Placement</option>
            <option value="corridors">Corridors</option>
            <option value="border">Border Wall</option>
          </select>
        </div>

        <!-- Preview -->
        <div class="preview-area"><canvas id="mapCanvas"></canvas></div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusSize" class="badge">60 x 40</span>
          </span>
          <div class="sep"></div>
          <span id="statusSeed">Seed: 42</span>
          <div class="sep"></div>
          <span id="statusSteps">0 steps</span>
          <div class="spacer"></div>
          <span id="statusTiles">0 walls / 0 floor</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${c.clean}</span>
        </div>
      </div>
    `,`
      let mapW = 60, mapH = 40, seed = 42;
      let mapData = [];
      let steps = [
        { type: 'fill', params: { tile: 1 } },
        { type: 'noise', params: { density: 0.45, tile: 0 } },
        { type: 'cellular', params: { iterations: 5, birthLimit: 4, deathLimit: 3 } },
      ];
      const undo = new UndoStack(40);

      function snapshot() { return JSON.parse(JSON.stringify({ steps, mapW, mapH, seed })); }
      function restoreSnap(s) { steps = s.steps; mapW = s.mapW; mapH = s.mapH; seed = s.seed;
        document.getElementById('mapW').value = mapW; document.getElementById('mapH').value = mapH;
        document.getElementById('seed').value = seed; refreshStepList(); generate();
      }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      function mulberry32(a) {
        return function() {
          a |= 0; a = a + 0x6D2B79F5 | 0;
          var t = Math.imul(a ^ a >>> 15, 1 | a);
          t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
          return ((t ^ t >>> 14) >>> 0) / 4294967296;
        };
      }
      let rng = mulberry32(seed);

      const TILE_COLORS = {
        0: '#1a1a2e', 1: '#3a3a5a', 2: '#2a4a2a', 3: '#2a3a5a',
      };

      function initMap() { mapData = new Array(mapW * mapH).fill(0); }
      function getCell(x, y) { return (x >= 0 && x < mapW && y >= 0 && y < mapH) ? mapData[y * mapW + x] : 1; }
      function setCell(x, y, v) { if (x >= 0 && x < mapW && y >= 0 && y < mapH) mapData[y * mapW + x] = v; }
      function countNeighbors(x, y, tile) {
        let count = 0;
        for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
          if (dx === 0 && dy === 0) continue;
          if (getCell(x + dx, y + dy) === tile) count++;
        }
        return count;
      }

      function applyStep(step) {
        switch (step.type) {
          case 'fill': mapData.fill(step.params.tile); break;
          case 'noise':
            for (let i = 0; i < mapData.length; i++) { if (rng() < step.params.density) mapData[i] = step.params.tile; }
            break;
          case 'cellular':
            for (let iter = 0; iter < step.params.iterations; iter++) {
              const next = [...mapData];
              for (let y = 0; y < mapH; y++) for (let x = 0; x < mapW; x++) {
                const walls = countNeighbors(x, y, 1);
                next[y * mapW + x] = mapData[y * mapW + x] === 1
                  ? (walls >= step.params.deathLimit ? 1 : 0)
                  : (walls >= step.params.birthLimit ? 1 : 0);
              }
              mapData = next;
            }
            break;
          case 'rooms': {
            const count = step.params.count || 6, minS = step.params.minSize || 4, maxS = step.params.maxSize || 10;
            for (let i = 0; i < count; i++) {
              const rw = Math.floor(rng() * (maxS - minS)) + minS;
              const rh = Math.floor(rng() * (maxS - minS)) + minS;
              const rx = Math.floor(rng() * (mapW - rw - 2)) + 1;
              const ry = Math.floor(rng() * (mapH - rh - 2)) + 1;
              for (let y = ry; y < ry + rh; y++) for (let x = rx; x < rx + rw; x++) setCell(x, y, 0);
            }
            break;
          }
          case 'corridors': {
            const openSpots = [];
            for (let y = 2; y < mapH - 2; y += 8) for (let x = 2; x < mapW - 2; x += 8) {
              if (getCell(x, y) === 0) openSpots.push({ x, y });
            }
            for (let i = 0; i < openSpots.length - 1; i++) {
              const a = openSpots[i], b = openSpots[i + 1];
              let cx = a.x;
              while (cx !== b.x) { setCell(cx, a.y, 0); cx += cx < b.x ? 1 : -1; }
              let cy = a.y;
              while (cy !== b.y) { setCell(b.x, cy, 0); cy += cy < b.y ? 1 : -1; }
            }
            break;
          }
          case 'border':
            for (let x = 0; x < mapW; x++) { setCell(x, 0, 1); setCell(x, mapH - 1, 1); }
            for (let y = 0; y < mapH; y++) { setCell(0, y, 1); setCell(mapW - 1, y, 1); }
            break;
        }
      }

      function generate() {
        mapW = parseInt(document.getElementById('mapW').value) || 60;
        mapH = parseInt(document.getElementById('mapH').value) || 40;
        seed = parseInt(document.getElementById('seed').value) || 0;
        rng = mulberry32(seed);
        initMap();
        for (const step of steps) applyStep(step);
        renderMap();
        updateStatus();
      }

      function renderMap() {
        const canvas = document.getElementById('mapCanvas');
        const parent = canvas.parentElement;
        const cs = Math.max(2, Math.min(Math.floor(parent.clientWidth / mapW), Math.floor(parent.clientHeight / mapH), 12));
        canvas.width = mapW * cs; canvas.height = mapH * cs;
        const ctx = canvas.getContext('2d');
        for (let y = 0; y < mapH; y++) for (let x = 0; x < mapW; x++) {
          ctx.fillStyle = TILE_COLORS[mapData[y * mapW + x]] || '#000';
          ctx.fillRect(x * cs, y * cs, cs, cs);
        }
      }

      function updateStatus() {
        document.getElementById('statusSize').textContent = mapW + ' x ' + mapH;
        document.getElementById('statusSeed').textContent = 'Seed: ' + seed;
        document.getElementById('statusSteps').textContent = steps.length + ' steps';
        const walls = mapData.filter(t => t === 1).length;
        document.getElementById('statusTiles').textContent = walls + ' walls / ' + (mapData.length - walls) + ' floor';
      }

      function refreshStepList() {
        const el = document.getElementById('stepList');
        el.innerHTML = '';
        steps.forEach((step, i) => {
          const card = document.createElement('div');
          card.className = 'step-card';
          let paramsHtml = '';
          for (const [k, v] of Object.entries(step.params)) {
            paramsHtml += '<div class="param-row"><label>' + k + '</label>' +
              '<input type="number" data-si="' + i + '" data-pk="' + k + '" value="' + v + '" style="width:60px" step="' + (typeof v === 'number' && v < 1 ? 0.05 : 1) + '"></div>';
          }
          card.innerHTML = '<div class="step-card-header"><span><span class="num">' + (i + 1) + '</span>' + step.type + '</span>' +
            '<span class="actions">' +
            '<button class="icon-btn" data-up="' + i + '" title="Move Up">${c.up}</button>' +
            '<button class="icon-btn" data-down="' + i + '" title="Move Down">${c.down}</button>' +
            '<button class="icon-btn" data-del="' + i + '" title="Remove">${c.trash}</button>' +
            '</span></div><div class="step-card-body">' + paramsHtml + '</div>';
          el.appendChild(card);
          card.querySelectorAll('input[data-si]').forEach(inp => {
            inp.addEventListener('input', (e) => {
              pushUndo();
              steps[parseInt(e.target.dataset.si)].params[e.target.dataset.pk] = parseFloat(e.target.value) || 0;
            });
          });
          card.querySelector('[data-del]').addEventListener('click', (e) => {
            pushUndo(); steps.splice(parseInt(e.currentTarget.dataset.del), 1); refreshStepList();
          });
          const upBtn = card.querySelector('[data-up]');
          if (upBtn) upBtn.addEventListener('click', (e) => {
            const idx = parseInt(e.currentTarget.dataset.up);
            if (idx > 0) { pushUndo(); [steps[idx-1], steps[idx]] = [steps[idx], steps[idx-1]]; refreshStepList(); }
          });
          const downBtn = card.querySelector('[data-down]');
          if (downBtn) downBtn.addEventListener('click', (e) => {
            const idx = parseInt(e.currentTarget.dataset.down);
            if (idx < steps.length - 1) { pushUndo(); [steps[idx], steps[idx+1]] = [steps[idx+1], steps[idx]]; refreshStepList(); }
          });
        });
      }

      document.getElementById('addStepSelect').addEventListener('change', (e) => {
        if (!e.target.value) return;
        pushUndo();
        const defaults = {
          fill: { tile: 1 }, noise: { density: 0.45, tile: 0 },
          cellular: { iterations: 5, birthLimit: 4, deathLimit: 3 },
          rooms: { count: 6, minSize: 4, maxSize: 10 }, corridors: {}, border: {},
        };
        steps.push({ type: e.target.value, params: { ...defaults[e.target.value] } });
        e.target.value = '';
        refreshStepList();
      });

      document.getElementById('btnGenerate').addEventListener('click', generate);
      document.getElementById('btnRandomSeed').addEventListener('click', () => {
        document.getElementById('seed').value = String(Math.floor(Math.random() * 999999));
        generate();
      });
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('g', () => generate());

      // \u2500\u2500 Export \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Procedural Map Generator', '-- Usage: local map = lurek.procgen.generate(config)', ''];
        lines.push('return {');
        lines.push('  width = ' + mapW + ',');
        lines.push('  height = ' + mapH + ',');
        lines.push('  seed = ' + seed + ',');
        lines.push('  steps = {');
        for (const s of steps) {
          let line = '    { type = "' + s.type + '"';
          for (const [k, v] of Object.entries(s.params)) line += ', ' + k + ' = ' + v;
          line += ' },';
          lines.push(line);
        }
        lines.push('  },');
        lines.push('  data = {');
        for (let y = 0; y < mapH; y++) {
          lines.push('    ' + mapData.slice(y * mapW, (y + 1) * mapW).join(', ') + ',');
        }
        lines.push('  },');
        lines.push('}');
        return lines.join('\\n');
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export Lua File', action: () => vscode.postMessage({ type: 'exportLua', content: buildLuaCode() }) },
        { label: 'Copy Lua Code', action: () => vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() }) },
        { label: 'Insert to Editor', action: () => vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() }) },
      ]);

      document.getElementById('btnCopyLua').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() });
      });

      // \u2500\u2500 Init \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      refreshStepList();
      window.addEventListener('resize', () => renderMap());
      generate();
    `)}};var Pn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.questTree","Quest / Tech Tree Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"quests.lua");break}}getHtml(){let e=L();return I(e,"Quest / Tech Tree Editor",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 260px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: var(--bg); }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); overflow-y: auto; background: var(--surface); }

      .prop-field { margin-bottom: 6px; }
      .prop-field label { display: block; font-size: 10px; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.3px; margin-bottom: 2px; }
      .prop-field input, .prop-field select, .prop-field textarea {
        width: 100%; box-sizing: border-box;
      }
      .prop-field textarea { resize: vertical; min-height: 36px; }

      .prereq-list { font-size: 11px; color: var(--text-dim); }
      .prereq-item { display: flex; align-items: center; gap: 4px; margin-bottom: 2px; }
      .prereq-dot { width: 6px; height: 6px; border-radius: 50%; background: var(--accent); flex-shrink: 0; }

      .mode-badge {
        display: inline-flex; align-items: center; gap: 4px;
        padding: 1px 8px; border-radius: 9px; font-size: 10px; font-weight: 600;
      }
      .mode-badge.select { background: var(--surface-2); color: var(--text-dim); }
      .mode-badge.link { background: var(--warning); color: var(--bg); }
    `,`
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            ${g("add",{id:"btnAdd",title:"Add Quest (A)"})}
            ${g("link",{id:"btnConnect",title:"Link Prerequisites (C)"})}
            ${g("trash",{id:"btnDelete",title:"Delete (Del)",cls:"danger"})}
          </div>
          ${k()}
          <div class="group">
            ${g("undo",{id:"btnUndo",title:"Undo (Ctrl+Z)"})}
            ${g("redo",{id:"btnRedo",title:"Redo (Ctrl+Y)"})}
          </div>
          ${k()}
          <div class="group">
            ${g("layout",{id:"btnAutoLayout",title:"Auto Layout"})}
            ${g("fitView",{id:"btnFitView",title:"Fit View (F)"})}
          </div>
          ${A()}
          <div class="group">
            ${g("copy",{id:"btnCopyLua",title:"Copy Lua Code"})}
            ${g("insert",{id:"btnInsert",title:"Insert to Editor"})}
          </div>
          ${k()}
          <button id="btnExport" class="primary">${c.exportFile} Export \u25BE</button>
        </div>

        <!-- Canvas -->
        <div class="canvas-area"><canvas id="questCanvas"></canvas></div>

        <!-- Properties -->
        <div class="props-panel">
          ${b("Quest Properties",'<div id="propsContent"><p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:20px;">Select a quest node</p></div>')}
          ${b("Statistics",'<div id="statsContent"></div>',!0)}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusQuests" class="badge">0 quests</span>
          </span>
          <div class="sep"></div>
          <span id="statusLinks">0 links</span>
          <div class="sep"></div>
          <span id="statusMode" class="mode-badge select">SELECT</span>
          <div class="spacer"></div>
          <span id="statusZoom">100%</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${c.clean}</span>
        </div>
      </div>
    `,`
      const canvas = document.getElementById('questCanvas');
      const ctx = canvas.getContext('2d');
      let nodes = [], edges = [];
      let selectedNode = null, dragNode = null, dragOff = { x: 0, y: 0 };
      let connectMode = false, connectFrom = null;
      let offsetX = 0, offsetY = 0, zoom = 1;
      let isPanning = false, panSX = 0, panSY = 0;
      let nextId = 1;
      const NODE_W = 160, NODE_H = 60;
      const undo = new UndoStack(60);

      function snapshot() { return JSON.parse(JSON.stringify({ nodes, edges, nextId })); }
      function restoreSnap(s) { nodes = s.nodes; edges = s.edges; nextId = s.nextId; selectedNode = null; showProps(null); updateStatus(); render(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      const STATUS_COLORS = {
        available: { bg: '#1a3a1a', border: '#3a6a3a', dot: '#4caf50' },
        locked:    { bg: '#2a2a2a', border: '#4a4a4a', dot: '#666' },
        completed: { bg: '#3a3a1a', border: '#6a5a2a', dot: '#ffd700' },
      };

      function addNode(name, x, y) {
        pushUndo();
        nodes.push({
          id: nextId++, name: name || 'Quest ' + (nodes.length + 1),
          x: x ?? (100 + nodes.length * 40), y: y ?? (100 + nodes.length * 80),
          description: '', requiredItems: '', reward: '', status: 'available',
        });
        updateStatus(); render();
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight; render();
      }

      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.save(); ctx.translate(offsetX, offsetY); ctx.scale(zoom, zoom);

        // Grid
        ctx.strokeStyle = 'rgba(255,255,255,0.03)'; ctx.lineWidth = 1;
        const gs = 40, startX = -offsetX / zoom, startY = -offsetY / zoom;
        const endX = startX + canvas.width / zoom, endY = startY + canvas.height / zoom;
        for (let x = Math.floor(startX / gs) * gs; x < endX; x += gs) { ctx.beginPath(); ctx.moveTo(x, startY); ctx.lineTo(x, endY); ctx.stroke(); }
        for (let y = Math.floor(startY / gs) * gs; y < endY; y += gs) { ctx.beginPath(); ctx.moveTo(startX, y); ctx.lineTo(endX, y); ctx.stroke(); }

        // Edges (curved bezier with arrows)
        for (const e of edges) {
          const from = nodes.find(n => n.id === e.from);
          const to = nodes.find(n => n.id === e.to);
          if (!from || !to) continue;
          const fx = from.x + NODE_W / 2, fy = from.y + NODE_H;
          const tx = to.x + NODE_W / 2, ty = to.y;
          const dy = Math.abs(ty - fy) * 0.5;
          ctx.beginPath();
          ctx.moveTo(fx, fy);
          ctx.bezierCurveTo(fx, fy + dy, tx, ty - dy, tx, ty);
          ctx.strokeStyle = 'rgba(255,255,255,0.15)'; ctx.lineWidth = 2; ctx.stroke();
          // Arrow
          ctx.fillStyle = 'rgba(255,255,255,0.25)'; ctx.beginPath();
          ctx.moveTo(tx, ty); ctx.lineTo(tx - 5, ty - 8); ctx.lineTo(tx + 5, ty - 8);
          ctx.closePath(); ctx.fill();
        }

        // Nodes
        for (const n of nodes) {
          const sc = STATUS_COLORS[n.status] || STATUS_COLORS.available;
          const selected = n === selectedNode;
          ctx.fillStyle = sc.bg;
          ctx.strokeStyle = selected ? 'var(--accent, #89b4fa)' : sc.border;
          ctx.lineWidth = selected ? 2.5 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.fill(); ctx.stroke();
          // Status dot
          ctx.fillStyle = sc.dot; ctx.beginPath(); ctx.arc(n.x + 12, n.y + 16, 5, 0, Math.PI * 2); ctx.fill();
          // Name
          ctx.fillStyle = '#ddd'; ctx.font = '600 12px sans-serif'; ctx.textAlign = 'left';
          ctx.fillText(n.name.length > 18 ? n.name.substring(0, 17) + '\u2026' : n.name, n.x + 24, n.y + 20);
          // Description
          if (n.description) {
            ctx.fillStyle = '#888'; ctx.font = '10px sans-serif';
            ctx.fillText(n.description.substring(0, 22) + (n.description.length > 22 ? '\u2026' : ''), n.x + 8, n.y + 38);
          }
          // Reward
          if (n.reward) {
            ctx.fillStyle = '#ffd700'; ctx.font = '10px sans-serif';
            ctx.fillText('\u2605 ' + n.reward, n.x + 8, n.y + 52);
          }
        }

        // Connect preview line
        if (connectMode && connectFrom) {
          ctx.strokeStyle = 'rgba(250,200,50,0.5)'; ctx.lineWidth = 2;
          ctx.setLineDash([6, 4]);
          ctx.beginPath();
          ctx.moveTo(connectFrom.x + NODE_W / 2, connectFrom.y + NODE_H);
          ctx.lineTo((canvas._mx - offsetX) / zoom, (canvas._my - offsetY) / zoom);
          ctx.stroke(); ctx.setLineDash([]);
        }
        ctx.restore();
      }

      canvas._mx = 0; canvas._my = 0;

      function hitTest(sx, sy) {
        const wx = (sx - offsetX) / zoom, wy = (sy - offsetY) / zoom;
        for (let i = nodes.length - 1; i >= 0; i--) {
          const n = nodes[i];
          if (wx >= n.x && wx <= n.x + NODE_W && wy >= n.y && wy <= n.y + NODE_H) return n;
        }
        return null;
      }

      function showProps(node) {
        const el = document.getElementById('propsContent');
        if (!node) { el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:20px;">Select a quest node</p>'; return; }
        el.innerHTML =
          '<div class="prop-field"><label>Name</label><input id="pName" value="' + node.name.replace(/"/g, '&quot;') + '"></div>' +
          '<div class="prop-field"><label>Description</label><textarea id="pDesc" rows="2">' + node.description + '</textarea></div>' +
          '<div class="prop-field"><label>Required Items</label><input id="pItems" value="' + node.requiredItems + '" placeholder="key, sword"></div>' +
          '<div class="prop-field"><label>Reward</label><input id="pReward" value="' + node.reward + '" placeholder="100 gold"></div>' +
          '<div class="prop-field"><label>Status</label><select id="pStatus">' +
            '<option value="available"' + (node.status === 'available' ? ' selected' : '') + '>Available</option>' +
            '<option value="locked"' + (node.status === 'locked' ? ' selected' : '') + '>Locked</option>' +
            '<option value="completed"' + (node.status === 'completed' ? ' selected' : '') + '>Completed</option></select></div>' +
          '<div class="prop-field"><label>Prerequisites</label><div id="prereqList" class="prereq-list"></div></div>';

        const prereqs = edges.filter(e => e.to === node.id).map(e => nodes.find(n => n.id === e.from)).filter(Boolean);
        const prereqEl = document.getElementById('prereqList');
        if (prereqs.length) {
          prereqEl.innerHTML = prereqs.map(p => '<div class="prereq-item"><span class="prereq-dot"></span>' + p.name + '</div>').join('');
        } else { prereqEl.textContent = 'None'; }

        const bind = (id, key) => {
          const inp = document.getElementById(id);
          if (inp) inp.addEventListener('input', (e) => { pushUndo(); node[key] = e.target.value; render(); });
        };
        bind('pName', 'name'); bind('pDesc', 'description'); bind('pItems', 'requiredItems'); bind('pReward', 'reward');
        document.getElementById('pStatus').addEventListener('change', (e) => { pushUndo(); node.status = e.target.value; render(); });
      }

      function updateStatus() {
        document.getElementById('statusQuests').textContent = nodes.length + ' quests';
        document.getElementById('statusLinks').textContent = edges.length + ' links';
        document.getElementById('statusZoom').textContent = Math.round(zoom * 100) + '%';
        // Stats
        const statsEl = document.getElementById('statsContent');
        const avail = nodes.filter(n => n.status === 'available').length;
        const locked = nodes.filter(n => n.status === 'locked').length;
        const done = nodes.filter(n => n.status === 'completed').length;
        statsEl.innerHTML =
          '<div style="font-size:11px;display:grid;grid-template-columns:1fr 1fr;gap:4px;">' +
          '<span style="color:#4caf50">Available: ' + avail + '</span>' +
          '<span style="color:#666">Locked: ' + locked + '</span>' +
          '<span style="color:#ffd700">Completed: ' + done + '</span>' +
          '<span>Total: ' + nodes.length + '</span></div>';
      }

      function fitView() {
        if (nodes.length === 0) return;
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        for (const n of nodes) {
          minX = Math.min(minX, n.x); minY = Math.min(minY, n.y);
          maxX = Math.max(maxX, n.x + NODE_W); maxY = Math.max(maxY, n.y + NODE_H);
        }
        const pad = 40;
        const w = maxX - minX + pad * 2, h = maxY - minY + pad * 2;
        zoom = Math.min(canvas.width / w, canvas.height / h, 2);
        offsetX = canvas.width / 2 - (minX + (maxX - minX) / 2) * zoom;
        offsetY = canvas.height / 2 - (minY + (maxY - minY) / 2) * zoom;
        render(); updateStatus();
      }

      function autoLayout() {
        if (nodes.length === 0) return;
        pushUndo();
        // Simple layered layout
        const layers = {}; const visited = new Set();
        const roots = nodes.filter(n => !edges.some(e => e.to === n.id));
        if (roots.length === 0) roots.push(nodes[0]);
        function assignLayer(node, depth) {
          if (visited.has(node.id)) return;
          visited.add(node.id);
          layers[node.id] = Math.max(layers[node.id] || 0, depth);
          const children = edges.filter(e => e.from === node.id).map(e => nodes.find(n => n.id === e.to)).filter(Boolean);
          children.forEach(c => assignLayer(c, depth + 1));
        }
        roots.forEach(r => assignLayer(r, 0));
        nodes.filter(n => !visited.has(n.id)).forEach(n => { layers[n.id] = 0; });
        const byLayer = {};
        for (const n of nodes) { const l = layers[n.id] || 0; (byLayer[l] = byLayer[l] || []).push(n); }
        for (const [layer, group] of Object.entries(byLayer)) {
          group.forEach((n, i) => { n.x = 80 + i * (NODE_W + 30); n.y = 60 + parseInt(layer) * (NODE_H + 50); });
        }
        render();
      }

      // \u2500\u2500 Canvas events \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) { isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY; return; }
        const node = hitTest(e.offsetX, e.offsetY);
        if (connectMode && e.button === 0) {
          if (!connectFrom && node) { connectFrom = node; }
          else if (connectFrom && node && node !== connectFrom) {
            if (!edges.find(ed => ed.from === connectFrom.id && ed.to === node.id)) {
              pushUndo(); edges.push({ from: connectFrom.id, to: node.id });
            }
            connectFrom = null; updateStatus(); render();
          } else { connectFrom = null; }
          return;
        }
        if (node) {
          selectedNode = node; showProps(node);
          dragNode = node; dragOff = { x: (e.offsetX - offsetX) / zoom - node.x, y: (e.offsetY - offsetY) / zoom - node.y };
        } else { selectedNode = null; showProps(null); }
        render();
      });
      canvas.addEventListener('mousemove', (e) => {
        canvas._mx = e.offsetX; canvas._my = e.offsetY;
        if (isPanning) { offsetX = e.clientX - panSX; offsetY = e.clientY - panSY; render(); return; }
        if (dragNode) { dragNode.x = (e.offsetX - offsetX) / zoom - dragOff.x; dragNode.y = (e.offsetY - offsetY) / zoom - dragOff.y; render(); }
        if (connectMode && connectFrom) render();
      });
      canvas.addEventListener('mouseup', () => { isPanning = false; if (dragNode) { pushUndo(); } dragNode = null; });
      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const old = zoom; zoom *= e.deltaY < 0 ? 1.1 : 0.9; zoom = Math.max(0.2, Math.min(4, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / old; offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / old;
        render(); updateStatus();
      }, { passive: false });

      // \u2500\u2500 Buttons \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      document.getElementById('btnAdd').addEventListener('click', () => addNode());
      document.getElementById('btnConnect').addEventListener('click', () => {
        connectMode = !connectMode; connectFrom = null;
        document.getElementById('btnConnect').classList.toggle('active', connectMode);
        const badge = document.getElementById('statusMode');
        badge.className = connectMode ? 'mode-badge link' : 'mode-badge select';
        badge.textContent = connectMode ? 'LINK' : 'SELECT';
      });
      document.getElementById('btnDelete').addEventListener('click', () => {
        if (!selectedNode) return;
        pushUndo();
        edges = edges.filter(e => e.from !== selectedNode.id && e.to !== selectedNode.id);
        nodes = nodes.filter(n => n !== selectedNode);
        selectedNode = null; showProps(null); updateStatus(); render();
      });
      document.getElementById('btnAutoLayout').addEventListener('click', autoLayout);
      document.getElementById('btnFitView').addEventListener('click', fitView);
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restoreSnap(s); });

      // \u2500\u2500 Shortcuts \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('a', () => addNode());
      registerShortcut('c', () => document.getElementById('btnConnect').click());
      registerShortcut('Delete', () => document.getElementById('btnDelete').click());
      registerShortcut('f', () => fitView());

      // \u2500\u2500 Export \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Quest / Tech Tree Editor', ''];
        lines.push('return {');
        for (const n of nodes) {
          lines.push('  {');
          lines.push('    id = ' + n.id + ',');
          lines.push('    name = "' + n.name + '",');
          if (n.description) lines.push('    description = "' + n.description + '",');
          if (n.requiredItems) {
            const items = n.requiredItems.split(',').map(s => '"' + s.trim() + '"').join(', ');
            lines.push('    requiredItems = { ' + items + ' },');
          }
          if (n.reward) lines.push('    reward = "' + n.reward + '",');
          const prereqs = edges.filter(e => e.to === n.id).map(e => e.from);
          if (prereqs.length) lines.push('    prerequisites = { ' + prereqs.join(', ') + ' },');
          lines.push('    status = "' + n.status + '",');
          lines.push('  },');
        }
        lines.push('}');
        return lines.join('\\n');
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export Lua File', action: () => vscode.postMessage({ type: 'exportLua', content: buildLuaCode() }) },
        { label: 'Copy Lua Code', action: () => vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() }) },
        { label: 'Insert to Editor', action: () => vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() }) },
      ]);

      document.getElementById('btnCopyLua').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() });
      });

      // \u2500\u2500 Init \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      // Sample quest tree
      nodes = [
        { id: 1, name: 'Find the Key', x: 80, y: 50, description: 'Locate the dungeon key', requiredItems: '', reward: '50 gold', status: 'available' },
        { id: 2, name: 'Enter Dungeon', x: 80, y: 160, description: 'Enter the dark dungeon', requiredItems: 'key', reward: '', status: 'locked' },
        { id: 3, name: 'Defeat Boss', x: 80, y: 270, description: 'Defeat the dragon', requiredItems: '', reward: 'Dragon Sword', status: 'locked' },
      ];
      nextId = 4;
      edges = [{ from: 1, to: 2 }, { from: 2, to: 3 }];
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `)}};var kn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.guiWidget","GUI Widget Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"gui_layout.lua");break}}getHtml(){let e=L();return I(e,"GUI Widget Editor",`
      .editor-layout {
        display: grid; grid-template-columns: 180px 1fr 240px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .hierarchy-panel { grid-row: 2; background: var(--surface); border-right: 1px solid var(--border); overflow-y: auto; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: var(--bg); }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); overflow-y: auto; background: var(--surface); }

      .widget-item {
        padding: 4px 8px; cursor: pointer; font-size: 11px; border-radius: var(--radius);
        margin: 1px 4px; display: flex; align-items: center; gap: 6px; transition: background 0.08s;
      }
      .widget-item:hover { background: var(--hover); }
      .widget-item.sel { background: var(--selection); }
      .widget-item .type-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
      .widget-item .hidden-tag { font-size: 9px; color: var(--text-dim); margin-left: auto; }

      .prop-field { margin-bottom: 6px; }
      .prop-field label { display: block; font-size: 10px; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.3px; margin-bottom: 2px; }
      .prop-row { display: grid; grid-template-columns: 30px 1fr 30px 1fr; gap: 4px; align-items: center; margin-bottom: 4px; }
      .prop-row label { font-size: 10px; text-align: right; color: var(--text-dim); }
    `,`
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            <select id="addWidget" style="width:130px">
              <option value="">+ Add Widget...</option>
              <option value="Button">Button</option>
              <option value="Panel">Panel</option>
              <option value="Label">Label</option>
              <option value="ProgressBar">Progress Bar</option>
              <option value="Checkbox">Checkbox</option>
              <option value="Slider">Slider</option>
              <option value="Image">Image</option>
            </select>
            ${g("trash",{id:"btnDelete",title:"Delete (Del)",cls:"danger"})}
          </div>
          ${k()}
          <div class="group">
            ${g("undo",{id:"btnUndo",title:"Undo (Ctrl+Z)"})}
            ${g("redo",{id:"btnRedo",title:"Redo (Ctrl+Y)"})}
          </div>
          ${k()}
          <div class="group">
            <button id="btnGrid" title="Toggle Grid Snap">${c.grid} Snap</button>
            <button id="btnAlignH" title="Align Horizontal Centers">\u27F7</button>
            <button id="btnAlignV" title="Align Vertical Centers">\u27D8</button>
          </div>
          ${A()}
          <div class="group">
            ${g("copy",{id:"btnCopyLua",title:"Copy Lua Code"})}
            ${g("insert",{id:"btnInsert",title:"Insert to Editor"})}
          </div>
          ${k()}
          <button id="btnExport" class="primary">${c.exportFile} Export \u25BE</button>
        </div>

        <!-- Hierarchy -->
        <div class="hierarchy-panel">
          ${b("Widget Hierarchy",'<div id="hierarchy"></div>')}
        </div>

        <!-- Canvas -->
        <div class="canvas-area"><canvas id="guiCanvas"></canvas></div>

        <!-- Properties -->
        <div class="props-panel">
          ${b("Properties",'<div id="propsContent"><p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:20px;">Select a widget</p></div>')}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusWidgets" class="badge">0 widgets</span>
          </span>
          <div class="sep"></div>
          <span id="statusSel">No selection</span>
          <div class="sep"></div>
          <span id="statusGrid">Snap: Off</span>
          <div class="spacer"></div>
          <span class="dirty-indicator">${c.clean}</span>
        </div>
      </div>
    `,`
      const canvas = document.getElementById('guiCanvas');
      const ctx = canvas.getContext('2d');
      let widgets = [], selectedIdx = -1;
      let dragWidget = null, dragOff = { x: 0, y: 0 };
      let nextId = 1, gridSnap = false;
      const undo = new UndoStack(60);
      const SNAP = 8;

      const TYPE_COLORS = {
        Button: '#89b4fa', Panel: '#6c7086', Label: '#a6e3a1',
        ProgressBar: '#f9e2af', Checkbox: '#cba6f7', Slider: '#fab387', Image: '#f38ba8',
      };

      function snapshot() { return JSON.parse(JSON.stringify({ widgets, selectedIdx, nextId })); }
      function restoreSnap(s) { widgets = s.widgets; selectedIdx = s.selectedIdx; nextId = s.nextId; refreshAll(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      const WIDGET_DEFAULTS = {
        Button: { w: 120, h: 36, text: 'Click Me', color: '#89b4fa', fontSize: 14, anchor: 'topLeft' },
        Panel: { w: 200, h: 150, text: '', color: '#1e1e2e', fontSize: 12, anchor: 'topLeft' },
        Label: { w: 100, h: 24, text: 'Label', color: 'transparent', fontSize: 14, anchor: 'topLeft' },
        ProgressBar: { w: 150, h: 20, text: '', color: '#a6e3a1', fontSize: 10, anchor: 'topLeft', value: 0.65 },
        Checkbox: { w: 24, h: 24, text: 'Option', color: '#45475a', fontSize: 12, anchor: 'topLeft', checked: false },
        Slider: { w: 150, h: 20, text: '', color: '#6c7086', fontSize: 10, anchor: 'topLeft', value: 0.5 },
        Image: { w: 64, h: 64, text: 'img', color: '#313244', fontSize: 10, anchor: 'topLeft' },
      };

      function snap(v) { return gridSnap ? Math.round(v / SNAP) * SNAP : v; }

      function addWidget(type) {
        pushUndo();
        const d = WIDGET_DEFAULTS[type];
        widgets.push({
          id: nextId++, type, name: type.toLowerCase() + '_' + nextId,
          x: snap(60 + widgets.length * 20), y: snap(60 + widgets.length * 20),
          w: d.w, h: d.h, text: d.text, color: d.color,
          fontSize: d.fontSize, anchor: d.anchor, visible: true,
          value: d.value, checked: d.checked,
        });
        selectedIdx = widgets.length - 1;
        refreshAll();
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight; render();
      }

      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // Grid
        if (gridSnap) {
          ctx.strokeStyle = 'rgba(255,255,255,0.03)'; ctx.lineWidth = 1;
          for (let x = 0; x < canvas.width; x += SNAP) { ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, canvas.height); ctx.stroke(); }
          for (let y = 0; y < canvas.height; y += SNAP) { ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(canvas.width, y); ctx.stroke(); }
        }

        // Reference frame (game viewport)
        ctx.strokeStyle = 'rgba(255,255,255,0.1)'; ctx.lineWidth = 1; ctx.setLineDash([4, 4]);
        ctx.strokeRect(20, 20, 800, 600); ctx.setLineDash([]);
        ctx.fillStyle = 'rgba(255,255,255,0.15)'; ctx.font = '10px sans-serif'; ctx.textAlign = 'left';
        ctx.fillText('800 \xD7 600 viewport', 24, 16);

        for (let i = 0; i < widgets.length; i++) {
          const w = widgets[i];
          if (!w.visible) continue;
          const sel = i === selectedIdx;

          ctx.fillStyle = w.color; ctx.strokeStyle = sel ? 'var(--accent, #89b4fa)' : 'rgba(255,255,255,0.08)';
          ctx.lineWidth = sel ? 2 : 1;

          switch (w.type) {
            case 'Button':
              ctx.beginPath(); ctx.roundRect(w.x, w.y, w.w, w.h, 4); ctx.fill(); ctx.stroke();
              ctx.fillStyle = '#1e1e2e'; ctx.font = 'bold ' + w.fontSize + 'px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
              ctx.fillText(w.text, w.x + w.w / 2, w.y + w.h / 2);
              break;
            case 'Panel':
              ctx.fillRect(w.x, w.y, w.w, w.h); ctx.strokeRect(w.x, w.y, w.w, w.h);
              break;
            case 'Label':
              ctx.fillStyle = '#cdd6f4'; ctx.font = w.fontSize + 'px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'top';
              ctx.fillText(w.text, w.x, w.y);
              if (sel) { ctx.strokeStyle = 'var(--accent, #89b4fa)'; ctx.strokeRect(w.x - 2, w.y - 2, w.w + 4, w.h + 4); }
              break;
            case 'ProgressBar':
              ctx.fillStyle = '#313244'; ctx.fillRect(w.x, w.y, w.w, w.h);
              ctx.fillStyle = w.color; ctx.fillRect(w.x, w.y, w.w * (w.value || 0), w.h);
              ctx.strokeRect(w.x, w.y, w.w, w.h);
              ctx.fillStyle = '#1e1e2e'; ctx.font = '10px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
              ctx.fillText(Math.round((w.value || 0) * 100) + '%', w.x + w.w / 2, w.y + w.h / 2);
              break;
            case 'Checkbox':
              ctx.strokeRect(w.x, w.y, 18, 18);
              if (w.checked) { ctx.fillStyle = '#a6e3a1'; ctx.fillRect(w.x + 3, w.y + 3, 12, 12); }
              ctx.fillStyle = '#cdd6f4'; ctx.font = '12px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'middle';
              ctx.fillText(w.text, w.x + 24, w.y + 9);
              break;
            case 'Slider':
              ctx.fillStyle = '#313244'; ctx.fillRect(w.x, w.y + 6, w.w, 8);
              ctx.fillStyle = w.color;
              const knobX = w.x + w.w * (w.value || 0);
              ctx.beginPath(); ctx.arc(knobX, w.y + 10, 8, 0, Math.PI * 2); ctx.fill();
              if (sel) { ctx.strokeStyle = 'var(--accent, #89b4fa)'; ctx.strokeRect(w.x - 2, w.y - 2, w.w + 4, w.h + 4); }
              break;
            case 'Image':
              ctx.fillRect(w.x, w.y, w.w, w.h); ctx.strokeRect(w.x, w.y, w.w, w.h);
              ctx.fillStyle = '#6c7086'; ctx.font = '10px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
              ctx.fillText('[' + w.text + ']', w.x + w.w / 2, w.y + w.h / 2);
              break;
          }

          if (sel) {
            ctx.fillStyle = 'var(--accent, #89b4fa)';
            const hs = 4;
            [[w.x-hs,w.y-hs],[w.x+w.w-hs,w.y-hs],[w.x-hs,w.y+w.h-hs],[w.x+w.w-hs,w.y+w.h-hs]].forEach(([hx,hy]) => {
              ctx.fillRect(hx, hy, hs*2, hs*2);
            });
          }
        }
      }

      function hitTest(sx, sy) {
        for (let i = widgets.length - 1; i >= 0; i--) {
          const w = widgets[i];
          if (sx >= w.x && sx <= w.x + w.w && sy >= w.y && sy <= w.y + w.h) return i;
        }
        return -1;
      }

      function showProps(idx) {
        const el = document.getElementById('propsContent');
        if (idx < 0) { el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:20px;">Select a widget</p>'; updateStatus(); return; }
        const w = widgets[idx];
        let html = '<div class="prop-field"><label>Name</label><input id="pName" value="' + w.name.replace(/"/g, '&quot;') + '"></div>';
        html += '<div class="prop-row"><label>X</label><input type="number" id="pX" value="' + w.x + '" style="width:60px"><label>Y</label><input type="number" id="pY" value="' + w.y + '" style="width:60px"></div>';
        html += '<div class="prop-row"><label>W</label><input type="number" id="pW" value="' + w.w + '" style="width:60px"><label>H</label><input type="number" id="pH" value="' + w.h + '" style="width:60px"></div>';
        html += '<div class="prop-field"><label>Text</label><input id="pText" value="' + (w.text || '').replace(/"/g, '&quot;') + '"></div>';
        html += '<div class="prop-field"><label>Color</label><input type="color" id="pColor" value="' + (w.color.startsWith('#') ? w.color : '#333333') + '" style="width:100%"></div>';
        html += '<div class="prop-field"><label>Font Size</label><input type="number" id="pFont" value="' + w.fontSize + '" min="8" max="48" style="width:60px"></div>';
        html += '<div class="prop-field"><label>Anchor</label><select id="pAnchor" style="width:100%"><option value="topLeft">Top Left</option><option value="topRight">Top Right</option><option value="center">Center</option><option value="bottomLeft">Bottom Left</option><option value="bottomRight">Bottom Right</option></select></div>';
        html += '<div class="prop-field" style="display:flex;align-items:center;gap:6px"><input type="checkbox" id="pVisible" ' + (w.visible ? 'checked' : '') + '><label style="margin:0">Visible</label></div>';
        if (w.value !== undefined) html += '<div class="prop-field"><label>Value</label><input type="range" id="pVal" value="' + w.value + '" min="0" max="1" step="0.01" style="width:100%"><span id="pValDisp" style="font-size:10px;font-family:var(--font-mono)">' + (w.value * 100).toFixed(0) + '%</span></div>';
        if (w.checked !== undefined) html += '<div class="prop-field" style="display:flex;align-items:center;gap:6px"><input type="checkbox" id="pChecked" ' + (w.checked ? 'checked' : '') + '><label style="margin:0">Checked</label></div>';
        el.innerHTML = html;

        document.getElementById('pAnchor').value = w.anchor;

        const bind = (id, key, parse) => {
          const inp = document.getElementById(id);
          if (inp) inp.addEventListener('input', (e) => { pushUndo(); w[key] = parse ? parse(e.target.value) : e.target.value; render(); if (key === 'name') refreshHierarchy(); });
        };
        bind('pName', 'name'); bind('pText', 'text'); bind('pColor', 'color');
        bind('pX', 'x', parseFloat); bind('pY', 'y', parseFloat);
        bind('pW', 'w', parseFloat); bind('pH', 'h', parseFloat);
        bind('pFont', 'fontSize', parseInt);
        const valInp = document.getElementById('pVal');
        if (valInp) valInp.addEventListener('input', (e) => { pushUndo(); w.value = parseFloat(e.target.value); document.getElementById('pValDisp').textContent = (w.value * 100).toFixed(0) + '%'; render(); });
        document.getElementById('pAnchor').addEventListener('change', (e) => { pushUndo(); w.anchor = e.target.value; });
        document.getElementById('pVisible').addEventListener('change', (e) => { pushUndo(); w.visible = e.target.checked; render(); refreshHierarchy(); });
        const chk = document.getElementById('pChecked');
        if (chk) chk.addEventListener('change', (e) => { pushUndo(); w.checked = e.target.checked; render(); });
        updateStatus();
      }

      function updateStatus() {
        document.getElementById('statusWidgets').textContent = widgets.length + ' widgets';
        document.getElementById('statusSel').textContent = selectedIdx >= 0 ? widgets[selectedIdx].name : 'No selection';
        document.getElementById('statusGrid').textContent = 'Snap: ' + (gridSnap ? 'On' : 'Off');
      }

      function refreshHierarchy() {
        const el = document.getElementById('hierarchy');
        el.innerHTML = '';
        widgets.forEach((w, i) => {
          const div = document.createElement('div');
          div.className = 'widget-item' + (i === selectedIdx ? ' sel' : '');
          div.innerHTML = '<span class="type-dot" style="background:' + (TYPE_COLORS[w.type] || '#6c7086') + '"></span>' +
            '<span style="flex:1">' + w.name + '</span>' +
            (!w.visible ? '<span class="hidden-tag">hidden</span>' : '');
          div.addEventListener('click', () => { selectedIdx = i; showProps(i); refreshHierarchy(); render(); });
          el.appendChild(div);
        });
        updateStatus();
      }

      function refreshAll() { refreshHierarchy(); showProps(selectedIdx); render(); }

      // \u2500\u2500 Canvas events \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      canvas.addEventListener('mousedown', (e) => {
        const idx = hitTest(e.offsetX, e.offsetY);
        if (idx >= 0) {
          selectedIdx = idx;
          dragWidget = widgets[idx];
          dragOff = { x: e.offsetX - widgets[idx].x, y: e.offsetY - widgets[idx].y };
        } else { selectedIdx = -1; }
        showProps(selectedIdx); refreshHierarchy(); render();
      });
      canvas.addEventListener('mousemove', (e) => {
        if (dragWidget) {
          dragWidget.x = snap(Math.round(e.offsetX - dragOff.x));
          dragWidget.y = snap(Math.round(e.offsetY - dragOff.y));
          render();
        }
      });
      canvas.addEventListener('mouseup', () => { if (dragWidget) { pushUndo(); showProps(selectedIdx); } dragWidget = null; });

      // \u2500\u2500 Toolbar \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      document.getElementById('addWidget').addEventListener('change', (e) => {
        if (e.target.value) { addWidget(e.target.value); e.target.value = ''; }
      });
      document.getElementById('btnDelete').addEventListener('click', () => {
        if (selectedIdx >= 0) { pushUndo(); widgets.splice(selectedIdx, 1); selectedIdx = -1; refreshAll(); }
      });
      document.getElementById('btnGrid').addEventListener('click', () => {
        gridSnap = !gridSnap;
        document.getElementById('btnGrid').classList.toggle('active', gridSnap);
        updateStatus(); render();
      });
      document.getElementById('btnAlignH').addEventListener('click', () => {
        if (selectedIdx < 0 || widgets.length < 2) return;
        pushUndo();
        const ref = widgets[selectedIdx];
        const cx = ref.x + ref.w / 2;
        widgets.forEach((w, i) => { if (i !== selectedIdx) w.x = snap(cx - w.w / 2); });
        render();
      });
      document.getElementById('btnAlignV').addEventListener('click', () => {
        if (selectedIdx < 0 || widgets.length < 2) return;
        pushUndo();
        const ref = widgets[selectedIdx];
        const cy = ref.y + ref.h / 2;
        widgets.forEach((w, i) => { if (i !== selectedIdx) w.y = snap(cy - w.h / 2); });
        render();
      });
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restoreSnap(s); });

      // \u2500\u2500 Shortcuts \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('Delete', () => document.getElementById('btnDelete').click());
      registerShortcut('ctrl+d', () => {
        if (selectedIdx < 0) return;
        pushUndo();
        const src = widgets[selectedIdx];
        const clone = JSON.parse(JSON.stringify(src));
        clone.id = nextId++; clone.name = src.type.toLowerCase() + '_' + nextId;
        clone.x += 20; clone.y += 20;
        widgets.push(clone); selectedIdx = widgets.length - 1; refreshAll();
      });

      // \u2500\u2500 Export \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D GUI Widget Editor', '-- Usage: local layout = lurek.ui.load_layout(data)', ''];
        lines.push('return {');
        for (const w of widgets) {
          lines.push('  {');
          lines.push('    type = "' + w.type + '", name = "' + w.name + '",');
          lines.push('    x = ' + w.x + ', y = ' + w.y + ', w = ' + w.w + ', h = ' + w.h + ',');
          if (w.text) lines.push('    text = "' + w.text + '",');
          lines.push('    color = "' + w.color + '", fontSize = ' + w.fontSize + ',');
          lines.push('    anchor = "' + w.anchor + '", visible = ' + w.visible + ',');
          if (w.value !== undefined) lines.push('    value = ' + w.value + ',');
          if (w.checked !== undefined) lines.push('    checked = ' + w.checked + ',');
          lines.push('  },');
        }
        lines.push('}');
        return lines.join('\\n');
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export Lua File', action: () => vscode.postMessage({ type: 'exportLua', content: buildLuaCode() }) },
        { label: 'Copy Lua Code', action: () => vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() }) },
        { label: 'Insert to Editor', action: () => vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() }) },
      ]);

      document.getElementById('btnCopyLua').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() });
      });

      // \u2500\u2500 Init \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      widgets = [
        { id: 1, type: 'Panel', name: 'settings_panel', x: 50, y: 50, w: 200, h: 150, text: '', color: '#1e1e2e', fontSize: 12, anchor: 'topLeft', visible: true },
        { id: 2, type: 'Label', name: 'title_label', x: 80, y: 60, w: 100, h: 24, text: 'Settings', color: 'transparent', fontSize: 16, anchor: 'topLeft', visible: true },
        { id: 3, type: 'Button', name: 'apply_btn', x: 80, y: 120, w: 120, h: 36, text: 'Apply', color: '#89b4fa', fontSize: 14, anchor: 'topLeft', visible: true },
      ];
      nextId = 4; selectedIdx = -1;
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
      refreshAll();
    `)}};var Mn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.aiBehavior","AI Behavior Tree")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"behavior_tree.lua");break}}getHtml(){let e=L();return I(e,"AI Behavior Tree",`
      .editor-layout {
        display: grid; grid-template-columns: 180px 1fr 240px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .palette-panel { grid-row: 2; background: var(--surface); border-right: 1px solid var(--border); overflow-y: auto; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: var(--bg); }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); overflow-y: auto; background: var(--surface); }

      .drag-node {
        padding: 5px 8px; font-size: 11px; cursor: pointer; border-radius: var(--radius);
        margin: 1px 4px; display: flex; align-items: center; gap: 6px;
        border: 1px solid transparent; transition: border-color 0.1s, background 0.08s;
      }
      .drag-node:hover { border-color: var(--accent); background: var(--hover); }
      .drag-node .cat-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }

      .prop-field { margin-bottom: 6px; }
      .prop-field label { display: block; font-size: 10px; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.3px; margin-bottom: 2px; }
      .prop-field .type-badge {
        display: inline-block; padding: 1px 8px; border-radius: 9px;
        font-size: 10px; font-weight: 600; margin-bottom: 4px;
      }

      .sim-badge { padding: 1px 8px; border-radius: 9px; font-size: 10px; font-weight: 600; }
      .sim-badge.idle { background: var(--surface-2); color: var(--text-dim); }
      .sim-badge.running { background: #ff9800; color: #1e1e2e; }
    `,`
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            ${g("trash",{id:"btnClearTree",title:"Clear Tree",cls:"danger"})}
            ${g("trash",{id:"btnDelete",title:"Delete Node (Del)",cls:"danger"})}
          </div>
          ${k()}
          <div class="group">
            ${g("undo",{id:"btnUndo",title:"Undo (Ctrl+Z)"})}
            ${g("redo",{id:"btnRedo",title:"Redo (Ctrl+Y)"})}
          </div>
          ${k()}
          <div class="group">
            <button id="btnSimulate">${c.play} Simulate</button>
            <button id="btnReset">${c.refresh} Reset</button>
          </div>
          ${k()}
          <div class="group">
            ${g("layout",{id:"btnAutoLayout",title:"Auto Layout"})}
            ${g("fitView",{id:"btnFitView",title:"Fit View (F)"})}
          </div>
          ${A()}
          <div class="group">
            ${g("copy",{id:"btnCopyLua",title:"Copy Lua Code"})}
            ${g("insert",{id:"btnInsert",title:"Insert to Editor"})}
          </div>
          ${k()}
          <button id="btnExport" class="primary">${c.exportFile} Export \u25BE</button>
        </div>

        <!-- Palette -->
        <div class="palette-panel">
          ${b("Composites",`
            <div class="drag-node" data-type="Sequence"><span class="cat-dot" style="background:#4caf50"></span>Sequence</div>
            <div class="drag-node" data-type="Selector"><span class="cat-dot" style="background:#4caf50"></span>Selector</div>
            <div class="drag-node" data-type="Parallel"><span class="cat-dot" style="background:#4caf50"></span>Parallel</div>
            <div class="drag-node" data-type="RandomSelector"><span class="cat-dot" style="background:#4caf50"></span>RandomSelector</div>
          `)}
          ${b("Decorators",`
            <div class="drag-node" data-type="Inverter"><span class="cat-dot" style="background:#f38ba8"></span>Inverter</div>
            <div class="drag-node" data-type="Repeater"><span class="cat-dot" style="background:#f38ba8"></span>Repeater</div>
            <div class="drag-node" data-type="Succeeder"><span class="cat-dot" style="background:#f38ba8"></span>Succeeder</div>
            <div class="drag-node" data-type="Cooldown"><span class="cat-dot" style="background:#f38ba8"></span>Cooldown</div>
            <div class="drag-node" data-type="Guard"><span class="cat-dot" style="background:#f38ba8"></span>Guard</div>
          `)}
          ${b("Conditions",`
            <div class="drag-node" data-type="HasTarget"><span class="cat-dot" style="background:#89b4fa"></span>HasTarget</div>
            <div class="drag-node" data-type="InRange"><span class="cat-dot" style="background:#89b4fa"></span>InRange</div>
            <div class="drag-node" data-type="HealthCheck"><span class="cat-dot" style="background:#89b4fa"></span>HealthCheck</div>
            <div class="drag-node" data-type="Custom"><span class="cat-dot" style="background:#89b4fa"></span>Custom</div>
          `)}
          ${b("Actions",`
            <div class="drag-node" data-type="MoveTo"><span class="cat-dot" style="background:#f9e2af"></span>MoveTo</div>
            <div class="drag-node" data-type="Attack"><span class="cat-dot" style="background:#f9e2af"></span>Attack</div>
            <div class="drag-node" data-type="Flee"><span class="cat-dot" style="background:#f9e2af"></span>Flee</div>
            <div class="drag-node" data-type="Patrol"><span class="cat-dot" style="background:#f9e2af"></span>Patrol</div>
          `)}
        </div>

        <!-- Canvas -->
        <div class="canvas-area"><canvas id="btCanvas"></canvas></div>

        <!-- Properties -->
        <div class="props-panel">
          ${b("Node Properties",'<div id="propsContent"><p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:20px;">Click palette to add nodes</p></div>')}
          ${b("Tree Stats",'<div id="treeStats"></div>',!0)}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusNodes" class="badge">0 nodes</span>
          </span>
          <div class="sep"></div>
          <span id="statusDepth">Depth: 0</span>
          <div class="sep"></div>
          <span id="statusSim" class="sim-badge idle">IDLE</span>
          <div class="spacer"></div>
          <span id="statusZoom">100%</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${c.clean}</span>
        </div>
      </div>
    `,`
      const canvas = document.getElementById('btCanvas');
      const ctx = canvas.getContext('2d');
      let nodes = [], selectedNode = null, dragNode = null, dragOff = { x: 0, y: 0 };
      let offsetX = 0, offsetY = 0, zoom = 1;
      let isPanning = false, panSX = 0, panSY = 0;
      let nextId = 1;
      const NODE_W = 130, NODE_H = 44;
      const undo = new UndoStack(60);

      function snapshot() { return JSON.parse(JSON.stringify({ nodes, nextId })); }
      function restoreSnap(s) { nodes = s.nodes; nextId = s.nextId; selectedNode = null; showProps(null); updateStatus(); render(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      const CATEGORIES = {
        Sequence: 'composite', Selector: 'composite', Parallel: 'composite', RandomSelector: 'composite',
        Inverter: 'decorator', Repeater: 'decorator', Succeeder: 'decorator', Cooldown: 'decorator', Guard: 'decorator',
        HasTarget: 'condition', InRange: 'condition', HealthCheck: 'condition', Custom: 'condition',
        MoveTo: 'action', Attack: 'action', Flee: 'action', Patrol: 'action'
      };
      const CAT_COLORS = {
        composite: { bg: '#1a3a1a', border: '#3a6a3a', dot: '#4caf50' },
        decorator: { bg: '#3a1a2a', border: '#6a3a4a', dot: '#f38ba8' },
        condition: { bg: '#1a2a3a', border: '#3a4a6a', dot: '#89b4fa' },
        action:    { bg: '#3a3a1a', border: '#5a5a2a', dot: '#f9e2af' },
      };
      const STATUS_COLORS = { success: '#4caf50', failure: '#f44336', running: '#ff9800', idle: '#585b70' };

      function addNode(type, x, y) {
        pushUndo();
        const node = {
          id: nextId++, type, category: CATEGORIES[type] || 'action',
          x: x ?? (canvas.width / 2 - NODE_W / 2), y: y ?? (60 + nodes.length * 60),
          parentId: null, status: 'idle', params: {}
        };
        if (type === 'Cooldown') node.params.duration = 2.0;
        if (type === 'Repeater') node.params.times = 3;
        if (type === 'InRange') node.params.range = 100;
        if (type === 'HealthCheck') node.params.threshold = 0.3;
        if (type === 'Custom') node.params.func = 'myCondition';
        nodes.push(node);
        if (selectedNode && (selectedNode.category === 'composite' || selectedNode.category === 'decorator')) {
          node.parentId = selectedNode.id;
          layoutTree();
        }
        selectedNode = node; showProps(node);
        updateStatus(); render();
      }

      function getChildren(parentId) { return nodes.filter(n => n.parentId === parentId); }

      function layoutTree() {
        const roots = nodes.filter(n => !n.parentId);
        let startX = 60;
        for (const root of roots) { startX = layoutSubtree(root, startX, 40); startX += 40; }
      }

      function layoutSubtree(node, startX, y) {
        const children = getChildren(node.id);
        node.y = y;
        if (children.length === 0) { node.x = startX; return startX + NODE_W + 20; }
        let x = startX;
        for (const child of children) { x = layoutSubtree(child, x, y + 80); }
        node.x = (startX + x - NODE_W - 20) / 2;
        return x;
      }

      function getTreeDepth() {
        function depth(nodeId) {
          const children = getChildren(nodeId);
          if (children.length === 0) return 1;
          return 1 + Math.max(...children.map(c => depth(c.id)));
        }
        const roots = nodes.filter(n => !n.parentId);
        return roots.length ? Math.max(...roots.map(r => depth(r.id))) : 0;
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight; render();
      }

      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.save(); ctx.translate(offsetX, offsetY); ctx.scale(zoom, zoom);

        // Grid
        ctx.strokeStyle = 'rgba(255,255,255,0.03)'; ctx.lineWidth = 1;
        const gs = 40, startX = -offsetX / zoom, startY = -offsetY / zoom;
        const endX = startX + canvas.width / zoom, endY = startY + canvas.height / zoom;
        for (let x = Math.floor(startX / gs) * gs; x < endX; x += gs) { ctx.beginPath(); ctx.moveTo(x, startY); ctx.lineTo(x, endY); ctx.stroke(); }
        for (let y = Math.floor(startY / gs) * gs; y < endY; y += gs) { ctx.beginPath(); ctx.moveTo(startX, y); ctx.lineTo(endX, y); ctx.stroke(); }

        // Edges (curved)
        for (const n of nodes) {
          if (!n.parentId) continue;
          const parent = nodes.find(p => p.id === n.parentId);
          if (!parent) continue;
          const fx = parent.x + NODE_W / 2, fy = parent.y + NODE_H;
          const tx = n.x + NODE_W / 2, ty = n.y;
          const dy = Math.abs(ty - fy) * 0.4;
          ctx.beginPath(); ctx.moveTo(fx, fy);
          ctx.bezierCurveTo(fx, fy + dy, tx, ty - dy, tx, ty);
          ctx.strokeStyle = 'rgba(255,255,255,0.15)'; ctx.lineWidth = 2; ctx.stroke();
          // Arrow
          ctx.fillStyle = 'rgba(255,255,255,0.25)'; ctx.beginPath();
          ctx.moveTo(tx, ty); ctx.lineTo(tx - 4, ty - 7); ctx.lineTo(tx + 4, ty - 7);
          ctx.closePath(); ctx.fill();
        }

        // Nodes
        for (const n of nodes) {
          const cc = CAT_COLORS[n.category] || CAT_COLORS.action;
          const sel = n === selectedNode;
          ctx.fillStyle = cc.bg;
          ctx.strokeStyle = sel ? 'var(--accent, #89b4fa)' : cc.border;
          ctx.lineWidth = sel ? 2.5 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.fill(); ctx.stroke();
          // Category color bar
          ctx.fillStyle = cc.dot; ctx.fillRect(n.x, n.y, 4, NODE_H);
          // Status indicator
          ctx.fillStyle = STATUS_COLORS[n.status]; ctx.beginPath();
          ctx.arc(n.x + 16, n.y + NODE_H / 2, 5, 0, Math.PI * 2); ctx.fill();
          // Label
          ctx.fillStyle = '#ddd'; ctx.font = '600 11px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'middle';
          ctx.fillText(n.type, n.x + 26, n.y + NODE_H / 2);
          // Params hint
          const paramKeys = Object.keys(n.params);
          if (paramKeys.length) {
            ctx.fillStyle = '#888'; ctx.font = '9px sans-serif';
            const hint = paramKeys.map(k => k + '=' + n.params[k]).join(' ');
            ctx.fillText(hint.substring(0, 18), n.x + 16, n.y + NODE_H - 6);
          }
        }
        ctx.restore();
      }

      function hitTest(sx, sy) {
        const wx = (sx - offsetX) / zoom, wy = (sy - offsetY) / zoom;
        for (let i = nodes.length - 1; i >= 0; i--) {
          const n = nodes[i];
          if (wx >= n.x && wx <= n.x + NODE_W && wy >= n.y && wy <= n.y + NODE_H) return n;
        }
        return null;
      }

      function showProps(node) {
        const el = document.getElementById('propsContent');
        if (!node) { el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:20px;">Click palette to add nodes</p>'; return; }
        const cc = CAT_COLORS[node.category] || CAT_COLORS.action;
        let html = '<div class="prop-field"><span class="type-badge" style="background:' + cc.bg + ';border:1px solid ' + cc.border + '">' + node.type + '</span></div>';
        html += '<div class="prop-field"><label>Category</label><span style="font-size:11px;color:' + cc.dot + '">' + node.category + '</span></div>';
        html += '<div class="prop-field"><label>Parent</label><select id="pParent" style="width:100%"><option value="">Root (no parent)</option>';
        for (const n of nodes) {
          if (n.id === node.id) continue;
          if (n.category === 'composite' || n.category === 'decorator') {
            html += '<option value="' + n.id + '"' + (node.parentId === n.id ? ' selected' : '') + '>' + n.type + ' #' + n.id + '</option>';
          }
        }
        html += '</select></div>';
        for (const [k, v] of Object.entries(node.params)) {
          html += '<div class="prop-field"><label>' + k + '</label><input id="pp_' + k + '" value="' + v + '" ' + (typeof v === 'number' ? 'type="number" step="0.1"' : '') + ' style="width:100%"></div>';
        }
        // Children list
        const children = getChildren(node.id);
        if (children.length) {
          html += '<div class="prop-field"><label>Children (' + children.length + ')</label><div style="font-size:11px;color:var(--text-dim)">' +
            children.map(c => c.type + ' #' + c.id).join('<br>') + '</div></div>';
        }
        el.innerHTML = html;

        document.getElementById('pParent').addEventListener('change', (e) => {
          pushUndo(); node.parentId = e.target.value ? parseInt(e.target.value) : null;
          layoutTree(); render(); updateStatus();
        });
        for (const k of Object.keys(node.params)) {
          const inp = document.getElementById('pp_' + k);
          if (inp) inp.addEventListener('input', (e) => {
            pushUndo();
            node.params[k] = typeof node.params[k] === 'number' ? parseFloat(e.target.value) || 0 : e.target.value;
          });
        }
      }

      function updateStatus() {
        document.getElementById('statusNodes').textContent = nodes.length + ' nodes';
        document.getElementById('statusDepth').textContent = 'Depth: ' + getTreeDepth();
        document.getElementById('statusZoom').textContent = Math.round(zoom * 100) + '%';
        const statsEl = document.getElementById('treeStats');
        const counts = {};
        for (const n of nodes) counts[n.category] = (counts[n.category] || 0) + 1;
        statsEl.innerHTML = '<div style="font-size:11px;display:grid;grid-template-columns:1fr 1fr;gap:4px">' +
          Object.entries(counts).map(([k, v]) => '<span style="color:' + (CAT_COLORS[k]?.dot || '#888') + '">' + k + ': ' + v + '</span>').join('') +
          '</div>';
      }

      function fitView() {
        if (nodes.length === 0) return;
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        for (const n of nodes) { minX = Math.min(minX, n.x); minY = Math.min(minY, n.y); maxX = Math.max(maxX, n.x + NODE_W); maxY = Math.max(maxY, n.y + NODE_H); }
        const pad = 40, w = maxX - minX + pad * 2, h = maxY - minY + pad * 2;
        zoom = Math.min(canvas.width / w, canvas.height / h, 2);
        offsetX = canvas.width / 2 - (minX + (maxX - minX) / 2) * zoom;
        offsetY = canvas.height / 2 - (minY + (maxY - minY) / 2) * zoom;
        render(); updateStatus();
      }

      // \u2500\u2500 Palette \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      document.querySelectorAll('.drag-node').forEach(el => {
        el.addEventListener('click', () => addNode(el.dataset.type));
      });

      // \u2500\u2500 Canvas events \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) { isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY; return; }
        const node = hitTest(e.offsetX, e.offsetY);
        if (node) {
          selectedNode = node; showProps(node);
          dragNode = node; dragOff = { x: (e.offsetX - offsetX) / zoom - node.x, y: (e.offsetY - offsetY) / zoom - node.y };
        } else { selectedNode = null; showProps(null); }
        render();
      });
      canvas.addEventListener('mousemove', (e) => {
        if (isPanning) { offsetX = e.clientX - panSX; offsetY = e.clientY - panSY; render(); return; }
        if (dragNode) { dragNode.x = (e.offsetX - offsetX) / zoom - dragOff.x; dragNode.y = (e.offsetY - offsetY) / zoom - dragOff.y; render(); }
      });
      canvas.addEventListener('mouseup', () => { isPanning = false; if (dragNode) pushUndo(); dragNode = null; });
      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const old = zoom; zoom *= e.deltaY < 0 ? 1.1 : 0.9; zoom = Math.max(0.2, Math.min(4, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / old;
        offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / old; render(); updateStatus();
      }, { passive: false });

      // \u2500\u2500 Buttons \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      document.getElementById('btnClearTree').addEventListener('click', () => { pushUndo(); nodes = []; selectedNode = null; showProps(null); updateStatus(); render(); });
      document.getElementById('btnDelete').addEventListener('click', () => {
        if (!selectedNode) return;
        pushUndo();
        const delId = selectedNode.id;
        nodes.filter(n => n.parentId === delId).forEach(n => { n.parentId = null; });
        nodes = nodes.filter(n => n.id !== delId);
        selectedNode = null; showProps(null); updateStatus(); render();
      });
      document.getElementById('btnAutoLayout').addEventListener('click', () => { pushUndo(); layoutTree(); render(); });
      document.getElementById('btnFitView').addEventListener('click', fitView);
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      document.getElementById('btnSimulate').addEventListener('click', () => {
        const statuses = ['success', 'failure', 'running'];
        for (const n of nodes) n.status = statuses[Math.floor(Math.random() * statuses.length)];
        const badge = document.getElementById('statusSim');
        badge.className = 'sim-badge running'; badge.textContent = 'RUNNING';
        render();
      });
      document.getElementById('btnReset').addEventListener('click', () => {
        for (const n of nodes) n.status = 'idle';
        const badge = document.getElementById('statusSim');
        badge.className = 'sim-badge idle'; badge.textContent = 'IDLE';
        render();
      });

      // \u2500\u2500 Shortcuts \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('Delete', () => document.getElementById('btnDelete').click());
      registerShortcut('f', () => fitView());
      registerShortcut('l', () => { pushUndo(); layoutTree(); render(); });

      // \u2500\u2500 Export \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function exportNode(node) {
        let lua = '{ type = "' + node.type + '"';
        for (const [k, v] of Object.entries(node.params)) {
          if (typeof v === 'string') lua += ', ' + k + ' = "' + v + '"';
          else lua += ', ' + k + ' = ' + v;
        }
        const children = getChildren(node.id);
        if (children.length) {
          lua += ', children = {\\n';
          for (const c of children) lua += '    ' + exportNode(c) + ',\\n';
          lua += '  }';
        }
        lua += ' }';
        return lua;
      }

      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D AI Behavior Tree Editor', '-- Usage: lurek.ai.behavior_tree(entity, tree)', ''];
        const roots = nodes.filter(n => !n.parentId);
        lines.push('return {');
        for (const r of roots) lines.push('  ' + exportNode(r) + ',');
        lines.push('}');
        return lines.join('\\n');
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export Lua File', action: () => vscode.postMessage({ type: 'exportLua', content: buildLuaCode() }) },
        { label: 'Copy Lua Code', action: () => vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() }) },
        { label: 'Insert to Editor', action: () => vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() }) },
      ]);

      document.getElementById('btnCopyLua').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() });
      });

      // \u2500\u2500 Init (default tree) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      nodes = [
        { id: 1, type: 'Selector', category: 'composite', x: 300, y: 40, parentId: null, status: 'idle', params: {} },
        { id: 2, type: 'Sequence', category: 'composite', x: 150, y: 120, parentId: 1, status: 'idle', params: {} },
        { id: 3, type: 'HasTarget', category: 'condition', x: 100, y: 200, parentId: 2, status: 'idle', params: {} },
        { id: 4, type: 'Attack', category: 'action', x: 220, y: 200, parentId: 2, status: 'idle', params: {} },
        { id: 5, type: 'Patrol', category: 'action', x: 400, y: 120, parentId: 1, status: 'idle', params: {} },
      ];
      nextId = 6;
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `)}};var Sn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.graph","Graph / Node Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"graph.lua");break}}getHtml(){let e=L();return I(e,"Graph / Node Editor",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 240px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: var(--bg); }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); overflow-y: auto; background: var(--surface); }

      .prop-field { margin-bottom: 6px; }
      .prop-field label { display: block; font-size: 10px; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.3px; margin-bottom: 2px; }

      .mode-badge {
        display: inline-flex; align-items: center; gap: 4px;
        padding: 1px 8px; border-radius: 9px; font-size: 10px; font-weight: 600;
      }
      .mode-badge.select { background: var(--surface-2); color: var(--text-dim); }
      .mode-badge.connect { background: #ff9800; color: var(--bg); }
    `,`
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            ${g("add",{id:"btnAddNode",title:"Add Node (A)"})}
            <input id="nodeType" value="Process" style="width:80px" title="Node type">
            ${g("link",{id:"btnConnect",title:"Connect Ports (C)"})}
            ${g("trash",{id:"btnDelete",title:"Delete (Del)",cls:"danger"})}
          </div>
          ${k()}
          <div class="group">
            ${g("undo",{id:"btnUndo",title:"Undo (Ctrl+Z)"})}
            ${g("redo",{id:"btnRedo",title:"Redo (Ctrl+Y)"})}
          </div>
          ${k()}
          <div class="group">
            ${g("fitView",{id:"btnFitView",title:"Fit View (F)"})}
          </div>
          ${A()}
          <div class="group">
            ${g("copy",{id:"btnCopyLua",title:"Copy Lua Code"})}
            ${g("insert",{id:"btnInsert",title:"Insert to Editor"})}
          </div>
          ${k()}
          <button id="btnExport" class="primary">${c.exportFile} Export \u25BE</button>
        </div>

        <!-- Canvas -->
        <div class="canvas-area"><canvas id="graphCanvas"></canvas></div>

        <!-- Properties -->
        <div class="props-panel">
          ${b("Node Properties",'<div id="propsContent"><p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:20px;">Select a node</p></div>')}
          ${b("Port Editor",'<div id="portEditor"><p style="color:var(--text-dim);font-size:11px">Ports are defined per-node</p></div>')}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusNodes" class="badge">0 nodes</span>
          </span>
          <div class="sep"></div>
          <span id="statusEdges">0 edges</span>
          <div class="sep"></div>
          <span id="statusMode" class="mode-badge select">SELECT</span>
          <div class="spacer"></div>
          <span id="statusZoom">100%</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${c.clean}</span>
        </div>
      </div>
    `,`
      const canvas = document.getElementById('graphCanvas');
      const ctx = canvas.getContext('2d');
      let nodes = [], edges = [];
      let selectedNode = null, dragNode = null, dragOff = { x: 0, y: 0 };
      let connectMode = false, connectFrom = null, connectPort = -1;
      let offsetX = 0, offsetY = 0, zoom = 1;
      let isPanning = false, panSX = 0, panSY = 0;
      let nextId = 1;
      const NODE_W = 150, NODE_H = 64, PORT_R = 6;
      const undo = new UndoStack(60);

      function snapshot() { return JSON.parse(JSON.stringify({ nodes, edges, nextId })); }
      function restoreSnap(s) { nodes = s.nodes; edges = s.edges; nextId = s.nextId; selectedNode = null; showProps(null); updateStatus(); render(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      const TYPE_COLORS = {
        Input: '#1a3a1a', Process: '#1a2a3a', Output: '#3a1a2a', Filter: '#3a3a1a', Merge: '#2a1a3a',
      };

      function addNode(type, x, y) {
        pushUndo();
        nodes.push({
          id: nextId++, type: type || 'Process',
          x: x ?? (150 + nodes.length * 40), y: y ?? (100 + nodes.length * 40),
          label: (type || 'Process') + ' ' + nextId,
          inPorts: ['in'], outPorts: ['out'], data: {}
        });
        updateStatus(); render();
      }

      function getPortPos(node, isOut, portIdx) {
        const portCount = isOut ? node.outPorts.length : node.inPorts.length;
        const spacing = NODE_H / (portCount + 1);
        return { x: isOut ? node.x + NODE_W : node.x, y: node.y + spacing * (portIdx + 1) };
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight; render();
      }

      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.save(); ctx.translate(offsetX, offsetY); ctx.scale(zoom, zoom);

        // Grid
        ctx.strokeStyle = 'rgba(255,255,255,0.03)'; ctx.lineWidth = 1;
        const gs = 40, sX = -offsetX / zoom, sY = -offsetY / zoom;
        const eX = sX + canvas.width / zoom, eY = sY + canvas.height / zoom;
        for (let x = Math.floor(sX / gs) * gs; x < eX; x += gs) { ctx.beginPath(); ctx.moveTo(x, sY); ctx.lineTo(x, eY); ctx.stroke(); }
        for (let y = Math.floor(sY / gs) * gs; y < eY; y += gs) { ctx.beginPath(); ctx.moveTo(sX, y); ctx.lineTo(eX, y); ctx.stroke(); }

        // Edges
        for (const e of edges) {
          const fromNode = nodes.find(n => n.id === e.fromNode);
          const toNode = nodes.find(n => n.id === e.toNode);
          if (!fromNode || !toNode) continue;
          const fp = getPortPos(fromNode, true, e.fromPort);
          const tp = getPortPos(toNode, false, e.toPort);
          const cx = (fp.x + tp.x) / 2;
          ctx.beginPath(); ctx.moveTo(fp.x, fp.y);
          ctx.bezierCurveTo(cx, fp.y, cx, tp.y, tp.x, tp.y);
          ctx.strokeStyle = 'rgba(255,255,255,0.2)'; ctx.lineWidth = 2; ctx.stroke();
        }

        // Nodes
        for (const n of nodes) {
          const sel = n === selectedNode;
          ctx.fillStyle = TYPE_COLORS[n.type] || '#2d2d2d';
          ctx.strokeStyle = sel ? 'var(--accent, #89b4fa)' : 'rgba(255,255,255,0.08)';
          ctx.lineWidth = sel ? 2.5 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.fill(); ctx.stroke();
          // Header bar
          ctx.fillStyle = 'rgba(255,255,255,0.06)';
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, 22, [6, 6, 0, 0]); ctx.fill();
          // Label
          ctx.fillStyle = '#ddd'; ctx.font = '600 11px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
          ctx.fillText(n.label.length > 18 ? n.label.substring(0, 17) + '\u2026' : n.label, n.x + NODE_W / 2, n.y + 11);
          // Type
          ctx.fillStyle = '#888'; ctx.font = '9px sans-serif';
          ctx.fillText(n.type, n.x + NODE_W / 2, n.y + 40);
          // In ports
          n.inPorts.forEach((p, i) => {
            const pos = getPortPos(n, false, i);
            ctx.fillStyle = '#4ec9b0'; ctx.beginPath(); ctx.arc(pos.x, pos.y, PORT_R, 0, Math.PI * 2); ctx.fill();
            ctx.strokeStyle = '#2a5a4a'; ctx.lineWidth = 1; ctx.stroke();
            ctx.fillStyle = '#999'; ctx.font = '9px sans-serif'; ctx.textAlign = 'left';
            ctx.fillText(p, pos.x + 10, pos.y + 3);
          });
          // Out ports
          n.outPorts.forEach((p, i) => {
            const pos = getPortPos(n, true, i);
            ctx.fillStyle = '#ff9800'; ctx.beginPath(); ctx.arc(pos.x, pos.y, PORT_R, 0, Math.PI * 2); ctx.fill();
            ctx.strokeStyle = '#5a3a1a'; ctx.lineWidth = 1; ctx.stroke();
            ctx.fillStyle = '#999'; ctx.font = '9px sans-serif'; ctx.textAlign = 'right';
            ctx.fillText(p, pos.x - 10, pos.y + 3);
          });
        }
        ctx.restore();
      }

      function hitNode(sx, sy) {
        const wx = (sx - offsetX) / zoom, wy = (sy - offsetY) / zoom;
        for (let i = nodes.length - 1; i >= 0; i--) {
          const n = nodes[i]; if (wx >= n.x && wx <= n.x + NODE_W && wy >= n.y && wy <= n.y + NODE_H) return n;
        }
        return null;
      }

      function hitPort(sx, sy) {
        const wx = (sx - offsetX) / zoom, wy = (sy - offsetY) / zoom;
        for (const n of nodes) {
          for (let i = 0; i < n.outPorts.length; i++) { const p = getPortPos(n, true, i); if (Math.hypot(wx - p.x, wy - p.y) < PORT_R * 2) return { node: n, isOut: true, port: i }; }
          for (let i = 0; i < n.inPorts.length; i++) { const p = getPortPos(n, false, i); if (Math.hypot(wx - p.x, wy - p.y) < PORT_R * 2) return { node: n, isOut: false, port: i }; }
        }
        return null;
      }

      function showProps(node) {
        const el = document.getElementById('propsContent');
        const pe = document.getElementById('portEditor');
        if (!node) { el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:20px;">Select a node</p>'; pe.innerHTML = ''; return; }
        el.innerHTML =
          '<div class="prop-field"><label>Label</label><input id="pLabel" value="' + node.label.replace(/"/g, '&quot;') + '" style="width:100%"></div>' +
          '<div class="prop-field"><label>Type</label><input id="pType" value="' + node.type + '" style="width:100%"></div>';
        document.getElementById('pLabel').addEventListener('input', (e) => { pushUndo(); node.label = e.target.value; render(); });
        document.getElementById('pType').addEventListener('input', (e) => { pushUndo(); node.type = e.target.value; render(); });

        pe.innerHTML =
          '<div class="prop-field"><label>In Ports (comma sep)</label><input id="pInPorts" value="' + node.inPorts.join(', ') + '" style="width:100%"></div>' +
          '<div class="prop-field"><label>Out Ports (comma sep)</label><input id="pOutPorts" value="' + node.outPorts.join(', ') + '" style="width:100%"></div>';
        document.getElementById('pInPorts').addEventListener('change', (e) => {
          pushUndo(); node.inPorts = e.target.value.split(',').map(s => s.trim()).filter(Boolean);
          edges = edges.filter(ed => !(ed.toNode === node.id && ed.toPort >= node.inPorts.length)); render();
        });
        document.getElementById('pOutPorts').addEventListener('change', (e) => {
          pushUndo(); node.outPorts = e.target.value.split(',').map(s => s.trim()).filter(Boolean);
          edges = edges.filter(ed => !(ed.fromNode === node.id && ed.fromPort >= node.outPorts.length)); render();
        });
      }

      function updateStatus() {
        document.getElementById('statusNodes').textContent = nodes.length + ' nodes';
        document.getElementById('statusEdges').textContent = edges.length + ' edges';
        document.getElementById('statusZoom').textContent = Math.round(zoom * 100) + '%';
      }

      function fitView() {
        if (nodes.length === 0) return;
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        for (const n of nodes) { minX = Math.min(minX, n.x); minY = Math.min(minY, n.y); maxX = Math.max(maxX, n.x + NODE_W); maxY = Math.max(maxY, n.y + NODE_H); }
        const pad = 40, w = maxX - minX + pad * 2, h = maxY - minY + pad * 2;
        zoom = Math.min(canvas.width / w, canvas.height / h, 2);
        offsetX = canvas.width / 2 - (minX + (maxX - minX) / 2) * zoom;
        offsetY = canvas.height / 2 - (minY + (maxY - minY) / 2) * zoom;
        render(); updateStatus();
      }

      // \u2500\u2500 Canvas events \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) { isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY; return; }
        if (connectMode) {
          const port = hitPort(e.offsetX, e.offsetY);
          if (port && port.isOut && !connectFrom) { connectFrom = port.node; connectPort = port.port; }
          else if (port && !port.isOut && connectFrom) {
            pushUndo(); edges.push({ fromNode: connectFrom.id, fromPort: connectPort, toNode: port.node.id, toPort: port.port });
            connectFrom = null; updateStatus(); render();
          } else { connectFrom = null; }
          return;
        }
        const node = hitNode(e.offsetX, e.offsetY);
        if (node) { selectedNode = node; showProps(node); dragNode = node; dragOff = { x: (e.offsetX - offsetX) / zoom - node.x, y: (e.offsetY - offsetY) / zoom - node.y }; }
        else { selectedNode = null; showProps(null); }
        render();
      });
      canvas.addEventListener('mousemove', (e) => {
        if (isPanning) { offsetX = e.clientX - panSX; offsetY = e.clientY - panSY; render(); return; }
        if (dragNode) { dragNode.x = (e.offsetX - offsetX) / zoom - dragOff.x; dragNode.y = (e.offsetY - offsetY) / zoom - dragOff.y; render(); }
      });
      canvas.addEventListener('mouseup', () => { isPanning = false; if (dragNode) pushUndo(); dragNode = null; });
      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const old = zoom; zoom *= e.deltaY < 0 ? 1.1 : 0.9; zoom = Math.max(0.2, Math.min(4, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / old; offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / old; render(); updateStatus();
      }, { passive: false });

      // \u2500\u2500 Buttons \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      document.getElementById('btnAddNode').addEventListener('click', () => addNode(document.getElementById('nodeType').value));
      document.getElementById('btnConnect').addEventListener('click', () => {
        connectMode = !connectMode; connectFrom = null;
        document.getElementById('btnConnect').classList.toggle('active', connectMode);
        const badge = document.getElementById('statusMode');
        badge.className = connectMode ? 'mode-badge connect' : 'mode-badge select';
        badge.textContent = connectMode ? 'CONNECT' : 'SELECT';
      });
      document.getElementById('btnDelete').addEventListener('click', () => {
        if (!selectedNode) return; pushUndo();
        edges = edges.filter(e => e.fromNode !== selectedNode.id && e.toNode !== selectedNode.id);
        nodes = nodes.filter(n => n !== selectedNode);
        selectedNode = null; showProps(null); updateStatus(); render();
      });
      document.getElementById('btnFitView').addEventListener('click', fitView);
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restoreSnap(s); });

      // \u2500\u2500 Shortcuts \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('a', () => document.getElementById('btnAddNode').click());
      registerShortcut('c', () => document.getElementById('btnConnect').click());
      registerShortcut('Delete', () => document.getElementById('btnDelete').click());
      registerShortcut('f', () => fitView());

      // \u2500\u2500 Export \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Graph / Node Editor', ''];
        lines.push('return {');
        lines.push('  nodes = {');
        for (const n of nodes) {
          lines.push('    { id = ' + n.id + ', type = "' + n.type + '", label = "' + n.label + '"' +
            ', inPorts = { "' + n.inPorts.join('", "') + '" }' +
            ', outPorts = { "' + n.outPorts.join('", "') + '" } },');
        }
        lines.push('  },');
        lines.push('  edges = {');
        for (const e of edges) {
          lines.push('    { from = ' + e.fromNode + ', fromPort = ' + (e.fromPort + 1) + ', to = ' + e.toNode + ', toPort = ' + (e.toPort + 1) + ' },');
        }
        lines.push('  },');
        lines.push('}');
        return lines.join('\\n');
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export Lua File', action: () => vscode.postMessage({ type: 'exportLua', content: buildLuaCode() }) },
        { label: 'Copy Lua Code', action: () => vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() }) },
        { label: 'Insert to Editor', action: () => vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() }) },
      ]);

      document.getElementById('btnCopyLua').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() });
      });

      // \u2500\u2500 Init \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      nodes = [
        { id: 1, type: 'Input', x: 80, y: 100, label: 'Input 1', inPorts: [], outPorts: ['data', 'signal'], data: {} },
        { id: 2, type: 'Process', x: 300, y: 80, label: 'Process 2', inPorts: ['data'], outPorts: ['result'], data: {} },
        { id: 3, type: 'Output', x: 520, y: 100, label: 'Output 3', inPorts: ['result'], outPorts: [], data: {} },
      ];
      nextId = 4;
      edges = [{ fromNode: 1, fromPort: 0, toNode: 2, toPort: 0 }, { fromNode: 2, fromPort: 0, toNode: 3, toPort: 0 }];
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `)}};var Cn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.tilemapScript","Tilemap Script Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"tilemap_script.lua");break}}getHtml(){let e=L();return I(e,"Tilemap Script Editor",`
      .editor-layout {
        display: grid; grid-template-columns: 180px 1fr 280px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .blocks-panel { grid-row: 2; background: var(--surface); border-right: 1px solid var(--border); overflow-y: auto; }
      .script-area { grid-row: 2; padding: 8px; overflow-y: auto; border-right: 1px solid var(--border); background: var(--bg); }
      .preview-panel { grid-row: 2; display: flex; flex-direction: column; background: var(--surface); }

      .block-btn {
        width: calc(100% - 8px); margin: 1px 4px; text-align: left; font-size: 11px;
        padding: 5px 8px; border-radius: var(--radius); cursor: pointer;
        border: 1px solid transparent; transition: border-color 0.1s, background 0.08s;
        display: flex; align-items: center; gap: 6px;
      }
      .block-btn:hover { border-color: var(--accent); background: var(--hover); }
      .block-btn .block-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }

      .script-step {
        background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius);
        padding: 8px; margin-bottom: 6px;
      }
      .script-step h4 {
        font-size: 11px; margin-bottom: 6px; display: flex; justify-content: space-between; align-items: center;
      }
      .script-step .step-num { color: var(--accent); font-weight: 700; font-size: 10px; }
      .step-controls button { padding: 1px 5px; font-size: 10px; }
      .preview-canvas { flex: 1; display: flex; align-items: center; justify-content: center; background: #111; }
    `,`
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            <label style="font-size:11px">W:</label><input type="number" id="mapW" value="40" min="5" max="100" style="width:44px">
            <label style="font-size:11px">H:</label><input type="number" id="mapH" value="30" min="5" max="100" style="width:44px">
            <label style="font-size:11px">Seed:</label><input type="number" id="seed" value="1234" style="width:56px">
          </div>
          ${k()}
          <div class="group">
            <button id="btnRun">${c.play} Run Script</button>
          </div>
          ${k()}
          <div class="group">
            ${g("undo",{id:"btnUndo",title:"Undo (Ctrl+Z)"})}
            ${g("redo",{id:"btnRedo",title:"Redo (Ctrl+Y)"})}
          </div>
          ${A()}
          <div class="group">
            ${g("copy",{id:"btnCopyLua",title:"Copy Lua Code"})}
            ${g("insert",{id:"btnInsert",title:"Insert to Editor"})}
          </div>
          ${k()}
          <button id="btnExport" class="primary">${c.exportFile} Export \u25BE</button>
        </div>

        <!-- Blocks Palette -->
        <div class="blocks-panel">
          ${b("Script Blocks",`
            <button class="block-btn" data-block="fill"><span class="block-dot" style="background:#585b70"></span>Fill All</button>
            <button class="block-btn" data-block="noise"><span class="block-dot" style="background:#89b4fa"></span>Random Noise</button>
            <button class="block-btn" data-block="rooms"><span class="block-dot" style="background:#a6e3a1"></span>Place Rooms</button>
            <button class="block-btn" data-block="corridors"><span class="block-dot" style="background:#f9e2af"></span>Connect Corridors</button>
            <button class="block-btn" data-block="border"><span class="block-dot" style="background:#f38ba8"></span>Add Border</button>
            <button class="block-btn" data-block="scatter"><span class="block-dot" style="background:#cba6f7"></span>Scatter Objects</button>
            <button class="block-btn" data-block="cellular"><span class="block-dot" style="background:#fab387"></span>Cellular Automata</button>
            <button class="block-btn" data-block="clear_center"><span class="block-dot" style="background:#94e2d5"></span>Clear Center</button>
          `)}
        </div>

        <!-- Script Steps -->
        <div class="script-area">
          <div style="font-size:11px;color:var(--text-dim);margin-bottom:8px;">Click blocks to add steps. Use arrows to reorder.</div>
          <div id="stepList"></div>
        </div>

        <!-- Preview -->
        <div class="preview-panel">
          <div style="padding:6px 8px;background:var(--surface);border-bottom:1px solid var(--border);font-size:11px;font-weight:600;color:var(--text-dim);text-transform:uppercase;letter-spacing:0.5px">Preview</div>
          <div class="preview-canvas"><canvas id="previewCanvas"></canvas></div>
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusSteps" class="badge">0 steps</span>
          </span>
          <div class="sep"></div>
          <span id="statusSize">40 \xD7 30</span>
          <div class="sep"></div>
          <span id="statusSeed">Seed: 1234</span>
          <div class="spacer"></div>
          <span class="dirty-indicator">${c.clean}</span>
        </div>
      </div>
    `,`
      let mapW = 40, mapH = 30, seed = 1234;
      let mapData = [];
      let steps = [];
      const undo = new UndoStack(40);

      function snapshot() { return JSON.parse(JSON.stringify(steps)); }
      function restoreSnap(s) { steps = s; refreshSteps(); runScript(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      const BLOCK_DEFAULTS = {
        fill: { label: 'Fill All', params: { tile: 1 } },
        noise: { label: 'Random Noise', params: { density: 0.4, tile: 0 } },
        rooms: { label: 'Place Rooms', params: { count: 5, minSize: 3, maxSize: 8 } },
        corridors: { label: 'Connect Corridors', params: {} },
        border: { label: 'Add Border', params: { tile: 1, thickness: 1 } },
        scatter: { label: 'Scatter Objects', params: { tile: 2, density: 0.05 } },
        cellular: { label: 'Cellular Automata', params: { iterations: 4, birthLimit: 4, deathLimit: 3 } },
        clear_center: { label: 'Clear Center', params: { radius: 5 } },
      };

      const TILE_COLORS = ['#1a1a2e', '#4a4a4a', '#3a5a3a', '#5a3a3a', '#3a3a5a'];

      function mulberry32(a) {
        return function() {
          a |= 0; a = a + 0x6D2B79F5 | 0;
          var t = Math.imul(a ^ a >>> 15, 1 | a);
          t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
          return ((t ^ t >>> 14) >>> 0) / 4294967296;
        };
      }

      function addStep(type) {
        pushUndo();
        const def = BLOCK_DEFAULTS[type];
        steps.push({ type, label: def.label, params: { ...def.params } });
        refreshSteps();
      }

      function refreshSteps() {
        const el = document.getElementById('stepList');
        el.innerHTML = '';
        steps.forEach((step, i) => {
          const div = document.createElement('div');
          div.className = 'script-step';
          let paramsHtml = '';
          for (const [k, v] of Object.entries(step.params)) {
            paramsHtml += '<div style="display:flex;align-items:center;gap:4px;margin-bottom:3px"><label style="width:65px;font-size:10px;color:var(--text-dim);text-transform:uppercase">' + k + '</label>';
            paramsHtml += '<input type="number" data-si="' + i + '" data-pk="' + k + '" value="' + v + '" style="width:60px" step="' + (typeof v === 'number' && v < 1 ? 0.05 : 1) + '"></div>';
          }
          div.innerHTML = '<h4><span><span class="step-num">#' + (i + 1) + '</span> ' + step.label + '</span>' +
            '<span class="step-controls"><button data-up="' + i + '" title="Move Up">\u25B2</button><button data-down="' + i + '" title="Move Down">\u25BC</button><button data-del="' + i + '" title="Remove">\u2715</button></span></h4>' + paramsHtml;
          el.appendChild(div);

          div.querySelectorAll('input[data-si]').forEach(inp => {
            inp.addEventListener('input', (e) => {
              steps[parseInt(e.target.dataset.si)].params[e.target.dataset.pk] = parseFloat(e.target.value) || 0;
            });
          });
          const up = div.querySelector('[data-up]');
          if (up) up.addEventListener('click', () => { if (i > 0) { pushUndo(); [steps[i-1], steps[i]] = [steps[i], steps[i-1]]; refreshSteps(); } });
          const down = div.querySelector('[data-down]');
          if (down) down.addEventListener('click', () => { if (i < steps.length-1) { pushUndo(); [steps[i], steps[i+1]] = [steps[i+1], steps[i]]; refreshSteps(); } });
          div.querySelector('[data-del]').addEventListener('click', () => { pushUndo(); steps.splice(i, 1); refreshSteps(); });
        });
        updateStatus();
      }

      function runScript() {
        mapW = parseInt(document.getElementById('mapW').value) || 40;
        mapH = parseInt(document.getElementById('mapH').value) || 30;
        seed = parseInt(document.getElementById('seed').value) || 0;
        const rng = mulberry32(seed);
        mapData = new Array(mapW * mapH).fill(0);

        const get = (x, y) => (x >= 0 && x < mapW && y >= 0 && y < mapH) ? mapData[y * mapW + x] : 1;
        const set = (x, y, v) => { if (x >= 0 && x < mapW && y >= 0 && y < mapH) mapData[y * mapW + x] = v; };

        const rooms = [];
        for (const step of steps) {
          const p = step.params;
          switch (step.type) {
            case 'fill': mapData.fill(p.tile); break;
            case 'noise':
              for (let i = 0; i < mapData.length; i++) { if (rng() < p.density) mapData[i] = p.tile; } break;
            case 'rooms':
              for (let r = 0; r < (p.count || 5); r++) {
                const rw = Math.floor(rng() * ((p.maxSize||8) - (p.minSize||3))) + (p.minSize||3);
                const rh = Math.floor(rng() * ((p.maxSize||8) - (p.minSize||3))) + (p.minSize||3);
                const rx = Math.floor(rng() * (mapW - rw - 2)) + 1;
                const ry = Math.floor(rng() * (mapH - rh - 2)) + 1;
                for (let y = ry; y < ry + rh; y++) for (let x = rx; x < rx + rw; x++) set(x, y, 0);
                rooms.push({ cx: rx + Math.floor(rw/2), cy: ry + Math.floor(rh/2) });
              } break;
            case 'corridors':
              for (let i = 0; i < rooms.length - 1; i++) {
                const a = rooms[i], b = rooms[i+1];
                let cx = a.cx; while (cx !== b.cx) { set(cx, a.cy, 0); cx += cx < b.cx ? 1 : -1; }
                let cy = a.cy; while (cy !== b.cy) { set(b.cx, cy, 0); cy += cy < b.cy ? 1 : -1; }
              } break;
            case 'border':
              for (let x = 0; x < mapW; x++) for (let t = 0; t < (p.thickness || 1); t++) { set(x, t, p.tile); set(x, mapH - 1 - t, p.tile); }
              for (let y = 0; y < mapH; y++) for (let t = 0; t < (p.thickness || 1); t++) { set(t, y, p.tile); set(mapW - 1 - t, y, p.tile); }
              break;
            case 'scatter':
              for (let i = 0; i < mapData.length; i++) { if (mapData[i] === 0 && rng() < (p.density || 0.05)) mapData[i] = p.tile; } break;
            case 'cellular':
              for (let iter = 0; iter < (p.iterations || 4); iter++) {
                const next = [...mapData];
                for (let y = 0; y < mapH; y++) for (let x = 0; x < mapW; x++) {
                  let walls = 0;
                  for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
                    if (dx === 0 && dy === 0) continue; if (get(x+dx, y+dy) === 1) walls++;
                  }
                  if (mapData[y*mapW+x] === 1) next[y*mapW+x] = walls >= (p.deathLimit||3) ? 1 : 0;
                  else next[y*mapW+x] = walls >= (p.birthLimit||4) ? 1 : 0;
                }
                mapData = next;
              } break;
            case 'clear_center': {
              const cx = Math.floor(mapW/2), cy = Math.floor(mapH/2), r = p.radius || 5;
              for (let y = cy - r; y <= cy + r; y++) for (let x = cx - r; x <= cx + r; x++) {
                if (Math.hypot(x - cx, y - cy) <= r) set(x, y, 0);
              } break;
            }
          }
        }
        renderPreview();
        updateStatus();
      }

      function renderPreview() {
        const canvas = document.getElementById('previewCanvas');
        const parent = canvas.parentElement;
        const cs = Math.min(Math.floor(parent.clientWidth / mapW), Math.floor(parent.clientHeight / mapH), 12);
        canvas.width = mapW * cs; canvas.height = mapH * cs;
        const ctx = canvas.getContext('2d');
        for (let y = 0; y < mapH; y++) for (let x = 0; x < mapW; x++) {
          ctx.fillStyle = TILE_COLORS[mapData[y * mapW + x]] || '#000';
          ctx.fillRect(x * cs, y * cs, cs, cs);
        }
      }

      function updateStatus() {
        document.getElementById('statusSteps').textContent = steps.length + ' steps';
        document.getElementById('statusSize').textContent = mapW + ' \xD7 ' + mapH;
        document.getElementById('statusSeed').textContent = 'Seed: ' + seed;
      }

      // \u2500\u2500 Palette clicks \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      document.querySelectorAll('.block-btn').forEach(btn => {
        btn.addEventListener('click', () => addStep(btn.dataset.block));
      });

      // \u2500\u2500 Buttons \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      document.getElementById('btnRun').addEventListener('click', runScript);
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restoreSnap(s); });

      // \u2500\u2500 Shortcuts \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+Enter', () => runScript());

      // \u2500\u2500 Export \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Tilemap Script Editor', ''];
        lines.push('return {');
        lines.push('  width = ' + mapW + ',');
        lines.push('  height = ' + mapH + ',');
        lines.push('  seed = ' + seed + ',');
        lines.push('  steps = {');
        for (const s of steps) {
          let params = '';
          for (const [k, v] of Object.entries(s.params)) params += ', ' + k + ' = ' + v;
          lines.push('    { type = "' + s.type + '"' + params + ' },');
        }
        lines.push('  },');
        lines.push('}');
        return lines.join('\\n');
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export Lua File', action: () => vscode.postMessage({ type: 'exportLua', content: buildLuaCode() }) },
        { label: 'Copy Lua Code', action: () => vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() }) },
        { label: 'Insert to Editor', action: () => vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() }) },
      ]);

      document.getElementById('btnCopyLua').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() });
      });

      // \u2500\u2500 Init \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      addStep('fill'); addStep('noise'); addStep('cellular'); addStep('border');
      refreshSteps(); runScript();
    `)}};var jn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.voxel","Voxel Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"voxel_model.lua");break}}getHtml(){let e=L();return I(e,"Voxel Editor",`
      .editor-layout {
        display: grid; grid-template-columns: 44px 1fr 1fr 200px;
        grid-template-rows: auto 1fr 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .tool-rail {
        grid-row: 2 / 4; background: var(--surface); border-right: 1px solid var(--border);
        display: flex; flex-direction: column; align-items: center; padding: 4px 2px; gap: 2px;
      }
      .tool-rail button {
        width: 36px; height: 36px; padding: 0; border-radius: var(--radius);
        display: flex; align-items: center; justify-content: center;
        border: 1px solid transparent; background: transparent; color: var(--text); cursor: pointer;
      }
      .tool-rail button:hover { background: var(--hover); }
      .tool-rail button.active { background: var(--accent); color: var(--bg); border-color: var(--accent); }
      .top-view { grid-row: 2; grid-column: 2; position: relative; overflow: hidden; border-bottom: 1px solid var(--border); border-right: 1px solid var(--border); background: #111; }
      .side-view { grid-row: 3; grid-column: 2; position: relative; overflow: hidden; border-right: 1px solid var(--border); background: #111; }
      .iso-view { grid-row: 2 / 4; grid-column: 3; position: relative; overflow: hidden; background: #111; }
      .right-panel { grid-row: 2 / 4; border-left: 1px solid var(--border); overflow-y: auto; background: var(--surface); }
      .view-label {
        position: absolute; top: 4px; left: 8px; font-size: 10px; color: var(--text-dim);
        background: var(--surface); padding: 1px 6px; border-radius: 9px; z-index: 1;
        text-transform: uppercase; letter-spacing: 0.3px; font-weight: 600;
      }
      .color-well {
        width: 100%; height: 28px; border: 1px solid var(--border); border-radius: var(--radius);
        cursor: pointer; margin-bottom: 6px;
      }
      .palette-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 2px; }
      .palette-grid div {
        aspect-ratio: 1; border-radius: 3px; cursor: pointer;
        border: 1px solid rgba(255,255,255,0.08); transition: border-color 0.1s;
      }
      .palette-grid div:hover { border-color: var(--accent); }
      .layer-btn {
        width: 100%; margin-bottom: 1px; font-size: 10px; text-align: left; padding: 3px 6px;
        border-radius: var(--radius); cursor: pointer; border: 1px solid transparent;
        background: transparent; color: var(--text);
      }
      .layer-btn:hover { background: var(--hover); }
      .layer-btn.sel { background: var(--accent); color: var(--bg); font-weight: 600; }
    `,`
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            <label style="font-size:11px">Grid:</label>
            <select id="gridSize"><option value="8">8\xB3</option><option value="16" selected>16\xB3</option><option value="32">32\xB3</option></select>
            <label style="font-size:11px">Z:</label>
            <input type="number" id="layerZ" value="0" min="0" max="15" style="width:38px">
          </div>
          ${k()}
          <div class="group">
            ${g("undo",{id:"btnUndo",title:"Undo (Ctrl+Z)"})}
            ${g("redo",{id:"btnRedo",title:"Redo (Ctrl+Y)"})}
          </div>
          ${k()}
          <div class="group">
            ${g("trash",{id:"btnClear",title:"Clear All",cls:"danger"})}
          </div>
          ${A()}
          <div class="group">
            ${g("copy",{id:"btnCopyLua",title:"Copy Lua Code"})}
            ${g("insert",{id:"btnInsert",title:"Insert to Editor"})}
          </div>
          ${k()}
          <button id="btnExport" class="primary">${c.exportFile} Export \u25BE</button>
        </div>

        <!-- Tool Rail -->
        <div class="tool-rail" id="tools">
          <button class="active" data-tool="pen" title="Pen (P)">${c.pencil}</button>
          <button data-tool="erase" title="Eraser (E)">${c.eraser}</button>
          <button data-tool="fill" title="Fill Layer (F)">${c.bucket}</button>
        </div>

        <!-- Views -->
        <div class="top-view"><span class="view-label">Top XY \u2014 Layer Z</span><canvas id="topCanvas"></canvas></div>
        <div class="side-view"><span class="view-label">Side XZ</span><canvas id="sideCanvas"></canvas></div>
        <div class="iso-view"><span class="view-label">3D Isometric</span><canvas id="isoCanvas"></canvas></div>

        <!-- Right Panel -->
        <div class="right-panel">
          ${b("Color",`
            <input type="color" id="voxelColor" value="#4ec9b0" class="color-well">
            <div id="palette" class="palette-grid"></div>
          `)}
          ${b("Layers (Z)",'<div id="layerList"></div>')}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span id="statusPos">0, 0, 0</span>
          <div class="sep"></div>
          <span id="statusVoxels" class="badge">0 voxels</span>
          <div class="sep"></div>
          <span id="statusTool">Pen</span>
          <div class="spacer"></div>
          <span class="dirty-indicator">${c.clean}</span>
        </div>
      </div>
    `,`
      const PALETTE = ['#4ec9b0','#007acc','#f44336','#ff9800','#4caf50','#9c27b0','#ffeb3b','#795548','#ffffff','#888888','#444444','#000000','#ff77a8','#29adff','#00e436','#ab5236'];
      let gridSize = 16, currentZ = 0, currentColor = '#4ec9b0', currentTool = 'pen';
      let voxels = {};
      const undo = new UndoStack(40);

      function snapshot() { return JSON.parse(JSON.stringify(voxels)); }
      function restoreSnap(s) { voxels = s; refreshLayers(); renderAll(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      function vKey(x, y, z) { return x + ',' + y + ',' + z; }
      function setVoxel(x, y, z, color) { if (color) voxels[vKey(x,y,z)] = color; else delete voxels[vKey(x,y,z)]; }
      function getVoxel(x, y, z) { return voxels[vKey(x,y,z)] || null; }
      function countVoxels() { return Object.keys(voxels).length; }

      const topCanvas = document.getElementById('topCanvas');
      const topCtx = topCanvas.getContext('2d');
      function renderTop() {
        const area = topCanvas.parentElement;
        topCanvas.width = area.clientWidth; topCanvas.height = area.clientHeight;
        const cs = Math.min(Math.floor(topCanvas.width / gridSize), Math.floor(topCanvas.height / gridSize));
        topCtx.clearRect(0, 0, topCanvas.width, topCanvas.height);
        for (let y = 0; y < gridSize; y++) for (let x = 0; x < gridSize; x++) {
          const c = getVoxel(x, y, currentZ);
          topCtx.fillStyle = c || ((x + y) % 2 === 0 ? '#1a1a1a' : '#222');
          topCtx.fillRect(x * cs, y * cs, cs, cs);
          topCtx.strokeStyle = '#333'; topCtx.lineWidth = 0.5;
          topCtx.strokeRect(x * cs, y * cs, cs, cs);
        }
      }

      const sideCanvas = document.getElementById('sideCanvas');
      const sideCtx = sideCanvas.getContext('2d');
      function renderSide() {
        const area = sideCanvas.parentElement;
        sideCanvas.width = area.clientWidth; sideCanvas.height = area.clientHeight;
        const cs = Math.min(Math.floor(sideCanvas.width / gridSize), Math.floor(sideCanvas.height / gridSize));
        sideCtx.clearRect(0, 0, sideCanvas.width, sideCanvas.height);
        const midY = Math.floor(gridSize / 2);
        for (let z = 0; z < gridSize; z++) for (let x = 0; x < gridSize; x++) {
          const c = getVoxel(x, midY, z);
          sideCtx.fillStyle = c || ((x + z) % 2 === 0 ? '#1a1a1a' : '#222');
          sideCtx.fillRect(x * cs, (gridSize - 1 - z) * cs, cs, cs);
          sideCtx.strokeStyle = '#333'; sideCtx.lineWidth = 0.5;
          sideCtx.strokeRect(x * cs, (gridSize - 1 - z) * cs, cs, cs);
        }
        sideCtx.strokeStyle = 'var(--accent, #89b4fa)'; sideCtx.lineWidth = 2;
        sideCtx.strokeRect(0, (gridSize - 1 - currentZ) * cs, gridSize * cs, cs);
      }

      const isoCanvas = document.getElementById('isoCanvas');
      const isoCtx = isoCanvas.getContext('2d');
      function renderIso() {
        const area = isoCanvas.parentElement;
        isoCanvas.width = area.clientWidth; isoCanvas.height = area.clientHeight;
        isoCtx.clearRect(0, 0, isoCanvas.width, isoCanvas.height);
        const cs = Math.min(Math.floor(isoCanvas.width / (gridSize * 2.5)), Math.floor(isoCanvas.height / (gridSize * 2)), 8);
        const ox = isoCanvas.width / 2, oy = 40;
        function isoProject(x, y, z) {
          return { px: ox + (x - y) * cs, py: oy + (x + y) * cs * 0.5 - z * cs };
        }
        for (let z = 0; z < gridSize; z++) for (let y = 0; y < gridSize; y++) for (let x = 0; x < gridSize; x++) {
          const c = getVoxel(x, y, z);
          if (!c) continue;
          const { px, py } = isoProject(x, y, z);
          isoCtx.fillStyle = c;
          isoCtx.beginPath(); isoCtx.moveTo(px, py - cs * 0.5); isoCtx.lineTo(px + cs, py); isoCtx.lineTo(px, py + cs * 0.5); isoCtx.lineTo(px - cs, py); isoCtx.closePath(); isoCtx.fill();
          isoCtx.fillStyle = darken(c, 0.7);
          isoCtx.beginPath(); isoCtx.moveTo(px - cs, py); isoCtx.lineTo(px, py + cs * 0.5); isoCtx.lineTo(px, py + cs * 0.5 + cs); isoCtx.lineTo(px - cs, py + cs); isoCtx.closePath(); isoCtx.fill();
          isoCtx.fillStyle = darken(c, 0.85);
          isoCtx.beginPath(); isoCtx.moveTo(px + cs, py); isoCtx.lineTo(px, py + cs * 0.5); isoCtx.lineTo(px, py + cs * 0.5 + cs); isoCtx.lineTo(px + cs, py + cs); isoCtx.closePath(); isoCtx.fill();
        }
      }

      function darken(hex, factor) {
        const r = Math.round(parseInt(hex.slice(1,3), 16) * factor);
        const g = Math.round(parseInt(hex.slice(3,5), 16) * factor);
        const b = Math.round(parseInt(hex.slice(5,7), 16) * factor);
        return '#' + [r,g,b].map(v => v.toString(16).padStart(2,'0')).join('');
      }

      function renderAll() { renderTop(); renderSide(); renderIso(); updateStatus(); }

      function updateStatus() {
        document.getElementById('statusVoxels').textContent = countVoxels() + ' voxels';
        document.getElementById('statusTool').textContent = currentTool.charAt(0).toUpperCase() + currentTool.slice(1);
      }

      let isDrawing = false;
      topCanvas.addEventListener('mousedown', (e) => { isDrawing = true; pushUndo(); handleTopClick(e); });
      topCanvas.addEventListener('mousemove', (e) => {
        if (isDrawing) handleTopClick(e);
        const cs = Math.min(Math.floor(topCanvas.width / gridSize), Math.floor(topCanvas.height / gridSize));
        const x = Math.floor(e.offsetX / cs), y = Math.floor(e.offsetY / cs);
        document.getElementById('statusPos').textContent = x + ', ' + y + ', ' + currentZ;
      });
      topCanvas.addEventListener('mouseup', () => { isDrawing = false; });

      function handleTopClick(e) {
        const cs = Math.min(Math.floor(topCanvas.width / gridSize), Math.floor(topCanvas.height / gridSize));
        const x = Math.floor(e.offsetX / cs), y = Math.floor(e.offsetY / cs);
        if (x < 0 || x >= gridSize || y < 0 || y >= gridSize) return;
        if (currentTool === 'pen') setVoxel(x, y, currentZ, currentColor);
        else if (currentTool === 'erase') setVoxel(x, y, currentZ, null);
        else if (currentTool === 'fill') {
          for (let fy = 0; fy < gridSize; fy++) for (let fx = 0; fx < gridSize; fx++) setVoxel(fx, fy, currentZ, currentColor);
        }
        renderAll();
      }

      document.getElementById('tools').addEventListener('click', (e) => {
        const btn = e.target.closest('[data-tool]');
        if (!btn) return;
        document.getElementById('tools').querySelectorAll('button').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentTool = btn.dataset.tool;
        updateStatus();
      });

      document.getElementById('layerZ').addEventListener('input', (e) => {
        currentZ = Math.max(0, Math.min(gridSize - 1, parseInt(e.target.value) || 0));
        refreshLayers(); renderAll();
      });

      document.getElementById('gridSize').addEventListener('change', (e) => {
        pushUndo(); gridSize = parseInt(e.target.value);
        voxels = {}; currentZ = 0;
        document.getElementById('layerZ').max = String(gridSize - 1);
        document.getElementById('layerZ').value = '0';
        refreshLayers(); renderAll();
      });

      const paletteEl = document.getElementById('palette');
      PALETTE.forEach(c => {
        const div = document.createElement('div');
        div.style.background = c;
        div.addEventListener('click', () => { currentColor = c; document.getElementById('voxelColor').value = c; });
        paletteEl.appendChild(div);
      });
      document.getElementById('voxelColor').addEventListener('input', (e) => { currentColor = e.target.value; });

      function refreshLayers() {
        const el = document.getElementById('layerList');
        el.innerHTML = '';
        for (let z = gridSize - 1; z >= 0; z--) {
          const btn = document.createElement('button');
          btn.className = 'layer-btn' + (z === currentZ ? ' sel' : '');
          let count = 0;
          for (let y = 0; y < gridSize; y++) for (let x = 0; x < gridSize; x++) if (getVoxel(x, y, z)) count++;
          btn.textContent = 'Z=' + z + (count > 0 ? ' (' + count + ')' : '');
          btn.addEventListener('click', () => {
            currentZ = z; document.getElementById('layerZ').value = String(z);
            refreshLayers(); renderAll();
          });
          el.appendChild(btn);
        }
      }

      // \u2500\u2500 Buttons \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      document.getElementById('btnClear').addEventListener('click', () => { pushUndo(); voxels = {}; renderAll(); refreshLayers(); });
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restoreSnap(s); });

      // \u2500\u2500 Shortcuts \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('p', () => { document.querySelector('[data-tool="pen"]').click(); });
      registerShortcut('e', () => { document.querySelector('[data-tool="erase"]').click(); });
      registerShortcut('f', () => { document.querySelector('[data-tool="fill"]').click(); });

      // \u2500\u2500 Export \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Voxel Editor', ''];
        lines.push('return {');
        lines.push('  size = ' + gridSize + ',');
        lines.push('  voxels = {');
        for (const [key, color] of Object.entries(voxels)) {
          const [x, y, z] = key.split(',');
          lines.push('    { x = ' + x + ', y = ' + y + ', z = ' + z + ', color = "' + color + '" },');
        }
        lines.push('  }');
        lines.push('}');
        return lines.join('\\n');
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export Lua File', action: () => vscode.postMessage({ type: 'exportLua', content: buildLuaCode() }) },
        { label: 'Copy Lua Code', action: () => vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() }) },
        { label: 'Insert to Editor', action: () => vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() }) },
      ]);

      document.getElementById('btnCopyLua').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() });
      });

      // \u2500\u2500 Init \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
      refreshLayers();
      window.addEventListener('resize', renderAll);
      renderAll();
    `)}};var ft=C(require("vscode")),Nr=C(require("path")),bt=C(require("fs"));gt();var Kl=["ai","audio","cardgame","combat","compute","config","crafting","data","dataframe","dialog","engine","ecs","event","filesystem","graph","render","graphics_ext","image","input","inventory","math","math_ext","minimap","mods","particle","pathfind","physics","postfx","quest","resource","save","scene","sound","stats","thread","tilemap","timer"],Rn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.testRunner","Test Runner"),setTimeout(()=>this.pushDiscoveredSuites(),300)}handleMessage(e){switch(e.type){case"discoverSuites":this.pushDiscoveredSuites();break;case"runAll":this.runParallelTestCommand($t(),"all");break;case"runSuite":this.runSuite(e.suite);break;case"runLua":this.runParallelTestCommand(xt(),"lua");break;case"runGolden":this.runParallelTestCommand(mt("golden_tests"),"golden");break;case"stop":ft.window.showInformationMessage("Use the terminal to cancel the running test.");break}}pushDiscoveredSuites(){let e=this.discoverTestSuites();this.panel.webview.postMessage({type:"suites",suites:e})}discoverTestSuites(){let e=ft.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!e)return this.fallbackSuites();let t=Nr.join(e,"tests");if(!bt.existsSync(t))return this.fallbackSuites();let r=[],a=new Set(["golden_tests","lua_tests"]),i;try{i=bt.readdirSync(t)}catch{return this.fallbackSuites()}for(let s of i.sort()){if(!s.endsWith("_tests.rs"))continue;let o=s.replace(/\.rs$/,"");if(a.has(o))continue;let l=this.extractTestNames(Nr.join(t,s));r.push({name:o,tests:l})}return r.push({name:"lua_tests",tests:["(lua vm tests \u2014 run via parallel_cargo.py test lua)"]}),r.push({name:"golden_tests",tests:["(golden output tests \u2014 run via parallel_cargo.py test target golden_tests)"]}),r}extractTestNames(e){try{let t=bt.readFileSync(e,"utf8"),r=[],a=/^\s*(?:#\[test\]\s*(?:#\[.*?\]\s*)*)?(?:async\s+)?fn\s+(\w+)/gm,i,s=t.split(`
`);for(let o=0;o<s.length;o++)if(s[o].trimStart().startsWith("#[test]"))for(let l=o+1;l<Math.min(o+5,s.length);l++){let p=s[l].match(/\bfn\s+(\w+)/);if(p){r.push(p[1]);break}}return r.length?r:["(no #[test] functions found)"]}catch{return["(could not read file)"]}}fallbackSuites(){return Kl.map(e=>({name:`${e}_tests`,tests:[`(run: python tools/dev/parallel_cargo.py test target ${e}_tests)`]}))}runSuite(e){let t=e==="lua_tests"?xt():mt(e);this.runParallelTestCommand(t,e)}runParallelTestCommand(e,t){let a=ft.window.terminals.find(i=>i.name==="Lurek2D Tests")??ft.window.createTerminal("Lurek2D Tests");a.show(),a.sendText(e),this.panel.webview.postMessage({type:"testStarted",filter:t,command:e})}getHtml(){let e=L();return I(e,"Test Runner",`
      .editor-layout {
        display: grid; grid-template-columns: 260px 1fr;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .tree-panel { grid-row: 2; overflow-y: auto; border-right: 1px solid var(--border); background: var(--surface); }
      .output-panel { grid-row: 2; padding: 8px; overflow-y: auto; font-family: 'Cascadia Code', 'Consolas', monospace; font-size: 12px; white-space: pre-wrap; background: var(--bg); color: #ccc; }

      .suite-row {
        display: flex; align-items: center; justify-content: space-between;
        font-weight: 600; font-size: 11px; padding: 5px 8px;
        border-bottom: 1px solid var(--border); color: var(--text-dim); cursor: pointer;
      }
      .suite-row:hover { background: var(--hover); }
      .suite-row.sel { background: var(--selection); }
      .suite-run-btn {
        font-size: 10px; padding: 1px 6px; border-radius: 9px; cursor: pointer;
        background: var(--surface-2); color: var(--text); border: 1px solid var(--border);
      }
      .suite-run-btn:hover { background: var(--accent); color: var(--bg); }

      .test-item {
        display: flex; align-items: center; gap: 6px; padding: 3px 8px 3px 24px;
        cursor: pointer; font-size: 11px; border-radius: var(--radius);
      }
      .test-item:hover { background: var(--hover); }
      .dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
      .dot.pass { background: #4caf50; } .dot.fail { background: #f44336; }
      .dot.pending { background: #585b70; } .dot.running { background: #ff9800; animation: pulse 1s infinite; }
      @keyframes pulse { 0%,100% { opacity:1; } 50% { opacity:0.3; } }

      .result-badge {
        font-size: 9px; padding: 1px 5px; border-radius: 9px; margin-left: 4px; font-weight: 600;
      }
      .result-badge.pass { background: rgba(76,175,80,0.15); color: #4caf50; }
      .result-badge.fail { background: rgba(244,67,54,0.15); color: #f44336; }
      #discovering { padding: 12px; font-size: 11px; color: var(--text-dim); }
    `,`
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            <button id="btnRunAll">${c.play} Run All</button>
            <button id="btnRunLua">Run Lua</button>
            <button id="btnRunGolden">Run Golden</button>
            <button id="btnRunSelected">Run Selected</button>
          </div>
          ${k()}
          <div class="group">
            <input id="filter" placeholder="Filter tests\u2026" style="width:130px">
          </div>
          ${A()}
          <span id="statusSummary" style="font-size:11px;color:var(--text-dim)">Discovering\u2026</span>
        </div>

        <!-- Tree Panel -->
        <div class="tree-panel" id="treePanel"><div id="discovering">Scanning tests/ directory\u2026</div></div>

        <!-- Output Panel -->
        <div class="output-panel" id="output">Tests run in the "Lurek2D Tests" terminal.

Select a suite and click "Run Selected", or click \u25B6 next to any suite name.</div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span id="statusSuites" class="badge">0 suites</span>
          <div class="sep"></div>
          <span id="statusTests">0 tests</span>
          <div class="sep"></div>
          <span id="statusPass" style="color:#4caf50">0 pass</span>
          <div class="sep"></div>
          <span id="statusFail" style="color:#f44336">0 fail</span>
          <div class="spacer"></div>
          <span id="statusState">Ready</span>
        </div>
      </div>
    `,`
      let TEST_SUITES = [];
      let results = {};
      let selectedSuite = '';

      window.addEventListener('message', (e) => {
        const data = e.data;
        if (data.type === 'suites') {
          TEST_SUITES = data.suites;
          initResults();
          renderTree();
          document.getElementById('statusSummary').textContent = TEST_SUITES.length + ' suites discovered';
          document.getElementById('discovering')?.remove();
        }
        if (data.type === 'testStarted') {
          document.getElementById('statusSummary').textContent = 'Running: ' + data.filter;
          document.getElementById('statusState').textContent = 'Running\u2026';
          document.getElementById('output').textContent = '$ ' + data.command + '\\n\\nSee "Lurek2D Tests" terminal for live output.';
        }
      });

      function initResults() {
        results = {};
        for (const suite of TEST_SUITES) {
          for (const t of suite.tests) results[suite.name + '::' + t] = 'pending';
        }
      }

      function renderTree() {
        const panel = document.getElementById('treePanel');
        const filter = document.getElementById('filter').value.toLowerCase();
        panel.innerHTML = '';
        for (const suite of TEST_SUITES) {
          const filteredTests = suite.tests.filter(t => !filter || t.includes(filter) || suite.name.includes(filter));
          if (filteredTests.length === 0) continue;

          const suiteResults = filteredTests.map(t => results[suite.name + '::' + t]);
          const passCount = suiteResults.filter(r => r === 'pass').length;
          const failCount = suiteResults.filter(r => r === 'fail').length;

          const row = document.createElement('div');
          row.className = 'suite-row' + (selectedSuite === suite.name ? ' sel' : '');
          let badges = '';
          if (passCount) badges += '<span class="result-badge pass">' + passCount + ' \u2713</span>';
          if (failCount) badges += '<span class="result-badge fail">' + failCount + ' \u2717</span>';
          row.innerHTML = '<span>' + suite.name + badges + '</span>' +
            '<button class="suite-run-btn" data-suite="' + suite.name + '">\u25B6</button>';
          row.querySelector('.suite-run-btn').addEventListener('click', (ev) => {
            ev.stopPropagation();
            const s = ev.target.dataset.suite;
            selectedSuite = s;
            vscode.postMessage({ type: 'runSuite', suite: s });
            renderTree();
          });
          row.addEventListener('click', () => { selectedSuite = suite.name; renderTree(); });
          panel.appendChild(row);

          for (const t of filteredTests) {
            const key = suite.name + '::' + t;
            const item = document.createElement('div');
            item.className = 'test-item';
            const status = results[key] || 'pending';
            item.innerHTML = '<span class="dot ' + status + '"></span><span>' + t + '</span>';
            item.addEventListener('click', () => {
              document.getElementById('output').textContent = 'Suite: ' + suite.name + '\\nTest: ' + t + '\\nStatus: ' + status + '\\n\\nRun the suite to see actual results.';
            });
            panel.appendChild(item);
          }
        }
        updateStatusBar();
      }

      function updateStatusBar() {
        const all = Object.values(results);
        const pass = all.filter(r => r === 'pass').length;
        const fail = all.filter(r => r === 'fail').length;
        const total = TEST_SUITES.reduce((s, sr) => s + sr.tests.length, 0);
        document.getElementById('statusSuites').textContent = TEST_SUITES.length + ' suites';
        document.getElementById('statusTests').textContent = total + ' tests';
        document.getElementById('statusPass').textContent = pass + ' pass';
        document.getElementById('statusFail').textContent = fail + ' fail';
      }

      document.getElementById('btnRunAll').addEventListener('click', () => vscode.postMessage({ type: 'runAll' }));
      document.getElementById('btnRunLua').addEventListener('click', () => vscode.postMessage({ type: 'runLua' }));
      document.getElementById('btnRunGolden').addEventListener('click', () => vscode.postMessage({ type: 'runGolden' }));
      document.getElementById('btnRunSelected').addEventListener('click', () => {
        if (selectedSuite) vscode.postMessage({ type: 'runSuite', suite: selectedSuite });
        else document.getElementById('statusSummary').textContent = 'Select a suite first';
      });
      document.getElementById('filter').addEventListener('input', renderTree);

      // Request suite discovery
      vscode.postMessage({ type: 'discoverSuites' });
    `)}};var At=C(require("vscode"));Vt();var En=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.apiReference","API Reference"),this.loadApiData()}async loadApiData(){try{let e=At.workspace.workspaceFolders;if(!e)return;let t=qe(e[0].uri.fsPath);if(!t)return;let r=await At.workspace.fs.readFile(At.Uri.file(t)),a=new globalThis.TextDecoder().decode(r);this.panel.webview.postMessage({type:"apiData",content:a})}catch{}}handleMessage(e){}getHtml(){let e=L();return I(e,"API Reference",`
      .editor-layout {
        display: grid; grid-template-columns: 200px 1fr;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .module-list { grid-row: 2; overflow-y: auto; border-right: 1px solid var(--border); background: var(--surface); }
      .doc-panel { grid-row: 2; overflow-y: auto; padding: 12px 20px; background: var(--bg); }

      .module-item {
        padding: 5px 10px; cursor: pointer; border-radius: var(--radius); font-size: 11px;
        margin: 1px 4px; display: flex; justify-content: space-between; align-items: center;
        border: 1px solid transparent; transition: border-color 0.1s, background 0.08s;
      }
      .module-item:hover { border-color: var(--accent); background: var(--hover); }
      .module-item.sel { background: var(--selection); border-color: var(--accent); }
      .module-count { font-size: 9px; color: var(--text-dim); background: var(--surface-2); padding: 1px 5px; border-radius: 9px; }

      .func-card {
        background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius);
        padding: 10px; margin-bottom: 8px;
      }
      .func-card h3 { font-size: 13px; color: var(--accent-2); margin-bottom: 3px; font-family: 'Cascadia Code', monospace; }
      .func-card .sig { font-size: 11px; color: var(--accent); font-family: 'Cascadia Code', monospace; margin-bottom: 6px; background: rgba(0,0,0,0.2); padding: 4px 8px; border-radius: var(--radius); }
      .func-card .desc { font-size: 11px; line-height: 1.5; }
      .func-card .param { font-size: 10px; color: var(--text-dim); margin-left: 12px; }
      .func-card .returns { font-size: 10px; color: #4ec9b0; margin-top: 4px; }

      .module-header { font-size: 15px; font-weight: 700; margin-bottom: 8px; padding-bottom: 6px; border-bottom: 1px solid var(--border); }
      .module-desc { font-size: 11px; color: var(--text-dim); margin-bottom: 14px; line-height: 1.5; }
      .tag { display: inline-block; padding: 1px 6px; border-radius: 9px; font-size: 9px; margin-left: 6px; font-weight: 600; }
      .tag.event { background: rgba(76,175,80,0.15); color: #4caf50; }
    `,`
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group" style="flex:1">
            <input id="searchInput" placeholder="Search functions, modules\u2026" style="flex:1;max-width:260px">
            <select id="filterType">
              <option value="">All Types</option>
              <option value="function">Functions</option>
              <option value="callback">Callbacks</option>
              <option value="constant">Constants</option>
            </select>
          </div>
        </div>

        <!-- Module List -->
        <div class="module-list" id="moduleList"></div>

        <!-- Doc Panel -->
        <div class="doc-panel" id="docPanel">
          <div class="module-header">Lurek2D API Reference</div>
          <div class="module-desc">Select a module from the left panel to browse its API.</div>
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span id="statusModules" class="badge">0 modules</span>
          <div class="sep"></div>
          <span id="statusFuncs">0 functions</span>
          <div class="spacer"></div>
          <span id="statusSource" style="font-size:10px;color:var(--text-dim)">Built-in data</span>
        </div>
      </div>
    `,`
      const API_DATA = {
        'lurek.graphic': {
          desc: 'Drawing primitives, colors, transforms, and render state. Also available as lurek.render table.',
          funcs: [
            { name: 'lurek.graphic.rectangle', sig: 'lurek.graphic.rectangle(mode, x, y, w, h)', desc: 'Draw a rectangle.', params: ['mode: "fill" or "line"', 'x, y: position', 'w, h: size'], returns: 'nil' },
            { name: 'lurek.graphic.circle', sig: 'lurek.graphic.circle(mode, x, y, r)', desc: 'Draw a circle.', params: ['mode: "fill" or "line"', 'x, y: center', 'r: radius'], returns: 'nil' },
            { name: 'lurek.graphic.line', sig: 'lurek.graphic.line(x1, y1, x2, y2)', desc: 'Draw a line between two points.', params: ['x1, y1: start point', 'x2, y2: end point'], returns: 'nil' },
            { name: 'lurek.graphic.print', sig: 'lurek.graphic.print(text, x, y)', desc: 'Draw text at position.', params: ['text: string to draw', 'x, y: position'], returns: 'nil' },
            { name: 'lurek.graphic.setColor', sig: 'lurek.graphic.setColor(r, g, b, a)', desc: 'Set the active drawing color.', params: ['r, g, b: 0-1 color channels', 'a: alpha (default 1)'], returns: 'nil' },
            { name: 'lurek.graphic.setBackgroundColor', sig: 'lurek.graphic.setBackgroundColor(r, g, b)', desc: 'Set the background clear color.', params: ['r, g, b: 0-1 color channels'], returns: 'nil' },
            { name: 'lurek.graphic.draw', sig: 'lurek.graphic.draw(image, x, y, r, sx, sy)', desc: 'Draw an image/texture.', params: ['image: texture object', 'x, y: position', 'r: rotation (radians)', 'sx, sy: scale'], returns: 'nil' },
            { name: 'lurek.graphic.newImage', sig: 'lurek.graphic.newImage(path)', desc: 'Load an image from file and return texture handle.', params: ['path: file path relative to game dir'], returns: 'Image' },
          ]
        },
        'lurek.input.keyboard': {
          desc: 'Keyboard input state and key queries.',
          funcs: [
            { name: 'lurek.input.keyboard.isDown', sig: 'lurek.input.keyboard.isDown(key)', desc: 'Check if a key is currently held down.', params: ['key: key name ("space", "a", "left", etc.)'], returns: 'boolean' },
            { name: 'lurek.input.keyboard.isUp', sig: 'lurek.input.keyboard.isUp(key)', desc: 'Check if a key is not pressed.', params: ['key: key name'], returns: 'boolean' },
          ]
        },
        'lurek.input.mouse': {
          desc: 'Mouse position and button queries.',
          funcs: [
            { name: 'lurek.input.mouse.getPosition', sig: 'lurek.input.mouse.getPosition()', desc: 'Get current mouse position.', params: [], returns: 'x, y' },
            { name: 'lurek.input.mouse.isDown', sig: 'lurek.input.mouse.isDown(button)', desc: 'Check if a mouse button is held.', params: ['button: 1=left, 2=right, 3=middle'], returns: 'boolean' },
          ]
        },
        'lurek.audio': {
          desc: 'Sound loading and playback.',
          funcs: [
            { name: 'lurek.audio.newSource', sig: 'lurek.audio.newSource(path, type)', desc: 'Load an audio source.', params: ['path: file path', 'type: "static" or "stream"'], returns: 'Source' },
            { name: 'lurek.audio.play', sig: 'lurek.audio.play(source)', desc: 'Play an audio source.', params: ['source: Source object'], returns: 'nil' },
            { name: 'lurek.audio.stop', sig: 'lurek.audio.stop(source)', desc: 'Stop an audio source.', params: ['source: Source object'], returns: 'nil' },
            { name: 'lurek.audio.setVolume', sig: 'lurek.audio.setVolume(source, vol)', desc: 'Set volume of a source.', params: ['source: Source object', 'vol: 0.0-1.0'], returns: 'nil' },
          ]
        },
        'lurek.physics': {
          desc: 'Physics world, bodies, and collision.',
          funcs: [
            { name: 'lurek.physics.newWorld', sig: 'lurek.physics.newWorld(gx, gy)', desc: 'Create a physics world.', params: ['gx, gy: gravity vector'], returns: 'World' },
            { name: 'lurek.physics.newBody', sig: 'lurek.physics.newBody(world, x, y, type)', desc: 'Create a physics body.', params: ['world: World', 'x, y: position', 'type: "dynamic", "static", "kinematic"'], returns: 'Body' },
            { name: 'lurek.physics.update', sig: 'lurek.physics.update(world, dt)', desc: 'Step the physics world.', params: ['world: World', 'dt: time step'], returns: 'nil' },
          ]
        },
        'lurek.timer': {
          desc: 'Time and delta queries.',
          funcs: [
            { name: 'lurek.timer.getDelta', sig: 'lurek.timer.getDelta()', desc: 'Get time since last frame in seconds.', params: [], returns: 'number' },
            { name: 'lurek.timer.getFPS', sig: 'lurek.timer.getFPS()', desc: 'Get current frames per second.', params: [], returns: 'number' },
            { name: 'lurek.timer.getTime', sig: 'lurek.timer.getTime()', desc: 'Get time since engine start.', params: [], returns: 'number' },
          ]
        },
        'lurek.window': {
          desc: 'Window management.',
          funcs: [
            { name: 'lurek.window.setTitle', sig: 'lurek.window.setTitle(title)', desc: 'Set window title.', params: ['title: string'], returns: 'nil' },
            { name: 'lurek.window.getWidth', sig: 'lurek.window.getWidth()', desc: 'Get window width.', params: [], returns: 'number' },
            { name: 'lurek.window.getHeight', sig: 'lurek.window.getHeight()', desc: 'Get window height.', params: [], returns: 'number' },
            { name: 'lurek.window.setMode', sig: 'lurek.window.setMode(w, h, flags)', desc: 'Set window size and mode.', params: ['w, h: dimensions', 'flags: table with fullscreen, vsync, etc.'], returns: 'nil' },
          ]
        },
        'lurek.math': {
          desc: 'Math utilities.',
          funcs: [
            { name: 'lurek.math.random', sig: 'lurek.math.random(min, max)', desc: 'Random number between min and max.', params: ['min, max: range bounds'], returns: 'number' },
            { name: 'lurek.math.lerp', sig: 'lurek.math.lerp(a, b, t)', desc: 'Linear interpolation.', params: ['a, b: values', 't: 0-1 factor'], returns: 'number' },
            { name: 'lurek.math.clamp', sig: 'lurek.math.clamp(x, min, max)', desc: 'Clamp value to range.', params: ['x: value', 'min, max: bounds'], returns: 'number' },
          ]
        },
        'Callbacks': {
          desc: 'Engine callback functions set by game scripts. These are called by the engine main loop.',
          funcs: [
            { name: 'lurek.init', sig: 'function lurek.init()', desc: 'Called once when the game starts. Initialize resources here.', params: [], returns: 'nil', tag: 'event' },
            { name: 'lurek.process', sig: 'function lurek.process(dt)', desc: 'Called every frame. Update game logic.', params: ['dt: delta time in seconds'], returns: 'nil', tag: 'event' },
            { name: 'lurek.draw', sig: 'function lurek.draw()', desc: 'Called every frame after process. Push draw commands here using lurek.render.* functions.', params: [], returns: 'nil', tag: 'event' },
            { name: 'lurek.draw_ui', sig: 'function lurek.draw_ui()', desc: 'Called after draw. Draw UI elements on top using lurek.render.* functions.', params: [], returns: 'nil', tag: 'event' },
            { name: 'lurek.keypressed', sig: 'function lurek.keypressed(key)', desc: 'Called when key is pressed.', params: ['key: key name string'], returns: 'nil', tag: 'event' },
            { name: 'lurek.mousepressed', sig: 'function lurek.mousepressed(x, y, btn)', desc: 'Called on mouse press.', params: ['x, y: position', 'btn: button number'], returns: 'nil', tag: 'event' },
          ]
        }
      };

      let selectedModule = '';
      let loadedMarkdown = '';

      function renderModuleList() {
        const el = document.getElementById('moduleList');
        const search = document.getElementById('searchInput').value.toLowerCase();
        el.innerHTML = '';
        let totalFuncs = 0;
        for (const mod of Object.keys(API_DATA)) {
          const funcs = API_DATA[mod].funcs;
          totalFuncs += funcs.length;
          const matchesMod = mod.toLowerCase().includes(search);
          const matchingFuncs = funcs.filter(f => f.name.toLowerCase().includes(search) || f.desc.toLowerCase().includes(search));
          if (!matchesMod && matchingFuncs.length === 0 && search) continue;
          const div = document.createElement('div');
          div.className = 'module-item' + (mod === selectedModule ? ' sel' : '');
          div.innerHTML = '<span>' + mod + '</span><span class="module-count">' + funcs.length + '</span>';
          div.addEventListener('click', () => { selectedModule = mod; renderModuleList(); renderDocs(); });
          el.appendChild(div);
        }
        document.getElementById('statusModules').textContent = Object.keys(API_DATA).length + ' modules';
        document.getElementById('statusFuncs').textContent = totalFuncs + ' functions';
      }

      function renderDocs() {
        const el = document.getElementById('docPanel');
        if (!selectedModule || !API_DATA[selectedModule]) {
          el.innerHTML = '<div class="module-header">Lurek2D API Reference</div><div class="module-desc">Select a module from the left panel to browse its API.</div>';
          if (loadedMarkdown) {
            el.innerHTML += '<div style="white-space:pre-wrap;font-size:11px;color:var(--text-dim);max-height:80vh;overflow-y:auto;margin-top:12px">' + escapeHtml(loadedMarkdown.substring(0, 5000)) + '</div>';
          }
          return;
        }
        const mod = API_DATA[selectedModule];
        const search = document.getElementById('searchInput').value.toLowerCase();
        const filterType = document.getElementById('filterType').value;

        let html = '<div class="module-header">' + selectedModule + '</div>';
        html += '<div class="module-desc">' + mod.desc + '</div>';

        const funcs = mod.funcs.filter(f => {
          if (search && !f.name.toLowerCase().includes(search) && !f.desc.toLowerCase().includes(search)) return false;
          if (filterType === 'callback' && f.tag !== 'event') return false;
          if (filterType === 'function' && f.tag === 'event') return false;
          return true;
        });

        for (const f of funcs) {
          html += '<div class="func-card">';
          html += '<h3>' + f.name + (f.tag ? '<span class="tag ' + f.tag + '">' + f.tag + '</span>' : '') + '</h3>';
          html += '<div class="sig">' + f.sig + '</div>';
          html += '<div class="desc">' + f.desc + '</div>';
          if (f.params.length) {
            html += '<div style="margin-top:4px;font-size:10px;color:var(--text-dim)">Parameters:</div>';
            for (const p of f.params) html += '<div class="param">\u2022 ' + p + '</div>';
          }
          html += '<div class="returns">Returns: ' + f.returns + '</div>';
          html += '</div>';
        }

        if (funcs.length === 0) html += '<p style="color:var(--text-dim);font-size:11px">No matching functions found.</p>';
        el.innerHTML = html;
      }

      function escapeHtml(text) {
        return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
      }

      document.getElementById('searchInput').addEventListener('input', () => { renderModuleList(); renderDocs(); });
      document.getElementById('filterType').addEventListener('change', () => renderDocs());

      window.addEventListener('message', (e) => {
        if (e.data.type === 'apiData') {
          loadedMarkdown = e.data.content;
          document.getElementById('statusSource').textContent = 'Workspace API data loaded';
          renderDocs();
        }
      });

      renderModuleList();
      renderDocs();
    `)}};var Qe=C(require("vscode"));var Ln=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.postfxOverlay","PostFX & Overlay Designer")}handleMessage(e){if(e.type==="copyCode"&&(Qe.env.clipboard.writeText(e.code),Qe.window.showInformationMessage("PostFX code copied to clipboard.")),e.type==="insertCode"){let t=Qe.window.activeTextEditor;t?t.insertSnippet(new Qe.SnippetString(e.code)):Qe.window.showWarningMessage("Open a Lua file to insert code.")}}getHtml(){let e=L();return I(e,"PostFX & Overlay Designer",`
      .editor-layout { display:grid; grid-template-rows:auto auto 1fr auto; height:100vh; overflow:hidden; }
      .toolbar { display:flex; align-items:center; gap:6px; padding:6px 10px; background:var(--surface); border-bottom:1px solid var(--border); }
      .toolbar .title { font-weight:600; font-size:13px; white-space:nowrap; }
      .tab-bar { display:flex; gap:2px; padding:4px 10px; background:var(--surface); border-bottom:1px solid var(--border); flex-wrap:wrap; }
      .tab { padding:4px 12px; border-radius:var(--radius) var(--radius) 0 0; font-size:12px; cursor:pointer; background:transparent; border:1px solid transparent; border-bottom:none; color:var(--text-dim); transition:background .15s,color .15s; }
      .tab:hover { background:var(--hover); color:var(--text); }
      .tab.sel { background:var(--bg); color:var(--accent); border-color:var(--border); font-weight:600; }
      .main-area { display:grid; grid-template-columns:320px 1fr; gap:0; overflow:hidden; }
      .props-col { overflow-y:auto; padding:8px 10px; border-right:1px solid var(--border); }
      .vis-col { display:flex; flex-direction:column; gap:8px; padding:8px 10px; overflow-y:auto; }
      .vis-box { background:var(--bg); border-radius:var(--radius); border:1px solid var(--border); overflow:hidden; aspect-ratio:16/9; }
      .vis-box canvas { display:block; width:100%; }
      .code-out { font-family:'Cascadia Code','Fira Code',monospace; font-size:11px; background:var(--bg); color:var(--accent); border:1px solid var(--border); border-radius:var(--radius); padding:10px; white-space:pre; overflow-x:auto; min-height:80px; max-height:200px; }
      .dsp-row { display:flex; align-items:center; gap:8px; margin-bottom:6px; font-size:12px; }
      .dsp-row label { min-width:120px; color:var(--text-dim); font-size:11px; }
      .dsp-row input[type=range] { flex:1; accent-color:var(--accent); }
      .dsp-row input[type=color] { width:36px; height:24px; padding:0; border:1px solid var(--border); border-radius:var(--radius); cursor:pointer; background:transparent; }
      .dsp-row input[type=checkbox] { width:15px; height:15px; accent-color:var(--accent); cursor:pointer; }
      .dsp-row .val { font-size:10px; min-width:34px; text-align:right; color:var(--text-dim); font-family:monospace; }
      .dsp-row select { background:var(--surface); color:var(--text); border:1px solid var(--border); padding:3px 6px; border-radius:var(--radius); font-size:11px; }
      .status-bar { display:flex; align-items:center; gap:8px; padding:4px 10px; background:var(--surface); border-top:1px solid var(--border); font-size:11px; color:var(--text-dim); }
      .badge { background:var(--accent); color:var(--bg); padding:1px 7px; border-radius:10px; font-size:10px; font-weight:600; }
      .sep { width:1px; height:14px; background:var(--border); }
      .spacer { flex:1; }
      .code-label { font-size:11px; color:var(--text-dim); text-transform:uppercase; letter-spacing:.05em; margin:0 0 4px; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <span class="title">${c.effect??"\u{1F3A8}"} PostFX & Overlay Designer</span>
          ${k()}
          ${g(c.copy,"btnCopy","Copy Code")}
          ${g(c.add,"btnInsert","Insert at Cursor")}
          ${A()}
          ${g(c.save,"btnExport","Export Lua")}
        </div>
        <div class="tab-bar" id="tabs">
          <button class="tab sel" data-tab="weather">Weather</button>
          <button class="tab" data-tab="timeofday">Time of Day</button>
          <button class="tab" data-tab="screen">Screen Effects</button>
          <button class="tab" data-tab="shake">Camera Shake</button>
          <button class="tab" data-tab="overlay">Overlay Presets</button>
        </div>
        <div class="main-area">
          <div class="props-col">
            <!-- WEATHER -->
            <div id="tab-weather">
              ${b("Weather",`
                <div class="dsp-row"><label>Preset</label>
                  <select id="weatherPreset"><option>Clear</option><option>Rain</option><option>Heavy Rain</option><option>Snow</option><option>Blizzard</option><option>Fog</option><option>Sandstorm</option><option>Thunderstorm</option></select>
                </div>
                <div class="dsp-row"><label>Intensity</label><input type="range" id="weatherIntensity" min="0" max="1" step="0.01" value="0.5"><span class="val" id="weatherIntensityVal">0.50</span></div>
                <div class="dsp-row"><label>Wind X</label><input type="range" id="windX" min="-500" max="500" step="1" value="80"><span class="val" id="windXVal">80</span></div>
                <div class="dsp-row"><label>Wind Y</label><input type="range" id="windY" min="50" max="600" step="1" value="300"><span class="val" id="windYVal">300</span></div>
                <div class="dsp-row"><label>Particle Color</label><input type="color" id="weatherColor" value="#aaddf0"></div>
                <div class="dsp-row"><label>Fog Density</label><input type="range" id="fogDensity" min="0" max="1" step="0.01" value="0"><span class="val" id="fogDensityVal">0.00</span></div>
                <div class="dsp-row"><label>Fog Color</label><input type="color" id="fogColor" value="#8899aa"></div>
              `)}
            </div>
            <!-- TIME OF DAY -->
            <div id="tab-timeofday" style="display:none">
              ${b("Time of Day",`
                <div class="dsp-row"><label>Hour</label><input type="range" id="hour" min="0" max="23.99" step="0.25" value="12"><span class="val" id="hourVal">12:00</span></div>
                <div class="dsp-row"><label>Sky Color</label><input type="color" id="skyColor" value="#87ceeb"></div>
                <div class="dsp-row"><label>Ambient Light</label><input type="range" id="ambientLight" min="0" max="1" step="0.01" value="1.0"><span class="val" id="ambientLightVal">1.00</span></div>
                <div class="dsp-row"><label>Sun Color</label><input type="color" id="sunColor" value="#fff5cc"></div>
                <div class="dsp-row"><label>Moon Enabled</label><input type="checkbox" id="moonEnabled" checked></div>
                <div class="dsp-row"><label>Stars Enabled</label><input type="checkbox" id="starsEnabled"></div>
                <div class="dsp-row"><label>Transition Speed</label><input type="range" id="todSpeed" min="0.001" max="0.1" step="0.001" value="0.01"><span class="val" id="todSpeedVal">0.010</span></div>
                <div class="dsp-row"><label>Preset</label>
                  <select id="todPreset"><option>Custom</option><option>Dawn</option><option>Morning</option><option>Noon</option><option>Afternoon</option><option>Dusk</option><option>Night</option><option>Midnight</option></select>
                </div>
              `)}
            </div>
            <!-- SCREEN EFFECTS -->
            <div id="tab-screen" style="display:none">
              ${b("Screen Effects",`
                <div class="dsp-row"><label>Vignette</label><input type="range" id="vignette" min="0" max="1" step="0.01" value="0"><span class="val" id="vignetteVal">0.00</span></div>
                <div class="dsp-row"><label>Vignette Color</label><input type="color" id="vignetteColor" value="#000000"></div>
                <div class="dsp-row"><label>Scanlines</label><input type="range" id="scanlines" min="0" max="1" step="0.01" value="0"><span class="val" id="scanlinesVal">0.00</span></div>
                <div class="dsp-row"><label>Color Saturation</label><input type="range" id="saturation" min="0" max="2" step="0.01" value="1"><span class="val" id="saturationVal">1.00</span></div>
                <div class="dsp-row"><label>Brightness</label><input type="range" id="brightness" min="0" max="2" step="0.01" value="1"><span class="val" id="brightnessVal">1.00</span></div>
                <div class="dsp-row"><label>Contrast</label><input type="range" id="contrast" min="0" max="3" step="0.01" value="1"><span class="val" id="contrastVal">1.00</span></div>
                <div class="dsp-row"><label>Chromatic Aberr.</label><input type="range" id="chromatic" min="0" max="10" step="0.1" value="0"><span class="val" id="chromaticVal">0.0</span></div>
                <div class="dsp-row"><label>Pixel Size</label><input type="range" id="pixelSize" min="1" max="16" step="1" value="1"><span class="val" id="pixelSizeVal">1</span></div>
                <div class="dsp-row"><label>Film Grain</label><input type="range" id="filmGrain" min="0" max="1" step="0.01" value="0"><span class="val" id="filmGrainVal">0.00</span></div>
                <div class="dsp-row"><label>Bloom</label><input type="range" id="bloom" min="0" max="1" step="0.01" value="0"><span class="val" id="bloomVal">0.00</span></div>
              `)}
            </div>
            <!-- CAMERA SHAKE -->
            <div id="tab-shake" style="display:none">
              ${b("Camera Shake",`
                <div class="dsp-row"><label>Amplitude</label><input type="range" id="shakeAmplitude" min="0" max="50" step="0.5" value="5"><span class="val" id="shakeAmplitudeVal">5.0</span></div>
                <div class="dsp-row"><label>Frequency</label><input type="range" id="shakeFrequency" min="1" max="60" step="1" value="20"><span class="val" id="shakeFrequencyVal">20</span></div>
                <div class="dsp-row"><label>Duration (s)</label><input type="range" id="shakeDuration" min="0.1" max="5" step="0.1" value="0.5"><span class="val" id="shakeDurationVal">0.50</span></div>
                <div class="dsp-row"><label>Decay</label><input type="range" id="shakeDecay" min="0.5" max="10" step="0.1" value="3"><span class="val" id="shakeDecayVal">3.0</span></div>
                <div class="dsp-row"><label>Rotation Shake</label><input type="range" id="shakeRotation" min="0" max="10" step="0.1" value="0"><span class="val" id="shakeRotationVal">0.0</span></div>
                <div class="dsp-row"><label>Trauma based</label><input type="checkbox" id="shakeTrauma" checked></div>
              `)}
            </div>
            <!-- OVERLAY PRESETS -->
            <div id="tab-overlay" style="display:none">
              ${b("Overlay Presets",`
                <div class="dsp-row"><label>Preset</label>
                  <select id="overlayPreset"><option>None</option><option>Blood Vignette</option><option>Underwater</option><option>Night Vision</option><option>Thermal Vision</option><option>Old Film</option><option>Heatwave</option><option>Poison</option><option>Fire Overlay</option></select>
                </div>
                <div class="dsp-row"><label>Overlay Alpha</label><input type="range" id="overlayAlpha" min="0" max="1" step="0.01" value="0.5"><span class="val" id="overlayAlphaVal">0.50</span></div>
                <div class="dsp-row"><label>Overlay Color</label><input type="color" id="overlayColor" value="#ff0000"></div>
                <div class="dsp-row"><label>Pulsate</label><input type="checkbox" id="overlayPulsate"></div>
                <div class="dsp-row"><label>Pulse Speed</label><input type="range" id="overlayPulseSpeed" min="0.5" max="10" step="0.5" value="2"><span class="val" id="overlayPulseSpeedVal">2.0</span></div>
              `)}
            </div>
          </div>

          <div class="vis-col">
            <div class="vis-box">
              <canvas id="preview" width="640" height="360"></canvas>
            </div>
            <div class="code-label">Generated Lua Code</div>
            <pre id="codeOut" class="code-out"></pre>
          </div>
        </div>
        <div class="status-bar">
          <span class="badge" id="tabBadge">Weather</span>
          <span class="sep"></span>
          <span id="effectCount">0 effects</span>
          <span class="spacer"></span>
          <span id="dirtyFlag">${c.clean??"\u2713"}</span>
        </div>
      </div>
    `,`
      const vscode = acquireVsCodeApi();
      let currentTab = 'weather';
      const undo = new UndoStack();

      function g(id) { return document.getElementById(id); }
      function fv(id) { return parseFloat(g(id).value); }

      function snap() {
        const data = {};
        document.querySelectorAll('input[type=range],input[type=color],select').forEach(el => { data[el.id] = el.value; });
        document.querySelectorAll('input[type=checkbox]').forEach(el => { data[el.id] = el.checked; });
        data._tab = currentTab;
        return data;
      }
      function load(data) {
        if (!data) return;
        Object.entries(data).forEach(([k,v]) => {
          if (k === '_tab') return;
          const el = g(k); if (!el) return;
          if (el.type === 'checkbox') el.checked = v;
          else el.value = v;
          const valEl = g(k + 'Val');
          if (valEl && el.type === 'range') {
            if (k === 'hour') { const h=Math.floor(v),m=Math.round((v-h)*60); valEl.textContent = h+':'+(m<10?'0':'')+m; }
            else if (el.step && parseFloat(el.step) >= 1) valEl.textContent = Math.round(v).toString();
            else valEl.textContent = parseFloat(v).toFixed(2);
          }
        });
        if (data._tab && data._tab !== currentTab) {
          currentTab = data._tab;
          document.querySelectorAll('.tab').forEach(t => t.classList.toggle('sel', t.dataset.tab === currentTab));
          document.querySelectorAll('.props-col > [id^="tab-"]').forEach(s => s.style.display = s.id === 'tab-' + currentTab ? '' : 'none');
          g('tabBadge').textContent = currentTab.charAt(0).toUpperCase() + currentTab.slice(1);
        }
        updateCode(); drawPreview();
      }

      // Tab switching
      document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', () => {
          currentTab = tab.dataset.tab;
          document.querySelectorAll('.tab').forEach(t => t.classList.remove('sel'));
          tab.classList.add('sel');
          document.querySelectorAll('.props-col > [id^="tab-"]').forEach(s => s.style.display = 'none');
          g('tab-' + currentTab).style.display = '';
          g('tabBadge').textContent = currentTab.charAt(0).toUpperCase() + currentTab.slice(1);
          updateCode(); drawPreview();
        });
      });

      // Live value labels
      document.querySelectorAll('input[type=range]').forEach(r => {
        const valEl = g(r.id + 'Val');
        function fmt(v) {
          if (r.id === 'hour') { const h = Math.floor(v); const m = Math.round((v-h)*60); return h+':'+(m<10?'0':'')+m; }
          if (r.step && parseFloat(r.step) >= 1) return Math.round(v).toString();
          return parseFloat(v).toFixed(2);
        }
        if (valEl) { valEl.textContent = fmt(r.value); r.addEventListener('input', () => { valEl.textContent = fmt(r.value); undo.push(snap()); markDirty(); updateCode(); drawPreview(); }); }
      });
      document.querySelectorAll('input[type=color],input[type=checkbox],select').forEach(el => el.addEventListener('change', () => { undo.push(snap()); markDirty(); updateCode(); drawPreview(); }));

      // Time-of-day presets
      const todPresets = {
        'Dawn':      { hour:5.5,  sky:'#ff8c42', ambient:0.45, sun:'#ffa44f' },
        'Morning':   { hour:8,    sky:'#87ceeb', ambient:0.75, sun:'#fffccc' },
        'Noon':      { hour:12,   sky:'#4fc3f7', ambient:1.0,  sun:'#ffffff' },
        'Afternoon': { hour:15.5, sky:'#87ceeb', ambient:0.9,  sun:'#fff0a0' },
        'Dusk':      { hour:18.5, sky:'#e67e4b', ambient:0.5,  sun:'#ffa44f' },
        'Night':     { hour:21,   sky:'#1a2344', ambient:0.2,  sun:'#aaaacc' },
        'Midnight':  { hour:0,    sky:'#0a0e24', ambient:0.05, sun:'#223366' },
      };
      g('todPreset').addEventListener('change', (e) => {
        const p = todPresets[e.target.value];
        if (!p) return;
        g('hour').value = p.hour;
        g('hourVal').textContent = (() => { const h=Math.floor(p.hour),m=Math.round((p.hour-h)*60); return h+':'+(m<10?'0':'')+m; })();
        g('skyColor').value = p.sky;
        g('ambientLight').value = p.ambient;
        g('ambientLightVal').textContent = p.ambient.toFixed(2);
        g('sunColor').value = p.sun;
        undo.push(snap()); markDirty(); updateCode(); drawPreview();
      });

      // Weather presets
      const wPresets = {
        'Rain':        { intensity:0.5, windX:80,  windY:350, color:'#aaddf0' },
        'Heavy Rain':  { intensity:1.0, windX:120, windY:500, color:'#aaddf0' },
        'Snow':        { intensity:0.4, windX:20,  windY:150, color:'#ffffff' },
        'Blizzard':    { intensity:1.0, windX:200, windY:200, color:'#eef5ff' },
        'Fog':         { intensity:0.6, windX:0,   windY:0,   color:'#8899aa', fogDensity:0.7 },
        'Sandstorm':   { intensity:0.8, windX:300, windY:100, color:'#c8a863' },
        'Thunderstorm':{ intensity:0.9, windX:150, windY:450, color:'#8899aa' },
      };
      g('weatherPreset').addEventListener('change', (e) => {
        const p = wPresets[e.target.value];
        if (!p) return;
        ['intensity','windX','windY'].forEach(k => {
          const el = g('weather'+k.charAt(0).toUpperCase()+k.slice(1)) || g(k);
          if (el && p[k] !== undefined) { el.value = p[k]; const v = g(el.id+'Val'); if(v) v.textContent = p[k]; }
        });
        if(p.color) g('weatherColor').value = p.color;
        if(p.fogDensity !== undefined) { g('fogDensity').value = p.fogDensity; g('fogDensityVal').textContent = p.fogDensity.toFixed(2); }
        undo.push(snap()); markDirty(); updateCode(); drawPreview();
      });

      // Overlay presets
      const oPresets = {
        'Blood Vignette':  { color:'#cc0000', alpha:0.4, pulsate:true, speed:3 },
        'Underwater':      { color:'#006080', alpha:0.3, pulsate:false },
        'Night Vision':    { color:'#004400', alpha:0.4, pulsate:false },
        'Thermal Vision':  { color:'#aa2200', alpha:0.3, pulsate:false },
        'Old Film':        { color:'#aa8855', alpha:0.25, pulsate:false },
        'Poison':          { color:'#226600', alpha:0.35, pulsate:true, speed:1.5 },
        'Fire Overlay':    { color:'#cc3300', alpha:0.3, pulsate:true, speed:4 },
      };
      g('overlayPreset').addEventListener('change', (e) => {
        const p = oPresets[e.target.value]; if(!p) return;
        g('overlayColor').value = p.color;
        g('overlayAlpha').value = p.alpha;
        g('overlayAlphaVal').textContent = p.alpha.toFixed(2);
        g('overlayPulsate').checked = !!p.pulsate;
        if(p.speed) { g('overlayPulseSpeed').value = p.speed; g('overlayPulseSpeedVal').textContent = p.speed.toFixed(1); }
        undo.push(snap()); markDirty(); updateCode(); drawPreview();
      });

      function countEffects() {
        let n = 0;
        if (currentTab === 'weather' && g('weatherPreset').value !== 'Clear') n++;
        if (currentTab === 'weather' && fv('fogDensity') > 0) n++;
        if (currentTab === 'screen') {
          if (fv('vignette') > 0) n++; if (fv('scanlines') > 0) n++; if (fv('saturation') !== 1) n++;
          if (fv('brightness') !== 1) n++; if (fv('contrast') !== 1) n++; if (fv('chromatic') > 0) n++;
          if (fv('pixelSize') > 1) n++; if (fv('filmGrain') > 0) n++; if (fv('bloom') > 0) n++;
        }
        if (currentTab === 'overlay' && g('overlayPreset').value !== 'None') n++;
        if (currentTab === 'shake') n++;
        if (currentTab === 'timeofday') n++;
        return n;
      }

      function updateCode() {
        let code = '';
        if (currentTab === 'weather') {
          const preset = g('weatherPreset').value;
          const intensity = fv('weatherIntensity');
          const windX = fv('windX'), windY = fv('windY');
          const color = g('weatherColor').value;
          const fogDensity = fv('fogDensity');
          const fogColor = g('fogColor').value;
          code = '-- Weather: ' + preset + '\\n';
          if (preset !== 'Clear') {
            code += 'local weather = lurek.effect.createWeather({\\n';
            code += '  preset   = "' + preset.toLowerCase().replace(/ /g,'_') + '",\\n';
            code += '  intensity = ' + intensity.toFixed(2) + ',\\n';
            code += '  wind      = lurek.math.vec2(' + windX + ', ' + windY + '),\\n';
            code += '  color     = lurek.graphic.newColor("' + color + '"),\\n';
            code += '})\\n\\n';
            code += 'function lurek.process(dt)\\n  weather:update(dt)\\nend\\n';
            code += 'function lurek.draw()
  weather:draw()
';
            if (fogDensity > 0) code += '  lurek.effect.fog({ density=' + fogDensity.toFixed(2) + ', color=lurek.graphic.newColor("' + fogColor + '") })\\n';
            code += 'end';
          } else {
            code += '-- No weather effects active';
          }
        } else if (currentTab === 'timeofday') {
          const hour = fv('hour');
          const sky = g('skyColor').value;
          const ambient = fv('ambientLight');
          const sun = g('sunColor').value;
          const moon = g('moonEnabled').checked;
          const stars = g('starsEnabled').checked;
          const speed = fv('todSpeed');
          code = '-- Time of Day Setup\\n';
          code += 'local tod = lurek.effect.createTimeOfDay({\\n';
          code += '  hour         = ' + hour.toFixed(2) + ',\\n';
          code += '  sky_color    = lurek.graphic.newColor("' + sky + '"),\\n';
          code += '  sun_color    = lurek.graphic.newColor("' + sun + '"),\\n';
          code += '  ambient      = ' + ambient.toFixed(2) + ',\\n';
          code += '  moon_enabled = ' + moon + ',\\n';
          code += '  stars        = ' + stars + ',\\n';
          code += '  speed        = ' + speed.toFixed(3) + ',\\n';
          code += '})\\n\\n';
          code += 'function lurek.process(dt)\\n  tod:update(dt)\\nend\\n';
          code += 'function lurek.draw()
  tod:drawSky()
  -- draw game world here
  tod:drawOverlay()
end';
        } else if (currentTab === 'screen') {
          const lines = [];
          const vig = fv('vignette');
          const scan = fv('scanlines');
          const sat = fv('saturation');
          const bright = fv('brightness');
          const cont = fv('contrast');
          const chrom = fv('chromatic');
          const px = fv('pixelSize');
          const grain = fv('filmGrain');
          const bloom_ = fv('bloom');
          code = '-- Screen PostFX
function lurek.draw()
  -- draw game
  local fx = lurek.effect.begin()
';
          if (vig > 0)    lines.push('  fx:vignette({ strength=' + vig.toFixed(2) + ', color=lurek.graphic.newColor("' + g('vignetteColor').value + '") })');
          if (scan > 0)   lines.push('  fx:scanlines({ alpha=' + scan.toFixed(2) + ' })');
          if (sat !== 1)  lines.push('  fx:saturation(' + sat.toFixed(2) + ')');
          if (bright !== 1) lines.push('  fx:brightness(' + bright.toFixed(2) + ')');
          if (cont !== 1) lines.push('  fx:contrast(' + cont.toFixed(2) + ')');
          if (chrom > 0)  lines.push('  fx:chromaticAberration(' + chrom.toFixed(1) + ')');
          if (px > 1)     lines.push('  fx:pixelate(' + px + ')');
          if (grain > 0)  lines.push('  fx:filmGrain(' + grain.toFixed(2) + ')');
          if (bloom_ > 0) lines.push('  fx:bloom({ threshold=0.7, strength=' + bloom_.toFixed(2) + ' })');
          code += lines.join('\\n') + '\\n  lurek.effect.finish(fx)\\nend';
        } else if (currentTab === 'shake') {
          const amp = fv('shakeAmplitude'), freq = fv('shakeFrequency');
          const dur = fv('shakeDuration'), decay = fv('shakeDecay');
          const rot = fv('shakeRotation');
          const trauma = g('shakeTrauma').checked;
          code = '-- Camera Shake\\n';
          code += 'local shaker = lurek.camera.createShaker({\\n';
          code += '  amplitude  = ' + amp.toFixed(1) + ',\\n';
          code += '  frequency  = ' + freq + ',\\n';
          code += '  duration   = ' + dur.toFixed(2) + ',\\n';
          code += '  decay      = ' + decay.toFixed(1) + ',\\n';
          code += '  rotation   = ' + rot.toFixed(1) + ',\\n';
          code += '  trauma     = ' + trauma + ',\\n';
          code += '})\\n\\n';
          code += '-- Trigger a shake (e.g. on explosion):\\nshaker:shake()\\n\\n';
          code += 'function lurek.process(dt)\\n  shaker:update(dt)\\nend\\n';
          code += 'function lurek.draw()
  shaker:push()
  -- draw everything here
  shaker:pop()
end';
        } else if (currentTab === 'overlay') {
          const preset = g('overlayPreset').value;
          const alpha = fv('overlayAlpha');
          const color = g('overlayColor').value;
          const pulse = g('overlayPulsate').checked;
          const speed = fv('overlayPulseSpeed');
          code = '-- Overlay: ' + preset + '\\n';
          code += 'local overlay = lurek.effect.createOverlay({\\n';
          code += '  preset  = "' + preset.toLowerCase().replace(/ /g,'_') + '",\\n';
          code += '  color   = lurek.graphic.newColor("' + color + '"),\\n';
          code += '  alpha   = ' + alpha.toFixed(2) + ',\\n';
          code += '  pulsate = ' + pulse + ',\\n';
          if (pulse) code += '  speed   = ' + speed.toFixed(1) + ',\\n';
          code += '})\\n\\n';
          code += 'function lurek.process(dt)\\n  overlay:update(dt)\\nend\\n';
          code += 'function lurek.draw()
  -- draw game
  overlay:draw()
end';
        }
        g('codeOut').textContent = code;
        g('effectCount').textContent = countEffects() + ' effect' + (countEffects() !== 1 ? 's' : '');
      }

      function drawPreview() {
        const canvas = g('preview');
        if (!canvas) return;
        const ctx = canvas.getContext('2d');
        const W = 640, H = 360;
        ctx.clearRect(0,0,W,H);

        if (currentTab === 'timeofday') {
          const sky = g('skyColor').value;
          ctx.fillStyle = sky; ctx.fillRect(0,0,W,H);
          ctx.fillStyle = '#2d4a1e'; ctx.fillRect(0,H*0.7,W,H*0.3);
          const hour = fv('hour');
          const sunX = (hour/24)*W;
          const sunY = H*0.5 - Math.sin((hour/24)*Math.PI)*H*0.4;
          if (hour > 5 && hour < 20) {
            ctx.beginPath(); ctx.arc(sunX,sunY,20,0,Math.PI*2);
            ctx.fillStyle = g('sunColor').value; ctx.fill();
          }
          const ambient = fv('ambientLight');
          if (ambient < 1) {
            ctx.fillStyle = 'rgba(0,0,20,' + (1-ambient).toFixed(2) + ')'; ctx.fillRect(0,0,W,H);
          }
        } else if (currentTab === 'weather') {
          ctx.fillStyle = '#3a5a7a'; ctx.fillRect(0,0,W,H);
          ctx.fillStyle = '#2d4a1e'; ctx.fillRect(0,H*0.7,W,H*0.3);
          const fog = fv('fogDensity');
          if (fog > 0) {
            ctx.fillStyle = 'rgba(' + parseInt(g('fogColor').value.slice(1,3),16) + ',' + parseInt(g('fogColor').value.slice(3,5),16) + ',' + parseInt(g('fogColor').value.slice(5,7),16) + ',' + (fog*0.8).toFixed(2) + ')';
            ctx.fillRect(0,0,W,H);
          }
          const intensity = fv('weatherIntensity');
          const preset = g('weatherPreset').value;
          if (preset !== 'Clear') {
            const col = g('weatherColor').value;
            ctx.strokeStyle = col; ctx.globalAlpha = intensity*0.7;
            const wX = fv('windX'), wY = fv('windY');
            const ang = Math.atan2(wY, wX);
            const count = Math.floor(intensity * 80);
            for (let i = 0; i < count; i++) {
              const x = Math.random()*W, y = Math.random()*H;
              const len = preset.includes('Snow') ? 3 : 12;
              ctx.beginPath(); ctx.moveTo(x, y);
              ctx.lineTo(x + Math.cos(ang)*len, y + Math.sin(ang)*len);
              ctx.stroke();
            }
            ctx.globalAlpha = 1;
          }
        } else {
          ctx.fillStyle = '#1e2d3a'; ctx.fillRect(0,0,W,H);
          ctx.fillStyle = '#2d4a1e'; ctx.fillRect(0,H*0.65,W,H*0.35);
          ctx.fillStyle = '#4a6741';
          ctx.fillRect(W*0.1,H*0.5,80,20); ctx.fillRect(W*0.4,H*0.4,60,20); ctx.fillRect(W*0.7,H*0.55,100,20);
        }

        if (currentTab === 'screen') {
          const vig = fv('vignette');
          if (vig > 0) {
            const vg = ctx.createRadialGradient(W/2,H/2,W*0.2,W/2,H/2,W*0.75);
            vg.addColorStop(0,'transparent');
            const vc = g('vignetteColor').value;
            vg.addColorStop(1,'rgba(' + parseInt(vc.slice(1,3),16) + ',' + parseInt(vc.slice(3,5),16) + ',' + parseInt(vc.slice(5,7),16) + ',' + vig + ')');
            ctx.fillStyle = vg; ctx.fillRect(0,0,W,H);
          }
        }
        if (currentTab === 'overlay') {
          const alpha = fv('overlayAlpha');
          const oc = g('overlayColor').value;
          ctx.fillStyle = 'rgba(' + parseInt(oc.slice(1,3),16) + ',' + parseInt(oc.slice(3,5),16) + ',' + parseInt(oc.slice(5,7),16) + ',' + (alpha*0.6) + ')';
          ctx.fillRect(0,0,W,H);
        }
      }

      g('btnCopy').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyCode', code: g('codeOut').textContent });
      });
      g('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertCode', code: g('codeOut').textContent });
      });
      g('btnExport').addEventListener('click', () => {
        vscode.postMessage({ type: 'exportLua', code: g('codeOut').textContent });
      });

      registerShortcut('ctrl+z', () => load(undo.undo()));
      registerShortcut('ctrl+shift+z', () => load(undo.redo()));
      registerShortcut('ctrl+s', () => g('btnExport').click());

      undo.push(snap());
      updateCode(); drawPreview();
    `)}};var Je=C(require("vscode"));var In=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.soundDsp","Sound DSP Panel")}handleMessage(e){if(e.type==="copyCode"&&(Je.env.clipboard.writeText(e.code),Je.window.showInformationMessage("Sound DSP code copied to clipboard.")),e.type==="insertCode"){let t=Je.window.activeTextEditor;t?t.insertSnippet(new Je.SnippetString(e.code)):Je.window.showWarningMessage("Open a Lua file to insert code.")}}getHtml(){let e=L();return I(e,"Sound DSP Panel",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr;
        grid-template-rows: auto auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-row: 1; }
      .tab-bar { display: flex; gap: 2px; padding: 2px 6px; background: var(--surface); border-bottom: 1px solid var(--border); overflow-x: auto; }
      .tab { padding: 4px 10px; border-radius: var(--radius) var(--radius) 0 0; font-size: 11px; cursor: pointer; background: transparent; border: 1px solid transparent; border-bottom: none; color: var(--text-dim); white-space: nowrap; }
      .tab:hover { background: var(--hover); }
      .tab.sel { background: var(--surface-2); color: var(--text); border-color: var(--border); }
      .main-area { display: grid; grid-template-columns: 320px 1fr; gap: 0; overflow: hidden; }
      .controls-panel { overflow-y: auto; padding: 6px; border-right: 1px solid var(--border); background: var(--surface); }
      .vis-panel { overflow-y: auto; padding: 6px; background: var(--bg); }
      .status-bar { grid-row: 4; }
      .dsp-row { display: flex; align-items: center; gap: 6px; margin-bottom: 4px; font-size: 11px; }
      .dsp-row label { min-width: 130px; color: var(--text-dim); }
      .dsp-row input[type=range] { flex: 1; }
      .val { font-size: 10px; min-width: 40px; text-align: right; color: var(--text-dim); font-family: var(--font-mono, monospace); }
      .vis-box { background: var(--bg); border-radius: var(--radius); border: 1px solid var(--border); padding: 4px; margin-bottom: 6px; }
      canvas { display: block; border-radius: var(--radius); }
      .eq-bands { display: flex; gap: 4px; align-items: flex-end; height: 110px; padding: 6px; background: var(--bg); border-radius: var(--radius); border: 1px solid var(--border); }
      .eq-band { display: flex; flex-direction: column; align-items: center; gap: 2px; flex: 1; }
      .eq-band input[type=range] { writing-mode: vertical-lr; direction: rtl; width: 20px; height: 70px; }
      .eq-band label { font-size: 9px; color: var(--text-dim); white-space: nowrap; }
      .eq-band .val { font-size: 9px; }
      .preset-row { display: flex; align-items: center; gap: 4px; margin-bottom: 6px; flex-wrap: wrap; }
      .preset-btn { font-size: 10px; padding: 2px 7px; border-radius: var(--radius); cursor: pointer; background: var(--surface-2); border: 1px solid var(--border); color: var(--text); transition: background 0.1s; }
      .preset-btn:hover { background: var(--accent); color: var(--bg); border-color: var(--accent); }
      .signal-chain { display: flex; gap: 4px; align-items: center; flex-wrap: wrap; font-size: 11px; margin-bottom: 6px; }
      .chain-node { background: var(--surface-2); border: 1px solid var(--accent); border-radius: var(--radius); padding: 2px 7px; color: var(--accent); font-size: 10px; }
      .chain-arrow { color: var(--text-dim); font-size: 10px; }
      .code-out { font-family: var(--font-mono, 'Cascadia Code', monospace); font-size: 10px; background: var(--bg); color: var(--accent); border-radius: var(--radius); border: 1px solid var(--border); padding: 6px; overflow-x: auto; white-space: pre; max-height: 280px; overflow-y: auto; margin: 4px 0; }
      .vis-mode-row { display: flex; gap: 8px; margin: 4px 0 6px; font-size: 10px; color: var(--text-dim); align-items: center; }
      .vis-mode-row label { cursor: pointer; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${g(c.copy,"btnCopy","Copy Code")}
            ${g(c.add,"btnInsert","Insert at Cursor")}
          </div>
          ${k()}
          <div class="group" style="font-size:10px;color:var(--text-dim)">Sound DSP Designer</div>
          ${A()}
          ${g(c.save,"btnExport","Export Lua")}
        </div>

        <div class="tab-bar" id="tabs">
          <button class="tab sel" data-tab="chain">Signal Chain</button>
          <button class="tab" data-tab="eq">Equalizer</button>
          <button class="tab" data-tab="reverb">Reverb</button>
          <button class="tab" data-tab="echo">Echo / Delay</button>
          <button class="tab" data-tab="chorus">Chorus</button>
          <button class="tab" data-tab="pitch">Pitch</button>
          <button class="tab" data-tab="dynamics">Dynamics</button>
          <button class="tab" data-tab="generator">Sound Gen</button>
        </div>

        <div class="main-area">
          <div class="controls-panel">
            <!-- SIGNAL CHAIN -->
            <div id="tab-chain">
              ${b("Signal Chain",'<div id="signalChain" class="signal-chain"></div>')}
              ${b("Master",`
                <div class="dsp-row"><label>Volume</label><input type="range" id="masterVolume" min="0" max="2" step="0.01" value="1"><span class="val" id="masterVolumeVal">1.00</span></div>
                <div class="dsp-row"><label>Pan</label><input type="range" id="masterPan" min="-1" max="1" step="0.01" value="0"><span class="val" id="masterPanVal">0.00</span></div>
                <div class="dsp-row"><label>Sample Rate</label>
                  <select id="sampleRate"><option value="22050">22050 Hz</option><option value="44100" selected>44100 Hz</option><option value="48000">48000 Hz</option></select>
                </div>
              `)}
            </div>
            <!-- EQ -->
            <div id="tab-eq" style="display:none">
              ${b("EQ Presets",`
                <div class="preset-row">
                  <button class="preset-btn" data-eq="flat">Flat</button>
                  <button class="preset-btn" data-eq="bass">Bass</button>
                  <button class="preset-btn" data-eq="treble">Treble</button>
                  <button class="preset-btn" data-eq="vocal">Vocal</button>
                  <button class="preset-btn" data-eq="underwater">Underwater</button>
                  <button class="preset-btn" data-eq="telephone">Telephone</button>
                  <button class="preset-btn" data-eq="radio">Lo-Fi</button>
                </div>
              `)}
              ${b("7-Band Parametric EQ",'<div class="eq-bands" id="eqBands"></div>')}
            </div>
            <!-- REVERB -->
            <div id="tab-reverb" style="display:none">
              ${b("Room Presets",`
                <div class="preset-row">
                  <button class="preset-btn" data-reverb="small">Small</button>
                  <button class="preset-btn" data-reverb="medium">Medium</button>
                  <button class="preset-btn" data-reverb="large">Large</button>
                  <button class="preset-btn" data-reverb="cave">Cave</button>
                  <button class="preset-btn" data-reverb="plate">Plate</button>
                  <button class="preset-btn" data-reverb="spring">Spring</button>
                </div>
              `)}
              ${b("Reverb",`
                <div class="dsp-row"><label>Room Size</label><input type="range" id="reverbRoom" min="0" max="1" step="0.01" value="0.5"><span class="val" id="reverbRoomVal">0.50</span></div>
                <div class="dsp-row"><label>Damping</label><input type="range" id="reverbDamp" min="0" max="1" step="0.01" value="0.5"><span class="val" id="reverbDampVal">0.50</span></div>
                <div class="dsp-row"><label>Wet / Dry</label><input type="range" id="reverbMix" min="0" max="1" step="0.01" value="0.3"><span class="val" id="reverbMixVal">0.30</span></div>
                <div class="dsp-row"><label>Pre-delay (ms)</label><input type="range" id="reverbPredelay" min="0" max="100" step="1" value="10"><span class="val" id="reverbPredelayVal">10</span></div>
                <div class="dsp-row"><label>Width</label><input type="range" id="reverbWidth" min="0" max="1" step="0.01" value="1"><span class="val" id="reverbWidthVal">1.00</span></div>
                <div class="dsp-row"><label>Decay (s)</label><input type="range" id="reverbDecay" min="0.1" max="10" step="0.1" value="2"><span class="val" id="reverbDecayVal">2.0</span></div>
              `)}
            </div>
            <!-- ECHO -->
            <div id="tab-echo" style="display:none">
              ${b("Echo / Delay",`
                <div class="dsp-row"><label>Delay (ms)</label><input type="range" id="echoDelay" min="10" max="2000" step="10" value="400"><span class="val" id="echoDelayVal">400</span></div>
                <div class="dsp-row"><label>Feedback</label><input type="range" id="echoFeedback" min="0" max="0.99" step="0.01" value="0.4"><span class="val" id="echoFeedbackVal">0.40</span></div>
                <div class="dsp-row"><label>Wet / Dry</label><input type="range" id="echoMix" min="0" max="1" step="0.01" value="0.4"><span class="val" id="echoMixVal">0.40</span></div>
                <div class="dsp-row"><label>Ping-Pong</label><input type="checkbox" id="echoPingPong"></div>
                <div class="dsp-row"><label>Sync BPM</label><input type="checkbox" id="echoSyncBpm"></div>
                <div class="dsp-row" id="bpmRow"><label>BPM</label><input type="range" id="echoBpm" min="60" max="200" step="1" value="120"><span class="val" id="echoBpmVal">120</span></div>
                <div class="dsp-row" id="divRow"><label>Division</label>
                  <select id="echoDiv"><option value="1">1/4</option><option value="0.5">1/8</option><option value="0.75">Dot 1/8</option><option value="0.333">Triplet</option></select>
                </div>
              `)}
            </div>
            <!-- CHORUS -->
            <div id="tab-chorus" style="display:none">
              ${b("Chorus / Flanger",`
                <div class="dsp-row"><label>Mode</label>
                  <select id="chorusMode"><option>Chorus</option><option>Flanger</option><option>Ensemble</option><option>Vibrato</option></select>
                </div>
                <div class="dsp-row"><label>Depth</label><input type="range" id="chorusDepth" min="0" max="1" step="0.01" value="0.5"><span class="val" id="chorusDepthVal">0.50</span></div>
                <div class="dsp-row"><label>Rate (Hz)</label><input type="range" id="chorusRate" min="0.1" max="10" step="0.1" value="1.5"><span class="val" id="chorusRateVal">1.50</span></div>
                <div class="dsp-row"><label>Wet / Dry</label><input type="range" id="chorusMix" min="0" max="1" step="0.01" value="0.4"><span class="val" id="chorusMixVal">0.40</span></div>
                <div class="dsp-row"><label>Voices</label><input type="range" id="chorusVoices" min="2" max="8" step="1" value="3"><span class="val" id="chorusVoicesVal">3</span></div>
                <div class="dsp-row"><label>Stereo Spread</label><input type="range" id="chorusSpread" min="0" max="1" step="0.01" value="0.7"><span class="val" id="chorusSpreadVal">0.70</span></div>
                <div class="dsp-row"><label>Flange FB</label><input type="range" id="flangerFeedback" min="0" max="0.95" step="0.01" value="0.5"><span class="val" id="flangerFeedbackVal">0.50</span></div>
              `)}
            </div>
            <!-- PITCH -->
            <div id="tab-pitch" style="display:none">
              ${b("Pitch Shift",`
                <div class="dsp-row"><label>Semitones</label><input type="range" id="pitchSemitones" min="-24" max="24" step="1" value="0"><span class="val" id="pitchSemitonesVal">0 st</span></div>
                <div class="dsp-row"><label>Fine (cents)</label><input type="range" id="pitchCents" min="-100" max="100" step="1" value="0"><span class="val" id="pitchCentsVal">0\xA2</span></div>
                <div class="dsp-row"><label>Formant</label><input type="checkbox" id="pitchFormant"></div>
                <div class="dsp-row"><label>Rate</label><input type="range" id="pitchRate" min="0.25" max="4" step="0.05" value="1"><span class="val" id="pitchRateVal">1.00\xD7</span></div>
              `)}
              ${b("Pitch Envelope",`
                <div class="dsp-row"><label>Sweep Start</label><input type="range" id="pitchSweepFrom" min="-12" max="12" step="1" value="0"><span class="val" id="pitchSweepFromVal">0 st</span></div>
                <div class="dsp-row"><label>Sweep End</label><input type="range" id="pitchSweepTo" min="-12" max="12" step="1" value="0"><span class="val" id="pitchSweepToVal">0 st</span></div>
                <div class="dsp-row"><label>Sweep Time (s)</label><input type="range" id="pitchSweepTime" min="0.01" max="2" step="0.01" value="0.5"><span class="val" id="pitchSweepTimeVal">0.50</span></div>
              `)}
            </div>
            <!-- DYNAMICS -->
            <div id="tab-dynamics" style="display:none">
              ${b("Compressor",`
                <div class="dsp-row"><label>Threshold (dB)</label><input type="range" id="compThreshold" min="-60" max="0" step="1" value="-24"><span class="val" id="compThresholdVal">-24</span></div>
                <div class="dsp-row"><label>Ratio</label><input type="range" id="compRatio" min="1" max="20" step="0.5" value="4"><span class="val" id="compRatioVal">4:1</span></div>
                <div class="dsp-row"><label>Attack (ms)</label><input type="range" id="compAttack" min="0.1" max="200" step="0.1" value="10"><span class="val" id="compAttackVal">10</span></div>
                <div class="dsp-row"><label>Release (ms)</label><input type="range" id="compRelease" min="10" max="2000" step="10" value="200"><span class="val" id="compReleaseVal">200</span></div>
                <div class="dsp-row"><label>Makeup (dB)</label><input type="range" id="compMakeup" min="0" max="24" step="0.5" value="0"><span class="val" id="compMakeupVal">0</span></div>
              `)}
              ${b("Gate / Limiter",`
                <div class="dsp-row"><label>Gate (dB)</label><input type="range" id="gateThreshold" min="-80" max="0" step="1" value="-60"><span class="val" id="gateThresholdVal">-60</span></div>
                <div class="dsp-row"><label>Ceiling (dB)</label><input type="range" id="limiterCeil" min="-20" max="0" step="0.5" value="-0.3"><span class="val" id="limiterCeilVal">-0.3</span></div>
              `)}
              ${b("Distortion",`
                <div class="dsp-row"><label>Drive</label><input type="range" id="distDrive" min="0" max="1" step="0.01" value="0"><span class="val" id="distDriveVal">0.00</span></div>
                <div class="dsp-row"><label>Mode</label>
                  <select id="distMode"><option>Soft Clip</option><option>Hard Clip</option><option>Fuzz</option><option>Bit Crush</option><option>Overdrive</option></select>
                </div>
                <div class="dsp-row"><label>Mix</label><input type="range" id="distMix" min="0" max="1" step="0.01" value="0.5"><span class="val" id="distMixVal">0.50</span></div>
              `)}
            </div>
            <!-- GENERATOR -->
            <div id="tab-generator" style="display:none">
              ${b("Waveform",`
                <div class="dsp-row"><label>Type</label>
                  <select id="genType"><option>Sine</option><option>Square</option><option>Sawtooth</option><option>Triangle</option><option>Noise</option><option>Pulse</option></select>
                </div>
                <div class="dsp-row"><label>Frequency (Hz)</label><input type="range" id="genFreq" min="20" max="4000" step="1" value="440"><span class="val" id="genFreqVal">440 Hz</span></div>
                <div class="dsp-row"><label>Volume</label><input type="range" id="genVol" min="0" max="1" step="0.01" value="0.5"><span class="val" id="genVolVal">0.50</span></div>
                <div class="dsp-row"><label>Duration (s)</label><input type="range" id="genDur" min="0.01" max="5" step="0.01" value="0.5"><span class="val" id="genDurVal">0.50</span></div>
              `)}
              ${b("ADSR Envelope",`
                <div class="dsp-row"><label>Attack (s)</label><input type="range" id="adsrAttack" min="0.001" max="2" step="0.001" value="0.01"><span class="val" id="adsrAttackVal">0.010</span></div>
                <div class="dsp-row"><label>Decay (s)</label><input type="range" id="adsrDecay" min="0.001" max="2" step="0.001" value="0.1"><span class="val" id="adsrDecayVal">0.100</span></div>
                <div class="dsp-row"><label>Sustain</label><input type="range" id="adsrSustain" min="0" max="1" step="0.01" value="0.7"><span class="val" id="adsrSustainVal">0.70</span></div>
                <div class="dsp-row"><label>Release (s)</label><input type="range" id="adsrRelease" min="0.001" max="3" step="0.001" value="0.3"><span class="val" id="adsrReleaseVal">0.300</span></div>
              `)}
              ${b("Sound Presets",`
                <div class="preset-row">
                  <button class="preset-btn" data-sound="laser">Laser</button>
                  <button class="preset-btn" data-sound="explosion">Explosion</button>
                  <button class="preset-btn" data-sound="jump">Jump</button>
                  <button class="preset-btn" data-sound="coin">Coin</button>
                  <button class="preset-btn" data-sound="powerup">Power-up</button>
                  <button class="preset-btn" data-sound="hurt">Hurt</button>
                  <button class="preset-btn" data-sound="blip">UI Blip</button>
                </div>
              `)}
            </div>
          </div>

          <div class="vis-panel">
            <div class="vis-box">
              <canvas id="visCanvas" width="560" height="120"></canvas>
            </div>
            <div class="vis-mode-row">
              <label><input type="radio" name="visMode" value="freq" checked> Frequency</label>
              <label><input type="radio" name="visMode" value="wave"> Waveform</label>
              <label><input type="radio" name="visMode" value="lissajous"> Lissajous</label>
            </div>
            ${b("Generated Lua Code",'<pre class="code-out" id="codeOut"></pre>')}
          </div>
        </div>

        <div class="status-bar">
          <span id="statusTab" class="badge">chain</span>
          <div class="sep"></div>
          <span id="statusRate">44100 Hz</span>
          <div class="sep"></div>
          <span id="statusVol">vol 1.00</span>
          <div class="spacer"></div>
          <span id="statusDirty" style="font-size:10px;color:var(--text-dim)">${c.clean}</span>
        </div>
      </div>
    `,`
      const undo = new UndoStack();
      let curTab = 'chain';

      document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', () => {
          curTab = tab.dataset.tab;
          document.querySelectorAll('.tab').forEach(t => t.classList.remove('sel'));
          tab.classList.add('sel');
          document.querySelectorAll('[id^="tab-"]').forEach(s => s.style.display = 'none');
          document.getElementById('tab-' + curTab).style.display = '';
          document.getElementById('statusTab').textContent = curTab;
          genCode(); drawVis();
        });
      });

      registerShortcut('ctrl+z', () => { /* undo placeholder */ });
      registerShortcut('ctrl+shift+z', () => { /* redo placeholder */ });
      registerShortcut('ctrl+s', () => document.getElementById('btnExport').click());

      document.querySelectorAll('input[type=range]').forEach(r => {
        const v = document.getElementById(r.id + 'Val');
        function fmt(val) {
          if (r.id === 'pitchSemitones' || r.id === 'pitchSweepFrom' || r.id === 'pitchSweepTo') return val + ' st';
          if (r.id === 'pitchCents') return val + '\\u00A2';
          if (r.id === 'pitchRate') return parseFloat(val).toFixed(2) + '\\u00D7';
          if (r.id === 'compRatio') return parseFloat(val).toFixed(1) + ':1';
          if (r.id === 'genFreq') return val + ' Hz';
          if (r.step && parseFloat(r.step) >= 1) return Math.round(val).toString();
          return parseFloat(val).toFixed(parseFloat(r.step) < 0.01 ? 3 : 2);
        }
        if (v) { v.textContent = fmt(r.value); r.addEventListener('input', () => { v.textContent = fmt(r.value); markDirty(); genCode(); drawVis(); }); }
        r.addEventListener('input', genCode);
      });
      document.querySelectorAll('select,input[type=checkbox]').forEach(el => el.addEventListener('change', () => { markDirty(); genCode(); drawVis(); }));

      const EQ_BANDS = [
        { freq:'60Hz', id:'eq0' }, { freq:'150Hz', id:'eq1' }, { freq:'400Hz', id:'eq2' },
        { freq:'1kHz', id:'eq3' }, { freq:'2.5kHz', id:'eq4' }, { freq:'6kHz', id:'eq5' }, { freq:'16kHz', id:'eq6' },
      ];
      const eqC = document.getElementById('eqBands');
      EQ_BANDS.forEach(b => {
        eqC.innerHTML += '<div class="eq-band"><input type="range" id="'+b.id+'" min="-12" max="12" step="0.5" value="0" orient="vertical"><label>'+b.freq+'</label><span class="val" id="'+b.id+'Val">0</span></div>';
      });
      document.querySelectorAll('#eqBands input[type=range]').forEach(r => {
        const v = document.getElementById(r.id + 'Val');
        if (v) r.addEventListener('input', () => { v.textContent = parseFloat(r.value).toFixed(1); markDirty(); genCode(); drawVis(); });
      });

      const eqPresets = { flat:[0,0,0,0,0,0,0], bass:[8,6,3,0,-1,-1,-2], treble:[-1,-1,0,1,3,5,7], vocal:[-2,0,2,4,3,1,-1], underwater:[-8,-6,-4,-2,-6,-10,-12], telephone:[-12,0,4,6,4,0,-12], radio:[-10,-4,2,6,4,2,-8] };
      document.querySelectorAll('[data-eq]').forEach(btn => {
        btn.addEventListener('click', () => { const vals=eqPresets[btn.dataset.eq]; EQ_BANDS.forEach((b,i)=>{const el=document.getElementById(b.id),v=document.getElementById(b.id+'Val');if(el){el.value=vals[i];if(v)v.textContent=vals[i].toFixed(1);}}); markDirty(); genCode(); drawVis(); });
      });

      const revPresets = { small:{room:0.2,damp:0.7,mix:0.2,predelay:5,width:0.6,decay:0.5}, medium:{room:0.5,damp:0.5,mix:0.3,predelay:20,width:0.9,decay:2.0}, large:{room:0.85,damp:0.3,mix:0.4,predelay:40,width:1.0,decay:5.0}, cave:{room:0.9,damp:0.1,mix:0.5,predelay:50,width:0.8,decay:7.0}, plate:{room:0.4,damp:0.8,mix:0.35,predelay:0,width:1.0,decay:1.5}, spring:{room:0.3,damp:0.6,mix:0.4,predelay:10,width:0.5,decay:1.2} };
      document.querySelectorAll('[data-reverb]').forEach(btn => {
        btn.addEventListener('click', () => { const p=revPresets[btn.dataset.reverb]; Object.entries({reverbRoom:p.room,reverbDamp:p.damp,reverbMix:p.mix,reverbPredelay:p.predelay,reverbWidth:p.width,reverbDecay:p.decay}).forEach(([id,val])=>{const el=document.getElementById(id),v=document.getElementById(id+'Val');if(el){el.value=val;if(v)v.textContent=parseFloat(el.step)>=1?Math.round(val):parseFloat(val).toFixed(2);}}); markDirty(); genCode(); drawVis(); });
      });

      const sndPresets = { laser:{type:'Square',freq:880,vol:0.7,dur:0.15,atk:0.001,dec:0.05,sus:0.3,rel:0.1,sweepFrom:6,sweepTo:-12,sweepTime:0.15}, explosion:{type:'Noise',freq:80,vol:0.9,dur:1.2,atk:0.001,dec:0.2,sus:0.2,rel:1.0,sweepFrom:0,sweepTo:-8,sweepTime:0.8}, jump:{type:'Sine',freq:220,vol:0.6,dur:0.3,atk:0.005,dec:0.1,sus:0.0,rel:0.15,sweepFrom:0,sweepTo:7,sweepTime:0.2}, coin:{type:'Sine',freq:660,vol:0.7,dur:0.2,atk:0.001,dec:0.05,sus:0.5,rel:0.1,sweepFrom:0,sweepTo:5,sweepTime:0.1}, powerup:{type:'Sawtooth',freq:220,vol:0.6,dur:0.6,atk:0.005,dec:0.1,sus:0.7,rel:0.2,sweepFrom:-5,sweepTo:7,sweepTime:0.5}, hurt:{type:'Triangle',freq:120,vol:0.8,dur:0.25,atk:0.001,dec:0.05,sus:0.3,rel:0.2,sweepFrom:2,sweepTo:-6,sweepTime:0.2}, blip:{type:'Sine',freq:440,vol:0.4,dur:0.07,atk:0.001,dec:0.01,sus:0.0,rel:0.05,sweepFrom:0,sweepTo:0,sweepTime:0.0} };
      document.querySelectorAll('[data-sound]').forEach(btn => {
        btn.addEventListener('click', () => {
          const p=sndPresets[btn.dataset.sound]; document.getElementById('genType').value=p.type;
          const fields={genFreq:p.freq,genVol:p.vol,genDur:p.dur,adsrAttack:p.atk,adsrDecay:p.dec,adsrSustain:p.sus,adsrRelease:p.rel,pitchSweepFrom:p.sweepFrom,pitchSweepTo:p.sweepTo,pitchSweepTime:p.sweepTime};
          Object.entries(fields).forEach(([id,val])=>{const el=document.getElementById(id),v=document.getElementById(id+'Val');if(el){el.value=val;if(v)v.textContent=el.step&&parseFloat(el.step)>=1?Math.round(val):parseFloat(val).toFixed(parseFloat(el.step||'0.01')<0.01?3:2);}});
          markDirty(); genCode(); drawVis();
        });
      });

      function g(id) { return document.getElementById(id); }
      function fv(id) { return parseFloat(g(id).value); }
      function bv(id) { return g(id).checked; }
      function sv(id) { return g(id).value; }

      function genCode() {
        let code = '';
        if (curTab === 'chain') {
          code = '-- Sound DSP Chain\\nlocal dsp = lurek.audio.createDsp()\\n\\n';
          code += 'dsp:setMasterVolume(' + fv('masterVolume').toFixed(2) + ')\\n';
          code += 'dsp:setMasterPan(' + fv('masterPan').toFixed(2) + ')\\n';
          code += 'dsp:setSampleRate(' + sv('sampleRate') + ')\\n\\n';
          code += '-- Apply DSP to a source:\\nlocal src = lurek.audio.load("my_sound.wav")\\n';
          code += 'lurek.audio.setDsp(src, dsp)\\nlurek.audio.play(src)';
        } else if (curTab === 'eq') {
          code = '-- 7-Band Parametric EQ\\nlocal eq = lurek.audio.createEq({\\n';
          const freqs = ['60','150','400','1000','2500','6000','16000'];
          EQ_BANDS.forEach((b,i) => { const gain=fv(b.id); if(gain!==0) code+='  { freq='+freqs[i]+', gain='+gain.toFixed(1)+' },\\n'; });
          code += '})\\nlurek.audio.addEffect(src, eq)';
        } else if (curTab === 'reverb') {
          code = '-- Reverb Effect\\nlocal reverb = lurek.audio.createReverb({\\n';
          code += '  room_size  = '+fv('reverbRoom').toFixed(2)+',\\n  damping    = '+fv('reverbDamp').toFixed(2)+',\\n';
          code += '  wet_dry    = '+fv('reverbMix').toFixed(2)+',\\n  pre_delay  = '+fv('reverbPredelay')+',\\n';
          code += '  width      = '+fv('reverbWidth').toFixed(2)+',\\n  decay      = '+fv('reverbDecay').toFixed(1)+',\\n';
          code += '})\\nlurek.audio.addEffect(src, reverb)';
        } else if (curTab === 'echo') {
          const syncBpm = bv('echoSyncBpm');
          code = '-- Echo / Delay\\nlocal echo = lurek.audio.createEcho({\\n';
          if (syncBpm) { code += '  bpm = '+fv('echoBpm')+', division = '+fv('echoDiv')+',\\n'; }
          else { code += '  delay_ms = '+fv('echoDelay')+',\\n'; }
          code += '  feedback = '+fv('echoFeedback').toFixed(2)+', wet_dry = '+fv('echoMix').toFixed(2)+',\\n';
          code += '  ping_pong = '+bv('echoPingPong')+',\\n})\\nlurek.audio.addEffect(src, echo)';
        } else if (curTab === 'chorus') {
          code = '-- '+sv('chorusMode')+' Effect\\nlocal chorus = lurek.audio.createChorus({\\n';
          code += '  mode = "'+sv('chorusMode').toLowerCase()+'", depth = '+fv('chorusDepth').toFixed(2)+',\\n';
          code += '  rate = '+fv('chorusRate').toFixed(2)+', wet_dry = '+fv('chorusMix').toFixed(2)+',\\n';
          code += '  voices = '+fv('chorusVoices')+', spread = '+fv('chorusSpread').toFixed(2)+',\\n';
          if (sv('chorusMode')==='Flanger') code += '  feedback = '+fv('flangerFeedback').toFixed(2)+',\\n';
          code += '})\\nlurek.audio.addEffect(src, chorus)';
        } else if (curTab === 'pitch') {
          const semi=fv('pitchSemitones'),cents=fv('pitchCents'),rate=fv('pitchRate');
          const sf=fv('pitchSweepFrom'),st2=fv('pitchSweepTo'),sTime=fv('pitchSweepTime');
          code = '-- Pitch Shift\\nlocal pitch = lurek.audio.createPitchShift({\\n';
          if(semi!==0) code+='  semitones = '+semi+',\\n';
          if(cents!==0) code+='  cents = '+cents+',\\n';
          if(rate!==1) code+='  rate = '+rate.toFixed(2)+',\\n';
          code += '  preserve_formants = '+bv('pitchFormant')+',\\n';
          if(sf!==0||st2!==0) code+='  sweep = { from='+sf+', to='+st2+', time='+sTime.toFixed(2)+' },\\n';
          code += '})\\nlurek.audio.addEffect(src, pitch)';
        } else if (curTab === 'dynamics') {
          const drive=fv('distDrive');
          code = '-- Dynamics Processing\\nlocal chain = lurek.audio.createDynamics({\\n';
          code += '  comp = {\\n    threshold = '+fv('compThreshold')+',\\n    ratio = '+fv('compRatio').toFixed(1)+',\\n';
          code += '    attack = '+fv('compAttack').toFixed(1)+',\\n    release = '+fv('compRelease')+',\\n';
          code += '    makeup = '+fv('compMakeup').toFixed(1)+',\\n  },\\n';
          code += '  gate = { threshold='+fv('gateThreshold')+' },\\n';
          code += '  limiter = { ceiling='+fv('limiterCeil').toFixed(1)+' },\\n';
          if(drive>0) code+='  distortion = { drive='+drive.toFixed(2)+', mode="'+sv('distMode').toLowerCase().replace(/ /g,'_')+'", mix='+fv('distMix').toFixed(2)+' },\\n';
          code += '})\\nlurek.audio.addEffect(src, chain)';
        } else if (curTab === 'generator') {
          const type=sv('genType').toLowerCase();
          code = '-- Procedural Sound: '+sv('genType')+'\\nlocal synth = lurek.audio.createSynth({\\n';
          code += '  wave = "'+type+'", frequency = '+fv('genFreq')+',\\n';
          code += '  volume = '+fv('genVol').toFixed(2)+', duration = '+fv('genDur').toFixed(2)+',\\n';
          code += '  adsr = { attack='+fv('adsrAttack').toFixed(3)+', decay='+fv('adsrDecay').toFixed(3)+', sustain='+fv('adsrSustain').toFixed(2)+', release='+fv('adsrRelease').toFixed(3)+' },\\n';
          const sf2=fv('pitchSweepFrom'),st3=fv('pitchSweepTo'),sT=fv('pitchSweepTime');
          if(sf2!==0||st3!==0) code+='  sweep = { from='+sf2+', to='+st3+', time='+sT.toFixed(2)+' },\\n';
          code += '})\\nlurek.audio.play(lurek.audio.fromSynth(synth))';
        }
        g('codeOut').textContent = code;
        updateChain();
        g('statusVol').textContent = 'vol '+fv('masterVolume').toFixed(2);
        g('statusRate').textContent = sv('sampleRate')+' Hz';
      }

      function updateChain() {
        const chain = g('signalChain');
        const nodes = ['Input','EQ','Reverb','Echo','Chorus','Pitch','Dynamics','Out'];
        chain.innerHTML = nodes.map(n => '<span class="chain-node">'+n+'</span>').join('<span class="chain-arrow">\\u2192</span>');
      }

      function drawVis() {
        const cvs = g('visCanvas'); if (!cvs) return;
        const cx = cvs.getContext('2d'), W = cvs.width, H = cvs.height;
        const bgCol = getComputedStyle(document.documentElement).getPropertyValue('--bg').trim() || '#1e1e1e';
        const accentCol = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim() || '#4fc3f7';
        const borderCol = getComputedStyle(document.documentElement).getPropertyValue('--border').trim() || '#333';
        const dimCol = getComputedStyle(document.documentElement).getPropertyValue('--text-dim').trim() || '#555';
        cx.fillStyle = bgCol; cx.fillRect(0,0,W,H);
        const mode = document.querySelector('input[name=visMode]:checked')?.value || 'freq';
        if (mode === 'freq') {
          cx.strokeStyle = accentCol; cx.lineWidth = 2; cx.beginPath();
          const gains = EQ_BANDS.map((b) => { try{return fv(b.id);}catch{return 0;} });
          for (let x=0;x<W;x++) { let gain=0; gains.forEach((g2,i)=>{const center=i/EQ_BANDS.length;gain+=g2*Math.exp(-Math.pow((x/W-center)*3,2));}); const y=H/2-(gain/12)*(H*0.4); if(x===0)cx.moveTo(x,y);else cx.lineTo(x,y); }
          cx.stroke();
          cx.strokeStyle = borderCol; cx.lineWidth = 1; cx.beginPath(); cx.moveTo(0,H/2); cx.lineTo(W,H/2); cx.stroke();
          ['20Hz','100Hz','1kHz','10kHz','20kHz'].forEach((lbl,i) => { const x=[0,0.12,0.52,0.85,1][i]*W; cx.fillStyle=dimCol; cx.font='9px sans-serif'; cx.fillText(lbl,x+2,H-3); });
        } else if (mode === 'wave') {
          cx.strokeStyle = accentCol; cx.lineWidth = 1.5; cx.beginPath();
          for (let x=0;x<W;x++) { const t=x/W*4*Math.PI; const y=H/2+Math.sin(t+Math.random()*0.05)*H*0.35; if(x===0)cx.moveTo(x,y);else cx.lineTo(x,y); }
          cx.stroke();
        } else {
          cx.strokeStyle = accentCol; cx.lineWidth = 1; cx.globalAlpha = 0.5; cx.beginPath();
          for (let i=0;i<500;i++) { const t=(i/500)*Math.PI*20; const x=W/2+Math.sin(t*1.5)*W*0.4; const y=H/2+Math.cos(t)*H*0.4; if(i===0)cx.moveTo(x,y);else cx.lineTo(x,y); }
          cx.stroke(); cx.globalAlpha = 1;
        }
      }

      document.querySelectorAll('input[name=visMode]').forEach(r => r.addEventListener('change', drawVis));
      document.getElementById('btnCopy').addEventListener('click', () => { vscode.postMessage({type:'copyCode',code:g('codeOut').textContent}); });
      document.getElementById('btnInsert').addEventListener('click', () => { vscode.postMessage({type:'insertCode',code:g('codeOut').textContent}); });
      document.getElementById('btnExport').addEventListener('click', () => { vscode.postMessage({type:'exportLua',content:g('codeOut').textContent}); });
      genCode(); drawVis();
    `)}};var Dn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.spriteAnimEditor","Sprite Animation")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"animation.lua");break}}getHtml(){let e=L();return I(e,"Sprite Animation",`
      .editor-layout {
        display: grid; grid-template-columns: 200px 1fr 200px;
        grid-template-rows: auto 1fr auto auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .frame-list { grid-row: 2; overflow-y: auto; border-right: 1px solid var(--border); background: var(--surface); padding: 4px; }
      .preview-area { grid-row: 2; display: flex; align-items: center; justify-content: center; background: var(--bg); position: relative; }
      .props-panel { grid-row: 2; overflow-y: auto; border-left: 1px solid var(--border); background: var(--surface); padding: 6px; }
      .timeline { grid-column: 1 / -1; background: var(--surface); border-top: 1px solid var(--border); padding: 6px 8px; min-height: 80px; }
      .frame-item {
        display: flex; align-items: center; gap: 6px; padding: 4px 6px;
        cursor: pointer; border-radius: var(--radius); font-size: 11px;
        border: 1px solid transparent; transition: border-color 0.1s, background 0.08s;
      }
      .frame-item:hover { border-color: var(--accent); background: var(--hover); }
      .frame-item.sel { background: var(--selection); border-color: var(--accent); }
      .frame-thumb { width: 28px; height: 28px; background: var(--surface-2); border: 1px solid var(--border); border-radius: var(--radius); }
      .timeline-track { display: flex; gap: 2px; padding: 4px 0; overflow-x: auto; }
      .timeline-frame {
        width: 36px; height: 36px; background: var(--surface-2); border: 1px solid var(--border);
        border-radius: var(--radius); cursor: pointer; flex-shrink: 0;
        display: flex; align-items: center; justify-content: center; font-size: 9px; color: var(--text-dim);
        transition: border-color 0.1s;
      }
      .timeline-frame:hover { border-color: var(--accent); }
      .timeline-frame.active { border-color: var(--accent); background: var(--selection); }
      .tag-list { display: flex; flex-wrap: wrap; gap: 3px; margin-top: 4px; }
      .anim-tag {
        background: rgba(0,122,204,0.2); color: var(--accent); padding: 1px 6px; border-radius: 9px;
        font-size: 9px; cursor: pointer; border: 1px solid var(--accent);
      }
      .anim-tag .rm { margin-left: 3px; opacity: 0.6; }
      .anim-tag .rm:hover { opacity: 1; }
      .playback-controls { display: flex; align-items: center; gap: 2px; }
      .playback-controls button { min-width: 28px; padding: 2px 6px; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${g(c.grid,"btnLoadSheet","Load Sheet")}
          </div>
          ${k()}
          <div class="group">
            <label>Cols:</label><input type="number" id="cols" value="4" min="1" max="64" style="width:40px">
            <label>Rows:</label><input type="number" id="rows" value="4" min="1" max="64" style="width:40px">
          </div>
          ${k()}
          <div class="playback-controls">
            <button id="btnFirst" title="First frame">\u23EE</button>
            <button id="btnPrev" title="Previous frame">\u25C0</button>
            <button id="btnPlay" title="Play/Pause">\u25B6 Play</button>
            <button id="btnNext" title="Next frame">\u25B6</button>
            <button id="btnLast" title="Last frame">\u23ED</button>
          </div>
          ${k()}
          <label>Speed:</label>
          <input type="range" id="speed" min="1" max="60" value="12" style="width:70px">
          <span id="speedLabel" style="font-size:10px;min-width:36px">12 fps</span>
          ${A()}
          ${g(c.save,"btnExport","Export Lua")}
        </div>

        <!-- Frame List -->
        <div class="frame-list" id="frameListPanel">
          <div style="font-size:10px;font-weight:700;text-transform:uppercase;color:var(--text-dim);margin-bottom:4px">Frames</div>
          <div id="frameList"></div>
          <button id="btnAddFrame" style="margin-top:6px;width:100%">+ Add Frame</button>
        </div>

        <!-- Preview -->
        <div class="preview-area">
          <canvas id="previewCanvas" width="256" height="256"></canvas>
        </div>

        <!-- Properties -->
        <div class="props-panel">
          ${b("Frame",`
            ${N("Duration (ms)",'<input type="number" id="frameDuration" value="100" min="16" max="5000">')}
            ${N("Origin X",'<input type="number" id="originX" value="0">')}
            ${N("Origin Y",'<input type="number" id="originY" value="0">')}
          `)}
          ${b("Animation",`
            ${N("Name",'<input type="text" id="animName" value="idle">')}
            <div class="field-row"><input type="checkbox" id="looping" checked><label for="looping">Loop</label></div>
          `)}
          ${b("Tags",`
            <div class="tag-list" id="tagList"></div>
            <div class="field-row" style="margin-top:4px">
              <input type="text" id="newTag" placeholder="New tag\u2026" style="flex:1">
              <button id="btnAddTag" style="min-width:24px">+</button>
            </div>
          `)}
        </div>

        <!-- Timeline -->
        <div class="timeline">
          <div style="font-size:10px;font-weight:700;text-transform:uppercase;color:var(--text-dim);margin-bottom:2px">Timeline</div>
          <div class="timeline-track" id="timelineTrack"></div>
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span id="statusFrame" class="badge">Frame: 1/16</span>
          <div class="sep"></div>
          <span id="statusSize">Sheet: 4\xD74</span>
          <div class="sep"></div>
          <span id="statusAnim">idle</span>
          <div class="spacer"></div>
          <span id="statusDirty" style="font-size:10px;color:var(--text-dim)">${c.clean}</span>
        </div>
      </div>
    `,`
      const undo = new UndoStack();
      let cols = 4, rows = 4;
      let frames = [];
      let currentFrame = 0;
      let playing = false;
      let playTimer = null;
      let fps = 12;
      let tags = [];

      const canvas = document.getElementById('previewCanvas');
      const ctx = canvas.getContext('2d');

      function initFrames() {
        frames = [];
        for (let i = 0; i < cols * rows; i++) {
          frames.push({ id: i, duration: 100, originX: 0, originY: 0 });
        }
        currentFrame = 0;
        rebuildUI();
      }

      function rebuildUI() {
        const list = document.getElementById('frameList');
        list.innerHTML = '';
        frames.forEach((f, i) => {
          const el = document.createElement('div');
          el.className = 'frame-item' + (i === currentFrame ? ' sel' : '');
          el.innerHTML = '<div class="frame-thumb"></div><span>Frame ' + (i+1) + ' (' + f.duration + 'ms)</span>';
          el.addEventListener('click', () => { currentFrame = i; rebuildUI(); });
          list.appendChild(el);
        });
        const track = document.getElementById('timelineTrack');
        track.innerHTML = '';
        frames.forEach((f, i) => {
          const el = document.createElement('div');
          el.className = 'timeline-frame' + (i === currentFrame ? ' active' : '');
          el.textContent = String(i + 1);
          el.addEventListener('click', () => { currentFrame = i; rebuildUI(); });
          track.appendChild(el);
        });
        if (frames[currentFrame]) {
          document.getElementById('frameDuration').value = frames[currentFrame].duration;
          document.getElementById('originX').value = frames[currentFrame].originX;
          document.getElementById('originY').value = frames[currentFrame].originY;
        }
        document.getElementById('statusFrame').textContent = 'Frame: ' + (currentFrame+1) + '/' + frames.length;
        document.getElementById('statusSize').textContent = 'Sheet: ' + cols + '\xD7' + rows;
        document.getElementById('statusAnim').textContent = document.getElementById('animName').value;
        renderPreview();
      }

      function renderPreview() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        const fw = canvas.width / cols;
        const fh = canvas.height / rows;
        ctx.strokeStyle = 'rgba(255,255,255,0.06)';
        for (let r = 0; r < rows; r++) {
          for (let c = 0; c < cols; c++) ctx.strokeRect(c * fw, r * fh, fw, fh);
        }
        const fc = currentFrame % cols;
        const fr = Math.floor(currentFrame / cols);
        ctx.fillStyle = 'rgba(0, 122, 204, 0.25)';
        ctx.fillRect(fc * fw, fr * fh, fw, fh);
        ctx.strokeStyle = 'var(--accent, #007acc)';
        ctx.lineWidth = 2;
        ctx.strokeRect(fc * fw, fr * fh, fw, fh);
        ctx.lineWidth = 1;
      }

      document.getElementById('btnPlay').addEventListener('click', () => {
        playing = !playing;
        document.getElementById('btnPlay').textContent = playing ? '\u23F8 Pause' : '\u25B6 Play';
        if (playing) {
          playTimer = setInterval(() => { currentFrame = (currentFrame + 1) % frames.length; rebuildUI(); }, 1000 / fps);
        } else { clearInterval(playTimer); }
      });
      document.getElementById('btnPrev').addEventListener('click', () => { currentFrame = (currentFrame - 1 + frames.length) % frames.length; rebuildUI(); });
      document.getElementById('btnNext').addEventListener('click', () => { currentFrame = (currentFrame + 1) % frames.length; rebuildUI(); });
      document.getElementById('btnFirst').addEventListener('click', () => { currentFrame = 0; rebuildUI(); });
      document.getElementById('btnLast').addEventListener('click', () => { currentFrame = frames.length - 1; rebuildUI(); });

      document.getElementById('speed').addEventListener('input', (e) => {
        fps = parseInt(e.target.value);
        document.getElementById('speedLabel').textContent = fps + ' fps';
        if (playing) { clearInterval(playTimer); playTimer = setInterval(() => { currentFrame = (currentFrame + 1) % frames.length; rebuildUI(); }, 1000 / fps); }
      });
      document.getElementById('cols').addEventListener('change', (e) => { cols = parseInt(e.target.value); initFrames(); });
      document.getElementById('rows').addEventListener('change', (e) => { rows = parseInt(e.target.value); initFrames(); });

      document.getElementById('frameDuration').addEventListener('change', (e) => {
        if (frames[currentFrame]) { frames[currentFrame].duration = parseInt(e.target.value); markDirty(); }
      });
      document.getElementById('originX').addEventListener('change', (e) => {
        if (frames[currentFrame]) { frames[currentFrame].originX = parseInt(e.target.value); markDirty(); }
      });
      document.getElementById('originY').addEventListener('change', (e) => {
        if (frames[currentFrame]) { frames[currentFrame].originY = parseInt(e.target.value); markDirty(); }
      });
      document.getElementById('btnAddFrame').addEventListener('click', () => {
        frames.push({ id: frames.length, duration: 100, originX: 0, originY: 0 });
        currentFrame = frames.length - 1; markDirty(); rebuildUI();
      });
      document.getElementById('btnAddTag').addEventListener('click', () => {
        const input = document.getElementById('newTag');
        const val = input.value.trim();
        if (val && !tags.includes(val)) { tags.push(val); input.value = ''; markDirty(); renderTags(); }
      });

      function renderTags() {
        const list = document.getElementById('tagList');
        list.innerHTML = '';
        tags.forEach((t, i) => {
          const el = document.createElement('span');
          el.className = 'anim-tag';
          el.innerHTML = t + '<span class="rm">\xD7</span>';
          el.querySelector('.rm').addEventListener('click', () => { tags.splice(i, 1); markDirty(); renderTags(); });
          list.appendChild(el);
        });
      }

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        lua += '  name = "' + document.getElementById('animName').value + '",\\n';
        lua += '  loop = ' + document.getElementById('looping').checked + ',\\n';
        lua += '  cols = ' + cols + ', rows = ' + rows + ',\\n';
        lua += '  tags = {' + tags.map(t => '"' + t + '"').join(', ') + '},\\n';
        lua += '  frames = {\\n';
        frames.forEach((f, i) => {
          lua += '    { id = ' + (i+1) + ', duration = ' + f.duration + ', ox = ' + f.originX + ', oy = ' + f.originY + ' },\\n';
        });
        lua += '  }\\n}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      registerShortcut('Ctrl+Z', () => undo.undo());
      registerShortcut('Ctrl+Shift+Z', () => undo.redo());

      initFrames();
      renderTags();
    `)}};var An=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.tilesetEditor","Tileset")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"tileset.lua");break}}getHtml(){let e=L();return I(e,"Tileset",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 220px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .tileset-area { grid-row: 2; position: relative; overflow: auto; background: var(--bg); }
      .props-panel { grid-row: 2; overflow-y: auto; border-left: 1px solid var(--border); background: var(--surface); padding: 6px; }
      .upload-zone {
        border: 2px dashed var(--border); border-radius: var(--radius); padding: 36px;
        text-align: center; color: var(--text-dim); cursor: pointer; margin: 20px;
        transition: border-color 0.15s, color 0.15s;
      }
      .upload-zone:hover { border-color: var(--accent); color: var(--accent); }
      .tile-props-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 3px; }
      .prop-chip {
        display: flex; align-items: center; gap: 4px; padding: 2px 6px;
        background: var(--surface-2); border-radius: var(--radius); font-size: 10px;
      }
      .auto-rule { display: flex; align-items: center; gap: 6px; padding: 4px; border-bottom: 1px solid var(--border); font-size: 10px; }
      .auto-rule-grid { display: grid; grid-template-columns: repeat(3, 14px); gap: 1px; }
      .auto-rule-cell {
        width: 14px; height: 14px; background: var(--surface-2); border: 1px solid var(--border);
        cursor: pointer; border-radius: 1px; transition: background 0.08s;
      }
      .auto-rule-cell.on { background: var(--accent); }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${g(c.add,"btnUpload","Upload Image")}
          </div>
          ${k()}
          <div class="group">
            <label>W:</label><input type="number" id="tileW" value="32" min="8" max="256" style="width:44px">
            <label>H:</label><input type="number" id="tileH" value="32" min="8" max="256" style="width:44px">
          </div>
          ${k()}
          <div class="group">
            ${g(c.grid,"btnShowGrid","Toggle Grid")}
            <button id="btnShowIds" title="Show Tile IDs" style="font-size:10px;padding:2px 6px">IDs</button>
          </div>
          ${A()}
          ${g(c.save,"btnExport","Export Lua")}
        </div>

        <div class="tileset-area" id="tilesetArea">
          <div class="upload-zone" id="uploadZone">
            <p style="font-size:13px">Drop tileset image here or click Upload</p>
            <p style="font-size:10px;margin-top:6px;color:var(--text-dim)">Supported: PNG, JPG</p>
          </div>
          <canvas id="tilesetCanvas" style="display:none;"></canvas>
        </div>

        <div class="props-panel">
          ${b("Selected Tile",`
            ${N("Tile ID",'<input type="text" id="tileId" readonly>')}
            ${N("Name",'<input type="text" id="tileName" placeholder="(optional)">')}
          `)}
          ${b("Properties",`
            <div class="tile-props-grid">
              <div class="prop-chip"><input type="checkbox" id="propSolid"><label for="propSolid">Solid</label></div>
              <div class="prop-chip"><input type="checkbox" id="propAnimated"><label for="propAnimated">Animated</label></div>
              <div class="prop-chip"><input type="checkbox" id="propSlope"><label for="propSlope">Slope</label></div>
              <div class="prop-chip"><input type="checkbox" id="propHazard"><label for="propHazard">Hazard</label></div>
            </div>
            ${N("Slope Angle",'<input type="range" id="slopeAngle" min="0" max="90" value="45" style="width:100%"><span id="slopeLabel" style="font-size:10px;min-width:24px">45\xB0</span>')}
          `)}
          ${b("Auto-Tile Rules",`
            <div id="autoRules"></div>
            <button id="btnAddRule" style="margin-top:4px;width:100%">+ Add Rule</button>
          `)}
        </div>

        <div class="status-bar">
          <span id="statusTile" class="badge">Tile: none</span>
          <div class="sep"></div>
          <span id="statusGrid">Grid: 0\xD70</span>
          <div class="sep"></div>
          <span id="statusTotal">0 tiles</span>
          <div class="spacer"></div>
          <span id="statusDirty" style="font-size:10px;color:var(--text-dim)">${c.clean}</span>
        </div>
      </div>
    `,`
      const canvas = document.getElementById('tilesetCanvas');
      const ctx = canvas.getContext('2d');
      const undo = new UndoStack();
      let tileW = 32, tileH = 32;
      let gridCols = 0, gridRows = 0;
      let selectedTile = -1;
      let showGrid = true, showIds = false;
      let tileProps = {};
      let autoRules = [];
      let imageLoaded = false;

      function getState() { return JSON.parse(JSON.stringify({ tileProps, autoRules })); }
      function loadState(s) { tileProps = s.tileProps; autoRules = s.autoRules; renderAutoRules(); draw(); }
      function pushUndo() { undo.push(getState()); markDirty(); }

      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) loadState(s); });
      registerShortcut('ctrl+shift+z', () => { const s = undo.redo(); if (s) loadState(s); });
      registerShortcut('ctrl+s', () => document.getElementById('btnExport').click());
      registerShortcut('g', () => document.getElementById('btnShowGrid').click());

      function updateGrid() {
        if (!imageLoaded) return;
        gridCols = Math.floor(canvas.width / tileW);
        gridRows = Math.floor(canvas.height / tileH);
        document.getElementById('statusGrid').textContent = 'Grid: ' + gridCols + '\\u00d7' + gridRows;
        document.getElementById('statusTotal').textContent = (gridCols * gridRows) + ' tiles';
        draw();
      }

      function draw() {
        if (!imageLoaded) return;
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        for (let y = 0; y < canvas.height; y += 16) {
          for (let x = 0; x < canvas.width; x += 16) {
            ctx.fillStyle = (Math.floor(x/16) + Math.floor(y/16)) % 2 === 0 ? '#2a2a2a' : '#242424';
            ctx.fillRect(x, y, 16, 16);
          }
        }
        if (showGrid) {
          ctx.strokeStyle = 'rgba(255,255,255,0.08)';
          ctx.lineWidth = 0.5;
          for (let c = 0; c <= gridCols; c++) { ctx.beginPath(); ctx.moveTo(c*tileW, 0); ctx.lineTo(c*tileW, gridRows*tileH); ctx.stroke(); }
          for (let r = 0; r <= gridRows; r++) { ctx.beginPath(); ctx.moveTo(0, r*tileH); ctx.lineTo(gridCols*tileW, r*tileH); ctx.stroke(); }
        }
        if (showIds) {
          ctx.fillStyle = 'rgba(255,255,255,0.7)';
          ctx.font = '9px monospace';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          for (let r = 0; r < gridRows; r++)
            for (let c = 0; c < gridCols; c++)
              ctx.fillText(String(r * gridCols + c), c * tileW + tileW/2, r * tileH + tileH/2);
        }
        if (selectedTile >= 0) {
          const sc = selectedTile % gridCols, sr = Math.floor(selectedTile / gridCols);
          ctx.strokeStyle = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim() || '#89b4fa';
          ctx.lineWidth = 2;
          ctx.strokeRect(sc * tileW + 1, sr * tileH + 1, tileW - 2, tileH - 2);
        }
      }

      canvas.addEventListener('click', (e) => {
        const rect = canvas.getBoundingClientRect();
        const c = Math.floor((e.clientX - rect.left) / tileW);
        const r = Math.floor((e.clientY - rect.top) / tileH);
        if (c < gridCols && r < gridRows) {
          selectedTile = r * gridCols + c;
          document.getElementById('tileId').value = selectedTile;
          document.getElementById('statusTile').textContent = 'Tile: ' + selectedTile;
          const p = tileProps[selectedTile] || {};
          document.getElementById('propSolid').checked = !!p.solid;
          document.getElementById('propAnimated').checked = !!p.animated;
          document.getElementById('propSlope').checked = !!p.slope;
          document.getElementById('propHazard').checked = !!p.hazard;
          document.getElementById('tileName').value = p.name || '';
          draw();
        }
      });

      function saveCurrentTileProps() {
        if (selectedTile < 0) return;
        pushUndo();
        tileProps[selectedTile] = {
          solid: document.getElementById('propSolid').checked,
          animated: document.getElementById('propAnimated').checked,
          slope: document.getElementById('propSlope').checked,
          hazard: document.getElementById('propHazard').checked,
          name: document.getElementById('tileName').value,
          slopeAngle: parseInt(document.getElementById('slopeAngle').value),
        };
      }

      ['propSolid','propAnimated','propSlope','propHazard','tileName'].forEach(id =>
        document.getElementById(id).addEventListener('change', saveCurrentTileProps));

      document.getElementById('slopeAngle').addEventListener('input', (e) => {
        document.getElementById('slopeLabel').textContent = e.target.value + '\\u00B0';
        saveCurrentTileProps();
      });

      document.getElementById('tileW').addEventListener('change', (e) => { tileW = parseInt(e.target.value); updateGrid(); });
      document.getElementById('tileH').addEventListener('change', (e) => { tileH = parseInt(e.target.value); updateGrid(); });

      document.getElementById('btnShowGrid').addEventListener('click', function() {
        showGrid = !showGrid; this.classList.toggle('active', showGrid); draw();
      });
      document.getElementById('btnShowIds').addEventListener('click', function() {
        showIds = !showIds; this.classList.toggle('active', showIds); draw();
      });

      document.getElementById('btnUpload').addEventListener('click', () => {
        canvas.style.display = 'block';
        document.getElementById('uploadZone').style.display = 'none';
        canvas.width = 256; canvas.height = 256;
        imageLoaded = true;
        updateGrid();
      });

      document.getElementById('btnAddRule').addEventListener('click', () => {
        pushUndo();
        autoRules.push({ mask: new Array(9).fill(false), target: selectedTile >= 0 ? selectedTile : 0 });
        renderAutoRules();
      });

      function renderAutoRules() {
        const c = document.getElementById('autoRules'); c.innerHTML = '';
        autoRules.forEach((rule, ri) => {
          const row = document.createElement('div'); row.className = 'auto-rule';
          const grid = document.createElement('div'); grid.className = 'auto-rule-grid';
          for (let i = 0; i < 9; i++) {
            const cell = document.createElement('div');
            cell.className = 'auto-rule-cell' + (rule.mask[i] ? ' on' : '');
            cell.addEventListener('click', () => { pushUndo(); rule.mask[i] = !rule.mask[i]; renderAutoRules(); });
            grid.appendChild(cell);
          }
          row.appendChild(grid);
          const lbl = document.createElement('span');
          lbl.textContent = ' \\u2192 Tile ' + rule.target;
          row.appendChild(lbl);
          c.appendChild(row);
        });
      }

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        lua += '  tile_width = ' + tileW + ',\\n  tile_height = ' + tileH + ',\\n';
        lua += '  cols = ' + gridCols + ', rows = ' + gridRows + ',\\n';
        lua += '  tiles = {\\n';
        for (let i = 0; i < gridCols * gridRows; i++) {
          const p = tileProps[i];
          if (p) {
            lua += '    [' + i + '] = { solid = ' + !!p.solid + ', animated = ' + !!p.animated;
            if (p.name) lua += ', name = "' + p.name + '"';
            if (p.slope) lua += ', slope = ' + (p.slopeAngle || 45);
            if (p.hazard) lua += ', hazard = true';
            lua += ' },\\n';
          }
        }
        lua += '  },\\n  auto_rules = {\\n';
        autoRules.forEach((r, i) => {
          lua += '    { mask = {' + r.mask.map(v => v ? '1' : '0').join(',') + '}, target = ' + r.target + ' },\\n';
        });
        lua += '  }\\n}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      vscode.postMessage({ type: 'stateChanged', state: { ready: true } });
    `)}};var _n=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.audioMixerEditor","Audio Mixer")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"mixer.lua");break}}getHtml(){let e=L();return I(e,"Audio Mixer",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 210px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .mixer-area {
        grid-row: 2; display: flex; gap: 2px; padding: 8px; overflow-x: auto;
        align-items: stretch; background: var(--bg);
      }
      .fx-panel {
        grid-row: 2; overflow-y: auto; border-left: 1px solid var(--border);
        background: var(--surface); padding: 6px;
      }
      .ch-strip {
        display: flex; flex-direction: column; align-items: center; gap: 4px;
        background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius);
        padding: 6px; min-width: 72px; flex-shrink: 0; cursor: pointer; transition: border-color 0.12s;
      }
      .ch-strip:hover { border-color: var(--hover); }
      .ch-strip.sel { border-color: var(--accent); }
      .ch-strip.master { min-width: 88px; }
      .ch-label { font-size: 10px; font-weight: 600; text-transform: uppercase; color: var(--text-dim); letter-spacing: 0.3px; }
      .fader-wrap { display: flex; flex-direction: column; align-items: center; flex: 1; min-height: 140px; justify-content: center; }
      .fader {
        -webkit-appearance: none; appearance: none; width: 5px; height: 130px;
        background: var(--surface-2); border-radius: 3px; outline: none;
        writing-mode: vertical-lr; direction: rtl;
      }
      .fader::-webkit-slider-thumb {
        -webkit-appearance: none; width: 18px; height: 8px;
        background: var(--text); border-radius: 2px; cursor: pointer;
      }
      .fader-val { font-size: 9px; color: var(--text-dim); margin-top: 3px; font-family: var(--font-mono, monospace); }
      .vu { width: 10px; height: 90px; background: var(--bg); border: 1px solid var(--border); border-radius: 2px; position: relative; overflow: hidden; }
      .vu-bar { position: absolute; bottom: 0; width: 100%; background: linear-gradient(to top, var(--success), var(--warning), var(--error)); transition: height 0.08s; }
      .pan-knob {
        width: 28px; height: 28px; border-radius: 50%; background: var(--surface-2);
        border: 2px solid var(--border); position: relative; cursor: pointer;
      }
      .pan-dot {
        position: absolute; width: 2px; height: 8px; background: var(--accent);
        top: 3px; left: 50%; transform-origin: bottom center;
      }
      .ch-btns { display: flex; gap: 2px; }
      .btn-m, .btn-s { width: 24px; height: 18px; font-size: 9px; font-weight: 700; padding: 0; border-radius: 2px; }
      .btn-m.active { background: var(--error); border-color: var(--error); color: #fff; }
      .btn-s.active { background: var(--warning); border-color: var(--warning); color: #000; }
      .fx-item {
        display: flex; align-items: center; justify-content: space-between;
        padding: 3px 6px; background: var(--surface-2); border-radius: var(--radius); margin-bottom: 3px; font-size: 11px;
        cursor: pointer; transition: background 0.1s;
      }
      .fx-item:hover { background: var(--hover); }
      .fx-item.sel { border-left: 2px solid var(--accent); }
      .bus-row { display: flex; align-items: center; gap: 4px; margin-bottom: 3px; font-size: 10px; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${g(c.add,"btnAddCh","Add Channel")}
            ${g(c.delete,"btnRemCh","Remove Channel")}
          </div>
          ${k()}
          <div class="group">
            <button id="btnReset" title="Reset All" style="font-size:10px;padding:2px 8px">Reset</button>
          </div>
          ${A()}
          ${g(c.save,"btnExport","Export Lua")}
        </div>

        <div class="mixer-area" id="mixerArea"></div>

        <div class="fx-panel">
          ${b("Effects Chain",`
            <div id="fxList"></div>
            <select id="addFx" style="width:100%;margin-top:4px;font-size:10px;">
              <option value="">+ Add Effect\u2026</option>
              <option value="reverb">Reverb</option>
              <option value="delay">Delay</option>
              <option value="lpf">Low-Pass Filter</option>
              <option value="hpf">High-Pass Filter</option>
              <option value="compressor">Compressor</option>
              <option value="distortion">Distortion</option>
            </select>
          `)}
          ${b("Bus Routing",'<div id="busRouting"></div>')}
          ${b("Effect Params",`
            <div id="fxParams"><p style="font-size:10px;color:var(--text-dim)">Select an effect</p></div>
          `)}
        </div>

        <div class="status-bar">
          <span id="stCh" class="badge">5 ch</span>
          <div class="sep"></div>
          <span id="stSel">Master</span>
          <div class="sep"></div>
          <span id="stFx">0 fx</span>
          <div class="spacer"></div>
          <span id="stDirty" style="font-size:10px;color:var(--text-dim)">${c.clean}</span>
        </div>
      </div>
    `,`
      const undo = new UndoStack();
      const NAMES = ['Master','Music','SFX','Voice','Ambient'];
      let channels = NAMES.map((name, i) => ({ name, vol: i===0?100:80, pan: 50, mute: false, solo: false, bus: 'master' }));
      let effects = [];
      let selCh = 0, selFx = -1;

      function snap() { return JSON.parse(JSON.stringify({ channels, effects })); }
      function load(s) { channels = s.channels; effects = s.effects; build(); buildFx(); buildBus(); }
      function push() { undo.push(snap()); markDirty(); }

      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) load(s); });
      registerShortcut('ctrl+shift+z', () => { const s = undo.redo(); if (s) load(s); });
      registerShortcut('ctrl+s', () => document.getElementById('btnExport').click());

      function build() {
        const area = document.getElementById('mixerArea'); area.innerHTML = '';
        channels.forEach((ch, i) => {
          const s = document.createElement('div');
          s.className = 'ch-strip' + (i===0?' master':'') + (i===selCh?' sel':'');
          const vu = 30 + Math.random()*50;
          s.innerHTML =
            '<span class="ch-label">'+ch.name+'</span>'+
            '<div class="vu"><div class="vu-bar" style="height:'+vu+'%"></div></div>'+
            '<div class="fader-wrap"><input type="range" class="fader" min="0" max="100" value="'+ch.vol+'" data-i="'+i+'"><span class="fader-val">'+ch.vol+'</span></div>'+
            '<div class="pan-knob" title="Pan: '+(ch.pan-50)+'"><div class="pan-dot" style="transform:rotate('+((ch.pan-50)*1.35)+'deg)"></div></div>'+
            '<div class="ch-btns"><button class="btn-m'+(ch.mute?' active':'')+'" data-i="'+i+'">M</button><button class="btn-s'+(ch.solo?' active':'')+'" data-i="'+i+'">S</button></div>';
          s.addEventListener('click', () => { selCh = i; document.getElementById('stSel').textContent = ch.name; build(); buildBus(); });
          area.appendChild(s);
        });
        area.querySelectorAll('.fader').forEach(f => f.addEventListener('input', e => {
          const idx = +e.target.dataset.i; channels[idx].vol = +e.target.value;
          e.target.parentElement.querySelector('.fader-val').textContent = e.target.value;
          push();
        }));
        area.querySelectorAll('.btn-m').forEach(b => b.addEventListener('click', e => {
          e.stopPropagation(); const idx = +b.dataset.i; push(); channels[idx].mute = !channels[idx].mute; b.classList.toggle('active', channels[idx].mute);
        }));
        area.querySelectorAll('.btn-s').forEach(b => b.addEventListener('click', e => {
          e.stopPropagation(); const idx = +b.dataset.i; push(); channels[idx].solo = !channels[idx].solo; b.classList.toggle('active', channels[idx].solo);
        }));
        document.getElementById('stCh').textContent = channels.length + ' ch';
      }

      function buildFx() {
        const list = document.getElementById('fxList'); list.innerHTML = '';
        effects.forEach((fx, i) => {
          const el = document.createElement('div');
          el.className = 'fx-item' + (i===selFx?' sel':'');
          el.innerHTML = '<span>'+fx.type+'</span><button style="padding:0 4px;font-size:9px" data-i="'+i+'">\xD7</button>';
          el.addEventListener('click', () => { selFx = i; showFxParams(fx); buildFx(); });
          el.querySelector('button').addEventListener('click', e => { e.stopPropagation(); push(); effects.splice(i,1); buildFx(); });
          list.appendChild(el);
        });
        document.getElementById('stFx').textContent = effects.length + ' fx';
      }

      function showFxParams(fx) {
        const c = document.getElementById('fxParams');
        const map = { reverb:['mix','decay','damping'], delay:['time','feedback','mix'], lpf:['cutoff','resonance'], hpf:['cutoff','resonance'], compressor:['threshold','ratio','attack','release'], distortion:['drive','tone'] };
        const ps = map[fx.type] || [];
        c.innerHTML = '<div style="font-size:10px;font-weight:600;margin-bottom:4px;text-transform:uppercase;color:var(--text-dim)">'+fx.type+'</div>';
        ps.forEach(p => {
          const v = fx.params[p] || 50;
          c.innerHTML += '<div class="field-inline"><label style="font-size:10px">'+p+'</label><input type="range" min="0" max="100" value="'+v+'" style="flex:1"><span style="font-size:9px;min-width:20px">'+v+'</span></div>';
        });
      }

      function buildBus() {
        const c = document.getElementById('busRouting'); c.innerHTML = '';
        channels.forEach((ch, i) => {
          if (i===0) return;
          const r = document.createElement('div'); r.className = 'bus-row';
          r.innerHTML = '<span style="min-width:48px">'+ch.name+'</span><select data-i="'+i+'"><option value="master">Master</option><option value="bus1">Bus 1</option><option value="bus2">Bus 2</option></select>';
          r.querySelector('select').value = ch.bus;
          r.querySelector('select').addEventListener('change', e => { push(); channels[i].bus = e.target.value; });
          c.appendChild(r);
        });
      }

      document.getElementById('addFx').addEventListener('change', e => {
        if (e.target.value) { push(); effects.push({ type: e.target.value, channel: selCh, params: {} }); e.target.value = ''; buildFx(); }
      });
      document.getElementById('btnAddCh').addEventListener('click', () => {
        push(); channels.push({ name: 'Ch '+channels.length, vol: 80, pan: 50, mute: false, solo: false, bus: 'master' }); build();
      });
      document.getElementById('btnRemCh').addEventListener('click', () => {
        if (channels.length > 1) { push(); channels.pop(); if (selCh >= channels.length) selCh = channels.length-1; build(); }
      });
      document.getElementById('btnReset').addEventListener('click', () => {
        push(); channels.forEach((ch,i) => { ch.vol = i===0?100:80; ch.pan = 50; ch.mute = false; ch.solo = false; });
        effects = []; build(); buildFx();
      });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  channels = {\\n';
        channels.forEach(ch => {
          lua += '    { name = "'+ch.name+'", volume = '+(ch.vol/100).toFixed(2)+', pan = '+((ch.pan-50)/50).toFixed(2)+', mute = '+ch.mute+', bus = "'+ch.bus+'" },\\n';
        });
        lua += '  },\\n  effects = {\\n';
        effects.forEach(fx => { lua += '    { type = "'+fx.type+'", channel = '+(fx.channel+1)+' },\\n'; });
        lua += '  }\\n}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      setInterval(() => {
        document.querySelectorAll('.vu-bar').forEach((el, i) => {
          const ch = channels[i];
          if (ch && !ch.mute) el.style.height = (20 + Math.random()*60*(ch.vol/100)) + '%';
          else if (ch) el.style.height = '0%';
        });
      }, 100);

      build(); buildFx(); buildBus();
      vscode.postMessage({ type: 'stateChanged', state: { ready: true } });
    `)}};var Bn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.colorPaletteEditor","Color Palette")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"palette.lua");break}}getHtml(){let e=L();return I(e,"Color Palette",`
      .editor-layout {
        display: grid; grid-template-columns: 240px 1fr 210px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .picker-panel {
        grid-row: 2; overflow-y: auto; border-right: 1px solid var(--border);
        background: var(--surface); padding: 6px;
      }
      .palette-area { grid-row: 2; padding: 10px; overflow-y: auto; background: var(--bg); }
      .harmony-panel {
        grid-row: 2; overflow-y: auto; border-left: 1px solid var(--border);
        background: var(--surface); padding: 6px;
      }
      .color-preview {
        width: 100%; height: 64px; border-radius: var(--radius); border: 1px solid var(--border); margin-bottom: 6px;
      }
      .slider-grp { margin-bottom: 5px; }
      .slider-grp label { display: flex; justify-content: space-between; font-size: 10px; color: var(--text-dim); }
      .slider-grp input[type="range"] { width: 100%; }
      .hex-input { width: 100%; font-family: var(--font-mono, monospace); font-size: 12px; text-align: center; }
      .palette-grid { display: grid; grid-template-columns: repeat(8, 1fr); gap: 3px; }
      .swatch {
        aspect-ratio: 1; border-radius: var(--radius); border: 2px solid transparent;
        cursor: pointer; position: relative; min-height: 32px; transition: border-color 0.1s;
      }
      .swatch:hover { border-color: var(--text); }
      .swatch.sel { border-color: var(--accent); box-shadow: 0 0 0 2px var(--accent); }
      .swatch-num {
        position: absolute; bottom: 1px; left: 0; right: 0; text-align: center;
        font-size: 7px; color: #fff; text-shadow: 0 0 2px #000;
      }
      .harmony-wheel {
        width: 160px; height: 160px; border-radius: 50%; margin: 8px auto;
        background: conic-gradient(red, yellow, lime, cyan, blue, magenta, red);
        position: relative;
      }
      .harmony-dot {
        width: 10px; height: 10px; border-radius: 50%; border: 2px solid #fff;
        position: absolute; transform: translate(-50%,-50%); box-shadow: 0 0 3px rgba(0,0,0,0.5);
      }
      .contrast-pill {
        display: inline-block; padding: 1px 6px; border-radius: var(--radius); font-size: 10px; font-weight: 600;
      }
      .contrast-ok { background: var(--success); color: #fff; }
      .contrast-no { background: var(--error); color: #fff; }
      .harmony-swatches { display: flex; gap: 3px; margin-top: 6px; justify-content: center; }
      .harmony-sw { width: 24px; height: 24px; border-radius: var(--radius); border: 1px solid var(--border); cursor: pointer; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${g(c.add,"btnAdd","Add Color")}
            ${g(c.delete,"btnRem","Remove Color")}
          </div>
          ${k()}
          <div class="group">
            <select id="colorMode" style="font-size:10px">
              <option value="hsl">HSL</option>
              <option value="rgb">RGB</option>
            </select>
          </div>
          ${k()}
          <div class="group">
            <button id="btnSortH" style="font-size:10px;padding:2px 6px">Sort Hue</button>
            <button id="btnSortL" style="font-size:10px;padding:2px 6px">Sort Light</button>
          </div>
          ${A()}
          ${g(c.save,"btnExport","Export Lua")}
        </div>

        <div class="picker-panel">
          ${b("Color Picker",`
            <div class="color-preview" id="colorPreview"></div>
            <input type="text" class="hex-input" id="hexInput" value="#89B4FA">
          `)}
          ${b("Sliders",`
            <div class="slider-grp"><label>H <span id="hVal">217</span></label><input type="range" id="hSlider" min="0" max="360" value="217"></div>
            <div class="slider-grp"><label>S <span id="sVal">92</span></label><input type="range" id="sSlider" min="0" max="100" value="92"></div>
            <div class="slider-grp"><label>L <span id="lVal">76</span></label><input type="range" id="lSlider" min="0" max="100" value="76"></div>
            <div class="slider-grp"><label>A <span id="aVal">255</span></label><input type="range" id="aSlider" min="0" max="255" value="255"></div>
          `)}
          ${b("Accessibility",`
            <div style="font-size:10px">
              <p>On white: <span id="crW" class="contrast-pill">--</span></p>
              <p style="margin-top:3px">On black: <span id="crB" class="contrast-pill">--</span></p>
            </div>
          `)}
        </div>

        <div class="palette-area">
          <div style="font-size:11px;margin-bottom:6px;color:var(--text-dim)">Palette (<span id="pCount">0</span>/64)</div>
          <div class="palette-grid" id="pGrid"></div>
        </div>

        <div class="harmony-panel">
          ${b("Harmony",`
            <select id="harmType" style="width:100%;font-size:10px">
              <option value="complementary">Complementary</option>
              <option value="triadic">Triadic</option>
              <option value="analogous">Analogous</option>
              <option value="split">Split-Complementary</option>
              <option value="tetradic">Tetradic</option>
            </select>
            <div class="harmony-wheel" id="hWheel"></div>
            <div class="harmony-swatches" id="hSwatches"></div>
            <button id="btnApplyH" style="width:100%;margin-top:4px;font-size:10px">Add Harmony Colors</button>
          `)}
        </div>

        <div class="status-bar">
          <span id="stColor" class="badge">#89B4FA</span>
          <div class="sep"></div>
          <span id="stIdx">Idx: \u2014</span>
          <div class="sep"></div>
          <span id="stTotal">0 colors</span>
          <div class="spacer"></div>
          <span id="stDirty" style="font-size:10px;color:var(--text-dim)">${c.clean}</span>
        </div>
      </div>
    `,`
      const undo = new UndoStack();
      let palette = [], selIdx = -1;
      let h = 217, s = 92, l = 76, a = 255;

      function snap() { return JSON.parse(JSON.stringify({ palette, selIdx })); }
      function loadSnap(st) { palette = st.palette; selIdx = st.selIdx; renderPal(); updateColor(); }
      function push() { undo.push(snap()); markDirty(); }
      registerShortcut('ctrl+z', () => { const s2 = undo.undo(); if (s2) loadSnap(s2); });
      registerShortcut('ctrl+shift+z', () => { const s2 = undo.redo(); if (s2) loadSnap(s2); });
      registerShortcut('ctrl+s', () => document.getElementById('btnExport').click());

      function hslHex(h, s, l) {
        const s2 = s/100, l2 = l/100;
        const k = n => (n + h/30)%12;
        const a2 = s2*Math.min(l2, 1-l2);
        const f = n => l2 - a2*Math.max(-1, Math.min(k(n)-3, 9-k(n), 1));
        const x = v => Math.round(v*255).toString(16).padStart(2,'0');
        return '#'+x(f(0))+x(f(8))+x(f(4));
      }
      function hexRgb(hex) {
        const m = hex.match(/^#?([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})$/i);
        return m ? {r:parseInt(m[1],16),g:parseInt(m[2],16),b:parseInt(m[3],16)} : {r:0,g:0,b:0};
      }
      function lum(r,g,b) {
        const [rs,gs,bs] = [r,g,b].map(c => { c/=255; return c<=0.03928?c/12.92:Math.pow((c+0.055)/1.055,2.4); });
        return 0.2126*rs+0.7152*gs+0.0722*bs;
      }
      function cr(l1,l2) { return (Math.max(l1,l2)+0.05)/(Math.min(l1,l2)+0.05); }

      function updateColor() {
        const hex = hslHex(h,s,l);
        document.getElementById('colorPreview').style.background = hex;
        document.getElementById('hexInput').value = hex;
        document.getElementById('hVal').textContent = h;
        document.getElementById('sVal').textContent = s;
        document.getElementById('lVal').textContent = l;
        document.getElementById('aVal').textContent = a;
        document.getElementById('stColor').textContent = hex;
        const rgb = hexRgb(hex), lu = lum(rgb.r,rgb.g,rgb.b);
        const cw = cr(1,lu).toFixed(1), cb = cr(lu,0).toFixed(1);
        const ew = document.getElementById('crW'), eb = document.getElementById('crB');
        ew.textContent = cw+':1'; ew.className = 'contrast-pill '+(cw>=4.5?'contrast-ok':'contrast-no');
        eb.textContent = cb+':1'; eb.className = 'contrast-pill '+(cb>=4.5?'contrast-ok':'contrast-no');
        updateHarm();
        if (selIdx >= 0 && selIdx < palette.length) { palette[selIdx] = {hex,h,s,l,a}; renderPal(); }
      }

      function renderPal() {
        const g = document.getElementById('pGrid'); g.innerHTML = '';
        palette.forEach((c,i) => {
          const el = document.createElement('div');
          el.className = 'swatch'+(i===selIdx?' sel':'');
          el.style.background = c.hex;
          el.innerHTML = '<span class="swatch-num">'+(i+1)+'</span>';
          el.addEventListener('click', () => {
            selIdx = i; h = c.h; s = c.s; l = c.l; a = c.a;
            document.getElementById('hSlider').value = h;
            document.getElementById('sSlider').value = s;
            document.getElementById('lSlider').value = l;
            document.getElementById('aSlider').value = a;
            updateColor(); renderPal();
            document.getElementById('stIdx').textContent = 'Idx: '+i;
          });
          g.appendChild(el);
        });
        document.getElementById('pCount').textContent = palette.length;
        document.getElementById('stTotal').textContent = palette.length+' colors';
      }

      function harmHues(type) {
        switch(type) {
          case 'complementary': return [h,(h+180)%360];
          case 'triadic': return [h,(h+120)%360,(h+240)%360];
          case 'analogous': return [(h-30+360)%360,h,(h+30)%360];
          case 'split': return [h,(h+150)%360,(h+210)%360];
          case 'tetradic': return [h,(h+90)%360,(h+180)%360,(h+270)%360];
          default: return [h];
        }
      }
      function updateHarm() {
        const type = document.getElementById('harmType').value;
        const hues = harmHues(type);
        const wheel = document.getElementById('hWheel'); wheel.innerHTML = '';
        const sw = document.getElementById('hSwatches'); sw.innerHTML = '';
        hues.forEach(hu => {
          const ang = (hu-90)*Math.PI/180, r = 70;
          const dot = document.createElement('div');
          dot.className = 'harmony-dot';
          dot.style.left = (80+r*Math.cos(ang))+'px';
          dot.style.top = (80+r*Math.sin(ang))+'px';
          dot.style.background = hslHex(hu,s,l);
          wheel.appendChild(dot);
          const sc = document.createElement('div');
          sc.className = 'harmony-sw';
          sc.style.background = hslHex(hu,s,l);
          sc.addEventListener('click', () => { if (palette.length<64) { push(); palette.push({hex:hslHex(hu,s,l),h:hu,s,l,a}); renderPal(); }});
          sw.appendChild(sc);
        });
      }

      ['hSlider','sSlider','lSlider','aSlider'].forEach(id => {
        document.getElementById(id).addEventListener('input', e => {
          if (id==='hSlider') h=+e.target.value; if (id==='sSlider') s=+e.target.value;
          if (id==='lSlider') l=+e.target.value; if (id==='aSlider') a=+e.target.value;
          updateColor();
        });
      });
      document.getElementById('hexInput').addEventListener('change', e => {
        const rgb = hexRgb(e.target.value);
        const r2=rgb.r/255,g2=rgb.g/255,b2=rgb.b/255;
        const mx=Math.max(r2,g2,b2),mn=Math.min(r2,g2,b2);
        l=Math.round((mx+mn)/2*100);
        if(mx!==mn){const d=mx-mn;s=Math.round((l>50?d/(2-mx-mn):d/(mx+mn))*100);
        if(mx===r2)h=Math.round(((g2-b2)/d+(g2<b2?6:0))*60);
        else if(mx===g2)h=Math.round(((b2-r2)/d+2)*60);
        else h=Math.round(((r2-g2)/d+4)*60);}else{s=0;h=0;}
        document.getElementById('hSlider').value=h;
        document.getElementById('sSlider').value=s;
        document.getElementById('lSlider').value=l;
        updateColor();
      });

      document.getElementById('btnAdd').addEventListener('click', () => {
        if (palette.length<64) { push(); palette.push({hex:hslHex(h,s,l),h,s,l,a}); selIdx=palette.length-1; renderPal(); }
      });
      document.getElementById('btnRem').addEventListener('click', () => {
        if (selIdx>=0) { push(); palette.splice(selIdx,1); selIdx=Math.min(selIdx,palette.length-1); renderPal(); }
      });
      document.getElementById('btnSortH').addEventListener('click', () => { push(); palette.sort((a,b)=>a.h-b.h); renderPal(); });
      document.getElementById('btnSortL').addEventListener('click', () => { push(); palette.sort((a,b)=>a.l-b.l); renderPal(); });
      document.getElementById('harmType').addEventListener('change', updateHarm);
      document.getElementById('btnApplyH').addEventListener('click', () => {
        const hues = harmHues(document.getElementById('harmType').value);
        push(); hues.forEach(hu => { if (palette.length<64) palette.push({hex:hslHex(hu,s,l),h:hu,s,l,a}); }); renderPal();
      });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        palette.forEach(c => { const rgb=hexRgb(c.hex); lua+='  { r = '+rgb.r+', g = '+rgb.g+', b = '+rgb.b+', a = '+c.a+' }, -- '+c.hex+'\\n'; });
        lua += '}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      updateColor(); renderPal();
      vscode.postMessage({ type: 'stateChanged', state: { ready: true } });
    `)}};var Fn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.inputMapperEditor","Input Mapper")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"input_map.lua");break}}getHtml(){let e=L();return I(e,"Input Mapper",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 210px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .mapping-area { grid-row: 2; overflow-y: auto; padding: 8px; background: var(--bg); }
      .config-panel { grid-row: 2; overflow-y: auto; border-left: 1px solid var(--border); background: var(--surface); padding: 6px; }
      .action-table { width: 100%; border-collapse: collapse; font-size: 11px; }
      .action-table th {
        text-align: left; padding: 4px 6px; background: var(--surface);
        border-bottom: 2px solid var(--border); font-size: 9px; text-transform: uppercase;
        color: var(--text-dim); position: sticky; top: 0; letter-spacing: 0.3px;
      }
      .action-table td { padding: 3px 6px; border-bottom: 1px solid var(--border); vertical-align: middle; }
      .action-table tr:hover { background: var(--hover); }
      .action-table tr.sel { background: var(--selection); }
      .binding-cell { display: flex; flex-wrap: wrap; gap: 2px; }
      .key-badge {
        background: var(--surface-2); border: 1px solid var(--border); padding: 1px 6px;
        border-radius: var(--radius); font-family: var(--font-mono, monospace); font-size: 10px;
        cursor: pointer; display: inline-flex; align-items: center; gap: 3px; transition: border-color 0.1s;
      }
      .key-badge:hover { border-color: var(--accent); }
      .key-badge .rm { font-size: 8px; opacity: 0.4; cursor: pointer; }
      .key-badge .rm:hover { opacity: 1; color: var(--error); }
      .key-badge.conflict { border-color: var(--error); background: rgba(244,67,54,0.12); }
      .add-bind {
        background: transparent; border: 1px dashed var(--border); padding: 1px 6px;
        border-radius: var(--radius); font-size: 10px; cursor: pointer; color: var(--text-dim);
      }
      .add-bind:hover { border-color: var(--accent); color: var(--accent); }
      .listen-overlay {
        position: fixed; inset: 0; background: rgba(0,0,0,0.7); display: flex;
        align-items: center; justify-content: center; z-index: 100;
      }
      .listen-box {
        background: var(--surface); padding: 20px 36px; border-radius: var(--radius);
        border: 2px solid var(--accent); text-align: center;
      }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${g(c.add,"btnAdd","Add Action")}
            ${g(c.delete,"btnRem","Remove Action")}
          </div>
          ${k()}
          <div class="group">
            <button id="btnConflicts" style="font-size:10px;padding:2px 8px">Check Conflicts</button>
          </div>
          ${A()}
          ${g(c.save,"btnExport","Export Lua")}
        </div>

        <div class="mapping-area">
          <table class="action-table">
            <thead><tr>
              <th style="width:120px">Action</th>
              <th style="width:160px">Description</th>
              <th>Keyboard</th>
              <th>Gamepad</th>
            </tr></thead>
            <tbody id="actBody"></tbody>
          </table>
        </div>

        <div class="config-panel">
          ${b("Selected Action",`
            ${N("Name",'<input type="text" id="actName" style="width:100%">')}
            ${N("Desc",'<input type="text" id="actDesc" style="width:100%">')}
          `)}
          ${b("Analog",`
            ${N("Dead Zone",'<input type="range" id="deadzone" min="0" max="50" value="15" style="flex:1"><span id="dzVal" style="font-size:9px;min-width:28px">0.15</span>')}
            ${N("Sensitivity",'<input type="range" id="sens" min="1" max="30" value="10" style="flex:1"><span id="sensVal" style="font-size:9px;min-width:28px">1.0</span>')}
          `)}
          ${b("Presets",`
            <button id="prePlatformer" style="width:100%;margin-bottom:3px;font-size:10px">Platformer</button>
            <button id="preRPG" style="width:100%;margin-bottom:3px;font-size:10px">RPG</button>
            <button id="preShooter" style="width:100%;font-size:10px">Top-Down Shooter</button>
          `)}
        </div>

        <div class="status-bar">
          <span id="stAct" class="badge">5 actions</span>
          <div class="sep"></div>
          <span id="stConf">0 conflicts</span>
          <div class="spacer"></div>
          <span id="stDirty" style="font-size:10px;color:var(--text-dim)">${c.clean}</span>
        </div>
      </div>
      <div class="listen-overlay" id="listenOverlay" style="display:none;">
        <div class="listen-box">
          <p style="font-size:14px;margin-bottom:6px">Press a key\u2026</p>
          <p style="font-size:10px;color:var(--text-dim)">Escape to cancel</p>
        </div>
      </div>
    `,`
      const undo = new UndoStack();
      let actions = [
        { name:'move_left', desc:'Move left', keys:['a','left'], gamepad:['dpad_left','lstick_left'], dz:0.15, sens:1.0 },
        { name:'move_right', desc:'Move right', keys:['d','right'], gamepad:['dpad_right','lstick_right'], dz:0.15, sens:1.0 },
        { name:'jump', desc:'Jump', keys:['space','w'], gamepad:['a'], dz:0.15, sens:1.0 },
        { name:'attack', desc:'Primary attack', keys:['j','enter'], gamepad:['x'], dz:0.15, sens:1.0 },
        { name:'interact', desc:'Interact / Talk', keys:['e'], gamepad:['b'], dz:0.15, sens:1.0 },
      ];
      let selAct = 0, listenTarget = null;

      function snap() { return JSON.parse(JSON.stringify(actions)); }
      function load(s) { actions = s; build(); updateProps(); }
      function push() { undo.push(snap()); markDirty(); }
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) load(s); });
      registerShortcut('ctrl+shift+z', () => { const s = undo.redo(); if (s) load(s); });
      registerShortcut('ctrl+s', () => document.getElementById('btnExport').click());

      function findConflicts() {
        const c = [];
        for (let i = 0; i < actions.length; i++)
          for (let j = i+1; j < actions.length; j++) {
            for (const k of actions[i].keys) if (actions[j].keys.includes(k)) c.push({a:i,b:j,key:k,type:'keys'});
            for (const g of actions[i].gamepad) if (actions[j].gamepad.includes(g)) c.push({a:i,b:j,key:g,type:'gamepad'});
          }
        return c;
      }

      function build() {
        const body = document.getElementById('actBody'); body.innerHTML = '';
        const conflicts = findConflicts();
        actions.forEach((act, i) => {
          const tr = document.createElement('tr');
          tr.className = i === selAct ? 'sel' : '';
          tr.addEventListener('click', () => { selAct = i; build(); updateProps(); });

          const tdN = document.createElement('td');
          tdN.textContent = act.name; tdN.style.fontFamily = 'var(--font-mono, monospace)';
          const tdD = document.createElement('td');
          tdD.textContent = act.desc; tdD.style.color = 'var(--text-dim)';

          function bindCell(arr, type) {
            const td = document.createElement('td');
            const d = document.createElement('div'); d.className = 'binding-cell';
            arr.forEach((k, ki) => {
              const b = document.createElement('span');
              b.className = 'key-badge' + (conflicts.some(c => c.key===k && c.type===type && (c.a===i||c.b===i)) ? ' conflict' : '');
              b.innerHTML = k + ' <span class="rm">\\u00d7</span>';
              b.querySelector('.rm').addEventListener('click', e => { e.stopPropagation(); push(); arr.splice(ki,1); build(); });
              d.appendChild(b);
            });
            const ab = document.createElement('button'); ab.className = 'add-bind'; ab.textContent = '+';
            ab.addEventListener('click', e => { e.stopPropagation(); listenTarget = {action:i, type}; document.getElementById('listenOverlay').style.display = 'flex'; });
            d.appendChild(ab);
            td.appendChild(d); return td;
          }

          tr.appendChild(tdN); tr.appendChild(tdD);
          tr.appendChild(bindCell(act.keys, 'keys'));
          tr.appendChild(bindCell(act.gamepad, 'gamepad'));
          body.appendChild(tr);
        });
        document.getElementById('stAct').textContent = actions.length + ' actions';
        document.getElementById('stConf').textContent = conflicts.length + ' conflicts';
        if (conflicts.length > 0) document.getElementById('stConf').style.color = 'var(--error)';
        else document.getElementById('stConf').style.color = '';
      }

      function updateProps() {
        const a = actions[selAct]; if (!a) return;
        document.getElementById('actName').value = a.name;
        document.getElementById('actDesc').value = a.desc;
        document.getElementById('deadzone').value = Math.round(a.dz*100);
        document.getElementById('dzVal').textContent = a.dz.toFixed(2);
        document.getElementById('sens').value = Math.round(a.sens*10);
        document.getElementById('sensVal').textContent = a.sens.toFixed(1);
      }

      document.addEventListener('keydown', e => {
        if (!listenTarget) return;
        e.preventDefault();
        if (e.key === 'Escape') { listenTarget = null; document.getElementById('listenOverlay').style.display = 'none'; return; }
        push();
        const key = e.key.toLowerCase(), a = actions[listenTarget.action];
        if (listenTarget.type === 'keys' && !a.keys.includes(key)) a.keys.push(key);
        listenTarget = null; document.getElementById('listenOverlay').style.display = 'none';
        build();
      });

      document.getElementById('actName').addEventListener('change', e => { if (actions[selAct]) { push(); actions[selAct].name = e.target.value; build(); } });
      document.getElementById('actDesc').addEventListener('change', e => { if (actions[selAct]) { push(); actions[selAct].desc = e.target.value; } });
      document.getElementById('deadzone').addEventListener('input', e => {
        const v = +e.target.value/100; document.getElementById('dzVal').textContent = v.toFixed(2);
        if (actions[selAct]) actions[selAct].dz = v;
      });
      document.getElementById('sens').addEventListener('input', e => {
        const v = +e.target.value/10; document.getElementById('sensVal').textContent = v.toFixed(1);
        if (actions[selAct]) actions[selAct].sens = v;
      });

      document.getElementById('btnAdd').addEventListener('click', () => {
        push(); actions.push({name:'new_action',desc:'',keys:[],gamepad:[],dz:0.15,sens:1.0});
        selAct = actions.length-1; build(); updateProps();
      });
      document.getElementById('btnRem').addEventListener('click', () => {
        if (actions.length > 0) { push(); actions.splice(selAct,1); selAct = Math.min(selAct, actions.length-1); build(); updateProps(); }
      });
      document.getElementById('btnConflicts').addEventListener('click', build);

      function loadPreset(p) {
        const presets = {
          Platformer: [
            {name:'move_left',desc:'Move left',keys:['a','left'],gamepad:['dpad_left','lstick_left'],dz:0.15,sens:1},
            {name:'move_right',desc:'Move right',keys:['d','right'],gamepad:['dpad_right','lstick_right'],dz:0.15,sens:1},
            {name:'jump',desc:'Jump',keys:['space','w','up'],gamepad:['a'],dz:0.15,sens:1},
            {name:'attack',desc:'Attack',keys:['j'],gamepad:['x'],dz:0.15,sens:1},
            {name:'dash',desc:'Dash',keys:['shift'],gamepad:['lb'],dz:0.15,sens:1},
          ],
          RPG: [
            {name:'move_up',desc:'Move up',keys:['w','up'],gamepad:['dpad_up','lstick_up'],dz:0.2,sens:1},
            {name:'move_down',desc:'Move down',keys:['s','down'],gamepad:['dpad_down','lstick_down'],dz:0.2,sens:1},
            {name:'move_left',desc:'Move left',keys:['a','left'],gamepad:['dpad_left','lstick_left'],dz:0.2,sens:1},
            {name:'move_right',desc:'Move right',keys:['d','right'],gamepad:['dpad_right','lstick_right'],dz:0.2,sens:1},
            {name:'interact',desc:'Talk / Interact',keys:['e','enter'],gamepad:['a'],dz:0.15,sens:1},
            {name:'menu',desc:'Open menu',keys:['escape','tab'],gamepad:['start'],dz:0.15,sens:1},
          ],
          Shooter: [
            {name:'move_up',desc:'Move up',keys:['w'],gamepad:['lstick_up'],dz:0.1,sens:1.5},
            {name:'move_down',desc:'Move down',keys:['s'],gamepad:['lstick_down'],dz:0.1,sens:1.5},
            {name:'move_left',desc:'Move left',keys:['a'],gamepad:['lstick_left'],dz:0.1,sens:1.5},
            {name:'move_right',desc:'Move right',keys:['d'],gamepad:['lstick_right'],dz:0.1,sens:1.5},
            {name:'shoot',desc:'Fire weapon',keys:['space'],gamepad:['rt'],dz:0.05,sens:1},
            {name:'reload',desc:'Reload',keys:['r'],gamepad:['x'],dz:0.15,sens:1},
          ],
        };
        push(); actions = presets[p] || actions; selAct = 0; build(); updateProps();
      }
      document.getElementById('prePlatformer').addEventListener('click', () => loadPreset('Platformer'));
      document.getElementById('preRPG').addEventListener('click', () => loadPreset('RPG'));
      document.getElementById('preShooter').addEventListener('click', () => loadPreset('Shooter'));

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        actions.forEach(a => {
          lua += '  '+a.name+' = {\\n    description = "'+a.desc+'",\\n';
          lua += '    keys = {'+a.keys.map(k=>'"'+k+'"').join(', ')+'},\\n';
          lua += '    gamepad = {'+a.gamepad.map(g=>'"'+g+'"').join(', ')+'},\\n';
          lua += '    deadzone = '+a.dz+', sensitivity = '+a.sens+',\\n  },\\n';
        });
        lua += '}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      build(); updateProps();
      vscode.postMessage({ type: 'stateChanged', state: { ready: true } });
    `)}};var zn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.timelineEditor","Timeline")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"timeline.lua");break}}getHtml(){let e=L();return I(e,"Timeline",`
      .editor-layout {
        display: grid; grid-template-columns: 140px 1fr 200px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .track-list { grid-row: 2; border-right: 1px solid var(--border); overflow-y: auto; background: var(--surface); }
      .timeline-area { grid-row: 2; overflow: auto; position: relative; background: var(--bg); }
      .props-panel { grid-row: 2; overflow-y: auto; border-left: 1px solid var(--border); background: var(--surface); padding: 6px; }
      .track-header {
        display: flex; align-items: center; gap: 4px; padding: 3px 6px;
        border-bottom: 1px solid var(--border); height: 32px; cursor: pointer; font-size: 11px;
        transition: background 0.08s;
      }
      .track-header:hover { background: var(--hover); }
      .track-header.sel { background: var(--selection); }
      .track-icon { font-size: 13px; }
      .track-name { flex: 1; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
      .track-mute { opacity: 0.4; cursor: pointer; font-size: 9px; font-weight: 700; }
      .track-mute.muted { opacity: 1; color: var(--error); }
      .timeline-ruler {
        height: 22px; background: var(--surface); border-bottom: 1px solid var(--border);
        position: sticky; top: 0; z-index: 5;
      }
      .timeline-tracks { position: relative; }
      .timeline-row { height: 32px; border-bottom: 1px solid var(--border); position: relative; }
      .keyframe {
        position: absolute; width: 9px; height: 9px; background: var(--accent);
        transform: rotate(45deg) translate(-50%, -50%); top: 12px; cursor: pointer; z-index: 2;
        transition: background 0.08s;
      }
      .keyframe:hover { background: var(--accent-2); }
      .keyframe.sel { background: var(--warning); box-shadow: 0 0 4px var(--warning); }
      .segment {
        position: absolute; height: 18px; top: 7px; background: rgba(137,180,250,0.2);
        border: 1px solid var(--accent); border-radius: var(--radius); cursor: move; z-index: 1;
        font-size: 8px; color: var(--text-dim); padding: 1px 4px; overflow: hidden;
      }
      .playhead {
        position: absolute; top: 0; bottom: 0; width: 2px; background: var(--error);
        z-index: 10; pointer-events: none;
      }
      .playhead-handle {
        position: absolute; top: 0; width: 10px; height: 10px; background: var(--error);
        left: -4px; cursor: pointer; pointer-events: auto; clip-path: polygon(0 0, 100% 0, 50% 100%);
      }
      .easing-preview { width: 100%; height: 50px; background: var(--bg); border: 1px solid var(--border); border-radius: var(--radius); }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${g(c.add,"btnAddTrack","Add Track")}
            <select id="trackType" style="font-size:10px">
              <option value="dialog">Dialog</option>
              <option value="camera">Camera</option>
              <option value="audio">Audio</option>
              <option value="effects">Effects</option>
              <option value="custom">Custom</option>
            </select>
          </div>
          ${k()}
          <div class="group">
            ${g(c.play,"btnPlay","Play")}
            ${g(c.pause,"btnStop","Stop")}
            <span id="timeDisplay" style="font-family:var(--font-mono,monospace);font-size:11px;min-width:70px;">00:00.000</span>
          </div>
          ${k()}
          <div class="group">
            <label style="font-size:10px">Dur:</label><input type="number" id="duration" value="10" min="1" max="300" style="width:40px">
            <label style="font-size:10px;margin-left:4px">Snap:</label>
            <select id="snapGrid" style="font-size:10px">
              <option value="0">Off</option>
              <option value="0.1">0.1s</option>
              <option value="0.25" selected>0.25s</option>
              <option value="0.5">0.5s</option>
              <option value="1">1s</option>
            </select>
          </div>
          ${k()}
          <div class="group">
            <button id="btnAddKeyframe" style="font-size:10px;padding:2px 6px">+ KF</button>
            <button id="btnDeleteKeyframe" style="font-size:10px;padding:2px 6px;color:var(--error)">\xD7 KF</button>
          </div>
          ${A()}
          ${g(c.save,"btnExport","Export Lua")}
        </div>

        <div class="track-list" id="trackList"></div>

        <div class="timeline-area" id="timelineArea">
          <canvas class="timeline-ruler" id="ruler"></canvas>
          <div class="timeline-tracks" id="timelineTracks">
            <div class="playhead" id="playhead">
              <div class="playhead-handle"></div>
            </div>
          </div>
        </div>

        <div class="props-panel">
          ${b("Keyframe",`
            ${N("Time (s)",'<input type="number" id="kfTime" step="0.01" min="0">')}
            ${N("Value",'<input type="text" id="kfValue">')}
            ${N("Easing",`<select id="kfEasing" style="flex:1">
              <option value="linear">Linear</option>
              <option value="easeIn">Ease In</option>
              <option value="easeOut">Ease Out</option>
              <option value="easeInOut">Ease In-Out</option>
              <option value="bounce">Bounce</option>
              <option value="elastic">Elastic</option>
            </select>`)}
            <canvas class="easing-preview" id="easingPreview"></canvas>
          `)}
          ${b("Segment",`
            ${N("Label",'<input type="text" id="segLabel">')}
            <div style="display:flex;gap:4px">
              ${N("Start",'<input type="number" id="segStart" step="0.1" style="width:56px">')}
              ${N("End",'<input type="number" id="segEnd" step="0.1" style="width:56px">')}
            </div>
          `)}
        </div>

        <div class="status-bar">
          <span id="statusTracks" class="badge">3 tracks</span>
          <div class="sep"></div>
          <span id="statusKeyframes">5 kf</span>
          <div class="sep"></div>
          <span id="statusDuration">10s</span>
          <div class="spacer"></div>
          <span id="statusDirty" style="font-size:10px;color:var(--text-dim)">${c.clean}</span>
        </div>
      </div>
    `,`
      const TRACK_ICONS = { dialog: '\\u{1F4AC}', camera: '\\u{1F3A5}', audio: '\\u{1F50A}', effects: '\\u2728', custom: '\\u{1F527}' };
      const undo = new UndoStack();
      let tracks = [
        { name: 'Dialog', type: 'dialog', muted: false, keyframes: [{t:0,val:'Hello',easing:'linear'},{t:2,val:'World',easing:'linear'}], segments: [{start:0,end:2,label:'Intro text'}] },
        { name: 'Camera', type: 'camera', muted: false, keyframes: [{t:0,val:'0,0',easing:'linear'},{t:3,val:'100,50',easing:'easeInOut'}], segments: [{start:0,end:3,label:'Pan right'}] },
        { name: 'Music', type: 'audio', muted: false, keyframes: [{t:0,val:'bgm.ogg',easing:'linear'}], segments: [{start:0,end:10,label:'Background music'}] },
      ];
      let selTrack = 0, selKF = -1, duration = 10, playTime = 0, playing = false, playTimer = null;
      const PX = 80;

      function snap() { return JSON.parse(JSON.stringify({ tracks, duration })); }
      function load(s) { tracks = s.tracks; duration = s.duration; build(); }
      function push() { undo.push(snap()); markDirty(); }
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) load(s); });
      registerShortcut('ctrl+shift+z', () => { const s = undo.redo(); if (s) load(s); });
      registerShortcut('ctrl+s', () => document.getElementById('btnExport').click());
      registerShortcut('space', () => { if (playing) document.getElementById('btnStop').click(); else document.getElementById('btnPlay').click(); });

      function build() {
        const list = document.getElementById('trackList'); list.innerHTML = '';
        tracks.forEach((tr, i) => {
          const el = document.createElement('div');
          el.className = 'track-header' + (i === selTrack ? ' sel' : '');
          el.innerHTML = '<span class="track-icon">' + (TRACK_ICONS[tr.type] || '?') + '</span>' +
            '<span class="track-name">' + tr.name + '</span>' +
            '<span class="track-mute' + (tr.muted ? ' muted' : '') + '" data-t="' + i + '">M</span>';
          el.addEventListener('click', () => { selTrack = i; selKF = -1; build(); });
          el.querySelector('.track-mute').addEventListener('click', e => { e.stopPropagation(); push(); tr.muted = !tr.muted; build(); });
          list.appendChild(el);
        });

        const container = document.getElementById('timelineTracks');
        container.querySelectorAll('.timeline-row').forEach(r => r.remove());
        let totalKF = 0;
        tracks.forEach((tr, ti) => {
          const row = document.createElement('div');
          row.className = 'timeline-row';
          row.style.width = (duration * PX) + 'px';
          tr.segments.forEach(seg => {
            const el = document.createElement('div');
            el.className = 'segment';
            el.style.left = (seg.start * PX) + 'px';
            el.style.width = ((seg.end - seg.start) * PX) + 'px';
            el.textContent = seg.label;
            row.appendChild(el);
          });
          tr.keyframes.forEach((kf, ki) => {
            const el = document.createElement('div');
            el.className = 'keyframe' + (ti === selTrack && ki === selKF ? ' sel' : '');
            el.style.left = (kf.t * PX) + 'px';
            el.addEventListener('click', e => { e.stopPropagation(); selTrack = ti; selKF = ki; updateKFProps(); build(); });
            row.appendChild(el);
            totalKF++;
          });
          container.appendChild(row);
        });

        document.getElementById('playhead').style.left = (playTime * PX) + 'px';
        drawRuler();
        document.getElementById('statusTracks').textContent = tracks.length + ' tracks';
        document.getElementById('statusKeyframes').textContent = totalKF + ' kf';
        document.getElementById('statusDuration').textContent = duration + 's';
      }

      function drawRuler() {
        const canvas = document.getElementById('ruler');
        canvas.width = duration * PX;
        canvas.height = 22;
        const ctx = canvas.getContext('2d');
        ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--surface').trim() || '#252526';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--text-dim').trim() || '#858585';
        ctx.font = '9px monospace';
        for (let t = 0; t <= duration; t += 0.5) {
          const x = t * PX;
          ctx.beginPath(); ctx.moveTo(x, t % 1 === 0 ? 8 : 16); ctx.lineTo(x, 22);
          ctx.strokeStyle = getComputedStyle(document.documentElement).getPropertyValue('--border').trim() || '#3c3c3c'; ctx.stroke();
          if (t % 1 === 0) ctx.fillText(t + 's', x + 2, 14);
        }
      }

      function updateKFProps() {
        const tr = tracks[selTrack];
        if (!tr || selKF < 0 || selKF >= tr.keyframes.length) return;
        const kf = tr.keyframes[selKF];
        document.getElementById('kfTime').value = kf.t;
        document.getElementById('kfValue').value = kf.val;
        document.getElementById('kfEasing').value = kf.easing || 'linear';
        drawEasingPreview(kf.easing || 'linear');
      }

      function drawEasingPreview(type) {
        const canvas = document.getElementById('easingPreview');
        const ctx = canvas.getContext('2d');
        canvas.width = canvas.clientWidth;
        canvas.height = 50;
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.strokeStyle = getComputedStyle(document.documentElement).getPropertyValue('--border').trim() || '#3c3c3c';
        ctx.strokeRect(0, 0, canvas.width, canvas.height);
        ctx.beginPath();
        ctx.strokeStyle = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim() || '#89b4fa';
        ctx.lineWidth = 2;
        for (let i = 0; i <= canvas.width; i++) {
          const t = i / canvas.width;
          let v;
          switch (type) {
            case 'easeIn': v = t * t; break;
            case 'easeOut': v = 1 - (1-t)*(1-t); break;
            case 'easeInOut': v = t < 0.5 ? 2*t*t : 1-Math.pow(-2*t+2,2)/2; break;
            case 'bounce': { const n=7.5625,d=2.75; let t2=1-t; v=1-(t2<1/d?n*t2*t2:t2<2/d?n*(t2-=1.5/d)*t2+.75:t2<2.5/d?n*(t2-=2.25/d)*t2+.9375:n*(t2-=2.625/d)*t2+.984375); break; }
            case 'elastic': v = t===0?0:t===1?1:Math.pow(2,-10*t)*Math.sin((t*10-0.75)*(2*Math.PI)/3)+1; break;
            default: v = t;
          }
          const y = canvas.height - v * (canvas.height - 4) - 2;
          if (i === 0) ctx.moveTo(i, y); else ctx.lineTo(i, y);
        }
        ctx.stroke();
      }

      document.getElementById('kfTime').addEventListener('change', e => {
        const tr = tracks[selTrack];
        if (tr && selKF >= 0) { push(); tr.keyframes[selKF].t = parseFloat(e.target.value); build(); }
      });
      document.getElementById('kfValue').addEventListener('change', e => {
        const tr = tracks[selTrack];
        if (tr && selKF >= 0) { push(); tr.keyframes[selKF].val = e.target.value; }
      });
      document.getElementById('kfEasing').addEventListener('change', e => {
        const tr = tracks[selTrack];
        if (tr && selKF >= 0) { push(); tr.keyframes[selKF].easing = e.target.value; }
        drawEasingPreview(e.target.value);
      });

      document.getElementById('btnAddTrack').addEventListener('click', () => {
        push();
        const type = document.getElementById('trackType').value;
        tracks.push({ name: type.charAt(0).toUpperCase() + type.slice(1) + ' ' + tracks.length, type, muted: false, keyframes: [], segments: [] });
        build();
      });

      document.getElementById('btnAddKeyframe').addEventListener('click', () => {
        const tr = tracks[selTrack];
        if (tr) { push(); tr.keyframes.push({ t: playTime, val: '', easing: 'linear' }); selKF = tr.keyframes.length - 1; build(); updateKFProps(); }
      });
      document.getElementById('btnDeleteKeyframe').addEventListener('click', () => {
        const tr = tracks[selTrack];
        if (tr && selKF >= 0) { push(); tr.keyframes.splice(selKF, 1); selKF = -1; build(); }
      });

      document.getElementById('btnPlay').addEventListener('click', () => {
        if (playing) return;
        playing = true;
        playTimer = setInterval(() => {
          playTime += 0.05;
          if (playTime >= duration) playTime = 0;
          document.getElementById('playhead').style.left = (playTime * PX) + 'px';
          const m = Math.floor(playTime / 60), s = Math.floor(playTime % 60), ms = Math.floor((playTime % 1) * 1000);
          document.getElementById('timeDisplay').textContent = String(m).padStart(2,'0') + ':' + String(s).padStart(2,'0') + '.' + String(ms).padStart(3,'0');
        }, 50);
      });
      document.getElementById('btnStop').addEventListener('click', () => {
        playing = false; clearInterval(playTimer);
        playTime = 0; document.getElementById('playhead').style.left = '0px';
        document.getElementById('timeDisplay').textContent = '00:00.000';
      });

      document.getElementById('duration').addEventListener('change', e => { duration = parseInt(e.target.value); build(); });

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  duration = ' + duration + ',\\n  tracks = {\\n';
        tracks.forEach(tr => {
          lua += '    { name = "' + tr.name + '", type = "' + tr.type + '",\\n';
          lua += '      keyframes = {\\n';
          tr.keyframes.forEach(kf => { lua += '        { t = ' + kf.t + ', value = "' + kf.val + '", easing = "' + (kf.easing||'linear') + '" },\\n'; });
          lua += '      },\\n      segments = {\\n';
          tr.segments.forEach(seg => { lua += '        { start = ' + seg.start + ', stop = ' + seg.end + ', label = "' + seg.label + '" },\\n'; });
          lua += '      },\\n    },\\n';
        });
        lua += '  }\\n}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      build(); drawEasingPreview('linear');
      vscode.postMessage({ type: 'stateChanged', state: { ready: true } });
    `)}};var Nn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.shaderPreviewEditor","Shader Preview")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"shader.lua");break}}getHtml(){let e=L();return I(e,"Shader Preview",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 1fr;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .code-area { grid-row: 2; display: flex; flex-direction: column; border-right: 1px solid var(--border); overflow: hidden; }
      .preview-area { grid-row: 2; display: flex; flex-direction: column; overflow: hidden; }
      .code-editor {
        flex: 1; background: var(--bg); color: var(--text); font-family: var(--font-mono, 'Consolas', monospace);
        font-size: 12px; line-height: 1.5; padding: 8px; border: none; resize: none;
        tab-size: 2; white-space: pre; overflow: auto;
      }
      .code-editor:focus { outline: 1px solid var(--accent); }
      .preview-canvas-wrapper { flex: 1; display: flex; align-items: center; justify-content: center; background: var(--bg); }
      .params-bar {
        padding: 6px; background: var(--surface); border-top: 1px solid var(--border);
        display: flex; flex-wrap: wrap; gap: 6px; align-items: center;
      }
      .param-item { display: flex; align-items: center; gap: 4px; font-size: 10px; }
      .param-item input[type="range"] { width: 72px; }
      .error-bar {
        padding: 4px 8px; background: rgba(243,139,168,0.15); color: var(--error);
        font-family: var(--font-mono, monospace); font-size: 10px; white-space: pre-wrap; max-height: 50px; overflow-y: auto;
      }
      .preset-btn {
        font-size: 10px; padding: 2px 7px; background: var(--surface-2); color: var(--text);
        border: 1px solid var(--border); border-radius: var(--radius); cursor: pointer;
      }
      .preset-btn:hover { background: var(--hover); }
      .preset-btn.sel { background: var(--accent); color: var(--bg); }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            <label style="font-size:10px">Preset:</label>
            <button class="preset-btn sel" data-preset="blur">Blur</button>
            <button class="preset-btn" data-preset="glow">Glow</button>
            <button class="preset-btn" data-preset="dissolve">Dissolve</button>
            <button class="preset-btn" data-preset="pixel">Pixelate</button>
            <button class="preset-btn" data-preset="wave">Wave</button>
            <button class="preset-btn" data-preset="custom">Custom</button>
          </div>
          ${k()}
          <div class="group">
            ${g(c.play,"btnRun","Run")}
            ${g(c.pause,"btnPause","Pause")}
          </div>
          ${A()}
          ${g(c.save,"btnExport","Export Lua")}
        </div>

        <div class="code-area">
          <textarea class="code-editor" id="codeEditor" spellcheck="false"></textarea>
          <div class="error-bar" id="errorBar" style="display:none;"></div>
        </div>

        <div class="preview-area">
          <div class="preview-canvas-wrapper">
            <canvas id="previewCanvas" width="400" height="300"></canvas>
          </div>
          <div class="params-bar" id="paramsBar"></div>
        </div>

        <div class="status-bar">
          <span id="statusPreset" class="badge">blur</span>
          <div class="sep"></div>
          <span id="perfFps" style="font-family:var(--font-mono,monospace)">FPS: --</span>
          <div class="sep"></div>
          <span id="perfTime" style="font-family:var(--font-mono,monospace)">Frame: -- ms</span>
          <div class="spacer"></div>
          <span id="statusDirty" style="font-size:10px;color:var(--text-dim)">${c.clean}</span>
        </div>
      </div>
    `,`
      const canvas = document.getElementById('previewCanvas');
      const ctx = canvas.getContext('2d');
      const editor = document.getElementById('codeEditor');
      const undo = new UndoStack();
      let running = true, frameCount = 0, lastFpsTime = performance.now(), currentPreset = 'blur';

      const PRESETS = {
        blur: {
          code: '-- Gaussian Blur Shader\\n-- Uniforms: radius, intensity\\n\\nfunction effect(pixel, x, y, uniforms)\\n  local r = uniforms.radius or 3\\n  local sum_r, sum_g, sum_b = 0, 0, 0\\n  local count = 0\\n  for dy = -r, r do\\n    for dx = -r, r do\\n      local p = getPixel(x + dx, y + dy)\\n      sum_r = sum_r + p.r\\n      sum_g = sum_g + p.g\\n      sum_b = sum_b + p.b\\n      count = count + 1\\n    end\\n  end\\n  return {\\n    r = sum_r / count,\\n    g = sum_g / count,\\n    b = sum_b / count,\\n    a = pixel.a\\n  }\\nend',
          params: [{ name: 'radius', min: 1, max: 20, value: 3 }, { name: 'intensity', min: 0, max: 100, value: 50 }],
        },
        glow: {
          code: '-- Glow Shader\\n-- Uniforms: threshold, strength\\n\\nfunction effect(pixel, x, y, uniforms)\\n  local lum = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114\\n  local t = uniforms.threshold or 0.5\\n  local s = (uniforms.strength or 50) / 100\\n  if lum > t then\\n    return {\\n      r = math.min(1, pixel.r + pixel.r * s),\\n      g = math.min(1, pixel.g + pixel.g * s),\\n      b = math.min(1, pixel.b + pixel.b * s),\\n      a = pixel.a\\n    }\\n  end\\n  return pixel\\nend',
          params: [{ name: 'threshold', min: 0, max: 100, value: 50 }, { name: 'strength', min: 0, max: 100, value: 50 }],
        },
        dissolve: {
          code: '-- Dissolve Shader\\n-- Uniforms: progress, edge_width\\n\\nfunction effect(pixel, x, y, uniforms)\\n  local noise = math.sin(x * 12.9898 + y * 78.233) * 43758.5453\\n  noise = noise - math.floor(noise)\\n  local p = (uniforms.progress or 50) / 100\\n  if noise < p then\\n    return { r = 0, g = 0, b = 0, a = 0 }\\n  end\\n  local edge = (uniforms.edge_width or 10) / 100\\n  if noise < p + edge then\\n    return { r = 1, g = 0.5, b = 0, a = pixel.a }\\n  end\\n  return pixel\\nend',
          params: [{ name: 'progress', min: 0, max: 100, value: 30 }, { name: 'edge_width', min: 0, max: 50, value: 10 }],
        },
        pixel: {
          code: '-- Pixelate Shader\\n-- Uniforms: size\\n\\nfunction effect(pixel, x, y, uniforms)\\n  local s = math.max(1, uniforms.size or 8)\\n  local bx = math.floor(x / s) * s + s / 2\\n  local by = math.floor(y / s) * s + s / 2\\n  return getPixel(bx, by)\\nend',
          params: [{ name: 'size', min: 1, max: 32, value: 8 }],
        },
        wave: {
          code: '-- Wave Distortion Shader\\n-- Uniforms: amplitude, frequency, speed\\n\\nfunction effect(pixel, x, y, uniforms)\\n  local amp = (uniforms.amplitude or 10)\\n  local freq = (uniforms.frequency or 20) / 100\\n  local t = lurek.timer.getTime()\\n  local offset = math.sin(y * freq + t) * amp\\n  return getPixel(x + offset, y)\\nend',
          params: [{ name: 'amplitude', min: 0, max: 50, value: 10 }, { name: 'frequency', min: 1, max: 100, value: 20 }, { name: 'speed', min: 1, max: 100, value: 50 }],
        },
        custom: {
          code: '-- Custom Shader\\n-- Write your own pixel effect here\\n\\nfunction effect(pixel, x, y, uniforms)\\n  return pixel\\nend',
          params: [{ name: 'param1', min: 0, max: 100, value: 50 }, { name: 'param2', min: 0, max: 100, value: 50 }],
        },
      };

      let params = {};
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) { editor.value = s.code; params = {...s.params}; } });
      registerShortcut('ctrl+shift+z', () => { const s = undo.redo(); if (s) { editor.value = s.code; params = {...s.params}; } });
      registerShortcut('ctrl+s', () => document.getElementById('btnExport').click());

      function loadPreset(name) {
        currentPreset = name;
        const preset = PRESETS[name];
        editor.value = preset.code;
        params = {};
        preset.params.forEach(p => { params[p.name] = p.value; });
        buildParams(preset.params);
        document.getElementById('statusPreset').textContent = name;
        document.getElementById('errorBar').style.display = 'none';
        document.querySelectorAll('.preset-btn').forEach(b => b.classList.toggle('sel', b.dataset.preset === name));
      }

      function buildParams(paramDefs) {
        const bar = document.getElementById('paramsBar'); bar.innerHTML = '';
        paramDefs.forEach(p => {
          const item = document.createElement('div'); item.className = 'param-item';
          item.innerHTML = '<label>' + p.name + '</label><input type="range" min="' + p.min + '" max="' + p.max + '" value="' + p.value + '" data-p="' + p.name + '"><span>' + p.value + '</span>';
          item.querySelector('input').addEventListener('input', e => { const v = parseInt(e.target.value); params[p.name] = v; e.target.nextElementSibling.textContent = v; });
          bar.appendChild(item);
        });
      }

      let time = 0;
      function renderPreview() {
        if (!running) return;
        const t0 = performance.now();
        const w = canvas.width, h = canvas.height;
        const imgData = ctx.createImageData(w, h);
        for (let y = 0; y < h; y++) {
          for (let x = 0; x < w; x++) {
            const i = (y * w + x) * 4;
            const cx = w/2, cy = h/2;
            const dist = Math.sqrt((x-cx)*(x-cx) + (y-cy)*(y-cy));
            const wave = Math.sin(dist * 0.05 - time * 0.02) * 0.5 + 0.5;
            let r = Math.floor((x / w) * 200 * wave + 55);
            let g = Math.floor((y / h) * 200 * wave + 55);
            let b = Math.floor(128 + 127 * Math.sin(time * 0.01 + x * 0.02));
            if (currentPreset === 'pixel') {
              const s = Math.max(1, params.size || 8);
              const bx = Math.floor(x / s) * s, by = Math.floor(y / s) * s;
              const bd = Math.sqrt((bx-cx)*(bx-cx) + (by-cy)*(by-cy));
              const bw = Math.sin(bd * 0.05 - time * 0.02) * 0.5 + 0.5;
              r = Math.floor((bx / w) * 200 * bw + 55); g = Math.floor((by / h) * 200 * bw + 55);
            } else if (currentPreset === 'dissolve') {
              const noise = Math.sin(x * 12.9898 + y * 78.233) * 43758.5453;
              const n = noise - Math.floor(noise);
              const p = (params.progress || 30) / 100;
              if (n < p) { r = 0; g = 0; b = 0; } else if (n < p + 0.05) { r = 255; g = 128; b = 0; }
            } else if (currentPreset === 'wave') {
              const amp = params.amplitude || 10, freq = (params.frequency || 20) / 100;
              const off = Math.sin(y * freq + time * 0.03) * amp;
              const sx = Math.floor(x + off);
              if (sx >= 0 && sx < w) { const sd = Math.sqrt((sx-cx)*(sx-cx) + (y-cy)*(y-cy)); const sw = Math.sin(sd * 0.05 - time * 0.02) * 0.5 + 0.5; r = Math.floor((sx / w) * 200 * sw + 55); }
            }
            imgData.data[i] = Math.min(255, Math.max(0, r)); imgData.data[i+1] = Math.min(255, Math.max(0, g));
            imgData.data[i+2] = Math.min(255, Math.max(0, b)); imgData.data[i+3] = 255;
          }
        }
        ctx.putImageData(imgData, 0, 0); time++; frameCount++;
        const elapsed = performance.now() - t0;
        document.getElementById('perfTime').textContent = 'Frame: ' + elapsed.toFixed(1) + ' ms';
        const now = performance.now();
        if (now - lastFpsTime >= 1000) { document.getElementById('perfFps').textContent = 'FPS: ' + frameCount; frameCount = 0; lastFpsTime = now; }
        requestAnimationFrame(renderPreview);
      }

      editor.addEventListener('input', () => { undo.push({ code: editor.value, params: {...params} }); markDirty(); });
      document.querySelectorAll('.preset-btn').forEach(btn => { btn.addEventListener('click', () => loadPreset(btn.dataset.preset)); });
      document.getElementById('btnRun').addEventListener('click', () => { running = true; renderPreview(); });
      document.getElementById('btnPause').addEventListener('click', () => { running = false; });
      document.getElementById('btnExport').addEventListener('click', () => { vscode.postMessage({ type: 'exportLua', content: editor.value }); });

      loadPreset('blur'); renderPreview();
    `)}};var On=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.fontPreviewEditor","Font Preview")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"font_config.lua");break}}getHtml(){let e=L();return I(e,"Font Preview",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 200px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .preview-area { grid-row: 2; overflow-y: auto; padding: 12px; }
      .config-panel { grid-row: 2; overflow-y: auto; border-left: 1px solid var(--border); background: var(--surface); padding: 6px; }
      .text-input-bar { padding: 6px 12px; background: var(--surface); border-bottom: 1px solid var(--border); }
      .text-input-bar input { width: 100%; font-size: 12px; padding: 4px 8px; }
      .specimen-block { margin-bottom: 14px; }
      .specimen-label { font-size: 10px; color: var(--text-dim); margin-bottom: 3px; }
      .specimen-text { word-wrap: break-word; }
      .glyph-grid { display: grid; grid-template-columns: repeat(16, 1fr); gap: 1px; margin-top: 8px; }
      .glyph-cell {
        aspect-ratio: 1; display: flex; align-items: center; justify-content: center;
        background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius);
        cursor: pointer; font-size: 14px; min-height: 28px; transition: border-color 0.08s;
      }
      .glyph-cell:hover { border-color: var(--accent); background: var(--hover); }
      .glyph-cell.sel { border-color: var(--accent); background: var(--selection); }
      .size-preview { border-bottom: 1px solid var(--border); padding-bottom: 8px; margin-bottom: 8px; }
      .color-row { display: flex; align-items: center; gap: 6px; }
      .preset-size { font-size: 10px; padding: 2px 6px; min-width: 26px; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            <label style="font-size:10px">Font:</label>
            <select id="fontFamily" style="width:130px;font-size:10px">
              <option value="sans-serif">Sans-Serif</option>
              <option value="serif">Serif</option>
              <option value="monospace">Monospace</option>
              <option value="cursive">Cursive</option>
              <option value="fantasy">Fantasy</option>
            </select>
          </div>
          ${k()}
          <div class="group">
            <label style="font-size:10px">Size:</label>
            <input type="range" id="fontSize" min="8" max="72" value="24" style="width:80px">
            <span id="sizeLabel" style="font-size:10px;min-width:30px">24pt</span>
          </div>
          ${k()}
          <div class="group">
            <button id="btnBold" style="font-weight:700;font-size:11px;padding:2px 6px">B</button>
            <button id="btnItalic" style="font-style:italic;font-size:11px;padding:2px 6px">I</button>
          </div>
          ${A()}
          ${g(c.save,"btnExport","Export Lua")}
        </div>

        <div class="preview-area" id="previewArea">
          <div class="text-input-bar">
            <input type="text" id="sampleText" value="The quick brown fox jumps over the lazy dog. 0123456789" placeholder="Type sample text...">
          </div>
          <div style="padding-top:10px;">
            <div class="specimen-block size-preview" id="multiSizePreview"></div>
            <div class="specimen-block">
              <div class="specimen-label">Preview</div>
              <div class="specimen-text" id="mainPreview" style="font-size:24px;"></div>
            </div>
            <div class="specimen-block">
              <div class="specimen-label">Character Map</div>
              <div class="glyph-grid" id="glyphGrid"></div>
            </div>
          </div>
        </div>

        <div class="config-panel">
          ${b("Text Color",`
            <div class="color-row">
              <input type="color" id="textColor" value="#cccccc">
              <span id="textColorHex" style="font-size:10px">#cccccc</span>
            </div>
          `)}
          ${b("Background",`
            <div class="color-row">
              <input type="color" id="bgColor" value="#1e1e1e">
              <span id="bgColorHex" style="font-size:10px">#1e1e1e</span>
            </div>
          `)}
          ${b("Spacing",`
            ${N('Line Height: <span id="lhVal">1.5</span>','<input type="range" id="lineHeight" min="10" max="30" value="15" style="width:100%">')}
            ${N('Letter Spacing: <span id="lsVal">0</span>px','<input type="range" id="letterSpacing" min="-5" max="20" value="0" style="width:100%">')}
          `)}
          ${b("Selected Glyph",`
            <div style="text-align:center;font-size:40px;padding:8px;" id="selectedGlyph">A</div>
            <div style="text-align:center;font-size:10px;color:var(--text-dim);" id="glyphInfo">U+0041 | Code: 65</div>
          `)}
          ${b("Quick Sizes",`
            <div style="display:flex;flex-wrap:wrap;gap:3px">
              <button class="preset-size" data-s="8">8</button>
              <button class="preset-size" data-s="12">12</button>
              <button class="preset-size" data-s="16">16</button>
              <button class="preset-size" data-s="24">24</button>
              <button class="preset-size" data-s="32">32</button>
              <button class="preset-size" data-s="48">48</button>
              <button class="preset-size" data-s="72">72</button>
            </div>
          `)}
        </div>

        <div class="status-bar">
          <span id="statusFont" class="badge">sans-serif</span>
          <div class="sep"></div>
          <span id="statusSize">24pt</span>
          <div class="sep"></div>
          <span id="statusGlyphs">95 glyphs</span>
          <div class="spacer"></div>
          <span id="statusDirty" style="font-size:10px;color:var(--text-dim)">${c.clean}</span>
        </div>
      </div>
    `,`
      let fontFamily = 'sans-serif', fontSize = 24, bold = false, italic = false;
      let textColor = '#cccccc', bgColor = '#1e1e1e', lineHeight = 1.5, letterSpacing = 0;
      const PRINTABLE_START = 32, PRINTABLE_END = 126;

      function getStyle(size) { return (italic ? 'italic ' : '') + (bold ? 'bold ' : '') + (size || fontSize) + 'px ' + fontFamily; }

      function updatePreview() {
        const text = document.getElementById('sampleText').value;
        const main = document.getElementById('mainPreview');
        main.style.font = getStyle(); main.style.color = textColor;
        main.style.lineHeight = lineHeight; main.style.letterSpacing = letterSpacing + 'px';
        main.textContent = text;
        document.getElementById('previewArea').style.background = bgColor;
        const multi = document.getElementById('multiSizePreview'); multi.innerHTML = '';
        [8, 12, 16, 24, 32, 48].forEach(s => {
          const div = document.createElement('div');
          div.style.font = getStyle(s); div.style.color = textColor; div.style.marginBottom = '6px';
          div.style.lineHeight = lineHeight; div.style.letterSpacing = letterSpacing + 'px';
          const label = document.createElement('span'); label.className = 'specimen-label'; label.textContent = s + 'pt  ';
          div.appendChild(label); div.appendChild(document.createTextNode(text));
          multi.appendChild(div);
        });
      }

      function buildGlyphGrid() {
        const grid = document.getElementById('glyphGrid'); grid.innerHTML = '';
        for (let code = PRINTABLE_START; code <= PRINTABLE_END; code++) {
          const cell = document.createElement('div'); cell.className = 'glyph-cell';
          cell.style.fontFamily = fontFamily; cell.textContent = String.fromCharCode(code);
          cell.addEventListener('click', () => {
            grid.querySelectorAll('.glyph-cell').forEach(c => c.classList.remove('sel'));
            cell.classList.add('sel');
            document.getElementById('selectedGlyph').textContent = String.fromCharCode(code);
            document.getElementById('selectedGlyph').style.fontFamily = fontFamily;
            document.getElementById('glyphInfo').textContent = 'U+' + code.toString(16).toUpperCase().padStart(4, '0') + ' | Code: ' + code;
          });
          grid.appendChild(cell);
        }
        document.getElementById('statusGlyphs').textContent = (PRINTABLE_END - PRINTABLE_START + 1) + ' glyphs';
      }

      document.getElementById('fontFamily').addEventListener('change', e => {
        fontFamily = e.target.value; document.getElementById('statusFont').textContent = fontFamily;
        markDirty(); updatePreview(); buildGlyphGrid();
      });
      document.getElementById('fontSize').addEventListener('input', e => {
        fontSize = parseInt(e.target.value); document.getElementById('sizeLabel').textContent = fontSize + 'pt';
        document.getElementById('statusSize').textContent = fontSize + 'pt'; updatePreview();
      });
      document.getElementById('btnBold').addEventListener('click', e => { bold = !bold; e.target.classList.toggle('sel', bold); markDirty(); updatePreview(); });
      document.getElementById('btnItalic').addEventListener('click', e => { italic = !italic; e.target.classList.toggle('sel', italic); markDirty(); updatePreview(); });
      document.getElementById('sampleText').addEventListener('input', updatePreview);
      document.getElementById('textColor').addEventListener('input', e => { textColor = e.target.value; document.getElementById('textColorHex').textContent = textColor; markDirty(); updatePreview(); });
      document.getElementById('bgColor').addEventListener('input', e => { bgColor = e.target.value; document.getElementById('bgColorHex').textContent = bgColor; markDirty(); updatePreview(); });
      document.getElementById('lineHeight').addEventListener('input', e => { lineHeight = parseInt(e.target.value) / 10; document.getElementById('lhVal').textContent = lineHeight.toFixed(1); updatePreview(); });
      document.getElementById('letterSpacing').addEventListener('input', e => { letterSpacing = parseInt(e.target.value); document.getElementById('lsVal').textContent = letterSpacing; updatePreview(); });
      document.querySelectorAll('.preset-size').forEach(b => {
        b.addEventListener('click', () => { fontSize = parseInt(b.dataset.s); document.getElementById('fontSize').value = fontSize; document.getElementById('sizeLabel').textContent = fontSize + 'pt'; updatePreview(); });
      });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = '-- Font configuration for Lurek2D\\n';
        lua += 'local font = lurek.graphic.newFont("' + fontFamily + '", ' + fontSize + ')\\n';
        lua += '-- Style: ' + (bold ? 'bold ' : '') + (italic ? 'italic' : 'normal') + '\\n';
        lua += '-- Color: { ' + parseInt(textColor.slice(1,3),16) + ', ' + parseInt(textColor.slice(3,5),16) + ', ' + parseInt(textColor.slice(5,7),16) + ' }\\n';
        lua += '-- Line height: ' + lineHeight.toFixed(1) + ', Letter spacing: ' + letterSpacing + '\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });
      registerShortcut('ctrl+s', () => document.getElementById('btnExport').click());

      updatePreview(); buildGlyphGrid();
    `)}};var Wn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.localizationEditor","Localization")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"strings.lua");break;case"exportJson":this.exportFile(e.content,"strings.json","JSON","json");break}}getHtml(){let e=L();return I(e,"Localization",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr;
        grid-template-rows: auto auto 1fr auto auto;
        height: 100vh;
      }
      .toolbar { grid-row: 1; }
      .filter-bar { grid-row: 2; padding: 4px 8px; background: var(--surface); border-bottom: 1px solid var(--border); display: flex; gap: 6px; align-items: center; }
      .table-area { grid-row: 3; overflow: auto; }
      .stats-bar { grid-row: 4; padding: 4px 8px; background: var(--surface); border-top: 1px solid var(--border); display: flex; gap: 12px; flex-wrap: wrap; }
      .status-bar { grid-row: 5; }
      .loc-table { width: 100%; border-collapse: collapse; font-size: 11px; }
      .loc-table th {
        position: sticky; top: 0; z-index: 5;
        text-align: left; padding: 4px 6px; background: var(--surface);
        border-bottom: 2px solid var(--border); font-size: 10px; text-transform: uppercase;
        color: var(--text-dim); white-space: nowrap;
      }
      .loc-table td { padding: 1px 3px; border-bottom: 1px solid var(--border); vertical-align: top; }
      .loc-table tr:hover { background: var(--hover); }
      .loc-table tr.sel { background: var(--selection); }
      .loc-input {
        width: 100%; background: transparent; border: 1px solid transparent;
        color: var(--text); padding: 2px 4px; font-size: 11px;
      }
      .loc-input:focus { border-color: var(--accent); background: var(--surface); }
      .loc-input.missing { border-color: var(--error); background: rgba(243,139,168,0.08); }
      .key-cell { font-family: var(--font-mono, monospace); font-size: 10px; color: var(--accent-2); min-width: 120px; }
      .coverage-bar { display: flex; align-items: center; gap: 4px; font-size: 10px; }
      .coverage-fill { width: 50px; height: 6px; background: var(--surface-2); border-radius: 3px; overflow: hidden; }
      .coverage-fill-inner { height: 100%; border-radius: 3px; transition: width 0.3s; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${g(c.add,"btnAddKey","Add Key")}
            ${g(c.trash,"btnRemoveKey","Remove Key")}
          </div>
          ${k()}
          <div class="group">
            <button id="btnAddLang" style="font-size:10px;padding:2px 6px">+ Lang</button>
            <button id="btnRemoveLang" style="font-size:10px;padding:2px 6px;color:var(--error)">- Lang</button>
          </div>
          ${k()}
          <div class="group">
            <button id="btnImportJson" style="font-size:10px;padding:2px 6px">Import JSON</button>
          </div>
          ${A()}
          <div class="group">
            <button id="btnExportJson" style="font-size:10px;padding:2px 6px">JSON</button>
            ${g(c.save,"btnExportLua","Export Lua")}
          </div>
        </div>

        <div class="filter-bar">
          <label style="font-size:10px">Search:</label>
          <input type="text" id="searchInput" placeholder="Filter keys or values..." style="flex:1;max-width:250px;font-size:10px">
          <label style="font-size:10px">Show:</label>
          <select id="filterMode" style="font-size:10px">
            <option value="all">All</option>
            <option value="missing">Missing</option>
            <option value="complete">Complete</option>
          </select>
        </div>

        <div class="table-area">
          <table class="loc-table">
            <thead id="tableHead"></thead>
            <tbody id="tableBody"></tbody>
          </table>
        </div>

        <div class="stats-bar" id="statsBar"></div>

        <div class="status-bar">
          <span id="statusKeys" class="badge">6 keys</span>
          <div class="sep"></div>
          <span id="statusLangs">4 langs</span>
          <div class="sep"></div>
          <span id="statusTotal">translations</span>
          <div class="spacer"></div>
          <span id="statusDirty" style="font-size:10px;color:var(--text-dim)">${c.clean}</span>
        </div>
      </div>
    `,`
      const undo = new UndoStack();
      let languages = ['en', 'es', 'fr', 'de'];
      let baseLang = 'en';
      let entries = [
        { key: 'menu.start', values: { en: 'Start Game', es: 'Iniciar Juego', fr: 'Commencer', de: 'Spiel starten' } },
        { key: 'menu.options', values: { en: 'Options', es: 'Opciones', fr: 'Options', de: 'Optionen' } },
        { key: 'menu.quit', values: { en: 'Quit', es: 'Salir', fr: 'Quitter', de: 'Beenden' } },
        { key: 'dialog.greeting', values: { en: 'Hello, traveler!', es: 'Hola, viajero!', fr: '', de: '' } },
        { key: 'item.sword', values: { en: 'Iron Sword', es: 'Espada de hierro', fr: '', de: '' } },
        { key: 'ui.health', values: { en: 'Health', es: 'Salud', fr: 'Sant\\u00e9', de: 'Gesundheit' } },
      ];
      let selectedRow = -1, searchText = '', filterMode = 'all';

      function snap() { return JSON.parse(JSON.stringify({ languages, entries })); }
      function load(s) { languages = s.languages; entries = s.entries; build(); }
      function push() { undo.push(snap()); markDirty(); }
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) load(s); });
      registerShortcut('ctrl+shift+z', () => { const s = undo.redo(); if (s) load(s); });
      registerShortcut('ctrl+s', () => document.getElementById('btnExportLua').click());

      function build() {
        const head = document.getElementById('tableHead');
        head.innerHTML = '<tr><th style="width:140px;">Key</th>';
        languages.forEach(lang => { head.querySelector('tr').innerHTML += '<th>' + lang.toUpperCase() + (lang === baseLang ? ' *' : '') + '</th>'; });
        head.querySelector('tr').innerHTML += '</tr>';

        const body = document.getElementById('tableBody'); body.innerHTML = '';
        const filtered = getFilteredEntries();
        filtered.forEach((entry) => {
          const origIdx = entries.indexOf(entry);
          const tr = document.createElement('tr');
          tr.className = origIdx === selectedRow ? 'sel' : '';
          tr.addEventListener('click', () => { selectedRow = origIdx; build(); });

          const tdKey = document.createElement('td'); tdKey.className = 'key-cell';
          const keyInput = document.createElement('input'); keyInput.className = 'loc-input';
          keyInput.value = entry.key; keyInput.style.fontFamily = 'var(--font-mono, monospace)'; keyInput.style.color = 'var(--accent-2)';
          keyInput.addEventListener('change', e => { push(); entry.key = e.target.value; });
          tdKey.appendChild(keyInput); tr.appendChild(tdKey);

          languages.forEach(lang => {
            const td = document.createElement('td');
            const input = document.createElement('input');
            input.className = 'loc-input' + ((entry.values[lang] || '').trim() === '' ? ' missing' : '');
            input.value = entry.values[lang] || '';
            input.placeholder = lang === baseLang ? '(base)' : '(missing)';
            input.addEventListener('change', e => { push(); entry.values[lang] = e.target.value; updateStats(); build(); });
            td.appendChild(input); tr.appendChild(td);
          });
          body.appendChild(tr);
        });
        updateStats();
      }

      function getFilteredEntries() {
        return entries.filter(e => {
          if (searchText) {
            const s = searchText.toLowerCase();
            if (!e.key.toLowerCase().includes(s) && !Object.values(e.values).some(v => (v || '').toLowerCase().includes(s))) return false;
          }
          if (filterMode === 'missing') return languages.some(l => !(e.values[l] || '').trim());
          if (filterMode === 'complete') return languages.every(l => (e.values[l] || '').trim());
          return true;
        });
      }

      function updateStats() {
        const bar = document.getElementById('statsBar'); bar.innerHTML = '';
        let totalFilled = 0, totalCells = 0;
        languages.forEach(lang => {
          let filled = 0;
          entries.forEach(e => { if ((e.values[lang] || '').trim()) filled++; });
          totalFilled += filled; totalCells += entries.length;
          const pct = entries.length > 0 ? Math.round(filled / entries.length * 100) : 0;
          const color = pct === 100 ? 'var(--success)' : pct > 50 ? 'var(--warning)' : 'var(--error)';
          const item = document.createElement('div'); item.className = 'coverage-bar';
          item.innerHTML = '<strong>' + lang.toUpperCase() + '</strong>' +
            '<div class="coverage-fill"><div class="coverage-fill-inner" style="width:' + pct + '%;background:' + color + '"></div></div>' +
            '<span>' + pct + '% (' + filled + '/' + entries.length + ')</span>';
          bar.appendChild(item);
        });
        document.getElementById('statusKeys').textContent = entries.length + ' keys';
        document.getElementById('statusLangs').textContent = languages.length + ' langs';
        document.getElementById('statusTotal').textContent = totalFilled + '/' + totalCells + ' filled';
      }

      document.getElementById('searchInput').addEventListener('input', e => { searchText = e.target.value; build(); });
      document.getElementById('filterMode').addEventListener('change', e => { filterMode = e.target.value; build(); });

      document.getElementById('btnAddKey').addEventListener('click', () => {
        push(); const values = {}; languages.forEach(l => { values[l] = ''; });
        entries.push({ key: 'new.key.' + entries.length, values }); selectedRow = entries.length - 1; build();
      });
      document.getElementById('btnRemoveKey').addEventListener('click', () => {
        if (selectedRow >= 0 && selectedRow < entries.length) { push(); entries.splice(selectedRow, 1); selectedRow = Math.min(selectedRow, entries.length - 1); build(); }
      });

      document.getElementById('btnAddLang').addEventListener('click', () => {
        const lang = prompt('Language code (e.g. ja, ko, pt):');
        if (lang && !languages.includes(lang)) { push(); languages.push(lang); entries.forEach(e => { e.values[lang] = ''; }); build(); }
      });
      document.getElementById('btnRemoveLang').addEventListener('click', () => {
        if (languages.length <= 1) return;
        const lang = prompt('Language code to remove:');
        if (lang && languages.includes(lang) && lang !== baseLang) { push(); languages = languages.filter(l => l !== lang); entries.forEach(e => { delete e.values[lang]; }); build(); }
      });

      document.getElementById('btnExportJson').addEventListener('click', () => {
        const obj = {}; languages.forEach(l => { obj[l] = {}; entries.forEach(e => { obj[l][e.key] = e.values[l] || ''; }); });
        vscode.postMessage({ type: 'exportJson', content: JSON.stringify(obj, null, 2) });
      });
      document.getElementById('btnExportLua').addEventListener('click', () => {
        let lua = 'return {\\n';
        languages.forEach(l => { lua += '  ' + l + ' = {\\n'; entries.forEach(e => { const val = (e.values[l] || '').replace(/"/g, '\\\\"'); lua += '    ["' + e.key + '"] = "' + val + '",\\n'; }); lua += '  },\\n'; });
        lua += '}'; vscode.postMessage({ type: 'exportLua', content: lua });
      });

      build();
    `)}};var Gn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.physicsMaterialsEditor","Physics Materials")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"physics_materials.lua");break}}getHtml(){let e=L();return I(e,"Physics Materials",`
      .editor-layout {
        display: grid; grid-template-columns: 160px 1fr 200px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .material-list { grid-row: 2; border-right: 1px solid var(--border); overflow-y: auto; background: var(--surface); }
      .preview-area { grid-row: 2; display: flex; flex-direction: column; overflow: hidden; }
      .props-panel { grid-row: 2; overflow-y: auto; border-left: 1px solid var(--border); background: var(--surface); padding: 6px; }
      .mat-item {
        display: flex; align-items: center; gap: 4px; padding: 4px 6px;
        cursor: pointer; font-size: 11px; border-bottom: 1px solid var(--border);
        transition: background 0.08s;
      }
      .mat-item:hover { background: var(--hover); }
      .mat-item.sel { background: var(--selection); }
      .mat-color { width: 12px; height: 12px; border-radius: 50%; border: 1px solid var(--border); flex-shrink: 0; }
      .canvas-section { flex: 1; display: flex; align-items: center; justify-content: center; background: var(--bg); }
      .matrix-section { border-top: 1px solid var(--border); padding: 8px; background: var(--surface); overflow: auto; }
      .matrix-table { border-collapse: collapse; font-size: 9px; }
      .matrix-table th { padding: 3px; background: var(--surface-2); border: 1px solid var(--border); writing-mode: vertical-lr; text-orientation: mixed; max-width: 24px; }
      .matrix-table td { padding: 0; border: 1px solid var(--border); text-align: center; }
      .matrix-cell { width: 20px; height: 20px; cursor: pointer; display: flex; align-items: center; justify-content: center; }
      .matrix-cell.on { background: var(--accent); color: var(--bg); }
      .matrix-cell.off { background: var(--surface-2); color: var(--text-dim); }
      .slider-row { display: flex; align-items: center; gap: 4px; margin-bottom: 4px; }
      .slider-row input[type="range"] { flex: 1; }
      .slider-row .val { font-family: var(--font-mono,monospace); font-size: 10px; min-width: 32px; text-align: right; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${g(c.add,"btnAdd","Add Material")}
            <button id="btnDuplicate" style="font-size:10px;padding:2px 6px">Dup</button>
            ${g(c.trash,"btnRemove","Remove")}
          </div>
          ${k()}
          <div class="group">
            <button id="btnPresets" style="font-size:10px;padding:2px 6px">Presets</button>
          </div>
          ${A()}
          ${g(c.save,"btnExport","Export Lua")}
        </div>

        <div class="material-list" id="materialList"></div>

        <div class="preview-area">
          <div class="canvas-section">
            <canvas id="previewCanvas" width="360" height="260"></canvas>
          </div>
          <div class="matrix-section">
            <div style="font-size:10px;text-transform:uppercase;color:var(--text-dim);margin-bottom:4px;font-weight:600">Collision Matrix</div>
            <table class="matrix-table" id="collisionMatrix"></table>
          </div>
        </div>

        <div class="props-panel">
          ${b("Material",`
            ${N("Name",'<input type="text" id="matName" style="width:100%">')}
            ${N("Color",'<input type="color" id="matColor" value="#89b4fa">')}
          `)}
          ${b("Physics",`
            <div class="slider-row"><label style="font-size:10px;min-width:60px">Friction</label><input type="range" id="friction" min="0" max="100" value="50"><span class="val" id="frictionVal">0.50</span></div>
            <div class="slider-row"><label style="font-size:10px;min-width:60px">Bounce</label><input type="range" id="restitution" min="0" max="100" value="30"><span class="val" id="restitutionVal">0.30</span></div>
            <div class="slider-row"><label style="font-size:10px;min-width:60px">Density</label><input type="range" id="density" min="1" max="200" value="10"><span class="val" id="densityVal">1.0</span></div>
          `)}
          ${b("Collision Layer",`
            <select id="collisionLayer" style="width:100%;font-size:10px">
              <option value="0">Layer 0 (Default)</option>
              <option value="1">Layer 1</option>
              <option value="2">Layer 2</option>
              <option value="3">Layer 3</option>
              <option value="4">Layer 4</option>
              <option value="5">Layer 5</option>
              <option value="6">Layer 6</option>
              <option value="7">Layer 7</option>
            </select>
          `)}
        </div>

        <div class="status-bar">
          <span id="statusMat" class="badge">Default</span>
          <div class="sep"></div>
          <span id="statusCount">5 materials</span>
          <div class="sep"></div>
          <span id="statusLayers">8 layers</span>
          <div class="spacer"></div>
          <span id="statusDirty" style="font-size:10px;color:var(--text-dim)">${c.clean}</span>
        </div>
      </div>
    `,`
      const undo = new UndoStack();
      let materials = [
        { name: 'Default', friction: 0.5, restitution: 0.3, density: 1.0, layer: 0, color: '#858585' },
        { name: 'Ice', friction: 0.05, restitution: 0.1, density: 0.9, layer: 0, color: '#80d4ff' },
        { name: 'Rubber', friction: 0.9, restitution: 0.8, density: 1.2, layer: 0, color: '#e06040' },
        { name: 'Metal', friction: 0.3, restitution: 0.2, density: 7.8, layer: 1, color: '#a0a0a0' },
        { name: 'Wood', friction: 0.6, restitution: 0.4, density: 0.6, layer: 0, color: '#b07040' },
      ];
      let selMat = 0;
      const NUM_LAYERS = 8;
      let collisionMatrix = [];
      for (let i = 0; i < NUM_LAYERS; i++) collisionMatrix[i] = new Array(NUM_LAYERS).fill(true);

      const canvas = document.getElementById('previewCanvas');
      const ctx = canvas.getContext('2d');
      let ballX = 180, ballY = 40, ballVY = 0, ballVX = 1;
      const GRAVITY = 0.3, FLOOR_Y = 220;

      function snap() { return JSON.parse(JSON.stringify({ materials, collisionMatrix })); }
      function loadSnap(s) { materials = s.materials; collisionMatrix = s.collisionMatrix; build(); updateProps(); }
      function push() { undo.push(snap()); markDirty(); }
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) loadSnap(s); });
      registerShortcut('ctrl+shift+z', () => { const s = undo.redo(); if (s) loadSnap(s); });
      registerShortcut('ctrl+s', () => document.getElementById('btnExport').click());

      function build() {
        const list = document.getElementById('materialList'); list.innerHTML = '';
        materials.forEach((mat, i) => {
          const el = document.createElement('div');
          el.className = 'mat-item' + (i === selMat ? ' sel' : '');
          el.innerHTML = '<div class="mat-color" style="background:' + mat.color + '"></div><span>' + mat.name + '</span>';
          el.addEventListener('click', () => { selMat = i; build(); updateProps(); resetBall(); });
          list.appendChild(el);
        });
        renderMatrix();
        document.getElementById('statusCount').textContent = materials.length + ' materials';
        document.getElementById('statusMat').textContent = materials[selMat]?.name || 'none';
      }

      function updateProps() {
        const mat = materials[selMat]; if (!mat) return;
        document.getElementById('matName').value = mat.name;
        document.getElementById('matColor').value = mat.color;
        document.getElementById('friction').value = Math.round(mat.friction * 100);
        document.getElementById('frictionVal').textContent = mat.friction.toFixed(2);
        document.getElementById('restitution').value = Math.round(mat.restitution * 100);
        document.getElementById('restitutionVal').textContent = mat.restitution.toFixed(2);
        document.getElementById('density').value = Math.round(mat.density * 10);
        document.getElementById('densityVal').textContent = mat.density.toFixed(1);
        document.getElementById('collisionLayer').value = mat.layer;
      }

      function renderMatrix() {
        const table = document.getElementById('collisionMatrix'); table.innerHTML = '';
        const hRow = document.createElement('tr'); hRow.innerHTML = '<th></th>';
        for (let i = 0; i < NUM_LAYERS; i++) hRow.innerHTML += '<th>L' + i + '</th>';
        table.appendChild(hRow);
        for (let r = 0; r < NUM_LAYERS; r++) {
          const row = document.createElement('tr'); row.innerHTML = '<th>L' + r + '</th>';
          for (let c = 0; c < NUM_LAYERS; c++) {
            const td = document.createElement('td'), cell = document.createElement('div');
            const on = collisionMatrix[r][c];
            cell.className = 'matrix-cell ' + (on ? 'on' : 'off');
            cell.textContent = on ? '\\u2713' : '';
            cell.addEventListener('click', () => { push(); collisionMatrix[r][c] = !collisionMatrix[r][c]; collisionMatrix[c][r] = collisionMatrix[r][c]; renderMatrix(); });
            td.appendChild(cell); row.appendChild(td);
          }
          table.appendChild(row);
        }
      }

      function resetBall() { ballX = 180; ballY = 40; ballVY = 0; ballVX = 1; }

      function animatePreview() {
        const bgCol = getComputedStyle(document.documentElement).getPropertyValue('--bg').trim() || '#1e1e1e';
        const textCol = getComputedStyle(document.documentElement).getPropertyValue('--text-dim').trim() || '#858585';
        const borderCol = getComputedStyle(document.documentElement).getPropertyValue('--border').trim() || '#3c3c3c';
        ctx.fillStyle = bgCol; ctx.fillRect(0, 0, canvas.width, canvas.height);
        const mat = materials[selMat];
        if (!mat) { requestAnimationFrame(animatePreview); return; }
        ctx.fillStyle = borderCol; ctx.fillRect(0, FLOOR_Y, canvas.width, canvas.height - FLOOR_Y);
        ctx.fillStyle = textCol; ctx.font = '10px sans-serif';
        ctx.fillText('friction: ' + mat.friction.toFixed(2) + '  bounce: ' + mat.restitution.toFixed(2) + '  density: ' + mat.density.toFixed(1), 8, FLOOR_Y + 16);
        ballVY += GRAVITY; ballY += ballVY; ballX += ballVX;
        const radius = 10 + mat.density * 2;
        if (ballY + radius >= FLOOR_Y) { ballY = FLOOR_Y - radius; ballVY = -ballVY * mat.restitution; ballVX *= (1 - mat.friction * 0.1); if (Math.abs(ballVY) < 0.5) ballVY = 0; }
        if (ballX + radius >= canvas.width || ballX - radius <= 0) { ballVX = -ballVX * 0.9; ballX = Math.max(radius, Math.min(canvas.width - radius, ballX)); }
        ctx.beginPath(); ctx.arc(ballX, ballY, radius, 0, Math.PI * 2);
        ctx.fillStyle = mat.color; ctx.fill(); ctx.strokeStyle = textCol; ctx.lineWidth = 1; ctx.stroke();
        ctx.fillStyle = textCol; ctx.font = '10px sans-serif'; ctx.textAlign = 'center';
        ctx.fillText(mat.name, ballX, ballY - radius - 4); ctx.textAlign = 'left';
        requestAnimationFrame(animatePreview);
      }

      document.getElementById('matName').addEventListener('change', e => { if (materials[selMat]) { push(); materials[selMat].name = e.target.value; build(); } });
      document.getElementById('matColor').addEventListener('input', e => { if (materials[selMat]) { push(); materials[selMat].color = e.target.value; build(); } });
      document.getElementById('friction').addEventListener('input', e => { const v = parseInt(e.target.value)/100; document.getElementById('frictionVal').textContent = v.toFixed(2); if (materials[selMat]) materials[selMat].friction = v; });
      document.getElementById('restitution').addEventListener('input', e => { const v = parseInt(e.target.value)/100; document.getElementById('restitutionVal').textContent = v.toFixed(2); if (materials[selMat]) { materials[selMat].restitution = v; resetBall(); } });
      document.getElementById('density').addEventListener('input', e => { const v = parseInt(e.target.value)/10; document.getElementById('densityVal').textContent = v.toFixed(1); if (materials[selMat]) { materials[selMat].density = v; resetBall(); } });
      document.getElementById('collisionLayer').addEventListener('change', e => { if (materials[selMat]) { push(); materials[selMat].layer = parseInt(e.target.value); } });

      document.getElementById('btnAdd').addEventListener('click', () => { push(); materials.push({ name: 'New Material', friction: 0.5, restitution: 0.3, density: 1.0, layer: 0, color: '#888888' }); selMat = materials.length - 1; build(); updateProps(); resetBall(); });
      document.getElementById('btnDuplicate').addEventListener('click', () => { const src = materials[selMat]; if (src) { push(); materials.push({ ...src, name: src.name + ' Copy' }); selMat = materials.length - 1; build(); updateProps(); } });
      document.getElementById('btnRemove').addEventListener('click', () => { if (materials.length > 1) { push(); materials.splice(selMat, 1); selMat = Math.min(selMat, materials.length - 1); build(); updateProps(); resetBall(); } });
      document.getElementById('btnPresets').addEventListener('click', () => {
        push();
        materials = [
          { name:'Default', friction:0.5, restitution:0.3, density:1.0, layer:0, color:'#858585' },
          { name:'Ice', friction:0.05, restitution:0.1, density:0.9, layer:0, color:'#80d4ff' },
          { name:'Rubber', friction:0.9, restitution:0.8, density:1.2, layer:0, color:'#e06040' },
          { name:'Metal', friction:0.3, restitution:0.2, density:7.8, layer:1, color:'#a0a0a0' },
          { name:'Wood', friction:0.6, restitution:0.4, density:0.6, layer:0, color:'#b07040' },
          { name:'Bouncy Ball', friction:0.4, restitution:0.95, density:0.5, layer:0, color:'#ff6090' },
          { name:'Stone', friction:0.7, restitution:0.1, density:2.5, layer:1, color:'#707070' },
        ];
        selMat = 0; build(); updateProps(); resetBall();
      });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  materials = {\\n';
        materials.forEach(m => { lua += '    { name = "' + m.name + '", friction = ' + m.friction.toFixed(2) + ', restitution = ' + m.restitution.toFixed(2) + ', density = ' + m.density.toFixed(1) + ', layer = ' + m.layer + ' },\\n'; });
        lua += '  },\\n  collision_matrix = {\\n';
        for (let r = 0; r < NUM_LAYERS; r++) lua += '    {' + collisionMatrix[r].map(v => v ? 'true' : 'false').join(', ') + '},\\n';
        lua += '  }\\n}'; vscode.postMessage({ type: 'exportLua', content: lua });
      });

      build(); updateProps(); animatePreview();
    `)}};var Hn=class n extends E{static open(e){return new n(e)}constructor(e){super(e,"lurek.worldMapEditor","World Map")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"world_map.lua");break}}getHtml(){let e=L();return I(e,"World Map",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 200px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: var(--bg); }
      .props-panel { grid-row: 2; overflow-y: auto; border-left: 1px solid var(--border); background: var(--surface); padding: 6px; }
      .status-bar { grid-column: 1 / -1; }
      .minimap {
        width: 100%; height: 100px; background: var(--bg); border: 1px solid var(--border);
        border-radius: var(--radius); margin-bottom: 4px;
      }
      .room-list { max-height: 160px; overflow-y: auto; }
      .room-item {
        display: flex; align-items: center; gap: 4px; padding: 3px 6px;
        cursor: pointer; font-size: 11px; border-bottom: 1px solid var(--border);
        transition: background 0.08s;
      }
      .room-item:hover { background: var(--hover); }
      .room-item.sel { background: var(--selection); }
      .room-dot { width: 10px; height: 10px; border-radius: 2px; flex-shrink: 0; }
      .mode-btn { font-size: 10px; padding: 2px 7px; }
      .mode-btn.sel { background: var(--accent); color: var(--bg); }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${g(c.add,"btnAddRoom","Add Room")}
            ${g(c.trash,"btnRemoveRoom","Remove")}
          </div>
          ${k()}
          <div class="group">
            <button class="mode-btn sel" id="btnConnect">Connect</button>
            <button class="mode-btn" id="btnMove">Move</button>
          </div>
          ${k()}
          <div class="group">
            <input type="checkbox" id="snapGrid" checked><label style="font-size:10px" for="snapGrid">Snap</label>
          </div>
          ${k()}
          <div class="group">
            ${g(c.zoomIn,"btnZoomIn","Zoom In")}
            ${g(c.zoomOut,"btnZoomOut","Zoom Out")}
            <button id="btnFitAll" style="font-size:10px;padding:2px 6px">Fit</button>
          </div>
          ${A()}
          ${g(c.save,"btnExport","Export Lua")}
        </div>

        <div class="canvas-area">
          <canvas id="mapCanvas"></canvas>
        </div>

        <div class="props-panel">
          ${b("Minimap",'<canvas class="minimap" id="minimap"></canvas>')}
          ${b("Room",`
            ${N("Name",'<input type="text" id="roomName" style="width:100%">')}
            <div style="display:flex;gap:4px">
              ${N("W",'<input type="number" id="roomW" min="40" max="400" value="120" style="width:50px">')}
              ${N("H",'<input type="number" id="roomH" min="30" max="300" value="80" style="width:50px">')}
            </div>
            ${N("Color",'<input type="color" id="roomColor" value="#2d5a88">')}
            ${N("BG",'<input type="text" id="roomBg" placeholder="bg.png" style="width:100%">')}
          `)}
          ${b("Rooms",'<div class="room-list" id="roomList"></div>')}
          ${b("Connections",'<div id="connectionList" style="font-size:10px;max-height:80px;overflow-y:auto;"></div>')}
        </div>

        <div class="status-bar">
          <span id="statusRooms" class="badge">4 rooms</span>
          <div class="sep"></div>
          <span id="statusConnections">3 conn</span>
          <div class="sep"></div>
          <span id="statusMode">connect</span>
          <div class="sep"></div>
          <span id="statusPos" style="font-family:var(--font-mono,monospace)">0, 0</span>
          <div class="spacer"></div>
          <span id="statusDirty" style="font-size:10px;color:var(--text-dim)">${c.clean}</span>
        </div>
      </div>
    `,`
      const canvas = document.getElementById('mapCanvas');
      const ctx = canvas.getContext('2d');
      const miniCanvas = document.getElementById('minimap');
      const miniCtx = miniCanvas.getContext('2d');
      const undo = new UndoStack();

      let rooms = [
        { id: 0, name: 'Entrance', x: 100, y: 200, w: 120, h: 80, color: '#2d5a88', bg: '' },
        { id: 1, name: 'Hallway', x: 300, y: 200, w: 140, h: 60, color: '#3a6b35', bg: '' },
        { id: 2, name: 'Boss Room', x: 520, y: 180, w: 160, h: 100, color: '#8b2500', bg: '' },
        { id: 3, name: 'Treasure', x: 300, y: 80, w: 100, h: 70, color: '#8b7500', bg: '' },
      ];
      let connections = [{ from: 0, to: 1 }, { from: 1, to: 2 }, { from: 1, to: 3 }];
      let nextId = 4, selRoom = 0, mode = 'connect', snapOn = true, zoom = 1, offX = 0, offY = 0;
      let dragging = null, connectFrom = -1, isPanning = false, panSX = 0, panSY = 0;
      const GRID = 20;

      function gridSnap(v) { return snapOn ? Math.round(v / GRID) * GRID : v; }
      function snapState() { return JSON.parse(JSON.stringify({ rooms, connections, nextId })); }
      function loadState(s) { rooms = s.rooms; connections = s.connections; nextId = s.nextId; draw(); updateList(); updateProps(); }
      function push() { undo.push(snapState()); markDirty(); }
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) loadState(s); });
      registerShortcut('ctrl+shift+z', () => { const s = undo.redo(); if (s) loadState(s); });
      registerShortcut('ctrl+s', () => document.getElementById('btnExport').click());

      function resizeCanvas() { const a = canvas.parentElement; canvas.width = a.clientWidth; canvas.height = a.clientHeight; draw(); }

      function draw() {
        const bgCol = getComputedStyle(document.documentElement).getPropertyValue('--bg').trim() || '#1e1e1e';
        const gridCol = getComputedStyle(document.documentElement).getPropertyValue('--border').trim() || '#2a2a2a';
        const textCol = getComputedStyle(document.documentElement).getPropertyValue('--text').trim() || '#cdd6f4';
        const dimCol = getComputedStyle(document.documentElement).getPropertyValue('--text-dim').trim() || '#858585';
        ctx.fillStyle = bgCol; ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.save(); ctx.translate(offX, offY); ctx.scale(zoom, zoom);
        ctx.strokeStyle = gridCol; ctx.lineWidth = 0.5;
        for (let x = -1000; x < 2000; x += GRID) { ctx.beginPath(); ctx.moveTo(x, -1000); ctx.lineTo(x, 2000); ctx.stroke(); }
        for (let y = -1000; y < 2000; y += GRID) { ctx.beginPath(); ctx.moveTo(-1000, y); ctx.lineTo(2000, y); ctx.stroke(); }
        ctx.lineWidth = 2;
        connections.forEach(c => {
          const from = rooms.find(r => r.id === c.from), to = rooms.find(r => r.id === c.to);
          if (!from || !to) return;
          const fx = from.x + from.w/2, fy = from.y + from.h/2, tx = to.x + to.w/2, ty = to.y + to.h/2;
          ctx.strokeStyle = dimCol; ctx.beginPath(); ctx.moveTo(fx, fy); ctx.lineTo(tx, ty); ctx.stroke();
          const angle = Math.atan2(ty-fy, tx-fx), mx = (fx+tx)/2, my = (fy+ty)/2;
          ctx.fillStyle = dimCol; ctx.beginPath();
          ctx.moveTo(mx + 8*Math.cos(angle), my + 8*Math.sin(angle));
          ctx.lineTo(mx + 8*Math.cos(angle+2.5), my + 8*Math.sin(angle+2.5));
          ctx.lineTo(mx + 8*Math.cos(angle-2.5), my + 8*Math.sin(angle-2.5)); ctx.fill();
        });
        rooms.forEach((r, i) => {
          ctx.fillStyle = r.color; ctx.globalAlpha = 0.7;
          ctx.fillRect(r.x, r.y, r.w, r.h); ctx.globalAlpha = 1;
          ctx.strokeStyle = i === selRoom ? textCol : dimCol;
          ctx.lineWidth = i === selRoom ? 2 : 1;
          ctx.strokeRect(r.x, r.y, r.w, r.h);
          ctx.fillStyle = textCol; ctx.font = '11px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
          ctx.fillText(r.name, r.x + r.w/2, r.y + r.h/2);
        });
        ctx.restore(); drawMinimap();
      }

      function drawMinimap() {
        miniCanvas.width = miniCanvas.clientWidth; miniCanvas.height = miniCanvas.clientHeight;
        miniCtx.clearRect(0, 0, miniCanvas.width, miniCanvas.height);
        if (!rooms.length) return;
        let mnX=Infinity, mnY=Infinity, mxX=-Infinity, mxY=-Infinity;
        rooms.forEach(r => { mnX=Math.min(mnX,r.x); mnY=Math.min(mnY,r.y); mxX=Math.max(mxX,r.x+r.w); mxY=Math.max(mxY,r.y+r.h); });
        const p=20, w=mxX-mnX+p*2, h=mxY-mnY+p*2, s=Math.min(miniCanvas.width/w, miniCanvas.height/h);
        const ox=(miniCanvas.width-w*s)/2-mnX*s+p*s, oy=(miniCanvas.height-h*s)/2-mnY*s+p*s;
        miniCtx.strokeStyle = '#555'; miniCtx.lineWidth = 1;
        connections.forEach(c => { const f=rooms.find(r=>r.id===c.from), t=rooms.find(r=>r.id===c.to); if(!f||!t) return; miniCtx.beginPath(); miniCtx.moveTo((f.x+f.w/2)*s+ox,(f.y+f.h/2)*s+oy); miniCtx.lineTo((t.x+t.w/2)*s+ox,(t.y+t.h/2)*s+oy); miniCtx.stroke(); });
        rooms.forEach((r,i) => { miniCtx.fillStyle=r.color; miniCtx.globalAlpha=0.8; miniCtx.fillRect(r.x*s+ox,r.y*s+oy,r.w*s,r.h*s); miniCtx.globalAlpha=1; if(i===selRoom) { miniCtx.strokeStyle='#fff'; miniCtx.lineWidth=1.5; miniCtx.strokeRect(r.x*s+ox,r.y*s+oy,r.w*s,r.h*s); } });
      }

      function updateList() {
        const list = document.getElementById('roomList'); list.innerHTML = '';
        rooms.forEach((r,i) => { const el=document.createElement('div'); el.className='room-item'+(i===selRoom?' sel':''); el.innerHTML='<div class="room-dot" style="background:'+r.color+'"></div><span>'+r.name+'</span>'; el.addEventListener('click',()=>{selRoom=i;draw();updateList();updateProps();}); list.appendChild(el); });
        const conns = document.getElementById('connectionList'); conns.innerHTML = '';
        connections.forEach((c,ci) => { const f=rooms.find(r=>r.id===c.from), t=rooms.find(r=>r.id===c.to); const el=document.createElement('div'); el.style.padding='2px 0'; el.innerHTML=(f?.name||'?')+' \\u2192 '+(t?.name||'?')+' <span style="cursor:pointer;color:var(--error);" data-ci="'+ci+'">x</span>'; el.querySelector('span').addEventListener('click',()=>{push();connections.splice(ci,1);draw();updateList();}); conns.appendChild(el); });
        document.getElementById('statusRooms').textContent = rooms.length + ' rooms';
        document.getElementById('statusConnections').textContent = connections.length + ' conn';
      }

      function updateProps() {
        const r=rooms[selRoom]; if(!r) return;
        document.getElementById('roomName').value=r.name; document.getElementById('roomW').value=r.w;
        document.getElementById('roomH').value=r.h; document.getElementById('roomColor').value=r.color;
        document.getElementById('roomBg').value=r.bg;
      }

      function s2w(sx,sy) { return {x:(sx-offX)/zoom, y:(sy-offY)/zoom}; }
      function findAt(wx,wy) { for(let i=rooms.length-1;i>=0;i--) { const r=rooms[i]; if(wx>=r.x&&wx<=r.x+r.w&&wy>=r.y&&wy<=r.y+r.h) return i; } return -1; }

      canvas.addEventListener('mousedown', e => {
        const rect=canvas.getBoundingClientRect(), sx=e.clientX-rect.left, sy=e.clientY-rect.top;
        if(e.button===1||(e.button===0&&e.altKey)){isPanning=true;panSX=sx-offX;panSY=sy-offY;return;}
        const {x:wx,y:wy}=s2w(sx,sy), hit=findAt(wx,wy);
        if(hit>=0){selRoom=hit;updateList();updateProps();if(mode==='move')dragging={i:hit,sx,sy,rx:rooms[hit].x,ry:rooms[hit].y};else connectFrom=hit;}
        draw();
      });
      canvas.addEventListener('mousemove', e => {
        const rect=canvas.getBoundingClientRect(), sx=e.clientX-rect.left, sy=e.clientY-rect.top;
        const {x:wx,y:wy}=s2w(sx,sy);
        document.getElementById('statusPos').textContent=Math.round(wx)+', '+Math.round(wy);
        if(isPanning){offX=sx-panSX;offY=sy-panSY;draw();return;}
        if(dragging){const dx=(sx-dragging.sx)/zoom,dy=(sy-dragging.sy)/zoom;rooms[dragging.i].x=gridSnap(dragging.rx+dx);rooms[dragging.i].y=gridSnap(dragging.ry+dy);draw();}
      });
      canvas.addEventListener('mouseup', e => {
        isPanning=false;
        if(dragging){push();dragging=null;draw();updateList();return;}
        if(connectFrom>=0&&mode==='connect'){const rect=canvas.getBoundingClientRect();const {x:wx,y:wy}=s2w(e.clientX-rect.left,e.clientY-rect.top);const hit=findAt(wx,wy);
        if(hit>=0&&hit!==connectFrom&&!connections.some(c=>c.from===rooms[connectFrom].id&&c.to===rooms[hit].id)){push();connections.push({from:rooms[connectFrom].id,to:rooms[hit].id});draw();updateList();}connectFrom=-1;}
      });
      canvas.addEventListener('wheel', e => { e.preventDefault(); zoom=Math.max(0.2,Math.min(3,zoom*(e.deltaY<0?1.1:0.9))); draw(); });

      document.getElementById('btnConnect').addEventListener('click',()=>{mode='connect';document.getElementById('btnConnect').classList.add('sel');document.getElementById('btnMove').classList.remove('sel');document.getElementById('statusMode').textContent='connect';});
      document.getElementById('btnMove').addEventListener('click',()=>{mode='move';document.getElementById('btnMove').classList.add('sel');document.getElementById('btnConnect').classList.remove('sel');document.getElementById('statusMode').textContent='move';});
      document.getElementById('snapGrid').addEventListener('change',e=>{snapOn=e.target.checked;});
      document.getElementById('btnZoomIn').addEventListener('click',()=>{zoom=Math.min(3,zoom*1.2);draw();});
      document.getElementById('btnZoomOut').addEventListener('click',()=>{zoom=Math.max(0.2,zoom/1.2);draw();});
      document.getElementById('btnFitAll').addEventListener('click',()=>{if(!rooms.length)return;let mnX=Infinity,mnY=Infinity,mxX=-Infinity,mxY=-Infinity;rooms.forEach(r=>{mnX=Math.min(mnX,r.x);mnY=Math.min(mnY,r.y);mxX=Math.max(mxX,r.x+r.w);mxY=Math.max(mxY,r.y+r.h);});const p=40,w=mxX-mnX+p*2,h=mxY-mnY+p*2;zoom=Math.min(canvas.width/w,canvas.height/h);offX=-mnX*zoom+p*zoom;offY=-mnY*zoom+p*zoom;draw();});
      document.getElementById('btnAddRoom').addEventListener('click',()=>{push();const cx=(canvas.width/2-offX)/zoom,cy=(canvas.height/2-offY)/zoom;rooms.push({id:nextId++,name:'Room '+rooms.length,x:gridSnap(cx),y:gridSnap(cy),w:120,h:80,color:'#2d5a88',bg:''});selRoom=rooms.length-1;draw();updateList();updateProps();});
      document.getElementById('btnRemoveRoom').addEventListener('click',()=>{if(!rooms.length)return;push();const rid=rooms[selRoom].id;rooms.splice(selRoom,1);connections=connections.filter(c=>c.from!==rid&&c.to!==rid);selRoom=Math.min(selRoom,rooms.length-1);draw();updateList();updateProps();});
      document.getElementById('roomName').addEventListener('change',e=>{if(rooms[selRoom]){push();rooms[selRoom].name=e.target.value;draw();updateList();}});
      document.getElementById('roomW').addEventListener('change',e=>{if(rooms[selRoom]){push();rooms[selRoom].w=parseInt(e.target.value);draw();}});
      document.getElementById('roomH').addEventListener('change',e=>{if(rooms[selRoom]){push();rooms[selRoom].h=parseInt(e.target.value);draw();}});
      document.getElementById('roomColor').addEventListener('input',e=>{if(rooms[selRoom]){push();rooms[selRoom].color=e.target.value;draw();updateList();}});
      document.getElementById('roomBg').addEventListener('change',e=>{if(rooms[selRoom]){push();rooms[selRoom].bg=e.target.value;}});
      document.getElementById('btnExport').addEventListener('click',()=>{
        let lua='return {\\n  rooms = {\\n';rooms.forEach(r=>{lua+='    { id = '+r.id+', name = "'+r.name+'", x = '+r.x+', y = '+r.y+', w = '+r.w+', h = '+r.h;if(r.bg)lua+=', background = "'+r.bg+'"';lua+=' },\\n';});
        lua+='  },\\n  connections = {\\n';connections.forEach(c=>{const f=rooms.find(r=>r.id===c.from),t=rooms.find(r=>r.id===c.to);lua+='    { from = "'+(f?.name||c.from)+'", to = "'+(t?.name||c.to)+'" },\\n';});
        lua+='  }\\n}';vscode.postMessage({type:'exportLua',content:lua});
      });
      window.addEventListener('resize',resizeCanvas); resizeCanvas(); updateList(); updateProps();
    `)}};var Zl=[{id:"tileMap",open:n=>gn.open(n)},{id:"sceneFlow",open:n=>hn.open(n)},{id:"ecs",open:n=>yn.open(n)},{id:"pixelArt",open:n=>fn.open(n)},{id:"particle",open:n=>bn.open(n)},{id:"dialog",open:n=>vn.open(n)},{id:"database",open:n=>Tn.open(n)},{id:"procMap",open:n=>wn.open(n)},{id:"questTree",open:n=>Pn.open(n)},{id:"guiWidget",open:n=>kn.open(n)},{id:"aiBehavior",open:n=>Mn.open(n)},{id:"graph",open:n=>Sn.open(n)},{id:"tilemapScript",open:n=>Cn.open(n)},{id:"voxel",open:n=>jn.open(n)},{id:"testRunner",open:n=>Rn.open(n)},{id:"apiReference",open:n=>En.open(n)},{id:"postfxOverlay",open:n=>Ln.open(n)},{id:"soundDsp",open:n=>In.open(n)},{id:"spriteAnim",open:n=>Dn.open(n)},{id:"tileset",open:n=>An.open(n)},{id:"audioMixer",open:n=>_n.open(n)},{id:"colorPalette",open:n=>Bn.open(n)},{id:"inputMapper",open:n=>Fn.open(n)},{id:"timeline",open:n=>zn.open(n)},{id:"shaderPreview",open:n=>Nn.open(n)},{id:"fontPreview",open:n=>On.open(n)},{id:"i18n",open:n=>Wn.open(n)},{id:"physicsMaterials",open:n=>Gn.open(n)},{id:"worldMap",open:n=>Hn.open(n)}];function Hi(n){return Zl.map(e=>Gi.commands.registerCommand(`lurek.editor.${e.id}`,()=>e.open(n)))}var G=C(require("vscode")),Vn=C(require("path")),Ce=C(require("fs"));Vt();async function qn(){let n=G.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!n){G.window.showErrorMessage("No workspace folder open.");return}let e=qe(n);if(!e||!Ce.existsSync(e)){G.window.showWarningMessage("API reference not found. Expected docs/api/lurek.lua or docs/api/lurek.md.");return}let t=Ce.readFileSync(e,"utf-8"),r=Ca(t,e);if(r.length===0){G.window.showInformationMessage("No API entries found.");return}let a=await G.window.showQuickPick(r.map(i=>({label:i.label,description:i.kind,line:i.line})),{placeHolder:"Search Lurek2D API...",matchOnDescription:!0});if(a){let i=await G.workspace.openTextDocument(e),s=await G.window.showTextDocument(i),o=typeof a.line=="number"?a.line:gr(t,e,a.label);if(o>=0){let l=new G.Position(o,0);s.selection=new G.Selection(l,l),s.revealRange(new G.Range(l,l))}}}async function Vi(){let n=G.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!n){G.window.showErrorMessage("No workspace folder open.");return}let e=qe(n);if(!e||!Ce.existsSync(e)){G.window.showWarningMessage("API reference not found. Expected docs/api/lurek.lua or docs/api/lurek.md.");return}let t=await G.workspace.openTextDocument(e);await G.window.showTextDocument(t)}async function qi(){let n=G.window.activeTextEditor,e=n?.document.getWordRangeAtPosition(n.selection.active,/lurek\.[a-zA-Z0-9_.]+/),t=e?n.document.getText(e):void 0,r=G.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!r){G.window.showErrorMessage("No workspace folder open.");return}let a=qe(r)??null;if(a){let i=Ce.readFileSync(a,"utf-8");if(t){let s=gr(i,a,t),o=await G.workspace.openTextDocument(a),l=await G.window.showTextDocument(o),p=new G.Position(Math.max(0,s),0);l.selection=new G.Selection(p,p),l.revealRange(new G.Range(p,p),G.TextEditorRevealType.InCenter),s<0&&G.window.showInformationMessage(`"${t}" not found in API docs \u2014 showing full reference.`)}else{let s=await G.workspace.openTextDocument(a);await G.window.showTextDocument(s)}}else await qn()}function Or(n){let e=G.workspace.workspaceFolders?.[0]?.uri.fsPath,t=G.window.createWebviewPanel("lurek.depGraph","Lurek2D Module Dependency Graph",G.ViewColumn.One,{enableScripts:!0,retainContextWhenHidden:!0}),r=[],a=[],i={math:"leaf",engine:"core",lua_api:"integration",window:"core",graphics:"domain",physics:"domain",audio:"domain",input:"domain",timer:"domain",filesystem:"domain",tilemap:"domain",sound:"domain",ai:"domain",compute:"domain",data:"domain",dataframe:"domain",entity:"domain",event:"domain",graph:"domain",image:"domain",modding:"domain",particle:"domain",savegame:"domain",scene:"domain",stats:"domain",thread:"domain",pathfinding:"domain",dialog:"domain",cardgame:"domain",combat:"domain",crafting:"domain",inventory:"domain",quest:"domain",resource:"domain"};if(e){let p=Vn.join(e,"src");if(Ce.existsSync(p)){let u=Ce.readdirSync(p,{withFileTypes:!0}).filter(d=>d.isDirectory()).map(d=>d.name);for(let d of u)r.push({id:d,tier:i[d]??"domain"});for(let d of u){let m=Vn.join(p,d,"mod.rs"),h=Vn.join(p,d,"lib.rs"),f=Ce.existsSync(m)?m:Ce.existsSync(h)?h:null;if(f)try{let y=[...Ce.readFileSync(f,"utf-8").matchAll(/use crate::([a-z_]+)/g)],P=new Set;for(let v of y){let x=v[1];x!==d&&u.includes(x)&&!P.has(x)&&(P.add(x),a.push({from:d,to:x}))}}catch{}}}}if(r.length===0){for(let[u,d]of Object.entries(i))r.push({id:u,tier:d});let p=[{from:"engine",to:"math"},{from:"render",to:"math"},{from:"physics",to:"math"},{from:"audio",to:"math"},{from:"input",to:"math"},{from:"timer",to:"math"},{from:"lua_api",to:"engine"},{from:"lua_api",to:"render"},{from:"lua_api",to:"physics"},{from:"lua_api",to:"audio"},{from:"lua_api",to:"input"},{from:"lua_api",to:"timer"},{from:"lua_api",to:"filesystem"},{from:"lua_api",to:"tilemap"},{from:"lua_api",to:"ai"},{from:"lua_api",to:"ecs"},{from:"lua_api",to:"scene"},{from:"lua_api",to:"particle"}];a.push(...p)}let s=ep(),o=JSON.stringify(r),l=JSON.stringify(a);t.webview.html=`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'nonce-${s}'; style-src 'nonce-${s}';">
<title>Module Dependency Graph</title>
<style nonce="${s}">
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: var(--vscode-font-family); background: var(--vscode-editor-background); color: var(--vscode-foreground); overflow: hidden; height: 100vh; }
  #toolbar { display: flex; align-items: center; gap: 10px; padding: 8px 12px; border-bottom: 1px solid var(--vscode-panel-border,#444); flex-wrap: wrap; font-size: 12px; }
  #toolbar button { font-size: 11px; padding: 3px 10px; background: var(--vscode-button-background); color: var(--vscode-button-foreground); border: none; border-radius: 3px; cursor: pointer; }
  #toolbar button:hover { background: var(--vscode-button-hoverBackground); }
  #info { flex: 1; opacity: .6; }
  canvas { display: block; }
  #legend { display: flex; gap: 12px; align-items: center; }
  .dot { width: 10px; height: 10px; border-radius: 50%; display: inline-block; margin-right: 3px; }
  .dot.leaf { background: #4ec9b0; }
  .dot.core { background: #569cd6; }
  .dot.integration { background: #dcdcaa; }
  .dot.domain { background: #9cdcfe; }
  #tooltip { position: fixed; background: var(--vscode-editorHoverWidget-background,#252526); border: 1px solid var(--vscode-panel-border,#444); border-radius: 4px; padding: 6px 10px; font-size: 11px; pointer-events: none; display: none; max-width: 220px; }
</style>
</head>
<body>
<div id="toolbar">
  <button id="btnLayout">Re-layout</button>
  <button id="btnZoomIn">\uFF0B Zoom</button>
  <button id="btnZoomOut">\uFF0D Zoom</button>
  <button id="btnReset">Reset View</button>
  <div id="legend">
    <span class="dot leaf"></span>Leaf
    <span class="dot core"></span>Core
    <span class="dot integration"></span>Integration
    <span class="dot domain"></span>Domain
  </div>
  <div id="info">Click a node to see its edges</div>
</div>
<canvas id="c"></canvas>
<div id="tooltip"></div>
<script nonce="${s}">
const NODES = ${o};
const EDGES = ${l};

const COLORS = { leaf:'#4ec9b0', core:'#569cd6', integration:'#dcdcaa', domain:'#9cdcfe' };
const canvas = document.getElementById('c');
const ctx = canvas.getContext('2d');
const tooltip = document.getElementById('tooltip');

let W, H, dragging = null, dragOffX = 0, dragOffY = 0;
let panX = 0, panY = 0, scale = 1, panning = false, panStartX = 0, panStartY = 0;
let selectedNode = null;

// Node positions (force-directed layout)
const pos = {};
function randomLayout() {
  const cx = W / 2, cy = H / 2, r = Math.min(W, H) * 0.38;
  NODES.forEach((n, i) => {
    const angle = (i / NODES.length) * Math.PI * 2;
    pos[n.id] = { x: cx + Math.cos(angle) * r * (0.5 + Math.random() * 0.5), y: cy + Math.sin(angle) * r * (0.5 + Math.random() * 0.5), vx: 0, vy: 0 };
  });
}

function resize() {
  W = canvas.width = window.innerWidth;
  H = canvas.height = window.innerHeight - document.getElementById('toolbar').offsetHeight;
  if (Object.keys(pos).length === 0) randomLayout();
}

function applyForces() {
  const k = 120, repel = 18000, damp = 0.85;
  NODES.forEach(a => {
    NODES.forEach(b => {
      if (a.id === b.id) return;
      const dx = pos[a.id].x - pos[b.id].x, dy = pos[a.id].y - pos[b.id].y;
      const d = Math.max(Math.sqrt(dx*dx+dy*dy), 1);
      const f = repel / (d*d);
      pos[a.id].vx += (dx/d)*f; pos[a.id].vy += (dy/d)*f;
    });
  });
  EDGES.forEach(e => {
    if (!pos[e.from] || !pos[e.to]) return;
    const dx = pos[e.to].x - pos[e.from].x, dy = pos[e.to].y - pos[e.from].y;
    const d = Math.max(Math.sqrt(dx*dx+dy*dy), 1);
    const f = (d - k) * 0.05;
    const fx = (dx/d)*f, fy = (dy/d)*f;
    pos[e.from].vx += fx; pos[e.from].vy += fy;
    pos[e.to].vx -= fx; pos[e.to].vy -= fy;
  });
  NODES.forEach(n => {
    pos[n.id].vx = (pos[n.id].vx + (W/2 - pos[n.id].x) * 0.005) * damp;
    pos[n.id].vy = (pos[n.id].vy + (H/2 - pos[n.id].y) * 0.005) * damp;
    pos[n.id].x += pos[n.id].vx; pos[n.id].y += pos[n.id].vy;
  });
}

let simSteps = 0;
function simulate(steps = 200) { simSteps = steps; }

const R = 28;
function draw() {
  if (simSteps > 0) { applyForces(); simSteps--; }
  ctx.setTransform(1,0,0,1,0,0);
  ctx.clearRect(0,0,W,H);
  ctx.setTransform(scale,0,0,scale,panX,panY);

  // Edges
  EDGES.forEach(e => {
    const a = pos[e.from], b = pos[e.to];
    if (!a || !b) return;
    const isHighlight = selectedNode && (e.from === selectedNode || e.to === selectedNode);
    ctx.globalAlpha = isHighlight ? 1 : (selectedNode ? 0.15 : 0.5);
    ctx.strokeStyle = isHighlight ? '#e8bf4a' : '#555';
    ctx.lineWidth = isHighlight ? 2 : 1;
    ctx.beginPath();
    ctx.moveTo(a.x, a.y);
    // Arrow
    const dx = b.x-a.x, dy = b.y-a.y, len = Math.sqrt(dx*dx+dy*dy);
    const ux = dx/len, uy = dy/len;
    const ex = b.x - ux*R, ey = b.y - uy*R;
    ctx.lineTo(ex, ey);
    ctx.stroke();
    // Arrowhead
    ctx.globalAlpha = isHighlight ? 1 : (selectedNode ? 0.1 : 0.4);
    ctx.fillStyle = isHighlight ? '#e8bf4a' : '#777';
    ctx.beginPath();
    const ax2 = ex - ux*8+uy*5, ay2 = ey - uy*8-ux*5;
    const bx2 = ex - ux*8-uy*5, by2 = ey - uy*8+ux*5;
    ctx.moveTo(ex,ey); ctx.lineTo(ax2,ay2); ctx.lineTo(bx2,by2); ctx.closePath(); ctx.fill();
  });

  // Nodes
  ctx.globalAlpha = 1;
  NODES.forEach(n => {
    const p = pos[n.id]; if (!p) return;
    const dimmed = selectedNode && selectedNode !== n.id && !EDGES.some(e => e.from===n.id&&e.to===selectedNode||e.from===selectedNode&&e.to===n.id);
    ctx.globalAlpha = dimmed ? 0.25 : 1;
    ctx.beginPath(); ctx.arc(p.x, p.y, R, 0, Math.PI*2);
    ctx.fillStyle = COLORS[n.tier] || '#9cdcfe';
    ctx.fill();
    ctx.strokeStyle = selectedNode === n.id ? '#fff' : '#0004';
    ctx.lineWidth = selectedNode === n.id ? 2.5 : 1;
    ctx.stroke();
    ctx.fillStyle = '#111'; ctx.font = 'bold 10px monospace'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.fillText(n.id.length>9 ? n.id.slice(0,8)+'\u2026' : n.id, p.x, p.y);
  });
  ctx.globalAlpha = 1;
  requestAnimationFrame(draw);
}

function nodeAt(mx, my) {
  const wx = (mx - panX) / scale, wy = (my - panY) / scale;
  return NODES.find(n => { const p = pos[n.id]; return p && Math.sqrt((wx-p.x)**2+(wy-p.y)**2) < R; });
}

canvas.addEventListener('mousedown', e => {
  const n = nodeAt(e.clientX, e.clientY - document.getElementById('toolbar').offsetHeight);
  if (n) { dragging = n.id; dragOffX = (e.clientX - panX)/scale - pos[n.id].x; dragOffY = ((e.clientY - document.getElementById('toolbar').offsetHeight) - panY)/scale - pos[n.id].y; }
  else { panning = true; panStartX = e.clientX - panX; panStartY = e.clientY - panY; }
});
canvas.addEventListener('mousemove', e => {
  const cy = e.clientY - document.getElementById('toolbar').offsetHeight;
  if (dragging) {
    pos[dragging].x = (e.clientX - panX)/scale - dragOffX;
    pos[dragging].y = (cy - panY)/scale - dragOffY;
    pos[dragging].vx = 0; pos[dragging].vy = 0;
  } else if (panning) {
    panX = e.clientX - panStartX; panY = e.clientY - panStartY;
  } else {
    const n = nodeAt(e.clientX, cy);
    if (n) {
      const deps = EDGES.filter(ed=>ed.from===n.id).map(ed=>ed.to);
      const rdeps = EDGES.filter(ed=>ed.to===n.id).map(ed=>ed.from);
      tooltip.style.display = 'block'; tooltip.style.left = (e.clientX+12)+'px'; tooltip.style.top = (e.clientY-30)+'px';
      tooltip.innerHTML = '<b>'+n.id+'</b> ('+n.tier+')<br>\u2192 '+( deps.length ? deps.join(', ') : 'none')+'<br>\u2190 '+(rdeps.length ? rdeps.join(', ') : 'none');
    } else { tooltip.style.display = 'none'; }
  }
});
canvas.addEventListener('mouseup', e => {
  const cy = e.clientY - document.getElementById('toolbar').offsetHeight;
  if (!dragging && !panning) {
    const n = nodeAt(e.clientX, cy);
    selectedNode = n ? (selectedNode === n.id ? null : n.id) : null;
    const info = document.getElementById('info');
    if (selectedNode) {
      const deps = EDGES.filter(ed=>ed.from===selectedNode).map(ed=>ed.to);
      const rdeps = EDGES.filter(ed=>ed.to===selectedNode).map(ed=>ed.from);
      info.textContent = selectedNode + ' \u2192 ['+deps.join(', ')+']  \u2190 ['+rdeps.join(', ')+']';
    } else { info.textContent = 'Click a node to see its edges'; }
  }
  dragging = null; panning = false;
});
canvas.addEventListener('wheel', e => {
  e.preventDefault();
  const factor = e.deltaY < 0 ? 1.1 : 0.9;
  const cy = e.clientY - document.getElementById('toolbar').offsetHeight;
  panX = e.clientX - (e.clientX - panX) * factor;
  panY = cy - (cy - panY) * factor;
  scale *= factor;
}, { passive: false });

document.getElementById('btnLayout').onclick = () => { randomLayout(); simulate(300); };
document.getElementById('btnZoomIn').onclick = () => { panX = W/2-(W/2-panX)*1.2; panY = H/2-(H/2-panY)*1.2; scale *= 1.2; };
document.getElementById('btnZoomOut').onclick = () => { panX = W/2-(W/2-panX)*0.8; panY = H/2-(H/2-panY)*0.8; scale *= 0.8; };
document.getElementById('btnReset').onclick = () => { panX=0;panY=0;scale=1; randomLayout(); simulate(300); };

window.addEventListener('resize', resize);
resize();
simulate(400);
draw();
</script>
</body>
</html>`}function $i(){let n=G.window.createTerminal("Lurek2D Deps");n.show(),n.sendText("cargo tree --depth 1")}function ep(){let n="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",e="";for(let t=0;t<32;t++)e+=n.charAt(Math.floor(Math.random()*n.length));return e}var J=C(require("vscode")),je=C(require("path")),ye=C(require("fs"));async function Ui(){let n=J.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!n){J.window.showErrorMessage("No workspace folder open.");return}let e=null,t=__dirname;for(let s=0;s<6;s++){let o=je.join(t,".github");if(ye.existsSync(o)){e=o;break}t=je.dirname(t)}if(!e){J.window.showErrorMessage("Could not locate engine .github/ folder. Make sure the extension is run from the lurek2d repository root.");return}let r=je.join(n,".github");if(ye.existsSync(r)&&await J.window.showWarningMessage(".github/ directory already exists in your workspace. Overwrite all CAG files?","Yes \u2014 Overwrite","Cancel")!=="Yes \u2014 Overwrite")return;let a=0;function i(s,o){ye.mkdirSync(o,{recursive:!0});for(let l of ye.readdirSync(s,{withFileTypes:!0})){let p=je.join(s,l.name),u=je.join(o,l.name);l.isDirectory()?i(p,u):(ye.copyFileSync(p,u),a++)}}try{i(e,r),J.window.showInformationMessage(`\u2705 CAG installed: ${a} file(s) copied to .github/`)}catch(s){J.window.showErrorMessage(`CAG install failed: ${s}`)}}async function Yi(){let n=await Ji("agents","*.agent.md");if(n.length===0){J.window.showWarningMessage("No agent definitions found.");return}let e=await J.window.showQuickPick(n,{placeHolder:"Select an agent"});if(e){let t=J.workspace.workspaceFolders?.[0]?.uri.fsPath;if(t){let r=je.join(t,".github","agents",e);if(ye.existsSync(r)){let a=await J.workspace.openTextDocument(r);await J.window.showTextDocument(a)}}}}async function Xi(){let n=J.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!n){J.window.showErrorMessage("No workspace folder open.");return}let e=je.join(n,".github","skills");if(!ye.existsSync(e)){J.window.showWarningMessage("No skills directory found.");return}let t=ye.readdirSync(e,{withFileTypes:!0}).filter(a=>a.isDirectory()).map(a=>a.name);if(t.length===0){J.window.showWarningMessage("No skills found.");return}let r=await J.window.showQuickPick(t,{placeHolder:"Select a skill"});if(r){let a=je.join(e,r,"SKILL.md");if(ye.existsSync(a)){let i=await J.workspace.openTextDocument(a);await J.window.showTextDocument(i)}}}async function Qi(){let n=await Ji("prompts","*.prompt.md");if(n.length===0){J.window.showWarningMessage("No prompts found.");return}let e=await J.window.showQuickPick(n,{placeHolder:"Select a prompt"});if(e){let t=J.workspace.workspaceFolders?.[0]?.uri.fsPath;if(t){let r=je.join(t,".github","prompts",e);if(ye.existsSync(r)){let a=await J.workspace.openTextDocument(r);await J.window.showTextDocument(a)}}}}async function Ji(n,e){let t=J.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!t)return[];let r=je.join(t,".github",n);if(!ye.existsSync(r))return[];try{return ye.readdirSync(r,{withFileTypes:!0}).filter(a=>a.isFile()&&a.name.endsWith(".md")).map(a=>a.name)}catch{return[]}}var O=C(require("vscode")),ie=C(require("path")),pe=C(require("fs"));function Wr(n){let e=[],t=new Set,r=/lurek\.(\w+)\.(\w+)\s*\(/g;for(let[a,i]of n.split(`
`).entries()){let s;for(r.lastIndex=0;(s=r.exec(i))!==null;){let o=s[1],l=s[2],p=`${o}.${l}`;t.has(p)||(t.add(p),e.push({module:o,func:l,line:a+1,text:i.trim()}))}}return e}function tp(n){let e=[],t=n.split(`
`),r=/^(?:local\s+)?function\s+([\w.:]+)\s*\(/;for(let a=0;a<t.length;a++){let i=r.exec(t[a]);if(i){let s=i[1],o=a,l=1,p=a+1;for(;p<t.length&&l>0;p++){let u=t[p].trim();/^(?:function|if|for|while|repeat)\b/.test(u)&&!u.endsWith("end")&&l++,/^end\b/.test(u)&&l--}e.push({name:s,line:o+1,endLine:p,body:t.slice(o,p).join(`
`)})}}return e}function np(n,e){let t=[`-- Auto-generated tests for ${n}`,"-- Generated by Lurek2D Toolkit","","local passed = 0","local failed = 0","local total = 0","","local function test(name, fn)","  total = total + 1","  local ok, err = pcall(fn)","  if ok then","    passed = passed + 1",'    print("[PASS] " .. name)',"  else","    failed = failed + 1",'    print("[FAIL] " .. name .. ": " .. tostring(err))',"  end","end",""],r=new Map;for(let a of e){let i=r.get(a.module)??[];i.push(a),r.set(a.module,i)}for(let[a,i]of r){t.push(`-- Tests for lurek.${a}`,"");for(let s of i)t.push(`test("lurek.${a}.${s.func} works", function()`,`  -- Source line ${s.line}: ${s.text}`,"  -- TODO: Add proper test assertion",`  local result = lurek.${a}.${s.func}()`,`  assert(result ~= nil, "lurek.${a}.${s.func} should return a value")`,"end)","")}return t.push("-- Summary",'print(string.format("\\n%d/%d tests passed (%d failed)", passed, total, failed))',"if failed > 0 then",'  error(string.format("%d tests failed", failed))',"end",""),t.join(`
`)}function rp(n,e,t){let r=Wr(t),a=[`-- Tests for function: ${e}`,`-- Source: ${n}`,"-- Generated by Lurek2D Toolkit","","local passed = 0","local failed = 0","local total = 0","","local function test(name, fn)","  total = total + 1","  local ok, err = pcall(fn)","  if ok then","    passed = passed + 1",'    print("[PASS] " .. name)',"  else","    failed = failed + 1",'    print("[FAIL] " .. name .. ": " .. tostring(err))',"  end","end","","-- Basic existence test",`test("${e} is defined", function()`,`  assert(type(${e}) == "function", "${e} should be a function")`,"end)","","-- Call test",`test("${e} can be called", function()`,"  -- TODO: Provide appropriate arguments",`  local ok, err = pcall(${e})`,"  -- Adjust based on expected behavior","end)",""];if(r.length>0){a.push("-- API dependency tests");for(let i of r)a.push(`test("${e} uses lurek.${i.module}.${i.func}", function()`,`  -- Verify lurek.${i.module}.${i.func} is available`,`  assert(type(lurek.${i.module}.${i.func}) == "function",`,`    "lurek.${i.module}.${i.func} should be available")`,"end)","")}return a.push("-- Summary",'print(string.format("\\n%d/%d tests passed (%d failed)", passed, total, failed))',"if failed > 0 then",'  error(string.format("%d tests failed", failed))',"end",""),a.join(`
`)}function _t(n){let e=ie.dirname(n);for(let t=0;t<10;t++){if(pe.existsSync(ie.join(e,"main.lua"))||pe.existsSync(ie.join(e,"conf.lua")))return e;let r=ie.dirname(e);if(r===e)break;e=r}return O.workspace.workspaceFolders?.[0]?.uri.fsPath}function Zi(n){n.subscriptions.push(O.commands.registerCommand("lurek.test.generateForFile",async()=>{let e=O.window.activeTextEditor;if(!e||e.document.languageId!=="lua"){O.window.showWarningMessage("Open a Lua file first.");return}let t=e.document,r=t.getText(),a=Wr(r);if(a.length===0){O.window.showInformationMessage("No lurek.* API calls detected in this file.");return}let i=ie.basename(t.fileName),s=_t(t.fileName);if(!s){O.window.showErrorMessage("Could not determine game root directory.");return}let o=ie.join(s,"tests");pe.existsSync(o)||pe.mkdirSync(o,{recursive:!0});let l=`test_${i}`,p=ie.join(o,l),u=np(i,a);pe.writeFileSync(p,u,"utf-8");let d=await O.workspace.openTextDocument(p);await O.window.showTextDocument(d),O.window.showInformationMessage(`Generated test file: tests/${l} (${a.length} API calls detected)`)})),n.subscriptions.push(O.commands.registerCommand("lurek.test.generateForFunction",async()=>{let e=O.window.activeTextEditor;if(!e||e.document.languageId!=="lua"){O.window.showWarningMessage("Open a Lua file first.");return}let t=e.document,r=t.getText(),a=e.selection.active.line+1,s=tp(r).find(S=>a>=S.line&&a<=S.endLine);if(!s){O.window.showWarningMessage("No function found at cursor position.");return}let o=ie.basename(t.fileName),l=_t(t.fileName);if(!l){O.window.showErrorMessage("Could not determine game root directory.");return}let p=ie.join(l,"tests");pe.existsSync(p)||pe.mkdirSync(p,{recursive:!0});let d=`test_${s.name.replace(/[.:]/g,"_")}.lua`,m=ie.join(p,d),h=rp(o,s.name,s.body);pe.writeFileSync(m,h,"utf-8");let f=await O.workspace.openTextDocument(m);await O.window.showTextDocument(f),O.window.showInformationMessage(`Generated test file: tests/${d} for ${s.name}()`)})),n.subscriptions.push(O.commands.registerCommand("lurek.test.runCurrent",async()=>{let e=O.window.activeTextEditor;if(!e||e.document.languageId!=="lua"){O.window.showWarningMessage("Open a Lua test file first.");return}let t=e.document.fileName,r=_t(t);if(!r){O.window.showErrorMessage("Could not determine game root directory.");return}let a=O.workspace.getConfiguration("lurek").get("enginePath","lurek2d"),i=Ki("Lurek2D Tests");i.show();let s=ie.relative(r,t).replace(/\\/g,"/");i.sendText(`cd "${r}" && "${a}" --test "${s}"`)})),n.subscriptions.push(O.commands.registerCommand("lurek.test.runAll",async()=>{let e=O.window.activeTextEditor,t=e?_t(e.document.fileName):O.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!t){O.window.showErrorMessage("No game project found.");return}let r=ie.join(t,"tests");if(!pe.existsSync(r)){O.window.showWarningMessage("No tests/ directory found in the game project.");return}let a=pe.readdirSync(r).filter(l=>l.endsWith(".lua"));if(a.length===0){O.window.showWarningMessage("No Lua test files found in tests/.");return}let i=O.window.createOutputChannel("Lurek2D Test Results");i.show(),i.appendLine(`Running ${a.length} test file(s)...`),i.appendLine("\u2500".repeat(50));let s=O.workspace.getConfiguration("lurek").get("enginePath","lurek2d"),o=Ki("Lurek2D Tests");o.show();for(let l of a)i.appendLine(`
Running: ${l}`),o.sendText(`cd "${t}" && "${s}" --test "tests/${l}"`);i.appendLine(`
`+"\u2500".repeat(50)),i.appendLine(`Queued ${a.length} test files.`)})),n.subscriptions.push(O.commands.registerCommand("lurek.test.coverage",async()=>{let e=O.window.activeTextEditor,t=e?_t(e.document.fileName):O.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!t){O.window.showErrorMessage("No game project found.");return}let r=es(t),a=new Set,i=new Set;for(let l of r){let p=pe.readFileSync(l,"utf-8"),u=Wr(p),d=l.includes(`${ie.sep}tests${ie.sep}`)||ie.basename(l).startsWith("test_");for(let m of u){let h=`lurek.${m.module}.${m.func}`;a.add(h),d&&i.add(h)}}let s=O.window.createOutputChannel("Lurek2D API Coverage");s.show(),s.appendLine("Lurek2D API Coverage Report"),s.appendLine("\u2550".repeat(50)),s.appendLine(`Total API calls used: ${a.size}`),s.appendLine(`Covered by tests:     ${i.size}`);let o=a.size>0?Math.round(i.size/a.size*100):0;if(s.appendLine(`Coverage:             ${o}%`),s.appendLine(""),a.size>i.size){s.appendLine("Untested API calls:");for(let l of[...a].sort())i.has(l)||s.appendLine(`  \u26A0 ${l}`)}s.appendLine(""),s.appendLine("Tested API calls:");for(let l of[...i].sort())s.appendLine(`  \u2713 ${l}`)}))}function es(n,e=[]){if(!pe.existsSync(n))return e;let t=pe.readdirSync(n,{withFileTypes:!0});for(let r of t){let a=ie.join(n,r.name);r.isDirectory()&&r.name!=="node_modules"&&r.name!==".git"?es(a,e):r.isFile()&&r.name.endsWith(".lua")&&e.push(a)}return e}function Ki(n){let e=O.window.terminals.find(t=>t.name===n);return e||O.window.createTerminal(n)}Gr();gt();var V=C(require("vscode"));function as(n,e){n.subscriptions.push(V.commands.registerCommand("lurek.debug.connect",async()=>{if(e.isConnected){V.window.showInformationMessage("Already connected to Lurek2D engine.");return}let t=await V.window.showInputBox({prompt:"Debug bridge port",value:String(V.workspace.getConfiguration("lurek.debugBridge").get("port",19740)),validateInput:a=>{let i=Number(a);if(isNaN(i)||i<1024||i>65535)return"Port must be 1024\u201365535"}});if(t===void 0)return;e.showOutput(),await e.connect(Number(t))?(V.window.showInformationMessage("Connected to Lurek2D engine."),V.commands.executeCommand("setContext","lurek.debugConnected",!0)):V.window.showErrorMessage("Failed to connect. Is the engine running with debug bridge enabled?")})),n.subscriptions.push(V.commands.registerCommand("lurek.debug.disconnect",()=>{e.disconnect(),V.commands.executeCommand("setContext","lurek.debugConnected",!1),V.window.showInformationMessage("Disconnected from Lurek2D engine.")})),n.subscriptions.push(V.commands.registerCommand("lurek.debug.evaluate",async()=>{if(!e.isConnected){V.window.showErrorMessage("Not connected to Lurek2D engine. Run 'Lurek2D: Debug Connect' first.");return}let t=await V.window.showInputBox({prompt:"Lua expression to evaluate",placeHolder:'e.g. print("hello") or player.x'});if(t)try{let r=await e.evaluate(t);e.showOutput(),V.window.showInformationMessage(`Result: ${r}`)}catch(r){V.window.showErrorMessage(`Evaluation failed: ${r instanceof Error?r.message:String(r)}`)}})),n.subscriptions.push(V.commands.registerCommand("lurek.debug.hotReload",async()=>{if(!e.isConnected){V.window.showErrorMessage("Not connected to Lurek2D engine.");return}let t=V.window.activeTextEditor;if(!t||t.document.languageId!=="lua"){V.window.showWarningMessage("Open a Lua file to hot-reload.");return}t.document.isDirty&&await t.document.save();try{await e.hotReload(t.document.uri)?V.window.showInformationMessage(`Hot-reloaded: ${V.workspace.asRelativePath(t.document.uri)}`):V.window.showErrorMessage("Hot-reload failed. Check debug output for details.")}catch(r){V.window.showErrorMessage(`Hot-reload error: ${r instanceof Error?r.message:String(r)}`)}})),n.subscriptions.push(V.commands.registerCommand("lurek.debug.showStats",async()=>{if(!e.isConnected){V.window.showErrorMessage("Not connected to Lurek2D engine.");return}e.startStatsPolling(),V.window.showInformationMessage("Engine stats enabled in status bar.")})),n.subscriptions.push(V.commands.registerCommand("lurek.debug.inspect",async()=>{if(!e.isConnected){V.window.showErrorMessage("Not connected to Lurek2D engine.");return}let t=V.window.activeTextEditor;if(!t){V.window.showWarningMessage("No active editor.");return}let r=t.selection,a;if(!r.isEmpty)a=t.document.getText(r);else{let i=t.document.getWordRangeAtPosition(r.active,/[\w.:\[\]]+/);if(!i){V.window.showWarningMessage("No variable found at cursor.");return}a=t.document.getText(i)}try{let i=await e.evaluate(`return tostring(${a})`),s=await e.evaluate(`return type(${a})`);V.window.showInformationMessage(`${a} = ${i} (${s})`)}catch(i){V.window.showErrorMessage(`Failed to inspect '${a}': ${i instanceof Error?i.message:String(i)}`)}}))}var q=C(require("vscode")),Ae=C(require("path")),se=C(require("fs")),sp=[{label:"Platformer",description:"Side-scrolling platformer with jump physics",confLua:`function lurek.conf(t)
  t.window.title = "My Platformer"
  t.window.width = 800
  t.window.height = 600
end
`,mainLua:`-- Platformer Starter
local player = { x = 100, y = 400, w = 32, h = 48, vy = 0, speed = 200, jumping = false }
local gravity = 980
local jumpForce = -450
local ground = 500

function lurek.load()
  lurek.window.setTitle("My Platformer")
end

function lurek.update(dt)
  -- Horizontal movement
  if lurek.input.keyboard.isDown("left") or lurek.input.keyboard.isDown("a") then
    player.x = player.x - player.speed * dt
  end
  if lurek.input.keyboard.isDown("right") or lurek.input.keyboard.isDown("d") then
    player.x = player.x + player.speed * dt
  end

  -- Gravity
  player.vy = player.vy + gravity * dt
  player.y = player.y + player.vy * dt

  -- Ground collision
  if player.y + player.h >= ground then
    player.y = ground - player.h
    player.vy = 0
    player.jumping = false
  end
end

function lurek.keypressed(key)
  if key == "space" and not player.jumping then
    player.vy = jumpForce
    player.jumping = true
  end
  if key == "escape" then
    lurek.event.quit()
  end
end

function lurek.draw()
  -- Sky
  lurek.graphics.setBackgroundColor(0.4, 0.7, 1.0)

  -- Ground
  lurek.graphics.setColor(0.3, 0.6, 0.2)
  lurek.graphics.rectangle("fill", 0, ground, 800, 100)

  -- Player
  lurek.graphics.setColor(0.2, 0.4, 0.9)
  lurek.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

  -- HUD
  lurek.graphics.setColor(1, 1, 1)
  lurek.graphics.print("Arrow keys / WASD to move, Space to jump", 10, 10)
end
`},{label:"Top-Down RPG",description:"Tile-based RPG with 4-directional movement",confLua:`function lurek.conf(t)
  t.window.title = "My RPG"
  t.window.width = 640
  t.window.height = 480
end
`,mainLua:`-- Top-Down RPG Starter
local player = { x = 320, y = 240, w = 32, h = 32, speed = 150, dir = "down" }
local map_w, map_h = 20, 15
local tile_size = 32

function lurek.load()
  lurek.window.setTitle("My RPG")
end

function lurek.update(dt)
  local dx, dy = 0, 0

  if lurek.input.keyboard.isDown("up") or lurek.input.keyboard.isDown("w") then
    dy = -1
    player.dir = "up"
  elseif lurek.input.keyboard.isDown("down") or lurek.input.keyboard.isDown("s") then
    dy = 1
    player.dir = "down"
  end

  if lurek.input.keyboard.isDown("left") or lurek.input.keyboard.isDown("a") then
    dx = -1
    player.dir = "left"
  elseif lurek.input.keyboard.isDown("right") or lurek.input.keyboard.isDown("d") then
    dx = 1
    player.dir = "right"
  end

  -- Normalize diagonal movement
  if dx ~= 0 and dy ~= 0 then
    local len = math.sqrt(dx * dx + dy * dy)
    dx = dx / len
    dy = dy / len
  end

  player.x = player.x + dx * player.speed * dt
  player.y = player.y + dy * player.speed * dt

  -- Clamp to map bounds
  player.x = math.max(0, math.min(player.x, map_w * tile_size - player.w))
  player.y = math.max(0, math.min(player.y, map_h * tile_size - player.h))
end

function lurek.keypressed(key)
  if key == "escape" then
    lurek.event.quit()
  end
end

function lurek.draw()
  lurek.graphics.setBackgroundColor(0.15, 0.15, 0.2)

  -- Draw grid
  lurek.graphics.setColor(0.25, 0.25, 0.3)
  for x = 0, map_w - 1 do
    for y = 0, map_h - 1 do
      lurek.graphics.rectangle("line", x * tile_size, y * tile_size, tile_size, tile_size)
    end
  end

  -- Player
  lurek.graphics.setColor(0.2, 0.8, 0.3)
  lurek.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

  -- Direction indicator
  lurek.graphics.setColor(1, 1, 1)
  local cx, cy = player.x + player.w / 2, player.y + player.h / 2
  local indicators = { up = {0, -8}, down = {0, 8}, left = {-8, 0}, right = {8, 0} }
  local ind = indicators[player.dir]
  lurek.graphics.circle("fill", cx + ind[1], cy + ind[2], 4)

  -- HUD
  lurek.graphics.setColor(1, 1, 1)
  lurek.graphics.print("WASD / Arrow keys to move", 10, 10)
end
`},{label:"Shooter",description:"Top-down shooter with projectiles",confLua:`function lurek.conf(t)
  t.window.title = "My Shooter"
  t.window.width = 800
  t.window.height = 600
end
`,mainLua:`-- Shooter Starter
local player = { x = 400, y = 500, w = 24, h = 24, speed = 250 }
local bullets = {}
local enemies = {}
local score = 0
local shoot_timer = 0
local shoot_cooldown = 0.2
local spawn_timer = 0
local spawn_rate = 1.5

function lurek.load()
  lurek.window.setTitle("My Shooter")
end

function lurek.update(dt)
  -- Player movement
  if lurek.input.keyboard.isDown("left") or lurek.input.keyboard.isDown("a") then
    player.x = player.x - player.speed * dt
  end
  if lurek.input.keyboard.isDown("right") or lurek.input.keyboard.isDown("d") then
    player.x = player.x + player.speed * dt
  end
  player.x = math.max(0, math.min(player.x, 800 - player.w))

  -- Shooting
  shoot_timer = shoot_timer - dt
  if lurek.input.keyboard.isDown("space") and shoot_timer <= 0 then
    table.insert(bullets, { x = player.x + player.w / 2 - 2, y = player.y - 8, w = 4, h = 8 })
    shoot_timer = shoot_cooldown
  end

  -- Update bullets
  for i = #bullets, 1, -1 do
    bullets[i].y = bullets[i].y - 400 * dt
    if bullets[i].y < -10 then
      table.remove(bullets, i)
    end
  end

  -- Spawn enemies
  spawn_timer = spawn_timer - dt
  if spawn_timer <= 0 then
    table.insert(enemies, {
      x = math.random(0, 800 - 24),
      y = -30,
      w = 24, h = 24,
      speed = 80 + math.random(0, 80)
    })
    spawn_timer = spawn_rate
  end

  -- Update enemies
  for i = #enemies, 1, -1 do
    enemies[i].y = enemies[i].y + enemies[i].speed * dt
    if enemies[i].y > 620 then
      table.remove(enemies, i)
    end
  end

  -- Collision: bullet vs enemy
  for bi = #bullets, 1, -1 do
    for ei = #enemies, 1, -1 do
      local b, e = bullets[bi], enemies[ei]
      if b and e and b.x < e.x + e.w and b.x + b.w > e.x and b.y < e.y + e.h and b.y + b.h > e.y then
        table.remove(bullets, bi)
        table.remove(enemies, ei)
        score = score + 10
        break
      end
    end
  end
end

function lurek.keypressed(key)
  if key == "escape" then
    lurek.event.quit()
  end
end

function lurek.draw()
  lurek.graphics.setBackgroundColor(0.05, 0.05, 0.1)

  -- Player
  lurek.graphics.setColor(0.2, 0.7, 1.0)
  lurek.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

  -- Bullets
  lurek.graphics.setColor(1, 1, 0.3)
  for _, b in ipairs(bullets) do
    lurek.graphics.rectangle("fill", b.x, b.y, b.w, b.h)
  end

  -- Enemies
  lurek.graphics.setColor(1, 0.3, 0.3)
  for _, e in ipairs(enemies) do
    lurek.graphics.rectangle("fill", e.x, e.y, e.w, e.h)
  end

  -- HUD
  lurek.graphics.setColor(1, 1, 1)
  lurek.graphics.print("Score: " .. score, 10, 10)
  lurek.graphics.print("WASD to move, Space to shoot", 10, 30)
end
`},{label:"Puzzle",description:"Grid-based puzzle with tile swapping",confLua:`function lurek.conf(t)
  t.window.title = "My Puzzle"
  t.window.width = 480
  t.window.height = 520
end
`,mainLua:`-- Puzzle Starter
local grid_size = 4
local tile_size = 100
local padding = 40
local grid = {}
local selected = nil
local moves = 0

local colors = {
  {0.9, 0.3, 0.3}, {0.3, 0.9, 0.3}, {0.3, 0.3, 0.9}, {0.9, 0.9, 0.3},
  {0.9, 0.3, 0.9}, {0.3, 0.9, 0.9}, {0.9, 0.6, 0.2}, {0.6, 0.2, 0.9},
}

function lurek.load()
  lurek.window.setTitle("My Puzzle")
  -- Fill grid with paired colors
  local tiles = {}
  for i = 1, (grid_size * grid_size) / 2 do
    local c = colors[(i - 1) % #colors + 1]
    table.insert(tiles, c)
    table.insert(tiles, c)
  end
  -- Shuffle
  for i = #tiles, 2, -1 do
    local j = math.random(1, i)
    tiles[i], tiles[j] = tiles[j], tiles[i]
  end
  -- Place on grid
  local idx = 1
  for y = 1, grid_size do
    grid[y] = {}
    for x = 1, grid_size do
      grid[y][x] = { color = tiles[idx], revealed = false, matched = false }
      idx = idx + 1
    end
  end
end

function lurek.mousepressed(mx, my, button)
  if button ~= 1 then return end

  local gx = math.floor((mx - padding) / tile_size) + 1
  local gy = math.floor((my - padding) / tile_size) + 1
  if gx < 1 or gx > grid_size or gy < 1 or gy > grid_size then return end

  local tile = grid[gy][gx]
  if tile.matched or tile.revealed then return end

  tile.revealed = true

  if selected == nil then
    selected = { x = gx, y = gy }
  else
    moves = moves + 1
    local prev = grid[selected.y][selected.x]
    if prev.color[1] == tile.color[1] and prev.color[2] == tile.color[2] and prev.color[3] == tile.color[3] then
      prev.matched = true
      tile.matched = true
    else
      -- Hide both after a short pause (simplified: immediate)
      prev.revealed = false
      tile.revealed = false
    end
    selected = nil
  end
end

function lurek.keypressed(key)
  if key == "r" then lurek.load() end
  if key == "escape" then lurek.event.quit() end
end

function lurek.draw()
  lurek.graphics.setBackgroundColor(0.12, 0.12, 0.15)

  for y = 1, grid_size do
    for x = 1, grid_size do
      local tile = grid[y][x]
      local px = padding + (x - 1) * tile_size + 4
      local py = padding + (y - 1) * tile_size + 4
      local tw = tile_size - 8
      local th = tile_size - 8

      if tile.revealed or tile.matched then
        lurek.graphics.setColor(tile.color[1], tile.color[2], tile.color[3])
      else
        lurek.graphics.setColor(0.3, 0.3, 0.35)
      end
      lurek.graphics.rectangle("fill", px, py, tw, th)

      -- Border
      lurek.graphics.setColor(0.5, 0.5, 0.55)
      lurek.graphics.rectangle("line", px, py, tw, th)
    end
  end

  lurek.graphics.setColor(1, 1, 1)
  lurek.graphics.print("Moves: " .. moves .. "  |  R to restart", 10, 10)
end
`},{label:"Visual Novel",description:"Dialog-driven narrative with choices",confLua:`function lurek.conf(t)
  t.window.title = "My Visual Novel"
  t.window.width = 800
  t.window.height = 600
end
`,mainLua:`-- Visual Novel Starter
local scenes = {
  intro = {
    text = "You find yourself at the entrance of a mysterious forest.",
    speaker = "Narrator",
    choices = {
      { text = "Enter the forest", next = "forest" },
      { text = "Turn back home", next = "home" },
    },
  },
  forest = {
    text = "The trees tower above you. A faint light glows deeper within.",
    speaker = "Narrator",
    choices = {
      { text = "Follow the light", next = "light" },
      { text = "Search the underbrush", next = "search" },
    },
  },
  home = {
    text = "You decide the adventure can wait. Maybe tomorrow...",
    speaker = "Narrator",
    choices = {
      { text = "Play again", next = "intro" },
    },
  },
  light = {
    text = "The light reveals a clearing with an ancient stone altar!",
    speaker = "Narrator",
    choices = {
      { text = "Touch the altar", next = "ending_good" },
      { text = "Leave quickly", next = "home" },
    },
  },
  search = {
    text = "You find a small chest hidden under the roots of an old oak.",
    speaker = "Narrator",
    choices = {
      { text = "Open the chest", next = "ending_treasure" },
      { text = "Leave it alone", next = "forest" },
    },
  },
  ending_good = {
    text = "The altar glows warmly. You feel a profound sense of peace...

--- THE END ---",
    speaker = "Narrator",
    choices = { { text = "Play again", next = "intro" } },
  },
  ending_treasure = {
    text = "Inside the chest is a golden key! What could it unlock?

--- THE END ---",
    speaker = "Narrator",
    choices = { { text = "Play again", next = "intro" } },
  },
}

local current_scene = "intro"
local hover_choice = 0

function lurek.load()
  lurek.window.setTitle("My Visual Novel")
end

function lurek.update(dt)
  local mx, my = lurek.input.mouse.getPosition()
  local scene = scenes[current_scene]
  hover_choice = 0

  for i, _ in ipairs(scene.choices) do
    local cy = 420 + (i - 1) * 50
    if mx >= 100 and mx <= 700 and my >= cy and my <= cy + 40 then
      hover_choice = i
    end
  end
end

function lurek.mousepressed(mx, my, button)
  if button ~= 1 then return end
  local scene = scenes[current_scene]
  if hover_choice >= 1 and hover_choice <= #scene.choices then
    current_scene = scene.choices[hover_choice].next
    hover_choice = 0
  end
end

function lurek.keypressed(key)
  if key == "escape" then lurek.event.quit() end
  local scene = scenes[current_scene]
  local num = tonumber(key)
  if num and num >= 1 and num <= #scene.choices then
    current_scene = scene.choices[num].next
  end
end

function lurek.draw()
  lurek.graphics.setBackgroundColor(0.1, 0.08, 0.15)

  local scene = scenes[current_scene]

  -- Dialog box background
  lurek.graphics.setColor(0.15, 0.12, 0.2, 0.95)
  lurek.graphics.rectangle("fill", 50, 280, 700, 100)
  lurek.graphics.setColor(0.6, 0.5, 0.8)
  lurek.graphics.rectangle("line", 50, 280, 700, 100)

  -- Speaker name
  lurek.graphics.setColor(0.8, 0.7, 1.0)
  lurek.graphics.print(scene.speaker, 70, 260)

  -- Dialog text
  lurek.graphics.setColor(1, 1, 1)
  lurek.graphics.print(scene.text, 70, 300)

  -- Choices
  for i, choice in ipairs(scene.choices) do
    local cy = 420 + (i - 1) * 50
    if hover_choice == i then
      lurek.graphics.setColor(0.3, 0.25, 0.45)
    else
      lurek.graphics.setColor(0.2, 0.17, 0.3)
    end
    lurek.graphics.rectangle("fill", 100, cy, 600, 40)
    lurek.graphics.setColor(0.6, 0.5, 0.8)
    lurek.graphics.rectangle("line", 100, cy, 600, 40)
    lurek.graphics.setColor(1, 1, 1)
    lurek.graphics.print(i .. ". " .. choice.text, 120, cy + 10)
  end
end
`}],op=[{label:"Camera",description:"Smooth follow camera with zoom and shake",patternFile:"camera.lua",requireLine:'local Camera = require("libs.camera")'},{label:"Tilemap",description:"Tile-based map rendering and collision",patternFile:"grid.lua",requireLine:'local Grid = require("libs.grid")'},{label:"Physics",description:"Simple physics wrappers",patternFile:"component-system.lua",requireLine:'local ECS = require("libs.component-system")'},{label:"UI",description:"Basic UI components",patternFile:"stack.lua",requireLine:'local Stack = require("libs.stack")'},{label:"Particles",description:"Particle effects system",patternFile:"timer.lua",requireLine:'local Timer = require("libs.timer")'},{label:"Save/Load",description:"Game state serialization",patternFile:"class.lua",requireLine:'local Class = require("libs.class")'},{label:"Sound Manager",description:"Audio management with fade and crossfade",patternFile:"event-bus.lua",requireLine:'local EventBus = require("libs.event-bus")'},{label:"State Machine",description:"Finite state machine for game states",patternFile:"fsm.lua",requireLine:'local FSM = require("libs.fsm")'},{label:"Signal",description:"Pub-sub signal / observer pattern",patternFile:"signal.lua",requireLine:'local Signal = require("libs.signal")'},{label:"Tween",description:"Property tweening / animation engine",patternFile:"tween.lua",requireLine:'local Tween = require("libs.tween")'},{label:"Object Pool",description:"Recycling pool for bullets/particles/etc.",patternFile:"object-pool.lua",requireLine:'local Pool = require("libs.object-pool")'}],$n,_e,Un;function lp(n){Yn(),Un=Date.now()+n*6e4,_e=q.window.createStatusBarItem(q.StatusBarAlignment.Right,200),_e.show();let e=n*6e4,t=!1,r=!1,a=!1,i=()=>{if(!Un||!_e)return;let s=Un-Date.now();if(s<=0){_e.text="$(bell) TIME'S UP!",_e.backgroundColor=new q.ThemeColor("statusBarItem.errorBackground"),q.window.showWarningMessage("Game Jam Timer: Time's up!"),Yn();return}let o=s/e,l=Math.floor(s/6e4),p=Math.floor(s%6e4/1e3);_e.text=`$(clock) ${l}:${String(p).padStart(2,"0")} remaining`,o<=.1&&!a?(a=!0,_e.backgroundColor=new q.ThemeColor("statusBarItem.errorBackground"),q.window.showWarningMessage("Game Jam Timer: 10% time remaining!")):o<=.25&&!r?(r=!0,_e.backgroundColor=new q.ThemeColor("statusBarItem.warningBackground"),q.window.showWarningMessage("Game Jam Timer: 25% time remaining!")):o<=.5&&!t&&(t=!0,q.window.showInformationMessage("Game Jam Timer: 50% time remaining."))};i(),$n=setInterval(i,1e3)}function Yn(){$n&&(clearInterval($n),$n=void 0),_e&&(_e.dispose(),_e=void 0),Un=void 0}function is(n){n.subscriptions.push(q.commands.registerCommand("lurek.gameJam.quickStart",async()=>{let e=await q.window.showQuickPick(sp.map(o=>({label:o.label,description:o.description,template:o})),{placeHolder:"Choose a game template"});if(!e)return;let t=await q.window.showInputBox({prompt:"Project name",placeHolder:"my-game",validateInput:o=>{if(!o.trim())return"Name cannot be empty";if(/[<>:"/\\|?*]/.test(o))return"Name contains invalid characters"}});if(!t)return;let r=await q.window.showOpenDialog({canSelectFolders:!0,canSelectFiles:!1,canSelectMany:!1,openLabel:"Select parent folder"});if(!r||r.length===0)return;let a=Ae.join(r[0].fsPath,t);if(se.existsSync(a)){q.window.showErrorMessage(`Folder already exists: ${a}`);return}let i=e.template;se.mkdirSync(a,{recursive:!0}),se.mkdirSync(Ae.join(a,"assets"),{recursive:!0}),se.mkdirSync(Ae.join(a,"libs"),{recursive:!0}),se.writeFileSync(Ae.join(a,"conf.lua"),i.confLua,"utf-8"),se.writeFileSync(Ae.join(a,"main.lua"),i.mainLua,"utf-8"),se.writeFileSync(Ae.join(a,"assets","README.md"),`# Assets

Place your game assets (images, sounds, fonts) in this folder.
`,"utf-8");let s=q.Uri.file(a);await q.commands.executeCommand("vscode.openFolder",s),q.window.showInformationMessage(`Created "${t}" with ${i.label} template!`)})),n.subscriptions.push(q.commands.registerCommand("lurek.gameJam.addModule",async()=>{let e=await q.window.showQuickPick(op.map(l=>({label:l.label,description:l.description,module:l})),{placeHolder:"Choose a module to add"});if(!e)return;let t=q.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!t){q.window.showErrorMessage("No workspace folder open.");return}let r=e.module,a=Ae.join(t,"libs");se.existsSync(a)||se.mkdirSync(a,{recursive:!0});let i=Ae.join(a,r.patternFile);if(se.existsSync(i)&&await q.window.showWarningMessage(`libs/${r.patternFile} already exists. Overwrite?`,"Yes","No")!=="Yes")return;let s=Ae.join(n.extensionPath,"data","patterns",r.patternFile);if(!se.existsSync(s)){q.window.showErrorMessage(`Pattern file not found: ${r.patternFile}`);return}se.copyFileSync(s,i);let o=Ae.join(t,"main.lua");if(se.existsSync(o)){let l=se.readFileSync(o,"utf-8");if(!l.includes(r.requireLine)){let p=l.split(`
`),u=0;for(let d=0;d<p.length;d++)p[d].startsWith("local ")&&p[d].includes("require")&&(u=d+1);p.splice(u,0,r.requireLine),se.writeFileSync(o,p.join(`
`),"utf-8")}}q.window.showInformationMessage(`Added ${r.label} module to libs/${r.patternFile}`)})),n.subscriptions.push(q.commands.registerCommand("lurek.gameJam.timer",async()=>{let e=await q.window.showQuickPick([{label:"30 minutes",minutes:30},{label:"1 hour",minutes:60},{label:"2 hours",minutes:120},{label:"Custom...",minutes:-1},{label:"Stop timer",minutes:0}],{placeHolder:"Game Jam countdown duration"});if(!e)return;if(e.minutes===0){Yn(),q.window.showInformationMessage("Game Jam Timer stopped.");return}let t=e.minutes;if(t<0){let r=await q.window.showInputBox({prompt:"Duration in minutes",placeHolder:"90",validateInput:a=>{let i=Number(a);if(isNaN(i)||i<=0)return"Enter a positive number"}});if(!r)return;t=Number(r)}lp(t),q.window.showInformationMessage(`Game Jam Timer started: ${t} minutes.`)})),n.subscriptions.push({dispose:Yn})}var Q=C(require("vscode")),ut=C(require("path")),be=C(require("fs")),ss=[{label:"Draw sprite",category:"Graphics",code:`local img = lurek.graphics.newImage("assets/sprite.png")

function lurek.draw()
  lurek.graphics.draw(img, x, y)
end`},{label:"Animation loop",category:"Graphics",code:`local frames = {}
local current_frame = 1
local frame_timer = 0
local frame_duration = 0.1

function lurek.load()
  for i = 1, 4 do
    frames[i] = lurek.graphics.newImage("assets/frame" .. i .. ".png")
  end
end

function lurek.update(dt)
  frame_timer = frame_timer + dt
  if frame_timer >= frame_duration then
    frame_timer = frame_timer - frame_duration
    current_frame = current_frame % #frames + 1
  end
end

function lurek.draw()
  lurek.graphics.draw(frames[current_frame], x, y)
end`},{label:"Particle burst",category:"Graphics",code:`local particles = {}

local function emit(px, py, count)
  for i = 1, count do
    local angle = math.random() * math.pi * 2
    local speed = 50 + math.random() * 100
    table.insert(particles, {
      x = px, y = py,
      vx = math.cos(angle) * speed,
      vy = math.sin(angle) * speed,
      life = 0.5 + math.random() * 0.5,
    })
  end
end

function lurek.update(dt)
  for i = #particles, 1, -1 do
    local p = particles[i]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.life = p.life - dt
    if p.life <= 0 then table.remove(particles, i) end
  end
end

function lurek.draw()
  for _, p in ipairs(particles) do
    local a = p.life
    lurek.graphics.setColor(1, 0.8, 0.2, a)
    lurek.graphics.circle("fill", p.x, p.y, 3)
  end
  lurek.graphics.setColor(1, 1, 1, 1)
end`},{label:"Screen shake",category:"Graphics",code:`local shake_timer = 0
local shake_intensity = 0
local shake_ox, shake_oy = 0, 0

local function startShake(duration, intensity)
  shake_timer = duration
  shake_intensity = intensity
end

function lurek.update(dt)
  if shake_timer > 0 then
    shake_timer = shake_timer - dt
    shake_ox = (math.random() - 0.5) * 2 * shake_intensity
    shake_oy = (math.random() - 0.5) * 2 * shake_intensity
  else
    shake_ox, shake_oy = 0, 0
  end
end

function lurek.draw()
  lurek.graphics.push()
  lurek.graphics.translate(shake_ox, shake_oy)
  -- Draw your game here
  lurek.graphics.pop()
end`},{label:"WASD movement",category:"Input",code:`local player = { x = 400, y = 300, speed = 200 }

function lurek.update(dt)
  if lurek.input.keyboard.isDown("w") or lurek.input.keyboard.isDown("up") then
    player.y = player.y - player.speed * dt
  end
  if lurek.input.keyboard.isDown("s") or lurek.input.keyboard.isDown("down") then
    player.y = player.y + player.speed * dt
  end
  if lurek.input.keyboard.isDown("a") or lurek.input.keyboard.isDown("left") then
    player.x = player.x - player.speed * dt
  end
  if lurek.input.keyboard.isDown("d") or lurek.input.keyboard.isDown("right") then
    player.x = player.x + player.speed * dt
  end
end`},{label:"Mouse aim",category:"Input",code:`local player = { x = 400, y = 300, angle = 0 }

function lurek.update(dt)
  local mx, my = lurek.input.mouse.getPosition()
  player.angle = math.atan2(my - player.y, mx - player.x)
end

function lurek.draw()
  lurek.graphics.push()
  lurek.graphics.translate(player.x, player.y)
  lurek.graphics.rotate(player.angle)
  lurek.graphics.setColor(0.3, 0.7, 1)
  lurek.graphics.rectangle("fill", -16, -8, 32, 16)
  lurek.graphics.pop()
end`},{label:"Gamepad support",category:"Input",code:`local player = { x = 400, y = 300, speed = 200 }

function lurek.update(dt)
  local axes = lurek.input.gamepad.getAxes(1)
  if axes then
    local deadzone = 0.2
    if math.abs(axes.leftx) > deadzone then
      player.x = player.x + axes.leftx * player.speed * dt
    end
    if math.abs(axes.lefty) > deadzone then
      player.y = player.y + axes.lefty * player.speed * dt
    end
  end
end

function lurek.gamepadpressed(id, button)
  if button == "a" then
    -- Jump or action
  end
end`},{label:"Touch controls",category:"Input",code:`local touches = {}

function lurek.touchpressed(id, x, y, dx, dy, pressure)
  touches[id] = { x = x, y = y, startX = x, startY = y }
end

function lurek.touchmoved(id, x, y, dx, dy, pressure)
  if touches[id] then
    touches[id].x = x
    touches[id].y = y
  end
end

function lurek.touchreleased(id, x, y, dx, dy, pressure)
  if touches[id] then
    local swipeX = x - touches[id].startX
    local swipeY = y - touches[id].startY
    -- Detect swipe direction
    if math.abs(swipeX) > 50 then
      if swipeX > 0 then print("Swipe right") else print("Swipe left") end
    end
    if math.abs(swipeY) > 50 then
      if swipeY > 0 then print("Swipe down") else print("Swipe up") end
    end
    touches[id] = nil
  end
end`},{label:"Platformer controller",category:"Physics",code:`local player = { x = 100, y = 400, w = 32, h = 48, vx = 0, vy = 0, onGround = false }
local gravity = 980
local jumpForce = -450
local moveSpeed = 200
local friction = 0.85
local ground_y = 500

function lurek.update(dt)
  -- Horizontal
  if lurek.input.keyboard.isDown("left") then player.vx = -moveSpeed
  elseif lurek.input.keyboard.isDown("right") then player.vx = moveSpeed
  else player.vx = player.vx * friction end

  -- Gravity
  player.vy = player.vy + gravity * dt

  -- Apply
  player.x = player.x + player.vx * dt
  player.y = player.y + player.vy * dt

  -- Ground check
  if player.y + player.h >= ground_y then
    player.y = ground_y - player.h
    player.vy = 0
    player.onGround = true
  else
    player.onGround = false
  end
end

function lurek.keypressed(key)
  if key == "space" and player.onGround then
    player.vy = jumpForce
  end
end`},{label:"Top-down movement",category:"Physics",code:`local player = { x = 400, y = 300, vx = 0, vy = 0, speed = 200, friction = 8 }

function lurek.update(dt)
  local ix, iy = 0, 0
  if lurek.input.keyboard.isDown("w") then iy = iy - 1 end
  if lurek.input.keyboard.isDown("s") then iy = iy + 1 end
  if lurek.input.keyboard.isDown("a") then ix = ix - 1 end
  if lurek.input.keyboard.isDown("d") then ix = ix + 1 end

  -- Normalize
  local len = math.sqrt(ix * ix + iy * iy)
  if len > 0 then ix, iy = ix / len, iy / len end

  -- Accelerate
  player.vx = player.vx + ix * player.speed * dt * 10
  player.vy = player.vy + iy * player.speed * dt * 10

  -- Friction
  player.vx = player.vx * (1 - player.friction * dt)
  player.vy = player.vy * (1 - player.friction * dt)

  player.x = player.x + player.vx * dt
  player.y = player.y + player.vy * dt
end`},{label:"Projectile",category:"Physics",code:`local bullets = {}

local function shoot(x, y, angle, speed)
  table.insert(bullets, {
    x = x, y = y,
    vx = math.cos(angle) * speed,
    vy = math.sin(angle) * speed,
    life = 3.0,
  })
end

function lurek.update(dt)
  for i = #bullets, 1, -1 do
    local b = bullets[i]
    b.x = b.x + b.vx * dt
    b.y = b.y + b.vy * dt
    b.life = b.life - dt
    if b.life <= 0 or b.x < -10 or b.x > 810 or b.y < -10 or b.y > 610 then
      table.remove(bullets, i)
    end
  end
end

function lurek.draw()
  lurek.graphics.setColor(1, 1, 0)
  for _, b in ipairs(bullets) do
    lurek.graphics.circle("fill", b.x, b.y, 3)
  end
end`},{label:"Raycast",category:"Physics",code:`-- Simple DDA raycast on a tile grid
local function raycast(grid, x, y, angle, maxDist)
  local dx = math.cos(angle)
  local dy = math.sin(angle)
  local dist = 0
  local step = 1

  while dist < maxDist do
    local checkX = math.floor(x + dx * dist)
    local checkY = math.floor(y + dy * dist)
    local gx = math.floor(checkX / 32) + 1
    local gy = math.floor(checkY / 32) + 1

    if grid[gy] and grid[gy][gx] and grid[gy][gx] > 0 then
      return { hit = true, x = checkX, y = checkY, dist = dist, tile = grid[gy][gx] }
    end
    dist = dist + step
  end

  return { hit = false, x = x + dx * maxDist, y = y + dy * maxDist, dist = maxDist }
end`},{label:"Health bar",category:"UI",code:`local hp = { current = 75, max = 100 }

local function drawHealthBar(x, y, w, h)
  local pct = hp.current / hp.max

  -- Background
  lurek.graphics.setColor(0.2, 0.2, 0.2)
  lurek.graphics.rectangle("fill", x, y, w, h)

  -- Fill
  local color_r = (1 - pct) * 2
  local color_g = pct * 2
  lurek.graphics.setColor(math.min(color_r, 1), math.min(color_g, 1), 0)
  lurek.graphics.rectangle("fill", x, y, w * pct, h)

  -- Border
  lurek.graphics.setColor(0.8, 0.8, 0.8)
  lurek.graphics.rectangle("line", x, y, w, h)

  -- Text
  lurek.graphics.setColor(1, 1, 1)
  lurek.graphics.print(hp.current .. "/" .. hp.max, x + 4, y + 2)
end`},{label:"Dialog box",category:"UI",code:`local dialog = { active = false, text = "", speaker = "", char_idx = 0, timer = 0, speed = 0.03 }

local function showDialog(speaker, text)
  dialog.active = true
  dialog.speaker = speaker
  dialog.text = text
  dialog.char_idx = 0
  dialog.timer = 0
end

function lurek.update(dt)
  if not dialog.active then return end
  dialog.timer = dialog.timer + dt
  if dialog.timer >= dialog.speed then
    dialog.timer = dialog.timer - dialog.speed
    dialog.char_idx = math.min(dialog.char_idx + 1, #dialog.text)
  end
end

function lurek.keypressed(key)
  if dialog.active and (key == "space" or key == "return") then
    if dialog.char_idx < #dialog.text then
      dialog.char_idx = #dialog.text
    else
      dialog.active = false
    end
  end
end

local function drawDialog()
  if not dialog.active then return end
  lurek.graphics.setColor(0, 0, 0, 0.85)
  lurek.graphics.rectangle("fill", 50, 400, 700, 150)
  lurek.graphics.setColor(0.7, 0.7, 0.9)
  lurek.graphics.rectangle("line", 50, 400, 700, 150)
  lurek.graphics.setColor(0.9, 0.8, 1)
  lurek.graphics.print(dialog.speaker, 70, 410)
  lurek.graphics.setColor(1, 1, 1)
  lurek.graphics.print(string.sub(dialog.text, 1, dialog.char_idx), 70, 440)
end`},{label:"Menu system",category:"UI",code:`local menu = {
  items = { "Start Game", "Options", "Quit" },
  selected = 1,
}

function lurek.keypressed(key)
  if key == "up" then
    menu.selected = menu.selected - 1
    if menu.selected < 1 then menu.selected = #menu.items end
  elseif key == "down" then
    menu.selected = menu.selected + 1
    if menu.selected > #menu.items then menu.selected = 1 end
  elseif key == "return" then
    if menu.items[menu.selected] == "Quit" then
      lurek.event.quit()
    end
  end
end

function lurek.draw()
  lurek.graphics.setBackgroundColor(0.1, 0.1, 0.15)
  for i, item in ipairs(menu.items) do
    local y = 200 + (i - 1) * 50
    if i == menu.selected then
      lurek.graphics.setColor(1, 0.9, 0.2)
      lurek.graphics.print("> " .. item, 300, y)
    else
      lurek.graphics.setColor(0.7, 0.7, 0.7)
      lurek.graphics.print("  " .. item, 300, y)
    end
  end
end`},{label:"Minimap",category:"UI",code:`local minimap = { x = 620, y = 10, w = 160, h = 120, scale = 0.1 }

local function drawMinimap(world_objects, player, world_w, world_h)
  -- Background
  lurek.graphics.setColor(0, 0, 0, 0.6)
  lurek.graphics.rectangle("fill", minimap.x, minimap.y, minimap.w, minimap.h)
  lurek.graphics.setColor(0.5, 0.5, 0.5)
  lurek.graphics.rectangle("line", minimap.x, minimap.y, minimap.w, minimap.h)

  local sx = minimap.w / world_w
  local sy = minimap.h / world_h

  -- Objects
  lurek.graphics.setColor(0.4, 0.4, 0.6)
  for _, obj in ipairs(world_objects) do
    lurek.graphics.rectangle("fill",
      minimap.x + obj.x * sx, minimap.y + obj.y * sy,
      math.max(obj.w * sx, 2), math.max(obj.h * sy, 2))
  end

  -- Player dot
  lurek.graphics.setColor(0, 1, 0)
  lurek.graphics.circle("fill", minimap.x + player.x * sx, minimap.y + player.y * sy, 3)
end`},{label:"Music manager",category:"Audio",code:`local music = { current = nil, volume = 0.7 }

local function playMusic(file)
  if music.current then
    lurek.audio.stop(music.current)
  end
  music.current = lurek.audio.newSource(file, "stream")
  lurek.audio.setVolume(music.current, music.volume)
  lurek.audio.play(music.current)
end

local function setMusicVolume(vol)
  music.volume = math.max(0, math.min(1, vol))
  if music.current then
    lurek.audio.setVolume(music.current, music.volume)
  end
end

local function stopMusic()
  if music.current then
    lurek.audio.stop(music.current)
    music.current = nil
  end
end`},{label:"SFX player",category:"Audio",code:`local sfx = {}

local function loadSFX(name, file)
  sfx[name] = lurek.audio.newSource(file, "static")
end

local function playSFX(name, volume, pitch)
  local s = sfx[name]
  if s then
    local clone = lurek.audio.clone(s)
    lurek.audio.setVolume(clone, volume or 1.0)
    lurek.audio.setPitch(clone, pitch or 1.0)
    lurek.audio.play(clone)
  end
end

-- Usage:
-- loadSFX("jump", "assets/sounds/jump.wav")
-- playSFX("jump", 0.8)`},{label:"Volume control",category:"Audio",code:`local master_volume = 1.0

function lurek.keypressed(key)
  if key == "+" or key == "=" then
    master_volume = math.min(master_volume + 0.1, 1.0)
    lurek.audio.setMasterVolume(master_volume)
  elseif key == "-" then
    master_volume = math.max(master_volume - 0.1, 0.0)
    lurek.audio.setMasterVolume(master_volume)
  elseif key == "m" then
    if master_volume > 0 then
      master_volume = 0
    else
      master_volume = 1.0
    end
    lurek.audio.setMasterVolume(master_volume)
  end
end`},{label:"Crossfade",category:"Audio",code:`local crossfade = { from = nil, to = nil, progress = 0, duration = 2.0, active = false }

local function crossfadeTo(newMusic, duration)
  crossfade.from = crossfade.to or nil
  crossfade.to = lurek.audio.newSource(newMusic, "stream")
  lurek.audio.setVolume(crossfade.to, 0)
  lurek.audio.play(crossfade.to)
  crossfade.progress = 0
  crossfade.duration = duration or 2.0
  crossfade.active = true
end

function lurek.update(dt)
  if not crossfade.active then return end
  crossfade.progress = crossfade.progress + dt / crossfade.duration
  if crossfade.progress >= 1 then
    crossfade.progress = 1
    crossfade.active = false
    if crossfade.from then lurek.audio.stop(crossfade.from) end
  end
  if crossfade.from then lurek.audio.setVolume(crossfade.from, 1 - crossfade.progress) end
  if crossfade.to then lurek.audio.setVolume(crossfade.to, crossfade.progress) end
end`},{label:"Save/Load",category:"Data",code:`local function saveGame(data, filename)
  filename = filename or "save.lua"
  local function serialize(val, indent)
    indent = indent or ""
    local t = type(val)
    if t == "table" then
      local parts = { "{\\n" }
      for k, v in pairs(val) do
        local key = type(k) == "number" and "" or ("[" .. serialize(k) .. "] = ")
        table.insert(parts, indent .. "  " .. key .. serialize(v, indent .. "  ") .. ",\\n")
      end
      table.insert(parts, indent .. "}")
      return table.concat(parts)
    elseif t == "string" then
      return string.format("%q", val)
    else
      return tostring(val)
    end
  end
  lurek.filesystem.write(filename, "return " .. serialize(data))
end

local function loadGame(filename)
  filename = filename or "save.lua"
  if not lurek.filesystem.exists(filename) then return nil end
  local content = lurek.filesystem.read(filename)
  local fn = load(content)
  return fn and fn() or nil
end`},{label:"Config file",category:"Data",code:`local config = {
  music_volume = 0.7,
  sfx_volume = 1.0,
  fullscreen = false,
  language = "en",
}

local function loadConfig()
  if lurek.filesystem.exists("config.lua") then
    local content = lurek.filesystem.read("config.lua")
    local fn = load(content)
    if fn then
      local loaded = fn()
      for k, v in pairs(loaded) do
        config[k] = v
      end
    end
  end
end

local function saveConfig()
  local lines = { "return {" }
  for k, v in pairs(config) do
    if type(v) == "string" then
      table.insert(lines, string.format("  %s = %q,", k, v))
    else
      table.insert(lines, string.format("  %s = %s,", k, tostring(v)))
    end
  end
  table.insert(lines, "}")
  lurek.filesystem.write("config.lua", table.concat(lines, "\\n"))
end`},{label:"High scores",category:"Data",code:`local scores = {}
local MAX_SCORES = 10

local function loadScores()
  if lurek.filesystem.exists("scores.lua") then
    local content = lurek.filesystem.read("scores.lua")
    local fn = load(content)
    if fn then scores = fn() or {} end
  end
end

local function saveScores()
  local lines = { "return {" }
  for _, entry in ipairs(scores) do
    table.insert(lines, string.format('  { name = %q, score = %d },', entry.name, entry.score))
  end
  table.insert(lines, "}")
  lurek.filesystem.write("scores.lua", table.concat(lines, "\\n"))
end

local function addScore(name, score)
  table.insert(scores, { name = name, score = score })
  table.sort(scores, function(a, b) return a.score > b.score end)
  while #scores > MAX_SCORES do table.remove(scores) end
  saveScores()
end`},{label:"Inventory",category:"Data",code:`local inventory = { slots = {}, maxSlots = 20 }

local function addItem(name, count)
  count = count or 1
  for _, slot in ipairs(inventory.slots) do
    if slot.name == name then
      slot.count = slot.count + count
      return true
    end
  end
  if #inventory.slots < inventory.maxSlots then
    table.insert(inventory.slots, { name = name, count = count })
    return true
  end
  return false  -- inventory full
end

local function removeItem(name, count)
  count = count or 1
  for i, slot in ipairs(inventory.slots) do
    if slot.name == name then
      slot.count = slot.count - count
      if slot.count <= 0 then table.remove(inventory.slots, i) end
      return true
    end
  end
  return false  -- item not found
end

local function hasItem(name, count)
  count = count or 1
  for _, slot in ipairs(inventory.slots) do
    if slot.name == name and slot.count >= count then return true end
  end
  return false
end`}];function pp(){let n=new Set;for(let e of ss)n.add(e.category);return[...n].sort()}function up(n){let e=ut.join(n,"data","patterns");return be.existsSync(e)?be.readdirSync(e).filter(t=>t.endsWith(".lua")).map(t=>({name:t.replace(".lua",""),fullPath:ut.join(e,t)})):[]}function os(n){n.subscriptions.push(Q.commands.registerCommand("lurek.library.browse",async()=>{let e=up(n.extensionPath);if(e.length===0){Q.window.showInformationMessage("No patterns found in data/patterns/.");return}let t=await Q.window.showQuickPick(e.map(a=>({label:a.name,description:`data/patterns/${a.name}.lua`,fullPath:a.fullPath})),{placeHolder:"Browse Lurek2D patterns"});if(!t)return;let r=await Q.window.showQuickPick([{label:"Preview",description:"Open the pattern file in a new tab"},{label:"Copy to project",description:"Copy to libs/ folder in your project"}],{placeHolder:`${t.label}: What would you like to do?`});if(r)if(r.label==="Preview"){let a=await Q.workspace.openTextDocument(t.fullPath);await Q.window.showTextDocument(a,{preview:!0})}else{let a=Q.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!a){Q.window.showErrorMessage("No workspace folder open.");return}let i=ut.join(a,"libs");be.existsSync(i)||be.mkdirSync(i,{recursive:!0});let s=ut.join(i,`${t.label}.lua`);if(be.existsSync(s)&&await Q.window.showWarningMessage(`libs/${t.label}.lua already exists. Overwrite?`,"Yes","No")!=="Yes")return;be.copyFileSync(t.fullPath,s),Q.window.showInformationMessage(`Copied ${t.label} to libs/${t.label}.lua`)}})),n.subscriptions.push(Q.commands.registerCommand("lurek.library.insertSnippet",async()=>{let e=pp(),t=await Q.window.showQuickPick(e.map(s=>({label:s})),{placeHolder:"Choose snippet category"});if(!t)return;let r=ss.filter(s=>s.category===t.label),a=await Q.window.showQuickPick(r.map(s=>({label:s.label,snippet:s})),{placeHolder:`${t.label} snippets`});if(!a)return;let i=Q.window.activeTextEditor;if(!i){let s=await Q.workspace.openTextDocument({language:"lua",content:a.snippet.code+`
`});await Q.window.showTextDocument(s);return}await i.edit(s=>{s.insert(i.selection.active,a.snippet.code+`
`)})})),n.subscriptions.push(Q.commands.registerCommand("lurek.library.newPattern",async()=>{let e=Q.window.activeTextEditor;if(!e||e.selection.isEmpty){Q.window.showWarningMessage("Select some Lua code first to create a pattern from it.");return}let t=e.document.getText(e.selection),r=await Q.window.showInputBox({prompt:"Pattern name",placeHolder:"my-pattern",validateInput:p=>{if(!p.trim())return"Name cannot be empty";if(/[<>:"/\\|?*\s]/.test(p))return"Name should be a simple identifier (use dashes, no spaces)"}});if(!r)return;let a=await Q.window.showInputBox({prompt:"Category",placeHolder:"e.g. gameplay, ui, utility"}),i=await Q.window.showInputBox({prompt:"Brief description",placeHolder:"What does this pattern do?"}),s=[`--- ${r} pattern for Lurek2D.`,`--- ${i??"Custom pattern."}`,"---",`--- Category: ${a??"general"}`,"---",""].join(`
`),o=ut.join(n.extensionPath,"data","patterns");be.existsSync(o)||be.mkdirSync(o,{recursive:!0});let l=ut.join(o,`${r}.lua`);be.existsSync(l)&&await Q.window.showWarningMessage(`Pattern "${r}" already exists. Overwrite?`,"Yes","No")!=="Yes"||(be.writeFileSync(l,s+t+`
`,"utf-8"),Q.window.showInformationMessage(`Pattern "${r}" saved to data/patterns/${r}.lua`))}))}var te=C(require("vscode")),ve=C(require("path")),ue=C(require("fs")),ls=[{label:"Agents",description:"AI agent definitions for game dev roles",srcDir:"agents"},{label:"Skills",description:"Domain skill packages for AI assistants",srcDir:"skills"},{label:"Prompts",description:"Task-driven playbooks for game development",srcDir:"prompts"},{label:"Instructions",description:"Contextual coding instructions",srcDir:"instructions"}],dp=[{label:"Minimal",description:"Bare-bones starter with essential callbacks",dir:"minimal"},{label:"Game Loop",description:"Structured loop with class system and event bus",dir:"game-loop"},{label:"Platformer",description:"Side-scrolling platformer with jump physics",dir:"platformer"},{label:"Top-Down RPG",description:"8-dir movement, scene management, HUD",dir:"top-down-rpg"},{label:"Shoot 'em Up",description:"Vertical scrolling shooter with bullet pool",dir:"shoot-em-up"},{label:"Puzzle",description:"Grid-based puzzle with click interaction",dir:"puzzle"},{label:"Roguelike",description:"Turn-based with BSP dungeon generation",dir:"roguelike"},{label:"Visual Novel",description:"Typewriter dialog and scene progression",dir:"visual-novel"},{label:"Arcade",description:"Simple arcade loop with score and lives",dir:"arcade"},{label:"Tower Defense",description:"Path-following enemies, placeable towers, waves",dir:"tower-defense"},{label:"Game Jam",description:"Minimal fast-start template for game jams",dir:"game-jam"},{label:"Demo Scene",description:"Scene switcher with multiple demo scenes",dir:"demo-scene"}];function Hr(n){return ve.join(n.extensionPath,"cag","game-dev")}function Vr(){return te.workspace.workspaceFolders?.[0]?.uri.fsPath}function Xn(n,e){ue.existsSync(e)||ue.mkdirSync(e,{recursive:!0});for(let t of ue.readdirSync(n,{withFileTypes:!0})){let r=ve.join(n,t.name),a=ve.join(e,t.name);t.isDirectory()?Xn(r,a):ue.copyFileSync(r,a)}}function Qn(n){if(!ue.existsSync(n))return 0;let e=0;for(let t of ue.readdirSync(n,{withFileTypes:!0}))t.isDirectory()?e+=Qn(ve.join(n,t.name)):e++;return e}async function cp(n){let e=Vr();if(!e){te.window.showErrorMessage("No workspace folder open.");return}let t=Hr(n);if(!ue.existsSync(t)){te.window.showErrorMessage("Game Dev CAG files not found in extension bundle.");return}let r=await te.window.showQuickPick(ls.map(s=>({label:s.label,description:s.description,picked:!0,srcDir:s.srcDir})),{canPickMany:!0,placeHolder:"Select CAG components to deploy",title:"Deploy Game Dev AI Layer"});if(!r||r.length===0)return;let a=ve.join(e,".github"),i=0;for(let s of r){let o=ve.join(t,s.srcDir);if(!ue.existsSync(o))continue;let l=ve.join(a,s.srcDir);Xn(o,l),i+=Qn(o)}te.window.showInformationMessage(`Deployed ${i} file(s) to .github/ (${r.map(s=>s.label).join(", ")})`)}async function mp(n){let e=Vr();if(!e){te.window.showErrorMessage("No workspace folder open.");return}let t=Hr(n),r=ve.join(t,"templates");if(!ue.existsSync(r)){te.window.showErrorMessage("Game Dev templates not found in extension bundle.");return}let a=await te.window.showQuickPick(dp.map(p=>({label:p.label,description:p.description,dir:p.dir})),{placeHolder:"Select a game template",title:"Scaffold Project from Template"});if(!a)return;let i=ve.join(r,a.dir);if(!ue.existsSync(i)){te.window.showErrorMessage(`Template "${a.label}" not found.`);return}let s=ve.join(e,"main.lua");if(ue.existsSync(s)&&await te.window.showWarningMessage("main.lua already exists in workspace. Overwrite project files?","Yes","No")!=="Yes")return;Xn(i,e);let o=Qn(i);te.window.showInformationMessage(`Scaffolded "${a.label}" template (${o} files)`);let l=ve.join(e,"main.lua");if(ue.existsSync(l)){let p=await te.workspace.openTextDocument(l);await te.window.showTextDocument(p)}}async function gp(n){let e=Vr();if(!e){te.window.showErrorMessage("No workspace folder open.");return}let t=ve.join(e,".github");if(!ue.existsSync(t)){te.window.showInformationMessage("No .github/ folder found. Use 'Deploy Game Dev AI Layer' first.");return}if(await te.window.showWarningMessage("This will overwrite existing CAG files in .github/ with the latest from the extension. Continue?","Yes","No")!=="Yes")return;let a=Hr(n),i=0;for(let s of ls){let o=ve.join(a,s.srcDir);if(!ue.existsSync(o))continue;let l=ve.join(t,s.srcDir);Xn(o,l),i+=Qn(o)}te.window.showInformationMessage(`Updated ${i} CAG file(s) in .github/`)}function ps(n){n.subscriptions.push(te.commands.registerCommand("lurek.cag.deploy",()=>cp(n)),te.commands.registerCommand("lurek.cag.scaffold",()=>mp(n)),te.commands.registerCommand("lurek.cag.updateGameDev",()=>gp(n)))}var Be=C(require("vscode"));var W=C(Ps()),Cs=C(require("net")),ne=C(require("path")),js=require("child_process"),et=C(require("fs")),ks=1,Ms=5,Ss=800,wa=8172,pr=class extends W.LoggingDebugSession{socket=null;engineProcess=null;breakpoints=new Map;variablesMap=new Map;nextVariableRef=1;pendingRequests=new Map;nextRequestId=1;receiveBuffer="";gamePath="";debugPort=wa;loadedSources=[];constructor(){super("lurek-debug.log"),this.setDebuggerLinesStartAt1(!0),this.setDebuggerColumnsStartAt1(!0)}initializeRequest(e,t){e.body={supportsConfigurationDoneRequest:!0,supportsFunctionBreakpoints:!1,supportsConditionalBreakpoints:!0,supportsHitConditionalBreakpoints:!0,supportsEvaluateForHovers:!0,supportsStepBack:!1,supportsSetVariable:!0,supportsRestartFrame:!1,supportsGotoTargetsRequest:!1,supportsStepInTargetsRequest:!1,supportsCompletionsRequest:!0,supportsModulesRequest:!1,supportsExceptionOptions:!1,supportsValueFormattingOptions:!1,supportsExceptionInfoRequest:!1,supportTerminateDebuggee:!0,supportsDelayedStackTraceLoading:!1,supportsLoadedSourcesRequest:!0,supportsLogPoints:!0,supportsTerminateThreadsRequest:!1,supportsSetExpression:!1,supportsTerminateRequest:!0,supportsDataBreakpoints:!1,supportsReadMemoryRequest:!1,supportsDisassembleRequest:!1,supportsBreakpointLocationsRequest:!0,supportsClipboardContext:!1,supportsExceptionFilterOptions:!1,supportsSteppingGranularity:!1,supportsInstructionBreakpoints:!1},this.sendResponse(e),this.sendEvent(new W.InitializedEvent)}async launchRequest(e,t){this.gamePath=t.program,this.debugPort=t.debugPort??wa;let r=t.stopOnEntry??!1,a=this.findEngineBinary(t.enginePath);if(!a){this.sendErrorResponse(e,1001,"Lurek2D engine not found. Set 'lurek.enginePath' in settings or ensure lurek2d is on PATH.");return}let i=[`--debug-port=${this.debugPort}`,this.gamePath,...t.args??[]];this.log(`Launching: ${a} ${i.join(" ")}`);try{this.engineProcess=(0,js.spawn)(a,i,{cwd:ne.dirname(this.gamePath),stdio:["ignore","pipe","pipe"]}),this.engineProcess.stdout?.on("data",s=>{this.sendEvent(new W.OutputEvent(s.toString(),"stdout"))}),this.engineProcess.stderr?.on("data",s=>{this.sendEvent(new W.OutputEvent(s.toString(),"stderr"))}),this.engineProcess.on("exit",s=>{this.log(`Engine exited with code ${s}`),this.sendEvent(new W.TerminatedEvent)}),this.engineProcess.on("error",s=>{this.sendEvent(new W.OutputEvent(`Engine error: ${s.message}
`,"stderr")),this.sendEvent(new W.TerminatedEvent)}),await this.connectToEngine(this.debugPort),r&&await this.sendToEngine("pause"),this.sendResponse(e)}catch(s){let o=s instanceof Error?s.message:String(s);this.sendErrorResponse(e,1002,`Failed to launch: ${o}`)}}async attachRequest(e,t){this.debugPort=t.debugPort??wa;try{await this.connectToEngine(this.debugPort),this.sendResponse(e)}catch(r){let a=r instanceof Error?r.message:String(r);this.sendErrorResponse(e,1003,`Failed to attach: ${a}`)}}configurationDoneRequest(e,t){this.sendResponse(e)}async disconnectRequest(e,t){if(t.terminateDebuggee!==!1&&this.engineProcess)try{await this.sendToEngine("terminate")}catch{}this.cleanup(),this.sendResponse(e)}async terminateRequest(e,t){try{await this.sendToEngine("terminate")}catch{}this.cleanup(),this.sendResponse(e)}async setBreakPointsRequest(e,t){let r=t.source.path??"",a=t.lines??[],i=this.toRelativePath(r);try{let s=await this.sendToEngine("setBreakpoints",{file:i,lines:a}),o=a.map((l,p)=>{let u=new W.Breakpoint(!0,l);if(u.id=p+1,s.body&&Array.isArray(s.body.breakpoints)){let d=s.body.breakpoints[p];d&&(u.verified=d.verified,d.line!==void 0&&(u.line=d.line))}return u});this.breakpoints.set(r,o),this.loadedSources.find(l=>l.path===r)||this.loadedSources.push(new W.Source(ne.basename(r),r)),e.body={breakpoints:o}}catch{let s=a.map((o,l)=>{let p=new W.Breakpoint(!1,o);return p.id=l+1,p});this.breakpoints.set(r,s),e.body={breakpoints:s}}this.sendResponse(e)}breakpointLocationsRequest(e,t){let r=t.line,a=t.endLine??r,i=[];for(let s=r;s<=a;s++)i.push({line:s});e.body={breakpoints:i},this.sendResponse(e)}threadsRequest(e){e.body={threads:[new W.Thread(ks,"Lurek2D Main")]},this.sendResponse(e)}async stackTraceRequest(e,t){try{let r=await this.sendToEngine("stackTrace"),a=[];if(r.body&&Array.isArray(r.body.frames)){let i=r.body.frames,s=t.startFrame??0,o=t.levels??i.length,l=Math.min(s+o,i.length);for(let p=s;p<l;p++){let u=i[p],d=this.toAbsolutePath(u.file),m=new W.Source(ne.basename(u.file),d);a.push(new W.StackFrame(p,u.name,m,u.line,u.column??1))}}e.body={stackFrames:a,totalFrames:r.body?.frames?.length??a.length}}catch{e.body={stackFrames:[],totalFrames:0}}this.sendResponse(e)}async scopesRequest(e,t){try{let r=await this.sendToEngine("scopes",{frameId:t.frameId}),a=[];if(r.body&&Array.isArray(r.body.scopes))for(let i of r.body.scopes)a.push(new W.Scope(i.name,i.variablesReference,i.expensive??!1));else{let i=this.nextVariableRef++,s=this.nextVariableRef++;a.push(new W.Scope("Locals",i,!1)),a.push(new W.Scope("Upvalues",s,!1))}e.body={scopes:a}}catch{e.body={scopes:[]}}this.sendResponse(e)}async variablesRequest(e,t){try{let r=this.variablesMap.get(t.variablesReference);if(r){e.body={variables:r},this.sendResponse(e);return}let a=await this.sendToEngine("variables",{variablesReference:t.variablesReference}),i=[];if(a.body&&Array.isArray(a.body.variables))for(let s of a.body.variables){let o=0;if(s.children&&s.children.length>0){o=this.nextVariableRef++;let l=s.children.map(p=>{let u=0;return p.children&&p.children.length>0&&(u=this.nextVariableRef++,this.variablesMap.set(u,p.children.map(d=>new W.Variable(d.name,d.value,0)))),new W.Variable(p.name,p.value,u)});this.variablesMap.set(o,l)}else s.variablesReference&&(o=s.variablesReference);i.push(new W.Variable(s.name,s.value,o))}this.variablesMap.set(t.variablesReference,i),e.body={variables:i}}catch{e.body={variables:[]}}this.sendResponse(e)}async setVariableRequest(e,t){try{let r=await this.sendToEngine("setVariable",{variablesReference:t.variablesReference,name:t.name,value:t.value});e.body={value:r.body?.value??t.value},this.variablesMap.delete(t.variablesReference)}catch(r){let a=r instanceof Error?r.message:String(r);this.sendErrorResponse(e,1010,`Failed to set variable: ${a}`);return}this.sendResponse(e)}async continueRequest(e,t){this.variablesMap.clear();try{await this.sendToEngine("continue")}catch{}e.body={allThreadsContinued:!0},this.sendResponse(e)}async nextRequest(e,t){this.variablesMap.clear();try{await this.sendToEngine("next")}catch{}this.sendResponse(e)}async stepInRequest(e,t){this.variablesMap.clear();try{await this.sendToEngine("stepIn")}catch{}this.sendResponse(e)}async stepOutRequest(e,t){this.variablesMap.clear();try{await this.sendToEngine("stepOut")}catch{}this.sendResponse(e)}async pauseRequest(e,t){try{await this.sendToEngine("pause")}catch{}this.sendResponse(e)}async evaluateRequest(e,t){try{let r=await this.sendToEngine("evaluate",{expression:t.expression,frameId:t.frameId??0,context:t.context}),a=r.body?.result??"nil",i=r.body?.variablesReference??0;e.body={result:a,variablesReference:i}}catch(r){let a=r instanceof Error?r.message:String(r);e.body={result:`Error: ${a}`,variablesReference:0}}this.sendResponse(e)}completionsRequest(e,t){let r=t.text,a=[];if(r.startsWith("lurek.")){let s=[];try{let o=ne.join(__dirname,"..","data","lurek-api.json");s=(JSON.parse(et.readFileSync(o,"utf8")).modules??[]).map(p=>p.name)}catch{s=["ai","animation","audio","camera","compute","data","ecs","event","filesystem","image","input","math","mods","particle","pathfind","physics","render","save","scene","thread","tilemap","timer","tween","ui","window"]}for(let o of s)o.startsWith(r.slice(5))&&a.push(new W.CompletionItem(o,9))}let i=["local","function","if","then","else","elseif","end","for","while","do","repeat","until","return","break","in","not","and","or","true","false","nil"];for(let s of i)s.startsWith(r)&&a.push(new W.CompletionItem(s,14));e.body={targets:a},this.sendResponse(e)}loadedSourcesRequest(e){e.body={sources:this.loadedSources},this.sendResponse(e)}connectToEngine(e){return new Promise((t,r)=>{let a=0,i=()=>{let s=new Cs.Socket,o=l=>{s.destroy(),a++,a<Ms?(this.log(`Connection attempt ${a} failed, retrying in ${Ss}ms...`),setTimeout(i,Ss)):r(new Error(`Failed to connect to Lurek2D engine on port ${e} after ${Ms} attempts: ${l.message}`))};s.once("error",o),s.connect(e,"127.0.0.1",()=>{s.removeListener("error",o),this.socket=s,this.receiveBuffer="",this.log(`Connected to Lurek2D engine on port ${e}`),s.on("data",l=>{this.onSocketData(l)}),s.on("error",l=>{this.sendEvent(new W.OutputEvent(`Engine connection error: ${l.message}
`,"stderr")),this.cleanup(),this.sendEvent(new W.TerminatedEvent)}),s.on("close",()=>{this.log("Engine connection closed"),this.cleanup(),this.sendEvent(new W.TerminatedEvent)}),t()})};i()})}sendToEngine(e,t){return new Promise((r,a)=>{if(!this.socket||this.socket.destroyed){a(new Error("Not connected to engine"));return}let i=this.nextRequestId++,s=JSON.stringify({id:i,command:e,args:t??{}}),o=`Content-Length: ${Buffer.byteLength(s)}\r
\r
${s}`;this.pendingRequests.set(i,{resolve:r,reject:a});let l=setTimeout(()=>{this.pendingRequests.delete(i),a(new Error(`Request '${e}' timed out`))},1e4),p=this.pendingRequests.get(i);this.pendingRequests.set(i,{resolve:u=>{clearTimeout(l),p.resolve(u)},reject:u=>{clearTimeout(l),p.reject(u)}});try{this.socket.write(o)}catch(u){clearTimeout(l),this.pendingRequests.delete(i),a(u instanceof Error?u:new Error(String(u)))}})}onSocketData(e){for(this.receiveBuffer+=e.toString("utf-8");;){let t=this.receiveBuffer.indexOf(`\r
\r
`);if(t===-1)break;let r=this.receiveBuffer.substring(0,t),a=/Content-Length:\s*(\d+)/i.exec(r);if(!a){this.receiveBuffer=this.receiveBuffer.substring(t+4);continue}let i=parseInt(a[1],10),s=t+4;if(this.receiveBuffer.length<s+i)break;let o=this.receiveBuffer.substring(s,s+i);this.receiveBuffer=this.receiveBuffer.substring(s+i);try{let l=JSON.parse(o);"event"in l?this.handleEngineEvent(l):"id"in l&&this.handleEngineResponse(l)}catch{this.log(`Failed to parse engine message: ${o}`)}}}handleEngineEvent(e){switch(e.event){case"stopped":{let t=new W.StoppedEvent(e.reason??"breakpoint",ks);this.variablesMap.clear(),this.sendEvent(t);break}case"output":{this.sendEvent(new W.OutputEvent(e.output??"",e.category??"console"));break}case"terminated":{this.sendEvent(new W.TerminatedEvent);break}case"breakpointValidated":{if(e.id!==void 0&&e.verified!==void 0)for(let[,t]of this.breakpoints)for(let r of t)r.id===e.id&&(r.verified=e.verified);break}default:this.log(`Unknown engine event: ${e.event}`)}}handleEngineResponse(e){let t=this.pendingRequests.get(e.id);t&&(this.pendingRequests.delete(e.id),e.success?t.resolve(e):t.reject(new Error(e.error??"Unknown engine error")))}findEngineBinary(e){if(e&&et.existsSync(e))return e;let t=require("vscode").workspace.getConfiguration("lurek").get("enginePath","");if(t&&et.existsSync(t))return t;let r=require("vscode").workspace.workspaceFolders?.[0]?.uri.fsPath;if(r){let l=process.platform==="win32"?"lurek2d.exe":"lurek2d",p=[ne.join(r,"build","debug",l),ne.join(r,"build","release",l),ne.join(r,"target","debug",l),ne.join(r,"target","release",l)];for(let u of p)if(et.existsSync(u))return this.log(`Found engine binary: ${u}`),u}let a=process.env.USERPROFILE??process.env.HOME??"",i=[ne.join(a,"bin","lurek2d.exe"),ne.join(a,"bin","lurek2d"),ne.join(a,".local","bin","lurek2d"),"/usr/local/bin/lurek2d"];for(let l of i)if(et.existsSync(l))return l;let s=process.platform==="win32"?"lurek2d.exe":"lurek2d",o=(process.env.PATH??"").split(ne.delimiter);for(let l of o){let p=ne.join(l,s);if(et.existsSync(p))return p}return null}toRelativePath(e){if(this.gamePath&&e.startsWith(this.gamePath)){let t=e.substring(this.gamePath.length);return(t.startsWith(ne.sep)||t.startsWith("/"))&&(t=t.substring(1)),t.replace(/\\/g,"/")}return ne.basename(e)}toAbsolutePath(e){return ne.isAbsolute(e)?e:ne.join(this.gamePath,e)}cleanup(){if(this.socket&&(this.socket.removeAllListeners(),this.socket.destroy(),this.socket=null),this.engineProcess){try{this.engineProcess.kill()}catch{}this.engineProcess=null}for(let[,e]of this.pendingRequests)e.reject(new Error("Debug session ended"));this.pendingRequests.clear(),this.variablesMap.clear()}log(e){this.sendEvent(new W.OutputEvent(`[Lurek2D Debug] ${e}
`,"console"))}};var Pa=class{createDebugAdapterDescriptor(e,t){return new Be.DebugAdapterInlineImplementation(new pr)}},ka=class{resolveDebugConfiguration(e,t,r){if(t.type||(t.type="lurek"),t.request||(t.request="launch"),t.name||(t.name="Lurek2D: Debug Game"),!t.program){let a=e?.uri.fsPath??Be.workspace.workspaceFolders?.[0]?.uri.fsPath,i=Be.window.activeTextEditor?.document.uri.fsPath;if(i){let s=require("path").dirname(i),o=require("path").join(s,"main.lua");require("fs").existsSync(o)?t.program=s:t.program=a??"${workspaceFolder}"}else t.program=a??"${workspaceFolder}"}if(t.luaVersion||(t.luaVersion=Be.workspace.getConfiguration("lurek").get("luaVersion","luajit")),t.stopOnEntry===void 0&&(t.stopOnEntry=!1),t.debugPort||(t.debugPort=8172),!t.enginePath){let a=e?.uri.fsPath??Be.workspace.workspaceFolders?.[0]?.uri.fsPath;if(a){let i=require("path").join(a,"build","debug",process.platform==="win32"?"lurek2d.exe":"lurek2d"),s=require("path").join(a,"build","release",process.platform==="win32"?"lurek2d.exe":"lurek2d");require("fs").existsSync(i)?t.enginePath=i:require("fs").existsSync(s)&&(t.enginePath=s)}}return t}provideDebugConfigurations(e){return[{type:"lurek",request:"launch",name:"Lurek2D: Debug Game",program:"${workspaceFolder}",stopOnEntry:!1},{type:"lurek",request:"launch",name:"Lurek2D: Debug Current Demo",program:"${fileDirname}",stopOnEntry:!1},{type:"lurek",request:"launch",name:"Lurek2D: Debug with Stop on Entry",program:"${workspaceFolder}",stopOnEntry:!0},{type:"lurek",request:"attach",name:"Lurek2D: Attach to Running",debugPort:8172}]}};function Rs(n){let e=new Pa,t=new ka;n.subscriptions.push(Be.debug.registerDebugAdapterDescriptorFactory("lurek",e),Be.debug.registerDebugConfigurationProvider("lurek",t))}var Nt,Ne,ur,Te,me;function Sp(n){Ne=new Xt,ur=new Qt,Te=new Jt,me=new Bt,n.subscriptions.push(Ne,ur,me),Te.load(n.extensionPath).catch(o=>{console.error("Failed to load Lurek2D API data:",o)}),Ne.onStatusChange(o=>{o?ur.setRunning():ur.setStopped()});let e=new Zt,t=new en,r=new tn;n.subscriptions.push(M.window.registerTreeDataProvider("lurek.projectTools",e),M.window.registerTreeDataProvider("lurek.devTools",t),M.window.registerTreeDataProvider("lurek.aiCopilot",r)),Ga(n,Te),Ua(n,Te),Ya(n,Te),Qa(n,Te),Ja(n,Te),Ka(n,Te),Za(n,Te),ti(n,Te),ri(n),ai(n),li(n,Te);let a=new sn;n.subscriptions.push(M.window.registerTreeDataProvider("lurek.assetExplorer",a)),D(n,"lurek.runGame",()=>Ar(Ne)),D(n,"lurek.stopGame",()=>Ri(Ne)),D(n,"lurek.runWithArgs",()=>Ei(Ne)),D(n,"lurek.runExample",()=>dn(Ne)),D(n,"lurek.test.all",()=>_i());let i=["ai","audio","cardgame","combat","compute","config","crafting","data","dataframe","dialog","engine","ecs","event","filesystem","graph","render","graphics_ext","image","input","inventory","math","math_ext","minimap","mods","particle","pathfind","physics","postfx","quest","resource","save","scene","sound","stats","thread","tilemap","timer"];for(let o of i)D(n,`lurek.test.rust.${o}`,()=>Bi(o));if(D(n,"lurek.test.lua.all",()=>Fi()),D(n,"lurek.test.lua.golden",()=>zi()),Zi(n),D(n,"lurek.scaffold.project",()=>Di()),D(n,"lurek.scaffold.file",()=>Ai()),D(n,"lurek.extractToModuleFile",async(...o)=>{let l=o[0],p=o[1];if(!l||!p)return;let u=await M.window.showInputBox({prompt:"New module file name (without .lua)",placeHolder:"my_module",validateInput:y=>/^[a-z_][a-z0-9_]*$/i.test(y)?null:"Use letters, digits, underscores"});if(!u)return;let m=(await M.workspace.openTextDocument(l)).getText(p),h=l.fsPath.replace(/[/\\][^/\\]+$/,""),f=M.Uri.file(`${h}/${u}.lua`),S=new M.WorkspaceEdit;S.createFile(f,{ignoreIfExists:!0}),S.insert(f,new M.Position(0,0),`-- ${u}.lua
local M = {}

${m}

return M
`),S.replace(l,p,`require("${u}")`),await M.workspace.applyEdit(S),await M.window.showTextDocument(f)}),D(n,"lurek.package.zip",()=>Ni()),D(n,"lurek.package.windows",()=>Oi()),D(n,"lurek.package.linux",()=>Wi()),n.subscriptions.push(...Hi(n)),D(n,"lurek.assets.refresh",()=>a.refresh()),D(n,"lurek.assets.openPanel",()=>{M.window.showInformationMessage("Asset Explorer is in the sidebar under Lurek2D.")}),D(n,"lurek.assets.findMissing",()=>pi()),D(n,"lurek.assets.insertPath",o=>{o instanceof lt&&ui(o)}),D(n,"lurek.perf.openDashboard",()=>Cr(n)),D(n,"lurek.perf.clearHistory",()=>{let{clearHistory:o}=(Rr(),Ht(ci));o()}),D(n,"lurek.perf.openHotReload",()=>{let o=M.window.createWebviewPanel("lurek.hotReload","Hot-Reload History",M.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0}),l=[],p=M.workspace.workspaceFolders?.[0]?.uri.fsPath??"",u=M.workspace.createFileSystemWatcher(new M.RelativePattern(p,"**/*.lua")),d=(m,h)=>{l.unshift({time:new Date().toLocaleTimeString(),file:M.workspace.asRelativePath(m),status:h}),l.length>200&&l.pop(),o.webview.postMessage({type:"events",events:l})};u.onDidChange(m=>d(m,"changed")),u.onDidCreate(m=>d(m,"created")),u.onDidDelete(m=>d(m,"deleted")),o.onDidDispose(()=>u.dispose()),o.webview.html=`<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline';"><style>body{font-family:var(--vscode-font-family);background:var(--vscode-editor-background);color:var(--vscode-foreground);padding:12px;margin:0;font-size:12px}h2{margin:0 0 10px;font-size:14px}table{border-collapse:collapse;width:100%}th,td{border:1px solid var(--vscode-panel-border,#444);padding:4px 8px;text-align:left}th{background:var(--vscode-editorWidget-background,#1e1e1e)}.changed{color:#4ec9b0}.created{color:#dcdcaa}.deleted{color:#f44747}#empty{opacity:.5;margin-top:20px}</style></head><body><h2>\u{1F504} Hot-Reload File Watcher</h2><p id="empty">Watching *.lua files \u2014 save a file to see events here.</p><table id="tbl" style="display:none"><thead><tr><th>Time</th><th>File</th><th>Status</th></tr></thead><tbody id="body"></tbody></table><script>window.addEventListener('message',e=>{const{events}=e.data;if(!events||!events.length)return;document.getElementById('empty').style.display='none';document.getElementById('tbl').style.display='';document.getElementById('body').innerHTML=events.map(ev=>'<tr><td>'+ev.time+'</td><td>'+ev.file+'</td><td class="'+ev.status+'">'+ev.status+'</td></tr>').join('');});</script></body></html>`}),D(n,"lurek.deps.showGraph",()=>Or(n)),D(n,"lurek.deps.findCircular",async()=>{let o=M.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!o){M.window.showErrorMessage("No workspace folder open.");return}let l=M.window.createOutputChannel("Lurek2D Circular Deps");l.show(!0),l.appendLine("\u{1F50D} Scanning for circular dependencies...");let p=require("fs"),u=require("path"),d=u.join(o,"src");if(!p.existsSync(d)){l.appendLine("src/ directory not found.");return}let m=p.readdirSync(d,{withFileTypes:!0}).filter(j=>j.isDirectory()).map(j=>j.name),h={};for(let j of m){h[j]=[];let H=u.join(d,j,"mod.rs");if(!p.existsSync(H))continue;let Z=p.readFileSync(H,"utf-8");for(let Re of Z.matchAll(/use crate::([a-z_]+)/g))Re[1]!==j&&m.includes(Re[1])&&!h[j].includes(Re[1])&&h[j].push(Re[1])}let f={},S={},y={},P=[],v=0,x=[];function B(j){f[j]=S[j]=v++,P.push(j),y[j]=!0;for(let H of h[j]||[])f[H]===void 0?(B(H),S[j]=Math.min(S[j],S[H])):y[H]&&(S[j]=Math.min(S[j],f[H]));if(S[j]===f[j]){let H=[],Z;do Z=P.pop(),y[Z]=!1,H.push(Z);while(Z!==j);H.length>1&&x.push(H)}}for(let j of m)f[j]===void 0&&B(j);x.length===0?l.appendLine("\u2705 No circular dependencies found."):(l.appendLine(`\u26A0\uFE0F  Found ${x.length} circular dependency cycle(s):`),x.forEach((j,H)=>l.appendLine(`  Cycle ${H+1}: ${j.join(" \u2192 ")} \u2192 ${j[j.length-1]}`))),l.appendLine(`
Done.`)}),D(n,"lurek.deps.findOrphans",async()=>{let o=M.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!o){M.window.showErrorMessage("No workspace folder open.");return}let l=M.window.createOutputChannel("Lurek2D Orphan Modules");l.show(!0),l.appendLine("\u{1F50D} Scanning for orphan modules...");let p=require("fs"),u=require("path"),d=u.join(o,"src");if(!p.existsSync(d)){l.appendLine("src/ not found.");return}let m=p.readdirSync(d,{withFileTypes:!0}).filter(v=>v.isDirectory()).map(v=>v.name),h=u.join(o,"src","lib.rs"),f=p.existsSync(h)?p.readFileSync(h,"utf-8"):"",S=new Set(m.filter(v=>f.includes(`pub mod ${v}`)||f.includes(`mod ${v}`))),y=new Set;for(let v of m){let x=u.join(d,v,"mod.rs");if(!p.existsSync(x))continue;let B=p.readFileSync(x,"utf-8");for(let j of B.matchAll(/use crate::([a-z_]+)/g))j[1]!==v&&y.add(j[1])}let P=m.filter(v=>!S.has(v)&&!y.has(v));P.length===0?l.appendLine("\u2705 No orphan modules found \u2014 all modules are referenced."):(l.appendLine(`\u26A0\uFE0F  Found ${P.length} potentially orphaned module(s):`),P.forEach(v=>l.appendLine(`  \u2022 ${v}`))),l.appendLine(`
Done.`)}),mi(n,Te),D(n,"lurek.debug.openWatchers",()=>fi(n)),D(n,"lurek.debug.openInspector",()=>{let o=M.window.createWebviewPanel("lurekVariableInspector","Lurek2D Variable Inspector",M.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0}),l=u=>`<!DOCTYPE html><html><head>
<meta charset="UTF-8">
<style>
  body{font-family:var(--vscode-font-family);font-size:13px;padding:12px;color:var(--vscode-editor-foreground);background:var(--vscode-editor-background)}
  h2{margin:0 0 10px;font-size:14px;color:var(--vscode-titleBar-activeForeground)}
  table{width:100%;border-collapse:collapse}
  th{background:var(--vscode-editor-selectionBackground);text-align:left;padding:6px 8px;font-size:12px}
  td{padding:5px 8px;border-bottom:1px solid var(--vscode-panel-border)}
  .type{color:var(--vscode-symbolIcon-typeForeground);font-size:11px}
  .val{color:var(--vscode-debugTokenExpression-value)}
  .empty{color:var(--vscode-disabledForeground);padding:16px;text-align:center}
  button{margin-top:12px;padding:5px 12px;background:var(--vscode-button-background);color:var(--vscode-button-foreground);border:none;cursor:pointer;border-radius:3px}
  button:hover{background:var(--vscode-button-hoverBackground)}
  .toolbar{display:flex;gap:8px;margin-bottom:12px}
  input{flex:1;padding:5px 8px;background:var(--vscode-input-background);border:1px solid var(--vscode-input-border);color:var(--vscode-input-foreground);border-radius:3px}
</style>
</head><body>
<h2>\u{1F50D} Variable Inspector</h2>
<div class="toolbar">
  <input id="expr" type="text" placeholder="Enter Lua expression, e.g. player.x" />
  <button onclick="addExpr()">Watch</button>
  <button onclick="clearAll()">Clear</button>
</div>
<table>
  <thead><tr><th>Expression</th><th>Value</th><th>Type</th></tr></thead>
  <tbody id="rows">${u.length===0?'<tr><td colspan="3" class="empty">No watched expressions. Enter a Lua expression above.</td></tr>':u.map(d=>`<tr><td>${d.expr}</td><td class="val">${d.value}</td><td class="type">${d.type}</td></tr>`).join("")}</tbody>
</table>
<script>
  const vscode = acquireVsCodeApi();
  function addExpr(){ const e=document.getElementById('expr'); if(e.value.trim()) vscode.postMessage({cmd:'watch',expr:e.value.trim()}); e.value=''; }
  function clearAll(){ vscode.postMessage({cmd:'clear'}); }
  document.getElementById('expr').addEventListener('keydown',e=>{ if(e.key==='Enter') addExpr(); });
  window.addEventListener('message',e=>{ if(e.data.cmd==='refresh') location.reload(); });
</script>
</body></html>`,p=[];o.webview.html=l(p),o.webview.onDidReceiveMessage(async u=>{if(u.cmd==="watch"){let d="(not connected \u2014 run game with debug bridge)",m="?";try{let{DebugBridge:h}=await Promise.resolve().then(()=>(Gr(),rs));if(h.instance?.isConnected()){let f=await h.instance.evaluate(u.expr);d=f?.resultString??"(nil)",m=f?.luaType??"?"}}catch{}p.push({expr:u.expr,value:d,type:m}),o.webview.html=l(p)}else u.cmd==="clear"&&(p.length=0,o.webview.html=l(p))},void 0,n.subscriptions)}),D(n,"lurek.debug.openCallStack",()=>{M.window.showInformationMessage("Call stack available when connected to the Lua debug bridge.")}),D(n,"lurek.debug.addWatch",()=>{let o=M.window.activeTextEditor;o&&vi(o)}),D(n,"lurek.runtime.openMonitor",()=>ki(n)),D(n,"lurek.api.usageReport",()=>Ci(n)),D(n,"lurek.api.quickInsert",()=>ji(Te)),typeof me.onConnected=="function"){let o=me;o.onConnected(()=>Ir(!0)),o.onDisconnected?.(()=>Ir(!1)),o.evaluate&&gi(async l=>{try{let p=await o.evaluate(l);return{value:String(p),type:typeof p}}catch{return}})}D(n,"lurek.browseApi",()=>qn()),D(n,"lurek.openApiDocs",()=>Vi()),D(n,"lurek.openWiki",()=>qi()),D(n,"lurek.depGraph",()=>Or(n)),D(n,"lurek.depList",()=>$i()),D(n,"lurek.apiCoverage",()=>{let o=M.window.createTerminal("Lurek2D API Coverage");o.show(),o.sendText("python tools/integration_coverage.py")}),as(n,me),Rs(n),D(n,"lurek.debug.runAndConnect",async()=>{await Ar(Ne),await new Promise(l=>setTimeout(l,1500)),await me.connect()?(M.commands.executeCommand("setContext","lurek.debugConnected",!0),me.startStatsPolling(),M.window.showInformationMessage("Lurek2D started and debug bridge connected.")):M.window.showWarningMessage("Game launched but debug bridge could not connect. Is debug bridge enabled in conf.lua?")}),D(n,"lurek.debug.performance",()=>{if(!me.isConnected){M.window.showErrorMessage("Not connected to Lurek2D engine. Run 'Lurek2D: Debug Connect' first.");return}let o=M.window.createWebviewPanel("lurek.debugPerf","Lurek2D Live Performance",M.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0});o.webview.html=`<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline';">
<style>
  body{font-family:var(--vscode-font-family);color:var(--vscode-foreground);background:var(--vscode-editor-background);padding:16px;margin:0}
  .row{display:flex;gap:24px;margin-bottom:16px;flex-wrap:wrap}
  .metric{background:var(--vscode-editorWidget-background,#1e1e1e);border-radius:6px;padding:12px 20px;min-width:130px;text-align:center}
  .val{font-size:36px;font-weight:700;margin:4px 0;color:var(--vscode-charts-blue,#569cd6)}
  .lbl{font-size:11px;opacity:.6;text-transform:uppercase;letter-spacing:.04em}
  canvas{display:block;width:100%;height:80px;margin-top:6px}
  h2{margin:0 0 12px;font-size:14px}
  .fps-ok{color:#4ec9b0}.fps-warn{color:#dcdcaa}.fps-bad{color:#f44747}
</style></head><body>
<h2>\u26A1 Live Engine Stats</h2>
<div class="row">
  <div class="metric"><div class="val fps-ok" id="fps">--</div><div class="lbl">FPS</div></div>
  <div class="metric"><div class="val" id="dc">--</div><div class="lbl">Draw Calls</div></div>
  <div class="metric"><div class="val" id="mem">--</div><div class="lbl">Memory MB</div></div>
</div>
<canvas id="fpsChart"></canvas>
<script>
const vscode=acquireVsCodeApi(),hist=[];
function draw(){const c=document.getElementById('fpsChart');if(!c)return;const W=c.offsetWidth||600;c.width=W;c.height=80;const ctx=c.getContext('2d');ctx.clearRect(0,0,W,80);if(hist.length<2)return;const mx=Math.max(...hist,1);ctx.strokeStyle='#4ec9b0';ctx.lineWidth=1.5;ctx.beginPath();hist.forEach((v,i)=>{const x=i/(hist.length-1)*W,y=80-(v/mx)*74-3;i===0?ctx.moveTo(x,y):ctx.lineTo(x,y)});ctx.stroke();ctx.lineTo(W,80);ctx.lineTo(0,80);ctx.closePath();const g=ctx.createLinearGradient(0,0,0,80);g.addColorStop(0,'#4ec9b033');g.addColorStop(1,'#4ec9b000');ctx.fillStyle=g;ctx.fill()}
window.addEventListener('message',e=>{if(e.data.type==='stats'){const{fps,drawCalls,memory}=e.data;document.getElementById('fps').textContent=fps;document.getElementById('fps').className='val '+(fps>=55?'fps-ok':fps>=25?'fps-warn':'fps-bad');document.getElementById('dc').textContent=drawCalls;document.getElementById('mem').textContent=(memory/1024/1024).toFixed(1);hist.push(fps);if(hist.length>120)hist.shift();draw()}});
window.addEventListener('resize',draw);
</script></body></html>`;let l=setInterval(async()=>{if(!me.isConnected){clearInterval(l);return}try{let p=await me.getStats();o.webview.postMessage({type:"stats",...p})}catch{}},500);o.onDidDispose(()=>clearInterval(l))}),D(n,"lurek.debug.printHistory",()=>{me.showOutput()}),D(n,"lurek.debug.screenshot",async()=>{if(!me.isConnected){M.window.showErrorMessage("Not connected to Lurek2D engine. Run 'Lurek2D: Debug Connect' first.");return}try{let o=await me.takeScreenshot();if(!o){M.window.showWarningMessage("Engine did not return screenshot data.");return}let l=Buffer.from(o,"base64"),p=M.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!p){M.window.showErrorMessage("No workspace folder.");return}let u=new Date().toISOString().replace(/[:.]/g,"-"),d=require("path").join(p,`screenshot-${u}.png`);require("fs").writeFileSync(d,l);let m=M.Uri.file(d);await M.commands.executeCommand("vscode.open",m),M.window.showInformationMessage(`Screenshot saved: screenshot-${u}.png`)}catch(o){M.window.showErrorMessage(`Screenshot failed: ${o instanceof Error?o.message:String(o)}`)}}),D(n,"lurek.debug.callStack",async()=>{if(!me.isConnected){M.window.showErrorMessage("Not connected to Lurek2D engine. Run 'Lurek2D: Debug Connect' first.");return}try{let o=await me.getCallStack();if(o.length===0){M.window.showInformationMessage("Call stack is empty (game may not be paused).");return}let l=o.map(u=>({label:`#${u.level} ${u.name}`,description:`${u.source}:${u.line}`,detail:`${u.source} line ${u.line}`,source:u.source,line:u.line})),p=await M.window.showQuickPick(l,{title:"Lua Call Stack",placeHolder:"Select a frame to navigate to"});if(p?.source&&p.source!=="?"&&p.source!=="[C]"){let u=p.source.startsWith("@")?p.source.slice(1):p.source,d=M.workspace.workspaceFolders?.[0]?.uri.fsPath;if(d){let m=require("path").join(d,u);if(require("fs").existsSync(m)){let h=await M.workspace.openTextDocument(m);await M.window.showTextDocument(h,{selection:new M.Range(p.line-1,0,p.line-1,0)})}}}}catch(o){M.window.showErrorMessage(`Call stack failed: ${o instanceof Error?o.message:String(o)}`)}}),D(n,"lurek.debug.status",async()=>{let o=me.getStatusInfo();if(!o.connected)await M.window.showInformationMessage(`Lurek2D debug bridge: NOT connected (port ${o.port})`,"Connect Now","Dismiss")==="Connect Now"&&M.commands.executeCommand("lurek.debug.connect");else try{let l=await me.getStats();M.window.showInformationMessage(`Lurek2D connected on port ${o.port} \xB7 FPS: ${l.fps} \xB7 Draw calls: ${l.drawCalls} \xB7 Memory: ${(l.memory/1024/1024).toFixed(1)} MB`)}catch{M.window.showInformationMessage(`Lurek2D debug bridge connected on port ${o.port}.`)}}),D(n,"lurek.cag.install",()=>Ui()),D(n,"lurek.cag.selectAgent",()=>Yi()),D(n,"lurek.cag.selectSkill",()=>Xi()),D(n,"lurek.cag.selectPrompt",()=>Qi()),D(n,"lurek.cag.update",()=>{M.window.showInformationMessage("CAG update is not yet implemented.")}),D(n,"lurek.mcp.install",()=>{M.window.showInformationMessage("MCP server installation is not yet implemented.")}),D(n,"lurek.mcp.status",()=>{M.window.showInformationMessage(Nt?"MCP server is running.":"MCP server is not running.")}),is(n),D(n,"lurek.jam.quickBuild",()=>{let o=M.window.createTerminal("Lurek2D Quick Build");o.show(),o.sendText(Ia("release"))}),D(n,"lurek.jam.checklist",()=>{M.window.showInformationMessage("Submission Checklist is not yet implemented.")}),os(n),ps(n),D(n,"lurek2d.runExample",()=>dn(Ne)),D(n,"lurek2d.listExamples",()=>dn(Ne)),D(n,"lurek2d.checkBuild",()=>{let o=M.window.createTerminal("Lurek2D Build Check");o.show(),o.sendText(Da())}),D(n,"lurek2d.getApiDoc",()=>qn()),D(n,"lurek2d.scanAllGames",async()=>{if(!Es()){M.window.showErrorMessage("No workspace open.");return}let l=await M.workspace.findFiles("content/games/**/main.lua","**/node_modules/**");if(l.length===0){M.window.showInformationMessage("No game main.lua files found.");return}await M.window.withProgress({location:M.ProgressLocation.Notification,title:`Scanning ${l.length} games\u2026`,cancellable:!1},async p=>{let u=0;for(let d of l){try{let m=await M.workspace.openTextDocument(d);await M.window.showTextDocument(m,{preview:!0,preserveFocus:!0})}catch{}u++,p.report({increment:100/l.length,message:`${u}/${l.length}`})}}),await M.commands.executeCommand("workbench.action.problems.focus"),M.window.showInformationMessage(`Scanned ${l.length} games. Check the Problems panel for errors.`)});let s=Es();s&&(Nt=za(s)),Ls(n),n.subscriptions.push(M.workspace.onDidChangeConfiguration(o=>{o.affectsConfiguration("lurek.luaVersion")&&(Te.load(n.extensionPath).catch(l=>{console.error("Failed to reload Lurek2D API data:",l)}),Ls(n))})),M.commands.executeCommand("setContext","lurek.gameRunning",!1)}function Cp(){Nt&&(Nt.kill(),Nt=void 0)}function D(n,e,t){n.subscriptions.push(M.commands.registerCommand(e,t))}function Es(){return M.workspace.workspaceFolders?.[0]?.uri.fsPath}function Ls(n){let e=M.workspace.workspaceFolders?.[0]?.uri.fsPath,t=e?dr.join(e,"docs","api"):void 0,r=dr.join(n.extensionPath,"data"),a=t&&Is.existsSync(dr.join(t,"lurek.lua"))?t:r,i=M.workspace.getConfiguration("Lua"),s=i.get("workspace.library")??[];if(!s.includes(a)){let u=[...s.filter(d=>!d.includes("lurek2d-toolkit")),a];i.update("workspace.library",u,M.ConfigurationTarget.Global).then(void 0,()=>{})}let l=M.workspace.getConfiguration("lurek").get("luaVersion","luajit")==="lua54"?"Lua 5.4":"LuaJIT";i.update("runtime.version",l,M.ConfigurationTarget.Global).then(void 0,()=>{})}0&&(module.exports={activate,deactivate});
