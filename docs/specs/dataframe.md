# dataframe

## General Info

- Module group: `Foundations`
- Source path: `src/dataframe/`
- Lua API path(s): `src/lua_api/dataframe_api.rs`
- Primary Lua namespace: `lurek.dataframe`
- Rust test path(s): tests/rust/unit/dataframe_tests.rs
- Lua test path(s): tests/lua/unit/test_dataframe.lua; tests/lua/stress/test_dataframe_stress.lua; tests/lua/integration/test_compute_dataframe.lua; tests/lua/golden/test_dataframe_golden.lua

## Summary

The `dataframe` module is Lurek2D's in-memory column-major tabular data system — a Foundations tier module for analytical workloads: game data tables, leaderboard processing, CSV imports, configurable save-game summaries, and lightweight SQL-style queries without an external database. It has no Lurek2D engine dependencies and can run in any headless test context.

**Core model.** `DataFrame` is the primary type: a column-major table where each column is a named `Vec<CellValue>`. `CellValue` is a tagged union of Null, Bool, Integer (i64), Float (f64), and Text (String). Rows are accessed by 0-based index; columns by name or by `ColRef` (name or 1-based Lua-style index). Core CRUD: `add_column(name, default)`, `remove_column(ref)`, `rename_column(old, new)`, `get_column(ref)`, `add_row(pairs)`, `remove_row(i)`, `get_cell(row, col)`, `set_cell(row, col, value)`. Meta queries: `nrows()`, `ncols()`, `columns()`, `count()`.

**Database.** `Database` groups multiple named `DataFrame` tables into a catalog for multi-table query workflows. `add_table(name, frame)`, `remove_table(name)`, `get_table(name)`, `list_tables()`.

**Query pipeline.** `query.rs` provides a comprehensive analytical pipeline operating on `DataFrame` instances:
- *Filtering*: `filter(predicate)` returns a row-index mask; `where_col_eq(col, value)`, `where_col_gt`, `where_col_lt` for typed comparisons.
- *Sorting*: `sort_by(col, asc)` returns a sorted copy; `sort_by_multi(cols, dirs)` for multi-key sort.
- *Projection*: `select_cols(names)` returns a new frame with only the specified columns; `drop_cols(names)` removes them.
- *Slicing*: `head(n)`, `tail(n)`, `slice(start, end)` return subsets.
- *Set operations*: `concat(other)` appends rows; `union_cols(other)` adds columns from another frame.
- *Group-by / aggregate*: `group_by(cols)` returns groups of row indices; `aggregate(col, AggFn)` computes sum, mean, min, max, count, std_dev over grouped or full columns. `pivot(row_col, col_col, val_col, agg)` builds a pivot table.
- *Sampling*: `sample(n, seed)` returns a random row subset (seeded for repeatability).
- *Null handling*: `drop_nulls(col)`, `fill_nulls(col, value)`, `count_nulls(col)`.
- *Statistics*: `describe(col)` returns min, max, mean, std_dev, count for numeric columns.
- *Type-casting*: `cast_column(col, target_type)` converts a column in-place.
- *Join*: `join(other, left_col, right_col, join_type)` for INNER, LEFT, RIGHT joins.

**SQL engine.** `sql.rs` is a hand-written SQL tokenizer, parser, expression evaluator, and execution engine supporting a useful subset of standard SQL: SELECT (column list or `*`), FROM (single table or two-table JOIN with ON clause), WHERE (comparison operators, AND/OR, IS NULL, LIKE), ORDER BY (ASC/DESC), GROUP BY, aggregate functions (SUM, COUNT, AVG, MIN, MAX), and LIMIT. Queries run against `Database` catalogs via `execute(db, sql_string) → Result<DataFrame>`.

**Serialisation.** `serial.rs` handles round-trip I/O for multiple formats:
- *CSV*: `from_csv(text, delimiter, has_header)` with auto-typed cell parsing; `to_csv(delimiter, include_header)`.
- *JSON*: `from_json_array(json_string)` (array-of-objects); `to_json_array()`.
- *LVDF*: Lurek2D's own lightweight binary format for fast DataFrame persistence.
- *Table string*: `to_table_string(max_rows)` for debug display.

