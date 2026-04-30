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
- HTML UI in this repo spans src/html/ domain code, src/ui/ integration, and src/lua_api/html_api.rs bindings, so authoring decisions should respect the full path from markup to Lua callbacks.
- Use docs/specs/html.md and docs/specs/ui.md as the behavior contract for the supported HTML and CSS feature set instead of assuming browser-complete behavior.
- Keep markup and styling together; do not spread layout decisions across Lua callbacks unless state actually changes them at runtime.
- Relayout only when DOM size, hierarchy, or content changes justify it; unnecessary rebuilds make UI behavior harder to reason about and can cost frame time.
- Showcase HTML screens already exist in content/games/showcase/ and are better anchors than generic web tutorials because they reflect the engine-supported subset.
- Keep IDs, classes, and callback wiring explicit so UI behavior stays inspectable, grep-friendly, and testable from scripts.
- Prefer HTML and CSS for document structure and visual rules, with Lua responsible for state transitions, user actions, and data flow.
- Avoid importing web assumptions that the engine does not promise, especially around layout edge cases, browser APIs, or unsupported styling behavior.
- This skill covers HTML and CSS UI documents and flow, not TOML layouts under content/layouts/ and not Rust widget internals in src/ui/.
- Good html-css work in this repo produces screens that are readable in source, predictable in runtime behavior, and clearly connected to the Lua logic that drives them.
- When UI behavior depends on game state, keep that contract visible in the script rather than burying logic in CSS or implicit DOM conventions.
## Companion File Index
- None.

## References
- docs/specs/html.md
- docs/specs/ui.md
- src/html/
- src/lua_api/html_api.rs
- content/games/showcase/
