"use strict";var gr=Object.create;var qt=Object.defineProperty;var hr=Object.getOwnPropertyDescriptor;var vr=Object.getOwnPropertyNames;var yr=Object.getPrototypeOf,br=Object.prototype.hasOwnProperty;var Yt=(n,e)=>()=>(n&&(e=n(n=0)),e);var je=(n,e)=>()=>(e||n((e={exports:{}}).exports,e),e.exports),Gt=(n,e)=>{for(var t in e)qt(n,t,{get:e[t],enumerable:!0})},Ls=(n,e,t,o)=>{if(e&&typeof e=="object"||typeof e=="function")for(let s of vr(e))!br.call(n,s)&&s!==t&&qt(n,s,{get:()=>e[s],enumerable:!(o=hr(e,s))||o.enumerable});return n};var E=(n,e,t)=>(t=n!=null?gr(yr(n)):{},Ls(e||!n||!n.__esModule?qt(t,"default",{value:n,enumerable:!0}):t,n)),Vt=n=>Ls(qt({},"__esModule",{value:!0}),n);function Ve(n){return[ot.join(n,"docs","API","lurek.lua"),ot.join(n,"docs","API","lua-api.md"),ot.join(n,"docs","API","lua_api_reference_generated.md"),ot.join(n,"docs","lua-api.md")].find(t=>Rs.existsSync(t))}function Ds(n,e){return ho(e)?xr(n):wr(n)}function go(n,e,t){return ho(e)?kr(n,t):Sr(n,t)}function Ms(n,e,t){return ho(e)?Er(n,t):Cr(n,t)}function ho(n){return ot.basename(n).toLowerCase()==="lurek.lua"}function xr(n){let e=n.split(`
`),t=new Map;for(let o=0;o<e.length;o++){let s=e[o].trim(),i=s.match(/^---@class\s+(lurek\.[A-Za-z0-9_]+)\s*$/);if(i){let c=i[1];t.has(c)||t.set(c,{label:c,line:o,kind:"module"});continue}let a=s.match(/^function\s+(lurek\.[A-Za-z0-9_]+\.[A-Za-z0-9_]+)\(/);if(a){let c=a[1];t.has(c)||t.set(c,{label:c,line:o,kind:"function"});continue}let r=s.match(/^function\s+(lurek\.[A-Za-z0-9_]+)\(/);if(r&&r[1].split(".").length===2){let c=r[1];t.has(c)||t.set(c,{label:c,line:o,kind:"callback"});continue}let l=s.match(/^function\s+([A-Za-z_][A-Za-z0-9_]*)[:.]([A-Za-z0-9_]+)\(/);if(l){let c=`${l[1]}:${l[2]}`;t.has(c)||t.set(c,{label:c,line:o,kind:"method"})}}return Array.from(t.values()).sort((o,s)=>o.label.localeCompare(s.label))}function wr(n){return n.split(`
`).map((e,t)=>({line:e,index:t})).filter(({line:e})=>e.startsWith("## ")||e.startsWith("### ")).map(({line:e,index:t})=>({label:e.replace(/^#+\s*/,""),line:t,kind:"section"}))}function kr(n,e){let t=n.split(`
`),o=[`function ${e}(`,`---@class ${e}`];for(let s=0;s<t.length;s++){let i=t[s].trim();if(o.some(a=>i.startsWith(a)))return s}return-1}function Sr(n,e){let t=e.replace(/^lurek\./,"");return n.split(`
`).findIndex(o=>o.startsWith("##")&&(o.includes(e)||o.includes(t)))}function Er(n,e){let t=e.toLowerCase(),s=Tr(n).filter(r=>r.text.toLowerCase().includes(t)).map(r=>r.text.trim()).filter(Boolean);if(s.length>0)return fo(s);let i=n.split(`
`),a=[];for(let r=0;r<i.length;r++){if(!i[r].toLowerCase().includes(t))continue;let l=Math.max(0,r-3),c=Math.min(i.length,r+4);a.push(i.slice(l,c).join(`
`).trim())}return fo(a.filter(Boolean))}function Cr(n,e){let t=n.split(`
`),o=e.toLowerCase(),s=[],i=[],a=!1;for(let r of t){if(r.startsWith("##")){a&&i.length>0&&s.push(i.join(`
`).trim()),i=[r],a=r.toLowerCase().includes(o);continue}i.push(r),r.toLowerCase().includes(o)&&(a=!0)}return a&&i.length>0&&s.push(i.join(`
`).trim()),fo(s.filter(Boolean))}function Tr(n){let e=n.split(`
`),t=[];for(let s=0;s<e.length;s++){let i=e[s].trim();if(!Ir(i))continue;let a=s;for(;a>0&&e[a-1].trim().startsWith("---");)a--;t.push(a)}let o=Array.from(new Set(t)).sort((s,i)=>s-i);return o.map((s,i)=>{let a=i+1<o.length?o[i+1]:e.length;return{startLine:s,text:e.slice(s,a).join(`
`)}})}function Ir(n){return/^---@class\s+lurek\./.test(n)||/^function\s+lurek\.[A-Za-z0-9_]+\.[A-Za-z0-9_]+\(/.test(n)||/^function\s+lurek\.[A-Za-z0-9_]+\(/.test(n)||/^function\s+[A-Za-z_][A-Za-z0-9_]*[:.][A-Za-z0-9_]+\(/.test(n)}function fo(n){return Array.from(new Set(n))}var Rs,ot,Xt=Yt(()=>{"use strict";Rs=E(require("fs")),ot=E(require("path"))});var yo={};Gt(yo,{getToolDefinitions:()=>Pr,handleCheckBuild:()=>Ar,handleGetApiDoc:()=>Rr,handleGetLogs:()=>Fr,handleListExamples:()=>Dr,handleRunExample:()=>Lr,handleRunLuaTest:()=>Mr});function Pr(){return[{name:"lurek2d.runExample",description:"Build and run a named Lurek2D example, returning its output.",inputSchema:{type:"object",properties:{name:{type:"string",description:'Name of the example directory (e.g. "hello_world").'}},required:["name"]}},{name:"lurek2d.getApiDoc",description:"Search the Lurek2D Lua API documentation for a query string.",inputSchema:{type:"object",properties:{query:{type:"string",description:'Search query (e.g. "lurek.graphics.draw" or "physics").'}},required:["query"]}},{name:"lurek2d.listExamples",description:"List all available Lurek2D example directories.",inputSchema:{type:"object",properties:{}}},{name:"lurek2d.runLuaTest",description:"Run a Lua test file against a debug build of Lurek2D.",inputSchema:{type:"object",properties:{file:{type:"string",description:"Path to the Lua test file, relative to workspace root."}},required:["file"]}},{name:"lurek2d.checkBuild",description:"Run `cargo check` and return compiler diagnostics.",inputSchema:{type:"object",properties:{}}},{name:"lurek2d.getLogs",description:"Return the last N lines of Lurek2D engine log output.",inputSchema:{type:"object",properties:{lines:{type:"number",description:"Number of log lines to return (default: 50)."}}}}]}function vo(n,e,t=6e4){return new Promise(o=>{As.exec(n,{cwd:e,timeout:t,maxBuffer:1024*1024},(s,i,a)=>{let r=(i||"")+(a||"");o(s?`${r}
[exit code: ${s.code??"unknown"}]`:r||"(no output)")})})}function Lr(n){return async e=>{let t=e.name;if(!t)return"Error: 'name' parameter is required.";let o=st.join(n,"demos",t);if(!Re.existsSync(o)){let s=Fs(n);return`Demo "${t}" not found. Available: ${s.join(", ")}`}return vo(`cargo run -- content/content/demos/${t}`,n,12e4)}}function Rr(n){return async e=>{let t=e.query;if(!t)return"Error: 'query' parameter is required.";let o=Ve(n);if(!o||!Re.existsSync(o))return"API reference not found. Expected docs/API/lurek.lua or docs/API/lua-api.md.";let s=Re.readFileSync(o,"utf-8"),i=Ms(s,o,t);return i.length===0?`No documentation found for "${t}".`:o.endsWith(".lua")?i.map(a=>`\`\`\`lua
${a}
\`\`\``).join(`

---

`):i.join(`

---

`)}}function Dr(n){return async()=>{let e=Fs(n);return e.length===0?"No demos found in content/content/demos/ directory.":e.join(`
`)}}function Mr(n){return async e=>{let t=e.file;if(!t)return"Error: 'file' parameter is required.";let o=st.resolve(n,t);return o.startsWith(n)?Re.existsSync(o)?vo(`cargo run -- ${t}`,n,12e4):`Test file not found: ${t}`:"Error: file path must be within the workspace."}}function Ar(n){return async()=>vo("cargo check 2>&1",n,12e4)}function Fr(n){return async e=>{let t=e.lines||50,o=[st.join(n,"lurek2d.log"),st.join(n,"target","lurek2d.log")];for(let s of o)if(Re.existsSync(s))return Re.readFileSync(s,"utf-8").split(`
`).slice(-t).join(`
`);return"No log file found. Engine logs are written to stdout by default. Use RUST_LOG=lurek2d=debug to enable verbose logging."}}function Fs(n){let e=st.join(n,"demos");if(!Re.existsSync(e))return[];try{return Re.readdirSync(e,{withFileTypes:!0}).filter(t=>t.isDirectory()).map(t=>t.name)}catch{return[]}}var As,Re,st,bo=Yt(()=>{"use strict";As=E(require("child_process")),Re=E(require("fs")),st=E(require("path"));Xt()});var Ui={};Gt(Ui,{clearHistory:()=>Xi,openPerfDashboard:()=>Do,recordSample:()=>gd});function Do(n){if(Me){Me.reveal(Dt.ViewColumn.Two);return}Me=Dt.window.createWebviewPanel("lurek.perfDashboard","Lurek2D Performance",Dt.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0}),Me.webview.html=hd(),Me.onDidDispose(()=>{Me=void 0},null,n.subscriptions),Me.webview.onDidReceiveMessage(e=>{e.type==="clear"&&Xi()},null,n.subscriptions),Mo()}function gd(n,e,t){Rt.push({timestamp:Date.now(),fps:n,frameMs:e,luaHeapKb:t}),Rt.length>fd&&Rt.shift(),Me?.visible&&Mo()}function Xi(){Rt.length=0,Me?.visible&&Mo()}function Mo(){Me&&Me.webview.postMessage({type:"data",samples:[...Rt]})}function hd(){return`<!DOCTYPE html>
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
</html>`}var Dt,Me,Rt,fd,Ao=Yt(()=>{"use strict";Dt=E(require("vscode")),Rt=[],fd=300});var Oa={};Gt(Oa,{DebugBridge:()=>Ot});var We,$a,_a,_d,$d,Ot,Go=Yt(()=>{"use strict";We=E(require("vscode")),$a=E(require("net")),_a=19740,_d=5e3,$d=1e4,Ot=class{socket=null;outputChannel;connected=!1;requestId=0;pending=new Map;buffer="";statsItem=null;statsInterval=null;constructor(){this.outputChannel=We.window.createOutputChannel("Lurek2D Debug")}get isConnected(){return this.connected}async connect(e){if(this.connected)return this.outputChannel.appendLine("[debug] Already connected."),!0;let t=e??We.workspace.getConfiguration("lurek.debugBridge").get("port",_a);return new Promise(o=>{let s=new $a.Socket,i=setTimeout(()=>{s.destroy(),this.outputChannel.appendLine(`[debug] Connection timed out on port ${t}`),o(!1)},_d);s.connect(t,"127.0.0.1",()=>{clearTimeout(i),this.socket=s,this.connected=!0,this.buffer="",this.outputChannel.appendLine(`[debug] Connected to Lurek2D on port ${t}`),o(!0)}),s.on("data",a=>this.onData(a)),s.on("error",a=>{clearTimeout(i),this.outputChannel.appendLine(`[debug] Connection error: ${a.message}`),this.cleanup(),o(!1)}),s.on("close",()=>{this.outputChannel.appendLine("[debug] Connection closed."),this.cleanup()})})}disconnect(){this.socket&&this.socket.destroy(),this.cleanup(),this.outputChannel.appendLine("[debug] Disconnected.")}async evaluate(e){let t=await this.sendRequest("evaluate",{expression:e});if(t.error)throw new Error(t.error);return String(t.data?.result??"nil")}async getVariables(){let e=await this.sendRequest("getVariables",{});if(e.error)throw new Error(e.error);let t=e.data?.variables;if(t&&typeof t=="object"){let o={};for(let[s,i]of Object.entries(t))o[s]=String(i);return o}return{}}async setBreakpoint(e,t){return!(await this.sendRequest("setBreakpoint",{file:e,line:t})).error}async removeBreakpoint(e,t){return!(await this.sendRequest("removeBreakpoint",{file:e,line:t})).error}async step(){await this.sendRequest("step",{})}async stepInto(){await this.sendRequest("stepInto",{})}async stepOut(){await this.sendRequest("stepOut",{})}async continueExecution(){await this.sendRequest("continue",{})}async hotReload(e){let o=(await We.workspace.openTextDocument(e)).getText(),s=We.workspace.asRelativePath(e,!1);return!(await this.sendRequest("hotReload",{file:s,content:o})).error}async getStats(){let e=await this.sendRequest("getStats",{});if(e.error)throw new Error(e.error);return{fps:Number(e.data?.fps??0),drawCalls:Number(e.data?.drawCalls??0),memory:Number(e.data?.memory??0)}}async getCallStack(){let e=await this.sendRequest("getCallStack",{});if(e.error)throw new Error(e.error);let t=e.data?.frames;return Array.isArray(t)?t.map((o,s)=>({level:s,source:String(o.source??"?"),line:Number(o.line??0),name:String(o.name??"?")})):[]}async takeScreenshot(){let e=await this.sendRequest("screenshot",{});if(e.error)throw new Error(e.error);return String(e.data?.png_base64??"")}getStatusInfo(){return{connected:this.connected,port:We.workspace.getConfiguration("lurek.debugBridge").get("port",_a)}}startStatsPolling(){this.statsItem||(this.statsItem=We.window.createStatusBarItem(We.StatusBarAlignment.Right,50),this.statsItem.text="$(pulse) FPS: --",this.statsItem.tooltip="Lurek2D Engine Stats",this.statsItem.show(),this.statsInterval=setInterval(async()=>{if(!this.connected){this.stopStatsPolling();return}try{let e=await this.getStats();this.statsItem&&(this.statsItem.text=`$(pulse) FPS: ${e.fps} | Draw: ${e.drawCalls} | Mem: ${(e.memory/1024/1024).toFixed(1)}MB`)}catch{}},1e3))}stopStatsPolling(){this.statsInterval&&(clearInterval(this.statsInterval),this.statsInterval=null),this.statsItem&&(this.statsItem.dispose(),this.statsItem=null)}showOutput(){this.outputChannel.show()}dispose(){this.disconnect(),this.stopStatsPolling(),this.outputChannel.dispose()}sendRequest(e,t){return new Promise((o,s)=>{if(!this.connected||!this.socket){s(new Error("Not connected to Lurek2D engine."));return}let i=++this.requestId,a=JSON.stringify({id:i,type:e,data:t})+`
`,r=setTimeout(()=>{this.pending.delete(i),s(new Error(`Request ${e} timed out.`))},$d);this.pending.set(i,{resolve:o,reject:s,timer:r}),this.socket.write(a,l=>{l&&(clearTimeout(r),this.pending.delete(i),s(new Error(`Failed to send request: ${l.message}`)))})})}onData(e){this.buffer+=e.toString("utf-8");let t=this.buffer.split(`
`);this.buffer=t.pop()??"";for(let o of t){let s=o.trim();if(s)try{let i=JSON.parse(s),a=this.pending.get(i.id);a?(clearTimeout(a.timer),this.pending.delete(i.id),a.resolve(i)):this.outputChannel.appendLine(`[engine] ${s}`)}catch{this.outputChannel.appendLine(`[engine] ${s}`)}}}cleanup(){this.connected=!1,this.socket=null;for(let[,e]of this.pending)clearTimeout(e.timer),e.reject(new Error("Connection lost."));this.pending.clear(),this.stopStatsPolling()}}});var Qn=je(tt=>{"use strict";Object.defineProperty(tt,"__esModule",{value:!0});tt.Event=tt.Response=tt.Message=void 0;var Wt=class{constructor(e){this.seq=0,this.type=e}};tt.Message=Wt;var Uo=class extends Wt{constructor(e,t){super("response"),this.request_seq=e.seq,this.command=e.command,t?(this.success=!1,this.message=t):this.success=!0}};tt.Response=Uo;var Ko=class extends Wt{constructor(e,t){super("event"),this.event=e,t&&(this.body=t)}};tt.Event=Ko});var Va=je(to=>{"use strict";Object.defineProperty(to,"__esModule",{value:!0});to.ProtocolServer=void 0;var Ud=require("events"),Ht=Qn(),Jo=class{get event(){return this._event||(this._event=(e,t)=>{this._listener=e,this._this=t;let o;return o={dispose:()=>{this._listener=void 0,this._this=void 0}},o}),this._event}fire(e){if(this._listener)try{this._listener.call(this._this,e)}catch{}}hasListener(){return!!this._listener}dispose(){this._listener=void 0,this._this=void 0}},eo=class n extends Ud.EventEmitter{constructor(){super(),this._sendMessage=new Jo,this._sequence=1,this._pendingRequests=new Map,this.onDidSendMessage=this._sendMessage.event}dispose(){}handleMessage(e){if(e.type==="request")this.dispatchRequest(e);else if(e.type==="response"){let t=e,o=this._pendingRequests.get(t.request_seq);o&&(this._pendingRequests.delete(t.request_seq),o(t))}}_isRunningInline(){return this._sendMessage&&this._sendMessage.hasListener()}start(e,t){this._writableStream=t,this._rawData=Buffer.alloc(0),e.on("data",o=>this._handleData(o)),e.on("close",()=>{this._emitEvent(new Ht.Event("close"))}),e.on("error",o=>{this._emitEvent(new Ht.Event("error","inStream error: "+(o&&o.message)))}),t.on("error",o=>{this._emitEvent(new Ht.Event("error","outStream error: "+(o&&o.message)))}),e.resume()}stop(){this._writableStream&&this._writableStream.end()}sendEvent(e){this._send("event",e)}sendResponse(e){e.seq>0?console.error(`attempt to send more than one response for command ${e.command}`):this._send("response",e)}sendRequest(e,t,o,s){let i={command:e};if(t&&Object.keys(t).length>0&&(i.arguments=t),this._send("request",i),s){this._pendingRequests.set(i.seq,s);let a=setTimeout(()=>{clearTimeout(a);let r=this._pendingRequests.get(i.seq);r&&(this._pendingRequests.delete(i.seq),r(new Ht.Response(i,"timeout")))},o)}}dispatchRequest(e){}_emitEvent(e){this.emit(e.event,e)}_send(e,t){if(t.type=e,t.seq=this._sequence++,this._writableStream){let o=JSON.stringify(t);this._writableStream.write(`Content-Length: ${Buffer.byteLength(o,"utf8")}\r
\r
${o}`,"utf8")}this._sendMessage.fire(t)}_handleData(e){for(this._rawData=Buffer.concat([this._rawData,e]);;){if(this._contentLength>=0){if(this._rawData.length>=this._contentLength){let t=this._rawData.toString("utf8",0,this._contentLength);if(this._rawData=this._rawData.slice(this._contentLength),this._contentLength=-1,t.length>0)try{let o=JSON.parse(t);this.handleMessage(o)}catch(o){this._emitEvent(new Ht.Event("error","Error handling data: "+(o&&o.message)))}continue}}else{let t=this._rawData.indexOf(n.TWO_CRLF);if(t!==-1){let s=this._rawData.toString("utf8",0,t).split(`\r
`);for(let i=0;i<s.length;i++){let a=s[i].split(/: +/);a[0]=="Content-Length"&&(this._contentLength=+a[1])}this._rawData=this._rawData.slice(t+n.TWO_CRLF.length);continue}}break}}};to.ProtocolServer=eo;eo.TWO_CRLF=`\r
\r
`});var Xa=je(no=>{"use strict";Object.defineProperty(no,"__esModule",{value:!0});no.runDebugAdapter=void 0;var Kd=require("net");function Jd(n){let e=0;if(process.argv.slice(2).forEach(function(o,s,i){let a=/^--server=(\d{4,5})$/.exec(o);a&&(e=parseInt(a[1],10))}),e>0)console.error(`waiting for debug protocol on port ${e}`),Kd.createServer(o=>{console.error(">> accepted connection from client"),o.on("end",()=>{console.error(`>> client connection closed
`)});let s=new n(!1,!0);s.setRunAsServer(!0),s.start(o,o)}).listen(e);else{let o=new n(!1);process.on("SIGTERM",()=>{o.shutdown()}),o.start(process.stdin,process.stdout)}}no.runDebugAdapter=Jd});var so=je(F=>{"use strict";Object.defineProperty(F,"__esModule",{value:!0});F.DebugSession=F.ErrorDestination=F.MemoryEvent=F.InvalidatedEvent=F.ProgressEndEvent=F.ProgressUpdateEvent=F.ProgressStartEvent=F.CapabilitiesEvent=F.LoadedSourceEvent=F.ModuleEvent=F.BreakpointEvent=F.ThreadEvent=F.OutputEvent=F.ExitedEvent=F.TerminatedEvent=F.InitializedEvent=F.ContinuedEvent=F.StoppedEvent=F.CompletionItem=F.Module=F.Breakpoint=F.Variable=F.Thread=F.StackFrame=F.Scope=F.Source=void 0;var Zd=Va(),fe=Qn(),Qd=Xa(),Ua=require("url"),Zo=class{constructor(e,t,o=0,s,i){this.name=e,this.path=t,this.sourceReference=o,s&&(this.origin=s),i&&(this.adapterData=i)}};F.Source=Zo;var Qo=class{constructor(e,t,o=!1){this.name=e,this.variablesReference=t,this.expensive=o}};F.Scope=Qo;var es=class{constructor(e,t,o,s=0,i=0){this.id=e,this.source=o,this.line=s,this.column=i,this.name=t}};F.StackFrame=es;var ts=class{constructor(e,t){this.id=e,t?this.name=t:this.name="Thread #"+e}};F.Thread=ts;var ns=class{constructor(e,t,o=0,s,i){this.name=e,this.value=t,this.variablesReference=o,typeof i=="number"&&(this.namedVariables=i),typeof s=="number"&&(this.indexedVariables=s)}};F.Variable=ns;var os=class{constructor(e,t,o,s){this.verified=e;let i=this;typeof t=="number"&&(i.line=t),typeof o=="number"&&(i.column=o),s&&(i.source=s)}setId(e){this.id=e}};F.Breakpoint=os;var ss=class{constructor(e,t){this.id=e,this.name=t}};F.Module=ss;var is=class{constructor(e,t,o=0){this.label=e,this.start=t,this.length=o}};F.CompletionItem=is;var as=class extends fe.Event{constructor(e,t,o){super("stopped"),this.body={reason:e},typeof t=="number"&&(this.body.threadId=t),typeof o=="string"&&(this.body.text=o)}};F.StoppedEvent=as;var rs=class extends fe.Event{constructor(e,t){super("continued"),this.body={threadId:e},typeof t=="boolean"&&(this.body.allThreadsContinued=t)}};F.ContinuedEvent=rs;var ls=class extends fe.Event{constructor(){super("initialized")}};F.InitializedEvent=ls;var cs=class extends fe.Event{constructor(e){if(super("terminated"),typeof e=="boolean"||e){let t=this;t.body={restart:e}}}};F.TerminatedEvent=cs;var ds=class extends fe.Event{constructor(e){super("exited"),this.body={exitCode:e}}};F.ExitedEvent=ds;var us=class extends fe.Event{constructor(e,t="console",o){super("output"),this.body={category:t,output:e},o!==void 0&&(this.body.data=o)}};F.OutputEvent=us;var ps=class extends fe.Event{constructor(e,t){super("thread"),this.body={reason:e,threadId:t}}};F.ThreadEvent=ps;var ms=class extends fe.Event{constructor(e,t){super("breakpoint"),this.body={reason:e,breakpoint:t}}};F.BreakpointEvent=ms;var fs=class extends fe.Event{constructor(e,t){super("module"),this.body={reason:e,module:t}}};F.ModuleEvent=fs;var gs=class extends fe.Event{constructor(e,t){super("loadedSource"),this.body={reason:e,source:t}}};F.LoadedSourceEvent=gs;var hs=class extends fe.Event{constructor(e){super("capabilities"),this.body={capabilities:e}}};F.CapabilitiesEvent=hs;var vs=class extends fe.Event{constructor(e,t,o){super("progressStart"),this.body={progressId:e,title:t},typeof o=="string"&&(this.body.message=o)}};F.ProgressStartEvent=vs;var ys=class extends fe.Event{constructor(e,t){super("progressUpdate"),this.body={progressId:e},typeof t=="string"&&(this.body.message=t)}};F.ProgressUpdateEvent=ys;var bs=class extends fe.Event{constructor(e,t){super("progressEnd"),this.body={progressId:e},typeof t=="string"&&(this.body.message=t)}};F.ProgressEndEvent=bs;var xs=class extends fe.Event{constructor(e,t,o){super("invalidated"),this.body={},e&&(this.body.areas=e),t&&(this.body.threadId=t),o&&(this.body.stackFrameId=o)}};F.InvalidatedEvent=xs;var ws=class extends fe.Event{constructor(e,t,o){super("memory"),this.body={memoryReference:e,offset:t,count:o}}};F.MemoryEvent=ws;var mt;(function(n){n[n.User=1]="User",n[n.Telemetry=2]="Telemetry"})(mt=F.ErrorDestination||(F.ErrorDestination={}));var oo=class n extends Zd.ProtocolServer{constructor(e,t){super();let o=typeof e=="boolean"?e:!1;this._debuggerLinesStartAt1=o,this._debuggerColumnsStartAt1=o,this._debuggerPathsAreURIs=!1,this._clientLinesStartAt1=!0,this._clientColumnsStartAt1=!0,this._clientPathsAreURIs=!1,this._isServer=typeof t=="boolean"?t:!1,this.on("close",()=>{this.shutdown()}),this.on("error",s=>{this.shutdown()})}setDebuggerPathFormat(e){this._debuggerPathsAreURIs=e!=="path"}setDebuggerLinesStartAt1(e){this._debuggerLinesStartAt1=e}setDebuggerColumnsStartAt1(e){this._debuggerColumnsStartAt1=e}setRunAsServer(e){this._isServer=e}static run(e){(0,Qd.runDebugAdapter)(e)}shutdown(){this._isServer||this._isRunningInline()||setTimeout(()=>{process.exit(0)},100)}sendErrorResponse(e,t,o,s,i=mt.User){let a;typeof t=="number"?(a={id:t,format:o},s&&(a.variables=s),i&mt.User&&(a.showUser=!0),i&mt.Telemetry&&(a.sendTelemetry=!0)):a=t,e.success=!1,e.message=n.formatPII(a.format,!0,a.variables),e.body||(e.body={}),e.body.error=a,this.sendResponse(e)}runInTerminalRequest(e,t,o){this.sendRequest("runInTerminal",e,t,o)}dispatchRequest(e){let t=new fe.Response(e);try{if(e.command==="initialize"){var o=e.arguments;if(typeof o.linesStartAt1=="boolean"&&(this._clientLinesStartAt1=o.linesStartAt1),typeof o.columnsStartAt1=="boolean"&&(this._clientColumnsStartAt1=o.columnsStartAt1),o.pathFormat!=="path")this.sendErrorResponse(t,2018,"debug adapter only supports native paths",null,mt.Telemetry);else{let s=t;s.body={},this.initializeRequest(s,o)}}else e.command==="launch"?this.launchRequest(t,e.arguments,e):e.command==="attach"?this.attachRequest(t,e.arguments,e):e.command==="disconnect"?this.disconnectRequest(t,e.arguments,e):e.command==="terminate"?this.terminateRequest(t,e.arguments,e):e.command==="restart"?this.restartRequest(t,e.arguments,e):e.command==="setBreakpoints"?this.setBreakPointsRequest(t,e.arguments,e):e.command==="setFunctionBreakpoints"?this.setFunctionBreakPointsRequest(t,e.arguments,e):e.command==="setExceptionBreakpoints"?this.setExceptionBreakPointsRequest(t,e.arguments,e):e.command==="configurationDone"?this.configurationDoneRequest(t,e.arguments,e):e.command==="continue"?this.continueRequest(t,e.arguments,e):e.command==="next"?this.nextRequest(t,e.arguments,e):e.command==="stepIn"?this.stepInRequest(t,e.arguments,e):e.command==="stepOut"?this.stepOutRequest(t,e.arguments,e):e.command==="stepBack"?this.stepBackRequest(t,e.arguments,e):e.command==="reverseContinue"?this.reverseContinueRequest(t,e.arguments,e):e.command==="restartFrame"?this.restartFrameRequest(t,e.arguments,e):e.command==="goto"?this.gotoRequest(t,e.arguments,e):e.command==="pause"?this.pauseRequest(t,e.arguments,e):e.command==="stackTrace"?this.stackTraceRequest(t,e.arguments,e):e.command==="scopes"?this.scopesRequest(t,e.arguments,e):e.command==="variables"?this.variablesRequest(t,e.arguments,e):e.command==="setVariable"?this.setVariableRequest(t,e.arguments,e):e.command==="setExpression"?this.setExpressionRequest(t,e.arguments,e):e.command==="source"?this.sourceRequest(t,e.arguments,e):e.command==="threads"?this.threadsRequest(t,e):e.command==="terminateThreads"?this.terminateThreadsRequest(t,e.arguments,e):e.command==="evaluate"?this.evaluateRequest(t,e.arguments,e):e.command==="stepInTargets"?this.stepInTargetsRequest(t,e.arguments,e):e.command==="gotoTargets"?this.gotoTargetsRequest(t,e.arguments,e):e.command==="completions"?this.completionsRequest(t,e.arguments,e):e.command==="exceptionInfo"?this.exceptionInfoRequest(t,e.arguments,e):e.command==="loadedSources"?this.loadedSourcesRequest(t,e.arguments,e):e.command==="dataBreakpointInfo"?this.dataBreakpointInfoRequest(t,e.arguments,e):e.command==="setDataBreakpoints"?this.setDataBreakpointsRequest(t,e.arguments,e):e.command==="readMemory"?this.readMemoryRequest(t,e.arguments,e):e.command==="writeMemory"?this.writeMemoryRequest(t,e.arguments,e):e.command==="disassemble"?this.disassembleRequest(t,e.arguments,e):e.command==="cancel"?this.cancelRequest(t,e.arguments,e):e.command==="breakpointLocations"?this.breakpointLocationsRequest(t,e.arguments,e):e.command==="setInstructionBreakpoints"?this.setInstructionBreakpointsRequest(t,e.arguments,e):this.customRequest(e.command,t,e.arguments,e)}catch(s){this.sendErrorResponse(t,1104,"{_stack}",{_exception:s.message,_stack:s.stack},mt.Telemetry)}}initializeRequest(e,t){e.body.supportsConditionalBreakpoints=!1,e.body.supportsHitConditionalBreakpoints=!1,e.body.supportsFunctionBreakpoints=!1,e.body.supportsConfigurationDoneRequest=!0,e.body.supportsEvaluateForHovers=!1,e.body.supportsStepBack=!1,e.body.supportsSetVariable=!1,e.body.supportsRestartFrame=!1,e.body.supportsStepInTargetsRequest=!1,e.body.supportsGotoTargetsRequest=!1,e.body.supportsCompletionsRequest=!1,e.body.supportsRestartRequest=!1,e.body.supportsExceptionOptions=!1,e.body.supportsValueFormattingOptions=!1,e.body.supportsExceptionInfoRequest=!1,e.body.supportTerminateDebuggee=!1,e.body.supportsDelayedStackTraceLoading=!1,e.body.supportsLoadedSourcesRequest=!1,e.body.supportsLogPoints=!1,e.body.supportsTerminateThreadsRequest=!1,e.body.supportsSetExpression=!1,e.body.supportsTerminateRequest=!1,e.body.supportsDataBreakpoints=!1,e.body.supportsReadMemoryRequest=!1,e.body.supportsDisassembleRequest=!1,e.body.supportsCancelRequest=!1,e.body.supportsBreakpointLocationsRequest=!1,e.body.supportsClipboardContext=!1,e.body.supportsSteppingGranularity=!1,e.body.supportsInstructionBreakpoints=!1,e.body.supportsExceptionFilterOptions=!1,this.sendResponse(e)}disconnectRequest(e,t,o){this.sendResponse(e),this.shutdown()}launchRequest(e,t,o){this.sendResponse(e)}attachRequest(e,t,o){this.sendResponse(e)}terminateRequest(e,t,o){this.sendResponse(e)}restartRequest(e,t,o){this.sendResponse(e)}setBreakPointsRequest(e,t,o){this.sendResponse(e)}setFunctionBreakPointsRequest(e,t,o){this.sendResponse(e)}setExceptionBreakPointsRequest(e,t,o){this.sendResponse(e)}configurationDoneRequest(e,t,o){this.sendResponse(e)}continueRequest(e,t,o){this.sendResponse(e)}nextRequest(e,t,o){this.sendResponse(e)}stepInRequest(e,t,o){this.sendResponse(e)}stepOutRequest(e,t,o){this.sendResponse(e)}stepBackRequest(e,t,o){this.sendResponse(e)}reverseContinueRequest(e,t,o){this.sendResponse(e)}restartFrameRequest(e,t,o){this.sendResponse(e)}gotoRequest(e,t,o){this.sendResponse(e)}pauseRequest(e,t,o){this.sendResponse(e)}sourceRequest(e,t,o){this.sendResponse(e)}threadsRequest(e,t){this.sendResponse(e)}terminateThreadsRequest(e,t,o){this.sendResponse(e)}stackTraceRequest(e,t,o){this.sendResponse(e)}scopesRequest(e,t,o){this.sendResponse(e)}variablesRequest(e,t,o){this.sendResponse(e)}setVariableRequest(e,t,o){this.sendResponse(e)}setExpressionRequest(e,t,o){this.sendResponse(e)}evaluateRequest(e,t,o){this.sendResponse(e)}stepInTargetsRequest(e,t,o){this.sendResponse(e)}gotoTargetsRequest(e,t,o){this.sendResponse(e)}completionsRequest(e,t,o){this.sendResponse(e)}exceptionInfoRequest(e,t,o){this.sendResponse(e)}loadedSourcesRequest(e,t,o){this.sendResponse(e)}dataBreakpointInfoRequest(e,t,o){this.sendResponse(e)}setDataBreakpointsRequest(e,t,o){this.sendResponse(e)}readMemoryRequest(e,t,o){this.sendResponse(e)}writeMemoryRequest(e,t,o){this.sendResponse(e)}disassembleRequest(e,t,o){this.sendResponse(e)}cancelRequest(e,t,o){this.sendResponse(e)}breakpointLocationsRequest(e,t,o){this.sendResponse(e)}setInstructionBreakpointsRequest(e,t,o){this.sendResponse(e)}customRequest(e,t,o,s){this.sendErrorResponse(t,1014,"unrecognized request",null,mt.Telemetry)}convertClientLineToDebugger(e){return this._debuggerLinesStartAt1?this._clientLinesStartAt1?e:e+1:this._clientLinesStartAt1?e-1:e}convertDebuggerLineToClient(e){return this._debuggerLinesStartAt1?this._clientLinesStartAt1?e:e-1:this._clientLinesStartAt1?e+1:e}convertClientColumnToDebugger(e){return this._debuggerColumnsStartAt1?this._clientColumnsStartAt1?e:e+1:this._clientColumnsStartAt1?e-1:e}convertDebuggerColumnToClient(e){return this._debuggerColumnsStartAt1?this._clientColumnsStartAt1?e:e-1:this._clientColumnsStartAt1?e+1:e}convertClientPathToDebugger(e){return this._clientPathsAreURIs!==this._debuggerPathsAreURIs?this._clientPathsAreURIs?n.uri2path(e):n.path2uri(e):e}convertDebuggerPathToClient(e){return this._debuggerPathsAreURIs!==this._clientPathsAreURIs?this._debuggerPathsAreURIs?n.uri2path(e):n.path2uri(e):e}static path2uri(e){process.platform==="win32"&&(/^[A-Z]:/.test(e)&&(e=e[0].toLowerCase()+e.substr(1)),e=e.replace(/\\/g,"/")),e=encodeURI(e);let t=new Ua.URL("file:");return t.pathname=e,t.toString()}static uri2path(e){let t=new Ua.URL(e),o=decodeURIComponent(t.pathname);return process.platform==="win32"&&(/^\/[a-zA-Z]:/.test(o)&&(o=o[1].toLowerCase()+o.substr(2)),o=o.replace(/\//g,"\\")),o}static formatPII(e,t,o){return e.replace(n._formatPIIRegexp,function(s,i){return t&&i.length>0&&i[0]!=="_"?s:o[i]&&o.hasOwnProperty(i)?o[i]:s})}};F.DebugSession=oo;oo._formatPIIRegexp=/{([^}]+)}/g});var Qa=je(ao=>{"use strict";Object.defineProperty(ao,"__esModule",{value:!0});ao.InternalLogger=void 0;var Ka=require("fs"),Ja=require("path"),Ce=ro(),ks=class{constructor(e,t){this.beforeExitCallback=()=>this.dispose(),this._logCallback=e,this._logToConsole=t,this._minLogLevel=Ce.LogLevel.Warn,this.disposeCallback=(o,s)=>{this.dispose(),s=s||2,s+=128,process.exit(s)}}async setup(e){if(this._minLogLevel=e.consoleMinLogLevel,this._prependTimestamp=e.prependTimestamp,e.logFilePath)if(!Ja.isAbsolute(e.logFilePath))this.log(`logFilePath must be an absolute path: ${e.logFilePath}`,Ce.LogLevel.Error);else{let t=o=>this.sendLog(`Error creating log file at path: ${e.logFilePath}. Error: ${o.toString()}
`,Ce.LogLevel.Error);try{await Ka.promises.mkdir(Ja.dirname(e.logFilePath),{recursive:!0}),this.log(`Verbose logs are written to:
`,Ce.LogLevel.Warn),this.log(e.logFilePath+`
`,Ce.LogLevel.Warn),this._logFileStream=Ka.createWriteStream(e.logFilePath),this.logDateTime(),this.setupShutdownListeners(),this._logFileStream.on("error",o=>{t(o)})}catch(o){t(o)}}}logDateTime(){let e=new Date,o=e.getUTCFullYear()+`-${e.getUTCMonth()+1}-`+e.getUTCDate()+", "+Za();this.log(o+`
`,Ce.LogLevel.Verbose,!1)}setupShutdownListeners(){process.on("beforeExit",this.beforeExitCallback),process.on("SIGTERM",this.disposeCallback),process.on("SIGINT",this.disposeCallback)}removeShutdownListeners(){process.removeListener("beforeExit",this.beforeExitCallback),process.removeListener("SIGTERM",this.disposeCallback),process.removeListener("SIGINT",this.disposeCallback)}dispose(){return new Promise(e=>{this.removeShutdownListeners(),this._logFileStream?(this._logFileStream.end(e),this._logFileStream=null):e()})}log(e,t,o=!0){if(this._minLogLevel!==Ce.LogLevel.Stop){if(t>=this._minLogLevel&&this.sendLog(e,t),this._logToConsole){let s=t===Ce.LogLevel.Error?console.error:t===Ce.LogLevel.Warn?console.warn:null;s&&s((0,Ce.trimLastNewline)(e))}t===Ce.LogLevel.Error&&(e=`[${Ce.LogLevel[t]}] ${e}`),this._prependTimestamp&&o&&(e="["+Za()+"] "+e),this._logFileStream&&this._logFileStream.write(e)}}sendLog(e,t){if(e.length>1500){let o=!!e.match(/(\n|\r\n)$/);e=e.substr(0,1500)+"[...]",o&&(e=e+`
`)}if(this._logCallback){let o=new Ce.LogOutputEvent(e,t);this._logCallback(o)}}};ao.InternalLogger=ks;function Za(){let n=new Date,e=io(2,String(n.getUTCHours())),t=io(2,String(n.getUTCMinutes())),o=io(2,String(n.getUTCSeconds())),s=io(3,String(n.getUTCMilliseconds()));return e+":"+t+":"+o+"."+s+" UTC"}function io(n,e){return e.length>=n?e:String("0".repeat(n)+e).slice(-n)}});var ro=je(Te=>{"use strict";Object.defineProperty(Te,"__esModule",{value:!0});Te.trimLastNewline=Te.LogOutputEvent=Te.logger=Te.Logger=Te.LogLevel=void 0;var eu=Qa(),tu=so(),nt;(function(n){n[n.Verbose=0]="Verbose",n[n.Log=1]="Log",n[n.Warn=2]="Warn",n[n.Error=3]="Error",n[n.Stop=4]="Stop"})(nt=Te.LogLevel||(Te.LogLevel={}));var lo=class{constructor(){this._pendingLogQ=[]}log(e,t=nt.Log){e=e+`
`,this._write(e,t)}verbose(e){this.log(e,nt.Verbose)}warn(e){this.log(e,nt.Warn)}error(e){this.log(e,nt.Error)}dispose(){if(this._currentLogger){let e=this._currentLogger.dispose();return this._currentLogger=null,e}else return Promise.resolve()}_write(e,t=nt.Log){e=e+"",this._pendingLogQ?this._pendingLogQ.push({msg:e,level:t}):this._currentLogger&&this._currentLogger.log(e,t)}setup(e,t,o=!0){let s=typeof t=="string"?t:t&&this._logFilePathFromInit;if(this._currentLogger){let i={consoleMinLogLevel:e,logFilePath:s,prependTimestamp:o};this._currentLogger.setup(i).then(()=>{if(this._pendingLogQ){let a=this._pendingLogQ;this._pendingLogQ=null,a.forEach(r=>this._write(r.msg,r.level))}})}}init(e,t,o){this._pendingLogQ=this._pendingLogQ||[],this._currentLogger=new eu.InternalLogger(e,o),this._logFilePathFromInit=t}};Te.Logger=lo;Te.logger=new lo;var Ss=class extends tu.OutputEvent{constructor(e,t){let o=t===nt.Error?"stderr":t===nt.Warn?"console":"stdout";super(e,o)}};Te.LogOutputEvent=Ss;function nu(n){return n.replace(/(\n|\r\n)$/,"")}Te.trimLastNewline=nu});var nr=je(co=>{"use strict";Object.defineProperty(co,"__esModule",{value:!0});co.LoggingDebugSession=void 0;var tr=ro(),St=tr.logger,er=so(),Es=class extends er.DebugSession{constructor(e,t,o){super(t,o),this.obsolete_logFilePath=e,this.on("error",s=>{St.error(s.body)})}start(e,t){super.start(e,t),St.init(o=>this.sendEvent(o),this.obsolete_logFilePath,this._isServer)}sendEvent(e){if(!(e instanceof tr.LogOutputEvent)){let t=e;e instanceof er.OutputEvent&&e.body&&e.body.data&&e.body.data.doNotLogOutput&&(delete e.body.data.doNotLogOutput,t={...e},t.body={...e.body,output:"<output not logged>"}),St.verbose(`To client: ${JSON.stringify(t)}`)}super.sendEvent(e)}sendRequest(e,t,o,s){St.verbose(`To client: ${JSON.stringify(e)}(${JSON.stringify(t)}), timeout: ${o}`),super.sendRequest(e,t,o,s)}sendResponse(e){St.verbose(`To client: ${JSON.stringify(e)}`),super.sendResponse(e)}dispatchRequest(e){St.verbose(`From client: ${e.command}(${JSON.stringify(e.arguments)})`),super.dispatchRequest(e)}};co.LoggingDebugSession=Es});var or=je(uo=>{"use strict";Object.defineProperty(uo,"__esModule",{value:!0});uo.Handles=void 0;var Cs=class{constructor(e){this.START_HANDLE=1e3,this._handleMap=new Map,this._nextHandle=typeof e=="number"?e:this.START_HANDLE}reset(){this._nextHandle=this.START_HANDLE,this._handleMap=new Map}create(e){var t=this._nextHandle++;return this._handleMap.set(t,e),t}get(e,t){return this._handleMap.get(e)||t}};uo.Handles=Cs});var ar=je(I=>{"use strict";Object.defineProperty(I,"__esModule",{value:!0});I.Handles=I.Response=I.Event=I.ErrorDestination=I.CompletionItem=I.Module=I.Source=I.Breakpoint=I.Variable=I.Scope=I.StackFrame=I.Thread=I.MemoryEvent=I.InvalidatedEvent=I.ProgressEndEvent=I.ProgressUpdateEvent=I.ProgressStartEvent=I.CapabilitiesEvent=I.LoadedSourceEvent=I.ModuleEvent=I.BreakpointEvent=I.ThreadEvent=I.OutputEvent=I.ContinuedEvent=I.StoppedEvent=I.ExitedEvent=I.TerminatedEvent=I.InitializedEvent=I.logger=I.Logger=I.LoggingDebugSession=I.DebugSession=void 0;var J=so();Object.defineProperty(I,"DebugSession",{enumerable:!0,get:function(){return J.DebugSession}});Object.defineProperty(I,"InitializedEvent",{enumerable:!0,get:function(){return J.InitializedEvent}});Object.defineProperty(I,"TerminatedEvent",{enumerable:!0,get:function(){return J.TerminatedEvent}});Object.defineProperty(I,"ExitedEvent",{enumerable:!0,get:function(){return J.ExitedEvent}});Object.defineProperty(I,"StoppedEvent",{enumerable:!0,get:function(){return J.StoppedEvent}});Object.defineProperty(I,"ContinuedEvent",{enumerable:!0,get:function(){return J.ContinuedEvent}});Object.defineProperty(I,"OutputEvent",{enumerable:!0,get:function(){return J.OutputEvent}});Object.defineProperty(I,"ThreadEvent",{enumerable:!0,get:function(){return J.ThreadEvent}});Object.defineProperty(I,"BreakpointEvent",{enumerable:!0,get:function(){return J.BreakpointEvent}});Object.defineProperty(I,"ModuleEvent",{enumerable:!0,get:function(){return J.ModuleEvent}});Object.defineProperty(I,"LoadedSourceEvent",{enumerable:!0,get:function(){return J.LoadedSourceEvent}});Object.defineProperty(I,"CapabilitiesEvent",{enumerable:!0,get:function(){return J.CapabilitiesEvent}});Object.defineProperty(I,"ProgressStartEvent",{enumerable:!0,get:function(){return J.ProgressStartEvent}});Object.defineProperty(I,"ProgressUpdateEvent",{enumerable:!0,get:function(){return J.ProgressUpdateEvent}});Object.defineProperty(I,"ProgressEndEvent",{enumerable:!0,get:function(){return J.ProgressEndEvent}});Object.defineProperty(I,"InvalidatedEvent",{enumerable:!0,get:function(){return J.InvalidatedEvent}});Object.defineProperty(I,"MemoryEvent",{enumerable:!0,get:function(){return J.MemoryEvent}});Object.defineProperty(I,"Thread",{enumerable:!0,get:function(){return J.Thread}});Object.defineProperty(I,"StackFrame",{enumerable:!0,get:function(){return J.StackFrame}});Object.defineProperty(I,"Scope",{enumerable:!0,get:function(){return J.Scope}});Object.defineProperty(I,"Variable",{enumerable:!0,get:function(){return J.Variable}});Object.defineProperty(I,"Breakpoint",{enumerable:!0,get:function(){return J.Breakpoint}});Object.defineProperty(I,"Source",{enumerable:!0,get:function(){return J.Source}});Object.defineProperty(I,"Module",{enumerable:!0,get:function(){return J.Module}});Object.defineProperty(I,"CompletionItem",{enumerable:!0,get:function(){return J.CompletionItem}});Object.defineProperty(I,"ErrorDestination",{enumerable:!0,get:function(){return J.ErrorDestination}});var ou=nr();Object.defineProperty(I,"LoggingDebugSession",{enumerable:!0,get:function(){return ou.LoggingDebugSession}});var sr=ro();I.Logger=sr;var ir=Qn();Object.defineProperty(I,"Event",{enumerable:!0,get:function(){return ir.Event}});Object.defineProperty(I,"Response",{enumerable:!0,get:function(){return ir.Response}});var su=or();Object.defineProperty(I,"Handles",{enumerable:!0,get:function(){return su.Handles}});var iu=sr.logger;I.logger=iu});var cu={};Gt(cu,{activate:()=>au,deactivate:()=>ru});module.exports=Vt(cu);var T=E(require("vscode")),fr=E(require("path"));var Ns=E(require("readline"));function zs(n){return{kill:()=>{}}}function Br(n){let e=zr(n),t=_r(n);Ns.createInterface({input:process.stdin,output:void 0,terminal:!1}).on("line",s=>{let i=s.trim();if(!i)return;let a;try{a=JSON.parse(i)}catch{Bs({jsonrpc:"2.0",id:0,error:{code:-32700,message:"Parse error"}});return}Nr(a,e,t).then(r=>{Bs(r)})})}function Bs(n){let e=JSON.stringify(n);process.stdout.write(e+`
`)}async function Nr(n,e,t){let{id:o,method:s,params:i}=n;switch(s){case"initialize":return{jsonrpc:"2.0",id:o,result:{protocolVersion:"2024-11-05",capabilities:{tools:{}},serverInfo:{name:"lurek2d-mcp",version:"0.1.0"}}};case"notifications/initialized":return{jsonrpc:"2.0",id:o,result:{}};case"tools/list":return{jsonrpc:"2.0",id:o,result:{tools:t}};case"tools/call":{let a=i?.name,r=i?.arguments??{},l=e.get(a);if(!l)return{jsonrpc:"2.0",id:o,error:{code:-32601,message:`Unknown tool: ${a}`}};try{let c=await l(r);return{jsonrpc:"2.0",id:o,result:{content:[{type:"text",text:c}]}}}catch(c){return{jsonrpc:"2.0",id:o,result:{content:[{type:"text",text:`Error: ${c instanceof Error?c.message:String(c)}`}],isError:!0}}}}default:return{jsonrpc:"2.0",id:o,error:{code:-32601,message:`Method not found: ${s}`}}}}function zr(n){let{handleRunExample:e,handleGetApiDoc:t,handleListExamples:o,handleRunLuaTest:s,handleCheckBuild:i,handleGetLogs:a}=(bo(),Vt(yo)),r=new Map;return r.set("lurek2d.runExample",e(n)),r.set("lurek2d.getApiDoc",t(n)),r.set("lurek2d.listExamples",o(n)),r.set("lurek2d.runLuaTest",s(n)),r.set("lurek2d.checkBuild",i(n)),r.set("lurek2d.getLogs",a(n)),r}function _r(n){let{getToolDefinitions:e}=(bo(),Vt(yo));return e()}if(require.main===module){let n=process.argv.slice(2),e=process.cwd(),t=n.indexOf("--workspace");t!==-1&&n[t+1]&&(e=n[t+1]),Br(e)}var ke=E(require("vscode")),Ct=E(require("path")),Ut=E(require("fs")),Kt=class{process=null;terminal=null;_onStatusChange=new ke.EventEmitter;onStatusChange=this._onStatusChange.event;async findLurekBinary(){let e=ke.workspace.getConfiguration("lurek").get("enginePath","");if(e&&Ut.existsSync(e))return e;let t=process.platform==="win32"?"lurek2d.exe":"lurek2d",o=(process.env.PATH??"").split(Ct.delimiter);for(let i of o){let a=Ct.join(i,t);if(Ut.existsSync(a))return a}let s=_s();if(s){let i=Ct.join(s,"Cargo.toml");if(Ut.existsSync(i))return"cargo run --"}throw new Error("Lurek2D binary not found. Install it or set lurek.lurekPath in settings.")}async run(e,t=[]){if(this.isRunning()){ke.window.showWarningMessage("Lurek2D is already running.");return}ke.workspace.getConfiguration("lurek").get("saveOnRun",!0)&&await ke.workspace.saveAll(!1);let s=await this.findLurekBinary(),i=s.startsWith("cargo run")?`${s} ${e} ${t.join(" ")}`.trim():`"${s}" ${e} ${t.join(" ")}`.trim();this.terminal=ke.window.createTerminal({name:"Lurek2D",cwd:_s()}),this.terminal.show(),this.terminal.sendText(i),this._onStatusChange.fire(!0),ke.commands.executeCommand("setContext","lurek.gameRunning",!0)}stop(){this.terminal&&(this.terminal.dispose(),this.terminal=null),this.process&&(this.process.kill(),this.process=null),this._onStatusChange.fire(!1),ke.commands.executeCommand("setContext","lurek.gameRunning",!1)}isRunning(){return this.terminal!==null}dispose(){this.stop(),this._onStatusChange.dispose()}};function _s(){return ke.workspace.workspaceFolders?.[0]?.uri.fsPath}var it=E(require("vscode")),Jt=class{item;constructor(){this.item=it.window.createStatusBarItem(it.StatusBarAlignment.Left,100),this.setStopped(),this.item.show()}setRunning(){this.item.text="$(play) Lurek2D: Running",this.item.tooltip="Lurek2D game is running \u2014 click to stop",this.item.command="lurek.stopGame",this.item.backgroundColor=new it.ThemeColor("statusBarItem.warningBackground")}setStopped(){this.item.text="$(rocket) Lurek2D",this.item.tooltip="Lurek2D Toolkit \u2014 click to run game",this.item.command="lurek.runGame",this.item.backgroundColor=void 0}setDebugConnected(){this.item.text="$(debug-alt) Lurek2D: Debug",this.item.tooltip="Lurek2D debug bridge connected",this.item.command="lurek.debug.status",this.item.backgroundColor=new it.ThemeColor("statusBarItem.prominentBackground")}dispose(){this.item.dispose()}};var $s=E(require("vscode")),ze=E(require("fs")),Tt=E(require("path")),$r={DrawMode:{values:["fill","line"],descriptions:new Map([["fill","Filled shape"],["line","Outlined shape"]])},BodyType:{values:["static","dynamic","kinematic"],descriptions:new Map([["static","Does not move"],["dynamic","Full physics simulation"],["kinematic","Moves via velocity only"]])},SourceType:{values:["static","stream"],descriptions:new Map([["static","Fully loaded into memory"],["stream","Streamed from disk"]])},BlendMode:{values:["alpha","add","subtract","multiply","premultiplied","replace","screen"],descriptions:new Map},FilterMode:{values:["nearest","linear"],descriptions:new Map([["nearest","Pixelated (sharp)"],["linear","Smooth (blurred)"]])},WrapMode:{values:["clamp","clampzero","repeat","mirroredrepeat"],descriptions:new Map},ShapeType:{values:["circle","rectangle","polygon","edge","chain"],descriptions:new Map},JointType:{values:["distance","revolute","prismatic","pulley","gear","weld","friction","motor"],descriptions:new Map},AlignMode:{values:["left","center","right","justify"],descriptions:new Map},ArcType:{values:["pie","open","closed"],descriptions:new Map},CompareMode:{values:["equal","notequal","less","lequal","gequal","greater","always","never"],descriptions:new Map},LineJoin:{values:["miter","bevel","none"],descriptions:new Map},LineCap:{values:["butt","round","square"],descriptions:new Map},EasingFunction:{values:["linear","quad","cubic","quart","quint","sine","expo","circ","back","bounce","elastic"],descriptions:new Map}},Or=[{name:"load",signature:"lurek.load()",description:"Called once after the script is loaded.",params:[]},{name:"update",signature:"lurek.update(dt)",description:"Called every frame; `dt` is elapsed seconds.",params:[{name:"dt",type:"number",description:"Delta time in seconds",optional:!1}]},{name:"draw",signature:"lurek.draw()",description:"Called every frame for rendering.",params:[]},{name:"keypressed",signature:"lurek.keypressed(key)",description:"Called when a keyboard key is pressed.",params:[{name:"key",type:"string",description:"Key name",optional:!1}]},{name:"keyreleased",signature:"lurek.keyreleased(key)",description:"Called when a keyboard key is released.",params:[{name:"key",type:"string",description:"Key name",optional:!1}]},{name:"textinput",signature:"lurek.textinput(text)",description:"Called on text input.",params:[{name:"text",type:"string",description:"Input character(s)",optional:!1}]},{name:"mousepressed",signature:"lurek.mousepressed(x, y, button)",description:"Called when a mouse button is pressed.",params:[{name:"x",type:"number",description:"Mouse X",optional:!1},{name:"y",type:"number",description:"Mouse Y",optional:!1},{name:"button",type:"number",description:"Button index",optional:!1}]},{name:"mousereleased",signature:"lurek.mousereleased(x, y, button)",description:"Called when a mouse button is released.",params:[{name:"x",type:"number",description:"Mouse X",optional:!1},{name:"y",type:"number",description:"Mouse Y",optional:!1},{name:"button",type:"number",description:"Button index",optional:!1}]},{name:"wheelmoved",signature:"lurek.wheelmoved(x, y)",description:"Called on mouse wheel movement.",params:[{name:"x",type:"number",description:"Horizontal scroll",optional:!1},{name:"y",type:"number",description:"Vertical scroll",optional:!1}]},{name:"gamepadpressed",signature:"lurek.gamepadpressed(id, button)",description:"Called on gamepad button press.",params:[{name:"id",type:"number",description:"Gamepad ID",optional:!1},{name:"button",type:"string",description:"Button name",optional:!1}]},{name:"gamepadreleased",signature:"lurek.gamepadreleased(id, button)",description:"Called on gamepad button release.",params:[{name:"id",type:"number",description:"Gamepad ID",optional:!1},{name:"button",type:"string",description:"Button name",optional:!1}]},{name:"gamepadaxis",signature:"lurek.gamepadaxis(id, axis, value)",description:"Called on gamepad axis change.",params:[{name:"id",type:"number",description:"Gamepad ID",optional:!1},{name:"axis",type:"string",description:"Axis name",optional:!1},{name:"value",type:"number",description:"Axis value",optional:!1}]},{name:"joystickadded",signature:"lurek.joystickadded(id)",description:"Called when a gamepad is connected.",params:[{name:"id",type:"number",description:"Gamepad ID",optional:!1}]},{name:"joystickremoved",signature:"lurek.joystickremoved(id)",description:"Called when a gamepad is disconnected.",params:[{name:"id",type:"number",description:"Gamepad ID",optional:!1}]},{name:"touchpressed",signature:"lurek.touchpressed(id, x, y, dx, dy, pressure)",description:"Called on touch start.",params:[{name:"id",type:"number",description:"Touch ID",optional:!1},{name:"x",type:"number",description:"X position",optional:!1},{name:"y",type:"number",description:"Y position",optional:!1},{name:"dx",type:"number",description:"X delta",optional:!1},{name:"dy",type:"number",description:"Y delta",optional:!1},{name:"pressure",type:"number",description:"Touch pressure",optional:!1}]},{name:"touchmoved",signature:"lurek.touchmoved(id, x, y, dx, dy, pressure)",description:"Called on touch move.",params:[{name:"id",type:"number",description:"Touch ID",optional:!1},{name:"x",type:"number",description:"X position",optional:!1},{name:"y",type:"number",description:"Y position",optional:!1},{name:"dx",type:"number",description:"X delta",optional:!1},{name:"dy",type:"number",description:"Y delta",optional:!1},{name:"pressure",type:"number",description:"Touch pressure",optional:!1}]},{name:"touchreleased",signature:"lurek.touchreleased(id, x, y, dx, dy, pressure)",description:"Called on touch end.",params:[{name:"id",type:"number",description:"Touch ID",optional:!1},{name:"x",type:"number",description:"X position",optional:!1},{name:"y",type:"number",description:"Y position",optional:!1},{name:"dx",type:"number",description:"X delta",optional:!1},{name:"dy",type:"number",description:"Y delta",optional:!1},{name:"pressure",type:"number",description:"Touch pressure",optional:!1}]},{name:"focus",signature:"lurek.focus(has_focus)",description:"Called when window gains or loses focus.",params:[{name:"has_focus",type:"boolean",description:"Whether window has focus",optional:!1}]},{name:"visible",signature:"lurek.visible(is_visible)",description:"Called when window visibility changes.",params:[{name:"is_visible",type:"boolean",description:"Whether window is visible",optional:!1}]},{name:"resize",signature:"lurek.resize(w, h)",description:"Called when the window is resized.",params:[{name:"w",type:"number",description:"New width",optional:!1},{name:"h",type:"number",description:"New height",optional:!1}]},{name:"quit",signature:"lurek.quit()",description:"Called when the window is closed.",params:[]}],Wr={string:{common:[{name:"byte",signature:"string.byte(s, i, j)",description:"Returns the internal numeric codes of the characters s[i], s[i+1], ..., s[j].",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"i",type:"number",description:"Start index",optional:!0,default:"1"},{name:"j",type:"number",description:"End index",optional:!0,default:"i"}],returns:"number..."},{name:"char",signature:"string.char(...)",description:"Returns a string with characters with the given internal numeric codes.",params:[{name:"...",type:"number",description:"Byte values",optional:!1}],returns:"string"},{name:"find",signature:"string.find(s, pattern, init, plain)",description:"Looks for the first match of pattern in the string.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"pattern",type:"string",description:"Search pattern",optional:!1},{name:"init",type:"number",description:"Start position",optional:!0,default:"1"},{name:"plain",type:"boolean",description:"Plain text search",optional:!0,default:"false"}],returns:"number, number, ...string"},{name:"format",signature:"string.format(formatstring, ...)",description:"Returns a formatted string following the description given in its arguments.",params:[{name:"formatstring",type:"string",description:"Format string",optional:!1},{name:"...",type:"any",description:"Format arguments",optional:!0}],returns:"string"},{name:"gmatch",signature:"string.gmatch(s, pattern)",description:"Returns an iterator function that returns the next captures from pattern over string s.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"pattern",type:"string",description:"Pattern",optional:!1}],returns:"function"},{name:"gsub",signature:"string.gsub(s, pattern, repl, n)",description:"Returns a copy of s in which all (or the first n) occurrences of the pattern are replaced.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"pattern",type:"string",description:"Pattern",optional:!1},{name:"repl",type:"string|table|function",description:"Replacement",optional:!1},{name:"n",type:"number",description:"Max replacements",optional:!0}],returns:"string, number"},{name:"len",signature:"string.len(s)",description:"Returns the length of the string.",params:[{name:"s",type:"string",description:"Input string",optional:!1}],returns:"number"},{name:"lower",signature:"string.lower(s)",description:"Returns a copy of this string with all uppercase letters changed to lowercase.",params:[{name:"s",type:"string",description:"Input string",optional:!1}],returns:"string"},{name:"match",signature:"string.match(s, pattern, init)",description:"Looks for the first match of pattern in the string.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"pattern",type:"string",description:"Pattern",optional:!1},{name:"init",type:"number",description:"Start position",optional:!0,default:"1"}],returns:"string..."},{name:"rep",signature:"string.rep(s, n, sep)",description:"Returns a string that is the concatenation of n copies of the string s.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"n",type:"number",description:"Repetitions",optional:!1},{name:"sep",type:"string",description:"Separator",optional:!0,default:'""'}],returns:"string"},{name:"reverse",signature:"string.reverse(s)",description:"Returns a string that is the string s reversed.",params:[{name:"s",type:"string",description:"Input string",optional:!1}],returns:"string"},{name:"sub",signature:"string.sub(s, i, j)",description:"Returns the substring from i to j.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"i",type:"number",description:"Start index",optional:!1},{name:"j",type:"number",description:"End index",optional:!0,default:"-1"}],returns:"string"},{name:"upper",signature:"string.upper(s)",description:"Returns a copy of this string with all lowercase letters changed to uppercase.",params:[{name:"s",type:"string",description:"Input string",optional:!1}],returns:"string"},{name:"dump",signature:"string.dump(function, strip)",description:"Returns a string containing a binary representation of the given function.",params:[{name:"function",type:"function",description:"Function to dump",optional:!1},{name:"strip",type:"boolean",description:"Strip debug info",optional:!0}],returns:"string"}]},table:{common:[{name:"concat",signature:"table.concat(list, sep, i, j)",description:"Concatenates elements of a table into a string.",params:[{name:"list",type:"table",description:"Input table",optional:!1},{name:"sep",type:"string",description:"Separator",optional:!0,default:'""'},{name:"i",type:"number",description:"Start index",optional:!0,default:"1"},{name:"j",type:"number",description:"End index",optional:!0,default:"#list"}],returns:"string"},{name:"insert",signature:"table.insert(list, pos, value)",description:"Inserts element value at position pos in list.",params:[{name:"list",type:"table",description:"Target table",optional:!1},{name:"pos",type:"number",description:"Position",optional:!0},{name:"value",type:"any",description:"Value to insert",optional:!1}],returns:"nil"},{name:"remove",signature:"table.remove(list, pos)",description:"Removes from list the element at position pos.",params:[{name:"list",type:"table",description:"Target table",optional:!1},{name:"pos",type:"number",description:"Position",optional:!0,default:"#list"}],returns:"any"},{name:"sort",signature:"table.sort(list, comp)",description:"Sorts list elements in-place using the given comparison function.",params:[{name:"list",type:"table",description:"Table to sort",optional:!1},{name:"comp",type:"function",description:"Comparison function",optional:!0}],returns:"nil"},{name:"unpack",signature:"table.unpack(list, i, j)",description:"Returns the elements from the given table.",params:[{name:"list",type:"table",description:"Input table",optional:!1},{name:"i",type:"number",description:"Start index",optional:!0,default:"1"},{name:"j",type:"number",description:"End index",optional:!0,default:"#list"}],returns:"any..."}],lua54Only:[{name:"move",signature:"table.move(a1, f, e, t, a2)",description:"Moves elements from table a1 into table a2.",params:[{name:"a1",type:"table",description:"Source table",optional:!1},{name:"f",type:"number",description:"From index",optional:!1},{name:"e",type:"number",description:"End index",optional:!1},{name:"t",type:"number",description:"Target start",optional:!1},{name:"a2",type:"table",description:"Dest table",optional:!0,default:"a1"}],returns:"table"},{name:"pack",signature:"table.pack(...)",description:"Returns a new table with all arguments stored into keys 1, 2, etc.",params:[{name:"...",type:"any",description:"Values to pack",optional:!1}],returns:"table"}],luajitOnly:[{name:"new",signature:"table.new(narray, nhash)",description:"Pre-allocates a table with the given number of array and hash slots.",params:[{name:"narray",type:"number",description:"Array slots",optional:!1},{name:"nhash",type:"number",description:"Hash slots",optional:!1}],returns:"table"},{name:"clear",signature:"table.clear(tab)",description:"Clears all keys and values from a table.",params:[{name:"tab",type:"table",description:"Table to clear",optional:!1}],returns:"nil"}]},math:{common:[{name:"abs",signature:"math.abs(x)",description:"Returns the absolute value of x.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"acos",signature:"math.acos(x)",description:"Returns the arc cosine of x (in radians).",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"asin",signature:"math.asin(x)",description:"Returns the arc sine of x (in radians).",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"atan",signature:"math.atan(y, x)",description:"Returns the arc tangent of y/x (in radians).",params:[{name:"y",type:"number",description:"Y value",optional:!1},{name:"x",type:"number",description:"X value",optional:!0,default:"1"}],returns:"number"},{name:"ceil",signature:"math.ceil(x)",description:"Returns the smallest integer larger than or equal to x.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"cos",signature:"math.cos(x)",description:"Returns the cosine of x (in radians).",params:[{name:"x",type:"number",description:"Angle in radians",optional:!1}],returns:"number"},{name:"deg",signature:"math.deg(x)",description:"Converts angle x from radians to degrees.",params:[{name:"x",type:"number",description:"Angle in radians",optional:!1}],returns:"number"},{name:"exp",signature:"math.exp(x)",description:"Returns the value e^x.",params:[{name:"x",type:"number",description:"Exponent",optional:!1}],returns:"number"},{name:"floor",signature:"math.floor(x)",description:"Returns the largest integer smaller than or equal to x.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"fmod",signature:"math.fmod(x, y)",description:"Returns the remainder of the division of x by y.",params:[{name:"x",type:"number",description:"Dividend",optional:!1},{name:"y",type:"number",description:"Divisor",optional:!1}],returns:"number"},{name:"huge",signature:"math.huge",description:"The value HUGE_VAL, representing positive infinity.",params:[],returns:"number"},{name:"log",signature:"math.log(x, base)",description:"Returns the logarithm of x in the given base.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"base",type:"number",description:"Log base",optional:!0,default:"e"}],returns:"number"},{name:"max",signature:"math.max(x, ...)",description:"Returns the maximum value among its arguments.",params:[{name:"x",type:"number",description:"First value",optional:!1},{name:"...",type:"number",description:"More values",optional:!0}],returns:"number"},{name:"min",signature:"math.min(x, ...)",description:"Returns the minimum value among its arguments.",params:[{name:"x",type:"number",description:"First value",optional:!1},{name:"...",type:"number",description:"More values",optional:!0}],returns:"number"},{name:"modf",signature:"math.modf(x)",description:"Returns the integral and fractional parts of x.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number, number"},{name:"pi",signature:"math.pi",description:"The value of pi.",params:[],returns:"number"},{name:"rad",signature:"math.rad(x)",description:"Converts angle x from degrees to radians.",params:[{name:"x",type:"number",description:"Angle in degrees",optional:!1}],returns:"number"},{name:"random",signature:"math.random(m, n)",description:"Returns a pseudo-random number.",params:[{name:"m",type:"number",description:"Lower bound",optional:!0},{name:"n",type:"number",description:"Upper bound",optional:!0}],returns:"number"},{name:"randomseed",signature:"math.randomseed(x)",description:"Sets x as the seed for the pseudo-random generator.",params:[{name:"x",type:"number",description:"Seed value",optional:!1}],returns:"nil"},{name:"sin",signature:"math.sin(x)",description:"Returns the sine of x (in radians).",params:[{name:"x",type:"number",description:"Angle in radians",optional:!1}],returns:"number"},{name:"sqrt",signature:"math.sqrt(x)",description:"Returns the square root of x.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"tan",signature:"math.tan(x)",description:"Returns the tangent of x (in radians).",params:[{name:"x",type:"number",description:"Angle in radians",optional:!1}],returns:"number"}],lua54Only:[{name:"maxinteger",signature:"math.maxinteger",description:"An integer with the maximum value for an integer.",params:[],returns:"integer"},{name:"mininteger",signature:"math.mininteger",description:"An integer with the minimum value for an integer.",params:[],returns:"integer"},{name:"tointeger",signature:"math.tointeger(x)",description:"If x is convertible to an integer, returns that integer.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"integer|nil"},{name:"type",signature:"math.type(x)",description:"Returns 'integer', 'float', or false.",params:[{name:"x",type:"any",description:"Value to check",optional:!1}],returns:"string|false"},{name:"ult",signature:"math.ult(m, n)",description:"Returns true if m < n when compared as unsigned integers.",params:[{name:"m",type:"integer",description:"First value",optional:!1},{name:"n",type:"integer",description:"Second value",optional:!1}],returns:"boolean"}]},os:{common:[{name:"clock",signature:"os.clock()",description:"Returns CPU time used by the program in seconds.",params:[],returns:"number"},{name:"date",signature:"os.date(format, time)",description:"Returns a string or table with date and time.",params:[{name:"format",type:"string",description:"Date format",optional:!0,default:'"%c"'},{name:"time",type:"number",description:"Time value",optional:!0}],returns:"string|table"},{name:"difftime",signature:"os.difftime(t2, t1)",description:"Returns the difference in seconds between two times.",params:[{name:"t2",type:"number",description:"End time",optional:!1},{name:"t1",type:"number",description:"Start time",optional:!1}],returns:"number"},{name:"time",signature:"os.time(table)",description:"Returns the current time or converts the given table to a timestamp.",params:[{name:"table",type:"table",description:"Date table",optional:!0}],returns:"number"}]},io:{common:[{name:"close",signature:"io.close(file)",description:"Closes file, or the default output file.",params:[{name:"file",type:"file",description:"File handle",optional:!0}],returns:"boolean"},{name:"lines",signature:"io.lines(filename, ...)",description:"Opens the given file and returns an iterator function.",params:[{name:"filename",type:"string",description:"File path",optional:!0},{name:"...",type:"string|number",description:"Read formats",optional:!0}],returns:"function"},{name:"open",signature:"io.open(filename, mode)",description:"Opens a file in the given mode.",params:[{name:"filename",type:"string",description:"File path",optional:!1},{name:"mode",type:"string",description:"Open mode",optional:!0,default:'"r"'}],returns:"file|nil, string"},{name:"read",signature:"io.read(...)",description:"Reads from the default input file.",params:[{name:"...",type:"string|number",description:"Read formats",optional:!0}],returns:"string|number|nil"},{name:"write",signature:"io.write(...)",description:"Writes to the default output file.",params:[{name:"...",type:"string|number",description:"Values to write",optional:!1}],returns:"file|nil, string"},{name:"type",signature:"io.type(obj)",description:"Checks whether obj is a valid file handle.",params:[{name:"obj",type:"any",description:"Value to check",optional:!1}],returns:"string|nil"}]},coroutine:{common:[{name:"create",signature:"coroutine.create(f)",description:"Creates a new coroutine with body f.",params:[{name:"f",type:"function",description:"Coroutine body",optional:!1}],returns:"thread"},{name:"resume",signature:"coroutine.resume(co, ...)",description:"Starts or continues the execution of coroutine co.",params:[{name:"co",type:"thread",description:"Coroutine",optional:!1},{name:"...",type:"any",description:"Arguments",optional:!0}],returns:"boolean, any..."},{name:"yield",signature:"coroutine.yield(...)",description:"Suspends the execution of the calling coroutine.",params:[{name:"...",type:"any",description:"Values to yield",optional:!0}],returns:"any..."},{name:"status",signature:"coroutine.status(co)",description:"Returns the status of coroutine co.",params:[{name:"co",type:"thread",description:"Coroutine",optional:!1}],returns:"string"},{name:"wrap",signature:"coroutine.wrap(f)",description:"Creates a coroutine and returns a resume function.",params:[{name:"f",type:"function",description:"Coroutine body",optional:!1}],returns:"function"},{name:"isyieldable",signature:"coroutine.isyieldable()",description:"Returns true if the running coroutine can yield.",params:[],returns:"boolean"},{name:"running",signature:"coroutine.running()",description:"Returns the running coroutine plus a boolean.",params:[],returns:"thread, boolean"}]},debug:{common:[{name:"getinfo",signature:"debug.getinfo(f, what)",description:"Returns a table with information about a function.",params:[{name:"f",type:"function|number",description:"Function or stack level",optional:!1},{name:"what",type:"string",description:"Info selector",optional:!0}],returns:"table"},{name:"getlocal",signature:"debug.getlocal(f, local)",description:"Returns name and value of local variable.",params:[{name:"f",type:"function|number",description:"Function or stack level",optional:!1},{name:"local",type:"number",description:"Local index",optional:!1}],returns:"string, any"},{name:"sethook",signature:"debug.sethook(hook, mask, count)",description:"Sets the given function as a hook.",params:[{name:"hook",type:"function",description:"Hook function",optional:!1},{name:"mask",type:"string",description:"Hook mask",optional:!1},{name:"count",type:"number",description:"Instruction count",optional:!0}],returns:"nil"},{name:"traceback",signature:"debug.traceback(message, level)",description:"Returns a string with a traceback of the call stack.",params:[{name:"message",type:"string",description:"Prefix message",optional:!0},{name:"level",type:"number",description:"Stack level",optional:!0,default:"1"}],returns:"string"}]},package:{common:[{name:"loaded",signature:"package.loaded",description:"A table of already-loaded modules.",params:[],returns:"table"},{name:"path",signature:"package.path",description:"The path used by require to search for a Lua loader.",params:[],returns:"string"},{name:"preload",signature:"package.preload",description:"A table to store loaders for specific modules.",params:[],returns:"table"},{name:"searchpath",signature:"package.searchpath(name, path, sep, rep)",description:"Searches for the given name in the given path.",params:[{name:"name",type:"string",description:"Module name",optional:!1},{name:"path",type:"string",description:"Search path",optional:!1},{name:"sep",type:"string",description:"Name separator",optional:!0,default:'"."'},{name:"rep",type:"string",description:"Replacement",optional:!0,default:'"/"'}],returns:"string|nil, string"}]},utf8:{common:[],lua54Only:[{name:"char",signature:"utf8.char(...)",description:"Returns a UTF-8 string from one or more codepoints.",params:[{name:"...",type:"number",description:"Codepoints",optional:!1}],returns:"string"},{name:"codepoint",signature:"utf8.codepoint(s, i, j)",description:"Returns the codepoints of all characters in s between positions i and j.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"i",type:"number",description:"Start",optional:!0,default:"1"},{name:"j",type:"number",description:"End",optional:!0,default:"i"}],returns:"number..."},{name:"codes",signature:"utf8.codes(s)",description:"Returns an iterator for all codepoints in string s.",params:[{name:"s",type:"string",description:"Input string",optional:!1}],returns:"function"},{name:"len",signature:"utf8.len(s, i, j)",description:"Returns the number of UTF-8 characters in string s.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"i",type:"number",description:"Start byte",optional:!0,default:"1"},{name:"j",type:"number",description:"End byte",optional:!0,default:"-1"}],returns:"number|nil, number"},{name:"offset",signature:"utf8.offset(s, n, i)",description:"Returns the byte position where the n-th character starts.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"n",type:"number",description:"Character offset",optional:!1},{name:"i",type:"number",description:"Start byte",optional:!0}],returns:"number"},{name:"charpattern",signature:"utf8.charpattern",description:"The pattern that matches exactly one UTF-8 byte sequence.",params:[],returns:"string"}]},bit:{common:[],luajitOnly:[{name:"tobit",signature:"bit.tobit(x)",description:"Normalizes a number to the numeric range of a 32-bit integer.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"tohex",signature:"bit.tohex(x, n)",description:"Converts x to a hex string with n digits.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"n",type:"number",description:"Number of digits",optional:!0}],returns:"string"},{name:"bnot",signature:"bit.bnot(x)",description:"Returns the bitwise NOT of x.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"band",signature:"bit.band(x1, ...)",description:"Returns the bitwise AND of all arguments.",params:[{name:"x1",type:"number",description:"First value",optional:!1},{name:"...",type:"number",description:"More values",optional:!0}],returns:"number"},{name:"bor",signature:"bit.bor(x1, ...)",description:"Returns the bitwise OR of all arguments.",params:[{name:"x1",type:"number",description:"First value",optional:!1},{name:"...",type:"number",description:"More values",optional:!0}],returns:"number"},{name:"bxor",signature:"bit.bxor(x1, ...)",description:"Returns the bitwise XOR of all arguments.",params:[{name:"x1",type:"number",description:"First value",optional:!1},{name:"...",type:"number",description:"More values",optional:!0}],returns:"number"},{name:"lshift",signature:"bit.lshift(x, n)",description:"Returns x logically shifted left by n bits.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"n",type:"number",description:"Shift amount",optional:!1}],returns:"number"},{name:"rshift",signature:"bit.rshift(x, n)",description:"Returns x logically shifted right by n bits.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"n",type:"number",description:"Shift amount",optional:!1}],returns:"number"},{name:"arshift",signature:"bit.arshift(x, n)",description:"Returns x arithmetically shifted right by n bits.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"n",type:"number",description:"Shift amount",optional:!1}],returns:"number"},{name:"rol",signature:"bit.rol(x, n)",description:"Returns x rotated left by n bits.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"n",type:"number",description:"Rotation amount",optional:!1}],returns:"number"},{name:"ror",signature:"bit.ror(x, n)",description:"Returns x rotated right by n bits.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"n",type:"number",description:"Rotation amount",optional:!1}],returns:"number"},{name:"bswap",signature:"bit.bswap(x)",description:"Swaps the bytes of x (byte-reverse).",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"}]},jit:{common:[],luajitOnly:[{name:"on",signature:"jit.on(func, recursive)",description:"Enables JIT compilation.",params:[{name:"func",type:"function",description:"Function or true for all",optional:!0},{name:"recursive",type:"boolean",description:"Include sub-functions",optional:!0}],returns:"nil"},{name:"off",signature:"jit.off(func, recursive)",description:"Disables JIT compilation.",params:[{name:"func",type:"function",description:"Function or true for all",optional:!0},{name:"recursive",type:"boolean",description:"Include sub-functions",optional:!0}],returns:"nil"},{name:"flush",signature:"jit.flush(func, recursive)",description:"Flushes the compiled code cache.",params:[{name:"func",type:"function",description:"Function to flush",optional:!0},{name:"recursive",type:"boolean",description:"Include sub-functions",optional:!0}],returns:"nil"},{name:"status",signature:"jit.status()",description:"Returns the current JIT status and architecture.",params:[],returns:"boolean, string..."},{name:"version",signature:"jit.version",description:"The LuaJIT version string.",params:[],returns:"string"},{name:"version_num",signature:"jit.version_num",description:"The LuaJIT version number.",params:[],returns:"number"},{name:"os",signature:"jit.os",description:"The target OS name.",params:[],returns:"string"},{name:"arch",signature:"jit.arch",description:"The target architecture name.",params:[],returns:"string"}]},ffi:{common:[],luajitOnly:[{name:"cdef",signature:"ffi.cdef(def)",description:"Adds C declarations.",params:[{name:"def",type:"string",description:"C declarations",optional:!1}],returns:"nil"},{name:"new",signature:"ffi.new(ctype, ...)",description:"Creates a C data object of the given type.",params:[{name:"ctype",type:"string|ctype",description:"C type",optional:!1},{name:"...",type:"any",description:"Initializers",optional:!0}],returns:"cdata"},{name:"cast",signature:"ffi.cast(ctype, init)",description:"Creates a scalar C data object with ctype and init.",params:[{name:"ctype",type:"string|ctype",description:"Target type",optional:!1},{name:"init",type:"any",description:"Initial value",optional:!1}],returns:"cdata"},{name:"typeof",signature:"ffi.typeof(ctype)",description:"Creates a C type object.",params:[{name:"ctype",type:"string",description:"C type declaration",optional:!1}],returns:"ctype"},{name:"sizeof",signature:"ffi.sizeof(ctype, nelem)",description:"Returns the size of a C type in bytes.",params:[{name:"ctype",type:"string|ctype|cdata",description:"C type",optional:!1},{name:"nelem",type:"number",description:"Number of elements",optional:!0}],returns:"number"},{name:"alignof",signature:"ffi.alignof(ctype)",description:"Returns the minimum required alignment of a C type.",params:[{name:"ctype",type:"string|ctype",description:"C type",optional:!1}],returns:"number"},{name:"istype",signature:"ffi.istype(ctype, obj)",description:"Returns true if obj has the given C type.",params:[{name:"ctype",type:"string|ctype",description:"C type",optional:!1},{name:"obj",type:"any",description:"Object to check",optional:!1}],returns:"boolean"},{name:"load",signature:"ffi.load(name, global)",description:"Loads a shared library.",params:[{name:"name",type:"string",description:"Library name",optional:!1},{name:"global",type:"boolean",description:"Export symbols globally",optional:!0}],returns:"clib"},{name:"string",signature:"ffi.string(ptr, len)",description:"Creates a Lua string from a C char pointer.",params:[{name:"ptr",type:"cdata",description:"Char pointer",optional:!1},{name:"len",type:"number",description:"Length",optional:!0}],returns:"string"},{name:"copy",signature:"ffi.copy(dst, src, len)",description:"Copies data between C objects.",params:[{name:"dst",type:"cdata",description:"Destination",optional:!1},{name:"src",type:"cdata|string",description:"Source",optional:!1},{name:"len",type:"number",description:"Byte count",optional:!0}],returns:"nil"},{name:"fill",signature:"ffi.fill(dst, len, c)",description:"Fills a memory region with a byte value.",params:[{name:"dst",type:"cdata",description:"Destination",optional:!1},{name:"len",type:"number",description:"Byte count",optional:!1},{name:"c",type:"number",description:"Fill byte",optional:!0,default:"0"}],returns:"nil"},{name:"gc",signature:"ffi.gc(cdata, finalizer)",description:"Associates a finalizer with a C data object.",params:[{name:"cdata",type:"cdata",description:"C data object",optional:!1},{name:"finalizer",type:"function",description:"Finalizer function",optional:!1}],returns:"cdata"}]}},Qt=class{modules=new Map;allFunctions=new Map;enums=new Map;methodsByObjectType=new Map;callbackList=[];loaded=!1;async load(e){if(this.loaded)return;let t=$s.workspace.workspaceFolders?.[0]?.uri.fsPath;if(t){let s=Tt.join(t,"docs","API","lurek.lua");if(ze.existsSync(s))try{let a=ze.readFileSync(s,"utf-8");this.loadFromLurekLua(a),this.initEnums(),this.initCallbacks(),this.loaded=!0;return}catch{}let i=Tt.join(t,"docs","API","api_data.json");if(ze.existsSync(i))try{let a=ze.readFileSync(i,"utf-8");this.loadFromJson(JSON.parse(a)),this.initEnums(),this.initCallbacks(),this.loaded=!0;return}catch{}}let o=Tt.join(e,"data","api-data.json");if(ze.existsSync(o))try{let s=ze.readFileSync(o,"utf-8");this.loadFromJson(JSON.parse(s)),this.initEnums(),this.initCallbacks(),this.loaded=!0;return}catch{}if(t){let s=Tt.join(t,"docs","API","lua-api.md");if(ze.existsSync(s))try{let i=ze.readFileSync(s,"utf-8");this.loadFromLuaApiMd(i),this.initEnums(),this.initCallbacks(),this.loaded=!0;return}catch{}}this.loadFallback(),this.initEnums(),this.initCallbacks(),this.loaded=!0}getModuleNames(){return Array.from(this.modules.keys())}getModule(e){return this.modules.get(e)}getFunctions(e){return this.modules.get(e)?.functions??[]}getFunction(e){return this.allFunctions.get(e)}getAllFunctions(){return Array.from(this.allFunctions.values())}searchFunctions(e){let t=e.toLowerCase(),o=[];for(let s of this.allFunctions.values())(s.fullPath.toLowerCase().includes(t)||s.name.toLowerCase().includes(t)||s.description.toLowerCase().includes(t))&&o.push(s);return o}getMethods(e){return this.methodsByObjectType.get(e)??[]}getMethod(e,t){return this.methodsByObjectType.get(e)?.find(s=>s.name===t)}getEnumValues(e){return this.enums.get(e)?.values??[]}getEnum(e){return this.enums.get(e)}getCallbacks(){return this.callbackList}getLuaStdlib(e){let t=[];for(let[o,s]of Object.entries(Wr)){for(let i of s.common)t.push(this.stdlibToApiFunction(o,i));if(e==="5.4"&&s.lua54Only)for(let i of s.lua54Only)t.push(this.stdlibToApiFunction(o,i));if(e==="luajit"&&s.luajitOnly)for(let i of s.luajitOnly)t.push(this.stdlibToApiFunction(o,i))}return t}getStats(){let e=0,t=0,o=0;for(let s of this.modules.values())e+=s.functions.length,t+=s.methods.length,o+=s.documentedEntries;return{modules:this.modules.size,functions:e,methods:t,documented:o}}loadFromJson(e){if(!e||typeof e!="object")return;let t=e;if(Array.isArray(t.modules))for(let o of t.modules){let s=String(o.name??""),i={name:s,fullPath:`lurek.${s}`,description:String(o.description??""),functions:[],methods:[],totalEntries:0,documentedEntries:0},a=Array.isArray(o.functions)?o.functions:[];for(let l of a){let c=this.rawToApiFunction(s,l);c.isMethod?(i.methods.push(c),this.indexMethod(c)):i.functions.push(c),this.allFunctions.set(c.fullPath,c)}let r=Array.isArray(o.methods)?o.methods:[];for(let l of r){let c=this.rawToApiFunction(s,l);c.isMethod=!0,i.methods.push(c),this.indexMethod(c),this.allFunctions.set(c.fullPath,c)}i.totalEntries=i.functions.length+i.methods.length,i.documentedEntries=[...i.functions,...i.methods].filter(l=>l.description.length>0).length,this.modules.set(s,i)}}rawToApiFunction(e,t){let o=String(t.name??""),s=String(t.fullPath??`lurek.${e}.${o}`),i=Array.isArray(t.parameters)?t.parameters.map(a=>({name:String(a.name??""),type:String(a.type??"any"),description:String(a.description??""),optional:!!a.optional,default:a.default!=null?String(a.default):void 0})):[];return{module:e,name:o,fullPath:s,signature:String(t.signature??`${s}(${i.map(a=>a.name).join(", ")})`),description:String(t.description??""),parameters:i,returns:t.returns!=null?String(t.returns):void 0,returnType:t.returnType!=null?String(t.returnType):void 0,since:t.since!=null?String(t.since):void 0,deprecated:t.deprecated!=null?String(t.deprecated):void 0,isMethod:!!t.isMethod,objectType:t.objectType!=null?String(t.objectType):void 0,sourceFile:t.sourceFile!=null?String(t.sourceFile):void 0}}loadFromMarkdown(e){let t=e.split(`
`),o=null,s=null,i=null,a=!1,r=!1,l=()=>{if(!s||!o||!s.name){s=null,a=!1;return}let c=(s.description??"").trim();c=c.replace(/\s*Lurek2D [\w]+ API function\.\s*/g," ").trim();let d={module:o.name,name:s.name,fullPath:s.fullPath??`lurek.${o.name}.${s.name}`,signature:s.signature??"",description:c,parameters:s.parameters??[],returns:s.returns,returnType:s.returnType??Zt(s.returns),since:s.since,deprecated:s.deprecated,isMethod:s.isMethod??!1,objectType:s.objectType,sourceFile:s.sourceFile};if(!d.signature){let u=d.parameters.map(v=>v.optional?`[${v.name}]`:v.name).join(", ");d.signature=d.isMethod?`${d.objectType??"obj"}:${d.name}(${u})`:`${d.fullPath}(${u})`}d.isMethod?(o.methods.push(d),this.indexMethod(d)):o.functions.push(d),this.allFunctions.set(d.fullPath,d),s=null,a=!1};for(let c=0;c<t.length;c++){let d=t[c],u=d.match(/^## (?:lurek\.)?(\w+)/);if(u&&!d.startsWith("## Contents")&&!d.startsWith("## Callbacks")){l(),o&&(o.totalEntries=o.functions.length+o.methods.length,o.documentedEntries=[...o.functions,...o.methods].filter(k=>k.description.length>0).length,this.modules.set(o.name,o));let g=u[1].toLowerCase().replace(/-/g,"_");o={name:g,fullPath:`lurek.${g}`,description:"",functions:[],methods:[],totalEntries:0,documentedEntries:0},i=null,r=!1;let f=c+1<t.length?t[c+1]:"";f&&!f.startsWith("#")&&!f.startsWith("*")&&f.trim().length>0&&(o.description=f.trim());let x=(t[c+1]??t[c+2]??"").match(/\*(\d+)\s+entries?\s*\|\s*(\d+)\s+documented\*/);x&&(o.totalEntries=parseInt(x[1],10),o.documentedEntries=parseInt(x[2],10));continue}let v=d.match(/^### (?:(\w+)\s+)?Methods$/);if(v&&o){l(),r=!0,i=v[1]??null;continue}if(d.match(/^### Functions$/)){l(),r=!1,i=null;continue}let m=d.match(/^#{3,4}\s+`?lurek\.(\w+)\.(\w+)(?:\(([^)]*)\))?`?/);if(m&&o){l();let[,,g,f]=m,b=f?f.split(",").map(x=>x.trim().replace(/[\[\]]/g,"")).filter(Boolean):[];s={name:g,fullPath:`lurek.${o.name}.${g}`,signature:`lurek.${o.name}.${g}(${f??""})`,description:"",parameters:b.map(x=>({name:x,type:"any",description:"",optional:x.startsWith("[")||f?.includes(`[${x}]`)||!1})),isMethod:!1};continue}let h=d.match(/^#{3,4}\s+`?(\w+):(\w+)(?:\(([^)]*)\))?`?\s*$/);if(h&&o){l();let[,g,f,b]=h,x=b?b.split(",").map(k=>k.trim().replace(/[\[\]]/g,"")).filter(Boolean):[];i=g,s={name:f,fullPath:`lurek.${o.name}.${g}:${f}`,signature:`${g}:${f}(${b??""})`,description:"",parameters:x.map(k=>({name:k,type:"any",description:"",optional:!1})),isMethod:!0,objectType:g};continue}if(!s)continue;if(/^\*\*Parameters:?\*\*/i.test(d)){if(d.match(/^\*\*Parameters:?\*\*\s+`([^`]+)`(?:,\s*`([^`]+)`)*$/)){let f=d.match(/`(\w+)`/g);if(f){let b=new Set((s.parameters??[]).map(x=>x.name));for(let x of f){let k=x.replace(/`/g,"");b.has(k)||(s.parameters=s.parameters??[],s.parameters.push({name:k,type:"any",description:"",optional:!1}))}}}else a=!0;continue}if(a&&d.match(/^- `[^`]+`/)){let g=d.match(/^- `([^`]+)`(?:,\s*`([^`]+)`)?\s*—\s*([^—]+?)\s*—\s*(.+)/);if(g){let[,x,k,L,_]=g;this.upsertParam(s,x,L.trim(),_.trim()),k&&this.upsertParam(s,k,L.trim(),_.trim());continue}let f=d.match(/^- `([^`]+)`(?:,\s*`([^`]+)`)?\s*—\s*(.*)/);if(f){let[,x,k,L]=f,_=L.match(/^`(\w+)`[:\s]\s*(.*)/);if(_)this.upsertParam(s,x,_[1],_[2].trim());else{let Q=Hr(L);this.upsertParam(s,x,Q,L.trim())}k&&this.upsertParam(s,k,"any","");continue}let b=d.match(/^- `(\w+)`\s*$/);if(b){this.upsertParam(s,b[1],"any","");continue}continue}a&&!d.startsWith("-")&&d.trim()!==""&&(a=!1);let y=d.match(/^\*\*Returns:?\*\*\s*(.*)/i);if(y){let g=y[1].trim();s.returns=g,s.returnType=Zt(g);continue}let p=d.match(/^\*Source:\s*\[([^\]]+)\]/);if(p){s.sourceFile=p[1];continue}if(!a&&d.trim().length>0&&!d.startsWith("#")&&!d.startsWith("*Source:")&&!d.startsWith("---")&&!d.startsWith("*")&&!d.match(/^Lua API:/)){let g=s.description??"";s.description=g?`${g} ${d.trim()}`:d.trim()}}l(),o&&(o.totalEntries=o.functions.length+o.methods.length,o.documentedEntries=[...o.functions,...o.methods].filter(c=>c.description.length>0).length,this.modules.set(o.name,o))}upsertParam(e,t,o,s){e.parameters=e.parameters??[];let i=e.parameters.find(a=>a.name===t);if(i)o!=="any"&&(i.type=o),s&&(i.description=s);else{let a=s.toLowerCase().startsWith("optional")||s.includes("(default")||t.startsWith("["),r=t.replace(/[\[\]]/g,""),l,c=s.match(/\(default[:\s]+([^)]+)\)/i);c&&(l=c[1].trim()),e.parameters.push({name:r,type:o,description:s,optional:a,default:l})}}indexMethod(e){let t=e.objectType;if(!t)return;let o=this.methodsByObjectType.get(t);o||(o=[],this.methodsByObjectType.set(t,o)),o.push(e)}initEnums(){for(let[e,t]of Object.entries($r))this.enums.set(e,{name:e,values:t.values,descriptions:t.descriptions})}initCallbacks(){this.callbackList=Or.map(e=>({module:"",name:e.name,fullPath:`lurek.${e.name}`,signature:e.signature,description:e.description,parameters:e.params,isMethod:!1}))}stdlibToApiFunction(e,t){return{module:e,name:t.name,fullPath:`${e}.${t.name}`,signature:t.signature,description:t.description,parameters:t.params,returns:t.returns,returnType:t.returns,isMethod:!1}}loadFromLurekLua(e){let t=e.split(`
`),o=null,s=[],i=[],a=[],r=()=>{o&&(o.totalEntries=o.functions.length+o.methods.length,o.documentedEntries=[...o.functions,...o.methods].filter(d=>d.description.length>0).length,this.modules.set(o.name,o))},l=()=>{s=[],i=[],a=[]},c=d=>(o&&o.name===d||(r(),o={name:d,fullPath:`lurek.${d}`,description:s.join(" ").trim(),functions:[],methods:[],totalEntries:0,documentedEntries:0},l()),o);for(let d of t){let u=d.trim();if(u.length===0)continue;let v=u.match(/^---(?!@)(.*)$/);if(v){let f=v[1].trim();f&&s.push(f);continue}let m=u.match(/^---@param\s+(\w+)\s+(\S+)(?:\s+(.*))?$/);if(m){let[,f,b,x]=m;i.push({name:f,type:b.replace(/\?$/,""),description:x?.trim()??"",optional:b.includes("?")||/optional/i.test(x??"")});continue}let h=u.match(/^---@return\s+(.+)$/);if(h){a.push(h[1].trim());continue}let y=u.match(/^---@class\s+lurek\.([A-Za-z0-9_]+)\s*$/);if(y){r(),o={name:y[1],fullPath:`lurek.${y[1]}`,description:s.join(" ").trim(),functions:[],methods:[],totalEntries:0,documentedEntries:0},l();continue}if(/^---@class\s+[A-Za-z_][A-Za-z0-9_]*(?:\s*:\s*[A-Za-z_][A-Za-z0-9_]*)?\s*$/.test(u)){l();continue}let p=u.match(/^function\s+lurek\.([A-Za-z0-9_]+)\.([A-Za-z0-9_]+)\(([^)]*)\)\s*end$/);if(p){let[,f,b,x]=p,k=c(f),L=a.length>0?a.join(", "):void 0,_=this.mergeSignatureParams(x,i),Q={module:k.name,name:b,fullPath:`lurek.${k.name}.${b}`,signature:`lurek.${k.name}.${b}(${x.trim()})`,description:s.join(" ").trim(),parameters:_,returns:L,returnType:Zt(L),isMethod:!1};k.functions.push(Q),this.allFunctions.set(Q.fullPath,Q),l();continue}let g=u.match(/^function\s+([A-Za-z_][A-Za-z0-9_]*)[:.]([A-Za-z0-9_]+)\(([^)]*)\)\s*end$/);if(g&&o){let[,f,b,x]=g,k=a.length>0?a.join(", "):void 0,L=this.mergeSignatureParams(x,i),_={module:o.name,name:b,fullPath:`lurek.${o.name}.${f}:${b}`,signature:`${f}:${b}(${x.trim()})`,description:s.join(" ").trim(),parameters:L,returns:k,returnType:Zt(k),isMethod:!0,objectType:f};o.methods.push(_),this.indexMethod(_),this.allFunctions.set(_.fullPath,_),l();continue}l()}r()}loadFromLuaApiMd(e){let t=e.split(`
`),o=null,s=!1,i=()=>{o&&(o.totalEntries=o.functions.length+o.methods.length,o.documentedEntries=[...o.functions,...o.methods].filter(a=>a.description.length>0).length,this.modules.set(o.name,o))};for(let a of t){let r=a.match(/^## [`']?lurek\.([\w]+)[`']?/);if(r){i();let l=r[1];o={name:l,fullPath:`lurek.${l}`,description:"",functions:[],methods:[],totalEntries:0,documentedEntries:0},s=!1;continue}if(o&&a.startsWith(">")&&!o.description){let l=a.replace(/^>\s*`[^`]*`\s*—\s*/,"").trim();l&&(o.description=l);continue}if(a.startsWith("```")){s=!s;continue}if(!(!s||!o)&&!a.match(/^function lurek\.(\w+)\(\s*(.*?)\s*\)\s*--\s*(.*)/)){{let l=a.match(/^lurek\.(\w+)\.(\w+)\(\s*(.*?)\s*\)(?:\s*->\s*([^-]+?))?\s*--\s*(.*)/);if(l){let[,,c,d,u,v]=l,m=u?.trim()||void 0,h=this.parseParamStr(d),y={module:o.name,name:c,fullPath:`lurek.${o.name}.${c}`,signature:`lurek.${o.name}.${c}(${d})`,description:v.trim(),parameters:h,returns:m,returnType:m,isMethod:!1};o.functions.push(y),this.allFunctions.set(y.fullPath,y);continue}}{let l=a.match(/^([A-Z]\w*):([\w]+)\(\s*(.*?)\s*\)(?:\s*->\s*([^-]+?))?\s*--\s*(.*)/);if(l){let[,c,d,u,v,m]=l,h=v?.trim()||void 0,y=this.parseParamStr(u),p={module:o.name,name:d,fullPath:`lurek.${o.name}.${c}:${d}`,signature:`${c}:${d}(${u})`,description:m.trim(),parameters:y,returns:h,returnType:h,isMethod:!0,objectType:c};o.methods.push(p),this.indexMethod(p),this.allFunctions.set(p.fullPath,p);continue}}}}i()}parseParamStr(e){return e.trim()?e.split(",").map(t=>{t=t.trim();let o=t.endsWith("?")||t.includes("?"),s=t.indexOf(":");if(s>=0){let a=t.slice(0,s).trim().replace(/[?\[\]]/g,""),r=t.slice(s+1).trim().replace(/\?$/,"").trim();return{name:a||"_",type:r||"any",description:"",optional:o}}return{name:t.replace(/[?\[\]]/g,"").trim()||"_",type:"any",description:"",optional:o}}):[]}mergeSignatureParams(e,t){let o=t.map(a=>({...a})),s=new Set(o.map(a=>a.name)),i=e.split(",").map(a=>a.trim()).filter(Boolean);for(let a of i)s.has(a)||o.push({name:a,type:"any",description:"",optional:!1});return o}loadFallback(){let e=[["graphics","Drawing and rendering functions",[["draw","Draws a drawable object at the specified position",["drawable","x","y","r","sx","sy","ox","oy"]],["rectangle","Draws a rectangle",["mode","x","y","width","height"]],["circle","Draws a circle",["mode","x","y","radius"]],["line","Draws a line between points",["x1","y1","x2","y2"]],["setColor","Sets the active drawing color (0-1 range)",["r","g","b","a"]],["setBackgroundColor","Sets the background color",["r","g","b"]],["newImage","Loads an image from file",["path"]],["newCanvas","Creates an off-screen canvas",["width","height"]],["newFont","Loads a font from file",["path","size"]],["newShader","Creates a shader from source",["code"]],["print","Draws text at position",["text","x","y"]],["push","Pushes the current transform onto the stack",[]],["pop","Pops the current transform from the stack",[]],["translate","Translates the coordinate system",["dx","dy"]],["rotate","Rotates the coordinate system",["angle"]],["scale","Scales the coordinate system",["sx","sy"]],["clear","Clears the screen with current background color",["r","g","b"]],["getWidth","Returns the window width in pixels",[]],["getHeight","Returns the window height in pixels",[]],["arc","Draws an arc",["mode","x","y","radius","angle1","angle2"]],["polygon","Draws a polygon",["mode","...vertices"]],["ellipse","Draws an ellipse",["mode","x","y","rx","ry"]],["points","Draws points at positions",["...coords"]],["setLineWidth","Sets the line width",["width"]],["getLineWidth","Returns the current line width",[]],["setFont","Sets the active font",["font"]],["origin","Resets the transform to identity",[]]]],["audio","Audio playback and management",[["newSource","Creates a new audio source from file",["path","type"]],["play","Plays an audio source",["source"]],["stop","Stops an audio source",["source"]],["pause","Pauses an audio source",["source"]],["setVolume","Sets the master volume (0-1)",["volume"]],["getVolume","Returns the master volume",[]]]],["physics","2D physics simulation with rapier2d",[["newWorld","Creates a new physics world",["gx","gy"]],["newBody","Creates a new rigid body",["world","x","y","type"]],["newRectangleShape","Attaches a rectangle collider",["body","w","h"]],["newCircleShape","Attaches a circle collider",["body","radius"]],["newEdgeShape","Attaches an edge collider",["body","x1","y1","x2","y2"]],["newPolygonShape","Attaches a polygon collider",["body","...vertices"]]]],["input","Keyboard, mouse, and gamepad input",[["isDown","Checks if a keyboard key is currently pressed",["key"]],["isUp","Checks if a keyboard key is not pressed",["key"]],["getMousePosition","Returns mouse x, y coordinates",[]],["getMouseX","Returns the mouse X position",[]],["getMouseY","Returns the mouse Y position",[]],["isMouseDown","Checks if a mouse button is pressed",["button"]],["getGamepadAxis","Returns gamepad axis value",["id","axis"]],["isGamepadDown","Checks if gamepad button is pressed",["id","button"]]]],["timer","Timing and frame management",[["getTime","Returns total elapsed time in seconds",[]],["getDelta","Returns delta time for current frame",[]],["getFPS","Returns current frames per second",[]],["sleep","Pauses execution for duration",["seconds"]],["average","Returns average frame time",[]]]],["window","Window management and display",[["setTitle","Sets the window title",["title"]],["getTitle","Returns the window title",[]],["setMode","Sets the window dimensions",["width","height","flags"]],["getWidth","Returns the window width",[]],["getHeight","Returns the window height",[]],["setFullscreen","Toggles fullscreen mode",["fullscreen"]],["isFullscreen","Returns whether window is fullscreen",[]],["setIcon","Sets the window icon",["imagedata"]],["close","Closes the window",[]],["minimize","Minimizes the window",[]],["maximize","Maximizes the window",[]],["restore","Restores the window from minimize/maximize",[]]]],["math","Mathematical utility functions",[["random","Returns a random number",["min","max"]],["noise","Generates Perlin noise value",["x","y","z"]],["lerp","Linearly interpolates between two values",["a","b","t"]],["clamp","Clamps a value between min and max",["x","min","max"]],["distance","Returns distance between two points",["x1","y1","x2","y2"]],["angle","Returns angle between two points",["x1","y1","x2","y2"]],["normalize","Normalizes a vector",["x","y"]]]],["filesystem","Sandboxed file I/O",[["read","Reads a file as a string",["path"]],["write","Writes a string to a file",["path","data"]],["exists","Checks if a file exists",["path"]],["getDirectoryItems","Lists items in a directory",["path"]],["createDirectory","Creates a directory",["path"]],["remove","Removes a file",["path"]],["isFile","Checks if path is a file",["path"]],["isDirectory","Checks if path is a directory",["path"]]]],["system","System information and utilities",[["getOS","Returns the operating system name",[]],["getClipboardText","Returns clipboard text content",[]],["setClipboardText","Sets clipboard text content",["text"]],["quit","Quits the application",[]],["openURL","Opens a URL in the default browser",["url"]]]]];for(let[t,o,s]of e){let i={name:t,fullPath:`lurek.${t}`,description:o,functions:[],methods:[],totalEntries:0,documentedEntries:0};for(let[a,r,l]of s){let c={module:t,name:a,fullPath:`lurek.${t}.${a}`,signature:`lurek.${t}.${a}(${l.join(", ")})`,description:r,parameters:l.map(d=>({name:d,type:"any",description:"",optional:!1})),isMethod:!1};i.functions.push(c),this.allFunctions.set(c.fullPath,c)}i.totalEntries=i.functions.length,i.documentedEntries=i.functions.filter(a=>a.description.length>0).length,this.modules.set(t,i)}}};function Zt(n){if(!n)return;let e=n.toLowerCase();return e==="nil"||e==="none"?"nil":e.startsWith("number")||e.startsWith("`number`")?"number":e.startsWith("string")||e.startsWith("`string`")?"string":e.startsWith("boolean")||e.startsWith("`boolean`")?"boolean":e.startsWith("table")||e.startsWith("`table`")?"table":e.startsWith("integer")||e.startsWith("`integer`")?"number":e.startsWith("function")||e.startsWith("`function`")?"function":e.includes(",")?"multiple":n}function Hr(n){let e=n.toLowerCase();return e.includes("boolean")?"boolean":e.includes("string")||e.includes("name")?"string":e.includes("pixel")||e.includes("coordinate")||e.includes("number")||e.includes("angle")||e.includes("radius")||e.includes("width")||e.includes("height")||e.includes("scale")||e.includes("factor")||e.includes("offset")||e.includes("index")||e.includes("integer")?"number":e.includes("table")?"table":e.includes("function")||e.includes("callback")?"function":e.includes("draw mode")||e.includes("'fill'")||e.includes("'line'")?"DrawMode":e.includes("blend mode")?"BlendMode":"any"}var w=E(require("vscode")),Xe=E(require("fs")),at=E(require("path")),S=class extends w.TreeItem{constructor(t,o,s,i,a){super(t,o);this.label=t;this.collapsibleState=o;this.commandId=s;this.icon=i;this.statusDescription=a;s&&(this.command={command:s,title:t}),i&&(this.iconPath=new w.ThemeIcon(i)),a&&(this.description=a)}},en=class{_onDidChangeTreeData=new w.EventEmitter;onDidChangeTreeData=this._onDidChangeTreeData.event;refresh(){this._onDidChangeTreeData.fire(void 0)}getTreeItem(e){return e}getChildren(e){if(!e)return[new S("Project Health",w.TreeItemCollapsibleState.Expanded,void 0,"heart"),new S("Create",w.TreeItemCollapsibleState.Expanded,void 0,"new-folder"),new S("Package",w.TreeItemCollapsibleState.Collapsed,void 0,"package"),new S("Libraries",w.TreeItemCollapsibleState.Collapsed,void 0,"library")];switch(e.label){case"Project Health":return this.getProjectHealthItems();case"Create":return[new S("New Project from Template",w.TreeItemCollapsibleState.None,"lurek.scaffold.project","file-add"),new S("New File from Template",w.TreeItemCollapsibleState.None,"lurek.scaffold.file","new-file")];case"Package":return[new S("Package .zip",w.TreeItemCollapsibleState.None,"lurek.package.zip","file-zip"),new S("Package for Windows",w.TreeItemCollapsibleState.None,"lurek.package.windows","desktop-download"),new S("Package for Linux",w.TreeItemCollapsibleState.None,"lurek.package.linux","terminal-linux")];case"Libraries":return[new S("Browse Pattern Library",w.TreeItemCollapsibleState.None,"lurek.library.browse","search"),new S("Insert Code Snippet",w.TreeItemCollapsibleState.None,"lurek.library.insertSnippet","code"),new S("Save Selection as Pattern",w.TreeItemCollapsibleState.None,"lurek.library.newPattern","save")];default:return[]}}getProjectHealthItems(){let e=w.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!e)return[new S("No workspace open",w.TreeItemCollapsibleState.None,void 0,"warning")];let t=[],o=Xe.existsSync(at.join(e,"main.lua"));t.push(new S("main.lua",w.TreeItemCollapsibleState.None,o?void 0:"lurek.scaffold.file",o?"pass":"error",o?"found":"missing"));let s=Xe.existsSync(at.join(e,"conf.lua"));t.push(new S("conf.lua",w.TreeItemCollapsibleState.None,void 0,s?"pass":"warning",s?"found":"optional"));let i=0;try{let r=l=>{let c=Xe.readdirSync(l,{withFileTypes:!0});for(let d of c){if(d.name.startsWith(".")||d.name==="node_modules")continue;let u=at.join(l,d.name);d.isDirectory()?r(u):d.name.endsWith(".lua")&&i++}};r(e)}catch{}t.push(new S("Lua files",w.TreeItemCollapsibleState.None,void 0,"file-code",`${i}`));let a=Xe.existsSync(at.join(e,"tests"))||Xe.existsSync(at.join(e,"test"))||Xe.existsSync(at.join(e,"tests.lua"));return t.push(new S("Tests",w.TreeItemCollapsibleState.None,void 0,a?"pass":"warning",a?"detected":"none found")),t}},tn=class{_onDidChangeTreeData=new w.EventEmitter;onDidChangeTreeData=this._onDidChangeTreeData.event;_gameStatus="stopped";_lastTestResult;setGameStatus(e){this._gameStatus=e,this._onDidChangeTreeData.fire(void 0)}setTestResult(e){this._lastTestResult=e,this._onDidChangeTreeData.fire(void 0)}refresh(){this._onDidChangeTreeData.fire(void 0)}getTreeItem(e){return e}getChildren(e){if(!e)return[new S("Run",w.TreeItemCollapsibleState.Expanded,void 0,"play"),new S("Testing",w.TreeItemCollapsibleState.Collapsed,void 0,"beaker"),new S("Editors",w.TreeItemCollapsibleState.Collapsed,void 0,"window"),new S("Debug",w.TreeItemCollapsibleState.Collapsed,void 0,"bug"),new S("Reference",w.TreeItemCollapsibleState.Collapsed,void 0,"book"),new S("Assets",w.TreeItemCollapsibleState.Collapsed,void 0,"file-media"),new S("Dependencies",w.TreeItemCollapsibleState.Collapsed,void 0,"list-tree"),new S("Performance",w.TreeItemCollapsibleState.Collapsed,void 0,"dashboard")];switch(e.label){case"Run":return[new S("Game Status",w.TreeItemCollapsibleState.None,void 0,this._gameStatus==="running"?"debug-start":this._gameStatus==="crashed"?"error":"debug-stop",this._gameStatus),new S("Run Game",w.TreeItemCollapsibleState.None,"lurek.runGame","play"),new S("Stop Game",w.TreeItemCollapsibleState.None,"lurek.stopGame","debug-stop"),new S("Run with Arguments",w.TreeItemCollapsibleState.None,"lurek.runWithArgs","terminal"),new S("Run Example",w.TreeItemCollapsibleState.None,"lurek.runExample","file-code")];case"Testing":return[...this._lastTestResult?[new S("Last Result",w.TreeItemCollapsibleState.None,void 0,this._lastTestResult.includes("fail")?"error":"pass",this._lastTestResult)]:[],new S("Open Test Runner",w.TreeItemCollapsibleState.None,"lurek.editor.testRunner","beaker"),new S("Run All Tests",w.TreeItemCollapsibleState.None,"lurek.test.all","testing-run-all-icon"),new S("Run Lua Tests",w.TreeItemCollapsibleState.None,"lurek.test.lua.all","test-view-icon"),new S("Run Golden Tests",w.TreeItemCollapsibleState.None,"lurek.test.lua.golden","file-media"),new S("Generate Tests for File",w.TreeItemCollapsibleState.None,"lurek.test.generateForFile","wand")];case"Editors":return[new S("Tile Map Editor",w.TreeItemCollapsibleState.None,"lurek.editor.tileMap","symbol-misc"),new S("Tileset Editor",w.TreeItemCollapsibleState.None,"lurek.editor.tileset","layers"),new S("Tilemap Script Editor",w.TreeItemCollapsibleState.None,"lurek.editor.tilemapScript","code"),new S("World Map Editor",w.TreeItemCollapsibleState.None,"lurek.editor.worldMap","map"),new S("Procedural Map Generator",w.TreeItemCollapsibleState.None,"lurek.editor.procMap","globe"),new S("Pixel Art Editor",w.TreeItemCollapsibleState.None,"lurek.editor.pixelArt","paintcan"),new S("Sprite Animation Editor",w.TreeItemCollapsibleState.None,"lurek.editor.spriteAnim","play-circle"),new S("Shader Preview",w.TreeItemCollapsibleState.None,"lurek.editor.shaderPreview","wand"),new S("Color Palette",w.TreeItemCollapsibleState.None,"lurek.editor.colorPalette","symbol-color"),new S("Font Preview",w.TreeItemCollapsibleState.None,"lurek.editor.fontPreview","text-size"),new S("Scene Flow Editor",w.TreeItemCollapsibleState.None,"lurek.editor.sceneFlow","type-hierarchy"),new S("Entity Designer",w.TreeItemCollapsibleState.None,"lurek.editor.entity","symbol-class"),new S("Dialog Editor",w.TreeItemCollapsibleState.None,"lurek.editor.dialog","comment-discussion"),new S("Quest Tree Editor",w.TreeItemCollapsibleState.None,"lurek.editor.questTree","git-merge"),new S("GUI Widget Editor",w.TreeItemCollapsibleState.None,"lurek.editor.guiWidget","symbol-interface"),new S("Timeline / Cutscene",w.TreeItemCollapsibleState.None,"lurek.editor.timeline","history"),new S("Input Mapper",w.TreeItemCollapsibleState.None,"lurek.editor.inputMapper","keyboard"),new S("Localization Editor",w.TreeItemCollapsibleState.None,"lurek.editor.localization","book"),new S("Particle Designer",w.TreeItemCollapsibleState.None,"lurek.editor.particle","sparkle"),new S("Physics Materials",w.TreeItemCollapsibleState.None,"lurek.editor.physicsMaterials","settings-gear"),new S("AI Behavior Tree",w.TreeItemCollapsibleState.None,"lurek.editor.aiBehavior","hubot"),new S("Voxel Editor",w.TreeItemCollapsibleState.None,"lurek.editor.voxel","layers"),new S("Audio Mixer",w.TreeItemCollapsibleState.None,"lurek.editor.audioMixer","unmute"),new S("Sound DSP Panel",w.TreeItemCollapsibleState.None,"lurek.editor.soundDsp","radio-tower"),new S("PostFX & Overlay Designer",w.TreeItemCollapsibleState.None,"lurek.editor.postfxOverlay","color-mode"),new S("Database Browser",w.TreeItemCollapsibleState.None,"lurek.editor.database","database"),new S("Graph Editor",w.TreeItemCollapsibleState.None,"lurek.editor.graph","graph")];case"Debug":return[new S("Debug Run + Connect",w.TreeItemCollapsibleState.None,"lurek.debug.runAndConnect","debug-start"),new S("Connect",w.TreeItemCollapsibleState.None,"lurek.debug.connect","plug"),new S("Disconnect",w.TreeItemCollapsibleState.None,"lurek.debug.disconnect","debug-disconnect"),new S("Evaluate Lua",w.TreeItemCollapsibleState.None,"lurek.debug.evaluate","terminal"),new S("Watchers Panel",w.TreeItemCollapsibleState.None,"lurek.debug.openWatchers","eye"),new S("Variable Inspector",w.TreeItemCollapsibleState.None,"lurek.debug.openInspector","symbol-variable"),new S("Call Stack",w.TreeItemCollapsibleState.None,"lurek.debug.openCallStack","list-tree"),new S("Performance",w.TreeItemCollapsibleState.None,"lurek.debug.performance","dashboard"),new S("Screenshot",w.TreeItemCollapsibleState.None,"lurek.debug.screenshot","device-camera"),new S("Status",w.TreeItemCollapsibleState.None,"lurek.debug.status","info")];case"Reference":return[new S("Browse API",w.TreeItemCollapsibleState.None,"lurek.browseApi","search"),new S("Open API Docs",w.TreeItemCollapsibleState.None,"lurek.openApiDocs","book"),new S("Open Wiki",w.TreeItemCollapsibleState.None,"lurek.openWiki","globe"),new S("Dependency Graph",w.TreeItemCollapsibleState.None,"lurek.depGraph","graph"),new S("Dependency List",w.TreeItemCollapsibleState.None,"lurek.depList","list-tree"),new S("API Coverage",w.TreeItemCollapsibleState.None,"lurek.apiCoverage","graph-line")];case"Assets":return[new S("Refresh Assets",w.TreeItemCollapsibleState.None,"lurek.assets.refresh","refresh"),new S("Open Asset Explorer",w.TreeItemCollapsibleState.None,"lurek.assets.openPanel","file-media"),new S("Find Missing Assets",w.TreeItemCollapsibleState.None,"lurek.assets.findMissing","warning")];case"Dependencies":return[new S("Show Module Graph",w.TreeItemCollapsibleState.None,"lurek.deps.showGraph","type-hierarchy"),new S("Find Circular Deps",w.TreeItemCollapsibleState.None,"lurek.deps.findCircular","warning"),new S("Show Orphan Modules",w.TreeItemCollapsibleState.None,"lurek.deps.findOrphans","question")];case"Performance":return[new S("Open Performance Dashboard",w.TreeItemCollapsibleState.None,"lurek.perf.openDashboard","dashboard"),new S("System Monitor",w.TreeItemCollapsibleState.None,"lurek.system.openMonitor","pulse"),new S("API Usage Report",w.TreeItemCollapsibleState.None,"lurek.api.usageReport","graph"),new S("Open Hot Reload History",w.TreeItemCollapsibleState.None,"lurek.perf.openHotReload","history"),new S("Clear History",w.TreeItemCollapsibleState.None,"lurek.perf.clearHistory","clear-all")];default:return[]}}},nn=class{_onDidChangeTreeData=new w.EventEmitter;onDidChangeTreeData=this._onDidChangeTreeData.event;refresh(){this._onDidChangeTreeData.fire(void 0)}getTreeItem(e){return e}getChildren(e){if(!e)return[new S("CAG (AI Config)",w.TreeItemCollapsibleState.Expanded,void 0,"hubot"),new S("MCP Server",w.TreeItemCollapsibleState.Collapsed,void 0,"server"),new S("Game Jam",w.TreeItemCollapsibleState.Collapsed,void 0,"flame")];switch(e.label){case"CAG (AI Config)":return[new S("Install AI Config",w.TreeItemCollapsibleState.None,"lurek.cag.install","cloud-download"),new S("Select Agent",w.TreeItemCollapsibleState.None,"lurek.cag.selectAgent","person"),new S("Select Skill",w.TreeItemCollapsibleState.None,"lurek.cag.selectSkill","mortar-board"),new S("Select Prompt",w.TreeItemCollapsibleState.None,"lurek.cag.selectPrompt","comment"),new S("Update CAG Files",w.TreeItemCollapsibleState.None,"lurek.cag.update","sync")];case"MCP Server":return[new S("Install MCP Server",w.TreeItemCollapsibleState.None,"lurek.mcp.install","cloud-download"),new S("MCP Status",w.TreeItemCollapsibleState.None,"lurek.mcp.status","info")];case"Game Jam":return[new S("Game Jam Quick Start",w.TreeItemCollapsibleState.None,"lurek.gameJam.quickStart","rocket"),new S("Add Game Module",w.TreeItemCollapsibleState.None,"lurek.gameJam.addModule","add"),new S("Game Jam Timer",w.TreeItemCollapsibleState.None,"lurek.gameJam.timer","watch"),new S("Quick Build",w.TreeItemCollapsibleState.None,"lurek.jam.quickBuild","zap"),new S("Submission Checklist",w.TreeItemCollapsibleState.None,"lurek.jam.checklist","checklist")];default:return[]}}};var C=E(require("vscode"));var jr=new Set(["and","break","do","else","elseif","end","false","for","function","goto","if","in","local","nil","not","or","repeat","return","then","true","until","while"]),Os=new Set(["load","update","draw","keypressed","keyreleased","textinput","mousepressed","mousereleased","wheelmoved","gamepadpressed","gamepadreleased","gamepadaxis","joystickadded","joystickremoved","touchpressed","touchmoved","touchreleased","focus","visible","resize","quit"]),Ws=new Set(["+","-","*","/","%","^","#","==","~=","<",">","<=",">=","=","..","...","//"]),qr=new Set(["(",")","{","}","[","]",";",":",",","."]),G=class{tokenize(e){let t=[],o=e.length,s=0,i=0,a=0;for(;s<o;){let r=e[s];if(r===" "||r==="	"||r==="\r"||r===`
`){let l=s,c=i,d=a;for(;s<o&&(e[s]===" "||e[s]==="	"||e[s]==="\r"||e[s]===`
`);)e[s]===`
`?(i++,a=0):a++,s++;t.push({type:7,value:e.slice(l,s),line:c,column:d,length:s-l});continue}if(r==="-"&&s+1<o&&e[s+1]==="-"){let l=i,c=a;if(s+2<o&&e[s+2]==="["){let m=this.countLongBracketLevel(e,s+2);if(m>=0){let h="]"+"=".repeat(m)+"]",y=e.indexOf(h,s+4+m),p=y>=0?y+h.length:o,g=e.slice(s,p),f=xo(g);t.push({type:4,value:g,line:l,column:c,length:p-s});for(let b=s;b<p;b++)e[b]===`
`?(i++,a=0):a++;s=p;continue}}let d=e.indexOf(`
`,s),u=d>=0?d:o,v=e.slice(s,u);t.push({type:4,value:v,line:l,column:c,length:u-s}),a+=u-s,s=u;continue}if(r==="["){let l=this.countLongBracketLevel(e,s);if(l>=0){let c="]"+"=".repeat(l)+"]",d=s+2+l,u=e.indexOf(c,d),v=u>=0?u+c.length:o,m=e.slice(s,v),h=i,y=a;for(let p=s;p<v;p++)e[p]===`
`?(i++,a=0):a++;t.push({type:2,value:m,line:h,column:y,length:v-s}),s=v;continue}}if(r==='"'||r==="'"){let l=i,c=a,d=r,u=s+1;for(;u<o;){if(e[u]==="\\"){u+=2;continue}if(e[u]===d){u++;break}if(e[u]===`
`)break;u++}let v=e.slice(s,u);t.push({type:2,value:v,line:l,column:c,length:u-s}),a+=u-s,s=u;continue}if(rt(r)||r==="."&&s+1<o&&rt(e[s+1])){let l=i,c=a,d=s;if(r==="0"&&d+1<o&&(e[d+1]==="x"||e[d+1]==="X"))for(d+=2;d<o&&Yr(e[d]);)d++;else if(r==="0"&&d+1<o&&(e[d+1]==="b"||e[d+1]==="B"))for(d+=2;d<o&&(e[d]==="0"||e[d]==="1");)d++;else{for(;d<o&&rt(e[d]);)d++;if(d<o&&e[d]===".")for(d++;d<o&&rt(e[d]);)d++;if(d<o&&(e[d]==="e"||e[d]==="E"))for(d++,d<o&&(e[d]==="+"||e[d]==="-")&&d++;d<o&&rt(e[d]);)d++}let u=e.slice(s,d);t.push({type:3,value:u,line:l,column:c,length:d-s}),a+=d-s,s=d;continue}if(Hs(r)){let l=a,c=s+1;for(;c<o&&It(e[c]);)c++;let d=e.slice(s,c),u=jr.has(d)?0:1;t.push({type:u,value:d,line:i,column:l,length:c-s}),a+=c-s,s=c;continue}if(s+2<o){let l=e.slice(s,s+3);if(l==="..."){t.push({type:5,value:l,line:i,column:a,length:3}),a+=3,s+=3;continue}}if(s+1<o){let l=e.slice(s,s+2);if(Ws.has(l)){t.push({type:5,value:l,line:i,column:a,length:2}),a+=2,s+=2;continue}}if(Ws.has(r)){t.push({type:5,value:r,line:i,column:a,length:1}),a++,s++;continue}if(qr.has(r)){t.push({type:6,value:r,line:i,column:a,length:1}),a++,s++;continue}a++,s++}return t.push({type:8,value:"",line:i,column:a,length:0}),t}analyze(e){let t=this.tokenize(e),o=[],s=[],i=[],a=[],r=[];for(let p of t)if(p.type===4){let g=p.value.replace(/^--\[=*\[/,"").replace(/\]=*\]$/,"").replace(/^--/,"").trim();r.push({text:g,line:p.line,isBlock:p.value.startsWith("--["),isLuaCATS:p.value.startsWith("---@")})}let l=t.filter(p=>p.type!==7&&p.type!==4),c=[],d=0,u=(p=0)=>l[d+p],v=(p,g)=>{let f=u();return!(!f||f.type!==p||g!==void 0&&f.value!==g)},m=()=>l[d++],h=p=>{for(let g=r.length-1;g>=0;g--)if(r[g].line===p-1||r[g].line===p)return r[g].text};for(;d<l.length&&u()?.type!==8;){let p=u();if(v(0,"local")){let g=m();if(v(0,"function")){if(m(),u()?.type===1){let f=m(),b=this.parseParamList(l,d);d=b.nextIndex;let x=h(g.line),k={name:f.value,kind:"function",line:f.line,column:f.column,scope:c.length>0?c[c.length-1].name:void 0,parameters:b.names,isLocal:!0,description:x};o.push(k);for(let L of b.names)o.push({name:L,kind:"parameter",line:f.line,column:f.column,scope:f.value,isLocal:!0});c.push({name:f.value,startLine:f.line,kind:"function"})}continue}if(u()?.type===1){let f=m();if(v(5,"=")){if(m(),u()?.type===1&&u()?.value==="require"&&(m(),v(6,"(")&&(m(),u()?.type===2))){let x=m().value.slice(1,-1);s.push({modulePath:x,localName:f.value,line:f.line,column:f.column})}if(u()?.type===6&&u()?.value==="{"){o.push({name:f.value,kind:"table",line:f.line,column:f.column,scope:c.length>0?c[c.length-1].name:void 0,isLocal:!0,description:h(f.line)});continue}}for(o.push({name:f.value,kind:"local",line:f.line,column:f.column,scope:c.length>0?c[c.length-1].name:void 0,isLocal:!0,description:h(f.line)});v(6,",");)if(m(),u()?.type===1){let b=m();o.push({name:b.value,kind:"local",line:b.line,column:b.column,scope:c.length>0?c[c.length-1].name:void 0,isLocal:!0})}}continue}if(v(0,"function")){let g=m();if(u()?.type===1){let b=m().value,x=!1,k;for(;;)if(v(6,"."))m(),u()?.type===1&&(b+="."+m().value);else if(v(6,":")){if(m(),x=!0,k=b,u()?.type===1){let gt=m();b+=":"+gt.value}}else break;let L=this.parseParamList(l,d);d=L.nextIndex;let _=b.lastIndexOf("."),Q=b.lastIndexOf(":"),Le=Math.max(_,Q),Ne=Le>=0?b.slice(Le+1):b,ft={name:Ne,kind:x?"method":"function",line:g.line,column:g.column,scope:c.length>0?c[c.length-1].name:void 0,type:k,parameters:L.names,isLocal:!1,description:h(g.line)};o.push(ft),b.startsWith("lurek.")&&Os.has(Ne)&&i.push(ft);for(let gt of L.names)o.push({name:gt,kind:"parameter",line:g.line,column:g.column,scope:Ne,isLocal:!0});c.push({name:Ne,startLine:g.line,kind:"function"});continue}c.push({name:"<anonymous>",startLine:g.line,kind:"function"}),v(6,"(")&&(d=this.parseParamList(l,d).nextIndex);continue}if(p.type===1){let g=d,f=p.value,b=d+1,x=!1;for(;b<l.length;)if(l[b]?.value==="."&&l[b+1]?.type===1)f+="."+l[b+1].value,b+=2;else if(l[b]?.value===":"&&l[b+1]?.type===1)f+=":"+l[b+1].value,x=!0,b+=2;else break;if(b<l.length&&l[b]?.value==="="){let k=b,L=l[k+1];if(L?.type===0&&L.value==="function"){d=k+2;let _=this.parseParamList(l,d);d=_.nextIndex;let Q=f.lastIndexOf("."),Le=Q>=0?f.slice(Q+1):f,Ne={name:Le,kind:"function",line:p.line,column:p.column,parameters:_.names,isLocal:!1,description:h(p.line)};o.push(Ne),f.startsWith("lurek.")&&Os.has(Le)&&i.push(Ne);for(let ft of _.names)o.push({name:ft,kind:"parameter",line:p.line,column:p.column,scope:Le,isLocal:!0});c.push({name:Le,startLine:p.line,kind:"function"});continue}if(f.endsWith(".__index")&&L?.type===1){d=k+2;continue}}m();continue}if(p.type===0){if(p.value==="do"){c.push({name:"do",startLine:p.line,kind:"do"}),m();continue}if(p.value==="if"||p.value==="elseif"){p.value==="if"&&c.push({name:"if",startLine:p.line,kind:"if"}),m();continue}if(p.value==="for"){c.push({name:"for",startLine:p.line,kind:"for"}),m();continue}if(p.value==="while"){c.push({name:"while",startLine:p.line,kind:"while"}),m();continue}if(p.value==="repeat"){c.push({name:"repeat",startLine:p.line,kind:"repeat"}),m();continue}if(p.value==="end"||p.value==="until"){let g=c.pop();if(g){a.push({name:g.name,startLine:g.startLine,endLine:p.line,kind:g.kind});for(let f=o.length-1;f>=0;f--)if(o[f].kind==="function"&&o[f].name===g.name&&o[f].line===g.startLine){o[f].endLine=p.line;break}}m();continue}}m()}let y=e.split(`
`).length-1;for(;c.length>0;){let p=c.pop();a.push({name:p.name,startLine:p.startLine,endLine:y,kind:p.kind})}return{symbols:o,requires:s,callbacks:i,scopes:a,comments:r}}getSymbolAt(e,t,o){for(let s of e.symbols)if(s.line===t&&o>=s.column&&o<s.column+s.name.length)return s}getScopeAt(e,t){let o;for(let s of e.scopes)t>=s.startLine&&t<=s.endLine&&(!o||s.startLine>o.startLine)&&(o=s);return o}findReferencesInDocument(e,t){let o=[],s=this.tokenize(e);for(let i of s)i.type===1&&i.value===t&&o.push({line:i.line,column:i.column});return o}getVisibleLocals(e,t){let o=this.getScopeAt(e,t);return e.symbols.filter(s=>!s.isLocal||s.line>t?!1:s.scope&&o?s.scope===o.name||!s.scope:!0)}detectClasses(e){let t=[],o=new Set;for(let s of e.symbols)s.kind==="method"&&s.type&&o.add(s.type);for(let s of o){let i=e.symbols.filter(l=>l.kind==="method"&&l.type===s),a=e.symbols.filter(l=>l.kind==="field"&&l.scope===s).map(l=>l.name),r=i[0];r&&t.push({name:s,methods:i,fields:a,line:r.line})}return t}getWordAtPosition(e,t,o){let s=e.split(`
`);if(t<0||t>=s.length)return"";let i=s[t];if(o<0||o>=i.length)return"";let a=o,r=o;for(;a>0&&It(i[a-1]);)a--;for(;r<i.length&&It(i[r]);)r++;for(;a>0&&(i[a-1]==="."||i[a-1]===":");)for(a--;a>0&&It(i[a-1]);)a--;return i.slice(a,r)}getFunctionCallContext(e,t,o){let s=e.split(`
`);if(t<0||t>=s.length)return;let i=s[t],a=0,r=0,l=t,c=Math.min(o,i.length)-1;for(;l>=0;){let d=s[l],u=l===t?c:d.length-1;for(let v=u;v>=0;v--){let m=d[v];if(m===")"){a++;continue}if(m==="("){if(a===0){let h=v-1;for(;h>=0&&d[h]===" ";)h--;let y=h;for(;y>0&&(It(d[y-1])||d[y-1]==="."||d[y-1]===":");)y--;let p=d.slice(y,h+1);return p.length>0?{functionName:p,paramIndex:r}:void 0}a--;continue}m===","&&a===0&&r++}l--,l>=0&&(c=s[l].length-1)}}isInsideString(e,t,o){let s=this.tokenize(e);for(let i of s){if(i.type!==2)continue;let a=i.line+xo(i.value);if(i.line===a){if(i.line===t&&o>=i.column&&o<i.column+i.length)return!0}else{if(t>i.line&&t<a||t===i.line&&o>=i.column)return!0;if(t===a){let r=i.value.lastIndexOf(`
`),l=i.value.length-r-1;if(o<l)return!0}}}return!1}isInsideComment(e,t,o){let s=this.tokenize(e);for(let i of s){if(i.type!==4)continue;let a=i.line+xo(i.value);if(i.line===a){if(i.line===t&&o>=i.column)return!0}else{if(t>i.line&&t<a||t===i.line&&o>=i.column)return!0;if(t===a){let r=i.value.lastIndexOf(`
`),l=i.value.length-r-1;if(o<l)return!0}}}return!1}countLongBracketLevel(e,t){if(e[t]!=="[")return-1;let o=0,s=t+1;for(;s<e.length&&e[s]==="=";)o++,s++;return s<e.length&&e[s]==="["?o:-1}parseParamList(e,t){let o=[],s=t;if(s>=e.length||e[s]?.value!=="(")return{names:o,nextIndex:s};for(s++;s<e.length&&e[s]?.value!==")";)e[s]?.type===1?o.push(e[s].value):e[s]?.value==="..."&&o.push("..."),s++;return s<e.length&&e[s]?.value===")"&&s++,{names:o,nextIndex:s}}};function rt(n){return n>="0"&&n<="9"}function Yr(n){return rt(n)||n>="a"&&n<="f"||n>="A"&&n<="F"}function Hs(n){return n>="a"&&n<="z"||n>="A"&&n<="Z"||n==="_"}function It(n){return Hs(n)||rt(n)}function xo(n){let e=0;for(let t=0;t<n.length;t++)n[t]===`
`&&e++;return e}var wo={scheme:"file",language:"lua"},on=new G,js=new Map;function qs(n){let e=n.uri.toString(),t=js.get(e);if(t&&t.version===n.version)return t.info;let o=on.analyze(n.getText());return js.set(e,{version:n.version,info:o}),o}var Gr=[{label:"print",kind:C.CompletionItemKind.Function,detail:"print(...)",doc:"Receives any number of arguments and prints their values to stdout.",snippet:"print(${1:value})"},{label:"require",kind:C.CompletionItemKind.Function,detail:"require(modname)",doc:"Loads the given module, returns the value stored in `package.loaded[modname]`.",snippet:'require("${1:module}")'},{label:"type",kind:C.CompletionItemKind.Function,detail:"type(v) \u2192 string",doc:"Returns the type of its argument as a string.",snippet:"type(${1:value})"},{label:"tostring",kind:C.CompletionItemKind.Function,detail:"tostring(v) \u2192 string",doc:"Converts any value to a string in a reasonable format.",snippet:"tostring(${1:value})"},{label:"tonumber",kind:C.CompletionItemKind.Function,detail:"tonumber(e [, base]) \u2192 number|nil",doc:"Tries to convert its argument to a number.",snippet:"tonumber(${1:value})"},{label:"pairs",kind:C.CompletionItemKind.Function,detail:"pairs(t) \u2192 iterator",doc:"Returns an iterator function for all key-value pairs in table t.",snippet:"pairs(${1:table})"},{label:"ipairs",kind:C.CompletionItemKind.Function,detail:"ipairs(t) \u2192 iterator",doc:"Returns an iterator function for the integer keys 1, 2, ... in table t.",snippet:"ipairs(${1:table})"},{label:"next",kind:C.CompletionItemKind.Function,detail:"next(table [, index]) \u2192 key, value",doc:"Returns the next key-value pair after index in the table.",snippet:"next(${1:table})"},{label:"select",kind:C.CompletionItemKind.Function,detail:"select(index, ...)",doc:'Returns all arguments after argument number index, or the total number with "#".',snippet:"select(${1:index})"},{label:"unpack",kind:C.CompletionItemKind.Function,detail:"unpack(list [, i [, j]])",doc:"Returns the elements from the given list.",snippet:"unpack(${1:list})"},{label:"setmetatable",kind:C.CompletionItemKind.Function,detail:"setmetatable(table, metatable) \u2192 table",doc:"Sets the metatable for the given table.",snippet:"setmetatable(${1:table}, ${2:metatable})"},{label:"getmetatable",kind:C.CompletionItemKind.Function,detail:"getmetatable(object) \u2192 table|nil",doc:"Returns the metatable of the given object, if it has one.",snippet:"getmetatable(${1:object})"},{label:"rawset",kind:C.CompletionItemKind.Function,detail:"rawset(table, index, value) \u2192 table",doc:"Sets the value of table[index] without invoking metamethods.",snippet:"rawset(${1:table}, ${2:index}, ${3:value})"},{label:"rawget",kind:C.CompletionItemKind.Function,detail:"rawget(table, index) \u2192 value",doc:"Gets the value of table[index] without invoking metamethods.",snippet:"rawget(${1:table}, ${2:index})"},{label:"rawequal",kind:C.CompletionItemKind.Function,detail:"rawequal(v1, v2) \u2192 boolean",doc:"Checks equality without invoking __eq metamethod.",snippet:"rawequal(${1:v1}, ${2:v2})"},{label:"rawlen",kind:C.CompletionItemKind.Function,detail:"rawlen(v) \u2192 number",doc:"Returns the length without invoking __len metamethod.",snippet:"rawlen(${1:v})"},{label:"error",kind:C.CompletionItemKind.Function,detail:"error(message [, level])",doc:"Terminates the last protected function called and returns message as the error object.",snippet:"error(${1:message})"},{label:"pcall",kind:C.CompletionItemKind.Function,detail:"pcall(f, ...) \u2192 ok, result...",doc:"Calls function f in protected mode. Returns status and results.",snippet:"pcall(${1:func})"},{label:"xpcall",kind:C.CompletionItemKind.Function,detail:"xpcall(f, msgh, ...) \u2192 ok, result...",doc:"Calls function f in protected mode with message handler msgh.",snippet:"xpcall(${1:func}, ${2:handler})"},{label:"assert",kind:C.CompletionItemKind.Function,detail:"assert(v [, message])",doc:"Calls error if the value of v is false or nil.",snippet:"assert(${1:value})"},{label:"dofile",kind:C.CompletionItemKind.Function,detail:"dofile(filename)",doc:"Opens the named file and executes its contents as a Lua chunk.",snippet:'dofile("${1:filename}")'},{label:"loadfile",kind:C.CompletionItemKind.Function,detail:"loadfile(filename) \u2192 function|nil, err",doc:"Loads a chunk from a file without executing it.",snippet:'loadfile("${1:filename}")'},{label:"load",kind:C.CompletionItemKind.Function,detail:"load(chunk [, chunkname]) \u2192 function|nil, err",doc:"Loads a chunk from a string or function.",snippet:"load(${1:chunk})"},{label:"loadstring",kind:C.CompletionItemKind.Function,detail:"loadstring(s) \u2192 function|nil, err",doc:"Loads a chunk from a string (LuaJIT/Lua 5.1 compat).",snippet:"loadstring(${1:code})"},{label:"collectgarbage",kind:C.CompletionItemKind.Function,detail:"collectgarbage(opt [, arg])",doc:"Interface to the garbage collector.",snippet:'collectgarbage("${1:collect}")'}],Vr=[{label:"string",detail:"String manipulation library"},{label:"table",detail:"Table manipulation library"},{label:"math",detail:"Math library"},{label:"os",detail:"Operating system facilities"},{label:"io",detail:"I/O library"},{label:"coroutine",detail:"Coroutine library"},{label:"debug",detail:"Debug library"},{label:"package",detail:"Package library"}],Xr=["space","return","escape","up","down","left","right","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9","f1","f2","f3","f4","f5","f6","f7","f8","f9","f10","f11","f12","lshift","rshift","lctrl","rctrl","lalt","ralt","tab","backspace","delete","insert","home","end","pageup","pagedown"],Ur=[{pattern:/lurek\.input\.(?:isDown|isUp)\s*\(\s*["']$/,values:Xr.map(n=>({label:n,detail:"Key name"}))},{pattern:/lurek\.graphics\.setBlendMode\s*\(\s*["']$/,values:[{label:"alpha",detail:"Standard alpha blending"},{label:"add",detail:"Additive blending"},{label:"subtract",detail:"Subtractive blending"},{label:"multiply",detail:"Multiply blending"},{label:"premultiplied",detail:"Pre-multiplied alpha"},{label:"replace",detail:"Replace pixels (no blending)"},{label:"screen",detail:"Screen blending"},{label:"darken",detail:"Darken blending"},{label:"lighten",detail:"Lighten blending"}]},{pattern:/lurek\.graphics\.setLineCap\s*\(\s*["']$/,values:[{label:"none",detail:"No line cap"},{label:"butt",detail:"Flat cap (default)"},{label:"square",detail:"Square cap extends past endpoint"},{label:"round",detail:"Rounded cap"}]},{pattern:/lurek\.graphics\.setLineJoin\s*\(\s*["']$/,values:[{label:"miter",detail:"Sharp join (default)"},{label:"bevel",detail:"Flat corner join"},{label:"none",detail:"No join"}]},{pattern:/lurek\.physics\.newBody\s*\([^)]*,\s*["']$/,values:[{label:"static",detail:"Immovable body"},{label:"dynamic",detail:"Fully simulated body"},{label:"kinematic",detail:"Moved by code, not forces"}]},{pattern:/lurek\.audio\.newSource\s*\([^)]*,\s*["']$/,values:[{label:"static",detail:"Load entirely into memory"},{label:"stream",detail:"Stream from disk"}]},{pattern:/:setFilter\s*\(\s*["']$/,values:[{label:"nearest",detail:"Pixel-perfect (no filtering)"},{label:"linear",detail:"Smooth bilinear filtering"}]},{pattern:/:setWrap\s*\(\s*["']$/,values:[{label:"clamp",detail:"Clamp to edge"},{label:"clampzero",detail:"Clamp to transparent"},{label:"repeat",detail:"Tile texture"},{label:"mirroredrepeat",detail:"Tile with mirroring"}]},{pattern:/lurek\.graphics\.setDefaultFilter\s*\(\s*["']$/,values:[{label:"nearest",detail:"Pixel-perfect (no filtering)"},{label:"linear",detail:"Smooth bilinear filtering"}]},{pattern:/lurek\.graphics\.setLineStyle\s*\(\s*["']$/,values:[{label:"rough",detail:"Aliased line"},{label:"smooth",detail:"Anti-aliased line"}]},{pattern:/lurek\.graphics\.(?:rectangle|circle|polygon|ellipse|arc)\s*\(\s*["']$/,values:[{label:"fill",detail:"Filled shape"},{label:"line",detail:"Outlined shape"}]},{pattern:/(?:easing|ease|tween)\s*[=:]\s*["']$|lurek\.tween\.\w+\s*\([^)]*["']$/i,values:[{label:"linear",detail:"Constant speed"},{label:"inQuad",detail:"Accelerating (quadratic)"},{label:"outQuad",detail:"Decelerating (quadratic)"},{label:"inOutQuad",detail:"Accel then decel (quadratic)"},{label:"inCubic",detail:"Accelerating (cubic)"},{label:"outCubic",detail:"Decelerating (cubic)"},{label:"inOutCubic",detail:"Accel then decel (cubic)"},{label:"inQuart",detail:"Accelerating (quartic)"},{label:"outQuart",detail:"Decelerating (quartic)"},{label:"inQuint",detail:"Accelerating (quintic)"},{label:"outQuint",detail:"Decelerating (quintic)"},{label:"inSine",detail:"Sine wave acceleration"},{label:"outSine",detail:"Sine wave deceleration"},{label:"inOutSine",detail:"Sine wave accel/decel"},{label:"inExpo",detail:"Exponential acceleration"},{label:"outExpo",detail:"Exponential deceleration"},{label:"inCirc",detail:"Circular acceleration"},{label:"outCirc",detail:"Circular deceleration"},{label:"inBack",detail:"Overshoot on start"},{label:"outBack",detail:"Overshoot on end"},{label:"inBounce",detail:"Bounce on start"},{label:"outBounce",detail:"Bounce on end"},{label:"inElastic",detail:"Elastic spring start"},{label:"outElastic",detail:"Elastic spring end"}]},{pattern:/lurek\.graphics\.printf\s*\([^)]*,[^)]*,[^)]*,[^)]*,\s*["']$/,values:[{label:"left",detail:"Left-aligned text"},{label:"center",detail:"Center-aligned text"},{label:"right",detail:"Right-aligned text"},{label:"justify",detail:"Justified text"}]},{pattern:/lurek\.graphics\.(?:setStencilTest|stencil)\s*\([^)]*["']$/,values:[{label:"greater",detail:"Draw where stencil > value"},{label:"greaterequal",detail:"Draw where stencil >= value"},{label:"less",detail:"Draw where stencil < value"},{label:"lessequal",detail:"Draw where stencil <= value"},{label:"equal",detail:"Draw where stencil == value"},{label:"notequal",detail:"Draw where stencil != value"},{label:"always",detail:"Always draw"},{label:"never",detail:"Never draw"}]},{pattern:/lurek\.input\.(?:getAxis|isGamepadAxis)\s*\([^)]*,\s*["']$/,values:[{label:"leftx",detail:"Left stick X axis"},{label:"lefty",detail:"Left stick Y axis"},{label:"rightx",detail:"Right stick X axis"},{label:"righty",detail:"Right stick Y axis"},{label:"triggerleft",detail:"Left trigger"},{label:"triggerright",detail:"Right trigger"}]},{pattern:/lurek\.input\.(?:isGamepadDown|isGamepadUp|wasGamepadPressed)\s*\([^)]*,\s*["']$/,values:[{label:"a",detail:"A button (Cross on PS)"},{label:"b",detail:"B button (Circle on PS)"},{label:"x",detail:"X button (Square on PS)"},{label:"y",detail:"Y button (Triangle on PS)"},{label:"back",detail:"Back / Select"},{label:"start",detail:"Start / Options"},{label:"leftshoulder",detail:"Left bumper (LB/L1)"},{label:"rightshoulder",detail:"Right bumper (RB/R1)"},{label:"lefttrigger",detail:"Left trigger (LT/L2)"},{label:"righttrigger",detail:"Right trigger (RT/R2)"},{label:"leftstick",detail:"Left stick click (LS/L3)"},{label:"rightstick",detail:"Right stick click (RS/R3)"},{label:"dpup",detail:"D-pad up"},{label:"dpdown",detail:"D-pad down"},{label:"dpleft",detail:"D-pad left"},{label:"dpright",detail:"D-pad right"},{label:"guide",detail:"Guide / Home button"}]},{pattern:/lurek\.graphics\.arc\s*\(\s*["']$/,values:[{label:"pie",detail:"Pie-slice arc"},{label:"open",detail:"Open arc (lines to centre not drawn)"},{label:"closed",detail:"Arc with closing chord"}]},{pattern:/lurek\.audio\.(?:setEffect|newEffect)\s*\([^)]*,\s*["']$/,values:[{label:"reverb",detail:"Reverb / room effect"},{label:"delay",detail:"Echo delay"},{label:"chorus",detail:"Chorus doubling effect"},{label:"distortion",detail:"Distortion"},{label:"echo",detail:"Echo"},{label:"flanger",detail:"Flanger"},{label:"ringmodulator",detail:"Ring modulator"},{label:"equalizer",detail:"EQ / equalizer"},{label:"bandpass",detail:"Band-pass filter"},{label:"lowpass",detail:"Low-pass filter"},{label:"highpass",detail:"High-pass filter"}]}],Kr={"lurek.graphics.newImage":"Image","lurek.graphics.newCanvas":"Canvas","lurek.graphics.newFont":"Font","lurek.graphics.newShader":"Shader","lurek.graphics.newQuad":"Quad","lurek.graphics.newMesh":"Mesh","lurek.graphics.newSpriteBatch":"SpriteBatch","lurek.graphics.newParticleSystem":"ParticleSystem","lurek.graphics.newImageData":"ImageData","lurek.audio.newSource":"Source","lurek.physics.newWorld":"World","lurek.physics.newBody":"Body","lurek.physics.newFixture":"Fixture","lurek.physics.newRectangleShape":"Shape","lurek.physics.newCircleShape":"Shape","lurek.physics.newPolygonShape":"Shape","lurek.physics.newEdgeShape":"Shape","lurek.physics.newChainShape":"Shape","lurek.physics.newDistanceJoint":"Joint","lurek.physics.newRevoluteJoint":"Joint","lurek.physics.newPrismaticJoint":"Joint","lurek.physics.newWeldJoint":"Joint","lurek.thread.newChannel":"Channel","lurek.thread.newThread":"Thread"},Jr=new Set(["draw","setColor","rectangle","circle","print","line","clear","push","pop","translate","rotate","scale","newImage","newFont","newCanvas","getWidth","getHeight","isDown","getMousePosition","newWorld","newBody","newSource","play","stop","getTime","getDelta","getFPS","random","lerp","clamp","read","write","exists"]);function ko(n){let e=new C.MarkdownString;if(e.appendCodeblock(n.signature,"lua"),n.description&&e.appendMarkdown(`
`+n.description+`
`),n.parameters.length>0){e.appendMarkdown(`
**Parameters:**
`);for(let t of n.parameters){let o=t.optional?" *(optional)*":"",s=t.default?` \u2014 default: \`${t.default}\``:"",i=t.description?` \u2014 ${t.description}`:"";e.appendMarkdown(`- \`${t.name}\`: *${t.type}*${o}${i}${s}
`)}}return n.returns&&e.appendMarkdown(`
**Returns:** ${n.returns}
`),n.since&&e.appendMarkdown(`
*Since ${n.since}*`),n.deprecated&&e.appendMarkdown(`

\u26A0\uFE0F **Deprecated:** ${n.deprecated}`),e.isTrusted=!0,e}function Ys(n){if(n.parameters.length===0)return n.name+"()";let e=n.parameters.filter(o=>!o.optional);if(e.length===0)return n.name+"(${1})";let t=e.map((o,s)=>`\${${s+1}:${o.name}}`).join(", ");return`${n.name}(${t})`}function Zr(n){if(n.parameters.length===0&&!n.signature.includes("("))return n.name;let t=n.parameters.filter(s=>!s.optional&&s.name!=="...");if(t.length===0)return n.name+"(${1})";let o=t.map((s,i)=>`\${${i+1}:${s.name}}`).join(", ");return`${n.name}(${o})`}function Gs(n){return Jr.has(n.name)?"0"+n.name:n.deprecated?"2"+n.name:"1"+n.name}function Qr(n){return n.replace(/[.*+?^${}()|[\]\\]/g,"\\$&")}function el(n,e,t,o){let s=n.getText().split(`
`);for(let a=e.line;a>=0;a--){let r=s[a].match(new RegExp(`(?:local\\s+)?${Qr(t)}\\s*=\\s*(lurek\\.[\\w.]+)\\s*\\(`));if(r){let l=r[1],c=Kr[l];if(c)return c;let d=o.getFunction(l);if(d?.returnType&&o.getMethods(d.returnType).length>0)return d.returnType}}let i=t.charAt(0).toUpperCase()+t.slice(1);if(o.getMethods(i).length>0)return i}function Vs(n,e){let t=C.languages.registerCompletionItemProvider(wo,{provideCompletionItems(i,a){let l=i.lineAt(a).text.substring(0,a.character);try{if(on.isInsideComment(i.getText(),a.line,a.character))return}catch{}let c=l.match(/lurek\.(\w+)\.(\w*)$/);if(c){let m=c[1],h=c[2].toLowerCase(),y=e.getFunctions(m);return y.length===0?void 0:y.filter(p=>!h||p.name.toLowerCase().startsWith(h)).sort((p,g)=>Gs(p).localeCompare(Gs(g))).map((p,g)=>{let f=new C.CompletionItem(p.name,p.isMethod?C.CompletionItemKind.Method:C.CompletionItemKind.Function);return f.detail=p.signature,f.documentation=ko(p),f.insertText=new C.SnippetString(Ys(p)),f.sortText=String(g).padStart(4,"0"),p.deprecated&&(f.tags=[C.CompletionItemTag.Deprecated]),f})}let d=l.match(/lurek\.(\w*)$/);if(d){let m=d[1].toLowerCase(),h=[];for(let y of e.getModuleNames()){if(m&&!y.toLowerCase().startsWith(m))continue;let p=e.getModule(y),g=new C.CompletionItem(y,C.CompletionItemKind.Module);g.detail=`lurek.${y}`,p?.description&&(g.documentation=new C.MarkdownString(p.description)),g.sortText="0"+y,h.push(g)}for(let y of e.getCallbacks()){if(m&&!y.name.toLowerCase().startsWith(m))continue;let p=new C.CompletionItem(y.name,C.CompletionItemKind.Event);p.detail=y.signature,p.documentation=new C.MarkdownString(y.description),p.sortText="1"+y.name,h.push(p)}return h}let u=l.match(/\b(string|table|math|os|io|coroutine|debug|package|utf8|bit|jit|ffi)\.(\w*)$/);if(u){let m=u[1],h=u[2].toLowerCase(),p=e.getLuaStdlib("luajit").filter(g=>g.module===m);return p.length===0?void 0:p.filter(g=>!h||g.name.toLowerCase().startsWith(h)).map(g=>{let f=g.parameters.length===0&&!g.signature.includes("("),b=new C.CompletionItem(g.name,f?C.CompletionItemKind.Constant:C.CompletionItemKind.Function);return b.detail=g.signature,b.documentation=ko(g),f||(b.insertText=new C.SnippetString(Zr(g))),b})}let v=l.match(/(\w+):(\w*)$/);if(v){let m=v[1],h=v[2].toLowerCase(),y=[],p=el(i,a,m,e);if(p)for(let g of e.getMethods(p)){if(h&&!g.name.toLowerCase().startsWith(h))continue;let f=new C.CompletionItem(g.name,C.CompletionItemKind.Method);f.detail=g.signature,f.documentation=ko(g),f.insertText=new C.SnippetString(Ys(g)),g.deprecated&&(f.tags=[C.CompletionItemTag.Deprecated]),y.push(f)}try{let g=qs(i),f=on.detectClasses(g),b=new Set(y.map(x=>typeof x.label=="string"?x.label:""));for(let x of f)if(!(x.name.toLowerCase()!==m.toLowerCase()&&x.name!==p))for(let k of x.methods){if(h&&!k.name.toLowerCase().startsWith(h)||b.has(k.name))continue;b.add(k.name);let L=new C.CompletionItem(k.name,C.CompletionItemKind.Method);L.detail=`${x.name}:${k.name}(${(k.parameters??[]).join(", ")})`,k.description&&(L.documentation=new C.MarkdownString(k.description)),y.push(L)}}catch{}if(y.length>0)return y}if(/(?:^|[\s=(,{;])[\w]*$/.test(l)&&!l.match(/\.\w*$/)&&!l.match(/:\w*$/)){let m=[];for(let y of Gr){let p=new C.CompletionItem(y.label,y.kind);p.detail=y.detail,p.documentation=new C.MarkdownString(y.doc),y.snippet&&(p.insertText=new C.SnippetString(y.snippet)),p.sortText="2"+y.label,m.push(p)}for(let y of Vr){let p=new C.CompletionItem(y.label,C.CompletionItemKind.Module);p.detail=y.detail,p.sortText="3"+y.label,m.push(p)}let h=new C.CompletionItem("lurek",C.CompletionItemKind.Module);h.detail="Lurek2D engine API",h.sortText="1lurek",m.push(h);try{let y=qs(i),p=on.getVisibleLocals(y,a.line),g=new Set(m.map(f=>typeof f.label=="string"?f.label:""));for(let f of p){if(g.has(f.name))continue;g.add(f.name);let b=f.kind==="function"?C.CompletionItemKind.Function:C.CompletionItemKind.Variable,x=new C.CompletionItem(f.name,b);x.detail=f.kind==="function"?`local function ${f.name}(${(f.parameters??[]).join(", ")})`:f.kind==="parameter"?"parameter":`local ${f.name}`,f.description&&(x.documentation=new C.MarkdownString(f.description)),x.sortText="0"+f.name,m.push(x)}for(let f of y.symbols){if(f.isLocal||f.kind==="parameter"||g.has(f.name))continue;g.add(f.name);let b=f.kind==="function"||f.kind==="method"?C.CompletionItemKind.Function:C.CompletionItemKind.Variable,x=new C.CompletionItem(f.name,b);x.detail=f.kind==="function"?`function ${f.name}(${(f.parameters??[]).join(", ")})`:f.name,x.sortText="1"+f.name,m.push(x)}}catch{}return m}}},".",":"),o=C.languages.registerCompletionItemProvider(wo,{provideCompletionItems(i,a){let r=i.lineAt(a).text.substring(0,a.character);for(let l of Ur)if(l.pattern.test(r))return l.values.map(c=>{let d=new C.CompletionItem(c.label,C.CompletionItemKind.EnumMember);return c.detail&&(d.detail=c.detail),d.insertText=c.label,d})}},"'",'"'),s=C.languages.registerCompletionItemProvider(wo,{async provideCompletionItems(i,a){let l=i.lineAt(a).text.substring(0,a.character).match(/require\s*\(\s*["']([^"']*)$/);if(!l)return;let c=l[1],d=[];try{let u=await C.workspace.findFiles("**/*.lua","**/node_modules/**",200),v=C.workspace.workspaceFolders?.[0]?.uri.fsPath;for(let m of u){if(m.fsPath===i.uri.fsPath)continue;let h="";v&&m.fsPath.startsWith(v)?h=m.fsPath.substring(v.length+1):h=C.workspace.asRelativePath(m);let y=h.replace(/\\/g,"/");y.endsWith("/init.lua")?y=y.slice(0,-9):y.endsWith(".lua")&&(y=y.slice(0,-4));let p=y.replace(/\//g,".");if(c&&!p.toLowerCase().startsWith(c.toLowerCase()))continue;let g=new C.CompletionItem(p,C.CompletionItemKind.File);g.detail=h,g.insertText=p,d.push(g)}}catch{}return d}},"'",'"');n.subscriptions.push(t,o,s)}var q=E(require("vscode"));var Pt={scheme:"file",language:"lua"},nl=new G,Xs=new Map;function ol(n){let e=n.uri.toString(),t=Xs.get(e);if(t&&t.version===n.version)return t.info;let o=nl.analyze(n.getText());return Xs.set(e,{version:n.version,info:o}),o}var sl={function:"Declares a function. Functions are first-class values in Lua.\n```lua\nfunction name(args) body end\nlocal f = function(args) body end\n```",local:"Declares a local variable or function. Local scope is limited to the enclosing block.\n```lua\nlocal x = 10\nlocal function helper() end\n```",if:`Conditional statement. Evaluates condition and executes the \`then\` block if truthy.
\`\`\`lua
if condition then
  -- body
elseif other then
  -- body
else
  -- body
end
\`\`\``,then:"Follows `if`/`elseif` to begin the conditional block.",else:"Alternative branch in an `if` statement, executed when all preceding conditions are false.",elseif:"Additional conditional branch in an `if` statement.\n```lua\nif x > 0 then\n  -- positive\nelseif x < 0 then\n  -- negative\nend\n```",end:"Closes a block started by `function`, `if`, `for`, `while`, or `do`.",for:"Loop construct. Numeric `for` or generic `for` (iterator).\n```lua\nfor i = 1, 10 do end       -- numeric\nfor k, v in pairs(t) do end -- generic\n```",while:"Loop that repeats while condition is truthy.\n```lua\nwhile condition do\n  -- body\nend\n```",repeat:"Loop that repeats until condition becomes truthy (always executes at least once).\n```lua\nrepeat\n  -- body\nuntil condition\n```",until:"Ends a `repeat` loop when the condition becomes truthy.",do:"Creates a block scope.\n```lua\ndo\n  local temp = compute()\nend -- temp is out of scope\n```",return:"Returns values from a function. Must be the last statement in a block.\n```lua\nreturn value1, value2\n```",break:"Exits the innermost `for`, `while`, or `repeat` loop.",goto:"Jumps to a label (Lua 5.2+/LuaJIT).\n```lua\ngoto done\n::done::\n```",in:"Used in generic `for` loops: `for k, v in pairs(t) do end`",and:"Logical AND operator. Returns first argument if falsy, otherwise second.\n```lua\nlocal x = a and b  -- b if a is truthy\n```",or:"Logical OR operator. Returns first argument if truthy, otherwise second.\n```lua\nlocal x = a or default  -- default if a is falsy\n```",not:"Logical NOT operator. Returns `true` if argument is falsy, `false` otherwise.",nil:"The absence of a value. Variables are `nil` before assignment. `nil` is falsy.",true:"Boolean true value.",false:"Boolean false value. Along with `nil`, the only falsy values in Lua."},il={"math.pi":"**`math.pi`** = `3.141592653589793` (\u03C0)\n\nRatio of a circle's circumference to its diameter.\n\n*Tip: `lurek.math.pi` is also available as a constant.*","math.huge":"**`math.huge`** = `+\u221E` (positive infinity overflow sentinel)\n\nUsed as a sentinel for unbounded ranges, e.g. `math.min(math.huge, x)` always returns `x`.","math.maxinteger":"**`math.maxinteger`** = `2^63 - 1` (max 64-bit signed integer, Lua 5.3+/LuaJIT)","math.mininteger":"**`math.mininteger`** = `-2^63` (min 64-bit signed integer, Lua 5.3+/LuaJIT)"},al={linear:{fn:n=>n,desc:"Constant speed, no acceleration"},inQuad:{fn:n=>n*n,desc:"Slow start, accelerating (quadratic)"},outQuad:{fn:n=>n*(2-n),desc:"Fast start, decelerating (quadratic)"},inOutQuad:{fn:n=>n<.5?2*n*n:-1+(4-2*n)*n,desc:"Accelerate then decelerate (quadratic)"},inCubic:{fn:n=>n*n*n,desc:"Slow start, accelerating (cubic)"},outCubic:{fn:n=>{let e=n-1;return e*e*e+1},desc:"Fast start, decelerating (cubic)"},inOutCubic:{fn:n=>n<.5?4*n*n*n:(n-1)*(2*n-2)*(2*n-2)+1,desc:"Accelerate then decelerate (cubic)"},inQuart:{fn:n=>n*n*n*n,desc:"Slow start, accelerating (quartic)"},outQuart:{fn:n=>{let e=n-1;return 1-e*e*e*e},desc:"Fast start, decelerating (quartic)"},inQuint:{fn:n=>n*n*n*n*n,desc:"Slow start, accelerating (quintic)"},outQuint:{fn:n=>{let e=n-1;return 1+e*e*e*e*e},desc:"Fast start, decelerating (quintic)"},inSine:{fn:n=>1-Math.cos(n*Math.PI/2),desc:"Sine wave acceleration"},outSine:{fn:n=>Math.sin(n*Math.PI/2),desc:"Sine wave deceleration"},inOutSine:{fn:n=>.5*(1-Math.cos(Math.PI*n)),desc:"Sine wave accel/decel"},inExpo:{fn:n=>n===0?0:Math.pow(2,10*(n-1)),desc:"Exponential acceleration"},outExpo:{fn:n=>n===1?1:1-Math.pow(2,-10*n),desc:"Exponential deceleration"},inBack:{fn:n=>n*n*((1.70158+1)*n-1.70158),desc:"Overshoot start then accelerate"},outBack:{fn:n=>{let t=n-1;return t*t*((1.70158+1)*t+1.70158)+1},desc:"Decelerate with overshoot at end"},outBounce:{fn:n=>{if(n<1/2.75)return 7.5625*n*n;if(n<2/2.75){let t=n-.5454545454545454;return 7.5625*t*t+.75}if(n<2.5/2.75){let t=n-.8181818181818182;return 7.5625*t*t+.9375}let e=n-2.625/2.75;return 7.5625*e*e+.984375},desc:"Bounce at end"},inBounce:{fn:n=>{let e=1-n;if(e<1/2.75)return 1-7.5625*e*e;if(e<2/2.75){let o=e-.5454545454545454;return 1-(7.5625*o*o+.75)}if(e<2.5/2.75){let o=e-.8181818181818182;return 1-(7.5625*o*o+.9375)}let t=e-2.625/2.75;return 1-(7.5625*t*t+.984375)},desc:"Bounce at start"},outElastic:{fn:n=>n===0||n===1?n:Math.pow(2,-10*n)*Math.sin((n-.075)*(2*Math.PI)/.3)+1,desc:"Elastic spring at end"},inElastic:{fn:n=>n===0||n===1?n:-(Math.pow(2,10*(n-1))*Math.sin((n-1.075)*(2*Math.PI)/.3)),desc:"Elastic spring at start"}};function rl(n,e){let s=[];for(let r=0;r<=20;r++)s.push(Math.max(0,Math.min(1,e(r/20))));let i=[];for(let r=0;r<8;r++)i.push(new Array(21).fill(" "));for(let r=0;r<=20;r++){let l=Math.max(0,Math.min(7,Math.round((1-s[r])*7)));i[l][r]="\u25CF"}let a=[];for(let r=0;r<8;r++){let l=r===0?"1\u2502":r===7?"0\u2502":" \u2502";a.push(l+i[r].join(""))}return a.push("  \u2514"+"\u2500".repeat(21)+"\u25BA t"),a.join(`
`)}function Us(n){let e=new q.MarkdownString;if(e.appendCodeblock(n.signature,"lua"),n.description&&e.appendMarkdown(`
`+n.description+`
`),n.parameters.length>0){e.appendMarkdown(`
**Parameters:**

`),e.appendMarkdown(`| Name | Type | Description |
`),e.appendMarkdown(`|------|------|-------------|
`);for(let o of n.parameters){let s=o.optional?" *(opt)*":"",i=o.default?` (default: \`${o.default}\`)`:"",a=(o.description||"")+i;e.appendMarkdown(`| \`${o.name}\` | *${o.type}*${s} | ${a} |
`)}}n.returns&&e.appendMarkdown(`
**Returns:** ${n.returns}
`),n.since&&e.appendMarkdown(`
*Since ${n.since}*
`),n.deprecated&&e.appendMarkdown(`
\u26A0\uFE0F **Deprecated:** ${n.deprecated}
`);let t=n.module?`lurek.${n.module}`:"";return t&&e.appendMarkdown(`
*${t}*`),e.isTrusted=!0,e}function Ks(n,e){let t=q.languages.registerHoverProvider(Pt,{provideHover(l,c){let d=l.getWordRangeAtPosition(c,/lurek\.\w+\.\w+/);if(d){let h=l.getText(d),y=e.getFunction(h);if(y)return new q.Hover(Us(y),d)}let u=l.getWordRangeAtPosition(c,/lurek\.\w+/);if(u){let h=l.getText(u);if(!h.includes(".",5)){for(let g of e.getCallbacks())if(g.fullPath===h){let f=new q.MarkdownString;if(f.appendCodeblock(g.signature,"lua"),f.appendMarkdown(`
`+g.description+`
`),g.parameters.length>0){f.appendMarkdown(`
**Parameters:**
`);for(let b of g.parameters)f.appendMarkdown(`- \`${b.name}\`: *${b.type}* \u2014 ${b.description}
`)}return f.appendMarkdown(`
*Engine callback \u2014 called automatically by Lurek2D*`),f.isTrusted=!0,new q.Hover(f,u)}}let y=h.replace("lurek.",""),p=e.getModule(y);if(p){let g=new q.MarkdownString;return g.appendMarkdown(`**lurek.${p.name}**

`),p.description&&g.appendMarkdown(p.description+`

`),g.appendMarkdown(`*${p.functions.length} functions, ${p.methods.length} methods*`),g.isTrusted=!0,new q.Hover(g,u)}}let v=l.getWordRangeAtPosition(c,/\b(?:string|table|math|os|io|coroutine|debug|package|utf8|bit|jit|ffi)\.\w+/);if(v){let h=l.getText(v),p=e.getLuaStdlib("luajit").find(g=>g.fullPath===h);if(p)return new q.Hover(Us(p),v)}let m=l.getWordRangeAtPosition(c,/\w+/);if(m){let h=l.getText(m),y=l.lineAt(c).text;if((m.start.character>0?y[m.start.character-1]:"")===".")return;try{let f=ol(l);for(let b of f.symbols)if(b.name===h&&b.line<=c.line){if(b.kind==="parameter")continue;let x=new q.MarkdownString;if(b.kind==="function"){let k=(b.parameters??[]).join(", "),L=b.isLocal?"local ":"";x.appendCodeblock(`${L}function ${b.name}(${k})`,"lua")}else if(b.kind==="method"){let k=(b.parameters??[]).join(", ");x.appendCodeblock(`function ${b.type??"obj"}:${b.name}(${k})`,"lua")}else b.kind==="table"?x.appendCodeblock(`local ${b.name} = {}`,"lua"):x.appendCodeblock(`local ${b.name}`,"lua");return b.description&&x.appendMarkdown(`
`+b.description+`
`),x.appendMarkdown(`
*Defined at line ${b.line+1}*`),b.scope&&x.appendMarkdown(` \xB7 scope: \`${b.scope}\``),x.isTrusted=!0,new q.Hover(x,m)}}catch{}let g=sl[h];if(g){let f=new q.MarkdownString;return f.appendMarkdown(`**\`${h}\`** \u2014 Lua keyword

`),f.appendMarkdown(g),f.isTrusted=!0,new q.Hover(f,m)}}}}),o=q.languages.registerHoverProvider(Pt,{provideHover(l,c){let d=l.lineAt(c).text,u=c.character,v=-1,m="";for(let x=u;x>=0;x--)if(d[x]==='"'||d[x]==="'"){v=x+1,m=d[x];break}if(v<0||!m)return;let h=-1;for(let x=u;x<d.length;x++)if(d[x]===m){h=x;break}if(h<0)return;let y=d.substring(v,h),p=al[y];if(!p)return;let g=rl(y,p.fn),f=new q.MarkdownString;f.appendMarkdown(`**Easing: \`${y}\`**

`),f.appendCodeblock(g,""),f.appendMarkdown(`
${p.desc}
`),f.isTrusted=!0;let b=new q.Range(c.line,v,c.line,h);return new q.Hover(f,b)}}),s=q.languages.registerHoverProvider(Pt,{provideHover(l,c){let d=l.getWordRangeAtPosition(c,/math\.\w+/);if(!d)return;let u=l.getText(d),v=il[u];if(!v)return;let m=new q.MarkdownString(v);return m.isTrusted=!0,new q.Hover(m,d)}}),i={update:{dt:{type:"number",desc:"Delta time in seconds since the last frame. Use this to make movement frame-rate-independent.\n\n```lua\nfunction lurek.update(dt)\n  x = x + speed * dt\nend\n```"}},keypressed:{key:{type:"string",desc:'Name of the key that was pressed (e.g. `"space"`, `"a"`, `"left"`, `"escape"`).'},scancode:{type:"string",desc:"Physical hardware scancode \u2014 use for layout-independent input."},isrepeat:{type:"boolean",desc:"`true` if generated by key repeat (held down), `false` for first press."}},keyreleased:{key:{type:"string",desc:'Name of the key that was released (e.g. `"space"`, `"a"`, `"left"`).'},scancode:{type:"string",desc:"Physical hardware scancode of the key."}},mousepressed:{x:{type:"number",desc:"Mouse X position in screen coordinates when button was pressed."},y:{type:"number",desc:"Mouse Y position in screen coordinates when button was pressed."},button:{type:"number",desc:"Mouse button index: `1` = left, `2` = right, `3` = middle."},istouch:{type:"boolean",desc:"`true` if this event was generated by a touch input device."},presses:{type:"number",desc:"Number of consecutive presses (`2` = double-click)."}},mousereleased:{x:{type:"number",desc:"Mouse X position when button was released."},y:{type:"number",desc:"Mouse Y position when button was released."},button:{type:"number",desc:"Mouse button index: `1` = left, `2` = right, `3` = middle."},istouch:{type:"boolean",desc:"`true` if generated by a touch input device."}},wheelmoved:{x:{type:"number",desc:"Horizontal scroll amount. Positive = right."},y:{type:"number",desc:"Vertical scroll amount. Positive = up (scroll wheel towards user)."}},resize:{w:{type:"number",desc:"New window width in pixels."},h:{type:"number",desc:"New window height in pixels."}},focus:{f:{type:"boolean",desc:"`true` if the window gained focus, `false` if it lost focus."}},visible:{v:{type:"boolean",desc:"`true` if the window became visible, `false` if minimized/hidden."}},textinput:{t:{type:"string",desc:"The UTF-8 encoded character(s) that were typed. Use this for text field input rather than `lurek.keypressed`."}},gamepadpressed:{joystick:{type:"Joystick",desc:"The joystick/gamepad object that reported the event."},button:{type:"string",desc:'Gamepad virtual button name: `"a"`, `"b"`, `"x"`, `"y"`, `"back"`, `"start"`, `"leftshoulder"`, `"rightshoulder"`, `"dpup"`, `"dpdown"`, `"dpleft"`, `"dpright"`.'}},gamepadreleased:{joystick:{type:"Joystick",desc:"The joystick/gamepad object that reported the event."},button:{type:"string",desc:'Gamepad virtual button name (`"a"`, `"b"`, `"x"`, `"y"`, etc.).'}},gamepadaxis:{joystick:{type:"Joystick",desc:"The joystick/gamepad object that reported the event."},axis:{type:"string",desc:'Axis name: `"leftx"`, `"lefty"`, `"rightx"`, `"righty"`, `"triggerleft"`, `"triggerright"`.'},value:{type:"number",desc:"Axis value in the range `[-1.0, 1.0]` (triggers: `[0, 1]`)."}},joystickadded:{joystick:{type:"Joystick",desc:"The joystick/gamepad that was connected."}},joystickremoved:{joystick:{type:"Joystick",desc:"The joystick/gamepad that was disconnected."}},touchpressed:{id:{type:"lightuserdata",desc:"Unique identifier for this touch point."},x:{type:"number",desc:"X position of the touch in screen coordinates."},y:{type:"number",desc:"Y position of the touch in screen coordinates."},dx:{type:"number",desc:"X movement delta since last touch event."},dy:{type:"number",desc:"Y movement delta since last touch event."},pressure:{type:"number",desc:"Touch pressure in `[0, 1]`. Not all devices support pressure."}},touchmoved:{id:{type:"lightuserdata",desc:"Unique identifier for this touch point."},x:{type:"number",desc:"X position of the touch."},y:{type:"number",desc:"Y position of the touch."},dx:{type:"number",desc:"X movement delta."},dy:{type:"number",desc:"Y movement delta."},pressure:{type:"number",desc:"Touch pressure in `[0, 1]`."}},touchreleased:{id:{type:"lightuserdata",desc:"Unique identifier for the touch point that ended."},x:{type:"number",desc:"X position where touch was released."},y:{type:"number",desc:"Y position where touch was released."},dx:{type:"number",desc:"X movement delta at release."},dy:{type:"number",desc:"Y movement delta at release."},pressure:{type:"number",desc:"Pressure at release."}}},a=q.languages.registerHoverProvider(Pt,{provideHover(l,c){let d=l.getWordRangeAtPosition(c,/\w+/);if(!d)return;let u=l.getText(d);if(!(u in Object.values(i).reduce((b,x)=>({...b,...x}),{})))return;let v=l.getText().split(`
`),m,h=0;for(let b=c.line;b>=0;b--){let x=v[b],k=(x.match(/\bend\b/g)??[]).length,L=(x.match(/\b(?:function|do|then|repeat)\b/g)??[]).length;if(h+=k-L,h>=0){let _=x.match(/lurek\.(\w+)\s*=\s*function/);if(_){m=_[1];break}}}if(!m)return;let y=i[m];if(!y?.[u])return;let{type:p,desc:g}=y[u],f=new q.MarkdownString;return f.appendCodeblock(`(parameter) ${u}: ${p}`,"typescript"),f.appendMarkdown(`
${g}

*Parameter of \`lurek.${m}\`*`),f.isTrusted=!0,new q.Hover(f,d)}}),r=q.languages.registerHoverProvider(Pt,{provideHover(l,c){let d=l.lineAt(c).text;if(!/lurek\.physics\.newWorld/.test(d))return;let u=l.getWordRangeAtPosition(c,/[-\d]+\.?\d*/);if(!u)return;let v=l.getText(u),m=parseFloat(v);if(isNaN(m)||(d.substring(0,u.start.character).match(/,/g)??[]).length!==1)return;let p=Math.round(980),g=new q.MarkdownString(`**Gravity Y = ${m} px/s\xB2**

Earth gravity (at 1px = 1cm) \u2248 **${p} px/s\xB2**

Current value is **${(m/p*100).toFixed(0)}%** of Earth gravity.`);return g.isTrusted=!0,new q.Hover(g,u)}});n.subscriptions.push(t,o,s,a,r)}var De=E(require("vscode"));var cl={scheme:"file",language:"lua"},dl=new G;function ul(n){let e=new De.SignatureInformation(n.signature);return e.documentation=new De.MarkdownString(n.description),e.parameters=n.parameters.map(t=>{let o=new De.MarkdownString,s=t.optional?" *(optional)*":"",i=t.default?` \u2014 default: \`${t.default}\``:"";return o.appendMarkdown(`*${t.type}*${s}${i}`),t.description&&o.appendMarkdown(` \u2014 ${t.description}`),new De.ParameterInformation(t.name,o)}),e}function Js(n,e){let t=De.languages.registerSignatureHelpProvider(cl,{provideSignatureHelp(o,s){let i=o.getText(),a=dl.getFunctionCallContext(i,s.line,s.character);if(!a)return;let{functionName:r,paramIndex:l}=a,c;if(c=e.getFunction(r),!c&&r.includes(":")){let v=r.lastIndexOf(":"),m=r.slice(v+1);for(let h of e.getAllFunctions())if(h.isMethod&&h.name===m){c=h;break}}if(c||(c=e.getLuaStdlib("luajit").find(m=>m.fullPath===r)),!c||c.parameters.length===0)return;let d=ul(c),u=new De.SignatureHelp;return u.signatures=[d],u.activeSignature=0,u.activeParameter=Math.min(l,c.parameters.length-1),u}},"(",",");n.subscriptions.push(t)}var Z=E(require("vscode")),Lt=E(require("path"));var ml={scheme:"file",language:"lua"},fl=new G,Zs="lurek-api",Qs=new Map;function gl(n){let e=n.uri.toString(),t=Qs.get(e);if(t&&t.version===n.version)return t.info;let o=fl.analyze(n.getText());return Qs.set(e,{version:n.version,info:o}),o}var So=class{constructor(e){this.apiData=e}provideTextDocumentContent(e){let t=e.path.replace(/^\//,""),o=this.apiData.getFunction(t);if(o)return this.renderFunction(o);let s=t.replace("lurek.",""),i=this.apiData.getModule(s);return i?this.renderModule(i):`-- No API definition found for: ${t}`}renderFunction(e){let t=[];if(t.push("-- Lurek2D API Definition"),t.push(`-- ${e.fullPath}`),t.push("--"),e.description&&(t.push(`-- ${e.description}`),t.push("--")),e.parameters.length>0){t.push("-- Parameters:");for(let s of e.parameters){let i=s.optional?" (optional)":"",a=s.default?` [default: ${s.default}]`:"",r=s.description?` -- ${s.description}`:"";t.push(`--   ${s.name}: ${s.type}${i}${a}${r}`)}t.push("--")}e.returns&&(t.push(`-- Returns: ${e.returns}`),t.push("--")),e.deprecated&&(t.push(`-- DEPRECATED: ${e.deprecated}`),t.push("--")),e.sourceFile&&t.push(`-- Source: ${e.sourceFile}`),t.push("");let o=e.parameters.map(s=>s.name).join(", ");return e.isMethod?t.push(`function ${e.objectType??"Object"}:${e.name}(${o})`):t.push(`function ${e.fullPath}(${o})`),t.push("  -- Implemented in Rust (native)"),t.push("end"),t.join(`
`)}renderModule(e){let t=[];t.push(`-- Lurek2D API Module: ${e.fullPath}`),e.description&&t.push(`-- ${e.description}`),t.push(`-- ${e.functions.length} functions, ${e.methods.length} methods`),t.push(""),t.push(`${e.name} = {}`),t.push("");for(let o of e.functions){let s=o.parameters.map(i=>i.name).join(", ");o.description&&t.push(`--- ${o.description}`),t.push(`function ${o.fullPath}(${s}) end`),t.push("")}for(let o of e.methods){let s=o.parameters.map(i=>i.name).join(", ");o.description&&t.push(`--- ${o.description}`),t.push(`function ${o.objectType??"Object"}:${o.name}(${s}) end`),t.push("")}return t.join(`
`)}};async function hl(n,e){let t=e.replace(/\./g,"/"),o=[t+".lua",t+"/init.lua"],s=Lt.dirname(n.uri.fsPath);for(let i of o){let a=Z.Uri.file(Lt.resolve(s,i));try{return await Z.workspace.fs.stat(a),new Z.Location(a,new Z.Position(0,0))}catch{}let r=Z.workspace.workspaceFolders?.[0]?.uri.fsPath;if(r){let c=Z.Uri.file(Lt.resolve(r,i));try{return await Z.workspace.fs.stat(c),new Z.Location(c,new Z.Position(0,0))}catch{}}let l=await Z.workspace.findFiles(`**/${i}`,"**/node_modules/**",1);if(l.length>0)return new Z.Location(l[0],new Z.Position(0,0))}}function vl(n,e,t){try{let a=gl(n),r;for(let l of a.symbols)l.name===e&&l.kind!=="parameter"&&(l.line>t||(!r||l.line>r.line)&&(r=l));if(r)return new Z.Location(n.uri,new Z.Position(r.line,r.column))}catch{}let o=n.getText(),s=e.replace(/[.*+?^${}()|[\]\\]/g,"\\$&"),i=[new RegExp(`\\blocal\\s+function\\s+${s}\\s*\\(`),new RegExp(`^function\\s+${s}\\s*\\(`,"m"),new RegExp(`\\blocal\\s+${s}\\s*=\\s*function\\s*\\(`),new RegExp(`\\blocal\\s+${s}\\s*=`),new RegExp(`^${s}\\s*=\\s*\\{`,"m")];for(let a of i){let r=a.exec(o);if(r){let l=n.positionAt(r.index);return new Z.Location(n.uri,l)}}}function ei(n,e){let t=new So(e);n.subscriptions.push(Z.workspace.registerTextDocumentContentProvider(Zs,t));let o=Z.languages.registerDefinitionProvider(ml,{async provideDefinition(s,i){let a=s.lineAt(i).text,r=a.match(/require\s*\(\s*["']([^"']+)["']\s*\)/);if(r){let v=r[1],m=a.indexOf(v),h=m+v.length;if(i.character>=m&&i.character<=h)return hl(s,v)}let l=s.getWordRangeAtPosition(i,/lurek\.\w+\.\w+/);if(l){let v=s.getText(l);if(e.getFunction(v)){let h=Z.Uri.parse(`${Zs}:/${v}`);return new Z.Location(h,new Z.Position(0,0))}}let c=s.getWordRangeAtPosition(i,/\w+/);if(!c)return;let d=s.getText(c),u=a.substring(0,c.start.character);if(!(u.endsWith("lurek.")||u.match(/lurek\.\w+\.$/)))return vl(s,d,i.line)}});n.subscriptions.push(o)}var _e=E(require("vscode"));var bl={scheme:"file",language:"lua"},xl=new G;function ti(n,e){let t=_e.languages.registerReferenceProvider(bl,{async provideReferences(o,s,i){let a=o.getWordRangeAtPosition(s,/[\w.]+/);if(!a)return[];let r=o.getText(a);if(!r||r.length<2)return[];let l=(r.includes("."),r),c=[],d=await _e.workspace.findFiles("**/*.lua","**/node_modules/**",500);for(let u of d)try{let v=await _e.workspace.openTextDocument(u),m=v.getText(),h=xl.findReferencesInDocument(m,l);for(let y of h)c.push(new _e.Location(u,new _e.Position(y.line,y.column)));if(l.includes(".")){let y=l.replace(/[.*+?^${}()|[\]\\]/g,"\\$&"),p=new RegExp(y,"g"),g;for(;(g=p.exec(m))!==null;){let f=v.positionAt(g.index);c.some(x=>x.uri.fsPath===u.fsPath&&x.range.start.line===f.line&&x.range.start.character===f.character)||c.push(new _e.Location(u,f))}}}catch{}return c}});n.subscriptions.push(t)}var B=E(require("vscode"));var kl={scheme:"file",language:"lua"},oi=new G,Sl=new Set(["load","update","draw","keypressed","keyreleased","textinput","mousepressed","mousereleased","wheelmoved","gamepadpressed","gamepadreleased","gamepadaxis","joystickadded","joystickremoved","touchpressed","touchmoved","touchreleased","focus","visible","resize","quit"]),ni=new Map;function El(n){let e=n.uri.toString(),t=ni.get(e);if(t&&t.version===n.version)return t.info;let o=oi.analyze(n.getText());return ni.set(e,{version:n.version,info:o}),o}function ht(n,e){let t=0,o=!1;for(let s=e;s<n.length;s++){let i=n[s].replace(/--.*$/,"").trim(),a=(i.match(/\b(function|if|for|while|repeat|do)\b/g)||[]).length,r=(i.match(/\bend\b/g)||[]).length,l=(i.match(/\buntil\b/g)||[]).length;if(t+=a-r-l,a>0&&(o=!0),o&&t<=0)return new B.Range(e,0,s,n[s].length)}return new B.Range(e,0,e,n[e]?.length??0)}function si(n,e){let t=B.languages.registerDocumentSymbolProvider(kl,{provideDocumentSymbols(s){let i=[],r=s.getText().split(`
`);try{let l=El(s),c=new Map;for(let d of l.requires){let u=r[d.line]?.length??0,v=new B.Range(d.line,0,d.line,u);i.push(new B.DocumentSymbol(d.localName,`require("${d.modulePath}")`,B.SymbolKind.Module,v,v))}for(let d of l.symbols){if(d.kind==="parameter")continue;let u=r[d.line]?.length??0,v=new B.Range(d.line,d.column,d.line,d.column+d.name.length);if(d.kind==="function"){let m=d.endLine!==void 0?new B.Range(d.line,0,d.endLine,r[d.endLine]?.length??0):ht(r,d.line),h=l.callbacks.some(b=>b.name===d.name&&b.line===d.line),y=h?B.SymbolKind.Event:B.SymbolKind.Function,p=h?"callback":d.isLocal?"local function":"function",g=h?`lurek.${d.name}`:d.name,f=new B.DocumentSymbol(g,p,y,m,v);d.scope&&c.has(d.scope)?c.get(d.scope).children.push(f):i.push(f)}else if(d.kind==="method"){let m=d.endLine!==void 0?new B.Range(d.line,0,d.endLine,r[d.endLine]?.length??0):ht(r,d.line),h=d.type?`${d.type}:${d.name}`:d.name,y=new B.DocumentSymbol(h,"method",B.SymbolKind.Method,m,v);d.type&&c.has(d.type)?c.get(d.type).children.push(y):i.push(y)}else if(d.kind==="table"){let m=new B.Range(d.line,0,d.line,u),h=new B.DocumentSymbol(d.name,"table",B.SymbolKind.Object,m,v);c.set(d.name,h),i.push(h)}else if(d.kind==="local"||d.kind==="global"){let m=/^[A-Z_][A-Z0-9_]*$/.test(d.name),h=new B.Range(d.line,0,d.line,u),y=m?B.SymbolKind.Constant:B.SymbolKind.Variable,p=d.isLocal?"local":"global";(!d.isLocal||m||!d.scope)&&i.push(new B.DocumentSymbol(d.name,p,y,h,v))}}}catch{return Cl(r)}return i}}),o=B.languages.registerWorkspaceSymbolProvider({async provideWorkspaceSymbols(s){if(s.length<2)return[];let i=s.toLowerCase(),a=[],r=await B.workspace.findFiles("**/*.lua","**/node_modules/**",100);for(let l of r)try{let c=await B.workspace.openTextDocument(l),d=oi.analyze(c.getText());for(let u of d.symbols){if(u.kind==="parameter"||!u.name.toLowerCase().includes(i))continue;let v=u.kind==="function"||u.kind==="method"?B.SymbolKind.Function:u.kind==="table"?B.SymbolKind.Object:B.SymbolKind.Variable,m=new B.Location(l,new B.Position(u.line,u.column));a.push(new B.SymbolInformation(u.name,v,u.scope??"",m))}}catch{}return a}});n.subscriptions.push(t,o)}function Cl(n){let e=[];for(let t=0;t<n.length;t++){let o=n[t],s=o.match(/^\s*function\s+(lurek\.\w+)\s*\(/);if(s){let c=s[1],d=ht(n,t),u=new B.Range(t,0,t,o.length),v=c.replace("lurek.",""),m=Sl.has(v)?B.SymbolKind.Event:B.SymbolKind.Function;e.push(new B.DocumentSymbol(c,"callback",m,d,u));continue}let i=o.match(/^\s*function\s+(\w[\w.:]*)\s*\(/);if(i){let c=i[1],d=ht(n,t),u=new B.Range(t,0,t,o.length);e.push(new B.DocumentSymbol(c,"function",B.SymbolKind.Function,d,u));continue}let a=o.match(/^\s*local\s+function\s+(\w+)\s*\(/);if(a){let c=a[1],d=ht(n,t),u=new B.Range(t,0,t,o.length);e.push(new B.DocumentSymbol(c,"local function",B.SymbolKind.Function,d,u));continue}let r=o.match(/^\s*local\s+(\w+)\s*=\s*function\s*\(/);if(r){let c=r[1],d=ht(n,t),u=new B.Range(t,0,t,o.length);e.push(new B.DocumentSymbol(c,"local function",B.SymbolKind.Function,d,u));continue}let l=o.match(/^\s*local\s+(\w+)\s*=\s*require\s*\(\s*["']([^"']+)["']\s*\)/);if(l){let c=new B.Range(t,0,t,o.length);e.push(new B.DocumentSymbol(l[1],`require("${l[2]}")`,B.SymbolKind.Module,c,c));continue}}return e}var A=E(require("vscode")),ii=E(require("fs")),Ue=E(require("path"));var sn=new G;function ai(n,e){let t=A.languages.createDiagnosticCollection("lurek");n.subscriptions.push(t);let o=new Map,s=a=>{if(a.languageId==="lua")try{let r=a.getText(),l=sn.analyze(r),c=[];c.push(...Il(r,e)),c.push(...Pl(r)),c.push(...Ll(r,l)),Rl(r,a,c),c.push(...Dl(r,l)),c.push(...Ml(r,a,l)),c.push(...Bl(r,e)),c.push(...Nl(r,e)),_l(r,a,c),c.push(...$l(r,l)),c.push(...Ol(r,a)),c.push(...Wl(r)),c.push(...Hl(r)),t.set(a.uri,c)}catch{}},i=a=>{let r=a.uri.toString(),l=o.get(r);l&&clearTimeout(l),o.set(r,setTimeout(()=>{o.delete(r),s(a)},300))};n.subscriptions.push(A.workspace.onDidOpenTextDocument(s),A.workspace.onDidSaveTextDocument(s),A.workspace.onDidChangeTextDocument(a=>i(a.document)),A.workspace.onDidCloseTextDocument(a=>{t.delete(a.uri);let r=a.uri.toString(),l=o.get(r);l&&(clearTimeout(l),o.delete(r))}));for(let a of A.workspace.textDocuments)s(a)}function Il(n,e){let t=[],o=e.getAllFunctions().filter(i=>i.deprecated);if(o.length===0)return t;let s=n.split(`
`);for(let i of o){let a=i.fullPath.replace(/\./g,"\\."),r=new RegExp(a,"g");for(let l=0;l<s.length;l++){let c=s[l];if(c.trimStart().startsWith("--"))continue;let d;for(;(d=r.exec(c))!==null;){let u=new A.Range(l,d.index,l,d.index+i.fullPath.length),v=new A.Diagnostic(u,`${i.fullPath} is deprecated. ${i.deprecated}`,A.DiagnosticSeverity.Warning);v.code="lurek.deprecated",v.source="Lurek2D Toolkit",v.tags=[A.DiagnosticTag.Deprecated],t.push(v)}}}return t}function Pl(n){let e=[],t=n.split(`
`),o=/lurek\.graphics\.(?:setColor|setBackgroundColor|clear)\s*\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)/g;for(let s=0;s<t.length;s++){let i=t[s];if(i.trimStart().startsWith("--"))continue;let a;for(;(a=o.exec(i))!==null;){let r=[parseFloat(a[1]),parseFloat(a[2]),parseFloat(a[3])];if(a[4]!==void 0&&r.push(parseFloat(a[4])),!r.some(v=>v>1))continue;let c=r.slice(0,3).map(v=>(v/255).toFixed(2)),d=new A.Range(s,a.index,s,a.index+a[0].length),u=new A.Diagnostic(d,`Color values should be in 0-1 range. Did you mean ${c.join(", ")}?`,A.DiagnosticSeverity.Warning);u.code="lurek.colorRange",u.source="Lurek2D Toolkit",e.push(u)}}return e}function Ll(n,e){let t=[];for(let o of e.requires){let s=o.localName;if(sn.findReferencesInDocument(n,s).length<=1){let a=n.split(`
`),r=o.line,l=a[r]??"",c=new A.Range(r,0,r,l.length),d=new A.Diagnostic(c,`Required module '${s}' is never used`,A.DiagnosticSeverity.Hint);d.code="lurek.unusedRequire",d.source="Lurek2D Toolkit",d.tags=[A.DiagnosticTag.Unnecessary],t.push(d)}}return t}function Rl(n,e,t){if(!A.workspace.workspaceFolders?.length)return;let o=n.split(`
`),s=/lurek\.(?:graphics\.newImage|audio\.newSource|filesystem\.read)\s*\(\s*["']([^"']+)["']/g,i=Ue.dirname(e.uri.fsPath),a=A.workspace.workspaceFolders[0].uri.fsPath;for(let r=0;r<o.length;r++){let l=o[r];if(l.trimStart().startsWith("--"))continue;let c;for(;(c=s.exec(l))!==null;){let d=c[1];if(d.includes("://")||!d.includes("."))continue;if(![Ue.resolve(i,d),Ue.resolve(a,d)].some(m=>{try{return ii.existsSync(m)}catch{return!1}})){let m=l.indexOf(d,c.index),h=new A.Range(r,m,r,m+d.length),y=new A.Diagnostic(h,`Asset file '${d}' not found in workspace`,A.DiagnosticSeverity.Warning);y.code="lurek.assetNotFound",y.source="Lurek2D Toolkit",t.push(y)}}}}function Dl(n,e){let t=[];if(!n.includes("lurek.thread"))return t;let o=n.split(`
`),s=/\bmath\.random\s*\(/g;for(let i=0;i<o.length;i++){let a=o[i];if(a.trimStart().startsWith("--"))continue;let r;for(;(r=s.exec(a))!==null;){let l=sn.getScopeAt(e,i);if(!l||!o.slice(l.startLine,l.endLine+1).join(`
`).includes("lurek.thread"))continue;let d=new A.Range(i,r.index,i,r.index+11),u=new A.Diagnostic(d,"math.random in threads may produce identical sequences. Consider seeding with thread ID.",A.DiagnosticSeverity.Information);u.code="lurek.threadRandom",u.source="Lurek2D Toolkit",t.push(u)}}return t}function Ml(n,e,t){let o=[];if(Ue.basename(e.uri.fsPath)!=="main.lua")return o;let i=t.callbacks.some(r=>r.name==="update")||/lurek\.update\s*=\s*function/.test(n),a=t.callbacks.some(r=>r.name==="draw")||/lurek\.draw\s*=\s*function/.test(n);if(!i&&!a){let r=n.split(`
`),l=new A.Range(0,0,0,r[0]?.length??0),c=new A.Diagnostic(l,"main.lua should define lurek.update(dt) and/or lurek.draw()",A.DiagnosticSeverity.Information);c.code="lurek.missingCallback",c.source="Lurek2D Toolkit",o.push(c)}return o}var Al=[{pattern:/lurek\.graphics\.(?:rectangle|circle|arc|polygon|ellipse)\s*\(\s*["']([^"']+)["']/g,valid:["fill","line"],label:"draw mode"},{pattern:/lurek\.graphics\.setBlendMode\s*\(\s*["']([^"']+)["']/g,valid:["alpha","add","subtract","multiply","replace","screen","darken","lighten","none"],label:"blend mode"},{pattern:/lurek\.graphics\.setLineStyle\s*\(\s*["']([^"']+)["']/g,valid:["smooth","rough"],label:"line style"},{pattern:/lurek\.graphics\.setFilter\s*\([^,]*,\s*["']([^"']+)["']/g,valid:["linear","nearest"],label:"texture filter"},{pattern:/lurek\.graphics\.setFilter\s*\(\s*["']([^"']+)["']/g,valid:["linear","nearest"],label:"texture filter"},{pattern:/lurek\.audio\.newSource\s*\([^,]*,\s*["']([^"']+)["']/g,valid:["static","stream"],label:"audio source type"},{pattern:/lurek\.physics\.newBody\s*\([^,]*,[^,]*,[^,]*,\s*["']([^"']+)["']/g,valid:["dynamic","static","kinematic"],label:"body type"},{pattern:/lurek\.graphics\.printf\s*\([^)]*,[^)]*,[^)]*,[^)]*,\s*["']([^"']+)["']/g,valid:["left","center","right","justify"],label:"text alignment"}];function Fl(n,e){for(let t of e){if(t===n)return;if(Math.abs(t.length-n.length)<=2){let o=0,s=Math.max(t.length,n.length);for(let i=0;i<s;i++)(t[i]??"")!==(n[i]??"")&&o++;if(o<=2)return t}}}function Bl(n,e){let t=[],o=n.split(`
`);for(let s of Al)for(let i=0;i<o.length;i++){let a=o[i];if(a.trimStart().startsWith("--"))continue;s.pattern.lastIndex=0;let r;for(;(r=s.pattern.exec(a))!==null;){let l=r[1];if(s.valid.includes(l))continue;let c=Fl(l,s.valid),d=a.indexOf(`"${l}"`,r.index)!==-1?a.indexOf(`"${l}"`,r.index)+1:a.indexOf(`'${l}'`,r.index)+1,u=new A.Range(i,d,i,d+l.length),v=c?`Unknown ${s.label} "${l}". Did you mean "${c}"? Valid: ${s.valid.join(", ")}`:`Unknown ${s.label} "${l}". Valid values: ${s.valid.join(", ")}`,m=new A.Diagnostic(u,v,A.DiagnosticSeverity.Warning);m.code="lurek.wrongEnumValue",m.source="Lurek2D Toolkit",t.push(m)}}return t}function Nl(n,e){let t=[],o=n.split(`
`),s=/lurek\.(\w+)\.(\w+)\s*\(/g;for(let i=0;i<o.length;i++){let a=o[i];if(a.trimStart().startsWith("--"))continue;s.lastIndex=0;let r;for(;(r=s.exec(a))!==null;){let l=r[1],c=r[2],d=`lurek.${l}.${c}`;if(!e.getModule(l)||e.getFunction(d)||e.getFunctions(l).find(g=>g.name===c))continue;let h=r.index+`lurek.${l}.`.length,y=new A.Range(i,h,i,h+c.length),p=new A.Diagnostic(y,`"${c}" is not a known function in lurek.${l}`,A.DiagnosticSeverity.Warning);p.code="lurek.unknownFunction",p.source="Lurek2D Toolkit",t.push(p)}}return t}var zl={window:["title","width","height","vsync","fullscreen","resizable","highdpi","minwidth","minheight","x","y","borderless","displayindex","icon"],performance:["target_fps","fixed_dt"],modules:["physics","audio","graphics","input","timer","filesystem","math","thread"],log:["file","append","level"]};function _l(n,e,t){if(Ue.basename(e.uri.fsPath)!=="conf.lua")return;let o=n.split(`
`),s=/\bt\.(\w+)\.(\w+)\s*=/g;for(let i=0;i<o.length;i++){let a=o[i];if(a.trimStart().startsWith("--"))continue;s.lastIndex=0;let r;for(;(r=s.exec(a))!==null;){let l=r[1],c=r[2],d=zl[l];if(!d||d.includes(c))continue;let u=r.index+`t.${l}.`.length,v=new A.Range(i,u,i,u+c.length),m=new A.Diagnostic(v,`"${c}" is not a recognised conf.lua key in t.${l}. Valid: ${d.join(", ")}`,A.DiagnosticSeverity.Warning);m.code="lurek.confKey",m.source="Lurek2D Toolkit",t.push(m)}}}function $l(n,e){let t=[],o=n.split(`
`),s=/lurek\.(?:graphics\.(?:newImage|newFont|newCanvas|newShader|newSpriteBatch|newMesh)|audio\.(?:newSource)|image\.load)\s*\(/g,i=["update","draw","render","render_ui","process","process_late","process_physics"];for(let a=0;a<o.length;a++){let r=o[a];if(r.trimStart().startsWith("--"))continue;s.lastIndex=0;let l;for(;(l=s.exec(r))!==null;){let c=sn.getScopeAt(e,a);if(!c||!i.some(h=>{let y=o.slice(c.startLine,Math.min(c.startLine+3,o.length)).join(`
`);return y.includes(`lurek.${h}`)||y.includes(`function ${h}`)}))continue;let u=l[0].replace(/\s*\($/,""),v=new A.Range(a,l.index,a,l.index+u.length),m=new A.Diagnostic(v,`${u} called inside a per-frame callback. This allocates every frame \u2014 move to lurek.init() or lurek.ready().`,A.DiagnosticSeverity.Warning);m.code="lurek.perFrameAlloc",m.source="Lurek2D Toolkit",t.push(m)}}return t}function Ol(n,e){let t=[],o=e.uri.fsPath.replace(/\\/g,"/");if(!o.includes("tests/lua/")&&!o.includes("tests\\lua\\")||!o.endsWith(".lua")||o.endsWith("init.lua"))return t;if(!/\btest_summary\s*\(\s*\)/.test(n)){let i=n.split(`
`),a=i.length-1,r=new A.Range(a,0,a,i[a]?.length??0),l=new A.Diagnostic(r,"Lua test file is missing test_summary() call at the end. Required by the Lurek2D test harness.",A.DiagnosticSeverity.Warning);l.code="lurek.missingTestSummary",l.source="Lurek2D Toolkit",t.push(l)}return t}function Wl(n){let e=[],t=n.split(`
`),o=/\blocal\s+(\w+)\s*=\s*lurek\.entity\.find\s*\(/g;for(let s=0;s<t.length;s++){let i=t[s];if(i.trimStart().startsWith("--"))continue;o.lastIndex=0;let a;for(;(a=o.exec(i))!==null;){let r=a[1],l=!1;for(let c=s+1;c<Math.min(s+6,t.length);c++){let d=t[c].trim();if(d.startsWith("--"))continue;if(d.includes(`if ${r}`)||d.includes(`if not ${r}`)){l=!0;break}if(new RegExp(`\\b${r}\\s*[:.:]\\s*\\w+`).test(d)&&!l){let v=d.indexOf(r),m=new A.Range(c,v,c,v+r.length),h=new A.Diagnostic(m,`'${r}' from lurek.entity.find() may be nil. Consider adding: if ${r} then`,A.DiagnosticSeverity.Information);h.code="lurek.entityNilAccess",h.source="Lurek2D Toolkit",e.push(h);break}}}}return e}function Hl(n){let e=[],t=n.split(`
`),o=/\b(\w+)\.(\w+)\s*\(\s*\1\s*[,)]/g;for(let s=0;s<t.length;s++){let i=t[s];if(i.trimStart().startsWith("--"))continue;o.lastIndex=0;let a;for(;(a=o.exec(i))!==null;){let r=a[1],l=a[2];if(r==="lurek")continue;let c=a.index,d=c+`${r}.${l}`.length,u=new A.Range(s,c,s,d),v=new A.Diagnostic(u,`Consider using colon syntax: ${r}:${l}(...) instead of ${r}.${l}(${r}, ...)`,A.DiagnosticSeverity.Information);v.code="lurek.colonSyntax",v.source="Lurek2D Toolkit",e.push(v)}}return e}var he=E(require("vscode")),ql={scheme:"file",language:"lua"},Yl=["setColor","setBackgroundColor","clear","newColor"];function ri(n,e){let t=he.languages.registerColorProvider(ql,{provideDocumentColors(o){try{return Vl(o)}catch{return[]}},provideColorPresentations(o,s){try{return Xl(o,s)}catch{return[]}}});n.subscriptions.push(t)}var Gl=new RegExp(`lurek\\.graphics\\.(?:${Yl.join("|")})\\s*\\(\\s*([\\d.]+)\\s*,\\s*([\\d.]+)\\s*,\\s*([\\d.]+)(?:\\s*,\\s*([\\d.]+))?\\s*\\)`,"g");function Vl(n){let e=[],t=n.getText(),o=new RegExp(Gl.source,"g"),s;for(;(s=o.exec(t))!==null;){let i=parseFloat(s[1]),a=parseFloat(s[2]),r=parseFloat(s[3]),l=s[4]!==void 0?parseFloat(s[4]):1;if(i>1||a>1||r>1||l>1)continue;let c=s[0],d=c.indexOf("(")+1,u=c.lastIndexOf(")"),v=s.index+d,m=u-d,h=n.positionAt(v),y=n.positionAt(v+m),p=new he.Range(h,y);e.push(new he.ColorInformation(p,new he.Color(i,a,r,l)))}return e}function Xl(n,e){let t=an(n.red),o=an(n.green),s=an(n.blue),i=an(n.alpha),a=[],r=new he.ColorPresentation(`${t}, ${o}, ${s}, ${i}`);if(r.textEdit=new he.TextEdit(e.range,`${t}, ${o}, ${s}, ${i}`),a.push(r),Math.abs(n.alpha-1)<.005){let v=new he.ColorPresentation(`${t}, ${o}, ${s}`);v.textEdit=new he.TextEdit(e.range,`${t}, ${o}, ${s}`),a.push(v)}let l=Math.round(n.red*255).toString(16).padStart(2,"0"),c=Math.round(n.green*255).toString(16).padStart(2,"0"),d=Math.round(n.blue*255).toString(16).padStart(2,"0"),u=new he.ColorPresentation(`${t}, ${o}, ${s} --[[ #${l}${c}${d} ]]`);return u.textEdit=new he.TextEdit(e.range,`${t}, ${o}, ${s} --[[ #${l}${c}${d} ]]`),a.push(u),a}function an(n){return n.toFixed(2).replace(/\.?0+$/,"")||"0"}var Se=E(require("vscode")),lt=E(require("path"));var Kl={scheme:"file",language:"lua"},Mu=new G,li={"lurek.graphics.newImage":[".png",".jpg",".jpeg",".bmp",".gif"],"lurek.audio.newSource":[".ogg",".wav",".mp3",".flac"],"lurek.filesystem.read":[],"lurek.filesystem.write":[],"lurek.filesystem.exists":[]},Jl=[".lua"];function ci(n,e){let t=Se.languages.registerCompletionItemProvider(Kl,{async provideCompletionItems(o,s){try{return await Zl(o,s)}catch{return}}},'"',"'","/");n.subscriptions.push(t)}async function Zl(n,e){let o=n.lineAt(e).text.substring(0,e.character),s=o.match(/(lurek\.\w+\.\w+)\s*\(\s*["']([^"']*)$/),i=o.match(/require\s*\(\s*["']([^"']*)$/);if(!s&&!i)return;let a=s?s[1]:"require",r=s?s[2]:i[1],l=[];if(a==="require")l=Jl;else if(a in li)l=li[a];else return;let c=Se.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!c)return;let d=r.includes("/")?lt.dirname(r):"",u=d?`${d}/**/*`:"**/*",v=await Se.workspace.findFiles(u,"**/node_modules/**",200),m=[],h=new Set;for(let y of v){let p=lt.extname(y.fsPath).toLowerCase();if(l.length>0&&!l.includes(p))continue;let g=lt.relative(c,y.fsPath).replace(/\\/g,"/");if(a==="require"){let k=g.replace(/\.lua$/,"").replace(/\//g,"."),L=new Se.CompletionItem(k,Se.CompletionItemKind.Module);L.detail="Lua module",L.insertText=k;let _=k.split(".").length;L.sortText=String(_).padStart(3,"0")+k,m.push(L);continue}let f=lt.dirname(g);if(f!=="."&&!h.has(f)&&(h.add(f),!r||f.startsWith(r.split("/")[0]))){let k=new Se.CompletionItem(f+"/",Se.CompletionItemKind.Folder);k.sortText="0"+f,m.push(k)}let b=new Se.CompletionItem(g,Se.CompletionItemKind.File);b.detail=p.toUpperCase().substring(1)+" file",b.insertText=g;let x=g.split("/").length;b.sortText=String(x).padStart(3,"0")+g,m.push(b)}return m}var Ke=E(require("vscode"));var ec={scheme:"file",language:"lua"},Fu=new G;function di(n,e){let t=Ke.languages.registerInlayHintsProvider(ec,{provideInlayHints(o,s){try{return Ke.workspace.getConfiguration("lurek").get("inlayHints.enabled")===!1?[]:tc(o,s,e)}catch{return[]}}});n.subscriptions.push(t)}function tc(n,e,t){let o=[],s=n.getText(e),i=n.offsetAt(e.start),a=/(lurek\.\w+\.\w+)\s*\(/g,r;for(;(r=a.exec(s))!==null;){let l=r[1],c=t.getFunction(l);if(!c||c.parameters.length===0)continue;let d=r.index+r[0].length-1,u=nc(s,d);if(!u)continue;let v=oc(u);if(v.length<=1)continue;let h=i+d+1;for(let y=0;y<v.length&&y<c.parameters.length;y++){let p=v[y],g=p.trimStart(),f=p.length-g.length;if(/^\w+\s*=/.test(g)){h+=p.length+1;continue}let b=c.parameters[y];if(g===b.name){h+=p.length+1;continue}if(sc(g,b.name)){h+=p.length+1;continue}let x=n.positionAt(h+f),k=new Ke.InlayHint(x,`${b.name}:`,Ke.InlayHintKind.Parameter);k.paddingRight=!0,o.push(k),h+=p.length+1}}return o}function nc(n,e){if(n[e]!=="(")return;let t=1,o=e+1;for(;o<n.length&&t>0;){let s=n[o];s==="("?t++:s===")"&&t--,o++}if(t===0)return n.slice(e+1,o-1)}function oc(n){if(!n.trim())return[];let e=[],t="",o=0,s=null;for(let i=0;i<n.length;i++){let a=n[i];if(s&&a==="\\"){t+=a,i+1<n.length&&(t+=n[i+1],i++);continue}if(!s&&(a==='"'||a==="'")){s=a,t+=a;continue}if(s&&a===s){s=null,t+=a;continue}if(s){t+=a;continue}a==="("||a==="{"||a==="["?(o++,t+=a):a===")"||a==="}"||a==="]"?(o--,t+=a):a===","&&o===0?(e.push(t),t=""):t+=a}return t&&e.push(t),e}function sc(n,e){return(n==="true"||n==="false"||n==="nil")&&e.length<=4}var N=E(require("vscode"));var ac={scheme:"file",language:"lua"},Nu=new G;function ui(n,e){let t=N.languages.registerCodeActionsProvider(ac,{provideCodeActions(o,s,i){try{return rc(o,s,i)}catch{return[]}}},{providedCodeActionKinds:[N.CodeActionKind.QuickFix,N.CodeActionKind.RefactorExtract]});n.subscriptions.push(t)}function rc(n,e,t){let o=[];for(let l of t.diagnostics)switch(l.code){case"lurek.unusedRequire":o.push(...lc(n,l));break;case"lurek.missingCallback":o.push(...cc(n,l));break;case"lurek.colorRange":o.push(...dc(n,l));break}let s=n.lineAt(e.start.line).text;e.isEmpty||(o.push(uc(n,e)),o.push(fc(n,e)));let i=s.match(/^(\s*)(\w+)\s*=\s*(.+)/);i&&!s.trimStart().startsWith("local ")&&!s.trimStart().startsWith("function ")&&!s.trimStart().startsWith("--")&&!s.includes("lurek.")&&!s.includes(".")&&!s.includes(":")&&o.push(pc(n,e.start.line,i)),/\brequire\s*\(/.test(s)&&!/pcall/.test(s)&&o.push(mc(n,e.start.line));let a=s.match(/^(\s*)local\s+(\w+)\s*=\s*(.+)/);if(a&&!e.isEmpty&&o.push(gc(n,e.start.line,a)),/^\s*if\s+/.test(s)){let l=hc(n,e.start.line);l&&o.push(l)}let r=s.match(/^(\s*)local\s+(\w+)\s*=/);if(r&&!s.includes("---@type")&&o.push(vc(n,e.start.line,r[2])),/(\w+)\.__index\s*=\s*\1/.test(s)||/setmetatable\s*\(\s*{/.test(s)){let l=s.match(/(\w+)\.__index/)?.[1];l&&o.push(yc(n,e.start.line,l))}return o}function lc(n,e){let t=new N.CodeAction("Remove unused require",N.CodeActionKind.QuickFix);t.edit=new N.WorkspaceEdit;let o=e.range.start.line,s=new N.Range(o,0,o+1,0);return t.edit.delete(n.uri,s),t.diagnostics=[e],t.isPreferred=!0,[t]}function cc(n,e){let t=n.getText(),o=[];if(!/function\s+lurek\.load\s*\(/.test(t)&&!/lurek\.load\s*=\s*function/.test(t)&&o.push("load"),!/function\s+lurek\.update\s*\(/.test(t)&&!/lurek\.update\s*=\s*function/.test(t)&&o.push("update"),!/function\s+lurek\.draw\s*\(/.test(t)&&!/lurek\.draw\s*=\s*function/.test(t)&&o.push("draw"),o.length===0)return[];let s=new N.CodeAction("Generate Lurek2D callbacks",N.CodeActionKind.QuickFix);s.edit=new N.WorkspaceEdit;let i=[];o.includes("load")&&i.push(`function lurek.load()
    -- Initialize game
end`),o.includes("update")&&i.push(`function lurek.update(dt)
    -- Update game logic
end`),o.includes("draw")&&i.push(`function lurek.draw()
    -- Draw game objects
end`);let a=n.lineAt(n.lineCount-1).range.end;return s.edit.insert(n.uri,a,`

`+i.join(`

`)+`
`),s.diagnostics=[e],[s]}function dc(n,e){let o=n.getText(e.range).match(/(lurek\.graphics\.(?:setColor|setBackgroundColor|clear))\s*\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)/);if(!o)return[];let s=o[1],i=u=>(parseFloat(u)/255).toFixed(2).replace(/\.?0+$/,"")||"0",a=i(o[2]),r=i(o[3]),l=i(o[4]),c;if(o[5]!==void 0){let u=i(o[5]);c=`${s}(${a}, ${r}, ${l}, ${u})`}else c=`${s}(${a}, ${r}, ${l})`;let d=new N.CodeAction("Convert to 0-1 color range",N.CodeActionKind.QuickFix);return d.edit=new N.WorkspaceEdit,d.edit.replace(n.uri,e.range,c),d.diagnostics=[e],d.isPreferred=!0,[d]}function uc(n,e){let t=new N.CodeAction("Extract to local function",N.CodeActionKind.RefactorExtract);t.edit=new N.WorkspaceEdit;let o=n.getText(e),s=n.lineAt(e.start.line).text.match(/^(\s*)/)?.[1]??"",i="extracted_function",a=o.split(`
`).map((l,c)=>c===0?l:s+"    "+l),r=`${s}local function ${i}()
${s}    ${a.join(`
`)}
${s}end

`;return t.edit.insert(n.uri,new N.Position(e.start.line,0),r),t.edit.replace(n.uri,e,`${i}()`),t}function pc(n,e,t){let o=new N.CodeAction("Convert to local variable",N.CodeActionKind.QuickFix);o.edit=new N.WorkspaceEdit;let s=n.lineAt(e).range,i=`${t[1]}local ${t[2]} = ${t[3]}`;return o.edit.replace(n.uri,s,i),o}function mc(n,e){let t=n.lineAt(e).text,o=t.match(/^(\s*)/)?.[1]??"",s=new N.CodeAction("Wrap require in pcall",N.CodeActionKind.QuickFix);s.edit=new N.WorkspaceEdit;let i=t.match(/^(\s*)local\s+(\w+)\s*=\s*require\s*\(\s*["']([^"']+)["']\s*\)/);if(i){let a=i[2],r=i[3],l=[`${o}local ok, ${a} = pcall(require, "${r}")`,`${o}if not ok then`,`${o}    error("Failed to load module: " .. tostring(${a}))`,`${o}end`].join(`
`);s.edit.replace(n.uri,n.lineAt(e).range,l)}else{let a=t.match(/require\s*\(\s*["']([^"']+)["']\s*\)/);if(a){let r=a[1],l=[`${o}local ok, module = pcall(require, "${r}")`,`${o}if not ok then`,`${o}    error("Failed to load module: " .. tostring(module))`,`${o}end`].join(`
`);s.edit.replace(n.uri,n.lineAt(e).range,l)}}return s}function fc(n,e){let t=new N.CodeAction("Extract selection to new module file",N.CodeActionKind.RefactorExtract);return t.command={command:"lurek.extractToModuleFile",title:"Extract to new module file",arguments:[n.uri,e]},t}function gc(n,e,t){let o=new N.CodeAction(`Inline variable '${t[2]}'`,N.CodeActionKind.RefactorInline);o.edit=new N.WorkspaceEdit;let s=t[1],i=t[3].trim();return o.edit.replace(n.uri,n.lineAt(e).range,`${s}-- TODO: inline '${t[2]}' = ${i}`),o}function hc(n,e){let t=[],o=n.lineAt(e).text.match(/if\s+(\w+)\s*==\s*['"]/)?.[1];if(!o)return;for(let u=e;u<Math.min(e+40,n.lineCount)&&(t.push(n.lineAt(u).text),n.lineAt(u).text.trimStart()!=="end");u++);let s=[],i=0;for(;i<t.length;){let u=t[i].match(/(?:if|elseif)\s+\w+\s*==\s*['"](\w+)['"]\s*then/);if(u){let v=u[1],m=[];for(i++;i<t.length&&!/(?:elseif|else|end)/.test(t[i].trimStart());)m.push(t[i].replace(/^\s{4}/,"    ")),i++;s.push({key:v,body:m.join(`
`)})}else i++}if(s.length<2)return;let a=(n.lineAt(e).text.match(/^(\s*)/)??["",""])[1],r=`${o}Handlers`,l=[`${a}local ${r} = {`,...s.map(u=>`${a}  ${u.key} = function()
${u.body}
${a}  end,`),`${a}}`,`${a}local _handler = ${r}[${o}]`,`${a}if _handler then _handler() end`],c=new N.CodeAction(`Convert if/elseif chain to state-map (${r})`,N.CodeActionKind.RefactorRewrite);c.edit=new N.WorkspaceEdit;let d=new N.Range(e,0,e+t.length-1,n.lineAt(e+t.length-1).range.end.character);return c.edit.replace(n.uri,d,l.join(`
`)),c}function vc(n,e,t){let o=new N.CodeAction(`Add ---@type annotation for '${t}'`,N.CodeActionKind.RefactorRewrite);o.edit=new N.WorkspaceEdit;let s=(n.lineAt(e).text.match(/^(\s*)/)??["",""])[1],i=new N.Position(e,0);return o.edit.insert(n.uri,i,`${s}---@type any
`),o}function yc(n,e,t){let o=new N.CodeAction(`Generate __tostring for ${t}`,N.CodeActionKind.QuickFix);o.edit=new N.WorkspaceEdit;let s=(n.lineAt(e).text.match(/^(\s*)/)??["",""])[1],i=new N.Position(e+1,0);return o.edit.insert(n.uri,i,`
${s}function ${t}:__tostring()
${s}  return "${t}()"  -- TODO: fill in fields
${s}end
`),o}var z=E(require("vscode")),pi={scheme:"file",language:"lua"},mi=[{name:"band",sig:"bit.band(a, b)",desc:"Bitwise AND"},{name:"bor",sig:"bit.bor(a, b)",desc:"Bitwise OR"},{name:"bxor",sig:"bit.bxor(a, b)",desc:"Bitwise XOR"},{name:"bnot",sig:"bit.bnot(a)",desc:"Bitwise NOT"},{name:"lshift",sig:"bit.lshift(a, n)",desc:"Left shift"},{name:"rshift",sig:"bit.rshift(a, n)",desc:"Logical right shift"},{name:"arshift",sig:"bit.arshift(a, n)",desc:"Arithmetic right shift"},{name:"tobit",sig:"bit.tobit(n)",desc:"Normalize to int32"},{name:"tohex",sig:"bit.tohex(n, [len])",desc:"Format as hex string"},{name:"rol",sig:"bit.rol(a, n)",desc:"Rotate left"},{name:"ror",sig:"bit.ror(a, n)",desc:"Rotate right"},{name:"bswap",sig:"bit.bswap(n)",desc:"Byte-swap a 32-bit integer"}],fi=[{name:"on",sig:"jit.on([func])",desc:"Enable JIT for function or globally"},{name:"off",sig:"jit.off([func])",desc:"Disable JIT (useful for debugging)"},{name:"flush",sig:"jit.flush([func])",desc:"Flush JIT cache"},{name:"status",sig:"jit.status()",desc:"Returns JIT engine status"},{name:"version",sig:"jit.version",desc:"LuaJIT version string"},{name:"version_num",sig:"jit.version_num",desc:"LuaJIT version number"},{name:"os",sig:"jit.os",desc:"Target OS name"},{name:"arch",sig:"jit.arch",desc:"Target architecture name"}],gi=[{name:"cdef",sig:"ffi.cdef(def)",desc:"Add C declarations"},{name:"new",sig:"ffi.new(ct, [init...])",desc:"Create cdata object"},{name:"cast",sig:"ffi.cast(ct, init)",desc:"Cast to ctype"},{name:"typeof",sig:"ffi.typeof(ct)",desc:"Create ctype object"},{name:"sizeof",sig:"ffi.sizeof(ct, [nelem])",desc:"Size of ctype in bytes"},{name:"string",sig:"ffi.string(ptr, [len])",desc:"Create Lua string from pointer"},{name:"copy",sig:"ffi.copy(dst, src, len)",desc:"Copy memory"},{name:"fill",sig:"ffi.fill(dst, len, [c])",desc:"Fill memory"},{name:"istype",sig:"ffi.istype(ct, obj)",desc:"Check cdata type"},{name:"load",sig:"ffi.load(name, [global])",desc:"Load dynamic library"}],xc=[{code:"lurek.perf.tableAllocHotPath",pattern:/\{\s*\}/,message:"Table allocation `{}` in hot path \u2014 consider pre-allocating or using an object pool.",severity:z.DiagnosticSeverity.Hint,hotPathOnly:!0},{code:"lurek.perf.newInHotPath",pattern:/lurek\.\w+\.new\w*\s*\(/,message:"Resource creation (lurek.*.new*) in hot path \u2014 move to lurek.load() or cache the result.",severity:z.DiagnosticSeverity.Warning,hotPathOnly:!0},{code:"lurek.perf.globalInLoop",pattern:/\bfor\b.+\bdo\b/,message:"Loop detected \u2014 ensure frequently accessed globals are cached as locals above the loop.",severity:z.DiagnosticSeverity.Hint,hotPathOnly:!1},{code:"lurek.perf.stringConcatLoop",pattern:/\.\.\s*["']/,message:"String concatenation in loop \u2014 consider table.insert + table.concat for better performance.",severity:z.DiagnosticSeverity.Hint,hotPathOnly:!0},{code:"lurek.perf.pcallHotPath",pattern:/\bpcall\s*\(/,message:"pcall in hot path adds overhead \u2014 consider error handling outside the frame loop.",severity:z.DiagnosticSeverity.Hint,hotPathOnly:!0},{code:"lurek.perf.mathFloor",pattern:/math\.floor\s*\(/,message:"Consider bit.tobit() or x%1 for faster integer conversion in LuaJIT.",severity:z.DiagnosticSeverity.Hint,hotPathOnly:!0},{code:"lurek.perf.mathRandom",pattern:/math\.random\s*\(/,message:"Use lurek.math.random() for deterministic, seedable RNG consistent across platforms.",severity:z.DiagnosticSeverity.Information,hotPathOnly:!1},{code:"lurek.perf.unpackInLoop",pattern:/\bunpack\s*\(/,message:"unpack() in hot path creates temporary values \u2014 prefer indexed access for known structures.",severity:z.DiagnosticSeverity.Hint,hotPathOnly:!0}],wc=[{code:"lurek.compat.constAttribute",pattern:/\blocal\s+\w+\s*<\s*const\s*>/,message:"Lua 5.4 `<const>` attribute is not supported in LuaJIT. Remove the attribute \u2014 LuaJIT inlines constants automatically."},{code:"lurek.compat.closeAttribute",pattern:/\blocal\s+\w+\s*<\s*close\s*>/,message:"Lua 5.4 `<close>` (to-be-closed variable) is not supported in LuaJIT. Use explicit :close() or defer via a wrapper."},{code:"lurek.compat.utf8Library",pattern:/\butf8\s*\.\s*\w+\s*\(/,message:"The `utf8` standard library is not available in LuaJIT. Use lurek.utf8.* instead or the luajit-utf8 binding."},{code:"lurek.compat.tableMove",pattern:/\btable\s*\.\s*move\s*\(/,message:"`table.move` behaviour differs between Lua 5.4 and LuaJIT. Test carefully, or use a manual loop for portability."},{code:"lurek.compat.bitwiseTilde",pattern:/(?<![=<>~])\s*~(?!\s*=)\s*(?![-\\/])/,message:"Lua 5.4 bitwise `~` (XOR / NOT) operator is not supported in LuaJIT. Use `bit.bxor(a, b)` or `bit.bnot(a)` instead."},{code:"lurek.compat.intDivOp",pattern:/\/\//,message:"Floor-division operator `//` is a LuaJIT extension that matches Lua 5.4. Behaviour is consistent \u2014 no action needed. (Hint only.)"},{code:"lurek.compat.warnLevel",pattern:/\bwarn\s*\(/,message:"`warn()` is a Lua 5.4-only function and is not available in LuaJIT. Use `print()` or `lurek.log.warn()` instead."}];function kc(n){let e=new Set,t=n.split(`
`),o=0,s=!1;for(let i=0;i<t.length;i++){let a=t[i];if(/^\s*function\s+lurek\.(update|draw)\s*\(/.test(a)&&(s=!0,o=0),s){let r=(a.match(/\b(function|do|then|repeat)\b/g)||[]).length,l=(a.match(/\b(end|until)\b/g)||[]).length;o+=r-l,e.add(i),o<=0&&i>0&&(s=!1)}}return e}function hi(n,e){let t=[],o=z.languages.registerCompletionItemProvider(pi,{provideCompletionItems(c,d){let v=c.lineAt(d).text.substring(0,d.character),m=v.match(/\bbit\.(\w*)$/);if(m){let p=m[1].toLowerCase();return mi.filter(g=>!p||g.name.toLowerCase().startsWith(p)).map(g=>{let f=new z.CompletionItem(g.name,z.CompletionItemKind.Function);return f.detail=g.sig,f.documentation=new z.MarkdownString(`**LuaJIT bit library**

${g.desc}`),f})}let h=v.match(/\bjit\.(\w*)$/);if(h){let p=h[1].toLowerCase();return fi.filter(g=>!p||g.name.toLowerCase().startsWith(p)).map(g=>{let f=g.sig.includes("(")?z.CompletionItemKind.Function:z.CompletionItemKind.Property,b=new z.CompletionItem(g.name,f);return b.detail=g.sig,b.documentation=new z.MarkdownString(`**LuaJIT jit library**

${g.desc}`),b})}let y=v.match(/\bffi\.(\w*)$/);if(y){let p=y[1].toLowerCase();return gi.filter(g=>!p||g.name.toLowerCase().startsWith(p)).map(g=>{let f=new z.CompletionItem(g.name,z.CompletionItemKind.Function);return f.detail=g.sig,f.documentation=new z.MarkdownString(`**LuaJIT FFI library**

${g.desc}`),f})}}},".");t.push(o);let s=z.languages.registerHoverProvider(pi,{provideHover(c,d){let u=[[/bit\.\w+/,"LuaJIT bit library",mi],[/jit\.\w+/,"LuaJIT jit library",fi],[/ffi\.\w+/,"LuaJIT FFI library",gi]];for(let[v,m,h]of u){let y=c.getWordRangeAtPosition(d,v);if(!y)continue;let g=c.getText(y).split(".")[1],f=h.find(x=>x.name===g);if(!f)continue;let b=new z.MarkdownString;return b.appendCodeblock(f.sig,"lua"),b.appendMarkdown(`
**${m}**

${f.desc}
`),b.isTrusted=!0,new z.Hover(b,y)}}});t.push(s);let i=z.languages.createDiagnosticCollection("lurek.luajit");t.push(i);let a=z.languages.createDiagnosticCollection("lurek.compat");t.push(a);function r(c){if(c.languageId!=="lua")return;let d=c.getText(),u=kc(d),v=[],m=d.split(`
`);for(let h=0;h<m.length;h++){let y=m[h];if(!/^\s*--/.test(y))for(let p of xc){if(p.hotPathOnly&&!u.has(h))continue;let g=p.pattern.exec(y);if(g){let f=g.index,b=g.index+g[0].length,x=new z.Range(h,f,h,b),k=new z.Diagnostic(x,p.message,p.severity);k.code=p.code,k.source="Lurek2D LuaJIT",v.push(k)}}}i.set(c.uri,v)}function l(c){if(c.languageId!=="lua")return;let d=c.getText(),u=[],v=d.split(`
`);for(let m=0;m<v.length;m++){let h=v[m];if(/^\s*--/.test(h))continue;let y=h.replace(/--.*$/,"");for(let p of wc){let g=p.pattern.exec(y);if(g){let f=g.index,b=g.index+g[0].length,x=new z.Range(m,f,m,b),k=p.code==="lurek.compat.intDivOp"?z.DiagnosticSeverity.Hint:z.DiagnosticSeverity.Warning,L=new z.Diagnostic(x,p.message,k);L.code=p.code,L.source="Lurek2D Compat",u.push(L)}}}a.set(c.uri,u)}z.window.activeTextEditor&&(r(z.window.activeTextEditor.document),l(z.window.activeTextEditor.document)),t.push(z.window.onDidChangeActiveTextEditor(c=>{c&&(r(c.document),l(c.document))}),z.workspace.onDidChangeTextDocument(c=>{r(c.document),l(c.document)}),z.workspace.onDidCloseTextDocument(c=>{i.delete(c.uri),a.delete(c.uri)})),n.subscriptions.push(...t)}var Y=E(require("vscode")),Eo={scheme:"file",language:"lua"},vt={"lurek.graphics.newImage":{typeName:"Image",methods:[{name:"getDimensions",sig:":getDimensions()",desc:"Returns width, height"},{name:"getWidth",sig:":getWidth()",desc:"Returns pixel width"},{name:"getHeight",sig:":getHeight()",desc:"Returns pixel height"},{name:"getFilter",sig:":getFilter()",desc:"Returns min, mag filter modes"},{name:"setFilter",sig:":setFilter(min, mag)",desc:"Set texture filter"},{name:"setWrap",sig:":setWrap(horiz, vert)",desc:"Set texture wrap mode"},{name:"getWrap",sig:":getWrap()",desc:"Returns horizontal, vertical wrap"},{name:"release",sig:":release()",desc:"Free GPU resources"},{name:"type",sig:":type()",desc:"Returns 'Image'"}]},"lurek.graphics.newCanvas":{typeName:"Canvas",methods:[{name:"getDimensions",sig:":getDimensions()",desc:"Returns width, height"},{name:"getWidth",sig:":getWidth()",desc:"Returns pixel width"},{name:"getHeight",sig:":getHeight()",desc:"Returns pixel height"},{name:"getFilter",sig:":getFilter()",desc:"Returns min, mag filter modes"},{name:"setFilter",sig:":setFilter(min, mag)",desc:"Set texture filter"},{name:"renderTo",sig:":renderTo(fn)",desc:"Render to this canvas"},{name:"release",sig:":release()",desc:"Free GPU resources"},{name:"type",sig:":type()",desc:"Returns 'Canvas'"}]},"lurek.graphics.newFont":{typeName:"Font",methods:[{name:"getWidth",sig:":getWidth(text)",desc:"Width of text in pixels"},{name:"getHeight",sig:":getHeight()",desc:"Font height in pixels"},{name:"getLineHeight",sig:":getLineHeight()",desc:"Returns line height multiplier"},{name:"setLineHeight",sig:":setLineHeight(h)",desc:"Set line height multiplier"},{name:"getAscent",sig:":getAscent()",desc:"Returns font ascent"},{name:"getDescent",sig:":getDescent()",desc:"Returns font descent"},{name:"hasGlyphs",sig:":hasGlyphs(text)",desc:"Check if font has glyphs"},{name:"release",sig:":release()",desc:"Free resources"},{name:"type",sig:":type()",desc:"Returns 'Font'"}]},"lurek.graphics.newShader":{typeName:"Shader",methods:[{name:"send",sig:":send(name, value)",desc:"Set uniform value"},{name:"hasUniform",sig:":hasUniform(name)",desc:"Check if uniform exists"},{name:"release",sig:":release()",desc:"Free GPU resources"},{name:"type",sig:":type()",desc:"Returns 'Shader'"}]},"lurek.graphics.newMesh":{typeName:"Mesh",methods:[{name:"setVertices",sig:":setVertices(verts)",desc:"Set vertex data"},{name:"setTexture",sig:":setTexture(tex)",desc:"Set texture for mesh"},{name:"getVertexCount",sig:":getVertexCount()",desc:"Returns vertex count"},{name:"release",sig:":release()",desc:"Free GPU resources"},{name:"type",sig:":type()",desc:"Returns 'Mesh'"}]},"lurek.graphics.newSpriteBatch":{typeName:"SpriteBatch",methods:[{name:"add",sig:":add(quad, x, y, r, sx, sy)",desc:"Add sprite to batch"},{name:"clear",sig:":clear()",desc:"Remove all sprites"},{name:"getCount",sig:":getCount()",desc:"Returns current sprite count"},{name:"set",sig:":set(id, quad, x, y, r, sx, sy)",desc:"Update sprite at index"},{name:"flush",sig:":flush()",desc:"Upload data to GPU"},{name:"release",sig:":release()",desc:"Free GPU resources"},{name:"type",sig:":type()",desc:"Returns 'SpriteBatch'"}]},"lurek.graphics.newQuad":{typeName:"Quad",methods:[{name:"getViewport",sig:":getViewport()",desc:"Returns x, y, w, h"},{name:"setViewport",sig:":setViewport(x, y, w, h)",desc:"Set viewport rect"},{name:"getTextureDimensions",sig:":getTextureDimensions()",desc:"Returns ref width, height"},{name:"type",sig:":type()",desc:"Returns 'Quad'"}]},"lurek.audio.newSource":{typeName:"Source",methods:[{name:"play",sig:":play()",desc:"Start or resume playback"},{name:"pause",sig:":pause()",desc:"Pause playback"},{name:"stop",sig:":stop()",desc:"Stop and rewind"},{name:"isPlaying",sig:":isPlaying()",desc:"Returns true if playing"},{name:"setVolume",sig:":setVolume(v)",desc:"Set volume (0-1)"},{name:"getVolume",sig:":getVolume()",desc:"Returns current volume"},{name:"setPitch",sig:":setPitch(p)",desc:"Set pitch multiplier"},{name:"getPitch",sig:":getPitch()",desc:"Returns pitch"},{name:"setLooping",sig:":setLooping(loop)",desc:"Enable/disable loop"},{name:"isLooping",sig:":isLooping()",desc:"Returns loop state"},{name:"seek",sig:":seek(seconds)",desc:"Seek to position"},{name:"tell",sig:":tell()",desc:"Returns current position"},{name:"getDuration",sig:":getDuration()",desc:"Returns duration in seconds"},{name:"release",sig:":release()",desc:"Free audio resources"},{name:"type",sig:":type()",desc:"Returns 'Source'"}]},"lurek.physics.newWorld":{typeName:"World",methods:[{name:"update",sig:":update(dt)",desc:"Step the simulation"},{name:"setGravity",sig:":setGravity(gx, gy)",desc:"Set gravity vector"},{name:"getGravity",sig:":getGravity()",desc:"Returns gx, gy"},{name:"getBodyCount",sig:":getBodyCount()",desc:"Number of bodies"},{name:"queryBoundingBox",sig:":queryBoundingBox(x1, y1, x2, y2, fn)",desc:"Query AABB"},{name:"rayCast",sig:":rayCast(x1, y1, x2, y2, fn)",desc:"Cast a ray"},{name:"setCallbacks",sig:":setCallbacks(begin, end, pre, post)",desc:"Set collision callbacks"},{name:"destroy",sig:":destroy()",desc:"Destroy physics world"},{name:"type",sig:":type()",desc:"Returns 'World'"}]},"lurek.physics.newBody":{typeName:"Body",methods:[{name:"getPosition",sig:":getPosition()",desc:"Returns x, y"},{name:"setPosition",sig:":setPosition(x, y)",desc:"Set position"},{name:"getAngle",sig:":getAngle()",desc:"Returns rotation in radians"},{name:"setAngle",sig:":setAngle(angle)",desc:"Set rotation"},{name:"getLinearVelocity",sig:":getLinearVelocity()",desc:"Returns vx, vy"},{name:"setLinearVelocity",sig:":setLinearVelocity(vx, vy)",desc:"Set velocity"},{name:"applyForce",sig:":applyForce(fx, fy)",desc:"Apply force at center"},{name:"applyLinearImpulse",sig:":applyLinearImpulse(ix, iy)",desc:"Apply impulse"},{name:"setMass",sig:":setMass(mass)",desc:"Set body mass"},{name:"getMass",sig:":getMass()",desc:"Returns body mass"},{name:"setType",sig:":setType(type)",desc:"Set body type"},{name:"getType",sig:":getType()",desc:"Returns body type string"},{name:"isAwake",sig:":isAwake()",desc:"Returns true if body is awake"},{name:"destroy",sig:":destroy()",desc:"Remove body from world"},{name:"type",sig:":type()",desc:"Returns 'Body'"}]},"lurek.graphics.newParticleSystem":{typeName:"ParticleSystem",methods:[{name:"emit",sig:":emit(count)",desc:"Emit particles"},{name:"update",sig:":update(dt)",desc:"Update particle system"},{name:"start",sig:":start()",desc:"Start emitting"},{name:"stop",sig:":stop()",desc:"Stop emitting"},{name:"pause",sig:":pause()",desc:"Pause system"},{name:"reset",sig:":reset()",desc:"Reset and clear particles"},{name:"getCount",sig:":getCount()",desc:"Returns active particle count"},{name:"setEmissionRate",sig:":setEmissionRate(rate)",desc:"Particles per second"},{name:"setLifetime",sig:":setLifetime(min, max)",desc:"Set particle lifetime range"},{name:"setPosition",sig:":setPosition(x, y)",desc:"Set emitter position"},{name:"setSpeed",sig:":setSpeed(min, max)",desc:"Set speed range"},{name:"setDirection",sig:":setDirection(angle)",desc:"Set emission direction"},{name:"setSpread",sig:":setSpread(spread)",desc:"Set emission cone angle"},{name:"release",sig:":release()",desc:"Free resources"},{name:"type",sig:":type()",desc:"Returns 'ParticleSystem'"}]},"lurek.cardgame.clone":{typeName:"Card",fields:[{name:"card_type",type:"string",desc:"The registered card type name"},{name:"name",type:"string",desc:"Card display name"},{name:"category",type:"string",desc:"Category (creature, spell, etc.)"},{name:"face_up",type:"boolean",desc:"Whether the card is face-up"},{name:"tapped",type:"boolean",desc:"Whether the card is tapped/exhausted"},{name:"owner",type:"string",desc:"Owner player identifier"},{name:"controller",type:"string",desc:"Controller player identifier"},{name:"zone",type:"string",desc:"Current zone name"}],methods:[{name:"hasTag",sig:":hasTag(tag)",desc:"Returns true if card has the tag"},{name:"addTag",sig:":addTag(tag)",desc:"Add a tag (deduplicated)"},{name:"removeTag",sig:":removeTag(tag)",desc:"Remove a tag by value"},{name:"getStat",sig:":getStat(name)",desc:"Get a numeric stat value"},{name:"setStat",sig:":setStat(name, value)",desc:"Set a numeric stat value"},{name:"addCounter",sig:":addCounter(kind, amount)",desc:"Add to a counter, returns new total"},{name:"getCounter",sig:":getCounter(kind)",desc:"Get a counter value"},{name:"tap",sig:":tap()",desc:"Tap the card (exhausted)"},{name:"untap",sig:":untap()",desc:"Untap the card"},{name:"getMeta",sig:":getMeta(key)",desc:"Get metadata value"},{name:"setMeta",sig:":setMeta(key, value)",desc:"Set metadata value"}]},"lurek.cardgame.newCard":{typeName:"Card",fields:[{name:"card_type",type:"string",desc:"The registered card type name"},{name:"name",type:"string",desc:"Card display name"},{name:"category",type:"string",desc:"Category (creature, spell, etc.)"},{name:"face_up",type:"boolean",desc:"Whether the card is face-up"},{name:"tapped",type:"boolean",desc:"Whether the card is tapped/exhausted"},{name:"owner",type:"string",desc:"Owner player identifier"},{name:"controller",type:"string",desc:"Controller player identifier"},{name:"zone",type:"string",desc:"Current zone name"}],methods:[{name:"hasTag",sig:":hasTag(tag)",desc:"Returns true if card has the tag"},{name:"addTag",sig:":addTag(tag)",desc:"Add a tag (deduplicated)"},{name:"removeTag",sig:":removeTag(tag)",desc:"Remove a tag by value"},{name:"getStat",sig:":getStat(name)",desc:"Get a numeric stat value"},{name:"setStat",sig:":setStat(name, value)",desc:"Set a numeric stat value"},{name:"addCounter",sig:":addCounter(kind, amount)",desc:"Add to a counter, returns new total"},{name:"getCounter",sig:":getCounter(kind)",desc:"Get a counter value"},{name:"removeCounters",sig:":removeCounters(kind)",desc:"Remove all counters of a type"},{name:"getMeta",sig:":getMeta(key)",desc:"Get metadata value"},{name:"setMeta",sig:":setMeta(key, value)",desc:"Set metadata value"},{name:"tap",sig:":tap()",desc:"Tap the card (exhausted)"},{name:"untap",sig:":untap()",desc:"Untap the card"},{name:"getAllCounters",sig:":getAllCounters()",desc:"Returns all (kind, count) counter pairs"}]},"lurek.cardgame.newDeck":{typeName:"Deck",fields:[{name:"name",type:"string",desc:"Deck display name"}],methods:[{name:"shuffle",sig:":shuffle()",desc:"Shuffle using Fisher-Yates"},{name:"draw",sig:":draw()",desc:"Draw from the top; returns Card or nil"},{name:"drawBottom",sig:":drawBottom()",desc:"Draw from the bottom"},{name:"pushTop",sig:":pushTop(card)",desc:"Add a card to the top"},{name:"pushBottom",sig:":pushBottom(card)",desc:"Add a card to the bottom"},{name:"peek",sig:":peek()",desc:"Peek at the top card without removing"},{name:"insertAt",sig:":insertAt(index, card)",desc:"Insert a card at a 0-based position"},{name:"removeAt",sig:":removeAt(index)",desc:"Remove and return card at index"},{name:"moveWithin",sig:":moveWithin(from, to)",desc:"Move card at from_index to to_index"},{name:"size",sig:":size()",desc:"Returns card count"},{name:"isEmpty",sig:":isEmpty()",desc:"Returns true if empty"},{name:"searchByTag",sig:":searchByTag(tag)",desc:"Returns indices of cards with tag"},{name:"searchByType",sig:":searchByType(card_type)",desc:"Returns indices of matching type"},{name:"countByType",sig:":countByType(card_type)",desc:"Count cards of a specific type"},{name:"revealTop",sig:":revealTop(n)",desc:"Peek at top n cards, returns type strings"},{name:"reset",sig:":reset()",desc:"Reset to original state"}]},"lurek.cardgame.newDeckBuilder":{typeName:"DeckBuilder",fields:[{name:"min_cards",type:"integer",desc:"Minimum total cards required"},{name:"max_cards",type:"integer",desc:"Maximum total cards allowed (0 = no limit)"},{name:"max_copies",type:"integer",desc:"Maximum copies of a single card type"}],methods:[{name:"validate",sig:":validate(deck)",desc:"Validate a deck, returns list of violation messages"}]},"lurek.cardgame.newStackManager":{typeName:"StackManager",methods:[{name:"push",sig:":push(entry)",desc:"Push an entry onto the stack"},{name:"resolve",sig:":resolve()",desc:"Pop and return the top entry"},{name:"peek",sig:":peek()",desc:"Peek at the top entry"},{name:"isEmpty",sig:":isEmpty()",desc:"Whether the stack has anything to resolve"},{name:"size",sig:":size()",desc:"Number of entries on the stack"},{name:"clear",sig:":clear()",desc:"Clear all entries"},{name:"findByKind",sig:":findByKind(kind)",desc:"Find first entry matching a kind"}]},"lurek.cardgame.newZone":{typeName:"Zone",fields:[{name:"name",type:"string",desc:"Zone name"},{name:"capacity",type:"integer",desc:"Max capacity (0 = unlimited)"}],methods:[{name:"canAdd",sig:":canAdd()",desc:"Returns true if zone accepts one more card"},{name:"add",sig:":add(card)",desc:"Add a card (returns error if zone full)"},{name:"removeAt",sig:":removeAt(index)",desc:"Remove card at 0-based index"},{name:"size",sig:":size()",desc:"Number of cards in zone"},{name:"isEmpty",sig:":isEmpty()",desc:"True if empty"},{name:"findByType",sig:":findByType(card_type)",desc:"Find first card by type"},{name:"countByType",sig:":countByType(card_type)",desc:"Count cards of a specific type"},{name:"getAllTypes",sig:":getAllTypes()",desc:"Return type strings of all cards"}]},"lurek.cardgame.newCardPool":{typeName:"CardPool",fields:[{name:"name",type:"string",desc:"Pool name"}],methods:[{name:"add",sig:":add(card_type, weight)",desc:"Add a card type with weight (default 1)"},{name:"remove",sig:":remove(card_type)",desc:"Remove a card type from pool"},{name:"draw",sig:":draw(n)",desc:"Draw n cards (with replacement), returns type names"},{name:"size",sig:":size()",desc:"Number of entries"},{name:"getTypes",sig:":getTypes()",desc:"Returns all card types in pool"},{name:"totalWeight",sig:":totalWeight()",desc:"Total weight of all entries"}]},"lurek.entity.new":{typeName:"Entity",methods:[{name:"getId",sig:":getId()",desc:"Returns entity ID"},{name:"getTag",sig:":getTag()",desc:"Returns entity tag"},{name:"setTag",sig:":setTag(tag)",desc:"Set entity tag"},{name:"getPosition",sig:":getPosition()",desc:"Returns x, y"},{name:"setPosition",sig:":setPosition(x, y)",desc:"Set position"},{name:"getComponent",sig:":getComponent(name)",desc:"Get component by name"},{name:"addComponent",sig:":addComponent(name, data)",desc:"Add component"},{name:"removeComponent",sig:":removeComponent(name)",desc:"Remove component"},{name:"hasComponent",sig:":hasComponent(name)",desc:"Returns true if entity has component"},{name:"destroy",sig:":destroy()",desc:"Destroy entity"},{name:"isAlive",sig:":isAlive()",desc:"Returns true if entity is alive"},{name:"type",sig:":type()",desc:"Returns 'Entity'"}]},"lurek.timer.after":{typeName:"Timer",methods:[{name:"cancel",sig:":cancel()",desc:"Cancel the timer"},{name:"pause",sig:":pause()",desc:"Pause the timer"},{name:"resume",sig:":resume()",desc:"Resume the timer"},{name:"isActive",sig:":isActive()",desc:"Returns true if still active"},{name:"type",sig:":type()",desc:"Returns 'Timer'"}]},"lurek.timer.every":{typeName:"Timer",methods:[{name:"cancel",sig:":cancel()",desc:"Cancel the timer"},{name:"pause",sig:":pause()",desc:"Pause the timer"},{name:"resume",sig:":resume()",desc:"Resume the timer"},{name:"isActive",sig:":isActive()",desc:"Returns true if still active"},{name:"type",sig:":type()",desc:"Returns 'Timer'"}]},"lurek.timer.tween":{typeName:"Tween",methods:[{name:"cancel",sig:":cancel()",desc:"Cancel the tween"},{name:"pause",sig:":pause()",desc:"Pause the tween"},{name:"resume",sig:":resume()",desc:"Resume the tween"},{name:"isActive",sig:":isActive()",desc:"Returns true if still active"},{name:"getProgress",sig:":getProgress()",desc:"Returns progress 0-1"},{name:"type",sig:":type()",desc:"Returns 'Tween'"}]},"lurek.tilemap.load":{typeName:"Tilemap",methods:[{name:"draw",sig:":draw()",desc:"Draw the tilemap"},{name:"getWidth",sig:":getWidth()",desc:"Returns width in tiles"},{name:"getHeight",sig:":getHeight()",desc:"Returns height in tiles"},{name:"getTileAt",sig:":getTileAt(x, y)",desc:"Get tile at grid position"},{name:"setTileAt",sig:":setTileAt(x, y, tile)",desc:"Set tile at grid position"},{name:"getLayer",sig:":getLayer(name)",desc:"Get layer by name"},{name:"getLayerCount",sig:":getLayerCount()",desc:"Returns number of layers"},{name:"getProperty",sig:":getProperty(name)",desc:"Get map property"},{name:"type",sig:":type()",desc:"Returns 'Tilemap'"}]},"lurek.scene.new":{typeName:"Scene",methods:[{name:"enter",sig:":enter()",desc:"Called when scene becomes active"},{name:"exit",sig:":exit()",desc:"Called when scene is deactivated"},{name:"update",sig:":update(dt)",desc:"Update scene"},{name:"draw",sig:":draw()",desc:"Draw scene"},{name:"getName",sig:":getName()",desc:"Returns scene name"},{name:"type",sig:":type()",desc:"Returns 'Scene'"}]},"lurek.data.newStore":{typeName:"DataStore",methods:[{name:"get",sig:":get(key)",desc:"Get value by key"},{name:"set",sig:":set(key, value)",desc:"Set a key-value pair"},{name:"delete",sig:":delete(key)",desc:"Delete a key"},{name:"has",sig:":has(key)",desc:"Returns true if key exists"},{name:"keys",sig:":keys()",desc:"Returns all keys"},{name:"values",sig:":values()",desc:"Returns all values"},{name:"clear",sig:":clear()",desc:"Remove all entries"},{name:"size",sig:":size()",desc:"Returns number of entries"},{name:"type",sig:":type()",desc:"Returns 'DataStore'"}]},"lurek.event.on":{typeName:"EventHandle",methods:[{name:"cancel",sig:":cancel()",desc:"Unsubscribe from event"},{name:"type",sig:":type()",desc:"Returns 'EventHandle'"}]},"lurek.camera.new":{typeName:"Camera",methods:[{name:"getPosition",sig:":getPosition()",desc:"Returns x, y"},{name:"setPosition",sig:":setPosition(x, y)",desc:"Set camera position"},{name:"getZoom",sig:":getZoom()",desc:"Returns zoom level"},{name:"setZoom",sig:":setZoom(zoom)",desc:"Set zoom level"},{name:"getRotation",sig:":getRotation()",desc:"Returns rotation in radians"},{name:"setRotation",sig:":setRotation(angle)",desc:"Set rotation"},{name:"lookAt",sig:":lookAt(x, y)",desc:"Center camera on position"},{name:"shake",sig:":shake(intensity, duration)",desc:"Apply screen shake"},{name:"attach",sig:":attach()",desc:"Apply camera transform"},{name:"detach",sig:":detach()",desc:"Reset camera transform"},{name:"worldToScreen",sig:":worldToScreen(wx, wy)",desc:"Convert world to screen coords"},{name:"screenToWorld",sig:":screenToWorld(sx, sy)",desc:"Convert screen to world coords"},{name:"type",sig:":type()",desc:"Returns 'Camera'"}]}},Ec=["graphics","audio","physics","input","timer","filesystem","compute","data","image","entity","window","thread","animation","camera","automation","event","math","particle","tilemap","scene","savegame","modding","graph","pathfinding","ai","dataframe","gui","minimap","overlay","postfx","terminal","cardgame","tween"];function Co(n){let e=[],t=[],o=[],s=new Map,a=n.getText().split(`
`);for(let r=0;r<a.length;r++){let l=a[r],c=l.match(/\blocal\s+(\w+)\s*=\s*(lurek\.\w+\.\w+)\s*\(/);if(c){let[,g,f]=c,b=vt[f];b&&e.push({varName:g,typeName:b.typeName,factoryCall:f,line:r})}let d=l.match(/\blocal\s+(\w+)\s*=\s*(lurek\.(\w+))\s*(?:$|--)/);if(d){let[,g,f,b]=d;Ec.includes(b)&&o.push({varName:g,modulePath:f,line:r})}let u=l.match(/\blocal\s+(\w+)\s*=\s*(\w+)\s*(?:$|--)/);if(u){let[,g,f]=u,b=e.find(x=>x.varName===f&&x.line<r);b&&e.push({varName:g,typeName:b.typeName,factoryCall:b.factoryCall,line:r})}let v=l.match(/\b(?:local\s+)?(\w+)\s*=\s*\{\s*\}/);if(v){let g=v[1];if(r+1<a.length){let f=a[r+1];(f.includes(`${g}.__index`)||f.includes(`__index = ${g}`))&&(s.has(g)||s.set(g,{name:g,methods:[],instances:[]}))}}let m=l.match(/\b(\w+)\.__index\s*=\s*\1\b/);if(m){let g=m[1];s.has(g)||s.set(g,{name:g,methods:[],instances:[]})}let h=l.match(/\bfunction\s+(\w+):(\w+)\s*\(/);if(h){let[,g,f]=h,b=s.get(g);b||(b={name:g,methods:[],instances:[]},s.set(g,b)),b.methods.find(x=>x.name===f)||b.methods.push({name:f,sig:`:${f}(...)`,desc:`Method of ${g}`})}let y=l.match(/\blocal\s+(\w+)\s*=\s*(\w+)[:.](new|create)\s*\(/);if(y){let[,g,f]=y,b=s.get(f);b&&b.instances.push({varName:g,line:r})}let p=l.match(/\blocal\s+(\w+)\s*=\s*setmetatable\s*\([^,]*,\s*(\w+)\s*\)/)??l.match(/\blocal\s+(\w+)\s*=\s*setmetatable\s*\([^,]*,\s*\{[^}]*__index\s*=\s*(\w+)[^}]*\}\s*\)/);if(p){let[,g,f]=p,b=s.get(f);b&&b.instances.push({varName:g,line:r})}}for(let r of s.values())t.push(r);return{varTypes:e,classes:t,moduleAliases:o}}function Cc(n,e,t,o){let s=t.find(i=>i.varName===n&&i.line<e.line);if(s){let i=Object.values(vt).find(a=>a.typeName===s.typeName);if(i)return{typeInfo:i,factoryCall:s.factoryCall}}}function Tc(n,e,t,o){let s=t.find(i=>i.varName===n&&i.line<e.line);if(s){let i=Object.values(vt).find(a=>a.typeName===s.typeName);if(i)return i.methods}for(let i of o)if(i.instances.find(r=>r.varName===n&&r.line<e.line)&&i.methods.length>0)return i.methods}function vi(n,e){let t=Y.languages.registerCompletionItemProvider(Eo,{provideCompletionItems(i,a){let c=i.lineAt(a).text.substring(0,a.character).match(/\b(\w+):(\w*)$/);if(!c)return;let d=c[1],u=c[2].toLowerCase(),{varTypes:v,classes:m}=Co(i),h=Tc(d,a,v,m);if(h)return h.filter(y=>!u||y.name.toLowerCase().startsWith(u)).map(y=>{let p=new Y.CompletionItem(y.name,Y.CompletionItemKind.Method);return p.detail=y.sig,p.documentation=new Y.MarkdownString(y.desc),p.sortText=`0${y.name}`,p})}},":"),o=Y.languages.registerCompletionItemProvider(Eo,{provideCompletionItems(i,a){let c=i.lineAt(a).text.substring(0,a.character).match(/\b(\w+)\.(\w*)$/);if(!c)return;let d=c[1];if(d==="lurek")return;let u=c[2].toLowerCase(),{varTypes:v,classes:m,moduleAliases:h}=Co(i),y=h.find(f=>f.varName===d&&f.line<a.line);if(y){let f=y.modulePath+".",b=[];for(let x of Object.keys(vt))if(x.startsWith(f)){let k=x.substring(f.length);if(!u||k.toLowerCase().startsWith(u)){let L=vt[x],_=new Y.CompletionItem(k,Y.CompletionItemKind.Function);_.detail=`\u2192 ${L.typeName}`,_.documentation=new Y.MarkdownString(`Factory from \`${x}\``),_.sortText=`0${k}`,b.push(_)}}if(b.length>0)return b}let p=[],g=v.find(f=>f.varName===d&&f.line<a.line);if(g){let f=Object.values(vt).find(b=>b.typeName===g.typeName);if(f){if(f.fields)for(let b of f.fields){if(u&&!b.name.toLowerCase().startsWith(u))continue;let x=new Y.CompletionItem(b.name,Y.CompletionItemKind.Field);x.detail=b.type,x.documentation=new Y.MarkdownString(b.desc),x.sortText=`0a${b.name}`,p.push(x)}for(let b of f.methods){if(u&&!b.name.toLowerCase().startsWith(u))continue;let x=new Y.CompletionItem(b.name,Y.CompletionItemKind.Method);x.detail=b.sig,x.documentation=new Y.MarkdownString(b.desc),x.sortText=`0b${b.name}`,p.push(x)}}}if(p.length===0){for(let f of m)if(f.instances.find(x=>x.varName===d&&x.line<a.line)&&f.methods.length>0){for(let x of f.methods){if(u&&!x.name.toLowerCase().startsWith(u))continue;let k=new Y.CompletionItem(x.name,Y.CompletionItemKind.Method);k.detail=x.sig,k.documentation=new Y.MarkdownString(x.desc),k.sortText=`0${x.name}`,p.push(k)}break}}return p.length>0?p:void 0}},"."),s=Y.languages.registerHoverProvider(Eo,{provideHover(i,a){let r=i.getWordRangeAtPosition(a,/\w+/);if(!r)return;let l=i.getText(r),{varTypes:c,classes:d,moduleAliases:u}=Co(i),v=u.find(h=>h.varName===l&&h.line<a.line);if(v){let h=new Y.MarkdownString;return h.appendCodeblock(`${l}: module (${v.modulePath})`,"lua"),h.appendMarkdown(`Alias for \`${v.modulePath}\``),new Y.Hover(h,r)}let m=Cc(l,a,c,d);if(m){let{typeInfo:h,factoryCall:y}=m,p=new Y.MarkdownString;return p.appendCodeblock(`${l}: ${h.typeName}`,"lua"),p.appendMarkdown(`Created by \`${y}()\`

`),h.fields&&h.fields.length>0&&p.appendMarkdown(`**Fields:** ${h.fields.map(g=>`\`${g.name}\``).join(", ")}

`),p.appendMarkdown(`**Methods:** ${h.methods.map(g=>`\`${g.name}\``).join(", ")}`),new Y.Hover(p,r)}for(let h of d)if(h.instances.find(p=>p.varName===l&&p.line<a.line)&&h.methods.length>0){let p=new Y.MarkdownString;return p.appendCodeblock(`${l}: ${h.name}`,"lua"),p.appendMarkdown(`**Methods:** ${h.methods.map(g=>`\`${g.name}\``).join(", ")}`),new Y.Hover(p,r)}}});n.subscriptions.push(t,o,s)}var le=E(require("vscode")),rn=E(require("path"));function Pc(n){let e=[],t=n.getText(),o=/\brequire\s*\(\s*["']([^"']+)["']\s*\)/g,s;for(;(s=o.exec(t))!==null;){let i=s[1],a=s.index,r=s.index+s[0].length,l=n.positionAt(a),c=n.positionAt(r);e.push({moduleName:i,range:new le.Range(l,c)})}return e}function Lc(n,e){let t=n.replace(/\./g,"/"),o=[`${t}.lua`,`${t}/init.lua`];for(let s of o)return le.Uri.joinPath(e,s)}function Rc(n){let s=new Map,i=new Map,a=[];for(let l of n.keys())s.set(l,0);function r(l,c){s.set(l,1);let d=n.get(l)||[];for(let u of d)if(s.has(u))if(s.get(u)===1){let v=c.indexOf(u);if(v>=0){let m=c.slice(v);m.push(u),a.push(m)}}else s.get(u)===0&&(i.set(u,l),r(u,[...c,u]));s.set(l,2)}for(let l of n.keys())s.get(l)===0&&r(l,[l]);return a}function yi(n){let e=le.languages.createDiagnosticCollection("lurek.requireGraph");n.subscriptions.push(e);let t=new Map;async function o(){let i=le.workspace.workspaceFolders?.[0]?.uri;if(!i)return;t.clear();let a=await le.workspace.findFiles("**/*.lua","**/node_modules/**");for(let r of a)try{let l=await le.workspace.openTextDocument(r),c=Pc(l);for(let d of c)d.resolvedUri=Lc(d.moduleName,i);t.set(r.toString(),{uri:r,requires:c})}catch{}s(i)}function s(i){let a=new Map,r=new Map;for(let[u,v]of t){let m=rn.relative(i.fsPath,v.uri.fsPath).replace(/\\/g,"/").replace(/\.lua$/,"").replace(/\/init$/,"");r.set(m,u),a.set(u,[])}for(let[u,v]of t){let m=[];for(let h of v.requires){let y=h.moduleName.replace(/\./g,"/"),p=r.get(y);p&&m.push(p)}a.set(u,m)}let l=Rc(a),c=new Set;for(let u of l)for(let v of u)c.add(v);e.clear();let d=new Map;for(let[u,v]of t){let m=[];for(let h of v.requires){if(h.resolvedUri){let g=h.moduleName.replace(/\./g,"/");if(!r.get(g)){let b=new le.Diagnostic(h.range,`Cannot resolve module "${h.moduleName}" \u2014 file not found in workspace.`,le.DiagnosticSeverity.Warning);b.code="lurek.requireMissing",b.source="Lurek2D Require Graph",m.push(b)}}let y=h.moduleName.replace(/\./g,"/"),p=r.get(y);if(p&&c.has(u)&&c.has(p)){for(let g of l)if(g.includes(u)&&g.includes(p)){let f=g.map(x=>{let k=t.get(x);return k?rn.basename(k.uri.fsPath,".lua"):"?"}),b=new le.Diagnostic(h.range,`Circular dependency detected: ${f.join(" \u2192 ")}`,le.DiagnosticSeverity.Warning);b.code="lurek.requireCycle",b.source="Lurek2D Require Graph",m.push(b);break}}}m.length>0&&d.set(u,m)}for(let[u,v]of d){let m=t.get(u);m&&e.set(m.uri,v)}}o(),n.subscriptions.push(le.workspace.onDidSaveTextDocument(i=>{i.languageId==="lua"&&o()}),le.workspace.onDidCreateFiles(()=>o()),le.workspace.onDidDeleteFiles(()=>o()))}var V=E(require("vscode")),Mc=[{regex:/\bfunction\s+(\w+\.\w+)\s*\(/g,kind:V.SymbolKind.Function,group:1},{regex:/\bfunction\s+(\w+)\s*\(/g,kind:V.SymbolKind.Function,group:1},{regex:/\blocal\s+function\s+(\w+)\s*\(/g,kind:V.SymbolKind.Function,group:1},{regex:/\bfunction\s+(\w+:\w+)\s*\(/g,kind:V.SymbolKind.Method,group:1},{regex:/^(\w+)\s*=\s*\{\s*\}/gm,kind:V.SymbolKind.Class,group:1},{regex:/\blocal\s+(\w+)\s*=\s*\{\s*\}/g,kind:V.SymbolKind.Class,group:1},{regex:/^([A-Z][A-Z_0-9]+)\s*=/gm,kind:V.SymbolKind.Constant,group:1},{regex:/\b(lurek\.\w+)\s*=\s*function/g,kind:V.SymbolKind.Function,group:1},{regex:/\bfunction\s+(lurek\.\w+)\s*\(/g,kind:V.SymbolKind.Function,group:1}],To=class{symbols=new Map;fileSymbols=new Map;building=!1;async buildIndex(){if(!this.building){this.building=!0;try{this.symbols.clear(),this.fileSymbols.clear();let e=await V.workspace.findFiles("**/*.lua","**/node_modules/**");for(let t of e)try{let o=await V.workspace.openTextDocument(t);this.indexDocument(o)}catch{}}finally{this.building=!1}}}async updateFile(e){try{let t=await V.workspace.openTextDocument(e);this.indexDocument(t)}catch{this.removeFile(e)}}removeFile(e){let t=e.toString(),o=this.fileSymbols.get(t)||[];for(let s of o){let i=this.symbols.get(s.name);if(i){let a=i.filter(r=>r.uri.toString()!==t);a.length>0?this.symbols.set(s.name,a):this.symbols.delete(s.name)}}this.fileSymbols.delete(t)}findDefinition(e){let t=this.symbols.get(e);if(!(!t||t.length===0))return t.find(o=>o.kind===V.SymbolKind.Function)||t.find(o=>o.kind===V.SymbolKind.Method)||t[0]}findReferences(e){return this.symbols.get(e)||[]}getWorkspaceSymbols(e){let t=e.toLowerCase(),o=[];for(let[s,i]of this.symbols)if(!t||s.toLowerCase().includes(t))for(let a of i)o.push(new V.SymbolInformation(a.name,a.kind,a.containerName||"",new V.Location(a.uri,a.range)));return o}getFileSymbols(e){return this.fileSymbols.get(e.toString())||[]}indexDocument(e){let t=e.uri.toString();this.removeFile(e.uri);let o=e.getText(),s=[];for(let i of Mc){i.regex.lastIndex=0;let a;for(;(a=i.regex.exec(o))!==null;){let r=a[i.group],l=e.positionAt(a.index),c=e.positionAt(a.index+a[0].length),d;r.includes(":")?d=r.split(":")[0]:r.includes(".")&&!r.startsWith("lurek.")&&(d=r.split(".")[0]);let u={name:r,kind:i.kind,uri:e.uri,range:new V.Range(l,c),containerName:d};s.push(u);let v=this.symbols.get(r)||[];v.push(u),this.symbols.set(r,v)}}this.fileSymbols.set(t,s)}};function bi(n){let e=new To;e.buildIndex(),n.subscriptions.push(V.workspace.onDidSaveTextDocument(o=>{o.languageId==="lua"&&e.updateFile(o.uri)}),V.workspace.onDidDeleteFiles(o=>{for(let s of o.files)e.removeFile(s)}),V.workspace.onDidCreateFiles(o=>{for(let s of o.files)s.fsPath.endsWith(".lua")&&e.updateFile(s)}));let t=V.languages.registerWorkspaceSymbolProvider({provideWorkspaceSymbols(o){return e.getWorkspaceSymbols(o)}});return n.subscriptions.push(t),e}var Je=E(require("vscode")),xi={scheme:"file",language:"lua"},Fc=/\b(function|if|for|while|do|repeat)\b/,Bc=/^\s*(end|else|elseif|until)\b/,Nc=/^\s*\}/,wi=/\{\s*$/;function ki(n,e){let t={provideDocumentFormattingEdits(o,s){try{return zc(o,s)}catch{return[]}},provideDocumentRangeFormattingEdits(o,s,i){try{return Si(o,s,i)}catch{return[]}}};n.subscriptions.push(Je.languages.registerDocumentFormattingEditProvider(xi,t),Je.languages.registerDocumentRangeFormattingEditProvider(xi,t))}function zc(n,e){let t=new Je.Range(0,0,n.lineCount-1,n.lineAt(n.lineCount-1).text.length);return Si(n,t,e)}function Si(n,e,t){let s=n.getText().split(/\r?\n/),i=t.insertSpaces?" ".repeat(t.tabSize):"	",r=_c(s,i).join(`
`);if(r===s.join(`
`))return[];let l=new Je.Range(0,0,n.lineCount-1,n.lineAt(n.lineCount-1).text.length);return[Je.TextEdit.replace(l,r)]}function _c(n,e){let t=[],o=0,s=0,i={inBlockComment:!1,inLongString:!1,closingPattern:""};for(let a=0;a<n.length;a++){let r=n[a];if(i.inBlockComment||i.inLongString){t.push(r),r.includes(i.closingPattern)&&(i.inBlockComment=!1,i.inLongString=!1,i.closingPattern=""),s=0;continue}let l=r.replace(/\s+$/,"").replace(/^\s+/,"");if(l===""){s++,s<=2&&t.push("");continue}s=0;let c=Hc(l);if(c){let m=c.closing;l.slice(l.indexOf(c.open)+c.open.length).includes(m)||(c.isComment?i.inBlockComment=!0:i.inLongString=!0,i.closingPattern=m);let y=$c(l);o=Math.max(0,o+y),t.push(Io(e,o)+l);let p=Oc(l);o=Math.max(0,o+p);continue}if(l.startsWith("--")){t.push(Io(e,o)+l);continue}let d=Po(l),u=Ei(d);o=Math.max(0,o+u),t.push(Io(e,o)+l);let v=Ci(d);o=Math.max(0,o+v)}return t}function $c(n){let e=Po(n);return Ei(e)}function Ei(n){let e=0;return Bc.test(n)&&e--,Nc.test(n)&&e--,e}function Oc(n){let e=Po(n);return Ci(e)}function Ci(n){if(Wc(n))return 0;let e=0;return Fc.test(n)&&(/^\s*(else|elseif)\b/.test(n),e++),wi.test(n)&&e++,e}function Wc(n){return!!(/\bfunction\b.*\bend\b/.test(n)||/\bif\b.*\bthen\b.*\bend\b/.test(n)||/\b(?:for|while)\b.*\bdo\b.*\bend\b/.test(n)||/\{.*\}/.test(n)&&!wi.test(n))}function Po(n){let e="",t=0;for(;t<n.length;){let o=n[t];if(o==="["){let s=jc(n,t);if(s>=0){let i="]"+"=".repeat(s)+"]",a=n.indexOf(i,t+2+s);if(a>=0){t=a+i.length;continue}}e+=o,t++;continue}if(o==='"'||o==="'"){for(t++;t<n.length;){if(n[t]==="\\"){t+=2;continue}if(n[t]===o){t++;break}t++}continue}e+=o,t++}return e}function Hc(n){let e=n.match(/--\[(=*)\[/);if(e){let o=e[1].length;return{open:"--["+"=".repeat(o)+"[",closing:"]"+"=".repeat(o)+"]",isComment:!0}}let t=n.match(/(?<!--)\[(=*)\[/);if(t){let o=t[1].length;return{open:"["+"=".repeat(o)+"[",closing:"]"+"=".repeat(o)+"]",isComment:!1}}}function jc(n,e){if(n[e]!=="[")return-1;let t=0,o=e+1;for(;o<n.length&&n[o]==="=";)t++,o++;return o<n.length&&n[o]==="["?t:-1}function Io(n,e){return n.repeat(Math.max(0,e))}var de=E(require("vscode"));var qc={scheme:"file",language:"lua"},Yc=new G;function Ri(n,e){n.subscriptions.push(de.languages.registerFoldingRangeProvider(qc,{provideFoldingRanges(t){try{return Gc(t)}catch{return[]}}}))}function Gc(n){let e=n.getText(),t=Yc.tokenize(e),o=[],s=[];Vc(t,o),Xc(n,o);let i=t.filter(r=>r.type!==7&&r.type!==4&&r.type!==2&&r.type!==8),a=[];for(let r of i){if(r.type===0)switch(r.value){case"function":case"if":case"for":case"while":case"do":s.push({keyword:r.value,line:r.line,kind:de.FoldingRangeKind.Region});break;case"repeat":s.push({keyword:"repeat",line:r.line,kind:de.FoldingRangeKind.Region});break;case"end":{let l=Ii(s,["function","if","for","while","do"]);l&&r.line>l.line&&o.push(new de.FoldingRange(l.line,r.line,l.kind));break}case"until":{let l=Ii(s,["repeat"]);l&&r.line>l.line&&o.push(new de.FoldingRange(l.line,r.line,l.kind));break}}if(r.type===6){if(r.value==="{")a.push(r.line);else if(r.value==="}"){let l=a.pop();l!==void 0&&r.line>l&&o.push(new de.FoldingRange(l,r.line,de.FoldingRangeKind.Region))}}}return o}function Vc(n,e){for(let t of n){if(t.type===4&&t.value.startsWith("--[")){let o=Pi(t.value);o>0&&e.push(new de.FoldingRange(t.line,t.line+o,de.FoldingRangeKind.Comment))}if(t.type===2&&t.value.startsWith("[")){let o=Pi(t.value);o>0&&e.push(new de.FoldingRange(t.line,t.line+o,de.FoldingRangeKind.Region))}}}function Xc(n,e){let t=[],o,s=-2;for(let i=0;i<n.lineCount;i++){let a=n.lineAt(i).text.trimStart();if(/^--\s*region\b/i.test(a))t.push(i);else if(/^--\s*endregion\b/i.test(a)){let r=t.pop();r!==void 0&&i>r&&e.push(new de.FoldingRange(r,i,de.FoldingRangeKind.Region))}/^---/.test(a)&&!a.startsWith("---[")&&(i===s+1||(Ti(o,s,e),o=i),s=i)}Ti(o,s,e)}function Ti(n,e,t){n!==void 0&&e>n&&t.push(new de.FoldingRange(n,e,de.FoldingRangeKind.Comment))}function Ii(n,e){for(let t=n.length-1;t>=0;t--)if(e.includes(n[t].keyword))return n.splice(t,1)[0]}function Pi(n){let e=0;for(let t of n)t===`
`&&e++;return e}var yt=E(require("vscode"));var Uc={scheme:"file",language:"lua"},Ze=new G,Mi=new Set(["and","break","do","else","elseif","end","false","for","function","goto","if","in","local","nil","not","or","repeat","return","then","true","until","while"]);function Ai(n,e){n.subscriptions.push(yt.languages.registerRenameProvider(Uc,{prepareRename(t,o){try{return Kc(t,o,e)}catch{return}},provideRenameEdits(t,o,s){try{return Jc(t,o,s,e)}catch{return}}}))}function Kc(n,e,t){let o=n.getText(),s=e.line,i=e.character;if(Ze.isInsideString(o,s,i)||Ze.isInsideComment(o,s,i))return;let a=Fi(n,e);if(a&&!Mi.has(a.text)&&!Bi(n,e,a.text,t))return{range:a.range,placeholder:a.text}}function Jc(n,e,t,o){let s=n.getText(),i=e.line,a=e.character;if(Ze.isInsideString(s,i,a)||Ze.isInsideComment(s,i,a))return;let r=Fi(n,e);if(!r||Mi.has(r.text)||Bi(n,e,r.text,o))return;let l=r.text,c=Ze.analyze(s),d=c.symbols.find(y=>y.name===l&&(y.kind==="local"||y.kind==="function"||y.kind==="parameter")),u=0,v=n.lineCount-1;if(d?.isLocal&&d.scope){let y=c.scopes.find(p=>p.name===d.scope);y&&(u=y.startLine,v=y.endLine)}else if(d?.kind==="parameter"&&d.scope){let y=c.scopes.find(p=>p.name===d.scope);y&&(u=y.startLine,v=y.endLine)}let m=Ze.tokenize(s),h=new yt.WorkspaceEdit;for(let y of m){if(y.type!==1||y.value!==l||y.line<u||y.line>v||Ze.isInsideString(s,y.line,y.column)||Ze.isInsideComment(s,y.line,y.column))continue;let p=n.lineAt(y.line).text,g=y.column>0?p[y.column-1]:"",f=y.column+y.length<p.length?p[y.column+y.length]:"";if(Di(g)||Di(f))continue;let b=new yt.Range(y.line,y.column,y.line,y.column+y.length);h.replace(n.uri,b,t)}return h}function Fi(n,e){let t=n.getWordRangeAtPosition(e,/[a-zA-Z_]\w*/);if(t)return{text:n.getText(t),range:t}}function Bi(n,e,t,o){let s=n.lineAt(e.line).text,i=e.character,a=s.substring(0,i);return!!(/lurek\.\w*\.?$/.test(a)&&o.getAllFunctions().find(l=>l.name===t)||t==="lurek")}function Di(n){return/[a-zA-Z0-9_]/.test(n)}var ct=E(require("vscode"));var Zc={scheme:"file",language:"lua"},Ni=new G,$i=["namespace","function","method","parameter","variable","property","keyword","string","number","comment","operator","type","enumMember","macro","decorator","event"],Oi=["declaration","definition","readonly","deprecated","modification","documentation","defaultLibrary"],Lo=new ct.SemanticTokensLegend($i,Oi),zi=new Set(["load","update","draw","keypressed","keyreleased","textinput","mousepressed","mousereleased","wheelmoved","gamepadpressed","gamepadreleased","gamepadaxis","joystickadded","joystickremoved","touchpressed","touchmoved","touchreleased","focus","visible","resize","quit"]),_i=new Map;function Wi(n,e){n.subscriptions.push(ct.languages.registerDocumentSemanticTokensProvider(Zc,{provideDocumentSemanticTokens(t){try{return Qc(t,e)}catch{return new ct.SemanticTokensBuilder(Lo).build()}}},Lo))}function Qc(n,e){let t=n.uri.toString(),o=_i.get(t);if(o&&o.version===n.version)return o.tokens;let s=n.getText(),i=Ni.tokenize(s),a=Ni.analyze(s),r=new ct.SemanticTokensBuilder(Lo),l=new Set(a.symbols.filter(p=>p.kind==="parameter").map(p=>p.name)),c=new Set(a.symbols.filter(p=>p.kind==="local").map(p=>p.name)),d=new Set(a.symbols.filter(p=>p.kind==="function"&&p.isLocal).map(p=>p.name)),u=new Map;for(let p of a.symbols)(p.kind==="local"||p.kind==="parameter")&&!u.has(p.name)&&u.set(p.name,p.line);let v=new Set(e.getAllFunctions().map(p=>p.name)),m=new Set(e.getAllFunctions().filter(p=>p.deprecated).map(p=>p.name)),h=new Set;for(let p of e.getModuleNames()){let g=e.getModule(p);if(g){for(let f of[...g.functions,...g.methods])for(let b of f.parameters)if(b.type.includes("|"))for(let x of b.type.split("|")){let k=x.trim().replace(/^["']|["']$/g,"");k&&!k.includes(" ")&&h.add(k)}}}for(let p=0;p<i.length;p++){let g=i[p],f=p>0?i[p-1]:void 0,b=sd(i,p),x=id(i,p);switch(g.type){case 0:se(r,g,"keyword",[]);break;case 4:td(r,g);break;case 2:nd(r,g,h);break;case 3:se(r,g,"number",[]);break;case 5:se(r,g,"operator",[]);break;case 1:ed(r,g,b,x,i,p,l,c,d,u,v,m,e);break}}let y=r.build();return _i.set(t,{version:n.version,tokens:y}),y}function ed(n,e,t,o,s,i,a,r,l,c,d,u,v){let m=e.value;if(m==="lurek"){if(o?.value==="."){let h=ad(s,i,2);if(h?.type===1&&zi.has(h.value)){se(n,e,"namespace",[]);return}}se(n,e,"namespace",[]);return}if(t?.value==="."||t?.value===":"){let h=rd(s,i);if(h.startsWith("lurek.")){let p=h.slice(5).split(".");if(v.getModule(p[0])&&p.length===1&&o?.value!=="("){se(n,e,"namespace",[]);return}if(p.length===1&&zi.has(m)){se(n,e,"event",[]);return}if(d.has(m)){let g=["defaultLibrary"];u.has(m)&&g.push("deprecated"),se(n,e,"function",g);return}}if(t?.value===":"){se(n,e,"method",[]);return}se(n,e,"property",[]);return}if(t?.type===0&&t.value==="function"){se(n,e,"function",["definition"]);return}if(o?.value==="("){if(l.has(m))se(n,e,"function",[]);else if(d.has(m)){let h=["defaultLibrary"];u.has(m)&&h.push("deprecated"),se(n,e,"function",h)}else se(n,e,"function",[]);return}if(a.has(m)){let h=c.get(m)===e.line;se(n,e,"parameter",h?["declaration"]:[]);return}if(r.has(m)){let h=c.get(m)===e.line;se(n,e,"variable",h?["declaration"]:[]);return}se(n,e,"variable",[])}function td(n,e){let t=e.value;if(/^---@\w+/.test(t)){se(n,e,"decorator",["documentation"]);return}se(n,e,"comment",[])}function nd(n,e,t){let o=od(e.value);if(o&&t.has(o)){se(n,e,"enumMember",[]);return}se(n,e,"string",[])}function od(n){return n.startsWith('"')&&n.endsWith('"')||n.startsWith("'")&&n.endsWith("'")?n.slice(1,-1):""}function se(n,e,t,o){let i=e.value.split(`
`)[0].length;if(i===0)return;let a=$i.indexOf(t);if(a<0)return;let r=0;for(let l of o){let c=Oi.indexOf(l);c>=0&&(r|=1<<c)}n.push(e.line,e.column,i,a,r)}function sd(n,e){for(let t=e-1;t>=0;t--)if(n[t].type!==7)return n[t]}function id(n,e){for(let t=e+1;t<n.length;t++)if(n[t].type!==7)return n[t]}function ad(n,e,t){let o=0;for(let s=e+1;s<n.length;s++)if(n[s].type!==7&&(o++,o>=t))return n[s]}function rd(n,e){let t=n[e].value,o=e-1;for(;o>=0;){if(n[o].type===7){o--;continue}if(n[o].type===6&&(n[o].value==="."||n[o].value===":")){let s=n[o].value;for(o--;o>=0&&n[o].type===7;)o--;if(o>=0&&n[o].type===1){t=n[o].value+s+t,o--;continue}}break}return t}var ie=E(require("vscode")),Hi={scheme:"file",language:"lua"},Ro=new Map;function ji(n){let e=n.uri.toString(),t=Ro.get(e);if(t&&t.version===n.version)return t;let o=new Map,s=new Map,i=n.getText().split(`
`),a=null,r="",l=[],c="";for(let u=0;u<i.length;u++){let m=i[u].trim(),h=m.match(/^---@class\s+(\w+)(?:\s*:\s*(\w+))?(?:\s+(.*))?$/);if(h){a={name:h[1],parent:h[2],fields:[],methods:[],definedLine:u,fileUri:n.uri.toString()},h[3]&&(r=h[3].trim()),o.set(a.name,a);continue}let y=m.match(/^---@field\s+(\w+)\s+(\S+)(?:\s+(.*))?$/);if(y&&a){a.fields.push({name:y[1],type:y[2],description:y[3]?.trim()??"",line:u});continue}let p=m.match(/^---@param\s+(\w+)\s+(\S+)(?:\s+(.*))?$/);if(p){l.push({name:p[1],type:p[2],desc:p[3]?.trim()??""});continue}let g=m.match(/^---@return\s+(\S+)(?:\s+(.*))?$/);if(g){c=g[1];continue}let f=m.match(/^---(?!@)(.*)$/);if(f){r=f[1].trim();continue}let b=m.match(/^(?:local\s+)?function\s+(\w+)[.:]([\w]+)\s*\(([^)]*)\)/);if(b){let Q=b[1],Le=b[2],Ne=o.get(Q);if(Ne){let ft=l.length>0?l.map(gt=>`${gt.name}: ${gt.type}`).join(", "):b[3];Ne.methods.push({name:Le,params:ft,returns:c,description:r,line:u})}l=[],c="",r="";continue}let k=(u>0?i[u-1].trim():"").match(/^---@type\s+(\w+)/);if(k){let Q=m.match(/^local\s+(\w+)\s*=/);Q&&s.set(Q[1],k[1])}let L=m.match(/^local\s+(\w+)\s*=\s*setmetatable\s*\(\s*\{[^}]*\}\s*,\s*(\w+)\s*\)/);L&&s.set(L[1],L[2]);let _=m.match(/^\s*return\s+setmetatable\s*\(\s*\{[^}]*\}\s*,\s*(\w+)\s*\)/);if(_){let Q=o.get(_[1]);Q&&(Q.methods.find(Le=>Le.name==="new")||Q.methods.push({name:"new",params:"",returns:_[1],description:`Create a new ${_[1]} instance`,line:u}))}m!==""&&!m.startsWith("---")&&(r="",l=[],c="")}let d={version:n.version,classes:o,instanceTypes:s};return Ro.set(e,d),d}function qi(n,e,t){if(t.classes.has(e))return t.classes.get(e);let o=t.instanceTypes.get(e);if(o)return t.classes.get(o);let i=n.getText().split(`
`),a=new RegExp(`\\blocal\\s+${e}\\s*=\\s*(\\w+)\\.new\\s*\\(`);for(let r=i.length-1;r>=0;r--){let l=a.exec(i[r]);if(l){let c=t.classes.get(l[1]);if(c)return c}}}function Yi(n,e){let t=ie.languages.registerHoverProvider(Hi,{provideHover(i,a){let r=ji(i),l=i.getWordRangeAtPosition(a,/\w+[.:]\w+/);if(l){let m=i.getText(l),h=m.includes(":")?":":".",[y,p]=m.split(h),g=qi(i,y,r);if(g){let f=g.fields.find(x=>x.name===p);if(f){let x=new ie.MarkdownString;return x.appendCodeblock(`${g.name}.${f.name}: ${f.type}`,"lua"),f.description&&x.appendMarkdown(`
${f.description}
`),x.appendMarkdown(`
*Defined in class \`${g.name}\`*`),x.isTrusted=!0,new ie.Hover(x,l)}let b=g.methods.find(x=>x.name===p);if(b){let x=new ie.MarkdownString;return x.appendCodeblock(`${g.name}:${b.name}(${b.params})${b.returns?` \u2192 ${b.returns}`:""}`,"lua"),b.description&&x.appendMarkdown(`
${b.description}
`),x.appendMarkdown(`
*Method of class \`${g.name}\`*`),x.isTrusted=!0,new ie.Hover(x,l)}}}let c=i.getWordRangeAtPosition(a,/\w+/);if(!c)return;let d=i.getText(c),u=r.classes.get(d);if(!u)return;let v=new ie.MarkdownString;if(v.appendCodeblock(`class ${u.name}${u.parent?` : ${u.parent}`:""}`,"lua"),u.fields.length>0){v.appendMarkdown(`
**Fields:**

`);for(let m of u.fields)v.appendMarkdown(`- \`${m.name}\`: *${m.type}*${m.description?` \u2014 ${m.description}`:""}
`)}if(u.methods.length>0){v.appendMarkdown(`
**Methods:**

`);for(let m of u.methods)v.appendMarkdown(`- \`${m.name}(${m.params})\`${m.returns?` \u2192 ${m.returns}`:""}${m.description?` \u2014 ${m.description}`:""}
`)}return v.isTrusted=!0,new ie.Hover(v,c)}}),o=ie.languages.registerCompletionItemProvider(Hi,{provideCompletionItems(i,a){let r=ji(i),l=i.lineAt(a).text.slice(0,a.character),c=l.match(/(\w+)[.:]\s*$/);if(!c)return[];let d=c[1],u=qi(i,d,r);if(!u)return[];let v=l.endsWith(":"),m=[];if(!v)for(let h of u.fields){let y=new ie.CompletionItem(h.name,ie.CompletionItemKind.Field);y.detail=`${h.type} \u2014 ${u.name}`,y.documentation=h.description,m.push(y)}for(let h of u.methods){let y=new ie.CompletionItem(h.name,ie.CompletionItemKind.Method);y.detail=`${u.name}:${h.name}(${h.params})${h.returns?` \u2192 ${h.returns}`:""}`,y.documentation=h.description,y.insertText=new ie.SnippetString(h.params?`${h.name}(\${1})`:`${h.name}()`),m.push(y)}return m}},".",":"),s=ie.workspace.onDidChangeTextDocument(i=>{i.document.languageId==="lua"&&Ro.delete(i.document.uri.toString())});n.subscriptions.push(t,o,s)}var ee=E(require("vscode")),ve=E(require("path")),Ee=E(require("fs")),dt=class n extends ee.TreeItem{constructor(t,o,s,i,a){super(t,o);this.label=t;this.collapsibleState=o;this.resourceUri=s;this.assetType=i;this.sizeBytes=a;s&&(this.resourceUri=s,this.tooltip=s.fsPath),this.iconPath=i?new ee.ThemeIcon(n.iconFor(i)):void 0,a!==void 0&&(this.description=n.formatSize(a)),i&&i!=="folder"&&s&&(this.command={command:"vscode.open",title:"Open File",arguments:[s]})}static iconFor(t){switch(t){case"image":return"file-media";case"audio":return"unmute";case"font":return"text-size";case"shader":return"symbol-color";case"folder":return"folder";default:return"file"}}static formatSize(t){return t<1024?`${t} B`:t<1024*1024?`${(t/1024).toFixed(1)} KB`:`${(t/1024/1024).toFixed(1)} MB`}},cd=new Set([".png",".jpg",".jpeg",".bmp",".gif",".tga",".tiff",".webp"]),dd=new Set([".wav",".ogg",".mp3",".flac",".aiff"]),ud=new Set([".ttf",".otf"]),pd=new Set([".glsl",".vert",".frag",".wgsl"]);function md(n){if(cd.has(n))return"image";if(dd.has(n))return"audio";if(ud.has(n))return"font";if(pd.has(n))return"shader"}var ln=class{_onDidChangeTreeData=new ee.EventEmitter;onDidChangeTreeData=this._onDidChangeTreeData.event;categories=[];_missingAssets=[];constructor(){this.refresh()}refresh(){this.categories=[{label:"Images",type:"image",icon:"file-media",root:this._newFolder("",""),totalCount:0},{label:"Audio",type:"audio",icon:"unmute",root:this._newFolder("",""),totalCount:0},{label:"Fonts",type:"font",icon:"text-size",root:this._newFolder("",""),totalCount:0},{label:"Shaders",type:"shader",icon:"symbol-color",root:this._newFolder("",""),totalCount:0}],this._missingAssets=[],this._scanGameRoot(),this._onDidChangeTreeData.fire(void 0)}get missingAssets(){return this._missingAssets}_findGameRoot(){let e=ee.workspace.workspaceFolders;if(!e?.length)return;let t=e[0].uri.fsPath;if(Ee.existsSync(ve.join(t,"main.lua")))return t;let o=["content/demos","content/examples","examples","game","src"];for(let s of o){let i=ve.join(t,s);if(Ee.existsSync(i))try{let a=Ee.readdirSync(i,{withFileTypes:!0});for(let r of a)if(r.isDirectory()){let l=ve.join(i,r.name);if(Ee.existsSync(ve.join(l,"main.lua")))return l}}catch{}}return t}_scanGameRoot(){let e=this._findGameRoot();e&&this._walk(e,e)}_newFolder(e,t){return{name:e,relPath:t,children:new Map,files:[]}}_ensureFolder(e,t){if(!t||t===".")return e;let o=t.split("/"),s=e,i="";for(let a of o){i=i?`${i}/${a}`:a;let r=s.children.get(a);r||(r=this._newFolder(a,i),s.children.set(a,r)),s=r}return s}_walk(e,t){let o;try{o=Ee.readdirSync(e,{withFileTypes:!0})}catch{return}for(let s of o){let i=ve.join(e,s.name);if(!(s.name.startsWith(".")||s.name==="node_modules"||s.name==="target"||s.name==="build")){if(s.isDirectory())this._walk(i,t);else if(s.isFile()){let a=ve.extname(s.name).toLowerCase(),r=md(a);if(!r)continue;let l=this.categories.find(m=>m.type===r);if(!l)continue;let c=0;try{c=Ee.statSync(i).size}catch{}let d=ve.relative(t,i).replace(/\\/g,"/"),u=ve.dirname(d);this._ensureFolder(l.root,u==="."?"":u).files.push({name:s.name,relPath:d,uri:ee.Uri.file(i),size:c,type:r}),l.totalCount++}}}}getTreeItem(e){return e}getChildren(e){if(!e)return this.categories.filter(i=>i.totalCount>0).map(i=>{let a=new dt(`${i.label} (${i.totalCount})`,ee.TreeItemCollapsibleState.Collapsed,void 0,"folder",void 0);return a.contextValue=`assetCategory.${i.type}`,a._catType=i.type,a});let t=e._catType;if(t){let i=this.categories.find(a=>a.type===t);return i?this._folderChildren(i.root,i.type):[]}let o=e._folderNode,s=e._fileType;return o?this._folderChildren(o,s||"image"):[]}_folderChildren(e,t){let o=[],s=Array.from(e.children.entries()).sort((a,r)=>a[0].localeCompare(r[0]));for(let[a,r]of s){let l=this._countFiles(r),c=new dt(`${a} (${l})`,ee.TreeItemCollapsibleState.Collapsed,void 0,"folder",void 0);c._folderNode=r,c._fileType=t,o.push(c)}let i=[...e.files].sort((a,r)=>a.name.localeCompare(r.name));for(let a of i){let r=new dt(a.name,ee.TreeItemCollapsibleState.None,a.uri,a.type,a.size);r.contextValue="assetItem",o.push(r)}return o}_countFiles(e){let t=e.files.length;for(let o of e.children.values())t+=this._countFiles(o);return t}};async function Gi(){let n=ee.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!n){ee.window.showWarningMessage("No workspace folder open.");return}let e=await ee.workspace.findFiles("**/*.lua","**/node_modules/**"),t=/lurek\.(?:graphics\.newImage|audio\.newSource)\s*\(\s*["']([^"']+)["']/g,o=[];for(let a of e){let r;try{r=Ee.readFileSync(a.fsPath,"utf8")}catch{continue}let l=r.split(`
`);for(let c=0;c<l.length;c++){t.lastIndex=0;let d;for(;(d=t.exec(l[c]))!==null;){let u=d[1];if(!u.includes("."))continue;let v=ve.resolve(ve.dirname(a.fsPath),u),m=ve.resolve(n,u);!Ee.existsSync(v)&&!Ee.existsSync(m)&&o.push({file:ee.workspace.asRelativePath(a),line:c+1,asset:u})}}}if(o.length===0){ee.window.showInformationMessage("No missing assets found.");return}let s=o.map(a=>`${a.file}:${a.line}  \u2192  ${a.asset}`).join(`
`),i=await ee.workspace.openTextDocument({content:`Missing assets:

${s}`,language:"plaintext"});ee.window.showTextDocument(i)}function Vi(n){let e=ee.window.activeTextEditor;if(!e||!n.resourceUri)return;let t=ee.workspace.workspaceFolders?.[0]?.uri.fsPath??"",o=n.resourceUri.fsPath;t&&o.startsWith(t)&&(o=o.substring(t.length+1)),o=o.replace(/\\/g,"/"),e.edit(s=>s.replace(e.selection,`"${o}"`))}Ao();var X=E(require("vscode")),vd={scheme:"file",language:"lua"},yd=new Set(["load","update","draw","keypressed","keyreleased","textinput","mousepressed","mousereleased","wheelmoved","resize","focus","visible","gamepadpressed","gamepadreleased","gamepadaxis","joystickadded","joystickremoved","touchpressed","touchmoved","touchreleased"]),Fo=class{_onDidChange=new X.EventEmitter;onDidChangeCodeLenses=this._onDidChange.event;provideCodeLenses(e){let t=[],o=e.getText(),s=o.split(`
`),i=/^(?:local\s+function\s+(\w+)|function\s+([\w.:]+))/;function a(r){let l=r.replace(/[.]/g,"\\."),c=new RegExp(`\\b${l}\\b`,"g"),d=o.match(c)??[];return Math.max(0,d.length-1)}for(let r=0;r<s.length;r++){let l=s[r],c=i.exec(l.trimStart());if(!c)continue;let d=c[1]??c[2];if(!d)continue;let u=new X.Range(r,0,r,0),m=d.match(/^lurek\.(\w+)$/)?.[1];if(m&&yd.has(m))t.push(new X.CodeLens(u,{title:`\u26A1 lurek.${m} callback`,command:"lurek.browseApi",arguments:[`lurek.${m}`],tooltip:`Open API documentation for lurek.${m}`}));else{let h=a(d.split(".").pop()??d),y=h===1?"1 reference":`${h} references`;t.push(new X.CodeLens(u,{title:h===0?"\u26A0 unused":y,command:"lurek.codelens.findRefs",arguments:[e.uri,new X.Position(r,l.indexOf(d)),d],tooltip:h===0?`"${d}" is never called`:`Find all references to "${d}"`}))}/^test_|_test\b/.test(d)&&t.push(new X.CodeLens(u,{title:"\u25B6 Run test",command:"lurek.test.runSingleLua",arguments:[e.uri,d],tooltip:`Run Lua test "${d}"`}))}return t}refresh(){this._onDidChange.fire()}};function bd(n){let e=X.window.createStatusBarItem(X.StatusBarAlignment.Right,95);e.name="Lurek2D Variable Type",e.tooltip="Type of the Lua symbol under the cursor",e.command="lurek.debug.openInspector",n.subscriptions.push(e);let t=[{pattern:/=\s*\d+(?:\.\d+)?(?!\w)/,type:"number"},{pattern:/=\s*["']/,type:"string"},{pattern:/=\s*(?:true|false)\b/,type:"boolean"},{pattern:/=\s*\{/,type:"table"},{pattern:/=\s*function\s*\(/,type:"function"},{pattern:/=\s*nil\b/,type:"nil"},{pattern:/lurek\.graphics\.newImage\s*\(/,type:"Image"},{pattern:/lurek\.graphics\.newCanvas\s*\(/,type:"Canvas"},{pattern:/lurek\.graphics\.newFont\s*\(/,type:"Font"},{pattern:/lurek\.graphics\.newShader\s*\(/,type:"Shader"},{pattern:/lurek\.graphics\.newMesh\s*\(/,type:"Mesh"},{pattern:/lurek\.graphics\.newSpriteBatch\s*\(/,type:"SpriteBatch"},{pattern:/lurek\.graphics\.newParticleSystem\s*\(/,type:"ParticleSystem"},{pattern:/lurek\.audio\.newSource\s*\(/,type:"Source"},{pattern:/lurek\.physics\.newWorld\s*\(/,type:"World"},{pattern:/lurek\.physics\.newBody\s*\(/,type:"Body"},{pattern:/lurek\.physics\.newFixture\s*\(/,type:"Fixture"},{pattern:/lurek\.physics\.newRectangleShape\s*\(/,type:"PolygonShape"},{pattern:/lurek\.physics\.newCircleShape\s*\(/,type:"CircleShape"},{pattern:/lurek\.math\.newTransform\s*\(/,type:"Transform"},{pattern:/lurek\.cardgame\.newCard\s*\(/,type:"Card"},{pattern:/lurek\.cardgame\.newDeck\s*\(/,type:"Deck"}];function o(s,i){let r=s.getText().split(`
`);for(let l=r.length-1;l>=0;l--){let c=r[l];if(new RegExp(`\\blocal\\s+${i}\\s*=|\\b${i}\\s*=(?!=)`,"g").test(c)){for(let{pattern:u,type:v}of t)if(u.test(c))return v;return"?"}}}n.subscriptions.push(X.window.onDidChangeTextEditorSelection(s=>{let i=s.textEditor;if(i.document.languageId!=="lua"){e.hide();return}let a=i.selection.active,r=i.document.getWordRangeAtPosition(a,/\w+/);if(!r){e.hide();return}let l=i.document.getText(r);if(/^(local|function|return|end|if|then|else|for|while|do|and|or|not|nil|true|false|repeat|until|break|goto|in)$/.test(l)){e.hide();return}let c=o(i.document,l);c?(e.text=`$(symbol-variable) ${l}: ${c}`,e.show()):e.hide()}))}function Ki(n,e){let t=new Fo;n.subscriptions.push(X.languages.registerCodeLensProvider(vd,t)),n.subscriptions.push(X.workspace.onDidChangeTextDocument(o=>{o.document.languageId==="lua"&&t.refresh()})),n.subscriptions.push(X.commands.registerCommand("lurek.codelens.findRefs",async(o,s)=>{await X.commands.executeCommand("editor.action.referenceSearch.trigger",s)})),bd(n),n.subscriptions.push(X.commands.registerCommand("lurek.codeLens.toggle",()=>{let o=X.workspace.getConfiguration("lurek"),s=o.get("codeLens.enabled",!0);o.update("codeLens.enabled",!s,X.ConfigurationTarget.Global),X.window.showInformationMessage(`Lurek2D Code Lens ${s?"disabled":"enabled"}`)}))}var At=E(require("vscode")),qe,Ye=[],wd=1,dn=!1,Mt,Bo;function Ji(n){Bo=n}function No(n){dn=n,n||Ye.forEach(e=>{e.value="\u2013",e.type="?",e.error=void 0}),ut(),n?Zi():Qi()}function Zi(){Mt||(Mt=setInterval(()=>{cn()},1500))}function Qi(){Mt&&(clearInterval(Mt),Mt=void 0)}async function cn(){if(!(!Bo||!dn||Ye.length===0)){for(let n of Ye){try{let e=await Bo(n.expression);e?(n.value=e.value,n.type=e.type,n.error=void 0):(n.value="nil",n.type="nil")}catch(e){n.value="\u2013",n.type="error",n.error=e instanceof Error?e.message:String(e)}n.lastUpdated=Date.now()}ut()}}function ea(n){if(qe){qe.reveal(At.ViewColumn.Two);return}qe=At.window.createWebviewPanel("lurek.debugWatchers","Lurek2D Watchers",At.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0}),qe.webview.html=Sd(),qe.onDidDispose(()=>{qe=void 0,Qi()},null,n.subscriptions),qe.webview.onDidReceiveMessage(async e=>{switch(e.type){case"add":ta(e.expression),await cn();break;case"remove":Ye=Ye.filter(t=>t.id!==e.id),ut();break;case"edit":kd(e.id,e.expression),await cn();break;case"refresh":await cn();break;case"clear":Ye=[],ut();break}},null,n.subscriptions),ut(),dn&&Zi()}function ta(n){n.trim()&&(Ye.push({id:wd++,expression:n.trim(),value:"\u2013",type:"?",lastUpdated:0}),ut())}function kd(n,e){let t=Ye.find(o=>o.id===n);t&&(t.expression=e.trim(),t.value="\u2013",t.type="?"),ut()}function ut(){qe&&qe.webview.postMessage({type:"update",watches:Ye,connected:dn})}function Sd(){return`<!DOCTYPE html>
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
</html>`}function na(n){let e=n.selection,t=n.document.getText(e.isEmpty?n.document.getWordRangeAtPosition(e.active,/[\w.:\[\]"']+/):e);t&&ta(t)}var Bt=E(require("vscode")),ia=require("child_process"),aa=require("util"),un=(0,aa.promisify)(ia.execFile),$e,bt=[],Ed=120,Ft;async function Cd(){let n={timestamp:Date.now(),cpuPercent:0,ramUsedMb:0,ramTotalMb:0,lurekProcessCpu:0,lurekProcessRamMb:0};return process.platform==="win32"?await Td(n):await Id(n),n}async function Td(n){let e=`
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
} | ConvertTo-Json -Compress`.trim();try{let{stdout:t}=await un("powershell",["-NoProfile","-NonInteractive","-Command",e],{timeout:4e3}),o=JSON.parse(t.trim());n.cpuPercent=o.CPU??0,n.ramTotalMb=Math.round((o.MemTotalKB??0)/1024);let s=Math.round((o.MemFreeKB??0)/1024);n.ramUsedMb=n.ramTotalMb-s,n.lurekProcessCpu=o.LurekCPU??0,n.lurekProcessRamMb=o.LurekRAMMB??0;let i=o.DiskReadBps??0,a=o.DiskWriteBps??0;n.diskReadKbs=Math.round(i/1024),n.diskWriteKbs=Math.round(a/1024);let r=o.NetSentBps??0,l=o.NetRecvBps??0;n.netSentKbs=Math.round(r/1024),n.netRecvKbs=Math.round(l/1024)}catch{}try{let{stdout:t}=await un("nvidia-smi",["--query-gpu=utilization.gpu,memory.used","--format=csv,noheader,nounits"],{timeout:2e3}),o=t.trim().split(",");n.gpuPercent=parseInt(o[0]??"0",10),n.gpuVramMb=parseInt(o[1]?.trim()??"0",10)}catch{}}async function Id(n){try{let{stdout:e}=await un("sh",["-c",`top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1; free -m | grep Mem | awk '{print $3" "$2}'`],{timeout:3e3}),t=e.trim().split(`
`);n.cpuPercent=parseFloat(t[0]??"0");let o=(t[1]??"").split(" ");n.ramUsedMb=parseInt(o[0]??"0",10),n.ramTotalMb=parseInt(o[1]??"0",10)}catch{}try{let{stdout:e}=await un("sh",["-c","ps -C lurek2d -o %cpu=,rss= 2>/dev/null || ps aux | grep '[l]urek2d' | awk '{print $3, $6}' | head -1"],{timeout:2e3}),t=e.trim().split(/\s+/);n.lurekProcessCpu=parseFloat(t[0]??"0"),n.lurekProcessRamMb=Math.round(parseInt(t[1]??"0",10)/1024)}catch{}}function oa(){Ft||(Ft=setInterval(async()=>{let n=await Cd();bt.push(n),bt.length>Ed&&bt.shift(),$e?.visible&&$e.webview.postMessage({type:"data",samples:bt})},2e3))}function sa(){Ft&&(clearInterval(Ft),Ft=void 0)}function ra(n){if($e){$e.reveal(Bt.ViewColumn.Two);return}$e=Bt.window.createWebviewPanel("lurek.systemMonitor","Lurek2D System Monitor",Bt.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0}),$e.webview.html=Pd(),$e.onDidDispose(()=>{$e=void 0,sa()},null,n.subscriptions),$e.webview.onDidReceiveMessage(e=>{e.type==="start"&&oa(),e.type==="stop"&&sa()},null,n.subscriptions),oa(),bt.length&&$e.webview.postMessage({type:"data",samples:bt})}function Pd(){return`<!DOCTYPE html>
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
</html>`}var ce=E(require("vscode")),la=E(require("fs")),ca=E(require("path"));async function Ld(){let n=await ce.workspace.findFiles("**/*.lua","**/node_modules/**"),e=new Map;for(let t of n){let o;try{o=la.readFileSync(t.fsPath,"utf8")}catch{continue}let s=ce.workspace.asRelativePath(t),i=o.split(`
`);for(let a=0;a<i.length;a++){let r=i[a];if(r.trimStart().startsWith("--"))continue;let l=/lurek\.(\w+)\.(\w+)\s*\(/g,c;for(;(c=l.exec(r))!==null;){let d=`lurek.${c[1]}.${c[2]}`;e.has(d)||e.set(d,{func:d,count:0,files:new Set,lines:[]});let u=e.get(d);u.count++,u.files.add(s),u.lines.length<5&&u.lines.push({file:s,line:a+1,text:r.trim()})}}}return Array.from(e.values()).sort((t,o)=>o.count-t.count)}var Ge;async function da(n){if(Ge){Ge.reveal(ce.ViewColumn.Two),await zo();return}Ge=ce.window.createWebviewPanel("lurek.apiUsage","Lurek2D API Usage",ce.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0}),Ge.onDidDispose(()=>{Ge=void 0},null,n.subscriptions),Ge.webview.onDidReceiveMessage(async e=>{if(e.type==="refresh"&&await zo(),e.type==="open"){let t=ce.Uri.file(ca.join(ce.workspace.workspaceFolders?.[0]?.uri.fsPath??"",e.file));await ce.window.showTextDocument(t,{selection:new ce.Range(e.line-1,0,e.line-1,0)})}},null,n.subscriptions),await zo()}async function zo(){if(!Ge)return;Ge.webview.postMessage({type:"loading"});let n=await Ld();Ge.webview.html=Rd(n)}function Rd(n){let e=n.reduce((l,c)=>l+c.count,0),t=n.length,o=n.slice(0,10),s=new Map;for(let l of n){let c=l.func.split(".")[1]??"?";s.has(c)||s.set(c,[]),s.get(c).push(l)}let i=Array.from(s.entries()).sort((l,c)=>c[1].reduce((d,u)=>d+u.count,0)-l[1].reduce((d,u)=>d+u.count,0)).map(([l,c])=>{let d=c.reduce((u,v)=>u+v.count,0);return`<tr><td><code>lurek.${Nt(l)}</code></td><td>${c.length}</td><td>${d}</td></tr>`}).join(""),a=o.map(l=>{let c=l.lines.map(d=>`<a href="#" data-file="${Nt(d.file)}" data-line="${d.line}" class="loc">${Nt(d.file)}:${d.line}</a>`).join(", ");return`<tr>
      <td><code>${Nt(l.func)}</code></td>
      <td>${l.count}</td>
      <td>${l.files.size}</td>
      <td style="font-size:11px;opacity:.7">${c}</td>
    </tr>`}).join(""),r=n.filter(l=>l.count===0).map(l=>`<tr><td><code>${Nt(l.func)}</code></td></tr>`).join("");return`<!DOCTYPE html>
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
  <div class="stat"><div class="stat-val">${s.size}</div><div class="stat-lbl">Modules Used</div></div>
</div>

<h3>By Module</h3>
<table>
  <thead><tr><th>Module</th><th>Functions</th><th>Total Calls</th></tr></thead>
  <tbody>${i}</tbody>
</table>

<h3>Top 10 Most Called</h3>
<table>
  <thead><tr><th>Function</th><th>Calls</th><th>Files</th><th>Locations</th></tr></thead>
  <tbody>${a}</tbody>
</table>

${r?`<h3>Called 0 times</h3><table><thead><tr><th>Function</th></tr></thead><tbody>${r}</tbody></table>`:""}

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
</html>`}function Nt(n){return n.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;")}async function ua(n){let e=ce.window.activeTextEditor;if(!e){ce.window.showWarningMessage("Open a Lua file first.");return}let t=n.getAllFunctions(),o=t.filter(r=>r.fullPath.startsWith("lurek.")).map(r=>({label:r.fullPath,description:r.description??"",detail:r.parameters?.map(l=>`${l.name}: ${l.type}`).join(", ")})),s=await ce.window.showQuickPick(o,{placeHolder:"Search lurek.* function to insert\u2026",matchOnDescription:!0,matchOnDetail:!0});if(!s)return;let i=t.find(r=>r.fullPath===s.label);if(!i)return;let a=i.fullPath+"(";if(i.parameters?.length){let r=i.parameters.filter(l=>!l.optional).map((l,c)=>`\${${c+1}:${l.name}}`).join(", ");a+=r}a+=")$0",e.insertSnippet(new ce.SnippetString(a))}var me=E(require("vscode")),zt=E(require("path")),pn=E(require("fs"));async function _o(n){let e=$o();if(!e){me.window.showErrorMessage("No workspace folder open.");return}let t=me.workspace.getConfiguration("lurek").get("srcDir",""),o=t?zt.join(e,t):e;try{await n.run(o)}catch(s){let i=s instanceof Error?s.message:String(s);me.window.showErrorMessage(`Failed to run Lurek2D: ${i}`)}}function pa(n){if(!n.isRunning()){me.window.showInformationMessage("No Lurek2D game is running.");return}n.stop(),me.window.showInformationMessage("Lurek2D game stopped.")}async function ma(n){let e=await me.window.showInputBox({prompt:"Enter arguments for Lurek2D",placeHolder:"e.g. --debug --fps-cap 60"});if(e===void 0)return;let t=$o();if(!t){me.window.showErrorMessage("No workspace folder open.");return}let o=me.workspace.getConfiguration("lurek").get("srcDir",""),s=o?zt.join(t,o):t;try{await n.run(s,e.split(/\s+/).filter(Boolean))}catch(i){let a=i instanceof Error?i.message:String(i);me.window.showErrorMessage(`Failed to run Lurek2D: ${a}`)}}async function mn(n){let e=$o();if(!e){me.window.showErrorMessage("No workspace folder open.");return}let t=zt.join(e,"content","demos");if(!pn.existsSync(t)){me.window.showWarningMessage("No content/content/demos/ directory found.");return}let o=pn.readdirSync(t,{withFileTypes:!0}).filter(i=>i.isDirectory()).map(i=>i.name);if(o.length===0){me.window.showWarningMessage("No examples found.");return}let s=await me.window.showQuickPick(o,{placeHolder:"Select a demo to run"});if(s)try{await n.run(zt.join(t,s))}catch(i){let a=i instanceof Error?i.message:String(i);me.window.showErrorMessage(`Failed to run example: ${a}`)}}function $o(){return me.workspace.workspaceFolders?.[0]?.uri.fsPath}var be=E(require("vscode")),Oo=E(require("path")),xt=E(require("fs")),fa=[{label:"Minimal",description:"Empty main.lua with gameloop stubs",files:{"main.lua":["function lurek.load()","end","","function lurek.update(dt)","end","","function lurek.draw()","end",""].join(`
`),"conf.lua":["function lurek.conf(t)",'  t.window.title = "My Game"',"  t.window.width = 800","  t.window.height = 600","end"].join(`
`)}},{label:"Game Loop",description:"Full game loop with player movement",files:{"main.lua":["local x, y = 400, 300","local speed = 200","","function lurek.load()",'  lurek.window.setTitle("Game Loop Demo")',"end","","function lurek.update(dt)",'  if lurek.keyboard.isDown("left") then x = x - speed * dt end','  if lurek.keyboard.isDown("right") then x = x + speed * dt end','  if lurek.keyboard.isDown("up") then y = y - speed * dt end','  if lurek.keyboard.isDown("down") then y = y + speed * dt end',"end","","function lurek.draw()","  lurek.graphics.clear(0.1, 0.1, 0.2)","  lurek.graphics.setColor(1, 1, 1)",'  lurek.graphics.circle("fill", x, y, 20)',"end",""].join(`
`),"conf.lua":["function lurek.conf(t)",'  t.window.title = "Game Loop Demo"',"  t.window.width = 800","  t.window.height = 600","end"].join(`
`)}},{label:"Physics",description:"Physics world with falling objects",files:{"main.lua":["local world","local ground, ball","","function lurek.load()","  world = lurek.physics.newWorld(0, 981)",'  ground = lurek.physics.newBody(world, 400, 580, "static")',"  lurek.physics.newRectangleShape(ground, 800, 40)",'  ball = lurek.physics.newBody(world, 400, 100, "dynamic")',"  lurek.physics.newCircleShape(ball, 20)","end","","function lurek.update(dt)","  world:update(dt)","end","","function lurek.draw()","  lurek.graphics.clear(0.1, 0.1, 0.2)","  lurek.graphics.setColor(0.3, 0.3, 0.3)",'  lurek.graphics.rectangle("fill", 0, 560, 800, 40)',"  lurek.graphics.setColor(1, 0.3, 0.3)","  local bx, by = ball:getPosition()",'  lurek.graphics.circle("fill", bx, by, 20)',"end",""].join(`
`),"conf.lua":["function lurek.conf(t)",'  t.window.title = "Physics Demo"',"  t.window.width = 800","  t.window.height = 600","end"].join(`
`)}},{label:"Platformer",description:"Simple platformer with gravity and jumping",files:{"main.lua":["local player = { x = 100, y = 400, vy = 0, w = 32, h = 48, onGround = false }","local gravity = 900","local jumpForce = -400","local moveSpeed = 200","local groundY = 500","","function lurek.update(dt)","  -- Horizontal movement",'  if lurek.keyboard.isDown("left") then player.x = player.x - moveSpeed * dt end','  if lurek.keyboard.isDown("right") then player.x = player.x + moveSpeed * dt end',"","  -- Gravity","  player.vy = player.vy + gravity * dt","  player.y = player.y + player.vy * dt","","  -- Ground collision","  if player.y + player.h >= groundY then","    player.y = groundY - player.h","    player.vy = 0","    player.onGround = true","  else","    player.onGround = false","  end","end","","function lurek.keypressed(key)",'  if key == "space" and player.onGround then',"    player.vy = jumpForce","  end","end","","function lurek.draw()","  lurek.graphics.clear(0.2, 0.3, 0.4)","  lurek.graphics.setColor(0.4, 0.4, 0.4)",'  lurek.graphics.rectangle("fill", 0, groundY, 800, 100)',"  lurek.graphics.setColor(0.2, 0.8, 0.4)",'  lurek.graphics.rectangle("fill", player.x, player.y, player.w, player.h)',"end",""].join(`
`),"conf.lua":["function lurek.conf(t)",'  t.window.title = "Platformer"',"  t.window.width = 800","  t.window.height = 600","end"].join(`
`)}},{label:"Top-Down",description:"Top-down view with WASD movement",files:{"main.lua":["local player = { x = 400, y = 300, speed = 200, size = 16 }","","function lurek.update(dt)",'  if lurek.keyboard.isDown("w") then player.y = player.y - player.speed * dt end','  if lurek.keyboard.isDown("s") then player.y = player.y + player.speed * dt end','  if lurek.keyboard.isDown("a") then player.x = player.x - player.speed * dt end','  if lurek.keyboard.isDown("d") then player.x = player.x + player.speed * dt end',"end","","function lurek.draw()","  lurek.graphics.clear(0.15, 0.15, 0.2)","  lurek.graphics.setColor(0.3, 0.7, 1)",'  lurek.graphics.rectangle("fill", player.x - player.size/2, player.y - player.size/2, player.size, player.size)',"end",""].join(`
`),"conf.lua":["function lurek.conf(t)",'  t.window.title = "Top-Down"',"  t.window.width = 800","  t.window.height = 600","end"].join(`
`)}},{label:"ECS",description:"Entity Component System with lurek.entity",files:{"main.lua":["local universe","","function lurek.load()","  universe = lurek.entity.newUniverse()","","  for i = 1, 10 do","    local e = universe:spawn()",'    e:set("position", { x = math.random(50, 750), y = math.random(50, 550) })','    e:set("velocity", { x = math.random(-100, 100), y = math.random(-100, 100) })','    e:set("radius", math.random(5, 20))',"  end","end","","function lurek.update(dt)",'  for _, e in universe:query("position", "velocity") do','    local pos = e:get("position")','    local vel = e:get("velocity")',"    pos.x = pos.x + vel.x * dt","    pos.y = pos.y + vel.y * dt","    if pos.x < 0 or pos.x > 800 then vel.x = -vel.x end","    if pos.y < 0 or pos.y > 600 then vel.y = -vel.y end","  end","end","","function lurek.draw()","  lurek.graphics.clear(0.1, 0.1, 0.15)",'  for _, e in universe:query("position", "radius") do','    local pos = e:get("position")','    local r = e:get("radius")',"    lurek.graphics.setColor(0.4, 0.8, 1)",'    lurek.graphics.circle("fill", pos.x, pos.y, r)',"  end","end",""].join(`
`),"conf.lua":["function lurek.conf(t)",'  t.window.title = "ECS Demo"',"  t.window.width = 800","  t.window.height = 600","end"].join(`
`)}}],ga={"main.lua":`function lurek.load()
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
`};async function ha(){let n=fa.map(a=>({label:a.label,description:a.description})),e=await be.window.showQuickPick(n,{placeHolder:"Select a project template"});if(!e)return;let t=await be.window.showOpenDialog({canSelectFolders:!0,canSelectFiles:!1,canSelectMany:!1,openLabel:"Select Project Folder"});if(!t||t.length===0)return;let o=t[0].fsPath,s=fa.find(a=>a.label===e.label);if(!s)return;for(let[a,r]of Object.entries(s.files)){let l=Oo.join(o,a);xt.existsSync(l)||xt.writeFileSync(l,r,"utf-8")}let i=be.Uri.file(o);await be.commands.executeCommand("vscode.openFolder",i)}async function va(){let n=Object.keys(ga),e=await be.window.showQuickPick(n,{placeHolder:"Select a file template"});if(!e)return;let t=be.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!t){be.window.showErrorMessage("No workspace folder open.");return}let o=await be.window.showInputBox({prompt:"Enter file name",value:e});if(!o)return;let s=Oo.join(t,o);if(xt.existsSync(s)){be.window.showWarningMessage(`File already exists: ${o}`);return}xt.writeFileSync(s,ga[e],"utf-8");let i=await be.workspace.openTextDocument(s);await be.window.showTextDocument(i)}var fn=E(require("vscode"));function ya(){let n=gn("Lurek2D Tests");n.show(),n.sendText("cargo test")}function ba(n){let e=gn("Lurek2D Tests");e.show(),e.sendText(`cargo test ${n}_tests`)}function xa(){let n=gn("Lurek2D Tests");n.show(),n.sendText("cargo test --test lua_tests")}function wa(){let n=gn("Lurek2D Tests");n.show(),n.sendText("cargo test --test golden_tests")}function gn(n){let e=fn.window.terminals.find(t=>t.name===n);return e||fn.window.createTerminal(n)}var Wo=E(require("vscode"));function ka(){let n=Ho("Lurek2D Package");n.show(),process.platform==="win32"?n.sendText("powershell -ExecutionPolicy Bypass -File tools/dist.ps1"):n.sendText("bash tools/dist.sh")}function Sa(){let n=Ho("Lurek2D Package");n.show(),n.sendText("powershell -ExecutionPolicy Bypass -File tools/dist.ps1")}function Ea(){let n=Ho("Lurek2D Package");n.show(),n.sendText("bash tools/dist.sh")}function Ho(n){let e=Wo.window.terminals.find(t=>t.name===n);return e||Wo.window.createTerminal(n)}var Ca=E(require("vscode"));var Oe=E(require("vscode"));function R(){let n="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",e="";for(let t=0;t<32;t++)e+=n.charAt(Math.floor(Math.random()*n.length));return e}function Dd(){return`
    :root {
      --bg: #1e1e1e; --surface: #252526; --surface-2: #2d2d2d;
      --border: #3c3c3c; --text: #cccccc; --text-dim: #858585;
      --accent: #007acc; --accent-2: #4ec9b0;
      --success: #4caf50; --warning: #ff9800; --danger: #f44336;
      --selection: #264f78;
    }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      color: var(--text); background: var(--bg);
      overflow: hidden; height: 100vh;
    }
    button {
      background: var(--surface-2); color: var(--text); border: 1px solid var(--border);
      padding: 4px 12px; border-radius: 3px; cursor: pointer; font-size: 12px;
    }
    button:hover { background: var(--accent); border-color: var(--accent); }
    button.active { background: var(--accent); border-color: var(--accent); }
    button.danger { border-color: var(--danger); }
    button.danger:hover { background: var(--danger); }
    input, select, textarea {
      background: var(--surface); color: var(--text); border: 1px solid var(--border);
      padding: 3px 6px; border-radius: 3px; font-size: 12px;
    }
    input:focus, select:focus, textarea:focus { outline: none; border-color: var(--accent); }
    label { font-size: 12px; color: var(--text-dim); }
    .toolbar {
      display: flex; align-items: center; gap: 6px; padding: 6px 10px;
      background: var(--surface); border-bottom: 1px solid var(--border);
    }
    .toolbar .sep { width: 1px; height: 20px; background: var(--border); }
    .panel {
      background: var(--surface); border-right: 1px solid var(--border);
      overflow-y: auto; padding: 8px;
    }
    .panel h3 {
      font-size: 11px; text-transform: uppercase; color: var(--text-dim);
      margin-bottom: 6px; letter-spacing: 0.5px;
    }
    .status-bar {
      display: flex; align-items: center; gap: 12px; padding: 2px 10px;
      background: var(--surface); border-top: 1px solid var(--border);
      font-size: 11px; color: var(--text-dim);
    }
    .list-item {
      padding: 4px 8px; cursor: pointer; border-radius: 3px; font-size: 12px;
    }
    .list-item:hover { background: var(--surface-2); }
    .list-item.selected { background: var(--selection); }
    .section { margin-bottom: 12px; }
    .field { display: flex; flex-direction: column; gap: 2px; margin-bottom: 6px; }
    .field-row { display: flex; align-items: center; gap: 6px; margin-bottom: 4px; }
    canvas { display: block; }
  `}function D(n,e,t,o,s){return`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta http-equiv="Content-Security-Policy"
    content="default-src 'none'; style-src 'nonce-${n}'; script-src 'nonce-${n}'; img-src data:;">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${e}</title>
  <style nonce="${n}">${Dd()}${t}</style>
</head>
<body>
${o}
<script nonce="${n}">
const vscode = acquireVsCodeApi();
${s}
</script>
</body>
</html>`}var P=class{constructor(e,t,o,s={}){this.context=e;this.data=s;this.panel=Oe.window.createWebviewPanel(t,o,Oe.ViewColumn.One,{enableScripts:!0,retainContextWhenHidden:!0}),this.panel.webview.onDidReceiveMessage(i=>this.handleMessage(i),void 0,this.disposables),this.panel.onDidDispose(()=>this.dispose(),void 0,this.disposables),this.panel.webview.html=this.getHtml()}panel;isDirty=!1;disposables=[];async exportFile(e,t,o,s){let i=await Oe.window.showSaveDialog({defaultUri:Oe.Uri.file(t),filters:{[o]:[s]}});i&&(await Oe.workspace.fs.writeFile(i,Buffer.from(e,"utf-8")),Oe.window.showInformationMessage(`Exported to ${i.fsPath}`))}async exportLua(e,t){return this.exportFile(e,t,"Lua","lua")}async exportToml(e,t){return this.exportFile(e,t,"TOML","toml")}dispose(){for(let e of this.disposables)e.dispose()}};var hn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.tileMap","Tile Map Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"tilemap.lua");break;case"exportToml":this.exportToml(e.content,"tilemap.toml");break}}getHtml(){let e=R();return D(e,"Tile Map Editor",`
      .editor-layout {
        display: grid; grid-template-columns: 200px 1fr; grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .side-panel { grid-row: 2; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; }
      .status-bar { grid-column: 1 / -1; }
      .palette-grid {
        display: grid; grid-template-columns: repeat(4, 1fr); gap: 2px; margin-top: 6px;
      }
      .palette-tile {
        width: 100%; aspect-ratio: 1; border: 1px solid var(--border); cursor: pointer;
        border-radius: 2px;
      }
      .palette-tile.selected { border-color: var(--accent); border-width: 2px; }
      .tool-list { display: flex; flex-direction: column; gap: 2px; margin-top: 6px; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <label>Width:</label><input type="number" id="mapWidth" value="20" min="1" max="200" style="width:50px">
          <label>Height:</label><input type="number" id="mapHeight" value="15" min="1" max="200" style="width:50px">
          <label>Tile Size:</label><input type="number" id="tileSize" value="32" min="8" max="128" style="width:50px">
          <div class="sep"></div>
          <label>Layer:</label>
          <select id="layerSelect"><option value="ground">Ground</option><option value="walls">Walls</option><option value="objects">Objects</option></select>
          <div class="sep"></div>
          <button id="btnResize">Resize</button>
          <button id="btnClear">Clear Layer</button>
          <div class="sep"></div>
          <button id="btnExportLua">Export Lua</button>
          <button id="btnExportToml">Export TOML</button>
        </div>
        <div class="panel side-panel">
          <div class="section">
            <h3>Tools</h3>
            <div class="tool-list" id="toolList">
              <button class="active" data-tool="paint">&#9998; Paint</button>
              <button data-tool="erase">&#9003; Erase</button>
              <button data-tool="fill">&#9636; Fill</button>
              <button data-tool="pick">&#128270; Pick</button>
              <button data-tool="rect">&#9645; Rect</button>
            </div>
          </div>
          <div class="section">
            <h3>Tile Palette</h3>
            <div class="palette-grid" id="palette"></div>
          </div>
          <div class="section">
            <h3>View</h3>
            <div class="field-row"><input type="checkbox" id="showGrid" checked><label for="showGrid">Show Grid</label></div>
            <div class="field-row"><input type="checkbox" id="showIds"><label for="showIds">Show Tile IDs</label></div>
          </div>
        </div>
        <div class="canvas-area"><canvas id="mapCanvas"></canvas></div>
        <div class="status-bar">
          <span id="statusPos">Pos: 0, 0</span>
          <span id="statusTile">Tile: 0</span>
          <span id="statusLayer">Layer: ground</span>
          <span id="statusSize">Grid: 20x15</span>
        </div>
      </div>
    `,`
      const canvas = document.getElementById('mapCanvas');
      const ctx = canvas.getContext('2d');
      let mapW = 20, mapH = 15, tileSize = 32;
      let currentTile = 1, currentTool = 'paint', currentLayer = 'ground';
      let showGrid = true, showIds = false;
      let offsetX = 0, offsetY = 0, zoom = 1;
      let isPanning = false, panStartX = 0, panStartY = 0;
      let isDrawing = false, rectStartX = -1, rectStartY = -1;

      const TILE_COLORS = [
        '#1a1a2e','#16213e','#0f3460','#533483','#e94560','#4ec9b0',
        '#007acc','#ff9800','#4caf50','#f44336','#9c27b0','#00bcd4',
        '#795548','#607d8b','#ffeb3b','#8bc34a'
      ];

      const layers = { ground: [], walls: [], objects: [] };
      function initLayer(name) {
        layers[name] = new Array(mapW * mapH).fill(0);
      }
      function initAllLayers() { for (const k in layers) initLayer(k); }
      initAllLayers();

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

        const layer = layers[currentLayer];
        for (let y = 0; y < mapH; y++) {
          for (let x = 0; x < mapW; x++) {
            const t = layer[y * mapW + x];
            const px = x * tileSize, py = y * tileSize;
            if (t > 0) {
              ctx.fillStyle = TILE_COLORS[(t - 1) % TILE_COLORS.length];
              ctx.fillRect(px, py, tileSize, tileSize);
            }
            if (showGrid) {
              ctx.strokeStyle = '#3c3c3c';
              ctx.lineWidth = 0.5;
              ctx.strokeRect(px, py, tileSize, tileSize);
            }
            if (showIds && t > 0) {
              ctx.fillStyle = '#fff';
              ctx.font = '10px monospace';
              ctx.textAlign = 'center';
              ctx.textBaseline = 'middle';
              ctx.fillText(String(t), px + tileSize/2, py + tileSize/2);
            }
          }
        }
        ctx.restore();
      }

      function screenToTile(sx, sy) {
        const tx = Math.floor((sx - offsetX) / (tileSize * zoom));
        const ty = Math.floor((sy - offsetY) / (tileSize * zoom));
        return { tx, ty };
      }

      function setTile(tx, ty, value) {
        if (tx >= 0 && tx < mapW && ty >= 0 && ty < mapH) {
          layers[currentLayer][ty * mapW + tx] = value;
        }
      }

      function floodFill(tx, ty, target, replacement) {
        if (target === replacement) return;
        const layer = layers[currentLayer];
        const stack = [[tx, ty]];
        while (stack.length) {
          const [x, y] = stack.pop();
          if (x < 0 || x >= mapW || y < 0 || y >= mapH) continue;
          if (layer[y * mapW + x] !== target) continue;
          layer[y * mapW + x] = replacement;
          stack.push([x-1,y],[x+1,y],[x,y-1],[x,y+1]);
        }
      }

      // Build palette
      const paletteEl = document.getElementById('palette');
      for (let i = 0; i <= 15; i++) {
        const el = document.createElement('div');
        el.className = 'palette-tile' + (i === 1 ? ' selected' : '');
        el.style.background = i === 0 ? 'transparent' : TILE_COLORS[(i-1) % TILE_COLORS.length];
        if (i === 0) { el.style.background = 'repeating-conic-gradient(#333 0% 25%, #222 0% 50%) 50% / 8px 8px'; }
        el.addEventListener('click', () => {
          paletteEl.querySelectorAll('.palette-tile').forEach(t => t.classList.remove('selected'));
          el.classList.add('selected');
          currentTile = i;
          document.getElementById('statusTile').textContent = 'Tile: ' + i;
        });
        paletteEl.appendChild(el);
      }

      // Tools
      document.getElementById('toolList').addEventListener('click', (e) => {
        const btn = e.target.closest('[data-tool]');
        if (!btn) return;
        document.getElementById('toolList').querySelectorAll('button').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentTool = btn.dataset.tool;
      });

      // Canvas events
      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) {
          isPanning = true; panStartX = e.clientX - offsetX; panStartY = e.clientY - offsetY;
          e.preventDefault(); return;
        }
        if (e.button === 0) {
          isDrawing = true;
          const { tx, ty } = screenToTile(e.offsetX, e.offsetY);
          if (currentTool === 'paint') { setTile(tx, ty, currentTile); render(); }
          else if (currentTool === 'erase') { setTile(tx, ty, 0); render(); }
          else if (currentTool === 'fill') {
            const layer = layers[currentLayer];
            if (tx >= 0 && tx < mapW && ty >= 0 && ty < mapH) {
              floodFill(tx, ty, layer[ty*mapW+tx], currentTile); render();
            }
          }
          else if (currentTool === 'pick') {
            const layer = layers[currentLayer];
            if (tx >= 0 && tx < mapW && ty >= 0 && ty < mapH) {
              currentTile = layer[ty*mapW+tx];
              document.getElementById('statusTile').textContent = 'Tile: ' + currentTile;
              paletteEl.querySelectorAll('.palette-tile').forEach((t,i) => {
                t.classList.toggle('selected', i === currentTile);
              });
            }
          }
          else if (currentTool === 'rect') { rectStartX = tx; rectStartY = ty; }
        }
      });

      canvas.addEventListener('mousemove', (e) => {
        if (isPanning) {
          offsetX = e.clientX - panStartX; offsetY = e.clientY - panStartY; render(); return;
        }
        const { tx, ty } = screenToTile(e.offsetX, e.offsetY);
        document.getElementById('statusPos').textContent = 'Pos: ' + tx + ', ' + ty;
        if (isDrawing) {
          if (currentTool === 'paint') { setTile(tx, ty, currentTile); render(); }
          else if (currentTool === 'erase') { setTile(tx, ty, 0); render(); }
        }
      });

      canvas.addEventListener('mouseup', (e) => {
        if (isPanning) { isPanning = false; return; }
        if (isDrawing && currentTool === 'rect') {
          const { tx, ty } = screenToTile(e.offsetX, e.offsetY);
          const x0 = Math.min(rectStartX, tx), x1 = Math.max(rectStartX, tx);
          const y0 = Math.min(rectStartY, ty), y1 = Math.max(rectStartY, ty);
          for (let y = y0; y <= y1; y++)
            for (let x = x0; x <= x1; x++) setTile(x, y, currentTile);
          render();
        }
        isDrawing = false;
      });

      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const oldZoom = zoom;
        zoom *= e.deltaY < 0 ? 1.1 : 0.9;
        zoom = Math.max(0.1, Math.min(5, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / oldZoom;
        offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / oldZoom;
        render();
      }, { passive: false });

      // Controls
      document.getElementById('showGrid').addEventListener('change', (e) => { showGrid = e.target.checked; render(); });
      document.getElementById('showIds').addEventListener('change', (e) => { showIds = e.target.checked; render(); });
      document.getElementById('layerSelect').addEventListener('change', (e) => {
        currentLayer = e.target.value;
        document.getElementById('statusLayer').textContent = 'Layer: ' + currentLayer;
        render();
      });
      document.getElementById('btnResize').addEventListener('click', () => {
        const nw = parseInt(document.getElementById('mapWidth').value) || 20;
        const nh = parseInt(document.getElementById('mapHeight').value) || 15;
        tileSize = parseInt(document.getElementById('tileSize').value) || 32;
        mapW = Math.min(200, Math.max(1, nw));
        mapH = Math.min(200, Math.max(1, nh));
        initAllLayers();
        document.getElementById('statusSize').textContent = 'Grid: ' + mapW + 'x' + mapH;
        render();
      });
      document.getElementById('btnClear').addEventListener('click', () => { initLayer(currentLayer); render(); });

      function generateExport() {
        const data = { width: mapW, height: mapH, tileSize: tileSize, layers: {} };
        for (const k in layers) data.layers[k] = Array.from(layers[k]);
        return data;
      }
      document.getElementById('btnExportLua').addEventListener('click', () => {
        const d = generateExport();
        let lua = 'return {\\n';
        lua += '  width = ' + d.width + ',\\n  height = ' + d.height + ',\\n  tileSize = ' + d.tileSize + ',\\n';
        lua += '  layers = {\\n';
        for (const k in d.layers) {
          lua += '    ' + k + ' = {' + d.layers[k].join(', ') + '},\\n';
        }
        lua += '  }\\n}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });
      document.getElementById('btnExportToml').addEventListener('click', () => {
        const d = generateExport();
        let toml = 'width = ' + d.width + '\\nheight = ' + d.height + '\\ntile_size = ' + d.tileSize + '\\n\\n';
        for (const k in d.layers) {
          toml += '[layers.' + k + ']\\ndata = [' + d.layers[k].join(', ') + ']\\n\\n';
        }
        vscode.postMessage({ type: 'exportToml', content: toml });
      });

      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `)}};var vn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.sceneFlow","Scene Flow Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"scenes.lua");break}}getHtml(){let e=R();return D(e,"Scene Flow Editor",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 240px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .canvas-area { position: relative; overflow: hidden; }
      .props-panel { grid-row: 2; overflow-y: auto; padding: 8px; background: var(--surface); border-left: 1px solid var(--border); }
      .status-bar { grid-column: 1 / -1; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAdd">+ Add Scene</button>
          <button id="btnConnect">Connect Mode</button>
          <button id="btnDelete" class="danger">Delete Selected</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="canvas-area"><canvas id="flowCanvas"></canvas></div>
        <div class="props-panel">
          <h3>Properties</h3>
          <div id="propsContent" style="margin-top: 8px;">
            <p style="color: var(--text-dim); font-size: 12px;">Select a scene node to edit its properties.</p>
          </div>
        </div>
        <div class="status-bar">
          <span id="statusInfo">Scenes: 0 | Transitions: 0</span>
          <span id="statusMode">Mode: Select</span>
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

      const NODE_W = 140, NODE_H = 50;
      const COLORS = ['#264f78','#2d4a22','#4a3222','#3c2244','#443322'];

      function addNode(name, x, y) {
        nodes.push({
          id: nextId++, name: name || 'Scene' + nodes.length,
          x: x || 100 + nodes.length * 30, y: y || 100 + nodes.length * 30,
          onEnter: '', onExit: '', onUpdate: '', onDraw: '',
          color: COLORS[nodes.length % COLORS.length]
        });
        updateStatus(); render();
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight;
        render();
      }

      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.save(); ctx.translate(offsetX, offsetY); ctx.scale(zoom, zoom);

        // Draw edges
        for (const e of edges) {
          const from = nodes.find(n => n.id === e.from);
          const to = nodes.find(n => n.id === e.to);
          if (!from || !to) continue;
          const fx = from.x + NODE_W/2, fy = from.y + NODE_H/2;
          const tx = to.x + NODE_W/2, ty = to.y + NODE_H/2;
          ctx.beginPath(); ctx.moveTo(fx, fy); ctx.lineTo(tx, ty);
          ctx.strokeStyle = '#858585'; ctx.lineWidth = 2; ctx.stroke();
          // Arrow
          const angle = Math.atan2(ty - fy, tx - fx);
          const ax = tx - Math.cos(angle) * (NODE_W/2 + 5);
          const ay = ty - Math.sin(angle) * (NODE_H/2 + 5);
          ctx.beginPath();
          ctx.moveTo(ax, ay);
          ctx.lineTo(ax - 10*Math.cos(angle-0.3), ay - 10*Math.sin(angle-0.3));
          ctx.lineTo(ax - 10*Math.cos(angle+0.3), ay - 10*Math.sin(angle+0.3));
          ctx.closePath(); ctx.fillStyle = '#858585'; ctx.fill();
        }

        // Draw nodes
        for (const n of nodes) {
          ctx.fillStyle = n.color; ctx.strokeStyle = n === selectedNode ? '#007acc' : '#3c3c3c';
          ctx.lineWidth = n === selectedNode ? 2 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.fill(); ctx.stroke();
          ctx.fillStyle = '#ccc'; ctx.font = '13px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
          ctx.fillText(n.name, n.x + NODE_W/2, n.y + NODE_H/2);
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
        if (!node) {
          document.getElementById('propsContent').innerHTML = '<p style="color:var(--text-dim);font-size:12px;">Select a scene node.</p>';
          return;
        }
        document.getElementById('propsContent').innerHTML =
          '<div class="field"><label>Name</label><input id="pName" value="' + node.name + '"></div>' +
          '<div class="field"><label>onEnter</label><input id="pEnter" value="' + node.onEnter + '"></div>' +
          '<div class="field"><label>onExit</label><input id="pExit" value="' + node.onExit + '"></div>' +
          '<div class="field"><label>onUpdate</label><input id="pUpdate" value="' + node.onUpdate + '"></div>' +
          '<div class="field"><label>onDraw</label><input id="pDraw" value="' + node.onDraw + '"></div>';
        ['pName','pEnter','pExit','pUpdate','pDraw'].forEach(id => {
          document.getElementById(id).addEventListener('input', (e) => {
            const map = {pName:'name',pEnter:'onEnter',pExit:'onExit',pUpdate:'onUpdate',pDraw:'onDraw'};
            node[map[id]] = e.target.value;
            if (id === 'pName') render();
          });
        });
      }

      function updateStatus() {
        document.getElementById('statusInfo').textContent = 'Scenes: ' + nodes.length + ' | Transitions: ' + edges.length;
      }

      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) {
          isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY; return;
        }
        const node = hitTest(e.offsetX, e.offsetY);
        if (connectMode && e.button === 0) {
          if (!connectFrom && node) { connectFrom = node; }
          else if (connectFrom && node && node !== connectFrom) {
            if (!edges.find(ed => ed.from === connectFrom.id && ed.to === node.id)) {
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
          dragNode.x = (e.offsetX - offsetX) / zoom - dragOff.x;
          dragNode.y = (e.offsetY - offsetY) / zoom - dragOff.y;
          render();
        }
      });

      canvas.addEventListener('mouseup', () => { isPanning = false; dragNode = null; });

      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const old = zoom;
        zoom *= e.deltaY < 0 ? 1.1 : 0.9;
        zoom = Math.max(0.2, Math.min(4, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / old;
        offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / old;
        render();
      }, { passive: false });

      document.getElementById('btnAdd').addEventListener('click', () => addNode());
      document.getElementById('btnConnect').addEventListener('click', () => {
        connectMode = !connectMode; connectFrom = null;
        document.getElementById('btnConnect').classList.toggle('active', connectMode);
        document.getElementById('statusMode').textContent = connectMode ? 'Mode: Connect' : 'Mode: Select';
      });
      document.getElementById('btnDelete').addEventListener('click', () => {
        if (!selectedNode) return;
        edges = edges.filter(e => e.from !== selectedNode.id && e.to !== selectedNode.id);
        nodes = nodes.filter(n => n !== selectedNode);
        selectedNode = null; showProps(null); updateStatus(); render();
      });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        for (const n of nodes) {
          lua += '  { name = "' + n.name + '"';
          if (n.onEnter) lua += ', onEnter = ' + n.onEnter;
          if (n.onExit) lua += ', onExit = ' + n.onExit;
          if (n.onUpdate) lua += ', onUpdate = ' + n.onUpdate;
          if (n.onDraw) lua += ', onDraw = ' + n.onDraw;
          const trans = edges.filter(e => e.from === n.id).map(e => {
            const target = nodes.find(nd => nd.id === e.to);
            return target ? '"' + target.name + '"' : '';
          }).filter(Boolean);
          if (trans.length) lua += ', transitions = { ' + trans.join(', ') + ' }';
          lua += ' },\\n';
        }
        lua += '}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      addNode('Title', 80, 80);
      addNode('Gameplay', 300, 80);
      addNode('GameOver', 520, 80);
      edges.push({ from: 1, to: 2 }, { from: 2, to: 3 });
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `)}};var yn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.entity","Entity Designer")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"entities.lua");break}}getHtml(){let e=R();return D(e,"Entity Designer",`
      .editor-layout {
        display: grid; grid-template-columns: 200px 1fr 220px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .entity-list { grid-row: 2; }
      .component-editor { grid-row: 2; padding: 12px; overflow-y: auto; }
      .preview-panel { grid-row: 2; border-left: 1px solid var(--border); padding: 8px; overflow-y: auto; background: var(--surface); }
      .status-bar { grid-column: 1 / -1; }
      .comp-card {
        background: var(--surface-2); border: 1px solid var(--border); border-radius: 4px;
        padding: 8px; margin-bottom: 8px;
      }
      .comp-card h4 { font-size: 12px; margin-bottom: 6px; display: flex; justify-content: space-between; align-items: center; }
      .comp-card h4 button { font-size: 10px; padding: 1px 6px; }
      .template-btn { margin: 2px; font-size: 11px; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnNewEntity">+ New Entity</button>
          <button id="btnDuplicate">Duplicate</button>
          <button id="btnDeleteEntity" class="danger">Delete</button>
          <div class="sep"></div>
          <label>Templates:</label>
          <button class="template-btn" data-tpl="player">Player</button>
          <button class="template-btn" data-tpl="enemy">Enemy</button>
          <button class="template-btn" data-tpl="pickup">Pickup</button>
          <button class="template-btn" data-tpl="projectile">Projectile</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="panel entity-list">
          <h3>Entities</h3>
          <div id="entityList"></div>
        </div>
        <div class="component-editor" id="compEditor">
          <p style="color: var(--text-dim);">Select or create an entity to begin editing.</p>
        </div>
        <div class="preview-panel">
          <h3>Preview</h3>
          <div id="previewArea" style="margin-top: 8px; text-align: center;">
            <canvas id="previewCanvas" width="180" height="180" style="border: 1px solid var(--border); border-radius: 4px;"></canvas>
          </div>
          <h3 style="margin-top: 12px;">Stats</h3>
          <div id="statsArea" style="font-size: 11px; color: var(--text-dim); margin-top: 4px;"></div>
        </div>
        <div class="status-bar"><span id="statusInfo">Entities: 0 | Components: 0</span></div>
      </div>
    `,`
      const COMPONENT_DEFS = {
        Transform: { x: 0, y: 0, rotation: 0, scaleX: 1, scaleY: 1 },
        Sprite: { image: '', width: 32, height: 32, color: '#ffffff' },
        Physics: { bodyType: 'dynamic', mass: 1, friction: 0.3, restitution: 0.2 },
        Collider: { shape: 'rectangle', width: 32, height: 32, isSensor: false },
        AI: { behavior: 'idle', speed: 100, detectionRange: 200 },
        Health: { maxHp: 100, currentHp: 100, invincible: false },
        Custom: { key: '', value: '' }
      };

      const TEMPLATES = {
        player: { name: 'Player', components: { Transform: {...COMPONENT_DEFS.Transform}, Sprite: {...COMPONENT_DEFS.Sprite, width: 32, height: 48, color: '#4ec9b0'}, Physics: {...COMPONENT_DEFS.Physics}, Collider: {...COMPONENT_DEFS.Collider, height: 48}, Health: {...COMPONENT_DEFS.Health} }},
        enemy: { name: 'Enemy', components: { Transform: {...COMPONENT_DEFS.Transform}, Sprite: {...COMPONENT_DEFS.Sprite, color: '#f44336'}, Physics: {...COMPONENT_DEFS.Physics}, Collider: {...COMPONENT_DEFS.Collider}, AI: {...COMPONENT_DEFS.AI, behavior: 'chase'}, Health: {...COMPONENT_DEFS.Health, maxHp: 50, currentHp: 50} }},
        pickup: { name: 'Pickup', components: { Transform: {...COMPONENT_DEFS.Transform}, Sprite: {...COMPONENT_DEFS.Sprite, width: 16, height: 16, color: '#ffeb3b'}, Collider: {...COMPONENT_DEFS.Collider, width: 16, height: 16, isSensor: true} }},
        projectile: { name: 'Projectile', components: { Transform: {...COMPONENT_DEFS.Transform}, Sprite: {...COMPONENT_DEFS.Sprite, width: 8, height: 8, color: '#ff9800'}, Physics: {...COMPONENT_DEFS.Physics, mass: 0.1}, Collider: {...COMPONENT_DEFS.Collider, width: 8, height: 8} }}
      };

      let entities = [], selectedIdx = -1;

      function createEntity(name, comps) {
        entities.push({ name: name || 'Entity' + entities.length, components: comps || { Transform: {...COMPONENT_DEFS.Transform} } });
        selectedIdx = entities.length - 1;
        refreshAll();
      }

      function refreshList() {
        const el = document.getElementById('entityList');
        el.innerHTML = '';
        entities.forEach((ent, i) => {
          const div = document.createElement('div');
          div.className = 'list-item' + (i === selectedIdx ? ' selected' : '');
          div.textContent = ent.name;
          div.addEventListener('click', () => { selectedIdx = i; refreshAll(); });
          el.appendChild(div);
        });
      }

      function refreshEditor() {
        const el = document.getElementById('compEditor');
        if (selectedIdx < 0 || selectedIdx >= entities.length) {
          el.innerHTML = '<p style="color:var(--text-dim);">Select or create an entity.</p>';
          return;
        }
        const ent = entities[selectedIdx];
        let html = '<div class="field"><label>Entity Name</label><input id="entName" value="' + ent.name + '"></div>';
        html += '<div style="margin: 8px 0;"><label>Add Component: </label><select id="addComp"><option value="">Choose...</option>';
        for (const k in COMPONENT_DEFS) {
          if (!ent.components[k]) html += '<option value="' + k + '">' + k + '</option>';
        }
        html += '</select></div>';
        for (const [name, data] of Object.entries(ent.components)) {
          html += '<div class="comp-card"><h4>' + name + ' <button data-remove="' + name + '">x</button></h4>';
          for (const [key, val] of Object.entries(data)) {
            const inputType = typeof val === 'boolean' ? 'checkbox' : typeof val === 'number' ? 'number' : 'text';
            if (inputType === 'checkbox') {
              html += '<div class="field-row"><input type="checkbox" data-comp="' + name + '" data-key="' + key + '" ' + (val ? 'checked' : '') + '><label>' + key + '</label></div>';
            } else {
              html += '<div class="field-row"><label style="width:80px">' + key + '</label><input type="' + inputType + '" data-comp="' + name + '" data-key="' + key + '" value="' + val + '" style="flex:1"></div>';
            }
          }
          html += '</div>';
        }
        el.innerHTML = html;
        document.getElementById('entName').addEventListener('input', (e) => { ent.name = e.target.value; refreshList(); });
        document.getElementById('addComp').addEventListener('change', (e) => {
          if (e.target.value && COMPONENT_DEFS[e.target.value]) {
            ent.components[e.target.value] = {...COMPONENT_DEFS[e.target.value]};
            refreshAll();
          }
        });
        el.querySelectorAll('[data-remove]').forEach(btn => {
          btn.addEventListener('click', (e) => { delete ent.components[e.target.dataset.remove]; refreshAll(); });
        });
        el.querySelectorAll('[data-comp]').forEach(inp => {
          inp.addEventListener('input', (e) => {
            const comp = e.target.dataset.comp, key = e.target.dataset.key;
            const orig = COMPONENT_DEFS[comp] && COMPONENT_DEFS[comp][key];
            if (e.target.type === 'checkbox') ent.components[comp][key] = e.target.checked;
            else if (typeof orig === 'number') ent.components[comp][key] = parseFloat(e.target.value) || 0;
            else ent.components[comp][key] = e.target.value;
            refreshPreview();
          });
        });
      }

      function refreshPreview() {
        const canvas = document.getElementById('previewCanvas');
        const ctx = canvas.getContext('2d');
        ctx.clearRect(0, 0, 180, 180);
        if (selectedIdx < 0) return;
        const ent = entities[selectedIdx];
        const sprite = ent.components.Sprite;
        if (sprite) {
          ctx.fillStyle = sprite.color || '#ccc';
          ctx.fillRect(90 - sprite.width/2, 90 - sprite.height/2, sprite.width, sprite.height);
        }
        const collider = ent.components.Collider;
        if (collider) {
          ctx.strokeStyle = collider.isSensor ? '#ffeb3b' : '#4caf50';
          ctx.lineWidth = 1; ctx.setLineDash([3, 3]);
          ctx.strokeRect(90 - collider.width/2, 90 - collider.height/2, collider.width, collider.height);
          ctx.setLineDash([]);
        }
        const stats = document.getElementById('statsArea');
        const compCount = Object.keys(ent.components).length;
        stats.innerHTML = 'Components: ' + compCount + '<br>Has Physics: ' + (ent.components.Physics ? 'Yes' : 'No') + '<br>Has AI: ' + (ent.components.AI ? 'Yes' : 'No');
        document.getElementById('statusInfo').textContent = 'Entities: ' + entities.length + ' | Components: ' + compCount;
      }

      function refreshAll() { refreshList(); refreshEditor(); refreshPreview(); }

      document.getElementById('btnNewEntity').addEventListener('click', () => createEntity());
      document.getElementById('btnDuplicate').addEventListener('click', () => {
        if (selectedIdx < 0) return;
        const src = entities[selectedIdx];
        createEntity(src.name + '_copy', JSON.parse(JSON.stringify(src.components)));
      });
      document.getElementById('btnDeleteEntity').addEventListener('click', () => {
        if (selectedIdx < 0) return;
        entities.splice(selectedIdx, 1);
        selectedIdx = Math.min(selectedIdx, entities.length - 1);
        refreshAll();
      });
      document.querySelectorAll('[data-tpl]').forEach(btn => {
        btn.addEventListener('click', (e) => {
          const tpl = TEMPLATES[e.target.dataset.tpl];
          if (tpl) createEntity(tpl.name, JSON.parse(JSON.stringify(tpl.components)));
        });
      });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = '-- Entity factory functions\\nlocal entities = {}\\n\\n';
        for (const ent of entities) {
          lua += 'function entities.create' + ent.name.replace(/[^a-zA-Z0-9]/g,'') + '(x, y)\\n';
          lua += '  local e = lurek.entity.spawn()\\n';
          for (const [comp, data] of Object.entries(ent.components)) {
            lua += '  lurek.entity.addComponent(e, "' + comp.toLowerCase() + '", {\\n';
            for (const [k, v] of Object.entries(data)) {
              if (typeof v === 'string') lua += '    ' + k + ' = "' + v + '",\\n';
              else if (typeof v === 'boolean') lua += '    ' + k + ' = ' + v + ',\\n';
              else lua += '    ' + k + ' = ' + v + ',\\n';
            }
            lua += '  })\\n';
          }
          lua += '  return e\\nend\\n\\n';
        }
        lua += 'return entities\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      refreshAll();
    `)}};var bn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.pixelArt","Pixel Art Editor")}handleMessage(e){switch(e.type){case"exportPng":this.exportFile(e.content,"sprite.png","PNG Image","png");break}}getHtml(){let e=R();return D(e,"Pixel Art Editor",`
      .editor-layout {
        display: grid; grid-template-columns: 48px 1fr 180px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .tool-sidebar { grid-row: 2; background: var(--surface); border-right: 1px solid var(--border); display: flex; flex-direction: column; align-items: center; padding: 4px; gap: 2px; }
      .tool-sidebar button { width: 36px; height: 36px; font-size: 16px; padding: 0; display: flex; align-items: center; justify-content: center; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: #111; }
      .right-panel { grid-row: 2; border-left: 1px solid var(--border); overflow-y: auto; padding: 8px; background: var(--surface); }
      .status-bar { grid-column: 1 / -1; }
      .color-display { display: flex; gap: 4px; margin-bottom: 8px; }
      .color-swatch { width: 32px; height: 32px; border: 2px solid var(--border); border-radius: 3px; cursor: pointer; }
      .color-swatch.active { border-color: var(--accent); }
      .pico-palette { display: grid; grid-template-columns: repeat(4, 1fr); gap: 2px; }
      .pico-palette div { aspect-ratio: 1; cursor: pointer; border-radius: 2px; border: 1px solid transparent; }
      .pico-palette div:hover { border-color: var(--text); }
      .pico-palette div.selected { border-color: var(--accent); border-width: 2px; }
      .layer-item { display: flex; align-items: center; gap: 4px; padding: 2px 4px; font-size: 11px; cursor: pointer; border-radius: 2px; }
      .layer-item:hover { background: var(--surface-2); }
      .layer-item.sel { background: var(--selection); }
      .frame-strip { display: flex; gap: 4px; overflow-x: auto; }
      .frame-thumb { width: 40px; height: 40px; border: 1px solid var(--border); cursor: pointer; border-radius: 2px; background: #111; }
      .frame-thumb.sel { border-color: var(--accent); }
      .preview-box { border: 1px solid var(--border); border-radius: 4px; background: #111; image-rendering: pixelated; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <label>Size:</label>
          <select id="sizeSelect">
            <option value="8">8x8</option><option value="16" selected>16x16</option>
            <option value="32">32x32</option><option value="64">64x64</option>
          </select>
          <div class="sep"></div>
          <button id="btnUndo">Undo</button>
          <button id="btnClear" class="danger">Clear</button>
          <div class="sep"></div>
          <button id="btnExport">Export PNG</button>
        </div>
        <div class="tool-sidebar" id="tools">
          <button class="active" data-tool="pen" title="Pen">&#9998;</button>
          <button data-tool="eraser" title="Eraser">&#9003;</button>
          <button data-tool="bucket" title="Bucket Fill">&#9636;</button>
          <button data-tool="rect" title="Rectangle">&#9645;</button>
          <button data-tool="line" title="Line">&#9585;</button>
          <button data-tool="pick" title="Color Pick">&#128270;</button>
        </div>
        <div class="canvas-area"><canvas id="artCanvas"></canvas></div>
        <div class="right-panel">
          <h3>Color</h3>
          <div class="color-display">
            <div class="color-swatch active" id="leftColor" title="Left click color"></div>
            <div class="color-swatch" id="rightColor" title="Right click color"></div>
          </div>
          <div class="field"><label>Hex</label><input id="hexInput" value="#000000" style="width:100%"></div>
          <div class="section" style="margin-top: 8px;">
            <h3>PICO-8 Palette</h3>
            <div class="pico-palette" id="palette"></div>
          </div>
          <div class="section" style="margin-top: 12px;">
            <h3>Layers</h3>
            <button id="btnAddLayer" style="font-size: 11px; width: 100%; margin-bottom: 4px;">+ Layer</button>
            <div id="layerList"></div>
          </div>
          <div class="section" style="margin-top: 12px;">
            <h3>Frames</h3>
            <div class="frame-strip" id="frameStrip"></div>
            <div style="margin-top: 4px; display: flex; gap: 4px;">
              <button id="btnAddFrame" style="flex:1; font-size: 11px;">+ Frame</button>
              <button id="btnPlay" style="flex:1; font-size: 11px;">&#9654; Play</button>
            </div>
          </div>
          <div class="section" style="margin-top: 12px;">
            <h3>Preview</h3>
            <canvas id="previewCanvas" class="preview-box" width="64" height="64" style="width: 100%;"></canvas>
          </div>
        </div>
        <div class="status-bar">
          <span id="statusPos">Pos: 0, 0</span>
          <span id="statusTool">Tool: Pen</span>
          <span id="statusSize">16x16</span>
        </div>
      </div>
    `,`
      const PICO8 = [
        '#000000','#1d2b53','#7e2553','#008751','#ab5236','#5f574f','#c2c3c7','#fff1e8',
        '#ff004d','#ffa300','#ffec27','#00e436','#29adff','#83769c','#ff77a8','#ffccaa'
      ];

      const canvas = document.getElementById('artCanvas');
      const ctx = canvas.getContext('2d');
      const previewCanvas = document.getElementById('previewCanvas');
      const previewCtx = previewCanvas.getContext('2d');

      let gridSize = 16, currentTool = 'pen';
      let leftColor = '#000000', rightColor = '#ffffff';
      let layers = [{ name: 'Layer 0', visible: true, data: null }];
      let currentLayer = 0;
      let frames = [null]; // frame 0 = default
      let currentFrame = 0, playing = false, animTimer = null;
      let history = [];
      let offsetX = 0, offsetY = 0, zoom = 16;
      let isPanning = false, panSX = 0, panSY = 0;
      let isDrawing = false, lineStartX = -1, lineStartY = -1;

      function initData() {
        for (const l of layers) l.data = new Array(gridSize * gridSize).fill(null);
        frames = [null]; currentFrame = 0;
      }
      initData();

      function saveHistory() {
        history.push(JSON.parse(JSON.stringify(layers.map(l => l.data))));
        if (history.length > 50) history.shift();
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight;
        render();
      }

      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.save(); ctx.translate(offsetX, offsetY);
        const pxSize = zoom;

        // Checkerboard background
        for (let y = 0; y < gridSize; y++) {
          for (let x = 0; x < gridSize; x++) {
            ctx.fillStyle = ((x + y) % 2 === 0) ? '#2a2a2a' : '#222';
            ctx.fillRect(x * pxSize, y * pxSize, pxSize, pxSize);
          }
        }

        // Layers
        for (const l of layers) {
          if (!l.visible) continue;
          for (let y = 0; y < gridSize; y++) {
            for (let x = 0; x < gridSize; x++) {
              const c = l.data[y * gridSize + x];
              if (c) { ctx.fillStyle = c; ctx.fillRect(x * pxSize, y * pxSize, pxSize, pxSize); }
            }
          }
        }

        // Grid
        ctx.strokeStyle = 'rgba(255,255,255,0.05)';
        ctx.lineWidth = 0.5;
        for (let x = 0; x <= gridSize; x++) { ctx.beginPath(); ctx.moveTo(x * pxSize, 0); ctx.lineTo(x * pxSize, gridSize * pxSize); ctx.stroke(); }
        for (let y = 0; y <= gridSize; y++) { ctx.beginPath(); ctx.moveTo(0, y * pxSize); ctx.lineTo(gridSize * pxSize, y * pxSize); ctx.stroke(); }
        ctx.restore();

        // Preview
        previewCtx.clearRect(0, 0, 64, 64);
        const s = 64 / gridSize;
        for (const l of layers) {
          if (!l.visible) continue;
          for (let y = 0; y < gridSize; y++)
            for (let x = 0; x < gridSize; x++) {
              const c = l.data[y * gridSize + x];
              if (c) { previewCtx.fillStyle = c; previewCtx.fillRect(x * s, y * s, s, s); }
            }
        }
      }

      function screenToPixel(sx, sy) {
        return { x: Math.floor((sx - offsetX) / zoom), y: Math.floor((sy - offsetY) / zoom) };
      }

      function setPixel(x, y, color) {
        if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
          layers[currentLayer].data[y * gridSize + x] = color;
        }
      }

      function getPixel(x, y) {
        if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) return layers[currentLayer].data[y * gridSize + x];
        return undefined;
      }

      function floodFill(x, y, target, fill) {
        if (target === fill) return;
        const stack = [[x, y]];
        while (stack.length) {
          const [cx, cy] = stack.pop();
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
        }
      }

      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) {
          isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY; return;
        }
        if (e.button === 0 || e.button === 2) {
          saveHistory(); isDrawing = true;
          const { x, y } = screenToPixel(e.offsetX, e.offsetY);
          if (currentTool === 'line' || currentTool === 'rect') { lineStartX = x; lineStartY = y; }
          else { applyTool(x, y, e.button); render(); }
        }
      });

      canvas.addEventListener('mousemove', (e) => {
        const { x, y } = screenToPixel(e.offsetX, e.offsetY);
        document.getElementById('statusPos').textContent = 'Pos: ' + x + ', ' + y;
        if (isPanning) { offsetX = e.clientX - panSX; offsetY = e.clientY - panSY; render(); return; }
        if (isDrawing && (currentTool === 'pen' || currentTool === 'eraser')) { applyTool(x, y, e.buttons & 2 ? 2 : 0); render(); }
      });

      canvas.addEventListener('mouseup', (e) => {
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

      // Palette
      const paletteEl = document.getElementById('palette');
      PICO8.forEach((c, i) => {
        const div = document.createElement('div');
        div.style.background = c; div.title = c;
        div.addEventListener('click', () => { leftColor = c; updateColorDisplay(); });
        div.addEventListener('contextmenu', (ev) => { ev.preventDefault(); rightColor = c; updateColorDisplay(); });
        paletteEl.appendChild(div);
      });

      function updateColorDisplay() {
        document.getElementById('leftColor').style.background = leftColor;
        document.getElementById('rightColor').style.background = rightColor;
        document.getElementById('hexInput').value = leftColor;
      }
      updateColorDisplay();

      document.getElementById('hexInput').addEventListener('change', (e) => {
        if (/^#[0-9a-fA-F]{6}$/.test(e.target.value)) { leftColor = e.target.value; updateColorDisplay(); }
      });

      // Tools
      document.getElementById('tools').addEventListener('click', (e) => {
        const btn = e.target.closest('[data-tool]');
        if (!btn) return;
        document.getElementById('tools').querySelectorAll('button').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentTool = btn.dataset.tool;
        document.getElementById('statusTool').textContent = 'Tool: ' + currentTool;
      });

      // Size
      document.getElementById('sizeSelect').addEventListener('change', (e) => {
        gridSize = parseInt(e.target.value);
        initData(); refreshLayers(); refreshFrames();
        offsetX = 0; offsetY = 0; zoom = Math.max(2, Math.floor(256 / gridSize));
        document.getElementById('statusSize').textContent = gridSize + 'x' + gridSize;
        resizeCanvas();
      });

      // Layers
      function refreshLayers() {
        const el = document.getElementById('layerList');
        el.innerHTML = '';
        layers.forEach((l, i) => {
          const div = document.createElement('div');
          div.className = 'layer-item' + (i === currentLayer ? ' sel' : '');
          div.innerHTML = '<input type="checkbox" ' + (l.visible ? 'checked' : '') + '> ' + l.name;
          div.querySelector('input').addEventListener('change', (ev) => { l.visible = ev.target.checked; render(); });
          div.addEventListener('click', (ev) => { if (ev.target.tagName !== 'INPUT') { currentLayer = i; refreshLayers(); } });
          el.appendChild(div);
        });
      }
      document.getElementById('btnAddLayer').addEventListener('click', () => {
        layers.push({ name: 'Layer ' + layers.length, visible: true, data: new Array(gridSize * gridSize).fill(null) });
        currentLayer = layers.length - 1; refreshLayers();
      });
      refreshLayers();

      // Frames
      function refreshFrames() {
        const el = document.getElementById('frameStrip');
        el.innerHTML = '';
        frames.forEach((_, i) => {
          const div = document.createElement('div');
          div.className = 'frame-thumb' + (i === currentFrame ? ' sel' : '');
          div.textContent = i;
          div.style.display = 'flex'; div.style.alignItems = 'center'; div.style.justifyContent = 'center';
          div.style.color = 'var(--text-dim)'; div.style.fontSize = '10px';
          div.addEventListener('click', () => { currentFrame = i; refreshFrames(); });
          el.appendChild(div);
        });
      }
      document.getElementById('btnAddFrame').addEventListener('click', () => {
        frames.push(JSON.parse(JSON.stringify(layers.map(l => l.data))));
        currentFrame = frames.length - 1; refreshFrames();
      });
      document.getElementById('btnPlay').addEventListener('click', () => {
        playing = !playing;
        document.getElementById('btnPlay').textContent = playing ? '\\u25A0 Stop' : '\\u25B6 Play';
        if (playing && frames.length > 1) {
          let fi = 0;
          animTimer = setInterval(() => {
            fi = (fi + 1) % frames.length;
            currentFrame = fi; refreshFrames(); render();
          }, 150);
        } else { clearInterval(animTimer); }
      });
      refreshFrames();

      // Undo
      document.getElementById('btnUndo').addEventListener('click', () => {
        if (history.length === 0) return;
        const prev = history.pop();
        layers.forEach((l, i) => { l.data = prev[i] || new Array(gridSize * gridSize).fill(null); });
        render();
      });

      // Clear
      document.getElementById('btnClear').addEventListener('click', () => {
        saveHistory();
        layers[currentLayer].data = new Array(gridSize * gridSize).fill(null);
        render();
      });

      // Export
      document.getElementById('btnExport').addEventListener('click', () => {
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
        vscode.postMessage({ type: 'exportPng', content: tmpCanvas.toDataURL('image/png') });
      });

      // Center canvas
      offsetX = 50; offsetY = 50;
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `)}};var xn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.particle","Particle Designer")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"particles.lua");break}}getHtml(){let e=R();return D(e,"Particle Designer",`
      .editor-layout {
        display: grid; grid-template-columns: 180px 1fr 240px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .preset-panel { grid-row: 2; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: #111; }
      .params-panel { grid-row: 2; border-left: 1px solid var(--border); padding: 8px; overflow-y: auto; background: var(--surface); }
      .status-bar { grid-column: 1 / -1; }
      .preset-item { padding: 6px 8px; cursor: pointer; border-radius: 3px; font-size: 12px; }
      .preset-item:hover { background: var(--surface-2); }
      .preset-item.selected { background: var(--selection); }
      .slider-row { display: flex; align-items: center; gap: 6px; margin-bottom: 4px; }
      .slider-row label { font-size: 11px; width: 70px; color: var(--text-dim); }
      .slider-row input[type=range] { flex: 1; }
      .slider-row .val { font-size: 11px; width: 40px; text-align: right; }
      .color-row { display: flex; align-items: center; gap: 6px; margin-bottom: 4px; }
      .color-row label { font-size: 11px; width: 70px; color: var(--text-dim); }
      .color-row input[type=color] { width: 32px; height: 24px; border: none; background: none; cursor: pointer; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnReset">Reset</button>
          <button id="btnPause">Pause</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="panel preset-panel">
          <h3>Presets</h3>
          <div id="presetList"></div>
        </div>
        <div class="canvas-area"><canvas id="particleCanvas"></canvas></div>
        <div class="params-panel">
          <h3>Parameters</h3>
          <div id="paramControls"></div>
          <h3 style="margin-top: 12px;">Colors</h3>
          <div id="colorControls"></div>
        </div>
        <div class="status-bar">
          <span id="statusParticles">Particles: 0</span>
          <span id="statusFps">FPS: 60</span>
        </div>
      </div>
    `,`
      const canvas = document.getElementById('particleCanvas');
      const ctx = canvas.getContext('2d');
      let paused = false;

      const PRESETS = {
        Fire: { max: 200, rate: 40, speed: 80, lifetime: 1.0, direction: -90, spread: 30, sizeMin: 2, sizeMax: 6, gravityX: 0, gravityY: -20, colorStart: '#ff4400', colorMid: '#ff8800', colorEnd: '#ffcc00' },
        Smoke: { max: 100, rate: 15, speed: 30, lifetime: 2.0, direction: -90, spread: 20, sizeMin: 4, sizeMax: 12, gravityX: 0, gravityY: -10, colorStart: '#666666', colorMid: '#888888', colorEnd: '#aaaaaa' },
        Sparks: { max: 150, rate: 50, speed: 200, lifetime: 0.5, direction: -90, spread: 180, sizeMin: 1, sizeMax: 3, gravityX: 0, gravityY: 100, colorStart: '#ffee00', colorMid: '#ff8800', colorEnd: '#ff4400' },
        Snow: { max: 300, rate: 20, speed: 40, lifetime: 4.0, direction: 90, spread: 40, sizeMin: 2, sizeMax: 4, gravityX: 10, gravityY: 20, colorStart: '#ffffff', colorMid: '#ddddff', colorEnd: '#bbbbff' },
        Rain: { max: 400, rate: 80, speed: 300, lifetime: 1.0, direction: 100, spread: 5, sizeMin: 1, sizeMax: 2, gravityX: 0, gravityY: 200, colorStart: '#6699cc', colorMid: '#4488bb', colorEnd: '#336699' },
        Burst: { max: 100, rate: 100, speed: 150, lifetime: 0.8, direction: 0, spread: 180, sizeMin: 2, sizeMax: 5, gravityX: 0, gravityY: 50, colorStart: '#ff0055', colorMid: '#ff44aa', colorEnd: '#ffaaff' },
        Magic: { max: 80, rate: 10, speed: 50, lifetime: 1.5, direction: -90, spread: 360, sizeMin: 2, sizeMax: 5, gravityX: 0, gravityY: -5, colorStart: '#aa44ff', colorMid: '#4488ff', colorEnd: '#44ffaa' },
        Hearts: { max: 30, rate: 5, speed: 40, lifetime: 2.0, direction: -90, spread: 30, sizeMin: 4, sizeMax: 8, gravityX: 0, gravityY: -15, colorStart: '#ff2266', colorMid: '#ff6699', colorEnd: '#ffaacc' },
        Confetti: { max: 200, rate: 30, speed: 120, lifetime: 2.0, direction: -60, spread: 120, sizeMin: 3, sizeMax: 6, gravityX: 0, gravityY: 80, colorStart: '#ff4444', colorMid: '#44ff44', colorEnd: '#4444ff' },
        Firefly: { max: 40, rate: 3, speed: 20, lifetime: 3.0, direction: 0, spread: 360, sizeMin: 2, sizeMax: 4, gravityX: 0, gravityY: -5, colorStart: '#aaff44', colorMid: '#88cc22', colorEnd: '#446600' },
        Bubbles: { max: 60, rate: 8, speed: 30, lifetime: 3.0, direction: -90, spread: 20, sizeMin: 3, sizeMax: 8, gravityX: 0, gravityY: -20, colorStart: '#88ccff', colorMid: '#aaddff', colorEnd: '#cceeff' },
        Dust: { max: 80, rate: 10, speed: 15, lifetime: 2.5, direction: 0, spread: 360, sizeMin: 1, sizeMax: 3, gravityX: 5, gravityY: -2, colorStart: '#aa9977', colorMid: '#886644', colorEnd: '#664422' }
      };

      let cfg = { ...PRESETS.Fire };
      let particles = [];
      let emitAccum = 0;

      const PARAM_DEFS = [
        { key: 'max', label: 'Max', min: 1, max: 1000, step: 1 },
        { key: 'rate', label: 'Rate', min: 1, max: 200, step: 1 },
        { key: 'speed', label: 'Speed', min: 1, max: 500, step: 1 },
        { key: 'lifetime', label: 'Lifetime', min: 0.1, max: 10, step: 0.1 },
        { key: 'direction', label: 'Direction', min: -180, max: 180, step: 1 },
        { key: 'spread', label: 'Spread', min: 0, max: 360, step: 1 },
        { key: 'sizeMin', label: 'Size Min', min: 1, max: 20, step: 1 },
        { key: 'sizeMax', label: 'Size Max', min: 1, max: 40, step: 1 },
        { key: 'gravityX', label: 'Gravity X', min: -200, max: 200, step: 1 },
        { key: 'gravityY', label: 'Gravity Y', min: -200, max: 200, step: 1 },
      ];

      function buildControls() {
        const el = document.getElementById('paramControls');
        el.innerHTML = '';
        for (const p of PARAM_DEFS) {
          const row = document.createElement('div');
          row.className = 'slider-row';
          row.innerHTML = '<label>' + p.label + '</label><input type="range" min="' + p.min + '" max="' + p.max + '" step="' + p.step + '" value="' + cfg[p.key] + '" data-key="' + p.key + '"><span class="val">' + cfg[p.key] + '</span>';
          el.appendChild(row);
          row.querySelector('input').addEventListener('input', (e) => {
            cfg[p.key] = parseFloat(e.target.value);
            row.querySelector('.val').textContent = e.target.value;
          });
        }
        const cel = document.getElementById('colorControls');
        cel.innerHTML = '';
        for (const ck of ['colorStart', 'colorMid', 'colorEnd']) {
          const row = document.createElement('div');
          row.className = 'color-row';
          const label = ck.replace('color', '');
          row.innerHTML = '<label>' + label + '</label><input type="color" value="' + cfg[ck] + '" data-key="' + ck + '">';
          cel.appendChild(row);
          row.querySelector('input').addEventListener('input', (e) => { cfg[ck] = e.target.value; });
        }
      }

      // Presets list
      const presetList = document.getElementById('presetList');
      let activePreset = 'Fire';
      for (const name of Object.keys(PRESETS)) {
        const div = document.createElement('div');
        div.className = 'preset-item' + (name === activePreset ? ' selected' : '');
        div.textContent = name;
        div.addEventListener('click', () => {
          activePreset = name;
          cfg = { ...PRESETS[name] };
          particles = []; emitAccum = 0;
          presetList.querySelectorAll('.preset-item').forEach(d => d.classList.remove('selected'));
          div.classList.add('selected');
          buildControls();
        });
        presetList.appendChild(div);
      }

      function hexToRgb(hex) {
        const r = parseInt(hex.slice(1,3), 16), g = parseInt(hex.slice(3,5), 16), b = parseInt(hex.slice(5,7), 16);
        return { r, g, b };
      }

      function lerpColor(c1, c2, t) {
        const a = hexToRgb(c1), b = hexToRgb(c2);
        const r = Math.round(a.r + (b.r - a.r) * t);
        const g = Math.round(a.g + (b.g - a.g) * t);
        const bl = Math.round(a.b + (b.b - a.b) * t);
        return 'rgb(' + r + ',' + g + ',' + bl + ')';
      }

      function emitParticle(cx, cy) {
        const angle = (cfg.direction + (Math.random() - 0.5) * cfg.spread) * Math.PI / 180;
        const speed = cfg.speed * (0.8 + Math.random() * 0.4);
        particles.push({
          x: cx, y: cy, vx: Math.cos(angle) * speed, vy: Math.sin(angle) * speed,
          life: 0, maxLife: cfg.lifetime * (0.8 + Math.random() * 0.4),
          size: cfg.sizeMin + Math.random() * (cfg.sizeMax - cfg.sizeMin)
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
          document.getElementById('statusFps').textContent = 'FPS: ' + frameCount;
          frameCount = 0; fpsTimer = 0;
        }

        const cx = canvas.width / 2, cy = canvas.height / 2;

        // Emit
        emitAccum += cfg.rate * dt;
        while (emitAccum >= 1 && particles.length < cfg.max) {
          emitParticle(cx, cy); emitAccum--;
        }

        // Update particles
        for (let i = particles.length - 1; i >= 0; i--) {
          const p = particles[i];
          p.vx += cfg.gravityX * dt; p.vy += cfg.gravityY * dt;
          p.x += p.vx * dt; p.y += p.vy * dt;
          p.life += dt;
          if (p.life >= p.maxLife) { particles.splice(i, 1); }
        }

        // Render
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        for (const p of particles) {
          const t = p.life / p.maxLife;
          const color = t < 0.5 ? lerpColor(cfg.colorStart, cfg.colorMid, t * 2) : lerpColor(cfg.colorMid, cfg.colorEnd, (t - 0.5) * 2);
          const alpha = 1 - t;
          ctx.globalAlpha = alpha;
          ctx.fillStyle = color;
          ctx.beginPath();
          ctx.arc(p.x, p.y, p.size * (1 - t * 0.3), 0, Math.PI * 2);
          ctx.fill();
        }
        ctx.globalAlpha = 1;

        document.getElementById('statusParticles').textContent = 'Particles: ' + particles.length;
        requestAnimationFrame(update);
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight;
      }

      document.getElementById('btnPause').addEventListener('click', () => {
        paused = !paused;
        document.getElementById('btnPause').textContent = paused ? 'Resume' : 'Pause';
      });
      document.getElementById('btnReset').addEventListener('click', () => { particles = []; emitAccum = 0; });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        lua += '  max = ' + cfg.max + ',\\n  rate = ' + cfg.rate + ',\\n';
        lua += '  speed = ' + cfg.speed + ',\\n  lifetime = ' + cfg.lifetime + ',\\n';
        lua += '  direction = ' + cfg.direction + ',\\n  spread = ' + cfg.spread + ',\\n';
        lua += '  sizeMin = ' + cfg.sizeMin + ',\\n  sizeMax = ' + cfg.sizeMax + ',\\n';
        lua += '  gravity = { x = ' + cfg.gravityX + ', y = ' + cfg.gravityY + ' },\\n';
        lua += '  colors = {\\n';
        lua += '    start = "' + cfg.colorStart + '",\\n';
        lua += '    mid = "' + cfg.colorMid + '",\\n';
        lua += '    finish = "' + cfg.colorEnd + '"\\n';
        lua += '  }\\n}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      buildControls();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
      requestAnimationFrame(update);
    `)}};var wn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.dialog","Dialog Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"dialog.lua");break}}getHtml(){let e=R();return D(e,"Dialog Editor",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 260px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); padding: 8px; overflow-y: auto; background: var(--surface); }
      .status-bar { grid-column: 1 / -1; }
      .choice-item { display: flex; gap: 4px; margin-bottom: 3px; }
      .choice-item input { flex: 1; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAddNpc">+ NPC Node</button>
          <button id="btnAddChoice">+ Choice Node</button>
          <button id="btnAddCondition">+ Condition</button>
          <button id="btnAddAction">+ Action</button>
          <div class="sep"></div>
          <button id="btnConnect">Connect Mode</button>
          <button id="btnDelete" class="danger">Delete</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="canvas-area"><canvas id="dialogCanvas"></canvas></div>
        <div class="props-panel">
          <h3>Properties</h3>
          <div id="propsContent"><p style="color:var(--text-dim);font-size:12px;">Select a node to edit.</p></div>
        </div>
        <div class="status-bar">
          <span id="statusInfo">Nodes: 0 | Connections: 0</span>
          <span id="statusMode">Mode: Select</span>
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
      const NODE_W = 160, NODE_H = 60;

      const NODE_TYPES = {
        npc: { color: '#1e3a5f', label: 'NPC' },
        choice: { color: '#1e4a2e', label: 'Choice' },
        condition: { color: '#4a3e1e', label: 'Condition' },
        action: { color: '#4a2e1e', label: 'Action' }
      };

      function addNode(type, x, y) {
        nodes.push({
          id: nextId++, type, x: x || 100 + nodes.length * 40, y: y || 100 + nodes.length * 40,
          speaker: type === 'npc' ? 'NPC' : '', text: '', choices: type === 'choice' ? ['Yes', 'No'] : [],
          condition: type === 'condition' ? 'has_item("key")' : '',
          action: type === 'action' ? 'give_item("reward")' : ''
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

        // Edges
        for (const e of edges) {
          const from = nodes.find(n => n.id === e.from);
          const to = nodes.find(n => n.id === e.to);
          if (!from || !to) continue;
          const fx = from.x + NODE_W / 2, fy = from.y + NODE_H;
          const tx = to.x + NODE_W / 2, ty = to.y;
          ctx.beginPath(); ctx.moveTo(fx, fy);
          ctx.bezierCurveTo(fx, fy + 40, tx, ty - 40, tx, ty);
          ctx.strokeStyle = e.label ? '#4ec9b0' : '#666'; ctx.lineWidth = 2; ctx.stroke();
          // Arrow
          const angle = Math.atan2(ty - (ty - 40), tx - tx) || -Math.PI / 2;
          ctx.beginPath(); ctx.moveTo(tx, ty);
          ctx.lineTo(tx - 6, ty - 10); ctx.lineTo(tx + 6, ty - 10); ctx.closePath();
          ctx.fillStyle = e.label ? '#4ec9b0' : '#666'; ctx.fill();
          if (e.label) {
            ctx.fillStyle = '#ccc'; ctx.font = '10px sans-serif'; ctx.textAlign = 'center';
            ctx.fillText(e.label, (fx + tx) / 2, (fy + ty) / 2);
          }
        }

        // Nodes
        for (const n of nodes) {
          const nt = NODE_TYPES[n.type];
          ctx.fillStyle = nt.color;
          ctx.strokeStyle = n === selectedNode ? '#007acc' : '#3c3c3c';
          ctx.lineWidth = n === selectedNode ? 2 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.fill(); ctx.stroke();
          // Type badge
          ctx.fillStyle = 'rgba(255,255,255,0.15)';
          ctx.fillRect(n.x, n.y, NODE_W, 18);
          ctx.fillStyle = '#ccc'; ctx.font = 'bold 10px sans-serif'; ctx.textAlign = 'left';
          ctx.fillText(nt.label + (n.speaker ? ': ' + n.speaker : ''), n.x + 6, n.y + 13);
          // Text preview
          ctx.fillStyle = '#aaa'; ctx.font = '11px sans-serif'; ctx.textAlign = 'center';
          const preview = n.text ? n.text.substring(0, 22) : (n.condition || n.action || '...');
          ctx.fillText(preview, n.x + NODE_W / 2, n.y + 40);
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
        if (!node) { el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;">Select a node.</p>'; return; }
        let html = '<div class="field"><label>Type</label><span style="font-size:12px;color:var(--accent-2)">' + NODE_TYPES[node.type].label + '</span></div>';
        if (node.type === 'npc' || node.type === 'choice') {
          html += '<div class="field"><label>Speaker</label><input id="pSpeaker" value="' + node.speaker + '"></div>';
          html += '<div class="field"><label>Text</label><textarea id="pText" rows="3" style="width:100%;resize:vertical">' + node.text + '</textarea></div>';
        }
        if (node.type === 'choice') {
          html += '<div class="field"><label>Choices</label><div id="choiceList">';
          node.choices.forEach((c, i) => {
            html += '<div class="choice-item"><input value="' + c + '" data-ci="' + i + '"><button data-delc="' + i + '">x</button></div>';
          });
          html += '</div><button id="btnAddChoiceItem" style="width:100%;margin-top:4px;font-size:11px;">+ Add Choice</button></div>';
        }
        if (node.type === 'condition') {
          html += '<div class="field"><label>Condition</label><input id="pCondition" value="' + node.condition + '"></div>';
        }
        if (node.type === 'action') {
          html += '<div class="field"><label>Action</label><input id="pAction" value="' + node.action + '"></div>';
        }
        el.innerHTML = html;

        const bind = (id, key) => { const e = document.getElementById(id); if (e) e.addEventListener('input', (ev) => { node[key] = ev.target.value; render(); }); };
        bind('pSpeaker', 'speaker'); bind('pText', 'text'); bind('pCondition', 'condition'); bind('pAction', 'action');
        el.querySelectorAll('[data-ci]').forEach(inp => {
          inp.addEventListener('input', (ev) => { node.choices[parseInt(ev.target.dataset.ci)] = ev.target.value; });
        });
        el.querySelectorAll('[data-delc]').forEach(btn => {
          btn.addEventListener('click', (ev) => { node.choices.splice(parseInt(ev.target.dataset.delc), 1); showProps(node); });
        });
        const addBtn = document.getElementById('btnAddChoiceItem');
        if (addBtn) addBtn.addEventListener('click', () => { node.choices.push('Option'); showProps(node); });
      }

      function updateStatus() {
        document.getElementById('statusInfo').textContent = 'Nodes: ' + nodes.length + ' | Connections: ' + edges.length;
      }

      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) { isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY; return; }
        const node = hitTest(e.offsetX, e.offsetY);
        if (connectMode && e.button === 0) {
          if (!connectFrom && node) { connectFrom = node; }
          else if (connectFrom && node && node !== connectFrom) {
            const label = connectFrom.type === 'choice' && connectFrom.choices.length > 0 ? connectFrom.choices[edges.filter(ed => ed.from === connectFrom.id).length] || '' : '';
            edges.push({ from: connectFrom.id, to: node.id, label });
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
        if (isPanning) { offsetX = e.clientX - panSX; offsetY = e.clientY - panSY; render(); return; }
        if (dragNode) { dragNode.x = (e.offsetX - offsetX) / zoom - dragOff.x; dragNode.y = (e.offsetY - offsetY) / zoom - dragOff.y; render(); }
      });
      canvas.addEventListener('mouseup', () => { isPanning = false; dragNode = null; });

      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const old = zoom; zoom *= e.deltaY < 0 ? 1.1 : 0.9; zoom = Math.max(0.2, Math.min(4, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / old; offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / old; render();
      }, { passive: false });

      document.getElementById('btnAddNpc').addEventListener('click', () => addNode('npc'));
      document.getElementById('btnAddChoice').addEventListener('click', () => addNode('choice'));
      document.getElementById('btnAddCondition').addEventListener('click', () => addNode('condition'));
      document.getElementById('btnAddAction').addEventListener('click', () => addNode('action'));
      document.getElementById('btnConnect').addEventListener('click', () => {
        connectMode = !connectMode; connectFrom = null;
        document.getElementById('btnConnect').classList.toggle('active', connectMode);
        document.getElementById('statusMode').textContent = connectMode ? 'Mode: Connect' : 'Mode: Select';
      });
      document.getElementById('btnDelete').addEventListener('click', () => {
        if (!selectedNode) return;
        edges = edges.filter(e => e.from !== selectedNode.id && e.to !== selectedNode.id);
        nodes = nodes.filter(n => n !== selectedNode);
        selectedNode = null; showProps(null); updateStatus(); render();
      });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        for (const n of nodes) {
          lua += '  { id = ' + n.id + ', type = "' + n.type + '"';
          if (n.speaker) lua += ', speaker = "' + n.speaker + '"';
          if (n.text) lua += ', text = "' + n.text + '"';
          if (n.choices.length) lua += ', choices = { "' + n.choices.join('", "') + '" }';
          if (n.condition) lua += ', condition = "' + n.condition + '"';
          if (n.action) lua += ', action = "' + n.action + '"';
          const conns = edges.filter(e => e.from === n.id).map(e => e.to);
          if (conns.length) lua += ', next = { ' + conns.join(', ') + ' }';
          lua += ' },\\n';
        }
        lua += '}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      addNode('npc', 100, 50); nodes[0].speaker = 'Guard'; nodes[0].text = 'Halt! Who goes there?';
      addNode('choice', 100, 180); nodes[1].text = 'Response'; nodes[1].choices = ['I am a friend', 'None of your business'];
      addNode('npc', 50, 310); nodes[2].speaker = 'Guard'; nodes[2].text = 'Welcome, friend.';
      addNode('action', 250, 310); nodes[3].action = 'start_combat()';
      edges.push({ from: 1, to: 2, label: '' }, { from: 2, to: 3, label: 'Friend' }, { from: 2, to: 4, label: 'Hostile' });
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `)}};var Sn=E(require("vscode"));var kn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.database","Database Browser")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"data.lua");break;case"exportToml":this.exportToml(e.content,"data.toml");break;case"importCsv":this.importCsv();break}}async importCsv(){let e=await Sn.window.showOpenDialog({filters:{"CSV Files":["csv"],"TOML Files":["toml"]}});if(e&&e[0]){let t=await Sn.workspace.fs.readFile(e[0]),o=new globalThis.TextDecoder().decode(t);this.panel.webview.postMessage({type:"csvData",content:o,name:e[0].fsPath})}}getHtml(){let e=R();return D(e,"Database Browser",`
      .editor-layout {
        display: grid; grid-template-columns: 180px 1fr;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .table-list { grid-row: 2; }
      .data-area { grid-row: 2; overflow: auto; padding: 8px; }
      .status-bar { grid-column: 1 / -1; }
      .data-grid { width: 100%; border-collapse: collapse; font-size: 12px; }
      .data-grid th {
        background: var(--surface-2); border: 1px solid var(--border); padding: 4px 8px;
        text-align: left; cursor: pointer; user-select: none; position: sticky; top: 0;
      }
      .data-grid th:hover { background: var(--accent); }
      .data-grid td { border: 1px solid var(--border); padding: 3px 6px; }
      .data-grid tr:hover td { background: var(--surface-2); }
      .data-grid td.editing { padding: 0; }
      .data-grid td.editing input { width: 100%; border: none; background: var(--selection); color: var(--text); padding: 3px 6px; }
      .filter-row { display: flex; gap: 4px; padding: 4px; border-bottom: 1px solid var(--border); }
      .filter-row input { flex: 1; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnNewTable">+ Table</button>
          <button id="btnDeleteTable" class="danger">Delete Table</button>
          <div class="sep"></div>
          <button id="btnAddRow">+ Row</button>
          <button id="btnAddCol">+ Column</button>
          <button id="btnDeleteRow" class="danger">Del Row</button>
          <div class="sep"></div>
          <button id="btnImport">Import</button>
          <button id="btnExportLua">Export Lua</button>
          <button id="btnExportToml">Export TOML</button>
        </div>
        <div class="panel table-list">
          <h3>Tables</h3>
          <div id="tableList"></div>
        </div>
        <div class="data-area">
          <div class="filter-row"><label>Filter:</label><input id="filterInput" placeholder="column:value"></div>
          <table class="data-grid"><thead id="gridHead"></thead><tbody id="gridBody"></tbody></table>
        </div>
        <div class="status-bar">
          <span id="statusInfo">Tables: 0 | Rows: 0</span>
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
      let editingCell = null;

      function refreshTableList() {
        const el = document.getElementById('tableList');
        el.innerHTML = '';
        for (const name of Object.keys(tables)) {
          const div = document.createElement('div');
          div.className = 'list-item' + (name === currentTable ? ' selected' : '');
          div.textContent = name + ' (' + tables[name].rows.length + ')';
          div.addEventListener('click', () => { currentTable = name; selectedRow = -1; refreshAll(); });
          el.appendChild(div);
        }
      }

      function refreshGrid() {
        const t = tables[currentTable];
        if (!t) { document.getElementById('gridHead').innerHTML = ''; document.getElementById('gridBody').innerHTML = ''; return; }
        const th = document.getElementById('gridHead');
        th.innerHTML = '<tr><th>#</th>' + t.columns.map((c, i) => '<th data-col="' + i + '">' + c + ' <span style="font-size:9px;color:var(--text-dim)">(' + t.types[i] + ')</span>' + (sortCol === i ? (sortAsc ? ' &#9650;' : ' &#9660;') : '') + '</th>').join('') + '</tr>';

        th.querySelectorAll('th[data-col]').forEach(th => {
          th.addEventListener('click', () => {
            const ci = parseInt(th.dataset.col);
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
        if (filter && filter.includes(':')) {
          const [col, val] = filter.split(':').map(s => s.trim());
          const ci = t.columns.indexOf(col);
          if (ci >= 0) rows = rows.filter(r => String(r[ci]).toLowerCase().includes(val.toLowerCase()));
        }

        const tb = document.getElementById('gridBody');
        tb.innerHTML = '';
        rows.forEach((row, ri) => {
          const tr = document.createElement('tr');
          tr.innerHTML = '<td style="color:var(--text-dim)">' + ri + '</td>' + row.map((v, ci) => '<td data-r="' + ri + '" data-c="' + ci + '">' + String(v) + '</td>').join('');
          tr.addEventListener('click', () => { selectedRow = ri; });
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
            inp.focus();
            inp.addEventListener('blur', () => {
              const type = t.types[ci];
              if (type === 'number') t.rows[ri][ci] = parseFloat(inp.value) || 0;
              else if (type === 'boolean') t.rows[ri][ci] = inp.value === 'true';
              else t.rows[ri][ci] = inp.value;
              refreshGrid();
            });
            inp.addEventListener('keydown', (e) => { if (e.key === 'Enter') inp.blur(); });
          });
        });

        document.getElementById('statusInfo').textContent = 'Tables: ' + Object.keys(tables).length + ' | Rows: ' + rows.length;
      }

      function refreshAll() { refreshTableList(); refreshGrid(); }

      document.getElementById('filterInput').addEventListener('input', () => refreshGrid());

      document.getElementById('btnNewTable').addEventListener('click', () => {
        let name = 'table' + Object.keys(tables).length;
        tables[name] = { columns: ['id', 'name'], types: ['number', 'string'], rows: [] };
        currentTable = name; refreshAll();
      });
      document.getElementById('btnDeleteTable').addEventListener('click', () => {
        if (!currentTable) return;
        delete tables[currentTable];
        const keys = Object.keys(tables);
        currentTable = keys.length > 0 ? keys[0] : '';
        refreshAll();
      });
      document.getElementById('btnAddRow').addEventListener('click', () => {
        const t = tables[currentTable]; if (!t) return;
        const row = t.columns.map((_, i) => t.types[i] === 'number' ? 0 : t.types[i] === 'boolean' ? false : '');
        row[0] = t.rows.length;
        t.rows.push(row); refreshGrid();
      });
      document.getElementById('btnAddCol').addEventListener('click', () => {
        const t = tables[currentTable]; if (!t) return;
        t.columns.push('col' + t.columns.length); t.types.push('string');
        t.rows.forEach(r => r.push(''));
        refreshGrid();
      });
      document.getElementById('btnDeleteRow').addEventListener('click', () => {
        const t = tables[currentTable]; if (!t || selectedRow < 0) return;
        t.rows.splice(selectedRow, 1); selectedRow = -1; refreshGrid();
      });
      document.getElementById('btnImport').addEventListener('click', () => vscode.postMessage({ type: 'importCsv' }));

      window.addEventListener('message', (e) => {
        if (e.data.type === 'csvData') {
          const lines = e.data.content.split('\\n').filter(l => l.trim());
          if (lines.length < 2) return;
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

      document.getElementById('btnExportLua').addEventListener('click', () => {
        const t = tables[currentTable]; if (!t) return;
        let lua = 'return {\\n';
        for (const row of t.rows) {
          lua += '  { ';
          t.columns.forEach((c, i) => {
            if (typeof row[i] === 'string') lua += c + ' = "' + row[i] + '", ';
            else lua += c + ' = ' + row[i] + ', ';
          });
          lua += '},\\n';
        }
        lua += '}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });
      document.getElementById('btnExportToml').addEventListener('click', () => {
        const t = tables[currentTable]; if (!t) return;
        let toml = '# Table: ' + currentTable + '\\n\\n';
        t.rows.forEach((row, ri) => {
          toml += '[[' + currentTable + ']]\\n';
          t.columns.forEach((c, i) => {
            if (typeof row[i] === 'string') toml += c + ' = "' + row[i] + '"\\n';
            else toml += c + ' = ' + row[i] + '\\n';
          });
          toml += '\\n';
        });
        vscode.postMessage({ type: 'exportToml', content: toml });
      });

      refreshAll();
    `)}};var En=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.procMap","Procedural Map Generator")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"mapgen.lua");break}}getHtml(){let e=R();return D(e,"Procedural Map Generator",`
      .editor-layout {
        display: grid; grid-template-columns: 260px 1fr;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .pipeline-panel { grid-row: 2; overflow-y: auto; padding: 8px; background: var(--surface); border-right: 1px solid var(--border); }
      .preview-area { grid-row: 2; display: flex; align-items: center; justify-content: center; background: #111; overflow: hidden; }
      .status-bar { grid-column: 1 / -1; }
      .step-card {
        background: var(--surface-2); border: 1px solid var(--border); border-radius: 4px;
        padding: 8px; margin-bottom: 6px;
      }
      .step-card h4 { font-size: 12px; margin-bottom: 6px; display: flex; justify-content: space-between; }
      .step-card h4 button { font-size: 10px; padding: 1px 6px; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <label>Width:</label><input type="number" id="mapW" value="60" min="10" max="200" style="width:50px">
          <label>Height:</label><input type="number" id="mapH" value="40" min="10" max="200" style="width:50px">
          <label>Seed:</label><input type="number" id="seed" value="42" style="width:60px">
          <div class="sep"></div>
          <button id="btnGenerate">Generate</button>
          <button id="btnRandomSeed">Random Seed</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="pipeline-panel">
          <h3>Pipeline Steps</h3>
          <div id="stepList"></div>
          <div style="margin-top: 8px;">
            <select id="addStepSelect" style="width: 100%;">
              <option value="">+ Add Step...</option>
              <option value="fill">Fill</option>
              <option value="noise">Noise</option>
              <option value="cellular">Cellular Automata</option>
              <option value="rooms">Room Placement</option>
              <option value="corridors">Corridors</option>
            </select>
          </div>
        </div>
        <div class="preview-area"><canvas id="mapCanvas"></canvas></div>
        <div class="status-bar">
          <span id="statusInfo">Size: 60x40 | Seed: 42</span>
          <span id="statusSteps">Steps: 0</span>
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

      // Simple seeded RNG
      function mulberry32(a) {
        return function() {
          a |= 0; a = a + 0x6D2B79F5 | 0;
          var t = Math.imul(a ^ a >>> 15, 1 | a);
          t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
          return ((t ^ t >>> 14) >>> 0) / 4294967296;
        };
      }

      let rng = mulberry32(seed);

      const TILE_CHARS = { 0: '.', 1: '#', 2: '+', 3: '~' };
      const TILE_COLORS = { 0: '#2a2a2a', 1: '#4a4a4a', 2: '#3a5a3a', 3: '#2a3a5a' };

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
          case 'fill':
            mapData.fill(step.params.tile);
            break;
          case 'noise':
            for (let i = 0; i < mapData.length; i++) {
              if (rng() < step.params.density) mapData[i] = step.params.tile;
            }
            break;
          case 'cellular':
            for (let iter = 0; iter < step.params.iterations; iter++) {
              const next = [...mapData];
              for (let y = 0; y < mapH; y++) for (let x = 0; x < mapW; x++) {
                const walls = countNeighbors(x, y, 1);
                if (mapData[y * mapW + x] === 1) {
                  next[y * mapW + x] = walls >= step.params.deathLimit ? 1 : 0;
                } else {
                  next[y * mapW + x] = walls >= step.params.birthLimit ? 1 : 0;
                }
              }
              mapData = next;
            }
            break;
          case 'rooms': {
            const count = step.params.count || 6;
            const minS = step.params.minSize || 4, maxS = step.params.maxSize || 10;
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
            // Connect open areas with L-shaped corridors
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
        document.getElementById('statusInfo').textContent = 'Size: ' + mapW + 'x' + mapH + ' | Seed: ' + seed;
      }

      function renderMap() {
        const canvas = document.getElementById('mapCanvas');
        const cs = Math.min(Math.floor(canvas.parentElement.clientWidth / mapW), Math.floor(canvas.parentElement.clientHeight / mapH), 12);
        canvas.width = mapW * cs; canvas.height = mapH * cs;
        const ctx = canvas.getContext('2d');
        for (let y = 0; y < mapH; y++) for (let x = 0; x < mapW; x++) {
          ctx.fillStyle = TILE_COLORS[mapData[y * mapW + x]] || '#000';
          ctx.fillRect(x * cs, y * cs, cs, cs);
        }
      }

      function refreshStepList() {
        const el = document.getElementById('stepList');
        el.innerHTML = '';
        steps.forEach((step, i) => {
          const card = document.createElement('div');
          card.className = 'step-card';
          let paramsHtml = '';
          for (const [k, v] of Object.entries(step.params)) {
            paramsHtml += '<div class="field-row"><label style="width:70px">' + k + '</label><input type="number" data-si="' + i + '" data-pk="' + k + '" value="' + v + '" style="width:60px" step="' + (typeof v === 'number' && v < 1 ? 0.05 : 1) + '"></div>';
          }
          card.innerHTML = '<h4>' + (i + 1) + '. ' + step.type + ' <button data-del="' + i + '">x</button></h4>' + paramsHtml;
          el.appendChild(card);
          card.querySelectorAll('input[data-si]').forEach(inp => {
            inp.addEventListener('input', (e) => {
              steps[parseInt(e.target.dataset.si)].params[e.target.dataset.pk] = parseFloat(e.target.value) || 0;
            });
          });
          card.querySelector('[data-del]').addEventListener('click', (e) => {
            steps.splice(parseInt(e.target.dataset.del), 1); refreshStepList();
          });
        });
        document.getElementById('statusSteps').textContent = 'Steps: ' + steps.length;
      }

      document.getElementById('addStepSelect').addEventListener('change', (e) => {
        if (!e.target.value) return;
        const defaults = {
          fill: { tile: 1 }, noise: { density: 0.45, tile: 0 },
          cellular: { iterations: 5, birthLimit: 4, deathLimit: 3 },
          rooms: { count: 6, minSize: 4, maxSize: 10 }, corridors: {}
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
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  width = ' + mapW + ',\\n  height = ' + mapH + ',\\n  seed = ' + seed + ',\\n';
        lua += '  steps = {\\n';
        for (const s of steps) {
          lua += '    { type = "' + s.type + '"';
          for (const [k, v] of Object.entries(s.params)) lua += ', ' + k + ' = ' + v;
          lua += ' },\\n';
        }
        lua += '  },\\n  data = {\\n    ';
        for (let y = 0; y < mapH; y++) {
          lua += mapData.slice(y * mapW, (y + 1) * mapW).join(', ') + ',\\n    ';
        }
        lua += '\\n  }\\n}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      refreshStepList();
      window.addEventListener('resize', () => renderMap());
      generate();
    `)}};var Cn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.questTree","Quest / Tech Tree Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"quests.lua");break}}getHtml(){let e=R();return D(e,"Quest / Tech Tree Editor",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 240px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); padding: 8px; overflow-y: auto; background: var(--surface); }
      .status-bar { grid-column: 1 / -1; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAdd">+ Quest</button>
          <button id="btnConnect">Link Prerequisites</button>
          <button id="btnDelete" class="danger">Delete</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="canvas-area"><canvas id="questCanvas"></canvas></div>
        <div class="props-panel">
          <h3>Quest Properties</h3>
          <div id="propsContent"><p style="color:var(--text-dim);font-size:12px;">Select a quest node.</p></div>
        </div>
        <div class="status-bar">
          <span id="statusInfo">Quests: 0</span>
          <span id="statusMode">Mode: Select</span>
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
      const NODE_W = 150, NODE_H = 55;

      const STATUS_COLORS = {
        available: '#2a5a2a', locked: '#3a3a3a', completed: '#5a4a1a'
      };

      function addNode(name, x, y) {
        nodes.push({
          id: nextId++, name: name || 'Quest ' + nodes.length,
          x: x || 100 + nodes.length * 30, y: y || 100 + nodes.length * 50,
          description: '', requiredItems: '', reward: '', status: 'available'
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

        for (const e of edges) {
          const from = nodes.find(n => n.id === e.from);
          const to = nodes.find(n => n.id === e.to);
          if (!from || !to) continue;
          ctx.beginPath();
          ctx.moveTo(from.x + NODE_W / 2, from.y + NODE_H);
          ctx.lineTo(to.x + NODE_W / 2, to.y);
          ctx.strokeStyle = '#555'; ctx.lineWidth = 2; ctx.setLineDash([4, 4]); ctx.stroke(); ctx.setLineDash([]);
          const mx = (from.x + to.x + NODE_W) / 2, my = (from.y + NODE_H + to.y) / 2;
          ctx.fillStyle = '#555'; ctx.beginPath();
          ctx.moveTo(to.x + NODE_W / 2, to.y);
          ctx.lineTo(to.x + NODE_W / 2 - 5, to.y - 8);
          ctx.lineTo(to.x + NODE_W / 2 + 5, to.y - 8);
          ctx.closePath(); ctx.fill();
        }

        for (const n of nodes) {
          ctx.fillStyle = STATUS_COLORS[n.status] || STATUS_COLORS.available;
          ctx.strokeStyle = n === selectedNode ? '#007acc' : '#3c3c3c';
          ctx.lineWidth = n === selectedNode ? 2.5 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.fill(); ctx.stroke();
          // Status dot
          const dotColor = n.status === 'completed' ? '#ffd700' : n.status === 'available' ? '#4caf50' : '#666';
          ctx.fillStyle = dotColor; ctx.beginPath(); ctx.arc(n.x + 12, n.y + 14, 4, 0, Math.PI * 2); ctx.fill();
          // Name
          ctx.fillStyle = '#ccc'; ctx.font = '12px sans-serif'; ctx.textAlign = 'left';
          ctx.fillText(n.name, n.x + 22, n.y + 18);
          // Description preview
          if (n.description) {
            ctx.fillStyle = '#888'; ctx.font = '10px sans-serif';
            ctx.fillText(n.description.substring(0, 20), n.x + 8, n.y + 38);
          }
          if (n.reward) {
            ctx.fillStyle = '#ffd700'; ctx.font = '10px sans-serif';
            ctx.fillText('\\u2605 ' + n.reward, n.x + 8, n.y + 50);
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
        if (!node) { el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;">Select a quest node.</p>'; return; }
        el.innerHTML =
          '<div class="field"><label>Name</label><input id="pName" value="' + node.name + '"></div>' +
          '<div class="field"><label>Description</label><textarea id="pDesc" rows="2" style="width:100%;resize:vertical">' + node.description + '</textarea></div>' +
          '<div class="field"><label>Required Items</label><input id="pItems" value="' + node.requiredItems + '" placeholder="key, sword"></div>' +
          '<div class="field"><label>Reward</label><input id="pReward" value="' + node.reward + '" placeholder="100 gold"></div>' +
          '<div class="field"><label>Status</label><select id="pStatus"><option value="available" ' + (node.status === 'available' ? 'selected' : '') + '>Available</option><option value="locked" ' + (node.status === 'locked' ? 'selected' : '') + '>Locked</option><option value="completed" ' + (node.status === 'completed' ? 'selected' : '') + '>Completed</option></select></div>' +
          '<div class="field" style="margin-top:8px"><label>Prerequisites</label><div id="prereqList" style="font-size:11px;color:var(--text-dim)"></div></div>';

        const prereqs = edges.filter(e => e.to === node.id).map(e => nodes.find(n => n.id === e.from)).filter(Boolean);
        document.getElementById('prereqList').textContent = prereqs.length ? prereqs.map(p => p.name).join(', ') : 'None';

        const bind = (id, key) => {
          const inp = document.getElementById(id);
          if (inp) inp.addEventListener('input', (e) => { node[key] = e.target.value; render(); });
        };
        bind('pName', 'name'); bind('pDesc', 'description'); bind('pItems', 'requiredItems'); bind('pReward', 'reward');
        document.getElementById('pStatus').addEventListener('change', (e) => { node.status = e.target.value; render(); });
      }

      function updateStatus() {
        document.getElementById('statusInfo').textContent = 'Quests: ' + nodes.length + ' | Links: ' + edges.length;
      }

      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) { isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY; return; }
        const node = hitTest(e.offsetX, e.offsetY);
        if (connectMode && e.button === 0) {
          if (!connectFrom && node) { connectFrom = node; }
          else if (connectFrom && node && node !== connectFrom) {
            if (!edges.find(ed => ed.from === connectFrom.id && ed.to === node.id)) {
              edges.push({ from: connectFrom.id, to: node.id });
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
        if (isPanning) { offsetX = e.clientX - panSX; offsetY = e.clientY - panSY; render(); return; }
        if (dragNode) { dragNode.x = (e.offsetX - offsetX) / zoom - dragOff.x; dragNode.y = (e.offsetY - offsetY) / zoom - dragOff.y; render(); }
      });
      canvas.addEventListener('mouseup', () => { isPanning = false; dragNode = null; });
      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const old = zoom; zoom *= e.deltaY < 0 ? 1.1 : 0.9; zoom = Math.max(0.2, Math.min(4, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / old; offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / old; render();
      }, { passive: false });

      document.getElementById('btnAdd').addEventListener('click', () => addNode());
      document.getElementById('btnConnect').addEventListener('click', () => {
        connectMode = !connectMode; connectFrom = null;
        document.getElementById('btnConnect').classList.toggle('active', connectMode);
        document.getElementById('statusMode').textContent = connectMode ? 'Mode: Link' : 'Mode: Select';
      });
      document.getElementById('btnDelete').addEventListener('click', () => {
        if (!selectedNode) return;
        edges = edges.filter(e => e.from !== selectedNode.id && e.to !== selectedNode.id);
        nodes = nodes.filter(n => n !== selectedNode);
        selectedNode = null; showProps(null); updateStatus(); render();
      });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        for (const n of nodes) {
          lua += '  {\\n    id = ' + n.id + ',\\n    name = "' + n.name + '",\\n';
          if (n.description) lua += '    description = "' + n.description + '",\\n';
          if (n.requiredItems) lua += '    requiredItems = { "' + n.requiredItems.split(',').map(s => s.trim()).join('", "') + '" },\\n';
          if (n.reward) lua += '    reward = "' + n.reward + '",\\n';
          const prereqs = edges.filter(e => e.to === n.id).map(e => e.from);
          if (prereqs.length) lua += '    prerequisites = { ' + prereqs.join(', ') + ' },\\n';
          lua += '    status = "' + n.status + '"\\n  },\\n';
        }
        lua += '}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      addNode('Find the Key', 80, 50); nodes[0].description = 'Locate the dungeon key'; nodes[0].reward = '50 gold';
      addNode('Enter Dungeon', 80, 160); nodes[1].description = 'Enter the dark dungeon'; nodes[1].status = 'locked';
      addNode('Defeat Boss', 80, 270); nodes[2].description = 'Defeat the dragon'; nodes[2].reward = 'Dragon Sword'; nodes[2].status = 'locked';
      edges.push({ from: 1, to: 2 }, { from: 2, to: 3 });
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `)}};var Tn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.guiWidget","GUI Widget Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"gui_layout.lua");break}}getHtml(){let e=R();return D(e,"GUI Widget Editor",`
      .editor-layout {
        display: grid; grid-template-columns: 180px 1fr 220px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .hierarchy-panel { grid-row: 2; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: #111; }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); padding: 8px; overflow-y: auto; background: var(--surface); }
      .status-bar { grid-column: 1 / -1; }
      .widget-item { padding: 3px 8px; cursor: pointer; font-size: 12px; border-radius: 2px; }
      .widget-item:hover { background: var(--surface-2); }
      .widget-item.sel { background: var(--selection); }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <label>Add:</label>
          <select id="addWidget">
            <option value="">Choose widget...</option>
            <option value="Button">Button</option>
            <option value="Panel">Panel</option>
            <option value="Label">Label</option>
            <option value="ProgressBar">ProgressBar</option>
            <option value="Checkbox">Checkbox</option>
            <option value="Slider">Slider</option>
            <option value="Image">Image</option>
          </select>
          <button id="btnDelete" class="danger">Delete</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="panel hierarchy-panel">
          <h3>Hierarchy</h3>
          <div id="hierarchy"></div>
        </div>
        <div class="canvas-area"><canvas id="guiCanvas"></canvas></div>
        <div class="props-panel">
          <h3>Properties</h3>
          <div id="propsContent"><p style="color:var(--text-dim);font-size:12px;">Select a widget.</p></div>
        </div>
        <div class="status-bar">
          <span id="statusInfo">Widgets: 0</span>
          <span id="statusSel">Selected: none</span>
        </div>
      </div>
    `,`
      const canvas = document.getElementById('guiCanvas');
      const ctx = canvas.getContext('2d');
      let widgets = [], selectedIdx = -1;
      let dragWidget = null, dragOff = { x: 0, y: 0 };
      let resizing = false, resizeHandle = '';
      let nextId = 1;

      const WIDGET_DEFAULTS = {
        Button: { w: 120, h: 36, text: 'Click Me', color: '#007acc', fontSize: 14, anchor: 'topLeft' },
        Panel: { w: 200, h: 150, text: '', color: '#252526', fontSize: 12, anchor: 'topLeft' },
        Label: { w: 100, h: 24, text: 'Label', color: 'transparent', fontSize: 14, anchor: 'topLeft' },
        ProgressBar: { w: 150, h: 20, text: '', color: '#4caf50', fontSize: 10, anchor: 'topLeft', value: 0.65 },
        Checkbox: { w: 24, h: 24, text: 'Option', color: '#333', fontSize: 12, anchor: 'topLeft', checked: false },
        Slider: { w: 150, h: 20, text: '', color: '#555', fontSize: 10, anchor: 'topLeft', value: 0.5 },
        Image: { w: 64, h: 64, text: 'img', color: '#333', fontSize: 10, anchor: 'topLeft' },
      };

      function addWidget(type) {
        const d = WIDGET_DEFAULTS[type];
        widgets.push({
          id: nextId++, type, name: type + '_' + nextId,
          x: 50 + widgets.length * 20, y: 50 + widgets.length * 20,
          w: d.w, h: d.h, text: d.text, color: d.color,
          fontSize: d.fontSize, anchor: d.anchor, visible: true,
          value: d.value, checked: d.checked
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
        // Reference frame
        ctx.strokeStyle = '#333'; ctx.lineWidth = 1;
        ctx.strokeRect(20, 20, 800, 600);
        ctx.fillStyle = '#333'; ctx.font = '10px sans-serif'; ctx.textAlign = 'left';
        ctx.fillText('800x600', 22, 16);

        for (let i = 0; i < widgets.length; i++) {
          const w = widgets[i];
          if (!w.visible) continue;
          const sel = i === selectedIdx;

          ctx.fillStyle = w.color; ctx.strokeStyle = sel ? '#007acc' : '#3c3c3c';
          ctx.lineWidth = sel ? 2 : 1;

          switch (w.type) {
            case 'Button':
              ctx.beginPath(); ctx.roundRect(w.x, w.y, w.w, w.h, 4); ctx.fill(); ctx.stroke();
              ctx.fillStyle = '#fff'; ctx.font = w.fontSize + 'px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
              ctx.fillText(w.text, w.x + w.w / 2, w.y + w.h / 2);
              break;
            case 'Panel':
              ctx.fillRect(w.x, w.y, w.w, w.h); ctx.strokeRect(w.x, w.y, w.w, w.h);
              break;
            case 'Label':
              ctx.fillStyle = '#ccc'; ctx.font = w.fontSize + 'px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'top';
              ctx.fillText(w.text, w.x, w.y);
              if (sel) ctx.strokeRect(w.x - 2, w.y - 2, w.w + 4, w.h + 4);
              break;
            case 'ProgressBar':
              ctx.fillStyle = '#333'; ctx.fillRect(w.x, w.y, w.w, w.h);
              ctx.fillStyle = w.color; ctx.fillRect(w.x, w.y, w.w * (w.value || 0), w.h);
              ctx.strokeRect(w.x, w.y, w.w, w.h);
              break;
            case 'Checkbox':
              ctx.strokeRect(w.x, w.y, 18, 18);
              if (w.checked) { ctx.fillStyle = '#4ec9b0'; ctx.fillRect(w.x + 3, w.y + 3, 12, 12); }
              ctx.fillStyle = '#ccc'; ctx.font = '12px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'middle';
              ctx.fillText(w.text, w.x + 24, w.y + 9);
              break;
            case 'Slider':
              ctx.fillStyle = '#333'; ctx.fillRect(w.x, w.y + 6, w.w, 8);
              ctx.fillStyle = w.color;
              const knobX = w.x + w.w * (w.value || 0);
              ctx.beginPath(); ctx.arc(knobX, w.y + 10, 8, 0, Math.PI * 2); ctx.fill();
              if (sel) ctx.strokeRect(w.x - 2, w.y - 2, w.w + 4, w.h + 4);
              break;
            case 'Image':
              ctx.fillRect(w.x, w.y, w.w, w.h); ctx.strokeRect(w.x, w.y, w.w, w.h);
              ctx.fillStyle = '#666'; ctx.font = '10px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
              ctx.fillText('[' + w.text + ']', w.x + w.w / 2, w.y + w.h / 2);
              break;
          }

          // Selection handles
          if (sel) {
            ctx.fillStyle = '#007acc';
            const hSize = 5;
            [[w.x-hSize,w.y-hSize],[w.x+w.w,w.y-hSize],[w.x-hSize,w.y+w.h],[w.x+w.w,w.y+w.h]].forEach(([hx,hy]) => {
              ctx.fillRect(hx, hy, hSize*2, hSize*2);
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
        if (idx < 0) { el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;">Select a widget.</p>'; return; }
        const w = widgets[idx];
        let html = '<div class="field"><label>Name</label><input id="pName" value="' + w.name + '"></div>';
        html += '<div class="field-row"><label style="width:30px">X</label><input type="number" id="pX" value="' + w.x + '" style="width:60px"><label style="width:30px;margin-left:8px">Y</label><input type="number" id="pY" value="' + w.y + '" style="width:60px"></div>';
        html += '<div class="field-row"><label style="width:30px">W</label><input type="number" id="pW" value="' + w.w + '" style="width:60px"><label style="width:30px;margin-left:8px">H</label><input type="number" id="pH" value="' + w.h + '" style="width:60px"></div>';
        html += '<div class="field"><label>Text</label><input id="pText" value="' + w.text + '"></div>';
        html += '<div class="field-row"><label>Color</label><input type="color" id="pColor" value="' + (w.color.startsWith('#') ? w.color : '#333333') + '"></div>';
        html += '<div class="field"><label>Font Size</label><input type="number" id="pFont" value="' + w.fontSize + '" min="8" max="48" style="width:60px"></div>';
        html += '<div class="field"><label>Anchor</label><select id="pAnchor"><option value="topLeft">Top Left</option><option value="topRight">Top Right</option><option value="center">Center</option><option value="bottomLeft">Bottom Left</option></select></div>';
        html += '<div class="field-row"><input type="checkbox" id="pVisible" ' + (w.visible ? 'checked' : '') + '><label>Visible</label></div>';
        if (w.value !== undefined) html += '<div class="field"><label>Value</label><input type="number" id="pVal" value="' + w.value + '" min="0" max="1" step="0.05" style="width:60px"></div>';
        el.innerHTML = html;

        const setAnchor = document.getElementById('pAnchor');
        setAnchor.value = w.anchor;

        const bind = (id, key, parse) => {
          const inp = document.getElementById(id);
          if (inp) inp.addEventListener('input', (e) => { w[key] = parse ? parse(e.target.value) : e.target.value; render(); });
        };
        bind('pName', 'name'); bind('pText', 'text'); bind('pColor', 'color');
        bind('pX', 'x', parseFloat); bind('pY', 'y', parseFloat);
        bind('pW', 'w', parseFloat); bind('pH', 'h', parseFloat);
        bind('pFont', 'fontSize', parseInt);
        bind('pVal', 'value', parseFloat);
        document.getElementById('pAnchor').addEventListener('change', (e) => { w.anchor = e.target.value; });
        document.getElementById('pVisible').addEventListener('change', (e) => { w.visible = e.target.checked; render(); });
        document.getElementById('statusSel').textContent = 'Selected: ' + w.name;
      }

      function refreshHierarchy() {
        const el = document.getElementById('hierarchy');
        el.innerHTML = '';
        widgets.forEach((w, i) => {
          const div = document.createElement('div');
          div.className = 'widget-item' + (i === selectedIdx ? ' sel' : '');
          div.textContent = (w.visible ? '' : '(hidden) ') + w.type + ': ' + w.name;
          div.addEventListener('click', () => { selectedIdx = i; showProps(i); refreshHierarchy(); render(); });
          el.appendChild(div);
        });
        document.getElementById('statusInfo').textContent = 'Widgets: ' + widgets.length;
      }

      function refreshAll() { refreshHierarchy(); showProps(selectedIdx); render(); }

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
          dragWidget.x = Math.round(e.offsetX - dragOff.x);
          dragWidget.y = Math.round(e.offsetY - dragOff.y);
          render();
        }
      });
      canvas.addEventListener('mouseup', () => { if (dragWidget) { showProps(selectedIdx); } dragWidget = null; });

      document.getElementById('addWidget').addEventListener('change', (e) => {
        if (e.target.value) { addWidget(e.target.value); e.target.value = ''; }
      });
      document.getElementById('btnDelete').addEventListener('click', () => {
        if (selectedIdx >= 0) { widgets.splice(selectedIdx, 1); selectedIdx = -1; refreshAll(); }
      });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        for (const w of widgets) {
          lua += '  {\\n    type = "' + w.type + '",\\n    name = "' + w.name + '",\\n';
          lua += '    x = ' + w.x + ', y = ' + w.y + ', w = ' + w.w + ', h = ' + w.h + ',\\n';
          if (w.text) lua += '    text = "' + w.text + '",\\n';
          lua += '    color = "' + w.color + '",\\n    fontSize = ' + w.fontSize + ',\\n';
          lua += '    anchor = "' + w.anchor + '", visible = ' + w.visible + ',\\n';
          if (w.value !== undefined) lua += '    value = ' + w.value + ',\\n';
          lua += '  },\\n';
        }
        lua += '}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      addWidget('Panel'); widgets[0].x = 50; widgets[0].y = 50;
      addWidget('Button'); widgets[1].x = 80; widgets[1].y = 120;
      addWidget('Label'); widgets[2].x = 80; widgets[2].y = 80; widgets[2].text = 'Settings';
      selectedIdx = -1;
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
      refreshAll();
    `)}};var In=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.aiBehavior","AI Behavior Tree")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"behavior_tree.lua");break}}getHtml(){let e=R();return D(e,"AI Behavior Tree",`
      .editor-layout {
        display: grid; grid-template-columns: 200px 1fr 220px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .palette-panel { grid-row: 2; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); padding: 8px; overflow-y: auto; background: var(--surface); }
      .status-bar { grid-column: 1 / -1; }
      .node-group { margin-bottom: 10px; }
      .node-group h4 { font-size: 11px; color: var(--text-dim); margin-bottom: 4px; text-transform: uppercase; }
      .drag-node {
        padding: 4px 8px; font-size: 12px; cursor: grab; border-radius: 3px;
        margin-bottom: 2px; border: 1px solid var(--border);
      }
      .drag-node:hover { border-color: var(--accent); }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnClear" class="danger">Clear Tree</button>
          <div class="sep"></div>
          <button id="btnSimulate">Simulate</button>
          <button id="btnReset">Reset Status</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="panel palette-panel">
          <h3>Node Palette</h3>
          <div class="node-group">
            <h4>Composites</h4>
            <div class="drag-node" data-type="Sequence" style="background:#2a3a2a">&#9654; Sequence</div>
            <div class="drag-node" data-type="Selector" style="background:#3a3a2a">&#9654; Selector</div>
            <div class="drag-node" data-type="Parallel" style="background:#2a2a3a">&#9654; Parallel</div>
            <div class="drag-node" data-type="RandomSelector" style="background:#3a2a3a">&#9654; RandomSelector</div>
          </div>
          <div class="node-group">
            <h4>Decorators</h4>
            <div class="drag-node" data-type="Inverter" style="background:#3a2a2a">&#8635; Inverter</div>
            <div class="drag-node" data-type="Repeater" style="background:#3a2a2a">&#8635; Repeater</div>
            <div class="drag-node" data-type="Succeeder" style="background:#3a2a2a">&#8635; Succeeder</div>
            <div class="drag-node" data-type="Cooldown" style="background:#3a2a2a">&#8635; Cooldown</div>
            <div class="drag-node" data-type="Guard" style="background:#3a2a2a">&#8635; Guard</div>
          </div>
          <div class="node-group">
            <h4>Conditions</h4>
            <div class="drag-node" data-type="HasTarget" style="background:#2a2a3e">&#10003; HasTarget</div>
            <div class="drag-node" data-type="InRange" style="background:#2a2a3e">&#10003; InRange</div>
            <div class="drag-node" data-type="HealthCheck" style="background:#2a2a3e">&#10003; HealthCheck</div>
            <div class="drag-node" data-type="Custom" style="background:#2a2a3e">&#10003; Custom</div>
          </div>
          <div class="node-group">
            <h4>Actions</h4>
            <div class="drag-node" data-type="MoveTo" style="background:#2a3e2a">&#9733; MoveTo</div>
            <div class="drag-node" data-type="Attack" style="background:#2a3e2a">&#9733; Attack</div>
            <div class="drag-node" data-type="Flee" style="background:#2a3e2a">&#9733; Flee</div>
            <div class="drag-node" data-type="Patrol" style="background:#2a3e2a">&#9733; Patrol</div>
          </div>
        </div>
        <div class="canvas-area"><canvas id="btCanvas"></canvas></div>
        <div class="props-panel">
          <h3>Node Properties</h3>
          <div id="propsContent"><p style="color:var(--text-dim);font-size:12px;">Click palette to add nodes, drag on canvas to move.</p></div>
        </div>
        <div class="status-bar">
          <span id="statusInfo">Nodes: 0</span>
          <span id="statusSim">Simulation: Idle</span>
        </div>
      </div>
    `,`
      const canvas = document.getElementById('btCanvas');
      const ctx = canvas.getContext('2d');
      let nodes = [], selectedNode = null, dragNode = null, dragOff = { x: 0, y: 0 };
      let offsetX = 0, offsetY = 0, zoom = 1;
      let isPanning = false, panSX = 0, panSY = 0;
      let nextId = 1;
      const NODE_W = 120, NODE_H = 40;

      const CATEGORIES = {
        Sequence: 'composite', Selector: 'composite', Parallel: 'composite', RandomSelector: 'composite',
        Inverter: 'decorator', Repeater: 'decorator', Succeeder: 'decorator', Cooldown: 'decorator', Guard: 'decorator',
        HasTarget: 'condition', InRange: 'condition', HealthCheck: 'condition', Custom: 'condition',
        MoveTo: 'action', Attack: 'action', Flee: 'action', Patrol: 'action'
      };
      const CAT_COLORS = { composite: '#2a4a2a', decorator: '#4a2a2a', condition: '#2a2a4a', action: '#2a4a3a' };
      const STATUS_COLORS = { success: '#4caf50', failure: '#f44336', running: '#ff9800', idle: '#666' };

      function addNode(type, x, y) {
        const node = {
          id: nextId++, type, category: CATEGORIES[type] || 'action',
          x: x || canvas.width / 2 - NODE_W / 2, y: y || 60 + nodes.length * 60,
          parentId: null, status: 'idle', params: {}
        };
        if (type === 'Cooldown') node.params.duration = 2.0;
        if (type === 'Repeater') node.params.times = 3;
        if (type === 'InRange') node.params.range = 100;
        if (type === 'HealthCheck') node.params.threshold = 0.3;
        if (type === 'Custom') node.params.func = 'myCondition';
        nodes.push(node);
        // Auto-parent to selected
        if (selectedNode && (selectedNode.category === 'composite' || selectedNode.category === 'decorator')) {
          node.parentId = selectedNode.id;
          layoutTree();
        }
        selectedNode = node; showProps(node);
        updateStatus(); render();
      }

      function getChildren(parentId) {
        return nodes.filter(n => n.parentId === parentId);
      }

      function layoutTree() {
        const roots = nodes.filter(n => !n.parentId);
        let startX = 60;
        for (const root of roots) {
          startX = layoutSubtree(root, startX, 40);
          startX += 40;
        }
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

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight; render();
      }

      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.save(); ctx.translate(offsetX, offsetY); ctx.scale(zoom, zoom);

        // Draw edges
        for (const n of nodes) {
          if (!n.parentId) continue;
          const parent = nodes.find(p => p.id === n.parentId);
          if (!parent) continue;
          ctx.beginPath();
          ctx.moveTo(parent.x + NODE_W / 2, parent.y + NODE_H);
          ctx.lineTo(n.x + NODE_W / 2, n.y);
          ctx.strokeStyle = '#555'; ctx.lineWidth = 1.5; ctx.stroke();
        }

        // Draw nodes
        for (const n of nodes) {
          ctx.fillStyle = CAT_COLORS[n.category] || '#333';
          ctx.strokeStyle = n === selectedNode ? '#007acc' : '#3c3c3c';
          ctx.lineWidth = n === selectedNode ? 2 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 5); ctx.fill(); ctx.stroke();
          // Status indicator
          ctx.fillStyle = STATUS_COLORS[n.status];
          ctx.beginPath(); ctx.arc(n.x + 12, n.y + NODE_H / 2, 5, 0, Math.PI * 2); ctx.fill();
          // Label
          ctx.fillStyle = '#ccc'; ctx.font = '11px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'middle';
          ctx.fillText(n.type, n.x + 22, n.y + NODE_H / 2);
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
        if (!node) { el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;">Select a node.</p>'; return; }
        let html = '<div class="field"><label>Type</label><span style="font-size:12px;color:var(--accent-2)">' + node.type + '</span></div>';
        html += '<div class="field"><label>Category</label><span style="font-size:12px">' + node.category + '</span></div>';
        html += '<div class="field"><label>Parent</label><select id="pParent"><option value="">Root</option>';
        for (const n of nodes) {
          if (n.id === node.id) continue;
          if (n.category === 'composite' || n.category === 'decorator') {
            html += '<option value="' + n.id + '" ' + (node.parentId === n.id ? 'selected' : '') + '>' + n.type + ' #' + n.id + '</option>';
          }
        }
        html += '</select></div>';
        for (const [k, v] of Object.entries(node.params)) {
          html += '<div class="field"><label>' + k + '</label><input id="pp_' + k + '" value="' + v + '" ' + (typeof v === 'number' ? 'type="number" step="0.1"' : '') + '></div>';
        }
        el.innerHTML = html;
        document.getElementById('pParent').addEventListener('change', (e) => {
          node.parentId = e.target.value ? parseInt(e.target.value) : null;
          layoutTree(); render();
        });
        for (const k of Object.keys(node.params)) {
          const inp = document.getElementById('pp_' + k);
          if (inp) inp.addEventListener('input', (e) => {
            node.params[k] = typeof node.params[k] === 'number' ? parseFloat(e.target.value) || 0 : e.target.value;
          });
        }
      }

      function updateStatus() {
        document.getElementById('statusInfo').textContent = 'Nodes: ' + nodes.length;
      }

      // Palette click
      document.querySelectorAll('.drag-node').forEach(el => {
        el.addEventListener('click', () => addNode(el.dataset.type));
      });

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
      canvas.addEventListener('mouseup', () => { isPanning = false; dragNode = null; });
      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const old = zoom; zoom *= e.deltaY < 0 ? 1.1 : 0.9; zoom = Math.max(0.2, Math.min(4, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / old;
        offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / old; render();
      }, { passive: false });

      // Simulate
      document.getElementById('btnSimulate').addEventListener('click', () => {
        const statuses = ['success', 'failure', 'running'];
        for (const n of nodes) n.status = statuses[Math.floor(Math.random() * statuses.length)];
        document.getElementById('statusSim').textContent = 'Simulation: Running';
        render();
      });
      document.getElementById('btnReset').addEventListener('click', () => {
        for (const n of nodes) n.status = 'idle';
        document.getElementById('statusSim').textContent = 'Simulation: Idle';
        render();
      });
      document.getElementById('btnClear').addEventListener('click', () => {
        nodes = []; selectedNode = null; showProps(null); updateStatus(); render();
      });

      document.getElementById('btnExport').addEventListener('click', () => {
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
        const roots = nodes.filter(n => !n.parentId);
        let lua = 'return {\\n';
        for (const r of roots) lua += '  ' + exportNode(r) + ',\\n';
        lua += '}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      // Default tree
      addNode('Selector', 300, 40); nodes[0].parentId = null;
      addNode('Sequence', 150, 120); nodes[1].parentId = 1;
      addNode('HasTarget', 100, 200); nodes[2].parentId = 2;
      addNode('Attack', 220, 200); nodes[3].parentId = 2;
      addNode('Patrol', 400, 120); nodes[4].parentId = 1;
      selectedNode = null; showProps(null);
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `)}};var Pn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.graph","Graph / Node Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"graph.lua");break}}getHtml(){let e=R();return D(e,"Graph / Node Editor",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 220px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); padding: 8px; overflow-y: auto; background: var(--surface); }
      .status-bar { grid-column: 1 / -1; }
      .port { width: 10px; height: 10px; border-radius: 50%; border: 1px solid var(--border); display: inline-block; cursor: crosshair; }
      .port.in { background: #4ec9b0; }
      .port.out { background: #ff9800; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAddNode">+ Node</button>
          <button id="btnConnect">Connect</button>
          <button id="btnDelete" class="danger">Delete</button>
          <div class="sep"></div>
          <label>Type:</label>
          <input id="nodeType" value="Process" style="width:80px">
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="canvas-area"><canvas id="graphCanvas"></canvas></div>
        <div class="props-panel">
          <h3>Node Properties</h3>
          <div id="propsContent"><p style="color:var(--text-dim);font-size:12px;">Select a node.</p></div>
          <h3 style="margin-top:12px">Port Editor</h3>
          <div id="portEditor"><p style="color:var(--text-dim);font-size:12px;">Ports are defined per-node.</p></div>
        </div>
        <div class="status-bar">
          <span id="statusInfo">Nodes: 0 | Edges: 0</span>
          <span id="statusMode">Mode: Select</span>
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
      const NODE_W = 140, NODE_H = 60, PORT_R = 6;

      function addNode(type, x, y) {
        nodes.push({
          id: nextId++, type: type || 'Process',
          x: x || 150 + nodes.length * 40, y: y || 100 + nodes.length * 40,
          label: (type || 'Process') + ' ' + nextId,
          inPorts: ['in'], outPorts: ['out'],
          data: {}
        });
        updateStatus(); render();
      }

      function getPortPos(node, isOut, portIdx) {
        const portCount = isOut ? node.outPorts.length : node.inPorts.length;
        const spacing = NODE_H / (portCount + 1);
        const x = isOut ? node.x + NODE_W : node.x;
        const y = node.y + spacing * (portIdx + 1);
        return { x, y };
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight; render();
      }

      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.save(); ctx.translate(offsetX, offsetY); ctx.scale(zoom, zoom);

        // Edges
        for (const e of edges) {
          const fromNode = nodes.find(n => n.id === e.fromNode);
          const toNode = nodes.find(n => n.id === e.toNode);
          if (!fromNode || !toNode) continue;
          const fp = getPortPos(fromNode, true, e.fromPort);
          const tp = getPortPos(toNode, false, e.toPort);
          ctx.beginPath();
          const cx = (fp.x + tp.x) / 2;
          ctx.moveTo(fp.x, fp.y);
          ctx.bezierCurveTo(cx, fp.y, cx, tp.y, tp.x, tp.y);
          ctx.strokeStyle = '#888'; ctx.lineWidth = 2; ctx.stroke();
        }

        // Nodes
        for (const n of nodes) {
          ctx.fillStyle = '#2d2d2d'; ctx.strokeStyle = n === selectedNode ? '#007acc' : '#3c3c3c';
          ctx.lineWidth = n === selectedNode ? 2 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 5); ctx.fill(); ctx.stroke();
          // Header
          ctx.fillStyle = '#1e3a5f'; ctx.beginPath();
          ctx.roundRect(n.x, n.y, NODE_W, 20, [5, 5, 0, 0]); ctx.fill();
          ctx.fillStyle = '#ccc'; ctx.font = '11px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
          ctx.fillText(n.label, n.x + NODE_W / 2, n.y + 10);
          // Type
          ctx.fillStyle = '#888'; ctx.font = '10px sans-serif';
          ctx.fillText(n.type, n.x + NODE_W / 2, n.y + 38);
          // In ports
          n.inPorts.forEach((p, i) => {
            const pos = getPortPos(n, false, i);
            ctx.fillStyle = '#4ec9b0'; ctx.beginPath(); ctx.arc(pos.x, pos.y, PORT_R, 0, Math.PI * 2); ctx.fill();
            ctx.fillStyle = '#aaa'; ctx.font = '9px sans-serif'; ctx.textAlign = 'left';
            ctx.fillText(p, pos.x + 10, pos.y + 3);
          });
          // Out ports
          n.outPorts.forEach((p, i) => {
            const pos = getPortPos(n, true, i);
            ctx.fillStyle = '#ff9800'; ctx.beginPath(); ctx.arc(pos.x, pos.y, PORT_R, 0, Math.PI * 2); ctx.fill();
            ctx.fillStyle = '#aaa'; ctx.font = '9px sans-serif'; ctx.textAlign = 'right';
            ctx.fillText(p, pos.x - 10, pos.y + 3);
          });
        }
        ctx.restore();
      }

      function hitNode(sx, sy) {
        const wx = (sx - offsetX) / zoom, wy = (sy - offsetY) / zoom;
        for (let i = nodes.length - 1; i >= 0; i--) {
          const n = nodes[i];
          if (wx >= n.x && wx <= n.x + NODE_W && wy >= n.y && wy <= n.y + NODE_H) return n;
        }
        return null;
      }

      function hitPort(sx, sy) {
        const wx = (sx - offsetX) / zoom, wy = (sy - offsetY) / zoom;
        for (const n of nodes) {
          for (let i = 0; i < n.outPorts.length; i++) {
            const p = getPortPos(n, true, i);
            if (Math.hypot(wx - p.x, wy - p.y) < PORT_R * 2) return { node: n, isOut: true, port: i };
          }
          for (let i = 0; i < n.inPorts.length; i++) {
            const p = getPortPos(n, false, i);
            if (Math.hypot(wx - p.x, wy - p.y) < PORT_R * 2) return { node: n, isOut: false, port: i };
          }
        }
        return null;
      }

      function showProps(node) {
        const el = document.getElementById('propsContent');
        const pe = document.getElementById('portEditor');
        if (!node) { el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;">Select a node.</p>'; pe.innerHTML = ''; return; }
        el.innerHTML =
          '<div class="field"><label>Label</label><input id="pLabel" value="' + node.label + '"></div>' +
          '<div class="field"><label>Type</label><input id="pType" value="' + node.type + '"></div>';
        document.getElementById('pLabel').addEventListener('input', (e) => { node.label = e.target.value; render(); });
        document.getElementById('pType').addEventListener('input', (e) => { node.type = e.target.value; render(); });

        pe.innerHTML = '<div class="field"><label>In Ports</label><input id="pInPorts" value="' + node.inPorts.join(', ') + '"></div>' +
          '<div class="field"><label>Out Ports</label><input id="pOutPorts" value="' + node.outPorts.join(', ') + '"></div>';
        document.getElementById('pInPorts').addEventListener('change', (e) => {
          node.inPorts = e.target.value.split(',').map(s => s.trim()).filter(Boolean);
          edges = edges.filter(ed => !(ed.toNode === node.id && ed.toPort >= node.inPorts.length));
          render();
        });
        document.getElementById('pOutPorts').addEventListener('change', (e) => {
          node.outPorts = e.target.value.split(',').map(s => s.trim()).filter(Boolean);
          edges = edges.filter(ed => !(ed.fromNode === node.id && ed.fromPort >= node.outPorts.length));
          render();
        });
      }

      function updateStatus() {
        document.getElementById('statusInfo').textContent = 'Nodes: ' + nodes.length + ' | Edges: ' + edges.length;
      }

      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) { isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY; return; }

        if (connectMode) {
          const port = hitPort(e.offsetX, e.offsetY);
          if (port && port.isOut && !connectFrom) {
            connectFrom = port.node; connectPort = port.port;
          } else if (port && !port.isOut && connectFrom) {
            edges.push({ fromNode: connectFrom.id, fromPort: connectPort, toNode: port.node.id, toPort: port.port });
            connectFrom = null; updateStatus(); render();
          } else { connectFrom = null; }
          return;
        }

        const node = hitNode(e.offsetX, e.offsetY);
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
      canvas.addEventListener('mouseup', () => { isPanning = false; dragNode = null; });
      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const old = zoom; zoom *= e.deltaY < 0 ? 1.1 : 0.9; zoom = Math.max(0.2, Math.min(4, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / old; offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / old; render();
      }, { passive: false });

      document.getElementById('btnAddNode').addEventListener('click', () => {
        addNode(document.getElementById('nodeType').value);
      });
      document.getElementById('btnConnect').addEventListener('click', () => {
        connectMode = !connectMode; connectFrom = null;
        document.getElementById('btnConnect').classList.toggle('active', connectMode);
        document.getElementById('statusMode').textContent = connectMode ? 'Mode: Connect' : 'Mode: Select';
      });
      document.getElementById('btnDelete').addEventListener('click', () => {
        if (!selectedNode) return;
        edges = edges.filter(e => e.fromNode !== selectedNode.id && e.toNode !== selectedNode.id);
        nodes = nodes.filter(n => n !== selectedNode);
        selectedNode = null; showProps(null); updateStatus(); render();
      });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  nodes = {\\n';
        for (const n of nodes) {
          lua += '    { id = ' + n.id + ', type = "' + n.type + '", label = "' + n.label + '"';
          lua += ', inPorts = { "' + n.inPorts.join('", "') + '" }';
          lua += ', outPorts = { "' + n.outPorts.join('", "') + '" }';
          lua += ' },\\n';
        }
        lua += '  },\\n  edges = {\\n';
        for (const e of edges) {
          lua += '    { from = ' + e.fromNode + ', fromPort = ' + (e.fromPort + 1) + ', to = ' + e.toNode + ', toPort = ' + (e.toPort + 1) + ' },\\n';
        }
        lua += '  }\\n}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      addNode('Input', 80, 100); nodes[0].outPorts = ['data', 'signal'];
      addNode('Process', 300, 80); nodes[1].inPorts = ['data']; nodes[1].outPorts = ['result'];
      addNode('Output', 520, 100); nodes[2].inPorts = ['result']; nodes[2].outPorts = [];
      edges.push({ fromNode: 1, fromPort: 0, toNode: 2, toPort: 0 });
      edges.push({ fromNode: 2, fromPort: 0, toNode: 3, toPort: 0 });
      selectedNode = null; showProps(null);
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `)}};var Ln=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.tilemapScript","Tilemap Script Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"tilemap_script.lua");break}}getHtml(){let e=R();return D(e,"Tilemap Script Editor",`
      .editor-layout {
        display: grid; grid-template-columns: 200px 1fr 300px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .blocks-panel { grid-row: 2; }
      .script-area { grid-row: 2; padding: 8px; overflow-y: auto; border-right: 1px solid var(--border); }
      .preview-panel { grid-row: 2; display: flex; flex-direction: column; }
      .status-bar { grid-column: 1 / -1; }
      .block-btn { width: 100%; margin-bottom: 3px; text-align: left; font-size: 11px; padding: 6px 8px; }
      .script-step {
        background: var(--surface-2); border: 1px solid var(--border); border-radius: 4px;
        padding: 8px; margin-bottom: 6px; position: relative;
      }
      .script-step h4 { font-size: 12px; margin-bottom: 6px; display: flex; justify-content: space-between; }
      .script-step .step-num { color: var(--accent); font-weight: bold; }
      .preview-canvas { flex: 1; background: #111; display: flex; align-items: center; justify-content: center; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <label>Width:</label><input type="number" id="mapW" value="40" min="5" max="100" style="width:50px">
          <label>Height:</label><input type="number" id="mapH" value="30" min="5" max="100" style="width:50px">
          <label>Seed:</label><input type="number" id="seed" value="1234" style="width:60px">
          <div class="sep"></div>
          <button id="btnRun">Run Script</button>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="panel blocks-panel">
          <h3>Script Blocks</h3>
          <button class="block-btn" data-block="fill">Fill All</button>
          <button class="block-btn" data-block="noise">Random Noise</button>
          <button class="block-btn" data-block="rooms">Place Rooms</button>
          <button class="block-btn" data-block="corridors">Connect Corridors</button>
          <button class="block-btn" data-block="border">Add Border</button>
          <button class="block-btn" data-block="scatter">Scatter Objects</button>
          <button class="block-btn" data-block="cellular">Cellular Automata</button>
          <button class="block-btn" data-block="clear_center">Clear Center</button>
        </div>
        <div class="script-area" id="scriptArea">
          <h3>Script Steps</h3>
          <div id="stepList"></div>
          <p style="color:var(--text-dim);font-size:11px;margin-top:8px;">Click blocks on the left to add steps. Drag to reorder.</p>
        </div>
        <div class="preview-panel">
          <h3 style="padding:8px;background:var(--surface);border-bottom:1px solid var(--border);">Preview</h3>
          <div class="preview-canvas"><canvas id="previewCanvas"></canvas></div>
        </div>
        <div class="status-bar">
          <span id="statusInfo">Steps: 0 | Size: 40x30</span>
        </div>
      </div>
    `,`
      let mapW = 40, mapH = 30, seed = 1234;
      let mapData = [];
      let steps = [];

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
            paramsHtml += '<div class="field-row"><label style="width:70px;font-size:11px">' + k + '</label>';
            paramsHtml += '<input type="number" data-si="' + i + '" data-pk="' + k + '" value="' + v + '" style="width:60px" step="' + (typeof v === 'number' && v < 1 ? 0.05 : 1) + '"></div>';
          }
          div.innerHTML = '<h4><span class="step-num">#' + (i + 1) + '</span> ' + step.label +
            ' <span><button data-up="' + i + '">\\u25B2</button><button data-down="' + i + '">\\u25BC</button><button data-del="' + i + '"> x</button></span></h4>' + paramsHtml;
          el.appendChild(div);

          div.querySelectorAll('input[data-si]').forEach(inp => {
            inp.addEventListener('input', (e) => {
              steps[parseInt(e.target.dataset.si)].params[e.target.dataset.pk] = parseFloat(e.target.value) || 0;
            });
          });
          const up = div.querySelector('[data-up]');
          if (up) up.addEventListener('click', () => { if (i > 0) { [steps[i-1], steps[i]] = [steps[i], steps[i-1]]; refreshSteps(); } });
          const down = div.querySelector('[data-down]');
          if (down) down.addEventListener('click', () => { if (i < steps.length-1) { [steps[i], steps[i+1]] = [steps[i+1], steps[i]]; refreshSteps(); } });
          div.querySelector('[data-del]').addEventListener('click', () => { steps.splice(i, 1); refreshSteps(); });
        });
        document.getElementById('statusInfo').textContent = 'Steps: ' + steps.length + ' | Size: ' + mapW + 'x' + mapH;
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
              for (let i = 0; i < mapData.length; i++) { if (rng() < p.density) mapData[i] = p.tile; }
              break;
            case 'rooms':
              for (let r = 0; r < (p.count || 5); r++) {
                const rw = Math.floor(rng() * ((p.maxSize||8) - (p.minSize||3))) + (p.minSize||3);
                const rh = Math.floor(rng() * ((p.maxSize||8) - (p.minSize||3))) + (p.minSize||3);
                const rx = Math.floor(rng() * (mapW - rw - 2)) + 1;
                const ry = Math.floor(rng() * (mapH - rh - 2)) + 1;
                for (let y = ry; y < ry + rh; y++) for (let x = rx; x < rx + rw; x++) set(x, y, 0);
                rooms.push({ cx: rx + Math.floor(rw/2), cy: ry + Math.floor(rh/2) });
              }
              break;
            case 'corridors':
              for (let i = 0; i < rooms.length - 1; i++) {
                const a = rooms[i], b = rooms[i+1];
                let cx = a.cx;
                while (cx !== b.cx) { set(cx, a.cy, 0); cx += cx < b.cx ? 1 : -1; }
                let cy = a.cy;
                while (cy !== b.cy) { set(b.cx, cy, 0); cy += cy < b.cy ? 1 : -1; }
              }
              break;
            case 'border':
              for (let x = 0; x < mapW; x++) for (let t = 0; t < (p.thickness || 1); t++) { set(x, t, p.tile); set(x, mapH - 1 - t, p.tile); }
              for (let y = 0; y < mapH; y++) for (let t = 0; t < (p.thickness || 1); t++) { set(t, y, p.tile); set(mapW - 1 - t, y, p.tile); }
              break;
            case 'scatter':
              for (let i = 0; i < mapData.length; i++) { if (mapData[i] === 0 && rng() < (p.density || 0.05)) mapData[i] = p.tile; }
              break;
            case 'cellular':
              for (let iter = 0; iter < (p.iterations || 4); iter++) {
                const next = [...mapData];
                for (let y = 0; y < mapH; y++) for (let x = 0; x < mapW; x++) {
                  let walls = 0;
                  for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
                    if (dx === 0 && dy === 0) continue;
                    if (get(x+dx, y+dy) === 1) walls++;
                  }
                  if (mapData[y*mapW+x] === 1) next[y*mapW+x] = walls >= (p.deathLimit||3) ? 1 : 0;
                  else next[y*mapW+x] = walls >= (p.birthLimit||4) ? 1 : 0;
                }
                mapData = next;
              }
              break;
            case 'clear_center': {
              const cx = Math.floor(mapW/2), cy = Math.floor(mapH/2), r = p.radius || 5;
              for (let y = cy - r; y <= cy + r; y++) for (let x = cx - r; x <= cx + r; x++) {
                if (Math.hypot(x - cx, y - cy) <= r) set(x, y, 0);
              }
              break;
            }
          }
        }
        renderPreview();
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

      document.querySelectorAll('.block-btn').forEach(btn => {
        btn.addEventListener('click', () => addStep(btn.dataset.block));
      });
      document.getElementById('btnRun').addEventListener('click', runScript);
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  width = ' + mapW + ',\\n  height = ' + mapH + ',\\n  seed = ' + seed + ',\\n';
        lua += '  steps = {\\n';
        for (const s of steps) {
          lua += '    { type = "' + s.type + '"';
          for (const [k, v] of Object.entries(s.params)) lua += ', ' + k + ' = ' + v;
          lua += ' },\\n';
        }
        lua += '  }\\n}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      addStep('fill'); addStep('noise'); addStep('cellular'); addStep('border');
      refreshSteps();
      runScript();
    `)}};var Rn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.voxel","Voxel Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"voxel_model.lua");break}}getHtml(){let e=R();return D(e,"Voxel Editor",`
      .editor-layout {
        display: grid; grid-template-columns: 48px 1fr 1fr 180px;
        grid-template-rows: auto 1fr 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .tool-sidebar { grid-row: 2 / 4; background: var(--surface); border-right: 1px solid var(--border); display: flex; flex-direction: column; align-items: center; padding: 4px; gap: 2px; }
      .tool-sidebar button { width: 36px; height: 36px; font-size: 16px; padding: 0; }
      .top-view { grid-row: 2; grid-column: 2; position: relative; overflow: hidden; border-bottom: 1px solid var(--border); border-right: 1px solid var(--border); }
      .side-view { grid-row: 3; grid-column: 2; position: relative; overflow: hidden; border-right: 1px solid var(--border); }
      .iso-view { grid-row: 2 / 4; grid-column: 3; position: relative; overflow: hidden; }
      .right-panel { grid-row: 2 / 4; border-left: 1px solid var(--border); padding: 8px; overflow-y: auto; background: var(--surface); }
      .status-bar { grid-column: 1 / -1; }
      .view-label {
        position: absolute; top: 4px; left: 8px; font-size: 11px; color: var(--text-dim);
        background: var(--surface); padding: 1px 6px; border-radius: 2px; z-index: 1;
      }
      .layer-btn { width: 100%; margin-bottom: 2px; font-size: 11px; text-align: left; }
      .layer-btn.sel { background: var(--accent); }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <label>Grid:</label>
          <select id="gridSize"><option value="8">8x8x8</option><option value="16" selected>16x16x16</option><option value="32">32x32x32</option></select>
          <label>Layer (Z):</label><input type="number" id="layerZ" value="0" min="0" max="15" style="width:40px">
          <div class="sep"></div>
          <button id="btnClear" class="danger">Clear</button>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="tool-sidebar" id="tools">
          <button class="active" data-tool="pen" title="Pen">&#9998;</button>
          <button data-tool="erase" title="Erase">&#9003;</button>
          <button data-tool="fill" title="Fill Layer">&#9636;</button>
        </div>
        <div class="top-view"><span class="view-label">Top (XY) \u2014 Layer Z</span><canvas id="topCanvas"></canvas></div>
        <div class="side-view"><span class="view-label">Side (XZ)</span><canvas id="sideCanvas"></canvas></div>
        <div class="iso-view"><span class="view-label">3D Isometric</span><canvas id="isoCanvas"></canvas></div>
        <div class="right-panel">
          <h3>Color</h3>
          <input type="color" id="voxelColor" value="#4ec9b0" style="width:100%;height:30px;border:none;cursor:pointer">
          <div class="section" style="margin-top: 8px;">
            <h3>Palette</h3>
            <div id="palette" style="display:grid;grid-template-columns:repeat(4,1fr);gap:2px;"></div>
          </div>
          <div class="section" style="margin-top: 12px;">
            <h3>Layers (Z)</h3>
            <div id="layerList"></div>
          </div>
        </div>
        <div class="status-bar">
          <span id="statusPos">Pos: 0, 0, 0</span>
          <span id="statusVoxels">Voxels: 0</span>
        </div>
      </div>
    `,`
      const PALETTE = ['#4ec9b0','#007acc','#f44336','#ff9800','#4caf50','#9c27b0','#ffeb3b','#795548','#ffffff','#888888','#444444','#000000','#ff77a8','#29adff','#00e436','#ab5236'];
      let gridSize = 16, currentZ = 0, currentColor = '#4ec9b0', currentTool = 'pen';
      let voxels = {}; // key "x,y,z" => color

      function vKey(x, y, z) { return x + ',' + y + ',' + z; }
      function setVoxel(x, y, z, color) { if (color) voxels[vKey(x,y,z)] = color; else delete voxels[vKey(x,y,z)]; }
      function getVoxel(x, y, z) { return voxels[vKey(x,y,z)] || null; }

      function countVoxels() { return Object.keys(voxels).length; }

      // Top view (XY at layer Z)
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

      // Side view (XZ at center Y)
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
        // Highlight current Z
        sideCtx.strokeStyle = '#007acc'; sideCtx.lineWidth = 2;
        sideCtx.strokeRect(0, (gridSize - 1 - currentZ) * cs, gridSize * cs, cs);
      }

      // Iso view
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

        // Render back to front
        for (let z = 0; z < gridSize; z++) {
          for (let y = 0; y < gridSize; y++) {
            for (let x = 0; x < gridSize; x++) {
              const c = getVoxel(x, y, z);
              if (!c) continue;
              const { px, py } = isoProject(x, y, z);
              // Top face
              isoCtx.fillStyle = c;
              isoCtx.beginPath();
              isoCtx.moveTo(px, py - cs * 0.5);
              isoCtx.lineTo(px + cs, py);
              isoCtx.lineTo(px, py + cs * 0.5);
              isoCtx.lineTo(px - cs, py);
              isoCtx.closePath(); isoCtx.fill();
              // Left face
              isoCtx.fillStyle = darken(c, 0.7);
              isoCtx.beginPath();
              isoCtx.moveTo(px - cs, py);
              isoCtx.lineTo(px, py + cs * 0.5);
              isoCtx.lineTo(px, py + cs * 0.5 + cs);
              isoCtx.lineTo(px - cs, py + cs);
              isoCtx.closePath(); isoCtx.fill();
              // Right face
              isoCtx.fillStyle = darken(c, 0.85);
              isoCtx.beginPath();
              isoCtx.moveTo(px + cs, py);
              isoCtx.lineTo(px, py + cs * 0.5);
              isoCtx.lineTo(px, py + cs * 0.5 + cs);
              isoCtx.lineTo(px + cs, py + cs);
              isoCtx.closePath(); isoCtx.fill();
            }
          }
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
        document.getElementById('statusVoxels').textContent = 'Voxels: ' + countVoxels();
      }

      // Top canvas interaction
      topCanvas.addEventListener('mousedown', (e) => handleTopClick(e));
      topCanvas.addEventListener('mousemove', (e) => {
        if (e.buttons === 1) handleTopClick(e);
        const cs = Math.min(Math.floor(topCanvas.width / gridSize), Math.floor(topCanvas.height / gridSize));
        const x = Math.floor(e.offsetX / cs), y = Math.floor(e.offsetY / cs);
        document.getElementById('statusPos').textContent = 'Pos: ' + x + ', ' + y + ', ' + currentZ;
      });

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

      // Tools
      document.getElementById('tools').addEventListener('click', (e) => {
        const btn = e.target.closest('[data-tool]');
        if (!btn) return;
        document.getElementById('tools').querySelectorAll('button').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentTool = btn.dataset.tool;
      });

      // Layer Z
      document.getElementById('layerZ').addEventListener('input', (e) => {
        currentZ = Math.max(0, Math.min(gridSize - 1, parseInt(e.target.value) || 0));
        refreshLayers(); renderAll();
      });

      // Grid size
      document.getElementById('gridSize').addEventListener('change', (e) => {
        gridSize = parseInt(e.target.value);
        voxels = {}; currentZ = 0;
        document.getElementById('layerZ').max = String(gridSize - 1);
        document.getElementById('layerZ').value = '0';
        refreshLayers(); renderAll();
      });

      // Palette
      const paletteEl = document.getElementById('palette');
      PALETTE.forEach(c => {
        const div = document.createElement('div');
        div.style.cssText = 'aspect-ratio:1;background:' + c + ';cursor:pointer;border:1px solid #555;border-radius:2px;';
        div.addEventListener('click', () => {
          currentColor = c;
          document.getElementById('voxelColor').value = c;
        });
        paletteEl.appendChild(div);
      });
      document.getElementById('voxelColor').addEventListener('input', (e) => { currentColor = e.target.value; });

      // Layers
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
            currentZ = z;
            document.getElementById('layerZ').value = String(z);
            refreshLayers(); renderAll();
          });
          el.appendChild(btn);
        }
      }

      document.getElementById('btnClear').addEventListener('click', () => { voxels = {}; renderAll(); refreshLayers(); });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  size = ' + gridSize + ',\\n  voxels = {\\n';
        for (const [key, color] of Object.entries(voxels)) {
          const [x, y, z] = key.split(',');
          lua += '    { x = ' + x + ', y = ' + y + ', z = ' + z + ', color = "' + color + '" },\\n';
        }
        lua += '  }\\n}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      refreshLayers();
      window.addEventListener('resize', renderAll);
      renderAll();
    `)}};var wt=E(require("vscode")),jo=E(require("path")),kt=E(require("fs"));var Md=["ai","audio","cardgame","combat","compute","config","crafting","data","dataframe","dialog","engine","entity","event","filesystem","graph","graphics","graphics_ext","image","input","inventory","math","math_ext","minimap","modding","particle","pathfinding","physics","postfx","quest","resource","savegame","scene","sound","stats","thread","tilemap","timer"],Dn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.testRunner","Test Runner"),setTimeout(()=>this.pushDiscoveredSuites(),300)}handleMessage(e){switch(e.type){case"discoverSuites":this.pushDiscoveredSuites();break;case"runAll":this.runCargoTest("","all");break;case"runSuite":this.runCargoTest(e.suite,e.suite);break;case"runLua":this.runCargoTest("--test lua_tests","lua");break;case"runGolden":this.runCargoTest("--test golden_tests","golden");break;case"stop":wt.window.showInformationMessage("Use the terminal to cancel the running test.");break}}pushDiscoveredSuites(){let e=this.discoverTestSuites();this.panel.webview.postMessage({type:"suites",suites:e})}discoverTestSuites(){let e=wt.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!e)return this.fallbackSuites();let t=jo.join(e,"tests");if(!kt.existsSync(t))return this.fallbackSuites();let o=[],s=new Set(["golden_tests","lua_tests"]),i;try{i=kt.readdirSync(t)}catch{return this.fallbackSuites()}for(let a of i.sort()){if(!a.endsWith("_tests.rs"))continue;let r=a.replace(/\.rs$/,"");if(s.has(r))continue;let l=this.extractTestNames(jo.join(t,a));o.push({name:r,tests:l})}return o.push({name:"lua_tests",tests:["(lua vm tests \u2014 run via cargo test --test lua_tests)"]}),o.push({name:"golden_tests",tests:["(golden output tests \u2014 run via cargo test --test golden_tests)"]}),o}extractTestNames(e){try{let t=kt.readFileSync(e,"utf8"),o=[],s=/^\s*(?:#\[test\]\s*(?:#\[.*?\]\s*)*)?(?:async\s+)?fn\s+(\w+)/gm,i,a=t.split(`
`);for(let r=0;r<a.length;r++)if(a[r].trimStart().startsWith("#[test]"))for(let l=r+1;l<Math.min(r+5,a.length);l++){let c=a[l].match(/\bfn\s+(\w+)/);if(c){o.push(c[1]);break}}return o.length?o:["(no #[test] functions found)"]}catch{return["(could not read file)"]}}fallbackSuites(){return Md.map(e=>({name:`${e}_tests`,tests:[`(run: cargo test --test ${e}_tests)`]}))}runCargoTest(e,t){let s=wt.window.terminals.find(a=>a.name==="Lurek2D Tests")??wt.window.createTerminal("Lurek2D Tests");s.show();let i=e?`cargo test ${e}`:"cargo test";s.sendText(i),this.panel.webview.postMessage({type:"testStarted",filter:t})}getHtml(){let e=R();return D(e,"Test Runner",`
      .editor-layout {
        display: grid; grid-template-columns: 280px 1fr;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
      .tree-panel { grid-row: 2; overflow-y: auto; border-right: 1px solid var(--border); }
      .output-panel { grid-row: 2; padding: 8px; overflow-y: auto; font-family: 'Cascadia Code', 'Consolas', monospace; font-size: 12px; white-space: pre-wrap; background: #1a1a1a; color: #ccc; }
      .status-bar { grid-column: 1 / -1; }
      .test-item { display: flex; align-items: center; gap: 6px; padding: 3px 8px 3px 24px; cursor: pointer; font-size: 12px; border-radius: 2px; }
      .test-item:hover { background: var(--surface-2); }
      .test-item.sel { background: var(--selection); }
      .dot { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; }
      .dot.pass { background: #4caf50; } .dot.fail { background: #f44336; }
      .dot.pending { background: #555; } .dot.running { background: #ff9800; animation: pulse 1s infinite; }
      @keyframes pulse { 0%,100% { opacity:1; } 50% { opacity:0.4; } }
      .suite-row { display: flex; align-items: center; justify-content: space-between; font-weight: 600; font-size: 12px; padding: 5px 8px; border-bottom: 1px solid var(--border); color: var(--text-dim); cursor: pointer; }
      .suite-row:hover { background: var(--surface-2); }
      .suite-run-btn { font-size: 10px; padding: 1px 6px; border-radius: 3px; background: #0e518c; color: #fff; border: none; cursor: pointer; }
      .suite-run-btn:hover { background: #1177bb; }
      .badge { font-size: 10px; padding: 1px 5px; border-radius: 8px; margin-left: 4px; }
      .badge.pass { background: #1e4a1e; color: #4caf50; } .badge.fail { background: #4a1e1e; color: #f44336; }
      #discovering { padding: 12px; font-size: 12px; opacity: 0.6; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnRunAll">&#9654; Run All</button>
          <button id="btnRunLua">Run Lua Tests</button>
          <button id="btnRunGolden">Run Golden Tests</button>
          <button id="btnRunSelected">Run Selected Suite</button>
          <div class="sep"></div>
          <label style="font-size:12px">Filter:</label>
          <input id="filter" placeholder="function name..." style="width:130px">
          <div class="sep"></div>
          <span id="statusSummary" style="font-size:12px;color:var(--text-dim)">Discovering\u2026</span>
        </div>
        <div class="panel tree-panel" id="treePanel"><div id="discovering">\u27F3 Scanning tests/ directory\u2026</div></div>
        <div class="output-panel" id="output">Tests run in the "Lurek2D Tests" terminal.

Select a suite and click "Run Selected Suite", or click \u25B6 next to any suite name.</div>
        <div class="status-bar"><span id="statusBar">Ready</span></div>
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
          document.getElementById('output').textContent = '$ cargo test ' + data.filter + '\\n\\nSee "Lurek2D Tests" terminal for live output.';
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
          row.className = 'suite-row';
          let badges = '';
          if (passCount) badges += '<span class="badge pass">' + passCount + '\u2713</span>';
          if (failCount) badges += '<span class="badge fail">' + failCount + '\u2717</span>';
          row.innerHTML = '<span>' + suite.name + badges + '</span>' +
            '<button class="suite-run-btn" data-suite="' + suite.name + '">\u25B6</button>';
          row.querySelector('.suite-run-btn').addEventListener('click', (ev) => {
            ev.stopPropagation();
            const s = ev.target.dataset.suite;
            selectedSuite = s;
            vscode.postMessage({ type: 'runSuite', suite: s });
          });
          row.addEventListener('click', () => { selectedSuite = suite.name; highlightSuite(suite.name); });
          panel.appendChild(row);

          for (const t of filteredTests) {
            const key = suite.name + '::' + t;
            const item = document.createElement('div');
            item.className = 'test-item';
            const status = results[key] || 'pending';
            item.innerHTML = '<span class="dot ' + status + '"></span><span>' + t + '</span>';
            item.addEventListener('click', () => {
              document.getElementById('output').textContent = 'Suite: ' + suite.name + '\\nTest: ' + t + '\\nStatus: ' + status + '\\n\\nRun the suite to get real results.';
            });
            panel.appendChild(item);
          }
        }
        updateStatusBar();
      }

      function highlightSuite(name) {
        document.querySelectorAll('.suite-row').forEach(r => r.style.background = '');
        const rows = document.querySelectorAll('.suite-row');
        rows.forEach(r => { if (r.querySelector('span')?.textContent?.startsWith(name)) r.style.background = 'var(--selection)'; });
      }

      function updateStatusBar() {
        const all = Object.values(results);
        const pass = all.filter(r => r === 'pass').length;
        const fail = all.filter(r => r === 'fail').length;
        const pending = all.filter(r => r === 'pending').length;
        const total = TEST_SUITES.reduce((s, sr) => s + sr.tests.length, 0);
        document.getElementById('statusBar').textContent =
          TEST_SUITES.length + ' suites \xB7 ' + total + ' tests \xB7 ' + pass + ' pass \xB7 ' + fail + ' fail \xB7 ' + pending + ' pending';
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
    `)}};var _t=E(require("vscode"));Xt();var Mn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.apiReference","API Reference"),this.loadApiData()}async loadApiData(){try{let e=_t.workspace.workspaceFolders;if(!e)return;let t=Ve(e[0].uri.fsPath);if(!t)return;let o=await _t.workspace.fs.readFile(_t.Uri.file(t)),s=new globalThis.TextDecoder().decode(o);this.panel.webview.postMessage({type:"apiData",content:s})}catch{}}handleMessage(e){}getHtml(){let e=R();return D(e,"API Reference",`
      .editor-layout {
        display: grid; grid-template-columns: 220px 1fr;
        grid-template-rows: auto 1fr; height: 100vh;
      }
      .search-bar { grid-column: 1 / -1; padding: 6px 10px; background: var(--surface); border-bottom: 1px solid var(--border); display: flex; gap: 8px; }
      .search-bar input { flex: 1; }
      .module-list { grid-row: 2; overflow-y: auto; }
      .doc-panel { grid-row: 2; overflow-y: auto; padding: 16px 24px; }
      .module-item { padding: 4px 12px; cursor: pointer; border-radius: 3px; font-size: 12px; }
      .module-item:hover { background: var(--surface-2); }
      .module-item.sel { background: var(--selection); }
      .func-card {
        background: var(--surface); border: 1px solid var(--border); border-radius: 4px;
        padding: 12px; margin-bottom: 10px;
      }
      .func-card h3 { font-size: 14px; color: var(--accent-2); margin-bottom: 4px; font-family: 'Cascadia Code', monospace; }
      .func-card .sig { font-size: 12px; color: var(--accent); font-family: 'Cascadia Code', monospace; margin-bottom: 6px; }
      .func-card .desc { font-size: 12px; line-height: 1.5; }
      .func-card .param { font-size: 11px; color: var(--text-dim); margin-left: 12px; }
      .func-card .returns { font-size: 11px; color: #4ec9b0; margin-top: 4px; }
      .module-header { font-size: 16px; font-weight: bold; margin-bottom: 12px; padding-bottom: 6px; border-bottom: 1px solid var(--border); }
      .module-desc { font-size: 12px; color: var(--text-dim); margin-bottom: 16px; }
      .tag { display: inline-block; padding: 1px 6px; border-radius: 3px; font-size: 10px; margin-left: 6px; }
      .tag.read { background: #1e3a5f; color: #4ec9b0; }
      .tag.write { background: #3a1e2a; color: #ff77a8; }
      .tag.event { background: #2a3a1e; color: #4caf50; }
    `,`
      <div class="editor-layout">
        <div class="search-bar">
          <input id="searchInput" placeholder="Search functions, modules...">
          <select id="filterType">
            <option value="">All</option>
            <option value="function">Functions</option>
            <option value="callback">Callbacks</option>
            <option value="constant">Constants</option>
          </select>
        </div>
        <div class="panel module-list" id="moduleList"></div>
        <div class="doc-panel" id="docPanel">
          <div class="module-header">Lurek2D API Reference</div>
          <div class="module-desc">Select a module from the left panel to browse its API functions.</div>
        </div>
      </div>
    `,`
      const API_DATA = {
        'lurek.graphics': {
          desc: 'Drawing primitives, colors, transforms, and render state.',
          funcs: [
            { name: 'lurek.graphics.rectangle', sig: 'lurek.graphics.rectangle(mode, x, y, w, h)', desc: 'Draw a rectangle.', params: ['mode: "fill" or "line"', 'x, y: position', 'w, h: size'], returns: 'nil' },
            { name: 'lurek.graphics.circle', sig: 'lurek.graphics.circle(mode, x, y, r)', desc: 'Draw a circle.', params: ['mode: "fill" or "line"', 'x, y: center', 'r: radius'], returns: 'nil' },
            { name: 'lurek.graphics.line', sig: 'lurek.graphics.line(x1, y1, x2, y2)', desc: 'Draw a line between two points.', params: ['x1, y1: start point', 'x2, y2: end point'], returns: 'nil' },
            { name: 'lurek.graphics.print', sig: 'lurek.graphics.print(text, x, y)', desc: 'Draw text at position.', params: ['text: string to draw', 'x, y: position'], returns: 'nil' },
            { name: 'lurek.graphics.setColor', sig: 'lurek.graphics.setColor(r, g, b, a)', desc: 'Set the active drawing color.', params: ['r, g, b: 0-1 color channels', 'a: alpha (default 1)'], returns: 'nil' },
            { name: 'lurek.graphics.setBackgroundColor', sig: 'lurek.graphics.setBackgroundColor(r, g, b)', desc: 'Set the background clear color.', params: ['r, g, b: 0-1 color channels'], returns: 'nil' },
            { name: 'lurek.graphics.draw', sig: 'lurek.graphics.draw(image, x, y, r, sx, sy)', desc: 'Draw an image/texture.', params: ['image: texture object', 'x, y: position', 'r: rotation (radians)', 'sx, sy: scale'], returns: 'nil' },
            { name: 'lurek.graphics.newImage', sig: 'lurek.graphics.newImage(path)', desc: 'Load an image from file and return texture handle.', params: ['path: file path relative to game dir'], returns: 'Image' },
          ]
        },
        'lurek.keyboard': {
          desc: 'Keyboard input state and key queries.',
          funcs: [
            { name: 'lurek.keyboard.isDown', sig: 'lurek.keyboard.isDown(key)', desc: 'Check if a key is currently held down.', params: ['key: key name ("space", "a", "left", etc.)'], returns: 'boolean' },
            { name: 'lurek.keyboard.isUp', sig: 'lurek.keyboard.isUp(key)', desc: 'Check if a key is not pressed.', params: ['key: key name'], returns: 'boolean' },
          ]
        },
        'lurek.mouse': {
          desc: 'Mouse position and button queries.',
          funcs: [
            { name: 'lurek.mouse.getPosition', sig: 'lurek.mouse.getPosition()', desc: 'Get current mouse position.', params: [], returns: 'x, y' },
            { name: 'lurek.mouse.isDown', sig: 'lurek.mouse.isDown(button)', desc: 'Check if a mouse button is held.', params: ['button: 1=left, 2=right, 3=middle'], returns: 'boolean' },
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
          desc: 'Engine callback functions set by game scripts.',
          funcs: [
            { name: 'lurek.load', sig: 'function lurek.load()', desc: 'Called once when the game starts. Initialize resources here.', params: [], returns: 'nil', tag: 'event' },
            { name: 'lurek.update', sig: 'function lurek.update(dt)', desc: 'Called every frame. Update game logic.', params: ['dt: delta time in seconds'], returns: 'nil', tag: 'event' },
            { name: 'lurek.draw', sig: 'function lurek.draw()', desc: 'Called every frame after update. Render your game.', params: [], returns: 'nil', tag: 'event' },
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
        for (const mod of Object.keys(API_DATA)) {
          const funcs = API_DATA[mod].funcs;
          const matchesMod = mod.toLowerCase().includes(search);
          const matchingFuncs = funcs.filter(f => f.name.toLowerCase().includes(search) || f.desc.toLowerCase().includes(search));
          if (!matchesMod && matchingFuncs.length === 0 && search) continue;
          const div = document.createElement('div');
          div.className = 'module-item' + (mod === selectedModule ? ' sel' : '');
          div.textContent = mod + ' (' + funcs.length + ')';
          div.addEventListener('click', () => { selectedModule = mod; renderModuleList(); renderDocs(); });
          el.appendChild(div);
        }
      }

      function renderDocs() {
        const el = document.getElementById('docPanel');
        if (!selectedModule || !API_DATA[selectedModule]) {
          el.innerHTML = '<div class="module-header">Lurek2D API Reference</div><div class="module-desc">Select a module.</div>';
          if (loadedMarkdown) {
            el.innerHTML += '<div style="white-space:pre-wrap;font-size:12px;color:var(--text-dim);max-height:80vh;overflow-y:auto;margin-top:16px">' + escapeHtml(loadedMarkdown.substring(0, 5000)) + '</div>';
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
            html += '<div style="margin-top:4px;font-size:11px;color:var(--text-dim)">Parameters:</div>';
            for (const p of f.params) html += '<div class="param">\\u2022 ' + p + '</div>';
          }
          html += '<div class="returns">Returns: ' + f.returns + '</div>';
          html += '</div>';
        }

        if (funcs.length === 0) html += '<p style="color:var(--text-dim)">No matching functions found.</p>';
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
          renderDocs();
        }
      });

      renderModuleList();
      renderDocs();
    `)}};var Qe=E(require("vscode"));var An=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.postfxOverlay","PostFX & Overlay Designer")}handleMessage(e){if(e.type==="copyCode"&&(Qe.env.clipboard.writeText(e.code),Qe.window.showInformationMessage("PostFX code copied to clipboard.")),e.type==="insertCode"){let t=Qe.window.activeTextEditor;t?t.insertSnippet(new Qe.SnippetString(e.code)):Qe.window.showWarningMessage("Open a Lua file to insert code.")}}getHtml(){let e=R();return D(e,"PostFX & Overlay Designer",`
      body { overflow-y: auto; }
      .layout { display: grid; grid-template-columns: 300px 1fr; gap: 12px; }
      h3 { font-size: 12px; text-transform: uppercase; letter-spacing: .05em; opacity: .6; margin: 16px 0 6px; }
      .section { margin-bottom: 12px; }
      .panel { padding: 12px; }
      .row { display: flex; align-items: center; gap: 8px; margin-bottom: 8px; font-size: 13px; }
      .row label { min-width: 130px; opacity: .8; }
      input[type=range] { flex: 1; }
      input[type=color] { width: 40px; height: 26px; padding: 0; border: none; cursor: pointer; }
      .val { font-size: 11px; min-width: 36px; text-align: right; opacity: .7; font-family: monospace; }
      .preview-box { background: #111; border-radius: 6px; border: 1px solid var(--border); position: relative; overflow: hidden; aspect-ratio: 16/9; }
      canvas#preview { display:block; width:100%; }
      code-out { font-family: 'Cascadia Code', monospace; font-size: 11px; background: #1a1a1a; color: #9cdcfe; border-radius: 4px; padding: 10px; display: block; white-space: pre; overflow-x: auto; }
      .btn-row { display: flex; gap: 8px; margin-top: 8px; }
      .tab-row { display: flex; gap: 4px; margin-bottom: 12px; flex-wrap: wrap; }
      .tab { padding: 4px 10px; border-radius: 3px; font-size: 12px; cursor: pointer; background: var(--surface-2); border: none; color: var(--foreground); }
      .tab.active { background: #0e518c; color: #fff; }
      select { background: var(--input-background); color: var(--foreground); border: 1px solid var(--border); padding: 2px 6px; border-radius: 3px; font-size: 12px; }
      .toggle { display: flex; align-items: center; gap: 8px; margin-bottom: 6px; cursor: pointer; }
      .toggle input { width: 16px; height: 16px; cursor: pointer; }
    `,`
      <h2 style="margin:0 0 12px;font-size:14px">\u{1F3A8} PostFX & Overlay Designer</h2>
      <div class="tab-row" id="tabs">
        <button class="tab active" data-tab="weather">Weather</button>
        <button class="tab" data-tab="timeofday">Time of Day</button>
        <button class="tab" data-tab="screen">Screen Effects</button>
        <button class="tab" data-tab="shake">Camera Shake</button>
        <button class="tab" data-tab="overlay">Overlay Presets</button>
      </div>
      <div class="layout">
        <div>
          <!-- WEATHER -->
          <div id="tab-weather" class="section">
            <h3>Weather</h3>
            <div class="row"><label>Preset</label>
              <select id="weatherPreset"><option>Clear</option><option>Rain</option><option>Heavy Rain</option><option>Snow</option><option>Blizzard</option><option>Fog</option><option>Sandstorm</option><option>Thunderstorm</option></select>
            </div>
            <div class="row"><label>Intensity</label><input type="range" id="weatherIntensity" min="0" max="1" step="0.01" value="0.5"><span class="val" id="weatherIntensityVal">0.50</span></div>
            <div class="row"><label>Wind X</label><input type="range" id="windX" min="-500" max="500" step="1" value="80"><span class="val" id="windXVal">80</span></div>
            <div class="row"><label>Wind Y</label><input type="range" id="windY" min="50" max="600" step="1" value="300"><span class="val" id="windYVal">300</span></div>
            <div class="row"><label>Particle Color</label><input type="color" id="weatherColor" value="#aaddf0"></div>
            <div class="row"><label>Fog Density</label><input type="range" id="fogDensity" min="0" max="1" step="0.01" value="0"><span class="val" id="fogDensityVal">0.00</span></div>
            <div class="row"><label>Fog Color</label><input type="color" id="fogColor" value="#8899aa"></div>
          </div>
          <!-- TIME OF DAY -->
          <div id="tab-timeofday" class="section" style="display:none">
            <h3>Time of Day</h3>
            <div class="row"><label>Hour</label><input type="range" id="hour" min="0" max="23.99" step="0.25" value="12"><span class="val" id="hourVal">12:00</span></div>
            <div class="row"><label>Sky Color</label><input type="color" id="skyColor" value="#87ceeb"></div>
            <div class="row"><label>Ambient Light</label><input type="range" id="ambientLight" min="0" max="1" step="0.01" value="1.0"><span class="val" id="ambientLightVal">1.00</span></div>
            <div class="row"><label>Sun Color</label><input type="color" id="sunColor" value="#fff5cc"></div>
            <div class="row"><label>Moon Enabled</label><input type="checkbox" id="moonEnabled" checked></div>
            <div class="row"><label>Stars Enabled</label><input type="checkbox" id="starsEnabled"></div>
            <div class="row"><label>Transition Speed</label><input type="range" id="todSpeed" min="0.001" max="0.1" step="0.001" value="0.01"><span class="val" id="todSpeedVal">0.010</span></div>
            <div class="row"><label>Preset</label>
              <select id="todPreset"><option>Custom</option><option>Dawn</option><option>Morning</option><option>Noon</option><option>Afternoon</option><option>Dusk</option><option>Night</option><option>Midnight</option></select>
            </div>
          </div>
          <!-- SCREEN EFFECTS -->
          <div id="tab-screen" class="section" style="display:none">
            <h3>Screen Effects</h3>
            <div class="row"><label>Vignette</label><input type="range" id="vignette" min="0" max="1" step="0.01" value="0"><span class="val" id="vignetteVal">0.00</span></div>
            <div class="row"><label>Vignette Color</label><input type="color" id="vignetteColor" value="#000000"></div>
            <div class="row"><label>Scanlines</label><input type="range" id="scanlines" min="0" max="1" step="0.01" value="0"><span class="val" id="scanlinesVal">0.00</span></div>
            <div class="row"><label>Color Saturation</label><input type="range" id="saturation" min="0" max="2" step="0.01" value="1"><span class="val" id="saturationVal">1.00</span></div>
            <div class="row"><label>Brightness</label><input type="range" id="brightness" min="0" max="2" step="0.01" value="1"><span class="val" id="brightnessVal">1.00</span></div>
            <div class="row"><label>Contrast</label><input type="range" id="contrast" min="0" max="3" step="0.01" value="1"><span class="val" id="contrastVal">1.00</span></div>
            <div class="row"><label>Chromatic Aberr.</label><input type="range" id="chromatic" min="0" max="10" step="0.1" value="0"><span class="val" id="chromaticVal">0.0</span></div>
            <div class="row"><label>Pixel Size</label><input type="range" id="pixelSize" min="1" max="16" step="1" value="1"><span class="val" id="pixelSizeVal">1</span></div>
            <div class="row"><label>Film Grain</label><input type="range" id="filmGrain" min="0" max="1" step="0.01" value="0"><span class="val" id="filmGrainVal">0.00</span></div>
            <div class="row"><label>Bloom</label><input type="range" id="bloom" min="0" max="1" step="0.01" value="0"><span class="val" id="bloomVal">0.00</span></div>
          </div>
          <!-- CAMERA SHAKE -->
          <div id="tab-shake" class="section" style="display:none">
            <h3>Camera Shake</h3>
            <div class="row"><label>Amplitude</label><input type="range" id="shakeAmplitude" min="0" max="50" step="0.5" value="5"><span class="val" id="shakeAmplitudeVal">5.0</span></div>
            <div class="row"><label>Frequency</label><input type="range" id="shakeFrequency" min="1" max="60" step="1" value="20"><span class="val" id="shakeFrequencyVal">20</span></div>
            <div class="row"><label>Duration (s)</label><input type="range" id="shakeDuration" min="0.1" max="5" step="0.1" value="0.5"><span class="val" id="shakeDurationVal">0.50</span></div>
            <div class="row"><label>Decay</label><input type="range" id="shakeDecay" min="0.5" max="10" step="0.1" value="3"><span class="val" id="shakeDecayVal">3.0</span></div>
            <div class="row"><label>Rotation Shake</label><input type="range" id="shakeRotation" min="0" max="10" step="0.1" value="0"><span class="val" id="shakeRotationVal">0.0</span></div>
            <div class="row"><label>Trauma based</label><input type="checkbox" id="shakeTrauma" checked></div>
          </div>
          <!-- OVERLAY PRESETS -->
          <div id="tab-overlay" class="section" style="display:none">
            <h3>Overlay Presets</h3>
            <div class="row"><label>Preset</label>
              <select id="overlayPreset"><option>None</option><option>Blood Vignette</option><option>Underwater</option><option>Night Vision</option><option>Thermal Vision</option><option>Old Film</option><option>Heatwave</option><option>Poison</option><option>Fire Overlay</option></select>
            </div>
            <div class="row"><label>Overlay Alpha</label><input type="range" id="overlayAlpha" min="0" max="1" step="0.01" value="0.5"><span class="val" id="overlayAlphaVal">0.50</span></div>
            <div class="row"><label>Overlay Color</label><input type="color" id="overlayColor" value="#ff0000"></div>
            <div class="row"><label>Pulsate</label><input type="checkbox" id="overlayPulsate"></div>
            <div class="row"><label>Pulse Speed</label><input type="range" id="overlayPulseSpeed" min="0.5" max="10" step="0.5" value="2"><span class="val" id="overlayPulseSpeedVal">2.0</span></div>
          </div>
        </div>

        <div>
          <div class="preview-box">
            <canvas id="preview" width="640" height="360"></canvas>
          </div>
          <h3>Generated Lua Code</h3>
          <pre id="codeOut" style="font-family:'Cascadia Code',monospace;font-size:11px;background:#1a1a1a;color:#9cdcfe;border-radius:4px;padding:10px;overflow-x:auto;white-space:pre;"></pre>
          <div class="btn-row">
            <button id="btnCopy">\u{1F4CB} Copy Code</button>
            <button id="btnInsert">\u2935 Insert at Cursor</button>
          </div>
        </div>
      </div>
    `,`
      const vscode = acquireVsCodeApi();
      let currentTab = 'weather';

      // Tab switching
      document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', () => {
          currentTab = tab.dataset.tab;
          document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
          tab.classList.add('active');
          document.querySelectorAll('[id^="tab-"]').forEach(s => s.style.display = 'none');
          document.getElementById('tab-' + currentTab).style.display = '';
          updateCode();
        });
      });

      // Live value labels
      document.querySelectorAll('input[type=range]').forEach(r => {
        const valEl = document.getElementById(r.id + 'Val');
        function fmt(v) {
          if (r.id === 'hour') { const h = Math.floor(v); const m = Math.round((v-h)*60); return h+':'+(m<10?'0':'')+m; }
          if (r.step && parseFloat(r.step) >= 1) return Math.round(v).toString();
          return parseFloat(v).toFixed(2);
        }
        if (valEl) { valEl.textContent = fmt(r.value); r.addEventListener('input', () => { valEl.textContent = fmt(r.value); updateCode(); drawPreview(); }); }
        r.addEventListener('input', updateCode);
      });
      document.querySelectorAll('input[type=color],input[type=checkbox],select').forEach(el => el.addEventListener('change', () => { updateCode(); drawPreview(); }));

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
      document.getElementById('todPreset').addEventListener('change', (e) => {
        const p = todPresets[e.target.value];
        if (!p) return;
        document.getElementById('hour').value = p.hour;
        document.getElementById('hourVal').textContent = (() => { const h=Math.floor(p.hour),m=Math.round((p.hour-h)*60); return h+':'+(m<10?'0':'')+m; })();
        document.getElementById('skyColor').value = p.sky;
        document.getElementById('ambientLight').value = p.ambient;
        document.getElementById('ambientLightVal').textContent = p.ambient.toFixed(2);
        document.getElementById('sunColor').value = p.sun;
        updateCode(); drawPreview();
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
      document.getElementById('weatherPreset').addEventListener('change', (e) => {
        const p = wPresets[e.target.value];
        if (!p) return;
        ['intensity','windX','windY'].forEach(k => {
          const el = document.getElementById('weather'+k.charAt(0).toUpperCase()+k.slice(1)) || document.getElementById(k);
          if (el && p[k] !== undefined) { el.value = p[k]; const v = document.getElementById(el.id+'Val'); if(v) v.textContent = p[k]; }
        });
        if(p.color) document.getElementById('weatherColor').value = p.color;
        if(p.fogDensity !== undefined) { document.getElementById('fogDensity').value = p.fogDensity; document.getElementById('fogDensityVal').textContent = p.fogDensity.toFixed(2); }
        updateCode(); drawPreview();
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
      document.getElementById('overlayPreset').addEventListener('change', (e) => {
        const p = oPresets[e.target.value]; if(!p) return;
        document.getElementById('overlayColor').value = p.color;
        document.getElementById('overlayAlpha').value = p.alpha;
        document.getElementById('overlayAlphaVal').textContent = p.alpha.toFixed(2);
        document.getElementById('overlayPulsate').checked = !!p.pulsate;
        if(p.speed) { document.getElementById('overlayPulseSpeed').value = p.speed; document.getElementById('overlayPulseSpeedVal').textContent = p.speed.toFixed(1); }
        updateCode(); drawPreview();
      });

      function g(id) { return document.getElementById(id); }
      function fv(id) { return parseFloat(g(id).value); }

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
            code += 'local weather = lurek.postfx.createWeather({\\n';
            code += '  preset   = "' + preset.toLowerCase().replace(/ /g,'_') + '",\\n';
            code += '  intensity = ' + intensity.toFixed(2) + ',\\n';
            code += '  wind      = lurek.math.vec2(' + windX + ', ' + windY + '),\\n';
            code += '  color     = lurek.graphics.newColor("' + color + '"),\\n';
            code += '})\\n\\n';
            code += 'function lurek.update(dt)\\n  weather:update(dt)\\nend\\n';
            code += 'function lurek.draw()\\n  weather:draw()\\n';
            if (fogDensity > 0) code += '  lurek.postfx.fog({ density=' + fogDensity.toFixed(2) + ', color=lurek.graphics.newColor("' + fogColor + '") })\\n';
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
          code += 'local tod = lurek.postfx.createTimeOfDay({\\n';
          code += '  hour         = ' + hour.toFixed(2) + ',\\n';
          code += '  sky_color    = lurek.graphics.newColor("' + sky + '"),\\n';
          code += '  sun_color    = lurek.graphics.newColor("' + sun + '"),\\n';
          code += '  ambient      = ' + ambient.toFixed(2) + ',\\n';
          code += '  moon_enabled = ' + moon + ',\\n';
          code += '  stars        = ' + stars + ',\\n';
          code += '  speed        = ' + speed.toFixed(3) + ',\\n';
          code += '})\\n\\n';
          code += 'function lurek.update(dt)\\n  tod:update(dt)\\nend\\n';
          code += 'function lurek.draw()\\n  tod:drawSky()\\n  -- draw game world here\\n  tod:drawOverlay()\\nend';
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
          code = '-- Screen PostFX\\nfunction lurek.draw()\\n  -- draw game\\n  local fx = lurek.postfx.begin()\\n';
          if (vig > 0)    lines.push('  fx:vignette({ strength=' + vig.toFixed(2) + ', color=lurek.graphics.newColor("' + g('vignetteColor').value + '") })');
          if (scan > 0)   lines.push('  fx:scanlines({ alpha=' + scan.toFixed(2) + ' })');
          if (sat !== 1)  lines.push('  fx:saturation(' + sat.toFixed(2) + ')');
          if (bright !== 1) lines.push('  fx:brightness(' + bright.toFixed(2) + ')');
          if (cont !== 1) lines.push('  fx:contrast(' + cont.toFixed(2) + ')');
          if (chrom > 0)  lines.push('  fx:chromaticAberration(' + chrom.toFixed(1) + ')');
          if (px > 1)     lines.push('  fx:pixelate(' + px + ')');
          if (grain > 0)  lines.push('  fx:filmGrain(' + grain.toFixed(2) + ')');
          if (bloom_ > 0) lines.push('  fx:bloom({ threshold=0.7, strength=' + bloom_.toFixed(2) + ' })');
          code += lines.join('\\n') + '\\n  lurek.postfx.finish(fx)\\nend';
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
          code += 'function lurek.update(dt)\\n  shaker:update(dt)\\nend\\n';
          code += 'function lurek.draw()\\n  shaker:push()\\n  -- draw everything here\\n  shaker:pop()\\nend';
        } else if (currentTab === 'overlay') {
          const preset = g('overlayPreset').value;
          const alpha = fv('overlayAlpha');
          const color = g('overlayColor').value;
          const pulse = g('overlayPulsate').checked;
          const speed = fv('overlayPulseSpeed');
          code = '-- Overlay: ' + preset + '\\n';
          code += 'local overlay = lurek.postfx.createOverlay({\\n';
          code += '  preset  = "' + preset.toLowerCase().replace(/ /g,'_') + '",\\n';
          code += '  color   = lurek.graphics.newColor("' + color + '"),\\n';
          code += '  alpha   = ' + alpha.toFixed(2) + ',\\n';
          code += '  pulsate = ' + pulse + ',\\n';
          if (pulse) code += '  speed   = ' + speed.toFixed(1) + ',\\n';
          code += '})\\n\\n';
          code += 'function lurek.update(dt)\\n  overlay:update(dt)\\nend\\n';
          code += 'function lurek.draw()\\n  -- draw game\\n  overlay:draw()\\nend';
        }
        g('codeOut').textContent = code;
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
          // ground
          ctx.fillStyle = '#2d4a1e'; ctx.fillRect(0,H*0.7,W,H*0.3);
          // sun position based on hour
          const hour = fv('hour');
          const sunX = (hour/24)*W;
          const sunY = H*0.5 - Math.sin((hour/24)*Math.PI)*H*0.4;
          if (hour > 5 && hour < 20) {
            ctx.beginPath(); ctx.arc(sunX,sunY,20,0,Math.PI*2);
            ctx.fillStyle = g('sunColor').value; ctx.fill();
          }
          // ambient overlay
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
          // Generic preview
          ctx.fillStyle = '#1e2d3a'; ctx.fillRect(0,0,W,H);
          ctx.fillStyle = '#2d4a1e'; ctx.fillRect(0,H*0.65,W,H*0.35);
          // Simple platformer silhouette
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

      document.getElementById('btnCopy').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyCode', code: g('codeOut').textContent });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertCode', code: g('codeOut').textContent });
      });

      updateCode(); drawPreview();
    `)}};var et=E(require("vscode"));var Fn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.editor.soundDsp","Sound DSP Panel")}handleMessage(e){if(e.type==="copyCode"&&(et.env.clipboard.writeText(e.code),et.window.showInformationMessage("Sound DSP code copied to clipboard.")),e.type==="insertCode"){let t=et.window.activeTextEditor;t?t.insertSnippet(new et.SnippetString(e.code)):et.window.showWarningMessage("Open a Lua file to insert code.")}}getHtml(){let e=R();return D(e,"Sound DSP Panel",`
      body { overflow-y: auto; }
      .layout { display: grid; grid-template-columns: 320px 1fr; gap: 12px; }
      h3 { font-size: 12px; text-transform: uppercase; letter-spacing:.05em; opacity:.6; margin: 16px 0 6px; }
      .row { display: flex; align-items: center; gap: 8px; margin-bottom: 8px; font-size: 13px; }
      .row label { min-width: 150px; opacity:.8; }
      input[type=range] { flex: 1; }
      .val { font-size: 11px; min-width: 44px; text-align:right; opacity:.7; font-family: monospace; }
      select { background: var(--input-background); color: var(--foreground); border: 1px solid var(--border); padding: 2px 6px; border-radius: 3px; font-size: 12px; }
      .tab-row { display: flex; gap: 4px; margin-bottom: 12px; flex-wrap: wrap; }
      .tab { padding: 4px 10px; border-radius: 3px; font-size: 12px; cursor: pointer; background: var(--surface-2); border: none; color: var(--foreground); }
      .tab.active { background: #0e518c; color: #fff; }
      .vis-box { background: #111; border-radius: 6px; border: 1px solid var(--border); padding: 8px; }
      canvas { display: block; border-radius: 4px; }
      .bypass-toggle { display: inline-flex; align-items: center; gap: 6px; cursor: pointer; font-size: 12px; opacity: .7; }
      .bypass-toggle.active { opacity: 1; color: #4fc3f7; }
      .eq-bands { display: flex; gap: 6px; align-items: flex-end; height: 120px; padding: 8px; background: #111; border-radius: 6px; border: 1px solid var(--border); }
      .eq-band { display: flex; flex-direction: column; align-items: center; gap: 4px; flex: 1; }
      .eq-band input[type=range] { writing-mode: vertical-lr; direction: rtl; width: 24px; height: 80px; }
      .eq-band label { font-size: 10px; opacity: .6; white-space: nowrap; }
      .eq-band .val { font-size: 10px; }
      .preset-row { display: flex; align-items: center; gap: 8px; margin-bottom: 12px; flex-wrap: wrap; }
      .preset-btn { font-size: 11px; padding: 3px 8px; border-radius: 3px; cursor: pointer; background: var(--surface-2); border: 1px solid var(--border); color: var(--foreground); }
      .preset-btn:hover { background: #0e518c; color: #fff; border-color: #0e518c; }
      .signal-chain { display: flex; gap: 6px; align-items: center; flex-wrap: wrap; margin-bottom: 12px; font-size: 12px; }
      .chain-node { background: #1e3a52; border: 1px solid #0e518c; border-radius: 4px; padding: 3px 8px; color: #4fc3f7; }
      .chain-arrow { opacity: .4; }
    `,`
      <h2 style="margin:0 0 12px;font-size:14px">\u{1F50A} Sound DSP Panel</h2>
      <div class="tab-row" id="tabs">
        <button class="tab active" data-tab="chain">Signal Chain</button>
        <button class="tab" data-tab="eq">Equalizer</button>
        <button class="tab" data-tab="reverb">Reverb</button>
        <button class="tab" data-tab="echo">Echo / Delay</button>
        <button class="tab" data-tab="chorus">Chorus / Flanger</button>
        <button class="tab" data-tab="pitch">Pitch Shift</button>
        <button class="tab" data-tab="dynamics">Dynamics</button>
        <button class="tab" data-tab="generator">Sound Gen</button>
      </div>
      <div class="layout">
        <div>
          <!-- SIGNAL CHAIN -->
          <div id="tab-chain">
            <h3>Active Signal Chain</h3>
            <div id="signalChain" class="signal-chain"></div>
            <h3>Effect Order (drag to reorder)</h3>
            <div id="effectList" style="font-size:12px;"></div>
            <h3>Master</h3>
            <div class="row"><label>Master Volume</label><input type="range" id="masterVolume" min="0" max="2" step="0.01" value="1"><span class="val" id="masterVolumeVal">1.00</span></div>
            <div class="row"><label>Master Pan</label><input type="range" id="masterPan" min="-1" max="1" step="0.01" value="0"><span class="val" id="masterPanVal">0.00</span></div>
            <div class="row"><label>Sample Rate</label>
              <select id="sampleRate"><option value="22050">22050 Hz</option><option value="44100" selected>44100 Hz</option><option value="48000">48000 Hz</option></select>
            </div>
          </div>
          <!-- EQ -->
          <div id="tab-eq" style="display:none">
            <h3>Equalizer (7-band Parametric)</h3>
            <div class="preset-row">
              <span style="font-size:12px;opacity:.6">Preset:</span>
              <button class="preset-btn" data-eq="flat">Flat</button>
              <button class="preset-btn" data-eq="bass">Bass Boost</button>
              <button class="preset-btn" data-eq="treble">Treble Boost</button>
              <button class="preset-btn" data-eq="vocal">Vocal</button>
              <button class="preset-btn" data-eq="underwater">Underwater</button>
              <button class="preset-btn" data-eq="telephone">Telephone</button>
              <button class="preset-btn" data-eq="radio">Lo-Fi Radio</button>
            </div>
            <div class="eq-bands" id="eqBands"></div>
          </div>
          <!-- REVERB -->
          <div id="tab-reverb" style="display:none">
            <h3>Reverb</h3>
            <div class="preset-row">
              <span style="font-size:12px;opacity:.6">Room:</span>
              <button class="preset-btn" data-reverb="small">Small Room</button>
              <button class="preset-btn" data-reverb="medium">Medium Hall</button>
              <button class="preset-btn" data-reverb="large">Large Hall</button>
              <button class="preset-btn" data-reverb="cave">Cave</button>
              <button class="preset-btn" data-reverb="plate">Plate</button>
              <button class="preset-btn" data-reverb="spring">Spring</button>
            </div>
            <div class="row"><label>Room Size</label><input type="range" id="reverbRoom" min="0" max="1" step="0.01" value="0.5"><span class="val" id="reverbRoomVal">0.50</span></div>
            <div class="row"><label>Damping</label><input type="range" id="reverbDamp" min="0" max="1" step="0.01" value="0.5"><span class="val" id="reverbDampVal">0.50</span></div>
            <div class="row"><label>Wet / Dry Mix</label><input type="range" id="reverbMix" min="0" max="1" step="0.01" value="0.3"><span class="val" id="reverbMixVal">0.30</span></div>
            <div class="row"><label>Pre-delay (ms)</label><input type="range" id="reverbPredelay" min="0" max="100" step="1" value="10"><span class="val" id="reverbPredelayVal">10</span></div>
            <div class="row"><label>Width</label><input type="range" id="reverbWidth" min="0" max="1" step="0.01" value="1"><span class="val" id="reverbWidthVal">1.00</span></div>
            <div class="row"><label>Decay (s)</label><input type="range" id="reverbDecay" min="0.1" max="10" step="0.1" value="2"><span class="val" id="reverbDecayVal">2.0</span></div>
          </div>
          <!-- ECHO/DELAY -->
          <div id="tab-echo" style="display:none">
            <h3>Echo / Delay</h3>
            <div class="row"><label>Delay Time (ms)</label><input type="range" id="echoDelay" min="10" max="2000" step="10" value="400"><span class="val" id="echoDelayVal">400</span></div>
            <div class="row"><label>Feedback</label><input type="range" id="echoFeedback" min="0" max="0.99" step="0.01" value="0.4"><span class="val" id="echoFeedbackVal">0.40</span></div>
            <div class="row"><label>Wet / Dry Mix</label><input type="range" id="echoMix" min="0" max="1" step="0.01" value="0.4"><span class="val" id="echoMixVal">0.40</span></div>
            <div class="row"><label>Ping-Pong</label><input type="checkbox" id="echoPingPong"></div>
            <div class="row"><label>Sync to BPM</label><input type="checkbox" id="echoSyncBpm"></div>
            <div class="row" id="bpmRow"><label>BPM</label><input type="range" id="echoBpm" min="60" max="200" step="1" value="120"><span class="val" id="echoBpmVal">120</span></div>
            <div class="row" id="divRow"><label>Division</label>
              <select id="echoDiv"><option value="1">1/4 note</option><option value="0.5">1/8 note</option><option value="0.75">Dotted 1/8</option><option value="0.333">1/8 triplet</option></select>
            </div>
          </div>
          <!-- CHORUS/FLANGER -->
          <div id="tab-chorus" style="display:none">
            <h3>Chorus / Flanger</h3>
            <div class="row"><label>Mode</label>
              <select id="chorusMode"><option>Chorus</option><option>Flanger</option><option>Ensemble</option><option>Vibrato</option></select>
            </div>
            <div class="row"><label>Depth</label><input type="range" id="chorusDepth" min="0" max="1" step="0.01" value="0.5"><span class="val" id="chorusDepthVal">0.50</span></div>
            <div class="row"><label>Rate (Hz)</label><input type="range" id="chorusRate" min="0.1" max="10" step="0.1" value="1.5"><span class="val" id="chorusRateVal">1.50</span></div>
            <div class="row"><label>Wet / Dry Mix</label><input type="range" id="chorusMix" min="0" max="1" step="0.01" value="0.4"><span class="val" id="chorusMixVal">0.40</span></div>
            <div class="row"><label>Voices</label><input type="range" id="chorusVoices" min="2" max="8" step="1" value="3"><span class="val" id="chorusVoicesVal">3</span></div>
            <div class="row"><label>Stereo Spread</label><input type="range" id="chorusSpread" min="0" max="1" step="0.01" value="0.7"><span class="val" id="chorusSpreadVal">0.70</span></div>
            <div class="row"><label>Flange Feedback</label><input type="range" id="flangerFeedback" min="0" max="0.95" step="0.01" value="0.5"><span class="val" id="flangerFeedbackVal">0.50</span></div>
          </div>
          <!-- PITCH -->
          <div id="tab-pitch" style="display:none">
            <h3>Pitch Shift</h3>
            <div class="row"><label>Semitones</label><input type="range" id="pitchSemitones" min="-24" max="24" step="1" value="0"><span class="val" id="pitchSemitonesVal">0 st</span></div>
            <div class="row"><label>Fine Tune (cents)</label><input type="range" id="pitchCents" min="-100" max="100" step="1" value="0"><span class="val" id="pitchCentsVal">0\xA2</span></div>
            <div class="row"><label>Formant Preserve</label><input type="checkbox" id="pitchFormant"></div>
            <div class="row"><label>Pitch Rate</label><input type="range" id="pitchRate" min="0.25" max="4" step="0.05" value="1"><span class="val" id="pitchRateVal">1.00\xD7</span></div>
            <h3>Pitch Envelope</h3>
            <div class="row"><label>Pitch Sweep Start</label><input type="range" id="pitchSweepFrom" min="-12" max="12" step="1" value="0"><span class="val" id="pitchSweepFromVal">0 st</span></div>
            <div class="row"><label>Pitch Sweep End</label><input type="range" id="pitchSweepTo" min="-12" max="12" step="1" value="0"><span class="val" id="pitchSweepToVal">0 st</span></div>
            <div class="row"><label>Sweep Time (s)</label><input type="range" id="pitchSweepTime" min="0.01" max="2" step="0.01" value="0.5"><span class="val" id="pitchSweepTimeVal">0.50</span></div>
          </div>
          <!-- DYNAMICS -->
          <div id="tab-dynamics" style="display:none">
            <h3>Compressor</h3>
            <div class="row"><label>Threshold (dB)</label><input type="range" id="compThreshold" min="-60" max="0" step="1" value="-24"><span class="val" id="compThresholdVal">-24</span></div>
            <div class="row"><label>Ratio</label><input type="range" id="compRatio" min="1" max="20" step="0.5" value="4"><span class="val" id="compRatioVal">4:1</span></div>
            <div class="row"><label>Attack (ms)</label><input type="range" id="compAttack" min="0.1" max="200" step="0.1" value="10"><span class="val" id="compAttackVal">10</span></div>
            <div class="row"><label>Release (ms)</label><input type="range" id="compRelease" min="10" max="2000" step="10" value="200"><span class="val" id="compReleaseVal">200</span></div>
            <div class="row"><label>Makeup Gain (dB)</label><input type="range" id="compMakeup" min="0" max="24" step="0.5" value="0"><span class="val" id="compMakeupVal">0</span></div>
            <h3>Gate / Limiter</h3>
            <div class="row"><label>Gate Threshold (dB)</label><input type="range" id="gateThreshold" min="-80" max="0" step="1" value="-60"><span class="val" id="gateThresholdVal">-60</span></div>
            <div class="row"><label>Limiter Ceiling (dB)</label><input type="range" id="limiterCeil" min="-20" max="0" step="0.5" value="-0.3"><span class="val" id="limiterCeilVal">-0.3</span></div>
            <h3>Distortion</h3>
            <div class="row"><label>Drive</label><input type="range" id="distDrive" min="0" max="1" step="0.01" value="0"><span class="val" id="distDriveVal">0.00</span></div>
            <div class="row"><label>Mode</label>
              <select id="distMode"><option>Soft Clip</option><option>Hard Clip</option><option>Fuzz</option><option>Bit Crush</option><option>Overdrive</option></select>
            </div>
            <div class="row"><label>Mix</label><input type="range" id="distMix" min="0" max="1" step="0.01" value="0.5"><span class="val" id="distMixVal">0.50</span></div>
          </div>
          <!-- GENERATOR -->
          <div id="tab-generator" style="display:none">
            <h3>Procedural Sound Generator</h3>
            <div class="row"><label>Type</label>
              <select id="genType"><option>Sine</option><option>Square</option><option>Sawtooth</option><option>Triangle</option><option>Noise</option><option>Pulse</option></select>
            </div>
            <div class="row"><label>Frequency (Hz)</label><input type="range" id="genFreq" min="20" max="4000" step="1" value="440"><span class="val" id="genFreqVal">440 Hz</span></div>
            <div class="row"><label>Volume</label><input type="range" id="genVol" min="0" max="1" step="0.01" value="0.5"><span class="val" id="genVolVal">0.50</span></div>
            <div class="row"><label>Duration (s)</label><input type="range" id="genDur" min="0.01" max="5" step="0.01" value="0.5"><span class="val" id="genDurVal">0.50</span></div>
            <h3>ADSR Envelope</h3>
            <div class="row"><label>Attack (s)</label><input type="range" id="adsrAttack" min="0.001" max="2" step="0.001" value="0.01"><span class="val" id="adsrAttackVal">0.010</span></div>
            <div class="row"><label>Decay (s)</label><input type="range" id="adsrDecay" min="0.001" max="2" step="0.001" value="0.1"><span class="val" id="adsrDecayVal">0.100</span></div>
            <div class="row"><label>Sustain Level</label><input type="range" id="adsrSustain" min="0" max="1" step="0.01" value="0.7"><span class="val" id="adsrSustainVal">0.70</span></div>
            <div class="row"><label>Release (s)</label><input type="range" id="adsrRelease" min="0.001" max="3" step="0.001" value="0.3"><span class="val" id="adsrReleaseVal">0.300</span></div>
            <h3>Sound Presets</h3>
            <div class="preset-row">
              <button class="preset-btn" data-sound="laser">Laser</button>
              <button class="preset-btn" data-sound="explosion">Explosion</button>
              <button class="preset-btn" data-sound="jump">Jump</button>
              <button class="preset-btn" data-sound="coin">Coin</button>
              <button class="preset-btn" data-sound="powerup">Power-up</button>
              <button class="preset-btn" data-sound="hurt">Hurt</button>
              <button class="preset-btn" data-sound="blip">UI Blip</button>
            </div>
          </div>
        </div>

        <div>
          <div class="vis-box">
            <canvas id="visCanvas" width="560" height="120"></canvas>
          </div>
          <div style="display:flex;gap:8px;margin-top:6px;font-size:11px;opacity:.5;align-items:center">
            <span>\u25C9 Frequency Response</span>
            <label><input type="radio" name="visMode" value="freq" checked> Frequency</label>
            <label><input type="radio" name="visMode" value="wave"> Waveform</label>
            <label><input type="radio" name="visMode" value="lissajous"> Lissajous</label>
          </div>
          <h3>Generated Lua Code</h3>
          <pre id="codeOut" style="font-family:'Cascadia Code',monospace;font-size:11px;background:#1a1a1a;color:#9cdcfe;border-radius:4px;padding:10px;overflow-x:auto;white-space:pre;max-height:340px;overflow-y:auto;"></pre>
          <div style="display:flex;gap:8px;margin-top:8px;">
            <button id="btnCopy">\u{1F4CB} Copy Code</button>
            <button id="btnInsert">\u2935 Insert at Cursor</button>
          </div>
        </div>
      </div>
    `,`
      const vscode = acquireVsCodeApi();
      let currentTab = 'chain';

      document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', () => {
          currentTab = tab.dataset.tab;
          document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
          tab.classList.add('active');
          document.querySelectorAll('[id^="tab-"]').forEach(s => s.style.display = 'none');
          document.getElementById('tab-' + currentTab).style.display = '';
          updateCode(); drawVis();
        });
      });

      // Range value labels
      document.querySelectorAll('input[type=range]').forEach(r => {
        const v = document.getElementById(r.id + 'Val');
        function fmt(val) {
          if (r.id === 'pitchSemitones' || r.id === 'pitchSweepFrom' || r.id === 'pitchSweepTo') return val + ' st';
          if (r.id === 'pitchCents') return val + '\xA2';
          if (r.id === 'pitchRate') return parseFloat(val).toFixed(2) + '\xD7';
          if (r.id === 'compRatio') return parseFloat(val).toFixed(1) + ':1';
          if (r.id === 'genFreq') return val + ' Hz';
          if (r.step && parseFloat(r.step) >= 1) return Math.round(val).toString();
          return parseFloat(val).toFixed(parseFloat(r.step) < 0.01 ? 3 : 2);
        }
        if (v) { v.textContent = fmt(r.value); r.addEventListener('input', () => { v.textContent = fmt(r.value); updateCode(); drawVis(); }); }
        r.addEventListener('input', updateCode);
      });
      document.querySelectorAll('select,input[type=checkbox]').forEach(el => el.addEventListener('change', () => { updateCode(); drawVis(); }));

      // Build EQ bands
      const EQ_BANDS = [
        { freq:'60Hz', id:'eq0' }, { freq:'150Hz', id:'eq1' }, { freq:'400Hz', id:'eq2' },
        { freq:'1kHz', id:'eq3' }, { freq:'2.5kHz', id:'eq4' }, { freq:'6kHz', id:'eq5' }, { freq:'16kHz', id:'eq6' },
      ];
      const eqContainer = document.getElementById('eqBands');
      EQ_BANDS.forEach(band => {
        eqContainer.innerHTML += '<div class="eq-band"><input type="range" id="' + band.id + '" min="-12" max="12" step="0.5" value="0" orient="vertical"><label>' + band.freq + '</label><span class="val" id="' + band.id + 'Val">0</span></div>';
      });
      document.querySelectorAll('#eqBands input[type=range]').forEach(r => {
        const v = document.getElementById(r.id + 'Val');
        if (v) { r.addEventListener('input', () => { v.textContent = parseFloat(r.value).toFixed(1); updateCode(); drawVis(); }); }
      });

      // EQ presets
      const eqPresets = {
        flat:       [0,0,0,0,0,0,0],
        bass:       [8,6,3,0,-1,-1,-2],
        treble:     [-1,-1,0,1,3,5,7],
        vocal:      [-2,0,2,4,3,1,-1],
        underwater: [-8,-6,-4,-2,-6,-10,-12],
        telephone:  [-12,0,4,6,4,0,-12],
        radio:      [-10,-4,2,6,4,2,-8],
      };
      document.querySelectorAll('[data-eq]').forEach(btn => {
        btn.addEventListener('click', () => {
          const vals = eqPresets[btn.dataset.eq];
          EQ_BANDS.forEach((band, i) => {
            const el = document.getElementById(band.id);
            const v = document.getElementById(band.id + 'Val');
            if (el) { el.value = vals[i]; if(v) v.textContent = vals[i].toFixed(1); }
          });
          updateCode(); drawVis();
        });
      });

      // Reverb presets
      const reverbPresets = {
        small:  { room:0.2, damp:0.7, mix:0.2, predelay:5,  width:0.6, decay:0.5 },
        medium: { room:0.5, damp:0.5, mix:0.3, predelay:20, width:0.9, decay:2.0 },
        large:  { room:0.85,damp:0.3, mix:0.4, predelay:40, width:1.0, decay:5.0 },
        cave:   { room:0.9, damp:0.1, mix:0.5, predelay:50, width:0.8, decay:7.0 },
        plate:  { room:0.4, damp:0.8, mix:0.35,predelay:0,  width:1.0, decay:1.5 },
        spring: { room:0.3, damp:0.6, mix:0.4, predelay:10, width:0.5, decay:1.2 },
      };
      document.querySelectorAll('[data-reverb]').forEach(btn => {
        btn.addEventListener('click', () => {
          const p = reverbPresets[btn.dataset.reverb];
          Object.entries({ reverbRoom:p.room, reverbDamp:p.damp, reverbMix:p.mix, reverbPredelay:p.predelay, reverbWidth:p.width, reverbDecay:p.decay }).forEach(([id,val]) => {
            const el = document.getElementById(id);
            const v = document.getElementById(id+'Val');
            if (el) {
              el.value = val;
              if (v) v.textContent = parseFloat(el.step) >= 1 ? Math.round(val) : parseFloat(val).toFixed(2);
            }
          });
          updateCode(); drawVis();
        });
      });

      // Sound presets
      const soundPresets = {
        laser:     { type:'Square',  freq:880, vol:0.7, dur:0.15, atk:0.001,dec:0.05,sus:0.3,rel:0.1,  sweepFrom:6,  sweepTo:-12, sweepTime:0.15 },
        explosion: { type:'Noise',   freq:80,  vol:0.9, dur:1.2,  atk:0.001,dec:0.2, sus:0.2,rel:1.0,  sweepFrom:0,  sweepTo:-8,  sweepTime:0.8  },
        jump:      { type:'Sine',    freq:220, vol:0.6, dur:0.3,  atk:0.005,dec:0.1, sus:0.0,rel:0.15, sweepFrom:0,  sweepTo:7,   sweepTime:0.2  },
        coin:      { type:'Sine',    freq:660, vol:0.7, dur:0.2,  atk:0.001,dec:0.05,sus:0.5,rel:0.1,  sweepFrom:0,  sweepTo:5,   sweepTime:0.1  },
        powerup:   { type:'Sawtooth',freq:220, vol:0.6, dur:0.6,  atk:0.005,dec:0.1, sus:0.7,rel:0.2,  sweepFrom:-5, sweepTo:7,   sweepTime:0.5  },
        hurt:      { type:'Triangle',freq:120, vol:0.8, dur:0.25, atk:0.001,dec:0.05,sus:0.3,rel:0.2,  sweepFrom:2,  sweepTo:-6,  sweepTime:0.2  },
        blip:      { type:'Sine',    freq:440, vol:0.4, dur:0.07, atk:0.001,dec:0.01,sus:0.0,rel:0.05, sweepFrom:0,  sweepTo:0,   sweepTime:0.0  },
      };
      document.querySelectorAll('[data-sound]').forEach(btn => {
        btn.addEventListener('click', () => {
          const p = soundPresets[btn.dataset.sound];
          document.getElementById('genType').value = p.type;
          const fields = { genFreq:p.freq, genVol:p.vol, genDur:p.dur, adsrAttack:p.atk, adsrDecay:p.dec, adsrSustain:p.sus, adsrRelease:p.rel, pitchSweepFrom:p.sweepFrom, pitchSweepTo:p.sweepTo, pitchSweepTime:p.sweepTime };
          Object.entries(fields).forEach(([id,val]) => {
            const el = document.getElementById(id);
            const v = document.getElementById(id+'Val');
            if (el) { el.value = val; if(v) v.textContent = el.step && parseFloat(el.step) >= 1 ? Math.round(val) : parseFloat(val).toFixed(parseFloat(el.step||'0.01') < 0.01 ? 3 : 2); }
          });
          updateCode(); drawVis();
        });
      });

      function g(id) { return document.getElementById(id); }
      function fv(id) { return parseFloat(g(id).value); }
      function bv(id) { return g(id).checked; }
      function sv(id) { return g(id).value; }

      function updateCode() {
        let code = '';

        if (currentTab === 'chain') {
          code = '-- Sound DSP Chain\\n';
          code += 'local dsp = lurek.sound.createDsp()\\n\\n';
          code += 'dsp:setMasterVolume(' + fv('masterVolume').toFixed(2) + ')\\n';
          code += 'dsp:setMasterPan(' + fv('masterPan').toFixed(2) + ')\\n';
          code += 'dsp:setSampleRate(' + sv('sampleRate') + ')\\n\\n';
          code += '-- Apply DSP to a source:\\n';
          code += 'local src = lurek.sound.load("my_sound.wav")\\n';
          code += 'lurek.sound.setDsp(src, dsp)\\n';
          code += 'lurek.sound.play(src)';
        } else if (currentTab === 'eq') {
          code = '-- 7-Band Parametric EQ\\n';
          code += 'local eq = lurek.sound.createEq({\\n';
          const freqs = ['60','150','400','1000','2500','6000','16000'];
          EQ_BANDS.forEach((band, i) => {
            const gain = fv(band.id);
            if (gain !== 0) code += '  { freq=' + freqs[i] + ', gain=' + gain.toFixed(1) + ' },\\n';
          });
          code += '})\\n';
          code += 'lurek.sound.addEffect(src, eq)';
        } else if (currentTab === 'reverb') {
          code = '-- Reverb Effect\\n';
          code += 'local reverb = lurek.sound.createReverb({\\n';
          code += '  room_size  = ' + fv('reverbRoom').toFixed(2) + ',\\n';
          code += '  damping    = ' + fv('reverbDamp').toFixed(2) + ',\\n';
          code += '  wet_dry    = ' + fv('reverbMix').toFixed(2) + ',\\n';
          code += '  pre_delay  = ' + fv('reverbPredelay') + ',  -- ms\\n';
          code += '  width      = ' + fv('reverbWidth').toFixed(2) + ',\\n';
          code += '  decay      = ' + fv('reverbDecay').toFixed(1) + ',\\n';
          code += '})\\n';
          code += 'lurek.sound.addEffect(src, reverb)';
        } else if (currentTab === 'echo') {
          const delay = fv('echoDelay');
          const syncBpm = bv('echoSyncBpm');
          code = '-- Echo / Delay Effect\\n';
          code += 'local echo = lurek.sound.createEcho({\\n';
          if (syncBpm) {
            code += '  bpm        = ' + fv('echoBpm') + ',\\n';
            code += '  division   = ' + fv('echoDiv') + ',\\n';
          } else {
            code += '  delay_ms   = ' + delay + ',\\n';
          }
          code += '  feedback   = ' + fv('echoFeedback').toFixed(2) + ',\\n';
          code += '  wet_dry    = ' + fv('echoMix').toFixed(2) + ',\\n';
          code += '  ping_pong  = ' + bv('echoPingPong') + ',\\n';
          code += '})\\n';
          code += 'lurek.sound.addEffect(src, echo)';
        } else if (currentTab === 'chorus') {
          code = '-- ' + sv('chorusMode') + ' Effect\\n';
          code += 'local chorus = lurek.sound.createChorus({\\n';
          code += '  mode     = "' + sv('chorusMode').toLowerCase() + '",\\n';
          code += '  depth    = ' + fv('chorusDepth').toFixed(2) + ',\\n';
          code += '  rate     = ' + fv('chorusRate').toFixed(2) + ',\\n';
          code += '  wet_dry  = ' + fv('chorusMix').toFixed(2) + ',\\n';
          code += '  voices   = ' + fv('chorusVoices') + ',\\n';
          code += '  spread   = ' + fv('chorusSpread').toFixed(2) + ',\\n';
          if (sv('chorusMode') === 'Flanger') code += '  feedback = ' + fv('flangerFeedback').toFixed(2) + ',\\n';
          code += '})\\n';
          code += 'lurek.sound.addEffect(src, chorus)';
        } else if (currentTab === 'pitch') {
          const semi = fv('pitchSemitones'), cents = fv('pitchCents'), rate = fv('pitchRate');
          const sweepFrom = fv('pitchSweepFrom'), sweepTo = fv('pitchSweepTo'), sweepTime = fv('pitchSweepTime');
          code = '-- Pitch Shift\\n';
          code += 'local pitch = lurek.sound.createPitchShift({\\n';
          if (semi !== 0) code += '  semitones = ' + semi + ',\\n';
          if (cents !== 0) code += '  cents     = ' + cents + ',\\n';
          if (rate !== 1) code += '  rate      = ' + rate.toFixed(2) + ',\\n';
          code += '  preserve_formants = ' + bv('pitchFormant') + ',\\n';
          if (sweepFrom !== 0 || sweepTo !== 0) {
            code += '  sweep = { from=' + sweepFrom + ', to=' + sweepTo + ', time=' + sweepTime.toFixed(2) + ' },\\n';
          }
          code += '})\\n';
          code += 'lurek.sound.addEffect(src, pitch)';
        } else if (currentTab === 'dynamics') {
          code = '-- Dynamics Processing\\n';
          const drive = fv('distDrive');
          code += 'local chain = lurek.sound.createDynamics({\\n';
          code += '  -- Compressor\\n';
          code += '  comp = {\\n';
          code += '    threshold = ' + fv('compThreshold') + ',  -- dB\\n';
          code += '    ratio     = ' + fv('compRatio').toFixed(1) + ',\\n';
          code += '    attack    = ' + fv('compAttack').toFixed(1) + ',  -- ms\\n';
          code += '    release   = ' + fv('compRelease') + ',         -- ms\\n';
          code += '    makeup    = ' + fv('compMakeup').toFixed(1) + ',  -- dB\\n';
          code += '  },\\n';
          code += '  -- Gate\\n';
          code += '  gate = { threshold=' + fv('gateThreshold') + ' },\\n';
          code += '  -- Limiter\\n';
          code += '  limiter = { ceiling=' + fv('limiterCeil').toFixed(1) + ' },\\n';
          if (drive > 0) {
            code += '  -- Distortion\\n';
            code += '  distortion = { drive=' + drive.toFixed(2) + ', mode="' + sv('distMode').toLowerCase().replace(/ /g,'_') + '", mix=' + fv('distMix').toFixed(2) + ' },\\n';
          }
          code += '})\\n';
          code += 'lurek.sound.addEffect(src, chain)';
        } else if (currentTab === 'generator') {
          const type = sv('genType').toLowerCase();
          code = '-- Procedural Sound: ' + sv('genType') + '\\n';
          code += 'local synth = lurek.sound.createSynth({\\n';
          code += '  wave      = "' + type + '",\\n';
          code += '  frequency = ' + fv('genFreq') + ',\\n';
          code += '  volume    = ' + fv('genVol').toFixed(2) + ',\\n';
          code += '  duration  = ' + fv('genDur').toFixed(2) + ',\\n';
          code += '  adsr      = { attack=' + fv('adsrAttack').toFixed(3) + ', decay=' + fv('adsrDecay').toFixed(3) + ', sustain=' + fv('adsrSustain').toFixed(2) + ', release=' + fv('adsrRelease').toFixed(3) + ' },\\n';
          const sf = fv('pitchSweepFrom'), st2 = fv('pitchSweepTo'), sTime = fv('pitchSweepTime');
          if (sf !== 0 || st2 !== 0) code += '  sweep     = { from=' + sf + ', to=' + st2 + ', time=' + sTime.toFixed(2) + ' },\\n';
          code += '})\\n\\n';
          code += '-- Play immediately:\\nlurek.sound.play(lurek.sound.fromSynth(synth))';
        }

        g('codeOut').textContent = code;
        updateChainVis();
      }

      function updateChainVis() {
        const chain = g('signalChain');
        const nodes = ['Input', 'EQ', 'Reverb', 'Echo', 'Chorus/Flanger', 'Pitch', 'Dynamics', 'Master Out'];
        chain.innerHTML = nodes.map(n => '<span class="chain-node">' + n + '</span>').join('<span class="chain-arrow">\u2192</span>');
      }

      function drawVis() {
        const canvas = g('visCanvas');
        if (!canvas) return;
        const ctx = canvas.getContext('2d');
        const W = 560, H = 120;
        ctx.fillStyle = '#111'; ctx.fillRect(0,0,W,H);

        const mode = document.querySelector('input[name=visMode]:checked')?.value || 'freq';

        if (mode === 'freq') {
          // Draw frequency response curve based on EQ
          ctx.strokeStyle = '#4fc3f7'; ctx.lineWidth = 2;
          ctx.beginPath();
          const gains = EQ_BANDS.map((b,i) => { try { return fv(b.id); } catch { return 0; } });
          for (let x = 0; x < W; x++) {
            let gain = 0;
            gains.forEach((g2, i) => { const center = i/EQ_BANDS.length; gain += g2 * Math.exp(-Math.pow((x/W - center)*3, 2)); });
            const y = H/2 - (gain / 12) * (H*0.4);
            if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
          }
          ctx.stroke();
          // Zero line
          ctx.strokeStyle = '#333'; ctx.lineWidth = 1;
          ctx.beginPath(); ctx.moveTo(0,H/2); ctx.lineTo(W,H/2); ctx.stroke();
          // Labels
          ['20Hz','100Hz','1kHz','10kHz','20kHz'].forEach((lbl, i) => {
            const x = [0,0.12,0.52,0.85,1][i]*W;
            ctx.fillStyle = '#555'; ctx.font = '9px sans-serif'; ctx.fillText(lbl, x+2, H-3);
          });
        } else if (mode === 'wave') {
          ctx.strokeStyle = '#4fc3f7'; ctx.lineWidth = 1.5;
          ctx.beginPath();
          for (let x = 0; x < W; x++) {
            const t = x/W * 4 * Math.PI;
            const y = H/2 + Math.sin(t + Math.random()*0.05) * H*0.35;
            if (x === 0) ctx.moveTo(x,y); else ctx.lineTo(x,y);
          }
          ctx.stroke();
        } else {
          // Lissajous
          ctx.strokeStyle = '#4fc3f7'; ctx.lineWidth = 1; ctx.globalAlpha = 0.5;
          ctx.beginPath();
          for (let i = 0; i < 500; i++) {
            const t = (i/500)*Math.PI*20;
            const x = W/2 + Math.sin(t*1.5)*W*0.4;
            const y = H/2 + Math.cos(t)*H*0.4;
            if (i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y);
          }
          ctx.stroke(); ctx.globalAlpha = 1;
        }
      }

      document.querySelectorAll('input[name=visMode]').forEach(r => r.addEventListener('change', drawVis));

      document.getElementById('btnCopy').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyCode', code: g('codeOut').textContent });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertCode', code: g('codeOut').textContent });
      });

      updateCode(); drawVis();
    `)}};var Bn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.spriteAnimEditor","Sprite Animation")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"animation.lua");break}}getHtml(){let e=R();return D(e,"Sprite Animation",`
      .editor-layout {
        display: grid; grid-template-columns: 240px 1fr 220px;
        grid-template-rows: auto 1fr auto auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .frame-list { grid-row: 2; overflow-y: auto; }
      .preview-area { grid-row: 2; display: flex; align-items: center; justify-content: center; background: var(--bg); position: relative; }
      .props-panel { grid-row: 2; }
      .timeline { grid-column: 1 / -1; background: var(--surface); border-top: 1px solid var(--border); padding: 8px; min-height: 120px; }
      .status-bar { grid-column: 1 / -1; }
      .frame-item {
        display: flex; align-items: center; gap: 6px; padding: 4px 8px;
        cursor: pointer; border-radius: 3px; font-size: 12px;
      }
      .frame-item:hover { background: var(--surface-2); }
      .frame-item.selected { background: var(--selection); }
      .frame-thumb { width: 32px; height: 32px; background: var(--surface-2); border: 1px solid var(--border); border-radius: 2px; }
      .playback-controls { display: flex; align-items: center; gap: 4px; }
      .timeline-track {
        display: flex; gap: 2px; padding: 6px 0; overflow-x: auto;
      }
      .timeline-frame {
        width: 40px; height: 40px; background: var(--surface-2); border: 1px solid var(--border);
        border-radius: 2px; cursor: pointer; flex-shrink: 0; position: relative;
        display: flex; align-items: center; justify-content: center; font-size: 10px; color: var(--text-dim);
      }
      .timeline-frame.active { border-color: var(--accent); }
      .tag-list { display: flex; flex-wrap: wrap; gap: 4px; margin-top: 4px; }
      .tag {
        background: var(--accent); color: #fff; padding: 1px 6px; border-radius: 8px;
        font-size: 10px; cursor: pointer;
      }
      .tag .remove { margin-left: 4px; opacity: 0.7; }
      .tag .remove:hover { opacity: 1; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnLoadSheet">Load Sheet</button>
          <div class="sep"></div>
          <label>Cols:</label><input type="number" id="cols" value="4" min="1" max="64" style="width:45px">
          <label>Rows:</label><input type="number" id="rows" value="4" min="1" max="64" style="width:45px">
          <div class="sep"></div>
          <div class="playback-controls">
            <button id="btnFirst">&#9198;</button>
            <button id="btnPrev">&#9664;</button>
            <button id="btnPlay">&#9654; Play</button>
            <button id="btnNext">&#9654;</button>
            <button id="btnLast">&#9197;</button>
          </div>
          <div class="sep"></div>
          <label>Speed:</label>
          <input type="range" id="speed" min="1" max="60" value="12" style="width:80px">
          <span id="speedLabel">12 fps</span>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>

        <div class="panel frame-list">
          <h3>Frames</h3>
          <div id="frameList"></div>
          <div style="margin-top:8px;">
            <button id="btnAddFrame">+ Add Frame</button>
          </div>
        </div>

        <div class="preview-area">
          <canvas id="previewCanvas" width="256" height="256"></canvas>
        </div>

        <div class="panel props-panel">
          <div class="section">
            <h3>Frame Properties</h3>
            <div class="field"><label>Duration (ms)</label><input type="number" id="frameDuration" value="100" min="16" max="5000"></div>
            <div class="field"><label>Origin X</label><input type="number" id="originX" value="0"></div>
            <div class="field"><label>Origin Y</label><input type="number" id="originY" value="0"></div>
          </div>
          <div class="section">
            <h3>Animation</h3>
            <div class="field"><label>Name</label><input type="text" id="animName" value="idle"></div>
            <div class="field-row"><input type="checkbox" id="looping" checked><label for="looping">Loop</label></div>
          </div>
          <div class="section">
            <h3>Tags</h3>
            <div class="tag-list" id="tagList"></div>
            <div class="field-row" style="margin-top:4px;">
              <input type="text" id="newTag" placeholder="New tag..." style="flex:1">
              <button id="btnAddTag">+</button>
            </div>
          </div>
        </div>

        <div class="timeline">
          <h3>Timeline</h3>
          <div class="timeline-track" id="timelineTrack"></div>
        </div>

        <div class="status-bar">
          <span id="statusFrame">Frame: 1/16</span>
          <span id="statusSize">Sheet: 4x4</span>
          <span id="statusAnim">Anim: idle</span>
        </div>
      </div>
    `,`
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
        // Frame list
        const list = document.getElementById('frameList');
        list.innerHTML = '';
        frames.forEach((f, i) => {
          const el = document.createElement('div');
          el.className = 'frame-item' + (i === currentFrame ? ' selected' : '');
          el.innerHTML = '<div class="frame-thumb"></div><span>Frame ' + (i+1) + ' (' + f.duration + 'ms)</span>';
          el.addEventListener('click', () => { currentFrame = i; rebuildUI(); });
          list.appendChild(el);
        });
        // Timeline
        const track = document.getElementById('timelineTrack');
        track.innerHTML = '';
        frames.forEach((f, i) => {
          const el = document.createElement('div');
          el.className = 'timeline-frame' + (i === currentFrame ? ' active' : '');
          el.textContent = String(i + 1);
          el.addEventListener('click', () => { currentFrame = i; rebuildUI(); });
          track.appendChild(el);
        });
        // Props
        if (frames[currentFrame]) {
          document.getElementById('frameDuration').value = frames[currentFrame].duration;
          document.getElementById('originX').value = frames[currentFrame].originX;
          document.getElementById('originY').value = frames[currentFrame].originY;
        }
        // Status
        document.getElementById('statusFrame').textContent = 'Frame: ' + (currentFrame+1) + '/' + frames.length;
        document.getElementById('statusSize').textContent = 'Sheet: ' + cols + 'x' + rows;
        renderPreview();
      }

      function renderPreview() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        const fw = canvas.width / cols;
        const fh = canvas.height / rows;
        // Draw grid
        ctx.strokeStyle = '#3c3c3c';
        for (let r = 0; r < rows; r++) {
          for (let c = 0; c < cols; c++) {
            ctx.strokeRect(c * fw, r * fh, fw, fh);
          }
        }
        // Highlight current frame
        const fc = currentFrame % cols;
        const fr = Math.floor(currentFrame / cols);
        ctx.fillStyle = 'rgba(0, 122, 204, 0.3)';
        ctx.fillRect(fc * fw, fr * fh, fw, fh);
        ctx.strokeStyle = '#007acc';
        ctx.lineWidth = 2;
        ctx.strokeRect(fc * fw, fr * fh, fw, fh);
        ctx.lineWidth = 1;
      }

      document.getElementById('btnPlay').addEventListener('click', () => {
        playing = !playing;
        document.getElementById('btnPlay').textContent = playing ? '\\u23F8 Pause' : '\\u25B6 Play';
        if (playing) {
          playTimer = setInterval(() => {
            currentFrame = (currentFrame + 1) % frames.length;
            rebuildUI();
          }, 1000 / fps);
        } else {
          clearInterval(playTimer);
        }
      });

      document.getElementById('btnPrev').addEventListener('click', () => {
        currentFrame = (currentFrame - 1 + frames.length) % frames.length;
        rebuildUI();
      });
      document.getElementById('btnNext').addEventListener('click', () => {
        currentFrame = (currentFrame + 1) % frames.length;
        rebuildUI();
      });
      document.getElementById('btnFirst').addEventListener('click', () => { currentFrame = 0; rebuildUI(); });
      document.getElementById('btnLast').addEventListener('click', () => { currentFrame = frames.length - 1; rebuildUI(); });

      document.getElementById('speed').addEventListener('input', (e) => {
        fps = parseInt(e.target.value);
        document.getElementById('speedLabel').textContent = fps + ' fps';
        if (playing) {
          clearInterval(playTimer);
          playTimer = setInterval(() => {
            currentFrame = (currentFrame + 1) % frames.length;
            rebuildUI();
          }, 1000 / fps);
        }
      });

      document.getElementById('cols').addEventListener('change', (e) => { cols = parseInt(e.target.value); initFrames(); });
      document.getElementById('rows').addEventListener('change', (e) => { rows = parseInt(e.target.value); initFrames(); });

      document.getElementById('frameDuration').addEventListener('change', (e) => {
        if (frames[currentFrame]) frames[currentFrame].duration = parseInt(e.target.value);
      });
      document.getElementById('originX').addEventListener('change', (e) => {
        if (frames[currentFrame]) frames[currentFrame].originX = parseInt(e.target.value);
      });
      document.getElementById('originY').addEventListener('change', (e) => {
        if (frames[currentFrame]) frames[currentFrame].originY = parseInt(e.target.value);
      });

      document.getElementById('btnAddFrame').addEventListener('click', () => {
        frames.push({ id: frames.length, duration: 100, originX: 0, originY: 0 });
        currentFrame = frames.length - 1;
        rebuildUI();
      });

      document.getElementById('btnAddTag').addEventListener('click', () => {
        const input = document.getElementById('newTag');
        const val = input.value.trim();
        if (val && !tags.includes(val)) {
          tags.push(val);
          input.value = '';
          renderTags();
        }
      });

      function renderTags() {
        const list = document.getElementById('tagList');
        list.innerHTML = '';
        tags.forEach((t, i) => {
          const el = document.createElement('span');
          el.className = 'tag';
          el.innerHTML = t + '<span class="remove">x</span>';
          el.querySelector('.remove').addEventListener('click', () => { tags.splice(i, 1); renderTags(); });
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

      initFrames();
      renderTags();
    `)}};var Nn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.tilesetEditor","Tileset")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"tileset.lua");break}}getHtml(){let e=R();return D(e,"Tileset",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 260px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .tileset-area { grid-row: 2; position: relative; overflow: auto; background: var(--bg); }
      .props-panel { grid-row: 2; }
      .status-bar { grid-column: 1 / -1; }
      .tile-grid-overlay { position: absolute; top: 0; left: 0; pointer-events: none; }
      .upload-zone {
        border: 2px dashed var(--border); border-radius: 8px; padding: 40px;
        text-align: center; color: var(--text-dim); cursor: pointer; margin: 20px;
      }
      .upload-zone:hover { border-color: var(--accent); color: var(--accent); }
      .tile-props-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 4px; }
      .prop-chip {
        display: flex; align-items: center; gap: 4px; padding: 2px 6px;
        background: var(--surface-2); border-radius: 3px; font-size: 11px;
      }
      .auto-rule { display: flex; align-items: center; gap: 4px; padding: 4px; border-bottom: 1px solid var(--border); font-size: 11px; }
      .auto-rule-grid {
        display: grid; grid-template-columns: repeat(3, 16px); gap: 1px;
      }
      .auto-rule-cell {
        width: 16px; height: 16px; background: var(--surface-2); border: 1px solid var(--border);
        cursor: pointer; border-radius: 1px;
      }
      .auto-rule-cell.on { background: var(--accent); }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnUpload">Upload Image</button>
          <div class="sep"></div>
          <label>Tile W:</label><input type="number" id="tileW" value="32" min="8" max="256" style="width:50px">
          <label>Tile H:</label><input type="number" id="tileH" value="32" min="8" max="256" style="width:50px">
          <div class="sep"></div>
          <button id="btnShowGrid" class="active">Grid</button>
          <button id="btnShowIds">IDs</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>

        <div class="tileset-area" id="tilesetArea">
          <div class="upload-zone" id="uploadZone">
            <p>Drop tileset image here or click Upload</p>
            <p style="font-size:11px;margin-top:8px;">Supported: PNG, JPG</p>
          </div>
          <canvas id="tilesetCanvas" style="display:none;"></canvas>
        </div>

        <div class="panel props-panel">
          <div class="section">
            <h3>Selected Tile</h3>
            <div class="field"><label>Tile ID</label><input type="text" id="tileId" readonly></div>
            <div class="field"><label>Name</label><input type="text" id="tileName" placeholder="(optional)"></div>
          </div>
          <div class="section">
            <h3>Properties</h3>
            <div class="tile-props-grid">
              <div class="prop-chip"><input type="checkbox" id="propSolid"><label for="propSolid">Solid</label></div>
              <div class="prop-chip"><input type="checkbox" id="propAnimated"><label for="propAnimated">Animated</label></div>
              <div class="prop-chip"><input type="checkbox" id="propSlope"><label for="propSlope">Slope</label></div>
              <div class="prop-chip"><input type="checkbox" id="propHazard"><label for="propHazard">Hazard</label></div>
            </div>
            <div class="field" style="margin-top:6px;">
              <label>Slope Angle</label>
              <input type="range" id="slopeAngle" min="0" max="90" value="45" style="width:100%">
              <span id="slopeLabel" style="font-size:11px;">45\xB0</span>
            </div>
          </div>
          <div class="section">
            <h3>Auto-Tile Rules</h3>
            <div id="autoRules"></div>
            <button id="btnAddRule" style="margin-top:4px;width:100%;">+ Add Rule</button>
          </div>
        </div>

        <div class="status-bar">
          <span id="statusTile">Tile: none</span>
          <span id="statusGrid">Grid: 0x0</span>
          <span id="statusTotal">Total: 0 tiles</span>
        </div>
      </div>
    `,`
      const canvas = document.getElementById('tilesetCanvas');
      const ctx = canvas.getContext('2d');
      let tileW = 32, tileH = 32;
      let gridCols = 0, gridRows = 0;
      let selectedTile = -1;
      let showGrid = true, showIds = false;
      let tileProps = {};
      let autoRules = [];
      let imageLoaded = false;

      function updateGrid() {
        if (!imageLoaded) return;
        gridCols = Math.floor(canvas.width / tileW);
        gridRows = Math.floor(canvas.height / tileH);
        document.getElementById('statusGrid').textContent = 'Grid: ' + gridCols + 'x' + gridRows;
        document.getElementById('statusTotal').textContent = 'Total: ' + (gridCols * gridRows) + ' tiles';
        render();
      }

      function render() {
        if (!imageLoaded) return;
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        // Checkerboard bg
        for (let y = 0; y < canvas.height; y += 16) {
          for (let x = 0; x < canvas.width; x += 16) {
            ctx.fillStyle = (Math.floor(x/16) + Math.floor(y/16)) % 2 === 0 ? '#2a2a2a' : '#242424';
            ctx.fillRect(x, y, 16, 16);
          }
        }
        if (showGrid) {
          ctx.strokeStyle = '#3c3c3c';
          ctx.lineWidth = 0.5;
          for (let c = 0; c <= gridCols; c++) { ctx.beginPath(); ctx.moveTo(c*tileW, 0); ctx.lineTo(c*tileW, gridRows*tileH); ctx.stroke(); }
          for (let r = 0; r <= gridRows; r++) { ctx.beginPath(); ctx.moveTo(0, r*tileH); ctx.lineTo(gridCols*tileW, r*tileH); ctx.stroke(); }
        }
        if (showIds) {
          ctx.fillStyle = '#fff';
          ctx.font = '10px monospace';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          for (let r = 0; r < gridRows; r++) {
            for (let c = 0; c < gridCols; c++) {
              ctx.fillText(String(r * gridCols + c), c * tileW + tileW/2, r * tileH + tileH/2);
            }
          }
        }
        // Highlight selected
        if (selectedTile >= 0) {
          const sc = selectedTile % gridCols;
          const sr = Math.floor(selectedTile / gridCols);
          ctx.strokeStyle = '#007acc';
          ctx.lineWidth = 2;
          ctx.strokeRect(sc * tileW, sr * tileH, tileW, tileH);
        }
      }

      canvas.addEventListener('click', (e) => {
        const rect = canvas.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        const c = Math.floor(x / tileW);
        const r = Math.floor(y / tileH);
        if (c < gridCols && r < gridRows) {
          selectedTile = r * gridCols + c;
          document.getElementById('tileId').value = selectedTile;
          document.getElementById('statusTile').textContent = 'Tile: ' + selectedTile;
          const props = tileProps[selectedTile] || {};
          document.getElementById('propSolid').checked = !!props.solid;
          document.getElementById('propAnimated').checked = !!props.animated;
          document.getElementById('propSlope').checked = !!props.slope;
          document.getElementById('propHazard').checked = !!props.hazard;
          document.getElementById('tileName').value = props.name || '';
          render();
        }
      });

      function saveCurrentTileProps() {
        if (selectedTile < 0) return;
        tileProps[selectedTile] = {
          solid: document.getElementById('propSolid').checked,
          animated: document.getElementById('propAnimated').checked,
          slope: document.getElementById('propSlope').checked,
          hazard: document.getElementById('propHazard').checked,
          name: document.getElementById('tileName').value,
          slopeAngle: parseInt(document.getElementById('slopeAngle').value),
        };
      }

      ['propSolid','propAnimated','propSlope','propHazard','tileName'].forEach(id => {
        document.getElementById(id).addEventListener('change', saveCurrentTileProps);
      });

      document.getElementById('slopeAngle').addEventListener('input', (e) => {
        document.getElementById('slopeLabel').textContent = e.target.value + '\\u00B0';
        saveCurrentTileProps();
      });

      document.getElementById('tileW').addEventListener('change', (e) => { tileW = parseInt(e.target.value); updateGrid(); });
      document.getElementById('tileH').addEventListener('change', (e) => { tileH = parseInt(e.target.value); updateGrid(); });

      document.getElementById('btnShowGrid').addEventListener('click', (e) => {
        showGrid = !showGrid;
        e.target.classList.toggle('active', showGrid);
        render();
      });
      document.getElementById('btnShowIds').addEventListener('click', (e) => {
        showIds = !showIds;
        e.target.classList.toggle('active', showIds);
        render();
      });

      // Simulate image load with a placeholder
      document.getElementById('btnUpload').addEventListener('click', () => {
        canvas.style.display = 'block';
        document.getElementById('uploadZone').style.display = 'none';
        canvas.width = 256; canvas.height = 256;
        imageLoaded = true;
        updateGrid();
      });

      document.getElementById('btnAddRule').addEventListener('click', () => {
        autoRules.push({ mask: new Array(9).fill(false), target: selectedTile >= 0 ? selectedTile : 0 });
        renderAutoRules();
      });

      function renderAutoRules() {
        const container = document.getElementById('autoRules');
        container.innerHTML = '';
        autoRules.forEach((rule, ri) => {
          const row = document.createElement('div');
          row.className = 'auto-rule';
          const grid = document.createElement('div');
          grid.className = 'auto-rule-grid';
          for (let i = 0; i < 9; i++) {
            const cell = document.createElement('div');
            cell.className = 'auto-rule-cell' + (rule.mask[i] ? ' on' : '');
            cell.addEventListener('click', () => { rule.mask[i] = !rule.mask[i]; renderAutoRules(); });
            grid.appendChild(cell);
          }
          row.appendChild(grid);
          const label = document.createElement('span');
          label.textContent = ' \\u2192 Tile ' + rule.target;
          row.appendChild(label);
          container.appendChild(row);
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
            if (p.slope) lua += ', slope = ' + p.slopeAngle;
            lua += ' },\\n';
          }
        }
        lua += '  }\\n}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });
    `)}};var zn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.audioMixerEditor","Audio Mixer")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"mixer.lua");break}}getHtml(){let e=R();return D(e,"Audio Mixer",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 220px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .mixer-area { grid-row: 2; display: flex; gap: 2px; padding: 10px; overflow-x: auto; align-items: stretch; }
      .effects-panel { grid-row: 2; }
      .status-bar { grid-column: 1 / -1; }
      .channel-strip {
        display: flex; flex-direction: column; align-items: center; gap: 4px;
        background: var(--surface); border: 1px solid var(--border); border-radius: 4px;
        padding: 8px; min-width: 80px; flex-shrink: 0;
      }
      .channel-strip.master { border-color: var(--accent); min-width: 100px; }
      .channel-label { font-size: 11px; font-weight: bold; text-transform: uppercase; color: var(--text-dim); }
      .fader-container { display: flex; flex-direction: column; align-items: center; flex: 1; min-height: 150px; justify-content: center; }
      .fader {
        -webkit-appearance: none; appearance: none; width: 6px; height: 140px;
        background: var(--surface-2); border-radius: 3px; outline: none;
        writing-mode: vertical-lr; direction: rtl;
      }
      .fader::-webkit-slider-thumb {
        -webkit-appearance: none; width: 20px; height: 10px;
        background: var(--text); border-radius: 2px; cursor: pointer;
      }
      .fader-value { font-size: 10px; color: var(--text-dim); margin-top: 4px; }
      .vu-meter { width: 12px; height: 100px; background: var(--bg); border: 1px solid var(--border); border-radius: 2px; position: relative; overflow: hidden; }
      .vu-fill { position: absolute; bottom: 0; width: 100%; background: linear-gradient(to top, var(--success), var(--warning), var(--danger)); transition: height 0.1s; }
      .pan-knob {
        width: 32px; height: 32px; border-radius: 50%; background: var(--surface-2);
        border: 2px solid var(--border); position: relative; cursor: pointer;
      }
      .pan-indicator {
        position: absolute; width: 2px; height: 10px; background: var(--accent);
        top: 3px; left: 50%; transform-origin: bottom center;
      }
      .btn-row { display: flex; gap: 2px; }
      .btn-mute, .btn-solo { width: 28px; height: 20px; font-size: 10px; font-weight: bold; padding: 0; }
      .btn-mute.active { background: var(--danger); border-color: var(--danger); }
      .btn-solo.active { background: var(--warning); border-color: var(--warning); color: #000; }
      .effect-item {
        display: flex; align-items: center; justify-content: space-between;
        padding: 4px 8px; background: var(--surface-2); border-radius: 3px; margin-bottom: 4px; font-size: 12px;
      }
      .bus-row { display: flex; align-items: center; gap: 4px; margin-bottom: 4px; font-size: 11px; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAddChannel">+ Channel</button>
          <button id="btnRemoveChannel">- Channel</button>
          <div class="sep"></div>
          <button id="btnResetAll">Reset All</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>

        <div class="mixer-area" id="mixerArea"></div>

        <div class="panel effects-panel">
          <div class="section">
            <h3>Effects Chain</h3>
            <div id="effectsList"></div>
            <select id="addEffect" style="width:100%;margin-top:4px;">
              <option value="">+ Add Effect...</option>
              <option value="reverb">Reverb</option>
              <option value="delay">Delay</option>
              <option value="lpf">Low-Pass Filter</option>
              <option value="hpf">High-Pass Filter</option>
              <option value="compressor">Compressor</option>
              <option value="distortion">Distortion</option>
            </select>
          </div>
          <div class="section">
            <h3>Bus Routing</h3>
            <div id="busRouting"></div>
          </div>
          <div class="section">
            <h3>Selected Effect</h3>
            <div id="effectParams">
              <p style="font-size:11px;color:var(--text-dim);">Select an effect to edit</p>
            </div>
          </div>
        </div>

        <div class="status-bar">
          <span id="statusChannels">Channels: 5</span>
          <span id="statusSelected">Selected: Master</span>
          <span id="statusEffects">Effects: 0</span>
        </div>
      </div>
    `,`
      const CHANNEL_NAMES = ['Master', 'Music', 'SFX', 'Voice', 'Ambient'];
      let channels = CHANNEL_NAMES.map((name, i) => ({
        name, volume: i === 0 ? 100 : 80, pan: 50, mute: false, solo: false, vu: 0, bus: 'master'
      }));
      let effects = [];
      let selectedChannel = 0;
      let selectedEffect = -1;

      function buildMixer() {
        const area = document.getElementById('mixerArea');
        area.innerHTML = '';
        channels.forEach((ch, i) => {
          const strip = document.createElement('div');
          strip.className = 'channel-strip' + (i === 0 ? ' master' : '');
          const vuLevel = 30 + Math.random() * 50;
          strip.innerHTML =
            '<span class="channel-label">' + ch.name + '</span>' +
            '<div class="vu-meter"><div class="vu-fill" style="height:' + vuLevel + '%"></div></div>' +
            '<div class="fader-container">' +
              '<input type="range" class="fader" min="0" max="100" value="' + ch.volume + '" data-ch="' + i + '">' +
              '<span class="fader-value">' + ch.volume + '%</span>' +
            '</div>' +
            '<div class="pan-knob" title="Pan: ' + (ch.pan - 50) + '">' +
              '<div class="pan-indicator" style="transform:rotate(' + ((ch.pan - 50) * 1.35) + 'deg)"></div>' +
            '</div>' +
            '<div class="btn-row">' +
              '<button class="btn-mute' + (ch.mute ? ' active' : '') + '" data-ch="' + i + '">M</button>' +
              '<button class="btn-solo' + (ch.solo ? ' active' : '') + '" data-ch="' + i + '">S</button>' +
            '</div>';
          strip.addEventListener('click', () => {
            selectedChannel = i;
            document.getElementById('statusSelected').textContent = 'Selected: ' + ch.name;
            buildBusRouting();
          });
          area.appendChild(strip);
        });

        // Attach fader events
        area.querySelectorAll('.fader').forEach(f => {
          f.addEventListener('input', (e) => {
            const idx = parseInt(e.target.dataset.ch);
            channels[idx].volume = parseInt(e.target.value);
            e.target.parentElement.querySelector('.fader-value').textContent = e.target.value + '%';
          });
        });
        area.querySelectorAll('.btn-mute').forEach(b => {
          b.addEventListener('click', (e) => {
            e.stopPropagation();
            const idx = parseInt(b.dataset.ch);
            channels[idx].mute = !channels[idx].mute;
            b.classList.toggle('active', channels[idx].mute);
          });
        });
        area.querySelectorAll('.btn-solo').forEach(b => {
          b.addEventListener('click', (e) => {
            e.stopPropagation();
            const idx = parseInt(b.dataset.ch);
            channels[idx].solo = !channels[idx].solo;
            b.classList.toggle('active', channels[idx].solo);
          });
        });
        document.getElementById('statusChannels').textContent = 'Channels: ' + channels.length;
      }

      function buildEffects() {
        const list = document.getElementById('effectsList');
        list.innerHTML = '';
        effects.forEach((fx, i) => {
          const el = document.createElement('div');
          el.className = 'effect-item';
          el.innerHTML = '<span>' + fx.type + '</span><button class="danger" data-fx="' + i + '" style="padding:1px 6px;">x</button>';
          el.addEventListener('click', () => { selectedEffect = i; showEffectParams(fx); });
          el.querySelector('button').addEventListener('click', (e) => {
            e.stopPropagation();
            effects.splice(i, 1);
            buildEffects();
          });
          list.appendChild(el);
        });
        document.getElementById('statusEffects').textContent = 'Effects: ' + effects.length;
      }

      function showEffectParams(fx) {
        const container = document.getElementById('effectParams');
        const params = { reverb: ['mix','decay','damping'], delay: ['time','feedback','mix'], lpf: ['cutoff','resonance'], hpf: ['cutoff','resonance'], compressor: ['threshold','ratio','attack','release'], distortion: ['drive','tone'] };
        const p = params[fx.type] || [];
        container.innerHTML = '<h3 style="font-size:11px;margin-bottom:6px;">' + fx.type + '</h3>';
        p.forEach(param => {
          const val = fx.params[param] || 50;
          container.innerHTML += '<div class="field"><label>' + param + '</label><input type="range" min="0" max="100" value="' + val + '"><span style="font-size:10px;">' + val + '</span></div>';
        });
      }

      function buildBusRouting() {
        const container = document.getElementById('busRouting');
        container.innerHTML = '';
        channels.forEach((ch, i) => {
          if (i === 0) return;
          const row = document.createElement('div');
          row.className = 'bus-row';
          row.innerHTML = '<span style="width:60px;">' + ch.name + '</span><select data-ch="' + i + '"><option value="master">Master</option><option value="bus1">Bus 1</option><option value="bus2">Bus 2</option></select>';
          row.querySelector('select').value = ch.bus;
          row.querySelector('select').addEventListener('change', (e) => { channels[i].bus = e.target.value; });
          container.appendChild(row);
        });
      }

      document.getElementById('addEffect').addEventListener('change', (e) => {
        if (e.target.value) {
          effects.push({ type: e.target.value, channel: selectedChannel, params: {} });
          e.target.value = '';
          buildEffects();
        }
      });

      document.getElementById('btnAddChannel').addEventListener('click', () => {
        const n = channels.length;
        channels.push({ name: 'Ch ' + n, volume: 80, pan: 50, mute: false, solo: false, vu: 0, bus: 'master' });
        buildMixer();
      });

      document.getElementById('btnRemoveChannel').addEventListener('click', () => {
        if (channels.length > 1) { channels.pop(); buildMixer(); }
      });

      document.getElementById('btnResetAll').addEventListener('click', () => {
        channels.forEach((ch, i) => { ch.volume = i === 0 ? 100 : 80; ch.pan = 50; ch.mute = false; ch.solo = false; });
        effects = [];
        buildMixer(); buildEffects();
      });

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  channels = {\\n';
        channels.forEach(ch => {
          lua += '    { name = "' + ch.name + '", volume = ' + (ch.volume/100).toFixed(2) + ', pan = ' + ((ch.pan-50)/50).toFixed(2) + ', mute = ' + ch.mute + ', bus = "' + ch.bus + '" },\\n';
        });
        lua += '  },\\n  effects = {\\n';
        effects.forEach(fx => {
          lua += '    { type = "' + fx.type + '", channel = ' + (fx.channel+1) + ' },\\n';
        });
        lua += '  }\\n}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      // Animate VU meters
      setInterval(() => {
        document.querySelectorAll('.vu-fill').forEach((el, i) => {
          const ch = channels[i];
          if (ch && !ch.mute) {
            const level = 20 + Math.random() * 60 * (ch.volume / 100);
            el.style.height = level + '%';
          } else if (ch && ch.mute) {
            el.style.height = '0%';
          }
        });
      }, 100);

      buildMixer();
      buildEffects();
      buildBusRouting();
    `)}};var _n=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.colorPaletteEditor","Color Palette")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"palette.lua");break}}getHtml(){let e=R();return D(e,"Color Palette",`
      .editor-layout {
        display: grid; grid-template-columns: 280px 1fr 240px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .picker-panel { grid-row: 2; }
      .palette-area { grid-row: 2; padding: 12px; overflow-y: auto; }
      .harmony-panel { grid-row: 2; }
      .status-bar { grid-column: 1 / -1; }
      .color-preview {
        width: 100%; height: 80px; border-radius: 4px; border: 1px solid var(--border); margin-bottom: 8px;
      }
      .slider-group { margin-bottom: 8px; }
      .slider-group label { display: flex; justify-content: space-between; }
      .slider-group input[type="range"] { width: 100%; }
      .hex-input { width: 100%; font-family: monospace; font-size: 14px; text-align: center; }
      .palette-grid {
        display: grid; grid-template-columns: repeat(8, 1fr); gap: 4px;
      }
      .swatch {
        aspect-ratio: 1; border-radius: 4px; border: 2px solid transparent;
        cursor: pointer; position: relative; min-height: 36px;
      }
      .swatch:hover { border-color: var(--text); }
      .swatch.selected { border-color: var(--accent); box-shadow: 0 0 0 2px var(--accent); }
      .swatch-label {
        position: absolute; bottom: 1px; left: 0; right: 0; text-align: center;
        font-size: 8px; color: #fff; text-shadow: 0 0 2px #000;
      }
      .harmony-wheel {
        width: 180px; height: 180px; border-radius: 50%; margin: 10px auto;
        background: conic-gradient(red, yellow, lime, cyan, blue, magenta, red);
        position: relative;
      }
      .harmony-dot {
        width: 12px; height: 12px; border-radius: 50%; border: 2px solid #fff;
        position: absolute; transform: translate(-50%,-50%); box-shadow: 0 0 4px rgba(0,0,0,0.5);
      }
      .contrast-badge {
        display: inline-block; padding: 2px 8px; border-radius: 3px; font-size: 11px; font-weight: bold;
      }
      .contrast-pass { background: var(--success); color: #fff; }
      .contrast-fail { background: var(--danger); color: #fff; }
      .harmony-swatches { display: flex; gap: 4px; margin-top: 8px; justify-content: center; }
      .harmony-swatch { width: 28px; height: 28px; border-radius: 4px; border: 1px solid var(--border); cursor: pointer; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAddColor">+ Add Color</button>
          <button id="btnRemoveColor" class="danger">Remove</button>
          <div class="sep"></div>
          <label>Mode:</label>
          <select id="colorMode">
            <option value="hsl">HSL</option>
            <option value="rgb">RGB</option>
            <option value="hsv">HSV</option>
          </select>
          <div class="sep"></div>
          <button id="btnSortHue">Sort by Hue</button>
          <button id="btnSortLight">Sort by Lightness</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>

        <div class="panel picker-panel">
          <div class="section">
            <h3>Color Picker</h3>
            <div class="color-preview" id="colorPreview"></div>
            <div class="field"><input type="text" class="hex-input" id="hexInput" value="#007ACC"></div>
          </div>
          <div class="section" id="slidersHSL">
            <div class="slider-group">
              <label>H <span id="hVal">210</span></label>
              <input type="range" id="hSlider" min="0" max="360" value="210">
            </div>
            <div class="slider-group">
              <label>S <span id="sVal">100</span></label>
              <input type="range" id="sSlider" min="0" max="100" value="100">
            </div>
            <div class="slider-group">
              <label>L <span id="lVal">40</span></label>
              <input type="range" id="lSlider" min="0" max="100" value="40">
            </div>
            <div class="slider-group">
              <label>A <span id="aVal">255</span></label>
              <input type="range" id="aSlider" min="0" max="255" value="255">
            </div>
          </div>
          <div class="section">
            <h3>Accessibility</h3>
            <div id="contrastInfo" style="font-size:11px;">
              <p>On white: <span id="contrastWhite" class="contrast-badge">--</span></p>
              <p style="margin-top:4px;">On black: <span id="contrastBlack" class="contrast-badge">--</span></p>
            </div>
          </div>
        </div>

        <div class="palette-area">
          <h3 style="margin-bottom:8px;">Palette (<span id="paletteCount">0</span>/64)</h3>
          <div class="palette-grid" id="paletteGrid"></div>
        </div>

        <div class="panel harmony-panel">
          <div class="section">
            <h3>Harmony</h3>
            <select id="harmonyType" style="width:100%;">
              <option value="complementary">Complementary</option>
              <option value="triadic">Triadic</option>
              <option value="analogous">Analogous</option>
              <option value="split">Split-Complementary</option>
              <option value="tetradic">Tetradic</option>
            </select>
            <div class="harmony-wheel" id="harmonyWheel"></div>
            <div class="harmony-swatches" id="harmonySwatches"></div>
            <button id="btnApplyHarmony" style="width:100%;margin-top:6px;">Add Harmony Colors</button>
          </div>
        </div>

        <div class="status-bar">
          <span id="statusColor">Color: #007ACC</span>
          <span id="statusIndex">Index: 0</span>
          <span id="statusCount">Total: 0</span>
        </div>
      </div>
    `,`
      let palette = [];
      let selectedIdx = -1;
      let h = 210, s = 100, l = 40, a = 255;

      function hslToHex(h, s, l) {
        s /= 100; l /= 100;
        const k = n => (n + h / 30) % 12;
        const a2 = s * Math.min(l, 1 - l);
        const f = n => l - a2 * Math.max(-1, Math.min(k(n) - 3, 9 - k(n), 1));
        const toHex = v => Math.round(v * 255).toString(16).padStart(2, '0');
        return '#' + toHex(f(0)) + toHex(f(8)) + toHex(f(4));
      }

      function hexToRgb(hex) {
        const m = hex.match(/^#?([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})$/i);
        return m ? { r: parseInt(m[1],16), g: parseInt(m[2],16), b: parseInt(m[3],16) } : { r:0, g:0, b:0 };
      }

      function luminance(r, g, b) {
        const [rs, gs, bs] = [r, g, b].map(c => { c /= 255; return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); });
        return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs;
      }

      function contrastRatio(l1, l2) {
        const lighter = Math.max(l1, l2), darker = Math.min(l1, l2);
        return (lighter + 0.05) / (darker + 0.05);
      }

      function updateColor() {
        const hex = hslToHex(h, s, l);
        document.getElementById('colorPreview').style.background = hex;
        document.getElementById('hexInput').value = hex;
        document.getElementById('hVal').textContent = h;
        document.getElementById('sVal').textContent = s;
        document.getElementById('lVal').textContent = l;
        document.getElementById('aVal').textContent = a;
        document.getElementById('statusColor').textContent = 'Color: ' + hex;

        // Contrast
        const rgb = hexToRgb(hex);
        const lum = luminance(rgb.r, rgb.g, rgb.b);
        const crWhite = contrastRatio(1, lum).toFixed(1);
        const crBlack = contrastRatio(lum, 0).toFixed(1);
        const eWhite = document.getElementById('contrastWhite');
        const eBlack = document.getElementById('contrastBlack');
        eWhite.textContent = crWhite + ':1';
        eWhite.className = 'contrast-badge ' + (crWhite >= 4.5 ? 'contrast-pass' : 'contrast-fail');
        eBlack.textContent = crBlack + ':1';
        eBlack.className = 'contrast-badge ' + (crBlack >= 4.5 ? 'contrast-pass' : 'contrast-fail');

        updateHarmony();
        if (selectedIdx >= 0 && selectedIdx < palette.length) {
          palette[selectedIdx] = { hex, h, s, l, a };
          renderPalette();
        }
      }

      function renderPalette() {
        const grid = document.getElementById('paletteGrid');
        grid.innerHTML = '';
        palette.forEach((c, i) => {
          const el = document.createElement('div');
          el.className = 'swatch' + (i === selectedIdx ? ' selected' : '');
          el.style.background = c.hex;
          el.innerHTML = '<span class="swatch-label">' + (i+1) + '</span>';
          el.addEventListener('click', () => {
            selectedIdx = i; h = c.h; s = c.s; l = c.l; a = c.a;
            document.getElementById('hSlider').value = h;
            document.getElementById('sSlider').value = s;
            document.getElementById('lSlider').value = l;
            document.getElementById('aSlider').value = a;
            updateColor();
            renderPalette();
            document.getElementById('statusIndex').textContent = 'Index: ' + i;
          });
          grid.appendChild(el);
        });
        document.getElementById('paletteCount').textContent = palette.length;
        document.getElementById('statusCount').textContent = 'Total: ' + palette.length;
      }

      function getHarmonyHues(type) {
        switch (type) {
          case 'complementary': return [h, (h + 180) % 360];
          case 'triadic': return [h, (h + 120) % 360, (h + 240) % 360];
          case 'analogous': return [(h - 30 + 360) % 360, h, (h + 30) % 360];
          case 'split': return [h, (h + 150) % 360, (h + 210) % 360];
          case 'tetradic': return [h, (h + 90) % 360, (h + 180) % 360, (h + 270) % 360];
          default: return [h];
        }
      }

      function updateHarmony() {
        const type = document.getElementById('harmonyType').value;
        const hues = getHarmonyHues(type);
        const wheel = document.getElementById('harmonyWheel');
        const swatches = document.getElementById('harmonySwatches');
        wheel.innerHTML = '';
        swatches.innerHTML = '';
        hues.forEach((hue) => {
          const angle = (hue - 90) * Math.PI / 180;
          const r = 80;
          const x = 90 + r * Math.cos(angle);
          const y = 90 + r * Math.sin(angle);
          const dot = document.createElement('div');
          dot.className = 'harmony-dot';
          dot.style.left = x + 'px';
          dot.style.top = y + 'px';
          dot.style.background = hslToHex(hue, s, l);
          wheel.appendChild(dot);
          const sw = document.createElement('div');
          sw.className = 'harmony-swatch';
          sw.style.background = hslToHex(hue, s, l);
          sw.addEventListener('click', () => {
            if (palette.length < 64) {
              palette.push({ hex: hslToHex(hue, s, l), h: hue, s, l, a });
              renderPalette();
            }
          });
          swatches.appendChild(sw);
        });
      }

      ['hSlider','sSlider','lSlider','aSlider'].forEach(id => {
        document.getElementById(id).addEventListener('input', (e) => {
          if (id === 'hSlider') h = parseInt(e.target.value);
          if (id === 'sSlider') s = parseInt(e.target.value);
          if (id === 'lSlider') l = parseInt(e.target.value);
          if (id === 'aSlider') a = parseInt(e.target.value);
          updateColor();
        });
      });

      document.getElementById('hexInput').addEventListener('change', (e) => {
        const rgb = hexToRgb(e.target.value);
        // Simplified re-derive HSL
        const r2 = rgb.r/255, g2 = rgb.g/255, b2 = rgb.b/255;
        const max = Math.max(r2,g2,b2), min = Math.min(r2,g2,b2);
        l = Math.round((max+min)/2*100);
        if (max !== min) {
          const d = max - min;
          s = Math.round((l > 50 ? d/(2-max-min) : d/(max+min))*100);
          if (max === r2) h = Math.round(((g2-b2)/d + (g2<b2?6:0))*60);
          else if (max === g2) h = Math.round(((b2-r2)/d+2)*60);
          else h = Math.round(((r2-g2)/d+4)*60);
        } else { s = 0; h = 0; }
        document.getElementById('hSlider').value = h;
        document.getElementById('sSlider').value = s;
        document.getElementById('lSlider').value = l;
        updateColor();
      });

      document.getElementById('btnAddColor').addEventListener('click', () => {
        if (palette.length < 64) {
          const hex = hslToHex(h, s, l);
          palette.push({ hex, h, s, l, a });
          selectedIdx = palette.length - 1;
          renderPalette();
        }
      });

      document.getElementById('btnRemoveColor').addEventListener('click', () => {
        if (selectedIdx >= 0) {
          palette.splice(selectedIdx, 1);
          selectedIdx = Math.min(selectedIdx, palette.length - 1);
          renderPalette();
        }
      });

      document.getElementById('btnSortHue').addEventListener('click', () => {
        palette.sort((a, b) => a.h - b.h);
        renderPalette();
      });
      document.getElementById('btnSortLight').addEventListener('click', () => {
        palette.sort((a, b) => a.l - b.l);
        renderPalette();
      });

      document.getElementById('harmonyType').addEventListener('change', updateHarmony);

      document.getElementById('btnApplyHarmony').addEventListener('click', () => {
        const type = document.getElementById('harmonyType').value;
        const hues = getHarmonyHues(type);
        hues.forEach(hue => {
          if (palette.length < 64) {
            palette.push({ hex: hslToHex(hue, s, l), h: hue, s, l, a });
          }
        });
        renderPalette();
      });

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        palette.forEach((c, i) => {
          const rgb = hexToRgb(c.hex);
          lua += '  { r = ' + rgb.r + ', g = ' + rgb.g + ', b = ' + rgb.b + ', a = ' + c.a + ' }, -- ' + c.hex + '\\n';
        });
        lua += '}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      updateColor();
      renderPalette();
    `)}};var $n=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.inputMapperEditor","Input Mapper")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"input_map.lua");break}}getHtml(){let e=R();return D(e,"Input Mapper",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 260px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .mapping-area { grid-row: 2; overflow-y: auto; padding: 10px; }
      .config-panel { grid-row: 2; }
      .status-bar { grid-column: 1 / -1; }
      .action-table { width: 100%; border-collapse: collapse; font-size: 12px; }
      .action-table th {
        text-align: left; padding: 6px 8px; background: var(--surface);
        border-bottom: 2px solid var(--border); font-size: 11px; text-transform: uppercase;
        color: var(--text-dim); position: sticky; top: 0;
      }
      .action-table td {
        padding: 4px 8px; border-bottom: 1px solid var(--border); vertical-align: middle;
      }
      .action-table tr:hover { background: var(--surface-2); }
      .binding-cell { display: flex; flex-wrap: wrap; gap: 3px; }
      .key-badge {
        background: var(--surface-2); border: 1px solid var(--border); padding: 2px 8px;
        border-radius: 3px; font-family: monospace; font-size: 11px; cursor: pointer;
        display: inline-flex; align-items: center; gap: 4px;
      }
      .key-badge:hover { border-color: var(--accent); }
      .key-badge .remove { font-size: 9px; opacity: 0.5; cursor: pointer; }
      .key-badge .remove:hover { opacity: 1; color: var(--danger); }
      .key-badge.conflict { border-color: var(--danger); background: rgba(244,67,54,0.15); }
      .add-binding {
        background: transparent; border: 1px dashed var(--border); padding: 2px 8px;
        border-radius: 3px; font-size: 11px; cursor: pointer; color: var(--text-dim);
      }
      .add-binding:hover { border-color: var(--accent); color: var(--accent); }
      .listen-overlay {
        position: fixed; inset: 0; background: rgba(0,0,0,0.7); display: flex;
        align-items: center; justify-content: center; z-index: 100;
      }
      .listen-box {
        background: var(--surface); padding: 24px 40px; border-radius: 8px;
        border: 2px solid var(--accent); text-align: center;
      }
      .deadzone-slider { width: 100%; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAddAction">+ Add Action</button>
          <button id="btnRemoveAction" class="danger">Remove Action</button>
          <div class="sep"></div>
          <button id="btnCheckConflicts">Check Conflicts</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>

        <div class="mapping-area">
          <table class="action-table">
            <thead>
              <tr>
                <th style="width:140px;">Action</th>
                <th style="width:180px;">Description</th>
                <th>Keyboard</th>
                <th>Gamepad</th>
              </tr>
            </thead>
            <tbody id="actionBody"></tbody>
          </table>
        </div>

        <div class="panel config-panel">
          <div class="section">
            <h3>Selected Action</h3>
            <div class="field"><label>Name</label><input type="text" id="actionName" style="width:100%"></div>
            <div class="field"><label>Description</label><input type="text" id="actionDesc" style="width:100%"></div>
          </div>
          <div class="section">
            <h3>Analog Settings</h3>
            <div class="field">
              <label>Dead Zone: <span id="dzVal">0.15</span></label>
              <input type="range" class="deadzone-slider" id="deadzone" min="0" max="50" value="15">
            </div>
            <div class="field">
              <label>Sensitivity: <span id="sensVal">1.0</span></label>
              <input type="range" class="deadzone-slider" id="sensitivity" min="1" max="30" value="10">
            </div>
          </div>
          <div class="section">
            <h3>Presets</h3>
            <button id="btnPresetPlatformer" style="width:100%;margin-bottom:4px;">Platformer</button>
            <button id="btnPresetRPG" style="width:100%;margin-bottom:4px;">RPG</button>
            <button id="btnPresetShooter" style="width:100%;">Top-Down Shooter</button>
          </div>
        </div>

        <div class="status-bar">
          <span id="statusActions">Actions: 0</span>
          <span id="statusConflicts">Conflicts: 0</span>
        </div>
      </div>
      <div class="listen-overlay" id="listenOverlay" style="display:none;">
        <div class="listen-box">
          <p style="font-size:16px;margin-bottom:8px;">Press a key...</p>
          <p style="font-size:11px;color:var(--text-dim);">Press Escape to cancel</p>
        </div>
      </div>
    `,`
      let actions = [
        { name: 'move_left', desc: 'Move left', keys: ['a','left'], gamepad: ['dpad_left','lstick_left'], deadzone: 0.15, sensitivity: 1.0 },
        { name: 'move_right', desc: 'Move right', keys: ['d','right'], gamepad: ['dpad_right','lstick_right'], deadzone: 0.15, sensitivity: 1.0 },
        { name: 'jump', desc: 'Jump', keys: ['space','w'], gamepad: ['a'], deadzone: 0.15, sensitivity: 1.0 },
        { name: 'attack', desc: 'Primary attack', keys: ['j','enter'], gamepad: ['x'], deadzone: 0.15, sensitivity: 1.0 },
        { name: 'interact', desc: 'Interact / Talk', keys: ['e'], gamepad: ['b'], deadzone: 0.15, sensitivity: 1.0 },
      ];
      let selectedAction = 0;
      let listenTarget = null; // {action, type:'keys'|'gamepad'}

      function render() {
        const body = document.getElementById('actionBody');
        body.innerHTML = '';
        const conflicts = findConflicts();
        actions.forEach((act, i) => {
          const tr = document.createElement('tr');
          tr.style.background = i === selectedAction ? 'var(--selection)' : '';
          tr.addEventListener('click', () => { selectedAction = i; render(); updateProps(); });

          const tdName = document.createElement('td');
          tdName.textContent = act.name;
          tdName.style.fontFamily = 'monospace';

          const tdDesc = document.createElement('td');
          tdDesc.textContent = act.desc;
          tdDesc.style.color = 'var(--text-dim)';

          const tdKeys = document.createElement('td');
          const keysDiv = document.createElement('div');
          keysDiv.className = 'binding-cell';
          act.keys.forEach((k, ki) => {
            const badge = document.createElement('span');
            const isConflict = conflicts.some(c => c.key === k && c.type === 'keys' && (c.a === i || c.b === i));
            badge.className = 'key-badge' + (isConflict ? ' conflict' : '');
            badge.innerHTML = k + ' <span class="remove">x</span>';
            badge.querySelector('.remove').addEventListener('click', (e) => {
              e.stopPropagation(); act.keys.splice(ki, 1); render();
            });
            keysDiv.appendChild(badge);
          });
          const addKeyBtn = document.createElement('button');
          addKeyBtn.className = 'add-binding';
          addKeyBtn.textContent = '+';
          addKeyBtn.addEventListener('click', (e) => { e.stopPropagation(); startListen(i, 'keys'); });
          keysDiv.appendChild(addKeyBtn);
          tdKeys.appendChild(keysDiv);

          const tdPad = document.createElement('td');
          const padDiv = document.createElement('div');
          padDiv.className = 'binding-cell';
          act.gamepad.forEach((g, gi) => {
            const badge = document.createElement('span');
            const isConflict = conflicts.some(c => c.key === g && c.type === 'gamepad' && (c.a === i || c.b === i));
            badge.className = 'key-badge' + (isConflict ? ' conflict' : '');
            badge.innerHTML = g + ' <span class="remove">x</span>';
            badge.querySelector('.remove').addEventListener('click', (e) => {
              e.stopPropagation(); act.gamepad.splice(gi, 1); render();
            });
            padDiv.appendChild(badge);
          });
          const addPadBtn = document.createElement('button');
          addPadBtn.className = 'add-binding';
          addPadBtn.textContent = '+';
          addPadBtn.addEventListener('click', (e) => { e.stopPropagation(); startListen(i, 'gamepad'); });
          padDiv.appendChild(addPadBtn);
          tdPad.appendChild(padDiv);

          tr.appendChild(tdName); tr.appendChild(tdDesc); tr.appendChild(tdKeys); tr.appendChild(tdPad);
          body.appendChild(tr);
        });
        document.getElementById('statusActions').textContent = 'Actions: ' + actions.length;
        document.getElementById('statusConflicts').textContent = 'Conflicts: ' + conflicts.length;
      }

      function updateProps() {
        const act = actions[selectedAction];
        if (!act) return;
        document.getElementById('actionName').value = act.name;
        document.getElementById('actionDesc').value = act.desc;
        document.getElementById('deadzone').value = Math.round(act.deadzone * 100);
        document.getElementById('dzVal').textContent = act.deadzone.toFixed(2);
        document.getElementById('sensitivity').value = Math.round(act.sensitivity * 10);
        document.getElementById('sensVal').textContent = act.sensitivity.toFixed(1);
      }

      function findConflicts() {
        const conflicts = [];
        for (let i = 0; i < actions.length; i++) {
          for (let j = i + 1; j < actions.length; j++) {
            for (const k of actions[i].keys) {
              if (actions[j].keys.includes(k)) conflicts.push({ a: i, b: j, key: k, type: 'keys' });
            }
            for (const g of actions[i].gamepad) {
              if (actions[j].gamepad.includes(g)) conflicts.push({ a: i, b: j, key: g, type: 'gamepad' });
            }
          }
        }
        return conflicts;
      }

      function startListen(actionIdx, type) {
        listenTarget = { action: actionIdx, type };
        document.getElementById('listenOverlay').style.display = 'flex';
      }

      document.addEventListener('keydown', (e) => {
        if (!listenTarget) return;
        e.preventDefault();
        if (e.key === 'Escape') {
          listenTarget = null;
          document.getElementById('listenOverlay').style.display = 'none';
          return;
        }
        const keyName = e.key.toLowerCase();
        const act = actions[listenTarget.action];
        if (listenTarget.type === 'keys' && !act.keys.includes(keyName)) {
          act.keys.push(keyName);
        }
        listenTarget = null;
        document.getElementById('listenOverlay').style.display = 'none';
        render();
      });

      document.getElementById('actionName').addEventListener('change', (e) => {
        if (actions[selectedAction]) { actions[selectedAction].name = e.target.value; render(); }
      });
      document.getElementById('actionDesc').addEventListener('change', (e) => {
        if (actions[selectedAction]) { actions[selectedAction].desc = e.target.value; }
      });
      document.getElementById('deadzone').addEventListener('input', (e) => {
        const v = parseInt(e.target.value) / 100;
        document.getElementById('dzVal').textContent = v.toFixed(2);
        if (actions[selectedAction]) actions[selectedAction].deadzone = v;
      });
      document.getElementById('sensitivity').addEventListener('input', (e) => {
        const v = parseInt(e.target.value) / 10;
        document.getElementById('sensVal').textContent = v.toFixed(1);
        if (actions[selectedAction]) actions[selectedAction].sensitivity = v;
      });

      document.getElementById('btnAddAction').addEventListener('click', () => {
        actions.push({ name: 'new_action', desc: '', keys: [], gamepad: [], deadzone: 0.15, sensitivity: 1.0 });
        selectedAction = actions.length - 1;
        render(); updateProps();
      });
      document.getElementById('btnRemoveAction').addEventListener('click', () => {
        if (actions.length > 0) {
          actions.splice(selectedAction, 1);
          selectedAction = Math.min(selectedAction, actions.length - 1);
          render(); updateProps();
        }
      });

      document.getElementById('btnCheckConflicts').addEventListener('click', render);

      function loadPreset(preset) {
        const presets = {
          Platformer: [
            { name:'move_left', desc:'Move left', keys:['a','left'], gamepad:['dpad_left','lstick_left'], deadzone:0.15, sensitivity:1 },
            { name:'move_right', desc:'Move right', keys:['d','right'], gamepad:['dpad_right','lstick_right'], deadzone:0.15, sensitivity:1 },
            { name:'jump', desc:'Jump', keys:['space','w','up'], gamepad:['a'], deadzone:0.15, sensitivity:1 },
            { name:'attack', desc:'Attack', keys:['j'], gamepad:['x'], deadzone:0.15, sensitivity:1 },
            { name:'dash', desc:'Dash', keys:['shift'], gamepad:['lb'], deadzone:0.15, sensitivity:1 },
          ],
          RPG: [
            { name:'move_up', desc:'Move up', keys:['w','up'], gamepad:['dpad_up','lstick_up'], deadzone:0.2, sensitivity:1 },
            { name:'move_down', desc:'Move down', keys:['s','down'], gamepad:['dpad_down','lstick_down'], deadzone:0.2, sensitivity:1 },
            { name:'move_left', desc:'Move left', keys:['a','left'], gamepad:['dpad_left','lstick_left'], deadzone:0.2, sensitivity:1 },
            { name:'move_right', desc:'Move right', keys:['d','right'], gamepad:['dpad_right','lstick_right'], deadzone:0.2, sensitivity:1 },
            { name:'interact', desc:'Talk / Interact', keys:['e','enter'], gamepad:['a'], deadzone:0.15, sensitivity:1 },
            { name:'menu', desc:'Open menu', keys:['escape','tab'], gamepad:['start'], deadzone:0.15, sensitivity:1 },
          ],
          Shooter: [
            { name:'move_up', desc:'Move up', keys:['w'], gamepad:['lstick_up'], deadzone:0.1, sensitivity:1.5 },
            { name:'move_down', desc:'Move down', keys:['s'], gamepad:['lstick_down'], deadzone:0.1, sensitivity:1.5 },
            { name:'move_left', desc:'Move left', keys:['a'], gamepad:['lstick_left'], deadzone:0.1, sensitivity:1.5 },
            { name:'move_right', desc:'Move right', keys:['d'], gamepad:['lstick_right'], deadzone:0.1, sensitivity:1.5 },
            { name:'shoot', desc:'Fire weapon', keys:['space'], gamepad:['rt'], deadzone:0.05, sensitivity:1 },
            { name:'reload', desc:'Reload', keys:['r'], gamepad:['x'], deadzone:0.15, sensitivity:1 },
          ],
        };
        actions = presets[preset] || actions;
        selectedAction = 0;
        render(); updateProps();
      }

      document.getElementById('btnPresetPlatformer').addEventListener('click', () => loadPreset('Platformer'));
      document.getElementById('btnPresetRPG').addEventListener('click', () => loadPreset('RPG'));
      document.getElementById('btnPresetShooter').addEventListener('click', () => loadPreset('Shooter'));

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        actions.forEach(a => {
          lua += '  ' + a.name + ' = {\\n';
          lua += '    description = "' + a.desc + '",\\n';
          lua += '    keys = {' + a.keys.map(k => '"' + k + '"').join(', ') + '},\\n';
          lua += '    gamepad = {' + a.gamepad.map(g => '"' + g + '"').join(', ') + '},\\n';
          lua += '    deadzone = ' + a.deadzone + ', sensitivity = ' + a.sensitivity + ',\\n';
          lua += '  },\\n';
        });
        lua += '}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      render();
      updateProps();
    `)}};var On=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.timelineEditor","Timeline")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"timeline.lua");break}}getHtml(){let e=R();return D(e,"Timeline",`
      .editor-layout {
        display: grid; grid-template-columns: 160px 1fr 220px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .track-list { grid-row: 2; border-right: 1px solid var(--border); }
      .timeline-area { grid-row: 2; overflow: auto; position: relative; }
      .props-panel { grid-row: 2; }
      .status-bar { grid-column: 1 / -1; }
      .track-header {
        display: flex; align-items: center; gap: 4px; padding: 4px 8px;
        border-bottom: 1px solid var(--border); height: 36px; cursor: pointer; font-size: 12px;
      }
      .track-header:hover { background: var(--surface-2); }
      .track-header.selected { background: var(--selection); }
      .track-icon { font-size: 14px; }
      .track-name { flex: 1; }
      .track-mute { opacity: 0.5; cursor: pointer; font-size: 10px; }
      .track-mute.muted { opacity: 1; color: var(--danger); }
      .timeline-ruler {
        height: 24px; background: var(--surface); border-bottom: 1px solid var(--border);
        position: sticky; top: 0; z-index: 5;
      }
      .timeline-tracks { position: relative; }
      .timeline-row {
        height: 36px; border-bottom: 1px solid var(--border); position: relative;
      }
      .keyframe {
        position: absolute; width: 10px; height: 10px; background: var(--accent);
        transform: rotate(45deg) translate(-50%, -50%); top: 13px; cursor: pointer; z-index: 2;
      }
      .keyframe:hover { background: var(--accent-2); }
      .keyframe.selected { background: var(--warning); box-shadow: 0 0 4px var(--warning); }
      .segment {
        position: absolute; height: 20px; top: 8px; background: rgba(0,122,204,0.3);
        border: 1px solid var(--accent); border-radius: 3px; cursor: move; z-index: 1;
        font-size: 9px; color: var(--text); padding: 2px 4px; overflow: hidden;
      }
      .playhead {
        position: absolute; top: 0; bottom: 0; width: 2px; background: var(--danger);
        z-index: 10; pointer-events: none;
      }
      .playhead-handle {
        position: absolute; top: 0; width: 12px; height: 12px; background: var(--danger);
        left: -5px; cursor: pointer; pointer-events: auto; clip-path: polygon(0 0, 100% 0, 50% 100%);
      }
      .easing-preview { width: 100%; height: 60px; background: var(--bg); border: 1px solid var(--border); border-radius: 4px; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAddTrack">+ Track</button>
          <select id="trackType">
            <option value="dialog">Dialog</option>
            <option value="camera">Camera</option>
            <option value="audio">Audio</option>
            <option value="effects">Effects</option>
            <option value="custom">Custom</option>
          </select>
          <div class="sep"></div>
          <button id="btnPlay">&#9654; Play</button>
          <button id="btnStop">&#9632; Stop</button>
          <span id="timeDisplay" style="font-family:monospace;font-size:12px;min-width:80px;">00:00.000</span>
          <div class="sep"></div>
          <label>Duration:</label><input type="number" id="duration" value="10" min="1" max="300" style="width:50px">s
          <label style="margin-left:8px;">Snap:</label>
          <select id="snapGrid">
            <option value="0">Off</option>
            <option value="0.1">0.1s</option>
            <option value="0.25" selected>0.25s</option>
            <option value="0.5">0.5s</option>
            <option value="1">1s</option>
          </select>
          <div class="sep"></div>
          <button id="btnAddKeyframe">+ Keyframe</button>
          <button id="btnDeleteKeyframe" class="danger">Delete KF</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>

        <div class="panel track-list" id="trackList"></div>

        <div class="timeline-area" id="timelineArea">
          <canvas class="timeline-ruler" id="ruler"></canvas>
          <div class="timeline-tracks" id="timelineTracks">
            <div class="playhead" id="playhead">
              <div class="playhead-handle"></div>
            </div>
          </div>
        </div>

        <div class="panel props-panel">
          <div class="section">
            <h3>Keyframe</h3>
            <div class="field"><label>Time (s)</label><input type="number" id="kfTime" step="0.01" min="0"></div>
            <div class="field"><label>Value</label><input type="text" id="kfValue"></div>
            <div class="field">
              <label>Easing</label>
              <select id="kfEasing">
                <option value="linear">Linear</option>
                <option value="easeIn">Ease In</option>
                <option value="easeOut">Ease Out</option>
                <option value="easeInOut">Ease In-Out</option>
                <option value="bounce">Bounce</option>
                <option value="elastic">Elastic</option>
              </select>
            </div>
            <canvas class="easing-preview" id="easingPreview"></canvas>
          </div>
          <div class="section">
            <h3>Segment</h3>
            <div class="field"><label>Label</label><input type="text" id="segLabel"></div>
            <div class="field-row">
              <div class="field" style="flex:1"><label>Start</label><input type="number" id="segStart" step="0.1"></div>
              <div class="field" style="flex:1"><label>End</label><input type="number" id="segEnd" step="0.1"></div>
            </div>
          </div>
        </div>

        <div class="status-bar">
          <span id="statusTracks">Tracks: 0</span>
          <span id="statusKeyframes">Keyframes: 0</span>
          <span id="statusDuration">Duration: 10s</span>
        </div>
      </div>
    `,`
      const TRACK_ICONS = { dialog: '\\u{1F4AC}', camera: '\\u{1F3A5}', audio: '\\u{1F50A}', effects: '\\u2728', custom: '\\u{1F527}' };
      let tracks = [
        { name: 'Dialog', type: 'dialog', muted: false, keyframes: [{t:0,val:'Hello'},{t:2,val:'World'}], segments: [{start:0,end:2,label:'Intro text'}] },
        { name: 'Camera', type: 'camera', muted: false, keyframes: [{t:0,val:'0,0'},{t:3,val:'100,50'}], segments: [{start:0,end:3,label:'Pan right'}] },
        { name: 'Music', type: 'audio', muted: false, keyframes: [{t:0,val:'bgm.ogg'}], segments: [{start:0,end:10,label:'Background music'}] },
      ];
      let selectedTrack = 0;
      let selectedKF = -1;
      let duration = 10;
      let playTime = 0;
      let playing = false;
      let playTimer = null;
      const PX_PER_SEC = 80;

      function render() {
        // Track list
        const list = document.getElementById('trackList');
        list.innerHTML = '';
        tracks.forEach((tr, i) => {
          const el = document.createElement('div');
          el.className = 'track-header' + (i === selectedTrack ? ' selected' : '');
          el.innerHTML = '<span class="track-icon">' + (TRACK_ICONS[tr.type] || '?') + '</span>' +
            '<span class="track-name">' + tr.name + '</span>' +
            '<span class="track-mute' + (tr.muted ? ' muted' : '') + '" data-t="' + i + '">M</span>';
          el.addEventListener('click', () => { selectedTrack = i; selectedKF = -1; render(); });
          list.appendChild(el);
        });

        // Timeline tracks
        const container = document.getElementById('timelineTracks');
        container.querySelectorAll('.timeline-row').forEach(r => r.remove());
        let totalKF = 0;
        tracks.forEach((tr, ti) => {
          const row = document.createElement('div');
          row.className = 'timeline-row';
          row.style.width = (duration * PX_PER_SEC) + 'px';
          // Segments
          tr.segments.forEach((seg) => {
            const el = document.createElement('div');
            el.className = 'segment';
            el.style.left = (seg.start * PX_PER_SEC) + 'px';
            el.style.width = ((seg.end - seg.start) * PX_PER_SEC) + 'px';
            el.textContent = seg.label;
            row.appendChild(el);
          });
          // Keyframes
          tr.keyframes.forEach((kf, ki) => {
            const el = document.createElement('div');
            el.className = 'keyframe' + (ti === selectedTrack && ki === selectedKF ? ' selected' : '');
            el.style.left = (kf.t * PX_PER_SEC) + 'px';
            el.addEventListener('click', (e) => {
              e.stopPropagation();
              selectedTrack = ti; selectedKF = ki;
              updateKFProps();
              render();
            });
            row.appendChild(el);
            totalKF++;
          });
          container.appendChild(row);
        });

        // Playhead
        document.getElementById('playhead').style.left = (playTime * PX_PER_SEC) + 'px';

        // Ruler
        drawRuler();

        document.getElementById('statusTracks').textContent = 'Tracks: ' + tracks.length;
        document.getElementById('statusKeyframes').textContent = 'Keyframes: ' + totalKF;
        document.getElementById('statusDuration').textContent = 'Duration: ' + duration + 's';
      }

      function drawRuler() {
        const canvas = document.getElementById('ruler');
        canvas.width = duration * PX_PER_SEC;
        canvas.height = 24;
        const ctx = canvas.getContext('2d');
        ctx.fillStyle = '#252526';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = '#858585';
        ctx.font = '10px monospace';
        for (let t = 0; t <= duration; t += 0.5) {
          const x = t * PX_PER_SEC;
          ctx.beginPath(); ctx.moveTo(x, t % 1 === 0 ? 8 : 16); ctx.lineTo(x, 24);
          ctx.strokeStyle = '#3c3c3c'; ctx.stroke();
          if (t % 1 === 0) ctx.fillText(t + 's', x + 2, 16);
        }
      }

      function updateKFProps() {
        const tr = tracks[selectedTrack];
        if (!tr || selectedKF < 0 || selectedKF >= tr.keyframes.length) return;
        const kf = tr.keyframes[selectedKF];
        document.getElementById('kfTime').value = kf.t;
        document.getElementById('kfValue').value = kf.val;
        drawEasingPreview(kf.easing || 'linear');
      }

      function drawEasingPreview(type) {
        const canvas = document.getElementById('easingPreview');
        const ctx = canvas.getContext('2d');
        canvas.width = canvas.clientWidth;
        canvas.height = 60;
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.strokeStyle = '#3c3c3c';
        ctx.strokeRect(0, 0, canvas.width, canvas.height);
        ctx.beginPath();
        ctx.strokeStyle = '#007acc';
        ctx.lineWidth = 2;
        for (let i = 0; i <= canvas.width; i++) {
          const t = i / canvas.width;
          let v;
          switch (type) {
            case 'easeIn': v = t * t; break;
            case 'easeOut': v = 1 - (1-t)*(1-t); break;
            case 'easeInOut': v = t < 0.5 ? 2*t*t : 1-Math.pow(-2*t+2,2)/2; break;
            case 'bounce': { const n=7.5625,d=2.75; let t2=1-t; v=1-(t2<1/d?n*t2*t2:t2<2/d?n*(t2-=1.5/d)*t2+.75:t2<2.5/d?n*(t2-=2.25/d)*t2+.9375:n*(t2-=2.625/d)*t2+.984375); break; }
            default: v = t;
          }
          const y = canvas.height - v * (canvas.height - 4) - 2;
          if (i === 0) ctx.moveTo(i, y); else ctx.lineTo(i, y);
        }
        ctx.stroke();
      }

      document.getElementById('kfTime').addEventListener('change', (e) => {
        const tr = tracks[selectedTrack];
        if (tr && selectedKF >= 0) { tr.keyframes[selectedKF].t = parseFloat(e.target.value); render(); }
      });
      document.getElementById('kfValue').addEventListener('change', (e) => {
        const tr = tracks[selectedTrack];
        if (tr && selectedKF >= 0) { tr.keyframes[selectedKF].val = e.target.value; }
      });
      document.getElementById('kfEasing').addEventListener('change', (e) => {
        const tr = tracks[selectedTrack];
        if (tr && selectedKF >= 0) { tr.keyframes[selectedKF].easing = e.target.value; }
        drawEasingPreview(e.target.value);
      });

      document.getElementById('btnAddTrack').addEventListener('click', () => {
        const type = document.getElementById('trackType').value;
        tracks.push({ name: type.charAt(0).toUpperCase() + type.slice(1) + ' ' + tracks.length, type, muted: false, keyframes: [], segments: [] });
        render();
      });

      document.getElementById('btnAddKeyframe').addEventListener('click', () => {
        const tr = tracks[selectedTrack];
        if (tr) {
          tr.keyframes.push({ t: playTime, val: '', easing: 'linear' });
          selectedKF = tr.keyframes.length - 1;
          render(); updateKFProps();
        }
      });
      document.getElementById('btnDeleteKeyframe').addEventListener('click', () => {
        const tr = tracks[selectedTrack];
        if (tr && selectedKF >= 0) {
          tr.keyframes.splice(selectedKF, 1);
          selectedKF = -1;
          render();
        }
      });

      document.getElementById('btnPlay').addEventListener('click', () => {
        if (playing) return;
        playing = true;
        playTimer = setInterval(() => {
          playTime += 0.05;
          if (playTime >= duration) { playTime = 0; }
          document.getElementById('playhead').style.left = (playTime * PX_PER_SEC) + 'px';
          const m = Math.floor(playTime / 60);
          const s = Math.floor(playTime % 60);
          const ms = Math.floor((playTime % 1) * 1000);
          document.getElementById('timeDisplay').textContent =
            String(m).padStart(2,'0') + ':' + String(s).padStart(2,'0') + '.' + String(ms).padStart(3,'0');
        }, 50);
      });
      document.getElementById('btnStop').addEventListener('click', () => {
        playing = false;
        clearInterval(playTimer);
        playTime = 0;
        document.getElementById('playhead').style.left = '0px';
        document.getElementById('timeDisplay').textContent = '00:00.000';
      });

      document.getElementById('duration').addEventListener('change', (e) => {
        duration = parseInt(e.target.value);
        render();
      });

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  duration = ' + duration + ',\\n  tracks = {\\n';
        tracks.forEach(tr => {
          lua += '    { name = "' + tr.name + '", type = "' + tr.type + '",\\n';
          lua += '      keyframes = {\\n';
          tr.keyframes.forEach(kf => {
            lua += '        { t = ' + kf.t + ', value = "' + kf.val + '", easing = "' + (kf.easing||'linear') + '" },\\n';
          });
          lua += '      },\\n      segments = {\\n';
          tr.segments.forEach(seg => {
            lua += '        { start = ' + seg.start + ', stop = ' + seg.end + ', label = "' + seg.label + '" },\\n';
          });
          lua += '      },\\n    },\\n';
        });
        lua += '  }\\n}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      render();
      drawEasingPreview('linear');
    `)}};var Wn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.shaderPreviewEditor","Shader Preview")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"shader.lua");break}}getHtml(){let e=R();return D(e,"Shader Preview",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 1fr;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .code-area { grid-row: 2; display: flex; flex-direction: column; border-right: 1px solid var(--border); }
      .preview-area { grid-row: 2; display: flex; flex-direction: column; }
      .status-bar { grid-column: 1 / -1; }
      .code-editor {
        flex: 1; background: var(--bg); color: #d4d4d4; font-family: 'Consolas', 'Courier New', monospace;
        font-size: 13px; line-height: 1.5; padding: 10px; border: none; resize: none;
        tab-size: 2; white-space: pre; overflow: auto;
      }
      .code-editor:focus { outline: none; }
      .preview-canvas-wrapper { flex: 1; display: flex; align-items: center; justify-content: center; background: #111; }
      .params-bar {
        padding: 8px; background: var(--surface); border-top: 1px solid var(--border);
        display: flex; flex-wrap: wrap; gap: 8px; align-items: center;
      }
      .param-item { display: flex; align-items: center; gap: 4px; font-size: 11px; }
      .param-item input[type="range"] { width: 80px; }
      .error-bar {
        padding: 4px 10px; background: rgba(244,67,54,0.15); color: var(--danger);
        font-family: monospace; font-size: 11px; white-space: pre-wrap; max-height: 60px; overflow-y: auto;
      }
      .preset-btn { font-size: 11px; padding: 2px 8px; }
      .perf-stat { font-family: monospace; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <label>Preset:</label>
          <button class="preset-btn active" data-preset="blur">Blur</button>
          <button class="preset-btn" data-preset="glow">Glow</button>
          <button class="preset-btn" data-preset="dissolve">Dissolve</button>
          <button class="preset-btn" data-preset="pixel">Pixelate</button>
          <button class="preset-btn" data-preset="wave">Wave</button>
          <button class="preset-btn" data-preset="custom">Custom</button>
          <div class="sep"></div>
          <button id="btnRun">&#9654; Run</button>
          <button id="btnPause">&#10074;&#10074;</button>
          <div class="sep"></div>
          <button id="btnExport">Export</button>
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
          <span id="statusPreset">Preset: blur</span>
          <span class="perf-stat" id="perfFps">FPS: --</span>
          <span class="perf-stat" id="perfTime">Frame: -- ms</span>
        </div>
      </div>
    `,`
      const canvas = document.getElementById('previewCanvas');
      const ctx = canvas.getContext('2d');
      const editor = document.getElementById('codeEditor');
      let running = true;
      let frameCount = 0;
      let lastFpsTime = performance.now();
      let currentPreset = 'blur';

      const PRESETS = {
        blur: {
          code: '-- Gaussian Blur Shader\\n-- Uniforms: radius, intensity\\n\\nfunction effect(pixel, x, y, uniforms)\\n  local r = uniforms.radius or 3\\n  local sum_r, sum_g, sum_b = 0, 0, 0\\n  local count = 0\\n  for dy = -r, r do\\n    for dx = -r, r do\\n      local p = getPixel(x + dx, y + dy)\\n      sum_r = sum_r + p.r\\n      sum_g = sum_g + p.g\\n      sum_b = sum_b + p.b\\n      count = count + 1\\n    end\\n  end\\n  return {\\n    r = sum_r / count,\\n    g = sum_g / count,\\n    b = sum_b / count,\\n    a = pixel.a\\n  }\\nend',
          params: [{ name: 'radius', min: 1, max: 20, value: 3 }, { name: 'intensity', min: 0, max: 100, value: 50 }],
        },
        glow: {
          code: '-- Glow Shader\\n-- Uniforms: threshold, strength, color\\n\\nfunction effect(pixel, x, y, uniforms)\\n  local lum = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114\\n  local t = uniforms.threshold or 0.5\\n  local s = (uniforms.strength or 50) / 100\\n  if lum > t then\\n    return {\\n      r = math.min(1, pixel.r + pixel.r * s),\\n      g = math.min(1, pixel.g + pixel.g * s),\\n      b = math.min(1, pixel.b + pixel.b * s),\\n      a = pixel.a\\n    }\\n  end\\n  return pixel\\nend',
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

      function loadPreset(name) {
        currentPreset = name;
        const preset = PRESETS[name];
        editor.value = preset.code;
        params = {};
        preset.params.forEach(p => { params[p.name] = p.value; });
        buildParams(preset.params);
        document.getElementById('statusPreset').textContent = 'Preset: ' + name;
        document.getElementById('errorBar').style.display = 'none';
        document.querySelectorAll('.preset-btn').forEach(b => b.classList.toggle('active', b.dataset.preset === name));
      }

      function buildParams(paramDefs) {
        const bar = document.getElementById('paramsBar');
        bar.innerHTML = '';
        paramDefs.forEach(p => {
          const item = document.createElement('div');
          item.className = 'param-item';
          item.innerHTML = '<label>' + p.name + '</label><input type="range" min="' + p.min + '" max="' + p.max + '" value="' + p.value + '" data-p="' + p.name + '"><span>' + p.value + '</span>';
          item.querySelector('input').addEventListener('input', (e) => {
            const v = parseInt(e.target.value);
            params[p.name] = v;
            e.target.nextElementSibling.textContent = v;
          });
          bar.appendChild(item);
        });
      }

      // Simple preview: draw a colorful pattern and show effect visually
      let time = 0;
      function renderPreview() {
        if (!running) return;
        const t0 = performance.now();
        const w = canvas.width, h = canvas.height;
        const imgData = ctx.createImageData(w, h);
        for (let y = 0; y < h; y++) {
          for (let x = 0; x < w; x++) {
            const i = (y * w + x) * 4;
            // Base pattern: gradient + circles
            const cx = w/2, cy = h/2;
            const dist = Math.sqrt((x-cx)*(x-cx) + (y-cy)*(y-cy));
            const wave = Math.sin(dist * 0.05 - time * 0.02) * 0.5 + 0.5;
            let r = Math.floor((x / w) * 200 * wave + 55);
            let g = Math.floor((y / h) * 200 * wave + 55);
            let b = Math.floor(128 + 127 * Math.sin(time * 0.01 + x * 0.02));

            // Apply simple param-based effects for visual demo
            if (currentPreset === 'pixel') {
              const s = Math.max(1, params.size || 8);
              const bx = Math.floor(x / s) * s;
              const by = Math.floor(y / s) * s;
              const bd = Math.sqrt((bx-cx)*(bx-cx) + (by-cy)*(by-cy));
              const bw = Math.sin(bd * 0.05 - time * 0.02) * 0.5 + 0.5;
              r = Math.floor((bx / w) * 200 * bw + 55);
              g = Math.floor((by / h) * 200 * bw + 55);
            } else if (currentPreset === 'dissolve') {
              const noise = Math.sin(x * 12.9898 + y * 78.233) * 43758.5453;
              const n = noise - Math.floor(noise);
              const p = (params.progress || 30) / 100;
              if (n < p) { r = 0; g = 0; b = 0; }
              else if (n < p + 0.05) { r = 255; g = 128; b = 0; }
            } else if (currentPreset === 'wave') {
              const amp = params.amplitude || 10;
              const freq = (params.frequency || 20) / 100;
              const off = Math.sin(y * freq + time * 0.03) * amp;
              const sx = Math.floor(x + off);
              if (sx >= 0 && sx < w) {
                const sd = Math.sqrt((sx-cx)*(sx-cx) + (y-cy)*(y-cy));
                const sw = Math.sin(sd * 0.05 - time * 0.02) * 0.5 + 0.5;
                r = Math.floor((sx / w) * 200 * sw + 55);
              }
            }

            imgData.data[i] = Math.min(255, Math.max(0, r));
            imgData.data[i+1] = Math.min(255, Math.max(0, g));
            imgData.data[i+2] = Math.min(255, Math.max(0, b));
            imgData.data[i+3] = 255;
          }
        }
        ctx.putImageData(imgData, 0, 0);
        time++;
        frameCount++;

        const elapsed = performance.now() - t0;
        document.getElementById('perfTime').textContent = 'Frame: ' + elapsed.toFixed(1) + ' ms';
        const now = performance.now();
        if (now - lastFpsTime >= 1000) {
          document.getElementById('perfFps').textContent = 'FPS: ' + frameCount;
          frameCount = 0;
          lastFpsTime = now;
        }
        requestAnimationFrame(renderPreview);
      }

      document.querySelectorAll('.preset-btn').forEach(btn => {
        btn.addEventListener('click', () => loadPreset(btn.dataset.preset));
      });

      document.getElementById('btnRun').addEventListener('click', () => {
        running = true;
        renderPreview();
      });
      document.getElementById('btnPause').addEventListener('click', () => { running = false; });

      document.getElementById('btnExport').addEventListener('click', () => {
        vscode.postMessage({ type: 'exportLua', content: editor.value });
      });

      loadPreset('blur');
      renderPreview();
    `)}};var Hn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.fontPreviewEditor","Font Preview")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"font_config.lua");break}}getHtml(){let e=R();return D(e,"Font Preview",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 240px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .preview-area { grid-row: 2; overflow-y: auto; padding: 20px; }
      .config-panel { grid-row: 2; }
      .status-bar { grid-column: 1 / -1; }
      .text-input-bar {
        padding: 8px 20px; background: var(--surface); border-bottom: 1px solid var(--border);
      }
      .text-input-bar input { width: 100%; font-size: 14px; padding: 6px 10px; }
      .specimen-block { margin-bottom: 20px; }
      .specimen-label { font-size: 11px; color: var(--text-dim); margin-bottom: 4px; }
      .specimen-text { word-wrap: break-word; }
      .glyph-grid {
        display: grid; grid-template-columns: repeat(16, 1fr); gap: 2px; margin-top: 12px;
      }
      .glyph-cell {
        aspect-ratio: 1; display: flex; align-items: center; justify-content: center;
        background: var(--surface); border: 1px solid var(--border); border-radius: 2px;
        cursor: pointer; font-size: 16px; min-height: 32px;
      }
      .glyph-cell:hover { border-color: var(--accent); background: var(--surface-2); }
      .glyph-cell.selected { border-color: var(--accent); background: var(--selection); }
      .size-preview { border-bottom: 1px solid var(--border); padding-bottom: 12px; margin-bottom: 12px; }
      .color-picker-row { display: flex; align-items: center; gap: 8px; }
      .color-swatch-sm {
        width: 24px; height: 24px; border-radius: 3px; border: 1px solid var(--border);
        cursor: pointer;
      }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <label>Font:</label>
          <select id="fontFamily" style="width:160px;">
            <option value="sans-serif">Sans-Serif (default)</option>
            <option value="serif">Serif</option>
            <option value="monospace">Monospace</option>
            <option value="cursive">Cursive</option>
            <option value="fantasy">Fantasy</option>
          </select>
          <div class="sep"></div>
          <label>Size:</label>
          <input type="range" id="fontSize" min="8" max="72" value="24" style="width:100px">
          <span id="sizeLabel">24pt</span>
          <div class="sep"></div>
          <button id="btnBold">B</button>
          <button id="btnItalic"><em>I</em></button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>

        <div class="preview-area" id="previewArea">
          <div class="text-input-bar">
            <input type="text" id="sampleText" value="The quick brown fox jumps over the lazy dog. 0123456789" placeholder="Type sample text...">
          </div>

          <div style="padding-top:16px;">
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

        <div class="panel config-panel">
          <div class="section">
            <h3>Text Color</h3>
            <div class="color-picker-row">
              <input type="color" id="textColor" value="#cccccc">
              <span id="textColorHex">#cccccc</span>
            </div>
          </div>
          <div class="section">
            <h3>Background</h3>
            <div class="color-picker-row">
              <input type="color" id="bgColor" value="#1e1e1e">
              <span id="bgColorHex">#1e1e1e</span>
            </div>
          </div>
          <div class="section">
            <h3>Spacing</h3>
            <div class="field">
              <label>Line Height: <span id="lhVal">1.5</span></label>
              <input type="range" id="lineHeight" min="10" max="30" value="15" style="width:100%">
            </div>
            <div class="field">
              <label>Letter Spacing: <span id="lsVal">0</span>px</label>
              <input type="range" id="letterSpacing" min="-5" max="20" value="0" style="width:100%">
            </div>
          </div>
          <div class="section">
            <h3>Selected Glyph</h3>
            <div style="text-align:center;font-size:48px;padding:12px;" id="selectedGlyph">A</div>
            <div style="text-align:center;font-size:11px;color:var(--text-dim);" id="glyphInfo">U+0041 | LATIN CAPITAL LETTER A</div>
          </div>
          <div class="section">
            <h3>Font Sizes Preview</h3>
            <div class="field-row">
              <button class="preset-size" data-s="8">8</button>
              <button class="preset-size" data-s="12">12</button>
              <button class="preset-size" data-s="16">16</button>
              <button class="preset-size" data-s="24">24</button>
              <button class="preset-size" data-s="32">32</button>
              <button class="preset-size" data-s="48">48</button>
              <button class="preset-size" data-s="72">72</button>
            </div>
          </div>
        </div>

        <div class="status-bar">
          <span id="statusFont">Font: sans-serif</span>
          <span id="statusSize">Size: 24pt</span>
          <span id="statusGlyphs">Glyphs: 95</span>
        </div>
      </div>
    `,`
      let fontFamily = 'sans-serif';
      let fontSize = 24;
      let bold = false, italic = false;
      let textColor = '#cccccc', bgColor = '#1e1e1e';
      let lineHeight = 1.5, letterSpacing = 0;

      const PRINTABLE_START = 32, PRINTABLE_END = 126;

      function getStyle(size) {
        return (italic ? 'italic ' : '') + (bold ? 'bold ' : '') + (size || fontSize) + 'px ' + fontFamily;
      }

      function updatePreview() {
        const text = document.getElementById('sampleText').value;
        const main = document.getElementById('mainPreview');
        main.style.font = getStyle();
        main.style.color = textColor;
        main.style.lineHeight = lineHeight;
        main.style.letterSpacing = letterSpacing + 'px';
        main.textContent = text;
        document.getElementById('previewArea').style.background = bgColor;

        // Multi-size preview
        const multi = document.getElementById('multiSizePreview');
        multi.innerHTML = '';
        [8, 12, 16, 24, 32, 48].forEach(s => {
          const div = document.createElement('div');
          div.style.font = getStyle(s);
          div.style.color = textColor;
          div.style.marginBottom = '8px';
          div.style.lineHeight = lineHeight;
          div.style.letterSpacing = letterSpacing + 'px';
          const label = document.createElement('span');
          label.className = 'specimen-label';
          label.textContent = s + 'pt  ';
          div.appendChild(label);
          div.appendChild(document.createTextNode(text));
          multi.appendChild(div);
        });
      }

      function buildGlyphGrid() {
        const grid = document.getElementById('glyphGrid');
        grid.innerHTML = '';
        for (let code = PRINTABLE_START; code <= PRINTABLE_END; code++) {
          const cell = document.createElement('div');
          cell.className = 'glyph-cell';
          cell.style.fontFamily = fontFamily;
          cell.textContent = String.fromCharCode(code);
          cell.addEventListener('click', () => {
            grid.querySelectorAll('.glyph-cell').forEach(c => c.classList.remove('selected'));
            cell.classList.add('selected');
            document.getElementById('selectedGlyph').textContent = String.fromCharCode(code);
            document.getElementById('selectedGlyph').style.fontFamily = fontFamily;
            document.getElementById('glyphInfo').textContent = 'U+' + code.toString(16).toUpperCase().padStart(4, '0') + ' | Code: ' + code;
          });
          grid.appendChild(cell);
        }
        document.getElementById('statusGlyphs').textContent = 'Glyphs: ' + (PRINTABLE_END - PRINTABLE_START + 1);
      }

      document.getElementById('fontFamily').addEventListener('change', (e) => {
        fontFamily = e.target.value;
        document.getElementById('statusFont').textContent = 'Font: ' + fontFamily;
        updatePreview(); buildGlyphGrid();
      });
      document.getElementById('fontSize').addEventListener('input', (e) => {
        fontSize = parseInt(e.target.value);
        document.getElementById('sizeLabel').textContent = fontSize + 'pt';
        document.getElementById('statusSize').textContent = 'Size: ' + fontSize + 'pt';
        updatePreview();
      });
      document.getElementById('btnBold').addEventListener('click', (e) => {
        bold = !bold; e.target.classList.toggle('active', bold); updatePreview();
      });
      document.getElementById('btnItalic').addEventListener('click', (e) => {
        italic = !italic; e.target.classList.toggle('active', italic); updatePreview();
      });
      document.getElementById('sampleText').addEventListener('input', updatePreview);

      document.getElementById('textColor').addEventListener('input', (e) => {
        textColor = e.target.value;
        document.getElementById('textColorHex').textContent = textColor;
        updatePreview();
      });
      document.getElementById('bgColor').addEventListener('input', (e) => {
        bgColor = e.target.value;
        document.getElementById('bgColorHex').textContent = bgColor;
        updatePreview();
      });
      document.getElementById('lineHeight').addEventListener('input', (e) => {
        lineHeight = parseInt(e.target.value) / 10;
        document.getElementById('lhVal').textContent = lineHeight.toFixed(1);
        updatePreview();
      });
      document.getElementById('letterSpacing').addEventListener('input', (e) => {
        letterSpacing = parseInt(e.target.value);
        document.getElementById('lsVal').textContent = letterSpacing;
        updatePreview();
      });

      document.querySelectorAll('.preset-size').forEach(b => {
        b.addEventListener('click', () => {
          fontSize = parseInt(b.dataset.s);
          document.getElementById('fontSize').value = fontSize;
          document.getElementById('sizeLabel').textContent = fontSize + 'pt';
          updatePreview();
        });
      });

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = '-- Font configuration for Lurek2D\\n';
        lua += 'local font = lurek.graphics.newFont("' + fontFamily + '", ' + fontSize + ')\\n';
        lua += '-- Style: ' + (bold ? 'bold ' : '') + (italic ? 'italic' : 'normal') + '\\n';
        lua += '-- Color: { ' + parseInt(textColor.slice(1,3),16) + ', ' + parseInt(textColor.slice(3,5),16) + ', ' + parseInt(textColor.slice(5,7),16) + ' }\\n';
        lua += '-- Line height: ' + lineHeight.toFixed(1) + '\\n';
        lua += '-- Letter spacing: ' + letterSpacing + '\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      updatePreview();
      buildGlyphGrid();
    `)}};var jn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.localizationEditor","Localization")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"strings.lua");break;case"exportJson":this.exportFile(e.content,"strings.json","JSON","json");break}}getHtml(){let e=R();return D(e,"Localization",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr;
        grid-template-rows: auto auto 1fr auto auto;
        height: 100vh;
      }
      .toolbar { grid-row: 1; }
      .filter-bar { grid-row: 2; padding: 6px 10px; background: var(--surface); border-bottom: 1px solid var(--border); display: flex; gap: 8px; align-items: center; }
      .table-area { grid-row: 3; overflow: auto; }
      .stats-bar { grid-row: 4; padding: 6px 10px; background: var(--surface); border-top: 1px solid var(--border); display: flex; gap: 16px; flex-wrap: wrap; }
      .status-bar { grid-row: 5; }
      .loc-table { width: 100%; border-collapse: collapse; font-size: 12px; }
      .loc-table th {
        position: sticky; top: 0; z-index: 5;
        text-align: left; padding: 6px 8px; background: var(--surface);
        border-bottom: 2px solid var(--border); font-size: 11px; text-transform: uppercase;
        color: var(--text-dim); white-space: nowrap;
      }
      .loc-table td {
        padding: 2px 4px; border-bottom: 1px solid var(--border); vertical-align: top;
      }
      .loc-table tr:hover { background: var(--surface-2); }
      .loc-table tr.selected { background: var(--selection); }
      .loc-input {
        width: 100%; background: transparent; border: 1px solid transparent;
        color: var(--text); padding: 2px 4px; font-size: 12px;
      }
      .loc-input:focus { border-color: var(--accent); background: var(--surface); }
      .loc-input.missing { border-color: var(--danger); background: rgba(244,67,54,0.08); }
      .key-cell { font-family: monospace; font-size: 11px; color: var(--accent-2); min-width: 140px; }
      .coverage-bar {
        display: flex; align-items: center; gap: 6px; font-size: 11px;
      }
      .coverage-fill {
        width: 60px; height: 8px; background: var(--surface-2); border-radius: 4px; overflow: hidden;
      }
      .coverage-fill-inner { height: 100%; border-radius: 4px; transition: width 0.3s; }
      .lang-header { display: flex; align-items: center; gap: 4px; }
      .lang-remove { font-size: 10px; cursor: pointer; opacity: 0.5; }
      .lang-remove:hover { opacity: 1; color: var(--danger); }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAddKey">+ Key</button>
          <button id="btnRemoveKey" class="danger">Remove Key</button>
          <div class="sep"></div>
          <button id="btnAddLang">+ Language</button>
          <button id="btnRemoveLang" class="danger">Remove Lang</button>
          <div class="sep"></div>
          <button id="btnImportJson">Import JSON</button>
          <button id="btnExportJson">Export JSON</button>
          <button id="btnExportLua">Export Lua</button>
        </div>

        <div class="filter-bar">
          <label>Search:</label>
          <input type="text" id="searchInput" placeholder="Filter keys or values..." style="flex:1;max-width:300px;">
          <label>Show:</label>
          <select id="filterMode">
            <option value="all">All</option>
            <option value="missing">Missing translations</option>
            <option value="complete">Complete only</option>
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
          <span id="statusKeys">Keys: 0</span>
          <span id="statusLangs">Languages: 0</span>
          <span id="statusTotal">Translations: 0</span>
        </div>
      </div>
    `,`
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
      let selectedRow = -1;
      let searchText = '';
      let filterMode = 'all';

      function render() {
        // Head
        const head = document.getElementById('tableHead');
        head.innerHTML = '<tr><th style="width:160px;">Key</th>';
        languages.forEach(lang => {
          head.querySelector('tr').innerHTML += '<th><div class="lang-header">' + lang.toUpperCase() + (lang === baseLang ? ' (base)' : '') + '</div></th>';
        });
        head.querySelector('tr').innerHTML += '</tr>';

        // Body
        const body = document.getElementById('tableBody');
        body.innerHTML = '';
        const filtered = getFilteredEntries();
        filtered.forEach((entry, fi) => {
          const origIdx = entries.indexOf(entry);
          const tr = document.createElement('tr');
          tr.className = origIdx === selectedRow ? 'selected' : '';
          tr.addEventListener('click', () => { selectedRow = origIdx; render(); });

          const tdKey = document.createElement('td');
          tdKey.className = 'key-cell';
          const keyInput = document.createElement('input');
          keyInput.className = 'loc-input';
          keyInput.value = entry.key;
          keyInput.style.fontFamily = 'monospace';
          keyInput.style.color = 'var(--accent-2)';
          keyInput.addEventListener('change', (e) => { entry.key = e.target.value; });
          tdKey.appendChild(keyInput);
          tr.appendChild(tdKey);

          languages.forEach(lang => {
            const td = document.createElement('td');
            const input = document.createElement('input');
            input.className = 'loc-input' + ((entry.values[lang] || '').trim() === '' ? ' missing' : '');
            input.value = entry.values[lang] || '';
            input.placeholder = lang === baseLang ? '(base)' : '(missing)';
            input.addEventListener('change', (e) => { entry.values[lang] = e.target.value; updateStats(); render(); });
            td.appendChild(input);
            tr.appendChild(td);
          });
          body.appendChild(tr);
        });

        updateStats();
      }

      function getFilteredEntries() {
        return entries.filter(e => {
          if (searchText) {
            const s = searchText.toLowerCase();
            const matchKey = e.key.toLowerCase().includes(s);
            const matchVal = Object.values(e.values).some(v => (v || '').toLowerCase().includes(s));
            if (!matchKey && !matchVal) return false;
          }
          if (filterMode === 'missing') {
            return languages.some(l => !(e.values[l] || '').trim());
          }
          if (filterMode === 'complete') {
            return languages.every(l => (e.values[l] || '').trim());
          }
          return true;
        });
      }

      function updateStats() {
        const bar = document.getElementById('statsBar');
        bar.innerHTML = '';
        let totalFilled = 0, totalCells = 0;
        languages.forEach(lang => {
          let filled = 0;
          entries.forEach(e => { if ((e.values[lang] || '').trim()) filled++; });
          totalFilled += filled;
          totalCells += entries.length;
          const pct = entries.length > 0 ? Math.round(filled / entries.length * 100) : 0;
          const color = pct === 100 ? 'var(--success)' : pct > 50 ? 'var(--warning)' : 'var(--danger)';
          const item = document.createElement('div');
          item.className = 'coverage-bar';
          item.innerHTML = '<strong>' + lang.toUpperCase() + '</strong>' +
            '<div class="coverage-fill"><div class="coverage-fill-inner" style="width:' + pct + '%;background:' + color + '"></div></div>' +
            '<span>' + pct + '% (' + filled + '/' + entries.length + ')</span>';
          bar.appendChild(item);
        });
        document.getElementById('statusKeys').textContent = 'Keys: ' + entries.length;
        document.getElementById('statusLangs').textContent = 'Languages: ' + languages.length;
        document.getElementById('statusTotal').textContent = 'Translations: ' + totalFilled + '/' + totalCells;
      }

      document.getElementById('searchInput').addEventListener('input', (e) => {
        searchText = e.target.value; render();
      });
      document.getElementById('filterMode').addEventListener('change', (e) => {
        filterMode = e.target.value; render();
      });

      document.getElementById('btnAddKey').addEventListener('click', () => {
        const values = {};
        languages.forEach(l => { values[l] = ''; });
        entries.push({ key: 'new.key.' + entries.length, values });
        selectedRow = entries.length - 1;
        render();
      });
      document.getElementById('btnRemoveKey').addEventListener('click', () => {
        if (selectedRow >= 0 && selectedRow < entries.length) {
          entries.splice(selectedRow, 1);
          selectedRow = Math.min(selectedRow, entries.length - 1);
          render();
        }
      });

      document.getElementById('btnAddLang').addEventListener('click', () => {
        const lang = prompt('Language code (e.g. ja, ko, pt):');
        if (lang && !languages.includes(lang)) {
          languages.push(lang);
          entries.forEach(e => { e.values[lang] = ''; });
          render();
        }
      });
      document.getElementById('btnRemoveLang').addEventListener('click', () => {
        if (languages.length <= 1) return;
        const lang = prompt('Language code to remove:');
        if (lang && languages.includes(lang) && lang !== baseLang) {
          languages = languages.filter(l => l !== lang);
          entries.forEach(e => { delete e.values[lang]; });
          render();
        }
      });

      document.getElementById('btnExportJson').addEventListener('click', () => {
        const obj = {};
        languages.forEach(l => { obj[l] = {}; entries.forEach(e => { obj[l][e.key] = e.values[l] || ''; }); });
        vscode.postMessage({ type: 'exportJson', content: JSON.stringify(obj, null, 2) });
      });

      document.getElementById('btnExportLua').addEventListener('click', () => {
        let lua = 'return {\\n';
        languages.forEach(l => {
          lua += '  ' + l + ' = {\\n';
          entries.forEach(e => {
            const val = (e.values[l] || '').replace(/"/g, '\\\\"');
            lua += '    ["' + e.key + '"] = "' + val + '",\\n';
          });
          lua += '  },\\n';
        });
        lua += '}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      render();
    `)}};var qn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.physicsMaterialsEditor","Physics Materials")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"physics_materials.lua");break}}getHtml(){let e=R();return D(e,"Physics Materials",`
      .editor-layout {
        display: grid; grid-template-columns: 200px 1fr 240px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .material-list { grid-row: 2; }
      .preview-area { grid-row: 2; display: flex; flex-direction: column; }
      .props-panel { grid-row: 2; }
      .status-bar { grid-column: 1 / -1; }
      .mat-item {
        display: flex; align-items: center; gap: 6px; padding: 6px 8px;
        cursor: pointer; border-radius: 3px; font-size: 12px; border-bottom: 1px solid var(--border);
      }
      .mat-item:hover { background: var(--surface-2); }
      .mat-item.selected { background: var(--selection); }
      .mat-color {
        width: 14px; height: 14px; border-radius: 50%; border: 1px solid var(--border); flex-shrink: 0;
      }
      .canvas-section { flex: 1; display: flex; align-items: center; justify-content: center; background: var(--bg); }
      .matrix-section {
        border-top: 1px solid var(--border); padding: 10px; background: var(--surface); overflow: auto;
      }
      .matrix-table { border-collapse: collapse; font-size: 10px; }
      .matrix-table th {
        padding: 4px; background: var(--surface-2); border: 1px solid var(--border);
        writing-mode: vertical-lr; text-orientation: mixed; max-width: 30px;
      }
      .matrix-table td { padding: 0; border: 1px solid var(--border); text-align: center; }
      .matrix-cell {
        width: 24px; height: 24px; cursor: pointer; display: flex;
        align-items: center; justify-content: center;
      }
      .matrix-cell.on { background: var(--accent); color: #fff; }
      .matrix-cell.off { background: var(--surface-2); color: var(--text-dim); }
      .slider-labeled { display: flex; flex-direction: column; gap: 2px; margin-bottom: 8px; }
      .slider-labeled .row { display: flex; align-items: center; gap: 6px; }
      .slider-labeled input[type="range"] { flex: 1; }
      .slider-labeled .val { font-family: monospace; font-size: 11px; min-width: 36px; text-align: right; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAdd">+ Material</button>
          <button id="btnDuplicate">Duplicate</button>
          <button id="btnRemove" class="danger">Remove</button>
          <div class="sep"></div>
          <button id="btnPresets">Load Presets</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>

        <div class="panel material-list" id="materialList"></div>

        <div class="preview-area">
          <div class="canvas-section">
            <canvas id="previewCanvas" width="360" height="260"></canvas>
          </div>
          <div class="matrix-section">
            <h3 style="font-size:11px;text-transform:uppercase;color:var(--text-dim);margin-bottom:6px;">Collision Matrix</h3>
            <table class="matrix-table" id="collisionMatrix"></table>
          </div>
        </div>

        <div class="panel props-panel">
          <div class="section">
            <h3>Material Properties</h3>
            <div class="field"><label>Name</label><input type="text" id="matName" style="width:100%"></div>
            <div class="field"><label>Color</label><input type="color" id="matColor" value="#007acc"></div>
          </div>
          <div class="section">
            <div class="slider-labeled">
              <label>Friction</label>
              <div class="row"><input type="range" id="friction" min="0" max="100" value="50"><span class="val" id="frictionVal">0.50</span></div>
            </div>
            <div class="slider-labeled">
              <label>Restitution (bounciness)</label>
              <div class="row"><input type="range" id="restitution" min="0" max="100" value="30"><span class="val" id="restitutionVal">0.30</span></div>
            </div>
            <div class="slider-labeled">
              <label>Density</label>
              <div class="row"><input type="range" id="density" min="1" max="200" value="10"><span class="val" id="densityVal">1.0</span></div>
            </div>
          </div>
          <div class="section">
            <h3>Collision Layer</h3>
            <div class="field">
              <label>Layer</label>
              <select id="collisionLayer" style="width:100%;">
                <option value="0">Layer 0 (Default)</option>
                <option value="1">Layer 1</option>
                <option value="2">Layer 2</option>
                <option value="3">Layer 3</option>
                <option value="4">Layer 4</option>
                <option value="5">Layer 5</option>
                <option value="6">Layer 6</option>
                <option value="7">Layer 7</option>
              </select>
            </div>
          </div>
        </div>

        <div class="status-bar">
          <span id="statusMat">Material: none</span>
          <span id="statusCount">Materials: 0</span>
          <span id="statusLayers">Layers: 8</span>
        </div>
      </div>
    `,`
      let materials = [
        { name: 'Default', friction: 0.5, restitution: 0.3, density: 1.0, layer: 0, color: '#858585' },
        { name: 'Ice', friction: 0.05, restitution: 0.1, density: 0.9, layer: 0, color: '#80d4ff' },
        { name: 'Rubber', friction: 0.9, restitution: 0.8, density: 1.2, layer: 0, color: '#e06040' },
        { name: 'Metal', friction: 0.3, restitution: 0.2, density: 7.8, layer: 1, color: '#a0a0a0' },
        { name: 'Wood', friction: 0.6, restitution: 0.4, density: 0.6, layer: 0, color: '#b07040' },
      ];
      let selectedMat = 0;
      const NUM_LAYERS = 8;
      let collisionMatrix = [];
      for (let i = 0; i < NUM_LAYERS; i++) {
        collisionMatrix[i] = new Array(NUM_LAYERS).fill(true);
      }

      const canvas = document.getElementById('previewCanvas');
      const ctx = canvas.getContext('2d');
      let ballX = 180, ballY = 40, ballVY = 0, ballVX = 0;
      const GRAVITY = 0.3;
      const FLOOR_Y = 220;
      let animId = null;

      function render() {
        const list = document.getElementById('materialList');
        list.innerHTML = '';
        materials.forEach((mat, i) => {
          const el = document.createElement('div');
          el.className = 'mat-item' + (i === selectedMat ? ' selected' : '');
          el.innerHTML = '<div class="mat-color" style="background:' + mat.color + '"></div><span>' + mat.name + '</span>';
          el.addEventListener('click', () => { selectedMat = i; render(); updateProps(); resetBall(); });
          list.appendChild(el);
        });
        renderMatrix();
        document.getElementById('statusCount').textContent = 'Materials: ' + materials.length;
        document.getElementById('statusMat').textContent = 'Material: ' + (materials[selectedMat]?.name || 'none');
      }

      function updateProps() {
        const mat = materials[selectedMat];
        if (!mat) return;
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
        const table = document.getElementById('collisionMatrix');
        table.innerHTML = '';
        const headerRow = document.createElement('tr');
        headerRow.innerHTML = '<th></th>';
        for (let i = 0; i < NUM_LAYERS; i++) { headerRow.innerHTML += '<th>L' + i + '</th>'; }
        table.appendChild(headerRow);
        for (let r = 0; r < NUM_LAYERS; r++) {
          const row = document.createElement('tr');
          row.innerHTML = '<th>L' + r + '</th>';
          for (let c = 0; c < NUM_LAYERS; c++) {
            const td = document.createElement('td');
            const cell = document.createElement('div');
            const on = collisionMatrix[r][c];
            cell.className = 'matrix-cell ' + (on ? 'on' : 'off');
            cell.textContent = on ? '\\u2713' : '';
            cell.addEventListener('click', () => {
              collisionMatrix[r][c] = !collisionMatrix[r][c];
              collisionMatrix[c][r] = collisionMatrix[r][c]; // symmetric
              renderMatrix();
            });
            td.appendChild(cell);
            row.appendChild(td);
          }
          table.appendChild(row);
        }
      }

      function resetBall() {
        ballX = 180; ballY = 40; ballVY = 0; ballVX = 1;
      }

      function animatePreview() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        const mat = materials[selectedMat];
        if (!mat) { animId = requestAnimationFrame(animatePreview); return; }

        // Floor
        ctx.fillStyle = '#333';
        ctx.fillRect(0, FLOOR_Y, canvas.width, canvas.height - FLOOR_Y);
        ctx.fillStyle = '#555';
        ctx.fillText('friction: ' + mat.friction.toFixed(2) + '  restitution: ' + mat.restitution.toFixed(2) + '  density: ' + mat.density.toFixed(1), 10, FLOOR_Y + 20);

        // Ball physics
        ballVY += GRAVITY;
        ballY += ballVY;
        ballX += ballVX;

        const radius = 10 + mat.density * 2;

        if (ballY + radius >= FLOOR_Y) {
          ballY = FLOOR_Y - radius;
          ballVY = -ballVY * mat.restitution;
          ballVX *= (1 - mat.friction * 0.1);
          if (Math.abs(ballVY) < 0.5) ballVY = 0;
        }

        if (ballX + radius >= canvas.width || ballX - radius <= 0) {
          ballVX = -ballVX * 0.9;
          ballX = Math.max(radius, Math.min(canvas.width - radius, ballX));
        }

        // Draw ball
        ctx.beginPath();
        ctx.arc(ballX, ballY, radius, 0, Math.PI * 2);
        ctx.fillStyle = mat.color;
        ctx.fill();
        ctx.strokeStyle = '#fff';
        ctx.lineWidth = 1;
        ctx.stroke();

        // Label
        ctx.fillStyle = '#fff';
        ctx.font = '11px sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText(mat.name, ballX, ballY - radius - 6);

        animId = requestAnimationFrame(animatePreview);
      }

      document.getElementById('matName').addEventListener('change', (e) => {
        if (materials[selectedMat]) { materials[selectedMat].name = e.target.value; render(); }
      });
      document.getElementById('matColor').addEventListener('input', (e) => {
        if (materials[selectedMat]) { materials[selectedMat].color = e.target.value; render(); }
      });
      document.getElementById('friction').addEventListener('input', (e) => {
        const v = parseInt(e.target.value) / 100;
        document.getElementById('frictionVal').textContent = v.toFixed(2);
        if (materials[selectedMat]) materials[selectedMat].friction = v;
      });
      document.getElementById('restitution').addEventListener('input', (e) => {
        const v = parseInt(e.target.value) / 100;
        document.getElementById('restitutionVal').textContent = v.toFixed(2);
        if (materials[selectedMat]) { materials[selectedMat].restitution = v; resetBall(); }
      });
      document.getElementById('density').addEventListener('input', (e) => {
        const v = parseInt(e.target.value) / 10;
        document.getElementById('densityVal').textContent = v.toFixed(1);
        if (materials[selectedMat]) { materials[selectedMat].density = v; resetBall(); }
      });
      document.getElementById('collisionLayer').addEventListener('change', (e) => {
        if (materials[selectedMat]) materials[selectedMat].layer = parseInt(e.target.value);
      });

      document.getElementById('btnAdd').addEventListener('click', () => {
        materials.push({ name: 'New Material', friction: 0.5, restitution: 0.3, density: 1.0, layer: 0, color: '#888888' });
        selectedMat = materials.length - 1;
        render(); updateProps(); resetBall();
      });
      document.getElementById('btnDuplicate').addEventListener('click', () => {
        const src = materials[selectedMat];
        if (src) {
          materials.push({ ...src, name: src.name + ' Copy' });
          selectedMat = materials.length - 1;
          render(); updateProps();
        }
      });
      document.getElementById('btnRemove').addEventListener('click', () => {
        if (materials.length > 1) {
          materials.splice(selectedMat, 1);
          selectedMat = Math.min(selectedMat, materials.length - 1);
          render(); updateProps(); resetBall();
        }
      });

      document.getElementById('btnPresets').addEventListener('click', () => {
        materials = [
          { name:'Default', friction:0.5, restitution:0.3, density:1.0, layer:0, color:'#858585' },
          { name:'Ice', friction:0.05, restitution:0.1, density:0.9, layer:0, color:'#80d4ff' },
          { name:'Rubber', friction:0.9, restitution:0.8, density:1.2, layer:0, color:'#e06040' },
          { name:'Metal', friction:0.3, restitution:0.2, density:7.8, layer:1, color:'#a0a0a0' },
          { name:'Wood', friction:0.6, restitution:0.4, density:0.6, layer:0, color:'#b07040' },
          { name:'Bouncy Ball', friction:0.4, restitution:0.95, density:0.5, layer:0, color:'#ff6090' },
          { name:'Stone', friction:0.7, restitution:0.1, density:2.5, layer:1, color:'#707070' },
        ];
        selectedMat = 0;
        render(); updateProps(); resetBall();
      });

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  materials = {\\n';
        materials.forEach(m => {
          lua += '    { name = "' + m.name + '", friction = ' + m.friction.toFixed(2);
          lua += ', restitution = ' + m.restitution.toFixed(2);
          lua += ', density = ' + m.density.toFixed(1);
          lua += ', layer = ' + m.layer + ' },\\n';
        });
        lua += '  },\\n  collision_matrix = {\\n';
        for (let r = 0; r < NUM_LAYERS; r++) {
          lua += '    {' + collisionMatrix[r].map(v => v ? 'true' : 'false').join(', ') + '},\\n';
        }
        lua += '  }\\n}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      render();
      updateProps();
      animatePreview();
    `)}};var Yn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"lurek.worldMapEditor","World Map")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"world_map.lua");break}}getHtml(){let e=R();return D(e,"World Map",`
      .editor-layout {
        display: grid; grid-template-columns: 1fr 240px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: var(--bg); }
      .props-panel { grid-row: 2; }
      .status-bar { grid-column: 1 / -1; }
      .minimap {
        width: 100%; height: 120px; background: var(--bg); border: 1px solid var(--border);
        border-radius: 4px; margin-bottom: 8px;
      }
      .room-list { max-height: 200px; overflow-y: auto; }
      .room-item {
        display: flex; align-items: center; gap: 6px; padding: 4px 8px;
        cursor: pointer; border-radius: 3px; font-size: 12px;
      }
      .room-item:hover { background: var(--surface-2); }
      .room-item.selected { background: var(--selection); }
      .room-dot { width: 10px; height: 10px; border-radius: 2px; flex-shrink: 0; }
    `,`
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAddRoom">+ Room</button>
          <button id="btnRemoveRoom" class="danger">Remove Room</button>
          <div class="sep"></div>
          <button id="btnConnect" class="active">Connect Mode</button>
          <button id="btnMove">Move Mode</button>
          <div class="sep"></div>
          <input type="checkbox" id="snapGrid" checked><label for="snapGrid">Snap to Grid</label>
          <div class="sep"></div>
          <button id="btnZoomIn">+</button>
          <button id="btnZoomOut">-</button>
          <button id="btnFitAll">Fit All</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>

        <div class="canvas-area">
          <canvas id="mapCanvas"></canvas>
        </div>

        <div class="panel props-panel">
          <div class="section">
            <h3>Minimap</h3>
            <canvas class="minimap" id="minimap"></canvas>
          </div>
          <div class="section">
            <h3>Room Properties</h3>
            <div class="field"><label>Name</label><input type="text" id="roomName" style="width:100%"></div>
            <div class="field-row">
              <div class="field" style="flex:1"><label>Width</label><input type="number" id="roomW" min="40" max="400" value="120"></div>
              <div class="field" style="flex:1"><label>Height</label><input type="number" id="roomH" min="30" max="300" value="80"></div>
            </div>
            <div class="field"><label>Color</label><input type="color" id="roomColor" value="#2d5a88"></div>
            <div class="field"><label>Background</label><input type="text" id="roomBg" placeholder="bg_forest.png" style="width:100%"></div>
          </div>
          <div class="section">
            <h3>Rooms</h3>
            <div class="room-list" id="roomList"></div>
          </div>
          <div class="section">
            <h3>Connections</h3>
            <div id="connectionList" style="font-size:11px;max-height:100px;overflow-y:auto;"></div>
          </div>
        </div>

        <div class="status-bar">
          <span id="statusRooms">Rooms: 0</span>
          <span id="statusConnections">Connections: 0</span>
          <span id="statusMode">Mode: connect</span>
          <span id="statusPos">Pos: 0, 0</span>
        </div>
      </div>
    `,`
      const canvas = document.getElementById('mapCanvas');
      const ctx = canvas.getContext('2d');
      const miniCanvas = document.getElementById('minimap');
      const miniCtx = miniCanvas.getContext('2d');

      let rooms = [
        { id: 0, name: 'Entrance', x: 100, y: 200, w: 120, h: 80, color: '#2d5a88', bg: '' },
        { id: 1, name: 'Hallway', x: 300, y: 200, w: 140, h: 60, color: '#3a6b35', bg: '' },
        { id: 2, name: 'Boss Room', x: 520, y: 180, w: 160, h: 100, color: '#8b2500', bg: '' },
        { id: 3, name: 'Treasure', x: 300, y: 80, w: 100, h: 70, color: '#8b7500', bg: '' },
      ];
      let connections = [
        { from: 0, to: 1 },
        { from: 1, to: 2 },
        { from: 1, to: 3 },
      ];
      let nextId = 4;

      let selectedRoom = 0;
      let mode = 'connect'; // 'connect' or 'move'
      let snapGrid = true;
      let zoom = 1, offsetX = 0, offsetY = 0;
      let dragging = null; // { roomIdx, startX, startY, roomStartX, roomStartY }
      let connectFrom = -1;
      let isPanning = false, panStartX = 0, panStartY = 0;

      const GRID = 20;

      function snap(v) { return snapGrid ? Math.round(v / GRID) * GRID : v; }

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

        // Grid
        ctx.strokeStyle = '#1a1a1a';
        ctx.lineWidth = 0.5;
        for (let x = -1000; x < 2000; x += GRID) {
          ctx.beginPath(); ctx.moveTo(x, -1000); ctx.lineTo(x, 2000); ctx.stroke();
        }
        for (let y = -1000; y < 2000; y += GRID) {
          ctx.beginPath(); ctx.moveTo(-1000, y); ctx.lineTo(2000, y); ctx.stroke();
        }

        // Connections
        ctx.lineWidth = 2;
        connections.forEach(c => {
          const from = rooms.find(r => r.id === c.from);
          const to = rooms.find(r => r.id === c.to);
          if (!from || !to) return;
          const fx = from.x + from.w / 2, fy = from.y + from.h / 2;
          const tx = to.x + to.w / 2, ty = to.y + to.h / 2;
          ctx.strokeStyle = '#666';
          ctx.beginPath(); ctx.moveTo(fx, fy); ctx.lineTo(tx, ty); ctx.stroke();
          // Arrow head
          const angle = Math.atan2(ty - fy, tx - fx);
          const mx = (fx + tx) / 2, my = (fy + ty) / 2;
          ctx.fillStyle = '#666';
          ctx.beginPath();
          ctx.moveTo(mx + 8 * Math.cos(angle), my + 8 * Math.sin(angle));
          ctx.lineTo(mx + 8 * Math.cos(angle + 2.5), my + 8 * Math.sin(angle + 2.5));
          ctx.lineTo(mx + 8 * Math.cos(angle - 2.5), my + 8 * Math.sin(angle - 2.5));
          ctx.fill();
        });

        // Rooms
        rooms.forEach((room, i) => {
          ctx.fillStyle = room.color;
          ctx.globalAlpha = 0.7;
          ctx.fillRect(room.x, room.y, room.w, room.h);
          ctx.globalAlpha = 1;
          ctx.strokeStyle = i === selectedRoom ? '#fff' : '#888';
          ctx.lineWidth = i === selectedRoom ? 2 : 1;
          ctx.strokeRect(room.x, room.y, room.w, room.h);

          ctx.fillStyle = '#fff';
          ctx.font = '12px sans-serif';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillText(room.name, room.x + room.w / 2, room.y + room.h / 2);
        });

        ctx.restore();
        renderMinimap();
      }

      function renderMinimap() {
        miniCanvas.width = miniCanvas.clientWidth;
        miniCanvas.height = miniCanvas.clientHeight;
        miniCtx.clearRect(0, 0, miniCanvas.width, miniCanvas.height);
        if (rooms.length === 0) return;
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        rooms.forEach(r => {
          minX = Math.min(minX, r.x); minY = Math.min(minY, r.y);
          maxX = Math.max(maxX, r.x + r.w); maxY = Math.max(maxY, r.y + r.h);
        });
        const pad = 20;
        const w = maxX - minX + pad * 2, h = maxY - minY + pad * 2;
        const scale = Math.min(miniCanvas.width / w, miniCanvas.height / h);
        const ox = (miniCanvas.width - w * scale) / 2 - minX * scale + pad * scale;
        const oy = (miniCanvas.height - h * scale) / 2 - minY * scale + pad * scale;
        // Connections
        miniCtx.strokeStyle = '#555'; miniCtx.lineWidth = 1;
        connections.forEach(c => {
          const from = rooms.find(r => r.id === c.from);
          const to = rooms.find(r => r.id === c.to);
          if (!from || !to) return;
          miniCtx.beginPath();
          miniCtx.moveTo((from.x + from.w/2) * scale + ox, (from.y + from.h/2) * scale + oy);
          miniCtx.lineTo((to.x + to.w/2) * scale + ox, (to.y + to.h/2) * scale + oy);
          miniCtx.stroke();
        });
        rooms.forEach((r, i) => {
          miniCtx.fillStyle = r.color;
          miniCtx.globalAlpha = 0.8;
          miniCtx.fillRect(r.x * scale + ox, r.y * scale + oy, r.w * scale, r.h * scale);
          miniCtx.globalAlpha = 1;
          if (i === selectedRoom) {
            miniCtx.strokeStyle = '#fff'; miniCtx.lineWidth = 1.5;
            miniCtx.strokeRect(r.x * scale + ox, r.y * scale + oy, r.w * scale, r.h * scale);
          }
        });
      }

      function updateRoomList() {
        const list = document.getElementById('roomList');
        list.innerHTML = '';
        rooms.forEach((r, i) => {
          const el = document.createElement('div');
          el.className = 'room-item' + (i === selectedRoom ? ' selected' : '');
          el.innerHTML = '<div class="room-dot" style="background:' + r.color + '"></div><span>' + r.name + '</span>';
          el.addEventListener('click', () => { selectedRoom = i; render(); updateRoomList(); updateProps(); });
          list.appendChild(el);
        });
        const conns = document.getElementById('connectionList');
        conns.innerHTML = '';
        connections.forEach((c, ci) => {
          const from = rooms.find(r => r.id === c.from);
          const to = rooms.find(r => r.id === c.to);
          const el = document.createElement('div');
          el.style.padding = '2px 0';
          el.innerHTML = (from?.name || '?') + ' \\u2192 ' + (to?.name || '?') + ' <span style="cursor:pointer;color:var(--danger);" data-ci="' + ci + '">x</span>';
          el.querySelector('span').addEventListener('click', () => { connections.splice(ci, 1); render(); updateRoomList(); });
          conns.appendChild(el);
        });
        document.getElementById('statusRooms').textContent = 'Rooms: ' + rooms.length;
        document.getElementById('statusConnections').textContent = 'Connections: ' + connections.length;
      }

      function updateProps() {
        const r = rooms[selectedRoom];
        if (!r) return;
        document.getElementById('roomName').value = r.name;
        document.getElementById('roomW').value = r.w;
        document.getElementById('roomH').value = r.h;
        document.getElementById('roomColor').value = r.color;
        document.getElementById('roomBg').value = r.bg;
      }

      function screenToWorld(sx, sy) {
        return { x: (sx - offsetX) / zoom, y: (sy - offsetY) / zoom };
      }

      function findRoomAt(wx, wy) {
        for (let i = rooms.length - 1; i >= 0; i--) {
          const r = rooms[i];
          if (wx >= r.x && wx <= r.x + r.w && wy >= r.y && wy <= r.y + r.h) return i;
        }
        return -1;
      }

      canvas.addEventListener('mousedown', (e) => {
        const rect = canvas.getBoundingClientRect();
        const sx = e.clientX - rect.left, sy = e.clientY - rect.top;
        if (e.button === 1 || (e.button === 0 && e.altKey)) {
          isPanning = true; panStartX = sx - offsetX; panStartY = sy - offsetY; return;
        }
        const { x: wx, y: wy } = screenToWorld(sx, sy);
        const hit = findRoomAt(wx, wy);
        if (hit >= 0) {
          selectedRoom = hit;
          updateRoomList();
          updateProps();
          if (mode === 'move') {
            dragging = { roomIdx: hit, startX: sx, startY: sy, roomStartX: rooms[hit].x, roomStartY: rooms[hit].y };
          } else if (mode === 'connect') {
            connectFrom = hit;
          }
        }
        render();
      });

      canvas.addEventListener('mousemove', (e) => {
        const rect = canvas.getBoundingClientRect();
        const sx = e.clientX - rect.left, sy = e.clientY - rect.top;
        const { x: wx, y: wy } = screenToWorld(sx, sy);
        document.getElementById('statusPos').textContent = 'Pos: ' + Math.round(wx) + ', ' + Math.round(wy);
        if (isPanning) {
          offsetX = sx - panStartX; offsetY = sy - panStartY; render(); return;
        }
        if (dragging) {
          const dx = (sx - dragging.startX) / zoom;
          const dy = (sy - dragging.startY) / zoom;
          rooms[dragging.roomIdx].x = snap(dragging.roomStartX + dx);
          rooms[dragging.roomIdx].y = snap(dragging.roomStartY + dy);
          render();
        }
      });

      canvas.addEventListener('mouseup', (e) => {
        isPanning = false;
        if (dragging) { dragging = null; render(); updateRoomList(); return; }
        if (connectFrom >= 0 && mode === 'connect') {
          const rect = canvas.getBoundingClientRect();
          const { x: wx, y: wy } = screenToWorld(e.clientX - rect.left, e.clientY - rect.top);
          const hit = findRoomAt(wx, wy);
          if (hit >= 0 && hit !== connectFrom) {
            const exists = connections.some(c => c.from === rooms[connectFrom].id && c.to === rooms[hit].id);
            if (!exists) {
              connections.push({ from: rooms[connectFrom].id, to: rooms[hit].id });
              render(); updateRoomList();
            }
          }
          connectFrom = -1;
        }
      });

      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const zoomFactor = e.deltaY < 0 ? 1.1 : 0.9;
        zoom = Math.max(0.2, Math.min(3, zoom * zoomFactor));
        render();
      });

      document.getElementById('btnConnect').addEventListener('click', () => {
        mode = 'connect';
        document.getElementById('btnConnect').classList.add('active');
        document.getElementById('btnMove').classList.remove('active');
        document.getElementById('statusMode').textContent = 'Mode: connect';
      });
      document.getElementById('btnMove').addEventListener('click', () => {
        mode = 'move';
        document.getElementById('btnMove').classList.add('active');
        document.getElementById('btnConnect').classList.remove('active');
        document.getElementById('statusMode').textContent = 'Mode: move';
      });

      document.getElementById('snapGrid').addEventListener('change', (e) => { snapGrid = e.target.checked; });

      document.getElementById('btnZoomIn').addEventListener('click', () => { zoom = Math.min(3, zoom * 1.2); render(); });
      document.getElementById('btnZoomOut').addEventListener('click', () => { zoom = Math.max(0.2, zoom / 1.2); render(); });
      document.getElementById('btnFitAll').addEventListener('click', () => {
        if (rooms.length === 0) return;
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        rooms.forEach(r => { minX = Math.min(minX, r.x); minY = Math.min(minY, r.y); maxX = Math.max(maxX, r.x + r.w); maxY = Math.max(maxY, r.y + r.h); });
        const pad = 40;
        const w = maxX - minX + pad * 2, h = maxY - minY + pad * 2;
        zoom = Math.min(canvas.width / w, canvas.height / h);
        offsetX = -minX * zoom + pad * zoom;
        offsetY = -minY * zoom + pad * zoom;
        render();
      });

      document.getElementById('btnAddRoom').addEventListener('click', () => {
        const cx = (canvas.width / 2 - offsetX) / zoom;
        const cy = (canvas.height / 2 - offsetY) / zoom;
        rooms.push({ id: nextId++, name: 'Room ' + rooms.length, x: snap(cx), y: snap(cy), w: 120, h: 80, color: '#2d5a88', bg: '' });
        selectedRoom = rooms.length - 1;
        render(); updateRoomList(); updateProps();
      });
      document.getElementById('btnRemoveRoom').addEventListener('click', () => {
        if (rooms.length === 0) return;
        const rid = rooms[selectedRoom].id;
        rooms.splice(selectedRoom, 1);
        connections = connections.filter(c => c.from !== rid && c.to !== rid);
        selectedRoom = Math.min(selectedRoom, rooms.length - 1);
        render(); updateRoomList(); updateProps();
      });

      document.getElementById('roomName').addEventListener('change', (e) => {
        if (rooms[selectedRoom]) { rooms[selectedRoom].name = e.target.value; render(); updateRoomList(); }
      });
      document.getElementById('roomW').addEventListener('change', (e) => {
        if (rooms[selectedRoom]) { rooms[selectedRoom].w = parseInt(e.target.value); render(); }
      });
      document.getElementById('roomH').addEventListener('change', (e) => {
        if (rooms[selectedRoom]) { rooms[selectedRoom].h = parseInt(e.target.value); render(); }
      });
      document.getElementById('roomColor').addEventListener('input', (e) => {
        if (rooms[selectedRoom]) { rooms[selectedRoom].color = e.target.value; render(); updateRoomList(); }
      });
      document.getElementById('roomBg').addEventListener('change', (e) => {
        if (rooms[selectedRoom]) rooms[selectedRoom].bg = e.target.value;
      });

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  rooms = {\\n';
        rooms.forEach(r => {
          lua += '    { id = ' + r.id + ', name = "' + r.name + '", x = ' + r.x + ', y = ' + r.y;
          lua += ', w = ' + r.w + ', h = ' + r.h;
          if (r.bg) lua += ', background = "' + r.bg + '"';
          lua += ' },\\n';
        });
        lua += '  },\\n  connections = {\\n';
        connections.forEach(c => {
          const from = rooms.find(r => r.id === c.from);
          const to = rooms.find(r => r.id === c.to);
          lua += '    { from = "' + (from?.name||c.from) + '", to = "' + (to?.name||c.to) + '" },\\n';
        });
        lua += '  }\\n}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
      updateRoomList();
      updateProps();
    `)}};var Ad=[{id:"tileMap",open:n=>hn.open(n)},{id:"sceneFlow",open:n=>vn.open(n)},{id:"entity",open:n=>yn.open(n)},{id:"pixelArt",open:n=>bn.open(n)},{id:"particle",open:n=>xn.open(n)},{id:"dialog",open:n=>wn.open(n)},{id:"database",open:n=>kn.open(n)},{id:"procMap",open:n=>En.open(n)},{id:"questTree",open:n=>Cn.open(n)},{id:"guiWidget",open:n=>Tn.open(n)},{id:"aiBehavior",open:n=>In.open(n)},{id:"graph",open:n=>Pn.open(n)},{id:"tilemapScript",open:n=>Ln.open(n)},{id:"voxel",open:n=>Rn.open(n)},{id:"testRunner",open:n=>Dn.open(n)},{id:"apiReference",open:n=>Mn.open(n)},{id:"postfxOverlay",open:n=>An.open(n)},{id:"soundDsp",open:n=>Fn.open(n)},{id:"spriteAnim",open:n=>Bn.open(n)},{id:"tileset",open:n=>Nn.open(n)},{id:"audioMixer",open:n=>zn.open(n)},{id:"colorPalette",open:n=>_n.open(n)},{id:"inputMapper",open:n=>$n.open(n)},{id:"timeline",open:n=>On.open(n)},{id:"shaderPreview",open:n=>Wn.open(n)},{id:"fontPreview",open:n=>Hn.open(n)},{id:"localization",open:n=>jn.open(n)},{id:"physicsMaterials",open:n=>qn.open(n)},{id:"worldMap",open:n=>Yn.open(n)}];function Ta(n){return Ad.map(e=>Ca.commands.registerCommand(`lurek.editor.${e.id}`,()=>e.open(n)))}var W=E(require("vscode")),Gn=E(require("path")),Ie=E(require("fs"));Xt();async function Vn(){let n=W.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!n){W.window.showErrorMessage("No workspace folder open.");return}let e=Ve(n);if(!e||!Ie.existsSync(e)){W.window.showWarningMessage("API reference not found. Expected docs/API/lurek.lua or docs/API/lua-api.md.");return}let t=Ie.readFileSync(e,"utf-8"),o=Ds(t,e);if(o.length===0){W.window.showInformationMessage("No API entries found.");return}let s=await W.window.showQuickPick(o.map(i=>({label:i.label,description:i.kind,line:i.line})),{placeHolder:"Search Lurek2D API...",matchOnDescription:!0});if(s){let i=await W.workspace.openTextDocument(e),a=await W.window.showTextDocument(i),r=typeof s.line=="number"?s.line:go(t,e,s.label);if(r>=0){let l=new W.Position(r,0);a.selection=new W.Selection(l,l),a.revealRange(new W.Range(l,l))}}}async function Ia(){let n=W.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!n){W.window.showErrorMessage("No workspace folder open.");return}let e=Ve(n);if(!e||!Ie.existsSync(e)){W.window.showWarningMessage("API reference not found. Expected docs/API/lurek.lua or docs/API/lua-api.md.");return}let t=await W.workspace.openTextDocument(e);await W.window.showTextDocument(t)}async function Pa(){let n=W.window.activeTextEditor,e=n?.document.getWordRangeAtPosition(n.selection.active,/lurek\.[a-zA-Z0-9_.]+/),t=e?n.document.getText(e):void 0,o=W.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!o){W.window.showErrorMessage("No workspace folder open.");return}let s=Ve(o)??null;if(s){let i=Ie.readFileSync(s,"utf-8");if(t){let a=go(i,s,t),r=await W.workspace.openTextDocument(s),l=await W.window.showTextDocument(r),c=new W.Position(Math.max(0,a),0);l.selection=new W.Selection(c,c),l.revealRange(new W.Range(c,c),W.TextEditorRevealType.InCenter),a<0&&W.window.showInformationMessage(`"${t}" not found in API docs \u2014 showing full reference.`)}else{let a=await W.workspace.openTextDocument(s);await W.window.showTextDocument(a)}}else await Vn()}function qo(n){let e=W.workspace.workspaceFolders?.[0]?.uri.fsPath,t=W.window.createWebviewPanel("lurek.depGraph","Lurek2D Module Dependency Graph",W.ViewColumn.One,{enableScripts:!0,retainContextWhenHidden:!0}),o=[],s=[],i={math:"leaf",engine:"core",lua_api:"integration",window:"core",graphics:"domain",physics:"domain",audio:"domain",input:"domain",timer:"domain",filesystem:"domain",tilemap:"domain",sound:"domain",ai:"domain",compute:"domain",data:"domain",dataframe:"domain",entity:"domain",event:"domain",graph:"domain",image:"domain",modding:"domain",particle:"domain",savegame:"domain",scene:"domain",stats:"domain",thread:"domain",pathfinding:"domain",dialog:"domain",cardgame:"domain",combat:"domain",crafting:"domain",inventory:"domain",quest:"domain",resource:"domain"};if(e){let c=Gn.join(e,"src");if(Ie.existsSync(c)){let d=Ie.readdirSync(c,{withFileTypes:!0}).filter(u=>u.isDirectory()).map(u=>u.name);for(let u of d)o.push({id:u,tier:i[u]??"domain"});for(let u of d){let v=Gn.join(c,u,"mod.rs"),m=Gn.join(c,u,"lib.rs"),h=Ie.existsSync(v)?v:Ie.existsSync(m)?m:null;if(h)try{let p=[...Ie.readFileSync(h,"utf-8").matchAll(/use crate::([a-z_]+)/g)],g=new Set;for(let f of p){let b=f[1];b!==u&&d.includes(b)&&!g.has(b)&&(g.add(b),s.push({from:u,to:b}))}}catch{}}}}if(o.length===0){for(let[d,u]of Object.entries(i))o.push({id:d,tier:u});let c=[{from:"engine",to:"math"},{from:"graphics",to:"math"},{from:"physics",to:"math"},{from:"audio",to:"math"},{from:"input",to:"math"},{from:"timer",to:"math"},{from:"lua_api",to:"engine"},{from:"lua_api",to:"graphics"},{from:"lua_api",to:"physics"},{from:"lua_api",to:"audio"},{from:"lua_api",to:"input"},{from:"lua_api",to:"timer"},{from:"lua_api",to:"filesystem"},{from:"lua_api",to:"tilemap"},{from:"lua_api",to:"ai"},{from:"lua_api",to:"entity"},{from:"lua_api",to:"scene"},{from:"lua_api",to:"particle"}];s.push(...c)}let a=Fd(),r=JSON.stringify(o),l=JSON.stringify(s);t.webview.html=`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'nonce-${a}'; style-src 'nonce-${a}';">
<title>Module Dependency Graph</title>
<style nonce="${a}">
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
<script nonce="${a}">
const NODES = ${r};
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
</html>`}function La(){let n=W.window.createTerminal("Lurek2D Deps");n.show(),n.sendText("cargo tree --depth 1")}function Fd(){let n="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",e="";for(let t=0;t<32;t++)e+=n.charAt(Math.floor(Math.random()*n.length));return e}var K=E(require("vscode")),Pe=E(require("path")),ye=E(require("fs"));async function Ra(){let n=K.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!n){K.window.showErrorMessage("No workspace folder open.");return}let e=null,t=__dirname;for(let a=0;a<6;a++){let r=Pe.join(t,".github");if(ye.existsSync(r)){e=r;break}t=Pe.dirname(t)}if(!e){K.window.showErrorMessage("Could not locate engine .github/ folder. Make sure the extension is run from the lurek2d repository root.");return}let o=Pe.join(n,".github");if(ye.existsSync(o)&&await K.window.showWarningMessage(".github/ directory already exists in your workspace. Overwrite all CAG files?","Yes \u2014 Overwrite","Cancel")!=="Yes \u2014 Overwrite")return;let s=0;function i(a,r){ye.mkdirSync(r,{recursive:!0});for(let l of ye.readdirSync(a,{withFileTypes:!0})){let c=Pe.join(a,l.name),d=Pe.join(r,l.name);l.isDirectory()?i(c,d):(ye.copyFileSync(c,d),s++)}}try{i(e,o),K.window.showInformationMessage(`\u2705 CAG installed: ${s} file(s) copied to .github/`)}catch(a){K.window.showErrorMessage(`CAG install failed: ${a}`)}}async function Da(){let n=await Fa("agents","*.agent.md");if(n.length===0){K.window.showWarningMessage("No agent definitions found.");return}let e=await K.window.showQuickPick(n,{placeHolder:"Select an agent"});if(e){let t=K.workspace.workspaceFolders?.[0]?.uri.fsPath;if(t){let o=Pe.join(t,".github","agents",e);if(ye.existsSync(o)){let s=await K.workspace.openTextDocument(o);await K.window.showTextDocument(s)}}}}async function Ma(){let n=K.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!n){K.window.showErrorMessage("No workspace folder open.");return}let e=Pe.join(n,".github","skills");if(!ye.existsSync(e)){K.window.showWarningMessage("No skills directory found.");return}let t=ye.readdirSync(e,{withFileTypes:!0}).filter(s=>s.isDirectory()).map(s=>s.name);if(t.length===0){K.window.showWarningMessage("No skills found.");return}let o=await K.window.showQuickPick(t,{placeHolder:"Select a skill"});if(o){let s=Pe.join(e,o,"SKILL.md");if(ye.existsSync(s)){let i=await K.workspace.openTextDocument(s);await K.window.showTextDocument(i)}}}async function Aa(){let n=await Fa("prompts","*.prompt.md");if(n.length===0){K.window.showWarningMessage("No prompts found.");return}let e=await K.window.showQuickPick(n,{placeHolder:"Select a prompt"});if(e){let t=K.workspace.workspaceFolders?.[0]?.uri.fsPath;if(t){let o=Pe.join(t,".github","prompts",e);if(ye.existsSync(o)){let s=await K.workspace.openTextDocument(o);await K.window.showTextDocument(s)}}}}async function Fa(n,e){let t=K.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!t)return[];let o=Pe.join(t,".github",n);if(!ye.existsSync(o))return[];try{return ye.readdirSync(o,{withFileTypes:!0}).filter(s=>s.isFile()&&s.name.endsWith(".md")).map(s=>s.name)}catch{return[]}}var $=E(require("vscode")),ae=E(require("path")),ue=E(require("fs"));function Yo(n){let e=[],t=new Set,o=/lurek\.(\w+)\.(\w+)\s*\(/g;for(let[s,i]of n.split(`
`).entries()){let a;for(o.lastIndex=0;(a=o.exec(i))!==null;){let r=a[1],l=a[2],c=`${r}.${l}`;t.has(c)||(t.add(c),e.push({module:r,func:l,line:s+1,text:i.trim()}))}}return e}function Bd(n){let e=[],t=n.split(`
`),o=/^(?:local\s+)?function\s+([\w.:]+)\s*\(/;for(let s=0;s<t.length;s++){let i=o.exec(t[s]);if(i){let a=i[1],r=s,l=1,c=s+1;for(;c<t.length&&l>0;c++){let d=t[c].trim();/^(?:function|if|for|while|repeat)\b/.test(d)&&!d.endsWith("end")&&l++,/^end\b/.test(d)&&l--}e.push({name:a,line:r+1,endLine:c,body:t.slice(r,c).join(`
`)})}}return e}function Nd(n,e){let t=[`-- Auto-generated tests for ${n}`,"-- Generated by Lurek2D Toolkit","","local passed = 0","local failed = 0","local total = 0","","local function test(name, fn)","  total = total + 1","  local ok, err = pcall(fn)","  if ok then","    passed = passed + 1",'    print("[PASS] " .. name)',"  else","    failed = failed + 1",'    print("[FAIL] " .. name .. ": " .. tostring(err))',"  end","end",""],o=new Map;for(let s of e){let i=o.get(s.module)??[];i.push(s),o.set(s.module,i)}for(let[s,i]of o){t.push(`-- Tests for lurek.${s}`,"");for(let a of i)t.push(`test("lurek.${s}.${a.func} works", function()`,`  -- Source line ${a.line}: ${a.text}`,"  -- TODO: Add proper test assertion",`  local result = lurek.${s}.${a.func}()`,`  assert(result ~= nil, "lurek.${s}.${a.func} should return a value")`,"end)","")}return t.push("-- Summary",'print(string.format("\\n%d/%d tests passed (%d failed)", passed, total, failed))',"if failed > 0 then",'  error(string.format("%d tests failed", failed))',"end",""),t.join(`
`)}function zd(n,e,t){let o=Yo(t),s=[`-- Tests for function: ${e}`,`-- Source: ${n}`,"-- Generated by Lurek2D Toolkit","","local passed = 0","local failed = 0","local total = 0","","local function test(name, fn)","  total = total + 1","  local ok, err = pcall(fn)","  if ok then","    passed = passed + 1",'    print("[PASS] " .. name)',"  else","    failed = failed + 1",'    print("[FAIL] " .. name .. ": " .. tostring(err))',"  end","end","","-- Basic existence test",`test("${e} is defined", function()`,`  assert(type(${e}) == "function", "${e} should be a function")`,"end)","","-- Call test",`test("${e} can be called", function()`,"  -- TODO: Provide appropriate arguments",`  local ok, err = pcall(${e})`,"  -- Adjust based on expected behavior","end)",""];if(o.length>0){s.push("-- API dependency tests");for(let i of o)s.push(`test("${e} uses lurek.${i.module}.${i.func}", function()`,`  -- Verify lurek.${i.module}.${i.func} is available`,`  assert(type(lurek.${i.module}.${i.func}) == "function",`,`    "lurek.${i.module}.${i.func} should be available")`,"end)","")}return s.push("-- Summary",'print(string.format("\\n%d/%d tests passed (%d failed)", passed, total, failed))',"if failed > 0 then",'  error(string.format("%d tests failed", failed))',"end",""),s.join(`
`)}function $t(n){let e=ae.dirname(n);for(let t=0;t<10;t++){if(ue.existsSync(ae.join(e,"main.lua"))||ue.existsSync(ae.join(e,"conf.lua")))return e;let o=ae.dirname(e);if(o===e)break;e=o}return $.workspace.workspaceFolders?.[0]?.uri.fsPath}function Na(n){n.subscriptions.push($.commands.registerCommand("lurek.test.generateForFile",async()=>{let e=$.window.activeTextEditor;if(!e||e.document.languageId!=="lua"){$.window.showWarningMessage("Open a Lua file first.");return}let t=e.document,o=t.getText(),s=Yo(o);if(s.length===0){$.window.showInformationMessage("No lurek.* API calls detected in this file.");return}let i=ae.basename(t.fileName),a=$t(t.fileName);if(!a){$.window.showErrorMessage("Could not determine game root directory.");return}let r=ae.join(a,"tests");ue.existsSync(r)||ue.mkdirSync(r,{recursive:!0});let l=`test_${i}`,c=ae.join(r,l),d=Nd(i,s);ue.writeFileSync(c,d,"utf-8");let u=await $.workspace.openTextDocument(c);await $.window.showTextDocument(u),$.window.showInformationMessage(`Generated test file: tests/${l} (${s.length} API calls detected)`)})),n.subscriptions.push($.commands.registerCommand("lurek.test.generateForFunction",async()=>{let e=$.window.activeTextEditor;if(!e||e.document.languageId!=="lua"){$.window.showWarningMessage("Open a Lua file first.");return}let t=e.document,o=t.getText(),s=e.selection.active.line+1,a=Bd(o).find(y=>s>=y.line&&s<=y.endLine);if(!a){$.window.showWarningMessage("No function found at cursor position.");return}let r=ae.basename(t.fileName),l=$t(t.fileName);if(!l){$.window.showErrorMessage("Could not determine game root directory.");return}let c=ae.join(l,"tests");ue.existsSync(c)||ue.mkdirSync(c,{recursive:!0});let u=`test_${a.name.replace(/[.:]/g,"_")}.lua`,v=ae.join(c,u),m=zd(r,a.name,a.body);ue.writeFileSync(v,m,"utf-8");let h=await $.workspace.openTextDocument(v);await $.window.showTextDocument(h),$.window.showInformationMessage(`Generated test file: tests/${u} for ${a.name}()`)})),n.subscriptions.push($.commands.registerCommand("lurek.test.runCurrent",async()=>{let e=$.window.activeTextEditor;if(!e||e.document.languageId!=="lua"){$.window.showWarningMessage("Open a Lua test file first.");return}let t=e.document.fileName,o=$t(t);if(!o){$.window.showErrorMessage("Could not determine game root directory.");return}let s=$.workspace.getConfiguration("lurek").get("enginePath","lurek2d"),i=Ba("Lurek2D Tests");i.show();let a=ae.relative(o,t).replace(/\\/g,"/");i.sendText(`cd "${o}" && "${s}" --test "${a}"`)})),n.subscriptions.push($.commands.registerCommand("lurek.test.runAll",async()=>{let e=$.window.activeTextEditor,t=e?$t(e.document.fileName):$.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!t){$.window.showErrorMessage("No game project found.");return}let o=ae.join(t,"tests");if(!ue.existsSync(o)){$.window.showWarningMessage("No tests/ directory found in the game project.");return}let s=ue.readdirSync(o).filter(l=>l.endsWith(".lua"));if(s.length===0){$.window.showWarningMessage("No Lua test files found in tests/.");return}let i=$.window.createOutputChannel("Lurek2D Test Results");i.show(),i.appendLine(`Running ${s.length} test file(s)...`),i.appendLine("\u2500".repeat(50));let a=$.workspace.getConfiguration("lurek").get("enginePath","lurek2d"),r=Ba("Lurek2D Tests");r.show();for(let l of s)i.appendLine(`
Running: ${l}`),r.sendText(`cd "${t}" && "${a}" --test "tests/${l}"`);i.appendLine(`
`+"\u2500".repeat(50)),i.appendLine(`Queued ${s.length} test files.`)})),n.subscriptions.push($.commands.registerCommand("lurek.test.coverage",async()=>{let e=$.window.activeTextEditor,t=e?$t(e.document.fileName):$.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!t){$.window.showErrorMessage("No game project found.");return}let o=za(t),s=new Set,i=new Set;for(let l of o){let c=ue.readFileSync(l,"utf-8"),d=Yo(c),u=l.includes(`${ae.sep}tests${ae.sep}`)||ae.basename(l).startsWith("test_");for(let v of d){let m=`lurek.${v.module}.${v.func}`;s.add(m),u&&i.add(m)}}let a=$.window.createOutputChannel("Lurek2D API Coverage");a.show(),a.appendLine("Lurek2D API Coverage Report"),a.appendLine("\u2550".repeat(50)),a.appendLine(`Total API calls used: ${s.size}`),a.appendLine(`Covered by tests:     ${i.size}`);let r=s.size>0?Math.round(i.size/s.size*100):0;if(a.appendLine(`Coverage:             ${r}%`),a.appendLine(""),s.size>i.size){a.appendLine("Untested API calls:");for(let l of[...s].sort())i.has(l)||a.appendLine(`  \u26A0 ${l}`)}a.appendLine(""),a.appendLine("Tested API calls:");for(let l of[...i].sort())a.appendLine(`  \u2713 ${l}`)}))}function za(n,e=[]){if(!ue.existsSync(n))return e;let t=ue.readdirSync(n,{withFileTypes:!0});for(let o of t){let s=ae.join(n,o.name);o.isDirectory()&&o.name!=="node_modules"&&o.name!==".git"?za(s,e):o.isFile()&&o.name.endsWith(".lua")&&e.push(s)}return e}function Ba(n){let e=$.window.terminals.find(t=>t.name===n);return e||$.window.createTerminal(n)}Go();var H=E(require("vscode"));function Wa(n,e){n.subscriptions.push(H.commands.registerCommand("lurek.debug.connect",async()=>{if(e.isConnected){H.window.showInformationMessage("Already connected to Lurek2D engine.");return}let t=await H.window.showInputBox({prompt:"Debug bridge port",value:String(H.workspace.getConfiguration("lurek.debugBridge").get("port",19740)),validateInput:s=>{let i=Number(s);if(isNaN(i)||i<1024||i>65535)return"Port must be 1024\u201365535"}});if(t===void 0)return;e.showOutput(),await e.connect(Number(t))?(H.window.showInformationMessage("Connected to Lurek2D engine."),H.commands.executeCommand("setContext","lurek.debugConnected",!0)):H.window.showErrorMessage("Failed to connect. Is the engine running with debug bridge enabled?")})),n.subscriptions.push(H.commands.registerCommand("lurek.debug.disconnect",()=>{e.disconnect(),H.commands.executeCommand("setContext","lurek.debugConnected",!1),H.window.showInformationMessage("Disconnected from Lurek2D engine.")})),n.subscriptions.push(H.commands.registerCommand("lurek.debug.evaluate",async()=>{if(!e.isConnected){H.window.showErrorMessage("Not connected to Lurek2D engine. Run 'Lurek2D: Debug Connect' first.");return}let t=await H.window.showInputBox({prompt:"Lua expression to evaluate",placeHolder:'e.g. print("hello") or player.x'});if(t)try{let o=await e.evaluate(t);e.showOutput(),H.window.showInformationMessage(`Result: ${o}`)}catch(o){H.window.showErrorMessage(`Evaluation failed: ${o instanceof Error?o.message:String(o)}`)}})),n.subscriptions.push(H.commands.registerCommand("lurek.debug.hotReload",async()=>{if(!e.isConnected){H.window.showErrorMessage("Not connected to Lurek2D engine.");return}let t=H.window.activeTextEditor;if(!t||t.document.languageId!=="lua"){H.window.showWarningMessage("Open a Lua file to hot-reload.");return}t.document.isDirty&&await t.document.save();try{await e.hotReload(t.document.uri)?H.window.showInformationMessage(`Hot-reloaded: ${H.workspace.asRelativePath(t.document.uri)}`):H.window.showErrorMessage("Hot-reload failed. Check debug output for details.")}catch(o){H.window.showErrorMessage(`Hot-reload error: ${o instanceof Error?o.message:String(o)}`)}})),n.subscriptions.push(H.commands.registerCommand("lurek.debug.showStats",async()=>{if(!e.isConnected){H.window.showErrorMessage("Not connected to Lurek2D engine.");return}e.startStatsPolling(),H.window.showInformationMessage("Engine stats enabled in status bar.")})),n.subscriptions.push(H.commands.registerCommand("lurek.debug.inspect",async()=>{if(!e.isConnected){H.window.showErrorMessage("Not connected to Lurek2D engine.");return}let t=H.window.activeTextEditor;if(!t){H.window.showWarningMessage("No active editor.");return}let o=t.selection,s;if(!o.isEmpty)s=t.document.getText(o);else{let i=t.document.getWordRangeAtPosition(o.active,/[\w.:\[\]]+/);if(!i){H.window.showWarningMessage("No variable found at cursor.");return}s=t.document.getText(i)}try{let i=await e.evaluate(`return tostring(${s})`),a=await e.evaluate(`return type(${s})`);H.window.showInformationMessage(`${s} = ${i} (${a})`)}catch(i){H.window.showErrorMessage(`Failed to inspect '${s}': ${i instanceof Error?i.message:String(i)}`)}}))}var j=E(require("vscode")),Ae=E(require("path")),re=E(require("fs")),Od=[{label:"Platformer",description:"Side-scrolling platformer with jump physics",confLua:`function lurek.conf(t)
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
  if lurek.keyboard.isDown("left") or lurek.keyboard.isDown("a") then
    player.x = player.x - player.speed * dt
  end
  if lurek.keyboard.isDown("right") or lurek.keyboard.isDown("d") then
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

  if lurek.keyboard.isDown("up") or lurek.keyboard.isDown("w") then
    dy = -1
    player.dir = "up"
  elseif lurek.keyboard.isDown("down") or lurek.keyboard.isDown("s") then
    dy = 1
    player.dir = "down"
  end

  if lurek.keyboard.isDown("left") or lurek.keyboard.isDown("a") then
    dx = -1
    player.dir = "left"
  elseif lurek.keyboard.isDown("right") or lurek.keyboard.isDown("d") then
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
  if lurek.keyboard.isDown("left") or lurek.keyboard.isDown("a") then
    player.x = player.x - player.speed * dt
  end
  if lurek.keyboard.isDown("right") or lurek.keyboard.isDown("d") then
    player.x = player.x + player.speed * dt
  end
  player.x = math.max(0, math.min(player.x, 800 - player.w))

  -- Shooting
  shoot_timer = shoot_timer - dt
  if lurek.keyboard.isDown("space") and shoot_timer <= 0 then
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
  local mx, my = lurek.mouse.getPosition()
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
`}],Wd=[{label:"Camera",description:"Smooth follow camera with zoom and shake",patternFile:"camera.lua",requireLine:'local Camera = require("libs.camera")'},{label:"Tilemap",description:"Tile-based map rendering and collision",patternFile:"grid.lua",requireLine:'local Grid = require("libs.grid")'},{label:"Physics",description:"Simple physics wrappers",patternFile:"component-system.lua",requireLine:'local ECS = require("libs.component-system")'},{label:"UI",description:"Basic UI components",patternFile:"stack.lua",requireLine:'local Stack = require("libs.stack")'},{label:"Particles",description:"Particle effects system",patternFile:"timer.lua",requireLine:'local Timer = require("libs.timer")'},{label:"Save/Load",description:"Game state serialization",patternFile:"class.lua",requireLine:'local Class = require("libs.class")'},{label:"Sound Manager",description:"Audio management with fade and crossfade",patternFile:"event-bus.lua",requireLine:'local EventBus = require("libs.event-bus")'},{label:"State Machine",description:"Finite state machine for game states",patternFile:"fsm.lua",requireLine:'local FSM = require("libs.fsm")'},{label:"Signal",description:"Pub-sub signal / observer pattern",patternFile:"signal.lua",requireLine:'local Signal = require("libs.signal")'},{label:"Tween",description:"Property tweening / animation engine",patternFile:"tween.lua",requireLine:'local Tween = require("libs.tween")'},{label:"Object Pool",description:"Recycling pool for bullets/particles/etc.",patternFile:"object-pool.lua",requireLine:'local Pool = require("libs.object-pool")'}],Xn,Fe,Un;function Hd(n){Kn(),Un=Date.now()+n*6e4,Fe=j.window.createStatusBarItem(j.StatusBarAlignment.Right,200),Fe.show();let e=n*6e4,t=!1,o=!1,s=!1,i=()=>{if(!Un||!Fe)return;let a=Un-Date.now();if(a<=0){Fe.text="$(bell) TIME'S UP!",Fe.backgroundColor=new j.ThemeColor("statusBarItem.errorBackground"),j.window.showWarningMessage("Game Jam Timer: Time's up!"),Kn();return}let r=a/e,l=Math.floor(a/6e4),c=Math.floor(a%6e4/1e3);Fe.text=`$(clock) ${l}:${String(c).padStart(2,"0")} remaining`,r<=.1&&!s?(s=!0,Fe.backgroundColor=new j.ThemeColor("statusBarItem.errorBackground"),j.window.showWarningMessage("Game Jam Timer: 10% time remaining!")):r<=.25&&!o?(o=!0,Fe.backgroundColor=new j.ThemeColor("statusBarItem.warningBackground"),j.window.showWarningMessage("Game Jam Timer: 25% time remaining!")):r<=.5&&!t&&(t=!0,j.window.showInformationMessage("Game Jam Timer: 50% time remaining."))};i(),Xn=setInterval(i,1e3)}function Kn(){Xn&&(clearInterval(Xn),Xn=void 0),Fe&&(Fe.dispose(),Fe=void 0),Un=void 0}function Ha(n){n.subscriptions.push(j.commands.registerCommand("lurek.gameJam.quickStart",async()=>{let e=await j.window.showQuickPick(Od.map(r=>({label:r.label,description:r.description,template:r})),{placeHolder:"Choose a game template"});if(!e)return;let t=await j.window.showInputBox({prompt:"Project name",placeHolder:"my-game",validateInput:r=>{if(!r.trim())return"Name cannot be empty";if(/[<>:"/\\|?*]/.test(r))return"Name contains invalid characters"}});if(!t)return;let o=await j.window.showOpenDialog({canSelectFolders:!0,canSelectFiles:!1,canSelectMany:!1,openLabel:"Select parent folder"});if(!o||o.length===0)return;let s=Ae.join(o[0].fsPath,t);if(re.existsSync(s)){j.window.showErrorMessage(`Folder already exists: ${s}`);return}let i=e.template;re.mkdirSync(s,{recursive:!0}),re.mkdirSync(Ae.join(s,"assets"),{recursive:!0}),re.mkdirSync(Ae.join(s,"libs"),{recursive:!0}),re.writeFileSync(Ae.join(s,"conf.lua"),i.confLua,"utf-8"),re.writeFileSync(Ae.join(s,"main.lua"),i.mainLua,"utf-8"),re.writeFileSync(Ae.join(s,"assets","README.md"),`# Assets

Place your game assets (images, sounds, fonts) in this folder.
`,"utf-8");let a=j.Uri.file(s);await j.commands.executeCommand("vscode.openFolder",a),j.window.showInformationMessage(`Created "${t}" with ${i.label} template!`)})),n.subscriptions.push(j.commands.registerCommand("lurek.gameJam.addModule",async()=>{let e=await j.window.showQuickPick(Wd.map(l=>({label:l.label,description:l.description,module:l})),{placeHolder:"Choose a module to add"});if(!e)return;let t=j.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!t){j.window.showErrorMessage("No workspace folder open.");return}let o=e.module,s=Ae.join(t,"libs");re.existsSync(s)||re.mkdirSync(s,{recursive:!0});let i=Ae.join(s,o.patternFile);if(re.existsSync(i)&&await j.window.showWarningMessage(`libs/${o.patternFile} already exists. Overwrite?`,"Yes","No")!=="Yes")return;let a=Ae.join(n.extensionPath,"data","patterns",o.patternFile);if(!re.existsSync(a)){j.window.showErrorMessage(`Pattern file not found: ${o.patternFile}`);return}re.copyFileSync(a,i);let r=Ae.join(t,"main.lua");if(re.existsSync(r)){let l=re.readFileSync(r,"utf-8");if(!l.includes(o.requireLine)){let c=l.split(`
`),d=0;for(let u=0;u<c.length;u++)c[u].startsWith("local ")&&c[u].includes("require")&&(d=u+1);c.splice(d,0,o.requireLine),re.writeFileSync(r,c.join(`
`),"utf-8")}}j.window.showInformationMessage(`Added ${o.label} module to libs/${o.patternFile}`)})),n.subscriptions.push(j.commands.registerCommand("lurek.gameJam.timer",async()=>{let e=await j.window.showQuickPick([{label:"30 minutes",minutes:30},{label:"1 hour",minutes:60},{label:"2 hours",minutes:120},{label:"Custom...",minutes:-1},{label:"Stop timer",minutes:0}],{placeHolder:"Game Jam countdown duration"});if(!e)return;if(e.minutes===0){Kn(),j.window.showInformationMessage("Game Jam Timer stopped.");return}let t=e.minutes;if(t<0){let o=await j.window.showInputBox({prompt:"Duration in minutes",placeHolder:"90",validateInput:s=>{let i=Number(s);if(isNaN(i)||i<=0)return"Enter a positive number"}});if(!o)return;t=Number(o)}Hd(t),j.window.showInformationMessage(`Game Jam Timer started: ${t} minutes.`)})),n.subscriptions.push({dispose:Kn})}var U=E(require("vscode")),pt=E(require("path")),xe=E(require("fs")),ja=[{label:"Draw sprite",category:"Graphics",code:`local img = lurek.graphics.newImage("assets/sprite.png")

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
  if lurek.keyboard.isDown("w") or lurek.keyboard.isDown("up") then
    player.y = player.y - player.speed * dt
  end
  if lurek.keyboard.isDown("s") or lurek.keyboard.isDown("down") then
    player.y = player.y + player.speed * dt
  end
  if lurek.keyboard.isDown("a") or lurek.keyboard.isDown("left") then
    player.x = player.x - player.speed * dt
  end
  if lurek.keyboard.isDown("d") or lurek.keyboard.isDown("right") then
    player.x = player.x + player.speed * dt
  end
end`},{label:"Mouse aim",category:"Input",code:`local player = { x = 400, y = 300, angle = 0 }

function lurek.update(dt)
  local mx, my = lurek.mouse.getPosition()
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
  local axes = lurek.gamepad.getAxes(1)
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
  if lurek.keyboard.isDown("left") then player.vx = -moveSpeed
  elseif lurek.keyboard.isDown("right") then player.vx = moveSpeed
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
  if lurek.keyboard.isDown("w") then iy = iy - 1 end
  if lurek.keyboard.isDown("s") then iy = iy + 1 end
  if lurek.keyboard.isDown("a") then ix = ix - 1 end
  if lurek.keyboard.isDown("d") then ix = ix + 1 end

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
end`}];function jd(){let n=new Set;for(let e of ja)n.add(e.category);return[...n].sort()}function qd(n){let e=pt.join(n,"data","patterns");return xe.existsSync(e)?xe.readdirSync(e).filter(t=>t.endsWith(".lua")).map(t=>({name:t.replace(".lua",""),fullPath:pt.join(e,t)})):[]}function qa(n){n.subscriptions.push(U.commands.registerCommand("lurek.library.browse",async()=>{let e=qd(n.extensionPath);if(e.length===0){U.window.showInformationMessage("No patterns found in data/patterns/.");return}let t=await U.window.showQuickPick(e.map(s=>({label:s.name,description:`data/patterns/${s.name}.lua`,fullPath:s.fullPath})),{placeHolder:"Browse Lurek2D patterns"});if(!t)return;let o=await U.window.showQuickPick([{label:"Preview",description:"Open the pattern file in a new tab"},{label:"Copy to project",description:"Copy to libs/ folder in your project"}],{placeHolder:`${t.label}: What would you like to do?`});if(o)if(o.label==="Preview"){let s=await U.workspace.openTextDocument(t.fullPath);await U.window.showTextDocument(s,{preview:!0})}else{let s=U.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!s){U.window.showErrorMessage("No workspace folder open.");return}let i=pt.join(s,"libs");xe.existsSync(i)||xe.mkdirSync(i,{recursive:!0});let a=pt.join(i,`${t.label}.lua`);if(xe.existsSync(a)&&await U.window.showWarningMessage(`libs/${t.label}.lua already exists. Overwrite?`,"Yes","No")!=="Yes")return;xe.copyFileSync(t.fullPath,a),U.window.showInformationMessage(`Copied ${t.label} to libs/${t.label}.lua`)}})),n.subscriptions.push(U.commands.registerCommand("lurek.library.insertSnippet",async()=>{let e=jd(),t=await U.window.showQuickPick(e.map(a=>({label:a})),{placeHolder:"Choose snippet category"});if(!t)return;let o=ja.filter(a=>a.category===t.label),s=await U.window.showQuickPick(o.map(a=>({label:a.label,snippet:a})),{placeHolder:`${t.label} snippets`});if(!s)return;let i=U.window.activeTextEditor;if(!i){let a=await U.workspace.openTextDocument({language:"lua",content:s.snippet.code+`
`});await U.window.showTextDocument(a);return}await i.edit(a=>{a.insert(i.selection.active,s.snippet.code+`
`)})})),n.subscriptions.push(U.commands.registerCommand("lurek.library.newPattern",async()=>{let e=U.window.activeTextEditor;if(!e||e.selection.isEmpty){U.window.showWarningMessage("Select some Lua code first to create a pattern from it.");return}let t=e.document.getText(e.selection),o=await U.window.showInputBox({prompt:"Pattern name",placeHolder:"my-pattern",validateInput:c=>{if(!c.trim())return"Name cannot be empty";if(/[<>:"/\\|?*\s]/.test(c))return"Name should be a simple identifier (use dashes, no spaces)"}});if(!o)return;let s=await U.window.showInputBox({prompt:"Category",placeHolder:"e.g. gameplay, ui, utility"}),i=await U.window.showInputBox({prompt:"Brief description",placeHolder:"What does this pattern do?"}),a=[`--- ${o} pattern for Lurek2D.`,`--- ${i??"Custom pattern."}`,"---",`--- Category: ${s??"general"}`,"---",""].join(`
`),r=pt.join(n.extensionPath,"data","patterns");xe.existsSync(r)||xe.mkdirSync(r,{recursive:!0});let l=pt.join(r,`${o}.lua`);xe.existsSync(l)&&await U.window.showWarningMessage(`Pattern "${o}" already exists. Overwrite?`,"Yes","No")!=="Yes"||(xe.writeFileSync(l,a+t+`
`,"utf-8"),U.window.showInformationMessage(`Pattern "${o}" saved to data/patterns/${o}.lua`))}))}var te=E(require("vscode")),we=E(require("path")),pe=E(require("fs")),Ya=[{label:"Agents",description:"AI agent definitions for game dev roles",srcDir:"agents"},{label:"Skills",description:"Domain skill packages for AI assistants",srcDir:"skills"},{label:"Prompts",description:"Task-driven playbooks for game development",srcDir:"prompts"},{label:"Instructions",description:"Contextual coding instructions",srcDir:"instructions"}],Yd=[{label:"Minimal",description:"Bare-bones starter with essential callbacks",dir:"minimal"},{label:"Game Loop",description:"Structured loop with class system and event bus",dir:"game-loop"},{label:"Platformer",description:"Side-scrolling platformer with jump physics",dir:"platformer"},{label:"Top-Down RPG",description:"8-dir movement, scene management, HUD",dir:"top-down-rpg"},{label:"Shoot 'em Up",description:"Vertical scrolling shooter with bullet pool",dir:"shoot-em-up"},{label:"Puzzle",description:"Grid-based puzzle with click interaction",dir:"puzzle"},{label:"Roguelike",description:"Turn-based with BSP dungeon generation",dir:"roguelike"},{label:"Visual Novel",description:"Typewriter dialog and scene progression",dir:"visual-novel"},{label:"Arcade",description:"Simple arcade loop with score and lives",dir:"arcade"},{label:"Tower Defense",description:"Path-following enemies, placeable towers, waves",dir:"tower-defense"},{label:"Game Jam",description:"Minimal fast-start template for game jams",dir:"game-jam"},{label:"Demo Scene",description:"Scene switcher with multiple demo scenes",dir:"demo-scene"}];function Vo(n){return we.join(n.extensionPath,"cag","game-dev")}function Xo(){return te.workspace.workspaceFolders?.[0]?.uri.fsPath}function Jn(n,e){pe.existsSync(e)||pe.mkdirSync(e,{recursive:!0});for(let t of pe.readdirSync(n,{withFileTypes:!0})){let o=we.join(n,t.name),s=we.join(e,t.name);t.isDirectory()?Jn(o,s):pe.copyFileSync(o,s)}}function Zn(n){if(!pe.existsSync(n))return 0;let e=0;for(let t of pe.readdirSync(n,{withFileTypes:!0}))t.isDirectory()?e+=Zn(we.join(n,t.name)):e++;return e}async function Gd(n){let e=Xo();if(!e){te.window.showErrorMessage("No workspace folder open.");return}let t=Vo(n);if(!pe.existsSync(t)){te.window.showErrorMessage("Game Dev CAG files not found in extension bundle.");return}let o=await te.window.showQuickPick(Ya.map(a=>({label:a.label,description:a.description,picked:!0,srcDir:a.srcDir})),{canPickMany:!0,placeHolder:"Select CAG components to deploy",title:"Deploy Game Dev AI Layer"});if(!o||o.length===0)return;let s=we.join(e,".github"),i=0;for(let a of o){let r=we.join(t,a.srcDir);if(!pe.existsSync(r))continue;let l=we.join(s,a.srcDir);Jn(r,l),i+=Zn(r)}te.window.showInformationMessage(`Deployed ${i} file(s) to .github/ (${o.map(a=>a.label).join(", ")})`)}async function Vd(n){let e=Xo();if(!e){te.window.showErrorMessage("No workspace folder open.");return}let t=Vo(n),o=we.join(t,"templates");if(!pe.existsSync(o)){te.window.showErrorMessage("Game Dev templates not found in extension bundle.");return}let s=await te.window.showQuickPick(Yd.map(c=>({label:c.label,description:c.description,dir:c.dir})),{placeHolder:"Select a game template",title:"Scaffold Project from Template"});if(!s)return;let i=we.join(o,s.dir);if(!pe.existsSync(i)){te.window.showErrorMessage(`Template "${s.label}" not found.`);return}let a=we.join(e,"main.lua");if(pe.existsSync(a)&&await te.window.showWarningMessage("main.lua already exists in workspace. Overwrite project files?","Yes","No")!=="Yes")return;Jn(i,e);let r=Zn(i);te.window.showInformationMessage(`Scaffolded "${s.label}" template (${r} files)`);let l=we.join(e,"main.lua");if(pe.existsSync(l)){let c=await te.workspace.openTextDocument(l);await te.window.showTextDocument(c)}}async function Xd(n){let e=Xo();if(!e){te.window.showErrorMessage("No workspace folder open.");return}let t=we.join(e,".github");if(!pe.existsSync(t)){te.window.showInformationMessage("No .github/ folder found. Use 'Deploy Game Dev AI Layer' first.");return}if(await te.window.showWarningMessage("This will overwrite existing CAG files in .github/ with the latest from the extension. Continue?","Yes","No")!=="Yes")return;let s=Vo(n),i=0;for(let a of Ya){let r=we.join(s,a.srcDir);if(!pe.existsSync(r))continue;let l=we.join(t,a.srcDir);Jn(r,l),i+=Zn(r)}te.window.showInformationMessage(`Updated ${i} CAG file(s) in .github/`)}function Ga(n){n.subscriptions.push(te.commands.registerCommand("lurek.cag.deploy",()=>Gd(n)),te.commands.registerCommand("lurek.cag.scaffold",()=>Vd(n)),te.commands.registerCommand("lurek.cag.updateGameDev",()=>Xd(n)))}var Be=E(require("vscode"));var O=E(ar()),dr=E(require("net")),oe=E(require("path")),ur=require("child_process"),Et=E(require("fs")),rr=1,lr=5,cr=800,Ts=8172,po=class extends O.LoggingDebugSession{socket=null;engineProcess=null;breakpoints=new Map;variablesMap=new Map;nextVariableRef=1;pendingRequests=new Map;nextRequestId=1;receiveBuffer="";gamePath="";debugPort=Ts;loadedSources=[];constructor(){super("lurek-debug.log"),this.setDebuggerLinesStartAt1(!0),this.setDebuggerColumnsStartAt1(!0)}initializeRequest(e,t){e.body={supportsConfigurationDoneRequest:!0,supportsFunctionBreakpoints:!1,supportsConditionalBreakpoints:!0,supportsHitConditionalBreakpoints:!0,supportsEvaluateForHovers:!0,supportsStepBack:!1,supportsSetVariable:!0,supportsRestartFrame:!1,supportsGotoTargetsRequest:!1,supportsStepInTargetsRequest:!1,supportsCompletionsRequest:!0,supportsModulesRequest:!1,supportsExceptionOptions:!1,supportsValueFormattingOptions:!1,supportsExceptionInfoRequest:!1,supportTerminateDebuggee:!0,supportsDelayedStackTraceLoading:!1,supportsLoadedSourcesRequest:!0,supportsLogPoints:!0,supportsTerminateThreadsRequest:!1,supportsSetExpression:!1,supportsTerminateRequest:!0,supportsDataBreakpoints:!1,supportsReadMemoryRequest:!1,supportsDisassembleRequest:!1,supportsBreakpointLocationsRequest:!0,supportsClipboardContext:!1,supportsExceptionFilterOptions:!1,supportsSteppingGranularity:!1,supportsInstructionBreakpoints:!1},this.sendResponse(e),this.sendEvent(new O.InitializedEvent)}async launchRequest(e,t){this.gamePath=t.program,this.debugPort=t.debugPort??Ts;let o=t.stopOnEntry??!1,s=this.findEngineBinary(t.enginePath);if(!s){this.sendErrorResponse(e,1001,"Lurek2D engine not found. Set 'lurek.enginePath' in settings or ensure lurek2d is on PATH.");return}let i=[`--debug-port=${this.debugPort}`,this.gamePath,...t.args??[]];this.log(`Launching: ${s} ${i.join(" ")}`);try{this.engineProcess=(0,ur.spawn)(s,i,{cwd:oe.dirname(this.gamePath),stdio:["ignore","pipe","pipe"]}),this.engineProcess.stdout?.on("data",a=>{this.sendEvent(new O.OutputEvent(a.toString(),"stdout"))}),this.engineProcess.stderr?.on("data",a=>{this.sendEvent(new O.OutputEvent(a.toString(),"stderr"))}),this.engineProcess.on("exit",a=>{this.log(`Engine exited with code ${a}`),this.sendEvent(new O.TerminatedEvent)}),this.engineProcess.on("error",a=>{this.sendEvent(new O.OutputEvent(`Engine error: ${a.message}
`,"stderr")),this.sendEvent(new O.TerminatedEvent)}),await this.connectToEngine(this.debugPort),o&&await this.sendToEngine("pause"),this.sendResponse(e)}catch(a){let r=a instanceof Error?a.message:String(a);this.sendErrorResponse(e,1002,`Failed to launch: ${r}`)}}async attachRequest(e,t){this.debugPort=t.debugPort??Ts;try{await this.connectToEngine(this.debugPort),this.sendResponse(e)}catch(o){let s=o instanceof Error?o.message:String(o);this.sendErrorResponse(e,1003,`Failed to attach: ${s}`)}}configurationDoneRequest(e,t){this.sendResponse(e)}async disconnectRequest(e,t){if(t.terminateDebuggee!==!1&&this.engineProcess)try{await this.sendToEngine("terminate")}catch{}this.cleanup(),this.sendResponse(e)}async terminateRequest(e,t){try{await this.sendToEngine("terminate")}catch{}this.cleanup(),this.sendResponse(e)}async setBreakPointsRequest(e,t){let o=t.source.path??"",s=t.lines??[],i=this.toRelativePath(o);try{let a=await this.sendToEngine("setBreakpoints",{file:i,lines:s}),r=s.map((l,c)=>{let d=new O.Breakpoint(!0,l);if(d.id=c+1,a.body&&Array.isArray(a.body.breakpoints)){let u=a.body.breakpoints[c];u&&(d.verified=u.verified,u.line!==void 0&&(d.line=u.line))}return d});this.breakpoints.set(o,r),this.loadedSources.find(l=>l.path===o)||this.loadedSources.push(new O.Source(oe.basename(o),o)),e.body={breakpoints:r}}catch{let a=s.map((r,l)=>{let c=new O.Breakpoint(!1,r);return c.id=l+1,c});this.breakpoints.set(o,a),e.body={breakpoints:a}}this.sendResponse(e)}breakpointLocationsRequest(e,t){let o=t.line,s=t.endLine??o,i=[];for(let a=o;a<=s;a++)i.push({line:a});e.body={breakpoints:i},this.sendResponse(e)}threadsRequest(e){e.body={threads:[new O.Thread(rr,"Lurek2D Main")]},this.sendResponse(e)}async stackTraceRequest(e,t){try{let o=await this.sendToEngine("stackTrace"),s=[];if(o.body&&Array.isArray(o.body.frames)){let i=o.body.frames,a=t.startFrame??0,r=t.levels??i.length,l=Math.min(a+r,i.length);for(let c=a;c<l;c++){let d=i[c],u=this.toAbsolutePath(d.file),v=new O.Source(oe.basename(d.file),u);s.push(new O.StackFrame(c,d.name,v,d.line,d.column??1))}}e.body={stackFrames:s,totalFrames:o.body?.frames?.length??s.length}}catch{e.body={stackFrames:[],totalFrames:0}}this.sendResponse(e)}async scopesRequest(e,t){try{let o=await this.sendToEngine("scopes",{frameId:t.frameId}),s=[];if(o.body&&Array.isArray(o.body.scopes))for(let i of o.body.scopes)s.push(new O.Scope(i.name,i.variablesReference,i.expensive??!1));else{let i=this.nextVariableRef++,a=this.nextVariableRef++;s.push(new O.Scope("Locals",i,!1)),s.push(new O.Scope("Upvalues",a,!1))}e.body={scopes:s}}catch{e.body={scopes:[]}}this.sendResponse(e)}async variablesRequest(e,t){try{let o=this.variablesMap.get(t.variablesReference);if(o){e.body={variables:o},this.sendResponse(e);return}let s=await this.sendToEngine("variables",{variablesReference:t.variablesReference}),i=[];if(s.body&&Array.isArray(s.body.variables))for(let a of s.body.variables){let r=0;if(a.children&&a.children.length>0){r=this.nextVariableRef++;let l=a.children.map(c=>{let d=0;return c.children&&c.children.length>0&&(d=this.nextVariableRef++,this.variablesMap.set(d,c.children.map(u=>new O.Variable(u.name,u.value,0)))),new O.Variable(c.name,c.value,d)});this.variablesMap.set(r,l)}else a.variablesReference&&(r=a.variablesReference);i.push(new O.Variable(a.name,a.value,r))}this.variablesMap.set(t.variablesReference,i),e.body={variables:i}}catch{e.body={variables:[]}}this.sendResponse(e)}async setVariableRequest(e,t){try{let o=await this.sendToEngine("setVariable",{variablesReference:t.variablesReference,name:t.name,value:t.value});e.body={value:o.body?.value??t.value},this.variablesMap.delete(t.variablesReference)}catch(o){let s=o instanceof Error?o.message:String(o);this.sendErrorResponse(e,1010,`Failed to set variable: ${s}`);return}this.sendResponse(e)}async continueRequest(e,t){this.variablesMap.clear();try{await this.sendToEngine("continue")}catch{}e.body={allThreadsContinued:!0},this.sendResponse(e)}async nextRequest(e,t){this.variablesMap.clear();try{await this.sendToEngine("next")}catch{}this.sendResponse(e)}async stepInRequest(e,t){this.variablesMap.clear();try{await this.sendToEngine("stepIn")}catch{}this.sendResponse(e)}async stepOutRequest(e,t){this.variablesMap.clear();try{await this.sendToEngine("stepOut")}catch{}this.sendResponse(e)}async pauseRequest(e,t){try{await this.sendToEngine("pause")}catch{}this.sendResponse(e)}async evaluateRequest(e,t){try{let o=await this.sendToEngine("evaluate",{expression:t.expression,frameId:t.frameId??0,context:t.context}),s=o.body?.result??"nil",i=o.body?.variablesReference??0;e.body={result:s,variablesReference:i}}catch(o){let s=o instanceof Error?o.message:String(o);e.body={result:`Error: ${s}`,variablesReference:0}}this.sendResponse(e)}completionsRequest(e,t){let o=t.text,s=[];if(o.startsWith("lurek.")){let a=["graphics","audio","timer","keyboard","mouse","gamepad","touch","window","filesystem","math","physics","system","data","event","thread","scene","entity","particle"];for(let r of a)r.startsWith(o.slice(5))&&s.push(new O.CompletionItem(r,9))}let i=["local","function","if","then","else","elseif","end","for","while","do","repeat","until","return","break","in","not","and","or","true","false","nil"];for(let a of i)a.startsWith(o)&&s.push(new O.CompletionItem(a,14));e.body={targets:s},this.sendResponse(e)}loadedSourcesRequest(e){e.body={sources:this.loadedSources},this.sendResponse(e)}connectToEngine(e){return new Promise((t,o)=>{let s=0,i=()=>{let a=new dr.Socket,r=l=>{a.destroy(),s++,s<lr?(this.log(`Connection attempt ${s} failed, retrying in ${cr}ms...`),setTimeout(i,cr)):o(new Error(`Failed to connect to Lurek2D engine on port ${e} after ${lr} attempts: ${l.message}`))};a.once("error",r),a.connect(e,"127.0.0.1",()=>{a.removeListener("error",r),this.socket=a,this.receiveBuffer="",this.log(`Connected to Lurek2D engine on port ${e}`),a.on("data",l=>{this.onSocketData(l)}),a.on("error",l=>{this.sendEvent(new O.OutputEvent(`Engine connection error: ${l.message}
`,"stderr")),this.cleanup(),this.sendEvent(new O.TerminatedEvent)}),a.on("close",()=>{this.log("Engine connection closed"),this.cleanup(),this.sendEvent(new O.TerminatedEvent)}),t()})};i()})}sendToEngine(e,t){return new Promise((o,s)=>{if(!this.socket||this.socket.destroyed){s(new Error("Not connected to engine"));return}let i=this.nextRequestId++,a=JSON.stringify({id:i,command:e,args:t??{}}),r=`Content-Length: ${Buffer.byteLength(a)}\r
\r
${a}`;this.pendingRequests.set(i,{resolve:o,reject:s});let l=setTimeout(()=>{this.pendingRequests.delete(i),s(new Error(`Request '${e}' timed out`))},1e4),c=this.pendingRequests.get(i);this.pendingRequests.set(i,{resolve:d=>{clearTimeout(l),c.resolve(d)},reject:d=>{clearTimeout(l),c.reject(d)}});try{this.socket.write(r)}catch(d){clearTimeout(l),this.pendingRequests.delete(i),s(d instanceof Error?d:new Error(String(d)))}})}onSocketData(e){for(this.receiveBuffer+=e.toString("utf-8");;){let t=this.receiveBuffer.indexOf(`\r
\r
`);if(t===-1)break;let o=this.receiveBuffer.substring(0,t),s=/Content-Length:\s*(\d+)/i.exec(o);if(!s){this.receiveBuffer=this.receiveBuffer.substring(t+4);continue}let i=parseInt(s[1],10),a=t+4;if(this.receiveBuffer.length<a+i)break;let r=this.receiveBuffer.substring(a,a+i);this.receiveBuffer=this.receiveBuffer.substring(a+i);try{let l=JSON.parse(r);"event"in l?this.handleEngineEvent(l):"id"in l&&this.handleEngineResponse(l)}catch{this.log(`Failed to parse engine message: ${r}`)}}}handleEngineEvent(e){switch(e.event){case"stopped":{let t=new O.StoppedEvent(e.reason??"breakpoint",rr);this.variablesMap.clear(),this.sendEvent(t);break}case"output":{this.sendEvent(new O.OutputEvent(e.output??"",e.category??"console"));break}case"terminated":{this.sendEvent(new O.TerminatedEvent);break}case"breakpointValidated":{if(e.id!==void 0&&e.verified!==void 0)for(let[,t]of this.breakpoints)for(let o of t)o.id===e.id&&(o.verified=e.verified);break}default:this.log(`Unknown engine event: ${e.event}`)}}handleEngineResponse(e){let t=this.pendingRequests.get(e.id);t&&(this.pendingRequests.delete(e.id),e.success?t.resolve(e):t.reject(new Error(e.error??"Unknown engine error")))}findEngineBinary(e){if(e&&Et.existsSync(e))return e;let t=require("vscode").workspace.getConfiguration("lurek").get("enginePath","");if(t&&Et.existsSync(t))return t;let o=require("vscode").workspace.workspaceFolders?.[0]?.uri.fsPath;if(o){let l=process.platform==="win32"?"lurek2d.exe":"lurek2d",c=[oe.join(o,"build","debug",l),oe.join(o,"build","release",l),oe.join(o,"target","debug",l),oe.join(o,"target","release",l)];for(let d of c)if(Et.existsSync(d))return this.log(`Found engine binary: ${d}`),d}let s=process.env.USERPROFILE??process.env.HOME??"",i=[oe.join(s,"bin","lurek2d.exe"),oe.join(s,"bin","lurek2d"),oe.join(s,".local","bin","lurek2d"),"/usr/local/bin/lurek2d"];for(let l of i)if(Et.existsSync(l))return l;let a=process.platform==="win32"?"lurek2d.exe":"lurek2d",r=(process.env.PATH??"").split(oe.delimiter);for(let l of r){let c=oe.join(l,a);if(Et.existsSync(c))return c}return null}toRelativePath(e){if(this.gamePath&&e.startsWith(this.gamePath)){let t=e.substring(this.gamePath.length);return(t.startsWith(oe.sep)||t.startsWith("/"))&&(t=t.substring(1)),t.replace(/\\/g,"/")}return oe.basename(e)}toAbsolutePath(e){return oe.isAbsolute(e)?e:oe.join(this.gamePath,e)}cleanup(){if(this.socket&&(this.socket.removeAllListeners(),this.socket.destroy(),this.socket=null),this.engineProcess){try{this.engineProcess.kill()}catch{}this.engineProcess=null}for(let[,e]of this.pendingRequests)e.reject(new Error("Debug session ended"));this.pendingRequests.clear(),this.variablesMap.clear()}log(e){this.sendEvent(new O.OutputEvent(`[Lurek2D Debug] ${e}
`,"console"))}};var Is=class{createDebugAdapterDescriptor(e,t){return new Be.DebugAdapterInlineImplementation(new po)}},Ps=class{resolveDebugConfiguration(e,t,o){if(t.type||(t.type="lurek"),t.request||(t.request="launch"),t.name||(t.name="Lurek2D: Debug Game"),!t.program){let s=e?.uri.fsPath??Be.workspace.workspaceFolders?.[0]?.uri.fsPath,i=Be.window.activeTextEditor?.document.uri.fsPath;if(i){let a=require("path").dirname(i),r=require("path").join(a,"main.lua");require("fs").existsSync(r)?t.program=a:t.program=s??"${workspaceFolder}"}else t.program=s??"${workspaceFolder}"}if(t.luaVersion||(t.luaVersion=Be.workspace.getConfiguration("lurek").get("luaVersion","luajit")),t.stopOnEntry===void 0&&(t.stopOnEntry=!1),t.debugPort||(t.debugPort=8172),!t.enginePath){let s=e?.uri.fsPath??Be.workspace.workspaceFolders?.[0]?.uri.fsPath;if(s){let i=require("path").join(s,"build","debug",process.platform==="win32"?"lurek2d.exe":"lurek2d"),a=require("path").join(s,"build","release",process.platform==="win32"?"lurek2d.exe":"lurek2d");require("fs").existsSync(i)?t.enginePath=i:require("fs").existsSync(a)&&(t.enginePath=a)}}return t}provideDebugConfigurations(e){return[{type:"lurek",request:"launch",name:"Lurek2D: Debug Game",program:"${workspaceFolder}",stopOnEntry:!1},{type:"lurek",request:"launch",name:"Lurek2D: Debug Current Demo",program:"${fileDirname}",stopOnEntry:!1},{type:"lurek",request:"launch",name:"Lurek2D: Debug with Stop on Entry",program:"${workspaceFolder}",stopOnEntry:!0},{type:"lurek",request:"attach",name:"Lurek2D: Attach to Running",debugPort:8172}]}};function pr(n){let e=new Is,t=new Ps;n.subscriptions.push(Be.debug.registerDebugAdapterDescriptorFactory("lurek",e),Be.debug.registerDebugConfigurationProvider("lurek",t))}var jt,He,mo,ne,ge;function au(n){He=new Kt,mo=new Jt,ne=new Qt,ge=new Ot,n.subscriptions.push(He,mo,ge),ne.load(n.extensionPath).catch(r=>{console.error("Failed to load Lurek2D API data:",r)}),He.onStatusChange(r=>{r?mo.setRunning():mo.setStopped()});let e=new en,t=new tn,o=new nn;n.subscriptions.push(T.window.registerTreeDataProvider("lurek.projectTools",e),T.window.registerTreeDataProvider("lurek.devTools",t),T.window.registerTreeDataProvider("lurek.aiCopilot",o)),Vs(n,ne),Ks(n,ne),Js(n,ne),ei(n,ne),ti(n,ne),si(n,ne),ai(n,ne),ri(n,ne),ci(n,ne),di(n,ne),ui(n,ne),hi(n,ne),vi(n,ne),yi(n),bi(n),Yi(n,ne),ki(n,ne),Ri(n,ne),Ai(n,ne),Wi(n,ne);let s=new ln;n.subscriptions.push(T.window.registerTreeDataProvider("lurek.assetExplorer",s)),M(n,"lurek.runGame",()=>_o(He)),M(n,"lurek.stopGame",()=>pa(He)),M(n,"lurek.runWithArgs",()=>ma(He)),M(n,"lurek.runExample",()=>mn(He)),M(n,"lurek.test.all",()=>ya());let i=["ai","audio","cardgame","combat","compute","config","crafting","data","dataframe","dialog","engine","entity","event","filesystem","graph","graphics","graphics_ext","image","input","inventory","math","math_ext","minimap","modding","particle","pathfinding","physics","postfx","quest","resource","savegame","scene","sound","stats","thread","tilemap","timer"];for(let r of i)M(n,`lurek.test.rust.${r}`,()=>ba(r));if(M(n,"lurek.test.lua.all",()=>xa()),M(n,"lurek.test.lua.golden",()=>wa()),Na(n),M(n,"lurek.scaffold.project",()=>ha()),M(n,"lurek.scaffold.file",()=>va()),M(n,"lurek.extractToModuleFile",async(...r)=>{let l=r[0],c=r[1];if(!l||!c)return;let d=await T.window.showInputBox({prompt:"New module file name (without .lua)",placeHolder:"my_module",validateInput:p=>/^[a-z_][a-z0-9_]*$/i.test(p)?null:"Use letters, digits, underscores"});if(!d)return;let v=(await T.workspace.openTextDocument(l)).getText(c),m=l.fsPath.replace(/[/\\][^/\\]+$/,""),h=T.Uri.file(`${m}/${d}.lua`),y=new T.WorkspaceEdit;y.createFile(h,{ignoreIfExists:!0}),y.insert(h,new T.Position(0,0),`-- ${d}.lua
local M = {}

${v}

return M
`),y.replace(l,c,`require("${d}")`),await T.workspace.applyEdit(y),await T.window.showTextDocument(h)}),M(n,"lurek.package.zip",()=>ka()),M(n,"lurek.package.windows",()=>Sa()),M(n,"lurek.package.linux",()=>Ea()),n.subscriptions.push(...Ta(n)),M(n,"lurek.assets.refresh",()=>s.refresh()),M(n,"lurek.assets.openPanel",()=>{T.window.showInformationMessage("Asset Explorer is in the sidebar under Lurek2D.")}),M(n,"lurek.assets.findMissing",()=>Gi()),M(n,"lurek.assets.insertPath",r=>{r instanceof dt&&Vi(r)}),M(n,"lurek.perf.openDashboard",()=>Do(n)),M(n,"lurek.perf.clearHistory",()=>{let{clearHistory:r}=(Ao(),Vt(Ui));r()}),M(n,"lurek.perf.openHotReload",()=>{let r=T.window.createWebviewPanel("lurek.hotReload","Hot-Reload History",T.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0}),l=[],c=T.workspace.workspaceFolders?.[0]?.uri.fsPath??"",d=T.workspace.createFileSystemWatcher(new T.RelativePattern(c,"**/*.lua")),u=(v,m)=>{l.unshift({time:new Date().toLocaleTimeString(),file:T.workspace.asRelativePath(v),status:m}),l.length>200&&l.pop(),r.webview.postMessage({type:"events",events:l})};d.onDidChange(v=>u(v,"changed")),d.onDidCreate(v=>u(v,"created")),d.onDidDelete(v=>u(v,"deleted")),r.onDidDispose(()=>d.dispose()),r.webview.html=`<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline';"><style>body{font-family:var(--vscode-font-family);background:var(--vscode-editor-background);color:var(--vscode-foreground);padding:12px;margin:0;font-size:12px}h2{margin:0 0 10px;font-size:14px}table{border-collapse:collapse;width:100%}th,td{border:1px solid var(--vscode-panel-border,#444);padding:4px 8px;text-align:left}th{background:var(--vscode-editorWidget-background,#1e1e1e)}.changed{color:#4ec9b0}.created{color:#dcdcaa}.deleted{color:#f44747}#empty{opacity:.5;margin-top:20px}</style></head><body><h2>\u{1F504} Hot-Reload File Watcher</h2><p id="empty">Watching *.lua files \u2014 save a file to see events here.</p><table id="tbl" style="display:none"><thead><tr><th>Time</th><th>File</th><th>Status</th></tr></thead><tbody id="body"></tbody></table><script>window.addEventListener('message',e=>{const{events}=e.data;if(!events||!events.length)return;document.getElementById('empty').style.display='none';document.getElementById('tbl').style.display='';document.getElementById('body').innerHTML=events.map(ev=>'<tr><td>'+ev.time+'</td><td>'+ev.file+'</td><td class="'+ev.status+'">'+ev.status+'</td></tr>').join('');});</script></body></html>`}),M(n,"lurek.deps.showGraph",()=>qo(n)),M(n,"lurek.deps.findCircular",async()=>{let r=T.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!r){T.window.showErrorMessage("No workspace folder open.");return}let l=T.window.createOutputChannel("Lurek2D Circular Deps");l.show(!0),l.appendLine("\u{1F50D} Scanning for circular dependencies...");let c=require("fs"),d=require("path"),u=d.join(r,"src");if(!c.existsSync(u)){l.appendLine("src/ directory not found.");return}let v=c.readdirSync(u,{withFileTypes:!0}).filter(k=>k.isDirectory()).map(k=>k.name),m={};for(let k of v){m[k]=[];let L=d.join(u,k,"mod.rs");if(!c.existsSync(L))continue;let _=c.readFileSync(L,"utf-8");for(let Q of _.matchAll(/use crate::([a-z_]+)/g))Q[1]!==k&&v.includes(Q[1])&&!m[k].includes(Q[1])&&m[k].push(Q[1])}let h={},y={},p={},g=[],f=0,b=[];function x(k){h[k]=y[k]=f++,g.push(k),p[k]=!0;for(let L of m[k]||[])h[L]===void 0?(x(L),y[k]=Math.min(y[k],y[L])):p[L]&&(y[k]=Math.min(y[k],h[L]));if(y[k]===h[k]){let L=[],_;do _=g.pop(),p[_]=!1,L.push(_);while(_!==k);L.length>1&&b.push(L)}}for(let k of v)h[k]===void 0&&x(k);b.length===0?l.appendLine("\u2705 No circular dependencies found."):(l.appendLine(`\u26A0\uFE0F  Found ${b.length} circular dependency cycle(s):`),b.forEach((k,L)=>l.appendLine(`  Cycle ${L+1}: ${k.join(" \u2192 ")} \u2192 ${k[k.length-1]}`))),l.appendLine(`
Done.`)}),M(n,"lurek.deps.findOrphans",async()=>{let r=T.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!r){T.window.showErrorMessage("No workspace folder open.");return}let l=T.window.createOutputChannel("Lurek2D Orphan Modules");l.show(!0),l.appendLine("\u{1F50D} Scanning for orphan modules...");let c=require("fs"),d=require("path"),u=d.join(r,"src");if(!c.existsSync(u)){l.appendLine("src/ not found.");return}let v=c.readdirSync(u,{withFileTypes:!0}).filter(f=>f.isDirectory()).map(f=>f.name),m=d.join(r,"src","lib.rs"),h=c.existsSync(m)?c.readFileSync(m,"utf-8"):"",y=new Set(v.filter(f=>h.includes(`pub mod ${f}`)||h.includes(`mod ${f}`))),p=new Set;for(let f of v){let b=d.join(u,f,"mod.rs");if(!c.existsSync(b))continue;let x=c.readFileSync(b,"utf-8");for(let k of x.matchAll(/use crate::([a-z_]+)/g))k[1]!==f&&p.add(k[1])}let g=v.filter(f=>!y.has(f)&&!p.has(f));g.length===0?l.appendLine("\u2705 No orphan modules found \u2014 all modules are referenced."):(l.appendLine(`\u26A0\uFE0F  Found ${g.length} potentially orphaned module(s):`),g.forEach(f=>l.appendLine(`  \u2022 ${f}`))),l.appendLine(`
Done.`)}),Ki(n,ne),M(n,"lurek.debug.openWatchers",()=>ea(n)),M(n,"lurek.debug.openInspector",()=>{let r=T.window.createWebviewPanel("lurekVariableInspector","Lurek2D Variable Inspector",T.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0}),l=d=>`<!DOCTYPE html><html><head>
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
  <tbody id="rows">${d.length===0?'<tr><td colspan="3" class="empty">No watched expressions. Enter a Lua expression above.</td></tr>':d.map(u=>`<tr><td>${u.expr}</td><td class="val">${u.value}</td><td class="type">${u.type}</td></tr>`).join("")}</tbody>
</table>
<script>
  const vscode = acquireVsCodeApi();
  function addExpr(){ const e=document.getElementById('expr'); if(e.value.trim()) vscode.postMessage({cmd:'watch',expr:e.value.trim()}); e.value=''; }
  function clearAll(){ vscode.postMessage({cmd:'clear'}); }
  document.getElementById('expr').addEventListener('keydown',e=>{ if(e.key==='Enter') addExpr(); });
  window.addEventListener('message',e=>{ if(e.data.cmd==='refresh') location.reload(); });
</script>
</body></html>`,c=[];r.webview.html=l(c),r.webview.onDidReceiveMessage(async d=>{if(d.cmd==="watch"){let u="(not connected \u2014 run game with debug bridge)",v="?";try{let{DebugBridge:m}=await Promise.resolve().then(()=>(Go(),Oa));if(m.instance?.isConnected()){let h=await m.instance.evaluate(d.expr);u=h?.resultString??"(nil)",v=h?.luaType??"?"}}catch{}c.push({expr:d.expr,value:u,type:v}),r.webview.html=l(c)}else d.cmd==="clear"&&(c.length=0,r.webview.html=l(c))},void 0,n.subscriptions)}),M(n,"lurek.debug.openCallStack",()=>{T.window.showInformationMessage("Call stack available when connected to the Lua debug bridge.")}),M(n,"lurek.debug.addWatch",()=>{let r=T.window.activeTextEditor;r&&na(r)}),M(n,"lurek.system.openMonitor",()=>ra(n)),M(n,"lurek.api.usageReport",()=>da(n)),M(n,"lurek.api.quickInsert",()=>ua(ne)),typeof ge.onConnected=="function"){let r=ge;r.onConnected(()=>No(!0)),r.onDisconnected?.(()=>No(!1)),r.evaluate&&Ji(async l=>{try{let c=await r.evaluate(l);return{value:String(c),type:typeof c}}catch{return}})}M(n,"lurek.browseApi",()=>Vn()),M(n,"lurek.openApiDocs",()=>Ia()),M(n,"lurek.openWiki",()=>Pa()),M(n,"lurek.depGraph",()=>qo(n)),M(n,"lurek.depList",()=>La()),M(n,"lurek.apiCoverage",()=>{let r=T.window.createTerminal("Lurek2D API Coverage");r.show(),r.sendText("python tools/integration_coverage.py")}),Wa(n,ge),pr(n),M(n,"lurek.debug.runAndConnect",async()=>{await _o(He),await new Promise(l=>setTimeout(l,1500)),await ge.connect()?(T.commands.executeCommand("setContext","lurek.debugConnected",!0),ge.startStatsPolling(),T.window.showInformationMessage("Lurek2D started and debug bridge connected.")):T.window.showWarningMessage("Game launched but debug bridge could not connect. Is debug bridge enabled in conf.lua?")}),M(n,"lurek.debug.performance",()=>{if(!ge.isConnected){T.window.showErrorMessage("Not connected to Lurek2D engine. Run 'Lurek2D: Debug Connect' first.");return}let r=T.window.createWebviewPanel("lurek.debugPerf","Lurek2D Live Performance",T.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0});r.webview.html=`<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
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
</script></body></html>`;let l=setInterval(async()=>{if(!ge.isConnected){clearInterval(l);return}try{let c=await ge.getStats();r.webview.postMessage({type:"stats",...c})}catch{}},500);r.onDidDispose(()=>clearInterval(l))}),M(n,"lurek.debug.printHistory",()=>{ge.showOutput()}),M(n,"lurek.debug.screenshot",async()=>{if(!ge.isConnected){T.window.showErrorMessage("Not connected to Lurek2D engine. Run 'Lurek2D: Debug Connect' first.");return}try{let r=await ge.takeScreenshot();if(!r){T.window.showWarningMessage("Engine did not return screenshot data.");return}let l=Buffer.from(r,"base64"),c=T.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!c){T.window.showErrorMessage("No workspace folder.");return}let d=new Date().toISOString().replace(/[:.]/g,"-"),u=require("path").join(c,`screenshot-${d}.png`);require("fs").writeFileSync(u,l);let v=T.Uri.file(u);await T.commands.executeCommand("vscode.open",v),T.window.showInformationMessage(`Screenshot saved: screenshot-${d}.png`)}catch(r){T.window.showErrorMessage(`Screenshot failed: ${r instanceof Error?r.message:String(r)}`)}}),M(n,"lurek.debug.callStack",async()=>{if(!ge.isConnected){T.window.showErrorMessage("Not connected to Lurek2D engine. Run 'Lurek2D: Debug Connect' first.");return}try{let r=await ge.getCallStack();if(r.length===0){T.window.showInformationMessage("Call stack is empty (game may not be paused).");return}let l=r.map(d=>({label:`#${d.level} ${d.name}`,description:`${d.source}:${d.line}`,detail:`${d.source} line ${d.line}`,source:d.source,line:d.line})),c=await T.window.showQuickPick(l,{title:"Lua Call Stack",placeHolder:"Select a frame to navigate to"});if(c?.source&&c.source!=="?"&&c.source!=="[C]"){let d=c.source.startsWith("@")?c.source.slice(1):c.source,u=T.workspace.workspaceFolders?.[0]?.uri.fsPath;if(u){let v=require("path").join(u,d);if(require("fs").existsSync(v)){let m=await T.workspace.openTextDocument(v);await T.window.showTextDocument(m,{selection:new T.Range(c.line-1,0,c.line-1,0)})}}}}catch(r){T.window.showErrorMessage(`Call stack failed: ${r instanceof Error?r.message:String(r)}`)}}),M(n,"lurek.debug.status",async()=>{let r=ge.getStatusInfo();if(!r.connected)await T.window.showInformationMessage(`Lurek2D debug bridge: NOT connected (port ${r.port})`,"Connect Now","Dismiss")==="Connect Now"&&T.commands.executeCommand("lurek.debug.connect");else try{let l=await ge.getStats();T.window.showInformationMessage(`Lurek2D connected on port ${r.port} \xB7 FPS: ${l.fps} \xB7 Draw calls: ${l.drawCalls} \xB7 Memory: ${(l.memory/1024/1024).toFixed(1)} MB`)}catch{T.window.showInformationMessage(`Lurek2D debug bridge connected on port ${r.port}.`)}}),M(n,"lurek.cag.install",()=>Ra()),M(n,"lurek.cag.selectAgent",()=>Da()),M(n,"lurek.cag.selectSkill",()=>Ma()),M(n,"lurek.cag.selectPrompt",()=>Aa()),M(n,"lurek.cag.update",()=>{T.window.showInformationMessage("CAG update is not yet implemented.")}),M(n,"lurek.mcp.install",()=>{T.window.showInformationMessage("MCP server installation is not yet implemented.")}),M(n,"lurek.mcp.status",()=>{T.window.showInformationMessage(jt?"MCP server is running.":"MCP server is not running.")}),Ha(n),M(n,"lurek.jam.quickBuild",()=>{let r=T.window.createTerminal("Lurek2D Quick Build");r.show(),r.sendText("cargo build --release")}),M(n,"lurek.jam.checklist",()=>{T.window.showInformationMessage("Submission Checklist is not yet implemented.")}),qa(n),Ga(n),M(n,"lurek2d.runExample",()=>mn(He)),M(n,"lurek2d.listExamples",()=>mn(He)),M(n,"lurek2d.checkBuild",()=>{let r=T.window.createTerminal("Lurek2D Build Check");r.show(),r.sendText("cargo check")}),M(n,"lurek2d.getApiDoc",()=>Vn());let a=lu();a&&(jt=zs(a)),mr(n),n.subscriptions.push(T.workspace.onDidChangeConfiguration(r=>{r.affectsConfiguration("lurek.luaVersion")&&(ne.load(n.extensionPath).catch(l=>{console.error("Failed to reload Lurek2D API data:",l)}),mr(n))})),T.commands.executeCommand("setContext","lurek.gameRunning",!1)}function ru(){jt&&(jt.kill(),jt=void 0)}function M(n,e,t){n.subscriptions.push(T.commands.registerCommand(e,t))}function lu(){return T.workspace.workspaceFolders?.[0]?.uri.fsPath}function mr(n){let e=fr.join(n.extensionPath,"data"),t=T.workspace.getConfiguration("Lua"),o=t.get("workspace.library")??[];if(!o.includes(e)){let a=[...o,e];t.update("workspace.library",a,T.ConfigurationTarget.Global).then(void 0,()=>{})}let i=T.workspace.getConfiguration("lurek").get("luaVersion","luajit")==="lua54"?"Lua 5.4":"LuaJIT";t.update("runtime.version",i,T.ConfigurationTarget.Global).then(void 0,()=>{})}0&&(module.exports={activate,deactivate});
