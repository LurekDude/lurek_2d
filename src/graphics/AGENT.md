# `graphics` — Agent Reference

| Property       | Value                                                                    |
|----------------|--------------------------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                                          |
| **Status**     | Implemented — Partial (migration to `src/render/` in progress)           |
| **Lua API**    | `lurek.graphic` (registered via `src/lua_api/render_api.rs`)             |
| **Source**     | `src/graphics/` (single file; bulk of implementation in `src/render/`)   |
| **Rust Tests** | `tests/rust/unit/graphics_tests.rs`, `tests/rust/ext/graphics_runtime_smoke_tests.rs` |
| **Lua Tests**  | `tests/lua/unit/test_graphics.lua`                                       |
| **Spec**       | `docs/specs/graphics.md`                                                 |

## Purpose

`src/graphics/` currently contains a single file — `gpu_renderer.rs` — which is the
primary wgpu GPU renderer implementation.  During the `refactor/src-migration-v2`
branch this module is being merged into `src/render/`, which already hosts the full
GPU rendering pipeline including the `RenderCommand` queue, all resource types
(textures, fonts, canvases, shaders, meshes, sprite batches), the transform stack,
blend modes, and the camera/light/effect sub-modules.

**Important**: The Lua API (`lurek.graphic.*`) is registered entirely by
`src/lua_api/render_api.rs`, not by any code in this folder.  Domain types that
have already been migrated live in `src/render/`.

## Source Files

| File             | Purpose                                                                |
|------------------|------------------------------------------------------------------------|
| `gpu_renderer.rs` | wgpu GPU renderer: device management, swap-chain presentation, render pass execution, resource `SlotMap` pools. Being merged into `src/render/gpu_renderer.rs`. |

## Key Types

| Type          | Description                                                              |
|---------------|--------------------------------------------------------------------------|
| `GpuRenderer` | Central GPU renderer; processes the `RenderCommand` queue into wgpu draw calls and manages all GPU resource pools (`TextureKey`, `FontKey`, `CanvasKey`, etc.). |

## Lua API Summary

All `lurek.graphic.*` bindings are in `src/lua_api/render_api.rs`.
See `docs/specs/graphics.md` for the full API surface (66 functions, 7 UserData types).

## Migration Note

When `gpu_renderer.rs` is fully moved to `src/render/`, this folder may be removed.
Track progress on the `refactor/src-migration-v2` branch.  Do not add new files to
`src/graphics/` — direct all new rendering work to `src/render/` instead.
