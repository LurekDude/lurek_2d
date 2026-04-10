import * as vscode from "vscode";
import * as path from "path";
import * as fs from "fs";
import * as cp from "child_process";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

// ── Types matching unit_test_api_coverage.py output ───────────────────────────

interface ModuleCov {
  total: number;
  covered_explicit: number;
  covered_heuristic: number;
  covered_any: number;
  uncovered: number;
  uncovered_any: number;
  pct_explicit: number;
  pct_any: number;
  explicit_apis: Array<{
    lua_name: string;
    coverage: "explicit";
    locations: string[];
  }>;
  heuristic_apis: Array<{
    lua_name: string;
    coverage: "heuristic";
    locations: string[];
  }>;
  uncovered_apis: Array<{
    lua_name: string;
    name: string;
    is_method: boolean;
    owner_type: string;
    source_file: string;
    source_line: number;
    coverage_hint: "heuristic" | "none";
    locations: string[];
  }>;
  uncovered_any_apis: Array<{
    lua_name: string;
    name: string;
    is_method: boolean;
    owner_type: string;
    source_file: string;
    source_line: number;
  }>;
  covered_apis: Array<{
    lua_name: string;
    coverage: "explicit" | "heuristic";
    locations: string[];
  }>;
}

interface CoverageData {
  generated: string;
  generator: string;
  strict_mode: boolean;
  summary: {
    total_apis: number;
    covered_explicit: number;
    covered_heuristic: number;
    covered_any: number;
    uncovered: number;
    uncovered_any: number;
    pct_explicit: number;
    pct_any: number;
    total_modules: number;
  };
  modules: Record<string, ModuleCov>;
}

// ── Editor class ──────────────────────────────────────────────────────────────

export class ApiCoverageEditor extends WebviewEditor {
  private covData: CoverageData | null = null;
  private scanning = false;

  static open(context: vscode.ExtensionContext): ApiCoverageEditor {
    return new ApiCoverageEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.editor.apiCoverage", "API Test Coverage");
    this.loadReport();
  }

  // ── Message handler ─────────────────────────────────────────────────────────

  protected handleMessage(msg: { type: string; [key: string]: unknown }): void {
    switch (msg.type) {
      case "rescan":
        this.runScan();
        break;
      case "openGaps":
        this.openGapsFile();
        break;
      case "openTest":
        this.openTestFile(msg.module as string);
        break;
    }
  }

  // ── Data loading ────────────────────────────────────────────────────────────

  private loadReport(): void {
    const ws = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (!ws) return;
    const jsonPath = path.join(ws, "docs", "logs", "unit_test_coverage.json");
    if (!fs.existsSync(jsonPath)) {
      this.panel.webview.postMessage({ type: "noData" });
      return;
    }
    try {
      const raw = fs.readFileSync(jsonPath, "utf-8");
      this.covData = JSON.parse(raw) as CoverageData;
      this.panel.webview.postMessage({ type: "data", payload: this.covData });
    } catch {
      this.panel.webview.postMessage({ type: "error", message: "Failed to parse coverage JSON" });
    }
  }

  private runScan(): void {
    if (this.scanning) return;
    const ws = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (!ws) return;

    this.scanning = true;
    this.panel.webview.postMessage({ type: "scanning" });

    const script = path.join(ws, "tools", "audit", "unit_test_api_coverage.py");
    const cmd = `python "${script}" --save`;

    cp.exec(cmd, { cwd: ws }, (err: Error | null, stdout: string, stderr: string) => {
      this.scanning = false;
      if (err) {
        this.panel.webview.postMessage({
          type: "scanError",
          message: stderr || err.message,
        });
        return;
      }
      this.loadReport();
      this.panel.webview.postMessage({ type: "scanDone", output: stdout });
    });
  }

  private openGapsFile(): void {
    const ws = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (!ws) return;
    const mdPath = path.join(ws, "docs", "quality", "unit_test_coverage.md");
    if (fs.existsSync(mdPath)) {
      vscode.commands.executeCommand(
        "markdown.showPreview",
        vscode.Uri.file(mdPath)
      );
    }
  }

  private openTestFile(moduleName: string): void {
    const ws = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (!ws) return;
    const testPath = path.join(ws, "tests", "lua", "unit", `test_${moduleName}.lua`);
    if (fs.existsSync(testPath)) {
      vscode.workspace.openTextDocument(testPath).then((doc: vscode.TextDocument) =>
        vscode.window.showTextDocument(doc)
      );
    }
  }

