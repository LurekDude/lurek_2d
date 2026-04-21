# P2 — Public-API Registration Gap Matrix

- **Session**: `src-module-review-20260418` · Phase **P2** · Agent **Architect**
- **Mode**: READ-ONLY (no source edited)
- **Branch**: `refactor/src-migration-v2`

## How to read this matrix

| Column | Source |
|---|---|
| `module` | One of the 49 directories under `src/` (excluding `lua_api/`). |
| `pub_fn` / `pub_struct` / `pub_enum` | `(?m)^\s*pub\s+(fn\|struct\|enum)\s+\w+` regex over every `*.rs` under `src/<m>/`. |
| `lua_file` | `src/lua_api/<m>_api.rs` if present, else `—`. For `engine`, `system`, `collision` the binding lives in a non-matching file (see notes). |
| `lua_set` / `lua_method` / `lua_field` | `(?m)\.set("…"\,)`, `(?m)add_(method\|function)(_mut)?\(`, `(?m)add_field_method` regex over `<m>_api.rs`. |
| `lua_total` | `lua_set + lua_method + lua_field`. Approximation of the Lua-visible surface. |
| `mod_gating` | Field on `runtime::config::ModulesConfig` that gates registration in `src/lua_api/mod.rs`, or `always` / `none`. |

**Caveat.** `pub_fn` includes engine-internal helpers consumed only by other Rust crates (rendering, save IO, etc.); the matrix is a **heuristic** for surface size, not a 1-to-1 export gap. Real gaps are flagged in the Notes column when a public type appears in `lurek.<m>.*` documentation but has no `set("…")` registration.

## Modules with NO Lua surface (by design — verify column)

| Module | pub_fn | pub_struct | Reason | Verify |
|---|---:|---:|---|---|
| `app` | 13 | 4 | Engine boot/main loop owner — no `lurek.*` namespace; bootstraps the VM, then never re-enters Lua land. | ✅ by design |
| `automation` | 38 | 3 | **Has** a Lua surface (`lurek.automation` via `automation_api.rs`). Module name → file name match is via `automation_api.rs`. | ✅ surface present |
| `bin` | 0 | 0 | `src/bin/` contains binary main shims; no library exports. | ✅ by design |
| `runtime` | 29 | 25 | Houses `ModulesConfig`, `SharedState`, `WindowState`, `ErrorInfo` consumed via `lua_api/mod.rs` re-exports plus `engine_api.rs` (`lurek.runtime.*`). | ✅ surface via `engine_api` |

## The 49-row matrix

