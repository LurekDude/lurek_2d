import * as vscode from 'vscode';
import { ApiDataService } from '../services/apiData.js';
import { LuaDocumentAnalyzer, TokenType, Token } from '../services/luaParser.js';
import { LUREK_CALLBACK_NAMES } from '../generated/lurekApiData.js';

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: 'file', language: 'lua' };
const analyzer = new LuaDocumentAnalyzer();

// ── Token legend ─────────────────────────────────────────────
//
// sumneko.lua handles all generic Lua semantic tokens (keywords, variables,
// functions, parameters, strings, numbers, operators, comments, LuaCATS).
// This provider adds ONLY Lurek2D-specific layers on top:
//   - lurekCallback: lurek.init, lurek.draw, lurek.process, etc.
//   - namespace:     lurek, lurek.graphics, lurek.physics, etc.
//   - function/defaultLibrary: lurek API function calls
//   - enumMember:   string literals that match a known lurek enum value

const tokenTypes = [
    'namespace',      // 0  lurek, lurek.graphics, lurek.physics, ...
    'function',       // 1  lurek API function calls
    'enumMember',     // 2  enum string literals ("fill", "alpha", "nearest", ...)
    'lurekCallback',  // 3  lifecycle callbacks (lurek.init, lurek.draw, ...)
];

const tokenModifiers = [
    'declaration',     // 0
    'definition',      // 1
    'readonly',        // 2
    'deprecated',      // 3
    'modification',    // 4
    'documentation',   // 5
    'defaultLibrary',  // 6
];

const legend = new vscode.SemanticTokensLegend(tokenTypes, tokenModifiers);

// Cached results per document version
const cache = new Map<string, { version: number; tokens: vscode.SemanticTokens }>();

/**
 * Registers the Lurek2D-specific semantic tokens provider for Lua files.
 *
 * This provider runs AFTER sumneko.lua and adds only Lurek2D-specific token
 * classifications on top — callbacks, namespaces, API functions, and enum
 * string values.  All generic Lua tokens (keywords, variables, comments, etc.)
 * are intentionally left to sumneko.lua.
 */
export function register(context: vscode.ExtensionContext, apiData: ApiDataService): void {
    context.subscriptions.push(
        vscode.languages.registerDocumentSemanticTokensProvider(LUA_SELECTOR, {
            provideDocumentSemanticTokens(document): vscode.SemanticTokens {
                try {
                    return computeSemanticTokens(document, apiData);
                } catch {
                    return new vscode.SemanticTokensBuilder(legend).build();
                }
            },
        }, legend),
    );
}

// ── Core computation ─────────────────────────────────────────

