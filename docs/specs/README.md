# specs/ — Luna2D Module Specifications

This folder contains the **full technical specification** for every `src/<module>/` module in the Luna2D engine.

Each file is named `<module>.md` and mirrors the module folder name. They are the canonical reference for architecture, public types, Lua API surface, examples, and cross-module relationships.

## Sync Contract

Whenever you:
- Add or remove a `.rs` file in `src/<module>/`
- Add, rename, or remove a public `struct` / `enum` / `fn`
- Add, rename, or remove a `luna.*` Lua binding
- Change module dependencies

You **must** update **all** of the following in the same commit:

| File | What to update |
|------|----------------|
| `specs/<module>.md` | Full detail: architecture, types, Lua API, examples |
| `src/<module>/AGENT.md` | Summary, source file table |
| `src/lua_api/<module>_api.rs` | Binding annotations (`@param`, `@return`) |
| `docs/API/lua_api_reference_generated.md` | Run `tools/gen_lua_api.py` |
| `demos/` and `examples/` | Update affected demo/example scripts |
| `library/` | Update Lunasome modules that depend on the changed API |

## Modules

- [ai](ai.md)
- [animation](animation.md)
- [audio](audio.md)
- [automation](automation.md)
- [bin](bin.md)
- [camera](camera.md)
- [compute](compute.md)
- [data](data.md)
- [dataframe](dataframe.md)
- [debugbridge](debugbridge.md)
- [devtools](devtools.md)
- [docs](docs.md)
- [engine](engine.md)
- [entity](entity.md)
- [event](event.md)
- [filesystem](filesystem.md)
- [fx](fx.md)
- [graph](graph.md)
- [graphics](graphics.md)
- [gui](gui.md)
- [image](image.md)
- [input](input.md)
- [light](light.md)
- [localization](localization.md)
- [log](log.md)
- [lua_api](lua_api.md)
- [math](math.md)
- [minimap](minimap.md)
- [modding](modding.md)
- [network](network.md)
- [particle](particle.md)
- [pathfinding](pathfinding.md)
- [patterns](patterns.md)
- [physics](physics.md)
- [pipeline](pipeline.md)
- [procgen](procgen.md)
- [raycaster](raycaster.md)
- [savegame](savegame.md)
- [scene](scene.md)
- [serial](serial.md)
- [spine](spine.md)
- [terminal](terminal.md)
- [thread](thread.md)
- [tilemap](tilemap.md)
- [timer](timer.md)
- [window](window.md)

