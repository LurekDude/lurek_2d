# `filesystem` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Core Runtime |
| **Status** | Implemented |
| **Lua API** | `lurek.filesystem` |
| **Source** | `src/filesystem/` |
| **Rust Tests** | `tests/rust/unit/filesystem_tests.rs`, plus inline unit coverage in `src/filesystem/async_loader.rs` |
| **Lua Tests** | `tests/lua/unit/test_filesystem.lua`, `tests/lua/stress/test_filesystem_stress.lua`, `tests/lua/integration/test_data_filesystem.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Core Runtime` |

---

## Summary

The filesystem module owns all sandboxed game I/O in Lurek2D. It gives the engine a single virtual filesystem rooted at the game directory, constrains writes to the save area, supports overlay mount layers, and provides both direct file handles and background read requests for scripts that need non-blocking asset loads.

This module exists to keep game scripts productive without giving them unrestricted access to the host filesystem. `GameFS` resolves and validates paths, `FileHandle` exposes buffered read and write operations inside that sandbox, `FileData` packages raw file bytes for Lua consumption, and `AsyncLoader` lets the main thread offload file reads without introducing a general async runtime.

It intentionally does not own network I/O, archive formats, arbitrary process-wide file access, or rendering-specific asset decoding. If the work is about PNG parsing, audio decoding, or remote data transport, that belongs elsewhere. The Lua API in `src/lua_api/filesystem_api.rs` owns how this sandbox is presented to scripts; the core module owns the actual path safety and file behavior.

**Scope boundary**: This module currently depends on `runtime`. It stays within the Core Runtime responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.filesystem.* (Lua API — src/lua_api/filesystem_api.rs)
    |
    v
src/filesystem/mod.rs
    |- async_loader.rs - async_loader
    |- file_data.rs - file_data
    |- file_handle.rs - file_handle
    |- vfs.rs - vfs
