# IDEA.md — `mods` module

> Migrated from `ideas/features/modding.md` and `ideas/performance/24-savegame-modding-io.md` (modding section).
> Status checked against `src/mods/` and `src/lua_api/mods_api.rs`.
> Lua namespace: `lurek.modding`.

---

## Features

### ✅ DONE — Mod API Version Gating
**Source**: features/modding.md — Feature Gaps #2 / Suggestions #1

`ModInfo.api_version: Option<String>` added to `src/mods/mod_manager.rs`. Exposed via
`mod:getApiVersion()` / `mod:setApiVersion()` and the helper `lurek.modding.checkApiVersion(mod, host_version) -> (bool, msg?)` in `src/lua_api/mods_api.rs`.

---

### ✅ DONE — Mod Capabilities / Permissions
**Source**: features/modding.md — Feature Gaps #3 / Suggestions #2

`ModInfo.capabilities: Vec<String>` added. Exposed via `mod:getCapabilities()` / `mod:setCapabilities()` in `src/lua_api/mods_api.rs`. Propagated through `mod_info_from_table` / `mod_info_to_table`.

---

### ✅ DONE — Mod Config Schema (Auto-generated UI)
**Source**: features/modding.md — Feature Gaps #5 / Suggestions #3

`ModInfo.config_schema: Vec<(String, String, String)>` added (key, type_hint, default triple).
Exposed via `mod:getConfigSchema()` / `mod:setConfigSchema()` in `src/lua_api/mods_api.rs`.

---

### ❌ DEFERRED — Track Active Mods in Save Files
**Source**: features/modding.md — Structural Issues / Suggestions #4

Needs cross-module coordination with `save`. Deferred until the save schema extension
landscape is clearer. Tracked in save module IDEA.md.

---

### ❌ DEFERRED — Mod Hot Reload
**Source**: features/modding.md — Feature Gaps #6 / Suggestions #5

Requires filesystem watcher integration. Deferred until `src/filesystem/` watcher lands.

---

### ✅ DONE — `luna mod init` CLI Scaffolding
**Source**: features/modding.md — Feature Gaps #7 / Suggestions #6

Implemented as `tools/mods/mod_init.py`. Generates `mod.toml`, `main.lua`, and `README.md`.
Run: `python tools/mods/mod_init.py <mod_name> [--dir mods/] [--author ...] [--capabilities ...]`
