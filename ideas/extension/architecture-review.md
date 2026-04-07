# Extension Architecture Review

## Current Architecture

The extension follows a layered architecture:

```
┌─── entry point ────────────────────────────────────────────┐
│  extension2.ts — registers everything, wires services       │
├─── services ───────────────────────────────────────────────┤
│  apiData     luaParser    statusBar    lunaProcess          │
│  debugBridge symbolIndex                                    │
├─── providers (language features) ──────────────────────────┤
│  completion  hover       signature    definition            │
│  references  symbols     diagnostics  color                 │
│  assetPath   inlayHints  codeActions  luajitHints           │
│  typeInference requireGraph luacatsProvider codeLens         │
│  formatting  folding     rename       semanticTokens        │
│  perfDashboard systemMonitor debugWatchers apiUsage          │
│  assetExplorer sidebar                                      │
├─── commands ───────────────────────────────────────────────┤
│  run  test  scaffold  packaging  editors  reference         │
│  cag  debugBridge  gameJam  library  gameDevCag  testGen    │
├─── editors (webviews) ─────────────────────────────────────┤
│  29 editor files + shared.ts                                │
├─── mcp ────────────────────────────────────────────────────┤
│  server.ts  tools.ts                                        │
├─── debug ──────────────────────────────────────────────────┤
│  luaDebugAdapter.ts  luaDebugSession.ts                     │
├─── cag ────────────────────────────────────────────────────┤
│  game-dev/ (agents, instructions, skills, templates)        │
└────────────────────────────────────────────────────────────┘
```

---

## Improvement Ideas

### 1. Consistent Provider Registration Pattern

**Current**: Some providers use `register(context, apiData)`, others use different signatures.

**Improvement**: Standardize all providers to:

```typescript
export function register(
  context: vscode.ExtensionContext,
  apiData: ApiDataService,
  services?: { debugBridge?: DebugBridge; parser?: LuaParser }
): void
```

### 2. Service Dependency Injection

**Current**: Services are created in extension2.ts and passed to providers individually.

**Improvement**: Create a ServiceContainer:

```typescript
class ServiceContainer {
  readonly apiData: ApiDataService;
  readonly parser: LuaParser;
  readonly debugBridge: DebugBridge;
  readonly statusBar: StatusBarService;
  readonly process: LunaProcessService;
  readonly symbolIndex: SymbolIndexService;
}
```

Pass the container instead of individual services. Enables testing with mock containers.

### 3. Extension Lifecycle Management

**Current**: All initialization happens synchronously in `activate()`.

**Improvement**:
- Phase 1: Essential services (status bar, API data)
- Phase 2: Language providers (completion, hover, diagnostics)
- Phase 3: Advanced features (editors, debug, MCP)
- Phase 4: Background tasks (symbol indexing, asset scanning)

This reduces activation time and prioritizes core features.

### 4. Event-Driven State Updates

**Current**: Providers likely poll for state changes or rebuild on every document change.

**Improvement**: Event bus for state propagation:

```typescript
class ExtensionEventBus {
  on(event: 'apiDataLoaded' | 'documentChanged' | 'gameStarted' | 'debugConnected', handler);
  emit(event, data);
}
```

Providers subscribe to relevant events instead of polling.

### 5. Configuration Service

**Current**: Configuration access scattered across files.

**Improvement**: Centralized configuration service:

```typescript
class ConfigService {
  get lunaPath(): string;
  get saveOnRun(): boolean;
  get diagnosticsEnabled(): DiagnosticsConfig;
  onChange(handler: (key: string) => void);
}
```

### 6. Error Handling Strategy

**Gap**: No consistent error handling across the extension.

**Improvement**:
- Wrap all provider methods in try/catch
- Log errors to dedicated output channel
- Show user-friendly errors for common failures
- Track error frequency for telemetry
- Never crash the extension on a single provider failure

### 7. Telemetry / Analytics

**Not implemented**. Consider opt-in telemetry for:
- Extension activation time
- Most-used commands
- Provider response latency
- Error frequency
- Feature discovery (which editors are opened)
- API data coverage trends

**Privacy**: Anonymous, aggregated data only. Respect VS Code telemetry settings.

### 8. Extension API for Other Extensions

**Not implemented**. Expose an API for other extensions:

```typescript
export class LunaApi {
  getApiData(): ApiModule[];
  runGame(path: string): Promise<void>;
  evaluateLua(expr: string): Promise<string>;
  getProjectInfo(): ProjectInfo;
}
```

This enables community extensions to build on top of Luna Toolkit.

### 9. Modular Extension Architecture

**Long-term idea**: Split into multiple extensions:

| Extension | Content | Install |
|---|---|---|
| Luna IntelliSense | Providers, completions, diagnostics | Core (always) |
| Luna Editors | 29 webview editors | Optional |
| Luna Debug | Debug adapter, bridge, watchers | Optional |
| Luna AI | CAG layer, MCP, game-dev agents | Optional |
| Luna Visual Scripting | Block editor, compiler | Optional |

**Benefits**: Faster activation for users who don't need all features. Smaller bundle per extension.

### 10. Documentation for Extension Development

**Gap**: No contributor docs for the extension.

**Needed**:
- `CONTRIBUTING.md` in vscode-extension/
- How to set up development environment
- How to debug the extension
- How to add a new provider
- How to add a new editor
- How to add a new MCP tool
- Architecture diagram
- Testing guide
