import * as vscode from "vscode";

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: "file", language: "lua" };

// ── Luna callback names (always shown) ───────────────────────

const LUNA_CALLBACKS = new Set([
  "load", "update", "draw", "keypressed", "keyreleased", "textinput",
  "mousepressed", "mousereleased", "wheelmoved", "resize", "focus", "visible",
  "gamepadpressed", "gamepadreleased", "gamepadaxis", "joystickadded",
  "joystickremoved", "touchpressed", "touchmoved", "touchreleased",
]);

// ── CodeLens: function reference counts + run targets ────────

class LuaCodeLensProvider implements vscode.CodeLensProvider {
  private readonly _onDidChange = new vscode.EventEmitter<void>();
  readonly onDidChangeCodeLenses = this._onDidChange.event;

  provideCodeLenses(document: vscode.TextDocument): vscode.CodeLens[] {
    const lenses: vscode.CodeLens[] = [];
    const text = document.getText();
    const lines = text.split("\n");

    // Collect all function definitions
    const funcDef = /^(?:local\s+function\s+(\w+)|function\s+([\w.:]+))/;

    // Count how many times each identifier appears in the whole document
    function countRefs(name: string): number {
      // Simple word-boundary count, skip the definition itself
      const plain = name.replace(/[.]/g, "\\.");
      const re = new RegExp(`\\b${plain}\\b`, "g");
      const all = text.match(re) ?? [];
      return Math.max(0, all.length - 1); // subtract 1 for the definition
    }

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const m = funcDef.exec(line.trimStart());
      if (!m) continue;

      const funcName = m[1] ?? m[2]; // local function X or function X.Y.Z
      if (!funcName) continue;
      const range = new vscode.Range(i, 0, i, 0);

      // Check if this is a luna.callback
      const lunaCallbackMatch = funcName.match(/^luna\.(\w+)$/);
      const cbName = lunaCallbackMatch?.[1];

      if (cbName && LUNA_CALLBACKS.has(cbName)) {
        // Luna callback: show documentation link
        lenses.push(new vscode.CodeLens(range, {
          title: `⚡ luna.${cbName} callback`,
          command: "luna.browseApi",
          arguments: [`luna.${cbName}`],
          tooltip: `Open API documentation for luna.${cbName}`,
        }));
      } else {
        // Regular function: show reference count
        const refCount = countRefs(funcName.split(".").pop() ?? funcName);
        const refLabel = refCount === 1 ? "1 reference" : `${refCount} references`;
        lenses.push(new vscode.CodeLens(range, {
          title: refCount === 0 ? "⚠ unused" : refLabel,
          command: "luna.codelens.findRefs",
          arguments: [document.uri, new vscode.Position(i, line.indexOf(funcName)), funcName],
          tooltip: refCount === 0
            ? `"${funcName}" is never called`
            : `Find all references to "${funcName}"`,
        }));
      }

      // Add "Run test" lens for test-style functions (test_ prefix or _test suffix)
      if (/^test_|_test\b/.test(funcName)) {
        lenses.push(new vscode.CodeLens(range, {
          title: "▶ Run test",
          command: "luna.test.runSingleLua",
          arguments: [document.uri, funcName],
          tooltip: `Run Lua test "${funcName}"`,
        }));
      }
    }

    return lenses;
  }

  refresh(): void {
    this._onDidChange.fire();
  }
}

// ── Variable type inspector (status bar) ─────────────────────

