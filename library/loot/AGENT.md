# `loot` â€” Agent Reference (Lunasome)

| Property       | Value                                                                                                        |
| -------------- | ------------------------------------------------------------------------------------------------------------ |
| **Tier**       | Tier 3 â€” Lunasome (pure Lua)                                                                                 |
| **Source**     | `library/loot/init.lua`                                                                                      |
| **Lua Tests**  | `tests/lua/library/test_library_loot.lua`                                                                    |
| **Depends on** | `lurek.math.newRandomGenerator` (sampling), `lurek.serial.fromToml` + `lurek.filesystem.read` (TOML loader, optional) |
| **Status**     | full                                                                                                         |

## Purpose

Designer-friendly weighted random tables, drop DSL, and pity timers. Built on
the Walkerâ€“Vose alias method for O(1) sampling. Plugs the gap between
`lurek.math.RandomGenerator` (uniform draws only) and the gameplay-shaped loot
needs of RPGs and roguelikes.

## Public API

### `LootTable`
- `M.newTable()` â€” empty table
- `M.fromList({{id, weight, meta?}, ...})`
- `M.fromToml(path)` â€” load via `lurek.filesystem.read` + `lurek.serial.fromToml`
- `M.merge(t1, t2, ...)` â€” combine, summing weights of duplicate ids
- `tbl:add(id, weight, meta?)`
- `tbl:remove(id)`
- `tbl:setWeight(id, w)`
- `tbl:sample(rng?) -> id, meta`
- `tbl:sampleN(n, rng?, opts?) -> {id, ...}` â€” `opts.unique=true` for without-replacement
- `tbl:weightOf(id)` / `tbl:totalWeight()` / `tbl:probability(id)` / `tbl:ids()` / `tbl:clone()`

### `DropSet`
- `M.newDrop()`
- `drop:roll(table, opts?)` â€” `{count, chance, tag}`
- `drop:guarantee(id, count?)`
- `drop:when(predicate_fn)` â€” gates subsequent clauses
- `drop:resolve(context, rng?) -> {{id, count, meta, tag}, ...}`
- `drop:explain(context) -> string`

### `Pity`
- `M.newPity(target_id, threshold)`
- `pity:notice(result_id) -> primed`
- `pity:reset()`
- `pity:getCounter()` / `pity:isPrimed()`
- `pity:save() / pity:restore(blob)`

### `Modifier`
- `M.newModifier()`
- `mod:add(name, fn)` â€” `fn(entry, context) -> multiplier`
- `mod:apply(table, context) -> LootTable` (new view)

### Module RNG
- `M.setDefaultRng(rng)` / `M.getDefaultRng()`

## Dependencies

- **`lurek.math.newRandomGenerator`** â€” module RNG default (lazy resolved; falls back to `math.random` if the binding is unavailable, e.g. headless host).
- **`lurek.serial.fromToml`** â€” TOML parser used by `M.fromToml` (optional).
- **`lurek.filesystem.read`** â€” sandboxed file read used by `M.fromToml` (optional).

## Status

`full` â€” alias-method core, drop DSL, pity, and modifier-view all implemented and tested.

## Examples

See `library/loot/example.lua` for a runnable boss-encounter loot
demo with magic-find modifier and a rare-ring pity timer.

## Notes

- The alias table rebuilds lazily on the next `:sample` after an `add/remove/setWeight`.
- `sampleN(n, rng, {unique=true})` clones the table and drains it; cost is
  O(n Ă— log entries). For large `n` against small tables, prefer plain
  `sampleN` and accept duplicates.
- `Pity:notice` must be called once per draw; failing to do so leaves the
  counter stale.
- `DropSet:when(fn)` gates **all** subsequent clauses, not just the next one;
  call `drop:when(function() return true end)` or build a new DropSet to clear.

