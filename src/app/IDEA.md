# IDEA — `src/app/`

> **This file is forward-looking.** It records ideas, not commitments. Nothing here is
> implemented in the same session that produces it. Implementation is gated by a separate
> roadmap decision.
>
> See [IDEA_AUTHORING.md](../../work/src-module-review-20260418/reports/IDEA_AUTHORING.md) for filling instructions.

---

## 1. Header

- **Module**: `app`
- **Owner module path**: `src/app/`
- **Last reviewed**: 2026-04-18 (UTC)
- **Reviewer agent**: `developer` · Session: `src-module-review-20260418`
- **Plugin tier candidacy**: `CORE-KEEP`
- **LOC (rust only)**: ~4280 · **Public Lua surface**: none direct — 0 fn / 0 userdata
- **Inbound non-`lua_api` callers**: `src/main.rs`, `src/bin/lurekc.rs` (binary entry points only)
- **Heavy dependencies**: `winit` 0.30, `wgpu` 22, `gilrs`, `pollster`, `tempfile`, `mlua`

## 2. Mission Summary

The `app` module is the engine's lifecycle orchestrator and sits at the Edge/Integration tier. It owns the winit event loop, the wgpu surface and device, the Lua VM instance, and the main frame-pacing loop. `App::run()` is the single public entry point — everything else is internal wiring. It serves **EngDev** (build the engine), **GameDev** (launch their game), and **Player** (stable runtime). It is NOT a Lua API surface and must NOT contain domain logic — only orchestration.

## 3. Existing Strengths

- **Clean event-loop structure**: `ApplicationHandler` trait impl with well-separated `resumed`, `window_event`, `about_to_wait` handlers.
- **Robust error recovery**: `RunState` state machine (Running → Error → Restarting) with `ErrorScreen` that supports Lua error extraction, traceback formatting, clipboard copy (Ctrl+C), and restart (R key).
- **Flexible vsync and present-mode negotiation**: `resolve_present_mode()` cascades through Mailbox → Immediate → Fifo → Auto*, handling GPU capability variance gracefully.
- **Drag-and-drop game loading**: Drop a folder or `.lurek`/`.luna` archive onto the splash screen to load it — polished end-user discovery workflow.
- **Auto-screenshot mode**: `--screenshot` CLI flag renders N frames then saves PNG and exits — enables automated visual regression testing.
- **Viewport scaling**: `recompute_viewport()` supports `letterbox`, `stretch`, `pixel`, and `none` modes with correct centering.

## 4. Gap List

1. **[P0][GAP]** `Hot reload (Lua + assets)` — No mechanism to reload scripts or assets without restarting the engine. Every competitor supports some form of live reload.
   - Why: The #1 missing feature for development workflow (GameDev, EngDev).
2. **[P1][GAP]** `app.rs is 3100+ lines` — Too large to navigate; mixes GPU init, event dispatch, game loop, splash screen, and auto-collect passes.
   - Why: Violates single-responsibility; makes targeted changes risky.
3. **[P2][GAP]** `No frame profiling hooks` — No way to measure per-callback timing (process, render, physics) from within the engine.
   - Why: Performance debugging requires external tools; cannot expose frame breakdown to `lurek.runtime`.

## 5. Feature Ideas

1. **[P0][FEAT]** `Lua hot-reload via file watcher` — On `main.lua` change, call `restart_game()` which reinitialises the Lua VM keeping window + GPU state. Asset changes invalidate affected SlotMap entries.
   - Rationale: Eliminates restart cycle for game authors. `filesystem::FileWatcher` already exists.
   - Effort: M · Risk: med (must preserve GPU state across restart).
   - Competitor inspiration: `[LÖVE: love.run() can be overridden for custom reload loops]`, `[Defold: live-reload of scripts + assets during Play mode]`, `[Godot: scene reload on editor save via ResourceLoader::reload_from_file]`.

2. **[P1][FEAT]** `Split app.rs into focused sub-modules` — Extract GPU init into `gpu_init.rs`, event dispatch into `event_dispatch.rs`, game loop into `game_loop.rs`, splash into `splash.rs`.
   - Rationale: 3100+ lines is unmanageable. Extraction is mechanical and low-risk.
   - Effort: M · Risk: low.

