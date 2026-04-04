# `doll` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Design-stage / Stub (Rust) → **Implemented as Tier 3 Lunasome** |
| **Lua API** | `require("library.doll")` |
| **Source** | `library/doll/init.lua` (active), `src/doll/` (legacy stub) |
| **Tests** | `tests/lua/library/test_library_doll.lua` |

## Summary

Sprite-composition engine for assembling multi-part visual objects —
characters, vehicles, creatures, faces — from interchangeable `Part`
elements attached to named `Socket` positions on a `DollTemplate`. A
`DollTemplate` defines the blueprint of a composite visual: socket layout
with world-offset positions, rotations, and draw-order values. A `Doll` is
a runtime instance of a template; its `slots` map holds the currently
attached Parts per socket. `attach(socketName, part)` and
`detach(socketName)` modify composition at runtime, enabling hot-swap of
weapons, costumes, facial expressions, or damage states without re-reading
assets. `getDrawList()` returns an ordered list of world-transform-resolved
draw records sorted by drawOrder, which the caller renders manually via
`luna.graphics.draw()`. Part compatibility is enforced via string-matched
`acceptType` and `partType` checks so ill-fitting parts are rejected at
attach time, not at render time. Textures and quads are duck-typed raw Lua
values so parts compose naturally with any `luna.graphics` texture handle.

## Architecture

```
DollTemplate (socket layout blueprint)
  ├── name: String
  └── sockets: Vec<Socket { name, acceptType, x, y, rotation, drawOrder }>

Doll (runtime composite instance)
  ├── template: &DollTemplate
  ├── transform: { x, y, rotation, scaleX, scaleY }
  ├── slots: HashMap<socketName, Part>
  ├── attach(socketName, part) / detach(socketName)
  └── getDrawList() → Vec<{ part, worldX, worldY, rotation, drawOrder }>
        (sorted by drawOrder; caller checks part:isVisible() before rendering)

Part (visual element)
  ├── partType: String  (matched against socket acceptType)
  ├── texture, quad   (Lua values — duck-typed)
  ├── offset: { x, y, rotation, scaleX, scaleY }
  ├── visible: bool
  └── color: { r, g, b, a }
```

## luna.doll — Visual Composition Engine

> **Luna2D-specific module** — This module is specific to Luna2D.

## Purpose

Assembles composite visual objects (characters, vehicles, faces) from sprite Parts attached to named Sockets on a Template. No physics, no collision, no gameplay logic — purely visual composition with draw ordering.

## Reimplementation Notes

- **Recommended strategy**: **Pure Lua** — all types are data containers, no GPU drawing (caller uses `getDrawList()` and renders manually)
- Three types: `DollTemplate`, `Doll`, `Part`
- Socket type-checking is string-based (acceptType vs partType)
- Textures, quads, fixtures stored as raw Lua values (duck-typed, no C++ type enforcement)
- `getDrawList()` does NOT filter by visibility — caller must check `part:isVisible()`

---

## Module-Level Functions (`luna.doll.*`)

| Lua API | Parameters | Returns | Description |
|---|---|---|---|
| `luna.doll.newTemplate(name)` | `string` | `DollTemplate` | Create socket layout blueprint |
| `luna.doll.newDoll(template)` | `DollTemplate` | `Doll` | Instantiate runtime composite |
| `luna.doll.newPart()` | — | `Part` | Create blank visual element |

---

## Type: `DollTemplate`

### Methods

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getName()` | — | `string` | |
| `setName(name)` | `string` | — | |
| `addSocket(name [, acceptType, x, y, rotation, drawOrder])` | `string, string?, number?, number?, number?, int?` | — | Defaults: acceptType="", x/y=0, rotation=0, drawOrder=0 |
| `removeSocket(name)` | `string` | `boolean` | false if not found |
| `getSocket(name)` | `string` | `table\|nil` | `{name, acceptType, x, y, rotation, drawOrder}` |
| `getSocketNames()` | — | `{string}` | In definition order |
| `getSocketCount()` | — | `int` | |

---

## Type: `Doll`

### Transform

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getPosition()` | — | `x, y` | |
| `setPosition(x, y)` | `number, number` | — | |
| `getRotation()` | — | `number` | Radians |
| `setRotation(r)` | `number` | — | |
| `getScale()` | — | `sx, sy` | |
| `setScale(sx [, sy])` | `number, number?` | — | sy defaults to sx |

