# Hardcoded Elements Review — Configurability Audit

**Date**: 2026-04-09 (revised 2026-04-10: scope expanded to full codebase)
**Scope**: All `src/**/*.rs` — every Lurek2D engine module
**Reviewer context**: Raised by user concern that engine systems must remain fully configurable — no fixed object counts, no undeclared orientation limitations, no magic numbers baked into core data structures. Review was initially scoped to `src/tilemap/` only; this document supersedes that with a codebase-wide audit.

---

## Summary

A full codebase sweep of `src/**/*.rs` identified **3 BLOCKER**, **4 WARNING**, and **7 NOTE** findings, spread across the `tilemap`, `audio`, `engine`, `graphics`, `ai`, `automation`, and `terminal` modules. Every other Lurek2D module was inspected and found to be correctly parameterised. The `tilemap` module contains the highest concentration of issues. The most critical finding outside tilemap is the MIDI renderer, which hard-wires its entire output to stereo 44100 Hz.

---

## Findings

### BLOCKER-01 — `IsoTile::parts` is a fixed-size array of 4

**Module:** `tilemap`
**File:** `src/tilemap/isomap.rs`
**Lines:** 74, 323, 346, 364, 491

```rust
// line 74
pub parts: [u32; 4],

// line 491 — draw loop
for part in 0u32..4 { ... }

// lines 323, 346, 364 — bounds checks
if part >= 4 { return; }
```

**Problem:** Every isometric map cell is permanently limited to four GID sub-slots. The number `4` and slot semantics (`Floor`, `NorthWall`, `WestWall`, `Object`) are baked into the struct layout, the draw loop, and all three mutating/reading methods. A game needing a fifth slot (ceiling layer, decal layer, unit overlay) cannot add one without forking the engine type.

**What should happen:** `part_count` becomes a constructor parameter of `IsoMap`. `IsoTile::parts` becomes `Vec<u32>` pre-sized to `part_count`. All literal `4` guards and loop bounds reference `self.part_count`. `newIsoMap` in the Lua API accepts an optional `partCount: integer` (default `4`).

**Remediation:** Route to `Developer`. Change `IsoTile::parts` from `[u32; 4]` to `Vec<u32>` populated at construction; replace all literal `4` guards with `self.part_count`; add `partCount` parameter to `lurek.tilemap.newIsoMap`.

---

### BLOCKER-02 — `IsoTilePart` enum names are hardcoded semantics

**Module:** `tilemap`
**File:** `src/tilemap/isomap.rs`
**Lines:** 22–31, 40–55

```rust
pub enum IsoTilePart {
    Floor = 0,
    NorthWall = 1,
    WestWall = 2,
    Object = 3,
}
```

**Problem:** The four slot names replicate OpenXcom's fixed ISO layout. A game using pure top-down, hexagonal, or any non-OpenXcom ISO style has different semantic meaning for its slots. The enum is currently a minor coupling (Lua exposes slots as 0-based integers), but the module doc comment hard-embeds a single game domain into the engine.

**What should happen:** `IsoTilePart` remains as a named convenience enum but must not be the sole rendering model. Draw order should come from a `part_order: Vec<u32>` on `IsoMap`.

**Remediation:** Route to `Lua-Designer` + `Developer`. Add optional draw-order configuration; make the enum a non-exhaustive helper, not the draw engine.

---

### BLOCKER-03 — `MidiPlayer` output format is hardcoded to stereo 44100 Hz

**Module:** `audio`
**File:** `src/audio/midi_player.rs`
**Line:** 195

```rust
let buffer = rodio::buffer::SamplesBuffer::new(2, 44100, pcm);
```

**Problem:** The MIDI renderer unconditionally produces stereo 44100 Hz output. `MidiPlayer` has no `sample_rate` or `channels` field. The module doc on line 523 explicitly states "stereo 16-bit PCM buffer at 44100 Hz" — meaning this is a known fixed decision, not an accident. A game targeting 48000 Hz (common on modern audio hardware), mono output, or any other rate cannot override this without recompiling the engine. All other `SoundData` paths in the audio module query `sample_rate()` from the decoded source rather than hardcoding.

**What should happen:** Add `sample_rate: u32` and `channels: u16` fields to `MidiPlayer`, populated at construction or via setters, and pass them to `SamplesBuffer::new`. Expose `setSampleRate` / `setChannels` in the Lua `MidiPlayer` API.

**Remediation:** Route to `Developer`. Add fields and constructor defaults (44100 Hz stereo for backward compat); update `SamplesBuffer::new(2, 44100, pcm)` to use these fields.

---

### WARNING-01 — `MapOrientation` is incomplete for orientations the engine already supports

**Module:** `tilemap`
**File:** `src/tilemap/mapgen.rs`
**Lines:** 693–700

```rust
pub enum MapOrientation {
    TopDown,
    SideView,
}
```

**Problem:** `src/tilemap/coords.rs` implements full isometric and hexagonal coordinate transforms (`to_screen_iso`, `from_screen_iso`, `to_screen_hex`, `from_screen_hex`, hex neighbours, distance, rings, spirals, rotation, reflection). The `IsoMap` type exists for ISO rendering. Yet `MapOrientation` — used by `TileMap` and `MapGen` — contains only `TopDown` and `SideView`. `TmxOrientation` in `src/tilemap/tmx.rs` already enumerates `Orthogonal`, `Isometric`, `Staggered`, `Hexagonal`; `MapOrientation` should align with it.

**What should happen:** Add `Isometric` and `Hexagonal` to `MapOrientation`. Update `TileMap::get_orientation` / `set_orientation`, the Lua bridge `getOrientation` / `setOrientation`, and docs.

**Remediation:** Route to `Developer`. Extend enum; update Lua bridge match arms; regression test in `tests/lua/unit/test_tilemap.lua` round-tripping all four orientation strings.

---

### WARNING-02 — Lua `addStep` exposes 3 of 8 domain step types

**Module:** `tilemap`
**File:** `src/lua_api/tilemap_api.rs` — `LuaMapScript::add_methods`
**File:** `src/tilemap/mapgen.rs` — `StepType` enum

```rust
// Domain (8 variants):
pub enum StepType { FillRandom, PlaceBlock, PlaceRandom, PlaceLine,
                    FloodFill, FillArea, DrawPath, FillRect }

// Lua bridge (3 variants only):
"fillRandom" => StepType::FillRandom,
"placeBlock" => StepType::PlaceBlock,
"fillArea"   => StepType::FillArea,
// PlaceRandom, PlaceLine, FloodFill, DrawPath, FillRect — unreachable from Lua
```

**Problem:** Five step types with existing Rust implementations are silently unreachable from scripts. Callers that pass `type = "drawPath"` receive a runtime error `"unknown step type"`.

**What should happen:** Extend the `addStep` match arm to cover all 8 types; expose per-step fields (direction, path width, etc.) from `ScriptStep` via the table parameter.

**Remediation:** Route to `Developer`. Extend match arm; expose additional step fields; update `docs/specs/tilemap.md` and `content/examples/tilemap.lua`.

---

### WARNING-03 — Physics spiral-of-death cap is a local magic literal

**Module:** `engine`
**File:** `src/engine/app.rs`
**Line:** 836

```rust
let max_steps = 8;
```

**Problem:** The variable that caps how many physics sub-steps can run per frame (preventing the "spiral of death" under frame-rate drops) is a local literal. It is not a field in `SharedState`, not in `Config`, and not reachable from Lua. Games that need different cap behaviour (physics-heavy simulations may need 12–16 sub-steps; lightweight games may want 2–4) cannot change this without recompiling.

**What should happen:** Add `physics_max_steps: u32` to `SharedState` (default `8`). Expose `lurek.timer.setPhysicsMaxSteps(n)` and `lurek.timer.getPhysicsMaxSteps()` alongside the existing `setPhysicsRate`/`getPhysicsRate`.

**Remediation:** Route to `Developer`. Promote `max_steps` to a `SharedState` field; add Lua bindings in `timer_api.rs`.

