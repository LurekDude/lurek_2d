import * as vscode from "vscode";
import { ApiDataService } from "../services/apiData.js";

const LUA_SELECTOR: vscode.DocumentSelector = {
  scheme: "file",
  language: "lua",
};

// NOTE: bit.*, jit.*, ffi.* completions and hover are now handled by sumneko.lua
// in LuaJIT mode. Only lurek-specific diagnostics remain below.

// ── Performance hint diagnostics ─────────────────────────

interface PerfRule {
  code: string;
  pattern: RegExp;
  message: string;
  severity: vscode.DiagnosticSeverity;
  hotPathOnly: boolean;
}

const PERF_RULES: PerfRule[] = [
  {
    code: "lurek.perf.tableAllocHotPath",
    pattern: /\{\s*\}/,
    message: "Table allocation `{}` in hot path — consider pre-allocating or using an object pool.",
    severity: vscode.DiagnosticSeverity.Hint,
    hotPathOnly: true,
  },
  {
    code: "lurek.perf.newInHotPath",
    pattern: /lurek\.\w+\.new\w*\s*\(/,
    message: "Resource creation (lurek.*.new*) in hot path — move to lurek.load() or cache the result.",
    severity: vscode.DiagnosticSeverity.Warning,
    hotPathOnly: true,
  },
  {
    code: "lurek.perf.globalInLoop",
    pattern: /\bfor\b.+\bdo\b/,
    message: "Loop detected — ensure frequently accessed globals are cached as locals above the loop.",
    severity: vscode.DiagnosticSeverity.Hint,
    hotPathOnly: false,
  },
  {
    code: "lurek.perf.stringConcatLoop",
    pattern: /\.\.\s*["']/,
    message: "String concatenation in loop — consider table.insert + table.concat for better performance.",
    severity: vscode.DiagnosticSeverity.Hint,
    hotPathOnly: true,
  },
  {
    code: "lurek.perf.pcallHotPath",
    pattern: /\bpcall\s*\(/,
    message: "pcall in hot path adds overhead — consider error handling outside the frame loop.",
    severity: vscode.DiagnosticSeverity.Hint,
    hotPathOnly: true,
  },
  {
    code: "lurek.perf.mathFloor",
    pattern: /math\.floor\s*\(/,
    message: "Consider bit.tobit() or x%1 for faster integer conversion in LuaJIT.",
    severity: vscode.DiagnosticSeverity.Hint,
    hotPathOnly: true,
  },
  {
    code: "lurek.perf.mathRandom",
    pattern: /math\.random\s*\(/,
    message: "Use lurek.math.random() for deterministic, seedable RNG consistent across platforms.",
    severity: vscode.DiagnosticSeverity.Information,
    hotPathOnly: true,
  },
  {
    code: "lurek.perf.unpackInLoop",
    pattern: /\bunpack\s*\(/,
    message: "unpack() in hot path creates temporary values — prefer indexed access for known structures.",
    severity: vscode.DiagnosticSeverity.Hint,
    hotPathOnly: true,
  },
];

// ── Lua 5.4-only feature compatibility warnings ──────────────

interface CompatRule {
  code: string;
  pattern: RegExp;
  message: string;
}

/**
 * Patterns that are valid Lua 5.4 but not supported in LuaJIT.
 * Lurek2D targets LuaJIT — these produce a Warning diagnostic.
 */
const COMPAT_RULES: CompatRule[] = [
  {
    code: "lurek.compat.constAttribute",
    pattern: /\blocal\s+\w+\s*<\s*const\s*>/,
    message:
      "Lua 5.4 `<const>` attribute is not supported in LuaJIT. Remove the attribute — LuaJIT inlines constants automatically.",
  },
  {
    code: "lurek.compat.closeAttribute",
    pattern: /\blocal\s+\w+\s*<\s*close\s*>/,
    message:
      "Lua 5.4 `<close>` (to-be-closed variable) is not supported in LuaJIT. Use explicit :close() or defer via a wrapper.",
  },
  {
    code: "lurek.compat.utf8Library",
    pattern: /\butf8\s*\.\s*\w+\s*\(/,
    message:
      "The `utf8` standard library is not available in LuaJIT. Use lurek.utf8.* instead or the luajit-utf8 binding.",
  },
  {
    code: "lurek.compat.tableMove",
    pattern: /\btable\s*\.\s*move\s*\(/,
    message:
      "`table.move` behaviour differs between Lua 5.4 and LuaJIT. Test carefully, or use a manual loop for portability.",
  },
  {
    code: "lurek.compat.bitwiseTilde",
    pattern: /(?<![=<>~])\s*~(?!\s*=)\s*(?![-\\/])/,
    message:
      "Lua 5.4 bitwise `~` (XOR / NOT) operator is not supported in LuaJIT. Use `bit.bxor(a, b)` or `bit.bnot(a)` instead.",
  },
  {
    code: "lurek.compat.intDivOp",
    pattern: /\/\//,
    message:
      "Floor-division operator `//` is a LuaJIT extension that matches Lua 5.4. Behaviour is consistent — no action needed. (Hint only.)",
  },
  {
    code: "lurek.compat.warnLevel",
    pattern: /(?<!\.)(?<!\w)\bwarn\s*\(/,
    message: "`warn()` is a Lua 5.4-only function and is not available in LuaJIT. Use `print()` or `lurek.log.warn()` instead.",
  },
];

/**
 * Detect which line ranges are inside lurek.update or lurek.draw (hot paths).
 * Returns a set of 0-based line numbers considered "hot".
 */
function findHotPathLines(text: string): Set<number> {
  const hot = new Set<number>();
  const lines = text.split("\n");
  let depth = 0;
  let inHotPath = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // Detect function lurek.update or lurek.draw
    if (/^\s*function\s+lurek\.(update|draw)\s*\(/.test(line)) {
      inHotPath = true;
      depth = 0;
    }

    if (inHotPath) {
      // Count nesting via simple keyword matching
      const opens = (line.match(/\b(function|do|then|repeat)\b/g) || []).length;
      const closes = (line.match(/\b(end|until)\b/g) || []).length;
      depth += opens - closes;
      hot.add(i);

      if (depth <= 0 && i > 0) {
        inHotPath = false;
      }
    }
  }

  return hot;
}

/**
 * Registers LuaJIT-specific performance and compat diagnostics.
 * NOTE: bit.*, jit.*, ffi.* completions/hover are now handled by sumneko.lua.
 */
export function register(
  context: vscode.ExtensionContext,
  _apiData: ApiDataService
): void {
  const disposables: vscode.Disposable[] = [];

  // ── Performance hint diagnostics ────────────────────────

  const diagCollection = vscode.languages.createDiagnosticCollection("lurek.luajit");
  disposables.push(diagCollection);

  const compatCollection = vscode.languages.createDiagnosticCollection("lurek.compat");
  disposables.push(compatCollection);

  function analyzePerfHints(document: vscode.TextDocument): void {
    if (document.languageId !== "lua") return;

    const text = document.getText();
    const hotLines = findHotPathLines(text);
    const diagnostics: vscode.Diagnostic[] = [];
    const lines = text.split("\n");

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      // Skip comments
      if (/^\s*--/.test(line)) continue;

      for (const rule of PERF_RULES) {
        if (rule.hotPathOnly && !hotLines.has(i)) continue;

        const match = rule.pattern.exec(line);
        if (match) {
          const startCol = match.index;
          const endCol = match.index + match[0].length;
          const range = new vscode.Range(i, startCol, i, endCol);
          const diag = new vscode.Diagnostic(range, rule.message, rule.severity);
          diag.code = rule.code;
          diag.source = "Lurek2D LuaJIT";
          diagnostics.push(diag);
        }
      }
    }

    diagCollection.set(document.uri, diagnostics);
  }

  function analyzeCompatWarnings(document: vscode.TextDocument): void {
    if (document.languageId !== "lua") return;

    const text = document.getText();
    const diagnostics: vscode.Diagnostic[] = [];
    const lines = text.split("\n");

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      // Skip full-line comments
      if (/^\s*--/.test(line)) continue;
      // Strip inline comments before matching
      const stripped = line.replace(/--.*$/, "");

      for (const rule of COMPAT_RULES) {
        const match = rule.pattern.exec(stripped);
        if (match) {
          const startCol = match.index;
          const endCol = match.index + match[0].length;
          const range = new vscode.Range(i, startCol, i, endCol);
          const sev = rule.code === "lurek.compat.intDivOp"
            ? vscode.DiagnosticSeverity.Hint
            : vscode.DiagnosticSeverity.Warning;
          const diag = new vscode.Diagnostic(range, rule.message, sev);
          diag.code = rule.code;
          diag.source = "Lurek2D Compat";
          diagnostics.push(diag);
        }
      }
    }

    compatCollection.set(document.uri, diagnostics);
  }

  // Analyze open editors and on change
  if (vscode.window.activeTextEditor) {
    analyzePerfHints(vscode.window.activeTextEditor.document);
    analyzeCompatWarnings(vscode.window.activeTextEditor.document);
  }

  disposables.push(
    vscode.window.onDidChangeActiveTextEditor((editor) => {
      if (editor) {
        analyzePerfHints(editor.document);
        analyzeCompatWarnings(editor.document);
      }
    }),
    vscode.workspace.onDidChangeTextDocument((e) => {
      analyzePerfHints(e.document);
      analyzeCompatWarnings(e.document);
    }),
    vscode.workspace.onDidCloseTextDocument((doc) => {
      diagCollection.delete(doc.uri);
      compatCollection.delete(doc.uri);
    })
  );

  context.subscriptions.push(...disposables);
}
