//! Integration tests for the DataFrame module (Phase 22).

use lurek2d::dataframe::{CellValue, ColRef, DataFrame, Database};

// ============================================================================
// Helper
// ============================================================================

/// Build a simple 3-row, 2-column DataFrame for reuse.
fn sample_df() -> DataFrame {
    DataFrame::from_raw(
        vec!["name".to_string(), "score".to_string()],
        vec![
            vec![
                CellValue::Text("Alice".to_string()),
                CellValue::Text("Bob".to_string()),
                CellValue::Text("Charlie".to_string()),
            ],
            vec![
                CellValue::Number(90.0),
                CellValue::Number(75.0),
                CellValue::Number(85.0),
            ],
        ],
    )
}

// ============================================================================
// CellValue
// ============================================================================

#[test]
fn cellvalue_nil_is_nil() {
    assert!(CellValue::Nil.is_nil());
    assert!(!CellValue::Number(0.0).is_nil());
}

#[test]
fn cellvalue_as_number() {
    assert!((CellValue::Number(3.14).as_number().unwrap() - 3.14).abs() < 1e-5);
    assert!(CellValue::Text("x".to_string()).as_number().is_none());
    assert!(CellValue::Nil.as_number().is_none());
}

#[test]
fn cellvalue_as_text() {
    assert_eq!(CellValue::Text("hi".to_string()).as_text().unwrap(), "hi");
    assert!(CellValue::Number(1.0).as_text().is_none());
}

#[test]
fn cellvalue_as_bool() {
    assert!(CellValue::Bool(true).as_bool().unwrap());
    assert!(CellValue::Nil.as_bool().is_none());
}

#[test]
fn cellvalue_display_nil() {
    assert_eq!(format!("{}", CellValue::Nil), "nil");
}

#[test]
fn cellvalue_display_number_integer() {
    assert_eq!(format!("{}", CellValue::Number(42.0)), "42");
}

#[test]
fn cellvalue_display_number_float() {
    assert_eq!(format!("{}", CellValue::Number(3.14)), "3.14");
}

#[test]
fn cellvalue_display_text() {
    assert_eq!(format!("{}", CellValue::Text("hello".to_string())), "hello");
}

#[test]
fn cellvalue_display_bool() {
    assert_eq!(format!("{}", CellValue::Bool(true)), "true");
    assert_eq!(format!("{}", CellValue::Bool(false)), "false");
}

#[test]
fn cellvalue_debug_variants() {
    // Just ensure Debug is implemented and doesn't panic
    let _ = format!("{:?}", CellValue::Nil);
    let _ = format!("{:?}", CellValue::Number(1.0));
    let _ = format!("{:?}", CellValue::Text("x".to_string()));
    let _ = format!("{:?}", CellValue::Bool(false));
}

#[test]
fn cellvalue_cmp_for_sort_nil_goes_last() {
    use std::cmp::Ordering;
    assert_eq!(CellValue::Nil.cmp_for_sort(&CellValue::Number(1.0)), Ordering::Greater);
    assert_eq!(CellValue::Number(1.0).cmp_for_sort(&CellValue::Nil), Ordering::Less);
    assert_eq!(CellValue::Nil.cmp_for_sort(&CellValue::Nil), Ordering::Equal);
}

// ============================================================================
// DataFrame Construction
// ============================================================================

#[test]
fn dataframe_new_empty() {
    let df = DataFrame::new();
    assert_eq!(df.nrows(), 0);
    assert_eq!(df.ncols(), 0);
    assert!(df.columns().is_empty());
}

#[test]
fn dataframe_default_is_empty() {
    let df = DataFrame::default();
    assert_eq!(df.nrows(), 0);
    assert_eq!(df.ncols(), 0);
}

#[test]
fn dataframe_from_raw() {
    let df = sample_df();
    assert_eq!(df.nrows(), 3);
    assert_eq!(df.ncols(), 2);
    let cols: Vec<&str> = df.columns().iter().map(|s| s.as_str()).collect();
    assert_eq!(cols, vec!["name", "score"]);
}

#[test]
fn dataframe_count_alias() {
    let df = sample_df();
    assert_eq!(df.nrows(), df.count());
}

// ============================================================================
// Column Operations
// ============================================================================

