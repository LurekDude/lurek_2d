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
    _folder: vscode.WorkspaceFolder | undefined,
    config: vscode.DebugConfiguration,
    _token?: vscode.CancellationToken,
  ): vscode.ProviderResult<vscode.DebugConfiguration> {
    if (!config.type) {
      config.type = "luna";
    }
    if (!config.request) {
      config.request = "launch";
    }
    if (!config.name) {
      config.name = "Luna2D: Debug Game";
    }
    if (!config.program) {
      config.program = "${workspaceFolder}";
    }
    if (!config.luaVersion) {
      config.luaVersion = vscode.workspace
        .getConfiguration("luna")
        .get("luaVersion", "luajit");
    }
    if (config.stopOnEntry === undefined) {
      config.stopOnEntry = false;
    }
    if (!config.debugPort) {
      config.debugPort = 8172;
    }
    return config;
  }

  provideDebugConfigurations(
    _folder: vscode.WorkspaceFolder | undefined,
  ): vscode.ProviderResult<vscode.DebugConfiguration[]> {
    return [
      {
        type: "luna",
        request: "launch",
        name: "Luna2D: Debug Game",
        program: "${workspaceFolder}",
        stopOnEntry: false,
      },
      {
        type: "luna",
        request: "attach",
        name: "Luna2D: Attach to Running",
        debugPort: 8172,
      },
    ];
  }
}

export function register(context: vscode.ExtensionContext): void {
  const factory = new LuaDebugAdapterFactory();
  const configProvider = new LuaDebugConfigurationProvider();

  context.subscriptions.push(
    vscode.debug.registerDebugAdapterDescriptorFactory("luna", factory),
    vscode.debug.registerDebugConfigurationProvider("luna", configProvider),
  );
}