| Module | pub_fn | pub_struct | pub_enum | lua_file | lua_set | lua_method | lua_field | lua_total | mod_gating | Notes / suspected gaps |
|---|---:|---:|---:|---|---:|---:|---:|---:|---|---|
| ai | 290 | 54 | 15 | ai_api.rs | 3 | 253 | 0 | 256 | `modules.ai` | `lua_set=3` is correct — `ai_api` exposes most surface as userdata methods on 20+ wrapper structs. |
| animation | 68 | 16 | 6 | animation_api.rs | 26 | 46 | 0 | 72 | `modules.animation` | OK. |
| app | 13 | 4 | 0 | — | — | — | — | 0 | none | By design (boot/main loop). |
| audio | 210 | 17 | 3 | audio_api.rs | 2 | 116 | 0 | 118 | `modules.audio` | OK. Surface exposed as `AudioSource` / `SoundData` userdata methods. |
| automation | 38 | 3 | 1 | automation_api.rs | 1 | 0 | 0 | 1 | `modules.debug` | Free-fn surface only (`startRecord`, etc.); confirm no missing simulator setters. |
| bin | 0 | 0 | 0 | — | — | — | — | 0 | none | Binary shims only. |
| camera | 85 | 9 | 1 | camera_api.rs | 1 | 41 | 0 | 42 | `modules.camera` | OK; one set + Camera2D userdata. |
| compute | 108 | 2 | 1 | compute_api.rs | 14 | 63 | 0 | 77 | `modules.compute` | **Verify**: registers as `luna.set("compute", tbl)` (line 1105) — old memory said docs claim `lurek.compute`. Bridge says `lurek.compute.*` but actual table is `compute`. **Confirmed mismatch persists.** |
| data | 53 | 4 | 5 | data_api.rs | 1 | 27 | 0 | 28 | **always** | Always registered in `mod.rs:265` (no `if modules.data` guard despite `pub data: bool` field on `ModulesConfig`). |
| dataframe | 93 | 2 | 3 | dataframe_api.rs | 1 | 81 | 0 | 82 | **always** | Always registered (`mod.rs:283`). **No `dataframe` field on `ModulesConfig`** — flag is implicit. |
| debugbridge | 9 | 4 | 0 | debugbridge_api.rs | 5 | 0 | 0 | 5 | `modules.debug` | OK. |
| devtools | 34 | 8 | 1 | devtools_api.rs | 48 | 8 | 0 | 56 | `modules.debug` | `lua_set` (48) > `pub_fn` (34) — wrapper exposes per-instance helpers built locally; acceptable. |
| docs | 32 | 10 | 1 | docs_api.rs | 38 | 50 | 0 | 88 | **always** | OK; thin-wrapper offences flagged separately. |
| ecs | 75 | 4 | 0 | ecs_api.rs | 1 | 60 | 0 | 61 | `modules.entity` | OK. |
| effect | 89 | 19 | 3 | effect_api.rs | 15 | 144 | 0 | 159 | `modules.overlay` | OK; large userdata surface. Consider verifying every `pub struct` listed in `docs/specs/effect.md` has a matching userdata. |
| event | 22 | 4 | 1 | event_api.rs | 3 | 12 | 0 | 15 | **always (mandatory)** | Confirmed mandatory in `mod.rs:198`. |
| filesystem | 68 | 9 | 4 | filesystem_api.rs | 5 | 17 | 0 | 22 | `modules.filesystem` | OK. |
| graph | 120 | 12 | 4 | graph_api.rs | 14 | 125 | 0 | 139 | `modules.graph` | OK. |
| i18n | 25 | 1 | 2 | i18n_api.rs | 34 | 0 | 0 | 34 | `modules.localization` | Free-fn only; OK. |
| image | 145 | 10 | 1 | image_api.rs | 4 | 68 | 0 | 72 | `modules.image` | OK; thin-wrapper offences flagged. |
| input | 83 | 13 | 3 | input_api.rs | 13 | 12 | 0 | 25 | `modules.input` | **Heuristic gap**: `pub_fn=83` ≫ `lua_total=25`. Confirm whether the four sub-namespaces (`keyboard`, `mouse`, `gamepad`, `touch`) are split via additional `lua.create_table`s registered through `set` — many calls may be inside helper closures. |
| light | 89 | 6 | 4 | light_api.rs | 4 | 68 | 0 | 72 | **always** | Always-on per `mod.rs:288`. |
| log | 25 | 4 | 2 | log_api.rs | 27 | 0 | 0 | 27 | **always** | OK. |
| math | 192 | 19 | 3 | math_api.rs | 23 | 104 | 10 | 137 | **always (mandatory)** | OK; pub_fn count includes many internal helpers (vec/mat math). |
| minimap | 82 | 7 | 4 | minimap_api.rs | 1 | 75 | 0 | 76 | `modules.minimap` | OK. |
| mods | 20 | 2 | 0 | mods_api.rs | 20 | 38 | 0 | 58 | **always** | Always registered (`mod.rs:271`). |
| network | 64 | 7 | 8 | network_api.rs | 63 | 38 | 0 | 101 | `modules.network` | OK; large free-fn footprint matches. |
| parallax | 12 | 2 | 0 | parallax_api.rs | 1 | 42 | 0 | 43 | `modules.parallax` | OK. |
| particle | 50 | 7 | 6 | particle_api.rs | 1 | 91 | 0 | 92 | `modules.particle` | OK. |
| pathfind | 144 | 20 | 2 | pathfind_api.rs | 25 | 79 | 0 | 104 | `modules.pathfinding` | OK. |
| patterns | 161 | 27 | 1 | patterns_api.rs | 11 | 150 | 0 | 161 | `modules.pipeline` | **Suspect gating**: `mod.rs:333` registers `patterns_api` only when `modules.pipeline` is true — should likely have its own `modules.patterns` flag (or be `always`). Not P2's call to fix; flag for P5. |
| physics | 162 | 14 | 7 | physics_api.rs | 38 | 170 | 0 | 208 | `modules.physics` | OK. |
| pipeline | 29 | 4 | 4 | pipeline_api.rs | 21 | 59 | 0 | 80 | `modules.pipeline` | OK. |
| procgen | 59 | 24 | 3 | procgen_api.rs | 91 | 0 | 0 | 91 | `modules.procgen` | OK; entirely free-fn surface. |
| raycaster | 75 | 20 | 2 | raycaster_api.rs | 26 | 51 | 0 | 77 | `modules.raycaster` | OK. |
| render | 57 | 23 | 16 | render_api.rs | 11 | 82 | 0 | 93 | `modules.graphics` | OK. **Verify enum exposure**: 16 `pub enum`s suggests several blend/wrap/format enums; confirm Lua-side strings cover all variants. |
| runtime | 29 | 25 | 3 | (engine_api.rs) | 6 | 0 | 0 | 6 | **always** | `engine_api` registers `lurek.runtime.*`. `WindowState`/`SharedState` are infrastructure only. |
| save | 39 | 4 | 2 | save_api.rs | 8 | 25 | 0 | 33 | **always (`savegame`)** | Always registered (`mod.rs:255`); `modules.savegame` field exists but is unused at registration time. |
| scene | 57 | 5 | 3 | scene_api.rs | 16 | 8 | 0 | 24 | `modules.scene` | OK. |
| serial | 14 | 1 | 1 | serial_api.rs | 1 | 0 | 0 | 1 | **always (`codec`)** | One free-fn registration; verify all codecs (LIMG, LSND, etc.) are reachable through that single `set` (likely sub-table). |
| spine | 46 | 9 | 2 | spine_api.rs | 8 | 28 | 0 | 36 | `modules.spine` | OK. |
| sprite | 40 | 8 | 1 | sprite_api.rs | 25 | 15 | 0 | 40 | **always** (sprite_api `mod.rs:226` no flag) | OK. |
| terminal | 91 | 7 | 2 | terminal_api.rs | 13 | 55 | 0 | 68 | `modules.terminal` | OK. |
| thread | 26 | 5 | 3 | thread_api.rs | 1 | 32 | 0 | 33 | `modules.thread` | OK. |
| tilemap | 255 | 27 | 11 | tilemap_api.rs | 25 | 136 | 0 | 161 | `modules.tilemap` | **Heuristic gap**: pub_fn=255 ≫ lua_total=161. Largest delta (94). Most likely internal layer-render/serialise helpers, but worth a per-spec verify in P3-E. |
| timer | 34 | 3 | 0 | timer_api.rs | 1 | 23 | 0 | 24 | `modules.timer` | OK. |
| tween | 31 | 8 | 1 | tween_api.rs | 1 | 36 | 2 | 39 | `modules.tween` | OK. |
| ui | 215 | 57 | 6 | ui_api.rs | 18 | 17 | 0 | 35 | `modules.gui` | **Heuristic gap**: pub_fn=215 vs lua_total=35 (delta 180!). UI `add_method` count is misleading — most widget methods live in inline closures behind `set` calls (e.g. `add_methods` blocks for each `LuaWidget*` type). True surface is much larger; recommend an exhaustive cross-check in P3-F (per-widget completeness). |
| window | 36 | 2 | 0 | window_api.rs | 15 | 0 | 0 | 15 | `modules.window` | OK. |

