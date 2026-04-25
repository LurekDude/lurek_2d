import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

export class WorldMapEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): WorldMapEditor {
    return new WorldMapEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.worldMapEditor", "World Map");
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
        display: grid; grid-template-columns: 1fr 200px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .canvas-area { grid-row: 2; position: relative; overflow: hidden; background: var(--bg); }
      .props-panel { grid-row: 2; overflow-y: auto; border-left: 1px solid var(--border); background: var(--surface); padding: 6px; }
      .status-bar { grid-column: 1 / -1; }
      .minimap {
        width: 100%; height: 100px; background: var(--bg); border: 1px solid var(--border);
        border-radius: var(--radius); margin-bottom: 4px;
      }
      .room-list { max-height: 160px; overflow-y: auto; }
      .room-item {
        display: flex; align-items: center; gap: 4px; padding: 3px 6px;
        cursor: pointer; font-size: 11px; border-bottom: 1px solid var(--border);
        transition: background 0.08s;
      }
      .room-item:hover { background: var(--hover); }
      .room-item.sel { background: var(--selection); }
      .room-dot { width: 10px; height: 10px; border-radius: 2px; flex-shrink: 0; }
      .mode-btn { font-size: 10px; padding: 2px 7px; }
      .mode-btn.sel { background: var(--accent); color: var(--bg); }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${iconButton(ICONS.add, 'btnAddRoom', 'Add Room')}
            ${iconButton(ICONS.trash, 'btnRemoveRoom', 'Remove')}
          </div>
          ${toolbarSep()}
          <div class="group">
            <button class="mode-btn sel" id="btnConnect">Connect</button>
            <button class="mode-btn" id="btnMove">Move</button>
          </div>
          ${toolbarSep()}
          <div class="group">
            <input type="checkbox" id="snapGrid" checked><label style="font-size:10px" for="snapGrid">Snap</label>
          </div>
          ${toolbarSep()}
          <div class="group">
            ${iconButton(ICONS.zoomIn, 'btnZoomIn', 'Zoom In')}
            ${iconButton(ICONS.zoomOut, 'btnZoomOut', 'Zoom Out')}
            <button id="btnFitAll" style="font-size:10px;padding:2px 6px">Fit</button>
          </div>
          ${toolbarSpacer()}
          ${iconButton(ICONS.save, 'btnExport', 'Export Lua')}
        </div>

        <div class="canvas-area">
          <canvas id="mapCanvas"></canvas>
        </div>

        <div class="props-panel">
          ${panelSection('Minimap', '<canvas class="minimap" id="minimap"></canvas>')}
          ${panelSection('Room', `
            ${fieldInline('Name', '<input type="text" id="roomName" style="width:100%">')}
            <div style="display:flex;gap:4px">
              ${fieldInline('W', '<input type="number" id="roomW" min="40" max="400" value="120" style="width:50px">')}
              ${fieldInline('H', '<input type="number" id="roomH" min="30" max="300" value="80" style="width:50px">')}
            </div>
            ${fieldInline('Color', '<input type="color" id="roomColor" value="#2d5a88">')}
            ${fieldInline('BG', '<input type="text" id="roomBg" placeholder="bg.png" style="width:100%">')}
          `)}
          ${panelSection('Rooms', '<div class="room-list" id="roomList"></div>')}
          ${panelSection('Connections', '<div id="connectionList" style="font-size:10px;max-height:80px;overflow-y:auto;"></div>')}
        </div>

        <div class="status-bar">
          <span id="statusRooms" class="badge">4 rooms</span>
          <div class="sep"></div>
          <span id="statusConnections">3 conn</span>
          <div class="sep"></div>
          <span id="statusMode">connect</span>
          <div class="sep"></div>
          <span id="statusPos" style="font-family:var(--font-mono,monospace)">0, 0</span>
          <div class="spacer"></div>
          <span id="statusDirty" style="font-size:10px;color:var(--text-dim)">${ICONS.clean}</span>
        </div>
      </div>
    `, `
      const canvas = document.getElementById('mapCanvas');
      const ctx = canvas.getContext('2d');
      const miniCanvas = document.getElementById('minimap');
      const miniCtx = miniCanvas.getContext('2d');
      const undo = new UndoStack();

      let rooms = [
        { id: 0, name: 'Entrance', x: 100, y: 200, w: 120, h: 80, color: '#2d5a88', bg: '' },
        { id: 1, name: 'Hallway', x: 300, y: 200, w: 140, h: 60, color: '#3a6b35', bg: '' },
        { id: 2, name: 'Boss Room', x: 520, y: 180, w: 160, h: 100, color: '#8b2500', bg: '' },
        { id: 3, name: 'Treasure', x: 300, y: 80, w: 100, h: 70, color: '#8b7500', bg: '' },
      ];
      let connections = [{ from: 0, to: 1 }, { from: 1, to: 2 }, { from: 1, to: 3 }];
      let nextId = 4, selRoom = 0, mode = 'connect', snapOn = true, zoom = 1, offX = 0, offY = 0;
      let dragging = null, connectFrom = -1, isPanning = false, panSX = 0, panSY = 0;
      const GRID = 20;

