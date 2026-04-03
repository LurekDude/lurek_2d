# CompoundShape / `luna.graphics.newShape()` — Feature Specification

## Feature Summary

`luna.graphics.newShape()` gives game scripts a reusable vector-drawing
resource. Instead of emitting individual `luna.graphics.circle()` /
`luna.graphics.rectangle()` calls every frame, a developer builds up a
`Shape` object once during `luna.load()` and then replays the entire
primitive set — at any position, rotation, and scale — with a single
`shape:draw(x, y)` call inside `luna.draw()`. This is ideal for game objects
made from multiple geometric primitives (tanks, spaceships, UI widgets,
debug overlays) where the internal geometry is fixed but the world transform
changes each frame. Because the command buffer is stored in Rust
(`SharedState::shapes`) and owns no GPU state, creating or clearing a Shape
is allocation-only and never touches the GPU until `draw` is called.

---

## API Method Table

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `luna.graphics.newShape` | `luna.graphics.newShape()` | `Shape` | Creates a new empty compound shape and returns a `Shape` userdata handle. |
| `shape:setColor` | `shape:setColor(r, g, b [, a])` | — | Sets the active draw color for subsequent commands. Components in `[0, 1]`; alpha defaults to `1.0`. |
| `shape:setLineWidth` | `shape:setLineWidth(w)` | — | Sets the stroke width in pixels for subsequently outlined primitives. |
| `shape:rectangle` | `shape:rectangle(mode, x, y, w, h [, rx [, ry]])` | — | Appends a rectangle. If `rx` is provided, draws a rounded rectangle; `ry` defaults to `rx`. `mode` is `'fill'` or `'line'`. |
| `shape:roundedRectangle` | `shape:roundedRectangle(mode, x, y, w, h, rx [, ry])` | — | Appends a rounded rectangle with required corner radii. `ry` defaults to `rx`. |
| `shape:circle` | `shape:circle(mode, x, y, r)` | — | Appends a circle at centre `(x, y)` with radius `r`. |
| `shape:ellipse` | `shape:ellipse(mode, x, y, rx, ry)` | — | Appends an ellipse with semi-axes `rx`, `ry`. |
| `shape:triangle` | `shape:triangle(mode, x1, y1, x2, y2, x3, y3)` | — | Appends a triangle with three explicit vertices. |
| `shape:polygon` | `shape:polygon(mode, x1, y1, x2, y2, ...)` | — | Appends an arbitrary polygon from a flat vararg vertex list (≥ 3 vertices / 6 numbers). |
| `shape:line` | `shape:line(x1, y1, x2, y2)` | — | Appends a single line segment. |
| `shape:polyline` | `shape:polyline(x1, y1, x2, y2, ...)` | — | Appends a connected polyline from a flat vararg point list (≥ 2 points / 4 numbers). |
| `shape:arc` | `shape:arc(mode, x, y, radius, angle1, angle2 [, segments])` | — | Appends an arc (sector or outline). `segments` defaults to `32`. |
| `shape:draw` | `shape:draw(x, y [, angle [, sx [, sy [, ox [, oy]]]]])` | — | Replays all commands at world position `(x, y)` with optional rotation, scale, and origin offset. |
| `shape:clear` | `shape:clear()` | — | Empties the command queue and resets color and line-width state to defaults. |
| `shape:getCommandCount` | `shape:getCommandCount()` | `integer` | Returns the number of commands currently queued. |

### `shape:draw` Parameter Detail

| Parameter | Default | Description |
|-----------|---------|-------------|
| `x` | required | World-space X destination. |
| `y` | required | World-space Y destination. |
| `angle` | `0` | Rotation in radians, applied around the origin. |
| `sx` | `1` | Horizontal scale factor. |
| `sy` | `1` | Vertical scale factor. |
| `ox` | `0` | Origin X offset in object space (shifts the rotation/scale pivot). |
| `oy` | `0` | Origin Y offset in object space. |

---

## Usage Example

