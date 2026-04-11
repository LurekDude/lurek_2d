# filesystem

## Module Info
- Module name: `filesystem`
- Module group: `Core Runtime`
- Spec path: `docs/specs/filesystem.md`
- Lua API path(s): `src/lua_api/filesystem_api.rs`
- Rust test path(s): `tests/rust/unit/filesystem_tests.rs`, plus inline unit coverage in `src/filesystem/async_loader.rs`
- Lua test path(s): `tests/lua/unit/test_filesystem.lua`, `tests/lua/stress/test_filesystem_stress.lua`, `tests/lua/integration/test_data_filesystem.lua`

## Module Purpose

The filesystem module owns all sandboxed game I/O in Lurek2D. It gives the engine a single virtual filesystem rooted at the game directory, constrains writes to the save area, supports overlay mount layers, and provides both direct file handles and background read requests for scripts that need non-blocking asset loads.

This module exists to keep game scripts productive without giving them unrestricted access to the host filesystem. `GameFS` resolves and validates paths, `FileHandle` exposes buffered read and write operations inside that sandbox, `FileData` packages raw file bytes for Lua consumption, and `AsyncLoader` lets the main thread offload file reads without introducing a general async runtime.

It intentionally does not own network I/O, archive formats, arbitrary process-wide file access, or rendering-specific asset decoding. If the work is about PNG parsing, audio decoding, or remote data transport, that belongs elsewhere. The Lua API in `src/lua_api/filesystem_api.rs` owns how this sandbox is presented to scripts; the core module owns the actual path safety and file behavior.

## Files
- `mod.rs` is the public module root and re-export surface. It ties together the sandboxed VFS, file handles, raw file-data buffers, and async loader.
- `vfs.rs` implements `GameFS`, metadata types, path resolution, read and write policy, and mount-layer behavior. This is the module's security-critical file because traversal prevention lives here.
- `file_handle.rs` implements the buffered open-file abstraction used for incremental read and write access. It is the right place for mode parsing, seek behavior, EOF checks, and buffered flushing semantics.
- `file_data.rs` defines the simple owned byte buffer returned when scripts need whole-file content packaged as an object. It is intentionally small and dumb.
- `async_loader.rs` implements the dedicated background reader used for non-blocking file loads. It owns request handles, completion status, and the worker-thread lifecycle.

## Key Types
- `GameFS` is the module's central ownership object. It stores the base directory, current identity, and virtual mount stack and is responsible for enforcing the filesystem sandbox.
- `MountLayer` describes one mounted overlay source and its virtual mountpoint. It matters when reasoning about mod folders and lookup precedence.
- `FileInfo` is the metadata snapshot returned by path queries. It is the lightweight inspection format for size, type, modification time, and read-only state.
- `FileType` is the coarse classification used by `FileInfo`. It keeps file and directory checks explicit instead of relying on raw OS metadata everywhere.
- `FileHandle` is the buffered open-file object for streamed access inside the sandbox. It is the right abstraction when scripts need incremental reads, writes, seeks, or EOF checks rather than one-shot reads.
- `FileMode` defines the allowed handle modes and the string parsing contract used by Lua. It is small, but it controls an important API boundary.
- `FileData` is the owned whole-file buffer exposed to Lua. Use it when a script needs bytes or a UTF-8 string snapshot, not an open handle.
- `AsyncLoader` is the module's non-blocking read service. It deliberately handles only background file loading, not generic task execution.
- `LoadHandle`, `LoadResult`, and `LoadStatus` are the async-loader handshake types. Together they define how a queued background read is identified, completed, or reported as pending.
- `LuaFileHandle` and `LuaFileData` in `src/lua_api/filesystem_api.rs` are the main scripting bridge objects for this module. They matter because they lock down exactly which handle and data operations scripts can perform.