#[test]
fn dataframe_add_column() {
    let mut df = sample_df();
    df.add_column("grade", CellValue::Text("A".to_string()))
        .unwrap();
    assert_eq!(df.ncols(), 3);
    assert_eq!(df.columns()[2], "grade");
    // Default value filled for existing rows
    let col = df.get_column(ColRef::Name("grade".to_string())).unwrap();
    assert_eq!(col.len(), 3);
    assert_eq!(col[0], CellValue::Text("A".to_string()));
}

#[test]
fn dataframe_add_column_duplicate_errors() {
    let mut df = sample_df();
    let result = df.add_column("name", CellValue::Nil);
    assert!(result.is_err());
}

#[test]
fn dataframe_remove_column_by_name() {
    let mut df = sample_df();
    df.remove_column(ColRef::Name("score".to_string())).unwrap();
    assert_eq!(df.ncols(), 1);
    let cols: Vec<&str> = df.columns().iter().map(|s| s.as_str()).collect();
    assert_eq!(cols, vec!["name"]);
}

#[test]
fn dataframe_remove_column_not_found_errors() {
    let mut df = sample_df();
    let result = df.remove_column(ColRef::Name("missing".to_string()));
    assert!(result.is_err());
}

#[test]
fn dataframe_rename_column() {
    let mut df = sample_df();
    df.rename_column(ColRef::Name("score".to_string()), "points")
        .unwrap();
    let cols: Vec<&str> = df.columns().iter().map(|s| s.as_str()).collect();
    assert_eq!(cols, vec!["name", "points"]);
}

#[test]
fn dataframe_rename_column_duplicate_errors() {
    let mut df = sample_df();
    let result = df.rename_column(ColRef::Name("score".to_string()), "name");
    assert!(result.is_err());
}

#[test]
fn dataframe_get_column_by_name() {
    let df = sample_df();
    let col = df.get_column(ColRef::Name("name".to_string())).unwrap();
    assert_eq!(col.len(), 3);
    assert_eq!(col[0], CellValue::Text("Alice".to_string()));
}

#[test]
fn dataframe_get_column_by_index() {
    let df = sample_df();
    // ColRef::Index is 1-based
    let col = df.get_column(ColRef::Index(2)).unwrap();
    assert_eq!(col[0], CellValue::Number(90.0));
}

#[test]
fn dataframe_resolve_col_index_zero_errors() {
    let df = sample_df();
    let result = df.resolve_col(ColRef::Index(0));
    assert!(result.is_err());
}

#[test]
fn dataframe_resolve_col_index_out_of_range_errors() {
    let df = sample_df();
    let result = df.resolve_col(ColRef::Index(99));
    assert!(result.is_err());
}

// ============================================================================
// Row Operations
// ============================================================================

#[test]
fn dataframe_add_row_returns_index() {
    let mut df = sample_df();
    let idx = df.add_row(&[
        ("name".to_string(), CellValue::Text("Diana".to_string())),
        ("score".to_string(), CellValue::Number(95.0)),
    ]);
    assert_eq!(idx, 3);
    assert_eq!(df.nrows(), 4);
}

#[test]
fn dataframe_add_row_missing_column_fills_nil() {
    let mut df = sample_df();
    df.add_row(&[("name".to_string(), CellValue::Text("Eve".to_string()))]);
    let val = df.get_value(3, ColRef::Name("score".to_string())).unwrap();
    assert!(val.is_nil());
}

#[test]
fn dataframe_remove_row() {
    let mut df = sample_df();
    df.remove_row(1).unwrap();
    assert_eq!(df.nrows(), 2);
    // Row 0 is still Alice, row 1 is now Charlie
    let val = df.get_value(1, ColRef::Name("name".to_string())).unwrap();
    assert_eq!(val, CellValue::Text("Charlie".to_string()));
}

#[test]
fn dataframe_remove_row_out_of_range_errors() {
    let mut df = sample_df();
    assert!(df.remove_row(99).is_err());
}

#[test]
fn dataframe_get_row() {
    let df = sample_df();
    let row = df.get_row(0).unwrap();
    assert_eq!(row.len(), 2);
    assert_eq!(row[0].0, "name");
    assert_eq!(row[0].1, CellValue::Text("Alice".to_string()));
    assert_eq!(row[1].0, "score");
    assert_eq!(row[1].1, CellValue::Number(90.0));
}

