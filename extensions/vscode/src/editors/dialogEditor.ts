import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

export class DialogEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): DialogEditor {
    return new DialogEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.editor.dialog", "Dialog Editor");
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
      .status-bar { grid-column: 1 / -1; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: var(--bg); }
      .canvas-area canvas { display: block; }
      .props-panel { grid-row: 2; border-left: 1px solid var(--border); overflow-y: auto; background: var(--surface); }

      .choice-item {
        display: flex; gap: 4px; margin-bottom: 3px; align-items: center;
      }
      .choice-item input { flex: 1; font-size: 11px; }

      .prop-field { margin-bottom: 4px; }
      .prop-field label {
        font-size: 10px; text-transform: uppercase; letter-spacing: 0.3px;
        color: var(--text-dim); display: block; margin-bottom: 1px;
      }
      .prop-field input, .prop-field textarea, .prop-field select { width: 100%; font-size: 12px; }
      .prop-field textarea { height: 56px; resize: vertical; font-family: var(--font-mono); font-size: 11px; }

      .type-badge {
        display: inline-flex; align-items: center; gap: 4px; padding: 2px 8px;
        border-radius: var(--radius); font-size: 10px; font-weight: 600;
        text-transform: uppercase; letter-spacing: 0.3px;
      }

      .conn-item {
        display: flex; align-items: center; gap: 4px; font-size: 11px;
        padding: 3px 6px; border-radius: var(--radius); margin-bottom: 2px;
      }
      .conn-item:hover { background: var(--hover); }
      .conn-item .arrow { color: var(--accent); }
      .conn-item .target { flex: 1; }

      .node-type-btn { display: flex; align-items: center; gap: 4px; font-size: 11px; padding: 4px 8px; }
      .node-type-btn .dot { width: 8px; height: 8px; border-radius: 50%; }
    `, `
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            <button class="node-type-btn" id="btnAddNpc"><span class="dot" style="background:#4488bb"></span>NPC</button>
            <button class="node-type-btn" id="btnAddChoice"><span class="dot" style="background:#44aa66"></span>Choice</button>
            <button class="node-type-btn" id="btnAddCondition"><span class="dot" style="background:#bbaa44"></span>Condition</button>
            <button class="node-type-btn" id="btnAddAction"><span class="dot" style="background:#bb6644"></span>Action</button>
          </div>
          ${toolbarSep()}
          <div class="group">
            ${iconButton('link', { id: 'btnConnect', title: 'Connect Mode (C)' })}
            ${iconButton('trash', { id: 'btnDelete', title: 'Delete Selected (Del)', cls: 'danger' })}
          </div>
          ${toolbarSep()}
          <div class="group">
            ${iconButton('undo', { id: 'btnUndo', title: 'Undo (Ctrl+Z)' })}
            ${iconButton('redo', { id: 'btnRedo', title: 'Redo (Ctrl+Y)' })}
          </div>
          ${toolbarSep()}
          <div class="group">
            <button id="btnAutoLayout" title="Auto-arrange nodes">Auto Layout</button>
            <button id="btnFitView" title="Fit all nodes in view">Fit View</button>
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
        <div class="canvas-area"><canvas id="dialogCanvas"></canvas></div>

        <!-- Properties Panel -->
        <div class="props-panel">
          ${panelSection('Node Properties', '<div id="propsContent"><p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:8px;">Select a dialog node.</p></div>')}
          ${panelSection('Connections', '<div id="connsContent"></div>', true)}
          ${panelSection('Preview', `
            <div id="previewArea" style="background:var(--bg);border:1px solid var(--border);border-radius:var(--radius);padding:8px;margin:0 8px;font-size:12px;min-height:60px;color:var(--text-dim);text-align:center;">
              Select a node to preview dialog.
            </div>
          `, true)}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusNodes" class="badge">0 nodes</span>
          </span>
          <div class="sep"></div>
          <span id="statusConns">0 connections</span>
          <div class="sep"></div>
          <span id="statusMode">Select</span>
          <div class="spacer"></div>
          <span id="statusZoom">100%</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${ICONS.clean}</span>
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
      const NODE_W = 170, NODE_H = 64;
      const undo = new UndoStack(60);

      const NODE_TYPES = {
        npc:       { color: '#1e3a5f', border: '#4488bb', label: 'NPC' },
        choice:    { color: '#1e4a2e', border: '#44aa66', label: 'Choice' },
        condition: { color: '#4a3e1e', border: '#bbaa44', label: 'Condition' },
        action:    { color: '#4a2e1e', border: '#bb6644', label: 'Action' },
      };

