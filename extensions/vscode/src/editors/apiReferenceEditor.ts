import * as vscode from "vscode";
import { WebviewEditor, getNonce, wrapHtml } from "./shared.js";

export class ApiReferenceEditor extends WebviewEditor {
  static open(context: vscode.ExtensionContext): ApiReferenceEditor {
    return new ApiReferenceEditor(context);
  }

  private constructor(context: vscode.ExtensionContext) {
    super(context, "luna.editor.apiReference", "API Reference");
    this.loadApiData();
  }

  private async loadApiData(): Promise<void> {
    // Try to read api_data.json or the generated markdown
    try {
      const workspaceFolders = vscode.workspace.workspaceFolders;
      if (!workspaceFolders) { return; }
      const root = workspaceFolders[0].uri;
      const apiPath = vscode.Uri.joinPath(root, "docs", "API", "lua_api_reference_generated.md");
      const data = await vscode.workspace.fs.readFile(apiPath);
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
        display: grid; grid-template-columns: 220px 1fr;
        grid-template-rows: auto 1fr; height: 100vh;
      }
      .search-bar { grid-column: 1 / -1; padding: 6px 10px; background: var(--surface); border-bottom: 1px solid var(--border); display: flex; gap: 8px; }
      .search-bar input { flex: 1; }
      .module-list { grid-row: 2; overflow-y: auto; }
      .doc-panel { grid-row: 2; overflow-y: auto; padding: 16px 24px; }
      .module-item { padding: 4px 12px; cursor: pointer; border-radius: 3px; font-size: 12px; }
      .module-item:hover { background: var(--surface-2); }
      .module-item.sel { background: var(--selection); }
      .func-card {
        background: var(--surface); border: 1px solid var(--border); border-radius: 4px;
        padding: 12px; margin-bottom: 10px;
      }
      .func-card h3 { font-size: 14px; color: var(--accent-2); margin-bottom: 4px; font-family: 'Cascadia Code', monospace; }
      .func-card .sig { font-size: 12px; color: var(--accent); font-family: 'Cascadia Code', monospace; margin-bottom: 6px; }
      .func-card .desc { font-size: 12px; line-height: 1.5; }
      .func-card .param { font-size: 11px; color: var(--text-dim); margin-left: 12px; }
      .func-card .returns { font-size: 11px; color: #4ec9b0; margin-top: 4px; }
      .module-header { font-size: 16px; font-weight: bold; margin-bottom: 12px; padding-bottom: 6px; border-bottom: 1px solid var(--border); }
      .module-desc { font-size: 12px; color: var(--text-dim); margin-bottom: 16px; }
      .tag { display: inline-block; padding: 1px 6px; border-radius: 3px; font-size: 10px; margin-left: 6px; }
      .tag.read { background: #1e3a5f; color: #4ec9b0; }
      .tag.write { background: #3a1e2a; color: #ff77a8; }
      .tag.event { background: #2a3a1e; color: #4caf50; }
    `, `
      <div class="editor-layout">
        <div class="search-bar">
          <input id="searchInput" placeholder="Search functions, modules...">
          <select id="filterType">
            <option value="">All</option>
            <option value="function">Functions</option>
            <option value="callback">Callbacks</option>
            <option value="constant">Constants</option>
          </select>
        </div>
        <div class="panel module-list" id="moduleList"></div>
        <div class="doc-panel" id="docPanel">
          <div class="module-header">Luna2D API Reference</div>
          <div class="module-desc">Select a module from the left panel to browse its API functions.</div>
        </div>
      </div>
    `, `
      const API_DATA = {
        'luna.graphics': {
          desc: 'Drawing primitives, colors, transforms, and render state.',
          funcs: [
            { name: 'luna.graphics.rectangle', sig: 'luna.graphics.rectangle(mode, x, y, w, h)', desc: 'Draw a rectangle.', params: ['mode: "fill" or "line"', 'x, y: position', 'w, h: size'], returns: 'nil' },
            { name: 'luna.graphics.circle', sig: 'luna.graphics.circle(mode, x, y, r)', desc: 'Draw a circle.', params: ['mode: "fill" or "line"', 'x, y: center', 'r: radius'], returns: 'nil' },
            { name: 'luna.graphics.line', sig: 'luna.graphics.line(x1, y1, x2, y2)', desc: 'Draw a line between two points.', params: ['x1, y1: start point', 'x2, y2: end point'], returns: 'nil' },
            { name: 'luna.graphics.print', sig: 'luna.graphics.print(text, x, y)', desc: 'Draw text at position.', params: ['text: string to draw', 'x, y: position'], returns: 'nil' },
            { name: 'luna.graphics.setColor', sig: 'luna.graphics.setColor(r, g, b, a)', desc: 'Set the active drawing color.', params: ['r, g, b: 0-1 color channels', 'a: alpha (default 1)'], returns: 'nil' },
            { name: 'luna.graphics.setBackgroundColor', sig: 'luna.graphics.setBackgroundColor(r, g, b)', desc: 'Set the background clear color.', params: ['r, g, b: 0-1 color channels'], returns: 'nil' },
            { name: 'luna.graphics.draw', sig: 'luna.graphics.draw(image, x, y, r, sx, sy)', desc: 'Draw an image/texture.', params: ['image: texture object', 'x, y: position', 'r: rotation (radians)', 'sx, sy: scale'], returns: 'nil' },
            { name: 'luna.graphics.newImage', sig: 'luna.graphics.newImage(path)', desc: 'Load an image from file and return texture handle.', params: ['path: file path relative to game dir'], returns: 'Image' },
          ]
        },
        'luna.keyboard': {
          desc: 'Keyboard input state and key queries.',
          funcs: [
            { name: 'luna.keyboard.isDown', sig: 'luna.keyboard.isDown(key)', desc: 'Check if a key is currently held down.', params: ['key: key name ("space", "a", "left", etc.)'], returns: 'boolean' },
            { name: 'luna.keyboard.isUp', sig: 'luna.keyboard.isUp(key)', desc: 'Check if a key is not pressed.', params: ['key: key name'], returns: 'boolean' },
          ]
        },
        'luna.mouse': {
          desc: 'Mouse position and button queries.',
          funcs: [
            { name: 'luna.mouse.getPosition', sig: 'luna.mouse.getPosition()', desc: 'Get current mouse position.', params: [], returns: 'x, y' },
            { name: 'luna.mouse.isDown', sig: 'luna.mouse.isDown(button)', desc: 'Check if a mouse button is held.', params: ['button: 1=left, 2=right, 3=middle'], returns: 'boolean' },
          ]
        },
        'luna.audio': {
          desc: 'Sound loading and playback.',
          funcs: [
            { name: 'luna.audio.newSource', sig: 'luna.audio.newSource(path, type)', desc: 'Load an audio source.', params: ['path: file path', 'type: "static" or "stream"'], returns: 'Source' },
            { name: 'luna.audio.play', sig: 'luna.audio.play(source)', desc: 'Play an audio source.', params: ['source: Source object'], returns: 'nil' },
            { name: 'luna.audio.stop', sig: 'luna.audio.stop(source)', desc: 'Stop an audio source.', params: ['source: Source object'], returns: 'nil' },
            { name: 'luna.audio.setVolume', sig: 'luna.audio.setVolume(source, vol)', desc: 'Set volume of a source.', params: ['source: Source object', 'vol: 0.0-1.0'], returns: 'nil' },
          ]
        },
        'luna.physics': {
          desc: 'Physics world, bodies, and collision.',
          funcs: [
            { name: 'luna.physics.newWorld', sig: 'luna.physics.newWorld(gx, gy)', desc: 'Create a physics world.', params: ['gx, gy: gravity vector'], returns: 'World' },
            { name: 'luna.physics.newBody', sig: 'luna.physics.newBody(world, x, y, type)', desc: 'Create a physics body.', params: ['world: World', 'x, y: position', 'type: "dynamic", "static", "kinematic"'], returns: 'Body' },
            { name: 'luna.physics.update', sig: 'luna.physics.update(world, dt)', desc: 'Step the physics world.', params: ['world: World', 'dt: time step'], returns: 'nil' },
          ]
        },
        'luna.timer': {
          desc: 'Time and delta queries.',
          funcs: [
            { name: 'luna.timer.getDelta', sig: 'luna.timer.getDelta()', desc: 'Get time since last frame in seconds.', params: [], returns: 'number' },
            { name: 'luna.timer.getFPS', sig: 'luna.timer.getFPS()', desc: 'Get current frames per second.', params: [], returns: 'number' },
            { name: 'luna.timer.getTime', sig: 'luna.timer.getTime()', desc: 'Get time since engine start.', params: [], returns: 'number' },
          ]
        },
        'luna.window': {
          desc: 'Window management.',
          funcs: [
            { name: 'luna.window.setTitle', sig: 'luna.window.setTitle(title)', desc: 'Set window title.', params: ['title: string'], returns: 'nil' },
            { name: 'luna.window.getWidth', sig: 'luna.window.getWidth()', desc: 'Get window width.', params: [], returns: 'number' },
            { name: 'luna.window.getHeight', sig: 'luna.window.getHeight()', desc: 'Get window height.', params: [], returns: 'number' },
            { name: 'luna.window.setMode', sig: 'luna.window.setMode(w, h, flags)', desc: 'Set window size and mode.', params: ['w, h: dimensions', 'flags: table with fullscreen, vsync, etc.'], returns: 'nil' },
          ]
        },
        'luna.math': {
          desc: 'Math utilities.',
          funcs: [
            { name: 'luna.math.random', sig: 'luna.math.random(min, max)', desc: 'Random number between min and max.', params: ['min, max: range bounds'], returns: 'number' },
            { name: 'luna.math.lerp', sig: 'luna.math.lerp(a, b, t)', desc: 'Linear interpolation.', params: ['a, b: values', 't: 0-1 factor'], returns: 'number' },
            { name: 'luna.math.clamp', sig: 'luna.math.clamp(x, min, max)', desc: 'Clamp value to range.', params: ['x: value', 'min, max: bounds'], returns: 'number' },
          ]
        },
        'Callbacks': {
          desc: 'Engine callback functions set by game scripts.',
          funcs: [
            { name: 'luna.load', sig: 'function luna.load()', desc: 'Called once when the game starts. Initialize resources here.', params: [], returns: 'nil', tag: 'event' },
            { name: 'luna.update', sig: 'function luna.update(dt)', desc: 'Called every frame. Update game logic.', params: ['dt: delta time in seconds'], returns: 'nil', tag: 'event' },
            { name: 'luna.draw', sig: 'function luna.draw()', desc: 'Called every frame after update. Render your game.', params: [], returns: 'nil', tag: 'event' },
            { name: 'luna.keypressed', sig: 'function luna.keypressed(key)', desc: 'Called when key is pressed.', params: ['key: key name string'], returns: 'nil', tag: 'event' },
            { name: 'luna.mousepressed', sig: 'function luna.mousepressed(x, y, btn)', desc: 'Called on mouse press.', params: ['x, y: position', 'btn: button number'], returns: 'nil', tag: 'event' },
          ]
        }
      };

      let selectedModule = '';
      let loadedMarkdown = '';

      function renderModuleList() {
        const el = document.getElementById('moduleList');
        const search = document.getElementById('searchInput').value.toLowerCase();
        el.innerHTML = '';
        for (const mod of Object.keys(API_DATA)) {
          const funcs = API_DATA[mod].funcs;
          const matchesMod = mod.toLowerCase().includes(search);
          const matchingFuncs = funcs.filter(f => f.name.toLowerCase().includes(search) || f.desc.toLowerCase().includes(search));
          if (!matchesMod && matchingFuncs.length === 0 && search) continue;
          const div = document.createElement('div');
          div.className = 'module-item' + (mod === selectedModule ? ' sel' : '');
          div.textContent = mod + ' (' + funcs.length + ')';
          div.addEventListener('click', () => { selectedModule = mod; renderModuleList(); renderDocs(); });
          el.appendChild(div);
        }
      }

      function renderDocs() {
        const el = document.getElementById('docPanel');
        if (!selectedModule || !API_DATA[selectedModule]) {
          el.innerHTML = '<div class="module-header">Luna2D API Reference</div><div class="module-desc">Select a module.</div>';
          if (loadedMarkdown) {
            el.innerHTML += '<div style="white-space:pre-wrap;font-size:12px;color:var(--text-dim);max-height:80vh;overflow-y:auto;margin-top:16px">' + escapeHtml(loadedMarkdown.substring(0, 5000)) + '</div>';
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
            html += '<div style="margin-top:4px;font-size:11px;color:var(--text-dim)">Parameters:</div>';
            for (const p of f.params) html += '<div class="param">\\u2022 ' + p + '</div>';
          }
          html += '<div class="returns">Returns: ' + f.returns + '</div>';
          html += '</div>';
        }

        if (funcs.length === 0) html += '<p style="color:var(--text-dim)">No matching functions found.</p>';
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
          renderDocs();
        }
      });

      renderModuleList();
      renderDocs();
    `);
  }
}
