import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';
import { ApiDataService } from '../services/apiData.js';
import { LuaDocumentAnalyzer } from '../services/luaParser.js';

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: 'file', language: 'lua' };
const analyzer = new LuaDocumentAnalyzer();

/**
 * Registers the Lua diagnostics provider.
 * Runs 6 diagnostic rules on document open, save, and change (debounced).
 */
export function register(context: vscode.ExtensionContext, apiData: ApiDataService): void {
    const collection = vscode.languages.createDiagnosticCollection('luna');
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
            diagnostics.push(...checkUnknownLunaFunc(text, apiData));
            checkConfLua(text, document, diagnostics);

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

// ── Rule 1: luna.deprecated ──────────────────────────────────

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
                diag.code = 'luna.deprecated';
                diag.source = 'Luna Toolkit';
                diag.tags = [vscode.DiagnosticTag.Deprecated];
                diagnostics.push(diag);
            }
        }
    }

    return diagnostics;
}

// ── Rule 2: luna.colorRange ──────────────────────────────────

function checkColorRange(text: string): vscode.Diagnostic[] {
    const diagnostics: vscode.Diagnostic[] = [];
    const lines = text.split('\n');

    const colorFuncPattern =
        /luna\.graphics\.(?:setColor|setBackgroundColor|clear)\s*\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)/g;

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
            diag.code = 'luna.colorRange';
            diag.source = 'Luna Toolkit';
            diagnostics.push(diag);
        }
    }

    return diagnostics;
}

// ── Rule 3: luna.unusedRequire ────────────────────────────────

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
            diag.code = 'luna.unusedRequire';
            diag.source = 'Luna Toolkit';
            diag.tags = [vscode.DiagnosticTag.Unnecessary];
            diagnostics.push(diag);
        }
    }

    return diagnostics;
}

// ── Rule 4: luna.assetNotFound ────────────────────────────────

function checkAssetNotFound(
    text: string,
    document: vscode.TextDocument,
    diagnostics: vscode.Diagnostic[],
): void {
    if (!vscode.workspace.workspaceFolders?.length) return;

    const lines = text.split('\n');
    const assetFuncPattern =
        /luna\.(?:graphics\.newImage|audio\.newSource|filesystem\.read)\s*\(\s*["']([^"']+)["']/g;

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
                diag.code = 'luna.assetNotFound';
                diag.source = 'Luna Toolkit';
                diagnostics.push(diag);
            }
        }
    }
}

// ── Rule 5: luna.threadRandom ────────────────────────────────

function checkThreadRandom(
    text: string,
    info: ReturnType<typeof analyzer.analyze>,
): vscode.Diagnostic[] {
    const diagnostics: vscode.Diagnostic[] = [];
    if (!text.includes('luna.thread')) return diagnostics;

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
            if (!scopeLines.includes('luna.thread')) continue;

            const range = new vscode.Range(i, match.index, i, match.index + 'math.random'.length);
            const diag = new vscode.Diagnostic(
                range,
                'math.random in threads may produce identical sequences. Consider seeding with thread ID.',
                vscode.DiagnosticSeverity.Information,
            );
            diag.code = 'luna.threadRandom';
            diag.source = 'Luna Toolkit';
            diagnostics.push(diag);
        }
    }

    return diagnostics;
}

// ── Rule 6: luna.missingCallback ─────────────────────────────

function checkMissingCallback(
    text: string,
    document: vscode.TextDocument,
    info: ReturnType<typeof analyzer.analyze>,
): vscode.Diagnostic[] {
    const diagnostics: vscode.Diagnostic[] = [];
    const fileName = path.basename(document.uri.fsPath);

    // Only for files named main.lua
    if (fileName !== 'main.lua') return diagnostics;

    const hasUpdate = info.callbacks.some(cb => cb.name === 'update')
        || /luna\.update\s*=\s*function/.test(text);
    const hasDraw = info.callbacks.some(cb => cb.name === 'draw')
        || /luna\.draw\s*=\s*function/.test(text);

    if (!hasUpdate && !hasDraw) {
        const lines = text.split('\n');
        const range = new vscode.Range(0, 0, 0, lines[0]?.length ?? 0);
        const diag = new vscode.Diagnostic(
            range,
            'main.lua should define luna.update(dt) and/or luna.draw()',
            vscode.DiagnosticSeverity.Information,
        );
        diag.code = 'luna.missingCallback';
        diag.source = 'Luna Toolkit';
        diagnostics.push(diag);
    }

    return diagnostics;
}

