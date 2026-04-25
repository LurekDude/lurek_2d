import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

export class PostFxOverlayEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): PostFxOverlayEditor {
    return new PostFxOverlayEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.editor.postfxOverlay", "PostFX & Overlay Designer");
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
      .editor-layout { display:grid; grid-template-rows:auto auto 1fr auto; height:100vh; overflow:hidden; }
      .toolbar { display:flex; align-items:center; gap:6px; padding:6px 10px; background:var(--surface); border-bottom:1px solid var(--border); }
      .toolbar .title { font-weight:600; font-size:13px; white-space:nowrap; }
      .tab-bar { display:flex; gap:2px; padding:4px 10px; background:var(--surface); border-bottom:1px solid var(--border); flex-wrap:wrap; }
      .tab { padding:4px 12px; border-radius:var(--radius) var(--radius) 0 0; font-size:12px; cursor:pointer; background:transparent; border:1px solid transparent; border-bottom:none; color:var(--text-dim); transition:background .15s,color .15s; }
      .tab:hover { background:var(--hover); color:var(--text); }
      .tab.sel { background:var(--bg); color:var(--accent); border-color:var(--border); font-weight:600; }
      .main-area { display:grid; grid-template-columns:320px 1fr; gap:0; overflow:hidden; }
      .props-col { overflow-y:auto; padding:8px 10px; border-right:1px solid var(--border); }
      .vis-col { display:flex; flex-direction:column; gap:8px; padding:8px 10px; overflow-y:auto; }
      .vis-box { background:var(--bg); border-radius:var(--radius); border:1px solid var(--border); overflow:hidden; aspect-ratio:16/9; }
      .vis-box canvas { display:block; width:100%; }
      .code-out { font-family:'Cascadia Code','Fira Code',monospace; font-size:11px; background:var(--bg); color:var(--accent); border:1px solid var(--border); border-radius:var(--radius); padding:10px; white-space:pre; overflow-x:auto; min-height:80px; max-height:200px; }
      .dsp-row { display:flex; align-items:center; gap:8px; margin-bottom:6px; font-size:12px; }
      .dsp-row label { min-width:120px; color:var(--text-dim); font-size:11px; }
      .dsp-row input[type=range] { flex:1; accent-color:var(--accent); }
      .dsp-row input[type=color] { width:36px; height:24px; padding:0; border:1px solid var(--border); border-radius:var(--radius); cursor:pointer; background:transparent; }
      .dsp-row input[type=checkbox] { width:15px; height:15px; accent-color:var(--accent); cursor:pointer; }
      .dsp-row .val { font-size:10px; min-width:34px; text-align:right; color:var(--text-dim); font-family:monospace; }
      .dsp-row select { background:var(--surface); color:var(--text); border:1px solid var(--border); padding:3px 6px; border-radius:var(--radius); font-size:11px; }
      .status-bar { display:flex; align-items:center; gap:8px; padding:4px 10px; background:var(--surface); border-top:1px solid var(--border); font-size:11px; color:var(--text-dim); }
      .badge { background:var(--accent); color:var(--bg); padding:1px 7px; border-radius:10px; font-size:10px; font-weight:600; }
      .sep { width:1px; height:14px; background:var(--border); }
      .spacer { flex:1; }
      .code-label { font-size:11px; color:var(--text-dim); text-transform:uppercase; letter-spacing:.05em; margin:0 0 4px; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <span class="title">${ICONS.effect ?? '🎨'} PostFX & Overlay Designer</span>
          ${toolbarSep()}
          ${iconButton(ICONS.copy,'btnCopy','Copy Code')}
          ${iconButton(ICONS.add,'btnInsert','Insert at Cursor')}
          ${toolbarSpacer()}
          ${iconButton(ICONS.save,'btnExport','Export Lua')}
        </div>
        <div class="tab-bar" id="tabs">
          <button class="tab sel" data-tab="weather">Weather</button>
          <button class="tab" data-tab="timeofday">Time of Day</button>
          <button class="tab" data-tab="screen">Screen Effects</button>
          <button class="tab" data-tab="shake">Camera Shake</button>
          <button class="tab" data-tab="overlay">Overlay Presets</button>
        </div>
        <div class="main-area">
          <div class="props-col">
            <!-- WEATHER -->
            <div id="tab-weather">
              ${panelSection('Weather', `
                <div class="dsp-row"><label>Preset</label>
                  <select id="weatherPreset"><option>Clear</option><option>Rain</option><option>Heavy Rain</option><option>Snow</option><option>Blizzard</option><option>Fog</option><option>Sandstorm</option><option>Thunderstorm</option></select>
                </div>
                <div class="dsp-row"><label>Intensity</label><input type="range" id="weatherIntensity" min="0" max="1" step="0.01" value="0.5"><span class="val" id="weatherIntensityVal">0.50</span></div>
                <div class="dsp-row"><label>Wind X</label><input type="range" id="windX" min="-500" max="500" step="1" value="80"><span class="val" id="windXVal">80</span></div>
                <div class="dsp-row"><label>Wind Y</label><input type="range" id="windY" min="50" max="600" step="1" value="300"><span class="val" id="windYVal">300</span></div>
                <div class="dsp-row"><label>Particle Color</label><input type="color" id="weatherColor" value="#aaddf0"></div>
                <div class="dsp-row"><label>Fog Density</label><input type="range" id="fogDensity" min="0" max="1" step="0.01" value="0"><span class="val" id="fogDensityVal">0.00</span></div>
                <div class="dsp-row"><label>Fog Color</label><input type="color" id="fogColor" value="#8899aa"></div>
              `)}
            </div>
            <!-- TIME OF DAY -->
            <div id="tab-timeofday" style="display:none">
              ${panelSection('Time of Day', `
                <div class="dsp-row"><label>Hour</label><input type="range" id="hour" min="0" max="23.99" step="0.25" value="12"><span class="val" id="hourVal">12:00</span></div>
                <div class="dsp-row"><label>Sky Color</label><input type="color" id="skyColor" value="#87ceeb"></div>
                <div class="dsp-row"><label>Ambient Light</label><input type="range" id="ambientLight" min="0" max="1" step="0.01" value="1.0"><span class="val" id="ambientLightVal">1.00</span></div>
                <div class="dsp-row"><label>Sun Color</label><input type="color" id="sunColor" value="#fff5cc"></div>
                <div class="dsp-row"><label>Moon Enabled</label><input type="checkbox" id="moonEnabled" checked></div>
                <div class="dsp-row"><label>Stars Enabled</label><input type="checkbox" id="starsEnabled"></div>
                <div class="dsp-row"><label>Transition Speed</label><input type="range" id="todSpeed" min="0.001" max="0.1" step="0.001" value="0.01"><span class="val" id="todSpeedVal">0.010</span></div>
                <div class="dsp-row"><label>Preset</label>
                  <select id="todPreset"><option>Custom</option><option>Dawn</option><option>Morning</option><option>Noon</option><option>Afternoon</option><option>Dusk</option><option>Night</option><option>Midnight</option></select>
                </div>
              `)}
            </div>
            <!-- SCREEN EFFECTS -->
            <div id="tab-screen" style="display:none">
              ${panelSection('Screen Effects', `
                <div class="dsp-row"><label>Vignette</label><input type="range" id="vignette" min="0" max="1" step="0.01" value="0"><span class="val" id="vignetteVal">0.00</span></div>
                <div class="dsp-row"><label>Vignette Color</label><input type="color" id="vignetteColor" value="#000000"></div>
                <div class="dsp-row"><label>Scanlines</label><input type="range" id="scanlines" min="0" max="1" step="0.01" value="0"><span class="val" id="scanlinesVal">0.00</span></div>
                <div class="dsp-row"><label>Color Saturation</label><input type="range" id="saturation" min="0" max="2" step="0.01" value="1"><span class="val" id="saturationVal">1.00</span></div>
                <div class="dsp-row"><label>Brightness</label><input type="range" id="brightness" min="0" max="2" step="0.01" value="1"><span class="val" id="brightnessVal">1.00</span></div>
                <div class="dsp-row"><label>Contrast</label><input type="range" id="contrast" min="0" max="3" step="0.01" value="1"><span class="val" id="contrastVal">1.00</span></div>
                <div class="dsp-row"><label>Chromatic Aberr.</label><input type="range" id="chromatic" min="0" max="10" step="0.1" value="0"><span class="val" id="chromaticVal">0.0</span></div>
                <div class="dsp-row"><label>Pixel Size</label><input type="range" id="pixelSize" min="1" max="16" step="1" value="1"><span class="val" id="pixelSizeVal">1</span></div>
                <div class="dsp-row"><label>Film Grain</label><input type="range" id="filmGrain" min="0" max="1" step="0.01" value="0"><span class="val" id="filmGrainVal">0.00</span></div>
                <div class="dsp-row"><label>Bloom</label><input type="range" id="bloom" min="0" max="1" step="0.01" value="0"><span class="val" id="bloomVal">0.00</span></div>
              `)}
            </div>
            <!-- CAMERA SHAKE -->
            <div id="tab-shake" style="display:none">
              ${panelSection('Camera Shake', `
                <div class="dsp-row"><label>Amplitude</label><input type="range" id="shakeAmplitude" min="0" max="50" step="0.5" value="5"><span class="val" id="shakeAmplitudeVal">5.0</span></div>
                <div class="dsp-row"><label>Frequency</label><input type="range" id="shakeFrequency" min="1" max="60" step="1" value="20"><span class="val" id="shakeFrequencyVal">20</span></div>
                <div class="dsp-row"><label>Duration (s)</label><input type="range" id="shakeDuration" min="0.1" max="5" step="0.1" value="0.5"><span class="val" id="shakeDurationVal">0.50</span></div>
                <div class="dsp-row"><label>Decay</label><input type="range" id="shakeDecay" min="0.5" max="10" step="0.1" value="3"><span class="val" id="shakeDecayVal">3.0</span></div>
                <div class="dsp-row"><label>Rotation Shake</label><input type="range" id="shakeRotation" min="0" max="10" step="0.1" value="0"><span class="val" id="shakeRotationVal">0.0</span></div>
                <div class="dsp-row"><label>Trauma based</label><input type="checkbox" id="shakeTrauma" checked></div>
              `)}
            </div>
            <!-- OVERLAY PRESETS -->
            <div id="tab-overlay" style="display:none">
              ${panelSection('Overlay Presets', `
                <div class="dsp-row"><label>Preset</label>
                  <select id="overlayPreset"><option>None</option><option>Blood Vignette</option><option>Underwater</option><option>Night Vision</option><option>Thermal Vision</option><option>Old Film</option><option>Heatwave</option><option>Poison</option><option>Fire Overlay</option></select>
                </div>
                <div class="dsp-row"><label>Overlay Alpha</label><input type="range" id="overlayAlpha" min="0" max="1" step="0.01" value="0.5"><span class="val" id="overlayAlphaVal">0.50</span></div>
                <div class="dsp-row"><label>Overlay Color</label><input type="color" id="overlayColor" value="#ff0000"></div>
                <div class="dsp-row"><label>Pulsate</label><input type="checkbox" id="overlayPulsate"></div>
                <div class="dsp-row"><label>Pulse Speed</label><input type="range" id="overlayPulseSpeed" min="0.5" max="10" step="0.5" value="2"><span class="val" id="overlayPulseSpeedVal">2.0</span></div>
              `)}
            </div>
          </div>

          <div class="vis-col">
            <div class="vis-box">
              <canvas id="preview" width="640" height="360"></canvas>
            </div>
            <div class="code-label">Generated Lua Code</div>
            <pre id="codeOut" class="code-out"></pre>
          </div>
        </div>
        <div class="status-bar">
          <span class="badge" id="tabBadge">Weather</span>
          <span class="sep"></span>
          <span id="effectCount">0 effects</span>
          <span class="spacer"></span>
          <span id="dirtyFlag">${ICONS.clean ?? '✓'}</span>
        </div>
      </div>
    `, `
      const vscode = acquireVsCodeApi();
      let currentTab = 'weather';
      const undo = new UndoStack();

      function g(id) { return document.getElementById(id); }
      function fv(id) { return parseFloat(g(id).value); }

      function snap() {
        const data = {};
        document.querySelectorAll('input[type=range],input[type=color],select').forEach(el => { data[el.id] = el.value; });
        document.querySelectorAll('input[type=checkbox]').forEach(el => { data[el.id] = el.checked; });
        data._tab = currentTab;
        return data;
      }
      function load(data) {
        if (!data) return;
        Object.entries(data).forEach(([k,v]) => {
          if (k === '_tab') return;
          const el = g(k); if (!el) return;
          if (el.type === 'checkbox') el.checked = v;
          else el.value = v;
          const valEl = g(k + 'Val');
          if (valEl && el.type === 'range') {
            if (k === 'hour') { const h=Math.floor(v),m=Math.round((v-h)*60); valEl.textContent = h+':'+(m<10?'0':'')+m; }
            else if (el.step && parseFloat(el.step) >= 1) valEl.textContent = Math.round(v).toString();
            else valEl.textContent = parseFloat(v).toFixed(2);
          }
        });
        if (data._tab && data._tab !== currentTab) {
          currentTab = data._tab;
          document.querySelectorAll('.tab').forEach(t => t.classList.toggle('sel', t.dataset.tab === currentTab));
          document.querySelectorAll('.props-col > [id^="tab-"]').forEach(s => s.style.display = s.id === 'tab-' + currentTab ? '' : 'none');
          g('tabBadge').textContent = currentTab.charAt(0).toUpperCase() + currentTab.slice(1);
        }
        updateCode(); drawPreview();
      }

      // Tab switching
      document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', () => {
          currentTab = tab.dataset.tab;
          document.querySelectorAll('.tab').forEach(t => t.classList.remove('sel'));
          tab.classList.add('sel');
          document.querySelectorAll('.props-col > [id^="tab-"]').forEach(s => s.style.display = 'none');
          g('tab-' + currentTab).style.display = '';
          g('tabBadge').textContent = currentTab.charAt(0).toUpperCase() + currentTab.slice(1);
          updateCode(); drawPreview();
        });
      });

      // Live value labels
      document.querySelectorAll('input[type=range]').forEach(r => {
        const valEl = g(r.id + 'Val');
        function fmt(v) {
          if (r.id === 'hour') { const h = Math.floor(v); const m = Math.round((v-h)*60); return h+':'+(m<10?'0':'')+m; }
          if (r.step && parseFloat(r.step) >= 1) return Math.round(v).toString();
          return parseFloat(v).toFixed(2);
        }
        if (valEl) { valEl.textContent = fmt(r.value); r.addEventListener('input', () => { valEl.textContent = fmt(r.value); undo.push(snap()); markDirty(); updateCode(); drawPreview(); }); }
      });
      document.querySelectorAll('input[type=color],input[type=checkbox],select').forEach(el => el.addEventListener('change', () => { undo.push(snap()); markDirty(); updateCode(); drawPreview(); }));

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
      g('todPreset').addEventListener('change', (e) => {
        const p = todPresets[e.target.value];
        if (!p) return;
        g('hour').value = p.hour;
        g('hourVal').textContent = (() => { const h=Math.floor(p.hour),m=Math.round((p.hour-h)*60); return h+':'+(m<10?'0':'')+m; })();
        g('skyColor').value = p.sky;
        g('ambientLight').value = p.ambient;
        g('ambientLightVal').textContent = p.ambient.toFixed(2);
        g('sunColor').value = p.sun;
        undo.push(snap()); markDirty(); updateCode(); drawPreview();
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
      g('weatherPreset').addEventListener('change', (e) => {
        const p = wPresets[e.target.value];
        if (!p) return;
        ['intensity','windX','windY'].forEach(k => {
          const el = g('weather'+k.charAt(0).toUpperCase()+k.slice(1)) || g(k);
          if (el && p[k] !== undefined) { el.value = p[k]; const v = g(el.id+'Val'); if(v) v.textContent = p[k]; }
        });
        if(p.color) g('weatherColor').value = p.color;
        if(p.fogDensity !== undefined) { g('fogDensity').value = p.fogDensity; g('fogDensityVal').textContent = p.fogDensity.toFixed(2); }
        undo.push(snap()); markDirty(); updateCode(); drawPreview();
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
      g('overlayPreset').addEventListener('change', (e) => {
        const p = oPresets[e.target.value]; if(!p) return;
        g('overlayColor').value = p.color;
        g('overlayAlpha').value = p.alpha;
        g('overlayAlphaVal').textContent = p.alpha.toFixed(2);
        g('overlayPulsate').checked = !!p.pulsate;
        if(p.speed) { g('overlayPulseSpeed').value = p.speed; g('overlayPulseSpeedVal').textContent = p.speed.toFixed(1); }
        undo.push(snap()); markDirty(); updateCode(); drawPreview();
      });

      function countEffects() {
        let n = 0;
        if (currentTab === 'weather' && g('weatherPreset').value !== 'Clear') n++;
        if (currentTab === 'weather' && fv('fogDensity') > 0) n++;
        if (currentTab === 'screen') {
          if (fv('vignette') > 0) n++; if (fv('scanlines') > 0) n++; if (fv('saturation') !== 1) n++;
          if (fv('brightness') !== 1) n++; if (fv('contrast') !== 1) n++; if (fv('chromatic') > 0) n++;
          if (fv('pixelSize') > 1) n++; if (fv('filmGrain') > 0) n++; if (fv('bloom') > 0) n++;
        }
        if (currentTab === 'overlay' && g('overlayPreset').value !== 'None') n++;
        if (currentTab === 'shake') n++;
        if (currentTab === 'timeofday') n++;
        return n;
      }

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
            code += 'local weather = lurek.effect.createWeather({\\n';
            code += '  preset   = "' + preset.toLowerCase().replace(/ /g,'_') + '",\\n';
            code += '  intensity = ' + intensity.toFixed(2) + ',\\n';
            code += '  wind      = lurek.math.vec2(' + windX + ', ' + windY + '),\\n';
            code += '  color     = lurek.graphic.newColor("' + color + '"),\\n';
            code += '})\\n\\n';
            code += 'function lurek.process(dt)\\n  weather:update(dt)\\nend\\n';
            code += 'function lurek.draw()\n  weather:draw()\n';
            if (fogDensity > 0) code += '  lurek.effect.fog({ density=' + fogDensity.toFixed(2) + ', color=lurek.graphic.newColor("' + fogColor + '") })\\n';
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
          code += 'local tod = lurek.effect.createTimeOfDay({\\n';
          code += '  hour         = ' + hour.toFixed(2) + ',\\n';
          code += '  sky_color    = lurek.graphic.newColor("' + sky + '"),\\n';
          code += '  sun_color    = lurek.graphic.newColor("' + sun + '"),\\n';
          code += '  ambient      = ' + ambient.toFixed(2) + ',\\n';
          code += '  moon_enabled = ' + moon + ',\\n';
          code += '  stars        = ' + stars + ',\\n';
          code += '  speed        = ' + speed.toFixed(3) + ',\\n';
          code += '})\\n\\n';
          code += 'function lurek.process(dt)\\n  tod:update(dt)\\nend\\n';
          code += 'function lurek.draw()\n  tod:drawSky()\n  -- draw game world here\n  tod:drawOverlay()\nend';
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
          code = '-- Screen PostFX\nfunction lurek.draw()\n  -- draw game\n  local fx = lurek.effect.begin()\n';
          if (vig > 0)    lines.push('  fx:vignette({ strength=' + vig.toFixed(2) + ', color=lurek.graphic.newColor("' + g('vignetteColor').value + '") })');
          if (scan > 0)   lines.push('  fx:scanlines({ alpha=' + scan.toFixed(2) + ' })');
          if (sat !== 1)  lines.push('  fx:saturation(' + sat.toFixed(2) + ')');
          if (bright !== 1) lines.push('  fx:brightness(' + bright.toFixed(2) + ')');
          if (cont !== 1) lines.push('  fx:contrast(' + cont.toFixed(2) + ')');
          if (chrom > 0)  lines.push('  fx:chromaticAberration(' + chrom.toFixed(1) + ')');
          if (px > 1)     lines.push('  fx:pixelate(' + px + ')');
          if (grain > 0)  lines.push('  fx:filmGrain(' + grain.toFixed(2) + ')');
          if (bloom_ > 0) lines.push('  fx:bloom({ threshold=0.7, strength=' + bloom_.toFixed(2) + ' })');
          code += lines.join('\\n') + '\\n  lurek.effect.finish(fx)\\nend';
        } else if (currentTab === 'shake') {
          const amp = fv('shakeAmplitude'), freq = fv('shakeFrequency');
          const dur = fv('shakeDuration'), decay = fv('shakeDecay');
          const rot = fv('shakeRotation');
          const trauma = g('shakeTrauma').checked;
          code = '-- Camera Shake\\n';
          code += 'local shaker = lurek.camera.createShaker({\\n';
          code += '  amplitude  = ' + amp.toFixed(1) + ',\\n';
          code += '  frequency  = ' + freq + ',\\n';
          code += '  duration   = ' + dur.toFixed(2) + ',\\n';
          code += '  decay      = ' + decay.toFixed(1) + ',\\n';
          code += '  rotation   = ' + rot.toFixed(1) + ',\\n';
          code += '  trauma     = ' + trauma + ',\\n';
          code += '})\\n\\n';
          code += '-- Trigger a shake (e.g. on explosion):\\nshaker:shake()\\n\\n';
          code += 'function lurek.process(dt)\\n  shaker:update(dt)\\nend\\n';
          code += 'function lurek.draw()\n  shaker:push()\n  -- draw everything here\n  shaker:pop()\nend';
        } else if (currentTab === 'overlay') {
          const preset = g('overlayPreset').value;
          const alpha = fv('overlayAlpha');
          const color = g('overlayColor').value;
          const pulse = g('overlayPulsate').checked;
          const speed = fv('overlayPulseSpeed');
          code = '-- Overlay: ' + preset + '\\n';
          code += 'local overlay = lurek.effect.createOverlay({\\n';
          code += '  preset  = "' + preset.toLowerCase().replace(/ /g,'_') + '",\\n';
          code += '  color   = lurek.graphic.newColor("' + color + '"),\\n';
          code += '  alpha   = ' + alpha.toFixed(2) + ',\\n';
          code += '  pulsate = ' + pulse + ',\\n';
          if (pulse) code += '  speed   = ' + speed.toFixed(1) + ',\\n';
          code += '})\\n\\n';
          code += 'function lurek.process(dt)\\n  overlay:update(dt)\\nend\\n';
          code += 'function lurek.draw()\n  -- draw game\n  overlay:draw()\nend';
        }
        g('codeOut').textContent = code;
        g('effectCount').textContent = countEffects() + ' effect' + (countEffects() !== 1 ? 's' : '');
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
          ctx.fillStyle = '#2d4a1e'; ctx.fillRect(0,H*0.7,W,H*0.3);
          const hour = fv('hour');
          const sunX = (hour/24)*W;
          const sunY = H*0.5 - Math.sin((hour/24)*Math.PI)*H*0.4;
          if (hour > 5 && hour < 20) {
            ctx.beginPath(); ctx.arc(sunX,sunY,20,0,Math.PI*2);
            ctx.fillStyle = g('sunColor').value; ctx.fill();
          }
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
          ctx.fillStyle = '#1e2d3a'; ctx.fillRect(0,0,W,H);
          ctx.fillStyle = '#2d4a1e'; ctx.fillRect(0,H*0.65,W,H*0.35);
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

      g('btnCopy').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyCode', code: g('codeOut').textContent });
      });
      g('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertCode', code: g('codeOut').textContent });
      });
      g('btnExport').addEventListener('click', () => {
        vscode.postMessage({ type: 'exportLua', code: g('codeOut').textContent });
      });

      registerShortcut('ctrl+z', () => load(undo.undo()));
      registerShortcut('ctrl+shift+z', () => load(undo.redo()));
      registerShortcut('ctrl+s', () => g('btnExport').click());

      undo.push(snap());
      updateCode(); drawPreview();
    `);
  }
}
