import * as vscode from "vscode";
import { ApiDataService } from "../services/apiData.js";
import { LuaDocumentAnalyzer, LuaDocumentInfo, LuaSymbol } from "../services/luaParser.js";

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: "file", language: "lua" };
const analyzer = new LuaDocumentAnalyzer();

// ── Lurek2D callbacks for Event kind ────────────────────────────

const LUREK_CALLBACKS = new Set([
  "load", "update", "draw",
  "keypressed", "keyreleased", "textinput",
  "mousepressed", "mousereleased", "wheelmoved",
  "gamepadpressed", "gamepadreleased", "gamepadaxis",
  "joystickadded", "joystickremoved",
  "touchpressed", "touchmoved", "touchreleased",
  "focus", "visible", "resize", "quit",
]);

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

// ── Block range finder ───────────────────────────────────────

function getBlockRange(lines: string[], startLine: number): vscode.Range {
  let depth = 0;
  let started = false;
  for (let i = startLine; i < lines.length; i++) {
    const trimmed = lines[i].replace(/--.*$/, "").trim();
    const openers = (trimmed.match(/\b(function|if|for|while|repeat|do)\b/g) || []).length;
    const closers = (trimmed.match(/\bend\b/g) || []).length;
    const untils = (trimmed.match(/\buntil\b/g) || []).length;
    depth += openers - closers - untils;
    if (openers > 0) started = true;
    if (started && depth <= 0) {
      return new vscode.Range(startLine, 0, i, lines[i].length);
    }
  }
  return new vscode.Range(startLine, 0, startLine, lines[startLine]?.length ?? 0);
}

// ── Provider registration ────────────────────────────────────

export function register(
  context: vscode.ExtensionContext,
  apiData: ApiDataService,
): void {
  // ── Document symbol provider (outline view) ──

  const docSymbolProvider = vscode.languages.registerDocumentSymbolProvider(
    LUA_SELECTOR,
    {
      provideDocumentSymbols(
        document: vscode.TextDocument,
      ): vscode.DocumentSymbol[] {
        const symbols: vscode.DocumentSymbol[] = [];
        const text = document.getText();
        const lines = text.split("\n");

        try {
          const info = getCachedAnalysis(document);

          // Collect table symbols for nesting methods
          const tableSymbols = new Map<string, vscode.DocumentSymbol>();

          // Process require statements
          for (const req of info.requires) {
            const lineLen = lines[req.line]?.length ?? 0;
            const range = new vscode.Range(req.line, 0, req.line, lineLen);
            symbols.push(new vscode.DocumentSymbol(
              req.localName,
              `require("${req.modulePath}")`,
              vscode.SymbolKind.Module,
              range,
              range,
            ));
          }

          // Process symbols from analysis
          for (const sym of info.symbols) {
            if (sym.kind === "parameter") continue;
            const lineLen = lines[sym.line]?.length ?? 0;
            const selRange = new vscode.Range(sym.line, sym.column, sym.line, sym.column + sym.name.length);

            if (sym.kind === "function") {
              const range = sym.endLine !== undefined
                ? new vscode.Range(sym.line, 0, sym.endLine, lines[sym.endLine]?.length ?? 0)
                : getBlockRange(lines, sym.line);

              // Check if this is a lurek.* callback
              const isCallback = info.callbacks.some(cb => cb.name === sym.name && cb.line === sym.line);
              const kind = isCallback ? vscode.SymbolKind.Event : vscode.SymbolKind.Function;
              const detail = isCallback ? "callback" : (sym.isLocal ? "local function" : "function");
              const displayName = isCallback ? `lurek.${sym.name}` : sym.name;

              const docSym = new vscode.DocumentSymbol(displayName, detail, kind, range, selRange);

              // Nest under table if scope matches
              if (sym.scope && tableSymbols.has(sym.scope)) {
                tableSymbols.get(sym.scope)!.children.push(docSym);
              } else {
                symbols.push(docSym);
              }
            } else if (sym.kind === "method") {
              const range = sym.endLine !== undefined
                ? new vscode.Range(sym.line, 0, sym.endLine, lines[sym.endLine]?.length ?? 0)
                : getBlockRange(lines, sym.line);
              const displayName = sym.type ? `${sym.type}:${sym.name}` : sym.name;
              const docSym = new vscode.DocumentSymbol(displayName, "method", vscode.SymbolKind.Method, range, selRange);

              // Nest under parent table/class
              if (sym.type && tableSymbols.has(sym.type)) {
                tableSymbols.get(sym.type)!.children.push(docSym);
              } else {
                symbols.push(docSym);
              }
            } else if (sym.kind === "table") {
              const range = new vscode.Range(sym.line, 0, sym.line, lineLen);
              const docSym = new vscode.DocumentSymbol(
                sym.name,
                "table",
                vscode.SymbolKind.Object,
                range,
                selRange,
              );
              tableSymbols.set(sym.name, docSym);
              symbols.push(docSym);
            } else if (sym.kind === "local" || sym.kind === "global") {
              // Constants: UPPERCASE local variables
              const isConstant = /^[A-Z_][A-Z0-9_]*$/.test(sym.name);
              const range = new vscode.Range(sym.line, 0, sym.line, lineLen);
              const kind = isConstant ? vscode.SymbolKind.Constant : vscode.SymbolKind.Variable;
              const detail = sym.isLocal ? "local" : "global";

              // Only show top-level or interesting variables, skip inner locals
              if (!sym.isLocal || isConstant || !sym.scope) {
                symbols.push(new vscode.DocumentSymbol(sym.name, detail, kind, range, selRange));
              }
            }
          }
        } catch {
          // Fallback: regex-based parsing
          return fallbackDocumentSymbols(lines);
        }

        return symbols;
      },
    },
  );

  // ── Workspace symbol provider ──

  const wsSymbolProvider = vscode.languages.registerWorkspaceSymbolProvider({
    async provideWorkspaceSymbols(
      query: string,
    ): Promise<vscode.SymbolInformation[]> {
      if (query.length < 2) return [];
      const lowerQuery = query.toLowerCase();
      const results: vscode.SymbolInformation[] = [];

      const files = await vscode.workspace.findFiles("**/*.lua", "{**/node_modules/**,ideas/**,work/**,.github/**}", 100);

      for (const fileUri of files) {
        try {
          const doc = await vscode.workspace.openTextDocument(fileUri);
          const info = analyzer.analyze(doc.getText());

          for (const sym of info.symbols) {
            if (sym.kind === "parameter") continue;
            if (!sym.name.toLowerCase().includes(lowerQuery)) continue;

            const kind = sym.kind === "function" || sym.kind === "method"
              ? vscode.SymbolKind.Function
              : sym.kind === "table"
                ? vscode.SymbolKind.Object
                : vscode.SymbolKind.Variable;

            const location = new vscode.Location(
              fileUri,
              new vscode.Position(sym.line, sym.column),
            );

            results.push(new vscode.SymbolInformation(
              sym.name,
              kind,
              sym.scope ?? "",
              location,
            ));
          }
        } catch { /* skip */ }
      }

      return results;
    },
  });

  context.subscriptions.push(docSymbolProvider, wsSymbolProvider);
}

