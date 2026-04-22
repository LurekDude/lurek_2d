import * as vscode from "vscode";
import * as path from "path";
import * as fs from "fs";
import {
  findApiSymbolLine,
  listApiEntries,
  resolveWorkspaceApiDocPath,
} from "../services/apiDocs.js";

/**
 * Browse the API via quick-pick. Shows known lurek.* functions from
 * the generated API reference if available.
 */
export async function browseApi(): Promise<void> {
  const root = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  if (!root) {
    vscode.window.showErrorMessage("No workspace folder open.");
    return;
  }

  const apiPath = resolveWorkspaceApiDocPath(root);
  if (!apiPath || !fs.existsSync(apiPath)) {
    vscode.window.showWarningMessage(
      "API reference not found. Expected docs/api/lurek.lua or docs/api/lurek.md."
    );
    return;
  }

  const content = fs.readFileSync(apiPath, "utf-8");
  const entries = listApiEntries(content, apiPath);

  if (entries.length === 0) {
    vscode.window.showInformationMessage("No API entries found.");
    return;
  }

  const picked = await vscode.window.showQuickPick(entries.map((entry) => ({
    label: entry.label,
    description: entry.kind,
    line: entry.line,
  })), {
    placeHolder: "Search Lurek2D API...",
    matchOnDescription: true,
  });

  if (picked) {
    const doc = await vscode.workspace.openTextDocument(apiPath);
    const editor = await vscode.window.showTextDocument(doc);
    const lineIndex = typeof picked.line === "number"
      ? picked.line
      : findApiSymbolLine(content, apiPath, picked.label);
    if (lineIndex >= 0) {
      const pos = new vscode.Position(lineIndex, 0);
      editor.selection = new vscode.Selection(pos, pos);
      editor.revealRange(new vscode.Range(pos, pos));
    }
  }
}

/**
 * Opens the generated Lua API documentation markdown file.
 */
export async function openApiDocs(): Promise<void> {
  const root = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  if (!root) {
    vscode.window.showErrorMessage("No workspace folder open.");
    return;
  }

  const apiPath = resolveWorkspaceApiDocPath(root);
  if (!apiPath || !fs.existsSync(apiPath)) {
    vscode.window.showWarningMessage(
      "API reference not found. Expected docs/api/lurek.lua or docs/api/lurek.md."
    );
    return;
  }

  const doc = await vscode.workspace.openTextDocument(apiPath);
  await vscode.window.showTextDocument(doc);
}

/**
 * Opens API docs for the lurek.* symbol under the cursor, or browses
 * the full reference if no symbol is found.
 */
export async function openWiki(): Promise<void> {
  const editor = vscode.window.activeTextEditor;

  const wordRange = editor?.document.getWordRangeAtPosition(
    editor.selection.active,
    /lurek\.[a-zA-Z0-9_.]+/
  );
  const symbol = wordRange ? editor!.document.getText(wordRange) : undefined;

  const root = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  if (!root) { vscode.window.showErrorMessage("No workspace folder open."); return; }

  const docPath = resolveWorkspaceApiDocPath(root) ?? null;

  if (docPath) {
    const content = fs.readFileSync(docPath, "utf-8");

    if (symbol) {
      const lineIndex = findApiSymbolLine(content, docPath, symbol);
      const doc = await vscode.workspace.openTextDocument(docPath);
      const editorDoc = await vscode.window.showTextDocument(doc);
      const pos = new vscode.Position(Math.max(0, lineIndex), 0);
      editorDoc.selection = new vscode.Selection(pos, pos);
      editorDoc.revealRange(new vscode.Range(pos, pos), vscode.TextEditorRevealType.InCenter);
      if (lineIndex < 0) {
        vscode.window.showInformationMessage(`"${symbol}" not found in API docs — showing full reference.`);
      }
    } else {
      const doc = await vscode.workspace.openTextDocument(docPath);
      await vscode.window.showTextDocument(doc);
    }
  } else {
    // Fallback: quick-pick browse
    await browseApi();
  }
}

