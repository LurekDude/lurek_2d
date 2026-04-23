import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';
import { ApiDataService } from '../services/apiData.js';
import { LuaDocumentAnalyzer } from '../services/luaParser.js';

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: 'file', language: 'lua' };
const analyzer = new LuaDocumentAnalyzer();

/**
 * Registers the Lua diagnostics provider.
 * Runs 13 diagnostic rules on document open, save, and change (debounced).
 */
export function register(context: vscode.ExtensionContext, apiData: ApiDataService): void {
    const collection = vscode.languages.createDiagnosticCollection('lurek');
    context.subscriptions.push(collection);

    const debounceTimers = new Map<string, ReturnType<typeof setTimeout>>();

    const diagnose = (document: vscode.TextDocument): void => {
        if (document.languageId !== 'lua') return;

        try {
            const text = document.getText();
            const info = analyzer.analyze(text);
            const diagnostics: vscode.Diagnostic[] = [];

            diagnostics.push(...checkDeprecated(text, apiData));
            diagnostics.push(...checkColorRange(text));
            diagnostics.push(...checkUnusedRequire(text, info));
            checkAssetNotFound(text, document, diagnostics);
            diagnostics.push(...checkThreadRandom(text, info));
            diagnostics.push(...checkMissingCallback(text, document, info));
            diagnostics.push(...checkWrongEnumValue(text, apiData));
            diagnostics.push(...checkUnknownLurekFunc(text, apiData));
            checkConfLua(text, document, diagnostics);
            diagnostics.push(...checkPerFrameAllocation(text, info));
            diagnostics.push(...checkMissingTestSummary(text, document));
            diagnostics.push(...checkEntityNilAccess(text));
            diagnostics.push(...checkMethodColonDot(text));

            collection.set(document.uri, diagnostics);
        } catch {
            // Never throw from diagnostics — silently degrade
        }
    };

    const debouncedDiagnose = (document: vscode.TextDocument): void => {
        const key = document.uri.toString();
        const existing = debounceTimers.get(key);
        if (existing) clearTimeout(existing);
        debounceTimers.set(key, setTimeout(() => {
            debounceTimers.delete(key);
            diagnose(document);
        }, 300));
    };

    context.subscriptions.push(
        vscode.workspace.onDidOpenTextDocument(diagnose),
        vscode.workspace.onDidSaveTextDocument(diagnose),
        vscode.workspace.onDidChangeTextDocument((e) => debouncedDiagnose(e.document)),
        vscode.workspace.onDidCloseTextDocument((doc) => {
            collection.delete(doc.uri);
            const key = doc.uri.toString();
            const timer = debounceTimers.get(key);
            if (timer) {
                clearTimeout(timer);
                debounceTimers.delete(key);
            }
        }),
    );

    // Diagnose already-open documents
    for (const doc of vscode.workspace.textDocuments) {
        diagnose(doc);
    }
}

// ── Rule 1: lurek.deprecated ──────────────────────────────────

function checkDeprecated(text: string, apiData: ApiDataService): vscode.Diagnostic[] {
    const diagnostics: vscode.Diagnostic[] = [];
    const deprecatedFns = apiData.getAllFunctions().filter(f => f.deprecated);
    if (deprecatedFns.length === 0) return diagnostics;

    const lines = text.split('\n');

    for (const fn of deprecatedFns) {
        const escaped = fn.fullPath.replace(/\./g, '\\.');
        const regex = new RegExp(escaped, 'g');

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (line.trimStart().startsWith('--')) continue;

            let match: RegExpExecArray | null;
            while ((match = regex.exec(line)) !== null) {
                const range = new vscode.Range(i, match.index, i, match.index + fn.fullPath.length);
                const diag = new vscode.Diagnostic(
                    range,
                    `${fn.fullPath} is deprecated. ${fn.deprecated}`,
                    vscode.DiagnosticSeverity.Warning,
                );
                diag.code = 'lurek.deprecated';
                diag.source = 'Lurek2D Toolkit';
                diag.tags = [vscode.DiagnosticTag.Deprecated];
                diagnostics.push(diag);
            }
        }
    }

    return diagnostics;
}

// ── Rule 2: lurek.colorRange ──────────────────────────────────

