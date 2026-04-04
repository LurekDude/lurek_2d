import * as vscode from "vscode";

// ── Symbol types ──────────────────────────────────────────

export interface SymbolInfo {
  name: string;
  kind: vscode.SymbolKind;
  uri: vscode.Uri;
  range: vscode.Range;
  containerName?: string;
  detail?: string;
}

// ── Regex patterns for Lua symbol detection ───────────────

const PATTERNS: { regex: RegExp; kind: vscode.SymbolKind; group: number }[] = [
  // function moduleName.funcName(...)
  { regex: /\bfunction\s+(\w+\.\w+)\s*\(/g, kind: vscode.SymbolKind.Function, group: 1 },
  // function funcName(...)
  { regex: /\bfunction\s+(\w+)\s*\(/g, kind: vscode.SymbolKind.Function, group: 1 },
  // local function funcName(...)
  { regex: /\blocal\s+function\s+(\w+)\s*\(/g, kind: vscode.SymbolKind.Function, group: 1 },
  // function Class:method(...)
  { regex: /\bfunction\s+(\w+:\w+)\s*\(/g, kind: vscode.SymbolKind.Method, group: 1 },
  // ModuleName = {} (table/class)
  { regex: /^(\w+)\s*=\s*\{\s*\}/gm, kind: vscode.SymbolKind.Class, group: 1 },
  // local ModuleName = {} (table/class)
  { regex: /\blocal\s+(\w+)\s*=\s*\{\s*\}/g, kind: vscode.SymbolKind.Class, group: 1 },
  // CONSTANT = value (all-caps)
  { regex: /^([A-Z][A-Z_0-9]+)\s*=/gm, kind: vscode.SymbolKind.Constant, group: 1 },
  // luna.callback assignment: luna.load = function ...
  { regex: /\b(luna\.\w+)\s*=\s*function/g, kind: vscode.SymbolKind.Function, group: 1 },
  // function luna.callback(...)
  { regex: /\bfunction\s+(luna\.\w+)\s*\(/g, kind: vscode.SymbolKind.Function, group: 1 },
];

/**
 * Workspace-wide symbol index for Lua files.
 * Provides fast lookup for definitions, references, and workspace symbols.
 */
export class SymbolIndex {
  private symbols = new Map<string, SymbolInfo[]>();
  private fileSymbols = new Map<string, SymbolInfo[]>();
  private building = false;

  /** Build the full workspace index. */
  async buildIndex(): Promise<void> {
    if (this.building) return;
    this.building = true;

    try {
      this.symbols.clear();
      this.fileSymbols.clear();

      const luaFiles = await vscode.workspace.findFiles("**/*.lua", "**/node_modules/**");

      for (const fileUri of luaFiles) {
        try {
          const doc = await vscode.workspace.openTextDocument(fileUri);
          this.indexDocument(doc);
        } catch {
          // Skip files that can't be opened
        }
      }
    } finally {
      this.building = false;
    }
  }

  /** Update index for a single file. */
  async updateFile(uri: vscode.Uri): Promise<void> {
    try {
      const doc = await vscode.workspace.openTextDocument(uri);
      this.indexDocument(doc);
    } catch {
      // File may have been deleted
      this.removeFile(uri);
    }
  }

  /** Remove a file from the index. */
  removeFile(uri: vscode.Uri): void {
    const key = uri.toString();
    const oldSymbols = this.fileSymbols.get(key) || [];
    for (const sym of oldSymbols) {
      const existing = this.symbols.get(sym.name);
      if (existing) {
        const filtered = existing.filter((s) => s.uri.toString() !== key);
        if (filtered.length > 0) {
          this.symbols.set(sym.name, filtered);
        } else {
          this.symbols.delete(sym.name);
        }
      }
    }
    this.fileSymbols.delete(key);
  }

  /** Find the primary definition of a symbol. */
  findDefinition(name: string): SymbolInfo | undefined {
    const syms = this.symbols.get(name);
    if (!syms || syms.length === 0) return undefined;
    // Prefer function definitions over assignments
    return (
      syms.find((s) => s.kind === vscode.SymbolKind.Function) ||
      syms.find((s) => s.kind === vscode.SymbolKind.Method) ||
      syms[0]
    );
  }

  /** Find all references/definitions of a symbol. */
  findReferences(name: string): SymbolInfo[] {
    return this.symbols.get(name) || [];
  }

  /** Search for workspace symbols matching a query. */
  getWorkspaceSymbols(query: string): vscode.SymbolInformation[] {
    const lower = query.toLowerCase();
    const results: vscode.SymbolInformation[] = [];

    for (const [name, syms] of this.symbols) {
      if (!lower || name.toLowerCase().includes(lower)) {
        for (const sym of syms) {
          results.push(
            new vscode.SymbolInformation(
              sym.name,
              sym.kind,
              sym.containerName || "",
              new vscode.Location(sym.uri, sym.range)
            )
          );
        }
      }
    }

    return results;
  }

  /** Get all symbols in a specific file. */
  getFileSymbols(uri: vscode.Uri): SymbolInfo[] {
    return this.fileSymbols.get(uri.toString()) || [];
  }

  // ── Internal ────────────────────────────────────────────

  private indexDocument(doc: vscode.TextDocument): void {
    const key = doc.uri.toString();

    // Remove old entries for this file
    this.removeFile(doc.uri);

    const text = doc.getText();
    const fileSyms: SymbolInfo[] = [];

    for (const pat of PATTERNS) {
      pat.regex.lastIndex = 0;
      let match: RegExpExecArray | null;

      while ((match = pat.regex.exec(text)) !== null) {
        const name = match[pat.group];
        const startPos = doc.positionAt(match.index);
        const endPos = doc.positionAt(match.index + match[0].length);

        // Extract container name for methods (Class:method → Class)
        let containerName: string | undefined;
        if (name.includes(":")) {
          containerName = name.split(":")[0];
        } else if (name.includes(".") && !name.startsWith("luna.")) {
          containerName = name.split(".")[0];
        }

        const sym: SymbolInfo = {
          name,
          kind: pat.kind,
          uri: doc.uri,
          range: new vscode.Range(startPos, endPos),
          containerName,
        };

        fileSyms.push(sym);

        // Add to global index
        const existing = this.symbols.get(name) || [];
        existing.push(sym);
        this.symbols.set(name, existing);
      }
    }

    this.fileSymbols.set(key, fileSyms);
  }
}

/**
 * Registers the symbol index and workspace symbol provider.
 */
export function register(context: vscode.ExtensionContext): SymbolIndex {
  const index = new SymbolIndex();

  // Build index on activation
  index.buildIndex();

  // Update on file save
  context.subscriptions.push(
    vscode.workspace.onDidSaveTextDocument((doc) => {
      if (doc.languageId === "lua") {
        index.updateFile(doc.uri);
      }
    }),
    vscode.workspace.onDidDeleteFiles((e) => {
      for (const uri of e.files) {
        index.removeFile(uri);
      }
    }),
    vscode.workspace.onDidCreateFiles((e) => {
      for (const uri of e.files) {
        if (uri.fsPath.endsWith(".lua")) {
          index.updateFile(uri);
        }
      }
    })
  );

  // Register workspace symbol provider
  const wsProvider = vscode.languages.registerWorkspaceSymbolProvider({
    provideWorkspaceSymbols(query: string): vscode.SymbolInformation[] {
      return index.getWorkspaceSymbols(query);
    },
  });
  context.subscriptions.push(wsProvider);

  return index;
}
