import * as vscode from "vscode";
import * as path from "path";

const LUA_SELECTOR: vscode.DocumentSelector = {
  scheme: "file",
  language: "lua",
};

// ── Require graph types ───────────────────────────────────

interface RequireInfo {
  moduleName: string;
  range: vscode.Range;
  resolvedUri?: vscode.Uri;
}

interface FileNode {
  uri: vscode.Uri;
  requires: RequireInfo[];
}

// ── Graph builder ─────────────────────────────────────────

/**
 * Parse a Lua file for require() calls.
 */
function parseRequires(document: vscode.TextDocument): RequireInfo[] {
  const requires: RequireInfo[] = [];
  const text = document.getText();
  const regex = /\brequire\s*\(\s*["']([^"']+)["']\s*\)/g;
  let match: RegExpExecArray | null;

  while ((match = regex.exec(text)) !== null) {
    const moduleName = match[1];
    const startOffset = match.index;
    const endOffset = match.index + match[0].length;
    const startPos = document.positionAt(startOffset);
    const endPos = document.positionAt(endOffset);
    requires.push({
      moduleName,
      range: new vscode.Range(startPos, endPos),
    });
  }

  return requires;
}

/**
 * Resolve a Lua module name to a file URI relative to workspace.
 */
function resolveModule(
  moduleName: string,
  workspaceFolder: vscode.Uri
): vscode.Uri | undefined {
  // Lua module resolution: replace dots with path separator
  const relativePath = moduleName.replace(/\./g, "/");
  const candidates = [
    `${relativePath}.lua`,
    `${relativePath}/init.lua`,
  ];

  for (const candidate of candidates) {
    const uri = vscode.Uri.joinPath(workspaceFolder, candidate);
    return uri; // Return candidate; actual existence checked later
  }

  return undefined;
}

/**
 * Detect cycles in the require graph using DFS with 3-color marking.
 */
function detectCycles(
  graph: Map<string, string[]>
): string[][] {
  const WHITE = 0, GRAY = 1, BLACK = 2;
  const color = new Map<string, number>();
  const parent = new Map<string, string | null>();
  const cycles: string[][] = [];

  for (const node of graph.keys()) {
    color.set(node, WHITE);
  }

  function dfs(u: string, pathStack: string[]): void {
    color.set(u, GRAY);

    const neighbors = graph.get(u) || [];
    for (const v of neighbors) {
      if (!color.has(v)) {
        // Node not in graph — skip (missing file)
        continue;
      }

      if (color.get(v) === GRAY) {
        // Back edge found — extract cycle
        const cycleStart = pathStack.indexOf(v);
        if (cycleStart >= 0) {
          const cycle = pathStack.slice(cycleStart);
          cycle.push(v);
          cycles.push(cycle);
        }
      } else if (color.get(v) === WHITE) {
        parent.set(v, u);
        dfs(v, [...pathStack, v]);
      }
    }

    color.set(u, BLACK);
  }

  for (const node of graph.keys()) {
    if (color.get(node) === WHITE) {
      dfs(node, [node]);
    }
  }

  return cycles;
}

/**
 * Registers the require dependency graph analysis provider.
 */
