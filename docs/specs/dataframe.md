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
- `query/analytics.rs`: - Percentile computation by linear interpolation over sorted values - Z-score standardization for numeric columns - Min-max normalization to arbitrary output range - Outlier detection via z-score threshold - Mode value computation across non-nil cells - Shannon entropy calculatio
- `query/filter.rs`: - Row filtering by column predicate with comparison and contains operators - Column sorting in ascending or descending order - Head, tail, and inclusive slice row selection - Column projection and unique value extraction - Group-by partitioning and inner/left join merging - Frame
- `query/grouping.rs`: - Grouped aggregation by key column with mean, sum, min, max, count, first, last - Pivot transformation from row/column/value keys into cross-tabulated frame - Pearson correlation between two numeric columns - Full numeric-column correlation matrix generation
- `query/mod.rs`: - Statistical and distribution-oriented analytics helpers - Row filtering, sorting, joins, and sampling operations - Grouped aggregation, pivoting, and correlation computations - Rolling and ranking window functions
- `query/window.rs`: - Rolling mean, sum, min, and max over configurable window size - Dense rank computation with average-rank tie-breaking - Row-to-row percent change calculation - Cumulative sum across ordered rows
- `rng.rs`: - Xorshift64 pseudo-random number generator for deterministic dataframe sampling - Float, integer, and index generation from 64-bit state - Zero-seed remap to avoid degenerate all-zero output
- `serial.rs`: Handles DataFrame serialization and parsing for CSV, JSON, LVDF binary, and printable string-table output.
- `sql.rs`: Implements the hand-written SQL tokenizer, parser, expression evaluator, and execution engine for single-table and multi-table queries. Supports `table.column` qualified names in SELECT.
- `vectorized.rs`: Provides `VecFrame` (typed flat-buffer columns), `ColumnStore`, and the scalar/binary/reduce/cmp op enums for bulk vectorized processing.

## Types

- `CellValue` (`enum`, `frame.rs`): Per-cell tagged value used throughout the module. It keeps nil, number, text, and boolean data explicit without forcing every column to share one type.
- `ColRef` (`enum`, `frame.rs`): Column selector that can resolve either a name or a 1-based index. It gives the Lua bridge and Rust helpers one shared way to address columns.
- `DataFrame` (`struct`, `frame.rs`): Core column-major table type with named columns and query methods. Most module behavior is expressed as methods on this type.
- `DataFrameRowIter` (`struct`, `frame.rs`): Iterate rows as vectors of column-name and cell references.
- `Database` (`struct`, `frame.rs`): Named collection of DataFrames used for multi-table workflows and SQL joins. It is deliberately small and acts as a query catalog rather than a storage engine.
- `AggFn` (`enum`, `frame.rs`): Aggregation function variants for group-by and pivot operations.
- `LazyQuery` (`struct`, `lazy.rs`): Hold deferred query source frame and queued steps.
- `Xorshift64` (`struct`, `rng.rs`): Hold xorshift64 state used by dataframe-local random helpers.
- `ColumnStore` (`enum`, `vectorized.rs`): Typed flat-buffer column with an optional null/validity bitmap.
- `ScalarOp` (`enum`, `vectorized.rs`): Scalar arithmetic operation applied element-wise to an entire column.
- `BinaryOp` (`enum`, `vectorized.rs`): Element-wise binary operation between two Float64 columns.
- `ReduceOp` (`enum`, `vectorized.rs`): Column-level reduction operations.
- `CmpOp` (`enum`, `vectorized.rs`): Comparison operator used in `VecFrame::filter_mask`.
- `VecFrame` (`struct`, `vectorized.rs`): Typed-column vectorized DataFrame.

## Functions

