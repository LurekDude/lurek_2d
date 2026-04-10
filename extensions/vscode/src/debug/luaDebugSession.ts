import {
  LoggingDebugSession,
  InitializedEvent,
  StoppedEvent,
  OutputEvent,
  TerminatedEvent,
  Thread,
  StackFrame,
  Scope,
  Source,
  Breakpoint,
  Variable,
  CompletionItem,
} from "@vscode/debugadapter";
import { DebugProtocol } from "@vscode/debugprotocol";
import * as net from "net";
import * as path from "path";
import { ChildProcess, spawn } from "child_process";
import * as fs from "fs";

/** Arguments for a launch request. */
interface LaunchRequestArguments extends DebugProtocol.LaunchRequestArguments {
  program: string;
  stopOnEntry?: boolean;
  luaVersion?: string;
  debugPort?: number;
  enginePath?: string;
  args?: string[];
}

/** Arguments for an attach request. */
interface AttachRequestArguments extends DebugProtocol.AttachRequestArguments {
  debugPort?: number;
}

/** A JSON message received from the engine. */
interface EngineEvent {
  event: string;
  reason?: string;
  line?: number;
  file?: string;
  category?: string;
  output?: string;
  id?: number;
  verified?: boolean;
}

/** A JSON response received from the engine. */
interface EngineResponse {
  id: number;
  success: boolean;
  body?: Record<string, unknown>;
  error?: string;
}

/** A stack frame as reported by the engine. */
interface EngineStackFrame {
  name: string;
  file: string;
  line: number;
  column?: number;
}

/** A variable as reported by the engine. */
interface EngineVariable {
  name: string;
  value: string;
  type?: string;
  variablesReference?: number;
  children?: EngineVariable[];
}

const THREAD_ID = 1;
const MAX_CONNECT_RETRIES = 5;
const RETRY_DELAY_MS = 800;
const DEFAULT_DEBUG_PORT = 8172;

export class LuaDebugSession extends LoggingDebugSession {
  private socket: net.Socket | null = null;
  private engineProcess: ChildProcess | null = null;
  private breakpoints = new Map<string, DebugProtocol.Breakpoint[]>();
  private variablesMap = new Map<number, Variable[]>();
  private nextVariableRef = 1;
  private pendingRequests = new Map<
    number,
    {
      resolve: (response: EngineResponse) => void;
      reject: (err: Error) => void;
    }
  >();
  private nextRequestId = 1;
  private receiveBuffer = "";
  private gamePath = "";
  private debugPort = DEFAULT_DEBUG_PORT;
  private loadedSources: Source[] = [];

  public constructor() {
    super("lurek-debug.log");
    this.setDebuggerLinesStartAt1(true);
    this.setDebuggerColumnsStartAt1(true);
  }

  // ── Initialization ──────────────────────────────────────

  protected initializeRequest(
    response: DebugProtocol.InitializeResponse,
    _args: DebugProtocol.InitializeRequestArguments,
  ): void {
    response.body = {
      supportsConfigurationDoneRequest: true,
      supportsFunctionBreakpoints: false,
      supportsConditionalBreakpoints: true,
      supportsHitConditionalBreakpoints: true,
      supportsEvaluateForHovers: true,
      supportsStepBack: false,
      supportsSetVariable: true,
      supportsRestartFrame: false,
      supportsGotoTargetsRequest: false,
      supportsStepInTargetsRequest: false,
      supportsCompletionsRequest: true,
      supportsModulesRequest: false,
      supportsExceptionOptions: false,
      supportsValueFormattingOptions: false,
      supportsExceptionInfoRequest: false,
      supportTerminateDebuggee: true,
      supportsDelayedStackTraceLoading: false,
      supportsLoadedSourcesRequest: true,
      supportsLogPoints: true,
      supportsTerminateThreadsRequest: false,
      supportsSetExpression: false,
      supportsTerminateRequest: true,
      supportsDataBreakpoints: false,
      supportsReadMemoryRequest: false,
      supportsDisassembleRequest: false,
      supportsBreakpointLocationsRequest: true,
      supportsClipboardContext: false,
      supportsExceptionFilterOptions: false,
      supportsSteppingGranularity: false,
      supportsInstructionBreakpoints: false,
    };

    this.sendResponse(response);
    this.sendEvent(new InitializedEvent());
  }

