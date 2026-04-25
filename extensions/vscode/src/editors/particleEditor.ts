import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

export class ParticleEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): ParticleEditor {
    return new ParticleEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.editor.particle", "Particle Designer");
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
      .status-bar { grid-column: 1 / -1; }
      .presets { grid-row: 2; background: var(--surface); border-right: 1px solid var(--border); overflow-y: auto; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: var(--bg); }
      .canvas-area canvas { display: block; }
      .params { grid-row: 2; background: var(--surface); border-left: 1px solid var(--border); overflow-y: auto; }

      .preset-item {
        padding: 6px 10px; cursor: pointer; border-radius: var(--radius); font-size: 12px;
        margin: 1px 4px; display: flex; align-items: center; gap: 6px;
        transition: background 0.08s;
      }
      .preset-item:hover { background: var(--hover); }
      .preset-item.selected { background: var(--selection); }
      .preset-item .dot { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; }

      .slider-row {
        display: grid; grid-template-columns: 70px 1fr 36px; gap: 4px;
        align-items: center; margin-bottom: 3px;
      }
      .slider-row label { font-size: 10px; text-align: right; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.3px; }
      .slider-row input[type=range] { width: 100%; }
      .slider-row .val { font-size: 10px; text-align: right; color: var(--text-dim); font-family: var(--font-mono); }

      .color-row {
        display: grid; grid-template-columns: 70px 28px 1fr; gap: 4px;
        align-items: center; margin-bottom: 4px;
      }
      .color-row label { font-size: 10px; text-align: right; color: var(--text-dim); text-transform: uppercase; }
      .color-row input[type=color] { width: 28px; height: 22px; border: 1px solid var(--border); border-radius: var(--radius); cursor: pointer; padding: 0; background: none; }
      .color-row .hex { font-size: 10px; color: var(--text-dim); font-family: var(--font-mono); }

      .emitter-shape-btns { display: flex; gap: 2px; }
      .emitter-shape-btns button { flex: 1; font-size: 10px; padding: 3px 0; }
    `, `
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            ${iconButton('refresh', { id: 'btnReset', title: 'Reset (R)' })}
            <button id="btnPause">${ICONS.play} Pause</button>
          </div>
          ${toolbarSep()}
          <div class="group">
            <label>BG:</label>
            <select id="bgSelect">
              <option value="dark">Dark</option>
              <option value="black">Black</option>
              <option value="checker">Checker</option>
              <option value="white">White</option>
            </select>
          </div>
          ${toolbarSep()}
          <div class="group">
            <label>Blend:</label>
            <select id="blendSelect">
              <option value="lighter">Additive</option>
              <option value="source-over" selected>Normal</option>
            </select>
          </div>
          ${toolbarSpacer()}
          <div class="group">
            ${iconButton('copy', { id: 'btnCopyLua', title: 'Copy Lua Code' })}
            ${iconButton('insert', { id: 'btnInsert', title: 'Insert to Editor' })}
          </div>
          ${toolbarSep()}
          <button id="btnExport" class="primary">${ICONS.exportFile} Export ▾</button>
        </div>

        <!-- Presets Panel -->
        <div class="presets">
          ${panelSection('Presets', '<div id="presetList"></div>')}
          ${panelSection('Emitter Shape', `
            <div class="emitter-shape-btns">
              <button class="active" data-shape="point">Point</button>
              <button data-shape="line">Line</button>
              <button data-shape="circle">Circle</button>
              <button data-shape="rect">Rect</button>
            </div>
            ${fieldInline('Radius', '<input type="number" id="emitRadius" value="0" min="0" max="200" style="width:50px">')}
          `, true)}
        </div>

        <!-- Canvas -->
        <div class="canvas-area"><canvas id="particleCanvas"></canvas></div>

