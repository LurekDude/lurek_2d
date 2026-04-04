import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class ColorPaletteEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): ColorPaletteEditor {
    return new ColorPaletteEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "luna.colorPaletteEditor", "Color Palette");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "palette.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Color Palette", `
      .editor-layout {
        display: grid; grid-template-columns: 280px 1fr 240px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .picker-panel { grid-row: 2; }
      .palette-area { grid-row: 2; padding: 12px; overflow-y: auto; }
      .harmony-panel { grid-row: 2; }
      .status-bar { grid-column: 1 / -1; }
      .color-preview {
        width: 100%; height: 80px; border-radius: 4px; border: 1px solid var(--border); margin-bottom: 8px;
      }
      .slider-group { margin-bottom: 8px; }
      .slider-group label { display: flex; justify-content: space-between; }
      .slider-group input[type="range"] { width: 100%; }
      .hex-input { width: 100%; font-family: monospace; font-size: 14px; text-align: center; }
      .palette-grid {
        display: grid; grid-template-columns: repeat(8, 1fr); gap: 4px;
      }
      .swatch {
        aspect-ratio: 1; border-radius: 4px; border: 2px solid transparent;
        cursor: pointer; position: relative; min-height: 36px;
      }
      .swatch:hover { border-color: var(--text); }
      .swatch.selected { border-color: var(--accent); box-shadow: 0 0 0 2px var(--accent); }
      .swatch-label {
        position: absolute; bottom: 1px; left: 0; right: 0; text-align: center;
        font-size: 8px; color: #fff; text-shadow: 0 0 2px #000;
      }
      .harmony-wheel {
        width: 180px; height: 180px; border-radius: 50%; margin: 10px auto;
        background: conic-gradient(red, yellow, lime, cyan, blue, magenta, red);
        position: relative;
      }
      .harmony-dot {
        width: 12px; height: 12px; border-radius: 50%; border: 2px solid #fff;
        position: absolute; transform: translate(-50%,-50%); box-shadow: 0 0 4px rgba(0,0,0,0.5);
      }
      .contrast-badge {
        display: inline-block; padding: 2px 8px; border-radius: 3px; font-size: 11px; font-weight: bold;
      }
      .contrast-pass { background: var(--success); color: #fff; }
      .contrast-fail { background: var(--danger); color: #fff; }
      .harmony-swatches { display: flex; gap: 4px; margin-top: 8px; justify-content: center; }
      .harmony-swatch { width: 28px; height: 28px; border-radius: 4px; border: 1px solid var(--border); cursor: pointer; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAddColor">+ Add Color</button>
          <button id="btnRemoveColor" class="danger">Remove</button>
          <div class="sep"></div>
          <label>Mode:</label>
          <select id="colorMode">
            <option value="hsl">HSL</option>
            <option value="rgb">RGB</option>
            <option value="hsv">HSV</option>
          </select>
          <div class="sep"></div>
          <button id="btnSortHue">Sort by Hue</button>
          <button id="btnSortLight">Sort by Lightness</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>

        <div class="panel picker-panel">
          <div class="section">
            <h3>Color Picker</h3>
            <div class="color-preview" id="colorPreview"></div>
            <div class="field"><input type="text" class="hex-input" id="hexInput" value="#007ACC"></div>
          </div>
          <div class="section" id="slidersHSL">
            <div class="slider-group">
              <label>H <span id="hVal">210</span></label>
              <input type="range" id="hSlider" min="0" max="360" value="210">
            </div>
            <div class="slider-group">
              <label>S <span id="sVal">100</span></label>
              <input type="range" id="sSlider" min="0" max="100" value="100">
            </div>
            <div class="slider-group">
              <label>L <span id="lVal">40</span></label>
              <input type="range" id="lSlider" min="0" max="100" value="40">
            </div>
            <div class="slider-group">
              <label>A <span id="aVal">255</span></label>
              <input type="range" id="aSlider" min="0" max="255" value="255">
            </div>
          </div>
          <div class="section">
            <h3>Accessibility</h3>
            <div id="contrastInfo" style="font-size:11px;">
              <p>On white: <span id="contrastWhite" class="contrast-badge">--</span></p>
              <p style="margin-top:4px;">On black: <span id="contrastBlack" class="contrast-badge">--</span></p>
            </div>
          </div>
        </div>

        <div class="palette-area">
          <h3 style="margin-bottom:8px;">Palette (<span id="paletteCount">0</span>/64)</h3>
          <div class="palette-grid" id="paletteGrid"></div>
        </div>

        <div class="panel harmony-panel">
          <div class="section">
            <h3>Harmony</h3>
            <select id="harmonyType" style="width:100%;">
              <option value="complementary">Complementary</option>
              <option value="triadic">Triadic</option>
              <option value="analogous">Analogous</option>
              <option value="split">Split-Complementary</option>
              <option value="tetradic">Tetradic</option>
            </select>
            <div class="harmony-wheel" id="harmonyWheel"></div>
            <div class="harmony-swatches" id="harmonySwatches"></div>
            <button id="btnApplyHarmony" style="width:100%;margin-top:6px;">Add Harmony Colors</button>
          </div>
        </div>

        <div class="status-bar">
          <span id="statusColor">Color: #007ACC</span>
          <span id="statusIndex">Index: 0</span>
          <span id="statusCount">Total: 0</span>
        </div>
      </div>
    `, `
      let palette = [];
      let selectedIdx = -1;
      let h = 210, s = 100, l = 40, a = 255;

      function hslToHex(h, s, l) {
        s /= 100; l /= 100;
        const k = n => (n + h / 30) % 12;
        const a2 = s * Math.min(l, 1 - l);
        const f = n => l - a2 * Math.max(-1, Math.min(k(n) - 3, 9 - k(n), 1));
        const toHex = v => Math.round(v * 255).toString(16).padStart(2, '0');
        return '#' + toHex(f(0)) + toHex(f(8)) + toHex(f(4));
      }

      function hexToRgb(hex) {
        const m = hex.match(/^#?([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})$/i);
        return m ? { r: parseInt(m[1],16), g: parseInt(m[2],16), b: parseInt(m[3],16) } : { r:0, g:0, b:0 };
      }

      function luminance(r, g, b) {
        const [rs, gs, bs] = [r, g, b].map(c => { c /= 255; return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); });
        return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs;
      }

      function contrastRatio(l1, l2) {
        const lighter = Math.max(l1, l2), darker = Math.min(l1, l2);
        return (lighter + 0.05) / (darker + 0.05);
      }

      function updateColor() {
        const hex = hslToHex(h, s, l);
        document.getElementById('colorPreview').style.background = hex;
        document.getElementById('hexInput').value = hex;
        document.getElementById('hVal').textContent = h;
        document.getElementById('sVal').textContent = s;
        document.getElementById('lVal').textContent = l;
        document.getElementById('aVal').textContent = a;
        document.getElementById('statusColor').textContent = 'Color: ' + hex;

        // Contrast
        const rgb = hexToRgb(hex);
        const lum = luminance(rgb.r, rgb.g, rgb.b);
        const crWhite = contrastRatio(1, lum).toFixed(1);
        const crBlack = contrastRatio(lum, 0).toFixed(1);
        const eWhite = document.getElementById('contrastWhite');
        const eBlack = document.getElementById('contrastBlack');
        eWhite.textContent = crWhite + ':1';
        eWhite.className = 'contrast-badge ' + (crWhite >= 4.5 ? 'contrast-pass' : 'contrast-fail');
        eBlack.textContent = crBlack + ':1';
        eBlack.className = 'contrast-badge ' + (crBlack >= 4.5 ? 'contrast-pass' : 'contrast-fail');

        updateHarmony();
        if (selectedIdx >= 0 && selectedIdx < palette.length) {
          palette[selectedIdx] = { hex, h, s, l, a };
          renderPalette();
        }
      }

      function renderPalette() {
        const grid = document.getElementById('paletteGrid');
        grid.innerHTML = '';
        palette.forEach((c, i) => {
          const el = document.createElement('div');
          el.className = 'swatch' + (i === selectedIdx ? ' selected' : '');
          el.style.background = c.hex;
          el.innerHTML = '<span class="swatch-label">' + (i+1) + '</span>';
          el.addEventListener('click', () => {
            selectedIdx = i; h = c.h; s = c.s; l = c.l; a = c.a;
            document.getElementById('hSlider').value = h;
            document.getElementById('sSlider').value = s;
            document.getElementById('lSlider').value = l;
            document.getElementById('aSlider').value = a;
            updateColor();
            renderPalette();
            document.getElementById('statusIndex').textContent = 'Index: ' + i;
          });
          grid.appendChild(el);
        });
        document.getElementById('paletteCount').textContent = palette.length;
        document.getElementById('statusCount').textContent = 'Total: ' + palette.length;
      }

      function getHarmonyHues(type) {
        switch (type) {
          case 'complementary': return [h, (h + 180) % 360];
          case 'triadic': return [h, (h + 120) % 360, (h + 240) % 360];
          case 'analogous': return [(h - 30 + 360) % 360, h, (h + 30) % 360];
          case 'split': return [h, (h + 150) % 360, (h + 210) % 360];
          case 'tetradic': return [h, (h + 90) % 360, (h + 180) % 360, (h + 270) % 360];
          default: return [h];
        }
      }

      function updateHarmony() {
        const type = document.getElementById('harmonyType').value;
        const hues = getHarmonyHues(type);
        const wheel = document.getElementById('harmonyWheel');
        const swatches = document.getElementById('harmonySwatches');
        wheel.innerHTML = '';
        swatches.innerHTML = '';
        hues.forEach((hue) => {
          const angle = (hue - 90) * Math.PI / 180;
          const r = 80;
          const x = 90 + r * Math.cos(angle);
          const y = 90 + r * Math.sin(angle);
          const dot = document.createElement('div');
          dot.className = 'harmony-dot';
          dot.style.left = x + 'px';
          dot.style.top = y + 'px';
          dot.style.background = hslToHex(hue, s, l);
          wheel.appendChild(dot);
          const sw = document.createElement('div');
          sw.className = 'harmony-swatch';
          sw.style.background = hslToHex(hue, s, l);
          sw.addEventListener('click', () => {
            if (palette.length < 64) {
              palette.push({ hex: hslToHex(hue, s, l), h: hue, s, l, a });
              renderPalette();
            }
          });
          swatches.appendChild(sw);
        });
      }

      ['hSlider','sSlider','lSlider','aSlider'].forEach(id => {
        document.getElementById(id).addEventListener('input', (e) => {
          if (id === 'hSlider') h = parseInt(e.target.value);
          if (id === 'sSlider') s = parseInt(e.target.value);
          if (id === 'lSlider') l = parseInt(e.target.value);
          if (id === 'aSlider') a = parseInt(e.target.value);
          updateColor();
        });
      });

      document.getElementById('hexInput').addEventListener('change', (e) => {
        const rgb = hexToRgb(e.target.value);
        // Simplified re-derive HSL
        const r2 = rgb.r/255, g2 = rgb.g/255, b2 = rgb.b/255;
        const max = Math.max(r2,g2,b2), min = Math.min(r2,g2,b2);
        l = Math.round((max+min)/2*100);
        if (max !== min) {
          const d = max - min;
          s = Math.round((l > 50 ? d/(2-max-min) : d/(max+min))*100);
          if (max === r2) h = Math.round(((g2-b2)/d + (g2<b2?6:0))*60);
          else if (max === g2) h = Math.round(((b2-r2)/d+2)*60);
          else h = Math.round(((r2-g2)/d+4)*60);
        } else { s = 0; h = 0; }
        document.getElementById('hSlider').value = h;
        document.getElementById('sSlider').value = s;
        document.getElementById('lSlider').value = l;
        updateColor();
      });

      document.getElementById('btnAddColor').addEventListener('click', () => {
        if (palette.length < 64) {
          const hex = hslToHex(h, s, l);
          palette.push({ hex, h, s, l, a });
          selectedIdx = palette.length - 1;
          renderPalette();
        }
      });

      document.getElementById('btnRemoveColor').addEventListener('click', () => {
        if (selectedIdx >= 0) {
          palette.splice(selectedIdx, 1);
          selectedIdx = Math.min(selectedIdx, palette.length - 1);
          renderPalette();
        }
      });

      document.getElementById('btnSortHue').addEventListener('click', () => {
        palette.sort((a, b) => a.h - b.h);
        renderPalette();
      });
      document.getElementById('btnSortLight').addEventListener('click', () => {
        palette.sort((a, b) => a.l - b.l);
        renderPalette();
      });

      document.getElementById('harmonyType').addEventListener('change', updateHarmony);

      document.getElementById('btnApplyHarmony').addEventListener('click', () => {
        const type = document.getElementById('harmonyType').value;
        const hues = getHarmonyHues(type);
        hues.forEach(hue => {
          if (palette.length < 64) {
            palette.push({ hex: hslToHex(hue, s, l), h: hue, s, l, a });
          }
        });
        renderPalette();
      });

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        palette.forEach((c, i) => {
          const rgb = hexToRgb(c.hex);
          lua += '  { r = ' + rgb.r + ', g = ' + rgb.g + ', b = ' + rgb.b + ', a = ' + c.a + ' }, -- ' + c.hex + '\\n';
        });
        lua += '}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      updateColor();
      renderPalette();
    `);
  }
}
