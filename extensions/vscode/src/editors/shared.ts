import * as vscode from "vscode";

/**
 * Generates a cryptographically random nonce for CSP.
 */
export function getNonce(): string {
  const chars =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  let result = "";
  for (let i = 0; i < 32; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

/**
 * Shared CSS theme for all Lurek2D editors.
 */
export function getSharedCss(): string {
  return `
    :root {
      --bg: #1e1e1e; --surface: #252526; --surface-2: #2d2d2d;
      --border: #3c3c3c; --text: #cccccc; --text-dim: #858585;
      --accent: #007acc; --accent-2: #4ec9b0;
      --success: #4caf50; --warning: #ff9800; --danger: #f44336;
      --selection: #264f78;
    }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      color: var(--text); background: var(--bg);
      overflow: hidden; height: 100vh;
    }
    button {
      background: var(--surface-2); color: var(--text); border: 1px solid var(--border);
      padding: 4px 12px; border-radius: 3px; cursor: pointer; font-size: 12px;
    }
    button:hover { background: var(--accent); border-color: var(--accent); }
    button.active { background: var(--accent); border-color: var(--accent); }
    button.danger { border-color: var(--danger); }
    button.danger:hover { background: var(--danger); }
    input, select, textarea {
      background: var(--surface); color: var(--text); border: 1px solid var(--border);
      padding: 3px 6px; border-radius: 3px; font-size: 12px;
    }
    input:focus, select:focus, textarea:focus { outline: none; border-color: var(--accent); }
    label { font-size: 12px; color: var(--text-dim); }
    .toolbar {
      display: flex; align-items: center; gap: 6px; padding: 6px 10px;
      background: var(--surface); border-bottom: 1px solid var(--border);
    }
    .toolbar .sep { width: 1px; height: 20px; background: var(--border); }
    .panel {
      background: var(--surface); border-right: 1px solid var(--border);
      overflow-y: auto; padding: 8px;
    }
    .panel h3 {
      font-size: 11px; text-transform: uppercase; color: var(--text-dim);
      margin-bottom: 6px; letter-spacing: 0.5px;
    }
    .status-bar {
      display: flex; align-items: center; gap: 12px; padding: 2px 10px;
      background: var(--surface); border-top: 1px solid var(--border);
      font-size: 11px; color: var(--text-dim);
    }
    .list-item {
      padding: 4px 8px; cursor: pointer; border-radius: 3px; font-size: 12px;
    }
    .list-item:hover { background: var(--surface-2); }
    .list-item.selected { background: var(--selection); }
    .section { margin-bottom: 12px; }
    .field { display: flex; flex-direction: column; gap: 2px; margin-bottom: 6px; }
    .field-row { display: flex; align-items: center; gap: 6px; margin-bottom: 4px; }
    canvas { display: block; }
  `;
}

/**
 * Wraps body + scripts into a complete CSP-safe HTML document.
 */
export function wrapHtml(
  nonce: string,
  title: string,
  extraCss: string,
  body: string,
  scripts: string
): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta http-equiv="Content-Security-Policy"
    content="default-src 'none'; style-src 'nonce-${nonce}'; script-src 'nonce-${nonce}'; img-src data:;">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
  <style nonce="${nonce}">${getSharedCss()}${extraCss}</style>
</head>
<body>
${body}
<script nonce="${nonce}">
const vscode = acquireVsCodeApi();
${scripts}
</script>
</body>
</html>`;
}

/**
 * Abstract base class for all Lurek2D webview editors.
 */
export abstract class WebviewEditor {
  protected panel: vscode.WebviewPanel;
  protected isDirty: boolean = false;
  private disposables: vscode.Disposable[] = [];

  constructor(
    protected context: vscode.ExtensionContext,
    viewType: string,
    title: string,
    protected data: Record<string, unknown> = {}
  ) {
    this.panel = vscode.window.createWebviewPanel(
      viewType,
      title,
      vscode.ViewColumn.One,
      { enableScripts: true, retainContextWhenHidden: true }
    );

    this.panel.webview.onDidReceiveMessage(
      (msg) => this.handleMessage(msg),
      undefined,
      this.disposables
    );

    this.panel.onDidDispose(
      () => this.dispose(),
      undefined,
      this.disposables
    );

    this.panel.webview.html = this.getHtml();
  }

  protected abstract handleMessage(msg: {
    type: string;
    [key: string]: unknown;
  }): void;
  protected abstract getHtml(): string;

  protected async exportFile(
    content: string,
    defaultName: string,
    filterLabel: string,
    ext: string
  ): Promise<void> {
    const uri = await vscode.window.showSaveDialog({
      defaultUri: vscode.Uri.file(defaultName),
      filters: { [filterLabel]: [ext] },
    });
    if (uri) {
      await vscode.workspace.fs.writeFile(
        uri,
        Buffer.from(content, "utf-8")
      );
      vscode.window.showInformationMessage(`Exported to ${uri.fsPath}`);
    }
  }

  protected async exportLua(
    content: string,
    defaultName: string
  ): Promise<void> {
    return this.exportFile(content, defaultName, "Lua", "lua");
  }

  protected async exportToml(
    content: string,
    defaultName: string
  ): Promise<void> {
    return this.exportFile(content, defaultName, "TOML", "toml");
  }

  dispose(): void {
    for (const d of this.disposables) {
      d.dispose();
    }
  }
}
