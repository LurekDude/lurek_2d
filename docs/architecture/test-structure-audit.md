# Luna2D Test Suite — Structure Audit & Redesign Proposal

> **Scope**: Analysis only — no files are created, moved, or edited by this document.
> Every finding maps to a concrete proposed change.
> **Date**: 2026-04-02

---

## 1. Current Layout (Inventory)

```
tests/
├── *.rs                          (40 Rust integration test files — flat top-level)
├── golden_tests.rs               (Rust harness for binary golden comparisons)
├── lua_tests.rs                  (Rust harness dispatching into tests/lua/)
│
├── golden/
│   ├── expected/                 (baseline artifacts — 13 files)
│   │   ├── *.png  (3 images)
│   │   ├── *.txt  (5 text/hash/encode)
│   │   ├── *.bin  (3 compressed binary)
│   │   └── *.toml (1 TOML)
│   └── actual/                   (runtime outputs — same 13 files, git-ignored)
│
├── lua/
│   ├── init.lua                  (BDD framework: describe/it/expect_* globals)
│   ├── test_*.lua                (30 Lua unit tests — flat top-level)
│   ├── golden/
│   │   └── test_math_golden.lua  (1 Lua golden test — orphaned, not registered)
│   ├── integration/              (10 integration tests)
│   ├── stress/                   (12 stress tests)
│   └── validation/               (3 validation tests)
│
└── stress/                       (4 Rust stress tests registered via [[test]] in Cargo.toml)
    ├── compute_stress_tests.rs
    ├── data_stress_tests.rs
    ├── image_stress_tests.rs
    └── physics_stress_tests.rs
```

### File counts

| Layer | Files | Test functions |
|---|---|---|
| Rust integration (top-level) | 40 | ~1,521 `#[test]` |
| Rust golden harness | 1 | 16 |
| Rust Lua harness | 1 | 46 dispatchers + 8 inline log tests |
| Rust stress (`tests/stress/`) | 4 | 28 |
| Lua root tests | 30 | ~500 `it()` blocks |
| Lua integration | 10 | — |
| Lua stress | 12 | — |
| Lua validation | 3 | — |
| Lua golden | 1 | — |

---

## 2. Problem Areas

### 2.1 Rust test files are all flat at `tests/`

All 40 `.rs` integration test files sit at `tests/*.rs`.
There is no sub-folder grouping by domain, importance, or speed.

This means:
- `cargo test` runs everything in one undifferentiated pool.
- There is no way to run "only core engine tests" vs "only game-system tests" without long `--test` flags.
- Stress tests (slow) live at `tests/stress/` but are registered via explicit `[[test]]` blocks in `Cargo.toml`. Regular tests at `tests/*.rs` are discovered automatically — the two discovery models are inconsistent.
- `golden_tests.rs` and `lua_tests.rs` are mixed in with domain tests even though they are *harnesses* (dispatchers), not domain tests.

### 2.2 Rust test naming is inconsistent

Three distinct conventions exist — sometimes within the *same file*:

| Style | Example | Files using it |
|---|---|---|
| `test_` prefix | `fn test_aiworld_new_empty()` | `ai_tests.rs`, `audio_tests.rs`, `tilemap_tests.rs` (partial) |
| No prefix | `fn body_creation()` | `physics_tests.rs`, `graphics_tests.rs`, `math_tests.rs` |
| Mixed (both) | `fn mixer_load_source()` + `fn test_phase01_…()` | `audio_tests.rs` |

The `test_` prefix is redundant (Rust test runner identifies tests by `#[test]`) and actively hurts readability in `cargo test` output.

### 2.3 Rust test section separators are inconsistent

Four different separator styles are in use:

| Style | Files using it |
|---|---|
| `// ── Section ───────────────────────────────────────────────────` (box-drawing) | `ai_tests.rs`, `cardgame_tests.rs`, `crafting_tests.rs` |
| `// ===========================================================================` (equals row) | `compute_tests.rs`, `golden_tests.rs`, few others |
| `// --- New tests for … ---` (dash with inline description) | `physics_tests.rs` (appended section headers) |
| No separators at all | `graphics_tests.rs`, `math_tests.rs`, `physics_tests.rs` (partial) |

The `// --- New tests for … ---` stubs in `physics_tests.rs` are particularly telling — they show sections added at different times by different authors without cleanup.

