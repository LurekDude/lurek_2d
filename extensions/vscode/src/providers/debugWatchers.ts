import * as vscode from "vscode";

// ── Watcher entry ────────────────────────────────────────────

interface WatchEntry {
  id: number;
  expression: string;
  value: string;
  type: string;
  error?: string;
  lastUpdated: number;
}

// ── Panel state ───────────────────────────────────────────────

let _panel: vscode.WebviewPanel | undefined;
let _watches: WatchEntry[] = [];
let _nextId = 1;
let _connected = false;
let _refreshInterval: ReturnType<typeof setInterval> | undefined;

// eslint-disable-next-line @typescript-eslint/no-explicit-any
let _evalFn: ((expr: string) => Promise<{ value: string; type: string } | undefined>) | undefined;

/** Register the evaluator function from the debug bridge. */
export function setEvaluator(
  fn: (expr: string) => Promise<{ value: string; type: string } | undefined>,
): void {
  _evalFn = fn;
}

export function setConnected(connected: boolean): void {
  _connected = connected;
  if (!connected) {
    _watches.forEach((w) => { w.value = "–"; w.type = "?"; w.error = undefined; });
  }
  pushUpdate();
  if (connected) startAutoRefresh();
  else stopAutoRefresh();
}

// ── Auto-refresh ──────────────────────────────────────────────

function startAutoRefresh(): void {
  if (_refreshInterval) return;
  _refreshInterval = setInterval(() => { void refreshAll(); }, 1500);
}

function stopAutoRefresh(): void {
  if (_refreshInterval) { clearInterval(_refreshInterval); _refreshInterval = undefined; }
}

async function refreshAll(): Promise<void> {
  if (!_evalFn || !_connected || _watches.length === 0) return;
  for (const w of _watches) {
    try {
      const result = await _evalFn(w.expression);
      if (result) {
        w.value = result.value;
        w.type = result.type;
        w.error = undefined;
      } else {
        w.value = "nil";
        w.type = "nil";
      }
    } catch (e: unknown) {
      w.value = "–";
      w.type = "error";
      w.error = e instanceof Error ? e.message : String(e);
    }
    w.lastUpdated = Date.now();
  }
  pushUpdate();
}

// ── Panel management ──────────────────────────────────────────

export function openWatchersPanel(context: vscode.ExtensionContext): void {
  if (_panel) { _panel.reveal(vscode.ViewColumn.Two); return; }

  _panel = vscode.window.createWebviewPanel(
    "lurek.debugWatchers",
    "Lurek2D Watchers",
    vscode.ViewColumn.Two,
    { enableScripts: true, retainContextWhenHidden: true },
  );

  _panel.webview.html = buildHtml();
  _panel.onDidDispose(() => { _panel = undefined; stopAutoRefresh(); }, null, context.subscriptions);

  _panel.webview.onDidReceiveMessage(async (msg) => {
    switch (msg.type) {
      case "add":
        addWatch(msg.expression);
        await refreshAll();
        break;
      case "remove":
        _watches = _watches.filter((w) => w.id !== msg.id);
        pushUpdate();
        break;
      case "edit":
        editWatch(msg.id, msg.expression);
        await refreshAll();
        break;
      case "refresh":
        await refreshAll();
        break;
      case "clear":
        _watches = [];
        pushUpdate();
        break;
    }
  }, null, context.subscriptions);

  pushUpdate();
  if (_connected) startAutoRefresh();
}

function addWatch(expression: string): void {
  if (!expression.trim()) return;
  _watches.push({ id: _nextId++, expression: expression.trim(), value: "–", type: "?", lastUpdated: 0 });
  pushUpdate();
}

function editWatch(id: number, expression: string): void {
  const w = _watches.find((x) => x.id === id);
  if (w) { w.expression = expression.trim(); w.value = "–"; w.type = "?"; }
  pushUpdate();
}

function pushUpdate(): void {
  if (!_panel) return;
  _panel.webview.postMessage({ type: "update", watches: _watches, connected: _connected });
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
<h2>🔍 Lua Watchers
  <span class="status disconnected" id="status">Disconnected</span>
</h2>

<div class="add-row">
  <input id="newExpr" placeholder='Add expression…  e.g.  player.x  or  #bullets' onkeydown="onKey(event)">
  <button onclick="addWatch()">Add</button>
</div>

<div class="toolbar">
  <button onclick="refresh()" title="Refresh all">⟳ Refresh</button>
  <button onclick="clearAll()" title="Clear all watches">✕ Clear</button>
</div>

<table id="table">
  <thead><tr><th>Expression</th><th>Value</th><th>Type</th><th>Age</th><th></th></tr></thead>
  <tbody id="tbody"><tr><td colspan="5" class="empty">No watches yet — type an expression and press Add</td></tr></tbody>
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
  if (!ms) return '–';
  const s = Math.floor((Date.now() - ms) / 1000);
  if (s < 2) return 'just now';
  if (s < 60) return s + 's ago';
  return Math.floor(s / 60) + 'm ago';
}

function render() {
  const tbody = document.getElementById('tbody');
  if (_watches.length === 0) {
    tbody.innerHTML = '<tr><td colspan="5" class="empty">No watches yet — type an expression and press Add</td></tr>';
    return;
  }
  tbody.innerHTML = _watches.map(w => {
    const isEditing = _editingId === w.id;
    const exprCell = isEditing
      ? '<input data-edit-id="' + w.id + '" value="' + escHtml(w.expression) + '" onblur="commitEdit(' + w.id + ')" onkeydown="if(event.key===\'Enter\')commitEdit(' + w.id + ')">'
      : '<span class="expr" ondblclick="startEdit(' + w.id + ', \'' + escHtml(w.expression) + '\')">' + escHtml(w.expression) + '</span>';
    const valClass = 'value ' + (w.error ? 'error' : w.type);
    const displayVal = w.error ? '⚠ ' + escHtml(w.error) : escHtml(w.value);
    return '<tr>' +
      '<td class="expr">' + exprCell + '</td>' +
      '<td><span class="' + valClass + '" title="' + displayVal + '">' + displayVal + '</span></td>' +
      '<td><span class="type">' + escHtml(w.type) + '</span></td>' +
      '<td><span class="age">' + timeAgo(w.lastUpdated) + '</span></td>' +
      '<td><button class="icon" onclick="removeWatch(' + w.id + ')" title="Remove">✕</button></td>' +
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
</html>`;
}

// ── Export add-watch command (call from status bar / context menu) ──

export function addWatchFromEditor(editor: vscode.TextEditor): void {
  const selection = editor.selection;
  const word = editor.document.getText(selection.isEmpty
    ? editor.document.getWordRangeAtPosition(selection.active, /[\w.:\[\]"']+/)
    : selection);
  if (word) addWatch(word);
}
