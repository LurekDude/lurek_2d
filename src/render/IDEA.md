# IDEA.md — render

| Field  | Value             |
| ------ | ----------------- |
| Module | render            |
| Path   | src/render/       |
| Date   | 2026-04-18        |
| Tier   | Platform Services |

---

## Mission

GPU rendering layer backed by wgpu 22.  Implements a deferred `RenderCommand` queue:
Lua callbacks push draw commands during `lurek.render()`, then `GpuRenderer::render_frame()`
processes the queue, batches compatible draw calls, and presents the swapchain surface.
No GPU work happens inside a Lua closure.

---

## Strengths

- **Comprehensive draw surface**: 40+ `RenderCommand` variants covering primitives, images,
  text, meshes, particles, spine skeletons, post-processing, and compositing layers.
- **Pipeline caching**: `PipelineKey`-based cache avoids re-creating wgpu render pipelines
  each frame; blend mode, stencil state, and color mask are all keyed.
- **Rich post-FX library**: 17 built-in WGSL effects (bloom, blur, CRT, vignette, dither,
  god rays, etc.) with a uniform parameter slot layout and custom shader registration.
- **2D lighting with shadow maps**: 1D radial shadow atlas, occluder-aware raycasting, and
  additive light accumulation — all within the 2D constraint.
- **Bitmap font system**: 6 built-in sizes from embedded PNGs; glyph lookup is grid-based
  (no HashMap), including optional Unicode box-drawing characters.
- **Custom shader support**: User WGSL validated via naga, entry-point rewritten into a
  wrapper for safe composition with the engine's vertex stage.

---

## Gaps

- **No anti-aliased lines/shapes**: rotated rectangles and small circles show jagged edges;
  needs MSAA pipeline variant or geometry-shader AA strips.
- **No GPU instancing**: N identical sprites = N draw calls; particle-heavy scenes pay a
  linear cost. Instance buffer would reduce to 1 draw call per texture.
- **No geometry caching**: static background geometry is re-tessellated from `RenderCommand`
  every frame; a "static draw" mode would skip re-tessellation.
- **Screenshot to ImageData missing**: `saveScreenshot` writes PNG to disk; no in-memory
  readback path for Lua-side pixel processing.
- **Module size**: 13 source files, 6 100+ line gpu_renderer.rs — largest module in the engine.
  A sub-module split (core, text, sprite, shader, shape) may improve maintainability.

---

## Features (competitor context, max 3 cites)

| Feature            | Lurek2D status | Competitor reference                                                                     |
| ------------------ | -------------- | ---------------------------------------------------------------------------------------- |
| GPU instancing     | ❌ TODO         | Bevy uses automatic batching + GPU instancing for identical meshes (bevy_render).        |
| Anti-aliased lines | ❌ TODO         | LÖVE 2D uses MSAA (setLineStyle "smooth") for anti-aliased vector drawing.               |
| Post-processing FX | ✅ 17 built-in  | Godot has a similar per-viewport post-process stack (WorldEnvironment + custom shaders). |

---

## Perf / Quality

- Viewport frustum culling on `DrawImage`/`DrawImageEx`/`DrawQuad`/`Rectangle` — skips
  tessellation when AABB falls outside the viewport.
- Transform stack is composed per-vertex on CPU; pushing to a UBO would reduce bus traffic
  at high vertex counts (low priority — measure first).
- Adaptive circle LOD (segment count based on screen-space radius) not yet implemented.

---

## Test Gaps

- `gpu_renderer.rs`: Existing inline tests cover stencil state builders. `compute_1d_shadow_map`
  (pure CPU raycasting) is untested — should have unit tests but is private; consider `pub(crate)`.
- `font.rs`: Newly added tests cover `nearest_size`, glyph lookup, `text_width`, `wrap_text`.
- `mesh.rs`: Newly added tests cover constructors, triangulate (all 3 modes), index buffer.
- `postfx_pipeline.rs`: `params_to_uniform` tested in sibling file. GPU pipeline creation untestable without device.
- `renderer.rs`: Defaults and `TextSpan::new` tested in sibling file. `RenderCommand` enum itself is data-only.
- `shader.rs`: 14 tests cover WGSL validation, uniform ordering, entry-point rewriting,
  plus pure-logic text helpers (`split_top_level_commas`, `find_matching_paren`,
  `consume_attribute`, `strip_leading_attributes`, `has_uniform`).
- Overall Lua test coverage for `lurek.render.*` is low (42 missing per P4 matrix).

---

## TODO(dedup): render ↔ pipeline

`postfx_pipeline.rs` lives inside `src/render/` and is tightly coupled to `GpuRenderer`.
Meanwhile `src/pipeline/` exists as a separate top-level module.  Clarify ownership:
- If `src/pipeline/` handles CPU-side render-command scheduling, it may overlap with
  `RenderCommand` batching logic in `gpu_renderer.rs`.
- If `src/pipeline/` is purely for asset/build pipelines, rename to avoid confusion.

## TODO(dedup): render ↔ effect

`image_effect.rs` in `src/render/` stores `ShaderPassDescriptor` — a Tier 1 type.
`src/effect/` is a separate module that owns `ImageEffect` and `PostFxEffect`.
The `to_passes()` bridge converts `ImageEffect → Vec<ShaderPassDescriptor>` in lua_api.
Potential overlap: both modules hold effect parameter dictionaries; consider consolidating
the parameter mapping into `src/effect/` and keeping `src/render/` free of effect semantics.

---

## TODO(helper):

- Extract `compute_1d_shadow_map` from `gpu_renderer.rs` to a `shadow_map.rs` helper and
  make it `pub(crate)` for unit testing.
- Extract the WGSL shader string constants (COLOR_SHADER, TEXTURE_SHADER, LIGHT_SHADER) from
  `gpu_renderer.rs` into a `shaders/` submodule to reduce the 6 100-line file.
- Extract `blend_state_for()` to a shared helper visible to both `GpuRenderer` and
  `PostFxPipeline` to avoid duplicating blend-mode logic.
- **Code duplication in `postfx_pipeline.rs`**: `apply()` and `run_copy_pass()` are
  duplicated 3× (lines ~870, ~960, ~1100) — likely a merge/edit artifact. Deduplicate
  to a single `impl PostFxPipeline` block.

---

## TODO(plugin): CORE-KEEP

The render module is **CORE-KEEP** — it cannot be extracted as an optional plugin.

**Rationale**: Every game that runs on Lurek2D requires a GPU renderer; the `lurek.render.*`
namespace is the primary visual output surface. Removing it would reduce the engine to a
headless Lua runtime. The wgpu dependency is unavoidable for the engine's stated purpose
(2D desktop games at 60 FPS on integrated GPUs). The postfx pipeline and custom shader
support are built atop the same wgpu device/queue — splitting them into a separate crate
would add IPC overhead for zero user benefit.

---

## References

- `docs/specs/render.md` — canonical module spec.
- `src/lua_api/render_api.rs` — Lua bridge (registered as `lurek.render.*`).
- `src/effect/` — higher-level effect definitions (`ImageEffect`, `PostFxEffect`).
- `src/pipeline/` — separate pipeline module (overlap candidate).
- `docs/API/lua-api.md` — generated Lua API reference.
