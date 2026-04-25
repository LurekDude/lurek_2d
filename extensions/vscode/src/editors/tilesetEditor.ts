import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

export class TilesetEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): TilesetEditor {
    return new TilesetEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.tilesetEditor", "Tileset");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "tileset.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Tileset", `
      .editor-layout {
        display: grid; grid-template-columns: 1fr 220px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .tileset-area { grid-row: 2; position: relative; overflow: auto; background: var(--bg); }
      .props-panel { grid-row: 2; overflow-y: auto; border-left: 1px solid var(--border); background: var(--surface); padding: 6px; }
      .upload-zone {
        border: 2px dashed var(--border); border-radius: var(--radius); padding: 36px;
        text-align: center; color: var(--text-dim); cursor: pointer; margin: 20px;
        transition: border-color 0.15s, color 0.15s;
      }
      .upload-zone:hover { border-color: var(--accent); color: var(--accent); }
      .tile-props-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 3px; }
      .prop-chip {
        display: flex; align-items: center; gap: 4px; padding: 2px 6px;
        background: var(--surface-2); border-radius: var(--radius); font-size: 10px;
      }
      .auto-rule { display: flex; align-items: center; gap: 6px; padding: 4px; border-bottom: 1px solid var(--border); font-size: 10px; }
      .auto-rule-grid { display: grid; grid-template-columns: repeat(3, 14px); gap: 1px; }
      .auto-rule-cell {
        width: 14px; height: 14px; background: var(--surface-2); border: 1px solid var(--border);
        cursor: pointer; border-radius: 1px; transition: background 0.08s;
      }
      .auto-rule-cell.on { background: var(--accent); }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${iconButton(ICONS.add, 'btnUpload', 'Upload Image')}
          </div>
          ${toolbarSep()}
          <div class="group">
            <label>W:</label><input type="number" id="tileW" value="32" min="8" max="256" style="width:44px">
            <label>H:</label><input type="number" id="tileH" value="32" min="8" max="256" style="width:44px">
          </div>
          ${toolbarSep()}
          <div class="group">
            ${iconButton(ICONS.grid, 'btnShowGrid', 'Toggle Grid')}
            <button id="btnShowIds" title="Show Tile IDs" style="font-size:10px;padding:2px 6px">IDs</button>
          </div>
          ${toolbarSpacer()}
          ${iconButton(ICONS.save, 'btnExport', 'Export Lua')}
        </div>

        <div class="tileset-area" id="tilesetArea">
          <div class="upload-zone" id="uploadZone">
            <p style="font-size:13px">Drop tileset image here or click Upload</p>
            <p style="font-size:10px;margin-top:6px;color:var(--text-dim)">Supported: PNG, JPG</p>
          </div>
          <canvas id="tilesetCanvas" style="display:none;"></canvas>
        </div>

        <div class="props-panel">
          ${panelSection('Selected Tile', `
            ${fieldInline('Tile ID', '<input type="text" id="tileId" readonly>')}
            ${fieldInline('Name', '<input type="text" id="tileName" placeholder="(optional)">')}
          `)}
          ${panelSection('Properties', `
            <div class="tile-props-grid">
              <div class="prop-chip"><input type="checkbox" id="propSolid"><label for="propSolid">Solid</label></div>
              <div class="prop-chip"><input type="checkbox" id="propAnimated"><label for="propAnimated">Animated</label></div>
              <div class="prop-chip"><input type="checkbox" id="propSlope"><label for="propSlope">Slope</label></div>
              <div class="prop-chip"><input type="checkbox" id="propHazard"><label for="propHazard">Hazard</label></div>
            </div>
            ${fieldInline('Slope Angle', '<input type="range" id="slopeAngle" min="0" max="90" value="45" style="width:100%"><span id="slopeLabel" style="font-size:10px;min-width:24px">45°</span>')}
          `)}
          ${panelSection('Auto-Tile Rules', `
            <div id="autoRules"></div>
            <button id="btnAddRule" style="margin-top:4px;width:100%">+ Add Rule</button>
          `)}
        </div>

