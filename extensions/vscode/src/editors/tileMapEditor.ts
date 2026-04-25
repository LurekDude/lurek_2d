import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

export class TileMapEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): TileMapEditor {
    return new TileMapEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.editor.tileMap", "Tile Map Editor");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "tilemap.lua");
        break;
      case "exportToml":
        this.exportToml(msg.content as string, "tilemap.toml");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Tile Map Editor", `
      .editor-layout {
        display: grid; grid-template-columns: 38px 1fr 220px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: var(--bg); }
      .canvas-area canvas { display: block; image-rendering: pixelated; }
      .properties { grid-row: 2; background: var(--surface); border-left: 1px solid var(--border); overflow-y: auto; }

      .palette-grid {
        display: grid; grid-template-columns: repeat(4, 1fr); gap: 2px;
      }
      .palette-tile {
        aspect-ratio: 1; cursor: pointer; border-radius: var(--radius);
        border: 1px solid transparent; transition: border-color 0.1s, transform 0.1s;
        position: relative;
      }
      .palette-tile:hover { border-color: var(--text); transform: scale(1.08); z-index: 1; }
      .palette-tile.selected { border-color: var(--accent); border-width: 2px; }
      .palette-tile .tile-id {
        position: absolute; bottom: 0; right: 0; font-size: 8px;
        background: rgba(0,0,0,0.6); color: var(--text-dim); padding: 0 3px;
        border-radius: 2px 0 2px 0; line-height: 1.4;
      }

