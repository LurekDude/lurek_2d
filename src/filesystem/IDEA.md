# IDEA — `src/filesystem/`

> **This file is forward-looking.** It records ideas, not commitments. Nothing here is
> implemented in the same session that produces it. Implementation is gated by a separate
> roadmap decision.

---

## 1. Header

- **Module**: `filesystem`
- **Owner module path**: `src/filesystem/`
- **Last reviewed**: 2026-04-18 (UTC)
- **Reviewer agent**: `developer` · Session: `src-module-review-20260418`
- **Plugin tier candidacy**: `CORE-KEEP`
- **LOC (rust only)**: ~850 · **Public Lua surface**: `lurek.filesystem` — ~25 fns / 1 userdata (FileHandle)
- **Inbound non-`lua_api` callers**: `app` (game dir resolution), `runtime` (VFS init)
- **Heavy dependencies**: `zip` (zip_mount only)

## 2. Mission Summary

Provides a sandboxed virtual filesystem that restricts all game I/O to the game directory.
Serves EngDev (engine integration), GameDev (file read/write from Lua), and Modder (mount
layers for mod content). Deliberately NOT a full OS filesystem abstraction — no symlink
creation, no arbitrary path access, no network filesystem support.

## 3. Existing Strengths

- Path-traversal prevention via canonicalization in `vfs.rs` — rejects `..` components before resolution.
- Write sandbox restricted to `save/` subdirectory — prevents scripts from writing outside game data.
- Virtual mount-layer system (newest-first search) supporting mod overlays cleanly.
- Background async loader with bounded channel and clean shutdown via Drop.
- ZIP archive mounting with normalised path index for O(1) lookups.
- Polling file watcher for hot-reload without OS-native notification coupling.

## 4. Gap List

1. ~~**[P2][GAP]** `Temp file creation` — no `createTempFile()` for intermediate processing.~~ ✅ **DONE** — Added `VirtualFs::create_temp_file` + `lurek.filesystem.createTempFile(prefix?)` Lua binding.
   - ~~Why: procedural generation or offline processing may need scratch files.~~
2. ~~**[P2][GAP]** `File size query without full metadata` — no lightweight size-only query.~~ ✅ **DONE** — Added `VirtualFs::stat` + `lurek.filesystem.stat(path)` returning `{size, isFile, isDir}`.
   - ~~Why: scripts checking file sizes in loops pay for unnecessary metadata.~~
3. ~~**[P3][GAP]** `Recursive glob` — current `glob()` is single-depth only; no `**` recursive descent.~~ ✅ **DONE** — Added `VirtualFs::list_recursive` and `lurek.filesystem.listRecursive(path)` Lua binding.
   - ~~Why: large projects with nested asset folders need deep wildcard search.~~

## 5. Feature Ideas

1. ~~**[P2][FEAT]** `lurek.filesystem.stat(path)` — Lightweight file-size and type query without full metadata.~~ ✅ **DONE** — Implemented as `VirtualFs::stat` + `lurek.filesystem.stat(path)`.
   - ~~Rationale: scripts checking sizes in loops pay for unnecessary `modified_time` + `readonly` lookups.~~
   - ~~Effort: S · Risk: low.~~
   - ~~Competitor inspiration: [Godot: FileAccess.get_length — docs.godotengine.org/en/stable/classes/class_FileAccess.html].~~
2. ~~**[P3][FEAT]** `Async write support` — extend AsyncLoader to support background writes.~~ ✅ **DONE** — Added `AsyncLoader::request_write` + `AsyncLoader::poll_write`, runtime bridge (`request_async_write` / `poll_async_write`), and Lua API `lurek.filesystem.writeAsync(path, data)` + `lurek.filesystem.pollAsyncWrite(handle)`.
   - ~~Rationale: large save files or screenshots can stall the main thread.~~
   - ~~Effort: M · Risk: med (write ordering guarantees needed).~~
   - ~~Competitor inspiration: [Solar2D: system.pathForFile + async callbacks — docs.coronalabs.com/api/library/system/pathForFile.html].~~
3. ~~**[P3][FEAT]** `lurek.filesystem.listRecursive(path)` — Recursive directory listing.~~ ✅ **DONE** — Implemented as `VirtualFs::list_recursive` + `lurek.filesystem.listRecursive`.
   - ~~Rationale: asset discovery without manual recursion in Lua.~~
   - ~~Effort: S · Risk: low.~~
   - ~~Competitor inspiration: [Defold: resource.get_all — defold.com/ref/stable/resource/].~~

## 6. Performance / Reliability / Quality Ideas

- ~~**[P2][PERF]** `Reduce redundant canonicalization` — `resolve_read_path` and `read_string` both canonicalize; internal calls could share the result.~~ ✅ **DONE** — `read_string` and `read_bytes` now delegate to `resolve_read_path`; `write_string` and `append_string` delegate to `resolve_save_path`.
   - ~~Hot path: `vfs.rs:120-170`.~~
   - Verification: benchmark with 1000 sequential reads.
- **[P3][REL]** `Async loader queue-full handling` — currently returns error silently. Should log a warning.
  - Files: `async_loader.rs:112-116`.
  - Suggested fix: add `log::warn!` when `try_send` fails.
- ~~**[P3][QUAL]** `Deduplicate path-traversal checks` — the `..` component check is repeated across write/append/resolve.~~ ✅ **DONE** — write/append now share `resolve_save_path`, which centralizes traversal rejection.
   - File: `vfs.rs`.
   - ~~Reason: extract a shared `reject_traversal(path)` helper.~~

## 7. Test Coverage Gaps

- **[P1][TEST-RUST]** Add Rust unit test for `vfs::GameFS` path-traversal rejection (sandboxable with temp dirs).
- **[P2][TEST-LUA]** Add Lua BDD test for `lurek.filesystem.read`, `lurek.filesystem.write`, `lurek.filesystem.append` under `tests/lua/filesystem/`.
- **[P2][TEST-RUST]** Add Rust unit test for `FileHandle::open` read/write/append modes.
- **[P3][TEST-FUZZ]** Fuzz target candidate: `vfs::resolve_read_path` with adversarial path strings.

## 8. TODO(dedup): Cross-Module Overlap

```text
TODO(dedup): save::SaveManager — save module duplicates write-to-save-dir logic that VFS already owns
TODO(dedup): image::load_image — image loader bypasses GameFS and uses std::fs::read directly
```

## 9. TODO(helper): Engine-Level Helper Candidates

```text
TODO(helper): fs_json_helper — JSON read/write pattern repeated in game scripts — citation: content/library/json/init.lua:1
```

## 10. TODO(plugin): Plugin Candidacy Proposal

```text
TODO(plugin): CORE-KEEP — filesystem is a foundational subsystem required by every game; extraction would break the sandbox contract.
```

- **Extraction blockers**: `runtime::shared_state` stores `GameFS` instance; `app` uses it for game loading.
- **Heavy dep impact if extracted**: `zip` crate (~0.3 MB) only used by `zip_mount`.
- **Lua surface stability**: stable.
- **Migration step**: n/a (CORE-KEEP).

## 11. References

- Module spec: [docs/specs/filesystem.md](../../../docs/specs/filesystem.md)
- Lua API reference: [docs/API/lua-api.md#fs](../../../docs/API/lua-api.md)
- Philosophy constraints touched: `A-01` (runtime only), `B-05` (TOML config)
- Plugin doc tier table: [plugins.md §5](../../../docs/architecture/plugins.md#5-candidate-modules)
- Authoring guide: [IDEA_AUTHORING.md](../../work/src-module-review-20260418/reports/IDEA_AUTHORING.md)
