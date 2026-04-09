# Luna2D API Examples

Each file in this folder is a **Lua API reference** for one engine module.
These files document every public `luna.*` function with realistic usage patterns.
They are not runnable games � they are meant to be read, searched, and copy-pasted from.

## How to use

- Browse a file to discover what a module can do.
- Copy snippets into your own `main.lua`.
- Use your editor's search to locate a specific function name.

## Module Reference Index

| File | API | Description |
|------|-----|-------------|
| [core-engine/main.lua](core-engine/main.lua) | All core callbacks | **Runnable tour**: every callback (`init`, `ready`, `process`, `process_physics`, `process_late`, `render`, `render_ui`), Lua OOP table methods, for-loops, and physics running at its own fixed timestep |
|------|-----|-------------|
| [ai.lua](ai.lua) | `luna.ai` | Finite-state machines, behaviour trees, GOAP planners, and steering behaviours |
| [animation.lua](animation.lua) | `luna.animation` | Sprite animation clips, frame pools, playback control, and frame-level events |
| [audio.lua](audio.lua) | `luna.audio` | Sound sources, streaming music, volume/pitch/pan, buses, and audio effects |
| [automation.lua](automation.lua) | `luna.automation` | Replaying and recording input sequences for automated testing or cutscenes |
| [camera.lua](camera.lua) | `luna.camera` | 2D cameras with pan, zoom, rotation, viewport scaling, and screen-to-world transforms |
| [compute.lua](compute.lua) | `luna.compute` | Dense numerical arrays (NdArray) and CPU-side numerical processing |
| [data.lua](data.lua) | `luna.data` | ByteData buffers, compression (deflate/gzip/lz4/zlib), hashing (MD5/SHA), and base64/hex encoding |
| [dataframe.lua](dataframe.lua) | `luna.dataframe` | Column-major tabular data, filtering, sorting, joins, aggregation, and an SQL-capable Database |
| [entity.lua](entity.lua) | `luna.entity` | Lightweight entity component helpers and entity management |
| [event.lua](event.lua) | `luna.signal` | Custom event queue, push/poll/clear, and engine lifecycle events |
| [filesystem.lua](filesystem.lua) | `luna.fs` | Sandboxed game filesystem, virtual mount points, ZIP archives, and FileHandle I/O |
| [fx.lua](fx.lua) | `luna.postfx` | Post-processing effects: blur, bloom, color grading, and custom effect chains |
| [graph.lua](graph.lua) | `luna.graph` | Directed graphs, edge/node operations, flow simulation, and graph algorithms |
| [graphics.lua](graphics.lua) | `luna.gfx` | 2D drawing, images, fonts, canvases, meshes, sprite batches, shaders, transforms, and stencils |
| [gui.lua](gui.lua) | `luna.ui` | Retained-mode widget UI: buttons, sliders, text inputs, panels, layouts, and theming |
| [image.lua](image.lua) | `luna.img` | CPU-side pixel buffers, per-pixel manipulation, and PNG/BMP encoding |
| [input.lua](input.lua) | `luna.input` | Keyboard, mouse, gamepad, and touch state queries |
| [light.lua](light.lua) | `luna.light` | Dynamic 2D lighting, light sources, shadow casting, and ambient light control |
| [math.lua](math.lua) | `luna.math` | Trigonometry, random numbers, noise (Perlin/simplex), easing, vectors, matrices, and Bezier curves |
| [minimap.lua](minimap.lua) | `luna.minimap` | Minimap rendering with fog-of-war, entity markers, terrain colours, and FOV masking |
| [modding.lua](modding.lua) | `luna.modding` | Mod discovery, dependency resolution, version constraints, load ordering, and config overrides |
| [network.lua](network.lua) | `luna.network` | UDP networking via ENet: hosts, peers, channels, reliable/unreliable send, and event polling |
| [particle.lua](particle.lua) | `luna.particles` | Emitter-based 2D particle systems with 35+ configurable fields |
| [pathfinding.lua](pathfinding.lua) | `luna.pathfinding` | Navigation grids, A* pathfinding, HPA*, flow fields, and waypoint graphs |
| [physics.lua](physics.lua) | `luna.physics` | rapier2d 2D rigid-body physics: worlds, bodies, shapes, joints, raycasting, and collision events |
| [pipeline.lua](pipeline.lua) | `luna.pipeline` | Data processing pipelines: transform chains, composable stages, and batch operations |
| [procgen.lua](procgen.lua) | `luna.procgen` | Procedural generation: dungeon layouts, terrain noise, L-systems, and cellular automata |
| [raycaster.lua](raycaster.lua) | `luna.raycaster` | Pseudo-3D raycasting renderer (Wolf3D-style) using 2D top-down maps |
| [savegame.lua](savegame.lua) | `luna.savegame` | Save/load orchestration, slot management, schema versioning, and serialisation helpers |
| [scene.lua](scene.lua) | `luna.scene` | Scene stack with push/pop/replace, per-scene update/draw/input, and transition effects |
| [serial.lua](serial.lua) | `luna.codec` | Serialisation: TOML, JSON, binary, and custom encode/decode pipelines |
| [spine.lua](spine.lua) | `luna.spine` | Spine 2D skeletal animation playback and attachment management |
| [terminal.lua](terminal.lua) | `luna.terminal` | In-game character-cell terminal emulator with widgets, REPL, and developer tools |
| [thread.lua](thread.lua) | `luna.thread` | Background Lua worker threads, typed MPMC channels, and thread-safe communication |
| [tilemap.lua](tilemap.lua) | `luna.tilemap` | Tilemaps, tilesets, autotiling, map generation, and coordinate helpers |
| [timer.lua](timer.lua) | `luna.time` | Frame timing, delta time, FPS tracking, and scheduled callbacks |
| [window.lua](window.lua) | `luna.window` | Window title, size, fullscreen, VSync, DPI scaling, clipboard, and display info |
| [log.lua](log.lua) | `luna.log` | Structured log level control and severity-filtered message output |
| [devtools.lua](devtools.lua) | `luna.devtools` | In-game logger, CPU profiler, frame-time stats, and hot-reload file watcher |
| [debugbridge.lua](debugbridge.lua) | `luna.debugbridge` | TCP remote debug server for VS Code and external tooling |
| [docs.lua](docs.lua) | `luna.docs` | API catalog scanning, validation, quality metrics, and docstring annotation |
| [patterns.lua](patterns.lua) | `luna.patterns` | EventBus, ObjectPool, CommandStack, ServiceLocator, Factory, and SimpleState |
| [localization.lua](localization.lua) | `luna.localization` | Multi-locale string catalog, variable interpolation, plural forms, and fallback chains |

## Notes

- All indices are **1-based** (Lua convention).
- All angles are in **radians**.
- All colour channels are **float 0.0�1.0**.
- Functions shown as `func(x, y?, z?)` have optional parameters marked `?`.
- `�` separates parameters from return values in comments.