function checkColorRange(text: string): vscode.Diagnostic[] {
    const diagnostics: vscode.Diagnostic[] = [];
    const lines = text.split('\n');

    // lurek.render.* is the current API namespace (lurek.graphics.* was the old name)
    const colorFuncPattern =
        /lurek\.render\.(?:setColor|setBackgroundColor|clear)\s*\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)/g;

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (line.trimStart().startsWith('--')) continue;

        let match: RegExpExecArray | null;
        while ((match = colorFuncPattern.exec(line)) !== null) {
            const vals = [parseFloat(match[1]), parseFloat(match[2]), parseFloat(match[3])];
            if (match[4] !== undefined) vals.push(parseFloat(match[4]));

            const hasLargeValue = vals.some(v => v > 1.0);
            if (!hasLargeValue) continue;

            const converted = vals.slice(0, 3).map(v => (v / 255).toFixed(2));
            const range = new vscode.Range(i, match.index, i, match.index + match[0].length);
            const diag = new vscode.Diagnostic(
                range,
                `Color values should be in 0-1 range. Did you mean ${converted.join(', ')}?`,
                vscode.DiagnosticSeverity.Warning,
            );
            diag.code = 'lurek.colorRange';
            diag.source = 'Lurek2D Toolkit';
            diagnostics.push(diag);
        }
    }

    return diagnostics;
}

// ── Rule 3: lurek.unusedRequire ────────────────────────────────

function checkUnusedRequire(
    text: string,
    info: ReturnType<typeof analyzer.analyze>,
): vscode.Diagnostic[] {
    const diagnostics: vscode.Diagnostic[] = [];

    for (const req of info.requires) {
        const varName = req.localName;
        const refs = analyzer.findReferencesInDocument(text, varName);
        // One reference is the declaration itself
        if (refs.length <= 1) {
            const lines = text.split('\n');
            const lineIdx = req.line;
            const lineText = lines[lineIdx] ?? '';
            const range = new vscode.Range(lineIdx, 0, lineIdx, lineText.length);
            const diag = new vscode.Diagnostic(
                range,
                `Required module '${varName}' is never used`,
                vscode.DiagnosticSeverity.Hint,
            );
            diag.code = 'lurek.unusedRequire';
            diag.source = 'Lurek2D Toolkit';
            diag.tags = [vscode.DiagnosticTag.Unnecessary];
            diagnostics.push(diag);
        }
    }

    return diagnostics;
}

// ── Rule 4: lurek.assetNotFound ────────────────────────────────

function checkAssetNotFound(
    text: string,
    document: vscode.TextDocument,
    diagnostics: vscode.Diagnostic[],
): void {
    if (!vscode.workspace.workspaceFolders?.length) return;

    const lines = text.split('\n');
    const assetFuncPattern =
        /lurek\.(?:render\.newImage|audio\.newSource|fs\.read)\s*\(\s*["']([^"']+)["']/g;

    const docDir = path.dirname(document.uri.fsPath);
    const wsRoot = vscode.workspace.workspaceFolders[0].uri.fsPath;

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (line.trimStart().startsWith('--')) continue;

        let match: RegExpExecArray | null;
        while ((match = assetFuncPattern.exec(line)) !== null) {
            const assetPath = match[1];
            // Skip URLs and extension-less paths (likely module names)
            if (assetPath.includes('://') || !assetPath.includes('.')) continue;

            const candidates = [
                path.resolve(docDir, assetPath),
                path.resolve(wsRoot, assetPath),
            ];

            const exists = candidates.some(c => {
                try {
                    return fs.existsSync(c);
                } catch {
                    return false;
                }
            });

            if (!exists) {
                const strStart = line.indexOf(assetPath, match.index);
                const range = new vscode.Range(i, strStart, i, strStart + assetPath.length);
                const diag = new vscode.Diagnostic(
                    range,
                    `Asset file '${assetPath}' not found in workspace`,
                    vscode.DiagnosticSeverity.Warning,
                );
                diag.code = 'lurek.assetNotFound';
                diag.source = 'Lurek2D Toolkit';
                diagnostics.push(diag);
            }
        }
    }
}

// ── Rule 5: lurek.threadRandom ────────────────────────────────