---

### WARNING-04 — `newSoundData` sample-rate falls through silently to 44100

**Module:** `audio`
**File:** `src/lua_api/audio_api.rs`
**Line:** 99

```rust
let rate = match it.next() {
    Some(LuaValue::Integer(n)) => n as u32,
    Some(LuaValue::Number(n)) => n as u32,
    _ => 44100,       // silent fallthrough
};
```

**Problem:** If the caller passes anything other than an integer or float as the `rate` argument (e.g. `newSoundData(count, "auto")` or passes a boolean by mistake), the API silently defaults to 44100 Hz instead of returning an error. This creates a silent failure mode that is hard to diagnose.

**What should happen:** The `_` arm should return a `LuaError::RuntimeError` describing the invalid sample-rate type, consistent with how the rest of the audio API validates inputs.

**Remediation:** Route to `Developer`. Replace the `_ => 44100` arm with an explicit error; update the `newSoundData` doc comment to clarify the accepted types.

---

### NOTE-01 — `LargeMapRenderer` default viewport is 800×600

**Module:** `tilemap`
**File:** `src/tilemap/large_map_renderer.rs`
**Lines:** 113–114

```rust
viewport_w: 800.0,
viewport_h: 600.0,
```

**Problem:** The default frustum for chunk culling is a 4:3 SD resolution assumption. Any game that forgets to call `setViewport` before rendering will get incorrect culling at any other resolution.

**Remediation:** Route to `Developer`. Change to `0.0 × 0.0`; treat `0 × 0` as "no culling" in `get_visible_chunks`.

---

### NOTE-02 — `IsoDrawItem::part` doc comment embeds 4-slot assumption

**Module:** `tilemap`
**File:** `src/tilemap/isomap.rs`

```rust
/// Part index (0 = Floor … 3 = Object).
```

**Remediation:** Update as part of BLOCKER-01 fix to `"Part slot index (0-based; meaning is defined by the IsoMap part schema)"`.

---

### NOTE-03 — GPU vertex buffer sizes are compile-time constants

**Module:** `graphics`
**File:** `src/graphics/gpu_renderer.rs`
**Lines:** 98–101

```rust
const MAX_COLOR_VERTS: u64 = 1 << 17; // 131 072 vertices
const MAX_COLOR_IDXS:  u64 = 1 << 19; // 524 288 indices
const MAX_TEX_VERTS:   u64 = 1 << 14; //  16 384 vertices
const MAX_TEX_IDXS:    u64 = 1 << 16; //  65 536 indices
```

**Problem:** These four constants govern how much GPU VRAM is pre-allocated at engine startup. A game with many geometric primitives per frame, or many sprites in a single `render()` call, will silently overflow these buffers with no user-visible diagnostic. The values are powers of two and are not documented anywhere in the Lua API, so scripts have no way to know they exist.

**What should happen:** Either expose these as optional `conf.lua` settings (`graphics.max_color_verts`, etc.) so game authors can tune at build time, or at minimum add `log::warn!` messages when the renderer detects approaching saturation so authors discover the ceiling before shipping.

**Remediation:** Route to `Doc-Writer` (document the limits in `docs/specs/graphics.md`). Route to `Developer` for the warn-on-saturation diagnostic. Configuration in `conf.lua` is a MINOR feature request, not blocking.

---

### NOTE-04 — `Terminal` grid dimensions are compile-time ceilings

**Module:** `terminal`
**File:** `src/terminal/terminal_state.rs` (or equivalent)
**Constants:** `MAX_COLS = 512`, `MAX_ROWS = 256`

**Problem:** The maximum terminal grid size is fixed. A `Terminal` cannot be constructed to exceed these dimensions regardless of the host window resolution. Unusually wide terminals (80-column modes, 200-column debug consoles) and very tall terminals are capped without diagnostic.

**What should happen:** Either make these module-level constants configurable via `conf.lua` or promote them to per-instance construction parameters with sane defaults.

**Remediation:** Route to `Developer`. Evaluate whether the cap can become per-instance or conf.lua-configurable; at minimum document in `docs/specs/terminal.md`.

---

### NOTE-05 — Automation `MAX_STEPS` is not Lua-configurable

**Module:** `automation`
**File:** `src/automation/script.rs`
**Line:** 20

```rust
pub(crate) const MAX_STEPS: usize = 100_000;
```

**Problem:** The step cap that prevents runaway automation scripts is a non-configurable Rust constant. Legitimate long-running procedurally driven scripts (e.g. a world generator running 500k tile placement operations) hit this ceiling invisibly. The value cannot be raised from a script without recompiling the engine.

**What should happen:** Expose as an optional `lurek.automation.setStepLimit(n)` (or engine config), still subject to a hard upper bound to prevent DoS.

**Remediation:** Route to `Developer`. Add an optional Lua setter with a hard compile-time ceiling (e.g. `10_000_000`); document in `docs/specs/automation.md`.

---

### NOTE-06 — Font glyph atlas ceiling is 2048×2048

**Module:** `graphics`
**File:** `src/graphics/font.rs`
**Lines:** 18, 20

```rust
const INITIAL_ATLAS_SIZE: u32 = 512;
const MAX_ATLAS_SIZE: u32 = 2048;
```

**Problem:** The atlas starts at 512×512 and doubles via `grow_atlas()` up to `MAX_ATLAS_SIZE = 2048`. Games using large Unicode character sets (CJK, emoji, full Latin extended) will exhaust glyph space with no way to raise the ceiling.
**Context:** The growing behaviour is correctly implemented — this is only the hard upper wall.

**What should happen:** Expose `MAX_ATLAS_SIZE` as an optional `conf.lua` setting (`graphics.font_atlas_max_size`).

**Remediation:** Route to `Developer`. Read from `Config` at `FontCache` construction rather than the compile-time constant.

---

### NOTE-07 — GOAP planner A★ iteration limit is a non-configurable local

**Module:** `ai`
**File:** `src/ai/goap.rs`
**Line:** 225

```rust
let max_iterations = 10_000;
```

**Problem:** The GOAP A★ safety cap is a local variable — it is not a field on `GOAPPlanner` and not Lua-settable. Games with large action sets or complex goal conditions where 10,000 iterations is insufficient have no recourse (the planner silently returns an empty plan).

**What should happen:** Promote to a `GOAPPlanner` field (`max_iterations: usize`, default `10_000`), exposed via `lurek.ai.goap.setMaxIterations(n)`.

**Remediation:** Route to `Developer`. Add field; update Lua binding; document in `docs/specs/ai.md`.

---

## Non-Issues Confirmed

The following were inspected across all modules and found to be correctly configurable or architecturally correct:

