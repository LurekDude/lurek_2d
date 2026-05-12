//! Lazy query pipeline for [`DataFrame`].
//!
//! [`LazyQuery`] records a sequence of operations (filter, sort, select,
//! head, tail) without materialising intermediate results.  Calling
//! [`LazyQuery::collect`] executes all steps in order and returns a fully
//! evaluated [`DataFrame`].
//!
//! This avoids allocating a full intermediate `DataFrame` for every step
//! in a multi-stage pipeline.
//!
//! # Example (Rust)
//! ```ignore
//! let result = df.lazy()
//!     .filter("age", ">", CellValue::Number(25.0))
//!     .sort("score", false)
//!     .head(10)
//!     .collect()?;
//! ```
//!
//! # Example (Lua)
//! ```lua
//! local result = df:lazy()
//!     :filter("age", ">", 25)
//!     :sort("score", false)
//!     :head(10)
//!     :collect()
//! ```

use crate::dataframe::frame::{CellValue, ColRef, DataFrame};

/// A single deferred operation.
#[derive(Clone)]
enum Step {
    Filter {
        col: String,
        op: String,
        val: CellValue,
    },
    Sort {
        col: String,
        ascending: bool,
    },
    Select {
        cols: Vec<String>,
    },
    Head(usize),
    Tail(usize),
    Slice {
        start: usize,
        end: usize,
    },
    DropNil(String),
    Limit(usize),
}

/// A lazy query pipeline built from a source [`DataFrame`].
///
/// Calling [`collect`](LazyQuery::collect) applies all recorded steps and
/// returns the resulting `DataFrame`.
pub struct LazyQuery {
    source: DataFrame,
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

    /// Create an empty placeholder used when consuming `self` via `std::mem::replace`.
    ///
    /// The tombstone holds an empty DataFrame and no steps; collecting it returns
    /// an empty DataFrame.
    pub fn tombstone() -> Self {
        Self::new(DataFrame::new())
    }

    /// Add a filter step: keep rows where `col op val` is true.
    ///
    /// Supported ops: `==`, `!=`, `<`, `<=`, `>`, `>=`, `contains`.
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

    /// Alias for `head` — limit the result to `n` rows.
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
    /// Begin a lazy evaluation pipeline over this DataFrame.
    ///
    /// The original DataFrame is cloned once; the clone is consumed by the
    /// pipeline.  No allocation occurs for intermediate steps until
    /// [`LazyQuery::collect`] is called.
    ///
    /// # Returns
    /// [`LazyQuery`] — a chainable pipeline builder.
    pub fn lazy(&self) -> LazyQuery {
        LazyQuery::new(self.clone_df())
    }
}
