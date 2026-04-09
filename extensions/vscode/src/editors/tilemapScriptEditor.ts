import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class TilemapScriptEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): TilemapScriptEditor {
    return new TilemapScriptEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "luna.editor.tilemapScript", "Tilemap Script Editor");
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
        display: grid; grid-template-columns: 200px 1fr 300px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .blocks-panel { grid-row: 2; }
      .script-area { grid-row: 2; padding: 8px; overflow-y: auto; border-right: 1px solid var(--border); }
      .preview-panel { grid-row: 2; display: flex; flex-direction: column; }
      .status-bar { grid-column: 1 / -1; }
      .block-btn { width: 100%; margin-bottom: 3px; text-align: left; font-size: 11px; padding: 6px 8px; }
      .script-step {
        background: var(--surface-2); border: 1px solid var(--border); border-radius: 4px;
        padding: 8px; margin-bottom: 6px; position: relative;
      }
      .script-step h4 { font-size: 12px; margin-bottom: 6px; display: flex; justify-content: space-between; }
      .script-step .step-num { color: var(--accent); font-weight: bold; }
      .preview-canvas { flex: 1; background: #111; display: flex; align-items: center; justify-content: center; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <label>Width:</label><input type="number" id="mapW" value="40" min="5" max="100" style="width:50px">
          <label>Height:</label><input type="number" id="mapH" value="30" min="5" max="100" style="width:50px">
          <label>Seed:</label><input type="number" id="seed" value="1234" style="width:60px">
          <div class="sep"></div>
          <button id="btnRun">Run Script</button>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="panel blocks-panel">
          <h3>Script Blocks</h3>
          <button class="block-btn" data-block="fill">Fill All</button>
          <button class="block-btn" data-block="noise">Random Noise</button>
          <button class="block-btn" data-block="rooms">Place Rooms</button>
          <button class="block-btn" data-block="corridors">Connect Corridors</button>
          <button class="block-btn" data-block="border">Add Border</button>
          <button class="block-btn" data-block="scatter">Scatter Objects</button>
          <button class="block-btn" data-block="cellular">Cellular Automata</button>
          <button class="block-btn" data-block="clear_center">Clear Center</button>
        </div>
        <div class="script-area" id="scriptArea">
          <h3>Script Steps</h3>
          <div id="stepList"></div>
          <p style="color:var(--text-dim);font-size:11px;margin-top:8px;">Click blocks on the left to add steps. Drag to reorder.</p>
        </div>
        <div class="preview-panel">
          <h3 style="padding:8px;background:var(--surface);border-bottom:1px solid var(--border);">Preview</h3>
          <div class="preview-canvas"><canvas id="previewCanvas"></canvas></div>
        </div>
        <div class="status-bar">
          <span id="statusInfo">Steps: 0 | Size: 40x30</span>
        </div>
      </div>
    `, `
      let mapW = 40, mapH = 30, seed = 1234;
      let mapData = [];
      let steps = [];

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
            paramsHtml += '<div class="field-row"><label style="width:70px;font-size:11px">' + k + '</label>';
            paramsHtml += '<input type="number" data-si="' + i + '" data-pk="' + k + '" value="' + v + '" style="width:60px" step="' + (typeof v === 'number' && v < 1 ? 0.05 : 1) + '"></div>';
          }
          div.innerHTML = '<h4><span class="step-num">#' + (i + 1) + '</span> ' + step.label +
            ' <span><button data-up="' + i + '">\\u25B2</button><button data-down="' + i + '">\\u25BC</button><button data-del="' + i + '"> x</button></span></h4>' + paramsHtml;
          el.appendChild(div);

          div.querySelectorAll('input[data-si]').forEach(inp => {
            inp.addEventListener('input', (e) => {
              steps[parseInt(e.target.dataset.si)].params[e.target.dataset.pk] = parseFloat(e.target.value) || 0;
            });
          });
          const up = div.querySelector('[data-up]');
          if (up) up.addEventListener('click', () => { if (i > 0) { [steps[i-1], steps[i]] = [steps[i], steps[i-1]]; refreshSteps(); } });
          const down = div.querySelector('[data-down]');
          if (down) down.addEventListener('click', () => { if (i < steps.length-1) { [steps[i], steps[i+1]] = [steps[i+1], steps[i]]; refreshSteps(); } });
          div.querySelector('[data-del]').addEventListener('click', () => { steps.splice(i, 1); refreshSteps(); });
        });
        document.getElementById('statusInfo').textContent = 'Steps: ' + steps.length + ' | Size: ' + mapW + 'x' + mapH;
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
              for (let i = 0; i < mapData.length; i++) { if (rng() < p.density) mapData[i] = p.tile; }
              break;
            case 'rooms':
              for (let r = 0; r < (p.count || 5); r++) {
                const rw = Math.floor(rng() * ((p.maxSize||8) - (p.minSize||3))) + (p.minSize||3);
                const rh = Math.floor(rng() * ((p.maxSize||8) - (p.minSize||3))) + (p.minSize||3);
                const rx = Math.floor(rng() * (mapW - rw - 2)) + 1;
                const ry = Math.floor(rng() * (mapH - rh - 2)) + 1;
                for (let y = ry; y < ry + rh; y++) for (let x = rx; x < rx + rw; x++) set(x, y, 0);
                rooms.push({ cx: rx + Math.floor(rw/2), cy: ry + Math.floor(rh/2) });
              }
              break;
            case 'corridors':
              for (let i = 0; i < rooms.length - 1; i++) {
                const a = rooms[i], b = rooms[i+1];
                let cx = a.cx;
                while (cx !== b.cx) { set(cx, a.cy, 0); cx += cx < b.cx ? 1 : -1; }
                let cy = a.cy;
                while (cy !== b.cy) { set(b.cx, cy, 0); cy += cy < b.cy ? 1 : -1; }
              }
              break;
            case 'border':
              for (let x = 0; x < mapW; x++) for (let t = 0; t < (p.thickness || 1); t++) { set(x, t, p.tile); set(x, mapH - 1 - t, p.tile); }
              for (let y = 0; y < mapH; y++) for (let t = 0; t < (p.thickness || 1); t++) { set(t, y, p.tile); set(mapW - 1 - t, y, p.tile); }
              break;
            case 'scatter':
              for (let i = 0; i < mapData.length; i++) { if (mapData[i] === 0 && rng() < (p.density || 0.05)) mapData[i] = p.tile; }
              break;
            case 'cellular':
              for (let iter = 0; iter < (p.iterations || 4); iter++) {
                const next = [...mapData];
                for (let y = 0; y < mapH; y++) for (let x = 0; x < mapW; x++) {
                  let walls = 0;
                  for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
                    if (dx === 0 && dy === 0) continue;
                    if (get(x+dx, y+dy) === 1) walls++;
                  }
                  if (mapData[y*mapW+x] === 1) next[y*mapW+x] = walls >= (p.deathLimit||3) ? 1 : 0;
                  else next[y*mapW+x] = walls >= (p.birthLimit||4) ? 1 : 0;
                }
                mapData = next;
              }
              break;
            case 'clear_center': {
              const cx = Math.floor(mapW/2), cy = Math.floor(mapH/2), r = p.radius || 5;
              for (let y = cy - r; y <= cy + r; y++) for (let x = cx - r; x <= cx + r; x++) {
                if (Math.hypot(x - cx, y - cy) <= r) set(x, y, 0);
              }
              break;
            }
          }
        }
        renderPreview();
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

      document.querySelectorAll('.block-btn').forEach(btn => {
        btn.addEventListener('click', () => addStep(btn.dataset.block));
      });
      document.getElementById('btnRun').addEventListener('click', runScript);
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  width = ' + mapW + ',\\n  height = ' + mapH + ',\\n  seed = ' + seed + ',\\n';
        lua += '  steps = {\\n';
        for (const s of steps) {
          lua += '    { type = "' + s.type + '"';
          for (const [k, v] of Object.entries(s.params)) lua += ', ' + k + ' = ' + v;
          lua += ' },\\n';
        }
        lua += '  }\\n}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      addStep('fill'); addStep('noise'); addStep('cellular'); addStep('border');
      refreshSteps();
      runScript();
    `);
  }
}
