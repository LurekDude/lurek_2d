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
- HTML UI in this repo spans src/html/ domain code, src/ui/ integration, and src/lua_api/html_api.rs bindings.
- Use docs/specs/html.md and docs/specs/ui.md as the behavior contract for supported HTML/CSS features.
- Keep markup and styling together; do not spread layout decisions across Lua callbacks unless state really changes them.
- Relayout only when DOM size or structure changes justify it.
- Showcase HTML screens already exist in content/games/showcase/ and are better anchors than generic web patterns.
- This skill covers HTML/CSS UI, not TOML layouts under content/layouts/.
- HTML-driven UI work should respect the current engine-side html/ui split and the showcase content already living under content/games/showcase/.
- Lua callback wiring should remain explicit so UI behavior stays inspectable and testable from game scripts.
- This skill owns HTML/CSS documents and flow, not TOML layout grids or Rust widget internals.
## Companion File Index
- None.

## References
- docs/specs/html.md
- docs/specs/ui.md
- src/html/
- src/lua_api/html_api.rs
- content/games/showcase/
