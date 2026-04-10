import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class PixelArtEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): PixelArtEditor {
    return new PixelArtEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.editor.pixelArt", "Pixel Art Editor");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportPng":
        this.exportFile(msg.content as string, "sprite.png", "PNG Image", "png");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Pixel Art Editor", `
      .editor-layout {
        display: grid; grid-template-columns: 48px 1fr 180px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .tool-sidebar { grid-row: 2; background: var(--surface); border-right: 1px solid var(--border); display: flex; flex-direction: column; align-items: center; padding: 4px; gap: 2px; }
      .tool-sidebar button { width: 36px; height: 36px; font-size: 16px; padding: 0; display: flex; align-items: center; justify-content: center; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: #111; }
      .right-panel { grid-row: 2; border-left: 1px solid var(--border); overflow-y: auto; padding: 8px; background: var(--surface); }
      .status-bar { grid-column: 1 / -1; }
      .color-display { display: flex; gap: 4px; margin-bottom: 8px; }
      .color-swatch { width: 32px; height: 32px; border: 2px solid var(--border); border-radius: 3px; cursor: pointer; }
      .color-swatch.active { border-color: var(--accent); }
      .pico-palette { display: grid; grid-template-columns: repeat(4, 1fr); gap: 2px; }
      .pico-palette div { aspect-ratio: 1; cursor: pointer; border-radius: 2px; border: 1px solid transparent; }
      .pico-palette div:hover { border-color: var(--text); }
      .pico-palette div.selected { border-color: var(--accent); border-width: 2px; }
      .layer-item { display: flex; align-items: center; gap: 4px; padding: 2px 4px; font-size: 11px; cursor: pointer; border-radius: 2px; }
      .layer-item:hover { background: var(--surface-2); }
      .layer-item.sel { background: var(--selection); }
      .frame-strip { display: flex; gap: 4px; overflow-x: auto; }
      .frame-thumb { width: 40px; height: 40px; border: 1px solid var(--border); cursor: pointer; border-radius: 2px; background: #111; }
      .frame-thumb.sel { border-color: var(--accent); }
      .preview-box { border: 1px solid var(--border); border-radius: 4px; background: #111; image-rendering: pixelated; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <label>Size:</label>
          <select id="sizeSelect">
            <option value="8">8x8</option><option value="16" selected>16x16</option>
            <option value="32">32x32</option><option value="64">64x64</option>
          </select>
          <div class="sep"></div>
          <button id="btnUndo">Undo</button>
          <button id="btnClear" class="danger">Clear</button>
          <div class="sep"></div>
          <button id="btnExport">Export PNG</button>
        </div>
        <div class="tool-sidebar" id="tools">
          <button class="active" data-tool="pen" title="Pen">&#9998;</button>
          <button data-tool="eraser" title="Eraser">&#9003;</button>
          <button data-tool="bucket" title="Bucket Fill">&#9636;</button>
          <button data-tool="rect" title="Rectangle">&#9645;</button>
          <button data-tool="line" title="Line">&#9585;</button>
          <button data-tool="pick" title="Color Pick">&#128270;</button>
        </div>
        <div class="canvas-area"><canvas id="artCanvas"></canvas></div>
        <div class="right-panel">
          <h3>Color</h3>
          <div class="color-display">
            <div class="color-swatch active" id="leftColor" title="Left click color"></div>
            <div class="color-swatch" id="rightColor" title="Right click color"></div>
          </div>
          <div class="field"><label>Hex</label><input id="hexInput" value="#000000" style="width:100%"></div>
          <div class="section" style="margin-top: 8px;">
            <h3>PICO-8 Palette</h3>
            <div class="pico-palette" id="palette"></div>
          </div>
          <div class="section" style="margin-top: 12px;">
            <h3>Layers</h3>
            <button id="btnAddLayer" style="font-size: 11px; width: 100%; margin-bottom: 4px;">+ Layer</button>
            <div id="layerList"></div>
          </div>
          <div class="section" style="margin-top: 12px;">
            <h3>Frames</h3>
            <div class="frame-strip" id="frameStrip"></div>
            <div style="margin-top: 4px; display: flex; gap: 4px;">
              <button id="btnAddFrame" style="flex:1; font-size: 11px;">+ Frame</button>
              <button id="btnPlay" style="flex:1; font-size: 11px;">&#9654; Play</button>
            </div>
          </div>
          <div class="section" style="margin-top: 12px;">
            <h3>Preview</h3>
            <canvas id="previewCanvas" class="preview-box" width="64" height="64" style="width: 100%;"></canvas>
          </div>
        </div>
        <div class="status-bar">
          <span id="statusPos">Pos: 0, 0</span>
          <span id="statusTool">Tool: Pen</span>
          <span id="statusSize">16x16</span>
        </div>
      </div>
    `, `
      const PICO8 = [
        '#000000','#1d2b53','#7e2553','#008751','#ab5236','#5f574f','#c2c3c7','#fff1e8',
        '#ff004d','#ffa300','#ffec27','#00e436','#29adff','#83769c','#ff77a8','#ffccaa'
      ];

      const canvas = document.getElementById('artCanvas');
      const ctx = canvas.getContext('2d');
      const previewCanvas = document.getElementById('previewCanvas');
      const previewCtx = previewCanvas.getContext('2d');

      let gridSize = 16, currentTool = 'pen';
      let leftColor = '#000000', rightColor = '#ffffff';
      let layers = [{ name: 'Layer 0', visible: true, data: null }];
      let currentLayer = 0;
      let frames = [null]; // frame 0 = default
      let currentFrame = 0, playing = false, animTimer = null;
      let history = [];
      let offsetX = 0, offsetY = 0, zoom = 16;
      let isPanning = false, panSX = 0, panSY = 0;
      let isDrawing = false, lineStartX = -1, lineStartY = -1;

      function initData() {
        for (const l of layers) l.data = new Array(gridSize * gridSize).fill(null);
        frames = [null]; currentFrame = 0;
      }
      initData();

      function saveHistory() {
        history.push(JSON.parse(JSON.stringify(layers.map(l => l.data))));
        if (history.length > 50) history.shift();
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight;
        render();
      }

      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.save(); ctx.translate(offsetX, offsetY);
        const pxSize = zoom;

        // Checkerboard background
        for (let y = 0; y < gridSize; y++) {
          for (let x = 0; x < gridSize; x++) {
            ctx.fillStyle = ((x + y) % 2 === 0) ? '#2a2a2a' : '#222';
            ctx.fillRect(x * pxSize, y * pxSize, pxSize, pxSize);
          }
        }

        // Layers
        for (const l of layers) {
          if (!l.visible) continue;
          for (let y = 0; y < gridSize; y++) {
            for (let x = 0; x < gridSize; x++) {
              const c = l.data[y * gridSize + x];
              if (c) { ctx.fillStyle = c; ctx.fillRect(x * pxSize, y * pxSize, pxSize, pxSize); }
            }
          }
        }

        // Grid
        ctx.strokeStyle = 'rgba(255,255,255,0.05)';
        ctx.lineWidth = 0.5;
        for (let x = 0; x <= gridSize; x++) { ctx.beginPath(); ctx.moveTo(x * pxSize, 0); ctx.lineTo(x * pxSize, gridSize * pxSize); ctx.stroke(); }
        for (let y = 0; y <= gridSize; y++) { ctx.beginPath(); ctx.moveTo(0, y * pxSize); ctx.lineTo(gridSize * pxSize, y * pxSize); ctx.stroke(); }
        ctx.restore();

        // Preview
        previewCtx.clearRect(0, 0, 64, 64);
        const s = 64 / gridSize;
        for (const l of layers) {
          if (!l.visible) continue;
          for (let y = 0; y < gridSize; y++)
            for (let x = 0; x < gridSize; x++) {
              const c = l.data[y * gridSize + x];
              if (c) { previewCtx.fillStyle = c; previewCtx.fillRect(x * s, y * s, s, s); }
            }
        }
      }

      function screenToPixel(sx, sy) {
        return { x: Math.floor((sx - offsetX) / zoom), y: Math.floor((sy - offsetY) / zoom) };
      }

      function setPixel(x, y, color) {
        if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
          layers[currentLayer].data[y * gridSize + x] = color;
        }
      }

      function getPixel(x, y) {
        if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) return layers[currentLayer].data[y * gridSize + x];
        return undefined;
      }

      function floodFill(x, y, target, fill) {
        if (target === fill) return;
        const stack = [[x, y]];
        while (stack.length) {
          const [cx, cy] = stack.pop();
          if (cx < 0 || cx >= gridSize || cy < 0 || cy >= gridSize) continue;
          if (getPixel(cx, cy) !== target) continue;
          setPixel(cx, cy, fill);
          stack.push([cx-1,cy],[cx+1,cy],[cx,cy-1],[cx,cy+1]);
        }
      }

      function drawLine(x0, y0, x1, y1, color) {
        const dx = Math.abs(x1 - x0), dy = Math.abs(y1 - y0);
        const sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1;
        let err = dx - dy;
        while (true) {
          setPixel(x0, y0, color);
          if (x0 === x1 && y0 === y1) break;
          const e2 = 2 * err;
          if (e2 > -dy) { err -= dy; x0 += sx; }
          if (e2 < dx) { err += dx; y0 += sy; }
        }
      }

      function applyTool(px, py, button) {
        const color = button === 2 ? rightColor : leftColor;
        switch (currentTool) {
          case 'pen': setPixel(px, py, color); break;
          case 'eraser': setPixel(px, py, null); break;
          case 'bucket': floodFill(px, py, getPixel(px, py), color); break;
          case 'pick': {
            const c = getPixel(px, py);
            if (c) { if (button === 2) { rightColor = c; } else { leftColor = c; } updateColorDisplay(); }
            break;
          }
        }
      }

      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) {
          isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY; return;
        }
        if (e.button === 0 || e.button === 2) {
          saveHistory(); isDrawing = true;
          const { x, y } = screenToPixel(e.offsetX, e.offsetY);
          if (currentTool === 'line' || currentTool === 'rect') { lineStartX = x; lineStartY = y; }
          else { applyTool(x, y, e.button); render(); }
        }
      });

      canvas.addEventListener('mousemove', (e) => {
        const { x, y } = screenToPixel(e.offsetX, e.offsetY);
        document.getElementById('statusPos').textContent = 'Pos: ' + x + ', ' + y;
        if (isPanning) { offsetX = e.clientX - panSX; offsetY = e.clientY - panSY; render(); return; }
        if (isDrawing && (currentTool === 'pen' || currentTool === 'eraser')) { applyTool(x, y, e.buttons & 2 ? 2 : 0); render(); }
      });

      canvas.addEventListener('mouseup', (e) => {
        if (isPanning) { isPanning = false; return; }
        if (isDrawing) {
          const { x, y } = screenToPixel(e.offsetX, e.offsetY);
          const color = e.button === 2 ? rightColor : leftColor;
          if (currentTool === 'line') drawLine(lineStartX, lineStartY, x, y, color);
          else if (currentTool === 'rect') {
            const x0 = Math.min(lineStartX, x), x1 = Math.max(lineStartX, x);
            const y0 = Math.min(lineStartY, y), y1 = Math.max(lineStartY, y);
            for (let ry = y0; ry <= y1; ry++) for (let rx = x0; rx <= x1; rx++) {
              if (ry === y0 || ry === y1 || rx === x0 || rx === x1) setPixel(rx, ry, color);
            }
          }
          isDrawing = false; render();
        }
      });

      canvas.addEventListener('contextmenu', (e) => e.preventDefault());

      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const oldZoom = zoom;
        zoom = Math.max(2, Math.min(64, zoom + (e.deltaY < 0 ? 2 : -2)));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / oldZoom;
        offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / oldZoom;
        render();
      }, { passive: false });

      // Palette
      const paletteEl = document.getElementById('palette');
      PICO8.forEach((c, i) => {
        const div = document.createElement('div');
        div.style.background = c; div.title = c;
        div.addEventListener('click', () => { leftColor = c; updateColorDisplay(); });
        div.addEventListener('contextmenu', (ev) => { ev.preventDefault(); rightColor = c; updateColorDisplay(); });
        paletteEl.appendChild(div);
      });

      function updateColorDisplay() {
        document.getElementById('leftColor').style.background = leftColor;
        document.getElementById('rightColor').style.background = rightColor;
        document.getElementById('hexInput').value = leftColor;
      }
      updateColorDisplay();

      document.getElementById('hexInput').addEventListener('change', (e) => {
        if (/^#[0-9a-fA-F]{6}$/.test(e.target.value)) { leftColor = e.target.value; updateColorDisplay(); }
      });

      // Tools
      document.getElementById('tools').addEventListener('click', (e) => {
        const btn = e.target.closest('[data-tool]');
        if (!btn) return;
        document.getElementById('tools').querySelectorAll('button').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        currentTool = btn.dataset.tool;
        document.getElementById('statusTool').textContent = 'Tool: ' + currentTool;
      });

      // Size
      document.getElementById('sizeSelect').addEventListener('change', (e) => {
        gridSize = parseInt(e.target.value);
        initData(); refreshLayers(); refreshFrames();
        offsetX = 0; offsetY = 0; zoom = Math.max(2, Math.floor(256 / gridSize));
        document.getElementById('statusSize').textContent = gridSize + 'x' + gridSize;
        resizeCanvas();
      });

      // Layers
      function refreshLayers() {
        const el = document.getElementById('layerList');
        el.innerHTML = '';
        layers.forEach((l, i) => {
          const div = document.createElement('div');
          div.className = 'layer-item' + (i === currentLayer ? ' sel' : '');
          div.innerHTML = '<input type="checkbox" ' + (l.visible ? 'checked' : '') + '> ' + l.name;
          div.querySelector('input').addEventListener('change', (ev) => { l.visible = ev.target.checked; render(); });
          div.addEventListener('click', (ev) => { if (ev.target.tagName !== 'INPUT') { currentLayer = i; refreshLayers(); } });
          el.appendChild(div);
        });
      }
      document.getElementById('btnAddLayer').addEventListener('click', () => {
        layers.push({ name: 'Layer ' + layers.length, visible: true, data: new Array(gridSize * gridSize).fill(null) });
        currentLayer = layers.length - 1; refreshLayers();
      });
      refreshLayers();

      // Frames
      function refreshFrames() {
        const el = document.getElementById('frameStrip');
        el.innerHTML = '';
        frames.forEach((_, i) => {
          const div = document.createElement('div');
          div.className = 'frame-thumb' + (i === currentFrame ? ' sel' : '');
          div.textContent = i;
          div.style.display = 'flex'; div.style.alignItems = 'center'; div.style.justifyContent = 'center';
          div.style.color = 'var(--text-dim)'; div.style.fontSize = '10px';
          div.addEventListener('click', () => { currentFrame = i; refreshFrames(); });
          el.appendChild(div);
        });
      }
      document.getElementById('btnAddFrame').addEventListener('click', () => {
        frames.push(JSON.parse(JSON.stringify(layers.map(l => l.data))));
        currentFrame = frames.length - 1; refreshFrames();
      });
      document.getElementById('btnPlay').addEventListener('click', () => {
        playing = !playing;
        document.getElementById('btnPlay').textContent = playing ? '\\u25A0 Stop' : '\\u25B6 Play';
        if (playing && frames.length > 1) {
          let fi = 0;
          animTimer = setInterval(() => {
            fi = (fi + 1) % frames.length;
            currentFrame = fi; refreshFrames(); render();
          }, 150);
        } else { clearInterval(animTimer); }
      });
      refreshFrames();

      // Undo
      document.getElementById('btnUndo').addEventListener('click', () => {
        if (history.length === 0) return;
        const prev = history.pop();
        layers.forEach((l, i) => { l.data = prev[i] || new Array(gridSize * gridSize).fill(null); });
        render();
      });

      // Clear
      document.getElementById('btnClear').addEventListener('click', () => {
        saveHistory();
        layers[currentLayer].data = new Array(gridSize * gridSize).fill(null);
        render();
      });

      // Export
      document.getElementById('btnExport').addEventListener('click', () => {
        const tmpCanvas = document.createElement('canvas');
        tmpCanvas.width = gridSize; tmpCanvas.height = gridSize;
        const tmpCtx = tmpCanvas.getContext('2d');
        for (const l of layers) {
          if (!l.visible) continue;
          for (let y = 0; y < gridSize; y++)
            for (let x = 0; x < gridSize; x++) {
              const c = l.data[y * gridSize + x];
              if (c) { tmpCtx.fillStyle = c; tmpCtx.fillRect(x, y, 1, 1); }
            }
        }
        vscode.postMessage({ type: 'exportPng', content: tmpCanvas.toDataURL('image/png') });
      });

      // Center canvas
      offsetX = 50; offsetY = 50;
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `);
  }
}