| Module | Item | Status |
|---|---|---|
| `tilemap` | `TileMap` layer count | Dynamic — `add_layer()` grows `Vec<TileLayer>` |
| `tilemap` | `MapBlock` layer count | Configurable — `layers: u32` constructor param |
| `tilemap` | `MapBlock` segment size | Configurable — `segment_size: u32` constructor param |
| `tilemap` | Tile dimensions | Configurable — `tile_width`, `tile_height` constructor params |
| `tilemap` | Chunk size | Configurable — `chunk_size` param (default 16, documented) |
| `tilemap` | `IsoMap` Z-level count | Dynamic — `add_level()` grows `Vec<IsoLevel>` |
| `tilemap` | `MapGroup` block count | Dynamic — `Vec<MapBlock>` |
| `tilemap` | Hex coordinate math | Fully parameter-driven — no hardcoded grid |
| `tilemap` | `MapSize` | Custom variant exists — `MapSize::Custom(w, h)` |
| `tilemap` | `AutoTileLayout` | Three named variants; extensible without API breakage |
| `tilemap` | `for raw in 0u16..256` in autotile | Iterates all 8-bit bitmask combinations — correct by definition |
| `input` | `[bool; 5]` mouse button array | Exactly 5 HID standard buttons — correct |
| `engine` | `[bool; 3]` prev_mouse in app_winit | 3 internal winit physical buttons — correct |
| `graphics` | `[Patch; 9]` in nine_slice | A 9-slice always produces exactly 9 patches — definitionally correct |
| `graphics` | `SpriteSheet::direction_count` | Takes any `u32` — fully configurable |
| `particle` | `max_particles: 256` default | Configurable via `setMaxParticles` Lua API |
| `physics` | `physics_fixed_dt: 1.0/60.0` | Exposed via `lurek.timer.setPhysicsRate` / `getPhysicsRate` |
| `network` | `MAX_PEERS=8`, `DEFAULT_PEERS=4` | Documented, Lua-configurable within ceiling |
| `entity` | `MAX_BITMAP_TAGS=63` | Tied to u64 bitmask — 63 is the mathematical ceiling |
| `light` | `max_lights: 64` default | Configurable via `lurek.light.setMaxLights(n)` (1–256) |
| `pathfinding` | `thread_count` | Configurable at construction and via `setThreadCount` at runtime |
| `raycaster` | DDA all limits (fov, ray_count, max_dist) | Caller-provided — no hardcoded ceiling |
| `procgen` | Width, height, room counts | All algorithms accept caller-provided dimensions |
| `ai` | GOAP `max_depth` | Caller-provided to `plan(max_depth)` |
| `savegame` | `for _ in 0..35` | Test-only data builder — not production code |
| `raycaster` | `for y in 0..8` / `for x in 0..8` | Test-only 8×8 grid iteration — not production code |
| `graphics` | Font atlas grows dynamically | `grow_atlas()` doubles until `MAX_ATLAS_SIZE` — growing mechanism is correct; only ceiling is an issue (see NOTE-06) |
| `engine` | `game_width/height: 800/600` in SharedState | Backed by `conf.lua` → `Config` load path — configurable |
| `engine` | `Config` window default 800×600 | Overridden by every `conf.lua` |
| `filesystem` | `QUEUE_CAPACITY: 64` async queue | Internal async loader backpressure — not user-visible |
| `math` | `for i in 0..3` / `for j in 0..3` in Mat3 | 3×3 matrix math — definitionally correct |

---

## Priority Order

| Priority | ID | Module | Finding | Route |
|---|---|---|---|---|
| 1 | BLOCKER-01 | `tilemap` | `IsoTile::parts: [u32; 4]` — fixed part count | `Developer` |
| 2 | BLOCKER-02 | `tilemap` | `IsoTilePart` fixed slot semantics | `Lua-Designer` + `Developer` |
| 3 | BLOCKER-03 | `audio` | MIDI hardcoded stereo 44100 Hz | `Developer` |
| 4 | WARNING-01 | `tilemap` | `MapOrientation` missing Isometric / Hexagonal | `Developer` |
| 5 | WARNING-02 | `tilemap` | `addStep` Lua gap (5 step types unreachable) | `Developer` |
| 6 | WARNING-03 | `engine` | Physics `max_steps = 8` local literal | `Developer` |
| 7 | WARNING-04 | `audio` | `newSoundData` silent 44100 fallthrough | `Developer` |
| 8 | NOTE-03 | `graphics` | GPU vertex buffer compile-time ceilings | `Developer` (warn) + `Doc-Writer` |
| 9 | NOTE-04 | `terminal` | `MAX_COLS=512`, `MAX_ROWS=256` fixed ceilings | `Developer` |
| 10 | NOTE-05 | `automation` | `MAX_STEPS=100_000` not Lua-configurable | `Developer` |
| 11 | NOTE-06 | `graphics` | Font atlas capped at 2048×2048 | `Developer` |
| 12 | NOTE-07 | `ai` | GOAP `max_iterations` not a planner field | `Developer` |
| 13 | NOTE-01 | `tilemap` | `LargeMapRenderer` 800×600 viewport default | `Developer` |
| 14 | NOTE-02 | `tilemap` | `IsoDrawItem::part` doc comment | `Developer` (part of BLOCKER-01) |

---

## Handover Notes

- **BLOCKER-01 + BLOCKER-02** should be one PR — they share `IsoTile` and the draw contract.
- **WARNING-01** is independent — small enum extension + Lua bridge update.
- **WARNING-02** is a pure Lua bridge PR — no domain Rust changes.
- **WARNING-03 + WARNING-04** can be batched into a single "engine config gaps" PR.
- **BLOCKER-03** is self-contained in `src/audio/midi_player.rs`.
- **NOTE-01 + NOTE-02** fold into the BLOCKER-01 PR.
- **NOTE-03 through NOTE-07** are all informed improvement; none are blocking merge of other work.

---

## Implementation Plan

This section provides a file-by-file, before/after implementation guide for every finding. **No production source files are changed by this document** — it is a reference for the Developer agent.

### Conventions

- **BEFORE** — exact current code verified against source at audit date 2026-04-10
- **AFTER** — the code as it must appear after the fix
- Line numbers are best-effort; the file may shift before implementation begins
- Every PR must also update `docs/CHANGELOG.md`
- Run `cargo test && cargo clippy -- -D warnings` after each PR before merge

---

### PR-1 — BLOCKER-01 + BLOCKER-02 + NOTE-02: Dynamic `IsoTile` part count and part order

**Files touched:**
- `src/tilemap/isomap.rs` — struct layout, constructor, three guards, draw loop, doc comment
- `src/lua_api/tilemap_api.rs` — `newIsoMap` optional `partCount`, new `setPartOrder` / `getPartOrder`

#### Change 1 — `IsoTile` struct and default (`isomap.rs` ~line 70)

