# docs/specs/ — Lurek2D Module Specifications

This folder contains the **full technical specification** for every `src/<module>/` module in the Lurek2D engine.

Each file is named `<module>.md` and mirrors the module folder name. They are the canonical reference for architecture, public types, Lua API surface, examples, and cross-module relationships.

## Sync Contract

Whenever you:
- Add or remove a `.rs` file in `src/<module>/`
- Add, rename, or remove a public `struct` / `enum` / `fn`
- Add, rename, or remove a `lurek.*` Lua binding
- Change module dependencies

You **must** update **all** of the following in the same commit:

| File | What to update |
|------|----------------|
| `docs/specs/<module>.md` | Full detail: architecture, types, Lua API, examples |
| `src/<module>/AGENT.md` | Summary, source file table |
| `src/lua_api/<module>_api.rs` | Binding annotations (`@param`, `@return`) |
| `docs/API/lua_api_reference_generated.md` | Run `tools/gen_lua_api.py` |
| `content/demos/` and `content/examples/` | Update affected demo/example scripts |
| `content/library/` | Update Lunasome modules that depend on the changed API |

## Modules

- [ai](ai.md)
- [animation](animation.md)
- [app](app.md)
- [audio](audio.md)
- [automation](automation.md)
- [bin](bin.md)
- [camera](camera.md) *(submodule of `src/render/camera/`)*
- [compute](compute.md)
- [data](data.md)
- [dataframe](dataframe.md)
- [debugbridge](debugbridge.md)
- [devtools](devtools.md)
- [docs](docs.md)
- [ecs](ecs.md)
- [effect](effect.md) *(submodule of `src/render/effect/`)*
- [event](event.md)
- [filesystem](filesystem.md)
- [graph](graph.md)
- [i18n](i18n.md)
- [image](image.md)
- [input](input.md)
- [light](light.md) *(submodule of `src/render/light/`)*
- [log](log.md)
- [math](math.md)
- [minimap](minimap.md)
- [mods](mods.md)
- [network](network.md)
- [parallax](parallax.md)
- [particle](particle.md)
- [pathfind](pathfind.md)
- [patterns](patterns.md)
- [physics](physics.md)
- [pipeline](pipeline.md)
- [procgen](procgen.md)
- [raycaster](raycaster.md)
- [render](render.md)
- [runtime](runtime.md)
- [save](save.md)
- [scene](scene.md)
- [serial](serial.md)
- [spine](spine.md)
- [terminal](terminal.md)
- [thread](thread.md)
- [tilemap](tilemap.md)
- [timer](timer.md)
- [tween](tween.md)
- [ui](ui.md)
- [window](window.md)
