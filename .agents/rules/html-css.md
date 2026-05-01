---
description: "Load when building lurek.html screens, HUDs, menus, dialogs, or scoreboards with HTML and CSS. Skip for src/ui/ Rust internals, TOML layouts, or pure game logic."
alwaysApply: false
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
- Use docs/specs/html.md and docs/specs/ui.md as the behavior contract for the supported HTML and CSS feature set; do not assume browser-complete behavior.
- Keep markup and styling together; do not spread layout decisions across Lua callbacks unless state actually changes them at runtime.
- Relayout only when DOM size, hierarchy, or content changes justify it.
- Showcase HTML screens in content/games/showcase/ are better anchors than generic web tutorials.
- Keep IDs, classes, and callback wiring explicit so UI behavior stays inspectable, grep-friendly, and testable.
- Prefer HTML and CSS for document structure and visual rules, with Lua responsible for state transitions.
- Avoid importing web assumptions that the engine does not promise.
- Good html-css work produces screens that are readable in source, predictable in runtime behavior.

## References
- docs/specs/html.md
- docs/specs/ui.md
- src/html/
- src/lua_api/html_api.rs
- content/games/showcase/
