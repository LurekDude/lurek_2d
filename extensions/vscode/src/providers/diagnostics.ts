import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';
import { ApiDataService } from '../services/apiData.js';
import { LuaDocumentAnalyzer } from '../services/luaParser.js';
import { LUREK_CALLBACK_NAMES } from '../generated/lurekApiData.js';

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
    const docVersions = new Map<string, number>();

    const diagnose = (document: vscode.TextDocument): void => {
        if (document.languageId !== 'lua') return;

        // Track document version to avoid stale diagnostics
        const key = document.uri.toString();
        const currentVersion = document.version;
        docVersions.set(key, currentVersion);

        try {
            // Re-check version after async gap — skip if document changed again
            if (docVersions.get(key) !== currentVersion) return;

            const text = document.getText();
            const info = analyzer.analyze(text);
            const diagnostics: vscode.Diagnostic[] = [];

            diagnostics.push(...checkDeprecated(text, apiData));
            diagnostics.push(...checkColorRange(text));
            checkAssetNotFound(text, document, diagnostics);
            diagnostics.push(...checkThreadRandom(text, info));
            diagnostics.push(...checkMissingCallback(text, document, info));
            diagnostics.push(...checkWrongEnumValue(text, apiData));
            checkConfLua(text, document, diagnostics);
            const relPath = vscode.workspace.asRelativePath(document.uri.fsPath, false);
            if (!relPath.startsWith('content/examples/') && !relPath.startsWith('content\\examples\\')) {
                diagnostics.push(...checkPerFrameAllocation(text, info, apiData));
            }
            diagnostics.push(...checkMissingTestSummary(text, document));
            diagnostics.push(...checkEntityNilAccess(text));

            collection.set(document.uri, diagnostics);
        } catch {
            // Never throw from diagnostics — silently degrade
        }
    };

    const debouncedDiagnose = (document: vscode.TextDocument): void => {
        const key = document.uri.toString();
        const version = document.version;
        docVersions.set(key, version);
        const existing = debounceTimers.get(key);
        if (existing) clearTimeout(existing);
        debounceTimers.set(key, setTimeout(() => {
            debounceTimers.delete(key);
            // Only diagnose if version hasn't changed during debounce wait
            if (docVersions.get(key) === version) {
                diagnose(document);
            }
        }, 800));
    };

    context.subscriptions.push(
        // NOTE: Do NOT use onDidOpenTextDocument here.
        // Many internal providers (symbols, references, requireGraph) open documents
        // programmatically via openTextDocument() — that fires onDidOpenTextDocument for
        // every file they scan, causing diagnostics to run on 200+ files per query.
        // Instead, only run diagnostics on documents visible in the editor.
        vscode.window.onDidChangeVisibleTextEditors((editors) => {
            for (const editor of editors) {
                diagnose(editor.document);
            }
        }),
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

    // Diagnose documents already visible in editors on activation
    for (const editor of vscode.window.visibleTextEditors) {
        diagnose(editor.document);
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
        const line = lines[i].split('--', 1)[0];
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

// ── Rule 4: lurek.assetNotFound ────────────────────────────────

function checkAssetNotFound(
    text: string,
    document: vscode.TextDocument,
    diagnostics: vscode.Diagnostic[],
): void {
    if (!vscode.workspace.workspaceFolders?.length) return;

    // Example files use placeholder asset paths — skip asset-existence check.
    const relPath = vscode.workspace.asRelativePath(document.uri.fsPath, false);
    if (relPath.startsWith('content/examples/') || relPath.startsWith('content\\examples\\')) return;

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

    // Determine actual callback names from API data
    const processName = LUREK_CALLBACK_NAMES.has('process') ? 'process' : 'update';
    const drawName = 'draw';

    const hasProcess = info.callbacks.some(cb => cb.name === processName)
        || new RegExp(`lurek\\.${processName}\\s*=\\s*function`).test(text);
    const hasDraw = info.callbacks.some(cb => cb.name === drawName)
        || /lurek\.draw\s*=\s*function/.test(text);

    if (!hasProcess && !hasDraw) {
        const lines = text.split('\n');
        const range = new vscode.Range(0, 0, 0, lines[0]?.length ?? 0);
        const diag = new vscode.Diagnostic(
            range,
            `main.lua should define lurek.${processName}(dt) and/or lurek.${drawName}()`,
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
    apiData: ApiDataService,
): vscode.Diagnostic[] {
    const diagnostics: vscode.Diagnostic[] = [];
    const lines = text.split('\n');
    const allocPattern = /lurek\.(?:render\.(?:newImage|newFont|newCanvas|newShader)|audio\.(?:newSource)|image\.load)\s*\(/g;
    // Per-frame callbacks: all callbacks that run every frame (have dt or are draw callbacks)
    const frameCallbacks = apiData.getCallbacks()
        .map(cb => cb.name)
        .filter(n => ['process', 'process_late', 'process_physics', 'fixedUpdate', 'draw', 'draw_ui'].includes(n));
    // Fallback if apiData not yet loaded
    if (frameCallbacks.length === 0) frameCallbacks.push('process', 'process_late', 'process_physics', 'draw', 'draw_ui');

    function enclosingLurekCallback(lineIndex: number): string | undefined {
        for (let j = lineIndex; j >= 0; j--) {
            const callbackMatch = lines[j].match(/function\s+lurek\.([A-Za-z_][\w]*)\s*\(/)
                || lines[j].match(/lurek\.([A-Za-z_][\w]*)\s*=\s*function\s*\(/);
            if (callbackMatch) return callbackMatch[1];
        }
        return undefined;
    }

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (line.trimStart().startsWith('--')) continue;

        allocPattern.lastIndex = 0;
        let m: RegExpExecArray | null;
        while ((m = allocPattern.exec(line)) !== null) {
            const callbackName = enclosingLurekCallback(i);
            if (!callbackName || !frameCallbacks.includes(callbackName)) continue;

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

