# `patterns` — Deprecation Stub (Lunasome)

| Property        | Value                                              |
| --------------- | -------------------------------------------------- |
| **Tier**        | Tier 3 — Lunasome (pure Lua, no Rust dependencies) |
| **Source**      | `library/patterns/init.lua` (4-line proxy)         |
| **Status**      | Proxy / Deprecated since 0.6.0                     |
| **Replacement** | `library/scheduler/`                               |

## Summary

This folder is a **deprecation stub**. The library that previously lived here
— a pure-Lua coroutine scheduler — was renamed to `library.scheduler` in 0.6.0
because the old name collided with the unrelated `lurek.patterns` Rust
namespace (`EventBus`, `ObjectPool`, `CommandStack`, `SimpleState`, …).

The remaining `init.lua` is a 4-line proxy that:

1. Emits a one-shot deprecation warning via `lurek.log.warn` (or `print` in
   headless contexts).
2. Returns `require("library.scheduler")` so existing scripts keep working
   without code changes.

## Migration

Replace:

```lua
local patterns = require("library.patterns")
```

with:

```lua
local scheduler = require("library.scheduler")
```

The public API is identical — `M.newScheduler(opts)` and the returned
`Scheduler:add/remove/pause/resume/getStatus/update/getCount/getErrors/clearErrors/clear`
methods are unchanged.

## Test Notes

The legacy test file `tests/lua/library/test_library_patterns.lua` continues
to exercise this stub (and therefore the underlying `library.scheduler`) and
will be renamed in P9.

## Removal Plan

This stub will be deleted in 0.7.0 once all in-tree consumers have migrated.
