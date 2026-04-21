# filesystem

## General Info

- Module group: `Core Runtime`
- Source path: `src/filesystem/`
- Lua API path(s): `src/lua_api/filesystem_api.rs`
- Primary Lua namespace: `lurek.filesystem`
- Rust test path(s): tests/rust/unit/filesystem_tests.rs, plus inline unit coverage in src/filesystem/async_loader.rs
- Lua test path(s): tests/lua/unit/test_filesystem.lua, tests/lua/stress/test_filesystem_stress.lua, tests/lua/integration/test_data_filesystem.lua

## Summary

The `filesystem` module provides Lurek2D's sandboxed virtual filesystem abstraction. It wraps all file-system access behind a `GameFS` type that ensures Lua scripts and engine code can only read and write within the game's allowed directory tree — preventing path traversal attacks that would let a game script escape its sandbox to access arbitrary host paths.

`GameFS` is initialised with a base directory (the loaded game folder) and an optional save-data directory. Every path passed to any `GameFS` method is resolved against the base directory and checked against a traversal guard: any path component that would escape the base (via `..`, symbolic links, or absolute path prefixes) is rejected with an `EngineError::FsPathTraversal` error before the OS is ever asked to open the file. The check is strict: it resolves the canonical path and confirms the result starts with the base directory prefix.

The API covers: `read_string(path)`, `read_bytes(path)`, `write_string(path, content)`, `write_bytes(path, data)`, `list(path)`, `get_directory_items(path)`, `get_info(path)`, `exists(path)`, `create_directory(path)`, `remove(path)`, `copy_file(src, dst)`, `move_file(src, dst)`, `remove_dir(path)`, `glob(pattern)`, `append_string(path, content)`, and `read_lines(path)`. `FileHandle` provides an open-file session with cursored reads, sequential writes, seek/tell, and explicit close semantics. `FileInfo` carries file type (`File`, `Directory`, `Symlink`, `Other`), size, modification timestamp, and read-only flag. `AsyncLoader` provides a background worker thread for non-blocking file reads with bounded-channel back-pressure.

Write operations are always routed to the save-data directory (if configured) rather than the read-only game folder. Read operations can access both. This separation mirrors how LÖVE2D handles the `love.filesystem` split between game content and mutable save state.

The module also provides the `MountPoint` abstraction for overlaying read-only archive or zip mounts on top of the base file system, used by the `mods` module to load mod content packages.

Two additional types expand the runtime I/O surface. `FileWatcher` (from `watcher.rs`) is a polling-based change detector that Lua scripts can use to react to file modifications at development time, created via `lurek.filesystem.newWatcher()`. `ZipArchive` adds first-class ZIP archive support: files inside a `.zip` can be listed and read without extracting them to disk, created via `lurek.filesystem.newZip()`. Both types expose full Lua method sets through `lurek.filesystem.*`.

**Scope boundary**: Core Runtime tier. Depends on `runtime` for error types. Lua bridge in `src/lua_api/filesystem_api.rs`.

## Files

- `async_loader.rs`: Background asset-loading worker that reads files off the main thread.
- `file_data.rs`: Raw file data buffer loaded from the VFS.
- `file_handle.rs`: File handle with buffered read/write and sandboxed path resolution.
- `mod.rs`: Mod implementation for the `filesystem` subsystem.
- `vfs.rs`: Vfs implementation for the `filesystem` subsystem.
- `watcher.rs`: Polling-based file watcher for development hot-reload workflows.
- `zip_mount.rs`: ZIP archive mounting — read-only virtual filesystem layer backed by a `.zip` file.

## Types

- `LoadHandle` (`struct`, `async_loader.rs`): Opaque handle returned to callers (and to Lua) that identifies a pending load.
- `LoadResult` (`enum`, `async_loader.rs`): Outcome of a completed load request.
- `LoadStatus` (`enum`, `async_loader.rs`): Status returned by [`AsyncLoader::poll`].
- `AsyncLoader` (`struct`, `async_loader.rs`): A single-threaded background file reader.
- `FileData` (`struct`, `file_data.rs`): Raw bytes loaded from the virtual filesystem.
- `FileMode` (`enum`, `file_handle.rs`): File access mode.
- `FileHandle` (`struct`, `file_handle.rs`): A sandboxed file handle for reading or writing game files.
- `FileInfo` (`struct`, `vfs.rs`): File metadata returned by `get_info()`.
- `FileType` (`enum`, `vfs.rs`): File type classification for `FileInfo`.
- `MountLayer` (`struct`, `vfs.rs`): A virtual filesystem mount layer overlaid on top of the game directory.
- `GameFS` (`struct`, `vfs.rs`): Sandboxed filesystem rooted at the game directory; prevents path-traversal attacks.
- `FileWatcher` (`struct`, `watcher.rs`): Polling file watcher that detects modification-time changes.
- `ZipMount` (`struct`, `zip_mount.rs`): A read-only mount backed by a `.zip` file.

