import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

export class InputMapperEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): InputMapperEditor {
    return new InputMapperEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.inputMapperEditor", "Input Mapper");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "input_map.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Input Mapper", `
      .editor-layout {
        display: grid; grid-template-columns: 1fr 210px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .mapping-area { grid-row: 2; overflow-y: auto; padding: 8px; background: var(--bg); }
      .config-panel { grid-row: 2; overflow-y: auto; border-left: 1px solid var(--border); background: var(--surface); padding: 6px; }
      .action-table { width: 100%; border-collapse: collapse; font-size: 11px; }
      .action-table th {
        text-align: left; padding: 4px 6px; background: var(--surface);
        border-bottom: 2px solid var(--border); font-size: 9px; text-transform: uppercase;
        color: var(--text-dim); position: sticky; top: 0; letter-spacing: 0.3px;
      }
      .action-table td { padding: 3px 6px; border-bottom: 1px solid var(--border); vertical-align: middle; }
      .action-table tr:hover { background: var(--hover); }
      .action-table tr.sel { background: var(--selection); }
      .binding-cell { display: flex; flex-wrap: wrap; gap: 2px; }
      .key-badge {
        background: var(--surface-2); border: 1px solid var(--border); padding: 1px 6px;
        border-radius: var(--radius); font-family: var(--font-mono, monospace); font-size: 10px;
        cursor: pointer; display: inline-flex; align-items: center; gap: 3px; transition: border-color 0.1s;
      }
      .key-badge:hover { border-color: var(--accent); }
      .key-badge .rm { font-size: 8px; opacity: 0.4; cursor: pointer; }
      .key-badge .rm:hover { opacity: 1; color: var(--error); }
      .key-badge.conflict { border-color: var(--error); background: rgba(244,67,54,0.12); }
      .add-bind {
        background: transparent; border: 1px dashed var(--border); padding: 1px 6px;
        border-radius: var(--radius); font-size: 10px; cursor: pointer; color: var(--text-dim);
      }
      .add-bind:hover { border-color: var(--accent); color: var(--accent); }
      .listen-overlay {
        position: fixed; inset: 0; background: rgba(0,0,0,0.7); display: flex;
        align-items: center; justify-content: center; z-index: 100;
      }
      .listen-box {
        background: var(--surface); padding: 20px 36px; border-radius: var(--radius);
        border: 2px solid var(--accent); text-align: center;
      }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${iconButton(ICONS.add, 'btnAdd', 'Add Action')}
            ${iconButton(ICONS.delete, 'btnRem', 'Remove Action')}
          </div>
          ${toolbarSep()}
          <div class="group">
            <button id="btnConflicts" style="font-size:10px;padding:2px 8px">Check Conflicts</button>
          </div>
          ${toolbarSpacer()}
          ${iconButton(ICONS.save, 'btnExport', 'Export Lua')}
        </div>

        <div class="mapping-area">
          <table class="action-table">
            <thead><tr>
              <th style="width:120px">Action</th>
              <th style="width:160px">Description</th>
              <th>Keyboard</th>
              <th>Gamepad</th>
            </tr></thead>
            <tbody id="actBody"></tbody>
          </table>
        </div>

        <div class="config-panel">
          ${panelSection('Selected Action', `
            ${fieldInline('Name', '<input type="text" id="actName" style="width:100%">')}
            ${fieldInline('Desc', '<input type="text" id="actDesc" style="width:100%">')}
          `)}
          ${panelSection('Analog', `
            ${fieldInline('Dead Zone', '<input type="range" id="deadzone" min="0" max="50" value="15" style="flex:1"><span id="dzVal" style="font-size:9px;min-width:28px">0.15</span>')}
            ${fieldInline('Sensitivity', '<input type="range" id="sens" min="1" max="30" value="10" style="flex:1"><span id="sensVal" style="font-size:9px;min-width:28px">1.0</span>')}
          `)}
          ${panelSection('Presets', `
            <button id="prePlatformer" style="width:100%;margin-bottom:3px;font-size:10px">Platformer</button>
            <button id="preRPG" style="width:100%;margin-bottom:3px;font-size:10px">RPG</button>
            <button id="preShooter" style="width:100%;font-size:10px">Top-Down Shooter</button>
          `)}
        </div>

        <div class="status-bar">
          <span id="stAct" class="badge">5 actions</span>
          <div class="sep"></div>
          <span id="stConf">0 conflicts</span>
          <div class="spacer"></div>
          <span id="stDirty" style="font-size:10px;color:var(--text-dim)">${ICONS.clean}</span>
        </div>
      </div>
      <div class="listen-overlay" id="listenOverlay" style="display:none;">
        <div class="listen-box">
          <p style="font-size:14px;margin-bottom:6px">Press a key…</p>
          <p style="font-size:10px;color:var(--text-dim)">Escape to cancel</p>
        </div>
      </div>
    `, `
      const undo = new UndoStack();
      let actions = [
        { name:'move_left', desc:'Move left', keys:['a','left'], gamepad:['dpad_left','lstick_left'], dz:0.15, sens:1.0 },
        { name:'move_right', desc:'Move right', keys:['d','right'], gamepad:['dpad_right','lstick_right'], dz:0.15, sens:1.0 },
        { name:'jump', desc:'Jump', keys:['space','w'], gamepad:['a'], dz:0.15, sens:1.0 },
        { name:'attack', desc:'Primary attack', keys:['j','enter'], gamepad:['x'], dz:0.15, sens:1.0 },
        { name:'interact', desc:'Interact / Talk', keys:['e'], gamepad:['b'], dz:0.15, sens:1.0 },
      ];
      let selAct = 0, listenTarget = null;

      function snap() { return JSON.parse(JSON.stringify(actions)); }
      function load(s) { actions = s; build(); updateProps(); }
      function push() { undo.push(snap()); markDirty(); }
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) load(s); });
      registerShortcut('ctrl+shift+z', () => { const s = undo.redo(); if (s) load(s); });
      registerShortcut('ctrl+s', () => document.getElementById('btnExport').click());

      function findConflicts() {
        const c = [];
        for (let i = 0; i < actions.length; i++)
          for (let j = i+1; j < actions.length; j++) {
            for (const k of actions[i].keys) if (actions[j].keys.includes(k)) c.push({a:i,b:j,key:k,type:'keys'});
            for (const g of actions[i].gamepad) if (actions[j].gamepad.includes(g)) c.push({a:i,b:j,key:g,type:'gamepad'});
          }
        return c;
      }

      function build() {
        const body = document.getElementById('actBody'); body.innerHTML = '';
        const conflicts = findConflicts();
        actions.forEach((act, i) => {
          const tr = document.createElement('tr');
          tr.className = i === selAct ? 'sel' : '';
          tr.addEventListener('click', () => { selAct = i; build(); updateProps(); });

          const tdN = document.createElement('td');
          tdN.textContent = act.name; tdN.style.fontFamily = 'var(--font-mono, monospace)';
          const tdD = document.createElement('td');
          tdD.textContent = act.desc; tdD.style.color = 'var(--text-dim)';

          function bindCell(arr, type) {
            const td = document.createElement('td');
            const d = document.createElement('div'); d.className = 'binding-cell';
            arr.forEach((k, ki) => {
              const b = document.createElement('span');
              b.className = 'key-badge' + (conflicts.some(c => c.key===k && c.type===type && (c.a===i||c.b===i)) ? ' conflict' : '');
              b.innerHTML = k + ' <span class="rm">\\u00d7</span>';
              b.querySelector('.rm').addEventListener('click', e => { e.stopPropagation(); push(); arr.splice(ki,1); build(); });
              d.appendChild(b);
            });
            const ab = document.createElement('button'); ab.className = 'add-bind'; ab.textContent = '+';
            ab.addEventListener('click', e => { e.stopPropagation(); listenTarget = {action:i, type}; document.getElementById('listenOverlay').style.display = 'flex'; });
            d.appendChild(ab);
            td.appendChild(d); return td;
          }

          tr.appendChild(tdN); tr.appendChild(tdD);
          tr.appendChild(bindCell(act.keys, 'keys'));
          tr.appendChild(bindCell(act.gamepad, 'gamepad'));
          body.appendChild(tr);
        });
        document.getElementById('stAct').textContent = actions.length + ' actions';
        document.getElementById('stConf').textContent = conflicts.length + ' conflicts';
        if (conflicts.length > 0) document.getElementById('stConf').style.color = 'var(--error)';
        else document.getElementById('stConf').style.color = '';
      }

      function updateProps() {
        const a = actions[selAct]; if (!a) return;
        document.getElementById('actName').value = a.name;
        document.getElementById('actDesc').value = a.desc;
        document.getElementById('deadzone').value = Math.round(a.dz*100);
        document.getElementById('dzVal').textContent = a.dz.toFixed(2);
        document.getElementById('sens').value = Math.round(a.sens*10);
        document.getElementById('sensVal').textContent = a.sens.toFixed(1);
      }

      document.addEventListener('keydown', e => {
        if (!listenTarget) return;
        e.preventDefault();
        if (e.key === 'Escape') { listenTarget = null; document.getElementById('listenOverlay').style.display = 'none'; return; }
        push();
        const key = e.key.toLowerCase(), a = actions[listenTarget.action];
        if (listenTarget.type === 'keys' && !a.keys.includes(key)) a.keys.push(key);
        listenTarget = null; document.getElementById('listenOverlay').style.display = 'none';
        build();
      });

      document.getElementById('actName').addEventListener('change', e => { if (actions[selAct]) { push(); actions[selAct].name = e.target.value; build(); } });
      document.getElementById('actDesc').addEventListener('change', e => { if (actions[selAct]) { push(); actions[selAct].desc = e.target.value; } });
      document.getElementById('deadzone').addEventListener('input', e => {
        const v = +e.target.value/100; document.getElementById('dzVal').textContent = v.toFixed(2);
        if (actions[selAct]) actions[selAct].dz = v;
      });
      document.getElementById('sens').addEventListener('input', e => {
        const v = +e.target.value/10; document.getElementById('sensVal').textContent = v.toFixed(1);
        if (actions[selAct]) actions[selAct].sens = v;
      });

      document.getElementById('btnAdd').addEventListener('click', () => {
        push(); actions.push({name:'new_action',desc:'',keys:[],gamepad:[],dz:0.15,sens:1.0});
        selAct = actions.length-1; build(); updateProps();
      });
      document.getElementById('btnRem').addEventListener('click', () => {
        if (actions.length > 0) { push(); actions.splice(selAct,1); selAct = Math.min(selAct, actions.length-1); build(); updateProps(); }
      });
      document.getElementById('btnConflicts').addEventListener('click', build);

      function loadPreset(p) {
        const presets = {
          Platformer: [
            {name:'move_left',desc:'Move left',keys:['a','left'],gamepad:['dpad_left','lstick_left'],dz:0.15,sens:1},
            {name:'move_right',desc:'Move right',keys:['d','right'],gamepad:['dpad_right','lstick_right'],dz:0.15,sens:1},
            {name:'jump',desc:'Jump',keys:['space','w','up'],gamepad:['a'],dz:0.15,sens:1},
            {name:'attack',desc:'Attack',keys:['j'],gamepad:['x'],dz:0.15,sens:1},
            {name:'dash',desc:'Dash',keys:['shift'],gamepad:['lb'],dz:0.15,sens:1},
          ],
          RPG: [
            {name:'move_up',desc:'Move up',keys:['w','up'],gamepad:['dpad_up','lstick_up'],dz:0.2,sens:1},
            {name:'move_down',desc:'Move down',keys:['s','down'],gamepad:['dpad_down','lstick_down'],dz:0.2,sens:1},
            {name:'move_left',desc:'Move left',keys:['a','left'],gamepad:['dpad_left','lstick_left'],dz:0.2,sens:1},
            {name:'move_right',desc:'Move right',keys:['d','right'],gamepad:['dpad_right','lstick_right'],dz:0.2,sens:1},
            {name:'interact',desc:'Talk / Interact',keys:['e','enter'],gamepad:['a'],dz:0.15,sens:1},
            {name:'menu',desc:'Open menu',keys:['escape','tab'],gamepad:['start'],dz:0.15,sens:1},
          ],
          Shooter: [
            {name:'move_up',desc:'Move up',keys:['w'],gamepad:['lstick_up'],dz:0.1,sens:1.5},
            {name:'move_down',desc:'Move down',keys:['s'],gamepad:['lstick_down'],dz:0.1,sens:1.5},
            {name:'move_left',desc:'Move left',keys:['a'],gamepad:['lstick_left'],dz:0.1,sens:1.5},
            {name:'move_right',desc:'Move right',keys:['d'],gamepad:['lstick_right'],dz:0.1,sens:1.5},
            {name:'shoot',desc:'Fire weapon',keys:['space'],gamepad:['rt'],dz:0.05,sens:1},
            {name:'reload',desc:'Reload',keys:['r'],gamepad:['x'],dz:0.15,sens:1},
          ],
        };
        push(); actions = presets[p] || actions; selAct = 0; build(); updateProps();
      }
      document.getElementById('prePlatformer').addEventListener('click', () => loadPreset('Platformer'));
      document.getElementById('preRPG').addEventListener('click', () => loadPreset('RPG'));
      document.getElementById('preShooter').addEventListener('click', () => loadPreset('Shooter'));

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        actions.forEach(a => {
          lua += '  '+a.name+' = {\\n    description = "'+a.desc+'",\\n';
          lua += '    keys = {'+a.keys.map(k=>'"'+k+'"').join(', ')+'},\\n';
          lua += '    gamepad = {'+a.gamepad.map(g=>'"'+g+'"').join(', ')+'},\\n';
          lua += '    deadzone = '+a.dz+', sensitivity = '+a.sens+',\\n  },\\n';
        });
        lua += '}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      build(); updateProps();
      vscode.postMessage({ type: 'stateChanged', state: { ready: true } });
    `);
  }
}
