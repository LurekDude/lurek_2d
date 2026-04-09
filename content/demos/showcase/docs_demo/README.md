# Docs Demo

Demonstrates `lurek.docs`: the self-documenting API introspection module. Scan the `luna` namespace at runtime, list modules, query function signatures, and display available APIs in-game.

## What It Demonstrates

- `lurek.docs.scan()` — build a catalog of the entire `lurek.*` namespace
- `catalog:getModules()` — list all registered API modules
- `catalog:getFunctions(module)` — list all functions in a module
- `catalog:getSignature(module, fn)` — retrieve a function's signature string
- `catalog:search(query)` — fuzzy-search across all function names and descriptions
- Rendering scrollable lists of API entries using `lurek.gfx.print()`

## How to Run

```powershell
cargo run -- content/demos/docs_demo
```

## Controls

| Key | Action |
|-----|--------|
| Up / Down | Scroll API list |
| Tab | Cycle modules |
| / | Search mode |

## Notes

- Useful as an in-game API browser during development
- All data comes from registered `///` doc comments on Lua binding code
