import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class SpriteAnimEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): SpriteAnimEditor {
    return new SpriteAnimEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "luna.spriteAnimEditor", "Sprite Animation");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "animation.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Sprite Animation", `
      .editor-layout {
        display: grid; grid-template-columns: 240px 1fr 220px;
        grid-template-rows: auto 1fr auto auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .frame-list { grid-row: 2; overflow-y: auto; }
      .preview-area { grid-row: 2; display: flex; align-items: center; justify-content: center; background: var(--bg); position: relative; }
      .props-panel { grid-row: 2; }
      .timeline { grid-column: 1 / -1; background: var(--surface); border-top: 1px solid var(--border); padding: 8px; min-height: 120px; }
      .status-bar { grid-column: 1 / -1; }
      .frame-item {
        display: flex; align-items: center; gap: 6px; padding: 4px 8px;
        cursor: pointer; border-radius: 3px; font-size: 12px;
      }
      .frame-item:hover { background: var(--surface-2); }
      .frame-item.selected { background: var(--selection); }
      .frame-thumb { width: 32px; height: 32px; background: var(--surface-2); border: 1px solid var(--border); border-radius: 2px; }
      .playback-controls { display: flex; align-items: center; gap: 4px; }
      .timeline-track {
        display: flex; gap: 2px; padding: 6px 0; overflow-x: auto;
      }
      .timeline-frame {
        width: 40px; height: 40px; background: var(--surface-2); border: 1px solid var(--border);
        border-radius: 2px; cursor: pointer; flex-shrink: 0; position: relative;
        display: flex; align-items: center; justify-content: center; font-size: 10px; color: var(--text-dim);
      }
      .timeline-frame.active { border-color: var(--accent); }
      .tag-list { display: flex; flex-wrap: wrap; gap: 4px; margin-top: 4px; }
      .tag {
        background: var(--accent); color: #fff; padding: 1px 6px; border-radius: 8px;
        font-size: 10px; cursor: pointer;
      }
      .tag .remove { margin-left: 4px; opacity: 0.7; }
      .tag .remove:hover { opacity: 1; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnLoadSheet">Load Sheet</button>
          <div class="sep"></div>
          <label>Cols:</label><input type="number" id="cols" value="4" min="1" max="64" style="width:45px">
          <label>Rows:</label><input type="number" id="rows" value="4" min="1" max="64" style="width:45px">
          <div class="sep"></div>
          <div class="playback-controls">
            <button id="btnFirst">&#9198;</button>
            <button id="btnPrev">&#9664;</button>
            <button id="btnPlay">&#9654; Play</button>
            <button id="btnNext">&#9654;</button>
            <button id="btnLast">&#9197;</button>
          </div>
          <div class="sep"></div>
          <label>Speed:</label>
          <input type="range" id="speed" min="1" max="60" value="12" style="width:80px">
          <span id="speedLabel">12 fps</span>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>

        <div class="panel frame-list">
          <h3>Frames</h3>
          <div id="frameList"></div>
          <div style="margin-top:8px;">
            <button id="btnAddFrame">+ Add Frame</button>
          </div>
        </div>

        <div class="preview-area">
          <canvas id="previewCanvas" width="256" height="256"></canvas>
        </div>

        <div class="panel props-panel">
          <div class="section">
            <h3>Frame Properties</h3>
            <div class="field"><label>Duration (ms)</label><input type="number" id="frameDuration" value="100" min="16" max="5000"></div>
            <div class="field"><label>Origin X</label><input type="number" id="originX" value="0"></div>
            <div class="field"><label>Origin Y</label><input type="number" id="originY" value="0"></div>
          </div>
          <div class="section">
            <h3>Animation</h3>
            <div class="field"><label>Name</label><input type="text" id="animName" value="idle"></div>
            <div class="field-row"><input type="checkbox" id="looping" checked><label for="looping">Loop</label></div>
          </div>
          <div class="section">
            <h3>Tags</h3>
            <div class="tag-list" id="tagList"></div>
            <div class="field-row" style="margin-top:4px;">
              <input type="text" id="newTag" placeholder="New tag..." style="flex:1">
              <button id="btnAddTag">+</button>
            </div>
          </div>
        </div>

        <div class="timeline">
          <h3>Timeline</h3>
          <div class="timeline-track" id="timelineTrack"></div>
        </div>

        <div class="status-bar">
          <span id="statusFrame">Frame: 1/16</span>
          <span id="statusSize">Sheet: 4x4</span>
          <span id="statusAnim">Anim: idle</span>
        </div>
      </div>
    `, `
      let cols = 4, rows = 4;
      let frames = [];
      let currentFrame = 0;
      let playing = false;
      let playTimer = null;
      let fps = 12;
      let tags = [];

      const canvas = document.getElementById('previewCanvas');
      const ctx = canvas.getContext('2d');

      function initFrames() {
        frames = [];
        for (let i = 0; i < cols * rows; i++) {
          frames.push({ id: i, duration: 100, originX: 0, originY: 0 });
        }
        currentFrame = 0;
        rebuildUI();
      }

      function rebuildUI() {
        // Frame list
        const list = document.getElementById('frameList');
        list.innerHTML = '';
        frames.forEach((f, i) => {
          const el = document.createElement('div');
          el.className = 'frame-item' + (i === currentFrame ? ' selected' : '');
          el.innerHTML = '<div class="frame-thumb"></div><span>Frame ' + (i+1) + ' (' + f.duration + 'ms)</span>';
          el.addEventListener('click', () => { currentFrame = i; rebuildUI(); });
          list.appendChild(el);
        });
        // Timeline
        const track = document.getElementById('timelineTrack');
        track.innerHTML = '';
        frames.forEach((f, i) => {
          const el = document.createElement('div');
          el.className = 'timeline-frame' + (i === currentFrame ? ' active' : '');
          el.textContent = String(i + 1);
          el.addEventListener('click', () => { currentFrame = i; rebuildUI(); });
          track.appendChild(el);
        });
        // Props
        if (frames[currentFrame]) {
          document.getElementById('frameDuration').value = frames[currentFrame].duration;
          document.getElementById('originX').value = frames[currentFrame].originX;
          document.getElementById('originY').value = frames[currentFrame].originY;
        }
        // Status
        document.getElementById('statusFrame').textContent = 'Frame: ' + (currentFrame+1) + '/' + frames.length;
        document.getElementById('statusSize').textContent = 'Sheet: ' + cols + 'x' + rows;
        renderPreview();
      }

      function renderPreview() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        const fw = canvas.width / cols;
        const fh = canvas.height / rows;
        // Draw grid
        ctx.strokeStyle = '#3c3c3c';
        for (let r = 0; r < rows; r++) {
          for (let c = 0; c < cols; c++) {
            ctx.strokeRect(c * fw, r * fh, fw, fh);
          }
        }
        // Highlight current frame
        const fc = currentFrame % cols;
        const fr = Math.floor(currentFrame / cols);
        ctx.fillStyle = 'rgba(0, 122, 204, 0.3)';
        ctx.fillRect(fc * fw, fr * fh, fw, fh);
        ctx.strokeStyle = '#007acc';
        ctx.lineWidth = 2;
        ctx.strokeRect(fc * fw, fr * fh, fw, fh);
        ctx.lineWidth = 1;
      }

      document.getElementById('btnPlay').addEventListener('click', () => {
        playing = !playing;
        document.getElementById('btnPlay').textContent = playing ? '\\u23F8 Pause' : '\\u25B6 Play';
        if (playing) {
          playTimer = setInterval(() => {
            currentFrame = (currentFrame + 1) % frames.length;
            rebuildUI();
          }, 1000 / fps);
        } else {
          clearInterval(playTimer);
        }
      });

      document.getElementById('btnPrev').addEventListener('click', () => {
        currentFrame = (currentFrame - 1 + frames.length) % frames.length;
        rebuildUI();
      });
      document.getElementById('btnNext').addEventListener('click', () => {
        currentFrame = (currentFrame + 1) % frames.length;
        rebuildUI();
      });
      document.getElementById('btnFirst').addEventListener('click', () => { currentFrame = 0; rebuildUI(); });
      document.getElementById('btnLast').addEventListener('click', () => { currentFrame = frames.length - 1; rebuildUI(); });

      document.getElementById('speed').addEventListener('input', (e) => {
        fps = parseInt(e.target.value);
        document.getElementById('speedLabel').textContent = fps + ' fps';
        if (playing) {
          clearInterval(playTimer);
          playTimer = setInterval(() => {
            currentFrame = (currentFrame + 1) % frames.length;
            rebuildUI();
          }, 1000 / fps);
        }
      });

      document.getElementById('cols').addEventListener('change', (e) => { cols = parseInt(e.target.value); initFrames(); });
      document.getElementById('rows').addEventListener('change', (e) => { rows = parseInt(e.target.value); initFrames(); });

      document.getElementById('frameDuration').addEventListener('change', (e) => {
        if (frames[currentFrame]) frames[currentFrame].duration = parseInt(e.target.value);
      });
      document.getElementById('originX').addEventListener('change', (e) => {
        if (frames[currentFrame]) frames[currentFrame].originX = parseInt(e.target.value);
      });
      document.getElementById('originY').addEventListener('change', (e) => {
        if (frames[currentFrame]) frames[currentFrame].originY = parseInt(e.target.value);
      });

      document.getElementById('btnAddFrame').addEventListener('click', () => {
        frames.push({ id: frames.length, duration: 100, originX: 0, originY: 0 });
        currentFrame = frames.length - 1;
        rebuildUI();
      });

      document.getElementById('btnAddTag').addEventListener('click', () => {
        const input = document.getElementById('newTag');
        const val = input.value.trim();
        if (val && !tags.includes(val)) {
          tags.push(val);
          input.value = '';
          renderTags();
        }
      });

      function renderTags() {
        const list = document.getElementById('tagList');
        list.innerHTML = '';
        tags.forEach((t, i) => {
          const el = document.createElement('span');
          el.className = 'tag';
          el.innerHTML = t + '<span class="remove">x</span>';
          el.querySelector('.remove').addEventListener('click', () => { tags.splice(i, 1); renderTags(); });
          list.appendChild(el);
        });
      }

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        lua += '  name = "' + document.getElementById('animName').value + '",\\n';
        lua += '  loop = ' + document.getElementById('looping').checked + ',\\n';
        lua += '  cols = ' + cols + ', rows = ' + rows + ',\\n';
        lua += '  tags = {' + tags.map(t => '"' + t + '"').join(', ') + '},\\n';
        lua += '  frames = {\\n';
        frames.forEach((f, i) => {
          lua += '    { id = ' + (i+1) + ', duration = ' + f.duration + ', ox = ' + f.originX + ', oy = ' + f.originY + ' },\\n';
        });
        lua += '  }\\n}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      initFrames();
      renderTags();
    `);
  }
}