#[test]
fn dataframe_get_row_out_of_range_errors() {
    let df = sample_df();
    assert!(df.get_row(99).is_err());
}

// ============================================================================
// Cell Access
// ============================================================================

#[test]
fn dataframe_get_value() {
    let df = sample_df();
    let val = df.get_value(1, ColRef::Name("score".to_string())).unwrap();
    assert_eq!(val, CellValue::Number(75.0));
}

#[test]
fn dataframe_set_value() {
    let mut df = sample_df();
    df.set_value(
        0,
        ColRef::Name("score".to_string()),
        CellValue::Number(100.0),
    )
    .unwrap();
    let val = df.get_value(0, ColRef::Name("score".to_string())).unwrap();
    assert_eq!(val, CellValue::Number(100.0));
}

#[test]
fn dataframe_get_value_out_of_range_errors() {
    let df = sample_df();
    assert!(df.get_value(99, ColRef::Name("name".to_string())).is_err());
}

#[test]
fn dataframe_set_value_out_of_range_errors() {
    let mut df = sample_df();
    assert!(df
        .set_value(99, ColRef::Name("name".to_string()), CellValue::Nil)
        .is_err());
}

// ============================================================================
// Query: filter
// ============================================================================

#[test]
fn filter_equals() {
    let df = sample_df();
    let result = df
        .filter(
            ColRef::Name("name".to_string()),
            "==",
            &CellValue::Text("Bob".to_string()),
        )
        .unwrap();
    assert_eq!(result.nrows(), 1);
    let val = result.get_value(0, ColRef::Name("name".to_string())).unwrap();
    assert_eq!(val, CellValue::Text("Bob".to_string()));
}

#[test]
fn filter_not_equals() {
    let df = sample_df();
    let result = df
        .filter(
            ColRef::Name("name".to_string()),
            "!=",
            &CellValue::Text("Bob".to_string()),
        )
        .unwrap();
    assert_eq!(result.nrows(), 2);
}

#[test]
fn filter_less_than() {
    let df = sample_df();
    let result = df
        .filter(
            ColRef::Name("score".to_string()),
            "<",
            &CellValue::Number(85.0),
        )
        .unwrap();
    assert_eq!(result.nrows(), 1);
    let val = result.get_value(0, ColRef::Name("name".to_string())).unwrap();
    assert_eq!(val, CellValue::Text("Bob".to_string()));
}

#[test]
fn filter_greater_equal() {
    let df = sample_df();
    let result = df
        .filter(
            ColRef::Name("score".to_string()),
            ">=",
            &CellValue::Number(85.0),
        )
        .unwrap();
    assert_eq!(result.nrows(), 2);
}

#[test]
fn filter_less_equal() {
    let df = sample_df();
    let result = df
        .filter(
            ColRef::Name("score".to_string()),
            "<=",
            &CellValue::Number(85.0),
        )
        .unwrap();
    assert_eq!(result.nrows(), 2);
}

#[test]
fn filter_greater_than() {
    let df = sample_df();
    let result = df
        .filter(
            ColRef::Name("score".to_string()),
            ">",
            &CellValue::Number(85.0),
        )
        .unwrap();
    assert_eq!(result.nrows(), 1);
}

#[test]
fn filter_contains() {
    let df = sample_df();
    let result = df
        .filter(
            ColRef::Name("name".to_string()),
            "contains",
            &CellValue::Text("li".to_string()),
        )
        .unwrap();
    // "Alice" and "Charlie" both contain "li"
    assert_eq!(result.nrows(), 2);
}

#[test]
fn filter_unsupported_op_errors() {
    let df = sample_df();
    let result = df.filter(
        ColRef::Name("name".to_string()),
        "~~",
        &CellValue::Text("x".to_string()),
    );
    assert!(result.is_err());
}

#[test]
fn filter_no_matches_returns_empty() {
    let df = sample_df();
    let result = df
        .filter(
            ColRef::Name("score".to_string()),
            ">",
            &CellValue::Number(999.0),
        )
        .unwrap();
    assert_eq!(result.nrows(), 0);
    assert_eq!(result.ncols(), 2); // columns preserved
}

// ============================================================================
// Query: sort, head, tail, slice
// ============================================================================

