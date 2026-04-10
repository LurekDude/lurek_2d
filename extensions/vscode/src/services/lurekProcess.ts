import * as vscode from "vscode";
import * as child_process from "child_process";
import * as path from "path";
import * as fs from "fs";

/**
 * Manages the Lurek2D game process lifecycle — finding the binary,
 * launching, stopping, and reporting status.
 */
export class LurekProcessService {
  private process: child_process.ChildProcess | null = null;
  private terminal: vscode.Terminal | null = null;
  private readonly _onStatusChange = new vscode.EventEmitter<boolean>();
  public readonly onStatusChange = this._onStatusChange.event;

  /**
   * Finds the lurek2d binary. Checks the user setting first,
   * then PATH, then falls back to `cargo run`.
   */
  async findLurekBinary(): Promise<string> {
    // 1. Check user setting
    const configured = vscode.workspace
      .getConfiguration("lurek")
      .get<string>("enginePath", "");
    if (configured && fs.existsSync(configured)) {
      return configured;
    }

    // 2. Check PATH for lurek2d
    const binaryName = process.platform === "win32" ? "lurek2d.exe" : "lurek2d";
    const pathDirs = (process.env.PATH ?? "").split(path.delimiter);
    for (const dir of pathDirs) {
      const candidate = path.join(dir, binaryName);
      if (fs.existsSync(candidate)) {
        return candidate;
      }
    }

    // 3. Check workspace for cargo
    const workspaceRoot = getWorkspaceRoot();
    if (workspaceRoot) {
      const cargoToml = path.join(workspaceRoot, "Cargo.toml");
      if (fs.existsSync(cargoToml)) {
        return "cargo run --";
      }
    }

    throw new Error(
      "Lurek2D binary not found. Install it or set lurek.lurekPath in settings."
    );
  }

  /**
   * Runs the game in an integrated terminal.
   */
  async run(gameDir: string, args: string[] = []): Promise<void> {
    if (this.isRunning()) {
      vscode.window.showWarningMessage("Lurek2D is already running.");
      return;
    }

    const saveOnRun = vscode.workspace
      .getConfiguration("lurek")
      .get<boolean>("saveOnRun", true);
    if (saveOnRun) {
      await vscode.workspace.saveAll(false);
    }

    const binary = await this.findLurekBinary();
    const cmd = binary.startsWith("cargo run")
      ? `${binary} ${gameDir} ${args.join(" ")}`.trim()
      : `"${binary}" ${gameDir} ${args.join(" ")}`.trim();

    this.terminal = vscode.window.createTerminal({
      name: "Lurek2D",
      cwd: getWorkspaceRoot(),
    });
    this.terminal.show();
    this.terminal.sendText(cmd);

    this._onStatusChange.fire(true);
    vscode.commands.executeCommand("setContext", "lurek.gameRunning", true);
  }

  /**
   * Stops the running game process.
   */
  stop(): void {
    if (this.terminal) {
      this.terminal.dispose();
      this.terminal = null;
    }
    if (this.process) {
      this.process.kill();
      this.process = null;
    }
    this._onStatusChange.fire(false);
    vscode.commands.executeCommand("setContext", "lurek.gameRunning", false);
  }

  /**
   * Returns whether a game process is currently running.
   */
  isRunning(): boolean {
    return this.terminal !== null;
  }

  dispose(): void {
    this.stop();
    this._onStatusChange.dispose();
  }
}

function getWorkspaceRoot(): string | undefined {
  const folders = vscode.workspace.workspaceFolders;
  return folders?.[0]?.uri.fsPath;
}
