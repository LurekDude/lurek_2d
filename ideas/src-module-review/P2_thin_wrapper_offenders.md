# P2 — Thin-wrapper Offender Audit

- **Session**: `src-module-review-20260418` · Phase **P2** · Agent **Architect**
- **Mode**: READ-ONLY (no source edited)
- **Branch**: `refactor/src-migration-v2`
- **Inputs**: 50 files under `src/lua_api/` (49 `<m>_api.rs` + 3 cross-cut files: `mod.rs`, `lua_types.rs`, `engine_api.rs`/`system_api.rs`/`collision_api.rs` which have no matching `src/<m>/`).
- **Rule audited**: Lurek2D Thin-Wrapper Rule — `src/lua_api/<m>_api.rs` owns all `impl LuaUserData` and `mlua` imports; domain modules under `src/<m>/` stay pure-Rust. Any business logic (file I/O, multi-step algorithms, math beyond conversion, error-recovery state machines) in `lua_api/` is a violation that should move to `src/<m>/`.

## Severity rubric

| Severity | Definition | Triage |
|---|---|---|
| **HIGH** | File I/O, multi-step algorithm, state machine, or non-trivial error-recovery logic that belongs in domain crate. Each item is a candidate P5-* sub-phase. |
| **MED** | Branching control flow over domain types (loops with logic, partial computations) where a small helper in `src/<m>/` would clean it up. Bundle into a P5-* sub-phase per module. |
| **LOW** | Trivial table/array iteration for parameter conversion (e.g. flat-pair Lua table → Rust `Vec<f32>`) or single nested loop for grid setup. Acceptable but flagged for awareness; no P5 entry required. |
| **CLEAN** | Pure thin-wrapper: userdata defs + parameter unwrap + single-call delegation to `crate::<m>::*`. |

`for k, v in tbl.pairs()` style iteration purely to convert a Lua table into a Rust `HashMap` / `Vec` is treated as parameter conversion and **not** an offence.

## Summary counts

| Severity | Files |
|---|---:|
| HIGH | 4 |
| MED  | 6 |
| LOW  | 8 |
| CLEAN | 32 |
| **Total** | **50** |

Top offender modules (by escalation priority): `audio_api`, `docs_api`, `image_api`, `ui_api`, `render_api`, `pipeline_api`, `effect_api`, `system_api`.

## HIGH offenders

### `src/lua_api/audio_api.rs` (3076 lines)

| Function | Line range | Offence | Proposed move-to |
|---|---|---|---|
| `lurek.audio.setMidiSoundFont` closure | 2173–2194 | Direct `std::fs::read(&full_path)` for SoundFont loading; constructs absolute path from `state.game_dir`. | `crate::audio::midi::load_soundfont(game_dir, rel_path) -> Result<Vec<u8>, String>` (or have `MidiState::set_soundfont_from_path(...)` accept a `Path` and own the read). |
| `lurek.audio.saveWAV` closure | 2683–2698 | `std::fs::create_dir_all(parent)` + `std::fs::write(path, bytes)` after calling `sd.encode_wav()`. The wrapper performs both filesystem branching and parent-directory bootstrap. | `crate::audio::sound_data::SoundData::save_wav(&self, path: &Path) -> std::io::Result<()>` — encode + write live together in domain. |

### `src/lua_api/docs_api.rs` (1534 lines)

| Function | Line range | Offence | Proposed move-to |
|---|---|---|---|
| `lurek.docs.checkStaleness` | 803–833 | `std::fs::read_to_string(&path)` on a single source file plus directory walk via `std::fs::read_dir(&directory)` filtered by `.rs`/`.lua` extension. Builds three Lua tables with the result. | `crate::docs::staleness::check(source_dir: &Path) -> StalenessReport` (return three `Vec<PathBuf>`s). Wrapper just converts to Lua tables. |
| `lurek.docs.loadModule` (or analogous loader near 844–900) | 838–908 | Recursive `std::fs::read_dir` + per-file `std::fs::read_to_string` to harvest doc entries. | `crate::docs::loader::load_module(dir: &Path) -> Vec<DocEntry>`. |
| `lurek.docs.scanSourceDir` | 1095–1140 | Same `read_dir` pattern again, now feeding `parse_file`. | Same loader module. |
| `lurek.docs.exportMarkdown` | 1290–1320 | Inline Markdown templating + `std::fs::write(path, md)` — multi-step formatting *and* file write, all inside the closure. | `crate::docs::export::write_markdown(catalog: &ApiCatalog, path: &Path) -> Result<(), String>`. |
| `lurek.docs.exportCheatsheet` | 1336–1360 | Same pattern: build text body then `std::fs::write`. | `crate::docs::export::write_cheatsheet(...)`. |