### 2.4 Module-level `//!` doc comments are missing in many Rust test files

Files **with** a `//!` header (18/40):
`cardgame`, `combat`, `compute`, `crafting`, `data`, `dataframe`, `dialog`, `entity`, `event`, `golden`, `graph`, `graphics_ext`, `image`, `inventory`, `math_ext`, `minimap`, `modding`, `particle`, `pathfinding`, `postfx`, `province`, `quest`, `resource`, `savegame`, `scene`, `sound`, `stats`, `tilemap`

Files **without** any `//!` header (12/40):
`ai_tests.rs`, `audio_tests.rs`, `config_tests.rs`, `engine_tests.rs`, `filesystem_tests.rs`, `graphics_tests.rs`, `input_tests.rs`, `lua_tests.rs`, `math_tests.rs`, `physics_tests.rs`, `thread_tests.rs`, `timer_tests.rs`

### 2.5 Lua tests: four different framework patterns

The `tests/lua/init.lua` file provides a clean global BDD framework (`describe`, `it`, `expect_*`, `test_summary`). However, only some files use it correctly:

#### Pattern A — Correct (uses global framework) [22 files]
```lua
-- test_math.lua
describe("luna.math constants", function()
    it("has pi", function()
        expect_not_nil(luna.math.pi)
    end)
end)
test_summary()
```
Files: `test_audio.lua`, `test_compute.lua`, `test_dataframe.lua` (no summary), `test_debugbridge.lua`,
`test_devtools.lua`, `test_docs.lua`, `test_filesystem.lua`, `test_graph.lua`, `test_graphics.lua`,
`test_input.lua`, `test_joystick_ext.lua`, `test_localization.lua`, `test_math.lua`, `test_particle.lua` (no summary),
`test_pathfinding.lua`, `test_patterns.lua`, `test_physics.lua`, `test_postfx.lua` (no summary),
`test_signal.lua`, `test_system.lua`, `test_timer.lua`, `test_window.lua`

#### Pattern B — Local private framework [4 files]
```lua
-- test_tween.lua, test_drawlayer.lua, test_dialog.lua, test_minimap.lua
local total, passed, failed = 0, 0, 0
local current_describe = ""
local function describe(name, fn) ... end
local function it(name, fn) ... end
-- assertions are also local (expect_eq, expect_type, etc.)
-- At the end: _test_results = { total = total, passed = passed, failed = failed }
```
These files **re-implement** the framework locally. Their assertion naming also differs:
`expect_eq` (local) vs `expect_equal` (global). They do eventually set `_test_results` so `lua_tests.rs`
can read results, but they bypass the global framework and have incompatible assertion names.

#### Pattern C — Raw `assert()` with no framework [2 files]
```lua
-- test_entity.lua, test_scene.lua
assert(x == 1, "first entity should be 1")
assert(world:getEntityCount() == 2, "should have 2 entities")
-- Ends with: print("All entity tests passed!")
```
These files use bare `assert()` only. They print success but do NOT set `_test_results`.
Because `lua_tests.rs` checks `_test_results.failed` after running these files, and the field
won't exist, the Rust harness will crash with a "Missing _test_results global" panic —
unless these scripts are NOT registered (see §2.6).

#### Pattern D — Hybrid (sub-folder tests with global framework)
Integration, stress, and validation sub-folder tests all use Pattern A (global `describe`/`it`)
consistently. ✓

### 2.6 Lua tests: 10 files exist but are NOT registered in `lua_tests.rs`

The following files are in `tests/lua/` but have no corresponding `#[test]` dispatcher in `lua_tests.rs`:

| File | Framework | Status |
|---|---|---|
| `test_audio.lua` | A (global) | Missing `test_summary()` call |
| `test_dialog.lua` | B (local, sets `_test_results`) | Not registered |
| `test_drawlayer.lua` | B (local, sets `_test_results`) | Not registered |
| `test_entity.lua` | C (raw assert, NO `_test_results`) | Not registered (would crash) |
| `test_filesystem.lua` | A (global) — has `test_summary()` | Not registered |
| `test_minimap.lua` | B (local, sets `_test_results`) | Not registered |
| `test_particle.lua` | A (global) | Missing `test_summary()` call |
| `test_postfx.lua` | A (global) | Missing `test_summary()` call |
| `test_scene.lua` | C (raw assert, NO `_test_results`) | Not registered (would crash) |
| `test_tween.lua` | B (local, sets `_test_results`) | Not registered |

