import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";

export class FontPreviewEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): FontPreviewEditor {
    return new FontPreviewEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.fontPreviewEditor", "Font Preview");
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    switch (msg.type) {
      case "exportLua":
        this.exportLua(msg.content as string, "font_config.lua");
        break;
    }
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "Font Preview", `
      .editor-layout {
        display: grid; grid-template-columns: 1fr 200px;
        grid-template-rows: auto 1fr auto;
        height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .preview-area { grid-row: 2; overflow-y: auto; padding: 12px; }
      .config-panel { grid-row: 2; overflow-y: auto; border-left: 1px solid var(--border); background: var(--surface); padding: 6px; }
      .text-input-bar { padding: 6px 12px; background: var(--surface); border-bottom: 1px solid var(--border); }
      .text-input-bar input { width: 100%; font-size: 12px; padding: 4px 8px; }
      .specimen-block { margin-bottom: 14px; }
      .specimen-label { font-size: 10px; color: var(--text-dim); margin-bottom: 3px; }
      .specimen-text { word-wrap: break-word; }
      .glyph-grid { display: grid; grid-template-columns: repeat(16, 1fr); gap: 1px; margin-top: 8px; }
      .glyph-cell {
        aspect-ratio: 1; display: flex; align-items: center; justify-content: center;
        background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius);
        cursor: pointer; font-size: 14px; min-height: 28px; transition: border-color 0.08s;
      }
      .glyph-cell:hover { border-color: var(--accent); background: var(--hover); }
      .glyph-cell.sel { border-color: var(--accent); background: var(--selection); }
      .size-preview { border-bottom: 1px solid var(--border); padding-bottom: 8px; margin-bottom: 8px; }
      .color-row { display: flex; align-items: center; gap: 6px; }
      .preset-size { font-size: 10px; padding: 2px 6px; min-width: 26px; }
    `, `
      <div class="editor-layout">
        <div class="toolbar">
          <div class="group">
            <label style="font-size:10px">Font:</label>
            <select id="fontFamily" style="width:130px;font-size:10px">
              <option value="sans-serif">Sans-Serif</option>
              <option value="serif">Serif</option>
              <option value="monospace">Monospace</option>
              <option value="cursive">Cursive</option>
              <option value="fantasy">Fantasy</option>
            </select>
          </div>
          ${toolbarSep()}
          <div class="group">
            <label style="font-size:10px">Size:</label>
            <input type="range" id="fontSize" min="8" max="72" value="24" style="width:80px">
            <span id="sizeLabel" style="font-size:10px;min-width:30px">24pt</span>
          </div>
          ${toolbarSep()}
          <div class="group">
            <button id="btnBold" style="font-weight:700;font-size:11px;padding:2px 6px">B</button>
            <button id="btnItalic" style="font-style:italic;font-size:11px;padding:2px 6px">I</button>
          </div>
          ${toolbarSpacer()}
          ${iconButton(ICONS.save, 'btnExport', 'Export Lua')}
        </div>

        <div class="preview-area" id="previewArea">
          <div class="text-input-bar">
            <input type="text" id="sampleText" value="The quick brown fox jumps over the lazy dog. 0123456789" placeholder="Type sample text...">
          </div>
          <div style="padding-top:10px;">
            <div class="specimen-block size-preview" id="multiSizePreview"></div>
            <div class="specimen-block">
              <div class="specimen-label">Preview</div>
              <div class="specimen-text" id="mainPreview" style="font-size:24px;"></div>
            </div>
            <div class="specimen-block">
              <div class="specimen-label">Character Map</div>
              <div class="glyph-grid" id="glyphGrid"></div>
            </div>
          </div>
        </div>

        <div class="config-panel">
          ${panelSection('Text Color', `
            <div class="color-row">
              <input type="color" id="textColor" value="#cccccc">
              <span id="textColorHex" style="font-size:10px">#cccccc</span>
            </div>
          `)}
          ${panelSection('Background', `
            <div class="color-row">
              <input type="color" id="bgColor" value="#1e1e1e">
              <span id="bgColorHex" style="font-size:10px">#1e1e1e</span>
            </div>
          `)}
          ${panelSection('Spacing', `
            ${fieldInline('Line Height: <span id="lhVal">1.5</span>', '<input type="range" id="lineHeight" min="10" max="30" value="15" style="width:100%">')}
            ${fieldInline('Letter Spacing: <span id="lsVal">0</span>px', '<input type="range" id="letterSpacing" min="-5" max="20" value="0" style="width:100%">')}
          `)}
          ${panelSection('Selected Glyph', `
            <div style="text-align:center;font-size:40px;padding:8px;" id="selectedGlyph">A</div>
            <div style="text-align:center;font-size:10px;color:var(--text-dim);" id="glyphInfo">U+0041 | Code: 65</div>
          `)}
          ${panelSection('Quick Sizes', `
            <div style="display:flex;flex-wrap:wrap;gap:3px">
              <button class="preset-size" data-s="8">8</button>
              <button class="preset-size" data-s="12">12</button>
              <button class="preset-size" data-s="16">16</button>
              <button class="preset-size" data-s="24">24</button>
              <button class="preset-size" data-s="32">32</button>
              <button class="preset-size" data-s="48">48</button>
              <button class="preset-size" data-s="72">72</button>
            </div>
          `)}
        </div>

        <div class="status-bar">
          <span id="statusFont" class="badge">sans-serif</span>
          <div class="sep"></div>
          <span id="statusSize">24pt</span>
          <div class="sep"></div>
          <span id="statusGlyphs">95 glyphs</span>
          <div class="spacer"></div>
          <span id="statusDirty" style="font-size:10px;color:var(--text-dim)">${ICONS.clean}</span>
        </div>
      </div>
    `, `
      let fontFamily = 'sans-serif', fontSize = 24, bold = false, italic = false;
      let textColor = '#cccccc', bgColor = '#1e1e1e', lineHeight = 1.5, letterSpacing = 0;
      const PRINTABLE_START = 32, PRINTABLE_END = 126;

      function getStyle(size) { return (italic ? 'italic ' : '') + (bold ? 'bold ' : '') + (size || fontSize) + 'px ' + fontFamily; }

      function updatePreview() {
        const text = document.getElementById('sampleText').value;
        const main = document.getElementById('mainPreview');
        main.style.font = getStyle(); main.style.color = textColor;
        main.style.lineHeight = lineHeight; main.style.letterSpacing = letterSpacing + 'px';
        main.textContent = text;
        document.getElementById('previewArea').style.background = bgColor;
        const multi = document.getElementById('multiSizePreview'); multi.innerHTML = '';
        [8, 12, 16, 24, 32, 48].forEach(s => {
          const div = document.createElement('div');
          div.style.font = getStyle(s); div.style.color = textColor; div.style.marginBottom = '6px';
          div.style.lineHeight = lineHeight; div.style.letterSpacing = letterSpacing + 'px';
          const label = document.createElement('span'); label.className = 'specimen-label'; label.textContent = s + 'pt  ';
          div.appendChild(label); div.appendChild(document.createTextNode(text));
          multi.appendChild(div);
        });
      }

      function buildGlyphGrid() {
        const grid = document.getElementById('glyphGrid'); grid.innerHTML = '';
        for (let code = PRINTABLE_START; code <= PRINTABLE_END; code++) {
          const cell = document.createElement('div'); cell.className = 'glyph-cell';
          cell.style.fontFamily = fontFamily; cell.textContent = String.fromCharCode(code);
          cell.addEventListener('click', () => {
            grid.querySelectorAll('.glyph-cell').forEach(c => c.classList.remove('sel'));
            cell.classList.add('sel');
            document.getElementById('selectedGlyph').textContent = String.fromCharCode(code);
            document.getElementById('selectedGlyph').style.fontFamily = fontFamily;
            document.getElementById('glyphInfo').textContent = 'U+' + code.toString(16).toUpperCase().padStart(4, '0') + ' | Code: ' + code;
          });
          grid.appendChild(cell);
        }
        document.getElementById('statusGlyphs').textContent = (PRINTABLE_END - PRINTABLE_START + 1) + ' glyphs';
      }

      document.getElementById('fontFamily').addEventListener('change', e => {
        fontFamily = e.target.value; document.getElementById('statusFont').textContent = fontFamily;
        markDirty(); updatePreview(); buildGlyphGrid();
      });
      document.getElementById('fontSize').addEventListener('input', e => {
        fontSize = parseInt(e.target.value); document.getElementById('sizeLabel').textContent = fontSize + 'pt';
        document.getElementById('statusSize').textContent = fontSize + 'pt'; updatePreview();
      });
      document.getElementById('btnBold').addEventListener('click', e => { bold = !bold; e.target.classList.toggle('sel', bold); markDirty(); updatePreview(); });
      document.getElementById('btnItalic').addEventListener('click', e => { italic = !italic; e.target.classList.toggle('sel', italic); markDirty(); updatePreview(); });
      document.getElementById('sampleText').addEventListener('input', updatePreview);
      document.getElementById('textColor').addEventListener('input', e => { textColor = e.target.value; document.getElementById('textColorHex').textContent = textColor; markDirty(); updatePreview(); });
      document.getElementById('bgColor').addEventListener('input', e => { bgColor = e.target.value; document.getElementById('bgColorHex').textContent = bgColor; markDirty(); updatePreview(); });
      document.getElementById('lineHeight').addEventListener('input', e => { lineHeight = parseInt(e.target.value) / 10; document.getElementById('lhVal').textContent = lineHeight.toFixed(1); updatePreview(); });
      document.getElementById('letterSpacing').addEventListener('input', e => { letterSpacing = parseInt(e.target.value); document.getElementById('lsVal').textContent = letterSpacing; updatePreview(); });
      document.querySelectorAll('.preset-size').forEach(b => {
        b.addEventListener('click', () => { fontSize = parseInt(b.dataset.s); document.getElementById('fontSize').value = fontSize; document.getElementById('sizeLabel').textContent = fontSize + 'pt'; updatePreview(); });
      });
      document.getElementById('btnExport').addEventListener('click', () => {
        let lua = '-- Font configuration for Lurek2D\\n';
        lua += 'local font = lurek.graphic.newFont("' + fontFamily + '", ' + fontSize + ')\\n';
        lua += '-- Style: ' + (bold ? 'bold ' : '') + (italic ? 'italic' : 'normal') + '\\n';
        lua += '-- Color: { ' + parseInt(textColor.slice(1,3),16) + ', ' + parseInt(textColor.slice(3,5),16) + ', ' + parseInt(textColor.slice(5,7),16) + ' }\\n';
        lua += '-- Line height: ' + lineHeight.toFixed(1) + ', Letter spacing: ' + letterSpacing + '\\n';
        vscode.postMessage({ type: 'exportLua', content: lua });
      });
      registerShortcut('ctrl+s', () => document.getElementById('btnExport').click());

      updatePreview(); buildGlyphGrid();
    `);
  }
}