```rust
// BEFORE
pub struct IsoTile {
    /// `parts[0]` = Floor, `parts[1]` = NorthWall, `parts[2]` = WestWall, `parts[3]` = Object.
    pub parts: [u32; 4],
}
```
```rust
// AFTER
pub struct IsoTile {
    /// One GID entry per part slot. Length equals the owning `IsoMap::part_count`.
    pub parts: Vec<u32>,
}
// Remove any `#[derive(Default)]` on IsoTile.
// All construction goes through IsoLevel tile allocation; never call IsoTile::default().
```

#### Change 2 — `IsoMap` struct — add `part_count` and `part_order` fields

Find the `IsoMap` struct definition (contains `width`, `height`, `tile_w`, `tile_h`, `level_height`, `origin_x`, `origin_y`, `levels`) and add two fields:

```rust
// BEFORE
pub struct IsoMap {
    pub width: u32,
    pub height: u32,
    pub tile_w: u32,
    pub tile_h: u32,
    pub level_height: u32,
    pub origin_x: f32,
    pub origin_y: f32,
    levels: Vec<IsoLevel>,
}
```
```rust
// AFTER
pub struct IsoMap {
    pub width: u32,
    pub height: u32,
    pub tile_w: u32,
    pub tile_h: u32,
    pub level_height: u32,
    pub origin_x: f32,
    pub origin_y: f32,
    /// Number of part slots per tile cell. Minimum 1. Default 4 (Floor/NorthWall/WestWall/Object).
    pub part_count: u32,
    /// Draw order for parts. `part_order[i]` is the part slot index rendered at step `i`.
    /// Defaults to `[0, 1, 2, …, part_count-1]` (ascending order).
    pub part_order: Vec<u32>,
    levels: Vec<IsoLevel>,
}
```

#### Change 3 — `IsoMap::new()` constructor (~line 271)

```rust
// BEFORE
pub fn new(width: u32, height: u32, tile_w: u32, tile_h: u32, level_height: u32) -> Self {
    Self {
        width, height, tile_w, tile_h, level_height,
        origin_x: 0.0, origin_y: 0.0, levels: Vec::new()
    }
}
```
```rust
// AFTER
pub fn new(
    width: u32,
    height: u32,
    tile_w: u32,
    tile_h: u32,
    level_height: u32,
    part_count: u32,
) -> Self {
    let part_count = part_count.max(1);
    let part_order = (0..part_count).collect();
    Self {
        width,
        height,
        tile_w,
        tile_h,
        level_height,
        origin_x: 0.0,
        origin_y: 0.0,
        part_count,
        part_order,
        levels: Vec::new(),
    }
}
```

#### Change 4 — Tile allocation in `add_level`

Find the `add_level()` body where it pushes a new `IsoLevel` with `vec![IsoTile::default(); …]`:

```rust
// BEFORE (approximate)
self.levels.push(IsoLevel {
    tiles: vec![IsoTile::default(); (self.width * self.height) as usize],
    visible: true,
});
```
```rust
// AFTER
let part_count = self.part_count as usize;
self.levels.push(IsoLevel {
    tiles: (0..(self.width * self.height) as usize)
        .map(|_| IsoTile { parts: vec![0u32; part_count] })
        .collect(),
    visible: true,
});
```

#### Change 5 — `set_tile_part` guard (~line 323)

```rust
// BEFORE
if part >= 4 {
    return;
}
```
```rust
// AFTER
if part >= self.part_count {
    return;
}
```

#### Change 6 — `get_tile_part` guard (~line 346)

```rust
// BEFORE
if part >= 4 {
    return 0;
}
```
```rust
// AFTER
if part >= self.part_count {
    return 0;
}
```

#### Change 7 — `fill_level` guard (~line 364)

```rust
// BEFORE
if part >= 4 {
    return;
}
```
```rust
// AFTER
if part >= self.part_count {
    return;
}
```

#### Change 8 — `draw_iter` capacity and loop (~line 460 area)

```rust
// BEFORE
// Estimate capacity: W * H * (max_z+1) * 4 parts
let mut items = Vec::with_capacity(w * h * (max_z + 1) * 4);
// ... (later inside the tile loop)
for part in 0u32..4 {
    items.push(IsoDrawItem {
        level: z as u32,
        tile_x: tx as u32,
        tile_y: ty as u32,
        part,
        gid: tile.parts[part as usize],
        screen_x: sx,
        screen_y: sy,
    });
}
```
```rust
// AFTER
let pc = self.part_count as usize;
// Estimate capacity: W * H * (max_z+1) * part_count
let mut items = Vec::with_capacity(w * h * (max_z + 1) * pc);
// ... (later inside the tile loop)
for &part in &self.part_order {
    let gid = tile.parts.get(part as usize).copied().unwrap_or(0);
    items.push(IsoDrawItem {
        level: z as u32,
        tile_x: tx as u32,
        tile_y: ty as u32,
        part,
        gid,
        screen_x: sx,
        screen_y: sy,
    });
}
```

#### Change 9 — NOTE-02: `IsoDrawItem::part` doc comment

```rust
// BEFORE
/// Part index (0 = Floor … 3 = Object).
pub part: u32,
```
```rust
// AFTER
/// Part slot index (0-based). Meaning is defined by the owning IsoMap's part schema.
/// The default 4-part schema uses: 0 = Floor, 1 = NorthWall, 2 = WestWall, 3 = Object.
pub part: u32,
```

#### Change 10 — BLOCKER-02: Mark `IsoTilePart` non-exhaustive

```rust
// BEFORE
pub enum IsoTilePart {
    Floor = 0,
    NorthWall = 1,
    WestWall = 2,
    Object = 3,
}
```
```rust
// AFTER
/// Named convenience constants for the default 4-part isometric layout.
///
/// These names describe the *default* part semantics. Games configured with a
/// different `part_count` or `part_order` may assign any meaning to their slots.
/// Do not rely on this enum being exhaustive across engine versions.
#[non_exhaustive]
pub enum IsoTilePart {
    Floor = 0,
    NorthWall = 1,
    WestWall = 2,
    Object = 3,
}
```

#### Change 11 — Lua API: `newIsoMap` optional `partCount` (`tilemap_api.rs`)

Find the `newIsoMap` closure registration and add the optional sixth parameter:

```rust
// BEFORE (approximate)
tbl.set(
    "newIsoMap",
    lua.create_function(move |_, (w, h, tw, th, lh): (u32, u32, u32, u32, u32)| {
        Ok(LuaIsoMap { inner: Rc::new(RefCell::new(IsoMap::new(w, h, tw, th, lh))) })
    })?,
)?;
```
```rust
// AFTER
/// Creates a new IsoMap.
/// @param w : integer
/// @param h : integer
/// @param tileW : integer
/// @param tileH : integer
/// @param levelHeight : integer
/// @param partCount : integer?   (default 4)
/// @return IsoMap
let s = state.clone();
tbl.set(
    "newIsoMap",
    lua.create_function(move |_, (w, h, tw, th, lh, pc): (u32, u32, u32, u32, u32, Option<u32>)| {
        let part_count = pc.unwrap_or(4).max(1);
        Ok(LuaIsoMap {
            inner: Rc::new(RefCell::new(IsoMap::new(w, h, tw, th, lh, part_count))),
        })
    })?,
)?;
```

#### Change 12 — Lua API: `setPartOrder` / `getPartOrder` on `LuaIsoMap`

Add to `LuaIsoMap::add_methods` in `tilemap_api.rs`:

```rust
// AFTER (new methods — add inside impl LuaUserData for LuaIsoMap)

// -- getPartOrder --
/// Returns the current draw-order array (0-based part slot indices).
/// @return table
methods.add_method("getPartOrder", |_, this, ()| {
    Ok(this.inner.borrow().part_order.clone())
});

// -- setPartOrder --
/// Overrides the draw order for this IsoMap. Length must equal partCount.
/// Each value is a 0-based part slot index.
/// @param order : table
/// @return nil
methods.add_method_mut("setPartOrder", |_, this, order: Vec<u32>| {
    let mut map = this.inner.borrow_mut();
    if order.len() != map.part_count as usize {
        return Err(LuaError::RuntimeError(format!(
            "setPartOrder: expected {} values, got {}",
            map.part_count,
            order.len()
        )));
    }
    if order.iter().any(|&i| i >= map.part_count) {
        return Err(LuaError::RuntimeError(
            "setPartOrder: part index out of range".to_string(),
        ));
    }
    map.part_order = order;
    Ok(())
});
```

#### Tests to add

**`tests/lua/unit/test_tilemap.lua`:**
- `it("newIsoMap default 4 parts sets and gets GIDs across all four slots")`
- `it("newIsoMap with partCount=6 accepts 6 GIDs per tile")`
- `it("newIsoMap partCount=6 rejects part index 6 with error")`
- `it("setPartOrder reorders draw_iter output")`
- `it("setPartOrder rejects wrong-length table")`
- `it("setPartOrder rejects out-of-range index")`

**`tests/rust/unit/tilemap_tests.rs`** (or new `tests/rust/unit/isomap_tests.rs`):
- `isomap_custom_part_count_round_trip_all_slots`
- `isomap_draw_iter_visits_all_custom_parts`
- `isomap_set_tile_part_oob_guard_uses_part_count`
- `isomap_part_order_reversal_changes_draw_sequence`

**Done when:** `cargo test --test tilemap_tests` passes; new Lua tests pass; `IsoMap::new` requires explicit `part_count`; all literal `4` guards and loops are gone from `isomap.rs`.

---

### PR-2 — WARNING-01: Extend `MapOrientation` to include `Isometric` and `Hexagonal`

**Files touched:**
- `src/tilemap/mapgen.rs` — extend enum
- `src/lua_api/tilemap_api.rs` — update `getOrientation` / `setOrientation` match arms
- `docs/specs/tilemap.md` — update orientation table
- `content/examples/tilemap.lua` — add orientation round-trip example

#### Change 1 — `MapOrientation` enum (`mapgen.rs` ~line 693)

```rust
// BEFORE
pub enum MapOrientation {
    /// Standard top-down orthogonal.
    TopDown,
    /// Side-scrolling view.
    SideView,
}
```
```rust
// AFTER
pub enum MapOrientation {
    /// Standard top-down orthogonal view.
    TopDown,
    /// Side-scrolling (platformer-style) view.
    SideView,
    /// Isometric diamond projection.
    Isometric,
    /// Hexagonal grid (flat-top or pointy-top depending on tile dimensions).
    Hexagonal,
}
```

#### Change 2 — Lua bridge match arms (`tilemap_api.rs`)

Find `getOrientation` and `setOrientation` registrations (search for the string `"topDown"`):

```rust
// BEFORE — getOrientation arm
MapOrientation::TopDown  => "topDown",
MapOrientation::SideView => "sideView",

