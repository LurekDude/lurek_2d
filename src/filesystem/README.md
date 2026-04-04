# `src/filesystem/` — Sandboxed Virtual Filesystem

## Purpose

All game I/O is routed through `GameFS` to enforce sandboxing — games can only
read/write within their own directory and a designated save directory. Prevents
path traversal attacks and unauthorized file access.

## Architecture

```
GameFS (sandbox root = game directory)
  │
  ├── Read sandbox ─── any path under base_dir/
  │     ├── resolve_read_path() → canonicalize + starts_with(base) guard
  │     ├── read_string(path) → UTF-8 file contents
  │     ├── read_bytes(path) → raw Vec<u8>
  │     ├── exists() / is_file() / is_directory()
  │     ├── list() / get_directory_items()
  │     └── get_info() → FileInfo { type, size, mtime, readonly }
  │
  ├── Write sandbox ── only base_dir/save/ subdirectory
  │     ├── resolve_save_path() → starts_with(save/) + no ".." guard
  │     ├── write_string(path, content)
  │     ├── append_string(path, content)
  │     ├── create_directory(path)
  │     └── remove(path) — file or empty directory
  │
  ├── FileHandle ── buffered file I/O with open/read/write/seek/close
  │     ├── Read mode → BufReader<File>
  │     ├── Write mode → BufWriter<File> (truncate)
  │     └── Append mode → BufWriter<File> (append)
  │
  └── AsyncLoader ── background thread for non-blocking file reads
        ├── SyncSender<LoadRequest> → worker thread (bounded queue, 64 slots)
        ├── Arc<Mutex<HashMap>> ← completed results
        └── poll(handle) → Pending | Done(Ready(bytes) | Error(msg))
```

### Security Model

The filesystem uses a **dual-sandbox design** with separate read and write boundaries:

| Operation | Allowed area | Validation |
|-----------|-------------|------------|
| Read | Anywhere under `base_dir/` | `canonicalize()` + `starts_with(base_canonical)` |
| Write | Only `base_dir/save/` | Logical prefix check + `..` component rejection |
| Delete | Only `base_dir/save/` | Same as write |

**Path traversal prevention** is layered:
1. **Canonicalization** — `std::fs::canonicalize()` resolves symlinks and `..` to an absolute path.
2. **Prefix check** — The canonical path must `starts_with()` the canonical base directory.
3. **Component scan** — Write paths are also scanned for `ParentDir` components as a belt-and-suspenders defense.
4. **No raw paths** — The engine never passes user-supplied paths directly to `std::fs`; everything routes through `resolve_read_path()` or `resolve_save_path()`.

### Dependency Direction

```
filesystem/ ──────► engine::error (EngineError, EngineResult)
```

Only depends on the engine error types. No other Luna2D module dependencies.
**Leaf module** — standalone filesystem with security-first design.

---

## File-by-File Analysis

### `mod.rs` — Module Root

Re-exports all public types from the three sub-modules. This is the single import
point for the rest of the engine:

```rust
pub use async_loader::{AsyncLoader, LoadHandle, LoadResult, LoadStatus};
pub use file_handle::{FileHandle, FileMode};
pub use vfs::{FileInfo, FileType, GameFS};
```

**13 lines** — pure wiring, no logic.

---

### `vfs.rs` — `GameFS` (Virtual Filesystem Sandbox)

**~340 lines** | Core sandbox implementation. All filesystem operations in Luna2D
ultimately route through this struct.

#### Struct: `GameFS`

```rust
pub struct GameFS {
    base_dir: PathBuf,    // game root directory (set at startup)
    identity: String,     // game name for save directory naming
}
```

#### Path Resolution (the security core)

Two internal methods form the security boundary:

| Method | Purpose | Guards |
|--------|---------|--------|
| `resolve_read_path(path)` | Map logical path → absolute path for reading | `canonicalize()` + `starts_with(base_canonical)` |
| `resolve_save_path(path)` | Map logical path → absolute path for writing | `starts_with(save/)` + `ParentDir` component scan |

**Why two methods?** Reads can access the entire game directory (assets, scripts, data),
but writes are confined to `save/` to prevent scripts from corrupting game assets or
writing outside the sandbox.

**Note on `resolve_save_path`**: Uses a logical prefix check (`full.starts_with(&save_dir)`)
rather than canonicalization because the target file may not exist yet (can't canonicalize
non-existent paths). The `..` component scan compensates for this.

#### Read Operations

