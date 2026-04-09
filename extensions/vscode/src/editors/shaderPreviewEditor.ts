import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class ShaderPreviewEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): ShaderPreviewEditor {
    return new ShaderPreviewEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "luna.shaderPreviewEditor", "Shader Preview");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "shader.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Shader Preview", `
      .editor-layout {
        display: grid; grid-template-columns: 1fr 1fr;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .code-area { grid-row: 2; display: flex; flex-direction: column; border-right: 1px solid var(--border); }
      .preview-area { grid-row: 2; display: flex; flex-direction: column; }
      .status-bar { grid-column: 1 / -1; }
      .code-editor {
        flex: 1; background: var(--bg); color: #d4d4d4; font-family: 'Consolas', 'Courier New', monospace;
        font-size: 13px; line-height: 1.5; padding: 10px; border: none; resize: none;
        tab-size: 2; white-space: pre; overflow: auto;
      }
      .code-editor:focus { outline: none; }
      .preview-canvas-wrapper { flex: 1; display: flex; align-items: center; justify-content: center; background: #111; }
      .params-bar {
        padding: 8px; background: var(--surface); border-top: 1px solid var(--border);
        display: flex; flex-wrap: wrap; gap: 8px; align-items: center;
      }
      .param-item { display: flex; align-items: center; gap: 4px; font-size: 11px; }
      .param-item input[type="range"] { width: 80px; }
      .error-bar {
        padding: 4px 10px; background: rgba(244,67,54,0.15); color: var(--danger);
        font-family: monospace; font-size: 11px; white-space: pre-wrap; max-height: 60px; overflow-y: auto;
      }
      .preset-btn { font-size: 11px; padding: 2px 8px; }
      .perf-stat { font-family: monospace; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <label>Preset:</label>
          <button class="preset-btn active" data-preset="blur">Blur</button>
          <button class="preset-btn" data-preset="glow">Glow</button>
          <button class="preset-btn" data-preset="dissolve">Dissolve</button>
          <button class="preset-btn" data-preset="pixel">Pixelate</button>
          <button class="preset-btn" data-preset="wave">Wave</button>
          <button class="preset-btn" data-preset="custom">Custom</button>
          <div class="sep"></div>
          <button id="btnRun">&#9654; Run</button>
          <button id="btnPause">&#10074;&#10074;</button>
          <div class="sep"></div>
          <button id="btnExport">Export</button>
        </div>

        <div class="code-area">
          <textarea class="code-editor" id="codeEditor" spellcheck="false"></textarea>
          <div class="error-bar" id="errorBar" style="display:none;"></div>
        </div>

        <div class="preview-area">
          <div class="preview-canvas-wrapper">
            <canvas id="previewCanvas" width="400" height="300"></canvas>
          </div>
          <div class="params-bar" id="paramsBar"></div>
        </div>

        <div class="status-bar">
          <span id="statusPreset">Preset: blur</span>
          <span class="perf-stat" id="perfFps">FPS: --</span>
          <span class="perf-stat" id="perfTime">Frame: -- ms</span>
        </div>
      </div>
    `, `
      const canvas = document.getElementById('previewCanvas');
      const ctx = canvas.getContext('2d');
      const editor = document.getElementById('codeEditor');
      let running = true;
      let frameCount = 0;
      let lastFpsTime = performance.now();
      let currentPreset = 'blur';

      const PRESETS = {
        blur: {
          code: '-- Gaussian Blur Shader\\n-- Uniforms: radius, intensity\\n\\nfunction effect(pixel, x, y, uniforms)\\n  local r = uniforms.radius or 3\\n  local sum_r, sum_g, sum_b = 0, 0, 0\\n  local count = 0\\n  for dy = -r, r do\\n    for dx = -r, r do\\n      local p = getPixel(x + dx, y + dy)\\n      sum_r = sum_r + p.r\\n      sum_g = sum_g + p.g\\n      sum_b = sum_b + p.b\\n      count = count + 1\\n    end\\n  end\\n  return {\\n    r = sum_r / count,\\n    g = sum_g / count,\\n    b = sum_b / count,\\n    a = pixel.a\\n  }\\nend',
          params: [{ name: 'radius', min: 1, max: 20, value: 3 }, { name: 'intensity', min: 0, max: 100, value: 50 }],
        },
        glow: {
          code: '-- Glow Shader\\n-- Uniforms: threshold, strength, color\\n\\nfunction effect(pixel, x, y, uniforms)\\n  local lum = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114\\n  local t = uniforms.threshold or 0.5\\n  local s = (uniforms.strength or 50) / 100\\n  if lum > t then\\n    return {\\n      r = math.min(1, pixel.r + pixel.r * s),\\n      g = math.min(1, pixel.g + pixel.g * s),\\n      b = math.min(1, pixel.b + pixel.b * s),\\n      a = pixel.a\\n    }\\n  end\\n  return pixel\\nend',
          params: [{ name: 'threshold', min: 0, max: 100, value: 50 }, { name: 'strength', min: 0, max: 100, value: 50 }],
        },
        dissolve: {
          code: '-- Dissolve Shader\\n-- Uniforms: progress, edge_width\\n\\nfunction effect(pixel, x, y, uniforms)\\n  local noise = math.sin(x * 12.9898 + y * 78.233) * 43758.5453\\n  noise = noise - math.floor(noise)\\n  local p = (uniforms.progress or 50) / 100\\n  if noise < p then\\n    return { r = 0, g = 0, b = 0, a = 0 }\\n  end\\n  local edge = (uniforms.edge_width or 10) / 100\\n  if noise < p + edge then\\n    return { r = 1, g = 0.5, b = 0, a = pixel.a }\\n  end\\n  return pixel\\nend',
          params: [{ name: 'progress', min: 0, max: 100, value: 30 }, { name: 'edge_width', min: 0, max: 50, value: 10 }],
        },
        pixel: {
          code: '-- Pixelate Shader\\n-- Uniforms: size\\n\\nfunction effect(pixel, x, y, uniforms)\\n  local s = math.max(1, uniforms.size or 8)\\n  local bx = math.floor(x / s) * s + s / 2\\n  local by = math.floor(y / s) * s + s / 2\\n  return getPixel(bx, by)\\nend',
          params: [{ name: 'size', min: 1, max: 32, value: 8 }],
        },
        wave: {
          code: '-- Wave Distortion Shader\\n-- Uniforms: amplitude, frequency, speed\\n\\nfunction effect(pixel, x, y, uniforms)\\n  local amp = (uniforms.amplitude or 10)\\n  local freq = (uniforms.frequency or 20) / 100\\n  local t = luna.timer.getTime()\\n  local offset = math.sin(y * freq + t) * amp\\n  return getPixel(x + offset, y)\\nend',
          params: [{ name: 'amplitude', min: 0, max: 50, value: 10 }, { name: 'frequency', min: 1, max: 100, value: 20 }, { name: 'speed', min: 1, max: 100, value: 50 }],
        },
        custom: {
          code: '-- Custom Shader\\n-- Write your own pixel effect here\\n\\nfunction effect(pixel, x, y, uniforms)\\n  return pixel\\nend',
          params: [{ name: 'param1', min: 0, max: 100, value: 50 }, { name: 'param2', min: 0, max: 100, value: 50 }],
        },
      };

      let params = {};

      function loadPreset(name) {
        currentPreset = name;
        const preset = PRESETS[name];
        editor.value = preset.code;
        params = {};
        preset.params.forEach(p => { params[p.name] = p.value; });
        buildParams(preset.params);
        document.getElementById('statusPreset').textContent = 'Preset: ' + name;
        document.getElementById('errorBar').style.display = 'none';
        document.querySelectorAll('.preset-btn').forEach(b => b.classList.toggle('active', b.dataset.preset === name));
      }

      function buildParams(paramDefs) {
        const bar = document.getElementById('paramsBar');
        bar.innerHTML = '';
        paramDefs.forEach(p => {
          const item = document.createElement('div');
          item.className = 'param-item';
          item.innerHTML = '<label>' + p.name + '</label><input type="range" min="' + p.min + '" max="' + p.max + '" value="' + p.value + '" data-p="' + p.name + '"><span>' + p.value + '</span>';
          item.querySelector('input').addEventListener('input', (e) => {
            const v = parseInt(e.target.value);
            params[p.name] = v;
            e.target.nextElementSibling.textContent = v;
          });
          bar.appendChild(item);
        });
      }

      // Simple preview: draw a colorful pattern and show effect visually
      let time = 0;
      function renderPreview() {
        if (!running) return;
        const t0 = performance.now();
        const w = canvas.width, h = canvas.height;
        const imgData = ctx.createImageData(w, h);
        for (let y = 0; y < h; y++) {
          for (let x = 0; x < w; x++) {
            const i = (y * w + x) * 4;
            // Base pattern: gradient + circles
            const cx = w/2, cy = h/2;
            const dist = Math.sqrt((x-cx)*(x-cx) + (y-cy)*(y-cy));
            const wave = Math.sin(dist * 0.05 - time * 0.02) * 0.5 + 0.5;
            let r = Math.floor((x / w) * 200 * wave + 55);
            let g = Math.floor((y / h) * 200 * wave + 55);
            let b = Math.floor(128 + 127 * Math.sin(time * 0.01 + x * 0.02));

            // Apply simple param-based effects for visual demo
            if (currentPreset === 'pixel') {
              const s = Math.max(1, params.size || 8);
              const bx = Math.floor(x / s) * s;
              const by = Math.floor(y / s) * s;
              const bd = Math.sqrt((bx-cx)*(bx-cx) + (by-cy)*(by-cy));
              const bw = Math.sin(bd * 0.05 - time * 0.02) * 0.5 + 0.5;
              r = Math.floor((bx / w) * 200 * bw + 55);
              g = Math.floor((by / h) * 200 * bw + 55);
            } else if (currentPreset === 'dissolve') {
              const noise = Math.sin(x * 12.9898 + y * 78.233) * 43758.5453;
              const n = noise - Math.floor(noise);
              const p = (params.progress || 30) / 100;
              if (n < p) { r = 0; g = 0; b = 0; }
              else if (n < p + 0.05) { r = 255; g = 128; b = 0; }
            } else if (currentPreset === 'wave') {
              const amp = params.amplitude || 10;
              const freq = (params.frequency || 20) / 100;
              const off = Math.sin(y * freq + time * 0.03) * amp;
              const sx = Math.floor(x + off);
              if (sx >= 0 && sx < w) {
                const sd = Math.sqrt((sx-cx)*(sx-cx) + (y-cy)*(y-cy));
                const sw = Math.sin(sd * 0.05 - time * 0.02) * 0.5 + 0.5;
                r = Math.floor((sx / w) * 200 * sw + 55);
              }
            }

            imgData.data[i] = Math.min(255, Math.max(0, r));
            imgData.data[i+1] = Math.min(255, Math.max(0, g));
            imgData.data[i+2] = Math.min(255, Math.max(0, b));
            imgData.data[i+3] = 255;
          }
        }
        ctx.putImageData(imgData, 0, 0);
        time++;
        frameCount++;

        const elapsed = performance.now() - t0;
        document.getElementById('perfTime').textContent = 'Frame: ' + elapsed.toFixed(1) + ' ms';
        const now = performance.now();
        if (now - lastFpsTime >= 1000) {
          document.getElementById('perfFps').textContent = 'FPS: ' + frameCount;
          frameCount = 0;
          lastFpsTime = now;
        }
        requestAnimationFrame(renderPreview);
      }

      document.querySelectorAll('.preset-btn').forEach(btn => {
        btn.addEventListener('click', () => loadPreset(btn.dataset.preset));
      });

      document.getElementById('btnRun').addEventListener('click', () => {
        running = true;
        renderPreview();
      });
      document.getElementById('btnPause').addEventListener('click', () => { running = false; });

      document.getElementById('btnExport').addEventListener('click', () => {
        vscode.postMessage({ type: 'exportLua', content: editor.value });
      });

      loadPreset('blur');
      renderPreview();
    `);
  }
}
