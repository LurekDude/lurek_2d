import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

export class SpriteAnimEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): SpriteAnimEditor {
    return new SpriteAnimEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.spriteAnimEditor", "Sprite Animation");
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
        display: grid; grid-template-columns: 200px 1fr 200px;
        grid-template-rows: auto 1fr auto auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .frame-list { grid-row: 2; overflow-y: auto; border-right: 1px solid var(--border); background: var(--surface); padding: 4px; }
      .preview-area { grid-row: 2; display: flex; align-items: center; justify-content: center; background: var(--bg); position: relative; }
      .props-panel { grid-row: 2; overflow-y: auto; border-left: 1px solid var(--border); background: var(--surface); padding: 6px; }
      .timeline { grid-column: 1 / -1; background: var(--surface); border-top: 1px solid var(--border); padding: 6px 8px; min-height: 80px; }
      .frame-item {
        display: flex; align-items: center; gap: 6px; padding: 4px 6px;
        cursor: pointer; border-radius: var(--radius); font-size: 11px;
        border: 1px solid transparent; transition: border-color 0.1s, background 0.08s;
      }
      .frame-item:hover { border-color: var(--accent); background: var(--hover); }
      .frame-item.sel { background: var(--selection); border-color: var(--accent); }
      .frame-thumb { width: 28px; height: 28px; background: var(--surface-2); border: 1px solid var(--border); border-radius: var(--radius); }
      .timeline-track { display: flex; gap: 2px; padding: 4px 0; overflow-x: auto; }
      .timeline-frame {
        width: 36px; height: 36px; background: var(--surface-2); border: 1px solid var(--border);
        border-radius: var(--radius); cursor: pointer; flex-shrink: 0;
        display: flex; align-items: center; justify-content: center; font-size: 9px; color: var(--text-dim);
        transition: border-color 0.1s;
      }
      .timeline-frame:hover { border-color: var(--accent); }
      .timeline-frame.active { border-color: var(--accent); background: var(--selection); }
      .tag-list { display: flex; flex-wrap: wrap; gap: 3px; margin-top: 4px; }
      .anim-tag {
        background: rgba(0,122,204,0.2); color: var(--accent); padding: 1px 6px; border-radius: 9px;
        font-size: 9px; cursor: pointer; border: 1px solid var(--accent);
      }
      .anim-tag .rm { margin-left: 3px; opacity: 0.6; }
      .anim-tag .rm:hover { opacity: 1; }
      .playback-controls { display: flex; align-items: center; gap: 2px; }
      .playback-controls button { min-width: 28px; padding: 2px 6px; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${iconButton(ICONS.grid, 'btnLoadSheet', 'Load Sheet')}
          </div>
          ${toolbarSep()}
          <div class="group">
            <label>Cols:</label><input type="number" id="cols" value="4" min="1" max="64" style="width:40px">
            <label>Rows:</label><input type="number" id="rows" value="4" min="1" max="64" style="width:40px">
          </div>
          ${toolbarSep()}
          <div class="playback-controls">
            <button id="btnFirst" title="First frame">⏮</button>
            <button id="btnPrev" title="Previous frame">◀</button>
            <button id="btnPlay" title="Play/Pause">▶ Play</button>
            <button id="btnNext" title="Next frame">▶</button>
            <button id="btnLast" title="Last frame">⏭</button>
          </div>
          ${toolbarSep()}
          <label>Speed:</label>
          <input type="range" id="speed" min="1" max="60" value="12" style="width:70px">
          <span id="speedLabel" style="font-size:10px;min-width:36px">12 fps</span>
          ${toolbarSpacer()}
          ${iconButton(ICONS.save, 'btnExport', 'Export Lua')}
        </div>

        <!-- Frame List -->
        <div class="frame-list" id="frameListPanel">
          <div style="font-size:10px;font-weight:700;text-transform:uppercase;color:var(--text-dim);margin-bottom:4px">Frames</div>
          <div id="frameList"></div>
          <button id="btnAddFrame" style="margin-top:6px;width:100%">+ Add Frame</button>
        </div>

        <!-- Preview -->
        <div class="preview-area">
          <canvas id="previewCanvas" width="256" height="256"></canvas>
        </div>

        <!-- Properties -->
        <div class="props-panel">
          ${panelSection('Frame', `
            ${fieldInline('Duration (ms)', '<input type="number" id="frameDuration" value="100" min="16" max="5000">')}
            ${fieldInline('Origin X', '<input type="number" id="originX" value="0">')}
            ${fieldInline('Origin Y', '<input type="number" id="originY" value="0">')}
          `)}
          ${panelSection('Animation', `
            ${fieldInline('Name', '<input type="text" id="animName" value="idle">')}
            <div class="field-row"><input type="checkbox" id="looping" checked><label for="looping">Loop</label></div>
          `)}
          ${panelSection('Tags', `
            <div class="tag-list" id="tagList"></div>
            <div class="field-row" style="margin-top:4px">
              <input type="text" id="newTag" placeholder="New tag…" style="flex:1">
              <button id="btnAddTag" style="min-width:24px">+</button>
            </div>
          `)}
        </div>

        <!-- Timeline -->
        <div class="timeline">
          <div style="font-size:10px;font-weight:700;text-transform:uppercase;color:var(--text-dim);margin-bottom:2px">Timeline</div>
          <div class="timeline-track" id="timelineTrack"></div>
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span id="statusFrame" class="badge">Frame: 1/16</span>
          <div class="sep"></div>
          <span id="statusSize">Sheet: 4×4</span>
          <div class="sep"></div>
          <span id="statusAnim">idle</span>
          <div class="spacer"></div>
          <span id="statusDirty" style="font-size:10px;color:var(--text-dim)">${ICONS.clean}</span>
        </div>
      </div>
    `, `
      const undo = new UndoStack();
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
        const list = document.getElementById('frameList');
        list.innerHTML = '';
        frames.forEach((f, i) => {
          const el = document.createElement('div');
          el.className = 'frame-item' + (i === currentFrame ? ' sel' : '');
          el.innerHTML = '<div class="frame-thumb"></div><span>Frame ' + (i+1) + ' (' + f.duration + 'ms)</span>';
          el.addEventListener('click', () => { currentFrame = i; rebuildUI(); });
          list.appendChild(el);
        });
        const track = document.getElementById('timelineTrack');
        track.innerHTML = '';
        frames.forEach((f, i) => {
          const el = document.createElement('div');
          el.className = 'timeline-frame' + (i === currentFrame ? ' active' : '');
          el.textContent = String(i + 1);
          el.addEventListener('click', () => { currentFrame = i; rebuildUI(); });
          track.appendChild(el);
        });
        if (frames[currentFrame]) {
          document.getElementById('frameDuration').value = frames[currentFrame].duration;
          document.getElementById('originX').value = frames[currentFrame].originX;
          document.getElementById('originY').value = frames[currentFrame].originY;
        }
        document.getElementById('statusFrame').textContent = 'Frame: ' + (currentFrame+1) + '/' + frames.length;
        document.getElementById('statusSize').textContent = 'Sheet: ' + cols + '×' + rows;
        document.getElementById('statusAnim').textContent = document.getElementById('animName').value;
        renderPreview();
      }

