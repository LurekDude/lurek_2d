import * as vscode from "vscode";
import * as net from "net";

const DEFAULT_PORT = 19740;
const CONNECT_TIMEOUT = 5000;
const REQUEST_TIMEOUT = 10000;

interface DebugResponse {
  id: number;
  type: string;
  data?: Record<string, unknown>;
  error?: string;
}

/**
 * Debug bridge: TCP communication with a running Luna2D engine instance.
 */
export class DebugBridge {
  private socket: net.Socket | null = null;
  private outputChannel: vscode.OutputChannel;
  private connected = false;
  private requestId = 0;
  private pending = new Map<number, {
    resolve: (value: DebugResponse) => void;
    reject: (reason: Error) => void;
    timer: ReturnType<typeof setTimeout>;
  }>();
  private buffer = "";
  private statsItem: vscode.StatusBarItem | null = null;
  private statsInterval: ReturnType<typeof setInterval> | null = null;

  constructor() {
    this.outputChannel = vscode.window.createOutputChannel("Luna Debug");
  }

  /** Whether the bridge is currently connected. */
  get isConnected(): boolean {
    return this.connected;
  }

  /** Connect to running Luna2D engine debug port. */
  async connect(port?: number): Promise<boolean> {
    if (this.connected) {
      this.outputChannel.appendLine("[debug] Already connected.");
      return true;
    }

    const targetPort = port ?? vscode.workspace.getConfiguration("luna.debugBridge").get<number>("port", DEFAULT_PORT);

    return new Promise<boolean>((resolve) => {
      const socket = new net.Socket();
      const timeout = setTimeout(() => {
        socket.destroy();
        this.outputChannel.appendLine(`[debug] Connection timed out on port ${targetPort}`);
        resolve(false);
      }, CONNECT_TIMEOUT);

      socket.connect(targetPort, "127.0.0.1", () => {
        clearTimeout(timeout);
        this.socket = socket;
        this.connected = true;
        this.buffer = "";
        this.outputChannel.appendLine(`[debug] Connected to Luna2D on port ${targetPort}`);
        resolve(true);
      });

      socket.on("data", (data) => this.onData(data));

      socket.on("error", (err) => {
        clearTimeout(timeout);
        this.outputChannel.appendLine(`[debug] Connection error: ${err.message}`);
        this.cleanup();
        resolve(false);
      });

      socket.on("close", () => {
        this.outputChannel.appendLine("[debug] Connection closed.");
        this.cleanup();
      });
    });
  }

  /** Disconnect from engine. */
  disconnect(): void {
    if (this.socket) {
      this.socket.destroy();
    }
    this.cleanup();
    this.outputChannel.appendLine("[debug] Disconnected.");
  }

  /** Send a Lua expression for evaluation, return the result string. */
  async evaluate(expression: string): Promise<string> {
    const resp = await this.sendRequest("evaluate", { expression });
    if (resp.error) {
      throw new Error(resp.error);
    }
    return String(resp.data?.result ?? "nil");
  }

  /** Request current variable state from the engine. */
  async getVariables(): Promise<Record<string, string>> {
    const resp = await this.sendRequest("getVariables", {});
    if (resp.error) {
      throw new Error(resp.error);
    }
    const vars = resp.data?.variables;
    if (vars && typeof vars === "object") {
      const result: Record<string, string> = {};
      for (const [k, v] of Object.entries(vars as Record<string, unknown>)) {
        result[k] = String(v);
      }
      return result;
    }
    return {};
  }

  /** Set a breakpoint in a Lua file. */
  async setBreakpoint(file: string, line: number): Promise<boolean> {
    const resp = await this.sendRequest("setBreakpoint", { file, line });
    return !resp.error;
  }

  /** Remove a breakpoint. */
  async removeBreakpoint(file: string, line: number): Promise<boolean> {
    const resp = await this.sendRequest("removeBreakpoint", { file, line });
    return !resp.error;
  }

  /** Step to next line. */
  async step(): Promise<void> {
    await this.sendRequest("step", {});
  }

  /** Step into function. */
  async stepInto(): Promise<void> {
    await this.sendRequest("stepInto", {});
  }

  /** Step out of function. */
  async stepOut(): Promise<void> {
    await this.sendRequest("stepOut", {});
  }

  /** Continue execution. */
  async continueExecution(): Promise<void> {
    await this.sendRequest("continue", {});
  }

  /** Hot-reload: send updated Lua file content to engine. */
  async hotReload(uri: vscode.Uri): Promise<boolean> {
    const doc = await vscode.workspace.openTextDocument(uri);
    const content = doc.getText();
    const relativePath = vscode.workspace.asRelativePath(uri, false);
    const resp = await this.sendRequest("hotReload", {
      file: relativePath,
      content,
    });
    return !resp.error;
  }

