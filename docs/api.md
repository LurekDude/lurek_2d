# Luna2D API Reference

Complete API reference for the `luna.*` Lua namespace.

## Table of Contents

- [Callbacks](#callbacks)
- [luna.graphics](#lunagraphics)
- [luna.window](#lunawindow)
- [luna.input (keyboard)](#lunainput-keyboard)
- [luna.input (mouse)](#lunainput-mouse)
- [luna.timer](#lunatimer)
- [luna.math](#lunamath)
- [luna.physics](#lunaphysics)
- [luna.audio](#lunaaudio)
- [luna.filesystem](#lunafilesystem)
- [luna.event](#lunaevent)
- [luna.system](#lunasystem)

---

## Callbacks

These functions are defined by your game and called by the engine.

### `luna.load()`
Called once after `main.lua` is loaded. Use for initialization.

```lua
function luna.load()
    player = { x = 100, y = 100, speed = 200 }
end
```

### `luna.update(dt)`
Called every frame with the time since last frame in seconds.

| Parameter | Type | Description |
|-----------|------|-------------|
| `dt` | number | Delta time in seconds |

```lua
function luna.update(dt)
    player.x = player.x + player.speed * dt
end
```

### `luna.draw()`
Called every frame for rendering. All draw calls go here.

```lua
function luna.draw()
    luna.graphics.rectangle("fill", player.x, player.y, 32, 32)
end
```

### `luna.keypressed(key)`
Called when a key is pressed.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Key name (e.g. `"space"`, `"escape"`, `"a"`) |

### `luna.keyreleased(key)`
Called when a key is released.

### `luna.mousepressed(x, y, button)`
Called when a mouse button is pressed.

| Parameter | Type | Description |
|-----------|------|-------------|
| `x` | number | Mouse X position |
| `y` | number | Mouse Y position |
| `button` | number | Button index: 1=left, 2=right, 3=middle |

### `luna.mousereleased(x, y, button)`
Called when a mouse button is released.

---

## luna.graphics

Drawing primitives and rendering control.

### `luna.graphics.setColor(r, g, b [, a])`
Set the current drawing color. Values 0.0–1.0.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `r` | number | — | Red component |
| `g` | number | — | Green component |
| `b` | number | — | Blue component |
| `a` | number | 1.0 | Alpha component |

### `luna.graphics.getColor()`
Returns the current color.

**Returns:** `r, g, b, a` (four numbers)

### `luna.graphics.setBackgroundColor(r, g, b)`
Set the background/clear color.

### `luna.graphics.getBackgroundColor()`
Returns the current background color.

**Returns:** `r, g, b` (three numbers)

### `luna.graphics.rectangle(mode, x, y, width, height [, rx, ry])`
Draw a rectangle, optionally with rounded corners.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `mode` | string | — | `"fill"` or `"line"` |
| `x` | number | — | X position |
| `y` | number | — | Y position |
| `width` | number | — | Width |
| `height` | number | — | Height |
| `rx` | number | 0 | Corner radius X |
| `ry` | number | 0 | Corner radius Y |

### `luna.graphics.circle(mode, x, y, radius)`
Draw a circle.

| Parameter | Type | Description |
|-----------|------|-------------|
| `mode` | string | `"fill"` or `"line"` |
| `x` | number | Center X |
| `y` | number | Center Y |
| `radius` | number | Circle radius |

### `luna.graphics.ellipse(mode, x, y, rx, ry)`
Draw an ellipse.

| Parameter | Type | Description |
|-----------|------|-------------|
| `mode` | string | `"fill"` or `"line"` |
| `x` | number | Center X |
| `y` | number | Center Y |
| `rx` | number | Horizontal radius |
| `ry` | number | Vertical radius |

### `luna.graphics.triangle(mode, x1, y1, x2, y2, x3, y3)`
Draw a triangle.

### `luna.graphics.polygon(mode, x1, y1, x2, y2, ...)`
Draw a polygon. Requires at least 3 vertices (6 numbers).

### `luna.graphics.line(x1, y1, x2, y2)`
Draw a line between two points.

### `luna.graphics.setLineWidth(width)`
Set the line width for stroke operations.

### `luna.graphics.getLineWidth()`
Returns the current line width.

**Returns:** number

### `luna.graphics.print(text, x, y [, scale])`
Draw text at the given position.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `text` | string | — | Text to draw |
| `x` | number | — | X position |
| `y` | number | — | Y position |
| `scale` | number | 1.0 | Text scale factor |

### `luna.graphics.draw(imageIndex, x, y)`
Draw a loaded image.

| Parameter | Type | Description |
|-----------|------|-------------|
| `imageIndex` | number | Index from `newImage()` |
| `x` | number | X position |
| `y` | number | Y position |

### `luna.graphics.newImage(path)`
Load an image file and return its index.

**Returns:** number (image index for use with `draw()`)

### `luna.graphics.getDimensions()`
Get the window dimensions.

**Returns:** `width, height` (two numbers)

### `luna.graphics.push()`
Push the current transform matrix onto the stack. Use with `pop()` to isolate transforms.

```lua
luna.graphics.push()
luna.graphics.translate(100, 50)
luna.graphics.rotate(0.3)
luna.graphics.rectangle("fill", 0, 0, 32, 32)
luna.graphics.pop()
```

### `luna.graphics.pop()`
Pop the top transform matrix from the stack, restoring the previous transform.

### `luna.graphics.translate(x, y)`
Translate the current transform.

| Parameter | Type | Description |
|-----------|------|-------------|
| `x` | number | X offset |
| `y` | number | Y offset |

### `luna.graphics.rotate(angle)`
Rotate the current transform.

| Parameter | Type | Description |
|-----------|------|-------------|
| `angle` | number | Rotation in radians |

### `luna.graphics.scale(sx [, sy])`
Scale the current transform. If `sy` is omitted, uniform scale is applied.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `sx` | number | — | Horizontal scale factor |
| `sy` | number | `sx` | Vertical scale factor |

### `luna.graphics.arc(mode, x, y, radius, angle1, angle2 [, segments])`
Draw an arc.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `mode` | string | — | `"fill"` or `"line"` |
| `x` | number | — | Center X |
| `y` | number | — | Center Y |
| `radius` | number | — | Arc radius |
| `angle1` | number | — | Start angle in radians |
| `angle2` | number | — | End angle in radians |
| `segments` | number | 32 | Number of line segments |

```lua
luna.graphics.arc("fill", 200, 200, 60, 0, math.pi)
```

### `luna.graphics.newQuad(x, y, w, h, sw, sh)`
Define a sub-rectangle of a texture (a quad).

| Parameter | Type | Description |
|-----------|------|-------------|
| `x` | number | Left edge within the texture |
| `y` | number | Top edge within the texture |
| `w` | number | Region width |
| `h` | number | Region height |
| `sw` | number | Total texture width |
| `sh` | number | Total texture height |

**Returns:** table `{x, y, w, h, sw, sh}`

```lua
local frame = luna.graphics.newQuad(0, 0, 32, 32, 128, 128)
```

### `luna.graphics.drawEx(image_id, x, y [, rotation [, sx [, sy [, ox [, oy]]]]])`
Draw an image with a full affine transform.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `image_id` | number | — | Index from `newImage()` |
| `x` | number | — | X position |
| `y` | number | — | Y position |
| `rotation` | number | 0 | Rotation in radians |
| `sx` | number | 1 | Horizontal scale |
| `sy` | number | 1 | Vertical scale |
| `ox` | number | 0 | Origin offset X (pixels) |
| `oy` | number | 0 | Origin offset Y (pixels) |

```lua
luna.graphics.drawEx(img, 200, 150, math.pi / 4, 2, 2, 16, 16)
```

### `luna.graphics.drawQuad(image_id, quad, x, y [, rotation [, sx [, sy [, ox [, oy]]]]])`
Draw a quad region of an image with an affine transform.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `image_id` | number | — | Index from `newImage()` |
| `quad` | table | — | Quad from `newQuad()` |
| `x` | number | — | X position |
| `y` | number | — | Y position |
| `rotation` | number | 0 | Rotation in radians |
| `sx` | number | 1 | Horizontal scale |
| `sy` | number | 1 | Vertical scale |
| `ox` | number | 0 | Origin offset X (pixels) |
| `oy` | number | 0 | Origin offset Y (pixels) |

```lua
local frame1 = luna.graphics.newQuad(0, 0, 32, 32, 128, 128)
luna.graphics.drawQuad(img, frame1, 100, 100)
```

### `luna.graphics.polyline(x1, y1, x2, y2, ...)`
Draw an open multi-segment polyline. Requires at least 2 points (4 values).

```lua
luna.graphics.polyline(10, 10, 100, 50, 200, 20, 300, 80)
```

---

## luna.window

Window management.

### `luna.window.setTitle(title)`
Set the window title.

### `luna.window.getTitle()`
Get the current window title.

**Returns:** string

### `luna.window.getWidth()`
Get the window width.

**Returns:** number

### `luna.window.getHeight()`
Get the window height.

**Returns:** number

### `luna.window.getDimensions()`
Get the window dimensions.

**Returns:** `width, height` (two numbers)

---

## luna.input (keyboard)

### `luna.keyboard.isDown(key)`
Check if a key is currently held down.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Key name (e.g. `"space"`, `"a"`, `"left"`) |

**Returns:** boolean

---

## luna.input (mouse)

### `luna.mouse.getPosition()`
Get the current mouse position.

**Returns:** `x, y` (two numbers)

### `luna.mouse.getX()`
Get the mouse X position.

**Returns:** number

### `luna.mouse.getY()`
Get the mouse Y position.

**Returns:** number

### `luna.mouse.isDown(button)`
Check if a mouse button is held.

| Parameter | Type | Description |
|-----------|------|-------------|
| `button` | number | 1=left, 2=right, 3=middle |

**Returns:** boolean

---

## luna.timer

### `luna.timer.getDelta()`
Get the time between the last two frames.

**Returns:** number (seconds)

### `luna.timer.getFPS()`
Get the current frames per second.

**Returns:** number

### `luna.timer.getTime()`
Get total elapsed time since engine start.

**Returns:** number (seconds)

---

## luna.math

Mathematical functions and utilities.

### Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `luna.math.pi` | 3.14159... | Pi |
| `luna.math.huge` | inf | Positive infinity |

### `luna.math.sin(x)` / `luna.math.cos(x)` / `luna.math.tan(x)`
Trigonometric functions (radians).

### `luna.math.asin(x)` / `luna.math.acos(x)` / `luna.math.atan2(y, x)`
Inverse trigonometric functions.

### `luna.math.sqrt(x)`
Square root.

### `luna.math.abs(x)`
Absolute value.

### `luna.math.floor(x)` / `luna.math.ceil(x)`
Floor and ceiling.

### `luna.math.min(a, b)` / `luna.math.max(a, b)`
Minimum and maximum.

### `luna.math.clamp(x, min, max)`
Clamp a value to a range.

**Returns:** number

### `luna.math.random([min, max])`
Generate a random number. With no args returns 0.0–1.0. With min/max returns a float in that range.

### `luna.math.distance(x1, y1, x2, y2)`
Euclidean distance between two points.

**Returns:** number

### `luna.math.lerp(a, b, t)`
Linear interpolation between `a` and `b` by factor `t`.

**Returns:** number

### `luna.math.normalize(x, y)`
Normalize a 2D vector.

**Returns:** `nx, ny` (two numbers)

---

## luna.physics

Simple AABB physics with gravity.

### `luna.physics.newWorld(gravity_x, gravity_y)`
Create a new physics world.

**Returns:** number (world_id)

### `luna.physics.newBody(world_id, x, y, body_type)`
Create a body in a world.

| Parameter | Type | Description |
|-----------|------|-------------|
| `world_id` | number | World from `newWorld()` |
| `x` | number | Initial X position |
| `y` | number | Initial Y position |
| `body_type` | string | `"dynamic"` or `"static"` |

**Returns:** number (body_id)

### `luna.physics.getBody(world_id, body_id)`
Get body state.

**Returns:** `x, y, vx, vy` (four numbers)

### `luna.physics.setBodySize(world_id, body_id, width, height)`
Set the body's collision rectangle size.

### `luna.physics.setBodyVelocity(world_id, body_id, vx, vy)`
Set the body's velocity.

### `luna.physics.step(world_id, dt)`
Step the physics simulation forward.

---

## luna.audio

Sound loading and playback.

### `luna.audio.newSource(path)`
Load an audio file (WAV, MP3, OGG, FLAC).

**Returns:** number (source_id)

### `luna.audio.play(source_id)`
Play a loaded audio source.

### `luna.audio.stop(source_id)`
Stop a playing audio source.

### `luna.audio.setVolume(source_id, volume)`
Set volume for a source (0.0–1.0).

### `luna.audio.getVolume(source_id)`
Get volume for a source.

**Returns:** number

---

## luna.filesystem

Sandboxed file I/O within the game directory.

### `luna.filesystem.read(path)`
Read a file's contents as a string.

**Returns:** string

### `luna.filesystem.write(path, data)`
Write a string to a file.

### `luna.filesystem.exists(path)`
Check if a file exists.

**Returns:** boolean

---

## luna.event

Engine event control.

### `luna.event.quit([exit_code])`
Request engine shutdown.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `exit_code` | number | 0 | Process exit code |

---

## luna.system

Engine information.

### `luna.system.getOS()`
Get the operating system name.

**Returns:** string (`"Windows"`, `"Linux"`, `"macOS"`, `"Unknown"`)

### `luna.system.getVersion()`
Get the engine version string.

**Returns:** string (e.g. `"0.2.0"`)

### `luna.system.getInfo()`
Get a table with engine information.

**Returns:** table with fields:
- `engine` — `"Luna2D"`
- `version` — version string
- `lua_version` — `"Lua 5.4"`
- `renderer` — renderer/backend identifier string reported by the current engine build

---

## Configuration (conf.lua)

Optional `conf.lua` in your game directory to configure the engine before startup:

```lua
function luna.conf(t)
    t.window.title = "My Game"
    t.window.width = 1280
    t.window.height = 720
    t.window.vsync = true
    t.window.resizable = false
    t.performance.target_fps = 60
end
```

### Window Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `t.window.title` | string | `"Luna2D"` | Window title |
| `t.window.width` | number | 800 | Window width |
| `t.window.height` | number | 600 | Window height |
| `t.window.vsync` | boolean | true | VSync enabled |
| `t.window.resizable` | boolean | false | Resizable window |

### Performance Config

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `t.performance.target_fps` | number | 60 | Target FPS |
