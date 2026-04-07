# Luna2D

**A ~20 MB 2D game engine.** Written in Rust. Scripted in Lua. GPU-rendered via wgpu. AI-first.

Luna2D is the engine for people who think game engines have become too complicated. One binary, one scripting language, one afternoon to learn. Drop `luna2d` next to `main.lua` — your game runs.

---

## The Pitch

The game engine market is dominated by multi-gigabyte toolchains with visual editors, plugin marketplaces, and months-long learning curves. Luna2D is the opposite:

- **~20 MB** single binary — no installer, no DLLs, no runtime dependencies
- **Lua scripting** — write `luna.load()`, `luna.update(dt)`, `luna.draw()`, your game runs
- **Rust performance** — GPU rendering, physics, audio, and threading owned by the engine
- **AI-augmented** — every API is designed so a Copilot agent can use it correctly on the first try

This is David vs. Goliath: a 20 MB engine that, powered by AI, delivers features rivalling engines 100× its size.

---

## Quick Start

```bash
# Build and run
cargo build                           # Debug build
cargo run                             # Splash screen (no game)
cargo run -- demos/hello_world     # Run an example
cargo run -- demos/physics_demo    # Physics demo
cargo build --release                 # Release build (~20 MB)
```

With no game directory, the engine displays a built-in splash screen. **Drag and drop** a game folder onto the window to load it instantly.

### Your First Game

Create a folder with a `main.lua`:

```lua
function luna.init()
    luna.gfx.setBackgroundColor(0.1, 0.1, 0.2)
end

function luna.render()
    luna.gfx.print("Hello, Luna2D!", 100, 100)
end
```

Run it:

```bash
cargo run -- path/to/your/game
```

That's it. No project files, no build steps, no configuration. An empty `main.lua` is valid — it produces a black window with no errors.

---

## Features

### Engine Subsystems

| Category | Capabilities |
|---|---|
| **Graphics** | GPU rendering (wgpu: Vulkan/DX12/Metal), sprites, sprite batches, meshes, canvases, custom WGSL shaders, blend modes, stencils, transform stack, camera system |
| **Audio** | Sound loading and playback (WAV, OGG, MP3, FLAC), streaming, volume/pitch/panning, audio buses |
| **Input** | Keyboard, mouse, gamepad (gilrs), touch — state queries and event callbacks |
| **Physics** | Rigid bodies, shapes, joints (11 types), raycasting, collision events (rapier2d) |
| **Particles** | Configurable emitter system with ~35 parameters, keyframed size/color |
| **Tilemaps** | Tile layers, tilesets, procedural map generation, coordinate helpers |
| **AI** | FSMs, behaviour trees, GOAP planning, steering behaviours |
| **Pathfinding** | Navigation grids, A★, HPA★, flow fields |
| **Scenes** | Scene stack management with transitions |
| **Data** | Binary data buffers, compression (deflate/gzip/lz4/zlib), hashing (MD5/SHA), encoding (base64/hex) |
| **Threading** | Background Rust workers, typed MPMC channels, per-thread Lua VMs |
| **Filesystem** | Sandboxed game I/O, virtual FS with archive mounting, mod support |
| **Math** | Vec2/Vec3/Mat3, noise (Perlin/simplex/fBm), easing (22 functions), Bezier curves, triangulation |
| **ECS** | Lightweight entity primitives with bitmap tags and blueprints |
| **Terminal** | In-game developer console/REPL with widget toolkit |

### Lua API

All bindings live under `luna.*` — a single, consistent namespace:

```
luna.gfx    luna.audio      luna.keyboard    luna.mouse
luna.gamepad     luna.touch      luna.time       luna.math
luna.physics     luna.fs luna.window      luna.signal
luna.platform      luna.particles   luna.data        luna.img
luna.sound       luna.thread     luna.terminal
```

Every callback is optional. Every function has sensible defaults. Every type has clear documentation.

### Callbacks

```lua
luna.load()                              -- once at startup
luna.update(dt)                          -- every frame
luna.draw()                              -- every frame
luna.keypressed(key, scancode, isrepeat) -- key down
luna.mousepressed(x, y, button)          -- mouse down
luna.gamepadpressed(id, button)          -- gamepad button
-- ... 22 total callbacks
```