      function gridSnap(v) { return snapOn ? Math.round(v / GRID) * GRID : v; }
      function snapState() { return JSON.parse(JSON.stringify({ rooms, connections, nextId })); }
      function loadState(s) { rooms = s.rooms; connections = s.connections; nextId = s.nextId; draw(); updateList(); updateProps(); }
      function push() { undo.push(snapState()); markDirty(); }
      registerShortcut('ctrl+z', () => { const s = undo.undo(); if (s) loadState(s); });
      registerShortcut('ctrl+shift+z', () => { const s = undo.redo(); if (s) loadState(s); });
      registerShortcut('ctrl+s', () => document.getElementById('btnExport').click());

      function resizeCanvas() { const a = canvas.parentElement; canvas.width = a.clientWidth; canvas.height = a.clientHeight; draw(); }

      function draw() {
        const bgCol = getComputedStyle(document.documentElement).getPropertyValue('--bg').trim() || '#1e1e1e';
        const gridCol = getComputedStyle(document.documentElement).getPropertyValue('--border').trim() || '#2a2a2a';
        const textCol = getComputedStyle(document.documentElement).getPropertyValue('--text').trim() || '#cdd6f4';
        const dimCol = getComputedStyle(document.documentElement).getPropertyValue('--text-dim').trim() || '#858585';
        ctx.fillStyle = bgCol; ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.save(); ctx.translate(offX, offY); ctx.scale(zoom, zoom);
        ctx.strokeStyle = gridCol; ctx.lineWidth = 0.5;
        for (let x = -1000; x < 2000; x += GRID) { ctx.beginPath(); ctx.moveTo(x, -1000); ctx.lineTo(x, 2000); ctx.stroke(); }
        for (let y = -1000; y < 2000; y += GRID) { ctx.beginPath(); ctx.moveTo(-1000, y); ctx.lineTo(2000, y); ctx.stroke(); }
        ctx.lineWidth = 2;
        connections.forEach(c => {
          const from = rooms.find(r => r.id === c.from), to = rooms.find(r => r.id === c.to);
          if (!from || !to) return;
          const fx = from.x + from.w/2, fy = from.y + from.h/2, tx = to.x + to.w/2, ty = to.y + to.h/2;
          ctx.strokeStyle = dimCol; ctx.beginPath(); ctx.moveTo(fx, fy); ctx.lineTo(tx, ty); ctx.stroke();
          const angle = Math.atan2(ty-fy, tx-fx), mx = (fx+tx)/2, my = (fy+ty)/2;
          ctx.fillStyle = dimCol; ctx.beginPath();
          ctx.moveTo(mx + 8*Math.cos(angle), my + 8*Math.sin(angle));
          ctx.lineTo(mx + 8*Math.cos(angle+2.5), my + 8*Math.sin(angle+2.5));
          ctx.lineTo(mx + 8*Math.cos(angle-2.5), my + 8*Math.sin(angle-2.5)); ctx.fill();
        });
        rooms.forEach((r, i) => {
          ctx.fillStyle = r.color; ctx.globalAlpha = 0.7;
          ctx.fillRect(r.x, r.y, r.w, r.h); ctx.globalAlpha = 1;
          ctx.strokeStyle = i === selRoom ? textCol : dimCol;
          ctx.lineWidth = i === selRoom ? 2 : 1;
          ctx.strokeRect(r.x, r.y, r.w, r.h);
          ctx.fillStyle = textCol; ctx.font = '11px sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
          ctx.fillText(r.name, r.x + r.w/2, r.y + r.h/2);
        });
        ctx.restore(); drawMinimap();
      }

