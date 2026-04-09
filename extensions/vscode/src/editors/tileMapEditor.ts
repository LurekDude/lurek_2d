import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class TileMapEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): TileMapEditor {
    return new TileMapEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "luna.editor.tileMap", "Tile Map Editor");
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
        display: grid; grid-template-columns: 200px 1fr; grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .side-panel { grid-row: 2; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; }
      .status-bar { grid-column: 1 / -1; }
      .palette-grid {
        display: grid; grid-template-columns: repeat(4, 1fr); gap: 2px; margin-top: 6px;
      }
      .palette-tile {
        width: 100%; aspect-ratio: 1; border: 1px solid var(--border); cursor: pointer;
        border-radius: 2px;
      }
      .palette-tile.selected { border-color: var(--accent); border-width: 2px; }
      .tool-list { display: flex; flex-direction: column; gap: 2px; margin-top: 6px; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <label>Width:</label><input type="number" id="mapWidth" value="20" min="1" max="200" style="width:50px">
          <label>Height:</label><input type="number" id="mapHeight" value="15" min="1" max="200" style="width:50px">
          <label>Tile Size:</label><input type="number" id="tileSize" value="32" min="8" max="128" style="width:50px">
          <div class="sep"></div>
          <label>Layer:</label>
          <select id="layerSelect"><option value="ground">Ground</option><option value="walls">Walls</option><option value="objects">Objects</option></select>
          <div class="sep"></div>
          <button id="btnResize">Resize</button>
          <button id="btnClear">Clear Layer</button>
          <div class="sep"></div>
          <button id="btnExportLua">Export Lua</button>
          <button id="btnExportToml">Export TOML</button>
        </div>
        <div class="panel side-panel">
          <div class="section">
            <h3>Tools</h3>
            <div class="tool-list" id="toolList">
              <button class="active" data-tool="paint">&#9998; Paint</button>
              <button data-tool="erase">&#9003; Erase</button>
              <button data-tool="fill">&#9636; Fill</button>
              <button data-tool="pick">&#128270; Pick</button>
              <button data-tool="rect">&#9645; Rect</button>
            </div>
          </div>
          <div class="section">
            <h3>Tile Palette</h3>
            <div class="palette-grid" id="palette"></div>
          </div>
          <div class="section">
            <h3>View</h3>
            <div class="field-row"><input type="checkbox" id="showGrid" checked><label for="showGrid">Show Grid</label></div>
            <div class="field-row"><input type="checkbox" id="showIds"><label for="showIds">Show Tile IDs</label></div>
          </div>
        </div>
        <div class="canvas-area"><canvas id="mapCanvas"></canvas></div>
        <div class="status-bar">
          <span id="statusPos">Pos: 0, 0</span>
          <span id="statusTile">Tile: 0</span>
          <span id="statusLayer">Layer: ground</span>
          <span id="statusSize">Grid: 20x15</span>
        </div>
      </div>
    `, `
      const canvas = document.getElementById('mapCanvas');
      const ctx = canvas.getContext('2d');
      let mapW = 20, mapH = 15, tileSize = 32;
      let currentTile = 1, currentTool = 'paint', currentLayer = 'ground';
      let showGrid = true, showIds = false;
      let offsetX = 0, offsetY = 0, zoom = 1;
      let isPanning = false, panStartX = 0, panStartY = 0;
      let isDrawing = false, rectStartX = -1, rectStartY = -1;

      const TILE_COLORS = [
        '#1a1a2e','#16213e','#0f3460','#533483','#e94560','#4ec9b0',
        '#007acc','#ff9800','#4caf50','#f44336','#9c27b0','#00bcd4',
        '#795548','#607d8b','#ffeb3b','#8bc34a'
      ];

      const layers = { ground: [], walls: [], objects: [] };
      function initLayer(name) {
        layers[name] = new Array(mapW * mapH).fill(0);
      }
      function initAllLayers() { for (const k in layers) initLayer(k); }
      initAllLayers();

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

        const layer = layers[currentLayer];
        for (let y = 0; y < mapH; y++) {
          for (let x = 0; x < mapW; x++) {
            const t = layer[y * mapW + x];
            const px = x * tileSize, py = y * tileSize;
            if (t > 0) {
              ctx.fillStyle = TILE_COLORS[(t - 1) % TILE_COLORS.length];
              ctx.fillRect(px, py, tileSize, tileSize);
            }
            if (showGrid) {
              ctx.strokeStyle = '#3c3c3c';
              ctx.lineWidth = 0.5;
              ctx.strokeRect(px, py, tileSize, tileSize);
            }
            if (showIds && t > 0) {
              ctx.fillStyle = '#fff';
              ctx.font = '10px monospace';
              ctx.textAlign = 'center';
              ctx.textBaseline = 'middle';
              ctx.fillText(String(t), px + tileSize/2, py + tileSize/2);
            }
          }
        }
        ctx.restore();
      }

      function screenToTile(sx, sy) {
        const tx = Math.floor((sx - offsetX) / (tileSize * zoom));
        const ty = Math.floor((sy - offsetY) / (tileSize * zoom));
        return { tx, ty };
      }

      function setTile(tx, ty, value) {
        if (tx >= 0 && tx < mapW && ty >= 0 && ty < mapH) {
          layers[currentLayer][ty * mapW + tx] = value;
        }
      }

      function floodFill(tx, ty, target, replacement) {
        if (target === replacement) return;
        const layer = layers[currentLayer];
        const stack = [[tx, ty]];
        while (stack.length) {
          const [x, y] = stack.pop();
          if (x < 0 || x >= mapW || y < 0 || y >= mapH) continue;
          if (layer[y * mapW + x] !== target) continue;
          layer[y * mapW + x] = replacement;
          stack.push([x-1,y],[x+1,y],[x,y-1],[x,y+1]);
        }
      }

      // Build palette
      const paletteEl = document.getElementById('palette');
      for (let i = 0; i <= 15; i++) {
        const el = document.createElement('div');
        el.className = 'palette-tile' + (i === 1 ? ' selected' : '');
        el.style.background = i === 0 ? 'transparent' : TILE_COLORS[(i-1) % TILE_COLORS.length];
        if (i === 0) { el.style.background = 'repeating-conic-gradient(#333 0% 25%, #222 0% 50%) 50% / 8px 8px'; }
        el.addEventListener('click', () => {
          paletteEl.querySelectorAll('.palette-tile').forEach(t => t.classList.remove('selected'));
          el.classList.add('selected');
          currentTile = i;
          document.getElementById('statusTile').textContent = 'Tile: ' + i;
        });
        paletteEl.appendChild(el);
      }

      // Tools
      document.getElementById('toolList').addEventListener('click', (e) => {
        const btn = e.target.closest('[data-tool]');
        if (!btn) return;
        document.getElementById('toolList').querySelectorAll('button').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentTool = btn.dataset.tool;
      });

      // Canvas events
      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) {
          isPanning = true; panStartX = e.clientX - offsetX; panStartY = e.clientY - offsetY;
          e.preventDefault(); return;
        }
        if (e.button === 0) {
          isDrawing = true;
          const { tx, ty } = screenToTile(e.offsetX, e.offsetY);
          if (currentTool === 'paint') { setTile(tx, ty, currentTile); render(); }
          else if (currentTool === 'erase') { setTile(tx, ty, 0); render(); }
          else if (currentTool === 'fill') {
            const layer = layers[currentLayer];
            if (tx >= 0 && tx < mapW && ty >= 0 && ty < mapH) {
              floodFill(tx, ty, layer[ty*mapW+tx], currentTile); render();
            }
          }
          else if (currentTool === 'pick') {
            const layer = layers[currentLayer];
            if (tx >= 0 && tx < mapW && ty >= 0 && ty < mapH) {
              currentTile = layer[ty*mapW+tx];
              document.getElementById('statusTile').textContent = 'Tile: ' + currentTile;
              paletteEl.querySelectorAll('.palette-tile').forEach((t,i) => {
                t.classList.toggle('selected', i === currentTile);
              });
            }
          }
          else if (currentTool === 'rect') { rectStartX = tx; rectStartY = ty; }
        }
      });

      canvas.addEventListener('mousemove', (e) => {
        if (isPanning) {
          offsetX = e.clientX - panStartX; offsetY = e.clientY - panStartY; render(); return;
        }
        const { tx, ty } = screenToTile(e.offsetX, e.offsetY);
        document.getElementById('statusPos').textContent = 'Pos: ' + tx + ', ' + ty;
        if (isDrawing) {
          if (currentTool === 'paint') { setTile(tx, ty, currentTile); render(); }
          else if (currentTool === 'erase') { setTile(tx, ty, 0); render(); }
        }
      });

      canvas.addEventListener('mouseup', (e) => {
        if (isPanning) { isPanning = false; return; }
        if (isDrawing && currentTool === 'rect') {
          const { tx, ty } = screenToTile(e.offsetX, e.offsetY);
          const x0 = Math.min(rectStartX, tx), x1 = Math.max(rectStartX, tx);
          const y0 = Math.min(rectStartY, ty), y1 = Math.max(rectStartY, ty);
          for (let y = y0; y <= y1; y++)
            for (let x = x0; x <= x1; x++) setTile(x, y, currentTile);
          render();
        }
        isDrawing = false;
      });

      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const oldZoom = zoom;
        zoom *= e.deltaY < 0 ? 1.1 : 0.9;
        zoom = Math.max(0.1, Math.min(5, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / oldZoom;
        offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / oldZoom;
        render();
      }, { passive: false });

      // Controls
      document.getElementById('showGrid').addEventListener('change', (e) => { showGrid = e.target.checked; render(); });
      document.getElementById('showIds').addEventListener('change', (e) => { showIds = e.target.checked; render(); });
      document.getElementById('layerSelect').addEventListener('change', (e) => {
        currentLayer = e.target.value;
        document.getElementById('statusLayer').textContent = 'Layer: ' + currentLayer;
        render();
      });
      document.getElementById('btnResize').addEventListener('click', () => {
        const nw = parseInt(document.getElementById('mapWidth').value) || 20;
        const nh = parseInt(document.getElementById('mapHeight').value) || 15;
        tileSize = parseInt(document.getElementById('tileSize').value) || 32;
        mapW = Math.min(200, Math.max(1, nw));
        mapH = Math.min(200, Math.max(1, nh));
        initAllLayers();
        document.getElementById('statusSize').textContent = 'Grid: ' + mapW + 'x' + mapH;
        render();
      });
      document.getElementById('btnClear').addEventListener('click', () => { initLayer(currentLayer); render(); });

      function generateExport() {
        const data = { width: mapW, height: mapH, tileSize: tileSize, layers: {} };
        for (const k in layers) data.layers[k] = Array.from(layers[k]);
        return data;
      }
      document.getElementById('btnExportLua').addEventListener('click', () => {
        const d = generateExport();
        let lua = 'return {\\n';
        lua += '  width = ' + d.width + ',\\n  height = ' + d.height + ',\\n  tileSize = ' + d.tileSize + ',\\n';
        lua += '  layers = {\\n';
        for (const k in d.layers) {
          lua += '    ' + k + ' = {' + d.layers[k].join(', ') + '},\\n';
        }
        lua += '  }\\n}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });
      document.getElementById('btnExportToml').addEventListener('click', () => {
        const d = generateExport();
        let toml = 'width = ' + d.width + '\\nheight = ' + d.height + '\\ntile_size = ' + d.tileSize + '\\n\\n';
        for (const k in d.layers) {
          toml += '[layers.' + k + ']\\ndata = [' + d.layers[k].join(', ') + ']\\n\\n';
        }
        vscode.postMessage({ type: 'exportToml', content: toml });
      });

      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `);
  }
}
