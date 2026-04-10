import * as vscode from "vscode";

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: "file", language: "lua" };

// ── Lurek2D callback names (always shown) ───────────────────────

const LUREK_CALLBACKS = new Set([
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

      // Check if this is a lurek.callback
      const lurekCallbackMatch = funcName.match(/^lurek\.(\w+)$/);
      const cbName = lurekCallbackMatch?.[1];

      if (cbName && LUREK_CALLBACKS.has(cbName)) {
        // Lurek2D callback: show documentation link
        lenses.push(new vscode.CodeLens(range, {
          title: `⚡ lurek.${cbName} callback`,
          command: "lurek.browseApi",
          arguments: [`lurek.${cbName}`],
          tooltip: `Open API documentation for lurek.${cbName}`,
        }));
      } else {
        // Regular function: show reference count
        const refCount = countRefs(funcName.split(".").pop() ?? funcName);
        const refLabel = refCount === 1 ? "1 reference" : `${refCount} references`;
        lenses.push(new vscode.CodeLens(range, {
          title: refCount === 0 ? "⚠ unused" : refLabel,
          command: "lurek.codelens.findRefs",
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
          command: "lurek.test.runSingleLua",
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
  barItem.name = "Lurek2D Variable Type";
  barItem.tooltip = "Type of the Lua symbol under the cursor";
  barItem.command = "lurek.debug.openInspector";
  context.subscriptions.push(barItem);

  // Known type table: simple type inference from surrounding code
  const TYPE_INIT: { pattern: RegExp; type: string }[] = [
    { pattern: /=\s*\d+(?:\.\d+)?(?!\w)/, type: "number" },
    { pattern: /=\s*["']/, type: "string" },
    { pattern: /=\s*(?:true|false)\b/, type: "boolean" },
    { pattern: /=\s*\{/, type: "table" },
    { pattern: /=\s*function\s*\(/, type: "function" },
    { pattern: /=\s*nil\b/, type: "nil" },
    { pattern: /lurek\.graphics\.newImage\s*\(/, type: "Image" },
    { pattern: /lurek\.graphics\.newCanvas\s*\(/, type: "Canvas" },
    { pattern: /lurek\.graphics\.newFont\s*\(/, type: "Font" },
    { pattern: /lurek\.graphics\.newShader\s*\(/, type: "Shader" },
    { pattern: /lurek\.graphics\.newMesh\s*\(/, type: "Mesh" },
    { pattern: /lurek\.graphics\.newSpriteBatch\s*\(/, type: "SpriteBatch" },
    { pattern: /lurek\.graphics\.newParticleSystem\s*\(/, type: "ParticleSystem" },
    { pattern: /lurek\.audio\.newSource\s*\(/, type: "Source" },
    { pattern: /lurek\.physics\.newWorld\s*\(/, type: "World" },
    { pattern: /lurek\.physics\.newBody\s*\(/, type: "Body" },
    { pattern: /lurek\.physics\.newFixture\s*\(/, type: "Fixture" },
    { pattern: /lurek\.physics\.newRectangleShape\s*\(/, type: "PolygonShape" },
    { pattern: /lurek\.physics\.newCircleShape\s*\(/, type: "CircleShape" },
    { pattern: /lurek\.math\.newTransform\s*\(/, type: "Transform" },
    { pattern: /lurek\.cardgame\.newCard\s*\(/, type: "Card" },
    { pattern: /lurek\.cardgame\.newDeck\s*\(/, type: "Deck" },
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
      "lurek.codelens.findRefs",
      async (_uri: vscode.Uri, pos: vscode.Position) => {
        await vscode.commands.executeCommand("editor.action.referenceSearch.trigger", pos);
      },
    ),
  );

  // Variable type inspector in status bar
  buildVariableInspector(context);

  // Config toggle: enable/disable code lenses
  context.subscriptions.push(
    vscode.commands.registerCommand("lurek.codeLens.toggle", () => {
      const cfg = vscode.workspace.getConfiguration("lurek");
      const current = cfg.get<boolean>("codeLens.enabled", true);
      cfg.update("codeLens.enabled", !current, vscode.ConfigurationTarget.Global);
      vscode.window.showInformationMessage(
        `Lurek2D Code Lens ${!current ? "enabled" : "disabled"}`,
      );
    }),
  );
}