  // ── Launch / Attach ─────────────────────────────────────

  protected async launchRequest(
    response: DebugProtocol.LaunchResponse,
    args: LaunchRequestArguments,
  ): Promise<void> {
    this.gamePath = args.program;
    this.debugPort = args.debugPort ?? DEFAULT_DEBUG_PORT;
    const stopOnEntry = args.stopOnEntry ?? false;

    const engineBinary = this.findEngineBinary(args.enginePath);
    if (!engineBinary) {
      this.sendErrorResponse(response, 1001, "Lurek2D engine not found. Set 'lurek.enginePath' in settings or ensure lurek2d is on PATH.");
      return;
    }

    const spawnArgs = [
      `--debug-port=${this.debugPort}`,
      this.gamePath,
      ...(args.args ?? []),
    ];

    this.log(`Launching: ${engineBinary} ${spawnArgs.join(" ")}`);

    try {
      this.engineProcess = spawn(engineBinary, spawnArgs, {
        cwd: path.dirname(this.gamePath),
        stdio: ["ignore", "pipe", "pipe"],
      });

      this.engineProcess.stdout?.on("data", (data: Buffer) => {
        this.sendEvent(
          new OutputEvent(data.toString(), "stdout"),
        );
      });

      this.engineProcess.stderr?.on("data", (data: Buffer) => {
        this.sendEvent(
          new OutputEvent(data.toString(), "stderr"),
        );
      });

      this.engineProcess.on("exit", (code) => {
        this.log(`Engine exited with code ${code}`);
        this.sendEvent(new TerminatedEvent());
      });

      this.engineProcess.on("error", (err) => {
        this.sendEvent(
          new OutputEvent(`Engine error: ${err.message}\n`, "stderr"),
        );
        this.sendEvent(new TerminatedEvent());
      });

      await this.connectToEngine(this.debugPort);

      if (stopOnEntry) {
        await this.sendToEngine("pause");
      }

      this.sendResponse(response);
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      this.sendErrorResponse(response, 1002, `Failed to launch: ${message}`);
    }
  }

  protected async attachRequest(
    response: DebugProtocol.AttachResponse,
    args: AttachRequestArguments,
  ): Promise<void> {
    this.debugPort = args.debugPort ?? DEFAULT_DEBUG_PORT;

    try {
      await this.connectToEngine(this.debugPort);
      this.sendResponse(response);
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      this.sendErrorResponse(response, 1003, `Failed to attach: ${message}`);
    }
  }

  protected configurationDoneRequest(
    response: DebugProtocol.ConfigurationDoneResponse,
    _args: DebugProtocol.ConfigurationDoneArguments,
  ): void {
    this.sendResponse(response);
  }

  protected async disconnectRequest(
    response: DebugProtocol.DisconnectResponse,
    args: DebugProtocol.DisconnectArguments,
  ): Promise<void> {
    if (args.terminateDebuggee !== false && this.engineProcess) {
      try {
        await this.sendToEngine("terminate");
      } catch {
        // engine may already be gone
      }
    }
    this.cleanup();
    this.sendResponse(response);
  }

  protected async terminateRequest(
    response: DebugProtocol.TerminateResponse,
    _args: DebugProtocol.TerminateArguments,
  ): Promise<void> {
    try {
      await this.sendToEngine("terminate");
    } catch {
      // best effort
    }
    this.cleanup();
    this.sendResponse(response);
  }

  // ── Breakpoints ─────────────────────────────────────────

