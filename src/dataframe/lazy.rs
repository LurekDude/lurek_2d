//! Deferred query composition.

use crate::dataframe::frame::{CellValue, ColRef, DataFrame};

/// A single deferred operation.
#[derive(Clone)]
enum Step {
    /// Filter rows by `col op val`.
    Filter {
        /// Target column name.
        col: String,
        /// Comparison operator string.
        op: String,
        /// Comparison value.
        val: CellValue,
    },
    /// Sort rows by one column.
    Sort {
        /// Target column name.
        col: String,
        /// Sort order flag.
        ascending: bool,
    },
    /// Keep only selected columns.
    Select {
        /// Ordered selected column names.
        cols: Vec<String>,
    },
    /// Keep first `n` rows.
    Head(usize),
    /// Keep last `n` rows.
    Tail(usize),
    /// Keep inclusive row slice `[start, end]`.
    Slice {
        /// Inclusive slice start.
        start: usize,
        /// Inclusive slice end.
        end: usize,
    },
    /// Drop rows where one column is `Nil`.
    DropNil(String),
    /// Limit output row count.
    Limit(usize),
}

/// Lazy query pipeline built from a source [`DataFrame`].
/// Call [`collect`](LazyQuery::collect) to apply recorded steps and return the resulting `DataFrame`.
pub struct LazyQuery {
    /// Source DataFrame consumed by collection.
    source: DataFrame,
    /// Recorded deferred steps in insertion order.
    steps: Vec<Step>,
}

impl LazyQuery {
    /// Create a new pipeline with the given source.
    pub fn new(source: DataFrame) -> Self {
        Self {
            source,
            steps: Vec::new(),
        }
    }

    /// Create an empty pipeline used as a replacement value.
    pub fn tombstone() -> Self {
        Self::new(DataFrame::new())
    }

    /// Add a filter step: keep rows where `col op val` is true.
    pub fn filter(mut self, col: &str, op: &str, val: CellValue) -> Self {
        self.steps.push(Step::Filter {
            col: col.to_string(),
            op: op.to_string(),
            val,
        });
        self
    }

    /// Add a sort step.
    pub fn sort(mut self, col: &str, ascending: bool) -> Self {
        self.steps.push(Step::Sort {
            col: col.to_string(),
            ascending,
        });
        self
    }

    /// Add a column selection step — retains only the named columns.
    pub fn select(mut self, cols: Vec<String>) -> Self {
        self.steps.push(Step::Select { cols });
        self
    }

    /// Retain only the first `n` rows.
    pub fn head(mut self, n: usize) -> Self {
        self.steps.push(Step::Head(n));
        self
    }

    /// Retain only the last `n` rows.
    pub fn tail(mut self, n: usize) -> Self {
        self.steps.push(Step::Tail(n));
        self
    }

    /// Retain a 1-based inclusive slice `[start, end]`.
    pub fn slice(mut self, start: usize, end: usize) -> Self {
        self.steps.push(Step::Slice { start, end });
        self
    }

    /// Remove rows where the given column is `Nil`.
    pub fn drop_nil(mut self, col: &str) -> Self {
        self.steps.push(Step::DropNil(col.to_string()));
        self
    }

    /// Limit the result to `n` rows.
    pub fn limit(mut self, n: usize) -> Self {
        self.steps.push(Step::Limit(n));
        self
    }

    /// Execute the pipeline and return the resulting `DataFrame`.
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
    /// Begin a lazy pipeline by cloning this DataFrame and return a chainable [`LazyQuery`].
    pub fn lazy(&self) -> LazyQuery {
        LazyQuery::new(self.clone_df())
    }
}
