//! INTERNAL ONLY: public `lurek.dataframe.*` constructors, transforms, and SQL
//! query behavior is covered by the Lua-first suite in
//! `tests/lua/unit/test_dataframe_core_unit.lua`.
//!
//! The remaining Rust coverage keeps the row iterator contract, which is not
//! exposed as a direct Lua API surface.

use lurek2d::dataframe::{CellValue, DataFrame};

#[test]
fn test_iter_rows_streams_rows_in_order() {
    let df = DataFrame::from_rows(
        vec!["id".to_string(), "name".to_string()],
        vec![
            vec![CellValue::Number(1.0), CellValue::Text("Alice".to_string())],
            vec![CellValue::Number(2.0), CellValue::Text("Bob".to_string())],
        ],
    )
    .unwrap();

    let mut rows = df.iter_rows();

    let first = rows.next().expect("first row should exist");
    assert_eq!(first.len(), 2);
    assert_eq!(first[0].0, "id");
    assert_eq!(first[0].1, &CellValue::Number(1.0));
    assert_eq!(first[1].0, "name");
    assert_eq!(first[1].1, &CellValue::Text("Alice".to_string()));

    let second = rows.next().expect("second row should exist");
    assert_eq!(second[0].1, &CellValue::Number(2.0));
    assert_eq!(second[1].1, &CellValue::Text("Bob".to_string()));

    assert!(rows.next().is_none());
}