**Vectorized layer (VecFrame).** `vectorized.rs` provides `VecFrame`, a Polars-inspired typed-column store where each column is a dense flat buffer (`Vec<f64>`, `Vec<i64>`, `Vec<bool>`, or `Vec<String>`) plus an optional validity bitmap for null rows.  Operations run over entire columns at once — no per-cell enum dispatch — so the Rust compiler can auto-vectorize numeric loops with SIMD instructions and `rayon` can parallelize multi-column sweeps.  Key operations: scalar ops (`add`/`sub`/`mul`/`div`/`abs`/`sqrt`/`floor`/`ceil`/`neg`/`clamp`) applied in-place to a whole column; binary column ops (`add`/`sub`/`mul`/`div`/`min`/`max`) between two columns producing a third; reductions (`sum`/`mean`/`min`/`max`/`std`/`var`/`count`) that skip null rows; comparison filter masks and `apply_mask` for row filtering; `col_cast` for type conversion; and `par_reduce`/`par_scalar_op` for rayon-parallel multi-column work.  `VecFrame::from_dataframe` converts a `DataFrame` into `VecFrame` by type-inferring each column; `VecFrame::to_dataframe` converts back.  A GPU path is intentionally deferred — would require crossing into `src/compute/`.

**Lua surface.** `lurek.dataframe.new()` creates an empty `DataFrame`. `lurek.dataframe.fromCSV(text)`, `fromJSON(text)`. The `DataFrame` userdata exposes the full column/row CRUD, all query methods, and serialisation methods. `lurek.dataframe.newDatabase()` creates a `Database`. `Database:execute(sql)` runs SQL directly from Lua.  `lurek.dataframe.toVec(df)` converts a `DataFrame` to a `VecFrame`; `lurek.dataframe.fromVec(vf)` converts back.  `VecFrame` exposes: `colAdd`/`colSub`/`colMul`/`colDiv`/`colAbs`/`colSqrt`/`colFloor`/`colCeil`/`colNeg`/`colClamp`, `colOp`, `reduce`, `filterMask`, `applyMask`, `colType`, `colCast`, `nrows`, `ncols`, `columns`, `parReduce`, `parScalarOp`, `toDataFrame`.

**Scope boundary.** Foundations tier. No Lurek2D module imports. Lua bridge in `src/lua_api/dataframe_api.rs`.

## Files

- `frame.rs`: Defines `CellValue`, `ColRef`, `DataFrame`, and `Database`, including column and row CRUD plus deterministic random test-data generation.
- `mod.rs`: Declares the dataframe submodules and re-exports the main table and database types, plus `VecFrame` and its op enums.
- `query.rs`: Implements most table-manipulation behavior such as filtering, sorting, slicing, projection, grouping, joins, sampling, nil handling, and numeric summary statistics.
- `serial.rs`: Handles DataFrame serialization and parsing for CSV, JSON, LVDF binary, and printable string-table output.
- `vectorized.rs`: Provides `VecFrame` (typed flat-buffer columns), `ColumnStore`, and the scalar/binary/reduce/cmp op enums for bulk vectorized processing.
- `sql.rs`: Implements the hand-written SQL tokenizer, parser, expression evaluator, and execution engine for single-table and multi-table queries.

## Types

- `CellValue` (`enum`, `frame.rs`): Per-cell tagged value used throughout the module. It keeps nil, number, text, and boolean data explicit without forcing every column to share one type.
- `ColRef` (`enum`, `frame.rs`): Column selector that can resolve either a name or a 1-based index. It gives the Lua bridge and Rust helpers one shared way to address columns.
- `DataFrame` (`struct`, `frame.rs`): Core column-major table type with named columns and query methods. Most module behavior is expressed as methods on this type.
- `Database` (`struct`, `frame.rs`): Named collection of DataFrames used for multi-table workflows and SQL joins. It is deliberately small and acts as a query catalog rather than a storage engine.
- `AggFn` (`enum`, `frame.rs`): Aggregation function variants for group-by and pivot operations.

## Functions