      .layer-item {
        display: flex; align-items: center; gap: 4px; padding: 3px 6px;
        font-size: 11px; cursor: pointer; border-radius: var(--radius);
        transition: background 0.08s;
      }
      .layer-item:hover { background: var(--hover); }
      .layer-item.sel { background: var(--selection); }
      .layer-item .vis-btn {
        width: 18px; height: 18px; background: none; border: none;
        cursor: pointer; color: var(--text-dim); padding: 0;
        display: flex; align-items: center; justify-content: center;
      }
      .layer-item .vis-btn:hover { color: var(--accent); background: transparent; border: none; }
      .layer-item .vis-btn svg { width: 12px; height: 12px; }
      .layer-item .name { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
      .layer-actions { display: flex; gap: 2px; margin-bottom: 4px; }
      .layer-actions button { flex: 1; font-size: 10px; padding: 3px 0; }
    `, `
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            <label>Map</label>
            <input type="number" id="mapWidth" value="20" min="1" max="256" style="width:48px" title="Width">
            <span style="color:var(--text-dim)">×</span>
            <input type="number" id="mapHeight" value="15" min="1" max="256" style="width:48px" title="Height">
            <button id="btnResize" title="Apply size" data-tooltip="Resize map">Apply</button>
          </div>
          ${toolbarSep()}
          <div class="group">
            <label>Tile</label>
            <input type="number" id="tileSize" value="32" min="8" max="128" style="width:48px" title="Tile pixel size">
          </div>
          ${toolbarSep()}
          <div class="group">
            ${iconButton('undo', { id: 'btnUndo', title: 'Undo (Ctrl+Z)' })}
            ${iconButton('redo', { id: 'btnRedo', title: 'Redo (Ctrl+Y)' })}
          </div>
          ${toolbarSep()}
          <div class="group">
            ${iconButton('grid', { id: 'btnGrid', title: 'Toggle Grid', className: 'active' })}
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
          <div class="tool-group">
            <button class="icon-btn active" data-tool="paint" title="Paint (B)" data-tooltip="Paint">${ICONS.pen}</button>
            <button class="icon-btn" data-tool="erase" title="Eraser (E)" data-tooltip="Eraser">${ICONS.eraser}</button>
            <button class="icon-btn" data-tool="fill" title="Fill (G)" data-tooltip="Fill">${ICONS.bucket}</button>
          </div>
          <div class="tool-group">
            <button class="icon-btn" data-tool="rect" title="Rectangle (R)" data-tooltip="Rect Fill">${ICONS.rect}</button>
            <button class="icon-btn" data-tool="stamp" title="Stamp (S)" data-tooltip="Stamp">${ICONS.stamp}</button>
          </div>
          <div class="tool-group">
            <button class="icon-btn" data-tool="pick" title="Pick Tile (I)" data-tooltip="Pick">${ICONS.pick}</button>
            <button class="icon-btn" data-tool="hand" title="Pan (H / Middle Mouse)" data-tooltip="Pan">${ICONS.hand}</button>
          </div>
        </div>

        <!-- Canvas -->
        <div class="canvas-area"><canvas id="mapCanvas"></canvas></div>

        <!-- Properties Panel -->
        <div class="properties">
          ${panelSection('Layers', `
            <div class="layer-actions">
              <button id="btnAddLayer">${ICONS.add} Add</button>
              <button id="btnDelLayer">${ICONS.trash} Del</button>
              <button id="btnMoveLayerUp">${ICONS.moveUp}</button>
              <button id="btnMoveLayerDown">${ICONS.moveDown}</button>
            </div>
            <div id="layerList"></div>
          `)}
          ${panelSection('Tile Palette', `
            <div class="palette-grid" id="palette"></div>
          `)}
          ${panelSection('View', `
            <div class="field-row"><input type="checkbox" id="showGrid" checked><label for="showGrid">Grid overlay</label></div>
            <div class="field-row"><input type="checkbox" id="showIds"><label for="showIds">Tile IDs</label></div>
            <div class="field-row"><input type="checkbox" id="showAllLayers" checked><label for="showAllLayers">Show all layers</label></div>
          `)}
          ${panelSection('Tile Properties', `
            <div id="tileProps">
              ${fieldInline('Selected', '<span id="selectedTileId">1</span>')}
              ${fieldInline('Color', '<span id="selectedTileColor" style="display:inline-block;width:14px;height:14px;border-radius:2px;vertical-align:middle;border:1px solid var(--border)"></span>')}
              ${fieldInline('Name', '<input id="tileName" value="" placeholder="unnamed" style="width:100%">')}
              ${fieldInline('Solid', '<input type="checkbox" id="tileSolid">')}
            </div>
          `, true)}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group"><span id="statusPos">0, 0</span></span>
          <div class="sep"></div>
          <span id="statusTool">Paint</span>
          <div class="sep"></div>
          <span id="statusTile">Tile: 1</span>
          <div class="sep"></div>
          <span id="statusLayer">ground</span>
          <div class="spacer"></div>
          <span id="statusSize">20×15</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${ICONS.clean}</span>
        </div>
      </div>
    `, `
      // ── Constants ──────────────────────────────────────
      const TILE_COLORS = [
        '#1a1a2e','#16213e','#0f3460','#533483','#e94560','#4ec9b0',
        '#007acc','#ff9800','#4caf50','#f44336','#9c27b0','#00bcd4',
        '#795548','#607d8b','#ffeb3b','#8bc34a','#e91e63','#673ab7',
        '#2196f3','#009688','#ff5722','#3f51b5','#cddc39','#ffc107',
        '#1b5e20','#bf360c','#0d47a1','#4a148c','#263238','#f5f5f5',
        '#424242','#e0e0e0'
      ];

      // ── State ──────────────────────────────────────────
      const canvas = document.getElementById('mapCanvas');
      const ctx = canvas.getContext('2d');
      const undoStack = new UndoStack(80);

      let mapW = 20, mapH = 15, tileSize = 32;
      let currentTile = 1, currentTool = 'paint';
      let showGrid = true, showIds = false, showAllLayers = true;
      let offsetX = 0, offsetY = 0, zoom = 1;
      let isPanning = false, panStartX = 0, panStartY = 0;
      let isDrawing = false, rectStartX = -1, rectStartY = -1;

      const LAYER_NAMES = ['ground', 'walls', 'objects', 'decor', 'collision'];
      let layerData = {};
      let layerVisible = {};
      let currentLayer = 'ground';
      let tileNames = {};
      let tileSolid = {};

      function initLayer(name) { layerData[name] = new Array(mapW * mapH).fill(0); }
      function initAllLayers() {
        LAYER_NAMES.forEach(n => { initLayer(n); layerVisible[n] = true; });
      }
      initAllLayers();

      function getState() {
        const ld = {};
        for (const k in layerData) ld[k] = [...layerData[k]];
        return { layerData: ld, currentLayer };
      }
      function pushUndo() { undoStack.push(getState()); markDirty(); }

      undoStack.onChange((canUndo, canRedo) => {
        document.getElementById('btnUndo').disabled = !canUndo;
        document.getElementById('btnRedo').disabled = !canRedo;
      });
      document.getElementById('btnUndo').addEventListener('click', () => {
        const prev = undoStack.undo();
        if (prev) { for (const k in prev.layerData) layerData[k] = prev.layerData[k]; render(); }
      });
      document.getElementById('btnRedo').addEventListener('click', () => {
        const next = undoStack.redo();
        if (next) { for (const k in next.layerData) layerData[k] = next.layerData[k]; render(); }
      });
      undoStack.push(getState());

      // ── Canvas Rendering ───────────────────────────────
      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth;
        canvas.height = area.clientHeight;
        render();
      }

      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.save();
        ctx.translate(offsetX, offsetY);
        ctx.scale(zoom, zoom);

