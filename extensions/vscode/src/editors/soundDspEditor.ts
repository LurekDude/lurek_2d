import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class SoundDspEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): SoundDspEditor {
    return new SoundDspEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "luna.editor.soundDsp", "Sound DSP Panel");
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
      body { overflow-y: auto; }
      .layout { display: grid; grid-template-columns: 320px 1fr; gap: 12px; }
      h3 { font-size: 12px; text-transform: uppercase; letter-spacing:.05em; opacity:.6; margin: 16px 0 6px; }
      .row { display: flex; align-items: center; gap: 8px; margin-bottom: 8px; font-size: 13px; }
      .row label { min-width: 150px; opacity:.8; }
      input[type=range] { flex: 1; }
      .val { font-size: 11px; min-width: 44px; text-align:right; opacity:.7; font-family: monospace; }
      select { background: var(--input-background); color: var(--foreground); border: 1px solid var(--border); padding: 2px 6px; border-radius: 3px; font-size: 12px; }
      .tab-row { display: flex; gap: 4px; margin-bottom: 12px; flex-wrap: wrap; }
      .tab { padding: 4px 10px; border-radius: 3px; font-size: 12px; cursor: pointer; background: var(--surface-2); border: none; color: var(--foreground); }
      .tab.active { background: #0e518c; color: #fff; }
      .vis-box { background: #111; border-radius: 6px; border: 1px solid var(--border); padding: 8px; }
      canvas { display: block; border-radius: 4px; }
      .bypass-toggle { display: inline-flex; align-items: center; gap: 6px; cursor: pointer; font-size: 12px; opacity: .7; }
      .bypass-toggle.active { opacity: 1; color: #4fc3f7; }
      .eq-bands { display: flex; gap: 6px; align-items: flex-end; height: 120px; padding: 8px; background: #111; border-radius: 6px; border: 1px solid var(--border); }
      .eq-band { display: flex; flex-direction: column; align-items: center; gap: 4px; flex: 1; }
      .eq-band input[type=range] { writing-mode: vertical-lr; direction: rtl; width: 24px; height: 80px; }
      .eq-band label { font-size: 10px; opacity: .6; white-space: nowrap; }
      .eq-band .val { font-size: 10px; }
      .preset-row { display: flex; align-items: center; gap: 8px; margin-bottom: 12px; flex-wrap: wrap; }
      .preset-btn { font-size: 11px; padding: 3px 8px; border-radius: 3px; cursor: pointer; background: var(--surface-2); border: 1px solid var(--border); color: var(--foreground); }
      .preset-btn:hover { background: #0e518c; color: #fff; border-color: #0e518c; }
      .signal-chain { display: flex; gap: 6px; align-items: center; flex-wrap: wrap; margin-bottom: 12px; font-size: 12px; }
      .chain-node { background: #1e3a52; border: 1px solid #0e518c; border-radius: 4px; padding: 3px 8px; color: #4fc3f7; }
      .chain-arrow { opacity: .4; }
    `, `
      <h2 style="margin:0 0 12px;font-size:14px">🔊 Sound DSP Panel</h2>
      <div class="tab-row" id="tabs">
        <button class="tab active" data-tab="chain">Signal Chain</button>
        <button class="tab" data-tab="eq">Equalizer</button>
        <button class="tab" data-tab="reverb">Reverb</button>
        <button class="tab" data-tab="echo">Echo / Delay</button>
        <button class="tab" data-tab="chorus">Chorus / Flanger</button>
        <button class="tab" data-tab="pitch">Pitch Shift</button>
        <button class="tab" data-tab="dynamics">Dynamics</button>
        <button class="tab" data-tab="generator">Sound Gen</button>
      </div>
      <div class="layout">
        <div>
          <!-- SIGNAL CHAIN -->
          <div id="tab-chain">
            <h3>Active Signal Chain</h3>
            <div id="signalChain" class="signal-chain"></div>
            <h3>Effect Order (drag to reorder)</h3>
            <div id="effectList" style="font-size:12px;"></div>
            <h3>Master</h3>
            <div class="row"><label>Master Volume</label><input type="range" id="masterVolume" min="0" max="2" step="0.01" value="1"><span class="val" id="masterVolumeVal">1.00</span></div>
            <div class="row"><label>Master Pan</label><input type="range" id="masterPan" min="-1" max="1" step="0.01" value="0"><span class="val" id="masterPanVal">0.00</span></div>
            <div class="row"><label>Sample Rate</label>
              <select id="sampleRate"><option value="22050">22050 Hz</option><option value="44100" selected>44100 Hz</option><option value="48000">48000 Hz</option></select>
            </div>
          </div>
          <!-- EQ -->
          <div id="tab-eq" style="display:none">
            <h3>Equalizer (7-band Parametric)</h3>
            <div class="preset-row">
              <span style="font-size:12px;opacity:.6">Preset:</span>
              <button class="preset-btn" data-eq="flat">Flat</button>
              <button class="preset-btn" data-eq="bass">Bass Boost</button>
              <button class="preset-btn" data-eq="treble">Treble Boost</button>
              <button class="preset-btn" data-eq="vocal">Vocal</button>
              <button class="preset-btn" data-eq="underwater">Underwater</button>
              <button class="preset-btn" data-eq="telephone">Telephone</button>
              <button class="preset-btn" data-eq="radio">Lo-Fi Radio</button>
            </div>
            <div class="eq-bands" id="eqBands"></div>
          </div>
          <!-- REVERB -->
          <div id="tab-reverb" style="display:none">
            <h3>Reverb</h3>
            <div class="preset-row">
              <span style="font-size:12px;opacity:.6">Room:</span>
              <button class="preset-btn" data-reverb="small">Small Room</button>
              <button class="preset-btn" data-reverb="medium">Medium Hall</button>
              <button class="preset-btn" data-reverb="large">Large Hall</button>
              <button class="preset-btn" data-reverb="cave">Cave</button>
              <button class="preset-btn" data-reverb="plate">Plate</button>
              <button class="preset-btn" data-reverb="spring">Spring</button>
            </div>
            <div class="row"><label>Room Size</label><input type="range" id="reverbRoom" min="0" max="1" step="0.01" value="0.5"><span class="val" id="reverbRoomVal">0.50</span></div>
            <div class="row"><label>Damping</label><input type="range" id="reverbDamp" min="0" max="1" step="0.01" value="0.5"><span class="val" id="reverbDampVal">0.50</span></div>
            <div class="row"><label>Wet / Dry Mix</label><input type="range" id="reverbMix" min="0" max="1" step="0.01" value="0.3"><span class="val" id="reverbMixVal">0.30</span></div>
            <div class="row"><label>Pre-delay (ms)</label><input type="range" id="reverbPredelay" min="0" max="100" step="1" value="10"><span class="val" id="reverbPredelayVal">10</span></div>
            <div class="row"><label>Width</label><input type="range" id="reverbWidth" min="0" max="1" step="0.01" value="1"><span class="val" id="reverbWidthVal">1.00</span></div>
            <div class="row"><label>Decay (s)</label><input type="range" id="reverbDecay" min="0.1" max="10" step="0.1" value="2"><span class="val" id="reverbDecayVal">2.0</span></div>
          </div>
          <!-- ECHO/DELAY -->
          <div id="tab-echo" style="display:none">
            <h3>Echo / Delay</h3>
            <div class="row"><label>Delay Time (ms)</label><input type="range" id="echoDelay" min="10" max="2000" step="10" value="400"><span class="val" id="echoDelayVal">400</span></div>
            <div class="row"><label>Feedback</label><input type="range" id="echoFeedback" min="0" max="0.99" step="0.01" value="0.4"><span class="val" id="echoFeedbackVal">0.40</span></div>
            <div class="row"><label>Wet / Dry Mix</label><input type="range" id="echoMix" min="0" max="1" step="0.01" value="0.4"><span class="val" id="echoMixVal">0.40</span></div>
            <div class="row"><label>Ping-Pong</label><input type="checkbox" id="echoPingPong"></div>
            <div class="row"><label>Sync to BPM</label><input type="checkbox" id="echoSyncBpm"></div>
            <div class="row" id="bpmRow"><label>BPM</label><input type="range" id="echoBpm" min="60" max="200" step="1" value="120"><span class="val" id="echoBpmVal">120</span></div>
            <div class="row" id="divRow"><label>Division</label>
              <select id="echoDiv"><option value="1">1/4 note</option><option value="0.5">1/8 note</option><option value="0.75">Dotted 1/8</option><option value="0.333">1/8 triplet</option></select>
            </div>
          </div>
          <!-- CHORUS/FLANGER -->
          <div id="tab-chorus" style="display:none">
            <h3>Chorus / Flanger</h3>
            <div class="row"><label>Mode</label>
              <select id="chorusMode"><option>Chorus</option><option>Flanger</option><option>Ensemble</option><option>Vibrato</option></select>
            </div>
            <div class="row"><label>Depth</label><input type="range" id="chorusDepth" min="0" max="1" step="0.01" value="0.5"><span class="val" id="chorusDepthVal">0.50</span></div>
            <div class="row"><label>Rate (Hz)</label><input type="range" id="chorusRate" min="0.1" max="10" step="0.1" value="1.5"><span class="val" id="chorusRateVal">1.50</span></div>
            <div class="row"><label>Wet / Dry Mix</label><input type="range" id="chorusMix" min="0" max="1" step="0.01" value="0.4"><span class="val" id="chorusMixVal">0.40</span></div>
            <div class="row"><label>Voices</label><input type="range" id="chorusVoices" min="2" max="8" step="1" value="3"><span class="val" id="chorusVoicesVal">3</span></div>
            <div class="row"><label>Stereo Spread</label><input type="range" id="chorusSpread" min="0" max="1" step="0.01" value="0.7"><span class="val" id="chorusSpreadVal">0.70</span></div>
            <div class="row"><label>Flange Feedback</label><input type="range" id="flangerFeedback" min="0" max="0.95" step="0.01" value="0.5"><span class="val" id="flangerFeedbackVal">0.50</span></div>
          </div>
          <!-- PITCH -->
          <div id="tab-pitch" style="display:none">
            <h3>Pitch Shift</h3>
            <div class="row"><label>Semitones</label><input type="range" id="pitchSemitones" min="-24" max="24" step="1" value="0"><span class="val" id="pitchSemitonesVal">0 st</span></div>
            <div class="row"><label>Fine Tune (cents)</label><input type="range" id="pitchCents" min="-100" max="100" step="1" value="0"><span class="val" id="pitchCentsVal">0¢</span></div>
            <div class="row"><label>Formant Preserve</label><input type="checkbox" id="pitchFormant"></div>
            <div class="row"><label>Pitch Rate</label><input type="range" id="pitchRate" min="0.25" max="4" step="0.05" value="1"><span class="val" id="pitchRateVal">1.00×</span></div>
            <h3>Pitch Envelope</h3>
            <div class="row"><label>Pitch Sweep Start</label><input type="range" id="pitchSweepFrom" min="-12" max="12" step="1" value="0"><span class="val" id="pitchSweepFromVal">0 st</span></div>
            <div class="row"><label>Pitch Sweep End</label><input type="range" id="pitchSweepTo" min="-12" max="12" step="1" value="0"><span class="val" id="pitchSweepToVal">0 st</span></div>
            <div class="row"><label>Sweep Time (s)</label><input type="range" id="pitchSweepTime" min="0.01" max="2" step="0.01" value="0.5"><span class="val" id="pitchSweepTimeVal">0.50</span></div>
          </div>
          <!-- DYNAMICS -->
          <div id="tab-dynamics" style="display:none">
            <h3>Compressor</h3>
            <div class="row"><label>Threshold (dB)</label><input type="range" id="compThreshold" min="-60" max="0" step="1" value="-24"><span class="val" id="compThresholdVal">-24</span></div>
            <div class="row"><label>Ratio</label><input type="range" id="compRatio" min="1" max="20" step="0.5" value="4"><span class="val" id="compRatioVal">4:1</span></div>
            <div class="row"><label>Attack (ms)</label><input type="range" id="compAttack" min="0.1" max="200" step="0.1" value="10"><span class="val" id="compAttackVal">10</span></div>
            <div class="row"><label>Release (ms)</label><input type="range" id="compRelease" min="10" max="2000" step="10" value="200"><span class="val" id="compReleaseVal">200</span></div>
            <div class="row"><label>Makeup Gain (dB)</label><input type="range" id="compMakeup" min="0" max="24" step="0.5" value="0"><span class="val" id="compMakeupVal">0</span></div>
            <h3>Gate / Limiter</h3>
            <div class="row"><label>Gate Threshold (dB)</label><input type="range" id="gateThreshold" min="-80" max="0" step="1" value="-60"><span class="val" id="gateThresholdVal">-60</span></div>
            <div class="row"><label>Limiter Ceiling (dB)</label><input type="range" id="limiterCeil" min="-20" max="0" step="0.5" value="-0.3"><span class="val" id="limiterCeilVal">-0.3</span></div>
            <h3>Distortion</h3>
            <div class="row"><label>Drive</label><input type="range" id="distDrive" min="0" max="1" step="0.01" value="0"><span class="val" id="distDriveVal">0.00</span></div>
            <div class="row"><label>Mode</label>
              <select id="distMode"><option>Soft Clip</option><option>Hard Clip</option><option>Fuzz</option><option>Bit Crush</option><option>Overdrive</option></select>
            </div>
            <div class="row"><label>Mix</label><input type="range" id="distMix" min="0" max="1" step="0.01" value="0.5"><span class="val" id="distMixVal">0.50</span></div>
          </div>
          <!-- GENERATOR -->
          <div id="tab-generator" style="display:none">
            <h3>Procedural Sound Generator</h3>
            <div class="row"><label>Type</label>
              <select id="genType"><option>Sine</option><option>Square</option><option>Sawtooth</option><option>Triangle</option><option>Noise</option><option>Pulse</option></select>
            </div>
            <div class="row"><label>Frequency (Hz)</label><input type="range" id="genFreq" min="20" max="4000" step="1" value="440"><span class="val" id="genFreqVal">440 Hz</span></div>
            <div class="row"><label>Volume</label><input type="range" id="genVol" min="0" max="1" step="0.01" value="0.5"><span class="val" id="genVolVal">0.50</span></div>
            <div class="row"><label>Duration (s)</label><input type="range" id="genDur" min="0.01" max="5" step="0.01" value="0.5"><span class="val" id="genDurVal">0.50</span></div>
            <h3>ADSR Envelope</h3>
            <div class="row"><label>Attack (s)</label><input type="range" id="adsrAttack" min="0.001" max="2" step="0.001" value="0.01"><span class="val" id="adsrAttackVal">0.010</span></div>
            <div class="row"><label>Decay (s)</label><input type="range" id="adsrDecay" min="0.001" max="2" step="0.001" value="0.1"><span class="val" id="adsrDecayVal">0.100</span></div>
            <div class="row"><label>Sustain Level</label><input type="range" id="adsrSustain" min="0" max="1" step="0.01" value="0.7"><span class="val" id="adsrSustainVal">0.70</span></div>
            <div class="row"><label>Release (s)</label><input type="range" id="adsrRelease" min="0.001" max="3" step="0.001" value="0.3"><span class="val" id="adsrReleaseVal">0.300</span></div>
            <h3>Sound Presets</h3>
            <div class="preset-row">
              <button class="preset-btn" data-sound="laser">Laser</button>
              <button class="preset-btn" data-sound="explosion">Explosion</button>
              <button class="preset-btn" data-sound="jump">Jump</button>
              <button class="preset-btn" data-sound="coin">Coin</button>
              <button class="preset-btn" data-sound="powerup">Power-up</button>
              <button class="preset-btn" data-sound="hurt">Hurt</button>
              <button class="preset-btn" data-sound="blip">UI Blip</button>
            </div>
          </div>
        </div>

        <div>
          <div class="vis-box">
            <canvas id="visCanvas" width="560" height="120"></canvas>
          </div>
          <div style="display:flex;gap:8px;margin-top:6px;font-size:11px;opacity:.5;align-items:center">
            <span>◉ Frequency Response</span>
            <label><input type="radio" name="visMode" value="freq" checked> Frequency</label>
            <label><input type="radio" name="visMode" value="wave"> Waveform</label>
            <label><input type="radio" name="visMode" value="lissajous"> Lissajous</label>
          </div>
          <h3>Generated Lua Code</h3>
          <pre id="codeOut" style="font-family:'Cascadia Code',monospace;font-size:11px;background:#1a1a1a;color:#9cdcfe;border-radius:4px;padding:10px;overflow-x:auto;white-space:pre;max-height:340px;overflow-y:auto;"></pre>
          <div style="display:flex;gap:8px;margin-top:8px;">
            <button id="btnCopy">📋 Copy Code</button>
            <button id="btnInsert">⤵ Insert at Cursor</button>
          </div>
        </div>
      </div>
    `, `
      const vscode = acquireVsCodeApi();
      let currentTab = 'chain';

      document.querySelectorAll('.tab').forEach(tab => {
        tab.addEventListener('click', () => {
          currentTab = tab.dataset.tab;
          document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
          tab.classList.add('active');
          document.querySelectorAll('[id^="tab-"]').forEach(s => s.style.display = 'none');
          document.getElementById('tab-' + currentTab).style.display = '';
          updateCode(); drawVis();
        });
      });

      // Range value labels
      document.querySelectorAll('input[type=range]').forEach(r => {
        const v = document.getElementById(r.id + 'Val');
        function fmt(val) {
          if (r.id === 'pitchSemitones' || r.id === 'pitchSweepFrom' || r.id === 'pitchSweepTo') return val + ' st';
          if (r.id === 'pitchCents') return val + '¢';
          if (r.id === 'pitchRate') return parseFloat(val).toFixed(2) + '×';
          if (r.id === 'compRatio') return parseFloat(val).toFixed(1) + ':1';
          if (r.id === 'genFreq') return val + ' Hz';
          if (r.step && parseFloat(r.step) >= 1) return Math.round(val).toString();
          return parseFloat(val).toFixed(parseFloat(r.step) < 0.01 ? 3 : 2);
        }
        if (v) { v.textContent = fmt(r.value); r.addEventListener('input', () => { v.textContent = fmt(r.value); updateCode(); drawVis(); }); }
        r.addEventListener('input', updateCode);
      });
      document.querySelectorAll('select,input[type=checkbox]').forEach(el => el.addEventListener('change', () => { updateCode(); drawVis(); }));

      // Build EQ bands
      const EQ_BANDS = [
        { freq:'60Hz', id:'eq0' }, { freq:'150Hz', id:'eq1' }, { freq:'400Hz', id:'eq2' },
        { freq:'1kHz', id:'eq3' }, { freq:'2.5kHz', id:'eq4' }, { freq:'6kHz', id:'eq5' }, { freq:'16kHz', id:'eq6' },
      ];
      const eqContainer = document.getElementById('eqBands');
      EQ_BANDS.forEach(band => {
        eqContainer.innerHTML += '<div class="eq-band"><input type="range" id="' + band.id + '" min="-12" max="12" step="0.5" value="0" orient="vertical"><label>' + band.freq + '</label><span class="val" id="' + band.id + 'Val">0</span></div>';
      });
      document.querySelectorAll('#eqBands input[type=range]').forEach(r => {
        const v = document.getElementById(r.id + 'Val');
        if (v) { r.addEventListener('input', () => { v.textContent = parseFloat(r.value).toFixed(1); updateCode(); drawVis(); }); }
      });

      // EQ presets
      const eqPresets = {
        flat:       [0,0,0,0,0,0,0],
        bass:       [8,6,3,0,-1,-1,-2],
        treble:     [-1,-1,0,1,3,5,7],
        vocal:      [-2,0,2,4,3,1,-1],
        underwater: [-8,-6,-4,-2,-6,-10,-12],
        telephone:  [-12,0,4,6,4,0,-12],
        radio:      [-10,-4,2,6,4,2,-8],
      };
      document.querySelectorAll('[data-eq]').forEach(btn => {
        btn.addEventListener('click', () => {
          const vals = eqPresets[btn.dataset.eq];
          EQ_BANDS.forEach((band, i) => {
            const el = document.getElementById(band.id);
            const v = document.getElementById(band.id + 'Val');
            if (el) { el.value = vals[i]; if(v) v.textContent = vals[i].toFixed(1); }
          });
          updateCode(); drawVis();
        });
      });

      // Reverb presets
      const reverbPresets = {
        small:  { room:0.2, damp:0.7, mix:0.2, predelay:5,  width:0.6, decay:0.5 },
        medium: { room:0.5, damp:0.5, mix:0.3, predelay:20, width:0.9, decay:2.0 },
        large:  { room:0.85,damp:0.3, mix:0.4, predelay:40, width:1.0, decay:5.0 },
        cave:   { room:0.9, damp:0.1, mix:0.5, predelay:50, width:0.8, decay:7.0 },
        plate:  { room:0.4, damp:0.8, mix:0.35,predelay:0,  width:1.0, decay:1.5 },
        spring: { room:0.3, damp:0.6, mix:0.4, predelay:10, width:0.5, decay:1.2 },
      };
      document.querySelectorAll('[data-reverb]').forEach(btn => {
        btn.addEventListener('click', () => {
          const p = reverbPresets[btn.dataset.reverb];
          Object.entries({ reverbRoom:p.room, reverbDamp:p.damp, reverbMix:p.mix, reverbPredelay:p.predelay, reverbWidth:p.width, reverbDecay:p.decay }).forEach(([id,val]) => {
            const el = document.getElementById(id);
            const v = document.getElementById(id+'Val');
            if (el) {
              el.value = val;
              if (v) v.textContent = parseFloat(el.step) >= 1 ? Math.round(val) : parseFloat(val).toFixed(2);
            }
          });
          updateCode(); drawVis();
        });
      });

      // Sound presets
      const soundPresets = {
        laser:     { type:'Square',  freq:880, vol:0.7, dur:0.15, atk:0.001,dec:0.05,sus:0.3,rel:0.1,  sweepFrom:6,  sweepTo:-12, sweepTime:0.15 },
        explosion: { type:'Noise',   freq:80,  vol:0.9, dur:1.2,  atk:0.001,dec:0.2, sus:0.2,rel:1.0,  sweepFrom:0,  sweepTo:-8,  sweepTime:0.8  },
        jump:      { type:'Sine',    freq:220, vol:0.6, dur:0.3,  atk:0.005,dec:0.1, sus:0.0,rel:0.15, sweepFrom:0,  sweepTo:7,   sweepTime:0.2  },
        coin:      { type:'Sine',    freq:660, vol:0.7, dur:0.2,  atk:0.001,dec:0.05,sus:0.5,rel:0.1,  sweepFrom:0,  sweepTo:5,   sweepTime:0.1  },
        powerup:   { type:'Sawtooth',freq:220, vol:0.6, dur:0.6,  atk:0.005,dec:0.1, sus:0.7,rel:0.2,  sweepFrom:-5, sweepTo:7,   sweepTime:0.5  },
        hurt:      { type:'Triangle',freq:120, vol:0.8, dur:0.25, atk:0.001,dec:0.05,sus:0.3,rel:0.2,  sweepFrom:2,  sweepTo:-6,  sweepTime:0.2  },
        blip:      { type:'Sine',    freq:440, vol:0.4, dur:0.07, atk:0.001,dec:0.01,sus:0.0,rel:0.05, sweepFrom:0,  sweepTo:0,   sweepTime:0.0  },
      };
      document.querySelectorAll('[data-sound]').forEach(btn => {
        btn.addEventListener('click', () => {
          const p = soundPresets[btn.dataset.sound];
          document.getElementById('genType').value = p.type;
          const fields = { genFreq:p.freq, genVol:p.vol, genDur:p.dur, adsrAttack:p.atk, adsrDecay:p.dec, adsrSustain:p.sus, adsrRelease:p.rel, pitchSweepFrom:p.sweepFrom, pitchSweepTo:p.sweepTo, pitchSweepTime:p.sweepTime };
          Object.entries(fields).forEach(([id,val]) => {
            const el = document.getElementById(id);
            const v = document.getElementById(id+'Val');
            if (el) { el.value = val; if(v) v.textContent = el.step && parseFloat(el.step) >= 1 ? Math.round(val) : parseFloat(val).toFixed(parseFloat(el.step||'0.01') < 0.01 ? 3 : 2); }
          });
          updateCode(); drawVis();
        });
      });

      function g(id) { return document.getElementById(id); }
      function fv(id) { return parseFloat(g(id).value); }
      function bv(id) { return g(id).checked; }
      function sv(id) { return g(id).value; }

      function updateCode() {
        let code = '';

        if (currentTab === 'chain') {
          code = '-- Sound DSP Chain\\n';
          code += 'local dsp = luna.sound.createDsp()\\n\\n';
          code += 'dsp:setMasterVolume(' + fv('masterVolume').toFixed(2) + ')\\n';
          code += 'dsp:setMasterPan(' + fv('masterPan').toFixed(2) + ')\\n';
          code += 'dsp:setSampleRate(' + sv('sampleRate') + ')\\n\\n';
          code += '-- Apply DSP to a source:\\n';
          code += 'local src = luna.sound.load("my_sound.wav")\\n';
          code += 'luna.sound.setDsp(src, dsp)\\n';
          code += 'luna.sound.play(src)';
        } else if (currentTab === 'eq') {
          code = '-- 7-Band Parametric EQ\\n';
          code += 'local eq = luna.sound.createEq({\\n';
          const freqs = ['60','150','400','1000','2500','6000','16000'];
          EQ_BANDS.forEach((band, i) => {
            const gain = fv(band.id);
            if (gain !== 0) code += '  { freq=' + freqs[i] + ', gain=' + gain.toFixed(1) + ' },\\n';
          });
          code += '})\\n';
          code += 'luna.sound.addEffect(src, eq)';
        } else if (currentTab === 'reverb') {
          code = '-- Reverb Effect\\n';
          code += 'local reverb = luna.sound.createReverb({\\n';
          code += '  room_size  = ' + fv('reverbRoom').toFixed(2) + ',\\n';
          code += '  damping    = ' + fv('reverbDamp').toFixed(2) + ',\\n';
          code += '  wet_dry    = ' + fv('reverbMix').toFixed(2) + ',\\n';
          code += '  pre_delay  = ' + fv('reverbPredelay') + ',  -- ms\\n';
          code += '  width      = ' + fv('reverbWidth').toFixed(2) + ',\\n';
          code += '  decay      = ' + fv('reverbDecay').toFixed(1) + ',\\n';
          code += '})\\n';
          code += 'luna.sound.addEffect(src, reverb)';
        } else if (currentTab === 'echo') {
          const delay = fv('echoDelay');
          const syncBpm = bv('echoSyncBpm');
          code = '-- Echo / Delay Effect\\n';
          code += 'local echo = luna.sound.createEcho({\\n';
          if (syncBpm) {
            code += '  bpm        = ' + fv('echoBpm') + ',\\n';
            code += '  division   = ' + fv('echoDiv') + ',\\n';
          } else {
            code += '  delay_ms   = ' + delay + ',\\n';
          }
          code += '  feedback   = ' + fv('echoFeedback').toFixed(2) + ',\\n';
          code += '  wet_dry    = ' + fv('echoMix').toFixed(2) + ',\\n';
          code += '  ping_pong  = ' + bv('echoPingPong') + ',\\n';
          code += '})\\n';
          code += 'luna.sound.addEffect(src, echo)';
        } else if (currentTab === 'chorus') {
          code = '-- ' + sv('chorusMode') + ' Effect\\n';
          code += 'local chorus = luna.sound.createChorus({\\n';
          code += '  mode     = "' + sv('chorusMode').toLowerCase() + '",\\n';
          code += '  depth    = ' + fv('chorusDepth').toFixed(2) + ',\\n';
          code += '  rate     = ' + fv('chorusRate').toFixed(2) + ',\\n';
          code += '  wet_dry  = ' + fv('chorusMix').toFixed(2) + ',\\n';
          code += '  voices   = ' + fv('chorusVoices') + ',\\n';
          code += '  spread   = ' + fv('chorusSpread').toFixed(2) + ',\\n';
          if (sv('chorusMode') === 'Flanger') code += '  feedback = ' + fv('flangerFeedback').toFixed(2) + ',\\n';
          code += '})\\n';
          code += 'luna.sound.addEffect(src, chorus)';
        } else if (currentTab === 'pitch') {
          const semi = fv('pitchSemitones'), cents = fv('pitchCents'), rate = fv('pitchRate');
          const sweepFrom = fv('pitchSweepFrom'), sweepTo = fv('pitchSweepTo'), sweepTime = fv('pitchSweepTime');
          code = '-- Pitch Shift\\n';
          code += 'local pitch = luna.sound.createPitchShift({\\n';
          if (semi !== 0) code += '  semitones = ' + semi + ',\\n';
          if (cents !== 0) code += '  cents     = ' + cents + ',\\n';
          if (rate !== 1) code += '  rate      = ' + rate.toFixed(2) + ',\\n';
          code += '  preserve_formants = ' + bv('pitchFormant') + ',\\n';
          if (sweepFrom !== 0 || sweepTo !== 0) {
            code += '  sweep = { from=' + sweepFrom + ', to=' + sweepTo + ', time=' + sweepTime.toFixed(2) + ' },\\n';
          }
          code += '})\\n';
          code += 'luna.sound.addEffect(src, pitch)';
        } else if (currentTab === 'dynamics') {
          code = '-- Dynamics Processing\\n';
          const drive = fv('distDrive');
          code += 'local chain = luna.sound.createDynamics({\\n';
          code += '  -- Compressor\\n';
          code += '  comp = {\\n';
          code += '    threshold = ' + fv('compThreshold') + ',  -- dB\\n';
          code += '    ratio     = ' + fv('compRatio').toFixed(1) + ',\\n';
          code += '    attack    = ' + fv('compAttack').toFixed(1) + ',  -- ms\\n';
          code += '    release   = ' + fv('compRelease') + ',         -- ms\\n';
          code += '    makeup    = ' + fv('compMakeup').toFixed(1) + ',  -- dB\\n';
          code += '  },\\n';
          code += '  -- Gate\\n';
          code += '  gate = { threshold=' + fv('gateThreshold') + ' },\\n';
          code += '  -- Limiter\\n';
          code += '  limiter = { ceiling=' + fv('limiterCeil').toFixed(1) + ' },\\n';
          if (drive > 0) {
            code += '  -- Distortion\\n';
            code += '  distortion = { drive=' + drive.toFixed(2) + ', mode="' + sv('distMode').toLowerCase().replace(/ /g,'_') + '", mix=' + fv('distMix').toFixed(2) + ' },\\n';
          }
          code += '})\\n';
          code += 'luna.sound.addEffect(src, chain)';
        } else if (currentTab === 'generator') {
          const type = sv('genType').toLowerCase();
          code = '-- Procedural Sound: ' + sv('genType') + '\\n';
          code += 'local synth = luna.sound.createSynth({\\n';
          code += '  wave      = "' + type + '",\\n';
          code += '  frequency = ' + fv('genFreq') + ',\\n';
          code += '  volume    = ' + fv('genVol').toFixed(2) + ',\\n';
          code += '  duration  = ' + fv('genDur').toFixed(2) + ',\\n';
          code += '  adsr      = { attack=' + fv('adsrAttack').toFixed(3) + ', decay=' + fv('adsrDecay').toFixed(3) + ', sustain=' + fv('adsrSustain').toFixed(2) + ', release=' + fv('adsrRelease').toFixed(3) + ' },\\n';
          const sf = fv('pitchSweepFrom'), st2 = fv('pitchSweepTo'), sTime = fv('pitchSweepTime');
          if (sf !== 0 || st2 !== 0) code += '  sweep     = { from=' + sf + ', to=' + st2 + ', time=' + sTime.toFixed(2) + ' },\\n';
          code += '})\\n\\n';
          code += '-- Play immediately:\\nluna.sound.play(luna.sound.fromSynth(synth))';
        }

        g('codeOut').textContent = code;
        updateChainVis();
      }

      function updateChainVis() {
        const chain = g('signalChain');
        const nodes = ['Input', 'EQ', 'Reverb', 'Echo', 'Chorus/Flanger', 'Pitch', 'Dynamics', 'Master Out'];
        chain.innerHTML = nodes.map(n => '<span class="chain-node">' + n + '</span>').join('<span class="chain-arrow">→</span>');
      }

      function drawVis() {
        const canvas = g('visCanvas');
        if (!canvas) return;
        const ctx = canvas.getContext('2d');
        const W = 560, H = 120;
        ctx.fillStyle = '#111'; ctx.fillRect(0,0,W,H);

        const mode = document.querySelector('input[name=visMode]:checked')?.value || 'freq';

        if (mode === 'freq') {
          // Draw frequency response curve based on EQ
          ctx.strokeStyle = '#4fc3f7'; ctx.lineWidth = 2;
          ctx.beginPath();
          const gains = EQ_BANDS.map((b,i) => { try { return fv(b.id); } catch { return 0; } });
          for (let x = 0; x < W; x++) {
            let gain = 0;
            gains.forEach((g2, i) => { const center = i/EQ_BANDS.length; gain += g2 * Math.exp(-Math.pow((x/W - center)*3, 2)); });
            const y = H/2 - (gain / 12) * (H*0.4);
            if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
          }
          ctx.stroke();
          // Zero line
          ctx.strokeStyle = '#333'; ctx.lineWidth = 1;
          ctx.beginPath(); ctx.moveTo(0,H/2); ctx.lineTo(W,H/2); ctx.stroke();
          // Labels
          ['20Hz','100Hz','1kHz','10kHz','20kHz'].forEach((lbl, i) => {
            const x = [0,0.12,0.52,0.85,1][i]*W;
            ctx.fillStyle = '#555'; ctx.font = '9px sans-serif'; ctx.fillText(lbl, x+2, H-3);
          });
        } else if (mode === 'wave') {
          ctx.strokeStyle = '#4fc3f7'; ctx.lineWidth = 1.5;
          ctx.beginPath();
          for (let x = 0; x < W; x++) {
            const t = x/W * 4 * Math.PI;
            const y = H/2 + Math.sin(t + Math.random()*0.05) * H*0.35;
            if (x === 0) ctx.moveTo(x,y); else ctx.lineTo(x,y);
          }
          ctx.stroke();
        } else {
          // Lissajous
          ctx.strokeStyle = '#4fc3f7'; ctx.lineWidth = 1; ctx.globalAlpha = 0.5;
          ctx.beginPath();
          for (let i = 0; i < 500; i++) {
            const t = (i/500)*Math.PI*20;
            const x = W/2 + Math.sin(t*1.5)*W*0.4;
            const y = H/2 + Math.cos(t)*H*0.4;
            if (i===0) ctx.moveTo(x,y); else ctx.lineTo(x,y);
          }
          ctx.stroke(); ctx.globalAlpha = 1;
        }
      }

      document.querySelectorAll('input[name=visMode]').forEach(r => r.addEventListener('change', drawVis));

      document.getElementById('btnCopy').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyCode', code: g('codeOut').textContent });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertCode', code: g('codeOut').textContent });
      });

      updateCode(); drawVis();
    `);
  }
}