      function drawMinimap() {
        miniCanvas.width = miniCanvas.clientWidth; miniCanvas.height = miniCanvas.clientHeight;
        miniCtx.clearRect(0, 0, miniCanvas.width, miniCanvas.height);
        if (!rooms.length) return;
        let mnX=Infinity, mnY=Infinity, mxX=-Infinity, mxY=-Infinity;
        rooms.forEach(r => { mnX=Math.min(mnX,r.x); mnY=Math.min(mnY,r.y); mxX=Math.max(mxX,r.x+r.w); mxY=Math.max(mxY,r.y+r.h); });
        const p=20, w=mxX-mnX+p*2, h=mxY-mnY+p*2, s=Math.min(miniCanvas.width/w, miniCanvas.height/h);
        const ox=(miniCanvas.width-w*s)/2-mnX*s+p*s, oy=(miniCanvas.height-h*s)/2-mnY*s+p*s;
        miniCtx.strokeStyle = '#555'; miniCtx.lineWidth = 1;
        connections.forEach(c => { const f=rooms.find(r=>r.id===c.from), t=rooms.find(r=>r.id===c.to); if(!f||!t) return; miniCtx.beginPath(); miniCtx.moveTo((f.x+f.w/2)*s+ox,(f.y+f.h/2)*s+oy); miniCtx.lineTo((t.x+t.w/2)*s+ox,(t.y+t.h/2)*s+oy); miniCtx.stroke(); });
        rooms.forEach((r,i) => { miniCtx.fillStyle=r.color; miniCtx.globalAlpha=0.8; miniCtx.fillRect(r.x*s+ox,r.y*s+oy,r.w*s,r.h*s); miniCtx.globalAlpha=1; if(i===selRoom) { miniCtx.strokeStyle='#fff'; miniCtx.lineWidth=1.5; miniCtx.strokeRect(r.x*s+ox,r.y*s+oy,r.w*s,r.h*s); } });
      }

      function updateList() {
        const list = document.getElementById('roomList'); list.innerHTML = '';
        rooms.forEach((r,i) => { const el=document.createElement('div'); el.className='room-item'+(i===selRoom?' sel':''); el.innerHTML='<div class="room-dot" style="background:'+r.color+'"></div><span>'+r.name+'</span>'; el.addEventListener('click',()=>{selRoom=i;draw();updateList();updateProps();}); list.appendChild(el); });
        const conns = document.getElementById('connectionList'); conns.innerHTML = '';
        connections.forEach((c,ci) => { const f=rooms.find(r=>r.id===c.from), t=rooms.find(r=>r.id===c.to); const el=document.createElement('div'); el.style.padding='2px 0'; el.innerHTML=(f?.name||'?')+' \\u2192 '+(t?.name||'?')+' <span style="cursor:pointer;color:var(--error);" data-ci="'+ci+'">x</span>'; el.querySelector('span').addEventListener('click',()=>{push();connections.splice(ci,1);draw();updateList();}); conns.appendChild(el); });
        document.getElementById('statusRooms').textContent = rooms.length + ' rooms';
        document.getElementById('statusConnections').textContent = connections.length + ' conn';
      }

      function updateProps() {
        const r=rooms[selRoom]; if(!r) return;
        document.getElementById('roomName').value=r.name; document.getElementById('roomW').value=r.w;
        document.getElementById('roomH').value=r.h; document.getElementById('roomColor').value=r.color;
        document.getElementById('roomBg').value=r.bg;
      }

      function s2w(sx,sy) { return {x:(sx-offX)/zoom, y:(sy-offY)/zoom}; }
      function findAt(wx,wy) { for(let i=rooms.length-1;i>=0;i--) { const r=rooms[i]; if(wx>=r.x&&wx<=r.x+r.w&&wy>=r.y&&wy<=r.y+r.h) return i; } return -1; }

      canvas.addEventListener('mousedown', e => {
        const rect=canvas.getBoundingClientRect(), sx=e.clientX-rect.left, sy=e.clientY-rect.top;
        if(e.button===1||(e.button===0&&e.altKey)){isPanning=true;panSX=sx-offX;panSY=sy-offY;return;}
        const {x:wx,y:wy}=s2w(sx,sy), hit=findAt(wx,wy);
        if(hit>=0){selRoom=hit;updateList();updateProps();if(mode==='move')dragging={i:hit,sx,sy,rx:rooms[hit].x,ry:rooms[hit].y};else connectFrom=hit;}
        draw();
      });
      canvas.addEventListener('mousemove', e => {
        const rect=canvas.getBoundingClientRect(), sx=e.clientX-rect.left, sy=e.clientY-rect.top;
        const {x:wx,y:wy}=s2w(sx,sy);
        document.getElementById('statusPos').textContent=Math.round(wx)+', '+Math.round(wy);
        if(isPanning){offX=sx-panSX;offY=sy-panSY;draw();return;}
        if(dragging){const dx=(sx-dragging.sx)/zoom,dy=(sy-dragging.sy)/zoom;rooms[dragging.i].x=gridSnap(dragging.rx+dx);rooms[dragging.i].y=gridSnap(dragging.ry+dy);draw();}
      });
      canvas.addEventListener('mouseup', e => {
        isPanning=false;
        if(dragging){push();dragging=null;draw();updateList();return;}
        if(connectFrom>=0&&mode==='connect'){const rect=canvas.getBoundingClientRect();const {x:wx,y:wy}=s2w(e.clientX-rect.left,e.clientY-rect.top);const hit=findAt(wx,wy);
        if(hit>=0&&hit!==connectFrom&&!connections.some(c=>c.from===rooms[connectFrom].id&&c.to===rooms[hit].id)){push();connections.push({from:rooms[connectFrom].id,to:rooms[hit].id});draw();updateList();}connectFrom=-1;}
      });
      canvas.addEventListener('wheel', e => { e.preventDefault(); zoom=Math.max(0.2,Math.min(3,zoom*(e.deltaY<0?1.1:0.9))); draw(); });

