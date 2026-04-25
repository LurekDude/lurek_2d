import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

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
      .status-bar { grid-column: 1 / -1; }
      .entity-list { grid-row: 2; background: var(--surface); border-right: 1px solid var(--border); overflow-y: auto; }
      .component-editor { grid-row: 2; padding: 10px; overflow-y: auto; }
      .preview-panel { grid-row: 2; border-left: 1px solid var(--border); overflow-y: auto; background: var(--surface); }

      .entity-item {
        padding: 5px 10px; cursor: pointer; border-radius: var(--radius); margin: 1px 4px;
        font-size: 12px; display: flex; align-items: center; gap: 6px; transition: background 0.08s;
      }
      .entity-item:hover { background: var(--hover); }
      .entity-item.selected { background: var(--selection); }
      .entity-item .icon { opacity: 0.5; }

      .comp-card {
        background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius);
        margin-bottom: 6px; overflow: hidden;
      }
      .comp-card-header {
        display: flex; align-items: center; justify-content: space-between;
        padding: 5px 8px; background: var(--surface-2); font-size: 11px; font-weight: 600;
        text-transform: uppercase; letter-spacing: 0.3px;
        border-bottom: 1px solid var(--border); cursor: grab;
      }
      .comp-card-header .actions { display: flex; gap: 2px; }
      .comp-card-body { padding: 6px 8px; }
      .comp-card-body .field-row { display: flex; align-items: center; gap: 4px; margin-bottom: 3px; }
      .comp-card-body .field-row label { font-size: 10px; width: 70px; text-align: right; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.3px; }
      .comp-card-body .field-row input[type=text],
      .comp-card-body .field-row input[type=number] { flex: 1; }
      .comp-card-body .field-row select { flex: 1; }

      .template-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 4px; }
      .template-grid button { font-size: 11px; padding: 6px 4px; text-align: center; }

      .preview-canvas-wrap {
        background: var(--bg); border: 1px solid var(--border); border-radius: var(--radius);
        margin: 0 8px; overflow: hidden; aspect-ratio: 1;
      }
      .preview-canvas-wrap canvas { display: block; width: 100%; height: 100%; }

      .stat-row { display: flex; justify-content: space-between; font-size: 10px; padding: 2px 0; color: var(--text-dim); }
      .stat-row .val { color: var(--text); font-family: var(--font-mono); }
    `, `
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            ${iconButton('add', { id: 'btnNewEntity', title: 'New Entity (N)' })}
            ${iconButton('copy', { id: 'btnDuplicate', title: 'Duplicate (Ctrl+D)' })}
            ${iconButton('trash', { id: 'btnDeleteEntity', title: 'Delete Entity (Del)', cls: 'danger' })}
          </div>
          ${toolbarSep()}
          <div class="group">
            ${iconButton('undo', { id: 'btnUndo', title: 'Undo (Ctrl+Z)' })}
            ${iconButton('redo', { id: 'btnRedo', title: 'Redo (Ctrl+Y)' })}
          </div>
          ${toolbarSpacer()}
          <div class="group">
            ${iconButton('copy', { id: 'btnCopyLua', title: 'Copy Lua Code' })}
            ${iconButton('insert', { id: 'btnInsert', title: 'Insert to Editor' })}
          </div>
          ${toolbarSep()}
          <button id="btnExport" class="primary">${ICONS.exportFile} Export ▾</button>
        </div>

        <!-- Entity List -->
        <div class="entity-list">
          ${panelSection('Entities', '<div id="entityList"></div>')}
          ${panelSection('Templates', `
            <div class="template-grid">
              <button data-tpl="player">${ICONS.entity} Player</button>
              <button data-tpl="enemy">${ICONS.entity} Enemy</button>
              <button data-tpl="pickup">${ICONS.entity} Pickup</button>
              <button data-tpl="projectile">${ICONS.entity} Projectile</button>
              <button data-tpl="npc">${ICONS.entity} NPC</button>
              <button data-tpl="trigger">${ICONS.entity} Trigger</button>
            </div>
          `, true)}
        </div>

        <!-- Component Editor (center) -->
        <div class="component-editor" id="compEditor">
          <p style="color:var(--text-dim); text-align:center; margin-top:40px;">Select or create an entity to begin editing.</p>
        </div>

        <!-- Preview Panel -->
        <div class="preview-panel">
          ${panelSection('Preview', `
            <div class="preview-canvas-wrap"><canvas id="previewCanvas" width="180" height="180"></canvas></div>
          `)}
          ${panelSection('Stats', '<div id="statsArea"></div>')}
          ${panelSection('Quick Add', `
            <select id="addCompSelect" style="width:100%; margin-bottom:4px;">
              <option value="">Add Component...</option>
            </select>
          `, true)}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusEntCount" class="badge">0 entities</span>
          </span>
          <div class="sep"></div>
          <span id="statusCompCount">0 components</span>
          <div class="spacer"></div>
          <span id="statusSelected">None selected</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${ICONS.clean}</span>
        </div>
      </div>
    `, `
      // ── Component Definitions ──────────────────────────
      const COMPONENT_DEFS = {
        Transform: { x: 0, y: 0, rotation: 0, scaleX: 1, scaleY: 1 },
        Sprite:    { image: '', width: 32, height: 32, color: '#ffffff', layer: 0 },
        Physics:   { bodyType: 'dynamic', mass: 1, friction: 0.3, restitution: 0.2, fixedRotation: false },
        Collider:  { shape: 'rectangle', width: 32, height: 32, isSensor: false },
        AI:        { behavior: 'idle', speed: 100, detectionRange: 200, attackRange: 50 },
        Health:    { maxHp: 100, currentHp: 100, invincible: false },
        Tag:       { tag: '' },
        Custom:    { key: '', value: '' },
      };

      const TEMPLATES = {
        player:     { name: 'Player', components: { Transform: {...COMPONENT_DEFS.Transform}, Sprite: {...COMPONENT_DEFS.Sprite, width:32, height:48, color:'#4ec9b0'}, Physics: {...COMPONENT_DEFS.Physics}, Collider: {...COMPONENT_DEFS.Collider, height:48}, Health: {...COMPONENT_DEFS.Health} }},
        enemy:      { name: 'Enemy', components: { Transform: {...COMPONENT_DEFS.Transform}, Sprite: {...COMPONENT_DEFS.Sprite, color:'#f44336'}, Physics: {...COMPONENT_DEFS.Physics}, Collider: {...COMPONENT_DEFS.Collider}, AI: {...COMPONENT_DEFS.AI, behavior:'chase'}, Health: {...COMPONENT_DEFS.Health, maxHp:50, currentHp:50} }},
        pickup:     { name: 'Pickup', components: { Transform: {...COMPONENT_DEFS.Transform}, Sprite: {...COMPONENT_DEFS.Sprite, width:16, height:16, color:'#ffeb3b'}, Collider: {...COMPONENT_DEFS.Collider, width:16, height:16, isSensor:true} }},
        projectile: { name: 'Projectile', components: { Transform: {...COMPONENT_DEFS.Transform}, Sprite: {...COMPONENT_DEFS.Sprite, width:8, height:8, color:'#ff9800'}, Physics: {...COMPONENT_DEFS.Physics, mass:0.1}, Collider: {...COMPONENT_DEFS.Collider, width:8, height:8} }},
        npc:        { name: 'NPC', components: { Transform: {...COMPONENT_DEFS.Transform}, Sprite: {...COMPONENT_DEFS.Sprite, width:32, height:48, color:'#89b4fa'}, AI: {...COMPONENT_DEFS.AI, behavior:'idle'}, Health: {...COMPONENT_DEFS.Health, maxHp:80, currentHp:80}, Tag: { tag: 'npc' } }},
        trigger:    { name: 'Trigger', components: { Transform: {...COMPONENT_DEFS.Transform}, Collider: {...COMPONENT_DEFS.Collider, width:64, height:64, isSensor:true}, Tag: { tag: 'trigger' } }},
      };

      const COMP_COLORS = {
        Transform: '#89b4fa', Sprite: '#a6e3a1', Physics: '#fab387', Collider: '#f9e2af',
        AI: '#cba6f7', Health: '#f38ba8', Tag: '#94e2d5', Custom: '#9399b2',
      };

      let entities = [], selectedIdx = -1;
      const undo = new UndoStack(80);

      function snapshot() { return JSON.parse(JSON.stringify({ entities, selectedIdx })); }
      function restore(s) { entities = s.entities; selectedIdx = s.selectedIdx; refreshAll(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      function createEntity(name, comps) {
        pushUndo();
        entities.push({ name: name || 'Entity_' + entities.length, components: comps || { Transform: {...COMPONENT_DEFS.Transform} } });
        selectedIdx = entities.length - 1;
        refreshAll();
      }

      // ── List Rendering ─────────────────────────────────
      function refreshList() {
        const el = document.getElementById('entityList');
        el.innerHTML = '';
        entities.forEach((ent, i) => {
          const div = document.createElement('div');
          div.className = 'entity-item' + (i === selectedIdx ? ' selected' : '');
          const compCount = Object.keys(ent.components).length;
          div.innerHTML = '<span class="icon">${ICONS.entity}</span><span style="flex:1">' + ent.name + '</span><span style="font-size:10px;color:var(--text-dim)">' + compCount + '</span>';
          div.addEventListener('click', () => { selectedIdx = i; refreshAll(); });
          el.appendChild(div);
        });
      }

      // ── Component Editor ───────────────────────────────
      function refreshEditor() {
        const el = document.getElementById('compEditor');
        if (selectedIdx < 0 || selectedIdx >= entities.length) {
          el.innerHTML = '<p style="color:var(--text-dim); text-align:center; margin-top:40px;">Select or create an entity.</p>';
          return;
        }
        const ent = entities[selectedIdx];
        let html = '<div class="comp-card"><div class="comp-card-header">Identity</div><div class="comp-card-body">';
        html += '<div class="field-row"><label>Name</label><input id="entName" type="text" value="' + ent.name + '"></div>';
        html += '</div></div>';

        // Add component dropdown
        const addSel = document.getElementById('addCompSelect');
        if (addSel) {
          addSel.innerHTML = '<option value="">Add Component...</option>';
          for (const k in COMPONENT_DEFS) {
            if (!ent.components[k]) addSel.innerHTML += '<option value="' + k + '">' + k + '</option>';
          }
        }

        for (const [name, data] of Object.entries(ent.components)) {
          const clr = COMP_COLORS[name] || '#9399b2';
          html += '<div class="comp-card"><div class="comp-card-header"><span style="display:flex;align-items:center;gap:4px"><span style="display:inline-block;width:8px;height:8px;border-radius:50%;background:' + clr + '"></span>' + name + '</span>';
          html += '<span class="actions"><button class="icon-btn" data-remove="' + name + '" title="Remove">${ICONS.trash}</button></span></div>';
          html += '<div class="comp-card-body">';
          for (const [key, val] of Object.entries(data)) {
            if (typeof val === 'boolean') {
              html += '<div class="field-row"><label>' + key + '</label><input type="checkbox" data-comp="' + name + '" data-key="' + key + '" ' + (val ? 'checked' : '') + '></div>';
            } else if (key === 'bodyType') {
              html += '<div class="field-row"><label>' + key + '</label><select data-comp="' + name + '" data-key="' + key + '"><option value="dynamic"' + (val==='dynamic'?' selected':'') + '>Dynamic</option><option value="static"' + (val==='static'?' selected':'') + '>Static</option><option value="kinematic"' + (val==='kinematic'?' selected':'') + '>Kinematic</option></select></div>';
            } else if (key === 'shape') {
              html += '<div class="field-row"><label>' + key + '</label><select data-comp="' + name + '" data-key="' + key + '"><option value="rectangle"' + (val==='rectangle'?' selected':'') + '>Rectangle</option><option value="circle"' + (val==='circle'?' selected':'') + '>Circle</option></select></div>';
            } else if (key === 'behavior') {
              html += '<div class="field-row"><label>' + key + '</label><select data-comp="' + name + '" data-key="' + key + '"><option value="idle"' + (val==='idle'?' selected':'') + '>Idle</option><option value="chase"' + (val==='chase'?' selected':'') + '>Chase</option><option value="patrol"' + (val==='patrol'?' selected':'') + '>Patrol</option><option value="flee"' + (val==='flee'?' selected':'') + '>Flee</option></select></div>';
            } else if (key === 'color') {
              html += '<div class="field-row"><label>' + key + '</label><input type="color" data-comp="' + name + '" data-key="' + key + '" value="' + val + '" style="width:28px;height:22px;border:1px solid var(--border);border-radius:var(--radius);padding:0"></div>';
            } else {
              const t = typeof val === 'number' ? 'number' : 'text';
              html += '<div class="field-row"><label>' + key + '</label><input type="' + t + '" data-comp="' + name + '" data-key="' + key + '" value="' + val + '"></div>';
            }
          }
          html += '</div></div>';
        }
        el.innerHTML = html;

        // Bindings
        document.getElementById('entName').addEventListener('input', (e) => { pushUndo(); ent.name = e.target.value; refreshList(); updateStatus(); });
        el.querySelectorAll('[data-remove]').forEach(btn => {
          btn.addEventListener('click', (e) => { pushUndo(); delete ent.components[e.currentTarget.dataset.remove]; refreshAll(); });
        });
        el.querySelectorAll('[data-comp]').forEach(inp => {
          const handler = (e) => {
            pushUndo();
            const comp = e.target.dataset.comp, key = e.target.dataset.key;
            const orig = COMPONENT_DEFS[comp] && COMPONENT_DEFS[comp][key];
            if (e.target.type === 'checkbox') ent.components[comp][key] = e.target.checked;
            else if (typeof orig === 'number') ent.components[comp][key] = parseFloat(e.target.value) || 0;
            else ent.components[comp][key] = e.target.value;
            refreshPreview();
          };
          inp.addEventListener(inp.type === 'checkbox' || inp.tagName === 'SELECT' ? 'change' : 'input', handler);
        });
      }

      // ── Preview ────────────────────────────────────────
      function refreshPreview() {
        const canvas = document.getElementById('previewCanvas');
        const ctx = canvas.getContext('2d');
        ctx.clearRect(0, 0, 180, 180);

        // Grid
        ctx.strokeStyle = 'rgba(137,180,250,0.08)'; ctx.lineWidth = 1;
        for (let i = 0; i <= 180; i += 18) { ctx.beginPath(); ctx.moveTo(i, 0); ctx.lineTo(i, 180); ctx.stroke(); ctx.beginPath(); ctx.moveTo(0, i); ctx.lineTo(180, i); ctx.stroke(); }

        if (selectedIdx < 0 || selectedIdx >= entities.length) return;
        const ent = entities[selectedIdx];

        // Origin
        ctx.strokeStyle = 'rgba(137,180,250,0.3)'; ctx.lineWidth = 0.5;
        ctx.beginPath(); ctx.moveTo(90, 0); ctx.lineTo(90, 180); ctx.stroke();
        ctx.beginPath(); ctx.moveTo(0, 90); ctx.lineTo(180, 90); ctx.stroke();

        const sprite = ent.components.Sprite;
        if (sprite) {
          ctx.fillStyle = sprite.color || '#ccc';
          ctx.fillRect(90 - sprite.width/2, 90 - sprite.height/2, sprite.width, sprite.height);
        }
        const collider = ent.components.Collider;
        if (collider) {
          ctx.strokeStyle = collider.isSensor ? '#f9e2af' : '#a6e3a1';
          ctx.lineWidth = 1.5; ctx.setLineDash([4, 3]);
          if (collider.shape === 'circle') {
            ctx.beginPath(); ctx.arc(90, 90, collider.width/2, 0, Math.PI*2); ctx.stroke();
          } else {
            ctx.strokeRect(90 - collider.width/2, 90 - collider.height/2, collider.width, collider.height);
          }
          ctx.setLineDash([]);
        }
        if (ent.components.AI && ent.components.AI.detectionRange) {
          ctx.strokeStyle = 'rgba(203,166,247,0.2)'; ctx.lineWidth = 1; ctx.setLineDash([2, 4]);
          ctx.beginPath(); ctx.arc(90, 90, Math.min(ent.components.AI.detectionRange/2, 85), 0, Math.PI*2); ctx.stroke();
          ctx.setLineDash([]);
        }

        updateStatus();
      }

      function updateStatus() {
        const ent = selectedIdx >= 0 && selectedIdx < entities.length ? entities[selectedIdx] : null;
        const compCount = ent ? Object.keys(ent.components).length : 0;
        document.getElementById('statusEntCount').textContent = entities.length + ' entities';
        document.getElementById('statusCompCount').textContent = compCount + ' components';
        document.getElementById('statusSelected').textContent = ent ? ent.name : 'None selected';

        const statsEl = document.getElementById('statsArea');
        if (ent) {
          let html = '';
          html += '<div class="stat-row"><span>Components</span><span class="val">' + compCount + '</span></div>';
          html += '<div class="stat-row"><span>Physics</span><span class="val">' + (ent.components.Physics ? ent.components.Physics.bodyType : '—') + '</span></div>';
          html += '<div class="stat-row"><span>AI</span><span class="val">' + (ent.components.AI ? ent.components.AI.behavior : '—') + '</span></div>';
          html += '<div class="stat-row"><span>Health</span><span class="val">' + (ent.components.Health ? ent.components.Health.currentHp + '/' + ent.components.Health.maxHp : '—') + '</span></div>';
          html += '<div class="stat-row"><span>Sensor</span><span class="val">' + (ent.components.Collider && ent.components.Collider.isSensor ? 'Yes' : 'No') + '</span></div>';
          statsEl.innerHTML = html;
        } else { statsEl.innerHTML = ''; }
      }

      function refreshAll() { refreshList(); refreshEditor(); refreshPreview(); }

      // ── Toolbar ────────────────────────────────────────
      document.getElementById('btnNewEntity').addEventListener('click', () => createEntity());
      document.getElementById('btnDuplicate').addEventListener('click', () => {
        if (selectedIdx < 0) return;
        const src = entities[selectedIdx];
        createEntity(src.name + '_copy', JSON.parse(JSON.stringify(src.components)));
      });
      document.getElementById('btnDeleteEntity').addEventListener('click', () => {
        if (selectedIdx < 0) return;
        pushUndo();
        entities.splice(selectedIdx, 1);
        selectedIdx = Math.min(selectedIdx, entities.length - 1);
        refreshAll();
      });
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restore(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restore(s); });
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restore(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restore(s); });
      registerShortcut('n', () => createEntity());
      registerShortcut('delete', () => {
        if (selectedIdx < 0) return;
        pushUndo(); entities.splice(selectedIdx, 1);
        selectedIdx = Math.min(selectedIdx, entities.length - 1);
        refreshAll();
      });

      document.querySelectorAll('[data-tpl]').forEach(btn => {
        btn.addEventListener('click', (e) => {
          const tpl = TEMPLATES[e.currentTarget.dataset.tpl];
          if (tpl) createEntity(tpl.name, JSON.parse(JSON.stringify(tpl.components)));
        });
      });

      document.getElementById('addCompSelect').addEventListener('change', (e) => {
        if (selectedIdx < 0 || !e.target.value) return;
        if (COMPONENT_DEFS[e.target.value]) {
          pushUndo();
          entities[selectedIdx].components[e.target.value] = {...COMPONENT_DEFS[e.target.value]};
          refreshAll();
        }
        e.target.value = '';
      });

      // ── Export ─────────────────────────────────────────
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Entity Designer', '-- Usage: local factory = require("entities")', ''];
        lines.push('local entities = {}');
        lines.push('');
        for (const ent of entities) {
          const fn = ent.name.replace(/[^a-zA-Z0-9_]/g, '');
          lines.push('function entities.create_' + fn + '(x, y)');
          lines.push('  local e = lurek.ecs.spawn()');
          for (const [comp, data] of Object.entries(ent.components)) {
            lines.push('  lurek.ecs.addComponent(e, "' + comp.toLowerCase() + '", {');
            for (const [k, v] of Object.entries(data)) {
              if (comp === 'Transform' && (k === 'x' || k === 'y')) {
                lines.push('    ' + k + ' = ' + (k === 'x' ? 'x or 0' : 'y or 0') + ',');
              } else if (typeof v === 'string') {
                lines.push('    ' + k + ' = "' + v + '",');
              } else if (typeof v === 'boolean') {
                lines.push('    ' + k + ' = ' + v + ',');
              } else {
                lines.push('    ' + k + ' = ' + v + ',');
              }
            }
            lines.push('  })');
          }
          lines.push('  return e');
          lines.push('end');
          lines.push('');
        }
        lines.push('return entities');
        return lines.join('\\n');
      }

      createExportDropdown(document.getElementById('btnExport'), [
        { label: 'Export Lua File', action: () => vscode.postMessage({ type: 'exportLua', content: buildLuaCode() }) },
        { label: 'Copy Lua Code', action: () => vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() }) },
        { label: 'Insert to Editor', action: () => vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() }) },
      ]);

      document.getElementById('btnCopyLua').addEventListener('click', () => {
        vscode.postMessage({ type: 'copyToClipboard', content: buildLuaCode() });
      });
      document.getElementById('btnInsert').addEventListener('click', () => {
        vscode.postMessage({ type: 'insertToEditor', content: buildLuaCode() });
      });

      // ── Init ───────────────────────────────────────────
      refreshAll();
    `);
  }
}
