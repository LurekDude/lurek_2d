# `filesystem` � Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 � Core Engine Subsystems                      |
| **Status**     | Implemented � Full                                   |
| **Lua API**    | `lurek.fs`                                    |
| **Source**     | `src/filesystem/`                                    |
| **Rust Tests** | `tests/rust/unit/filesystem_tests.rs`                |
| **Lua Tests**  | `tests/lua/unit/test_filesystem.lua`                 |
| **Architecture** | �                                                  |

## Purpose

The `filesystem` module provides all game I/O through `GameFS`, a sandboxed virtual filesystem that forces every resolved path to stay within the game's own directory or a designated per-identity save directory. This security model prevents path-traversal attacks (e.g. `../../etc/passwd`) and ensures Lua scripts cannot read or write arbitrary files on the host system. Read operations are sandboxed to the game root directory via `resolve_read_path()`, which canonicalises the path and verifies it starts with the base directory. Write operations are further restricted to the `save/` subdirectory via `resolve_save_path()`, blocking `..` components in both the logical path and the resolved canonical path. `FileHandle` wraps a single open file in one of four modes � Read, Write, Append, or Closed � with buffered line-by-line and bulk read/write operations using `BufReader`/`BufWriter`. `AsyncLoader` dispatches background file reads to a dedicated worker thread via a bounded sync channel (64-slot capacity) and returns a `LoadHandle` immediately; the Lua loop polls `pollAsync()` each frame without blocking the event loop. The VFS mount layer system allows overlaying additional directories (e.g. mod folders) at virtual mountpoints, with newest-mounted layers searched first. `FileData` provides a simple raw-bytes buffer for files loaded through the VFS. The `identity` field namespaces a game's writable directory separately from its read-only asset tree, preventing save-file collisions between games sharing the same engine install. The module intentionally does not provide network I/O, ZIP archive decompression (that is handled by `VirtualFS` in the engine layer), or recursive directory deletion � these are out of scope.

## Source Files

| File              | Purpose                                                              |
|-------------------|----------------------------------------------------------------------|
| `mod.rs`          | Module root; re-exports `GameFS`, `AsyncLoader`, `FileHandle`, `FileData`, `MountLayer` |
| `vfs.rs`          | `GameFS` sandboxed filesystem, `FileInfo`, `FileType`, `MountLayer`, path resolution, mount layers |
| `file_handle.rs`  | `FileHandle` with buffered read/write/seek/close, `FileMode` enum   |
| `file_data.rs`    | `FileData` raw byte buffer loaded from VFS                          |
| `async_loader.rs` | `AsyncLoader` background file reader, `LoadHandle`, `LoadResult`, `LoadStatus` |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

� [`docs/specs/filesystem.md`](../../docs/specs/filesystem.md)

_Update both this file **and** `docs/specs/filesystem.md` whenever source files, public types, or Lua bindings change._