// BEFORE — setOrientation arm
"topDown"  => MapOrientation::TopDown,
"sideView" => MapOrientation::SideView,
other => return Err(LuaError::RuntimeError(format!(
    "setOrientation: unknown orientation '{}'", other
))),
```
```rust
// AFTER — getOrientation arm
MapOrientation::TopDown   => "topDown",
MapOrientation::SideView  => "sideView",
MapOrientation::Isometric => "isometric",
MapOrientation::Hexagonal => "hexagonal",

// AFTER — setOrientation arm
"topDown"    => MapOrientation::TopDown,
"sideView"   => MapOrientation::SideView,
"isometric"  => MapOrientation::Isometric,
"hexagonal"  => MapOrientation::Hexagonal,
other => return Err(LuaError::RuntimeError(format!(
    "setOrientation: unknown '{}' (valid: topDown, sideView, isometric, hexagonal)", other
))),
```

#### Tests to add

**`tests/lua/unit/test_tilemap.lua`:**
- `it("setOrientation/getOrientation round-trips topDown")`
- `it("setOrientation/getOrientation round-trips sideView")`
- `it("setOrientation/getOrientation round-trips isometric")`
- `it("setOrientation/getOrientation round-trips hexagonal")`
- `it("setOrientation rejects unknown string with descriptive error")`

**Done when:** All four orientation strings accepted; unknown string returns a `LuaError`; Lua tests pass.

---

### PR-3 — WARNING-02: `addStep` exposes all 8 domain step types

**Files touched:**
- `src/lua_api/tilemap_api.rs` — extend match arm and field parsing in `addStep`
- `docs/specs/tilemap.md` — update `addStep` parameter table
- `content/examples/tilemap.lua` — demonstrate at least one of the previously missing types

#### Change 1 — `addStep` match arm (`tilemap_api.rs` ~lines 1362–1368)

```rust
// BEFORE
let st = match step_type_str.as_str() {
    "fillRandom" => StepType::FillRandom,
    "placeBlock" => StepType::PlaceBlock,
    "fillArea"   => StepType::FillArea,
    other => {
        return Err(LuaError::RuntimeError(format!(
            "addStep: unknown step type '{}'",
            other
        )))
    }
};
```
```rust
// AFTER
let st = match step_type_str.as_str() {
    "fillRandom"  => StepType::FillRandom,
    "placeBlock"  => StepType::PlaceBlock,
    "placeRandom" => StepType::PlaceRandom,
    "placeLine"   => StepType::PlaceLine,
    "floodFill"   => StepType::FloodFill,
    "fillArea"    => StepType::FillArea,
    "drawPath"    => StepType::DrawPath,
    "fillRect"    => StepType::FillRect,
    other => {
        return Err(LuaError::RuntimeError(format!(
            "addStep: unknown step type '{}' \
             (valid: fillRandom, placeBlock, placeRandom, placeLine, \
              floodFill, fillArea, drawPath, fillRect)",
            other
        )))
    }
};
```

#### Change 2 — Expose additional `ScriptStep` fields in table parsing

The current table parser in `addStep` only reads `x`, `y`, `w`, `h`, `gid`, `chance`. Add a `get_i32_field` helper and read additional fields that the newly exposed step types require:

```rust
// BEFORE — step construction block
let step = ScriptStep {
    step_type: st,
    x: get_u32_field(&step_def, "x"),
    y: get_u32_field(&step_def, "y"),
    width: get_u32_field(&step_def, "w"),
    height: get_u32_field(&step_def, "h"),
    tile_id: get_u32_field(&step_def, "gid"),
    chance: get_f32_field(&step_def, "chance"),
    ..Default::default()
};
```
```rust
// AFTER — add helper + extended fields
let get_i32_field = |tbl: &LuaTable, key: &str, default: i32| -> i32 {
    match tbl.get::<_, LuaValue>(key) {
        Ok(LuaValue::Integer(n)) => n as i32,
        Ok(LuaValue::Number(n)) => n as i32,
        _ => default,
    }
};
let step = ScriptStep {
    step_type: st,
    x: get_u32_field(&step_def, "x"),
    y: get_u32_field(&step_def, "y"),
    width: get_u32_field(&step_def, "w"),
    height: get_u32_field(&step_def, "h"),
    tile_id: get_u32_field(&step_def, "gid"),
    chance: get_f32_field(&step_def, "chance"),
    direction: get_u32_field(&step_def, "direction"),
    path_width: get_u32_field(&step_def, "pathWidth"),
    repeat_count: get_u32_field(&step_def, "repeatCount"),
    group_index: get_i32_field(&step_def, "groupIndex", -1),
    block_index: get_i32_field(&step_def, "blockIndex", -1),
    ..Default::default()
};
```

#### Change 3 — Update `addStep` docstring

```rust
// BEFORE
/// Accepted type strings: "fillRandom", "placeBlock", "fillArea".
/// @param stepDef : table  {type, x?, y?, w?, h?, gid?, chance?}
```
```rust
// AFTER
/// Accepted type strings: "fillRandom", "placeBlock", "placeRandom", "placeLine",
/// "floodFill", "fillArea", "drawPath", "fillRect".
/// @param stepDef : table  {type, x?, y?, w?, h?, gid?, chance?, direction?, pathWidth?, repeatCount?, groupIndex?, blockIndex?}
```

#### Tests to add

**`tests/lua/unit/test_tilemap.lua`:**
- `it("addStep accepts placeRandom")`
- `it("addStep accepts placeLine")`
- `it("addStep accepts floodFill")`
- `it("addStep accepts drawPath")`
- `it("addStep accepts fillRect")`
- `it("addStep rejects unknown type with descriptive error listing valid types")`

**Done when:** All 8 step types accepted without error; unknown type returns descriptive `LuaError`; Lua tests pass.

---

### PR-4 — WARNING-03 + WARNING-04: Physics spiral cap + `newSoundData` guard

**Files touched:**
- `src/engine/shared_state.rs` — add `physics_max_steps: u32` field
- `src/engine/app.rs` — read `physics_max_steps` at line 836
- `src/lua_api/timer_api.rs` — add `getPhysicsMaxSteps` / `setPhysicsMaxSteps`
- `src/lua_api/audio_api.rs` — replace silent `_ => 44100` fallthrough with error
- `docs/specs/timer.md` — document new functions
- `docs/specs/audio.md` — document corrected `newSoundData` behaviour

#### WARNING-03, Change 1 — `SharedState` struct (`shared_state.rs` ~line 356)

```rust
// BEFORE
    /// Fixed time-step for `process_physics` callback, in seconds (default 1/60).
    pub physics_fixed_dt: f64,
}
```
```rust
// AFTER
    /// Fixed time-step for `process_physics` callback, in seconds (default 1/60).
    pub physics_fixed_dt: f64,
    /// Maximum physics sub-steps per frame (spiral-of-death cap). Default is 8.
    pub physics_max_steps: u32,
}
```

#### WARNING-03, Change 2 — `SharedState` initializer (~line 434)

```rust
// BEFORE
            physics_fixed_dt: 1.0 / 60.0,
```
```rust
// AFTER
            physics_fixed_dt: 1.0 / 60.0,
            physics_max_steps: 8,
```

#### WARNING-03, Change 3 — `app.rs` line 836

```rust
// BEFORE
            // Safety cap: max 8 physics steps per frame to avoid spiral of death.
            let max_steps = 8;
```
```rust
// AFTER
            // Safety cap: configurable max sub-steps per frame (spiral-of-death guard).
            let max_steps = state.borrow().physics_max_steps;
