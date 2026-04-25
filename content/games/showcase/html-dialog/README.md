# HTML Dialog Demo

An RPG-style NPC conversation system using HTML dialog boxes with branching
choices, showcasing dynamic DOM replacement and per-element event handling.

## What it demonstrates

- Building HTML content dynamically in Lua (`string.format` → `setHtml`).
- Calling `relayout()` after bulk DOM replacement.
- Wiring per-button click handlers to advance a conversation tree.
- Using `consumed = doc:mousepressed(x, y, btn)` to block game clicks when the
  dialog is open.

## Controls

| Input              | Action                              |
|--------------------|-------------------------------------|
| Click NPC          | Open dialog                         |
| Click choice btn   | Advance conversation / close dialog |
| `Escape`           | Close dialog / Quit                 |
