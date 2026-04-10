import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class SceneFlowEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): SceneFlowEditor {
    return new SceneFlowEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.editor.sceneFlow", "Scene Flow Editor");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "scenes.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Scene Flow Editor", `
      .editor-layout {
        display: grid; grid-template-columns: 1fr 240px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .canvas-area { position: relative; overflow: hidden; }
      .props-panel { grid-row: 2; overflow-y: auto; padding: 8px; background: var(--surface); border-left: 1px solid var(--border); }
      .status-bar { grid-column: 1 / -1; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAdd">+ Add Scene</button>
          <button id="btnConnect">Connect Mode</button>
          <button id="btnDelete" class="danger">Delete Selected</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="canvas-area"><canvas id="flowCanvas"></canvas></div>
        <div class="props-panel">
          <h3>Properties</h3>
          <div id="propsContent" style="margin-top: 8px;">
            <p style="color: var(--text-dim); font-size: 12px;">Select a scene node to edit its properties.</p>
          </div>
        </div>
        <div class="status-bar">
          <span id="statusInfo">Scenes: 0 | Transitions: 0</span>
          <span id="statusMode">Mode: Select</span>
        </div>
      </div>
    `, `
      const canvas = document.getElementById('flowCanvas');
      const ctx = canvas.getContext('2d');
      let nodes = [], edges = [];
      let selectedNode = null, dragNode = null, dragOff = {x:0,y:0};
      let connectMode = false, connectFrom = null;
      let offsetX = 0, offsetY = 0, zoom = 1;
      let isPanning = false, panSX = 0, panSY = 0;
      let nextId = 1;

      const NODE_W = 140, NODE_H = 50;
      const COLORS = ['#264f78','#2d4a22','#4a3222','#3c2244','#443322'];

      function addNode(name, x, y) {
        nodes.push({
          id: nextId++, name: name || 'Scene' + nodes.length,
          x: x || 100 + nodes.length * 30, y: y || 100 + nodes.length * 30,
          onEnter: '', onExit: '', onUpdate: '', onDraw: '',
          color: COLORS[nodes.length % COLORS.length]
        });
        updateStatus(); render();
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight;
        render();
      }

      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.save(); ctx.translate(offsetX, offsetY); ctx.scale(zoom, zoom);

        // Draw edges
        for (const e of edges) {
          const from = nodes.find(n => n.id === e.from);
          const to = nodes.find(n => n.id === e.to);
          if (!from || !to) continue;
          const fx = from.x + NODE_W/2, fy = from.y + NODE_H/2;
          const tx = to.x + NODE_W/2, ty = to.y + NODE_H/2;
          ctx.beginPath(); ctx.moveTo(fx, fy); ctx.lineTo(tx, ty);
          ctx.strokeStyle = '#858585'; ctx.lineWidth = 2; ctx.stroke();
          // Arrow
          const angle = Math.atan2(ty - fy, tx - fx);
          const ax = tx - Math.cos(angle) * (NODE_W/2 + 5);
          const ay = ty - Math.sin(angle) * (NODE_H/2 + 5);
          ctx.beginPath();
          ctx.moveTo(ax, ay);
          ctx.lineTo(ax - 10*Math.cos(angle-0.3), ay - 10*Math.sin(angle-0.3));
          ctx.lineTo(ax - 10*Math.cos(angle+0.3), ay - 10*Math.sin(angle+0.3));
          ctx.closePath(); ctx.fillStyle = '#858585'; ctx.fill();
        }

        // Draw nodes
        for (const n of nodes) {
          ctx.fillStyle = n.color; ctx.strokeStyle = n === selectedNode ? '#007acc' : '#3c3c3c';
          ctx.lineWidth = n === selectedNode ? 2 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.fill(); ctx.stroke();
          ctx.fillStyle = '#ccc'; ctx.font = '13px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
          ctx.fillText(n.name, n.x + NODE_W/2, n.y + NODE_H/2);
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
        if (!node) {
          document.getElementById('propsContent').innerHTML = '<p style="color:var(--text-dim);font-size:12px;">Select a scene node.</p>';
          return;
        }
        document.getElementById('propsContent').innerHTML =
          '<div class="field"><label>Name</label><input id="pName" value="' + node.name + '"></div>' +
          '<div class="field"><label>onEnter</label><input id="pEnter" value="' + node.onEnter + '"></div>' +
          '<div class="field"><label>onExit</label><input id="pExit" value="' + node.onExit + '"></div>' +
          '<div class="field"><label>onUpdate</label><input id="pUpdate" value="' + node.onUpdate + '"></div>' +
          '<div class="field"><label>onDraw</label><input id="pDraw" value="' + node.onDraw + '"></div>';
        ['pName','pEnter','pExit','pUpdate','pDraw'].forEach(id => {
          document.getElementById(id).addEventListener('input', (e) => {
            const map = {pName:'name',pEnter:'onEnter',pExit:'onExit',pUpdate:'onUpdate',pDraw:'onDraw'};
            node[map[id]] = e.target.value;
            if (id === 'pName') render();
          });
        });
      }

      function updateStatus() {
        document.getElementById('statusInfo').textContent = 'Scenes: ' + nodes.length + ' | Transitions: ' + edges.length;
      }

      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) {
          isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY; return;
        }
        const node = hitTest(e.offsetX, e.offsetY);
        if (connectMode && e.button === 0) {
          if (!connectFrom && node) { connectFrom = node; }
          else if (connectFrom && node && node !== connectFrom) {
            if (!edges.find(ed => ed.from === connectFrom.id && ed.to === node.id)) {
              edges.push({ from: connectFrom.id, to: node.id });
            }
            connectFrom = null; updateStatus(); render();
          } else { connectFrom = null; }
          return;
        }
        if (node) {
          selectedNode = node; showProps(node);
          dragNode = node; dragOff = { x: (e.offsetX - offsetX)/zoom - node.x, y: (e.offsetY - offsetY)/zoom - node.y };
        } else { selectedNode = null; showProps(null); }
        render();
      });

      canvas.addEventListener('mousemove', (e) => {
        if (isPanning) { offsetX = e.clientX - panSX; offsetY = e.clientY - panSY; render(); return; }
        if (dragNode) {
          dragNode.x = (e.offsetX - offsetX) / zoom - dragOff.x;
          dragNode.y = (e.offsetY - offsetY) / zoom - dragOff.y;
          render();
        }
      });

      canvas.addEventListener('mouseup', () => { isPanning = false; dragNode = null; });

      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const old = zoom;
        zoom *= e.deltaY < 0 ? 1.1 : 0.9;
        zoom = Math.max(0.2, Math.min(4, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / old;
        offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / old;
        render();
      }, { passive: false });

      document.getElementById('btnAdd').addEventListener('click', () => addNode());
      document.getElementById('btnConnect').addEventListener('click', () => {
        connectMode = !connectMode; connectFrom = null;
        document.getElementById('btnConnect').classList.toggle('active', connectMode);
        document.getElementById('statusMode').textContent = connectMode ? 'Mode: Connect' : 'Mode: Select';
      });
      document.getElementById('btnDelete').addEventListener('click', () => {
        if (!selectedNode) return;
        edges = edges.filter(e => e.from !== selectedNode.id && e.to !== selectedNode.id);
        nodes = nodes.filter(n => n !== selectedNode);
        selectedNode = null; showProps(null); updateStatus(); render();
      });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        for (const n of nodes) {
          lua += '  { name = "' + n.name + '"';
          if (n.onEnter) lua += ', onEnter = ' + n.onEnter;
          if (n.onExit) lua += ', onExit = ' + n.onExit;
          if (n.onUpdate) lua += ', onUpdate = ' + n.onUpdate;
          if (n.onDraw) lua += ', onDraw = ' + n.onDraw;
          const trans = edges.filter(e => e.from === n.id).map(e => {
            const target = nodes.find(nd => nd.id === e.to);
            return target ? '"' + target.name + '"' : '';
          }).filter(Boolean);
          if (trans.length) lua += ', transitions = { ' + trans.join(', ') + ' }';
          lua += ' },\\n';
        }
        lua += '}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      addNode('Title', 80, 80);
      addNode('Gameplay', 300, 80);
      addNode('GameOver', 520, 80);
      edges.push({ from: 1, to: 2 }, { from: 2, to: 3 });
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `);
  }
}
