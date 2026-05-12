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

**Query pipeline.** `query/` (previously `query.rs`) provides a comprehensive analytical pipeline operating on `DataFrame` instances:
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
- *Streaming rows*: `iter_rows()` yields borrowed row views lazily to support sequential processing without `toTable` full materialization.

**SQL engine.** `sql.rs` is a hand-written SQL tokenizer, parser, expression evaluator, and execution engine supporting a useful subset of standard SQL: SELECT (column list or `*`, with optional `table.column` qualified names), FROM (single table or two-table JOIN with ON clause), WHERE (comparison operators, AND/OR, IS NULL, LIKE), ORDER BY (ASC/DESC), GROUP BY, aggregate functions (SUM, COUNT, AVG, MIN, MAX), and LIMIT. Queries run against `Database` catalogs via `execute(db, sql_string) → Result<DataFrame>`.

**Serialisation.** `serial.rs` handles round-trip I/O for multiple formats:
- *CSV*: `from_csv(text, delimiter, has_header)` with auto-typed cell parsing; `to_csv(delimiter, include_header)`.
- *JSON*: `from_json_array(json_string)` (array-of-objects); `to_json_array()`.
- *LVDF*: Lurek2D's own lightweight binary format for fast DataFrame persistence.
- *Table string*: `to_table_string(max_rows)` for debug display.

**Vectorized layer (VecFrame).** `vectorized.rs` provides `VecFrame`, a Polars-inspired typed-column store where each column is a dense flat buffer (`Vec<f64>`, `Vec<i64>`, `Vec<bool>`, or `Vec<String>`) plus an optional validity bitmap for null rows.  Operations run over entire columns at once — no per-cell enum dispatch — so the Rust compiler can auto-vectorize numeric loops with SIMD instructions and `rayon` can parallelize multi-column sweeps.  Key operations: scalar ops (`add`/`sub`/`mul`/`div`/`abs`/`sqrt`/`floor`/`ceil`/`neg`/`clamp`) applied in-place to a whole column; binary column ops (`add`/`sub`/`mul`/`div`/`min`/`max`) between two columns producing a third; reductions (`sum`/`mean`/`min`/`max`/`std`/`var`/`count`) that skip null rows; comparison filter masks and `apply_mask` for row filtering; `col_cast` for type conversion; and `par_reduce`/`par_scalar_op` for rayon-parallel multi-column work.  `VecFrame::from_dataframe` converts a `DataFrame` into `VecFrame` by type-inferring each column; `VecFrame::to_dataframe` converts back.  A GPU path is intentionally deferred — would require crossing into `src/compute/`.

**Lua surface.** `lurek.dataframe.new()` creates an empty `DataFrame`. `lurek.dataframe.fromCSV(text)`, `fromJSON(text)`. The `DataFrame` userdata exposes the full column/row CRUD, all query methods, and serialisation methods. `DataFrame:lazy()` starts a lazy evaluation pipeline (`LLazyQuery`) whose steps — `filter`, `sort`, `head`, `tail`, `limit`, `slice`, `dropNil`, `select` — each return a new pipeline builder; `collect()` executes the whole chain at once without allocating intermediate frames. `lurek.dataframe.newDatabase()` creates a `Database`. `Database:execute(sql)` runs SQL directly from Lua.  `lurek.dataframe.toVec(df)` converts a `DataFrame` to a `VecFrame`; `lurek.dataframe.fromVec(vf)` converts back.  `VecFrame` exposes: `colAdd`/`colSub`/`colMul`/`colDiv`/`colAbs`/`colSqrt`/`colFloor`/`colCeil`/`colNeg`/`colClamp`, `colOp`, `reduce`, `filterMask`, `applyMask`, `colType`, `colCast`, `nrows`, `ncols`, `columns`, `parReduce`, `parScalarOp`, `toDataFrame`.

**Scope boundary.** Foundations tier. No Lurek2D module imports. Lua bridge in `src/lua_api/dataframe_api.rs`.

## Files