## Functions

- `AsyncLoader::new` (`async_loader.rs`): Spawns the background worker thread.
- `AsyncLoader::request_load` (`async_loader.rs`): Submit a file-read request.
- `AsyncLoader::poll` (`async_loader.rs`): Check the status of a previously-requested load.
- `AsyncLoader::pending_results` (`async_loader.rs`): Returns the number of completed but un-polled results.
- `FileData::new` (`file_data.rs`): Creates a new `FileData` with the given path and content.
- `FileData::len` (`file_data.rs`): Returns the number of bytes in this buffer.
- `FileData::is_empty` (`file_data.rs`): Returns `true` if the buffer is empty.
- `FileData::as_str` (`file_data.rs`): Returns the bytes as a UTF-8 string slice, or an error if invalid.
- `FileMode::parse_mode` (`file_handle.rs`): Convert a mode string ("r", "w", "a") to a `FileMode`.
- `FileMode::as_str` (`file_handle.rs`): Convert a `FileMode` to its string representation.
- `FileHandle::open` (`file_handle.rs`): Open a file within the sandbox.
- `FileHandle::read` (`file_handle.rs`): Read up to `count` bytes, or all remaining bytes when `count` is `None`.
- `FileHandle::read_line` (`file_handle.rs`): Read a single line without the trailing newline character.
- `FileHandle::write` (`file_handle.rs`): Write raw bytes to the file.
- `FileHandle::seek` (`file_handle.rs`): Seek to an absolute byte position in the file.
- `FileHandle::tell` (`file_handle.rs`): Get the current byte position within the file.
- `FileHandle::get_size` (`file_handle.rs`): Get the file size in bytes (cached at open time).
- `FileHandle::get_mode` (`file_handle.rs`): Get the current file access mode.
- `FileHandle::get_path` (`file_handle.rs`): Get the logical (game-relative) path of this file.
- `FileHandle::flush` (`file_handle.rs`): Flush buffered writes to disk.
- `FileHandle::close` (`file_handle.rs`): Close the file handle, flushing any pending writes first.
- `FileHandle::is_eof` (`file_handle.rs`): Check whether the end of file has been reached (Read mode only).
- `FileType::as_str` (`vfs.rs`): Returns the string name of this file type.
- `GameFS::new` (`vfs.rs`): Creates a new `GameFS` rooted at `base_dir`.
- `GameFS::base_dir` (`vfs.rs`): Returns a reference to the base directory path.
- `GameFS::read_string` (`vfs.rs`): Reads the file at `path` (relative to base dir) and returns its contents as a `String`.
- `GameFS::read_bytes` (`vfs.rs`): Reads the file at `path` as raw bytes.
- `GameFS::write_string` (`vfs.rs`): Writes `content` to `path`, which must be inside the `save/` subdirectory.
- `GameFS::write_bytes` (`vfs.rs`): Writes raw bytes to `path`, which must stay inside the `save/` subdirectory.
- `GameFS::exists` (`vfs.rs`): Returns `true` if the file or directory at `path` exists within the game directory.
- `GameFS::list` (`vfs.rs`): Lists all entries in the directory at `path` relative to the game directory.
- `GameFS::get_directory_items` (`vfs.rs`): Get sorted directory items relative to `base_dir`.
- `GameFS::is_file` (`vfs.rs`): Check if the given path refers to a regular file.
- `GameFS::is_directory` (`vfs.rs`): Check if the given path refers to a directory.
- `GameFS::create_directory` (`vfs.rs`): Create a directory (and all parent directories) inside the save area.
- `GameFS::remove` (`vfs.rs`): Remove a file or empty directory from the save area.
- `GameFS::get_info` (`vfs.rs`): Get file or directory metadata.
- `GameFS::append_string` (`vfs.rs`): Append UTF-8 string content to a file in the save area.
- `GameFS::get_source` (`vfs.rs`): Get the game source directory (where `main.lua` lives).
- `GameFS::get_save_directory` (`vfs.rs`): Get the save directory path.
- `GameFS::get_working_directory` (`vfs.rs`): Get the current working directory of the process.
- `GameFS::get_user_directory` (`vfs.rs`): Get the current user's home directory.
- `GameFS::get_identity` (`vfs.rs`): Get the game identity string used for save directory naming.
- `GameFS::set_identity` (`vfs.rs`): Set the game identity string.
- `GameFS::mount` (`vfs.rs`): Mounts a host directory (relative to the game dir) at a virtual mountpoint.
- `GameFS::mount_full` (`vfs.rs`): Mounts an absolute host-OS path at a virtual mountpoint.
- `GameFS::unmount` (`vfs.rs`): Removes the first mount layer matching `mountpoint`.
- `GameFS::load_chunk` (`vfs.rs`): Reads file bytes from the VFS, searching mount layers newest-first before falling back to the base game directory.
- `GameFS::get_directory_items_merged` (`vfs.rs`): Lists entries visible under a virtual path, merging all mount layers.
- `GameFS::resolve_read_path` (`vfs.rs`): Resolve a logical path to an absolute path for reading.
- `GameFS::resolve_save_path` (`vfs.rs`): Resolve a logical path to an absolute path for writing.
- `GameFS::read_lines` (`vfs.rs`): Reads a text file and returns its contents split into lines.
- `GameFS::open_file` (`vfs.rs`): Opens a file handle by parsing the mode string and delegating to `FileHandle::open`.
- `GameFS::copy_file` (`vfs.rs`): Copies a file within the sandbox.
- `GameFS::move_file` (`vfs.rs`): Moves (renames) a file within the `save/` directory.
- `GameFS::remove_dir` (`vfs.rs`): Recursively removes a directory and all its contents within the `save/` directory.
- `GameFS::glob` (`vfs.rs`): Returns a list of paths inside the game root that match a simple glob pattern.
- `FileWatcher::new` (`watcher.rs`): Creates an empty [`FileWatcher`] with no watched paths.
- `FileWatcher::watch` (`watcher.rs`): Adds `path` to the watch list.
- `FileWatcher::unwatch` (`watcher.rs`): Removes `path` from the watch list.
- `FileWatcher::is_watching` (`watcher.rs`): Returns `true` if `path` is currently on the watch list.
- `FileWatcher::poll` (`watcher.rs`): Polls all watched paths and returns a sorted list of paths whose modification time has changed since the last call to `poll()` (or since `watch()` for newly added paths).
- `FileWatcher::len` (`watcher.rs`): Returns the number of paths currently being watched.
- `FileWatcher::is_empty` (`watcher.rs`): Returns `true` if no paths are being watched.
- `ZipMount::new` (`zip_mount.rs`): Opens a ZIP archive at `archive_path` and builds the entry index.
- `ZipMount::read_file` (`zip_mount.rs`): Reads the contents of `virtual_path` from the ZIP.
- `ZipMount::contains` (`zip_mount.rs`): Returns `true` if `virtual_path` exists in this ZIP mount.
- `ZipMount::list_files` (`zip_mount.rs`): Returns a sorted list of all virtual file paths exposed by this mount.