- `CellValue::is_nil` (`frame.rs`): Returns `true` if this cell is `Nil`.
- `CellValue::as_number` (`frame.rs`): Returns the contained number, or `None`.
- `CellValue::as_text` (`frame.rs`): Returns the contained text as a string slice, or `None`.
- `CellValue::as_bool` (`frame.rs`): Returns the contained boolean, or `None`.
- `CellValue::cmp_for_sort` (`frame.rs`): Comparison for sorting.
- `DataFrame::new` (`frame.rs`): Create an empty DataFrame with no columns or rows.
- `DataFrame::nrows` (`frame.rs`): Return the number of rows.
- `DataFrame::ncols` (`frame.rs`): Return the number of columns.
- `DataFrame::columns` (`frame.rs`): Return the column names.
- `DataFrame::count` (`frame.rs`): Alias for `nrows()`; returns the row count in O(1) time.
- `DataFrame::resolve_col` (`frame.rs`): Resolve a `ColRef` to a 0-based column index.
- `DataFrame::add_column` (`frame.rs`): Add a new column, filling existing rows with `default`.
- `DataFrame::remove_column` (`frame.rs`): Remove a column by reference.
- `DataFrame::rename_column` (`frame.rs`): Rename a column.
- `DataFrame::get_column` (`frame.rs`): Return a reference to the column data.
- `DataFrame::add_row` (`frame.rs`): Add a row from name-value pairs.
- `DataFrame::remove_row` (`frame.rs`): Remove a row by 0-based index.
- `DataFrame::get_row` (`frame.rs`): Get a full row as name-value pairs (0-based index).
- `DataFrame::get_value` (`frame.rs`): Get a single cell value (0-based row, ColRef for column).
- `DataFrame::set_value` (`frame.rs`): Set a single cell value (0-based row, ColRef for column).
- `DataFrame::clone_df` (`frame.rs`): Deep-clone this DataFrame.
- `DataFrame::column_data_mut` (`frame.rs`): Return a mutable reference to a column's cell data, resolved by `ColRef`.
- `DataFrame::from_raw` (`frame.rs`): Create a DataFrame from raw column names and column-major data.
- `DataFrame::raw_data` (`frame.rs`): Get a reference to the underlying column-major data.
- `DataFrame::random` (`frame.rs`): Generate a DataFrame with random data.
- `DataFrame::with_eval` (`frame.rs`): Creates a new `DataFrame` with an extra computed column.
- `DataFrame::pivot_table` (`frame.rs`): Reshapes this DataFrame from long to wide format (pivot table).
- `DataFrame::rolling_mean` (`frame.rs`): Appends a rolling mean column to a copy of this DataFrame.
- `DataFrame::rolling_sum` (`frame.rs`): Appends a rolling sum column to a copy of this DataFrame.
- `DataFrame::rank_column` (`frame.rs`): Appends a dense-rank column to a copy of this DataFrame.
- `Database::new` (`frame.rs`): Create an empty database.
- `Database::add_table` (`frame.rs`): Add or replace a table.
- `Database::get_table` (`frame.rs`): Get a shared reference to a table by name.
- `Database::get_table_mut` (`frame.rs`): Get a mutable reference to a table by name.
- `Database::remove_table` (`frame.rs`): Remove a table by name.
- `Database::has_table` (`frame.rs`): Check whether a table with the given name exists.
- `Database::list_tables` (`frame.rs`): Return the names of all tables, sorted alphabetically.
- `Database::table_count` (`frame.rs`): Return the number of tables.
- `Database::clear` (`frame.rs`): Remove all tables.
- `Database::merge` (`frame.rs`): Merge all tables from `other` into this database.
- `Database::clone_db` (`frame.rs`): Deep-clone this Database and all contained DataFrames.
- `AggFn::parse` (`frame.rs`): Parse a string into an `AggFn`.
- `DataFrame::filter` (`query.rs`): Filter rows where `col op val` is true.
- `DataFrame::sort` (`query.rs`): Sort by column, stable sort.
- `DataFrame::head` (`query.rs`): Return the first `n` rows.
- `DataFrame::tail` (`query.rs`): Return the last `n` rows.
- `DataFrame::slice` (`query.rs`): Return a slice of rows from `start` to `end` (0-based, inclusive on both ends).
- `DataFrame::select_columns` (`query.rs`): Column projection: select a subset of columns.
- `DataFrame::unique` (`query.rs`): Return unique values in a column (O(n^2) dedup).
- `DataFrame::group_by` (`query.rs`): Group rows by the value in a column.
- `DataFrame::join` (`query.rs`): Join with another DataFrame on matching columns.
- `DataFrame::merge` (`query.rs`): Append rows from another DataFrame in-place.
- `DataFrame::count_by` (`query.rs`): Count distinct values in a column, returning a DataFrame with "value" and "count" columns.
- `DataFrame::drop_nil` (`query.rs`): Remove rows where the given column is Nil.
- `DataFrame::sample` (`query.rs`): Random sample of `n` rows using Fisher-Yates shuffle.
- `DataFrame::sum` (`query.rs`): Sum of numeric values in a column (skipping nils).
- `DataFrame::mean` (`query.rs`): Mean of numeric values in a column (skipping nils).
- `DataFrame::min_val` (`query.rs`): Minimum numeric value in a column (skipping nils).
- `DataFrame::max_val` (`query.rs`): Maximum numeric value in a column (skipping nils).
- `DataFrame::median` (`query.rs`): Median of numeric values in a column (skipping nils).
- `DataFrame::stddev` (`query.rs`): Standard deviation of numeric values in a column (population stddev, skipping nils).
- `DataFrame::variance` (`query.rs`): Variance of numeric values in a column (population variance, skipping nils).
- `DataFrame::describe` (`query.rs`): Descriptive statistics for all numeric columns.
- `DataFrame::fill_nil` (`query.rs`): Replace Nil values in a column with the given value (in-place).
- `DataFrame::with_rolling_mean` (`query.rs`): Add a new column containing the rolling mean of `col` with `window` rows.
- `DataFrame::with_rolling_sum` (`query.rs`): Add a new column containing the rolling sum of `col` with `window` rows.
- `DataFrame::with_rolling_min` (`query.rs`): Add a new column containing the rolling minimum of `col` with `window` rows.
- `DataFrame::with_rolling_max` (`query.rs`): Add a new column containing the rolling maximum of `col` with `window` rows.
- `DataFrame::with_rank` (`query.rs`): Add a new column containing the rank of each row's value in `col`.
- `DataFrame::with_pct_change` (`query.rs`): Add a new column containing the percentage change from the previous row in `col`.
- `DataFrame::with_cumsum` (`query.rs`): Add a new column containing the cumulative sum of `col`.
- `DataFrame::group_agg` (`query.rs`): Aggregate `agg_col` grouped by `group_col` using `agg_fn`.
- `DataFrame::pivot` (`query.rs`): Create a pivot table: rows = unique values of `row_col`, columns = unique values of `col_col`, cells = values of `val_col` (first match per cell).
- `DataFrame::corr` (`query.rs`): Pearson correlation coefficient between two numeric columns.
- `DataFrame::correlation_matrix` (`query.rs`): Build a correlation matrix DataFrame for all numeric columns.
- `DataFrame::zscore_col` (`query.rs`): Add a z-score column for a numeric column.
- `DataFrame::normalize_col` (`query.rs`): Add a min-max normalised column for a numeric column.
- `DataFrame::outliers` (`query.rs`): Return a new DataFrame containing only rows where `col` is an outlier.
- `DataFrame::mode_val` (`query.rs`): Return the most frequent value in a column, or `CellValue::Nil` if empty.
- `DataFrame::entropy` (`query.rs`): Shannon entropy (bits) of the value distribution in a column.
- `DataFrame::add_row_batch` (`query.rs`): Add multiple rows at once from a `Vec<Vec<CellValue>>`.
- `DataFrame::get_column_as_f64` (`query.rs`): Return the numeric values of a column as `Vec<f64>` (nils → NaN).
- `DataFrame::set_column_from_f64` (`query.rs`): Set all rows of a numeric column from a `Vec<f64>`.
- `from_csv` (`serial.rs`): Parse a CSV string into a DataFrame.
- `DataFrame::to_csv` (`serial.rs`): Serialize to CSV string (RFC 4180).
- `from_json` (`serial.rs`): Parse JSON (array-of-objects) into a DataFrame.
- `DataFrame::to_json` (`serial.rs`): Serialize to JSON string (array-of-objects format).
- `DataFrame::to_binary` (`serial.rs`): Serialize to LVDF binary format.
- `from_binary` (`serial.rs`): Deserialize a DataFrame from LVDF binary format.
- `DataFrame::to_string_table` (`serial.rs`): Format the DataFrame as an ASCII table for debug display.
- `Database::to_json` (`serial.rs`): Serialize all tables to a JSON object string.
- `query_sql` (`sql.rs`): Execute a SQL query on a single DataFrame.
- `query_sql_database` (`sql.rs`): Execute a SQL query on a Database (supports FROM and JOIN).

