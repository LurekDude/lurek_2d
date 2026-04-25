import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

export class TilemapScriptEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): TilemapScriptEditor {
    return new TilemapScriptEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.editor.tilemapScript", "Tilemap Script Editor");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "tilemap_script.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Tilemap Script Editor", `
      .editor-layout {
        display: grid; grid-template-columns: 180px 1fr 280px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .blocks-panel { grid-row: 2; background: var(--surface); border-right: 1px solid var(--border); overflow-y: auto; }
      .script-area { grid-row: 2; padding: 8px; overflow-y: auto; border-right: 1px solid var(--border); background: var(--bg); }
      .preview-panel { grid-row: 2; display: flex; flex-direction: column; background: var(--surface); }

      .block-btn {
        width: calc(100% - 8px); margin: 1px 4px; text-align: left; font-size: 11px;
        padding: 5px 8px; border-radius: var(--radius); cursor: pointer;
        border: 1px solid transparent; transition: border-color 0.1s, background 0.08s;
        display: flex; align-items: center; gap: 6px;
      }
      .block-btn:hover { border-color: var(--accent); background: var(--hover); }
      .block-btn .block-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }

      .script-step {
        background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius);
        padding: 8px; margin-bottom: 6px;
      }
      .script-step h4 {
        font-size: 11px; margin-bottom: 6px; display: flex; justify-content: space-between; align-items: center;
      }
      .script-step .step-num { color: var(--accent); font-weight: 700; font-size: 10px; }
      .step-controls button { padding: 1px 5px; font-size: 10px; }
      .preview-canvas { flex: 1; display: flex; align-items: center; justify-content: center; background: #111; }
    `, `
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            <label style="font-size:11px">W:</label><input type="number" id="mapW" value="40" min="5" max="100" style="width:44px">
            <label style="font-size:11px">H:</label><input type="number" id="mapH" value="30" min="5" max="100" style="width:44px">
            <label style="font-size:11px">Seed:</label><input type="number" id="seed" value="1234" style="width:56px">
          </div>
          ${toolbarSep()}
          <div class="group">
            <button id="btnRun">${ICONS.play} Run Script</button>
          </div>
          ${toolbarSep()}
          <div class="group">
            ${iconButton('undo', { id: 'btnUndo', title: 'Undo (Ctrl+Z)' })}
            ${iconButton('redo', { id: 'btnRedo', title: 'Redo (Ctrl+Y)' })}
          </div>
          ${toolbarSpacer()}
          <div class="group">
            ${iconButton('copy', { id: 'btnCopyLua', title: 'Copy Lua Code' })}
            ${iconButton('insert', { id: 'btnInsert', title: 'Insert to Editor' })}
          </div>
          ${toolbarSep()}
          <button id="btnExport" class="primary">${ICONS.exportFile} Export ▾</button>
        </div>

        <!-- Blocks Palette -->
        <div class="blocks-panel">
          ${panelSection('Script Blocks', `
            <button class="block-btn" data-block="fill"><span class="block-dot" style="background:#585b70"></span>Fill All</button>
            <button class="block-btn" data-block="noise"><span class="block-dot" style="background:#89b4fa"></span>Random Noise</button>
            <button class="block-btn" data-block="rooms"><span class="block-dot" style="background:#a6e3a1"></span>Place Rooms</button>
            <button class="block-btn" data-block="corridors"><span class="block-dot" style="background:#f9e2af"></span>Connect Corridors</button>
            <button class="block-btn" data-block="border"><span class="block-dot" style="background:#f38ba8"></span>Add Border</button>
            <button class="block-btn" data-block="scatter"><span class="block-dot" style="background:#cba6f7"></span>Scatter Objects</button>
            <button class="block-btn" data-block="cellular"><span class="block-dot" style="background:#fab387"></span>Cellular Automata</button>
            <button class="block-btn" data-block="clear_center"><span class="block-dot" style="background:#94e2d5"></span>Clear Center</button>
          `)}
        </div>

        <!-- Script Steps -->
        <div class="script-area">
          <div style="font-size:11px;color:var(--text-dim);margin-bottom:8px;">Click blocks to add steps. Use arrows to reorder.</div>
          <div id="stepList"></div>
        </div>

        <!-- Preview -->
        <div class="preview-panel">
          <div style="padding:6px 8px;background:var(--surface);border-bottom:1px solid var(--border);font-size:11px;font-weight:600;color:var(--text-dim);text-transform:uppercase;letter-spacing:0.5px">Preview</div>
          <div class="preview-canvas"><canvas id="previewCanvas"></canvas></div>
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusSteps" class="badge">0 steps</span>
          </span>
          <div class="sep"></div>
          <span id="statusSize">40 × 30</span>
          <div class="sep"></div>
          <span id="statusSeed">Seed: 1234</span>
          <div class="spacer"></div>
          <span class="dirty-indicator">${ICONS.clean}</span>
        </div>
      </div>
    `, `
      let mapW = 40, mapH = 30, seed = 1234;
      let mapData = [];
      let steps = [];
      const undo = new UndoStack(40);

      function snapshot() { return JSON.parse(JSON.stringify(steps)); }
      function restoreSnap(s) { steps = s; refreshSteps(); runScript(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      const BLOCK_DEFAULTS = {
        fill: { label: 'Fill All', params: { tile: 1 } },
        noise: { label: 'Random Noise', params: { density: 0.4, tile: 0 } },
        rooms: { label: 'Place Rooms', params: { count: 5, minSize: 3, maxSize: 8 } },
        corridors: { label: 'Connect Corridors', params: {} },
        border: { label: 'Add Border', params: { tile: 1, thickness: 1 } },
        scatter: { label: 'Scatter Objects', params: { tile: 2, density: 0.05 } },
        cellular: { label: 'Cellular Automata', params: { iterations: 4, birthLimit: 4, deathLimit: 3 } },
        clear_center: { label: 'Clear Center', params: { radius: 5 } },
      };

      const TILE_COLORS = ['#1a1a2e', '#4a4a4a', '#3a5a3a', '#5a3a3a', '#3a3a5a'];

      function mulberry32(a) {
        return function() {
          a |= 0; a = a + 0x6D2B79F5 | 0;
          var t = Math.imul(a ^ a >>> 15, 1 | a);
          t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
          return ((t ^ t >>> 14) >>> 0) / 4294967296;
        };
      }

      function addStep(type) {
        pushUndo();
        const def = BLOCK_DEFAULTS[type];
        steps.push({ type, label: def.label, params: { ...def.params } });
        refreshSteps();
      }

      function refreshSteps() {
        const el = document.getElementById('stepList');
        el.innerHTML = '';
        steps.forEach((step, i) => {
          const div = document.createElement('div');
          div.className = 'script-step';
          let paramsHtml = '';
          for (const [k, v] of Object.entries(step.params)) {
            paramsHtml += '<div style="display:flex;align-items:center;gap:4px;margin-bottom:3px"><label style="width:65px;font-size:10px;color:var(--text-dim);text-transform:uppercase">' + k + '</label>';
            paramsHtml += '<input type="number" data-si="' + i + '" data-pk="' + k + '" value="' + v + '" style="width:60px" step="' + (typeof v === 'number' && v < 1 ? 0.05 : 1) + '"></div>';
          }
          div.innerHTML = '<h4><span><span class="step-num">#' + (i + 1) + '</span> ' + step.label + '</span>' +
            '<span class="step-controls"><button data-up="' + i + '" title="Move Up">▲</button><button data-down="' + i + '" title="Move Down">▼</button><button data-del="' + i + '" title="Remove">✕</button></span></h4>' + paramsHtml;
          el.appendChild(div);

          div.querySelectorAll('input[data-si]').forEach(inp => {
            inp.addEventListener('input', (e) => {
              steps[parseInt(e.target.dataset.si)].params[e.target.dataset.pk] = parseFloat(e.target.value) || 0;
            });
          });
          const up = div.querySelector('[data-up]');
          if (up) up.addEventListener('click', () => { if (i > 0) { pushUndo(); [steps[i-1], steps[i]] = [steps[i], steps[i-1]]; refreshSteps(); } });
          const down = div.querySelector('[data-down]');
          if (down) down.addEventListener('click', () => { if (i < steps.length-1) { pushUndo(); [steps[i], steps[i+1]] = [steps[i+1], steps[i]]; refreshSteps(); } });
          div.querySelector('[data-del]').addEventListener('click', () => { pushUndo(); steps.splice(i, 1); refreshSteps(); });
        });
        updateStatus();
      }

      function runScript() {
        mapW = parseInt(document.getElementById('mapW').value) || 40;
        mapH = parseInt(document.getElementById('mapH').value) || 30;
        seed = parseInt(document.getElementById('seed').value) || 0;
        const rng = mulberry32(seed);
        mapData = new Array(mapW * mapH).fill(0);

        const get = (x, y) => (x >= 0 && x < mapW && y >= 0 && y < mapH) ? mapData[y * mapW + x] : 1;
        const set = (x, y, v) => { if (x >= 0 && x < mapW && y >= 0 && y < mapH) mapData[y * mapW + x] = v; };

        const rooms = [];
        for (const step of steps) {
          const p = step.params;
          switch (step.type) {
            case 'fill': mapData.fill(p.tile); break;
            case 'noise':
              for (let i = 0; i < mapData.length; i++) { if (rng() < p.density) mapData[i] = p.tile; } break;
            case 'rooms':
              for (let r = 0; r < (p.count || 5); r++) {
                const rw = Math.floor(rng() * ((p.maxSize||8) - (p.minSize||3))) + (p.minSize||3);
                const rh = Math.floor(rng() * ((p.maxSize||8) - (p.minSize||3))) + (p.minSize||3);
                const rx = Math.floor(rng() * (mapW - rw - 2)) + 1;
                const ry = Math.floor(rng() * (mapH - rh - 2)) + 1;
                for (let y = ry; y < ry + rh; y++) for (let x = rx; x < rx + rw; x++) set(x, y, 0);
                rooms.push({ cx: rx + Math.floor(rw/2), cy: ry + Math.floor(rh/2) });
              } break;
            case 'corridors':
              for (let i = 0; i < rooms.length - 1; i++) {
                const a = rooms[i], b = rooms[i+1];
                let cx = a.cx; while (cx !== b.cx) { set(cx, a.cy, 0); cx += cx < b.cx ? 1 : -1; }
                let cy = a.cy; while (cy !== b.cy) { set(b.cx, cy, 0); cy += cy < b.cy ? 1 : -1; }
              } break;
            case 'border':
              for (let x = 0; x < mapW; x++) for (let t = 0; t < (p.thickness || 1); t++) { set(x, t, p.tile); set(x, mapH - 1 - t, p.tile); }
              for (let y = 0; y < mapH; y++) for (let t = 0; t < (p.thickness || 1); t++) { set(t, y, p.tile); set(mapW - 1 - t, y, p.tile); }
              break;
            case 'scatter':
              for (let i = 0; i < mapData.length; i++) { if (mapData[i] === 0 && rng() < (p.density || 0.05)) mapData[i] = p.tile; } break;
            case 'cellular':
              for (let iter = 0; iter < (p.iterations || 4); iter++) {
                const next = [...mapData];
                for (let y = 0; y < mapH; y++) for (let x = 0; x < mapW; x++) {
                  let walls = 0;
                  for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
                    if (dx === 0 && dy === 0) continue; if (get(x+dx, y+dy) === 1) walls++;
                  }
                  if (mapData[y*mapW+x] === 1) next[y*mapW+x] = walls >= (p.deathLimit||3) ? 1 : 0;
                  else next[y*mapW+x] = walls >= (p.birthLimit||4) ? 1 : 0;
                }
                mapData = next;
              } break;
            case 'clear_center': {
              const cx = Math.floor(mapW/2), cy = Math.floor(mapH/2), r = p.radius || 5;
              for (let y = cy - r; y <= cy + r; y++) for (let x = cx - r; x <= cx + r; x++) {
                if (Math.hypot(x - cx, y - cy) <= r) set(x, y, 0);
              } break;
            }
          }
        }
        renderPreview();
        updateStatus();
      }

      function renderPreview() {
        const canvas = document.getElementById('previewCanvas');
        const parent = canvas.parentElement;
        const cs = Math.min(Math.floor(parent.clientWidth / mapW), Math.floor(parent.clientHeight / mapH), 12);
        canvas.width = mapW * cs; canvas.height = mapH * cs;
        const ctx = canvas.getContext('2d');
        for (let y = 0; y < mapH; y++) for (let x = 0; x < mapW; x++) {
          ctx.fillStyle = TILE_COLORS[mapData[y * mapW + x]] || '#000';
          ctx.fillRect(x * cs, y * cs, cs, cs);
        }
      }

      function updateStatus() {
        document.getElementById('statusSteps').textContent = steps.length + ' steps';
        document.getElementById('statusSize').textContent = mapW + ' × ' + mapH;
        document.getElementById('statusSeed').textContent = 'Seed: ' + seed;
      }

      // ── Palette clicks ─────────────────────────────────
      document.querySelectorAll('.block-btn').forEach(btn => {
        btn.addEventListener('click', () => addStep(btn.dataset.block));
      });

      // ── Buttons ────────────────────────────────────────
      document.getElementById('btnRun').addEventListener('click', runScript);
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restoreSnap(s); });

      // ── Shortcuts ──────────────────────────────────────
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+Enter', () => runScript());

      // ── Export ─────────────────────────────────────────
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Tilemap Script Editor', ''];
        lines.push('return {');
        lines.push('  width = ' + mapW + ',');
        lines.push('  height = ' + mapH + ',');
        lines.push('  seed = ' + seed + ',');
        lines.push('  steps = {');
        for (const s of steps) {
          let params = '';
          for (const [k, v] of Object.entries(s.params)) params += ', ' + k + ' = ' + v;
          lines.push('    { type = "' + s.type + '"' + params + ' },');
        }
        lines.push('  },');
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
      addStep('fill'); addStep('noise'); addStep('cellular'); addStep('border');
      refreshSteps(); runScript();
    `);
  }
}
