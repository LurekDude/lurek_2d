import * as vscode from "vscode";

/**
 * A single item in the Luna sidebar tree views.
 */
export class SidebarItem extends vscode.TreeItem {
  constructor(
    public readonly label: string,
    public readonly collapsibleState: vscode.TreeItemCollapsibleState,
    public readonly commandId?: string,
    public readonly icon?: string
  ) {
    super(label, collapsibleState);
    if (commandId) {
      this.command = {
        command: commandId,
        title: label,
      };
    }
    if (icon) {
      this.iconPath = new vscode.ThemeIcon(icon);
    }
  }
}

// ─── Project Tools ───────────────────────────────────────────

export class ProjectToolsProvider
  implements vscode.TreeDataProvider<SidebarItem>
{
  private readonly _onDidChangeTreeData =
    new vscode.EventEmitter<SidebarItem | undefined>();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;

  refresh(): void {
    this._onDidChangeTreeData.fire(undefined);
  }

  getTreeItem(element: SidebarItem): SidebarItem {
    return element;
  }

  getChildren(element?: SidebarItem): SidebarItem[] {
    if (!element) {
      return [
        new SidebarItem(
          "Create",
          vscode.TreeItemCollapsibleState.Expanded,
          undefined,
          "new-folder"
        ),
        new SidebarItem(
          "Package",
          vscode.TreeItemCollapsibleState.Collapsed,
          undefined,
          "package"
        ),
        new SidebarItem(
          "Libraries",
          vscode.TreeItemCollapsibleState.Collapsed,
          undefined,
          "library"
        ),
      ];
    }

    switch (element.label) {
      case "Create":
        return [
          new SidebarItem(
            "New Project from Template",
            vscode.TreeItemCollapsibleState.None,
            "luna.scaffold.project",
            "file-add"
          ),
          new SidebarItem(
            "New File from Template",
            vscode.TreeItemCollapsibleState.None,
            "luna.scaffold.file",
            "new-file"
          ),
        ];
      case "Package":
        return [
          new SidebarItem(
            "Package .zip",
            vscode.TreeItemCollapsibleState.None,
            "luna.package.zip",
            "file-zip"
          ),
          new SidebarItem(
            "Package for Windows",
            vscode.TreeItemCollapsibleState.None,
            "luna.package.windows",
            "desktop-download"
          ),
          new SidebarItem(
            "Package for Linux",
            vscode.TreeItemCollapsibleState.None,
            "luna.package.linux",
            "terminal-linux"
          ),
        ];
      case "Libraries":
        return [
          new SidebarItem(
            "Install Library",
            vscode.TreeItemCollapsibleState.None,
            "luna.library.install",
            "cloud-download"
          ),
          new SidebarItem(
            "List Libraries",
            vscode.TreeItemCollapsibleState.None,
            "luna.library.list",
            "list-unordered"
          ),
        ];
      default:
        return [];
    }
  }
}

// ─── Dev Tools ───────────────────────────────────────────────

