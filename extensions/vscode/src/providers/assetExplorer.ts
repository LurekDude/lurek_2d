import * as vscode from "vscode";
import * as path from "path";
import * as fs from "fs";

// ── Asset item ───────────────────────────────────────────────

export class AssetItem extends vscode.TreeItem {
  constructor(
    public readonly label: string,
    public readonly collapsibleState: vscode.TreeItemCollapsibleState,
    public readonly resourceUri?: vscode.Uri,
    public readonly assetType?: "image" | "audio" | "font" | "shader" | "folder",
    public readonly sizeBytes?: number,
  ) {
    super(label, collapsibleState);
    if (resourceUri) {
      this.resourceUri = resourceUri;
      this.tooltip = resourceUri.fsPath;
    }
    this.iconPath = assetType ? new vscode.ThemeIcon(AssetItem.iconFor(assetType)) : undefined;
    if (sizeBytes !== undefined) {
      this.description = AssetItem.formatSize(sizeBytes);
    }
    if (assetType && assetType !== "folder" && resourceUri) {
      this.command = {
        command: "vscode.open",
        title: "Open File",
        arguments: [resourceUri],
      };
    }
  }

  private static iconFor(kind: string): string {
    switch (kind) {
      case "image":  return "file-media";
      case "audio":  return "unmute";
      case "font":   return "text-size";
      case "shader": return "symbol-color";
      case "folder": return "folder";
      default:       return "file";
    }
  }

  private static formatSize(bytes: number): string {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
  }
}

// ── Extension patterns ───────────────────────────────────────

const IMAGE_EXT  = new Set([".png", ".jpg", ".jpeg", ".bmp", ".gif", ".tga", ".tiff", ".webp"]);
const AUDIO_EXT  = new Set([".wav", ".ogg", ".mp3", ".flac", ".aiff"]);
const FONT_EXT   = new Set([".ttf", ".otf"]);
const SHADER_EXT = new Set([".glsl", ".vert", ".frag"]);

function classifyFile(ext: string): "image" | "audio" | "font" | "shader" | undefined {
  if (IMAGE_EXT.has(ext))  return "image";
  if (AUDIO_EXT.has(ext))  return "audio";
  if (FONT_EXT.has(ext))   return "font";
  if (SHADER_EXT.has(ext)) return "shader";
  return undefined;
}

// ── Category node ────────────────────────────────────────────

interface AssetCategory {
  label: string;
  type: "image" | "audio" | "font" | "shader";
  icon: string;
  items: { name: string; uri: vscode.Uri; size: number }[];
}

// ── Provider ─────────────────────────────────────────────────

export class AssetExplorerProvider implements vscode.TreeDataProvider<AssetItem> {
  private readonly _onDidChangeTreeData = new vscode.EventEmitter<AssetItem | undefined>();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;

  private categories: AssetCategory[] = [];
  private _missingAssets: string[] = [];

  constructor() {
    this.refresh();
  }

  refresh(): void {
    this.categories = [
      { label: "Images",  type: "image",  icon: "file-media",  items: [] },
      { label: "Audio",   type: "audio",  icon: "unmute",      items: [] },
      { label: "Fonts",   type: "font",   icon: "text-size",   items: [] },
      { label: "Shaders", type: "shader", icon: "symbol-color", items: [] },
    ];
    this._missingAssets = [];
    this._scanWorkspace();
    this._onDidChangeTreeData.fire(undefined);
  }

  get missingAssets(): string[] {
    return this._missingAssets;
  }

  private _scanWorkspace(): void {
    const folders = vscode.workspace.workspaceFolders;
    if (!folders?.length) return;
    const root = folders[0].uri.fsPath;
    this._walk(root, root);
  }

