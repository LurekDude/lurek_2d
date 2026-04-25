import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

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
      .status-bar { grid-column: 1 / -1; }
      .pipeline-panel { grid-row: 2; overflow-y: auto; background: var(--surface); border-right: 1px solid var(--border); }
      .preview-area { grid-row: 2; display: flex; align-items: center; justify-content: center; background: var(--bg); overflow: hidden; }

      .step-card {
        background: var(--surface-2); border: 1px solid var(--border); border-radius: var(--radius);
        margin: 0 4px 6px 4px; overflow: hidden;
      }
      .step-card-header {
        display: flex; align-items: center; justify-content: space-between;
        padding: 5px 8px; font-size: 11px; font-weight: 600;
        text-transform: uppercase; letter-spacing: 0.3px;
        border-bottom: 1px solid var(--border); cursor: grab;
      }
      .step-card-header .num { color: var(--accent); margin-right: 6px; font-family: var(--font-mono); }
      .step-card-header .actions { display: flex; gap: 2px; }
      .step-card-body { padding: 6px 8px; }
      .step-card-body .param-row {
        display: grid; grid-template-columns: 80px 1fr; gap: 4px;
        align-items: center; margin-bottom: 3px;
      }
      .step-card-body .param-row label { font-size: 10px; text-align: right; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.3px; }

      .config-field {
        display: grid; grid-template-columns: 60px 1fr; gap: 4px;
        align-items: center; margin-bottom: 4px;
      }
      .config-field label { font-size: 10px; text-align: right; color: var(--text-dim); text-transform: uppercase; }

      .add-step-btn { width: calc(100% - 16px); margin: 4px 8px; font-size: 11px; }
    `, `
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            <button id="btnGenerate" class="primary">${ICONS.refresh} Generate</button>
            <button id="btnRandomSeed">${ICONS.dice} Random Seed</button>
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

        <!-- Pipeline Panel -->
        <div class="pipeline-panel">
          ${panelSection('Map Config', `
            <div class="config-field"><label>Width</label><input type="number" id="mapW" value="60" min="10" max="200" style="width:60px"></div>
            <div class="config-field"><label>Height</label><input type="number" id="mapH" value="40" min="10" max="200" style="width:60px"></div>
            <div class="config-field"><label>Seed</label><input type="number" id="seed" value="42" style="width:80px"></div>
          `)}
          ${panelSection('Pipeline Steps', '<div id="stepList"></div>')}
          <select id="addStepSelect" class="add-step-btn">
            <option value="">+ Add Step...</option>
            <option value="fill">Fill</option>
            <option value="noise">Noise</option>
            <option value="cellular">Cellular Automata</option>
            <option value="rooms">Room Placement</option>
            <option value="corridors">Corridors</option>
            <option value="border">Border Wall</option>
          </select>
        </div>

        <!-- Preview -->
        <div class="preview-area"><canvas id="mapCanvas"></canvas></div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusSize" class="badge">60 x 40</span>
          </span>
          <div class="sep"></div>
          <span id="statusSeed">Seed: 42</span>
          <div class="sep"></div>
          <span id="statusSteps">0 steps</span>
          <div class="spacer"></div>
          <span id="statusTiles">0 walls / 0 floor</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${ICONS.clean}</span>
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
      const undo = new UndoStack(40);

      function snapshot() { return JSON.parse(JSON.stringify({ steps, mapW, mapH, seed })); }
      function restoreSnap(s) { steps = s.steps; mapW = s.mapW; mapH = s.mapH; seed = s.seed;
        document.getElementById('mapW').value = mapW; document.getElementById('mapH').value = mapH;
        document.getElementById('seed').value = seed; refreshStepList(); generate();
      }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      function mulberry32(a) {
        return function() {
          a |= 0; a = a + 0x6D2B79F5 | 0;
          var t = Math.imul(a ^ a >>> 15, 1 | a);
          t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
          return ((t ^ t >>> 14) >>> 0) / 4294967296;
        };
      }
      let rng = mulberry32(seed);

      const TILE_COLORS = {
        0: '#1a1a2e', 1: '#3a3a5a', 2: '#2a4a2a', 3: '#2a3a5a',
      };

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
          case 'fill': mapData.fill(step.params.tile); break;
          case 'noise':
            for (let i = 0; i < mapData.length; i++) { if (rng() < step.params.density) mapData[i] = step.params.tile; }
            break;
          case 'cellular':
            for (let iter = 0; iter < step.params.iterations; iter++) {
              const next = [...mapData];
              for (let y = 0; y < mapH; y++) for (let x = 0; x < mapW; x++) {
                const walls = countNeighbors(x, y, 1);
                next[y * mapW + x] = mapData[y * mapW + x] === 1
                  ? (walls >= step.params.deathLimit ? 1 : 0)
                  : (walls >= step.params.birthLimit ? 1 : 0);
              }
              mapData = next;
            }
            break;
          case 'rooms': {
            const count = step.params.count || 6, minS = step.params.minSize || 4, maxS = step.params.maxSize || 10;
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
          case 'border':
            for (let x = 0; x < mapW; x++) { setCell(x, 0, 1); setCell(x, mapH - 1, 1); }
            for (let y = 0; y < mapH; y++) { setCell(0, y, 1); setCell(mapW - 1, y, 1); }
            break;
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
        updateStatus();
      }

      function renderMap() {
        const canvas = document.getElementById('mapCanvas');
        const parent = canvas.parentElement;
        const cs = Math.max(2, Math.min(Math.floor(parent.clientWidth / mapW), Math.floor(parent.clientHeight / mapH), 12));
        canvas.width = mapW * cs; canvas.height = mapH * cs;
        const ctx = canvas.getContext('2d');
        for (let y = 0; y < mapH; y++) for (let x = 0; x < mapW; x++) {
          ctx.fillStyle = TILE_COLORS[mapData[y * mapW + x]] || '#000';
          ctx.fillRect(x * cs, y * cs, cs, cs);
        }
      }

      function updateStatus() {
        document.getElementById('statusSize').textContent = mapW + ' x ' + mapH;
        document.getElementById('statusSeed').textContent = 'Seed: ' + seed;
        document.getElementById('statusSteps').textContent = steps.length + ' steps';
        const walls = mapData.filter(t => t === 1).length;
        document.getElementById('statusTiles').textContent = walls + ' walls / ' + (mapData.length - walls) + ' floor';
      }

      function refreshStepList() {
        const el = document.getElementById('stepList');
        el.innerHTML = '';
        steps.forEach((step, i) => {
          const card = document.createElement('div');
          card.className = 'step-card';
          let paramsHtml = '';
          for (const [k, v] of Object.entries(step.params)) {
            paramsHtml += '<div class="param-row"><label>' + k + '</label>' +
              '<input type="number" data-si="' + i + '" data-pk="' + k + '" value="' + v + '" style="width:60px" step="' + (typeof v === 'number' && v < 1 ? 0.05 : 1) + '"></div>';
          }
          card.innerHTML = '<div class="step-card-header"><span><span class="num">' + (i + 1) + '</span>' + step.type + '</span>' +
            '<span class="actions">' +
            '<button class="icon-btn" data-up="' + i + '" title="Move Up">${ICONS.up}</button>' +
            '<button class="icon-btn" data-down="' + i + '" title="Move Down">${ICONS.down}</button>' +
            '<button class="icon-btn" data-del="' + i + '" title="Remove">${ICONS.trash}</button>' +
            '</span></div><div class="step-card-body">' + paramsHtml + '</div>';
          el.appendChild(card);
          card.querySelectorAll('input[data-si]').forEach(inp => {
            inp.addEventListener('input', (e) => {
              pushUndo();
              steps[parseInt(e.target.dataset.si)].params[e.target.dataset.pk] = parseFloat(e.target.value) || 0;
            });
          });
          card.querySelector('[data-del]').addEventListener('click', (e) => {
            pushUndo(); steps.splice(parseInt(e.currentTarget.dataset.del), 1); refreshStepList();
          });
          const upBtn = card.querySelector('[data-up]');
          if (upBtn) upBtn.addEventListener('click', (e) => {
            const idx = parseInt(e.currentTarget.dataset.up);
            if (idx > 0) { pushUndo(); [steps[idx-1], steps[idx]] = [steps[idx], steps[idx-1]]; refreshStepList(); }
          });
          const downBtn = card.querySelector('[data-down]');
          if (downBtn) downBtn.addEventListener('click', (e) => {
            const idx = parseInt(e.currentTarget.dataset.down);
            if (idx < steps.length - 1) { pushUndo(); [steps[idx], steps[idx+1]] = [steps[idx+1], steps[idx]]; refreshStepList(); }
          });
        });
      }

      document.getElementById('addStepSelect').addEventListener('change', (e) => {
        if (!e.target.value) return;
        pushUndo();
        const defaults = {
          fill: { tile: 1 }, noise: { density: 0.45, tile: 0 },
          cellular: { iterations: 5, birthLimit: 4, deathLimit: 3 },
          rooms: { count: 6, minSize: 4, maxSize: 10 }, corridors: {}, border: {},
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
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('g', () => generate());

      // ── Export ─────────────────────────────────────────
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Procedural Map Generator', '-- Usage: local map = lurek.procgen.generate(config)', ''];
        lines.push('return {');
        lines.push('  width = ' + mapW + ',');
        lines.push('  height = ' + mapH + ',');
        lines.push('  seed = ' + seed + ',');
        lines.push('  steps = {');
        for (const s of steps) {
          let line = '    { type = "' + s.type + '"';
          for (const [k, v] of Object.entries(s.params)) line += ', ' + k + ' = ' + v;
          line += ' },';
          lines.push(line);
        }
        lines.push('  },');
        lines.push('  data = {');
        for (let y = 0; y < mapH; y++) {
          lines.push('    ' + mapData.slice(y * mapW, (y + 1) * mapW).join(', ') + ',');
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
      refreshStepList();
      window.addEventListener('resize', () => renderMap());
      generate();
    `);
  }
}
