import * as vscode from 'vscode';
import { ApiDataService } from '../services/apiData.js';

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: 'file', language: 'lua' };

/** Color-related function names to detect. */
const COLOR_FUNCTIONS = ['setColor', 'setBackgroundColor', 'clear', 'newColor'];

/**
 * Registers the color provider for lurek.graphics color calls.
 * Detects 0-1 range RGBA values and shows the VS Code color picker.
 */
export function register(context: vscode.ExtensionContext, apiData: ApiDataService): void {
    const provider = vscode.languages.registerColorProvider(LUA_SELECTOR, {
        provideDocumentColors(document: vscode.TextDocument): vscode.ColorInformation[] {
            try {
                return detectColors(document);
            } catch {
                return [];
            }
        },

        provideColorPresentations(
            color: vscode.Color,
            colorContext: { document: vscode.TextDocument; range: vscode.Range },
        ): vscode.ColorPresentation[] {
            try {
                return createPresentations(color, colorContext);
            } catch {
                return [];
            }
        },
    });

    context.subscriptions.push(provider);
}

/** Build regex pattern for all color functions. */
const COLOR_CALL_PATTERN = new RegExp(
    `lurek\\.graphics\\.(?:${COLOR_FUNCTIONS.join('|')})` +
    `\\s*\\(\\s*([\\d.]+)\\s*,\\s*([\\d.]+)\\s*,\\s*([\\d.]+)(?:\\s*,\\s*([\\d.]+))?\\s*\\)`,
    'g',
);

function detectColors(document: vscode.TextDocument): vscode.ColorInformation[] {
    const colors: vscode.ColorInformation[] = [];
    const text = document.getText();

    const pattern = new RegExp(COLOR_CALL_PATTERN.source, 'g');
    let match: RegExpExecArray | null;

    while ((match = pattern.exec(text)) !== null) {
        const r = parseFloat(match[1]);
        const g = parseFloat(match[2]);
        const b = parseFloat(match[3]);
        const a = match[4] !== undefined ? parseFloat(match[4]) : 1;

        // Only provide inline color for 0-1 range values
        if (r > 1 || g > 1 || b > 1 || a > 1) continue;

        // Find the range of just the arguments (r, g, b[, a])
        const fullMatchText = match[0];
        const argsStart = fullMatchText.indexOf('(') + 1;
        const argsEnd = fullMatchText.lastIndexOf(')');
        const argsOffset = match.index + argsStart;
        const argsLen = argsEnd - argsStart;

        const startPos = document.positionAt(argsOffset);
        const endPos = document.positionAt(argsOffset + argsLen);
        const range = new vscode.Range(startPos, endPos);

        colors.push(new vscode.ColorInformation(range, new vscode.Color(r, g, b, a)));
    }

    return colors;
}

function createPresentations(
    color: vscode.Color,
    colorContext: { document: vscode.TextDocument; range: vscode.Range },
): vscode.ColorPresentation[] {
    const r = formatComponent(color.red);
    const g = formatComponent(color.green);
    const b = formatComponent(color.blue);
    const a = formatComponent(color.alpha);

    const presentations: vscode.ColorPresentation[] = [];

    // With alpha
    const withAlpha = new vscode.ColorPresentation(`${r}, ${g}, ${b}, ${a}`);
    withAlpha.textEdit = new vscode.TextEdit(colorContext.range, `${r}, ${g}, ${b}, ${a}`);
    presentations.push(withAlpha);

    // Without alpha (if alpha is ~1)
    if (Math.abs(color.alpha - 1.0) < 0.005) {
        const noAlpha = new vscode.ColorPresentation(`${r}, ${g}, ${b}`);
        noAlpha.textEdit = new vscode.TextEdit(colorContext.range, `${r}, ${g}, ${b}`);
        presentations.push(noAlpha);
    }

    // Hex comment
    const hexR = Math.round(color.red * 255).toString(16).padStart(2, '0');
    const hexG = Math.round(color.green * 255).toString(16).padStart(2, '0');
    const hexB = Math.round(color.blue * 255).toString(16).padStart(2, '0');
    const hexPresentation = new vscode.ColorPresentation(`${r}, ${g}, ${b} --[[ #${hexR}${hexG}${hexB} ]]`);
    hexPresentation.textEdit = new vscode.TextEdit(
        colorContext.range,
        `${r}, ${g}, ${b} --[[ #${hexR}${hexG}${hexB} ]]`,
    );
    presentations.push(hexPresentation);

    return presentations;
}

/** Format a 0-1 color component to 2 decimal places, trimming trailing zeros. */
function formatComponent(value: number): string {
    return value.toFixed(2).replace(/\.?0+$/, '') || '0';
}