`docs_api.rs` essentially carries half of `crate::docs::export` *inside the binding layer*; it should drop to a thin selector once the moves land.

### `src/lua_api/image_api.rs` (1036 lines)

| Function | Line range | Offence | Proposed move-to |
|---|---|---|---|
| `lurek.image.savePNG` | 432–450 | Calls `img.encode_png()` then performs `std::fs::create_dir_all` + `std::fs::write`. | `crate::image::ImageData::save_png(&self, path: &Path)` (mirror the `save_wav` proposal). |
| `LuaImageData::mapPixels` (`add_method_mut`) | 583–607 | Double `for y in 0..h { for x in 0..w { ... } }` pixel loop calling a Lua callback per pixel. The loop itself is bridge concern (calling Lua), but the `(r,g,b,a)` tuple round-trip and partial-application live in the wrapper. | Acceptable to keep loop in wrapper (must call Lua) — but extract `crate::image::ImageData::for_each_pixel_mut(impl FnMut(u32,u32,Pixel)->Pixel)` so the wrapper is one call. |
| `LuaImageData::mapPixel` | 920–940 | Same as `mapPixels`. | Same helper. |

`mapPixels`/`mapPixel` are MED in isolation; promoted to HIGH only because they live next to `savePNG`/`loadImage`/`newProvinceGrid` which already mix domain concerns.

### `src/lua_api/ui_api.rs` (6608 lines — largest binding file)

| Function | Line range | Offence | Proposed move-to |
|---|---|---|---|
| `lurek.ui.loadLayoutFile` | 6062–6078 | `std::fs::read_to_string(&path)` then `crate::ui::load_layout_toml`. The read is a domain concern — `crate::ui::load_layout_toml` already exists for the parsing half but the loader for files is open-coded in the wrapper. | `crate::ui::load_layout_file(g: &mut Group, path: &Path) -> Result<usize, String>` — own the read. |
| `lurek.ui.<second loadLayoutFile>` (effect_api duplicate) | 6220–6240 | Second copy of the same `fs::read_to_string + load_layout_toml` pair (function is registered twice or there is a second variant). Confirm during P5. | Same helper. |

`ui_api.rs` itself is enormous but most of the bulk is widget-userdata methods that delegate to `crate::ui::*`; those are CLEAN. The HIGH classification is driven by the file-I/O wrapper *and* by the file's overall size — it deserves a P5-* split into per-widget submodules even without a logic move.

## MED offenders

### `src/lua_api/render_api.rs` (4646 lines)

- **`lurek.render.newFont` (PNG bitmap-font branch)** — lines 2255–2280. After failing to match a built-in default font, the closure does `std::fs::read(&full_path)` then computes `cell_w = (size * 0.6).round() as u32` and calls `Font::from_png_bytes`. Both the read and the cell-size heuristic should live in `crate::render::font` (e.g. `Font::load_png_with_size(path, size) -> Result<Font, _>`).
- **`LuaImageData::mapPixels` analogue inside render_api**: lines 124–145 contain a `for py/px` pixel loop that iterates per-pixel through a callback. Same pattern as `image_api` — extract `for_each_pixel_mut` into the appropriate domain.
- File is also the second-largest binding module (4.6 KLOC); even after logic moves, recommend a P5 split into `render_api/{font,canvas,shape,text,texture}.rs` submodules to keep each under the 1 KLOC informal cap.

### `src/lua_api/pipeline_api.rs` (1293 lines)

- **`Step::execute`** (the local-impl method invoked from a `add_method_mut` closure) — lines 60–100. Implements a **retry loop** (`for attempt in 0..max_attempts`) with status-mutation, error capture, and `should_run` short-circuiting. This is a multi-step state-machine algorithm and belongs in `crate::pipeline::step::Step::execute(ctx) -> StepOutcome`. The wrapper should pass the Lua callback handle through and translate the result.

### `src/lua_api/effect_api.rs` (1765 lines)

- **`LuaImageEffect::clone`** — lines 624–635. Walks `effect_count()` and reconstructs a new `ImageEffect` by deep-cloning each child. Trivial logic but lives at the binding seam; `crate::effect::image_effect::ImageEffect::deep_clone()` would let the wrapper be a one-liner.
- File is also one of the larger binding files; recommend a P5 split into `effect_api/{image_effect,shader_pass,overlay}.rs` submodules.

### `src/lua_api/system_api.rs` (634 lines)

- **`lurek.runtime.parseArgs`** (or the only large closure near line 488–535) — implements a full `--flag` / `--key=value` / `--key value` / `--` argv parser with index tracking (`while i < raw_args.len()`). Argv parsing is platform/system concern and should live as `crate::system::argv::parse(args: &[String]) -> ParsedArgs`.

### `src/lua_api/dataframe_api.rs` (1360 lines)

