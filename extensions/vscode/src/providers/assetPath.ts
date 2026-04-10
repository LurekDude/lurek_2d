import * as vscode from 'vscode';
import * as path from 'path';
import { ApiDataService } from '../services/apiData.js';
import { LuaDocumentAnalyzer } from '../services/luaParser.js';

const LUA_SELECTOR: vscode.DocumentSelector = { scheme: 'file', language: 'lua' };
const analyzer = new LuaDocumentAnalyzer();

/** Maps asset function patterns to their expected file extensions. */
const ASSET_FUNC_EXTENSIONS: Record<string, string[]> = {
    'lurek.graphics.newImage': ['.png', '.jpg', '.jpeg', '.bmp', '.gif'],
    'lurek.audio.newSource': ['.ogg', '.wav', '.mp3', '.flac'],
    'lurek.filesystem.read': [],
    'lurek.filesystem.write': [],
    'lurek.filesystem.exists': [],
};

/** Extensions shown for require() completions. */
const LUA_EXTENSIONS = ['.lua'];

/**
 * Registers the asset path completion provider.
 * Completes file paths inside string arguments to asset-loading and require functions.
 */
export function register(context: vscode.ExtensionContext, apiData: ApiDataService): void {
    const provider = vscode.languages.registerCompletionItemProvider(
        LUA_SELECTOR,
        {
            async provideCompletionItems(
                document: vscode.TextDocument,
                position: vscode.Position,
            ): Promise<vscode.CompletionItem[] | undefined> {
                try {
                    return await getAssetCompletions(document, position);
                } catch {
                    return undefined;
                }
            },
        },
        '"', "'", '/',
    );

    context.subscriptions.push(provider);
}

async function getAssetCompletions(
    document: vscode.TextDocument,
    position: vscode.Position,
): Promise<vscode.CompletionItem[] | undefined> {
    const lineText = document.lineAt(position).text;
    const textBefore = lineText.substring(0, position.character);

    // Try matching an asset-loading function: lurek.module.func("partial_path
    const assetMatch = textBefore.match(/(lurek\.\w+\.\w+)\s*\(\s*["']([^"']*)$/);
    // Try matching require: require("partial_path
    const requireMatch = textBefore.match(/require\s*\(\s*["']([^"']*)$/);

    if (!assetMatch && !requireMatch) return undefined;

    const funcPath = assetMatch ? assetMatch[1] : 'require';
    const partialPath = assetMatch ? assetMatch[2] : requireMatch![1];

    // Determine extensions filter
    let extensions: string[] = [];
    if (funcPath === 'require') {
        extensions = LUA_EXTENSIONS;
    } else if (funcPath in ASSET_FUNC_EXTENSIONS) {
        extensions = ASSET_FUNC_EXTENSIONS[funcPath];
    } else {
        return undefined;
    }

    const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    if (!workspaceRoot) return undefined;

    // Build glob pattern
    const searchDir = partialPath.includes('/') ? path.dirname(partialPath) : '';
    const globPattern = searchDir ? `${searchDir}/**/*` : '**/*';

    const files = await vscode.workspace.findFiles(globPattern, '**/node_modules/**', 200);
    const items: vscode.CompletionItem[] = [];
    const seenDirs = new Set<string>();

    for (const file of files) {
        const ext = path.extname(file.fsPath).toLowerCase();

        // Filter by expected extensions (empty = allow all)
        if (extensions.length > 0 && !extensions.includes(ext)) continue;

        const relativePath = path.relative(workspaceRoot, file.fsPath).replace(/\\/g, '/');

        // For require(), strip .lua extension and use dot-separated paths
        if (funcPath === 'require') {
            const requirePath = relativePath
                .replace(/\.lua$/, '')
                .replace(/\//g, '.');
            const item = new vscode.CompletionItem(requirePath, vscode.CompletionItemKind.Module);
            item.detail = 'Lua module';
            item.insertText = requirePath;
            const depth = requirePath.split('.').length;
            item.sortText = String(depth).padStart(3, '0') + requirePath;
            items.push(item);
            continue;
        }

        // Add folder completions
        const dir = path.dirname(relativePath);
        if (dir !== '.' && !seenDirs.has(dir)) {
            seenDirs.add(dir);
            // Only add dir completion if it matches partial path prefix
            if (!partialPath || dir.startsWith(partialPath.split('/')[0])) {
                const dirItem = new vscode.CompletionItem(dir + '/', vscode.CompletionItemKind.Folder);
                dirItem.sortText = '0' + dir;
                items.push(dirItem);
            }
        }

        const item = new vscode.CompletionItem(relativePath, vscode.CompletionItemKind.File);
        item.detail = ext.toUpperCase().substring(1) + ' file';
        item.insertText = relativePath;

        // Sort by depth — nearby files first
        const depth = relativePath.split('/').length;
        item.sortText = String(depth).padStart(3, '0') + relativePath;
        items.push(item);
    }

    return items;
}
