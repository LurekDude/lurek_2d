import * as vscode from "vscode";
import { ApiDataService } from "../services/apiData.js";
import { LuaDocumentAnalyzer } from "../services/luaParser.js";

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: "file", language: "lua" };
const analyzer = new LuaDocumentAnalyzer();

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

      // For dotted paths like luna.graphics.draw, search the full path
      // For simple identifiers, search just the word
      const searchTerm = word.includes(".") ? word : word;
      const locations: vscode.Location[] = [];

      // Search across all .lua files in workspace
      const files = await vscode.workspace.findFiles("**/*.lua", "**/node_modules/**", 500);

      for (const fileUri of files) {
        try {
          const doc = await vscode.workspace.openTextDocument(fileUri);
          const text = doc.getText();

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
              const pos = doc.positionAt(match.index);
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
          // Skip files that can't be opened
        }
      }

      return locations;
    },
  });

  context.subscriptions.push(provider);
}
