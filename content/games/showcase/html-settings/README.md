# HTML Settings Demo

A full settings screen with toggle switches and radio groups, demonstrating
two-way DOM binding between Lua state and HTML/CSS state.

## What it demonstrates

- Rendering a multi-section form using standard HTML structure.
- Toggle switches: clicking flips a CSS class and a Lua variable.
- Radio groups: `queryAll('[data-group="…"]')` clears siblings before setting
  the active class.
- `keypressed` and `textinput` forwarding for keyboard navigation.

## Controls

| Input            | Action                |
|------------------|-----------------------|
| Click toggles    | Enable / disable      |
| Click radio btns | Select quality preset |
| Click Apply      | Print settings        |
| `Escape`         | Quit                  |
