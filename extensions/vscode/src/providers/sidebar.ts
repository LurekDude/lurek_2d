import * as vscode from "vscode";
import * as fs from "fs";
import * as path from "path";

/**
 * A single item in the Lurek2D sidebar tree views.
 */
export class SidebarItem extends vscode.TreeItem {
  constructor(
    public readonly label: string,
    public readonly collapsibleState: vscode.TreeItemCollapsibleState,
    public readonly commandId?: string,
    public readonly icon?: string,
    public readonly statusDescription?: string,
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
    if (statusDescription) {
      this.description = statusDescription;
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
          "Project Health",
          vscode.TreeItemCollapsibleState.Expanded,
          undefined,
          "heart"
        ),
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
      case "Project Health":
        return this.getProjectHealthItems();
      case "Create":
        return [
          new SidebarItem(
            "New Project from Template",
            vscode.TreeItemCollapsibleState.None,
            "lurek.scaffold.project",
            "file-add"
          ),
          new SidebarItem(
            "New File from Template",
            vscode.TreeItemCollapsibleState.None,
            "lurek.scaffold.file",
            "new-file"
          ),
        ];
      case "Package":
        return [
          new SidebarItem(
            "Package .zip",
            vscode.TreeItemCollapsibleState.None,
            "lurek.package.zip",
            "file-zip"
          ),
          new SidebarItem(
            "Package for Windows",
            vscode.TreeItemCollapsibleState.None,
            "lurek.package.windows",
            "desktop-download"
          ),
          new SidebarItem(
            "Package for Linux",
            vscode.TreeItemCollapsibleState.None,
            "lurek.package.linux",
            "terminal-linux"
          ),
        ];
      case "Libraries":
        return [
          new SidebarItem(
            "Browse Pattern Library",
            vscode.TreeItemCollapsibleState.None,
            "lurek.library.browse",
            "search"
          ),
          new SidebarItem(
            "Insert Code Snippet",
            vscode.TreeItemCollapsibleState.None,
            "lurek.library.insertSnippet",
            "code"
          ),
          new SidebarItem(
            "Save Selection as Pattern",
            vscode.TreeItemCollapsibleState.None,
            "lurek.library.newPattern",
            "save"
          ),
        ];
      default:
        return [];
    }
  }

  /** Scans the workspace for key project files and returns health indicators. */
  private getProjectHealthItems(): SidebarItem[] {
    const wsRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (!wsRoot) {
      return [
        new SidebarItem("No workspace open", vscode.TreeItemCollapsibleState.None, undefined, "warning"),
      ];
    }

    const items: SidebarItem[] = [];

    // Check main.lua
    const hasMainLua = fs.existsSync(path.join(wsRoot, "main.lua"));
    items.push(new SidebarItem(
      "main.lua",
      vscode.TreeItemCollapsibleState.None,
      hasMainLua ? undefined : "lurek.scaffold.file",
      hasMainLua ? "pass" : "error",
      hasMainLua ? "found" : "missing"
    ));

    // Check conf.lua
    const hasConfLua = fs.existsSync(path.join(wsRoot, "conf.lua"));
    items.push(new SidebarItem(
      "conf.lua",
      vscode.TreeItemCollapsibleState.None,
      undefined,
      hasConfLua ? "pass" : "warning",
      hasConfLua ? "found" : "optional"
    ));

    // Count Lua files
    let luaFileCount = 0;
    try {
      const countLuaFiles = (dir: string): void => {
        const entries = fs.readdirSync(dir, { withFileTypes: true });
        for (const entry of entries) {
          if (entry.name.startsWith(".") || entry.name === "node_modules") { continue; }
          const fullPath = path.join(dir, entry.name);
          if (entry.isDirectory()) {
            countLuaFiles(fullPath);
          } else if (entry.name.endsWith(".lua")) {
            luaFileCount++;
          }
        }
      };
      countLuaFiles(wsRoot);
    } catch { /* ignore fs errors */ }
    items.push(new SidebarItem(
      "Lua files",
      vscode.TreeItemCollapsibleState.None,
      undefined,
      "file-code",
      `${luaFileCount}`
    ));

    // Check if tests exist
    const hasTests = fs.existsSync(path.join(wsRoot, "tests")) ||
                     fs.existsSync(path.join(wsRoot, "test")) ||
                     fs.existsSync(path.join(wsRoot, "tests.lua"));
    items.push(new SidebarItem(
      "Tests",
      vscode.TreeItemCollapsibleState.None,
      undefined,
      hasTests ? "pass" : "warning",
      hasTests ? "detected" : "none found"
    ));

    return items;
  }
}

