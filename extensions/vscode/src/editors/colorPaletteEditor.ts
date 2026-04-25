import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

export class ColorPaletteEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): ColorPaletteEditor {
    return new ColorPaletteEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.colorPaletteEditor", "Color Palette");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "palette.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Color Palette", `
      .editor-layout {
        display: grid; grid-template-columns: 240px 1fr 210px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .picker-panel {
        grid-row: 2; overflow-y: auto; border-right: 1px solid var(--border);
        background: var(--surface); padding: 6px;
      }
      .palette-area { grid-row: 2; padding: 10px; overflow-y: auto; background: var(--bg); }
      .harmony-panel {
        grid-row: 2; overflow-y: auto; border-left: 1px solid var(--border);
        background: var(--surface); padding: 6px;
      }
      .color-preview {
        width: 100%; height: 64px; border-radius: var(--radius); border: 1px solid var(--border); margin-bottom: 6px;
      }
      .slider-grp { margin-bottom: 5px; }
      .slider-grp label { display: flex; justify-content: space-between; font-size: 10px; color: var(--text-dim); }
      .slider-grp input[type="range"] { width: 100%; }
      .hex-input { width: 100%; font-family: var(--font-mono, monospace); font-size: 12px; text-align: center; }
      .palette-grid { display: grid; grid-template-columns: repeat(8, 1fr); gap: 3px; }
      .swatch {
        aspect-ratio: 1; border-radius: var(--radius); border: 2px solid transparent;
        cursor: pointer; position: relative; min-height: 32px; transition: border-color 0.1s;
      }
      .swatch:hover { border-color: var(--text); }
      .swatch.sel { border-color: var(--accent); box-shadow: 0 0 0 2px var(--accent); }
      .swatch-num {
        position: absolute; bottom: 1px; left: 0; right: 0; text-align: center;
        font-size: 7px; color: #fff; text-shadow: 0 0 2px #000;
      }
      .harmony-wheel {
        width: 160px; height: 160px; border-radius: 50%; margin: 8px auto;
        background: conic-gradient(red, yellow, lime, cyan, blue, magenta, red);
        position: relative;
      }
      .harmony-dot {
        width: 10px; height: 10px; border-radius: 50%; border: 2px solid #fff;
        position: absolute; transform: translate(-50%,-50%); box-shadow: 0 0 3px rgba(0,0,0,0.5);
      }
      .contrast-pill {
        display: inline-block; padding: 1px 6px; border-radius: var(--radius); font-size: 10px; font-weight: 600;
      }
      .contrast-ok { background: var(--success); color: #fff; }
      .contrast-no { background: var(--error); color: #fff; }
      .harmony-swatches { display: flex; gap: 3px; margin-top: 6px; justify-content: center; }
      .harmony-sw { width: 24px; height: 24px; border-radius: var(--radius); border: 1px solid var(--border); cursor: pointer; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            ${iconButton(ICONS.add, 'btnAdd', 'Add Color')}
            ${iconButton(ICONS.delete, 'btnRem', 'Remove Color')}
          </div>
          ${toolbarSep()}
          <div class="group">
            <select id="colorMode" style="font-size:10px">
              <option value="hsl">HSL</option>
              <option value="rgb">RGB</option>
            </select>
          </div>
          ${toolbarSep()}
          <div class="group">
            <button id="btnSortH" style="font-size:10px;padding:2px 6px">Sort Hue</button>
            <button id="btnSortL" style="font-size:10px;padding:2px 6px">Sort Light</button>
          </div>
          ${toolbarSpacer()}
          ${iconButton(ICONS.save, 'btnExport', 'Export Lua')}
        </div>

        <div class="picker-panel">
          ${panelSection('Color Picker', `
            <div class="color-preview" id="colorPreview"></div>
            <input type="text" class="hex-input" id="hexInput" value="#89B4FA">
          `)}
          ${panelSection('Sliders', `
            <div class="slider-grp"><label>H <span id="hVal">217</span></label><input type="range" id="hSlider" min="0" max="360" value="217"></div>
            <div class="slider-grp"><label>S <span id="sVal">92</span></label><input type="range" id="sSlider" min="0" max="100" value="92"></div>
            <div class="slider-grp"><label>L <span id="lVal">76</span></label><input type="range" id="lSlider" min="0" max="100" value="76"></div>
            <div class="slider-grp"><label>A <span id="aVal">255</span></label><input type="range" id="aSlider" min="0" max="255" value="255"></div>
          `)}
          ${panelSection('Accessibility', `
            <div style="font-size:10px">
              <p>On white: <span id="crW" class="contrast-pill">--</span></p>
              <p style="margin-top:3px">On black: <span id="crB" class="contrast-pill">--</span></p>
            </div>
          `)}
        </div>

        <div class="palette-area">
          <div style="font-size:11px;margin-bottom:6px;color:var(--text-dim)">Palette (<span id="pCount">0</span>/64)</div>
          <div class="palette-grid" id="pGrid"></div>
        </div>

        <div class="harmony-panel">
          ${panelSection('Harmony', `
            <select id="harmType" style="width:100%;font-size:10px">
              <option value="complementary">Complementary</option>
              <option value="triadic">Triadic</option>
              <option value="analogous">Analogous</option>
              <option value="split">Split-Complementary</option>
              <option value="tetradic">Tetradic</option>
            </select>
            <div class="harmony-wheel" id="hWheel"></div>
            <div class="harmony-swatches" id="hSwatches"></div>
            <button id="btnApplyH" style="width:100%;margin-top:4px;font-size:10px">Add Harmony Colors</button>
          `)}
        </div>

        <div class="status-bar">
          <span id="stColor" class="badge">#89B4FA</span>
          <div class="sep"></div>
          <span id="stIdx">Idx: —</span>
          <div class="sep"></div>
          <span id="stTotal">0 colors</span>
          <div class="spacer"></div>
          <span id="stDirty" style="font-size:10px;color:var(--text-dim)">${ICONS.clean}</span>
        </div>
      </div>
    `, `
      const undo = new UndoStack();
      let palette = [], selIdx = -1;
      let h = 217, s = 92, l = 76, a = 255;

      function snap() { return JSON.parse(JSON.stringify({ palette, selIdx })); }
      function loadSnap(st) { palette = st.palette; selIdx = st.selIdx; renderPal(); updateColor(); }
      function push() { undo.push(snap()); markDirty(); }
      registerShortcut('ctrl+z', () => { const s2 = undo.undo(); if (s2) loadSnap(s2); });
      registerShortcut('ctrl+shift+z', () => { const s2 = undo.redo(); if (s2) loadSnap(s2); });
      registerShortcut('ctrl+s', () => document.getElementById('btnExport').click());

      function hslHex(h, s, l) {
        const s2 = s/100, l2 = l/100;
        const k = n => (n + h/30)%12;
        const a2 = s2*Math.min(l2, 1-l2);
        const f = n => l2 - a2*Math.max(-1, Math.min(k(n)-3, 9-k(n), 1));
        const x = v => Math.round(v*255).toString(16).padStart(2,'0');
        return '#'+x(f(0))+x(f(8))+x(f(4));
      }
      function hexRgb(hex) {
        const m = hex.match(/^#?([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})$/i);
        return m ? {r:parseInt(m[1],16),g:parseInt(m[2],16),b:parseInt(m[3],16)} : {r:0,g:0,b:0};
      }
      function lum(r,g,b) {
        const [rs,gs,bs] = [r,g,b].map(c => { c/=255; return c<=0.03928?c/12.92:Math.pow((c+0.055)/1.055,2.4); });
        return 0.2126*rs+0.7152*gs+0.0722*bs;
      }
      function cr(l1,l2) { return (Math.max(l1,l2)+0.05)/(Math.min(l1,l2)+0.05); }

      function updateColor() {
        const hex = hslHex(h,s,l);
        document.getElementById('colorPreview').style.background = hex;
        document.getElementById('hexInput').value = hex;
        document.getElementById('hVal').textContent = h;
        document.getElementById('sVal').textContent = s;
        document.getElementById('lVal').textContent = l;
        document.getElementById('aVal').textContent = a;
        document.getElementById('stColor').textContent = hex;
        const rgb = hexRgb(hex), lu = lum(rgb.r,rgb.g,rgb.b);
        const cw = cr(1,lu).toFixed(1), cb = cr(lu,0).toFixed(1);
        const ew = document.getElementById('crW'), eb = document.getElementById('crB');
        ew.textContent = cw+':1'; ew.className = 'contrast-pill '+(cw>=4.5?'contrast-ok':'contrast-no');
        eb.textContent = cb+':1'; eb.className = 'contrast-pill '+(cb>=4.5?'contrast-ok':'contrast-no');
        updateHarm();
        if (selIdx >= 0 && selIdx < palette.length) { palette[selIdx] = {hex,h,s,l,a}; renderPal(); }
      }

      function renderPal() {
        const g = document.getElementById('pGrid'); g.innerHTML = '';
        palette.forEach((c,i) => {
          const el = document.createElement('div');
          el.className = 'swatch'+(i===selIdx?' sel':'');
          el.style.background = c.hex;
          el.innerHTML = '<span class="swatch-num">'+(i+1)+'</span>';
          el.addEventListener('click', () => {
            selIdx = i; h = c.h; s = c.s; l = c.l; a = c.a;
            document.getElementById('hSlider').value = h;
            document.getElementById('sSlider').value = s;
            document.getElementById('lSlider').value = l;
            document.getElementById('aSlider').value = a;
            updateColor(); renderPal();
            document.getElementById('stIdx').textContent = 'Idx: '+i;
          });
          g.appendChild(el);
        });
        document.getElementById('pCount').textContent = palette.length;
        document.getElementById('stTotal').textContent = palette.length+' colors';
      }

      function harmHues(type) {
        switch(type) {
          case 'complementary': return [h,(h+180)%360];
          case 'triadic': return [h,(h+120)%360,(h+240)%360];
          case 'analogous': return [(h-30+360)%360,h,(h+30)%360];
          case 'split': return [h,(h+150)%360,(h+210)%360];
          case 'tetradic': return [h,(h+90)%360,(h+180)%360,(h+270)%360];
          default: return [h];
        }
      }
      function updateHarm() {
        const type = document.getElementById('harmType').value;
        const hues = harmHues(type);
        const wheel = document.getElementById('hWheel'); wheel.innerHTML = '';
        const sw = document.getElementById('hSwatches'); sw.innerHTML = '';
        hues.forEach(hu => {
          const ang = (hu-90)*Math.PI/180, r = 70;
          const dot = document.createElement('div');
          dot.className = 'harmony-dot';
          dot.style.left = (80+r*Math.cos(ang))+'px';
          dot.style.top = (80+r*Math.sin(ang))+'px';
          dot.style.background = hslHex(hu,s,l);
          wheel.appendChild(dot);
          const sc = document.createElement('div');
          sc.className = 'harmony-sw';
          sc.style.background = hslHex(hu,s,l);
          sc.addEventListener('click', () => { if (palette.length<64) { push(); palette.push({hex:hslHex(hu,s,l),h:hu,s,l,a}); renderPal(); }});
          sw.appendChild(sc);
        });
      }

      ['hSlider','sSlider','lSlider','aSlider'].forEach(id => {
        document.getElementById(id).addEventListener('input', e => {
          if (id==='hSlider') h=+e.target.value; if (id==='sSlider') s=+e.target.value;
          if (id==='lSlider') l=+e.target.value; if (id==='aSlider') a=+e.target.value;
          updateColor();
        });
      });
      document.getElementById('hexInput').addEventListener('change', e => {
        const rgb = hexRgb(e.target.value);
        const r2=rgb.r/255,g2=rgb.g/255,b2=rgb.b/255;
        const mx=Math.max(r2,g2,b2),mn=Math.min(r2,g2,b2);
        l=Math.round((mx+mn)/2*100);
        if(mx!==mn){const d=mx-mn;s=Math.round((l>50?d/(2-mx-mn):d/(mx+mn))*100);
        if(mx===r2)h=Math.round(((g2-b2)/d+(g2<b2?6:0))*60);
        else if(mx===g2)h=Math.round(((b2-r2)/d+2)*60);
        else h=Math.round(((r2-g2)/d+4)*60);}else{s=0;h=0;}
        document.getElementById('hSlider').value=h;
        document.getElementById('sSlider').value=s;
        document.getElementById('lSlider').value=l;
        updateColor();
      });

      document.getElementById('btnAdd').addEventListener('click', () => {
        if (palette.length<64) { push(); palette.push({hex:hslHex(h,s,l),h,s,l,a}); selIdx=palette.length-1; renderPal(); }
      });
      document.getElementById('btnRem').addEventListener('click', () => {
        if (selIdx>=0) { push(); palette.splice(selIdx,1); selIdx=Math.min(selIdx,palette.length-1); renderPal(); }
      });
      document.getElementById('btnSortH').addEventListener('click', () => { push(); palette.sort((a,b)=>a.h-b.h); renderPal(); });
      document.getElementById('btnSortL').addEventListener('click', () => { push(); palette.sort((a,b)=>a.l-b.l); renderPal(); });
      document.getElementById('harmType').addEventListener('change', updateHarm);
      document.getElementById('btnApplyH').addEventListener('click', () => {
        const hues = harmHues(document.getElementById('harmType').value);
        push(); hues.forEach(hu => { if (palette.length<64) palette.push({hex:hslHex(hu,s,l),h:hu,s,l,a}); }); renderPal();
      });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = 'return {\\n';
        palette.forEach(c => { const rgb=hexRgb(c.hex); lua+='  { r = '+rgb.r+', g = '+rgb.g+', b = '+rgb.b+', a = '+c.a+' }, -- '+c.hex+'\\n'; });
        lua += '}';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });

      updateColor(); renderPal();
      vscode.postMessage({ type: 'stateChanged', state: { ready: true } });
    `);
  }
}
