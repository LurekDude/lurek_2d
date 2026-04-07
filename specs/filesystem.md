# `filesystem` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                      |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `luna.filesystem`                                    |
| **Source**     | `src/filesystem/`                                    |
| **Rust Tests** | `tests/rust/unit/filesystem_tests.rs`                |
| **Lua Tests**  | `tests/lua/unit/test_filesystem.lua`                 |
| **Architecture** | —                                                  |

## Summary

The `filesystem` module provides all game I/O through `GameFS`, a sandboxed virtual filesystem that forces every resolved path to stay within the game's own directory or a designated per-identity save directory. This security model prevents path-traversal attacks (e.g. `../../etc/passwd`) and ensures Lua scripts cannot read or write arbitrary files on the host system. Read operations are sandboxed to the game root directory via `resolve_read_path()`, which canonicalises the path and verifies it starts with the base directory. Write operations are further restricted to the `save/` subdirectory via `resolve_save_path()`, blocking `..` components in both the logical path and the resolved canonical path. `FileHandle` wraps a single open file in one of four modes — Read, Write, Append, or Closed — with buffered line-by-line and bulk read/write operations using `BufReader`/`BufWriter`. `AsyncLoader` dispatches background file reads to a dedicated worker thread via a bounded sync channel (64-slot capacity) and returns a `LoadHandle` immediately; the Lua loop polls `pollAsync()` each frame without blocking the event loop. The VFS mount layer system allows overlaying additional directories (e.g. mod folders) at virtual mountpoints, with newest-mounted layers searched first. `FileData` provides a simple raw-bytes buffer for files loaded through the VFS. The `identity` field namespaces a game's writable directory separately from its read-only asset tree, preventing save-file collisions between games sharing the same engine install. The module intentionally does not provide network I/O, ZIP archive decompression (that is handled by `VirtualFS` in the engine layer), or recursive directory deletion — these are out of scope.

## Architecture

```
GameFS (sandbox root = game directory)
  │
  ├── Read sandbox ─── any path under base_dir/
  │     ├── resolve_read_path() → canonicalize + starts_with(base) guard
  │     ├── read_string(path) → UTF-8 file contents
  │     ├── read_bytes(path) → raw Vec<u8>
  │     ├── read_lines(path) → Vec<String> (line-split)
  │     ├── load_chunk(path) → bytes from mounts then base dir
  │     ├── exists() / is_file() / is_directory()
  │     ├── list() / get_directory_items() / get_directory_items_merged()
  │     └── get_info() → FileInfo { type, size, mtime, readonly }
  │
  ├── Write sandbox ── only base_dir/save/ subdirectory
  │     ├── resolve_save_path() → starts_with(save/) + no ".." guard
  │     ├── write_string(path, content)
  │     ├── write_bytes(path, bytes)
  │     ├── append_string(path, content)
  │     ├── create_directory(path)
  │     └── remove(path) — file or empty directory
  │
  ├── Mount Layer System ── overlaid directory search
  │     ├── mount(source, mountpoint) → add MountLayer (game-dir relative)
  │     ├── mount_full(abs_path, mountpoint) → add MountLayer (absolute)
  │     ├── unmount(mountpoint) → remove first matching layer
  │     └── load_chunk() / get_directory_items_merged() — search newest-first
  │
  ├── FileHandle ── buffered file I/O with open/read/write/seek/close
  │     ├── Read mode → BufReader<File>
  │     ├── Write mode → BufWriter<File> (truncate)
  │     ├── Append mode → BufWriter<File> (append)
  │     └── Closed → no I/O
  │
  ├── FileData ── raw byte buffer loaded from VFS
  │     └── path + Vec<u8> content, with len/is_empty/as_str accessors
  │
  └── AsyncLoader ── background thread for non-blocking file reads
        ├── SyncSender<LoadRequest> → worker thread (bounded queue, 64 slots)
        ├── Arc<Mutex<HashMap>> ← completed results
        ├── request_load(path) → LoadHandle
        └── poll(handle) → Pending | Done(Ready(bytes) | Error(msg))
```

## Source Files

| File              | Purpose                                                              |
|-------------------|----------------------------------------------------------------------|
| `mod.rs`          | Module root; re-exports `GameFS`, `AsyncLoader`, `FileHandle`, `FileData`, `MountLayer` |
| `vfs.rs`          | `GameFS` sandboxed filesystem, `FileInfo`, `FileType`, `MountLayer`, path resolution, mount layers |
| `file_handle.rs`  | `FileHandle` with buffered read/write/seek/close, `FileMode` enum   |
| `file_data.rs`    | `FileData` raw byte buffer loaded from VFS                          |
| `async_loader.rs` | `AsyncLoader` background file reader, `LoadHandle`, `LoadResult`, `LoadStatus` |

