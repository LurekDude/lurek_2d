import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

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
        display: grid; grid-template-columns: 200px 1fr 240px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .material-list { grid-row: 2; }
      .preview-area { grid-row: 2; display: flex; flex-direction: column; }
      .props-panel { grid-row: 2; }
      .status-bar { grid-column: 1 / -1; }
      .mat-item {
        display: flex; align-items: center; gap: 6px; padding: 6px 8px;
        cursor: pointer; border-radius: 3px; font-size: 12px; border-bottom: 1px solid var(--border);
      }
      .mat-item:hover { background: var(--surface-2); }
      .mat-item.selected { background: var(--selection); }
      .mat-color {
        width: 14px; height: 14px; border-radius: 50%; border: 1px solid var(--border); flex-shrink: 0;
      }
      .canvas-section { flex: 1; display: flex; align-items: center; justify-content: center; background: var(--bg); }
      .matrix-section {
        border-top: 1px solid var(--border); padding: 10px; background: var(--surface); overflow: auto;
      }
      .matrix-table { border-collapse: collapse; font-size: 10px; }
      .matrix-table th {
        padding: 4px; background: var(--surface-2); border: 1px solid var(--border);
        writing-mode: vertical-lr; text-orientation: mixed; max-width: 30px;
      }
      .matrix-table td { padding: 0; border: 1px solid var(--border); text-align: center; }
      .matrix-cell {
        width: 24px; height: 24px; cursor: pointer; display: flex;
        align-items: center; justify-content: center;
      }
      .matrix-cell.on { background: var(--accent); color: #fff; }
      .matrix-cell.off { background: var(--surface-2); color: var(--text-dim); }
      .slider-labeled { display: flex; flex-direction: column; gap: 2px; margin-bottom: 8px; }
      .slider-labeled .row { display: flex; align-items: center; gap: 6px; }
      .slider-labeled input[type="range"] { flex: 1; }
      .slider-labeled .val { font-family: monospace; font-size: 11px; min-width: 36px; text-align: right; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAdd">+ Material</button>
          <button id="btnDuplicate">Duplicate</button>
          <button id="btnRemove" class="danger">Remove</button>
          <div class="sep"></div>
          <button id="btnPresets">Load Presets</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>

        <div class="panel material-list" id="materialList"></div>

        <div class="preview-area">
          <div class="canvas-section">
            <canvas id="previewCanvas" width="360" height="260"></canvas>
          </div>
          <div class="matrix-section">
            <h3 style="font-size:11px;text-transform:uppercase;color:var(--text-dim);margin-bottom:6px;">Collision Matrix</h3>
            <table class="matrix-table" id="collisionMatrix"></table>
          </div>
        </div>

        <div class="panel props-panel">
          <div class="section">
            <h3>Material Properties</h3>
            <div class="field"><label>Name</label><input type="text" id="matName" style="width:100%"></div>
            <div class="field"><label>Color</label><input type="color" id="matColor" value="#007acc"></div>
          </div>
          <div class="section">
            <div class="slider-labeled">
              <label>Friction</label>
              <div class="row"><input type="range" id="friction" min="0" max="100" value="50"><span class="val" id="frictionVal">0.50</span></div>
            </div>
            <div class="slider-labeled">
              <label>Restitution (bounciness)</label>
              <div class="row"><input type="range" id="restitution" min="0" max="100" value="30"><span class="val" id="restitutionVal">0.30</span></div>
            </div>
            <div class="slider-labeled">
              <label>Density</label>
              <div class="row"><input type="range" id="density" min="1" max="200" value="10"><span class="val" id="densityVal">1.0</span></div>
            </div>
          </div>
          <div class="section">
            <h3>Collision Layer</h3>
            <div class="field">
              <label>Layer</label>
              <select id="collisionLayer" style="width:100%;">
                <option value="0">Layer 0 (Default)</option>
                <option value="1">Layer 1</option>
                <option value="2">Layer 2</option>
                <option value="3">Layer 3</option>
                <option value="4">Layer 4</option>
                <option value="5">Layer 5</option>
                <option value="6">Layer 6</option>
                <option value="7">Layer 7</option>
              </select>
            </div>
          </div>
        </div>

        <div class="status-bar">
          <span id="statusMat">Material: none</span>
          <span id="statusCount">Materials: 0</span>
          <span id="statusLayers">Layers: 8</span>
        </div>
      </div>
    `, `
      let materials = [
        { name: 'Default', friction: 0.5, restitution: 0.3, density: 1.0, layer: 0, color: '#858585' },
        { name: 'Ice', friction: 0.05, restitution: 0.1, density: 0.9, layer: 0, color: '#80d4ff' },
        { name: 'Rubber', friction: 0.9, restitution: 0.8, density: 1.2, layer: 0, color: '#e06040' },
        { name: 'Metal', friction: 0.3, restitution: 0.2, density: 7.8, layer: 1, color: '#a0a0a0' },
        { name: 'Wood', friction: 0.6, restitution: 0.4, density: 0.6, layer: 0, color: '#b07040' },
      ];
      let selectedMat = 0;
      const NUM_LAYERS = 8;
      let collisionMatrix = [];
      for (let i = 0; i < NUM_LAYERS; i++) {
        collisionMatrix[i] = new Array(NUM_LAYERS).fill(true);
      }

      const canvas = document.getElementById('previewCanvas');
      const ctx = canvas.getContext('2d');
      let ballX = 180, ballY = 40, ballVY = 0, ballVX = 0;
      const GRAVITY = 0.3;
      const FLOOR_Y = 220;
      let animId = null;

      function render() {
        const list = document.getElementById('materialList');
        list.innerHTML = '';
        materials.forEach((mat, i) => {
          const el = document.createElement('div');
          el.className = 'mat-item' + (i === selectedMat ? ' selected' : '');
          el.innerHTML = '<div class="mat-color" style="background:' + mat.color + '"></div><span>' + mat.name + '</span>';
          el.addEventListener('click', () => { selectedMat = i; render(); updateProps(); resetBall(); });
          list.appendChild(el);
        });
        renderMatrix();
        document.getElementById('statusCount').textContent = 'Materials: ' + materials.length;
        document.getElementById('statusMat').textContent = 'Material: ' + (materials[selectedMat]?.name || 'none');
      }

      function updateProps() {
        const mat = materials[selectedMat];
        if (!mat) return;
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
        const table = document.getElementById('collisionMatrix');
        table.innerHTML = '';
        const headerRow = document.createElement('tr');
        headerRow.innerHTML = '<th></th>';
        for (let i = 0; i < NUM_LAYERS; i++) { headerRow.innerHTML += '<th>L' + i + '</th>'; }
        table.appendChild(headerRow);
        for (let r = 0; r < NUM_LAYERS; r++) {
          const row = document.createElement('tr');
          row.innerHTML = '<th>L' + r + '</th>';
          for (let c = 0; c < NUM_LAYERS; c++) {
            const td = document.createElement('td');
            const cell = document.createElement('div');
            const on = collisionMatrix[r][c];
            cell.className = 'matrix-cell ' + (on ? 'on' : 'off');
            cell.textContent = on ? '\\u2713' : '';
            cell.addEventListener('click', () => {
              collisionMatrix[r][c] = !collisionMatrix[r][c];
              collisionMatrix[c][r] = collisionMatrix[r][c]; // symmetric
              renderMatrix();
            });
            td.appendChild(cell);
            row.appendChild(td);
          }
          table.appendChild(row);
        }
      }

      function resetBall() {
        ballX = 180; ballY = 40; ballVY = 0; ballVX = 1;
      }

      function animatePreview() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        const mat = materials[selectedMat];
        if (!mat) { animId = requestAnimationFrame(animatePreview); return; }

        // Floor
        ctx.fillStyle = '#333';
        ctx.fillRect(0, FLOOR_Y, canvas.width, canvas.height - FLOOR_Y);
        ctx.fillStyle = '#555';
        ctx.fillText('friction: ' + mat.friction.toFixed(2) + '  restitution: ' + mat.restitution.toFixed(2) + '  density: ' + mat.density.toFixed(1), 10, FLOOR_Y + 20);

        // Ball physics
        ballVY += GRAVITY;
        ballY += ballVY;
        ballX += ballVX;

        const radius = 10 + mat.density * 2;

        if (ballY + radius >= FLOOR_Y) {
          ballY = FLOOR_Y - radius;
          ballVY = -ballVY * mat.restitution;
          ballVX *= (1 - mat.friction * 0.1);
          if (Math.abs(ballVY) < 0.5) ballVY = 0;
        }

        if (ballX + radius >= canvas.width || ballX - radius <= 0) {
          ballVX = -ballVX * 0.9;
          ballX = Math.max(radius, Math.min(canvas.width - radius, ballX));
        }

        // Draw ball
        ctx.beginPath();
        ctx.arc(ballX, ballY, radius, 0, Math.PI * 2);
        ctx.fillStyle = mat.color;
        ctx.fill();
        ctx.strokeStyle = '#fff';
        ctx.lineWidth = 1;
        ctx.stroke();

        // Label
        ctx.fillStyle = '#fff';
        ctx.font = '11px sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText(mat.name, ballX, ballY - radius - 6);

        animId = requestAnimationFrame(animatePreview);
      }

      document.getElementById('matName').addEventListener('change', (e) => {
        if (materials[selectedMat]) { materials[selectedMat].name = e.target.value; render(); }
      });
      document.getElementById('matColor').addEventListener('input', (e) => {
        if (materials[selectedMat]) { materials[selectedMat].color = e.target.value; render(); }
      });
      document.getElementById('friction').addEventListener('input', (e) => {
        const v = parseInt(e.target.value) / 100;
        document.getElementById('frictionVal').textContent = v.toFixed(2);
        if (materials[selectedMat]) materials[selectedMat].friction = v;
      });
      document.getElementById('restitution').addEventListener('input', (e) => {
        const v = parseInt(e.target.value) / 100;
        document.getElementById('restitutionVal').textContent = v.toFixed(2);
        if (materials[selectedMat]) { materials[selectedMat].restitution = v; resetBall(); }
      });
      document.getElementById('density').addEventListener('input', (e) => {
        const v = parseInt(e.target.value) / 10;
        document.getElementById('densityVal').textContent = v.toFixed(1);
        if (materials[selectedMat]) { materials[selectedMat].density = v; resetBall(); }
      });
      document.getElementById('collisionLayer').addEventListener('change', (e) => {
        if (materials[selectedMat]) materials[selectedMat].layer = parseInt(e.target.value);
      });

      document.getElementById('btnAdd').addEventListener('click', () => {
        materials.push({ name: 'New Material', friction: 0.5, restitution: 0.3, density: 1.0, layer: 0, color: '#888888' });
        selectedMat = materials.length - 1;
        render(); updateProps(); resetBall();
      });
      document.getElementById('btnDuplicate').addEventListener('click', () => {
        const src = materials[selectedMat];
        if (src) {
          materials.push({ ...src, name: src.name + ' Copy' });
          selectedMat = materials.length - 1;
          render(); updateProps();
        }
      });
      document.getElementById('btnRemove').addEventListener('click', () => {
        if (materials.length > 1) {
          materials.splice(selectedMat, 1);
          selectedMat = Math.min(selectedMat, materials.length - 1);
          render(); updateProps(); resetBall();
        }
      });

      document.getElementById('btnPresets').addEventListener('click', () => {
        materials = [
          { name:'Default', friction:0.5, restitution:0.3, density:1.0, layer:0, color:'#858585' },
          { name:'Ice', friction:0.05, restitution:0.1, density:0.9, layer:0, color:'#80d4ff' },
          { name:'Rubber', friction:0.9, restitution:0.8, density:1.2, layer:0, color:'#e06040' },
          { name:'Metal', friction:0.3, restitution:0.2, density:7.8, layer:1, color:'#a0a0a0' },
          { name:'Wood', friction:0.6, restitution:0.4, density:0.6, layer:0, color:'#b07040' },
          { name:'Bouncy Ball', friction:0.4, restitution:0.95, density:0.5, layer:0, color:'#ff6090' },
          { name:'Stone', friction:0.7, restitution:0.1, density:2.5, layer:1, color:'#707070' },
        ];
        selectedMat = 0;
        render(); updateProps(); resetBall();
      });

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  materials = {\\n';
        materials.forEach(m => {
          lua += '    { name = "' + m.name + '", friction = ' + m.friction.toFixed(2);
          lua += ', restitution = ' + m.restitution.toFixed(2);
          lua += ', density = ' + m.density.toFixed(1);
          lua += ', layer = ' + m.layer + ' },\\n';
        });
        lua += '  },\\n  collision_matrix = {\\n';
        for (let r = 0; r < NUM_LAYERS; r++) {
          lua += '    {' + collisionMatrix[r].map(v => v ? 'true' : 'false').join(', ') + '},\\n';
        }
        lua += '  }\\n}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      render();
      updateProps();
      animatePreview();
    `);
  }
}
