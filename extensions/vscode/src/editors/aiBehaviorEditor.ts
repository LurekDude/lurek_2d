import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class AiBehaviorEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): AiBehaviorEditor {
    return new AiBehaviorEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.editor.aiBehavior", "AI Behavior Tree");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "behavior_tree.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "AI Behavior Tree", `
      .editor-layout {
        display: grid; grid-template-columns: 200px 1fr 220px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .palette-panel { grid-row: 2; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); padding: 8px; overflow-y: auto; background: var(--surface); }
      .status-bar { grid-column: 1 / -1; }
      .node-group { margin-bottom: 10px; }
      .node-group h4 { font-size: 11px; color: var(--text-dim); margin-bottom: 4px; text-transform: uppercase; }
      .drag-node {
        padding: 4px 8px; font-size: 12px; cursor: grab; border-radius: 3px;
        margin-bottom: 2px; border: 1px solid var(--border);
      }
      .drag-node:hover { border-color: var(--accent); }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnClear" class="danger">Clear Tree</button>
          <div class="sep"></div>
          <button id="btnSimulate">Simulate</button>
          <button id="btnReset">Reset Status</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="panel palette-panel">
          <h3>Node Palette</h3>
          <div class="node-group">
            <h4>Composites</h4>
            <div class="drag-node" data-type="Sequence" style="background:#2a3a2a">&#9654; Sequence</div>
            <div class="drag-node" data-type="Selector" style="background:#3a3a2a">&#9654; Selector</div>
            <div class="drag-node" data-type="Parallel" style="background:#2a2a3a">&#9654; Parallel</div>
            <div class="drag-node" data-type="RandomSelector" style="background:#3a2a3a">&#9654; RandomSelector</div>
          </div>
          <div class="node-group">
            <h4>Decorators</h4>
            <div class="drag-node" data-type="Inverter" style="background:#3a2a2a">&#8635; Inverter</div>
            <div class="drag-node" data-type="Repeater" style="background:#3a2a2a">&#8635; Repeater</div>
            <div class="drag-node" data-type="Succeeder" style="background:#3a2a2a">&#8635; Succeeder</div>
            <div class="drag-node" data-type="Cooldown" style="background:#3a2a2a">&#8635; Cooldown</div>
            <div class="drag-node" data-type="Guard" style="background:#3a2a2a">&#8635; Guard</div>
          </div>
          <div class="node-group">
            <h4>Conditions</h4>
            <div class="drag-node" data-type="HasTarget" style="background:#2a2a3e">&#10003; HasTarget</div>
            <div class="drag-node" data-type="InRange" style="background:#2a2a3e">&#10003; InRange</div>
            <div class="drag-node" data-type="HealthCheck" style="background:#2a2a3e">&#10003; HealthCheck</div>
            <div class="drag-node" data-type="Custom" style="background:#2a2a3e">&#10003; Custom</div>
          </div>
          <div class="node-group">
            <h4>Actions</h4>
            <div class="drag-node" data-type="MoveTo" style="background:#2a3e2a">&#9733; MoveTo</div>
            <div class="drag-node" data-type="Attack" style="background:#2a3e2a">&#9733; Attack</div>
            <div class="drag-node" data-type="Flee" style="background:#2a3e2a">&#9733; Flee</div>
            <div class="drag-node" data-type="Patrol" style="background:#2a3e2a">&#9733; Patrol</div>
          </div>
        </div>
        <div class="canvas-area"><canvas id="btCanvas"></canvas></div>
        <div class="props-panel">
          <h3>Node Properties</h3>
          <div id="propsContent"><p style="color:var(--text-dim);font-size:12px;">Click palette to add nodes, drag on canvas to move.</p></div>
        </div>
        <div class="status-bar">
          <span id="statusInfo">Nodes: 0</span>
          <span id="statusSim">Simulation: Idle</span>
        </div>
      </div>
    `, `
      const canvas = document.getElementById('btCanvas');
      const ctx = canvas.getContext('2d');
      let nodes = [], selectedNode = null, dragNode = null, dragOff = { x: 0, y: 0 };
      let offsetX = 0, offsetY = 0, zoom = 1;
      let isPanning = false, panSX = 0, panSY = 0;
      let nextId = 1;
      const NODE_W = 120, NODE_H = 40;

      const CATEGORIES = {
        Sequence: 'composite', Selector: 'composite', Parallel: 'composite', RandomSelector: 'composite',
        Inverter: 'decorator', Repeater: 'decorator', Succeeder: 'decorator', Cooldown: 'decorator', Guard: 'decorator',
        HasTarget: 'condition', InRange: 'condition', HealthCheck: 'condition', Custom: 'condition',
        MoveTo: 'action', Attack: 'action', Flee: 'action', Patrol: 'action'
      };
      const CAT_COLORS = { composite: '#2a4a2a', decorator: '#4a2a2a', condition: '#2a2a4a', action: '#2a4a3a' };
      const STATUS_COLORS = { success: '#4caf50', failure: '#f44336', running: '#ff9800', idle: '#666' };

      function addNode(type, x, y) {
        const node = {
          id: nextId++, type, category: CATEGORIES[type] || 'action',
          x: x || canvas.width / 2 - NODE_W / 2, y: y || 60 + nodes.length * 60,
          parentId: null, status: 'idle', params: {}
        };
        if (type === 'Cooldown') node.params.duration = 2.0;
        if (type === 'Repeater') node.params.times = 3;
        if (type === 'InRange') node.params.range = 100;
        if (type === 'HealthCheck') node.params.threshold = 0.3;
        if (type === 'Custom') node.params.func = 'myCondition';
        nodes.push(node);
        // Auto-parent to selected
        if (selectedNode && (selectedNode.category === 'composite' || selectedNode.category === 'decorator')) {
          node.parentId = selectedNode.id;
          layoutTree();
        }
        selectedNode = node; showProps(node);
        updateStatus(); render();
      }

      function getChildren(parentId) {
        return nodes.filter(n => n.parentId === parentId);
      }

      function layoutTree() {
        const roots = nodes.filter(n => !n.parentId);
        let startX = 60;
        for (const root of roots) {
          startX = layoutSubtree(root, startX, 40);
          startX += 40;
        }
      }

      function layoutSubtree(node, startX, y) {
        const children = getChildren(node.id);
        node.y = y;
        if (children.length === 0) { node.x = startX; return startX + NODE_W + 20; }
        let x = startX;
        for (const child of children) { x = layoutSubtree(child, x, y + 80); }
        node.x = (startX + x - NODE_W - 20) / 2;
        return x;
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight; render();
      }

      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.save(); ctx.translate(offsetX, offsetY); ctx.scale(zoom, zoom);

        // Draw edges
        for (const n of nodes) {
          if (!n.parentId) continue;
          const parent = nodes.find(p => p.id === n.parentId);
          if (!parent) continue;
          ctx.beginPath();
          ctx.moveTo(parent.x + NODE_W / 2, parent.y + NODE_H);
          ctx.lineTo(n.x + NODE_W / 2, n.y);
          ctx.strokeStyle = '#555'; ctx.lineWidth = 1.5; ctx.stroke();
        }

        // Draw nodes
        for (const n of nodes) {
          ctx.fillStyle = CAT_COLORS[n.category] || '#333';
          ctx.strokeStyle = n === selectedNode ? '#007acc' : '#3c3c3c';
          ctx.lineWidth = n === selectedNode ? 2 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 5); ctx.fill(); ctx.stroke();
          // Status indicator
          ctx.fillStyle = STATUS_COLORS[n.status];
          ctx.beginPath(); ctx.arc(n.x + 12, n.y + NODE_H / 2, 5, 0, Math.PI * 2); ctx.fill();
          // Label
          ctx.fillStyle = '#ccc'; ctx.font = '11px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'middle';
          ctx.fillText(n.type, n.x + 22, n.y + NODE_H / 2);
        }
        ctx.restore();
      }

      function hitTest(sx, sy) {
        const wx = (sx - offsetX) / zoom, wy = (sy - offsetY) / zoom;
        for (let i = nodes.length - 1; i >= 0; i--) {
          const n = nodes[i];
          if (wx >= n.x && wx <= n.x + NODE_W && wy >= n.y && wy <= n.y + NODE_H) return n;
        }
        return null;
      }

      function showProps(node) {
        const el = document.getElementById('propsContent');
        if (!node) { el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;">Select a node.</p>'; return; }
        let html = '<div class="field"><label>Type</label><span style="font-size:12px;color:var(--accent-2)">' + node.type + '</span></div>';
        html += '<div class="field"><label>Category</label><span style="font-size:12px">' + node.category + '</span></div>';
        html += '<div class="field"><label>Parent</label><select id="pParent"><option value="">Root</option>';
        for (const n of nodes) {
          if (n.id === node.id) continue;
          if (n.category === 'composite' || n.category === 'decorator') {
            html += '<option value="' + n.id + '" ' + (node.parentId === n.id ? 'selected' : '') + '>' + n.type + ' #' + n.id + '</option>';
          }
        }
        html += '</select></div>';
        for (const [k, v] of Object.entries(node.params)) {
          html += '<div class="field"><label>' + k + '</label><input id="pp_' + k + '" value="' + v + '" ' + (typeof v === 'number' ? 'type="number" step="0.1"' : '') + '></div>';
        }
        el.innerHTML = html;
        document.getElementById('pParent').addEventListener('change', (e) => {
          node.parentId = e.target.value ? parseInt(e.target.value) : null;
          layoutTree(); render();
        });
        for (const k of Object.keys(node.params)) {
          const inp = document.getElementById('pp_' + k);
          if (inp) inp.addEventListener('input', (e) => {
            node.params[k] = typeof node.params[k] === 'number' ? parseFloat(e.target.value) || 0 : e.target.value;
          });
        }
      }

      function updateStatus() {
        document.getElementById('statusInfo').textContent = 'Nodes: ' + nodes.length;
      }

      // Palette click
      document.querySelectorAll('.drag-node').forEach(el => {
        el.addEventListener('click', () => addNode(el.dataset.type));
      });

      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) { isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY; return; }
        const node = hitTest(e.offsetX, e.offsetY);
        if (node) {
          selectedNode = node; showProps(node);
          dragNode = node; dragOff = { x: (e.offsetX - offsetX) / zoom - node.x, y: (e.offsetY - offsetY) / zoom - node.y };
        } else { selectedNode = null; showProps(null); }
        render();
      });
      canvas.addEventListener('mousemove', (e) => {
        if (isPanning) { offsetX = e.clientX - panSX; offsetY = e.clientY - panSY; render(); return; }
        if (dragNode) { dragNode.x = (e.offsetX - offsetX) / zoom - dragOff.x; dragNode.y = (e.offsetY - offsetY) / zoom - dragOff.y; render(); }
      });
      canvas.addEventListener('mouseup', () => { isPanning = false; dragNode = null; });
      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const old = zoom; zoom *= e.deltaY < 0 ? 1.1 : 0.9; zoom = Math.max(0.2, Math.min(4, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / old;
        offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / old; render();
      }, { passive: false });

      // Simulate
      document.getElementById('btnSimulate').addEventListener('click', () => {
        const statuses = ['success', 'failure', 'running'];
        for (const n of nodes) n.status = statuses[Math.floor(Math.random() * statuses.length)];
        document.getElementById('statusSim').textContent = 'Simulation: Running';
        render();
      });
      document.getElementById('btnReset').addEventListener('click', () => {
        for (const n of nodes) n.status = 'idle';
        document.getElementById('statusSim').textContent = 'Simulation: Idle';
        render();
      });
      document.getElementById('btnClear').addEventListener('click', () => {
        nodes = []; selectedNode = null; showProps(null); updateStatus(); render();
      });

      document.getElementById('btnExport').addEventListener('click', () => {
        function exportNode(node) {
          let lua = '{ type = "' + node.type + '"';
          for (const [k, v] of Object.entries(node.params)) {
            if (typeof v === 'string') lua += ', ' + k + ' = "' + v + '"';
            else lua += ', ' + k + ' = ' + v;
          }
          const children = getChildren(node.id);
          if (children.length) {
            lua += ', children = {\\n';
            for (const c of children) lua += '    ' + exportNode(c) + ',\\n';
            lua += '  }';
          }
          lua += ' }';
          return lua;
        }
        const roots = nodes.filter(n => !n.parentId);
        let lua = 'return {\\n';
        for (const r of roots) lua += '  ' + exportNode(r) + ',\\n';
        lua += '}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      // Default tree
      addNode('Selector', 300, 40); nodes[0].parentId = null;
      addNode('Sequence', 150, 120); nodes[1].parentId = 1;
      addNode('HasTarget', 100, 200); nodes[2].parentId = 2;
      addNode('Attack', 220, 200); nodes[3].parentId = 2;
      addNode('Patrol', 400, 120); nodes[4].parentId = 1;
      selectedNode = null; showProps(null);
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `);
  }
}
