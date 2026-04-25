import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

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
      .filter-bar { grid-row: 2; padding: 4px 8px; background: var(--surface); border-bottom: 1px solid var(--border); display: flex; gap: 6px; align-items: center; }
      .table-area { grid-row: 3; overflow: auto; }
      .stats-bar { grid-row: 4; padding: 4px 8px; background: var(--surface); border-top: 1px solid var(--border); display: flex; gap: 12px; flex-wrap: wrap; }
      .status-bar { grid-row: 5; }
      .loc-table { width: 100%; border-collapse: collapse; font-size: 11px; }
      .loc-table th {
        position: sticky; top: 0; z-index: 5;
        text-align: left; padding: 4px 6px; background: var(--surface);
        border-bottom: 2px solid var(--border); font-size: 10px; text-transform: uppercase;
        color: var(--text-dim); white-space: nowrap;
      }
      .loc-table td { padding: 1px 3px; border-bottom: 1px solid var(--border); vertical-align: top; }
      .loc-table tr:hover { background: var(--hover); }
      .loc-table tr.sel { background: var(--selection); }
      .loc-input {
        width: 100%; background: transparent; border: 1px solid transparent;
        color: var(--text); padding: 2px 4px; font-size: 11px;
      }
      .loc-input:focus { border-color: var(--accent); background: var(--surface); }
      .loc-input.missing { border-color: var(--error); background: rgba(243,139,168,0.08); }
      .key-cell { font-family: var(--font-mono, monospace); font-size: 10px; color: var(--accent-2); min-width: 120px; }
      .coverage-bar { display: flex; align-items: center; gap: 4px; font-size: 10px; }
      .coverage-fill { width: 50px; height: 6px; background: var(--surface-2); border-radius: 3px; overflow: hidden; }
      .coverage-fill-inner { height: 100%; border-radius: 3px; transition: width 0.3s; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${iconButton(ICONS.add, 'btnAddKey', 'Add Key')}
            ${iconButton(ICONS.trash, 'btnRemoveKey', 'Remove Key')}
          </div>
          ${toolbarSep()}
          <div class="group">
            <button id="btnAddLang" style="font-size:10px;padding:2px 6px">+ Lang</button>
            <button id="btnRemoveLang" style="font-size:10px;padding:2px 6px;color:var(--error)">- Lang</button>
          </div>
          ${toolbarSep()}
          <div class="group">
            <button id="btnImportJson" style="font-size:10px;padding:2px 6px">Import JSON</button>
          </div>
          ${toolbarSpacer()}
          <div class="group">
            <button id="btnExportJson" style="font-size:10px;padding:2px 6px">JSON</button>
            ${iconButton(ICONS.save, 'btnExportLua', 'Export Lua')}
          </div>
        </div>

        <div class="filter-bar">
          <label style="font-size:10px">Search:</label>
          <input type="text" id="searchInput" placeholder="Filter keys or values..." style="flex:1;max-width:250px;font-size:10px">
          <label style="font-size:10px">Show:</label>
          <select id="filterMode" style="font-size:10px">
            <option value="all">All</option>
            <option value="missing">Missing</option>
            <option value="complete">Complete</option>
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
          <span id="statusKeys" class="badge">6 keys</span>
          <div class="sep"></div>
          <span id="statusLangs">4 langs</span>
          <div class="sep"></div>
          <span id="statusTotal">translations</span>
          <div class="spacer"></div>
          <span id="statusDirty" style="font-size:10px;color:var(--text-dim)">${ICONS.clean}</span>
        </div>
      </div>
    `, `
      const undo = new UndoStack();
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
      let selectedRow = -1, searchText = '', filterMode = 'all';

      function snap() { return JSON.parse(JSON.stringify({ languages, entries })); }
      function load(s) { languages = s.languages; entries = s.entries; build(); }
      function push() { undo.push(snap()); markDirty(); }
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) load(s); });
      registerShortcut('ctrl+shift+z', () => { const s = undo.redo(); if (s) load(s); });
      registerShortcut('ctrl+s', () => document.getElementById('btnExportLua').click());

      function build() {
        const head = document.getElementById('tableHead');
        head.innerHTML = '<tr><th style="width:140px;">Key</th>';
        languages.forEach(lang => { head.querySelector('tr').innerHTML += '<th>' + lang.toUpperCase() + (lang === baseLang ? ' *' : '') + '</th>'; });
        head.querySelector('tr').innerHTML += '</tr>';

        const body = document.getElementById('tableBody'); body.innerHTML = '';
        const filtered = getFilteredEntries();
        filtered.forEach((entry) => {
          const origIdx = entries.indexOf(entry);
          const tr = document.createElement('tr');
          tr.className = origIdx === selectedRow ? 'sel' : '';
          tr.addEventListener('click', () => { selectedRow = origIdx; build(); });

          const tdKey = document.createElement('td'); tdKey.className = 'key-cell';
          const keyInput = document.createElement('input'); keyInput.className = 'loc-input';
          keyInput.value = entry.key; keyInput.style.fontFamily = 'var(--font-mono, monospace)'; keyInput.style.color = 'var(--accent-2)';
          keyInput.addEventListener('change', e => { push(); entry.key = e.target.value; });
          tdKey.appendChild(keyInput); tr.appendChild(tdKey);

          languages.forEach(lang => {
            const td = document.createElement('td');
            const input = document.createElement('input');
            input.className = 'loc-input' + ((entry.values[lang] || '').trim() === '' ? ' missing' : '');
            input.value = entry.values[lang] || '';
            input.placeholder = lang === baseLang ? '(base)' : '(missing)';
            input.addEventListener('change', e => { push(); entry.values[lang] = e.target.value; updateStats(); build(); });
            td.appendChild(input); tr.appendChild(td);
          });
          body.appendChild(tr);
        });
        updateStats();
      }

      function getFilteredEntries() {
        return entries.filter(e => {
          if (searchText) {
            const s = searchText.toLowerCase();
            if (!e.key.toLowerCase().includes(s) && !Object.values(e.values).some(v => (v || '').toLowerCase().includes(s))) return false;
          }
          if (filterMode === 'missing') return languages.some(l => !(e.values[l] || '').trim());
          if (filterMode === 'complete') return languages.every(l => (e.values[l] || '').trim());
          return true;
        });
      }

      function updateStats() {
        const bar = document.getElementById('statsBar'); bar.innerHTML = '';
        let totalFilled = 0, totalCells = 0;
        languages.forEach(lang => {
          let filled = 0;
          entries.forEach(e => { if ((e.values[lang] || '').trim()) filled++; });
          totalFilled += filled; totalCells += entries.length;
          const pct = entries.length > 0 ? Math.round(filled / entries.length * 100) : 0;
          const color = pct === 100 ? 'var(--success)' : pct > 50 ? 'var(--warning)' : 'var(--error)';
          const item = document.createElement('div'); item.className = 'coverage-bar';
          item.innerHTML = '<strong>' + lang.toUpperCase() + '</strong>' +
            '<div class="coverage-fill"><div class="coverage-fill-inner" style="width:' + pct + '%;background:' + color + '"></div></div>' +
            '<span>' + pct + '% (' + filled + '/' + entries.length + ')</span>';
          bar.appendChild(item);
        });
        document.getElementById('statusKeys').textContent = entries.length + ' keys';
        document.getElementById('statusLangs').textContent = languages.length + ' langs';
        document.getElementById('statusTotal').textContent = totalFilled + '/' + totalCells + ' filled';
      }

      document.getElementById('searchInput').addEventListener('input', e => { searchText = e.target.value; build(); });
      document.getElementById('filterMode').addEventListener('change', e => { filterMode = e.target.value; build(); });

      document.getElementById('btnAddKey').addEventListener('click', () => {
        push(); const values = {}; languages.forEach(l => { values[l] = ''; });
        entries.push({ key: 'new.key.' + entries.length, values }); selectedRow = entries.length - 1; build();
      });
      document.getElementById('btnRemoveKey').addEventListener('click', () => {
        if (selectedRow >= 0 && selectedRow < entries.length) { push(); entries.splice(selectedRow, 1); selectedRow = Math.min(selectedRow, entries.length - 1); build(); }
      });

      document.getElementById('btnAddLang').addEventListener('click', () => {
        const lang = prompt('Language code (e.g. ja, ko, pt):');
        if (lang && !languages.includes(lang)) { push(); languages.push(lang); entries.forEach(e => { e.values[lang] = ''; }); build(); }
      });
      document.getElementById('btnRemoveLang').addEventListener('click', () => {
        if (languages.length <= 1) return;
        const lang = prompt('Language code to remove:');
        if (lang && languages.includes(lang) && lang !== baseLang) { push(); languages = languages.filter(l => l !== lang); entries.forEach(e => { delete e.values[lang]; }); build(); }
      });

      document.getElementById('btnExportJson').addEventListener('click', () => {
        const obj = {}; languages.forEach(l => { obj[l] = {}; entries.forEach(e => { obj[l][e.key] = e.values[l] || ''; }); });
        vscode.postMessage({ type: 'exportJson', content: JSON.stringify(obj, null, 2) });
      });
      document.getElementById('btnExportLua').addEventListener('click', () => {
        let lua = 'return {\\n';
        languages.forEach(l => { lua += '  ' + l + ' = {\\n'; entries.forEach(e => { const val = (e.values[l] || '').replace(/"/g, '\\\\"'); lua += '    ["' + e.key + '"] = "' + val + '",\\n'; }); lua += '  },\\n'; });
        lua += '}'; vscode.postMessage({ type: 'exportLua', content: lua });
      });

      build();
    `);
  }
}