#[test]
fn sort_ascending() {
    let df = sample_df();
    let sorted = df.sort(ColRef::Name("score".to_string()), true).unwrap();
    let first = sorted
        .get_value(0, ColRef::Name("score".to_string()))
        .unwrap();
    let last = sorted
        .get_value(2, ColRef::Name("score".to_string()))
        .unwrap();
    assert!((first.as_number().unwrap() - 75.0).abs() < 1e-5);
    assert!((last.as_number().unwrap() - 90.0).abs() < 1e-5);
}

#[test]
fn sort_descending() {
    let df = sample_df();
    let sorted = df.sort(ColRef::Name("score".to_string()), false).unwrap();
    let first = sorted
        .get_value(0, ColRef::Name("score".to_string()))
        .unwrap();
    assert!((first.as_number().unwrap() - 90.0).abs() < 1e-5);
}

#[test]
fn head() {
    let df = sample_df();
    let h = df.head(2);
    assert_eq!(h.nrows(), 2);
    let val = h.get_value(0, ColRef::Name("name".to_string())).unwrap();
    assert_eq!(val, CellValue::Text("Alice".to_string()));
}

#[test]
fn head_larger_than_nrows() {
    let df = sample_df();
    let h = df.head(100);
    assert_eq!(h.nrows(), 3);
}

#[test]
fn tail() {
    let df = sample_df();
    let t = df.tail(1);
    assert_eq!(t.nrows(), 1);
    let val = t.get_value(0, ColRef::Name("name".to_string())).unwrap();
    assert_eq!(val, CellValue::Text("Charlie".to_string()));
}

#[test]
fn slice_basic() {
    let df = sample_df();
    let s = df.slice(0, 1).unwrap();
    assert_eq!(s.nrows(), 2); // inclusive on both ends
}

#[test]
fn slice_out_of_range_start_errors() {
    let df = sample_df();
    assert!(df.slice(99, 100).is_err());
}

#[test]
fn slice_end_clamped() {
    let df = sample_df();
    let s = df.slice(1, 999).unwrap();
    assert_eq!(s.nrows(), 2); // rows 1 and 2
}

// ============================================================================
// Query: select_columns, unique, count_by, drop_nil
// ============================================================================

#[test]
fn select_columns() {
    let df = sample_df();
    let projected = df
        .select_columns(&[ColRef::Name("score".to_string())])
        .unwrap();
    assert_eq!(projected.ncols(), 1);
    let cols: Vec<&str> = projected.columns().iter().map(|s| s.as_str()).collect();
    assert_eq!(cols, vec!["score"]);
    assert_eq!(projected.nrows(), 3);
}

#[test]
fn unique() {
    let df = DataFrame::from_raw(
        vec!["color".to_string()],
        vec![vec![
            CellValue::Text("red".to_string()),
            CellValue::Text("blue".to_string()),
            CellValue::Text("red".to_string()),
            CellValue::Text("green".to_string()),
        ]],
    );
    let vals = df.unique(ColRef::Name("color".to_string())).unwrap();
    assert_eq!(vals.len(), 3);
}

#[test]
fn count_by() {
    let df = DataFrame::from_raw(
        vec!["color".to_string()],
        vec![vec![
            CellValue::Text("red".to_string()),
            CellValue::Text("blue".to_string()),
            CellValue::Text("red".to_string()),
        ]],
    );
    let counts = df.count_by(ColRef::Name("color".to_string())).unwrap();
    assert_eq!(counts.nrows(), 2); // red and blue
    let cols: Vec<&str> = counts.columns().iter().map(|s| s.as_str()).collect();
    assert_eq!(cols, vec!["value", "count"]);
}

#[test]
fn drop_nil() {
    let df = DataFrame::from_raw(
        vec!["x".to_string()],
        vec![vec![
            CellValue::Number(1.0),
            CellValue::Nil,
            CellValue::Number(3.0),
        ]],
    );
    let cleaned = df.drop_nil(ColRef::Name("x".to_string())).unwrap();
    assert_eq!(cleaned.nrows(), 2);
}

// ============================================================================
// Query: join
// ============================================================================