        <!-- Parameters Panel -->
        <div class="params">
          ${panelSection('Emission', '<div id="emissionParams"></div>')}
          ${panelSection('Motion', '<div id="motionParams"></div>')}
          ${panelSection('Appearance', '<div id="appearanceParams"></div>')}
          ${panelSection('Colors', '<div id="colorControls"></div>')}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusParticles" class="badge">0 particles</span>
          </span>
          <div class="sep"></div>
          <span id="statusPreset">Fire</span>
          <div class="spacer"></div>
          <span id="statusFps">60 FPS</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${ICONS.clean}</span>
        </div>
      </div>
    `, `
      // ── Constants & Presets ─────────────────────────────
      const canvas = document.getElementById('particleCanvas');
      const ctx = canvas.getContext('2d');
      let paused = false, blendMode = 'source-over', bgMode = 'dark';
      let emitterShape = 'point', emitRadius = 0;

      const PRESETS = {
        Fire:     { max:200, rate:40, speed:80, lifetime:1.0, direction:-90, spread:30, sizeMin:2, sizeMax:6, gravityX:0, gravityY:-20, damping:0, spin:0, colorStart:'#ff4400', colorMid:'#ff8800', colorEnd:'#ffcc00' },
        Smoke:    { max:100, rate:15, speed:30, lifetime:2.0, direction:-90, spread:20, sizeMin:4, sizeMax:12, gravityX:0, gravityY:-10, damping:0.02, spin:0.5, colorStart:'#666666', colorMid:'#888888', colorEnd:'#aaaaaa' },
        Sparks:   { max:150, rate:50, speed:200, lifetime:0.5, direction:-90, spread:180, sizeMin:1, sizeMax:3, gravityX:0, gravityY:100, damping:0, spin:0, colorStart:'#ffee00', colorMid:'#ff8800', colorEnd:'#ff4400' },
        Snow:     { max:300, rate:20, speed:40, lifetime:4.0, direction:90, spread:40, sizeMin:2, sizeMax:4, gravityX:10, gravityY:20, damping:0, spin:1, colorStart:'#ffffff', colorMid:'#ddddff', colorEnd:'#bbbbff' },
        Rain:     { max:400, rate:80, speed:300, lifetime:1.0, direction:100, spread:5, sizeMin:1, sizeMax:2, gravityX:0, gravityY:200, damping:0, spin:0, colorStart:'#6699cc', colorMid:'#4488bb', colorEnd:'#336699' },
        Burst:    { max:100, rate:100, speed:150, lifetime:0.8, direction:0, spread:180, sizeMin:2, sizeMax:5, gravityX:0, gravityY:50, damping:0.03, spin:0, colorStart:'#ff0055', colorMid:'#ff44aa', colorEnd:'#ffaaff' },
        Magic:    { max:80, rate:10, speed:50, lifetime:1.5, direction:-90, spread:360, sizeMin:2, sizeMax:5, gravityX:0, gravityY:-5, damping:0.01, spin:2, colorStart:'#aa44ff', colorMid:'#4488ff', colorEnd:'#44ffaa' },
        Hearts:   { max:30, rate:5, speed:40, lifetime:2.0, direction:-90, spread:30, sizeMin:4, sizeMax:8, gravityX:0, gravityY:-15, damping:0, spin:0, colorStart:'#ff2266', colorMid:'#ff6699', colorEnd:'#ffaacc' },
        Confetti: { max:200, rate:30, speed:120, lifetime:2.0, direction:-60, spread:120, sizeMin:3, sizeMax:6, gravityX:0, gravityY:80, damping:0, spin:3, colorStart:'#ff4444', colorMid:'#44ff44', colorEnd:'#4444ff' },
        Firefly:  { max:40, rate:3, speed:20, lifetime:3.0, direction:0, spread:360, sizeMin:2, sizeMax:4, gravityX:0, gravityY:-5, damping:0, spin:0, colorStart:'#aaff44', colorMid:'#88cc22', colorEnd:'#446600' },
        Bubbles:  { max:60, rate:8, speed:30, lifetime:3.0, direction:-90, spread:20, sizeMin:3, sizeMax:8, gravityX:0, gravityY:-20, damping:0.01, spin:0, colorStart:'#88ccff', colorMid:'#aaddff', colorEnd:'#cceeff' },
        Dust:     { max:80, rate:10, speed:15, lifetime:2.5, direction:0, spread:360, sizeMin:1, sizeMax:3, gravityX:5, gravityY:-2, damping:0, spin:0.3, colorStart:'#aa9977', colorMid:'#886644', colorEnd:'#664422' },
      };

