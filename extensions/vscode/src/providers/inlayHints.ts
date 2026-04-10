import * as vscode from 'vscode';
import { ApiDataService } from '../services/apiData.js';
import { LuaDocumentAnalyzer } from '../services/luaParser.js';

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: 'file', language: 'lua' };
const analyzer = new LuaDocumentAnalyzer();

/**
 * Registers the inlay hints provider for lurek.* function calls.
 * Shows parameter name hints at call sites.
 */
export function register(context: vscode.ExtensionContext, apiData: ApiDataService): void {
    const provider = vscode.languages.registerInlayHintsProvider(LUA_SELECTOR, {
        provideInlayHints(
            document: vscode.TextDocument,
            range: vscode.Range,
        ): vscode.InlayHint[] {
            try {
                const config = vscode.workspace.getConfiguration('lurek');
                if (config.get<boolean>('inlayHints.enabled') === false) return [];

                return getInlayHints(document, range, apiData);
            } catch {
                return [];
            }
        },
    });

    context.subscriptions.push(provider);
}

function getInlayHints(
    document: vscode.TextDocument,
    range: vscode.Range,
    apiData: ApiDataService,
): vscode.InlayHint[] {
    const hints: vscode.InlayHint[] = [];
    const text = document.getText(range);
    const offset = document.offsetAt(range.start);

    // Match lurek.module.func(...) calls — handle nested parens by finding the call then parsing args
    const callPattern = /(lurek\.\w+\.\w+)\s*\(/g;
    let callMatch: RegExpExecArray | null;

    while ((callMatch = callPattern.exec(text)) !== null) {
        const fullPath = callMatch[1];
        const fn = apiData.getFunction(fullPath);
        if (!fn || fn.parameters.length === 0) continue;

        // Find the opening paren position
        const openParenIdx = callMatch.index + callMatch[0].length - 1;
        const argsText = extractArgsText(text, openParenIdx);
        if (!argsText) continue;

        const args = splitArgs(argsText);

        // Don't show hints for single-argument calls
        if (args.length <= 1) continue;

        // Calculate the absolute offset of the arguments start
        const argsStartOffset = offset + openParenIdx + 1;

        let argOffset = argsStartOffset;
        for (let i = 0; i < args.length && i < fn.parameters.length; i++) {
            const arg = args[i];
            const trimmedArg = arg.trimStart();
            const leadingSpaces = arg.length - trimmedArg.length;

            // Skip if argument is a named assignment (e.g., "x = 5")
            if (/^\w+\s*=/.test(trimmedArg)) {
                argOffset += arg.length + 1;
                continue;
            }

            const param = fn.parameters[i];

            // Skip if argument variable name matches the parameter name
            if (trimmedArg === param.name) {
                argOffset += arg.length + 1;
                continue;
            }

            // Skip obvious string/boolean literals where context is clear
            if (shouldSkipHint(trimmedArg, param.name)) {
                argOffset += arg.length + 1;
                continue;
            }

            const pos = document.positionAt(argOffset + leadingSpaces);
            const hint = new vscode.InlayHint(
                pos,
                `${param.name}:`,
                vscode.InlayHintKind.Parameter,
            );
            hint.paddingRight = true;
            hints.push(hint);

            argOffset += arg.length + 1; // +1 for comma
        }
    }

    return hints;
}

/**
 * Extract the text between matching parentheses starting at openParenIdx.
 */
function extractArgsText(text: string, openParenIdx: number): string | undefined {
    if (text[openParenIdx] !== '(') return undefined;

    let depth = 1;
    let pos = openParenIdx + 1;
    while (pos < text.length && depth > 0) {
        const ch = text[pos];
        if (ch === '(') depth++;
        else if (ch === ')') depth--;
        pos++;
    }

    if (depth !== 0) return undefined;
    return text.slice(openParenIdx + 1, pos - 1);
}

/**
 * Split function arguments by commas, respecting nested parens/brackets/braces/strings.
 */
function splitArgs(argsText: string): string[] {
    if (!argsText.trim()) return [];

    const args: string[] = [];
    let current = '';
    let depth = 0;
    let inString: string | null = null;

    for (let i = 0; i < argsText.length; i++) {
        const ch = argsText[i];

        // Handle escape sequences inside strings
        if (inString && ch === '\\') {
            current += ch;
            if (i + 1 < argsText.length) {
                current += argsText[i + 1];
                i++;
            }
            continue;
        }

        // String boundaries
        if (!inString && (ch === '"' || ch === "'")) {
            inString = ch;
            current += ch;
            continue;
        }
        if (inString && ch === inString) {
            inString = null;
            current += ch;
            continue;
        }

        if (inString) {
            current += ch;
            continue;
        }

        if (ch === '(' || ch === '{' || ch === '[') {
            depth++;
            current += ch;
        } else if (ch === ')' || ch === '}' || ch === ']') {
            depth--;
            current += ch;
        } else if (ch === ',' && depth === 0) {
            args.push(current);
            current = '';
        } else {
            current += ch;
        }
    }

    if (current) args.push(current);
    return args;
}

/**
 * Determine if a hint should be skipped for a given argument.
 * Skip for obvious boolean/string literals where the parameter intent is clear.
 */
function shouldSkipHint(arg: string, paramName: string): boolean {
    // Skip if the argument is true/false and param name suggests boolean
    if ((arg === 'true' || arg === 'false' || arg === 'nil') && paramName.length <= 4) {
        return true;
    }
    return false;
}
