import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

export class AudioMixerEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): AudioMixerEditor {
    return new AudioMixerEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.audioMixerEditor", "Audio Mixer");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "mixer.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Audio Mixer", `
      .editor-layout {
        display: grid; grid-template-columns: 1fr 210px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .mixer-area {
        grid-row: 2; display: flex; gap: 2px; padding: 8px; overflow-x: auto;
        align-items: stretch; background: var(--bg);
      }
      .fx-panel {
        grid-row: 2; overflow-y: auto; border-left: 1px solid var(--border);
        background: var(--surface); padding: 6px;
      }
      .ch-strip {
        display: flex; flex-direction: column; align-items: center; gap: 4px;
        background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius);
        padding: 6px; min-width: 72px; flex-shrink: 0; cursor: pointer; transition: border-color 0.12s;
      }
      .ch-strip:hover { border-color: var(--hover); }
      .ch-strip.sel { border-color: var(--accent); }
      .ch-strip.master { min-width: 88px; }
      .ch-label { font-size: 10px; font-weight: 600; text-transform: uppercase; color: var(--text-dim); letter-spacing: 0.3px; }
      .fader-wrap { display: flex; flex-direction: column; align-items: center; flex: 1; min-height: 140px; justify-content: center; }
      .fader {
        -webkit-appearance: none; appearance: none; width: 5px; height: 130px;
        background: var(--surface-2); border-radius: 3px; outline: none;
        writing-mode: vertical-lr; direction: rtl;
      }
      .fader::-webkit-slider-thumb {
        -webkit-appearance: none; width: 18px; height: 8px;
        background: var(--text); border-radius: 2px; cursor: pointer;
      }
      .fader-val { font-size: 9px; color: var(--text-dim); margin-top: 3px; font-family: var(--font-mono, monospace); }
      .vu { width: 10px; height: 90px; background: var(--bg); border: 1px solid var(--border); border-radius: 2px; position: relative; overflow: hidden; }
      .vu-bar { position: absolute; bottom: 0; width: 100%; background: linear-gradient(to top, var(--success), var(--warning), var(--error)); transition: height 0.08s; }
      .pan-knob {
        width: 28px; height: 28px; border-radius: 50%; background: var(--surface-2);
        border: 2px solid var(--border); position: relative; cursor: pointer;
      }
      .pan-dot {
        position: absolute; width: 2px; height: 8px; background: var(--accent);
        top: 3px; left: 50%; transform-origin: bottom center;
      }
      .ch-btns { display: flex; gap: 2px; }
      .btn-m, .btn-s { width: 24px; height: 18px; font-size: 9px; font-weight: 700; padding: 0; border-radius: 2px; }
      .btn-m.active { background: var(--error); border-color: var(--error); color: #fff; }
      .btn-s.active { background: var(--warning); border-color: var(--warning); color: #000; }
      .fx-item {
        display: flex; align-items: center; justify-content: space-between;
        padding: 3px 6px; background: var(--surface-2); border-radius: var(--radius); margin-bottom: 3px; font-size: 11px;
        cursor: pointer; transition: background 0.1s;
      }
      .fx-item:hover { background: var(--hover); }
      .fx-item.sel { border-left: 2px solid var(--accent); }
      .bus-row { display: flex; align-items: center; gap: 4px; margin-bottom: 3px; font-size: 10px; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${iconButton(ICONS.add, 'btnAddCh', 'Add Channel')}
            ${iconButton(ICONS.delete, 'btnRemCh', 'Remove Channel')}
          </div>
          ${toolbarSep()}
          <div class="group">
            <button id="btnReset" title="Reset All" style="font-size:10px;padding:2px 8px">Reset</button>
          </div>
          ${toolbarSpacer()}
          ${iconButton(ICONS.save, 'btnExport', 'Export Lua')}
        </div>

        <div class="mixer-area" id="mixerArea"></div>

        <div class="fx-panel">
          ${panelSection('Effects Chain', `
            <div id="fxList"></div>
            <select id="addFx" style="width:100%;margin-top:4px;font-size:10px;">
              <option value="">+ Add Effect…</option>
              <option value="reverb">Reverb</option>
              <option value="delay">Delay</option>
              <option value="lpf">Low-Pass Filter</option>
              <option value="hpf">High-Pass Filter</option>
              <option value="compressor">Compressor</option>
              <option value="distortion">Distortion</option>
            </select>
          `)}
          ${panelSection('Bus Routing', '<div id="busRouting"></div>')}
          ${panelSection('Effect Params', `
            <div id="fxParams"><p style="font-size:10px;color:var(--text-dim)">Select an effect</p></div>
          `)}
        </div>

        <div class="status-bar">
          <span id="stCh" class="badge">5 ch</span>
          <div class="sep"></div>
          <span id="stSel">Master</span>
          <div class="sep"></div>
          <span id="stFx">0 fx</span>
          <div class="spacer"></div>
          <span id="stDirty" style="font-size:10px;color:var(--text-dim)">${ICONS.clean}</span>
        </div>
      </div>
    `, `
      const undo = new UndoStack();
      const NAMES = ['Master','Music','SFX','Voice','Ambient'];
      let channels = NAMES.map((name, i) => ({ name, vol: i===0?100:80, pan: 50, mute: false, solo: false, bus: 'master' }));
      let effects = [];
      let selCh = 0, selFx = -1;

      function snap() { return JSON.parse(JSON.stringify({ channels, effects })); }
      function load(s) { channels = s.channels; effects = s.effects; build(); buildFx(); buildBus(); }
      function push() { undo.push(snap()); markDirty(); }

      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) load(s); });
      registerShortcut('ctrl+shift+z', () => { const s = undo.redo(); if (s) load(s); });
      registerShortcut('ctrl+s', () => document.getElementById('btnExport').click());