export class DevToolsProvider
  implements vscode.TreeDataProvider<SidebarItem>
{
  private readonly _onDidChangeTreeData =
    new vscode.EventEmitter<SidebarItem | undefined>();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;

  refresh(): void {
    this._onDidChangeTreeData.fire(undefined);
  }

  getTreeItem(element: SidebarItem): SidebarItem {
    return element;
  }

  getChildren(element?: SidebarItem): SidebarItem[] {
    if (!element) {
      return [
        new SidebarItem(
          "Run",
          vscode.TreeItemCollapsibleState.Expanded,
          undefined,
          "play"
        ),
        new SidebarItem(
          "Testing",
          vscode.TreeItemCollapsibleState.Collapsed,
          undefined,
          "beaker"
        ),
        new SidebarItem(
          "Editors",
          vscode.TreeItemCollapsibleState.Collapsed,
          undefined,
          "window"
        ),
        new SidebarItem(
          "Debug",
          vscode.TreeItemCollapsibleState.Collapsed,
          undefined,
          "bug"
        ),
        new SidebarItem(
          "Reference",
          vscode.TreeItemCollapsibleState.Collapsed,
          undefined,
          "book"
        ),
        new SidebarItem(
          "Assets",
          vscode.TreeItemCollapsibleState.Collapsed,
          undefined,
          "file-media"
        ),
        new SidebarItem(
          "Dependencies",
          vscode.TreeItemCollapsibleState.Collapsed,
          undefined,
          "list-tree"
        ),
        new SidebarItem(
          "Performance",
          vscode.TreeItemCollapsibleState.Collapsed,
          undefined,
          "dashboard"
        ),
      ];
    }

    switch (element.label) {
      case "Run":
        return [
          new SidebarItem(
            "Run Game",
            vscode.TreeItemCollapsibleState.None,
            "luna.runGame",
            "play"
          ),
          new SidebarItem(
            "Stop Game",
            vscode.TreeItemCollapsibleState.None,
            "luna.stopGame",
            "debug-stop"
          ),
          new SidebarItem(
            "Run with Arguments",
            vscode.TreeItemCollapsibleState.None,
            "luna.runWithArgs",
            "terminal"
          ),
          new SidebarItem(
            "Run Example",
            vscode.TreeItemCollapsibleState.None,
            "luna.runExample",
            "file-code"
          ),
        ];
      case "Testing":
        return [
          new SidebarItem(
            "Open Test Runner",
            vscode.TreeItemCollapsibleState.None,
            "luna.editor.testRunner",
            "beaker"
          ),
          new SidebarItem(
            "Run All Tests",
            vscode.TreeItemCollapsibleState.None,
            "luna.test.all",
            "testing-run-all-icon"
          ),
          new SidebarItem(
            "Run Lua Tests",
            vscode.TreeItemCollapsibleState.None,
            "luna.test.lua.all",
            "test-view-icon"
          ),
          new SidebarItem(
            "Run Golden Tests",
            vscode.TreeItemCollapsibleState.None,
            "luna.test.lua.golden",
            "file-media"
          ),
          new SidebarItem(
            "Generate Tests for File",
            vscode.TreeItemCollapsibleState.None,
            "luna.test.generateForFile",
            "wand"
          ),
        ];
      case "Editors":
        return [
          // ── Level / World ─────────────────────────────────────
          new SidebarItem("Tile Map Editor", vscode.TreeItemCollapsibleState.None, "luna.editor.tileMap", "symbol-misc"),
          new SidebarItem("Tileset Editor", vscode.TreeItemCollapsibleState.None, "luna.editor.tileset", "layers"),
          new SidebarItem("Tilemap Script Editor", vscode.TreeItemCollapsibleState.None, "luna.editor.tilemapScript", "code"),
          new SidebarItem("World Map Editor", vscode.TreeItemCollapsibleState.None, "luna.editor.worldMap", "map"),
          new SidebarItem("Procedural Map Generator", vscode.TreeItemCollapsibleState.None, "luna.editor.procMap", "globe"),
          // ── Art / Visual ──────────────────────────────────────
          new SidebarItem("Pixel Art Editor", vscode.TreeItemCollapsibleState.None, "luna.editor.pixelArt", "paintcan"),
          new SidebarItem("Sprite Animation Editor", vscode.TreeItemCollapsibleState.None, "luna.editor.spriteAnim", "play-circle"),
          new SidebarItem("Shader Preview", vscode.TreeItemCollapsibleState.None, "luna.editor.shaderPreview", "wand"),
          new SidebarItem("Color Palette", vscode.TreeItemCollapsibleState.None, "luna.editor.colorPalette", "symbol-color"),
          new SidebarItem("Font Preview", vscode.TreeItemCollapsibleState.None, "luna.editor.fontPreview", "text-size"),
          // ── Game Design ───────────────────────────────────────
          new SidebarItem("Scene Flow Editor", vscode.TreeItemCollapsibleState.None, "luna.editor.sceneFlow", "type-hierarchy"),
          new SidebarItem("Entity Designer", vscode.TreeItemCollapsibleState.None, "luna.editor.entity", "symbol-class"),
          new SidebarItem("Dialog Editor", vscode.TreeItemCollapsibleState.None, "luna.editor.dialog", "comment-discussion"),
          new SidebarItem("Quest Tree Editor", vscode.TreeItemCollapsibleState.None, "luna.editor.questTree", "git-merge"),
          new SidebarItem("GUI Widget Editor", vscode.TreeItemCollapsibleState.None, "luna.editor.guiWidget", "symbol-interface"),
          new SidebarItem("Timeline / Cutscene", vscode.TreeItemCollapsibleState.None, "luna.editor.timeline", "history"),
          new SidebarItem("Input Mapper", vscode.TreeItemCollapsibleState.None, "luna.editor.inputMapper", "keyboard"),
          new SidebarItem("Localization Editor", vscode.TreeItemCollapsibleState.None, "luna.editor.localization", "book"),
          // ── Simulation ────────────────────────────────────────
          new SidebarItem("Particle Designer", vscode.TreeItemCollapsibleState.None, "luna.editor.particle", "sparkle"),
          new SidebarItem("Physics Materials", vscode.TreeItemCollapsibleState.None, "luna.editor.physicsMaterials", "settings-gear"),
          new SidebarItem("AI Behavior Tree", vscode.TreeItemCollapsibleState.None, "luna.editor.aiBehavior", "hubot"),
          new SidebarItem("Voxel Editor", vscode.TreeItemCollapsibleState.None, "luna.editor.voxel", "layers"),
          // ── Audio / FX ───────────────────────────────────────
          new SidebarItem("Audio Mixer", vscode.TreeItemCollapsibleState.None, "luna.editor.audioMixer", "unmute"),
          new SidebarItem("Sound DSP Panel", vscode.TreeItemCollapsibleState.None, "luna.editor.soundDsp", "radio-tower"),
          new SidebarItem("PostFX & Overlay Designer", vscode.TreeItemCollapsibleState.None, "luna.editor.postfxOverlay", "color-mode"),
          // ── Data ──────────────────────────────────────────────
          new SidebarItem("Database Browser", vscode.TreeItemCollapsibleState.None, "luna.editor.database", "database"),
          new SidebarItem("Graph Editor", vscode.TreeItemCollapsibleState.None, "luna.editor.graph", "graph"),
        ];
      case "Debug":
        return [
          new SidebarItem("Debug Run + Connect", vscode.TreeItemCollapsibleState.None, "luna.debug.runAndConnect", "debug-start"),
          new SidebarItem("Connect", vscode.TreeItemCollapsibleState.None, "luna.debug.connect", "plug"),
          new SidebarItem("Disconnect", vscode.TreeItemCollapsibleState.None, "luna.debug.disconnect", "debug-disconnect"),
          new SidebarItem("Evaluate Lua", vscode.TreeItemCollapsibleState.None, "luna.debug.evaluate", "terminal"),
          new SidebarItem("Watchers Panel", vscode.TreeItemCollapsibleState.None, "luna.debug.openWatchers", "eye"),
          new SidebarItem("Variable Inspector", vscode.TreeItemCollapsibleState.None, "luna.debug.openInspector", "symbol-variable"),
          new SidebarItem("Call Stack", vscode.TreeItemCollapsibleState.None, "luna.debug.openCallStack", "list-tree"),
          new SidebarItem("Performance", vscode.TreeItemCollapsibleState.None, "luna.debug.performance", "dashboard"),
          new SidebarItem("Screenshot", vscode.TreeItemCollapsibleState.None, "luna.debug.screenshot", "device-camera"),
          new SidebarItem("Status", vscode.TreeItemCollapsibleState.None, "luna.debug.status", "info"),
        ];
      case "Reference":
        return [
          new SidebarItem("Browse API", vscode.TreeItemCollapsibleState.None, "luna.browseApi", "search"),
          new SidebarItem("Open API Docs", vscode.TreeItemCollapsibleState.None, "luna.openApiDocs", "book"),
          new SidebarItem("Open Wiki", vscode.TreeItemCollapsibleState.None, "luna.openWiki", "globe"),
          new SidebarItem("Dependency Graph", vscode.TreeItemCollapsibleState.None, "luna.depGraph", "graph"),
          new SidebarItem("Dependency List", vscode.TreeItemCollapsibleState.None, "luna.depList", "list-tree"),
          new SidebarItem("API Coverage", vscode.TreeItemCollapsibleState.None, "luna.apiCoverage", "graph-line"),
        ];
      case "Assets":
        return [
          new SidebarItem("Refresh Assets", vscode.TreeItemCollapsibleState.None, "luna.assets.refresh", "refresh"),
          new SidebarItem("Open Asset Explorer", vscode.TreeItemCollapsibleState.None, "luna.assets.openPanel", "file-media"),
          new SidebarItem("Find Missing Assets", vscode.TreeItemCollapsibleState.None, "luna.assets.findMissing", "warning"),
        ];
      case "Dependencies":
        return [
          new SidebarItem("Show Module Graph", vscode.TreeItemCollapsibleState.None, "luna.deps.showGraph", "type-hierarchy"),
          new SidebarItem("Find Circular Deps", vscode.TreeItemCollapsibleState.None, "luna.deps.findCircular", "warning"),
          new SidebarItem("Show Orphan Modules", vscode.TreeItemCollapsibleState.None, "luna.deps.findOrphans", "question"),
        ];
      case "Performance":
        return [
          new SidebarItem("Open Performance Dashboard", vscode.TreeItemCollapsibleState.None, "luna.perf.openDashboard", "dashboard"),
          new SidebarItem("System Monitor", vscode.TreeItemCollapsibleState.None, "luna.system.openMonitor", "pulse"),
          new SidebarItem("API Usage Report", vscode.TreeItemCollapsibleState.None, "luna.api.usageReport", "graph"),
          new SidebarItem("Open Hot Reload History", vscode.TreeItemCollapsibleState.None, "luna.perf.openHotReload", "history"),
          new SidebarItem("Clear History", vscode.TreeItemCollapsibleState.None, "luna.perf.clearHistory", "clear-all"),
        ];
      default:
        return [];
    }
  }
}

