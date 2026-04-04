# `filesystem` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 1 — Basic Core |
| **Lua API** | `luna.filesystem` |
| **Source** | `src/filesystem/` |
| **Tests** | `tests/filesystem_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_filesystem.lua` |

## Summary

All game I/O is routed through `GameFS`, a sandboxed virtual filesystem that
forces every resolved path to stay within the game's own directory or a
designated per-identity save directory. This prevents path traversal attacks
(e.g. `../../etc/passwd`) and ensures scripts cannot read or write arbitrary
files on the host system. `FileHandle` wraps a single open file in one of
four modes — Read, Write, Append, or Closed — with line-by-line and bulk
read/write operations. `AsyncLoader` dispatches background file reads to a
worker thread and returns a `LoadHandle` immediately; the Lua loop polls
`check_load()` each frame without blocking the event loop. `GameFS` also
provides `list_files()`, `file_exists()`, `file_info()`, and
`create_directory()`. The `identity` field namespaces a game's writable
directory separately from its read-only asset tree, preventing save-file
collisions between games sharing the same engine install.

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

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | Module root; re-exports GameFS, AsyncLoader, FileHandle, FileData, and Vfs access |
| `async_loader.rs` | Background asset-loading worker that reads files off the main thread |
| `file_data.rs` | Raw file data buffer loaded from the VFS |
| `file_handle.rs` | File handle with buffered read/write and sandboxed path resolution |
| `vfs.rs` | Vfs implementation for the `filesystem` subsystem |

## Submodules

### `filesystem::async_loader`

Background asset-loading worker that reads files off the main thread.

- **`LoadHandle`** (struct): Opaque handle returned to callers (and to Lua) that identifies a pending load.
- **`LoadResult`** (enum): Outcome of a completed load request. Returns an error if the source data is malformed or missing.
- **`LoadStatus`** (enum): Status returned by [`AsyncLoader::poll`].
- **`AsyncLoader`** (struct): A single-threaded background file reader.  Create one per engine session; drop it to join the worker thread.

### `filesystem::file_handle`

File handle with buffered read/write and sandboxed path resolution.

- **`FileMode`** (enum): File access mode. Consult the module-level documentation for the broader usage context and preconditions.
- **`FileHandle`** (struct): A sandboxed file handle for reading or writing game files.

### `filesystem::vfs`

Vfs implementation for the `filesystem` subsystem.

- **`FileInfo`** (struct): File metadata returned by `get_info()`. Consult the module-level documentation for the broader usage context and...
- **`FileType`** (enum): File type classification for `FileInfo`.
- **`GameFS`** (struct): Sandboxed filesystem rooted at the game directory; prevents path-traversal attacks.

## Key Types

### Structs

#### `filesystem::async_loader::AsyncLoader`

A single-threaded background file reader.  Create one per engine session; drop it to join the worker thread.

#### `filesystem::file_handle::FileHandle`

A sandboxed file handle for reading or writing game files.

#### `filesystem::vfs::FileInfo`

File metadata returned by `get_info()`. Consult the module-level documentation for the broader usage context and...

#### `filesystem::vfs::GameFS`

Sandboxed filesystem rooted at the game directory; prevents path-traversal attacks.

#### `filesystem::async_loader::LoadHandle`

Opaque handle returned to callers (and to Lua) that identifies a pending load.

### Enums

#### `filesystem::file_handle::FileMode`

File access mode. Consult the module-level documentation for the broader usage context and preconditions.

#### `filesystem::vfs::FileType`

File type classification for `FileInfo`.

#### `filesystem::async_loader::LoadResult`

Outcome of a completed load request. Returns an error if the source data is malformed or missing.

#### `filesystem::async_loader::LoadStatus`

Status returned by [`AsyncLoader::poll`].

## Lua API

Exposed under `luna.filesystem.*` by `src/lua_api/filesystem_api/`.

## Item Summary

| Kind | Count |
|------|-------|
| `enum` | 4 |
| `mod` | 3 |
| `struct` | 5 |
| **Total** | **12** |