      function snapshot() { return JSON.parse(JSON.stringify({ nodes, edges, nextId })); }
      function restoreSnap(s) { nodes = s.nodes; edges = s.edges; nextId = s.nextId; selectedNode = null; showProps(null); updateStatus(); render(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      function addNode(type, x, y) {
        pushUndo();
        nodes.push({
          id: nextId++, type,
          x: x !== undefined ? x : 100 + nodes.length * 50,
          y: y !== undefined ? y : 100 + nodes.length * 50,
          speaker: type === 'npc' ? 'NPC' : '', text: '',
          choices: type === 'choice' ? ['Yes', 'No'] : [],
          condition: type === 'condition' ? 'has_item("key")' : '',
          action: type === 'action' ? 'give_item("reward")' : '',
        });
        updateStatus(); render();
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight; render();
      }

      // ── Rendering ──────────────────────────────────────
      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        // Grid dots
        ctx.fillStyle = 'rgba(137,180,250,0.06)';
        const gs = 40 * zoom, sx = offsetX % gs, sy = offsetY % gs;
        for (let y = sy; y < canvas.height; y += gs)
          for (let x = sx; x < canvas.width; x += gs)
            ctx.fillRect(x - 1, y - 1, 2, 2);

        ctx.save(); ctx.translate(offsetX, offsetY); ctx.scale(zoom, zoom);

        // Edges with bezier curves
        for (const e of edges) {
          const from = nodes.find(n => n.id === e.from);
          const to = nodes.find(n => n.id === e.to);
          if (!from || !to) continue;
          const fx = from.x + NODE_W / 2, fy = from.y + NODE_H;
          const tx = to.x + NODE_W / 2, ty = to.y;
          ctx.beginPath(); ctx.moveTo(fx, fy);
          ctx.bezierCurveTo(fx, fy + 50, tx, ty - 50, tx, ty);
          ctx.strokeStyle = e.label ? 'rgba(78,201,176,0.6)' : 'rgba(137,180,250,0.4)';
          ctx.lineWidth = 2; ctx.stroke();
          // Arrow
          ctx.beginPath(); ctx.moveTo(tx, ty);
          ctx.lineTo(tx - 6, ty - 10); ctx.lineTo(tx + 6, ty - 10); ctx.closePath();
          ctx.fillStyle = e.label ? 'rgba(78,201,176,0.6)' : 'rgba(137,180,250,0.4)'; ctx.fill();
          // Edge label
          if (e.label) {
            ctx.fillStyle = 'rgba(255,255,255,0.6)'; ctx.font = '10px sans-serif'; ctx.textAlign = 'center';
            const mx = (fx + tx) / 2, my = (fy + ty) / 2;
            ctx.fillText(e.label, mx, my);
          }
        }

        // Nodes
        for (const n of nodes) {
          const nt = NODE_TYPES[n.type];
          const isSel = n === selectedNode;

          // Shadow
          ctx.fillStyle = 'rgba(0,0,0,0.25)';
          ctx.beginPath(); ctx.roundRect(n.x + 2, n.y + 2, NODE_W, NODE_H, 6); ctx.fill();

          // Body
          ctx.fillStyle = nt.color;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.fill();

          // Border
          ctx.strokeStyle = isSel ? '#89b4fa' : nt.border;
          ctx.lineWidth = isSel ? 2.5 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.stroke();

          // Type bar
          ctx.fillStyle = nt.border + '30';
          ctx.fillRect(n.x + 1, n.y + 1, NODE_W - 2, 18);

          // Type label + speaker
          ctx.fillStyle = nt.border; ctx.font = 'bold 10px sans-serif'; ctx.textAlign = 'left';
          ctx.fillText(nt.label + (n.speaker ? ': ' + n.speaker : ''), n.x + 8, n.y + 13);

          // Text preview
          ctx.fillStyle = '#ccc'; ctx.font = '11px sans-serif'; ctx.textAlign = 'center';
          const preview = n.text || n.condition || n.action || (n.choices.length ? n.choices.join(' / ') : '...');
          ctx.fillText(preview.substring(0, 24), n.x + NODE_W / 2, n.y + 38);

          // Connection count
          const outC = edges.filter(e => e.from === n.id).length;
          const inC = edges.filter(e => e.to === n.id).length;
          ctx.fillStyle = 'rgba(255,255,255,0.25)'; ctx.font = '9px sans-serif';
          ctx.fillText(inC + ' in / ' + outC + ' out', n.x + NODE_W / 2, n.y + 54);

          // Connect dot
          if (connectMode) {
            ctx.fillStyle = 'rgba(250,179,135,0.6)';
            ctx.beginPath(); ctx.arc(n.x + NODE_W / 2, n.y + NODE_H, 5, 0, Math.PI * 2); ctx.fill();
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

      // ── Properties ─────────────────────────────────────
      function showProps(node) {
        const el = document.getElementById('propsContent');
        const cel = document.getElementById('connsContent');
        const prev = document.getElementById('previewArea');
        if (!node) {
          el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:8px;">Select a dialog node.</p>';
          cel.innerHTML = '';
          prev.innerHTML = 'Select a node to preview dialog.';
          return;
        }

        const nt = NODE_TYPES[node.type];
        let html = '<div style="margin-bottom:6px"><span class="type-badge" style="background:' + nt.border + '30;color:' + nt.border + '">' + nt.label + '</span></div>';

        if (node.type === 'npc' || node.type === 'choice') {
          html += '<div class="prop-field"><label>Speaker</label><input id="pSpeaker" value="' + node.speaker + '"></div>';
          html += '<div class="prop-field"><label>Dialog Text</label><textarea id="pText">' + node.text + '</textarea></div>';
        }
        if (node.type === 'choice') {
          html += '<div class="prop-field"><label>Choices</label><div id="choiceList">';
          node.choices.forEach((c, i) => {
            html += '<div class="choice-item"><input value="' + c + '" data-ci="' + i + '"><button class="icon-btn" data-delc="' + i + '" title="Remove">${ICONS.trash}</button></div>';
          });
          html += '</div><button id="btnAddChoiceItem" style="width:100%;margin-top:4px;font-size:11px;">${ICONS.add} Add Choice</button></div>';
        }
        if (node.type === 'condition') {
          html += '<div class="prop-field"><label>Condition Expression</label><textarea id="pCondition">' + node.condition + '</textarea></div>';
        }
        if (node.type === 'action') {
          html += '<div class="prop-field"><label>Action Script</label><textarea id="pAction">' + node.action + '</textarea></div>';
        }
        el.innerHTML = html;

        // Bind property inputs
        const bind = (id, key) => {
          const inp = document.getElementById(id);
          if (inp) inp.addEventListener('input', (ev) => { pushUndo(); node[key] = ev.target.value; render(); updatePreview(node); });
        };
        bind('pSpeaker', 'speaker'); bind('pText', 'text'); bind('pCondition', 'condition'); bind('pAction', 'action');

        el.querySelectorAll('[data-ci]').forEach(inp => {
          inp.addEventListener('input', (ev) => { pushUndo(); node.choices[parseInt(ev.target.dataset.ci)] = ev.target.value; render(); });
        });
        el.querySelectorAll('[data-delc]').forEach(btn => {
          btn.addEventListener('click', (ev) => { pushUndo(); node.choices.splice(parseInt(ev.currentTarget.dataset.delc), 1); showProps(node); render(); });
        });
        const addBtn = document.getElementById('btnAddChoiceItem');
        if (addBtn) addBtn.addEventListener('click', () => { pushUndo(); node.choices.push('Option'); showProps(node); render(); });

        // Connections
        const outEdges = edges.filter(e => e.from === node.id);
        const inEdges = edges.filter(e => e.to === node.id);
        let chtml = '';
        if (outEdges.length) {
          chtml += '<div style="font-size:10px;color:var(--text-dim);margin-bottom:2px">OUTGOING</div>';
          for (const e of outEdges) {
            const t = nodes.find(n => n.id === e.to);
            chtml += '<div class="conn-item"><span class="arrow">→</span><span class="target">' + (t ? (NODE_TYPES[t.type].label + ': ' + (t.speaker || t.text || '...').substring(0, 16)) : '?') + '</span>';
            if (e.label) chtml += '<span style="font-size:9px;color:var(--accent-2)">' + e.label + '</span>';
            chtml += '<button class="icon-btn" data-del-edge="' + e.from + '-' + e.to + '">${ICONS.trash}</button></div>';
          }
        }
        if (inEdges.length) {
          chtml += '<div style="font-size:10px;color:var(--text-dim);margin:4px 0 2px">INCOMING</div>';
          for (const e of inEdges) {
            const f = nodes.find(n => n.id === e.from);
            chtml += '<div class="conn-item"><span class="arrow">←</span><span class="target">' + (f ? (NODE_TYPES[f.type].label + ': ' + (f.speaker || f.text || '...').substring(0, 16)) : '?') + '</span></div>';
          }
        }
        if (!outEdges.length && !inEdges.length) chtml = '<p style="color:var(--text-dim);font-size:11px">No connections</p>';
        cel.innerHTML = chtml;

        cel.querySelectorAll('[data-del-edge]').forEach(btn => {
          btn.addEventListener('click', (ev) => {
            const [from, to] = ev.currentTarget.dataset.delEdge.split('-').map(Number);
            pushUndo();
            edges = edges.filter(ed => !(ed.from === from && ed.to === to));
            showProps(node); updateStatus(); render();
          });
        });

        updatePreview(node);
      }

      function updatePreview(node) {
        const prev = document.getElementById('previewArea');
        if (!node) { prev.innerHTML = ''; return; }
        if (node.type === 'npc' || node.type === 'choice') {
          let h = '<div style="text-align:left">';
          if (node.speaker) h += '<div style="font-weight:600;color:var(--accent);margin-bottom:2px">' + node.speaker + '</div>';
          h += '<div style="color:var(--text);font-style:italic">"' + (node.text || '...') + '"</div>';
          if (node.type === 'choice' && node.choices.length) {
            h += '<div style="margin-top:6px;border-top:1px solid var(--border);padding-top:4px">';
            node.choices.forEach((c, i) => { h += '<div style="color:var(--accent-2);cursor:pointer;padding:2px 0">' + (i+1) + '. ' + c + '</div>'; });
            h += '</div>';
          }
          h += '</div>';
          prev.innerHTML = h;
        } else if (node.type === 'condition') {
          prev.innerHTML = '<div style="text-align:left;font-family:var(--font-mono);font-size:11px">if ' + (node.condition || '...') + ' then<br>&nbsp;&nbsp;→ true branch<br>else<br>&nbsp;&nbsp;→ false branch</div>';
        } else if (node.type === 'action') {
          prev.innerHTML = '<div style="text-align:left;font-family:var(--font-mono);font-size:11px">' + (node.action || '-- no action') + '</div>';
        }
      }

      function updateStatus() {
        document.getElementById('statusNodes').textContent = nodes.length + ' nodes';
        document.getElementById('statusConns').textContent = edges.length + ' connections';
        document.getElementById('statusMode').textContent = connectMode ? 'Connect' : 'Select';
        document.getElementById('statusZoom').textContent = Math.round(zoom * 100) + '%';
      }

      // ── Canvas Events ──────────────────────────────────
      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) { isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY; canvas.style.cursor = 'grabbing'; return; }
        const node = hitTest(e.offsetX, e.offsetY);
        if (connectMode && e.button === 0) {
          if (!connectFrom && node) { connectFrom = node; }
          else if (connectFrom && node && node !== connectFrom) {
            if (!edges.find(ed => ed.from === connectFrom.id && ed.to === node.id)) {
              const label = connectFrom.type === 'choice' && connectFrom.choices.length > 0
                ? connectFrom.choices[edges.filter(ed => ed.from === connectFrom.id).length] || ''
                : '';
              pushUndo();
              edges.push({ from: connectFrom.id, to: node.id, label });
            }
            connectFrom = null; updateStatus(); render();
          } else { connectFrom = null; }
          return;
        }
        if (node) {
          selectedNode = node; showProps(node);
          dragNode = node;
          dragOff = { x: (e.offsetX - offsetX) / zoom - node.x, y: (e.offsetY - offsetY) / zoom - node.y };
        } else { selectedNode = null; showProps(null); }
        render();
      });

      canvas.addEventListener('mousemove', (e) => {
        if (isPanning) { offsetX = e.clientX - panSX; offsetY = e.clientY - panSY; render(); return; }
        if (dragNode) {
          dragNode.x = Math.round(((e.offsetX - offsetX) / zoom - dragOff.x) / 20) * 20;
          dragNode.y = Math.round(((e.offsetY - offsetY) / zoom - dragOff.y) / 20) * 20;
          render();
        }
      });
      canvas.addEventListener('mouseup', () => { isPanning = false; dragNode = null; canvas.style.cursor = ''; });

      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const old = zoom; zoom *= e.deltaY < 0 ? 1.1 : 0.9; zoom = Math.max(0.2, Math.min(4, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / old;
        offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / old;
        updateStatus(); render();
      }, { passive: false });

      // ── Toolbar ────────────────────────────────────────
      document.getElementById('btnAddNpc').addEventListener('click', () => addNode('npc'));
      document.getElementById('btnAddChoice').addEventListener('click', () => addNode('choice'));
      document.getElementById('btnAddCondition').addEventListener('click', () => addNode('condition'));
      document.getElementById('btnAddAction').addEventListener('click', () => addNode('action'));
      document.getElementById('btnConnect').addEventListener('click', () => {
        connectMode = !connectMode; connectFrom = null;
        document.getElementById('btnConnect').classList.toggle('active', connectMode);
        updateStatus();
      });
      document.getElementById('btnDelete').addEventListener('click', () => {
        if (!selectedNode) return;
        pushUndo();
        edges = edges.filter(e => e.from !== selectedNode.id && e.to !== selectedNode.id);
        nodes = nodes.filter(n => n !== selectedNode);
        selectedNode = null; showProps(null); updateStatus(); render();
      });
      document.getElementById('btnUndo').addEventListener('click', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      document.getElementById('btnRedo').addEventListener('click', () => { const s = undo.redo(); if (s) restoreSnap(s); });

      document.getElementById('btnAutoLayout').addEventListener('click', () => {
        if (nodes.length === 0) return;
        pushUndo();
        const placed = new Set();
        function placeTree(id, col, row) {
          if (placed.has(id)) return row;
          placed.add(id);
          const n = nodes.find(nd => nd.id === id);
          if (!n) return row;
          n.x = col * (NODE_W + 60) + 40;
          n.y = row * (NODE_H + 50) + 40;
          const outs = edges.filter(e => e.from === id);
          let nextRow = row;
          for (const e of outs) { nextRow = placeTree(e.to, col + 1, nextRow); nextRow++; }
          return Math.max(row, nextRow);
        }
        const hasIncoming = new Set(edges.map(e => e.to));
        const roots = nodes.filter(n => !hasIncoming.has(n.id));
        if (roots.length === 0) roots.push(nodes[0]);
        let row = 0;
        for (const r of roots) { row = placeTree(r.id, 0, row); row++; }
        nodes.forEach((n, i) => { if (!placed.has(n.id)) { n.x = 40; n.y = (placed.size + i) * (NODE_H + 50) + 40; placed.add(n.id); } });
        render();
      });

      document.getElementById('btnFitView').addEventListener('click', () => {
        if (nodes.length === 0) return;
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        for (const n of nodes) { minX = Math.min(minX, n.x); minY = Math.min(minY, n.y); maxX = Math.max(maxX, n.x + NODE_W); maxY = Math.max(maxY, n.y + NODE_H); }
        const pad = 60, w = maxX - minX + pad * 2, h = maxY - minY + pad * 2;
        zoom = Math.min(canvas.width / w, canvas.height / h, 2);
        offsetX = (canvas.width - w * zoom) / 2 - minX * zoom + pad * zoom;
        offsetY = (canvas.height - h * zoom) / 2 - minY * zoom + pad * zoom;
        updateStatus(); render();
      });

      registerShortcut('c', () => { connectMode = !connectMode; connectFrom = null; document.getElementById('btnConnect').classList.toggle('active', connectMode); updateStatus(); });
      registerShortcut('delete', () => document.getElementById('btnDelete').click());
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });
      registerShortcut('1', () => addNode('npc'));
      registerShortcut('2', () => addNode('choice'));
      registerShortcut('3', () => addNode('condition'));
      registerShortcut('4', () => addNode('action'));

