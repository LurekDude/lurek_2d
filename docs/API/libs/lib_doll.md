# `library.doll`

library.doll — Socket-Based Visual Composition Engine
Assembles composite visual objects (characters, vehicles, faces) from
interchangeable Part sprites attached to named Socket positions on a
DollTemplate blueprint. No physics, no collision, no gameplay logic —
purely visual composition with draw ordering.

The library never calls rendering APIs directly; it produces a sorted
draw list via `Doll:getDrawList()` that the caller hands to its renderer
(typically `lurek.render`). The legacy `Doll:draw()` method is retained
as a deprecated no-op for source compatibility.

*25 functions, 0 module fields documented.*

See: [`lurek.render`](../lua-api.md#lurekgraphic) — caller-side renderer that consumes `getDrawList()` entries, [`lurek.image`](../lua-api.md#lurekimg) — image/texture loader for `Part:setTexture()`, [`lurek.serial.toJson`](../lua-api.md#lurekcodectojson) — serialise template + part state for persistence

## Functions

### `newPart()`

Create a new Part (visual element for attaching to a Doll socket). Parts carry texture, transform, colour, flip, draw-order, and arbitrary key-value attributes. Attach to a Doll socket with `doll:attach()`.

**Returns**

- *Part* — blank part with defaults

### `getTexture()`

Texture / Quad

### `getOffset()`

Local Transform

### `setScale(sx, sy)`

Set part scale. Passing a single number sets uniform scale.

**Parameters**

- `sx` *number* — horizontal scale
- `sy` *number* — vertical scale

### `getDrawOrder()`

Draw Order & Type

### `setDrawOrder(n)`

Set part draw order (z-sort key).

**Parameters**

- `n` *number* — draw order value

### `isVisible()`

Visibility & Appearance

### `getFollowsRotation()`

Behaviour

### `getAttribute(key)`

Attributes (user-defined key-value store)

### `getFixture()`

Optional physics fixture ref (stored, never called)

### `getAbsoluteScale()`

Get the absolute scale magnitude, ignoring flip. Useful when flip is used for mirroring but the caller needs the positive magnitude (e.g. bounding-box calculation).

**Returns**

- *number* — absolute scaleX
- *number* — absolute scaleY

### `getAttributes()`

Get a shallow copy of all attributes.

**Returns**

- *table* — key-value copy of all stored attributes

### `newTemplate(name)`

Create a new DollTemplate (socket layout blueprint). A template defines named sockets at fixed positions and rotations. Each socket has an acceptType filter and a drawOrder for z-sorting.

**Parameters**

- `name` *string* — template name

**Returns**

- *DollTemplate* — empty template

### `addSocket(socketName, acceptType, x, y, rotation, drawOrder)`

Add a socket to the template. Returns true on success, or false plus a message if the name is invalid or already registered.

**Parameters**

- `socketName` *string* — unique socket name (non-empty)
- `acceptType` *string* — part type filter ("" = accept anything)
- `x` *number* — offset X from doll origin
- `y` *number* — offset Y from doll origin
- `rotation` *number* — socket rotation in radians
- `drawOrder` *number* — z-sort key

**Returns**

- *boolean* — success
- *string* — error message on failure

### `_iterSockets()`

Internal: iterate raw sockets (used by Doll).

### `newDoll(template)`

Create a new Doll (runtime composite instance of a template). A Doll binds a DollTemplate to a world-space transform and holds Part instances attached to template sockets.

**Parameters**

- `template` *DollTemplate* — socket layout to use

**Returns**

- *Doll* — runtime doll instance

### `getPosition()`

Transform

### `getTemplate()`

Template

### `isVisible()`

Visibility

### `getBody()`

Optional body / user data refs

### `attach(socketName, part)`

Attach a Part to a named socket. Returns false if socket not found, type mismatch, or invalid args.

**Parameters**

- `socketName` *string* — socket to attach to
- `part` *Part* — part instance to attach

**Returns**

- *boolean* — success

### `detach(socketName)`

Detach the Part from a socket, returning it.

**Parameters**

- `socketName` *string* — socket to detach from

**Returns**

- *Part|nil* — detached part, or nil if socket was empty

### `getDrawList()`

Compute world-transform draw list sorted by drawOrder. Each entry: {socketName, part, x, y, rotation, scaleX, scaleY, originX, originY, drawOrder}. **Flip behaviour**: Part flip flags produce negative scale values (e.g. scaleX = -2 when flipX is true and doll+part scale = 2). This is intentional — GPU scale-based mirroring. Use `doll.getAbsoluteScale(entry)` if you need the positive magnitude. **Transform order**: Part offset is rotated by socket rotation before being added to the socket position (socket-local space). The combined offset is then scaled by doll scale and rotated by doll rotation. Does NOT filter by part visibility — caller handles that.

**Returns**

- *table* — ordered draw list

### `draw()` *(deprecated)*

Deprecated convenience draw shim — retained only as a no-op. The original implementation referenced an undefined global (`luna`) and a non-existent namespace (`lurek.render`), so the call chain was a silent no-op in every build. Library code must not call rendering APIs directly (per `library.*` conventions), so the correct path now is for the caller to iterate `Doll:getDrawList()` and dispatch the entries to `lurek.render` (or any other renderer) themselves. This method emits a one-time warning on first invocation and then returns immediately. It will be removed in a future major bump.

See: [`lurek.render`](../lua-api.md#lurekgraphic)

### `getAbsoluteScale(entry)`

Get the absolute scale magnitude from a draw-list entry. Strips the sign introduced by flip flags, returning positive values.

**Parameters**

- `entry` *table* — a draw-list entry from Doll:getDrawList()

**Returns**

- *number* — absolute scaleX
- *number* — absolute scaleY