  private _walk(dir: string, root: string): void {
    let entries: fs.Dirent[];
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch {
      return;
    }

    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      // Skip hidden dirs, node_modules, target
      if (entry.name.startsWith(".") || entry.name === "node_modules" || entry.name === "target") continue;

      if (entry.isDirectory()) {
        this._walk(fullPath, root);
      } else if (entry.isFile()) {
        const ext = path.extname(entry.name).toLowerCase();
        const kind = classifyFile(ext);
        if (!kind) continue;
        const cat = this.categories.find(c => c.type === kind);
        if (!cat) continue;
        let size = 0;
        try { size = fs.statSync(fullPath).size; } catch { /* skip */ }
        cat.items.push({
          name: path.relative(root, fullPath).replace(/\\/g, "/"),
          uri: vscode.Uri.file(fullPath),
          size,
        });
      }
    }
  }

  getTreeItem(element: AssetItem): AssetItem {
    return element;
  }

  getChildren(element?: AssetItem): AssetItem[] {
    if (!element) {
      return this.categories
        .filter(cat => cat.items.length > 0)
        .map(cat => {
          const item = new AssetItem(
            `${cat.label} (${cat.items.length})`,
            vscode.TreeItemCollapsibleState.Collapsed,
            undefined,
            "folder",
            undefined,
          );
          item.contextValue = `assetCategory.${cat.type}`;
          // Store type for getChildren lookup
          (item as AssetItem & { _catType: string })._catType = cat.type;
          return item;
        });
    }

    // Find the category for this header node
    const catType = (element as AssetItem & { _catType?: string })._catType;
    if (catType) {
      const cat = this.categories.find(c => c.type === catType);
      if (!cat) return [];
      return cat.items.map(i =>
        new AssetItem(
          path.basename(i.name),
          vscode.TreeItemCollapsibleState.None,
          i.uri,
          cat.type,
          i.size,
        ),
      );
    }

    return [];
  }
}

// ── "Find missing assets" helper ─────────────────────────────

export async function findMissingAssets(): Promise<void> {
  const wsRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  if (!wsRoot) {
    vscode.window.showWarningMessage("No workspace folder open.");
    return;
  }

  const luaFiles = await vscode.workspace.findFiles("**/*.lua", "**/node_modules/**");
  const assetPattern = /luna\.(?:graphics\.newImage|audio\.newSource)\s*\(\s*["']([^"']+)["']/g;
  const missing: { file: string; line: number; asset: string }[] = [];

  for (const uri of luaFiles) {
    let text: string;
    try { text = fs.readFileSync(uri.fsPath, "utf8"); } catch { continue; }
    const lines = text.split("\n");
    for (let i = 0; i < lines.length; i++) {
      assetPattern.lastIndex = 0;
      let m: RegExpExecArray | null;
      while ((m = assetPattern.exec(lines[i])) !== null) {
        const assetPath = m[1];
        if (!assetPath.includes(".")) continue;
        const abs = path.resolve(path.dirname(uri.fsPath), assetPath);
        const abs2 = path.resolve(wsRoot, assetPath);
        if (!fs.existsSync(abs) && !fs.existsSync(abs2)) {
          missing.push({ file: vscode.workspace.asRelativePath(uri), line: i + 1, asset: assetPath });
        }
      }
    }
  }

  if (missing.length === 0) {
    vscode.window.showInformationMessage("No missing assets found.");
    return;
  }

  const report = missing.map(m => `${m.file}:${m.line}  →  ${m.asset}`).join("\n");
  const doc = await vscode.workspace.openTextDocument({ content: `Missing assets:\n\n${report}`, language: "plaintext" });
  vscode.window.showTextDocument(doc);
}

// ── "Insert path" command helper ─────────────────────────────

export function insertAssetPath(item: AssetItem): void {
  const editor = vscode.window.activeTextEditor;
  if (!editor || !item.resourceUri) return;
  const wsRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath ?? "";
  let rel = item.resourceUri.fsPath;
  if (wsRoot && rel.startsWith(wsRoot)) rel = rel.substring(wsRoot.length + 1);
  rel = rel.replace(/\\/g, "/");
  editor.edit(b => b.replace(editor.selection, `"${rel}"`));
}
