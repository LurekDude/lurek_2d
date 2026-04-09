# `devtools` — Full Specification

| Property         | Value                                                  |
|------------------|--------------------------------------------------------|
| **Tier**         | Tier 1 — Core Engine Subsystems                        |
| **Status**       | Implemented — Full                                     |
| **Lua API**      | `lurek.devtools`                                        |
| **Source**       | `src/devtools/`                                        |
| **Rust Tests**   | `tests/rust/unit/devtools_tests.rs`                    |
| **Lua Tests**    | `tests/lua/unit/test_devtools.lua`                     |
| **Architecture** | —                                                      |

## Summary

The `devtools` module is the **engine and game diagnostics toolkit** for engine developers and advanced game developers who need deep runtime visibility. It gives Lua scripts access to structured runtime monitoring and performance analysis capabilities that go beyond simple logging — without requiring any external profiling tools or IDE debugger.

This module is gated by `modules.debug = true` in `conf.lua` and is NOT available in release builds where that flag is false. It is intended for development and profiling workflows, not for production game logic.

The module contains four orthogonal components:

> **Ownership Rule — frame statistics**: Use `lurek.time.getDelta()`, `lurek.time.getFps()`, and `lurek.time.getAverageDelta()` for basic per-frame timing (zero setup — `timer::Clock` is auto-ticked by the engine). Use `lurek.devtools.frameStats:record(dt)` + `frameStats:snapshot()` only when p50/p95/p99 **percentile analysis** is needed.

1. **Logger** — A ring-buffer log history with `LogLevel` (Trace/Debug/Info/Warn/Error/Fatal) filtering, optional per-entry category tags, and source file/line capture. Entries are stored in memory for in-game display panels and can be filtered or cleared at runtime. The logger does NOT write to files itself; it delegates physical output to the Rust `log` facade.

2. **Profiler** — A hierarchical push/pop zone profiler that records start/end timestamps for named CPU regions. Each frame's zones form a tree (via nested push calls). The last N frames are retained for rolling display in an in-game profiler panel. It gracefully handles unbalanced push/pop by producing zero-duration zones.

3. **FrameStats** — A circular buffer of per-frame delta times that provides FPS, min/max, average, and p50/p95/p99 percentiles via `snapshot()`. All statistics are computed lazily from the raw sample buffer — no running state to corrupt.

4. **FileWatcher** — A polling-based path watcher that compares `std::fs::metadata` modification timestamps between polls. It produces a list of changed paths on each `poll()` call, enabling hot-reload patterns. The polling interval is controlled entirely by the caller; the module provides no background threads.

All four types are **pure Rust** with no mlua dependency. All Lua plumbing lives in `src/lua_api/devtools_api.rs`.

This module intentionally does **not** provide:
- Physical file logging (use the `log` crate with `env_logger`)
- Visual profiler rendering (render the data with `lurek.gfx` in game code)
- Filesystem events (OS-level inotify/FSEvents — polling only)
- Network inspection or memory allocation tracking
- Frame-timing basics — those come from `timer::Clock` via `lurek.time` (auto-ticked, no setup)

## Architecture

```
src/devtools/
├── mod.rs          re-exports Logger, Profiler, FrameStats, FileWatcher, ProfileZone, LogLevel, LogEntry, FrameSnapshot
├── logger.rs       LogLevel enum + LogEntry struct + Logger ring-buffer
├── profiler.rs     ProfileZone struct (tree-buildable) + Profiler push/pop/end_frame
├── frame_stats.rs  FrameStats rolling buffer + FrameSnapshot computed view
└── watcher.rs      FileWatcher mtime-polling map

src/lua_api/
└── devtools_api.rs  Thin Lua bridge — DevtoolsShared, zone_to_table helper
```

Data flow:
```
Lua: lurek.devtools.logger:push(level, msg)
  → DevtoolsShared.logger.push()
  → Logger.history Vec<LogEntry>

Lua: lurek.devtools.profiler:push("zone_name")
  → DevtoolsShared.profiler.push()
  → Profiler.current_stack Vec<ProfileZone>

Lua: lurek.devtools.profiler:endFrame()
  → profiler.end_frame()
  → stores Vec<ProfileZone> in profiler.frames ring buffer

Lua: lurek.devtools.frameStats:record(dt)
  → FrameStats.samples VecDeque<f64>

Lua: lurek.devtools.watcher:poll()
  → FileWatcher iterates HashMap<PathBuf, Option<SystemTime>>
  → returns changed paths as Lua array
```

## Source Files

| File              | Purpose                                                                         |
|-------------------|---------------------------------------------------------------------------------|
| `logger.rs`       | `Logger`, `LogEntry`, `LogLevel` — structured log buffer with level and category |
| `profiler.rs`     | `Profiler`, `ProfileZone` — hierarchical CPU-time zone profiler across frames   |
| `frame_stats.rs`  | `FrameStats`, `FrameSnapshot` — circular frame-time buffer with percentile stats |
| `watcher.rs`      | `FileWatcher` — path modification time polling for hot-reload detection         |
| `mod.rs`          | Re-exports all public types                                                     |

