# `library.dialog`

A pure-Lua replacement for the former `lurek.dialog` Rust binding.
No engine dependencies; works in headless test VMs.
Optional: uses `lurek.log.debug()` when available for dialog progression tracing.

Usage:
local dialog = require("library.dialog")
local seq = dialog.newSequencer()
seq:setSpeed(25)
seq:on("line", function(speaker, text) print(speaker..": "..text) end)
seq:load({ {type="say",speaker="Alice",text="Hello!"} })
seq:start()
-- each frame: seq:update(dt)
-- on input:   seq:advance()  /  seq:choose(1)

*26 functions, 0 module fields documented.*

See: [`lurek.patterns.newEventBus`](../lua-api.md#lurekpatternsneweventbus) — optional event bus mirror returned by `seq:getEventBus()`, [`lurek.event.newSignal`](../lua-api.md#lureksignalnewsignal) — alternative scoped pub/sub backbone, [`lurek.i18n.t`](../lua-api.md#lureklocalizationt) — translate `say`/`choice` text fields before passing them in, [`lurek.serial.toJson`](../lua-api.md#lurekcodectojson) — serialise/deserialise script node arrays for persistence

## Functions

### `newSequencer()`

Create a new dialog sequencer. The sequencer runs a list of dialog nodes one at a time, revealing typewriter-style text, pausing for choices, and firing named callbacks. States: "idle"    ÔÇö no script loaded or sequence ended, not started "typing"  ÔÇö revealing the current line character by character "waiting" ÔÇö current line fully revealed, waiting for advance() "choice"  ÔÇö waiting for the player to call choose(index) "paused"  ÔÇö a "wait" node is counting down "done"    ÔÇö sequence finished

**Returns**

- *table* — Sequencer object.

### `load(nodes)`

Load a new script, replacing any existing one. Call start() afterwards to begin playback.

**Parameters**

- `nodes` *table* — Array of node tables (nil treated as empty).

### `start()`

Begin playback from the first node.

### `update(dt)`

Advance per-frame. Call every frame while isActive() is true.

**Parameters**

- `dt` *number* — Delta time in seconds (clamped to >= 0).

### `advance()`

Advance past the current line (when state == "waiting" or "typing"). If typing, skips to full reveal first. If waiting, moves to next node.

### `skip()`

Skip the entire current line instantly (advances to "waiting").

### `choose(index)`

Select a choice option by 1-based index. Only valid when state == "choice".

**Parameters**

- `index` *number* — 1-based index into getChoiceLabels().

### `setSpeed(cps)`

Set the typewriter reveal speed.

**Parameters**

- `cps` *number* — Characters per second (default: 20).

### `getSpeed()`

Get the current reveal speed.

**Returns**

- *number* — Characters per second.

### `getState()`

Get the current state string.

**Returns**

- *string* — One of: "idle", "typing", "waiting", "choice", "paused", "done".

### `isActive()`

Returns true while the sequence is in progress (not idle or done).

**Returns**

- *boolean*

### `isWaitingForChoice()`

Returns true when a choice is pending player input.

**Returns**

- *boolean*

### `currentSpeaker()`

Returns the speaker name of the current "say" node.

**Returns**

- *string*

### `currentText()`

Returns the full text of the current "say" node.

**Returns**

- *string*

### `revealedText()`

Returns only the revealed portion of the current text.

**Returns**

- *string*

### `getChoiceText()`

Returns the prompt text of the current "choice" node.

**Returns**

- *string*

### `getChoiceLabels()`

Returns an array of choice labels for the current "choice" node.

**Returns**

- *table* — Array of strings.

### `on(event, fn)`

Register a callback for a named event. Events: "line" (speaker, text), "choice" (), "finished" (), "done" (), "event" (name, data), "typewrite" (char, full_text).

**Parameters**

- `event` *string* — Event name.
- `fn` *function* — Callback function.

### `off(event)`

Unregister all callbacks for a named event.

**Parameters**

- `event` *string* — Event name.

### `getEventBus()`

Return the optional `lurek.patterns` EventBus mirror, or nil when the engine is not present. External systems can subscribe to any of the sequencer's events through the bus without going through `seq:on()`. The canonical event delivery path remains the local handler table, so the bus is purely a parallel observer channel.

**Returns**

- *table|nil* — EventBus instance, or nil when unavailable.

See: [`lurek.patterns.newEventBus`](../lua-api.md#lurekpatternsneweventbus)

### `say(actor, text, opts)`

Create a `say` dialog node (spoken line with typewriter reveal).

**Parameters**

- `actor` *string* — Speaker name.
- `text` *string* — Line to reveal.
- `opts` *table* — Optional extra fields merged into the node (e.g. cond, label).

**Returns**

- *table* — Node table: { type="say", speaker, text, ... }.

### `choice(prompt, options, opts)`

Create a `choice` dialog node (branching prompt).

**Parameters**

- `prompt` *string* — Prompt text shown above options.
- `options` *table* — Array of { label, branch } tables.
- `opts` *table* — Optional extra fields merged into the node.

**Returns**

- *table* — Node table: { type="choice", text, options, ... }.

### `wait(seconds, opts)`

Create a `wait` dialog node (timed pause).

**Parameters**

- `seconds` *number* — Duration of the pause in seconds.
- `opts` *table* — Optional extra fields merged into the node.

**Returns**

- *table* — Node table: { type="wait", time, ... }.

### `event(name, data, opts)`

Create an `event` dialog node (named hook signal). When executed, fires `seq:on("event", fn)` with (name, data) then advances.

**Parameters**

- `name` *string* — Event name.
- `data` *any* — Optional payload passed to the callback.
- `opts` *table* — Optional extra fields merged into the node.

**Returns**

- *table* — Node table: { type="event", name, data, ... }.

### `call(fn, opts)`

Create a `call` dialog node (inline Lua callback). When executed, calls `fn()` immediately and advances without pausing.

**Parameters**

- `fn` *function* — Callback to invoke.
- `opts` *table* — Optional extra fields merged into the node.

**Returns**

- *table* — Node table: { type="call", fn, ... }.

### `jump(target, opts)`

Create a `jump` dialog node (label-based control transfer). Execution resumes at the first node in the current script whose `.label` field equals `target`. Unknown targets are silently skipped.

**Parameters**

- `target` *string* — Target label name.
- `opts` *table* — Optional extra fields merged into the node.

**Returns**

- *table* — Node table: { type="jump", target, ... }.
