import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class EntityEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): EntityEditor {
    return new EntityEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.editor.entity", "Entity Designer");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "entities.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Entity Designer", `
      .editor-layout {
        display: grid; grid-template-columns: 200px 1fr 220px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .entity-list { grid-row: 2; }
      .component-editor { grid-row: 2; padding: 12px; overflow-y: auto; }
      .preview-panel { grid-row: 2; border-left: 1px solid var(--border); padding: 8px; overflow-y: auto; background: var(--surface); }
      .status-bar { grid-column: 1 / -1; }
      .comp-card {
        background: var(--surface-2); border: 1px solid var(--border); border-radius: 4px;
        padding: 8px; margin-bottom: 8px;
      }
      .comp-card h4 { font-size: 12px; margin-bottom: 6px; display: flex; justify-content: space-between; align-items: center; }
      .comp-card h4 button { font-size: 10px; padding: 1px 6px; }
      .template-btn { margin: 2px; font-size: 11px; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnNewEntity">+ New Entity</button>
          <button id="btnDuplicate">Duplicate</button>
          <button id="btnDeleteEntity" class="danger">Delete</button>
          <div class="sep"></div>
          <label>Templates:</label>
          <button class="template-btn" data-tpl="player">Player</button>
          <button class="template-btn" data-tpl="enemy">Enemy</button>
          <button class="template-btn" data-tpl="pickup">Pickup</button>
          <button class="template-btn" data-tpl="projectile">Projectile</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="panel entity-list">
          <h3>Entities</h3>
          <div id="entityList"></div>
        </div>
        <div class="component-editor" id="compEditor">
          <p style="color: var(--text-dim);">Select or create an entity to begin editing.</p>
        </div>
        <div class="preview-panel">
          <h3>Preview</h3>
          <div id="previewArea" style="margin-top: 8px; text-align: center;">
            <canvas id="previewCanvas" width="180" height="180" style="border: 1px solid var(--border); border-radius: 4px;"></canvas>
          </div>
          <h3 style="margin-top: 12px;">Stats</h3>
          <div id="statsArea" style="font-size: 11px; color: var(--text-dim); margin-top: 4px;"></div>
        </div>
        <div class="status-bar"><span id="statusInfo">Entities: 0 | Components: 0</span></div>
      </div>
    `, `
      const COMPONENT_DEFS = {
        Transform: { x: 0, y: 0, rotation: 0, scaleX: 1, scaleY: 1 },
        Sprite: { image: '', width: 32, height: 32, color: '#ffffff' },
        Physics: { bodyType: 'dynamic', mass: 1, friction: 0.3, restitution: 0.2 },
        Collider: { shape: 'rectangle', width: 32, height: 32, isSensor: false },
        AI: { behavior: 'idle', speed: 100, detectionRange: 200 },
        Health: { maxHp: 100, currentHp: 100, invincible: false },
        Custom: { key: '', value: '' }
      };

      const TEMPLATES = {
        player: { name: 'Player', components: { Transform: {...COMPONENT_DEFS.Transform}, Sprite: {...COMPONENT_DEFS.Sprite, width: 32, height: 48, color: '#4ec9b0'}, Physics: {...COMPONENT_DEFS.Physics}, Collider: {...COMPONENT_DEFS.Collider, height: 48}, Health: {...COMPONENT_DEFS.Health} }},
        enemy: { name: 'Enemy', components: { Transform: {...COMPONENT_DEFS.Transform}, Sprite: {...COMPONENT_DEFS.Sprite, color: '#f44336'}, Physics: {...COMPONENT_DEFS.Physics}, Collider: {...COMPONENT_DEFS.Collider}, AI: {...COMPONENT_DEFS.AI, behavior: 'chase'}, Health: {...COMPONENT_DEFS.Health, maxHp: 50, currentHp: 50} }},
        pickup: { name: 'Pickup', components: { Transform: {...COMPONENT_DEFS.Transform}, Sprite: {...COMPONENT_DEFS.Sprite, width: 16, height: 16, color: '#ffeb3b'}, Collider: {...COMPONENT_DEFS.Collider, width: 16, height: 16, isSensor: true} }},
        projectile: { name: 'Projectile', components: { Transform: {...COMPONENT_DEFS.Transform}, Sprite: {...COMPONENT_DEFS.Sprite, width: 8, height: 8, color: '#ff9800'}, Physics: {...COMPONENT_DEFS.Physics, mass: 0.1}, Collider: {...COMPONENT_DEFS.Collider, width: 8, height: 8} }}
      };

      let entities = [], selectedIdx = -1;

      function createEntity(name, comps) {
        entities.push({ name: name || 'Entity' + entities.length, components: comps || { Transform: {...COMPONENT_DEFS.Transform} } });
        selectedIdx = entities.length - 1;
        refreshAll();
      }

      function refreshList() {
        const el = document.getElementById('entityList');
        el.innerHTML = '';
        entities.forEach((ent, i) => {
          const div = document.createElement('div');
          div.className = 'list-item' + (i === selectedIdx ? ' selected' : '');
          div.textContent = ent.name;
          div.addEventListener('click', () => { selectedIdx = i; refreshAll(); });
          el.appendChild(div);
        });
      }

      function refreshEditor() {
        const el = document.getElementById('compEditor');
        if (selectedIdx < 0 || selectedIdx >= entities.length) {
          el.innerHTML = '<p style="color:var(--text-dim);">Select or create an entity.</p>';
          return;
        }
        const ent = entities[selectedIdx];
        let html = '<div class="field"><label>Entity Name</label><input id="entName" value="' + ent.name + '"></div>';
        html += '<div style="margin: 8px 0;"><label>Add Component: </label><select id="addComp"><option value="">Choose...</option>';
        for (const k in COMPONENT_DEFS) {
          if (!ent.components[k]) html += '<option value="' + k + '">' + k + '</option>';
        }
        html += '</select></div>';
        for (const [name, data] of Object.entries(ent.components)) {
          html += '<div class="comp-card"><h4>' + name + ' <button data-remove="' + name + '">x</button></h4>';
          for (const [key, val] of Object.entries(data)) {
            const inputType = typeof val === 'boolean' ? 'checkbox' : typeof val === 'number' ? 'number' : 'text';
            if (inputType === 'checkbox') {
              html += '<div class="field-row"><input type="checkbox" data-comp="' + name + '" data-key="' + key + '" ' + (val ? 'checked' : '') + '><label>' + key + '</label></div>';
            } else {
              html += '<div class="field-row"><label style="width:80px">' + key + '</label><input type="' + inputType + '" data-comp="' + name + '" data-key="' + key + '" value="' + val + '" style="flex:1"></div>';
            }
          }
          html += '</div>';
        }
        el.innerHTML = html;
        document.getElementById('entName').addEventListener('input', (e) => { ent.name = e.target.value; refreshList(); });
        document.getElementById('addComp').addEventListener('change', (e) => {
          if (e.target.value && COMPONENT_DEFS[e.target.value]) {
            ent.components[e.target.value] = {...COMPONENT_DEFS[e.target.value]};
            refreshAll();
          }
        });
        el.querySelectorAll('[data-remove]').forEach(btn => {
          btn.addEventListener('click', (e) => { delete ent.components[e.target.dataset.remove]; refreshAll(); });
        });
        el.querySelectorAll('[data-comp]').forEach(inp => {
          inp.addEventListener('input', (e) => {
            const comp = e.target.dataset.comp, key = e.target.dataset.key;
            const orig = COMPONENT_DEFS[comp] && COMPONENT_DEFS[comp][key];
            if (e.target.type === 'checkbox') ent.components[comp][key] = e.target.checked;
            else if (typeof orig === 'number') ent.components[comp][key] = parseFloat(e.target.value) || 0;
            else ent.components[comp][key] = e.target.value;
            refreshPreview();
          });
        });
      }

      function refreshPreview() {
        const canvas = document.getElementById('previewCanvas');
        const ctx = canvas.getContext('2d');
        ctx.clearRect(0, 0, 180, 180);
        if (selectedIdx < 0) return;
        const ent = entities[selectedIdx];
        const sprite = ent.components.Sprite;
        if (sprite) {
          ctx.fillStyle = sprite.color || '#ccc';
          ctx.fillRect(90 - sprite.width/2, 90 - sprite.height/2, sprite.width, sprite.height);
        }
        const collider = ent.components.Collider;
        if (collider) {
          ctx.strokeStyle = collider.isSensor ? '#ffeb3b' : '#4caf50';
          ctx.lineWidth = 1; ctx.setLineDash([3, 3]);
          ctx.strokeRect(90 - collider.width/2, 90 - collider.height/2, collider.width, collider.height);
          ctx.setLineDash([]);
        }
        const stats = document.getElementById('statsArea');
        const compCount = Object.keys(ent.components).length;
        stats.innerHTML = 'Components: ' + compCount + '<br>Has Physics: ' + (ent.components.Physics ? 'Yes' : 'No') + '<br>Has AI: ' + (ent.components.AI ? 'Yes' : 'No');
        document.getElementById('statusInfo').textContent = 'Entities: ' + entities.length + ' | Components: ' + compCount;
      }

      function refreshAll() { refreshList(); refreshEditor(); refreshPreview(); }

      document.getElementById('btnNewEntity').addEventListener('click', () => createEntity());
      document.getElementById('btnDuplicate').addEventListener('click', () => {
        if (selectedIdx < 0) return;
        const src = entities[selectedIdx];
        createEntity(src.name + '_copy', JSON.parse(JSON.stringify(src.components)));
      });
      document.getElementById('btnDeleteEntity').addEventListener('click', () => {
        if (selectedIdx < 0) return;
        entities.splice(selectedIdx, 1);
        selectedIdx = Math.min(selectedIdx, entities.length - 1);
        refreshAll();
      });
      document.querySelectorAll('[data-tpl]').forEach(btn => {
        btn.addEventListener('click', (e) => {
          const tpl = TEMPLATES[e.target.dataset.tpl];
          if (tpl) createEntity(tpl.name, JSON.parse(JSON.stringify(tpl.components)));
        });
      });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = '-- Entity factory functions\\nlocal entities = {}\\n\\n';
        for (const ent of entities) {
          lua += 'function entities.create' + ent.name.replace(/[^a-zA-Z0-9]/g,'') + '(x, y)\\n';
          lua += '  local e = lurek.ecs.spawn()\\n';
          for (const [comp, data] of Object.entries(ent.components)) {
            lua += '  lurek.ecs.addComponent(e, "' + comp.toLowerCase() + '", {\\n';
            for (const [k, v] of Object.entries(data)) {
              if (typeof v === 'string') lua += '    ' + k + ' = "' + v + '",\\n';
              else if (typeof v === 'boolean') lua += '    ' + k + ' = ' + v + ',\\n';
              else lua += '    ' + k + ' = ' + v + ',\\n';
            }
            lua += '  })\\n';
          }
          lua += '  return e\\nend\\n\\n';
        }
        lua += 'return entities\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      refreshAll();
    `);
  }
}
