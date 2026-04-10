import * as vscode from "vscode";
import * as path from "path";
import * as fs from "fs";
import { LurekProcessService } from "../services/lurekProcess.js";

/**
 * Runs the game from the workspace root or a chosen directory.
 */
export async function runGame(lurekProcess: LurekProcessService): Promise<void> {
  const root = getWorkspaceRoot();
  if (!root) {
    vscode.window.showErrorMessage("No workspace folder open.");
    return;
  }

  // Determine game directory
  const srcDir = vscode.workspace
    .getConfiguration("lurek")
    .get<string>("srcDir", "");
  const gameDir = srcDir ? path.join(root, srcDir) : root;

  try {
    await lurekProcess.run(gameDir);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    vscode.window.showErrorMessage(`Failed to run Lurek2D: ${msg}`);
  }
}

/**
 * Stops the currently running game.
 */
export function stopGame(lurekProcess: LurekProcessService): void {
  if (!lurekProcess.isRunning()) {
    vscode.window.showInformationMessage("No Lurek2D game is running.");
    return;
  }
  lurekProcess.stop();
  vscode.window.showInformationMessage("Lurek2D game stopped.");
}

/**
 * Runs the game with user-provided extra arguments.
 */
export async function runWithArgs(
  lurekProcess: LurekProcessService
): Promise<void> {
  const args = await vscode.window.showInputBox({
    prompt: "Enter arguments for Lurek2D",
    placeHolder: "e.g. --debug --fps-cap 60",
  });
  if (args === undefined) {
    return;
  }

  const root = getWorkspaceRoot();
  if (!root) {
    vscode.window.showErrorMessage("No workspace folder open.");
    return;
  }

  const srcDir = vscode.workspace
    .getConfiguration("lurek")
    .get<string>("srcDir", "");
  const gameDir = srcDir ? path.join(root, srcDir) : root;

  try {
    await lurekProcess.run(gameDir, args.split(/\s+/).filter(Boolean));
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    vscode.window.showErrorMessage(`Failed to run Lurek2D: ${msg}`);
  }
}

/**
 * Shows a quick-pick list of example projects and runs the selected one.
 */
export async function runExample(
  lurekProcess: LurekProcessService
): Promise<void> {
  const root = getWorkspaceRoot();
  if (!root) {
    vscode.window.showErrorMessage("No workspace folder open.");
    return;
  }

  const examplesDir = path.join(root, "content", "demos");
  if (!fs.existsSync(examplesDir)) {
    vscode.window.showWarningMessage("No content/content/demos/ directory found.");
    return;
  }

  const examples = fs
    .readdirSync(examplesDir, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name);

  if (examples.length === 0) {
    vscode.window.showWarningMessage("No examples found.");
    return;
  }

  const selected = await vscode.window.showQuickPick(examples, {
    placeHolder: "Select a demo to run",
  });
  if (!selected) {
    return;
  }

  try {
    await lurekProcess.run(path.join(examplesDir, selected));
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    vscode.window.showErrorMessage(`Failed to run example: ${msg}`);
  }
}

function getWorkspaceRoot(): string | undefined {
  return vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
}