function checkThreadRandom(
    text: string,
    info: ReturnType<typeof analyzer.analyze>,
): vscode.Diagnostic[] {
    const diagnostics: vscode.Diagnostic[] = [];
    if (!text.includes('lurek.thread')) return diagnostics;

    const lines = text.split('\n');
    const randomPattern = /\bmath\.random\s*\(/g;

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (line.trimStart().startsWith('--')) continue;

        let match: RegExpExecArray | null;
        while ((match = randomPattern.exec(line)) !== null) {
            const scope = analyzer.getScopeAt(info, i);
            if (!scope) continue;

            // Heuristic: check if surrounding scope contains thread-related code
            const scopeLines = lines.slice(scope.startLine, scope.endLine + 1).join('\n');
            if (!scopeLines.includes('lurek.thread')) continue;

            const range = new vscode.Range(i, match.index, i, match.index + 'math.random'.length);
            const diag = new vscode.Diagnostic(
                range,
                'math.random in threads may produce identical sequences. Consider seeding with thread ID.',
                vscode.DiagnosticSeverity.Information,
            );
            diag.code = 'lurek.threadRandom';
            diag.source = 'Lurek2D Toolkit';
            diagnostics.push(diag);
        }
    }

    return diagnostics;
}

// ── Rule 6: lurek.missingCallback ─────────────────────────────

function checkMissingCallback(
    text: string,
    document: vscode.TextDocument,
    info: ReturnType<typeof analyzer.analyze>,
): vscode.Diagnostic[] {
    const diagnostics: vscode.Diagnostic[] = [];
    const fileName = path.basename(document.uri.fsPath);

    // Only for files named main.lua that live inside content/games/
    // (not ideas/, work/, .github/ skill examples, or other root main.lua files)
    if (fileName !== 'main.lua') return diagnostics;
    const filePath = document.uri.fsPath.replace(/\\/g, '/');
    if (!filePath.includes('/content/games/')) return diagnostics;

    const hasUpdate = info.callbacks.some(cb => cb.name === 'update')
        || /lurek\.update\s*=\s*function/.test(text);
    const hasDraw = info.callbacks.some(cb => cb.name === 'draw')
        || /lurek\.draw\s*=\s*function/.test(text);

    if (!hasUpdate && !hasDraw) {
        const lines = text.split('\n');
        const range = new vscode.Range(0, 0, 0, lines[0]?.length ?? 0);
        const diag = new vscode.Diagnostic(
            range,
            'main.lua should define lurek.update(dt) and/or lurek.draw()',
            vscode.DiagnosticSeverity.Information,
        );
        diag.code = 'lurek.missingCallback';
        diag.source = 'Lurek2D Toolkit';
        diagnostics.push(diag);
    }

    return diagnostics;
}

// ── D2: Wrong enum value with "Did you mean?" ─────────────────

