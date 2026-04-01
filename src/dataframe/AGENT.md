# src/dataframe/

In-memory column-major tabular data with query, analytics, and SQL support.

## What This Module Contains

DataFrame for named-column data tables. Database for multi-table catalogs with SQL query execution. Supports filtering, sorting, grouping, aggregation, joins, and CSV-style serialization.

## Files

| File | Purpose |
|------|---------|
| `frame.rs` | `Frame` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |
| `query.rs` | `Query` implementation |
| `serial.rs` | `Serial` implementation |
| `sql.rs` | `Sql` implementation |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/dataframe_tests.rs`
- **Lua API bindings**: `src/lua_api/dataframe_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
