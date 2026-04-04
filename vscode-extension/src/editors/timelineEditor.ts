import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class TimelineEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): TimelineEditor {
    return new TimelineEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "luna.timelineEditor", "Timeline");
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
        display: grid; grid-template-columns: 160px 1fr 220px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .track-list { grid-row: 2; border-right: 1px solid var(--border); }
      .timeline-area { grid-row: 2; overflow: auto; position: relative; }
      .props-panel { grid-row: 2; }
      .status-bar { grid-column: 1 / -1; }
      .track-header {
        display: flex; align-items: center; gap: 4px; padding: 4px 8px;
        border-bottom: 1px solid var(--border); height: 36px; cursor: pointer; font-size: 12px;
      }
      .track-header:hover { background: var(--surface-2); }
      .track-header.selected { background: var(--selection); }
      .track-icon { font-size: 14px; }
      .track-name { flex: 1; }
      .track-mute { opacity: 0.5; cursor: pointer; font-size: 10px; }
      .track-mute.muted { opacity: 1; color: var(--danger); }
      .timeline-ruler {
        height: 24px; background: var(--surface); border-bottom: 1px solid var(--border);
        position: sticky; top: 0; z-index: 5;
      }
      .timeline-tracks { position: relative; }
      .timeline-row {
        height: 36px; border-bottom: 1px solid var(--border); position: relative;
      }
      .keyframe {
        position: absolute; width: 10px; height: 10px; background: var(--accent);
        transform: rotate(45deg) translate(-50%, -50%); top: 13px; cursor: pointer; z-index: 2;
      }
      .keyframe:hover { background: var(--accent-2); }
      .keyframe.selected { background: var(--warning); box-shadow: 0 0 4px var(--warning); }
      .segment {
        position: absolute; height: 20px; top: 8px; background: rgba(0,122,204,0.3);
        border: 1px solid var(--accent); border-radius: 3px; cursor: move; z-index: 1;
        font-size: 9px; color: var(--text); padding: 2px 4px; overflow: hidden;
      }
      .playhead {
        position: absolute; top: 0; bottom: 0; width: 2px; background: var(--danger);
        z-index: 10; pointer-events: none;
      }
      .playhead-handle {
        position: absolute; top: 0; width: 12px; height: 12px; background: var(--danger);
        left: -5px; cursor: pointer; pointer-events: auto; clip-path: polygon(0 0, 100% 0, 50% 100%);
      }
      .easing-preview { width: 100%; height: 60px; background: var(--bg); border: 1px solid var(--border); border-radius: 4px; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAddTrack">+ Track</button>
          <select id="trackType">
            <option value="dialog">Dialog</option>
            <option value="camera">Camera</option>
            <option value="audio">Audio</option>
            <option value="effects">Effects</option>
            <option value="custom">Custom</option>
          </select>
          <div class="sep"></div>
          <button id="btnPlay">&#9654; Play</button>
          <button id="btnStop">&#9632; Stop</button>
          <span id="timeDisplay" style="font-family:monospace;font-size:12px;min-width:80px;">00:00.000</span>
          <div class="sep"></div>
          <label>Duration:</label><input type="number" id="duration" value="10" min="1" max="300" style="width:50px">s
          <label style="margin-left:8px;">Snap:</label>
          <select id="snapGrid">
            <option value="0">Off</option>
            <option value="0.1">0.1s</option>
            <option value="0.25" selected>0.25s</option>
            <option value="0.5">0.5s</option>
            <option value="1">1s</option>
          </select>
          <div class="sep"></div>
          <button id="btnAddKeyframe">+ Keyframe</button>
          <button id="btnDeleteKeyframe" class="danger">Delete KF</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>

        <div class="panel track-list" id="trackList"></div>

        <div class="timeline-area" id="timelineArea">
          <canvas class="timeline-ruler" id="ruler"></canvas>
          <div class="timeline-tracks" id="timelineTracks">
            <div class="playhead" id="playhead">
              <div class="playhead-handle"></div>
            </div>
          </div>
        </div>

        <div class="panel props-panel">
          <div class="section">
            <h3>Keyframe</h3>
            <div class="field"><label>Time (s)</label><input type="number" id="kfTime" step="0.01" min="0"></div>
            <div class="field"><label>Value</label><input type="text" id="kfValue"></div>
            <div class="field">
              <label>Easing</label>
              <select id="kfEasing">
                <option value="linear">Linear</option>
                <option value="easeIn">Ease In</option>
                <option value="easeOut">Ease Out</option>
                <option value="easeInOut">Ease In-Out</option>
                <option value="bounce">Bounce</option>
                <option value="elastic">Elastic</option>
              </select>
            </div>
            <canvas class="easing-preview" id="easingPreview"></canvas>
          </div>
          <div class="section">
            <h3>Segment</h3>
            <div class="field"><label>Label</label><input type="text" id="segLabel"></div>
            <div class="field-row">
              <div class="field" style="flex:1"><label>Start</label><input type="number" id="segStart" step="0.1"></div>
              <div class="field" style="flex:1"><label>End</label><input type="number" id="segEnd" step="0.1"></div>
            </div>
          </div>
        </div>

        <div class="status-bar">
          <span id="statusTracks">Tracks: 0</span>
          <span id="statusKeyframes">Keyframes: 0</span>
          <span id="statusDuration">Duration: 10s</span>
        </div>
      </div>
    `, `
      const TRACK_ICONS = { dialog: '\\u{1F4AC}', camera: '\\u{1F3A5}', audio: '\\u{1F50A}', effects: '\\u2728', custom: '\\u{1F527}' };
      let tracks = [
        { name: 'Dialog', type: 'dialog', muted: false, keyframes: [{t:0,val:'Hello'},{t:2,val:'World'}], segments: [{start:0,end:2,label:'Intro text'}] },
        { name: 'Camera', type: 'camera', muted: false, keyframes: [{t:0,val:'0,0'},{t:3,val:'100,50'}], segments: [{start:0,end:3,label:'Pan right'}] },
        { name: 'Music', type: 'audio', muted: false, keyframes: [{t:0,val:'bgm.ogg'}], segments: [{start:0,end:10,label:'Background music'}] },
      ];
      let selectedTrack = 0;
      let selectedKF = -1;
      let duration = 10;
      let playTime = 0;
      let playing = false;
      let playTimer = null;
      const PX_PER_SEC = 80;

      function render() {
        // Track list
        const list = document.getElementById('trackList');
        list.innerHTML = '';
        tracks.forEach((tr, i) => {
          const el = document.createElement('div');
          el.className = 'track-header' + (i === selectedTrack ? ' selected' : '');
          el.innerHTML = '<span class="track-icon">' + (TRACK_ICONS[tr.type] || '?') + '</span>' +
            '<span class="track-name">' + tr.name + '</span>' +
            '<span class="track-mute' + (tr.muted ? ' muted' : '') + '" data-t="' + i + '">M</span>';
          el.addEventListener('click', () => { selectedTrack = i; selectedKF = -1; render(); });
          list.appendChild(el);
        });

        // Timeline tracks
        const container = document.getElementById('timelineTracks');
        container.querySelectorAll('.timeline-row').forEach(r => r.remove());
        let totalKF = 0;
        tracks.forEach((tr, ti) => {
          const row = document.createElement('div');
          row.className = 'timeline-row';
          row.style.width = (duration * PX_PER_SEC) + 'px';
          // Segments
          tr.segments.forEach((seg) => {
            const el = document.createElement('div');
            el.className = 'segment';
            el.style.left = (seg.start * PX_PER_SEC) + 'px';
            el.style.width = ((seg.end - seg.start) * PX_PER_SEC) + 'px';
            el.textContent = seg.label;
            row.appendChild(el);
          });
          // Keyframes
          tr.keyframes.forEach((kf, ki) => {
            const el = document.createElement('div');
            el.className = 'keyframe' + (ti === selectedTrack && ki === selectedKF ? ' selected' : '');
            el.style.left = (kf.t * PX_PER_SEC) + 'px';
            el.addEventListener('click', (e) => {
              e.stopPropagation();
              selectedTrack = ti; selectedKF = ki;
              updateKFProps();
              render();
            });
            row.appendChild(el);
            totalKF++;
          });
          container.appendChild(row);
        });

        // Playhead
        document.getElementById('playhead').style.left = (playTime * PX_PER_SEC) + 'px';

        // Ruler
        drawRuler();

        document.getElementById('statusTracks').textContent = 'Tracks: ' + tracks.length;
        document.getElementById('statusKeyframes').textContent = 'Keyframes: ' + totalKF;
        document.getElementById('statusDuration').textContent = 'Duration: ' + duration + 's';
      }

      function drawRuler() {
        const canvas = document.getElementById('ruler');
        canvas.width = duration * PX_PER_SEC;
        canvas.height = 24;
        const ctx = canvas.getContext('2d');
        ctx.fillStyle = '#252526';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = '#858585';
        ctx.font = '10px monospace';
        for (let t = 0; t <= duration; t += 0.5) {
          const x = t * PX_PER_SEC;
          ctx.beginPath(); ctx.moveTo(x, t % 1 === 0 ? 8 : 16); ctx.lineTo(x, 24);
          ctx.strokeStyle = '#3c3c3c'; ctx.stroke();
          if (t % 1 === 0) ctx.fillText(t + 's', x + 2, 16);
        }
      }

      function updateKFProps() {
        const tr = tracks[selectedTrack];
        if (!tr || selectedKF < 0 || selectedKF >= tr.keyframes.length) return;
        const kf = tr.keyframes[selectedKF];
        document.getElementById('kfTime').value = kf.t;
        document.getElementById('kfValue').value = kf.val;
        drawEasingPreview(kf.easing || 'linear');
      }

      function drawEasingPreview(type) {
        const canvas = document.getElementById('easingPreview');
        const ctx = canvas.getContext('2d');
        canvas.width = canvas.clientWidth;
        canvas.height = 60;
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.strokeStyle = '#3c3c3c';
        ctx.strokeRect(0, 0, canvas.width, canvas.height);
        ctx.beginPath();
        ctx.strokeStyle = '#007acc';
        ctx.lineWidth = 2;
        for (let i = 0; i <= canvas.width; i++) {
          const t = i / canvas.width;
          let v;
          switch (type) {
            case 'easeIn': v = t * t; break;
            case 'easeOut': v = 1 - (1-t)*(1-t); break;
            case 'easeInOut': v = t < 0.5 ? 2*t*t : 1-Math.pow(-2*t+2,2)/2; break;
            case 'bounce': { const n=7.5625,d=2.75; let t2=1-t; v=1-(t2<1/d?n*t2*t2:t2<2/d?n*(t2-=1.5/d)*t2+.75:t2<2.5/d?n*(t2-=2.25/d)*t2+.9375:n*(t2-=2.625/d)*t2+.984375); break; }
            default: v = t;
          }
          const y = canvas.height - v * (canvas.height - 4) - 2;
          if (i === 0) ctx.moveTo(i, y); else ctx.lineTo(i, y);
        }
        ctx.stroke();
      }

      document.getElementById('kfTime').addEventListener('change', (e) => {
        const tr = tracks[selectedTrack];
        if (tr && selectedKF >= 0) { tr.keyframes[selectedKF].t = parseFloat(e.target.value); render(); }
      });
      document.getElementById('kfValue').addEventListener('change', (e) => {
        const tr = tracks[selectedTrack];
        if (tr && selectedKF >= 0) { tr.keyframes[selectedKF].val = e.target.value; }
      });
      document.getElementById('kfEasing').addEventListener('change', (e) => {
        const tr = tracks[selectedTrack];
        if (tr && selectedKF >= 0) { tr.keyframes[selectedKF].easing = e.target.value; }
        drawEasingPreview(e.target.value);
      });

      document.getElementById('btnAddTrack').addEventListener('click', () => {
        const type = document.getElementById('trackType').value;
        tracks.push({ name: type.charAt(0).toUpperCase() + type.slice(1) + ' ' + tracks.length, type, muted: false, keyframes: [], segments: [] });
        render();
      });

      document.getElementById('btnAddKeyframe').addEventListener('click', () => {
        const tr = tracks[selectedTrack];
        if (tr) {
          tr.keyframes.push({ t: playTime, val: '', easing: 'linear' });
          selectedKF = tr.keyframes.length - 1;
          render(); updateKFProps();
        }
      });
      document.getElementById('btnDeleteKeyframe').addEventListener('click', () => {
        const tr = tracks[selectedTrack];
        if (tr && selectedKF >= 0) {
          tr.keyframes.splice(selectedKF, 1);
          selectedKF = -1;
          render();
        }
      });

      document.getElementById('btnPlay').addEventListener('click', () => {
        if (playing) return;
        playing = true;
        playTimer = setInterval(() => {
          playTime += 0.05;
          if (playTime >= duration) { playTime = 0; }
          document.getElementById('playhead').style.left = (playTime * PX_PER_SEC) + 'px';
          const m = Math.floor(playTime / 60);
          const s = Math.floor(playTime % 60);
          const ms = Math.floor((playTime % 1) * 1000);
          document.getElementById('timeDisplay').textContent =
            String(m).padStart(2,'0') + ':' + String(s).padStart(2,'0') + '.' + String(ms).padStart(3,'0');
        }, 50);
      });
      document.getElementById('btnStop').addEventListener('click', () => {
        playing = false;
        clearInterval(playTimer);
        playTime = 0;
        document.getElementById('playhead').style.left = '0px';
        document.getElementById('timeDisplay').textContent = '00:00.000';
      });

      document.getElementById('duration').addEventListener('change', (e) => {
        duration = parseInt(e.target.value);
        render();
      });

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  duration = ' + duration + ',\\n  tracks = {\\n';
        tracks.forEach(tr => {
          lua += '    { name = "' + tr.name + '", type = "' + tr.type + '",\\n';
          lua += '      keyframes = {\\n';
          tr.keyframes.forEach(kf => {
            lua += '        { t = ' + kf.t + ', value = "' + kf.val + '", easing = "' + (kf.easing||'linear') + '" },\\n';
          });
          lua += '      },\\n      segments = {\\n';
          tr.segments.forEach(seg => {
            lua += '        { start = ' + seg.start + ', stop = ' + seg.end + ', label = "' + seg.label + '" },\\n';
          });
          lua += '      },\\n    },\\n';
        });
        lua += '  }\\n}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      render();
      drawEasingPreview('linear');
    `);
  }
}
