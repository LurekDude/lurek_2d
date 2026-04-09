import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class GuiWidgetEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): GuiWidgetEditor {
    return new GuiWidgetEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "luna.editor.guiWidget", "GUI Widget Editor");
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
        display: grid; grid-template-columns: 180px 1fr 220px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .hierarchy-panel { grid-row: 2; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: #111; }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); padding: 8px; overflow-y: auto; background: var(--surface); }
      .status-bar { grid-column: 1 / -1; }
      .widget-item { padding: 3px 8px; cursor: pointer; font-size: 12px; border-radius: 2px; }
      .widget-item:hover { background: var(--surface-2); }
      .widget-item.sel { background: var(--selection); }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <label>Add:</label>
          <select id="addWidget">
            <option value="">Choose widget...</option>
            <option value="Button">Button</option>
            <option value="Panel">Panel</option>
            <option value="Label">Label</option>
            <option value="ProgressBar">ProgressBar</option>
            <option value="Checkbox">Checkbox</option>
            <option value="Slider">Slider</option>
            <option value="Image">Image</option>
          </select>
          <button id="btnDelete" class="danger">Delete</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="panel hierarchy-panel">
          <h3>Hierarchy</h3>
          <div id="hierarchy"></div>
        </div>
        <div class="canvas-area"><canvas id="guiCanvas"></canvas></div>
        <div class="props-panel">
          <h3>Properties</h3>
          <div id="propsContent"><p style="color:var(--text-dim);font-size:12px;">Select a widget.</p></div>
        </div>
        <div class="status-bar">
          <span id="statusInfo">Widgets: 0</span>
          <span id="statusSel">Selected: none</span>
        </div>
      </div>
    `, `
      const canvas = document.getElementById('guiCanvas');
      const ctx = canvas.getContext('2d');
      let widgets = [], selectedIdx = -1;
      let dragWidget = null, dragOff = { x: 0, y: 0 };
      let resizing = false, resizeHandle = '';
      let nextId = 1;

      const WIDGET_DEFAULTS = {
        Button: { w: 120, h: 36, text: 'Click Me', color: '#007acc', fontSize: 14, anchor: 'topLeft' },
        Panel: { w: 200, h: 150, text: '', color: '#252526', fontSize: 12, anchor: 'topLeft' },
        Label: { w: 100, h: 24, text: 'Label', color: 'transparent', fontSize: 14, anchor: 'topLeft' },
        ProgressBar: { w: 150, h: 20, text: '', color: '#4caf50', fontSize: 10, anchor: 'topLeft', value: 0.65 },
        Checkbox: { w: 24, h: 24, text: 'Option', color: '#333', fontSize: 12, anchor: 'topLeft', checked: false },
        Slider: { w: 150, h: 20, text: '', color: '#555', fontSize: 10, anchor: 'topLeft', value: 0.5 },
        Image: { w: 64, h: 64, text: 'img', color: '#333', fontSize: 10, anchor: 'topLeft' },
      };

      function addWidget(type) {
        const d = WIDGET_DEFAULTS[type];
        widgets.push({
          id: nextId++, type, name: type + '_' + nextId,
          x: 50 + widgets.length * 20, y: 50 + widgets.length * 20,
          w: d.w, h: d.h, text: d.text, color: d.color,
          fontSize: d.fontSize, anchor: d.anchor, visible: true,
          value: d.value, checked: d.checked
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
        // Reference frame
        ctx.strokeStyle = '#333'; ctx.lineWidth = 1;
        ctx.strokeRect(20, 20, 800, 600);
        ctx.fillStyle = '#333'; ctx.font = '10px sans-serif'; ctx.textAlign = 'left';
        ctx.fillText('800x600', 22, 16);

        for (let i = 0; i < widgets.length; i++) {
          const w = widgets[i];
          if (!w.visible) continue;
          const sel = i === selectedIdx;

          ctx.fillStyle = w.color; ctx.strokeStyle = sel ? '#007acc' : '#3c3c3c';
          ctx.lineWidth = sel ? 2 : 1;

          switch (w.type) {
            case 'Button':
              ctx.beginPath(); ctx.roundRect(w.x, w.y, w.w, w.h, 4); ctx.fill(); ctx.stroke();
              ctx.fillStyle = '#fff'; ctx.font = w.fontSize + 'px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
              ctx.fillText(w.text, w.x + w.w / 2, w.y + w.h / 2);
              break;
            case 'Panel':
              ctx.fillRect(w.x, w.y, w.w, w.h); ctx.strokeRect(w.x, w.y, w.w, w.h);
              break;
            case 'Label':
              ctx.fillStyle = '#ccc'; ctx.font = w.fontSize + 'px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'top';
              ctx.fillText(w.text, w.x, w.y);
              if (sel) ctx.strokeRect(w.x - 2, w.y - 2, w.w + 4, w.h + 4);
              break;
            case 'ProgressBar':
              ctx.fillStyle = '#333'; ctx.fillRect(w.x, w.y, w.w, w.h);
              ctx.fillStyle = w.color; ctx.fillRect(w.x, w.y, w.w * (w.value || 0), w.h);
              ctx.strokeRect(w.x, w.y, w.w, w.h);
              break;
            case 'Checkbox':
              ctx.strokeRect(w.x, w.y, 18, 18);
              if (w.checked) { ctx.fillStyle = '#4ec9b0'; ctx.fillRect(w.x + 3, w.y + 3, 12, 12); }
              ctx.fillStyle = '#ccc'; ctx.font = '12px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'middle';
              ctx.fillText(w.text, w.x + 24, w.y + 9);
              break;
            case 'Slider':
              ctx.fillStyle = '#333'; ctx.fillRect(w.x, w.y + 6, w.w, 8);
              ctx.fillStyle = w.color;
              const knobX = w.x + w.w * (w.value || 0);
              ctx.beginPath(); ctx.arc(knobX, w.y + 10, 8, 0, Math.PI * 2); ctx.fill();
              if (sel) ctx.strokeRect(w.x - 2, w.y - 2, w.w + 4, w.h + 4);
              break;
            case 'Image':
              ctx.fillRect(w.x, w.y, w.w, w.h); ctx.strokeRect(w.x, w.y, w.w, w.h);
              ctx.fillStyle = '#666'; ctx.font = '10px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
              ctx.fillText('[' + w.text + ']', w.x + w.w / 2, w.y + w.h / 2);
              break;
          }

          // Selection handles
          if (sel) {
            ctx.fillStyle = '#007acc';
            const hSize = 5;
            [[w.x-hSize,w.y-hSize],[w.x+w.w,w.y-hSize],[w.x-hSize,w.y+w.h],[w.x+w.w,w.y+w.h]].forEach(([hx,hy]) => {
              ctx.fillRect(hx, hy, hSize*2, hSize*2);
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
        if (idx < 0) { el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;">Select a widget.</p>'; return; }
        const w = widgets[idx];
        let html = '<div class="field"><label>Name</label><input id="pName" value="' + w.name + '"></div>';
        html += '<div class="field-row"><label style="width:30px">X</label><input type="number" id="pX" value="' + w.x + '" style="width:60px"><label style="width:30px;margin-left:8px">Y</label><input type="number" id="pY" value="' + w.y + '" style="width:60px"></div>';
        html += '<div class="field-row"><label style="width:30px">W</label><input type="number" id="pW" value="' + w.w + '" style="width:60px"><label style="width:30px;margin-left:8px">H</label><input type="number" id="pH" value="' + w.h + '" style="width:60px"></div>';
        html += '<div class="field"><label>Text</label><input id="pText" value="' + w.text + '"></div>';
        html += '<div class="field-row"><label>Color</label><input type="color" id="pColor" value="' + (w.color.startsWith('#') ? w.color : '#333333') + '"></div>';
        html += '<div class="field"><label>Font Size</label><input type="number" id="pFont" value="' + w.fontSize + '" min="8" max="48" style="width:60px"></div>';
        html += '<div class="field"><label>Anchor</label><select id="pAnchor"><option value="topLeft">Top Left</option><option value="topRight">Top Right</option><option value="center">Center</option><option value="bottomLeft">Bottom Left</option></select></div>';
        html += '<div class="field-row"><input type="checkbox" id="pVisible" ' + (w.visible ? 'checked' : '') + '><label>Visible</label></div>';
        if (w.value !== undefined) html += '<div class="field"><label>Value</label><input type="number" id="pVal" value="' + w.value + '" min="0" max="1" step="0.05" style="width:60px"></div>';
        el.innerHTML = html;

        const setAnchor = document.getElementById('pAnchor');
        setAnchor.value = w.anchor;

        const bind = (id, key, parse) => {
          const inp = document.getElementById(id);
          if (inp) inp.addEventListener('input', (e) => { w[key] = parse ? parse(e.target.value) : e.target.value; render(); });
        };
        bind('pName', 'name'); bind('pText', 'text'); bind('pColor', 'color');
        bind('pX', 'x', parseFloat); bind('pY', 'y', parseFloat);
        bind('pW', 'w', parseFloat); bind('pH', 'h', parseFloat);
        bind('pFont', 'fontSize', parseInt);
        bind('pVal', 'value', parseFloat);
        document.getElementById('pAnchor').addEventListener('change', (e) => { w.anchor = e.target.value; });
        document.getElementById('pVisible').addEventListener('change', (e) => { w.visible = e.target.checked; render(); });
        document.getElementById('statusSel').textContent = 'Selected: ' + w.name;
      }

      function refreshHierarchy() {
        const el = document.getElementById('hierarchy');
        el.innerHTML = '';
        widgets.forEach((w, i) => {
          const div = document.createElement('div');
          div.className = 'widget-item' + (i === selectedIdx ? ' sel' : '');
          div.textContent = (w.visible ? '' : '(hidden) ') + w.type + ': ' + w.name;
          div.addEventListener('click', () => { selectedIdx = i; showProps(i); refreshHierarchy(); render(); });
          el.appendChild(div);
        });
        document.getElementById('statusInfo').textContent = 'Widgets: ' + widgets.length;
      }

      function refreshAll() { refreshHierarchy(); showProps(selectedIdx); render(); }

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
          dragWidget.x = Math.round(e.offsetX - dragOff.x);
          dragWidget.y = Math.round(e.offsetY - dragOff.y);
          render();
        }
      });
      canvas.addEventListener('mouseup', () => { if (dragWidget) { showProps(selectedIdx); } dragWidget = null; });

      document.getElementById('addWidget').addEventListener('change', (e) => {
        if (e.target.value) { addWidget(e.target.value); e.target.value = ''; }
      });
      document.getElementById('btnDelete').addEventListener('click', () => {
        if (selectedIdx >= 0) { widgets.splice(selectedIdx, 1); selectedIdx = -1; refreshAll(); }
      });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        for (const w of widgets) {
          lua += '  {\\n    type = "' + w.type + '",\\n    name = "' + w.name + '",\\n';
          lua += '    x = ' + w.x + ', y = ' + w.y + ', w = ' + w.w + ', h = ' + w.h + ',\\n';
          if (w.text) lua += '    text = "' + w.text + '",\\n';
          lua += '    color = "' + w.color + '",\\n    fontSize = ' + w.fontSize + ',\\n';
          lua += '    anchor = "' + w.anchor + '", visible = ' + w.visible + ',\\n';
          if (w.value !== undefined) lua += '    value = ' + w.value + ',\\n';
          lua += '  },\\n';
        }
        lua += '}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      addWidget('Panel'); widgets[0].x = 50; widgets[0].y = 50;
      addWidget('Button'); widgets[1].x = 80; widgets[1].y = 120;
      addWidget('Label'); widgets[2].x = 80; widgets[2].y = 80; widgets[2].text = 'Settings';
      selectedIdx = -1;
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
      refreshAll();
    `);
  }
}