3. **[P2][FEAT]** `Frame profiling hooks` — Record per-callback wall-clock timing (process, render, physics, fixedUpdate) and expose via `lurek.runtime.getFrameProfile()`.
   - Rationale: Enables in-game performance overlays and automated perf regression tests.
   - Effort: S · Risk: low.
   - Competitor inspiration: `[Godot: Performance.get_monitor(TIME_PROCESS, TIME_PHYSICS_PROCESS)]`.

## 6. Performance / Reliability / Quality Ideas

- **[P1][QUAL]** `Extract splash screen to splash.rs` — `make_splash_commands()` and `SplashBranding` are self-contained; moving them reduces app.rs by ~200 lines.
  - File: `app.rs:SplashBranding`, `make_splash_commands`.
  - Reason: Readability; splash code is dead weight once a game is loaded.
- **[P2][PERF]** `Avoid per-frame Vec allocation in auto-collect` — Parallax, tilemap, and raycaster auto-collect loops allocate temporary `Vec`s each frame. Use a reusable `render_cmd_buf` (already exists but only for viewport wrapping).
  - Hot path: `app.rs:game_update` auto-collect sections.
  - Verification: alloc counting via `dhat` or `GlobalAlloc` counter.
- **[P2][REL]** `Timeout for Lua callbacks` — A stuck `lurek.process()` blocks the event loop forever. Add an optional wall-clock timeout with a configurable cap.
  - File: `app.rs:game_update`.
  - Suggested fix: `std::time::Instant` check after each callback; transition to `RunState::Error` on timeout.
- **[P3][QUAL]** `app_winit.rs is dead code` — Marked as "DEAD FILE" in its own doc comment. Remove or archive.
  - File: `app_winit.rs`.

## 7. Test Coverage Gaps

- **[P1][TEST-RUST]** `debug_overlay.rs` — Existing tests cover enabled/disabled/no-font. Add a test for command structure (assert background rect + 2 text prints).
- **[P1][TEST-RUST]** `error_screen.rs` — Existing tests cover basic construction. Add: wrap_text edge cases (single word > max_chars), format_traceback with nested CallbackError, as_text round-trip.
- **[P2][TEST-RUST]** `recompute_viewport` — Pure function, no GPU deps. Test all four scale modes, zero-size window, extreme aspect ratios.
- **[P2][TEST-RUST]** `fit_contain_size` — Pure function. Test square source, zero dims, extreme ratios.
- **[P2][TEST-RUST]** `resolve_present_mode` — Pure function. Test all request values against various available-mode lists.
- **[P3][TEST-LUA]** No Lua surface — no Lua tests needed.

## 8. TODO(dedup): Cross-Module Overlap

```text
TODO(dedup): devtools::DebugOverlay vs app::DebugOverlay — app has its own lightweight overlay; devtools may provide a richer one. Unify or differentiate clearly.
TODO(dedup): render::GpuRenderer init vs app::init_gpu — GPU device/surface creation logic is in app.rs; renderer construction is in render/. Consider a factory in render/.
```

## 9. TODO(helper): Engine-Level Helper Candidates

```text
TODO(helper): frame_profiler — Lua helper to display per-callback timing breakdown — citation: none (common game-dev debugging pattern).
```

## 10. TODO(plugin): Plugin Candidacy Proposal

```text
TODO(plugin): CORE-KEEP — app is the engine entry point and event loop owner. Cannot be extracted.
```

- **Extraction blockers**: Owns the winit event loop, wgpu surface, and Lua VM lifecycle. Tightly coupled to `runtime::SharedState`, `render::GpuRenderer`, and `lua_api::create_lua_vm`.
- **Heavy dep impact if extracted**: n/a.
- **Lua surface stability**: n/a (no Lua API).
- **Migration step**: n/a.

## 11. References

- Module spec: [docs/specs/app.md](../../docs/specs/app.md)
- Lua API reference: n/a (no direct Lua surface)
- Philosophy constraints touched: `A-01` (runtime only), `A-02` (desktop only), `B-02` (wgpu 22), `B-03` (60 FPS at 1080p on iGPU)
- Plugin doc tier table: [plugins.md §5](../../docs/architecture/plugins.md#5-candidate-modules)
- Authoring guide: [IDEA_AUTHORING.md](../../work/src-module-review-20260418/reports/IDEA_AUTHORING.md)
- Session plan: [PLAN.md](../../work/src-module-review-20260418/reports/PLAN.md)