- `CellValue::is_nil` (`frame.rs`): Return true when cell is nil.
- `CellValue::as_number` (`frame.rs`): Return numeric value when cell stores number.
- `CellValue::as_text` (`frame.rs`): Return text slice when cell stores text.
- `CellValue::as_bool` (`frame.rs`): Return bool value when cell stores boolean.
- `CellValue::cmp_for_sort` (`frame.rs`): Compare values for deterministic sort ordering.
- `DataFrame::new` (`frame.rs`): Create empty dataframe.
- `DataFrame::nrows` (`frame.rs`): Return number of rows.
- `DataFrame::ncols` (`frame.rs`): Return number of columns.
- `DataFrame::columns` (`frame.rs`): Return ordered column names.
- `DataFrame::count` (`frame.rs`): Return row count alias.
- `DataFrame::resolve_col` (`frame.rs`): Resolve column selector to zero-based index.
- `DataFrame::add_column` (`frame.rs`): Add new column filled with default values.
- `DataFrame::remove_column` (`frame.rs`): Remove selected column.
- `DataFrame::rename_column` (`frame.rs`): Rename selected column.
- `DataFrame::get_column` (`frame.rs`): Return selected column slice.
- `DataFrame::add_row` (`frame.rs`): Append row from sparse key-value input and return row index.
- `DataFrame::remove_row` (`frame.rs`): Remove row by index.
- `DataFrame::get_row` (`frame.rs`): Return cloned row values by index.
- `DataFrame::iter_rows` (`frame.rs`): Return iterator over row views.
- `DataFrame::get_value` (`frame.rs`): Return cloned cell value at row and column.
- `DataFrame::set_value` (`frame.rs`): Set cell value at row and column.
- `DataFrame::clone_df` (`frame.rs`): Clone dataframe deeply.
- `DataFrame::column_data_mut` (`frame.rs`): Return mutable column vector for selected column.
- `DataFrame::from_raw` (`frame.rs`): Build dataframe from raw column names and data vectors.
- `DataFrame::from_rows` (`frame.rs`): Build dataframe from row-major data.
- `DataFrame::raw_data` (`frame.rs`): Return raw column storage reference.
- `DataFrame::random` (`frame.rs`): Generate random dataframe from typed column definitions.
- `DataFrame::with_eval` (`frame.rs`): Evaluate arithmetic expression per row and append result column.
- `DataFrame::pivot_table` (`frame.rs`): Build pivot table from row key, column key, and value key.
- `DataFrame::rolling_mean` (`frame.rs`): Compute rolling mean and return dataframe with appended column.
- `DataFrame::rolling_sum` (`frame.rs`): Compute rolling sum and return dataframe with appended column.
- `DataFrame::rank_column` (`frame.rs`): Compute rank for numeric column and return dataframe with rank column.
- `Database::new` (`frame.rs`): Create empty database.
- `Database::add_table` (`frame.rs`): Insert or replace table by name.
- `Database::get_table` (`frame.rs`): Return immutable table reference by name.
- `Database::get_table_mut` (`frame.rs`): Return mutable table reference by name.
- `Database::remove_table` (`frame.rs`): Remove table by name.
- `Database::has_table` (`frame.rs`): Return true when table exists.
- `Database::list_tables` (`frame.rs`): Return sorted list of table names.
- `Database::table_count` (`frame.rs`): Return number of tables.
- `Database::clear` (`frame.rs`): Remove all tables.
- `Database::merge` (`frame.rs`): Merge another database into self by table name.
- `Database::clone_db` (`frame.rs`): Clone database deeply.
- `AggFn::parse` (`frame.rs`): Parse aggregation label and return mode or error.
- `LazyQuery::new` (`lazy.rs`): Create lazy query from source frame.
- `LazyQuery::tombstone` (`lazy.rs`): Create empty sentinel lazy query.
- `LazyQuery::filter` (`lazy.rs`): Append filter step and return updated query.
- `LazyQuery::sort` (`lazy.rs`): Append sort step and return updated query.
- `LazyQuery::select` (`lazy.rs`): Append column selection step and return updated query.
- `LazyQuery::head` (`lazy.rs`): Append head step and return updated query.
- `LazyQuery::tail` (`lazy.rs`): Append tail step and return updated query.
- `LazyQuery::slice` (`lazy.rs`): Append slice step and return updated query.
- `LazyQuery::drop_nil` (`lazy.rs`): Append drop-nil step and return updated query.
- `LazyQuery::limit` (`lazy.rs`): Append row limit step and return updated query.
- `LazyQuery::collect` (`lazy.rs`): Execute deferred steps and return materialized frame.
- `DataFrame::lazy` (`lazy.rs`): Create lazy query from cloned current frame.
- `percentile` (`query/analytics.rs`): Compute percentile by linear interpolation over sorted values.
- `DataFrame::zscore_col` (`query/analytics.rs`): Compute z-score for numeric column and write result column.
- `DataFrame::normalize_col` (`query/analytics.rs`): Normalize numeric column to output range and write result column.
- `DataFrame::outliers` (`query/analytics.rs`): Return rows where absolute z-score exceeds threshold.
- `DataFrame::mode_val` (`query/analytics.rs`): Return most frequent non-nil value in selected column.
- `DataFrame::entropy` (`query/analytics.rs`): Compute Shannon entropy over rendered cell values.
- `DataFrame::filter` (`query/filter.rs`): Filter rows by column predicate and return matching frame.
- `DataFrame::sort` (`query/filter.rs`): Sort rows by column and return sorted frame.
- `DataFrame::head` (`query/filter.rs`): Return first n rows as new frame.
- `DataFrame::tail` (`query/filter.rs`): Return last n rows as new frame.
- `DataFrame::slice` (`query/filter.rs`): Return inclusive row slice as new frame.
- `DataFrame::select_columns` (`query/filter.rs`): Select subset of columns and return new frame.
- `DataFrame::unique` (`query/filter.rs`): Return unique values from selected column.
- `DataFrame::group_by` (`query/filter.rs`): Group rows by key column and return grouped frames.
- `DataFrame::join` (`query/filter.rs`): Join two frames by key columns and return merged frame.
- `DataFrame::merge` (`query/filter.rs`): Append columns and rows from other frame into self.
- `DataFrame::count_by` (`query/filter.rs`): Count occurrences by key column and return two-column frame.
- `DataFrame::drop_nil` (`query/filter.rs`): Drop rows where selected column is nil.
- `DataFrame::sample` (`query/filter.rs`): Sample up to n rows using deterministic optional seed.
- `DataFrame::sum` (`query/filter.rs`): Sum numeric values from selected column.
- `DataFrame::mean` (`query/filter.rs`): Compute mean of numeric values from selected column.
- `DataFrame::min_val` (`query/filter.rs`): Return minimum numeric value from selected column.
- `DataFrame::max_val` (`query/filter.rs`): Return maximum numeric value from selected column.
- `DataFrame::median` (`query/filter.rs`): Compute median of numeric values from selected column.
- `DataFrame::stddev` (`query/filter.rs`): Compute standard deviation of numeric values from column.
- `DataFrame::variance` (`query/filter.rs`): Compute variance of numeric values from column.
- `DataFrame::describe` (`query/filter.rs`): Build descriptive statistics frame for numeric columns.
- `DataFrame::fill_nil` (`query/filter.rs`): Replace nil values in selected column with provided value.
- `DataFrame::extract_rows` (`query/filter.rs`): Extract rows by indices and return new frame.
- `DataFrame::collect_numbers` (`query/filter.rs`): Collect numeric values from selected column.
- `DataFrame::add_row_batch` (`query/filter.rs`): Append batch of rows to frame and return error on width mismatch.
- `DataFrame::get_column_as_f64` (`query/filter.rs`): Export selected column as f64 vector with nil as NaN.
- `DataFrame::set_column_from_f64` (`query/filter.rs`): Set selected column from f64 vector with NaN mapped to nil.
- `DataFrame::group_agg` (`query/grouping.rs`): Aggregate values by group key and return grouped result frame.
- `DataFrame::pivot` (`query/grouping.rs`): Pivot row and column keys into cross-tabulated frame.
- `DataFrame::corr` (`query/grouping.rs`): Compute Pearson correlation between two numeric columns.
- `DataFrame::correlation_matrix` (`query/grouping.rs`): Build numeric-column correlation matrix frame.
- `DataFrame::with_rolling_mean` (`query/window.rs`): Compute rolling mean and append output column.
- `DataFrame::with_rolling_sum` (`query/window.rs`): Compute rolling sum and append output column.
- `DataFrame::with_rolling_min` (`query/window.rs`): Compute rolling minimum and append output column.
- `DataFrame::with_rolling_max` (`query/window.rs`): Compute rolling maximum and append output column.
- `DataFrame::with_rank` (`query/window.rs`): Compute rank over numeric column and append output column.
- `DataFrame::with_pct_change` (`query/window.rs`): Compute row-to-row percent change and append output column.
- `DataFrame::with_cumsum` (`query/window.rs`): Compute cumulative sum and append output column.
- `Xorshift64::new` (`rng.rs`): Create generator from seed and remap zero seed to one.
- `Xorshift64::next_u64` (`rng.rs`): Advance generator and return next 64-bit pseudo-random value.
- `Xorshift64::next_f64` (`rng.rs`): Return pseudo-random float in the half-open range [0, 1).
- `Xorshift64::next_usize` (`rng.rs`): Return pseudo-random index in the half-open range [0, max).
- `from_csv` (`serial.rs`): Parse a CSV string into a DataFrame.
- `DataFrame::to_csv` (`serial.rs`): Serialize DataFrame to CSV string.
- `from_json` (`serial.rs`): Parse JSON (array-of-objects) into a DataFrame.
- `DataFrame::to_json` (`serial.rs`): Serialize DataFrame to JSON table string.
- `DataFrame::to_binary` (`serial.rs`): Serialize DataFrame to compact binary format bytes.
- `from_binary` (`serial.rs`): Deserialize a DataFrame from LVDF binary format.
- `DataFrame::to_string_table` (`serial.rs`): Render DataFrame as padded string table.
- `Database::to_json` (`serial.rs`): Serialize Database tables to JSON string.
- `query_sql` (`sql.rs`): Execute a SQL query on a single DataFrame.
- `query_sql_database` (`sql.rs`): Execute a SQL query on a Database (supports FROM and JOIN).
- `ColumnStore::dtype_name` (`vectorized.rs`): Return static type name for this column variant.
- `ColumnStore::len` (`vectorized.rs`): Return number of rows in this column.
- `ColumnStore::is_empty` (`vectorized.rs`): Return true when this column has no rows.
- `ColumnStore::is_valid` (`vectorized.rs`): Return true when row at index is valid according to validity mask.
- `ColumnStore::valid_f64s` (`vectorized.rs`): Return valid f64 values for Float64 columns, skipping nil rows.
- `ColumnStore::filter` (`vectorized.rs`): Filter rows by boolean mask and return new column.
- `ScalarOp::parse` (`vectorized.rs`): Parse operation label and return variant or error.
- `BinaryOp::parse` (`vectorized.rs`): Parse operation label and return variant or error.
- `ReduceOp::parse` (`vectorized.rs`): Parse operation label and return variant or error.
- `CmpOp::parse` (`vectorized.rs`): Parse comparison operator string and return variant or error.
- `VecFrame::new` (`vectorized.rs`): Create empty VecFrame.
- `VecFrame::nrows` (`vectorized.rs`): Return number of rows.
- `VecFrame::ncols` (`vectorized.rs`): Return number of columns.
- `VecFrame::columns` (`vectorized.rs`): Return ordered column names.
- `VecFrame::col_type` (`vectorized.rs`): Return type name for named column.
- `VecFrame::from_dataframe` (`vectorized.rs`): Convert DataFrame to VecFrame by inferring column types.
- `VecFrame::to_dataframe` (`vectorized.rs`): Convert VecFrame back to DataFrame.
- `VecFrame::col_scalar_op` (`vectorized.rs`): Apply scalar operation to Float64 column in place.
- `VecFrame::col_clamp` (`vectorized.rs`): Clamp Float64 column values to inclusive range in place.
- `VecFrame::col_binary_op` (`vectorized.rs`): Compute element-wise binary operation between two numeric columns and write result column.
- `VecFrame::col_reduce` (`vectorized.rs`): Reduce numeric column to single value using selected aggregation.
- `VecFrame::filter_mask` (`vectorized.rs`): Build boolean mask by comparing numeric column against scalar value.
- `VecFrame::apply_mask` (`vectorized.rs`): Filter all columns by boolean mask and return new VecFrame.
- `VecFrame::col_cast` (`vectorized.rs`): Cast named column to target type in place.
- `VecFrame::par_reduce` (`vectorized.rs`): Reduce multiple columns in parallel and return name-to-result map.
- `VecFrame::par_scalar_op` (`vectorized.rs`): Apply scalar operation across multiple Float64 columns in parallel.

