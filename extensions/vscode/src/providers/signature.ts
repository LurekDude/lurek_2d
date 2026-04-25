import * as vscode from "vscode";
import { ApiDataService, ApiFunction } from "../services/apiData.js";
import { LuaDocumentAnalyzer } from "../services/luaParser.js";

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: "file", language: "lua" };
const analyzer = new LuaDocumentAnalyzer();

// ── Helpers ──────────────────────────────────────────────────

function buildSignatureInfo(fn: ApiFunction): vscode.SignatureInformation {
  const sig = new vscode.SignatureInformation(fn.signature);
  sig.documentation = new vscode.MarkdownString(fn.description);
  sig.parameters = fn.parameters.map(p => {
    const paramDoc = new vscode.MarkdownString();
    const opt = p.optional ? " *(optional)*" : "";
    const def = p.default ? ` — default: \`${p.default}\`` : "";
    paramDoc.appendMarkdown(`*${p.type}*${opt}${def}`);
    if (p.description) paramDoc.appendMarkdown(` — ${p.description}`);
    return new vscode.ParameterInformation(p.name, paramDoc);
  });
  return sig;
}

function countActiveParam(argsText: string): number {
  let paramIndex = 0;
  let parenDepth = 0;
  let bracketDepth = 0;
  let braceDepth = 0;
  let inString = false;
  let stringChar = "";

  for (let i = 0; i < argsText.length; i++) {
    const ch = argsText[i];

    // Handle string literals
    if (inString) {
      if (ch === "\\" && i + 1 < argsText.length) { i++; continue; }
      if (ch === stringChar) inString = false;
      continue;
    }
    if (ch === '"' || ch === "'") { inString = true; stringChar = ch; continue; }

    // Handle nesting
    if (ch === "(") { parenDepth++; continue; }
    if (ch === ")") { parenDepth--; continue; }
    if (ch === "[") { bracketDepth++; continue; }
    if (ch === "]") { bracketDepth--; continue; }
    if (ch === "{") { braceDepth++; continue; }
    if (ch === "}") { braceDepth--; continue; }

    // Count commas at top level only
    if (ch === "," && parenDepth === 0 && bracketDepth === 0 && braceDepth === 0) {
      paramIndex++;
    }
  }

  return paramIndex;
}

// ── Provider registration ────────────────────────────────────

export function register(
  context: vscode.ExtensionContext,
  apiData: ApiDataService,
): void {
  const provider = vscode.languages.registerSignatureHelpProvider(
    LUA_SELECTOR,
    {
      provideSignatureHelp(
        document: vscode.TextDocument,
        position: vscode.Position,
      ): vscode.SignatureHelp | undefined {
        const text = document.getText();

        // Use the analyzer to find what function call we're inside
        const callCtx = analyzer.getFunctionCallContext(text, position.line, position.character);
        if (!callCtx) return undefined;

        const { functionName, paramIndex } = callCtx;
        let fn: ApiFunction | undefined;

        // ── Lurek2D API functions ──
        fn = apiData.getFunction(functionName);

        // ── Method calls (obj:method) — try to find in all methods ──
        if (!fn && functionName.includes(":")) {
          const colonIdx = functionName.lastIndexOf(":");
          const methodName = functionName.slice(colonIdx + 1);
          // Search all methods
          for (const apiFn of apiData.getAllFunctions()) {
            if (apiFn.isMethod && apiFn.name === methodName) {
              fn = apiFn;
              break;
            }
          }
        }

        // ── Lua stdlib functions — sumneko.lua handles these ──
        // Do NOT fall back to stdlib here; let sumneko.lua provide
        // signature help for string.*, table.*, math.*, etc.

        if (!fn || fn.parameters.length === 0) return undefined;

        const sig = buildSignatureInfo(fn);
        const help = new vscode.SignatureHelp();
        help.signatures = [sig];
        help.activeSignature = 0;
        help.activeParameter = Math.min(paramIndex, fn.parameters.length - 1);

        return help;
      },
    },
    "(",
    ",",
  );

  context.subscriptions.push(provider);
}
