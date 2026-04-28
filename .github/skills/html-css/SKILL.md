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
- Create documents once and update or draw them through the normal frame flow.
- Keep layout and styling concerns in HTML and CSS, not scattered in Lua.
- Use relayout when bulk DOM or HTML changes require it.
- Forward input intentionally so UI can consume it cleanly.
- Keep UI examples readable and easy to inspect.
- Use the UI spec as the contract for supported behavior.

## Companion File Index
- None.

## References
- docs/specs/ui.md
- src/lua_api/ui_api.rs
- src/ui/html/
- content/examples/ui.lua