// ── D2: Wrong enum value with "Did you mean?" ─────────────────

// Known enum sets per function/param pattern
const ENUM_RULES: { pattern: RegExp; valid: string[]; label: string }[] = [
    {
        pattern: /luna\.graphics\.(?:rectangle|circle|arc|polygon|ellipse)\s*\(\s*["']([^"']+)["']/g,
        valid: ['fill', 'line'],
        label: 'draw mode',
    },
    {
        pattern: /luna\.graphics\.setBlendMode\s*\(\s*["']([^"']+)["']/g,
        valid: ['alpha', 'add', 'subtract', 'multiply', 'replace', 'screen', 'darken', 'lighten', 'none'],
        label: 'blend mode',
    },
    {
        pattern: /luna\.graphics\.setLineStyle\s*\(\s*["']([^"']+)["']/g,
        valid: ['smooth', 'rough'],
        label: 'line style',
    },
    {
        pattern: /luna\.graphics\.setFilter\s*\([^,]*,\s*["']([^"']+)["']/g,
        valid: ['linear', 'nearest'],
        label: 'texture filter',
    },
    {
        pattern: /luna\.graphics\.setFilter\s*\(\s*["']([^"']+)["']/g,
        valid: ['linear', 'nearest'],
        label: 'texture filter',
    },
    {
        pattern: /luna\.audio\.newSource\s*\([^,]*,\s*["']([^"']+)["']/g,
        valid: ['static', 'stream'],
        label: 'audio source type',
    },
    {
        pattern: /luna\.physics\.newBody\s*\([^,]*,[^,]*,[^,]*,\s*["']([^"']+)["']/g,
        valid: ['dynamic', 'static', 'kinematic'],
        label: 'body type',
    },
    {
        pattern: /luna\.graphics\.printf\s*\([^)]*,[^)]*,[^)]*,[^)]*,\s*["']([^"']+)["']/g,
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
                diag.code = 'luna.wrongEnumValue';
                diag.source = 'Luna Toolkit';
                diagnostics.push(diag);
            }
        }
    }

    return diagnostics;
}

// ── D6: Unknown luna.module.function call ─────────────────────

function checkUnknownLunaFunc(text: string, apiData: ApiDataService): vscode.Diagnostic[] {
    const diagnostics: vscode.Diagnostic[] = [];
    const lines = text.split('\n');
    const callPattern = /luna\.(\w+)\.(\w+)\s*\(/g;

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (line.trimStart().startsWith('--')) continue;
        callPattern.lastIndex = 0;
        let m: RegExpExecArray | null;
        while ((m = callPattern.exec(line)) !== null) {
            const modName = m[1];
            const funcName = m[2];
            const fullPath = `luna.${modName}.${funcName}`;
            const mod = apiData.getModule(modName);
            if (!mod) continue; // unknown module — skip (not our concern)
            const knownFn = apiData.getFunction(fullPath);
            if (knownFn) continue; // known function
            // Also check methods (e.g. for known types)
            const methodFn = apiData.getFunctions(modName).find(f => f.name === funcName);
            if (methodFn) continue;

            const col = m.index + `luna.${modName}.`.length;
            const range = new vscode.Range(i, col, i, col + funcName.length);
            const diag = new vscode.Diagnostic(
                range,
                `"${funcName}" is not a known function in luna.${modName}`,
                vscode.DiagnosticSeverity.Warning,
            );
            diag.code = 'luna.unknownFunction';
            diag.source = 'Luna Toolkit';
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
            diag.code = 'luna.confKey';
            diag.source = 'Luna Toolkit';
            diagnostics.push(diag);
        }
    }
}
