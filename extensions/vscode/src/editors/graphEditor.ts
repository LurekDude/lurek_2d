import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

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
        display: grid; grid-template-columns: 1fr 240px;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: var(--bg); }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); overflow-y: auto; background: var(--surface); }

      .prop-field { margin-bottom: 6px; }
      .prop-field label { display: block; font-size: 10px; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.3px; margin-bottom: 2px; }

      .mode-badge {
        display: inline-flex; align-items: center; gap: 4px;
        padding: 1px 8px; border-radius: 9px; font-size: 10px; font-weight: 600;
      }
      .mode-badge.select { background: var(--surface-2); color: var(--text-dim); }
      .mode-badge.connect { background: #ff9800; color: var(--bg); }
    `, `
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            ${iconButton('add', { id: 'btnAddNode', title: 'Add Node (A)' })}
            <input id="nodeType" value="Process" style="width:80px" title="Node type">
            ${iconButton('link', { id: 'btnConnect', title: 'Connect Ports (C)' })}
            ${iconButton('trash', { id: 'btnDelete', title: 'Delete (Del)', cls: 'danger' })}
          </div>
          ${toolbarSep()}
          <div class="group">
            ${iconButton('undo', { id: 'btnUndo', title: 'Undo (Ctrl+Z)' })}
            ${iconButton('redo', { id: 'btnRedo', title: 'Redo (Ctrl+Y)' })}
          </div>
          ${toolbarSep()}
          <div class="group">
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
        <div class="canvas-area"><canvas id="graphCanvas"></canvas></div>

        <!-- Properties -->
        <div class="props-panel">
          ${panelSection('Node Properties', '<div id="propsContent"><p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:20px;">Select a node</p></div>')}
          ${panelSection('Port Editor', '<div id="portEditor"><p style="color:var(--text-dim);font-size:11px">Ports are defined per-node</p></div>')}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusNodes" class="badge">0 nodes</span>
          </span>
          <div class="sep"></div>
          <span id="statusEdges">0 edges</span>
          <div class="sep"></div>
          <span id="statusMode" class="mode-badge select">SELECT</span>
          <div class="spacer"></div>
          <span id="statusZoom">100%</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${ICONS.clean}</span>
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
      const NODE_W = 150, NODE_H = 64, PORT_R = 6;
      const undo = new UndoStack(60);

      function snapshot() { return JSON.parse(JSON.stringify({ nodes, edges, nextId })); }
      function restoreSnap(s) { nodes = s.nodes; edges = s.edges; nextId = s.nextId; selectedNode = null; showProps(null); updateStatus(); render(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      const TYPE_COLORS = {
        Input: '#1a3a1a', Process: '#1a2a3a', Output: '#3a1a2a', Filter: '#3a3a1a', Merge: '#2a1a3a',
      };

      function addNode(type, x, y) {
        pushUndo();
        nodes.push({
          id: nextId++, type: type || 'Process',
          x: x ?? (150 + nodes.length * 40), y: y ?? (100 + nodes.length * 40),
          label: (type || 'Process') + ' ' + nextId,
          inPorts: ['in'], outPorts: ['out'], data: {}
        });
        updateStatus(); render();
      }

      function getPortPos(node, isOut, portIdx) {
        const portCount = isOut ? node.outPorts.length : node.inPorts.length;
        const spacing = NODE_H / (portCount + 1);
        return { x: isOut ? node.x + NODE_W : node.x, y: node.y + spacing * (portIdx + 1) };
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
        const gs = 40, sX = -offsetX / zoom, sY = -offsetY / zoom;
        const eX = sX + canvas.width / zoom, eY = sY + canvas.height / zoom;
        for (let x = Math.floor(sX / gs) * gs; x < eX; x += gs) { ctx.beginPath(); ctx.moveTo(x, sY); ctx.lineTo(x, eY); ctx.stroke(); }
        for (let y = Math.floor(sY / gs) * gs; y < eY; y += gs) { ctx.beginPath(); ctx.moveTo(sX, y); ctx.lineTo(eX, y); ctx.stroke(); }

        // Edges
        for (const e of edges) {
          const fromNode = nodes.find(n => n.id === e.fromNode);
          const toNode = nodes.find(n => n.id === e.toNode);
          if (!fromNode || !toNode) continue;
          const fp = getPortPos(fromNode, true, e.fromPort);
          const tp = getPortPos(toNode, false, e.toPort);
          const cx = (fp.x + tp.x) / 2;
          ctx.beginPath(); ctx.moveTo(fp.x, fp.y);
          ctx.bezierCurveTo(cx, fp.y, cx, tp.y, tp.x, tp.y);
          ctx.strokeStyle = 'rgba(255,255,255,0.2)'; ctx.lineWidth = 2; ctx.stroke();
        }

        // Nodes
        for (const n of nodes) {
          const sel = n === selectedNode;
          ctx.fillStyle = TYPE_COLORS[n.type] || '#2d2d2d';
          ctx.strokeStyle = sel ? 'var(--accent, #89b4fa)' : 'rgba(255,255,255,0.08)';
          ctx.lineWidth = sel ? 2.5 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.fill(); ctx.stroke();
          // Header bar
          ctx.fillStyle = 'rgba(255,255,255,0.06)';
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, 22, [6, 6, 0, 0]); ctx.fill();
          // Label
          ctx.fillStyle = '#ddd'; ctx.font = '600 11px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
          ctx.fillText(n.label.length > 18 ? n.label.substring(0, 17) + '…' : n.label, n.x + NODE_W / 2, n.y + 11);
          // Type
          ctx.fillStyle = '#888'; ctx.font = '9px sans-serif';
          ctx.fillText(n.type, n.x + NODE_W / 2, n.y + 40);
          // In ports
          n.inPorts.forEach((p, i) => {
            const pos = getPortPos(n, false, i);
            ctx.fillStyle = '#4ec9b0'; ctx.beginPath(); ctx.arc(pos.x, pos.y, PORT_R, 0, Math.PI * 2); ctx.fill();
            ctx.strokeStyle = '#2a5a4a'; ctx.lineWidth = 1; ctx.stroke();
            ctx.fillStyle = '#999'; ctx.font = '9px sans-serif'; ctx.textAlign = 'left';
            ctx.fillText(p, pos.x + 10, pos.y + 3);
          });
          // Out ports
          n.outPorts.forEach((p, i) => {
            const pos = getPortPos(n, true, i);
            ctx.fillStyle = '#ff9800'; ctx.beginPath(); ctx.arc(pos.x, pos.y, PORT_R, 0, Math.PI * 2); ctx.fill();
            ctx.strokeStyle = '#5a3a1a'; ctx.lineWidth = 1; ctx.stroke();
            ctx.fillStyle = '#999'; ctx.font = '9px sans-serif'; ctx.textAlign = 'right';
            ctx.fillText(p, pos.x - 10, pos.y + 3);
          });
        }
        ctx.restore();
      }

      function hitNode(sx, sy) {
        const wx = (sx - offsetX) / zoom, wy = (sy - offsetY) / zoom;
        for (let i = nodes.length - 1; i >= 0; i--) {
          const n = nodes[i]; if (wx >= n.x && wx <= n.x + NODE_W && wy >= n.y && wy <= n.y + NODE_H) return n;
        }
        return null;
      }

      function hitPort(sx, sy) {
        const wx = (sx - offsetX) / zoom, wy = (sy - offsetY) / zoom;
        for (const n of nodes) {
          for (let i = 0; i < n.outPorts.length; i++) { const p = getPortPos(n, true, i); if (Math.hypot(wx - p.x, wy - p.y) < PORT_R * 2) return { node: n, isOut: true, port: i }; }
          for (let i = 0; i < n.inPorts.length; i++) { const p = getPortPos(n, false, i); if (Math.hypot(wx - p.x, wy - p.y) < PORT_R * 2) return { node: n, isOut: false, port: i }; }
        }
        return null;
      }

      function showProps(node) {
        const el = document.getElementById('propsContent');
        const pe = document.getElementById('portEditor');
        if (!node) { el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:20px;">Select a node</p>'; pe.innerHTML = ''; return; }
        el.innerHTML =
          '<div class="prop-field"><label>Label</label><input id="pLabel" value="' + node.label.replace(/"/g, '&quot;') + '" style="width:100%"></div>' +
          '<div class="prop-field"><label>Type</label><input id="pType" value="' + node.type + '" style="width:100%"></div>';
        document.getElementById('pLabel').addEventListener('input', (e) => { pushUndo(); node.label = e.target.value; render(); });
        document.getElementById('pType').addEventListener('input', (e) => { pushUndo(); node.type = e.target.value; render(); });

        pe.innerHTML =
          '<div class="prop-field"><label>In Ports (comma sep)</label><input id="pInPorts" value="' + node.inPorts.join(', ') + '" style="width:100%"></div>' +
          '<div class="prop-field"><label>Out Ports (comma sep)</label><input id="pOutPorts" value="' + node.outPorts.join(', ') + '" style="width:100%"></div>';
        document.getElementById('pInPorts').addEventListener('change', (e) => {
          pushUndo(); node.inPorts = e.target.value.split(',').map(s => s.trim()).filter(Boolean);
          edges = edges.filter(ed => !(ed.toNode === node.id && ed.toPort >= node.inPorts.length)); render();
        });
        document.getElementById('pOutPorts').addEventListener('change', (e) => {
          pushUndo(); node.outPorts = e.target.value.split(',').map(s => s.trim()).filter(Boolean);
          edges = edges.filter(ed => !(ed.fromNode === node.id && ed.fromPort >= node.outPorts.length)); render();
        });
      }

      function updateStatus() {
        document.getElementById('statusNodes').textContent = nodes.length + ' nodes';
        document.getElementById('statusEdges').textContent = edges.length + ' edges';
        document.getElementById('statusZoom').textContent = Math.round(zoom * 100) + '%';
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

      // ── Canvas events ──────────────────────────────────
      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) { isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY; return; }
        if (connectMode) {
          const port = hitPort(e.offsetX, e.offsetY);
          if (port && port.isOut && !connectFrom) { connectFrom = port.node; connectPort = port.port; }
          else if (port && !port.isOut && connectFrom) {
            pushUndo(); edges.push({ fromNode: connectFrom.id, fromPort: connectPort, toNode: port.node.id, toPort: port.port });
            connectFrom = null; updateStatus(); render();
          } else { connectFrom = null; }
          return;
        }
        const node = hitNode(e.offsetX, e.offsetY);
        if (node) { selectedNode = node; showProps(node); dragNode = node; dragOff = { x: (e.offsetX - offsetX) / zoom - node.x, y: (e.offsetY - offsetY) / zoom - node.y }; }
        else { selectedNode = null; showProps(null); }
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
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / old; offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / old; render(); updateStatus();
      }, { passive: false });

      // ── Buttons ────────────────────────────────────────
      document.getElementById('btnAddNode').addEventListener('click', () => addNode(document.getElementById('nodeType').value));
      document.getElementById('btnConnect').addEventListener('click', () => {
        connectMode = !connectMode; connectFrom = null;
        document.getElementById('btnConnect').classList.toggle('active', connectMode);
        const badge = document.getElementById('statusMode');
        badge.className = connectMode ? 'mode-badge connect' : 'mode-badge select';
        badge.textContent = connectMode ? 'CONNECT' : 'SELECT';
      });
      document.getElementById('btnDelete').addEventListener('click', () => {
        if (!selectedNode) return; pushUndo();
        edges = edges.filter(e => e.fromNode !== selectedNode.id && e.toNode !== selectedNode.id);
        nodes = nodes.filter(n => n !== selectedNode);
        selectedNode = null; showProps(null); updateStatus(); render();
      });
      document.getElementById('btnFitView').addEventListener('click', fitView);
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restoreSnap(s); });

      // ── Shortcuts ──────────────────────────────────────
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('a', () => document.getElementById('btnAddNode').click());
      registerShortcut('c', () => document.getElementById('btnConnect').click());
      registerShortcut('Delete', () => document.getElementById('btnDelete').click());
      registerShortcut('f', () => fitView());

      // ── Export ─────────────────────────────────────────
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Graph / Node Editor', ''];
        lines.push('return {');
        lines.push('  nodes = {');
        for (const n of nodes) {
          lines.push('    { id = ' + n.id + ', type = "' + n.type + '", label = "' + n.label + '"' +
            ', inPorts = { "' + n.inPorts.join('", "') + '" }' +
            ', outPorts = { "' + n.outPorts.join('", "') + '" } },');
        }
        lines.push('  },');
        lines.push('  edges = {');
        for (const e of edges) {
          lines.push('    { from = ' + e.fromNode + ', fromPort = ' + (e.fromPort + 1) + ', to = ' + e.toNode + ', toPort = ' + (e.toPort + 1) + ' },');
        }
        lines.push('  },');
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
      nodes = [
        { id: 1, type: 'Input', x: 80, y: 100, label: 'Input 1', inPorts: [], outPorts: ['data', 'signal'], data: {} },
        { id: 2, type: 'Process', x: 300, y: 80, label: 'Process 2', inPorts: ['data'], outPorts: ['result'], data: {} },
        { id: 3, type: 'Output', x: 520, y: 100, label: 'Output 3', inPorts: ['result'], outPorts: [], data: {} },
      ];
      nextId = 4;
      edges = [{ fromNode: 1, fromPort: 0, toNode: 2, toPort: 0 }, { fromNode: 2, fromPort: 0, toNode: 3, toPort: 0 }];
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `);
  }
}
