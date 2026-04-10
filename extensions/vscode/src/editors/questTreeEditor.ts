import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class QuestTreeEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): QuestTreeEditor {
    return new QuestTreeEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.editor.questTree", "Quest / Tech Tree Editor");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "quests.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Quest / Tech Tree Editor", `
      .editor-layout {
        display: grid; grid-template-columns: 1fr 240px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); padding: 8px; overflow-y: auto; background: var(--surface); }
      .status-bar { grid-column: 1 / -1; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAdd">+ Quest</button>
          <button id="btnConnect">Link Prerequisites</button>
          <button id="btnDelete" class="danger">Delete</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="canvas-area"><canvas id="questCanvas"></canvas></div>
        <div class="props-panel">
          <h3>Quest Properties</h3>
          <div id="propsContent"><p style="color:var(--text-dim);font-size:12px;">Select a quest node.</p></div>
        </div>
        <div class="status-bar">
          <span id="statusInfo">Quests: 0</span>
          <span id="statusMode">Mode: Select</span>
        </div>
      </div>
    `, `
      const canvas = document.getElementById('questCanvas');
      const ctx = canvas.getContext('2d');
      let nodes = [], edges = [];
      let selectedNode = null, dragNode = null, dragOff = { x: 0, y: 0 };
      let connectMode = false, connectFrom = null;
      let offsetX = 0, offsetY = 0, zoom = 1;
      let isPanning = false, panSX = 0, panSY = 0;
      let nextId = 1;
      const NODE_W = 150, NODE_H = 55;

      const STATUS_COLORS = {
        available: '#2a5a2a', locked: '#3a3a3a', completed: '#5a4a1a'
      };

      function addNode(name, x, y) {
        nodes.push({
          id: nextId++, name: name || 'Quest ' + nodes.length,
          x: x || 100 + nodes.length * 30, y: y || 100 + nodes.length * 50,
          description: '', requiredItems: '', reward: '', status: 'available'
        });
        updateStatus(); render();
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight; render();
      }

      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.save(); ctx.translate(offsetX, offsetY); ctx.scale(zoom, zoom);

        for (const e of edges) {
          const from = nodes.find(n => n.id === e.from);
          const to = nodes.find(n => n.id === e.to);
          if (!from || !to) continue;
          ctx.beginPath();
          ctx.moveTo(from.x + NODE_W / 2, from.y + NODE_H);
          ctx.lineTo(to.x + NODE_W / 2, to.y);
          ctx.strokeStyle = '#555'; ctx.lineWidth = 2; ctx.setLineDash([4, 4]); ctx.stroke(); ctx.setLineDash([]);
          const mx = (from.x + to.x + NODE_W) / 2, my = (from.y + NODE_H + to.y) / 2;
          ctx.fillStyle = '#555'; ctx.beginPath();
          ctx.moveTo(to.x + NODE_W / 2, to.y);
          ctx.lineTo(to.x + NODE_W / 2 - 5, to.y - 8);
          ctx.lineTo(to.x + NODE_W / 2 + 5, to.y - 8);
          ctx.closePath(); ctx.fill();
        }

        for (const n of nodes) {
          ctx.fillStyle = STATUS_COLORS[n.status] || STATUS_COLORS.available;
          ctx.strokeStyle = n === selectedNode ? '#007acc' : '#3c3c3c';
          ctx.lineWidth = n === selectedNode ? 2.5 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.fill(); ctx.stroke();
          // Status dot
          const dotColor = n.status === 'completed' ? '#ffd700' : n.status === 'available' ? '#4caf50' : '#666';
          ctx.fillStyle = dotColor; ctx.beginPath(); ctx.arc(n.x + 12, n.y + 14, 4, 0, Math.PI * 2); ctx.fill();
          // Name
          ctx.fillStyle = '#ccc'; ctx.font = '12px sans-serif'; ctx.textAlign = 'left';
          ctx.fillText(n.name, n.x + 22, n.y + 18);
          // Description preview
          if (n.description) {
            ctx.fillStyle = '#888'; ctx.font = '10px sans-serif';
            ctx.fillText(n.description.substring(0, 20), n.x + 8, n.y + 38);
          }
          if (n.reward) {
            ctx.fillStyle = '#ffd700'; ctx.font = '10px sans-serif';
            ctx.fillText('\\u2605 ' + n.reward, n.x + 8, n.y + 50);
          }
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
        if (!node) { el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;">Select a quest node.</p>'; return; }
        el.innerHTML =
          '<div class="field"><label>Name</label><input id="pName" value="' + node.name + '"></div>' +
          '<div class="field"><label>Description</label><textarea id="pDesc" rows="2" style="width:100%;resize:vertical">' + node.description + '</textarea></div>' +
          '<div class="field"><label>Required Items</label><input id="pItems" value="' + node.requiredItems + '" placeholder="key, sword"></div>' +
          '<div class="field"><label>Reward</label><input id="pReward" value="' + node.reward + '" placeholder="100 gold"></div>' +
          '<div class="field"><label>Status</label><select id="pStatus"><option value="available" ' + (node.status === 'available' ? 'selected' : '') + '>Available</option><option value="locked" ' + (node.status === 'locked' ? 'selected' : '') + '>Locked</option><option value="completed" ' + (node.status === 'completed' ? 'selected' : '') + '>Completed</option></select></div>' +
          '<div class="field" style="margin-top:8px"><label>Prerequisites</label><div id="prereqList" style="font-size:11px;color:var(--text-dim)"></div></div>';

        const prereqs = edges.filter(e => e.to === node.id).map(e => nodes.find(n => n.id === e.from)).filter(Boolean);
        document.getElementById('prereqList').textContent = prereqs.length ? prereqs.map(p => p.name).join(', ') : 'None';

        const bind = (id, key) => {
          const inp = document.getElementById(id);
          if (inp) inp.addEventListener('input', (e) => { node[key] = e.target.value; render(); });
        };
        bind('pName', 'name'); bind('pDesc', 'description'); bind('pItems', 'requiredItems'); bind('pReward', 'reward');
        document.getElementById('pStatus').addEventListener('change', (e) => { node.status = e.target.value; render(); });
      }

      function updateStatus() {
        document.getElementById('statusInfo').textContent = 'Quests: ' + nodes.length + ' | Links: ' + edges.length;
      }

      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) { isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY; return; }
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

      document.getElementById('btnAdd').addEventListener('click', () => addNode());
      document.getElementById('btnConnect').addEventListener('click', () => {
        connectMode = !connectMode; connectFrom = null;
        document.getElementById('btnConnect').classList.toggle('active', connectMode);
        document.getElementById('statusMode').textContent = connectMode ? 'Mode: Link' : 'Mode: Select';
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
          lua += '  {\\n    id = ' + n.id + ',\\n    name = "' + n.name + '",\\n';
          if (n.description) lua += '    description = "' + n.description + '",\\n';
          if (n.requiredItems) lua += '    requiredItems = { "' + n.requiredItems.split(',').map(s => s.trim()).join('", "') + '" },\\n';
          if (n.reward) lua += '    reward = "' + n.reward + '",\\n';
          const prereqs = edges.filter(e => e.to === n.id).map(e => e.from);
          if (prereqs.length) lua += '    prerequisites = { ' + prereqs.join(', ') + ' },\\n';
          lua += '    status = "' + n.status + '"\\n  },\\n';
        }
        lua += '}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      addNode('Find the Key', 80, 50); nodes[0].description = 'Locate the dungeon key'; nodes[0].reward = '50 gold';
      addNode('Enter Dungeon', 80, 160); nodes[1].description = 'Enter the dark dungeon'; nodes[1].status = 'locked';
      addNode('Defeat Boss', 80, 270); nodes[2].description = 'Defeat the dragon'; nodes[2].reward = 'Dragon Sword'; nodes[2].status = 'locked';
      edges.push({ from: 1, to: 2 }, { from: 2, to: 3 });
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `);
  }
}
