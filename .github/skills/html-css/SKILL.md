---
name: html-css
description: "Load this skill when building UI screens, HUD overlays, inventory grids, dialogs, settings menus, or scoreboards using lurek.html â€” HTML markup and CSS for layout, Lua callbacks for logic. Skip it for Rust src/ui/ internals, TOML layout files (use ui-layout), pure game logic, or non-HTML widget work."
companion_files:
  - examples/quickstart.lua
  - snippets/common-patterns.lua
related_skills:
  - lua-scripting
  - lua-api-design
  - lua-rust-bridge
  - ui-layout
---
# html-css

## Mission

Guide GameDevs and Modders in authoring `lurek.html` screens â€” choosing selectors,
wiring events, forwarding input, and animating state â€” without touching Rust internals.

## When To Load

- Adding any HUD overlay, health bar, minimap badge, or screen-edge panel
- Building a dialog tree, settings screen, or main menu using HTML/CSS
- Animating element state (active / disabled / selected) with CSS classes
- Rendering a table-based scoreboard or inventory grid
- Forwarding `lurek.mousepressed` / `keypressed` / `textinput` to an HTML document
- Using `queryAll`, `on`, or `off` on document or element objects
- Creating a new demo under `content/games/showcase/html-*/`

## When To Skip

- Modifying `src/ui/html/*.rs` Rust internals â†’ use `rust-coding` + `lua-rust-bridge`
- Authoring `content/layouts/*.toml` files â†’ use `ui-layout` skill
- Pure game logic with no UI involvement â†’ use `lua-scripting`
- Profiling draw call overhead â†’ use `performance-profiling`

## Domain Knowledge

### Document lifecycle

1. Create once in `lurek.load` with `lurek.html.newDocument(html?, opts?)`.
2. Call `doc:update(dt)` every frame from `lurek.update`.
3. Call `doc:draw(x?, y?)` every frame from `lurek.draw`.
4. After any bulk `setHtml` call, invoke `doc:relayout()` before the next draw.

### Input forwarding pattern

Forward all four input events and test the consumed boolean to block game hit-tests:
see `snippets/common-patterns.lua` for the canonical 4-line block.

### Event wiring

Wire element events with `el:on("click", fn)` â€” returns an opaque handle.
Unwire with `el:off(handle)` in the screen teardown path.
Document-level `doc:on` / `doc:off` follow the same contract.

### CSS class state machine

Prefer toggling CSS classes over inline `setStyle` for mutually exclusive states â€”
the CSS rule-set stays in one place and theming is easier.
Use `el:toggleClass(cls)` for binary toggles; it returns the new state (true = added).
Use `queryAll` + `removeClass` + single `addClass` for radio-group patterns.

### Viewport sync

Always call `doc:setViewport(w, h)` inside `lurek.resize(w, h)` so the document
re-flows to match the new window size.

### Performance

Avoid rebuilding the full DOM every frame â€” prefer `el:setText`, `el:setStyle`, or
CSS class swaps for per-frame updates. Reserve `setHtml + relayout` for bulk changes
triggered by discrete events (level start, dialog page turn, score update).

### loadDocument vs newDocument

`newDocument(html, opts)` â€” inline HTML string; good for small templates.
`loadDocument(path, opts)` â€” reads a `.html` file from the game folder; raises a
Lua error if the file is missing.  Always guard with `pcall` in production code.

### supports() feature guard

Call `lurek.html.supports("feature")` once at startup to gate optional features.
Known truthy values: `"html"`, `"css"`, `"selectors"`, `"events"`, `"forms"`,
`"pure-rust"`, `"inline-style"`, `"draw-commands"`, `"descendant-selectors"`,
`"child-selectors"`.

## Companion File Index

| File | Contents |
|------|----------|
| `examples/quickstart.lua` | Minimal single-file HUD example â€” create, update, draw, input |
| `snippets/common-patterns.lua` | Input forwarding, class toggle, queryAll radio-group, relayout-after-setHtml |

## References

- `docs/specs/ui.md` â€” canonical `lurek.html` API reference (full method list)
- `content/examples/ui.lua` â€” `--@api-stub:` blocks for every `lurek.html.*` function
- `content/games/showcase/html-hud/` â€” HUD overlay demo
- `content/games/showcase/html-inventory/` â€” inventory grid demo
- `content/games/showcase/html-dialog/` â€” branching dialog demo
- `content/games/showcase/html-settings/` â€” settings screen demo
- `content/games/showcase/html-scoreboard/` â€” live leaderboard demo
- `src/lua_api/ui_api.rs` â€” thin Lua wrapper (LuaHtmlDocument / LuaHtmlElement)
- `src/ui/html/` â€” pure-Rust HTML/CSS engine (domain logic)
