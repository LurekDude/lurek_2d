# render

## Module Info
- Group: Platform Services.
- Source: `src/render/`.
- Spec: `docs/specs/render.md`.
- Lua bridge: `src/lua_api/render_api.rs` registers the `lurek.graphic` surface on top of these types.
- Runtime focus: deferred render-command queue plus the wgpu backend that executes it.

## Module Purpose
The render module owns the engine's core 2D rendering pipeline. It exists so Lua and higher-level systems can describe draw intent through `RenderCommand` values while the engine keeps control of batching, resource uploads, pipeline state, canvas targets, and final frame execution.

Its boundary is the command queue and backend needed to consume it: canvases, fonts, shaders, meshes, vector shapes, draw layers, decals, and lightweight effect descriptors live here because they are part of the renderer's own object model. It does not own sprite-domain data now housed under `src/sprite/`, and it does not own separate feature systems that consume rendering such as scene flow or gameplay animation.

## Files
- `mod.rs`: Module root and public re-export surface for the active render submodules.
- `canvas.rs`: Logical off-screen render-target descriptor used by the backend and Lua canvas APIs.
- `decal_surface.rs`: Persistent descriptor for decal stamping targets.
- `draw_layer.rs`: Ordered callback queue for grouped draw-order management.
- `font.rs`: Bitmap font loading, atlas storage, glyph lookup, and text-measurement helpers.
- `gpu_renderer.rs`: Concrete wgpu renderer for device setup, resource pools, pipeline caching, and frame execution.
- `image_effect.rs`: Lightweight per-image shader-pass descriptor used by render commands.
- `mesh.rs`: Custom geometry data structures and mesh draw-mode support.
- `renderer.rs`: Render-command enum plus blend, stencil, depth, text, and texture-side data types.
- `shader.rs`: Custom WGSL shader objects, validation, and typed uniform values.
- `shape.rs`: Compound vector-shape builder and the primitive command list it records.

## Key Types
- `RenderCommand`: Central deferred draw-operation enum consumed by the backend.
- `GpuRenderer`: wgpu-backed renderer that owns the actual frame, pipeline, and GPU resource logic.
- `Canvas`: Off-screen target descriptor for drawing into textures instead of the swapchain.
- `Font`: Render-side text resource with atlas and measurement behavior.
- `TextureData`: CPU-side pixel container handed off for GPU texture upload.
- `BlendMode`: Public blend-policy enum used by queued draw operations.
- `DrawMode`: Fill-versus-line enum used by vector primitives.
- `StencilMode`, `StencilAction`, `CompareMode`, `DepthMode`: Core depth and stencil state vocabulary for queued rendering.
- `Shader` and `UniformValue`: Custom shader object plus the typed values scripts can send into it.
- `Mesh` and `MeshVertex`: Custom geometry types for explicit vertex-driven rendering.
- `CompoundShape` and `ShapeCommand`: Recorded vector-shape commands replayed later through render commands.
- `DrawLayer`: Ordered callback container for higher-level draw sequencing.
- `DecalSurface`: Render-owned descriptor for decal workflows.
- `ShaderPassDescriptor`: Lightweight effect-pass description attached to image draws.