```

#### WARNING-03, Change 4 — `timer_api.rs` — two new bindings after `setPhysicsDelta`

Insert after the `setPhysicsDelta` block (around line 365):

```rust
// AFTER (insert these two blocks)

    // -- getPhysicsMaxSteps --
    /// Returns the maximum physics sub-steps allowed per frame (spiral-of-death cap).
    /// @return integer
    let s = state.clone();
    tbl.set(
        "getPhysicsMaxSteps",
        lua.create_function(move |_, ()| Ok(s.borrow().physics_max_steps))?,
    )?;

    // -- setPhysicsMaxSteps --
    /// Sets the maximum physics sub-steps per frame. Clamped to [1, 64].
    /// @param n : integer
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setPhysicsMaxSteps",
        lua.create_function(move |_, n: u32| {
            s.borrow_mut().physics_max_steps = n.clamp(1, 64);
            Ok(())
        })?,
    )?;
```

#### WARNING-04, Change 1 — `audio_api.rs` `parse_new_sound_data_args` (~lines 97–99)

```rust
// BEFORE
    let rate = match it.next() {
        Some(LuaValue::Integer(n)) => n as u32,
        Some(LuaValue::Number(n)) => n as u32,
        _ => 44100,
    };
```
```rust
// AFTER
    let rate = match it.next() {
        Some(LuaValue::Integer(n)) => n as u32,
        Some(LuaValue::Number(n)) => n as u32,
        None => 44100,
        Some(other) => {
            return Err(LuaError::RuntimeError(format!(
                "newSoundData: invalid sample rate type '{}', expected integer",
                other.type_name()
            )));
        }
    };
```

#### Tests to add

**`tests/lua/unit/test_timer.lua`:**
- `it("getPhysicsMaxSteps default is 8")`
- `it("setPhysicsMaxSteps clamps below 1 to 1")`
- `it("setPhysicsMaxSteps clamps above 64 to 64")`
- `it("setPhysicsMaxSteps round-trips value 12")`

**`tests/lua/unit/test_audio.lua`:**
- `it("newSoundData errors on non-integer sample rate argument")`

**Done when:** `getPhysicsMaxSteps()` returns 8 by default; clamp works; `newSoundData` with a boolean/string rate returns a `LuaError` with descriptive message.

---

### PR-5 — BLOCKER-03: `MidiPlayer` sample rate and channel count configurable

**Files touched:**
- `src/audio/midi_player.rs` — add `sample_rate: u32` and `channels: u16` fields; update `play()`; add getters/setters
- `src/lua_api/audio_api.rs` — expose `getSampleRate` / `setSampleRate` / `getChannels` / `setChannels` on `LuaMidiPlayer`

> ⚠️ **Pre-condition:** MIDI synthesis is currently disabled — the `midly` crate was removed from `Cargo.toml` and `render_to_pcm()` is a no-op stub. This PR adds the fields and plumbs the values through; it does not re-enable MIDI synthesis. Apply when MIDI re-enable is planned.

#### Change 1 — `MidiPlayer` struct (`midi_player.rs` ~line 78)

```rust
// BEFORE
pub struct MidiPlayer {
    midi_data: Option<MidiData>,
    raw_midi: Option<Vec<u8>>,
    file_path: Option<String>,
    volume: f32,
    looping: bool,
    tempo_scale: f32,
    current_bpm: f64,
    channel_muted: [bool; 16],
    channel_volume: [f32; 16],
    channel_instrument: [u8; 16],
    track_muted: Vec<bool>,
    position_secs: f64,
    sink: Option<rodio::Sink>,
    play_state: PlayState,
    bus_key: Option<BusKey>,
}
```
```rust
// AFTER
pub struct MidiPlayer {
    midi_data: Option<MidiData>,
    raw_midi: Option<Vec<u8>>,
    file_path: Option<String>,
    volume: f32,
    looping: bool,
    tempo_scale: f32,
    current_bpm: f64,
    channel_muted: [bool; 16],
    channel_volume: [f32; 16],
    channel_instrument: [u8; 16],
    track_muted: Vec<bool>,
    position_secs: f64,
    sink: Option<rodio::Sink>,
    play_state: PlayState,
    bus_key: Option<BusKey>,
    /// Output sample rate in Hz. Default 44100 for backward compatibility.
    sample_rate: u32,
    /// Output channel count (1 = mono, 2 = stereo). Default 2.
    channels: u16,
}
```

#### Change 2 — `MidiPlayer::new()` initializer

```rust
// BEFORE — end of the MidiPlayer { } block in new()
            sink: None,
            play_state: PlayState::Stopped,
            bus_key: None,
        }
```
```rust
// AFTER
            sink: None,
            play_state: PlayState::Stopped,
            bus_key: None,
            sample_rate: 44100,
            channels: 2,
        }
```

#### Change 3 — `play()` method — `SamplesBuffer::new` call

```rust
// BEFORE
        let buffer = rodio::buffer::SamplesBuffer::new(2, 44100, pcm);
```
```rust
// AFTER
        let buffer = rodio::buffer::SamplesBuffer::new(self.channels, self.sample_rate, pcm);
```

#### Change 4 — New domain methods on `impl MidiPlayer`

Add these four methods to the `impl MidiPlayer` block:

```rust
// AFTER (new methods)

    /// Returns the configured output sample rate in Hz.
    ///
    /// # Returns
    /// `u32`.
    pub fn get_sample_rate(&self) -> u32 {
        self.sample_rate
    }

    /// Sets the output sample rate for the next `play()` call. Clamped to [8000, 192000].
    ///
    /// # Parameters
    /// - `rate` — `u32`.
    pub fn set_sample_rate(&mut self, rate: u32) {
        self.sample_rate = rate.clamp(8_000, 192_000);
    }

    /// Returns the configured output channel count (1 = mono, 2 = stereo).
    ///
    /// # Returns
    /// `u16`.
    pub fn get_channels(&self) -> u16 {
        self.channels
    }

    /// Sets the output channel count for the next `play()` call (clamped to 1–2).
    ///
    /// # Parameters
    /// - `channels` — `u16`.
    pub fn set_channels(&mut self, channels: u16) {
        self.channels = channels.clamp(1, 2);
    }
```

#### Change 5 — Lua API: add 4 methods to `LuaMidiPlayer` in `audio_api.rs`

Add inside the `add_methods` block of `impl LuaUserData for LuaMidiPlayer`:

```rust
// AFTER (new methods)

        // -- getSampleRate --
        /// Returns the output sample rate in Hz (default 44100).
        /// @return integer
        methods.add_method("getSampleRate", |_, this, ()| {
            Ok(this.inner.borrow().get_sample_rate())
        });

        // -- setSampleRate --
        /// Sets the output sample rate for the next play() call. Clamped to [8000, 192000].
        /// @param rate : integer
        /// @return nil
        methods.add_method_mut("setSampleRate", |_, this, rate: u32| {
            this.inner.borrow_mut().set_sample_rate(rate);
            Ok(())
        });

        // -- getChannels --
        /// Returns the output channel count (1 = mono, 2 = stereo).
        /// @return integer
        methods.add_method("getChannels", |_, this, ()| {
            Ok(this.inner.borrow().get_channels() as u32)
        });

        // -- setChannels --
        /// Sets the output channel count for the next play() call (1 or 2).
        /// @param channels : integer
        /// @return nil
        methods.add_method_mut("setChannels", |_, this, channels: u16| {
            this.inner.borrow_mut().set_channels(channels);
            Ok(())
        });
```

#### Tests to add

**`tests/lua/unit/test_audio.lua`:**
- `it("MidiPlayer default sample rate is 44100")`
- `it("MidiPlayer setSampleRate round-trips 48000")`
- `it("MidiPlayer setSampleRate clamps below 8000 to 8000")`
- `it("MidiPlayer setSampleRate clamps above 192000 to 192000")`
- `it("MidiPlayer getChannels returns 2 by default")`
- `it("MidiPlayer setChannels to 1 returns 1")`

**Done when:** Fields exist; `play()` uses them; Lua getters/setters round-trip; Lua tests pass.

---

### PR-6 — NOTE-01: `LargeMapRenderer` default viewport 0×0 (no culling)

**Files touched:**
- `src/tilemap/large_map_renderer.rs` — constructor and `visible_chunk_range`

#### Change 1 — Constructor defaults (~lines 113–114)

```rust
// BEFORE
            viewport_w: 800.0,
            viewport_h: 600.0,
