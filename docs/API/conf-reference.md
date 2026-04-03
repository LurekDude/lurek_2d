# Luna2D `conf.lua` Reference

Configuration for a Luna2D game lives in an optional `conf.lua` file at the root of the game directory. The engine calls `luna.conf(t)` with a pre-populated table before the window is created, so you can override any value.

```lua
function luna.conf(t)
    t.window.title  = "My Game"
    t.window.width  = 1280
    t.window.height = 720
end
```

If `conf.lua` is absent or the function is not defined, all fields keep their engine defaults.

---

## `t.window` — Window settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `title` | `string` | `"Luna2D vX.Y"` | Title bar text. |
| `width` | `integer` | `800` | Window width in pixels. |
| `height` | `integer` | `600` | Window height in pixels. |
| `vsync` | `boolean` | `true` | Enable vertical synchronisation. |
| `fullscreen` | `boolean` | `false` | Launch in fullscreen mode. |
| `resizable` | `boolean` | `false` | Allow the user to resize the window. |
| `minwidth` | `integer` | `0` (unset) | Minimum window width. `0` means no minimum. |
| `minheight` | `integer` | `0` (unset) | Minimum window height. `0` means no minimum. |
| `borderless` | `boolean` | `false` | Remove window decorations (title bar, borders). |
| `icon` | `string` | `""` (unset) | Path to a window-icon image, relative to the game directory. |
| `displayindex` | `integer` | `0` | Monitor index for initial window placement. `0` is the primary monitor. |
| `scalemode` | `string` | `"none"` | **[New]** Viewport scaling mode. Valid values: `"none"`, `"letterbox"`, `"stretch"`, `"pixel"`. |
| `gamewidth` | `integer` | `0` (match window) | **[New]** Logical game resolution width in virtual pixels. `0` means use the window width. |
| `gameheight` | `integer` | `0` (match window) | **[New]** Logical game resolution height in virtual pixels. `0` means use the window height. |
| `maximized` | `boolean` | `false` | **[New]** Start the window maximized. |

### Scale modes

| Mode | Behaviour |
|------|-----------|
| `"none"` | No scaling. The game canvas matches the window size. `gamewidth`/`gameheight` are ignored. |
| `"letterbox"` | The game canvas is scaled to fit inside the window while preserving aspect ratio. Black bars fill the unused edges. |
| `"stretch"` | The game canvas is stretched to fill the window exactly, ignoring aspect ratio. |
| `"pixel"` | Like `"letterbox"` but only whole-integer scale factors are allowed, preserving pixel-perfect rendering. |

### Example — letterbox scaling

```lua
function luna.conf(t)
    t.window.title      = "Pixel Adventure"
    t.window.width      = 1280
    t.window.height     = 720
    t.window.scalemode  = "letterbox"
    t.window.gamewidth  = 320
    t.window.gameheight = 180
end
```

---

## `t.graphics` — GPU backend settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `backend` | `string` | `"auto"` | Graphics API. Valid values: `"auto"`, `"dx12"`, `"vulkan"`, `"metal"`. `"auto"` uses the best available backend for the platform. |
| `power_preference` | `string` | `"high"` | GPU power hint when multiple adapters are present. Valid values: `"high"` (discrete GPU), `"low"` (integrated GPU), `"none"` (driver decides). |

---

## `t.modules` — Engine subsystem toggles

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `audio` | `boolean` | `true` | Enable the rodio audio subsystem. |
| `physics` | `boolean` | `true` | Enable the rapier2d physics world. |
| `graphics` | `boolean` | `true` | Enable the wgpu graphics pipeline. |
| `input` | `boolean` | `true` | Enable the input subsystem (keyboard, mouse, gamepad). |
| `timer` | `boolean` | `true` | Enable the frame timer. |
| `filesystem` | `boolean` | `true` | Enable the sandboxed virtual filesystem. |

---

## `t.performance` — Frame rate and performance

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `target_fps` | `integer` | `60` | Target frames per second for the game loop. |

---

## `t.log` — Logging

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `file` | `string` | `""` (disabled) | Path to write log output, relative to the game directory. Empty string disables file logging. |
| `append` | `boolean` | `false` | If `true`, append to the log file instead of overwriting it. |
| `level` | `string` | `""` (use default) | Minimum log level to emit. Valid values: `"error"`, `"warn"`, `"info"`, `"debug"`, `"trace"`. |

---

## Top-level keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `identity` | `string` | `nil` | Save-data identity string used to locate the save directory. |
| `version` | `string` | `nil` | Game version string (informational only). |