## Lua API Reference

- Binding path(s): `src/lua_api/dataframe_api.rs`
- Namespace: `lurek.dataframe`

### Module Functions
- `lurek.dataframe.newDataFrame`: Creates an empty dataframe.
- `lurek.dataframe.newDatabase`: Creates an empty dataframe database.
- `lurek.dataframe.fromTable`: Creates a dataframe from an array table of row tables.
- `lurek.dataframe.fromRows`: Creates a dataframe from column names and array-style rows.
- `lurek.dataframe.fromCSV`: Parses a dataframe from CSV text.
- `lurek.dataframe.fromJSON`: Parses a dataframe from JSON text.
- `lurek.dataframe.fromBinary`: Parses a dataframe from binary data.
- `lurek.dataframe.random`: Creates a random dataframe from column definitions.
- `lurek.dataframe.toVec`: Converts a dataframe to a vectorized frame.
- `lurek.dataframe.fromVec`: Converts a vectorized frame to a dataframe.

### `LDataFrame` Methods
- `LDataFrame:nrows`: Returns the number of rows in this dataframe.
- `LDataFrame:ncols`: Returns the number of columns in this dataframe.
- `LDataFrame:columns`: Returns all column names in order.
- `LDataFrame:count`: Returns the row count for this dataframe.
- `LDataFrame:addColumn`: Adds a column with an optional default value.
- `LDataFrame:removeColumn`: Removes a column by name or one-based index.
- `LDataFrame:rename`: Renames a column by name or one-based index.
- `LDataFrame:getColumn`: Returns a column as an array table.
- `LDataFrame:addRow`: Adds a row from an optional map table and returns its one-based row index.
- `LDataFrame:removeRow`: Removes a row by one-based index.
- `LDataFrame:getRow`: Returns a row as a table keyed by column name.
- `LDataFrame:getValue`: Returns one cell value by one-based row and column reference.
- `LDataFrame:setValue`: Sets one cell value by one-based row and column reference.
- `LDataFrame:filter`: Returns rows whose column value matches a comparison.
- `LDataFrame:sort`: Returns rows sorted by a column.
- `LDataFrame:head`: Returns the first rows of this dataframe.
- `LDataFrame:tail`: Returns the last rows of this dataframe.
- `LDataFrame:slice`: Returns a one-based inclusive row slice.
- `LDataFrame:select`: Returns a dataframe with selected columns.
- `LDataFrame:unique`: Returns unique values from a column.
- `LDataFrame:groupBy`: Groups rows by a column and returns a table from group key to dataframe.
- `LDataFrame:groupByObj`: Groups rows by a column and returns a grouped-frame object.
- `LDataFrame:join`: Joins this dataframe with another dataframe by column references.
- `LDataFrame:merge`: Appends another dataframe into this dataframe in place.
- `LDataFrame:countBy`: Counts occurrences of each value in a column.
- `LDataFrame:dropNil`: Returns rows where the chosen column is not nil.
- `LDataFrame:sample`: Returns a sampled dataframe.
- `LDataFrame:describe`: Returns summary statistics for numeric columns.
- `LDataFrame:sum`: Returns the numeric sum of a column.
- `LDataFrame:mean`: Returns the numeric mean of a column.
- `LDataFrame:min`: Returns the minimum value of a column.
- `LDataFrame:max`: Returns the maximum value of a column.
- `LDataFrame:median`: Returns the numeric median of a column.
- `LDataFrame:stddev`: Returns the numeric standard deviation of a column.
- `LDataFrame:variance`: Returns the numeric variance of a column.
- `LDataFrame:fillNil`: Replaces nil cells in a column with a value.
- `LDataFrame:apply`: Applies a Lua function to each value in a column in place.
- `LDataFrame:toCSV`: Serializes this dataframe to CSV text.
- `LDataFrame:toJSON`: Serializes this dataframe to JSON text.
- `LDataFrame:toBinary`: Serializes this dataframe to binary data.
- `LDataFrame:toTable`: Converts this dataframe to an array table of row tables.
- `LDataFrame:rows`: Returns an iterator function over one-based row index and row table pairs.
- `LDataFrame:toString`: Formats this dataframe as a human-readable text table.
- `LDataFrame:query`: Runs a SQL-style query against this dataframe.
- `LDataFrame:clone`: Returns a deep copy of this dataframe.
- `LDataFrame:withRollingMean`: Adds a rolling mean column in place.
- `LDataFrame:withRollingSum`: Adds a rolling sum column in place.
- `LDataFrame:withRollingMin`: Adds a rolling minimum column in place.
- `LDataFrame:withRollingMax`: Adds a rolling maximum column in place.
- `LDataFrame:withRank`: Adds a rank column in place.
- `LDataFrame:withPctChange`: Adds a percent-change column in place.
- `LDataFrame:withCumsum`: Adds a cumulative-sum column in place.
- `LDataFrame:groupAgg`: Groups by one column and aggregates another column.
- `LDataFrame:pivot`: Pivots rows into columns using row, column, and value fields.
- `LDataFrame:corr`: Returns correlation between two numeric columns.
- `LDataFrame:correlationMatrix`: Returns a correlation matrix for numeric columns.
- `LDataFrame:zscoreCol`: Adds a z-score normalized column in place.
- `LDataFrame:normalizeCol`: Adds a range-normalized column in place.
- `LDataFrame:outliers`: Returns rows considered outliers for a numeric column.
- `LDataFrame:modeVal`: Returns the mode value of a column.
- `LDataFrame:entropy`: Returns entropy for a column.
- `LDataFrame:addRowBatch`: Appends multiple rows from array-style row tables.
- `LDataFrame:getColumnAsF64`: Returns a numeric column as an array of numbers.
- `LDataFrame:setColumnFromF64`: Replaces a numeric column from an array table of numbers.
- `LDataFrame:type`: Returns the Lua-visible type name for this dataframe handle.
- `LDataFrame:typeOf`: Returns whether this dataframe handle matches a supported type name.
- `LDataFrame:withEval`: Returns a dataframe with a column computed from an expression.
- `LDataFrame:pivotTable`: Builds a pivot table using row key, column key, value column, and aggregate function.
- `LDataFrame:rollingMean`: Returns a dataframe with a rolling mean column.
- `LDataFrame:rollingSum`: Returns a dataframe with a rolling sum column.
- `LDataFrame:rank`: Returns a dataframe with a rank column.
- `LDataFrame:lazy`: Starts a lazy query pipeline from this dataframe.