export function register(context: vscode.ExtensionContext): void {
  const diagCollection = vscode.languages.createDiagnosticCollection("luna.requireGraph");
  context.subscriptions.push(diagCollection);

  // File node cache
  const nodeCache = new Map<string, FileNode>();

  async function buildGraph(): Promise<void> {
    const workspaceFolder = vscode.workspace.workspaceFolders?.[0]?.uri;
    if (!workspaceFolder) return;

    nodeCache.clear();

    const luaFiles = await vscode.workspace.findFiles("**/*.lua", "**/node_modules/**");

    for (const fileUri of luaFiles) {
      try {
        const doc = await vscode.workspace.openTextDocument(fileUri);
        const requires = parseRequires(doc);

        // Resolve each require
        for (const req of requires) {
          req.resolvedUri = resolveModule(req.moduleName, workspaceFolder);
        }

        nodeCache.set(fileUri.toString(), { uri: fileUri, requires });
      } catch {
        // Skip files that can't be opened
      }
    }

    analyzeGraph(workspaceFolder);
  }

  function analyzeGraph(workspaceFolder: vscode.Uri): void {
    // Build adjacency list
    const adj = new Map<string, string[]>();
    const uriByModule = new Map<string, string>(); // module path → file URI string

    for (const [uriStr, node] of nodeCache) {
      const relPath = path.relative(
        workspaceFolder.fsPath,
        node.uri.fsPath
      ).replace(/\\/g, "/").replace(/\.lua$/, "").replace(/\/init$/, "");
      uriByModule.set(relPath, uriStr);
      adj.set(uriStr, []);
    }

    // Link requires to targets
    for (const [uriStr, node] of nodeCache) {
      const edges: string[] = [];
      for (const req of node.requires) {
        const modulePath = req.moduleName.replace(/\./g, "/");
        const targetUri = uriByModule.get(modulePath);
        if (targetUri) {
          edges.push(targetUri);
        }
      }
      adj.set(uriStr, edges);
    }

    // Detect cycles
    const cycles = detectCycles(adj);
    const cycleMembers = new Set<string>();
    for (const cycle of cycles) {
      for (const member of cycle) {
        cycleMembers.add(member);
      }
    }

    // Clear previous diagnostics
    diagCollection.clear();

    // Generate diagnostics
    const allDiags = new Map<string, vscode.Diagnostic[]>();

    for (const [uriStr, node] of nodeCache) {
      const diagnostics: vscode.Diagnostic[] = [];

      for (const req of node.requires) {
        // Check for missing files
        if (req.resolvedUri) {
          const modulePath = req.moduleName.replace(/\./g, "/");
          const targetUri = uriByModule.get(modulePath);
          if (!targetUri) {
            const diag = new vscode.Diagnostic(
              req.range,
              `Cannot resolve module "${req.moduleName}" — file not found in workspace.`,
              vscode.DiagnosticSeverity.Warning
            );
            diag.code = "luna.requireMissing";
            diag.source = "Luna Require Graph";
            diagnostics.push(diag);
          }
        }

        // Check if this require is part of a cycle
        const modulePath = req.moduleName.replace(/\./g, "/");
        const targetUri = uriByModule.get(modulePath);
        if (targetUri && cycleMembers.has(uriStr) && cycleMembers.has(targetUri)) {
          // Find the actual cycle containing both
          for (const cycle of cycles) {
            if (cycle.includes(uriStr) && cycle.includes(targetUri)) {
              const cycleNames = cycle.map((u) => {
                const n = nodeCache.get(u);
                if (!n) return "?";
                return path.basename(n.uri.fsPath, ".lua");
              });
              const diag = new vscode.Diagnostic(
                req.range,
                `Circular dependency detected: ${cycleNames.join(" → ")}`,
                vscode.DiagnosticSeverity.Warning
              );
              diag.code = "luna.requireCycle";
              diag.source = "Luna Require Graph";
              diagnostics.push(diag);
              break;
            }
          }
        }
      }

      if (diagnostics.length > 0) {
        allDiags.set(uriStr, diagnostics);
      }
    }

    for (const [uriStr, diags] of allDiags) {
      const node = nodeCache.get(uriStr);
      if (node) {
        diagCollection.set(node.uri, diags);
      }
    }
  }

  // Build graph on activation
  buildGraph();

  // Rebuild on file save
  context.subscriptions.push(
    vscode.workspace.onDidSaveTextDocument((doc) => {
      if (doc.languageId === "lua") {
        buildGraph();
      }
    }),
    vscode.workspace.onDidCreateFiles(() => buildGraph()),
    vscode.workspace.onDidDeleteFiles(() => buildGraph())
  );
}
