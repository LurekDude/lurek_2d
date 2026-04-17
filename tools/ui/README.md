# tools/ui/

Standalone Python utilities for Lurek2D UI layout tooling.
No game engine required — these scripts run directly from the command line.

## render_layout.py — Layout PNG Preview

Renders a Lurek2D TOML UI layout file to a wireframe PNG image.
Each widget is drawn as a colour-coded filled rectangle with a border and a
label showing: `widget_type [id] "text"`.

### Requirements

```
pip install Pillow
# Python < 3.11 also needs:
pip install tomli
```

### Usage

```powershell
# Render a single layout file (outputs hud.png next to hud.layout.toml)
python tools/ui/render_layout.py content/demos/my_game/hud.layout.toml

# Render all *.layout.toml files under content/ (non-recursive)
python tools/ui/render_layout.py --all content/

# Render all *.layout.toml recursively
python tools/ui/render_layout.py --all content/ --recursive

# Preview: see what would be rendered without writing PNGs
python tools/ui/render_layout.py --dry-run content/demos/my_game/hud.layout.toml
```

### Layout file format

A layout file is a `.toml` file with a `[root]` section (a `WidgetDef` tree).

Resolution (output PNG size) is determined in this order:
1. `resolution = [1280, 720]`  — top-level explicit key  (**preferred**)
2. `root.w` × `root.h`         — root widget size
3. `1280 × 720`                 — hardcoded fallback

### Example

```toml
# content/demos/my_game/hud.layout.toml
resolution = [1280, 720]

[root]
widget_type = "panel"
w = 1280.0
h = 720.0

[[root.children]]
widget_type = "label"
id = "score_label"
text = "Score: 0"
x = 10.0
y = 10.0
w = 200.0
h = 30.0

[[root.children]]
widget_type = "button"
id = "pause_btn"
text = "Pause"
x = 1180.0
y = 10.0
w = 90.0
h = 30.0
```

Run:
```powershell
python tools/ui/render_layout.py content/demos/my_game/hud.layout.toml
# -> writes content/demos/my_game/hud.png
```

### Widget colour legend

| Widget type     | Colour        |
|-----------------|---------------|
| button          | Blue          |
| label           | Green         |
| panel           | Dark blue     |
| textinput       | Light grey    |
| checkbox        | Gold          |
| slider          | Green         |
| progressbar     | Teal          |
| combobox        | Purple        |
| listbox         | Blue-grey     |
| layout          | Very dark     |
| guiwindow       | Dark blue     |
| dialog          | Dark blue     |
| menubar/statusbar | Very dark   |
| badge           | Red           |
| *unknown*       | Mid grey      |
