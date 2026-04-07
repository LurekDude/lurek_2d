# Debug System Analysis

## Current State

The extension has **two separate debug systems** — one documented, one undocumented:

### 1. Debug Bridge (Documented in 04-commands)

| Component | File | Purpose |
|---|---|---|
| Service | services/debugBridge.ts | TCP socket to running game (port 19740) |
| Commands | commands/debugBridge.ts | 12+ debug commands |
| Protocol | JSON-RPC over TCP | Evaluate, inspect, hot-reload, screenshot |

**Implementation depth**: Real. TCP socket management, request/response queue, per-request timeouts, JSON message parsing, output channel logging, status bar stats.

### 2. VS Code Debug Adapter Protocol (NOT in docs)

| Component | File | Purpose |
|---|---|---|
| Adapter factory | debug/luaDebugAdapter.ts | DAP session creation |
| Debug session | debug/luaDebugSession.ts | DAP protocol handling |

**Implementation depth**: Real but minimal. LuaDebugAdapterFactory, LuaDebugConfigurationProvider with 2 launch modes (launch + attach on port 8172). The DAP integration means the standard VS Code debug panel (breakpoints, call stack, variables, watch) can work.

---

## Gap Analysis

### Debug Bridge vs DAP

| Feature | Debug Bridge | DAP |
|---|---|---|
| **Architecture** | Custom TCP + JSON-RPC | VS Code standard protocol |
| **Port** | 19740 | 8172 |
| **Breakpoints** | Not supported | Standard VS Code breakpoints |
| **Call stack** | Manual command | Automatic in debug panel |
| **Watch variables** | Custom watchers panel | Standard VS Code watch |
| **Step debug** | Not supported | Step in/over/out |
| **Hot reload** | ✅ Supported | Not built-in |
| **Evaluate Lua** | ✅ Supported | Via debug console |
| **Screenshot** | ✅ Supported | Not built-in |
| **Performance data** | ✅ FPS/frame time | Not built-in |
| **Integration** | Sidebar commands | F5 workflow |

### Key Overlap

Both systems can:
- Connect to a running game
- Evaluate Lua expressions
- Inspect variables

But they use different ports, different protocols, and different UI paradigms.

---

## Improvement Ideas

### 1. Unify Debug Systems

**Problem**: Two overlapping debug systems confuse developers. "Do I use Debug Bridge or F5?"

**Solution**:
- Make DAP the primary debug interface (breakpoints, step, variables)
- Make Debug Bridge a DAP extension that adds game-specific features
- Single port, single connection, single UI
- Debug Bridge commands become DAP custom requests

### 2. Engine-Side Debug Server

**Prerequisite**: The Luna2D engine needs a server-side component to accept debug connections.

**Current engine state**: No TCP debug server in `src/`. The Debug Bridge requires an engine counterpart.

**Action items**:
- Implement `src/debug_bridge/` module in the engine (Tier 1)
- TCP listener on configurable port
- JSON-RPC handler for: evaluate, inspect, setBreakpoint, getCallStack, hotReload, screenshot, performance
- Lua debug hooks for breakpoint/step support
- Must not impact game performance when debugger is not connected

### 3. Hot-Reload Improvements

**Current**: Extension watches *.lua files and can trigger reload via Debug Bridge.

**Improvements**:
- Show changed function list before reloading
- Selective reload (only changed modules)
- State preservation across reloads (serialize global state, reload, restore)
- Error recovery (if reloaded code crashes, roll back)
- Visual diff in extension showing what changed

### 4. Live Performance Overlay

**Current**: `perfDashboard.ts` shows FPS/frame/memory in a webview panel.

**Improvements**:
- Real-time streaming from engine (not polling)
- Frame time breakdown: Lua update, Lua draw, GPU render, physics step
- Memory breakdown: Lua heap, textures, audio buffers, physics
- Alert thresholds: flash when FPS drops below 60, memory exceeds limit
- Export performance data for offline analysis
- Flame chart for per-function timing

### 5. Debug Watchers Enhancement

**Current**: `debugWatchers.ts` provides a watch expression panel.

**Improvements**:
- Auto-watch: automatically watch variables in scope at breakpoint
- Conditional watches: only evaluate when expression is truthy
- Watch history: show how a value changed over time (graph)
- Table drill-down: expand table values inline
- Entity inspector: show all components of a selected entity

### 6. Variable Inspector Enhancement

**Current**: Inline webview in extension2.ts with expression evaluation.

**Improvements**:
- Type-specific rendering (Vec2 → show as (x, y), Color → show color swatch)
- Table structure explorer (tree view)
- Linked to game entities (click entity in game → inspect in extension)
- Support modifying values at runtime

### 7. Conditional Breakpoints

**Standard DAP feature** but needs engine support:
- Break when `player.health < 10`
- Break on Nth hit of a line
- Break on specific event (`keypressed("space")`)
- Logpoints: log without stopping

### 8. Launch Configuration Templates

**Improvement**: Provide `.vscode/launch.json` templates:
```json
{
  "type": "luna",
  "request": "launch",
  "name": "Run Game",
  "program": "${workspaceFolder}",
  "luaVersion": "luajit"
}
```
- Auto-detect game directory
- Support running specific demo or example
- Support command-line arguments
- Support environment variables (RUST_LOG)

### 9. Debug Bridge Protocol Documentation

**The Debug Bridge protocol (JSON-RPC messages) should be formally documented**:
- Request/response schemas
- Error codes
- Capability negotiation
- Version compatibility
- This enables third-party tools to connect

### 10. Multi-VM Debugging

**Luna2D supports worker threads** (B-04), each with its own Lua VM.

**Improvement**:
- Show all active Lua VMs in debug panel
- Switch between VMs
- Set breakpoints in worker thread code
- Watch Channel messages between VMs
- Debug thread synchronization issues
