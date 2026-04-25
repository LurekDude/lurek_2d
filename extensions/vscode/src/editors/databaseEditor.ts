import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

export class DatabaseEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): DatabaseEditor {
    return new DatabaseEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.editor.database", "Database Browser");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "data.lua");
        break;
      case "exportToml":
        this.exportToml(msg.content as string, "data.toml");
        break;
      case "importCsv":
        this.importCsv();
        break;
    }
  }

  private async importCsv(): Promise<void> {
    const uri = await vscode.window.showOpenDialog({
      filters: { "CSV Files": ["csv"], "TOML Files": ["toml"] },
    });
    if (uri && uri[0]) {
      const data = await vscode.workspace.fs.readFile(uri[0]);
      const text = new (globalThis as any).TextDecoder().decode(data) as string;
      this.panel.webview.postMessage({ type: "csvData", content: text, name: uri[0].fsPath });
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Database Browser", `
      .editor-layout {
        display: grid; grid-template-columns: 180px 1fr;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .table-list { grid-row: 2; background: var(--surface); border-right: 1px solid var(--border); overflow-y: auto; }
      .data-area { grid-row: 2; overflow: auto; display: flex; flex-direction: column; }

      .table-item {
        padding: 5px 10px; cursor: pointer; border-radius: var(--radius); margin: 1px 4px;
        font-size: 12px; display: flex; align-items: center; gap: 6px; transition: background 0.08s;
      }
      .table-item:hover { background: var(--hover); }
      .table-item.selected { background: var(--selection); }
      .table-item .count { font-size: 10px; color: var(--text-dim); margin-left: auto; font-family: var(--font-mono); }

      .filter-bar {
        display: flex; gap: 4px; padding: 6px 8px; border-bottom: 1px solid var(--border);
        background: var(--surface); align-items: center;
      }
      .filter-bar input { flex: 1; }
      .filter-bar label { font-size: 10px; color: var(--text-dim); text-transform: uppercase; }

      .data-grid { width: 100%; border-collapse: collapse; font-size: 12px; }
      .data-grid th {
        background: var(--surface-2); border: 1px solid var(--border); padding: 4px 8px;
        text-align: left; cursor: pointer; user-select: none; position: sticky; top: 0; z-index: 1;
        font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.3px;
      }
      .data-grid th:hover { background: var(--accent); color: var(--bg); }
      .data-grid td { border: 1px solid var(--border); padding: 3px 6px; font-family: var(--font-mono); font-size: 11px; }
      .data-grid tr:hover td { background: var(--hover); }
      .data-grid tr.selected td { background: var(--selection); }
      .data-grid td.editing { padding: 0; }
      .data-grid td.editing input { width: 100%; border: none; background: var(--selection); color: var(--text); padding: 3px 6px; font-family: var(--font-mono); font-size: 11px; }
      .data-grid .type-hint { font-size: 9px; color: var(--text-dim); font-weight: 400; text-transform: none; }
      .data-grid .sort-indicator { margin-left: 2px; }

      .col-type-select { font-size: 10px; padding: 1px 4px; margin-left: 4px; }
    `, `
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            ${iconButton('add', { id: 'btnNewTable', title: 'New Table' })}
            ${iconButton('trash', { id: 'btnDeleteTable', title: 'Delete Table', cls: 'danger' })}
          </div>
          ${toolbarSep()}
          <div class="group">
            ${iconButton('add', { id: 'btnAddRow', title: 'Add Row' })}
            <button id="btnAddCol" title="Add Column">+ Col</button>
            ${iconButton('trash', { id: 'btnDeleteRow', title: 'Delete Selected Row', cls: 'danger' })}
          </div>
          ${toolbarSep()}
          <div class="group">
            ${iconButton('undo', { id: 'btnUndo', title: 'Undo (Ctrl+Z)' })}
            ${iconButton('redo', { id: 'btnRedo', title: 'Redo (Ctrl+Y)' })}
          </div>
          ${toolbarSep()}
          <button id="btnImport">${ICONS.importFile} Import</button>
          ${toolbarSpacer()}
          <div class="group">
            ${iconButton('copy', { id: 'btnCopyLua', title: 'Copy Lua Code' })}
            ${iconButton('insert', { id: 'btnInsert', title: 'Insert to Editor' })}
          </div>
          ${toolbarSep()}
          <button id="btnExport" class="primary">${ICONS.exportFile} Export ▾</button>
        </div>

        <!-- Table List -->
        <div class="table-list">
          ${panelSection('Tables', '<div id="tableList"></div>')}
        </div>

        <!-- Data Area -->
        <div class="data-area">
          <div class="filter-bar"><label>Filter:</label><input id="filterInput" placeholder="column:value or free text"></div>
          <div style="flex:1;overflow:auto">
            <table class="data-grid"><thead id="gridHead"></thead><tbody id="gridBody"></tbody></table>
          </div>
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusTables" class="badge">0 tables</span>
          </span>
          <div class="sep"></div>
          <span id="statusRows">0 rows</span>
          <div class="sep"></div>
          <span id="statusCols">0 columns</span>
          <div class="spacer"></div>
          <span id="statusSelected">No selection</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${ICONS.clean}</span>
        </div>
      </div>
    `, `
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
      const undo = new UndoStack(80);

      function snapshot() { return JSON.parse(JSON.stringify({ tables, currentTable, selectedRow })); }
      function restoreSnap(s) { tables = s.tables; currentTable = s.currentTable; selectedRow = s.selectedRow; refreshAll(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      function refreshTableList() {
        const el = document.getElementById('tableList');
        el.innerHTML = '';
        for (const name of Object.keys(tables)) {
          const div = document.createElement('div');
          div.className = 'table-item' + (name === currentTable ? ' selected' : '');
          div.innerHTML = '<span style="flex:1">' + name + '</span><span class="count">' + tables[name].rows.length + '</span>';
          div.addEventListener('click', () => { currentTable = name; selectedRow = -1; sortCol = -1; refreshAll(); });
          el.appendChild(div);
        }
      }

      function refreshGrid() {
        const t = tables[currentTable];
        if (!t) { document.getElementById('gridHead').innerHTML = ''; document.getElementById('gridBody').innerHTML = ''; updateStatus(); return; }
        const th = document.getElementById('gridHead');
        th.innerHTML = '<tr><th style="width:30px">#</th>' + t.columns.map((c, i) =>
          '<th data-col="' + i + '">' + c + ' <span class="type-hint">' + t.types[i] + '</span>' +
          (sortCol === i ? '<span class="sort-indicator">' + (sortAsc ? '▲' : '▼') + '</span>' : '') + '</th>'
        ).join('') + '</tr>';

        th.querySelectorAll('th[data-col]').forEach(thEl => {
          thEl.addEventListener('click', () => {
            const ci = parseInt(thEl.dataset.col);
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
        if (filter) {
          if (filter.includes(':')) {
            const [col, val] = filter.split(':').map(s => s.trim());
            const ci = t.columns.indexOf(col);
            if (ci >= 0) rows = rows.filter(r => String(r[ci]).toLowerCase().includes(val.toLowerCase()));
          } else {
            rows = rows.filter(r => r.some(v => String(v).toLowerCase().includes(filter.toLowerCase())));
          }
        }

        const tb = document.getElementById('gridBody');
        tb.innerHTML = '';
        rows.forEach((row, ri) => {
          const tr = document.createElement('tr');
          if (ri === selectedRow) tr.classList.add('selected');
          tr.innerHTML = '<td style="color:var(--text-dim);text-align:center;font-size:10px">' + ri + '</td>' +
            row.map((v, ci) => {
              let display = String(v);
              if (typeof v === 'boolean') display = v ? '✓' : '✗';
              return '<td data-r="' + ri + '" data-c="' + ci + '">' + display + '</td>';
            }).join('');
          tr.addEventListener('click', () => { selectedRow = ri; updateStatus(); tb.querySelectorAll('tr').forEach(r => r.classList.remove('selected')); tr.classList.add('selected'); });
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
            inp.focus(); inp.select();
            const commit = () => {
              pushUndo();
              const type = t.types[ci];
              if (type === 'number') t.rows[ri][ci] = parseFloat(inp.value) || 0;
              else if (type === 'boolean') t.rows[ri][ci] = inp.value === 'true' || inp.value === '1';
              else t.rows[ri][ci] = inp.value;
              refreshGrid();
            };
            inp.addEventListener('blur', commit);
            inp.addEventListener('keydown', (e) => {
              if (e.key === 'Enter') inp.blur();
              if (e.key === 'Escape') { refreshGrid(); }
            });
          });
        });

        updateStatus();
      }

      function updateStatus() {
        const t = tables[currentTable];
        document.getElementById('statusTables').textContent = Object.keys(tables).length + ' tables';
        document.getElementById('statusRows').textContent = (t ? t.rows.length : 0) + ' rows';
        document.getElementById('statusCols').textContent = (t ? t.columns.length : 0) + ' columns';
        document.getElementById('statusSelected').textContent = selectedRow >= 0 ? 'Row ' + selectedRow : 'No selection';
      }

      function refreshAll() { refreshTableList(); refreshGrid(); }

      document.getElementById('filterInput').addEventListener('input', () => refreshGrid());

      document.getElementById('btnNewTable').addEventListener('click', () => {
        pushUndo();
        const name = 'table_' + Object.keys(tables).length;
        tables[name] = { columns: ['id', 'name'], types: ['number', 'string'], rows: [] };
        currentTable = name; refreshAll();
      });
      document.getElementById('btnDeleteTable').addEventListener('click', () => {
        if (!currentTable) return;
        pushUndo();
        delete tables[currentTable];
        const keys = Object.keys(tables);
        currentTable = keys.length > 0 ? keys[0] : '';
        refreshAll();
      });
      document.getElementById('btnAddRow').addEventListener('click', () => {
        const t = tables[currentTable]; if (!t) return;
        pushUndo();
        const row = t.columns.map((_, i) => t.types[i] === 'number' ? 0 : t.types[i] === 'boolean' ? false : '');
        row[0] = t.rows.length;
        t.rows.push(row); refreshGrid();
      });
      document.getElementById('btnAddCol').addEventListener('click', () => {
        const t = tables[currentTable]; if (!t) return;
        pushUndo();
        t.columns.push('col_' + t.columns.length); t.types.push('string');
        t.rows.forEach(r => r.push(''));
        refreshGrid();
      });
      document.getElementById('btnDeleteRow').addEventListener('click', () => {
        const t = tables[currentTable]; if (!t || selectedRow < 0) return;
        pushUndo();
        t.rows.splice(selectedRow, 1); selectedRow = -1; refreshGrid();
      });
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });

      document.getElementById('btnImport').addEventListener('click', () => vscode.postMessage({ type: 'importCsv' }));

      window.addEventListener('message', (e) => {
        if (e.data.type === 'csvData') {
          const lines = e.data.content.split('\\n').filter(l => l.trim());
          if (lines.length < 2) return;
          pushUndo();
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

      // ── Export ─────────────────────────────────────────
      function buildLuaCode() {
        const t = tables[currentTable];
        if (!t) return '-- No table selected';
        const lines = ['-- Generated by Lurek2D Database Browser', '-- Table: ' + currentTable, ''];
        lines.push('return {');
        for (const row of t.rows) {
          let items = [];
          t.columns.forEach((c, i) => {
            if (typeof row[i] === 'string') items.push(c + ' = "' + row[i] + '"');
            else items.push(c + ' = ' + row[i]);
          });
          lines.push('  { ' + items.join(', ') + ' },');
        }
        lines.push('}');
        return lines.join('\\n');
      }

      function buildTomlCode() {
        const t = tables[currentTable];
        if (!t) return '# No table selected';
        let toml = '# Table: ' + currentTable + '\\n\\n';
        for (const row of t.rows) {
          toml += '[[' + currentTable + ']]\\n';
          t.columns.forEach((c, i) => {
            if (typeof row[i] === 'string') toml += c + ' = "' + row[i] + '"\\n';
            else toml += c + ' = ' + row[i] + '\\n';
          });
          toml += '\\n';
        }
        return toml;
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export Lua File', action: () => vscode.postMessage({ type: 'exportLua', content: buildLuaCode() }) },
        { label: 'Export TOML File', action: () => vscode.postMessage({ type: 'exportToml', content: buildTomlCode() }) },
        { label: 'Copy Lua Code', action: () => vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() }) },
        { label: 'Insert to Editor', action: () => vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() }) },
      ]);

      document.getElementById('btnCopyLua').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() });
      });

      // ── Init ───────────────────────────────────────────
      refreshAll();
    `);
  }
}