Additionally:
- `tests/lua/golden/test_math_golden.lua` — exists but is NOT registered in `lua_tests.rs`.
- Sub-folder files (`integration/`, `stress/`, `validation/`) are also unregistered — they have no dispatcher in `lua_tests.rs` at all.

### 2.7 Golden tests: no sub-folder grouping, missing sound/audio category

Currently `tests/golden/expected/` has 13 files across four categories mixed flat:

| Category | Files |
|---|---|
| Images | `solid_red_4x4.png`, `gradient_8x8.png`, `checkerboard_16x16.png` |
| Hash digests | `md5_hello.txt`, `sha1_engine.txt`, `sha256_hello.txt`, `sha512_engine.txt` |
| Encoding | `base64_encode.txt`, `hex_encode.txt` |
| Compression | `deflate_compressed.bin`, `lz4_compressed.bin`, `zlib_compressed.bin` |
| TOML | `toml_roundtrip.toml` |
| **Audio** | *(none)* |

Missing categories:
- **Audio**: no golden `.wav`/`.ogg` decode output, no waveform sample assertions
- **Font**: no golden glyph bitmap output (fontdue rasterisation is deterministic and should be goldenised)
- **Text**: no golden output for `encode_toml` format stability beyond roundtrip

### 2.8 Rust stress tests are co-located but use a different discovery mechanism

`tests/stress/*.rs` are registered via explicit `[[test]]` entries in `Cargo.toml`, while
`tests/*.rs` are auto-discovered. This split makes:
- Stress tests easy to exclude from normal `cargo test` (since they need a named `--test` flag)
- But the discovery model inconsistency is confusing — a reader of `tests/` doesn't understand
  why some subdirectory test files require Cargo.toml entries and others don't.

There is no way to run *all* stress tests together with `cargo test stress` — you must name each:
```
cargo test --test compute_stress_tests
cargo test --test data_stress_tests
cargo test --test image_stress_tests
cargo test --test physics_stress_tests
```

### 2.9 `tests/lua/init.lua` and `tests/lua_tests.rs` responsibilities are blurry

`lua_tests.rs` does three unrelated things:
1. Loads `tests/lua/init.lua` (framework bootstrap)
2. Dispatches 20 Lua test files via `run_lua_test()`
3. Directly tests `luna.log.*` API with 8 inline Rust tests that hardcode Lua snippets

The inline `luna.log` tests belong with audio/system-level tests or should be in a dedicated
`test_log.lua`. Their placement in the Lua dispatcher harness makes them hard to find.

---

## 3. Proposed New Structure

