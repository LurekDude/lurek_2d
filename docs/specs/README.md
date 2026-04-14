# docs/specs/ — Lurek2D Module References

This folder contains the canonical merged module reference for every `src/<module>/` directory in the Lurek2D engine.

Each file is named `<module>.md` and mirrors the module folder name. These files now hold the former AGENT overview content and the deeper technical material in a single place.

## Sync Contract

Whenever you:
- Add or remove a `.rs` file in `src/<module>/`
- Add, rename, or remove a public `struct` / `enum` / `fn`
- Add, rename, or remove a `lurek.*` Lua binding
- Change module dependencies

You **must** update **all** of the following in the same commit:

| File | What to update |
|------|----------------|
| `docs/specs/<module>.md` | General Info, Summary, Files, Types, Functions, Lua API Reference, References, Notes |
| `src/lua_api/<module>_api.rs` | Binding annotations (`@param`, `@return`) |
| `docs/API/lua_api_reference_generated.md` | Run `tools/gen_lua_api.py` |
| `content/demos/` and `content/examples/` | Update affected demo/example scripts |
| `content/library/` | Update Lunasome modules that depend on the changed API |

## Generation Workflow

- `python tools/docs/gen_module_specs.py` rebuilds the auto-collected sections from source.
- Summary paragraphs and Notes are manual prose and should be revised module by module.
- `python tools/audit/validate_agent_md.py --module <name>` validates the merged spec format. The script name is kept for compatibility even though `src/<module>/AGENT.md` files have been retired.

## Modules
- [ai](ai.md)
- [animation](animation.md)
- [app](app.md)
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
- [ecs](ecs.md)
- [effect](effect.md)
- [event](event.md)
- [filesystem](filesystem.md)
- [graph](graph.md)
- [i18n](i18n.md)
- [image](image.md)
- [input](input.md)
- [light](light.md)
- [log](log.md)
- [lua_api](lua_api.md)
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
- [sprite](sprite.md)
- [terminal](terminal.md)
- [thread](thread.md)
- [tilemap](tilemap.md)
- [timer](timer.md)
- [tween](tween.md)
- [ui](ui.md)
- [window](window.md)