        // Background
        ctx.fillStyle = '#1a1a2e';
        ctx.fillRect(0, 0, mapW * tileSize, mapH * tileSize);

        // Render layers
        const layersToShow = showAllLayers ? LAYER_NAMES : [currentLayer];
        for (const lName of layersToShow) {
          if (!layerVisible[lName]) continue;
          const layer = layerData[lName];
          if (!layer) continue;
          const alpha = (lName !== currentLayer && showAllLayers) ? 0.5 : 1;
          ctx.globalAlpha = alpha;
          for (let y = 0; y < mapH; y++) {
            for (let x = 0; x < mapW; x++) {
              const t = layer[y * mapW + x];
              if (t > 0) {
                ctx.fillStyle = TILE_COLORS[(t - 1) % TILE_COLORS.length];
                ctx.fillRect(x * tileSize, y * tileSize, tileSize, tileSize);
              }
            }
          }
          ctx.globalAlpha = 1;
        }

        // Grid
        if (showGrid) {
          ctx.strokeStyle = 'rgba(255,255,255,0.06)';
          ctx.lineWidth = 0.5 / zoom;
          for (let x = 0; x <= mapW; x++) { ctx.beginPath(); ctx.moveTo(x * tileSize, 0); ctx.lineTo(x * tileSize, mapH * tileSize); ctx.stroke(); }
          for (let y = 0; y <= mapH; y++) { ctx.beginPath(); ctx.moveTo(0, y * tileSize); ctx.lineTo(mapW * tileSize, y * tileSize); ctx.stroke(); }
        }

        // Tile IDs
        if (showIds) {
          ctx.fillStyle = '#fff';
          ctx.font = Math.max(8, 10 / zoom) + 'px monospace';
          ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
          const layer = layerData[currentLayer];
          for (let y = 0; y < mapH; y++)
            for (let x = 0; x < mapW; x++) {
              const t = layer[y * mapW + x];
              if (t > 0) ctx.fillText(String(t), x * tileSize + tileSize/2, y * tileSize + tileSize/2);
            }
        }

        // Map border
        ctx.strokeStyle = 'rgba(137,180,250,0.3)';
        ctx.lineWidth = 1 / zoom;
        ctx.strokeRect(0, 0, mapW * tileSize, mapH * tileSize);

        // Rect preview
        if (isDrawing && currentTool === 'rect' && rectStartX >= 0) {
          const { tx, ty } = lastHover;
          const x0 = Math.min(rectStartX, tx), y0 = Math.min(rectStartY, ty);
          const x1 = Math.max(rectStartX, tx), y1 = Math.max(rectStartY, ty);
          ctx.strokeStyle = 'rgba(137,180,250,0.6)';
          ctx.lineWidth = 1 / zoom;
          ctx.setLineDash([4 / zoom, 4 / zoom]);
          ctx.strokeRect(x0 * tileSize, y0 * tileSize, (x1 - x0 + 1) * tileSize, (y1 - y0 + 1) * tileSize);
          ctx.setLineDash([]);
        }