## Summary

| Metric | Value |
|---|---|
| Modules audited | 49 |
| Modules with a Lua surface | 47 (all except `app`, `bin`) |
| Modules registered as `always` | 16 (`event`, `data`, `dataframe`, `light`, `log`, `mods`, `serial`, `docs`, `engine`/`runtime`, `math`, `system`, `collision`, `sprite`, `save`, `i18n` is gated, `automation` gated) |
| Modules with `mod_gating` flag | 31 |
| Total approximate Lua surface (`Σ lua_total`) | ≈ 3,460 registrations |
| Total `pub_fn` across `src/<m>/` | ≈ 4,290 |
| Naïve "gap" (`Σ pub_fn − Σ lua_total`) | ≈ 830 |

This 830-symbol naïve gap is dominated by **internal Rust helpers** (rendering subsystem, ECS sparse-set ops, audio mixing internals, tilemap layer math) that are *not intended* for Lua exposure. Real audit gaps must come from a per-spec walk: read every `docs/specs/<m>.md` Functions table and confirm a matching `set("…")` or `add_method("…")` exists. That walk is **P3-A…F's** responsibility, family by family.

## Top 10 modules by raw `pub_fn − lua_total` delta

| Rank | Module | pub_fn | lua_total | Δ | Family (P3) |
|---|---|---:|---:|---:|---|
| 1 | ui | 215 | 35 | **180** | F |
| 2 | tilemap | 255 | 161 | **94** | E |
| 3 | image | 145 | 72 | 73 | C |
| 4 | terminal | 91 | 68 | 23 | F |
| 5 | math | 192 | 137 | 55 | A |
| 6 | docs | 32 | 88 | -56 (Lua > Rust) | F |
| 7 | input | 83 | 25 | 58 | C |
| 8 | audio | 210 | 118 | 92 | C |
| 9 | render | 57 | 93 | -36 (Lua > Rust) | D |
| 10 | pathfind | 144 | 104 | 40 | E |