#[test]
fn join_inner() {
    let left = DataFrame::from_raw(
        vec!["id".to_string(), "name".to_string()],
        vec![
            vec![
                CellValue::Number(1.0),
                CellValue::Number(2.0),
                CellValue::Number(3.0),
            ],
            vec![
                CellValue::Text("Alice".to_string()),
                CellValue::Text("Bob".to_string()),
                CellValue::Text("Charlie".to_string()),
            ],
        ],
    );
    let right = DataFrame::from_raw(
        vec!["id".to_string(), "score".to_string()],
        vec![
            vec![CellValue::Number(1.0), CellValue::Number(3.0)],
            vec![CellValue::Number(90.0), CellValue::Number(85.0)],
        ],
    );
    let joined = left
        .join(
            &right,
            ColRef::Name("id".to_string()),
            ColRef::Name("id".to_string()),
            "inner",
        )
        .unwrap();
    assert_eq!(joined.nrows(), 2); // ids 1 and 3
    assert_eq!(joined.ncols(), 3); // id, name, score (id is shared)
}

// ============================================================================
// Analytics
// ============================================================================

fn numeric_df() -> DataFrame {
    DataFrame::from_raw(
        vec!["val".to_string()],
        vec![vec![
            CellValue::Number(10.0),
            CellValue::Number(20.0),
            CellValue::Number(30.0),
            CellValue::Number(40.0),
            CellValue::Number(50.0),
        ]],
    )
}

#[test]
fn sum() {
    let df = numeric_df();
    let s = df.sum(ColRef::Name("val".to_string())).unwrap();
    assert!((s - 150.0).abs() < 1e-5);
}

#[test]
fn mean() {
    let df = numeric_df();
    let m = df.mean(ColRef::Name("val".to_string())).unwrap();
    assert!((m - 30.0).abs() < 1e-5);
}

#[test]
fn min_val() {
    let df = numeric_df();
    let v = df.min_val(ColRef::Name("val".to_string())).unwrap();
    assert!((v - 10.0).abs() < 1e-5);
}

#[test]
fn max_val() {
    let df = numeric_df();
    let v = df.max_val(ColRef::Name("val".to_string())).unwrap();
    assert!((v - 50.0).abs() < 1e-5);
}

#[test]
fn median_odd_count() {
    let df = numeric_df();
    let m = df.median(ColRef::Name("val".to_string())).unwrap();
    assert!((m - 30.0).abs() < 1e-5);
}

#[test]
fn median_even_count() {
    let df = DataFrame::from_raw(
        vec!["val".to_string()],
        vec![vec![
            CellValue::Number(10.0),
            CellValue::Number(20.0),
            CellValue::Number(30.0),
            CellValue::Number(40.0),
        ]],
    );
    let m = df.median(ColRef::Name("val".to_string())).unwrap();
    assert!((m - 25.0).abs() < 1e-5);
}

#[test]
fn variance() {
    let df = numeric_df();
    // Population variance of [10,20,30,40,50] = 200
    let v = df.variance(ColRef::Name("val".to_string())).unwrap();
    assert!((v - 200.0).abs() < 1e-5);
}

#[test]
fn stddev() {
    let df = numeric_df();
    let sd = df.stddev(ColRef::Name("val".to_string())).unwrap();
    // sqrt(200) ~= 14.14213562
    assert!((sd - 200.0_f64.sqrt()).abs() < 1e-5);
}

#[test]
fn analytics_empty_column_errors() {
    let df = DataFrame::from_raw(
        vec!["x".to_string()],
        vec![vec![CellValue::Nil, CellValue::Nil]],
    );
    assert!(df.mean(ColRef::Name("x".to_string())).is_err());
    assert!(df.min_val(ColRef::Name("x".to_string())).is_err());
    assert!(df.max_val(ColRef::Name("x".to_string())).is_err());
    assert!(df.median(ColRef::Name("x".to_string())).is_err());
    assert!(df.variance(ColRef::Name("x".to_string())).is_err());
}

#[test]
fn describe_returns_stats_rows() {
    let df = numeric_df();
    let desc = df.describe();
    // Should have "stat" column + one column per numeric column
    assert!(desc.ncols() >= 2);
    assert_eq!(desc.nrows(), 8); // count, mean, std, min, 25%, 50%, 75%, max
}

#[test]
fn describe_empty_no_numeric_returns_empty() {
    let df = DataFrame::from_raw(
        vec!["label".to_string()],
        vec![vec![CellValue::Text("a".to_string())]],
    );
    let desc = df.describe();
    assert_eq!(desc.ncols(), 0);
}

// ============================================================================
// Serialization: CSV
// ============================================================================