function computeSemanticTokens(document: vscode.TextDocument, apiData: ApiDataService): vscode.SemanticTokens {
    const key = document.uri.toString();
    const cached = cache.get(key);
    if (cached && cached.version === document.version) {
        return cached.tokens;
    }

    const text = document.getText();
    const tokens = analyzer.tokenize(text);
    const builder = new vscode.SemanticTokensBuilder(legend);

    // Build lookup sets
    const lurekFuncNames = new Set(apiData.getAllFunctions().map(f => f.name));
    const deprecatedFuncs = new Set(apiData.getAllFunctions().filter(f => f.deprecated).map(f => f.name));

    // Collect known lurek enum string values (e.g. "fill", "alpha", "nearest")
    const enumValues = new Set<string>();
    for (const modName of apiData.getModuleNames()) {
        const mod = apiData.getModule(modName);
        if (mod) {
            for (const fn of [...mod.functions, ...mod.methods]) {
                for (const p of fn.parameters) {
                    if (p.type.includes('|')) {
                        for (const v of p.type.split('|')) {
                            const trimmed = v.trim().replace(/^["']|["']$/g, '');
                            if (trimmed && !trimmed.includes(' ')) enumValues.add(trimmed);
                        }
                    }
                }
            }
        }
    }

    // Process tokens — only emit for Lurek-specific cases
    for (let i = 0; i < tokens.length; i++) {
        const tok = tokens[i];

        if (tok.type === TokenType.String) {
            // Enum member string: "fill", "alpha", "nearest", etc.
            const content = extractStringContent(tok.value);
            if (content && enumValues.has(content)) {
                pushToken(builder, tok, 'enumMember', []);
            }
            // All other strings: left to sumneko.lua
            continue;
        }

        if (tok.type !== TokenType.Identifier) continue;

        const name = tok.value;
        const prevCode = findPrevNonWhitespace(tokens, i);
        const nextCode = findNextNonWhitespace(tokens, i);

        // `lurek` as namespace token
        if (name === 'lurek') {
            pushToken(builder, tok, 'namespace', []);
            continue;
        }

        // Tokens after `.` or `:` within a `lurek.*` chain
        if (prevCode?.value === '.' || prevCode?.value === ':') {
            const chain = getIdentifierChain(tokens, i);

            if (chain.startsWith('lurek.')) {
                const afterLurek = chain.slice(6); // e.g. "graphics", "graphics.draw", "init"
                const parts = afterLurek.split('.');

                // lurek.init, lurek.draw, etc. → lifecycle callback
                if (parts.length === 1 && LUREK_CALLBACK_NAMES.has(name)) {
                    pushToken(builder, tok, 'lurekCallback', []);
                    continue;
                }

                // lurek.graphics, lurek.physics, etc. → sub-namespace
                if (parts.length === 1 && apiData.getModule(name)) {
                    pushToken(builder, tok, 'namespace', []);
                    continue;
                }

                // lurek API function call (lurek.module.funcName or lurek.funcName)
                if (lurekFuncNames.has(name)) {
                    const mods: string[] = ['defaultLibrary'];
                    if (deprecatedFuncs.has(name)) mods.push('deprecated');
                    pushToken(builder, tok, 'function', mods);
                    continue;
                }
            }
        }
        // All other identifiers (variables, parameters, stdlib calls, etc.) left to sumneko.lua
    }

    const result = builder.build();
    cache.set(key, { version: document.version, tokens: result });
    return result;
}

// ── Helpers ──────────────────────────────────────────────────

function extractStringContent(raw: string): string {
    if ((raw.startsWith('"') && raw.endsWith('"')) || (raw.startsWith("'") && raw.endsWith("'"))) {
        return raw.slice(1, -1);
    }
    return '';
}

function pushToken(
    builder: vscode.SemanticTokensBuilder,
    tok: Token,
    tokenType: string,
    modifiers: string[],
): void {
    const lines = tok.value.split('\n');
    const firstLineLen = lines[0].length;
    if (firstLineLen === 0) return;

    const typeIdx = tokenTypes.indexOf(tokenType);
    if (typeIdx < 0) return;

    let modBits = 0;
    for (const mod of modifiers) {
        const modIdx = tokenModifiers.indexOf(mod);
        if (modIdx >= 0) modBits |= 1 << modIdx;
    }

    builder.push(tok.line, tok.column, firstLineLen, typeIdx, modBits);
}

function findPrevNonWhitespace(tokens: Token[], idx: number): Token | undefined {
    for (let i = idx - 1; i >= 0; i--) {
        if (tokens[i].type !== TokenType.Whitespace) return tokens[i];
    }
    return undefined;
}

function findNextNonWhitespace(tokens: Token[], idx: number): Token | undefined {
    for (let i = idx + 1; i < tokens.length; i++) {
        if (tokens[i].type !== TokenType.Whitespace) return tokens[i];
    }
    return undefined;
}

function getIdentifierChain(tokens: Token[], idx: number): string {
    let chain = tokens[idx].value;
    let i = idx - 1;

    while (i >= 0) {
        if (tokens[i].type === TokenType.Whitespace) { i--; continue; }
        if (tokens[i].type === TokenType.Punctuation && (tokens[i].value === '.' || tokens[i].value === ':')) {
            i--;
            while (i >= 0 && tokens[i].type === TokenType.Whitespace) i--;
            if (i >= 0 && tokens[i].type === TokenType.Identifier) {
                chain = tokens[i].value + '.' + chain;
                i--;
                continue;
            }
        }
        break;
    }

    return chain;
}