// ─── Dev Tools ───────────────────────────────────────────────

export class DevToolsProvider
  implements vscode.TreeDataProvider<SidebarItem>
{
  private readonly _onDidChangeTreeData =
    new vscode.EventEmitter<SidebarItem | undefined>();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;

  private _gameStatus: "stopped" | "running" | "crashed" = "stopped";
  private _lastTestResult: string | undefined;

  /** Update the game running status and refresh the tree. */
  setGameStatus(status: "stopped" | "running" | "crashed"): void {
    this._gameStatus = status;
    this._onDidChangeTreeData.fire(undefined);
  }

  /** Update the last test result summary and refresh the tree. */
  setTestResult(summary: string): void {
    this._lastTestResult = summary;
    this._onDidChangeTreeData.fire(undefined);
  }

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
            "Game Status",
            vscode.TreeItemCollapsibleState.None,
            undefined,
            this._gameStatus === "running" ? "debug-start" :
            this._gameStatus === "crashed" ? "error" : "debug-stop",
            this._gameStatus
          ),
          new SidebarItem(
            "Run Game",
            vscode.TreeItemCollapsibleState.None,
            "lurek.runGame",
            "play"
          ),
          new SidebarItem(
            "Stop Game",
            vscode.TreeItemCollapsibleState.None,
            "lurek.stopGame",
            "debug-stop"
          ),
          new SidebarItem(
            "Run with Arguments",
            vscode.TreeItemCollapsibleState.None,
            "lurek.runWithArgs",
            "terminal"
          ),
          new SidebarItem(
            "Run Example",
            vscode.TreeItemCollapsibleState.None,
            "lurek.runExample",
            "file-code"
          ),
        ];
      case "Testing":
        return [
          ...(this._lastTestResult ? [
            new SidebarItem(
              "Last Result",
              vscode.TreeItemCollapsibleState.None,
              undefined,
              this._lastTestResult.includes("fail") ? "error" : "pass",
              this._lastTestResult
            ),
          ] : []),
          new SidebarItem(
            "Open Test Runner",
            vscode.TreeItemCollapsibleState.None,
            "lurek.editor.testRunner",
            "beaker"
          ),
          new SidebarItem(
            "Run All Tests",
            vscode.TreeItemCollapsibleState.None,
            "lurek.test.all",
            "testing-run-all-icon"
          ),
          new SidebarItem(
            "Run Lua Tests",
            vscode.TreeItemCollapsibleState.None,
            "lurek.test.lua.all",
            "test-view-icon"
          ),
          new SidebarItem(
            "Run Golden Tests",
            vscode.TreeItemCollapsibleState.None,
            "lurek.test.lua.golden",
            "file-media"
          ),
          new SidebarItem(
            "Generate Tests for File",
            vscode.TreeItemCollapsibleState.None,
            "lurek.test.generateForFile",
            "wand"
          ),
        ];
      case "Editors":
        return [
          // ── Level / World ─────────────────────────────────────
          new SidebarItem("Tile Map Editor", vscode.TreeItemCollapsibleState.None, "lurek.editor.tileMap", "symbol-misc"),
          new SidebarItem("Tileset Editor", vscode.TreeItemCollapsibleState.None, "lurek.editor.tileset", "layers"),
          new SidebarItem("Tilemap Script Editor", vscode.TreeItemCollapsibleState.None, "lurek.editor.tilemapScript", "code"),
          new SidebarItem("World Map Editor", vscode.TreeItemCollapsibleState.None, "lurek.editor.worldMap", "map"),
          new SidebarItem("Procedural Map Generator", vscode.TreeItemCollapsibleState.None, "lurek.editor.procMap", "globe"),
          // ── Art / Visual ──────────────────────────────────────
          new SidebarItem("Pixel Art Editor", vscode.TreeItemCollapsibleState.None, "lurek.editor.pixelArt", "paintcan"),
          new SidebarItem("Sprite Animation Editor", vscode.TreeItemCollapsibleState.None, "lurek.editor.spriteAnim", "play-circle"),
          new SidebarItem("Shader Preview", vscode.TreeItemCollapsibleState.None, "lurek.editor.shaderPreview", "wand"),
          new SidebarItem("Color Palette", vscode.TreeItemCollapsibleState.None, "lurek.editor.colorPalette", "symbol-color"),
          new SidebarItem("Font Preview", vscode.TreeItemCollapsibleState.None, "lurek.editor.fontPreview", "text-size"),
          // ── Game Design ───────────────────────────────────────
          new SidebarItem("Scene Flow Editor", vscode.TreeItemCollapsibleState.None, "lurek.editor.sceneFlow", "type-hierarchy"),
          new SidebarItem("Entity Designer", vscode.TreeItemCollapsibleState.None, "lurek.editor.entity", "symbol-class"),
          new SidebarItem("Dialog Editor", vscode.TreeItemCollapsibleState.None, "lurek.editor.dialog", "comment-discussion"),
          new SidebarItem("Quest Tree Editor", vscode.TreeItemCollapsibleState.None, "lurek.editor.questTree", "git-merge"),
          new SidebarItem("GUI Widget Editor", vscode.TreeItemCollapsibleState.None, "lurek.editor.guiWidget", "symbol-interface"),
          new SidebarItem("Timeline / Cutscene", vscode.TreeItemCollapsibleState.None, "lurek.editor.timeline", "history"),
          new SidebarItem("Input Mapper", vscode.TreeItemCollapsibleState.None, "lurek.editor.inputMapper", "keyboard"),
          new SidebarItem("Localization Editor", vscode.TreeItemCollapsibleState.None, "lurek.editor.localization", "book"),
          // ── Simulation ────────────────────────────────────────
          new SidebarItem("Particle Designer", vscode.TreeItemCollapsibleState.None, "lurek.editor.particle", "sparkle"),
          new SidebarItem("Physics Materials", vscode.TreeItemCollapsibleState.None, "lurek.editor.physicsMaterials", "settings-gear"),
          new SidebarItem("AI Behavior Tree", vscode.TreeItemCollapsibleState.None, "lurek.editor.aiBehavior", "hubot"),
          new SidebarItem("Voxel Editor", vscode.TreeItemCollapsibleState.None, "lurek.editor.voxel", "layers"),
          // ── Audio / FX ───────────────────────────────────────
          new SidebarItem("Audio Mixer", vscode.TreeItemCollapsibleState.None, "lurek.editor.audioMixer", "unmute"),
          new SidebarItem("Sound DSP Panel", vscode.TreeItemCollapsibleState.None, "lurek.editor.soundDsp", "radio-tower"),
          new SidebarItem("PostFX & Overlay Designer", vscode.TreeItemCollapsibleState.None, "lurek.editor.postfxOverlay", "color-mode"),
          // ── Data ──────────────────────────────────────────────
          new SidebarItem("Database Browser", vscode.TreeItemCollapsibleState.None, "lurek.editor.database", "database"),
          new SidebarItem("Graph Editor", vscode.TreeItemCollapsibleState.None, "lurek.editor.graph", "graph"),
        ];
      case "Debug":
        return [
          new SidebarItem("Debug Run + Connect", vscode.TreeItemCollapsibleState.None, "lurek.debug.runAndConnect", "debug-start"),
          new SidebarItem("Connect", vscode.TreeItemCollapsibleState.None, "lurek.debug.connect", "plug"),
          new SidebarItem("Disconnect", vscode.TreeItemCollapsibleState.None, "lurek.debug.disconnect", "debug-disconnect"),
          new SidebarItem("Evaluate Lua", vscode.TreeItemCollapsibleState.None, "lurek.debug.evaluate", "terminal"),
          new SidebarItem("Watchers Panel", vscode.TreeItemCollapsibleState.None, "lurek.debug.openWatchers", "eye"),
          new SidebarItem("Variable Inspector", vscode.TreeItemCollapsibleState.None, "lurek.debug.openInspector", "symbol-variable"),
          new SidebarItem("Call Stack", vscode.TreeItemCollapsibleState.None, "lurek.debug.openCallStack", "list-tree"),
          new SidebarItem("Performance", vscode.TreeItemCollapsibleState.None, "lurek.debug.performance", "dashboard"),
          new SidebarItem("Screenshot", vscode.TreeItemCollapsibleState.None, "lurek.debug.screenshot", "device-camera"),
          new SidebarItem("Status", vscode.TreeItemCollapsibleState.None, "lurek.debug.status", "info"),
        ];
      case "Reference":
        return [
          new SidebarItem("Browse API", vscode.TreeItemCollapsibleState.None, "lurek.browseApi", "search"),
          new SidebarItem("Open API Docs", vscode.TreeItemCollapsibleState.None, "lurek.openApiDocs", "book"),
          new SidebarItem("Open Wiki", vscode.TreeItemCollapsibleState.None, "lurek.openWiki", "globe"),
          new SidebarItem("Dependency Graph", vscode.TreeItemCollapsibleState.None, "lurek.depGraph", "graph"),
          new SidebarItem("Dependency List", vscode.TreeItemCollapsibleState.None, "lurek.depList", "list-tree"),
          new SidebarItem("API Coverage", vscode.TreeItemCollapsibleState.None, "lurek.apiCoverage", "graph-line"),
        ];
      case "Assets":
        return [
          new SidebarItem("Refresh Assets", vscode.TreeItemCollapsibleState.None, "lurek.assets.refresh", "refresh"),
          new SidebarItem("Open Asset Explorer", vscode.TreeItemCollapsibleState.None, "lurek.assets.openPanel", "file-media"),
          new SidebarItem("Find Missing Assets", vscode.TreeItemCollapsibleState.None, "lurek.assets.findMissing", "warning"),
        ];
      case "Dependencies":
        return [
          new SidebarItem("Show Module Graph", vscode.TreeItemCollapsibleState.None, "lurek.deps.showGraph", "type-hierarchy"),
          new SidebarItem("Find Circular Deps", vscode.TreeItemCollapsibleState.None, "lurek.deps.findCircular", "warning"),
          new SidebarItem("Show Orphan Modules", vscode.TreeItemCollapsibleState.None, "lurek.deps.findOrphans", "question"),
        ];
      case "Performance":
        return [
          new SidebarItem("Open Performance Dashboard", vscode.TreeItemCollapsibleState.None, "lurek.perf.openDashboard", "dashboard"),
          new SidebarItem("System Monitor", vscode.TreeItemCollapsibleState.None, "lurek.runtime.openMonitor", "pulse"),
          new SidebarItem("API Usage Report", vscode.TreeItemCollapsibleState.None, "lurek.api.usageReport", "graph"),
          new SidebarItem("Open Hot Reload History", vscode.TreeItemCollapsibleState.None, "lurek.perf.openHotReload", "history"),
          new SidebarItem("Clear History", vscode.TreeItemCollapsibleState.None, "lurek.perf.clearHistory", "clear-all"),
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
          new SidebarItem("Install AI Config", vscode.TreeItemCollapsibleState.None, "lurek.cag.install", "cloud-download"),
          new SidebarItem("Select Agent", vscode.TreeItemCollapsibleState.None, "lurek.cag.selectAgent", "person"),
          new SidebarItem("Select Skill", vscode.TreeItemCollapsibleState.None, "lurek.cag.selectSkill", "mortar-board"),
          new SidebarItem("Select Prompt", vscode.TreeItemCollapsibleState.None, "lurek.cag.selectPrompt", "comment"),
          new SidebarItem("Update CAG Files", vscode.TreeItemCollapsibleState.None, "lurek.cag.update", "sync"),
        ];
      case "MCP Server":
        return [
          new SidebarItem("Install MCP Server", vscode.TreeItemCollapsibleState.None, "lurek.mcp.install", "cloud-download"),
          new SidebarItem("MCP Status", vscode.TreeItemCollapsibleState.None, "lurek.mcp.status", "info"),
        ];
      case "Game Jam":
        return [
          new SidebarItem("Game Jam Quick Start", vscode.TreeItemCollapsibleState.None, "lurek.gameJam.quickStart", "rocket"),
          new SidebarItem("Add Game Module", vscode.TreeItemCollapsibleState.None, "lurek.gameJam.addModule", "add"),
          new SidebarItem("Game Jam Timer", vscode.TreeItemCollapsibleState.None, "lurek.gameJam.timer", "watch"),
          new SidebarItem("Quick Build", vscode.TreeItemCollapsibleState.None, "lurek.jam.quickBuild", "zap"),
          new SidebarItem("Submission Checklist", vscode.TreeItemCollapsibleState.None, "lurek.jam.checklist", "checklist"),
        ];
      default:
        return [];
    }
  }
}
