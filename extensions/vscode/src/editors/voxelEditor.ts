import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class VoxelEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): VoxelEditor {
    return new VoxelEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "luna.editor.voxel", "Voxel Editor");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "voxel_model.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Voxel Editor", `
      .editor-layout {
        display: grid; grid-template-columns: 48px 1fr 1fr 180px;
        grid-template-rows: auto 1fr 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .tool-sidebar { grid-row: 2 / 4; background: var(--surface); border-right: 1px solid var(--border); display: flex; flex-direction: column; align-items: center; padding: 4px; gap: 2px; }
      .tool-sidebar button { width: 36px; height: 36px; font-size: 16px; padding: 0; }
      .top-view { grid-row: 2; grid-column: 2; position: relative; overflow: hidden; border-bottom: 1px solid var(--border); border-right: 1px solid var(--border); }
      .side-view { grid-row: 3; grid-column: 2; position: relative; overflow: hidden; border-right: 1px solid var(--border); }
      .iso-view { grid-row: 2 / 4; grid-column: 3; position: relative; overflow: hidden; }
      .right-panel { grid-row: 2 / 4; border-left: 1px solid var(--border); padding: 8px; overflow-y: auto; background: var(--surface); }
      .status-bar { grid-column: 1 / -1; }
      .view-label {
        position: absolute; top: 4px; left: 8px; font-size: 11px; color: var(--text-dim);
        background: var(--surface); padding: 1px 6px; border-radius: 2px; z-index: 1;
      }
      .layer-btn { width: 100%; margin-bottom: 2px; font-size: 11px; text-align: left; }
      .layer-btn.sel { background: var(--accent); }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <label>Grid:</label>
          <select id="gridSize"><option value="8">8x8x8</option><option value="16" selected>16x16x16</option><option value="32">32x32x32</option></select>
          <label>Layer (Z):</label><input type="number" id="layerZ" value="0" min="0" max="15" style="width:40px">
          <div class="sep"></div>
          <button id="btnClear" class="danger">Clear</button>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="tool-sidebar" id="tools">
          <button class="active" data-tool="pen" title="Pen">&#9998;</button>
          <button data-tool="erase" title="Erase">&#9003;</button>
          <button data-tool="fill" title="Fill Layer">&#9636;</button>
        </div>
        <div class="top-view"><span class="view-label">Top (XY) — Layer Z</span><canvas id="topCanvas"></canvas></div>
        <div class="side-view"><span class="view-label">Side (XZ)</span><canvas id="sideCanvas"></canvas></div>
        <div class="iso-view"><span class="view-label">3D Isometric</span><canvas id="isoCanvas"></canvas></div>
        <div class="right-panel">
          <h3>Color</h3>
          <input type="color" id="voxelColor" value="#4ec9b0" style="width:100%;height:30px;border:none;cursor:pointer">
          <div class="section" style="margin-top: 8px;">
            <h3>Palette</h3>
            <div id="palette" style="display:grid;grid-template-columns:repeat(4,1fr);gap:2px;"></div>
          </div>
          <div class="section" style="margin-top: 12px;">
            <h3>Layers (Z)</h3>
            <div id="layerList"></div>
          </div>
        </div>
        <div class="status-bar">
          <span id="statusPos">Pos: 0, 0, 0</span>
          <span id="statusVoxels">Voxels: 0</span>
        </div>
      </div>
    `, `
      const PALETTE = ['#4ec9b0','#007acc','#f44336','#ff9800','#4caf50','#9c27b0','#ffeb3b','#795548','#ffffff','#888888','#444444','#000000','#ff77a8','#29adff','#00e436','#ab5236'];
      let gridSize = 16, currentZ = 0, currentColor = '#4ec9b0', currentTool = 'pen';
      let voxels = {}; // key "x,y,z" => color

      function vKey(x, y, z) { return x + ',' + y + ',' + z; }
      function setVoxel(x, y, z, color) { if (color) voxels[vKey(x,y,z)] = color; else delete voxels[vKey(x,y,z)]; }
      function getVoxel(x, y, z) { return voxels[vKey(x,y,z)] || null; }

      function countVoxels() { return Object.keys(voxels).length; }

      // Top view (XY at layer Z)
      const topCanvas = document.getElementById('topCanvas');
      const topCtx = topCanvas.getContext('2d');
      function renderTop() {
        const area = topCanvas.parentElement;
        topCanvas.width = area.clientWidth; topCanvas.height = area.clientHeight;
        const cs = Math.min(Math.floor(topCanvas.width / gridSize), Math.floor(topCanvas.height / gridSize));
        topCtx.clearRect(0, 0, topCanvas.width, topCanvas.height);
        for (let y = 0; y < gridSize; y++) for (let x = 0; x < gridSize; x++) {
          const c = getVoxel(x, y, currentZ);
          topCtx.fillStyle = c || ((x + y) % 2 === 0 ? '#1a1a1a' : '#222');
          topCtx.fillRect(x * cs, y * cs, cs, cs);
          topCtx.strokeStyle = '#333'; topCtx.lineWidth = 0.5;
          topCtx.strokeRect(x * cs, y * cs, cs, cs);
        }
      }

      // Side view (XZ at center Y)
      const sideCanvas = document.getElementById('sideCanvas');
      const sideCtx = sideCanvas.getContext('2d');
      function renderSide() {
        const area = sideCanvas.parentElement;
        sideCanvas.width = area.clientWidth; sideCanvas.height = area.clientHeight;
        const cs = Math.min(Math.floor(sideCanvas.width / gridSize), Math.floor(sideCanvas.height / gridSize));
        sideCtx.clearRect(0, 0, sideCanvas.width, sideCanvas.height);
        const midY = Math.floor(gridSize / 2);
        for (let z = 0; z < gridSize; z++) for (let x = 0; x < gridSize; x++) {
          const c = getVoxel(x, midY, z);
          sideCtx.fillStyle = c || ((x + z) % 2 === 0 ? '#1a1a1a' : '#222');
          sideCtx.fillRect(x * cs, (gridSize - 1 - z) * cs, cs, cs);
          sideCtx.strokeStyle = '#333'; sideCtx.lineWidth = 0.5;
          sideCtx.strokeRect(x * cs, (gridSize - 1 - z) * cs, cs, cs);
        }
        // Highlight current Z
        sideCtx.strokeStyle = '#007acc'; sideCtx.lineWidth = 2;
        sideCtx.strokeRect(0, (gridSize - 1 - currentZ) * cs, gridSize * cs, cs);
      }

      // Iso view
      const isoCanvas = document.getElementById('isoCanvas');
      const isoCtx = isoCanvas.getContext('2d');
      function renderIso() {
        const area = isoCanvas.parentElement;
        isoCanvas.width = area.clientWidth; isoCanvas.height = area.clientHeight;
        isoCtx.clearRect(0, 0, isoCanvas.width, isoCanvas.height);
        const cs = Math.min(Math.floor(isoCanvas.width / (gridSize * 2.5)), Math.floor(isoCanvas.height / (gridSize * 2)), 8);
        const ox = isoCanvas.width / 2, oy = 40;

        function isoProject(x, y, z) {
          return { px: ox + (x - y) * cs, py: oy + (x + y) * cs * 0.5 - z * cs };
        }

        // Render back to front
        for (let z = 0; z < gridSize; z++) {
          for (let y = 0; y < gridSize; y++) {
            for (let x = 0; x < gridSize; x++) {
              const c = getVoxel(x, y, z);
              if (!c) continue;
              const { px, py } = isoProject(x, y, z);
              // Top face
              isoCtx.fillStyle = c;
              isoCtx.beginPath();
              isoCtx.moveTo(px, py - cs * 0.5);
              isoCtx.lineTo(px + cs, py);
              isoCtx.lineTo(px, py + cs * 0.5);
              isoCtx.lineTo(px - cs, py);
              isoCtx.closePath(); isoCtx.fill();
              // Left face
              isoCtx.fillStyle = darken(c, 0.7);
              isoCtx.beginPath();
              isoCtx.moveTo(px - cs, py);
              isoCtx.lineTo(px, py + cs * 0.5);
              isoCtx.lineTo(px, py + cs * 0.5 + cs);
              isoCtx.lineTo(px - cs, py + cs);
              isoCtx.closePath(); isoCtx.fill();
              // Right face
              isoCtx.fillStyle = darken(c, 0.85);
              isoCtx.beginPath();
              isoCtx.moveTo(px + cs, py);
              isoCtx.lineTo(px, py + cs * 0.5);
              isoCtx.lineTo(px, py + cs * 0.5 + cs);
              isoCtx.lineTo(px + cs, py + cs);
              isoCtx.closePath(); isoCtx.fill();
            }
          }
        }
      }

      function darken(hex, factor) {
        const r = Math.round(parseInt(hex.slice(1,3), 16) * factor);
        const g = Math.round(parseInt(hex.slice(3,5), 16) * factor);
        const b = Math.round(parseInt(hex.slice(5,7), 16) * factor);
        return '#' + [r,g,b].map(v => v.toString(16).padStart(2,'0')).join('');
      }

      function renderAll() { renderTop(); renderSide(); renderIso(); updateStatus(); }

      function updateStatus() {
        document.getElementById('statusVoxels').textContent = 'Voxels: ' + countVoxels();
      }

      // Top canvas interaction
      topCanvas.addEventListener('mousedown', (e) => handleTopClick(e));
      topCanvas.addEventListener('mousemove', (e) => {
        if (e.buttons === 1) handleTopClick(e);
        const cs = Math.min(Math.floor(topCanvas.width / gridSize), Math.floor(topCanvas.height / gridSize));
        const x = Math.floor(e.offsetX / cs), y = Math.floor(e.offsetY / cs);
        document.getElementById('statusPos').textContent = 'Pos: ' + x + ', ' + y + ', ' + currentZ;
      });

      function handleTopClick(e) {
        const cs = Math.min(Math.floor(topCanvas.width / gridSize), Math.floor(topCanvas.height / gridSize));
        const x = Math.floor(e.offsetX / cs), y = Math.floor(e.offsetY / cs);
        if (x < 0 || x >= gridSize || y < 0 || y >= gridSize) return;
        if (currentTool === 'pen') setVoxel(x, y, currentZ, currentColor);
        else if (currentTool === 'erase') setVoxel(x, y, currentZ, null);
        else if (currentTool === 'fill') {
          for (let fy = 0; fy < gridSize; fy++) for (let fx = 0; fx < gridSize; fx++) setVoxel(fx, fy, currentZ, currentColor);
        }
        renderAll();
      }

      // Tools
      document.getElementById('tools').addEventListener('click', (e) => {
        const btn = e.target.closest('[data-tool]');
        if (!btn) return;
        document.getElementById('tools').querySelectorAll('button').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentTool = btn.dataset.tool;
      });

      // Layer Z
      document.getElementById('layerZ').addEventListener('input', (e) => {
        currentZ = Math.max(0, Math.min(gridSize - 1, parseInt(e.target.value) || 0));
        refreshLayers(); renderAll();
      });

      // Grid size
      document.getElementById('gridSize').addEventListener('change', (e) => {
        gridSize = parseInt(e.target.value);
        voxels = {}; currentZ = 0;
        document.getElementById('layerZ').max = String(gridSize - 1);
        document.getElementById('layerZ').value = '0';
        refreshLayers(); renderAll();
      });

      // Palette
      const paletteEl = document.getElementById('palette');
      PALETTE.forEach(c => {
        const div = document.createElement('div');
        div.style.cssText = 'aspect-ratio:1;background:' + c + ';cursor:pointer;border:1px solid #555;border-radius:2px;';
        div.addEventListener('click', () => {
          currentColor = c;
          document.getElementById('voxelColor').value = c;
        });
        paletteEl.appendChild(div);
      });
      document.getElementById('voxelColor').addEventListener('input', (e) => { currentColor = e.target.value; });

      // Layers
      function refreshLayers() {
        const el = document.getElementById('layerList');
        el.innerHTML = '';
        for (let z = gridSize - 1; z >= 0; z--) {
          const btn = document.createElement('button');
          btn.className = 'layer-btn' + (z === currentZ ? ' sel' : '');
          let count = 0;
          for (let y = 0; y < gridSize; y++) for (let x = 0; x < gridSize; x++) if (getVoxel(x, y, z)) count++;
          btn.textContent = 'Z=' + z + (count > 0 ? ' (' + count + ')' : '');
          btn.addEventListener('click', () => {
            currentZ = z;
            document.getElementById('layerZ').value = String(z);
            refreshLayers(); renderAll();
          });
          el.appendChild(btn);
        }
      }

      document.getElementById('btnClear').addEventListener('click', () => { voxels = {}; renderAll(); refreshLayers(); });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  size = ' + gridSize + ',\\n  voxels = {\\n';
        for (const [key, color] of Object.entries(voxels)) {
          const [x, y, z] = key.split(',');
          lua += '    { x = ' + x + ', y = ' + y + ', z = ' + z + ', color = "' + color + '" },\\n';
        }
        lua += '  }\\n}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      refreshLayers();
      window.addEventListener('resize', renderAll);
      renderAll();
    `);
  }
}