### Template

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getTemplate()` | — | `DollTemplate` | |

### Part Attachment

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `attach(socketName, part)` | `string, Part` | `boolean` | false if socket missing or type mismatch |
| `detach(socketName)` | `string` | `Part\|nil` | Returns detached Part |
| `getPartAt(socketName)` | `string` | `Part\|nil` | |
| `findSocket(part)` | `Part` | `string\|nil` | Reverse lookup |
| `detachAll()` | — | — | |
| `getAttachedSockets()` | — | `{string}` | |
| `getEmptySockets()` | — | `{string}` | |

### Rendering

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getDrawList()` | — | `table` | Sorted by drawOrder ascending |
| `isVisible()` | — | `boolean` | |
| `setVisible(v)` | `boolean` | — | |

**DrawList entry:**
```lua
{ socketName="torso", part=<Part>, x=100, y=200, rotation=0.5, scaleX=1, scaleY=1 }
```

### Optional References

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getBody()` | — | `any\|nil` | Physics Body reference (not simulated) |
| `setBody(body)` | `any\|nil` | — | |
| `getUserData()` | — | `any\|nil` | Arbitrary Lua value |
| `setUserData(value)` | `any\|nil` | — | |

---

## Type: `Part`

### Texture / Quad

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getTexture()` | — | `any\|nil` | |
| `setTexture(drawable)` | `any` | — | Any drawable (Image, Canvas, etc.) |
| `getQuad()` | — | `Quad\|nil` | |
| `setQuad(quad)` | `Quad\|nil` | — | |

### Local Transform

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getOffset()` | — | `x, y` | Relative to socket |
| `setOffset(x, y)` | `number, number` | — | |
| `getRotation()` | — | `number` | Radians |
| `setRotation(r)` | `number` | — | |
| `getScale()` | — | `sx, sy` | |
| `setScale(sx [, sy])` | `number, number?` | — | |
| `getOrigin()` | — | `ox, oy` | Rotation pivot |
| `setOrigin(ox, oy)` | `number, number` | — | |

### Draw Order & Type

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getDrawOrder()` | — | `int` | Lower = behind |
| `setDrawOrder(n)` | `int` | — | |
| `getPartType()` | — | `string` | Type tag for socket matching |
| `setPartType(type)` | `string` | — | |

### Visibility & Appearance

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `isVisible()` | — | `boolean` | |
| `setVisible(v)` | `boolean` | — | |
| `getColor()` | — | `r, g, b, a` | |
| `setColor(r, g, b [, a])` | `number, number, number, number?` | — | a defaults to 1 |
| `getFlip()` | — | `flipX, flipY` | |
| `setFlip(flipX [, flipY])` | `boolean, boolean?` | — | flipY defaults to false |

### Behavior

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getFollowsRotation()` | — | `boolean` | Inherits doll rotation (default true) |
| `setFollowsRotation(f)` | `boolean` | — | false = axis-locked |

### User Attributes

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getAttribute(key)` | `string` | `any\|nil` | |
| `setAttribute(key, value)` | `string, any\|nil` | — | nil deletes |
| `getAttributeKeys()` | — | `{string}` | |