function buildVariableInspector(context: vscode.ExtensionContext): void {
  const barItem = vscode.window.createStatusBarItem(
    vscode.StatusBarAlignment.Right, 95,
  );
  barItem.name = "Luna Variable Type";
  barItem.tooltip = "Type of the Lua symbol under the cursor";
  barItem.command = "luna.debug.openInspector";
  context.subscriptions.push(barItem);

  // Known type table: simple type inference from surrounding code
  const TYPE_INIT: { pattern: RegExp; type: string }[] = [
    { pattern: /=\s*\d+(?:\.\d+)?(?!\w)/, type: "number" },
    { pattern: /=\s*["']/, type: "string" },
    { pattern: /=\s*(?:true|false)\b/, type: "boolean" },
    { pattern: /=\s*\{/, type: "table" },
    { pattern: /=\s*function\s*\(/, type: "function" },
    { pattern: /=\s*nil\b/, type: "nil" },
    { pattern: /luna\.graphics\.newImage\s*\(/, type: "Image" },
    { pattern: /luna\.graphics\.newCanvas\s*\(/, type: "Canvas" },
    { pattern: /luna\.graphics\.newFont\s*\(/, type: "Font" },
    { pattern: /luna\.graphics\.newShader\s*\(/, type: "Shader" },
    { pattern: /luna\.graphics\.newMesh\s*\(/, type: "Mesh" },
    { pattern: /luna\.graphics\.newSpriteBatch\s*\(/, type: "SpriteBatch" },
    { pattern: /luna\.graphics\.newParticleSystem\s*\(/, type: "ParticleSystem" },
    { pattern: /luna\.audio\.newSource\s*\(/, type: "Source" },
    { pattern: /luna\.physics\.newWorld\s*\(/, type: "World" },
    { pattern: /luna\.physics\.newBody\s*\(/, type: "Body" },
    { pattern: /luna\.physics\.newFixture\s*\(/, type: "Fixture" },
    { pattern: /luna\.physics\.newRectangleShape\s*\(/, type: "PolygonShape" },
    { pattern: /luna\.physics\.newCircleShape\s*\(/, type: "CircleShape" },
    { pattern: /luna\.math\.newTransform\s*\(/, type: "Transform" },
    { pattern: /luna\.cardgame\.newCard\s*\(/, type: "Card" },
    { pattern: /luna\.cardgame\.newDeck\s*\(/, type: "Deck" },
  ];

  function inferType(document: vscode.TextDocument, word: string): string | undefined {
    const text = document.getText();
    const lines = text.split("\n");
    // Walk backwards to find assignment
    for (let i = lines.length - 1; i >= 0; i--) {
      const line = lines[i];
      const assignPattern = new RegExp(`\\blocal\\s+${word}\\s*=|\\b${word}\\s*=(?!=)`, "g");
      if (!assignPattern.test(line)) continue;
      for (const { pattern, type } of TYPE_INIT) {
        if (pattern.test(line)) return type;
      }
      return "?";
    }
    return undefined;
  }

  context.subscriptions.push(
    vscode.window.onDidChangeTextEditorSelection((e) => {
      const editor = e.textEditor;
      if (editor.document.languageId !== "lua") {
        barItem.hide(); return;
      }
      const pos = editor.selection.active;
      const wordRange = editor.document.getWordRangeAtPosition(pos, /\w+/);
      if (!wordRange) { barItem.hide(); return; }
      const word = editor.document.getText(wordRange);
      if (/^(local|function|return|end|if|then|else|for|while|do|and|or|not|nil|true|false|repeat|until|break|goto|in)$/.test(word)) {
        barItem.hide(); return;
      }
      const t = inferType(editor.document, word);
      if (t) {
        barItem.text = `$(symbol-variable) ${word}: ${t}`;
        barItem.show();
      } else {
        barItem.hide();
      }
    }),
  );
}

// ── Registration ──────────────────────────────────────────────

export function register(context: vscode.ExtensionContext, _apiData: unknown): void {
  const provider = new LuaCodeLensProvider();
  context.subscriptions.push(
    vscode.languages.registerCodeLensProvider(LUA_SELECTOR, provider),
  );

  // Refresh code lenses when document changes
  context.subscriptions.push(
    vscode.workspace.onDidChangeTextDocument((e) => {
      if (e.document.languageId === "lua") provider.refresh();
    }),
  );

  // Command: find references from CodeLens click
  context.subscriptions.push(
    vscode.commands.registerCommand(
      "luna.codelens.findRefs",
      async (_uri: vscode.Uri, pos: vscode.Position) => {
        await vscode.commands.executeCommand("editor.action.referenceSearch.trigger", pos);
      },
    ),
  );

  // Variable type inspector in status bar
  buildVariableInspector(context);

  // Config toggle: enable/disable code lenses
  context.subscriptions.push(
    vscode.commands.registerCommand("luna.codeLens.toggle", () => {
      const cfg = vscode.workspace.getConfiguration("luna");
      const current = cfg.get<boolean>("codeLens.enabled", true);
      cfg.update("codeLens.enabled", !current, vscode.ConfigurationTarget.Global);
      vscode.window.showInformationMessage(
        `Luna Code Lens ${!current ? "enabled" : "disabled"}`,
      );
    }),
  );
}