```
```rust
// AFTER
            viewport_w: 0.0,
            viewport_h: 0.0,
```

#### Change 2 — `visible_chunk_range` guard: treat 0×0 as render-everything

Add at the very top of the `visible_chunk_range` function body, before the existing zoom/half-width logic:

```rust
// AFTER — insert at start of visible_chunk_range
        // 0×0 viewport means no culling: return the full map extent.
        if self.viewport_w <= 0.0 || self.viewport_h <= 0.0 {
            let cs = self.chunk_size as i32;
            let max_cx = if self.tile_width > 0 {
                (self.map_width as i32 + cs - 1) / cs
            } else {
                0
            };
            let max_cy = if self.tile_height > 0 {
                (self.map_height as i32 + cs - 1) / cs
            } else {
                0
            };
            return (0, max_cx, 0, max_cy);
        }
        // ... existing logic unchanged below ...
```

#### Tests to add

**`tests/lua/unit/test_tilemap.lua`:**
- `it("LargeMapRenderer default viewport is 0x0")`
- `it("LargeMapRenderer with 0 viewport returns all chunks visible")`
- `it("LargeMapRenderer explicit setViewport limits visible chunks")`

**Done when:** Default viewport is `0.0×0.0`; zero-viewport path renders full map without crashing; Lua tests pass.

---

### PR-7 — NOTE-03: GPU vertex buffer saturation warnings

**Files touched:**
- `src/graphics/gpu_renderer.rs` — add `log::warn!` near geometry flush
- `docs/specs/graphics.md` — document the four buffer constants

#### Change 1 — Near geometry submission (exact lines require reading the flush path)

The four constants are at lines 98–101:
```rust
const MAX_COLOR_VERTS: u64 = 1 << 17; // 131 072 vertices
const MAX_COLOR_IDXS:  u64 = 1 << 19; // 524 288 indices
const MAX_TEX_VERTS:   u64 = 1 << 14; //  16 384 vertices
const MAX_TEX_IDXS:    u64 = 1 << 16; //  65 536 indices
```

The Developer must locate the point after vertex/index `Vec`s are assembled and before `queue.write_buffer()` is called for each buffer. Add a warn at 90% capacity for each:

```rust
// AFTER — pattern to apply once per buffer (adapt variable names to actual code)
if color_verts.len() as u64 > MAX_COLOR_VERTS * 9 / 10 {
    log::warn!(
        "color vertex buffer at {}% ({}/{}); increase MAX_COLOR_VERTS in gpu_renderer.rs",
        color_verts.len() as u64 * 100 / MAX_COLOR_VERTS,
        color_verts.len(),
        MAX_COLOR_VERTS
    );
}
// Repeat for MAX_COLOR_IDXS, MAX_TEX_VERTS, MAX_TEX_IDXS
```

#### Note on `docs/specs/graphics.md`

Add a section documenting all four constants, their current values, and the fact that they are compile-time only. Mention the 90% warn threshold.

**Done when:** A render call that fills >90% of any buffer emits a `log::warn!`; constants are documented in the spec.

---

### PR-8 — NOTE-04: `Terminal` per-instance `MAX_COLS` / `MAX_ROWS`

**Files touched:**
- `src/terminal/terminal_state.rs` — add per-instance `max_cols` / `max_rows` fields; update all clamps
- `src/terminal/widget.rs` — update 5 call sites that use module-level `MAX_COLS` / `MAX_ROWS`
- `src/lua_api/terminal_api.rs` — expose `getMaxCols` / `getMaxRows` on Terminal UserData
- `docs/specs/terminal.md` — document the per-instance cap

#### Change 1 — Keep module constants as defaults; add struct fields (`terminal_state.rs`)

```rust
// BEFORE (lines 9, 12)
pub(crate) const MAX_COLS: usize = 512;
pub(crate) const MAX_ROWS: usize = 256;
```
```rust
// AFTER — unchanged values, updated doc
/// Default maximum columns for a Terminal. Per-instance cap may be set at construction.
pub(crate) const MAX_COLS: usize = 512;
/// Default maximum rows for a Terminal. Per-instance cap may be set at construction.
pub(crate) const MAX_ROWS: usize = 256;
```

Add to the `TerminalState` struct (find the struct definition):
```rust
// AFTER — new fields on TerminalState
    /// Per-instance column ceiling (defaults to MAX_COLS).
    pub(crate) max_cols: usize,
    /// Per-instance row ceiling (defaults to MAX_ROWS).
    pub(crate) max_rows: usize,
```

Initialize in `TerminalState::new()` / constructor:
```rust
// AFTER
    max_cols: MAX_COLS,
    max_rows: MAX_ROWS,
```

#### Change 2 — Replace all `MAX_COLS` / `MAX_ROWS` in clamps with instance fields

In `terminal_state.rs` (lines 132–133, 1014–1015):
```rust
// BEFORE
        let cols = cols.clamp(1, MAX_COLS);
        let rows = rows.clamp(1, MAX_ROWS);
```
```rust
// AFTER
        let cols = cols.clamp(1, self.max_cols);
        let rows = rows.clamp(1, self.max_rows);
```
(Repeat for lines 1014–1015.)

In `widget.rs` (lines 246–347 — 5 call sites), change:
```rust
// BEFORE (pattern repeated 5 times)
width.clamp(1, MAX_COLS),
height.clamp(1, MAX_ROWS),
```
These require access to the terminal's instance fields. The Developer should thread `max_cols` / `max_rows` from `TerminalState` into the widget builder calls, or pass them as parameters.

#### Change 3 — Lua API: expose read-only caps

In `terminal_api.rs` (inside `LuaTerminal` UserData methods):
```rust
// AFTER (new methods)

        // -- getMaxCols --
        /// Returns the maximum column count for this terminal.
        /// @return integer
        methods.add_method("getMaxCols", |_, this, ()| {
            Ok(this.inner.borrow().max_cols)
        });

        // -- getMaxRows --
        /// Returns the maximum row count for this terminal.
        /// @return integer
        methods.add_method("getMaxRows", |_, this, ()| {
            Ok(this.inner.borrow().max_rows)
        });
```

**Done when:** Per-instance fields exist; all 7 call sites use them; Lua getters work; no module constant leaks into instance logic.

---

### PR-9 — NOTE-05: Automation `MAX_STEPS` Lua-configurable

**Files touched:**
- `src/automation/script.rs` — rename constant; add per-script override
- `src/engine/shared_state.rs` — add `automation_max_steps: usize` field
- `src/lua_api/automation_api.rs` — expose `lurek.automation.setMaxSteps(n)` / `getMaxSteps()`
- `docs/specs/automation.md`

#### Change 1 — `script.rs` constant rename and absolute ceiling

```rust
// BEFORE (line 20)
const MAX_STEPS: usize = 100_000;
```
```rust
// AFTER
/// Absolute engine ceiling — no script may exceed this regardless of Lua config (DoS guard).
pub(crate) const ABS_MAX_STEPS: usize = 10_000_000;
/// Default maximum steps per script if the Lua caller has not changed it.
pub(crate) const DEFAULT_MAX_STEPS: usize = 100_000;
```

All uses of `MAX_STEPS` in `Script::new()` replace with the value passed in (from `SharedState::automation_max_steps`).

#### Change 2 — `SharedState` new field (`shared_state.rs`)

Next to `physics_fixed_dt`, add:
```rust
// AFTER
    /// Per-script step cap for the automation module. Default DEFAULT_MAX_STEPS.
    pub automation_max_steps: usize,
```

Initialize in `SharedState` default/new:
```rust
// AFTER
            automation_max_steps: crate::automation::script::DEFAULT_MAX_STEPS,
