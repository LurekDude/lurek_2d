import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

export class GuiWidgetEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): GuiWidgetEditor {
    return new GuiWidgetEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.editor.guiWidget", "GUI Widget Editor");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "gui_layout.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "GUI Widget Editor", `
      .editor-layout {
        display: grid; grid-template-columns: 180px 1fr 240px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .hierarchy-panel { grid-row: 2; background: var(--surface); border-right: 1px solid var(--border); overflow-y: auto; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: var(--bg); }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); overflow-y: auto; background: var(--surface); }

      .widget-item {
        padding: 4px 8px; cursor: pointer; font-size: 11px; border-radius: var(--radius);
        margin: 1px 4px; display: flex; align-items: center; gap: 6px; transition: background 0.08s;
      }
      .widget-item:hover { background: var(--hover); }
      .widget-item.sel { background: var(--selection); }
      .widget-item .type-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
      .widget-item .hidden-tag { font-size: 9px; color: var(--text-dim); margin-left: auto; }

      .prop-field { margin-bottom: 6px; }
      .prop-field label { display: block; font-size: 10px; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.3px; margin-bottom: 2px; }
      .prop-row { display: grid; grid-template-columns: 30px 1fr 30px 1fr; gap: 4px; align-items: center; margin-bottom: 4px; }
      .prop-row label { font-size: 10px; text-align: right; color: var(--text-dim); }
    `, `
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            <select id="addWidget" style="width:130px">
              <option value="">+ Add Widget...</option>
              <option value="Button">Button</option>
              <option value="Panel">Panel</option>
              <option value="Label">Label</option>
              <option value="ProgressBar">Progress Bar</option>
              <option value="Checkbox">Checkbox</option>
              <option value="Slider">Slider</option>
              <option value="Image">Image</option>
            </select>
            ${iconButton('trash', { id: 'btnDelete', title: 'Delete (Del)', cls: 'danger' })}
          </div>
          ${toolbarSep()}
          <div class="group">
            ${iconButton('undo', { id: 'btnUndo', title: 'Undo (Ctrl+Z)' })}
            ${iconButton('redo', { id: 'btnRedo', title: 'Redo (Ctrl+Y)' })}
          </div>
          ${toolbarSep()}
          <div class="group">
            <button id="btnGrid" title="Toggle Grid Snap">${ICONS.grid} Snap</button>
            <button id="btnAlignH" title="Align Horizontal Centers">⟷</button>
            <button id="btnAlignV" title="Align Vertical Centers">⟘</button>
          </div>
          ${toolbarSpacer()}
          <div class="group">
            ${iconButton('copy', { id: 'btnCopyLua', title: 'Copy Lua Code' })}
            ${iconButton('insert', { id: 'btnInsert', title: 'Insert to Editor' })}
          </div>
          ${toolbarSep()}
          <button id="btnExport" class="primary">${ICONS.exportFile} Export ▾</button>
        </div>

        <!-- Hierarchy -->
        <div class="hierarchy-panel">
          ${panelSection('Widget Hierarchy', '<div id="hierarchy"></div>')}
        </div>

        <!-- Canvas -->
        <div class="canvas-area"><canvas id="guiCanvas"></canvas></div>

        <!-- Properties -->
        <div class="props-panel">
          ${panelSection('Properties', '<div id="propsContent"><p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:20px;">Select a widget</p></div>')}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusWidgets" class="badge">0 widgets</span>
          </span>
          <div class="sep"></div>
          <span id="statusSel">No selection</span>
          <div class="sep"></div>
          <span id="statusGrid">Snap: Off</span>
          <div class="spacer"></div>
          <span class="dirty-indicator">${ICONS.clean}</span>
        </div>
      </div>
    `, `
      const canvas = document.getElementById('guiCanvas');
      const ctx = canvas.getContext('2d');
      let widgets = [], selectedIdx = -1;
      let dragWidget = null, dragOff = { x: 0, y: 0 };
      let nextId = 1, gridSnap = false;
      const undo = new UndoStack(60);
      const SNAP = 8;

      const TYPE_COLORS = {
        Button: '#89b4fa', Panel: '#6c7086', Label: '#a6e3a1',
        ProgressBar: '#f9e2af', Checkbox: '#cba6f7', Slider: '#fab387', Image: '#f38ba8',
      };

      function snapshot() { return JSON.parse(JSON.stringify({ widgets, selectedIdx, nextId })); }
      function restoreSnap(s) { widgets = s.widgets; selectedIdx = s.selectedIdx; nextId = s.nextId; refreshAll(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      const WIDGET_DEFAULTS = {
        Button: { w: 120, h: 36, text: 'Click Me', color: '#89b4fa', fontSize: 14, anchor: 'topLeft' },
        Panel: { w: 200, h: 150, text: '', color: '#1e1e2e', fontSize: 12, anchor: 'topLeft' },
        Label: { w: 100, h: 24, text: 'Label', color: 'transparent', fontSize: 14, anchor: 'topLeft' },
        ProgressBar: { w: 150, h: 20, text: '', color: '#a6e3a1', fontSize: 10, anchor: 'topLeft', value: 0.65 },
        Checkbox: { w: 24, h: 24, text: 'Option', color: '#45475a', fontSize: 12, anchor: 'topLeft', checked: false },
        Slider: { w: 150, h: 20, text: '', color: '#6c7086', fontSize: 10, anchor: 'topLeft', value: 0.5 },
        Image: { w: 64, h: 64, text: 'img', color: '#313244', fontSize: 10, anchor: 'topLeft' },
      };

      function snap(v) { return gridSnap ? Math.round(v / SNAP) * SNAP : v; }

      function addWidget(type) {
        pushUndo();
        const d = WIDGET_DEFAULTS[type];
        widgets.push({
          id: nextId++, type, name: type.toLowerCase() + '_' + nextId,
          x: snap(60 + widgets.length * 20), y: snap(60 + widgets.length * 20),
          w: d.w, h: d.h, text: d.text, color: d.color,
          fontSize: d.fontSize, anchor: d.anchor, visible: true,
          value: d.value, checked: d.checked,
        });
        selectedIdx = widgets.length - 1;
        refreshAll();
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight; render();
      }

      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // Grid
        if (gridSnap) {
          ctx.strokeStyle = 'rgba(255,255,255,0.03)'; ctx.lineWidth = 1;
          for (let x = 0; x < canvas.width; x += SNAP) { ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, canvas.height); ctx.stroke(); }
          for (let y = 0; y < canvas.height; y += SNAP) { ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(canvas.width, y); ctx.stroke(); }
        }

        // Reference frame (game viewport)
        ctx.strokeStyle = 'rgba(255,255,255,0.1)'; ctx.lineWidth = 1; ctx.setLineDash([4, 4]);
        ctx.strokeRect(20, 20, 800, 600); ctx.setLineDash([]);
        ctx.fillStyle = 'rgba(255,255,255,0.15)'; ctx.font = '10px sans-serif'; ctx.textAlign = 'left';
        ctx.fillText('800 × 600 viewport', 24, 16);

        for (let i = 0; i < widgets.length; i++) {
          const w = widgets[i];
          if (!w.visible) continue;
          const sel = i === selectedIdx;

          ctx.fillStyle = w.color; ctx.strokeStyle = sel ? 'var(--accent, #89b4fa)' : 'rgba(255,255,255,0.08)';
          ctx.lineWidth = sel ? 2 : 1;

          switch (w.type) {
            case 'Button':
              ctx.beginPath(); ctx.roundRect(w.x, w.y, w.w, w.h, 4); ctx.fill(); ctx.stroke();
              ctx.fillStyle = '#1e1e2e'; ctx.font = 'bold ' + w.fontSize + 'px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
              ctx.fillText(w.text, w.x + w.w / 2, w.y + w.h / 2);
              break;
            case 'Panel':
              ctx.fillRect(w.x, w.y, w.w, w.h); ctx.strokeRect(w.x, w.y, w.w, w.h);
              break;
            case 'Label':
              ctx.fillStyle = '#cdd6f4'; ctx.font = w.fontSize + 'px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'top';
              ctx.fillText(w.text, w.x, w.y);
              if (sel) { ctx.strokeStyle = 'var(--accent, #89b4fa)'; ctx.strokeRect(w.x - 2, w.y - 2, w.w + 4, w.h + 4); }
              break;
            case 'ProgressBar':
              ctx.fillStyle = '#313244'; ctx.fillRect(w.x, w.y, w.w, w.h);
              ctx.fillStyle = w.color; ctx.fillRect(w.x, w.y, w.w * (w.value || 0), w.h);
              ctx.strokeRect(w.x, w.y, w.w, w.h);
              ctx.fillStyle = '#1e1e2e'; ctx.font = '10px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
              ctx.fillText(Math.round((w.value || 0) * 100) + '%', w.x + w.w / 2, w.y + w.h / 2);
              break;
            case 'Checkbox':
              ctx.strokeRect(w.x, w.y, 18, 18);
              if (w.checked) { ctx.fillStyle = '#a6e3a1'; ctx.fillRect(w.x + 3, w.y + 3, 12, 12); }
              ctx.fillStyle = '#cdd6f4'; ctx.font = '12px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'middle';
              ctx.fillText(w.text, w.x + 24, w.y + 9);
              break;
            case 'Slider':
              ctx.fillStyle = '#313244'; ctx.fillRect(w.x, w.y + 6, w.w, 8);
              ctx.fillStyle = w.color;
              const knobX = w.x + w.w * (w.value || 0);
              ctx.beginPath(); ctx.arc(knobX, w.y + 10, 8, 0, Math.PI * 2); ctx.fill();
              if (sel) { ctx.strokeStyle = 'var(--accent, #89b4fa)'; ctx.strokeRect(w.x - 2, w.y - 2, w.w + 4, w.h + 4); }
              break;
            case 'Image':
              ctx.fillRect(w.x, w.y, w.w, w.h); ctx.strokeRect(w.x, w.y, w.w, w.h);
              ctx.fillStyle = '#6c7086'; ctx.font = '10px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
              ctx.fillText('[' + w.text + ']', w.x + w.w / 2, w.y + w.h / 2);
              break;
          }

          if (sel) {
            ctx.fillStyle = 'var(--accent, #89b4fa)';
            const hs = 4;
            [[w.x-hs,w.y-hs],[w.x+w.w-hs,w.y-hs],[w.x-hs,w.y+w.h-hs],[w.x+w.w-hs,w.y+w.h-hs]].forEach(([hx,hy]) => {
              ctx.fillRect(hx, hy, hs*2, hs*2);
            });
          }
        }
      }

      function hitTest(sx, sy) {
        for (let i = widgets.length - 1; i >= 0; i--) {
          const w = widgets[i];
          if (sx >= w.x && sx <= w.x + w.w && sy >= w.y && sy <= w.y + w.h) return i;
        }
        return -1;
      }

      function showProps(idx) {
        const el = document.getElementById('propsContent');
        if (idx < 0) { el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:20px;">Select a widget</p>'; updateStatus(); return; }
        const w = widgets[idx];
        let html = '<div class="prop-field"><label>Name</label><input id="pName" value="' + w.name.replace(/"/g, '&quot;') + '"></div>';
        html += '<div class="prop-row"><label>X</label><input type="number" id="pX" value="' + w.x + '" style="width:60px"><label>Y</label><input type="number" id="pY" value="' + w.y + '" style="width:60px"></div>';
        html += '<div class="prop-row"><label>W</label><input type="number" id="pW" value="' + w.w + '" style="width:60px"><label>H</label><input type="number" id="pH" value="' + w.h + '" style="width:60px"></div>';
        html += '<div class="prop-field"><label>Text</label><input id="pText" value="' + (w.text || '').replace(/"/g, '&quot;') + '"></div>';
        html += '<div class="prop-field"><label>Color</label><input type="color" id="pColor" value="' + (w.color.startsWith('#') ? w.color : '#333333') + '" style="width:100%"></div>';
        html += '<div class="prop-field"><label>Font Size</label><input type="number" id="pFont" value="' + w.fontSize + '" min="8" max="48" style="width:60px"></div>';
        html += '<div class="prop-field"><label>Anchor</label><select id="pAnchor" style="width:100%"><option value="topLeft">Top Left</option><option value="topRight">Top Right</option><option value="center">Center</option><option value="bottomLeft">Bottom Left</option><option value="bottomRight">Bottom Right</option></select></div>';
        html += '<div class="prop-field" style="display:flex;align-items:center;gap:6px"><input type="checkbox" id="pVisible" ' + (w.visible ? 'checked' : '') + '><label style="margin:0">Visible</label></div>';
        if (w.value !== undefined) html += '<div class="prop-field"><label>Value</label><input type="range" id="pVal" value="' + w.value + '" min="0" max="1" step="0.01" style="width:100%"><span id="pValDisp" style="font-size:10px;font-family:var(--font-mono)">' + (w.value * 100).toFixed(0) + '%</span></div>';
        if (w.checked !== undefined) html += '<div class="prop-field" style="display:flex;align-items:center;gap:6px"><input type="checkbox" id="pChecked" ' + (w.checked ? 'checked' : '') + '><label style="margin:0">Checked</label></div>';
        el.innerHTML = html;

        document.getElementById('pAnchor').value = w.anchor;

        const bind = (id, key, parse) => {
          const inp = document.getElementById(id);
          if (inp) inp.addEventListener('input', (e) => { pushUndo(); w[key] = parse ? parse(e.target.value) : e.target.value; render(); if (key === 'name') refreshHierarchy(); });
        };
        bind('pName', 'name'); bind('pText', 'text'); bind('pColor', 'color');
        bind('pX', 'x', parseFloat); bind('pY', 'y', parseFloat);
        bind('pW', 'w', parseFloat); bind('pH', 'h', parseFloat);
        bind('pFont', 'fontSize', parseInt);
        const valInp = document.getElementById('pVal');
        if (valInp) valInp.addEventListener('input', (e) => { pushUndo(); w.value = parseFloat(e.target.value); document.getElementById('pValDisp').textContent = (w.value * 100).toFixed(0) + '%'; render(); });
        document.getElementById('pAnchor').addEventListener('change', (e) => { pushUndo(); w.anchor = e.target.value; });
        document.getElementById('pVisible').addEventListener('change', (e) => { pushUndo(); w.visible = e.target.checked; render(); refreshHierarchy(); });
        const chk = document.getElementById('pChecked');
        if (chk) chk.addEventListener('change', (e) => { pushUndo(); w.checked = e.target.checked; render(); });
        updateStatus();
      }

      function updateStatus() {
        document.getElementById('statusWidgets').textContent = widgets.length + ' widgets';
        document.getElementById('statusSel').textContent = selectedIdx >= 0 ? widgets[selectedIdx].name : 'No selection';
        document.getElementById('statusGrid').textContent = 'Snap: ' + (gridSnap ? 'On' : 'Off');
      }

      function refreshHierarchy() {
        const el = document.getElementById('hierarchy');
        el.innerHTML = '';
        widgets.forEach((w, i) => {
          const div = document.createElement('div');
          div.className = 'widget-item' + (i === selectedIdx ? ' sel' : '');
          div.innerHTML = '<span class="type-dot" style="background:' + (TYPE_COLORS[w.type] || '#6c7086') + '"></span>' +
            '<span style="flex:1">' + w.name + '</span>' +
            (!w.visible ? '<span class="hidden-tag">hidden</span>' : '');
          div.addEventListener('click', () => { selectedIdx = i; showProps(i); refreshHierarchy(); render(); });
          el.appendChild(div);
        });
        updateStatus();
      }

      function refreshAll() { refreshHierarchy(); showProps(selectedIdx); render(); }

      // ── Canvas events ──────────────────────────────────
      canvas.addEventListener('mousedown', (e) => {
        const idx = hitTest(e.offsetX, e.offsetY);
        if (idx >= 0) {
          selectedIdx = idx;
          dragWidget = widgets[idx];
          dragOff = { x: e.offsetX - widgets[idx].x, y: e.offsetY - widgets[idx].y };
        } else { selectedIdx = -1; }
        showProps(selectedIdx); refreshHierarchy(); render();
      });
      canvas.addEventListener('mousemove', (e) => {
        if (dragWidget) {
          dragWidget.x = snap(Math.round(e.offsetX - dragOff.x));
          dragWidget.y = snap(Math.round(e.offsetY - dragOff.y));
          render();
        }
      });
      canvas.addEventListener('mouseup', () => { if (dragWidget) { pushUndo(); showProps(selectedIdx); } dragWidget = null; });

      // ── Toolbar ────────────────────────────────────────
      document.getElementById('addWidget').addEventListener('change', (e) => {
        if (e.target.value) { addWidget(e.target.value); e.target.value = ''; }
      });
      document.getElementById('btnDelete').addEventListener('click', () => {
        if (selectedIdx >= 0) { pushUndo(); widgets.splice(selectedIdx, 1); selectedIdx = -1; refreshAll(); }
      });
      document.getElementById('btnGrid').addEventListener('click', () => {
        gridSnap = !gridSnap;
        document.getElementById('btnGrid').classList.toggle('active', gridSnap);
        updateStatus(); render();
      });
      document.getElementById('btnAlignH').addEventListener('click', () => {
        if (selectedIdx < 0 || widgets.length < 2) return;
        pushUndo();
        const ref = widgets[selectedIdx];
        const cx = ref.x + ref.w / 2;
        widgets.forEach((w, i) => { if (i !== selectedIdx) w.x = snap(cx - w.w / 2); });
        render();
      });
      document.getElementById('btnAlignV').addEventListener('click', () => {
        if (selectedIdx < 0 || widgets.length < 2) return;
        pushUndo();
        const ref = widgets[selectedIdx];
        const cy = ref.y + ref.h / 2;
        widgets.forEach((w, i) => { if (i !== selectedIdx) w.y = snap(cy - w.h / 2); });
        render();
      });
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restoreSnap(s); });

      // ── Shortcuts ──────────────────────────────────────
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('Delete', () => document.getElementById('btnDelete').click());
      registerShortcut('ctrl+d', () => {
        if (selectedIdx < 0) return;
        pushUndo();
        const src = widgets[selectedIdx];
        const clone = JSON.parse(JSON.stringify(src));
        clone.id = nextId++; clone.name = src.type.toLowerCase() + '_' + nextId;
        clone.x += 20; clone.y += 20;
        widgets.push(clone); selectedIdx = widgets.length - 1; refreshAll();
      });

      // ── Export ─────────────────────────────────────────
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D GUI Widget Editor', '-- Usage: local layout = lurek.ui.load_layout(data)', ''];
        lines.push('return {');
        for (const w of widgets) {
          lines.push('  {');
          lines.push('    type = "' + w.type + '", name = "' + w.name + '",');
          lines.push('    x = ' + w.x + ', y = ' + w.y + ', w = ' + w.w + ', h = ' + w.h + ',');
          if (w.text) lines.push('    text = "' + w.text + '",');
          lines.push('    color = "' + w.color + '", fontSize = ' + w.fontSize + ',');
          lines.push('    anchor = "' + w.anchor + '", visible = ' + w.visible + ',');
          if (w.value !== undefined) lines.push('    value = ' + w.value + ',');
          if (w.checked !== undefined) lines.push('    checked = ' + w.checked + ',');
          lines.push('  },');
        }
        lines.push('}');
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
      widgets = [
        { id: 1, type: 'Panel', name: 'settings_panel', x: 50, y: 50, w: 200, h: 150, text: '', color: '#1e1e2e', fontSize: 12, anchor: 'topLeft', visible: true },
        { id: 2, type: 'Label', name: 'title_label', x: 80, y: 60, w: 100, h: 24, text: 'Settings', color: 'transparent', fontSize: 16, anchor: 'topLeft', visible: true },
        { id: 3, type: 'Button', name: 'apply_btn', x: 80, y: 120, w: 120, h: 36, text: 'Apply', color: '#89b4fa', fontSize: 14, anchor: 'topLeft', visible: true },
      ];
      nextId = 4; selectedIdx = -1;
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
      refreshAll();
    `);
  }
}