// Known enum sets per function/param pattern
const ENUM_RULES: { pattern: RegExp; valid: string[]; label: string }[] = [
    {
        // lurek.render.* is the current draw API namespace
        pattern: /lurek\.render\.(?:rectangle|circle|arc|polygon|ellipse)\s*\(\s*["']([^"']+)["']/g,
        valid: ['fill', 'line'],
        label: 'draw mode',
    },
    {
        pattern: /lurek\.render\.setBlendMode\s*\(\s*["']([^"']+)["']/g,
        valid: ['alpha', 'add', 'subtract', 'multiply', 'replace', 'screen', 'darken', 'lighten', 'none'],
        label: 'blend mode',
    },
    {
        pattern: /lurek\.render\.setLineStyle\s*\(\s*["']([^"']+)["']/g,
        valid: ['smooth', 'rough'],
        label: 'line style',
    },
    {
        pattern: /lurek\.render\.setFilter\s*\([^,]*,\s*["']([^"']+)["']/g,
        valid: ['linear', 'nearest'],
        label: 'texture filter',
    },
    {
        pattern: /lurek\.render\.setFilter\s*\(\s*["']([^"']+)["']/g,
        valid: ['linear', 'nearest'],
        label: 'texture filter',
    },
    {
        pattern: /lurek\.audio\.newSource\s*\([^,]*,\s*["']([^"']+)["']/g,
        valid: ['static', 'stream'],
        label: 'audio source type',
    },
    {
        pattern: /lurek\.physics\.newBody\s*\([^,]*,[^,]*,[^,]*,\s*["']([^"']+)["']/g,
        valid: ['dynamic', 'static', 'kinematic'],
        label: 'body type',
    },
    {
        pattern: /lurek\.render\.printf\s*\([^)]*,[^)]*,[^)]*,[^)]*,\s*["']([^"']+)["']/g,
        valid: ['left', 'center', 'right', 'justify'],
        label: 'text alignment',
    },
];

function fuzzyMatch(word: string, candidates: string[]): string | undefined {
    // Simple edit-distance-1 check
    for (const c of candidates) {
        if (c === word) return undefined; // exact match — no error
        if (Math.abs(c.length - word.length) <= 2) {
            let diff = 0;
            const len = Math.max(c.length, word.length);
            for (let i = 0; i < len; i++) {
                if ((c[i] ?? '') !== (word[i] ?? '')) diff++;
            }
            if (diff <= 2) return c;
        }
    }
    return undefined;
}

function checkWrongEnumValue(text: string, _apiData: ApiDataService): vscode.Diagnostic[] {
    const diagnostics: vscode.Diagnostic[] = [];
    const lines = text.split('\n');

    for (const rule of ENUM_RULES) {
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (line.trimStart().startsWith('--')) continue;
            rule.pattern.lastIndex = 0;
            let m: RegExpExecArray | null;
            while ((m = rule.pattern.exec(line)) !== null) {
                const value = m[1];
                if (rule.valid.includes(value)) continue;
                const suggestion = fuzzyMatch(value, rule.valid);
                const valueStart = line.indexOf(`"${value}"`, m.index) !== -1
                    ? line.indexOf(`"${value}"`, m.index) + 1
                    : line.indexOf(`'${value}'`, m.index) + 1;
                const range = new vscode.Range(i, valueStart, i, valueStart + value.length);
                const msg = suggestion
                    ? `Unknown ${rule.label} "${value}". Did you mean "${suggestion}"? Valid: ${rule.valid.join(', ')}`
                    : `Unknown ${rule.label} "${value}". Valid values: ${rule.valid.join(', ')}`;
                const diag = new vscode.Diagnostic(range, msg, vscode.DiagnosticSeverity.Warning);
                diag.code = 'lurek.wrongEnumValue';
                diag.source = 'Lurek2D Toolkit';
                diagnostics.push(diag);
            }
        }
    }

    return diagnostics;
}

// ── D6: Unknown lurek.module.function call ─────────────────────

function checkUnknownLurekFunc(text: string, apiData: ApiDataService): vscode.Diagnostic[] {
    const diagnostics: vscode.Diagnostic[] = [];
    const lines = text.split('\n');
    const callPattern = /lurek\.(\w+)\.(\w+)\s*\(/g;

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (line.trimStart().startsWith('--')) continue;
        callPattern.lastIndex = 0;
        let m: RegExpExecArray | null;
        while ((m = callPattern.exec(line)) !== null) {
            const modName = m[1];
            const funcName = m[2];
            const fullPath = `lurek.${modName}.${funcName}`;
            const mod = apiData.getModule(modName);
            if (!mod) continue; // unknown module — skip (not our concern)
            const knownFn = apiData.getFunction(fullPath);
            if (knownFn) continue; // known function
            // Also check methods (e.g. for known types)
            const methodFn = apiData.getFunctions(modName).find(f => f.name === funcName);
            if (methodFn) continue;

            const col = m.index + `lurek.${modName}.`.length;
            const range = new vscode.Range(i, col, i, col + funcName.length);
            const diag = new vscode.Diagnostic(
                range,
                `"${funcName}" is not a known function in lurek.${modName}`,
                vscode.DiagnosticSeverity.Warning,
            );
            diag.code = 'lurek.unknownFunction';
            diag.source = 'Lurek2D Toolkit';
            diagnostics.push(diag);
        }
    }

    return diagnostics;
}

// ── D5: conf.lua validation ───────────────────────────────────

const VALID_CONF_KEYS: Record<string, string[]> = {
    window: ['title', 'width', 'height', 'vsync', 'fullscreen', 'resizable',
             'highdpi', 'minwidth', 'minheight', 'x', 'y', 'borderless',
             'displayindex', 'icon'],
    performance: ['target_fps', 'fixed_dt'],
    modules: ['physics', 'audio', 'graphics', 'input', 'timer', 'filesystem',
              'math', 'thread'],
    log: ['file', 'append', 'level'],
};

function checkConfLua(
    text: string,
    document: vscode.TextDocument,
    diagnostics: vscode.Diagnostic[],
): void {
    if (path.basename(document.uri.fsPath) !== 'conf.lua') return;

    const lines = text.split('\n');
    const keyPattern = /\bt\.(\w+)\.(\w+)\s*=/g;

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (line.trimStart().startsWith('--')) continue;
        keyPattern.lastIndex = 0;
        let m: RegExpExecArray | null;
        while ((m = keyPattern.exec(line)) !== null) {
            const section = m[1];
            const key = m[2];
            const validKeys = VALID_CONF_KEYS[section];
            if (!validKeys) continue; // unknown section — skip
            if (validKeys.includes(key)) continue;

            const col = m.index + `t.${section}.`.length;
            const range = new vscode.Range(i, col, i, col + key.length);
            const diag = new vscode.Diagnostic(
                range,
                `"${key}" is not a recognised conf.lua key in t.${section}. Valid: ${validKeys.join(', ')}`,
                vscode.DiagnosticSeverity.Warning,
            );
            diag.code = 'lurek.confKey';
            diag.source = 'Lurek2D Toolkit';
            diagnostics.push(diag);
        }
    }
}

// ── Rule 10: Per-frame allocation detection ───────────────────

/**
 * Warns about common per-frame allocation pitfalls: calling factory functions
 * like newImage, newSource, newFont inside callbacks that run every frame
 * (lurek.update, lurek.draw, lurek.render, lurek.render_ui).
 */
function checkPerFrameAllocation(
    text: string,
    info: ReturnType<typeof analyzer.analyze>,
): vscode.Diagnostic[] {
    const diagnostics: vscode.Diagnostic[] = [];
    const lines = text.split('\n');
    const allocPattern = /lurek\.(?:render\.(?:newImage|newFont|newCanvas|newShader)|audio\.(?:newSource)|image\.load)\s*\(/g;
    const frameCallbacks = ['update', 'draw', 'render', 'render_ui', 'process', 'process_late', 'process_physics'];

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (line.trimStart().startsWith('--')) continue;

        allocPattern.lastIndex = 0;
        let m: RegExpExecArray | null;
        while ((m = allocPattern.exec(line)) !== null) {
            // Check if this line is inside a per-frame callback scope
            const scope = analyzer.getScopeAt(info, i);
            if (!scope) continue;

            const isPerFrame = frameCallbacks.some(cb => {
                const scopeText = lines.slice(scope.startLine, Math.min(scope.startLine + 3, lines.length)).join('\n');
                return scopeText.includes(`lurek.${cb}`) || scopeText.includes(`function ${cb}`);
            });

            if (!isPerFrame) continue;

            const funcName = m[0].replace(/\s*\($/, '');
            const range = new vscode.Range(i, m.index, i, m.index + funcName.length);
            const diag = new vscode.Diagnostic(
                range,
                `${funcName} called inside a per-frame callback. This allocates every frame — move to lurek.init() or lurek.ready().`,
                vscode.DiagnosticSeverity.Warning,
            );
            diag.code = 'lurek.perFrameAlloc';
            diag.source = 'Lurek2D Toolkit';
            diagnostics.push(diag);
        }
    }

    return diagnostics;
}

// ── Rule 11: Missing test_summary() in test files ─────────────

/**
 * Checks if Lua files under tests/lua/ end with a test_summary() call,
 * which is required by the Lurek2D test harness.
 */
function checkMissingTestSummary(
    text: string,
    document: vscode.TextDocument,
): vscode.Diagnostic[] {
    const diagnostics: vscode.Diagnostic[] = [];
    const filePath = document.uri.fsPath.replace(/\\/g, '/');

    // Only applies to test files
    if (!filePath.includes('tests/lua/') && !filePath.includes('tests\\lua\\')) return diagnostics;
    if (!filePath.endsWith('.lua')) return diagnostics;
    // Skip the init.lua harness itself
    if (filePath.endsWith('init.lua')) return diagnostics;

    const hasTestSummary = /\btest_summary\s*\(\s*\)/.test(text);
    if (!hasTestSummary) {
        const lines = text.split('\n');
        const lastLine = lines.length - 1;
        const range = new vscode.Range(lastLine, 0, lastLine, lines[lastLine]?.length ?? 0);
        const diag = new vscode.Diagnostic(
            range,
            'Lua test file is missing test_summary() call at the end. Required by the Lurek2D test harness.',
            vscode.DiagnosticSeverity.Warning,
        );
        diag.code = 'lurek.missingTestSummary';
        diag.source = 'Lurek2D Toolkit';
        diagnostics.push(diag);
    }

    return diagnostics;
}

// ── Rule 12: Entity nil access after find ─────────────────────

/**
 * Warns when a lurek.ecs.find() result is used without nil-checking.
 * entity.find() can return nil, so accessing methods directly is unsafe.
 */
function checkEntityNilAccess(text: string): vscode.Diagnostic[] {
    const diagnostics: vscode.Diagnostic[] = [];
    const lines = text.split('\n');

    // Detect pattern: local X = lurek.ecs.find(...) \n X:method() or X.method without if X then
    const findPattern = /\blocal\s+(\w+)\s*=\s*lurek\.entity\.find\s*\(/g;

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (line.trimStart().startsWith('--')) continue;

        findPattern.lastIndex = 0;
        let m: RegExpExecArray | null;
        while ((m = findPattern.exec(line)) !== null) {
            const varName = m[1];
            // Check next 5 lines for unguarded access
            let hasGuard = false;
            for (let j = i + 1; j < Math.min(i + 6, lines.length); j++) {
                const checkLine = lines[j].trim();
                if (checkLine.startsWith('--')) continue;
                if (checkLine.includes(`if ${varName}`) || checkLine.includes(`if not ${varName}`)) {
                    hasGuard = true;
                    break;
                }
                // Direct method call without guard
                const accessPattern = new RegExp(`\\b${varName}\\s*[:.:]\\s*\\w+`);
                if (accessPattern.test(checkLine) && !hasGuard) {
                    const col = checkLine.indexOf(varName);
                    const range = new vscode.Range(j, col, j, col + varName.length);
                    const diag = new vscode.Diagnostic(
                        range,
                        `'${varName}' from lurek.ecs.find() may be nil. Consider adding: if ${varName} then`,
                        vscode.DiagnosticSeverity.Information,
                    );
                    diag.code = 'lurek.entityNilAccess';
                    diag.source = 'Lurek2D Toolkit';
                    diagnostics.push(diag);
                    break; // Only report once per find()
                }
            }
        }
    }

    return diagnostics;
}

// ── Rule 13: Method call colon vs dot warning ─────────────────

/**
 * Detects common mistake of using dot instead of colon for method calls
 * on known Lurek2D objects. E.g. obj.setFilter(obj, ...) should be obj:setFilter(...)
 */
function checkMethodColonDot(text: string): vscode.Diagnostic[] {
    const diagnostics: vscode.Diagnostic[] = [];
    const lines = text.split('\n');

    // Pattern: var.method(var, ...) — the variable appears as the first arg
    const dotCallPattern = /\b(\w+)\.(\w+)\s*\(\s*\1\s*[,)]/g;

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (line.trimStart().startsWith('--')) continue;

        dotCallPattern.lastIndex = 0;
        let m: RegExpExecArray | null;
        while ((m = dotCallPattern.exec(line)) !== null) {
            const varName = m[1];
            const methodName = m[2];

            // Skip lurek.* namespace calls (that's not a method call, it's a module call)
            if (varName === 'lurek') continue;

            const col = m.index;
            const endCol = col + `${varName}.${methodName}`.length;
            const range = new vscode.Range(i, col, i, endCol);
            const diag = new vscode.Diagnostic(
                range,
                `Consider using colon syntax: ${varName}:${methodName}(...) instead of ${varName}.${methodName}(${varName}, ...)`,
                vscode.DiagnosticSeverity.Information,
            );
            diag.code = 'lurek.colonSyntax';
            diag.source = 'Lurek2D Toolkit';
            diagnostics.push(diag);
        }
    }

    return diagnostics;
}
