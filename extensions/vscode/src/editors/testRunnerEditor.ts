import * as vscode from "vscode";
import * as path from "path";
import * as fs from "fs";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

// ── Static fallback — auto-updated from actual tests/ directory ──
const KNOWN_MODULES = [
  "ai","audio","cardgame","combat","compute","config","crafting","data",
  "dataframe","dialog","engine","entity","event","filesystem","graph",
  "graphics","graphics_ext","image","input","inventory","math","math_ext",
  "minimap","modding","particle","pathfinding","physics","postfx","quest",
  "resource","savegame","scene","sound","stats","thread","tilemap","timer",
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
        this.runCargoTest("", "all");
        break;
      case "runSuite":
        this.runCargoTest(msg.suite as string, msg.suite as string);
        break;
      case "runLua":
        this.runCargoTest("--test lua_tests", "lua");
        break;
      case "runGolden":
        this.runCargoTest("--test golden_tests", "golden");
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
    result.push({ name: "lua_tests", tests: ["(lua vm tests — run via cargo test --test lua_tests)"] });
    result.push({ name: "golden_tests", tests: ["(golden output tests — run via cargo test --test golden_tests)"] });
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
    return KNOWN_MODULES.map((m) => ({ name: `${m}_tests`, tests: [`(run: cargo test --test ${m}_tests)`] }));
  }

  private runCargoTest(filter: string, label: string): void {
    const existing = vscode.window.terminals.find((t) => t.name === "Lurek2D Tests");
    const terminal = existing ?? vscode.window.createTerminal("Lurek2D Tests");
    terminal.show();
    const cmd = filter ? `cargo test ${filter}` : "cargo test";
    terminal.sendText(cmd);
    this.panel.webview.postMessage({ type: "testStarted", filter: label });
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Test Runner", `
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
    `, `
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
          <span id="statusSummary" style="font-size:12px;color:var(--text-dim)">Discovering…</span>
        </div>
        <div class="panel tree-panel" id="treePanel"><div id="discovering">⟳ Scanning tests/ directory…</div></div>
        <div class="output-panel" id="output">Tests run in the "Lurek2D Tests" terminal.\n\nSelect a suite and click "Run Selected Suite", or click ▶ next to any suite name.</div>
        <div class="status-bar"><span id="statusBar">Ready</span></div>
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
          if (passCount) badges += '<span class="badge pass">' + passCount + '✓</span>';
          if (failCount) badges += '<span class="badge fail">' + failCount + '✗</span>';
          row.innerHTML = '<span>' + suite.name + badges + '</span>' +
            '<button class="suite-run-btn" data-suite="' + suite.name + '">▶</button>';
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
          TEST_SUITES.length + ' suites · ' + total + ' tests · ' + pass + ' pass · ' + fail + ' fail · ' + pending + ' pending';
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