| Method | Returns | Notes |
|--------|---------|-------|
| `read_string(path)` | `EngineResult<String>` | UTF-8 decoding, full sandbox check |
| `read_bytes(path)` | `EngineResult<Vec<u8>>` | Raw bytes, full sandbox check |
| `exists(path)` | `bool` | Simple existence check (no canonicalization) |
| `is_file(path)` | `bool` | Via `resolve_read_path` |
| `is_directory(path)` | `bool` | Via `resolve_read_path` |
| `list(path)` | `EngineResult<Vec<String>>` | Unsorted entry names |
| `get_directory_items(path)` | `EngineResult<Vec<String>>` | **Sorted** entry names (via `resolve_read_path`) |
| `get_info(path)` | `EngineResult<FileInfo>` | Type, size, mtime, readonly |

**Design note**: Both `list()` and `get_directory_items()` exist — `list()` is simpler
(direct `base_dir.join`) while `get_directory_items()` goes through `resolve_read_path()`
for full sandbox validation and returns sorted results. Prefer `get_directory_items()`.

#### Write Operations

| Method | Behavior | Auto-creates dirs? |
|--------|----------|-------------------|
| `write_string(path, content)` | Truncate and write | Yes |
| `append_string(path, content)` | Append to file (creates if missing) | Yes |
| `create_directory(path)` | `create_dir_all` inside save/ | Yes (recursive) |
| `remove(path)` | Delete file or **empty** directory | No |

All write operations enforce the `save/` prefix rule.

#### Path Utilities

| Method | Returns |
|--------|---------|
| `get_source()` | Absolute path of game root as `String` |
| `get_save_directory()` | `PathBuf` to `base_dir/save/` |
| `get_working_directory()` | Process CWD (static method) |
| `get_user_directory()` | `USERPROFILE` (Windows) or `HOME` (Unix) |
| `get_identity()` / `set_identity()` | Game identity string for save naming |

**Platform-specific**: `get_user_directory()` uses `#[cfg(target_os = "windows")]`
for `USERPROFILE` vs `HOME` on Unix. Falls back to CWD on failure.

---

### `file_handle.rs` — `FileHandle` (Buffered File I/O)

**~310 lines** | Provides Lua-friendly file handles with open/read/write/seek/close
lifecycle, backed by `BufReader`/`BufWriter` from `std::io`.

#### Struct: `FileHandle`

```rust
pub struct FileHandle {
    mode: FileMode,                         // Read | Write | Append | Closed
    path: PathBuf,                          // resolved absolute path
    logical_path: String,                   // original relative path (for errors)
    reader: Option<BufReader<std::fs::File>>,
    writer: Option<BufWriter<std::fs::File>>,
    size: u64,                              // cached at open time
}
```

**Mutual exclusion**: A handle is either reading **or** writing, never both. The
`reader` and `writer` fields are `Option<>` — exactly one is `Some` at any time.

#### Enum: `FileMode`

```
Read ─── open existing file, BufReader
Write ── create or truncate, BufWriter
Append ─ create or append, BufWriter (OpenOptions.append(true))
Closed ─ handle released, all operations return errors
```

`FileMode::parse_mode("r"/"w"/"a")` converts Lua mode strings.

#### Open Behavior by Mode

| Mode | Sandbox check | File creation | Truncate? |
|------|--------------|---------------|-----------|
| Read | `resolve_read_path` (entire game dir) | No (file must exist) | No |
| Write | `resolve_save_path` (save/ only) | Yes + auto-create parent dirs | Yes |
| Append | `resolve_save_path` (save/ only) | Yes + auto-create parent dirs | No |

#### I/O Methods

| Method | Signature | Notes |
|--------|-----------|-------|
| `read(count)` | `Option<usize> → Vec<u8>` | `None` = read all remaining bytes |
| `read_line()` | `→ Option<String>` | Strips `\r\n` / `\n`, returns `None` at EOF |
| `write(data)` | `&[u8] → usize` | Returns bytes written |
| `seek(pos)` | `u64 → u64` | Absolute position from start |
| `tell()` | `→ u64` | Current stream position |
| `flush()` | `→ ()` | Flushes BufWriter to disk |
| `close()` | `→ ()` | Flushes then drops reader/writer, sets mode to Closed |
| `is_eof()` | `→ bool` | Uses `BufReader::fill_buf()` to peek without consuming |
| `get_size()` | `→ u64` | Cached value from open time |
| `get_mode()` | `→ FileMode` | Current mode |
| `get_path()` | `→ &str` | Logical game-relative path |

