import * as vscode from "vscode";

/**
 * Manages the Luna Toolkit status bar indicator.
 */
export class StatusBarService {
  private readonly item: vscode.StatusBarItem;

  constructor() {
    this.item = vscode.window.createStatusBarItem(
      vscode.StatusBarAlignment.Left,
      100
    );
    this.setStopped();
    this.item.show();
  }

  /** Show "Running" state with play icon. */
  setRunning(): void {
    this.item.text = "$(play) Luna2D: Running";
    this.item.tooltip = "Luna2D game is running — click to stop";
    this.item.command = "luna.stopGame";
    this.item.backgroundColor = new vscode.ThemeColor(
      "statusBarItem.warningBackground"
    );
  }

  /** Show default idle state. */
  setStopped(): void {
    this.item.text = "$(rocket) Luna2D";
    this.item.tooltip = "Luna Toolkit — click to run game";
    this.item.command = "luna.runGame";
    this.item.backgroundColor = undefined;
  }

  /** Show debug-connected state. */
  setDebugConnected(): void {
    this.item.text = "$(debug-alt) Luna2D: Debug";
    this.item.tooltip = "Luna2D debug bridge connected";
    this.item.command = "luna.debug.status";
    this.item.backgroundColor = new vscode.ThemeColor(
      "statusBarItem.prominentBackground"
    );
  }

  dispose(): void {
    this.item.dispose();
  }
}
