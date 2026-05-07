//! Rust unit tests for dataframe internals and SQL execution paths.

use lurek2d::dataframe::sql;
use lurek2d::dataframe::{CellValue, ColRef, DataFrame, Database};

#[test]
fn test_empty_frame_has_zero_shape() {
    let df = DataFrame::new();
    assert_eq!(df.nrows(), 0);
    assert_eq!(df.ncols(), 0);
}

#[test]
fn test_from_rows_builds_column_major_data() {
    let df = DataFrame::from_rows(
        vec!["id".to_string(), "name".to_string(), "score".to_string()],
        vec![
            vec![
                CellValue::Number(1.0),
                CellValue::Text("Alice".to_string()),
                CellValue::Number(10.0),
            ],
            vec![
                CellValue::Number(2.0),
                CellValue::Text("Bob".to_string()),
                CellValue::Number(20.0),
            ],
        ],
    )
    .expect("from_rows should succeed");

    assert_eq!(df.ncols(), 3);
    assert_eq!(df.nrows(), 2);
    assert_eq!(df.get_value(1, ColRef::Name("name".to_string())).unwrap(), CellValue::Text("Bob".to_string()));
}

#[test]
fn test_from_rows_rejects_mismatched_row_width() {
    let result = DataFrame::from_rows(
        vec!["a".to_string(), "b".to_string()],
        vec![vec![CellValue::Number(1.0)]],
    );

    let err = result.err().expect("row width mismatch should fail");

    assert!(err.contains("from_rows: row 0 has 1 values but expected 2"));
}

#[test]
fn test_random_zero_seed_matches_none_seed() {
    let defs = vec![("x".to_string(), "float".to_string())];
    let a = DataFrame::random(&defs, 8, Some(0));
    let b = DataFrame::random(&defs, 8, None);
    assert_eq!(a.raw_data(), b.raw_data());
}

#[test]
fn test_with_eval_pivot_rolling_and_rank_paths() {
    let base = DataFrame::from_rows(
        vec!["team".to_string(), "kind".to_string(), "score".to_string()],
        vec![
            vec![CellValue::Text("red".to_string()), CellValue::Text("a".to_string()), CellValue::Number(2.0)],
            vec![CellValue::Text("red".to_string()), CellValue::Text("b".to_string()), CellValue::Number(4.0)],
            vec![CellValue::Text("blue".to_string()), CellValue::Text("a".to_string()), CellValue::Number(6.0)],
        ],
    )
    .unwrap();

    let eval = base.with_eval("double", "score * 2").unwrap();
    assert_eq!(eval.ncols(), 4);
    assert_eq!(eval.get_value(2, ColRef::Name("double".to_string())).unwrap(), CellValue::Number(12.0));

    let pivot = base
        .pivot_table(
            ColRef::Name("team".to_string()),
            ColRef::Name("kind".to_string()),
            ColRef::Name("score".to_string()),
            "sum",
        )
        .unwrap();
    assert_eq!(pivot.nrows(), 2);
    assert!(pivot.columns().contains(&"a".to_string()));

    let roll = base
        .rolling_mean(ColRef::Name("score".to_string()), 2, "score_ma2")
        .unwrap();
    assert_eq!(roll.get_value(2, ColRef::Name("score_ma2".to_string())).unwrap(), CellValue::Number(5.0));

    let ranked = base
        .rank_column(ColRef::Name("score".to_string()), "desc", "rank")
        .unwrap();
    assert_eq!(ranked.get_value(0, ColRef::Name("rank".to_string())).unwrap(), CellValue::Number(3.0));
    assert_eq!(ranked.get_value(2, ColRef::Name("rank".to_string())).unwrap(), CellValue::Number(1.0));
}

#[test]
fn test_query_sql_database_multi_table_join() {
    let players = DataFrame::from_rows(
        vec!["id".to_string(), "name".to_string()],
        vec![
            vec![CellValue::Number(1.0), CellValue::Text("Alice".to_string())],
            vec![CellValue::Number(2.0), CellValue::Text("Bob".to_string())],
        ],
    )
    .unwrap();

    let scores = DataFrame::from_rows(
        vec!["player_id".to_string(), "score".to_string()],
        vec![
            vec![CellValue::Number(1.0), CellValue::Number(100.0)],
            vec![CellValue::Number(2.0), CellValue::Number(200.0)],
        ],
    )
    .unwrap();

    let mut db = Database::new();
    db.add_table("players", players);
    db.add_table("scores", scores);

    let out = sql::query_sql_database(
        &db,
        "SELECT name, score FROM players JOIN scores ON players.id = scores.player_id ORDER BY score DESC",
    )
    .unwrap();

    assert_eq!(out.nrows(), 2);
    assert_eq!(out.get_value(0, ColRef::Name("name".to_string())).unwrap(), CellValue::Text("Bob".to_string()));
    assert_eq!(out.get_value(0, ColRef::Name("score".to_string())).unwrap(), CellValue::Number(200.0));
}