## Submodules

### `filesystem::vfs`

Sandboxed virtual filesystem rooted at the game directory with mount layer support.

- **`GameFS`** (struct) — Sandboxed filesystem rooted at the game directory; prevents path-traversal attacks. Manages read/write sandboxing, mount layers, directory queries, and file metadata.
- **`FileInfo`** (struct) — File metadata returned by `get_info()`: file type, size, modification time, and read-only flag.
- **`FileType`** (enum) — File type classification: `File`, `Directory`, `Symlink`, `Other`.
- **`MountLayer`** (struct) — A virtual filesystem mount layer with a host-OS source directory and a virtual path prefix mountpoint.

### `filesystem::file_handle`

Buffered file handle with read/write/seek operations and sandboxed path resolution.

- **`FileHandle`** (struct) — A sandboxed file handle for reading or writing game files. Supports `Read`, `Write`, and `Append` modes with `BufReader`/`BufWriter` wrappers.
- **`FileMode`** (enum) — File access mode: `Read`, `Write`, `Append`, `Closed`.

### `filesystem::file_data`

Raw file data buffer loaded from the VFS.

- **`FileData`** (struct) — Raw bytes loaded from the virtual filesystem with `path` and `bytes` fields. Provides `len()`, `is_empty()`, and `as_str()` accessors.

### `filesystem::async_loader`

Background asset-loading worker running on a dedicated OS thread.

- **`AsyncLoader`** (struct) — A single-threaded background file reader. Spawns one worker thread at creation; dropping the instance joins the thread. Uses a bounded channel (64 slots) for requests and an `Arc<Mutex<HashMap>>` for results.
- **`LoadHandle`** (struct) — Opaque handle identifying a pending async load (wraps a `u64` ID).
- **`LoadResult`** (enum) — Outcome of a completed load: `Ready(Vec<u8>)` or `Error(String)`.
- **`LoadStatus`** (enum) — Poll result: `Pending` or `Done(LoadResult)`.

## Key Types

### Structs

#### `filesystem::vfs::GameFS`

Sandboxed filesystem rooted at the game directory; prevents path-traversal attacks. Fields: `base_dir` (`PathBuf`), `identity` (`String`), `mounts` (`Vec<MountLayer>`). Provides all read and write operations with path validation, mount layer management, directory listing, and metadata queries. Primary constructor: `GameFS::new(base_dir)`.

#### `filesystem::vfs::FileInfo`

File metadata returned by `GameFS::get_info()`. Fields: `file_type` (`FileType`), `size` (`u64`), `modified_time` (`Option<u64>` — UNIX timestamp), `readonly` (`bool`).

#### `filesystem::vfs::MountLayer`

A virtual filesystem mount layer. Fields: `source` (`PathBuf` — host-OS directory), `mountpoint` (`String` — virtual path prefix). Added via `GameFS::mount()` or `GameFS::mount_full()`.

#### `filesystem::file_handle::FileHandle`

A sandboxed file handle for reading or writing game files. Fields: `mode` (`FileMode`), `path` (`PathBuf` — resolved absolute), `logical_path` (`String`), `reader` (`Option<BufReader<File>>`), `writer` (`Option<BufWriter<File>>`), `size` (`u64`). Constructor: `FileHandle::open(vfs, path, mode)`. Key operations: `read()`, `read_line()`, `write()`, `seek()`, `tell()`, `flush()`, `close()`, `is_eof()`.

#### `filesystem::file_data::FileData`

Raw bytes loaded from the virtual filesystem. Fields: `path` (`String`), `bytes` (`Vec<u8>`). Constructor: `FileData::new(path, bytes)`. Accessors: `len()`, `is_empty()`, `as_str()`.

#### `filesystem::async_loader::AsyncLoader`

A single-threaded background file reader. Spawns a worker thread with a bounded sync channel (64 slots). Constructor: `AsyncLoader::new()`. Key operations: `request_load(resolved_path)` → `LoadHandle`, `poll(handle)` → `LoadStatus`, `pending_results()`. Implements `Drop` to join the worker thread on cleanup.

#### `filesystem::async_loader::LoadHandle`

Opaque handle returned to callers that identifies a pending load. Wraps a `u64` ID. Implements `Debug`, `Clone`, `Copy`, `PartialEq`, `Eq`, `Hash`.

### Enums

#### `filesystem::vfs::FileType`

