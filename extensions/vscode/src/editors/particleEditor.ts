import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class ParticleEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): ParticleEditor {
    return new ParticleEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "luna.editor.particle", "Particle Designer");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "particles.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Particle Designer", `
      .editor-layout {
        display: grid; grid-template-columns: 180px 1fr 240px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .preset-panel { grid-row: 2; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: #111; }
      .params-panel { grid-row: 2; border-left: 1px solid var(--border); padding: 8px; overflow-y: auto; background: var(--surface); }
      .status-bar { grid-column: 1 / -1; }
      .preset-item { padding: 6px 8px; cursor: pointer; border-radius: 3px; font-size: 12px; }
      .preset-item:hover { background: var(--surface-2); }
      .preset-item.selected { background: var(--selection); }
      .slider-row { display: flex; align-items: center; gap: 6px; margin-bottom: 4px; }
      .slider-row label { font-size: 11px; width: 70px; color: var(--text-dim); }
      .slider-row input[type=range] { flex: 1; }
      .slider-row .val { font-size: 11px; width: 40px; text-align: right; }
      .color-row { display: flex; align-items: center; gap: 6px; margin-bottom: 4px; }
      .color-row label { font-size: 11px; width: 70px; color: var(--text-dim); }
      .color-row input[type=color] { width: 32px; height: 24px; border: none; background: none; cursor: pointer; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnReset">Reset</button>
          <button id="btnPause">Pause</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="panel preset-panel">
          <h3>Presets</h3>
          <div id="presetList"></div>
        </div>
        <div class="canvas-area"><canvas id="particleCanvas"></canvas></div>
        <div class="params-panel">
          <h3>Parameters</h3>
          <div id="paramControls"></div>
          <h3 style="margin-top: 12px;">Colors</h3>
          <div id="colorControls"></div>
        </div>
        <div class="status-bar">
          <span id="statusParticles">Particles: 0</span>
          <span id="statusFps">FPS: 60</span>
        </div>
      </div>
    `, `
      const canvas = document.getElementById('particleCanvas');
      const ctx = canvas.getContext('2d');
      let paused = false;

      const PRESETS = {
        Fire: { max: 200, rate: 40, speed: 80, lifetime: 1.0, direction: -90, spread: 30, sizeMin: 2, sizeMax: 6, gravityX: 0, gravityY: -20, colorStart: '#ff4400', colorMid: '#ff8800', colorEnd: '#ffcc00' },
        Smoke: { max: 100, rate: 15, speed: 30, lifetime: 2.0, direction: -90, spread: 20, sizeMin: 4, sizeMax: 12, gravityX: 0, gravityY: -10, colorStart: '#666666', colorMid: '#888888', colorEnd: '#aaaaaa' },
        Sparks: { max: 150, rate: 50, speed: 200, lifetime: 0.5, direction: -90, spread: 180, sizeMin: 1, sizeMax: 3, gravityX: 0, gravityY: 100, colorStart: '#ffee00', colorMid: '#ff8800', colorEnd: '#ff4400' },
        Snow: { max: 300, rate: 20, speed: 40, lifetime: 4.0, direction: 90, spread: 40, sizeMin: 2, sizeMax: 4, gravityX: 10, gravityY: 20, colorStart: '#ffffff', colorMid: '#ddddff', colorEnd: '#bbbbff' },
        Rain: { max: 400, rate: 80, speed: 300, lifetime: 1.0, direction: 100, spread: 5, sizeMin: 1, sizeMax: 2, gravityX: 0, gravityY: 200, colorStart: '#6699cc', colorMid: '#4488bb', colorEnd: '#336699' },
        Burst: { max: 100, rate: 100, speed: 150, lifetime: 0.8, direction: 0, spread: 180, sizeMin: 2, sizeMax: 5, gravityX: 0, gravityY: 50, colorStart: '#ff0055', colorMid: '#ff44aa', colorEnd: '#ffaaff' },
        Magic: { max: 80, rate: 10, speed: 50, lifetime: 1.5, direction: -90, spread: 360, sizeMin: 2, sizeMax: 5, gravityX: 0, gravityY: -5, colorStart: '#aa44ff', colorMid: '#4488ff', colorEnd: '#44ffaa' },
        Hearts: { max: 30, rate: 5, speed: 40, lifetime: 2.0, direction: -90, spread: 30, sizeMin: 4, sizeMax: 8, gravityX: 0, gravityY: -15, colorStart: '#ff2266', colorMid: '#ff6699', colorEnd: '#ffaacc' },
        Confetti: { max: 200, rate: 30, speed: 120, lifetime: 2.0, direction: -60, spread: 120, sizeMin: 3, sizeMax: 6, gravityX: 0, gravityY: 80, colorStart: '#ff4444', colorMid: '#44ff44', colorEnd: '#4444ff' },
        Firefly: { max: 40, rate: 3, speed: 20, lifetime: 3.0, direction: 0, spread: 360, sizeMin: 2, sizeMax: 4, gravityX: 0, gravityY: -5, colorStart: '#aaff44', colorMid: '#88cc22', colorEnd: '#446600' },
        Bubbles: { max: 60, rate: 8, speed: 30, lifetime: 3.0, direction: -90, spread: 20, sizeMin: 3, sizeMax: 8, gravityX: 0, gravityY: -20, colorStart: '#88ccff', colorMid: '#aaddff', colorEnd: '#cceeff' },
        Dust: { max: 80, rate: 10, speed: 15, lifetime: 2.5, direction: 0, spread: 360, sizeMin: 1, sizeMax: 3, gravityX: 5, gravityY: -2, colorStart: '#aa9977', colorMid: '#886644', colorEnd: '#664422' }
      };

      let cfg = { ...PRESETS.Fire };
      let particles = [];
      let emitAccum = 0;

      const PARAM_DEFS = [
        { key: 'max', label: 'Max', min: 1, max: 1000, step: 1 },
        { key: 'rate', label: 'Rate', min: 1, max: 200, step: 1 },
        { key: 'speed', label: 'Speed', min: 1, max: 500, step: 1 },
        { key: 'lifetime', label: 'Lifetime', min: 0.1, max: 10, step: 0.1 },
        { key: 'direction', label: 'Direction', min: -180, max: 180, step: 1 },
        { key: 'spread', label: 'Spread', min: 0, max: 360, step: 1 },
        { key: 'sizeMin', label: 'Size Min', min: 1, max: 20, step: 1 },
        { key: 'sizeMax', label: 'Size Max', min: 1, max: 40, step: 1 },
        { key: 'gravityX', label: 'Gravity X', min: -200, max: 200, step: 1 },
        { key: 'gravityY', label: 'Gravity Y', min: -200, max: 200, step: 1 },
      ];

      function buildControls() {
        const el = document.getElementById('paramControls');
        el.innerHTML = '';
        for (const p of PARAM_DEFS) {
          const row = document.createElement('div');
          row.className = 'slider-row';
          row.innerHTML = '<label>' + p.label + '</label><input type="range" min="' + p.min + '" max="' + p.max + '" step="' + p.step + '" value="' + cfg[p.key] + '" data-key="' + p.key + '"><span class="val">' + cfg[p.key] + '</span>';
          el.appendChild(row);
          row.querySelector('input').addEventListener('input', (e) => {
            cfg[p.key] = parseFloat(e.target.value);
            row.querySelector('.val').textContent = e.target.value;
          });
        }
        const cel = document.getElementById('colorControls');
        cel.innerHTML = '';
        for (const ck of ['colorStart', 'colorMid', 'colorEnd']) {
          const row = document.createElement('div');
          row.className = 'color-row';
          const label = ck.replace('color', '');
          row.innerHTML = '<label>' + label + '</label><input type="color" value="' + cfg[ck] + '" data-key="' + ck + '">';
          cel.appendChild(row);
          row.querySelector('input').addEventListener('input', (e) => { cfg[ck] = e.target.value; });
        }
      }

      // Presets list
      const presetList = document.getElementById('presetList');
      let activePreset = 'Fire';
      for (const name of Object.keys(PRESETS)) {
        const div = document.createElement('div');
        div.className = 'preset-item' + (name === activePreset ? ' selected' : '');
        div.textContent = name;
        div.addEventListener('click', () => {
          activePreset = name;
          cfg = { ...PRESETS[name] };
          particles = []; emitAccum = 0;
          presetList.querySelectorAll('.preset-item').forEach(d => d.classList.remove('selected'));
          div.classList.add('selected');
          buildControls();
        });
        presetList.appendChild(div);
      }

      function hexToRgb(hex) {
        const r = parseInt(hex.slice(1,3), 16), g = parseInt(hex.slice(3,5), 16), b = parseInt(hex.slice(5,7), 16);
        return { r, g, b };
      }

      function lerpColor(c1, c2, t) {
        const a = hexToRgb(c1), b = hexToRgb(c2);
        const r = Math.round(a.r + (b.r - a.r) * t);
        const g = Math.round(a.g + (b.g - a.g) * t);
        const bl = Math.round(a.b + (b.b - a.b) * t);
        return 'rgb(' + r + ',' + g + ',' + bl + ')';
      }

      function emitParticle(cx, cy) {
        const angle = (cfg.direction + (Math.random() - 0.5) * cfg.spread) * Math.PI / 180;
        const speed = cfg.speed * (0.8 + Math.random() * 0.4);
        particles.push({
          x: cx, y: cy, vx: Math.cos(angle) * speed, vy: Math.sin(angle) * speed,
          life: 0, maxLife: cfg.lifetime * (0.8 + Math.random() * 0.4),
          size: cfg.sizeMin + Math.random() * (cfg.sizeMax - cfg.sizeMin)
        });
      }

      let lastTime = performance.now();
      let frameCount = 0, fpsTimer = 0;

      function update() {
        if (paused) { requestAnimationFrame(update); return; }
        const now = performance.now();
        const dt = Math.min((now - lastTime) / 1000, 0.05);
        lastTime = now;

        frameCount++; fpsTimer += dt;
        if (fpsTimer >= 1) {
          document.getElementById('statusFps').textContent = 'FPS: ' + frameCount;
          frameCount = 0; fpsTimer = 0;
        }

        const cx = canvas.width / 2, cy = canvas.height / 2;

        // Emit
        emitAccum += cfg.rate * dt;
        while (emitAccum >= 1 && particles.length < cfg.max) {
          emitParticle(cx, cy); emitAccum--;
        }

        // Update particles
        for (let i = particles.length - 1; i >= 0; i--) {
          const p = particles[i];
          p.vx += cfg.gravityX * dt; p.vy += cfg.gravityY * dt;
          p.x += p.vx * dt; p.y += p.vy * dt;
          p.life += dt;
          if (p.life >= p.maxLife) { particles.splice(i, 1); }
        }

        // Render
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        for (const p of particles) {
          const t = p.life / p.maxLife;
          const color = t < 0.5 ? lerpColor(cfg.colorStart, cfg.colorMid, t * 2) : lerpColor(cfg.colorMid, cfg.colorEnd, (t - 0.5) * 2);
          const alpha = 1 - t;
          ctx.globalAlpha = alpha;
          ctx.fillStyle = color;
          ctx.beginPath();
          ctx.arc(p.x, p.y, p.size * (1 - t * 0.3), 0, Math.PI * 2);
          ctx.fill();
        }
        ctx.globalAlpha = 1;

        document.getElementById('statusParticles').textContent = 'Particles: ' + particles.length;
        requestAnimationFrame(update);
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight;
      }

      document.getElementById('btnPause').addEventListener('click', () => {
        paused = !paused;
        document.getElementById('btnPause').textContent = paused ? 'Resume' : 'Pause';
      });
      document.getElementById('btnReset').addEventListener('click', () => { particles = []; emitAccum = 0; });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        lua += '  max = ' + cfg.max + ',\\n  rate = ' + cfg.rate + ',\\n';
        lua += '  speed = ' + cfg.speed + ',\\n  lifetime = ' + cfg.lifetime + ',\\n';
        lua += '  direction = ' + cfg.direction + ',\\n  spread = ' + cfg.spread + ',\\n';
        lua += '  sizeMin = ' + cfg.sizeMin + ',\\n  sizeMax = ' + cfg.sizeMax + ',\\n';
        lua += '  gravity = { x = ' + cfg.gravityX + ', y = ' + cfg.gravityY + ' },\\n';
        lua += '  colors = {\\n';
        lua += '    start = "' + cfg.colorStart + '",\\n';
        lua += '    mid = "' + cfg.colorMid + '",\\n';
        lua += '    finish = "' + cfg.colorEnd + '"\\n';
        lua += '  }\\n}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      buildControls();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
      requestAnimationFrame(update);
    `);
  }
}