### `LDatabase` Methods
- `LDatabase:addTable`: Adds or replaces a named dataframe table in the database.
- `LDatabase:getTable`: Returns a copy of a named table when it exists.
- `LDatabase:removeTable`: Removes a named table from the database.
- `LDatabase:hasTable`: Returns whether a named table exists.
- `LDatabase:listTables`: Returns all table names in the database.
- `LDatabase:tableCount`: Returns the number of tables in the database.
- `LDatabase:clear`: Removes every table from the database.
- `LDatabase:merge`: Merges another database into this database.
- `LDatabase:toJSON`: Serializes the database to JSON text.
- `LDatabase:query`: Runs a SQL-style query against the database tables.
- `LDatabase:type`: Returns the Lua-visible type name for this database handle.
- `LDatabase:typeOf`: Returns whether this database handle matches a supported type name.

### `LGroupedFrame` Methods
- `LGroupedFrame:aggregate`: Aggregates one numeric column in every group by calling a Lua function with that group's numeric values.
- `LGroupedFrame:type`: Returns the Lua-visible type name for this grouped frame handle.
- `LGroupedFrame:typeOf`: Returns whether this grouped frame handle matches a supported type name.

### `LLazyQuery` Methods
- `LLazyQuery:filter`: Adds a filter step to the lazy query.
- `LLazyQuery:sort`: Adds a sort step to the lazy query.
- `LLazyQuery:head`: Adds a head limit step to the lazy query.
- `LLazyQuery:tail`: Adds a tail limit step to the lazy query.
- `LLazyQuery:limit`: Adds a row limit step to the lazy query.
- `LLazyQuery:slice`: Adds a one-based row slice step to the lazy query.
- `LLazyQuery:dropNil`: Adds a step that drops rows with nil values in a column.
- `LLazyQuery:select`: Adds a column selection step to the lazy query.
- `LLazyQuery:collect`: Executes the lazy query and returns a dataframe.
- `LLazyQuery:type`: Returns the Lua-visible type name for this lazy query handle.
- `LLazyQuery:typeOf`: Returns whether this lazy query handle matches a supported type name.