```lua
-- Build a tank from geometric primitives (once, in luna.load)
local tank

function luna.load()
    tank = luna.graphics.newShape()

    -- Hull (filled dark-green rectangle)
    tank:setColor(0.2, 0.5, 0.2)
    tank:rectangle("fill", -30, -15, 60, 30)

    -- Turret (lighter-green filled circle)
    tank:setColor(0.3, 0.6, 0.3)
    tank:circle("fill", 0, 0, 14)

    -- Gun barrel (line sticking out from the front)
    tank:setColor(0.15, 0.4, 0.15)
    tank:setLineWidth(5)
    tank:line(0, 0, 35, 0)

    -- Wheels (outlined circles at the four corners)
    tank:setColor(0.1, 0.3, 0.1)
    tank:setLineWidth(2)
    for _, pos in ipairs({ {-20, -15}, {20, -15}, {-20, 15}, {20, 15} }) do
        tank:circle("line", pos[1], pos[2], 8)
    end
end

local angle = 0

function luna.update(dt)
    angle = angle + dt * 0.8  -- slowly rotate the tank
end

function luna.draw()
    -- Replay all tank primitives in one call with the current transform.
    -- The shape's internal geometry stays in object space; only (x, y, angle)
    -- changes per frame.
    tank:draw(400, 300, angle)
end
```

---

## Render Strategy

- `shape:draw(x, y, angle, sx, sy, ox, oy)` pushes a single
  `DrawCommand::DrawShape { shape_key, x, y, rotation, sx, sy, ox, oy }` onto
  the engine's draw-command queue during `luna.draw()`. No CPU work happens at
  push time.
- When `GpuRenderer::render_frame()` processes the queue it finds
  `DrawShape`, pushes a `PushTransform` with the composed translation /
  rotation / scale matrix (origin-offset baked in), then iterates
  `CompoundShape::commands` dispatching each `ShapeCommand` variant through
  the same tessellation paths used by the regular primitive draw calls.
- After all `ShapeCommand` entries are dispatched, a `PopTransform` restores
  the matrix stack to its pre-draw state.
- `SetColor` and `SetLineWidth` commands inside the buffer update renderer
  state exactly as their top-level `DrawCommand` counterparts do — they are
  scoped to the shape's local dispatch loop and do not leak out after
  `PopTransform`.

---

## Storage Model

`CompoundShape` uses **Option A — pooled `SlotMap`**:

- `SharedState::shapes` is a `SlotMap<ShapeKey, CompoundShape>`.
- Every `luna.graphics.newShape()` call inserts a new `CompoundShape` into
  the map and wraps the resulting `ShapeKey` in a `LuaShape` userdata.
- `LuaShape` implements `__gc` via mlua's `add_meta_method`. When the Lua
  garbage collector finalizes a `LuaShape`, the Rust handler removes the
  `CompoundShape` from `SharedState::shapes`, preventing unbounded memory
  growth even if the script discards handles without calling `clear`.
- `ShapeKey` is a generational key (slotmap). Accessing a removed slot
  returns `None`, and all `LuaShape` methods convert `None` to a descriptive
  `LuaError::RuntimeError("Shape handle is no longer valid")` rather than
  panicking.

---

## Known Limitations

- **No `getBounds()`**: The axis-aligned bounding box of the combined
  primitives is not computed by the engine. Games that need bounding-box
  queries must track dimensions manually.
- **No nested shapes**: A `ShapeCommand` cannot reference another
  `CompoundShape`. Composition must be done at the Lua layer by calling
  `draw` multiple times with offset positions.
- **Commands clone per draw call**: The `render_frame` loop iterates
  `CompoundShape::commands` by reference each frame; there is no GPU-side
  cached representation. For shapes with very large command counts
  (> ~500 primitives) a future optimization would pre-bake the vertex buffer
  at `build` time and mark it dirty on mutation. This is not yet implemented.
- **No `destroy()` method**: Shapes are managed by Lua garbage collection
  via `__gc`. There is no explicit `shape:destroy()` API. Callers that need
  deterministic teardown can call `shape:clear()` (which frees the command
  vector but keeps the slot) and then let the handle go out of scope.
- **No per-primitive transform**: All primitives inside a shape share the
  same parent transform applied at `draw` time. Sub-group transforms must be
  baked into vertex coordinates at build time.
