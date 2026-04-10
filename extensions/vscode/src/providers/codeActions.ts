import * as vscode from 'vscode';
import { ApiDataService } from '../services/apiData.js';
import { LuaDocumentAnalyzer } from '../services/luaParser.js';

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: 'file', language: 'lua' };
const analyzer = new LuaDocumentAnalyzer();

/**
 * Registers code action providers for Lua files.
 * Provides quick fixes tied to diagnostics and general refactoring actions.
 */
export function register(context: vscode.ExtensionContext, apiData: ApiDataService): void {
    const provider = vscode.languages.registerCodeActionsProvider(
        LUA_SELECTOR,
        {
            provideCodeActions(
                document: vscode.TextDocument,
                range: vscode.Range,
                actionContext: vscode.CodeActionContext,
            ): vscode.CodeAction[] {
                try {
                    return getCodeActions(document, range, actionContext);
                } catch {
                    return [];
                }
            },
        },
        {
            providedCodeActionKinds: [
                vscode.CodeActionKind.QuickFix,
                vscode.CodeActionKind.RefactorExtract,
            ],
        },
    );

    context.subscriptions.push(provider);
}

function getCodeActions(
    document: vscode.TextDocument,
    range: vscode.Range,
    actionContext: vscode.CodeActionContext,
): vscode.CodeAction[] {
    const actions: vscode.CodeAction[] = [];

    // ── Diagnostic-driven quick fixes ──
    for (const diag of actionContext.diagnostics) {
        switch (diag.code) {
            case 'lurek.unusedRequire':
                actions.push(...createRemoveUnusedRequire(document, diag));
                break;
            case 'lurek.missingCallback':
                actions.push(...createGenerateCallbacks(document, diag));
                break;
            case 'lurek.colorRange':
                actions.push(...createConvertColorRange(document, diag));
                break;
        }
    }

    // ── Context-driven actions ──
    const lineText = document.lineAt(range.start.line).text;

    // Action 4: Extract function (selection required)
    if (!range.isEmpty) {
        actions.push(createExtractFunction(document, range));
        actions.push(createExtractToFileModule(document, range));
    }

    // Action 5: Convert global to local
    const globalMatch = lineText.match(/^(\s*)(\w+)\s*=\s*(.+)/);
    if (
        globalMatch
        && !lineText.trimStart().startsWith('local ')
        && !lineText.trimStart().startsWith('function ')
        && !lineText.trimStart().startsWith('--')
        && !lineText.includes('lurek.')
        && !lineText.includes('.')
        && !lineText.includes(':')
    ) {
        actions.push(createConvertToLocal(document, range.start.line, globalMatch));
    }

    // Action 6: Wrap require in pcall
    if (/\brequire\s*\(/.test(lineText) && !/pcall/.test(lineText)) {
        actions.push(createWrapRequirePcall(document, range.start.line));
    }

    // Action 7: Inline single-use variable (local x = expr → use expr directly)
    const inlineMatch = lineText.match(/^(\s*)local\s+(\w+)\s*=\s*(.+)/);
    if (inlineMatch && !range.isEmpty) {
        actions.push(createInlineVariable(document, range.start.line, inlineMatch));
    }

    // Action 8: Convert if/elseif chain to state-map
    if (/^\s*if\s+/.test(lineText)) {
        const stateMap = tryCreateStateMapConversion(document, range.start.line);
        if (stateMap) actions.push(stateMap);
    }

    // Action 9: Add ---@type annotation
    const localVarMatch = lineText.match(/^(\s*)local\s+(\w+)\s*=/);
    if (localVarMatch && !lineText.includes('---@type')) {
        actions.push(createAddTypeAnnotation(document, range.start.line, localVarMatch[2]));
    }

    // Action 10: Generate __tostring metamethod
    if (/(\w+)\.__index\s*=\s*\1/.test(lineText) || /setmetatable\s*\(\s*{/.test(lineText)) {
        const className = lineText.match(/(\w+)\.__index/)?.[1];
        if (className) {
            actions.push(createGenerateTostring(document, range.start.line, className));
        }
    }

    return actions;
}

// ── Action 1: Remove unused require ──────────────────────────

function createRemoveUnusedRequire(
    document: vscode.TextDocument,
    diag: vscode.Diagnostic,
): vscode.CodeAction[] {
    const action = new vscode.CodeAction(
        'Remove unused require',
        vscode.CodeActionKind.QuickFix,
    );
    action.edit = new vscode.WorkspaceEdit();

    // Delete the entire line including the newline
    const line = diag.range.start.line;
    const deleteRange = new vscode.Range(line, 0, line + 1, 0);
    action.edit.delete(document.uri, deleteRange);
    action.diagnostics = [diag];
    action.isPreferred = true;

    return [action];
}

// ── Action 2: Generate missing callbacks ─────────────────────

function createGenerateCallbacks(
    document: vscode.TextDocument,
    diag: vscode.Diagnostic,
): vscode.CodeAction[] {
    const text = document.getText();
    const missing: string[] = [];

    if (!/function\s+lurek\.load\s*\(/.test(text) && !/lurek\.load\s*=\s*function/.test(text)) {
        missing.push('load');
    }
    if (!/function\s+lurek\.update\s*\(/.test(text) && !/lurek\.update\s*=\s*function/.test(text)) {
        missing.push('update');
    }
    if (!/function\s+lurek\.draw\s*\(/.test(text) && !/lurek\.draw\s*=\s*function/.test(text)) {
        missing.push('draw');
    }

    if (missing.length === 0) return [];

    const action = new vscode.CodeAction(
        'Generate Lurek2D callbacks',
        vscode.CodeActionKind.QuickFix,
    );
    action.edit = new vscode.WorkspaceEdit();

    const stubs: string[] = [];
    if (missing.includes('load')) {
        stubs.push('function lurek.load()\n    -- Initialize game\nend');
    }
    if (missing.includes('update')) {
        stubs.push('function lurek.update(dt)\n    -- Update game logic\nend');
    }
    if (missing.includes('draw')) {
        stubs.push('function lurek.draw()\n    -- Draw game objects\nend');
    }

    const endPos = document.lineAt(document.lineCount - 1).range.end;
    action.edit.insert(document.uri, endPos, '\n\n' + stubs.join('\n\n') + '\n');
    action.diagnostics = [diag];

    return [action];
}

// ── Action 3: Convert 0-255 color to 0-1 ─────────────────────

function createConvertColorRange(
    document: vscode.TextDocument,
    diag: vscode.Diagnostic,
): vscode.CodeAction[] {
    const text = document.getText(diag.range);

    const match = text.match(
        /(lurek\.graphics\.(?:setColor|setBackgroundColor|clear))\s*\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)/,
    );
    if (!match) return [];

    const func = match[1];
    const format = (v: string): string => (parseFloat(v) / 255).toFixed(2).replace(/\.?0+$/, '') || '0';
    const r = format(match[2]);
    const g = format(match[3]);
    const b = format(match[4]);

    let replacement: string;
    if (match[5] !== undefined) {
        const a = format(match[5]);
        replacement = `${func}(${r}, ${g}, ${b}, ${a})`;
    } else {
        replacement = `${func}(${r}, ${g}, ${b})`;
    }

    const action = new vscode.CodeAction(
        'Convert to 0-1 color range',
        vscode.CodeActionKind.QuickFix,
    );
    action.edit = new vscode.WorkspaceEdit();
    action.edit.replace(document.uri, diag.range, replacement);
    action.diagnostics = [diag];
    action.isPreferred = true;

    return [action];
}

// ── Action 4: Extract function ───────────────────────────────

function createExtractFunction(
    document: vscode.TextDocument,
    range: vscode.Range,
): vscode.CodeAction {
    const action = new vscode.CodeAction(
        'Extract to local function',
        vscode.CodeActionKind.RefactorExtract,
    );
    action.edit = new vscode.WorkspaceEdit();

    const selectedText = document.getText(range);
    const indent = document.lineAt(range.start.line).text.match(/^(\s*)/)?.[1] ?? '';
    const funcName = 'extracted_function';

    const bodyLines = selectedText.split('\n').map((l, i) => i === 0 ? l : indent + '    ' + l);
    const funcDef = `${indent}local function ${funcName}()\n${indent}    ${bodyLines.join('\n')}\n${indent}end\n\n`;

    // Insert function definition before the selection
    action.edit.insert(document.uri, new vscode.Position(range.start.line, 0), funcDef);
    // Replace the selection with a call
    action.edit.replace(document.uri, range, `${funcName}()`);

    return action;
}

// ── Action 5: Convert global to local ────────────────────────

function createConvertToLocal(
    document: vscode.TextDocument,
    line: number,
    match: RegExpMatchArray,
): vscode.CodeAction {
    const action = new vscode.CodeAction(
        'Convert to local variable',
        vscode.CodeActionKind.QuickFix,
    );
    action.edit = new vscode.WorkspaceEdit();

    const lineRange = document.lineAt(line).range;
    const newText = `${match[1]}local ${match[2]} = ${match[3]}`;
    action.edit.replace(document.uri, lineRange, newText);

    return action;
}

// ── Action 6: Wrap require in pcall ──────────────────────────

function createWrapRequirePcall(
    document: vscode.TextDocument,
    line: number,
): vscode.CodeAction {
    const lineText = document.lineAt(line).text;
    const indent = lineText.match(/^(\s*)/)?.[1] ?? '';

    const action = new vscode.CodeAction(
        'Wrap require in pcall',
        vscode.CodeActionKind.QuickFix,
    );
    action.edit = new vscode.WorkspaceEdit();

    // Match: local varName = require("module")
    const match = lineText.match(/^(\s*)local\s+(\w+)\s*=\s*require\s*\(\s*["']([^"']+)["']\s*\)/);
    if (match) {
        const varName = match[2];
        const modName = match[3];
        const newText = [
            `${indent}local ok, ${varName} = pcall(require, "${modName}")`,
            `${indent}if not ok then`,
            `${indent}    error("Failed to load module: " .. tostring(${varName}))`,
            `${indent}end`,
        ].join('\n');
        action.edit.replace(document.uri, document.lineAt(line).range, newText);
    } else {
        // Fallback: generic require wrap
        const requireMatch = lineText.match(/require\s*\(\s*["']([^"']+)["']\s*\)/);
        if (requireMatch) {
            const modName = requireMatch[1];
            const newText = [
                `${indent}local ok, module = pcall(require, "${modName}")`,
                `${indent}if not ok then`,
                `${indent}    error("Failed to load module: " .. tostring(module))`,
                `${indent}end`,
            ].join('\n');
            action.edit.replace(document.uri, document.lineAt(line).range, newText);
        }
    }

    return action;
}

// ── Action 7: Extract to new file module ─────────────────────

function createExtractToFileModule(
    document: vscode.TextDocument,
    range: vscode.Range,
): vscode.CodeAction {
    const action = new vscode.CodeAction(
        'Extract selection to new module file',
        vscode.CodeActionKind.RefactorExtract,
    );
    action.command = {
        command: 'lurek.extractToModuleFile',
        title: 'Extract to new module file',
        arguments: [document.uri, range],
    };
    return action;
}

// ── Action 8: Inline single-use variable ─────────────────────

function createInlineVariable(
    document: vscode.TextDocument,
    line: number,
    match: RegExpMatchArray,
): vscode.CodeAction {
    const action = new vscode.CodeAction(
        `Inline variable '${match[2]}'`,
        vscode.CodeActionKind.RefactorInline,
    );
    action.edit = new vscode.WorkspaceEdit();
    const indent = match[1];
    const rhs = match[3].trim();
    // Replace the local declaration with a comment hint — actual inlining
    // requires multi-line analysis, so we emit a TODO marker
    action.edit.replace(
        document.uri,
        document.lineAt(line).range,
        `${indent}-- TODO: inline '${match[2]}' = ${rhs}`,
    );
    return action;
}

// ── Action 9: Convert if/elseif chain to state-map ───────────

function tryCreateStateMapConversion(
    document: vscode.TextDocument,
    startLine: number,
): vscode.CodeAction | undefined {
    // Collect the if/elseif chain
    const lines: string[] = [];
    const stateVar = document.lineAt(startLine).text.match(/if\s+(\w+)\s*==\s*['"]/)?.[1];
    if (!stateVar) return undefined;

    for (let i = startLine; i < Math.min(startLine + 40, document.lineCount); i++) {
        lines.push(document.lineAt(i).text);
        if (document.lineAt(i).text.trimStart() === 'end') break;
    }

    const cases: { key: string; body: string }[] = [];
    let i = 0;
    while (i < lines.length) {
        const caseMatch = lines[i].match(/(?:if|elseif)\s+\w+\s*==\s*['"](\w+)['"]\s*then/);
        if (caseMatch) {
            const key = caseMatch[1];
            const bodyLines: string[] = [];
            i++;
            while (i < lines.length && !/(?:elseif|else|end)/.test(lines[i].trimStart())) {
                bodyLines.push(lines[i].replace(/^\s{4}/, '    '));
                i++;
            }
            cases.push({ key, body: bodyLines.join('\n') });
        } else {
            i++;
        }
    }

    if (cases.length < 2) return undefined;

    const indent = (document.lineAt(startLine).text.match(/^(\s*)/) ?? ['', ''])[1];
    const mapName = `${stateVar}Handlers`;
    const mapLines = [
        `${indent}local ${mapName} = {`,
        ...cases.map(c => `${indent}  ${c.key} = function()\n${c.body}\n${indent}  end,`),
        `${indent}}`,
        `${indent}local _handler = ${mapName}[${stateVar}]`,
        `${indent}if _handler then _handler() end`,
    ];

    const action = new vscode.CodeAction(
        `Convert if/elseif chain to state-map (${mapName})`,
        vscode.CodeActionKind.RefactorRewrite,
    );
    action.edit = new vscode.WorkspaceEdit();
    const replaceRange = new vscode.Range(
        startLine, 0,
        startLine + lines.length - 1,
        document.lineAt(startLine + lines.length - 1).range.end.character,
    );
    action.edit.replace(document.uri, replaceRange, mapLines.join('\n'));
    return action;
}

// ── Action 10: Add ---@type annotation ───────────────────────

function createAddTypeAnnotation(
    document: vscode.TextDocument,
    line: number,
    varName: string,
): vscode.CodeAction {
    const action = new vscode.CodeAction(
        `Add ---@type annotation for '${varName}'`,
        vscode.CodeActionKind.RefactorRewrite,
    );
    action.edit = new vscode.WorkspaceEdit();
    const indent = (document.lineAt(line).text.match(/^(\s*)/) ?? ['', ''])[1];
    const insertPos = new vscode.Position(line, 0);
    action.edit.insert(document.uri, insertPos, `${indent}---@type any\n`);
    return action;
}

// ── Action 11: Generate __tostring metamethod ─────────────────

function createGenerateTostring(
    document: vscode.TextDocument,
    line: number,
    className: string,
): vscode.CodeAction {
    const action = new vscode.CodeAction(
        `Generate __tostring for ${className}`,
        vscode.CodeActionKind.QuickFix,
    );
    action.edit = new vscode.WorkspaceEdit();
    const indent = (document.lineAt(line).text.match(/^(\s*)/) ?? ['', ''])[1];
    const insertPos = new vscode.Position(line + 1, 0);
    action.edit.insert(
        document.uri,
        insertPos,
        `\n${indent}function ${className}:__tostring()\n` +
        `${indent}  return "${className}()"  -- TODO: fill in fields\n` +
        `${indent}end\n`,
    );
    return action;
}
