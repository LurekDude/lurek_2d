import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

export class TimelineEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): TimelineEditor {
    return new TimelineEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.timelineEditor", "Timeline");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "timeline.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Timeline", `
      .editor-layout {
        display: grid; grid-template-columns: 140px 1fr 200px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .track-list { grid-row: 2; border-right: 1px solid var(--border); overflow-y: auto; background: var(--surface); }
      .timeline-area { grid-row: 2; overflow: auto; position: relative; background: var(--bg); }
      .props-panel { grid-row: 2; overflow-y: auto; border-left: 1px solid var(--border); background: var(--surface); padding: 6px; }
      .track-header {
        display: flex; align-items: center; gap: 4px; padding: 3px 6px;
        border-bottom: 1px solid var(--border); height: 32px; cursor: pointer; font-size: 11px;
        transition: background 0.08s;
      }
      .track-header:hover { background: var(--hover); }
      .track-header.sel { background: var(--selection); }
      .track-icon { font-size: 13px; }
      .track-name { flex: 1; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
      .track-mute { opacity: 0.4; cursor: pointer; font-size: 9px; font-weight: 700; }
      .track-mute.muted { opacity: 1; color: var(--error); }
      .timeline-ruler {
        height: 22px; background: var(--surface); border-bottom: 1px solid var(--border);
        position: sticky; top: 0; z-index: 5;
      }
      .timeline-tracks { position: relative; }
      .timeline-row { height: 32px; border-bottom: 1px solid var(--border); position: relative; }
      .keyframe {
        position: absolute; width: 9px; height: 9px; background: var(--accent);
        transform: rotate(45deg) translate(-50%, -50%); top: 12px; cursor: pointer; z-index: 2;
        transition: background 0.08s;
      }
      .keyframe:hover { background: var(--accent-2); }
      .keyframe.sel { background: var(--warning); box-shadow: 0 0 4px var(--warning); }
      .segment {
        position: absolute; height: 18px; top: 7px; background: rgba(137,180,250,0.2);
        border: 1px solid var(--accent); border-radius: var(--radius); cursor: move; z-index: 1;
        font-size: 8px; color: var(--text-dim); padding: 1px 4px; overflow: hidden;
      }
      .playhead {
        position: absolute; top: 0; bottom: 0; width: 2px; background: var(--error);
        z-index: 10; pointer-events: none;
      }
      .playhead-handle {
        position: absolute; top: 0; width: 10px; height: 10px; background: var(--error);
        left: -4px; cursor: pointer; pointer-events: auto; clip-path: polygon(0 0, 100% 0, 50% 100%);
      }
      .easing-preview { width: 100%; height: 50px; background: var(--bg); border: 1px solid var(--border); border-radius: var(--radius); }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${iconButton(ICONS.add, 'btnAddTrack', 'Add Track')}
            <select id="trackType" style="font-size:10px">
              <option value="dialog">Dialog</option>
              <option value="camera">Camera</option>
              <option value="audio">Audio</option>
              <option value="effects">Effects</option>
              <option value="custom">Custom</option>
            </select>
          </div>
          ${toolbarSep()}
          <div class="group">
            ${iconButton(ICONS.play, 'btnPlay', 'Play')}
            ${iconButton(ICONS.pause, 'btnStop', 'Stop')}
            <span id="timeDisplay" style="font-family:var(--font-mono,monospace);font-size:11px;min-width:70px;">00:00.000</span>
          </div>
          ${toolbarSep()}
          <div class="group">
            <label style="font-size:10px">Dur:</label><input type="number" id="duration" value="10" min="1" max="300" style="width:40px">
            <label style="font-size:10px;margin-left:4px">Snap:</label>
            <select id="snapGrid" style="font-size:10px">
              <option value="0">Off</option>
              <option value="0.1">0.1s</option>
              <option value="0.25" selected>0.25s</option>
              <option value="0.5">0.5s</option>
              <option value="1">1s</option>
            </select>
          </div>
          ${toolbarSep()}
          <div class="group">
            <button id="btnAddKeyframe" style="font-size:10px;padding:2px 6px">+ KF</button>
            <button id="btnDeleteKeyframe" style="font-size:10px;padding:2px 6px;color:var(--error)">× KF</button>
          </div>
          ${toolbarSpacer()}
          ${iconButton(ICONS.save, 'btnExport', 'Export Lua')}
        </div>

        <div class="track-list" id="trackList"></div>

        <div class="timeline-area" id="timelineArea">
          <canvas class="timeline-ruler" id="ruler"></canvas>
          <div class="timeline-tracks" id="timelineTracks">
            <div class="playhead" id="playhead">
              <div class="playhead-handle"></div>
            </div>
          </div>
        </div>

        <div class="props-panel">
          ${panelSection('Keyframe', `
            ${fieldInline('Time (s)', '<input type="number" id="kfTime" step="0.01" min="0">')}
            ${fieldInline('Value', '<input type="text" id="kfValue">')}
            ${fieldInline('Easing', `<select id="kfEasing" style="flex:1">
              <option value="linear">Linear</option>
              <option value="easeIn">Ease In</option>
              <option value="easeOut">Ease Out</option>
              <option value="easeInOut">Ease In-Out</option>
              <option value="bounce">Bounce</option>
              <option value="elastic">Elastic</option>
            </select>`)}
            <canvas class="easing-preview" id="easingPreview"></canvas>
          `)}
          ${panelSection('Segment', `
            ${fieldInline('Label', '<input type="text" id="segLabel">')}
            <div style="display:flex;gap:4px">
              ${fieldInline('Start', '<input type="number" id="segStart" step="0.1" style="width:56px">')}
              ${fieldInline('End', '<input type="number" id="segEnd" step="0.1" style="width:56px">')}
            </div>
          `)}
        </div>

        <div class="status-bar">
          <span id="statusTracks" class="badge">3 tracks</span>
          <div class="sep"></div>
          <span id="statusKeyframes">5 kf</span>
          <div class="sep"></div>
          <span id="statusDuration">10s</span>
          <div class="spacer"></div>
          <span id="statusDirty" style="font-size:10px;color:var(--text-dim)">${ICONS.clean}</span>
        </div>
      </div>
    `, `
      const TRACK_ICONS = { dialog: '\\u{1F4AC}', camera: '\\u{1F3A5}', audio: '\\u{1F50A}', effects: '\\u2728', custom: '\\u{1F527}' };
      const undo = new UndoStack();
      let tracks = [
        { name: 'Dialog', type: 'dialog', muted: false, keyframes: [{t:0,val:'Hello',easing:'linear'},{t:2,val:'World',easing:'linear'}], segments: [{start:0,end:2,label:'Intro text'}] },
        { name: 'Camera', type: 'camera', muted: false, keyframes: [{t:0,val:'0,0',easing:'linear'},{t:3,val:'100,50',easing:'easeInOut'}], segments: [{start:0,end:3,label:'Pan right'}] },
        { name: 'Music', type: 'audio', muted: false, keyframes: [{t:0,val:'bgm.ogg',easing:'linear'}], segments: [{start:0,end:10,label:'Background music'}] },
      ];
      let selTrack = 0, selKF = -1, duration = 10, playTime = 0, playing = false, playTimer = null;
      const PX = 80;

      function snap() { return JSON.parse(JSON.stringify({ tracks, duration })); }
      function load(s) { tracks = s.tracks; duration = s.duration; build(); }
      function push() { undo.push(snap()); markDirty(); }
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) load(s); });
      registerShortcut('ctrl+shift+z', () => { const s = undo.redo(); if (s) load(s); });
      registerShortcut('ctrl+s', () => document.getElementById('btnExport').click());
      registerShortcut('space', () => { if (playing) document.getElementById('btnStop').click(); else document.getElementById('btnPlay').click(); });

      function build() {
        const list = document.getElementById('trackList'); list.innerHTML = '';
        tracks.forEach((tr, i) => {
          const el = document.createElement('div');
          el.className = 'track-header' + (i === selTrack ? ' sel' : '');
          el.innerHTML = '<span class="track-icon">' + (TRACK_ICONS[tr.type] || '?') + '</span>' +
            '<span class="track-name">' + tr.name + '</span>' +
            '<span class="track-mute' + (tr.muted ? ' muted' : '') + '" data-t="' + i + '">M</span>';
          el.addEventListener('click', () => { selTrack = i; selKF = -1; build(); });
          el.querySelector('.track-mute').addEventListener('click', e => { e.stopPropagation(); push(); tr.muted = !tr.muted; build(); });
          list.appendChild(el);
        });

        const container = document.getElementById('timelineTracks');
        container.querySelectorAll('.timeline-row').forEach(r => r.remove());
        let totalKF = 0;
        tracks.forEach((tr, ti) => {
          const row = document.createElement('div');
          row.className = 'timeline-row';
          row.style.width = (duration * PX) + 'px';
          tr.segments.forEach(seg => {
            const el = document.createElement('div');
            el.className = 'segment';
            el.style.left = (seg.start * PX) + 'px';
            el.style.width = ((seg.end - seg.start) * PX) + 'px';
            el.textContent = seg.label;
            row.appendChild(el);
          });
          tr.keyframes.forEach((kf, ki) => {
            const el = document.createElement('div');
            el.className = 'keyframe' + (ti === selTrack && ki === selKF ? ' sel' : '');
            el.style.left = (kf.t * PX) + 'px';
            el.addEventListener('click', e => { e.stopPropagation(); selTrack = ti; selKF = ki; updateKFProps(); build(); });
            row.appendChild(el);
            totalKF++;
          });
          container.appendChild(row);
        });

        document.getElementById('playhead').style.left = (playTime * PX) + 'px';
        drawRuler();
        document.getElementById('statusTracks').textContent = tracks.length + ' tracks';
        document.getElementById('statusKeyframes').textContent = totalKF + ' kf';
        document.getElementById('statusDuration').textContent = duration + 's';
      }

      function drawRuler() {
        const canvas = document.getElementById('ruler');
        canvas.width = duration * PX;
        canvas.height = 22;
        const ctx = canvas.getContext('2d');
        ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--surface').trim() || '#252526';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--text-dim').trim() || '#858585';
        ctx.font = '9px monospace';
        for (let t = 0; t <= duration; t += 0.5) {
          const x = t * PX;
          ctx.beginPath(); ctx.moveTo(x, t % 1 === 0 ? 8 : 16); ctx.lineTo(x, 22);
          ctx.strokeStyle = getComputedStyle(document.documentElement).getPropertyValue('--border').trim() || '#3c3c3c'; ctx.stroke();
          if (t % 1 === 0) ctx.fillText(t + 's', x + 2, 14);
        }
      }

      function updateKFProps() {
        const tr = tracks[selTrack];
        if (!tr || selKF < 0 || selKF >= tr.keyframes.length) return;
        const kf = tr.keyframes[selKF];
        document.getElementById('kfTime').value = kf.t;
        document.getElementById('kfValue').value = kf.val;
        document.getElementById('kfEasing').value = kf.easing || 'linear';
        drawEasingPreview(kf.easing || 'linear');
      }

      function drawEasingPreview(type) {
        const canvas = document.getElementById('easingPreview');
        const ctx = canvas.getContext('2d');
        canvas.width = canvas.clientWidth;
        canvas.height = 50;
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.strokeStyle = getComputedStyle(document.documentElement).getPropertyValue('--border').trim() || '#3c3c3c';
        ctx.strokeRect(0, 0, canvas.width, canvas.height);
        ctx.beginPath();
        ctx.strokeStyle = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim() || '#89b4fa';
        ctx.lineWidth = 2;
        for (let i = 0; i <= canvas.width; i++) {
          const t = i / canvas.width;
          let v;
          switch (type) {
            case 'easeIn': v = t * t; break;
            case 'easeOut': v = 1 - (1-t)*(1-t); break;
            case 'easeInOut': v = t < 0.5 ? 2*t*t : 1-Math.pow(-2*t+2,2)/2; break;
            case 'bounce': { const n=7.5625,d=2.75; let t2=1-t; v=1-(t2<1/d?n*t2*t2:t2<2/d?n*(t2-=1.5/d)*t2+.75:t2<2.5/d?n*(t2-=2.25/d)*t2+.9375:n*(t2-=2.625/d)*t2+.984375); break; }
            case 'elastic': v = t===0?0:t===1?1:Math.pow(2,-10*t)*Math.sin((t*10-0.75)*(2*Math.PI)/3)+1; break;
            default: v = t;
          }
          const y = canvas.height - v * (canvas.height - 4) - 2;
          if (i === 0) ctx.moveTo(i, y); else ctx.lineTo(i, y);
        }
        ctx.stroke();
      }

      document.getElementById('kfTime').addEventListener('change', e => {
        const tr = tracks[selTrack];
        if (tr && selKF >= 0) { push(); tr.keyframes[selKF].t = parseFloat(e.target.value); build(); }
      });
      document.getElementById('kfValue').addEventListener('change', e => {
        const tr = tracks[selTrack];
        if (tr && selKF >= 0) { push(); tr.keyframes[selKF].val = e.target.value; }
      });
      document.getElementById('kfEasing').addEventListener('change', e => {
        const tr = tracks[selTrack];
        if (tr && selKF >= 0) { push(); tr.keyframes[selKF].easing = e.target.value; }
        drawEasingPreview(e.target.value);
      });

      document.getElementById('btnAddTrack').addEventListener('click', () => {
        push();
        const type = document.getElementById('trackType').value;
        tracks.push({ name: type.charAt(0).toUpperCase() + type.slice(1) + ' ' + tracks.length, type, muted: false, keyframes: [], segments: [] });
        build();
      });

      document.getElementById('btnAddKeyframe').addEventListener('click', () => {
        const tr = tracks[selTrack];
        if (tr) { push(); tr.keyframes.push({ t: playTime, val: '', easing: 'linear' }); selKF = tr.keyframes.length - 1; build(); updateKFProps(); }
      });
      document.getElementById('btnDeleteKeyframe').addEventListener('click', () => {
        const tr = tracks[selTrack];
        if (tr && selKF >= 0) { push(); tr.keyframes.splice(selKF, 1); selKF = -1; build(); }
      });

      document.getElementById('btnPlay').addEventListener('click', () => {
        if (playing) return;
        playing = true;
        playTimer = setInterval(() => {
          playTime += 0.05;
          if (playTime >= duration) playTime = 0;
          document.getElementById('playhead').style.left = (playTime * PX) + 'px';
          const m = Math.floor(playTime / 60), s = Math.floor(playTime % 60), ms = Math.floor((playTime % 1) * 1000);
          document.getElementById('timeDisplay').textContent = String(m).padStart(2,'0') + ':' + String(s).padStart(2,'0') + '.' + String(ms).padStart(3,'0');
        }, 50);
      });
      document.getElementById('btnStop').addEventListener('click', () => {
        playing = false; clearInterval(playTimer);
        playTime = 0; document.getElementById('playhead').style.left = '0px';
        document.getElementById('timeDisplay').textContent = '00:00.000';
      });

      document.getElementById('duration').addEventListener('change', e => { duration = parseInt(e.target.value); build(); });

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  duration = ' + duration + ',\\n  tracks = {\\n';
        tracks.forEach(tr => {
          lua += '    { name = "' + tr.name + '", type = "' + tr.type + '",\\n';
          lua += '      keyframes = {\\n';
          tr.keyframes.forEach(kf => { lua += '        { t = ' + kf.t + ', value = "' + kf.val + '", easing = "' + (kf.easing||'linear') + '" },\\n'; });
          lua += '      },\\n      segments = {\\n';
          tr.segments.forEach(seg => { lua += '        { start = ' + seg.start + ', stop = ' + seg.end + ', label = "' + seg.label + '" },\\n'; });
          lua += '      },\\n    },\\n';
        });
        lua += '  }\\n}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      build(); drawEasingPreview('linear');
      vscode.postMessage({ type: 'stateChanged', state: { ready: true } });
    `);
  }
}