### Optional Physics

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getFixture()` | — | `any\|nil` | |
| `setFixture(fixture)` | `any\|nil` | — | |

---

## Enums

None.

## Dependencies

- `common/Module.h`, `common/Object.h`, `common/runtime.h`
- **No external libraries**

## Registered Types

| Type | Inherits |
|---|---|
| `DollTemplate` | `Object` |
| `Doll` | `Object` |
| `Part` | `Object` |

---

## Game Design Role

- **Character customisation**: Mix and match hair, armour, weapons, accessories as visual layers.
- **Equipment visualisation**: When `luna.inventory` equips an item, `luna.doll` shows it on the character sprite.
- **Animation‑ready**: Draw‑order sorting means parts layer correctly regardless of character facing.
- **Modular art**: Art team creates individual part sprites; doll composites them at runtime.

---

## Module Boundaries

**vs luna.inventory** — Inventory manages *what items* you have and *equip slots* (logical). Doll manages *how equipped items look* (visual). When you equip a helmet: inventory stores it in the "head" equipment slot; doll attaches the helmet Part sprite to the "head" socket.

**vs luna.graphics** — Graphics provides draw primitives (images, quads). Doll orchestrates *multiple* draw calls in correct z‑order for character composition.

**vs luna.entity** — Entity is a generic ECS. A Doll can be a component on a player entity.

**vs luna.gui** — GUI renders UI widgets. Doll renders character visuals. Character preview in a GUI panel would combine both.

---

## Edge Cases & Pitfalls

- **Socket type mismatches**: Attaching a Part to a socket whose `acceptType` doesn't match the Part's `partType` returns false. Always verify `template:getSocket(socketName)` first.
- **Draw order with nil Parts**: Unoccupied sockets draw nothing. If your art relies on a background slot always being filled, assign a default "empty" Part rather than leaving the socket nil.
- **Transform origin**: Part transforms are relative to the Doll's origin point (usually the character's feet or centre). If you authored sprites with different origins, all offsets will be off by a constant — store the origin offset in the Part definition.
- **Shared Templates**: Multiple Dolls can share the same Template. Mutating a Template's socket definition after Dolls are created does not retroactively update those Dolls.
- **Layer numbering gaps**: Draw order is defined by socket `drawOrder` values. Gaps between values are fine and recommended (10, 20, 30 instead of 1, 2, 3) so new sockets can be inserted without renumbering.

---

## Planned / To Implement

- **W2**: Part blending — lerp between two Parts for the same socket (e.g. wound-state overlay)
- **W2**: Procedural inverse-kinematics socket — IK target socket where a Part snaps to a world-space anchor
- **W3**: Runtime Template baking — freeze a composed Doll into a single SpriteBatch for performance

## Purpose

Assembles composite visual objects (characters, vehicles, faces) from sprite Parts attached to named Sockets on a Template. No physics, no collision, no gameplay logic — purely visual composition with draw ordering.

## Reimplementation Notes

- **Recommended strategy**: **Pure Lua** — all types are data containers, no GPU drawing (caller uses `getDrawList()` and renders manually)
- Three types: `DollTemplate`, `Doll`, `Part`
- Socket type-checking is string-based (acceptType vs partType)
- Textures, quads, fixtures stored as raw Lua values (duck-typed, no C++ type enforcement)
- `getDrawList()` does NOT filter by visibility — caller must check `part:isVisible()`

---

## Module-Level Functions (`luna.doll.*`)

| Lua API | Parameters | Returns | Description |
|---|---|---|---|
| `luna.doll.newTemplate(name)` | `string` | `DollTemplate` | Create socket layout blueprint |
| `luna.doll.newDoll(template)` | `DollTemplate` | `Doll` | Instantiate runtime composite |
| `luna.doll.newPart()` | — | `Part` | Create blank visual element |

---

## Type: `DollTemplate`

### Methods

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getName()` | — | `string` | |
| `setName(name)` | `string` | — | |
| `addSocket(name [, acceptType, x, y, rotation, drawOrder])` | `string, string?, number?, number?, number?, int?` | — | Defaults: acceptType="", x/y=0, rotation=0, drawOrder=0 |
| `removeSocket(name)` | `string` | `boolean` | false if not found |
| `getSocket(name)` | `string` | `table\|nil` | `{name, acceptType, x, y, rotation, drawOrder}` |
| `getSocketNames()` | — | `{string}` | In definition order |
| `getSocketCount()` | — | `int` | |

---

## Methods

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `getName()` | — | `string` | |
| `setName(name)` | `string` | — | |
| `addSocket(name [, acceptType, x, y, rotation, drawOrder])` | `string, string?, number?, number?, number?, int?` | — | Defaults: acceptType="", x/y=0, rotation=0, drawOrder=0 |
| `removeSocket(name)` | `string` | `boolean` | false if not found |
| `getSocket(name)` | `string` | `table\|nil` | `{name, acceptType, x, y, rotation, drawOrder}` |
| `getSocketNames()` | — | `{string}` | In definition order |
| `getSocketCount()` | — | `int` | |

---