      // ── Export ─────────────────────────────────────────
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Dialog Editor', '-- Usage: local dialog = require("dialog")', ''];
        lines.push('return {');
        for (const n of nodes) {
          let line = '  { id = ' + n.id + ', type = "' + n.type + '"';
          if (n.speaker) line += ', speaker = "' + n.speaker + '"';
          if (n.text) line += ', text = "' + n.text + '"';
          if (n.choices.length) line += ', choices = { "' + n.choices.join('", "') + '" }';
          if (n.condition) line += ', condition = function() return ' + n.condition + ' end';
          if (n.action) line += ', action = function() ' + n.action + ' end';
          const conns = edges.filter(e => e.from === n.id);
          if (conns.length === 1) {
            line += ', next = ' + conns[0].to;
          } else if (conns.length > 1) {
            line += ', next = { ' + conns.map(e => {
              const label = e.label ? '["' + e.label + '"] = ' + e.to : e.to;
              return label;
            }).join(', ') + ' }';
          }
          line += ' },';
          lines.push(line);
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
      addNode('npc', 100, 50); nodes[0].speaker = 'Guard'; nodes[0].text = 'Halt! Who goes there?';
      addNode('choice', 100, 180); nodes[1].text = 'Response'; nodes[1].choices = ['I am a friend', 'None of your business'];
      addNode('npc', 50, 310); nodes[2].speaker = 'Guard'; nodes[2].text = 'Welcome, friend.';
      addNode('action', 300, 310); nodes[3].action = 'start_combat()';
      edges.push({ from: 1, to: 2, label: '' }, { from: 2, to: 3, label: 'Friend' }, { from: 2, to: 4, label: 'Hostile' });
      undo.clear();
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `);
  }
}