- `frame.rs`: Defines `CellValue`, `ColRef`, `DataFrame`, and `Database`, including column and row CRUD plus deterministic random test-data generation.
- `lazy.rs`: Defines `LazyQuery`, a step-list pipeline builder over a `DataFrame`. Steps are recorded cheaply and executed once at `collect()` without intermediate allocations.
- `mod.rs`: Declares the dataframe submodules and re-exports the main table and database types, plus `VecFrame` and its op enums.
- `query/`: Analytical pipeline split into focused sub-modules — `filter.rs` (row predicate ops), `window.rs` (rolling, rank, cumsum), `grouping.rs` (group-agg, pivot, correlation), `analytics.rs` (z-score, normalize, outliers, entropy, percentile).
- `serial.rs`: Handles DataFrame serialization and parsing for CSV, JSON, LVDF binary, and printable string-table output.
- `sql.rs`: Implements the hand-written SQL tokenizer, parser, expression evaluator, and execution engine for single-table and multi-table queries. Supports `table.column` qualified names in SELECT.
- `vectorized.rs`: Provides `VecFrame` (typed flat-buffer columns), `ColumnStore`, and the scalar/binary/reduce/cmp op enums for bulk vectorized processing.

## Types

- `CellValue` (`enum`, `frame.rs`): Per-cell tagged value used throughout the module. It keeps nil, number, text, and boolean data explicit without forcing every column to share one type.
- `ColRef` (`enum`, `frame.rs`): Column selector that can resolve either a name or a 1-based index. It gives the Lua bridge and Rust helpers one shared way to address columns.
- `DataFrame` (`struct`, `frame.rs`): Core column-major table type with named columns and query methods. Most module behavior is expressed as methods on this type.
- `Database` (`struct`, `frame.rs`): Named collection of DataFrames used for multi-table workflows and SQL joins. It is deliberately small and acts as a query catalog rather than a storage engine.
- `AggFn` (`enum`, `frame.rs`): Aggregation function variants for group-by and pivot operations.
- `ColumnStore` (`enum`, `vectorized.rs`): Typed flat-buffer column with an optional null/validity bitmap.
- `ScalarOp` (`enum`, `vectorized.rs`): Scalar arithmetic operation applied element-wise to an entire column.
- `BinaryOp` (`enum`, `vectorized.rs`): Element-wise binary operation between two Float64 columns.
- `ReduceOp` (`enum`, `vectorized.rs`): Column-level reduction operations.
- `CmpOp` (`enum`, `vectorized.rs`): Comparison operator used in `VecFrame::filter_mask`.
- `VecFrame` (`struct`, `vectorized.rs`): Typed-column vectorized DataFrame.

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
- `DataFrame::iter_rows` (`frame.rs`): Iterate rows lazily as borrowed `(column_name, cell)` pairs.
- `DataFrame::get_value` (`frame.rs`): Get a single cell value (0-based row, ColRef for column).
- `DataFrame::set_value` (`frame.rs`): Set a single cell value (0-based row, ColRef for column).
- `DataFrame::clone_df` (`frame.rs`): Deep-clone this DataFrame.
- `DataFrame::column_data_mut` (`frame.rs`): Return a mutable reference to a column's cell data, resolved by `ColRef`.
- `DataFrame::from_raw` (`frame.rs`): Create a DataFrame from raw column names and column-major data.
- `DataFrame::from_rows` (`frame.rs`): Create a DataFrame from explicit column names plus row-major values.
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
- `ColumnStore::dtype_name` (`vectorized.rs`): Return the dtype name as a static string slice.
- `ColumnStore::len` (`vectorized.rs`): Return the number of rows in this column.
- `ColumnStore::is_empty` (`vectorized.rs`): Return `true` if the column has zero rows.
- `ColumnStore::is_valid` (`vectorized.rs`): Return `true` if row `i` is valid (not null).
- `ColumnStore::valid_f64s` (`vectorized.rs`): Collect valid (non-null) f64 values from a Float64 column.
- `ColumnStore::filter` (`vectorized.rs`): Filter rows by a boolean mask, returning a new `ColumnStore`.
- `ScalarOp::parse` (`vectorized.rs`): Parse a string into a `ScalarOp`.
- `BinaryOp::parse` (`vectorized.rs`): Parse a string into a `BinaryOp`.
- `ReduceOp::parse` (`vectorized.rs`): Parse a string into a `ReduceOp`.
- `CmpOp::parse` (`vectorized.rs`): Parse a string into a `CmpOp`.
- `VecFrame::new` (`vectorized.rs`): Create an empty `VecFrame` with no columns.
- `VecFrame::nrows` (`vectorized.rs`): Return the number of rows.
- `VecFrame::ncols` (`vectorized.rs`): Return the number of columns.
- `VecFrame::columns` (`vectorized.rs`): Return a slice of column names.
- `VecFrame::col_type` (`vectorized.rs`): Return the dtype name for a column, or `None` if the column is not found.
- `VecFrame::from_dataframe` (`vectorized.rs`): Convert a [`DataFrame`] into a `VecFrame`.
- `VecFrame::to_dataframe` (`vectorized.rs`): Convert this `VecFrame` back to a [`DataFrame`].
- `VecFrame::col_scalar_op` (`vectorized.rs`): Apply a scalar operation to every element of a Float64 column in-place.
- `VecFrame::col_clamp` (`vectorized.rs`): Clamp every element of a Float64 column to `[min_val, max_val]` in-place.
- `VecFrame::col_binary_op` (`vectorized.rs`): Compute `out_col[i] = left_col[i] op right_col[i]` for every row, storing the result in a new column named `out_col`.
- `VecFrame::col_reduce` (`vectorized.rs`): Reduce an entire Float64 column to a single scalar.
- `VecFrame::filter_mask` (`vectorized.rs`): Build a boolean row mask for `col[i] op val`.
- `VecFrame::apply_mask` (`vectorized.rs`): Return a new `VecFrame` containing only the rows where `mask[i]` is `true`.
- `VecFrame::col_cast` (`vectorized.rs`): Cast a column to a new type.
- `VecFrame::par_reduce` (`vectorized.rs`): Reduce multiple columns in parallel using `rayon`, returning a map of column name → result.
- `VecFrame::par_scalar_op` (`vectorized.rs`): Apply a scalar operation in parallel to multiple Float64 columns.

