# IDEA.md — `dataframe` module

> Migrated from `ideas/features/dataframe.md`.
> Status checked against `src/dataframe/` and `src/lua_api/dataframe_api.rs`.

---

## Features

### ❌ TODO — Pivot Tables
**Source**: features/dataframe.md — Feature Gaps #1

No pivot/reshape from long to wide format found. Needed for complex game-data analysis
(turn stats into per-player columns, etc.).

---

### ❌ TODO — Window Functions (Rolling Average, Running Total, Rank)
**Source**: features/dataframe.md — Feature Gaps #2 / Suggestions #2

No `rollingMean`, `rollingSum`, or rank functions found. Essential for leaderboards,
time-series game stats, and smooth progression curves.

Suggested API:
```lua
df:rollingMean("damage", 5)   -- 5-frame rolling average
df:rank("score", "desc")      -- leaderboard rank column
```

---

### ✅ DONE — Expression-Based Column Creation
**Source**: features/dataframe.md — Feature Gaps #3

`DataFrame::with_eval(col_name, expr)` added to `src/dataframe/frame.rs`.
`LuaDataFrame:withEval(col_name, expr)` added to `src/lua_api/dataframe_api.rs`.
Returns a new `DataFrame` with the computed column appended.
Supports column-name references and numeric literals with `+`, `-`, `*`, `/`.

```lua
local df2 = df:withEval("total", "attack + bonus * 1.5")
```

Implemented: 2026-04-15

---

### ❌ TODO — SQLite Import
**Source**: features/dataframe.md — Feature Gaps #5 / Suggestions #3

No `fromSQLite(path, query)` found. SQLite is a common format for game balance data and
modder-supplied databases.

---

### ❌ TODO — Visualization / Chart Output
**Source**: features/dataframe.md — Feature Gaps #4 / Suggestions #5

No `df:plot()` or chart rendering. A minimal bar/line chart for debug overlays would make
the module far more practical for game developers.

---

### 🤔 CONSIDER — Move to Tier 3 Pure-Lua Library
**Source**: features/dataframe.md — Structural Issues / Suggestions #1

The DataFrame use case (leaderboard analysis, balance tuning, event logs) is valid but niche
for a 2D game engine. A pure-Lua implementation in `content/library/` with `lurek.codec`
for CSV and `lurek.compute` for numerics could serve the same audience without engine-level
Rust overhead. Requires Architect decision.
