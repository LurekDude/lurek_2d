import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class DatabaseEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): DatabaseEditor {
    return new DatabaseEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "luna.editor.database", "Database Browser");
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
    `, `
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
    `);
  }
}
