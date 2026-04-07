# dataframe — Feature Analysis

**Tier**: 2 (Extension)
**Spec**: `specs/dataframe.md`
**Files**: Column-major tabular data

## Purpose

Column-oriented tabular data structure for game data analysis, scoring tables, statistics, and data-driven design.

## Current Feature Summary

- `DataFrame`: column-major storage with named columns
- Column types: numeric (f64) and string
- Query operations: filter, sort, group_by, aggregate
- Statistical operations: mean, sum, min, max, std, median per column
- Join operations: inner, left, right joins between DataFrames
- CSV import/export
- Row/column iteration
- Column operations: add, remove, rename, transform
- Missing value handling (NaN)

## Feature Gaps

1. **No pivot tables**: Can't reshape data from long to wide format.
2. **No window functions**: Rolling averages, running totals, rank — common for leaderboards and time series.
3. **No expression-based column creation**: Must transform column-by-column. No `df:eval("health * 1.5 + armor")` expression parsing.
4. **No visualization integration**: Can't plot DataFrame data as charts/graphs directly.
5. **No Excel/SQLite import**: Only CSV. Excel and SQLite are common data sources for game balancing.

## Structural Issues

- **Questionable for a game engine**: DataFrames are a data science tool. Most 2D game developers won't use column-major tabular analysis. The use cases (leaderboards, balance spreadsheets, event analytics) are valid but niche.
- **Overlap with compute**: NdArray (compute) and DataFrame both handle tabular numerical data. DataFrame adds column names and mixed types; NdArray is pure numerical. Consider if both are needed.
- **Better as Tier 3?**: A pure-Lua DataFrame library in `library/dataframe/` would serve the same audience without engine-level overhead.

## Suggestions

1. **Consider moving to Tier 3 library**: `library/dataframe/` as pure Lua — no Rust overhead. Use `luna.serial` for CSV import and `luna.compute` for numerics.
2. **Add window functions**: `df:rollingMean("column", windowSize)` — enables time series analysis, rolling averages for game stats.
3. **Add SQLite import**: `luna.dataframe.fromSQLite(path, query)` — useful for modders and data-driven game design.
4. **Document use cases**: The module is powerful but users need to understand why they'd use DataFrames in a game. Add examples: leaderboard analysis, balance tuning, event log analysis.
5. **Add simple charting**: `df:plot("column", x, y, w, h)` — even a basic bar/line chart for debug overlays would make DataFrames much more practical.

## Competitor Comparison

No competitor 2D game engine has a built-in DataFrame. This is unique but potentially over-engineered for the target audience.

| Feature | Luna2D | Love2D | Solar2D | Bevy | Pandas (ref) |
|---|---|---|---|---|---|
| DataFrame | ✅ | ❌ | ❌ | ❌ | ✅ |
| Group by | ✅ | N/A | N/A | N/A | ✅ |
| Joins | ✅ | N/A | N/A | N/A | ✅ |
| Statistics | ✅ | N/A | N/A | N/A | ✅ |
| Window funcs | ❌ | N/A | N/A | N/A | ✅ |
| Visualization | ❌ | N/A | N/A | N/A | ✅ (matplotlib) |

## Priority

**LOW** — Module is functional but niche. Consider Tier 3 migration. Use cases should be better documented.