```
tests/
│
├── unit/                          ← NEW folder for Rust unit tests
│   ├── ai_tests.rs
│   ├── audio_tests.rs
│   ├── compute_tests.rs
│   ├── config_tests.rs
│   ├── data_tests.rs
│   ├── dataframe_tests.rs
│   ├── dialog_tests.rs
│   ├── engine_tests.rs
│   ├── entity_tests.rs
│   ├── event_tests.rs
│   ├── filesystem_tests.rs
│   ├── graphics_tests.rs
│   ├── graph_tests.rs
│   ├── image_tests.rs
│   ├── input_tests.rs
│   ├── math_tests.rs
│   ├── modding_tests.rs
│   ├── particle_tests.rs
│   ├── pathfinding_tests.rs
│   ├── physics_tests.rs
│   ├── postfx_tests.rs
│   ├── savegame_tests.rs
│   ├── scene_tests.rs
│   ├── sound_tests.rs
│   ├── thread_tests.rs
│   ├── tilemap_tests.rs
│   └── timer_tests.rs
│
├── ext/                           ← NEW folder for extension/Phase 2x Rust tests
│   ├── graphics_ext_tests.rs      (Phase 24)
│   └── math_ext_tests.rs          (Phase 25)
│
├── game/                          ← NEW folder for gameplay-system Rust tests
│   ├── ai_tests.rs                (already covers game-AI systems)
│   ├── cardgame_tests.rs
│   ├── combat_tests.rs
│   ├── crafting_tests.rs
│   ├── inventory_tests.rs
│   ├── minimap_tests.rs
│   ├── province_tests.rs
│   ├── quest_tests.rs
│   ├── resource_tests.rs
│   └── stats_tests.rs
│
├── stress/                        ← keep, but expand
│   ├── compute_stress_tests.rs
│   ├── data_stress_tests.rs
│   ├── image_stress_tests.rs
│   └── physics_stress_tests.rs
│
├── golden/
│   ├── harness.rs                 ← RENAME from golden_tests.rs (moved here)
│   ├── expected/
│   │   ├── image/                 ← NEW sub-folder
│   │   │   ├── solid_red_4x4.png
│   │   │   ├── gradient_8x8.png
│   │   │   └── checkerboard_16x16.png
│   │   ├── hash/                  ← NEW sub-folder
│   │   │   ├── md5_hello.txt
│   │   │   ├── sha1_engine.txt
│   │   │   ├── sha256_hello.txt
│   │   │   └── sha512_engine.txt
│   │   ├── encode/                ← NEW sub-folder
│   │   │   ├── base64_encode.txt
│   │   │   └── hex_encode.txt
│   │   ├── compress/              ← NEW sub-folder
│   │   │   ├── deflate_compressed.bin
│   │   │   ├── lz4_compressed.bin
│   │   │   └── zlib_compressed.bin
│   │   ├── data/                  ← NEW sub-folder
│   │   │   └── toml_roundtrip.toml
│   │   └── audio/                 ← NEW empty folder (for future sound golden tests)
│   └── actual/                    ← (git-ignored, same sub-folder mirrors)
│
└── lua/
    ├── init.lua                   ← keep (BDD framework, no changes)
    ├── harness.rs                 ← RENAME from lua_tests.rs (moved here)
    │
    ├── unit/                      ← NEW sub-folder (currently flat root .lua files)
    │   ├── test_ai.lua
    │   ├── test_audio.lua
    │   ├── test_audio_bus.lua
    │   ├── test_compute.lua
    │   ├── test_dataframe.lua
    │   ├── test_debugbridge.lua
    │   ├── test_devtools.lua
    │   ├── test_dialog.lua        ← migrate to global framework
    │   ├── test_docs.lua
    │   ├── test_drawlayer.lua     ← migrate to global framework
    │   ├── test_entity.lua        ← migrate to global framework
    │   ├── test_filesystem.lua
    │   ├── test_graph.lua
    │   ├── test_graphics.lua
    │   ├── test_input.lua
    │   ├── test_joystick_ext.lua
    │   ├── test_localization.lua
    │   ├── test_log.lua           ← NEW: extracted from harness.rs inline tests
    │   ├── test_math.lua
    │   ├── test_minimap.lua       ← migrate to global framework
    │   ├── test_particle.lua
    │   ├── test_pathfinding.lua
    │   ├── test_patterns.lua
    │   ├── test_physics.lua
    │   ├── test_postfx.lua
    │   ├── test_scene.lua         ← migrate to global framework
    │   ├── test_signal.lua
    │   ├── test_system.lua
    │   ├── test_timer.lua
    │   ├── test_tween.lua         ← migrate to global framework
    │   └── test_window.lua
    │
    ├── golden/
    │   └── test_math_golden.lua   ← register in harness
    │
    ├── integration/               ← keep as-is
    │   └── test_*.lua (10 files)
    │
    ├── stress/                    ← keep as-is
    │   └── test_*_stress.lua (12 files)
    │
    └── validation/                ← keep as-is
        └── test_*.lua (3 files)
```

---

## 4. File-by-File Change List

### 4.1 Files to MOVE (location change only, no content change)

