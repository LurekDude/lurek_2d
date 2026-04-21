# P2 — Cross-Module Overlap Pre-scan

- **Session**: `src-module-review-20260418` · Phase **P2** · Agent **Architect**
- **Mode**: READ-ONLY heuristic pre-scan (no source edited).
- **Branch**: `refactor/src-migration-v2`
- **Method**: Cross-read of `docs/specs/<m>.md` Files/Types/Functions sections (where present), `src/<m>/` top-level file names, and the `lua_total` registration counts from `P2_api_registration_matrix.md`. Heuristic — **not** a definitive duplication map. Each row is a hypothesis to be confirmed or dismissed in **P6 — Cross-module overlap synthesis**.

## Suspected overlaps

Severity column triage:
- **HIGH** — strong evidence of duplicated implementation (two modules ship the same algorithm or API surface).
- **MED** — adjacent responsibility with likely overlap in helpers (e.g. RNG seeded twice, table-walk helpers).
- **LOW** — same problem domain but plausibly partitioned cleanly; flag only for P6 sanity-check.

| # | Module A | Module B | Suspected overlap area | Severity | Rationale / where to confirm in P6 |
|---|---|---|---|---|---|
| 1 | `tween` | `animation` | Time-based property interpolation. | **HIGH** | `tween` advertises "property animation API" (animate any Lua field) and `animation` advertises "frame clips, named animations". `tween` likely contains easing curves; `animation` may also hold easing for tween-style frame blending. Confirm whether both depend on a shared `crate::math::easing` (good) or each duplicate easing constants (bad). |
| 2 | `tween` | `effect` | Per-frame value interpolation (post-FX shader uniforms ramping). | MED | `effect` likely has its own colour/uniform LERP for postfx fades. Confirm whether `effect` calls `crate::tween` or owns its own LERP. |
| 3 | `serial` | `save` | Binary serialization. | **HIGH** | `serial` exposes `lurek.serial.*` (LIMG, LSND, LMID format codecs); `save` exposes `lurek.save.*` slot-based persistence. Likely both write Lua table → bytes; check for a shared `crate::serial::table_to_bytes` versus a parallel implementation in `crate::save`. |
| 4 | `serial` | `data` | Compression / encoding (`lurek.data.*` advertises "compression, hashing, encoding"; `lurek.serial.*` advertises "format serialization"). | MED | Likely overlap in base64/hex/zlib helpers. Confirm in `src/data/` and `src/serial/` for two copies of `encode_base64` / `compress_zlib`. |
| 5 | `data` | `save` | Binary blob → file. | LOW | `save` may use `data::compress` to gzip slot data. Acceptable layering if so; flag if both wrap `flate2` directly. |
| 6 | `math` | `procgen` | Random number generation. | **HIGH** | `math` ships RNG (Random userdata, vec/mat math, noise — `pub_fn=192`); `procgen` ships its own noise/rng for terrain/maze generation (`pub_struct=24`). Almost certainly two PRNG implementations or two `Perlin` modules. Confirm by grepping `src/procgen/` for `Rng`, `Perlin`, `Simplex`. |
| 7 | `math` | `ai` | Steering / vector math. | LOW | `ai_api::LuaSteeringManager` performs vector arithmetic; should consume `crate::math::vec` not duplicate it. P6 verify. |
| 8 | `math` | `physics` | Vector / shape primitives. | MED | `physics` uses rapier types (Vec2 etc.); `math` exposes its own `Vec2`. Two parallel vector types is the canonical overlap; may already be an explicit conversion seam (acceptable) or an implicit duplicate (bad). |
| 9 | `pathfind` | `ai` | Goal-oriented planning / search. | MED | `ai` has a GOAP planner (`LuaGOAPPlanner`); `pathfind` has A*/JPS/HPA*. Both run search algorithms; verify GOAP doesn't ship its own A* helper that duplicates `crate::pathfind::astar`. |
| 10 | `pathfind` | `minimap` | Grid representation. | LOW | `minimap` advertises grid-based minimap; `pathfind` ships `NavGrid`. `minimap` likely consumes `NavGrid` (good) or duplicates a `Grid<u32>` (bad). Confirm in `src/minimap/` imports. |
| 11 | `pathfind` | `tilemap` | Grid coord ↔ pixel conversion. | LOW | `tilemap` ships coord helpers; `pathfind` has its own `(x,y)` indexing. `LuaNavGrid::fromTilemap` (line 1245) suggests `pathfind` already takes a tilemap layer — interface, not duplicate. Verify no extra coord-math copy. |
| 12 | `filesystem` | `mods` | Game-dir resolution + sandboxed read. | MED | `mods` loads mod manifests from disk; `filesystem` is the sanctioned sandboxed I/O. Confirm `mods` calls `filesystem::*` rather than re-rolling `std::fs::read_dir`. |
| 13 | `filesystem` | `save` | File path resolution under `game_dir`. | MED | `save_api` likely computes `state.game_dir.join(&slot_name)` directly; should ideally route through `filesystem::sandboxed_path`. Same for `audio`/`image` (which were flagged in `P2_thin_wrapper_offenders.md`). |
| 14 | `filesystem` | `audio` / `image` / `docs` / `ui` | Direct `std::fs::*` reads bypassing the sandbox. | MED | All four are flagged as offenders in `P2_thin_wrapper_offenders.md` — the consolidation target is the same `crate::filesystem::sandboxed_*` API surface. P6/P5 cross-link. |
| 15 | `ecs` | `scene` | Object lifecycle / iteration. | MED | `ecs` provides entities; `scene` provides the scene stack and depth-sorter. Overlap if `scene` keeps its own object pool instead of being a render-order layer over `ecs`. Verify in `src/scene/`. |
| 16 | `ecs` | `patterns` | Component-style behaviours (Observer, Command, etc.). | LOW | `patterns` exposes 27 `pub_struct`s including likely Observer/Command/State implementations; some may be implementable on top of `ecs::Entity`. P6 verify, low priority. |
| 17 | `event` | `patterns` | Observer / pub-sub. | MED | `event_api` is the queue/signal hub; `patterns_api` likely also ships an Observer pattern. Confirm whether `patterns::Observer` is a thin alias over `event::Signal`. |
| 18 | `event` | `automation` | Input event injection. | LOW | `automation` ("simulator") replays/captures input — it almost certainly **needs** the event queue. Verify it consumes `event::*` and doesn't re-implement queueing. |
| 19 | `input` | `automation` | Input record/replay. | LOW | Same domain by design (automation injects input). Confirm clean directional dependency `automation → input`. |
| 20 | `sprite` | `animation` | Sprite-sheet UV / frame ranges. | MED | `sprite_api` (`lurek.sprite`) ships UV layout & atlas parsing; `animation` ships frame clips. Both touch sprite frames; verify `animation::Animation::from_atlas` consumes `sprite::Atlas` rather than re-parsing. |
| 21 | `sprite` | `spine` | Skeletal vs. spritesheet animation. | LOW | Different mechanics, but both ultimately produce textured quads each frame. No duplication expected; just ensure both render through the same `crate::render::*` queue. |
| 22 | `particle` | `effect` | GPU shader-driven visual effects. | MED | `effect` is post-FX; `particle` is per-particle quads. Both write into the render queue; check whether each maintains its own draw-state struct vs. using a shared `render::DrawCmd`. |
| 23 | `particle` | `parallax` | Multi-layer scrolling. | LOW | `parallax` is background-layer-only; particles are emitter-driven. Different mental models; flag only for explicit confirmation that they share `camera::view_matrix`. |
| 24 | `camera` | `window` | Viewport / DPI scaling. | LOW | `window` owns OS window + framebuffer size; `camera` owns world-space view. Clean split expected; verify no DPI math is in both. |
| 25 | `camera` | `scene` | Active camera tracking. | LOW | `scene` may store the current camera handle; verify it's a **handle** to `camera::*`, not a duplicate `Camera2D` struct. |
| 26 | `light` | `effect` | Render-target compositing. | LOW | Both render off-screen and composite over the scene; verify they share `render::Canvas`. |
| 27 | `raycaster` | `render` | Quad emission for textured walls/floors. | LOW | `raycaster` is 2.5D rendering via 2D draw calls (per A-03); should consume `render::DrawCmd`, not maintain its own pipeline. Verify. |
| 28 | `raycaster` | `tilemap` | Grid-based map representation. | MED | `raycaster` walks a 2D grid for DDA; `tilemap` owns 2D tile grids. Confirm raycaster accepts `tilemap::Layer` or whether it has its own `RaycasterMap` type that mirrors tilemap's layout. |
| 29 | `terminal` | `ui` | Text rendering / character grid. | LOW | `terminal` is a text-mode emulator (CP437); `ui` has labels/buttons. Both rasterise text via `crate::render::font`; verify single font path. |
| 30 | `terminal` | `i18n` | Glyph fallback / locale. | LOW | If terminal renders Unicode beyond CP437, may overlap with `i18n::Catalog`. Verify scope; likely no overlap. |
| 31 | `compute` | `dataframe` | GPU/CPU array ops. | MED | `compute` exposes "array computation" (108 `pub_fn`); `dataframe` exposes tabular data with column ops. Both are array/columnar systems. Confirm clean split: is `dataframe` built on `compute::Array`, or independent (probably independent on Polars)? |
| 32 | `compute` | `data` | Buffer / encoding helpers. | LOW | `data` has `pub_struct=4` (small surface — likely Buffer, Hash, Compress); `compute` has its own buffer types. Different intents; verify no `Vec<u8>` helper duplicated. |
| 33 | `dataframe` | `data` | Same as above: tabular vs. binary blob. | LOW | Likely orthogonal. |
| 34 | `pipeline` | `graph` | DAG/graph data structures. | MED | `pipeline` is a DAG orchestrator (29 pub_fn); `graph` is a directed-graph + item-flow simulation (120 pub_fn). Two graph implementations is the classic overlap. Verify whether `pipeline` builds on `graph::DiGraph` or owns its own DAG type. |
| 35 | `network` | `thread` | Background tasks. | LOW | `network` runs UDP I/O; `thread` exposes worker VMs. Confirm `network` doesn't spin its own background thread without the `thread` abstraction (or it might be intentional for UDP polling — verify in P6). |
| 36 | `log` | `devtools` | Diagnostic output. | MED | `log` is the structured-log facade (always-on); `devtools` exposes profiler/REPL/file-watcher. Confirm `devtools` writes through `log::*` rather than printing directly. |
| 37 | `log` | `debugbridge` | Remote diagnostic stream. | LOW | `debugbridge` is a TCP debug server; should likely subscribe to the `log` stream rather than maintaining a parallel sink. Verify in P6. |
| 38 | `docs` | `mods` | Asset/manifest scanning. | LOW | Both walk directories. Confirm directory-walk helper is shared (likely uses `std::fs::read_dir` independently — pre-flagged in `P2_thin_wrapper_offenders.md`). |
| 39 | `i18n` | `docs` | String table / catalog format. | LOW | Different domains but both store key→string maps. No duplication expected; flag for P6 sanity check. |
| 40 | `timer` | `tween` | Frame-time tracking. | LOW | `tween` advances by `dt`; `timer` exposes frame time / FPS. `tween` should consume `timer::dt()` not own a separate clock. |

