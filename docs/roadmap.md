# Luna2D Roadmap

## v0.2.0 — Winit/WGPU Runtime & Core Systems

The current release centers on the winit + wgpu runtime, Lua scripting, and the expanded graphics, audio, and physics toolset.

### Completed
- Legacy tiny-skia/minifb CPU renderer retained in the repo as fallback code
- GPU-accelerated rendering via wgpu (primary runtime renderer)
- Lua 5.4 scripting via mlua (vendored)
- Complete `luna.*` API namespace registered through 11 Rust-side API modules
- Love2D-style callbacks (load/update/draw/keypressed/etc.)
- conf.lua configuration system
- AABB physics with gravity
- **Circle physics bodies** (`luna.physics.newCircleBody`)
- **Circle-circle and rect-circle collision detection**
- **Sensor bodies** — trigger volumes with events, no physical resolution
- **Collision layer/mask filtering** — `luna.physics.setBodyLayer(world, body, layer, mask)`
- **Collision events** — `luna.physics.getCollisions(world_id)` → `{body_a, body_b}[]`
- **Body shape introspection** — `luna.physics.getBodyShape(world, body)` → `"rect"|"circle", ...`
- **Body restitution control** — `luna.physics.setBodyRestitution(world, body, value)`
- Audio playback (WAV, MP3, OGG, FLAC via rodio)
- Audio loop, pitch, pause/resume control
- Mouse and keyboard input, plus `luna.gamepad.*` query APIs
- Sandboxed filesystem I/O
- Math utilities (trig, vectors, RNG, lerp, normalize, easing, noise)
- TTF font rendering via fontdue
- Font metrics: `luna.graphics.getFontWidth(id, text)`, `luna.graphics.getFontHeight(id)`
- Bitmap font text rendering (fallback)
- Sprite batching for efficient rendering
- Canvas/render targets (off-screen rendering surfaces)
- Sprite-sheet animation system
- Emitter-based particle system
- Scene management (Lua-side pattern)
- Splash screen when no game loaded
- Comprehensive test suite (147+ tests, including Lua integration tests)
- thiserror-based error handling

---

## Current: v0.4.0 — Advanced Physics & Joints

### Completed
- Physics backend replaced with **rapier2d 0.32** (replaces custom AABB engine)
- Revolute joints (`luna.physics.newJoint`)
- Friction coefficient on bodies (`luna.physics.setBodyFriction`)
- Raycasting (`luna.physics.raycast`)
- Body angle read/write (`luna.physics.getBodyAngle`, `luna.physics.setBodyAngle`)
- Apply instantaneous impulse (`luna.physics.applyImpulse`)
- **Demo game** (`examples/demo_game`) — shooting gallery with raycast aim beam, physics balls, score counter

### Remaining
- Distance and prismatic joints
- Polygon body shapes
- Continuous collision detection (tunneling prevention)

---

## v0.5.0 — GPU Rendering & Effects

### Completed
- **wgpu** backend as primary renderer
- Particle system (`luna.particle.*`)

### Remaining
- Shader support (not implemented; `src/graphics/shader.rs` is currently a placeholder)
- Post-processing effects
- Further performance optimization

---

## v0.6.0 — Input & Platform

### Completed
- Gamepad support (`luna.gamepad.*` API)
- **Gamepad hardware integration via gilrs** — `luna.gamepad.*` now backed by real hardware polling on all platforms

### Remaining
- Touch input for mobile/tablet
- Multi-window support
- Fullscreen and display modes
- Clipboard access
- Drag and drop

---

## v0.7.0 — Ecosystem

### Goals
- Asset hot-reloading (watch filesystem for changes)
- Built-in debug console
- Profiler overlay (`luna.debug.showStats()`)
- Game packaging (single executable with embedded assets)
- Project templates and scaffolding tool

---

## Future Considerations

- **Networking**: UDP/TCP via `luna.net`
- **GUI**: Immediate-mode UI toolkit
- **Tilemap**: Built-in Tiled map loader
- **Animation**: ~~Sprite sheet animation system~~ ✅ Done
- **Scene graph**: ~~Entity management~~ Scene management pattern provided
- **Scripting**: LuaJIT backend option
- **Web export**: WASM target
- **Mobile**: Android/iOS support
