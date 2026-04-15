# IDEA.md — `devtools` module

> No `ideas/features/` file. Assembled from `src/devtools/` and `src/lua_api/devtools_api.rs`.
> Lua namespace: `lurek.devtools`.

---

## Features

### ✅ DONE — Lua Profiler (Push / Pop Named Zones)
**Source**: `devtools_api.rs:225` — `Profiler::push/pop`, `ProfileZone`

`lurek.devtools.profilerEnabled(bool)` — enable/disable.
`lurek.devtools.profilerBegin(name)` / `profilerEnd(name)` — manual zone bracketing.

---

### ✅ DONE — Frame Stats (`FrameStats`)
**Source**: `devtools_api.rs:12` — `FrameStats` import

Per-frame timing and draw call statistics capture.

---

### ✅ DONE — Logger Console Toggle
**Source**: `devtools_api.rs:148` — `setLogConsole` / `getLogConsole`

Enable/disable engine log output mirror to the in-game console.

---

### ✅ DONE — Named Live Watches
**Source**: `devtools_api.rs:36` — `exposeWatch`

`lurek.devtools.exposeWatch(name, getter_fn)` — registers a named live watch
sampled on demand by external inspector tools.

---

### ✅ DONE — File Watcher
**Source**: `devtools_api.rs:12` — `FileWatcher` import

Internal file watcher component (used by the engine for monitoring script changes).
Currently not Lua-exposed as a user-callable API.

---

### ✅ DONE — Expose FileWatcher to Lua
**Source**: General devtools completeness

`FileWatcher` exists in Rust but has no Lua binding. Games could use it for runtime
config file watching, hot-loading item data, etc.

```lua
local watcher = lurek.devtools.newFileWatcher("data/items.toml")
watcher:onChanged(function() reloadItems() end)
```

---

### ✅ DONE — Profiler Report Export
**Source**: General profiling completeness

No `lurek.devtools.profilerReport()` that returns accumulated zone data as a table
for external analysis or CSV export.

---

### ❌ TODO — In-Game Console Widget (REPL)
**Source**: General devtools completeness

`console_open` flag exists in `DevtoolsState` but no REPL input widget is bound.
A REPL panel where developers can evaluate Lua expressions at runtime would be
significantly more useful than the existing log-only console.

---

### ❌ TODO — Entity Inspector Widget
**Source**: General devtools completeness

No `lurek.devtools.openEntityInspector()` for browsing live ECS component hierarchies.
Would plug into the `lurek.ecs` module.
