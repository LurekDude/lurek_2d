# MCP Server Analysis

## Current State

### Implementation

| File | Content |
|---|---|
| mcp/server.ts | JSON-RPC 2.0 server, in-process + stdio modes |
| mcp/tools.ts | 4 tool definitions |

### Implemented Tools

| Tool | Description | Status |
|---|---|---|
| luna2d.runExample | Run a demo/example | ✅ Real |
| luna2d.getApiDoc | Get API documentation | ✅ Real |
| luna2d.listExamples | List available examples | ✅ Real |
| luna2d.runLuaTest | Run a Lua test file | ✅ Real |

### Documented Tools (04-commands-features.md)

| Tool | Documented | Implemented |
|---|---|---|
| runExample | ✅ | ✅ |
| getApiDoc | ✅ | ✅ |
| listExamples | ✅ | ✅ |
| runLuaTest | ✅ | ✅ |
| getModuleInfo | ✅ | ❌ Missing |
| inspectLuaFile | ✅ | ❌ Missing |
| generateTest | ✅ | ❌ Missing |
| getTestCoverage | ✅ | ❌ Missing |
| scaffoldProject | ✅ | ❌ Missing |
| runDiagnostics | ✅ | ❌ Missing |

**60% of planned MCP tools are not implemented.**

---

## Improvement Ideas

### 1. Complete the Planned Tools

**getModuleInfo**: Return module structure information.
```json
{
  "name": "getModuleInfo",
  "inputSchema": { "moduleName": "string" },
  "output": { "tier": "number", "files": ["string"], "dependencies": ["string"], "luaApi": ["string"] }
}
```

**inspectLuaFile**: Parse a Lua file and return its structure.
```json
{
  "name": "inspectLuaFile",
  "inputSchema": { "filePath": "string" },
  "output": { "functions": [...], "requires": [...], "globals": [...], "callbacks": [...] }
}
```
Already has the parser (services/luaParser.ts) — just needs a tool wrapper.

**generateTest**: Generate test scaffolding for a Lua file.
```json
{
  "name": "generateTest",
  "inputSchema": { "filePath": "string", "testType": "unit|integration" },
  "output": { "testCode": "string", "testPath": "string" }
}
```

**getTestCoverage**: Return API test coverage data.
```json
{
  "name": "getTestCoverage",
  "inputSchema": { "module": "string?" },
  "output": { "total": "number", "covered": "number", "uncovered": ["string"] }
}
```

**scaffoldProject**: Create a new project from template.
```json
{
  "name": "scaffoldProject",
  "inputSchema": { "template": "string", "name": "string", "path": "string" },
  "output": { "filesCreated": ["string"] }
}
```

**runDiagnostics**: Run extension diagnostics on a file.
```json
{
  "name": "runDiagnostics",
  "inputSchema": { "filePath": "string" },
  "output": { "diagnostics": [{ "line": "number", "message": "string", "severity": "string" }] }
}
```

### 2. New MCP Tools for AI Agents

Additional tools that would help Copilot and other AI assistants:

| Tool | Purpose |
|---|---|
| `getEngineArchitecture` | Return tier structure, module boundaries, dependency rules |
| `getApiFunction` | Detailed info for a specific luna.* function |
| `searchApiByKeyword` | Fuzzy search across all luna.* APIs |
| `getActiveSceneInfo` | Return current game state (via debug bridge) |
| `getEntityList` | List all entities in running game |
| `runEngineCommand` | Execute a Rust/Lua engine command |
| `getProjectStructure` | Return game project file tree |
| `validateLuaCode` | Check Lua code for common errors |
| `getDependencyGraph` | Return module dependency graph |
| `getBuildStatus` | Return last cargo build/test/clippy result |
| `getAssetList` | List all game assets with metadata |
| `getPerformanceData` | Return FPS, memory, frame time from running game |

### 3. MCP Server Architecture Improvements

**Current**: In-process handler with stdio fallback.

**Improvements**:
- **Separate process**: Run MCP server as a standalone Node.js process for stability
- **WebSocket transport**: Add WebSocket support for browser-based clients
- **Authentication**: Add token-based auth for remote connections
- **Rate limiting**: Prevent DOS from rapid tool calls
- **Logging**: Structured logging for debugging tool invocations
- **Health check**: Endpoint to verify server is alive

### 4. Tool Response Enrichment

**Current**: Tools return basic text responses.

**Improvements**:
- Return structured JSON with consistent schema
- Include metadata (execution time, data freshness)
- Include hyperlinks to relevant files
- Include suggested next actions
- Cache responses for frequently requested data

### 5. Streaming Tool Responses

For long-running tools (running tests, building):
- Stream progress updates
- Show partial results as they become available
- Allow cancellation
- Show estimated completion time

### 6. MCP ↔ Debug Bridge Integration

Connect MCP tools to the debug bridge for live game inspection:
- `evaluateLua` tool → sends to debug bridge → returns result
- `takeScreenshot` tool → triggers screenshot → returns image path
- `getGameState` tool → queries running game for all global state
- `hotReloadFile` tool → triggers file reload in running game

### 7. MCP Tool Testing

**No tests exist for MCP tools.**

Test plan:
1. Unit tests for each tool handler
2. Integration tests with mock VS Code workspace
3. Protocol compliance tests (JSON-RPC 2.0)
4. Error handling tests (invalid input, missing files, permission errors)
5. Performance tests (response time < 200ms for simple queries)

### 8. Tool Discovery Metadata

**Improvement**: Add rich metadata for AI assistants:
```json
{
  "name": "luna2d.getApiDoc",
  "description": "Get Luna2D API documentation for a specific function or namespace",
  "hints": ["Use when user asks about luna.* API", "Returns complete parameter info"],
  "examples": [
    { "input": { "query": "luna.graphics.circle" }, "output": "..." }
  ],
  "category": "documentation"
}
```
