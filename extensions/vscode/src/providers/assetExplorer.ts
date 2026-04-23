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
const SHADER_EXT = new Set([".glsl", ".vert", ".frag", ".wgsl"]);

function classifyFile(ext: string): "image" | "audio" | "font" | "shader" | undefined {
  if (IMAGE_EXT.has(ext))  return "image";
  if (AUDIO_EXT.has(ext))  return "audio";
  if (FONT_EXT.has(ext))   return "font";
  if (SHADER_EXT.has(ext)) return "shader";
  return undefined;
}

// ── Category node ────────────────────────────────────────────

interface AssetFile {
  name: string;
  relPath: string;
  uri: vscode.Uri;
  size: number;
  type: "image" | "audio" | "font" | "shader";
}

interface FolderNode {
  name: string;
  relPath: string;
  children: Map<string, FolderNode>;
  files: AssetFile[];
}

interface AssetCategory {
  label: string;
  type: "image" | "audio" | "font" | "shader";
  icon: string;
  root: FolderNode;
  totalCount: number;
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
      { label: "Images",  type: "image",  icon: "file-media",   root: this._newFolder("", ""), totalCount: 0 },
      { label: "Audio",   type: "audio",  icon: "unmute",       root: this._newFolder("", ""), totalCount: 0 },
      { label: "Fonts",   type: "font",   icon: "text-size",    root: this._newFolder("", ""), totalCount: 0 },
      { label: "Shaders", type: "shader", icon: "symbol-color", root: this._newFolder("", ""), totalCount: 0 },
    ];
    this._missingAssets = [];
    this._scanGameRoot();
    this._onDidChangeTreeData.fire(undefined);
  }

  get missingAssets(): string[] {
    return this._missingAssets;
  }

  /** Find the game project root — the folder containing main.lua closest to workspace root. */
  private _findGameRoot(): string | undefined {
    const folders = vscode.workspace.workspaceFolders;
    if (!folders?.length) return undefined;
    const wsRoot = folders[0].uri.fsPath;

    // Check workspace root first
    if (fs.existsSync(path.join(wsRoot, "main.lua"))) {
      return wsRoot;
    }

    // Check immediate child folders (e.g. content/demos/hello_world)
    // Also check common game content directories
    const searchDirs = ["content/demos", "content/examples", "examples", "game", "src"];
    for (const rel of searchDirs) {
      const dir = path.join(wsRoot, rel);
      if (!fs.existsSync(dir)) continue;
      try {
        const entries = fs.readdirSync(dir, { withFileTypes: true });
        for (const entry of entries) {
          if (entry.isDirectory()) {
            const candidate = path.join(dir, entry.name);
            if (fs.existsSync(path.join(candidate, "main.lua"))) {
              return candidate;
            }
          }
        }
      } catch { /* ignore */ }
    }

    // Fallback: scan the workspace root itself for assets
    return wsRoot;
  }

  private _scanGameRoot(): void {
    const gameRoot = this._findGameRoot();
    if (!gameRoot) return;
    this._walk(gameRoot, gameRoot);
  }

  private _newFolder(name: string, relPath: string): FolderNode {
    return { name, relPath, children: new Map(), files: [] };
  }

  private _ensureFolder(root: FolderNode, relDir: string): FolderNode {
    if (!relDir || relDir === ".") return root;
    const parts = relDir.split("/");
    let current = root;
    let builtPath = "";
    for (const part of parts) {
      builtPath = builtPath ? `${builtPath}/${part}` : part;
      let child = current.children.get(part);
      if (!child) {
        child = this._newFolder(part, builtPath);
        current.children.set(part, child);
      }
      current = child;
    }
    return current;
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
      // Skip hidden dirs, node_modules, target, build, .git
      if (entry.name.startsWith(".") || entry.name === "node_modules" || entry.name === "target" || entry.name === "build") continue;

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
        const relPath = path.relative(root, fullPath).replace(/\\/g, "/");
        const relDir = path.dirname(relPath);
        const folder = this._ensureFolder(cat.root, relDir === "." ? "" : relDir);
        folder.files.push({
          name: entry.name,
          relPath,
          uri: vscode.Uri.file(fullPath),
          size,
          type: kind,
        });
        cat.totalCount++;
      }
    }
  }

  getTreeItem(element: AssetItem): AssetItem {
    return element;
  }

  getChildren(element?: AssetItem): AssetItem[] {
    if (!element) {
      // Top level: show categories with counts
      return this.categories
        .filter(cat => cat.totalCount > 0)
        .map(cat => {
          const item = new AssetItem(
            `${cat.label} (${cat.totalCount})`,
            vscode.TreeItemCollapsibleState.Collapsed,
            undefined,
            "folder",
            undefined,
          );
          item.contextValue = `assetCategory.${cat.type}`;
          (item as AssetItem & { _catType: string })._catType = cat.type;
          return item;
        });
    }

    // Category node → show folder tree or direct files
    const catType = (element as AssetItem & { _catType?: string })._catType;
    if (catType) {
      const cat = this.categories.find(c => c.type === catType);
      if (!cat) return [];
      return this._folderChildren(cat.root, cat.type);
    }

    // Folder node → show subfolders + files
    const folderData = (element as AssetItem & { _folderNode?: FolderNode; _fileType?: string })._folderNode;
    const fileType = (element as AssetItem & { _fileType?: string })._fileType;
    if (folderData) {
      return this._folderChildren(folderData, fileType as "image" | "audio" | "font" | "shader" || "image");
    }

    return [];
  }

  private _folderChildren(folder: FolderNode, fileType: "image" | "audio" | "font" | "shader"): AssetItem[] {
    const items: AssetItem[] = [];

    // Sub-folders first (sorted)
    const sortedFolders = Array.from(folder.children.entries()).sort((a, b) => a[0].localeCompare(b[0]));
    for (const [name, child] of sortedFolders) {
      const fileCount = this._countFiles(child);
      const item = new AssetItem(
        `${name} (${fileCount})`,
        vscode.TreeItemCollapsibleState.Collapsed,
        undefined,
        "folder",
        undefined,
      );
      (item as AssetItem & { _folderNode: FolderNode; _fileType: string })._folderNode = child;
      (item as AssetItem & { _fileType: string })._fileType = fileType;
      items.push(item);
    }

    // Files (sorted)
    const sortedFiles = [...folder.files].sort((a, b) => a.name.localeCompare(b.name));
    for (const file of sortedFiles) {
      const item = new AssetItem(
        file.name,
        vscode.TreeItemCollapsibleState.None,
        file.uri,
        file.type,
        file.size,
      );
      item.contextValue = "assetItem";
      items.push(item);
    }

    return items;
  }

  private _countFiles(folder: FolderNode): number {
    let count = folder.files.length;
    for (const child of folder.children.values()) {
      count += this._countFiles(child);
    }
    return count;
  }
}

// ── "Find missing assets" helper ─────────────────────────────

export async function findMissingAssets(): Promise<void> {
  const wsRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  if (!wsRoot) {
    vscode.window.showWarningMessage("No workspace folder open.");
    return;
  }

  const luaFiles = await vscode.workspace.findFiles("**/*.lua", "{**/node_modules/**,ideas/**,work/**,.github/**}");
  const assetPattern = /lurek\.(?:graphics\.newImage|audio\.newSource)\s*\(\s*["']([^"']+)["']/g;
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
