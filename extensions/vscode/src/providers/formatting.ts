import * as vscode from 'vscode';
import { ApiDataService } from '../services/apiData.js';

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: 'file', language: 'lua' };

// Keywords that open a block (increase indent after the line)
const BLOCK_OPENERS = /\b(function|if|for|while|do|repeat)\b/;
// Keywords/tokens that close a block (decrease indent for this line)
const BLOCK_CLOSERS = /^\s*(end|else|elseif|until)\b/;
// `}` as the first non-whitespace
const BRACE_CLOSER = /^\s*\}/;
// `{` at end of line (opens indent)
const BRACE_OPENER = /\{\s*$/;

/**
 * Registers document formatting and range-formatting providers for Lua.
 */
export function register(context: vscode.ExtensionContext, _apiData: ApiDataService): void {
    const provider: vscode.DocumentFormattingEditProvider & vscode.DocumentRangeFormattingEditProvider = {
        provideDocumentFormattingEdits(document, options) {
            try {
                return formatDocument(document, options);
            } catch {
                return [];
            }
        },
        provideDocumentRangeFormattingEdits(document, range, options) {
            try {
                return formatRange(document, range, options);
            } catch {
                return [];
            }
        },
    };

    context.subscriptions.push(
        vscode.languages.registerDocumentFormattingEditProvider(LUA_SELECTOR, provider),
        vscode.languages.registerDocumentRangeFormattingEditProvider(LUA_SELECTOR, provider),
    );
}

// ── Core formatting ──────────────────────────────────────────

function formatDocument(document: vscode.TextDocument, options: vscode.FormattingOptions): vscode.TextEdit[] {
    const fullRange = new vscode.Range(0, 0, document.lineCount - 1, document.lineAt(document.lineCount - 1).text.length);
    return formatRange(document, fullRange, options);
}

function formatRange(document: vscode.TextDocument, range: vscode.Range, options: vscode.FormattingOptions): vscode.TextEdit[] {
    const text = document.getText();
    const lines = text.split(/\r?\n/);
    const indentStr = options.insertSpaces ? ' '.repeat(options.tabSize) : '\t';

    const formatted = formatLines(lines, indentStr);
    const newText = formatted.join('\n');

    if (newText === lines.join('\n')) {
        return [];
    }

    const fullRange = new vscode.Range(0, 0, document.lineCount - 1, document.lineAt(document.lineCount - 1).text.length);
    return [vscode.TextEdit.replace(fullRange, newText)];
}

interface MultilineState {
    inBlockComment: boolean;
    inLongString: boolean;
    closingPattern: string;
}

function formatLines(lines: string[], indentStr: string): string[] {
    const result: string[] = [];
    let indentLevel = 0;
    let consecutiveEmpty = 0;
    const mlState: MultilineState = { inBlockComment: false, inLongString: false, closingPattern: '' };

    for (let i = 0; i < lines.length; i++) {
        const raw = lines[i];

        // Inside a multi-line comment or long string: preserve verbatim
        if (mlState.inBlockComment || mlState.inLongString) {
            result.push(raw);
            if (raw.includes(mlState.closingPattern)) {
                mlState.inBlockComment = false;
                mlState.inLongString = false;
                mlState.closingPattern = '';
            }
            consecutiveEmpty = 0;
            continue;
        }

        // Trim the line
        const trimmed = raw.replace(/\s+$/, '').replace(/^\s+/, '');

        // Preserve empty lines (max 2 consecutive)
        if (trimmed === '') {
            consecutiveEmpty++;
            if (consecutiveEmpty <= 2) {
                result.push('');
            }
            continue;
        }
        consecutiveEmpty = 0;

        // Check for multi-line string/comment start
        const longStringStart = detectLongBracketOpen(trimmed);
        if (longStringStart) {
            const closing = longStringStart.closing;
            // Check if it closes on the same line
            const afterOpen = trimmed.slice(trimmed.indexOf(longStringStart.open) + longStringStart.open.length);
            if (!afterOpen.includes(closing)) {
                if (longStringStart.isComment) {
                    mlState.inBlockComment = true;
                } else {
                    mlState.inLongString = true;
                }
                mlState.closingPattern = closing;
            }
            // Output the line with current indent
            const deIndent = computeDeIndent(trimmed);
            indentLevel = Math.max(0, indentLevel + deIndent);
            result.push(makeIndent(indentStr, indentLevel) + trimmed);
            const addIndent = computeAddIndent(trimmed);
            indentLevel = Math.max(0, indentLevel + addIndent);
            continue;
        }

        // Handle line comment: apply indent but don't parse keywords inside
        if (trimmed.startsWith('--')) {
            result.push(makeIndent(indentStr, indentLevel) + trimmed);
            continue;
        }

        // Strip strings for keyword analysis
        const stripped = stripStrings(trimmed);

        // Compute indent changes
        const deIndent = computeDeIndentFromStripped(stripped);
        indentLevel = Math.max(0, indentLevel + deIndent);
        result.push(makeIndent(indentStr, indentLevel) + trimmed);
        const addIndent = computeAddIndentFromStripped(stripped);
        indentLevel = Math.max(0, indentLevel + addIndent);
    }

    return result;
}

// ── Indent computation ───────────────────────────────────────

function computeDeIndent(trimmed: string): number {
    const stripped = stripStrings(trimmed);
    return computeDeIndentFromStripped(stripped);
}

function computeDeIndentFromStripped(stripped: string): number {
    let delta = 0;
    if (BLOCK_CLOSERS.test(stripped)) {
        delta--;
    }
    if (BRACE_CLOSER.test(stripped)) {
        delta--;
    }
    return delta;
}

function computeAddIndent(trimmed: string): number {
    const stripped = stripStrings(trimmed);
    return computeAddIndentFromStripped(stripped);
}

function computeAddIndentFromStripped(stripped: string): number {
    // Don't indent single-line constructs
    if (isSingleLineBlock(stripped)) {
        return 0;
    }

    let delta = 0;

    // Count block openers
    if (BLOCK_OPENERS.test(stripped)) {
        // 'elseif' and 'else' are special: they de-indented above, now re-indent
        if (/^\s*(else|elseif)\b/.test(stripped)) {
            delta++;
        } else {
            delta++;
        }
    }

    // `{` at end of line
    if (BRACE_OPENER.test(stripped)) {
        delta++;
    }

    // Subtract closers that also appear on this line (e.g., opening function that also has `end`)
    // This is already handled by isSingleLineBlock

    return delta;
}

/**
 * Detects commonly single-line blocks:
 * - `if x then return end`
 * - `local function f() return 1 end`
 * - `function f() return 1 end`
 * - `{ a = 1, b = 2 }`
 */
function isSingleLineBlock(stripped: string): boolean {
    // Single-line function
    if (/\bfunction\b.*\bend\b/.test(stripped)) {
        return true;
    }
    // Single-line if
    if (/\bif\b.*\bthen\b.*\bend\b/.test(stripped)) {
        return true;
    }
    // Single-line for/while/do
    if (/\b(?:for|while)\b.*\bdo\b.*\bend\b/.test(stripped)) {
        return true;
    }
    // Single-line table `{ ... }` — both braces on same line
    if (/\{.*\}/.test(stripped) && !BRACE_OPENER.test(stripped)) {
        return true;
    }
    return false;
}

// ── String / comment stripping ───────────────────────────────

/**
 * Replace string literals with empty placeholders to avoid
 * detecting keywords inside strings.
 */
function stripStrings(line: string): string {
    let result = '';
    let i = 0;
    while (i < line.length) {
        const ch = line[i];
        // Long string [[ ... ]]
        if (ch === '[') {
            const level = countLongBracketLevel(line, i);
            if (level >= 0) {
                const closing = ']' + '='.repeat(level) + ']';
                const end = line.indexOf(closing, i + 2 + level);
                if (end >= 0) {
                    i = end + closing.length;
                    continue;
                }
            }
            result += ch;
            i++;
            continue;
        }
        // Quoted strings
        if (ch === '"' || ch === "'") {
            i++;
            while (i < line.length) {
                if (line[i] === '\\') { i += 2; continue; }
                if (line[i] === ch) { i++; break; }
                i++;
            }
            continue;
        }
        result += ch;
        i++;
    }
    return result;
}

// ── Long bracket detection ───────────────────────────────────

interface LongBracketInfo {
    open: string;
    closing: string;
    isComment: boolean;
}

function detectLongBracketOpen(line: string): LongBracketInfo | undefined {
    // --[[ or --[=[ block comment
    const commentMatch = line.match(/--\[(=*)\[/);
    if (commentMatch) {
        const level = commentMatch[1].length;
        return {
            open: '--[' + '='.repeat(level) + '[',
            closing: ']' + '='.repeat(level) + ']',
            isComment: true,
        };
    }
    // [[ or [=[ long string (not preceded by --)
    const strMatch = line.match(/(?<!--)\[(=*)\[/);
    if (strMatch) {
        const level = strMatch[1].length;
        return {
            open: '[' + '='.repeat(level) + '[',
            closing: ']' + '='.repeat(level) + ']',
            isComment: false,
        };
    }
    return undefined;
}

function countLongBracketLevel(text: string, pos: number): number {
    if (text[pos] !== '[') return -1;
    let level = 0;
    let p = pos + 1;
    while (p < text.length && text[p] === '=') { level++; p++; }
    if (p < text.length && text[p] === '[') return level;
    return -1;
}

// ── Helpers ──────────────────────────────────────────────────

function makeIndent(indentStr: string, level: number): string {
    return indentStr.repeat(Math.max(0, level));
}