      function build() {
        const area = document.getElementById('mixerArea'); area.innerHTML = '';
        channels.forEach((ch, i) => {
          const s = document.createElement('div');
          s.className = 'ch-strip' + (i===0?' master':'') + (i===selCh?' sel':'');
          const vu = 30 + Math.random()*50;
          s.innerHTML =
            '<span class="ch-label">'+ch.name+'</span>'+
            '<div class="vu"><div class="vu-bar" style="height:'+vu+'%"></div></div>'+
            '<div class="fader-wrap"><input type="range" class="fader" min="0" max="100" value="'+ch.vol+'" data-i="'+i+'"><span class="fader-val">'+ch.vol+'</span></div>'+
            '<div class="pan-knob" title="Pan: '+(ch.pan-50)+'"><div class="pan-dot" style="transform:rotate('+((ch.pan-50)*1.35)+'deg)"></div></div>'+
            '<div class="ch-btns"><button class="btn-m'+(ch.mute?' active':'')+'" data-i="'+i+'">M</button><button class="btn-s'+(ch.solo?' active':'')+'" data-i="'+i+'">S</button></div>';
          s.addEventListener('click', () => { selCh = i; document.getElementById('stSel').textContent = ch.name; build(); buildBus(); });
          area.appendChild(s);
        });
        area.querySelectorAll('.fader').forEach(f => f.addEventListener('input', e => {
          const idx = +e.target.dataset.i; channels[idx].vol = +e.target.value;
          e.target.parentElement.querySelector('.fader-val').textContent = e.target.value;
          push();
        }));
        area.querySelectorAll('.btn-m').forEach(b => b.addEventListener('click', e => {
          e.stopPropagation(); const idx = +b.dataset.i; push(); channels[idx].mute = !channels[idx].mute; b.classList.toggle('active', channels[idx].mute);
        }));
        area.querySelectorAll('.btn-s').forEach(b => b.addEventListener('click', e => {
          e.stopPropagation(); const idx = +b.dataset.i; push(); channels[idx].solo = !channels[idx].solo; b.classList.toggle('active', channels[idx].solo);
        }));
        document.getElementById('stCh').textContent = channels.length + ' ch';
      }

