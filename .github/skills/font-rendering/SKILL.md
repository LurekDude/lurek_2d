---
name: font-rendering
description: "Load this skill when implementing or modifying text rendering in Luna2D: bitmap font embedding, glyph rasterization, the Print DrawCommand pipeline, or adding TTF support. Skip it for non-text graphics, physics, audio, or Lua API design unrelated to text."
---

# Font Rendering — Luna2D Engine

## Load When

- Implementing or changing `DrawCommand::Print` processing in `execute_commands()`
- Embedding or updating the bitmap font asset
- Adding font scaling, color, or alignment to `luna.graphics.print`
- Planning TTF font support via `rusttype` or `fontdue`

## Owns

- `DrawCommand::Print { text, x, y, scale }` — definition and execution
- Bitmap font embedding and glyph lookup
- Text color via `SetColor` draw-state tracking
- `luna.graphics.print(text, x, y)` Lua binding

## Does Not Cover

- Non-text draw commands → `software-rendering` skill
- Texture atlas for sprites → `software-rendering` skill
- Lua API design conventions → `lua-api-design` skill

## Live Repository Contracts

- `src/graphics/renderer.rs` — `DrawCommand::Print` arm inside `execute_commands()`; current color is read from `draw_state.color` set by the preceding `SetColor` command
- `src/lua_api/graphics_api.rs` — `luna.graphics.print(text, x, y)` pushes `DrawCommand::Print { text, x, y, scale: 1.0 }` onto the command queue

## Decision Rules

- **No TTF in core**: Keep the core dependency-free; bitmap font only. TTF (`fontdue`/`rusttype`) goes behind a Cargo feature flag when added
- **Bitmap font as const**: Embed the font as `const FONT_BITMAP: &[u8]` in `src/graphics/renderer.rs`; no runtime file I/O
- **Scale is uniform**: `scale` multiplies both glyph width and height equally — no separate x/y scale
- **Text color from draw state**: The `Print` arm reads the color accumulated from the most recent `DrawCommand::SetColor`; it does not carry its own color field
- **Top-left origin**: Glyph rendering starts at `(x, y)` as the top-left corner of the first character — no centering by default
- **No automatic wrapping**: Text exceeding the window width is clipped; the engine does not wrap lines
- **No newline handling**: `\n` in the string is not parsed; treat the input as a single line
- **TTF rendering**: fontdue is integrated — `FontAtlas` preloads glyph data into `SharedState`, resolved glyphs are rendered through wgpu as textured quads
