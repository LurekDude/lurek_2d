# HTML HUD Demo

A minimal game showcasing the `lurek.html` API for building live game HUDs
using HTML markup and CSS.

## What it demonstrates

- `lurek.html.newDocument(html, opts)` to create an overlay document.
- `getElementById` + `setStyle` to drive a CSS-animated health bar.
- `setText` to update score and timer labels each frame.
- `hud:draw()` to composite the HTML layer over wgpu game-world draw calls.
- Input forwarding (`mousemoved`, `mousepressed`) so the document can react.

## Controls

| Input       | Action              |
|-------------|---------------------|
| Move mouse  | Move the player dot |
| `Escape`    | Quit                |

## Key patterns used

```lua
-- Create once in lurek.load
hud = lurek.html.newDocument(HTML, { css = CSS, width = w, height = h })

-- Update DOM each frame in lurek.update
local bar = hud:getElementById("hp-bar")
bar:setStyle("width", math.floor(pct * 100) .. "%")
hud:update(dt)

-- Render on top of world in lurek.draw
hud:draw()
```
