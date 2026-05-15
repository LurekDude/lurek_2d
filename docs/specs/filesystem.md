# filesystem

## General Info

- Module group: `Core Runtime`
- Source path: `src/filesystem/`
- Lua API path(s): `src/lua_api/filesystem_api.rs`
- Primary Lua namespace: `lurek.filesystem`
- Rust test path(s): tests/rust/unit/filesystem_tests.rs
- Lua test path(s): tests/lua/unit/test_filesystem_core_unit.lua, tests/lua/stress/test_filesystem_stress.lua

## Summary

The `filesystem` module is Lurek2D's sandboxed virtual filesystem abstraction — a Core Runtime tier module that wraps all file I/O behind a `GameFS` type ensuring Lua scripts and engine code can only read and write within the game's allowed directory tree. It is the primary security boundary preventing path traversal attacks that could allow a game script to access arbitrary host files.

**Sandbox model.** `GameFS` is initialised with a base directory (the loaded game folder) and an optional separate save-data directory. Every path passed to any `GameFS` method is resolved against the base directory and checked against a traversal guard: components using `..`, symbolic links, or absolute path prefixes are rejected with `EngineError::FsPathTraversal` before the OS is ever consulted. The check resolves the canonical path and confirms it starts with the base directory prefix. Write operations are always routed to the save-data directory (if configured) rather than the read-only game folder; read operations can access both — mirroring LÖVE2D's content/save split.

**Core file API.** `GameFS` methods: `read_string(path)`, `read_bytes(path)`, `write_string(path, content)`, `write_bytes(path, data)`, `append_string(path, content)`, `read_lines(path)` (iterator), `list(path)` (directory entries), `get_directory_items(path)` (with type tags), `get_info(path)` → `FileInfo`, `exists(path)`, `create_directory(path)`, `remove(path)`, `copy_file(src, dst)`, `move_file(src, dst)`, `remove_dir(path)`, `glob(pattern)` (wildcard matching), and JSON helpers `read_json(path)`, `write_json(path, json)`, `read_or_write_json(path, default_json)`.

**FileHandle.** `FileHandle` provides an open-file session with explicit lifecycle: `open(path, mode)` → handle, `read(n)`, `read_all()`, `write(bytes)`, `seek(pos)`, `tell()`, `close()`. `FileMode` enum: `Read`, `Write`, `Append`, `ReadWrite`. Lua: `lurek.filesystem.open(path, mode)` returns a `FileHandle` userdata.

**FileInfo.** `FileInfo` carries: `file_type` (`File`, `Directory`, `Symlink`, `Other`), `size` (bytes), `mod_time` (Unix timestamp), `read_only` flag. Returned by `lurek.filesystem.getInfo(path)`.

**AsyncLoader.** `AsyncLoader` provides a background worker thread for non-blocking file reads and writes with bounded-channel back-pressure. Read path: `request_load(path) → LoadHandle` then `poll(handle) → LoadStatus`. Write path: `request_write(path, bytes) → LoadHandle` then `poll_write(handle) → WriteStatus`. Lua: `lurek.filesystem.readAsync(path)` / `pollAsync(handle)` and `lurek.filesystem.writeAsync(path, data)` / `pollAsyncWrite(handle)`.

**FileWatcher.** `FileWatcher` is a polling-based change detector that tracks file modification times. `watch(path)`, `check()` → changed paths, `unwatch(path)`. Designed for development hot-reload: Lua scripts watch their own assets and reload on change. Lua: `lurek.filesystem.newWatcher()` → `FileWatcher` userdata.

**ZIP archive support.** `ZipMount` / `ZipArchive` adds first-class ZIP archive support: files inside a `.zip` can be listed and read without extracting to disk. Lua: `lurek.filesystem.newZip(path)` → `ZipArchive` userdata; `zip:list()`, `zip:read(entry)`, `zip:exists(entry)`.

**Mount points.** `MountLayer` provides a read-only virtual filesystem overlay for archive and mod content packages. The `mods` module uses `MountLayer` to overlay mod `.lurek` archives over the base game directory, giving mod content transparent access through the same `GameFS` API.

**Lua surface.** `lurek.filesystem.read(path)`, `write(path, content)`, `append(path, content)`, `exists(path)`, `list(path)`, `getInfo(path)`, `mkdir(path)`, `remove(path)`, `copy(src, dst)`, `move(src, dst)`, `glob(pattern)`, `open(path, mode)` → `FileHandle`, `readAsync(path)` → handle, `pollAsync(handle)`, `writeAsync(path, data)` → handle, `pollAsyncWrite(handle)`, `newWatcher()` → `FileWatcher`, `mountZip(path, prefix)` → `LZipMount`.

