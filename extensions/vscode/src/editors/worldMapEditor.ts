import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class WorldMapEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): WorldMapEditor {
    return new WorldMapEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "luna.worldMapEditor", "World Map");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "world_map.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "World Map", `
      .editor-layout {
        display: grid; grid-template-columns: 1fr 240px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: var(--bg); }
      .props-panel { grid-row: 2; }
      .status-bar { grid-column: 1 / -1; }
      .minimap {
        width: 100%; height: 120px; background: var(--bg); border: 1px solid var(--border);
        border-radius: 4px; margin-bottom: 8px;
      }
      .room-list { max-height: 200px; overflow-y: auto; }
      .room-item {
        display: flex; align-items: center; gap: 6px; padding: 4px 8px;
        cursor: pointer; border-radius: 3px; font-size: 12px;
      }
      .room-item:hover { background: var(--surface-2); }
      .room-item.selected { background: var(--selection); }
      .room-dot { width: 10px; height: 10px; border-radius: 2px; flex-shrink: 0; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <button id="btnAddRoom">+ Room</button>
          <button id="btnRemoveRoom" class="danger">Remove Room</button>
          <div class="sep"></div>
          <button id="btnConnect" class="active">Connect Mode</button>
          <button id="btnMove">Move Mode</button>
          <div class="sep"></div>
          <input type="checkbox" id="snapGrid" checked><label for="snapGrid">Snap to Grid</label>
          <div class="sep"></div>
          <button id="btnZoomIn">+</button>
          <button id="btnZoomOut">-</button>
          <button id="btnFitAll">Fit All</button>
          <div class="sep"></div>
          <button id="btnExport">Export Lua</button>
        </div>

        <div class="canvas-area">
          <canvas id="mapCanvas"></canvas>
        </div>

        <div class="panel props-panel">
          <div class="section">
            <h3>Minimap</h3>
            <canvas class="minimap" id="minimap"></canvas>
          </div>
          <div class="section">
            <h3>Room Properties</h3>
            <div class="field"><label>Name</label><input type="text" id="roomName" style="width:100%"></div>
            <div class="field-row">
              <div class="field" style="flex:1"><label>Width</label><input type="number" id="roomW" min="40" max="400" value="120"></div>
              <div class="field" style="flex:1"><label>Height</label><input type="number" id="roomH" min="30" max="300" value="80"></div>
            </div>
            <div class="field"><label>Color</label><input type="color" id="roomColor" value="#2d5a88"></div>
            <div class="field"><label>Background</label><input type="text" id="roomBg" placeholder="bg_forest.png" style="width:100%"></div>
          </div>
          <div class="section">
            <h3>Rooms</h3>
            <div class="room-list" id="roomList"></div>
          </div>
          <div class="section">
            <h3>Connections</h3>
            <div id="connectionList" style="font-size:11px;max-height:100px;overflow-y:auto;"></div>
          </div>
        </div>

        <div class="status-bar">
          <span id="statusRooms">Rooms: 0</span>
          <span id="statusConnections">Connections: 0</span>
          <span id="statusMode">Mode: connect</span>
          <span id="statusPos">Pos: 0, 0</span>
        </div>
      </div>
    `, `
      const canvas = document.getElementById('mapCanvas');
      const ctx = canvas.getContext('2d');
      const miniCanvas = document.getElementById('minimap');
      const miniCtx = miniCanvas.getContext('2d');

      let rooms = [
        { id: 0, name: 'Entrance', x: 100, y: 200, w: 120, h: 80, color: '#2d5a88', bg: '' },
        { id: 1, name: 'Hallway', x: 300, y: 200, w: 140, h: 60, color: '#3a6b35', bg: '' },
        { id: 2, name: 'Boss Room', x: 520, y: 180, w: 160, h: 100, color: '#8b2500', bg: '' },
        { id: 3, name: 'Treasure', x: 300, y: 80, w: 100, h: 70, color: '#8b7500', bg: '' },
      ];
      let connections = [
        { from: 0, to: 1 },
        { from: 1, to: 2 },
        { from: 1, to: 3 },
      ];
      let nextId = 4;

      let selectedRoom = 0;
      let mode = 'connect'; // 'connect' or 'move'
      let snapGrid = true;
      let zoom = 1, offsetX = 0, offsetY = 0;
      let dragging = null; // { roomIdx, startX, startY, roomStartX, roomStartY }
      let connectFrom = -1;
      let isPanning = false, panStartX = 0, panStartY = 0;

      const GRID = 20;

      function snap(v) { return snapGrid ? Math.round(v / GRID) * GRID : v; }

      function resizeCanvas() {
        const area = canvas.parentElement;
        canvas.width = area.clientWidth;
        canvas.height = area.clientHeight;
        render();
      }

      function render() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.save();
        ctx.translate(offsetX, offsetY);
        ctx.scale(zoom, zoom);

        // Grid
        ctx.strokeStyle = '#1a1a1a';
        ctx.lineWidth = 0.5;
        for (let x = -1000; x < 2000; x += GRID) {
          ctx.beginPath(); ctx.moveTo(x, -1000); ctx.lineTo(x, 2000); ctx.stroke();
        }
        for (let y = -1000; y < 2000; y += GRID) {
          ctx.beginPath(); ctx.moveTo(-1000, y); ctx.lineTo(2000, y); ctx.stroke();
        }

        // Connections
        ctx.lineWidth = 2;
        connections.forEach(c => {
          const from = rooms.find(r => r.id === c.from);
          const to = rooms.find(r => r.id === c.to);
          if (!from || !to) return;
          const fx = from.x + from.w / 2, fy = from.y + from.h / 2;
          const tx = to.x + to.w / 2, ty = to.y + to.h / 2;
          ctx.strokeStyle = '#666';
          ctx.beginPath(); ctx.moveTo(fx, fy); ctx.lineTo(tx, ty); ctx.stroke();
          // Arrow head
          const angle = Math.atan2(ty - fy, tx - fx);
          const mx = (fx + tx) / 2, my = (fy + ty) / 2;
          ctx.fillStyle = '#666';
          ctx.beginPath();
          ctx.moveTo(mx + 8 * Math.cos(angle), my + 8 * Math.sin(angle));
          ctx.lineTo(mx + 8 * Math.cos(angle + 2.5), my + 8 * Math.sin(angle + 2.5));
          ctx.lineTo(mx + 8 * Math.cos(angle - 2.5), my + 8 * Math.sin(angle - 2.5));
          ctx.fill();
        });

        // Rooms
        rooms.forEach((room, i) => {
          ctx.fillStyle = room.color;
          ctx.globalAlpha = 0.7;
          ctx.fillRect(room.x, room.y, room.w, room.h);
          ctx.globalAlpha = 1;
          ctx.strokeStyle = i === selectedRoom ? '#fff' : '#888';
          ctx.lineWidth = i === selectedRoom ? 2 : 1;
          ctx.strokeRect(room.x, room.y, room.w, room.h);

          ctx.fillStyle = '#fff';
          ctx.font = '12px sans-serif';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillText(room.name, room.x + room.w / 2, room.y + room.h / 2);
        });

        ctx.restore();
        renderMinimap();
      }

      function renderMinimap() {
        miniCanvas.width = miniCanvas.clientWidth;
        miniCanvas.height = miniCanvas.clientHeight;
        miniCtx.clearRect(0, 0, miniCanvas.width, miniCanvas.height);
        if (rooms.length === 0) return;
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        rooms.forEach(r => {
          minX = Math.min(minX, r.x); minY = Math.min(minY, r.y);
          maxX = Math.max(maxX, r.x + r.w); maxY = Math.max(maxY, r.y + r.h);
        });
        const pad = 20;
        const w = maxX - minX + pad * 2, h = maxY - minY + pad * 2;
        const scale = Math.min(miniCanvas.width / w, miniCanvas.height / h);
        const ox = (miniCanvas.width - w * scale) / 2 - minX * scale + pad * scale;
        const oy = (miniCanvas.height - h * scale) / 2 - minY * scale + pad * scale;
        // Connections
        miniCtx.strokeStyle = '#555'; miniCtx.lineWidth = 1;
        connections.forEach(c => {
          const from = rooms.find(r => r.id === c.from);
          const to = rooms.find(r => r.id === c.to);
          if (!from || !to) return;
          miniCtx.beginPath();
          miniCtx.moveTo((from.x + from.w/2) * scale + ox, (from.y + from.h/2) * scale + oy);
          miniCtx.lineTo((to.x + to.w/2) * scale + ox, (to.y + to.h/2) * scale + oy);
          miniCtx.stroke();
        });
        rooms.forEach((r, i) => {
          miniCtx.fillStyle = r.color;
          miniCtx.globalAlpha = 0.8;
          miniCtx.fillRect(r.x * scale + ox, r.y * scale + oy, r.w * scale, r.h * scale);
          miniCtx.globalAlpha = 1;
          if (i === selectedRoom) {
            miniCtx.strokeStyle = '#fff'; miniCtx.lineWidth = 1.5;
            miniCtx.strokeRect(r.x * scale + ox, r.y * scale + oy, r.w * scale, r.h * scale);
          }
        });
      }

      function updateRoomList() {
        const list = document.getElementById('roomList');
        list.innerHTML = '';
        rooms.forEach((r, i) => {
          const el = document.createElement('div');
          el.className = 'room-item' + (i === selectedRoom ? ' selected' : '');
          el.innerHTML = '<div class="room-dot" style="background:' + r.color + '"></div><span>' + r.name + '</span>';
          el.addEventListener('click', () => { selectedRoom = i; render(); updateRoomList(); updateProps(); });
          list.appendChild(el);
        });
        const conns = document.getElementById('connectionList');
        conns.innerHTML = '';
        connections.forEach((c, ci) => {
          const from = rooms.find(r => r.id === c.from);
          const to = rooms.find(r => r.id === c.to);
          const el = document.createElement('div');
          el.style.padding = '2px 0';
          el.innerHTML = (from?.name || '?') + ' \\u2192 ' + (to?.name || '?') + ' <span style="cursor:pointer;color:var(--danger);" data-ci="' + ci + '">x</span>';
          el.querySelector('span').addEventListener('click', () => { connections.splice(ci, 1); render(); updateRoomList(); });
          conns.appendChild(el);
        });
        document.getElementById('statusRooms').textContent = 'Rooms: ' + rooms.length;
        document.getElementById('statusConnections').textContent = 'Connections: ' + connections.length;
      }

      function updateProps() {
        const r = rooms[selectedRoom];
        if (!r) return;
        document.getElementById('roomName').value = r.name;
        document.getElementById('roomW').value = r.w;
        document.getElementById('roomH').value = r.h;
        document.getElementById('roomColor').value = r.color;
        document.getElementById('roomBg').value = r.bg;
      }

      function screenToWorld(sx, sy) {
        return { x: (sx - offsetX) / zoom, y: (sy - offsetY) / zoom };
      }

      function findRoomAt(wx, wy) {
        for (let i = rooms.length - 1; i >= 0; i--) {
          const r = rooms[i];
          if (wx >= r.x && wx <= r.x + r.w && wy >= r.y && wy <= r.y + r.h) return i;
        }
        return -1;
      }

      canvas.addEventListener('mousedown', (e) => {
        const rect = canvas.getBoundingClientRect();
        const sx = e.clientX - rect.left, sy = e.clientY - rect.top;
        if (e.button === 1 || (e.button === 0 && e.altKey)) {
          isPanning = true; panStartX = sx - offsetX; panStartY = sy - offsetY; return;
        }
        const { x: wx, y: wy } = screenToWorld(sx, sy);
        const hit = findRoomAt(wx, wy);
        if (hit >= 0) {
          selectedRoom = hit;
          updateRoomList();
          updateProps();
          if (mode === 'move') {
            dragging = { roomIdx: hit, startX: sx, startY: sy, roomStartX: rooms[hit].x, roomStartY: rooms[hit].y };
          } else if (mode === 'connect') {
            connectFrom = hit;
          }
        }
        render();
      });

      canvas.addEventListener('mousemove', (e) => {
        const rect = canvas.getBoundingClientRect();
        const sx = e.clientX - rect.left, sy = e.clientY - rect.top;
        const { x: wx, y: wy } = screenToWorld(sx, sy);
        document.getElementById('statusPos').textContent = 'Pos: ' + Math.round(wx) + ', ' + Math.round(wy);
        if (isPanning) {
          offsetX = sx - panStartX; offsetY = sy - panStartY; render(); return;
        }
        if (dragging) {
          const dx = (sx - dragging.startX) / zoom;
          const dy = (sy - dragging.startY) / zoom;
          rooms[dragging.roomIdx].x = snap(dragging.roomStartX + dx);
          rooms[dragging.roomIdx].y = snap(dragging.roomStartY + dy);
          render();
        }
      });

      canvas.addEventListener('mouseup', (e) => {
        isPanning = false;
        if (dragging) { dragging = null; render(); updateRoomList(); return; }
        if (connectFrom >= 0 && mode === 'connect') {
          const rect = canvas.getBoundingClientRect();
          const { x: wx, y: wy } = screenToWorld(e.clientX - rect.left, e.clientY - rect.top);
          const hit = findRoomAt(wx, wy);
          if (hit >= 0 && hit !== connectFrom) {
            const exists = connections.some(c => c.from === rooms[connectFrom].id && c.to === rooms[hit].id);
            if (!exists) {
              connections.push({ from: rooms[connectFrom].id, to: rooms[hit].id });
              render(); updateRoomList();
            }
          }
          connectFrom = -1;
        }
      });

      canvas.addEventListener('wheel', (e) => {
        e.preventDefault();
        const zoomFactor = e.deltaY < 0 ? 1.1 : 0.9;
        zoom = Math.max(0.2, Math.min(3, zoom * zoomFactor));
        render();
      });

      document.getElementById('btnConnect').addEventListener('click', () => {
        mode = 'connect';
        document.getElementById('btnConnect').classList.add('active');
        document.getElementById('btnMove').classList.remove('active');
        document.getElementById('statusMode').textContent = 'Mode: connect';
      });
      document.getElementById('btnMove').addEventListener('click', () => {
        mode = 'move';
        document.getElementById('btnMove').classList.add('active');
        document.getElementById('btnConnect').classList.remove('active');
        document.getElementById('statusMode').textContent = 'Mode: move';
      });

      document.getElementById('snapGrid').addEventListener('change', (e) => { snapGrid = e.target.checked; });

      document.getElementById('btnZoomIn').addEventListener('click', () => { zoom = Math.min(3, zoom * 1.2); render(); });
      document.getElementById('btnZoomOut').addEventListener('click', () => { zoom = Math.max(0.2, zoom / 1.2); render(); });
      document.getElementById('btnFitAll').addEventListener('click', () => {
        if (rooms.length === 0) return;
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        rooms.forEach(r => { minX = Math.min(minX, r.x); minY = Math.min(minY, r.y); maxX = Math.max(maxX, r.x + r.w); maxY = Math.max(maxY, r.y + r.h); });
        const pad = 40;
        const w = maxX - minX + pad * 2, h = maxY - minY + pad * 2;
        zoom = Math.min(canvas.width / w, canvas.height / h);
        offsetX = -minX * zoom + pad * zoom;
        offsetY = -minY * zoom + pad * zoom;
        render();
      });

      document.getElementById('btnAddRoom').addEventListener('click', () => {
        const cx = (canvas.width / 2 - offsetX) / zoom;
        const cy = (canvas.height / 2 - offsetY) / zoom;
        rooms.push({ id: nextId++, name: 'Room ' + rooms.length, x: snap(cx), y: snap(cy), w: 120, h: 80, color: '#2d5a88', bg: '' });
        selectedRoom = rooms.length - 1;
        render(); updateRoomList(); updateProps();
      });
      document.getElementById('btnRemoveRoom').addEventListener('click', () => {
        if (rooms.length === 0) return;
        const rid = rooms[selectedRoom].id;
        rooms.splice(selectedRoom, 1);
        connections = connections.filter(c => c.from !== rid && c.to !== rid);
        selectedRoom = Math.min(selectedRoom, rooms.length - 1);
        render(); updateRoomList(); updateProps();
      });

      document.getElementById('roomName').addEventListener('change', (e) => {
        if (rooms[selectedRoom]) { rooms[selectedRoom].name = e.target.value; render(); updateRoomList(); }
      });
      document.getElementById('roomW').addEventListener('change', (e) => {
        if (rooms[selectedRoom]) { rooms[selectedRoom].w = parseInt(e.target.value); render(); }
      });
      document.getElementById('roomH').addEventListener('change', (e) => {
        if (rooms[selectedRoom]) { rooms[selectedRoom].h = parseInt(e.target.value); render(); }
      });
      document.getElementById('roomColor').addEventListener('input', (e) => {
        if (rooms[selectedRoom]) { rooms[selectedRoom].color = e.target.value; render(); updateRoomList(); }
      });
      document.getElementById('roomBg').addEventListener('change', (e) => {
        if (rooms[selectedRoom]) rooms[selectedRoom].bg = e.target.value;
      });

      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n  rooms = {\\n';
        rooms.forEach(r => {
          lua += '    { id = ' + r.id + ', name = "' + r.name + '", x = ' + r.x + ', y = ' + r.y;
          lua += ', w = ' + r.w + ', h = ' + r.h;
          if (r.bg) lua += ', background = "' + r.bg + '"';
          lua += ' },\\n';
        });
        lua += '  },\\n  connections = {\\n';
        connections.forEach(c => {
          const from = rooms.find(r => r.id === c.from);
          const to = rooms.find(r => r.id === c.to);
          lua += '    { from = "' + (from?.name||c.from) + '", to = "' + (to?.name||c.to) + '" },\\n';
        });
        lua += '  }\\n}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      window.addEventListener('resize', resizeCanvas);
      resizeCanvas();
      updateRoomList();
      updateProps();
    `);
  }
}
