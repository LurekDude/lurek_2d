The overlay shows per-frame draw call count — the primary signal for render performance.

---

### Lurek2D-Specific Hot Paths
| Hot Path | Location | Bottleneck |
|----------|----------|------------|
| RenderCommand processing | `src/render/gpu_renderer.rs` | Draw call count, state changes |
| Sprite batch flush | `src/render/sprite_batch.rs` | Vertex buffer upload size |
| Physics world step | `src/physics/world.rs` | Body + collider count |
| Lua `lurek.update()` | `src/app/app.rs` | Lua computation + GC |
| Particle system update | `src/particle/mod.rs` | Active particle count |
| Font glyph rasterization | `src/render/font.rs` | First-time cache miss only |
| Texture decompression | `src/render/texture.rs` | Load time, not per-frame |

---

### Draw Call Reduction
Draw call count is the primary render budget variable on integrated GPUs.

**Target: ≤ 200 draw calls per frame.**

### SpriteBatch (most important)

> See [examples/spritebatch-most-important.lua](examples/spritebatch-most-important.lua) for the example.

### Texture atlas

Pack small sprites into a single large texture. Use `lurek.render.newQuad()` to define sub-regions. This keeps SpriteBatch at exactly 1 draw call regardless of sprite count.

---

### Lua GC Pressure Reduction
The LuaJIT GC runs incrementally. Excessive allocation causes visible micro-stalls.

**Detect GC pressure:**

> See [examples/lua-gc-pressure-reduction.lua](examples/lua-gc-pressure-reduction.lua) for the example.

**Patterns:**

> See [examples/lua-gc-pressure-reduction-2.lua](examples/lua-gc-pressure-reduction-2.lua) for the example.

---

### Physics Performance
- `world:step()` cost scales with **body count × collider complexity**
- **50+ dynamic bodies**: enable broadphase stats to confirm bottleneck
- Circle colliders are 3-5× faster than polygon colliders in narrow phase
- Use **sensors** (no collision response) for trigger zones — negligible cost
- Disable sleeping: `body:setSleepingAllowed(false)` increases cost; leave default (true)
- Destroy unused bodies immediately: `world:destroyBody(body)` — stale bodies still cost broadphase time