---

## Architecture

Luna2D uses a layered module architecture:

```
Lua game scripts
    ▼
library/  (Tier 3: Lunasome — pure Lua standard library)
    ▼
lua_api/  (bridge: registers luna.* namespace)
    ▼
Tier 2 extensions (particle, tilemap, scene, ai, pathfinding, ...)
    ▼
Tier 1 core (graphics, audio, physics, input, timer, ...)
    ▼
Baseline: math (leaf) + engine (lifecycle, SharedState)
```

**Layer rules**: Tier 1 depends only on Baseline. Tier 2 depends on Baseline + Tier 1. No circular dependencies. No cross-tier imports within the same level.

### Documentation

| Document | Contents |
|---|---|
| [Engine Architecture](docs/architecture/engine-architecture.md) | Runtime modules, rendering pipeline, boot sequence, state management |
| [Test Framework](docs/architecture/test-framework.md) | Test suite structure, BDD framework, naming conventions, quality gates |
| [Philosophy & Design Assumptions](docs/architecture/philosophy.md) | The Zen of Luna, binding constraints, decision heuristics |
| [Lua API Reference](docs/lua_api_reference_generated.md) | Complete `luna.*` API for game developers |
| [Rust API Reference](docs/api_generated.md) | Engine internals for contributors |

---

## Tech Stack

| Component | Technology | Purpose |
|---|---|---|
| Language | Rust stable ≥1.78 | Engine core |
| Scripting | LuaJIT (mlua 0.9) | Game logic |
| Rendering | wgpu 22 | GPU (Vulkan/DX12/Metal) |
| Windowing | winit 0.30 | Cross-platform windows + input |
| Physics | rapier2d 0.32 | 2D rigid-body simulation |
| Audio | rodio 0.17 | Sound playback |
| Fonts | fontdue 0.9 | TTF/OTF rasterization |
| Gamepad | gilrs 0.11 | Controller support |

---

## Examples

27 example games and demos ship in `demos/`:

| Example | Demonstrates |
|---|---|
| `hello_world` | Minimal game — text rendering |
| `physics_demo` | Rigid bodies, shapes, collisions |
| `sprites` | Image loading, sprite drawing |
| `platformer` | Side-scrolling movement and collision |
| `particles_demo` | Particle system configuration |
| `scene_demo` | Scene stack and transitions |
| `dialog_demo` | Dialogue system and branching |
| `tilemap` | Tile-based map rendering |
| `terminal_demo` | In-game developer console |
| `tween_demo` | Easing and animation |
| `light_demo` | Dynamic lighting effects |
| `postfx_demo` | Post-processing effects |
| ... | See `demos/` for all demos |

Run any example:

```bash
cargo run -- demos/hello_world
```

---

## Development

### Build Commands

```bash
cargo check                            # Type-check only (~2-5s incremental)
cargo test --test math_tests           # Test one module
cargo test lua_test_math               # Test one Lua module
cargo clippy --lib                     # Lint library only
```

### Quality Gates (before every commit)

```bash
cargo test && cargo clippy -- -D warnings
cargo fmt --check
```

### Regenerate Assets

```bash
python tools/gen_splash.py             # Regenerate splash.png
python tools/gen_icon.py               # Regenerate icon.ico + icon.png
python tools/gen_branding.py           # Regenerate all SVG branding
```

---

## VS Code Extension

The first-party VS Code extension lives in [`vscode-extension/`](vscode-extension/README.md). It provides:

- API documentation and IntelliSense for `luna.*`
- Example-running workflows
- AI-oriented tooling (CAG layer, MCP server)

The extension is a companion tool, not part of the engine runtime.

---

## Project Identity

Luna2D's visual identity tells a story:

- **🌙 Moon** — Lua means "moon" in Portuguese. The crescent represents the scripting layer.
- **⚙️ Gear** — The Rust engine core. Industrial-strength, memory-safe.
- **🟡 Pacman** — The gear is shaped like Pacman — the engine that *eats* game scripts and runs them.
- **🧊 Cube** — The industry giants (Unity, Unreal, Godot) orbit Luna2D, not the reverse.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security

See [SECURITY.md](SECURITY.md) for reporting instructions.

## License

MIT — see [LICENSE](LICENSE).

