//! INTERNAL ONLY: Rust-only tests for dataframe internals not exposed as `lurek.dataframe.*`.

mod frame_tests {
    use lurek2d::dataframe::DataFrame;

    #[test]
    fn empty_frame_has_zero_rows() {
        let df = DataFrame::new();
        assert_eq!(df.count(), 0);
    }

    #[test]
    fn empty_frame_has_zero_columns() {
        let df = DataFrame::new();
        assert_eq!(df.columns().len(), 0);
    }
}
