//! - Deferred query step representation for filter, sort, select, head, tail, slice, and limit
//! - Lazy query builder that chains steps without executing until `collect`
//! - Materialization via sequential step application over a cloned source frame

use crate::dataframe::frame::{CellValue, ColRef, DataFrame};
#[derive(Clone)]
/// Store one deferred lazy-query step applied during `collect`.
enum Step {
    /// Keep rows that satisfy a column predicate.
    Filter {
        /// Store column name used by the predicate.
        col: String,
        /// Store comparison operator string.
        op: String,
        /// Store right-hand-side predicate value.
        val: CellValue,
    },
    /// Reorder rows by one column.
    Sort {
        /// Store column name used for ordering.
        col: String,
        /// Store sort direction flag.
        ascending: bool,
    },
    /// Keep only selected columns.
    Select {
        /// Store ordered selected column names.
        cols: Vec<String>,
    },
    /// Keep first N rows.
    Head(usize),
    /// Keep last N rows.
    Tail(usize),
    /// Keep inclusive row range.
    Slice {
        /// Store start row index.
        start: usize,
        /// Store end row index.
        end: usize,
    },
    /// Remove rows where selected column is nil.
    DropNil(String),
    /// Limit output to first N rows.
    Limit(usize),
}
/// Hold deferred query source frame and queued steps.
pub struct LazyQuery {
    /// Store source frame cloned at lazy creation.
    source: DataFrame,
    /// Store deferred query steps.
    steps: Vec<Step>,
}
impl LazyQuery {
    /// Create lazy query from source frame.
    pub fn new(source: DataFrame) -> Self {
        Self {
            source,
            steps: Vec::new(),
        }
    }
    /// Create empty sentinel lazy query.
    pub fn tombstone() -> Self {
        Self::new(DataFrame::new())
    }
    /// Append filter step and return updated query.
    pub fn filter(mut self, col: &str, op: &str, val: CellValue) -> Self {
        self.steps.push(Step::Filter {
            col: col.to_string(),
            op: op.to_string(),
            val,
        });
        self
    }
    /// Append sort step and return updated query.
    pub fn sort(mut self, col: &str, ascending: bool) -> Self {
        self.steps.push(Step::Sort {
            col: col.to_string(),
            ascending,
        });
        self
    }
    /// Append column selection step and return updated query.
    pub fn select(mut self, cols: Vec<String>) -> Self {
        self.steps.push(Step::Select { cols });
        self
    }
    /// Append head step and return updated query.
    pub fn head(mut self, n: usize) -> Self {
        self.steps.push(Step::Head(n));
        self
    }
    /// Append tail step and return updated query.
    pub fn tail(mut self, n: usize) -> Self {
        self.steps.push(Step::Tail(n));
        self
    }
    /// Append slice step and return updated query.
    pub fn slice(mut self, start: usize, end: usize) -> Self {
        self.steps.push(Step::Slice { start, end });
        self
    }
    /// Append drop-nil step and return updated query.
    pub fn drop_nil(mut self, col: &str) -> Self {
        self.steps.push(Step::DropNil(col.to_string()));
        self
    }
    /// Append row limit step and return updated query.
    pub fn limit(mut self, n: usize) -> Self {
        self.steps.push(Step::Limit(n));
        self
    }
    /// Execute deferred steps and return materialized frame.
    pub fn collect(self) -> Result<DataFrame, String> {
        let mut df = self.source;
        for step in self.steps {
            df = match step {
                Step::Filter { col, op, val } => df.filter(ColRef::Name(col), &op, &val)?,
                Step::Sort { col, ascending } => df.sort(ColRef::Name(col), ascending)?,
                Step::Select { cols } => {
                    let refs: Vec<ColRef> = cols.into_iter().map(ColRef::Name).collect();
                    df.select_columns(&refs)?
                }
                Step::Head(n) => df.head(n),
                Step::Tail(n) => df.tail(n),
                Step::Slice { start, end } => df.slice(start, end)?,
                Step::DropNil(col) => df.drop_nil(ColRef::Name(col))?,
                Step::Limit(n) => df.head(n),
            };
        }
        Ok(df)
    }
}
impl DataFrame {
    /// Create lazy query from cloned current frame.
    pub fn lazy(&self) -> LazyQuery {
        LazyQuery::new(self.clone_df())
    }
}