  protected async setBreakPointsRequest(
    response: DebugProtocol.SetBreakpointsResponse,
    args: DebugProtocol.SetBreakpointsArguments,
  ): Promise<void> {
    const sourcePath = args.source.path ?? "";
    const clientLines = args.lines ?? [];

    const relativePath = this.toRelativePath(sourcePath);

    try {
      const engineResp = await this.sendToEngine("setBreakpoints", {
        file: relativePath,
        lines: clientLines,
      });

      const bps: DebugProtocol.Breakpoint[] = clientLines.map((line, idx) => {
        const bp = new Breakpoint(true, line) as DebugProtocol.Breakpoint;
        bp.id = idx + 1;
        if (engineResp.body && Array.isArray(engineResp.body.breakpoints)) {
          const engineBp = (engineResp.body.breakpoints as Array<{ verified: boolean; line?: number }>)[idx];
          if (engineBp) {
            bp.verified = engineBp.verified;
            if (engineBp.line !== undefined) {
              bp.line = engineBp.line;
            }
          }
        }
        return bp;
      });

      this.breakpoints.set(sourcePath, bps);

      if (!this.loadedSources.find((s) => s.path === sourcePath)) {
        this.loadedSources.push(
          new Source(path.basename(sourcePath), sourcePath),
        );
      }

      response.body = { breakpoints: bps };
    } catch {
      // Offline — report all as unverified
      const bps: DebugProtocol.Breakpoint[] = clientLines.map((line, idx) => {
        const bp = new Breakpoint(false, line) as DebugProtocol.Breakpoint;
        bp.id = idx + 1;
        return bp;
      });
      this.breakpoints.set(sourcePath, bps);
      response.body = { breakpoints: bps };
    }

    this.sendResponse(response);
  }

  protected breakpointLocationsRequest(
    response: DebugProtocol.BreakpointLocationsResponse,
    args: DebugProtocol.BreakpointLocationsArguments,
  ): void {
    // Report that breakpoints can be set on any requested line
    const startLine = args.line;
    const endLine = args.endLine ?? startLine;
    const locations: DebugProtocol.BreakpointLocation[] = [];
    for (let line = startLine; line <= endLine; line++) {
      locations.push({ line });
    }
    response.body = { breakpoints: locations };
    this.sendResponse(response);
  }

  // ── Threads ─────────────────────────────────────────────

  protected threadsRequest(response: DebugProtocol.ThreadsResponse): void {
    response.body = {
      threads: [new Thread(THREAD_ID, "Lurek2D Main")],
    };
    this.sendResponse(response);
  }

  // ── Stack Trace ─────────────────────────────────────────

  protected async stackTraceRequest(
    response: DebugProtocol.StackTraceResponse,
    args: DebugProtocol.StackTraceArguments,
  ): Promise<void> {
    try {
      const engineResp = await this.sendToEngine("stackTrace");
      const frames: DebugProtocol.StackFrame[] = [];

      if (engineResp.body && Array.isArray(engineResp.body.frames)) {
        const engineFrames = engineResp.body.frames as EngineStackFrame[];
        const startFrame = args.startFrame ?? 0;
        const levels = args.levels ?? engineFrames.length;
        const endFrame = Math.min(startFrame + levels, engineFrames.length);

        for (let i = startFrame; i < endFrame; i++) {
          const ef = engineFrames[i];
          const fullPath = this.toAbsolutePath(ef.file);
          const source = new Source(path.basename(ef.file), fullPath);
          frames.push(
            new StackFrame(i, ef.name, source, ef.line, ef.column ?? 1),
          );
        }
      }

      response.body = {
        stackFrames: frames,
        totalFrames: (engineResp.body?.frames as unknown[])?.length ?? frames.length,
      };
    } catch {
      response.body = { stackFrames: [], totalFrames: 0 };
    }

    this.sendResponse(response);
  }

  // ── Scopes ──────────────────────────────────────────────

