# IDEA — src/runtime

## Niezrobione TODO/WIP

- DONE(FEAT): `evict_lru_resources` now uses `resource_memory_stats().total_bytes` (textures + fonts + canvases + shaders) as the budget check instead of texture-only byte sum; `canvas_last_used` tracking added via `touch_canvas()`.
- DONE(FEAT): hot-reload of mutable `conf.toml` fields now triggerable via `lurek.runtime.reloadConfig()`; sets `pending_config_reload` flag consumed by the app loop; `FileWatcher::force_changed()` added.
- DONE(PERF): `evict_lru_resources` uses `Vec::with_capacity` + `sort_unstable_by_key` to eliminate repeated realloc and extra comparisons.
- DONE(QUAL): physics-related fields extracted from `SharedState` into `PhysicsRunConfig` sub-struct (`fixed_dt`, `max_steps`, `debug_draw`, `fixed_update_dt`).
- DONE(REL): `messages::get_message` `unsafe` lifetime extension removed; `MessageCatalog` now stores `&'static str` via `Box::leak` in `collect_strings`; no `unsafe` blocks remain in `messages.rs`.
- DONE(dedup): `Clock` confirmed as single source of truth in `src/timer/clock.rs`; no duplicate in `runtime`.
- DONE(dedup): `EventQueue` confirmed as single source of truth in `src/event/event_queue.rs`; no duplicate in `runtime`.
- DONE(helper): `lurek.runtime.getConfig()` returns active runtime-mutable config snapshot (physics tick rate, fixed update tick rate, frame budget warn ms, vsync, log level, config reload revision); `lurek.runtime.reloadConfig()` triggers hot-reload.
