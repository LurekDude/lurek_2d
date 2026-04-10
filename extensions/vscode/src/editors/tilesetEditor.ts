import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

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
        display: grid; grid-template-columns: 1fr 260px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .tileset-area { grid-row: 2; position: relative; overflow: auto; background: var(--bg); }
      .props-panel { grid-row: 2; }
      .status-bar { grid-column: 1 / -1; }
      .tile-grid-overlay { position: absolute; top: 0; left: 0; pointer-events: none; }
      .upload-zone {
        border: 2px dashed var(--border); border-radius: 8px; padding: 40px;
        text-align: center; color: var(--text-dim); cursor: pointer; margin: 20px;
      }
      .upload-zone:hover { border-color: var(--accent); color: var(--accent); }
      .tile-props-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 4px; }
      .prop-chip {
        display: flex; align-items: center; gap: 4px; padding: 2px 6px;
        background: var(--surface-2); border-radius: 3px; font-size: 11px;
      }
      .auto-rule { display: flex; align-items: center; gap: 4px; padding: 4px; border-bottom: 1px solid var(--border); font-size: 11px; }
      .auto-rule-grid {
        display: grid; grid-template-columns: repeat(3, 16px); gap: 1px;
      }
      .auto-rule-cell {
        width: 16px; height: 16px; background: var(--surface-2); border: 1px solid var(--border);
        cursor: pointer; border-radius: 1px;
      }
      .auto-rule-cell.on { background: var(--accent); }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnUpload">Upload Image</button>
          <div class="sep"></div>
          <label>Tile W:</label><input type="number" id="tileW" value="32" min="8" max="256" style="width:50px">
          <label>Tile H:</label><input type="number" id="tileH" value="32" min="8" max="256" style="width:50px">
          <div class="sep"></div>
          <button id="btnShowGrid" class="active">Grid</button>
          <button id="btnShowIds">IDs</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>

        <div class="tileset-area" id="tilesetArea">
          <div class="upload-zone" id="uploadZone">
            <p>Drop tileset image here or click Upload</p>
            <p style="font-size:11px;margin-top:8px;">Supported: PNG, JPG</p>
          </div>
          <canvas id="tilesetCanvas" style="display:none;"></canvas>
        </div>

        <div class="panel props-panel">
          <div class="section">
            <h3>Selected Tile</h3>
            <div class="field"><label>Tile ID</label><input type="text" id="tileId" readonly></div>
            <div class="field"><label>Name</label><input type="text" id="tileName" placeholder="(optional)"></div>
          </div>
          <div class="section">
            <h3>Properties</h3>
            <div class="tile-props-grid">
              <div class="prop-chip"><input type="checkbox" id="propSolid"><label for="propSolid">Solid</label></div>
              <div class="prop-chip"><input type="checkbox" id="propAnimated"><label for="propAnimated">Animated</label></div>
              <div class="prop-chip"><input type="checkbox" id="propSlope"><label for="propSlope">Slope</label></div>
              <div class="prop-chip"><input type="checkbox" id="propHazard"><label for="propHazard">Hazard</label></div>
            </div>
            <div class="field" style="margin-top:6px;">
              <label>Slope Angle</label>
              <input type="range" id="slopeAngle" min="0" max="90" value="45" style="width:100%">
              <span id="slopeLabel" style="font-size:11px;">45°</span>
            </div>
          </div>
          <div class="section">
            <h3>Auto-Tile Rules</h3>
            <div id="autoRules"></div>
            <button id="btnAddRule" style="margin-top:4px;width:100%;">+ Add Rule</button>
          </div>
        </div>

        <div class="status-bar">
          <span id="statusTile">Tile: none</span>
          <span id="statusGrid">Grid: 0x0</span>
          <span id="statusTotal">Total: 0 tiles</span>
        </div>
      </div>
    `, `
      const canvas = document.getElementById('tilesetCanvas');
      const ctx = canvas.getContext('2d');
      let tileW = 32, tileH = 32;
      let gridCols = 0, gridRows = 0;
      let selectedTile = -1;
      let showGrid = true, showIds = false;
      let tileProps = {};
      let autoRules = [];
      let imageLoaded = false;

      function updateGrid() {
        if (!imageLoaded) return;
        gridCols = Math.floor(canvas.width / tileW);
        gridRows = Math.floor(canvas.height / tileH);
        document.getElementById('statusGrid').textContent = 'Grid: ' + gridCols + 'x' + gridRows;
        document.getElementById('statusTotal').textContent = 'Total: ' + (gridCols * gridRows) + ' tiles';
        render();
      }

      function render() {
        if (!imageLoaded) return;
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        // Checkerboard bg
        for (let y = 0; y < canvas.height; y += 16) {
          for (let x = 0; x < canvas.width; x += 16) {
            ctx.fillStyle = (Math.floor(x/16) + Math.floor(y/16)) % 2 === 0 ? '#2a2a2a' : '#242424';
            ctx.fillRect(x, y, 16, 16);
          }
        }
        if (showGrid) {
          ctx.strokeStyle = '#3c3c3c';
          ctx.lineWidth = 0.5;
          for (let c = 0; c <= gridCols; c++) { ctx.beginPath(); ctx.moveTo(c*tileW, 0); ctx.lineTo(c*tileW, gridRows*tileH); ctx.stroke(); }
          for (let r = 0; r <= gridRows; r++) { ctx.beginPath(); ctx.moveTo(0, r*tileH); ctx.lineTo(gridCols*tileW, r*tileH); ctx.stroke(); }
        }
        if (showIds) {
          ctx.fillStyle = '#fff';
          ctx.font = '10px monospace';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          for (let r = 0; r < gridRows; r++) {
            for (let c = 0; c < gridCols; c++) {
              ctx.fillText(String(r * gridCols + c), c * tileW + tileW/2, r * tileH + tileH/2);
            }
          }
        }
        // Highlight selected
        if (selectedTile >= 0) {
          const sc = selectedTile % gridCols;
          const sr = Math.floor(selectedTile / gridCols);
          ctx.strokeStyle = '#007acc';
          ctx.lineWidth = 2;
          ctx.strokeRect(sc * tileW, sr * tileH, tileW, tileH);
        }
      }

      canvas.addEventListener('click', (e) => {
        const rect = canvas.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        const c = Math.floor(x / tileW);
        const r = Math.floor(y / tileH);
        if (c < gridCols && r < gridRows) {
          selectedTile = r * gridCols + c;
          document.getElementById('tileId').value = selectedTile;
          document.getElementById('statusTile').textContent = 'Tile: ' + selectedTile;
          const props = tileProps[selectedTile] || {};
          document.getElementById('propSolid').checked = !!props.solid;
          document.getElementById('propAnimated').checked = !!props.animated;
          document.getElementById('propSlope').checked = !!props.slope;
          document.getElementById('propHazard').checked = !!props.hazard;
          document.getElementById('tileName').value = props.name || '';
          render();
        }
      });

      function saveCurrentTileProps() {
        if (selectedTile < 0) return;
        tileProps[selectedTile] = {
          solid: document.getElementById('propSolid').checked,
          animated: document.getElementById('propAnimated').checked,
          slope: document.getElementById('propSlope').checked,
          hazard: document.getElementById('propHazard').checked,
          name: document.getElementById('tileName').value,
          slopeAngle: parseInt(document.getElementById('slopeAngle').value),
        };
      }

      ['propSolid','propAnimated','propSlope','propHazard','tileName'].forEach(id => {
        document.getElementById(id).addEventListener('change', saveCurrentTileProps);
      });

      document.getElementById('slopeAngle').addEventListener('input', (e) => {
        document.getElementById('slopeLabel').textContent = e.target.value + '\\u00B0';
        saveCurrentTileProps();
      });

      document.getElementById('tileW').addEventListener('change', (e) => { tileW = parseInt(e.target.value); updateGrid(); });
      document.getElementById('tileH').addEventListener('change', (e) => { tileH = parseInt(e.target.value); updateGrid(); });

      document.getElementById('btnShowGrid').addEventListener('click', (e) => {
        showGrid = !showGrid;
        e.target.classList.toggle('active', showGrid);
        render();
      });
      document.getElementById('btnShowIds').addEventListener('click', (e) => {
        showIds = !showIds;
        e.target.classList.toggle('active', showIds);
        render();
      });

      // Simulate image load with a placeholder
      document.getElementById('btnUpload').addEventListener('click', () => {
        canvas.style.display = 'block';
        document.getElementById('uploadZone').style.display = 'none';
        canvas.width = 256; canvas.height = 256;
        imageLoaded = true;
        updateGrid();
      });

      document.getElementById('btnAddRule').addEventListener('click', () => {
        autoRules.push({ mask: new Array(9).fill(false), target: selectedTile >= 0 ? selectedTile : 0 });
        renderAutoRules();
      });

      function renderAutoRules() {
        const container = document.getElementById('autoRules');
        container.innerHTML = '';
        autoRules.forEach((rule, ri) => {
          const row = document.createElement('div');
          row.className = 'auto-rule';
          const grid = document.createElement('div');
          grid.className = 'auto-rule-grid';
          for (let i = 0; i < 9; i++) {
            const cell = document.createElement('div');
            cell.className = 'auto-rule-cell' + (rule.mask[i] ? ' on' : '');
            cell.addEventListener('click', () => { rule.mask[i] = !rule.mask[i]; renderAutoRules(); });
            grid.appendChild(cell);
          }
          row.appendChild(grid);
          const label = document.createElement('span');
          label.textContent = ' \\u2192 Tile ' + rule.target;
          row.appendChild(label);
          container.appendChild(row);
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
            if (p.slope) lua += ', slope = ' + p.slopeAngle;
            lua += ' },\\n';
          }
        }
        lua += '  }\\n}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });
    `);
  }
}