```

---

## Source Files

| File | Purpose |
|------|---------|
| `async_loader.rs` | Background asset-loading worker that reads files off the main thread. |
| `file_data.rs` | Raw file data buffer loaded from the VFS. |
| `file_handle.rs` | File handle with buffered read/write and sandboxed path resolution. |
| `mod.rs` | Mod implementation for the `filesystem` subsystem. |
| `vfs.rs` | Vfs implementation for the `filesystem` subsystem. |

---

## Submodules

### `filesystem::async_loader`

Background asset-loading worker that reads files off the main thread.

- **`LoadHandle`** (struct): Opaque handle returned to callers (and to Lua) that identifies a pending load.
- **`LoadResult`** (enum): Outcome of a completed load request.
- **`LoadStatus`** (enum): Status returned by [`AsyncLoader::poll`].
- **`AsyncLoader`** (struct): A single-threaded background file reader.

### `filesystem::file_data`

Raw file data buffer loaded from the VFS.

- **`FileData`** (struct): Raw bytes loaded from the virtual filesystem.

### `filesystem::file_handle`

File handle with buffered read/write and sandboxed path resolution.

- **`FileMode`** (enum): File access mode.
- **`FileHandle`** (struct): A sandboxed file handle for reading or writing game files.

### `filesystem::vfs`

Vfs implementation for the `filesystem` subsystem.

- **`FileInfo`** (struct): File metadata returned by `get_info()`.
- **`FileType`** (enum): File type classification for `FileInfo`.
- **`MountLayer`** (struct): A virtual filesystem mount layer overlaid on top of the game directory.
- **`GameFS`** (struct): Sandboxed filesystem rooted at the game directory; prevents path-traversal attacks.

---

## Key Types

### Public Types

#### `LoadHandle`

Opaque handle returned to callers (and to Lua) that identifies a pending load.

#### `LoadResult`

Outcome of a completed load request.

#### `LoadStatus`

Status returned by [`AsyncLoader::poll`].

#### `AsyncLoader`

A single-threaded background file reader.

#### `FileData`

Raw bytes loaded from the virtual filesystem.

#### `FileMode`

File access mode.

#### `FileHandle`

A sandboxed file handle for reading or writing game files.

#### `FileInfo`

File metadata returned by `get_info()`.

---

## Lua API

Exposed under `lurek.filesystem.*` by `src/lua_api/filesystem_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.filesystem.read` | Reads a text file and returns its contents as a string. |
| `lurek.filesystem.write` | Writes a string to a file in the save directory. |
| `lurek.filesystem.exists` | Returns whether the given file or directory exists. |
| `lurek.filesystem.append` | Opens the file in append mode and writes the given string at the end. |
| `lurek.filesystem.openFile` | Opens a file and returns a readable/writable file handle. |
| `lurek.filesystem.getDirectoryItems` | Returns a table containing the names of every file and subdirectory in the given path. |
| `lurek.filesystem.isFile` | Returns whether the given path is a regular file. |
| `lurek.filesystem.isDirectory` | Returns whether the given path is a directory. |
| `lurek.filesystem.createDirectory` | Creates a directory and any missing parent directories in the save area. |
| `lurek.filesystem.remove` | Permanently deletes a file or empty directory from the save directory. |
| `lurek.filesystem.getInfo` | Returns a table of metadata for a path, or nil if the path does not exist. |
| `lurek.filesystem.getSource` | Returns the absolute path of the directory the game was loaded from. |
| `lurek.filesystem.getSaveDirectory` | Returns the sandboxed save data directory path. |
| `lurek.filesystem.getWorkingDirectory` | Returns the current working directory path. |
| `lurek.filesystem.getUserDirectory` | Returns the current user's home directory path. |
| `lurek.filesystem.getIdentity` | Returns the identity string used to locate the game's save directory. |
| `lurek.filesystem.setIdentity` | Sets the identity string that names the game's sandboxed save-data directory. |
| `lurek.filesystem.lines` | Returns an iterator function over the lines of a text file. |
| `lurek.filesystem.readAsync` | Starts loading a file in the background and returns an opaque handle. |
| `lurek.filesystem.pollAsync` | Polls an async load handle, returning status and optional data. |
| `lurek.filesystem.mount` | Mounts a directory at a virtual path inside the game filesystem. |
| `lurek.filesystem.unmount` | Removes a virtual mount layer by mountpoint. |
| `lurek.filesystem.load` | Loads and compiles a Lua file from the VFS, returning it as a callable function. |
| `lurek.filesystem.newFileData` | Loads a file from the VFS into a FileData buffer. |

### `FileData` Methods

| Method | Description |
|--------|-------------|
| `filedata:getSize(...)` | Returns the file size in bytes. |
| `filedata:getString(...)` | Returns the file content as a Lua string. |
| `filedata:getFilename(...)` | Returns the virtual path this data was loaded from. |

### `FileHandle` Methods

| Method | Description |
|--------|-------------|
| `filehandle:read(...)` | Reads bytes from the file, returning them as a string. |
| `filehandle:readLine(...)` | Reads the next line from the file without the trailing newline. |
| `filehandle:write(...)` | Writes a string to the file and returns the number of bytes written. |
| `filehandle:seek(...)` | Seeks the file position to the given byte offset from the start. |
| `filehandle:tell(...)` | Returns the current read/write byte offset from the start of the file. |
| `filehandle:getSize(...)` | Returns the size of the open file in bytes. |
| `filehandle:getMode(...)` | Returns the access mode the file was opened with. |
| `filehandle:flush(...)` | Flushes all buffered writes to disk without closing the handle. |
| `filehandle:close(...)` | Flushes any pending writes and closes the file handle. |
| `filehandle:isEOF(...)` | Returns whether the read cursor has reached the end of the file. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.filesystem.
if lurek.filesystem then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 7 |
| `enum` | 4 |
| `fn` (Lua API) | 37 |
| **Total** | **48** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/filesystem/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