```

#### Change 3 — `automation_api.rs` Lua bindings

```rust
// AFTER (add to lurek.automation table registration)

    // -- setMaxSteps --
    /// Sets the maximum step count per automation script. Clamped to [1, 10_000_000].
    /// Takes effect on the next lurek.automation.loadScript() call.
    /// @param n : integer
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setMaxSteps",
        lua.create_function(move |_, n: usize| {
            s.borrow_mut().automation_max_steps =
                n.clamp(1, crate::automation::script::ABS_MAX_STEPS);
            Ok(())
        })?,
    )?;

    // -- getMaxSteps --
    /// Returns the current per-script step cap.
    /// @return integer
    let s = state.clone();
    tbl.set(
        "getMaxSteps",
        lua.create_function(move |_, ()| Ok(s.borrow().automation_max_steps))?,
    )?;
```

**Done when:** `getMaxSteps()` returns 100 000 by default; `setMaxSteps` updates it; scripts loaded after the call respect the new cap; ABS ceiling enforced at 10 000 000; Lua tests pass.

---

### PR-10 — NOTE-06: Font atlas ceiling from `conf.lua`

**Files touched:**
- `src/engine/config.rs` — add `graphics.font_atlas_max_size: u32` config key
- `src/graphics/font.rs` — replace `MAX_ATLAS_SIZE` constant with a per-`Font` field
- Callers of `Font::from_bytes()` or `FontCache` construction — thread the config value through
- `docs/specs/graphics.md`, `docs/specs/config.md`

#### Change 1 — `Config` (`engine/config.rs`)

In the graphics section of the appropriate config struct (verify field name by reading `config.rs`):

```rust
// AFTER — new field in GraphicsConfig (or equivalent)
    /// Maximum font glyph atlas size in pixels. Powers of two recommended.
    /// Must be >= 512 (the initial size). Default 2048.
    pub font_atlas_max_size: u32,
```

Default value: `2048`.

#### Change 2 — `Font` struct and `grow_atlas` (`font.rs`)

```rust
// BEFORE (lines 18–19)
const INITIAL_ATLAS_SIZE: u32 = 512;
const MAX_ATLAS_SIZE: u32 = 2048;
```
```rust
// AFTER — keep INITIAL_ATLAS_SIZE; max moves to instance field
const INITIAL_ATLAS_SIZE: u32 = 512;
// MAX_ATLAS_SIZE removed — now a per-Font field
```

Add `max_atlas_size: u32` to the `Font` struct. Update `Font::from_bytes(…, max_atlas_size: u32)`:
```rust
// AFTER — in from_bytes init
    max_atlas_size: max_atlas_size.max(INITIAL_ATLAS_SIZE),
```

Update `grow_atlas()`:
```rust
// BEFORE
if self.atlas_width >= MAX_ATLAS_SIZE {
```
```rust
// AFTER
if self.atlas_width >= self.max_atlas_size {
```

**Done when:** `Font::from_bytes` accepts `max_atlas_size`; `conf.lua` key wired through; constant removed from module scope; Lua tests pass.

---

### PR-11 — NOTE-07: GOAP `max_iterations` as `GoapPlanner` field

**Files touched:**
- `src/ai/goap.rs` — add `max_iterations: usize` field; replace local variable
- `src/lua_api/ai_api.rs` — expose `setMaxIterations` / `getMaxIterations`
- `docs/specs/ai.md`

#### Change 1 — `GoapPlanner` struct (`goap.rs`)

Find the `GoapPlanner` struct (contains `actions: Vec<GoapAction>`) and add:

```rust
// AFTER
    /// A★ search iteration cap. Prevents runaway planning on large action sets.
    /// Default 10 000. Increase for complex worlds; decrease for real-time AI.
    pub max_iterations: usize,
```

Initialize in `GoapPlanner::new()` or `Default`:
```rust
// AFTER
    max_iterations: 10_000,
```

#### Change 2 — `plan_for_goal` / `plan` method (~line 225)

```rust
// BEFORE
        let max_iterations = 10_000;
        while let Some(current) = open.pop() {
            iterations += 1;
            if iterations > max_iterations {
```
```rust
// AFTER
        while let Some(current) = open.pop() {
            iterations += 1;
            if iterations > self.max_iterations {
```

#### Change 3 — Lua bindings in `ai_api.rs`

Add to `LuaGoapPlanner::add_methods`:
```rust
// AFTER

        // -- setMaxIterations --
        /// Sets the A★ iteration cap for plan(). Default 10000.
        /// @param n : integer
        /// @return nil
        methods.add_method_mut("setMaxIterations", |_, this, n: usize| {
            this.inner.borrow_mut().max_iterations = n.max(1);
            Ok(())
        });

        // -- getMaxIterations --
        /// Returns the current A★ iteration cap.
        /// @return integer
        methods.add_method("getMaxIterations", |_, this, ()| {
            Ok(this.inner.borrow().max_iterations)
        });
```

#### Tests to add

**`tests/lua/unit/test_ai.lua`:**
- `it("GoapPlanner default max_iterations is 10000")`
- `it("setMaxIterations to 500 round-trips via getMaxIterations")`

**Done when:** `max_iterations` is a `GoapPlanner` field; local variable removed; Lua getters/setters work; Lua tests pass.

---

### Execution Order and PR Groupings

| PR | Commit type | Title | Depends on | Parallelizable |
|---|---|---|---|---|
| PR-1 | `feat(tilemap)` | Dynamic IsoTile part count and part order | — | Yes |
| PR-2 | `feat(tilemap)` | Extend MapOrientation to Isometric/Hexagonal | — | Yes |
| PR-3 | `feat(tilemap)` | addStep exposes all 8 step types | — | Yes |
| PR-4 | `feat(engine)` | Physics max-steps cap + newSoundData guard | — | Yes |
| PR-5 | `feat(audio)` | MidiPlayer sample-rate/channels fields | MIDI re-enable | No |
| PR-6 | `fix(tilemap)` | LargeMapRenderer default viewport 0×0 | — | Yes |
| PR-7 | `fix(graphics)` | GPU buffer saturation warnings | — | Yes |
| PR-8 | `feat(terminal)` | Per-instance MAX_COLS/MAX_ROWS | — | Yes |
| PR-9 | `feat(automation)` | Lua-configurable MAX_STEPS | SharedState field | Yes |
| PR-10 | `feat(graphics)` | Font atlas ceiling from conf.lua | Config change → Configurator review | No |
| PR-11 | `feat(ai)` | GOAP max_iterations as planner field | — | Yes |

**PR-1 through PR-4, PR-6 through PR-9, PR-11** can be opened in parallel — they touch disjoint files.
**PR-5** waits on MIDI re-enable.
**PR-10** requires a `conf.lua` template change — coordinate with `Configurator` before merging.

---

### Cross-Artifact Sync Checklist

Every PR must verify all rows of the cross-artifact sync contract before merge:

| PR | Must also update |
|---|---|
| PR-1 | `src/tilemap/AGENT.md` · `docs/specs/tilemap.md` · `content/examples/tilemap.lua` · `docs/API/lua-api.md` (run `python tools/gen_all_docs.py`) |
| PR-2 | `docs/specs/tilemap.md` · `content/examples/tilemap.lua` |
| PR-3 | `docs/specs/tilemap.md` · `content/examples/tilemap.lua` |
| PR-4 | `docs/specs/timer.md` · `docs/specs/audio.md` |
| PR-5 | `src/audio/AGENT.md` · `docs/specs/audio.md` · `docs/API/lua-api.md` |
| PR-6 | `docs/specs/tilemap.md` |
| PR-7 | `docs/specs/graphics.md` |
| PR-8 | `docs/specs/terminal.md` |
| PR-9 | `docs/specs/automation.md` · `src/engine/shared_state.rs` (new field) |
| PR-10 | `docs/specs/graphics.md` · `docs/specs/config.md` · conf.lua template |
| PR-11 | `docs/specs/ai.md` |
| All | `docs/CHANGELOG.md` — add MINOR entry (new Lua API) |