| Current path | Proposed path | Reason |
|---|---|---|
| `tests/golden_tests.rs` | `tests/golden/harness.rs` | Co-locate harness with its data |
| `tests/lua_tests.rs` | `tests/lua/harness.rs` | Co-locate harness with its scripts |
| `tests/ai_tests.rs` | `tests/unit/ai_tests.rs` | Domain grouping |
| `tests/audio_tests.rs` | `tests/unit/audio_tests.rs` | Domain grouping |
| `tests/compute_tests.rs` | `tests/unit/compute_tests.rs` | Domain grouping |
| `tests/config_tests.rs` | `tests/unit/config_tests.rs` | Domain grouping |
| `tests/data_tests.rs` | `tests/unit/data_tests.rs` | Domain grouping |
| `tests/dataframe_tests.rs` | `tests/unit/dataframe_tests.rs` | Domain grouping |
| `tests/dialog_tests.rs` | `tests/unit/dialog_tests.rs` | Domain grouping |
| `tests/engine_tests.rs` | `tests/unit/engine_tests.rs` | Domain grouping |
| `tests/entity_tests.rs` | `tests/unit/entity_tests.rs` | Domain grouping |
| `tests/event_tests.rs` | `tests/unit/event_tests.rs` | Domain grouping |
| `tests/filesystem_tests.rs` | `tests/unit/filesystem_tests.rs` | Domain grouping |
| `tests/graphics_tests.rs` | `tests/unit/graphics_tests.rs` | Domain grouping |
| `tests/graph_tests.rs` | `tests/unit/graph_tests.rs` | Domain grouping |
| `tests/image_tests.rs` | `tests/unit/image_tests.rs` | Domain grouping |
| `tests/input_tests.rs` | `tests/unit/input_tests.rs` | Domain grouping |
| `tests/math_tests.rs` | `tests/unit/math_tests.rs` | Domain grouping |
| `tests/modding_tests.rs` | `tests/unit/modding_tests.rs` | Domain grouping |
| `tests/particle_tests.rs` | `tests/unit/particle_tests.rs` | Domain grouping |
| `tests/pathfinding_tests.rs` | `tests/unit/pathfinding_tests.rs` | Domain grouping |
| `tests/physics_tests.rs` | `tests/unit/physics_tests.rs` | Domain grouping |
| `tests/postfx_tests.rs` | `tests/unit/postfx_tests.rs` | Domain grouping |
| `tests/savegame_tests.rs` | `tests/unit/savegame_tests.rs` | Domain grouping |
| `tests/scene_tests.rs` | `tests/unit/scene_tests.rs` | Domain grouping |
| `tests/sound_tests.rs` | `tests/unit/sound_tests.rs` | Domain grouping |
| `tests/thread_tests.rs` | `tests/unit/thread_tests.rs` | Domain grouping |
| `tests/tilemap_tests.rs` | `tests/unit/tilemap_tests.rs` | Domain grouping |
| `tests/timer_tests.rs` | `tests/unit/timer_tests.rs` | Domain grouping |
| `tests/graphics_ext_tests.rs` | `tests/ext/graphics_ext_tests.rs` | Phase extension grouping |
| `tests/math_ext_tests.rs` | `tests/ext/math_ext_tests.rs` | Phase extension grouping |
| `tests/cardgame_tests.rs` | `tests/game/cardgame_tests.rs` | Gameplay system grouping |
| `tests/combat_tests.rs` | `tests/game/combat_tests.rs` | Gameplay system grouping |
| `tests/crafting_tests.rs` | `tests/game/crafting_tests.rs` | Gameplay system grouping |
| `tests/inventory_tests.rs` | `tests/game/inventory_tests.rs` | Gameplay system grouping |
| `tests/minimap_tests.rs` | `tests/game/minimap_tests.rs` | Gameplay system grouping |
| `tests/province_tests.rs` | `tests/game/province_tests.rs` | Gameplay system grouping |
| `tests/quest_tests.rs` | `tests/game/quest_tests.rs` | Gameplay system grouping |
| `tests/resource_tests.rs` | `tests/game/resource_tests.rs` | Gameplay system grouping |
| `tests/stats_tests.rs` | `tests/game/stats_tests.rs` | Gameplay system grouping |
| `tests/lua/test_ai.lua` → `test_window.lua` (30 files) | `tests/lua/unit/test_*.lua` | Mirror Rust structure |
| `tests/golden/expected/*.png/txt/bin/toml` | `tests/golden/expected/{image,hash,encode,compress,data}/` | Clarity |

### 4.2 Files needing CONTENT changes

#### Lua tests — migrate to global framework (4 files)

| File | Current pattern | Required changes |
|---|---|---|
| `test_tween.lua` | B (local private) | Remove local `describe/it/expect_*`; use global framework; rename `expect_eq` → `expect_equal`, `expect_near(a,b,e)` → `expect_near(expected, actual, tol)`; add `test_summary()` at end |
| `test_drawlayer.lua` | B (local private) | Same as above |
| `test_dialog.lua` | B (local private) | Same as above |
| `test_minimap.lua` | B (local private) | Same as above |