## Lua API Reference

- Binding path(s): `src/lua_api/dataframe_api.rs`
- Namespace: `lurek.dataframe`

### Module Functions
- `lurek.dataframe.newDataFrame`: Creates a new empty DataFrame.
- `lurek.dataframe.newDatabase`: Creates a new empty Database.
- `lurek.dataframe.fromTable`: Creates a DataFrame from an array of row tables.
- `lurek.dataframe.fromCSV`: Parses a CSV string into a DataFrame.
- `lurek.dataframe.fromJSON`: Parses a JSON string into a DataFrame.
- `lurek.dataframe.fromBinary`: Deserializes a binary LVDF string into a DataFrame.
- `lurek.dataframe.random`: Generates a DataFrame with random data from column definitions.

### `DataFrame` Methods
- `DataFrame:nrows`: Returns the number of rows.
- `DataFrame:ncols`: Returns the number of columns.
- `DataFrame:columns`: Returns a table of column names.
- `DataFrame:count`: Returns the row count (alias for nrows).
- `DataFrame:removeColumn`: Removes a column by name or index.
- `DataFrame:rename`: Renames the column `old_name` to `new_name` in this DataFrame.
- `DataFrame:getColumn`: Returns all values in a column as a table.
- `DataFrame:addRow`: Adds a row from an optional table of name-value pairs, returns 1-based index.
- `DataFrame:removeRow`: Removes a row by 1-based index.
- `DataFrame:getRow`: Returns a row as a table of name-value pairs.
- `DataFrame:getValue`: Returns a single cell value.
- `DataFrame:head`: Returns the first n rows (default 5).
- `DataFrame:tail`: Returns the last n rows (default 5).
- `DataFrame:slice`: Returns rows from start to end (1-based, inclusive).
- `DataFrame:select`: Selects a subset of columns, returns a new DataFrame.
- `DataFrame:unique`: Returns unique values in a column as a table.
- `DataFrame:groupBy`: Groups rows by column value, returns a table of DataFrames keyed by value.
- `DataFrame:groupByObj`: Groups rows by column value, returns a GroupedFrame object supporting aggregate().
- `DataFrame:merge`: Appends rows from another DataFrame in-place.
- `DataFrame:countBy`: Counts distinct values in a column, returns a DataFrame with value and count columns.
- `DataFrame:dropNil`: Removes rows where the given column is nil, returns a new DataFrame.
- `DataFrame:sample`: Returns a random sample of n rows.
- `DataFrame:describe`: Returns descriptive statistics for all numeric columns.
- `DataFrame:sum`: Returns the sum of numeric values in a column.
- `DataFrame:mean`: Returns the mean of numeric values in a column.
- `DataFrame:min`: Returns the minimum numeric value in a column.
- `DataFrame:max`: Returns the maximum numeric value in a column.
- `DataFrame:median`: Returns the median of numeric values in a column.
- `DataFrame:stddev`: Returns the population standard deviation of numeric values in a column.
- `DataFrame:variance`: Returns the population variance of numeric values in a column.
- `DataFrame:fillNil`: Replaces nil values in a column with the given value.
- `DataFrame:toCSV`: Serializes this DataFrame to a CSV string.
- `DataFrame:toJSON`: Serializes this DataFrame to a JSON string.
- `DataFrame:toBinary`: Serializes this DataFrame to a binary LVDF string.
- `DataFrame:toTable`: Converts this DataFrame to a Lua table of row tables.
- `DataFrame:toString`: Returns a formatted string table representation.
- `DataFrame:query`: Executes a SQL query against this DataFrame.
- `DataFrame:clone`: Returns a deep copy of this DataFrame.
- `DataFrame:correlationMatrix`: Compute a correlation matrix for all numeric columns.
- `DataFrame:modeVal`: Return the most frequent value in a column (nil if empty).
- `DataFrame:entropy`: Shannon entropy (bits) of the value distribution in a column.
- `DataFrame:addRowBatch`: Add multiple rows at once from a table of row tables.
- `DataFrame:getColumnAsF64`: Return a numeric column as a Lua array of numbers (nils → 0/nan).
- `DataFrame:setColumnFromF64`: Set a numeric column from a Lua array of numbers.
- `DataFrame:type`: Returns the type name of this object.
- `DataFrame:typeOf`: Returns true if this object is of the given type.
- `DataFrame:withEval`: Returns a new DataFrame with an additional computed column named `col_name`.

### `Database` Methods
- `Database:getTable`: Returns a copy of a table by name, or nil if not found.
- `Database:removeTable`: Drops the named table from this in-memory database if it exists.
- `Database:hasTable`: Returns true if a table with the given name exists.
- `Database:listTables`: Returns a table of all table names.
- `Database:tableCount`: Returns the number of tables.
- `Database:clear`: Drops every table from this in-memory database, leaving it empty.
- `Database:merge`: Merges all tables from another Database into this one.
- `Database:toJSON`: Serializes all tables to a JSON object string.
- `Database:query`: Executes a SQL query against the database tables.
- `Database:type`: Returns the type name of this object.
- `Database:typeOf`: Returns true if this object is of the given type.

### `GroupedFrame` Methods
- `GroupedFrame:aggregate`: Apply a Lua function to aggregate a column's values per group.

## References

- No top-level `crate::<module>` imports were detected in this module's Rust source files.

## Notes

- Keep this module reference synchronized with `src/dataframe/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
