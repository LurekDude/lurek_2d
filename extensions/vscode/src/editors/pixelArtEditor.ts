import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

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
      case "exportSpriteSheet":
        this.exportFile(msg.content as string, "spritesheet.png", "PNG Image", "png");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Pixel Art Editor", `
      .editor-layout {
        display: grid;
        grid-template-columns: 38px 1fr 220px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .canvas-area {
        grid-row: 2; position: relative; overflow: hidden;
        background: var(--bg);
      }
      .canvas-area canvas { display: block; image-rendering: pixelated; }
      .properties { grid-row: 2; background: var(--surface); border-left: 1px solid var(--border); overflow-y: auto; }

      /* Color section */
      .color-wells {
        display: flex; gap: 4px; margin-bottom: 8px; align-items: center;
      }
      .color-well {
        width: 30px; height: 30px; border: 2px solid var(--border);
        border-radius: var(--radius); cursor: pointer; position: relative;
        transition: border-color 0.12s;
      }
      .color-well.active { border-color: var(--accent); }
      .color-well .label {
        position: absolute; bottom: -1px; right: -1px;
        font-size: 8px; background: var(--surface-2); color: var(--text-dim);
        padding: 0 3px; border-radius: 2px 0 2px 0; line-height: 1.4;
      }
      .swap-btn { background: none; border: none; color: var(--text-dim); cursor: pointer; padding: 2px; font-size: 14px; }
      .swap-btn:hover { color: var(--text-bright); background: transparent; border: none; }

      .palette-grid {
        display: grid; grid-template-columns: repeat(8, 1fr); gap: 1px;
      }
      .palette-grid .swatch {
        aspect-ratio: 1; cursor: pointer; border-radius: 2px;
        border: 1px solid transparent; transition: border-color 0.1s, transform 0.1s;
      }
      .palette-grid .swatch:hover { border-color: var(--text); transform: scale(1.15); z-index: 1; }
      .palette-grid .swatch.selected { border-color: var(--accent); border-width: 2px; }

      /* Layer list */
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

      /* Frame strip */
      .frame-strip {
        display: flex; gap: 3px; overflow-x: auto; padding: 2px 0;
      }
      .frame-thumb {
        width: 36px; height: 36px; border: 1px solid var(--border); cursor: pointer;
        border-radius: var(--radius); background: var(--bg); display: flex;
        align-items: center; justify-content: center; flex-shrink: 0;
        font-size: 9px; color: var(--text-dim); transition: border-color 0.1s;
        image-rendering: pixelated; position: relative;
      }
      .frame-thumb:hover { border-color: var(--text); }
      .frame-thumb.sel { border-color: var(--accent); border-width: 2px; }
      .frame-actions { display: flex; gap: 2px; margin-top: 4px; }
      .frame-actions button { flex: 1; font-size: 10px; padding: 3px 0; }

      /* Preview */
      .preview-wrap {
        background: var(--bg); border: 1px solid var(--border); border-radius: var(--radius);
        padding: 4px; display: flex; align-items: center; justify-content: center;
      }
      .preview-wrap canvas { image-rendering: pixelated; width: 100%; height: auto; }

      /* Symmetry indicator */
      .symmetry-indicator {
        display: flex; gap: 4px; font-size: 10px; align-items: center;
      }
      .symmetry-indicator button { font-size: 10px; padding: 2px 6px; }
    `, `
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            <label>Size</label>
            <select id="sizeSelect">
              <option value="8">8×8</option>
              <option value="16" selected>16×16</option>
              <option value="32">32×32</option>
              <option value="64">64×64</option>
              <option value="128">128×128</option>
            </select>
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
          <div class="group symmetry-indicator">
            <label>Mirror:</label>
            <button id="btnMirrorH" title="Mirror Horizontal" data-tooltip="Mirror H">H</button>
            <button id="btnMirrorV" title="Mirror Vertical" data-tooltip="Mirror V">V</button>
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
            <button class="icon-btn active" data-tool="pen" title="Pen (B)" data-tooltip="Pen">${ICONS.pen}</button>
            <button class="icon-btn" data-tool="eraser" title="Eraser (E)" data-tooltip="Eraser">${ICONS.eraser}</button>
            <button class="icon-btn" data-tool="bucket" title="Fill (G)" data-tooltip="Fill">${ICONS.bucket}</button>
          </div>
          <div class="tool-group">
            <button class="icon-btn" data-tool="rect" title="Rectangle (R)" data-tooltip="Rectangle">${ICONS.rect}</button>
            <button class="icon-btn" data-tool="line" title="Line (L)" data-tooltip="Line">${ICONS.line}</button>
            <button class="icon-btn" data-tool="select" title="Select (M)" data-tooltip="Select">${ICONS.select}</button>
          </div>
          <div class="tool-group">
            <button class="icon-btn" data-tool="pick" title="Color Pick (I)" data-tooltip="Pick">${ICONS.pick}</button>
            <button class="icon-btn" data-tool="hand" title="Pan (H / Middle Mouse)" data-tooltip="Pan">${ICONS.hand}</button>
          </div>
        </div>

        <!-- Canvas -->
        <div class="canvas-area"><canvas id="artCanvas"></canvas></div>

        <!-- Properties Panel -->
        <div class="properties">
          ${panelSection('Color', `
            <div class="color-wells">
              <div class="color-well active" id="leftColor" title="Primary color (left click)">
                <span class="label">L</span>
              </div>
              <button class="swap-btn" id="btnSwapColor" title="Swap colors (X)">⇄</button>
              <div class="color-well" id="rightColor" title="Secondary color (right click)">
                <span class="label">R</span>
              </div>
            </div>
            ${fieldInline('Hex', '<input id="hexInput" value="#000000" maxlength="7" style="width:100%">')}
            ${fieldInline('Opacity', '<input type="range" id="opacitySlider" min="0" max="100" value="100" style="width:100%"><span id="opacityVal" style="width:28px;text-align:right;font-size:10px;color:var(--text-dim)">100%</span>')}
          `)}
          ${panelSection('Palette', `
            <div class="palette-grid" id="palette"></div>
          `)}
          ${panelSection('Layers', `
            <div class="layer-actions">
              <button id="btnAddLayer">${ICONS.add} Add</button>
              <button id="btnDelLayer">${ICONS.trash} Del</button>
              <button id="btnMoveLayerUp">${ICONS.moveUp}</button>
              <button id="btnMoveLayerDown">${ICONS.moveDown}</button>
            </div>
            <div id="layerList"></div>
          `)}
          ${panelSection('Animation', `
            <div class="frame-strip" id="frameStrip"></div>
            <div class="frame-actions">
              <button id="btnAddFrame">${ICONS.add} Frame</button>
              <button id="btnDupFrame">${ICONS.copy} Dup</button>
              <button id="btnDelFrame">${ICONS.trash}</button>
            </div>
            <div style="margin-top:6px">
              ${fieldInline('FPS', '<input type="number" id="fpsInput" value="8" min="1" max="60" style="width:50px">')}
              <div style="display:flex;gap:4px;margin-top:4px">
                <button id="btnPlay" style="flex:1">${ICONS.play} Play</button>
                <button id="btnOnionSkin" style="flex:1" data-tooltip="Onion skin">${ICONS.eye} Onion</button>
              </div>
            </div>
          `)}
          ${panelSection('Preview', `
            <div class="preview-wrap">
              <canvas id="previewCanvas" width="64" height="64"></canvas>
            </div>
            <div style="display:flex;gap:4px;margin-top:4px">
              <button id="btnPreviewBg" style="flex:1;font-size:10px">BG: Checker</button>
            </div>
          `)}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusPos">0, 0</span>
          </span>
          <div class="sep"></div>
          <span id="statusTool">Pen</span>
          <div class="sep"></div>
          <span id="statusSize">16×16</span>
          <div class="spacer"></div>
          <span class="status-group">
            <span id="statusFrameInfo">Frame 1/1</span>
            <div class="sep"></div>
            <span id="statusLayerInfo">Layer 1/1</span>
          </span>
          <div class="sep"></div>
          <span class="dirty-indicator">${ICONS.clean}</span>
        </div>
      </div>
    `, `
      // ── Constants ──────────────────────────────────────
      const PICO8 = [
        '#000000','#1d2b53','#7e2553','#008751','#ab5236','#5f574f','#c2c3c7','#fff1e8',
        '#ff004d','#ffa300','#ffec27','#00e436','#29adff','#83769c','#ff77a8','#ffccaa'
      ];
      const ENDESGA32 = [
        '#be4a2f','#d77643','#ead4aa','#e4a672','#b86f50','#733e39','#3e2731','#a22633',
        '#e43b44','#f77622','#feae34','#fee761','#63c74d','#3e8948','#265c42','#193c3e',
        '#124e89','#0099db','#2ce8f5','#ffffff','#c0cbdc','#8b9bb4','#5a6988','#3a4466',
        '#262b44','#181425','#ff0044','#68386c','#b55088','#f6757a','#e8b796','#c28569'
      ];

      // ── State ──────────────────────────────────────────
      const canvas = document.getElementById('artCanvas');
      const ctx = canvas.getContext('2d');
      const previewCanvas = document.getElementById('previewCanvas');
      const previewCtx = previewCanvas.getContext('2d');
      const undoStack = new UndoStack(100);

      let gridSize = 16, currentTool = 'pen';
      let leftColor = '#1d2b53', rightColor = '#ffffff';
      let layers = [{ name: 'Background', visible: true, data: null }];
      let currentLayer = 0;
      let frames = [null];
      let currentFrame = 0, playing = false, animTimer = null, fps = 8;
      let offsetX = 0, offsetY = 0, zoom = 16;
      let showGrid = true, showOnionSkin = false;
      let mirrorH = false, mirrorV = false;
      let isPanning = false, panSX = 0, panSY = 0;
      let isDrawing = false, lineStartX = -1, lineStartY = -1;
      let previewBg = 'checker'; // checker, black, white, transparent
      let selecting = false, selection = null; // {x,y,w,h}

      function initData() {
        for (const l of layers) l.data = new Array(gridSize * gridSize).fill(null);
        frames = [null]; currentFrame = 0;
      }
      initData();

      function getState() {
        return { layers: layers.map(l => ({ ...l, data: [...l.data] })), currentLayer };
      }
      function pushUndo() {
        undoStack.push(getState());
        markDirty();
      }

      // ── Undo / Redo wiring ─────────────────────────────
      undoStack.onChange((canUndo, canRedo) => {
        document.getElementById('btnUndo').disabled = !canUndo;
        document.getElementById('btnRedo').disabled = !canRedo;
      });

      document.getElementById('btnUndo').addEventListener('click', () => {
        const prev = undoStack.undo();
        if (prev) { restoreState(prev); render(); }
      });
      document.getElementById('btnRedo').addEventListener('click', () => {
        const next = undoStack.redo();
        if (next) { restoreState(next); render(); }
      });

      function restoreState(state) {
        state.layers.forEach((sl, i) => {
          if (layers[i]) { layers[i].data = sl.data; layers[i].name = sl.name; layers[i].visible = sl.visible; }
        });
        currentLayer = state.currentLayer;
        refreshLayers();
      }

      // Push initial state
      undoStack.push(getState());

      // ── Canvas Rendering ───────────────────────────────
      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight;
        render();
      }

      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.save(); ctx.translate(offsetX, offsetY);
        const pxSize = zoom;
        const totalPx = gridSize * pxSize;

        // Checkerboard background
        for (let y = 0; y < gridSize; y++) {
          for (let x = 0; x < gridSize; x++) {
            ctx.fillStyle = ((x + y) % 2 === 0) ? '#2a2a3d' : '#232334';
            ctx.fillRect(x * pxSize, y * pxSize, pxSize, pxSize);
          }
        }

        // Onion skin (previous frame ghost)
        if (showOnionSkin && currentFrame > 0 && frames[currentFrame - 1]) {
          ctx.globalAlpha = 0.25;
          const prevData = frames[currentFrame - 1];
          for (let li = 0; li < prevData.length; li++) {
            if (!layers[li] || !layers[li].visible) continue;
            for (let y = 0; y < gridSize; y++)
              for (let x = 0; x < gridSize; x++) {
                const c = prevData[li][y * gridSize + x];
                if (c) { ctx.fillStyle = c; ctx.fillRect(x * pxSize, y * pxSize, pxSize, pxSize); }
              }
          }
          ctx.globalAlpha = 1;
        }

        // Layers
        for (let li = 0; li < layers.length; li++) {
          const l = layers[li];
          if (!l.visible) continue;
          for (let y = 0; y < gridSize; y++) {
            for (let x = 0; x < gridSize; x++) {
              const c = l.data[y * gridSize + x];
              if (c) { ctx.fillStyle = c; ctx.fillRect(x * pxSize, y * pxSize, pxSize, pxSize); }
            }
          }
        }

        // Grid overlay
        if (showGrid && zoom >= 6) {
          ctx.strokeStyle = 'rgba(255,255,255,0.06)';
          ctx.lineWidth = 0.5;
          for (let x = 0; x <= gridSize; x++) { ctx.beginPath(); ctx.moveTo(x * pxSize, 0); ctx.lineTo(x * pxSize, totalPx); ctx.stroke(); }
          for (let y = 0; y <= gridSize; y++) { ctx.beginPath(); ctx.moveTo(0, y * pxSize); ctx.lineTo(totalPx, y * pxSize); ctx.stroke(); }
        }

        // Border around sprite
        ctx.strokeStyle = 'rgba(137,180,250,0.3)';
        ctx.lineWidth = 1;
        ctx.strokeRect(-0.5, -0.5, totalPx + 1, totalPx + 1);

        // Selection overlay
        if (selection) {
          ctx.strokeStyle = 'var(--accent, #89b4fa)';
          ctx.lineWidth = 1;
          ctx.setLineDash([4, 4]);
          ctx.strokeRect(selection.x * pxSize, selection.y * pxSize, selection.w * pxSize, selection.h * pxSize);
          ctx.setLineDash([]);
        }

        // Mirror guide lines
        if (mirrorH) {
          ctx.strokeStyle = 'rgba(166,227,161,0.4)'; ctx.lineWidth = 1;
          ctx.beginPath(); ctx.moveTo(totalPx / 2, 0); ctx.lineTo(totalPx / 2, totalPx); ctx.stroke();
        }
        if (mirrorV) {
          ctx.strokeStyle = 'rgba(249,226,175,0.4)'; ctx.lineWidth = 1;
          ctx.beginPath(); ctx.moveTo(0, totalPx / 2); ctx.lineTo(totalPx, totalPx / 2); ctx.stroke();
        }

        ctx.restore();
        renderPreview();
      }

      function renderPreview() {
        const sz = 64;
        previewCtx.clearRect(0, 0, sz, sz);
        if (previewBg === 'checker') {
          const s = sz / gridSize;
          for (let y = 0; y < gridSize; y++) for (let x = 0; x < gridSize; x++) {
            previewCtx.fillStyle = ((x+y)%2===0) ? '#2a2a3d' : '#232334';
            previewCtx.fillRect(x*s, y*s, s, s);
          }
        } else if (previewBg === 'black') {
          previewCtx.fillStyle = '#000'; previewCtx.fillRect(0,0,sz,sz);
        } else if (previewBg === 'white') {
          previewCtx.fillStyle = '#fff'; previewCtx.fillRect(0,0,sz,sz);
        }
        const s = sz / gridSize;
        for (const l of layers) {
          if (!l.visible) continue;
          for (let y = 0; y < gridSize; y++)
            for (let x = 0; x < gridSize; x++) {
              const c = l.data[y * gridSize + x];
              if (c) { previewCtx.fillStyle = c; previewCtx.fillRect(x*s, y*s, s, s); }
            }
        }
      }

      // ── Pixel Operations ───────────────────────────────
      function screenToPixel(sx, sy) {
        return { x: Math.floor((sx - offsetX) / zoom), y: Math.floor((sy - offsetY) / zoom) };
      }

      function setPixel(x, y, color) {
        if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
          layers[currentLayer].data[y * gridSize + x] = color;
          // Symmetry
          if (mirrorH) {
            const mx = gridSize - 1 - x;
            if (mx >= 0 && mx < gridSize) layers[currentLayer].data[y * gridSize + mx] = color;
          }
          if (mirrorV) {
            const my = gridSize - 1 - y;
            if (my >= 0 && my < gridSize) layers[currentLayer].data[my * gridSize + x] = color;
          }
          if (mirrorH && mirrorV) {
            const mx = gridSize - 1 - x, my = gridSize - 1 - y;
            if (mx >= 0 && mx < gridSize && my >= 0 && my < gridSize)
              layers[currentLayer].data[my * gridSize + mx] = color;
          }
        }
      }

      function getPixel(x, y) {
        if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) return layers[currentLayer].data[y * gridSize + x];
        return undefined;
      }

      function floodFill(x, y, target, fill) {
        if (target === fill) return;
        const stack = [[x, y]];
        const visited = new Set();
        while (stack.length) {
          const [cx, cy] = stack.pop();
          const key = cx + ',' + cy;
          if (visited.has(key)) continue;
          visited.add(key);
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
          case 'select': {
            if (!selecting) { selecting = true; lineStartX = px; lineStartY = py; }
            break;
          }
        }
      }

      // ── Input Handlers ─────────────────────────────────
      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || currentTool === 'hand' || (e.altKey && e.button === 0)) {
          isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY;
          canvas.style.cursor = 'grabbing'; return;
        }
        if (e.button === 0 || e.button === 2) {
          pushUndo(); isDrawing = true;
          const { x, y } = screenToPixel(e.offsetX, e.offsetY);
          if (currentTool === 'line' || currentTool === 'rect' || currentTool === 'select') {
            lineStartX = x; lineStartY = y;
          } else {
            applyTool(x, y, e.button); render();
          }
        }
      });

      canvas.addEventListener('mousemove', (e) => {
        const { x, y } = screenToPixel(e.offsetX, e.offsetY);
        document.getElementById('statusPos').textContent = x + ', ' + y;
        if (isPanning) { offsetX = e.clientX - panSX; offsetY = e.clientY - panSY; render(); return; }
        if (isDrawing && (currentTool === 'pen' || currentTool === 'eraser')) {
          applyTool(x, y, e.buttons & 2 ? 2 : 0); render();
        }
        if (isDrawing && currentTool === 'select') {
          selection = {
            x: Math.min(lineStartX, x), y: Math.min(lineStartY, y),
            w: Math.abs(x - lineStartX) + 1, h: Math.abs(y - lineStartY) + 1
          };
          render();
        }
      });

      canvas.addEventListener('mouseup', (e) => {
        canvas.style.cursor = '';
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

      // ── Tool Shortcuts ─────────────────────────────────
      const toolKeys = { b: 'pen', e: 'eraser', g: 'bucket', r: 'rect', l: 'line', m: 'select', i: 'pick', h: 'hand' };
      Object.entries(toolKeys).forEach(([key, tool]) => {
        registerShortcut(key, () => { selectTool(tool); });
      });
      registerShortcut('x', () => {
        [leftColor, rightColor] = [rightColor, leftColor]; updateColorDisplay();
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
        if (!btn) return;
        selectTool(btn.dataset.tool);
      });

      // ── Color ──────────────────────────────────────────
      const paletteEl = document.getElementById('palette');
      const allColors = [...PICO8, ...ENDESGA32];
      allColors.forEach((c) => {
        const div = document.createElement('div');
        div.className = 'swatch';
        div.style.background = c; div.title = c;
        div.addEventListener('click', () => { leftColor = c; updateColorDisplay(); markDirty(); });
        div.addEventListener('contextmenu', (ev) => { ev.preventDefault(); rightColor = c; updateColorDisplay(); });
        paletteEl.appendChild(div);
      });

      function updateColorDisplay() {
        document.getElementById('leftColor').style.background = leftColor;
        document.getElementById('rightColor').style.background = rightColor;
        document.getElementById('hexInput').value = leftColor;
        // Highlight selected swatch
        paletteEl.querySelectorAll('.swatch').forEach(s => {
          s.classList.toggle('selected', s.style.background === leftColor ||
            s.title === leftColor);
        });
      }
      updateColorDisplay();

      document.getElementById('hexInput').addEventListener('change', (e) => {
        if (/^#[0-9a-fA-F]{6}$/.test(e.target.value)) { leftColor = e.target.value; updateColorDisplay(); }
      });
      document.getElementById('btnSwapColor').addEventListener('click', () => {
        [leftColor, rightColor] = [rightColor, leftColor]; updateColorDisplay();
      });
      document.getElementById('opacitySlider').addEventListener('input', (e) => {
        document.getElementById('opacityVal').textContent = e.target.value + '%';
      });

      // ── Grid / Mirror ──────────────────────────────────
      document.getElementById('btnGrid').addEventListener('click', function() {
        showGrid = !showGrid;
        this.classList.toggle('active', showGrid);
        render();
      });
      document.getElementById('btnMirrorH').addEventListener('click', function() {
        mirrorH = !mirrorH;
        this.classList.toggle('active', mirrorH);
        render();
      });
      document.getElementById('btnMirrorV').addEventListener('click', function() {
        mirrorV = !mirrorV;
        this.classList.toggle('active', mirrorV);
        render();
      });

      // ── Size ───────────────────────────────────────────
      document.getElementById('sizeSelect').addEventListener('change', (e) => {
        gridSize = parseInt(e.target.value);
        initData(); refreshLayers(); refreshFrames();
        offsetX = 0; offsetY = 0; zoom = Math.max(2, Math.floor(320 / gridSize));
        document.getElementById('statusSize').textContent = gridSize + '×' + gridSize;
        resizeCanvas();
      });

      // ── Layers ─────────────────────────────────────────
      function refreshLayers() {
        const el = document.getElementById('layerList');
        el.innerHTML = '';
        layers.forEach((l, i) => {
          const div = document.createElement('div');
          div.className = 'layer-item' + (i === currentLayer ? ' sel' : '');
          const visIcon = l.visible ? '${ICONS.eye}' : '${ICONS.eyeOff}';
          div.innerHTML = '<button class="vis-btn" title="Toggle visibility">' + visIcon + '</button>' +
            '<span class="name">' + l.name + '</span>';
          div.querySelector('.vis-btn').addEventListener('click', (ev) => {
            ev.stopPropagation();
            l.visible = !l.visible; refreshLayers(); render();
          });
          div.addEventListener('click', () => { currentLayer = i; refreshLayers(); });
          el.appendChild(div);
        });
        document.getElementById('statusLayerInfo').textContent = 'Layer ' + (currentLayer+1) + '/' + layers.length;
      }

      document.getElementById('btnAddLayer').addEventListener('click', () => {
        pushUndo();
        layers.push({ name: 'Layer ' + layers.length, visible: true, data: new Array(gridSize * gridSize).fill(null) });
        currentLayer = layers.length - 1; refreshLayers();
      });
      document.getElementById('btnDelLayer').addEventListener('click', () => {
        if (layers.length <= 1) { showToast('Cannot delete last layer', 'warn'); return; }
        pushUndo();
        layers.splice(currentLayer, 1);
        currentLayer = Math.min(currentLayer, layers.length - 1);
        refreshLayers(); render();
      });
      document.getElementById('btnMoveLayerUp').addEventListener('click', () => {
        if (currentLayer >= layers.length - 1) return;
        pushUndo();
        [layers[currentLayer], layers[currentLayer+1]] = [layers[currentLayer+1], layers[currentLayer]];
        currentLayer++; refreshLayers(); render();
      });
      document.getElementById('btnMoveLayerDown').addEventListener('click', () => {
        if (currentLayer <= 0) return;
        pushUndo();
        [layers[currentLayer], layers[currentLayer-1]] = [layers[currentLayer-1], layers[currentLayer]];
        currentLayer--; refreshLayers(); render();
      });
      refreshLayers();

      // ── Frames ─────────────────────────────────────────
      function refreshFrames() {
        const el = document.getElementById('frameStrip');
        el.innerHTML = '';
        frames.forEach((_, i) => {
          const div = document.createElement('div');
          div.className = 'frame-thumb' + (i === currentFrame ? ' sel' : '');
          div.textContent = (i + 1);
          div.addEventListener('click', () => { currentFrame = i; refreshFrames(); });
          el.appendChild(div);
        });
        document.getElementById('statusFrameInfo').textContent = 'Frame ' + (currentFrame+1) + '/' + frames.length;
      }

      document.getElementById('btnAddFrame').addEventListener('click', () => {
        frames.push(JSON.parse(JSON.stringify(layers.map(l => l.data))));
        currentFrame = frames.length - 1; refreshFrames(); markDirty();
      });
      document.getElementById('btnDupFrame').addEventListener('click', () => {
        const dup = JSON.parse(JSON.stringify(layers.map(l => l.data)));
        frames.splice(currentFrame + 1, 0, dup);
        currentFrame++; refreshFrames(); markDirty();
      });
      document.getElementById('btnDelFrame').addEventListener('click', () => {
        if (frames.length <= 1) { showToast('Cannot delete last frame', 'warn'); return; }
        frames.splice(currentFrame, 1);
        currentFrame = Math.min(currentFrame, frames.length - 1);
        refreshFrames(); markDirty();
      });

      document.getElementById('fpsInput').addEventListener('change', (e) => {
        fps = Math.max(1, Math.min(60, parseInt(e.target.value) || 8));
        e.target.value = fps;
      });

      document.getElementById('btnPlay').addEventListener('click', function() {
        playing = !playing;
        this.innerHTML = playing ? '${ICONS.stop} Stop' : '${ICONS.play} Play';
        if (playing && frames.length > 1) {
          let fi = currentFrame;
          animTimer = setInterval(() => {
            // Save current frame data
            if (frames[fi]) {
              layers.forEach((l, i) => { if (frames[fi][i]) l.data = [...frames[fi][i]]; });
            }
            fi = (fi + 1) % frames.length;
            currentFrame = fi; refreshFrames(); render();
          }, Math.round(1000 / fps));
        } else { clearInterval(animTimer); }
      });

      document.getElementById('btnOnionSkin').addEventListener('click', function() {
        showOnionSkin = !showOnionSkin;
        this.classList.toggle('active', showOnionSkin);
        render();
      });
      refreshFrames();

      // ── Preview Background ─────────────────────────────
      const bgModes = ['checker', 'black', 'white', 'transparent'];
      let bgIdx = 0;
      document.getElementById('btnPreviewBg').addEventListener('click', function() {
        bgIdx = (bgIdx + 1) % bgModes.length;
        previewBg = bgModes[bgIdx];
        this.textContent = 'BG: ' + previewBg.charAt(0).toUpperCase() + previewBg.slice(1);
        renderPreview();
      });

      // ── Export ─────────────────────────────────────────
      function buildPng() {
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
        return tmpCanvas.toDataURL('image/png');
      }

      function buildSpriteSheet() {
        const cols = Math.ceil(Math.sqrt(frames.length));
        const rows = Math.ceil(frames.length / cols);
        const tmpCanvas = document.createElement('canvas');
        tmpCanvas.width = gridSize * cols; tmpCanvas.height = gridSize * rows;
        const tmpCtx = tmpCanvas.getContext('2d');
        frames.forEach((fData, fi) => {
          const fx = (fi % cols) * gridSize, fy = Math.floor(fi / cols) * gridSize;
          const layerData = fData || layers.map(l => l.data);
          for (let li = 0; li < layerData.length; li++) {
            if (layers[li] && !layers[li].visible) continue;
            for (let y = 0; y < gridSize; y++)
              for (let x = 0; x < gridSize; x++) {
                const c = layerData[li] ? layerData[li][y * gridSize + x] : null;
                if (c) { tmpCtx.fillStyle = c; tmpCtx.fillRect(fx + x, fy + y, 1, 1); }
              }
          }
        });
        return tmpCanvas.toDataURL('image/png');
      }

      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Pixel Art Editor'];
        lines.push('-- Load sprite:');
        lines.push('local sprite = lurek.render.newImage("sprites/mysprite.png")');
        if (frames.length > 1) {
          const cols = Math.ceil(Math.sqrt(frames.length));
          lines.push('');
          lines.push('-- Sprite sheet quads (' + frames.length + ' frames, ' + gridSize + 'x' + gridSize + ')');
          lines.push('local quads = {}');
          lines.push('local sheet = lurek.render.newImage("sprites/mysprite_sheet.png")');
          frames.forEach((_, fi) => {
            const qx = (fi % cols) * gridSize, qy = Math.floor(fi / cols) * gridSize;
            lines.push('quads[' + (fi+1) + '] = lurek.render.newQuad(' + qx + ', ' + qy + ', ' + gridSize + ', ' + gridSize + ', sheet:getWidth(), sheet:getHeight())');
          });
          lines.push('');
          lines.push('-- Draw a frame:');
          lines.push('-- lurek.render.drawq(sheet, quads[frameIndex], x, y)');
        }
        return lines.join('\\n');
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export PNG (current frame)', action: () => vscode.postMessage({ type: 'exportPng', content: buildPng() }) },
        { label: 'Export Sprite Sheet (all frames)', action: () => vscode.postMessage({ type: 'exportSpriteSheet', content: buildSpriteSheet() }) },
        { label: 'Copy Lua Code', action: () => vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() }) },
        { label: 'Insert Lua to Editor', action: () => vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() }) },
      ]);

      document.getElementById('btnCopyLua').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() });
      });

      // ── Center canvas & init ───────────────────────────
      function centerCanvas() {
        const area = canvas.parentElement;
        const totalPx = gridSize * zoom;
        offsetX = (area.clientWidth - totalPx) / 2;
        offsetY = (area.clientHeight - totalPx) / 2;
      }
      zoom = Math.max(2, Math.floor(320 / gridSize));
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
      centerCanvas();
      render();
    `);
  }
}