## Lua API Reference

- Binding path(s): `src/lua_api/dataframe_api.rs`
- Namespace: `lurek.dataframe`

### Module Functions
- `lurek.dataframe.newDataFrame`: Creates a new empty DataFrame.
- `lurek.dataframe.newDatabase`: Creates a new empty Database.
- `lurek.dataframe.fromTable`: Creates a DataFrame from an array of row tables.
- `lurek.dataframe.fromRows`: Creates a DataFrame from explicit columns and row-major arrays.
- `lurek.dataframe.fromCSV`: Parses a CSV string into a DataFrame.
- `lurek.dataframe.fromJSON`: Parses a JSON string into a DataFrame.
- `lurek.dataframe.fromBinary`: Deserializes a binary LVDF string into a DataFrame.
- `lurek.dataframe.random`: Generates a DataFrame with random data from column definitions.
- `lurek.dataframe.toVec`: Converts a DataFrame to a VecFrame for vectorized column operations.
- `lurek.dataframe.fromVec`: Converts a VecFrame back to a DataFrame.

### `LDataFrame` Methods
- `LDataFrame:nrows`: Returns the number of rows.
- `LDataFrame:ncols`: Returns the number of columns.
- `LDataFrame:columns`: Returns a table of column names.
- `LDataFrame:count`: Returns the row count (alias for nrows).
- `LDataFrame:addColumn`: Adds a new column with an optional default value.
- `LDataFrame:removeColumn`: Removes a column by name or index.
- `LDataFrame:rename`: Renames the column `old_name` to `new_name` in this DataFrame.
- `LDataFrame:getColumn`: Returns all values in a column as a table.
- `LDataFrame:addRow`: Adds a row from an optional table of name-value pairs, returns 1-based index.
- `LDataFrame:removeRow`: Removes a row by 1-based index.
- `LDataFrame:getRow`: Returns a row as a table of name-value pairs.
- `LDataFrame:getValue`: Returns a single cell value.
- `LDataFrame:setValue`: Sets a single cell value.
- `LDataFrame:filter`: Filters rows where column matches a condition, returns a new DataFrame.
- `LDataFrame:sort`: Sorts by column, returns a new DataFrame.
- `LDataFrame:head`: Returns the first n rows (default 5).
- `LDataFrame:tail`: Returns the last n rows (default 5).
- `LDataFrame:slice`: Returns rows from start to end (1-based, inclusive).
- `LDataFrame:select`: Selects a subset of columns, returns a new DataFrame.
- `LDataFrame:unique`: Returns unique values in a column as a table.
- `LDataFrame:groupBy`: Groups rows by column value, returns a table of DataFrames keyed by value.
- `LDataFrame:groupByObj`: Groups rows by column value, returns a GroupedFrame object supporting aggregate().
- `LDataFrame:join`: Joins with another DataFrame on matching columns.
- `LDataFrame:merge`: Appends rows from another DataFrame in-place.
- `LDataFrame:countBy`: Counts distinct values in a column, returns a DataFrame with value and count columns.
- `LDataFrame:dropNil`: Removes rows where the given column is nil, returns a new DataFrame.
- `LDataFrame:sample`: Returns a random sample of n rows.
- `LDataFrame:describe`: Returns descriptive statistics for all numeric columns.
- `LDataFrame:sum`: Returns the sum of numeric values in a column.
- `LDataFrame:mean`: Returns the mean of numeric values in a column.
- `LDataFrame:min`: Returns the minimum numeric value in a column.
- `LDataFrame:max`: Returns the maximum numeric value in a column.
- `LDataFrame:median`: Returns the median of numeric values in a column.
- `LDataFrame:stddev`: Returns the population standard deviation of numeric values in a column.
- `LDataFrame:variance`: Returns the population variance of numeric values in a column.
- `LDataFrame:fillNil`: Replaces nil values in a column with the given value.
- `LDataFrame:apply`: Applies a function to each value in a column, replacing cells with results.
- `LDataFrame:toCSV`: Serializes this DataFrame to a CSV string.
- `LDataFrame:toJSON`: Serializes this DataFrame to a JSON string.
- `LDataFrame:toBinary`: Serializes this DataFrame to a binary LVDF string.
- `LDataFrame:toTable`: Converts this DataFrame to a Lua table of row tables.
- `LDataFrame:rows`: Returns a streaming row iterator yielding `(row_index, row_table)`.
- `LDataFrame:toString`: Returns a formatted string table representation.
- `LDataFrame:query`: Executes a SQL query against this DataFrame.
- `LDataFrame:clone`: Returns a deep copy of this DataFrame.
- `LDataFrame:withRollingMean`: Add a rolling mean column. Rows with insufficient history get nil.
- `LDataFrame:withRollingSum`: Add a rolling sum column.
- `LDataFrame:withRollingMin`: Add a rolling minimum column.
- `LDataFrame:withRollingMax`: Add a rolling maximum column.
- `LDataFrame:withRank`: Add a rank column (1-based, ties averaged).
- `LDataFrame:withPctChange`: Add a percent-change-from-previous-row column.
- `LDataFrame:withCumsum`: Add a cumulative-sum column.
- `LDataFrame:groupAgg`: Aggregate agg_col grouped by group_col using the named function.
- `LDataFrame:pivot`: Creates a wide pivot table by reshaping rows into columns.
- `LDataFrame:corr`: Pearson correlation coefficient between two numeric columns.
- `LDataFrame:correlationMatrix`: Compute a correlation matrix for all numeric columns.
- `LDataFrame:zscoreCol`: Add a z-score column for the given numeric column.
- `LDataFrame:normalizeCol`: Add a min-max normalized column scaled to [out_min, out_max].
- `LDataFrame:outliers`: Return a new DataFrame with only outlier rows (|z-score| > threshold).
- `LDataFrame:modeVal`: Return the most frequent value in a column (nil if empty).
- `LDataFrame:entropy`: Shannon entropy (bits) of the value distribution in a column.
- `LDataFrame:addRowBatch`: Add multiple rows at once from a table of row tables.
- `LDataFrame:getColumnAsF64`: Return a numeric column as a Lua array of numbers (nils -> 0/nan).
- `LDataFrame:setColumnFromF64`: Set a numeric column from a Lua array of numbers.
- `LDataFrame:type`: Returns the type name of this object.
- `LDataFrame:typeOf`: Returns true if this object is of the given type.
- `LDataFrame:withEval`: Returns a new DataFrame with an additional computed column named `col_name`.
- `LDataFrame:pivotTable`: Reshapes a long-format DataFrame into wide format.
- `LDataFrame:rollingMean`: Returns a new DataFrame with a rolling mean column appended.
- `LDataFrame:rollingSum`: Returns a new DataFrame with a rolling sum column appended.
- `LDataFrame:rank`: Returns a new DataFrame with a dense-rank column appended.