## Submodules

### `devtools::logger`

- `LogLevel` enum: `Trace`, `Debug`, `Info`, `Warn`, `Error`, `Fatal`
- `LogEntry` struct: `level`, `timestamp`, `message`, `source`, `line`, `category`
- `Logger` struct: ring-buffer of `LogEntry` with `min_level` filter

### `devtools::profiler`

- `ProfileZone` struct: `name`, `start_time`, `end_time`, `children: Vec<ProfileZone>`
- `Profiler` struct: active stack + completed frames ring buffer

### `devtools::frame_stats`

- `FrameStats` struct: `VecDeque<f64>` circular sample buffer
- `FrameSnapshot` struct: `fps`, `dt`, `avg`, `min`, `max`, `p50`, `p95`, `p99`, `samples`

### `devtools::watcher`

- `FileWatcher` struct: `HashMap<PathBuf, Option<SystemTime>>` path watch table

## Key Types

### Structs

#### `devtools::logger::Logger`
Ring-buffer log store. Call `push(level, msg, source, line, category)` to append. `tail(n)` returns the last N entries. `filter_category(cat)` returns entries with a matching category name. `clear()` empties the history.

**Public fields:** `min_level: LogLevel`, `console_enabled: bool`, `log_file: String`, `history: Vec<LogEntry>`, `max_history: usize`

#### `devtools::logger::LogEntry`
A single log record. Holds `level`, `timestamp` (seconds as `f64`), `message`, `source` file path, `line` number, and optional `category`.

#### `devtools::profiler::Profiler`
Push/pop zone profiler. `push(name)` starts a zone; `pop()` ends the innermost open zone. `end_frame()` finalises the current frame and appends it to the frames ring. `get_frame(idx)` returns frame N (0 = oldest, -1 = newest). `reset()` clears all frames.

**Public fields:** `enabled: bool`, `frames: Vec<Vec<ProfileZone>>`, `max_frames: usize`

#### `devtools::profiler::ProfileZone`
One timed region. `total_time()` returns `end - start` including children. `self_time()` subtracts child time. `flatten()` returns all descendant zones in a flat list.

#### `devtools::frame_stats::FrameStats`
Rolling delta-time store. `record(dt)` appends a sample (drops oldest when at capacity). `set_capacity(n)` resizes the buffer. `snapshot()` computes and returns a `FrameSnapshot`.

#### `devtools::frame_stats::FrameSnapshot`
Immutable statistics computed from the sample buffer at snapshot time. Fields: `fps`, `dt`, `avg`, `min`, `max`, `p50`, `p95`, `p99`, `samples: usize`.

#### `devtools::watcher::FileWatcher`
Polling file-change detector. `watch(path)` adds a path. `unwatch(path)` removes it. `poll()` returns a `Vec<String>` of changed paths since the last poll. `clear()` removes all watched paths.

**Public field:** `paths: HashMap<PathBuf, Option<SystemTime>>`

### Enums

#### `devtools::logger::LogLevel`
`Trace | Debug | Info | Warn | Error | Fatal`. Implements `PartialOrd` for `min_level` filtering. `from_str(s)` and `as_str()` for Lua interop.

## Lua API

The Lua API is registered in `src/lua_api/devtools_api.rs` under `lurek.devtools.*`.

A `DevtoolsShared` bridge struct holds Arc-cloned domain types so all Lua closures share the same instances. A separate `zone_to_table` helper recursively converts `ProfileZone` trees to Lua tables.

| Function | Signature | Description |
|---|---|---|
| `lurek.devtools.logger` | UserData | Shared `Logger` instance |
| `logger:push(level, msg, src?, line?, cat?)` | — | Append a log entry |
| `logger:tail(n)` | `→ table` | Last N entries as array of tables |
| `logger:filterCategory(cat)` | `→ table` | Entries matching category |
| `logger:clear()` | — | Empty the log history |
| `logger:setMinLevel(level)` | — | Set minimum level string |
| `logger:getMinLevel()` | `→ string` | Current minimum level |
| `lurek.devtools.profiler` | UserData | Shared `Profiler` instance |
| `profiler:push(name)` | — | Begin a named zone |
| `profiler:pop()` | — | End the innermost zone |
| `profiler:endFrame()` | — | Commit current frame |
| `profiler:getFrame(idx)` | `→ table` | Frame zones as nested table |
| `profiler:frameCount()` | `→ int` | Number of retained frames |
| `profiler:reset()` | — | Clear all retained frames |
| `lurek.devtools.frameStats` | UserData | Shared `FrameStats` instance |
| `frameStats:record(dt)` | — | Append a frame delta time |
| `frameStats:snapshot()` | `→ table` | Compute stats snapshot |
| `frameStats:setCapacity(n)` | — | Resize sample window |
| `lurek.devtools.watcher` | UserData | Shared `FileWatcher` instance |
| `watcher:watch(path)` | — | Start watching a path |
| `watcher:unwatch(path)` | — | Stop watching a path |
| `watcher:poll()` | `→ table` | Array of changed paths |
| `watcher:watchedPaths()` | `→ table` | All currently watched paths |
| `watcher:clear()` | — | Remove all watch entries |

