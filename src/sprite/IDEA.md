# IDEA.md — `sprite` module

> Migrated from `ideas/features/graphics.md` (sprite / atlas sections).
> Status checked against `src/sprite/` and `src/lua_api/sprite_api.rs`.
> Lua namespace: `lurek.sprite`.

---

## Features

### ✅ DONE — TexturePacker JSON Atlas Import
**Source**: features/graphics.md — Feature Gaps #1 (IMPLEMENTED in sprite module)

`lurek.sprite.parseAtlas(json_str)` → `SpriteAtlas` — TexturePacker hash or array
format parsing via `src/sprite/atlas.rs:parse_texturepacker_json`.
`LuaSpriteAtlas` with `impl LuaUserData` at `sprite_api.rs:141`.

---

### ✅ DONE — Atlas-Derived SpriteSheet
**Source**: `sprite_api.rs:219`

`lurek.sprite.newAtlasSheet(atlas, sheet_w, sheet_h)` — wraps `SpriteAtlas` into
a sprite-sheet with named region lookup.

---

### ✅ DONE — Named Frame Groups / Region Lookup
**Source**: `sprite_api.rs` — `LuaSpriteAtlas` methods

Named region extraction and frame group mapping from atlas metadata.

---

### ❌ TODO — Aseprite JSON Atlas Format Support
**Source**: features/graphics.md — Feature Gaps #1

`parseAtlas` handles TexturePacker format. Aseprite also exports JSON sprite sheets
with a different schema. Many small-team and solo developers use Aseprite natively.

---

### ❌ TODO — Runtime Atlas Packing (Batch Textures → Single GPU Page)
**Source**: features/graphics.md — Feature Gaps #1 / performance/02-gpu-rendering.md — Opportunity 2

No runtime atlas packer that takes multiple loaded textures and packs them into shared
GPU pages to reduce texture switching. This is the highest-ROI batching improvement —
reduces 200+ draw calls to 3–5 for a typical sprite-heavy game.

Suggested API:
```lua
local atlas = lurek.sprite.newAtlasPacker(2048, 2048)
atlas:add("player", player_img)
atlas:add("enemy", enemy_img)
local packed = atlas:pack()  -- returns SpriteAtlas + backing texture
```

---

### ❌ TODO — Normal Map / Lit Sprite Support
**Source**: general engine completeness

No normal map channel binding for lit 2D sprites (useful with `lurek.light` module).
Currently lighting and sprites are decoupled — a lit-sprite path would link them.

---

### ❌ TODO — Sprite Flip (flipX / flipY) as First-Class Atlas Feature
**Source**: general API completeness

Flipping is currently done per draw call via transform scaling. A first-class
`region:getFlipped(flipX, flipY)` returning a flipped UV region would be cleaner.

---

### 🔇 LOW — Binary Atlas Format (Faster Load)
**Source**: general performance

JSON parsing at startup for large atlases adds measurable load time. A compiled binary
format (e.g. flat binary UV table) would load faster. Low priority unless atlas files
exceed ~5000 regions.