  /** Get engine performance stats. */
  async getStats(): Promise<{ fps: number; drawCalls: number; memory: number }> {
    const resp = await this.sendRequest("getStats", {});
    if (resp.error) {
      throw new Error(resp.error);
    }
    return {
      fps: Number(resp.data?.fps ?? 0),
      drawCalls: Number(resp.data?.drawCalls ?? 0),
      memory: Number(resp.data?.memory ?? 0),
    };
  }

  /** Get the current Lua call stack from the engine. */
  async getCallStack(): Promise<{ level: number; source: string; line: number; name: string }[]> {
    const resp = await this.sendRequest("getCallStack", {});
    if (resp.error) {
      throw new Error(resp.error);
    }
    const frames = resp.data?.frames;
    if (Array.isArray(frames)) {
      return frames.map((f: Record<string, unknown>, i: number) => ({
        level: i,
        source: String(f["source"] ?? "?"),
        line: Number(f["line"] ?? 0),
        name: String(f["name"] ?? "?"),
      }));
    }
    return [];
  }

  /** Request a PNG screenshot from the engine, returned as base64. */
  async takeScreenshot(): Promise<string> {
    const resp = await this.sendRequest("screenshot", {});
    if (resp.error) {
      throw new Error(resp.error);
    }
    return String(resp.data?.png_base64 ?? "");
  }

  /** Get connection port and uptime info. */
  getStatusInfo(): { connected: boolean; port: number } {
    return {
      connected: this.connected,
      port: vscode.workspace.getConfiguration("luna.debugBridge").get<number>("port", DEFAULT_PORT),
    };
  }

  /** Show a persistent status bar item with live engine stats. */
  startStatsPolling(): void {
    if (this.statsItem) {
      return;
    }
    this.statsItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 50);
    this.statsItem.text = "$(pulse) FPS: --";
    this.statsItem.tooltip = "Luna2D Engine Stats";
    this.statsItem.show();

    this.statsInterval = setInterval(async () => {
      if (!this.connected) {
        this.stopStatsPolling();
        return;
      }
      try {
        const stats = await this.getStats();
        if (this.statsItem) {
          this.statsItem.text = `$(pulse) FPS: ${stats.fps} | Draw: ${stats.drawCalls} | Mem: ${(stats.memory / 1024 / 1024).toFixed(1)}MB`;
        }
      } catch {
        // Stats request failed — ignore, will retry.
      }
    }, 1000);
  }

  /** Stop polling and hide stats status bar item. */
  stopStatsPolling(): void {
    if (this.statsInterval) {
      clearInterval(this.statsInterval);
      this.statsInterval = null;
    }
    if (this.statsItem) {
      this.statsItem.dispose();
      this.statsItem = null;
    }
  }

  /** Show the debug output channel. */
  showOutput(): void {
    this.outputChannel.show();
  }

  /** Clean up all resources. */
  dispose(): void {
    this.disconnect();
    this.stopStatsPolling();
    this.outputChannel.dispose();
  }

  // ─── Private ─────────────────────────────────────────────

  private sendRequest(type: string, data: Record<string, unknown>): Promise<DebugResponse> {
    return new Promise<DebugResponse>((resolve, reject) => {
      if (!this.connected || !this.socket) {
        reject(new Error("Not connected to Luna2D engine."));
        return;
      }

      const id = ++this.requestId;
      const message = JSON.stringify({ id, type, data }) + "\n";

      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`Request ${type} timed out.`));
      }, REQUEST_TIMEOUT);

      this.pending.set(id, { resolve, reject, timer });

      this.socket.write(message, (err) => {
        if (err) {
          clearTimeout(timer);
          this.pending.delete(id);
          reject(new Error(`Failed to send request: ${err.message}`));
        }
      });
    });
  }

  private onData(data: Buffer): void {
    this.buffer += data.toString("utf-8");
    const lines = this.buffer.split("\n");
    // Keep the last (potentially incomplete) segment in the buffer.
    this.buffer = lines.pop() ?? "";

    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed) {
        continue;
      }
      try {
        const msg = JSON.parse(trimmed) as DebugResponse;
        const entry = this.pending.get(msg.id);
        if (entry) {
          clearTimeout(entry.timer);
          this.pending.delete(msg.id);
          entry.resolve(msg);
        } else {
          // Unsolicited message — log it.
          this.outputChannel.appendLine(`[engine] ${trimmed}`);
        }
      } catch {
        this.outputChannel.appendLine(`[engine] ${trimmed}`);
      }
    }
  }

  private cleanup(): void {
    this.connected = false;
    this.socket = null;
    for (const [, entry] of this.pending) {
      clearTimeout(entry.timer);
      entry.reject(new Error("Connection lost."));
    }
    this.pending.clear();
    this.stopStatsPolling();
  }
}
