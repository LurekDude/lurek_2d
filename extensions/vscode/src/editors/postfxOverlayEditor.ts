import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class PostFxOverlayEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): PostFxOverlayEditor {
    return new PostFxOverlayEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "luna.editor.postfxOverlay", "PostFX & Overlay Designer");
  }

  protected handleMessage(msg: { type: string; [key: string]: unknown }): void {
    if (msg.type === "copyCode") {
      vscode.env.clipboard.writeText(msg.code as string);
      vscode.window.showInformationMessage("PostFX code copied to clipboard.");
    }
    if (msg.type === "insertCode") {
      const editor = vscode.window.activeTextEditor;
      if (editor) {
        editor.insertSnippet(new vscode.SnippetString(msg.code as string));
      } else {
        vscode.window.showWarningMessage("Open a Lua file to insert code.");
      }
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "PostFX & Overlay Designer", `
      body { overflow-y: auto; }
      .layout { display: grid; grid-template-columns: 300px 1fr; gap: 12px; }
      h3 { font-size: 12px; text-transform: uppercase; letter-spacing: .05em; opacity: .6; margin: 16px 0 6px; }
      .section { margin-bottom: 12px; }
      .panel { padding: 12px; }
      .row { display: flex; align-items: center; gap: 8px; margin-bottom: 8px; font-size: 13px; }
      .row label { min-width: 130px; opacity: .8; }
      input[type=range] { flex: 1; }
      input[type=color] { width: 40px; height: 26px; padding: 0; border: none; cursor: pointer; }
      .val { font-size: 11px; min-width: 36px; text-align: right; opacity: .7; font-family: monospace; }
      .preview-box { background: #111; border-radius: 6px; border: 1px solid var(--border); position: relative; overflow: hidden; aspect-ratio: 16/9; }
      canvas#preview { display:block; width:100%; }
      code-out { font-family: 'Cascadia Code', monospace; font-size: 11px; background: #1a1a1a; color: #9cdcfe; border-radius: 4px; padding: 10px; display: block; white-space: pre; overflow-x: auto; }
      .btn-row { display: flex; gap: 8px; margin-top: 8px; }
      .tab-row { display: flex; gap: 4px; margin-bottom: 12px; flex-wrap: wrap; }
      .tab { padding: 4px 10px; border-radius: 3px; font-size: 12px; cursor: pointer; background: var(--surface-2); border: none; color: var(--foreground); }
      .tab.active { background: #0e518c; color: #fff; }
      select { background: var(--input-background); color: var(--foreground); border: 1px solid var(--border); padding: 2px 6px; border-radius: 3px; font-size: 12px; }
      .toggle { display: flex; align-items: center; gap: 8px; margin-bottom: 6px; cursor: pointer; }
      .toggle input { width: 16px; height: 16px; cursor: pointer; }
    `, `
      <h2 style="margin:0 0 12px;font-size:14px">🎨 PostFX & Overlay Designer</h2>
      <div class="tab-row" id="tabs">
        <button class="tab active" data-tab="weather">Weather</button>
        <button class="tab" data-tab="timeofday">Time of Day</button>
        <button class="tab" data-tab="screen">Screen Effects</button>
        <button class="tab" data-tab="shake">Camera Shake</button>
        <button class="tab" data-tab="overlay">Overlay Presets</button>
      </div>
      <div class="layout">
        <div>
          <!-- WEATHER -->
          <div id="tab-weather" class="section">
            <h3>Weather</h3>
            <div class="row"><label>Preset</label>
              <select id="weatherPreset"><option>Clear</option><option>Rain</option><option>Heavy Rain</option><option>Snow</option><option>Blizzard</option><option>Fog</option><option>Sandstorm</option><option>Thunderstorm</option></select>
            </div>
            <div class="row"><label>Intensity</label><input type="range" id="weatherIntensity" min="0" max="1" step="0.01" value="0.5"><span class="val" id="weatherIntensityVal">0.50</span></div>
            <div class="row"><label>Wind X</label><input type="range" id="windX" min="-500" max="500" step="1" value="80"><span class="val" id="windXVal">80</span></div>
            <div class="row"><label>Wind Y</label><input type="range" id="windY" min="50" max="600" step="1" value="300"><span class="val" id="windYVal">300</span></div>
            <div class="row"><label>Particle Color</label><input type="color" id="weatherColor" value="#aaddf0"></div>
            <div class="row"><label>Fog Density</label><input type="range" id="fogDensity" min="0" max="1" step="0.01" value="0"><span class="val" id="fogDensityVal">0.00</span></div>
            <div class="row"><label>Fog Color</label><input type="color" id="fogColor" value="#8899aa"></div>
          </div>
          <!-- TIME OF DAY -->
          <div id="tab-timeofday" class="section" style="display:none">
            <h3>Time of Day</h3>
            <div class="row"><label>Hour</label><input type="range" id="hour" min="0" max="23.99" step="0.25" value="12"><span class="val" id="hourVal">12:00</span></div>
            <div class="row"><label>Sky Color</label><input type="color" id="skyColor" value="#87ceeb"></div>
            <div class="row"><label>Ambient Light</label><input type="range" id="ambientLight" min="0" max="1" step="0.01" value="1.0"><span class="val" id="ambientLightVal">1.00</span></div>
            <div class="row"><label>Sun Color</label><input type="color" id="sunColor" value="#fff5cc"></div>
            <div class="row"><label>Moon Enabled</label><input type="checkbox" id="moonEnabled" checked></div>
            <div class="row"><label>Stars Enabled</label><input type="checkbox" id="starsEnabled"></div>
            <div class="row"><label>Transition Speed</label><input type="range" id="todSpeed" min="0.001" max="0.1" step="0.001" value="0.01"><span class="val" id="todSpeedVal">0.010</span></div>
            <div class="row"><label>Preset</label>
              <select id="todPreset"><option>Custom</option><option>Dawn</option><option>Morning</option><option>Noon</option><option>Afternoon</option><option>Dusk</option><option>Night</option><option>Midnight</option></select>
            </div>
          </div>
          <!-- SCREEN EFFECTS -->
          <div id="tab-screen" class="section" style="display:none">
            <h3>Screen Effects</h3>
            <div class="row"><label>Vignette</label><input type="range" id="vignette" min="0" max="1" step="0.01" value="0"><span class="val" id="vignetteVal">0.00</span></div>
            <div class="row"><label>Vignette Color</label><input type="color" id="vignetteColor" value="#000000"></div>
            <div class="row"><label>Scanlines</label><input type="range" id="scanlines" min="0" max="1" step="0.01" value="0"><span class="val" id="scanlinesVal">0.00</span></div>
            <div class="row"><label>Color Saturation</label><input type="range" id="saturation" min="0" max="2" step="0.01" value="1"><span class="val" id="saturationVal">1.00</span></div>
            <div class="row"><label>Brightness</label><input type="range" id="brightness" min="0" max="2" step="0.01" value="1"><span class="val" id="brightnessVal">1.00</span></div>
            <div class="row"><label>Contrast</label><input type="range" id="contrast" min="0" max="3" step="0.01" value="1"><span class="val" id="contrastVal">1.00</span></div>
            <div class="row"><label>Chromatic Aberr.</label><input type="range" id="chromatic" min="0" max="10" step="0.1" value="0"><span class="val" id="chromaticVal">0.0</span></div>
            <div class="row"><label>Pixel Size</label><input type="range" id="pixelSize" min="1" max="16" step="1" value="1"><span class="val" id="pixelSizeVal">1</span></div>
            <div class="row"><label>Film Grain</label><input type="range" id="filmGrain" min="0" max="1" step="0.01" value="0"><span class="val" id="filmGrainVal">0.00</span></div>
            <div class="row"><label>Bloom</label><input type="range" id="bloom" min="0" max="1" step="0.01" value="0"><span class="val" id="bloomVal">0.00</span></div>
          </div>
          <!-- CAMERA SHAKE -->
          <div id="tab-shake" class="section" style="display:none">
            <h3>Camera Shake</h3>
            <div class="row"><label>Amplitude</label><input type="range" id="shakeAmplitude" min="0" max="50" step="0.5" value="5"><span class="val" id="shakeAmplitudeVal">5.0</span></div>
            <div class="row"><label>Frequency</label><input type="range" id="shakeFrequency" min="1" max="60" step="1" value="20"><span class="val" id="shakeFrequencyVal">20</span></div>
            <div class="row"><label>Duration (s)</label><input type="range" id="shakeDuration" min="0.1" max="5" step="0.1" value="0.5"><span class="val" id="shakeDurationVal">0.50</span></div>
            <div class="row"><label>Decay</label><input type="range" id="shakeDecay" min="0.5" max="10" step="0.1" value="3"><span class="val" id="shakeDecayVal">3.0</span></div>
            <div class="row"><label>Rotation Shake</label><input type="range" id="shakeRotation" min="0" max="10" step="0.1" value="0"><span class="val" id="shakeRotationVal">0.0</span></div>
            <div class="row"><label>Trauma based</label><input type="checkbox" id="shakeTrauma" checked></div>
          </div>
          <!-- OVERLAY PRESETS -->
          <div id="tab-overlay" class="section" style="display:none">
            <h3>Overlay Presets</h3>
            <div class="row"><label>Preset</label>
              <select id="overlayPreset"><option>None</option><option>Blood Vignette</option><option>Underwater</option><option>Night Vision</option><option>Thermal Vision</option><option>Old Film</option><option>Heatwave</option><option>Poison</option><option>Fire Overlay</option></select>
            </div>
            <div class="row"><label>Overlay Alpha</label><input type="range" id="overlayAlpha" min="0" max="1" step="0.01" value="0.5"><span class="val" id="overlayAlphaVal">0.50</span></div>
            <div class="row"><label>Overlay Color</label><input type="color" id="overlayColor" value="#ff0000"></div>
            <div class="row"><label>Pulsate</label><input type="checkbox" id="overlayPulsate"></div>
            <div class="row"><label>Pulse Speed</label><input type="range" id="overlayPulseSpeed" min="0.5" max="10" step="0.5" value="2"><span class="val" id="overlayPulseSpeedVal">2.0</span></div>
          </div>
        </div>

        <div>
          <div class="preview-box">
            <canvas id="preview" width="640" height="360"></canvas>
          </div>
          <h3>Generated Lua Code</h3>
          <pre id="codeOut" style="font-family:'Cascadia Code',monospace;font-size:11px;background:#1a1a1a;color:#9cdcfe;border-radius:4px;padding:10px;overflow-x:auto;white-space:pre;"></pre>
          <div class="btn-row">
            <button id="btnCopy">📋 Copy Code</button>
            <button id="btnInsert">⤵ Insert at Cursor</button>
          </div>
        </div>
      </div>
    `, `
      const vscode = acquireVsCodeApi();
      let currentTab = 'weather';

      // Tab switching
      document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', () => {
          currentTab = tab.dataset.tab;
          document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
          tab.classList.add('active');
          document.querySelectorAll('[id^="tab-"]').forEach(s => s.style.display = 'none');
          document.getElementById('tab-' + currentTab).style.display = '';
          updateCode();
        });
      });

      // Live value labels
      document.querySelectorAll('input[type=range]').forEach(r => {
        const valEl = document.getElementById(r.id + 'Val');
        function fmt(v) {
          if (r.id === 'hour') { const h = Math.floor(v); const m = Math.round((v-h)*60); return h+':'+(m<10?'0':'')+m; }
          if (r.step && parseFloat(r.step) >= 1) return Math.round(v).toString();
          return parseFloat(v).toFixed(2);
        }
        if (valEl) { valEl.textContent = fmt(r.value); r.addEventListener('input', () => { valEl.textContent = fmt(r.value); updateCode(); drawPreview(); }); }
        r.addEventListener('input', updateCode);
      });
      document.querySelectorAll('input[type=color],input[type=checkbox],select').forEach(el => el.addEventListener('change', () => { updateCode(); drawPreview(); }));

      // Time-of-day presets
      const todPresets = {
        'Dawn':      { hour:5.5,  sky:'#ff8c42', ambient:0.45, sun:'#ffa44f' },
        'Morning':   { hour:8,    sky:'#87ceeb', ambient:0.75, sun:'#fffccc' },
        'Noon':      { hour:12,   sky:'#4fc3f7', ambient:1.0,  sun:'#ffffff' },
        'Afternoon': { hour:15.5, sky:'#87ceeb', ambient:0.9,  sun:'#fff0a0' },
        'Dusk':      { hour:18.5, sky:'#e67e4b', ambient:0.5,  sun:'#ffa44f' },
        'Night':     { hour:21,   sky:'#1a2344', ambient:0.2,  sun:'#aaaacc' },
        'Midnight':  { hour:0,    sky:'#0a0e24', ambient:0.05, sun:'#223366' },
      };
      document.getElementById('todPreset').addEventListener('change', (e) => {
        const p = todPresets[e.target.value];
        if (!p) return;
        document.getElementById('hour').value = p.hour;
        document.getElementById('hourVal').textContent = (() => { const h=Math.floor(p.hour),m=Math.round((p.hour-h)*60); return h+':'+(m<10?'0':'')+m; })();
        document.getElementById('skyColor').value = p.sky;
        document.getElementById('ambientLight').value = p.ambient;
        document.getElementById('ambientLightVal').textContent = p.ambient.toFixed(2);
        document.getElementById('sunColor').value = p.sun;
        updateCode(); drawPreview();
      });

      // Weather presets
      const wPresets = {
        'Rain':        { intensity:0.5, windX:80,  windY:350, color:'#aaddf0' },
        'Heavy Rain':  { intensity:1.0, windX:120, windY:500, color:'#aaddf0' },
        'Snow':        { intensity:0.4, windX:20,  windY:150, color:'#ffffff' },
        'Blizzard':    { intensity:1.0, windX:200, windY:200, color:'#eef5ff' },
        'Fog':         { intensity:0.6, windX:0,   windY:0,   color:'#8899aa', fogDensity:0.7 },
        'Sandstorm':   { intensity:0.8, windX:300, windY:100, color:'#c8a863' },
        'Thunderstorm':{ intensity:0.9, windX:150, windY:450, color:'#8899aa' },
      };
      document.getElementById('weatherPreset').addEventListener('change', (e) => {
        const p = wPresets[e.target.value];
        if (!p) return;
        ['intensity','windX','windY'].forEach(k => {
          const el = document.getElementById('weather'+k.charAt(0).toUpperCase()+k.slice(1)) || document.getElementById(k);
          if (el && p[k] !== undefined) { el.value = p[k]; const v = document.getElementById(el.id+'Val'); if(v) v.textContent = p[k]; }
        });
        if(p.color) document.getElementById('weatherColor').value = p.color;
        if(p.fogDensity !== undefined) { document.getElementById('fogDensity').value = p.fogDensity; document.getElementById('fogDensityVal').textContent = p.fogDensity.toFixed(2); }
        updateCode(); drawPreview();
      });

      // Overlay presets
      const oPresets = {
        'Blood Vignette':  { color:'#cc0000', alpha:0.4, pulsate:true, speed:3 },
        'Underwater':      { color:'#006080', alpha:0.3, pulsate:false },
        'Night Vision':    { color:'#004400', alpha:0.4, pulsate:false },
        'Thermal Vision':  { color:'#aa2200', alpha:0.3, pulsate:false },
        'Old Film':        { color:'#aa8855', alpha:0.25, pulsate:false },
        'Poison':          { color:'#226600', alpha:0.35, pulsate:true, speed:1.5 },
        'Fire Overlay':    { color:'#cc3300', alpha:0.3, pulsate:true, speed:4 },
      };
      document.getElementById('overlayPreset').addEventListener('change', (e) => {
        const p = oPresets[e.target.value]; if(!p) return;
        document.getElementById('overlayColor').value = p.color;
        document.getElementById('overlayAlpha').value = p.alpha;
        document.getElementById('overlayAlphaVal').textContent = p.alpha.toFixed(2);
        document.getElementById('overlayPulsate').checked = !!p.pulsate;
        if(p.speed) { document.getElementById('overlayPulseSpeed').value = p.speed; document.getElementById('overlayPulseSpeedVal').textContent = p.speed.toFixed(1); }
        updateCode(); drawPreview();
      });

      function g(id) { return document.getElementById(id); }
      function fv(id) { return parseFloat(g(id).value); }

      function updateCode() {
        let code = '';
        if (currentTab === 'weather') {
          const preset = g('weatherPreset').value;
          const intensity = fv('weatherIntensity');
          const windX = fv('windX'), windY = fv('windY');
          const color = g('weatherColor').value;
          const fogDensity = fv('fogDensity');
          const fogColor = g('fogColor').value;
          code = '-- Weather: ' + preset + '\\n';
          if (preset !== 'Clear') {
            code += 'local weather = luna.postfx.createWeather({\\n';
            code += '  preset   = "' + preset.toLowerCase().replace(/ /g,'_') + '",\\n';
            code += '  intensity = ' + intensity.toFixed(2) + ',\\n';
            code += '  wind      = luna.math.vec2(' + windX + ', ' + windY + '),\\n';
            code += '  color     = luna.graphics.newColor("' + color + '"),\\n';
            code += '})\\n\\n';
            code += 'function luna.update(dt)\\n  weather:update(dt)\\nend\\n';
            code += 'function luna.draw()\\n  weather:draw()\\n';
            if (fogDensity > 0) code += '  luna.postfx.fog({ density=' + fogDensity.toFixed(2) + ', color=luna.graphics.newColor("' + fogColor + '") })\\n';
            code += 'end';
          } else {
            code += '-- No weather effects active';
          }
        } else if (currentTab === 'timeofday') {
          const hour = fv('hour');
          const sky = g('skyColor').value;
          const ambient = fv('ambientLight');
          const sun = g('sunColor').value;
          const moon = g('moonEnabled').checked;
          const stars = g('starsEnabled').checked;
          const speed = fv('todSpeed');
          code = '-- Time of Day Setup\\n';
          code += 'local tod = luna.postfx.createTimeOfDay({\\n';
          code += '  hour         = ' + hour.toFixed(2) + ',\\n';
          code += '  sky_color    = luna.graphics.newColor("' + sky + '"),\\n';
          code += '  sun_color    = luna.graphics.newColor("' + sun + '"),\\n';
          code += '  ambient      = ' + ambient.toFixed(2) + ',\\n';
          code += '  moon_enabled = ' + moon + ',\\n';
          code += '  stars        = ' + stars + ',\\n';
          code += '  speed        = ' + speed.toFixed(3) + ',\\n';
          code += '})\\n\\n';
          code += 'function luna.update(dt)\\n  tod:update(dt)\\nend\\n';
          code += 'function luna.draw()\\n  tod:drawSky()\\n  -- draw game world here\\n  tod:drawOverlay()\\nend';
        } else if (currentTab === 'screen') {
          const lines = [];
          const vig = fv('vignette');
          const scan = fv('scanlines');
          const sat = fv('saturation');
          const bright = fv('brightness');
          const cont = fv('contrast');
          const chrom = fv('chromatic');
          const px = fv('pixelSize');
          const grain = fv('filmGrain');
          const bloom_ = fv('bloom');
          code = '-- Screen PostFX\\nfunction luna.draw()\\n  -- draw game\\n  local fx = luna.postfx.begin()\\n';
          if (vig > 0)    lines.push('  fx:vignette({ strength=' + vig.toFixed(2) + ', color=luna.graphics.newColor("' + g('vignetteColor').value + '") })');
          if (scan > 0)   lines.push('  fx:scanlines({ alpha=' + scan.toFixed(2) + ' })');
          if (sat !== 1)  lines.push('  fx:saturation(' + sat.toFixed(2) + ')');
          if (bright !== 1) lines.push('  fx:brightness(' + bright.toFixed(2) + ')');
          if (cont !== 1) lines.push('  fx:contrast(' + cont.toFixed(2) + ')');
          if (chrom > 0)  lines.push('  fx:chromaticAberration(' + chrom.toFixed(1) + ')');
          if (px > 1)     lines.push('  fx:pixelate(' + px + ')');
          if (grain > 0)  lines.push('  fx:filmGrain(' + grain.toFixed(2) + ')');
          if (bloom_ > 0) lines.push('  fx:bloom({ threshold=0.7, strength=' + bloom_.toFixed(2) + ' })');
          code += lines.join('\\n') + '\\n  luna.postfx.finish(fx)\\nend';
        } else if (currentTab === 'shake') {
          const amp = fv('shakeAmplitude'), freq = fv('shakeFrequency');
          const dur = fv('shakeDuration'), decay = fv('shakeDecay');
          const rot = fv('shakeRotation');
          const trauma = g('shakeTrauma').checked;
          code = '-- Camera Shake\\n';
          code += 'local shaker = luna.camera.createShaker({\\n';
          code += '  amplitude  = ' + amp.toFixed(1) + ',\\n';
          code += '  frequency  = ' + freq + ',\\n';
          code += '  duration   = ' + dur.toFixed(2) + ',\\n';
          code += '  decay      = ' + decay.toFixed(1) + ',\\n';
          code += '  rotation   = ' + rot.toFixed(1) + ',\\n';
          code += '  trauma     = ' + trauma + ',\\n';
          code += '})\\n\\n';
          code += '-- Trigger a shake (e.g. on explosion):\\nshaker:shake()\\n\\n';
          code += 'function luna.update(dt)\\n  shaker:update(dt)\\nend\\n';
          code += 'function luna.draw()\\n  shaker:push()\\n  -- draw everything here\\n  shaker:pop()\\nend';
        } else if (currentTab === 'overlay') {
          const preset = g('overlayPreset').value;
          const alpha = fv('overlayAlpha');
          const color = g('overlayColor').value;
          const pulse = g('overlayPulsate').checked;
          const speed = fv('overlayPulseSpeed');
          code = '-- Overlay: ' + preset + '\\n';
          code += 'local overlay = luna.postfx.createOverlay({\\n';
          code += '  preset  = "' + preset.toLowerCase().replace(/ /g,'_') + '",\\n';
          code += '  color   = luna.graphics.newColor("' + color + '"),\\n';
          code += '  alpha   = ' + alpha.toFixed(2) + ',\\n';
          code += '  pulsate = ' + pulse + ',\\n';
          if (pulse) code += '  speed   = ' + speed.toFixed(1) + ',\\n';
          code += '})\\n\\n';
          code += 'function luna.update(dt)\\n  overlay:update(dt)\\nend\\n';
          code += 'function luna.draw()\\n  -- draw game\\n  overlay:draw()\\nend';
        }
        g('codeOut').textContent = code;
      }

      function drawPreview() {
        const canvas = g('preview');
        if (!canvas) return;
        const ctx = canvas.getContext('2d');
        const W = 640, H = 360;
        ctx.clearRect(0,0,W,H);

        if (currentTab === 'timeofday') {
          const sky = g('skyColor').value;
          ctx.fillStyle = sky; ctx.fillRect(0,0,W,H);
          // ground
          ctx.fillStyle = '#2d4a1e'; ctx.fillRect(0,H*0.7,W,H*0.3);
          // sun position based on hour
          const hour = fv('hour');
          const sunX = (hour/24)*W;
          const sunY = H*0.5 - Math.sin((hour/24)*Math.PI)*H*0.4;
          if (hour > 5 && hour < 20) {
            ctx.beginPath(); ctx.arc(sunX,sunY,20,0,Math.PI*2);
            ctx.fillStyle = g('sunColor').value; ctx.fill();
          }
          // ambient overlay
          const ambient = fv('ambientLight');
          if (ambient < 1) {
            ctx.fillStyle = 'rgba(0,0,20,' + (1-ambient).toFixed(2) + ')'; ctx.fillRect(0,0,W,H);
          }
        } else if (currentTab === 'weather') {
          ctx.fillStyle = '#3a5a7a'; ctx.fillRect(0,0,W,H);
          ctx.fillStyle = '#2d4a1e'; ctx.fillRect(0,H*0.7,W,H*0.3);
          const fog = fv('fogDensity');
          if (fog > 0) {
            ctx.fillStyle = 'rgba(' + parseInt(g('fogColor').value.slice(1,3),16) + ',' + parseInt(g('fogColor').value.slice(3,5),16) + ',' + parseInt(g('fogColor').value.slice(5,7),16) + ',' + (fog*0.8).toFixed(2) + ')';
            ctx.fillRect(0,0,W,H);
          }
          const intensity = fv('weatherIntensity');
          const preset = g('weatherPreset').value;
          if (preset !== 'Clear') {
            const col = g('weatherColor').value;
            ctx.strokeStyle = col; ctx.globalAlpha = intensity*0.7;
            const wX = fv('windX'), wY = fv('windY');
            const ang = Math.atan2(wY, wX);
            const count = Math.floor(intensity * 80);
            for (let i = 0; i < count; i++) {
              const x = Math.random()*W, y = Math.random()*H;
              const len = preset.includes('Snow') ? 3 : 12;
              ctx.beginPath(); ctx.moveTo(x, y);
              ctx.lineTo(x + Math.cos(ang)*len, y + Math.sin(ang)*len);
              ctx.stroke();
            }
            ctx.globalAlpha = 1;
          }
        } else {
          // Generic preview
          ctx.fillStyle = '#1e2d3a'; ctx.fillRect(0,0,W,H);
          ctx.fillStyle = '#2d4a1e'; ctx.fillRect(0,H*0.65,W,H*0.35);
          // Simple platformer silhouette
          ctx.fillStyle = '#4a6741';
          ctx.fillRect(W*0.1,H*0.5,80,20); ctx.fillRect(W*0.4,H*0.4,60,20); ctx.fillRect(W*0.7,H*0.55,100,20);
        }

        if (currentTab === 'screen') {
          const vig = fv('vignette');
          if (vig > 0) {
            const vg = ctx.createRadialGradient(W/2,H/2,W*0.2,W/2,H/2,W*0.75);
            vg.addColorStop(0,'transparent');
            const vc = g('vignetteColor').value;
            vg.addColorStop(1,'rgba(' + parseInt(vc.slice(1,3),16) + ',' + parseInt(vc.slice(3,5),16) + ',' + parseInt(vc.slice(5,7),16) + ',' + vig + ')');
            ctx.fillStyle = vg; ctx.fillRect(0,0,W,H);
          }
        }
        if (currentTab === 'overlay') {
          const alpha = fv('overlayAlpha');
          const oc = g('overlayColor').value;
          ctx.fillStyle = 'rgba(' + parseInt(oc.slice(1,3),16) + ',' + parseInt(oc.slice(3,5),16) + ',' + parseInt(oc.slice(5,7),16) + ',' + (alpha*0.6) + ')';
          ctx.fillRect(0,0,W,H);
        }
      }

      document.getElementById('btnCopy').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyCode', code: g('codeOut').textContent });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertCode', code: g('codeOut').textContent });
      });

      updateCode(); drawPreview();
    `);
  }
}