      let cfg = { ...PRESETS.Fire };
      let particles = [], emitAccum = 0;

      // ── Parameter Groups ───────────────────────────────
      const EMISSION_PARAMS = [
        { key:'max', label:'Max', min:1, max:1000, step:1 },
        { key:'rate', label:'Rate', min:1, max:200, step:1 },
        { key:'lifetime', label:'Life', min:0.1, max:10, step:0.1 },
      ];
      const MOTION_PARAMS = [
        { key:'speed', label:'Speed', min:1, max:500, step:1 },
        { key:'direction', label:'Dir (°)', min:-180, max:180, step:1 },
        { key:'spread', label:'Spread', min:0, max:360, step:1 },
        { key:'gravityX', label:'Grav X', min:-200, max:200, step:1 },
        { key:'gravityY', label:'Grav Y', min:-200, max:200, step:1 },
        { key:'damping', label:'Damping', min:0, max:0.2, step:0.005 },
        { key:'spin', label:'Spin', min:0, max:10, step:0.1 },
      ];
      const APPEARANCE_PARAMS = [
        { key:'sizeMin', label:'Size Min', min:1, max:20, step:1 },
        { key:'sizeMax', label:'Size Max', min:1, max:40, step:1 },
      ];

      function buildSliderGroup(containerId, params) {
        const el = document.getElementById(containerId);
        el.innerHTML = '';
        for (const p of params) {
          const row = document.createElement('div');
          row.className = 'slider-row';
          row.innerHTML = '<label>' + p.label + '</label>' +
            '<input type="range" min="' + p.min + '" max="' + p.max + '" step="' + p.step + '" value="' + cfg[p.key] + '" data-key="' + p.key + '">' +
            '<span class="val">' + cfg[p.key] + '</span>';
          el.appendChild(row);
          row.querySelector('input').addEventListener('input', (e) => {
            cfg[p.key] = parseFloat(e.target.value);
            row.querySelector('.val').textContent = e.target.value;
            markDirty();
          });
        }
      }

      function buildColorControls() {
        const cel = document.getElementById('colorControls');
        cel.innerHTML = '';
        for (const ck of ['colorStart', 'colorMid', 'colorEnd']) {
          const row = document.createElement('div');
          row.className = 'color-row';
          const label = ck.replace('color', '');
          row.innerHTML = '<label>' + label + '</label>' +
            '<input type="color" value="' + cfg[ck] + '" data-key="' + ck + '">' +
            '<span class="hex">' + cfg[ck] + '</span>';
          cel.appendChild(row);
          row.querySelector('input').addEventListener('input', (e) => {
            cfg[ck] = e.target.value;
            row.querySelector('.hex').textContent = e.target.value;
            markDirty();
          });
        }
      }

      function buildAllControls() {
        buildSliderGroup('emissionParams', EMISSION_PARAMS);
        buildSliderGroup('motionParams', MOTION_PARAMS);
        buildSliderGroup('appearanceParams', APPEARANCE_PARAMS);
        buildColorControls();
      }

      // ── Presets ────────────────────────────────────────
      const presetList = document.getElementById('presetList');
      let activePreset = 'Fire';
      for (const name of Object.keys(PRESETS)) {
        const div = document.createElement('div');
        div.className = 'preset-item' + (name === activePreset ? ' selected' : '');
        const dotColor = PRESETS[name].colorStart;
        div.innerHTML = '<span class="dot" style="background:' + dotColor + '"></span>' + name;
        div.addEventListener('click', () => {
          activePreset = name;
          cfg = { ...PRESETS[name] };
          particles = []; emitAccum = 0;
          presetList.querySelectorAll('.preset-item').forEach(d => d.classList.remove('selected'));
          div.classList.add('selected');
          document.getElementById('statusPreset').textContent = name;
          buildAllControls();
          markDirty();
        });
        presetList.appendChild(div);
      }

      // ── Emitter Shape ──────────────────────────────────
      document.querySelectorAll('[data-shape]').forEach(btn => {
        btn.addEventListener('click', function() {
          document.querySelectorAll('[data-shape]').forEach(b => b.classList.remove('active'));
          this.classList.add('active');
          emitterShape = this.dataset.shape;
        });
      });
      document.getElementById('emitRadius').addEventListener('input', (e) => { emitRadius = parseInt(e.target.value) || 0; });

