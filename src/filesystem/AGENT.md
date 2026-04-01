# src/filesystem/

Sandboxed virtual filesystem restricting I/O to the game directory.

## What This Module Contains

GameFS enforces path containment (no traversal outside game dir). VirtualFS adds mount points for game dir, save dir, and archive files. FileHandle provides buffered read/write. AsyncLoader runs background asset loading on a worker thread.

## Files

| File | Purpose |
|------|---------|
| `async_loader.rs` | `AsyncLoader` implementation |
| `file_handle.rs` | `FileHandle` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |
| `vfs.rs` | `Vfs` implementation |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/filesystem_tests.rs`
- **Lua API bindings**: `src/lua_api/filesystem_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
