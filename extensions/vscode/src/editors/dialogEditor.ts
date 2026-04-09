import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class DialogEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): DialogEditor {
    return new DialogEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "luna.editor.dialog", "Dialog Editor");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "dialog.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Dialog Editor", `
      .editor-layout {
        display: grid; grid-template-columns: 1fr 260px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); padding: 8px; overflow-y: auto; background: var(--surface); }
      .status-bar { grid-column: 1 / -1; }
      .choice-item { display: flex; gap: 4px; margin-bottom: 3px; }
      .choice-item input { flex: 1; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAddNpc">+ NPC Node</button>
          <button id="btnAddChoice">+ Choice Node</button>
          <button id="btnAddCondition">+ Condition</button>
          <button id="btnAddAction">+ Action</button>
          <div class="sep"></div>
          <button id="btnConnect">Connect Mode</button>
          <button id="btnDelete" class="danger">Delete</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>
        <div class="canvas-area"><canvas id="dialogCanvas"></canvas></div>
        <div class="props-panel">
          <h3>Properties</h3>
          <div id="propsContent"><p style="color:var(--text-dim);font-size:12px;">Select a node to edit.</p></div>
        </div>
        <div class="status-bar">
          <span id="statusInfo">Nodes: 0 | Connections: 0</span>
          <span id="statusMode">Mode: Select</span>
        </div>
      </div>
    `, `
      const canvas = document.getElementById('dialogCanvas');
      const ctx = canvas.getContext('2d');
      let nodes = [], edges = [];
      let selectedNode = null, dragNode = null, dragOff = { x: 0, y: 0 };
      let connectMode = false, connectFrom = null;
      let offsetX = 0, offsetY = 0, zoom = 1;
      let isPanning = false, panSX = 0, panSY = 0;
      let nextId = 1;
      const NODE_W = 160, NODE_H = 60;

      const NODE_TYPES = {
        npc: { color: '#1e3a5f', label: 'NPC' },
        choice: { color: '#1e4a2e', label: 'Choice' },
        condition: { color: '#4a3e1e', label: 'Condition' },
        action: { color: '#4a2e1e', label: 'Action' }
      };

      function addNode(type, x, y) {
        nodes.push({
          id: nextId++, type, x: x || 100 + nodes.length * 40, y: y || 100 + nodes.length * 40,
          speaker: type === 'npc' ? 'NPC' : '', text: '', choices: type === 'choice' ? ['Yes', 'No'] : [],
          condition: type === 'condition' ? 'has_item("key")' : '',
          action: type === 'action' ? 'give_item("reward")' : ''
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

        // Edges
        for (const e of edges) {
          const from = nodes.find(n => n.id === e.from);
          const to = nodes.find(n => n.id === e.to);
          if (!from || !to) continue;
          const fx = from.x + NODE_W / 2, fy = from.y + NODE_H;
          const tx = to.x + NODE_W / 2, ty = to.y;
          ctx.beginPath(); ctx.moveTo(fx, fy);
          ctx.bezierCurveTo(fx, fy + 40, tx, ty - 40, tx, ty);
          ctx.strokeStyle = e.label ? '#4ec9b0' : '#666'; ctx.lineWidth = 2; ctx.stroke();
          // Arrow
          const angle = Math.atan2(ty - (ty - 40), tx - tx) || -Math.PI / 2;
          ctx.beginPath(); ctx.moveTo(tx, ty);
          ctx.lineTo(tx - 6, ty - 10); ctx.lineTo(tx + 6, ty - 10); ctx.closePath();
          ctx.fillStyle = e.label ? '#4ec9b0' : '#666'; ctx.fill();
          if (e.label) {
            ctx.fillStyle = '#ccc'; ctx.font = '10px sans-serif'; ctx.textAlign = 'center';
            ctx.fillText(e.label, (fx + tx) / 2, (fy + ty) / 2);
          }
        }

        // Nodes
        for (const n of nodes) {
          const nt = NODE_TYPES[n.type];
          ctx.fillStyle = nt.color;
          ctx.strokeStyle = n === selectedNode ? '#007acc' : '#3c3c3c';
          ctx.lineWidth = n === selectedNode ? 2 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.fill(); ctx.stroke();
          // Type badge
          ctx.fillStyle = 'rgba(255,255,255,0.15)';
          ctx.fillRect(n.x, n.y, NODE_W, 18);
          ctx.fillStyle = '#ccc'; ctx.font = 'bold 10px sans-serif'; ctx.textAlign = 'left';
          ctx.fillText(nt.label + (n.speaker ? ': ' + n.speaker : ''), n.x + 6, n.y + 13);
          // Text preview
          ctx.fillStyle = '#aaa'; ctx.font = '11px sans-serif'; ctx.textAlign = 'center';
          const preview = n.text ? n.text.substring(0, 22) : (n.condition || n.action || '...');
          ctx.fillText(preview, n.x + NODE_W / 2, n.y + 40);
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
        let html = '<div class="field"><label>Type</label><span style="font-size:12px;color:var(--accent-2)">' + NODE_TYPES[node.type].label + '</span></div>';
        if (node.type === 'npc' || node.type === 'choice') {
          html += '<div class="field"><label>Speaker</label><input id="pSpeaker" value="' + node.speaker + '"></div>';
          html += '<div class="field"><label>Text</label><textarea id="pText" rows="3" style="width:100%;resize:vertical">' + node.text + '</textarea></div>';
        }
        if (node.type === 'choice') {
          html += '<div class="field"><label>Choices</label><div id="choiceList">';
          node.choices.forEach((c, i) => {
            html += '<div class="choice-item"><input value="' + c + '" data-ci="' + i + '"><button data-delc="' + i + '">x</button></div>';
          });
          html += '</div><button id="btnAddChoiceItem" style="width:100%;margin-top:4px;font-size:11px;">+ Add Choice</button></div>';
        }
        if (node.type === 'condition') {
          html += '<div class="field"><label>Condition</label><input id="pCondition" value="' + node.condition + '"></div>';
        }
        if (node.type === 'action') {
          html += '<div class="field"><label>Action</label><input id="pAction" value="' + node.action + '"></div>';
        }
        el.innerHTML = html;

        const bind = (id, key) => { const e = document.getElementById(id); if (e) e.addEventListener('input', (ev) => { node[key] = ev.target.value; render(); }); };
        bind('pSpeaker', 'speaker'); bind('pText', 'text'); bind('pCondition', 'condition'); bind('pAction', 'action');
        el.querySelectorAll('[data-ci]').forEach(inp => {
          inp.addEventListener('input', (ev) => { node.choices[parseInt(ev.target.dataset.ci)] = ev.target.value; });
        });
        el.querySelectorAll('[data-delc]').forEach(btn => {
          btn.addEventListener('click', (ev) => { node.choices.splice(parseInt(ev.target.dataset.delc), 1); showProps(node); });
        });
        const addBtn = document.getElementById('btnAddChoiceItem');
        if (addBtn) addBtn.addEventListener('click', () => { node.choices.push('Option'); showProps(node); });
      }

      function updateStatus() {
        document.getElementById('statusInfo').textContent = 'Nodes: ' + nodes.length + ' | Connections: ' + edges.length;
      }

      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) { isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY; return; }
        const node = hitTest(e.offsetX, e.offsetY);
        if (connectMode && e.button === 0) {
          if (!connectFrom && node) { connectFrom = node; }
          else if (connectFrom && node && node !== connectFrom) {
            const label = connectFrom.type === 'choice' && connectFrom.choices.length > 0 ? connectFrom.choices[edges.filter(ed => ed.from === connectFrom.id).length] || '' : '';
            edges.push({ from: connectFrom.id, to: node.id, label });
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

      document.getElementById('btnAddNpc').addEventListener('click', () => addNode('npc'));
      document.getElementById('btnAddChoice').addEventListener('click', () => addNode('choice'));
      document.getElementById('btnAddCondition').addEventListener('click', () => addNode('condition'));
      document.getElementById('btnAddAction').addEventListener('click', () => addNode('action'));
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
          lua += '  { id = ' + n.id + ', type = "' + n.type + '"';
          if (n.speaker) lua += ', speaker = "' + n.speaker + '"';
          if (n.text) lua += ', text = "' + n.text + '"';
          if (n.choices.length) lua += ', choices = { "' + n.choices.join('", "') + '" }';
          if (n.condition) lua += ', condition = "' + n.condition + '"';
          if (n.action) lua += ', action = "' + n.action + '"';
          const conns = edges.filter(e => e.from === n.id).map(e => e.to);
          if (conns.length) lua += ', next = { ' + conns.join(', ') + ' }';
          lua += ' },\\n';
        }
        lua += '}\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      addNode('npc', 100, 50); nodes[0].speaker = 'Guard'; nodes[0].text = 'Halt! Who goes there?';
      addNode('choice', 100, 180); nodes[1].text = 'Response'; nodes[1].choices = ['I am a friend', 'None of your business'];
      addNode('npc', 50, 310); nodes[2].speaker = 'Guard'; nodes[2].text = 'Welcome, friend.';
      addNode('action', 250, 310); nodes[3].action = 'start_combat()';
      edges.push({ from: 1, to: 2, label: '' }, { from: 2, to: 3, label: 'Friend' }, { from: 2, to: 4, label: 'Hostile' });
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `);
  }
}