## Lua API Reference

- Binding path(s): `src/lua_api/filesystem_api.rs`
- Namespace: `lurek.filesystem`

### Module Functions
- `lurek.filesystem.mountZip`: Mounts a ZIP archive at a virtual path prefix, making its contents readable
- `lurek.filesystem.watchPath`: Adds `path` to the polled file-watch list.
- `lurek.filesystem.unwatchPath`: Removes `path` from the polled file-watch list.  No-op if not watched.
- `lurek.filesystem.pollWatchers`: Polls all watched paths and returns an array of paths that changed since the
- `lurek.filesystem.read`: Reads a text file and returns its contents as a string.
- `lurek.filesystem.write`: Writes a string to a file in the save directory.
- `lurek.filesystem.exists`: Returns whether the given file or directory exists.
- `lurek.filesystem.append`: Opens the file in append mode and writes the given string at the end.
- `lurek.filesystem.openFile`: Opens a file and returns a readable/writable file handle.
- `lurek.filesystem.getDirectoryItems`: Returns a table containing the names of every file and subdirectory in the given path.
- `lurek.filesystem.isFile`: Returns whether the given path is a regular file.
- `lurek.filesystem.isDirectory`: Returns whether the given path is a directory.
- `lurek.filesystem.createDirectory`: Creates a directory and any missing parent directories in the save area.
- `lurek.filesystem.remove`: Permanently deletes a file or empty directory from the save directory.
- `lurek.filesystem.getInfo`: Returns a table of metadata for a path, or nil if the path does not exist.
- `lurek.filesystem.getSource`: Returns the absolute path of the directory the game was loaded from.
- `lurek.filesystem.getSaveDirectory`: Returns the sandboxed save data directory path.
- `lurek.filesystem.getWorkingDirectory`: Returns the current working directory path.
- `lurek.filesystem.getUserDirectory`: Returns the current user's home directory path.
- `lurek.filesystem.getIdentity`: Returns the identity string used to locate the game's save directory.
- `lurek.filesystem.setIdentity`: Sets the identity string that names the game's sandboxed save-data directory.
- `lurek.filesystem.lines`: Returns an iterator function over the lines of a text file.
- `lurek.filesystem.readAsync`: Starts loading a file in the background and returns an opaque handle.
- `lurek.filesystem.pollAsync`: Polls an async load handle, returning status and optional data.
- `lurek.filesystem.mount`: Mounts a directory at a virtual path inside the game filesystem.
- `lurek.filesystem.unmount`: Removes a virtual mount layer by mountpoint.
- `lurek.filesystem.load`: Loads and compiles a Lua file from the VFS, returning it as a callable function.
- `lurek.filesystem.newFileData`: Loads a file from the VFS into a FileData buffer.
- `lurek.filesystem.copy`: Copies a file within the sandbox.
- `lurek.filesystem.move`: Moves (renames) a file within the `save/` directory.
- `lurek.filesystem.removeDir`: Recursively deletes a directory and all its contents within `save/`.
- `lurek.filesystem.glob`: Returns a sorted list of paths matching a simple wildcard pattern.

