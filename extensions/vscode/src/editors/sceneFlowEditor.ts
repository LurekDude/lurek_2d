import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

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
      .status-bar { grid-column: 1 / -1; }
      .canvas-area { position: relative; overflow: hidden; background: var(--bg); }
      .canvas-area canvas { display: block; }
      .props-panel { grid-row: 2; overflow-y: auto; background: var(--surface); border-left: 1px solid var(--border); }

      .scene-prop { margin-bottom: 3px; }
      .scene-prop label {
        font-size: 10px; text-transform: uppercase; letter-spacing: 0.3px;
        color: var(--text-dim); display: block; margin-bottom: 1px;
      }
      .scene-prop input, .scene-prop textarea {
        width: 100%; font-size: 12px;
      }
      .scene-prop textarea { height: 48px; resize: vertical; font-family: var(--font-mono); font-size: 11px; }

      .transition-item {
        display: flex; align-items: center; gap: 4px; font-size: 11px;
        padding: 3px 6px; border-radius: var(--radius); margin-bottom: 2px;
      }
      .transition-item:hover { background: var(--hover); }
      .transition-item .arrow { color: var(--accent); }
      .transition-item .target { flex: 1; }

      .minimap {
        border: 1px solid var(--border); border-radius: var(--radius); background: var(--bg);
        margin: 0 8px; height: 100px; position: relative; overflow: hidden;
      }
    `, `
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group">
            ${iconButton('add', { id: 'btnAdd', title: 'Add Scene (A)' })}
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
        <div class="canvas-area"><canvas id="flowCanvas"></canvas></div>

        <!-- Properties Panel -->
        <div class="props-panel">
          ${panelSection('Scene Properties', '<div id="propsContent"><p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:8px;">Select a scene node.</p></div>')}
          ${panelSection('Transitions', '<div id="transContent"></div>', true)}
          ${panelSection('Minimap', '<div class="minimap"><canvas id="minimapCanvas" width="200" height="100"></canvas></div>', true)}
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span class="status-group">
            <span id="statusScenes" class="badge">0 scenes</span>
          </span>
          <div class="sep"></div>
          <span id="statusTransitions">0 transitions</span>
          <div class="sep"></div>
          <span id="statusMode">Select</span>
          <div class="spacer"></div>
          <span id="statusZoom">100%</span>
          <div class="sep"></div>
          <span class="dirty-indicator">${ICONS.clean}</span>
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
      const undo = new UndoStack(60);

      const NODE_W = 140, NODE_H = 54;
      const NODE_COLORS = ['#264f78','#2d4a22','#4a3222','#3c2244','#443322','#224a4a'];

      function snapshot() { return JSON.parse(JSON.stringify({ nodes, edges, nextId })); }
      function restoreSnap(s) { nodes = s.nodes; edges = s.edges; nextId = s.nextId; selectedNode = null; showProps(null); updateStatus(); render(); }
      function pushUndo() { undo.push(snapshot()); markDirty(); }

      function addNode(name, x, y) {
        pushUndo();
        nodes.push({
          id: nextId++, name: name || 'Scene_' + nodes.length,
          x: x !== undefined ? x : 100 + nodes.length * 40, y: y !== undefined ? y : 100 + nodes.length * 40,
          onEnter: '', onExit: '', onProcess: '', onRender: '',
          color: NODE_COLORS[nodes.length % NODE_COLORS.length]
        });
        updateStatus(); render();
      }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth; canvas.height = area.clientHeight;
        render();
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

        // Edges
        for (const e of edges) {
          const from = nodes.find(n => n.id === e.from);
          const to = nodes.find(n => n.id === e.to);
          if (!from || !to) continue;
          const fx = from.x + NODE_W/2, fy = from.y + NODE_H/2;
          const tx = to.x + NODE_W/2, ty = to.y + NODE_H/2;

          // Curved line
          const mx = (fx+tx)/2, my = (fy+ty)/2;
          const dx = tx-fx, dy = ty-fy;
          const len = Math.sqrt(dx*dx+dy*dy);
          const cx = mx + (fy-ty)*0.15, cy = my + (tx-fx)*0.15;

          ctx.beginPath(); ctx.moveTo(fx, fy); ctx.quadraticCurveTo(cx, cy, tx, ty);
          ctx.strokeStyle = 'rgba(137,180,250,0.4)'; ctx.lineWidth = 2; ctx.stroke();

          // Arrow
          const t = 0.85;
          const px = (1-t)*(1-t)*fx + 2*(1-t)*t*cx + t*t*tx;
          const py = (1-t)*(1-t)*fy + 2*(1-t)*t*cy + t*t*ty;
          const px2 = (1-0.84)*(1-0.84)*fx + 2*(1-0.84)*0.84*cx + 0.84*0.84*tx;
          const py2 = (1-0.84)*(1-0.84)*fy + 2*(1-0.84)*0.84*cy + 0.84*0.84*ty;
          const angle = Math.atan2(py-py2, px-px2);
          ctx.beginPath();
          ctx.moveTo(px + 6*Math.cos(angle), py + 6*Math.sin(angle));
          ctx.lineTo(px - 8*Math.cos(angle-0.5), py - 8*Math.sin(angle-0.5));
          ctx.lineTo(px - 8*Math.cos(angle+0.5), py - 8*Math.sin(angle+0.5));
          ctx.closePath(); ctx.fillStyle = 'rgba(137,180,250,0.5)'; ctx.fill();
        }

        // Connection preview
        if (connectMode && connectFrom) {
          ctx.strokeStyle = 'rgba(250,179,135,0.5)'; ctx.lineWidth = 2; ctx.setLineDash([6,4]);
          ctx.beginPath(); ctx.moveTo(connectFrom.x+NODE_W/2, connectFrom.y+NODE_H/2);
          // We'll draw to mouse in render — but we don't track mouse in render directly, skip
          ctx.setLineDash([]);
        }

        // Nodes
        for (const n of nodes) {
          const isSel = n === selectedNode;

          // Shadow
          ctx.fillStyle = 'rgba(0,0,0,0.3)';
          ctx.beginPath(); ctx.roundRect(n.x+2, n.y+2, NODE_W, NODE_H, 6); ctx.fill();

          // Body
          ctx.fillStyle = n.color;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.fill();

          // Border
          ctx.strokeStyle = isSel ? '#89b4fa' : 'rgba(255,255,255,0.1)';
          ctx.lineWidth = isSel ? 2.5 : 1;
          ctx.beginPath(); ctx.roundRect(n.x, n.y, NODE_W, NODE_H, 6); ctx.stroke();

          // Title
          ctx.fillStyle = '#e0e0e0'; ctx.font = 'bold 12px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
          ctx.fillText(n.name, n.x + NODE_W/2, n.y + NODE_H/2 - 6);

          // Subtitle (connection count)
          const outCount = edges.filter(e => e.from === n.id).length;
          const inCount = edges.filter(e => e.to === n.id).length;
          ctx.fillStyle = 'rgba(255,255,255,0.35)'; ctx.font = '10px sans-serif';
          ctx.fillText(inCount + ' in / ' + outCount + ' out', n.x + NODE_W/2, n.y + NODE_H/2 + 10);

          // Connect indicator
          if (connectMode) {
            ctx.fillStyle = 'rgba(250,179,135,0.6)';
            ctx.beginPath(); ctx.arc(n.x + NODE_W, n.y + NODE_H/2, 5, 0, Math.PI*2); ctx.fill();
          }
        }
        ctx.restore();
        renderMinimap();
      }

      function renderMinimap() {
        const mc = document.getElementById('minimapCanvas');
        if (!mc) return;
        const mctx = mc.getContext('2d');
        mctx.clearRect(0, 0, 200, 100);
        if (nodes.length === 0) return;
        let minX=Infinity,minY=Infinity,maxX=-Infinity,maxY=-Infinity;
        for (const n of nodes) { minX=Math.min(minX,n.x); minY=Math.min(minY,n.y); maxX=Math.max(maxX,n.x+NODE_W); maxY=Math.max(maxY,n.y+NODE_H); }
        const pad=20, w=maxX-minX+pad*2, h=maxY-minY+pad*2;
        const s = Math.min(200/w, 100/h);
        const ox = (200-w*s)/2 - minX*s + pad*s, oy = (100-h*s)/2 - minY*s + pad*s;
        for (const e of edges) {
          const from=nodes.find(n=>n.id===e.from), to=nodes.find(n=>n.id===e.to);
          if(!from||!to)continue;
          mctx.beginPath(); mctx.moveTo(from.x*s+ox+NODE_W*s/2, from.y*s+oy+NODE_H*s/2);
          mctx.lineTo(to.x*s+ox+NODE_W*s/2, to.y*s+oy+NODE_H*s/2);
          mctx.strokeStyle='rgba(137,180,250,0.3)'; mctx.lineWidth=1; mctx.stroke();
        }
        for (const n of nodes) {
          mctx.fillStyle = n===selectedNode ? '#89b4fa' : n.color;
          mctx.fillRect(n.x*s+ox, n.y*s+oy, NODE_W*s, NODE_H*s);
        }
      }

      // ── Hit Test & Interaction ─────────────────────────
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
        const tel = document.getElementById('transContent');
        if (!node) {
          el.innerHTML = '<p style="color:var(--text-dim);font-size:12px;text-align:center;margin-top:8px;">Select a scene node.</p>';
          tel.innerHTML = '';
          return;
        }
        el.innerHTML =
          '<div class="scene-prop"><label>Name</label><input id="pName" value="' + node.name + '"></div>' +
          '<div class="scene-prop"><label>Color</label><input type="color" id="pColor" value="' + node.color + '" style="width:28px;height:22px;border:1px solid var(--border);border-radius:var(--radius);padding:0"></div>' +
          '<div class="scene-prop"><label>onEnter</label><textarea id="pEnter">' + node.onEnter + '</textarea></div>' +
          '<div class="scene-prop"><label>onExit</label><textarea id="pExit">' + node.onExit + '</textarea></div>' +
          '<div class="scene-prop"><label>onProcess</label><textarea id="pProcess">' + node.onProcess + '</textarea></div>' +
          '<div class="scene-prop"><label>onRender</label><textarea id="pRender">' + node.onRender + '</textarea></div>';

        const bind = (id, key) => {
          document.getElementById(id).addEventListener('input', (e) => {
            pushUndo(); node[key] = e.target.value;
            if (key === 'name' || key === 'color') render();
          });
        };
        bind('pName','name'); bind('pColor','color'); bind('pEnter','onEnter');
        bind('pExit','onExit'); bind('pProcess','onProcess'); bind('pRender','onRender');

        // Transitions list
        const outEdges = edges.filter(e => e.from === node.id);
        const inEdges = edges.filter(e => e.to === node.id);
        let thtml = '';
        if (outEdges.length) {
          thtml += '<div style="font-size:10px;color:var(--text-dim);margin-bottom:2px">OUTGOING</div>';
          for (const e of outEdges) {
            const t = nodes.find(n => n.id === e.to);
            thtml += '<div class="transition-item"><span class="arrow">→</span><span class="target">' + (t ? t.name : '?') + '</span><button class="icon-btn" data-del-edge="' + e.from + '-' + e.to + '">${ICONS.trash}</button></div>';
          }
        }
        if (inEdges.length) {
          thtml += '<div style="font-size:10px;color:var(--text-dim);margin:4px 0 2px">INCOMING</div>';
          for (const e of inEdges) {
            const f = nodes.find(n => n.id === e.from);
            thtml += '<div class="transition-item"><span class="arrow">←</span><span class="target">' + (f ? f.name : '?') + '</span></div>';
          }
        }
        if (!outEdges.length && !inEdges.length) thtml = '<p style="color:var(--text-dim);font-size:11px">No transitions</p>';
        tel.innerHTML = thtml;

        tel.querySelectorAll('[data-del-edge]').forEach(btn => {
          btn.addEventListener('click', (e) => {
            const [from, to] = e.currentTarget.dataset.delEdge.split('-').map(Number);
            pushUndo();
            edges = edges.filter(ed => !(ed.from === from && ed.to === to));
            showProps(node); updateStatus(); render();
          });
        });
      }

      function updateStatus() {
        document.getElementById('statusScenes').textContent = nodes.length + ' scenes';
        document.getElementById('statusTransitions').textContent = edges.length + ' transitions';
        document.getElementById('statusMode').textContent = connectMode ? 'Connect' : 'Select';
        document.getElementById('statusZoom').textContent = Math.round(zoom * 100) + '%';
      }

      // ── Canvas Events ──────────────────────────────────
      canvas.addEventListener('mousedown', (e) => {
        if (e.button === 1 || (e.altKey && e.button === 0)) {
          isPanning = true; panSX = e.clientX - offsetX; panSY = e.clientY - offsetY;
          canvas.style.cursor = 'grabbing'; return;
        }
        const node = hitTest(e.offsetX, e.offsetY);
        if (connectMode && e.button === 0) {
          if (!connectFrom && node) { connectFrom = node; }
          else if (connectFrom && node && node !== connectFrom) {
            if (!edges.find(ed => ed.from === connectFrom.id && ed.to === node.id)) {
              pushUndo();
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
          pushUndo();
          dragNode.x = Math.round(((e.offsetX - offsetX) / zoom - dragOff.x) / 20) * 20;
          dragNode.y = Math.round(((e.offsetY - offsetY) / zoom - dragOff.y) / 20) * 20;
          render();
        }
      });

      canvas.addEventListener('mouseup', () => { isPanning = false; dragNode = null; canvas.style.cursor = ''; });

      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const old = zoom;
        zoom *= e.deltaY < 0 ? 1.1 : 0.9;
        zoom = Math.max(0.2, Math.min(4, zoom));
        offsetX = e.offsetX - (e.offsetX - offsetX) * zoom / old;
        offsetY = e.offsetY - (e.offsetY - offsetY) * zoom / old;
        updateStatus(); render();
      }, { passive: false });

      // ── Toolbar ────────────────────────────────────────
      document.getElementById('btnAdd').addEventListener('click', () => addNode());
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
        // Simple left-to-right layout by topological order
        const placed = new Set();
        let col = 0;
        function placeFrom(id, row) {
          if (placed.has(id)) return;
          placed.add(id);
          const n = nodes.find(nd => nd.id === id);
          if (!n) return;
          n.x = col * (NODE_W + 60) + 40; n.y = row * (NODE_H + 40) + 40;
          const outs = edges.filter(e => e.from === id);
          outs.forEach((e, i) => { col++; placeFrom(e.to, i); });
        }
        // Start from nodes with no incoming edges
        const hasIncoming = new Set(edges.map(e => e.to));
        const roots = nodes.filter(n => !hasIncoming.has(n.id));
        if (roots.length === 0 && nodes.length > 0) roots.push(nodes[0]);
        roots.forEach((r, i) => { col = 0; placeFrom(r.id, i * 3); });
        // Place any remaining
        nodes.forEach((n, i) => { if (!placed.has(n.id)) { n.x = 40; n.y = (placed.size + i) * (NODE_H + 40) + 40; placed.add(n.id); } });
        render();
      });
      document.getElementById('btnFitView').addEventListener('click', () => {
        if (nodes.length === 0) return;
        let minX=Infinity,minY=Infinity,maxX=-Infinity,maxY=-Infinity;
        for (const n of nodes) { minX=Math.min(minX,n.x); minY=Math.min(minY,n.y); maxX=Math.max(maxX,n.x+NODE_W); maxY=Math.max(maxY,n.y+NODE_H); }
        const pad=60, w=maxX-minX+pad*2, h=maxY-minY+pad*2;
        zoom = Math.min(canvas.width/w, canvas.height/h, 2);
        offsetX = (canvas.width - w*zoom)/2 - minX*zoom + pad*zoom;
        offsetY = (canvas.height - h*zoom)/2 - minY*zoom + pad*zoom;
        updateStatus(); render();
      });

      registerShortcut('a', () => addNode());
      registerShortcut('c', () => { connectMode = !connectMode; connectFrom = null; document.getElementById('btnConnect').classList.toggle('active', connectMode); updateStatus(); });
      registerShortcut('delete', () => document.getElementById('btnDelete').click());
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) restoreSnap(s); });
      registerShortcut('ctrl+y', () => { const s = undo.redo(); if (s) restoreSnap(s); });

      // ── Export ─────────────────────────────────────────
      function buildLuaCode() {
        const lines = ['-- Generated by Lurek2D Scene Flow Editor', '-- Usage: lurek.scene.load(scenes)', ''];
        lines.push('return {');
        for (const n of nodes) {
          let line = '  { name = "' + n.name + '"';
          if (n.onEnter) line += ', on_enter = function() ' + n.onEnter + ' end';
          if (n.onExit) line += ', on_exit = function() ' + n.onExit + ' end';
          if (n.onProcess) line += ', on_process = function(dt) ' + n.onProcess + ' end';
          if (n.onRender) line += ', on_render = function() ' + n.onRender + ' end';
          const trans = edges.filter(e => e.from === n.id).map(e => {
            const target = nodes.find(nd => nd.id === e.to);
            return target ? '"' + target.name + '"' : '';
          }).filter(Boolean);
          if (trans.length) line += ', transitions = { ' + trans.join(', ') + ' }';
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
      addNode('Title', 80, 80);
      addNode('Gameplay', 300, 80);
      addNode('GameOver', 520, 80);
      edges.push({ from: 1, to: 2 }, { from: 2, to: 3 });
      undo.clear();
      updateStatus();
      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
    `);
  }
}