File type classification for `FileInfo`. Variants: `File` (regular file), `Directory`, `Symlink` (symbolic link), `Other` (unknown or special entry). Provides `as_str()` → `"file"` / `"directory"` / `"symlink"` / `"other"`.

#### `filesystem::file_handle::FileMode`

File access mode. Variants: `Read` (file must exist), `Write` (creates or truncates), `Append` (creates if needed, writes at end), `Closed` (handle not open). Provides `parse_mode(s)` for `"r"/"w"/"a"` conversion and `as_str()` for the reverse.

#### `filesystem::async_loader::LoadResult`

Outcome of a completed load request. Variants: `Ready(Vec<u8>)` (bytes loaded successfully), `Error(String)` (error message).

#### `filesystem::async_loader::LoadStatus`

Status returned by `AsyncLoader::poll()`. Variants: `Pending` (still processing), `Done(LoadResult)` (completed — consumed on first poll).

## Lua API

Exposed under `luna.filesystem.*` by `src/lua_api/filesystem_api.rs`. The API provides sandboxed file I/O, directory queries, async asset loading, VFS mount management, and file handle operations. Two UserData types are also exposed: `FileHandle` (returned by `openFile`) and `FileData` (returned by `newFileData`).

### Module Functions (`luna.filesystem.*`)

| Function | Signature | Description |
|----------|-----------|-------------|
| `read` | `(path: string) → string` | Reads a text file and returns its contents |
| `write` | `(path: string, data: string) → nil` | Writes a string to a file in the save directory |
| `exists` | `(path: string) → boolean` | Returns whether the given file or directory exists |
| `append` | `(path: string, data: string) → nil` | Opens a file in append mode and writes at the end |
| `openFile` | `(path: string, mode: string) → FileHandle` | Opens a file and returns a readable/writable handle |
| `getDirectoryItems` | `(path: string) → table` | Returns names of files and subdirectories in path |
| `isFile` | `(path: string) → boolean` | Returns whether the path is a regular file |
| `isDirectory` | `(path: string) → boolean` | Returns whether the path is a directory |
| `createDirectory` | `(path: string) → nil` | Creates a directory and parents in save area |
| `remove` | `(path: string) → nil` | Deletes a file or empty directory from save area |
| `getInfo` | `(path: string) → table?` | Returns metadata table or nil if path missing |
| `getSource` | `() → string` | Returns absolute path of the game directory |
| `getSaveDirectory` | `() → string` | Returns the sandboxed save data directory path |
| `getWorkingDirectory` | `() → string` | Returns the current working directory path |
| `getUserDirectory` | `() → string` | Returns the current user's home directory path |
| `getIdentity` | `() → string` | Returns the identity string for save directory naming |
| `setIdentity` | `(name: string) → nil` | Sets the identity string |
| `lines` | `(path: string) → function` | Returns an iterator function over lines of a file |
| `readAsync` | `(path: string) → integer` | Starts a background file load, returns handle ID |
| `pollAsync` | `(handle: integer) → string, string?` | Polls async load handle for status and data |
| `mount` | `(source: string, mountpoint: string) → boolean` | Mounts a directory at a virtual path |
| `unmount` | `(mountpoint: string) → boolean` | Removes a virtual mount layer |
| `load` | `(path: string) → function` | Loads and compiles a Lua file from VFS |
| `newFileData` | `(path: string) → FileData` | Loads a file from VFS into a FileData buffer |

### FileHandle Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `read` | `(count: integer?) → string` | Reads bytes, returns as string |
| `readLine` | `() → string?` | Reads next line without trailing newline |
| `write` | `(data: string) → integer` | Writes string, returns bytes written |
| `seek` | `(pos: integer) → integer` | Seeks to byte offset from start |
| `tell` | `() → integer` | Returns current byte offset |
| `getSize` | `() → integer` | Returns file size in bytes |
| `getMode` | `() → string` | Returns access mode (`"r"`, `"w"`, `"a"`, `"c"`) |
| `flush` | `() → nil` | Flushes buffered writes to disk |
| `close` | `() → nil` | Flushes and closes the handle |
| `isEOF` | `() → boolean` | Returns whether read cursor is at EOF |

### FileData Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `getSize` | `() → integer` | Returns file size in bytes |
| `getString` | `() → string` | Returns file content as a Lua string |
| `getFilename` | `() → string` | Returns the virtual path this data was loaded from |

## Lua Examples

