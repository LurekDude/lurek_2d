# tools/mods — Mod Tooling

CLI helpers for Lurek2D mod development.

| Script | Purpose |
|--------|---------|
| `mod_init.py` | Scaffold a new mod folder with `mod.toml`, `main.lua`, and `README.md`. |

## Usage

```powershell
# Create a new mod called "my_rpg_mod" inside game/mods/
python tools/mods/mod_init.py my_rpg_mod --dir game/mods --author "Alice" --capabilities filesystem,network

# All options
python tools/mods/mod_init.py --help
```

Generated layout:
```
mods/my_rpg_mod/
├── mod.toml    ← metadata (id, name, version, api_version, capabilities)
├── main.lua    ← entry point loaded by Lurek2D
└── README.md   ← usage stub
```

See `docs/specs/mods.md` for the full `lurek.modding.*` API reference.