**Scope boundary.** Core Runtime tier. Depends on `runtime` for error types. Lua bridge in `src/lua_api/filesystem_api.rs`.

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
- `WriteResult` (`enum`, `async_loader.rs`): Outcome of a completed write request.
- `WriteStatus` (`enum`, `async_loader.rs`): Status returned by [`AsyncLoader::poll_write`].
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

- `AsyncLoader::new` (`async_loader.rs`): Create a loader with a background worker thread.
- `AsyncLoader::request_load` (`async_loader.rs`): Queue a read request and return its handle even when the queue is full.
- `AsyncLoader::request_write` (`async_loader.rs`): Queue a write request and return its handle even when the queue is full.
- `AsyncLoader::poll` (`async_loader.rs`): Poll a read request and return its current status.
- `AsyncLoader::pending_results` (`async_loader.rs`): Return the number of completed read results waiting to be consumed.
- `AsyncLoader::poll_write` (`async_loader.rs`): Poll a write request and return its current status.
- `FileData::new` (`file_data.rs`): Create a file payload from a path and raw bytes.
- `FileData::len` (`file_data.rs`): Return the payload length in bytes.
- `FileData::is_empty` (`file_data.rs`): Return true when the payload has no bytes.
- `FileData::as_str` (`file_data.rs`): Decode the payload as UTF-8 or return the decode error.
- `FileMode::parse_mode` (`file_handle.rs`): Parse a mode string into a file mode or error on unsupported input.
- `FileMode::as_str` (`file_handle.rs`): Return the single-letter mode string used by Lua and save data.
- `FileHandle::open` (`file_handle.rs`): Open a GameFS file handle or error on path resolution, access, or OS failure.
- `FileHandle::read` (`file_handle.rs`): Read bytes from the open reader or error if the handle is not readable.
- `FileHandle::read_line` (`file_handle.rs`): Read the next line without its trailing newline or return None at EOF.
- `FileHandle::write` (`file_handle.rs`): Write bytes to the open writer or error if the handle is not writable.
- `FileHandle::seek` (`file_handle.rs`): Seek the active stream to an absolute byte offset or error when closed.
- `FileHandle::tell` (`file_handle.rs`): Read the current absolute byte offset or error when closed.
- `FileHandle::get_size` (`file_handle.rs`): Return the captured file size in bytes.
- `FileHandle::get_mode` (`file_handle.rs`): Return the current file mode.
- `FileHandle::get_path` (`file_handle.rs`): Return the logical path used to open the handle.
- `FileHandle::flush` (`file_handle.rs`): Flush buffered writes and return an error on write failure.
- `FileHandle::close` (`file_handle.rs`): Close the handle, flush pending writes, and release both buffered streams.
- `FileHandle::is_eof` (`file_handle.rs`): Check whether the reader has no buffered bytes left or error if unreadable.
- `FileType::as_str` (`vfs.rs`): Return the lowercase type label used in metadata output.
- `GameFS::new` (`vfs.rs`): Create a new filesystem rooted at the supplied base directory.
- `GameFS::base_dir` (`vfs.rs`): Return the root directory used for path resolution.
- `GameFS::read_string` (`vfs.rs`): Read a UTF-8 file through the mounted filesystem or return a filesystem error.
- `GameFS::read_bytes` (`vfs.rs`): Read a file as raw bytes or return a filesystem error.
- `GameFS::write_string` (`vfs.rs`): Write UTF-8 content into the save filesystem or return a filesystem error.
- `GameFS::write_bytes` (`vfs.rs`): Write raw bytes into the save filesystem or return a filesystem error.
- `GameFS::read_json` (`vfs.rs`): Validate JSON content and return the original string on success.
- `GameFS::write_json` (`vfs.rs`): Validate JSON text and write it to the save filesystem.
- `GameFS::read_or_write_json` (`vfs.rs`): Read existing JSON or create it from the default payload when missing.
- `GameFS::exists` (`vfs.rs`): Return true when the base filesystem path exists.
- `GameFS::list` (`vfs.rs`): List entries in a directory without recursion.
- `GameFS::list_recursive` (`vfs.rs`): List directory entries recursively under the resolved read path.
- `GameFS::get_directory_items` (`vfs.rs`): Return sorted directory entries from the resolved read path.
- `GameFS::is_file` (`vfs.rs`): Return true when the resolved path points to a file.
- `GameFS::is_directory` (`vfs.rs`): Return true when the resolved path points to a directory.
- `GameFS::create_directory` (`vfs.rs`): Create a directory tree in the save filesystem or return a filesystem error.
- `GameFS::remove` (`vfs.rs`): Remove a file or directory from the save filesystem or return a filesystem error.
- `GameFS::get_info` (`vfs.rs`): Read metadata for a path and return a normalized file info record.
- `GameFS::append_string` (`vfs.rs`): Append UTF-8 content into a file in the save filesystem.
- `GameFS::get_source` (`vfs.rs`): Return the base directory as a string for reporting.
- `GameFS::get_save_directory` (`vfs.rs`): Return the save directory path under the base directory.
- `GameFS::get_working_directory` (`vfs.rs`): Return the current working directory as a string or filesystem error.
- `GameFS::get_user_directory` (`vfs.rs`): Return the user home directory string or fall back to the current directory.
- `GameFS::get_identity` (`vfs.rs`): Return the current identity string assigned to the filesystem.
- `GameFS::set_identity` (`vfs.rs`): Set the identity string used by filesystem callers.
- `GameFS::mount` (`vfs.rs`): Mount a source directory under a virtual mountpoint or return an error.
- `GameFS::mount_full` (`vfs.rs`): Mount an already validated path under a virtual mountpoint or return an error.
- `GameFS::unmount` (`vfs.rs`): Remove a mountpoint and return true when one was removed.
- `GameFS::load_chunk` (`vfs.rs`): Read a chunk path from the newest matching mount layer or from the base filesystem.
- `GameFS::get_directory_items_merged` (`vfs.rs`): Merge directory entries from the base path and any mounted overlays.
- `GameFS::resolve_read_path` (`vfs.rs`): Resolve a readable path into a canonical host path or return a filesystem error.
- `GameFS::resolve_save_path` (`vfs.rs`): Resolve a writable path inside save/ or return a filesystem error.
- `GameFS::read_lines` (`vfs.rs`): Read a file and split it into owned lines.
- `GameFS::open_file` (`vfs.rs`): Open a file handle from a mode string or return a filesystem error.
- `GameFS::copy_file` (`vfs.rs`): Copy a file into the save filesystem or return a filesystem error.
- `GameFS::move_file` (`vfs.rs`): Move a file inside the save filesystem or return a filesystem error.
- `GameFS::remove_dir` (`vfs.rs`): Remove a directory tree from the save filesystem or return a filesystem error.
- `GameFS::glob` (`vfs.rs`): Return sorted matches for a glob pattern within a readable directory.
- `GameFS::stat` (`vfs.rs`): Return size and kind flags for the resolved path.
- `GameFS::create_temp_file` (`vfs.rs`): Create a unique temporary file under save/ and return its logical path.
- `FileWatcher::new` (`watcher.rs`): Create an empty file watcher.
- `FileWatcher::watch` (`watcher.rs`): Start watching a path and cache its current modification time.
- `FileWatcher::unwatch` (`watcher.rs`): Stop watching a path if it is present.
- `FileWatcher::is_watching` (`watcher.rs`): Return true when the watcher contains the path.
- `FileWatcher::poll` (`watcher.rs`): Poll all watched paths and return the ones whose modification time changed.
- `FileWatcher::len` (`watcher.rs`): Return the number of watched paths.
- `FileWatcher::is_empty` (`watcher.rs`): Return true when no paths are watched.
- `FileWatcher::force_changed` (`watcher.rs`): Force all watched paths to report a change on the next poll.
- `read_mtime` (`watcher.rs`): Read the last modification time for a path or return None on metadata failure.
- `ZipMount::new` (`zip_mount.rs`): Build a ZIP mount index or return an error on archive open or parse failure.
- `ZipMount::read_file` (`zip_mount.rs`): Read a virtual file from the archive or return an error when missing or invalid.
- `ZipMount::contains` (`zip_mount.rs`): Return true when the virtual path is indexed in the archive.
- `ZipMount::list_files` (`zip_mount.rs`): Return all indexed virtual paths in sorted order.
- `normalise` (`zip_mount.rs`): Normalise a path: collapse duplicate slashes, strip leading slash.
- `is_traversal` (`zip_mount.rs`): Returns `true` if any path component is `..`, or if the path starts with a drive letter (Windows absolute), to prevent traversal attacks.

