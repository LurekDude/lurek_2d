import * as vscode from "vscode";

// ── Data types ───────────────────────────────────────────────

interface PerfSample {
  timestamp: number;
  fps: number;
  frameMs: number;
  luaHeapKb?: number;
}

// ── Panel manager ────────────────────────────────────────────

let _panel: vscode.WebviewPanel | undefined;
const _history: PerfSample[] = [];
const MAX_HISTORY = 300;

export function openPerfDashboard(context: vscode.ExtensionContext): void {
  if (_panel) {
    _panel.reveal(vscode.ViewColumn.Two);
    return;
  }

  _panel = vscode.window.createWebviewPanel(
    "luna.perfDashboard",
    "Luna2D Performance",
    vscode.ViewColumn.Two,
    { enableScripts: true, retainContextWhenHidden: true },
  );

  _panel.webview.html = buildHtml();
  _panel.onDidDispose(() => { _panel = undefined; }, null, context.subscriptions);

  // Re-render on messages from the webview (future: interactive controls)
  _panel.webview.onDidReceiveMessage((msg) => {
    if (msg.type === "clear") clearHistory();
  }, null, context.subscriptions);

  // Push current history immediately
  pushToPanel();
}

export function recordSample(fps: number, frameMs: number, luaHeapKb?: number): void {
  _history.push({ timestamp: Date.now(), fps, frameMs, luaHeapKb });
  if (_history.length > MAX_HISTORY) _history.shift();
  if (_panel?.visible) pushToPanel();
}

export function clearHistory(): void {
  _history.length = 0;
  if (_panel?.visible) pushToPanel();
}

function pushToPanel(): void {
  if (!_panel) return;
  _panel.webview.postMessage({ type: "data", samples: [..._history] });
}

// ── Webview HTML ─────────────────────────────────────────────

function buildHtml(): string {
  return /* html */`<!DOCTYPE html>
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
<h2>🎮 Luna2D Performance Dashboard</h2>
<div class="stats">
  <div class="stat"><div class="stat-value" id="fps">–</div><div class="stat-label">FPS</div></div>
  <div class="stat"><div class="stat-value" id="frame">–</div><div class="stat-label">Frame ms</div></div>
  <div class="stat"><div class="stat-value" id="heap">–</div><div class="stat-label">Lua Heap</div></div>
  <div class="stat"><div class="stat-value" id="samples">0</div><div class="stat-label">Samples</div></div>
</div>

<p class="chart-label">FPS over time</p>
<canvas id="fpsChart" width="600" height="120"></canvas>
<p class="chart-label">Frame time (ms)</p>
<canvas id="msChart" width="600" height="120"></canvas>

<div id="empty" class="empty">No data yet — run your game with luna.debug.connect() to stream performance data.</div>

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
  document.getElementById('heap').textContent = last.luaHeapKb ? (last.luaHeapKb + ' KB') : '–';
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
</html>`;
}
