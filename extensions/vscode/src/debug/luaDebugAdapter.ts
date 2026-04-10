import * as vscode from "vscode";
import { LuaDebugSession } from "./luaDebugSession.js";

export class LuaDebugAdapterFactory
  implements vscode.DebugAdapterDescriptorFactory
{
  createDebugAdapterDescriptor(
    _session: vscode.DebugSession,
    _executable: vscode.DebugAdapterExecutable | undefined,
  ): vscode.ProviderResult<vscode.DebugAdapterDescriptor> {
    return new vscode.DebugAdapterInlineImplementation(new LuaDebugSession());
  }
}

export class LuaDebugConfigurationProvider
  implements vscode.DebugConfigurationProvider
{
  resolveDebugConfiguration(
    folder: vscode.WorkspaceFolder | undefined,
    config: vscode.DebugConfiguration,
    _token?: vscode.CancellationToken,
  ): vscode.ProviderResult<vscode.DebugConfiguration> {
    if (!config.type) {
      config.type = "lurek";
    }
    if (!config.request) {
      config.request = "launch";
    }
    if (!config.name) {
      config.name = "Lurek2D: Debug Game";
    }
    if (!config.program) {
      // Auto-detect: look for main.lua in workspace root or active editor dir
      const wsRoot = folder?.uri.fsPath ?? vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
      const activeFile = vscode.window.activeTextEditor?.document.uri.fsPath;

      if (activeFile) {
        // If the active file is a main.lua, use its directory as the game path
        const activeDir = require("path").dirname(activeFile);
        const mainLua = require("path").join(activeDir, "main.lua");
        if (require("fs").existsSync(mainLua)) {
          config.program = activeDir;
        } else {
          config.program = wsRoot ?? "${workspaceFolder}";
        }
      } else {
        config.program = wsRoot ?? "${workspaceFolder}";
      }
    }
    if (!config.luaVersion) {
      config.luaVersion = vscode.workspace
        .getConfiguration("lurek")
        .get("luaVersion", "luajit");
    }
    if (config.stopOnEntry === undefined) {
      config.stopOnEntry = false;
    }
    if (!config.debugPort) {
      config.debugPort = 8172;
    }
    // Auto-detect engine binary from workspace build/ folder
    if (!config.enginePath) {
      const wsRoot = folder?.uri.fsPath ?? vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
      if (wsRoot) {
        const buildDebug = require("path").join(wsRoot, "build", "debug", process.platform === "win32" ? "lurek2d.exe" : "lurek2d");
        const buildRelease = require("path").join(wsRoot, "build", "release", process.platform === "win32" ? "lurek2d.exe" : "lurek2d");
        if (require("fs").existsSync(buildDebug)) {
          config.enginePath = buildDebug;
        } else if (require("fs").existsSync(buildRelease)) {
          config.enginePath = buildRelease;
        }
      }
    }
    return config;
  }

  provideDebugConfigurations(
    _folder: vscode.WorkspaceFolder | undefined,
  ): vscode.ProviderResult<vscode.DebugConfiguration[]> {
    return [
      {
        type: "lurek",
        request: "launch",
        name: "Lurek2D: Debug Game",
        program: "${workspaceFolder}",
        stopOnEntry: false,
      },
      {
        type: "lurek",
        request: "launch",
        name: "Lurek2D: Debug Current Demo",
        program: "${fileDirname}",
        stopOnEntry: false,
      },
      {
        type: "lurek",
        request: "launch",
        name: "Lurek2D: Debug with Stop on Entry",
        program: "${workspaceFolder}",
        stopOnEntry: true,
      },
      {
        type: "lurek",
        request: "attach",
        name: "Lurek2D: Attach to Running",
        debugPort: 8172,
      },
    ];
  }
}

export function register(context: vscode.ExtensionContext): void {
  const factory = new LuaDebugAdapterFactory();
  const configProvider = new LuaDebugConfigurationProvider();

  context.subscriptions.push(
    vscode.debug.registerDebugAdapterDescriptorFactory("lurek", factory),
    vscode.debug.registerDebugConfigurationProvider("lurek", configProvider),
  );
}