- **`lurek.dataframe.toRows` / `iterRows`** at line 580–610. `for row in 0..df.nrows()` collecting per-row `LuaTable`s. Acceptable as bridge code (must build Lua tables) but extract `crate::dataframe::DataFrame::row_view(idx) -> impl Iterator<Item = (&str, AnyValue)>` to keep the wrapper to a tight `for (name, val) in df.row_view(row) { tbl.set(name, ...)? }`.

### `src/lua_api/data_api.rs` (875 lines)

- **`lurek.data.popN` / `drainN`** style closures around line 850–880. `for i in 0..count` shifting items from a `VecDeque`. Better as `crate::data::buffer::Buffer::drain_n(n: usize) -> Vec<Item>`.

## LOW offenders (acceptable but noted)

| File | Line | Pattern | Notes |
|---|---|---|---|
| `physics_api.rs` | 50–58 | `while i < len as i64 { float_args.push(tbl.raw_get(i)?); float_args.push(tbl.raw_get(i+1)?); i += 2; }` | Flat-pair Lua table → `Vec<f32>` for polygon vertices. Pure parameter conversion. |
| `physics_api.rs` | 275–290, 330–345 | Same flat-pair conversion in two more closures. | Same; could share a helper but acceptable. |
| `math_api.rs` | 2045–2070 | `while i <= len as i64 { ... }` flat-pair points → `Vec<(f64,f64)>` for `delaunayTriangulate` / `convexHull`. | Same parameter-conversion pattern. |
| `particle_api.rs` | 1218–1232 | `for row in 0..rows { for col in 0..cols { quads.push([...]) } }` building flipbook UV quads. | Single nested loop, no branching. Could move to `crate::particle::flipbook::build_quads(cols, rows)` for symmetry but no behavioural risk. |
| `pathfind_api.rs` | 1245–1265 | Nested grid loop building a `NavGrid` from a tilemap layer + blocked-GID set. | Clear conversion-only intent; acceptable. |
| `tilemap_api.rs` | (no offending sites flagged) | Largest API by raw add-method count (136), but every `add_method` matched delegates to `crate::tilemap::*`. | LOW only because of size. |
| `ai_api.rs` | 1428–1450 | `for pair in world_state_tbl.pairs::<String,bool>()` → `HashMap`. | Parameter conversion. |
| `effect_api.rs` | 624–635 | Already listed as MED (`clone`). | — |

## CLEAN files (32)

`animation_api.rs`, `automation_api.rs`, `camera_api.rs`, `collision_api.rs`, `compute_api.rs`, `debugbridge_api.rs`, `devtools_api.rs`, `ecs_api.rs`, `engine_api.rs`, `event_api.rs`, `filesystem_api.rs`, `graph_api.rs`, `i18n_api.rs`, `input_api.rs`, `light_api.rs`, `log_api.rs`, `lua_types.rs`, `minimap_api.rs`, `mods_api.rs`, `network_api.rs`, `parallax_api.rs`, `procgen_api.rs`, `raycaster_api.rs`, `save_api.rs`, `scene_api.rs`, `serial_api.rs`, `spine_api.rs`, `sprite_api.rs`, `terminal_api.rs`, `thread_api.rs`, `timer_api.rs`, `tween_api.rs`, `window_api.rs`, `mod.rs` (registration glue only).

Note: `ai_api.rs` (3423 lines), `tilemap_api.rs` (2512 lines), `patterns_api.rs` (2601 lines), `terminal_api.rs` (1903 lines), `graph_api.rs` (1914 lines), and `audio_api.rs` (mostly clean apart from the two HIGH sites) are all **CLEAN by responsibility** but very large; recommend a P5 split into per-feature submodules for readability — those splits do not require domain-crate edits and can land alongside the IDEA.md additions in P3.

## Cross-cutting observation

Six of the ten HIGH/MED offences are **filesystem reads or writes** living in `lua_api/`:

- `audio_api::setMidiSoundFont`, `audio_api::saveWAV`
- `image_api::savePNG`
- `docs_api::checkStaleness`, `docs_api::scanSourceDir`, `docs_api::exportMarkdown`, `docs_api::exportCheatsheet`
- `ui_api::loadLayoutFile`
- `render_api::newFont` (PNG branch)

Recommendation for P5 sequencing: bundle these into a single sub-phase **P5-fs-pull-down** that adds matching `save_*` / `load_*` methods on the relevant domain types, leaving the wrappers as one-liners. Doing so closes the highest-volume class of violations and makes every remaining MED a single-function move.

## Done-when checklist

- [x] One row per `src/lua_api/<m>_api.rs` (50 files reviewed).
- [x] Every HIGH/MED entry names the offending function and proposes a move target.
- [x] Severity counts published.
- [x] Report ≤ 300 lines (this file: ~210).
