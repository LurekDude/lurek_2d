import * as vscode from "vscode";

/**
 * Packages the game as a zip archive using the platform-appropriate script.
 */
export function packageZip(): void {
  const terminal = getOrCreateTerminal("Lurek2D Package");
  terminal.show();
  if (process.platform === "win32") {
    terminal.sendText("powershell -ExecutionPolicy Bypass -File tools/dist.ps1");
  } else {
    terminal.sendText("bash tools/dist.sh");
  }
}

/**
 * Packages for Windows using dist.ps1.
 */
export function packageWindows(): void {
  const terminal = getOrCreateTerminal("Lurek2D Package");
  terminal.show();
  terminal.sendText("powershell -ExecutionPolicy Bypass -File tools/dist.ps1");
}

/**
 * Packages for Linux/macOS using dist.sh.
 */
export function packageLinux(): void {
  const terminal = getOrCreateTerminal("Lurek2D Package");
  terminal.show();
  terminal.sendText("bash tools/dist.sh");
}

function getOrCreateTerminal(name: string): vscode.Terminal {
  const existing = vscode.window.terminals.find((t) => t.name === name);
  if (existing) {
    return existing;
  }
  return vscode.window.createTerminal(name);
}
