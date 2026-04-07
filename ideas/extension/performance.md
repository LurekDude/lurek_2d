# Extension Performance Analysis

## Current State

The extension registers 90+ commands, 22 providers, 4 sidebar views, and 29 editors at activation time.
No performance profiling has been documented.

---

## Concerns

### 1. Activation Time

**Risk**: Loading 90+ commands, 22 provider modules, and initializing services at activation could delay VS Code startup.

**Current activation events** (from package2.json):
- `workspaceContains:**/main.lua` — may trigger on any workspace with a `main.lua`
- `workspaceContains:Cargo.toml` — triggers on ANY Rust project, not just Luna2D
- `onLanguage:lua` — triggers when any Lua file is opened

**Issues**:
- `workspaceContains:Cargo.toml` is too broad — activates for all Rust projects
- All imports are top-level static imports in extension2.ts — no lazy loading

**Improvements**:
- Change activation to `workspaceContains:conf.lua` (specific to Luna2D games)
- Keep `workspaceContains:Cargo.toml` but check for `luna2d` in dependencies before full activation
- Dynamic import for editor modules (load only when editor command is invoked)
- Measure activation time with `vscode.window.withProgress`

### 2. Provider Performance

**Completion provider** (~600 lines):
- Document cache with version tracking ✅ (good)
- May reparse on every keystroke — needs debouncing
- 25+ static builtins + dynamic API data → potential large completion list

**Diagnostics provider** (~400 lines):
- Has 300ms debounce ✅ (good)
- 9 diagnostic rules run sequentially — could parallelize
- `checkAssetNotFound` may scan filesystem on every save

**Type inference** (~400 lines):
- Runs on document change — could be expensive for large files

**Improvements**:
- Add completion result caching (reuse if document hasn't changed)
- Rate-limit diagnostic runs for large files (>1000 lines: increase debounce to 500ms)
- Cache asset file list instead of scanning filesystem per diagnostic run
- Use incremental parsing in luaParser.ts (only reparse changed regions)
- Profile provider response times in debug mode

### 3. Memory Usage

**Potential issues**:
- `apiData.ts` loads entire API surface into memory at activation
- `symbolIndex.ts` indexes all symbols workspace-wide
- `luaParser.ts` may cache parsed ASTs for every open document
- System monitor polls every few seconds, accumulating history (120 samples)
- 29 editor webviews could each consume significant memory if opened

**Improvements**:
- LRU cache for parsed documents (evict after N documents)
- Lazy-load API data (only load modules that are referenced in open files)
- Limit webview count (warn after 3 editors open, suggest closing unused)
- Monitor extension memory usage in status bar (debug mode)

### 4. File System Operations

**Current FS operations**:
- Asset path resolution scans game directories
- Require graph builds dependency tree by reading all .lua files
- Circular dependency finder reads all mod.rs files
- Scaffold commands write multiple files

**Improvements**:
- Use VS Code FileSystemWatcher instead of manual scanning
- Cache dependency graph — rebuild only when files change
- Use workspace.findFiles() with exclude patterns to skip node_modules, build/

### 5. Webview Performance

**29 editors create webviews** with embedded HTML/CSS/JS.

**Potential issues**:
- Large canvas-based editors (tile map, pixel art) may struggle with big maps
- No virtualization for large data sets (database browser with many records)
- HTML templates are rebuilt entirely on state change (no virtual DOM)

**Improvements**:
- Implement viewport-based rendering for canvas editors (only draw visible tiles)
- Paginate large data sets in database browser and API reference
- Use `postMessage` for incremental updates instead of full HTML rebuild
- Add loading indicators for slow operations
- Consider using a lightweight framework (Preact) for complex editors

### 6. Build System Performance

**Current**: Uses `tsc` compiler.

**Planned**: `esbuild` bundler (from architecture doc).

**Impact of switching to esbuild**:
- Build time: tsc ~5-10s → esbuild ~100ms
- Output size: tsc preserves module structure → esbuild single bundle
- Tree shaking: esbuild removes unused code
- Source maps: both support them

**Recommendation**: Switch to esbuild for faster dev cycles and smaller bundle.

### 7. Extension Bundle Size

**Concern**: 29 editor files + 22 providers + 11 commands + services + MCP ≈ large bundle.

**Improvements**:
- Use esbuild with tree shaking to eliminate dead code
- Split editors into separate chunks (load on demand)
- Minify HTML templates inside editor files
- Consider whether all 29 editors need to ship — could some be in a separate "Luna Editors Pack" extension?

---

## Performance Monitoring Ideas

### 1. Activation Time Telemetry
- Log time from `activate()` call to all providers registered
- Break down: API data load, provider registration, sidebar setup, command registration

### 2. Provider Latency Tracking
- Measure each provider's response time
- Log slow responses (>100ms for completion, >200ms for diagnostics)
- Surface in the Performance Dashboard

### 3. Memory Budget
- Set a memory budget for the extension (e.g., 100MB)
- Monitor and alert when approaching budget
- Profile which component uses the most memory

### 4. Startup Profiling Command
- `luna.perf.profileStartup` — restart extension with timing enabled
- Show waterfall chart of component initialization