#### Lua tests — migrate to describe/it from raw assert (2 files)

| File | Current pattern | Required changes |
|---|---|---|
| `test_entity.lua` | C (raw assert) | Wrap each `-- ====` section in `describe(…, function()`, wrap each logical assertion block in `it(…, function()`, add `test_summary()` at end, set up `_test_results` via global |
| `test_scene.lua` | C (raw assert) | Same as above |

#### Lua tests — add missing `test_summary()` (7 files)

| File | Notes |
|---|---|
| `test_audio.lua` | Has `describe/it` but no `test_summary()` at end |
| `test_dataframe.lua` | Has `describe/it` but no `test_summary()` at end |
| `test_particle.lua` | Has `describe/it` but no `test_summary()` at end |
| `test_postfx.lua` | Has `describe/it` (uses local `expect_eq` vs global `expect_equal`) + no `test_summary()` |
| `test_audio_bus.lua` | Has `describe/it` but no `test_summary()` at end |
| `test_docs.lua` | Has `describe/it` but no `test_summary()` call visible |
| `test_compute.lua` | Has `describe/it` but no `test_summary()` at end |

> Note: `test_postfx.lua` also uses `expect_eq` (local style) instead of `expect_equal`. The file uses the
> global `describe`/`it` but its assertion names are local-style. This is a partial migration artifact.

#### `tests/lua/harness.rs` (formerly `lua_tests.rs`) — register missing Lua tests

Add dispatchers for all 10 unregistered Lua files:
- `test_audio`, `test_dialog`, `test_drawlayer`, `test_entity`, `test_filesystem`,
  `test_minimap`, `test_particle`, `test_postfx`, `test_scene`, `test_tween`
- Add dispatcher for `tests/lua/golden/test_math_golden.lua`
- Move the 8 inline `test_log_*` Rust tests to `test_log.lua` and add a dispatcher

#### Rust test files — add `//!` module headers (12 files)

Standardise with one-line `//!` + blank line before first `use`:

```rust
//! Integration tests for `luna2d::audio` — Mixer, Bus, MidiPlayer, and audio source lifecycle.

use std::cell::RefCell;
```

Files needing headers: `ai_tests.rs`, `audio_tests.rs`, `config_tests.rs`, `engine_tests.rs`,
`filesystem_tests.rs`, `graphics_tests.rs`, `input_tests.rs`, `lua_tests.rs`,
`math_tests.rs`, `physics_tests.rs`, `thread_tests.rs`, `timer_tests.rs`

#### Rust test files — standardise section separators

**Chosen standard** (matching `compute_tests.rs` and `golden_tests.rs`):
```rust
// ===========================================================================
// Section Name (src/module/file.rs)
// ===========================================================================
```

Files needing separator standardisation:
- `ai_tests.rs` (currently uses `// ── …` box-drawing)
- `physics_tests.rs` (currently uses `// --- New tests for … ---` stubs → promote to standard headers)
- `audio_tests.rs` (mixed, no separators between Phase blocks)
- `graphics_tests.rs` (no separators at all — infer from test function groupings)
- `math_tests.rs` (no separators)

#### Rust test files — standardise function naming

**Chosen standard**: no `test_` prefix — let `#[test]` + the context be enough.
```rust
// BAD
fn test_aiworld_new_empty()

// GOOD
fn aiworld_new_empty()
```

Files needing renaming: `ai_tests.rs`, `audio_tests.rs`, `tilemap_tests.rs`, and any others
with `test_` prefix on `#[test]` functions (not helper functions).

---

## 5. Cargo.toml — Proposed Test Registration Changes

### Current state
- `tests/*.rs` — auto-discovered by Cargo (no entries needed)
- `tests/stress/*.rs` — manually registered via 4 `[[test]]` blocks

### After moving files to sub-folders

Rust integration tests at `tests/unit/*.rs`, `tests/ext/*.rs`, `tests/game/*.rs` will need
`[[test]]` entries in `Cargo.toml` (Cargo only auto-discovers direct children of `tests/`).

Proposed `[[test]]` section grouping in `Cargo.toml`:

```toml
# ─── Unit tests ─────────────────────────────────────────────────────────────
[[test]]
name = "unit_ai"
path = "tests/unit/ai_tests.rs"
# ... (one entry per file in tests/unit/)

# ─── Extension tests ────────────────────────────────────────────────────────
[[test]]
name = "ext_graphics"
path = "tests/ext/graphics_ext_tests.rs"
[[test]]
name = "ext_math"
path = "tests/ext/math_ext_tests.rs"

# ─── Game-system tests ──────────────────────────────────────────────────────
[[test]]
name = "game_cardgame"
path = "tests/game/cardgame_tests.rs"
# ... (one entry per file in tests/game/)

# ─── Stress tests ───────────────────────────────────────────────────────────
[[test]]
name = "stress_compute"
path = "tests/stress/compute_stress_tests.rs"
# ... existing entries

# ─── Harnesses ──────────────────────────────────────────────────────────────
[[test]]
name = "golden"
path = "tests/golden/harness.rs"
[[test]]
name = "lua"
path = "tests/lua/harness.rs"
```

With this naming, test execution becomes composable:

```powershell
cargo test                                     # all tests
cargo test --test "unit_*"                     # unit tests only (partial match not supported natively, but...)
cargo test --test unit_physics                 # specific unit test
cargo test --test "stress_*"                   # stress only
cargo test --test golden                       # golden only
cargo test --test lua                          # all Lua tests
```

> **Note**: Cargo doesn't support glob `--test "unit_*"` natively. To enable group running, add
> test feature flags (see §6 on `cargo nextest`).

---

## 6. Test Markers & Running Strategy

### Recommended: adopt `cargo-nextest`

`cargo nextest` supports test filtering by name pattern, enabling:

```powershell
# Install once
cargo install cargo-nextest

# Run by group-prefix
cargo nextest run --test-threads 4 unit_       # all unit tests
cargo nextest run stress_                      # all stress tests
cargo nextest run game_                        # all game tests
```

### Tag convention for test functions

Add a `[category]` comment above test groups to support `cargo nextest`'s `--filter-expr`:

```rust
// [tag:unit] [tag:physics]
#[test]
fn body_creation() { … }
```

Then: `cargo nextest run --filter-expr 'test(#tag:physics)'`

### Suggested `Makefile` / task shortcuts

| Command | Purpose |
|---|---|
| `cargo test` | All tests |
| `cargo nextest run unit_` | Unit tests only (fast — no Lua VM startup) |
| `cargo nextest run lua` | All Lua integration tests |
| `cargo nextest run stress_` | Stress tests (slow — run in CI only) |
| `cargo nextest run golden` | Golden binary baseline tests |
| `cargo test --test lua -- lua_test_math` | Single Lua test |

---

## 7. Lua Framework — Standardised File Template

Every `tests/lua/unit/test_*.lua` file should follow this exact template:

```lua
-- tests/lua/unit/test_MODULE.lua
-- Unit tests for luna.MODULE — BRIEF DESCRIPTION
-- Headless-safe: no window, GPU, or audio device required.

-- ============================================================
-- SECTION NAME (matches src/lua_api/module_api.rs grouping)
-- ============================================================

describe("luna.MODULE section", function()

    it("brief description of the behaviour", function()
        -- arrange
        local value = luna.MODULE.something()
        -- assert
        expect_equal("expected", value)
    end)

end)

-- ============================================================
-- Another section
-- ============================================================

describe("luna.MODULE other section", function()

    it("another case", function()
        expect_near(0.5, luna.MODULE.calculate(), 0.001)
    end)

end)

test_summary()
```

Rules:
1. `--` file path comment on line 1
2. One-line description on line 2 (mirrors `//!` in Rust)
3. `-- Headless-safe` note on line 3 (or `-- Requires: GPU` if not headless-safe)
4. Section headers `-- ====` match source file groupings
5. `describe()` string = `"luna.MODULE subsystem"` (all lowercase, dotted)
6. `it()` string = plain English sentence, no "should" prefix needed
7. `test_summary()` always last line

---

## 8. Golden Tests — Proposed Enhancements

### 8.1 Sub-folder `assert_golden` helper

The `assert_golden()` helper in `harness.rs` currently uses flat filenames.
After adding sub-folders, it should accept a path:

```rust
/// Compare bytes against a golden baseline stored at `tests/golden/expected/{path}`.
fn assert_golden(path: &str, actual: &[u8]) { … }

// Usage:
assert_golden("image/solid_red_4x4.png", &png);
assert_golden("hash/sha256_hello.txt", digest.as_bytes());
```

