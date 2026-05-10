# HTML LoadDocument Demo

A showcase game that uses only external HTML/CSS files for UI via
lurek.html.loadDocument.

## What it demonstrates

- File-backed UI loading: ui/hud.html + ui/hud.css.
- No inline HTML/CSS strings in Lua runtime code.
- Runtime DOM updates for score, timer, status, and pulse counter.
- HTML button interactions wired through document and element events.
- Input forwarding to document handlers (mouse, keyboard, wheel, text).

## Controls

- Move mouse: move the player dot.
- Left click: interact with HTML buttons.
- Space: pulse counter increment from gameplay input.
- Escape: quit.

## Run

cargo run -- content/games/showcase/html-load-document