## Lua API Reference

- Binding path(s): `src/lua_api/filesystem_api.rs`
- Namespace: `lurek.filesystem`

### Module Functions
- `lurek.filesystem.mountZip`: Opens a ZIP archive and exposes it through a virtual prefix.
- `lurek.filesystem.watchPath`: Adds a path to the module-local file watcher.
- `lurek.filesystem.unwatchPath`: Removes a path from the module-local file watcher.
- `lurek.filesystem.pollWatchers`: Polls watched paths and returns paths that changed since the previous poll.
- `lurek.filesystem.read`: Reads a UTF-8 text file from GameFS.
- `lurek.filesystem.write`: Writes a UTF-8 text file through GameFS.
- `lurek.filesystem.readJson`: Reads a JSON document as text from GameFS.
- `lurek.filesystem.writeJson`: Writes JSON text through GameFS.
- `lurek.filesystem.readOrWriteJson`: Reads a JSON file or writes and returns default JSON when the file is absent.
- `lurek.filesystem.readBytes`: Reads a binary file from GameFS and returns the bytes as a Lua string.
- `lurek.filesystem.writeBytes`: Writes binary data through GameFS.
- `lurek.filesystem.exists`: Returns whether a path exists in GameFS.
- `lurek.filesystem.append`: Appends UTF-8 text to a GameFS file.
- `lurek.filesystem.openFile`: Opens a GameFS file handle in a requested mode.
- `lurek.filesystem.getDirectoryItems`: Lists immediate entries in a GameFS directory.
- `lurek.filesystem.isFile`: Returns whether a GameFS path is a regular file.
- `lurek.filesystem.isDirectory`: Returns whether a GameFS path is a directory.
- `lurek.filesystem.createDirectory`: Creates a GameFS directory and any missing parents.
- `lurek.filesystem.remove`: Removes a GameFS file or supported path.
- `lurek.filesystem.getInfo`: Returns file metadata for a GameFS path when available.
- `lurek.filesystem.getSource`: Returns the GameFS source root string.
- `lurek.filesystem.getSaveDirectory`: Returns the save directory path used by GameFS.
- `lurek.filesystem.getWorkingDirectory`: Returns the process working directory.
- `lurek.filesystem.getUserDirectory`: Returns the current user's directory path.
- `lurek.filesystem.getIdentity`: Returns the current filesystem identity string.
- `lurek.filesystem.setIdentity`: Sets the filesystem identity string used by save paths.
- `lurek.filesystem.lines`: Creates an iterator function over lines in a text file.
- `lurek.filesystem.readAsync`: Starts an asynchronous file load request.
- `lurek.filesystem.pollAsync`: Polls an asynchronous file load request.
- `lurek.filesystem.writeAsync`: Starts an asynchronous file write request.
- `lurek.filesystem.pollAsyncWrite`: Polls an asynchronous file write request.
- `lurek.filesystem.mount`: Mounts an external source path at a GameFS mount point.
- `lurek.filesystem.unmount`: Removes a GameFS mount point.
- `lurek.filesystem.load`: Loads a Lua chunk from GameFS and returns it as a Lua function.
- `lurek.filesystem.newFileData`: Loads a file into an immutable file data handle.
- `lurek.filesystem.copy`: Copies one GameFS file to another path.
- `lurek.filesystem.move`: Moves or renames one GameFS file to another path.
- `lurek.filesystem.removeDir`: Removes a GameFS directory.
- `lurek.filesystem.glob`: Returns GameFS paths matching a glob pattern.
- `lurek.filesystem.listRecursive`: Lists all paths under a GameFS directory recursively.
- `lurek.filesystem.stat`: Returns size and file/directory flags for a GameFS path.
- `lurek.filesystem.createTempFile`: Creates a temporary file through GameFS.
- `lurek.filesystem.mkdir`: Creates a directory under the GameFS base directory.
- `lurek.filesystem.toAbsolutePath`: Resolves a GameFS-relative path against the filesystem base directory.