### `LDatabase` Methods
- `LDatabase:addTable`: Adds or replaces a table by cloning the given DataFrame.
- `LDatabase:getTable`: Returns a copy of a table by name, or nil if not found.
- `LDatabase:removeTable`: Drops the named table from this in-memory database if it exists.
- `LDatabase:hasTable`: Returns true if a table with the given name exists.
- `LDatabase:listTables`: Returns a table of all table names.
- `LDatabase:tableCount`: Returns the number of tables.
- `LDatabase:clear`: Drops every table from this in-memory database, leaving it empty.
- `LDatabase:merge`: Merges all tables from another Database into this one.
- `LDatabase:toJSON`: Serializes all tables to a JSON object string.
- `LDatabase:query`: Executes a SQL query against the database tables.
- `LDatabase:type`: Returns the type name of this object.
- `LDatabase:typeOf`: Returns true if this object is of the given type.

### `LGroupedFrame` Methods
- `LGroupedFrame:aggregate`: Apply a Lua function to aggregate a column's values per group.
- `LGroupedFrame:type`: Returns the type name of this object.
- `LGroupedFrame:typeOf`: Returns true if this object is of the given type.

### `LVecFrame` Methods
- `LVecFrame:colAdd`: Add a scalar to every element of a Float64 column.
- `LVecFrame:colSub`: Subtract a scalar from every element of a Float64 column.
- `LVecFrame:colMul`: Multiply every element of a Float64 column by a scalar.
- `LVecFrame:colDiv`: Divide every element of a Float64 column by a scalar.
- `LVecFrame:colAbs`: Apply absolute value to every element of a Float64 column.
- `LVecFrame:colSqrt`: Apply square root to every element of a Float64 column.
- `LVecFrame:colFloor`: Apply floor to every element of a Float64 column.
- `LVecFrame:colCeil`: Apply ceiling to every element of a Float64 column.
- `LVecFrame:colNeg`: Negate every element of a Float64 column.
- `LVecFrame:colClamp`: Clamp every element of a Float64 column to [min, max].
- `LVecFrame:colOp`: Compute out[i] = left[i] op right[i] for every row.
- `LVecFrame:reduce`: Reduce an entire numeric column to a single value.
- `LVecFrame:filterMask`: Build a boolean row mask: mask[i] = col[i] cmp_op val.
- `LVecFrame:applyMask`: Return a new VecFrame containing only the rows where mask[i] is true.
- `LVecFrame:colType`: Return the dtype name of a column: "float64", "int64", "bool", or "text".
- `LVecFrame:colCast`: Cast a column to a new dtype: "float64", "int64", or "text".
- `LVecFrame:nrows`: Return the number of rows.
- `LVecFrame:ncols`: Return the number of columns.
- `LVecFrame:columns`: Return a table of column names.
- `LVecFrame:parReduce`: Reduce multiple columns in parallel, returning {col -> value} table.
- `LVecFrame:parScalarOp`: Apply a scalar op in parallel to multiple Float64 columns.
- `LVecFrame:toDataFrame`: Convert this VecFrame back to a DataFrame.
- `LVecFrame:type`: Returns the type name of this object.
- `LVecFrame:typeOf`: Returns true if this object is of the given type.

## References

- No top-level `crate::<module>` imports were detected in this module's Rust source files.

## Notes

- Keep this module reference synchronized with `src/dataframe/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