  protected async scopesRequest(
    response: DebugProtocol.ScopesResponse,
    args: DebugProtocol.ScopesArguments,
  ): Promise<void> {
    try {
      const engineResp = await this.sendToEngine("scopes", {
        frameId: args.frameId,
      });

      const scopes: Scope[] = [];
      if (engineResp.body && Array.isArray(engineResp.body.scopes)) {
        for (const s of engineResp.body.scopes as Array<{
          name: string;
          variablesReference: number;
          expensive?: boolean;
        }>) {
          scopes.push(
            new Scope(s.name, s.variablesReference, s.expensive ?? false),
          );
        }
      } else {
        // Default scopes: locals and upvalues
        const localsRef = this.nextVariableRef++;
        const upvaluesRef = this.nextVariableRef++;
        scopes.push(new Scope("Locals", localsRef, false));
        scopes.push(new Scope("Upvalues", upvaluesRef, false));
      }

      response.body = { scopes };
    } catch {
      response.body = { scopes: [] };
    }

    this.sendResponse(response);
  }

  // ── Variables ───────────────────────────────────────────

  protected async variablesRequest(
    response: DebugProtocol.VariablesResponse,
    args: DebugProtocol.VariablesArguments,
  ): Promise<void> {
    try {
      const cached = this.variablesMap.get(args.variablesReference);
      if (cached) {
        response.body = { variables: cached };
        this.sendResponse(response);
        return;
      }

      const engineResp = await this.sendToEngine("variables", {
        variablesReference: args.variablesReference,
      });

      const variables: Variable[] = [];
      if (engineResp.body && Array.isArray(engineResp.body.variables)) {
        for (const v of engineResp.body.variables as EngineVariable[]) {
          let varRef = 0;
          if (v.children && v.children.length > 0) {
            varRef = this.nextVariableRef++;
            const childVars = v.children.map((c) => {
              let childRef = 0;
              if (c.children && c.children.length > 0) {
                childRef = this.nextVariableRef++;
                this.variablesMap.set(
                  childRef,
                  c.children.map(
                    (gc) => new Variable(gc.name, gc.value, 0),
                  ),
                );
              }
              return new Variable(c.name, c.value, childRef);
            });
            this.variablesMap.set(varRef, childVars);
          } else if (v.variablesReference) {
            varRef = v.variablesReference;
          }

          variables.push(new Variable(v.name, v.value, varRef));
        }
      }

      this.variablesMap.set(args.variablesReference, variables);
      response.body = { variables };
    } catch {
      response.body = { variables: [] };
    }

    this.sendResponse(response);
  }

  protected async setVariableRequest(
    response: DebugProtocol.SetVariableResponse,
    args: DebugProtocol.SetVariableArguments,
  ): Promise<void> {
    try {
      const engineResp = await this.sendToEngine("setVariable", {
        variablesReference: args.variablesReference,
        name: args.name,
        value: args.value,
      });

      response.body = {
        value: (engineResp.body?.value as string) ?? args.value,
      };

      // Invalidate cached variables
      this.variablesMap.delete(args.variablesReference);
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      this.sendErrorResponse(response, 1010, `Failed to set variable: ${message}`);
      return;
    }

    this.sendResponse(response);
  }

  // ── Execution Control ───────────────────────────────────

  protected async continueRequest(
    response: DebugProtocol.ContinueResponse,
    _args: DebugProtocol.ContinueArguments,
  ): Promise<void> {
    this.variablesMap.clear();
    try {
      await this.sendToEngine("continue");
    } catch {
      // best effort
    }
    response.body = { allThreadsContinued: true };
    this.sendResponse(response);
  }

  protected async nextRequest(
    response: DebugProtocol.NextResponse,
    _args: DebugProtocol.NextArguments,
  ): Promise<void> {
    this.variablesMap.clear();
    try {
      await this.sendToEngine("next");
    } catch {
      // best effort
    }
    this.sendResponse(response);
  }

  protected async stepInRequest(
    response: DebugProtocol.StepInResponse,
    _args: DebugProtocol.StepInArguments,
  ): Promise<void> {
    this.variablesMap.clear();
    try {
      await this.sendToEngine("stepIn");
    } catch {
      // best effort
    }
    this.sendResponse(response);
  }