## Lua Examples

```lua
-- === Logger ===
local log = lurek.devtools.logger
log:setMinLevel("debug")
log:push("info", "Game loaded", "main.lua", 1, "boot")
log:push("warn", "Missing sprite atlas", "sprites.lua", 42)

local recent = log:tail(5)
for _, entry in ipairs(recent) do
    print(entry.level, entry.message)
end

-- === Profiler ===
local prof = lurek.devtools.profiler

lurek.process = function(dt)
    prof:push("update")
        prof:push("physics")
        prof:pop()
        prof:push("ai")
        prof:pop()
    prof:pop()
    prof:endFrame()
end

lurek.render = function()
    local frame = prof:getFrame(-1) -- last frame
    if frame then
        for _, zone in ipairs(frame) do
            print(zone.name, zone.total_time)
        end
    end
end

-- === FrameStats ===
local stats = lurek.devtools.frameStats
stats:setCapacity(120)

lurek.process = function(dt)
    stats:record(dt)
end

lurek.render = function()
    local snap = stats:snapshot()
    print(string.format("FPS: %.1f  p95: %.2fms", snap.fps, snap.p95 * 1000))
end

-- === FileWatcher (hot-reload) ===
local watcher = lurek.devtools.watcher
watcher:watch("scripts/game.lua")
watcher:watch("data/weapons.json")

lurek.process = function(dt)
    local changed = watcher:poll()
    for _, path in ipairs(changed) do
        print("Reloading:", path)
    end
end
```

## Item Summary

| Kind      | Count |
|-----------|-------|
| `struct`  | 8     |
| `enum`    | 1     |
| `fn`      | 24+   |
| **Total** | **33+** |

## Live Watches — `exposeWatch` / `getWatches`

Live watches let scripts register named getter functions that can be sampled on demand by an in-game overlay, the VS Code extension, or a `snapshot()` call. Each getter is stored as a `LuaRegistryKey` in `devtools_api.rs`.

| Function | Signature | Description |
|---|---|---|
| `exposeWatch(name, fn, category?)` | `(string, function, string?) → integer` | Registers a getter; returns a sequential id. |
| `removeWatch(id)` | `(integer) → boolean` | Removes the watch with the given id. |
| `getWatches()` | `() → table` | Samples all getters. Returns `{name, category, value}[]`. |

### `WatchEntry` (internal, `devtools_api.rs`)

```rust
struct WatchEntry {
    name:     String,
    getter:   LuaRegistryKey,
    category: String,
}
```

Stored as `Vec<WatchEntry>` in `DevtoolsShared`. The `next_watch_id: u64` field is incremented on each `exposeWatch` call. Removal uses the offset from `(next_watch_id - watches.len())`.

## Snapshot — `snapshot()`

`snapshot()` captures a point-in-time diagnostic dump as a plain Lua table. All fields are present even if empty.

| Field | Type | Description |
|---|---|---|
| `watches` | `{name, category, value}[]` | All registered watches sampled at call time |
| `frameStats` | `{fps, dt, avg, p95, p99}` | Last `FrameStats` snapshot |
| `profile` | `table` | Last profiler frame zones (may be empty) |
| `log` | `{level, message, source}[]` | Last 10 devtools log entries |
| `watchCount` | integer | Total registered watch count |

The snapshot table is a plain Lua value — easily serialised with `lurek.data.encode("json", snap)` for crash reports or external tools.

```lua
local snap = lurek.devtools.snapshot()
lurek.log.info(string.format("snapshot: %d watches, fps=%.1f", snap.watchCount, snap.frameStats.fps))
```

## References

| Module       | Relationship | Notes                                      |
|--------------|--------------|--------------------------------------------|
| `engine`     | Imports from | `SharedState` used in `devtools_api.rs` only |
| `lua_api`    | Imported by  | `devtools_api.rs` registers the Lua surface |
| `graphics`   | —            | Rendering profiler data is left to game scripts |
| `vscode-extension` | Consumer | `snapshot()` output compatible with extension devtools panel |

## Notes

- `Profiler::push`/`pop` must be balanced per frame; unbalanced calls produce zero-duration zones rather than panics.
- `FileWatcher::poll()` uses `std::fs::metadata` which is blocking — avoid watching hundreds of paths on a slow filesystem.
- `Logger` is not thread-safe; it is owned by the main Lua VM thread only.
- Watch getter functions must not error — errors are silently turned into `nil` values in `getWatches()` output.
- All four types are deliberately independent — you can use `FrameStats` without `Logger` etc.
- The module is gated by `modules.debug`; ship builds should set this to `false`.