#[test]
fn csv_roundtrip() {
    let df = sample_df();
    let csv = df.to_csv();
    let restored = lurek2d::dataframe::serial::from_csv(&csv).unwrap();
    assert_eq!(df.nrows(), restored.nrows());
    assert_eq!(df.ncols(), restored.ncols());
    {
        let cols: Vec<&str> = restored.columns().iter().map(|s| s.as_str()).collect();
        let orig: Vec<&str> = df.columns().iter().map(|s| s.as_str()).collect();
        assert_eq!(cols, orig);
    }
    let val = restored.get_value(0, ColRef::Name("name".to_string())).unwrap();
    assert_eq!(val, CellValue::Text("Alice".to_string()));
}

#[test]
fn csv_numeric_roundtrip() {
    let df = numeric_df();
    let csv = df.to_csv();
    let restored = lurek2d::dataframe::serial::from_csv(&csv).unwrap();
    let v = restored
        .get_value(0, ColRef::Name("val".to_string()))
        .unwrap()
        .as_number()
        .unwrap();
    assert!((v - 10.0).abs() < 1e-5);
}

#[test]
fn csv_empty() {
    let csv = "";
    let df = lurek2d::dataframe::serial::from_csv(csv).unwrap();
    assert_eq!(df.nrows(), 0);
}

// ============================================================================
// Serialization: JSON
// ============================================================================

#[test]
fn json_roundtrip() {
    let df = sample_df();
    let json = df.to_json();
    let restored = lurek2d::dataframe::serial::from_json(&json).unwrap();
    assert_eq!(df.nrows(), restored.nrows());
    assert_eq!(df.ncols(), restored.ncols());
    let val = restored.get_value(1, ColRef::Name("name".to_string())).unwrap();
    assert_eq!(val, CellValue::Text("Bob".to_string()));
}

#[test]
fn json_empty_array() {
    let df = lurek2d::dataframe::serial::from_json("[]").unwrap();
    assert_eq!(df.nrows(), 0);
}

#[test]
fn json_with_null_and_bool() {
    let json = r#"[{"a": 1, "b": null, "c": true}]"#;
    let df = lurek2d::dataframe::serial::from_json(json).unwrap();
    assert_eq!(df.nrows(), 1);
    let b_val = df.get_value(0, ColRef::Name("b".to_string())).unwrap();
    assert!(b_val.is_nil());
    let c_val = df.get_value(0, ColRef::Name("c".to_string())).unwrap();
    assert_eq!(c_val, CellValue::Bool(true));
}

// ============================================================================
// Serialization: Binary (LVDF)
// ============================================================================

#[test]
fn binary_roundtrip() {
    let df = sample_df();
    let bytes = df.to_binary();
    let restored = lurek2d::dataframe::serial::from_binary(&bytes).unwrap();
    assert_eq!(df.nrows(), restored.nrows());
    assert_eq!(df.ncols(), restored.ncols());
    {
        let cols: Vec<&str> = restored.columns().iter().map(|s| s.as_str()).collect();
        let orig: Vec<&str> = df.columns().iter().map(|s| s.as_str()).collect();
        assert_eq!(cols, orig);
    }
    let val = restored.get_value(2, ColRef::Name("name".to_string())).unwrap();
    assert_eq!(val, CellValue::Text("Charlie".to_string()));
}

#[test]
fn binary_roundtrip_all_types() {
    let df = DataFrame::from_raw(
        vec![
            "a".to_string(),
            "b".to_string(),
            "c".to_string(),
            "d".to_string(),
        ],
        vec![
            vec![CellValue::Nil],
            vec![CellValue::Number(3.14)],
            vec![CellValue::Text("hello".to_string())],
            vec![CellValue::Bool(false)],
        ],
    );
    let bytes = df.to_binary();
    let restored = lurek2d::dataframe::serial::from_binary(&bytes).unwrap();
    assert!(restored
        .get_value(0, ColRef::Name("a".to_string()))
        .unwrap()
        .is_nil());
    let n = restored
        .get_value(0, ColRef::Name("b".to_string()))
        .unwrap()
        .as_number()
        .unwrap();
    assert!((n - 3.14).abs() < 1e-5);
    let c_val = restored.get_value(0, ColRef::Name("c".to_string())).unwrap();
    assert_eq!(c_val, CellValue::Text("hello".to_string()));
    let d_val = restored.get_value(0, ColRef::Name("d".to_string())).unwrap();
    assert_eq!(d_val, CellValue::Bool(false));
}

