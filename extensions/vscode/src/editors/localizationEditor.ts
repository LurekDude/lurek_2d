import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class LocalizationEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): LocalizationEditor {
    return new LocalizationEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.localizationEditor", "Localization");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "strings.lua");
        break;
      case "exportJson":
        this.exportFile(msg.content as string, "strings.json", "JSON", "json");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Localization", `
      .editor-layout {
        display: grid; grid-template-columns: 1fr;
        grid-template-rows: auto auto 1fr auto auto;
        height: 100vh;
      }
      .toolbar { grid-row: 1; }
      .filter-bar { grid-row: 2; padding: 6px 10px; background: var(--surface); border-bottom: 1px solid var(--border); display: flex; gap: 8px; align-items: center; }
      .table-area { grid-row: 3; overflow: auto; }
      .stats-bar { grid-row: 4; padding: 6px 10px; background: var(--surface); border-top: 1px solid var(--border); display: flex; gap: 16px; flex-wrap: wrap; }
      .status-bar { grid-row: 5; }
      .loc-table { width: 100%; border-collapse: collapse; font-size: 12px; }
      .loc-table th {
        position: sticky; top: 0; z-index: 5;
        text-align: left; padding: 6px 8px; background: var(--surface);
        border-bottom: 2px solid var(--border); font-size: 11px; text-transform: uppercase;
        color: var(--text-dim); white-space: nowrap;
      }
      .loc-table td {
        padding: 2px 4px; border-bottom: 1px solid var(--border); vertical-align: top;
      }
      .loc-table tr:hover { background: var(--surface-2); }
      .loc-table tr.selected { background: var(--selection); }
      .loc-input {
        width: 100%; background: transparent; border: 1px solid transparent;
        color: var(--text); padding: 2px 4px; font-size: 12px;
      }
      .loc-input:focus { border-color: var(--accent); background: var(--surface); }
      .loc-input.missing { border-color: var(--danger); background: rgba(244,67,54,0.08); }
      .key-cell { font-family: monospace; font-size: 11px; color: var(--accent-2); min-width: 140px; }
      .coverage-bar {
        display: flex; align-items: center; gap: 6px; font-size: 11px;
      }
      .coverage-fill {
        width: 60px; height: 8px; background: var(--surface-2); border-radius: 4px; overflow: hidden;
      }
      .coverage-fill-inner { height: 100%; border-radius: 4px; transition: width 0.3s; }
      .lang-header { display: flex; align-items: center; gap: 4px; }
      .lang-remove { font-size: 10px; cursor: pointer; opacity: 0.5; }
      .lang-remove:hover { opacity: 1; color: var(--danger); }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAddKey">+ Key</button>
          <button id="btnRemoveKey" class="danger">Remove Key</button>
          <div class="sep"></div>
          <button id="btnAddLang">+ Language</button>
          <button id="btnRemoveLang" class="danger">Remove Lang</button>
          <div class="sep"></div>
          <button id="btnImportJson">Import JSON</button>
          <button id="btnExportJson">Export JSON</button>
          <button id="btnExportLua">Export Lua</button>
        </div>

        <div class="filter-bar">
          <label>Search:</label>
          <input type="text" id="searchInput" placeholder="Filter keys or values..." style="flex:1;max-width:300px;">
          <label>Show:</label>
          <select id="filterMode">
            <option value="all">All</option>
            <option value="missing">Missing translations</option>
            <option value="complete">Complete only</option>
          </select>
        </div>

        <div class="table-area">
          <table class="loc-table">
            <thead id="tableHead"></thead>
            <tbody id="tableBody"></tbody>
          </table>
        </div>

        <div class="stats-bar" id="statsBar"></div>

        <div class="status-bar">
          <span id="statusKeys">Keys: 0</span>
          <span id="statusLangs">Languages: 0</span>
          <span id="statusTotal">Translations: 0</span>
        </div>
      </div>
    `, `
      let languages = ['en', 'es', 'fr', 'de'];
      let baseLang = 'en';
      let entries = [
        { key: 'menu.start', values: { en: 'Start Game', es: 'Iniciar Juego', fr: 'Commencer', de: 'Spiel starten' } },
        { key: 'menu.options', values: { en: 'Options', es: 'Opciones', fr: 'Options', de: 'Optionen' } },
        { key: 'menu.quit', values: { en: 'Quit', es: 'Salir', fr: 'Quitter', de: 'Beenden' } },
        { key: 'dialog.greeting', values: { en: 'Hello, traveler!', es: 'Hola, viajero!', fr: '', de: '' } },
        { key: 'item.sword', values: { en: 'Iron Sword', es: 'Espada de hierro', fr: '', de: '' } },
        { key: 'ui.health', values: { en: 'Health', es: 'Salud', fr: 'Sant\\u00e9', de: 'Gesundheit' } },
      ];
      let selectedRow = -1;
      let searchText = '';
      let filterMode = 'all';

      function render() {
        // Head
        const head = document.getElementById('tableHead');
        head.innerHTML = '<tr><th style="width:160px;">Key</th>';
        languages.forEach(lang => {
          head.querySelector('tr').innerHTML += '<th><div class="lang-header">' + lang.toUpperCase() + (lang === baseLang ? ' (base)' : '') + '</div></th>';
        });
        head.querySelector('tr').innerHTML += '</tr>';

        // Body
        const body = document.getElementById('tableBody');
        body.innerHTML = '';
        const filtered = getFilteredEntries();
        filtered.forEach((entry, fi) => {
          const origIdx = entries.indexOf(entry);
          const tr = document.createElement('tr');
          tr.className = origIdx === selectedRow ? 'selected' : '';
          tr.addEventListener('click', () => { selectedRow = origIdx; render(); });

          const tdKey = document.createElement('td');
          tdKey.className = 'key-cell';
          const keyInput = document.createElement('input');
          keyInput.className = 'loc-input';
          keyInput.value = entry.key;
          keyInput.style.fontFamily = 'monospace';
          keyInput.style.color = 'var(--accent-2)';
          keyInput.addEventListener('change', (e) => { entry.key = e.target.value; });
          tdKey.appendChild(keyInput);
          tr.appendChild(tdKey);

          languages.forEach(lang => {
            const td = document.createElement('td');
            const input = document.createElement('input');
            input.className = 'loc-input' + ((entry.values[lang] || '').trim() === '' ? ' missing' : '');
            input.value = entry.values[lang] || '';
            input.placeholder = lang === baseLang ? '(base)' : '(missing)';
            input.addEventListener('change', (e) => { entry.values[lang] = e.target.value; updateStats(); render(); });
            td.appendChild(input);
            tr.appendChild(td);
          });
          body.appendChild(tr);
        });

        updateStats();
      }

      function getFilteredEntries() {
        return entries.filter(e => {
          if (searchText) {
            const s = searchText.toLowerCase();
            const matchKey = e.key.toLowerCase().includes(s);
            const matchVal = Object.values(e.values).some(v => (v || '').toLowerCase().includes(s));
            if (!matchKey && !matchVal) return false;
          }
          if (filterMode === 'missing') {
            return languages.some(l => !(e.values[l] || '').trim());
          }
          if (filterMode === 'complete') {
            return languages.every(l => (e.values[l] || '').trim());
          }
          return true;
        });
      }

      function updateStats() {
        const bar = document.getElementById('statsBar');
        bar.innerHTML = '';
        let totalFilled = 0, totalCells = 0;
        languages.forEach(lang => {
          let filled = 0;
          entries.forEach(e => { if ((e.values[lang] || '').trim()) filled++; });
          totalFilled += filled;
          totalCells += entries.length;
          const pct = entries.length > 0 ? Math.round(filled / entries.length * 100) : 0;
          const color = pct === 100 ? 'var(--success)' : pct > 50 ? 'var(--warning)' : 'var(--danger)';
          const item = document.createElement('div');
          item.className = 'coverage-bar';
          item.innerHTML = '<strong>' + lang.toUpperCase() + '</strong>' +
            '<div class="coverage-fill"><div class="coverage-fill-inner" style="width:' + pct + '%;background:' + color + '"></div></div>' +
            '<span>' + pct + '% (' + filled + '/' + entries.length + ')</span>';
          bar.appendChild(item);
        });
        document.getElementById('statusKeys').textContent = 'Keys: ' + entries.length;
        document.getElementById('statusLangs').textContent = 'Languages: ' + languages.length;
        document.getElementById('statusTotal').textContent = 'Translations: ' + totalFilled + '/' + totalCells;
      }

      document.getElementById('searchInput').addEventListener('input', (e) => {
        searchText = e.target.value; render();
      });
      document.getElementById('filterMode').addEventListener('change', (e) => {
        filterMode = e.target.value; render();
      });

      document.getElementById('btnAddKey').addEventListener('click', () => {
        const values = {};
        languages.forEach(l => { values[l] = ''; });
        entries.push({ key: 'new.key.' + entries.length, values });
        selectedRow = entries.length - 1;
        render();
      });
      document.getElementById('btnRemoveKey').addEventListener('click', () => {
        if (selectedRow >= 0 && selectedRow < entries.length) {
          entries.splice(selectedRow, 1);
          selectedRow = Math.min(selectedRow, entries.length - 1);
          render();
        }
      });

      document.getElementById('btnAddLang').addEventListener('click', () => {
        const lang = prompt('Language code (e.g. ja, ko, pt):');
        if (lang && !languages.includes(lang)) {
          languages.push(lang);
          entries.forEach(e => { e.values[lang] = ''; });
          render();
        }
      });
      document.getElementById('btnRemoveLang').addEventListener('click', () => {
        if (languages.length <= 1) return;
        const lang = prompt('Language code to remove:');
        if (lang && languages.includes(lang) && lang !== baseLang) {
          languages = languages.filter(l => l !== lang);
          entries.forEach(e => { delete e.values[lang]; });
          render();
        }
      });

      document.getElementById('btnExportJson').addEventListener('click', () => {
        const obj = {};
        languages.forEach(l => { obj[l] = {}; entries.forEach(e => { obj[l][e.key] = e.values[l] || ''; }); });
        vscode.postMessage({ type: 'exportJson', content: JSON.stringify(obj, null, 2) });
      });

      document.getElementById('btnExportLua').addEventListener('click', () => {
        let lua = 'return {\\n';
        languages.forEach(l => {
          lua += '  ' + l + ' = {\\n';
          entries.forEach(e => {
            const val = (e.values[l] || '').replace(/"/g, '\\\\"');
            lua += '    ["' + e.key + '"] = "' + val + '",\\n';
          });
          lua += '  },\\n';
        });
        lua += '}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      render();
    `);
  }
}