  // ── HTML ────────────────────────────────────────────────────────────────────

  protected getHtml(): string {
    const nonce = getNonce();
    const css = `
      .cov-layout { display: flex; flex-direction: column; height: 100vh; }
      .cov-header { padding: 10px 14px; background: var(--surface); border-bottom: 1px solid var(--border); display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
      .cov-header h1 { font-size: 14px; font-weight: 600; flex: 1; }
      .cov-body { display: flex; flex: 1; overflow: hidden; }
      .cov-sidebar { width: 220px; min-width: 180px; overflow-y: auto; padding: 8px; border-right: 1px solid var(--border); }
      .cov-main { flex: 1; overflow-y: auto; padding: 14px 18px; }
      .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 10px; margin-bottom: 18px; }
      .stat-card { background: var(--surface); border: 1px solid var(--border); border-radius: 5px; padding: 10px 14px; }
      .stat-card .val { font-size: 22px; font-weight: 700; color: var(--accent-2); }
      .stat-card .lbl { font-size: 11px; color: var(--text-dim); margin-top: 2px; }
      .module-item { padding: 5px 8px; cursor: pointer; border-radius: 3px; font-size: 12px; display: flex; align-items: center; gap: 6px; }
      .module-item:hover { background: var(--surface-2); }
      .module-item.selected { background: var(--selection); }
      .module-item .pct { font-size: 11px; color: var(--text-dim); margin-left: auto; }
      .module-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
      .dot-good { background: var(--success); }
      .dot-warn { background: var(--warning); }
      .dot-bad { background: var(--danger); }
      .bar-row { display: flex; align-items: center; gap: 8px; margin-bottom: 4px; font-size: 12px; }
      .bar-bg { flex: 1; height: 8px; background: var(--surface-2); border-radius: 4px; overflow: hidden; }
      .bar-fill-explicit { height: 100%; background: var(--success); border-radius: 4px; }
      .bar-fill-heuristic { height: 100%; background: var(--warning); border-radius: 4px; }
      .api-table { width: 100%; border-collapse: collapse; font-size: 12px; }
      .api-table th { background: var(--surface); padding: 6px 8px; text-align: left; border-bottom: 1px solid var(--border); font-size: 11px; color: var(--text-dim); position: sticky; top: 0; }
      .api-table td { padding: 4px 8px; border-bottom: 1px solid var(--border); font-family: 'Cascadia Code', monospace; }
      .badge { display: inline-block; padding: 1px 6px; border-radius: 10px; font-size: 10px; }
      .badge-explicit { background: #1a3a2a; color: #4caf50; }
      .badge-heuristic { background: #3a2a1a; color: #ff9800; }
      .badge-gap { background: #3a1a1a; color: #f44336; }
      .search-bar { display: flex; gap: 6px; margin-bottom: 12px; }
      .search-bar input { flex: 1; }
      .section-head { font-size: 13px; font-weight: 600; margin: 14px 0 8px; padding-bottom: 4px; border-bottom: 1px solid var(--border); }
      .no-data { padding: 40px; text-align: center; color: var(--text-dim); }
      .spin { display: inline-block; width: 14px; height: 14px; border: 2px solid var(--border); border-top-color: var(--accent); border-radius: 50%; animation: spin 0.6s linear infinite; }
      @keyframes spin { to { transform: rotate(360deg); } }
      .filter-row { display: flex; gap: 6px; margin-bottom: 10px; }
      .ts-note { font-size: 11px; color: var(--text-dim); }
    `;

    const body = `
<div class="cov-layout">
  <div class="cov-header">
    <h1>API Unit-Test Coverage</h1>
    <input id="search" type="text" placeholder="Search API…" style="width:180px">
    <select id="filterSel">
      <option value="all">All APIs</option>
      <option value="explicit">Explicit @tests</option>
      <option value="needs-annotation">Needs @tests</option>
      <option value="zero-evidence">Zero evidence</option>
    </select>
    <button onclick="rescan()" id="scanBtn">↻ Re-scan</button>
    <button onclick="openGaps()">📄 Open Report</button>
    <span id="spinEl" style="display:none"><span class="spin"></span> Scanning…</span>
    <span id="tsNote" class="ts-note"></span>
  </div>
  <div class="cov-body">
    <div class="cov-sidebar" id="sidebar">
      <div style="padding:4px 8px;font-size:11px;color:var(--text-dim);text-transform:uppercase;letter-spacing:.5px">Modules</div>
      <div id="moduleList"></div>
    </div>
    <div class="cov-main" id="mainPanel">
      <div class="no-data" id="noDataMsg">
        <div style="font-size:24px;margin-bottom:12px">Coverage</div>
        <p style="margin-bottom:10px">No coverage data found.</p>
        <p style="font-size:12px;color:var(--text-dim);margin-bottom:16px">
          Run <code>python tools/audit/unit_test_api_coverage.py --save</code><br>
          or click <strong>Re-scan</strong> above.
        </p>
      </div>
      <div id="content" style="display:none">
        <div id="summary" class="summary-grid"></div>
        <div id="moduleDetail"></div>
      </div>
    </div>
  </div>
</div>`;

    const scripts = `
let coverageData = null;
let selectedModule = '__all__';
let filter = 'all';
let searchTerm = '';

window.addEventListener('message', ev => {
  const msg = ev.data;
  if (msg.type === 'data') { coverageData = msg.payload; render(); }
  else if (msg.type === 'noData') { showNoData(); }
  else if (msg.type === 'scanning') { setScan(true); }
  else if (msg.type === 'scanDone') { setScan(false); }
  else if (msg.type === 'scanError') { setScan(false); alert('Scan error: ' + msg.message); }
  else if (msg.type === 'error') { showNoData(msg.message); }
});

document.getElementById('search').addEventListener('input', e => {
  searchTerm = e.target.value.toLowerCase();
  renderModuleDetail();
});
document.getElementById('filterSel').addEventListener('change', e => {
  filter = e.target.value;
  renderModuleDetail();
});

function rescan() { vscode.postMessage({ type: 'rescan' }); }
function openGaps() { vscode.postMessage({ type: 'openGaps' }); }
function openTest(mod) { vscode.postMessage({ type: 'openTest', module: mod }); }
function setScan(v) {
  document.getElementById('scanBtn').disabled = v;
  document.getElementById('spinEl').style.display = v ? 'inline-flex' : 'none';
}

function showNoData(msg) {
  document.getElementById('noDataMsg').style.display = '';
  document.getElementById('content').style.display = 'none';
  if (msg) document.getElementById('noDataMsg').querySelector('p').textContent = msg;
}

function dotClass(pct) {
  if (pct >= 80) return 'dot-good';
  if (pct >= 40) return 'dot-warn';
  return 'dot-bad';
}

function badgeHtml(cov) {
  if (cov === 'explicit') return '<span class="badge badge-explicit">explicit</span>';
  if (cov === 'heuristic') return '<span class="badge badge-heuristic">heuristic</span>';
  return '<span class="badge badge-gap">gap</span>';
}

function render() {
  if (!coverageData) return;
  document.getElementById('noDataMsg').style.display = 'none';
  document.getElementById('content').style.display = '';

  const s = coverageData.summary;
  const ts = coverageData.generated ? coverageData.generated.slice(0,19).replace('T',' ') : '';
  document.getElementById('tsNote').textContent = ts ? 'Last scan: ' + ts : '';

  // Summary cards
  document.getElementById('summary').innerHTML = [
    card(s.total_apis, 'Total APIs'),
    card(s.covered_explicit + ' (' + s.pct_explicit.toFixed(1) + '%)', 'Explicit @tests'),
    card(s.covered_heuristic, 'Heuristic-only hints'),
    card(s.uncovered + ' (' + (100 - s.pct_explicit).toFixed(1) + '%)', 'Needs @tests', s.uncovered > 0 ? 'var(--danger)' : 'var(--success)'),
    card(s.uncovered_any, 'Zero evidence', s.uncovered_any > 0 ? 'var(--warning)' : 'var(--success)'),
    card(s.covered_any + ' (' + s.pct_any.toFixed(1) + '%)', 'Any evidence'),
    card(s.total_modules, 'Modules'),
  ].join('');

  // Module list sidebar
  const mods = Object.entries(coverageData.modules).sort((a, b) => a[1].pct_explicit - b[1].pct_explicit);
  let listHtml = '<div class="module-item' + (selectedModule === '__all__' ? ' selected' : '') + '" onclick="selectModule(\'__all__\', this)">'
    + '<span class="module-dot dot-good"></span><span>All modules</span>'
    + '<span class="pct">' + s.pct_explicit.toFixed(0) + '%</span></div>';
  for (const [mod, m] of mods) {
    listHtml += '<div class="module-item' + (selectedModule === mod ? ' selected' : '') + '" onclick="selectModule(\'' + esc(mod) + '\', this)">'
      + '<span class="module-dot ' + dotClass(m.pct_explicit) + '"></span>'
      + '<span>' + esc(mod) + '</span>'
      + '<span class="pct">' + m.pct_explicit.toFixed(0) + '%</span></div>';
  }
  document.getElementById('moduleList').innerHTML = listHtml;
  renderModuleDetail();
}

function card(val, lbl, color) {
  return '<div class="stat-card"><div class="val" style="' + (color ? 'color:' + color : '') + '">' + val + '</div><div class="lbl">' + lbl + '</div></div>';
}

function selectModule(mod, el) {
  selectedModule = mod;
  // Update sidebar highlights
  document.querySelectorAll('#moduleList .module-item').forEach(el => el.classList.remove('selected'));
  if (el) el.classList.add('selected');
  renderModuleDetail();
}

function renderModuleDetail() {
  if (!coverageData) return;
  const detail = document.getElementById('moduleDetail');
  const mods = selectedModule === '__all__'
    ? Object.entries(coverageData.modules).sort((a, b) => a[1].pct_explicit - b[1].pct_explicit)
    : Object.entries(coverageData.modules).filter(([k]) => k === selectedModule);

  let html = '';
  for (const [mod, m] of mods) {
    const allApis = [
      ...m.explicit_apis.map(a => ({ ...a, covered: 'explicit' })),
      ...m.heuristic_apis.map(a => ({ ...a, covered: 'heuristic' })),
      ...m.uncovered_any_apis.map(a => ({ lua_name: a.lua_name, name: a.name, covered: 'gap', locations: [], is_method: a.is_method, owner_type: a.owner_type })),
    ];

    const filtered = allApis.filter(a => {
      if (searchTerm && !a.lua_name.toLowerCase().includes(searchTerm)) return false;
      if (filter === 'explicit' && a.covered !== 'explicit') return false;
      if (filter === 'needs-annotation' && a.covered === 'explicit') return false;
      if (filter === 'zero-evidence' && a.covered !== 'gap') return false;
      return true;
    });

    if (selectedModule === '__all__' && filtered.length === 0) continue;

    // Coverage bar
    const explPct = m.pct_explicit;
    const heurPct = m.pct_any - m.pct_explicit;
    const barExpl = '<div class="bar-fill-explicit" style="width:' + explPct + '%"></div>';
    const barHeur = heurPct > 0
      ? '<div style="width:' + heurPct + '%;background:var(--warning);height:100%;float:right;border-radius:4px"></div>'
      : '';

    html += '<div class="section-head">'
      + '<span style="font-family:monospace">lurek.' + esc(mod) + '</span>'
      + ' <span class="ts-note">' + m.covered_explicit + '/' + m.total + ' explicit (' + m.pct_explicit.toFixed(1) + '%)</span>'
      + ' <button style="font-size:10px;padding:1px 6px" onclick="openTest(\'' + esc(mod) + '\')">Open Test</button>'
      + '</div>'
      + '<div class="bar-row"><span style="width:60px;text-align:right;font-size:11px">' + m.pct_explicit.toFixed(1) + '%</span>'
      + '<div class="bar-bg"><div style="display:flex;height:100%;border-radius:4px;overflow:hidden">'
      + barExpl + barHeur
      + '</div></div>'
      + '<span class="ts-note" style="width:130px">' + m.covered_heuristic + ' heuristic-only</span></div>';

    if (filtered.length === 0) {
      html += '<p class="ts-note" style="padding:6px 0">No APIs match current filter.</p>';
    } else {
      html += '<table class="api-table"><thead><tr><th>API</th><th>Coverage</th><th>Test location</th></tr></thead><tbody>';
      for (const a of filtered.slice(0, 300)) {
        const loc = a.locations && a.locations.length > 0 ? esc(a.locations[0]) : '';
        html += '<tr><td>' + esc(a.lua_name) + '</td><td>' + badgeHtml(a.covered) + '</td><td style="color:var(--text-dim);font-size:11px">' + loc + '</td></tr>';
      }
      if (filtered.length > 300) {
        html += '<tr><td colspan="3" style="color:var(--text-dim);font-size:11px">… and ' + (filtered.length - 300) + ' more</td></tr>';
      }
      html += '</tbody></table>';
    }
    html += '<div style="margin-bottom:18px"></div>';
  }

  detail.innerHTML = html || '<p class="ts-note" style="padding:20px">No APIs match filter.</p>';
}

function esc(s) {
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
`;

    return wrapHtml(nonce, "API Test Coverage", css, body, scripts);
  }
}