  protected async stepOutRequest(
    response: DebugProtocol.StepOutResponse,
    _args: DebugProtocol.StepOutArguments,
  ): Promise<void> {
    this.variablesMap.clear();
    try {
      await this.sendToEngine("stepOut");
    } catch {
      // best effort
    }
    this.sendResponse(response);
  }

  protected async pauseRequest(
    response: DebugProtocol.PauseResponse,
    _args: DebugProtocol.PauseArguments,
  ): Promise<void> {
    try {
      await this.sendToEngine("pause");
    } catch {
      // best effort
    }
    this.sendResponse(response);
  }

  // ── Evaluate ────────────────────────────────────────────

  protected async evaluateRequest(
    response: DebugProtocol.EvaluateResponse,
    args: DebugProtocol.EvaluateArguments,
  ): Promise<void> {
    try {
      const engineResp = await this.sendToEngine("evaluate", {
        expression: args.expression,
        frameId: args.frameId ?? 0,
        context: args.context,
      });

      const result = (engineResp.body?.result as string) ?? "nil";
      const varRef = (engineResp.body?.variablesReference as number) ?? 0;

      response.body = {
        result,
        variablesReference: varRef,
      };
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      response.body = {
        result: `Error: ${message}`,
        variablesReference: 0,
      };
    }

    this.sendResponse(response);
  }

  // ── Completions ─────────────────────────────────────────

  protected completionsRequest(
    response: DebugProtocol.CompletionsResponse,
    args: DebugProtocol.CompletionsArguments,
  ): void {
    const text = args.text;
    const targets: CompletionItem[] = [];

    // Provide lurek.* namespace completions
    if (text.startsWith("lurek.")) {
      const lurekModules = [
        "graphics", "audio", "timer", "keyboard", "mouse", "gamepad",
        "touch", "window", "filesystem", "math", "physics", "system",
        "data", "event", "thread", "scene", "entity", "particle",
      ];
      for (const mod of lurekModules) {
        if (mod.startsWith(text.slice(5))) {
          targets.push(new CompletionItem(mod, 9)); // 9 = Module
        }
      }
    }

    // Basic Lua keywords
    const keywords = [
      "local", "function", "if", "then", "else", "elseif", "end",
      "for", "while", "do", "repeat", "until", "return", "break",
      "in", "not", "and", "or", "true", "false", "nil",
    ];
    for (const kw of keywords) {
      if (kw.startsWith(text)) {
        targets.push(new CompletionItem(kw, 14)); // 14 = Keyword
      }
    }

    response.body = { targets };
    this.sendResponse(response);
  }

  // ── Loaded Sources ──────────────────────────────────────

  protected loadedSourcesRequest(
    response: DebugProtocol.LoadedSourcesResponse,
  ): void {
    response.body = { sources: this.loadedSources };
    this.sendResponse(response);
  }

  // ── TCP Communication ───────────────────────────────────

  private connectToEngine(port: number): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      let retries = 0;

      const attempt = (): void => {
        const socket = new net.Socket();

        const onError = (err: Error): void => {
          socket.destroy();
          retries++;
          if (retries < MAX_CONNECT_RETRIES) {
            this.log(
              `Connection attempt ${retries} failed, retrying in ${RETRY_DELAY_MS}ms...`,
            );
            setTimeout(attempt, RETRY_DELAY_MS);
          } else {
            reject(
              new Error(
                `Failed to connect to Lurek2D engine on port ${port} after ${MAX_CONNECT_RETRIES} attempts: ${err.message}`,
              ),
            );
          }
        };

        socket.once("error", onError);

        socket.connect(port, "127.0.0.1", () => {
          socket.removeListener("error", onError);
          this.socket = socket;
          this.receiveBuffer = "";

          this.log(`Connected to Lurek2D engine on port ${port}`);

          socket.on("data", (data: Buffer) => {
            this.onSocketData(data);
          });

          socket.on("error", (err) => {
            this.sendEvent(
              new OutputEvent(`Engine connection error: ${err.message}\n`, "stderr"),
            );
            this.cleanup();
            this.sendEvent(new TerminatedEvent());
          });

          socket.on("close", () => {
            this.log("Engine connection closed");
            this.cleanup();
            this.sendEvent(new TerminatedEvent());
          });

          resolve();
        });
      };

