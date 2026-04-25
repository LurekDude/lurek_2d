import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

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
        display: grid; grid-template-columns: 1fr 260px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: var(--bg); }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); overflow-y: auto; background: var(--surface); }

      .prop-field { margin-bottom: 6px; }
      .prop-field label { display: block; font-size: 10px; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.3px; margin-bottom: 2px; }
      .prop-field input, .prop-field select, .prop-field textarea {
        width: 100%; box-sizing: border-box;
      }
      .prop-field textarea { resize: vertical; min-height: 36px; }

      .prereq-list { font-size: 11px; color: var(--text-dim); }
      .prereq-item { display: flex; align-items: center; gap: 4px; margin-bottom: 2px; }
      .prereq-dot { width: 6px; height: 6px; border-radius: 50%; background: var(--accent); flex-shrink: 0; }

      .mode-badge {
        display: inline-flex; align-items: center; gap: 4px;
        padding: 1px 8px; border-radius: 9px; font-size: 10px; font-weight: 600;
      }
      .mode-badge.select { background: var(--surface-2); color: var(--text-dim); }
      .mode-badge.link { background: var(--warning); color: var(--bg); }
    `, `
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            ${iconButton('add', { id: 'btnAdd', title: 'Add Quest (A)' })}
            ${iconButton('link', { id: 'btnConnect', title: 'Link Prerequisites (C)' })}
            ${iconButton('trash', { id: 'btnDelete', title: 'Delete (Del)', cls: 'danger' })}
          </div>
          ${toolbarSep()}
          <div class="group">
            ${iconButton('undo', { id: 'btnUndo', title: 'Undo (Ctrl+Z)' })}
            ${iconButton('redo', { id: 'btnRedo', title: 'Redo (Ctrl+Y)' })}
          </div>
          ${toolbarSep()}
          <div class="group">
            ${iconButton('layout', { id: 'btnAutoLayout', title: 'Auto Layout' })}
            ${iconButton('fitView', { id: 'btnFitView', title: 'Fit View (F)' })}
          </div>
          ${toolbarSpacer()}
          <div class="group">
            ${iconButton('copy', { id: 'btnCopyLua', title: 'Copy Lua Code' })}
            ${iconButton('insert', { id: 'btnInsert', title: 'Insert to Editor' })}
          </div>
          ${toolbarSep()}
          <button id="btnExport" class="primary">${ICONS.exportFile} Export ▾</button>
        </div>

        <!-- Canvas -->
        <div class="canvas-area"><canvas id="questCanvas"></canvas></div>

        <!-- Properties -->
        <div class="props-panel">
          ${panelSection('Quest Properties', '<div id="propsContent"><p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:20px;">Select a quest node</p></div>')}
          ${panelSection('Statistics', '<div id="statsContent"></div>', true)}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusQuests" class="badge">0 quests</span>
          </span>
          <div class="sep"></div>
          <span id="statusLinks">0 links</span>
          <div class="sep"></div>
          <span id="statusMode" class="mode-badge select">SELECT</span>
          <div class="spacer"></div>
          <span id="statusZoom">100%</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${ICONS.clean}</span>
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
      const NODE_W = 160, NODE_H = 60;
      const undo = new UndoStack(60);

      function snapshot() { return JSON.parse(JSON.stringify({ nodes, edges, nextId })); }
      function restoreSnap(s) { nodes = s.nodes; edges = s.edges; nextId = s.nextId; selectedNode = null; showProps(null); updateStatus(); render(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      const STATUS_COLORS = {
        available: { bg: '#1a3a1a', border: '#3a6a3a', dot: '#4caf50' },
        locked:    { bg: '#2a2a2a', border: '#4a4a4a', dot: '#666' },
        completed: { bg: '#3a3a1a', border: '#6a5a2a', dot: '#ffd700' },
      };

      function addNode(name, x, y) {
        pushUndo();
        nodes.push({
          id: nextId++, name: name || 'Quest ' + (nodes.length + 1),
          x: x ?? (100 + nodes.length * 40), y: y ?? (100 + nodes.length * 80),
          description: '', requiredItems: '', reward: '', status: 'available',
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

        // Grid
        ctx.strokeStyle = 'rgba(255,255,255,0.03)'; ctx.lineWidth = 1;
        const gs = 40, startX = -offsetX / zoom, startY = -offsetY / zoom;
        const endX = startX + canvas.width / zoom, endY = startY + canvas.height / zoom;
        for (let x = Math.floor(startX / gs) * gs; x < endX; x += gs) { ctx.beginPath(); ctx.moveTo(x, startY); ctx.lineTo(x, endY); ctx.stroke(); }
        for (let y = Math.floor(startY / gs) * gs; y < endY; y += gs) { ctx.beginPath(); ctx.moveTo(startX, y); ctx.lineTo(endX, y); ctx.stroke(); }

        // Edges (curved bezier with arrows)
        for (const e of edges) {
          const from = nodes.find(n => n.id === e.from);
          const to = nodes.find(n => n.id === e.to);
          if (!from || !to) continue;
          const fx = from.x + NODE_W / 2, fy = from.y + NODE_H;
          const tx = to.x + NODE_W / 2, ty = to.y;
          const dy = Math.abs(ty - fy) * 0.5;
          ctx.beginPath();
          ctx.moveTo(fx, fy);
          ctx.bezierCurveTo(fx, fy + dy, tx, ty - dy, tx, ty);
          ctx.strokeStyle = 'rgba(255,255,255,0.15)'; ctx.lineWidth = 2; ctx.stroke();
          // Arrow
          ctx.fillStyle = 'rgba(255,255,255,0.25)'; ctx.beginPath();
          ctx.moveTo(tx, ty); ctx.lineTo(tx - 5, ty - 8); ctx.lineTo(tx + 5, ty - 8);
          ctx.closePath(); ctx.fill();
        }

        // Nodes
        for (const n of nodes) {
          const sc = STATUS_COLORS[n.status] || STATUS_COLORS.available;
          const selected = n === selectedNode;
          ctx.fillStyle = sc.bg;
          ctx.strokeStyle = selected ? 'var(--accent, #89b4fa)' : sc.border;
          ctx.lineWidth = selected ? 2.5 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.fill(); ctx.stroke();
          // Status dot
          ctx.fillStyle = sc.dot; ctx.beginPath(); ctx.arc(n.x + 12, n.y + 16, 5, 0, Math.PI * 2); ctx.fill();
          // Name
          ctx.fillStyle = '#ddd'; ctx.font = '600 12px sans-serif'; ctx.textAlign = 'left';
          ctx.fillText(n.name.length > 18 ? n.name.substring(0, 17) + '…' : n.name, n.x + 24, n.y + 20);
          // Description
          if (n.description) {
            ctx.fillStyle = '#888'; ctx.font = '10px sans-serif';
            ctx.fillText(n.description.substring(0, 22) + (n.description.length > 22 ? '…' : ''), n.x + 8, n.y + 38);
          }
          // Reward
          if (n.reward) {
            ctx.fillStyle = '#ffd700'; ctx.font = '10px sans-serif';
            ctx.fillText('★ ' + n.reward, n.x + 8, n.y + 52);
          }
        }

        // Connect preview line
        if (connectMode && connectFrom) {
          ctx.strokeStyle = 'rgba(250,200,50,0.5)'; ctx.lineWidth = 2;
          ctx.setLineDash([6, 4]);
          ctx.beginPath();
          ctx.moveTo(connectFrom.x + NODE_W / 2, connectFrom.y + NODE_H);
          ctx.lineTo((canvas._mx - offsetX) / zoom, (canvas._my - offsetY) / zoom);
          ctx.stroke(); ctx.setLineDash([]);
        }
        ctx.restore();
      }

      canvas._mx = 0; canvas._my = 0;

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
        if (!node) { el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:20px;">Select a quest node</p>'; return; }
        el.innerHTML =
          '<div class="prop-field"><label>Name</label><input id="pName" value="' + node.name.replace(/"/g, '&quot;') + '"></div>' +
          '<div class="prop-field"><label>Description</label><textarea id="pDesc" rows="2">' + node.description + '</textarea></div>' +
          '<div class="prop-field"><label>Required Items</label><input id="pItems" value="' + node.requiredItems + '" placeholder="key, sword"></div>' +
          '<div class="prop-field"><label>Reward</label><input id="pReward" value="' + node.reward + '" placeholder="100 gold"></div>' +
          '<div class="prop-field"><label>Status</label><select id="pStatus">' +
            '<option value="available"' + (node.status === 'available' ? ' selected' : '') + '>Available</option>' +
            '<option value="locked"' + (node.status === 'locked' ? ' selected' : '') + '>Locked</option>' +
            '<option value="completed"' + (node.status === 'completed' ? ' selected' : '') + '>Completed</option></select></div>' +
          '<div class="prop-field"><label>Prerequisites</label><div id="prereqList" class="prereq-list"></div></div>';

        const prereqs = edges.filter(e => e.to === node.id).map(e => nodes.find(n => n.id === e.from)).filter(Boolean);
        const prereqEl = document.getElementById('prereqList');
        if (prereqs.length) {
          prereqEl.innerHTML = prereqs.map(p => '<div class="prereq-item"><span class="prereq-dot"></span>' + p.name + '</div>').join('');
        } else { prereqEl.textContent = 'None'; }

        const bind = (id, key) => {
          const inp = document.getElementById(id);
          if (inp) inp.addEventListener('input', (e) => { pushUndo(); node[key] = e.target.value; render(); });
        };
        bind('pName', 'name'); bind('pDesc', 'description'); bind('pItems', 'requiredItems'); bind('pReward', 'reward');
        document.getElementById('pStatus').addEventListener('change', (e) => { pushUndo(); node.status = e.target.value; render(); });
      }

      function updateStatus() {
        document.getElementById('statusQuests').textContent = nodes.length + ' quests';
        document.getElementById('statusLinks').textContent = edges.length + ' links';
        document.getElementById('statusZoom').textContent = Math.round(zoom * 100) + '%';
        // Stats
        const statsEl = document.getElementById('statsContent');
        const avail = nodes.filter(n => n.status === 'available').length;
        const locked = nodes.filter(n => n.status === 'locked').length;
        const done = nodes.filter(n => n.status === 'completed').length;
        statsEl.innerHTML =
          '<div style="font-size:11px;display:grid;grid-template-columns:1fr 1fr;gap:4px;">' +
          '<span style="color:#4caf50">Available: ' + avail + '</span>' +
          '<span style="color:#666">Locked: ' + locked + '</span>' +
          '<span style="color:#ffd700">Completed: ' + done + '</span>' +
          '<span>Total: ' + nodes.length + '</span></div>';
      }

      function fitView() {
        if (nodes.length === 0) return;
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        for (const n of nodes) {
          minX = Math.min(minX, n.x); minY = Math.min(minY, n.y);
          maxX = Math.max(maxX, n.x + NODE_W); maxY = Math.max(maxY, n.y + NODE_H);
        }
        const pad = 40;
        const w = maxX - minX + pad * 2, h = maxY - minY + pad * 2;
        zoom = Math.min(canvas.width / w, canvas.height / h, 2);
        offsetX = canvas.width / 2 - (minX + (maxX - minX) / 2) * zoom;
        offsetY = canvas.height / 2 - (minY + (maxY - minY) / 2) * zoom;
        render(); updateStatus();
      }

      function autoLayout() {
        if (nodes.length === 0) return;
        pushUndo();
        // Simple layered layout
        const layers = {}; const visited = new Set();
        const roots = nodes.filter(n => !edges.some(e => e.to === n.id));
        if (roots.length === 0) roots.push(nodes[0]);
        function assignLayer(node, depth) {
          if (visited.has(node.id)) return;
          visited.add(node.id);
          layers[node.id] = Math.max(layers[node.id] || 0, depth);
          const children = edges.filter(e => e.from === node.id).map(e => nodes.find(n => n.id === e.to)).filter(Boolean);
          children.forEach(c => assignLayer(c, depth + 1));
        }
        roots.forEach(r => assignLayer(r, 0));
        nodes.filter(n => !visited.has(n.id)).forEach(n => { layers[n.id] = 0; });
        const byLayer = {};
        for (const n of nodes) { const l = layers[n.id] || 0; (byLayer[l] = byLayer[l] || []).push(n); }
        for (const [layer, group] of Object.entries(byLayer)) {
          group.forEach((n, i) => { n.x = 80 + i * (NODE_W + 30); n.y = 60 + parseInt(layer) * (NODE_H + 50); });
        }
        render();
      }

      // ── Canvas events ──────────────────────────────────
      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) { isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY; return; }
        const node = hitTest(e.offsetX, e.offsetY);
        if (connectMode && e.button === 0) {
          if (!connectFrom && node) { connectFrom = node; }
          else if (connectFrom && node && node !== connectFrom) {
            if (!edges.find(ed => ed.from === connectFrom.id && ed.to === node.id)) {
              pushUndo(); edges.push({ from: connectFrom.id, to: node.id });
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
        canvas._mx = e.offsetX; canvas._my = e.offsetY;
        if (isPanning) { offsetX = e.clientX - panSX; offsetY = e.clientY - panSY; render(); return; }
        if (dragNode) { dragNode.x = (e.offsetX - offsetX) / zoom - dragOff.x; dragNode.y = (e.offsetY - offsetY) / zoom - dragOff.y; render(); }
        if (connectMode && connectFrom) render();
      });
      canvas.addEventListener('mouseup', () => { isPanning = false; if (dragNode) { pushUndo(); } dragNode = null; });
      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const old = zoom; zoom *= e.deltaY < 0 ? 1.1 : 0.9; zoom = Math.max(0.2, Math.min(4, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / old; offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / old;
        render(); updateStatus();
      }, { passive: false });

      // ── Buttons ────────────────────────────────────────
      document.getElementById('btnAdd').addEventListener('click', () => addNode());
      document.getElementById('btnConnect').addEventListener('click', () => {
        connectMode = !connectMode; connectFrom = null;
        document.getElementById('btnConnect').classList.toggle('active', connectMode);
        const badge = document.getElementById('statusMode');
        badge.className = connectMode ? 'mode-badge link' : 'mode-badge select';
        badge.textContent = connectMode ? 'LINK' : 'SELECT';
      });
      document.getElementById('btnDelete').addEventListener('click', () => {
        if (!selectedNode) return;
        pushUndo();
        edges = edges.filter(e => e.from !== selectedNode.id && e.to !== selectedNode.id);
        nodes = nodes.filter(n => n !== selectedNode);
        selectedNode = null; showProps(null); updateStatus(); render();
      });
      document.getElementById('btnAutoLayout').addEventListener('click', autoLayout);
      document.getElementById('btnFitView').addEventListener('click', fitView);
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restoreSnap(s); });

      // ── Shortcuts ──────────────────────────────────────
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('a', () => addNode());
      registerShortcut('c', () => document.getElementById('btnConnect').click());
      registerShortcut('Delete', () => document.getElementById('btnDelete').click());
      registerShortcut('f', () => fitView());

      // ── Export ─────────────────────────────────────────
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Quest / Tech Tree Editor', ''];
        lines.push('return {');
        for (const n of nodes) {
          lines.push('  {');
          lines.push('    id = ' + n.id + ',');
          lines.push('    name = "' + n.name + '",');
          if (n.description) lines.push('    description = "' + n.description + '",');
          if (n.requiredItems) {
            const items = n.requiredItems.split(',').map(s => '"' + s.trim() + '"').join(', ');
            lines.push('    requiredItems = { ' + items + ' },');
          }
          if (n.reward) lines.push('    reward = "' + n.reward + '",');
          const prereqs = edges.filter(e => e.to === n.id).map(e => e.from);
          if (prereqs.length) lines.push('    prerequisites = { ' + prereqs.join(', ') + ' },');
          lines.push('    status = "' + n.status + '",');
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
      // Sample quest tree
      nodes = [
        { id: 1, name: 'Find the Key', x: 80, y: 50, description: 'Locate the dungeon key', requiredItems: '', reward: '50 gold', status: 'available' },
        { id: 2, name: 'Enter Dungeon', x: 80, y: 160, description: 'Enter the dark dungeon', requiredItems: 'key', reward: '', status: 'locked' },
        { id: 3, name: 'Defeat Boss', x: 80, y: 270, description: 'Defeat the dragon', requiredItems: '', reward: 'Dragon Sword', status: 'locked' },
      ];
      nextId = 4;
      edges = [{ from: 1, to: 2 }, { from: 2, to: 3 }];
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `);
  }
}
