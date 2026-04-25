import * as vscode from "vscode";
import * as path from "path";
import * as fs from "fs";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";
import {
  buildLuaTestsCommand,
  buildTestAllCommand,
  buildTestTargetCommand,
} from "../services/parallelCargo.js";

// ── Static fallback — auto-updated from actual tests/ directory ──
const KNOWN_MODULES = [
  "ai","audio","cardgame","combat","compute","config","crafting","data",
  "dataframe","dialog","engine","ecs","event","filesystem","graph",
  "render","graphics_ext","image","input","inventory","math","math_ext",
  "minimap","mods","particle","pathfind","physics","postfx","quest",
  "resource","save","scene","sound","stats","thread","tilemap","timer",
];

export class TestRunnerEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): TestRunnerEditor {
    return new TestRunnerEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.editor.testRunner", "Test Runner");
    // Push discovered suites as soon as the panel is ready
    setTimeout(() => this.pushDiscoveredSuites(), 300);
  }

  protected handleMessage(msg: { type: string; [key: string]: unknown }): void {
    switch (msg.type) {
      case "discoverSuites":
        this.pushDiscoveredSuites();
        break;
      case "runAll":
        this.runParallelTestCommand(buildTestAllCommand(), "all");
        break;
      case "runSuite":
        this.runSuite(msg.suite as string);
        break;
      case "runLua":
        this.runParallelTestCommand(buildLuaTestsCommand(), "lua");
        break;
      case "runGolden":
        this.runParallelTestCommand(buildTestTargetCommand("golden_tests"), "golden");
        break;
      case "stop":
        vscode.window.showInformationMessage("Use the terminal to cancel the running test.");
        break;
    }
  }

  private pushDiscoveredSuites(): void {
    const suites = this.discoverTestSuites();
    this.panel.webview.postMessage({ type: "suites", suites });
  }

  /** Scan tests/ directory for *_tests.rs and extract test function names. */
  private discoverTestSuites(): { name: string; tests: string[] }[] {
    const ws = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (!ws) return this.fallbackSuites();
    const testsDir = path.join(ws, "tests");
    if (!fs.existsSync(testsDir)) return this.fallbackSuites();

    const result: { name: string; tests: string[] }[] = [];
    const special = new Set(["golden_tests", "lua_tests"]);

    let files: string[];
    try { files = fs.readdirSync(testsDir); } catch { return this.fallbackSuites(); }

    for (const file of files.sort()) {
      if (!file.endsWith("_tests.rs")) continue;
      const suiteName = file.replace(/\.rs$/, "");
      if (special.has(suiteName)) continue; // listed separately
      const tests = this.extractTestNames(path.join(testsDir, file));
      result.push({ name: suiteName, tests });
    }

    // Add specials at the end
    result.push({ name: "lua_tests", tests: ["(lua vm tests — run via parallel_cargo.py test lua)"] });
    result.push({ name: "golden_tests", tests: ["(golden output tests — run via parallel_cargo.py test target golden_tests)"] });
    return result;
  }

  private extractTestNames(filePath: string): string[] {
    try {
      const src = fs.readFileSync(filePath, "utf8");
      const names: string[] = [];
      const re = /^\s*(?:#\[test\]\s*(?:#\[.*?\]\s*)*)?(?:async\s+)?fn\s+(\w+)/gm;
      let m: RegExpExecArray | null;
      // Only include functions preceded by #[test]
      const lines = src.split("\n");
      for (let i = 0; i < lines.length; i++) {
        if (lines[i].trimStart().startsWith("#[test]")) {
          // next non-blank, non-attr line should be the fn
          for (let j = i + 1; j < Math.min(i + 5, lines.length); j++) {
            const fnMatch = lines[j].match(/\bfn\s+(\w+)/);
            if (fnMatch) { names.push(fnMatch[1]); break; }
          }
        }
      }
      return names.length ? names : ["(no #[test] functions found)"];
    } catch {
      return ["(could not read file)"];
    }
  }

  private fallbackSuites(): { name: string; tests: string[] }[] {
    return KNOWN_MODULES.map((m) => ({ name: `${m}_tests`, tests: [`(run: python tools/dev/parallel_cargo.py test target ${m}_tests)`] }));
  }

  private runSuite(suite: string): void {
    const command = suite === "lua_tests"
      ? buildLuaTestsCommand()
      : buildTestTargetCommand(suite);
    this.runParallelTestCommand(command, suite);
  }

  private runParallelTestCommand(command: string, label: string): void {
    const existing = vscode.window.terminals.find((t) => t.name === "Lurek2D Tests");
    const terminal = existing ?? vscode.window.createTerminal("Lurek2D Tests");
    terminal.show();
    terminal.sendText(command);
    this.panel.webview.postMessage({ type: "testStarted", filter: label, command });
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Test Runner", `
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
    `, `
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            <button id="btnRunAll">${ICONS.play} Run All</button>
            <button id="btnRunLua">Run Lua</button>
            <button id="btnRunGolden">Run Golden</button>
            <button id="btnRunSelected">Run Selected</button>
          </div>
          ${toolbarSep()}
          <div class="group">
            <input id="filter" placeholder="Filter tests…" style="width:130px">
          </div>
          ${toolbarSpacer()}
          <span id="statusSummary" style="font-size:11px;color:var(--text-dim)">Discovering…</span>
        </div>

        <!-- Tree Panel -->
        <div class="tree-panel" id="treePanel"><div id="discovering">Scanning tests/ directory…</div></div>

        <!-- Output Panel -->
        <div class="output-panel" id="output">Tests run in the "Lurek2D Tests" terminal.\n\nSelect a suite and click "Run Selected", or click ▶ next to any suite name.</div>

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
    `, `
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
          document.getElementById('statusState').textContent = 'Running…';
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
          if (passCount) badges += '<span class="result-badge pass">' + passCount + ' ✓</span>';
          if (failCount) badges += '<span class="result-badge fail">' + failCount + ' ✗</span>';
          row.innerHTML = '<span>' + suite.name + badges + '</span>' +
            '<button class="suite-run-btn" data-suite="' + suite.name + '">▶</button>';
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
    `);
  }
}