      function renderPreview() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        const fw = canvas.width / cols;
        const fh = canvas.height / rows;
        ctx.strokeStyle = 'rgba(255,255,255,0.06)';
        for (let r = 0; r < rows; r++) {
          for (let c = 0; c < cols; c++) ctx.strokeRect(c * fw, r * fh, fw, fh);
        }
        const fc = currentFrame % cols;
        const fr = Math.floor(currentFrame / cols);
        ctx.fillStyle = 'rgba(0, 122, 204, 0.25)';
        ctx.fillRect(fc * fw, fr * fh, fw, fh);
        ctx.strokeStyle = 'var(--accent, #007acc)';
        ctx.lineWidth = 2;
        ctx.strokeRect(fc * fw, fr * fh, fw, fh);
        ctx.lineWidth = 1;
      }

      document.getElementById('btnPlay').addEventListener('click', () => {
        playing = !playing;
        document.getElementById('btnPlay').textContent = playing ? '⏸ Pause' : '▶ Play';
        if (playing) {
          playTimer = setInterval(() => { currentFrame = (currentFrame + 1) % frames.length; rebuildUI(); }, 1000 / fps);
        } else { clearInterval(playTimer); }
      });
      document.getElementById('btnPrev').addEventListener('click', () => { currentFrame = (currentFrame - 1 + frames.length) % frames.length; rebuildUI(); });
      document.getElementById('btnNext').addEventListener('click', () => { currentFrame = (currentFrame + 1) % frames.length; rebuildUI(); });
      document.getElementById('btnFirst').addEventListener('click', () => { currentFrame = 0; rebuildUI(); });
      document.getElementById('btnLast').addEventListener('click', () => { currentFrame = frames.length - 1; rebuildUI(); });

      document.getElementById('speed').addEventListener('input', (e) => {
        fps = parseInt(e.target.value);
        document.getElementById('speedLabel').textContent = fps + ' fps';
        if (playing) { clearInterval(playTimer); playTimer = setInterval(() => { currentFrame = (currentFrame + 1) % frames.length; rebuildUI(); }, 1000 / fps); }
      });
      document.getElementById('cols').addEventListener('change', (e) => { cols = parseInt(e.target.value); initFrames(); });
      document.getElementById('rows').addEventListener('change', (e) => { rows = parseInt(e.target.value); initFrames(); });

      document.getElementById('frameDuration').addEventListener('change', (e) => {
        if (frames[currentFrame]) { frames[currentFrame].duration = parseInt(e.target.value); markDirty(); }
      });
      document.getElementById('originX').addEventListener('change', (e) => {
        if (frames[currentFrame]) { frames[currentFrame].originX = parseInt(e.target.value); markDirty(); }
      });
      document.getElementById('originY').addEventListener('change', (e) => {
        if (frames[currentFrame]) { frames[currentFrame].originY = parseInt(e.target.value); markDirty(); }
      });
      document.getElementById('btnAddFrame').addEventListener('click', () => {
        frames.push({ id: frames.length, duration: 100, originX: 0, originY: 0 });
        currentFrame = frames.length - 1; markDirty(); rebuildUI();
      });
      document.getElementById('btnAddTag').addEventListener('click', () => {
        const input = document.getElementById('newTag');
        const val = input.value.trim();
        if (val && !tags.includes(val)) { tags.push(val); input.value = ''; markDirty(); renderTags(); }
      });

      function renderTags() {
        const list = document.getElementById('tagList');
        list.innerHTML = '';
        tags.forEach((t, i) => {
          const el = document.createElement('span');
          el.className = 'anim-tag';
          el.innerHTML = t + '<span class="rm">×</span>';
          el.querySelector('.rm').addEventListener('click', () => { tags.splice(i, 1); markDirty(); renderTags(); });
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

      registerShortcut('Ctrl+Z', () => undo.undo());
      registerShortcut('Ctrl+Shift+Z', () => undo.redo());

      initFrames();
      renderTags();
    `);
  }
}