      function buildFx() {
        const list = document.getElementById('fxList'); list.innerHTML = '';
        effects.forEach((fx, i) => {
          const el = document.createElement('div');
          el.className = 'fx-item' + (i===selFx?' sel':'');
          el.innerHTML = '<span>'+fx.type+'</span><button style="padding:0 4px;font-size:9px" data-i="'+i+'">×</button>';
          el.addEventListener('click', () => { selFx = i; showFxParams(fx); buildFx(); });
          el.querySelector('button').addEventListener('click', e => { e.stopPropagation(); push(); effects.splice(i,1); buildFx(); });
          list.appendChild(el);
        });
        document.getElementById('stFx').textContent = effects.length + ' fx';
      }

      function showFxParams(fx) {
        const c = document.getElementById('fxParams');
        const map = { reverb:['mix','decay','damping'], delay:['time','feedback','mix'], lpf:['cutoff','resonance'], hpf:['cutoff','resonance'], compressor:['threshold','ratio','attack','release'], distortion:['drive','tone'] };
        const ps = map[fx.type] || [];
        c.innerHTML = '<div style="font-size:10px;font-weight:600;margin-bottom:4px;text-transform:uppercase;color:var(--text-dim)">'+fx.type+'</div>';
        ps.forEach(p => {
          const v = fx.params[p] || 50;
          c.innerHTML += '<div class="field-inline"><label style="font-size:10px">'+p+'</label><input type="range" min="0" max="100" value="'+v+'" style="flex:1"><span style="font-size:9px;min-width:20px">'+v+'</span></div>';
        });
      }

      function buildBus() {
        const c = document.getElementById('busRouting'); c.innerHTML = '';
        channels.forEach((ch, i) => {
          if (i===0) return;
          const r = document.createElement('div'); r.className = 'bus-row';
          r.innerHTML = '<span style="min-width:48px">'+ch.name+'</span><select data-i="'+i+'"><option value="master">Master</option><option value="bus1">Bus 1</option><option value="bus2">Bus 2</option></select>';
          r.querySelector('select').value = ch.bus;
          r.querySelector('select').addEventListener('change', e => { push(); channels[i].bus = e.target.value; });
          c.appendChild(r);
        });
      }

      document.getElementById('addFx').addEventListener('change', e => {
        if (e.target.value) { push(); effects.push({ type: e.target.value, channel: selCh, params: {} }); e.target.value = ''; buildFx(); }
      });
      document.getElementById('btnAddCh').addEventListener('click', () => {
        push(); channels.push({ name: 'Ch '+channels.length, vol: 80, pan: 50, mute: false, solo: false, bus: 'master' }); build();
      });
      document.getElementById('btnRemCh').addEventListener('click', () => {
        if (channels.length > 1) { push(); channels.pop(); if (selCh >= channels.length) selCh = channels.length-1; build(); }
      });
      document.getElementById('btnReset').addEventListener('click', () => {
        push(); channels.forEach((ch,i) => { ch.vol = i===0?100:80; ch.pan = 50; ch.mute = false; ch.solo = false; });
        effects = []; build(); buildFx();
      });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  channels = {\\n';
        channels.forEach(ch => {
          lua += '    { name = "'+ch.name+'", volume = '+(ch.vol/100).toFixed(2)+', pan = '+((ch.pan-50)/50).toFixed(2)+', mute = '+ch.mute+', bus = "'+ch.bus+'" },\\n';
        });
        lua += '  },\\n  effects = {\\n';
        effects.forEach(fx => { lua += '    { type = "'+fx.type+'", channel = '+(fx.channel+1)+' },\\n'; });
        lua += '  }\\n}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      setInterval(() => {
        document.querySelectorAll('.vu-bar').forEach((el, i) => {
          const ch = channels[i];
          if (ch && !ch.mute) el.style.height = (20 + Math.random()*60*(ch.vol/100)) + '%';
          else if (ch) el.style.height = '0%';
        });
      }, 100);

      build(); buildFx(); buildBus();
      vscode.postMessage({ type: 'stateChanged', state: { ready: true } });
    `);
  }
}
