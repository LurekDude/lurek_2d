import * as vscode from 'vscode';
import { ApiDataService } from '../services/apiData.js';
import { LuaDocumentAnalyzer, TokenType } from '../services/luaParser.js';

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: 'file', language: 'lua' };
const analyzer = new LuaDocumentAnalyzer();

/**
 * Registers the code folding provider for Lua files.
 */
export function register(context: vscode.ExtensionContext, _apiData: ApiDataService): void {
    context.subscriptions.push(
        vscode.languages.registerFoldingRangeProvider(LUA_SELECTOR, {
            provideFoldingRanges(document): vscode.FoldingRange[] {
                try {
                    return computeFoldingRanges(document);
                } catch {
                    return [];
                }
            },
        }),
    );
}

// ── Folding computation ──────────────────────────────────────

interface StackEntry {
    keyword: string;
    line: number;
    kind: vscode.FoldingRangeKind;
}

function computeFoldingRanges(document: vscode.TextDocument): vscode.FoldingRange[] {
    const text = document.getText();
    const tokens = analyzer.tokenize(text);
    const ranges: vscode.FoldingRange[] = [];

    // Stack for keyword-based blocks
    const stack: StackEntry[] = [];

    // Track multiline comments and strings from tokens
    addTokenFolds(tokens, ranges);

    // Track region markers and consecutive doc comments from lines
    addLineFolds(document, ranges);

    // Non-whitespace, non-comment, non-string tokens for block analysis
    const codeToks = tokens.filter(t =>
        t.type !== TokenType.Whitespace &&
        t.type !== TokenType.Comment &&
        t.type !== TokenType.String &&
        t.type !== TokenType.EOF,
    );

    // Track `{` / `}` for table constructors
    const braceStack: number[] = [];

    for (const tok of codeToks) {
        if (tok.type === TokenType.Keyword) {
            switch (tok.value) {
                case 'function':
                case 'if':
                case 'for':
                case 'while':
                case 'do':
                    stack.push({ keyword: tok.value, line: tok.line, kind: vscode.FoldingRangeKind.Region });
                    break;

                case 'repeat':
                    stack.push({ keyword: 'repeat', line: tok.line, kind: vscode.FoldingRangeKind.Region });
                    break;

                case 'end': {
                    const entry = popMatching(stack, ['function', 'if', 'for', 'while', 'do']);
                    if (entry && tok.line > entry.line) {
                        ranges.push(new vscode.FoldingRange(entry.line, tok.line, entry.kind));
                    }
                    break;
                }

                case 'until': {
                    const entry = popMatching(stack, ['repeat']);
                    if (entry && tok.line > entry.line) {
                        ranges.push(new vscode.FoldingRange(entry.line, tok.line, entry.kind));
                    }
                    break;
                }
            }
        }

        if (tok.type === TokenType.Punctuation) {
            if (tok.value === '{') {
                braceStack.push(tok.line);
            } else if (tok.value === '}') {
                const openLine = braceStack.pop();
                if (openLine !== undefined && tok.line > openLine) {
                    ranges.push(new vscode.FoldingRange(openLine, tok.line, vscode.FoldingRangeKind.Region));
                }
            }
        }
    }

    return ranges;
}

// ── Token-based folds (multiline comments & long strings) ────

function addTokenFolds(tokens: ReadonlyArray<{ type: TokenType; value: string; line: number }>, ranges: vscode.FoldingRange[]): void {
    for (const tok of tokens) {
        if (tok.type === TokenType.Comment && tok.value.startsWith('--[')) {
            const nlCount = countNewlines(tok.value);
            if (nlCount > 0) {
                ranges.push(new vscode.FoldingRange(tok.line, tok.line + nlCount, vscode.FoldingRangeKind.Comment));
            }
        }
        if (tok.type === TokenType.String && tok.value.startsWith('[')) {
            const nlCount = countNewlines(tok.value);
            if (nlCount > 0) {
                ranges.push(new vscode.FoldingRange(tok.line, tok.line + nlCount, vscode.FoldingRangeKind.Region));
            }
        }
    }
}

// ── Line-based folds (regions, consecutive doc comments) ─────

function addLineFolds(document: vscode.TextDocument, ranges: vscode.FoldingRange[]): void {
    const regionStack: number[] = [];
    let docCommentStart: number | undefined;
    let lastDocCommentLine = -2;

    for (let i = 0; i < document.lineCount; i++) {
        const line = document.lineAt(i).text.trimStart();

        // -- region / -- endregion markers
        if (/^--\s*region\b/i.test(line)) {
            regionStack.push(i);
        } else if (/^--\s*endregion\b/i.test(line)) {
            const start = regionStack.pop();
            if (start !== undefined && i > start) {
                ranges.push(new vscode.FoldingRange(start, i, vscode.FoldingRangeKind.Region));
            }
        }

        // Consecutive `---` doc comments
        if (/^---/.test(line) && !line.startsWith('---[')) {
            if (i === lastDocCommentLine + 1) {
                // continue the run
            } else {
                // flush previous run
                flushDocCommentRun(docCommentStart, lastDocCommentLine, ranges);
                docCommentStart = i;
            }
            lastDocCommentLine = i;
        }
    }
    // flush final run
    flushDocCommentRun(docCommentStart, lastDocCommentLine, ranges);
}

function flushDocCommentRun(start: number | undefined, end: number, ranges: vscode.FoldingRange[]): void {
    if (start !== undefined && end > start) {
        ranges.push(new vscode.FoldingRange(start, end, vscode.FoldingRangeKind.Comment));
    }
}

// ── Helpers ──────────────────────────────────────────────────

function popMatching(stack: StackEntry[], keywords: string[]): StackEntry | undefined {
    for (let i = stack.length - 1; i >= 0; i--) {
        if (keywords.includes(stack[i].keyword)) {
            return stack.splice(i, 1)[0];
        }
    }
    return undefined;
}

function countNewlines(text: string): number {
    let count = 0;
    for (const ch of text) {
        if (ch === '\n') count++;
    }
    return count;
}
