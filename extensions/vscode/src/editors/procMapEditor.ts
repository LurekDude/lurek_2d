import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class ProcMapEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): ProcMapEditor {
    return new ProcMapEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.editor.procMap", "Procedural Map Generator");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "mapgen.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Procedural Map Generator", `
      .editor-layout {
        display: grid; grid-template-columns: 260px 1fr;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .pipeline-panel { grid-row: 2; overflow-y: auto; padding: 8px; background: var(--surface); border-right: 1px solid var(--border); }
      .preview-area { grid-row: 2; display: flex; align-items: center; justify-content: center; background: #111; overflow: hidden; }
      .status-bar { grid-column: 1 / -1; }
      .step-card {
        background: var(--surface-2); border: 1px solid var(--border); border-radius: 4px;
        padding: 8px; margin-bottom: 6px;
      }
      .step-card h4 { font-size: 12px; margin-bottom: 6px; display: flex; justify-content: space-between; }
      .step-card h4 button { font-size: 10px; padding: 1px 6px; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <label>Width:</label><input type="number" id="mapW" value="60" min="10" max="200" style="width:50px">
          <label>Height:</label><input type="number" id="mapH" value="40" min="10" max="200" style="width:50px">
          <label>Seed:</label><input type="number" id="seed" value="42" style="width:60px">
          <div class="sep"></div>
          <button id="btnGenerate">Generate</button>
          <button id="btnRandomSeed">Random Seed</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="pipeline-panel">
          <h3>Pipeline Steps</h3>
          <div id="stepList"></div>
          <div style="margin-top: 8px;">
            <select id="addStepSelect" style="width: 100%;">
              <option value="">+ Add Step...</option>
              <option value="fill">Fill</option>
              <option value="noise">Noise</option>
              <option value="cellular">Cellular Automata</option>
              <option value="rooms">Room Placement</option>
              <option value="corridors">Corridors</option>
            </select>
          </div>
        </div>
        <div class="preview-area"><canvas id="mapCanvas"></canvas></div>
        <div class="status-bar">
          <span id="statusInfo">Size: 60x40 | Seed: 42</span>
          <span id="statusSteps">Steps: 0</span>
        </div>
      </div>
    `, `
      let mapW = 60, mapH = 40, seed = 42;
      let mapData = [];
      let steps = [
        { type: 'fill', params: { tile: 1 } },
        { type: 'noise', params: { density: 0.45, tile: 0 } },
        { type: 'cellular', params: { iterations: 5, birthLimit: 4, deathLimit: 3 } },
      ];

      // Simple seeded RNG
      function mulberry32(a) {
        return function() {
          a |= 0; a = a + 0x6D2B79F5 | 0;
          var t = Math.imul(a ^ a >>> 15, 1 | a);
          t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
          return ((t ^ t >>> 14) >>> 0) / 4294967296;
        };
      }

      let rng = mulberry32(seed);

      const TILE_CHARS = { 0: '.', 1: '#', 2: '+', 3: '~' };
      const TILE_COLORS = { 0: '#2a2a2a', 1: '#4a4a4a', 2: '#3a5a3a', 3: '#2a3a5a' };

      function initMap() { mapData = new Array(mapW * mapH).fill(0); }
      function getCell(x, y) { return (x >= 0 && x < mapW && y >= 0 && y < mapH) ? mapData[y * mapW + x] : 1; }
      function setCell(x, y, v) { if (x >= 0 && x < mapW && y >= 0 && y < mapH) mapData[y * mapW + x] = v; }

      function countNeighbors(x, y, tile) {
        let count = 0;
        for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
          if (dx === 0 && dy === 0) continue;
          if (getCell(x + dx, y + dy) === tile) count++;
        }
        return count;
      }

      function applyStep(step) {
        switch (step.type) {
          case 'fill':
            mapData.fill(step.params.tile);
            break;
          case 'noise':
            for (let i = 0; i < mapData.length; i++) {
              if (rng() < step.params.density) mapData[i] = step.params.tile;
            }
            break;
          case 'cellular':
            for (let iter = 0; iter < step.params.iterations; iter++) {
              const next = [...mapData];
              for (let y = 0; y < mapH; y++) for (let x = 0; x < mapW; x++) {
                const walls = countNeighbors(x, y, 1);
                if (mapData[y * mapW + x] === 1) {
                  next[y * mapW + x] = walls >= step.params.deathLimit ? 1 : 0;
                } else {
                  next[y * mapW + x] = walls >= step.params.birthLimit ? 1 : 0;
                }
              }
              mapData = next;
            }
            break;
          case 'rooms': {
            const count = step.params.count || 6;
            const minS = step.params.minSize || 4, maxS = step.params.maxSize || 10;
            for (let i = 0; i < count; i++) {
              const rw = Math.floor(rng() * (maxS - minS)) + minS;
              const rh = Math.floor(rng() * (maxS - minS)) + minS;
              const rx = Math.floor(rng() * (mapW - rw - 2)) + 1;
              const ry = Math.floor(rng() * (mapH - rh - 2)) + 1;
              for (let y = ry; y < ry + rh; y++) for (let x = rx; x < rx + rw; x++) setCell(x, y, 0);
            }
            break;
          }
          case 'corridors': {
            // Connect open areas with L-shaped corridors
            const openSpots = [];
            for (let y = 2; y < mapH - 2; y += 8) for (let x = 2; x < mapW - 2; x += 8) {
              if (getCell(x, y) === 0) openSpots.push({ x, y });
            }
            for (let i = 0; i < openSpots.length - 1; i++) {
              const a = openSpots[i], b = openSpots[i + 1];
              let cx = a.x;
              while (cx !== b.x) { setCell(cx, a.y, 0); cx += cx < b.x ? 1 : -1; }
              let cy = a.y;
              while (cy !== b.y) { setCell(b.x, cy, 0); cy += cy < b.y ? 1 : -1; }
            }
            break;
          }
        }
      }

      function generate() {
        mapW = parseInt(document.getElementById('mapW').value) || 60;
        mapH = parseInt(document.getElementById('mapH').value) || 40;
        seed = parseInt(document.getElementById('seed').value) || 0;
        rng = mulberry32(seed);
        initMap();
        for (const step of steps) applyStep(step);
        renderMap();
        document.getElementById('statusInfo').textContent = 'Size: ' + mapW + 'x' + mapH + ' | Seed: ' + seed;
      }

      function renderMap() {
        const canvas = document.getElementById('mapCanvas');
        const cs = Math.min(Math.floor(canvas.parentElement.clientWidth / mapW), Math.floor(canvas.parentElement.clientHeight / mapH), 12);
        canvas.width = mapW * cs; canvas.height = mapH * cs;
        const ctx = canvas.getContext('2d');
        for (let y = 0; y < mapH; y++) for (let x = 0; x < mapW; x++) {
          ctx.fillStyle = TILE_COLORS[mapData[y * mapW + x]] || '#000';
          ctx.fillRect(x * cs, y * cs, cs, cs);
        }
      }

      function refreshStepList() {
        const el = document.getElementById('stepList');
        el.innerHTML = '';
        steps.forEach((step, i) => {
          const card = document.createElement('div');
          card.className = 'step-card';
          let paramsHtml = '';
          for (const [k, v] of Object.entries(step.params)) {
            paramsHtml += '<div class="field-row"><label style="width:70px">' + k + '</label><input type="number" data-si="' + i + '" data-pk="' + k + '" value="' + v + '" style="width:60px" step="' + (typeof v === 'number' && v < 1 ? 0.05 : 1) + '"></div>';
          }
          card.innerHTML = '<h4>' + (i + 1) + '. ' + step.type + ' <button data-del="' + i + '">x</button></h4>' + paramsHtml;
          el.appendChild(card);
          card.querySelectorAll('input[data-si]').forEach(inp => {
            inp.addEventListener('input', (e) => {
              steps[parseInt(e.target.dataset.si)].params[e.target.dataset.pk] = parseFloat(e.target.value) || 0;
            });
          });
          card.querySelector('[data-del]').addEventListener('click', (e) => {
            steps.splice(parseInt(e.target.dataset.del), 1); refreshStepList();
          });
        });
        document.getElementById('statusSteps').textContent = 'Steps: ' + steps.length;
      }

      document.getElementById('addStepSelect').addEventListener('change', (e) => {
        if (!e.target.value) return;
        const defaults = {
          fill: { tile: 1 }, noise: { density: 0.45, tile: 0 },
          cellular: { iterations: 5, birthLimit: 4, deathLimit: 3 },
          rooms: { count: 6, minSize: 4, maxSize: 10 }, corridors: {}
        };
        steps.push({ type: e.target.value, params: { ...defaults[e.target.value] } });
        e.target.value = '';
        refreshStepList();
      });

      document.getElementById('btnGenerate').addEventListener('click', generate);
      document.getElementById('btnRandomSeed').addEventListener('click', () => {
        document.getElementById('seed').value = String(Math.floor(Math.random() * 999999));
        generate();
      });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  width = ' + mapW + ',\\n  height = ' + mapH + ',\\n  seed = ' + seed + ',\\n';
        lua += '  steps = {\\n';
        for (const s of steps) {
          lua += '    { type = "' + s.type + '"';
          for (const [k, v] of Object.entries(s.params)) lua += ', ' + k + ' = ' + v;
          lua += ' },\\n';
        }
        lua += '  },\\n  data = {\\n    ';
        for (let y = 0; y < mapH; y++) {
          lua += mapData.slice(y * mapW, (y + 1) * mapW).join(', ') + ',\\n    ';
        }
        lua += '\\n  }\\n}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      refreshStepList();
      window.addEventListener('resize', () => renderMap());
      generate();
    `);
  }
}
