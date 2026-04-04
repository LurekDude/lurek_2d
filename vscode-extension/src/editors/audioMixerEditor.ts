import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class AudioMixerEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): AudioMixerEditor {
    return new AudioMixerEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "luna.audioMixerEditor", "Audio Mixer");
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
        display: grid; grid-template-columns: 1fr 220px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .mixer-area { grid-row: 2; display: flex; gap: 2px; padding: 10px; overflow-x: auto; align-items: stretch; }
      .effects-panel { grid-row: 2; }
      .status-bar { grid-column: 1 / -1; }
      .channel-strip {
        display: flex; flex-direction: column; align-items: center; gap: 4px;
        background: var(--surface); border: 1px solid var(--border); border-radius: 4px;
        padding: 8px; min-width: 80px; flex-shrink: 0;
      }
      .channel-strip.master { border-color: var(--accent); min-width: 100px; }
      .channel-label { font-size: 11px; font-weight: bold; text-transform: uppercase; color: var(--text-dim); }
      .fader-container { display: flex; flex-direction: column; align-items: center; flex: 1; min-height: 150px; justify-content: center; }
      .fader {
        -webkit-appearance: none; appearance: none; width: 6px; height: 140px;
        background: var(--surface-2); border-radius: 3px; outline: none;
        writing-mode: vertical-lr; direction: rtl;
      }
      .fader::-webkit-slider-thumb {
        -webkit-appearance: none; width: 20px; height: 10px;
        background: var(--text); border-radius: 2px; cursor: pointer;
      }
      .fader-value { font-size: 10px; color: var(--text-dim); margin-top: 4px; }
      .vu-meter { width: 12px; height: 100px; background: var(--bg); border: 1px solid var(--border); border-radius: 2px; position: relative; overflow: hidden; }
      .vu-fill { position: absolute; bottom: 0; width: 100%; background: linear-gradient(to top, var(--success), var(--warning), var(--danger)); transition: height 0.1s; }
      .pan-knob {
        width: 32px; height: 32px; border-radius: 50%; background: var(--surface-2);
        border: 2px solid var(--border); position: relative; cursor: pointer;
      }
      .pan-indicator {
        position: absolute; width: 2px; height: 10px; background: var(--accent);
        top: 3px; left: 50%; transform-origin: bottom center;
      }
      .btn-row { display: flex; gap: 2px; }
      .btn-mute, .btn-solo { width: 28px; height: 20px; font-size: 10px; font-weight: bold; padding: 0; }
      .btn-mute.active { background: var(--danger); border-color: var(--danger); }
      .btn-solo.active { background: var(--warning); border-color: var(--warning); color: #000; }
      .effect-item {
        display: flex; align-items: center; justify-content: space-between;
        padding: 4px 8px; background: var(--surface-2); border-radius: 3px; margin-bottom: 4px; font-size: 12px;
      }
      .bus-row { display: flex; align-items: center; gap: 4px; margin-bottom: 4px; font-size: 11px; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAddChannel">+ Channel</button>
          <button id="btnRemoveChannel">- Channel</button>
          <div class="sep"></div>
          <button id="btnResetAll">Reset All</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>

        <div class="mixer-area" id="mixerArea"></div>

        <div class="panel effects-panel">
          <div class="section">
            <h3>Effects Chain</h3>
            <div id="effectsList"></div>
            <select id="addEffect" style="width:100%;margin-top:4px;">
              <option value="">+ Add Effect...</option>
              <option value="reverb">Reverb</option>
              <option value="delay">Delay</option>
              <option value="lpf">Low-Pass Filter</option>
              <option value="hpf">High-Pass Filter</option>
              <option value="compressor">Compressor</option>
              <option value="distortion">Distortion</option>
            </select>
          </div>
          <div class="section">
            <h3>Bus Routing</h3>
            <div id="busRouting"></div>
          </div>
          <div class="section">
            <h3>Selected Effect</h3>
            <div id="effectParams">
              <p style="font-size:11px;color:var(--text-dim);">Select an effect to edit</p>
            </div>
          </div>
        </div>

        <div class="status-bar">
          <span id="statusChannels">Channels: 5</span>
          <span id="statusSelected">Selected: Master</span>
          <span id="statusEffects">Effects: 0</span>
        </div>
      </div>
    `, `
      const CHANNEL_NAMES = ['Master', 'Music', 'SFX', 'Voice', 'Ambient'];
      let channels = CHANNEL_NAMES.map((name, i) => ({
        name, volume: i === 0 ? 100 : 80, pan: 50, mute: false, solo: false, vu: 0, bus: 'master'
      }));
      let effects = [];
      let selectedChannel = 0;
      let selectedEffect = -1;

      function buildMixer() {
        const area = document.getElementById('mixerArea');
        area.innerHTML = '';
        channels.forEach((ch, i) => {
          const strip = document.createElement('div');
          strip.className = 'channel-strip' + (i === 0 ? ' master' : '');
          const vuLevel = 30 + Math.random() * 50;
          strip.innerHTML =
            '<span class="channel-label">' + ch.name + '</span>' +
            '<div class="vu-meter"><div class="vu-fill" style="height:' + vuLevel + '%"></div></div>' +
            '<div class="fader-container">' +
              '<input type="range" class="fader" min="0" max="100" value="' + ch.volume + '" data-ch="' + i + '">' +
              '<span class="fader-value">' + ch.volume + '%</span>' +
            '</div>' +
            '<div class="pan-knob" title="Pan: ' + (ch.pan - 50) + '">' +
              '<div class="pan-indicator" style="transform:rotate(' + ((ch.pan - 50) * 1.35) + 'deg)"></div>' +
            '</div>' +
            '<div class="btn-row">' +
              '<button class="btn-mute' + (ch.mute ? ' active' : '') + '" data-ch="' + i + '">M</button>' +
              '<button class="btn-solo' + (ch.solo ? ' active' : '') + '" data-ch="' + i + '">S</button>' +
            '</div>';
          strip.addEventListener('click', () => {
            selectedChannel = i;
            document.getElementById('statusSelected').textContent = 'Selected: ' + ch.name;
            buildBusRouting();
          });
          area.appendChild(strip);
        });

        // Attach fader events
        area.querySelectorAll('.fader').forEach(f => {
          f.addEventListener('input', (e) => {
            const idx = parseInt(e.target.dataset.ch);
            channels[idx].volume = parseInt(e.target.value);
            e.target.parentElement.querySelector('.fader-value').textContent = e.target.value + '%';
          });
        });
        area.querySelectorAll('.btn-mute').forEach(b => {
          b.addEventListener('click', (e) => {
            e.stopPropagation();
            const idx = parseInt(b.dataset.ch);
            channels[idx].mute = !channels[idx].mute;
            b.classList.toggle('active', channels[idx].mute);
          });
        });
        area.querySelectorAll('.btn-solo').forEach(b => {
          b.addEventListener('click', (e) => {
            e.stopPropagation();
            const idx = parseInt(b.dataset.ch);
            channels[idx].solo = !channels[idx].solo;
            b.classList.toggle('active', channels[idx].solo);
          });
        });
        document.getElementById('statusChannels').textContent = 'Channels: ' + channels.length;
      }

      function buildEffects() {
        const list = document.getElementById('effectsList');
        list.innerHTML = '';
        effects.forEach((fx, i) => {
          const el = document.createElement('div');
          el.className = 'effect-item';
          el.innerHTML = '<span>' + fx.type + '</span><button class="danger" data-fx="' + i + '" style="padding:1px 6px;">x</button>';
          el.addEventListener('click', () => { selectedEffect = i; showEffectParams(fx); });
          el.querySelector('button').addEventListener('click', (e) => {
            e.stopPropagation();
            effects.splice(i, 1);
            buildEffects();
          });
          list.appendChild(el);
        });
        document.getElementById('statusEffects').textContent = 'Effects: ' + effects.length;
      }

      function showEffectParams(fx) {
        const container = document.getElementById('effectParams');
        const params = { reverb: ['mix','decay','damping'], delay: ['time','feedback','mix'], lpf: ['cutoff','resonance'], hpf: ['cutoff','resonance'], compressor: ['threshold','ratio','attack','release'], distortion: ['drive','tone'] };
        const p = params[fx.type] || [];
        container.innerHTML = '<h3 style="font-size:11px;margin-bottom:6px;">' + fx.type + '</h3>';
        p.forEach(param => {
          const val = fx.params[param] || 50;
          container.innerHTML += '<div class="field"><label>' + param + '</label><input type="range" min="0" max="100" value="' + val + '"><span style="font-size:10px;">' + val + '</span></div>';
        });
      }

      function buildBusRouting() {
        const container = document.getElementById('busRouting');
        container.innerHTML = '';
        channels.forEach((ch, i) => {
          if (i === 0) return;
          const row = document.createElement('div');
          row.className = 'bus-row';
          row.innerHTML = '<span style="width:60px;">' + ch.name + '</span><select data-ch="' + i + '"><option value="master">Master</option><option value="bus1">Bus 1</option><option value="bus2">Bus 2</option></select>';
          row.querySelector('select').value = ch.bus;
          row.querySelector('select').addEventListener('change', (e) => { channels[i].bus = e.target.value; });
          container.appendChild(row);
        });
      }

      document.getElementById('addEffect').addEventListener('change', (e) => {
        if (e.target.value) {
          effects.push({ type: e.target.value, channel: selectedChannel, params: {} });
          e.target.value = '';
          buildEffects();
        }
      });

      document.getElementById('btnAddChannel').addEventListener('click', () => {
        const n = channels.length;
        channels.push({ name: 'Ch ' + n, volume: 80, pan: 50, mute: false, solo: false, vu: 0, bus: 'master' });
        buildMixer();
      });

      document.getElementById('btnRemoveChannel').addEventListener('click', () => {
        if (channels.length > 1) { channels.pop(); buildMixer(); }
      });

      document.getElementById('btnResetAll').addEventListener('click', () => {
        channels.forEach((ch, i) => { ch.volume = i === 0 ? 100 : 80; ch.pan = 50; ch.mute = false; ch.solo = false; });
        effects = [];
        buildMixer(); buildEffects();
      });

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  channels = {\\n';
        channels.forEach(ch => {
          lua += '    { name = "' + ch.name + '", volume = ' + (ch.volume/100).toFixed(2) + ', pan = ' + ((ch.pan-50)/50).toFixed(2) + ', mute = ' + ch.mute + ', bus = "' + ch.bus + '" },\\n';
        });
        lua += '  },\\n  effects = {\\n';
        effects.forEach(fx => {
          lua += '    { type = "' + fx.type + '", channel = ' + (fx.channel+1) + ' },\\n';
        });
        lua += '  }\\n}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      // Animate VU meters
      setInterval(() => {
        document.querySelectorAll('.vu-fill').forEach((el, i) => {
          const ch = channels[i];
          if (ch && !ch.mute) {
            const level = 20 + Math.random() * 60 * (ch.volume / 100);
            el.style.height = level + '%';
          } else if (ch && ch.mute) {
            el.style.height = '0%';
          }
        });
      }, 100);

      buildMixer();
      buildEffects();
      buildBusRouting();
    `);
  }
}
