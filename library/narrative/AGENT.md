# `narrative` â€” Agent Reference (Lunasome)

| Property       | Value                                                                                                                                                           |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Tier**       | Tier 3 â€” Lunasome (pure Lua)                                                                                                                                    |
| **Source**     | `library/narrative/init.lua`                                                                                                                                    |
| **Lua Tests**  | `tests/lua/library/test_library_narrative.lua`                                                                                                                  |
| **Depends on** | `lurek.filesystem.read` (loadFile), `lurek.serial` (precompile blobs), `lurek.i18n.t` (optional), `lurek.log.debug` (trace), `lurek.save` (collector wiring) |
| **Status**     | partial â€” usable Ink subset; full Ink parity is non-goal                                                                                                        |

## Purpose

Pure-Lua interpreter for an Ink-flavoured branching narrative language with
knots, diverts, sticky choices, conditional choices, variables, inline value
substitution, tags, and visit counters. Coexists with `library.dialog`
(barks/menus); `narrative` is for scripted scenes and branching prose.

## Public API

### Loaders
- `M.compile(source) -> Story`
- `M.loadFile(path) -> Story` (uses `lurek.filesystem.read`)
- `M.precompile(source) -> bytecode`
- `M.fromBytecode(blob) -> Story`

### Story lifecycle
- `story:start(knot?)` â€” reset to entry knot (default `START` or first knot)
- `story:canContinue() / isAtChoice() / isEnded()`
- `story:continue() -> string?, tags`
- `story:continueAll(sep?) -> string`
- `story:getChoices() -> {{text, available, tags, index}}`
- `story:choose(index)`

### Variables & functions
- `story:setVar(name, value) / getVar(name) / listVars()`
- `story:bindFunction(name, fn)`
- `story:onTag(tag, fn) -> handle / offTag(handle)`
- `story:onVarChange(name, fn) -> handle`

### Flow control
- `story:gotoKnot(name)` (alias `divertTo`)
- `story:visit(knot) -> count`
- `story:turnsSince(knot) -> int`
- `story:save() -> blob / resume(blob)`

### Module helpers
- `M.parseTagList(str)`
- `M.weightedChoice(choices, rng)`
- `M.formatList(values, conjunction?)`
- `M.localiseStory(story, locale?)` â€” wraps `lurek.i18n.t` over `{loc:key}` markers

## Supported Ink Subset

```ink
=== knot ===
Plain prose. {variable} {fn(arg)} interpolation.
~ flag = true            -- in-line assignment
-> next_knot             -- divert
* { cond } text          -- one-shot, optional condition
+ text | -> target       -- sticky, with inline divert
# tag                    -- attach tag to last line
VAR name = value         -- declare initial variable
// comment
-> END                   -- end story
```

## Dependencies

- **`lurek.filesystem.read`** â€” reads `.ink` files for `M.loadFile`.
- **`lurek.serial`** â€” caller may persist `precompile` output via JSON.
- **`lurek.i18n.t`** â€” only used if `M.localiseStory` is invoked.
- **`lurek.log.debug`** â€” used when `story:trace(true)` is enabled.
- **`lurek.save`** â€” caller wires `story:save()/resume()` collectors.

## Status

`partial` â€” implements a usable subset that covers ~90% of typical branching
prose. Out of scope for v1: stitches (`= stitch_name`), threads, lists,
gather points (`-`), tunnels (`->-> knot ->->`), external functions, ink-side
random selectors. These can be layered later without API breakage.

## Examples

See `library/narrative/example.lua` for a multi-knot story exercising
choices, conditions, tags, and save/resume.

## Notes

- The parser is line-based; multi-line prose gets one node per source line.
  Emit blank `say` lines from your renderer if you need explicit paragraph
  breaks beyond what the source text provides.
- Inline `{expr}` markers run through a sandboxed `load()` pointing at the
  story's `_vars` and `_fns` tables â€” host globals are not visible.
- `story:save()` only persists scalar (number/string/boolean) variables;
  table-valued variables are skipped to keep the blob safely round-trippable
  through `lurek.serial.toJson`.
- `M.localiseStory` is a thin wrapper â€” it translates `{loc:KEY}` markers
  found in already-substituted prose; richer i18n (gendered plurals, etc.)
  belongs in `lurek.i18n` itself.