## Cross-cut: filesystem-bypass cluster

The single largest *behavioural* overlap visible in the snapshot is the **direct-`std::fs` cluster** flagged in `P2_thin_wrapper_offenders.md`: `audio_api`, `image_api`, `docs_api`, `ui_api`, and `render_api` all bypass `crate::filesystem` and call `std::fs::{read, read_to_string, write, create_dir_all, read_dir}` directly.

This is technically a *binding-layer* problem (P5-fs-pull-down sub-phase), but it surfaces in this overlap report because the **sandbox responsibility** that should sit in `filesystem/` is being spread across five other modules. P6 should treat "every domain that does I/O" as a sub-cluster and decide whether `crate::filesystem::sandbox` becomes a mandatory crate-internal API.

## Cross-cut: serialization cluster

Three modules carry overlapping serialization concerns:

- `serial` — codec/format serialization (`lurek.serial.*`)
- `save` — slot-based save/load (`lurek.save.*`)
- `data` — binary buffers / compression / hashing / encoding (`lurek.data.*`)

For P6: produce a **canonical serialization stack** — buffer (`data`) → codec (`serial`) → persistence (`save`) — and verify each layer only depends *downward*. Today's evidence is heuristic (no concrete duplication confirmed), but the surface-area overlap is high enough that a one-page architectural check is worth the time.

## Done-when checklist

- [x] ≥ 5 suspected overlap entries (40 entries; far exceeds the minimum).
- [x] Each entry names module pair, area, severity, and a P6 verification action.
- [x] Two cross-cut clusters (filesystem-bypass, serialization stack) called out for P6 architectural review.
- [x] Report ≤ 300 lines (this file: ~155).
