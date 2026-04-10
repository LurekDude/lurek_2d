import * as vscode from "vscode";

/**
 * Manages the Lurek2D Toolkit status bar indicator.
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
    this.item.text = "$(play) Lurek2D: Running";
    this.item.tooltip = "Lurek2D game is running — click to stop";
    this.item.command = "lurek.stopGame";
    this.item.backgroundColor = new vscode.ThemeColor(
      "statusBarItem.warningBackground"
    );
  }

  /** Show default idle state. */
  setStopped(): void {
    this.item.text = "$(rocket) Lurek2D";
    this.item.tooltip = "Lurek2D Toolkit — click to run game";
    this.item.command = "lurek.runGame";
    this.item.backgroundColor = undefined;
  }

  /** Show debug-connected state. */
  setDebugConnected(): void {
    this.item.text = "$(debug-alt) Lurek2D: Debug";
    this.item.tooltip = "Lurek2D debug bridge connected";
    this.item.command = "lurek.debug.status";
    this.item.backgroundColor = new vscode.ThemeColor(
      "statusBarItem.prominentBackground"
    );
  }

  dispose(): void {
    this.item.dispose();
  }
}
