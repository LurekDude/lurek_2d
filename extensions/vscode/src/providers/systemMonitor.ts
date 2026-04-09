import * as vscode from "vscode";
import { execFile } from "child_process";
import { promisify } from "util";

const execFileAsync = promisify(execFile);

// ── Sample types ──────────────────────────────────────────────

export interface SystemSample {
  timestamp: number;
  cpuPercent: number;
  ramUsedMb: number;
  ramTotalMb: number;
  lunaProcessCpu: number;
  lunaProcessRamMb: number;
  gpuPercent?: number;
  gpuVramMb?: number;
  diskReadKbs?: number;
  diskWriteKbs?: number;
  netSentKbs?: number;
  netRecvKbs?: number;
}

// ── Panel state ───────────────────────────────────────────────

let _panel: vscode.WebviewPanel | undefined;
const _history: SystemSample[] = [];
const MAX_SAMPLES = 120;
let _pollInterval: ReturnType<typeof setInterval> | undefined;
let _prevDiskRead = 0;
let _prevDiskWrite = 0;
let _prevNetSent = 0;
let _prevNetRecv = 0;

// ── Data collection ───────────────────────────────────────────

async function collectSample(): Promise<SystemSample> {
  const sample: SystemSample = {
    timestamp: Date.now(),
    cpuPercent: 0,
    ramUsedMb: 0,
    ramTotalMb: 0,
    lunaProcessCpu: 0,
    lunaProcessRamMb: 0,
  };

  if (process.platform === "win32") {
    await collectWindows(sample);
  } else {
    await collectUnix(sample);
  }

  return sample;
}

async function collectWindows(sample: SystemSample): Promise<void> {
  // Use PowerShell to gather data — single script for efficiency
  const script = `
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
} | ConvertTo-Json -Compress`.trim();

  try {
    const { stdout } = await execFileAsync("powershell", ["-NoProfile", "-NonInteractive", "-Command", script], { timeout: 4000 });
    const data = JSON.parse(stdout.trim()) as Record<string, number>;
    sample.cpuPercent = data["CPU"] ?? 0;
    sample.ramTotalMb = Math.round((data["MemTotalKB"] ?? 0) / 1024);
    const freeMb = Math.round((data["MemFreeKB"] ?? 0) / 1024);
    sample.ramUsedMb = sample.ramTotalMb - freeMb;
    sample.lunaProcessCpu = data["LunaCPU"] ?? 0;
    sample.lunaProcessRamMb = data["LunaRAMMB"] ?? 0;
    const dr = data["DiskReadBps"] ?? 0;
    const dw = data["DiskWriteBps"] ?? 0;
    sample.diskReadKbs = Math.round(dr / 1024);
    sample.diskWriteKbs = Math.round(dw / 1024);
    const ns = data["NetSentBps"] ?? 0;
    const nr = data["NetRecvBps"] ?? 0;
    sample.netSentKbs = Math.round(ns / 1024);
    sample.netRecvKbs = Math.round(nr / 1024);
  } catch {
    // Fall through with zeros
  }

  // Try NVIDIA GPU via nvidia-smi  
  try {
    const { stdout: gpuOut } = await execFileAsync(
      "nvidia-smi",
      ["--query-gpu=utilization.gpu,memory.used", "--format=csv,noheader,nounits"],
      { timeout: 2000 },
    );
    const parts = gpuOut.trim().split(",");
    sample.gpuPercent = parseInt(parts[0] ?? "0", 10);
    sample.gpuVramMb = parseInt(parts[1]?.trim() ?? "0", 10);
  } catch {
    // No NVIDIA GPU or driver not available
  }
}

async function collectUnix(sample: SystemSample): Promise<void> {
  // Linux/macOS: use /proc/stat and /proc/meminfo
  try {
    const { stdout: topOut } = await execFileAsync("sh", ["-c",
      "top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1; free -m | grep Mem | awk '{print $3\" \"$2}'"
    ], { timeout: 3000 });
    const lines = topOut.trim().split("\n");
    sample.cpuPercent = parseFloat(lines[0] ?? "0");
    const memParts = (lines[1] ?? "").split(" ");
    sample.ramUsedMb = parseInt(memParts[0] ?? "0", 10);
    sample.ramTotalMb = parseInt(memParts[1] ?? "0", 10);
  } catch { /* skip */ }

  try {
    const { stdout: procOut } = await execFileAsync("sh", ["-c",
      "ps -C luna2d -o %cpu=,rss= 2>/dev/null || ps aux | grep '[l]una' | awk '{print $3, $6}' | head -1"
    ], { timeout: 2000 });
    const parts = procOut.trim().split(/\s+/);
    sample.lunaProcessCpu = parseFloat(parts[0] ?? "0");
    sample.lunaProcessRamMb = Math.round(parseInt(parts[1] ?? "0", 10) / 1024);
  } catch { /* skip */ }
}