#[test]
fn binary_invalid_magic_errors() {
    let bad = b"BADXsomegarbagedata";
    assert!(lurek2d::dataframe::serial::from_binary(bad).is_err());
}

#[test]
fn binary_too_short_errors() {
    let bad = b"LVDF";
    assert!(lurek2d::dataframe::serial::from_binary(bad).is_err());
}

// ============================================================================
// SQL
// ============================================================================

#[test]
fn sql_select_star() {
    let df = sample_df();
    let result = lurek2d::dataframe::sql::query_sql(&df, "SELECT * FROM data").unwrap();
    assert_eq!(result.nrows(), 3);
    assert_eq!(result.ncols(), 2);
}

#[test]
fn sql_select_specific_column() {
    let df = sample_df();
    let result = lurek2d::dataframe::sql::query_sql(&df, "SELECT name FROM data").unwrap();
    assert_eq!(result.ncols(), 1);
    let cols: Vec<&str> = result.columns().iter().map(|s| s.as_str()).collect();
    assert_eq!(cols, vec!["name"]);
    assert_eq!(result.nrows(), 3);
}

#[test]
fn sql_where_clause() {
    let df = sample_df();
    let result =
        lurek2d::dataframe::sql::query_sql(&df, "SELECT * FROM data WHERE score > 80").unwrap();
    assert_eq!(result.nrows(), 2); // Alice (90) and Charlie (85)
}

#[test]
fn sql_order_by() {
    let df = sample_df();
    let result =
        lurek2d::dataframe::sql::query_sql(&df, "SELECT * FROM data ORDER BY score ASC").unwrap();
    let first = result
        .get_value(0, ColRef::Name("score".to_string()))
        .unwrap()
        .as_number()
        .unwrap();
    assert!((first - 75.0).abs() < 1e-5);
}

#[test]
fn sql_group_by_count() {
    let df = DataFrame::from_raw(
        vec!["dept".to_string(), "salary".to_string()],
        vec![
            vec![
                CellValue::Text("eng".to_string()),
                CellValue::Text("eng".to_string()),
                CellValue::Text("sales".to_string()),
            ],
            vec![
                CellValue::Number(100.0),
                CellValue::Number(120.0),
                CellValue::Number(80.0),
            ],
        ],
    );
    let result = lurek2d::dataframe::sql::query_sql(
        &df,
        "SELECT dept, COUNT(salary) FROM data GROUP BY dept",
    )
    .unwrap();
    assert_eq!(result.nrows(), 2); // eng and sales
}

#[test]
fn sql_group_by_sum() {
    let df = DataFrame::from_raw(
        vec!["dept".to_string(), "salary".to_string()],
        vec![
            vec![
                CellValue::Text("eng".to_string()),
                CellValue::Text("eng".to_string()),
                CellValue::Text("sales".to_string()),
            ],
            vec![
                CellValue::Number(100.0),
                CellValue::Number(120.0),
                CellValue::Number(80.0),
            ],
        ],
    );
    let result =
        lurek2d::dataframe::sql::query_sql(&df, "SELECT dept, SUM(salary) FROM data GROUP BY dept")
            .unwrap();
    assert_eq!(result.nrows(), 2);
}

// ============================================================================
// Database
// ============================================================================

#[test]
fn database_new_empty() {
    let db = Database::new();
    assert_eq!(db.table_count(), 0);
    assert!(db.list_tables().is_empty());
}

#[test]
fn database_default_empty() {
    let db = Database::default();
    assert_eq!(db.table_count(), 0);
}

#[test]
fn database_add_and_get_table() {
    let mut db = Database::new();
    db.add_table("users", sample_df());
    assert!(db.has_table("users"));
    assert!(!db.has_table("missing"));
    let t = db.get_table("users").unwrap();
    assert_eq!(t.nrows(), 3);
}

#[test]
fn database_get_table_mut() {
    let mut db = Database::new();
    db.add_table("users", sample_df());
    let t = db.get_table_mut("users").unwrap();
    t.add_row(&[("name".to_string(), CellValue::Text("Diana".to_string()))]);
    assert_eq!(db.get_table("users").unwrap().nrows(), 4);
}

