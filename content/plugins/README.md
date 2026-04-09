# Lurek2D Plugins

This folder contains pure-Lua plugins — self-contained modules that extend game
functionality without modifying or recompiling the engine.

## Difference from `library/`

| Folder | Purpose | Audience |
|---|---|---|
| `library/` | Lunasome Tier-3 standard library — curated, shipped with engine | Engine shipping set |
| `plugins/` | Third-party or experimental Lua plugins — drop-in, no engine changes | Community |

## Plugin Layout

Each plugin lives in its own subdirectory:

```
content/plugins/<name>/
    init.lua         ← main entry point, loaded with require("plugins.<name>")
    README.md        ← description, usage, API
```

## Using a Plugin

```lua
local my_plugin = require("plugins.my_plugin")
```

Ensure `content/plugins/` is on your `package.path` or placed next to your game folder.
