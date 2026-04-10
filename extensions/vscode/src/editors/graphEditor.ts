import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class GraphEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): GraphEditor {
    return new GraphEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.editor.graph", "Graph / Node Editor");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "graph.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Graph / Node Editor", `
      .editor-layout {
        display: grid; grid-template-columns: 1fr 220px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); padding: 8px; overflow-y: auto; background: var(--surface); }
      .status-bar { grid-column: 1 / -1; }
      .port { width: 10px; height: 10px; border-radius: 50%; border: 1px solid var(--border); display: inline-block; cursor: crosshair; }
      .port.in { background: #4ec9b0; }
      .port.out { background: #ff9800; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAddNode">+ Node</button>
          <button id="btnConnect">Connect</button>
          <button id="btnDelete" class="danger">Delete</button>
          <div class="sep"></div>
          <label>Type:</label>
          <input id="nodeType" value="Process" style="width:80px">
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="canvas-area"><canvas id="graphCanvas"></canvas></div>
        <div class="props-panel">
          <h3>Node Properties</h3>
          <div id="propsContent"><p style="color:var(--text-dim);font-size:12px;">Select a node.</p></div>
          <h3 style="margin-top:12px">Port Editor</h3>
          <div id="portEditor"><p style="color:var(--text-dim);font-size:12px;">Ports are defined per-node.</p></div>
        </div>
        <div class="status-bar">
          <span id="statusInfo">Nodes: 0 | Edges: 0</span>
          <span id="statusMode">Mode: Select</span>
        </div>
      </div>
    `, `
      const canvas = document.getElementById('graphCanvas');
      const ctx = canvas.getContext('2d');
      let nodes = [], edges = [];
      let selectedNode = null, dragNode = null, dragOff = { x: 0, y: 0 };
      let connectMode = false, connectFrom = null, connectPort = -1;
      let offsetX = 0, offsetY = 0, zoom = 1;
      let isPanning = false, panSX = 0, panSY = 0;
      let nextId = 1;
      const NODE_W = 140, NODE_H = 60, PORT_R = 6;

      function addNode(type, x, y) {
        nodes.push({
          id: nextId++, type: type || 'Process',
          x: x || 150 + nodes.length * 40, y: y || 100 + nodes.length * 40,
          label: (type || 'Process') + ' ' + nextId,
          inPorts: ['in'], outPorts: ['out'],
          data: {}
        });
        updateStatus(); render();
      }

      function getPortPos(node, isOut, portIdx) {
        const portCount = isOut ? node.outPorts.length : node.inPorts.length;
        const spacing = NODE_H / (portCount + 1);
        const x = isOut ? node.x + NODE_W : node.x;
        const y = node.y + spacing * (portIdx + 1);
        return { x, y };
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight; render();
      }

      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.save(); ctx.translate(offsetX, offsetY); ctx.scale(zoom, zoom);

        // Edges
        for (const e of edges) {
          const fromNode = nodes.find(n => n.id === e.fromNode);
          const toNode = nodes.find(n => n.id === e.toNode);
          if (!fromNode || !toNode) continue;
          const fp = getPortPos(fromNode, true, e.fromPort);
          const tp = getPortPos(toNode, false, e.toPort);
          ctx.beginPath();
          const cx = (fp.x + tp.x) / 2;
          ctx.moveTo(fp.x, fp.y);
          ctx.bezierCurveTo(cx, fp.y, cx, tp.y, tp.x, tp.y);
          ctx.strokeStyle = '#888'; ctx.lineWidth = 2; ctx.stroke();
        }

        // Nodes
        for (const n of nodes) {
          ctx.fillStyle = '#2d2d2d'; ctx.strokeStyle = n === selectedNode ? '#007acc' : '#3c3c3c';
          ctx.lineWidth = n === selectedNode ? 2 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 5); ctx.fill(); ctx.stroke();
          // Header
          ctx.fillStyle = '#1e3a5f'; ctx.beginPath();
          ctx.roundRect(n.x, n.y, NODE_W, 20, [5, 5, 0, 0]); ctx.fill();
          ctx.fillStyle = '#ccc'; ctx.font = '11px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
          ctx.fillText(n.label, n.x + NODE_W / 2, n.y + 10);
          // Type
          ctx.fillStyle = '#888'; ctx.font = '10px sans-serif';
          ctx.fillText(n.type, n.x + NODE_W / 2, n.y + 38);
          // In ports
          n.inPorts.forEach((p, i) => {
            const pos = getPortPos(n, false, i);
            ctx.fillStyle = '#4ec9b0'; ctx.beginPath(); ctx.arc(pos.x, pos.y, PORT_R, 0, Math.PI * 2); ctx.fill();
            ctx.fillStyle = '#aaa'; ctx.font = '9px sans-serif'; ctx.textAlign = 'left';
            ctx.fillText(p, pos.x + 10, pos.y + 3);
          });
          // Out ports
          n.outPorts.forEach((p, i) => {
            const pos = getPortPos(n, true, i);
            ctx.fillStyle = '#ff9800'; ctx.beginPath(); ctx.arc(pos.x, pos.y, PORT_R, 0, Math.PI * 2); ctx.fill();
            ctx.fillStyle = '#aaa'; ctx.font = '9px sans-serif'; ctx.textAlign = 'right';
            ctx.fillText(p, pos.x - 10, pos.y + 3);
          });
        }
        ctx.restore();
      }

      function hitNode(sx, sy) {
        const wx = (sx - offsetX) / zoom, wy = (sy - offsetY) / zoom;
        for (let i = nodes.length - 1; i >= 0; i--) {
          const n = nodes[i];
          if (wx >= n.x && wx <= n.x + NODE_W && wy >= n.y && wy <= n.y + NODE_H) return n;
        }
        return null;
      }

      function hitPort(sx, sy) {
        const wx = (sx - offsetX) / zoom, wy = (sy - offsetY) / zoom;
        for (const n of nodes) {
          for (let i = 0; i < n.outPorts.length; i++) {
            const p = getPortPos(n, true, i);
            if (Math.hypot(wx - p.x, wy - p.y) < PORT_R * 2) return { node: n, isOut: true, port: i };
          }
          for (let i = 0; i < n.inPorts.length; i++) {
            const p = getPortPos(n, false, i);
            if (Math.hypot(wx - p.x, wy - p.y) < PORT_R * 2) return { node: n, isOut: false, port: i };
          }
        }
        return null;
      }

      function showProps(node) {
        const el = document.getElementById('propsContent');
        const pe = document.getElementById('portEditor');
        if (!node) { el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;">Select a node.</p>'; pe.innerHTML = ''; return; }
        el.innerHTML =
          '<div class="field"><label>Label</label><input id="pLabel" value="' + node.label + '"></div>' +
          '<div class="field"><label>Type</label><input id="pType" value="' + node.type + '"></div>';
        document.getElementById('pLabel').addEventListener('input', (e) => { node.label = e.target.value; render(); });
        document.getElementById('pType').addEventListener('input', (e) => { node.type = e.target.value; render(); });

        pe.innerHTML = '<div class="field"><label>In Ports</label><input id="pInPorts" value="' + node.inPorts.join(', ') + '"></div>' +
          '<div class="field"><label>Out Ports</label><input id="pOutPorts" value="' + node.outPorts.join(', ') + '"></div>';
        document.getElementById('pInPorts').addEventListener('change', (e) => {
          node.inPorts = e.target.value.split(',').map(s => s.trim()).filter(Boolean);
          edges = edges.filter(ed => !(ed.toNode === node.id && ed.toPort >= node.inPorts.length));
          render();
        });
        document.getElementById('pOutPorts').addEventListener('change', (e) => {
          node.outPorts = e.target.value.split(',').map(s => s.trim()).filter(Boolean);
          edges = edges.filter(ed => !(ed.fromNode === node.id && ed.fromPort >= node.outPorts.length));
          render();
        });
      }

      function updateStatus() {
        document.getElementById('statusInfo').textContent = 'Nodes: ' + nodes.length + ' | Edges: ' + edges.length;
      }

      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) { isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY; return; }

        if (connectMode) {
          const port = hitPort(e.offsetX, e.offsetY);
          if (port && port.isOut && !connectFrom) {
            connectFrom = port.node; connectPort = port.port;
          } else if (port && !port.isOut && connectFrom) {
            edges.push({ fromNode: connectFrom.id, fromPort: connectPort, toNode: port.node.id, toPort: port.port });
            connectFrom = null; updateStatus(); render();
          } else { connectFrom = null; }
          return;
        }

        const node = hitNode(e.offsetX, e.offsetY);
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
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / old; offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / old; render();
      }, { passive: false });

      document.getElementById('btnAddNode').addEventListener('click', () => {
        addNode(document.getElementById('nodeType').value);
      });
      document.getElementById('btnConnect').addEventListener('click', () => {
        connectMode = !connectMode; connectFrom = null;
        document.getElementById('btnConnect').classList.toggle('active', connectMode);
        document.getElementById('statusMode').textContent = connectMode ? 'Mode: Connect' : 'Mode: Select';
      });
      document.getElementById('btnDelete').addEventListener('click', () => {
        if (!selectedNode) return;
        edges = edges.filter(e => e.fromNode !== selectedNode.id && e.toNode !== selectedNode.id);
        nodes = nodes.filter(n => n !== selectedNode);
        selectedNode = null; showProps(null); updateStatus(); render();
      });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  nodes = {\\n';
        for (const n of nodes) {
          lua += '    { id = ' + n.id + ', type = "' + n.type + '", label = "' + n.label + '"';
          lua += ', inPorts = { "' + n.inPorts.join('", "') + '" }';
          lua += ', outPorts = { "' + n.outPorts.join('", "') + '" }';
          lua += ' },\\n';
        }
        lua += '  },\\n  edges = {\\n';
        for (const e of edges) {
          lua += '    { from = ' + e.fromNode + ', fromPort = ' + (e.fromPort + 1) + ', to = ' + e.toNode + ', toPort = ' + (e.toPort + 1) + ' },\\n';
        }
        lua += '  }\\n}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      addNode('Input', 80, 100); nodes[0].outPorts = ['data', 'signal'];
      addNode('Process', 300, 80); nodes[1].inPorts = ['data']; nodes[1].outPorts = ['result'];
      addNode('Output', 520, 100); nodes[2].inPorts = ['result']; nodes[2].outPorts = [];
      edges.push({ fromNode: 1, fromPort: 0, toNode: 2, toPort: 0 });
      edges.push({ fromNode: 2, fromPort: 0, toNode: 3, toPort: 0 });
      selectedNode = null; showProps(null);
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `);
  }
}
