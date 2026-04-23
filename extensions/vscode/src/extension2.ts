import * as vscode from "vscode";
import * as path from "path";
import * as fs from "fs";
import { startMcpServer } from "./mcp/server.js";

// Services
import { LurekProcessService } from "./services/lurekProcess.js";
import { StatusBarService } from "./services/statusBar.js";
import { ApiDataService } from "./services/apiData.js";

// Sidebar providers
import {
  ProjectToolsProvider,
  DevToolsProvider,
  AiToolsProvider,
} from "./providers/sidebar.js";

// Language providers
import * as completionProvider from "./providers/completion.js";
import * as hoverProvider from "./providers/hover.js";
import * as signatureProvider from "./providers/signature.js";
import * as definitionProvider from "./providers/definition.js";
import * as referencesProvider from "./providers/references.js";
import * as symbolsProvider from "./providers/symbols.js";
import * as diagnosticsProvider from "./providers/diagnostics.js";
import * as colorProvider from "./providers/color.js";
import * as assetPathProvider from "./providers/assetPath.js";
import * as inlayHintsProvider from "./providers/inlayHints.js";
import * as codeActionsProvider from "./providers/codeActions.js";

// Phase 2b providers
import * as luajitHintsProvider from "./providers/luajitHints.js";
import * as typeInferenceProvider from "./providers/typeInference.js";
import * as requireGraphProvider from "./providers/requireGraph.js";
import * as symbolIndexService from "./services/symbolIndex.js";

// Phase 3 providers
import { register as registerFormatting } from "./providers/formatting.js";
import { register as registerFolding } from "./providers/folding.js";
import { register as registerRename } from "./providers/rename.js";
import { register as registerSemanticTokens } from "./providers/semanticTokens.js";

// New providers (Phase 4+)
import * as luacatsProvider from "./providers/luacatsProvider.js";
import { AssetExplorerProvider, findMissingAssets, insertAssetPath, AssetItem } from "./providers/assetExplorer.js";
import { openPerfDashboard } from "./providers/perfDashboard.js";
import * as codeLensProvider from "./providers/codeLens.js";
import { openWatchersPanel, addWatchFromEditor, setConnected as setWatchersConnected, setEvaluator as setWatchersEvaluator } from "./providers/debugWatchers.js";
import { openSystemMonitor } from "./providers/systemMonitor.js";
import { openApiUsageReport, quickInsertLurekApi } from "./providers/apiUsage.js";



// Commands
import { runGame, stopGame, runWithArgs, runExample } from "./commands/run.js";
import { scaffoldProject, scaffoldFile } from "./commands/scaffold.js";
import {
  testAll,
  testModule,
  testLuaAll,
  testLuaGolden,
} from "./commands/test.js";
import {
  packageZip,
  packageWindows,
  packageLinux,
} from "./commands/packaging.js";
import { registerEditorCommands } from "./commands/editors.js";
import {
  browseApi,
  openApiDocs,
  openWiki,
  depGraph,
  depList,
} from "./commands/reference.js";
import {
  installCag,
  selectAgent,
  selectSkill,
  selectPrompt,
} from "./commands/cag.js";
import { registerTestCommands } from "./commands/testGenerator.js";
import { DebugBridge } from "./services/debugBridge.js";
import { buildBuildCommand, buildCheckCommand } from "./services/parallelCargo.js";
import { registerDebugBridgeCommands } from "./commands/debugBridge.js";
import { registerGameJamCommands } from "./commands/gameJam.js";
import { registerLibraryCommands } from "./commands/library.js";
import { registerGameDevCagCommands } from "./commands/gameDevCag.js";
import { register as registerDebugger } from "./debug/luaDebugAdapter.js";

/** MCP server handle. */
let mcpProcess: ReturnType<typeof startMcpServer> | undefined;

/** Shared services. */
let lurekProcess: LurekProcessService;
let statusBar: StatusBarService;
let apiData: ApiDataService;
let debugBridge: DebugBridge;

/**
 * Activates the Lurek2D Toolkit extension.
 */
