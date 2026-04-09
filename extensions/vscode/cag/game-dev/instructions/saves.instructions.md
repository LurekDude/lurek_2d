---
applyTo: "**/saves/*.lua"
---
# Save System Rules
- All save data serializes to TOML via luna.data.encodeToml()
- ALWAYS include a `save_version` integer field
- ALWAYS validate save_version on load, migrate if needed
- NEVER store raw Lua function references in save data
- Save paths use luna.fs.getSaveDirectory()
- Validate save data before applying (nil-check every expected field)