#[test]
fn database_remove_table() {
    let mut db = Database::new();
    db.add_table("users", sample_df());
    db.remove_table("users").unwrap();
    assert!(!db.has_table("users"));
    assert_eq!(db.table_count(), 0);
}

#[test]
fn database_remove_table_not_found_errors() {
    let mut db = Database::new();
    assert!(db.remove_table("nonexistent").is_err());
}

#[test]
fn database_list_tables_sorted() {
    let mut db = Database::new();
    db.add_table("zebra", DataFrame::new());
    db.add_table("alpha", DataFrame::new());
    db.add_table("middle", DataFrame::new());
    let names = db.list_tables();
    assert_eq!(names, vec!["alpha", "middle", "zebra"]);
}

#[test]
fn database_table_count() {
    let mut db = Database::new();
    db.add_table("a", DataFrame::new());
    db.add_table("b", DataFrame::new());
    assert_eq!(db.table_count(), 2);
}

#[test]
fn database_clear() {
    let mut db = Database::new();
    db.add_table("a", DataFrame::new());
    db.add_table("b", sample_df());
    db.clear();
    assert_eq!(db.table_count(), 0);
    assert!(db.list_tables().is_empty());
}

#[test]
fn database_merge() {
    let mut db1 = Database::new();
    db1.add_table("t1", DataFrame::new());
    let mut db2 = Database::new();
    db2.add_table("t2", sample_df());
    db1.merge(db2);
    assert_eq!(db1.table_count(), 2);
    assert!(db1.has_table("t1"));
    assert!(db1.has_table("t2"));
}

// ============================================================================
// DataFrame: clone_df
// ============================================================================

#[test]
fn clone_df_independent() {
    let df = sample_df();
    let mut clone = df.clone_df();
    clone.remove_row(0).unwrap();
    assert_eq!(clone.nrows(), 2);
    assert_eq!(df.nrows(), 3); // original unchanged
}

// ============================================================================
// DataFrame: fill_nil
// ============================================================================

#[test]
fn fill_nil() {
    let mut df = DataFrame::from_raw(
        vec!["x".to_string()],
        vec![vec![
            CellValue::Number(1.0),
            CellValue::Nil,
            CellValue::Number(3.0),
        ]],
    );
    df.fill_nil(ColRef::Name("x".to_string()), CellValue::Number(0.0))
        .unwrap();
    let val = df.get_value(1, ColRef::Name("x".to_string())).unwrap();
    assert_eq!(val, CellValue::Number(0.0));
}

// ============================================================================
// DataFrame: merge (append rows)
// ============================================================================

#[test]
fn dataframe_merge_appends_rows() {
    let mut df1 = DataFrame::from_raw(vec!["a".to_string()], vec![vec![CellValue::Number(1.0)]]);
    let df2 = DataFrame::from_raw(
        vec!["a".to_string()],
        vec![vec![CellValue::Number(2.0), CellValue::Number(3.0)]],
    );
    df1.merge(&df2);
    assert_eq!(df1.nrows(), 3);
}

// ============================================================================
// DataFrame: random
// ============================================================================

#[test]
fn random_deterministic_with_seed() {
    let defs = vec![
        ("id".to_string(), "id".to_string()),
        ("name".to_string(), "name".to_string()),
    ];
    let df1 = DataFrame::random(&defs, 5, Some(42));
    let df2 = DataFrame::random(&defs, 5, Some(42));
    assert_eq!(df1.nrows(), 5);
    assert_eq!(df2.nrows(), 5);
    // Same seed -> same data
    for row in 0..5 {
        let v1 = df1.get_value(row, ColRef::Name("name".to_string())).unwrap();
        let v2 = df2.get_value(row, ColRef::Name("name".to_string())).unwrap();
        assert_eq!(v1, v2);
    }
}

// ============================================================================
// SQL on Database
// ============================================================================

#[test]
fn sql_database_from_table() {
    let mut db = Database::new();
    db.add_table("users", sample_df());
    let result = lurek2d::dataframe::sql::query_sql_database(&db, "SELECT * FROM users").unwrap();
    assert_eq!(result.nrows(), 3);
}

#[test]
fn sql_database_table_not_found_errors() {
    let db = Database::new();
    let result = lurek2d::dataframe::sql::query_sql_database(&db, "SELECT * FROM missing");
    assert!(result.is_err());
}