### `FileData` Methods
- `FileData:getSize`: Returns the file size in bytes.
- `FileData:getString`: Returns the file content as a Lua string.
- `FileData:getFilename`: Returns the virtual path this data was loaded from.

### `FileHandle` Methods
- `FileHandle:read`: Reads bytes from the file, returning them as a string.
- `FileHandle:readLine`: Reads the next line from the file without the trailing newline.
- `FileHandle:write`: Writes a string to the file and returns the number of bytes written.
- `FileHandle:seek`: Seeks the file position to the given byte offset from the start.
- `FileHandle:tell`: Returns the current read/write byte offset from the start of the file.
- `FileHandle:getSize`: Returns the size of the open file in bytes.
- `FileHandle:getMode`: Returns the access mode the file was opened with.
- `FileHandle:flush`: Flushes all buffered writes to disk without closing the handle.
- `FileHandle:close`: Flushes any pending writes and closes the file handle.
- `FileHandle:isEOF`: Returns whether the read cursor has reached the end of the file.

### `ZipMount` Methods
- `ZipMount:readFile`: Reads a file from the ZIP and returns it as a string of bytes.
- `ZipMount:contains`: Returns true if `virtual_path` exists inside this ZIP mount.
- `ZipMount:listFiles`: Returns a sorted array of all virtual paths exposed by this ZIP mount.
- `ZipMount:prefix`: Returns the virtual path prefix this archive was mounted under.

### New in 0.15.0 (Lua API)

- `lurek.filesystem.listRecursive(path)` — Recursively lists all files under `path` (relative to the game root). Returns a flat array of path strings. Raises a Lua error on path-traversal attempts (`..` in path) or if the directory cannot be read.
- `lurek.filesystem.stat(path)` — Returns a table `{ size: integer, isFile: boolean, isDir: boolean }` for the file or directory at `path` (sandboxed). Raises on path-traversal or missing entry.
- `lurek.filesystem.createTempFile(prefix?)` — Creates an empty scratch file under `save/` and returns its relative path. Each call generates a unique name. `prefix` is sanitised (alphanumeric, `_`, `-`; max 32 chars).

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/filesystem/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