      attempt();
    });
  }

  private sendToEngine(
    command: string,
    args?: Record<string, unknown>,
  ): Promise<EngineResponse> {
    return new Promise<EngineResponse>((resolve, reject) => {
      if (!this.socket || this.socket.destroyed) {
        reject(new Error("Not connected to engine"));
        return;
      }

      const id = this.nextRequestId++;
      const message = JSON.stringify({ id, command, args: args ?? {} });
      const packet = `Content-Length: ${Buffer.byteLength(message)}\r\n\r\n${message}`;

      this.pendingRequests.set(id, { resolve, reject });

      // Timeout after 10 seconds
      const timer = setTimeout(() => {
        this.pendingRequests.delete(id);
        reject(new Error(`Request '${command}' timed out`));
      }, 10_000);

      // Wrap resolve/reject to clear timeout
      const original = this.pendingRequests.get(id)!;
      this.pendingRequests.set(id, {
        resolve: (resp) => {
          clearTimeout(timer);
          original.resolve(resp);
        },
        reject: (err) => {
          clearTimeout(timer);
          original.reject(err);
        },
      });

      try {
        this.socket.write(packet);
      } catch (err) {
        clearTimeout(timer);
        this.pendingRequests.delete(id);
        reject(err instanceof Error ? err : new Error(String(err)));
      }
    });
  }

  private onSocketData(data: Buffer): void {
    this.receiveBuffer += data.toString("utf-8");

    // Process complete messages from the buffer
    while (true) {
      const headerEnd = this.receiveBuffer.indexOf("\r\n\r\n");
      if (headerEnd === -1) {
        break;
      }

      const header = this.receiveBuffer.substring(0, headerEnd);
      const match = /Content-Length:\s*(\d+)/i.exec(header);
      if (!match) {
        // Malformed header — skip past it
        this.receiveBuffer = this.receiveBuffer.substring(headerEnd + 4);
        continue;
      }

      const contentLength = parseInt(match[1], 10);
      const bodyStart = headerEnd + 4;

      if (this.receiveBuffer.length < bodyStart + contentLength) {
        break; // incomplete body
      }

      const body = this.receiveBuffer.substring(
        bodyStart,
        bodyStart + contentLength,
      );
      this.receiveBuffer = this.receiveBuffer.substring(
        bodyStart + contentLength,
      );

      try {
        const message = JSON.parse(body) as Record<string, unknown>;
        if ("event" in message) {
          this.handleEngineEvent(message as unknown as EngineEvent);
        } else if ("id" in message) {
          this.handleEngineResponse(message as unknown as EngineResponse);
        }
      } catch {
        this.log(`Failed to parse engine message: ${body}`);
      }
    }
  }

  private handleEngineEvent(event: EngineEvent): void {
    switch (event.event) {
      case "stopped": {
        const stoppedEvent = new StoppedEvent(
          event.reason ?? "breakpoint",
          THREAD_ID,
        );
        this.variablesMap.clear();
        this.sendEvent(stoppedEvent);
        break;
      }
      case "output": {
        this.sendEvent(
          new OutputEvent(
            event.output ?? "",
            event.category ?? "console",
          ),
        );
        break;
      }
      case "terminated": {
        this.sendEvent(new TerminatedEvent());
        break;
      }
      case "breakpointValidated": {
        if (event.id !== undefined && event.verified !== undefined) {
          // Find and update the breakpoint
          for (const [, bps] of this.breakpoints) {
            for (const bp of bps) {
              if (bp.id === event.id) {
                bp.verified = event.verified;
              }
            }
          }
        }
        break;
      }
      default:
        this.log(`Unknown engine event: ${event.event}`);
    }
  }

  private handleEngineResponse(response: EngineResponse): void {
    const pending = this.pendingRequests.get(response.id);
    if (pending) {
      this.pendingRequests.delete(response.id);
      if (response.success) {
        pending.resolve(response);
      } else {
        pending.reject(new Error(response.error ?? "Unknown engine error"));
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────

  private findEngineBinary(configPath?: string): string | null {
    // 1. Explicitly configured path from launch.json
    if (configPath && fs.existsSync(configPath)) {
      return configPath;
    }

    // 2. VS Code setting
    const settingsPath = (
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      require("vscode") as typeof import("vscode")
    ).workspace
      .getConfiguration("lurek")
      .get<string>("enginePath", "");

    if (settingsPath && fs.existsSync(settingsPath)) {
      return settingsPath;
    }

    // 3. Check workspace build/ folder (Lurek2D uses build/ instead of target/)
    const wsRoot = (
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      require("vscode") as typeof import("vscode")
    ).workspace.workspaceFolders?.[0]?.uri.fsPath;

    if (wsRoot) {
      const exeName = process.platform === "win32" ? "lurek2d.exe" : "lurek2d";
      const buildCandidates = [
        path.join(wsRoot, "build", "debug", exeName),
        path.join(wsRoot, "build", "release", exeName),
        path.join(wsRoot, "target", "debug", exeName),
        path.join(wsRoot, "target", "release", exeName),
      ];
      for (const candidate of buildCandidates) {
        if (fs.existsSync(candidate)) {
          this.log(`Found engine binary: ${candidate}`);
          return candidate;
        }
      }
    }

    // 4. Common install locations
    const homeDir = process.env.USERPROFILE ?? process.env.HOME ?? "";
    const candidates = [
      path.join(homeDir, "bin", "lurek2d.exe"),
      path.join(homeDir, "bin", "lurek2d"),
      path.join(homeDir, ".local", "bin", "lurek2d"),
      "/usr/local/bin/lurek2d",
    ];

    for (const candidate of candidates) {
      if (fs.existsSync(candidate)) {
        return candidate;
      }
    }

    // 5. Rely on PATH
    const pathExe = process.platform === "win32" ? "lurek2d.exe" : "lurek2d";
    const pathDirs = (process.env.PATH ?? "").split(path.delimiter);
    for (const dir of pathDirs) {
      const fullPath = path.join(dir, pathExe);
      if (fs.existsSync(fullPath)) {
        return fullPath;
      }
    }

    return null;
  }

  private toRelativePath(absolutePath: string): string {
    if (this.gamePath && absolutePath.startsWith(this.gamePath)) {
      let rel = absolutePath.substring(this.gamePath.length);
      if (rel.startsWith(path.sep) || rel.startsWith("/")) {
        rel = rel.substring(1);
      }
      return rel.replace(/\\/g, "/");
    }
    return path.basename(absolutePath);
  }

  private toAbsolutePath(relativePath: string): string {
    if (path.isAbsolute(relativePath)) {
      return relativePath;
    }
    return path.join(this.gamePath, relativePath);
  }

  private cleanup(): void {
    if (this.socket) {
      this.socket.removeAllListeners();
      this.socket.destroy();
      this.socket = null;
    }

    if (this.engineProcess) {
      try {
        this.engineProcess.kill();
      } catch {
        // already dead
      }
      this.engineProcess = null;
    }

    // Reject all pending requests
    for (const [, pending] of this.pendingRequests) {
      pending.reject(new Error("Debug session ended"));
    }
    this.pendingRequests.clear();
    this.variablesMap.clear();
  }

  private log(message: string): void {
    this.sendEvent(new OutputEvent(`[Lurek2D Debug] ${message}\n`, "console"));
  }
}