// ── Poll loop ─────────────────────────────────────────────────

function startPolling(): void {
  if (_pollInterval) return;
  _pollInterval = setInterval(async () => {
    const sample = await collectSample();
    _history.push(sample);
    if (_history.length > MAX_SAMPLES) _history.shift();
    if (_panel?.visible) {
      _panel.webview.postMessage({ type: "data", samples: _history });
    }
  }, 2000);
}

function stopPolling(): void {
  if (_pollInterval) { clearInterval(_pollInterval); _pollInterval = undefined; }
}

// ── Public API ────────────────────────────────────────────────

export function openSystemMonitor(context: vscode.ExtensionContext): void {
  if (_panel) { _panel.reveal(vscode.ViewColumn.Two); return; }

  _panel = vscode.window.createWebviewPanel(
    "luna.systemMonitor",
    "Luna2D System Monitor",
    vscode.ViewColumn.Two,
    { enableScripts: true, retainContextWhenHidden: true },
  );

  _panel.webview.html = buildHtml();
  _panel.onDidDispose(() => {
    _panel = undefined;
    stopPolling();
  }, null, context.subscriptions);

  _panel.webview.onDidReceiveMessage((msg) => {
    if (msg.type === "start") startPolling();
    if (msg.type === "stop") stopPolling();
  }, null, context.subscriptions);

  startPolling();
  // Push existing history immediately
  if (_history.length) {
    _panel.webview.postMessage({ type: "data", samples: _history });
  }
}

// ── Webview HTML ──────────────────────────────────────────────

function buildHtml(): string {
  return /* html */`<!DOCTYPE html>
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
<h2>🖥 System Monitor</h2>
<div class="status-row">
  <div class="dot idle" id="pollDot"></div>
  <span id="pollStatus" style="font-size:12px;opacity:.7">Starting…</span>
  <span id="lunaStatus" class="badge idle">luna2d: not running</span>
</div>

<div class="grid">
  <!-- CPU -->
  <div class="card">
    <div class="card-title">CPU <span id="cpuPct">–%</span></div>
    <canvas id="cpuChart"></canvas>
  </div>

  <!-- RAM -->
  <div class="card">
    <div class="card-title">RAM <span id="ramPct">–</span></div>
    <canvas id="ramChart"></canvas>
  </div>

  <!-- GPU -->
  <div class="card">
    <div class="card-title">GPU <span id="gpuPct">–</span></div>
    <div id="gpuContent"><div class="no-gpu">No NVIDIA GPU detected (nvidia-smi required)</div></div>
    <canvas id="gpuChart"></canvas>
  </div>

  <!-- Disk -->
  <div class="card">
    <div class="card-title">Disk I/O</div>
    <div class="row">
      <div class="stat"><div class="big" id="diskR">–</div><div class="sub">Read KB/s</div></div>
      <div class="stat"><div class="big" id="diskW">–</div><div class="sub">Write KB/s</div></div>
    </div>
    <canvas id="diskChart"></canvas>
  </div>

  <!-- Network -->
  <div class="card">
    <div class="card-title">Network</div>
    <div class="row">
      <div class="stat"><div class="big" id="netS">–</div><div class="sub">Sent KB/s</div></div>
      <div class="stat"><div class="big" id="netR">–</div><div class="sub">Recv KB/s</div></div>
    </div>
    <canvas id="netChart"></canvas>
  </div>

  <!-- Luna2D process -->
  <div class="card luna-card">
    <div class="card-title">Luna2D Process</div>
    <div class="row">
      <div class="stat"><div class="big" id="lunaCpu">–</div><div class="sub">CPU %</div></div>
      <div class="stat"><div class="big" id="lunaRam">–</div><div class="sub">RAM MB</div></div>
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
  document.getElementById('pollStatus').textContent = 'Polling every 2s  ·  ' + _samples.length + ' samples';
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
</html>`;
}
