# parallax

## Module Info
- Module name: `parallax`
- Module group: `Feature Systems`
- Spec path: `docs/specs/parallax.md`
- Lua API path(s): `src/lua_api/parallax_api.rs`
- Rust test path(s): inline tests in `src/parallax/layer.rs`, `src/parallax/render.rs`, and `src/parallax/draw.rs`
- Lua test path(s): `tests/lua/unit/test_parallax.lua`, `tests/lua/integration/test_parallax_camera.lua`

## Module Purpose
The `parallax` module provides CPU-side scrolling background layers for side views, overhead views, and atmospheric scene dressing. It computes how a textured layer should move relative to camera motion, optional autoscroll, tiling, opacity, tint, and blend mode.

It exists to keep background-layer math and batching separate from the renderer and from game scripts. Scripts decide which layers exist and when to draw them, while the module turns layer state into concrete draw batches or render commands.

It intentionally does not own texture loading, GPU resources, or camera state itself. Those concerns remain in shared runtime state and in the render pipeline; `parallax` just interprets them to produce scroll-aware draw data.

## Files
- `mod.rs` - Declares the parallax submodules and re-exports the main layer and batch types.
- `draw.rs` - Implements CPU-side image drawing for headless and test-friendly parallax output without depending on the GPU path.
- `layer.rs` - Defines `ParallaxLayer` state, scroll calculations, autoscroll behavior, and batch-building logic.
- `render.rs` - Converts parallax batches into `RenderCommand` sequences with color, blend mode, and repeated image draws.

## Key Types
- `ParallaxLayer` - The main scrolling background layer. It owns camera-relative scroll factors, offsets, tiling, opacity, tint, scale, bounds, and z-order.
- `ParallaxDrawBatch` - A CPU-side batch description generated from a layer so the Lua bridge or renderer can issue the actual draw commands.
| `draw.rs`  | CPU headless drawing — `draw_to_image()` on `ParallaxLayer`; returns solid-colour fill from layer tint and opacity for headless testing. |