### `LFileData` Methods
- `LFileData:getSize`: Returns the byte length of this file data.
- `LFileData:getString`: Returns file data bytes as a Lua string without UTF-8 validation.
- `LFileData:getFilename`: Returns the path associated with this file data object.
- `LFileData:type`: Returns the Lua-visible type name for this file data handle.
- `LFileData:typeOf`: Returns whether this file data handle matches a supported type name.

### `LFileHandle` Methods
- `LFileHandle:read`: Reads up to an optional byte count and returns text using lossless UTF-8 replacement.
- `LFileHandle:readLine`: Reads the next line from this file handle.
- `LFileHandle:write`: Writes a string to this file handle.
- `LFileHandle:seek`: Moves the file cursor to an absolute byte position.
- `LFileHandle:tell`: Returns the current file cursor position.
- `LFileHandle:getSize`: Returns the size of the open file.
- `LFileHandle:getMode`: Returns the mode used to open this file handle.
- `LFileHandle:flush`: Flushes pending writes on this file handle.
- `LFileHandle:close`: Closes this file handle.
- `LFileHandle:isEOF`: Returns whether the file cursor is at end of file.
- `LFileHandle:type`: Returns the Lua-visible type name for this file handle.
- `LFileHandle:typeOf`: Returns whether this file handle matches a supported type name.

### `LZipMount` Methods
- `LZipMount:readFile`: Reads a file from the ZIP mount by virtual path.
- `LZipMount:contains`: Returns whether a virtual path exists in the ZIP mount.
- `LZipMount:listFiles`: Returns every virtual file path in the ZIP mount.
- `LZipMount:prefix`: Returns the virtual prefix used by this ZIP mount.
- `LZipMount:type`: Returns the Lua-visible type name for this ZIP mount handle.
- `LZipMount:typeOf`: Returns whether this ZIP mount handle matches a supported type name.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/filesystem/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