### `LVecFrame` Methods
- `LVecFrame:colAdd`: Adds a scalar to a numeric column in place.
- `LVecFrame:colSub`: Subtracts a scalar from a numeric column in place.
- `LVecFrame:colMul`: Multiplies a numeric column by a scalar in place.
- `LVecFrame:colDiv`: Divides a numeric column by a scalar in place.
- `LVecFrame:colAbs`: Applies absolute value to a numeric column in place.
- `LVecFrame:colSqrt`: Applies square root to a numeric column in place.
- `LVecFrame:colFloor`: Applies floor to a numeric column in place.
- `LVecFrame:colCeil`: Applies ceil to a numeric column in place.
- `LVecFrame:colNeg`: Negates a numeric column in place.
- `LVecFrame:colClamp`: Clamps a numeric column in place.
- `LVecFrame:colOp`: Applies a binary column operation into an output column.
- `LVecFrame:reduce`: Reduces a numeric column with a named operation.
- `LVecFrame:filterMask`: Builds a boolean mask for a numeric column comparison.
- `LVecFrame:applyMask`: Returns a vectorized frame filtered by a boolean mask table.
- `LVecFrame:colType`: Returns the data type name for a vectorized column.
- `LVecFrame:colCast`: Casts a vectorized column to another data type in place.
- `LVecFrame:nrows`: Returns the number of rows in this vectorized frame.
- `LVecFrame:ncols`: Returns the number of columns in this vectorized frame.
- `LVecFrame:columns`: Returns all vectorized column names in order.
- `LVecFrame:parReduce`: Reduces multiple numeric columns in parallel.
- `LVecFrame:parScalarOp`: Applies a scalar operation to multiple numeric columns in parallel.
- `LVecFrame:toDataFrame`: Converts this vectorized frame to a dataframe.
- `LVecFrame:type`: Returns the Lua-visible type name for this vectorized frame handle.
- `LVecFrame:typeOf`: Returns whether this vectorized frame handle matches a supported type name.

## References

- No top-level `crate::<module>` imports were detected in this module's Rust source files.

## Notes

- Keep this module reference synchronized with `src/dataframe/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