        <div class="status-bar">
          <span id="statusTile" class="badge">Tile: none</span>
          <div class="sep"></div>
          <span id="statusGrid">Grid: 0×0</span>
          <div class="sep"></div>
          <span id="statusTotal">0 tiles</span>
          <div class="spacer"></div>
          <span id="statusDirty" style="font-size:10px;color:var(--text-dim)">${ICONS.clean}</span>
        </div>
      </div>
    `, `
      const canvas = document.getElementById('tilesetCanvas');
      const ctx = canvas.getContext('2d');
      const undo = new UndoStack();
      let tileW = 32, tileH = 32;
      let gridCols = 0, gridRows = 0;
      let selectedTile = -1;
      let showGrid = true, showIds = false;
      let tileProps = {};
      let autoRules = [];
      let imageLoaded = false;

      function getState() { return JSON.parse(JSON.stringify({ tileProps, autoRules })); }
      function loadState(s) { tileProps = s.tileProps; autoRules = s.autoRules; renderAutoRules(); draw(); }
      function pushUndo() { undo.push(getState()); markDirty(); }

      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) loadState(s); });
      registerShortcut('ctrl+shift+z', () => { const s = undo.redo(); if (s) loadState(s); });
      registerShortcut('ctrl+s', () => document.getElementById('btnExport').click());
      registerShortcut('g', () => document.getElementById('btnShowGrid').click());

      function updateGrid() {
        if (!imageLoaded) return;
        gridCols = Math.floor(canvas.width / tileW);
        gridRows = Math.floor(canvas.height / tileH);
        document.getElementById('statusGrid').textContent = 'Grid: ' + gridCols + '\\u00d7' + gridRows;
        document.getElementById('statusTotal').textContent = (gridCols * gridRows) + ' tiles';
        draw();
      }

      function draw() {
        if (!imageLoaded) return;
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        for (let y = 0; y < canvas.height; y += 16) {
          for (let x = 0; x < canvas.width; x += 16) {
            ctx.fillStyle = (Math.floor(x/16) + Math.floor(y/16)) % 2 === 0 ? '#2a2a2a' : '#242424';
            ctx.fillRect(x, y, 16, 16);
          }
        }
        if (showGrid) {
          ctx.strokeStyle = 'rgba(255,255,255,0.08)';
          ctx.lineWidth = 0.5;
          for (let c = 0; c <= gridCols; c++) { ctx.beginPath(); ctx.moveTo(c*tileW, 0); ctx.lineTo(c*tileW, gridRows*tileH); ctx.stroke(); }
          for (let r = 0; r <= gridRows; r++) { ctx.beginPath(); ctx.moveTo(0, r*tileH); ctx.lineTo(gridCols*tileW, r*tileH); ctx.stroke(); }
        }
        if (showIds) {
          ctx.fillStyle = 'rgba(255,255,255,0.7)';
          ctx.font = '9px monospace';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          for (let r = 0; r < gridRows; r++)
            for (let c = 0; c < gridCols; c++)
              ctx.fillText(String(r * gridCols + c), c * tileW + tileW/2, r * tileH + tileH/2);
        }
        if (selectedTile >= 0) {
          const sc = selectedTile % gridCols, sr = Math.floor(selectedTile / gridCols);
          ctx.strokeStyle = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim() || '#89b4fa';
          ctx.lineWidth = 2;
          ctx.strokeRect(sc * tileW + 1, sr * tileH + 1, tileW - 2, tileH - 2);
        }
      }

      canvas.addEventListener('click', (e) => {
        const rect = canvas.getBoundingClientRect();
        const c = Math.floor((e.clientX - rect.left) / tileW);
        const r = Math.floor((e.clientY - rect.top) / tileH);
        if (c < gridCols && r < gridRows) {
          selectedTile = r * gridCols + c;
          document.getElementById('tileId').value = selectedTile;
          document.getElementById('statusTile').textContent = 'Tile: ' + selectedTile;
          const p = tileProps[selectedTile] || {};
          document.getElementById('propSolid').checked = !!p.solid;
          document.getElementById('propAnimated').checked = !!p.animated;
          document.getElementById('propSlope').checked = !!p.slope;
          document.getElementById('propHazard').checked = !!p.hazard;
          document.getElementById('tileName').value = p.name || '';
          draw();
        }
      });

      function saveCurrentTileProps() {
        if (selectedTile < 0) return;
        pushUndo();
        tileProps[selectedTile] = {
          solid: document.getElementById('propSolid').checked,
          animated: document.getElementById('propAnimated').checked,
          slope: document.getElementById('propSlope').checked,
          hazard: document.getElementById('propHazard').checked,
          name: document.getElementById('tileName').value,
          slopeAngle: parseInt(document.getElementById('slopeAngle').value),
        };
      }

      ['propSolid','propAnimated','propSlope','propHazard','tileName'].forEach(id =>
        document.getElementById(id).addEventListener('change', saveCurrentTileProps));

      document.getElementById('slopeAngle').addEventListener('input', (e) => {
        document.getElementById('slopeLabel').textContent = e.target.value + '\\u00B0';
        saveCurrentTileProps();
      });

      document.getElementById('tileW').addEventListener('change', (e) => { tileW = parseInt(e.target.value); updateGrid(); });
      document.getElementById('tileH').addEventListener('change', (e) => { tileH = parseInt(e.target.value); updateGrid(); });

      document.getElementById('btnShowGrid').addEventListener('click', function() {
        showGrid = !showGrid; this.classList.toggle('active', showGrid); draw();
      });
      document.getElementById('btnShowIds').addEventListener('click', function() {
        showIds = !showIds; this.classList.toggle('active', showIds); draw();
      });

      document.getElementById('btnUpload').addEventListener('click', () => {
        canvas.style.display = 'block';
        document.getElementById('uploadZone').style.display = 'none';
        canvas.width = 256; canvas.height = 256;
        imageLoaded = true;
        updateGrid();
      });

      document.getElementById('btnAddRule').addEventListener('click', () => {
        pushUndo();
        autoRules.push({ mask: new Array(9).fill(false), target: selectedTile >= 0 ? selectedTile : 0 });
        renderAutoRules();
      });

      function renderAutoRules() {
        const c = document.getElementById('autoRules'); c.innerHTML = '';
        autoRules.forEach((rule, ri) => {
          const row = document.createElement('div'); row.className = 'auto-rule';
          const grid = document.createElement('div'); grid.className = 'auto-rule-grid';
          for (let i = 0; i < 9; i++) {
            const cell = document.createElement('div');
            cell.className = 'auto-rule-cell' + (rule.mask[i] ? ' on' : '');
            cell.addEventListener('click', () => { pushUndo(); rule.mask[i] = !rule.mask[i]; renderAutoRules(); });
            grid.appendChild(cell);
          }
          row.appendChild(grid);
          const lbl = document.createElement('span');
          lbl.textContent = ' \\u2192 Tile ' + rule.target;
          row.appendChild(lbl);
          c.appendChild(row);
        });
      }

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        lua += '  tile_width = ' + tileW + ',\\n  tile_height = ' + tileH + ',\\n';
        lua += '  cols = ' + gridCols + ', rows = ' + gridRows + ',\\n';
        lua += '  tiles = {\\n';
        for (let i = 0; i < gridCols * gridRows; i++) {
          const p = tileProps[i];
          if (p) {
            lua += '    [' + i + '] = { solid = ' + !!p.solid + ', animated = ' + !!p.animated;
            if (p.name) lua += ', name = "' + p.name + '"';
            if (p.slope) lua += ', slope = ' + (p.slopeAngle || 45);
            if (p.hazard) lua += ', hazard = true';
            lua += ' },\\n';
          }
        }
        lua += '  },\\n  auto_rules = {\\n';
        autoRules.forEach((r, i) => {
          lua += '    { mask = {' + r.mask.map(v => v ? '1' : '0').join(',') + '}, target = ' + r.target + ' },\\n';
        });
        lua += '  }\\n}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      vscode.postMessage({ type: 'stateChanged', state: { ready: true } });
    `);
  }
}
