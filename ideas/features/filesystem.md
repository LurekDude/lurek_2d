# filesystem — Feature Analysis

**Tier**: 1 (Core)
**Spec**: `specs/filesystem.md`
**Files**: GameFS sandbox, VFS mounts, FileHandle, AsyncLoader

## Purpose

Sandboxed filesystem access via GameFS: read/write files within game directory and user save directory. Virtual filesystem with mount points. Async file loading.

## Current Feature Summary

- `GameFS`: sandboxed VFS with mount points (game dir read-only, save dir read-write)
- Path validation: canonicalize, prefix check, null-byte rejection, no absolute paths
- `FileHandle`: buffered read/write with seek
- `AsyncLoader`: background file loading with completion callbacks
- File operations: read, write, exists, remove, list, mkdir, stat
- Directory listing with file info (size, modified time)
- Working directory query
- String encoding: UTF-8 enforced

## Feature Gaps

1. **No ZIP archive mounting**: Can't treat a ZIP file as a virtual directory. Love2D has this (`.love` is a ZIP). Essential for distribution and mod support.
2. **No file watcher/notify**: Can't detect when files change on disk. Critical for hot reload workflows.
3. **No glob/pattern matching**: `listFiles()` returns all files; can't filter with `*.lua` or `**/*.png`.
4. **No recursive directory deletion**: Must manually walk and delete. Common need for cleanup.
5. **No temp files**: No `createTempFile()` for intermediate processing.
6. **No symlink support**: Symlinks are resolved but can't be created. Low priority.
7. **No file locking**: Can't lock files for exclusive access. Relevant for save files with multiple processes.
8. **No file copy/move**: Must read+write to copy a file. `luna.filesystem.copy(src, dst)` would be convenient.

## Structural Issues

- **Clean security boundary**: Path validation is thorough. Null-byte rejection and canonicalization are correct for preventing path traversal.
- **AsyncLoader scope**: Async file loading is good but the completion mechanism (callback or polling?) should be clarified.
- **Mount system**: VFS mounts enable modding support by layering directories. Well-designed.

## Suggestions

1. **Add ZIP mounting** (high priority): `luna.filesystem.mountZip(path, mountPoint)` — unlocks `.luna` distribution format and mod archives.
2. **Add file watcher**: `luna.filesystem.watch(path, fn)` — callback when file changes. Enables hot reload — the most requested missing feature.
3. **Add glob listing**: `luna.filesystem.glob("assets/**/*.png")` → filtered file list. Quality-of-life.
4. **Add file copy**: `luna.filesystem.copy(src, dst)` and `luna.filesystem.move(src, dst)`.
5. **Add recursive rmdir**: `luna.filesystem.removeDir(path, recursive)`.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy |
|---|---|---|---|---|
| Sandboxed FS | ✅ | ✅ | ✅ | ❌ (raw) |
| ZIP mounting | ❌ | ✅ (.love) | ❌ | ❌ |
| File watcher | ❌ | ❌ | ❌ | ✅ (asset server) |
| Async loading | ✅ | ❌ | ✅ | ✅ |
| VFS mounts | ✅ | ✅ | ❌ | ❌ |
| Glob | ❌ | ❌ | ❌ | ✅ |

## Priority

**HIGH** — ZIP mounting is critical for the distribution story (`.luna` format). File watcher enables hot reload. Both are high-value features.