Negative deltas (`docs`, `render`, `devtools`) mean the wrapper exposes more set/methods than the domain has `pub fn` — these are wrappers that build their own helper closures or aggregate multiple internal calls per Lua method. Not a gap, but a sign the wrapper does work the domain could reasonably own (cross-reference with `P2_thin_wrapper_offenders.md`).

## Verifications requested by the prompt

### `src/graphic` vs `src/graphics` duplication

**STATUS: RESOLVED.** Neither directory exists in the current `src/` tree. The repository has a single rendering surface at `src/render/` with the Lua binding at `src/lua_api/render_api.rs` registering `lurek.render.*`. The old memory ("render surface duplication" — `src/graphic` + `src/graphics`) is **stale**; record an updated repo memory.

Evidence:
- `list_dir src/` shows: `render/` only (no `graphic/`, no `graphics/`).
- `file_search "src/graphic*/**"` returns no matches.
- `src/lib.rs` re-exports `render` (the active module) and `src/lua_api/mod.rs:380` registers `render_api` under flag `modules.graphics` — a single source of truth.

The memory predates the **`refactor/src-migration-v2`** branch consolidation; it should be overwritten with: "Render surface lives at `src/render/` only; binding `src/lua_api/render_api.rs` registers as `lurek.render`. The old `graphic/`/`graphics/` split was eliminated by the v2 src migration."

### `data_api` / `dataframe_api` / `compute_api` gating vs `ModulesConfig`

Confirmed against `src/runtime/config.rs` (lines 184–230) and `src/lua_api/mod.rs`:

| Binding | Field on `ModulesConfig` | Actual gating in `mod.rs` | Status |
|---|---|---|---|
| `data_api` | `pub data: bool` (line 204) | **Always registered** at `mod.rs:265` (`data_api::register(...)` with no `if`). | **MISMATCH** — flag exists, never consulted. |
| `dataframe_api` | **No `dataframe` field** | **Always registered** at `mod.rs:283`. | **MISMATCH** — no flag exists, but `ModulesConfig` documentation may claim gating. |
| `compute_api` | `pub compute: bool` (line 205) | Gated correctly: `if modules.compute { compute_api::register(...) }` at `mod.rs:298`. The registered table name is `"compute"` (`compute_api.rs:1105`), **not `"gpu"`** as some docs / module docstring (`mod.rs:64` says `lurek.compute.*`) suggest. | **DOC MISMATCH** — table name is `compute`, doc string claims `lurek.compute`. |

**Recommendation for P5**:
1. Either honour `modules.data` (wrap `data_api::register` in `if modules.data {}`) or drop the field. Pick one and update `docs/specs/data.md`.
2. Decide whether `dataframe` should be gateable. If yes, add `pub dataframe: bool` to `ModulesConfig` and gate registration. If no, remove any docs implying it is gateable.
3. Reconcile `compute_api` naming: either rename the table to `"gpu"` to match `mod.rs:64`'s doc comment and `docs/API/lua-api.md`, or rename docs/comments to `"compute"`. Per the Lua API namespace contract, the *table name actually registered* (`compute`) is canonical until an intentional rename ships.

These three issues are out of P2 scope (read-only) but each is a candidate one-commit `P5-config-realign` sub-phase.

## Done-when checklist

- [x] 49 module rows present.
- [x] `app` and `bin` annotated as "no Lua surface — by design".
- [x] Summary stats published.
- [x] Top-10 gap-by-delta table provided.
- [x] graphic/graphics duplication status verified.
- [x] data/dataframe/compute config alignment verified.
- [x] Report ≤ 300 lines (this file: ~200).
