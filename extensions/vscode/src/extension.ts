import * as vscode from "vscode";
import * as path from "path";
import * as fs from "fs";
import { startMcpServer } from "./mcp/server";
import { resolveWorkspaceApiDocPath, searchApiDocumentation } from "./services/apiDocs.js";
import { buildCheckCommand, buildRunCommand } from "./services/parallelCargo.js";

/** Status bar item displayed when the extension is active. */
let statusBarItem: vscode.StatusBarItem;

/** MCP server child process reference. */
let mcpProcess: ReturnType<typeof startMcpServer> | undefined;

/**
 * Activates the Lurek2D extension.
 *
 * Called by VS Code when a workspace containing `main.lua` or `Cargo.toml`
 * is opened. Registers commands, starts the MCP server, and shows a status
 * bar indicator.
 */
export function activate(context: vscode.ExtensionContext): void {
  // Status bar
  statusBarItem = vscode.window.createStatusBarItem(
    vscode.StatusBarAlignment.Left,
    100
  );
  statusBarItem.text = "$(rocket) Lurek2D";
  statusBarItem.tooltip = "Lurek2D game engine is active";
  statusBarItem.show();
  context.subscriptions.push(statusBarItem);

  // Register commands
  context.subscriptions.push(
    vscode.commands.registerCommand("lurek2d.runExample", runExampleCommand),
    vscode.commands.registerCommand("lurek2d.listExamples", listExamplesCommand),
    vscode.commands.registerCommand("lurek2d.checkBuild", checkBuildCommand),
    vscode.commands.registerCommand("lurek2d.getApiDoc", getApiDocCommand)
  );

  // Start MCP server
  const workspaceRoot = getWorkspaceRoot();
  if (workspaceRoot) {
    mcpProcess = startMcpServer(workspaceRoot);
  }

  vscode.window.showInformationMessage("Lurek2D extension activated.");
}

/**
 * Deactivates the Lurek2D extension.
 *
 * Cleans up the MCP server process and status bar item.
 */
export function deactivate(): void {
  if (mcpProcess) {
    mcpProcess.kill();
    mcpProcess = undefined;
  }
}

/**
 * Returns the first workspace folder root path, or undefined if none.
 */
function getWorkspaceRoot(): string | undefined {
  const folders = vscode.workspace.workspaceFolders;
  if (folders && folders.length > 0) {
    return folders[0].uri.fsPath;
  }
  return undefined;
}

/**
 * Returns the path to the examples directory within the workspace.
 */
function getExamplesDir(): string | undefined {
  const root = getWorkspaceRoot();
  if (!root) {
    return undefined;
  }
  const examplesDir = path.join(root, "content", "games", "showcase");
  if (fs.existsSync(examplesDir)) {
    return examplesDir;
  }
  return undefined;
}

/**
 * Lists showcase game directory names from the workspace content/games/showcase/ folder.
 */
function listExampleNames(): string[] {
  const examplesDir = getExamplesDir();
  if (!examplesDir) {
    return [];
  }
  try {
    return fs
      .readdirSync(examplesDir, { withFileTypes: true })
      .filter((entry) => entry.isDirectory())
      .map((entry) => entry.name);
  } catch {
    return [];
  }
}

/**
 * Command: Lurek2D: Run Example
 *
 * Shows a quick-pick list of available showcase games and runs the selected one
 * in an integrated terminal via the wrapper-backed run command.
 */
async function runExampleCommand(): Promise<void> {
  const examples = listExampleNames();
  if (examples.length === 0) {
    vscode.window.showWarningMessage("No Lurek2D examples found in workspace.");
    return;
  }

  const selected = await vscode.window.showQuickPick(examples, {
    placeHolder: "Select a Lurek2D example to run",
  });

  if (!selected) {
    return;
  }

  const terminal = vscode.window.createTerminal("Lurek2D Example");
  terminal.show();
  terminal.sendText(
    buildRunCommand("debug", [path.posix.join("content", "games", "showcase", selected)]),
  );
}

/**
 * Command: Lurek2D: List Examples
 *
 * Displays the available example names in an information message.
 */
async function listExamplesCommand(): Promise<void> {
  const examples = listExampleNames();
  if (examples.length === 0) {
    vscode.window.showWarningMessage("No Lurek2D examples found in workspace.");
    return;
  }

  const message = `Lurek2D Examples: ${examples.join(", ")}`;
  vscode.window.showInformationMessage(message);
}

/**
 * Command: Lurek2D: Check Build
 *
 * Runs the wrapper-backed repo check flow in a terminal and reports results.
 */
async function checkBuildCommand(): Promise<void> {
  const terminal = vscode.window.createTerminal("Lurek2D Build Check");
  terminal.show();
  terminal.sendText(buildCheckCommand());
}

/**
 * Command: Lurek2D: Get API Documentation
 *
 * Prompts the user for a query string and searches the canonical workspace API
 * reference. Results are displayed in a new editor tab.
 */
async function getApiDocCommand(): Promise<void> {
  const query = await vscode.window.showInputBox({
    placeHolder: "e.g. lurek.graphics.draw",
    prompt: "Search Lurek2D API documentation",
  });

  if (!query) {
    return;
  }

  const root = getWorkspaceRoot();
  if (!root) {
    vscode.window.showErrorMessage("No workspace folder open.");
    return;
  }

  const apiDocPath = resolveWorkspaceApiDocPath(root);

  if (!apiDocPath || !fs.existsSync(apiDocPath)) {
    vscode.window.showWarningMessage(
      "API reference file not found. Expected docs/api/lurek.lua or docs/api/lurek.md."
    );
    return;
  }

  try {
    const content = fs.readFileSync(apiDocPath, "utf-8");
    const matches = searchApiDocumentation(content, apiDocPath, query);

    if (matches.length === 0) {
      vscode.window.showInformationMessage(
        `No API documentation found for "${query}".`
      );
      return;
    }

    // Show results in a new untitled document
    const formattedMatches = apiDocPath.endsWith(".lua")
      ? matches.map((match) => `\`\`\`lua\n${match}\n\`\`\``)
      : matches;
    const resultText = `# Lurek2D API — Search: "${query}"\n\n${formattedMatches.join("\n\n---\n\n")}`;
    const doc = await vscode.workspace.openTextDocument({
      content: resultText,
      language: "markdown",
    });
    await vscode.window.showTextDocument(doc, { preview: true });
  } catch (err) {
    vscode.window.showErrorMessage(
      `Failed to read API documentation: ${err}`
    );
  }
}