```lua
-- Basic file read/write
function luna.load()
    -- Write save data (must be under save/)
    luna.filesystem.write("save/progress.json", '{"score": 100}')

    -- Read it back
    if luna.filesystem.exists("save/progress.json") then
        local data = luna.filesystem.read("save/progress.json")
        print("Loaded: " .. data)
    end

    -- Append a log line
    luna.filesystem.append("save/game.log", "Session started\n")

    -- Query file info
    local info = luna.filesystem.getInfo("save/progress.json")
    if info then
        print("Type: " .. info.type)
        print("Size: " .. info.size .. " bytes")
    end
end
```

```lua
-- Directory listing and file handle I/O
function luna.load()
    -- List files in current directory
    local items = luna.filesystem.getDirectoryItems(".")
    for _, name in ipairs(items) do
        if luna.filesystem.isFile(name) then
            print("File: " .. name)
        elseif luna.filesystem.isDirectory(name) then
            print("Dir:  " .. name)
        end
    end

    -- File handle for line-by-line reading
    local fh = luna.filesystem.openFile("data/config.txt", "r")
    while not fh:isEOF() do
        local line = fh:readLine()
        if line then print(line) end
    end
    fh:close()
end
```

```lua
-- Async loading and VFS mounting
function luna.load()
    -- Mount a mod directory
    luna.filesystem.mount("mods/expansion", "/mods/expansion")

    -- Load a Lua file from the VFS (searches mounts first)
    local mod_init = luna.filesystem.load("mods/expansion/init.lua")
    mod_init()

    -- Start an async file load
    handle = luna.filesystem.readAsync("assets/large_texture.png")
end

function luna.update(dt)
    if handle then
        local status, data = luna.filesystem.pollAsync(handle)
        if status == "done" then
            print("Loaded " .. #data .. " bytes")
            handle = nil
        elseif status == "error" then
            print("Load failed: " .. tostring(data))
            handle = nil
        end
    end
end
```

## Item Summary

| Kind       | Count |
|------------|-------|
| `struct`   | 7     |
| `enum`     | 4     |
| `fn`       | 53    |
| **Total**  | **64**|

## References

| Module      | Relationship  | Notes                                                          |
|-------------|---------------|----------------------------------------------------------------|
| `engine`    | Imports from  | Uses `EngineError`, `EngineResult`, log message constants      |
| `math`      | —             | No direct dependency                                           |
| `data`      | Related       | `data` manipulates bytes in memory; `filesystem` provides sandboxed I/O to disk |
| `savegame`  | Related       | `savegame` calls `filesystem` to persist serialised save data  |
| `modding`   | Related       | `modding` uses mount layers for mod discovery and load ordering |
| `thread`    | Related       | Worker threads can use `filesystem` for background I/O         |
| `lua_api`   | Imported by   | `src/lua_api/filesystem_api.rs` registers `luna.filesystem.*`  |

## Notes

- **Path sandbox is the security boundary.** All read paths are canonicalised and checked against `base_dir`. All write paths must resolve inside `save/`. `..` components are rejected for write paths. Never expose engine `src/` paths to Lua.
- **Write restriction.** `write_string`, `write_bytes`, `append_string`, `create_directory`, and `remove` are restricted to the `save/` subdirectory. Read operations work from any path under the game root.
- **Mount layers.** `mount()` only accepts source directories inside the game directory (canonicalised and validated). `mount_full()` accepts absolute paths but is not exposed to Lua — it is for internal engine use only. Mounts are searched newest-first by `load_chunk()` and `get_directory_items_merged()`.
- **Async loader.** `AsyncLoader` uses a bounded sync channel (64 slots). If the queue is full, `request_load()` returns a handle whose poll result is an immediate error. The `resolve_read_path()` validation must happen on the main thread before `request_load()` to prevent TOCTOU races. Results are consumed once — the first `poll()` returning `Done` removes the entry.
- **FileHandle buffering.** Read mode uses `BufReader`, Write and Append modes use `BufWriter`. The `Drop` implementation calls `close()` to flush pending writes automatically if the handle is not explicitly closed.
- **Identity.** The `identity` field namespaces a game's save directory separately from its read-only asset tree, preventing save-file collisions between games sharing the same engine install. Set via `conf.lua` (`t.identity = "my_game"`) or `luna.filesystem.setIdentity()`.
- **No network I/O.** The filesystem module is strictly local disk. No HTTP, WebSocket, or remote file access.
- **Platform paths.** `get_user_directory()` reads `USERPROFILE` on Windows and `HOME` on Unix, falling back to the current directory. `get_save_directory()` returns `base_dir/save/`.
- **Breaking change surface.** Renaming or removing any `luna.filesystem.*` function breaks existing Lua game scripts. The `getInfo` return table shape (`type`, `size`, `modtime`, `readonly`) is part of the public API contract.
