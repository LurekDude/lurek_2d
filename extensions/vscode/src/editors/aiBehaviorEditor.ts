import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

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
        display: grid; grid-template-columns: 180px 1fr 240px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .palette-panel { grid-row: 2; background: var(--surface); border-right: 1px solid var(--border); overflow-y: auto; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: var(--bg); }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); overflow-y: auto; background: var(--surface); }

      .drag-node {
        padding: 5px 8px; font-size: 11px; cursor: pointer; border-radius: var(--radius);
        margin: 1px 4px; display: flex; align-items: center; gap: 6px;
        border: 1px solid transparent; transition: border-color 0.1s, background 0.08s;
      }
      .drag-node:hover { border-color: var(--accent); background: var(--hover); }
      .drag-node .cat-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }

      .prop-field { margin-bottom: 6px; }
      .prop-field label { display: block; font-size: 10px; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.3px; margin-bottom: 2px; }
      .prop-field .type-badge {
        display: inline-block; padding: 1px 8px; border-radius: 9px;
        font-size: 10px; font-weight: 600; margin-bottom: 4px;
      }

      .sim-badge { padding: 1px 8px; border-radius: 9px; font-size: 10px; font-weight: 600; }
      .sim-badge.idle { background: var(--surface-2); color: var(--text-dim); }
      .sim-badge.running { background: #ff9800; color: #1e1e2e; }
    `, `
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            ${iconButton('trash', { id: 'btnClearTree', title: 'Clear Tree', cls: 'danger' })}
            ${iconButton('trash', { id: 'btnDelete', title: 'Delete Node (Del)', cls: 'danger' })}
          </div>
          ${toolbarSep()}
          <div class="group">
            ${iconButton('undo', { id: 'btnUndo', title: 'Undo (Ctrl+Z)' })}
            ${iconButton('redo', { id: 'btnRedo', title: 'Redo (Ctrl+Y)' })}
          </div>
          ${toolbarSep()}
          <div class="group">
            <button id="btnSimulate">${ICONS.play} Simulate</button>
            <button id="btnReset">${ICONS.refresh} Reset</button>
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

        <!-- Palette -->
        <div class="palette-panel">
          ${panelSection('Composites', `
            <div class="drag-node" data-type="Sequence"><span class="cat-dot" style="background:#4caf50"></span>Sequence</div>
            <div class="drag-node" data-type="Selector"><span class="cat-dot" style="background:#4caf50"></span>Selector</div>
            <div class="drag-node" data-type="Parallel"><span class="cat-dot" style="background:#4caf50"></span>Parallel</div>
            <div class="drag-node" data-type="RandomSelector"><span class="cat-dot" style="background:#4caf50"></span>RandomSelector</div>
          `)}
          ${panelSection('Decorators', `
            <div class="drag-node" data-type="Inverter"><span class="cat-dot" style="background:#f38ba8"></span>Inverter</div>
            <div class="drag-node" data-type="Repeater"><span class="cat-dot" style="background:#f38ba8"></span>Repeater</div>
            <div class="drag-node" data-type="Succeeder"><span class="cat-dot" style="background:#f38ba8"></span>Succeeder</div>
            <div class="drag-node" data-type="Cooldown"><span class="cat-dot" style="background:#f38ba8"></span>Cooldown</div>
            <div class="drag-node" data-type="Guard"><span class="cat-dot" style="background:#f38ba8"></span>Guard</div>
          `)}
          ${panelSection('Conditions', `
            <div class="drag-node" data-type="HasTarget"><span class="cat-dot" style="background:#89b4fa"></span>HasTarget</div>
            <div class="drag-node" data-type="InRange"><span class="cat-dot" style="background:#89b4fa"></span>InRange</div>
            <div class="drag-node" data-type="HealthCheck"><span class="cat-dot" style="background:#89b4fa"></span>HealthCheck</div>
            <div class="drag-node" data-type="Custom"><span class="cat-dot" style="background:#89b4fa"></span>Custom</div>
          `)}
          ${panelSection('Actions', `
            <div class="drag-node" data-type="MoveTo"><span class="cat-dot" style="background:#f9e2af"></span>MoveTo</div>
            <div class="drag-node" data-type="Attack"><span class="cat-dot" style="background:#f9e2af"></span>Attack</div>
            <div class="drag-node" data-type="Flee"><span class="cat-dot" style="background:#f9e2af"></span>Flee</div>
            <div class="drag-node" data-type="Patrol"><span class="cat-dot" style="background:#f9e2af"></span>Patrol</div>
          `)}
        </div>

        <!-- Canvas -->
        <div class="canvas-area"><canvas id="btCanvas"></canvas></div>

        <!-- Properties -->
        <div class="props-panel">
          ${panelSection('Node Properties', '<div id="propsContent"><p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:20px;">Click palette to add nodes</p></div>')}
          ${panelSection('Tree Stats', '<div id="treeStats"></div>', true)}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusNodes" class="badge">0 nodes</span>
          </span>
          <div class="sep"></div>
          <span id="statusDepth">Depth: 0</span>
          <div class="sep"></div>
          <span id="statusSim" class="sim-badge idle">IDLE</span>
          <div class="spacer"></div>
          <span id="statusZoom">100%</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${ICONS.clean}</span>
        </div>
      </div>
    `, `
      const canvas = document.getElementById('btCanvas');
      const ctx = canvas.getContext('2d');
      let nodes = [], selectedNode = null, dragNode = null, dragOff = { x: 0, y: 0 };
      let offsetX = 0, offsetY = 0, zoom = 1;
      let isPanning = false, panSX = 0, panSY = 0;
      let nextId = 1;
      const NODE_W = 130, NODE_H = 44;
      const undo = new UndoStack(60);

      function snapshot() { return JSON.parse(JSON.stringify({ nodes, nextId })); }
      function restoreSnap(s) { nodes = s.nodes; nextId = s.nextId; selectedNode = null; showProps(null); updateStatus(); render(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      const CATEGORIES = {
        Sequence: 'composite', Selector: 'composite', Parallel: 'composite', RandomSelector: 'composite',
        Inverter: 'decorator', Repeater: 'decorator', Succeeder: 'decorator', Cooldown: 'decorator', Guard: 'decorator',
        HasTarget: 'condition', InRange: 'condition', HealthCheck: 'condition', Custom: 'condition',
        MoveTo: 'action', Attack: 'action', Flee: 'action', Patrol: 'action'
      };
      const CAT_COLORS = {
        composite: { bg: '#1a3a1a', border: '#3a6a3a', dot: '#4caf50' },
        decorator: { bg: '#3a1a2a', border: '#6a3a4a', dot: '#f38ba8' },
        condition: { bg: '#1a2a3a', border: '#3a4a6a', dot: '#89b4fa' },
        action:    { bg: '#3a3a1a', border: '#5a5a2a', dot: '#f9e2af' },
      };
      const STATUS_COLORS = { success: '#4caf50', failure: '#f44336', running: '#ff9800', idle: '#585b70' };

      function addNode(type, x, y) {
        pushUndo();
        const node = {
          id: nextId++, type, category: CATEGORIES[type] || 'action',
          x: x ?? (canvas.width / 2 - NODE_W / 2), y: y ?? (60 + nodes.length * 60),
          parentId: null, status: 'idle', params: {}
        };
        if (type === 'Cooldown') node.params.duration = 2.0;
        if (type === 'Repeater') node.params.times = 3;
        if (type === 'InRange') node.params.range = 100;
        if (type === 'HealthCheck') node.params.threshold = 0.3;
        if (type === 'Custom') node.params.func = 'myCondition';
        nodes.push(node);
        if (selectedNode && (selectedNode.category === 'composite' || selectedNode.category === 'decorator')) {
          node.parentId = selectedNode.id;
          layoutTree();
        }
        selectedNode = node; showProps(node);
        updateStatus(); render();
      }

      function getChildren(parentId) { return nodes.filter(n => n.parentId === parentId); }

      function layoutTree() {
        const roots = nodes.filter(n => !n.parentId);
        let startX = 60;
        for (const root of roots) { startX = layoutSubtree(root, startX, 40); startX += 40; }
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

      function getTreeDepth() {
        function depth(nodeId) {
          const children = getChildren(nodeId);
          if (children.length === 0) return 1;
          return 1 + Math.max(...children.map(c => depth(c.id)));
        }
        const roots = nodes.filter(n => !n.parentId);
        return roots.length ? Math.max(...roots.map(r => depth(r.id))) : 0;
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

        // Edges (curved)
        for (const n of nodes) {
          if (!n.parentId) continue;
          const parent = nodes.find(p => p.id === n.parentId);
          if (!parent) continue;
          const fx = parent.x + NODE_W / 2, fy = parent.y + NODE_H;
          const tx = n.x + NODE_W / 2, ty = n.y;
          const dy = Math.abs(ty - fy) * 0.4;
          ctx.beginPath(); ctx.moveTo(fx, fy);
          ctx.bezierCurveTo(fx, fy + dy, tx, ty - dy, tx, ty);
          ctx.strokeStyle = 'rgba(255,255,255,0.15)'; ctx.lineWidth = 2; ctx.stroke();
          // Arrow
          ctx.fillStyle = 'rgba(255,255,255,0.25)'; ctx.beginPath();
          ctx.moveTo(tx, ty); ctx.lineTo(tx - 4, ty - 7); ctx.lineTo(tx + 4, ty - 7);
          ctx.closePath(); ctx.fill();
        }

        // Nodes
        for (const n of nodes) {
          const cc = CAT_COLORS[n.category] || CAT_COLORS.action;
          const sel = n === selectedNode;
          ctx.fillStyle = cc.bg;
          ctx.strokeStyle = sel ? 'var(--accent, #89b4fa)' : cc.border;
          ctx.lineWidth = sel ? 2.5 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.fill(); ctx.stroke();
          // Category color bar
          ctx.fillStyle = cc.dot; ctx.fillRect(n.x, n.y, 4, NODE_H);
          // Status indicator
          ctx.fillStyle = STATUS_COLORS[n.status]; ctx.beginPath();
          ctx.arc(n.x + 16, n.y + NODE_H / 2, 5, 0, Math.PI * 2); ctx.fill();
          // Label
          ctx.fillStyle = '#ddd'; ctx.font = '600 11px sans-serif'; ctx.textAlign = 'left'; ctx.textBaseline = 'middle';
          ctx.fillText(n.type, n.x + 26, n.y + NODE_H / 2);
          // Params hint
          const paramKeys = Object.keys(n.params);
          if (paramKeys.length) {
            ctx.fillStyle = '#888'; ctx.font = '9px sans-serif';
            const hint = paramKeys.map(k => k + '=' + n.params[k]).join(' ');
            ctx.fillText(hint.substring(0, 18), n.x + 16, n.y + NODE_H - 6);
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
        if (!node) { el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:20px;">Click palette to add nodes</p>'; return; }
        const cc = CAT_COLORS[node.category] || CAT_COLORS.action;
        let html = '<div class="prop-field"><span class="type-badge" style="background:' + cc.bg + ';border:1px solid ' + cc.border + '">' + node.type + '</span></div>';
        html += '<div class="prop-field"><label>Category</label><span style="font-size:11px;color:' + cc.dot + '">' + node.category + '</span></div>';
        html += '<div class="prop-field"><label>Parent</label><select id="pParent" style="width:100%"><option value="">Root (no parent)</option>';
        for (const n of nodes) {
          if (n.id === node.id) continue;
          if (n.category === 'composite' || n.category === 'decorator') {
            html += '<option value="' + n.id + '"' + (node.parentId === n.id ? ' selected' : '') + '>' + n.type + ' #' + n.id + '</option>';
          }
        }
        html += '</select></div>';
        for (const [k, v] of Object.entries(node.params)) {
          html += '<div class="prop-field"><label>' + k + '</label><input id="pp_' + k + '" value="' + v + '" ' + (typeof v === 'number' ? 'type="number" step="0.1"' : '') + ' style="width:100%"></div>';
        }
        // Children list
        const children = getChildren(node.id);
        if (children.length) {
          html += '<div class="prop-field"><label>Children (' + children.length + ')</label><div style="font-size:11px;color:var(--text-dim)">' +
            children.map(c => c.type + ' #' + c.id).join('<br>') + '</div></div>';
        }
        el.innerHTML = html;

        document.getElementById('pParent').addEventListener('change', (e) => {
          pushUndo(); node.parentId = e.target.value ? parseInt(e.target.value) : null;
          layoutTree(); render(); updateStatus();
        });
        for (const k of Object.keys(node.params)) {
          const inp = document.getElementById('pp_' + k);
          if (inp) inp.addEventListener('input', (e) => {
            pushUndo();
            node.params[k] = typeof node.params[k] === 'number' ? parseFloat(e.target.value) || 0 : e.target.value;
          });
        }
      }

      function updateStatus() {
        document.getElementById('statusNodes').textContent = nodes.length + ' nodes';
        document.getElementById('statusDepth').textContent = 'Depth: ' + getTreeDepth();
        document.getElementById('statusZoom').textContent = Math.round(zoom * 100) + '%';
        const statsEl = document.getElementById('treeStats');
        const counts = {};
        for (const n of nodes) counts[n.category] = (counts[n.category] || 0) + 1;
        statsEl.innerHTML = '<div style="font-size:11px;display:grid;grid-template-columns:1fr 1fr;gap:4px">' +
          Object.entries(counts).map(([k, v]) => '<span style="color:' + (CAT_COLORS[k]?.dot || '#888') + '">' + k + ': ' + v + '</span>').join('') +
          '</div>';
      }

      function fitView() {
        if (nodes.length === 0) return;
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        for (const n of nodes) { minX = Math.min(minX, n.x); minY = Math.min(minY, n.y); maxX = Math.max(maxX, n.x + NODE_W); maxY = Math.max(maxY, n.y + NODE_H); }
        const pad = 40, w = maxX - minX + pad * 2, h = maxY - minY + pad * 2;
        zoom = Math.min(canvas.width / w, canvas.height / h, 2);
        offsetX = canvas.width / 2 - (minX + (maxX - minX) / 2) * zoom;
        offsetY = canvas.height / 2 - (minY + (maxY - minY) / 2) * zoom;
        render(); updateStatus();
      }

      // ── Palette ────────────────────────────────────────
      document.querySelectorAll('.drag-node').forEach(el => {
        el.addEventListener('click', () => addNode(el.dataset.type));
      });

      // ── Canvas events ──────────────────────────────────
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
      canvas.addEventListener('mouseup', () => { isPanning = false; if (dragNode) pushUndo(); dragNode = null; });
      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const old = zoom; zoom *= e.deltaY < 0 ? 1.1 : 0.9; zoom = Math.max(0.2, Math.min(4, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / old;
        offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / old; render(); updateStatus();
      }, { passive: false });

      // ── Buttons ────────────────────────────────────────
      document.getElementById('btnClearTree').addEventListener('click', () => { pushUndo(); nodes = []; selectedNode = null; showProps(null); updateStatus(); render(); });
      document.getElementById('btnDelete').addEventListener('click', () => {
        if (!selectedNode) return;
        pushUndo();
        const delId = selectedNode.id;
        nodes.filter(n => n.parentId === delId).forEach(n => { n.parentId = null; });
        nodes = nodes.filter(n => n.id !== delId);
        selectedNode = null; showProps(null); updateStatus(); render();
      });
      document.getElementById('btnAutoLayout').addEventListener('click', () => { pushUndo(); layoutTree(); render(); });
      document.getElementById('btnFitView').addEventListener('click', fitView);
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      document.getElementById('btnSimulate').addEventListener('click', () => {
        const statuses = ['success', 'failure', 'running'];
        for (const n of nodes) n.status = statuses[Math.floor(Math.random() * statuses.length)];
        const badge = document.getElementById('statusSim');
        badge.className = 'sim-badge running'; badge.textContent = 'RUNNING';
        render();
      });
      document.getElementById('btnReset').addEventListener('click', () => {
        for (const n of nodes) n.status = 'idle';
        const badge = document.getElementById('statusSim');
        badge.className = 'sim-badge idle'; badge.textContent = 'IDLE';
        render();
      });

      // ── Shortcuts ──────────────────────────────────────
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('Delete', () => document.getElementById('btnDelete').click());
      registerShortcut('f', () => fitView());
      registerShortcut('l', () => { pushUndo(); layoutTree(); render(); });

      // ── Export ─────────────────────────────────────────
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

      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D AI Behavior Tree Editor', '-- Usage: lurek.ai.behavior_tree(entity, tree)', ''];
        const roots = nodes.filter(n => !n.parentId);
        lines.push('return {');
        for (const r of roots) lines.push('  ' + exportNode(r) + ',');
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

      // ── Init (default tree) ────────────────────────────
      nodes = [
        { id: 1, type: 'Selector', category: 'composite', x: 300, y: 40, parentId: null, status: 'idle', params: {} },
        { id: 2, type: 'Sequence', category: 'composite', x: 150, y: 120, parentId: 1, status: 'idle', params: {} },
        { id: 3, type: 'HasTarget', category: 'condition', x: 100, y: 200, parentId: 2, status: 'idle', params: {} },
        { id: 4, type: 'Attack', category: 'action', x: 220, y: 200, parentId: 2, status: 'idle', params: {} },
        { id: 5, type: 'Patrol', category: 'action', x: 400, y: 120, parentId: 1, status: 'idle', params: {} },
      ];
      nextId = 6;
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `);
  }
}