// ── Fallback regex-based symbol extraction ───────────────────

function fallbackDocumentSymbols(lines: string[]): vscode.DocumentSymbol[] {
  const symbols: vscode.DocumentSymbol[] = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // function lurek.callback(...)
    const cbMatch = line.match(/^\s*function\s+(lurek\.\w+)\s*\(/);
    if (cbMatch) {
      const name = cbMatch[1];
      const range = getBlockRange(lines, i);
      const selRange = new vscode.Range(i, 0, i, line.length);
      const shortName = name.replace("lurek.", "");
      const kind = LUREK_CALLBACKS.has(shortName) ? vscode.SymbolKind.Event : vscode.SymbolKind.Function;
      symbols.push(new vscode.DocumentSymbol(name, "callback", kind, range, selRange));
      continue;
    }

    // function name(...)
    const globalFuncMatch = line.match(/^\s*function\s+(\w[\w.:]*)\s*\(/);
    if (globalFuncMatch) {
      const name = globalFuncMatch[1];
      const range = getBlockRange(lines, i);
      const selRange = new vscode.Range(i, 0, i, line.length);
      symbols.push(new vscode.DocumentSymbol(name, "function", vscode.SymbolKind.Function, range, selRange));
      continue;
    }

    // local function name(...)
    const localFuncMatch = line.match(/^\s*local\s+function\s+(\w+)\s*\(/);
    if (localFuncMatch) {
      const name = localFuncMatch[1];
      const range = getBlockRange(lines, i);
      const selRange = new vscode.Range(i, 0, i, line.length);
      symbols.push(new vscode.DocumentSymbol(name, "local function", vscode.SymbolKind.Function, range, selRange));
      continue;
    }

    // local name = function(...)
    const assignFuncMatch = line.match(/^\s*local\s+(\w+)\s*=\s*function\s*\(/);
    if (assignFuncMatch) {
      const name = assignFuncMatch[1];
      const range = getBlockRange(lines, i);
      const selRange = new vscode.Range(i, 0, i, line.length);
      symbols.push(new vscode.DocumentSymbol(name, "local function", vscode.SymbolKind.Function, range, selRange));
      continue;
    }

    // require statements: local x = require("mod")
    const requireMatch = line.match(/^\s*local\s+(\w+)\s*=\s*require\s*\(\s*["']([^"']+)["']\s*\)/);
    if (requireMatch) {
      const range = new vscode.Range(i, 0, i, line.length);
      symbols.push(new vscode.DocumentSymbol(
        requireMatch[1],
        `require("${requireMatch[2]}")`,
        vscode.SymbolKind.Module,
        range,
        range,
      ));
      continue;
    }
  }

  return symbols;
}