export function activate(context: vscode.ExtensionContext): void {
  // ─── Services ────────────────────────────────────────────
  lurekProcess = new LurekProcessService();
  statusBar = new StatusBarService();
  apiData = new ApiDataService();
  debugBridge = new DebugBridge();
  context.subscriptions.push(lurekProcess, statusBar, debugBridge);

  // Load API data asynchronously (providers work with partial data until loaded)
  apiData.load(context.extensionPath).catch((err) => {
    console.error("Failed to load Lurek2D API data:", err);
  });

  // Wire status bar to process events
  lurekProcess.onStatusChange((running) => {
    if (running) {
      statusBar.setRunning();
    } else {
      statusBar.setStopped();
    }
  });

  // ─── Sidebar Tree Views ──────────────────────────────────
  const projectTools = new ProjectToolsProvider();
  const devTools = new DevToolsProvider();
  const aiTools = new AiToolsProvider();

  context.subscriptions.push(
    vscode.window.registerTreeDataProvider("lurek.projectTools", projectTools),
    vscode.window.registerTreeDataProvider("lurek.devTools", devTools),
    vscode.window.registerTreeDataProvider("lurek.aiCopilot", aiTools)
  );

  // ─── Language Providers (IntelliSense) ───────────────────
  completionProvider.register(context, apiData);
  hoverProvider.register(context, apiData);
  signatureProvider.register(context, apiData);
  definitionProvider.register(context, apiData);
  referencesProvider.register(context, apiData);
  symbolsProvider.register(context, apiData);
  diagnosticsProvider.register(context, apiData);
  colorProvider.register(context, apiData);
  assetPathProvider.register(context, apiData);
  inlayHintsProvider.register(context, apiData);
  codeActionsProvider.register(context, apiData);

  // Phase 2b: Enhanced IntelliSense providers
  luajitHintsProvider.register(context, apiData);
  typeInferenceProvider.register(context, apiData);
  requireGraphProvider.register(context);
  symbolIndexService.register(context);
  // LuaCATS @class/@field annotation hover and completion
  luacatsProvider.register(context, apiData);

  // Phase 3: Formatting, folding, rename, semantic tokens
  registerFormatting(context, apiData);
  registerFolding(context, apiData);
  registerRename(context, apiData);
  registerSemanticTokens(context, apiData);

  // ─── Asset Explorer Tree View ────────────────────────────
  const assetExplorer = new AssetExplorerProvider();
  context.subscriptions.push(
    vscode.window.registerTreeDataProvider("lurek.assetExplorer", assetExplorer),
  );

  // ─── Run Commands ────────────────────────────────────────
  registerCommand(context, "lurek.runGame", () => runGame(lurekProcess));
  registerCommand(context, "lurek.stopGame", () => stopGame(lurekProcess));
  registerCommand(context, "lurek.runWithArgs", () => runWithArgs(lurekProcess));
  registerCommand(context, "lurek.runExample", () => runExample(lurekProcess));

  // ─── Test Commands ───────────────────────────────────────
  registerCommand(context, "lurek.test.all", () => testAll());

  // Rust module tests
  const rustModules = [
    "ai", "audio", "cardgame", "combat", "compute", "config", "crafting",
    "data", "dataframe", "dialog", "engine", "ecs", "event", "filesystem",
    "graph", "render", "graphics_ext", "image", "input", "inventory",
    "math", "math_ext", "minimap", "mods", "particle", "pathfind",
    "physics", "postfx", "quest", "resource", "save", "scene", "sound",
    "stats", "thread", "tilemap", "timer",
  ];
  for (const mod of rustModules) {
    registerCommand(context, `lurek.test.rust.${mod}`, () => testModule(mod));
  }

  registerCommand(context, "lurek.test.lua.all", () => testLuaAll());
  registerCommand(context, "lurek.test.lua.golden", () => testLuaGolden());

  // Test generator commands (Phase 4)
  registerTestCommands(context);

  // ─── Scaffold Commands ───────────────────────────────────
  registerCommand(context, "lurek.scaffold.project", () => scaffoldProject());
  registerCommand(context, "lurek.scaffold.file", () => scaffoldFile());

  // ─── Refactor Commands ───────────────────────────────────
  registerCommand(context, "lurek.extractToModuleFile",
    async (...args: unknown[]) => {
      const uri = args[0] as vscode.Uri | undefined;
      const range = args[1] as vscode.Range | undefined;
      if (!uri || !range) return;
      const moduleName = await vscode.window.showInputBox({
        prompt: "New module file name (without .lua)",
        placeHolder: "my_module",
        validateInput: v => /^[a-z_][a-z0-9_]*$/i.test(v) ? null : "Use letters, digits, underscores",
      });
      if (!moduleName) return;
      const doc = await vscode.workspace.openTextDocument(uri);
      const selectedText = doc.getText(range);
      const folder = uri.fsPath.replace(/[/\\][^/\\]+$/, "");
      const newUri = vscode.Uri.file(`${folder}/${moduleName}.lua`);
      const we = new vscode.WorkspaceEdit();
      we.createFile(newUri, { ignoreIfExists: true });
      we.insert(newUri, new vscode.Position(0, 0),
        `-- ${moduleName}.lua\nlocal M = {}\n\n${selectedText}\n\nreturn M\n`);
      we.replace(uri, range, `require("${moduleName}")`);
      await vscode.workspace.applyEdit(we);
      await vscode.window.showTextDocument(newUri);
    },
  );

  // ─── Package Commands ────────────────────────────────────
  registerCommand(context, "lurek.package.zip", () => packageZip());
  registerCommand(context, "lurek.package.windows", () => packageWindows());
  registerCommand(context, "lurek.package.linux", () => packageLinux());

  // ─── Editor Commands ─────────────────────────────────────
  context.subscriptions.push(...registerEditorCommands(context));

  // ─── Asset Explorer Commands ─────────────────────────────
  registerCommand(context, "lurek.assets.refresh", () => assetExplorer.refresh());
  registerCommand(context, "lurek.assets.openPanel", () => {
    vscode.window.showInformationMessage("Asset Explorer is in the sidebar under Lurek2D.");
  });
  registerCommand(context, "lurek.assets.findMissing", () => findMissingAssets());
  registerCommand(context, "lurek.assets.insertPath", (item: unknown) => {
    if (item instanceof AssetItem) insertAssetPath(item);
  });

  // ─── Performance Dashboard Commands ─────────────────────
  registerCommand(context, "lurek.perf.openDashboard", () => openPerfDashboard(context));
  registerCommand(context, "lurek.perf.clearHistory", () => {
    const { clearHistory } = require("./providers/perfDashboard.js") as typeof import("./providers/perfDashboard.js");
    clearHistory();
  });
  registerCommand(context, "lurek.perf.openHotReload", () => {
    const panel = vscode.window.createWebviewPanel(
      "lurek.hotReload", "Hot-Reload History", vscode.ViewColumn.Two,
      { enableScripts: true, retainContextWhenHidden: true }
    );
    const events: { time: string; file: string; status: string }[] = [];
    const wsRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? "";
    const watcher = vscode.workspace.createFileSystemWatcher(
      new vscode.RelativePattern(wsRoot, "**/*.lua")
    );
    const push = (file: vscode.Uri, status: string) => {
      events.unshift({ time: new Date().toLocaleTimeString(), file: vscode.workspace.asRelativePath(file), status });
      if (events.length > 200) events.pop();
      panel.webview.postMessage({ type: "events", events });
    };
    watcher.onDidChange((u) => push(u, "changed"));
    watcher.onDidCreate((u) => push(u, "created"));
    watcher.onDidDelete((u) => push(u, "deleted"));
    panel.onDidDispose(() => watcher.dispose());
    panel.webview.html = `<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline';"><style>body{font-family:var(--vscode-font-family);background:var(--vscode-editor-background);color:var(--vscode-foreground);padding:12px;margin:0;font-size:12px}h2{margin:0 0 10px;font-size:14px}table{border-collapse:collapse;width:100%}th,td{border:1px solid var(--vscode-panel-border,#444);padding:4px 8px;text-align:left}th{background:var(--vscode-editorWidget-background,#1e1e1e)}.changed{color:#4ec9b0}.created{color:#dcdcaa}.deleted{color:#f44747}#empty{opacity:.5;margin-top:20px}</style></head><body><h2>\uD83D\uDD04 Hot-Reload File Watcher</h2><p id="empty">Watching *.lua files \u2014 save a file to see events here.</p><table id="tbl" style="display:none"><thead><tr><th>Time</th><th>File</th><th>Status</th></tr></thead><tbody id="body"></tbody></table><script>window.addEventListener('message',e=>{const{events}=e.data;if(!events||!events.length)return;document.getElementById('empty').style.display='none';document.getElementById('tbl').style.display='';document.getElementById('body').innerHTML=events.map(ev=>'<tr><td>'+ev.time+'</td><td>'+ev.file+'</td><td class="'+ev.status+'">'+ev.status+'</td></tr>').join('');});<\/script></body></html>`;
  });

  // ─── Dependency Graph Commands ───────────────────────────
  registerCommand(context, "lurek.deps.showGraph", () => depGraph(context));
  registerCommand(context, "lurek.deps.findCircular", async () => {
    const wsRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (!wsRoot) { vscode.window.showErrorMessage("No workspace folder open."); return; }
    const out = vscode.window.createOutputChannel("Lurek2D Circular Deps");
    out.show(true);
    out.appendLine("\uD83D\uDD0D Scanning for circular dependencies...");
    const nodeFsModule = require("fs") as typeof import("fs");
    const nodePathModule = require("path") as typeof import("path");
    const srcDir = nodePathModule.join(wsRoot, "src");
    if (!nodeFsModule.existsSync(srcDir)) { out.appendLine("src/ directory not found."); return; }
    const modules = nodeFsModule.readdirSync(srcDir, { withFileTypes: true }).filter((e: import('fs').Dirent) => e.isDirectory()).map((e: import('fs').Dirent) => e.name);
    const adj: Record<string, string[]> = {};
    for (const mod of modules) {
      adj[mod] = [];
      const modFile = nodePathModule.join(srcDir, mod, "mod.rs");
      if (!nodeFsModule.existsSync(modFile)) continue;
      const src = nodeFsModule.readFileSync(modFile, "utf-8");
      for (const m of src.matchAll(/use crate::([a-z_]+)/g)) {
        if (m[1] !== mod && modules.includes(m[1]) && !adj[mod].includes(m[1])) adj[mod].push(m[1]);
      }
    }
    const indexMap: Record<string, number> = {}, lowlink: Record<string, number> = {}, onStack: Record<string, boolean> = {}, stack: string[] = []; let idx = 0; const sccs: string[][] = [];
    function strongconnect(v: string) {
      indexMap[v] = lowlink[v] = idx++; stack.push(v); onStack[v] = true;
      for (const w of (adj[v] || [])) { if (indexMap[w] === undefined) { strongconnect(w); lowlink[v] = Math.min(lowlink[v], lowlink[w]); } else if (onStack[w]) { lowlink[v] = Math.min(lowlink[v], indexMap[w]); } }
      if (lowlink[v] === indexMap[v]) { const scc: string[] = []; let w: string; do { w = stack.pop()!; onStack[w] = false; scc.push(w); } while (w !== v); if (scc.length > 1) sccs.push(scc); }
    }
    for (const v of modules) { if (indexMap[v] === undefined) strongconnect(v); }
    if (sccs.length === 0) { out.appendLine("\u2705 No circular dependencies found."); } else { out.appendLine(`\u26A0\uFE0F  Found ${sccs.length} circular dependency cycle(s):`); sccs.forEach((scc, i) => out.appendLine(`  Cycle ${i+1}: ${scc.join(" \u2192 ")} \u2192 ${scc[scc.length-1]}`)); }
    out.appendLine("\nDone.");
  });
  registerCommand(context, "lurek.deps.findOrphans", async () => {
    const wsRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (!wsRoot) { vscode.window.showErrorMessage("No workspace folder open."); return; }
    const out = vscode.window.createOutputChannel("Lurek2D Orphan Modules");
    out.show(true);
    out.appendLine("\uD83D\uDD0D Scanning for orphan modules...");
    const nodeFsModule = require("fs") as typeof import("fs");
    const nodePathModule = require("path") as typeof import("path");
    const srcDir = nodePathModule.join(wsRoot, "src");
    if (!nodeFsModule.existsSync(srcDir)) { out.appendLine("src/ not found."); return; }
    const modules = nodeFsModule.readdirSync(srcDir, { withFileTypes: true }).filter((e: import('fs').Dirent) => e.isDirectory()).map((e: import('fs').Dirent) => e.name);
    const libRs = nodePathModule.join(wsRoot, "src", "lib.rs");
    const libContent = nodeFsModule.existsSync(libRs) ? nodeFsModule.readFileSync(libRs, "utf-8") : "";
    const referencedInLib = new Set(modules.filter((m: string) => libContent.includes(`pub mod ${m}`) || libContent.includes(`mod ${m}`)));
    const referencedByOthers = new Set<string>();
    for (const mod of modules) { const modFile = nodePathModule.join(srcDir, mod, "mod.rs"); if (!nodeFsModule.existsSync(modFile)) continue; const src = nodeFsModule.readFileSync(modFile, "utf-8"); for (const m of src.matchAll(/use crate::([a-z_]+)/g)) if (m[1] !== mod) referencedByOthers.add(m[1]); }
    const orphans = modules.filter((m: string) => !referencedInLib.has(m) && !referencedByOthers.has(m));
    if (orphans.length === 0) { out.appendLine("\u2705 No orphan modules found \u2014 all modules are referenced."); } else { out.appendLine(`\u26A0\uFE0F  Found ${orphans.length} potentially orphaned module(s):`); orphans.forEach((m: string) => out.appendLine(`  \u2022 ${m}`)); }
    out.appendLine("\nDone.");
  });

  // ─── New Phase 5 providers ───────────────────────────────
  codeLensProvider.register(context, apiData);

  // ─── Debug Watchers + System Monitor ────────────────────
  registerCommand(context, "lurek.debug.openWatchers", () => openWatchersPanel(context));
  registerCommand(context, "lurek.debug.openInspector", () => {
    const panel = vscode.window.createWebviewPanel(
      "lurekVariableInspector",
      "Lurek2D Variable Inspector",
      vscode.ViewColumn.Two,
      { enableScripts: true, retainContextWhenHidden: true }
    );
    const getHtml = (entries: Array<{expr: string; value: string; type: string}>) => `<!DOCTYPE html><html><head>
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
<h2>🔍 Variable Inspector</h2>
<div class="toolbar">
  <input id="expr" type="text" placeholder="Enter Lua expression, e.g. player.x" />
  <button onclick="addExpr()">Watch</button>
  <button onclick="clearAll()">Clear</button>
</div>
<table>
  <thead><tr><th>Expression</th><th>Value</th><th>Type</th></tr></thead>
  <tbody id="rows">${entries.length === 0
    ? '<tr><td colspan="3" class="empty">No watched expressions. Enter a Lua expression above.</td></tr>'
    : entries.map(e => `<tr><td>${e.expr}</td><td class="val">${e.value}</td><td class="type">${e.type}</td></tr>`).join("")}</tbody>
</table>
<script>
  const vscode = acquireVsCodeApi();
  function addExpr(){ const e=document.getElementById('expr'); if(e.value.trim()) vscode.postMessage({cmd:'watch',expr:e.value.trim()}); e.value=''; }
  function clearAll(){ vscode.postMessage({cmd:'clear'}); }
  document.getElementById('expr').addEventListener('keydown',e=>{ if(e.key==='Enter') addExpr(); });
  window.addEventListener('message',e=>{ if(e.data.cmd==='refresh') location.reload(); });
</script>
</body></html>`;

    const watches: Array<{expr: string; value: string; type: string}> = [];
    panel.webview.html = getHtml(watches);

    panel.webview.onDidReceiveMessage(async (msg) => {
      if (msg.cmd === "watch") {
        // Try to evaluate against debug bridge if connected, else show placeholder
        let value = "(not connected — run game with debug bridge)";
        let type = "?";
        try {
          const { DebugBridge } = await import("./services/debugBridge");
          if (DebugBridge.instance?.isConnected()) {
            const result = await DebugBridge.instance.evaluate(msg.expr);
            value = result?.resultString ?? "(nil)";
            type = result?.luaType ?? "?";
          }
        } catch (_) { /* bridge not available */ }
        watches.push({ expr: msg.expr, value, type });
        panel.webview.html = getHtml(watches);
      } else if (msg.cmd === "clear") {
        watches.length = 0;
        panel.webview.html = getHtml(watches);
      }
    }, undefined, context.subscriptions);
  });
  registerCommand(context, "lurek.debug.openCallStack", () => {
    vscode.window.showInformationMessage("Call stack available when connected to the Lua debug bridge.");
  });
  registerCommand(context, "lurek.debug.addWatch", () => {
    const editor = vscode.window.activeTextEditor;
    if (editor) addWatchFromEditor(editor);
  });
  registerCommand(context, "lurek.runtime.openMonitor", () => openSystemMonitor(context));
  registerCommand(context, "lurek.api.usageReport", () => openApiUsageReport(context));
  registerCommand(context, "lurek.api.quickInsert", () => quickInsertLurekApi(apiData));

  // Wire watchers to debug bridge events (if debug bridge exposes events)
  if (typeof (debugBridge as unknown as { onConnected?: (fn: () => void) => void }).onConnected === "function") {
    const bridge = debugBridge as unknown as {
      onConnected: (fn: () => void) => void;
      onDisconnected?: (fn: () => void) => void;
      evaluate?: (e: string) => Promise<string>;
    };
    bridge.onConnected(() => setWatchersConnected(true));
    bridge.onDisconnected?.(() => setWatchersConnected(false));
    if (bridge.evaluate) {
      setWatchersEvaluator(async (expr) => {
        try {
          const raw = await bridge.evaluate!(expr);
          return { value: String(raw), type: typeof raw };
        } catch { return undefined; }
      });
    }
  }

  // ─── Reference Commands ──────────────────────────────────
  registerCommand(context, "lurek.browseApi", () => browseApi());
  registerCommand(context, "lurek.openApiDocs", () => openApiDocs());
  registerCommand(context, "lurek.openWiki", () => openWiki());
  registerCommand(context, "lurek.depGraph", () => depGraph(context));
  registerCommand(context, "lurek.depList", () => depList());
  registerCommand(context, "lurek.apiCoverage", () => {
    const terminal = vscode.window.createTerminal("Lurek2D API Coverage");
    terminal.show();
    terminal.sendText("python tools/integration_coverage.py");
  });

  // ─── Debug Bridge Commands (Phase 4) ──────────────────────
  registerDebugBridgeCommands(context, debugBridge);

  // ─── DAP Lua Debugger ────────────────────────────────────
  registerDebugger(context);

  // ── lurek.debug.runAndConnect — start game then auto-connect ──
  registerCommand(context, "lurek.debug.runAndConnect", async () => {
    await runGame(lurekProcess);
    // Give the engine a moment to boot before trying to connect
    await new Promise<void>((res) => setTimeout(res, 1500));
    const ok = await debugBridge.connect();
    if (ok) {
      vscode.commands.executeCommand("setContext", "lurek.debugConnected", true);
      debugBridge.startStatsPolling();
      vscode.window.showInformationMessage("Lurek2D started and debug bridge connected.");
    } else {
      vscode.window.showWarningMessage(
        "Game launched but debug bridge could not connect. Is debug bridge enabled in conf.lua?"
      );
    }
  });

  // ── lurek.debug.performance — live engine stats webview ───────
  registerCommand(context, "lurek.debug.performance", () => {
    if (!debugBridge.isConnected) {
      vscode.window.showErrorMessage("Not connected to Lurek2D engine. Run 'Lurek2D: Debug Connect' first.");
      return;
    }
    const panel = vscode.window.createWebviewPanel(
      "lurek.debugPerf",
      "Lurek2D Live Performance",
      vscode.ViewColumn.Two,
      { enableScripts: true, retainContextWhenHidden: true },
    );
    panel.webview.html = `<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
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
<h2>⚡ Live Engine Stats</h2>
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
</script></body></html>`;
    const perfInterval = setInterval(async () => {
      if (!debugBridge.isConnected) { clearInterval(perfInterval); return; }
      try {
        const stats = await debugBridge.getStats();
        panel.webview.postMessage({ type: "stats", ...stats });
      } catch { /* ignore */ }
    }, 500);
    panel.onDidDispose(() => clearInterval(perfInterval));
  });

  // ── lurek.debug.printHistory — show debug output channel ──────
  registerCommand(context, "lurek.debug.printHistory", () => {
    debugBridge.showOutput();
  });

  // ── lurek.debug.screenshot — save screenshot from engine ──────
  registerCommand(context, "lurek.debug.screenshot", async () => {
    if (!debugBridge.isConnected) {
      vscode.window.showErrorMessage("Not connected to Lurek2D engine. Run 'Lurek2D: Debug Connect' first.");
      return;
    }
    try {
      const b64 = await debugBridge.takeScreenshot();
      if (!b64) {
        vscode.window.showWarningMessage("Engine did not return screenshot data.");
        return;
      }
      const buf = Buffer.from(b64, "base64");
      const wsFolder = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
      if (!wsFolder) { vscode.window.showErrorMessage("No workspace folder."); return; }
      const ts = new Date().toISOString().replace(/[:.]/g, "-");
      const outPath = require("path").join(wsFolder, `screenshot-${ts}.png`);
      require("fs").writeFileSync(outPath, buf);
      const uri = vscode.Uri.file(outPath);
      await vscode.commands.executeCommand("vscode.open", uri);
      vscode.window.showInformationMessage(`Screenshot saved: screenshot-${ts}.png`);
    } catch (err) {
      vscode.window.showErrorMessage(`Screenshot failed: ${err instanceof Error ? err.message : String(err)}`);
    }
  });

  // ── lurek.debug.callStack — show current Lua call stack ───────
  registerCommand(context, "lurek.debug.callStack", async () => {
    if (!debugBridge.isConnected) {
      vscode.window.showErrorMessage("Not connected to Lurek2D engine. Run 'Lurek2D: Debug Connect' first.");
      return;
    }
    try {
      const frames = await debugBridge.getCallStack();
      if (frames.length === 0) {
        vscode.window.showInformationMessage("Call stack is empty (game may not be paused).");
        return;
      }
      const items = frames.map((f) => ({
        label: `#${f.level} ${f.name}`,
        description: `${f.source}:${f.line}`,
        detail: `${f.source} line ${f.line}`,
        source: f.source,
        line: f.line,
      }));
      const picked = await vscode.window.showQuickPick(items, {
        title: "Lua Call Stack",
        placeHolder: "Select a frame to navigate to",
      });
      if (picked?.source && picked.source !== "?" && picked.source !== "[C]") {
        const relPath = picked.source.startsWith("@") ? picked.source.slice(1) : picked.source;
        const wsFolder = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
        if (wsFolder) {
          const filePath = require("path").join(wsFolder, relPath);
          if (require("fs").existsSync(filePath)) {
            const doc = await vscode.workspace.openTextDocument(filePath);
            await vscode.window.showTextDocument(doc, {
              selection: new vscode.Range(picked.line - 1, 0, picked.line - 1, 0),
            });
          }
        }
      }
    } catch (err) {
      vscode.window.showErrorMessage(`Call stack failed: ${err instanceof Error ? err.message : String(err)}`);
    }
  });

  // ── lurek.debug.status — connection status info ────────────────
  registerCommand(context, "lurek.debug.status", async () => {
    const info = debugBridge.getStatusInfo();
    if (!info.connected) {
      const choice = await vscode.window.showInformationMessage(
        `Lurek2D debug bridge: NOT connected (port ${info.port})`,
        "Connect Now",
        "Dismiss",
      );
      if (choice === "Connect Now") {
        vscode.commands.executeCommand("lurek.debug.connect");
      }
    } else {
      try {
        const stats = await debugBridge.getStats();
        vscode.window.showInformationMessage(
          `Lurek2D connected on port ${info.port} · FPS: ${stats.fps} · Draw calls: ${stats.drawCalls} · Memory: ${(stats.memory / 1024 / 1024).toFixed(1)} MB`,
        );
      } catch {
        vscode.window.showInformationMessage(`Lurek2D debug bridge connected on port ${info.port}.`);
      }
    }
  });

  // ─── CAG Commands ────────────────────────────────────────
  registerCommand(context, "lurek.cag.install", () => installCag());
  registerCommand(context, "lurek.cag.selectAgent", () => selectAgent());
  registerCommand(context, "lurek.cag.selectSkill", () => selectSkill());
  registerCommand(context, "lurek.cag.selectPrompt", () => selectPrompt());
  registerCommand(context, "lurek.cag.update", () => {
    vscode.window.showInformationMessage(
      "CAG update is not yet implemented."
    );
  });

  // ─── MCP Commands ────────────────────────────────────────
  registerCommand(context, "lurek.mcp.install", () => {
    vscode.window.showInformationMessage(
      "MCP server installation is not yet implemented."
    );
  });
  registerCommand(context, "lurek.mcp.status", () => {
    vscode.window.showInformationMessage(
      mcpProcess ? "MCP server is running." : "MCP server is not running."
    );
  });

  // ─── Game Jam Commands (Phase 5a) ─────────────────────────
  registerGameJamCommands(context);
  registerCommand(context, "lurek.jam.quickBuild", () => {
    const terminal = vscode.window.createTerminal("Lurek2D Quick Build");
    terminal.show();
    terminal.sendText(buildBuildCommand("release"));
  });
  registerCommand(context, "lurek.jam.checklist", () => {
    vscode.window.showInformationMessage(
      "Submission Checklist is not yet implemented."
    );
  });

  // ─── Library Commands (Phase 5a) ──────────────────────────
  registerLibraryCommands(context);

  // ─── Game Dev CAG Commands ────────────────────────────────
  registerGameDevCagCommands(context);

  // ─── Legacy Backward Compat (lurek2d.* → lurek.*) ─────────
  registerCommand(context, "lurek2d.runExample", () => runExample(lurekProcess));
  registerCommand(context, "lurek2d.listExamples", () => runExample(lurekProcess));
  registerCommand(context, "lurek2d.checkBuild", () => {
    const terminal = vscode.window.createTerminal("Lurek2D Build Check");
    terminal.show();
    terminal.sendText(buildCheckCommand());
  });
  registerCommand(context, "lurek2d.getApiDoc", () => browseApi());

  // ─── Scan All Games (bulk diagnostic) ────────────────────
  registerCommand(context, "lurek2d.scanAllGames", async () => {
    const wsRoot = getWorkspaceRoot();
    if (!wsRoot) {
      vscode.window.showErrorMessage("No workspace open.");
      return;
    }
    const uris = await vscode.workspace.findFiles("content/games/**/main.lua", "**/node_modules/**");
    if (uris.length === 0) {
      vscode.window.showInformationMessage("No game main.lua files found.");
      return;
    }

    await vscode.window.withProgress(
      { location: vscode.ProgressLocation.Notification, title: `Scanning ${uris.length} games…`, cancellable: false },
      async (progress) => {
        let done = 0;
        for (const uri of uris) {
          try {
            const doc = await vscode.workspace.openTextDocument(uri);
            // Opening the document triggers the diagnostics provider automatically.
            await vscode.window.showTextDocument(doc, { preview: true, preserveFocus: true });
          } catch {
            // skip unreadable files
          }
          done++;
          progress.report({ increment: (100 / uris.length), message: `${done}/${uris.length}` });
        }
      }
    );

    // Show Problems panel
    await vscode.commands.executeCommand("workbench.action.problems.focus");
    vscode.window.showInformationMessage(`Scanned ${uris.length} games. Check the Problems panel for errors.`);
  });

  // ─── MCP Server ──────────────────────────────────────────
  const workspaceRoot = getWorkspaceRoot();
  if (workspaceRoot) {
    mcpProcess = startMcpServer(workspaceRoot);
  }

  // ─── Lua Language Server Integration ──────────────────
  configureLuaWorkspaceLibrary(context);

  // ─── Settings Change Listener ──────────────────────────
  context.subscriptions.push(
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration("lurek.luaVersion")) {
        apiData.load(context.extensionPath).catch((err) => {
          console.error("Failed to reload Lurek2D API data:", err);
        });
        configureLuaWorkspaceLibrary(context);
      }
    })
  );

  // ─── Context Keys ───────────────────────────────────────
  vscode.commands.executeCommand("setContext", "lurek.gameRunning", false);
}