      document.getElementById('btnConnect').addEventListener('click',()=>{mode='connect';document.getElementById('btnConnect').classList.add('sel');document.getElementById('btnMove').classList.remove('sel');document.getElementById('statusMode').textContent='connect';});
      document.getElementById('btnMove').addEventListener('click',()=>{mode='move';document.getElementById('btnMove').classList.add('sel');document.getElementById('btnConnect').classList.remove('sel');document.getElementById('statusMode').textContent='move';});
      document.getElementById('snapGrid').addEventListener('change',e=>{snapOn=e.target.checked;});
      document.getElementById('btnZoomIn').addEventListener('click',()=>{zoom=Math.min(3,zoom*1.2);draw();});
      document.getElementById('btnZoomOut').addEventListener('click',()=>{zoom=Math.max(0.2,zoom/1.2);draw();});
      document.getElementById('btnFitAll').addEventListener('click',()=>{if(!rooms.length)return;let mnX=Infinity,mnY=Infinity,mxX=-Infinity,mxY=-Infinity;rooms.forEach(r=>{mnX=Math.min(mnX,r.x);mnY=Math.min(mnY,r.y);mxX=Math.max(mxX,r.x+r.w);mxY=Math.max(mxY,r.y+r.h);});const p=40,w=mxX-mnX+p*2,h=mxY-mnY+p*2;zoom=Math.min(canvas.width/w,canvas.height/h);offX=-mnX*zoom+p*zoom;offY=-mnY*zoom+p*zoom;draw();});
      document.getElementById('btnAddRoom').addEventListener('click',()=>{push();const cx=(canvas.width/2-offX)/zoom,cy=(canvas.height/2-offY)/zoom;rooms.push({id:nextId++,name:'Room '+rooms.length,x:gridSnap(cx),y:gridSnap(cy),w:120,h:80,color:'#2d5a88',bg:''});selRoom=rooms.length-1;draw();updateList();updateProps();});
      document.getElementById('btnRemoveRoom').addEventListener('click',()=>{if(!rooms.length)return;push();const rid=rooms[selRoom].id;rooms.splice(selRoom,1);connections=connections.filter(c=>c.from!==rid&&c.to!==rid);selRoom=Math.min(selRoom,rooms.length-1);draw();updateList();updateProps();});
      document.getElementById('roomName').addEventListener('change',e=>{if(rooms[selRoom]){push();rooms[selRoom].name=e.target.value;draw();updateList();}});
      document.getElementById('roomW').addEventListener('change',e=>{if(rooms[selRoom]){push();rooms[selRoom].w=parseInt(e.target.value);draw();}});
      document.getElementById('roomH').addEventListener('change',e=>{if(rooms[selRoom]){push();rooms[selRoom].h=parseInt(e.target.value);draw();}});
      document.getElementById('roomColor').addEventListener('input',e=>{if(rooms[selRoom]){push();rooms[selRoom].color=e.target.value;draw();updateList();}});
      document.getElementById('roomBg').addEventListener('change',e=>{if(rooms[selRoom]){push();rooms[selRoom].bg=e.target.value;}});
      document.getElementById('btnExport').addEventListener('click',()=>{
        let lua='return {\\n  rooms = {\\n';rooms.forEach(r=>{lua+='    { id = '+r.id+', name = "'+r.name+'", x = '+r.x+', y = '+r.y+', w = '+r.w+', h = '+r.h;if(r.bg)lua+=', background = "'+r.bg+'"';lua+=' },\\n';});
        lua+='  },\\n  connections = {\\n';connections.forEach(c=>{const f=rooms.find(r=>r.id===c.from),t=rooms.find(r=>r.id===c.to);lua+='    { from = "'+(f?.name||c.from)+'", to = "'+(t?.name||c.to)+'" },\\n';});
        lua+='  }\\n}';vscode.postMessage({type:'exportLua',content:lua});
      });
      window.addEventListener('resize',resizeCanvas); resizeCanvas(); updateList(); updateProps();
    `);
  }
}
