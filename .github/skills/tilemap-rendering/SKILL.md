---
name: tilemap-rendering
description: "Load this skill when implementing tilemaps, tile culling, tileset atlases, or tile-based collision in Luna2D Lua scripts. Skip it for free-form sprite rendering, physics bodies, audio, or Rust engine code."
---

# Tilemap Rendering — Luna2D Engine

## Load When

- Implementing a tile-based level or world map in Lua
- Adding tile culling to skip off-screen draw calls
- Building a tileset loader or collision layer
- Layering background / entity / foreground tile passes

## Owns

- Lua-side tilemap data structure and draw loop
- Viewport culling math for visible tile range
- Tileset pre-loading pattern in `luna.load()`
- Collision layer design (separate table, checked in `update`)
- Multi-layer rendering order

## Does Not Cover

- Physics body creation → use `physics-engine` skill
- Camera setup → use `camera-transforms` skill
- Sprite animation on tiles → use `animation-system` skill
- Tiled (.tmx) file parsing (no built-in support — parse externally, express result as Lua table)

## Live Repository Contracts

- `src/lua_api/graphics_api.rs` — `luna.graphics.draw(texture_id, x, y)` binding
- `src/graphics/renderer.rs` — `DrawCommand::DrawImage { texture_id, x, y }` and `DrawCommand::Rectangle`
- `src/graphics/camera.rs` — viewport bounds used for culling (`camera_x`, `camera_y`, viewport width/height)

## Decision Rules

- **Always cull**: O(N×M) DrawCommands per frame is budget-critical; skip tiles outside the viewport every frame
- **Culling math**: compute `first_col = math.max(1, math.floor(cam_x / TILE_SIZE) + 1)` and `last_col = math.min(map_width, first_col + viewport_cols + 1)`; same for rows
- **Tile coords are world space**: multiply `(col-1)*TILE_SIZE` and `(row-1)*TILE_SIZE`; camera transform is applied by the renderer
- **Integer tile lookup**: use `math.floor` when converting world coords to tile indices to avoid float-index errors
- **Map indexing**: prefer `map[row][col]` (2D nested table) over flat `map[row*width+col]` — Lua tables are 1-indexed
- **Tileset pre-loading**: load all textures in `luna.load()` into a `tileset = {}` table keyed by tile ID; never load inside the draw loop
- **Collision layer separate**: store solid flags in a parallel `collision[row][col]` boolean table; query it in `luna.update()`, never in `luna.draw()`
- **Layer order**: draw background tiles first, then entities/sprites, then foreground tiles — three separate passes over the same culled range
- **Tile ID 0 = empty**: skip draw calls for tile ID 0 to avoid rendering blank tiles
- **Use Rectangle for solid-color tiles**: when no texture is needed, `DrawCommand::Rectangle` avoids a texture lookup

## Canonical Tilemap Pattern

> See [example.lua](example.lua) for the canonical tilemap pattern code example.
