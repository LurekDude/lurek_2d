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
 * Compute a vscode.Position from a raw text offset.
 */
function positionFromOffset(text: string, offset: number): vscode.Position {
  const before = text.substring(0, offset);
  const lines = before.split("\n");
  return new vscode.Position(lines.length - 1, lines[lines.length - 1].length);
}

/**
 * Parse raw Lua text for require() calls.
 * Does NOT need an open TextDocument — works on raw bytes read via fs.readFile.
 */
function parseRequires(text: string): RequireInfo[] {
  const requires: RequireInfo[] = [];
  const regex = /\brequire\s*\(\s*["']([^"']+)["']\s*\)/g;
  let match: RegExpExecArray | null;

  while ((match = regex.exec(text)) !== null) {
    const moduleName = match[1];
    const startOffset = match.index;
    const endOffset = match.index + match[0].length;
    const startPos = positionFromOffset(text, startOffset);
    const endPos = positionFromOffset(text, endOffset);
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
  const diagCollection = vscode.languages.createDiagnosticCollection("lurek.requireGraph");
  context.subscriptions.push(diagCollection);

  // File node cache
  const nodeCache = new Map<string, FileNode>();

  let buildDebounceTimer: ReturnType<typeof setTimeout> | undefined;

  function scheduleBuildGraph(): void {
    if (buildDebounceTimer) clearTimeout(buildDebounceTimer);
    buildDebounceTimer = setTimeout(() => {
      buildDebounceTimer = undefined;
      buildGraph();
    }, 500);
  }

  async function buildGraph(): Promise<void> {
    const workspaceFolder = vscode.workspace.workspaceFolders?.[0]?.uri;
    if (!workspaceFolder) return;

    nodeCache.clear();

    // Only scan game/example/library Lua — exclude tests, build artefacts,
    // scratch folders, and binary/log directories.
    const luaFiles = await vscode.workspace.findFiles(
      "**/*.lua",
      "{**/node_modules/**,ideas/**,work/**,.github/**,**/build/**,**/save/**,**/assets/**,**/logs/**}",
    );

    for (const fileUri of luaFiles) {
      try {
        // Use fs.readFile — NOT openTextDocument — to avoid triggering
        // onDidOpenTextDocument and cascading diagnostics on every rebuild.
        const bytes = await vscode.workspace.fs.readFile(fileUri);
        const text = new TextDecoder().decode(bytes);
        const requires = parseRequires(text);

        // Resolve each require
        for (const req of requires) {
          req.resolvedUri = resolveModule(req.moduleName, workspaceFolder);
        }

        nodeCache.set(fileUri.toString(), { uri: fileUri, requires });
      } catch {
        // Skip files that can't be read
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
            diag.code = "lurek.requireMissing";
            diag.source = "Lurek2D Require Graph";
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
              diag.code = "lurek.requireCycle";
              diag.source = "Lurek2D Require Graph";
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

  // Rebuild on file save (debounced — a save can trigger many rapid rebuilds
  // if files are being auto-saved or if several files are saved at once).
  context.subscriptions.push(
    vscode.workspace.onDidSaveTextDocument((doc) => {
      if (doc.languageId === "lua") {
        scheduleBuildGraph();
      }
    }),
    vscode.workspace.onDidCreateFiles(() => scheduleBuildGraph()),
    vscode.workspace.onDidDeleteFiles(() => scheduleBuildGraph()),
  );
}
