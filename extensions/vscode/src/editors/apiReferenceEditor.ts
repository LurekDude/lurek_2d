import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml, ICONS, iconButton, panelSection, fieldInline, toolbarSep, toolbarSpacer } from "./shared.js";
import { resolveWorkspaceApiDocPath } from "../services/apiDocs.js";

export class ApiReferenceEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): ApiReferenceEditor {
    return new ApiReferenceEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "lurek.editor.apiReference", "API Reference");
    this.loadApiData();
  }

  private async loadApiData(): Promise<void> {
    try {
      const workspaceFolders = vscode.workspace.workspaceFolders;
      if (!workspaceFolders) { return; }
      const apiPath = resolveWorkspaceApiDocPath(workspaceFolders[0].uri.fsPath);
      if (!apiPath) { return; }
      const data = await vscode.workspace.fs.readFile(vscode.Uri.file(apiPath));
      const text = new (globalThis as any).TextDecoder().decode(data) as string;
      this.panel.webview.postMessage({ type: "apiData", content: text });
    } catch {
      // Ignore — editor works with built-in data
    }
  }

  protected handleMessage(msg: { type: string;[key: string]: unknown }): void {
    // No export needed for reference browser
  }

  protected getHtml(): string {
    const nonce = getNonce();
    return wrapHtml(nonce, "API Reference", `
      .editor-layout {
        display: grid; grid-template-columns: 200px 1fr;
        grid-template-rows: auto 1fr auto; height: 100vh;
      }
      .toolbar { grid-column: 1 / -1; }
      .status-bar { grid-column: 1 / -1; }
      .module-list { grid-row: 2; overflow-y: auto; border-right: 1px solid var(--border); background: var(--surface); }
      .doc-panel { grid-row: 2; overflow-y: auto; padding: 12px 20px; background: var(--bg); }

      .module-item {
        padding: 5px 10px; cursor: pointer; border-radius: var(--radius); font-size: 11px;
        margin: 1px 4px; display: flex; justify-content: space-between; align-items: center;
        border: 1px solid transparent; transition: border-color 0.1s, background 0.08s;
      }
      .module-item:hover { border-color: var(--accent); background: var(--hover); }
      .module-item.sel { background: var(--selection); border-color: var(--accent); }
      .module-count { font-size: 9px; color: var(--text-dim); background: var(--surface-2); padding: 1px 5px; border-radius: 9px; }

      .func-card {
        background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius);
        padding: 10px; margin-bottom: 8px;
      }
      .func-card h3 { font-size: 13px; color: var(--accent-2); margin-bottom: 3px; font-family: 'Cascadia Code', monospace; }
      .func-card .sig { font-size: 11px; color: var(--accent); font-family: 'Cascadia Code', monospace; margin-bottom: 6px; background: rgba(0,0,0,0.2); padding: 4px 8px; border-radius: var(--radius); }
      .func-card .desc { font-size: 11px; line-height: 1.5; }
      .func-card .param { font-size: 10px; color: var(--text-dim); margin-left: 12px; }
      .func-card .returns { font-size: 10px; color: #4ec9b0; margin-top: 4px; }

      .module-header { font-size: 15px; font-weight: 700; margin-bottom: 8px; padding-bottom: 6px; border-bottom: 1px solid var(--border); }
      .module-desc { font-size: 11px; color: var(--text-dim); margin-bottom: 14px; line-height: 1.5; }
      .tag { display: inline-block; padding: 1px 6px; border-radius: 9px; font-size: 9px; margin-left: 6px; font-weight: 600; }
      .tag.event { background: rgba(76,175,80,0.15); color: #4caf50; }
    `, `
      <div class="editor-layout">
        <!-- Toolbar -->
        <div class="toolbar">
          <div class="group" style="flex:1">
            <input id="searchInput" placeholder="Search functions, modules…" style="flex:1;max-width:260px">
            <select id="filterType">
              <option value="">All Types</option>
              <option value="function">Functions</option>
              <option value="callback">Callbacks</option>
              <option value="constant">Constants</option>
            </select>
          </div>
        </div>

        <!-- Module List -->
        <div class="module-list" id="moduleList"></div>

        <!-- Doc Panel -->
        <div class="doc-panel" id="docPanel">
          <div class="module-header">Lurek2D API Reference</div>
          <div class="module-desc">Select a module from the left panel to browse its API.</div>
        </div>

        <!-- Status Bar -->
        <div class="status-bar">
          <span id="statusModules" class="badge">0 modules</span>
          <div class="sep"></div>
          <span id="statusFuncs">0 functions</span>
          <div class="spacer"></div>
          <span id="statusSource" style="font-size:10px;color:var(--text-dim)">Built-in data</span>
        </div>
      </div>
    `, `
      const API_DATA = {
        'lurek.graphic': {
          desc: 'Drawing primitives, colors, transforms, and render state. Also available as lurek.render table.',
          funcs: [
            { name: 'lurek.graphic.rectangle', sig: 'lurek.graphic.rectangle(mode, x, y, w, h)', desc: 'Draw a rectangle.', params: ['mode: "fill" or "line"', 'x, y: position', 'w, h: size'], returns: 'nil' },
            { name: 'lurek.graphic.circle', sig: 'lurek.graphic.circle(mode, x, y, r)', desc: 'Draw a circle.', params: ['mode: "fill" or "line"', 'x, y: center', 'r: radius'], returns: 'nil' },
            { name: 'lurek.graphic.line', sig: 'lurek.graphic.line(x1, y1, x2, y2)', desc: 'Draw a line between two points.', params: ['x1, y1: start point', 'x2, y2: end point'], returns: 'nil' },
            { name: 'lurek.graphic.print', sig: 'lurek.graphic.print(text, x, y)', desc: 'Draw text at position.', params: ['text: string to draw', 'x, y: position'], returns: 'nil' },
            { name: 'lurek.graphic.setColor', sig: 'lurek.graphic.setColor(r, g, b, a)', desc: 'Set the active drawing color.', params: ['r, g, b: 0-1 color channels', 'a: alpha (default 1)'], returns: 'nil' },
            { name: 'lurek.graphic.setBackgroundColor', sig: 'lurek.graphic.setBackgroundColor(r, g, b)', desc: 'Set the background clear color.', params: ['r, g, b: 0-1 color channels'], returns: 'nil' },
            { name: 'lurek.graphic.draw', sig: 'lurek.graphic.draw(image, x, y, r, sx, sy)', desc: 'Draw an image/texture.', params: ['image: texture object', 'x, y: position', 'r: rotation (radians)', 'sx, sy: scale'], returns: 'nil' },
            { name: 'lurek.graphic.newImage', sig: 'lurek.graphic.newImage(path)', desc: 'Load an image from file and return texture handle.', params: ['path: file path relative to game dir'], returns: 'Image' },
          ]
        },
        'lurek.input.keyboard': {
          desc: 'Keyboard input state and key queries.',
          funcs: [
            { name: 'lurek.input.keyboard.isDown', sig: 'lurek.input.keyboard.isDown(key)', desc: 'Check if a key is currently held down.', params: ['key: key name ("space", "a", "left", etc.)'], returns: 'boolean' },
            { name: 'lurek.input.keyboard.isUp', sig: 'lurek.input.keyboard.isUp(key)', desc: 'Check if a key is not pressed.', params: ['key: key name'], returns: 'boolean' },
          ]
        },
        'lurek.input.mouse': {
          desc: 'Mouse position and button queries.',
          funcs: [
            { name: 'lurek.input.mouse.getPosition', sig: 'lurek.input.mouse.getPosition()', desc: 'Get current mouse position.', params: [], returns: 'x, y' },
            { name: 'lurek.input.mouse.isDown', sig: 'lurek.input.mouse.isDown(button)', desc: 'Check if a mouse button is held.', params: ['button: 1=left, 2=right, 3=middle'], returns: 'boolean' },
          ]
        },
        'lurek.audio': {
          desc: 'Sound loading and playback.',
          funcs: [
            { name: 'lurek.audio.newSource', sig: 'lurek.audio.newSource(path, type)', desc: 'Load an audio source.', params: ['path: file path', 'type: "static" or "stream"'], returns: 'Source' },
            { name: 'lurek.audio.play', sig: 'lurek.audio.play(source)', desc: 'Play an audio source.', params: ['source: Source object'], returns: 'nil' },
            { name: 'lurek.audio.stop', sig: 'lurek.audio.stop(source)', desc: 'Stop an audio source.', params: ['source: Source object'], returns: 'nil' },
            { name: 'lurek.audio.setVolume', sig: 'lurek.audio.setVolume(source, vol)', desc: 'Set volume of a source.', params: ['source: Source object', 'vol: 0.0-1.0'], returns: 'nil' },
          ]
        },
        'lurek.physics': {
          desc: 'Physics world, bodies, and collision.',
          funcs: [
            { name: 'lurek.physics.newWorld', sig: 'lurek.physics.newWorld(gx, gy)', desc: 'Create a physics world.', params: ['gx, gy: gravity vector'], returns: 'World' },
            { name: 'lurek.physics.newBody', sig: 'lurek.physics.newBody(world, x, y, type)', desc: 'Create a physics body.', params: ['world: World', 'x, y: position', 'type: "dynamic", "static", "kinematic"'], returns: 'Body' },
            { name: 'lurek.physics.update', sig: 'lurek.physics.update(world, dt)', desc: 'Step the physics world.', params: ['world: World', 'dt: time step'], returns: 'nil' },
          ]
        },
        'lurek.timer': {
          desc: 'Time and delta queries.',
          funcs: [
            { name: 'lurek.timer.getDelta', sig: 'lurek.timer.getDelta()', desc: 'Get time since last frame in seconds.', params: [], returns: 'number' },
            { name: 'lurek.timer.getFPS', sig: 'lurek.timer.getFPS()', desc: 'Get current frames per second.', params: [], returns: 'number' },
            { name: 'lurek.timer.getTime', sig: 'lurek.timer.getTime()', desc: 'Get time since engine start.', params: [], returns: 'number' },
          ]
        },
        'lurek.window': {
          desc: 'Window management.',
          funcs: [
            { name: 'lurek.window.setTitle', sig: 'lurek.window.setTitle(title)', desc: 'Set window title.', params: ['title: string'], returns: 'nil' },
            { name: 'lurek.window.getWidth', sig: 'lurek.window.getWidth()', desc: 'Get window width.', params: [], returns: 'number' },
            { name: 'lurek.window.getHeight', sig: 'lurek.window.getHeight()', desc: 'Get window height.', params: [], returns: 'number' },
            { name: 'lurek.window.setMode', sig: 'lurek.window.setMode(w, h, flags)', desc: 'Set window size and mode.', params: ['w, h: dimensions', 'flags: table with fullscreen, vsync, etc.'], returns: 'nil' },
          ]
        },
        'lurek.math': {
          desc: 'Math utilities.',
          funcs: [
            { name: 'lurek.math.random', sig: 'lurek.math.random(min, max)', desc: 'Random number between min and max.', params: ['min, max: range bounds'], returns: 'number' },
            { name: 'lurek.math.lerp', sig: 'lurek.math.lerp(a, b, t)', desc: 'Linear interpolation.', params: ['a, b: values', 't: 0-1 factor'], returns: 'number' },
            { name: 'lurek.math.clamp', sig: 'lurek.math.clamp(x, min, max)', desc: 'Clamp value to range.', params: ['x: value', 'min, max: bounds'], returns: 'number' },
          ]
        },
        'Callbacks': {
          desc: 'Engine callback functions set by game scripts. These are called by the engine main loop.',
          funcs: [
            { name: 'lurek.init', sig: 'function lurek.init()', desc: 'Called once when the game starts. Initialize resources here.', params: [], returns: 'nil', tag: 'event' },
            { name: 'lurek.process', sig: 'function lurek.process(dt)', desc: 'Called every frame. Update game logic.', params: ['dt: delta time in seconds'], returns: 'nil', tag: 'event' },
            { name: 'lurek.draw', sig: 'function lurek.draw()', desc: 'Called every frame after process. Push draw commands here using lurek.render.* functions.', params: [], returns: 'nil', tag: 'event' },
            { name: 'lurek.draw_ui', sig: 'function lurek.draw_ui()', desc: 'Called after draw. Draw UI elements on top using lurek.render.* functions.', params: [], returns: 'nil', tag: 'event' },
            { name: 'lurek.keypressed', sig: 'function lurek.keypressed(key)', desc: 'Called when key is pressed.', params: ['key: key name string'], returns: 'nil', tag: 'event' },
            { name: 'lurek.mousepressed', sig: 'function lurek.mousepressed(x, y, btn)', desc: 'Called on mouse press.', params: ['x, y: position', 'btn: button number'], returns: 'nil', tag: 'event' },
          ]
        }
      };

      let selectedModule = '';
      let loadedMarkdown = '';

      function renderModuleList() {
        const el = document.getElementById('moduleList');
        const search = document.getElementById('searchInput').value.toLowerCase();
        el.innerHTML = '';
        let totalFuncs = 0;
        for (const mod of Object.keys(API_DATA)) {
          const funcs = API_DATA[mod].funcs;
          totalFuncs += funcs.length;
          const matchesMod = mod.toLowerCase().includes(search);
          const matchingFuncs = funcs.filter(f => f.name.toLowerCase().includes(search) || f.desc.toLowerCase().includes(search));
          if (!matchesMod && matchingFuncs.length === 0 && search) continue;
          const div = document.createElement('div');
          div.className = 'module-item' + (mod === selectedModule ? ' sel' : '');
          div.innerHTML = '<span>' + mod + '</span><span class="module-count">' + funcs.length + '</span>';
          div.addEventListener('click', () => { selectedModule = mod; renderModuleList(); renderDocs(); });
          el.appendChild(div);
        }
        document.getElementById('statusModules').textContent = Object.keys(API_DATA).length + ' modules';
        document.getElementById('statusFuncs').textContent = totalFuncs + ' functions';
      }

      function renderDocs() {
        const el = document.getElementById('docPanel');
        if (!selectedModule || !API_DATA[selectedModule]) {
          el.innerHTML = '<div class="module-header">Lurek2D API Reference</div><div class="module-desc">Select a module from the left panel to browse its API.</div>';
          if (loadedMarkdown) {
            el.innerHTML += '<div style="white-space:pre-wrap;font-size:11px;color:var(--text-dim);max-height:80vh;overflow-y:auto;margin-top:12px">' + escapeHtml(loadedMarkdown.substring(0, 5000)) + '</div>';
          }
          return;
        }
        const mod = API_DATA[selectedModule];
        const search = document.getElementById('searchInput').value.toLowerCase();
        const filterType = document.getElementById('filterType').value;

        let html = '<div class="module-header">' + selectedModule + '</div>';
        html += '<div class="module-desc">' + mod.desc + '</div>';

        const funcs = mod.funcs.filter(f => {
          if (search && !f.name.toLowerCase().includes(search) && !f.desc.toLowerCase().includes(search)) return false;
          if (filterType === 'callback' && f.tag !== 'event') return false;
          if (filterType === 'function' && f.tag === 'event') return false;
          return true;
        });

        for (const f of funcs) {
          html += '<div class="func-card">';
          html += '<h3>' + f.name + (f.tag ? '<span class="tag ' + f.tag + '">' + f.tag + '</span>' : '') + '</h3>';
          html += '<div class="sig">' + f.sig + '</div>';
          html += '<div class="desc">' + f.desc + '</div>';
          if (f.params.length) {
            html += '<div style="margin-top:4px;font-size:10px;color:var(--text-dim)">Parameters:</div>';
            for (const p of f.params) html += '<div class="param">• ' + p + '</div>';
          }
          html += '<div class="returns">Returns: ' + f.returns + '</div>';
          html += '</div>';
        }

        if (funcs.length === 0) html += '<p style="color:var(--text-dim);font-size:11px">No matching functions found.</p>';
        el.innerHTML = html;
      }

      function escapeHtml(text) {
        return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
      }

      document.getElementById('searchInput').addEventListener('input', () => { renderModuleList(); renderDocs(); });
      document.getElementById('filterType').addEventListener('change', () => renderDocs());

      window.addEventListener('message', (e) => {
        if (e.data.type === 'apiData') {
          loadedMarkdown = e.data.content;
          document.getElementById('statusSource').textContent = 'Workspace API data loaded';
          renderDocs();
        }
      });

      renderModuleList();
      renderDocs();
    `);
  }
}
