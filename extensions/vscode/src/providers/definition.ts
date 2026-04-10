import * as vscode from "vscode";
import * as path from "path";
import { ApiDataService } from "../services/apiData.js";
import { LuaDocumentAnalyzer, LuaDocumentInfo } from "../services/luaParser.js";

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: "file", language: "lua" };
const analyzer = new LuaDocumentAnalyzer();
const LUREK_API_SCHEME = "lurek-api";

// ── Document analysis cache ──────────────────────────────────

interface CachedAnalysis {
  version: number;
  info: LuaDocumentInfo;
}

const analysisCache = new Map<string, CachedAnalysis>();

function getCachedAnalysis(document: vscode.TextDocument): LuaDocumentInfo {
  const key = document.uri.toString();
  const cached = analysisCache.get(key);
  if (cached && cached.version === document.version) return cached.info;
  const info = analyzer.analyze(document.getText());
  analysisCache.set(key, { version: document.version, info });
  return info;
}

// ── Virtual document provider for lurek.* API definitions ─────

class LurekApiDocumentProvider implements vscode.TextDocumentContentProvider {
  constructor(private apiData: ApiDataService) {}

  provideTextDocumentContent(uri: vscode.Uri): string {
    const fullPath = uri.path.replace(/^\//, "");
    const fn = this.apiData.getFunction(fullPath);
    if (fn) {
      return this.renderFunction(fn);
    }

    // Try as module
    const modName = fullPath.replace("lurek.", "");
    const mod = this.apiData.getModule(modName);
    if (mod) {
      return this.renderModule(mod);
    }

    return `-- No API definition found for: ${fullPath}`;
  }

  private renderFunction(fn: import("../services/apiData.js").ApiFunction): string {
    const lines: string[] = [];
    lines.push(`-- Lurek2D API Definition`);
    lines.push(`-- ${fn.fullPath}`);
    lines.push(`--`);
    if (fn.description) {
      lines.push(`-- ${fn.description}`);
      lines.push(`--`);
    }
    if (fn.parameters.length > 0) {
      lines.push(`-- Parameters:`);
      for (const p of fn.parameters) {
        const opt = p.optional ? " (optional)" : "";
        const def = p.default ? ` [default: ${p.default}]` : "";
        const desc = p.description ? ` -- ${p.description}` : "";
        lines.push(`--   ${p.name}: ${p.type}${opt}${def}${desc}`);
      }
      lines.push(`--`);
    }
    if (fn.returns) {
      lines.push(`-- Returns: ${fn.returns}`);
      lines.push(`--`);
    }
    if (fn.deprecated) {
      lines.push(`-- DEPRECATED: ${fn.deprecated}`);
      lines.push(`--`);
    }
    if (fn.sourceFile) {
      lines.push(`-- Source: ${fn.sourceFile}`);
    }
    lines.push(``);

    // Render as Lua function declaration
    const params = fn.parameters.map(p => p.name).join(", ");
    if (fn.isMethod) {
      lines.push(`function ${fn.objectType ?? "Object"}:${fn.name}(${params})`);
    } else {
      lines.push(`function ${fn.fullPath}(${params})`);
    }
    lines.push(`  -- Implemented in Rust (native)`);
    lines.push(`end`);

    return lines.join("\n");
  }

  private renderModule(mod: import("../services/apiData.js").ApiModule): string {
    const lines: string[] = [];
    lines.push(`-- Lurek2D API Module: ${mod.fullPath}`);
    if (mod.description) {
      lines.push(`-- ${mod.description}`);
    }
    lines.push(`-- ${mod.functions.length} functions, ${mod.methods.length} methods`);
    lines.push(``);
    lines.push(`${mod.name} = {}`);
    lines.push(``);

    for (const fn of mod.functions) {
      const params = fn.parameters.map(p => p.name).join(", ");
      if (fn.description) lines.push(`--- ${fn.description}`);
      lines.push(`function ${fn.fullPath}(${params}) end`);
      lines.push(``);
    }

    for (const m of mod.methods) {
      const params = m.parameters.map(p => p.name).join(", ");
      if (m.description) lines.push(`--- ${m.description}`);
      lines.push(`function ${m.objectType ?? "Object"}:${m.name}(${params}) end`);
      lines.push(``);
    }

    return lines.join("\n");
  }
}

// ── Require path resolution ──────────────────────────────────

async function resolveRequire(
  document: vscode.TextDocument,
  requirePath: string,
): Promise<vscode.Location | undefined> {
  const fsPath = requirePath.replace(/\./g, "/");
  const candidates = [fsPath + ".lua", fsPath + "/init.lua"];
  const docDir = path.dirname(document.uri.fsPath);

  for (const candidate of candidates) {
    // Relative to current file
    const relUri = vscode.Uri.file(path.resolve(docDir, candidate));
    try {
      await vscode.workspace.fs.stat(relUri);
      return new vscode.Location(relUri, new vscode.Position(0, 0));
    } catch { /* not found */ }

    // Relative to workspace root
    const wsRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (wsRoot) {
      const absUri = vscode.Uri.file(path.resolve(wsRoot, candidate));
      try {
        await vscode.workspace.fs.stat(absUri);
        return new vscode.Location(absUri, new vscode.Position(0, 0));
      } catch { /* not found */ }
    }

    // Workspace-wide search
    const files = await vscode.workspace.findFiles(`**/${candidate}`, "**/node_modules/**", 1);
    if (files.length > 0) {
      return new vscode.Location(files[0], new vscode.Position(0, 0));
    }
  }

  return undefined;
}

// ── Local definition finder ──────────────────────────────────

function findLocalDefinition(document: vscode.TextDocument, word: string, cursorLine: number): vscode.Location | undefined {
  try {
    const info = getCachedAnalysis(document);

    // Find the best matching symbol (declared before or at cursor line)
    let best: import("../services/luaParser.js").LuaSymbol | undefined;
    for (const sym of info.symbols) {
      if (sym.name !== word) continue;
      if (sym.kind === "parameter") continue;
      if (sym.line > cursorLine) continue;
      if (!best || sym.line > best.line) {
        best = sym;
      }
    }

    if (best) {
      return new vscode.Location(
        document.uri,
        new vscode.Position(best.line, best.column),
      );
    }
  } catch { /* fallback to regex */ }

  // Regex fallback for simple patterns
  const text = document.getText();
  const escaped = word.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const patterns = [
    new RegExp(`\\blocal\\s+function\\s+${escaped}\\s*\\(`),
    new RegExp(`^function\\s+${escaped}\\s*\\(`, "m"),
    new RegExp(`\\blocal\\s+${escaped}\\s*=\\s*function\\s*\\(`),
    new RegExp(`\\blocal\\s+${escaped}\\s*=`),
    new RegExp(`^${escaped}\\s*=\\s*\\{`, "m"),
  ];

  for (const pattern of patterns) {
    const match = pattern.exec(text);
    if (match) {
      const pos = document.positionAt(match.index);
      return new vscode.Location(document.uri, pos);
    }
  }

  return undefined;
}

// ── Provider registration ────────────────────────────────────

export function register(
  context: vscode.ExtensionContext,
  apiData: ApiDataService,
): void {
  // Register virtual document provider for lurek.* API definitions
  const docProvider = new LurekApiDocumentProvider(apiData);
  context.subscriptions.push(
    vscode.workspace.registerTextDocumentContentProvider(LUREK_API_SCHEME, docProvider),
  );

  const provider = vscode.languages.registerDefinitionProvider(LUA_SELECTOR, {
    async provideDefinition(
      document: vscode.TextDocument,
      position: vscode.Position,
    ): Promise<vscode.Definition | undefined> {
      const lineText = document.lineAt(position).text;

      // ── require("module.path") ──
      const requireMatch = lineText.match(/require\s*\(\s*["']([^"']+)["']\s*\)/);
      if (requireMatch) {
        const reqPath = requireMatch[1];
        const charStart = lineText.indexOf(reqPath);
        const charEnd = charStart + reqPath.length;
        if (position.character >= charStart && position.character <= charEnd) {
          return resolveRequire(document, reqPath);
        }
      }

      // ── lurek.module.func → virtual API document ──
      const lurekRange = document.getWordRangeAtPosition(position, /lurek\.\w+\.\w+/);
      if (lurekRange) {
        const fullPath = document.getText(lurekRange);
        const fn = apiData.getFunction(fullPath);
        if (fn) {
          const uri = vscode.Uri.parse(`${LUREK_API_SCHEME}:/${fullPath}`);
          return new vscode.Location(uri, new vscode.Position(0, 0));
        }
      }

      // ── Local/global variables and functions ──
      const wordRange = document.getWordRangeAtPosition(position, /\w+/);
      if (!wordRange) return undefined;
      const word = document.getText(wordRange);

      // Skip lurek.* prefix situations
      const beforeWord = lineText.substring(0, wordRange.start.character);
      if (beforeWord.endsWith("lurek.") || beforeWord.match(/lurek\.\w+\.$/)) {
        return undefined;
      }

      return findLocalDefinition(document, word, position.line);
    },
  });

  context.subscriptions.push(provider);
}
