# Docs Demo

Interactive API documentation browser and viewer: navigate 12 `lurek.*` namespaces in a sidebar, inspect function signatures with syntax-highlighted params and return types, search across all functions, bookmark favourites, and track browsing history — all rendered as a polished in-engine reference tool.

## What It Demonstrates

- `lurek.gfx.rectangle()` / `lurek.gfx.print()` / `lurek.gfx.line()` — sidebar, panels, syntax-highlighted text
- `lurek.particles.newSystem()` — page-turn sparkle and search-result highlight glow
- `lurek.tween.to()` / `lurek.tween.update()` — smooth sidebar scroll and panel slide transitions
- `lurek.input.bind()` / `lurek.input.wasActionPressed()` — action-based navigation, search, bookmarks, history
- `lurek.camera.attach()` / `lurek.camera.detach()` — camera setup for world/UI split
- `lurek.window.setTitle()` / `lurek.gfx.setBackgroundColor()` — window configuration
- `lurek.signal.quit()` — clean exit

## How to Run

```bash
cargo run -- content/games/showcase/docs_demo
```

## Controls

| Key          | Action                                       |
| ------------ | -------------------------------------------- |
| Up / Down    | Navigate namespace list or function list     |
| Left / Right | Previous / next page within a namespace      |
| Enter        | Expand selected namespace or select function |
| /            | Open search mode — type to filter functions  |
| B            | Bookmark / unbookmark current function       |
| Tab          | View bookmarks list                          |
| H            | View browsing history                        |
| Escape       | Back / close overlay / quit from main        |

## Notes

- All API data is inline — no external files are loaded; the demo is entirely self-contained.
- Coverage meter reflects the static data set (42/50 documented) and animates on namespace changes.
- Search is case-insensitive and matches against function names, parameter names, and descriptions.