/**
 * Deactivates the extension.
 */
export function deactivate(): void {
  if (mcpProcess) {
    mcpProcess.kill();
    mcpProcess = undefined;
  }
}

/** Helper to register a command and push to subscriptions. */
function registerCommand(
  context: vscode.ExtensionContext,
  id: string,
  handler: (...args: unknown[]) => unknown
): void {
  context.subscriptions.push(
    vscode.commands.registerCommand(id, handler)
  );
}

function getWorkspaceRoot(): string | undefined {
  return vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
}

/**
 * Configures lua-language-server (sumneko.lua) to include the lurek2d LuaCATS
 * type definitions and sets the Lua runtime version to match lurek.luaVersion.
 */
function configureLuaWorkspaceLibrary(context: vscode.ExtensionContext): void {
  // Prefer the workspace's own docs/api/ folder (always up-to-date),
  // fallback to the bundled data/ folder inside the extension.
  const wsRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  const wsDocsApi = wsRoot ? path.join(wsRoot, "docs", "api") : undefined;
  const bundledData = path.join(context.extensionPath, "data");
  const annotationsDir = (wsDocsApi && fs.existsSync(path.join(wsDocsApi, "lurek.lua")))
    ? wsDocsApi
    : bundledData;

  const luaConfig = vscode.workspace.getConfiguration("Lua");

  // Add the annotations folder to Lua.workspace.library
  const currentLibrary: string[] = luaConfig.get<string[]>("workspace.library") ?? [];
  if (!currentLibrary.includes(annotationsDir)) {
    // Remove any old bundledData entry so we don't accumulate stale entries
    const filtered = currentLibrary.filter((p) => !p.includes("lurek2d-toolkit"));
    const updated = [...filtered, annotationsDir];
    luaConfig
      .update("workspace.library", updated, vscode.ConfigurationTarget.Global)
      .then(undefined, () => {/* ignore if not installed */});
  }

  // Sync Lua.runtime.version to lurek.luaVersion
  const lurekVersion = vscode.workspace
    .getConfiguration("lurek")
    .get<string>("luaVersion", "luajit");
  const runtimeVersion = lurekVersion === "lua54" ? "Lua 5.4" : "LuaJIT";
  luaConfig
    .update("runtime.version", runtimeVersion, vscode.ConfigurationTarget.Global)
    .then(undefined, () => {/* ignore if not installed */});
}
