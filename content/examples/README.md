# API Examples — `content/examples/`

Each file in this directory demonstrates one `lurek.*` API namespace in
isolation.  Scripts are self-contained and can be run directly:

```bash
cargo run -- content/examples/<name>.lua
```

## Index

| File | Namespace | Description |
|------|-----------|-------------|
| `ai.lua` | `lurek.ai` | Behaviour trees, FSM, GOAP, steering |
| `animation.lua` | `lurek.animation` | Frame sequences, grids, playback control |
| `audio.lua` | `lurek.audio` | Sources, mixer, spatial audio |
| `automation.lua` | `lurek.automation` | Macro recording and playback |
| `camera.lua` | `lurek.camera` | Viewport pan, zoom, shake |
| `compute.lua` | `lurek.compute` | GPU-side compute passes |
| `data.lua` | `lurek.data` | Typed arrays, buffers |
| `dataframe.lua` | `lurek.dataframe` | Tabular in-memory data |
| `debugbridge.lua` | `lurek.debugbridge` | Live debug variable bridge |
| `devtools.lua` | `lurek.devtools` | In-game console, overlay |
| `docs.lua` | `lurek.docs` | Runtime docstring queries |
| `ecs.lua` | `lurek.ecs` | Entity-Component-System |
| `effect.lua` | `lurek.effect` | Post-process effect pipeline |
| `event.lua` | `lurek.event` | Custom event bus |
| `fileapp.lua` | `lurek.filesystem` | Sandboxed file I/O |
| `globe.lua` | `lurek.globe` | XCOM-style province globe — all 53 API calls |
| `graph.lua` | `lurek.graph` | Directed/undirected graph |
| `i18n.lua` | `lurek.i18n` | Localisation strings |
| `image.lua` | `lurek.image` | Pixel data creation and manipulation |
| `province_sanitize.lua` | `lurek.province` | Marker sanitization + province-count comparison demo |
| `input.lua` | `lurek.input` | Keyboard, mouse, gamepad, actions |
| `light.lua` | `lurek.light` | 2D point lights |
| `log.lua` | `lurek.log` | Structured log output |
| `math.lua` | `lurek.math` | Vectors, noise, RNG |
| `minimap.lua` | `lurek.minimap` | Minimap renderer |
| `mods.lua` | `lurek.mods` | Mod loading and sandboxing |
| `network.lua` | `lurek.network` | TCP/UDP sockets |
| `parallax.lua` | `lurek.parallax` | Multi-layer parallax scrolling |
| `particle.lua` | `lurek.particle` | Particle system |
| `pathfind.lua` | `lurek.pathfind` | A\*, Dijkstra, navmesh |
| `patterns.lua` | `lurek.patterns` | Tileable pattern generation |
| `physics.lua` | `lurek.physics` | Rigid bodies, joints |
| `physics_physics.lua` | `lurek.physics` | Collision events and filtering |
| `pipeline.lua` | `lurek.pipeline` | Render pipeline composition |
| `procgen.lua` | `lurek.procgen` | Procedural map generation |
| `raycaster.lua` | `lurek.raycaster` | Textured-quad 2.5D raycasting |
| `render.lua` | `lurek.render` | Shapes, sprites, canvas, blend modes |
| `runtimer.lua` | `lurek.runtime` | Engine lifecycle, config |
| `runtime_window.lua` | `lurek.runtime` | Platform queries |
| `save.lua` | `lurek.save` | Save/load game state |
| `scene.lua` | `lurek.scene` | Scene graph, transitions |
| `serial.lua` | `lurek.serial` | Serialisation (TOML/JSON/binary) |
| `spine.lua` | `lurek.spine` | Spine skeletal animation |
| `sprite.lua` | `lurek.sprite` | Sprite batch |
| `terminal.lua` | `lurek.terminal` | In-game terminal widget |
| `thread.lua` | `lurek.thread` | Worker threads, channels |
| `tilemap.lua` | `lurek.tilemap` | Tile layers, auto-tile |
| `timer.lua` | `lurek.timer` | One-shot and repeating timers |
| `tween.lua` | `lurek.tween` | Easing and animation tweens |
| `ui.lua` | `lurek.ui` | Immediate-mode UI widgets |
| `window.lua` | `lurek.window` | Window title, size, fullscreen |
