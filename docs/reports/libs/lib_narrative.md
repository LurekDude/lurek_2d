# `library.narrative` *(partial)*

Lurek2D narrative library — Ink-flavoured branching narrative interpreter.

Pure-Lua implementation of a usable subset of inkle's Ink scripting language.
Supports knots, diverts, sticky/regular choices, variables, conditional
choices, inline `{var}` and `{fn(arg)}` substitution, tags, visit counters,
and save/resume.

Supported Ink subset:

=== knot_name ===            -- knot header
Plain prose lines.            -- emitted by continue()
-> next_knot                  -- divert
-> END   (or -> DONE)         -- end story
* text                        -- one-shot choice
+ text                        -- sticky choice (re-selectable)
* { condition } text          -- conditional choice
{ variable } / { fn(args) }   -- inline value substitution
# tag                         -- attach tag to last emitted line
VAR name = value              -- declare initial variable
~ name = expr                 -- run-line variable assignment
// line comment               -- ignored

Usage:
local narrative = require("library.narrative")
local story = narrative.compile([[
=== START ===
Hello, {player_name}.
* Greet the king | -> COURT
* Leave silently | -> END
=== COURT ===
The court applauds. # music:fanfare
-> END
]]):start()

*30 functions, 0 module fields documented.*

See: [`lurek.filesystem.read`](../lua-api.md#lurekfsread) — load `.ink` files, [`lurek.serial.toJson`](../lua-api.md#lurekcodectojson) — precompile / save state serialisation, [`lurek.save`](../lua-api.md#lureksavegame) — wire `story:save`/`resume` into a SaveManager, [`lurek.i18n.t`](../lua-api.md#lureklocalizationt) — used by `M.localiseStory` for {loc:key} markers, [`lurek.event`](../lua-api.md#lureksignal) — optional trace event sink

## Functions

### `compile(source)`

Compile Ink-subset source into a Story program (not yet started).

**Parameters**

- `source` *string*

**Returns**

- *Story*

**Raises**

- on parse error.

### `loadFile(path)`

Load and compile a .ink file via `lurek.filesystem.read`.

**Parameters**

- `path` *string*

**Returns**

- *Story*

### `precompile(source)`

Produce a serialisable AST blob (cacheable).

**Parameters**

- `source` *string*

**Returns**

- *table* — bytecode

### `fromBytecode(blob)`

Restore a precompiled program into a fresh Story.

**Parameters**

- `blob` *table*

**Returns**

- *Story*

### `start(knot)`

Reset to the entry knot. Defaults to `START` (or first declared knot).

**Parameters**

- `knot` *string?*

**Returns**

- *Story* — self

### `canContinue()`

True while there is more prose to emit before the next choice or end.

**Returns**

- *boolean*

### `isAtChoice()`

True when the playhead is at a choice point.

### `isEnded()`

True when the story has reached `-> END`.

### `continue()`

Emit the next prose line; returns nil at choice points or end. Also returns the tag list attached to the line.

**Returns**

- *string?,* — table tags

### `continueAll(sep)`

Drain prose until a choice or end, returning the joined string.

**Parameters**

- `sep` *string?* — Line separator (default "\n").

**Returns**

- *string*

### `getChoices()`

Get the current pending choice list.

**Returns**

- *table* — Array of `{text, available, tags, index}`.

### `choose(index)`

Select a choice by 1-based index. Raises if not available.

**Parameters**

- `index` *integer*

**Returns**

- *Story* — self

### `setVar(name, value)`

Set a variable.

### `getVar(name)`

Get a variable.

### `listVars()`

Snapshot of all variables (shallow copy).

### `bindFunction(name, fn)`

Bind a Lua function callable from inside `{name(arg)}` markers.

### `onTag(tag, fn)`

Register a tag handler. Returns an opaque handle for `offTag`.

### `offTag(handle)`

Remove a previously registered tag handler.

### `onVarChange(name, fn)`

Register a variable-change handler.

### `gotoKnot(name)`

Jump to a knot. Records the visit and turn counter.

### `visit(knot)`

Visit count of a knot.

### `turnsSince(knot)`

Turns since a knot was last visited (math.huge if never).

### `trace(enable)`

Toggle trace logging via `lurek.log.debug` (requires it to be available).

### `dumpProfile()`

Profile the current story state (visits + var counts).

### `save()`

Serialise full state (vars, visits, knot, pc) for `lurek.save`.

### `resume(state)`

Restore from a save blob.

### `parseTagList(str)`

Parse a `# tag1 # tag2` style string into an array.

### `weightedChoice(choices, rng)`

Pick a weighted choice from a `{ {text, weight} ... }` list using rng.

### `formatList(values, conjunction)`

Format a list of values as natural prose: "a, b, and c".

### `localiseStory(story, locale)`

Attach a `{loc:KEY}` localisation pre-processor using `lurek.i18n.t`.