**Safety**: `Drop` implementation calls `close()` automatically, so handles are
always flushed even if Lua scripts forget to close them.

---

### `async_loader.rs` — `AsyncLoader` (Background File Reader)

**~210 lines** (including ~80 lines of inline tests) | Single-threaded background
file I/O for assets that are too large to load synchronously without stuttering.

#### Architecture

```
Main thread                          Worker thread ("luna-async-loader")
    │                                      │
    │ request_load(resolved_path)          │
    │ ──(SyncSender)──────────────────────►│
    │         LoadRequest { handle, path } │
    │                                      │ std::fs::read(path)
    │                                      │
    │         poll(handle)                 │
    │◄──(Arc<Mutex<HashMap>>)──────────────│
    │         LoadStatus::Done(result)     │
```

#### Key Design Decisions

1. **Bounded channel** (`QUEUE_CAPACITY = 64`): `try_send()` is used on the main
   thread to avoid blocking. If the queue is full, an immediate error result is
   inserted into the results map.

2. **One-shot consumption**: `poll()` removes the result from the map on first read.
   Second `poll()` for the same handle returns `Pending` (result is gone). This
   prevents memory leaks from uncollected results.

3. **Pre-validated paths**: The `resolved_path` parameter must already be
   sandbox-validated. Path checking happens on the main thread **before** enqueueing
   to prevent TOCTOU (time-of-check-time-of-use) races.

4. **`AtomicU64` ID generation**: `LoadHandle` IDs are monotonically increasing atomic
   counters — no locking needed for ID assignment.

5. **Graceful shutdown**: `Drop` drops the sender channel, causing `rx.iter()` in the
   worker to terminate. Then `worker.join()` waits for the thread to finish.

#### Types

| Type | Purpose |
|------|---------|
| `AsyncLoader` | Owns the worker thread, sender, and result map |
| `LoadHandle(u64)` | Opaque ID returned to callers for polling |
| `LoadResult` | `Ready(Vec<u8>)` or `Error(String)` |
| `LoadStatus` | `Pending` (still loading) or `Done(LoadResult)` |

#### Thread Safety

- `Arc<Mutex<HashMap<u64, LoadResult>>>` — shared results map.
- `AtomicU64` — lock-free handle ID generation.
- `mpsc::SyncSender` — bounded channel for request submission.
- No `unsafe` anywhere in this file.

#### Inline Tests

Three tests verify core behavior:
- `load_existing_file` — writes a temp file, loads it async, verifies content.
- `load_missing_file` — loads a non-existent path, expects `LoadResult::Error`.
- `poll_returns_done_once` — verifies result is consumed on first poll.

---

## Cross-Cutting Concerns

### Error Handling

All fallible operations return `EngineResult<T>` (alias for `Result<T, EngineError>`).
The filesystem exclusively uses the `EngineError::FileSystemError(String)` variant.
Error messages always include the logical path for debuggability.

### Thread Safety

`GameFS` and `FileHandle` are **not** `Send`/`Sync` — they are designed to be used
from the main thread only. `AsyncLoader` handles cross-thread concerns internally
via `Arc<Mutex<>>` and atomic operations.

### Lua Integration

The Lua bridge lives in `src/lua_api/filesystem_api.rs` (not in this module).
It wraps `GameFS` and `FileHandle` as `LuaUserData` types exposed through:
- `luna.filesystem.read(path)` — calls `GameFS::read_string`
- `luna.filesystem.newFile(path, mode)` — creates a `FileHandle`
- `luna.filesystem.getDirectoryItems(path)` — calls `get_directory_items`
- `luna.filesystem.getInfo(path)` — calls `get_info`
- `luna.filesystem.write(path, data)` — calls `write_string`
- File handle methods: `:read()`, `:write()`, `:seek()`, `:close()`, etc.

### Usage from Lua

```lua
-- Read a game asset
local content = luna.filesystem.read("data/levels.json")

-- Check if a file exists
if luna.filesystem.getInfo("config.toml") then
    local cfg = luna.filesystem.read("config.toml")
end

-- List directory contents
local items = luna.filesystem.getDirectoryItems("assets/sprites")

-- Write save data (restricted to save/ directory)
luna.filesystem.write("save/progress.json", json_string)

-- Buffered file I/O
local file = luna.filesystem.newFile("save/log.txt", "a")
file:write("Game started\n")
file:flush()
file:close()
```
