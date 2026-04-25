# HTML Inventory Demo

An inventory grid screen built entirely with HTML/CSS, demonstrating how to
handle click events on dynamically generated element lists.

## What it demonstrates

- Building a grid of 20 item slots with `newDocument`.
- Querying all slots at once with `queryAll(".slot.filled")`.
- Wiring click event handlers via `el:on("click", fn)`.
- Using `addClass` / `removeClass` to toggle a "selected" visual state.
- Reading `getAttribute("data-*")` to carry item metadata in the DOM.

## Controls

| Input           | Action            |
|-----------------|-------------------|
| Click item slot | Equip / highlight |
| `Escape`        | Quit              |
