---
name: html-css
description: "Load this skill when building lurek.html screens, HUDs, menus, dialogs, or scoreboards with HTML and CSS. Skip it for src/ui/ Rust internals, TOML layouts, or pure game logic."
---
# html-css

## Mission
- Own lurek.html authoring patterns for HTML, CSS, and Lua-driven UI flow.

## When To Load
- Build an HTML screen.
- Add HUD, menu, dialog, or scoreboard markup.
- Review CSS layout or UI document flow.
- Connect Lua callbacks to HTML UI behavior.

## When To Skip
- src/ui/ Rust internals.
- TOML layout files.
- Pure game logic.

## Domain Knowledge
- Full pipeline: `src/html/parser.rs` tokenises the HTML string → `src/html/element.rs` builds the DOM arena → `src/html/style.rs` parses CSS and resolves computed styles → `src/html/selector.rs` matches selectors → `src/html/document.rs` returns an `HtmlDocument` with layout rects. The `HtmlDocument` is then handed to `GpuRenderer` as a draw source. Every step is pure Rust; there is no browser engine.
- Supported CSS subset: type selectors, class selectors (`.foo`), id selectors (`#foo`), descendant (` `) and child (`>`) combinators, `color`, `font-size`, `padding`, `text-align`, `background-color`, `width`, `height`, `display: none`. Flexbox is available as an opt-in via `lurek.html.supports("css-flex")` — check this before using flex layout so the code degrades gracefully in CI environments.
- How to wire a Lua callback: after calling `lurek.html.newDocument(html, options)`, use `doc:on("click", "#button_id", function(evt) ... end)`. The `evt` table has `id`, `tag`, and `value` fields. Callbacks fire synchronously from the event queue before the next `lurek.draw()`. Never do heavy computation in a callback.
- How to update DOM state from Lua: call `doc:setAttr("#score", "text", tostring(score))` to change text content, or `doc:setClass("#panel", "hidden", true)` to toggle visibility. Do not rebuild the whole document each frame — that triggers a full re-parse and layout cycle, which is expensive. Patch only what changed.
- Performance rule: relayout triggers when DOM structure, element count, or CSS that affects sizing changes. Text-only changes and class toggles that affect only color or display:none are cheaper. If a screen is complex, split it: static chrome in one document, dynamic counters in a second smaller document composited over the first.
- The supported HTML tags are those `src/html/parser.rs` explicitly handles. Before using an uncommon tag or attribute, check the parser source. Unsupported tags are silently skipped — they do not error, but they also do not render, which is a silent bug.
- Content separation rule: HTML and CSS own structure and visual rules. Lua owns state transitions, data flow, and timing. Never compute game state inside a CSS expression or inline HTML attribute. If the value comes from game state, write it through `doc:setAttr()` from Lua.
## Companion File Index
- None.

## References
- docs/specs/html.md
- docs/specs/ui.md
- src/html/
- src/lua_api/html_api.rs
- content/games/showcase/
