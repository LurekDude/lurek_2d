# IDEA — dataframe

| Field  | Value            |
| ------ | ---------------- |
| Module | `dataframe`      |
| Path   | `src/dataframe/` |
| Date   | 2026-04-18       |
| Tier   | Foundations      |

## Mission

Provide a zero-dependency, in-memory column-major tabular data engine for Lurek2D games: named-column DataFrames, a query pipeline (filter/sort/group-by/join), CSV/JSON/binary serialization, and a hand-rolled SQL subset — all available from Lua via `lurek.dataframe.*`.

## Strengths

- **Self-contained SQL engine** — tokenizer, parser, and executor for SELECT/WHERE/GROUP BY/HAVING/JOIN/ORDER BY without any external crate.
- **Rich analytical surface** — rolling windows, rank, pivot, sample, describe, with_eval, plus a full aggregation enum (mean/sum/min/max/count/first/last).
- **Deterministic random data generator** — xorshift64-backed `DataFrame::random()` for reproducible test datasets with typed column definitions.

## Gaps

- `frame.rs` and `query.rs` duplicate a `Xorshift64` PRNG; only one copy should exist.
- No streaming/lazy evaluation; large tables fully materialise every intermediate result.
- `query.rs` at 1565 lines is a candidate for splitting into sub-files.

## Features — Competitor Comparison

| Feature                    | Lurek2D (dataframe)      | LÖVE2D                    | Godot 4                  |
| -------------------------- | ------------------------ | ------------------------- | ------------------------ |
| In-memory SQL queries      | ✅ Hand-rolled SQL subset | ❌ No built-in tabular API | ❌ Requires SQLite plugin |
| CSV/JSON serialization     | ✅ RFC 4180 + JSON AoO    | ❌ Manual or lib           | ❌ Manual or plugin       |
| Pivot / rolling aggregates | ✅ pivot_table, rolling_* | ❌ N/A                     | ❌ N/A                    |

## Performance / Quality

- All query ops (`filter`, `sort`, `group_by`, `join`) are O(n·m) or better for typical sizes but use naive quadratic dedup in `unique()`.
- The SQL tokenizer scans char-by-char in a single pass; no regex overhead.
- `serial.rs` CSV parser handles RFC 4180 edge cases (quoted fields, embedded newlines, escaped quotes).

## Test Gaps

- `frame.rs` (1222 lines) — had **no tests**; new `frame_tests.rs` added (17 tests).
- `query.rs` (1565 lines) — had **no tests**; new `query_tests.rs` added (13 tests).
- `serial.rs` and `sql.rs` already have inline `#[cfg(test)]` suites.
- Missing coverage: `with_eval`, `pivot_table`, `rolling_mean`, `rolling_sum`, `rank_column`, `random` edge cases, `Database` multi-table SQL.

## TODO(dedup)

- [ ] Extract the duplicated `Xorshift64` from `frame.rs` and `query.rs` into a shared private helper (e.g. `rng.rs` or `crate::math::xorshift`).

## TODO(helper)

- [ ] Split `query.rs` (1565L) — extract grouping/aggregation and join logic into dedicated sub-files.
- [ ] Add `DataFrame::from_rows()` constructor for row-major input (common Lua pattern).
- [ ] Add streaming iterator API for large tables to avoid full materialisation.

## TODO(vectorized) ✅ DONE

- [x] Implement `VecFrame` typed-column vectorized processing layer (`src/dataframe/vectorized.rs`).
  - Typed flat-buffer columns (`Float64`/`Int64`/`Bool`/`Text`) with validity bitmaps.
  - Scalar ops (add/sub/mul/div/abs/sqrt/floor/ceil/neg/clamp) over entire columns.
  - Binary column ops (add/sub/mul/div/min/max between two columns).
  - Reductions (sum/mean/min/max/std/var/count) with null-skip.
  - Filter mask + `apply_mask` for vectorized row filtering.
  - `par_reduce` and `par_scalar_op` for rayon-parallel multi-column processing.
  - GPU path intentionally deferred — would require crossing into `src/compute/`.

## TODO(plugin)

- [ ] Consider a `TIER-2-PLUGIN` extraction so games that don't use tabular data pay no compile-time cost.
- [ ] Plugin boundary: `dataframe` + `sql` as optional Cargo feature gated behind `dataframe` flag.

## Prior Ideas (Migrated)

- ❌ TODO — SQLite Import (`fromSQLite(path, query)`) — no implementation found.
- ❌ TODO — Visualization / Chart Output (`df:plot()`) — no implementation found.
- 🤔 CONSIDER — Move to Tier 3 Pure-Lua Library — requires Architect decision.

## References

- `docs/specs/dataframe.md` — module spec
- `src/lua_api/dataframe_api.rs` — Lua bridge
- `tests/lua/unit/test_dataframe.lua` — Lua test suite
