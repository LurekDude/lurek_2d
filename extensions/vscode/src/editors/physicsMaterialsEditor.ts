import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

export class PhysicsMaterialsEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): PhysicsMaterialsEditor {
    return new PhysicsMaterialsEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.physicsMaterialsEditor", "Physics Materials");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "physics_materials.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Physics Materials", `
      .editor-layout {
        display: grid; grid-template-columns: 160px 1fr 200px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .material-list { grid-row: 2; border-right: 1px solid var(--border); overflow-y: auto; background: var(--surface); }
      .preview-area { grid-row: 2; display: flex; flex-direction: column; overflow: hidden; }
      .props-panel { grid-row: 2; overflow-y: auto; border-left: 1px solid var(--border); background: var(--surface); padding: 6px; }
      .mat-item {
        display: flex; align-items: center; gap: 4px; padding: 4px 6px;
        cursor: pointer; font-size: 11px; border-bottom: 1px solid var(--border);
        transition: background 0.08s;
      }
      .mat-item:hover { background: var(--hover); }
      .mat-item.sel { background: var(--selection); }
      .mat-color { width: 12px; height: 12px; border-radius: 50%; border: 1px solid var(--border); flex-shrink: 0; }
      .canvas-section { flex: 1; display: flex; align-items: center; justify-content: center; background: var(--bg); }
      .matrix-section { border-top: 1px solid var(--border); padding: 8px; background: var(--surface); overflow: auto; }
      .matrix-table { border-collapse: collapse; font-size: 9px; }
      .matrix-table th { padding: 3px; background: var(--surface-2); border: 1px solid var(--border); writing-mode: vertical-lr; text-orientation: mixed; max-width: 24px; }
      .matrix-table td { padding: 0; border: 1px solid var(--border); text-align: center; }
      .matrix-cell { width: 20px; height: 20px; cursor: pointer; display: flex; align-items: center; justify-content: center; }
      .matrix-cell.on { background: var(--accent); color: var(--bg); }
      .matrix-cell.off { background: var(--surface-2); color: var(--text-dim); }
      .slider-row { display: flex; align-items: center; gap: 4px; margin-bottom: 4px; }
      .slider-row input[type="range"] { flex: 1; }
      .slider-row .val { font-family: var(--font-mono,monospace); font-size: 10px; min-width: 32px; text-align: right; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${iconButton(ICONS.add, 'btnAdd', 'Add Material')}
            <button id="btnDuplicate" style="font-size:10px;padding:2px 6px">Dup</button>
            ${iconButton(ICONS.trash, 'btnRemove', 'Remove')}
          </div>
          ${toolbarSep()}
          <div class="group">
            <button id="btnPresets" style="font-size:10px;padding:2px 6px">Presets</button>
          </div>
          ${toolbarSpacer()}
          ${iconButton(ICONS.save, 'btnExport', 'Export Lua')}
        </div>

        <div class="material-list" id="materialList"></div>

        <div class="preview-area">
          <div class="canvas-section">
            <canvas id="previewCanvas" width="360" height="260"></canvas>
          </div>
          <div class="matrix-section">
            <div style="font-size:10px;text-transform:uppercase;color:var(--text-dim);margin-bottom:4px;font-weight:600">Collision Matrix</div>
            <table class="matrix-table" id="collisionMatrix"></table>
          </div>
        </div>

        <div class="props-panel">
          ${panelSection('Material', `
            ${fieldInline('Name', '<input type="text" id="matName" style="width:100%">')}
            ${fieldInline('Color', '<input type="color" id="matColor" value="#89b4fa">')}
          `)}
          ${panelSection('Physics', `
            <div class="slider-row"><label style="font-size:10px;min-width:60px">Friction</label><input type="range" id="friction" min="0" max="100" value="50"><span class="val" id="frictionVal">0.50</span></div>
            <div class="slider-row"><label style="font-size:10px;min-width:60px">Bounce</label><input type="range" id="restitution" min="0" max="100" value="30"><span class="val" id="restitutionVal">0.30</span></div>
            <div class="slider-row"><label style="font-size:10px;min-width:60px">Density</label><input type="range" id="density" min="1" max="200" value="10"><span class="val" id="densityVal">1.0</span></div>
          `)}
          ${panelSection('Collision Layer', `
            <select id="collisionLayer" style="width:100%;font-size:10px">
              <option value="0">Layer 0 (Default)</option>
              <option value="1">Layer 1</option>
              <option value="2">Layer 2</option>
              <option value="3">Layer 3</option>
              <option value="4">Layer 4</option>
              <option value="5">Layer 5</option>
              <option value="6">Layer 6</option>
              <option value="7">Layer 7</option>
            </select>
          `)}
        </div>

        <div class="status-bar">
          <span id="statusMat" class="badge">Default</span>
          <div class="sep"></div>
          <span id="statusCount">5 materials</span>
          <div class="sep"></div>
          <span id="statusLayers">8 layers</span>
          <div class="spacer"></div>
          <span id="statusDirty" style="font-size:10px;color:var(--text-dim)">${ICONS.clean}</span>
        </div>
      </div>
    `, `
      const undo = new UndoStack();
      let materials = [
        { name: 'Default', friction: 0.5, restitution: 0.3, density: 1.0, layer: 0, color: '#858585' },
        { name: 'Ice', friction: 0.05, restitution: 0.1, density: 0.9, layer: 0, color: '#80d4ff' },
        { name: 'Rubber', friction: 0.9, restitution: 0.8, density: 1.2, layer: 0, color: '#e06040' },
        { name: 'Metal', friction: 0.3, restitution: 0.2, density: 7.8, layer: 1, color: '#a0a0a0' },
        { name: 'Wood', friction: 0.6, restitution: 0.4, density: 0.6, layer: 0, color: '#b07040' },
      ];
      let selMat = 0;
      const NUM_LAYERS = 8;
      let collisionMatrix = [];
      for (let i = 0; i < NUM_LAYERS; i++) collisionMatrix[i] = new Array(NUM_LAYERS).fill(true);

      const canvas = document.getElementById('previewCanvas');
      const ctx = canvas.getContext('2d');
      let ballX = 180, ballY = 40, ballVY = 0, ballVX = 1;
      const GRAVITY = 0.3, FLOOR_Y = 220;

      function snap() { return JSON.parse(JSON.stringify({ materials, collisionMatrix })); }
      function loadSnap(s) { materials = s.materials; collisionMatrix = s.collisionMatrix; build(); updateProps(); }
      function push() { undo.push(snap()); markDirty(); }
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) loadSnap(s); });
      registerShortcut('ctrl+shift+z', () => { const s = undo.redo(); if (s) loadSnap(s); });
      registerShortcut('ctrl+s', () => document.getElementById('btnExport').click());

      function build() {
        const list = document.getElementById('materialList'); list.innerHTML = '';
        materials.forEach((mat, i) => {
          const el = document.createElement('div');
          el.className = 'mat-item' + (i === selMat ? ' sel' : '');
          el.innerHTML = '<div class="mat-color" style="background:' + mat.color + '"></div><span>' + mat.name + '</span>';
          el.addEventListener('click', () => { selMat = i; build(); updateProps(); resetBall(); });
          list.appendChild(el);
        });
        renderMatrix();
        document.getElementById('statusCount').textContent = materials.length + ' materials';
        document.getElementById('statusMat').textContent = materials[selMat]?.name || 'none';
      }

      function updateProps() {
        const mat = materials[selMat]; if (!mat) return;
        document.getElementById('matName').value = mat.name;
        document.getElementById('matColor').value = mat.color;
        document.getElementById('friction').value = Math.round(mat.friction * 100);
        document.getElementById('frictionVal').textContent = mat.friction.toFixed(2);
        document.getElementById('restitution').value = Math.round(mat.restitution * 100);
        document.getElementById('restitutionVal').textContent = mat.restitution.toFixed(2);
        document.getElementById('density').value = Math.round(mat.density * 10);
        document.getElementById('densityVal').textContent = mat.density.toFixed(1);
        document.getElementById('collisionLayer').value = mat.layer;
      }

      function renderMatrix() {
        const table = document.getElementById('collisionMatrix'); table.innerHTML = '';
        const hRow = document.createElement('tr'); hRow.innerHTML = '<th></th>';
        for (let i = 0; i < NUM_LAYERS; i++) hRow.innerHTML += '<th>L' + i + '</th>';
        table.appendChild(hRow);
        for (let r = 0; r < NUM_LAYERS; r++) {
          const row = document.createElement('tr'); row.innerHTML = '<th>L' + r + '</th>';
          for (let c = 0; c < NUM_LAYERS; c++) {
            const td = document.createElement('td'), cell = document.createElement('div');
            const on = collisionMatrix[r][c];
            cell.className = 'matrix-cell ' + (on ? 'on' : 'off');
            cell.textContent = on ? '\\u2713' : '';
            cell.addEventListener('click', () => { push(); collisionMatrix[r][c] = !collisionMatrix[r][c]; collisionMatrix[c][r] = collisionMatrix[r][c]; renderMatrix(); });
            td.appendChild(cell); row.appendChild(td);
          }
          table.appendChild(row);
        }
      }

      function resetBall() { ballX = 180; ballY = 40; ballVY = 0; ballVX = 1; }

      function animatePreview() {
        const bgCol = getComputedStyle(document.documentElement).getPropertyValue('--bg').trim() || '#1e1e1e';
        const textCol = getComputedStyle(document.documentElement).getPropertyValue('--text-dim').trim() || '#858585';
        const borderCol = getComputedStyle(document.documentElement).getPropertyValue('--border').trim() || '#3c3c3c';
        ctx.fillStyle = bgCol; ctx.fillRect(0, 0, canvas.width, canvas.height);
        const mat = materials[selMat];
        if (!mat) { requestAnimationFrame(animatePreview); return; }
        ctx.fillStyle = borderCol; ctx.fillRect(0, FLOOR_Y, canvas.width, canvas.height - FLOOR_Y);
        ctx.fillStyle = textCol; ctx.font = '10px sans-serif';
        ctx.fillText('friction: ' + mat.friction.toFixed(2) + '  bounce: ' + mat.restitution.toFixed(2) + '  density: ' + mat.density.toFixed(1), 8, FLOOR_Y + 16);
        ballVY += GRAVITY; ballY += ballVY; ballX += ballVX;
        const radius = 10 + mat.density * 2;
        if (ballY + radius >= FLOOR_Y) { ballY = FLOOR_Y - radius; ballVY = -ballVY * mat.restitution; ballVX *= (1 - mat.friction * 0.1); if (Math.abs(ballVY) < 0.5) ballVY = 0; }
        if (ballX + radius >= canvas.width || ballX - radius <= 0) { ballVX = -ballVX * 0.9; ballX = Math.max(radius, Math.min(canvas.width - radius, ballX)); }
        ctx.beginPath(); ctx.arc(ballX, ballY, radius, 0, Math.PI * 2);
        ctx.fillStyle = mat.color; ctx.fill(); ctx.strokeStyle = textCol; ctx.lineWidth = 1; ctx.stroke();
        ctx.fillStyle = textCol; ctx.font = '10px sans-serif'; ctx.textAlign = 'center';
        ctx.fillText(mat.name, ballX, ballY - radius - 4); ctx.textAlign = 'left';
        requestAnimationFrame(animatePreview);
      }

      document.getElementById('matName').addEventListener('change', e => { if (materials[selMat]) { push(); materials[selMat].name = e.target.value; build(); } });
      document.getElementById('matColor').addEventListener('input', e => { if (materials[selMat]) { push(); materials[selMat].color = e.target.value; build(); } });
      document.getElementById('friction').addEventListener('input', e => { const v = parseInt(e.target.value)/100; document.getElementById('frictionVal').textContent = v.toFixed(2); if (materials[selMat]) materials[selMat].friction = v; });
      document.getElementById('restitution').addEventListener('input', e => { const v = parseInt(e.target.value)/100; document.getElementById('restitutionVal').textContent = v.toFixed(2); if (materials[selMat]) { materials[selMat].restitution = v; resetBall(); } });
      document.getElementById('density').addEventListener('input', e => { const v = parseInt(e.target.value)/10; document.getElementById('densityVal').textContent = v.toFixed(1); if (materials[selMat]) { materials[selMat].density = v; resetBall(); } });
      document.getElementById('collisionLayer').addEventListener('change', e => { if (materials[selMat]) { push(); materials[selMat].layer = parseInt(e.target.value); } });

      document.getElementById('btnAdd').addEventListener('click', () => { push(); materials.push({ name: 'New Material', friction: 0.5, restitution: 0.3, density: 1.0, layer: 0, color: '#888888' }); selMat = materials.length - 1; build(); updateProps(); resetBall(); });
      document.getElementById('btnDuplicate').addEventListener('click', () => { const src = materials[selMat]; if (src) { push(); materials.push({ ...src, name: src.name + ' Copy' }); selMat = materials.length - 1; build(); updateProps(); } });
      document.getElementById('btnRemove').addEventListener('click', () => { if (materials.length > 1) { push(); materials.splice(selMat, 1); selMat = Math.min(selMat, materials.length - 1); build(); updateProps(); resetBall(); } });
      document.getElementById('btnPresets').addEventListener('click', () => {
        push();
        materials = [
          { name:'Default', friction:0.5, restitution:0.3, density:1.0, layer:0, color:'#858585' },
          { name:'Ice', friction:0.05, restitution:0.1, density:0.9, layer:0, color:'#80d4ff' },
          { name:'Rubber', friction:0.9, restitution:0.8, density:1.2, layer:0, color:'#e06040' },
          { name:'Metal', friction:0.3, restitution:0.2, density:7.8, layer:1, color:'#a0a0a0' },
          { name:'Wood', friction:0.6, restitution:0.4, density:0.6, layer:0, color:'#b07040' },
          { name:'Bouncy Ball', friction:0.4, restitution:0.95, density:0.5, layer:0, color:'#ff6090' },
          { name:'Stone', friction:0.7, restitution:0.1, density:2.5, layer:1, color:'#707070' },
        ];
        selMat = 0; build(); updateProps(); resetBall();
      });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  materials = {\\n';
        materials.forEach(m => { lua += '    { name = "' + m.name + '", friction = ' + m.friction.toFixed(2) + ', restitution = ' + m.restitution.toFixed(2) + ', density = ' + m.density.toFixed(1) + ', layer = ' + m.layer + ' },\\n'; });
        lua += '  },\\n  collision_matrix = {\\n';
        for (let r = 0; r < NUM_LAYERS; r++) lua += '    {' + collisionMatrix[r].map(v => v ? 'true' : 'false').join(', ') + '},\\n';
        lua += '  }\\n}'; vscode.postMessage({ type: 'exportLua', content: lua });
      });

      build(); updateProps(); animatePreview();
    `);
  }
}
