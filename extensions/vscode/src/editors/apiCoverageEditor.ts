import * as vscode from "vscode";
import * as path from "path";
import * as fs from "fs";
import * as cp from "child_process";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

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
    return wrapHtml(nonce, "API Test Coverage", `
      .editor-layout { display:grid; grid-template-rows:auto 1fr auto; height:100vh; overflow:hidden; }
      .toolbar { display:flex; align-items:center; gap:6px; padding:6px 10px; background:var(--surface); border-bottom:1px solid var(--border); flex-wrap:wrap; }
      .toolbar .title { font-weight:600; font-size:13px; white-space:nowrap; }
      .toolbar input[type=text] { width:180px; background:var(--bg); color:var(--text); border:1px solid var(--border); border-radius:var(--radius); padding:3px 8px; font-size:12px; }
      .toolbar select { background:var(--surface); color:var(--text); border:1px solid var(--border); border-radius:var(--radius); padding:3px 6px; font-size:11px; }
      .main-area { display:grid; grid-template-columns:220px 1fr; overflow:hidden; }
      .sidebar-col { overflow-y:auto; padding:8px; border-right:1px solid var(--border); }
      .sidebar-label { padding:4px 8px; font-size:11px; color:var(--text-dim); text-transform:uppercase; letter-spacing:.05em; }
      .content-col { flex:1; overflow-y:auto; padding:14px 18px; }
      .summary-grid { display:grid; grid-template-columns:repeat(auto-fit, minmax(140px,1fr)); gap:10px; margin-bottom:18px; }
      .stat-card { background:var(--surface); border:1px solid var(--border); border-radius:var(--radius); padding:10px 14px; }
      .stat-card .big { font-size:22px; font-weight:700; color:var(--accent-2); }
      .stat-card .lbl { font-size:11px; color:var(--text-dim); margin-top:2px; }
      .module-item { padding:5px 8px; cursor:pointer; border-radius:var(--radius); font-size:12px; display:flex; align-items:center; gap:6px; transition:background .12s; }
      .module-item:hover { background:var(--hover); }
      .module-item.sel { background:var(--selection); }
      .module-item .pct { font-size:11px; color:var(--text-dim); margin-left:auto; font-family:monospace; }
      .module-dot { width:8px; height:8px; border-radius:50%; flex-shrink:0; }
      .dot-good { background:var(--success); }
      .dot-warn { background:var(--warning); }
      .dot-bad { background:var(--error); }
      .bar-row { display:flex; align-items:center; gap:8px; margin-bottom:4px; font-size:12px; }
      .bar-bg { flex:1; height:8px; background:var(--surface-2); border-radius:4px; overflow:hidden; }
      .bar-fill-explicit { height:100%; background:var(--success); border-radius:4px; }
      .bar-fill-heuristic { height:100%; background:var(--warning); border-radius:4px; }
      .api-table { width:100%; border-collapse:collapse; font-size:12px; }
      .api-table th { background:var(--surface); padding:6px 8px; text-align:left; border-bottom:1px solid var(--border); font-size:11px; color:var(--text-dim); position:sticky; top:0; z-index:1; }
      .api-table td { padding:4px 8px; border-bottom:1px solid var(--border); font-family:'Cascadia Code','Fira Code',monospace; }
      .api-table tr:hover { background:var(--hover); }
      .badge { display:inline-block; padding:1px 7px; border-radius:10px; font-size:10px; font-weight:600; }
      .badge-explicit { background:color-mix(in srgb, var(--success) 20%, transparent); color:var(--success); }
      .badge-heuristic { background:color-mix(in srgb, var(--warning) 20%, transparent); color:var(--warning); }
      .badge-gap { background:color-mix(in srgb, var(--error) 20%, transparent); color:var(--error); }
      .section-head { font-size:13px; font-weight:600; margin:14px 0 8px; padding-bottom:4px; border-bottom:1px solid var(--border); display:flex; align-items:center; gap:8px; }
      .section-head .mod-name { font-family:monospace; }
      .section-head .mod-stat { font-size:11px; color:var(--text-dim); font-weight:400; }
      .section-head button { font-size:10px; padding:1px 6px; background:var(--surface); color:var(--text-dim); border:1px solid var(--border); border-radius:var(--radius); cursor:pointer; margin-left:auto; }
      .section-head button:hover { background:var(--hover); color:var(--text); }
      .no-data { padding:40px; text-align:center; color:var(--text-dim); }
      .no-data code { background:var(--surface); padding:2px 6px; border-radius:var(--radius); font-size:12px; }
      .spin { display:inline-block; width:14px; height:14px; border:2px solid var(--border); border-top-color:var(--accent); border-radius:50%; animation:spin .6s linear infinite; }
      @keyframes spin { to { transform:rotate(360deg); } }
      .status-bar { display:flex; align-items:center; gap:8px; padding:4px 10px; background:var(--surface); border-top:1px solid var(--border); font-size:11px; color:var(--text-dim); }
      .status-badge { background:var(--accent); color:var(--bg); padding:1px 7px; border-radius:10px; font-size:10px; font-weight:600; }
      .sep { width:1px; height:14px; background:var(--border); }
      .spacer { flex:1; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <span class="title">${ICONS.grid ?? '📊'} API Test Coverage</span>
          ${toolbarSep()}
          <input id="search" type="text" placeholder="Search API…">
          <select id="filterSel">
            <option value="all">All APIs</option>
            <option value="explicit">Explicit @tests</option>
            <option value="needs-annotation">Needs @tests</option>
            <option value="zero-evidence">Zero evidence</option>
          </select>
          ${toolbarSep()}
          ${iconButton(ICONS.play,'scanBtn','Re-scan')}
          <span id="spinEl" style="display:none"><span class="spin"></span> Scanning…</span>
          ${toolbarSpacer()}
          ${iconButton(ICONS.save,'openGapsBtn','Open Report')}
          <span id="tsNote" style="font-size:11px;color:var(--text-dim)"></span>
        </div>
        <div class="main-area">
          <div class="sidebar-col" id="sidebar">
            <div class="sidebar-label">Modules</div>
            <div id="moduleList"></div>
          </div>
          <div class="content-col" id="mainPanel">
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
        <div class="status-bar">
          <span class="status-badge" id="statusBadge">—</span>
          <span class="sep"></span>
          <span id="statusText">No data loaded</span>
          <span class="spacer"></span>
          <span id="statusTs"></span>
        </div>
      </div>
    `, `
      const vscode = acquireVsCodeApi();
      let coverageData = null;
      let selectedModule = '__all__';
      let filter = 'all';
      let searchTerm = '';

      function g(id) { return document.getElementById(id); }

      window.addEventListener('message', ev => {
        const msg = ev.data;
        if (msg.type === 'data') { coverageData = msg.payload; render(); }
        else if (msg.type === 'noData') { showNoData(); }
        else if (msg.type === 'scanning') { setScan(true); }
        else if (msg.type === 'scanDone') { setScan(false); }
        else if (msg.type === 'scanError') { setScan(false); showToast('Scan error: ' + msg.message, 'error'); }
        else if (msg.type === 'error') { showNoData(msg.message); }
      });

      g('search').addEventListener('input', e => { searchTerm = e.target.value.toLowerCase(); renderModuleDetail(); });
      g('filterSel').addEventListener('change', e => { filter = e.target.value; renderModuleDetail(); });
      g('scanBtn').addEventListener('click', () => vscode.postMessage({ type: 'rescan' }));
      g('openGapsBtn').addEventListener('click', () => vscode.postMessage({ type: 'openGaps' }));

      function openTest(mod) { vscode.postMessage({ type: 'openTest', module: mod }); }

      function setScan(v) {
        g('scanBtn').disabled = v;
        g('spinEl').style.display = v ? 'inline-flex' : 'none';
        g('statusText').textContent = v ? 'Scanning…' : (coverageData ? coverageData.summary.total_apis + ' APIs across ' + coverageData.summary.total_modules + ' modules' : 'No data loaded');
      }

      function showNoData(msg) {
        g('noDataMsg').style.display = '';
        g('content').style.display = 'none';
        if (msg) g('noDataMsg').querySelector('p').textContent = msg;
        g('statusBadge').textContent = '—';
        g('statusText').textContent = msg || 'No data loaded';
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
        g('noDataMsg').style.display = 'none';
        g('content').style.display = '';

        const s = coverageData.summary;
        const ts = coverageData.generated ? coverageData.generated.slice(0,19).replace('T',' ') : '';
        g('tsNote').textContent = ts ? 'Last: ' + ts : '';
        g('statusTs').textContent = ts ? 'Scanned: ' + ts : '';
        g('statusBadge').textContent = s.pct_explicit.toFixed(0) + '%';
        g('statusText').textContent = s.total_apis + ' APIs across ' + s.total_modules + ' modules';

        g('summary').innerHTML = [
          card(s.total_apis, 'Total APIs'),
          card(s.covered_explicit + ' (' + s.pct_explicit.toFixed(1) + '%)', 'Explicit @tests'),
          card(s.covered_heuristic, 'Heuristic-only hints'),
          card(s.uncovered + ' (' + (100 - s.pct_explicit).toFixed(1) + '%)', 'Needs @tests', s.uncovered > 0 ? 'var(--error)' : 'var(--success)'),
          card(s.uncovered_any, 'Zero evidence', s.uncovered_any > 0 ? 'var(--warning)' : 'var(--success)'),
          card(s.covered_any + ' (' + s.pct_any.toFixed(1) + '%)', 'Any evidence'),
          card(s.total_modules, 'Modules'),
        ].join('');

        const mods = Object.entries(coverageData.modules).sort((a, b) => a[1].pct_explicit - b[1].pct_explicit);
        let listHtml = '<div class="module-item' + (selectedModule === '__all__' ? ' sel' : '') + '" onclick="selectModule(\'__all__\', this)">'
          + '<span class="module-dot dot-good"></span><span>All modules</span>'
          + '<span class="pct">' + s.pct_explicit.toFixed(0) + '%</span></div>';
        for (const [mod, m] of mods) {
          listHtml += '<div class="module-item' + (selectedModule === mod ? ' sel' : '') + '" onclick="selectModule(\'' + esc(mod) + '\', this)">'
            + '<span class="module-dot ' + dotClass(m.pct_explicit) + '"></span>'
            + '<span>' + esc(mod) + '</span>'
            + '<span class="pct">' + m.pct_explicit.toFixed(0) + '%</span></div>';
        }
        g('moduleList').innerHTML = listHtml;
        renderModuleDetail();
      }

      function card(val, lbl, color) {
        return '<div class="stat-card"><div class="big" style="' + (color ? 'color:' + color : '') + '">' + val + '</div><div class="lbl">' + lbl + '</div></div>';
      }

      function selectModule(mod, el) {
        selectedModule = mod;
        document.querySelectorAll('#moduleList .module-item').forEach(e => e.classList.remove('sel'));
        if (el) el.classList.add('sel');
        renderModuleDetail();
      }

      function renderModuleDetail() {
        if (!coverageData) return;
        const detail = g('moduleDetail');
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

          const explPct = m.pct_explicit;
          const heurPct = m.pct_any - m.pct_explicit;

          html += '<div class="section-head">'
            + '<span class="mod-name">lurek.' + esc(mod) + '</span>'
            + '<span class="mod-stat">' + m.covered_explicit + '/' + m.total + ' explicit (' + m.pct_explicit.toFixed(1) + '%)</span>'
            + '<button onclick="openTest(\'' + esc(mod) + '\')">Open Test</button>'
            + '</div>'
            + '<div class="bar-row"><span style="width:60px;text-align:right;font-size:11px">' + m.pct_explicit.toFixed(1) + '%</span>'
            + '<div class="bar-bg"><div style="display:flex;height:100%;border-radius:4px;overflow:hidden">'
            + '<div class="bar-fill-explicit" style="width:' + explPct + '%"></div>'
            + (heurPct > 0 ? '<div style="width:' + heurPct + '%;background:var(--warning);height:100%;border-radius:4px"></div>' : '')
            + '</div></div>'
            + '<span style="width:130px;font-size:11px;color:var(--text-dim)">' + m.covered_heuristic + ' heuristic-only</span></div>';

          if (filtered.length === 0) {
            html += '<p style="padding:6px 0;font-size:11px;color:var(--text-dim)">No APIs match current filter.</p>';
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

        detail.innerHTML = html || '<p style="padding:20px;font-size:11px;color:var(--text-dim)">No APIs match filter.</p>';
      }

      function esc(s) {
        return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
      }
    `);
  }
}
