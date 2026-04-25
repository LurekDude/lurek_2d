import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

export class SoundDspEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): SoundDspEditor {
    return new SoundDspEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.editor.soundDsp", "Sound DSP Panel");
  }

  protected handleMessage(msg: { type: string; [key: string]: unknown }): void {
    if (msg.type === "copyCode") {
      vscode.env.clipboard.writeText(msg.code as string);
      vscode.window.showInformationMessage("Sound DSP code copied to clipboard.");
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
    return wrapHtml(nonce, "Sound DSP Panel", `
      .editor-layout {
        display: grid; grid-template-columns: 1fr;
        grid-template-rows: auto auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-row: 1; }
      .tab-bar { display: flex; gap: 2px; padding: 2px 6px; background: var(--surface); border-bottom: 1px solid var(--border); overflow-x: auto; }
      .tab { padding: 4px 10px; border-radius: var(--radius) var(--radius) 0 0; font-size: 11px; cursor: pointer; background: transparent; border: 1px solid transparent; border-bottom: none; color: var(--text-dim); white-space: nowrap; }
      .tab:hover { background: var(--hover); }
      .tab.sel { background: var(--surface-2); color: var(--text); border-color: var(--border); }
      .main-area { display: grid; grid-template-columns: 320px 1fr; gap: 0; overflow: hidden; }
      .controls-panel { overflow-y: auto; padding: 6px; border-right: 1px solid var(--border); background: var(--surface); }
      .vis-panel { overflow-y: auto; padding: 6px; background: var(--bg); }
      .status-bar { grid-row: 4; }
      .dsp-row { display: flex; align-items: center; gap: 6px; margin-bottom: 4px; font-size: 11px; }
      .dsp-row label { min-width: 130px; color: var(--text-dim); }
      .dsp-row input[type=range] { flex: 1; }
      .val { font-size: 10px; min-width: 40px; text-align: right; color: var(--text-dim); font-family: var(--font-mono, monospace); }
      .vis-box { background: var(--bg); border-radius: var(--radius); border: 1px solid var(--border); padding: 4px; margin-bottom: 6px; }
      canvas { display: block; border-radius: var(--radius); }
      .eq-bands { display: flex; gap: 4px; align-items: flex-end; height: 110px; padding: 6px; background: var(--bg); border-radius: var(--radius); border: 1px solid var(--border); }
      .eq-band { display: flex; flex-direction: column; align-items: center; gap: 2px; flex: 1; }
      .eq-band input[type=range] { writing-mode: vertical-lr; direction: rtl; width: 20px; height: 70px; }
      .eq-band label { font-size: 9px; color: var(--text-dim); white-space: nowrap; }
      .eq-band .val { font-size: 9px; }
      .preset-row { display: flex; align-items: center; gap: 4px; margin-bottom: 6px; flex-wrap: wrap; }
      .preset-btn { font-size: 10px; padding: 2px 7px; border-radius: var(--radius); cursor: pointer; background: var(--surface-2); border: 1px solid var(--border); color: var(--text); transition: background 0.1s; }
      .preset-btn:hover { background: var(--accent); color: var(--bg); border-color: var(--accent); }
      .signal-chain { display: flex; gap: 4px; align-items: center; flex-wrap: wrap; font-size: 11px; margin-bottom: 6px; }
      .chain-node { background: var(--surface-2); border: 1px solid var(--accent); border-radius: var(--radius); padding: 2px 7px; color: var(--accent); font-size: 10px; }
      .chain-arrow { color: var(--text-dim); font-size: 10px; }
      .code-out { font-family: var(--font-mono, 'Cascadia Code', monospace); font-size: 10px; background: var(--bg); color: var(--accent); border-radius: var(--radius); border: 1px solid var(--border); padding: 6px; overflow-x: auto; white-space: pre; max-height: 280px; overflow-y: auto; margin: 4px 0; }
      .vis-mode-row { display: flex; gap: 8px; margin: 4px 0 6px; font-size: 10px; color: var(--text-dim); align-items: center; }
      .vis-mode-row label { cursor: pointer; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${iconButton(ICONS.copy, 'btnCopy', 'Copy Code')}
            ${iconButton(ICONS.add, 'btnInsert', 'Insert at Cursor')}
          </div>
          ${toolbarSep()}
          <div class="group" style="font-size:10px;color:var(--text-dim)">Sound DSP Designer</div>
          ${toolbarSpacer()}
          ${iconButton(ICONS.save, 'btnExport', 'Export Lua')}
        </div>

        <div class="tab-bar" id="tabs">
          <button class="tab sel" data-tab="chain">Signal Chain</button>
          <button class="tab" data-tab="eq">Equalizer</button>
          <button class="tab" data-tab="reverb">Reverb</button>
          <button class="tab" data-tab="echo">Echo / Delay</button>
          <button class="tab" data-tab="chorus">Chorus</button>
          <button class="tab" data-tab="pitch">Pitch</button>
          <button class="tab" data-tab="dynamics">Dynamics</button>
          <button class="tab" data-tab="generator">Sound Gen</button>
        </div>

        <div class="main-area">
          <div class="controls-panel">
            <!-- SIGNAL CHAIN -->
            <div id="tab-chain">
              ${panelSection('Signal Chain', '<div id="signalChain" class="signal-chain"></div>')}
              ${panelSection('Master', `
                <div class="dsp-row"><label>Volume</label><input type="range" id="masterVolume" min="0" max="2" step="0.01" value="1"><span class="val" id="masterVolumeVal">1.00</span></div>
                <div class="dsp-row"><label>Pan</label><input type="range" id="masterPan" min="-1" max="1" step="0.01" value="0"><span class="val" id="masterPanVal">0.00</span></div>
                <div class="dsp-row"><label>Sample Rate</label>
                  <select id="sampleRate"><option value="22050">22050 Hz</option><option value="44100" selected>44100 Hz</option><option value="48000">48000 Hz</option></select>
                </div>
              `)}
            </div>
            <!-- EQ -->
            <div id="tab-eq" style="display:none">
              ${panelSection('EQ Presets', `
                <div class="preset-row">
                  <button class="preset-btn" data-eq="flat">Flat</button>
                  <button class="preset-btn" data-eq="bass">Bass</button>
                  <button class="preset-btn" data-eq="treble">Treble</button>
                  <button class="preset-btn" data-eq="vocal">Vocal</button>
                  <button class="preset-btn" data-eq="underwater">Underwater</button>
                  <button class="preset-btn" data-eq="telephone">Telephone</button>
                  <button class="preset-btn" data-eq="radio">Lo-Fi</button>
                </div>
              `)}
              ${panelSection('7-Band Parametric EQ', '<div class="eq-bands" id="eqBands"></div>')}
            </div>
            <!-- REVERB -->
            <div id="tab-reverb" style="display:none">
              ${panelSection('Room Presets', `
                <div class="preset-row">
                  <button class="preset-btn" data-reverb="small">Small</button>
                  <button class="preset-btn" data-reverb="medium">Medium</button>
                  <button class="preset-btn" data-reverb="large">Large</button>
                  <button class="preset-btn" data-reverb="cave">Cave</button>
                  <button class="preset-btn" data-reverb="plate">Plate</button>
                  <button class="preset-btn" data-reverb="spring">Spring</button>
                </div>
              `)}
              ${panelSection('Reverb', `
                <div class="dsp-row"><label>Room Size</label><input type="range" id="reverbRoom" min="0" max="1" step="0.01" value="0.5"><span class="val" id="reverbRoomVal">0.50</span></div>
                <div class="dsp-row"><label>Damping</label><input type="range" id="reverbDamp" min="0" max="1" step="0.01" value="0.5"><span class="val" id="reverbDampVal">0.50</span></div>
                <div class="dsp-row"><label>Wet / Dry</label><input type="range" id="reverbMix" min="0" max="1" step="0.01" value="0.3"><span class="val" id="reverbMixVal">0.30</span></div>
                <div class="dsp-row"><label>Pre-delay (ms)</label><input type="range" id="reverbPredelay" min="0" max="100" step="1" value="10"><span class="val" id="reverbPredelayVal">10</span></div>
                <div class="dsp-row"><label>Width</label><input type="range" id="reverbWidth" min="0" max="1" step="0.01" value="1"><span class="val" id="reverbWidthVal">1.00</span></div>
                <div class="dsp-row"><label>Decay (s)</label><input type="range" id="reverbDecay" min="0.1" max="10" step="0.1" value="2"><span class="val" id="reverbDecayVal">2.0</span></div>
              `)}
            </div>
            <!-- ECHO -->
            <div id="tab-echo" style="display:none">
              ${panelSection('Echo / Delay', `
                <div class="dsp-row"><label>Delay (ms)</label><input type="range" id="echoDelay" min="10" max="2000" step="10" value="400"><span class="val" id="echoDelayVal">400</span></div>
                <div class="dsp-row"><label>Feedback</label><input type="range" id="echoFeedback" min="0" max="0.99" step="0.01" value="0.4"><span class="val" id="echoFeedbackVal">0.40</span></div>
                <div class="dsp-row"><label>Wet / Dry</label><input type="range" id="echoMix" min="0" max="1" step="0.01" value="0.4"><span class="val" id="echoMixVal">0.40</span></div>
                <div class="dsp-row"><label>Ping-Pong</label><input type="checkbox" id="echoPingPong"></div>
                <div class="dsp-row"><label>Sync BPM</label><input type="checkbox" id="echoSyncBpm"></div>
                <div class="dsp-row" id="bpmRow"><label>BPM</label><input type="range" id="echoBpm" min="60" max="200" step="1" value="120"><span class="val" id="echoBpmVal">120</span></div>
                <div class="dsp-row" id="divRow"><label>Division</label>
                  <select id="echoDiv"><option value="1">1/4</option><option value="0.5">1/8</option><option value="0.75">Dot 1/8</option><option value="0.333">Triplet</option></select>
                </div>
              `)}
            </div>
            <!-- CHORUS -->
            <div id="tab-chorus" style="display:none">
              ${panelSection('Chorus / Flanger', `
                <div class="dsp-row"><label>Mode</label>
                  <select id="chorusMode"><option>Chorus</option><option>Flanger</option><option>Ensemble</option><option>Vibrato</option></select>
                </div>
                <div class="dsp-row"><label>Depth</label><input type="range" id="chorusDepth" min="0" max="1" step="0.01" value="0.5"><span class="val" id="chorusDepthVal">0.50</span></div>
                <div class="dsp-row"><label>Rate (Hz)</label><input type="range" id="chorusRate" min="0.1" max="10" step="0.1" value="1.5"><span class="val" id="chorusRateVal">1.50</span></div>
                <div class="dsp-row"><label>Wet / Dry</label><input type="range" id="chorusMix" min="0" max="1" step="0.01" value="0.4"><span class="val" id="chorusMixVal">0.40</span></div>
                <div class="dsp-row"><label>Voices</label><input type="range" id="chorusVoices" min="2" max="8" step="1" value="3"><span class="val" id="chorusVoicesVal">3</span></div>
                <div class="dsp-row"><label>Stereo Spread</label><input type="range" id="chorusSpread" min="0" max="1" step="0.01" value="0.7"><span class="val" id="chorusSpreadVal">0.70</span></div>
                <div class="dsp-row"><label>Flange FB</label><input type="range" id="flangerFeedback" min="0" max="0.95" step="0.01" value="0.5"><span class="val" id="flangerFeedbackVal">0.50</span></div>
              `)}
            </div>
            <!-- PITCH -->
            <div id="tab-pitch" style="display:none">
              ${panelSection('Pitch Shift', `
                <div class="dsp-row"><label>Semitones</label><input type="range" id="pitchSemitones" min="-24" max="24" step="1" value="0"><span class="val" id="pitchSemitonesVal">0 st</span></div>
                <div class="dsp-row"><label>Fine (cents)</label><input type="range" id="pitchCents" min="-100" max="100" step="1" value="0"><span class="val" id="pitchCentsVal">0\u00A2</span></div>
                <div class="dsp-row"><label>Formant</label><input type="checkbox" id="pitchFormant"></div>
                <div class="dsp-row"><label>Rate</label><input type="range" id="pitchRate" min="0.25" max="4" step="0.05" value="1"><span class="val" id="pitchRateVal">1.00\u00D7</span></div>
              `)}
              ${panelSection('Pitch Envelope', `
                <div class="dsp-row"><label>Sweep Start</label><input type="range" id="pitchSweepFrom" min="-12" max="12" step="1" value="0"><span class="val" id="pitchSweepFromVal">0 st</span></div>
                <div class="dsp-row"><label>Sweep End</label><input type="range" id="pitchSweepTo" min="-12" max="12" step="1" value="0"><span class="val" id="pitchSweepToVal">0 st</span></div>
                <div class="dsp-row"><label>Sweep Time (s)</label><input type="range" id="pitchSweepTime" min="0.01" max="2" step="0.01" value="0.5"><span class="val" id="pitchSweepTimeVal">0.50</span></div>
              `)}
            </div>
            <!-- DYNAMICS -->
            <div id="tab-dynamics" style="display:none">
              ${panelSection('Compressor', `
                <div class="dsp-row"><label>Threshold (dB)</label><input type="range" id="compThreshold" min="-60" max="0" step="1" value="-24"><span class="val" id="compThresholdVal">-24</span></div>
                <div class="dsp-row"><label>Ratio</label><input type="range" id="compRatio" min="1" max="20" step="0.5" value="4"><span class="val" id="compRatioVal">4:1</span></div>
                <div class="dsp-row"><label>Attack (ms)</label><input type="range" id="compAttack" min="0.1" max="200" step="0.1" value="10"><span class="val" id="compAttackVal">10</span></div>
                <div class="dsp-row"><label>Release (ms)</label><input type="range" id="compRelease" min="10" max="2000" step="10" value="200"><span class="val" id="compReleaseVal">200</span></div>
                <div class="dsp-row"><label>Makeup (dB)</label><input type="range" id="compMakeup" min="0" max="24" step="0.5" value="0"><span class="val" id="compMakeupVal">0</span></div>
              `)}
              ${panelSection('Gate / Limiter', `
                <div class="dsp-row"><label>Gate (dB)</label><input type="range" id="gateThreshold" min="-80" max="0" step="1" value="-60"><span class="val" id="gateThresholdVal">-60</span></div>
                <div class="dsp-row"><label>Ceiling (dB)</label><input type="range" id="limiterCeil" min="-20" max="0" step="0.5" value="-0.3"><span class="val" id="limiterCeilVal">-0.3</span></div>
              `)}
              ${panelSection('Distortion', `
                <div class="dsp-row"><label>Drive</label><input type="range" id="distDrive" min="0" max="1" step="0.01" value="0"><span class="val" id="distDriveVal">0.00</span></div>
                <div class="dsp-row"><label>Mode</label>
                  <select id="distMode"><option>Soft Clip</option><option>Hard Clip</option><option>Fuzz</option><option>Bit Crush</option><option>Overdrive</option></select>
                </div>
                <div class="dsp-row"><label>Mix</label><input type="range" id="distMix" min="0" max="1" step="0.01" value="0.5"><span class="val" id="distMixVal">0.50</span></div>
              `)}
            </div>
            <!-- GENERATOR -->
            <div id="tab-generator" style="display:none">
              ${panelSection('Waveform', `
                <div class="dsp-row"><label>Type</label>
                  <select id="genType"><option>Sine</option><option>Square</option><option>Sawtooth</option><option>Triangle</option><option>Noise</option><option>Pulse</option></select>
                </div>
                <div class="dsp-row"><label>Frequency (Hz)</label><input type="range" id="genFreq" min="20" max="4000" step="1" value="440"><span class="val" id="genFreqVal">440 Hz</span></div>
                <div class="dsp-row"><label>Volume</label><input type="range" id="genVol" min="0" max="1" step="0.01" value="0.5"><span class="val" id="genVolVal">0.50</span></div>
                <div class="dsp-row"><label>Duration (s)</label><input type="range" id="genDur" min="0.01" max="5" step="0.01" value="0.5"><span class="val" id="genDurVal">0.50</span></div>
              `)}
              ${panelSection('ADSR Envelope', `
                <div class="dsp-row"><label>Attack (s)</label><input type="range" id="adsrAttack" min="0.001" max="2" step="0.001" value="0.01"><span class="val" id="adsrAttackVal">0.010</span></div>
                <div class="dsp-row"><label>Decay (s)</label><input type="range" id="adsrDecay" min="0.001" max="2" step="0.001" value="0.1"><span class="val" id="adsrDecayVal">0.100</span></div>
                <div class="dsp-row"><label>Sustain</label><input type="range" id="adsrSustain" min="0" max="1" step="0.01" value="0.7"><span class="val" id="adsrSustainVal">0.70</span></div>
                <div class="dsp-row"><label>Release (s)</label><input type="range" id="adsrRelease" min="0.001" max="3" step="0.001" value="0.3"><span class="val" id="adsrReleaseVal">0.300</span></div>
              `)}
              ${panelSection('Sound Presets', `
                <div class="preset-row">
                  <button class="preset-btn" data-sound="laser">Laser</button>
                  <button class="preset-btn" data-sound="explosion">Explosion</button>
                  <button class="preset-btn" data-sound="jump">Jump</button>
                  <button class="preset-btn" data-sound="coin">Coin</button>
                  <button class="preset-btn" data-sound="powerup">Power-up</button>
                  <button class="preset-btn" data-sound="hurt">Hurt</button>
                  <button class="preset-btn" data-sound="blip">UI Blip</button>
                </div>
              `)}
            </div>
          </div>

          <div class="vis-panel">
            <div class="vis-box">
              <canvas id="visCanvas" width="560" height="120"></canvas>
            </div>
            <div class="vis-mode-row">
              <label><input type="radio" name="visMode" value="freq" checked> Frequency</label>
              <label><input type="radio" name="visMode" value="wave"> Waveform</label>
              <label><input type="radio" name="visMode" value="lissajous"> Lissajous</label>
            </div>
            ${panelSection('Generated Lua Code', '<pre class="code-out" id="codeOut"></pre>')}
          </div>
        </div>

        <div class="status-bar">
          <span id="statusTab" class="badge">chain</span>
          <div class="sep"></div>
          <span id="statusRate">44100 Hz</span>
          <div class="sep"></div>
          <span id="statusVol">vol 1.00</span>
          <div class="spacer"></div>
          <span id="statusDirty" style="font-size:10px;color:var(--text-dim)">${ICONS.clean}</span>
        </div>
      </div>
    `, `
      const undo = new UndoStack();
      let curTab = 'chain';

      document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', () => {
          curTab = tab.dataset.tab;
          document.querySelectorAll('.tab').forEach(t => t.classList.remove('sel'));
          tab.classList.add('sel');
          document.querySelectorAll('[id^="tab-"]').forEach(s => s.style.display = 'none');
          document.getElementById('tab-' + curTab).style.display = '';
          document.getElementById('statusTab').textContent = curTab;
          genCode(); drawVis();
        });
      });

      registerShortcut('ctrl+z', () => { /* undo placeholder */ });
      registerShortcut('ctrl+shift+z', () => { /* redo placeholder */ });
      registerShortcut('ctrl+s', () => document.getElementById('btnExport').click());

      document.querySelectorAll('input[type=range]').forEach(r => {
        const v = document.getElementById(r.id + 'Val');
        function fmt(val) {
          if (r.id === 'pitchSemitones' || r.id === 'pitchSweepFrom' || r.id === 'pitchSweepTo') return val + ' st';
          if (r.id === 'pitchCents') return val + '\\u00A2';
          if (r.id === 'pitchRate') return parseFloat(val).toFixed(2) + '\\u00D7';
          if (r.id === 'compRatio') return parseFloat(val).toFixed(1) + ':1';
          if (r.id === 'genFreq') return val + ' Hz';
          if (r.step && parseFloat(r.step) >= 1) return Math.round(val).toString();
          return parseFloat(val).toFixed(parseFloat(r.step) < 0.01 ? 3 : 2);
        }
        if (v) { v.textContent = fmt(r.value); r.addEventListener('input', () => { v.textContent = fmt(r.value); markDirty(); genCode(); drawVis(); }); }
        r.addEventListener('input', genCode);
      });
      document.querySelectorAll('select,input[type=checkbox]').forEach(el => el.addEventListener('change', () => { markDirty(); genCode(); drawVis(); }));

      const EQ_BANDS = [
        { freq:'60Hz', id:'eq0' }, { freq:'150Hz', id:'eq1' }, { freq:'400Hz', id:'eq2' },
        { freq:'1kHz', id:'eq3' }, { freq:'2.5kHz', id:'eq4' }, { freq:'6kHz', id:'eq5' }, { freq:'16kHz', id:'eq6' },
      ];
      const eqC = document.getElementById('eqBands');
      EQ_BANDS.forEach(b => {
        eqC.innerHTML += '<div class="eq-band"><input type="range" id="'+b.id+'" min="-12" max="12" step="0.5" value="0" orient="vertical"><label>'+b.freq+'</label><span class="val" id="'+b.id+'Val">0</span></div>';
      });
      document.querySelectorAll('#eqBands input[type=range]').forEach(r => {
        const v = document.getElementById(r.id + 'Val');
        if (v) r.addEventListener('input', () => { v.textContent = parseFloat(r.value).toFixed(1); markDirty(); genCode(); drawVis(); });
      });

      const eqPresets = { flat:[0,0,0,0,0,0,0], bass:[8,6,3,0,-1,-1,-2], treble:[-1,-1,0,1,3,5,7], vocal:[-2,0,2,4,3,1,-1], underwater:[-8,-6,-4,-2,-6,-10,-12], telephone:[-12,0,4,6,4,0,-12], radio:[-10,-4,2,6,4,2,-8] };
      document.querySelectorAll('[data-eq]').forEach(btn => {
        btn.addEventListener('click', () => { const vals=eqPresets[btn.dataset.eq]; EQ_BANDS.forEach((b,i)=>{const el=document.getElementById(b.id),v=document.getElementById(b.id+'Val');if(el){el.value=vals[i];if(v)v.textContent=vals[i].toFixed(1);}}); markDirty(); genCode(); drawVis(); });
      });

      const revPresets = { small:{room:0.2,damp:0.7,mix:0.2,predelay:5,width:0.6,decay:0.5}, medium:{room:0.5,damp:0.5,mix:0.3,predelay:20,width:0.9,decay:2.0}, large:{room:0.85,damp:0.3,mix:0.4,predelay:40,width:1.0,decay:5.0}, cave:{room:0.9,damp:0.1,mix:0.5,predelay:50,width:0.8,decay:7.0}, plate:{room:0.4,damp:0.8,mix:0.35,predelay:0,width:1.0,decay:1.5}, spring:{room:0.3,damp:0.6,mix:0.4,predelay:10,width:0.5,decay:1.2} };
      document.querySelectorAll('[data-reverb]').forEach(btn => {
        btn.addEventListener('click', () => { const p=revPresets[btn.dataset.reverb]; Object.entries({reverbRoom:p.room,reverbDamp:p.damp,reverbMix:p.mix,reverbPredelay:p.predelay,reverbWidth:p.width,reverbDecay:p.decay}).forEach(([id,val])=>{const el=document.getElementById(id),v=document.getElementById(id+'Val');if(el){el.value=val;if(v)v.textContent=parseFloat(el.step)>=1?Math.round(val):parseFloat(val).toFixed(2);}}); markDirty(); genCode(); drawVis(); });
      });

      const sndPresets = { laser:{type:'Square',freq:880,vol:0.7,dur:0.15,atk:0.001,dec:0.05,sus:0.3,rel:0.1,sweepFrom:6,sweepTo:-12,sweepTime:0.15}, explosion:{type:'Noise',freq:80,vol:0.9,dur:1.2,atk:0.001,dec:0.2,sus:0.2,rel:1.0,sweepFrom:0,sweepTo:-8,sweepTime:0.8}, jump:{type:'Sine',freq:220,vol:0.6,dur:0.3,atk:0.005,dec:0.1,sus:0.0,rel:0.15,sweepFrom:0,sweepTo:7,sweepTime:0.2}, coin:{type:'Sine',freq:660,vol:0.7,dur:0.2,atk:0.001,dec:0.05,sus:0.5,rel:0.1,sweepFrom:0,sweepTo:5,sweepTime:0.1}, powerup:{type:'Sawtooth',freq:220,vol:0.6,dur:0.6,atk:0.005,dec:0.1,sus:0.7,rel:0.2,sweepFrom:-5,sweepTo:7,sweepTime:0.5}, hurt:{type:'Triangle',freq:120,vol:0.8,dur:0.25,atk:0.001,dec:0.05,sus:0.3,rel:0.2,sweepFrom:2,sweepTo:-6,sweepTime:0.2}, blip:{type:'Sine',freq:440,vol:0.4,dur:0.07,atk:0.001,dec:0.01,sus:0.0,rel:0.05,sweepFrom:0,sweepTo:0,sweepTime:0.0} };
      document.querySelectorAll('[data-sound]').forEach(btn => {
        btn.addEventListener('click', () => {
          const p=sndPresets[btn.dataset.sound]; document.getElementById('genType').value=p.type;
          const fields={genFreq:p.freq,genVol:p.vol,genDur:p.dur,adsrAttack:p.atk,adsrDecay:p.dec,adsrSustain:p.sus,adsrRelease:p.rel,pitchSweepFrom:p.sweepFrom,pitchSweepTo:p.sweepTo,pitchSweepTime:p.sweepTime};
          Object.entries(fields).forEach(([id,val])=>{const el=document.getElementById(id),v=document.getElementById(id+'Val');if(el){el.value=val;if(v)v.textContent=el.step&&parseFloat(el.step)>=1?Math.round(val):parseFloat(val).toFixed(parseFloat(el.step||'0.01')<0.01?3:2);}});
          markDirty(); genCode(); drawVis();
        });
      });

      function g(id) { return document.getElementById(id); }
      function fv(id) { return parseFloat(g(id).value); }
      function bv(id) { return g(id).checked; }
      function sv(id) { return g(id).value; }

      function genCode() {
        let code = '';
        if (curTab === 'chain') {
          code = '-- Sound DSP Chain\\nlocal dsp = lurek.audio.createDsp()\\n\\n';
          code += 'dsp:setMasterVolume(' + fv('masterVolume').toFixed(2) + ')\\n';
          code += 'dsp:setMasterPan(' + fv('masterPan').toFixed(2) + ')\\n';
          code += 'dsp:setSampleRate(' + sv('sampleRate') + ')\\n\\n';
          code += '-- Apply DSP to a source:\\nlocal src = lurek.audio.load("my_sound.wav")\\n';
          code += 'lurek.audio.setDsp(src, dsp)\\nlurek.audio.play(src)';
        } else if (curTab === 'eq') {
          code = '-- 7-Band Parametric EQ\\nlocal eq = lurek.audio.createEq({\\n';
          const freqs = ['60','150','400','1000','2500','6000','16000'];
          EQ_BANDS.forEach((b,i) => { const gain=fv(b.id); if(gain!==0) code+='  { freq='+freqs[i]+', gain='+gain.toFixed(1)+' },\\n'; });
          code += '})\\nlurek.audio.addEffect(src, eq)';
        } else if (curTab === 'reverb') {
          code = '-- Reverb Effect\\nlocal reverb = lurek.audio.createReverb({\\n';
          code += '  room_size  = '+fv('reverbRoom').toFixed(2)+',\\n  damping    = '+fv('reverbDamp').toFixed(2)+',\\n';
          code += '  wet_dry    = '+fv('reverbMix').toFixed(2)+',\\n  pre_delay  = '+fv('reverbPredelay')+',\\n';
          code += '  width      = '+fv('reverbWidth').toFixed(2)+',\\n  decay      = '+fv('reverbDecay').toFixed(1)+',\\n';
          code += '})\\nlurek.audio.addEffect(src, reverb)';
        } else if (curTab === 'echo') {
          const syncBpm = bv('echoSyncBpm');
          code = '-- Echo / Delay\\nlocal echo = lurek.audio.createEcho({\\n';
          if (syncBpm) { code += '  bpm = '+fv('echoBpm')+', division = '+fv('echoDiv')+',\\n'; }
          else { code += '  delay_ms = '+fv('echoDelay')+',\\n'; }
          code += '  feedback = '+fv('echoFeedback').toFixed(2)+', wet_dry = '+fv('echoMix').toFixed(2)+',\\n';
          code += '  ping_pong = '+bv('echoPingPong')+',\\n})\\nlurek.audio.addEffect(src, echo)';
        } else if (curTab === 'chorus') {
          code = '-- '+sv('chorusMode')+' Effect\\nlocal chorus = lurek.audio.createChorus({\\n';
          code += '  mode = "'+sv('chorusMode').toLowerCase()+'", depth = '+fv('chorusDepth').toFixed(2)+',\\n';
          code += '  rate = '+fv('chorusRate').toFixed(2)+', wet_dry = '+fv('chorusMix').toFixed(2)+',\\n';
          code += '  voices = '+fv('chorusVoices')+', spread = '+fv('chorusSpread').toFixed(2)+',\\n';
          if (sv('chorusMode')==='Flanger') code += '  feedback = '+fv('flangerFeedback').toFixed(2)+',\\n';
          code += '})\\nlurek.audio.addEffect(src, chorus)';
        } else if (curTab === 'pitch') {
          const semi=fv('pitchSemitones'),cents=fv('pitchCents'),rate=fv('pitchRate');
          const sf=fv('pitchSweepFrom'),st2=fv('pitchSweepTo'),sTime=fv('pitchSweepTime');
          code = '-- Pitch Shift\\nlocal pitch = lurek.audio.createPitchShift({\\n';
          if(semi!==0) code+='  semitones = '+semi+',\\n';
          if(cents!==0) code+='  cents = '+cents+',\\n';
          if(rate!==1) code+='  rate = '+rate.toFixed(2)+',\\n';
          code += '  preserve_formants = '+bv('pitchFormant')+',\\n';
          if(sf!==0||st2!==0) code+='  sweep = { from='+sf+', to='+st2+', time='+sTime.toFixed(2)+' },\\n';
          code += '})\\nlurek.audio.addEffect(src, pitch)';
        } else if (curTab === 'dynamics') {
          const drive=fv('distDrive');
          code = '-- Dynamics Processing\\nlocal chain = lurek.audio.createDynamics({\\n';
          code += '  comp = {\\n    threshold = '+fv('compThreshold')+',\\n    ratio = '+fv('compRatio').toFixed(1)+',\\n';
          code += '    attack = '+fv('compAttack').toFixed(1)+',\\n    release = '+fv('compRelease')+',\\n';
          code += '    makeup = '+fv('compMakeup').toFixed(1)+',\\n  },\\n';
          code += '  gate = { threshold='+fv('gateThreshold')+' },\\n';
          code += '  limiter = { ceiling='+fv('limiterCeil').toFixed(1)+' },\\n';
          if(drive>0) code+='  distortion = { drive='+drive.toFixed(2)+', mode="'+sv('distMode').toLowerCase().replace(/ /g,'_')+'", mix='+fv('distMix').toFixed(2)+' },\\n';
          code += '})\\nlurek.audio.addEffect(src, chain)';
        } else if (curTab === 'generator') {
          const type=sv('genType').toLowerCase();
          code = '-- Procedural Sound: '+sv('genType')+'\\nlocal synth = lurek.audio.createSynth({\\n';
          code += '  wave = "'+type+'", frequency = '+fv('genFreq')+',\\n';
          code += '  volume = '+fv('genVol').toFixed(2)+', duration = '+fv('genDur').toFixed(2)+',\\n';
          code += '  adsr = { attack='+fv('adsrAttack').toFixed(3)+', decay='+fv('adsrDecay').toFixed(3)+', sustain='+fv('adsrSustain').toFixed(2)+', release='+fv('adsrRelease').toFixed(3)+' },\\n';
          const sf2=fv('pitchSweepFrom'),st3=fv('pitchSweepTo'),sT=fv('pitchSweepTime');
          if(sf2!==0||st3!==0) code+='  sweep = { from='+sf2+', to='+st3+', time='+sT.toFixed(2)+' },\\n';
          code += '})\\nlurek.audio.play(lurek.audio.fromSynth(synth))';
        }
        g('codeOut').textContent = code;
        updateChain();
        g('statusVol').textContent = 'vol '+fv('masterVolume').toFixed(2);
        g('statusRate').textContent = sv('sampleRate')+' Hz';
      }

      function updateChain() {
        const chain = g('signalChain');
        const nodes = ['Input','EQ','Reverb','Echo','Chorus','Pitch','Dynamics','Out'];
        chain.innerHTML = nodes.map(n => '<span class="chain-node">'+n+'</span>').join('<span class="chain-arrow">\\u2192</span>');
      }

      function drawVis() {
        const cvs = g('visCanvas'); if (!cvs) return;
        const cx = cvs.getContext('2d'), W = cvs.width, H = cvs.height;
        const bgCol = getComputedStyle(document.documentElement).getPropertyValue('--bg').trim() || '#1e1e1e';
        const accentCol = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim() || '#4fc3f7';
        const borderCol = getComputedStyle(document.documentElement).getPropertyValue('--border').trim() || '#333';
        const dimCol = getComputedStyle(document.documentElement).getPropertyValue('--text-dim').trim() || '#555';
        cx.fillStyle = bgCol; cx.fillRect(0,0,W,H);
        const mode = document.querySelector('input[name=visMode]:checked')?.value || 'freq';
        if (mode === 'freq') {
          cx.strokeStyle = accentCol; cx.lineWidth = 2; cx.beginPath();
          const gains = EQ_BANDS.map((b) => { try{return fv(b.id);}catch{return 0;} });
          for (let x=0;x<W;x++) { let gain=0; gains.forEach((g2,i)=>{const center=i/EQ_BANDS.length;gain+=g2*Math.exp(-Math.pow((x/W-center)*3,2));}); const y=H/2-(gain/12)*(H*0.4); if(x===0)cx.moveTo(x,y);else cx.lineTo(x,y); }
          cx.stroke();
          cx.strokeStyle = borderCol; cx.lineWidth = 1; cx.beginPath(); cx.moveTo(0,H/2); cx.lineTo(W,H/2); cx.stroke();
          ['20Hz','100Hz','1kHz','10kHz','20kHz'].forEach((lbl,i) => { const x=[0,0.12,0.52,0.85,1][i]*W; cx.fillStyle=dimCol; cx.font='9px sans-serif'; cx.fillText(lbl,x+2,H-3); });
        } else if (mode === 'wave') {
          cx.strokeStyle = accentCol; cx.lineWidth = 1.5; cx.beginPath();
          for (let x=0;x<W;x++) { const t=x/W*4*Math.PI; const y=H/2+Math.sin(t+Math.random()*0.05)*H*0.35; if(x===0)cx.moveTo(x,y);else cx.lineTo(x,y); }
          cx.stroke();
        } else {
          cx.strokeStyle = accentCol; cx.lineWidth = 1; cx.globalAlpha = 0.5; cx.beginPath();
          for (let i=0;i<500;i++) { const t=(i/500)*Math.PI*20; const x=W/2+Math.sin(t*1.5)*W*0.4; const y=H/2+Math.cos(t)*H*0.4; if(i===0)cx.moveTo(x,y);else cx.lineTo(x,y); }
          cx.stroke(); cx.globalAlpha = 1;
        }
      }

      document.querySelectorAll('input[name=visMode]').forEach(r => r.addEventListener('change', drawVis));
      document.getElementById('btnCopy').addEventListener('click', () => { vscode.postMessage({type:'copyCode',code:g('codeOut').textContent}); });
      document.getElementById('btnInsert').addEventListener('click', () => { vscode.postMessage({type:'insertCode',code:g('codeOut').textContent}); });
      document.getElementById('btnExport').addEventListener('click', () => { vscode.postMessage({type:'exportLua',content:g('codeOut').textContent}); });
      genCode(); drawVis();
    `);
  }
}
