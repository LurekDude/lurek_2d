import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class InputMapperEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): InputMapperEditor {
    return new InputMapperEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "luna.inputMapperEditor", "Input Mapper");
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
        display: grid; grid-template-columns: 1fr 260px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .mapping-area { grid-row: 2; overflow-y: auto; padding: 10px; }
      .config-panel { grid-row: 2; }
      .status-bar { grid-column: 1 / -1; }
      .action-table { width: 100%; border-collapse: collapse; font-size: 12px; }
      .action-table th {
        text-align: left; padding: 6px 8px; background: var(--surface);
        border-bottom: 2px solid var(--border); font-size: 11px; text-transform: uppercase;
        color: var(--text-dim); position: sticky; top: 0;
      }
      .action-table td {
        padding: 4px 8px; border-bottom: 1px solid var(--border); vertical-align: middle;
      }
      .action-table tr:hover { background: var(--surface-2); }
      .binding-cell { display: flex; flex-wrap: wrap; gap: 3px; }
      .key-badge {
        background: var(--surface-2); border: 1px solid var(--border); padding: 2px 8px;
        border-radius: 3px; font-family: monospace; font-size: 11px; cursor: pointer;
        display: inline-flex; align-items: center; gap: 4px;
      }
      .key-badge:hover { border-color: var(--accent); }
      .key-badge .remove { font-size: 9px; opacity: 0.5; cursor: pointer; }
      .key-badge .remove:hover { opacity: 1; color: var(--danger); }
      .key-badge.conflict { border-color: var(--danger); background: rgba(244,67,54,0.15); }
      .add-binding {
        background: transparent; border: 1px dashed var(--border); padding: 2px 8px;
        border-radius: 3px; font-size: 11px; cursor: pointer; color: var(--text-dim);
      }
      .add-binding:hover { border-color: var(--accent); color: var(--accent); }
      .listen-overlay {
        position: fixed; inset: 0; background: rgba(0,0,0,0.7); display: flex;
        align-items: center; justify-content: center; z-index: 100;
      }
      .listen-box {
        background: var(--surface); padding: 24px 40px; border-radius: 8px;
        border: 2px solid var(--accent); text-align: center;
      }
      .deadzone-slider { width: 100%; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAddAction">+ Add Action</button>
          <button id="btnRemoveAction" class="danger">Remove Action</button>
          <div class="sep"></div>
          <button id="btnCheckConflicts">Check Conflicts</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>

        <div class="mapping-area">
          <table class="action-table">
            <thead>
              <tr>
                <th style="width:140px;">Action</th>
                <th style="width:180px;">Description</th>
                <th>Keyboard</th>
                <th>Gamepad</th>
              </tr>
            </thead>
            <tbody id="actionBody"></tbody>
          </table>
        </div>

        <div class="panel config-panel">
          <div class="section">
            <h3>Selected Action</h3>
            <div class="field"><label>Name</label><input type="text" id="actionName" style="width:100%"></div>
            <div class="field"><label>Description</label><input type="text" id="actionDesc" style="width:100%"></div>
          </div>
          <div class="section">
            <h3>Analog Settings</h3>
            <div class="field">
              <label>Dead Zone: <span id="dzVal">0.15</span></label>
              <input type="range" class="deadzone-slider" id="deadzone" min="0" max="50" value="15">
            </div>
            <div class="field">
              <label>Sensitivity: <span id="sensVal">1.0</span></label>
              <input type="range" class="deadzone-slider" id="sensitivity" min="1" max="30" value="10">
            </div>
          </div>
          <div class="section">
            <h3>Presets</h3>
            <button id="btnPresetPlatformer" style="width:100%;margin-bottom:4px;">Platformer</button>
            <button id="btnPresetRPG" style="width:100%;margin-bottom:4px;">RPG</button>
            <button id="btnPresetShooter" style="width:100%;">Top-Down Shooter</button>
          </div>
        </div>

        <div class="status-bar">
          <span id="statusActions">Actions: 0</span>
          <span id="statusConflicts">Conflicts: 0</span>
        </div>
      </div>
      <div class="listen-overlay" id="listenOverlay" style="display:none;">
        <div class="listen-box">
          <p style="font-size:16px;margin-bottom:8px;">Press a key...</p>
          <p style="font-size:11px;color:var(--text-dim);">Press Escape to cancel</p>
        </div>
      </div>
    `, `
      let actions = [
        { name: 'move_left', desc: 'Move left', keys: ['a','left'], gamepad: ['dpad_left','lstick_left'], deadzone: 0.15, sensitivity: 1.0 },
        { name: 'move_right', desc: 'Move right', keys: ['d','right'], gamepad: ['dpad_right','lstick_right'], deadzone: 0.15, sensitivity: 1.0 },
        { name: 'jump', desc: 'Jump', keys: ['space','w'], gamepad: ['a'], deadzone: 0.15, sensitivity: 1.0 },
        { name: 'attack', desc: 'Primary attack', keys: ['j','enter'], gamepad: ['x'], deadzone: 0.15, sensitivity: 1.0 },
        { name: 'interact', desc: 'Interact / Talk', keys: ['e'], gamepad: ['b'], deadzone: 0.15, sensitivity: 1.0 },
      ];
      let selectedAction = 0;
      let listenTarget = null; // {action, type:'keys'|'gamepad'}

      function render() {
        const body = document.getElementById('actionBody');
        body.innerHTML = '';
        const conflicts = findConflicts();
        actions.forEach((act, i) => {
          const tr = document.createElement('tr');
          tr.style.background = i === selectedAction ? 'var(--selection)' : '';
          tr.addEventListener('click', () => { selectedAction = i; render(); updateProps(); });

          const tdName = document.createElement('td');
          tdName.textContent = act.name;
          tdName.style.fontFamily = 'monospace';

          const tdDesc = document.createElement('td');
          tdDesc.textContent = act.desc;
          tdDesc.style.color = 'var(--text-dim)';

          const tdKeys = document.createElement('td');
          const keysDiv = document.createElement('div');
          keysDiv.className = 'binding-cell';
          act.keys.forEach((k, ki) => {
            const badge = document.createElement('span');
            const isConflict = conflicts.some(c => c.key === k && c.type === 'keys' && (c.a === i || c.b === i));
            badge.className = 'key-badge' + (isConflict ? ' conflict' : '');
            badge.innerHTML = k + ' <span class="remove">x</span>';
            badge.querySelector('.remove').addEventListener('click', (e) => {
              e.stopPropagation(); act.keys.splice(ki, 1); render();
            });
            keysDiv.appendChild(badge);
          });
          const addKeyBtn = document.createElement('button');
          addKeyBtn.className = 'add-binding';
          addKeyBtn.textContent = '+';
          addKeyBtn.addEventListener('click', (e) => { e.stopPropagation(); startListen(i, 'keys'); });
          keysDiv.appendChild(addKeyBtn);
          tdKeys.appendChild(keysDiv);

          const tdPad = document.createElement('td');
          const padDiv = document.createElement('div');
          padDiv.className = 'binding-cell';
          act.gamepad.forEach((g, gi) => {
            const badge = document.createElement('span');
            const isConflict = conflicts.some(c => c.key === g && c.type === 'gamepad' && (c.a === i || c.b === i));
            badge.className = 'key-badge' + (isConflict ? ' conflict' : '');
            badge.innerHTML = g + ' <span class="remove">x</span>';
            badge.querySelector('.remove').addEventListener('click', (e) => {
              e.stopPropagation(); act.gamepad.splice(gi, 1); render();
            });
            padDiv.appendChild(badge);
          });
          const addPadBtn = document.createElement('button');
          addPadBtn.className = 'add-binding';
          addPadBtn.textContent = '+';
          addPadBtn.addEventListener('click', (e) => { e.stopPropagation(); startListen(i, 'gamepad'); });
          padDiv.appendChild(addPadBtn);
          tdPad.appendChild(padDiv);

          tr.appendChild(tdName); tr.appendChild(tdDesc); tr.appendChild(tdKeys); tr.appendChild(tdPad);
          body.appendChild(tr);
        });
        document.getElementById('statusActions').textContent = 'Actions: ' + actions.length;
        document.getElementById('statusConflicts').textContent = 'Conflicts: ' + conflicts.length;
      }

      function updateProps() {
        const act = actions[selectedAction];
        if (!act) return;
        document.getElementById('actionName').value = act.name;
        document.getElementById('actionDesc').value = act.desc;
        document.getElementById('deadzone').value = Math.round(act.deadzone * 100);
        document.getElementById('dzVal').textContent = act.deadzone.toFixed(2);
        document.getElementById('sensitivity').value = Math.round(act.sensitivity * 10);
        document.getElementById('sensVal').textContent = act.sensitivity.toFixed(1);
      }

      function findConflicts() {
        const conflicts = [];
        for (let i = 0; i < actions.length; i++) {
          for (let j = i + 1; j < actions.length; j++) {
            for (const k of actions[i].keys) {
              if (actions[j].keys.includes(k)) conflicts.push({ a: i, b: j, key: k, type: 'keys' });
            }
            for (const g of actions[i].gamepad) {
              if (actions[j].gamepad.includes(g)) conflicts.push({ a: i, b: j, key: g, type: 'gamepad' });
            }
          }
        }
        return conflicts;
      }

      function startListen(actionIdx, type) {
        listenTarget = { action: actionIdx, type };
        document.getElementById('listenOverlay').style.display = 'flex';
      }

      document.addEventListener('keydown', (e) => {
        if (!listenTarget) return;
        e.preventDefault();
        if (e.key === 'Escape') {
          listenTarget = null;
          document.getElementById('listenOverlay').style.display = 'none';
          return;
        }
        const keyName = e.key.toLowerCase();
        const act = actions[listenTarget.action];
        if (listenTarget.type === 'keys' && !act.keys.includes(keyName)) {
          act.keys.push(keyName);
        }
        listenTarget = null;
        document.getElementById('listenOverlay').style.display = 'none';
        render();
      });

      document.getElementById('actionName').addEventListener('change', (e) => {
        if (actions[selectedAction]) { actions[selectedAction].name = e.target.value; render(); }
      });
      document.getElementById('actionDesc').addEventListener('change', (e) => {
        if (actions[selectedAction]) { actions[selectedAction].desc = e.target.value; }
      });
      document.getElementById('deadzone').addEventListener('input', (e) => {
        const v = parseInt(e.target.value) / 100;
        document.getElementById('dzVal').textContent = v.toFixed(2);
        if (actions[selectedAction]) actions[selectedAction].deadzone = v;
      });
      document.getElementById('sensitivity').addEventListener('input', (e) => {
        const v = parseInt(e.target.value) / 10;
        document.getElementById('sensVal').textContent = v.toFixed(1);
        if (actions[selectedAction]) actions[selectedAction].sensitivity = v;
      });

      document.getElementById('btnAddAction').addEventListener('click', () => {
        actions.push({ name: 'new_action', desc: '', keys: [], gamepad: [], deadzone: 0.15, sensitivity: 1.0 });
        selectedAction = actions.length - 1;
        render(); updateProps();
      });
      document.getElementById('btnRemoveAction').addEventListener('click', () => {
        if (actions.length > 0) {
          actions.splice(selectedAction, 1);
          selectedAction = Math.min(selectedAction, actions.length - 1);
          render(); updateProps();
        }
      });

      document.getElementById('btnCheckConflicts').addEventListener('click', render);

      function loadPreset(preset) {
        const presets = {
          Platformer: [
            { name:'move_left', desc:'Move left', keys:['a','left'], gamepad:['dpad_left','lstick_left'], deadzone:0.15, sensitivity:1 },
            { name:'move_right', desc:'Move right', keys:['d','right'], gamepad:['dpad_right','lstick_right'], deadzone:0.15, sensitivity:1 },
            { name:'jump', desc:'Jump', keys:['space','w','up'], gamepad:['a'], deadzone:0.15, sensitivity:1 },
            { name:'attack', desc:'Attack', keys:['j'], gamepad:['x'], deadzone:0.15, sensitivity:1 },
            { name:'dash', desc:'Dash', keys:['shift'], gamepad:['lb'], deadzone:0.15, sensitivity:1 },
          ],
          RPG: [
            { name:'move_up', desc:'Move up', keys:['w','up'], gamepad:['dpad_up','lstick_up'], deadzone:0.2, sensitivity:1 },
            { name:'move_down', desc:'Move down', keys:['s','down'], gamepad:['dpad_down','lstick_down'], deadzone:0.2, sensitivity:1 },
            { name:'move_left', desc:'Move left', keys:['a','left'], gamepad:['dpad_left','lstick_left'], deadzone:0.2, sensitivity:1 },
            { name:'move_right', desc:'Move right', keys:['d','right'], gamepad:['dpad_right','lstick_right'], deadzone:0.2, sensitivity:1 },
            { name:'interact', desc:'Talk / Interact', keys:['e','enter'], gamepad:['a'], deadzone:0.15, sensitivity:1 },
            { name:'menu', desc:'Open menu', keys:['escape','tab'], gamepad:['start'], deadzone:0.15, sensitivity:1 },
          ],
          Shooter: [
            { name:'move_up', desc:'Move up', keys:['w'], gamepad:['lstick_up'], deadzone:0.1, sensitivity:1.5 },
            { name:'move_down', desc:'Move down', keys:['s'], gamepad:['lstick_down'], deadzone:0.1, sensitivity:1.5 },
            { name:'move_left', desc:'Move left', keys:['a'], gamepad:['lstick_left'], deadzone:0.1, sensitivity:1.5 },
            { name:'move_right', desc:'Move right', keys:['d'], gamepad:['lstick_right'], deadzone:0.1, sensitivity:1.5 },
            { name:'shoot', desc:'Fire weapon', keys:['space'], gamepad:['rt'], deadzone:0.05, sensitivity:1 },
            { name:'reload', desc:'Reload', keys:['r'], gamepad:['x'], deadzone:0.15, sensitivity:1 },
          ],
        };
        actions = presets[preset] || actions;
        selectedAction = 0;
        render(); updateProps();
      }

      document.getElementById('btnPresetPlatformer').addEventListener('click', () => loadPreset('Platformer'));
      document.getElementById('btnPresetRPG').addEventListener('click', () => loadPreset('RPG'));
      document.getElementById('btnPresetShooter').addEventListener('click', () => loadPreset('Shooter'));

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        actions.forEach(a => {
          lua += '  ' + a.name + ' = {\\n';
          lua += '    description = "' + a.desc + '",\\n';
          lua += '    keys = {' + a.keys.map(k => '"' + k + '"').join(', ') + '},\\n';
          lua += '    gamepad = {' + a.gamepad.map(g => '"' + g + '"').join(', ') + '},\\n';
          lua += '    deadzone = ' + a.deadzone + ', sensitivity = ' + a.sensitivity + ',\\n';
          lua += '  },\\n';
        });
        lua += '}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      render();
      updateProps();
    `);
  }
}