// ─── AI & Copilot ────────────────────────────────────────────

export class AiToolsProvider
  implements vscode.TreeDataProvider<SidebarItem>
{
  private readonly _onDidChangeTreeData =
    new vscode.EventEmitter<SidebarItem | undefined>();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;

  refresh(): void {
    this._onDidChangeTreeData.fire(undefined);
  }

  getTreeItem(element: SidebarItem): SidebarItem {
    return element;
  }

  getChildren(element?: SidebarItem): SidebarItem[] {
    if (!element) {
      return [
        new SidebarItem(
          "CAG (AI Config)",
          vscode.TreeItemCollapsibleState.Expanded,
          undefined,
          "hubot"
        ),
        new SidebarItem(
          "MCP Server",
          vscode.TreeItemCollapsibleState.Collapsed,
          undefined,
          "server"
        ),
        new SidebarItem(
          "Game Jam",
          vscode.TreeItemCollapsibleState.Collapsed,
          undefined,
          "flame"
        ),
      ];
    }

    switch (element.label) {
      case "CAG (AI Config)":
        return [
          new SidebarItem("Install AI Config", vscode.TreeItemCollapsibleState.None, "luna.cag.install", "cloud-download"),
          new SidebarItem("Select Agent", vscode.TreeItemCollapsibleState.None, "luna.cag.selectAgent", "person"),
          new SidebarItem("Select Skill", vscode.TreeItemCollapsibleState.None, "luna.cag.selectSkill", "mortar-board"),
          new SidebarItem("Select Prompt", vscode.TreeItemCollapsibleState.None, "luna.cag.selectPrompt", "comment"),
          new SidebarItem("Update CAG Files", vscode.TreeItemCollapsibleState.None, "luna.cag.update", "sync"),
        ];
      case "MCP Server":
        return [
          new SidebarItem("Install MCP Server", vscode.TreeItemCollapsibleState.None, "luna.mcp.install", "cloud-download"),
          new SidebarItem("MCP Status", vscode.TreeItemCollapsibleState.None, "luna.mcp.status", "info"),
        ];
      case "Game Jam":
        return [
          new SidebarItem("Game Jam Timer", vscode.TreeItemCollapsibleState.None, "luna.jam.timer", "watch"),
          new SidebarItem("Quick Build", vscode.TreeItemCollapsibleState.None, "luna.jam.quickBuild", "zap"),
          new SidebarItem("Submission Checklist", vscode.TreeItemCollapsibleState.None, "luna.jam.checklist", "checklist"),
        ];
      default:
        return [];
    }
  }
}
