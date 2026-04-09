"use strict";var nr=Object.create;var _t=Object.defineProperty;var or=Object.getOwnPropertyDescriptor;var ar=Object.getOwnPropertyNames;var sr=Object.getPrototypeOf,ir=Object.prototype.hasOwnProperty;var ha=(n,e)=>()=>(n&&(e=n(n=0)),e);var $e=(n,e)=>()=>(e||n((e={exports:{}}).exports,e),e.exports),oo=(n,e)=>{for(var t in e)_t(n,t,{get:e[t],enumerable:!0})},va=(n,e,t,o)=>{if(e&&typeof e=="object"||typeof e=="function")for(let a of ar(e))!ir.call(n,a)&&a!==t&&_t(n,a,{get:()=>e[a],enumerable:!(o=or(e,a))||o.enumerable});return n};var E=(n,e,t)=>(t=n!=null?nr(sr(n)):{},va(e||!n||!n.__esModule?_t(t,"default",{value:n,enumerable:!0}):t,n)),Ot=n=>va(_t({},"__esModule",{value:!0}),n);var so={};oo(so,{getToolDefinitions:()=>rr,handleCheckBuild:()=>pr,handleGetApiDoc:()=>dr,handleGetLogs:()=>mr,handleListExamples:()=>cr,handleRunExample:()=>lr,handleRunLuaTest:()=>ur});function rr(){return[{name:"luna2d.runExample",description:"Build and run a named Luna2D example, returning its output.",inputSchema:{type:"object",properties:{name:{type:"string",description:'Name of the example directory (e.g. "hello_world").'}},required:["name"]}},{name:"luna2d.getApiDoc",description:"Search the Luna2D Lua API documentation for a query string.",inputSchema:{type:"object",properties:{query:{type:"string",description:'Search query (e.g. "luna.graphics.draw" or "physics").'}},required:["query"]}},{name:"luna2d.listExamples",description:"List all available Luna2D example directories.",inputSchema:{type:"object",properties:{}}},{name:"luna2d.runLuaTest",description:"Run a Lua test file against a debug build of Luna2D.",inputSchema:{type:"object",properties:{file:{type:"string",description:"Path to the Lua test file, relative to workspace root."}},required:["file"]}},{name:"luna2d.checkBuild",description:"Run `cargo check` and return compiler diagnostics.",inputSchema:{type:"object",properties:{}}},{name:"luna2d.getLogs",description:"Return the last N lines of Luna2D engine log output.",inputSchema:{type:"object",properties:{lines:{type:"number",description:"Number of log lines to return (default: 50)."}}}}]}function ao(n,e,t=6e4){return new Promise(o=>{ya.exec(n,{cwd:e,timeout:t,maxBuffer:1024*1024},(a,s,i)=>{let r=(s||"")+(i||"");o(a?`${r}
[exit code: ${a.code??"unknown"}]`:r||"(no output)")})})}function lr(n){return async e=>{let t=e.name;if(!t)return"Error: 'name' parameter is required.";let o=Ye.join(n,"examples",t);if(!Le.existsSync(o)){let a=ba(n);return`Example "${t}" not found. Available: ${a.join(", ")}`}return ao(`cargo run -- examples/${t}`,n,12e4)}}function dr(n){return async e=>{let t=e.query;if(!t)return"Error: 'query' parameter is required.";let o=Ye.join(n,"docs","lua_api_reference_generated.md");if(!Le.existsSync(o))return"API reference not found. Run 'python tools/gen_lua_api.py' to generate it.";let s=Le.readFileSync(o,"utf-8").split(`
`),i=t.toLowerCase(),r=[],l=[],d=!1;for(let c of s)c.startsWith("##")?(d&&l.length>0&&r.push(l.join(`
`)),l=[c],d=c.toLowerCase().includes(i)):(l.push(c),c.toLowerCase().includes(i)&&(d=!0));return d&&l.length>0&&r.push(l.join(`
`)),r.length===0?`No documentation found for "${t}".`:r.join(`

---

`)}}function cr(n){return async()=>{let e=ba(n);return e.length===0?"No examples found in examples/ directory.":e.join(`
`)}}function ur(n){return async e=>{let t=e.file;if(!t)return"Error: 'file' parameter is required.";let o=Ye.resolve(n,t);return o.startsWith(n)?Le.existsSync(o)?ao(`cargo run -- ${t}`,n,12e4):`Test file not found: ${t}`:"Error: file path must be within the workspace."}}function pr(n){return async()=>ao("cargo check 2>&1",n,12e4)}function mr(n){return async e=>{let t=e.lines||50,o=[Ye.join(n,"luna2d.log"),Ye.join(n,"target","luna2d.log")];for(let a of o)if(Le.existsSync(a))return Le.readFileSync(a,"utf-8").split(`
`).slice(-t).join(`
`);return"No log file found. Engine logs are written to stdout by default. Use RUST_LOG=luna2d=debug to enable verbose logging."}}function ba(n){let e=Ye.join(n,"examples");if(!Le.existsSync(e))return[];try{return Le.readdirSync(e,{withFileTypes:!0}).filter(t=>t.isDirectory()).map(t=>t.name)}catch{return[]}}var ya,Le,Ye,io=ha(()=>{"use strict";ya=E(require("child_process")),Le=E(require("fs")),Ye=E(require("path"))});var zs={};oo(zs,{clearHistory:()=>Ns,openPerfDashboard:()=>bo,recordSample:()=>Hd});function bo(n){if(Me){Me.reveal(Ct.ViewColumn.Two);return}Me=Ct.window.createWebviewPanel("luna.perfDashboard","Luna2D Performance",Ct.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0}),Me.webview.html=qd(),Me.onDidDispose(()=>{Me=void 0},null,n.subscriptions),Me.webview.onDidReceiveMessage(e=>{e.type==="clear"&&Ns()},null,n.subscriptions),xo()}function Hd(n,e,t){Et.push({timestamp:Date.now(),fps:n,frameMs:e,luaHeapKb:t}),Et.length>Wd&&Et.shift(),Me?.visible&&xo()}function Ns(){Et.length=0,Me?.visible&&xo()}function xo(){Me&&Me.webview.postMessage({type:"data",samples:[...Et]})}function qd(){return`<!DOCTYPE html>
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
<h2>\u{1F3AE} Luna2D Performance Dashboard</h2>
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

<div id="empty" class="empty">No data yet \u2014 run your game with luna.debug.connect() to stream performance data.</div>

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
</html>`}var Ct,Me,Et,Wd,wo=ha(()=>{"use strict";Ct=E(require("vscode")),Et=[],Wd=300});var qn=$e(et=>{"use strict";Object.defineProperty(et,"__esModule",{value:!0});et.Event=et.Response=et.Message=void 0;var Ft=class{constructor(e){this.seq=0,this.type=e}};et.Message=Ft;var No=class extends Ft{constructor(e,t){super("response"),this.request_seq=e.seq,this.command=e.command,t?(this.success=!1,this.message=t):this.success=!0}};et.Response=No;var zo=class extends Ft{constructor(e,t){super("event"),this.event=e,t&&(this.body=t)}};et.Event=zo});var Fi=$e(Yn=>{"use strict";Object.defineProperty(Yn,"__esModule",{value:!0});Yn.ProtocolServer=void 0;var kc=require("events"),Bt=qn(),_o=class{get event(){return this._event||(this._event=(e,t)=>{this._listener=e,this._this=t;let o;return o={dispose:()=>{this._listener=void 0,this._this=void 0}},o}),this._event}fire(e){if(this._listener)try{this._listener.call(this._this,e)}catch{}}hasListener(){return!!this._listener}dispose(){this._listener=void 0,this._this=void 0}},jn=class n extends kc.EventEmitter{constructor(){super(),this._sendMessage=new _o,this._sequence=1,this._pendingRequests=new Map,this.onDidSendMessage=this._sendMessage.event}dispose(){}handleMessage(e){if(e.type==="request")this.dispatchRequest(e);else if(e.type==="response"){let t=e,o=this._pendingRequests.get(t.request_seq);o&&(this._pendingRequests.delete(t.request_seq),o(t))}}_isRunningInline(){return this._sendMessage&&this._sendMessage.hasListener()}start(e,t){this._writableStream=t,this._rawData=Buffer.alloc(0),e.on("data",o=>this._handleData(o)),e.on("close",()=>{this._emitEvent(new Bt.Event("close"))}),e.on("error",o=>{this._emitEvent(new Bt.Event("error","inStream error: "+(o&&o.message)))}),t.on("error",o=>{this._emitEvent(new Bt.Event("error","outStream error: "+(o&&o.message)))}),e.resume()}stop(){this._writableStream&&this._writableStream.end()}sendEvent(e){this._send("event",e)}sendResponse(e){e.seq>0?console.error(`attempt to send more than one response for command ${e.command}`):this._send("response",e)}sendRequest(e,t,o,a){let s={command:e};if(t&&Object.keys(t).length>0&&(s.arguments=t),this._send("request",s),a){this._pendingRequests.set(s.seq,a);let i=setTimeout(()=>{clearTimeout(i);let r=this._pendingRequests.get(s.seq);r&&(this._pendingRequests.delete(s.seq),r(new Bt.Response(s,"timeout")))},o)}}dispatchRequest(e){}_emitEvent(e){this.emit(e.event,e)}_send(e,t){if(t.type=e,t.seq=this._sequence++,this._writableStream){let o=JSON.stringify(t);this._writableStream.write(`Content-Length: ${Buffer.byteLength(o,"utf8")}\r
\r
${o}`,"utf8")}this._sendMessage.fire(t)}_handleData(e){for(this._rawData=Buffer.concat([this._rawData,e]);;){if(this._contentLength>=0){if(this._rawData.length>=this._contentLength){let t=this._rawData.toString("utf8",0,this._contentLength);if(this._rawData=this._rawData.slice(this._contentLength),this._contentLength=-1,t.length>0)try{let o=JSON.parse(t);this.handleMessage(o)}catch(o){this._emitEvent(new Bt.Event("error","Error handling data: "+(o&&o.message)))}continue}}else{let t=this._rawData.indexOf(n.TWO_CRLF);if(t!==-1){let a=this._rawData.toString("utf8",0,t).split(`\r
`);for(let s=0;s<a.length;s++){let i=a[s].split(/: +/);i[0]=="Content-Length"&&(this._contentLength=+i[1])}this._rawData=this._rawData.slice(t+n.TWO_CRLF.length);continue}}break}}};Yn.ProtocolServer=jn;jn.TWO_CRLF=`\r
\r
`});var Bi=$e(Vn=>{"use strict";Object.defineProperty(Vn,"__esModule",{value:!0});Vn.runDebugAdapter=void 0;var Sc=require("net");function Ec(n){let e=0;if(process.argv.slice(2).forEach(function(o,a,s){let i=/^--server=(\d{4,5})$/.exec(o);i&&(e=parseInt(i[1],10))}),e>0)console.error(`waiting for debug protocol on port ${e}`),Sc.createServer(o=>{console.error(">> accepted connection from client"),o.on("end",()=>{console.error(`>> client connection closed
`)});let a=new n(!1,!0);a.setRunAsServer(!0),a.start(o,o)}).listen(e);else{let o=new n(!1);process.on("SIGTERM",()=>{o.shutdown()}),o.start(process.stdin,process.stdout)}}Vn.runDebugAdapter=Ec});var Gn=$e(D=>{"use strict";Object.defineProperty(D,"__esModule",{value:!0});D.DebugSession=D.ErrorDestination=D.MemoryEvent=D.InvalidatedEvent=D.ProgressEndEvent=D.ProgressUpdateEvent=D.ProgressStartEvent=D.CapabilitiesEvent=D.LoadedSourceEvent=D.ModuleEvent=D.BreakpointEvent=D.ThreadEvent=D.OutputEvent=D.ExitedEvent=D.TerminatedEvent=D.InitializedEvent=D.ContinuedEvent=D.StoppedEvent=D.CompletionItem=D.Module=D.Breakpoint=D.Variable=D.Thread=D.StackFrame=D.Scope=D.Source=void 0;var Cc=Fi(),me=qn(),Tc=Bi(),Ni=require("url"),Oo=class{constructor(e,t,o=0,a,s){this.name=e,this.path=t,this.sourceReference=o,a&&(this.origin=a),s&&(this.adapterData=s)}};D.Source=Oo;var $o=class{constructor(e,t,o=!1){this.name=e,this.variablesReference=t,this.expensive=o}};D.Scope=$o;var Wo=class{constructor(e,t,o,a=0,s=0){this.id=e,this.source=o,this.line=a,this.column=s,this.name=t}};D.StackFrame=Wo;var Ho=class{constructor(e,t){this.id=e,t?this.name=t:this.name="Thread #"+e}};D.Thread=Ho;var qo=class{constructor(e,t,o=0,a,s){this.name=e,this.value=t,this.variablesReference=o,typeof s=="number"&&(this.namedVariables=s),typeof a=="number"&&(this.indexedVariables=a)}};D.Variable=qo;var jo=class{constructor(e,t,o,a){this.verified=e;let s=this;typeof t=="number"&&(s.line=t),typeof o=="number"&&(s.column=o),a&&(s.source=a)}setId(e){this.id=e}};D.Breakpoint=jo;var Yo=class{constructor(e,t){this.id=e,this.name=t}};D.Module=Yo;var Vo=class{constructor(e,t,o=0){this.label=e,this.start=t,this.length=o}};D.CompletionItem=Vo;var Xo=class extends me.Event{constructor(e,t,o){super("stopped"),this.body={reason:e},typeof t=="number"&&(this.body.threadId=t),typeof o=="string"&&(this.body.text=o)}};D.StoppedEvent=Xo;var Go=class extends me.Event{constructor(e,t){super("continued"),this.body={threadId:e},typeof t=="boolean"&&(this.body.allThreadsContinued=t)}};D.ContinuedEvent=Go;var Uo=class extends me.Event{constructor(){super("initialized")}};D.InitializedEvent=Uo;var Ko=class extends me.Event{constructor(e){if(super("terminated"),typeof e=="boolean"||e){let t=this;t.body={restart:e}}}};D.TerminatedEvent=Ko;var Jo=class extends me.Event{constructor(e){super("exited"),this.body={exitCode:e}}};D.ExitedEvent=Jo;var Qo=class extends me.Event{constructor(e,t="console",o){super("output"),this.body={category:t,output:e},o!==void 0&&(this.body.data=o)}};D.OutputEvent=Qo;var Zo=class extends me.Event{constructor(e,t){super("thread"),this.body={reason:e,threadId:t}}};D.ThreadEvent=Zo;var ea=class extends me.Event{constructor(e,t){super("breakpoint"),this.body={reason:e,breakpoint:t}}};D.BreakpointEvent=ea;var ta=class extends me.Event{constructor(e,t){super("module"),this.body={reason:e,module:t}}};D.ModuleEvent=ta;var na=class extends me.Event{constructor(e,t){super("loadedSource"),this.body={reason:e,source:t}}};D.LoadedSourceEvent=na;var oa=class extends me.Event{constructor(e){super("capabilities"),this.body={capabilities:e}}};D.CapabilitiesEvent=oa;var aa=class extends me.Event{constructor(e,t,o){super("progressStart"),this.body={progressId:e,title:t},typeof o=="string"&&(this.body.message=o)}};D.ProgressStartEvent=aa;var sa=class extends me.Event{constructor(e,t){super("progressUpdate"),this.body={progressId:e},typeof t=="string"&&(this.body.message=t)}};D.ProgressUpdateEvent=sa;var ia=class extends me.Event{constructor(e,t){super("progressEnd"),this.body={progressId:e},typeof t=="string"&&(this.body.message=t)}};D.ProgressEndEvent=ia;var ra=class extends me.Event{constructor(e,t,o){super("invalidated"),this.body={},e&&(this.body.areas=e),t&&(this.body.threadId=t),o&&(this.body.stackFrameId=o)}};D.InvalidatedEvent=ra;var la=class extends me.Event{constructor(e,t,o){super("memory"),this.body={memoryReference:e,offset:t,count:o}}};D.MemoryEvent=la;var lt;(function(n){n[n.User=1]="User",n[n.Telemetry=2]="Telemetry"})(lt=D.ErrorDestination||(D.ErrorDestination={}));var Xn=class n extends Cc.ProtocolServer{constructor(e,t){super();let o=typeof e=="boolean"?e:!1;this._debuggerLinesStartAt1=o,this._debuggerColumnsStartAt1=o,this._debuggerPathsAreURIs=!1,this._clientLinesStartAt1=!0,this._clientColumnsStartAt1=!0,this._clientPathsAreURIs=!1,this._isServer=typeof t=="boolean"?t:!1,this.on("close",()=>{this.shutdown()}),this.on("error",a=>{this.shutdown()})}setDebuggerPathFormat(e){this._debuggerPathsAreURIs=e!=="path"}setDebuggerLinesStartAt1(e){this._debuggerLinesStartAt1=e}setDebuggerColumnsStartAt1(e){this._debuggerColumnsStartAt1=e}setRunAsServer(e){this._isServer=e}static run(e){(0,Tc.runDebugAdapter)(e)}shutdown(){this._isServer||this._isRunningInline()||setTimeout(()=>{process.exit(0)},100)}sendErrorResponse(e,t,o,a,s=lt.User){let i;typeof t=="number"?(i={id:t,format:o},a&&(i.variables=a),s&lt.User&&(i.showUser=!0),s&lt.Telemetry&&(i.sendTelemetry=!0)):i=t,e.success=!1,e.message=n.formatPII(i.format,!0,i.variables),e.body||(e.body={}),e.body.error=i,this.sendResponse(e)}runInTerminalRequest(e,t,o){this.sendRequest("runInTerminal",e,t,o)}dispatchRequest(e){let t=new me.Response(e);try{if(e.command==="initialize"){var o=e.arguments;if(typeof o.linesStartAt1=="boolean"&&(this._clientLinesStartAt1=o.linesStartAt1),typeof o.columnsStartAt1=="boolean"&&(this._clientColumnsStartAt1=o.columnsStartAt1),o.pathFormat!=="path")this.sendErrorResponse(t,2018,"debug adapter only supports native paths",null,lt.Telemetry);else{let a=t;a.body={},this.initializeRequest(a,o)}}else e.command==="launch"?this.launchRequest(t,e.arguments,e):e.command==="attach"?this.attachRequest(t,e.arguments,e):e.command==="disconnect"?this.disconnectRequest(t,e.arguments,e):e.command==="terminate"?this.terminateRequest(t,e.arguments,e):e.command==="restart"?this.restartRequest(t,e.arguments,e):e.command==="setBreakpoints"?this.setBreakPointsRequest(t,e.arguments,e):e.command==="setFunctionBreakpoints"?this.setFunctionBreakPointsRequest(t,e.arguments,e):e.command==="setExceptionBreakpoints"?this.setExceptionBreakPointsRequest(t,e.arguments,e):e.command==="configurationDone"?this.configurationDoneRequest(t,e.arguments,e):e.command==="continue"?this.continueRequest(t,e.arguments,e):e.command==="next"?this.nextRequest(t,e.arguments,e):e.command==="stepIn"?this.stepInRequest(t,e.arguments,e):e.command==="stepOut"?this.stepOutRequest(t,e.arguments,e):e.command==="stepBack"?this.stepBackRequest(t,e.arguments,e):e.command==="reverseContinue"?this.reverseContinueRequest(t,e.arguments,e):e.command==="restartFrame"?this.restartFrameRequest(t,e.arguments,e):e.command==="goto"?this.gotoRequest(t,e.arguments,e):e.command==="pause"?this.pauseRequest(t,e.arguments,e):e.command==="stackTrace"?this.stackTraceRequest(t,e.arguments,e):e.command==="scopes"?this.scopesRequest(t,e.arguments,e):e.command==="variables"?this.variablesRequest(t,e.arguments,e):e.command==="setVariable"?this.setVariableRequest(t,e.arguments,e):e.command==="setExpression"?this.setExpressionRequest(t,e.arguments,e):e.command==="source"?this.sourceRequest(t,e.arguments,e):e.command==="threads"?this.threadsRequest(t,e):e.command==="terminateThreads"?this.terminateThreadsRequest(t,e.arguments,e):e.command==="evaluate"?this.evaluateRequest(t,e.arguments,e):e.command==="stepInTargets"?this.stepInTargetsRequest(t,e.arguments,e):e.command==="gotoTargets"?this.gotoTargetsRequest(t,e.arguments,e):e.command==="completions"?this.completionsRequest(t,e.arguments,e):e.command==="exceptionInfo"?this.exceptionInfoRequest(t,e.arguments,e):e.command==="loadedSources"?this.loadedSourcesRequest(t,e.arguments,e):e.command==="dataBreakpointInfo"?this.dataBreakpointInfoRequest(t,e.arguments,e):e.command==="setDataBreakpoints"?this.setDataBreakpointsRequest(t,e.arguments,e):e.command==="readMemory"?this.readMemoryRequest(t,e.arguments,e):e.command==="writeMemory"?this.writeMemoryRequest(t,e.arguments,e):e.command==="disassemble"?this.disassembleRequest(t,e.arguments,e):e.command==="cancel"?this.cancelRequest(t,e.arguments,e):e.command==="breakpointLocations"?this.breakpointLocationsRequest(t,e.arguments,e):e.command==="setInstructionBreakpoints"?this.setInstructionBreakpointsRequest(t,e.arguments,e):this.customRequest(e.command,t,e.arguments,e)}catch(a){this.sendErrorResponse(t,1104,"{_stack}",{_exception:a.message,_stack:a.stack},lt.Telemetry)}}initializeRequest(e,t){e.body.supportsConditionalBreakpoints=!1,e.body.supportsHitConditionalBreakpoints=!1,e.body.supportsFunctionBreakpoints=!1,e.body.supportsConfigurationDoneRequest=!0,e.body.supportsEvaluateForHovers=!1,e.body.supportsStepBack=!1,e.body.supportsSetVariable=!1,e.body.supportsRestartFrame=!1,e.body.supportsStepInTargetsRequest=!1,e.body.supportsGotoTargetsRequest=!1,e.body.supportsCompletionsRequest=!1,e.body.supportsRestartRequest=!1,e.body.supportsExceptionOptions=!1,e.body.supportsValueFormattingOptions=!1,e.body.supportsExceptionInfoRequest=!1,e.body.supportTerminateDebuggee=!1,e.body.supportsDelayedStackTraceLoading=!1,e.body.supportsLoadedSourcesRequest=!1,e.body.supportsLogPoints=!1,e.body.supportsTerminateThreadsRequest=!1,e.body.supportsSetExpression=!1,e.body.supportsTerminateRequest=!1,e.body.supportsDataBreakpoints=!1,e.body.supportsReadMemoryRequest=!1,e.body.supportsDisassembleRequest=!1,e.body.supportsCancelRequest=!1,e.body.supportsBreakpointLocationsRequest=!1,e.body.supportsClipboardContext=!1,e.body.supportsSteppingGranularity=!1,e.body.supportsInstructionBreakpoints=!1,e.body.supportsExceptionFilterOptions=!1,this.sendResponse(e)}disconnectRequest(e,t,o){this.sendResponse(e),this.shutdown()}launchRequest(e,t,o){this.sendResponse(e)}attachRequest(e,t,o){this.sendResponse(e)}terminateRequest(e,t,o){this.sendResponse(e)}restartRequest(e,t,o){this.sendResponse(e)}setBreakPointsRequest(e,t,o){this.sendResponse(e)}setFunctionBreakPointsRequest(e,t,o){this.sendResponse(e)}setExceptionBreakPointsRequest(e,t,o){this.sendResponse(e)}configurationDoneRequest(e,t,o){this.sendResponse(e)}continueRequest(e,t,o){this.sendResponse(e)}nextRequest(e,t,o){this.sendResponse(e)}stepInRequest(e,t,o){this.sendResponse(e)}stepOutRequest(e,t,o){this.sendResponse(e)}stepBackRequest(e,t,o){this.sendResponse(e)}reverseContinueRequest(e,t,o){this.sendResponse(e)}restartFrameRequest(e,t,o){this.sendResponse(e)}gotoRequest(e,t,o){this.sendResponse(e)}pauseRequest(e,t,o){this.sendResponse(e)}sourceRequest(e,t,o){this.sendResponse(e)}threadsRequest(e,t){this.sendResponse(e)}terminateThreadsRequest(e,t,o){this.sendResponse(e)}stackTraceRequest(e,t,o){this.sendResponse(e)}scopesRequest(e,t,o){this.sendResponse(e)}variablesRequest(e,t,o){this.sendResponse(e)}setVariableRequest(e,t,o){this.sendResponse(e)}setExpressionRequest(e,t,o){this.sendResponse(e)}evaluateRequest(e,t,o){this.sendResponse(e)}stepInTargetsRequest(e,t,o){this.sendResponse(e)}gotoTargetsRequest(e,t,o){this.sendResponse(e)}completionsRequest(e,t,o){this.sendResponse(e)}exceptionInfoRequest(e,t,o){this.sendResponse(e)}loadedSourcesRequest(e,t,o){this.sendResponse(e)}dataBreakpointInfoRequest(e,t,o){this.sendResponse(e)}setDataBreakpointsRequest(e,t,o){this.sendResponse(e)}readMemoryRequest(e,t,o){this.sendResponse(e)}writeMemoryRequest(e,t,o){this.sendResponse(e)}disassembleRequest(e,t,o){this.sendResponse(e)}cancelRequest(e,t,o){this.sendResponse(e)}breakpointLocationsRequest(e,t,o){this.sendResponse(e)}setInstructionBreakpointsRequest(e,t,o){this.sendResponse(e)}customRequest(e,t,o,a){this.sendErrorResponse(t,1014,"unrecognized request",null,lt.Telemetry)}convertClientLineToDebugger(e){return this._debuggerLinesStartAt1?this._clientLinesStartAt1?e:e+1:this._clientLinesStartAt1?e-1:e}convertDebuggerLineToClient(e){return this._debuggerLinesStartAt1?this._clientLinesStartAt1?e:e-1:this._clientLinesStartAt1?e+1:e}convertClientColumnToDebugger(e){return this._debuggerColumnsStartAt1?this._clientColumnsStartAt1?e:e+1:this._clientColumnsStartAt1?e-1:e}convertDebuggerColumnToClient(e){return this._debuggerColumnsStartAt1?this._clientColumnsStartAt1?e:e-1:this._clientColumnsStartAt1?e+1:e}convertClientPathToDebugger(e){return this._clientPathsAreURIs!==this._debuggerPathsAreURIs?this._clientPathsAreURIs?n.uri2path(e):n.path2uri(e):e}convertDebuggerPathToClient(e){return this._debuggerPathsAreURIs!==this._clientPathsAreURIs?this._debuggerPathsAreURIs?n.uri2path(e):n.path2uri(e):e}static path2uri(e){process.platform==="win32"&&(/^[A-Z]:/.test(e)&&(e=e[0].toLowerCase()+e.substr(1)),e=e.replace(/\\/g,"/")),e=encodeURI(e);let t=new Ni.URL("file:");return t.pathname=e,t.toString()}static uri2path(e){let t=new Ni.URL(e),o=decodeURIComponent(t.pathname);return process.platform==="win32"&&(/^\/[a-zA-Z]:/.test(o)&&(o=o[1].toLowerCase()+o.substr(2)),o=o.replace(/\//g,"\\")),o}static formatPII(e,t,o){return e.replace(n._formatPIIRegexp,function(a,s){return t&&s.length>0&&s[0]!=="_"?a:o[s]&&o.hasOwnProperty(s)?o[s]:a})}};D.DebugSession=Xn;Xn._formatPIIRegexp=/{([^}]+)}/g});var $i=$e(Kn=>{"use strict";Object.defineProperty(Kn,"__esModule",{value:!0});Kn.InternalLogger=void 0;var zi=require("fs"),_i=require("path"),Ee=Jn(),da=class{constructor(e,t){this.beforeExitCallback=()=>this.dispose(),this._logCallback=e,this._logToConsole=t,this._minLogLevel=Ee.LogLevel.Warn,this.disposeCallback=(o,a)=>{this.dispose(),a=a||2,a+=128,process.exit(a)}}async setup(e){if(this._minLogLevel=e.consoleMinLogLevel,this._prependTimestamp=e.prependTimestamp,e.logFilePath)if(!_i.isAbsolute(e.logFilePath))this.log(`logFilePath must be an absolute path: ${e.logFilePath}`,Ee.LogLevel.Error);else{let t=o=>this.sendLog(`Error creating log file at path: ${e.logFilePath}. Error: ${o.toString()}
`,Ee.LogLevel.Error);try{await zi.promises.mkdir(_i.dirname(e.logFilePath),{recursive:!0}),this.log(`Verbose logs are written to:
`,Ee.LogLevel.Warn),this.log(e.logFilePath+`
`,Ee.LogLevel.Warn),this._logFileStream=zi.createWriteStream(e.logFilePath),this.logDateTime(),this.setupShutdownListeners(),this._logFileStream.on("error",o=>{t(o)})}catch(o){t(o)}}}logDateTime(){let e=new Date,o=e.getUTCFullYear()+`-${e.getUTCMonth()+1}-`+e.getUTCDate()+", "+Oi();this.log(o+`
`,Ee.LogLevel.Verbose,!1)}setupShutdownListeners(){process.on("beforeExit",this.beforeExitCallback),process.on("SIGTERM",this.disposeCallback),process.on("SIGINT",this.disposeCallback)}removeShutdownListeners(){process.removeListener("beforeExit",this.beforeExitCallback),process.removeListener("SIGTERM",this.disposeCallback),process.removeListener("SIGINT",this.disposeCallback)}dispose(){return new Promise(e=>{this.removeShutdownListeners(),this._logFileStream?(this._logFileStream.end(e),this._logFileStream=null):e()})}log(e,t,o=!0){if(this._minLogLevel!==Ee.LogLevel.Stop){if(t>=this._minLogLevel&&this.sendLog(e,t),this._logToConsole){let a=t===Ee.LogLevel.Error?console.error:t===Ee.LogLevel.Warn?console.warn:null;a&&a((0,Ee.trimLastNewline)(e))}t===Ee.LogLevel.Error&&(e=`[${Ee.LogLevel[t]}] ${e}`),this._prependTimestamp&&o&&(e="["+Oi()+"] "+e),this._logFileStream&&this._logFileStream.write(e)}}sendLog(e,t){if(e.length>1500){let o=!!e.match(/(\n|\r\n)$/);e=e.substr(0,1500)+"[...]",o&&(e=e+`
`)}if(this._logCallback){let o=new Ee.LogOutputEvent(e,t);this._logCallback(o)}}};Kn.InternalLogger=da;function Oi(){let n=new Date,e=Un(2,String(n.getUTCHours())),t=Un(2,String(n.getUTCMinutes())),o=Un(2,String(n.getUTCSeconds())),a=Un(3,String(n.getUTCMilliseconds()));return e+":"+t+":"+o+"."+a+" UTC"}function Un(n,e){return e.length>=n?e:String("0".repeat(n)+e).slice(-n)}});var Jn=$e(Ce=>{"use strict";Object.defineProperty(Ce,"__esModule",{value:!0});Ce.trimLastNewline=Ce.LogOutputEvent=Ce.logger=Ce.Logger=Ce.LogLevel=void 0;var Ic=$i(),Pc=Gn(),tt;(function(n){n[n.Verbose=0]="Verbose",n[n.Log=1]="Log",n[n.Warn=2]="Warn",n[n.Error=3]="Error",n[n.Stop=4]="Stop"})(tt=Ce.LogLevel||(Ce.LogLevel={}));var Qn=class{constructor(){this._pendingLogQ=[]}log(e,t=tt.Log){e=e+`
`,this._write(e,t)}verbose(e){this.log(e,tt.Verbose)}warn(e){this.log(e,tt.Warn)}error(e){this.log(e,tt.Error)}dispose(){if(this._currentLogger){let e=this._currentLogger.dispose();return this._currentLogger=null,e}else return Promise.resolve()}_write(e,t=tt.Log){e=e+"",this._pendingLogQ?this._pendingLogQ.push({msg:e,level:t}):this._currentLogger&&this._currentLogger.log(e,t)}setup(e,t,o=!0){let a=typeof t=="string"?t:t&&this._logFilePathFromInit;if(this._currentLogger){let s={consoleMinLogLevel:e,logFilePath:a,prependTimestamp:o};this._currentLogger.setup(s).then(()=>{if(this._pendingLogQ){let i=this._pendingLogQ;this._pendingLogQ=null,i.forEach(r=>this._write(r.msg,r.level))}})}}init(e,t,o){this._pendingLogQ=this._pendingLogQ||[],this._currentLogger=new Ic.InternalLogger(e,o),this._logFilePathFromInit=t}};Ce.Logger=Qn;Ce.logger=new Qn;var ca=class extends Pc.OutputEvent{constructor(e,t){let o=t===tt.Error?"stderr":t===tt.Warn?"console":"stdout";super(e,o)}};Ce.LogOutputEvent=ca;function Lc(n){return n.replace(/(\n|\r\n)$/,"")}Ce.trimLastNewline=Lc});var qi=$e(Zn=>{"use strict";Object.defineProperty(Zn,"__esModule",{value:!0});Zn.LoggingDebugSession=void 0;var Hi=Jn(),bt=Hi.logger,Wi=Gn(),ua=class extends Wi.DebugSession{constructor(e,t,o){super(t,o),this.obsolete_logFilePath=e,this.on("error",a=>{bt.error(a.body)})}start(e,t){super.start(e,t),bt.init(o=>this.sendEvent(o),this.obsolete_logFilePath,this._isServer)}sendEvent(e){if(!(e instanceof Hi.LogOutputEvent)){let t=e;e instanceof Wi.OutputEvent&&e.body&&e.body.data&&e.body.data.doNotLogOutput&&(delete e.body.data.doNotLogOutput,t={...e},t.body={...e.body,output:"<output not logged>"}),bt.verbose(`To client: ${JSON.stringify(t)}`)}super.sendEvent(e)}sendRequest(e,t,o,a){bt.verbose(`To client: ${JSON.stringify(e)}(${JSON.stringify(t)}), timeout: ${o}`),super.sendRequest(e,t,o,a)}sendResponse(e){bt.verbose(`To client: ${JSON.stringify(e)}`),super.sendResponse(e)}dispatchRequest(e){bt.verbose(`From client: ${e.command}(${JSON.stringify(e.arguments)})`),super.dispatchRequest(e)}};Zn.LoggingDebugSession=ua});var ji=$e(eo=>{"use strict";Object.defineProperty(eo,"__esModule",{value:!0});eo.Handles=void 0;var pa=class{constructor(e){this.START_HANDLE=1e3,this._handleMap=new Map,this._nextHandle=typeof e=="number"?e:this.START_HANDLE}reset(){this._nextHandle=this.START_HANDLE,this._handleMap=new Map}create(e){var t=this._nextHandle++;return this._handleMap.set(t,e),t}get(e,t){return this._handleMap.get(e)||t}};eo.Handles=pa});var Xi=$e(I=>{"use strict";Object.defineProperty(I,"__esModule",{value:!0});I.Handles=I.Response=I.Event=I.ErrorDestination=I.CompletionItem=I.Module=I.Source=I.Breakpoint=I.Variable=I.Scope=I.StackFrame=I.Thread=I.MemoryEvent=I.InvalidatedEvent=I.ProgressEndEvent=I.ProgressUpdateEvent=I.ProgressStartEvent=I.CapabilitiesEvent=I.LoadedSourceEvent=I.ModuleEvent=I.BreakpointEvent=I.ThreadEvent=I.OutputEvent=I.ContinuedEvent=I.StoppedEvent=I.ExitedEvent=I.TerminatedEvent=I.InitializedEvent=I.logger=I.Logger=I.LoggingDebugSession=I.DebugSession=void 0;var K=Gn();Object.defineProperty(I,"DebugSession",{enumerable:!0,get:function(){return K.DebugSession}});Object.defineProperty(I,"InitializedEvent",{enumerable:!0,get:function(){return K.InitializedEvent}});Object.defineProperty(I,"TerminatedEvent",{enumerable:!0,get:function(){return K.TerminatedEvent}});Object.defineProperty(I,"ExitedEvent",{enumerable:!0,get:function(){return K.ExitedEvent}});Object.defineProperty(I,"StoppedEvent",{enumerable:!0,get:function(){return K.StoppedEvent}});Object.defineProperty(I,"ContinuedEvent",{enumerable:!0,get:function(){return K.ContinuedEvent}});Object.defineProperty(I,"OutputEvent",{enumerable:!0,get:function(){return K.OutputEvent}});Object.defineProperty(I,"ThreadEvent",{enumerable:!0,get:function(){return K.ThreadEvent}});Object.defineProperty(I,"BreakpointEvent",{enumerable:!0,get:function(){return K.BreakpointEvent}});Object.defineProperty(I,"ModuleEvent",{enumerable:!0,get:function(){return K.ModuleEvent}});Object.defineProperty(I,"LoadedSourceEvent",{enumerable:!0,get:function(){return K.LoadedSourceEvent}});Object.defineProperty(I,"CapabilitiesEvent",{enumerable:!0,get:function(){return K.CapabilitiesEvent}});Object.defineProperty(I,"ProgressStartEvent",{enumerable:!0,get:function(){return K.ProgressStartEvent}});Object.defineProperty(I,"ProgressUpdateEvent",{enumerable:!0,get:function(){return K.ProgressUpdateEvent}});Object.defineProperty(I,"ProgressEndEvent",{enumerable:!0,get:function(){return K.ProgressEndEvent}});Object.defineProperty(I,"InvalidatedEvent",{enumerable:!0,get:function(){return K.InvalidatedEvent}});Object.defineProperty(I,"MemoryEvent",{enumerable:!0,get:function(){return K.MemoryEvent}});Object.defineProperty(I,"Thread",{enumerable:!0,get:function(){return K.Thread}});Object.defineProperty(I,"StackFrame",{enumerable:!0,get:function(){return K.StackFrame}});Object.defineProperty(I,"Scope",{enumerable:!0,get:function(){return K.Scope}});Object.defineProperty(I,"Variable",{enumerable:!0,get:function(){return K.Variable}});Object.defineProperty(I,"Breakpoint",{enumerable:!0,get:function(){return K.Breakpoint}});Object.defineProperty(I,"Source",{enumerable:!0,get:function(){return K.Source}});Object.defineProperty(I,"Module",{enumerable:!0,get:function(){return K.Module}});Object.defineProperty(I,"CompletionItem",{enumerable:!0,get:function(){return K.CompletionItem}});Object.defineProperty(I,"ErrorDestination",{enumerable:!0,get:function(){return K.ErrorDestination}});var Rc=qi();Object.defineProperty(I,"LoggingDebugSession",{enumerable:!0,get:function(){return Rc.LoggingDebugSession}});var Yi=Jn();I.Logger=Yi;var Vi=qn();Object.defineProperty(I,"Event",{enumerable:!0,get:function(){return Vi.Event}});Object.defineProperty(I,"Response",{enumerable:!0,get:function(){return Vi.Response}});var Mc=ji();Object.defineProperty(I,"Handles",{enumerable:!0,get:function(){return Mc.Handles}});var Dc=Yi.logger;I.logger=Dc});var Nc={};oo(Nc,{activate:()=>Ac,deactivate:()=>Fc});module.exports=Ot(Nc);var C=E(require("vscode")),tr=E(require("path"));var wa=E(require("readline"));function ka(n){return{kill:()=>{}}}function fr(n){let e=hr(n),t=vr(n);wa.createInterface({input:process.stdin,output:void 0,terminal:!1}).on("line",a=>{let s=a.trim();if(!s)return;let i;try{i=JSON.parse(s)}catch{xa({jsonrpc:"2.0",id:0,error:{code:-32700,message:"Parse error"}});return}gr(i,e,t).then(r=>{xa(r)})})}function xa(n){let e=JSON.stringify(n);process.stdout.write(e+`
`)}async function gr(n,e,t){let{id:o,method:a,params:s}=n;switch(a){case"initialize":return{jsonrpc:"2.0",id:o,result:{protocolVersion:"2024-11-05",capabilities:{tools:{}},serverInfo:{name:"luna2d-mcp",version:"0.1.0"}}};case"notifications/initialized":return{jsonrpc:"2.0",id:o,result:{}};case"tools/list":return{jsonrpc:"2.0",id:o,result:{tools:t}};case"tools/call":{let i=s?.name,r=s?.arguments??{},l=e.get(i);if(!l)return{jsonrpc:"2.0",id:o,error:{code:-32601,message:`Unknown tool: ${i}`}};try{let d=await l(r);return{jsonrpc:"2.0",id:o,result:{content:[{type:"text",text:d}]}}}catch(d){return{jsonrpc:"2.0",id:o,result:{content:[{type:"text",text:`Error: ${d instanceof Error?d.message:String(d)}`}],isError:!0}}}}default:return{jsonrpc:"2.0",id:o,error:{code:-32601,message:`Method not found: ${a}`}}}}function hr(n){let{handleRunExample:e,handleGetApiDoc:t,handleListExamples:o,handleRunLuaTest:a,handleCheckBuild:s,handleGetLogs:i}=(io(),Ot(so)),r=new Map;return r.set("luna2d.runExample",e(n)),r.set("luna2d.getApiDoc",t(n)),r.set("luna2d.listExamples",o(n)),r.set("luna2d.runLuaTest",a(n)),r.set("luna2d.checkBuild",s(n)),r.set("luna2d.getLogs",i(n)),r}function vr(n){let{getToolDefinitions:e}=(io(),Ot(so));return e()}if(require.main===module){let n=process.argv.slice(2),e=process.cwd(),t=n.indexOf("--workspace");t!==-1&&n[t+1]&&(e=n[t+1]),fr(e)}var we=E(require("vscode")),xt=E(require("path")),$t=E(require("fs")),Wt=class{process=null;terminal=null;_onStatusChange=new we.EventEmitter;onStatusChange=this._onStatusChange.event;async findLunaBinary(){let e=we.workspace.getConfiguration("luna").get("lunaPath","");if(e&&$t.existsSync(e))return e;let t=process.platform==="win32"?"luna.exe":"luna",o=(process.env.PATH??"").split(xt.delimiter);for(let s of o){let i=xt.join(s,t);if($t.existsSync(i))return i}let a=Sa();if(a){let s=xt.join(a,"Cargo.toml");if($t.existsSync(s))return"cargo run --"}throw new Error("Luna2D binary not found. Install it or set luna.lunaPath in settings.")}async run(e,t=[]){if(this.isRunning()){we.window.showWarningMessage("Luna2D is already running.");return}we.workspace.getConfiguration("luna").get("saveOnRun",!0)&&await we.workspace.saveAll(!1);let a=await this.findLunaBinary(),s=a.startsWith("cargo run")?`${a} ${e} ${t.join(" ")}`.trim():`"${a}" ${e} ${t.join(" ")}`.trim();this.terminal=we.window.createTerminal({name:"Luna2D",cwd:Sa()}),this.terminal.show(),this.terminal.sendText(s),this._onStatusChange.fire(!0),we.commands.executeCommand("setContext","luna.gameRunning",!0)}stop(){this.terminal&&(this.terminal.dispose(),this.terminal=null),this.process&&(this.process.kill(),this.process=null),this._onStatusChange.fire(!1),we.commands.executeCommand("setContext","luna.gameRunning",!1)}isRunning(){return this.terminal!==null}dispose(){this.stop(),this._onStatusChange.dispose()}};function Sa(){return we.workspace.workspaceFolders?.[0]?.uri.fsPath}var nt=E(require("vscode")),Ht=class{item;constructor(){this.item=nt.window.createStatusBarItem(nt.StatusBarAlignment.Left,100),this.setStopped(),this.item.show()}setRunning(){this.item.text="$(play) Luna2D: Running",this.item.tooltip="Luna2D game is running \u2014 click to stop",this.item.command="luna.stopGame",this.item.backgroundColor=new nt.ThemeColor("statusBarItem.warningBackground")}setStopped(){this.item.text="$(rocket) Luna2D",this.item.tooltip="Luna Toolkit \u2014 click to run game",this.item.command="luna.runGame",this.item.backgroundColor=void 0}setDebugConnected(){this.item.text="$(debug-alt) Luna2D: Debug",this.item.tooltip="Luna2D debug bridge connected",this.item.command="luna.debug.status",this.item.backgroundColor=new nt.ThemeColor("statusBarItem.prominentBackground")}dispose(){this.item.dispose()}};var Ca=E(require("vscode")),Ve=E(require("fs")),qt=E(require("path")),yr={DrawMode:{values:["fill","line"],descriptions:new Map([["fill","Filled shape"],["line","Outlined shape"]])},BodyType:{values:["static","dynamic","kinematic"],descriptions:new Map([["static","Does not move"],["dynamic","Full physics simulation"],["kinematic","Moves via velocity only"]])},SourceType:{values:["static","stream"],descriptions:new Map([["static","Fully loaded into memory"],["stream","Streamed from disk"]])},BlendMode:{values:["alpha","add","subtract","multiply","premultiplied","replace","screen"],descriptions:new Map},FilterMode:{values:["nearest","linear"],descriptions:new Map([["nearest","Pixelated (sharp)"],["linear","Smooth (blurred)"]])},WrapMode:{values:["clamp","clampzero","repeat","mirroredrepeat"],descriptions:new Map},ShapeType:{values:["circle","rectangle","polygon","edge","chain"],descriptions:new Map},JointType:{values:["distance","revolute","prismatic","pulley","gear","weld","friction","motor"],descriptions:new Map},AlignMode:{values:["left","center","right","justify"],descriptions:new Map},ArcType:{values:["pie","open","closed"],descriptions:new Map},CompareMode:{values:["equal","notequal","less","lequal","gequal","greater","always","never"],descriptions:new Map},LineJoin:{values:["miter","bevel","none"],descriptions:new Map},LineCap:{values:["butt","round","square"],descriptions:new Map},EasingFunction:{values:["linear","quad","cubic","quart","quint","sine","expo","circ","back","bounce","elastic"],descriptions:new Map}},br=[{name:"load",signature:"luna.load()",description:"Called once after the script is loaded.",params:[]},{name:"update",signature:"luna.update(dt)",description:"Called every frame; `dt` is elapsed seconds.",params:[{name:"dt",type:"number",description:"Delta time in seconds",optional:!1}]},{name:"draw",signature:"luna.draw()",description:"Called every frame for rendering.",params:[]},{name:"keypressed",signature:"luna.keypressed(key)",description:"Called when a keyboard key is pressed.",params:[{name:"key",type:"string",description:"Key name",optional:!1}]},{name:"keyreleased",signature:"luna.keyreleased(key)",description:"Called when a keyboard key is released.",params:[{name:"key",type:"string",description:"Key name",optional:!1}]},{name:"textinput",signature:"luna.textinput(text)",description:"Called on text input.",params:[{name:"text",type:"string",description:"Input character(s)",optional:!1}]},{name:"mousepressed",signature:"luna.mousepressed(x, y, button)",description:"Called when a mouse button is pressed.",params:[{name:"x",type:"number",description:"Mouse X",optional:!1},{name:"y",type:"number",description:"Mouse Y",optional:!1},{name:"button",type:"number",description:"Button index",optional:!1}]},{name:"mousereleased",signature:"luna.mousereleased(x, y, button)",description:"Called when a mouse button is released.",params:[{name:"x",type:"number",description:"Mouse X",optional:!1},{name:"y",type:"number",description:"Mouse Y",optional:!1},{name:"button",type:"number",description:"Button index",optional:!1}]},{name:"wheelmoved",signature:"luna.wheelmoved(x, y)",description:"Called on mouse wheel movement.",params:[{name:"x",type:"number",description:"Horizontal scroll",optional:!1},{name:"y",type:"number",description:"Vertical scroll",optional:!1}]},{name:"gamepadpressed",signature:"luna.gamepadpressed(id, button)",description:"Called on gamepad button press.",params:[{name:"id",type:"number",description:"Gamepad ID",optional:!1},{name:"button",type:"string",description:"Button name",optional:!1}]},{name:"gamepadreleased",signature:"luna.gamepadreleased(id, button)",description:"Called on gamepad button release.",params:[{name:"id",type:"number",description:"Gamepad ID",optional:!1},{name:"button",type:"string",description:"Button name",optional:!1}]},{name:"gamepadaxis",signature:"luna.gamepadaxis(id, axis, value)",description:"Called on gamepad axis change.",params:[{name:"id",type:"number",description:"Gamepad ID",optional:!1},{name:"axis",type:"string",description:"Axis name",optional:!1},{name:"value",type:"number",description:"Axis value",optional:!1}]},{name:"joystickadded",signature:"luna.joystickadded(id)",description:"Called when a gamepad is connected.",params:[{name:"id",type:"number",description:"Gamepad ID",optional:!1}]},{name:"joystickremoved",signature:"luna.joystickremoved(id)",description:"Called when a gamepad is disconnected.",params:[{name:"id",type:"number",description:"Gamepad ID",optional:!1}]},{name:"touchpressed",signature:"luna.touchpressed(id, x, y, dx, dy, pressure)",description:"Called on touch start.",params:[{name:"id",type:"number",description:"Touch ID",optional:!1},{name:"x",type:"number",description:"X position",optional:!1},{name:"y",type:"number",description:"Y position",optional:!1},{name:"dx",type:"number",description:"X delta",optional:!1},{name:"dy",type:"number",description:"Y delta",optional:!1},{name:"pressure",type:"number",description:"Touch pressure",optional:!1}]},{name:"touchmoved",signature:"luna.touchmoved(id, x, y, dx, dy, pressure)",description:"Called on touch move.",params:[{name:"id",type:"number",description:"Touch ID",optional:!1},{name:"x",type:"number",description:"X position",optional:!1},{name:"y",type:"number",description:"Y position",optional:!1},{name:"dx",type:"number",description:"X delta",optional:!1},{name:"dy",type:"number",description:"Y delta",optional:!1},{name:"pressure",type:"number",description:"Touch pressure",optional:!1}]},{name:"touchreleased",signature:"luna.touchreleased(id, x, y, dx, dy, pressure)",description:"Called on touch end.",params:[{name:"id",type:"number",description:"Touch ID",optional:!1},{name:"x",type:"number",description:"X position",optional:!1},{name:"y",type:"number",description:"Y position",optional:!1},{name:"dx",type:"number",description:"X delta",optional:!1},{name:"dy",type:"number",description:"Y delta",optional:!1},{name:"pressure",type:"number",description:"Touch pressure",optional:!1}]},{name:"focus",signature:"luna.focus(has_focus)",description:"Called when window gains or loses focus.",params:[{name:"has_focus",type:"boolean",description:"Whether window has focus",optional:!1}]},{name:"visible",signature:"luna.visible(is_visible)",description:"Called when window visibility changes.",params:[{name:"is_visible",type:"boolean",description:"Whether window is visible",optional:!1}]},{name:"resize",signature:"luna.resize(w, h)",description:"Called when the window is resized.",params:[{name:"w",type:"number",description:"New width",optional:!1},{name:"h",type:"number",description:"New height",optional:!1}]},{name:"quit",signature:"luna.quit()",description:"Called when the window is closed.",params:[]}],xr={string:{common:[{name:"byte",signature:"string.byte(s, i, j)",description:"Returns the internal numeric codes of the characters s[i], s[i+1], ..., s[j].",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"i",type:"number",description:"Start index",optional:!0,default:"1"},{name:"j",type:"number",description:"End index",optional:!0,default:"i"}],returns:"number..."},{name:"char",signature:"string.char(...)",description:"Returns a string with characters with the given internal numeric codes.",params:[{name:"...",type:"number",description:"Byte values",optional:!1}],returns:"string"},{name:"find",signature:"string.find(s, pattern, init, plain)",description:"Looks for the first match of pattern in the string.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"pattern",type:"string",description:"Search pattern",optional:!1},{name:"init",type:"number",description:"Start position",optional:!0,default:"1"},{name:"plain",type:"boolean",description:"Plain text search",optional:!0,default:"false"}],returns:"number, number, ...string"},{name:"format",signature:"string.format(formatstring, ...)",description:"Returns a formatted string following the description given in its arguments.",params:[{name:"formatstring",type:"string",description:"Format string",optional:!1},{name:"...",type:"any",description:"Format arguments",optional:!0}],returns:"string"},{name:"gmatch",signature:"string.gmatch(s, pattern)",description:"Returns an iterator function that returns the next captures from pattern over string s.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"pattern",type:"string",description:"Pattern",optional:!1}],returns:"function"},{name:"gsub",signature:"string.gsub(s, pattern, repl, n)",description:"Returns a copy of s in which all (or the first n) occurrences of the pattern are replaced.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"pattern",type:"string",description:"Pattern",optional:!1},{name:"repl",type:"string|table|function",description:"Replacement",optional:!1},{name:"n",type:"number",description:"Max replacements",optional:!0}],returns:"string, number"},{name:"len",signature:"string.len(s)",description:"Returns the length of the string.",params:[{name:"s",type:"string",description:"Input string",optional:!1}],returns:"number"},{name:"lower",signature:"string.lower(s)",description:"Returns a copy of this string with all uppercase letters changed to lowercase.",params:[{name:"s",type:"string",description:"Input string",optional:!1}],returns:"string"},{name:"match",signature:"string.match(s, pattern, init)",description:"Looks for the first match of pattern in the string.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"pattern",type:"string",description:"Pattern",optional:!1},{name:"init",type:"number",description:"Start position",optional:!0,default:"1"}],returns:"string..."},{name:"rep",signature:"string.rep(s, n, sep)",description:"Returns a string that is the concatenation of n copies of the string s.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"n",type:"number",description:"Repetitions",optional:!1},{name:"sep",type:"string",description:"Separator",optional:!0,default:'""'}],returns:"string"},{name:"reverse",signature:"string.reverse(s)",description:"Returns a string that is the string s reversed.",params:[{name:"s",type:"string",description:"Input string",optional:!1}],returns:"string"},{name:"sub",signature:"string.sub(s, i, j)",description:"Returns the substring from i to j.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"i",type:"number",description:"Start index",optional:!1},{name:"j",type:"number",description:"End index",optional:!0,default:"-1"}],returns:"string"},{name:"upper",signature:"string.upper(s)",description:"Returns a copy of this string with all lowercase letters changed to uppercase.",params:[{name:"s",type:"string",description:"Input string",optional:!1}],returns:"string"},{name:"dump",signature:"string.dump(function, strip)",description:"Returns a string containing a binary representation of the given function.",params:[{name:"function",type:"function",description:"Function to dump",optional:!1},{name:"strip",type:"boolean",description:"Strip debug info",optional:!0}],returns:"string"}]},table:{common:[{name:"concat",signature:"table.concat(list, sep, i, j)",description:"Concatenates elements of a table into a string.",params:[{name:"list",type:"table",description:"Input table",optional:!1},{name:"sep",type:"string",description:"Separator",optional:!0,default:'""'},{name:"i",type:"number",description:"Start index",optional:!0,default:"1"},{name:"j",type:"number",description:"End index",optional:!0,default:"#list"}],returns:"string"},{name:"insert",signature:"table.insert(list, pos, value)",description:"Inserts element value at position pos in list.",params:[{name:"list",type:"table",description:"Target table",optional:!1},{name:"pos",type:"number",description:"Position",optional:!0},{name:"value",type:"any",description:"Value to insert",optional:!1}],returns:"nil"},{name:"remove",signature:"table.remove(list, pos)",description:"Removes from list the element at position pos.",params:[{name:"list",type:"table",description:"Target table",optional:!1},{name:"pos",type:"number",description:"Position",optional:!0,default:"#list"}],returns:"any"},{name:"sort",signature:"table.sort(list, comp)",description:"Sorts list elements in-place using the given comparison function.",params:[{name:"list",type:"table",description:"Table to sort",optional:!1},{name:"comp",type:"function",description:"Comparison function",optional:!0}],returns:"nil"},{name:"unpack",signature:"table.unpack(list, i, j)",description:"Returns the elements from the given table.",params:[{name:"list",type:"table",description:"Input table",optional:!1},{name:"i",type:"number",description:"Start index",optional:!0,default:"1"},{name:"j",type:"number",description:"End index",optional:!0,default:"#list"}],returns:"any..."}],lua54Only:[{name:"move",signature:"table.move(a1, f, e, t, a2)",description:"Moves elements from table a1 into table a2.",params:[{name:"a1",type:"table",description:"Source table",optional:!1},{name:"f",type:"number",description:"From index",optional:!1},{name:"e",type:"number",description:"End index",optional:!1},{name:"t",type:"number",description:"Target start",optional:!1},{name:"a2",type:"table",description:"Dest table",optional:!0,default:"a1"}],returns:"table"},{name:"pack",signature:"table.pack(...)",description:"Returns a new table with all arguments stored into keys 1, 2, etc.",params:[{name:"...",type:"any",description:"Values to pack",optional:!1}],returns:"table"}],luajitOnly:[{name:"new",signature:"table.new(narray, nhash)",description:"Pre-allocates a table with the given number of array and hash slots.",params:[{name:"narray",type:"number",description:"Array slots",optional:!1},{name:"nhash",type:"number",description:"Hash slots",optional:!1}],returns:"table"},{name:"clear",signature:"table.clear(tab)",description:"Clears all keys and values from a table.",params:[{name:"tab",type:"table",description:"Table to clear",optional:!1}],returns:"nil"}]},math:{common:[{name:"abs",signature:"math.abs(x)",description:"Returns the absolute value of x.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"acos",signature:"math.acos(x)",description:"Returns the arc cosine of x (in radians).",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"asin",signature:"math.asin(x)",description:"Returns the arc sine of x (in radians).",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"atan",signature:"math.atan(y, x)",description:"Returns the arc tangent of y/x (in radians).",params:[{name:"y",type:"number",description:"Y value",optional:!1},{name:"x",type:"number",description:"X value",optional:!0,default:"1"}],returns:"number"},{name:"ceil",signature:"math.ceil(x)",description:"Returns the smallest integer larger than or equal to x.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"cos",signature:"math.cos(x)",description:"Returns the cosine of x (in radians).",params:[{name:"x",type:"number",description:"Angle in radians",optional:!1}],returns:"number"},{name:"deg",signature:"math.deg(x)",description:"Converts angle x from radians to degrees.",params:[{name:"x",type:"number",description:"Angle in radians",optional:!1}],returns:"number"},{name:"exp",signature:"math.exp(x)",description:"Returns the value e^x.",params:[{name:"x",type:"number",description:"Exponent",optional:!1}],returns:"number"},{name:"floor",signature:"math.floor(x)",description:"Returns the largest integer smaller than or equal to x.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"fmod",signature:"math.fmod(x, y)",description:"Returns the remainder of the division of x by y.",params:[{name:"x",type:"number",description:"Dividend",optional:!1},{name:"y",type:"number",description:"Divisor",optional:!1}],returns:"number"},{name:"huge",signature:"math.huge",description:"The value HUGE_VAL, representing positive infinity.",params:[],returns:"number"},{name:"log",signature:"math.log(x, base)",description:"Returns the logarithm of x in the given base.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"base",type:"number",description:"Log base",optional:!0,default:"e"}],returns:"number"},{name:"max",signature:"math.max(x, ...)",description:"Returns the maximum value among its arguments.",params:[{name:"x",type:"number",description:"First value",optional:!1},{name:"...",type:"number",description:"More values",optional:!0}],returns:"number"},{name:"min",signature:"math.min(x, ...)",description:"Returns the minimum value among its arguments.",params:[{name:"x",type:"number",description:"First value",optional:!1},{name:"...",type:"number",description:"More values",optional:!0}],returns:"number"},{name:"modf",signature:"math.modf(x)",description:"Returns the integral and fractional parts of x.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number, number"},{name:"pi",signature:"math.pi",description:"The value of pi.",params:[],returns:"number"},{name:"rad",signature:"math.rad(x)",description:"Converts angle x from degrees to radians.",params:[{name:"x",type:"number",description:"Angle in degrees",optional:!1}],returns:"number"},{name:"random",signature:"math.random(m, n)",description:"Returns a pseudo-random number.",params:[{name:"m",type:"number",description:"Lower bound",optional:!0},{name:"n",type:"number",description:"Upper bound",optional:!0}],returns:"number"},{name:"randomseed",signature:"math.randomseed(x)",description:"Sets x as the seed for the pseudo-random generator.",params:[{name:"x",type:"number",description:"Seed value",optional:!1}],returns:"nil"},{name:"sin",signature:"math.sin(x)",description:"Returns the sine of x (in radians).",params:[{name:"x",type:"number",description:"Angle in radians",optional:!1}],returns:"number"},{name:"sqrt",signature:"math.sqrt(x)",description:"Returns the square root of x.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"tan",signature:"math.tan(x)",description:"Returns the tangent of x (in radians).",params:[{name:"x",type:"number",description:"Angle in radians",optional:!1}],returns:"number"}],lua54Only:[{name:"maxinteger",signature:"math.maxinteger",description:"An integer with the maximum value for an integer.",params:[],returns:"integer"},{name:"mininteger",signature:"math.mininteger",description:"An integer with the minimum value for an integer.",params:[],returns:"integer"},{name:"tointeger",signature:"math.tointeger(x)",description:"If x is convertible to an integer, returns that integer.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"integer|nil"},{name:"type",signature:"math.type(x)",description:"Returns 'integer', 'float', or false.",params:[{name:"x",type:"any",description:"Value to check",optional:!1}],returns:"string|false"},{name:"ult",signature:"math.ult(m, n)",description:"Returns true if m < n when compared as unsigned integers.",params:[{name:"m",type:"integer",description:"First value",optional:!1},{name:"n",type:"integer",description:"Second value",optional:!1}],returns:"boolean"}]},os:{common:[{name:"clock",signature:"os.clock()",description:"Returns CPU time used by the program in seconds.",params:[],returns:"number"},{name:"date",signature:"os.date(format, time)",description:"Returns a string or table with date and time.",params:[{name:"format",type:"string",description:"Date format",optional:!0,default:'"%c"'},{name:"time",type:"number",description:"Time value",optional:!0}],returns:"string|table"},{name:"difftime",signature:"os.difftime(t2, t1)",description:"Returns the difference in seconds between two times.",params:[{name:"t2",type:"number",description:"End time",optional:!1},{name:"t1",type:"number",description:"Start time",optional:!1}],returns:"number"},{name:"time",signature:"os.time(table)",description:"Returns the current time or converts the given table to a timestamp.",params:[{name:"table",type:"table",description:"Date table",optional:!0}],returns:"number"}]},io:{common:[{name:"close",signature:"io.close(file)",description:"Closes file, or the default output file.",params:[{name:"file",type:"file",description:"File handle",optional:!0}],returns:"boolean"},{name:"lines",signature:"io.lines(filename, ...)",description:"Opens the given file and returns an iterator function.",params:[{name:"filename",type:"string",description:"File path",optional:!0},{name:"...",type:"string|number",description:"Read formats",optional:!0}],returns:"function"},{name:"open",signature:"io.open(filename, mode)",description:"Opens a file in the given mode.",params:[{name:"filename",type:"string",description:"File path",optional:!1},{name:"mode",type:"string",description:"Open mode",optional:!0,default:'"r"'}],returns:"file|nil, string"},{name:"read",signature:"io.read(...)",description:"Reads from the default input file.",params:[{name:"...",type:"string|number",description:"Read formats",optional:!0}],returns:"string|number|nil"},{name:"write",signature:"io.write(...)",description:"Writes to the default output file.",params:[{name:"...",type:"string|number",description:"Values to write",optional:!1}],returns:"file|nil, string"},{name:"type",signature:"io.type(obj)",description:"Checks whether obj is a valid file handle.",params:[{name:"obj",type:"any",description:"Value to check",optional:!1}],returns:"string|nil"}]},coroutine:{common:[{name:"create",signature:"coroutine.create(f)",description:"Creates a new coroutine with body f.",params:[{name:"f",type:"function",description:"Coroutine body",optional:!1}],returns:"thread"},{name:"resume",signature:"coroutine.resume(co, ...)",description:"Starts or continues the execution of coroutine co.",params:[{name:"co",type:"thread",description:"Coroutine",optional:!1},{name:"...",type:"any",description:"Arguments",optional:!0}],returns:"boolean, any..."},{name:"yield",signature:"coroutine.yield(...)",description:"Suspends the execution of the calling coroutine.",params:[{name:"...",type:"any",description:"Values to yield",optional:!0}],returns:"any..."},{name:"status",signature:"coroutine.status(co)",description:"Returns the status of coroutine co.",params:[{name:"co",type:"thread",description:"Coroutine",optional:!1}],returns:"string"},{name:"wrap",signature:"coroutine.wrap(f)",description:"Creates a coroutine and returns a resume function.",params:[{name:"f",type:"function",description:"Coroutine body",optional:!1}],returns:"function"},{name:"isyieldable",signature:"coroutine.isyieldable()",description:"Returns true if the running coroutine can yield.",params:[],returns:"boolean"},{name:"running",signature:"coroutine.running()",description:"Returns the running coroutine plus a boolean.",params:[],returns:"thread, boolean"}]},debug:{common:[{name:"getinfo",signature:"debug.getinfo(f, what)",description:"Returns a table with information about a function.",params:[{name:"f",type:"function|number",description:"Function or stack level",optional:!1},{name:"what",type:"string",description:"Info selector",optional:!0}],returns:"table"},{name:"getlocal",signature:"debug.getlocal(f, local)",description:"Returns name and value of local variable.",params:[{name:"f",type:"function|number",description:"Function or stack level",optional:!1},{name:"local",type:"number",description:"Local index",optional:!1}],returns:"string, any"},{name:"sethook",signature:"debug.sethook(hook, mask, count)",description:"Sets the given function as a hook.",params:[{name:"hook",type:"function",description:"Hook function",optional:!1},{name:"mask",type:"string",description:"Hook mask",optional:!1},{name:"count",type:"number",description:"Instruction count",optional:!0}],returns:"nil"},{name:"traceback",signature:"debug.traceback(message, level)",description:"Returns a string with a traceback of the call stack.",params:[{name:"message",type:"string",description:"Prefix message",optional:!0},{name:"level",type:"number",description:"Stack level",optional:!0,default:"1"}],returns:"string"}]},package:{common:[{name:"loaded",signature:"package.loaded",description:"A table of already-loaded modules.",params:[],returns:"table"},{name:"path",signature:"package.path",description:"The path used by require to search for a Lua loader.",params:[],returns:"string"},{name:"preload",signature:"package.preload",description:"A table to store loaders for specific modules.",params:[],returns:"table"},{name:"searchpath",signature:"package.searchpath(name, path, sep, rep)",description:"Searches for the given name in the given path.",params:[{name:"name",type:"string",description:"Module name",optional:!1},{name:"path",type:"string",description:"Search path",optional:!1},{name:"sep",type:"string",description:"Name separator",optional:!0,default:'"."'},{name:"rep",type:"string",description:"Replacement",optional:!0,default:'"/"'}],returns:"string|nil, string"}]},utf8:{common:[],lua54Only:[{name:"char",signature:"utf8.char(...)",description:"Returns a UTF-8 string from one or more codepoints.",params:[{name:"...",type:"number",description:"Codepoints",optional:!1}],returns:"string"},{name:"codepoint",signature:"utf8.codepoint(s, i, j)",description:"Returns the codepoints of all characters in s between positions i and j.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"i",type:"number",description:"Start",optional:!0,default:"1"},{name:"j",type:"number",description:"End",optional:!0,default:"i"}],returns:"number..."},{name:"codes",signature:"utf8.codes(s)",description:"Returns an iterator for all codepoints in string s.",params:[{name:"s",type:"string",description:"Input string",optional:!1}],returns:"function"},{name:"len",signature:"utf8.len(s, i, j)",description:"Returns the number of UTF-8 characters in string s.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"i",type:"number",description:"Start byte",optional:!0,default:"1"},{name:"j",type:"number",description:"End byte",optional:!0,default:"-1"}],returns:"number|nil, number"},{name:"offset",signature:"utf8.offset(s, n, i)",description:"Returns the byte position where the n-th character starts.",params:[{name:"s",type:"string",description:"Input string",optional:!1},{name:"n",type:"number",description:"Character offset",optional:!1},{name:"i",type:"number",description:"Start byte",optional:!0}],returns:"number"},{name:"charpattern",signature:"utf8.charpattern",description:"The pattern that matches exactly one UTF-8 byte sequence.",params:[],returns:"string"}]},bit:{common:[],luajitOnly:[{name:"tobit",signature:"bit.tobit(x)",description:"Normalizes a number to the numeric range of a 32-bit integer.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"tohex",signature:"bit.tohex(x, n)",description:"Converts x to a hex string with n digits.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"n",type:"number",description:"Number of digits",optional:!0}],returns:"string"},{name:"bnot",signature:"bit.bnot(x)",description:"Returns the bitwise NOT of x.",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"},{name:"band",signature:"bit.band(x1, ...)",description:"Returns the bitwise AND of all arguments.",params:[{name:"x1",type:"number",description:"First value",optional:!1},{name:"...",type:"number",description:"More values",optional:!0}],returns:"number"},{name:"bor",signature:"bit.bor(x1, ...)",description:"Returns the bitwise OR of all arguments.",params:[{name:"x1",type:"number",description:"First value",optional:!1},{name:"...",type:"number",description:"More values",optional:!0}],returns:"number"},{name:"bxor",signature:"bit.bxor(x1, ...)",description:"Returns the bitwise XOR of all arguments.",params:[{name:"x1",type:"number",description:"First value",optional:!1},{name:"...",type:"number",description:"More values",optional:!0}],returns:"number"},{name:"lshift",signature:"bit.lshift(x, n)",description:"Returns x logically shifted left by n bits.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"n",type:"number",description:"Shift amount",optional:!1}],returns:"number"},{name:"rshift",signature:"bit.rshift(x, n)",description:"Returns x logically shifted right by n bits.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"n",type:"number",description:"Shift amount",optional:!1}],returns:"number"},{name:"arshift",signature:"bit.arshift(x, n)",description:"Returns x arithmetically shifted right by n bits.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"n",type:"number",description:"Shift amount",optional:!1}],returns:"number"},{name:"rol",signature:"bit.rol(x, n)",description:"Returns x rotated left by n bits.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"n",type:"number",description:"Rotation amount",optional:!1}],returns:"number"},{name:"ror",signature:"bit.ror(x, n)",description:"Returns x rotated right by n bits.",params:[{name:"x",type:"number",description:"Input value",optional:!1},{name:"n",type:"number",description:"Rotation amount",optional:!1}],returns:"number"},{name:"bswap",signature:"bit.bswap(x)",description:"Swaps the bytes of x (byte-reverse).",params:[{name:"x",type:"number",description:"Input value",optional:!1}],returns:"number"}]},jit:{common:[],luajitOnly:[{name:"on",signature:"jit.on(func, recursive)",description:"Enables JIT compilation.",params:[{name:"func",type:"function",description:"Function or true for all",optional:!0},{name:"recursive",type:"boolean",description:"Include sub-functions",optional:!0}],returns:"nil"},{name:"off",signature:"jit.off(func, recursive)",description:"Disables JIT compilation.",params:[{name:"func",type:"function",description:"Function or true for all",optional:!0},{name:"recursive",type:"boolean",description:"Include sub-functions",optional:!0}],returns:"nil"},{name:"flush",signature:"jit.flush(func, recursive)",description:"Flushes the compiled code cache.",params:[{name:"func",type:"function",description:"Function to flush",optional:!0},{name:"recursive",type:"boolean",description:"Include sub-functions",optional:!0}],returns:"nil"},{name:"status",signature:"jit.status()",description:"Returns the current JIT status and architecture.",params:[],returns:"boolean, string..."},{name:"version",signature:"jit.version",description:"The LuaJIT version string.",params:[],returns:"string"},{name:"version_num",signature:"jit.version_num",description:"The LuaJIT version number.",params:[],returns:"number"},{name:"os",signature:"jit.os",description:"The target OS name.",params:[],returns:"string"},{name:"arch",signature:"jit.arch",description:"The target architecture name.",params:[],returns:"string"}]},ffi:{common:[],luajitOnly:[{name:"cdef",signature:"ffi.cdef(def)",description:"Adds C declarations.",params:[{name:"def",type:"string",description:"C declarations",optional:!1}],returns:"nil"},{name:"new",signature:"ffi.new(ctype, ...)",description:"Creates a C data object of the given type.",params:[{name:"ctype",type:"string|ctype",description:"C type",optional:!1},{name:"...",type:"any",description:"Initializers",optional:!0}],returns:"cdata"},{name:"cast",signature:"ffi.cast(ctype, init)",description:"Creates a scalar C data object with ctype and init.",params:[{name:"ctype",type:"string|ctype",description:"Target type",optional:!1},{name:"init",type:"any",description:"Initial value",optional:!1}],returns:"cdata"},{name:"typeof",signature:"ffi.typeof(ctype)",description:"Creates a C type object.",params:[{name:"ctype",type:"string",description:"C type declaration",optional:!1}],returns:"ctype"},{name:"sizeof",signature:"ffi.sizeof(ctype, nelem)",description:"Returns the size of a C type in bytes.",params:[{name:"ctype",type:"string|ctype|cdata",description:"C type",optional:!1},{name:"nelem",type:"number",description:"Number of elements",optional:!0}],returns:"number"},{name:"alignof",signature:"ffi.alignof(ctype)",description:"Returns the minimum required alignment of a C type.",params:[{name:"ctype",type:"string|ctype",description:"C type",optional:!1}],returns:"number"},{name:"istype",signature:"ffi.istype(ctype, obj)",description:"Returns true if obj has the given C type.",params:[{name:"ctype",type:"string|ctype",description:"C type",optional:!1},{name:"obj",type:"any",description:"Object to check",optional:!1}],returns:"boolean"},{name:"load",signature:"ffi.load(name, global)",description:"Loads a shared library.",params:[{name:"name",type:"string",description:"Library name",optional:!1},{name:"global",type:"boolean",description:"Export symbols globally",optional:!0}],returns:"clib"},{name:"string",signature:"ffi.string(ptr, len)",description:"Creates a Lua string from a C char pointer.",params:[{name:"ptr",type:"cdata",description:"Char pointer",optional:!1},{name:"len",type:"number",description:"Length",optional:!0}],returns:"string"},{name:"copy",signature:"ffi.copy(dst, src, len)",description:"Copies data between C objects.",params:[{name:"dst",type:"cdata",description:"Destination",optional:!1},{name:"src",type:"cdata|string",description:"Source",optional:!1},{name:"len",type:"number",description:"Byte count",optional:!0}],returns:"nil"},{name:"fill",signature:"ffi.fill(dst, len, c)",description:"Fills a memory region with a byte value.",params:[{name:"dst",type:"cdata",description:"Destination",optional:!1},{name:"len",type:"number",description:"Byte count",optional:!1},{name:"c",type:"number",description:"Fill byte",optional:!0,default:"0"}],returns:"nil"},{name:"gc",signature:"ffi.gc(cdata, finalizer)",description:"Associates a finalizer with a C data object.",params:[{name:"cdata",type:"cdata",description:"C data object",optional:!1},{name:"finalizer",type:"function",description:"Finalizer function",optional:!1}],returns:"cdata"}]}},jt=class{modules=new Map;allFunctions=new Map;enums=new Map;methodsByObjectType=new Map;callbackList=[];loaded=!1;async load(e){if(this.loaded)return;let t=Ca.workspace.workspaceFolders?.[0]?.uri.fsPath;if(t){let a=qt.join(t,"docs","api_data.json");if(Ve.existsSync(a))try{let s=Ve.readFileSync(a,"utf-8");this.loadFromJson(JSON.parse(s)),this.initEnums(),this.initCallbacks(),this.loaded=!0;return}catch{}}let o=qt.join(e,"data","api-data.json");if(Ve.existsSync(o))try{let a=Ve.readFileSync(o,"utf-8");this.loadFromJson(JSON.parse(a)),this.initEnums(),this.initCallbacks(),this.loaded=!0;return}catch{}if(t){let a=qt.join(t,"docs","lua_api_reference_generated.md");if(Ve.existsSync(a))try{let s=Ve.readFileSync(a,"utf-8");this.loadFromMarkdown(s),this.initEnums(),this.initCallbacks(),this.loaded=!0;return}catch{}}this.loadFallback(),this.initEnums(),this.initCallbacks(),this.loaded=!0}getModuleNames(){return Array.from(this.modules.keys())}getModule(e){return this.modules.get(e)}getFunctions(e){return this.modules.get(e)?.functions??[]}getFunction(e){return this.allFunctions.get(e)}getAllFunctions(){return Array.from(this.allFunctions.values())}searchFunctions(e){let t=e.toLowerCase(),o=[];for(let a of this.allFunctions.values())(a.fullPath.toLowerCase().includes(t)||a.name.toLowerCase().includes(t)||a.description.toLowerCase().includes(t))&&o.push(a);return o}getMethods(e){return this.methodsByObjectType.get(e)??[]}getMethod(e,t){return this.methodsByObjectType.get(e)?.find(a=>a.name===t)}getEnumValues(e){return this.enums.get(e)?.values??[]}getEnum(e){return this.enums.get(e)}getCallbacks(){return this.callbackList}getLuaStdlib(e){let t=[];for(let[o,a]of Object.entries(xr)){for(let s of a.common)t.push(this.stdlibToApiFunction(o,s));if(e==="5.4"&&a.lua54Only)for(let s of a.lua54Only)t.push(this.stdlibToApiFunction(o,s));if(e==="luajit"&&a.luajitOnly)for(let s of a.luajitOnly)t.push(this.stdlibToApiFunction(o,s))}return t}getStats(){let e=0,t=0,o=0;for(let a of this.modules.values())e+=a.functions.length,t+=a.methods.length,o+=a.documentedEntries;return{modules:this.modules.size,functions:e,methods:t,documented:o}}loadFromJson(e){if(!e||typeof e!="object")return;let t=e;if(Array.isArray(t.modules))for(let o of t.modules){let a=String(o.name??""),s={name:a,fullPath:`luna.${a}`,description:String(o.description??""),functions:[],methods:[],totalEntries:0,documentedEntries:0},i=Array.isArray(o.functions)?o.functions:[];for(let l of i){let d=this.rawToApiFunction(a,l);d.isMethod?(s.methods.push(d),this.indexMethod(d)):s.functions.push(d),this.allFunctions.set(d.fullPath,d)}let r=Array.isArray(o.methods)?o.methods:[];for(let l of r){let d=this.rawToApiFunction(a,l);d.isMethod=!0,s.methods.push(d),this.indexMethod(d),this.allFunctions.set(d.fullPath,d)}s.totalEntries=s.functions.length+s.methods.length,s.documentedEntries=[...s.functions,...s.methods].filter(l=>l.description.length>0).length,this.modules.set(a,s)}}rawToApiFunction(e,t){let o=String(t.name??""),a=String(t.fullPath??`luna.${e}.${o}`),s=Array.isArray(t.parameters)?t.parameters.map(i=>({name:String(i.name??""),type:String(i.type??"any"),description:String(i.description??""),optional:!!i.optional,default:i.default!=null?String(i.default):void 0})):[];return{module:e,name:o,fullPath:a,signature:String(t.signature??`${a}(${s.map(i=>i.name).join(", ")})`),description:String(t.description??""),parameters:s,returns:t.returns!=null?String(t.returns):void 0,returnType:t.returnType!=null?String(t.returnType):void 0,since:t.since!=null?String(t.since):void 0,deprecated:t.deprecated!=null?String(t.deprecated):void 0,isMethod:!!t.isMethod,objectType:t.objectType!=null?String(t.objectType):void 0,sourceFile:t.sourceFile!=null?String(t.sourceFile):void 0}}loadFromMarkdown(e){let t=e.split(`
`),o=null,a=null,s=null,i=!1,r=!1,l=()=>{if(!a||!o||!a.name){a=null,i=!1;return}let d=(a.description??"").trim();d=d.replace(/\s*Luna [\w]+ API function\.\s*/g," ").trim();let c={module:o.name,name:a.name,fullPath:a.fullPath??`luna.${o.name}.${a.name}`,signature:a.signature??"",description:d,parameters:a.parameters??[],returns:a.returns,returnType:a.returnType??Ea(a.returns),since:a.since,deprecated:a.deprecated,isMethod:a.isMethod??!1,objectType:a.objectType,sourceFile:a.sourceFile};if(!c.signature){let u=c.parameters.map(h=>h.optional?`[${h.name}]`:h.name).join(", ");c.signature=c.isMethod?`${c.objectType??"obj"}:${c.name}(${u})`:`${c.fullPath}(${u})`}c.isMethod?(o.methods.push(c),this.indexMethod(c)):o.functions.push(c),this.allFunctions.set(c.fullPath,c),a=null,i=!1};for(let d=0;d<t.length;d++){let c=t[d],u=c.match(/^## (?:luna\.)?(\w+)/);if(u&&!c.startsWith("## Contents")&&!c.startsWith("## Callbacks")){l(),o&&(o.totalEntries=o.functions.length+o.methods.length,o.documentedEntries=[...o.functions,...o.methods].filter(k=>k.description.length>0).length,this.modules.set(o.name,o));let v=u[1].toLowerCase().replace(/-/g,"_");o={name:v,fullPath:`luna.${v}`,description:"",functions:[],methods:[],totalEntries:0,documentedEntries:0},s=null,r=!1;let y=d+1<t.length?t[d+1]:"";y&&!y.startsWith("#")&&!y.startsWith("*")&&y.trim().length>0&&(o.description=y.trim());let x=(t[d+1]??t[d+2]??"").match(/\*(\d+)\s+entries?\s*\|\s*(\d+)\s+documented\*/);x&&(o.totalEntries=parseInt(x[1],10),o.documentedEntries=parseInt(x[2],10));continue}let h=c.match(/^### (?:(\w+)\s+)?Methods$/);if(h&&o){l(),r=!0,s=h[1]??null;continue}if(c.match(/^### Functions$/)){l(),r=!1,s=null;continue}let p=c.match(/^#{3,4}\s+`?luna\.(\w+)\.(\w+)(?:\(([^)]*)\))?`?/);if(p&&o){l();let[,,v,y]=p,b=y?y.split(",").map(x=>x.trim().replace(/[\[\]]/g,"")).filter(Boolean):[];a={name:v,fullPath:`luna.${o.name}.${v}`,signature:`luna.${o.name}.${v}(${y??""})`,description:"",parameters:b.map(x=>({name:x,type:"any",description:"",optional:x.startsWith("[")||y?.includes(`[${x}]`)||!1})),isMethod:!1};continue}let f=c.match(/^#{3,4}\s+`?(\w+):(\w+)(?:\(([^)]*)\))?`?\s*$/);if(f&&o){l();let[,v,y,b]=f,x=b?b.split(",").map(k=>k.trim().replace(/[\[\]]/g,"")).filter(Boolean):[];s=v,a={name:y,fullPath:`luna.${o.name}.${v}:${y}`,signature:`${v}:${y}(${b??""})`,description:"",parameters:x.map(k=>({name:k,type:"any",description:"",optional:!1})),isMethod:!0,objectType:v};continue}if(!a)continue;if(/^\*\*Parameters:?\*\*/i.test(c)){if(c.match(/^\*\*Parameters:?\*\*\s+`([^`]+)`(?:,\s*`([^`]+)`)*$/)){let y=c.match(/`(\w+)`/g);if(y){let b=new Set((a.parameters??[]).map(x=>x.name));for(let x of y){let k=x.replace(/`/g,"");b.has(k)||(a.parameters=a.parameters??[],a.parameters.push({name:k,type:"any",description:"",optional:!1}))}}}else i=!0;continue}if(i&&c.match(/^- `[^`]+`/)){let v=c.match(/^- `([^`]+)`(?:,\s*`([^`]+)`)?\s*—\s*([^—]+?)\s*—\s*(.+)/);if(v){let[,x,k,F,q]=v;this.upsertParam(a,x,F.trim(),q.trim()),k&&this.upsertParam(a,k,F.trim(),q.trim());continue}let y=c.match(/^- `([^`]+)`(?:,\s*`([^`]+)`)?\s*—\s*(.*)/);if(y){let[,x,k,F]=y,q=F.match(/^`(\w+)`[:\s]\s*(.*)/);if(q)this.upsertParam(a,x,q[1],q[2].trim());else{let ae=wr(F);this.upsertParam(a,x,ae,F.trim())}k&&this.upsertParam(a,k,"any","");continue}let b=c.match(/^- `(\w+)`\s*$/);if(b){this.upsertParam(a,b[1],"any","");continue}continue}i&&!c.startsWith("-")&&c.trim()!==""&&(i=!1);let g=c.match(/^\*\*Returns:?\*\*\s*(.*)/i);if(g){let v=g[1].trim();a.returns=v,a.returnType=Ea(v);continue}let m=c.match(/^\*Source:\s*\[([^\]]+)\]/);if(m){a.sourceFile=m[1];continue}if(!i&&c.trim().length>0&&!c.startsWith("#")&&!c.startsWith("*Source:")&&!c.startsWith("---")&&!c.startsWith("*")&&!c.match(/^Lua API:/)){let v=a.description??"";a.description=v?`${v} ${c.trim()}`:c.trim()}}l(),o&&(o.totalEntries=o.functions.length+o.methods.length,o.documentedEntries=[...o.functions,...o.methods].filter(d=>d.description.length>0).length,this.modules.set(o.name,o))}upsertParam(e,t,o,a){e.parameters=e.parameters??[];let s=e.parameters.find(i=>i.name===t);if(s)o!=="any"&&(s.type=o),a&&(s.description=a);else{let i=a.toLowerCase().startsWith("optional")||a.includes("(default")||t.startsWith("["),r=t.replace(/[\[\]]/g,""),l,d=a.match(/\(default[:\s]+([^)]+)\)/i);d&&(l=d[1].trim()),e.parameters.push({name:r,type:o,description:a,optional:i,default:l})}}indexMethod(e){let t=e.objectType;if(!t)return;let o=this.methodsByObjectType.get(t);o||(o=[],this.methodsByObjectType.set(t,o)),o.push(e)}initEnums(){for(let[e,t]of Object.entries(yr))this.enums.set(e,{name:e,values:t.values,descriptions:t.descriptions})}initCallbacks(){this.callbackList=br.map(e=>({module:"",name:e.name,fullPath:`luna.${e.name}`,signature:e.signature,description:e.description,parameters:e.params,isMethod:!1}))}stdlibToApiFunction(e,t){return{module:e,name:t.name,fullPath:`${e}.${t.name}`,signature:t.signature,description:t.description,parameters:t.params,returns:t.returns,returnType:t.returns,isMethod:!1}}loadFallback(){let e=[["graphics","Drawing and rendering functions",[["draw","Draws a drawable object at the specified position",["drawable","x","y","r","sx","sy","ox","oy"]],["rectangle","Draws a rectangle",["mode","x","y","width","height"]],["circle","Draws a circle",["mode","x","y","radius"]],["line","Draws a line between points",["x1","y1","x2","y2"]],["setColor","Sets the active drawing color (0-1 range)",["r","g","b","a"]],["setBackgroundColor","Sets the background color",["r","g","b"]],["newImage","Loads an image from file",["path"]],["newCanvas","Creates an off-screen canvas",["width","height"]],["newFont","Loads a font from file",["path","size"]],["newShader","Creates a shader from source",["code"]],["print","Draws text at position",["text","x","y"]],["push","Pushes the current transform onto the stack",[]],["pop","Pops the current transform from the stack",[]],["translate","Translates the coordinate system",["dx","dy"]],["rotate","Rotates the coordinate system",["angle"]],["scale","Scales the coordinate system",["sx","sy"]],["clear","Clears the screen with current background color",["r","g","b"]],["getWidth","Returns the window width in pixels",[]],["getHeight","Returns the window height in pixels",[]],["arc","Draws an arc",["mode","x","y","radius","angle1","angle2"]],["polygon","Draws a polygon",["mode","...vertices"]],["ellipse","Draws an ellipse",["mode","x","y","rx","ry"]],["points","Draws points at positions",["...coords"]],["setLineWidth","Sets the line width",["width"]],["getLineWidth","Returns the current line width",[]],["setFont","Sets the active font",["font"]],["origin","Resets the transform to identity",[]]]],["audio","Audio playback and management",[["newSource","Creates a new audio source from file",["path","type"]],["play","Plays an audio source",["source"]],["stop","Stops an audio source",["source"]],["pause","Pauses an audio source",["source"]],["setVolume","Sets the master volume (0-1)",["volume"]],["getVolume","Returns the master volume",[]]]],["physics","2D physics simulation with rapier2d",[["newWorld","Creates a new physics world",["gx","gy"]],["newBody","Creates a new rigid body",["world","x","y","type"]],["newRectangleShape","Attaches a rectangle collider",["body","w","h"]],["newCircleShape","Attaches a circle collider",["body","radius"]],["newEdgeShape","Attaches an edge collider",["body","x1","y1","x2","y2"]],["newPolygonShape","Attaches a polygon collider",["body","...vertices"]]]],["input","Keyboard, mouse, and gamepad input",[["isDown","Checks if a keyboard key is currently pressed",["key"]],["isUp","Checks if a keyboard key is not pressed",["key"]],["getMousePosition","Returns mouse x, y coordinates",[]],["getMouseX","Returns the mouse X position",[]],["getMouseY","Returns the mouse Y position",[]],["isMouseDown","Checks if a mouse button is pressed",["button"]],["getGamepadAxis","Returns gamepad axis value",["id","axis"]],["isGamepadDown","Checks if gamepad button is pressed",["id","button"]]]],["timer","Timing and frame management",[["getTime","Returns total elapsed time in seconds",[]],["getDelta","Returns delta time for current frame",[]],["getFPS","Returns current frames per second",[]],["sleep","Pauses execution for duration",["seconds"]],["average","Returns average frame time",[]]]],["window","Window management and display",[["setTitle","Sets the window title",["title"]],["getTitle","Returns the window title",[]],["setMode","Sets the window dimensions",["width","height","flags"]],["getWidth","Returns the window width",[]],["getHeight","Returns the window height",[]],["setFullscreen","Toggles fullscreen mode",["fullscreen"]],["isFullscreen","Returns whether window is fullscreen",[]],["setIcon","Sets the window icon",["imagedata"]],["close","Closes the window",[]],["minimize","Minimizes the window",[]],["maximize","Maximizes the window",[]],["restore","Restores the window from minimize/maximize",[]]]],["math","Mathematical utility functions",[["random","Returns a random number",["min","max"]],["noise","Generates Perlin noise value",["x","y","z"]],["lerp","Linearly interpolates between two values",["a","b","t"]],["clamp","Clamps a value between min and max",["x","min","max"]],["distance","Returns distance between two points",["x1","y1","x2","y2"]],["angle","Returns angle between two points",["x1","y1","x2","y2"]],["normalize","Normalizes a vector",["x","y"]]]],["filesystem","Sandboxed file I/O",[["read","Reads a file as a string",["path"]],["write","Writes a string to a file",["path","data"]],["exists","Checks if a file exists",["path"]],["getDirectoryItems","Lists items in a directory",["path"]],["createDirectory","Creates a directory",["path"]],["remove","Removes a file",["path"]],["isFile","Checks if path is a file",["path"]],["isDirectory","Checks if path is a directory",["path"]]]],["system","System information and utilities",[["getOS","Returns the operating system name",[]],["getClipboardText","Returns clipboard text content",[]],["setClipboardText","Sets clipboard text content",["text"]],["quit","Quits the application",[]],["openURL","Opens a URL in the default browser",["url"]]]]];for(let[t,o,a]of e){let s={name:t,fullPath:`luna.${t}`,description:o,functions:[],methods:[],totalEntries:0,documentedEntries:0};for(let[i,r,l]of a){let d={module:t,name:i,fullPath:`luna.${t}.${i}`,signature:`luna.${t}.${i}(${l.join(", ")})`,description:r,parameters:l.map(c=>({name:c,type:"any",description:"",optional:!1})),isMethod:!1};s.functions.push(d),this.allFunctions.set(d.fullPath,d)}s.totalEntries=s.functions.length,s.documentedEntries=s.functions.filter(i=>i.description.length>0).length,this.modules.set(t,s)}}};function Ea(n){if(!n)return;let e=n.toLowerCase();return e==="nil"||e==="none"?"nil":e.startsWith("number")||e.startsWith("`number`")?"number":e.startsWith("string")||e.startsWith("`string`")?"string":e.startsWith("boolean")||e.startsWith("`boolean`")?"boolean":e.startsWith("table")||e.startsWith("`table`")?"table":e.startsWith("integer")||e.startsWith("`integer`")?"number":e.startsWith("function")||e.startsWith("`function`")?"function":e.includes(",")?"multiple":n}function wr(n){let e=n.toLowerCase();return e.includes("boolean")?"boolean":e.includes("string")||e.includes("name")?"string":e.includes("pixel")||e.includes("coordinate")||e.includes("number")||e.includes("angle")||e.includes("radius")||e.includes("width")||e.includes("height")||e.includes("scale")||e.includes("factor")||e.includes("offset")||e.includes("index")||e.includes("integer")?"number":e.includes("table")?"table":e.includes("function")||e.includes("callback")?"function":e.includes("draw mode")||e.includes("'fill'")||e.includes("'line'")?"DrawMode":e.includes("blend mode")?"BlendMode":"any"}var w=E(require("vscode")),S=class extends w.TreeItem{constructor(t,o,a,s){super(t,o);this.label=t;this.collapsibleState=o;this.commandId=a;this.icon=s;a&&(this.command={command:a,title:t}),s&&(this.iconPath=new w.ThemeIcon(s))}},Yt=class{_onDidChangeTreeData=new w.EventEmitter;onDidChangeTreeData=this._onDidChangeTreeData.event;refresh(){this._onDidChangeTreeData.fire(void 0)}getTreeItem(e){return e}getChildren(e){if(!e)return[new S("Create",w.TreeItemCollapsibleState.Expanded,void 0,"new-folder"),new S("Package",w.TreeItemCollapsibleState.Collapsed,void 0,"package"),new S("Libraries",w.TreeItemCollapsibleState.Collapsed,void 0,"library")];switch(e.label){case"Create":return[new S("New Project from Template",w.TreeItemCollapsibleState.None,"luna.scaffold.project","file-add"),new S("New File from Template",w.TreeItemCollapsibleState.None,"luna.scaffold.file","new-file")];case"Package":return[new S("Package .zip",w.TreeItemCollapsibleState.None,"luna.package.zip","file-zip"),new S("Package for Windows",w.TreeItemCollapsibleState.None,"luna.package.windows","desktop-download"),new S("Package for Linux",w.TreeItemCollapsibleState.None,"luna.package.linux","terminal-linux")];case"Libraries":return[new S("Install Library",w.TreeItemCollapsibleState.None,"luna.library.install","cloud-download"),new S("List Libraries",w.TreeItemCollapsibleState.None,"luna.library.list","list-unordered")];default:return[]}}},Vt=class{_onDidChangeTreeData=new w.EventEmitter;onDidChangeTreeData=this._onDidChangeTreeData.event;refresh(){this._onDidChangeTreeData.fire(void 0)}getTreeItem(e){return e}getChildren(e){if(!e)return[new S("Run",w.TreeItemCollapsibleState.Expanded,void 0,"play"),new S("Testing",w.TreeItemCollapsibleState.Collapsed,void 0,"beaker"),new S("Editors",w.TreeItemCollapsibleState.Collapsed,void 0,"window"),new S("Debug",w.TreeItemCollapsibleState.Collapsed,void 0,"bug"),new S("Reference",w.TreeItemCollapsibleState.Collapsed,void 0,"book"),new S("Assets",w.TreeItemCollapsibleState.Collapsed,void 0,"file-media"),new S("Dependencies",w.TreeItemCollapsibleState.Collapsed,void 0,"list-tree"),new S("Performance",w.TreeItemCollapsibleState.Collapsed,void 0,"dashboard")];switch(e.label){case"Run":return[new S("Run Game",w.TreeItemCollapsibleState.None,"luna.runGame","play"),new S("Stop Game",w.TreeItemCollapsibleState.None,"luna.stopGame","debug-stop"),new S("Run with Arguments",w.TreeItemCollapsibleState.None,"luna.runWithArgs","terminal"),new S("Run Example",w.TreeItemCollapsibleState.None,"luna.runExample","file-code")];case"Testing":return[new S("Open Test Runner",w.TreeItemCollapsibleState.None,"luna.editor.testRunner","beaker"),new S("Run All Tests",w.TreeItemCollapsibleState.None,"luna.test.all","testing-run-all-icon"),new S("Run Lua Tests",w.TreeItemCollapsibleState.None,"luna.test.lua.all","test-view-icon"),new S("Run Golden Tests",w.TreeItemCollapsibleState.None,"luna.test.lua.golden","file-media"),new S("Generate Tests for File",w.TreeItemCollapsibleState.None,"luna.test.generateForFile","wand")];case"Editors":return[new S("Tile Map Editor",w.TreeItemCollapsibleState.None,"luna.editor.tileMap","symbol-misc"),new S("Tileset Editor",w.TreeItemCollapsibleState.None,"luna.editor.tileset","layers"),new S("Tilemap Script Editor",w.TreeItemCollapsibleState.None,"luna.editor.tilemapScript","code"),new S("World Map Editor",w.TreeItemCollapsibleState.None,"luna.editor.worldMap","map"),new S("Procedural Map Generator",w.TreeItemCollapsibleState.None,"luna.editor.procMap","globe"),new S("Pixel Art Editor",w.TreeItemCollapsibleState.None,"luna.editor.pixelArt","paintcan"),new S("Sprite Animation Editor",w.TreeItemCollapsibleState.None,"luna.editor.spriteAnim","play-circle"),new S("Shader Preview",w.TreeItemCollapsibleState.None,"luna.editor.shaderPreview","wand"),new S("Color Palette",w.TreeItemCollapsibleState.None,"luna.editor.colorPalette","symbol-color"),new S("Font Preview",w.TreeItemCollapsibleState.None,"luna.editor.fontPreview","text-size"),new S("Scene Flow Editor",w.TreeItemCollapsibleState.None,"luna.editor.sceneFlow","type-hierarchy"),new S("Entity Designer",w.TreeItemCollapsibleState.None,"luna.editor.entity","symbol-class"),new S("Dialog Editor",w.TreeItemCollapsibleState.None,"luna.editor.dialog","comment-discussion"),new S("Quest Tree Editor",w.TreeItemCollapsibleState.None,"luna.editor.questTree","git-merge"),new S("GUI Widget Editor",w.TreeItemCollapsibleState.None,"luna.editor.guiWidget","symbol-interface"),new S("Timeline / Cutscene",w.TreeItemCollapsibleState.None,"luna.editor.timeline","history"),new S("Input Mapper",w.TreeItemCollapsibleState.None,"luna.editor.inputMapper","keyboard"),new S("Localization Editor",w.TreeItemCollapsibleState.None,"luna.editor.localization","book"),new S("Particle Designer",w.TreeItemCollapsibleState.None,"luna.editor.particle","sparkle"),new S("Physics Materials",w.TreeItemCollapsibleState.None,"luna.editor.physicsMaterials","settings-gear"),new S("AI Behavior Tree",w.TreeItemCollapsibleState.None,"luna.editor.aiBehavior","hubot"),new S("Voxel Editor",w.TreeItemCollapsibleState.None,"luna.editor.voxel","layers"),new S("Audio Mixer",w.TreeItemCollapsibleState.None,"luna.editor.audioMixer","unmute"),new S("Sound DSP Panel",w.TreeItemCollapsibleState.None,"luna.editor.soundDsp","radio-tower"),new S("PostFX & Overlay Designer",w.TreeItemCollapsibleState.None,"luna.editor.postfxOverlay","color-mode"),new S("Database Browser",w.TreeItemCollapsibleState.None,"luna.editor.database","database"),new S("Graph Editor",w.TreeItemCollapsibleState.None,"luna.editor.graph","graph")];case"Debug":return[new S("Debug Run + Connect",w.TreeItemCollapsibleState.None,"luna.debug.runAndConnect","debug-start"),new S("Connect",w.TreeItemCollapsibleState.None,"luna.debug.connect","plug"),new S("Disconnect",w.TreeItemCollapsibleState.None,"luna.debug.disconnect","debug-disconnect"),new S("Evaluate Lua",w.TreeItemCollapsibleState.None,"luna.debug.evaluate","terminal"),new S("Watchers Panel",w.TreeItemCollapsibleState.None,"luna.debug.openWatchers","eye"),new S("Variable Inspector",w.TreeItemCollapsibleState.None,"luna.debug.openInspector","symbol-variable"),new S("Call Stack",w.TreeItemCollapsibleState.None,"luna.debug.openCallStack","list-tree"),new S("Performance",w.TreeItemCollapsibleState.None,"luna.debug.performance","dashboard"),new S("Screenshot",w.TreeItemCollapsibleState.None,"luna.debug.screenshot","device-camera"),new S("Status",w.TreeItemCollapsibleState.None,"luna.debug.status","info")];case"Reference":return[new S("Browse API",w.TreeItemCollapsibleState.None,"luna.browseApi","search"),new S("Open API Docs",w.TreeItemCollapsibleState.None,"luna.openApiDocs","book"),new S("Open Wiki",w.TreeItemCollapsibleState.None,"luna.openWiki","globe"),new S("Dependency Graph",w.TreeItemCollapsibleState.None,"luna.depGraph","graph"),new S("Dependency List",w.TreeItemCollapsibleState.None,"luna.depList","list-tree"),new S("API Coverage",w.TreeItemCollapsibleState.None,"luna.apiCoverage","graph-line")];case"Assets":return[new S("Refresh Assets",w.TreeItemCollapsibleState.None,"luna.assets.refresh","refresh"),new S("Open Asset Explorer",w.TreeItemCollapsibleState.None,"luna.assets.openPanel","file-media"),new S("Find Missing Assets",w.TreeItemCollapsibleState.None,"luna.assets.findMissing","warning")];case"Dependencies":return[new S("Show Module Graph",w.TreeItemCollapsibleState.None,"luna.deps.showGraph","type-hierarchy"),new S("Find Circular Deps",w.TreeItemCollapsibleState.None,"luna.deps.findCircular","warning"),new S("Show Orphan Modules",w.TreeItemCollapsibleState.None,"luna.deps.findOrphans","question")];case"Performance":return[new S("Open Performance Dashboard",w.TreeItemCollapsibleState.None,"luna.perf.openDashboard","dashboard"),new S("System Monitor",w.TreeItemCollapsibleState.None,"luna.system.openMonitor","pulse"),new S("API Usage Report",w.TreeItemCollapsibleState.None,"luna.api.usageReport","graph"),new S("Open Hot Reload History",w.TreeItemCollapsibleState.None,"luna.perf.openHotReload","history"),new S("Clear History",w.TreeItemCollapsibleState.None,"luna.perf.clearHistory","clear-all")];default:return[]}}},Xt=class{_onDidChangeTreeData=new w.EventEmitter;onDidChangeTreeData=this._onDidChangeTreeData.event;refresh(){this._onDidChangeTreeData.fire(void 0)}getTreeItem(e){return e}getChildren(e){if(!e)return[new S("CAG (AI Config)",w.TreeItemCollapsibleState.Expanded,void 0,"hubot"),new S("MCP Server",w.TreeItemCollapsibleState.Collapsed,void 0,"server"),new S("Game Jam",w.TreeItemCollapsibleState.Collapsed,void 0,"flame")];switch(e.label){case"CAG (AI Config)":return[new S("Install AI Config",w.TreeItemCollapsibleState.None,"luna.cag.install","cloud-download"),new S("Select Agent",w.TreeItemCollapsibleState.None,"luna.cag.selectAgent","person"),new S("Select Skill",w.TreeItemCollapsibleState.None,"luna.cag.selectSkill","mortar-board"),new S("Select Prompt",w.TreeItemCollapsibleState.None,"luna.cag.selectPrompt","comment"),new S("Update CAG Files",w.TreeItemCollapsibleState.None,"luna.cag.update","sync")];case"MCP Server":return[new S("Install MCP Server",w.TreeItemCollapsibleState.None,"luna.mcp.install","cloud-download"),new S("MCP Status",w.TreeItemCollapsibleState.None,"luna.mcp.status","info")];case"Game Jam":return[new S("Game Jam Timer",w.TreeItemCollapsibleState.None,"luna.jam.timer","watch"),new S("Quick Build",w.TreeItemCollapsibleState.None,"luna.jam.quickBuild","zap"),new S("Submission Checklist",w.TreeItemCollapsibleState.None,"luna.jam.checklist","checklist")];default:return[]}}};var T=E(require("vscode"));var kr=new Set(["and","break","do","else","elseif","end","false","for","function","goto","if","in","local","nil","not","or","repeat","return","then","true","until","while"]),Ta=new Set(["load","update","draw","keypressed","keyreleased","textinput","mousepressed","mousereleased","wheelmoved","gamepadpressed","gamepadreleased","gamepadaxis","joystickadded","joystickremoved","touchpressed","touchmoved","touchreleased","focus","visible","resize","quit"]),Ia=new Set(["+","-","*","/","%","^","#","==","~=","<",">","<=",">=","=","..","...","//"]),Sr=new Set(["(",")","{","}","[","]",";",":",",","."]),Y=class{tokenize(e){let t=[],o=e.length,a=0,s=0,i=0;for(;a<o;){let r=e[a];if(r===" "||r==="	"||r==="\r"||r===`
`){let l=a,d=s,c=i;for(;a<o&&(e[a]===" "||e[a]==="	"||e[a]==="\r"||e[a]===`
`);)e[a]===`
`?(s++,i=0):i++,a++;t.push({type:7,value:e.slice(l,a),line:d,column:c,length:a-l});continue}if(r==="-"&&a+1<o&&e[a+1]==="-"){let l=s,d=i;if(a+2<o&&e[a+2]==="["){let p=this.countLongBracketLevel(e,a+2);if(p>=0){let f="]"+"=".repeat(p)+"]",g=e.indexOf(f,a+4+p),m=g>=0?g+f.length:o,v=e.slice(a,m),y=ro(v);t.push({type:4,value:v,line:l,column:d,length:m-a});for(let b=a;b<m;b++)e[b]===`
`?(s++,i=0):i++;a=m;continue}}let c=e.indexOf(`
`,a),u=c>=0?c:o,h=e.slice(a,u);t.push({type:4,value:h,line:l,column:d,length:u-a}),i+=u-a,a=u;continue}if(r==="["){let l=this.countLongBracketLevel(e,a);if(l>=0){let d="]"+"=".repeat(l)+"]",c=a+2+l,u=e.indexOf(d,c),h=u>=0?u+d.length:o,p=e.slice(a,h),f=s,g=i;for(let m=a;m<h;m++)e[m]===`
`?(s++,i=0):i++;t.push({type:2,value:p,line:f,column:g,length:h-a}),a=h;continue}}if(r==='"'||r==="'"){let l=s,d=i,c=r,u=a+1;for(;u<o;){if(e[u]==="\\"){u+=2;continue}if(e[u]===c){u++;break}if(e[u]===`
`)break;u++}let h=e.slice(a,u);t.push({type:2,value:h,line:l,column:d,length:u-a}),i+=u-a,a=u;continue}if(ot(r)||r==="."&&a+1<o&&ot(e[a+1])){let l=s,d=i,c=a;if(r==="0"&&c+1<o&&(e[c+1]==="x"||e[c+1]==="X"))for(c+=2;c<o&&Er(e[c]);)c++;else if(r==="0"&&c+1<o&&(e[c+1]==="b"||e[c+1]==="B"))for(c+=2;c<o&&(e[c]==="0"||e[c]==="1");)c++;else{for(;c<o&&ot(e[c]);)c++;if(c<o&&e[c]===".")for(c++;c<o&&ot(e[c]);)c++;if(c<o&&(e[c]==="e"||e[c]==="E"))for(c++,c<o&&(e[c]==="+"||e[c]==="-")&&c++;c<o&&ot(e[c]);)c++}let u=e.slice(a,c);t.push({type:3,value:u,line:l,column:d,length:c-a}),i+=c-a,a=c;continue}if(Pa(r)){let l=i,d=a+1;for(;d<o&&wt(e[d]);)d++;let c=e.slice(a,d),u=kr.has(c)?0:1;t.push({type:u,value:c,line:s,column:l,length:d-a}),i+=d-a,a=d;continue}if(a+2<o){let l=e.slice(a,a+3);if(l==="..."){t.push({type:5,value:l,line:s,column:i,length:3}),i+=3,a+=3;continue}}if(a+1<o){let l=e.slice(a,a+2);if(Ia.has(l)){t.push({type:5,value:l,line:s,column:i,length:2}),i+=2,a+=2;continue}}if(Ia.has(r)){t.push({type:5,value:r,line:s,column:i,length:1}),i++,a++;continue}if(Sr.has(r)){t.push({type:6,value:r,line:s,column:i,length:1}),i++,a++;continue}i++,a++}return t.push({type:8,value:"",line:s,column:i,length:0}),t}analyze(e){let t=this.tokenize(e),o=[],a=[],s=[],i=[],r=[];for(let m of t)if(m.type===4){let v=m.value.replace(/^--\[=*\[/,"").replace(/\]=*\]$/,"").replace(/^--/,"").trim();r.push({text:v,line:m.line,isBlock:m.value.startsWith("--["),isLuaCATS:m.value.startsWith("---@")})}let l=t.filter(m=>m.type!==7&&m.type!==4),d=[],c=0,u=(m=0)=>l[c+m],h=(m,v)=>{let y=u();return!(!y||y.type!==m||v!==void 0&&y.value!==v)},p=()=>l[c++],f=m=>{for(let v=r.length-1;v>=0;v--)if(r[v].line===m-1||r[v].line===m)return r[v].text};for(;c<l.length&&u()?.type!==8;){let m=u();if(h(0,"local")){let v=p();if(h(0,"function")){if(p(),u()?.type===1){let y=p(),b=this.parseParamList(l,c);c=b.nextIndex;let x=f(v.line),k={name:y.value,kind:"function",line:y.line,column:y.column,scope:d.length>0?d[d.length-1].name:void 0,parameters:b.names,isLocal:!0,description:x};o.push(k);for(let F of b.names)o.push({name:F,kind:"parameter",line:y.line,column:y.column,scope:y.value,isLocal:!0});d.push({name:y.value,startLine:y.line,kind:"function"})}continue}if(u()?.type===1){let y=p();if(h(5,"=")){if(p(),u()?.type===1&&u()?.value==="require"&&(p(),h(6,"(")&&(p(),u()?.type===2))){let x=p().value.slice(1,-1);a.push({modulePath:x,localName:y.value,line:y.line,column:y.column})}if(u()?.type===6&&u()?.value==="{"){o.push({name:y.value,kind:"table",line:y.line,column:y.column,scope:d.length>0?d[d.length-1].name:void 0,isLocal:!0,description:f(y.line)});continue}}for(o.push({name:y.value,kind:"local",line:y.line,column:y.column,scope:d.length>0?d[d.length-1].name:void 0,isLocal:!0,description:f(y.line)});h(6,",");)if(p(),u()?.type===1){let b=p();o.push({name:b.value,kind:"local",line:b.line,column:b.column,scope:d.length>0?d[d.length-1].name:void 0,isLocal:!0})}}continue}if(h(0,"function")){let v=p();if(u()?.type===1){let b=p().value,x=!1,k;for(;;)if(h(6,"."))p(),u()?.type===1&&(b+="."+p().value);else if(h(6,":")){if(p(),x=!0,k=b,u()?.type===1){let ut=p();b+=":"+ut.value}}else break;let F=this.parseParamList(l,c);c=F.nextIndex;let q=b.lastIndexOf("."),ae=b.lastIndexOf(":"),Pe=Math.max(q,ae),Fe=Pe>=0?b.slice(Pe+1):b,ct={name:Fe,kind:x?"method":"function",line:v.line,column:v.column,scope:d.length>0?d[d.length-1].name:void 0,type:k,parameters:F.names,isLocal:!1,description:f(v.line)};o.push(ct),b.startsWith("luna.")&&Ta.has(Fe)&&s.push(ct);for(let ut of F.names)o.push({name:ut,kind:"parameter",line:v.line,column:v.column,scope:Fe,isLocal:!0});d.push({name:Fe,startLine:v.line,kind:"function"});continue}d.push({name:"<anonymous>",startLine:v.line,kind:"function"}),h(6,"(")&&(c=this.parseParamList(l,c).nextIndex);continue}if(m.type===1){let v=c,y=m.value,b=c+1,x=!1;for(;b<l.length;)if(l[b]?.value==="."&&l[b+1]?.type===1)y+="."+l[b+1].value,b+=2;else if(l[b]?.value===":"&&l[b+1]?.type===1)y+=":"+l[b+1].value,x=!0,b+=2;else break;if(b<l.length&&l[b]?.value==="="){let k=b,F=l[k+1];if(F?.type===0&&F.value==="function"){c=k+2;let q=this.parseParamList(l,c);c=q.nextIndex;let ae=y.lastIndexOf("."),Pe=ae>=0?y.slice(ae+1):y,Fe={name:Pe,kind:"function",line:m.line,column:m.column,parameters:q.names,isLocal:!1,description:f(m.line)};o.push(Fe),y.startsWith("luna.")&&Ta.has(Pe)&&s.push(Fe);for(let ct of q.names)o.push({name:ct,kind:"parameter",line:m.line,column:m.column,scope:Pe,isLocal:!0});d.push({name:Pe,startLine:m.line,kind:"function"});continue}if(y.endsWith(".__index")&&F?.type===1){c=k+2;continue}}p();continue}if(m.type===0){if(m.value==="do"){d.push({name:"do",startLine:m.line,kind:"do"}),p();continue}if(m.value==="if"||m.value==="elseif"){m.value==="if"&&d.push({name:"if",startLine:m.line,kind:"if"}),p();continue}if(m.value==="for"){d.push({name:"for",startLine:m.line,kind:"for"}),p();continue}if(m.value==="while"){d.push({name:"while",startLine:m.line,kind:"while"}),p();continue}if(m.value==="repeat"){d.push({name:"repeat",startLine:m.line,kind:"repeat"}),p();continue}if(m.value==="end"||m.value==="until"){let v=d.pop();if(v){i.push({name:v.name,startLine:v.startLine,endLine:m.line,kind:v.kind});for(let y=o.length-1;y>=0;y--)if(o[y].kind==="function"&&o[y].name===v.name&&o[y].line===v.startLine){o[y].endLine=m.line;break}}p();continue}}p()}let g=e.split(`
`).length-1;for(;d.length>0;){let m=d.pop();i.push({name:m.name,startLine:m.startLine,endLine:g,kind:m.kind})}return{symbols:o,requires:a,callbacks:s,scopes:i,comments:r}}getSymbolAt(e,t,o){for(let a of e.symbols)if(a.line===t&&o>=a.column&&o<a.column+a.name.length)return a}getScopeAt(e,t){let o;for(let a of e.scopes)t>=a.startLine&&t<=a.endLine&&(!o||a.startLine>o.startLine)&&(o=a);return o}findReferencesInDocument(e,t){let o=[],a=this.tokenize(e);for(let s of a)s.type===1&&s.value===t&&o.push({line:s.line,column:s.column});return o}getVisibleLocals(e,t){let o=this.getScopeAt(e,t);return e.symbols.filter(a=>!a.isLocal||a.line>t?!1:a.scope&&o?a.scope===o.name||!a.scope:!0)}detectClasses(e){let t=[],o=new Set;for(let a of e.symbols)a.kind==="method"&&a.type&&o.add(a.type);for(let a of o){let s=e.symbols.filter(l=>l.kind==="method"&&l.type===a),i=e.symbols.filter(l=>l.kind==="field"&&l.scope===a).map(l=>l.name),r=s[0];r&&t.push({name:a,methods:s,fields:i,line:r.line})}return t}getWordAtPosition(e,t,o){let a=e.split(`
`);if(t<0||t>=a.length)return"";let s=a[t];if(o<0||o>=s.length)return"";let i=o,r=o;for(;i>0&&wt(s[i-1]);)i--;for(;r<s.length&&wt(s[r]);)r++;for(;i>0&&(s[i-1]==="."||s[i-1]===":");)for(i--;i>0&&wt(s[i-1]);)i--;return s.slice(i,r)}getFunctionCallContext(e,t,o){let a=e.split(`
`);if(t<0||t>=a.length)return;let s=a[t],i=0,r=0,l=t,d=Math.min(o,s.length)-1;for(;l>=0;){let c=a[l],u=l===t?d:c.length-1;for(let h=u;h>=0;h--){let p=c[h];if(p===")"){i++;continue}if(p==="("){if(i===0){let f=h-1;for(;f>=0&&c[f]===" ";)f--;let g=f;for(;g>0&&(wt(c[g-1])||c[g-1]==="."||c[g-1]===":");)g--;let m=c.slice(g,f+1);return m.length>0?{functionName:m,paramIndex:r}:void 0}i--;continue}p===","&&i===0&&r++}l--,l>=0&&(d=a[l].length-1)}}isInsideString(e,t,o){let a=this.tokenize(e);for(let s of a){if(s.type!==2)continue;let i=s.line+ro(s.value);if(s.line===i){if(s.line===t&&o>=s.column&&o<s.column+s.length)return!0}else{if(t>s.line&&t<i||t===s.line&&o>=s.column)return!0;if(t===i){let r=s.value.lastIndexOf(`
`),l=s.value.length-r-1;if(o<l)return!0}}}return!1}isInsideComment(e,t,o){let a=this.tokenize(e);for(let s of a){if(s.type!==4)continue;let i=s.line+ro(s.value);if(s.line===i){if(s.line===t&&o>=s.column)return!0}else{if(t>s.line&&t<i||t===s.line&&o>=s.column)return!0;if(t===i){let r=s.value.lastIndexOf(`
`),l=s.value.length-r-1;if(o<l)return!0}}}return!1}countLongBracketLevel(e,t){if(e[t]!=="[")return-1;let o=0,a=t+1;for(;a<e.length&&e[a]==="=";)o++,a++;return a<e.length&&e[a]==="["?o:-1}parseParamList(e,t){let o=[],a=t;if(a>=e.length||e[a]?.value!=="(")return{names:o,nextIndex:a};for(a++;a<e.length&&e[a]?.value!==")";)e[a]?.type===1?o.push(e[a].value):e[a]?.value==="..."&&o.push("..."),a++;return a<e.length&&e[a]?.value===")"&&a++,{names:o,nextIndex:a}}};function ot(n){return n>="0"&&n<="9"}function Er(n){return ot(n)||n>="a"&&n<="f"||n>="A"&&n<="F"}function Pa(n){return n>="a"&&n<="z"||n>="A"&&n<="Z"||n==="_"}function wt(n){return Pa(n)||ot(n)}function ro(n){let e=0;for(let t=0;t<n.length;t++)n[t]===`
`&&e++;return e}var lo={scheme:"file",language:"lua"},Gt=new Y,La=new Map;function Ra(n){let e=n.uri.toString(),t=La.get(e);if(t&&t.version===n.version)return t.info;let o=Gt.analyze(n.getText());return La.set(e,{version:n.version,info:o}),o}var Cr=[{label:"print",kind:T.CompletionItemKind.Function,detail:"print(...)",doc:"Receives any number of arguments and prints their values to stdout.",snippet:"print(${1:value})"},{label:"require",kind:T.CompletionItemKind.Function,detail:"require(modname)",doc:"Loads the given module, returns the value stored in `package.loaded[modname]`.",snippet:'require("${1:module}")'},{label:"type",kind:T.CompletionItemKind.Function,detail:"type(v) \u2192 string",doc:"Returns the type of its argument as a string.",snippet:"type(${1:value})"},{label:"tostring",kind:T.CompletionItemKind.Function,detail:"tostring(v) \u2192 string",doc:"Converts any value to a string in a reasonable format.",snippet:"tostring(${1:value})"},{label:"tonumber",kind:T.CompletionItemKind.Function,detail:"tonumber(e [, base]) \u2192 number|nil",doc:"Tries to convert its argument to a number.",snippet:"tonumber(${1:value})"},{label:"pairs",kind:T.CompletionItemKind.Function,detail:"pairs(t) \u2192 iterator",doc:"Returns an iterator function for all key-value pairs in table t.",snippet:"pairs(${1:table})"},{label:"ipairs",kind:T.CompletionItemKind.Function,detail:"ipairs(t) \u2192 iterator",doc:"Returns an iterator function for the integer keys 1, 2, ... in table t.",snippet:"ipairs(${1:table})"},{label:"next",kind:T.CompletionItemKind.Function,detail:"next(table [, index]) \u2192 key, value",doc:"Returns the next key-value pair after index in the table.",snippet:"next(${1:table})"},{label:"select",kind:T.CompletionItemKind.Function,detail:"select(index, ...)",doc:'Returns all arguments after argument number index, or the total number with "#".',snippet:"select(${1:index})"},{label:"unpack",kind:T.CompletionItemKind.Function,detail:"unpack(list [, i [, j]])",doc:"Returns the elements from the given list.",snippet:"unpack(${1:list})"},{label:"setmetatable",kind:T.CompletionItemKind.Function,detail:"setmetatable(table, metatable) \u2192 table",doc:"Sets the metatable for the given table.",snippet:"setmetatable(${1:table}, ${2:metatable})"},{label:"getmetatable",kind:T.CompletionItemKind.Function,detail:"getmetatable(object) \u2192 table|nil",doc:"Returns the metatable of the given object, if it has one.",snippet:"getmetatable(${1:object})"},{label:"rawset",kind:T.CompletionItemKind.Function,detail:"rawset(table, index, value) \u2192 table",doc:"Sets the value of table[index] without invoking metamethods.",snippet:"rawset(${1:table}, ${2:index}, ${3:value})"},{label:"rawget",kind:T.CompletionItemKind.Function,detail:"rawget(table, index) \u2192 value",doc:"Gets the value of table[index] without invoking metamethods.",snippet:"rawget(${1:table}, ${2:index})"},{label:"rawequal",kind:T.CompletionItemKind.Function,detail:"rawequal(v1, v2) \u2192 boolean",doc:"Checks equality without invoking __eq metamethod.",snippet:"rawequal(${1:v1}, ${2:v2})"},{label:"rawlen",kind:T.CompletionItemKind.Function,detail:"rawlen(v) \u2192 number",doc:"Returns the length without invoking __len metamethod.",snippet:"rawlen(${1:v})"},{label:"error",kind:T.CompletionItemKind.Function,detail:"error(message [, level])",doc:"Terminates the last protected function called and returns message as the error object.",snippet:"error(${1:message})"},{label:"pcall",kind:T.CompletionItemKind.Function,detail:"pcall(f, ...) \u2192 ok, result...",doc:"Calls function f in protected mode. Returns status and results.",snippet:"pcall(${1:func})"},{label:"xpcall",kind:T.CompletionItemKind.Function,detail:"xpcall(f, msgh, ...) \u2192 ok, result...",doc:"Calls function f in protected mode with message handler msgh.",snippet:"xpcall(${1:func}, ${2:handler})"},{label:"assert",kind:T.CompletionItemKind.Function,detail:"assert(v [, message])",doc:"Calls error if the value of v is false or nil.",snippet:"assert(${1:value})"},{label:"dofile",kind:T.CompletionItemKind.Function,detail:"dofile(filename)",doc:"Opens the named file and executes its contents as a Lua chunk.",snippet:'dofile("${1:filename}")'},{label:"loadfile",kind:T.CompletionItemKind.Function,detail:"loadfile(filename) \u2192 function|nil, err",doc:"Loads a chunk from a file without executing it.",snippet:'loadfile("${1:filename}")'},{label:"load",kind:T.CompletionItemKind.Function,detail:"load(chunk [, chunkname]) \u2192 function|nil, err",doc:"Loads a chunk from a string or function.",snippet:"load(${1:chunk})"},{label:"loadstring",kind:T.CompletionItemKind.Function,detail:"loadstring(s) \u2192 function|nil, err",doc:"Loads a chunk from a string (LuaJIT/Lua 5.1 compat).",snippet:"loadstring(${1:code})"},{label:"collectgarbage",kind:T.CompletionItemKind.Function,detail:"collectgarbage(opt [, arg])",doc:"Interface to the garbage collector.",snippet:'collectgarbage("${1:collect}")'}],Tr=[{label:"string",detail:"String manipulation library"},{label:"table",detail:"Table manipulation library"},{label:"math",detail:"Math library"},{label:"os",detail:"Operating system facilities"},{label:"io",detail:"I/O library"},{label:"coroutine",detail:"Coroutine library"},{label:"debug",detail:"Debug library"},{label:"package",detail:"Package library"}],Ir=["space","return","escape","up","down","left","right","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9","f1","f2","f3","f4","f5","f6","f7","f8","f9","f10","f11","f12","lshift","rshift","lctrl","rctrl","lalt","ralt","tab","backspace","delete","insert","home","end","pageup","pagedown"],Pr=[{pattern:/luna\.input\.(?:isDown|isUp)\s*\(\s*["']$/,values:Ir.map(n=>({label:n,detail:"Key name"}))},{pattern:/luna\.graphics\.setBlendMode\s*\(\s*["']$/,values:[{label:"alpha",detail:"Standard alpha blending"},{label:"add",detail:"Additive blending"},{label:"subtract",detail:"Subtractive blending"},{label:"multiply",detail:"Multiply blending"},{label:"premultiplied",detail:"Pre-multiplied alpha"},{label:"replace",detail:"Replace pixels (no blending)"},{label:"screen",detail:"Screen blending"},{label:"darken",detail:"Darken blending"},{label:"lighten",detail:"Lighten blending"}]},{pattern:/luna\.graphics\.setLineCap\s*\(\s*["']$/,values:[{label:"none",detail:"No line cap"},{label:"butt",detail:"Flat cap (default)"},{label:"square",detail:"Square cap extends past endpoint"},{label:"round",detail:"Rounded cap"}]},{pattern:/luna\.graphics\.setLineJoin\s*\(\s*["']$/,values:[{label:"miter",detail:"Sharp join (default)"},{label:"bevel",detail:"Flat corner join"},{label:"none",detail:"No join"}]},{pattern:/luna\.physics\.newBody\s*\([^)]*,\s*["']$/,values:[{label:"static",detail:"Immovable body"},{label:"dynamic",detail:"Fully simulated body"},{label:"kinematic",detail:"Moved by code, not forces"}]},{pattern:/luna\.audio\.newSource\s*\([^)]*,\s*["']$/,values:[{label:"static",detail:"Load entirely into memory"},{label:"stream",detail:"Stream from disk"}]},{pattern:/:setFilter\s*\(\s*["']$/,values:[{label:"nearest",detail:"Pixel-perfect (no filtering)"},{label:"linear",detail:"Smooth bilinear filtering"}]},{pattern:/:setWrap\s*\(\s*["']$/,values:[{label:"clamp",detail:"Clamp to edge"},{label:"clampzero",detail:"Clamp to transparent"},{label:"repeat",detail:"Tile texture"},{label:"mirroredrepeat",detail:"Tile with mirroring"}]},{pattern:/luna\.graphics\.setDefaultFilter\s*\(\s*["']$/,values:[{label:"nearest",detail:"Pixel-perfect (no filtering)"},{label:"linear",detail:"Smooth bilinear filtering"}]},{pattern:/luna\.graphics\.setLineStyle\s*\(\s*["']$/,values:[{label:"rough",detail:"Aliased line"},{label:"smooth",detail:"Anti-aliased line"}]},{pattern:/luna\.graphics\.(?:rectangle|circle|polygon|ellipse|arc)\s*\(\s*["']$/,values:[{label:"fill",detail:"Filled shape"},{label:"line",detail:"Outlined shape"}]},{pattern:/(?:easing|ease|tween)\s*[=:]\s*["']$|luna\.tween\.\w+\s*\([^)]*["']$/i,values:[{label:"linear",detail:"Constant speed"},{label:"inQuad",detail:"Accelerating (quadratic)"},{label:"outQuad",detail:"Decelerating (quadratic)"},{label:"inOutQuad",detail:"Accel then decel (quadratic)"},{label:"inCubic",detail:"Accelerating (cubic)"},{label:"outCubic",detail:"Decelerating (cubic)"},{label:"inOutCubic",detail:"Accel then decel (cubic)"},{label:"inQuart",detail:"Accelerating (quartic)"},{label:"outQuart",detail:"Decelerating (quartic)"},{label:"inQuint",detail:"Accelerating (quintic)"},{label:"outQuint",detail:"Decelerating (quintic)"},{label:"inSine",detail:"Sine wave acceleration"},{label:"outSine",detail:"Sine wave deceleration"},{label:"inOutSine",detail:"Sine wave accel/decel"},{label:"inExpo",detail:"Exponential acceleration"},{label:"outExpo",detail:"Exponential deceleration"},{label:"inCirc",detail:"Circular acceleration"},{label:"outCirc",detail:"Circular deceleration"},{label:"inBack",detail:"Overshoot on start"},{label:"outBack",detail:"Overshoot on end"},{label:"inBounce",detail:"Bounce on start"},{label:"outBounce",detail:"Bounce on end"},{label:"inElastic",detail:"Elastic spring start"},{label:"outElastic",detail:"Elastic spring end"}]},{pattern:/luna\.graphics\.printf\s*\([^)]*,[^)]*,[^)]*,[^)]*,\s*["']$/,values:[{label:"left",detail:"Left-aligned text"},{label:"center",detail:"Center-aligned text"},{label:"right",detail:"Right-aligned text"},{label:"justify",detail:"Justified text"}]},{pattern:/luna\.graphics\.(?:setStencilTest|stencil)\s*\([^)]*["']$/,values:[{label:"greater",detail:"Draw where stencil > value"},{label:"greaterequal",detail:"Draw where stencil >= value"},{label:"less",detail:"Draw where stencil < value"},{label:"lessequal",detail:"Draw where stencil <= value"},{label:"equal",detail:"Draw where stencil == value"},{label:"notequal",detail:"Draw where stencil != value"},{label:"always",detail:"Always draw"},{label:"never",detail:"Never draw"}]},{pattern:/luna\.input\.(?:getAxis|isGamepadAxis)\s*\([^)]*,\s*["']$/,values:[{label:"leftx",detail:"Left stick X axis"},{label:"lefty",detail:"Left stick Y axis"},{label:"rightx",detail:"Right stick X axis"},{label:"righty",detail:"Right stick Y axis"},{label:"triggerleft",detail:"Left trigger"},{label:"triggerright",detail:"Right trigger"}]},{pattern:/luna\.input\.(?:isGamepadDown|isGamepadUp|wasGamepadPressed)\s*\([^)]*,\s*["']$/,values:[{label:"a",detail:"A button (Cross on PS)"},{label:"b",detail:"B button (Circle on PS)"},{label:"x",detail:"X button (Square on PS)"},{label:"y",detail:"Y button (Triangle on PS)"},{label:"back",detail:"Back / Select"},{label:"start",detail:"Start / Options"},{label:"leftshoulder",detail:"Left bumper (LB/L1)"},{label:"rightshoulder",detail:"Right bumper (RB/R1)"},{label:"lefttrigger",detail:"Left trigger (LT/L2)"},{label:"righttrigger",detail:"Right trigger (RT/R2)"},{label:"leftstick",detail:"Left stick click (LS/L3)"},{label:"rightstick",detail:"Right stick click (RS/R3)"},{label:"dpup",detail:"D-pad up"},{label:"dpdown",detail:"D-pad down"},{label:"dpleft",detail:"D-pad left"},{label:"dpright",detail:"D-pad right"},{label:"guide",detail:"Guide / Home button"}]},{pattern:/luna\.graphics\.arc\s*\(\s*["']$/,values:[{label:"pie",detail:"Pie-slice arc"},{label:"open",detail:"Open arc (lines to centre not drawn)"},{label:"closed",detail:"Arc with closing chord"}]},{pattern:/luna\.audio\.(?:setEffect|newEffect)\s*\([^)]*,\s*["']$/,values:[{label:"reverb",detail:"Reverb / room effect"},{label:"delay",detail:"Echo delay"},{label:"chorus",detail:"Chorus doubling effect"},{label:"distortion",detail:"Distortion"},{label:"echo",detail:"Echo"},{label:"flanger",detail:"Flanger"},{label:"ringmodulator",detail:"Ring modulator"},{label:"equalizer",detail:"EQ / equalizer"},{label:"bandpass",detail:"Band-pass filter"},{label:"lowpass",detail:"Low-pass filter"},{label:"highpass",detail:"High-pass filter"}]}],Lr={"luna.graphics.newImage":"Image","luna.graphics.newCanvas":"Canvas","luna.graphics.newFont":"Font","luna.graphics.newShader":"Shader","luna.graphics.newQuad":"Quad","luna.graphics.newMesh":"Mesh","luna.graphics.newSpriteBatch":"SpriteBatch","luna.graphics.newParticleSystem":"ParticleSystem","luna.graphics.newImageData":"ImageData","luna.audio.newSource":"Source","luna.physics.newWorld":"World","luna.physics.newBody":"Body","luna.physics.newFixture":"Fixture","luna.physics.newRectangleShape":"Shape","luna.physics.newCircleShape":"Shape","luna.physics.newPolygonShape":"Shape","luna.physics.newEdgeShape":"Shape","luna.physics.newChainShape":"Shape","luna.physics.newDistanceJoint":"Joint","luna.physics.newRevoluteJoint":"Joint","luna.physics.newPrismaticJoint":"Joint","luna.physics.newWeldJoint":"Joint","luna.thread.newChannel":"Channel","luna.thread.newThread":"Thread"},Rr=new Set(["draw","setColor","rectangle","circle","print","line","clear","push","pop","translate","rotate","scale","newImage","newFont","newCanvas","getWidth","getHeight","isDown","getMousePosition","newWorld","newBody","newSource","play","stop","getTime","getDelta","getFPS","random","lerp","clamp","read","write","exists"]);function co(n){let e=new T.MarkdownString;if(e.appendCodeblock(n.signature,"lua"),n.description&&e.appendMarkdown(`
`+n.description+`
`),n.parameters.length>0){e.appendMarkdown(`
**Parameters:**
`);for(let t of n.parameters){let o=t.optional?" *(optional)*":"",a=t.default?` \u2014 default: \`${t.default}\``:"",s=t.description?` \u2014 ${t.description}`:"";e.appendMarkdown(`- \`${t.name}\`: *${t.type}*${o}${s}${a}
`)}}return n.returns&&e.appendMarkdown(`
**Returns:** ${n.returns}
`),n.since&&e.appendMarkdown(`
*Since ${n.since}*`),n.deprecated&&e.appendMarkdown(`

\u26A0\uFE0F **Deprecated:** ${n.deprecated}`),e.isTrusted=!0,e}function Ma(n){if(n.parameters.length===0)return n.name+"()";let e=n.parameters.filter(o=>!o.optional);if(e.length===0)return n.name+"(${1})";let t=e.map((o,a)=>`\${${a+1}:${o.name}}`).join(", ");return`${n.name}(${t})`}function Mr(n){if(n.parameters.length===0&&!n.signature.includes("("))return n.name;let t=n.parameters.filter(a=>!a.optional&&a.name!=="...");if(t.length===0)return n.name+"(${1})";let o=t.map((a,s)=>`\${${s+1}:${a.name}}`).join(", ");return`${n.name}(${o})`}function Da(n){return Rr.has(n.name)?"0"+n.name:n.deprecated?"2"+n.name:"1"+n.name}function Dr(n){return n.replace(/[.*+?^${}()|[\]\\]/g,"\\$&")}function Ar(n,e,t,o){let a=n.getText().split(`
`);for(let i=e.line;i>=0;i--){let r=a[i].match(new RegExp(`(?:local\\s+)?${Dr(t)}\\s*=\\s*(luna\\.[\\w.]+)\\s*\\(`));if(r){let l=r[1],d=Lr[l];if(d)return d;let c=o.getFunction(l);if(c?.returnType&&o.getMethods(c.returnType).length>0)return c.returnType}}let s=t.charAt(0).toUpperCase()+t.slice(1);if(o.getMethods(s).length>0)return s}function Aa(n,e){let t=T.languages.registerCompletionItemProvider(lo,{provideCompletionItems(s,i){let l=s.lineAt(i).text.substring(0,i.character);try{if(Gt.isInsideComment(s.getText(),i.line,i.character))return}catch{}let d=l.match(/luna\.(\w+)\.(\w*)$/);if(d){let p=d[1],f=d[2].toLowerCase(),g=e.getFunctions(p);return g.length===0?void 0:g.filter(m=>!f||m.name.toLowerCase().startsWith(f)).sort((m,v)=>Da(m).localeCompare(Da(v))).map((m,v)=>{let y=new T.CompletionItem(m.name,m.isMethod?T.CompletionItemKind.Method:T.CompletionItemKind.Function);return y.detail=m.signature,y.documentation=co(m),y.insertText=new T.SnippetString(Ma(m)),y.sortText=String(v).padStart(4,"0"),m.deprecated&&(y.tags=[T.CompletionItemTag.Deprecated]),y})}let c=l.match(/luna\.(\w*)$/);if(c){let p=c[1].toLowerCase(),f=[];for(let g of e.getModuleNames()){if(p&&!g.toLowerCase().startsWith(p))continue;let m=e.getModule(g),v=new T.CompletionItem(g,T.CompletionItemKind.Module);v.detail=`luna.${g}`,m?.description&&(v.documentation=new T.MarkdownString(m.description)),v.sortText="0"+g,f.push(v)}for(let g of e.getCallbacks()){if(p&&!g.name.toLowerCase().startsWith(p))continue;let m=new T.CompletionItem(g.name,T.CompletionItemKind.Event);m.detail=g.signature,m.documentation=new T.MarkdownString(g.description),m.sortText="1"+g.name,f.push(m)}return f}let u=l.match(/\b(string|table|math|os|io|coroutine|debug|package|utf8|bit|jit|ffi)\.(\w*)$/);if(u){let p=u[1],f=u[2].toLowerCase(),m=e.getLuaStdlib("luajit").filter(v=>v.module===p);return m.length===0?void 0:m.filter(v=>!f||v.name.toLowerCase().startsWith(f)).map(v=>{let y=v.parameters.length===0&&!v.signature.includes("("),b=new T.CompletionItem(v.name,y?T.CompletionItemKind.Constant:T.CompletionItemKind.Function);return b.detail=v.signature,b.documentation=co(v),y||(b.insertText=new T.SnippetString(Mr(v))),b})}let h=l.match(/(\w+):(\w*)$/);if(h){let p=h[1],f=h[2].toLowerCase(),g=[],m=Ar(s,i,p,e);if(m)for(let v of e.getMethods(m)){if(f&&!v.name.toLowerCase().startsWith(f))continue;let y=new T.CompletionItem(v.name,T.CompletionItemKind.Method);y.detail=v.signature,y.documentation=co(v),y.insertText=new T.SnippetString(Ma(v)),v.deprecated&&(y.tags=[T.CompletionItemTag.Deprecated]),g.push(y)}try{let v=Ra(s),y=Gt.detectClasses(v),b=new Set(g.map(x=>typeof x.label=="string"?x.label:""));for(let x of y)if(!(x.name.toLowerCase()!==p.toLowerCase()&&x.name!==m))for(let k of x.methods){if(f&&!k.name.toLowerCase().startsWith(f)||b.has(k.name))continue;b.add(k.name);let F=new T.CompletionItem(k.name,T.CompletionItemKind.Method);F.detail=`${x.name}:${k.name}(${(k.parameters??[]).join(", ")})`,k.description&&(F.documentation=new T.MarkdownString(k.description)),g.push(F)}}catch{}if(g.length>0)return g}if(/(?:^|[\s=(,{;])[\w]*$/.test(l)&&!l.match(/\.\w*$/)&&!l.match(/:\w*$/)){let p=[];for(let g of Cr){let m=new T.CompletionItem(g.label,g.kind);m.detail=g.detail,m.documentation=new T.MarkdownString(g.doc),g.snippet&&(m.insertText=new T.SnippetString(g.snippet)),m.sortText="2"+g.label,p.push(m)}for(let g of Tr){let m=new T.CompletionItem(g.label,T.CompletionItemKind.Module);m.detail=g.detail,m.sortText="3"+g.label,p.push(m)}let f=new T.CompletionItem("luna",T.CompletionItemKind.Module);f.detail="Luna2D engine API",f.sortText="1luna",p.push(f);try{let g=Ra(s),m=Gt.getVisibleLocals(g,i.line),v=new Set(p.map(y=>typeof y.label=="string"?y.label:""));for(let y of m){if(v.has(y.name))continue;v.add(y.name);let b=y.kind==="function"?T.CompletionItemKind.Function:T.CompletionItemKind.Variable,x=new T.CompletionItem(y.name,b);x.detail=y.kind==="function"?`local function ${y.name}(${(y.parameters??[]).join(", ")})`:y.kind==="parameter"?"parameter":`local ${y.name}`,y.description&&(x.documentation=new T.MarkdownString(y.description)),x.sortText="0"+y.name,p.push(x)}for(let y of g.symbols){if(y.isLocal||y.kind==="parameter"||v.has(y.name))continue;v.add(y.name);let b=y.kind==="function"||y.kind==="method"?T.CompletionItemKind.Function:T.CompletionItemKind.Variable,x=new T.CompletionItem(y.name,b);x.detail=y.kind==="function"?`function ${y.name}(${(y.parameters??[]).join(", ")})`:y.name,x.sortText="1"+y.name,p.push(x)}}catch{}return p}}},".",":"),o=T.languages.registerCompletionItemProvider(lo,{provideCompletionItems(s,i){let r=s.lineAt(i).text.substring(0,i.character);for(let l of Pr)if(l.pattern.test(r))return l.values.map(d=>{let c=new T.CompletionItem(d.label,T.CompletionItemKind.EnumMember);return d.detail&&(c.detail=d.detail),c.insertText=d.label,c})}},"'",'"'),a=T.languages.registerCompletionItemProvider(lo,{async provideCompletionItems(s,i){let l=s.lineAt(i).text.substring(0,i.character).match(/require\s*\(\s*["']([^"']*)$/);if(!l)return;let d=l[1],c=[];try{let u=await T.workspace.findFiles("**/*.lua","**/node_modules/**",200),h=T.workspace.workspaceFolders?.[0]?.uri.fsPath;for(let p of u){if(p.fsPath===s.uri.fsPath)continue;let f="";h&&p.fsPath.startsWith(h)?f=p.fsPath.substring(h.length+1):f=T.workspace.asRelativePath(p);let g=f.replace(/\\/g,"/");g.endsWith("/init.lua")?g=g.slice(0,-9):g.endsWith(".lua")&&(g=g.slice(0,-4));let m=g.replace(/\//g,".");if(d&&!m.toLowerCase().startsWith(d.toLowerCase()))continue;let v=new T.CompletionItem(m,T.CompletionItemKind.File);v.detail=f,v.insertText=m,c.push(v)}}catch{}return c}},"'",'"');n.subscriptions.push(t,o,a)}var j=E(require("vscode"));var kt={scheme:"file",language:"lua"},Br=new Y,Fa=new Map;function Nr(n){let e=n.uri.toString(),t=Fa.get(e);if(t&&t.version===n.version)return t.info;let o=Br.analyze(n.getText());return Fa.set(e,{version:n.version,info:o}),o}var zr={function:"Declares a function. Functions are first-class values in Lua.\n```lua\nfunction name(args) body end\nlocal f = function(args) body end\n```",local:"Declares a local variable or function. Local scope is limited to the enclosing block.\n```lua\nlocal x = 10\nlocal function helper() end\n```",if:`Conditional statement. Evaluates condition and executes the \`then\` block if truthy.
\`\`\`lua
if condition then
  -- body
elseif other then
  -- body
else
  -- body
end
\`\`\``,then:"Follows `if`/`elseif` to begin the conditional block.",else:"Alternative branch in an `if` statement, executed when all preceding conditions are false.",elseif:"Additional conditional branch in an `if` statement.\n```lua\nif x > 0 then\n  -- positive\nelseif x < 0 then\n  -- negative\nend\n```",end:"Closes a block started by `function`, `if`, `for`, `while`, or `do`.",for:"Loop construct. Numeric `for` or generic `for` (iterator).\n```lua\nfor i = 1, 10 do end       -- numeric\nfor k, v in pairs(t) do end -- generic\n```",while:"Loop that repeats while condition is truthy.\n```lua\nwhile condition do\n  -- body\nend\n```",repeat:"Loop that repeats until condition becomes truthy (always executes at least once).\n```lua\nrepeat\n  -- body\nuntil condition\n```",until:"Ends a `repeat` loop when the condition becomes truthy.",do:"Creates a block scope.\n```lua\ndo\n  local temp = compute()\nend -- temp is out of scope\n```",return:"Returns values from a function. Must be the last statement in a block.\n```lua\nreturn value1, value2\n```",break:"Exits the innermost `for`, `while`, or `repeat` loop.",goto:"Jumps to a label (Lua 5.2+/LuaJIT).\n```lua\ngoto done\n::done::\n```",in:"Used in generic `for` loops: `for k, v in pairs(t) do end`",and:"Logical AND operator. Returns first argument if falsy, otherwise second.\n```lua\nlocal x = a and b  -- b if a is truthy\n```",or:"Logical OR operator. Returns first argument if truthy, otherwise second.\n```lua\nlocal x = a or default  -- default if a is falsy\n```",not:"Logical NOT operator. Returns `true` if argument is falsy, `false` otherwise.",nil:"The absence of a value. Variables are `nil` before assignment. `nil` is falsy.",true:"Boolean true value.",false:"Boolean false value. Along with `nil`, the only falsy values in Lua."},_r={"math.pi":"**`math.pi`** = `3.141592653589793` (\u03C0)\n\nRatio of a circle's circumference to its diameter.\n\n*Tip: `luna.math.pi` is also available as a constant.*","math.huge":"**`math.huge`** = `+\u221E` (positive infinity overflow sentinel)\n\nUsed as a sentinel for unbounded ranges, e.g. `math.min(math.huge, x)` always returns `x`.","math.maxinteger":"**`math.maxinteger`** = `2^63 - 1` (max 64-bit signed integer, Lua 5.3+/LuaJIT)","math.mininteger":"**`math.mininteger`** = `-2^63` (min 64-bit signed integer, Lua 5.3+/LuaJIT)"},Or={linear:{fn:n=>n,desc:"Constant speed, no acceleration"},inQuad:{fn:n=>n*n,desc:"Slow start, accelerating (quadratic)"},outQuad:{fn:n=>n*(2-n),desc:"Fast start, decelerating (quadratic)"},inOutQuad:{fn:n=>n<.5?2*n*n:-1+(4-2*n)*n,desc:"Accelerate then decelerate (quadratic)"},inCubic:{fn:n=>n*n*n,desc:"Slow start, accelerating (cubic)"},outCubic:{fn:n=>{let e=n-1;return e*e*e+1},desc:"Fast start, decelerating (cubic)"},inOutCubic:{fn:n=>n<.5?4*n*n*n:(n-1)*(2*n-2)*(2*n-2)+1,desc:"Accelerate then decelerate (cubic)"},inQuart:{fn:n=>n*n*n*n,desc:"Slow start, accelerating (quartic)"},outQuart:{fn:n=>{let e=n-1;return 1-e*e*e*e},desc:"Fast start, decelerating (quartic)"},inQuint:{fn:n=>n*n*n*n*n,desc:"Slow start, accelerating (quintic)"},outQuint:{fn:n=>{let e=n-1;return 1+e*e*e*e*e},desc:"Fast start, decelerating (quintic)"},inSine:{fn:n=>1-Math.cos(n*Math.PI/2),desc:"Sine wave acceleration"},outSine:{fn:n=>Math.sin(n*Math.PI/2),desc:"Sine wave deceleration"},inOutSine:{fn:n=>.5*(1-Math.cos(Math.PI*n)),desc:"Sine wave accel/decel"},inExpo:{fn:n=>n===0?0:Math.pow(2,10*(n-1)),desc:"Exponential acceleration"},outExpo:{fn:n=>n===1?1:1-Math.pow(2,-10*n),desc:"Exponential deceleration"},inBack:{fn:n=>n*n*((1.70158+1)*n-1.70158),desc:"Overshoot start then accelerate"},outBack:{fn:n=>{let t=n-1;return t*t*((1.70158+1)*t+1.70158)+1},desc:"Decelerate with overshoot at end"},outBounce:{fn:n=>{if(n<1/2.75)return 7.5625*n*n;if(n<2/2.75){let t=n-.5454545454545454;return 7.5625*t*t+.75}if(n<2.5/2.75){let t=n-.8181818181818182;return 7.5625*t*t+.9375}let e=n-2.625/2.75;return 7.5625*e*e+.984375},desc:"Bounce at end"},inBounce:{fn:n=>{let e=1-n;if(e<1/2.75)return 1-7.5625*e*e;if(e<2/2.75){let o=e-.5454545454545454;return 1-(7.5625*o*o+.75)}if(e<2.5/2.75){let o=e-.8181818181818182;return 1-(7.5625*o*o+.9375)}let t=e-2.625/2.75;return 1-(7.5625*t*t+.984375)},desc:"Bounce at start"},outElastic:{fn:n=>n===0||n===1?n:Math.pow(2,-10*n)*Math.sin((n-.075)*(2*Math.PI)/.3)+1,desc:"Elastic spring at end"},inElastic:{fn:n=>n===0||n===1?n:-(Math.pow(2,10*(n-1))*Math.sin((n-1.075)*(2*Math.PI)/.3)),desc:"Elastic spring at start"}};function $r(n,e){let a=[];for(let r=0;r<=20;r++)a.push(Math.max(0,Math.min(1,e(r/20))));let s=[];for(let r=0;r<8;r++)s.push(new Array(21).fill(" "));for(let r=0;r<=20;r++){let l=Math.max(0,Math.min(7,Math.round((1-a[r])*7)));s[l][r]="\u25CF"}let i=[];for(let r=0;r<8;r++){let l=r===0?"1\u2502":r===7?"0\u2502":" \u2502";i.push(l+s[r].join(""))}return i.push("  \u2514"+"\u2500".repeat(21)+"\u25BA t"),i.join(`
`)}function Ba(n){let e=new j.MarkdownString;if(e.appendCodeblock(n.signature,"lua"),n.description&&e.appendMarkdown(`
`+n.description+`
`),n.parameters.length>0){e.appendMarkdown(`
**Parameters:**

`),e.appendMarkdown(`| Name | Type | Description |
`),e.appendMarkdown(`|------|------|-------------|
`);for(let o of n.parameters){let a=o.optional?" *(opt)*":"",s=o.default?` (default: \`${o.default}\`)`:"",i=(o.description||"")+s;e.appendMarkdown(`| \`${o.name}\` | *${o.type}*${a} | ${i} |
`)}}n.returns&&e.appendMarkdown(`
**Returns:** ${n.returns}
`),n.since&&e.appendMarkdown(`
*Since ${n.since}*
`),n.deprecated&&e.appendMarkdown(`
\u26A0\uFE0F **Deprecated:** ${n.deprecated}
`);let t=n.module?`luna.${n.module}`:"";return t&&e.appendMarkdown(`
*${t}*`),e.isTrusted=!0,e}function Na(n,e){let t=j.languages.registerHoverProvider(kt,{provideHover(l,d){let c=l.getWordRangeAtPosition(d,/luna\.\w+\.\w+/);if(c){let f=l.getText(c),g=e.getFunction(f);if(g)return new j.Hover(Ba(g),c)}let u=l.getWordRangeAtPosition(d,/luna\.\w+/);if(u){let f=l.getText(u);if(!f.includes(".",5)){for(let v of e.getCallbacks())if(v.fullPath===f){let y=new j.MarkdownString;if(y.appendCodeblock(v.signature,"lua"),y.appendMarkdown(`
`+v.description+`
`),v.parameters.length>0){y.appendMarkdown(`
**Parameters:**
`);for(let b of v.parameters)y.appendMarkdown(`- \`${b.name}\`: *${b.type}* \u2014 ${b.description}
`)}return y.appendMarkdown(`
*Engine callback \u2014 called automatically by Luna2D*`),y.isTrusted=!0,new j.Hover(y,u)}}let g=f.replace("luna.",""),m=e.getModule(g);if(m){let v=new j.MarkdownString;return v.appendMarkdown(`**luna.${m.name}**

`),m.description&&v.appendMarkdown(m.description+`

`),v.appendMarkdown(`*${m.functions.length} functions, ${m.methods.length} methods*`),v.isTrusted=!0,new j.Hover(v,u)}}let h=l.getWordRangeAtPosition(d,/\b(?:string|table|math|os|io|coroutine|debug|package|utf8|bit|jit|ffi)\.\w+/);if(h){let f=l.getText(h),m=e.getLuaStdlib("luajit").find(v=>v.fullPath===f);if(m)return new j.Hover(Ba(m),h)}let p=l.getWordRangeAtPosition(d,/\w+/);if(p){let f=l.getText(p),g=l.lineAt(d).text;if((p.start.character>0?g[p.start.character-1]:"")===".")return;try{let y=Nr(l);for(let b of y.symbols)if(b.name===f&&b.line<=d.line){if(b.kind==="parameter")continue;let x=new j.MarkdownString;if(b.kind==="function"){let k=(b.parameters??[]).join(", "),F=b.isLocal?"local ":"";x.appendCodeblock(`${F}function ${b.name}(${k})`,"lua")}else if(b.kind==="method"){let k=(b.parameters??[]).join(", ");x.appendCodeblock(`function ${b.type??"obj"}:${b.name}(${k})`,"lua")}else b.kind==="table"?x.appendCodeblock(`local ${b.name} = {}`,"lua"):x.appendCodeblock(`local ${b.name}`,"lua");return b.description&&x.appendMarkdown(`
`+b.description+`
`),x.appendMarkdown(`
*Defined at line ${b.line+1}*`),b.scope&&x.appendMarkdown(` \xB7 scope: \`${b.scope}\``),x.isTrusted=!0,new j.Hover(x,p)}}catch{}let v=zr[f];if(v){let y=new j.MarkdownString;return y.appendMarkdown(`**\`${f}\`** \u2014 Lua keyword

`),y.appendMarkdown(v),y.isTrusted=!0,new j.Hover(y,p)}}}}),o=j.languages.registerHoverProvider(kt,{provideHover(l,d){let c=l.lineAt(d).text,u=d.character,h=-1,p="";for(let x=u;x>=0;x--)if(c[x]==='"'||c[x]==="'"){h=x+1,p=c[x];break}if(h<0||!p)return;let f=-1;for(let x=u;x<c.length;x++)if(c[x]===p){f=x;break}if(f<0)return;let g=c.substring(h,f),m=Or[g];if(!m)return;let v=$r(g,m.fn),y=new j.MarkdownString;y.appendMarkdown(`**Easing: \`${g}\`**

`),y.appendCodeblock(v,""),y.appendMarkdown(`
${m.desc}
`),y.isTrusted=!0;let b=new j.Range(d.line,h,d.line,f);return new j.Hover(y,b)}}),a=j.languages.registerHoverProvider(kt,{provideHover(l,d){let c=l.getWordRangeAtPosition(d,/math\.\w+/);if(!c)return;let u=l.getText(c),h=_r[u];if(!h)return;let p=new j.MarkdownString(h);return p.isTrusted=!0,new j.Hover(p,c)}}),s={update:{dt:{type:"number",desc:"Delta time in seconds since the last frame. Use this to make movement frame-rate-independent.\n\n```lua\nfunction luna.update(dt)\n  x = x + speed * dt\nend\n```"}},keypressed:{key:{type:"string",desc:'Name of the key that was pressed (e.g. `"space"`, `"a"`, `"left"`, `"escape"`).'},scancode:{type:"string",desc:"Physical hardware scancode \u2014 use for layout-independent input."},isrepeat:{type:"boolean",desc:"`true` if generated by key repeat (held down), `false` for first press."}},keyreleased:{key:{type:"string",desc:'Name of the key that was released (e.g. `"space"`, `"a"`, `"left"`).'},scancode:{type:"string",desc:"Physical hardware scancode of the key."}},mousepressed:{x:{type:"number",desc:"Mouse X position in screen coordinates when button was pressed."},y:{type:"number",desc:"Mouse Y position in screen coordinates when button was pressed."},button:{type:"number",desc:"Mouse button index: `1` = left, `2` = right, `3` = middle."},istouch:{type:"boolean",desc:"`true` if this event was generated by a touch input device."},presses:{type:"number",desc:"Number of consecutive presses (`2` = double-click)."}},mousereleased:{x:{type:"number",desc:"Mouse X position when button was released."},y:{type:"number",desc:"Mouse Y position when button was released."},button:{type:"number",desc:"Mouse button index: `1` = left, `2` = right, `3` = middle."},istouch:{type:"boolean",desc:"`true` if generated by a touch input device."}},wheelmoved:{x:{type:"number",desc:"Horizontal scroll amount. Positive = right."},y:{type:"number",desc:"Vertical scroll amount. Positive = up (scroll wheel towards user)."}},resize:{w:{type:"number",desc:"New window width in pixels."},h:{type:"number",desc:"New window height in pixels."}},focus:{f:{type:"boolean",desc:"`true` if the window gained focus, `false` if it lost focus."}},visible:{v:{type:"boolean",desc:"`true` if the window became visible, `false` if minimized/hidden."}},textinput:{t:{type:"string",desc:"The UTF-8 encoded character(s) that were typed. Use this for text field input rather than `luna.keypressed`."}},gamepadpressed:{joystick:{type:"Joystick",desc:"The joystick/gamepad object that reported the event."},button:{type:"string",desc:'Gamepad virtual button name: `"a"`, `"b"`, `"x"`, `"y"`, `"back"`, `"start"`, `"leftshoulder"`, `"rightshoulder"`, `"dpup"`, `"dpdown"`, `"dpleft"`, `"dpright"`.'}},gamepadreleased:{joystick:{type:"Joystick",desc:"The joystick/gamepad object that reported the event."},button:{type:"string",desc:'Gamepad virtual button name (`"a"`, `"b"`, `"x"`, `"y"`, etc.).'}},gamepadaxis:{joystick:{type:"Joystick",desc:"The joystick/gamepad object that reported the event."},axis:{type:"string",desc:'Axis name: `"leftx"`, `"lefty"`, `"rightx"`, `"righty"`, `"triggerleft"`, `"triggerright"`.'},value:{type:"number",desc:"Axis value in the range `[-1.0, 1.0]` (triggers: `[0, 1]`)."}},joystickadded:{joystick:{type:"Joystick",desc:"The joystick/gamepad that was connected."}},joystickremoved:{joystick:{type:"Joystick",desc:"The joystick/gamepad that was disconnected."}},touchpressed:{id:{type:"lightuserdata",desc:"Unique identifier for this touch point."},x:{type:"number",desc:"X position of the touch in screen coordinates."},y:{type:"number",desc:"Y position of the touch in screen coordinates."},dx:{type:"number",desc:"X movement delta since last touch event."},dy:{type:"number",desc:"Y movement delta since last touch event."},pressure:{type:"number",desc:"Touch pressure in `[0, 1]`. Not all devices support pressure."}},touchmoved:{id:{type:"lightuserdata",desc:"Unique identifier for this touch point."},x:{type:"number",desc:"X position of the touch."},y:{type:"number",desc:"Y position of the touch."},dx:{type:"number",desc:"X movement delta."},dy:{type:"number",desc:"Y movement delta."},pressure:{type:"number",desc:"Touch pressure in `[0, 1]`."}},touchreleased:{id:{type:"lightuserdata",desc:"Unique identifier for the touch point that ended."},x:{type:"number",desc:"X position where touch was released."},y:{type:"number",desc:"Y position where touch was released."},dx:{type:"number",desc:"X movement delta at release."},dy:{type:"number",desc:"Y movement delta at release."},pressure:{type:"number",desc:"Pressure at release."}}},i=j.languages.registerHoverProvider(kt,{provideHover(l,d){let c=l.getWordRangeAtPosition(d,/\w+/);if(!c)return;let u=l.getText(c);if(!(u in Object.values(s).reduce((b,x)=>({...b,...x}),{})))return;let h=l.getText().split(`
`),p,f=0;for(let b=d.line;b>=0;b--){let x=h[b],k=(x.match(/\bend\b/g)??[]).length,F=(x.match(/\b(?:function|do|then|repeat)\b/g)??[]).length;if(f+=k-F,f>=0){let q=x.match(/luna\.(\w+)\s*=\s*function/);if(q){p=q[1];break}}}if(!p)return;let g=s[p];if(!g?.[u])return;let{type:m,desc:v}=g[u],y=new j.MarkdownString;return y.appendCodeblock(`(parameter) ${u}: ${m}`,"typescript"),y.appendMarkdown(`
${v}

*Parameter of \`luna.${p}\`*`),y.isTrusted=!0,new j.Hover(y,c)}}),r=j.languages.registerHoverProvider(kt,{provideHover(l,d){let c=l.lineAt(d).text;if(!/luna\.physics\.newWorld/.test(c))return;let u=l.getWordRangeAtPosition(d,/[-\d]+\.?\d*/);if(!u)return;let h=l.getText(u),p=parseFloat(h);if(isNaN(p)||(c.substring(0,u.start.character).match(/,/g)??[]).length!==1)return;let m=Math.round(980),v=new j.MarkdownString(`**Gravity Y = ${p} px/s\xB2**

Earth gravity (at 1px = 1cm) \u2248 **${m} px/s\xB2**

Current value is **${(p/m*100).toFixed(0)}%** of Earth gravity.`);return v.isTrusted=!0,new j.Hover(v,u)}});n.subscriptions.push(t,o,a,i,r)}var Re=E(require("vscode"));var Hr={scheme:"file",language:"lua"},qr=new Y;function jr(n){let e=new Re.SignatureInformation(n.signature);return e.documentation=new Re.MarkdownString(n.description),e.parameters=n.parameters.map(t=>{let o=new Re.MarkdownString,a=t.optional?" *(optional)*":"",s=t.default?` \u2014 default: \`${t.default}\``:"";return o.appendMarkdown(`*${t.type}*${a}${s}`),t.description&&o.appendMarkdown(` \u2014 ${t.description}`),new Re.ParameterInformation(t.name,o)}),e}function za(n,e){let t=Re.languages.registerSignatureHelpProvider(Hr,{provideSignatureHelp(o,a){let s=o.getText(),i=qr.getFunctionCallContext(s,a.line,a.character);if(!i)return;let{functionName:r,paramIndex:l}=i,d;if(d=e.getFunction(r),!d&&r.includes(":")){let h=r.lastIndexOf(":"),p=r.slice(h+1);for(let f of e.getAllFunctions())if(f.isMethod&&f.name===p){d=f;break}}if(d||(d=e.getLuaStdlib("luajit").find(p=>p.fullPath===r)),!d||d.parameters.length===0)return;let c=jr(d),u=new Re.SignatureHelp;return u.signatures=[c],u.activeSignature=0,u.activeParameter=Math.min(l,d.parameters.length-1),u}},"(",",");n.subscriptions.push(t)}var J=E(require("vscode")),St=E(require("path"));var Vr={scheme:"file",language:"lua"},Xr=new Y,_a="luna-api",Oa=new Map;function Gr(n){let e=n.uri.toString(),t=Oa.get(e);if(t&&t.version===n.version)return t.info;let o=Xr.analyze(n.getText());return Oa.set(e,{version:n.version,info:o}),o}var uo=class{constructor(e){this.apiData=e}provideTextDocumentContent(e){let t=e.path.replace(/^\//,""),o=this.apiData.getFunction(t);if(o)return this.renderFunction(o);let a=t.replace("luna.",""),s=this.apiData.getModule(a);return s?this.renderModule(s):`-- No API definition found for: ${t}`}renderFunction(e){let t=[];if(t.push("-- Luna2D API Definition"),t.push(`-- ${e.fullPath}`),t.push("--"),e.description&&(t.push(`-- ${e.description}`),t.push("--")),e.parameters.length>0){t.push("-- Parameters:");for(let a of e.parameters){let s=a.optional?" (optional)":"",i=a.default?` [default: ${a.default}]`:"",r=a.description?` -- ${a.description}`:"";t.push(`--   ${a.name}: ${a.type}${s}${i}${r}`)}t.push("--")}e.returns&&(t.push(`-- Returns: ${e.returns}`),t.push("--")),e.deprecated&&(t.push(`-- DEPRECATED: ${e.deprecated}`),t.push("--")),e.sourceFile&&t.push(`-- Source: ${e.sourceFile}`),t.push("");let o=e.parameters.map(a=>a.name).join(", ");return e.isMethod?t.push(`function ${e.objectType??"Object"}:${e.name}(${o})`):t.push(`function ${e.fullPath}(${o})`),t.push("  -- Implemented in Rust (native)"),t.push("end"),t.join(`
`)}renderModule(e){let t=[];t.push(`-- Luna2D API Module: ${e.fullPath}`),e.description&&t.push(`-- ${e.description}`),t.push(`-- ${e.functions.length} functions, ${e.methods.length} methods`),t.push(""),t.push(`${e.name} = {}`),t.push("");for(let o of e.functions){let a=o.parameters.map(s=>s.name).join(", ");o.description&&t.push(`--- ${o.description}`),t.push(`function ${o.fullPath}(${a}) end`),t.push("")}for(let o of e.methods){let a=o.parameters.map(s=>s.name).join(", ");o.description&&t.push(`--- ${o.description}`),t.push(`function ${o.objectType??"Object"}:${o.name}(${a}) end`),t.push("")}return t.join(`
`)}};async function Ur(n,e){let t=e.replace(/\./g,"/"),o=[t+".lua",t+"/init.lua"],a=St.dirname(n.uri.fsPath);for(let s of o){let i=J.Uri.file(St.resolve(a,s));try{return await J.workspace.fs.stat(i),new J.Location(i,new J.Position(0,0))}catch{}let r=J.workspace.workspaceFolders?.[0]?.uri.fsPath;if(r){let d=J.Uri.file(St.resolve(r,s));try{return await J.workspace.fs.stat(d),new J.Location(d,new J.Position(0,0))}catch{}}let l=await J.workspace.findFiles(`**/${s}`,"**/node_modules/**",1);if(l.length>0)return new J.Location(l[0],new J.Position(0,0))}}function Kr(n,e,t){try{let i=Gr(n),r;for(let l of i.symbols)l.name===e&&l.kind!=="parameter"&&(l.line>t||(!r||l.line>r.line)&&(r=l));if(r)return new J.Location(n.uri,new J.Position(r.line,r.column))}catch{}let o=n.getText(),a=e.replace(/[.*+?^${}()|[\]\\]/g,"\\$&"),s=[new RegExp(`\\blocal\\s+function\\s+${a}\\s*\\(`),new RegExp(`^function\\s+${a}\\s*\\(`,"m"),new RegExp(`\\blocal\\s+${a}\\s*=\\s*function\\s*\\(`),new RegExp(`\\blocal\\s+${a}\\s*=`),new RegExp(`^${a}\\s*=\\s*\\{`,"m")];for(let i of s){let r=i.exec(o);if(r){let l=n.positionAt(r.index);return new J.Location(n.uri,l)}}}function $a(n,e){let t=new uo(e);n.subscriptions.push(J.workspace.registerTextDocumentContentProvider(_a,t));let o=J.languages.registerDefinitionProvider(Vr,{async provideDefinition(a,s){let i=a.lineAt(s).text,r=i.match(/require\s*\(\s*["']([^"']+)["']\s*\)/);if(r){let h=r[1],p=i.indexOf(h),f=p+h.length;if(s.character>=p&&s.character<=f)return Ur(a,h)}let l=a.getWordRangeAtPosition(s,/luna\.\w+\.\w+/);if(l){let h=a.getText(l);if(e.getFunction(h)){let f=J.Uri.parse(`${_a}:/${h}`);return new J.Location(f,new J.Position(0,0))}}let d=a.getWordRangeAtPosition(s,/\w+/);if(!d)return;let c=a.getText(d),u=i.substring(0,d.start.character);if(!(u.endsWith("luna.")||u.match(/luna\.\w+\.$/)))return Kr(a,c,s.line)}});n.subscriptions.push(o)}var Be=E(require("vscode"));var Qr={scheme:"file",language:"lua"},Zr=new Y;function Wa(n,e){let t=Be.languages.registerReferenceProvider(Qr,{async provideReferences(o,a,s){let i=o.getWordRangeAtPosition(a,/[\w.]+/);if(!i)return[];let r=o.getText(i);if(!r||r.length<2)return[];let l=(r.includes("."),r),d=[],c=await Be.workspace.findFiles("**/*.lua","**/node_modules/**",500);for(let u of c)try{let h=await Be.workspace.openTextDocument(u),p=h.getText(),f=Zr.findReferencesInDocument(p,l);for(let g of f)d.push(new Be.Location(u,new Be.Position(g.line,g.column)));if(l.includes(".")){let g=l.replace(/[.*+?^${}()|[\]\\]/g,"\\$&"),m=new RegExp(g,"g"),v;for(;(v=m.exec(p))!==null;){let y=h.positionAt(v.index);d.some(x=>x.uri.fsPath===u.fsPath&&x.range.start.line===y.line&&x.range.start.character===y.character)||d.push(new Be.Location(u,y))}}}catch{}return d}});n.subscriptions.push(t)}var A=E(require("vscode"));var tl={scheme:"file",language:"lua"},qa=new Y,nl=new Set(["load","update","draw","keypressed","keyreleased","textinput","mousepressed","mousereleased","wheelmoved","gamepadpressed","gamepadreleased","gamepadaxis","joystickadded","joystickremoved","touchpressed","touchmoved","touchreleased","focus","visible","resize","quit"]),Ha=new Map;function ol(n){let e=n.uri.toString(),t=Ha.get(e);if(t&&t.version===n.version)return t.info;let o=qa.analyze(n.getText());return Ha.set(e,{version:n.version,info:o}),o}function pt(n,e){let t=0,o=!1;for(let a=e;a<n.length;a++){let s=n[a].replace(/--.*$/,"").trim(),i=(s.match(/\b(function|if|for|while|repeat|do)\b/g)||[]).length,r=(s.match(/\bend\b/g)||[]).length,l=(s.match(/\buntil\b/g)||[]).length;if(t+=i-r-l,i>0&&(o=!0),o&&t<=0)return new A.Range(e,0,a,n[a].length)}return new A.Range(e,0,e,n[e]?.length??0)}function ja(n,e){let t=A.languages.registerDocumentSymbolProvider(tl,{provideDocumentSymbols(a){let s=[],r=a.getText().split(`
`);try{let l=ol(a),d=new Map;for(let c of l.requires){let u=r[c.line]?.length??0,h=new A.Range(c.line,0,c.line,u);s.push(new A.DocumentSymbol(c.localName,`require("${c.modulePath}")`,A.SymbolKind.Module,h,h))}for(let c of l.symbols){if(c.kind==="parameter")continue;let u=r[c.line]?.length??0,h=new A.Range(c.line,c.column,c.line,c.column+c.name.length);if(c.kind==="function"){let p=c.endLine!==void 0?new A.Range(c.line,0,c.endLine,r[c.endLine]?.length??0):pt(r,c.line),f=l.callbacks.some(b=>b.name===c.name&&b.line===c.line),g=f?A.SymbolKind.Event:A.SymbolKind.Function,m=f?"callback":c.isLocal?"local function":"function",v=f?`luna.${c.name}`:c.name,y=new A.DocumentSymbol(v,m,g,p,h);c.scope&&d.has(c.scope)?d.get(c.scope).children.push(y):s.push(y)}else if(c.kind==="method"){let p=c.endLine!==void 0?new A.Range(c.line,0,c.endLine,r[c.endLine]?.length??0):pt(r,c.line),f=c.type?`${c.type}:${c.name}`:c.name,g=new A.DocumentSymbol(f,"method",A.SymbolKind.Method,p,h);c.type&&d.has(c.type)?d.get(c.type).children.push(g):s.push(g)}else if(c.kind==="table"){let p=new A.Range(c.line,0,c.line,u),f=new A.DocumentSymbol(c.name,"table",A.SymbolKind.Object,p,h);d.set(c.name,f),s.push(f)}else if(c.kind==="local"||c.kind==="global"){let p=/^[A-Z_][A-Z0-9_]*$/.test(c.name),f=new A.Range(c.line,0,c.line,u),g=p?A.SymbolKind.Constant:A.SymbolKind.Variable,m=c.isLocal?"local":"global";(!c.isLocal||p||!c.scope)&&s.push(new A.DocumentSymbol(c.name,m,g,f,h))}}}catch{return al(r)}return s}}),o=A.languages.registerWorkspaceSymbolProvider({async provideWorkspaceSymbols(a){if(a.length<2)return[];let s=a.toLowerCase(),i=[],r=await A.workspace.findFiles("**/*.lua","**/node_modules/**",100);for(let l of r)try{let d=await A.workspace.openTextDocument(l),c=qa.analyze(d.getText());for(let u of c.symbols){if(u.kind==="parameter"||!u.name.toLowerCase().includes(s))continue;let h=u.kind==="function"||u.kind==="method"?A.SymbolKind.Function:u.kind==="table"?A.SymbolKind.Object:A.SymbolKind.Variable,p=new A.Location(l,new A.Position(u.line,u.column));i.push(new A.SymbolInformation(u.name,h,u.scope??"",p))}}catch{}return i}});n.subscriptions.push(t,o)}function al(n){let e=[];for(let t=0;t<n.length;t++){let o=n[t],a=o.match(/^\s*function\s+(luna\.\w+)\s*\(/);if(a){let d=a[1],c=pt(n,t),u=new A.Range(t,0,t,o.length),h=d.replace("luna.",""),p=nl.has(h)?A.SymbolKind.Event:A.SymbolKind.Function;e.push(new A.DocumentSymbol(d,"callback",p,c,u));continue}let s=o.match(/^\s*function\s+(\w[\w.:]*)\s*\(/);if(s){let d=s[1],c=pt(n,t),u=new A.Range(t,0,t,o.length);e.push(new A.DocumentSymbol(d,"function",A.SymbolKind.Function,c,u));continue}let i=o.match(/^\s*local\s+function\s+(\w+)\s*\(/);if(i){let d=i[1],c=pt(n,t),u=new A.Range(t,0,t,o.length);e.push(new A.DocumentSymbol(d,"local function",A.SymbolKind.Function,c,u));continue}let r=o.match(/^\s*local\s+(\w+)\s*=\s*function\s*\(/);if(r){let d=r[1],c=pt(n,t),u=new A.Range(t,0,t,o.length);e.push(new A.DocumentSymbol(d,"local function",A.SymbolKind.Function,c,u));continue}let l=o.match(/^\s*local\s+(\w+)\s*=\s*require\s*\(\s*["']([^"']+)["']\s*\)/);if(l){let d=new A.Range(t,0,t,o.length);e.push(new A.DocumentSymbol(l[1],`require("${l[2]}")`,A.SymbolKind.Module,d,d));continue}}return e}var z=E(require("vscode")),Ya=E(require("fs")),Xe=E(require("path"));var po=new Y;function Va(n,e){let t=z.languages.createDiagnosticCollection("luna");n.subscriptions.push(t);let o=new Map,a=i=>{if(i.languageId==="lua")try{let r=i.getText(),l=po.analyze(r),d=[];d.push(...il(r,e)),d.push(...rl(r)),d.push(...ll(r,l)),dl(r,i,d),d.push(...cl(r,l)),d.push(...ul(r,i,l)),d.push(...fl(r,e)),d.push(...gl(r,e)),vl(r,i,d),t.set(i.uri,d)}catch{}},s=i=>{let r=i.uri.toString(),l=o.get(r);l&&clearTimeout(l),o.set(r,setTimeout(()=>{o.delete(r),a(i)},300))};n.subscriptions.push(z.workspace.onDidOpenTextDocument(a),z.workspace.onDidSaveTextDocument(a),z.workspace.onDidChangeTextDocument(i=>s(i.document)),z.workspace.onDidCloseTextDocument(i=>{t.delete(i.uri);let r=i.uri.toString(),l=o.get(r);l&&(clearTimeout(l),o.delete(r))}));for(let i of z.workspace.textDocuments)a(i)}function il(n,e){let t=[],o=e.getAllFunctions().filter(s=>s.deprecated);if(o.length===0)return t;let a=n.split(`
`);for(let s of o){let i=s.fullPath.replace(/\./g,"\\."),r=new RegExp(i,"g");for(let l=0;l<a.length;l++){let d=a[l];if(d.trimStart().startsWith("--"))continue;let c;for(;(c=r.exec(d))!==null;){let u=new z.Range(l,c.index,l,c.index+s.fullPath.length),h=new z.Diagnostic(u,`${s.fullPath} is deprecated. ${s.deprecated}`,z.DiagnosticSeverity.Warning);h.code="luna.deprecated",h.source="Luna Toolkit",h.tags=[z.DiagnosticTag.Deprecated],t.push(h)}}}return t}function rl(n){let e=[],t=n.split(`
`),o=/luna\.graphics\.(?:setColor|setBackgroundColor|clear)\s*\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)/g;for(let a=0;a<t.length;a++){let s=t[a];if(s.trimStart().startsWith("--"))continue;let i;for(;(i=o.exec(s))!==null;){let r=[parseFloat(i[1]),parseFloat(i[2]),parseFloat(i[3])];if(i[4]!==void 0&&r.push(parseFloat(i[4])),!r.some(h=>h>1))continue;let d=r.slice(0,3).map(h=>(h/255).toFixed(2)),c=new z.Range(a,i.index,a,i.index+i[0].length),u=new z.Diagnostic(c,`Color values should be in 0-1 range. Did you mean ${d.join(", ")}?`,z.DiagnosticSeverity.Warning);u.code="luna.colorRange",u.source="Luna Toolkit",e.push(u)}}return e}function ll(n,e){let t=[];for(let o of e.requires){let a=o.localName;if(po.findReferencesInDocument(n,a).length<=1){let i=n.split(`
`),r=o.line,l=i[r]??"",d=new z.Range(r,0,r,l.length),c=new z.Diagnostic(d,`Required module '${a}' is never used`,z.DiagnosticSeverity.Hint);c.code="luna.unusedRequire",c.source="Luna Toolkit",c.tags=[z.DiagnosticTag.Unnecessary],t.push(c)}}return t}function dl(n,e,t){if(!z.workspace.workspaceFolders?.length)return;let o=n.split(`
`),a=/luna\.(?:graphics\.newImage|audio\.newSource|filesystem\.read)\s*\(\s*["']([^"']+)["']/g,s=Xe.dirname(e.uri.fsPath),i=z.workspace.workspaceFolders[0].uri.fsPath;for(let r=0;r<o.length;r++){let l=o[r];if(l.trimStart().startsWith("--"))continue;let d;for(;(d=a.exec(l))!==null;){let c=d[1];if(c.includes("://")||!c.includes("."))continue;if(![Xe.resolve(s,c),Xe.resolve(i,c)].some(p=>{try{return Ya.existsSync(p)}catch{return!1}})){let p=l.indexOf(c,d.index),f=new z.Range(r,p,r,p+c.length),g=new z.Diagnostic(f,`Asset file '${c}' not found in workspace`,z.DiagnosticSeverity.Warning);g.code="luna.assetNotFound",g.source="Luna Toolkit",t.push(g)}}}}function cl(n,e){let t=[];if(!n.includes("luna.thread"))return t;let o=n.split(`
`),a=/\bmath\.random\s*\(/g;for(let s=0;s<o.length;s++){let i=o[s];if(i.trimStart().startsWith("--"))continue;let r;for(;(r=a.exec(i))!==null;){let l=po.getScopeAt(e,s);if(!l||!o.slice(l.startLine,l.endLine+1).join(`
`).includes("luna.thread"))continue;let c=new z.Range(s,r.index,s,r.index+11),u=new z.Diagnostic(c,"math.random in threads may produce identical sequences. Consider seeding with thread ID.",z.DiagnosticSeverity.Information);u.code="luna.threadRandom",u.source="Luna Toolkit",t.push(u)}}return t}function ul(n,e,t){let o=[];if(Xe.basename(e.uri.fsPath)!=="main.lua")return o;let s=t.callbacks.some(r=>r.name==="update")||/luna\.update\s*=\s*function/.test(n),i=t.callbacks.some(r=>r.name==="draw")||/luna\.draw\s*=\s*function/.test(n);if(!s&&!i){let r=n.split(`
`),l=new z.Range(0,0,0,r[0]?.length??0),d=new z.Diagnostic(l,"main.lua should define luna.update(dt) and/or luna.draw()",z.DiagnosticSeverity.Information);d.code="luna.missingCallback",d.source="Luna Toolkit",o.push(d)}return o}var pl=[{pattern:/luna\.graphics\.(?:rectangle|circle|arc|polygon|ellipse)\s*\(\s*["']([^"']+)["']/g,valid:["fill","line"],label:"draw mode"},{pattern:/luna\.graphics\.setBlendMode\s*\(\s*["']([^"']+)["']/g,valid:["alpha","add","subtract","multiply","replace","screen","darken","lighten","none"],label:"blend mode"},{pattern:/luna\.graphics\.setLineStyle\s*\(\s*["']([^"']+)["']/g,valid:["smooth","rough"],label:"line style"},{pattern:/luna\.graphics\.setFilter\s*\([^,]*,\s*["']([^"']+)["']/g,valid:["linear","nearest"],label:"texture filter"},{pattern:/luna\.graphics\.setFilter\s*\(\s*["']([^"']+)["']/g,valid:["linear","nearest"],label:"texture filter"},{pattern:/luna\.audio\.newSource\s*\([^,]*,\s*["']([^"']+)["']/g,valid:["static","stream"],label:"audio source type"},{pattern:/luna\.physics\.newBody\s*\([^,]*,[^,]*,[^,]*,\s*["']([^"']+)["']/g,valid:["dynamic","static","kinematic"],label:"body type"},{pattern:/luna\.graphics\.printf\s*\([^)]*,[^)]*,[^)]*,[^)]*,\s*["']([^"']+)["']/g,valid:["left","center","right","justify"],label:"text alignment"}];function ml(n,e){for(let t of e){if(t===n)return;if(Math.abs(t.length-n.length)<=2){let o=0,a=Math.max(t.length,n.length);for(let s=0;s<a;s++)(t[s]??"")!==(n[s]??"")&&o++;if(o<=2)return t}}}function fl(n,e){let t=[],o=n.split(`
`);for(let a of pl)for(let s=0;s<o.length;s++){let i=o[s];if(i.trimStart().startsWith("--"))continue;a.pattern.lastIndex=0;let r;for(;(r=a.pattern.exec(i))!==null;){let l=r[1];if(a.valid.includes(l))continue;let d=ml(l,a.valid),c=i.indexOf(`"${l}"`,r.index)!==-1?i.indexOf(`"${l}"`,r.index)+1:i.indexOf(`'${l}'`,r.index)+1,u=new z.Range(s,c,s,c+l.length),h=d?`Unknown ${a.label} "${l}". Did you mean "${d}"? Valid: ${a.valid.join(", ")}`:`Unknown ${a.label} "${l}". Valid values: ${a.valid.join(", ")}`,p=new z.Diagnostic(u,h,z.DiagnosticSeverity.Warning);p.code="luna.wrongEnumValue",p.source="Luna Toolkit",t.push(p)}}return t}function gl(n,e){let t=[],o=n.split(`
`),a=/luna\.(\w+)\.(\w+)\s*\(/g;for(let s=0;s<o.length;s++){let i=o[s];if(i.trimStart().startsWith("--"))continue;a.lastIndex=0;let r;for(;(r=a.exec(i))!==null;){let l=r[1],d=r[2],c=`luna.${l}.${d}`;if(!e.getModule(l)||e.getFunction(c)||e.getFunctions(l).find(v=>v.name===d))continue;let f=r.index+`luna.${l}.`.length,g=new z.Range(s,f,s,f+d.length),m=new z.Diagnostic(g,`"${d}" is not a known function in luna.${l}`,z.DiagnosticSeverity.Warning);m.code="luna.unknownFunction",m.source="Luna Toolkit",t.push(m)}}return t}var hl={window:["title","width","height","vsync","fullscreen","resizable","highdpi","minwidth","minheight","x","y","borderless","displayindex","icon"],performance:["target_fps","fixed_dt"],modules:["physics","audio","graphics","input","timer","filesystem","math","thread"],log:["file","append","level"]};function vl(n,e,t){if(Xe.basename(e.uri.fsPath)!=="conf.lua")return;let o=n.split(`
`),a=/\bt\.(\w+)\.(\w+)\s*=/g;for(let s=0;s<o.length;s++){let i=o[s];if(i.trimStart().startsWith("--"))continue;a.lastIndex=0;let r;for(;(r=a.exec(i))!==null;){let l=r[1],d=r[2],c=hl[l];if(!c||c.includes(d))continue;let u=r.index+`t.${l}.`.length,h=new z.Range(s,u,s,u+d.length),p=new z.Diagnostic(h,`"${d}" is not a recognised conf.lua key in t.${l}. Valid: ${c.join(", ")}`,z.DiagnosticSeverity.Warning);p.code="luna.confKey",p.source="Luna Toolkit",t.push(p)}}}var ge=E(require("vscode")),bl={scheme:"file",language:"lua"},xl=["setColor","setBackgroundColor","clear","newColor"];function Xa(n,e){let t=ge.languages.registerColorProvider(bl,{provideDocumentColors(o){try{return kl(o)}catch{return[]}},provideColorPresentations(o,a){try{return Sl(o,a)}catch{return[]}}});n.subscriptions.push(t)}var wl=new RegExp(`luna\\.graphics\\.(?:${xl.join("|")})\\s*\\(\\s*([\\d.]+)\\s*,\\s*([\\d.]+)\\s*,\\s*([\\d.]+)(?:\\s*,\\s*([\\d.]+))?\\s*\\)`,"g");function kl(n){let e=[],t=n.getText(),o=new RegExp(wl.source,"g"),a;for(;(a=o.exec(t))!==null;){let s=parseFloat(a[1]),i=parseFloat(a[2]),r=parseFloat(a[3]),l=a[4]!==void 0?parseFloat(a[4]):1;if(s>1||i>1||r>1||l>1)continue;let d=a[0],c=d.indexOf("(")+1,u=d.lastIndexOf(")"),h=a.index+c,p=u-c,f=n.positionAt(h),g=n.positionAt(h+p),m=new ge.Range(f,g);e.push(new ge.ColorInformation(m,new ge.Color(s,i,r,l)))}return e}function Sl(n,e){let t=Ut(n.red),o=Ut(n.green),a=Ut(n.blue),s=Ut(n.alpha),i=[],r=new ge.ColorPresentation(`${t}, ${o}, ${a}, ${s}`);if(r.textEdit=new ge.TextEdit(e.range,`${t}, ${o}, ${a}, ${s}`),i.push(r),Math.abs(n.alpha-1)<.005){let h=new ge.ColorPresentation(`${t}, ${o}, ${a}`);h.textEdit=new ge.TextEdit(e.range,`${t}, ${o}, ${a}`),i.push(h)}let l=Math.round(n.red*255).toString(16).padStart(2,"0"),d=Math.round(n.green*255).toString(16).padStart(2,"0"),c=Math.round(n.blue*255).toString(16).padStart(2,"0"),u=new ge.ColorPresentation(`${t}, ${o}, ${a} --[[ #${l}${d}${c} ]]`);return u.textEdit=new ge.TextEdit(e.range,`${t}, ${o}, ${a} --[[ #${l}${d}${c} ]]`),i.push(u),i}function Ut(n){return n.toFixed(2).replace(/\.?0+$/,"")||"0"}var ke=E(require("vscode")),at=E(require("path"));var Cl={scheme:"file",language:"lua"},ou=new Y,Ga={"luna.graphics.newImage":[".png",".jpg",".jpeg",".bmp",".gif"],"luna.audio.newSource":[".ogg",".wav",".mp3",".flac"],"luna.filesystem.read":[],"luna.filesystem.write":[],"luna.filesystem.exists":[]},Tl=[".lua"];function Ua(n,e){let t=ke.languages.registerCompletionItemProvider(Cl,{async provideCompletionItems(o,a){try{return await Il(o,a)}catch{return}}},'"',"'","/");n.subscriptions.push(t)}async function Il(n,e){let o=n.lineAt(e).text.substring(0,e.character),a=o.match(/(luna\.\w+\.\w+)\s*\(\s*["']([^"']*)$/),s=o.match(/require\s*\(\s*["']([^"']*)$/);if(!a&&!s)return;let i=a?a[1]:"require",r=a?a[2]:s[1],l=[];if(i==="require")l=Tl;else if(i in Ga)l=Ga[i];else return;let d=ke.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!d)return;let c=r.includes("/")?at.dirname(r):"",u=c?`${c}/**/*`:"**/*",h=await ke.workspace.findFiles(u,"**/node_modules/**",200),p=[],f=new Set;for(let g of h){let m=at.extname(g.fsPath).toLowerCase();if(l.length>0&&!l.includes(m))continue;let v=at.relative(d,g.fsPath).replace(/\\/g,"/");if(i==="require"){let k=v.replace(/\.lua$/,"").replace(/\//g,"."),F=new ke.CompletionItem(k,ke.CompletionItemKind.Module);F.detail="Lua module",F.insertText=k;let q=k.split(".").length;F.sortText=String(q).padStart(3,"0")+k,p.push(F);continue}let y=at.dirname(v);if(y!=="."&&!f.has(y)&&(f.add(y),!r||y.startsWith(r.split("/")[0]))){let k=new ke.CompletionItem(y+"/",ke.CompletionItemKind.Folder);k.sortText="0"+y,p.push(k)}let b=new ke.CompletionItem(v,ke.CompletionItemKind.File);b.detail=m.toUpperCase().substring(1)+" file",b.insertText=v;let x=v.split("/").length;b.sortText=String(x).padStart(3,"0")+v,p.push(b)}return p}var Ge=E(require("vscode"));var Ll={scheme:"file",language:"lua"},su=new Y;function Ka(n,e){let t=Ge.languages.registerInlayHintsProvider(Ll,{provideInlayHints(o,a){try{return Ge.workspace.getConfiguration("luna").get("inlayHints.enabled")===!1?[]:Rl(o,a,e)}catch{return[]}}});n.subscriptions.push(t)}function Rl(n,e,t){let o=[],a=n.getText(e),s=n.offsetAt(e.start),i=/(luna\.\w+\.\w+)\s*\(/g,r;for(;(r=i.exec(a))!==null;){let l=r[1],d=t.getFunction(l);if(!d||d.parameters.length===0)continue;let c=r.index+r[0].length-1,u=Ml(a,c);if(!u)continue;let h=Dl(u);if(h.length<=1)continue;let f=s+c+1;for(let g=0;g<h.length&&g<d.parameters.length;g++){let m=h[g],v=m.trimStart(),y=m.length-v.length;if(/^\w+\s*=/.test(v)){f+=m.length+1;continue}let b=d.parameters[g];if(v===b.name){f+=m.length+1;continue}if(Al(v,b.name)){f+=m.length+1;continue}let x=n.positionAt(f+y),k=new Ge.InlayHint(x,`${b.name}:`,Ge.InlayHintKind.Parameter);k.paddingRight=!0,o.push(k),f+=m.length+1}}return o}function Ml(n,e){if(n[e]!=="(")return;let t=1,o=e+1;for(;o<n.length&&t>0;){let a=n[o];a==="("?t++:a===")"&&t--,o++}if(t===0)return n.slice(e+1,o-1)}function Dl(n){if(!n.trim())return[];let e=[],t="",o=0,a=null;for(let s=0;s<n.length;s++){let i=n[s];if(a&&i==="\\"){t+=i,s+1<n.length&&(t+=n[s+1],s++);continue}if(!a&&(i==='"'||i==="'")){a=i,t+=i;continue}if(a&&i===a){a=null,t+=i;continue}if(a){t+=i;continue}i==="("||i==="{"||i==="["?(o++,t+=i):i===")"||i==="}"||i==="]"?(o--,t+=i):i===","&&o===0?(e.push(t),t=""):t+=i}return t&&e.push(t),e}function Al(n,e){return(n==="true"||n==="false"||n==="nil")&&e.length<=4}var B=E(require("vscode"));var Bl={scheme:"file",language:"lua"},ru=new Y;function Ja(n,e){let t=B.languages.registerCodeActionsProvider(Bl,{provideCodeActions(o,a,s){try{return Nl(o,a,s)}catch{return[]}}},{providedCodeActionKinds:[B.CodeActionKind.QuickFix,B.CodeActionKind.RefactorExtract]});n.subscriptions.push(t)}function Nl(n,e,t){let o=[];for(let l of t.diagnostics)switch(l.code){case"luna.unusedRequire":o.push(...zl(n,l));break;case"luna.missingCallback":o.push(..._l(n,l));break;case"luna.colorRange":o.push(...Ol(n,l));break}let a=n.lineAt(e.start.line).text;e.isEmpty||(o.push($l(n,e)),o.push(ql(n,e)));let s=a.match(/^(\s*)(\w+)\s*=\s*(.+)/);s&&!a.trimStart().startsWith("local ")&&!a.trimStart().startsWith("function ")&&!a.trimStart().startsWith("--")&&!a.includes("luna.")&&!a.includes(".")&&!a.includes(":")&&o.push(Wl(n,e.start.line,s)),/\brequire\s*\(/.test(a)&&!/pcall/.test(a)&&o.push(Hl(n,e.start.line));let i=a.match(/^(\s*)local\s+(\w+)\s*=\s*(.+)/);if(i&&!e.isEmpty&&o.push(jl(n,e.start.line,i)),/^\s*if\s+/.test(a)){let l=Yl(n,e.start.line);l&&o.push(l)}let r=a.match(/^(\s*)local\s+(\w+)\s*=/);if(r&&!a.includes("---@type")&&o.push(Vl(n,e.start.line,r[2])),/(\w+)\.__index\s*=\s*\1/.test(a)||/setmetatable\s*\(\s*{/.test(a)){let l=a.match(/(\w+)\.__index/)?.[1];l&&o.push(Xl(n,e.start.line,l))}return o}function zl(n,e){let t=new B.CodeAction("Remove unused require",B.CodeActionKind.QuickFix);t.edit=new B.WorkspaceEdit;let o=e.range.start.line,a=new B.Range(o,0,o+1,0);return t.edit.delete(n.uri,a),t.diagnostics=[e],t.isPreferred=!0,[t]}function _l(n,e){let t=n.getText(),o=[];if(!/function\s+luna\.load\s*\(/.test(t)&&!/luna\.load\s*=\s*function/.test(t)&&o.push("load"),!/function\s+luna\.update\s*\(/.test(t)&&!/luna\.update\s*=\s*function/.test(t)&&o.push("update"),!/function\s+luna\.draw\s*\(/.test(t)&&!/luna\.draw\s*=\s*function/.test(t)&&o.push("draw"),o.length===0)return[];let a=new B.CodeAction("Generate Luna2D callbacks",B.CodeActionKind.QuickFix);a.edit=new B.WorkspaceEdit;let s=[];o.includes("load")&&s.push(`function luna.load()
    -- Initialize game
end`),o.includes("update")&&s.push(`function luna.update(dt)
    -- Update game logic
end`),o.includes("draw")&&s.push(`function luna.draw()
    -- Draw game objects
end`);let i=n.lineAt(n.lineCount-1).range.end;return a.edit.insert(n.uri,i,`

`+s.join(`

`)+`
`),a.diagnostics=[e],[a]}function Ol(n,e){let o=n.getText(e.range).match(/(luna\.graphics\.(?:setColor|setBackgroundColor|clear))\s*\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)/);if(!o)return[];let a=o[1],s=u=>(parseFloat(u)/255).toFixed(2).replace(/\.?0+$/,"")||"0",i=s(o[2]),r=s(o[3]),l=s(o[4]),d;if(o[5]!==void 0){let u=s(o[5]);d=`${a}(${i}, ${r}, ${l}, ${u})`}else d=`${a}(${i}, ${r}, ${l})`;let c=new B.CodeAction("Convert to 0-1 color range",B.CodeActionKind.QuickFix);return c.edit=new B.WorkspaceEdit,c.edit.replace(n.uri,e.range,d),c.diagnostics=[e],c.isPreferred=!0,[c]}function $l(n,e){let t=new B.CodeAction("Extract to local function",B.CodeActionKind.RefactorExtract);t.edit=new B.WorkspaceEdit;let o=n.getText(e),a=n.lineAt(e.start.line).text.match(/^(\s*)/)?.[1]??"",s="extracted_function",i=o.split(`
`).map((l,d)=>d===0?l:a+"    "+l),r=`${a}local function ${s}()
${a}    ${i.join(`
`)}
${a}end

`;return t.edit.insert(n.uri,new B.Position(e.start.line,0),r),t.edit.replace(n.uri,e,`${s}()`),t}function Wl(n,e,t){let o=new B.CodeAction("Convert to local variable",B.CodeActionKind.QuickFix);o.edit=new B.WorkspaceEdit;let a=n.lineAt(e).range,s=`${t[1]}local ${t[2]} = ${t[3]}`;return o.edit.replace(n.uri,a,s),o}function Hl(n,e){let t=n.lineAt(e).text,o=t.match(/^(\s*)/)?.[1]??"",a=new B.CodeAction("Wrap require in pcall",B.CodeActionKind.QuickFix);a.edit=new B.WorkspaceEdit;let s=t.match(/^(\s*)local\s+(\w+)\s*=\s*require\s*\(\s*["']([^"']+)["']\s*\)/);if(s){let i=s[2],r=s[3],l=[`${o}local ok, ${i} = pcall(require, "${r}")`,`${o}if not ok then`,`${o}    error("Failed to load module: " .. tostring(${i}))`,`${o}end`].join(`
`);a.edit.replace(n.uri,n.lineAt(e).range,l)}else{let i=t.match(/require\s*\(\s*["']([^"']+)["']\s*\)/);if(i){let r=i[1],l=[`${o}local ok, module = pcall(require, "${r}")`,`${o}if not ok then`,`${o}    error("Failed to load module: " .. tostring(module))`,`${o}end`].join(`
`);a.edit.replace(n.uri,n.lineAt(e).range,l)}}return a}function ql(n,e){let t=new B.CodeAction("Extract selection to new module file",B.CodeActionKind.RefactorExtract);return t.command={command:"luna.extractToModuleFile",title:"Extract to new module file",arguments:[n.uri,e]},t}function jl(n,e,t){let o=new B.CodeAction(`Inline variable '${t[2]}'`,B.CodeActionKind.RefactorInline);o.edit=new B.WorkspaceEdit;let a=t[1],s=t[3].trim();return o.edit.replace(n.uri,n.lineAt(e).range,`${a}-- TODO: inline '${t[2]}' = ${s}`),o}function Yl(n,e){let t=[],o=n.lineAt(e).text.match(/if\s+(\w+)\s*==\s*['"]/)?.[1];if(!o)return;for(let u=e;u<Math.min(e+40,n.lineCount)&&(t.push(n.lineAt(u).text),n.lineAt(u).text.trimStart()!=="end");u++);let a=[],s=0;for(;s<t.length;){let u=t[s].match(/(?:if|elseif)\s+\w+\s*==\s*['"](\w+)['"]\s*then/);if(u){let h=u[1],p=[];for(s++;s<t.length&&!/(?:elseif|else|end)/.test(t[s].trimStart());)p.push(t[s].replace(/^\s{4}/,"    ")),s++;a.push({key:h,body:p.join(`
`)})}else s++}if(a.length<2)return;let i=(n.lineAt(e).text.match(/^(\s*)/)??["",""])[1],r=`${o}Handlers`,l=[`${i}local ${r} = {`,...a.map(u=>`${i}  ${u.key} = function()
${u.body}
${i}  end,`),`${i}}`,`${i}local _handler = ${r}[${o}]`,`${i}if _handler then _handler() end`],d=new B.CodeAction(`Convert if/elseif chain to state-map (${r})`,B.CodeActionKind.RefactorRewrite);d.edit=new B.WorkspaceEdit;let c=new B.Range(e,0,e+t.length-1,n.lineAt(e+t.length-1).range.end.character);return d.edit.replace(n.uri,c,l.join(`
`)),d}function Vl(n,e,t){let o=new B.CodeAction(`Add ---@type annotation for '${t}'`,B.CodeActionKind.RefactorRewrite);o.edit=new B.WorkspaceEdit;let a=(n.lineAt(e).text.match(/^(\s*)/)??["",""])[1],s=new B.Position(e,0);return o.edit.insert(n.uri,s,`${a}---@type any
`),o}function Xl(n,e,t){let o=new B.CodeAction(`Generate __tostring for ${t}`,B.CodeActionKind.QuickFix);o.edit=new B.WorkspaceEdit;let a=(n.lineAt(e).text.match(/^(\s*)/)??["",""])[1],s=new B.Position(e+1,0);return o.edit.insert(n.uri,s,`
${a}function ${t}:__tostring()
${a}  return "${t}()"  -- TODO: fill in fields
${a}end
`),o}var N=E(require("vscode")),Qa={scheme:"file",language:"lua"},Za=[{name:"band",sig:"bit.band(a, b)",desc:"Bitwise AND"},{name:"bor",sig:"bit.bor(a, b)",desc:"Bitwise OR"},{name:"bxor",sig:"bit.bxor(a, b)",desc:"Bitwise XOR"},{name:"bnot",sig:"bit.bnot(a)",desc:"Bitwise NOT"},{name:"lshift",sig:"bit.lshift(a, n)",desc:"Left shift"},{name:"rshift",sig:"bit.rshift(a, n)",desc:"Logical right shift"},{name:"arshift",sig:"bit.arshift(a, n)",desc:"Arithmetic right shift"},{name:"tobit",sig:"bit.tobit(n)",desc:"Normalize to int32"},{name:"tohex",sig:"bit.tohex(n, [len])",desc:"Format as hex string"},{name:"rol",sig:"bit.rol(a, n)",desc:"Rotate left"},{name:"ror",sig:"bit.ror(a, n)",desc:"Rotate right"},{name:"bswap",sig:"bit.bswap(n)",desc:"Byte-swap a 32-bit integer"}],es=[{name:"on",sig:"jit.on([func])",desc:"Enable JIT for function or globally"},{name:"off",sig:"jit.off([func])",desc:"Disable JIT (useful for debugging)"},{name:"flush",sig:"jit.flush([func])",desc:"Flush JIT cache"},{name:"status",sig:"jit.status()",desc:"Returns JIT engine status"},{name:"version",sig:"jit.version",desc:"LuaJIT version string"},{name:"version_num",sig:"jit.version_num",desc:"LuaJIT version number"},{name:"os",sig:"jit.os",desc:"Target OS name"},{name:"arch",sig:"jit.arch",desc:"Target architecture name"}],ts=[{name:"cdef",sig:"ffi.cdef(def)",desc:"Add C declarations"},{name:"new",sig:"ffi.new(ct, [init...])",desc:"Create cdata object"},{name:"cast",sig:"ffi.cast(ct, init)",desc:"Cast to ctype"},{name:"typeof",sig:"ffi.typeof(ct)",desc:"Create ctype object"},{name:"sizeof",sig:"ffi.sizeof(ct, [nelem])",desc:"Size of ctype in bytes"},{name:"string",sig:"ffi.string(ptr, [len])",desc:"Create Lua string from pointer"},{name:"copy",sig:"ffi.copy(dst, src, len)",desc:"Copy memory"},{name:"fill",sig:"ffi.fill(dst, len, [c])",desc:"Fill memory"},{name:"istype",sig:"ffi.istype(ct, obj)",desc:"Check cdata type"},{name:"load",sig:"ffi.load(name, [global])",desc:"Load dynamic library"}],Ul=[{code:"luna.perf.tableAllocHotPath",pattern:/\{\s*\}/,message:"Table allocation `{}` in hot path \u2014 consider pre-allocating or using an object pool.",severity:N.DiagnosticSeverity.Hint,hotPathOnly:!0},{code:"luna.perf.newInHotPath",pattern:/luna\.\w+\.new\w*\s*\(/,message:"Resource creation (luna.*.new*) in hot path \u2014 move to luna.load() or cache the result.",severity:N.DiagnosticSeverity.Warning,hotPathOnly:!0},{code:"luna.perf.globalInLoop",pattern:/\bfor\b.+\bdo\b/,message:"Loop detected \u2014 ensure frequently accessed globals are cached as locals above the loop.",severity:N.DiagnosticSeverity.Hint,hotPathOnly:!1},{code:"luna.perf.stringConcatLoop",pattern:/\.\.\s*["']/,message:"String concatenation in loop \u2014 consider table.insert + table.concat for better performance.",severity:N.DiagnosticSeverity.Hint,hotPathOnly:!0},{code:"luna.perf.pcallHotPath",pattern:/\bpcall\s*\(/,message:"pcall in hot path adds overhead \u2014 consider error handling outside the frame loop.",severity:N.DiagnosticSeverity.Hint,hotPathOnly:!0},{code:"luna.perf.mathFloor",pattern:/math\.floor\s*\(/,message:"Consider bit.tobit() or x%1 for faster integer conversion in LuaJIT.",severity:N.DiagnosticSeverity.Hint,hotPathOnly:!0},{code:"luna.perf.mathRandom",pattern:/math\.random\s*\(/,message:"Use luna.math.random() for deterministic, seedable RNG consistent across platforms.",severity:N.DiagnosticSeverity.Information,hotPathOnly:!1},{code:"luna.perf.unpackInLoop",pattern:/\bunpack\s*\(/,message:"unpack() in hot path creates temporary values \u2014 prefer indexed access for known structures.",severity:N.DiagnosticSeverity.Hint,hotPathOnly:!0}],Kl=[{code:"luna.compat.constAttribute",pattern:/\blocal\s+\w+\s*<\s*const\s*>/,message:"Lua 5.4 `<const>` attribute is not supported in LuaJIT. Remove the attribute \u2014 LuaJIT inlines constants automatically."},{code:"luna.compat.closeAttribute",pattern:/\blocal\s+\w+\s*<\s*close\s*>/,message:"Lua 5.4 `<close>` (to-be-closed variable) is not supported in LuaJIT. Use explicit :close() or defer via a wrapper."},{code:"luna.compat.utf8Library",pattern:/\butf8\s*\.\s*\w+\s*\(/,message:"The `utf8` standard library is not available in LuaJIT. Use luna.utf8.* instead or the luajit-utf8 binding."},{code:"luna.compat.tableMove",pattern:/\btable\s*\.\s*move\s*\(/,message:"`table.move` behaviour differs between Lua 5.4 and LuaJIT. Test carefully, or use a manual loop for portability."},{code:"luna.compat.bitwiseTilde",pattern:/(?<![=<>~])\s*~(?!\s*=)\s*(?![-\\/])/,message:"Lua 5.4 bitwise `~` (XOR / NOT) operator is not supported in LuaJIT. Use `bit.bxor(a, b)` or `bit.bnot(a)` instead."},{code:"luna.compat.intDivOp",pattern:/\/\//,message:"Floor-division operator `//` is a LuaJIT extension that matches Lua 5.4. Behaviour is consistent \u2014 no action needed. (Hint only.)"},{code:"luna.compat.warnLevel",pattern:/\bwarn\s*\(/,message:"`warn()` is a Lua 5.4-only function and is not available in LuaJIT. Use `print()` or `luna.log.warn()` instead."}];function Jl(n){let e=new Set,t=n.split(`
`),o=0,a=!1;for(let s=0;s<t.length;s++){let i=t[s];if(/^\s*function\s+luna\.(update|draw)\s*\(/.test(i)&&(a=!0,o=0),a){let r=(i.match(/\b(function|do|then|repeat)\b/g)||[]).length,l=(i.match(/\b(end|until)\b/g)||[]).length;o+=r-l,e.add(s),o<=0&&s>0&&(a=!1)}}return e}function ns(n,e){let t=[],o=N.languages.registerCompletionItemProvider(Qa,{provideCompletionItems(d,c){let h=d.lineAt(c).text.substring(0,c.character),p=h.match(/\bbit\.(\w*)$/);if(p){let m=p[1].toLowerCase();return Za.filter(v=>!m||v.name.toLowerCase().startsWith(m)).map(v=>{let y=new N.CompletionItem(v.name,N.CompletionItemKind.Function);return y.detail=v.sig,y.documentation=new N.MarkdownString(`**LuaJIT bit library**

${v.desc}`),y})}let f=h.match(/\bjit\.(\w*)$/);if(f){let m=f[1].toLowerCase();return es.filter(v=>!m||v.name.toLowerCase().startsWith(m)).map(v=>{let y=v.sig.includes("(")?N.CompletionItemKind.Function:N.CompletionItemKind.Property,b=new N.CompletionItem(v.name,y);return b.detail=v.sig,b.documentation=new N.MarkdownString(`**LuaJIT jit library**

${v.desc}`),b})}let g=h.match(/\bffi\.(\w*)$/);if(g){let m=g[1].toLowerCase();return ts.filter(v=>!m||v.name.toLowerCase().startsWith(m)).map(v=>{let y=new N.CompletionItem(v.name,N.CompletionItemKind.Function);return y.detail=v.sig,y.documentation=new N.MarkdownString(`**LuaJIT FFI library**

${v.desc}`),y})}}},".");t.push(o);let a=N.languages.registerHoverProvider(Qa,{provideHover(d,c){let u=[[/bit\.\w+/,"LuaJIT bit library",Za],[/jit\.\w+/,"LuaJIT jit library",es],[/ffi\.\w+/,"LuaJIT FFI library",ts]];for(let[h,p,f]of u){let g=d.getWordRangeAtPosition(c,h);if(!g)continue;let v=d.getText(g).split(".")[1],y=f.find(x=>x.name===v);if(!y)continue;let b=new N.MarkdownString;return b.appendCodeblock(y.sig,"lua"),b.appendMarkdown(`
**${p}**

${y.desc}
`),b.isTrusted=!0,new N.Hover(b,g)}}});t.push(a);let s=N.languages.createDiagnosticCollection("luna.luajit");t.push(s);let i=N.languages.createDiagnosticCollection("luna.compat");t.push(i);function r(d){if(d.languageId!=="lua")return;let c=d.getText(),u=Jl(c),h=[],p=c.split(`
`);for(let f=0;f<p.length;f++){let g=p[f];if(!/^\s*--/.test(g))for(let m of Ul){if(m.hotPathOnly&&!u.has(f))continue;let v=m.pattern.exec(g);if(v){let y=v.index,b=v.index+v[0].length,x=new N.Range(f,y,f,b),k=new N.Diagnostic(x,m.message,m.severity);k.code=m.code,k.source="Luna LuaJIT",h.push(k)}}}s.set(d.uri,h)}function l(d){if(d.languageId!=="lua")return;let c=d.getText(),u=[],h=c.split(`
`);for(let p=0;p<h.length;p++){let f=h[p];if(/^\s*--/.test(f))continue;let g=f.replace(/--.*$/,"");for(let m of Kl){let v=m.pattern.exec(g);if(v){let y=v.index,b=v.index+v[0].length,x=new N.Range(p,y,p,b),k=m.code==="luna.compat.intDivOp"?N.DiagnosticSeverity.Hint:N.DiagnosticSeverity.Warning,F=new N.Diagnostic(x,m.message,k);F.code=m.code,F.source="Luna Compat",u.push(F)}}}i.set(d.uri,u)}N.window.activeTextEditor&&(r(N.window.activeTextEditor.document),l(N.window.activeTextEditor.document)),t.push(N.window.onDidChangeActiveTextEditor(d=>{d&&(r(d.document),l(d.document))}),N.workspace.onDidChangeTextDocument(d=>{r(d.document),l(d.document)}),N.workspace.onDidCloseTextDocument(d=>{s.delete(d.uri),i.delete(d.uri)})),n.subscriptions.push(...t)}var Te=E(require("vscode")),os={scheme:"file",language:"lua"},mo={"luna.graphics.newImage":{typeName:"Image",methods:[{name:"getDimensions",sig:":getDimensions()",desc:"Returns width, height"},{name:"getWidth",sig:":getWidth()",desc:"Returns pixel width"},{name:"getHeight",sig:":getHeight()",desc:"Returns pixel height"},{name:"getFilter",sig:":getFilter()",desc:"Returns min, mag filter modes"},{name:"setFilter",sig:":setFilter(min, mag)",desc:"Set texture filter"},{name:"setWrap",sig:":setWrap(horiz, vert)",desc:"Set texture wrap mode"},{name:"getWrap",sig:":getWrap()",desc:"Returns horizontal, vertical wrap"},{name:"release",sig:":release()",desc:"Free GPU resources"},{name:"type",sig:":type()",desc:"Returns 'Image'"}]},"luna.graphics.newCanvas":{typeName:"Canvas",methods:[{name:"getDimensions",sig:":getDimensions()",desc:"Returns width, height"},{name:"getWidth",sig:":getWidth()",desc:"Returns pixel width"},{name:"getHeight",sig:":getHeight()",desc:"Returns pixel height"},{name:"getFilter",sig:":getFilter()",desc:"Returns min, mag filter modes"},{name:"setFilter",sig:":setFilter(min, mag)",desc:"Set texture filter"},{name:"renderTo",sig:":renderTo(fn)",desc:"Render to this canvas"},{name:"release",sig:":release()",desc:"Free GPU resources"},{name:"type",sig:":type()",desc:"Returns 'Canvas'"}]},"luna.graphics.newFont":{typeName:"Font",methods:[{name:"getWidth",sig:":getWidth(text)",desc:"Width of text in pixels"},{name:"getHeight",sig:":getHeight()",desc:"Font height in pixels"},{name:"getLineHeight",sig:":getLineHeight()",desc:"Returns line height multiplier"},{name:"setLineHeight",sig:":setLineHeight(h)",desc:"Set line height multiplier"},{name:"getAscent",sig:":getAscent()",desc:"Returns font ascent"},{name:"getDescent",sig:":getDescent()",desc:"Returns font descent"},{name:"hasGlyphs",sig:":hasGlyphs(text)",desc:"Check if font has glyphs"},{name:"release",sig:":release()",desc:"Free resources"},{name:"type",sig:":type()",desc:"Returns 'Font'"}]},"luna.graphics.newShader":{typeName:"Shader",methods:[{name:"send",sig:":send(name, value)",desc:"Set uniform value"},{name:"hasUniform",sig:":hasUniform(name)",desc:"Check if uniform exists"},{name:"release",sig:":release()",desc:"Free GPU resources"},{name:"type",sig:":type()",desc:"Returns 'Shader'"}]},"luna.graphics.newMesh":{typeName:"Mesh",methods:[{name:"setVertices",sig:":setVertices(verts)",desc:"Set vertex data"},{name:"setTexture",sig:":setTexture(tex)",desc:"Set texture for mesh"},{name:"getVertexCount",sig:":getVertexCount()",desc:"Returns vertex count"},{name:"release",sig:":release()",desc:"Free GPU resources"},{name:"type",sig:":type()",desc:"Returns 'Mesh'"}]},"luna.graphics.newSpriteBatch":{typeName:"SpriteBatch",methods:[{name:"add",sig:":add(quad, x, y, r, sx, sy)",desc:"Add sprite to batch"},{name:"clear",sig:":clear()",desc:"Remove all sprites"},{name:"getCount",sig:":getCount()",desc:"Returns current sprite count"},{name:"set",sig:":set(id, quad, x, y, r, sx, sy)",desc:"Update sprite at index"},{name:"flush",sig:":flush()",desc:"Upload data to GPU"},{name:"release",sig:":release()",desc:"Free GPU resources"},{name:"type",sig:":type()",desc:"Returns 'SpriteBatch'"}]},"luna.graphics.newQuad":{typeName:"Quad",methods:[{name:"getViewport",sig:":getViewport()",desc:"Returns x, y, w, h"},{name:"setViewport",sig:":setViewport(x, y, w, h)",desc:"Set viewport rect"},{name:"getTextureDimensions",sig:":getTextureDimensions()",desc:"Returns ref width, height"},{name:"type",sig:":type()",desc:"Returns 'Quad'"}]},"luna.audio.newSource":{typeName:"Source",methods:[{name:"play",sig:":play()",desc:"Start or resume playback"},{name:"pause",sig:":pause()",desc:"Pause playback"},{name:"stop",sig:":stop()",desc:"Stop and rewind"},{name:"isPlaying",sig:":isPlaying()",desc:"Returns true if playing"},{name:"setVolume",sig:":setVolume(v)",desc:"Set volume (0-1)"},{name:"getVolume",sig:":getVolume()",desc:"Returns current volume"},{name:"setPitch",sig:":setPitch(p)",desc:"Set pitch multiplier"},{name:"getPitch",sig:":getPitch()",desc:"Returns pitch"},{name:"setLooping",sig:":setLooping(loop)",desc:"Enable/disable loop"},{name:"isLooping",sig:":isLooping()",desc:"Returns loop state"},{name:"seek",sig:":seek(seconds)",desc:"Seek to position"},{name:"tell",sig:":tell()",desc:"Returns current position"},{name:"getDuration",sig:":getDuration()",desc:"Returns duration in seconds"},{name:"release",sig:":release()",desc:"Free audio resources"},{name:"type",sig:":type()",desc:"Returns 'Source'"}]},"luna.physics.newWorld":{typeName:"World",methods:[{name:"update",sig:":update(dt)",desc:"Step the simulation"},{name:"setGravity",sig:":setGravity(gx, gy)",desc:"Set gravity vector"},{name:"getGravity",sig:":getGravity()",desc:"Returns gx, gy"},{name:"getBodyCount",sig:":getBodyCount()",desc:"Number of bodies"},{name:"queryBoundingBox",sig:":queryBoundingBox(x1, y1, x2, y2, fn)",desc:"Query AABB"},{name:"rayCast",sig:":rayCast(x1, y1, x2, y2, fn)",desc:"Cast a ray"},{name:"setCallbacks",sig:":setCallbacks(begin, end, pre, post)",desc:"Set collision callbacks"},{name:"destroy",sig:":destroy()",desc:"Destroy physics world"},{name:"type",sig:":type()",desc:"Returns 'World'"}]},"luna.physics.newBody":{typeName:"Body",methods:[{name:"getPosition",sig:":getPosition()",desc:"Returns x, y"},{name:"setPosition",sig:":setPosition(x, y)",desc:"Set position"},{name:"getAngle",sig:":getAngle()",desc:"Returns rotation in radians"},{name:"setAngle",sig:":setAngle(angle)",desc:"Set rotation"},{name:"getLinearVelocity",sig:":getLinearVelocity()",desc:"Returns vx, vy"},{name:"setLinearVelocity",sig:":setLinearVelocity(vx, vy)",desc:"Set velocity"},{name:"applyForce",sig:":applyForce(fx, fy)",desc:"Apply force at center"},{name:"applyLinearImpulse",sig:":applyLinearImpulse(ix, iy)",desc:"Apply impulse"},{name:"setMass",sig:":setMass(mass)",desc:"Set body mass"},{name:"getMass",sig:":getMass()",desc:"Returns body mass"},{name:"setType",sig:":setType(type)",desc:"Set body type"},{name:"getType",sig:":getType()",desc:"Returns body type string"},{name:"isAwake",sig:":isAwake()",desc:"Returns true if body is awake"},{name:"destroy",sig:":destroy()",desc:"Remove body from world"},{name:"type",sig:":type()",desc:"Returns 'Body'"}]},"luna.graphics.newParticleSystem":{typeName:"ParticleSystem",methods:[{name:"emit",sig:":emit(count)",desc:"Emit particles"},{name:"update",sig:":update(dt)",desc:"Update particle system"},{name:"start",sig:":start()",desc:"Start emitting"},{name:"stop",sig:":stop()",desc:"Stop emitting"},{name:"pause",sig:":pause()",desc:"Pause system"},{name:"reset",sig:":reset()",desc:"Reset and clear particles"},{name:"getCount",sig:":getCount()",desc:"Returns active particle count"},{name:"setEmissionRate",sig:":setEmissionRate(rate)",desc:"Particles per second"},{name:"setLifetime",sig:":setLifetime(min, max)",desc:"Set particle lifetime range"},{name:"setPosition",sig:":setPosition(x, y)",desc:"Set emitter position"},{name:"setSpeed",sig:":setSpeed(min, max)",desc:"Set speed range"},{name:"setDirection",sig:":setDirection(angle)",desc:"Set emission direction"},{name:"setSpread",sig:":setSpread(spread)",desc:"Set emission cone angle"},{name:"release",sig:":release()",desc:"Free resources"},{name:"type",sig:":type()",desc:"Returns 'ParticleSystem'"}]},"luna.cardgame.clone":{typeName:"Card",fields:[{name:"card_type",type:"string",desc:"The registered card type name"},{name:"name",type:"string",desc:"Card display name"},{name:"category",type:"string",desc:"Category (creature, spell, etc.)"},{name:"face_up",type:"boolean",desc:"Whether the card is face-up"},{name:"tapped",type:"boolean",desc:"Whether the card is tapped/exhausted"},{name:"owner",type:"string",desc:"Owner player identifier"},{name:"controller",type:"string",desc:"Controller player identifier"},{name:"zone",type:"string",desc:"Current zone name"}],methods:[{name:"hasTag",sig:":hasTag(tag)",desc:"Returns true if card has the tag"},{name:"addTag",sig:":addTag(tag)",desc:"Add a tag (deduplicated)"},{name:"removeTag",sig:":removeTag(tag)",desc:"Remove a tag by value"},{name:"getStat",sig:":getStat(name)",desc:"Get a numeric stat value"},{name:"setStat",sig:":setStat(name, value)",desc:"Set a numeric stat value"},{name:"addCounter",sig:":addCounter(kind, amount)",desc:"Add to a counter, returns new total"},{name:"getCounter",sig:":getCounter(kind)",desc:"Get a counter value"},{name:"tap",sig:":tap()",desc:"Tap the card (exhausted)"},{name:"untap",sig:":untap()",desc:"Untap the card"},{name:"getMeta",sig:":getMeta(key)",desc:"Get metadata value"},{name:"setMeta",sig:":setMeta(key, value)",desc:"Set metadata value"}]},"luna.cardgame.newCard":{typeName:"Card",fields:[{name:"card_type",type:"string",desc:"The registered card type name"},{name:"name",type:"string",desc:"Card display name"},{name:"category",type:"string",desc:"Category (creature, spell, etc.)"},{name:"face_up",type:"boolean",desc:"Whether the card is face-up"},{name:"tapped",type:"boolean",desc:"Whether the card is tapped/exhausted"},{name:"owner",type:"string",desc:"Owner player identifier"},{name:"controller",type:"string",desc:"Controller player identifier"},{name:"zone",type:"string",desc:"Current zone name"}],methods:[{name:"hasTag",sig:":hasTag(tag)",desc:"Returns true if card has the tag"},{name:"addTag",sig:":addTag(tag)",desc:"Add a tag (deduplicated)"},{name:"removeTag",sig:":removeTag(tag)",desc:"Remove a tag by value"},{name:"getStat",sig:":getStat(name)",desc:"Get a numeric stat value"},{name:"setStat",sig:":setStat(name, value)",desc:"Set a numeric stat value"},{name:"addCounter",sig:":addCounter(kind, amount)",desc:"Add to a counter, returns new total"},{name:"getCounter",sig:":getCounter(kind)",desc:"Get a counter value"},{name:"removeCounters",sig:":removeCounters(kind)",desc:"Remove all counters of a type"},{name:"getMeta",sig:":getMeta(key)",desc:"Get metadata value"},{name:"setMeta",sig:":setMeta(key, value)",desc:"Set metadata value"},{name:"tap",sig:":tap()",desc:"Tap the card (exhausted)"},{name:"untap",sig:":untap()",desc:"Untap the card"},{name:"getAllCounters",sig:":getAllCounters()",desc:"Returns all (kind, count) counter pairs"}]},"luna.cardgame.newDeck":{typeName:"Deck",fields:[{name:"name",type:"string",desc:"Deck display name"}],methods:[{name:"shuffle",sig:":shuffle()",desc:"Shuffle using Fisher-Yates"},{name:"draw",sig:":draw()",desc:"Draw from the top; returns Card or nil"},{name:"drawBottom",sig:":drawBottom()",desc:"Draw from the bottom"},{name:"pushTop",sig:":pushTop(card)",desc:"Add a card to the top"},{name:"pushBottom",sig:":pushBottom(card)",desc:"Add a card to the bottom"},{name:"peek",sig:":peek()",desc:"Peek at the top card without removing"},{name:"insertAt",sig:":insertAt(index, card)",desc:"Insert a card at a 0-based position"},{name:"removeAt",sig:":removeAt(index)",desc:"Remove and return card at index"},{name:"moveWithin",sig:":moveWithin(from, to)",desc:"Move card at from_index to to_index"},{name:"size",sig:":size()",desc:"Returns card count"},{name:"isEmpty",sig:":isEmpty()",desc:"Returns true if empty"},{name:"searchByTag",sig:":searchByTag(tag)",desc:"Returns indices of cards with tag"},{name:"searchByType",sig:":searchByType(card_type)",desc:"Returns indices of matching type"},{name:"countByType",sig:":countByType(card_type)",desc:"Count cards of a specific type"},{name:"revealTop",sig:":revealTop(n)",desc:"Peek at top n cards, returns type strings"},{name:"reset",sig:":reset()",desc:"Reset to original state"}]},"luna.cardgame.newDeckBuilder":{typeName:"DeckBuilder",fields:[{name:"min_cards",type:"integer",desc:"Minimum total cards required"},{name:"max_cards",type:"integer",desc:"Maximum total cards allowed (0 = no limit)"},{name:"max_copies",type:"integer",desc:"Maximum copies of a single card type"}],methods:[{name:"validate",sig:":validate(deck)",desc:"Validate a deck, returns list of violation messages"}]},"luna.cardgame.newStackManager":{typeName:"StackManager",methods:[{name:"push",sig:":push(entry)",desc:"Push an entry onto the stack"},{name:"resolve",sig:":resolve()",desc:"Pop and return the top entry"},{name:"peek",sig:":peek()",desc:"Peek at the top entry"},{name:"isEmpty",sig:":isEmpty()",desc:"Whether the stack has anything to resolve"},{name:"size",sig:":size()",desc:"Number of entries on the stack"},{name:"clear",sig:":clear()",desc:"Clear all entries"},{name:"findByKind",sig:":findByKind(kind)",desc:"Find first entry matching a kind"}]},"luna.cardgame.newZone":{typeName:"Zone",fields:[{name:"name",type:"string",desc:"Zone name"},{name:"capacity",type:"integer",desc:"Max capacity (0 = unlimited)"}],methods:[{name:"canAdd",sig:":canAdd()",desc:"Returns true if zone accepts one more card"},{name:"add",sig:":add(card)",desc:"Add a card (returns error if zone full)"},{name:"removeAt",sig:":removeAt(index)",desc:"Remove card at 0-based index"},{name:"size",sig:":size()",desc:"Number of cards in zone"},{name:"isEmpty",sig:":isEmpty()",desc:"True if empty"},{name:"findByType",sig:":findByType(card_type)",desc:"Find first card by type"},{name:"countByType",sig:":countByType(card_type)",desc:"Count cards of a specific type"},{name:"getAllTypes",sig:":getAllTypes()",desc:"Return type strings of all cards"}]},"luna.cardgame.newCardPool":{typeName:"CardPool",fields:[{name:"name",type:"string",desc:"Pool name"}],methods:[{name:"add",sig:":add(card_type, weight)",desc:"Add a card type with weight (default 1)"},{name:"remove",sig:":remove(card_type)",desc:"Remove a card type from pool"},{name:"draw",sig:":draw(n)",desc:"Draw n cards (with replacement), returns type names"},{name:"size",sig:":size()",desc:"Number of entries"},{name:"getTypes",sig:":getTypes()",desc:"Returns all card types in pool"},{name:"totalWeight",sig:":totalWeight()",desc:"Total weight of all entries"}]}};function as(n){let e=[],t=[],o=new Map,s=n.getText().split(`
`);for(let i=0;i<s.length;i++){let r=s[i],l=r.match(/\blocal\s+(\w+)\s*=\s*(luna\.\w+\.\w+)\s*\(/);if(l){let[,f,g]=l,m=mo[g];m&&e.push({varName:f,typeName:m.typeName,line:i})}let d=r.match(/\b(?:local\s+)?(\w+)\s*=\s*\{\s*\}/);if(d){let f=d[1];if(i+1<s.length){let g=s[i+1];(g.includes(`${f}.__index`)||g.includes(`__index = ${f}`))&&(o.has(f)||o.set(f,{name:f,methods:[],instances:[]}))}}let c=r.match(/\b(\w+)\.__index\s*=\s*\1\b/);if(c){let f=c[1];o.has(f)||o.set(f,{name:f,methods:[],instances:[]})}let u=r.match(/\bfunction\s+(\w+):(\w+)\s*\(/);if(u){let[,f,g]=u,m=o.get(f);m||(m={name:f,methods:[],instances:[]},o.set(f,m)),m.methods.find(v=>v.name===g)||m.methods.push({name:g,sig:`:${g}(...)`,desc:`Method of ${f}`})}let h=r.match(/\blocal\s+(\w+)\s*=\s*(\w+)[:.](new|create)\s*\(/);if(h){let[,f,g]=h,m=o.get(g);m&&m.instances.push({varName:f,line:i})}let p=r.match(/\blocal\s+(\w+)\s*=\s*setmetatable\s*\([^,]*,\s*(\w+)\s*\)/)??r.match(/\blocal\s+(\w+)\s*=\s*setmetatable\s*\([^,]*,\s*\{[^}]*__index\s*=\s*(\w+)[^}]*\}\s*\)/);if(p){let[,f,g]=p,m=o.get(g);m&&m.instances.push({varName:f,line:i})}}for(let i of o.values())t.push(i);return{varTypes:e,classes:t}}function Zl(n,e,t,o){let a=t.find(s=>s.varName===n&&s.line<e.line);if(a){let s=Object.values(mo).find(i=>i.typeName===a.typeName);if(s)return s.methods}for(let s of o)if(s.instances.find(r=>r.varName===n&&r.line<e.line)&&s.methods.length>0)return s.methods}function ss(n,e){let t=Te.languages.registerCompletionItemProvider(os,{provideCompletionItems(a,s){let l=a.lineAt(s).text.substring(0,s.character).match(/\b(\w+):(\w*)$/);if(!l)return;let d=l[1],c=l[2].toLowerCase(),{varTypes:u,classes:h}=as(a),p=Zl(d,s,u,h);if(p)return p.filter(f=>!c||f.name.toLowerCase().startsWith(c)).map(f=>{let g=new Te.CompletionItem(f.name,Te.CompletionItemKind.Method);return g.detail=f.sig,g.documentation=new Te.MarkdownString(f.desc),g.sortText=`0${f.name}`,g})}},":"),o=Te.languages.registerCompletionItemProvider(os,{provideCompletionItems(a,s){let l=a.lineAt(s).text.substring(0,s.character).match(/\b(\w+)\.(\w*)$/);if(!l)return;let d=l[1];if(d==="luna")return;let c=l[2].toLowerCase(),{varTypes:u}=as(a),h=u.find(f=>f.varName===d&&f.line<s.line);if(!h)return;let p=Object.values(mo).find(f=>f.typeName===h.typeName);if(!(!p?.fields||p.fields.length===0))return p.fields.filter(f=>!c||f.name.toLowerCase().startsWith(c)).map(f=>{let g=new Te.CompletionItem(f.name,Te.CompletionItemKind.Field);return g.detail=f.type,g.documentation=new Te.MarkdownString(f.desc),g.sortText=`0${f.name}`,g})}},".");n.subscriptions.push(t,o)}var ie=E(require("vscode")),Kt=E(require("path"));function td(n){let e=[],t=n.getText(),o=/\brequire\s*\(\s*["']([^"']+)["']\s*\)/g,a;for(;(a=o.exec(t))!==null;){let s=a[1],i=a.index,r=a.index+a[0].length,l=n.positionAt(i),d=n.positionAt(r);e.push({moduleName:s,range:new ie.Range(l,d)})}return e}function nd(n,e){let t=n.replace(/\./g,"/"),o=[`${t}.lua`,`${t}/init.lua`];for(let a of o)return ie.Uri.joinPath(e,a)}function od(n){let a=new Map,s=new Map,i=[];for(let l of n.keys())a.set(l,0);function r(l,d){a.set(l,1);let c=n.get(l)||[];for(let u of c)if(a.has(u))if(a.get(u)===1){let h=d.indexOf(u);if(h>=0){let p=d.slice(h);p.push(u),i.push(p)}}else a.get(u)===0&&(s.set(u,l),r(u,[...d,u]));a.set(l,2)}for(let l of n.keys())a.get(l)===0&&r(l,[l]);return i}function is(n){let e=ie.languages.createDiagnosticCollection("luna.requireGraph");n.subscriptions.push(e);let t=new Map;async function o(){let s=ie.workspace.workspaceFolders?.[0]?.uri;if(!s)return;t.clear();let i=await ie.workspace.findFiles("**/*.lua","**/node_modules/**");for(let r of i)try{let l=await ie.workspace.openTextDocument(r),d=td(l);for(let c of d)c.resolvedUri=nd(c.moduleName,s);t.set(r.toString(),{uri:r,requires:d})}catch{}a(s)}function a(s){let i=new Map,r=new Map;for(let[u,h]of t){let p=Kt.relative(s.fsPath,h.uri.fsPath).replace(/\\/g,"/").replace(/\.lua$/,"").replace(/\/init$/,"");r.set(p,u),i.set(u,[])}for(let[u,h]of t){let p=[];for(let f of h.requires){let g=f.moduleName.replace(/\./g,"/"),m=r.get(g);m&&p.push(m)}i.set(u,p)}let l=od(i),d=new Set;for(let u of l)for(let h of u)d.add(h);e.clear();let c=new Map;for(let[u,h]of t){let p=[];for(let f of h.requires){if(f.resolvedUri){let v=f.moduleName.replace(/\./g,"/");if(!r.get(v)){let b=new ie.Diagnostic(f.range,`Cannot resolve module "${f.moduleName}" \u2014 file not found in workspace.`,ie.DiagnosticSeverity.Warning);b.code="luna.requireMissing",b.source="Luna Require Graph",p.push(b)}}let g=f.moduleName.replace(/\./g,"/"),m=r.get(g);if(m&&d.has(u)&&d.has(m)){for(let v of l)if(v.includes(u)&&v.includes(m)){let y=v.map(x=>{let k=t.get(x);return k?Kt.basename(k.uri.fsPath,".lua"):"?"}),b=new ie.Diagnostic(f.range,`Circular dependency detected: ${y.join(" \u2192 ")}`,ie.DiagnosticSeverity.Warning);b.code="luna.requireCycle",b.source="Luna Require Graph",p.push(b);break}}}p.length>0&&c.set(u,p)}for(let[u,h]of c){let p=t.get(u);p&&e.set(p.uri,h)}}o(),n.subscriptions.push(ie.workspace.onDidSaveTextDocument(s=>{s.languageId==="lua"&&o()}),ie.workspace.onDidCreateFiles(()=>o()),ie.workspace.onDidDeleteFiles(()=>o()))}var V=E(require("vscode")),sd=[{regex:/\bfunction\s+(\w+\.\w+)\s*\(/g,kind:V.SymbolKind.Function,group:1},{regex:/\bfunction\s+(\w+)\s*\(/g,kind:V.SymbolKind.Function,group:1},{regex:/\blocal\s+function\s+(\w+)\s*\(/g,kind:V.SymbolKind.Function,group:1},{regex:/\bfunction\s+(\w+:\w+)\s*\(/g,kind:V.SymbolKind.Method,group:1},{regex:/^(\w+)\s*=\s*\{\s*\}/gm,kind:V.SymbolKind.Class,group:1},{regex:/\blocal\s+(\w+)\s*=\s*\{\s*\}/g,kind:V.SymbolKind.Class,group:1},{regex:/^([A-Z][A-Z_0-9]+)\s*=/gm,kind:V.SymbolKind.Constant,group:1},{regex:/\b(luna\.\w+)\s*=\s*function/g,kind:V.SymbolKind.Function,group:1},{regex:/\bfunction\s+(luna\.\w+)\s*\(/g,kind:V.SymbolKind.Function,group:1}],fo=class{symbols=new Map;fileSymbols=new Map;building=!1;async buildIndex(){if(!this.building){this.building=!0;try{this.symbols.clear(),this.fileSymbols.clear();let e=await V.workspace.findFiles("**/*.lua","**/node_modules/**");for(let t of e)try{let o=await V.workspace.openTextDocument(t);this.indexDocument(o)}catch{}}finally{this.building=!1}}}async updateFile(e){try{let t=await V.workspace.openTextDocument(e);this.indexDocument(t)}catch{this.removeFile(e)}}removeFile(e){let t=e.toString(),o=this.fileSymbols.get(t)||[];for(let a of o){let s=this.symbols.get(a.name);if(s){let i=s.filter(r=>r.uri.toString()!==t);i.length>0?this.symbols.set(a.name,i):this.symbols.delete(a.name)}}this.fileSymbols.delete(t)}findDefinition(e){let t=this.symbols.get(e);if(!(!t||t.length===0))return t.find(o=>o.kind===V.SymbolKind.Function)||t.find(o=>o.kind===V.SymbolKind.Method)||t[0]}findReferences(e){return this.symbols.get(e)||[]}getWorkspaceSymbols(e){let t=e.toLowerCase(),o=[];for(let[a,s]of this.symbols)if(!t||a.toLowerCase().includes(t))for(let i of s)o.push(new V.SymbolInformation(i.name,i.kind,i.containerName||"",new V.Location(i.uri,i.range)));return o}getFileSymbols(e){return this.fileSymbols.get(e.toString())||[]}indexDocument(e){let t=e.uri.toString();this.removeFile(e.uri);let o=e.getText(),a=[];for(let s of sd){s.regex.lastIndex=0;let i;for(;(i=s.regex.exec(o))!==null;){let r=i[s.group],l=e.positionAt(i.index),d=e.positionAt(i.index+i[0].length),c;r.includes(":")?c=r.split(":")[0]:r.includes(".")&&!r.startsWith("luna.")&&(c=r.split(".")[0]);let u={name:r,kind:s.kind,uri:e.uri,range:new V.Range(l,d),containerName:c};a.push(u);let h=this.symbols.get(r)||[];h.push(u),this.symbols.set(r,h)}}this.fileSymbols.set(t,a)}};function rs(n){let e=new fo;e.buildIndex(),n.subscriptions.push(V.workspace.onDidSaveTextDocument(o=>{o.languageId==="lua"&&e.updateFile(o.uri)}),V.workspace.onDidDeleteFiles(o=>{for(let a of o.files)e.removeFile(a)}),V.workspace.onDidCreateFiles(o=>{for(let a of o.files)a.fsPath.endsWith(".lua")&&e.updateFile(a)}));let t=V.languages.registerWorkspaceSymbolProvider({provideWorkspaceSymbols(o){return e.getWorkspaceSymbols(o)}});return n.subscriptions.push(t),e}var Ue=E(require("vscode")),ls={scheme:"file",language:"lua"},rd=/\b(function|if|for|while|do|repeat)\b/,ld=/^\s*(end|else|elseif|until)\b/,dd=/^\s*\}/,ds=/\{\s*$/;function cs(n,e){let t={provideDocumentFormattingEdits(o,a){try{return cd(o,a)}catch{return[]}},provideDocumentRangeFormattingEdits(o,a,s){try{return us(o,a,s)}catch{return[]}}};n.subscriptions.push(Ue.languages.registerDocumentFormattingEditProvider(ls,t),Ue.languages.registerDocumentRangeFormattingEditProvider(ls,t))}function cd(n,e){let t=new Ue.Range(0,0,n.lineCount-1,n.lineAt(n.lineCount-1).text.length);return us(n,t,e)}function us(n,e,t){let a=n.getText().split(/\r?\n/),s=t.insertSpaces?" ".repeat(t.tabSize):"	",r=ud(a,s).join(`
`);if(r===a.join(`
`))return[];let l=new Ue.Range(0,0,n.lineCount-1,n.lineAt(n.lineCount-1).text.length);return[Ue.TextEdit.replace(l,r)]}function ud(n,e){let t=[],o=0,a=0,s={inBlockComment:!1,inLongString:!1,closingPattern:""};for(let i=0;i<n.length;i++){let r=n[i];if(s.inBlockComment||s.inLongString){t.push(r),r.includes(s.closingPattern)&&(s.inBlockComment=!1,s.inLongString=!1,s.closingPattern=""),a=0;continue}let l=r.replace(/\s+$/,"").replace(/^\s+/,"");if(l===""){a++,a<=2&&t.push("");continue}a=0;let d=gd(l);if(d){let p=d.closing;l.slice(l.indexOf(d.open)+d.open.length).includes(p)||(d.isComment?s.inBlockComment=!0:s.inLongString=!0,s.closingPattern=p);let g=pd(l);o=Math.max(0,o+g),t.push(go(e,o)+l);let m=md(l);o=Math.max(0,o+m);continue}if(l.startsWith("--")){t.push(go(e,o)+l);continue}let c=ho(l),u=ps(c);o=Math.max(0,o+u),t.push(go(e,o)+l);let h=ms(c);o=Math.max(0,o+h)}return t}function pd(n){let e=ho(n);return ps(e)}function ps(n){let e=0;return ld.test(n)&&e--,dd.test(n)&&e--,e}function md(n){let e=ho(n);return ms(e)}function ms(n){if(fd(n))return 0;let e=0;return rd.test(n)&&(/^\s*(else|elseif)\b/.test(n),e++),ds.test(n)&&e++,e}function fd(n){return!!(/\bfunction\b.*\bend\b/.test(n)||/\bif\b.*\bthen\b.*\bend\b/.test(n)||/\b(?:for|while)\b.*\bdo\b.*\bend\b/.test(n)||/\{.*\}/.test(n)&&!ds.test(n))}function ho(n){let e="",t=0;for(;t<n.length;){let o=n[t];if(o==="["){let a=hd(n,t);if(a>=0){let s="]"+"=".repeat(a)+"]",i=n.indexOf(s,t+2+a);if(i>=0){t=i+s.length;continue}}e+=o,t++;continue}if(o==='"'||o==="'"){for(t++;t<n.length;){if(n[t]==="\\"){t+=2;continue}if(n[t]===o){t++;break}t++}continue}e+=o,t++}return e}function gd(n){let e=n.match(/--\[(=*)\[/);if(e){let o=e[1].length;return{open:"--["+"=".repeat(o)+"[",closing:"]"+"=".repeat(o)+"]",isComment:!0}}let t=n.match(/(?<!--)\[(=*)\[/);if(t){let o=t[1].length;return{open:"["+"=".repeat(o)+"[",closing:"]"+"=".repeat(o)+"]",isComment:!1}}}function hd(n,e){if(n[e]!=="[")return-1;let t=0,o=e+1;for(;o<n.length&&n[o]==="=";)t++,o++;return o<n.length&&n[o]==="["?t:-1}function go(n,e){return n.repeat(Math.max(0,e))}var de=E(require("vscode"));var vd={scheme:"file",language:"lua"},yd=new Y;function ys(n,e){n.subscriptions.push(de.languages.registerFoldingRangeProvider(vd,{provideFoldingRanges(t){try{return bd(t)}catch{return[]}}}))}function bd(n){let e=n.getText(),t=yd.tokenize(e),o=[],a=[];xd(t,o),wd(n,o);let s=t.filter(r=>r.type!==7&&r.type!==4&&r.type!==2&&r.type!==8),i=[];for(let r of s){if(r.type===0)switch(r.value){case"function":case"if":case"for":case"while":case"do":a.push({keyword:r.value,line:r.line,kind:de.FoldingRangeKind.Region});break;case"repeat":a.push({keyword:"repeat",line:r.line,kind:de.FoldingRangeKind.Region});break;case"end":{let l=gs(a,["function","if","for","while","do"]);l&&r.line>l.line&&o.push(new de.FoldingRange(l.line,r.line,l.kind));break}case"until":{let l=gs(a,["repeat"]);l&&r.line>l.line&&o.push(new de.FoldingRange(l.line,r.line,l.kind));break}}if(r.type===6){if(r.value==="{")i.push(r.line);else if(r.value==="}"){let l=i.pop();l!==void 0&&r.line>l&&o.push(new de.FoldingRange(l,r.line,de.FoldingRangeKind.Region))}}}return o}function xd(n,e){for(let t of n){if(t.type===4&&t.value.startsWith("--[")){let o=hs(t.value);o>0&&e.push(new de.FoldingRange(t.line,t.line+o,de.FoldingRangeKind.Comment))}if(t.type===2&&t.value.startsWith("[")){let o=hs(t.value);o>0&&e.push(new de.FoldingRange(t.line,t.line+o,de.FoldingRangeKind.Region))}}}function wd(n,e){let t=[],o,a=-2;for(let s=0;s<n.lineCount;s++){let i=n.lineAt(s).text.trimStart();if(/^--\s*region\b/i.test(i))t.push(s);else if(/^--\s*endregion\b/i.test(i)){let r=t.pop();r!==void 0&&s>r&&e.push(new de.FoldingRange(r,s,de.FoldingRangeKind.Region))}/^---/.test(i)&&!i.startsWith("---[")&&(s===a+1||(fs(o,a,e),o=s),a=s)}fs(o,a,e)}function fs(n,e,t){n!==void 0&&e>n&&t.push(new de.FoldingRange(n,e,de.FoldingRangeKind.Comment))}function gs(n,e){for(let t=n.length-1;t>=0;t--)if(e.includes(n[t].keyword))return n.splice(t,1)[0]}function hs(n){let e=0;for(let t of n)t===`
`&&e++;return e}var mt=E(require("vscode"));var kd={scheme:"file",language:"lua"},Ke=new Y,xs=new Set(["and","break","do","else","elseif","end","false","for","function","goto","if","in","local","nil","not","or","repeat","return","then","true","until","while"]);function ws(n,e){n.subscriptions.push(mt.languages.registerRenameProvider(kd,{prepareRename(t,o){try{return Sd(t,o,e)}catch{return}},provideRenameEdits(t,o,a){try{return Ed(t,o,a,e)}catch{return}}}))}function Sd(n,e,t){let o=n.getText(),a=e.line,s=e.character;if(Ke.isInsideString(o,a,s)||Ke.isInsideComment(o,a,s))return;let i=ks(n,e);if(i&&!xs.has(i.text)&&!Ss(n,e,i.text,t))return{range:i.range,placeholder:i.text}}function Ed(n,e,t,o){let a=n.getText(),s=e.line,i=e.character;if(Ke.isInsideString(a,s,i)||Ke.isInsideComment(a,s,i))return;let r=ks(n,e);if(!r||xs.has(r.text)||Ss(n,e,r.text,o))return;let l=r.text,d=Ke.analyze(a),c=d.symbols.find(g=>g.name===l&&(g.kind==="local"||g.kind==="function"||g.kind==="parameter")),u=0,h=n.lineCount-1;if(c?.isLocal&&c.scope){let g=d.scopes.find(m=>m.name===c.scope);g&&(u=g.startLine,h=g.endLine)}else if(c?.kind==="parameter"&&c.scope){let g=d.scopes.find(m=>m.name===c.scope);g&&(u=g.startLine,h=g.endLine)}let p=Ke.tokenize(a),f=new mt.WorkspaceEdit;for(let g of p){if(g.type!==1||g.value!==l||g.line<u||g.line>h||Ke.isInsideString(a,g.line,g.column)||Ke.isInsideComment(a,g.line,g.column))continue;let m=n.lineAt(g.line).text,v=g.column>0?m[g.column-1]:"",y=g.column+g.length<m.length?m[g.column+g.length]:"";if(bs(v)||bs(y))continue;let b=new mt.Range(g.line,g.column,g.line,g.column+g.length);f.replace(n.uri,b,t)}return f}function ks(n,e){let t=n.getWordRangeAtPosition(e,/[a-zA-Z_]\w*/);if(t)return{text:n.getText(t),range:t}}function Ss(n,e,t,o){let a=n.lineAt(e.line).text,s=e.character,i=a.substring(0,s);return!!(/luna\.\w*\.?$/.test(i)&&o.getAllFunctions().find(l=>l.name===t)||t==="luna")}function bs(n){return/[a-zA-Z0-9_]/.test(n)}var st=E(require("vscode"));var Cd={scheme:"file",language:"lua"},Es=new Y,Is=["namespace","function","method","parameter","variable","property","keyword","string","number","comment","operator","type","enumMember","macro","decorator","event"],Ps=["declaration","definition","readonly","deprecated","modification","documentation","defaultLibrary"],vo=new st.SemanticTokensLegend(Is,Ps),Cs=new Set(["load","update","draw","keypressed","keyreleased","textinput","mousepressed","mousereleased","wheelmoved","gamepadpressed","gamepadreleased","gamepadaxis","joystickadded","joystickremoved","touchpressed","touchmoved","touchreleased","focus","visible","resize","quit"]),Ts=new Map;function Ls(n,e){n.subscriptions.push(st.languages.registerDocumentSemanticTokensProvider(Cd,{provideDocumentSemanticTokens(t){try{return Td(t,e)}catch{return new st.SemanticTokensBuilder(vo).build()}}},vo))}function Td(n,e){let t=n.uri.toString(),o=Ts.get(t);if(o&&o.version===n.version)return o.tokens;let a=n.getText(),s=Es.tokenize(a),i=Es.analyze(a),r=new st.SemanticTokensBuilder(vo),l=new Set(i.symbols.filter(m=>m.kind==="parameter").map(m=>m.name)),d=new Set(i.symbols.filter(m=>m.kind==="local").map(m=>m.name)),c=new Set(i.symbols.filter(m=>m.kind==="function"&&m.isLocal).map(m=>m.name)),u=new Map;for(let m of i.symbols)(m.kind==="local"||m.kind==="parameter")&&!u.has(m.name)&&u.set(m.name,m.line);let h=new Set(e.getAllFunctions().map(m=>m.name)),p=new Set(e.getAllFunctions().filter(m=>m.deprecated).map(m=>m.name)),f=new Set;for(let m of e.getModuleNames()){let v=e.getModule(m);if(v){for(let y of[...v.functions,...v.methods])for(let b of y.parameters)if(b.type.includes("|"))for(let x of b.type.split("|")){let k=x.trim().replace(/^["']|["']$/g,"");k&&!k.includes(" ")&&f.add(k)}}}for(let m=0;m<s.length;m++){let v=s[m],y=m>0?s[m-1]:void 0,b=Md(s,m),x=Dd(s,m);switch(v.type){case 0:te(r,v,"keyword",[]);break;case 4:Pd(r,v);break;case 2:Ld(r,v,f);break;case 3:te(r,v,"number",[]);break;case 5:te(r,v,"operator",[]);break;case 1:Id(r,v,b,x,s,m,l,d,c,u,h,p,e);break}}let g=r.build();return Ts.set(t,{version:n.version,tokens:g}),g}function Id(n,e,t,o,a,s,i,r,l,d,c,u,h){let p=e.value;if(p==="luna"){if(o?.value==="."){let f=Ad(a,s,2);if(f?.type===1&&Cs.has(f.value)){te(n,e,"namespace",[]);return}}te(n,e,"namespace",[]);return}if(t?.value==="."||t?.value===":"){let f=Fd(a,s);if(f.startsWith("luna.")){let m=f.slice(5).split(".");if(h.getModule(m[0])&&m.length===1&&o?.value!=="("){te(n,e,"namespace",[]);return}if(m.length===1&&Cs.has(p)){te(n,e,"event",[]);return}if(c.has(p)){let v=["defaultLibrary"];u.has(p)&&v.push("deprecated"),te(n,e,"function",v);return}}if(t?.value===":"){te(n,e,"method",[]);return}te(n,e,"property",[]);return}if(t?.type===0&&t.value==="function"){te(n,e,"function",["definition"]);return}if(o?.value==="("){if(l.has(p))te(n,e,"function",[]);else if(c.has(p)){let f=["defaultLibrary"];u.has(p)&&f.push("deprecated"),te(n,e,"function",f)}else te(n,e,"function",[]);return}if(i.has(p)){let f=d.get(p)===e.line;te(n,e,"parameter",f?["declaration"]:[]);return}if(r.has(p)){let f=d.get(p)===e.line;te(n,e,"variable",f?["declaration"]:[]);return}te(n,e,"variable",[])}function Pd(n,e){let t=e.value;if(/^---@\w+/.test(t)){te(n,e,"decorator",["documentation"]);return}te(n,e,"comment",[])}function Ld(n,e,t){let o=Rd(e.value);if(o&&t.has(o)){te(n,e,"enumMember",[]);return}te(n,e,"string",[])}function Rd(n){return n.startsWith('"')&&n.endsWith('"')||n.startsWith("'")&&n.endsWith("'")?n.slice(1,-1):""}function te(n,e,t,o){let s=e.value.split(`
`)[0].length;if(s===0)return;let i=Is.indexOf(t);if(i<0)return;let r=0;for(let l of o){let d=Ps.indexOf(l);d>=0&&(r|=1<<d)}n.push(e.line,e.column,s,i,r)}function Md(n,e){for(let t=e-1;t>=0;t--)if(n[t].type!==7)return n[t]}function Dd(n,e){for(let t=e+1;t<n.length;t++)if(n[t].type!==7)return n[t]}function Ad(n,e,t){let o=0;for(let a=e+1;a<n.length;a++)if(n[a].type!==7&&(o++,o>=t))return n[a]}function Fd(n,e){let t=n[e].value,o=e-1;for(;o>=0;){if(n[o].type===7){o--;continue}if(n[o].type===6&&(n[o].value==="."||n[o].value===":")){let a=n[o].value;for(o--;o>=0&&n[o].type===7;)o--;if(o>=0&&n[o].type===1){t=n[o].value+a+t,o--;continue}}break}return t}var ne=E(require("vscode")),Rs={scheme:"file",language:"lua"},yo=new Map;function Ms(n){let e=n.uri.toString(),t=yo.get(e);if(t&&t.version===n.version)return t;let o=new Map,a=new Map,s=n.getText().split(`
`),i=null,r="",l=[],d="";for(let u=0;u<s.length;u++){let p=s[u].trim(),f=p.match(/^---@class\s+(\w+)(?:\s*:\s*(\w+))?(?:\s+(.*))?$/);if(f){i={name:f[1],parent:f[2],fields:[],methods:[],definedLine:u,fileUri:n.uri.toString()},f[3]&&(r=f[3].trim()),o.set(i.name,i);continue}let g=p.match(/^---@field\s+(\w+)\s+(\S+)(?:\s+(.*))?$/);if(g&&i){i.fields.push({name:g[1],type:g[2],description:g[3]?.trim()??"",line:u});continue}let m=p.match(/^---@param\s+(\w+)\s+(\S+)(?:\s+(.*))?$/);if(m){l.push({name:m[1],type:m[2],desc:m[3]?.trim()??""});continue}let v=p.match(/^---@return\s+(\S+)(?:\s+(.*))?$/);if(v){d=v[1];continue}let y=p.match(/^---(?!@)(.*)$/);if(y){r=y[1].trim();continue}let b=p.match(/^(?:local\s+)?function\s+(\w+)[.:]([\w]+)\s*\(([^)]*)\)/);if(b){let ae=b[1],Pe=b[2],Fe=o.get(ae);if(Fe){let ct=l.length>0?l.map(ut=>`${ut.name}: ${ut.type}`).join(", "):b[3];Fe.methods.push({name:Pe,params:ct,returns:d,description:r,line:u})}l=[],d="",r="";continue}let k=(u>0?s[u-1].trim():"").match(/^---@type\s+(\w+)/);if(k){let ae=p.match(/^local\s+(\w+)\s*=/);ae&&a.set(ae[1],k[1])}let F=p.match(/^local\s+(\w+)\s*=\s*setmetatable\s*\(\s*\{[^}]*\}\s*,\s*(\w+)\s*\)/);F&&a.set(F[1],F[2]);let q=p.match(/^\s*return\s+setmetatable\s*\(\s*\{[^}]*\}\s*,\s*(\w+)\s*\)/);if(q){let ae=o.get(q[1]);ae&&(ae.methods.find(Pe=>Pe.name==="new")||ae.methods.push({name:"new",params:"",returns:q[1],description:`Create a new ${q[1]} instance`,line:u}))}p!==""&&!p.startsWith("---")&&(r="",l=[],d="")}let c={version:n.version,classes:o,instanceTypes:a};return yo.set(e,c),c}function Ds(n,e,t){if(t.classes.has(e))return t.classes.get(e);let o=t.instanceTypes.get(e);if(o)return t.classes.get(o);let s=n.getText().split(`
`),i=new RegExp(`\\blocal\\s+${e}\\s*=\\s*(\\w+)\\.new\\s*\\(`);for(let r=s.length-1;r>=0;r--){let l=i.exec(s[r]);if(l){let d=t.classes.get(l[1]);if(d)return d}}}function As(n,e){let t=ne.languages.registerHoverProvider(Rs,{provideHover(s,i){let r=Ms(s),l=s.getWordRangeAtPosition(i,/\w+[.:]\w+/);if(l){let p=s.getText(l),f=p.includes(":")?":":".",[g,m]=p.split(f),v=Ds(s,g,r);if(v){let y=v.fields.find(x=>x.name===m);if(y){let x=new ne.MarkdownString;return x.appendCodeblock(`${v.name}.${y.name}: ${y.type}`,"lua"),y.description&&x.appendMarkdown(`
${y.description}
`),x.appendMarkdown(`
*Defined in class \`${v.name}\`*`),x.isTrusted=!0,new ne.Hover(x,l)}let b=v.methods.find(x=>x.name===m);if(b){let x=new ne.MarkdownString;return x.appendCodeblock(`${v.name}:${b.name}(${b.params})${b.returns?` \u2192 ${b.returns}`:""}`,"lua"),b.description&&x.appendMarkdown(`
${b.description}
`),x.appendMarkdown(`
*Method of class \`${v.name}\`*`),x.isTrusted=!0,new ne.Hover(x,l)}}}let d=s.getWordRangeAtPosition(i,/\w+/);if(!d)return;let c=s.getText(d),u=r.classes.get(c);if(!u)return;let h=new ne.MarkdownString;if(h.appendCodeblock(`class ${u.name}${u.parent?` : ${u.parent}`:""}`,"lua"),u.fields.length>0){h.appendMarkdown(`
**Fields:**

`);for(let p of u.fields)h.appendMarkdown(`- \`${p.name}\`: *${p.type}*${p.description?` \u2014 ${p.description}`:""}
`)}if(u.methods.length>0){h.appendMarkdown(`
**Methods:**

`);for(let p of u.methods)h.appendMarkdown(`- \`${p.name}(${p.params})\`${p.returns?` \u2192 ${p.returns}`:""}${p.description?` \u2014 ${p.description}`:""}
`)}return h.isTrusted=!0,new ne.Hover(h,d)}}),o=ne.languages.registerCompletionItemProvider(Rs,{provideCompletionItems(s,i){let r=Ms(s),l=s.lineAt(i).text.slice(0,i.character),d=l.match(/(\w+)[.:]\s*$/);if(!d)return[];let c=d[1],u=Ds(s,c,r);if(!u)return[];let h=l.endsWith(":"),p=[];if(!h)for(let f of u.fields){let g=new ne.CompletionItem(f.name,ne.CompletionItemKind.Field);g.detail=`${f.type} \u2014 ${u.name}`,g.documentation=f.description,p.push(g)}for(let f of u.methods){let g=new ne.CompletionItem(f.name,ne.CompletionItemKind.Method);g.detail=`${u.name}:${f.name}(${f.params})${f.returns?` \u2192 ${f.returns}`:""}`,g.documentation=f.description,g.insertText=new ne.SnippetString(f.params?`${f.name}(\${1})`:`${f.name}()`),p.push(g)}return p}},".",":"),a=ne.workspace.onDidChangeTextDocument(s=>{s.document.languageId==="lua"&&yo.delete(s.document.uri.toString())});n.subscriptions.push(t,o,a)}var Q=E(require("vscode")),Se=E(require("path")),We=E(require("fs")),ft=class n extends Q.TreeItem{constructor(t,o,a,s,i){super(t,o);this.label=t;this.collapsibleState=o;this.resourceUri=a;this.assetType=s;this.sizeBytes=i;a&&(this.resourceUri=a,this.tooltip=a.fsPath),this.iconPath=s?new Q.ThemeIcon(n.iconFor(s)):void 0,i!==void 0&&(this.description=n.formatSize(i)),s&&s!=="folder"&&a&&(this.command={command:"vscode.open",title:"Open File",arguments:[a]})}static iconFor(t){switch(t){case"image":return"file-media";case"audio":return"unmute";case"font":return"text-size";case"shader":return"symbol-color";case"folder":return"folder";default:return"file"}}static formatSize(t){return t<1024?`${t} B`:t<1024*1024?`${(t/1024).toFixed(1)} KB`:`${(t/1024/1024).toFixed(1)} MB`}},Nd=new Set([".png",".jpg",".jpeg",".bmp",".gif",".tga",".tiff",".webp"]),zd=new Set([".wav",".ogg",".mp3",".flac",".aiff"]),_d=new Set([".ttf",".otf"]),Od=new Set([".glsl",".vert",".frag"]);function $d(n){if(Nd.has(n))return"image";if(zd.has(n))return"audio";if(_d.has(n))return"font";if(Od.has(n))return"shader"}var Jt=class{_onDidChangeTreeData=new Q.EventEmitter;onDidChangeTreeData=this._onDidChangeTreeData.event;categories=[];_missingAssets=[];constructor(){this.refresh()}refresh(){this.categories=[{label:"Images",type:"image",icon:"file-media",items:[]},{label:"Audio",type:"audio",icon:"unmute",items:[]},{label:"Fonts",type:"font",icon:"text-size",items:[]},{label:"Shaders",type:"shader",icon:"symbol-color",items:[]}],this._missingAssets=[],this._scanWorkspace(),this._onDidChangeTreeData.fire(void 0)}get missingAssets(){return this._missingAssets}_scanWorkspace(){let e=Q.workspace.workspaceFolders;if(!e?.length)return;let t=e[0].uri.fsPath;this._walk(t,t)}_walk(e,t){let o;try{o=We.readdirSync(e,{withFileTypes:!0})}catch{return}for(let a of o){let s=Se.join(e,a.name);if(!(a.name.startsWith(".")||a.name==="node_modules"||a.name==="target")){if(a.isDirectory())this._walk(s,t);else if(a.isFile()){let i=Se.extname(a.name).toLowerCase(),r=$d(i);if(!r)continue;let l=this.categories.find(c=>c.type===r);if(!l)continue;let d=0;try{d=We.statSync(s).size}catch{}l.items.push({name:Se.relative(t,s).replace(/\\/g,"/"),uri:Q.Uri.file(s),size:d})}}}}getTreeItem(e){return e}getChildren(e){if(!e)return this.categories.filter(o=>o.items.length>0).map(o=>{let a=new ft(`${o.label} (${o.items.length})`,Q.TreeItemCollapsibleState.Collapsed,void 0,"folder",void 0);return a.contextValue=`assetCategory.${o.type}`,a._catType=o.type,a});let t=e._catType;if(t){let o=this.categories.find(a=>a.type===t);return o?o.items.map(a=>new ft(Se.basename(a.name),Q.TreeItemCollapsibleState.None,a.uri,o.type,a.size)):[]}return[]}};async function Fs(){let n=Q.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!n){Q.window.showWarningMessage("No workspace folder open.");return}let e=await Q.workspace.findFiles("**/*.lua","**/node_modules/**"),t=/luna\.(?:graphics\.newImage|audio\.newSource)\s*\(\s*["']([^"']+)["']/g,o=[];for(let i of e){let r;try{r=We.readFileSync(i.fsPath,"utf8")}catch{continue}let l=r.split(`
`);for(let d=0;d<l.length;d++){t.lastIndex=0;let c;for(;(c=t.exec(l[d]))!==null;){let u=c[1];if(!u.includes("."))continue;let h=Se.resolve(Se.dirname(i.fsPath),u),p=Se.resolve(n,u);!We.existsSync(h)&&!We.existsSync(p)&&o.push({file:Q.workspace.asRelativePath(i),line:d+1,asset:u})}}}if(o.length===0){Q.window.showInformationMessage("No missing assets found.");return}let a=o.map(i=>`${i.file}:${i.line}  \u2192  ${i.asset}`).join(`
`),s=await Q.workspace.openTextDocument({content:`Missing assets:

${a}`,language:"plaintext"});Q.window.showTextDocument(s)}function Bs(n){let e=Q.window.activeTextEditor;if(!e||!n.resourceUri)return;let t=Q.workspace.workspaceFolders?.[0]?.uri.fsPath??"",o=n.resourceUri.fsPath;t&&o.startsWith(t)&&(o=o.substring(t.length+1)),o=o.replace(/\\/g,"/"),e.edit(a=>a.replace(e.selection,`"${o}"`))}wo();var X=E(require("vscode")),jd={scheme:"file",language:"lua"},Yd=new Set(["load","update","draw","keypressed","keyreleased","textinput","mousepressed","mousereleased","wheelmoved","resize","focus","visible","gamepadpressed","gamepadreleased","gamepadaxis","joystickadded","joystickremoved","touchpressed","touchmoved","touchreleased"]),ko=class{_onDidChange=new X.EventEmitter;onDidChangeCodeLenses=this._onDidChange.event;provideCodeLenses(e){let t=[],o=e.getText(),a=o.split(`
`),s=/^(?:local\s+function\s+(\w+)|function\s+([\w.:]+))/;function i(r){let l=r.replace(/[.]/g,"\\."),d=new RegExp(`\\b${l}\\b`,"g"),c=o.match(d)??[];return Math.max(0,c.length-1)}for(let r=0;r<a.length;r++){let l=a[r],d=s.exec(l.trimStart());if(!d)continue;let c=d[1]??d[2];if(!c)continue;let u=new X.Range(r,0,r,0),p=c.match(/^luna\.(\w+)$/)?.[1];if(p&&Yd.has(p))t.push(new X.CodeLens(u,{title:`\u26A1 luna.${p} callback`,command:"luna.browseApi",arguments:[`luna.${p}`],tooltip:`Open API documentation for luna.${p}`}));else{let f=i(c.split(".").pop()??c),g=f===1?"1 reference":`${f} references`;t.push(new X.CodeLens(u,{title:f===0?"\u26A0 unused":g,command:"luna.codelens.findRefs",arguments:[e.uri,new X.Position(r,l.indexOf(c)),c],tooltip:f===0?`"${c}" is never called`:`Find all references to "${c}"`}))}/^test_|_test\b/.test(c)&&t.push(new X.CodeLens(u,{title:"\u25B6 Run test",command:"luna.test.runSingleLua",arguments:[e.uri,c],tooltip:`Run Lua test "${c}"`}))}return t}refresh(){this._onDidChange.fire()}};function Vd(n){let e=X.window.createStatusBarItem(X.StatusBarAlignment.Right,95);e.name="Luna Variable Type",e.tooltip="Type of the Lua symbol under the cursor",e.command="luna.debug.openInspector",n.subscriptions.push(e);let t=[{pattern:/=\s*\d+(?:\.\d+)?(?!\w)/,type:"number"},{pattern:/=\s*["']/,type:"string"},{pattern:/=\s*(?:true|false)\b/,type:"boolean"},{pattern:/=\s*\{/,type:"table"},{pattern:/=\s*function\s*\(/,type:"function"},{pattern:/=\s*nil\b/,type:"nil"},{pattern:/luna\.graphics\.newImage\s*\(/,type:"Image"},{pattern:/luna\.graphics\.newCanvas\s*\(/,type:"Canvas"},{pattern:/luna\.graphics\.newFont\s*\(/,type:"Font"},{pattern:/luna\.graphics\.newShader\s*\(/,type:"Shader"},{pattern:/luna\.graphics\.newMesh\s*\(/,type:"Mesh"},{pattern:/luna\.graphics\.newSpriteBatch\s*\(/,type:"SpriteBatch"},{pattern:/luna\.graphics\.newParticleSystem\s*\(/,type:"ParticleSystem"},{pattern:/luna\.audio\.newSource\s*\(/,type:"Source"},{pattern:/luna\.physics\.newWorld\s*\(/,type:"World"},{pattern:/luna\.physics\.newBody\s*\(/,type:"Body"},{pattern:/luna\.physics\.newFixture\s*\(/,type:"Fixture"},{pattern:/luna\.physics\.newRectangleShape\s*\(/,type:"PolygonShape"},{pattern:/luna\.physics\.newCircleShape\s*\(/,type:"CircleShape"},{pattern:/luna\.math\.newTransform\s*\(/,type:"Transform"},{pattern:/luna\.cardgame\.newCard\s*\(/,type:"Card"},{pattern:/luna\.cardgame\.newDeck\s*\(/,type:"Deck"}];function o(a,s){let r=a.getText().split(`
`);for(let l=r.length-1;l>=0;l--){let d=r[l];if(new RegExp(`\\blocal\\s+${s}\\s*=|\\b${s}\\s*=(?!=)`,"g").test(d)){for(let{pattern:u,type:h}of t)if(u.test(d))return h;return"?"}}}n.subscriptions.push(X.window.onDidChangeTextEditorSelection(a=>{let s=a.textEditor;if(s.document.languageId!=="lua"){e.hide();return}let i=s.selection.active,r=s.document.getWordRangeAtPosition(i,/\w+/);if(!r){e.hide();return}let l=s.document.getText(r);if(/^(local|function|return|end|if|then|else|for|while|do|and|or|not|nil|true|false|repeat|until|break|goto|in)$/.test(l)){e.hide();return}let d=o(s.document,l);d?(e.text=`$(symbol-variable) ${l}: ${d}`,e.show()):e.hide()}))}function _s(n,e){let t=new ko;n.subscriptions.push(X.languages.registerCodeLensProvider(jd,t)),n.subscriptions.push(X.workspace.onDidChangeTextDocument(o=>{o.document.languageId==="lua"&&t.refresh()})),n.subscriptions.push(X.commands.registerCommand("luna.codelens.findRefs",async(o,a)=>{await X.commands.executeCommand("editor.action.referenceSearch.trigger",a)})),Vd(n),n.subscriptions.push(X.commands.registerCommand("luna.codeLens.toggle",()=>{let o=X.workspace.getConfiguration("luna"),a=o.get("codeLens.enabled",!0);o.update("codeLens.enabled",!a,X.ConfigurationTarget.Global),X.window.showInformationMessage(`Luna Code Lens ${a?"disabled":"enabled"}`)}))}var It=E(require("vscode")),He,qe=[],Gd=1,Zt=!1,Tt,So;function Os(n){So=n}function Eo(n){Zt=n,n||qe.forEach(e=>{e.value="\u2013",e.type="?",e.error=void 0}),it(),n?$s():Ws()}function $s(){Tt||(Tt=setInterval(()=>{Qt()},1500))}function Ws(){Tt&&(clearInterval(Tt),Tt=void 0)}async function Qt(){if(!(!So||!Zt||qe.length===0)){for(let n of qe){try{let e=await So(n.expression);e?(n.value=e.value,n.type=e.type,n.error=void 0):(n.value="nil",n.type="nil")}catch(e){n.value="\u2013",n.type="error",n.error=e instanceof Error?e.message:String(e)}n.lastUpdated=Date.now()}it()}}function Hs(n){if(He){He.reveal(It.ViewColumn.Two);return}He=It.window.createWebviewPanel("luna.debugWatchers","Luna2D Watchers",It.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0}),He.webview.html=Kd(),He.onDidDispose(()=>{He=void 0,Ws()},null,n.subscriptions),He.webview.onDidReceiveMessage(async e=>{switch(e.type){case"add":qs(e.expression),await Qt();break;case"remove":qe=qe.filter(t=>t.id!==e.id),it();break;case"edit":Ud(e.id,e.expression),await Qt();break;case"refresh":await Qt();break;case"clear":qe=[],it();break}},null,n.subscriptions),it(),Zt&&$s()}function qs(n){n.trim()&&(qe.push({id:Gd++,expression:n.trim(),value:"\u2013",type:"?",lastUpdated:0}),it())}function Ud(n,e){let t=qe.find(o=>o.id===n);t&&(t.expression=e.trim(),t.value="\u2013",t.type="?"),it()}function it(){He&&He.webview.postMessage({type:"update",watches:qe,connected:Zt})}function Kd(){return`<!DOCTYPE html>
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
</html>`}function js(n){let e=n.selection,t=n.document.getText(e.isEmpty?n.document.getWordRangeAtPosition(e.active,/[\w.:\[\]"']+/):e);t&&qs(t)}var Lt=E(require("vscode")),Xs=require("child_process"),Gs=require("util"),en=(0,Gs.promisify)(Xs.execFile),Ne,gt=[],Jd=120,Pt;async function Qd(){let n={timestamp:Date.now(),cpuPercent:0,ramUsedMb:0,ramTotalMb:0,lunaProcessCpu:0,lunaProcessRamMb:0};return process.platform==="win32"?await Zd(n):await ec(n),n}async function Zd(n){let e=`
$ErrorActionPreference = 'SilentlyContinue'
$mem = Get-CimInstance Win32_OperatingSystem | Select-Object FreePhysicalMemory, TotalVisibleMemorySize
$cpu = (Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$lunaProc = Get-Process -Name 'luna*','luna2d' -ErrorAction SilentlyContinue | Sort-Object CPU -Descending | Select-Object -First 1
$disk = Get-CimInstance Win32_PerfFormattedData_PerfDisk_LogicalDisk -Filter "Name='_Total'" | Select-Object DiskReadBytesPersec, DiskWriteBytesPersec
$net = Get-CimInstance Win32_PerfFormattedData_Tcpip_NetworkInterface | Measure-Object -Property BytesSentPersec,BytesReceivedPersec -Sum
[PSCustomObject]@{
  CPU = [int]$cpu
  MemFreeKB = [long]$mem.FreePhysicalMemory
  MemTotalKB = [long]$mem.TotalVisibleMemorySize
  LunaCPU = if($lunaProc){ [math]::Round($lunaProc.CPU,1) } else { 0 }
  LunaRAMMB = if($lunaProc){ [math]::Round($lunaProc.WorkingSet64 / 1MB, 1) } else { 0 }
  DiskReadBps = if($disk){ [long]$disk.DiskReadBytesPersec } else { 0 }
  DiskWriteBps = if($disk){ [long]$disk.DiskWriteBytesPersec } else { 0 }
  NetSentBps = [long]$net.Sum[0]
  NetRecvBps = [long]$net.Sum[1]
} | ConvertTo-Json -Compress`.trim();try{let{stdout:t}=await en("powershell",["-NoProfile","-NonInteractive","-Command",e],{timeout:4e3}),o=JSON.parse(t.trim());n.cpuPercent=o.CPU??0,n.ramTotalMb=Math.round((o.MemTotalKB??0)/1024);let a=Math.round((o.MemFreeKB??0)/1024);n.ramUsedMb=n.ramTotalMb-a,n.lunaProcessCpu=o.LunaCPU??0,n.lunaProcessRamMb=o.LunaRAMMB??0;let s=o.DiskReadBps??0,i=o.DiskWriteBps??0;n.diskReadKbs=Math.round(s/1024),n.diskWriteKbs=Math.round(i/1024);let r=o.NetSentBps??0,l=o.NetRecvBps??0;n.netSentKbs=Math.round(r/1024),n.netRecvKbs=Math.round(l/1024)}catch{}try{let{stdout:t}=await en("nvidia-smi",["--query-gpu=utilization.gpu,memory.used","--format=csv,noheader,nounits"],{timeout:2e3}),o=t.trim().split(",");n.gpuPercent=parseInt(o[0]??"0",10),n.gpuVramMb=parseInt(o[1]?.trim()??"0",10)}catch{}}async function ec(n){try{let{stdout:e}=await en("sh",["-c",`top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1; free -m | grep Mem | awk '{print $3" "$2}'`],{timeout:3e3}),t=e.trim().split(`
`);n.cpuPercent=parseFloat(t[0]??"0");let o=(t[1]??"").split(" ");n.ramUsedMb=parseInt(o[0]??"0",10),n.ramTotalMb=parseInt(o[1]??"0",10)}catch{}try{let{stdout:e}=await en("sh",["-c","ps -C luna2d -o %cpu=,rss= 2>/dev/null || ps aux | grep '[l]una' | awk '{print $3, $6}' | head -1"],{timeout:2e3}),t=e.trim().split(/\s+/);n.lunaProcessCpu=parseFloat(t[0]??"0"),n.lunaProcessRamMb=Math.round(parseInt(t[1]??"0",10)/1024)}catch{}}function Ys(){Pt||(Pt=setInterval(async()=>{let n=await Qd();gt.push(n),gt.length>Jd&&gt.shift(),Ne?.visible&&Ne.webview.postMessage({type:"data",samples:gt})},2e3))}function Vs(){Pt&&(clearInterval(Pt),Pt=void 0)}function Us(n){if(Ne){Ne.reveal(Lt.ViewColumn.Two);return}Ne=Lt.window.createWebviewPanel("luna.systemMonitor","Luna2D System Monitor",Lt.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0}),Ne.webview.html=tc(),Ne.onDidDispose(()=>{Ne=void 0,Vs()},null,n.subscriptions),Ne.webview.onDidReceiveMessage(e=>{e.type==="start"&&Ys(),e.type==="stop"&&Vs()},null,n.subscriptions),Ys(),gt.length&&Ne.webview.postMessage({type:"data",samples:gt})}function tc(){return`<!DOCTYPE html>
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
  .luna-card { grid-column: 1 / -1; }
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
  <span id="lunaStatus" class="badge idle">luna2d: not running</span>
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

  <!-- Luna2D process -->
  <div class="card luna-card">
    <div class="card-title">Luna2D Process</div>
    <div class="row">
      <div class="stat"><div class="big" id="lunaCpu">\u2013</div><div class="sub">CPU %</div></div>
      <div class="stat"><div class="big" id="lunaRam">\u2013</div><div class="sub">RAM MB</div></div>
    </div>
    <canvas id="lunaChart"></canvas>
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
  luna:  '#f48771',
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
  const hasLuna = last.lunaProcessCpu > 0 || last.lunaProcessRamMb > 0;
  const hasGpu = last.gpuPercent !== undefined && last.gpuPercent !== null;

  // Poll status
  document.getElementById('pollDot').className = 'dot active';
  document.getElementById('pollStatus').textContent = 'Polling every 2s  \xB7  ' + _samples.length + ' samples';
  document.getElementById('lunaStatus').textContent = hasLuna ? 'luna2d: running' : 'luna2d: not detected';
  document.getElementById('lunaStatus').className = 'badge ' + (hasLuna ? 'run' : 'idle');

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

  // Luna
  document.getElementById('lunaCpu').textContent = last.lunaProcessCpu;
  document.getElementById('lunaRam').textContent = last.lunaProcessRamMb;
  document.getElementById('lunaCpu').style.color = last.lunaProcessCpu > 50 ? '#f44747' : 'inherit';
  drawLine('lunaChart', _samples.map(s => s.lunaProcessCpu), COLOR.luna, 100);
}

window.addEventListener('resize', updateUI);
window.addEventListener('message', (e) => {
  if (e.data.type === 'data') { _samples = e.data.samples; updateUI(); }
});
</script>
</body>
</html>`}var re=E(require("vscode")),Ks=E(require("fs")),Js=E(require("path"));async function nc(){let n=await re.workspace.findFiles("**/*.lua","**/node_modules/**"),e=new Map;for(let t of n){let o;try{o=Ks.readFileSync(t.fsPath,"utf8")}catch{continue}let a=re.workspace.asRelativePath(t),s=o.split(`
`);for(let i=0;i<s.length;i++){let r=s[i];if(r.trimStart().startsWith("--"))continue;let l=/luna\.(\w+)\.(\w+)\s*\(/g,d;for(;(d=l.exec(r))!==null;){let c=`luna.${d[1]}.${d[2]}`;e.has(c)||e.set(c,{func:c,count:0,files:new Set,lines:[]});let u=e.get(c);u.count++,u.files.add(a),u.lines.length<5&&u.lines.push({file:a,line:i+1,text:r.trim()})}}}return Array.from(e.values()).sort((t,o)=>o.count-t.count)}var je;async function Qs(n){if(je){je.reveal(re.ViewColumn.Two),await Co();return}je=re.window.createWebviewPanel("luna.apiUsage","Luna2D API Usage",re.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0}),je.onDidDispose(()=>{je=void 0},null,n.subscriptions),je.webview.onDidReceiveMessage(async e=>{if(e.type==="refresh"&&await Co(),e.type==="open"){let t=re.Uri.file(Js.join(re.workspace.workspaceFolders?.[0]?.uri.fsPath??"",e.file));await re.window.showTextDocument(t,{selection:new re.Range(e.line-1,0,e.line-1,0)})}},null,n.subscriptions),await Co()}async function Co(){if(!je)return;je.webview.postMessage({type:"loading"});let n=await nc();je.webview.html=oc(n)}function oc(n){let e=n.reduce((l,d)=>l+d.count,0),t=n.length,o=n.slice(0,10),a=new Map;for(let l of n){let d=l.func.split(".")[1]??"?";a.has(d)||a.set(d,[]),a.get(d).push(l)}let s=Array.from(a.entries()).sort((l,d)=>d[1].reduce((c,u)=>c+u.count,0)-l[1].reduce((c,u)=>c+u.count,0)).map(([l,d])=>{let c=d.reduce((u,h)=>u+h.count,0);return`<tr><td><code>luna.${Rt(l)}</code></td><td>${d.length}</td><td>${c}</td></tr>`}).join(""),i=o.map(l=>{let d=l.lines.map(c=>`<a href="#" data-file="${Rt(c.file)}" data-line="${c.line}" class="loc">${Rt(c.file)}:${c.line}</a>`).join(", ");return`<tr>
      <td><code>${Rt(l.func)}</code></td>
      <td>${l.count}</td>
      <td>${l.files.size}</td>
      <td style="font-size:11px;opacity:.7">${d}</td>
    </tr>`}).join(""),r=n.filter(l=>l.count===0).map(l=>`<tr><td><code>${Rt(l.func)}</code></td></tr>`).join("");return`<!DOCTYPE html>
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
<h2>\u{1F4CA} Luna2D API Usage Report</h2>
<button onclick="vscode.postMessage({type:'refresh'})">\u27F3 Re-scan</button>

<div class="stats">
  <div class="stat"><div class="stat-val">${e}</div><div class="stat-lbl">Total Calls</div></div>
  <div class="stat"><div class="stat-val">${t}</div><div class="stat-lbl">Unique Functions</div></div>
  <div class="stat"><div class="stat-val">${a.size}</div><div class="stat-lbl">Modules Used</div></div>
</div>

<h3>By Module</h3>
<table>
  <thead><tr><th>Module</th><th>Functions</th><th>Total Calls</th></tr></thead>
  <tbody>${s}</tbody>
</table>

<h3>Top 10 Most Called</h3>
<table>
  <thead><tr><th>Function</th><th>Calls</th><th>Files</th><th>Locations</th></tr></thead>
  <tbody>${i}</tbody>
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
</html>`}function Rt(n){return n.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;")}async function Zs(n){let e=re.window.activeTextEditor;if(!e){re.window.showWarningMessage("Open a Lua file first.");return}let t=n.getAllFunctions(),o=t.filter(r=>r.fullPath.startsWith("luna.")).map(r=>({label:r.fullPath,description:r.description??"",detail:r.parameters?.map(l=>`${l.name}: ${l.type}`).join(", ")})),a=await re.window.showQuickPick(o,{placeHolder:"Search luna.* function to insert\u2026",matchOnDescription:!0,matchOnDetail:!0});if(!a)return;let s=t.find(r=>r.fullPath===a.label);if(!s)return;let i=s.fullPath+"(";if(s.parameters?.length){let r=s.parameters.filter(l=>!l.optional).map((l,d)=>`\${${d+1}:${l.name}}`).join(", ");i+=r}i+=")$0",e.insertSnippet(new re.SnippetString(i))}var pe=E(require("vscode")),Mt=E(require("path")),tn=E(require("fs"));async function To(n){let e=Io();if(!e){pe.window.showErrorMessage("No workspace folder open.");return}let t=pe.workspace.getConfiguration("luna").get("srcDir",""),o=t?Mt.join(e,t):e;try{await n.run(o)}catch(a){let s=a instanceof Error?a.message:String(a);pe.window.showErrorMessage(`Failed to run Luna2D: ${s}`)}}function ei(n){if(!n.isRunning()){pe.window.showInformationMessage("No Luna2D game is running.");return}n.stop(),pe.window.showInformationMessage("Luna2D game stopped.")}async function ti(n){let e=await pe.window.showInputBox({prompt:"Enter arguments for Luna2D",placeHolder:"e.g. --debug --fps-cap 60"});if(e===void 0)return;let t=Io();if(!t){pe.window.showErrorMessage("No workspace folder open.");return}let o=pe.workspace.getConfiguration("luna").get("srcDir",""),a=o?Mt.join(t,o):t;try{await n.run(a,e.split(/\s+/).filter(Boolean))}catch(s){let i=s instanceof Error?s.message:String(s);pe.window.showErrorMessage(`Failed to run Luna2D: ${i}`)}}async function nn(n){let e=Io();if(!e){pe.window.showErrorMessage("No workspace folder open.");return}let t=Mt.join(e,"examples");if(!tn.existsSync(t)){pe.window.showWarningMessage("No examples/ directory found.");return}let o=tn.readdirSync(t,{withFileTypes:!0}).filter(s=>s.isDirectory()).map(s=>s.name);if(o.length===0){pe.window.showWarningMessage("No examples found.");return}let a=await pe.window.showQuickPick(o,{placeHolder:"Select an example to run"});if(a)try{await n.run(Mt.join(t,a))}catch(s){let i=s instanceof Error?s.message:String(s);pe.window.showErrorMessage(`Failed to run example: ${i}`)}}function Io(){return pe.workspace.workspaceFolders?.[0]?.uri.fsPath}var ve=E(require("vscode")),Po=E(require("path")),ht=E(require("fs")),ni=[{label:"Minimal",description:"Empty main.lua with gameloop stubs",files:{"main.lua":["function luna.load()","end","","function luna.update(dt)","end","","function luna.draw()","end",""].join(`
`),"conf.lua":["function luna.conf(t)",'  t.window.title = "My Game"',"  t.window.width = 800","  t.window.height = 600","end"].join(`
`)}},{label:"Game Loop",description:"Full game loop with player movement",files:{"main.lua":["local x, y = 400, 300","local speed = 200","","function luna.load()",'  luna.window.setTitle("Game Loop Demo")',"end","","function luna.update(dt)",'  if luna.keyboard.isDown("left") then x = x - speed * dt end','  if luna.keyboard.isDown("right") then x = x + speed * dt end','  if luna.keyboard.isDown("up") then y = y - speed * dt end','  if luna.keyboard.isDown("down") then y = y + speed * dt end',"end","","function luna.draw()","  luna.graphics.clear(0.1, 0.1, 0.2)","  luna.graphics.setColor(1, 1, 1)",'  luna.graphics.circle("fill", x, y, 20)',"end",""].join(`
`),"conf.lua":["function luna.conf(t)",'  t.window.title = "Game Loop Demo"',"  t.window.width = 800","  t.window.height = 600","end"].join(`
`)}},{label:"Physics",description:"Physics world with falling objects",files:{"main.lua":["local world","local ground, ball","","function luna.load()","  world = luna.physics.newWorld(0, 981)",'  ground = luna.physics.newBody(world, 400, 580, "static")',"  luna.physics.newRectangleShape(ground, 800, 40)",'  ball = luna.physics.newBody(world, 400, 100, "dynamic")',"  luna.physics.newCircleShape(ball, 20)","end","","function luna.update(dt)","  world:update(dt)","end","","function luna.draw()","  luna.graphics.clear(0.1, 0.1, 0.2)","  luna.graphics.setColor(0.3, 0.3, 0.3)",'  luna.graphics.rectangle("fill", 0, 560, 800, 40)',"  luna.graphics.setColor(1, 0.3, 0.3)","  local bx, by = ball:getPosition()",'  luna.graphics.circle("fill", bx, by, 20)',"end",""].join(`
`),"conf.lua":["function luna.conf(t)",'  t.window.title = "Physics Demo"',"  t.window.width = 800","  t.window.height = 600","end"].join(`
`)}},{label:"Platformer",description:"Simple platformer with gravity and jumping",files:{"main.lua":["local player = { x = 100, y = 400, vy = 0, w = 32, h = 48, onGround = false }","local gravity = 900","local jumpForce = -400","local moveSpeed = 200","local groundY = 500","","function luna.update(dt)","  -- Horizontal movement",'  if luna.keyboard.isDown("left") then player.x = player.x - moveSpeed * dt end','  if luna.keyboard.isDown("right") then player.x = player.x + moveSpeed * dt end',"","  -- Gravity","  player.vy = player.vy + gravity * dt","  player.y = player.y + player.vy * dt","","  -- Ground collision","  if player.y + player.h >= groundY then","    player.y = groundY - player.h","    player.vy = 0","    player.onGround = true","  else","    player.onGround = false","  end","end","","function luna.keypressed(key)",'  if key == "space" and player.onGround then',"    player.vy = jumpForce","  end","end","","function luna.draw()","  luna.graphics.clear(0.2, 0.3, 0.4)","  luna.graphics.setColor(0.4, 0.4, 0.4)",'  luna.graphics.rectangle("fill", 0, groundY, 800, 100)',"  luna.graphics.setColor(0.2, 0.8, 0.4)",'  luna.graphics.rectangle("fill", player.x, player.y, player.w, player.h)',"end",""].join(`
`),"conf.lua":["function luna.conf(t)",'  t.window.title = "Platformer"',"  t.window.width = 800","  t.window.height = 600","end"].join(`
`)}},{label:"Top-Down",description:"Top-down view with WASD movement",files:{"main.lua":["local player = { x = 400, y = 300, speed = 200, size = 16 }","","function luna.update(dt)",'  if luna.keyboard.isDown("w") then player.y = player.y - player.speed * dt end','  if luna.keyboard.isDown("s") then player.y = player.y + player.speed * dt end','  if luna.keyboard.isDown("a") then player.x = player.x - player.speed * dt end','  if luna.keyboard.isDown("d") then player.x = player.x + player.speed * dt end',"end","","function luna.draw()","  luna.graphics.clear(0.15, 0.15, 0.2)","  luna.graphics.setColor(0.3, 0.7, 1)",'  luna.graphics.rectangle("fill", player.x - player.size/2, player.y - player.size/2, player.size, player.size)',"end",""].join(`
`),"conf.lua":["function luna.conf(t)",'  t.window.title = "Top-Down"',"  t.window.width = 800","  t.window.height = 600","end"].join(`
`)}},{label:"ECS",description:"Entity Component System with luna.entity",files:{"main.lua":["local universe","","function luna.load()","  universe = luna.entity.newUniverse()","","  for i = 1, 10 do","    local e = universe:spawn()",'    e:set("position", { x = math.random(50, 750), y = math.random(50, 550) })','    e:set("velocity", { x = math.random(-100, 100), y = math.random(-100, 100) })','    e:set("radius", math.random(5, 20))',"  end","end","","function luna.update(dt)",'  for _, e in universe:query("position", "velocity") do','    local pos = e:get("position")','    local vel = e:get("velocity")',"    pos.x = pos.x + vel.x * dt","    pos.y = pos.y + vel.y * dt","    if pos.x < 0 or pos.x > 800 then vel.x = -vel.x end","    if pos.y < 0 or pos.y > 600 then vel.y = -vel.y end","  end","end","","function luna.draw()","  luna.graphics.clear(0.1, 0.1, 0.15)",'  for _, e in universe:query("position", "radius") do','    local pos = e:get("position")','    local r = e:get("radius")',"    luna.graphics.setColor(0.4, 0.8, 1)",'    luna.graphics.circle("fill", pos.x, pos.y, r)',"  end","end",""].join(`
`),"conf.lua":["function luna.conf(t)",'  t.window.title = "ECS Demo"',"  t.window.width = 800","  t.window.height = 600","end"].join(`
`)}}],oi={"main.lua":`function luna.load()
end

function luna.update(dt)
end

function luna.draw()
end
`,"conf.lua":`function luna.conf(t)
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
`};async function ai(){let n=ni.map(i=>({label:i.label,description:i.description})),e=await ve.window.showQuickPick(n,{placeHolder:"Select a project template"});if(!e)return;let t=await ve.window.showOpenDialog({canSelectFolders:!0,canSelectFiles:!1,canSelectMany:!1,openLabel:"Select Project Folder"});if(!t||t.length===0)return;let o=t[0].fsPath,a=ni.find(i=>i.label===e.label);if(!a)return;for(let[i,r]of Object.entries(a.files)){let l=Po.join(o,i);ht.existsSync(l)||ht.writeFileSync(l,r,"utf-8")}let s=ve.Uri.file(o);await ve.commands.executeCommand("vscode.openFolder",s)}async function si(){let n=Object.keys(oi),e=await ve.window.showQuickPick(n,{placeHolder:"Select a file template"});if(!e)return;let t=ve.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!t){ve.window.showErrorMessage("No workspace folder open.");return}let o=await ve.window.showInputBox({prompt:"Enter file name",value:e});if(!o)return;let a=Po.join(t,o);if(ht.existsSync(a)){ve.window.showWarningMessage(`File already exists: ${o}`);return}ht.writeFileSync(a,oi[e],"utf-8");let s=await ve.workspace.openTextDocument(a);await ve.window.showTextDocument(s)}var on=E(require("vscode"));function ii(){let n=an("Luna Tests");n.show(),n.sendText("cargo test")}function ri(n){let e=an("Luna Tests");e.show(),e.sendText(`cargo test ${n}_tests`)}function li(){let n=an("Luna Tests");n.show(),n.sendText("cargo test --test lua_tests")}function di(){let n=an("Luna Tests");n.show(),n.sendText("cargo test --test golden_tests")}function an(n){let e=on.window.terminals.find(t=>t.name===n);return e||on.window.createTerminal(n)}var Lo=E(require("vscode"));function ci(){let n=Ro("Luna Package");n.show(),process.platform==="win32"?n.sendText("powershell -ExecutionPolicy Bypass -File tools/dist.ps1"):n.sendText("bash tools/dist.sh")}function ui(){let n=Ro("Luna Package");n.show(),n.sendText("powershell -ExecutionPolicy Bypass -File tools/dist.ps1")}function pi(){let n=Ro("Luna Package");n.show(),n.sendText("bash tools/dist.sh")}function Ro(n){let e=Lo.window.terminals.find(t=>t.name===n);return e||Lo.window.createTerminal(n)}var mi=E(require("vscode"));var ze=E(require("vscode"));function L(){let n="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",e="";for(let t=0;t<32;t++)e+=n.charAt(Math.floor(Math.random()*n.length));return e}function ac(){return`
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
  `}function R(n,e,t,o,a){return`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta http-equiv="Content-Security-Policy"
    content="default-src 'none'; style-src 'nonce-${n}'; script-src 'nonce-${n}'; img-src data:;">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${e}</title>
  <style nonce="${n}">${ac()}${t}</style>
</head>
<body>
${o}
<script nonce="${n}">
const vscode = acquireVsCodeApi();
${a}
</script>
</body>
</html>`}var P=class{constructor(e,t,o,a={}){this.context=e;this.data=a;this.panel=ze.window.createWebviewPanel(t,o,ze.ViewColumn.One,{enableScripts:!0,retainContextWhenHidden:!0}),this.panel.webview.onDidReceiveMessage(s=>this.handleMessage(s),void 0,this.disposables),this.panel.onDidDispose(()=>this.dispose(),void 0,this.disposables),this.panel.webview.html=this.getHtml()}panel;isDirty=!1;disposables=[];async exportFile(e,t,o,a){let s=await ze.window.showSaveDialog({defaultUri:ze.Uri.file(t),filters:{[o]:[a]}});s&&(await ze.workspace.fs.writeFile(s,Buffer.from(e,"utf-8")),ze.window.showInformationMessage(`Exported to ${s.fsPath}`))}async exportLua(e,t){return this.exportFile(e,t,"Lua","lua")}async exportToml(e,t){return this.exportFile(e,t,"TOML","toml")}dispose(){for(let e of this.disposables)e.dispose()}};var sn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.editor.tileMap","Tile Map Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"tilemap.lua");break;case"exportToml":this.exportToml(e.content,"tilemap.toml");break}}getHtml(){let e=L();return R(e,"Tile Map Editor",`
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
    `)}};var rn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.editor.sceneFlow","Scene Flow Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"scenes.lua");break}}getHtml(){let e=L();return R(e,"Scene Flow Editor",`
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
    `)}};var ln=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.editor.entity","Entity Designer")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"entities.lua");break}}getHtml(){let e=L();return R(e,"Entity Designer",`
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
          lua += '  local e = luna.entity.spawn()\\n';
          for (const [comp, data] of Object.entries(ent.components)) {
            lua += '  luna.entity.addComponent(e, "' + comp.toLowerCase() + '", {\\n';
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
    `)}};var dn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.editor.pixelArt","Pixel Art Editor")}handleMessage(e){switch(e.type){case"exportPng":this.exportFile(e.content,"sprite.png","PNG Image","png");break}}getHtml(){let e=L();return R(e,"Pixel Art Editor",`
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
    `)}};var cn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.editor.particle","Particle Designer")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"particles.lua");break}}getHtml(){let e=L();return R(e,"Particle Designer",`
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
    `)}};var un=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.editor.dialog","Dialog Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"dialog.lua");break}}getHtml(){let e=L();return R(e,"Dialog Editor",`
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
    `)}};var mn=E(require("vscode"));var pn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.editor.database","Database Browser")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"data.lua");break;case"exportToml":this.exportToml(e.content,"data.toml");break;case"importCsv":this.importCsv();break}}async importCsv(){let e=await mn.window.showOpenDialog({filters:{"CSV Files":["csv"],"TOML Files":["toml"]}});if(e&&e[0]){let t=await mn.workspace.fs.readFile(e[0]),o=new globalThis.TextDecoder().decode(t);this.panel.webview.postMessage({type:"csvData",content:o,name:e[0].fsPath})}}getHtml(){let e=L();return R(e,"Database Browser",`
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
    `)}};var fn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.editor.procMap","Procedural Map Generator")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"mapgen.lua");break}}getHtml(){let e=L();return R(e,"Procedural Map Generator",`
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
    `)}};var gn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.editor.questTree","Quest / Tech Tree Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"quests.lua");break}}getHtml(){let e=L();return R(e,"Quest / Tech Tree Editor",`
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
    `)}};var hn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.editor.guiWidget","GUI Widget Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"gui_layout.lua");break}}getHtml(){let e=L();return R(e,"GUI Widget Editor",`
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
    `)}};var vn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.editor.aiBehavior","AI Behavior Tree")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"behavior_tree.lua");break}}getHtml(){let e=L();return R(e,"AI Behavior Tree",`
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
    `)}};var yn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.editor.graph","Graph / Node Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"graph.lua");break}}getHtml(){let e=L();return R(e,"Graph / Node Editor",`
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
    `)}};var bn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.editor.tilemapScript","Tilemap Script Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"tilemap_script.lua");break}}getHtml(){let e=L();return R(e,"Tilemap Script Editor",`
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
    `)}};var xn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.editor.voxel","Voxel Editor")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"voxel_model.lua");break}}getHtml(){let e=L();return R(e,"Voxel Editor",`
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
    `)}};var vt=E(require("vscode")),Mo=E(require("path")),yt=E(require("fs"));var sc=["ai","audio","cardgame","combat","compute","config","crafting","data","dataframe","dialog","engine","entity","event","filesystem","graph","graphics","graphics_ext","image","input","inventory","math","math_ext","minimap","modding","particle","pathfinding","physics","postfx","quest","resource","savegame","scene","sound","stats","thread","tilemap","timer"],wn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.editor.testRunner","Test Runner"),setTimeout(()=>this.pushDiscoveredSuites(),300)}handleMessage(e){switch(e.type){case"discoverSuites":this.pushDiscoveredSuites();break;case"runAll":this.runCargoTest("","all");break;case"runSuite":this.runCargoTest(e.suite,e.suite);break;case"runLua":this.runCargoTest("--test lua_tests","lua");break;case"runGolden":this.runCargoTest("--test golden_tests","golden");break;case"stop":vt.window.showInformationMessage("Use the terminal to cancel the running test.");break}}pushDiscoveredSuites(){let e=this.discoverTestSuites();this.panel.webview.postMessage({type:"suites",suites:e})}discoverTestSuites(){let e=vt.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!e)return this.fallbackSuites();let t=Mo.join(e,"tests");if(!yt.existsSync(t))return this.fallbackSuites();let o=[],a=new Set(["golden_tests","lua_tests"]),s;try{s=yt.readdirSync(t)}catch{return this.fallbackSuites()}for(let i of s.sort()){if(!i.endsWith("_tests.rs"))continue;let r=i.replace(/\.rs$/,"");if(a.has(r))continue;let l=this.extractTestNames(Mo.join(t,i));o.push({name:r,tests:l})}return o.push({name:"lua_tests",tests:["(lua vm tests \u2014 run via cargo test --test lua_tests)"]}),o.push({name:"golden_tests",tests:["(golden output tests \u2014 run via cargo test --test golden_tests)"]}),o}extractTestNames(e){try{let t=yt.readFileSync(e,"utf8"),o=[],a=/^\s*(?:#\[test\]\s*(?:#\[.*?\]\s*)*)?(?:async\s+)?fn\s+(\w+)/gm,s,i=t.split(`
`);for(let r=0;r<i.length;r++)if(i[r].trimStart().startsWith("#[test]"))for(let l=r+1;l<Math.min(r+5,i.length);l++){let d=i[l].match(/\bfn\s+(\w+)/);if(d){o.push(d[1]);break}}return o.length?o:["(no #[test] functions found)"]}catch{return["(could not read file)"]}}fallbackSuites(){return sc.map(e=>({name:`${e}_tests`,tests:[`(run: cargo test --test ${e}_tests)`]}))}runCargoTest(e,t){let a=vt.window.terminals.find(i=>i.name==="Luna Tests")??vt.window.createTerminal("Luna Tests");a.show();let s=e?`cargo test ${e}`:"cargo test";a.sendText(s),this.panel.webview.postMessage({type:"testStarted",filter:t})}getHtml(){let e=L();return R(e,"Test Runner",`
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
        <div class="output-panel" id="output">Tests run in the "Luna Tests" terminal.

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
          document.getElementById('output').textContent = '$ cargo test ' + data.filter + '\\n\\nSee "Luna Tests" terminal for live output.';
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
    `)}};var Dt=E(require("vscode"));var kn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.editor.apiReference","API Reference"),this.loadApiData()}async loadApiData(){try{let e=Dt.workspace.workspaceFolders;if(!e)return;let t=e[0].uri,o=Dt.Uri.joinPath(t,"docs","lua_api_reference_generated.md"),a=await Dt.workspace.fs.readFile(o),s=new globalThis.TextDecoder().decode(a);this.panel.webview.postMessage({type:"apiData",content:s})}catch{}}handleMessage(e){}getHtml(){let e=L();return R(e,"API Reference",`
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
          <div class="module-header">Luna2D API Reference</div>
          <div class="module-desc">Select a module from the left panel to browse its API functions.</div>
        </div>
      </div>
    `,`
      const API_DATA = {
        'luna.graphics': {
          desc: 'Drawing primitives, colors, transforms, and render state.',
          funcs: [
            { name: 'luna.graphics.rectangle', sig: 'luna.graphics.rectangle(mode, x, y, w, h)', desc: 'Draw a rectangle.', params: ['mode: "fill" or "line"', 'x, y: position', 'w, h: size'], returns: 'nil' },
            { name: 'luna.graphics.circle', sig: 'luna.graphics.circle(mode, x, y, r)', desc: 'Draw a circle.', params: ['mode: "fill" or "line"', 'x, y: center', 'r: radius'], returns: 'nil' },
            { name: 'luna.graphics.line', sig: 'luna.graphics.line(x1, y1, x2, y2)', desc: 'Draw a line between two points.', params: ['x1, y1: start point', 'x2, y2: end point'], returns: 'nil' },
            { name: 'luna.graphics.print', sig: 'luna.graphics.print(text, x, y)', desc: 'Draw text at position.', params: ['text: string to draw', 'x, y: position'], returns: 'nil' },
            { name: 'luna.graphics.setColor', sig: 'luna.graphics.setColor(r, g, b, a)', desc: 'Set the active drawing color.', params: ['r, g, b: 0-1 color channels', 'a: alpha (default 1)'], returns: 'nil' },
            { name: 'luna.graphics.setBackgroundColor', sig: 'luna.graphics.setBackgroundColor(r, g, b)', desc: 'Set the background clear color.', params: ['r, g, b: 0-1 color channels'], returns: 'nil' },
            { name: 'luna.graphics.draw', sig: 'luna.graphics.draw(image, x, y, r, sx, sy)', desc: 'Draw an image/texture.', params: ['image: texture object', 'x, y: position', 'r: rotation (radians)', 'sx, sy: scale'], returns: 'nil' },
            { name: 'luna.graphics.newImage', sig: 'luna.graphics.newImage(path)', desc: 'Load an image from file and return texture handle.', params: ['path: file path relative to game dir'], returns: 'Image' },
          ]
        },
        'luna.keyboard': {
          desc: 'Keyboard input state and key queries.',
          funcs: [
            { name: 'luna.keyboard.isDown', sig: 'luna.keyboard.isDown(key)', desc: 'Check if a key is currently held down.', params: ['key: key name ("space", "a", "left", etc.)'], returns: 'boolean' },
            { name: 'luna.keyboard.isUp', sig: 'luna.keyboard.isUp(key)', desc: 'Check if a key is not pressed.', params: ['key: key name'], returns: 'boolean' },
          ]
        },
        'luna.mouse': {
          desc: 'Mouse position and button queries.',
          funcs: [
            { name: 'luna.mouse.getPosition', sig: 'luna.mouse.getPosition()', desc: 'Get current mouse position.', params: [], returns: 'x, y' },
            { name: 'luna.mouse.isDown', sig: 'luna.mouse.isDown(button)', desc: 'Check if a mouse button is held.', params: ['button: 1=left, 2=right, 3=middle'], returns: 'boolean' },
          ]
        },
        'luna.audio': {
          desc: 'Sound loading and playback.',
          funcs: [
            { name: 'luna.audio.newSource', sig: 'luna.audio.newSource(path, type)', desc: 'Load an audio source.', params: ['path: file path', 'type: "static" or "stream"'], returns: 'Source' },
            { name: 'luna.audio.play', sig: 'luna.audio.play(source)', desc: 'Play an audio source.', params: ['source: Source object'], returns: 'nil' },
            { name: 'luna.audio.stop', sig: 'luna.audio.stop(source)', desc: 'Stop an audio source.', params: ['source: Source object'], returns: 'nil' },
            { name: 'luna.audio.setVolume', sig: 'luna.audio.setVolume(source, vol)', desc: 'Set volume of a source.', params: ['source: Source object', 'vol: 0.0-1.0'], returns: 'nil' },
          ]
        },
        'luna.physics': {
          desc: 'Physics world, bodies, and collision.',
          funcs: [
            { name: 'luna.physics.newWorld', sig: 'luna.physics.newWorld(gx, gy)', desc: 'Create a physics world.', params: ['gx, gy: gravity vector'], returns: 'World' },
            { name: 'luna.physics.newBody', sig: 'luna.physics.newBody(world, x, y, type)', desc: 'Create a physics body.', params: ['world: World', 'x, y: position', 'type: "dynamic", "static", "kinematic"'], returns: 'Body' },
            { name: 'luna.physics.update', sig: 'luna.physics.update(world, dt)', desc: 'Step the physics world.', params: ['world: World', 'dt: time step'], returns: 'nil' },
          ]
        },
        'luna.timer': {
          desc: 'Time and delta queries.',
          funcs: [
            { name: 'luna.timer.getDelta', sig: 'luna.timer.getDelta()', desc: 'Get time since last frame in seconds.', params: [], returns: 'number' },
            { name: 'luna.timer.getFPS', sig: 'luna.timer.getFPS()', desc: 'Get current frames per second.', params: [], returns: 'number' },
            { name: 'luna.timer.getTime', sig: 'luna.timer.getTime()', desc: 'Get time since engine start.', params: [], returns: 'number' },
          ]
        },
        'luna.window': {
          desc: 'Window management.',
          funcs: [
            { name: 'luna.window.setTitle', sig: 'luna.window.setTitle(title)', desc: 'Set window title.', params: ['title: string'], returns: 'nil' },
            { name: 'luna.window.getWidth', sig: 'luna.window.getWidth()', desc: 'Get window width.', params: [], returns: 'number' },
            { name: 'luna.window.getHeight', sig: 'luna.window.getHeight()', desc: 'Get window height.', params: [], returns: 'number' },
            { name: 'luna.window.setMode', sig: 'luna.window.setMode(w, h, flags)', desc: 'Set window size and mode.', params: ['w, h: dimensions', 'flags: table with fullscreen, vsync, etc.'], returns: 'nil' },
          ]
        },
        'luna.math': {
          desc: 'Math utilities.',
          funcs: [
            { name: 'luna.math.random', sig: 'luna.math.random(min, max)', desc: 'Random number between min and max.', params: ['min, max: range bounds'], returns: 'number' },
            { name: 'luna.math.lerp', sig: 'luna.math.lerp(a, b, t)', desc: 'Linear interpolation.', params: ['a, b: values', 't: 0-1 factor'], returns: 'number' },
            { name: 'luna.math.clamp', sig: 'luna.math.clamp(x, min, max)', desc: 'Clamp value to range.', params: ['x: value', 'min, max: bounds'], returns: 'number' },
          ]
        },
        'Callbacks': {
          desc: 'Engine callback functions set by game scripts.',
          funcs: [
            { name: 'luna.load', sig: 'function luna.load()', desc: 'Called once when the game starts. Initialize resources here.', params: [], returns: 'nil', tag: 'event' },
            { name: 'luna.update', sig: 'function luna.update(dt)', desc: 'Called every frame. Update game logic.', params: ['dt: delta time in seconds'], returns: 'nil', tag: 'event' },
            { name: 'luna.draw', sig: 'function luna.draw()', desc: 'Called every frame after update. Render your game.', params: [], returns: 'nil', tag: 'event' },
            { name: 'luna.keypressed', sig: 'function luna.keypressed(key)', desc: 'Called when key is pressed.', params: ['key: key name string'], returns: 'nil', tag: 'event' },
            { name: 'luna.mousepressed', sig: 'function luna.mousepressed(x, y, btn)', desc: 'Called on mouse press.', params: ['x, y: position', 'btn: button number'], returns: 'nil', tag: 'event' },
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
          el.innerHTML = '<div class="module-header">Luna2D API Reference</div><div class="module-desc">Select a module.</div>';
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
    `)}};var Je=E(require("vscode"));var Sn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.editor.postfxOverlay","PostFX & Overlay Designer")}handleMessage(e){if(e.type==="copyCode"&&(Je.env.clipboard.writeText(e.code),Je.window.showInformationMessage("PostFX code copied to clipboard.")),e.type==="insertCode"){let t=Je.window.activeTextEditor;t?t.insertSnippet(new Je.SnippetString(e.code)):Je.window.showWarningMessage("Open a Lua file to insert code.")}}getHtml(){let e=L();return R(e,"PostFX & Overlay Designer",`
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
            code += 'local weather = luna.postfx.createWeather({\\n';
            code += '  preset   = "' + preset.toLowerCase().replace(/ /g,'_') + '",\\n';
            code += '  intensity = ' + intensity.toFixed(2) + ',\\n';
            code += '  wind      = luna.math.vec2(' + windX + ', ' + windY + '),\\n';
            code += '  color     = luna.graphics.newColor("' + color + '"),\\n';
            code += '})\\n\\n';
            code += 'function luna.update(dt)\\n  weather:update(dt)\\nend\\n';
            code += 'function luna.draw()\\n  weather:draw()\\n';
            if (fogDensity > 0) code += '  luna.postfx.fog({ density=' + fogDensity.toFixed(2) + ', color=luna.graphics.newColor("' + fogColor + '") })\\n';
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
          code += 'local tod = luna.postfx.createTimeOfDay({\\n';
          code += '  hour         = ' + hour.toFixed(2) + ',\\n';
          code += '  sky_color    = luna.graphics.newColor("' + sky + '"),\\n';
          code += '  sun_color    = luna.graphics.newColor("' + sun + '"),\\n';
          code += '  ambient      = ' + ambient.toFixed(2) + ',\\n';
          code += '  moon_enabled = ' + moon + ',\\n';
          code += '  stars        = ' + stars + ',\\n';
          code += '  speed        = ' + speed.toFixed(3) + ',\\n';
          code += '})\\n\\n';
          code += 'function luna.update(dt)\\n  tod:update(dt)\\nend\\n';
          code += 'function luna.draw()\\n  tod:drawSky()\\n  -- draw game world here\\n  tod:drawOverlay()\\nend';
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
          code = '-- Screen PostFX\\nfunction luna.draw()\\n  -- draw game\\n  local fx = luna.postfx.begin()\\n';
          if (vig > 0)    lines.push('  fx:vignette({ strength=' + vig.toFixed(2) + ', color=luna.graphics.newColor("' + g('vignetteColor').value + '") })');
          if (scan > 0)   lines.push('  fx:scanlines({ alpha=' + scan.toFixed(2) + ' })');
          if (sat !== 1)  lines.push('  fx:saturation(' + sat.toFixed(2) + ')');
          if (bright !== 1) lines.push('  fx:brightness(' + bright.toFixed(2) + ')');
          if (cont !== 1) lines.push('  fx:contrast(' + cont.toFixed(2) + ')');
          if (chrom > 0)  lines.push('  fx:chromaticAberration(' + chrom.toFixed(1) + ')');
          if (px > 1)     lines.push('  fx:pixelate(' + px + ')');
          if (grain > 0)  lines.push('  fx:filmGrain(' + grain.toFixed(2) + ')');
          if (bloom_ > 0) lines.push('  fx:bloom({ threshold=0.7, strength=' + bloom_.toFixed(2) + ' })');
          code += lines.join('\\n') + '\\n  luna.postfx.finish(fx)\\nend';
        } else if (currentTab === 'shake') {
          const amp = fv('shakeAmplitude'), freq = fv('shakeFrequency');
          const dur = fv('shakeDuration'), decay = fv('shakeDecay');
          const rot = fv('shakeRotation');
          const trauma = g('shakeTrauma').checked;
          code = '-- Camera Shake\\n';
          code += 'local shaker = luna.camera.createShaker({\\n';
          code += '  amplitude  = ' + amp.toFixed(1) + ',\\n';
          code += '  frequency  = ' + freq + ',\\n';
          code += '  duration   = ' + dur.toFixed(2) + ',\\n';
          code += '  decay      = ' + decay.toFixed(1) + ',\\n';
          code += '  rotation   = ' + rot.toFixed(1) + ',\\n';
          code += '  trauma     = ' + trauma + ',\\n';
          code += '})\\n\\n';
          code += '-- Trigger a shake (e.g. on explosion):\\nshaker:shake()\\n\\n';
          code += 'function luna.update(dt)\\n  shaker:update(dt)\\nend\\n';
          code += 'function luna.draw()\\n  shaker:push()\\n  -- draw everything here\\n  shaker:pop()\\nend';
        } else if (currentTab === 'overlay') {
          const preset = g('overlayPreset').value;
          const alpha = fv('overlayAlpha');
          const color = g('overlayColor').value;
          const pulse = g('overlayPulsate').checked;
          const speed = fv('overlayPulseSpeed');
          code = '-- Overlay: ' + preset + '\\n';
          code += 'local overlay = luna.postfx.createOverlay({\\n';
          code += '  preset  = "' + preset.toLowerCase().replace(/ /g,'_') + '",\\n';
          code += '  color   = luna.graphics.newColor("' + color + '"),\\n';
          code += '  alpha   = ' + alpha.toFixed(2) + ',\\n';
          code += '  pulsate = ' + pulse + ',\\n';
          if (pulse) code += '  speed   = ' + speed.toFixed(1) + ',\\n';
          code += '})\\n\\n';
          code += 'function luna.update(dt)\\n  overlay:update(dt)\\nend\\n';
          code += 'function luna.draw()\\n  -- draw game\\n  overlay:draw()\\nend';
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
    `)}};var Qe=E(require("vscode"));var En=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.editor.soundDsp","Sound DSP Panel")}handleMessage(e){if(e.type==="copyCode"&&(Qe.env.clipboard.writeText(e.code),Qe.window.showInformationMessage("Sound DSP code copied to clipboard.")),e.type==="insertCode"){let t=Qe.window.activeTextEditor;t?t.insertSnippet(new Qe.SnippetString(e.code)):Qe.window.showWarningMessage("Open a Lua file to insert code.")}}getHtml(){let e=L();return R(e,"Sound DSP Panel",`
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
          code += 'local dsp = luna.sound.createDsp()\\n\\n';
          code += 'dsp:setMasterVolume(' + fv('masterVolume').toFixed(2) + ')\\n';
          code += 'dsp:setMasterPan(' + fv('masterPan').toFixed(2) + ')\\n';
          code += 'dsp:setSampleRate(' + sv('sampleRate') + ')\\n\\n';
          code += '-- Apply DSP to a source:\\n';
          code += 'local src = luna.sound.load("my_sound.wav")\\n';
          code += 'luna.sound.setDsp(src, dsp)\\n';
          code += 'luna.sound.play(src)';
        } else if (currentTab === 'eq') {
          code = '-- 7-Band Parametric EQ\\n';
          code += 'local eq = luna.sound.createEq({\\n';
          const freqs = ['60','150','400','1000','2500','6000','16000'];
          EQ_BANDS.forEach((band, i) => {
            const gain = fv(band.id);
            if (gain !== 0) code += '  { freq=' + freqs[i] + ', gain=' + gain.toFixed(1) + ' },\\n';
          });
          code += '})\\n';
          code += 'luna.sound.addEffect(src, eq)';
        } else if (currentTab === 'reverb') {
          code = '-- Reverb Effect\\n';
          code += 'local reverb = luna.sound.createReverb({\\n';
          code += '  room_size  = ' + fv('reverbRoom').toFixed(2) + ',\\n';
          code += '  damping    = ' + fv('reverbDamp').toFixed(2) + ',\\n';
          code += '  wet_dry    = ' + fv('reverbMix').toFixed(2) + ',\\n';
          code += '  pre_delay  = ' + fv('reverbPredelay') + ',  -- ms\\n';
          code += '  width      = ' + fv('reverbWidth').toFixed(2) + ',\\n';
          code += '  decay      = ' + fv('reverbDecay').toFixed(1) + ',\\n';
          code += '})\\n';
          code += 'luna.sound.addEffect(src, reverb)';
        } else if (currentTab === 'echo') {
          const delay = fv('echoDelay');
          const syncBpm = bv('echoSyncBpm');
          code = '-- Echo / Delay Effect\\n';
          code += 'local echo = luna.sound.createEcho({\\n';
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
          code += 'luna.sound.addEffect(src, echo)';
        } else if (currentTab === 'chorus') {
          code = '-- ' + sv('chorusMode') + ' Effect\\n';
          code += 'local chorus = luna.sound.createChorus({\\n';
          code += '  mode     = "' + sv('chorusMode').toLowerCase() + '",\\n';
          code += '  depth    = ' + fv('chorusDepth').toFixed(2) + ',\\n';
          code += '  rate     = ' + fv('chorusRate').toFixed(2) + ',\\n';
          code += '  wet_dry  = ' + fv('chorusMix').toFixed(2) + ',\\n';
          code += '  voices   = ' + fv('chorusVoices') + ',\\n';
          code += '  spread   = ' + fv('chorusSpread').toFixed(2) + ',\\n';
          if (sv('chorusMode') === 'Flanger') code += '  feedback = ' + fv('flangerFeedback').toFixed(2) + ',\\n';
          code += '})\\n';
          code += 'luna.sound.addEffect(src, chorus)';
        } else if (currentTab === 'pitch') {
          const semi = fv('pitchSemitones'), cents = fv('pitchCents'), rate = fv('pitchRate');
          const sweepFrom = fv('pitchSweepFrom'), sweepTo = fv('pitchSweepTo'), sweepTime = fv('pitchSweepTime');
          code = '-- Pitch Shift\\n';
          code += 'local pitch = luna.sound.createPitchShift({\\n';
          if (semi !== 0) code += '  semitones = ' + semi + ',\\n';
          if (cents !== 0) code += '  cents     = ' + cents + ',\\n';
          if (rate !== 1) code += '  rate      = ' + rate.toFixed(2) + ',\\n';
          code += '  preserve_formants = ' + bv('pitchFormant') + ',\\n';
          if (sweepFrom !== 0 || sweepTo !== 0) {
            code += '  sweep = { from=' + sweepFrom + ', to=' + sweepTo + ', time=' + sweepTime.toFixed(2) + ' },\\n';
          }
          code += '})\\n';
          code += 'luna.sound.addEffect(src, pitch)';
        } else if (currentTab === 'dynamics') {
          code = '-- Dynamics Processing\\n';
          const drive = fv('distDrive');
          code += 'local chain = luna.sound.createDynamics({\\n';
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
          code += 'luna.sound.addEffect(src, chain)';
        } else if (currentTab === 'generator') {
          const type = sv('genType').toLowerCase();
          code = '-- Procedural Sound: ' + sv('genType') + '\\n';
          code += 'local synth = luna.sound.createSynth({\\n';
          code += '  wave      = "' + type + '",\\n';
          code += '  frequency = ' + fv('genFreq') + ',\\n';
          code += '  volume    = ' + fv('genVol').toFixed(2) + ',\\n';
          code += '  duration  = ' + fv('genDur').toFixed(2) + ',\\n';
          code += '  adsr      = { attack=' + fv('adsrAttack').toFixed(3) + ', decay=' + fv('adsrDecay').toFixed(3) + ', sustain=' + fv('adsrSustain').toFixed(2) + ', release=' + fv('adsrRelease').toFixed(3) + ' },\\n';
          const sf = fv('pitchSweepFrom'), st2 = fv('pitchSweepTo'), sTime = fv('pitchSweepTime');
          if (sf !== 0 || st2 !== 0) code += '  sweep     = { from=' + sf + ', to=' + st2 + ', time=' + sTime.toFixed(2) + ' },\\n';
          code += '})\\n\\n';
          code += '-- Play immediately:\\nluna.sound.play(luna.sound.fromSynth(synth))';
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
    `)}};var Cn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.spriteAnimEditor","Sprite Animation")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"animation.lua");break}}getHtml(){let e=L();return R(e,"Sprite Animation",`
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
    `)}};var Tn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.tilesetEditor","Tileset")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"tileset.lua");break}}getHtml(){let e=L();return R(e,"Tileset",`
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
    `)}};var In=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.audioMixerEditor","Audio Mixer")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"mixer.lua");break}}getHtml(){let e=L();return R(e,"Audio Mixer",`
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
    `)}};var Pn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.colorPaletteEditor","Color Palette")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"palette.lua");break}}getHtml(){let e=L();return R(e,"Color Palette",`
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
    `)}};var Ln=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.inputMapperEditor","Input Mapper")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"input_map.lua");break}}getHtml(){let e=L();return R(e,"Input Mapper",`
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
    `)}};var Rn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.timelineEditor","Timeline")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"timeline.lua");break}}getHtml(){let e=L();return R(e,"Timeline",`
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
    `)}};var Mn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.shaderPreviewEditor","Shader Preview")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"shader.lua");break}}getHtml(){let e=L();return R(e,"Shader Preview",`
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
          code: '-- Wave Distortion Shader\\n-- Uniforms: amplitude, frequency, speed\\n\\nfunction effect(pixel, x, y, uniforms)\\n  local amp = (uniforms.amplitude or 10)\\n  local freq = (uniforms.frequency or 20) / 100\\n  local t = luna.timer.getTime()\\n  local offset = math.sin(y * freq + t) * amp\\n  return getPixel(x + offset, y)\\nend',
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
    `)}};var Dn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.fontPreviewEditor","Font Preview")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"font_config.lua");break}}getHtml(){let e=L();return R(e,"Font Preview",`
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
        let lua = '-- Font configuration for Luna2D\\n';
        lua += 'local font = luna.graphics.newFont("' + fontFamily + '", ' + fontSize + ')\\n';
        lua += '-- Style: ' + (bold ? 'bold ' : '') + (italic ? 'italic' : 'normal') + '\\n';
        lua += '-- Color: { ' + parseInt(textColor.slice(1,3),16) + ', ' + parseInt(textColor.slice(3,5),16) + ', ' + parseInt(textColor.slice(5,7),16) + ' }\\n';
        lua += '-- Line height: ' + lineHeight.toFixed(1) + '\\n';
        lua += '-- Letter spacing: ' + letterSpacing + '\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      updatePreview();
      buildGlyphGrid();
    `)}};var An=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.localizationEditor","Localization")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"strings.lua");break;case"exportJson":this.exportFile(e.content,"strings.json","JSON","json");break}}getHtml(){let e=L();return R(e,"Localization",`
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
    `)}};var Fn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.physicsMaterialsEditor","Physics Materials")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"physics_materials.lua");break}}getHtml(){let e=L();return R(e,"Physics Materials",`
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
    `)}};var Bn=class n extends P{static open(e){return new n(e)}constructor(e){super(e,"luna.worldMapEditor","World Map")}handleMessage(e){switch(e.type){case"exportLua":this.exportLua(e.content,"world_map.lua");break}}getHtml(){let e=L();return R(e,"World Map",`
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
    `)}};var ic=[{id:"tileMap",open:n=>sn.open(n)},{id:"sceneFlow",open:n=>rn.open(n)},{id:"entity",open:n=>ln.open(n)},{id:"pixelArt",open:n=>dn.open(n)},{id:"particle",open:n=>cn.open(n)},{id:"dialog",open:n=>un.open(n)},{id:"database",open:n=>pn.open(n)},{id:"procMap",open:n=>fn.open(n)},{id:"questTree",open:n=>gn.open(n)},{id:"guiWidget",open:n=>hn.open(n)},{id:"aiBehavior",open:n=>vn.open(n)},{id:"graph",open:n=>yn.open(n)},{id:"tilemapScript",open:n=>bn.open(n)},{id:"voxel",open:n=>xn.open(n)},{id:"testRunner",open:n=>wn.open(n)},{id:"apiReference",open:n=>kn.open(n)},{id:"postfxOverlay",open:n=>Sn.open(n)},{id:"soundDsp",open:n=>En.open(n)},{id:"spriteAnim",open:n=>Cn.open(n)},{id:"tileset",open:n=>Tn.open(n)},{id:"audioMixer",open:n=>In.open(n)},{id:"colorPalette",open:n=>Pn.open(n)},{id:"inputMapper",open:n=>Ln.open(n)},{id:"timeline",open:n=>Rn.open(n)},{id:"shaderPreview",open:n=>Mn.open(n)},{id:"fontPreview",open:n=>Dn.open(n)},{id:"localization",open:n=>An.open(n)},{id:"physicsMaterials",open:n=>Fn.open(n)},{id:"worldMap",open:n=>Bn.open(n)}];function fi(n){return ic.map(e=>mi.commands.registerCommand(`luna.editor.${e.id}`,()=>e.open(n)))}var $=E(require("vscode")),Ze=E(require("path")),xe=E(require("fs"));async function Nn(){let n=$.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!n){$.window.showErrorMessage("No workspace folder open.");return}let e=Ze.join(n,"docs","lua_api_reference_generated.md");if(!xe.existsSync(e)){$.window.showWarningMessage("API reference not found. Run 'python tools/gen_lua_api.py' to generate it.");return}let t=xe.readFileSync(e,"utf-8"),o=t.split(`
`).filter(s=>s.startsWith("## ")||s.startsWith("### ")).map(s=>s.replace(/^#+\s*/,""));if(o.length===0){$.window.showInformationMessage("No API entries found.");return}let a=await $.window.showQuickPick(o,{placeHolder:"Search Luna2D API...",matchOnDescription:!0});if(a){let s=await $.workspace.openTextDocument(e),i=await $.window.showTextDocument(s),r=t.split(`
`).findIndex(l=>l.includes(a));if(r>=0){let l=new $.Position(r,0);i.selection=new $.Selection(l,l),i.revealRange(new $.Range(l,l))}}}async function gi(){let n=$.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!n){$.window.showErrorMessage("No workspace folder open.");return}let e=Ze.join(n,"docs","lua_api_reference_generated.md");if(!xe.existsSync(e)){$.window.showWarningMessage("API reference not found. Run 'python tools/gen_lua_api.py' first.");return}let t=await $.workspace.openTextDocument(e);await $.window.showTextDocument(t)}async function hi(){let n=$.window.activeTextEditor,e=n?.document.getWordRangeAtPosition(n.selection.active,/luna\.[a-zA-Z0-9_.]+/),t=e?n.document.getText(e):void 0,o=$.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!o){$.window.showErrorMessage("No workspace folder open.");return}let a=Ze.join(o,"docs","lua_api_reference_generated.md"),s=Ze.join(o,"docs","lua-api.md"),i=xe.existsSync(a)?a:xe.existsSync(s)?s:null;if(i){let l=xe.readFileSync(i,"utf-8").split(`
`);if(t){let d=t.replace(/^luna\./,""),c=l.findIndex(f=>f.startsWith("##")&&(f.includes(t)||f.includes(d))),u=await $.workspace.openTextDocument(i),h=await $.window.showTextDocument(u),p=new $.Position(Math.max(0,c),0);h.selection=new $.Selection(p,p),h.revealRange(new $.Range(p,p),$.TextEditorRevealType.InCenter),c<0&&$.window.showInformationMessage(`"${t}" not found in API docs \u2014 showing full reference.`)}else{let d=await $.workspace.openTextDocument(i);await $.window.showTextDocument(d)}}else await Nn()}function Do(n){let e=$.workspace.workspaceFolders?.[0]?.uri.fsPath,t=$.window.createWebviewPanel("luna.depGraph","Luna2D Module Dependency Graph",$.ViewColumn.One,{enableScripts:!0,retainContextWhenHidden:!0}),o=[],a=[],s={math:"leaf",engine:"core",lua_api:"integration",window:"core",graphics:"domain",physics:"domain",audio:"domain",input:"domain",timer:"domain",filesystem:"domain",tilemap:"domain",sound:"domain",ai:"domain",compute:"domain",data:"domain",dataframe:"domain",entity:"domain",event:"domain",graph:"domain",image:"domain",modding:"domain",particle:"domain",savegame:"domain",scene:"domain",stats:"domain",thread:"domain",pathfinding:"domain",dialog:"domain",cardgame:"domain",combat:"domain",crafting:"domain",inventory:"domain",quest:"domain",resource:"domain"};if(e){let d=Ze.join(e,"src");if(xe.existsSync(d)){let c=xe.readdirSync(d,{withFileTypes:!0}).filter(u=>u.isDirectory()).map(u=>u.name);for(let u of c)o.push({id:u,tier:s[u]??"domain"});for(let u of c){let h=Ze.join(d,u,"mod.rs"),p=Ze.join(d,u,"lib.rs"),f=xe.existsSync(h)?h:xe.existsSync(p)?p:null;if(f)try{let m=[...xe.readFileSync(f,"utf-8").matchAll(/use crate::([a-z_]+)/g)],v=new Set;for(let y of m){let b=y[1];b!==u&&c.includes(b)&&!v.has(b)&&(v.add(b),a.push({from:u,to:b}))}}catch{}}}}if(o.length===0){for(let[c,u]of Object.entries(s))o.push({id:c,tier:u});let d=[{from:"engine",to:"math"},{from:"graphics",to:"math"},{from:"physics",to:"math"},{from:"audio",to:"math"},{from:"input",to:"math"},{from:"timer",to:"math"},{from:"lua_api",to:"engine"},{from:"lua_api",to:"graphics"},{from:"lua_api",to:"physics"},{from:"lua_api",to:"audio"},{from:"lua_api",to:"input"},{from:"lua_api",to:"timer"},{from:"lua_api",to:"filesystem"},{from:"lua_api",to:"tilemap"},{from:"lua_api",to:"ai"},{from:"lua_api",to:"entity"},{from:"lua_api",to:"scene"},{from:"lua_api",to:"particle"}];a.push(...d)}let i=rc(),r=JSON.stringify(o),l=JSON.stringify(a);t.webview.html=`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'nonce-${i}'; style-src 'nonce-${i}';">
<title>Module Dependency Graph</title>
<style nonce="${i}">
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
<script nonce="${i}">
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
</html>`}function vi(){let n=$.window.createTerminal("Luna Deps");n.show(),n.sendText("cargo tree --depth 1")}function rc(){let n="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",e="";for(let t=0;t<32;t++)e+=n.charAt(Math.floor(Math.random()*n.length));return e}var U=E(require("vscode")),Ie=E(require("path")),he=E(require("fs"));async function yi(){let n=U.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!n){U.window.showErrorMessage("No workspace folder open.");return}let e=null,t=__dirname;for(let i=0;i<6;i++){let r=Ie.join(t,".github");if(he.existsSync(r)){e=r;break}t=Ie.dirname(t)}if(!e){U.window.showErrorMessage("Could not locate engine .github/ folder. Make sure the extension is run from the luna_2d repository root.");return}let o=Ie.join(n,".github");if(he.existsSync(o)&&await U.window.showWarningMessage(".github/ directory already exists in your workspace. Overwrite all CAG files?","Yes \u2014 Overwrite","Cancel")!=="Yes \u2014 Overwrite")return;let a=0;function s(i,r){he.mkdirSync(r,{recursive:!0});for(let l of he.readdirSync(i,{withFileTypes:!0})){let d=Ie.join(i,l.name),c=Ie.join(r,l.name);l.isDirectory()?s(d,c):(he.copyFileSync(d,c),a++)}}try{s(e,o),U.window.showInformationMessage(`\u2705 CAG installed: ${a} file(s) copied to .github/`)}catch(i){U.window.showErrorMessage(`CAG install failed: ${i}`)}}async function bi(){let n=await ki("agents","*.agent.md");if(n.length===0){U.window.showWarningMessage("No agent definitions found.");return}let e=await U.window.showQuickPick(n,{placeHolder:"Select an agent"});if(e){let t=U.workspace.workspaceFolders?.[0]?.uri.fsPath;if(t){let o=Ie.join(t,".github","agents",e);if(he.existsSync(o)){let a=await U.workspace.openTextDocument(o);await U.window.showTextDocument(a)}}}}async function xi(){let n=U.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!n){U.window.showErrorMessage("No workspace folder open.");return}let e=Ie.join(n,".github","skills");if(!he.existsSync(e)){U.window.showWarningMessage("No skills directory found.");return}let t=he.readdirSync(e,{withFileTypes:!0}).filter(a=>a.isDirectory()).map(a=>a.name);if(t.length===0){U.window.showWarningMessage("No skills found.");return}let o=await U.window.showQuickPick(t,{placeHolder:"Select a skill"});if(o){let a=Ie.join(e,o,"SKILL.md");if(he.existsSync(a)){let s=await U.workspace.openTextDocument(a);await U.window.showTextDocument(s)}}}async function wi(){let n=await ki("prompts","*.prompt.md");if(n.length===0){U.window.showWarningMessage("No prompts found.");return}let e=await U.window.showQuickPick(n,{placeHolder:"Select a prompt"});if(e){let t=U.workspace.workspaceFolders?.[0]?.uri.fsPath;if(t){let o=Ie.join(t,".github","prompts",e);if(he.existsSync(o)){let a=await U.workspace.openTextDocument(o);await U.window.showTextDocument(a)}}}}async function ki(n,e){let t=U.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!t)return[];let o=Ie.join(t,".github",n);if(!he.existsSync(o))return[];try{return he.readdirSync(o,{withFileTypes:!0}).filter(a=>a.isFile()&&a.name.endsWith(".md")).map(a=>a.name)}catch{return[]}}var _=E(require("vscode")),oe=E(require("path")),ce=E(require("fs"));function Ao(n){let e=[],t=new Set,o=/luna\.(\w+)\.(\w+)\s*\(/g;for(let[a,s]of n.split(`
`).entries()){let i;for(o.lastIndex=0;(i=o.exec(s))!==null;){let r=i[1],l=i[2],d=`${r}.${l}`;t.has(d)||(t.add(d),e.push({module:r,func:l,line:a+1,text:s.trim()}))}}return e}function lc(n){let e=[],t=n.split(`
`),o=/^(?:local\s+)?function\s+([\w.:]+)\s*\(/;for(let a=0;a<t.length;a++){let s=o.exec(t[a]);if(s){let i=s[1],r=a,l=1,d=a+1;for(;d<t.length&&l>0;d++){let c=t[d].trim();/^(?:function|if|for|while|repeat)\b/.test(c)&&!c.endsWith("end")&&l++,/^end\b/.test(c)&&l--}e.push({name:i,line:r+1,endLine:d,body:t.slice(r,d).join(`
`)})}}return e}function dc(n,e){let t=[`-- Auto-generated tests for ${n}`,"-- Generated by Luna Toolkit","","local passed = 0","local failed = 0","local total = 0","","local function test(name, fn)","  total = total + 1","  local ok, err = pcall(fn)","  if ok then","    passed = passed + 1",'    print("[PASS] " .. name)',"  else","    failed = failed + 1",'    print("[FAIL] " .. name .. ": " .. tostring(err))',"  end","end",""],o=new Map;for(let a of e){let s=o.get(a.module)??[];s.push(a),o.set(a.module,s)}for(let[a,s]of o){t.push(`-- Tests for luna.${a}`,"");for(let i of s)t.push(`test("luna.${a}.${i.func} works", function()`,`  -- Source line ${i.line}: ${i.text}`,"  -- TODO: Add proper test assertion",`  local result = luna.${a}.${i.func}()`,`  assert(result ~= nil, "luna.${a}.${i.func} should return a value")`,"end)","")}return t.push("-- Summary",'print(string.format("\\n%d/%d tests passed (%d failed)", passed, total, failed))',"if failed > 0 then",'  error(string.format("%d tests failed", failed))',"end",""),t.join(`
`)}function cc(n,e,t){let o=Ao(t),a=[`-- Tests for function: ${e}`,`-- Source: ${n}`,"-- Generated by Luna Toolkit","","local passed = 0","local failed = 0","local total = 0","","local function test(name, fn)","  total = total + 1","  local ok, err = pcall(fn)","  if ok then","    passed = passed + 1",'    print("[PASS] " .. name)',"  else","    failed = failed + 1",'    print("[FAIL] " .. name .. ": " .. tostring(err))',"  end","end","","-- Basic existence test",`test("${e} is defined", function()`,`  assert(type(${e}) == "function", "${e} should be a function")`,"end)","","-- Call test",`test("${e} can be called", function()`,"  -- TODO: Provide appropriate arguments",`  local ok, err = pcall(${e})`,"  -- Adjust based on expected behavior","end)",""];if(o.length>0){a.push("-- API dependency tests");for(let s of o)a.push(`test("${e} uses luna.${s.module}.${s.func}", function()`,`  -- Verify luna.${s.module}.${s.func} is available`,`  assert(type(luna.${s.module}.${s.func}) == "function",`,`    "luna.${s.module}.${s.func} should be available")`,"end)","")}return a.push("-- Summary",'print(string.format("\\n%d/%d tests passed (%d failed)", passed, total, failed))',"if failed > 0 then",'  error(string.format("%d tests failed", failed))',"end",""),a.join(`
`)}function At(n){let e=oe.dirname(n);for(let t=0;t<10;t++){if(ce.existsSync(oe.join(e,"main.lua"))||ce.existsSync(oe.join(e,"conf.lua")))return e;let o=oe.dirname(e);if(o===e)break;e=o}return _.workspace.workspaceFolders?.[0]?.uri.fsPath}function Ei(n){n.subscriptions.push(_.commands.registerCommand("luna.test.generateForFile",async()=>{let e=_.window.activeTextEditor;if(!e||e.document.languageId!=="lua"){_.window.showWarningMessage("Open a Lua file first.");return}let t=e.document,o=t.getText(),a=Ao(o);if(a.length===0){_.window.showInformationMessage("No luna.* API calls detected in this file.");return}let s=oe.basename(t.fileName),i=At(t.fileName);if(!i){_.window.showErrorMessage("Could not determine game root directory.");return}let r=oe.join(i,"tests");ce.existsSync(r)||ce.mkdirSync(r,{recursive:!0});let l=`test_${s}`,d=oe.join(r,l),c=dc(s,a);ce.writeFileSync(d,c,"utf-8");let u=await _.workspace.openTextDocument(d);await _.window.showTextDocument(u),_.window.showInformationMessage(`Generated test file: tests/${l} (${a.length} API calls detected)`)})),n.subscriptions.push(_.commands.registerCommand("luna.test.generateForFunction",async()=>{let e=_.window.activeTextEditor;if(!e||e.document.languageId!=="lua"){_.window.showWarningMessage("Open a Lua file first.");return}let t=e.document,o=t.getText(),a=e.selection.active.line+1,i=lc(o).find(g=>a>=g.line&&a<=g.endLine);if(!i){_.window.showWarningMessage("No function found at cursor position.");return}let r=oe.basename(t.fileName),l=At(t.fileName);if(!l){_.window.showErrorMessage("Could not determine game root directory.");return}let d=oe.join(l,"tests");ce.existsSync(d)||ce.mkdirSync(d,{recursive:!0});let u=`test_${i.name.replace(/[.:]/g,"_")}.lua`,h=oe.join(d,u),p=cc(r,i.name,i.body);ce.writeFileSync(h,p,"utf-8");let f=await _.workspace.openTextDocument(h);await _.window.showTextDocument(f),_.window.showInformationMessage(`Generated test file: tests/${u} for ${i.name}()`)})),n.subscriptions.push(_.commands.registerCommand("luna.test.runCurrent",async()=>{let e=_.window.activeTextEditor;if(!e||e.document.languageId!=="lua"){_.window.showWarningMessage("Open a Lua test file first.");return}let t=e.document.fileName,o=At(t);if(!o){_.window.showErrorMessage("Could not determine game root directory.");return}let a=_.workspace.getConfiguration("luna").get("lunaPath","luna"),s=Si("Luna Tests");s.show();let i=oe.relative(o,t).replace(/\\/g,"/");s.sendText(`cd "${o}" && "${a}" --test "${i}"`)})),n.subscriptions.push(_.commands.registerCommand("luna.test.runAll",async()=>{let e=_.window.activeTextEditor,t=e?At(e.document.fileName):_.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!t){_.window.showErrorMessage("No game project found.");return}let o=oe.join(t,"tests");if(!ce.existsSync(o)){_.window.showWarningMessage("No tests/ directory found in the game project.");return}let a=ce.readdirSync(o).filter(l=>l.endsWith(".lua"));if(a.length===0){_.window.showWarningMessage("No Lua test files found in tests/.");return}let s=_.window.createOutputChannel("Luna Test Results");s.show(),s.appendLine(`Running ${a.length} test file(s)...`),s.appendLine("\u2500".repeat(50));let i=_.workspace.getConfiguration("luna").get("lunaPath","luna"),r=Si("Luna Tests");r.show();for(let l of a)s.appendLine(`
Running: ${l}`),r.sendText(`cd "${t}" && "${i}" --test "tests/${l}"`);s.appendLine(`
`+"\u2500".repeat(50)),s.appendLine(`Queued ${a.length} test files.`)})),n.subscriptions.push(_.commands.registerCommand("luna.test.coverage",async()=>{let e=_.window.activeTextEditor,t=e?At(e.document.fileName):_.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!t){_.window.showErrorMessage("No game project found.");return}let o=Ci(t),a=new Set,s=new Set;for(let l of o){let d=ce.readFileSync(l,"utf-8"),c=Ao(d),u=l.includes(`${oe.sep}tests${oe.sep}`)||oe.basename(l).startsWith("test_");for(let h of c){let p=`luna.${h.module}.${h.func}`;a.add(p),u&&s.add(p)}}let i=_.window.createOutputChannel("Luna API Coverage");i.show(),i.appendLine("Luna API Coverage Report"),i.appendLine("\u2550".repeat(50)),i.appendLine(`Total API calls used: ${a.size}`),i.appendLine(`Covered by tests:     ${s.size}`);let r=a.size>0?Math.round(s.size/a.size*100):0;if(i.appendLine(`Coverage:             ${r}%`),i.appendLine(""),a.size>s.size){i.appendLine("Untested API calls:");for(let l of[...a].sort())s.has(l)||i.appendLine(`  \u26A0 ${l}`)}i.appendLine(""),i.appendLine("Tested API calls:");for(let l of[...s].sort())i.appendLine(`  \u2713 ${l}`)}))}function Ci(n,e=[]){if(!ce.existsSync(n))return e;let t=ce.readdirSync(n,{withFileTypes:!0});for(let o of t){let a=oe.join(n,o.name);o.isDirectory()&&o.name!=="node_modules"&&o.name!==".git"?Ci(a,e):o.isFile()&&o.name.endsWith(".lua")&&e.push(a)}return e}function Si(n){let e=_.window.terminals.find(t=>t.name===n);return e||_.window.createTerminal(n)}var _e=E(require("vscode")),Ii=E(require("net")),Ti=19740,uc=5e3,pc=1e4,zn=class{socket=null;outputChannel;connected=!1;requestId=0;pending=new Map;buffer="";statsItem=null;statsInterval=null;constructor(){this.outputChannel=_e.window.createOutputChannel("Luna Debug")}get isConnected(){return this.connected}async connect(e){if(this.connected)return this.outputChannel.appendLine("[debug] Already connected."),!0;let t=e??_e.workspace.getConfiguration("luna.debugBridge").get("port",Ti);return new Promise(o=>{let a=new Ii.Socket,s=setTimeout(()=>{a.destroy(),this.outputChannel.appendLine(`[debug] Connection timed out on port ${t}`),o(!1)},uc);a.connect(t,"127.0.0.1",()=>{clearTimeout(s),this.socket=a,this.connected=!0,this.buffer="",this.outputChannel.appendLine(`[debug] Connected to Luna2D on port ${t}`),o(!0)}),a.on("data",i=>this.onData(i)),a.on("error",i=>{clearTimeout(s),this.outputChannel.appendLine(`[debug] Connection error: ${i.message}`),this.cleanup(),o(!1)}),a.on("close",()=>{this.outputChannel.appendLine("[debug] Connection closed."),this.cleanup()})})}disconnect(){this.socket&&this.socket.destroy(),this.cleanup(),this.outputChannel.appendLine("[debug] Disconnected.")}async evaluate(e){let t=await this.sendRequest("evaluate",{expression:e});if(t.error)throw new Error(t.error);return String(t.data?.result??"nil")}async getVariables(){let e=await this.sendRequest("getVariables",{});if(e.error)throw new Error(e.error);let t=e.data?.variables;if(t&&typeof t=="object"){let o={};for(let[a,s]of Object.entries(t))o[a]=String(s);return o}return{}}async setBreakpoint(e,t){return!(await this.sendRequest("setBreakpoint",{file:e,line:t})).error}async removeBreakpoint(e,t){return!(await this.sendRequest("removeBreakpoint",{file:e,line:t})).error}async step(){await this.sendRequest("step",{})}async stepInto(){await this.sendRequest("stepInto",{})}async stepOut(){await this.sendRequest("stepOut",{})}async continueExecution(){await this.sendRequest("continue",{})}async hotReload(e){let o=(await _e.workspace.openTextDocument(e)).getText(),a=_e.workspace.asRelativePath(e,!1);return!(await this.sendRequest("hotReload",{file:a,content:o})).error}async getStats(){let e=await this.sendRequest("getStats",{});if(e.error)throw new Error(e.error);return{fps:Number(e.data?.fps??0),drawCalls:Number(e.data?.drawCalls??0),memory:Number(e.data?.memory??0)}}async getCallStack(){let e=await this.sendRequest("getCallStack",{});if(e.error)throw new Error(e.error);let t=e.data?.frames;return Array.isArray(t)?t.map((o,a)=>({level:a,source:String(o.source??"?"),line:Number(o.line??0),name:String(o.name??"?")})):[]}async takeScreenshot(){let e=await this.sendRequest("screenshot",{});if(e.error)throw new Error(e.error);return String(e.data?.png_base64??"")}getStatusInfo(){return{connected:this.connected,port:_e.workspace.getConfiguration("luna.debugBridge").get("port",Ti)}}startStatsPolling(){this.statsItem||(this.statsItem=_e.window.createStatusBarItem(_e.StatusBarAlignment.Right,50),this.statsItem.text="$(pulse) FPS: --",this.statsItem.tooltip="Luna2D Engine Stats",this.statsItem.show(),this.statsInterval=setInterval(async()=>{if(!this.connected){this.stopStatsPolling();return}try{let e=await this.getStats();this.statsItem&&(this.statsItem.text=`$(pulse) FPS: ${e.fps} | Draw: ${e.drawCalls} | Mem: ${(e.memory/1024/1024).toFixed(1)}MB`)}catch{}},1e3))}stopStatsPolling(){this.statsInterval&&(clearInterval(this.statsInterval),this.statsInterval=null),this.statsItem&&(this.statsItem.dispose(),this.statsItem=null)}showOutput(){this.outputChannel.show()}dispose(){this.disconnect(),this.stopStatsPolling(),this.outputChannel.dispose()}sendRequest(e,t){return new Promise((o,a)=>{if(!this.connected||!this.socket){a(new Error("Not connected to Luna2D engine."));return}let s=++this.requestId,i=JSON.stringify({id:s,type:e,data:t})+`
`,r=setTimeout(()=>{this.pending.delete(s),a(new Error(`Request ${e} timed out.`))},pc);this.pending.set(s,{resolve:o,reject:a,timer:r}),this.socket.write(i,l=>{l&&(clearTimeout(r),this.pending.delete(s),a(new Error(`Failed to send request: ${l.message}`)))})})}onData(e){this.buffer+=e.toString("utf-8");let t=this.buffer.split(`
`);this.buffer=t.pop()??"";for(let o of t){let a=o.trim();if(a)try{let s=JSON.parse(a),i=this.pending.get(s.id);i?(clearTimeout(i.timer),this.pending.delete(s.id),i.resolve(s)):this.outputChannel.appendLine(`[engine] ${a}`)}catch{this.outputChannel.appendLine(`[engine] ${a}`)}}}cleanup(){this.connected=!1,this.socket=null;for(let[,e]of this.pending)clearTimeout(e.timer),e.reject(new Error("Connection lost."));this.pending.clear(),this.stopStatsPolling()}};var W=E(require("vscode"));function Pi(n,e){n.subscriptions.push(W.commands.registerCommand("luna.debug.connect",async()=>{if(e.isConnected){W.window.showInformationMessage("Already connected to Luna2D engine.");return}let t=await W.window.showInputBox({prompt:"Debug bridge port",value:String(W.workspace.getConfiguration("luna.debugBridge").get("port",19740)),validateInput:a=>{let s=Number(a);if(isNaN(s)||s<1024||s>65535)return"Port must be 1024\u201365535"}});if(t===void 0)return;e.showOutput(),await e.connect(Number(t))?(W.window.showInformationMessage("Connected to Luna2D engine."),W.commands.executeCommand("setContext","luna.debugConnected",!0)):W.window.showErrorMessage("Failed to connect. Is the engine running with debug bridge enabled?")})),n.subscriptions.push(W.commands.registerCommand("luna.debug.disconnect",()=>{e.disconnect(),W.commands.executeCommand("setContext","luna.debugConnected",!1),W.window.showInformationMessage("Disconnected from Luna2D engine.")})),n.subscriptions.push(W.commands.registerCommand("luna.debug.evaluate",async()=>{if(!e.isConnected){W.window.showErrorMessage("Not connected to Luna2D engine. Run 'Luna: Debug Connect' first.");return}let t=await W.window.showInputBox({prompt:"Lua expression to evaluate",placeHolder:'e.g. print("hello") or player.x'});if(t)try{let o=await e.evaluate(t);e.showOutput(),W.window.showInformationMessage(`Result: ${o}`)}catch(o){W.window.showErrorMessage(`Evaluation failed: ${o instanceof Error?o.message:String(o)}`)}})),n.subscriptions.push(W.commands.registerCommand("luna.debug.hotReload",async()=>{if(!e.isConnected){W.window.showErrorMessage("Not connected to Luna2D engine.");return}let t=W.window.activeTextEditor;if(!t||t.document.languageId!=="lua"){W.window.showWarningMessage("Open a Lua file to hot-reload.");return}t.document.isDirty&&await t.document.save();try{await e.hotReload(t.document.uri)?W.window.showInformationMessage(`Hot-reloaded: ${W.workspace.asRelativePath(t.document.uri)}`):W.window.showErrorMessage("Hot-reload failed. Check debug output for details.")}catch(o){W.window.showErrorMessage(`Hot-reload error: ${o instanceof Error?o.message:String(o)}`)}})),n.subscriptions.push(W.commands.registerCommand("luna.debug.showStats",async()=>{if(!e.isConnected){W.window.showErrorMessage("Not connected to Luna2D engine.");return}e.startStatsPolling(),W.window.showInformationMessage("Engine stats enabled in status bar.")})),n.subscriptions.push(W.commands.registerCommand("luna.debug.inspect",async()=>{if(!e.isConnected){W.window.showErrorMessage("Not connected to Luna2D engine.");return}let t=W.window.activeTextEditor;if(!t){W.window.showWarningMessage("No active editor.");return}let o=t.selection,a;if(!o.isEmpty)a=t.document.getText(o);else{let s=t.document.getWordRangeAtPosition(o.active,/[\w.:\[\]]+/);if(!s){W.window.showWarningMessage("No variable found at cursor.");return}a=t.document.getText(s)}try{let s=await e.evaluate(`return tostring(${a})`),i=await e.evaluate(`return type(${a})`);W.window.showInformationMessage(`${a} = ${s} (${i})`)}catch(s){W.window.showErrorMessage(`Failed to inspect '${a}': ${s instanceof Error?s.message:String(s)}`)}}))}var H=E(require("vscode")),De=E(require("path")),se=E(require("fs")),mc=[{label:"Platformer",description:"Side-scrolling platformer with jump physics",confLua:`function luna.conf(t)
  t.window.title = "My Platformer"
  t.window.width = 800
  t.window.height = 600
end
`,mainLua:`-- Platformer Starter
local player = { x = 100, y = 400, w = 32, h = 48, vy = 0, speed = 200, jumping = false }
local gravity = 980
local jumpForce = -450
local ground = 500

function luna.load()
  luna.window.setTitle("My Platformer")
end

function luna.update(dt)
  -- Horizontal movement
  if luna.keyboard.isDown("left") or luna.keyboard.isDown("a") then
    player.x = player.x - player.speed * dt
  end
  if luna.keyboard.isDown("right") or luna.keyboard.isDown("d") then
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

function luna.keypressed(key)
  if key == "space" and not player.jumping then
    player.vy = jumpForce
    player.jumping = true
  end
  if key == "escape" then
    luna.event.quit()
  end
end

function luna.draw()
  -- Sky
  luna.graphics.setBackgroundColor(0.4, 0.7, 1.0)

  -- Ground
  luna.graphics.setColor(0.3, 0.6, 0.2)
  luna.graphics.rectangle("fill", 0, ground, 800, 100)

  -- Player
  luna.graphics.setColor(0.2, 0.4, 0.9)
  luna.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

  -- HUD
  luna.graphics.setColor(1, 1, 1)
  luna.graphics.print("Arrow keys / WASD to move, Space to jump", 10, 10)
end
`},{label:"Top-Down RPG",description:"Tile-based RPG with 4-directional movement",confLua:`function luna.conf(t)
  t.window.title = "My RPG"
  t.window.width = 640
  t.window.height = 480
end
`,mainLua:`-- Top-Down RPG Starter
local player = { x = 320, y = 240, w = 32, h = 32, speed = 150, dir = "down" }
local map_w, map_h = 20, 15
local tile_size = 32

function luna.load()
  luna.window.setTitle("My RPG")
end

function luna.update(dt)
  local dx, dy = 0, 0

  if luna.keyboard.isDown("up") or luna.keyboard.isDown("w") then
    dy = -1
    player.dir = "up"
  elseif luna.keyboard.isDown("down") or luna.keyboard.isDown("s") then
    dy = 1
    player.dir = "down"
  end

  if luna.keyboard.isDown("left") or luna.keyboard.isDown("a") then
    dx = -1
    player.dir = "left"
  elseif luna.keyboard.isDown("right") or luna.keyboard.isDown("d") then
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

function luna.keypressed(key)
  if key == "escape" then
    luna.event.quit()
  end
end

function luna.draw()
  luna.graphics.setBackgroundColor(0.15, 0.15, 0.2)

  -- Draw grid
  luna.graphics.setColor(0.25, 0.25, 0.3)
  for x = 0, map_w - 1 do
    for y = 0, map_h - 1 do
      luna.graphics.rectangle("line", x * tile_size, y * tile_size, tile_size, tile_size)
    end
  end

  -- Player
  luna.graphics.setColor(0.2, 0.8, 0.3)
  luna.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

  -- Direction indicator
  luna.graphics.setColor(1, 1, 1)
  local cx, cy = player.x + player.w / 2, player.y + player.h / 2
  local indicators = { up = {0, -8}, down = {0, 8}, left = {-8, 0}, right = {8, 0} }
  local ind = indicators[player.dir]
  luna.graphics.circle("fill", cx + ind[1], cy + ind[2], 4)

  -- HUD
  luna.graphics.setColor(1, 1, 1)
  luna.graphics.print("WASD / Arrow keys to move", 10, 10)
end
`},{label:"Shooter",description:"Top-down shooter with projectiles",confLua:`function luna.conf(t)
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

function luna.load()
  luna.window.setTitle("My Shooter")
end

function luna.update(dt)
  -- Player movement
  if luna.keyboard.isDown("left") or luna.keyboard.isDown("a") then
    player.x = player.x - player.speed * dt
  end
  if luna.keyboard.isDown("right") or luna.keyboard.isDown("d") then
    player.x = player.x + player.speed * dt
  end
  player.x = math.max(0, math.min(player.x, 800 - player.w))

  -- Shooting
  shoot_timer = shoot_timer - dt
  if luna.keyboard.isDown("space") and shoot_timer <= 0 then
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

function luna.keypressed(key)
  if key == "escape" then
    luna.event.quit()
  end
end

function luna.draw()
  luna.graphics.setBackgroundColor(0.05, 0.05, 0.1)

  -- Player
  luna.graphics.setColor(0.2, 0.7, 1.0)
  luna.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

  -- Bullets
  luna.graphics.setColor(1, 1, 0.3)
  for _, b in ipairs(bullets) do
    luna.graphics.rectangle("fill", b.x, b.y, b.w, b.h)
  end

  -- Enemies
  luna.graphics.setColor(1, 0.3, 0.3)
  for _, e in ipairs(enemies) do
    luna.graphics.rectangle("fill", e.x, e.y, e.w, e.h)
  end

  -- HUD
  luna.graphics.setColor(1, 1, 1)
  luna.graphics.print("Score: " .. score, 10, 10)
  luna.graphics.print("WASD to move, Space to shoot", 10, 30)
end
`},{label:"Puzzle",description:"Grid-based puzzle with tile swapping",confLua:`function luna.conf(t)
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

function luna.load()
  luna.window.setTitle("My Puzzle")
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

function luna.mousepressed(mx, my, button)
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

function luna.keypressed(key)
  if key == "r" then luna.load() end
  if key == "escape" then luna.event.quit() end
end

function luna.draw()
  luna.graphics.setBackgroundColor(0.12, 0.12, 0.15)

  for y = 1, grid_size do
    for x = 1, grid_size do
      local tile = grid[y][x]
      local px = padding + (x - 1) * tile_size + 4
      local py = padding + (y - 1) * tile_size + 4
      local tw = tile_size - 8
      local th = tile_size - 8

      if tile.revealed or tile.matched then
        luna.graphics.setColor(tile.color[1], tile.color[2], tile.color[3])
      else
        luna.graphics.setColor(0.3, 0.3, 0.35)
      end
      luna.graphics.rectangle("fill", px, py, tw, th)

      -- Border
      luna.graphics.setColor(0.5, 0.5, 0.55)
      luna.graphics.rectangle("line", px, py, tw, th)
    end
  end

  luna.graphics.setColor(1, 1, 1)
  luna.graphics.print("Moves: " .. moves .. "  |  R to restart", 10, 10)
end
`},{label:"Visual Novel",description:"Dialog-driven narrative with choices",confLua:`function luna.conf(t)
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

function luna.load()
  luna.window.setTitle("My Visual Novel")
end

function luna.update(dt)
  local mx, my = luna.mouse.getPosition()
  local scene = scenes[current_scene]
  hover_choice = 0

  for i, _ in ipairs(scene.choices) do
    local cy = 420 + (i - 1) * 50
    if mx >= 100 and mx <= 700 and my >= cy and my <= cy + 40 then
      hover_choice = i
    end
  end
end

function luna.mousepressed(mx, my, button)
  if button ~= 1 then return end
  local scene = scenes[current_scene]
  if hover_choice >= 1 and hover_choice <= #scene.choices then
    current_scene = scene.choices[hover_choice].next
    hover_choice = 0
  end
end

function luna.keypressed(key)
  if key == "escape" then luna.event.quit() end
  local scene = scenes[current_scene]
  local num = tonumber(key)
  if num and num >= 1 and num <= #scene.choices then
    current_scene = scene.choices[num].next
  end
end

function luna.draw()
  luna.graphics.setBackgroundColor(0.1, 0.08, 0.15)

  local scene = scenes[current_scene]

  -- Dialog box background
  luna.graphics.setColor(0.15, 0.12, 0.2, 0.95)
  luna.graphics.rectangle("fill", 50, 280, 700, 100)
  luna.graphics.setColor(0.6, 0.5, 0.8)
  luna.graphics.rectangle("line", 50, 280, 700, 100)

  -- Speaker name
  luna.graphics.setColor(0.8, 0.7, 1.0)
  luna.graphics.print(scene.speaker, 70, 260)

  -- Dialog text
  luna.graphics.setColor(1, 1, 1)
  luna.graphics.print(scene.text, 70, 300)

  -- Choices
  for i, choice in ipairs(scene.choices) do
    local cy = 420 + (i - 1) * 50
    if hover_choice == i then
      luna.graphics.setColor(0.3, 0.25, 0.45)
    else
      luna.graphics.setColor(0.2, 0.17, 0.3)
    end
    luna.graphics.rectangle("fill", 100, cy, 600, 40)
    luna.graphics.setColor(0.6, 0.5, 0.8)
    luna.graphics.rectangle("line", 100, cy, 600, 40)
    luna.graphics.setColor(1, 1, 1)
    luna.graphics.print(i .. ". " .. choice.text, 120, cy + 10)
  end
end
`}],fc=[{label:"Camera",description:"Smooth follow camera with zoom and shake",patternFile:"camera.lua",requireLine:'local Camera = require("libs.camera")'},{label:"Tilemap",description:"Tile-based map rendering and collision",patternFile:"grid.lua",requireLine:'local Grid = require("libs.grid")'},{label:"Physics",description:"Simple physics wrappers",patternFile:"component-system.lua",requireLine:'local ECS = require("libs.component-system")'},{label:"UI",description:"Basic UI components",patternFile:"stack.lua",requireLine:'local Stack = require("libs.stack")'},{label:"Particles",description:"Particle effects system",patternFile:"timer.lua",requireLine:'local Timer = require("libs.timer")'},{label:"Save/Load",description:"Game state serialization",patternFile:"class.lua",requireLine:'local Class = require("libs.class")'},{label:"Sound Manager",description:"Audio management with fade and crossfade",patternFile:"event-bus.lua",requireLine:'local EventBus = require("libs.event-bus")'},{label:"State Machine",description:"Finite state machine for game states",patternFile:"fsm.lua",requireLine:'local FSM = require("libs.fsm")'},{label:"Signal",description:"Pub-sub signal / observer pattern",patternFile:"signal.lua",requireLine:'local Signal = require("libs.signal")'},{label:"Tween",description:"Property tweening / animation engine",patternFile:"tween.lua",requireLine:'local Tween = require("libs.tween")'},{label:"Object Pool",description:"Recycling pool for bullets/particles/etc.",patternFile:"object-pool.lua",requireLine:'local Pool = require("libs.object-pool")'}],_n,Ae,On;function gc(n){$n(),On=Date.now()+n*6e4,Ae=H.window.createStatusBarItem(H.StatusBarAlignment.Right,200),Ae.show();let e=n*6e4,t=!1,o=!1,a=!1,s=()=>{if(!On||!Ae)return;let i=On-Date.now();if(i<=0){Ae.text="$(bell) TIME'S UP!",Ae.backgroundColor=new H.ThemeColor("statusBarItem.errorBackground"),H.window.showWarningMessage("Game Jam Timer: Time's up!"),$n();return}let r=i/e,l=Math.floor(i/6e4),d=Math.floor(i%6e4/1e3);Ae.text=`$(clock) ${l}:${String(d).padStart(2,"0")} remaining`,r<=.1&&!a?(a=!0,Ae.backgroundColor=new H.ThemeColor("statusBarItem.errorBackground"),H.window.showWarningMessage("Game Jam Timer: 10% time remaining!")):r<=.25&&!o?(o=!0,Ae.backgroundColor=new H.ThemeColor("statusBarItem.warningBackground"),H.window.showWarningMessage("Game Jam Timer: 25% time remaining!")):r<=.5&&!t&&(t=!0,H.window.showInformationMessage("Game Jam Timer: 50% time remaining."))};s(),_n=setInterval(s,1e3)}function $n(){_n&&(clearInterval(_n),_n=void 0),Ae&&(Ae.dispose(),Ae=void 0),On=void 0}function Li(n){n.subscriptions.push(H.commands.registerCommand("luna.gameJam.quickStart",async()=>{let e=await H.window.showQuickPick(mc.map(r=>({label:r.label,description:r.description,template:r})),{placeHolder:"Choose a game template"});if(!e)return;let t=await H.window.showInputBox({prompt:"Project name",placeHolder:"my-game",validateInput:r=>{if(!r.trim())return"Name cannot be empty";if(/[<>:"/\\|?*]/.test(r))return"Name contains invalid characters"}});if(!t)return;let o=await H.window.showOpenDialog({canSelectFolders:!0,canSelectFiles:!1,canSelectMany:!1,openLabel:"Select parent folder"});if(!o||o.length===0)return;let a=De.join(o[0].fsPath,t);if(se.existsSync(a)){H.window.showErrorMessage(`Folder already exists: ${a}`);return}let s=e.template;se.mkdirSync(a,{recursive:!0}),se.mkdirSync(De.join(a,"assets"),{recursive:!0}),se.mkdirSync(De.join(a,"libs"),{recursive:!0}),se.writeFileSync(De.join(a,"conf.lua"),s.confLua,"utf-8"),se.writeFileSync(De.join(a,"main.lua"),s.mainLua,"utf-8"),se.writeFileSync(De.join(a,"assets","README.md"),`# Assets

Place your game assets (images, sounds, fonts) in this folder.
`,"utf-8");let i=H.Uri.file(a);await H.commands.executeCommand("vscode.openFolder",i),H.window.showInformationMessage(`Created "${t}" with ${s.label} template!`)})),n.subscriptions.push(H.commands.registerCommand("luna.gameJam.addModule",async()=>{let e=await H.window.showQuickPick(fc.map(l=>({label:l.label,description:l.description,module:l})),{placeHolder:"Choose a module to add"});if(!e)return;let t=H.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!t){H.window.showErrorMessage("No workspace folder open.");return}let o=e.module,a=De.join(t,"libs");se.existsSync(a)||se.mkdirSync(a,{recursive:!0});let s=De.join(a,o.patternFile);if(se.existsSync(s)&&await H.window.showWarningMessage(`libs/${o.patternFile} already exists. Overwrite?`,"Yes","No")!=="Yes")return;let i=De.join(n.extensionPath,"data","patterns",o.patternFile);if(!se.existsSync(i)){H.window.showErrorMessage(`Pattern file not found: ${o.patternFile}`);return}se.copyFileSync(i,s);let r=De.join(t,"main.lua");if(se.existsSync(r)){let l=se.readFileSync(r,"utf-8");if(!l.includes(o.requireLine)){let d=l.split(`
`),c=0;for(let u=0;u<d.length;u++)d[u].startsWith("local ")&&d[u].includes("require")&&(c=u+1);d.splice(c,0,o.requireLine),se.writeFileSync(r,d.join(`
`),"utf-8")}}H.window.showInformationMessage(`Added ${o.label} module to libs/${o.patternFile}`)})),n.subscriptions.push(H.commands.registerCommand("luna.gameJam.timer",async()=>{let e=await H.window.showQuickPick([{label:"30 minutes",minutes:30},{label:"1 hour",minutes:60},{label:"2 hours",minutes:120},{label:"Custom...",minutes:-1},{label:"Stop timer",minutes:0}],{placeHolder:"Game Jam countdown duration"});if(!e)return;if(e.minutes===0){$n(),H.window.showInformationMessage("Game Jam Timer stopped.");return}let t=e.minutes;if(t<0){let o=await H.window.showInputBox({prompt:"Duration in minutes",placeHolder:"90",validateInput:a=>{let s=Number(a);if(isNaN(s)||s<=0)return"Enter a positive number"}});if(!o)return;t=Number(o)}gc(t),H.window.showInformationMessage(`Game Jam Timer started: ${t} minutes.`)})),n.subscriptions.push({dispose:$n})}var G=E(require("vscode")),rt=E(require("path")),ye=E(require("fs")),Ri=[{label:"Draw sprite",category:"Graphics",code:`local img = luna.graphics.newImage("assets/sprite.png")

function luna.draw()
  luna.graphics.draw(img, x, y)
end`},{label:"Animation loop",category:"Graphics",code:`local frames = {}
local current_frame = 1
local frame_timer = 0
local frame_duration = 0.1

function luna.load()
  for i = 1, 4 do
    frames[i] = luna.graphics.newImage("assets/frame" .. i .. ".png")
  end
end

function luna.update(dt)
  frame_timer = frame_timer + dt
  if frame_timer >= frame_duration then
    frame_timer = frame_timer - frame_duration
    current_frame = current_frame % #frames + 1
  end
end

function luna.draw()
  luna.graphics.draw(frames[current_frame], x, y)
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

function luna.update(dt)
  for i = #particles, 1, -1 do
    local p = particles[i]
    p.x = p.x + p.vx * dt
    p.y = p.y + p.vy * dt
    p.life = p.life - dt
    if p.life <= 0 then table.remove(particles, i) end
  end
end

function luna.draw()
  for _, p in ipairs(particles) do
    local a = p.life
    luna.graphics.setColor(1, 0.8, 0.2, a)
    luna.graphics.circle("fill", p.x, p.y, 3)
  end
  luna.graphics.setColor(1, 1, 1, 1)
end`},{label:"Screen shake",category:"Graphics",code:`local shake_timer = 0
local shake_intensity = 0
local shake_ox, shake_oy = 0, 0

local function startShake(duration, intensity)
  shake_timer = duration
  shake_intensity = intensity
end

function luna.update(dt)
  if shake_timer > 0 then
    shake_timer = shake_timer - dt
    shake_ox = (math.random() - 0.5) * 2 * shake_intensity
    shake_oy = (math.random() - 0.5) * 2 * shake_intensity
  else
    shake_ox, shake_oy = 0, 0
  end
end

function luna.draw()
  luna.graphics.push()
  luna.graphics.translate(shake_ox, shake_oy)
  -- Draw your game here
  luna.graphics.pop()
end`},{label:"WASD movement",category:"Input",code:`local player = { x = 400, y = 300, speed = 200 }

function luna.update(dt)
  if luna.keyboard.isDown("w") or luna.keyboard.isDown("up") then
    player.y = player.y - player.speed * dt
  end
  if luna.keyboard.isDown("s") or luna.keyboard.isDown("down") then
    player.y = player.y + player.speed * dt
  end
  if luna.keyboard.isDown("a") or luna.keyboard.isDown("left") then
    player.x = player.x - player.speed * dt
  end
  if luna.keyboard.isDown("d") or luna.keyboard.isDown("right") then
    player.x = player.x + player.speed * dt
  end
end`},{label:"Mouse aim",category:"Input",code:`local player = { x = 400, y = 300, angle = 0 }

function luna.update(dt)
  local mx, my = luna.mouse.getPosition()
  player.angle = math.atan2(my - player.y, mx - player.x)
end

function luna.draw()
  luna.graphics.push()
  luna.graphics.translate(player.x, player.y)
  luna.graphics.rotate(player.angle)
  luna.graphics.setColor(0.3, 0.7, 1)
  luna.graphics.rectangle("fill", -16, -8, 32, 16)
  luna.graphics.pop()
end`},{label:"Gamepad support",category:"Input",code:`local player = { x = 400, y = 300, speed = 200 }

function luna.update(dt)
  local axes = luna.gamepad.getAxes(1)
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

function luna.gamepadpressed(id, button)
  if button == "a" then
    -- Jump or action
  end
end`},{label:"Touch controls",category:"Input",code:`local touches = {}

function luna.touchpressed(id, x, y, dx, dy, pressure)
  touches[id] = { x = x, y = y, startX = x, startY = y }
end

function luna.touchmoved(id, x, y, dx, dy, pressure)
  if touches[id] then
    touches[id].x = x
    touches[id].y = y
  end
end

function luna.touchreleased(id, x, y, dx, dy, pressure)
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

function luna.update(dt)
  -- Horizontal
  if luna.keyboard.isDown("left") then player.vx = -moveSpeed
  elseif luna.keyboard.isDown("right") then player.vx = moveSpeed
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

function luna.keypressed(key)
  if key == "space" and player.onGround then
    player.vy = jumpForce
  end
end`},{label:"Top-down movement",category:"Physics",code:`local player = { x = 400, y = 300, vx = 0, vy = 0, speed = 200, friction = 8 }

function luna.update(dt)
  local ix, iy = 0, 0
  if luna.keyboard.isDown("w") then iy = iy - 1 end
  if luna.keyboard.isDown("s") then iy = iy + 1 end
  if luna.keyboard.isDown("a") then ix = ix - 1 end
  if luna.keyboard.isDown("d") then ix = ix + 1 end

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

function luna.update(dt)
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

function luna.draw()
  luna.graphics.setColor(1, 1, 0)
  for _, b in ipairs(bullets) do
    luna.graphics.circle("fill", b.x, b.y, 3)
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
  luna.graphics.setColor(0.2, 0.2, 0.2)
  luna.graphics.rectangle("fill", x, y, w, h)

  -- Fill
  local color_r = (1 - pct) * 2
  local color_g = pct * 2
  luna.graphics.setColor(math.min(color_r, 1), math.min(color_g, 1), 0)
  luna.graphics.rectangle("fill", x, y, w * pct, h)

  -- Border
  luna.graphics.setColor(0.8, 0.8, 0.8)
  luna.graphics.rectangle("line", x, y, w, h)

  -- Text
  luna.graphics.setColor(1, 1, 1)
  luna.graphics.print(hp.current .. "/" .. hp.max, x + 4, y + 2)
end`},{label:"Dialog box",category:"UI",code:`local dialog = { active = false, text = "", speaker = "", char_idx = 0, timer = 0, speed = 0.03 }

local function showDialog(speaker, text)
  dialog.active = true
  dialog.speaker = speaker
  dialog.text = text
  dialog.char_idx = 0
  dialog.timer = 0
end

function luna.update(dt)
  if not dialog.active then return end
  dialog.timer = dialog.timer + dt
  if dialog.timer >= dialog.speed then
    dialog.timer = dialog.timer - dialog.speed
    dialog.char_idx = math.min(dialog.char_idx + 1, #dialog.text)
  end
end

function luna.keypressed(key)
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
  luna.graphics.setColor(0, 0, 0, 0.85)
  luna.graphics.rectangle("fill", 50, 400, 700, 150)
  luna.graphics.setColor(0.7, 0.7, 0.9)
  luna.graphics.rectangle("line", 50, 400, 700, 150)
  luna.graphics.setColor(0.9, 0.8, 1)
  luna.graphics.print(dialog.speaker, 70, 410)
  luna.graphics.setColor(1, 1, 1)
  luna.graphics.print(string.sub(dialog.text, 1, dialog.char_idx), 70, 440)
end`},{label:"Menu system",category:"UI",code:`local menu = {
  items = { "Start Game", "Options", "Quit" },
  selected = 1,
}

function luna.keypressed(key)
  if key == "up" then
    menu.selected = menu.selected - 1
    if menu.selected < 1 then menu.selected = #menu.items end
  elseif key == "down" then
    menu.selected = menu.selected + 1
    if menu.selected > #menu.items then menu.selected = 1 end
  elseif key == "return" then
    if menu.items[menu.selected] == "Quit" then
      luna.event.quit()
    end
  end
end

function luna.draw()
  luna.graphics.setBackgroundColor(0.1, 0.1, 0.15)
  for i, item in ipairs(menu.items) do
    local y = 200 + (i - 1) * 50
    if i == menu.selected then
      luna.graphics.setColor(1, 0.9, 0.2)
      luna.graphics.print("> " .. item, 300, y)
    else
      luna.graphics.setColor(0.7, 0.7, 0.7)
      luna.graphics.print("  " .. item, 300, y)
    end
  end
end`},{label:"Minimap",category:"UI",code:`local minimap = { x = 620, y = 10, w = 160, h = 120, scale = 0.1 }

local function drawMinimap(world_objects, player, world_w, world_h)
  -- Background
  luna.graphics.setColor(0, 0, 0, 0.6)
  luna.graphics.rectangle("fill", minimap.x, minimap.y, minimap.w, minimap.h)
  luna.graphics.setColor(0.5, 0.5, 0.5)
  luna.graphics.rectangle("line", minimap.x, minimap.y, minimap.w, minimap.h)

  local sx = minimap.w / world_w
  local sy = minimap.h / world_h

  -- Objects
  luna.graphics.setColor(0.4, 0.4, 0.6)
  for _, obj in ipairs(world_objects) do
    luna.graphics.rectangle("fill",
      minimap.x + obj.x * sx, minimap.y + obj.y * sy,
      math.max(obj.w * sx, 2), math.max(obj.h * sy, 2))
  end

  -- Player dot
  luna.graphics.setColor(0, 1, 0)
  luna.graphics.circle("fill", minimap.x + player.x * sx, minimap.y + player.y * sy, 3)
end`},{label:"Music manager",category:"Audio",code:`local music = { current = nil, volume = 0.7 }

local function playMusic(file)
  if music.current then
    luna.audio.stop(music.current)
  end
  music.current = luna.audio.newSource(file, "stream")
  luna.audio.setVolume(music.current, music.volume)
  luna.audio.play(music.current)
end

local function setMusicVolume(vol)
  music.volume = math.max(0, math.min(1, vol))
  if music.current then
    luna.audio.setVolume(music.current, music.volume)
  end
end

local function stopMusic()
  if music.current then
    luna.audio.stop(music.current)
    music.current = nil
  end
end`},{label:"SFX player",category:"Audio",code:`local sfx = {}

local function loadSFX(name, file)
  sfx[name] = luna.audio.newSource(file, "static")
end

local function playSFX(name, volume, pitch)
  local s = sfx[name]
  if s then
    local clone = luna.audio.clone(s)
    luna.audio.setVolume(clone, volume or 1.0)
    luna.audio.setPitch(clone, pitch or 1.0)
    luna.audio.play(clone)
  end
end

-- Usage:
-- loadSFX("jump", "assets/sounds/jump.wav")
-- playSFX("jump", 0.8)`},{label:"Volume control",category:"Audio",code:`local master_volume = 1.0

function luna.keypressed(key)
  if key == "+" or key == "=" then
    master_volume = math.min(master_volume + 0.1, 1.0)
    luna.audio.setMasterVolume(master_volume)
  elseif key == "-" then
    master_volume = math.max(master_volume - 0.1, 0.0)
    luna.audio.setMasterVolume(master_volume)
  elseif key == "m" then
    if master_volume > 0 then
      master_volume = 0
    else
      master_volume = 1.0
    end
    luna.audio.setMasterVolume(master_volume)
  end
end`},{label:"Crossfade",category:"Audio",code:`local crossfade = { from = nil, to = nil, progress = 0, duration = 2.0, active = false }

local function crossfadeTo(newMusic, duration)
  crossfade.from = crossfade.to or nil
  crossfade.to = luna.audio.newSource(newMusic, "stream")
  luna.audio.setVolume(crossfade.to, 0)
  luna.audio.play(crossfade.to)
  crossfade.progress = 0
  crossfade.duration = duration or 2.0
  crossfade.active = true
end

function luna.update(dt)
  if not crossfade.active then return end
  crossfade.progress = crossfade.progress + dt / crossfade.duration
  if crossfade.progress >= 1 then
    crossfade.progress = 1
    crossfade.active = false
    if crossfade.from then luna.audio.stop(crossfade.from) end
  end
  if crossfade.from then luna.audio.setVolume(crossfade.from, 1 - crossfade.progress) end
  if crossfade.to then luna.audio.setVolume(crossfade.to, crossfade.progress) end
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
  luna.filesystem.write(filename, "return " .. serialize(data))
end

local function loadGame(filename)
  filename = filename or "save.lua"
  if not luna.filesystem.exists(filename) then return nil end
  local content = luna.filesystem.read(filename)
  local fn = load(content)
  return fn and fn() or nil
end`},{label:"Config file",category:"Data",code:`local config = {
  music_volume = 0.7,
  sfx_volume = 1.0,
  fullscreen = false,
  language = "en",
}

local function loadConfig()
  if luna.filesystem.exists("config.lua") then
    local content = luna.filesystem.read("config.lua")
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
  luna.filesystem.write("config.lua", table.concat(lines, "\\n"))
end`},{label:"High scores",category:"Data",code:`local scores = {}
local MAX_SCORES = 10

local function loadScores()
  if luna.filesystem.exists("scores.lua") then
    local content = luna.filesystem.read("scores.lua")
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
  luna.filesystem.write("scores.lua", table.concat(lines, "\\n"))
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
end`}];function hc(){let n=new Set;for(let e of Ri)n.add(e.category);return[...n].sort()}function vc(n){let e=rt.join(n,"data","patterns");return ye.existsSync(e)?ye.readdirSync(e).filter(t=>t.endsWith(".lua")).map(t=>({name:t.replace(".lua",""),fullPath:rt.join(e,t)})):[]}function Mi(n){n.subscriptions.push(G.commands.registerCommand("luna.library.browse",async()=>{let e=vc(n.extensionPath);if(e.length===0){G.window.showInformationMessage("No patterns found in data/patterns/.");return}let t=await G.window.showQuickPick(e.map(a=>({label:a.name,description:`data/patterns/${a.name}.lua`,fullPath:a.fullPath})),{placeHolder:"Browse Luna2D patterns"});if(!t)return;let o=await G.window.showQuickPick([{label:"Preview",description:"Open the pattern file in a new tab"},{label:"Copy to project",description:"Copy to libs/ folder in your project"}],{placeHolder:`${t.label}: What would you like to do?`});if(o)if(o.label==="Preview"){let a=await G.workspace.openTextDocument(t.fullPath);await G.window.showTextDocument(a,{preview:!0})}else{let a=G.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!a){G.window.showErrorMessage("No workspace folder open.");return}let s=rt.join(a,"libs");ye.existsSync(s)||ye.mkdirSync(s,{recursive:!0});let i=rt.join(s,`${t.label}.lua`);if(ye.existsSync(i)&&await G.window.showWarningMessage(`libs/${t.label}.lua already exists. Overwrite?`,"Yes","No")!=="Yes")return;ye.copyFileSync(t.fullPath,i),G.window.showInformationMessage(`Copied ${t.label} to libs/${t.label}.lua`)}})),n.subscriptions.push(G.commands.registerCommand("luna.library.insertSnippet",async()=>{let e=hc(),t=await G.window.showQuickPick(e.map(i=>({label:i})),{placeHolder:"Choose snippet category"});if(!t)return;let o=Ri.filter(i=>i.category===t.label),a=await G.window.showQuickPick(o.map(i=>({label:i.label,snippet:i})),{placeHolder:`${t.label} snippets`});if(!a)return;let s=G.window.activeTextEditor;if(!s){let i=await G.workspace.openTextDocument({language:"lua",content:a.snippet.code+`
`});await G.window.showTextDocument(i);return}await s.edit(i=>{i.insert(s.selection.active,a.snippet.code+`
`)})})),n.subscriptions.push(G.commands.registerCommand("luna.library.newPattern",async()=>{let e=G.window.activeTextEditor;if(!e||e.selection.isEmpty){G.window.showWarningMessage("Select some Lua code first to create a pattern from it.");return}let t=e.document.getText(e.selection),o=await G.window.showInputBox({prompt:"Pattern name",placeHolder:"my-pattern",validateInput:d=>{if(!d.trim())return"Name cannot be empty";if(/[<>:"/\\|?*\s]/.test(d))return"Name should be a simple identifier (use dashes, no spaces)"}});if(!o)return;let a=await G.window.showInputBox({prompt:"Category",placeHolder:"e.g. gameplay, ui, utility"}),s=await G.window.showInputBox({prompt:"Brief description",placeHolder:"What does this pattern do?"}),i=[`--- ${o} pattern for Luna2D.`,`--- ${s??"Custom pattern."}`,"---",`--- Category: ${a??"general"}`,"---",""].join(`
`),r=rt.join(n.extensionPath,"data","patterns");ye.existsSync(r)||ye.mkdirSync(r,{recursive:!0});let l=rt.join(r,`${o}.lua`);ye.existsSync(l)&&await G.window.showWarningMessage(`Pattern "${o}" already exists. Overwrite?`,"Yes","No")!=="Yes"||(ye.writeFileSync(l,i+t+`
`,"utf-8"),G.window.showInformationMessage(`Pattern "${o}" saved to data/patterns/${o}.lua`))}))}var Z=E(require("vscode")),be=E(require("path")),ue=E(require("fs")),Di=[{label:"Agents",description:"AI agent definitions for game dev roles",srcDir:"agents"},{label:"Skills",description:"Domain skill packages for AI assistants",srcDir:"skills"},{label:"Prompts",description:"Task-driven playbooks for game development",srcDir:"prompts"},{label:"Instructions",description:"Contextual coding instructions",srcDir:"instructions"}],yc=[{label:"Minimal",description:"Bare-bones starter with essential callbacks",dir:"minimal"},{label:"Game Loop",description:"Structured loop with class system and event bus",dir:"game-loop"},{label:"Platformer",description:"Side-scrolling platformer with jump physics",dir:"platformer"},{label:"Top-Down RPG",description:"8-dir movement, scene management, HUD",dir:"top-down-rpg"},{label:"Shoot 'em Up",description:"Vertical scrolling shooter with bullet pool",dir:"shoot-em-up"},{label:"Puzzle",description:"Grid-based puzzle with click interaction",dir:"puzzle"},{label:"Roguelike",description:"Turn-based with BSP dungeon generation",dir:"roguelike"},{label:"Visual Novel",description:"Typewriter dialog and scene progression",dir:"visual-novel"},{label:"Arcade",description:"Simple arcade loop with score and lives",dir:"arcade"},{label:"Tower Defense",description:"Path-following enemies, placeable towers, waves",dir:"tower-defense"},{label:"Game Jam",description:"Minimal fast-start template for game jams",dir:"game-jam"},{label:"Demo Scene",description:"Scene switcher with multiple demo scenes",dir:"demo-scene"}];function Fo(n){return be.join(n.extensionPath,"cag","game-dev")}function Bo(){return Z.workspace.workspaceFolders?.[0]?.uri.fsPath}function Wn(n,e){ue.existsSync(e)||ue.mkdirSync(e,{recursive:!0});for(let t of ue.readdirSync(n,{withFileTypes:!0})){let o=be.join(n,t.name),a=be.join(e,t.name);t.isDirectory()?Wn(o,a):ue.copyFileSync(o,a)}}function Hn(n){if(!ue.existsSync(n))return 0;let e=0;for(let t of ue.readdirSync(n,{withFileTypes:!0}))t.isDirectory()?e+=Hn(be.join(n,t.name)):e++;return e}async function bc(n){let e=Bo();if(!e){Z.window.showErrorMessage("No workspace folder open.");return}let t=Fo(n);if(!ue.existsSync(t)){Z.window.showErrorMessage("Game Dev CAG files not found in extension bundle.");return}let o=await Z.window.showQuickPick(Di.map(i=>({label:i.label,description:i.description,picked:!0,srcDir:i.srcDir})),{canPickMany:!0,placeHolder:"Select CAG components to deploy",title:"Deploy Game Dev AI Layer"});if(!o||o.length===0)return;let a=be.join(e,".github"),s=0;for(let i of o){let r=be.join(t,i.srcDir);if(!ue.existsSync(r))continue;let l=be.join(a,i.srcDir);Wn(r,l),s+=Hn(r)}Z.window.showInformationMessage(`Deployed ${s} file(s) to .github/ (${o.map(i=>i.label).join(", ")})`)}async function xc(n){let e=Bo();if(!e){Z.window.showErrorMessage("No workspace folder open.");return}let t=Fo(n),o=be.join(t,"templates");if(!ue.existsSync(o)){Z.window.showErrorMessage("Game Dev templates not found in extension bundle.");return}let a=await Z.window.showQuickPick(yc.map(d=>({label:d.label,description:d.description,dir:d.dir})),{placeHolder:"Select a game template",title:"Scaffold Project from Template"});if(!a)return;let s=be.join(o,a.dir);if(!ue.existsSync(s)){Z.window.showErrorMessage(`Template "${a.label}" not found.`);return}let i=be.join(e,"main.lua");if(ue.existsSync(i)&&await Z.window.showWarningMessage("main.lua already exists in workspace. Overwrite project files?","Yes","No")!=="Yes")return;Wn(s,e);let r=Hn(s);Z.window.showInformationMessage(`Scaffolded "${a.label}" template (${r} files)`);let l=be.join(e,"main.lua");if(ue.existsSync(l)){let d=await Z.workspace.openTextDocument(l);await Z.window.showTextDocument(d)}}async function wc(n){let e=Bo();if(!e){Z.window.showErrorMessage("No workspace folder open.");return}let t=be.join(e,".github");if(!ue.existsSync(t)){Z.window.showInformationMessage("No .github/ folder found. Use 'Deploy Game Dev AI Layer' first.");return}if(await Z.window.showWarningMessage("This will overwrite existing CAG files in .github/ with the latest from the extension. Continue?","Yes","No")!=="Yes")return;let a=Fo(n),s=0;for(let i of Di){let r=be.join(a,i.srcDir);if(!ue.existsSync(r))continue;let l=be.join(t,i.srcDir);Wn(r,l),s+=Hn(r)}Z.window.showInformationMessage(`Updated ${s} CAG file(s) in .github/`)}function Ai(n){n.subscriptions.push(Z.commands.registerCommand("luna.cag.deploy",()=>bc(n)),Z.commands.registerCommand("luna.cag.scaffold",()=>xc(n)),Z.commands.registerCommand("luna.cag.updateGameDev",()=>wc(n)))}var dt=E(require("vscode"));var O=E(Xi()),Ji=E(require("net")),le=E(require("path")),Qi=require("child_process"),Nt=E(require("fs")),Gi=1,Ui=3,Ki=500,ma=8172,to=class extends O.LoggingDebugSession{socket=null;engineProcess=null;breakpoints=new Map;variablesMap=new Map;nextVariableRef=1;pendingRequests=new Map;nextRequestId=1;receiveBuffer="";gamePath="";debugPort=ma;loadedSources=[];constructor(){super("luna-debug.log"),this.setDebuggerLinesStartAt1(!0),this.setDebuggerColumnsStartAt1(!0)}initializeRequest(e,t){e.body={supportsConfigurationDoneRequest:!0,supportsFunctionBreakpoints:!1,supportsConditionalBreakpoints:!0,supportsHitConditionalBreakpoints:!0,supportsEvaluateForHovers:!0,supportsStepBack:!1,supportsSetVariable:!0,supportsRestartFrame:!1,supportsGotoTargetsRequest:!1,supportsStepInTargetsRequest:!1,supportsCompletionsRequest:!0,supportsModulesRequest:!1,supportsExceptionOptions:!1,supportsValueFormattingOptions:!1,supportsExceptionInfoRequest:!1,supportTerminateDebuggee:!0,supportsDelayedStackTraceLoading:!1,supportsLoadedSourcesRequest:!0,supportsLogPoints:!0,supportsTerminateThreadsRequest:!1,supportsSetExpression:!1,supportsTerminateRequest:!0,supportsDataBreakpoints:!1,supportsReadMemoryRequest:!1,supportsDisassembleRequest:!1,supportsBreakpointLocationsRequest:!0,supportsClipboardContext:!1,supportsExceptionFilterOptions:!1,supportsSteppingGranularity:!1,supportsInstructionBreakpoints:!1},this.sendResponse(e),this.sendEvent(new O.InitializedEvent)}async launchRequest(e,t){this.gamePath=t.program,this.debugPort=t.debugPort??ma;let o=t.stopOnEntry??!1,a=this.findEngineBinary(t.enginePath);if(!a){this.sendErrorResponse(e,1001,"Luna2D engine not found. Set 'luna.lunaPath' in settings or ensure luna2d is on PATH.");return}let s=[`--debug-port=${this.debugPort}`,this.gamePath,...t.args??[]];this.log(`Launching: ${a} ${s.join(" ")}`);try{this.engineProcess=(0,Qi.spawn)(a,s,{cwd:le.dirname(this.gamePath),stdio:["ignore","pipe","pipe"]}),this.engineProcess.stdout?.on("data",i=>{this.sendEvent(new O.OutputEvent(i.toString(),"stdout"))}),this.engineProcess.stderr?.on("data",i=>{this.sendEvent(new O.OutputEvent(i.toString(),"stderr"))}),this.engineProcess.on("exit",i=>{this.log(`Engine exited with code ${i}`),this.sendEvent(new O.TerminatedEvent)}),this.engineProcess.on("error",i=>{this.sendEvent(new O.OutputEvent(`Engine error: ${i.message}
`,"stderr")),this.sendEvent(new O.TerminatedEvent)}),await this.connectToEngine(this.debugPort),o&&await this.sendToEngine("pause"),this.sendResponse(e)}catch(i){let r=i instanceof Error?i.message:String(i);this.sendErrorResponse(e,1002,`Failed to launch: ${r}`)}}async attachRequest(e,t){this.debugPort=t.debugPort??ma;try{await this.connectToEngine(this.debugPort),this.sendResponse(e)}catch(o){let a=o instanceof Error?o.message:String(o);this.sendErrorResponse(e,1003,`Failed to attach: ${a}`)}}configurationDoneRequest(e,t){this.sendResponse(e)}async disconnectRequest(e,t){if(t.terminateDebuggee!==!1&&this.engineProcess)try{await this.sendToEngine("terminate")}catch{}this.cleanup(),this.sendResponse(e)}async terminateRequest(e,t){try{await this.sendToEngine("terminate")}catch{}this.cleanup(),this.sendResponse(e)}async setBreakPointsRequest(e,t){let o=t.source.path??"",a=t.lines??[],s=this.toRelativePath(o);try{let i=await this.sendToEngine("setBreakpoints",{file:s,lines:a}),r=a.map((l,d)=>{let c=new O.Breakpoint(!0,l);if(c.id=d+1,i.body&&Array.isArray(i.body.breakpoints)){let u=i.body.breakpoints[d];u&&(c.verified=u.verified,u.line!==void 0&&(c.line=u.line))}return c});this.breakpoints.set(o,r),this.loadedSources.find(l=>l.path===o)||this.loadedSources.push(new O.Source(le.basename(o),o)),e.body={breakpoints:r}}catch{let i=a.map((r,l)=>{let d=new O.Breakpoint(!1,r);return d.id=l+1,d});this.breakpoints.set(o,i),e.body={breakpoints:i}}this.sendResponse(e)}breakpointLocationsRequest(e,t){let o=t.line,a=t.endLine??o,s=[];for(let i=o;i<=a;i++)s.push({line:i});e.body={breakpoints:s},this.sendResponse(e)}threadsRequest(e){e.body={threads:[new O.Thread(Gi,"Luna Main")]},this.sendResponse(e)}async stackTraceRequest(e,t){try{let o=await this.sendToEngine("stackTrace"),a=[];if(o.body&&Array.isArray(o.body.frames)){let s=o.body.frames,i=t.startFrame??0,r=t.levels??s.length,l=Math.min(i+r,s.length);for(let d=i;d<l;d++){let c=s[d],u=this.toAbsolutePath(c.file),h=new O.Source(le.basename(c.file),u);a.push(new O.StackFrame(d,c.name,h,c.line,c.column??1))}}e.body={stackFrames:a,totalFrames:o.body?.frames?.length??a.length}}catch{e.body={stackFrames:[],totalFrames:0}}this.sendResponse(e)}async scopesRequest(e,t){try{let o=await this.sendToEngine("scopes",{frameId:t.frameId}),a=[];if(o.body&&Array.isArray(o.body.scopes))for(let s of o.body.scopes)a.push(new O.Scope(s.name,s.variablesReference,s.expensive??!1));else{let s=this.nextVariableRef++,i=this.nextVariableRef++;a.push(new O.Scope("Locals",s,!1)),a.push(new O.Scope("Upvalues",i,!1))}e.body={scopes:a}}catch{e.body={scopes:[]}}this.sendResponse(e)}async variablesRequest(e,t){try{let o=this.variablesMap.get(t.variablesReference);if(o){e.body={variables:o},this.sendResponse(e);return}let a=await this.sendToEngine("variables",{variablesReference:t.variablesReference}),s=[];if(a.body&&Array.isArray(a.body.variables))for(let i of a.body.variables){let r=0;if(i.children&&i.children.length>0){r=this.nextVariableRef++;let l=i.children.map(d=>{let c=0;return d.children&&d.children.length>0&&(c=this.nextVariableRef++,this.variablesMap.set(c,d.children.map(u=>new O.Variable(u.name,u.value,0)))),new O.Variable(d.name,d.value,c)});this.variablesMap.set(r,l)}else i.variablesReference&&(r=i.variablesReference);s.push(new O.Variable(i.name,i.value,r))}this.variablesMap.set(t.variablesReference,s),e.body={variables:s}}catch{e.body={variables:[]}}this.sendResponse(e)}async setVariableRequest(e,t){try{let o=await this.sendToEngine("setVariable",{variablesReference:t.variablesReference,name:t.name,value:t.value});e.body={value:o.body?.value??t.value},this.variablesMap.delete(t.variablesReference)}catch(o){let a=o instanceof Error?o.message:String(o);this.sendErrorResponse(e,1010,`Failed to set variable: ${a}`);return}this.sendResponse(e)}async continueRequest(e,t){this.variablesMap.clear();try{await this.sendToEngine("continue")}catch{}e.body={allThreadsContinued:!0},this.sendResponse(e)}async nextRequest(e,t){this.variablesMap.clear();try{await this.sendToEngine("next")}catch{}this.sendResponse(e)}async stepInRequest(e,t){this.variablesMap.clear();try{await this.sendToEngine("stepIn")}catch{}this.sendResponse(e)}async stepOutRequest(e,t){this.variablesMap.clear();try{await this.sendToEngine("stepOut")}catch{}this.sendResponse(e)}async pauseRequest(e,t){try{await this.sendToEngine("pause")}catch{}this.sendResponse(e)}async evaluateRequest(e,t){try{let o=await this.sendToEngine("evaluate",{expression:t.expression,frameId:t.frameId??0,context:t.context}),a=o.body?.result??"nil",s=o.body?.variablesReference??0;e.body={result:a,variablesReference:s}}catch(o){let a=o instanceof Error?o.message:String(o);e.body={result:`Error: ${a}`,variablesReference:0}}this.sendResponse(e)}completionsRequest(e,t){let o=t.text,a=[];if(o.startsWith("luna.")){let i=["graphics","audio","timer","keyboard","mouse","gamepad","touch","window","filesystem","math","physics","system","data","event","thread","scene","entity","particle"];for(let r of i)r.startsWith(o.slice(5))&&a.push(new O.CompletionItem(r,9))}let s=["local","function","if","then","else","elseif","end","for","while","do","repeat","until","return","break","in","not","and","or","true","false","nil"];for(let i of s)i.startsWith(o)&&a.push(new O.CompletionItem(i,14));e.body={targets:a},this.sendResponse(e)}loadedSourcesRequest(e){e.body={sources:this.loadedSources},this.sendResponse(e)}connectToEngine(e){return new Promise((t,o)=>{let a=0,s=()=>{let i=new Ji.Socket,r=l=>{i.destroy(),a++,a<Ui?(this.log(`Connection attempt ${a} failed, retrying in ${Ki}ms...`),setTimeout(s,Ki)):o(new Error(`Failed to connect to Luna2D engine on port ${e} after ${Ui} attempts: ${l.message}`))};i.once("error",r),i.connect(e,"127.0.0.1",()=>{i.removeListener("error",r),this.socket=i,this.receiveBuffer="",this.log(`Connected to Luna2D engine on port ${e}`),i.on("data",l=>{this.onSocketData(l)}),i.on("error",l=>{this.sendEvent(new O.OutputEvent(`Engine connection error: ${l.message}
`,"stderr")),this.cleanup(),this.sendEvent(new O.TerminatedEvent)}),i.on("close",()=>{this.log("Engine connection closed"),this.cleanup(),this.sendEvent(new O.TerminatedEvent)}),t()})};s()})}sendToEngine(e,t){return new Promise((o,a)=>{if(!this.socket||this.socket.destroyed){a(new Error("Not connected to engine"));return}let s=this.nextRequestId++,i=JSON.stringify({id:s,command:e,args:t??{}}),r=`Content-Length: ${Buffer.byteLength(i)}\r
\r
${i}`;this.pendingRequests.set(s,{resolve:o,reject:a});let l=setTimeout(()=>{this.pendingRequests.delete(s),a(new Error(`Request '${e}' timed out`))},1e4),d=this.pendingRequests.get(s);this.pendingRequests.set(s,{resolve:c=>{clearTimeout(l),d.resolve(c)},reject:c=>{clearTimeout(l),d.reject(c)}});try{this.socket.write(r)}catch(c){clearTimeout(l),this.pendingRequests.delete(s),a(c instanceof Error?c:new Error(String(c)))}})}onSocketData(e){for(this.receiveBuffer+=e.toString("utf-8");;){let t=this.receiveBuffer.indexOf(`\r
\r
`);if(t===-1)break;let o=this.receiveBuffer.substring(0,t),a=/Content-Length:\s*(\d+)/i.exec(o);if(!a){this.receiveBuffer=this.receiveBuffer.substring(t+4);continue}let s=parseInt(a[1],10),i=t+4;if(this.receiveBuffer.length<i+s)break;let r=this.receiveBuffer.substring(i,i+s);this.receiveBuffer=this.receiveBuffer.substring(i+s);try{let l=JSON.parse(r);"event"in l?this.handleEngineEvent(l):"id"in l&&this.handleEngineResponse(l)}catch{this.log(`Failed to parse engine message: ${r}`)}}}handleEngineEvent(e){switch(e.event){case"stopped":{let t=new O.StoppedEvent(e.reason??"breakpoint",Gi);this.variablesMap.clear(),this.sendEvent(t);break}case"output":{this.sendEvent(new O.OutputEvent(e.output??"",e.category??"console"));break}case"terminated":{this.sendEvent(new O.TerminatedEvent);break}case"breakpointValidated":{if(e.id!==void 0&&e.verified!==void 0)for(let[,t]of this.breakpoints)for(let o of t)o.id===e.id&&(o.verified=e.verified);break}default:this.log(`Unknown engine event: ${e.event}`)}}handleEngineResponse(e){let t=this.pendingRequests.get(e.id);t&&(this.pendingRequests.delete(e.id),e.success?t.resolve(e):t.reject(new Error(e.error??"Unknown engine error")))}findEngineBinary(e){if(e&&Nt.existsSync(e))return e;let t=require("vscode").workspace.getConfiguration("luna").get("lunaPath","");if(t&&Nt.existsSync(t))return t;let o=process.env.USERPROFILE??process.env.HOME??"",a=[le.join(o,"bin","luna.exe"),le.join(o,"bin","luna2d.exe"),le.join(o,"bin","luna"),le.join(o,"bin","luna2d")];for(let r of a)if(Nt.existsSync(r))return r;let s=process.platform==="win32"?"luna.exe":"luna2d",i=(process.env.PATH??"").split(le.delimiter);for(let r of i){let l=le.join(r,s);if(Nt.existsSync(l))return l}return null}toRelativePath(e){if(this.gamePath&&e.startsWith(this.gamePath)){let t=e.substring(this.gamePath.length);return(t.startsWith(le.sep)||t.startsWith("/"))&&(t=t.substring(1)),t.replace(/\\/g,"/")}return le.basename(e)}toAbsolutePath(e){return le.isAbsolute(e)?e:le.join(this.gamePath,e)}cleanup(){if(this.socket&&(this.socket.removeAllListeners(),this.socket.destroy(),this.socket=null),this.engineProcess){try{this.engineProcess.kill()}catch{}this.engineProcess=null}for(let[,e]of this.pendingRequests)e.reject(new Error("Debug session ended"));this.pendingRequests.clear(),this.variablesMap.clear()}log(e){this.sendEvent(new O.OutputEvent(`[Luna Debug] ${e}
`,"console"))}};var fa=class{createDebugAdapterDescriptor(e,t){return new dt.DebugAdapterInlineImplementation(new to)}},ga=class{resolveDebugConfiguration(e,t,o){return t.type||(t.type="luna"),t.request||(t.request="launch"),t.name||(t.name="Luna2D: Debug Game"),t.program||(t.program="${workspaceFolder}"),t.luaVersion||(t.luaVersion=dt.workspace.getConfiguration("luna").get("luaVersion","luajit")),t.stopOnEntry===void 0&&(t.stopOnEntry=!1),t.debugPort||(t.debugPort=8172),t}provideDebugConfigurations(e){return[{type:"luna",request:"launch",name:"Luna2D: Debug Game",program:"${workspaceFolder}",stopOnEntry:!1},{type:"luna",request:"attach",name:"Luna2D: Attach to Running",debugPort:8172}]}};function Zi(n){let e=new fa,t=new ga;n.subscriptions.push(dt.debug.registerDebugAdapterDescriptorFactory("luna",e),dt.debug.registerDebugConfigurationProvider("luna",t))}var zt,Oe,no,ee,fe;function Ac(n){Oe=new Wt,no=new Ht,ee=new jt,fe=new zn,n.subscriptions.push(Oe,no,fe),ee.load(n.extensionPath).catch(r=>{console.error("Failed to load Luna API data:",r)}),Oe.onStatusChange(r=>{r?no.setRunning():no.setStopped()});let e=new Yt,t=new Vt,o=new Xt;n.subscriptions.push(C.window.registerTreeDataProvider("luna.projectTools",e),C.window.registerTreeDataProvider("luna.devTools",t),C.window.registerTreeDataProvider("luna.aiCopilot",o)),Aa(n,ee),Na(n,ee),za(n,ee),$a(n,ee),Wa(n,ee),ja(n,ee),Va(n,ee),Xa(n,ee),Ua(n,ee),Ka(n,ee),Ja(n,ee),ns(n,ee),ss(n,ee),is(n),rs(n),As(n,ee),cs(n,ee),ys(n,ee),ws(n,ee),Ls(n,ee);let a=new Jt;n.subscriptions.push(C.window.registerTreeDataProvider("luna.assetExplorer",a)),M(n,"luna.runGame",()=>To(Oe)),M(n,"luna.stopGame",()=>ei(Oe)),M(n,"luna.runWithArgs",()=>ti(Oe)),M(n,"luna.runExample",()=>nn(Oe)),M(n,"luna.test.all",()=>ii());let s=["ai","audio","cardgame","combat","compute","config","crafting","data","dataframe","dialog","engine","entity","event","filesystem","graph","graphics","graphics_ext","image","input","inventory","math","math_ext","minimap","modding","particle","pathfinding","physics","postfx","quest","resource","savegame","scene","sound","stats","thread","tilemap","timer"];for(let r of s)M(n,`luna.test.rust.${r}`,()=>ri(r));if(M(n,"luna.test.lua.all",()=>li()),M(n,"luna.test.lua.golden",()=>di()),Ei(n),M(n,"luna.scaffold.project",()=>ai()),M(n,"luna.scaffold.file",()=>si()),M(n,"luna.extractToModuleFile",async(...r)=>{let l=r[0],d=r[1];if(!l||!d)return;let c=await C.window.showInputBox({prompt:"New module file name (without .lua)",placeHolder:"my_module",validateInput:m=>/^[a-z_][a-z0-9_]*$/i.test(m)?null:"Use letters, digits, underscores"});if(!c)return;let h=(await C.workspace.openTextDocument(l)).getText(d),p=l.fsPath.replace(/[/\\][^/\\]+$/,""),f=C.Uri.file(`${p}/${c}.lua`),g=new C.WorkspaceEdit;g.createFile(f,{ignoreIfExists:!0}),g.insert(f,new C.Position(0,0),`-- ${c}.lua
local M = {}

${h}

return M
`),g.replace(l,d,`require("${c}")`),await C.workspace.applyEdit(g),await C.window.showTextDocument(f)}),M(n,"luna.package.zip",()=>ci()),M(n,"luna.package.windows",()=>ui()),M(n,"luna.package.linux",()=>pi()),n.subscriptions.push(...fi(n)),M(n,"luna.assets.refresh",()=>a.refresh()),M(n,"luna.assets.openPanel",()=>{C.window.showInformationMessage("Asset Explorer is in the sidebar under Luna2D.")}),M(n,"luna.assets.findMissing",()=>Fs()),M(n,"luna.assets.insertPath",r=>{r instanceof ft&&Bs(r)}),M(n,"luna.perf.openDashboard",()=>bo(n)),M(n,"luna.perf.clearHistory",()=>{let{clearHistory:r}=(wo(),Ot(zs));r()}),M(n,"luna.perf.openHotReload",()=>{let r=C.window.createWebviewPanel("luna.hotReload","Hot-Reload History",C.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0}),l=[],d=C.workspace.workspaceFolders?.[0]?.uri.fsPath??"",c=C.workspace.createFileSystemWatcher(new C.RelativePattern(d,"**/*.lua")),u=(h,p)=>{l.unshift({time:new Date().toLocaleTimeString(),file:C.workspace.asRelativePath(h),status:p}),l.length>200&&l.pop(),r.webview.postMessage({type:"events",events:l})};c.onDidChange(h=>u(h,"changed")),c.onDidCreate(h=>u(h,"created")),c.onDidDelete(h=>u(h,"deleted")),r.onDidDispose(()=>c.dispose()),r.webview.html=`<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline';"><style>body{font-family:var(--vscode-font-family);background:var(--vscode-editor-background);color:var(--vscode-foreground);padding:12px;margin:0;font-size:12px}h2{margin:0 0 10px;font-size:14px}table{border-collapse:collapse;width:100%}th,td{border:1px solid var(--vscode-panel-border,#444);padding:4px 8px;text-align:left}th{background:var(--vscode-editorWidget-background,#1e1e1e)}.changed{color:#4ec9b0}.created{color:#dcdcaa}.deleted{color:#f44747}#empty{opacity:.5;margin-top:20px}</style></head><body><h2>\u{1F504} Hot-Reload File Watcher</h2><p id="empty">Watching *.lua files \u2014 save a file to see events here.</p><table id="tbl" style="display:none"><thead><tr><th>Time</th><th>File</th><th>Status</th></tr></thead><tbody id="body"></tbody></table><script>window.addEventListener('message',e=>{const{events}=e.data;if(!events||!events.length)return;document.getElementById('empty').style.display='none';document.getElementById('tbl').style.display='';document.getElementById('body').innerHTML=events.map(ev=>'<tr><td>'+ev.time+'</td><td>'+ev.file+'</td><td class="'+ev.status+'">'+ev.status+'</td></tr>').join('');});</script></body></html>`}),M(n,"luna.deps.showGraph",()=>Do(n)),M(n,"luna.deps.findCircular",async()=>{let r=C.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!r){C.window.showErrorMessage("No workspace folder open.");return}let l=C.window.createOutputChannel("Luna Circular Deps");l.show(!0),l.appendLine("\u{1F50D} Scanning for circular dependencies...");let d=require("fs"),c=require("path"),u=c.join(r,"src");if(!d.existsSync(u)){l.appendLine("src/ directory not found.");return}let h=d.readdirSync(u,{withFileTypes:!0}).filter(k=>k.isDirectory()).map(k=>k.name),p={};for(let k of h){p[k]=[];let F=c.join(u,k,"mod.rs");if(!d.existsSync(F))continue;let q=d.readFileSync(F,"utf-8");for(let ae of q.matchAll(/use crate::([a-z_]+)/g))ae[1]!==k&&h.includes(ae[1])&&!p[k].includes(ae[1])&&p[k].push(ae[1])}let f={},g={},m={},v=[],y=0,b=[];function x(k){f[k]=g[k]=y++,v.push(k),m[k]=!0;for(let F of p[k]||[])f[F]===void 0?(x(F),g[k]=Math.min(g[k],g[F])):m[F]&&(g[k]=Math.min(g[k],f[F]));if(g[k]===f[k]){let F=[],q;do q=v.pop(),m[q]=!1,F.push(q);while(q!==k);F.length>1&&b.push(F)}}for(let k of h)f[k]===void 0&&x(k);b.length===0?l.appendLine("\u2705 No circular dependencies found."):(l.appendLine(`\u26A0\uFE0F  Found ${b.length} circular dependency cycle(s):`),b.forEach((k,F)=>l.appendLine(`  Cycle ${F+1}: ${k.join(" \u2192 ")} \u2192 ${k[k.length-1]}`))),l.appendLine(`
Done.`)}),M(n,"luna.deps.findOrphans",async()=>{let r=C.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!r){C.window.showErrorMessage("No workspace folder open.");return}let l=C.window.createOutputChannel("Luna Orphan Modules");l.show(!0),l.appendLine("\u{1F50D} Scanning for orphan modules...");let d=require("fs"),c=require("path"),u=c.join(r,"src");if(!d.existsSync(u)){l.appendLine("src/ not found.");return}let h=d.readdirSync(u,{withFileTypes:!0}).filter(y=>y.isDirectory()).map(y=>y.name),p=c.join(r,"src","lib.rs"),f=d.existsSync(p)?d.readFileSync(p,"utf-8"):"",g=new Set(h.filter(y=>f.includes(`pub mod ${y}`)||f.includes(`mod ${y}`))),m=new Set;for(let y of h){let b=c.join(u,y,"mod.rs");if(!d.existsSync(b))continue;let x=d.readFileSync(b,"utf-8");for(let k of x.matchAll(/use crate::([a-z_]+)/g))k[1]!==y&&m.add(k[1])}let v=h.filter(y=>!g.has(y)&&!m.has(y));v.length===0?l.appendLine("\u2705 No orphan modules found \u2014 all modules are referenced."):(l.appendLine(`\u26A0\uFE0F  Found ${v.length} potentially orphaned module(s):`),v.forEach(y=>l.appendLine(`  \u2022 ${y}`))),l.appendLine(`
Done.`)}),_s(n,ee),M(n,"luna.debug.openWatchers",()=>Hs(n)),M(n,"luna.debug.openInspector",()=>{let r=C.window.createWebviewPanel("lunaVariableInspector","Luna Variable Inspector",C.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0}),l=c=>`<!DOCTYPE html><html><head>
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
  <tbody id="rows">${c.length===0?'<tr><td colspan="3" class="empty">No watched expressions. Enter a Lua expression above.</td></tr>':c.map(u=>`<tr><td>${u.expr}</td><td class="val">${u.value}</td><td class="type">${u.type}</td></tr>`).join("")}</tbody>
</table>
<script>
  const vscode = acquireVsCodeApi();
  function addExpr(){ const e=document.getElementById('expr'); if(e.value.trim()) vscode.postMessage({cmd:'watch',expr:e.value.trim()}); e.value=''; }
  function clearAll(){ vscode.postMessage({cmd:'clear'}); }
  document.getElementById('expr').addEventListener('keydown',e=>{ if(e.key==='Enter') addExpr(); });
  window.addEventListener('message',e=>{ if(e.data.cmd==='refresh') location.reload(); });
</script>
</body></html>`,d=[];r.webview.html=l(d),r.webview.onDidReceiveMessage(async c=>{if(c.cmd==="watch"){let u="(not connected \u2014 run game with debug bridge)",h="?";try{let{DebugBridge:p}=await import("./debug/debugBridge");if(p.instance?.isConnected()){let f=await p.instance.evaluate(c.expr);u=f?.resultString??"(nil)",h=f?.luaType??"?"}}catch{}d.push({expr:c.expr,value:u,type:h}),r.webview.html=l(d)}else c.cmd==="clear"&&(d.length=0,r.webview.html=l(d))},void 0,n.subscriptions)}),M(n,"luna.debug.openCallStack",()=>{C.window.showInformationMessage("Call stack available when connected to the Lua debug bridge.")}),M(n,"luna.debug.addWatch",()=>{let r=C.window.activeTextEditor;r&&js(r)}),M(n,"luna.system.openMonitor",()=>Us(n)),M(n,"luna.api.usageReport",()=>Qs(n)),M(n,"luna.api.quickInsert",()=>Zs(ee)),M(n,"luna.codeLens.toggle",()=>C.commands.executeCommand("luna.codeLens.toggle")),typeof fe.onConnected=="function"){let r=fe;r.onConnected(()=>Eo(!0)),r.onDisconnected?.(()=>Eo(!1)),r.evaluate&&Os(async l=>{try{let d=await r.evaluate(l);return{value:String(d),type:typeof d}}catch{return}})}M(n,"luna.browseApi",()=>Nn()),M(n,"luna.openApiDocs",()=>gi()),M(n,"luna.openWiki",()=>hi()),M(n,"luna.depGraph",()=>Do(n)),M(n,"luna.depList",()=>vi()),M(n,"luna.apiCoverage",()=>{let r=C.window.createTerminal("Luna API Coverage");r.show(),r.sendText("python tools/integration_coverage.py")}),Pi(n,fe),Zi(n),M(n,"luna.debug.runAndConnect",async()=>{await To(Oe),await new Promise(l=>setTimeout(l,1500)),await fe.connect()?(C.commands.executeCommand("setContext","luna.debugConnected",!0),fe.startStatsPolling(),C.window.showInformationMessage("Luna2D started and debug bridge connected.")):C.window.showWarningMessage("Game launched but debug bridge could not connect. Is debug bridge enabled in conf.lua?")}),M(n,"luna.debug.performance",()=>{if(!fe.isConnected){C.window.showErrorMessage("Not connected to Luna2D engine. Run 'Luna: Debug Connect' first.");return}let r=C.window.createWebviewPanel("luna.debugPerf","Luna2D Live Performance",C.ViewColumn.Two,{enableScripts:!0,retainContextWhenHidden:!0});r.webview.html=`<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
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
</script></body></html>`;let l=setInterval(async()=>{if(!fe.isConnected){clearInterval(l);return}try{let d=await fe.getStats();r.webview.postMessage({type:"stats",...d})}catch{}},500);r.onDidDispose(()=>clearInterval(l))}),M(n,"luna.debug.printHistory",()=>{fe.showOutput()}),M(n,"luna.debug.screenshot",async()=>{if(!fe.isConnected){C.window.showErrorMessage("Not connected to Luna2D engine. Run 'Luna: Debug Connect' first.");return}try{let r=await fe.takeScreenshot();if(!r){C.window.showWarningMessage("Engine did not return screenshot data.");return}let l=Buffer.from(r,"base64"),d=C.workspace.workspaceFolders?.[0]?.uri.fsPath;if(!d){C.window.showErrorMessage("No workspace folder.");return}let c=new Date().toISOString().replace(/[:.]/g,"-"),u=require("path").join(d,`screenshot-${c}.png`);require("fs").writeFileSync(u,l);let h=C.Uri.file(u);await C.commands.executeCommand("vscode.open",h),C.window.showInformationMessage(`Screenshot saved: screenshot-${c}.png`)}catch(r){C.window.showErrorMessage(`Screenshot failed: ${r instanceof Error?r.message:String(r)}`)}}),M(n,"luna.debug.callStack",async()=>{if(!fe.isConnected){C.window.showErrorMessage("Not connected to Luna2D engine. Run 'Luna: Debug Connect' first.");return}try{let r=await fe.getCallStack();if(r.length===0){C.window.showInformationMessage("Call stack is empty (game may not be paused).");return}let l=r.map(c=>({label:`#${c.level} ${c.name}`,description:`${c.source}:${c.line}`,detail:`${c.source} line ${c.line}`,source:c.source,line:c.line})),d=await C.window.showQuickPick(l,{title:"Lua Call Stack",placeHolder:"Select a frame to navigate to"});if(d?.source&&d.source!=="?"&&d.source!=="[C]"){let c=d.source.startsWith("@")?d.source.slice(1):d.source,u=C.workspace.workspaceFolders?.[0]?.uri.fsPath;if(u){let h=require("path").join(u,c);if(require("fs").existsSync(h)){let p=await C.workspace.openTextDocument(h);await C.window.showTextDocument(p,{selection:new C.Range(d.line-1,0,d.line-1,0)})}}}}catch(r){C.window.showErrorMessage(`Call stack failed: ${r instanceof Error?r.message:String(r)}`)}}),M(n,"luna.debug.status",async()=>{let r=fe.getStatusInfo();if(!r.connected)await C.window.showInformationMessage(`Luna2D debug bridge: NOT connected (port ${r.port})`,"Connect Now","Dismiss")==="Connect Now"&&C.commands.executeCommand("luna.debug.connect");else try{let l=await fe.getStats();C.window.showInformationMessage(`Luna2D connected on port ${r.port} \xB7 FPS: ${l.fps} \xB7 Draw calls: ${l.drawCalls} \xB7 Memory: ${(l.memory/1024/1024).toFixed(1)} MB`)}catch{C.window.showInformationMessage(`Luna2D debug bridge connected on port ${r.port}.`)}}),M(n,"luna.cag.install",()=>yi()),M(n,"luna.cag.selectAgent",()=>bi()),M(n,"luna.cag.selectSkill",()=>xi()),M(n,"luna.cag.selectPrompt",()=>wi()),M(n,"luna.cag.update",()=>{C.window.showInformationMessage("CAG update is not yet implemented.")}),M(n,"luna.mcp.install",()=>{C.window.showInformationMessage("MCP server installation is not yet implemented.")}),M(n,"luna.mcp.status",()=>{C.window.showInformationMessage(zt?"MCP server is running.":"MCP server is not running.")}),Li(n),M(n,"luna.jam.quickBuild",()=>{let r=C.window.createTerminal("Luna Quick Build");r.show(),r.sendText("cargo build --release")}),M(n,"luna.jam.checklist",()=>{C.window.showInformationMessage("Submission Checklist is not yet implemented.")}),Mi(n),Ai(n),M(n,"luna2d.runExample",()=>nn(Oe)),M(n,"luna2d.listExamples",()=>nn(Oe)),M(n,"luna2d.checkBuild",()=>{let r=C.window.createTerminal("Luna Build Check");r.show(),r.sendText("cargo check")}),M(n,"luna2d.getApiDoc",()=>Nn());let i=Bc();i&&(zt=ka(i)),er(n),n.subscriptions.push(C.workspace.onDidChangeConfiguration(r=>{r.affectsConfiguration("luna.luaVersion")&&(ee.load(n.extensionPath).catch(l=>{console.error("Failed to reload Luna API data:",l)}),er(n))})),C.commands.executeCommand("setContext","luna.gameRunning",!1)}function Fc(){zt&&(zt.kill(),zt=void 0)}function M(n,e,t){n.subscriptions.push(C.commands.registerCommand(e,t))}function Bc(){return C.workspace.workspaceFolders?.[0]?.uri.fsPath}function er(n){let e=tr.join(n.extensionPath,"data"),t=C.workspace.getConfiguration("Lua"),o=t.get("workspace.library")??[];if(!o.includes(e)){let i=[...o,e];t.update("workspace.library",i,C.ConfigurationTarget.Global).then(void 0,()=>{})}let s=C.workspace.getConfiguration("luna").get("luaVersion","luajit")==="lua54"?"Lua 5.4":"LuaJIT";t.update("runtime.version",s,C.ConfigurationTarget.Global).then(void 0,()=>{})}0&&(module.exports={activate,deactivate});