      // ── Simulation ─────────────────────────────────────
      function hexToRgb(hex) {
        return { r: parseInt(hex.slice(1,3),16), g: parseInt(hex.slice(3,5),16), b: parseInt(hex.slice(5,7),16) };
      }
      function lerpColor(c1, c2, t) {
        const a = hexToRgb(c1), b = hexToRgb(c2);
        return 'rgb(' + Math.round(a.r+(b.r-a.r)*t) + ',' + Math.round(a.g+(b.g-a.g)*t) + ',' + Math.round(a.b+(b.b-a.b)*t) + ')';
      }

      function emitOffset() {
        if (emitterShape === 'point') return { x: 0, y: 0 };
        if (emitterShape === 'circle') {
          const a = Math.random() * Math.PI * 2, r = Math.random() * emitRadius;
          return { x: Math.cos(a) * r, y: Math.sin(a) * r };
        }
        if (emitterShape === 'line') {
          return { x: (Math.random() - 0.5) * emitRadius * 2, y: 0 };
        }
        if (emitterShape === 'rect') {
          return { x: (Math.random() - 0.5) * emitRadius * 2, y: (Math.random() - 0.5) * emitRadius * 2 };
        }
        return { x: 0, y: 0 };
      }

      function emitParticle(cx, cy) {
        const off = emitOffset();
        const angle = (cfg.direction + (Math.random() - 0.5) * cfg.spread) * Math.PI / 180;
        const speed = cfg.speed * (0.8 + Math.random() * 0.4);
        particles.push({
          x: cx + off.x, y: cy + off.y,
          vx: Math.cos(angle) * speed, vy: Math.sin(angle) * speed,
          life: 0, maxLife: cfg.lifetime * (0.8 + Math.random() * 0.4),
          size: cfg.sizeMin + Math.random() * (cfg.sizeMax - cfg.sizeMin),
          rotation: 0, spinRate: (Math.random() - 0.5) * cfg.spin,
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
          document.getElementById('statusFps').textContent = frameCount + ' FPS';
          frameCount = 0; fpsTimer = 0;
        }

        const cx = canvas.width / 2, cy = canvas.height / 2;

        emitAccum += cfg.rate * dt;
        while (emitAccum >= 1 && particles.length < cfg.max) {
          emitParticle(cx, cy); emitAccum--;
        }

        for (let i = particles.length - 1; i >= 0; i--) {
          const p = particles[i];
          p.vx += cfg.gravityX * dt; p.vy += cfg.gravityY * dt;
          if (cfg.damping > 0) {
            p.vx *= (1 - cfg.damping); p.vy *= (1 - cfg.damping);
          }
          p.x += p.vx * dt; p.y += p.vy * dt;
          p.rotation += p.spinRate * dt;
          p.life += dt;
          if (p.life >= p.maxLife) particles.splice(i, 1);
        }

        // Render
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // Background
        if (bgMode === 'checker') {
          const s = 16;
          for (let y = 0; y < canvas.height; y += s)
            for (let x = 0; x < canvas.width; x += s) {
              ctx.fillStyle = ((Math.floor(x/s) + Math.floor(y/s)) % 2 === 0) ? '#2a2a3d' : '#232334';
              ctx.fillRect(x, y, s, s);
            }
        } else if (bgMode === 'black') {
          ctx.fillStyle = '#000'; ctx.fillRect(0, 0, canvas.width, canvas.height);
        } else if (bgMode === 'white') {
          ctx.fillStyle = '#fff'; ctx.fillRect(0, 0, canvas.width, canvas.height);
        }

        // Emitter indicator
        ctx.strokeStyle = 'rgba(137,180,250,0.3)'; ctx.lineWidth = 1;
        if (emitterShape === 'point') {
          ctx.beginPath(); ctx.arc(cx, cy, 4, 0, Math.PI * 2); ctx.stroke();
        } else if (emitterShape === 'circle') {
          ctx.beginPath(); ctx.arc(cx, cy, emitRadius, 0, Math.PI * 2); ctx.stroke();
        } else if (emitterShape === 'line') {
          ctx.beginPath(); ctx.moveTo(cx - emitRadius, cy); ctx.lineTo(cx + emitRadius, cy); ctx.stroke();
        } else if (emitterShape === 'rect') {
          ctx.strokeRect(cx - emitRadius, cy - emitRadius, emitRadius * 2, emitRadius * 2);
        }

        // Particles
        ctx.globalCompositeOperation = blendMode;
        for (const p of particles) {
          const t = p.life / p.maxLife;
          const color = t < 0.5 ? lerpColor(cfg.colorStart, cfg.colorMid, t * 2) : lerpColor(cfg.colorMid, cfg.colorEnd, (t - 0.5) * 2);
          ctx.globalAlpha = 1 - t;
          ctx.fillStyle = color;
          ctx.save();
          ctx.translate(p.x, p.y);
          ctx.rotate(p.rotation);
          ctx.beginPath();
          ctx.arc(0, 0, p.size * (1 - t * 0.3), 0, Math.PI * 2);
          ctx.fill();
          ctx.restore();
        }
        ctx.globalAlpha = 1;
        ctx.globalCompositeOperation = 'source-over';

        document.getElementById('statusParticles').textContent = particles.length + ' particles';
        requestAnimationFrame(update);
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight;
      }

      // ── Controls ───────────────────────────────────────
      document.getElementById('btnPause').addEventListener('click', function() {
        paused = !paused;
        this.innerHTML = paused ? '${ICONS.play} Resume' : '${ICONS.stop} Pause';
        if (!paused) { lastTime = performance.now(); }
      });
      document.getElementById('btnReset').addEventListener('click', () => { particles = []; emitAccum = 0; });
      registerShortcut('r', () => { particles = []; emitAccum = 0; });
      registerShortcut('space', () => {
        paused = !paused;
        document.getElementById('btnPause').innerHTML = paused ? '${ICONS.play} Resume' : '${ICONS.stop} Pause';
        if (!paused) { lastTime = performance.now(); }
      });

      document.getElementById('bgSelect').addEventListener('change', (e) => { bgMode = e.target.value; });
      document.getElementById('blendSelect').addEventListener('change', (e) => { blendMode = e.target.value; });

      // ── Export ─────────────────────────────────────────
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Particle Designer'];
        lines.push('-- Usage: local emitter = lurek.particle.newEmitter(config)');
        lines.push('');
        lines.push('return {');
        lines.push('  max_particles = ' + cfg.max + ',');
        lines.push('  emit_rate = ' + cfg.rate + ',');
        lines.push('  speed = ' + cfg.speed + ',');
        lines.push('  lifetime = ' + cfg.lifetime + ',');
        lines.push('  direction = ' + cfg.direction + ',');
        lines.push('  spread = ' + cfg.spread + ',');
        lines.push('  size = { min = ' + cfg.sizeMin + ', max = ' + cfg.sizeMax + ' },');
        lines.push('  gravity = { x = ' + cfg.gravityX + ', y = ' + cfg.gravityY + ' },');
        lines.push('  damping = ' + cfg.damping + ',');
        lines.push('  spin = ' + cfg.spin + ',');
        if (emitterShape !== 'point') {
          lines.push('  emitter_shape = "' + emitterShape + '",');
          lines.push('  emitter_radius = ' + emitRadius + ',');
        }
        lines.push('  colors = {');
        lines.push('    start  = "' + cfg.colorStart + '",');
        lines.push('    mid    = "' + cfg.colorMid + '",');
        lines.push('    finish = "' + cfg.colorEnd + '",');
        lines.push('  },');
        if (blendMode === 'lighter') lines.push('  blend = "additive",');
        lines.push('}');
        return lines.join('\\n');
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export Lua', action: () => vscode.postMessage({ type: 'exportLua', content: buildLuaCode() }) },
        { label: 'Copy Lua Code', action: () => vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() }) },
        { label: 'Insert Lua to Editor', action: () => vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() }) },
      ]);

      document.getElementById('btnCopyLua').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() });
      });

      // ── Init ───────────────────────────────────────────
      buildAllControls();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
      requestAnimationFrame(update);
    `);
  }
}
