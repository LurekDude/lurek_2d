import * as vscode from "vscode";
import { ApiDataService } from "../services/apiData.js";
import { LuaDocumentAnalyzer } from "../services/luaParser.js";

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: "file", language: "lua" };
const analyzer = new LuaDocumentAnalyzer();

/** Compute a vscode.Position from a raw text offset (replaces doc.positionAt). */
function positionFromOffset(text: string, offset: number): vscode.Position {
  const before = text.substring(0, offset);
  const lines = before.split("\n");
  return new vscode.Position(lines.length - 1, lines[lines.length - 1].length);
}

// ── Provider registration ────────────────────────────────────

export function register(
  context: vscode.ExtensionContext,
  apiData: ApiDataService,
): void {
  const provider = vscode.languages.registerReferenceProvider(LUA_SELECTOR, {
    async provideReferences(
      document: vscode.TextDocument,
      position: vscode.Position,
      _refContext: vscode.ReferenceContext,
    ): Promise<vscode.Location[]> {
      const wordRange = document.getWordRangeAtPosition(position, /[\w.]+/);
      if (!wordRange) return [];
      const word = document.getText(wordRange);
      if (!word || word.length < 2) return [];

      // For dotted paths like lurek.graphics.draw, search the full path
      // For simple identifiers, search just the word
      const searchTerm = word.includes(".") ? word : word;
      const locations: vscode.Location[] = [];

      // Search across all .lua files in workspace
      const files = await vscode.workspace.findFiles(
        "**/*.lua",
        "{**/node_modules/**,ideas/**,work/**,.github/**,**/build/**,**/save/**,**/assets/**,**/logs/**}",
        500,
      );

      for (const fileUri of files) {
        try {
          const bytes = await vscode.workspace.fs.readFile(fileUri);
          const text = new TextDecoder().decode(bytes);

          // Use analyzer for precise token-based search
          const refs = analyzer.findReferencesInDocument(text, searchTerm);
          for (const ref of refs) {
            locations.push(new vscode.Location(
              fileUri,
              new vscode.Position(ref.line, ref.column),
            ));
          }

          // For dotted paths, also do a string search since the tokenizer
          // splits on dots
          if (searchTerm.includes(".")) {
            const escaped = searchTerm.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
            const pattern = new RegExp(escaped, "g");
            let match: RegExpExecArray | null;
            while ((match = pattern.exec(text)) !== null) {
              const pos = positionFromOffset(text, match.index);
              // Avoid duplicates
              const isDuplicate = locations.some(
                loc => loc.uri.fsPath === fileUri.fsPath &&
                       loc.range.start.line === pos.line &&
                       loc.range.start.character === pos.character,
              );
              if (!isDuplicate) {
                locations.push(new vscode.Location(fileUri, pos));
              }
            }
          }
        } catch {
          // Skip files that can't be read
        }
      }

      return locations;
    },
  });

  context.subscriptions.push(provider);
}