        ctx.restore();
      }
      let lastHover = { tx: 0, ty: 0 };

      // ── Tile Operations ────────────────────────────────
      function screenToTile(sx, sy) {
        const tx = Math.floor((sx - offsetX) / (tileSize * zoom));
        const ty = Math.floor((sy - offsetY) / (tileSize * zoom));
        return { tx, ty };
      }

      function setTile(tx, ty, value) {
        if (tx >= 0 && tx < mapW && ty >= 0 && ty < mapH) {
          layerData[currentLayer][ty * mapW + tx] = value;
        }
      }

      function floodFill(tx, ty, target, replacement) {
        if (target === replacement) return;
        const layer = layerData[currentLayer];
        const stack = [[tx, ty]];
        const visited = new Set();
        while (stack.length) {
          const [x, y] = stack.pop();
          const key = x + ',' + y;
          if (visited.has(key)) continue;
          visited.add(key);
          if (x < 0 || x >= mapW || y < 0 || y >= mapH) continue;
          if (layer[y * mapW + x] !== target) continue;
          layer[y * mapW + x] = replacement;
          stack.push([x-1,y],[x+1,y],[x,y-1],[x,y+1]);
        }
      }

      // ── Input Handlers ─────────────────────────────────
      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || currentTool === 'hand' || (e.altKey && e.button === 0)) {
          isPanning = true; panStartX = e.clientX - offsetX; panStartY = e.clientY - offsetY;
          canvas.style.cursor = 'grabbing'; e.preventDefault(); return;
        }
        if (e.button === 0) {
          pushUndo(); isDrawing = true;
          const { tx, ty } = screenToTile(e.offsetX, e.offsetY);
          if (currentTool === 'paint') { setTile(tx, ty, currentTile); render(); }
          else if (currentTool === 'erase') { setTile(tx, ty, 0); render(); }
          else if (currentTool === 'fill') {
            const layer = layerData[currentLayer];
            if (tx >= 0 && tx < mapW && ty >= 0 && ty < mapH) {
              floodFill(tx, ty, layer[ty*mapW+tx], currentTile); render();
            }
          }
          else if (currentTool === 'pick') {
            const layer = layerData[currentLayer];
            if (tx >= 0 && tx < mapW && ty >= 0 && ty < mapH) {
              currentTile = layer[ty*mapW+tx];
              updateTileDisplay();
            }
          }
          else if (currentTool === 'rect') { rectStartX = tx; rectStartY = ty; }
          else if (currentTool === 'stamp') { setTile(tx, ty, currentTile); render(); }
        }
      });

      canvas.addEventListener('mousemove', (e) => {
        const { tx, ty } = screenToTile(e.offsetX, e.offsetY);
        lastHover = { tx, ty };
        document.getElementById('statusPos').textContent = tx + ', ' + ty;
        if (isPanning) { offsetX = e.clientX - panStartX; offsetY = e.clientY - panStartY; render(); return; }
        if (isDrawing) {
          if (currentTool === 'paint' || currentTool === 'stamp') { setTile(tx, ty, currentTile); render(); }
          else if (currentTool === 'erase') { setTile(tx, ty, 0); render(); }
          else if (currentTool === 'rect') { render(); }
        }
      });

      canvas.addEventListener('mouseup', (e) => {
        canvas.style.cursor = '';
        if (isPanning) { isPanning = false; return; }
        if (isDrawing && currentTool === 'rect') {
          const { tx, ty } = screenToTile(e.offsetX, e.offsetY);
          const x0 = Math.min(rectStartX, tx), x1 = Math.max(rectStartX, tx);
          const y0 = Math.min(rectStartY, ty), y1 = Math.max(rectStartY, ty);
          for (let ry = y0; ry <= y1; ry++)
            for (let rx = x0; rx <= x1; rx++) setTile(rx, ry, currentTile);
          render();
        }
        isDrawing = false;
      });

      canvas.addEventListener('contextmenu', (e) => e.preventDefault());

      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const oldZoom = zoom;
        zoom *= e.deltaY < 0 ? 1.1 : 0.9;
        zoom = Math.max(0.1, Math.min(5, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / oldZoom;
        offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / oldZoom;
        render();
      }, { passive: false });

      // ── Tool Selection ─────────────────────────────────
      const toolKeys = { b: 'paint', e: 'erase', g: 'fill', r: 'rect', s: 'stamp', i: 'pick', h: 'hand' };
      Object.entries(toolKeys).forEach(([key, tool]) => {
        registerShortcut(key, () => { selectTool(tool); });
      });

      function selectTool(tool) {
        currentTool = tool;
        document.querySelectorAll('#tools .icon-btn').forEach(b => {
          b.classList.toggle('active', b.dataset.tool === tool);
        });
        document.getElementById('statusTool').textContent = tool.charAt(0).toUpperCase() + tool.slice(1);
      }

      document.getElementById('tools').addEventListener('click', (e) => {
        const btn = e.target.closest('[data-tool]');
        if (btn) selectTool(btn.dataset.tool);
      });

      // ── Palette ────────────────────────────────────────
      const paletteEl = document.getElementById('palette');
      for (let i = 0; i <= 31; i++) {
        const el = document.createElement('div');
        el.className = 'palette-tile' + (i === 1 ? ' selected' : '');
        if (i === 0) {
          el.style.background = 'repeating-conic-gradient(#333 0% 25%, #222 0% 50%) 50% / 8px 8px';
        } else {
          el.style.background = TILE_COLORS[(i-1) % TILE_COLORS.length];
        }
        el.innerHTML = '<span class="tile-id">' + i + '</span>';
        el.title = 'Tile ' + i;
        el.addEventListener('click', () => { currentTile = i; updateTileDisplay(); });
        paletteEl.appendChild(el);
      }

      function updateTileDisplay() {
        paletteEl.querySelectorAll('.palette-tile').forEach((t, idx) => {
          t.classList.toggle('selected', idx === currentTile);
        });
        document.getElementById('statusTile').textContent = 'Tile: ' + currentTile;
        document.getElementById('selectedTileId').textContent = currentTile;
        const color = currentTile > 0 ? TILE_COLORS[(currentTile-1) % TILE_COLORS.length] : 'transparent';
        document.getElementById('selectedTileColor').style.background = color;
        document.getElementById('tileName').value = tileNames[currentTile] || '';
        document.getElementById('tileSolid').checked = !!tileSolid[currentTile];
      }
      updateTileDisplay();

      document.getElementById('tileName').addEventListener('change', (e) => { tileNames[currentTile] = e.target.value; });
      document.getElementById('tileSolid').addEventListener('change', (e) => { tileSolid[currentTile] = e.target.checked; });

      // ── Grid / View ────────────────────────────────────
      document.getElementById('btnGrid').addEventListener('click', function() {
        showGrid = !showGrid; this.classList.toggle('active', showGrid); render();
      });
      document.getElementById('showGrid').addEventListener('change', (e) => {
        showGrid = e.target.checked;
        document.getElementById('btnGrid').classList.toggle('active', showGrid);
        render();
      });
      document.getElementById('showIds').addEventListener('change', (e) => { showIds = e.target.checked; render(); });
      document.getElementById('showAllLayers').addEventListener('change', (e) => { showAllLayers = e.target.checked; render(); });

      // ── Resize ─────────────────────────────────────────
      document.getElementById('btnResize').addEventListener('click', () => {
        const nw = Math.min(256, Math.max(1, parseInt(document.getElementById('mapWidth').value) || 20));
        const nh = Math.min(256, Math.max(1, parseInt(document.getElementById('mapHeight').value) || 15));
        const newTs = parseInt(document.getElementById('tileSize').value) || 32;
        pushUndo();
        // Preserve existing data where possible
        for (const k of LAYER_NAMES) {
          const oldData = layerData[k] || [];
          const newData = new Array(nw * nh).fill(0);
          const copyW = Math.min(mapW, nw), copyH = Math.min(mapH, nh);
          for (let y = 0; y < copyH; y++)
            for (let x = 0; x < copyW; x++)
              newData[y * nw + x] = oldData[y * mapW + x] || 0;
          layerData[k] = newData;
        }
        mapW = nw; mapH = nh; tileSize = newTs;
        document.getElementById('statusSize').textContent = mapW + '×' + mapH;
        render();
        showToast('Resized to ' + mapW + '×' + mapH, 'info');
      });

      // ── Layers ─────────────────────────────────────────
      function refreshLayers() {
        const el = document.getElementById('layerList');
        el.innerHTML = '';
        LAYER_NAMES.forEach(name => {
          const div = document.createElement('div');
          div.className = 'layer-item' + (name === currentLayer ? ' sel' : '');
          const visIcon = layerVisible[name] ? '${ICONS.eye}' : '${ICONS.eyeOff}';
          div.innerHTML = '<button class="vis-btn" title="Toggle">' + visIcon + '</button>' +
            '<span class="name">' + name + '</span>';
          div.querySelector('.vis-btn').addEventListener('click', (ev) => {
            ev.stopPropagation();
            layerVisible[name] = !layerVisible[name]; refreshLayers(); render();
          });
          div.addEventListener('click', () => {
            currentLayer = name; refreshLayers();
            document.getElementById('statusLayer').textContent = name;
            render();
          });
          el.appendChild(div);
        });
      }

      document.getElementById('btnAddLayer').addEventListener('click', () => {
        const name = 'layer_' + LAYER_NAMES.length;
        LAYER_NAMES.push(name);
        layerData[name] = new Array(mapW * mapH).fill(0);
        layerVisible[name] = true;
        currentLayer = name;
        refreshLayers(); render();
        showToast('Added layer: ' + name, 'info');
      });
      document.getElementById('btnDelLayer').addEventListener('click', () => {
        if (LAYER_NAMES.length <= 1) { showToast('Cannot delete last layer', 'warn'); return; }
        pushUndo();
        const idx = LAYER_NAMES.indexOf(currentLayer);
        delete layerData[currentLayer]; delete layerVisible[currentLayer];
        LAYER_NAMES.splice(idx, 1);
        currentLayer = LAYER_NAMES[Math.min(idx, LAYER_NAMES.length - 1)];
        refreshLayers(); render();
      });
      document.getElementById('btnMoveLayerUp').addEventListener('click', () => {
        const idx = LAYER_NAMES.indexOf(currentLayer);
        if (idx >= LAYER_NAMES.length - 1) return;
        [LAYER_NAMES[idx], LAYER_NAMES[idx+1]] = [LAYER_NAMES[idx+1], LAYER_NAMES[idx]];
        refreshLayers(); render();
      });
      document.getElementById('btnMoveLayerDown').addEventListener('click', () => {
        const idx = LAYER_NAMES.indexOf(currentLayer);
        if (idx <= 0) return;
        [LAYER_NAMES[idx], LAYER_NAMES[idx-1]] = [LAYER_NAMES[idx-1], LAYER_NAMES[idx]];
        refreshLayers(); render();
      });
      refreshLayers();

      // ── Export ─────────────────────────────────────────
      function generateExportData() {
        const data = { width: mapW, height: mapH, tileSize: tileSize, layers: {} };
        for (const k of LAYER_NAMES) data.layers[k] = Array.from(layerData[k]);
        return data;
      }

      function buildLuaCode() {
        const d = generateExportData();
        const lines = ['-- Generated by Lurek2D Tile Map Editor'];
        lines.push('-- Usage: local map = lurek.tilemap.new(data)');
        lines.push('');
        lines.push('return {');
        lines.push('  width = ' + d.width + ',');
        lines.push('  height = ' + d.height + ',');
        lines.push('  tile_size = ' + d.tileSize + ',');

        // Tile properties
        const solidTiles = Object.entries(tileSolid).filter(([,v]) => v).map(([k]) => k);
        if (solidTiles.length > 0) {
          lines.push('  solid_tiles = {' + solidTiles.join(', ') + '},');
        }

        lines.push('  layers = {');
        for (const k of LAYER_NAMES) {
          // Row-by-row for readability
          lines.push('    ' + k + ' = {');
          for (let y = 0; y < d.height; y++) {
            const row = d.layers[k].slice(y * d.width, (y + 1) * d.width);
            const comma = y < d.height - 1 ? ',' : '';
            lines.push('      {' + row.join(',') + '}' + comma);
          }
          lines.push('    },');
        }
        lines.push('  }');
        lines.push('}');
        return lines.join('\\n');
      }

      function buildToml() {
        const d = generateExportData();
        let toml = '# Generated by Lurek2D Tile Map Editor\\n';
        toml += 'width = ' + d.width + '\\n';
        toml += 'height = ' + d.height + '\\n';
        toml += 'tile_size = ' + d.tileSize + '\\n\\n';
        for (const k of LAYER_NAMES) {
          toml += '[layers.' + k + ']\\n';
          toml += 'data = [' + d.layers[k].join(', ') + ']\\n\\n';
        }
        return toml;
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export Lua', action: () => vscode.postMessage({ type: 'exportLua', content: buildLuaCode() }) },
        { label: 'Export TOML', action: () => vscode.postMessage({ type: 'exportToml', content: buildToml() }) },
        { label: 'Copy Lua Code', action: () => vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() }) },
        { label: 'Insert Lua to Editor', action: () => vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() }) },
      ]);

      document.getElementById('btnCopyLua').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() });
      });

      // ── Init ───────────────────────────────────────────
      function centerCanvas() {
        const area = canvas.parentElement;
        const totalW = mapW * tileSize * zoom, totalH = mapH * tileSize * zoom;
        offsetX = (area.clientWidth - totalW) / 2;
        offsetY = (area.clientHeight - totalH) / 2;
      }
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
      centerCanvas();
      render();
    `);
  }
}
