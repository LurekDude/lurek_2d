import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

export class VoxelEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): VoxelEditor {
    return new VoxelEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.editor.voxel", "Voxel Editor");
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
        display: grid; grid-template-columns: 44px 1fr 1fr 200px;
        grid-template-rows: auto 1fr 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .tool-rail {
        grid-row: 2 / 4; background: var(--surface); border-right: 1px solid var(--border);
        display: flex; flex-direction: column; align-items: center; padding: 4px 2px; gap: 2px;
      }
      .tool-rail button {
        width: 36px; height: 36px; padding: 0; border-radius: var(--radius);
        display: flex; align-items: center; justify-content: center;
        border: 1px solid transparent; background: transparent; color: var(--text); cursor: pointer;
      }
      .tool-rail button:hover { background: var(--hover); }
      .tool-rail button.active { background: var(--accent); color: var(--bg); border-color: var(--accent); }
      .top-view { grid-row: 2; grid-column: 2; position: relative; overflow: hidden; border-bottom: 1px solid var(--border); border-right: 1px solid var(--border); background: #111; }
      .side-view { grid-row: 3; grid-column: 2; position: relative; overflow: hidden; border-right: 1px solid var(--border); background: #111; }
      .iso-view { grid-row: 2 / 4; grid-column: 3; position: relative; overflow: hidden; background: #111; }
      .right-panel { grid-row: 2 / 4; border-left: 1px solid var(--border); overflow-y: auto; background: var(--surface); }
      .view-label {
        position: absolute; top: 4px; left: 8px; font-size: 10px; color: var(--text-dim);
        background: var(--surface); padding: 1px 6px; border-radius: 9px; z-index: 1;
        text-transform: uppercase; letter-spacing: 0.3px; font-weight: 600;
      }
      .color-well {
        width: 100%; height: 28px; border: 1px solid var(--border); border-radius: var(--radius);
        cursor: pointer; margin-bottom: 6px;
      }
      .palette-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 2px; }
      .palette-grid div {
        aspect-ratio: 1; border-radius: 3px; cursor: pointer;
        border: 1px solid rgba(255,255,255,0.08); transition: border-color 0.1s;
      }
      .palette-grid div:hover { border-color: var(--accent); }
      .layer-btn {
        width: 100%; margin-bottom: 1px; font-size: 10px; text-align: left; padding: 3px 6px;
        border-radius: var(--radius); cursor: pointer; border: 1px solid transparent;
        background: transparent; color: var(--text);
      }
      .layer-btn:hover { background: var(--hover); }
      .layer-btn.sel { background: var(--accent); color: var(--bg); font-weight: 600; }
    `, `
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            <label style="font-size:11px">Grid:</label>
            <select id="gridSize"><option value="8">8³</option><option value="16" selected>16³</option><option value="32">32³</option></select>
            <label style="font-size:11px">Z:</label>
            <input type="number" id="layerZ" value="0" min="0" max="15" style="width:38px">
          </div>
          ${toolbarSep()}
          <div class="group">
            ${iconButton('undo', { id: 'btnUndo', title: 'Undo (Ctrl+Z)' })}
            ${iconButton('redo', { id: 'btnRedo', title: 'Redo (Ctrl+Y)' })}
          </div>
          ${toolbarSep()}
          <div class="group">
            ${iconButton('trash', { id: 'btnClear', title: 'Clear All', cls: 'danger' })}
          </div>
          ${toolbarSpacer()}
          <div class="group">
            ${iconButton('copy', { id: 'btnCopyLua', title: 'Copy Lua Code' })}
            ${iconButton('insert', { id: 'btnInsert', title: 'Insert to Editor' })}
          </div>
          ${toolbarSep()}
          <button id="btnExport" class="primary">${ICONS.exportFile} Export ▾</button>
        </div>

        <!-- Tool Rail -->
        <div class="tool-rail" id="tools">
          <button class="active" data-tool="pen" title="Pen (P)">${ICONS.pencil}</button>
          <button data-tool="erase" title="Eraser (E)">${ICONS.eraser}</button>
          <button data-tool="fill" title="Fill Layer (F)">${ICONS.bucket}</button>
        </div>

        <!-- Views -->
        <div class="top-view"><span class="view-label">Top XY — Layer Z</span><canvas id="topCanvas"></canvas></div>
        <div class="side-view"><span class="view-label">Side XZ</span><canvas id="sideCanvas"></canvas></div>
        <div class="iso-view"><span class="view-label">3D Isometric</span><canvas id="isoCanvas"></canvas></div>

        <!-- Right Panel -->
        <div class="right-panel">
          ${panelSection('Color', `
            <input type="color" id="voxelColor" value="#4ec9b0" class="color-well">
            <div id="palette" class="palette-grid"></div>
          `)}
          ${panelSection('Layers (Z)', '<div id="layerList"></div>')}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span id="statusPos">0, 0, 0</span>
          <div class="sep"></div>
          <span id="statusVoxels" class="badge">0 voxels</span>
          <div class="sep"></div>
          <span id="statusTool">Pen</span>
          <div class="spacer"></div>
          <span class="dirty-indicator">${ICONS.clean}</span>
        </div>
      </div>
    `, `
      const PALETTE = ['#4ec9b0','#007acc','#f44336','#ff9800','#4caf50','#9c27b0','#ffeb3b','#795548','#ffffff','#888888','#444444','#000000','#ff77a8','#29adff','#00e436','#ab5236'];
      let gridSize = 16, currentZ = 0, currentColor = '#4ec9b0', currentTool = 'pen';
      let voxels = {};
      const undo = new UndoStack(40);

      function snapshot() { return JSON.parse(JSON.stringify(voxels)); }
      function restoreSnap(s) { voxels = s; refreshLayers(); renderAll(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      function vKey(x, y, z) { return x + ',' + y + ',' + z; }
      function setVoxel(x, y, z, color) { if (color) voxels[vKey(x,y,z)] = color; else delete voxels[vKey(x,y,z)]; }
      function getVoxel(x, y, z) { return voxels[vKey(x,y,z)] || null; }
      function countVoxels() { return Object.keys(voxels).length; }

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
        sideCtx.strokeStyle = 'var(--accent, #89b4fa)'; sideCtx.lineWidth = 2;
        sideCtx.strokeRect(0, (gridSize - 1 - currentZ) * cs, gridSize * cs, cs);
      }

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
        for (let z = 0; z < gridSize; z++) for (let y = 0; y < gridSize; y++) for (let x = 0; x < gridSize; x++) {
          const c = getVoxel(x, y, z);
          if (!c) continue;
          const { px, py } = isoProject(x, y, z);
          isoCtx.fillStyle = c;
          isoCtx.beginPath(); isoCtx.moveTo(px, py - cs * 0.5); isoCtx.lineTo(px + cs, py); isoCtx.lineTo(px, py + cs * 0.5); isoCtx.lineTo(px - cs, py); isoCtx.closePath(); isoCtx.fill();
          isoCtx.fillStyle = darken(c, 0.7);
          isoCtx.beginPath(); isoCtx.moveTo(px - cs, py); isoCtx.lineTo(px, py + cs * 0.5); isoCtx.lineTo(px, py + cs * 0.5 + cs); isoCtx.lineTo(px - cs, py + cs); isoCtx.closePath(); isoCtx.fill();
          isoCtx.fillStyle = darken(c, 0.85);
          isoCtx.beginPath(); isoCtx.moveTo(px + cs, py); isoCtx.lineTo(px, py + cs * 0.5); isoCtx.lineTo(px, py + cs * 0.5 + cs); isoCtx.lineTo(px + cs, py + cs); isoCtx.closePath(); isoCtx.fill();
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
        document.getElementById('statusVoxels').textContent = countVoxels() + ' voxels';
        document.getElementById('statusTool').textContent = currentTool.charAt(0).toUpperCase() + currentTool.slice(1);
      }

      let isDrawing = false;
      topCanvas.addEventListener('mousedown', (e) => { isDrawing = true; pushUndo(); handleTopClick(e); });
      topCanvas.addEventListener('mousemove', (e) => {
        if (isDrawing) handleTopClick(e);
        const cs = Math.min(Math.floor(topCanvas.width / gridSize), Math.floor(topCanvas.height / gridSize));
        const x = Math.floor(e.offsetX / cs), y = Math.floor(e.offsetY / cs);
        document.getElementById('statusPos').textContent = x + ', ' + y + ', ' + currentZ;
      });
      topCanvas.addEventListener('mouseup', () => { isDrawing = false; });

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

      document.getElementById('tools').addEventListener('click', (e) => {
        const btn = e.target.closest('[data-tool]');
        if (!btn) return;
        document.getElementById('tools').querySelectorAll('button').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentTool = btn.dataset.tool;
        updateStatus();
      });

      document.getElementById('layerZ').addEventListener('input', (e) => {
        currentZ = Math.max(0, Math.min(gridSize - 1, parseInt(e.target.value) || 0));
        refreshLayers(); renderAll();
      });

      document.getElementById('gridSize').addEventListener('change', (e) => {
        pushUndo(); gridSize = parseInt(e.target.value);
        voxels = {}; currentZ = 0;
        document.getElementById('layerZ').max = String(gridSize - 1);
        document.getElementById('layerZ').value = '0';
        refreshLayers(); renderAll();
      });

      const paletteEl = document.getElementById('palette');
      PALETTE.forEach(c => {
        const div = document.createElement('div');
        div.style.background = c;
        div.addEventListener('click', () => { currentColor = c; document.getElementById('voxelColor').value = c; });
        paletteEl.appendChild(div);
      });
      document.getElementById('voxelColor').addEventListener('input', (e) => { currentColor = e.target.value; });

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
            currentZ = z; document.getElementById('layerZ').value = String(z);
            refreshLayers(); renderAll();
          });
          el.appendChild(btn);
        }
      }

      // ── Buttons ────────────────────────────────────────
      document.getElementById('btnClear').addEventListener('click', () => { pushUndo(); voxels = {}; renderAll(); refreshLayers(); });
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restoreSnap(s); });

      // ── Shortcuts ──────────────────────────────────────
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('p', () => { document.querySelector('[data-tool="pen"]').click(); });
      registerShortcut('e', () => { document.querySelector('[data-tool="erase"]').click(); });
      registerShortcut('f', () => { document.querySelector('[data-tool="fill"]').click(); });

      // ── Export ─────────────────────────────────────────
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Voxel Editor', ''];
        lines.push('return {');
        lines.push('  size = ' + gridSize + ',');
        lines.push('  voxels = {');
        for (const [key, color] of Object.entries(voxels)) {
          const [x, y, z] = key.split(',');
          lines.push('    { x = ' + x + ', y = ' + y + ', z = ' + z + ', color = "' + color + '" },');
        }
        lines.push('  }');
        lines.push('}');
        return lines.join('\\n');
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export Lua File', action: () => vscode.postMessage({ type: 'exportLua', content: buildLuaCode() }) },
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
      refreshLayers();
      window.addEventListener('resize', renderAll);
      renderAll();
    `);
  }
}