/**
 * Shows an interactive Lurek2D module dependency graph in a webview panel.
 * Reads the actual src/ directory structure to discover modules and
 * parses use crate:: statements to derive real edges.
 */
export function depGraph(context: vscode.ExtensionContext): void {
  const root = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  const panel = vscode.window.createWebviewPanel(
    "lurek.depGraph",
    "Lurek2D Module Dependency Graph",
    vscode.ViewColumn.One,
    { enableScripts: true, retainContextWhenHidden: true }
  );

  // Discover modules from src/ directory
  interface NodeDef { id: string; tier: string; }
  interface EdgeDef { from: string; to: string; }
  const nodes: NodeDef[] = [];
  const edges: EdgeDef[] = [];

  const tiers: Record<string, string> = {
    math: "leaf",
    engine: "core",
    lua_api: "integration",
    window: "core",
    graphics: "domain",
    physics: "domain",
    audio: "domain",
    input: "domain",
    timer: "domain",
    filesystem: "domain",
    tilemap: "domain",
    sound: "domain",
    ai: "domain",
    compute: "domain",
    data: "domain",
    dataframe: "domain",
    entity: "domain",
    event: "domain",
    graph: "domain",
    image: "domain",
    modding: "domain",
    particle: "domain",
    savegame: "domain",
    scene: "domain",
    stats: "domain",
    thread: "domain",
    pathfinding: "domain",
    dialog: "domain",
    cardgame: "domain",
    combat: "domain",
    crafting: "domain",
    inventory: "domain",
    quest: "domain",
    resource: "domain",
  };

  if (root) {
    const srcDir = path.join(root, "src");
    if (fs.existsSync(srcDir)) {
      const dirs = fs.readdirSync(srcDir, { withFileTypes: true })
        .filter((e) => e.isDirectory())
        .map((e) => e.name);

      for (const dir of dirs) {
        nodes.push({ id: dir, tier: tiers[dir] ?? "domain" });
      }

      // Parse use crate:: imports to build edges
      for (const dir of dirs) {
        const modFile = path.join(srcDir, dir, "mod.rs");
        const libFile = path.join(srcDir, dir, "lib.rs");
        const candidate = fs.existsSync(modFile) ? modFile : fs.existsSync(libFile) ? libFile : null;
        if (!candidate) continue;

        try {
          const src = fs.readFileSync(candidate, "utf-8");
          const matches = [...src.matchAll(/use crate::([a-z_]+)/g)];
          const seen = new Set<string>();
          for (const m of matches) {
            const dep = m[1];
            if (dep !== dir && dirs.includes(dep) && !seen.has(dep)) {
              seen.add(dep);
              edges.push({ from: dir, to: dep });
            }
          }
        } catch { /* skip unreadable files */ }
      }
    }
  }

  // Fall back to canonical architecture if no src found
  if (nodes.length === 0) {
    for (const [id, tier] of Object.entries(tiers)) {
      nodes.push({ id, tier });
    }
    const archEdges: EdgeDef[] = [
      { from: "engine", to: "math" }, { from: "render", to: "math" },
      { from: "physics", to: "math" }, { from: "audio", to: "math" },
      { from: "input", to: "math" }, { from: "timer", to: "math" },
      { from: "lua_api", to: "engine" }, { from: "lua_api", to: "render" },
      { from: "lua_api", to: "physics" }, { from: "lua_api", to: "audio" },
      { from: "lua_api", to: "input" }, { from: "lua_api", to: "timer" },
      { from: "lua_api", to: "filesystem" }, { from: "lua_api", to: "tilemap" },
      { from: "lua_api", to: "ai" }, { from: "lua_api", to: "ecs" },
      { from: "lua_api", to: "scene" }, { from: "lua_api", to: "particle" },
    ];
    edges.push(...archEdges);
  }

  const nonce = getNonce();
  const nodesJson = JSON.stringify(nodes);
  const edgesJson = JSON.stringify(edges);

  panel.webview.html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'nonce-${nonce}'; style-src 'nonce-${nonce}';">
<title>Module Dependency Graph</title>
<style nonce="${nonce}">
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: var(--vscode-font-family); background: var(--vscode-editor-background); color: var(--vscode-foreground); overflow: hidden; height: 100vh; }
  #toolbar { display: flex; align-items: center; gap: 10px; padding: 8px 12px; border-bottom: 1px solid var(--vscode-panel-border,#444); flex-wrap: wrap; font-size: 12px; }
  #toolbar button { font-size: 11px; padding: 3px 10px; background: var(--vscode-button-background); color: var(--vscode-button-foreground); border: none; border-radius: 3px; cursor: pointer; }
  #toolbar button:hover { background: var(--vscode-button-hoverBackground); }
  #info { flex: 1; opacity: .6; }
  canvas { display: block; }
  #legend { display: flex; gap: 12px; align-items: center; }
  .dot { width: 10px; height: 10px; border-radius: 50%; display: inline-block; margin-right: 3px; }
  .dot.leaf { background: #4ec9b0; }
  .dot.core { background: #569cd6; }
  .dot.integration { background: #dcdcaa; }
  .dot.domain { background: #9cdcfe; }
  #tooltip { position: fixed; background: var(--vscode-editorHoverWidget-background,#252526); border: 1px solid var(--vscode-panel-border,#444); border-radius: 4px; padding: 6px 10px; font-size: 11px; pointer-events: none; display: none; max-width: 220px; }
</style>
</head>
<body>
<div id="toolbar">
  <button id="btnLayout">Re-layout</button>
  <button id="btnZoomIn">＋ Zoom</button>
  <button id="btnZoomOut">－ Zoom</button>
  <button id="btnReset">Reset View</button>
  <div id="legend">
    <span class="dot leaf"></span>Leaf
    <span class="dot core"></span>Core
    <span class="dot integration"></span>Integration
    <span class="dot domain"></span>Domain
  </div>
  <div id="info">Click a node to see its edges</div>
</div>
<canvas id="c"></canvas>
<div id="tooltip"></div>
<script nonce="${nonce}">
const NODES = ${nodesJson};
const EDGES = ${edgesJson};

const COLORS = { leaf:'#4ec9b0', core:'#569cd6', integration:'#dcdcaa', domain:'#9cdcfe' };
const canvas = document.getElementById('c');
const ctx = canvas.getContext('2d');
const tooltip = document.getElementById('tooltip');

let W, H, dragging = null, dragOffX = 0, dragOffY = 0;
let panX = 0, panY = 0, scale = 1, panning = false, panStartX = 0, panStartY = 0;
let selectedNode = null;

// Node positions (force-directed layout)
const pos = {};
function randomLayout() {
  const cx = W / 2, cy = H / 2, r = Math.min(W, H) * 0.38;
  NODES.forEach((n, i) => {
    const angle = (i / NODES.length) * Math.PI * 2;
    pos[n.id] = { x: cx + Math.cos(angle) * r * (0.5 + Math.random() * 0.5), y: cy + Math.sin(angle) * r * (0.5 + Math.random() * 0.5), vx: 0, vy: 0 };
  });
}

function resize() {
  W = canvas.width = window.innerWidth;
  H = canvas.height = window.innerHeight - document.getElementById('toolbar').offsetHeight;
  if (Object.keys(pos).length === 0) randomLayout();
}

function applyForces() {
  const k = 120, repel = 18000, damp = 0.85;
  NODES.forEach(a => {
    NODES.forEach(b => {
      if (a.id === b.id) return;
      const dx = pos[a.id].x - pos[b.id].x, dy = pos[a.id].y - pos[b.id].y;
      const d = Math.max(Math.sqrt(dx*dx+dy*dy), 1);
      const f = repel / (d*d);
      pos[a.id].vx += (dx/d)*f; pos[a.id].vy += (dy/d)*f;
    });
  });
  EDGES.forEach(e => {
    if (!pos[e.from] || !pos[e.to]) return;
    const dx = pos[e.to].x - pos[e.from].x, dy = pos[e.to].y - pos[e.from].y;
    const d = Math.max(Math.sqrt(dx*dx+dy*dy), 1);
    const f = (d - k) * 0.05;
    const fx = (dx/d)*f, fy = (dy/d)*f;
    pos[e.from].vx += fx; pos[e.from].vy += fy;
    pos[e.to].vx -= fx; pos[e.to].vy -= fy;
  });
  NODES.forEach(n => {
    pos[n.id].vx = (pos[n.id].vx + (W/2 - pos[n.id].x) * 0.005) * damp;
    pos[n.id].vy = (pos[n.id].vy + (H/2 - pos[n.id].y) * 0.005) * damp;
    pos[n.id].x += pos[n.id].vx; pos[n.id].y += pos[n.id].vy;
  });
}

let simSteps = 0;
function simulate(steps = 200) { simSteps = steps; }

const R = 28;
function draw() {
  if (simSteps > 0) { applyForces(); simSteps--; }
  ctx.setTransform(1,0,0,1,0,0);
  ctx.clearRect(0,0,W,H);
  ctx.setTransform(scale,0,0,scale,panX,panY);

  // Edges
  EDGES.forEach(e => {
    const a = pos[e.from], b = pos[e.to];
    if (!a || !b) return;
    const isHighlight = selectedNode && (e.from === selectedNode || e.to === selectedNode);
    ctx.globalAlpha = isHighlight ? 1 : (selectedNode ? 0.15 : 0.5);
    ctx.strokeStyle = isHighlight ? '#e8bf4a' : '#555';
    ctx.lineWidth = isHighlight ? 2 : 1;
    ctx.beginPath();
    ctx.moveTo(a.x, a.y);
    // Arrow
    const dx = b.x-a.x, dy = b.y-a.y, len = Math.sqrt(dx*dx+dy*dy);
    const ux = dx/len, uy = dy/len;
    const ex = b.x - ux*R, ey = b.y - uy*R;
    ctx.lineTo(ex, ey);
    ctx.stroke();
    // Arrowhead
    ctx.globalAlpha = isHighlight ? 1 : (selectedNode ? 0.1 : 0.4);
    ctx.fillStyle = isHighlight ? '#e8bf4a' : '#777';
    ctx.beginPath();
    const ax2 = ex - ux*8+uy*5, ay2 = ey - uy*8-ux*5;
    const bx2 = ex - ux*8-uy*5, by2 = ey - uy*8+ux*5;
    ctx.moveTo(ex,ey); ctx.lineTo(ax2,ay2); ctx.lineTo(bx2,by2); ctx.closePath(); ctx.fill();
  });

  // Nodes
  ctx.globalAlpha = 1;
  NODES.forEach(n => {
    const p = pos[n.id]; if (!p) return;
    const dimmed = selectedNode && selectedNode !== n.id && !EDGES.some(e => e.from===n.id&&e.to===selectedNode||e.from===selectedNode&&e.to===n.id);
    ctx.globalAlpha = dimmed ? 0.25 : 1;
    ctx.beginPath(); ctx.arc(p.x, p.y, R, 0, Math.PI*2);
    ctx.fillStyle = COLORS[n.tier] || '#9cdcfe';
    ctx.fill();
    ctx.strokeStyle = selectedNode === n.id ? '#fff' : '#0004';
    ctx.lineWidth = selectedNode === n.id ? 2.5 : 1;
    ctx.stroke();
    ctx.fillStyle = '#111'; ctx.font = 'bold 10px monospace'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    ctx.fillText(n.id.length>9 ? n.id.slice(0,8)+'…' : n.id, p.x, p.y);
  });
  ctx.globalAlpha = 1;
  requestAnimationFrame(draw);
}

function nodeAt(mx, my) {
  const wx = (mx - panX) / scale, wy = (my - panY) / scale;
  return NODES.find(n => { const p = pos[n.id]; return p && Math.sqrt((wx-p.x)**2+(wy-p.y)**2) < R; });
}

canvas.addEventListener('mousedown', e => {
  const n = nodeAt(e.clientX, e.clientY - document.getElementById('toolbar').offsetHeight);
  if (n) { dragging = n.id; dragOffX = (e.clientX - panX)/scale - pos[n.id].x; dragOffY = ((e.clientY - document.getElementById('toolbar').offsetHeight) - panY)/scale - pos[n.id].y; }
  else { panning = true; panStartX = e.clientX - panX; panStartY = e.clientY - panY; }
});
canvas.addEventListener('mousemove', e => {
  const cy = e.clientY - document.getElementById('toolbar').offsetHeight;
  if (dragging) {
    pos[dragging].x = (e.clientX - panX)/scale - dragOffX;
    pos[dragging].y = (cy - panY)/scale - dragOffY;
    pos[dragging].vx = 0; pos[dragging].vy = 0;
  } else if (panning) {
    panX = e.clientX - panStartX; panY = e.clientY - panStartY;
  } else {
    const n = nodeAt(e.clientX, cy);
    if (n) {
      const deps = EDGES.filter(ed=>ed.from===n.id).map(ed=>ed.to);
      const rdeps = EDGES.filter(ed=>ed.to===n.id).map(ed=>ed.from);
      tooltip.style.display = 'block'; tooltip.style.left = (e.clientX+12)+'px'; tooltip.style.top = (e.clientY-30)+'px';
      tooltip.innerHTML = '<b>'+n.id+'</b> ('+n.tier+')<br>→ '+( deps.length ? deps.join(', ') : 'none')+'<br>← '+(rdeps.length ? rdeps.join(', ') : 'none');
    } else { tooltip.style.display = 'none'; }
  }
});
canvas.addEventListener('mouseup', e => {
  const cy = e.clientY - document.getElementById('toolbar').offsetHeight;
  if (!dragging && !panning) {
    const n = nodeAt(e.clientX, cy);
    selectedNode = n ? (selectedNode === n.id ? null : n.id) : null;
    const info = document.getElementById('info');
    if (selectedNode) {
      const deps = EDGES.filter(ed=>ed.from===selectedNode).map(ed=>ed.to);
      const rdeps = EDGES.filter(ed=>ed.to===selectedNode).map(ed=>ed.from);
      info.textContent = selectedNode + ' → ['+deps.join(', ')+']  ← ['+rdeps.join(', ')+']';
    } else { info.textContent = 'Click a node to see its edges'; }
  }
  dragging = null; panning = false;
});
canvas.addEventListener('wheel', e => {
  e.preventDefault();
  const factor = e.deltaY < 0 ? 1.1 : 0.9;
  const cy = e.clientY - document.getElementById('toolbar').offsetHeight;
  panX = e.clientX - (e.clientX - panX) * factor;
  panY = cy - (cy - panY) * factor;
  scale *= factor;
}, { passive: false });

document.getElementById('btnLayout').onclick = () => { randomLayout(); simulate(300); };
document.getElementById('btnZoomIn').onclick = () => { panX = W/2-(W/2-panX)*1.2; panY = H/2-(H/2-panY)*1.2; scale *= 1.2; };
document.getElementById('btnZoomOut').onclick = () => { panX = W/2-(W/2-panX)*0.8; panY = H/2-(H/2-panY)*0.8; scale *= 0.8; };
document.getElementById('btnReset').onclick = () => { panX=0;panY=0;scale=1; randomLayout(); simulate(300); };

window.addEventListener('resize', resize);
resize();
simulate(400);
draw();
</script>
</body>
</html>`;
}

/**
 * Shows a dependency list in the output channel.
 */
export function depList(): void {
  const terminal = vscode.window.createTerminal("Lurek2D Deps");
  terminal.show();
  terminal.sendText("cargo tree --depth 1");
}

function getNonce(): string {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let result = "";
  for (let i = 0; i < 32; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}