### 8.2 Missing golden categories to add

| Category | File(s) to add | Why |
|---|---|---|
| Audio | `audio/sine_440hz_100ms.wav` | rodio `SineWave` source is deterministic |
| Audio | `audio/sample_rate_44100.txt` | verify sample rate constant |
| Font | `font/embedded_font_glyph_A.bin` | fontdue rasterisation is deterministic |
| Text | `data/toml_complex_types.toml` | round-trip stability for nested TOML |

---

## 9. Summary of All Problems & Their Fixes

| # | Problem | Files Affected | Fix |
|---|---|---|---|
| R-01 | No sub-folder grouping for Rust tests | 40 `.rs` files | Move to `unit/`, `ext/`, `game/` sub-folders; add `[[test]]` entries |
| R-02 | `test_` prefix on `#[test]` functions | `ai_tests.rs`, `audio_tests.rs`, `tilemap_tests.rs` | Remove `test_` prefix from test function names |
| R-03 | Inconsistent section separators | `ai_tests.rs`, `physics_tests.rs`, `audio_tests.rs`, `graphics_tests.rs`, `math_tests.rs` | Standardise to `// ===…` style |
| R-04 | Missing `//!` module doc headers | 12 files (listed in §2.4) | Add one-line `//!` header |
| R-05 | Harness files mixed with domain tests | `golden_tests.rs`, `lua_tests.rs` | Move to `tests/golden/harness.rs`, `tests/lua/harness.rs` |
| R-06 | Inline Lua snippets in `lua_tests.rs` | `lua_tests.rs` (8 tests) | Extract to `tests/lua/unit/test_log.lua` |
| R-07 | Stress tests need explicit Cargo entries | `tests/stress/` | Document in README; extend with `[[test]]` group prefix naming |
| L-01 | 4 Lua files use local private framework | `test_tween`, `test_drawlayer`, `test_dialog`, `test_minimap` | Migrate to global `init.lua` framework; rename assertions |
| L-02 | 2 Lua files use raw `assert()` | `test_entity`, `test_scene` | Wrap in `describe/it`; add `test_summary()` |
| L-03 | 7 Lua files missing `test_summary()` | `test_audio`, `test_dataframe`, `test_particle`, `test_postfx`, `test_audio_bus`, `test_docs`, `test_compute` | Add `test_summary()` as last line |
| L-04 | 10 Lua files unregistered in harness | see §2.6 | Add dispatchers in `harness.rs` |
| L-05 | `test_postfx.lua` uses `expect_eq` not `expect_equal` | `test_postfx.lua` | Rename to match global framework |
| L-06 | Lua sub-folder tests point at flat structure | integration/stress/validation all load relative to `tests/lua/` | Update `run_lua_test()` path prefix after move |
| L-07 | `test_math_golden.lua` is orphaned | `tests/lua/golden/` | Register in harness |
| L-08 | Flat top-level Lua unit tests | 30 files | Move to `tests/lua/unit/` |
| G-01 | Golden expected files are flat | `tests/golden/expected/` (13 files) | Add `image/`, `hash/`, `encode/`, `compress/`, `data/`, `audio/` sub-folders |
| G-02 | No audio golden files | — | Add `audio/` sub-folder with deterministic WAV reference |
| G-03 | No font golden files | — | Add `font/` sub-folder with glyph bitmap reference |

---

## 10. Priority Order for Implementation

Ordered by impact:

1. **[High] Fix Lua framework inconsistencies** (L-01, L-02, L-03) — unregistered tests mean coverage is silently missing. 6 files currently produce no test results.
2. **[High] Register missing Lua tests** (L-04) — 10 test files are invisible to the CI runner.
3. **[Medium] Move Rust tests to sub-folders** (R-01) — structural clarity; requires Cargo.toml changes.
4. **[Medium] Add `//!` headers to 12 Rust files** (R-04) — doc coverage compliance.
5. **[Medium] Standardise section separators** (R-03) — readability.
6. **[Low] Rename `test_` prefixed functions** (R-02) — cosmetic only.
7. **[Low] Move harness files** (R-05) — structural clarity; requires Cargo.toml path changes.
8. **[Low] Golden sub-folders** (G-01) — requires updating path strings in `harness.rs`.
9. **[Low] Add missing golden categories** (G-02, G-03) — new coverage.
