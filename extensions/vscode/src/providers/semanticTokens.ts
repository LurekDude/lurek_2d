import * as vscode from 'vscode';
import { ApiDataService } from '../services/apiData.js';
import { LuaDocumentAnalyzer, TokenType, Token } from '../services/luaParser.js';

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: 'file', language: 'lua' };
const analyzer = new LuaDocumentAnalyzer();

// ── Token legend ─────────────────────────────────────────────

const tokenTypes = [
    'namespace',    // 0  lurek, lurek.graphics, lurek.physics
    'function',     // 1  function definitions and calls
    'method',       // 2  obj:method calls
    'parameter',    // 3  function parameters
    'variable',     // 4  local variables
    'property',     // 5  table properties
    'keyword',      // 6  Lua keywords
    'string',       // 7  string literals
    'number',       // 8  numeric literals
    'comment',      // 9  comments
    'operator',     // 10 operators
    'type',         // 11 type annotations in comments
    'enumMember',   // 12 enum string values
    'macro',        // 13 LuaJIT FFI
    'decorator',    // 14 LuaCATS annotations
    'event',        // 15 lurek.* callbacks
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

const LUREK_CALLBACKS = new Set([
    'load', 'update', 'draw', 'keypressed', 'keyreleased', 'textinput',
    'mousepressed', 'mousereleased', 'wheelmoved',
    'gamepadpressed', 'gamepadreleased', 'gamepadaxis',
    'joystickadded', 'joystickremoved',
    'touchpressed', 'touchmoved', 'touchreleased',
    'focus', 'visible', 'resize', 'quit',
]);

// Cached results per document version
const cache = new Map<string, { version: number; tokens: vscode.SemanticTokens }>();

/**
 * Registers the semantic tokens provider for Lua files.
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
    const info = analyzer.analyze(text);
    const builder = new vscode.SemanticTokensBuilder(legend);

    // Build lookup sets for efficient classification
    const paramNames = new Set(info.symbols.filter(s => s.kind === 'parameter').map(s => s.name));
    const localNames = new Set(info.symbols.filter(s => s.kind === 'local').map(s => s.name));
    const localFuncNames = new Set(info.symbols.filter(s => s.kind === 'function' && s.isLocal).map(s => s.name));
    const declaredLines = new Map<string, number>();
    for (const sym of info.symbols) {
        if ((sym.kind === 'local' || sym.kind === 'parameter') && !declaredLines.has(sym.name)) {
            declaredLines.set(sym.name, sym.line);
        }
    }

    // Collect known lurek API function names
    const lurekFuncNames = new Set(apiData.getAllFunctions().map(f => f.name));
    const deprecatedFuncs = new Set(apiData.getAllFunctions().filter(f => f.deprecated).map(f => f.name));

    // Collect enum values
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

    // Process tokens in order
    for (let i = 0; i < tokens.length; i++) {
        const tok = tokens[i];
        const prev = i > 0 ? tokens[i - 1] : undefined;
        const prevCode = findPrevNonWhitespace(tokens, i);
        const nextCode = findNextNonWhitespace(tokens, i);

        switch (tok.type) {
            case TokenType.Keyword:
                pushToken(builder, tok, 'keyword', []);
                break;

            case TokenType.Comment:
                classifyComment(builder, tok);
                break;

            case TokenType.String:
                classifyString(builder, tok, enumValues);
                break;

            case TokenType.Number:
                pushToken(builder, tok, 'number', []);
                break;

            case TokenType.Operator:
                pushToken(builder, tok, 'operator', []);
                break;

            case TokenType.Identifier:
                classifyIdentifier(
                    builder, tok, prevCode, nextCode, tokens, i,
                    paramNames, localNames, localFuncNames, declaredLines,
                    lurekFuncNames, deprecatedFuncs, apiData,
                );
                break;
        }
    }

    const result = builder.build();
    cache.set(key, { version: document.version, tokens: result });
    return result;
}

// ── Identifier classification ────────────────────────────────

function classifyIdentifier(
    builder: vscode.SemanticTokensBuilder,
    tok: Token,
    prevCode: Token | undefined,
    nextCode: Token | undefined,
    allTokens: Token[],
    idx: number,
    paramNames: Set<string>,
    localNames: Set<string>,
    localFuncNames: Set<string>,
    declaredLines: Map<string, number>,
    lurekFuncNames: Set<string>,
    deprecatedFuncs: Set<string>,
    apiData: ApiDataService,
): void {
    const name = tok.value;

    // `lurek` as namespace
    if (name === 'lurek') {
        // Check if next is `.callbackName` → event
        if (nextCode?.value === '.') {
            const afterDot = findNextNonWhitespaceAfter(allTokens, idx, 2);
            if (afterDot?.type === TokenType.Identifier && LUREK_CALLBACKS.has(afterDot.value)) {
                pushToken(builder, tok, 'namespace', []);
                return;
            }
        }
        pushToken(builder, tok, 'namespace', []);
        return;
    }

    // Property after `lurek.` — could be module namespace, callback (event), or API function
    if (prevCode?.value === '.' || prevCode?.value === ':') {
        // Walk back to find the root
        const chain = getIdentifierChain(allTokens, idx);

        if (chain.startsWith('lurek.')) {
            const afterLurek = chain.slice(5);
            const parts = afterLurek.split('.');

            // lurek.graphics, lurek.physics etc → submodule names = namespace
            if (apiData.getModule(parts[0])) {
                if (parts.length === 1 && nextCode?.value !== '(') {
                    pushToken(builder, tok, 'namespace', []);
                    return;
                }
            }

            // lurek.update, lurek.draw etc → callback event
            if (parts.length === 1 && LUREK_CALLBACKS.has(name)) {
                pushToken(builder, tok, 'event', []);
                return;
            }

            // lurek API function call
            if (lurekFuncNames.has(name)) {
                const mods: string[] = ['defaultLibrary'];
                if (deprecatedFuncs.has(name)) mods.push('deprecated');
                pushToken(builder, tok, 'function', mods);
                return;
            }
        }

        // obj:method()
        if (prevCode?.value === ':') {
            pushToken(builder, tok, 'method', []);
            return;
        }

        // table.property
        pushToken(builder, tok, 'property', []);
        return;
    }

    // Function definition: `function name` or `local function name`
    if (prevCode?.type === TokenType.Keyword && prevCode.value === 'function') {
        pushToken(builder, tok, 'function', ['definition']);
        return;
    }

    // Function call: `name(`
    if (nextCode?.value === '(') {
        if (localFuncNames.has(name)) {
            pushToken(builder, tok, 'function', []);
        } else if (lurekFuncNames.has(name)) {
            const mods: string[] = ['defaultLibrary'];
            if (deprecatedFuncs.has(name)) mods.push('deprecated');
            pushToken(builder, tok, 'function', mods);
        } else {
            pushToken(builder, tok, 'function', []);
        }
        return;
    }

    // Parameter
    if (paramNames.has(name)) {
        const isDecl = declaredLines.get(name) === tok.line;
        pushToken(builder, tok, 'parameter', isDecl ? ['declaration'] : []);
        return;
    }

    // Local variable
    if (localNames.has(name)) {
        const isDecl = declaredLines.get(name) === tok.line;
        pushToken(builder, tok, 'variable', isDecl ? ['declaration'] : []);
        return;
    }

    // Fallback: global variable
    pushToken(builder, tok, 'variable', []);
}

// ── Comment classification ───────────────────────────────────

function classifyComment(builder: vscode.SemanticTokensBuilder, tok: Token): void {
    const value = tok.value;

    // LuaCATS annotations: ---@param, ---@return, etc.
    if (/^---@\w+/.test(value)) {
        // Push the whole token as decorator
        pushToken(builder, tok, 'decorator', ['documentation']);
        return;
    }

    pushToken(builder, tok, 'comment', []);
}

// ── String classification ────────────────────────────────────

function classifyString(builder: vscode.SemanticTokensBuilder, tok: Token, enumValues: Set<string>): void {
    // Check if the string content (without quotes) is a known enum value
    const content = extractStringContent(tok.value);
    if (content && enumValues.has(content)) {
        pushToken(builder, tok, 'enumMember', []);
        return;
    }

    pushToken(builder, tok, 'string', []);
}

function extractStringContent(raw: string): string {
    if ((raw.startsWith('"') && raw.endsWith('"')) || (raw.startsWith("'") && raw.endsWith("'"))) {
        return raw.slice(1, -1);
    }
    return '';
}

// ── Token builder helpers ────────────────────────────────────

function pushToken(
    builder: vscode.SemanticTokensBuilder,
    tok: Token,
    tokenType: string,
    modifiers: string[],
): void {
    // SemanticTokensBuilder expects single-line tokens.
    // For multiline tokens (comments, strings), push only the first line.
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

// ── Token navigation helpers ─────────────────────────────────

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

function findNextNonWhitespaceAfter(tokens: Token[], idx: number, skip: number): Token | undefined {
    let found = 0;
    for (let i = idx + 1; i < tokens.length; i++) {
        if (tokens[i].type !== TokenType.Whitespace) {
            found++;
            if (found >= skip) return tokens[i];
        }
    }
    return undefined;
}

/**
 * Walk backwards from the given index to build a dotted identifier chain
 * like "lurek.graphics.draw".
 */
function getIdentifierChain(tokens: Token[], idx: number): string {
    let chain = tokens[idx].value;
    let i = idx - 1;

    while (i >= 0) {
        // Skip whitespace
        if (tokens[i].type === TokenType.Whitespace) { i--; continue; }
        // Expect `.` or `:`
        if (tokens[i].type === TokenType.Punctuation && (tokens[i].value === '.' || tokens[i].value === ':')) {
            const sep = tokens[i].value;
            i--;
            // Skip whitespace
            while (i >= 0 && tokens[i].type === TokenType.Whitespace) i--;
            if (i >= 0 && tokens[i].type === TokenType.Identifier) {
                chain = tokens[i].value + sep + chain;
                i--;
                continue;
            }
        }
        break;
    }

    return chain;
}
