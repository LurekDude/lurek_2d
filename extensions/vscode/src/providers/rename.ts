import * as vscode from 'vscode';
import { ApiDataService } from '../services/apiData.js';
import { LuaDocumentAnalyzer, TokenType } from '../services/luaParser.js';

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: 'file', language: 'lua' };
const analyzer = new LuaDocumentAnalyzer();

const LUA_KEYWORDS = new Set([
    'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for',
    'function', 'goto', 'if', 'in', 'local', 'nil', 'not', 'or',
    'repeat', 'return', 'then', 'true', 'until', 'while',
]);

/**
 * Registers the rename provider for Lua files.
 */
export function register(context: vscode.ExtensionContext, apiData: ApiDataService): void {
    context.subscriptions.push(
        vscode.languages.registerRenameProvider(LUA_SELECTOR, {
            prepareRename(document, position): vscode.ProviderResult<vscode.Range | { range: vscode.Range; placeholder: string }> {
                try {
                    return doPrepareRename(document, position, apiData);
                } catch {
                    return undefined;
                }
            },
            provideRenameEdits(document, position, newName): vscode.ProviderResult<vscode.WorkspaceEdit> {
                try {
                    return doRename(document, position, newName, apiData);
                } catch {
                    return undefined;
                }
            },
        }),
    );
}

// ── Prepare rename ───────────────────────────────────────────

function doPrepareRename(
    document: vscode.TextDocument,
    position: vscode.Position,
    apiData: ApiDataService,
): { range: vscode.Range; placeholder: string } | undefined {
    const text = document.getText();
    const line = position.line;
    const col = position.character;

    // Don't rename inside strings or comments
    if (analyzer.isInsideString(text, line, col) || analyzer.isInsideComment(text, line, col)) {
        return undefined;
    }

    const word = getWordAt(document, position);
    if (!word) return undefined;

    // Don't rename Lua keywords
    if (LUA_KEYWORDS.has(word.text)) {
        return undefined;
    }

    // Don't rename lurek.* API names
    if (isLurekApiName(document, position, word.text, apiData)) {
        return undefined;
    }

    return { range: word.range, placeholder: word.text };
}

// ── Rename execution ─────────────────────────────────────────

function doRename(
    document: vscode.TextDocument,
    position: vscode.Position,
    newName: string,
    apiData: ApiDataService,
): vscode.WorkspaceEdit | undefined {
    const text = document.getText();
    const line = position.line;
    const col = position.character;

    if (analyzer.isInsideString(text, line, col) || analyzer.isInsideComment(text, line, col)) {
        return undefined;
    }

    const word = getWordAt(document, position);
    if (!word || LUA_KEYWORDS.has(word.text)) return undefined;
    if (isLurekApiName(document, position, word.text, apiData)) return undefined;

    const symbolName = word.text;
    const info = analyzer.analyze(text);

    // Find the symbol definition to determine scope
    const defSymbol = info.symbols.find(s =>
        s.name === symbolName && (s.kind === 'local' || s.kind === 'function' || s.kind === 'parameter'),
    );

    // Determine the scope range for local/parameter symbols
    let scopeStartLine = 0;
    let scopeEndLine = document.lineCount - 1;

    if (defSymbol?.isLocal && defSymbol.scope) {
        const parentScope = info.scopes.find(sc => sc.name === defSymbol.scope);
        if (parentScope) {
            scopeStartLine = parentScope.startLine;
            scopeEndLine = parentScope.endLine;
        }
    } else if (defSymbol?.kind === 'parameter' && defSymbol.scope) {
        const funcScope = info.scopes.find(sc => sc.name === defSymbol.scope);
        if (funcScope) {
            scopeStartLine = funcScope.startLine;
            scopeEndLine = funcScope.endLine;
        }
    }

    // Find all identifier tokens matching the symbol name
    const tokens = analyzer.tokenize(text);
    const edit = new vscode.WorkspaceEdit();

    for (const tok of tokens) {
        if (tok.type !== TokenType.Identifier) continue;
        if (tok.value !== symbolName) continue;
        if (tok.line < scopeStartLine || tok.line > scopeEndLine) continue;

        // Skip occurrences inside strings/comments
        if (analyzer.isInsideString(text, tok.line, tok.column)) continue;
        if (analyzer.isInsideComment(text, tok.line, tok.column)) continue;

        // Verify word boundary: the character before/after must not be an identifier char
        const lineText = document.lineAt(tok.line).text;
        const before = tok.column > 0 ? lineText[tok.column - 1] : '';
        const after = tok.column + tok.length < lineText.length ? lineText[tok.column + tok.length] : '';
        if (isIdentChar(before) || isIdentChar(after)) continue;

        const range = new vscode.Range(tok.line, tok.column, tok.line, tok.column + tok.length);
        edit.replace(document.uri, range, newName);
    }

    return edit;
}

// ── Helpers ──────────────────────────────────────────────────

interface WordInfo {
    text: string;
    range: vscode.Range;
}

function getWordAt(document: vscode.TextDocument, position: vscode.Position): WordInfo | undefined {
    const range = document.getWordRangeAtPosition(position, /[a-zA-Z_]\w*/);
    if (!range) return undefined;
    return { text: document.getText(range), range };
}

function isLurekApiName(
    document: vscode.TextDocument,
    position: vscode.Position,
    word: string,
    apiData: ApiDataService,
): boolean {
    const lineText = document.lineAt(position.line).text;
    const wordStart = position.character;

    // Check if preceded by `lurek.` or `lurek.xxx.`
    const beforeWord = lineText.substring(0, wordStart);
    if (/lurek\.\w*\.?$/.test(beforeWord)) {
        // Check if it's a known API function
        const fn = apiData.getAllFunctions().find(f => f.name === word);
        if (fn) return true;
    }

    // `lurek` itself
    if (word === 'lurek') {
        return true;
    }

    return false;
}

function isIdentChar(ch: string): boolean {
    return /[a-zA-Z0-9_]/.test(ch);
}
