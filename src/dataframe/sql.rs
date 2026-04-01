//! SQL-like query parser and executor for DataFrame.
//!
//! Supports a subset of SQL: SELECT, WHERE, GROUP BY, HAVING, ORDER BY,
//! LIMIT/OFFSET, aggregate functions, and JOIN (for Database queries).

use crate::dataframe::frame::{CellValue, ColRef, DataFrame, Database};

// ---------------------------------------------------------------------------
// Token types
// ---------------------------------------------------------------------------

/// SQL token.
#[derive(Debug, Clone, PartialEq)]
enum Token {
    /// Keyword or identifier.
    Ident(String),
    /// String literal (single-quoted).
    StringLit(String),
    /// Numeric literal.
    NumberLit(f64),
    /// Star / asterisk.
    Star,
    /// Comma.
    Comma,
    /// Dot.
    Dot,
    /// Opening parenthesis.
    LParen,
    /// Closing parenthesis.
    RParen,
    /// Operator: =, !=, <, <=, >, >=.
    Op(String),
    /// End of input.
    Eof,
}

// ---------------------------------------------------------------------------
// Tokenizer
// ---------------------------------------------------------------------------

/// Tokenize a SQL string.
fn tokenize(sql: &str) -> Result<Vec<Token>, String> {
    let chars: Vec<char> = sql.chars().collect();
    let len = chars.len();
    let mut tokens = Vec::new();
    let mut i = 0;

    while i < len {
        let c = chars[i];

        // Skip whitespace
        if c.is_ascii_whitespace() {
            i += 1;
            continue;
        }

        match c {
            '*' => {
                tokens.push(Token::Star);
                i += 1;
            }
            ',' => {
                tokens.push(Token::Comma);
                i += 1;
            }
            '.' => {
                tokens.push(Token::Dot);
                i += 1;
            }
            '(' => {
                tokens.push(Token::LParen);
                i += 1;
            }
            ')' => {
                tokens.push(Token::RParen);
                i += 1;
            }
            '=' => {
                tokens.push(Token::Op("=".to_string()));
                i += 1;
            }
            '!' => {
                if i + 1 < len && chars[i + 1] == '=' {
                    tokens.push(Token::Op("!=".to_string()));
                    i += 2;
                } else {
                    return Err(format!("unexpected '!' at position {i}"));
                }
            }
            '<' => {
                if i + 1 < len && chars[i + 1] == '=' {
                    tokens.push(Token::Op("<=".to_string()));
                    i += 2;
                } else if i + 1 < len && chars[i + 1] == '>' {
                    tokens.push(Token::Op("!=".to_string()));
                    i += 2;
                } else {
                    tokens.push(Token::Op("<".to_string()));
                    i += 1;
                }
            }
            '>' => {
                if i + 1 < len && chars[i + 1] == '=' {
                    tokens.push(Token::Op(">=".to_string()));
                    i += 2;
                } else {
                    tokens.push(Token::Op(">".to_string()));
                    i += 1;
                }
            }
            '\'' => {
                // String literal
                i += 1;
                let mut s = String::new();
                while i < len {
                    if chars[i] == '\'' {
                        if i + 1 < len && chars[i + 1] == '\'' {
                            s.push('\'');
                            i += 2;
                        } else {
                            break;
                        }
                    } else {
                        s.push(chars[i]);
                        i += 1;
                    }
                }
                if i >= len {
                    return Err("unterminated string literal".to_string());
                }
                i += 1; // skip closing quote
                tokens.push(Token::StringLit(s));
            }
            '"' => {
                // Double-quoted identifier
                i += 1;
                let mut s = String::new();
                while i < len && chars[i] != '"' {
                    s.push(chars[i]);
                    i += 1;
                }
                if i >= len {
                    return Err("unterminated double-quoted identifier".to_string());
                }
                i += 1;
                tokens.push(Token::Ident(s));
            }
            _ if c.is_ascii_digit()
                || (c == '-' && i + 1 < len && chars[i + 1].is_ascii_digit()) =>
            {
                let start = i;
                if c == '-' {
                    i += 1;
                }
                while i < len && (chars[i].is_ascii_digit() || chars[i] == '.') {
                    i += 1;
                }
                // Handle scientific notation
                if i < len && (chars[i] == 'e' || chars[i] == 'E') {
                    i += 1;
                    if i < len && (chars[i] == '+' || chars[i] == '-') {
                        i += 1;
                    }
                    while i < len && chars[i].is_ascii_digit() {
                        i += 1;
                    }
                }
                let num_str: String = chars[start..i].iter().collect();
                let n: f64 = num_str
                    .parse()
                    .map_err(|_| format!("invalid number: {num_str}"))?;
                tokens.push(Token::NumberLit(n));
            }
            _ if c.is_ascii_alphabetic() || c == '_' => {
                let start = i;
                while i < len && (chars[i].is_ascii_alphanumeric() || chars[i] == '_') {
                    i += 1;
                }
                let word: String = chars[start..i].iter().collect();
                tokens.push(Token::Ident(word));
            }
            _ => {
                return Err(format!("unexpected character '{c}' in SQL at position {i}"));
            }
        }
    }

    tokens.push(Token::Eof);
    Ok(tokens)
}

// ---------------------------------------------------------------------------
// Parser state
// ---------------------------------------------------------------------------

/// Parsed SQL statement.
#[derive(Debug)]
struct SqlSelect {
    columns: Vec<SelectExpr>,
    from: Option<String>,
    joins: Vec<JoinClause>,
    where_clause: Option<Expr>,
    group_by: Option<String>,
    having: Option<Expr>,
    order_by: Option<(String, bool)>, // (col, ascending)
    limit: Option<usize>,
    offset: Option<usize>,
}

/// A column expression in SELECT.
#[derive(Debug)]
enum SelectExpr {
    /// All columns.
    Star,
    /// A single column reference.
    Column(String),
    /// Aggregate function: COUNT, SUM, AVG, MIN, MAX.
    Aggregate(AggFunc, AggArg),
}

/// Aggregate function type.
#[derive(Debug, Clone)]
enum AggFunc {
    Count,
    Sum,
    Avg,
    Min,
    Max,
}

/// Aggregate argument.
#[derive(Debug, Clone)]
enum AggArg {
    /// COUNT(*)
    Star,
    /// SUM(col), etc.
    Column(String),
}

/// JOIN clause.
#[derive(Debug)]
struct JoinClause {
    table: String,
    left_col: String,
    right_col: String,
}

/// WHERE / HAVING expression tree.
#[derive(Debug)]
enum Expr {
    /// Comparison: col op value.
    Compare(String, String, CellValue),
    /// LIKE: col LIKE pattern.
    Like(String, String),
    /// IN: col IN (val1, val2, ...).
    In(String, Vec<CellValue>),
    /// NOT expr.
    Not(Box<Expr>),
    /// AND.
    And(Box<Expr>, Box<Expr>),
    /// OR.
    Or(Box<Expr>, Box<Expr>),
}

// ---------------------------------------------------------------------------
// Parser
// ---------------------------------------------------------------------------

/// Recursive-descent SQL parser.
struct Parser {
    tokens: Vec<Token>,
    pos: usize,
}

impl Parser {
    fn new(tokens: Vec<Token>) -> Self {
        Self { tokens, pos: 0 }
    }

    fn peek(&self) -> &Token {
        &self.tokens[self.pos]
    }

    fn advance(&mut self) -> Token {
        let t = self.tokens[self.pos].clone();
        if self.pos < self.tokens.len() - 1 {
            self.pos += 1;
        }
        t
    }

    fn expect_ident(&mut self) -> Result<String, String> {
        match self.advance() {
            Token::Ident(s) => Ok(s),
            other => Err(format!("expected identifier, got {other:?}")),
        }
    }

    fn is_keyword(&self, kw: &str) -> bool {
        matches!(self.peek(), Token::Ident(s) if s.eq_ignore_ascii_case(kw))
    }

    fn consume_keyword(&mut self, kw: &str) -> bool {
        if self.is_keyword(kw) {
            self.advance();
            true
        } else {
            false
        }
    }

    fn expect_keyword(&mut self, kw: &str) -> Result<(), String> {
        if self.consume_keyword(kw) {
            Ok(())
        } else {
            Err(format!("expected keyword '{kw}', got {:?}", self.peek()))
        }
    }

    /// Parse a full SELECT statement.
    fn parse_select(&mut self) -> Result<SqlSelect, String> {
        self.expect_keyword("SELECT")?;

        // Parse select list
        let columns = self.parse_select_list()?;

        // Optional FROM
        let from = if self.consume_keyword("FROM") {
            Some(self.expect_ident()?)
        } else {
            None
        };

        // Optional JOINs
        let mut joins = Vec::new();
        while self.consume_keyword("JOIN") {
            let table = self.expect_ident()?;
            self.expect_keyword("ON")?;
            // Expect: t1.col = t2.col
            let left_table_or_col = self.expect_ident()?;
            let left_col = if matches!(self.peek(), Token::Dot) {
                self.advance(); // .
                self.expect_ident()?
            } else {
                left_table_or_col
            };
            match self.advance() {
                Token::Op(ref s) if s == "=" => {}
                other => return Err(format!("expected '=' in JOIN ON, got {other:?}")),
            }
            let right_table_or_col = self.expect_ident()?;
            let right_col = if matches!(self.peek(), Token::Dot) {
                self.advance(); // .
                self.expect_ident()?
            } else {
                right_table_or_col
            };
            joins.push(JoinClause {
                table,
                left_col,
                right_col,
            });
        }

        // Optional WHERE
        let where_clause = if self.consume_keyword("WHERE") {
            Some(self.parse_expr()?)
        } else {
            None
        };

        // Optional GROUP BY
        let group_by = if self.consume_keyword("GROUP") {
            self.expect_keyword("BY")?;
            Some(self.expect_ident()?)
        } else {
            None
        };

        // Optional HAVING
        let having = if self.consume_keyword("HAVING") {
            Some(self.parse_expr()?)
        } else {
            None
        };

        // Optional ORDER BY
        let order_by = if self.consume_keyword("ORDER") {
            self.expect_keyword("BY")?;
            let col = self.expect_ident()?;
            let ascending = if self.consume_keyword("DESC") {
                false
            } else {
                self.consume_keyword("ASC");
                true
            };
            Some((col, ascending))
        } else {
            None
        };

        // Optional LIMIT
        let limit = if self.consume_keyword("LIMIT") {
            match self.advance() {
                Token::NumberLit(n) => Some(n as usize),
                other => return Err(format!("expected number after LIMIT, got {other:?}")),
            }
        } else {
            None
        };

        // Optional OFFSET
        let offset = if self.consume_keyword("OFFSET") {
            match self.advance() {
                Token::NumberLit(n) => Some(n as usize),
                other => return Err(format!("expected number after OFFSET, got {other:?}")),
            }
        } else {
            None
        };

        Ok(SqlSelect {
            columns,
            from,
            joins,
            where_clause,
            group_by,
            having,
            order_by,
            limit,
            offset,
        })
    }

    /// Parse the SELECT column list.
    fn parse_select_list(&mut self) -> Result<Vec<SelectExpr>, String> {
        let mut list = Vec::new();

        loop {
            if matches!(self.peek(), Token::Star) {
                self.advance();
                list.push(SelectExpr::Star);
            } else if self.is_agg_func() {
                list.push(self.parse_agg_expr()?);
            } else {
                let name = self.expect_ident()?;
                list.push(SelectExpr::Column(name));
            }

            if matches!(self.peek(), Token::Comma) {
                self.advance();
            } else {
                break;
            }
        }

        Ok(list)
    }

    /// Check if current token is an aggregate function name.
    fn is_agg_func(&self) -> bool {
        matches!(self.peek(), Token::Ident(s) if {
            let u = s.to_uppercase();
            u == "COUNT" || u == "SUM" || u == "AVG" || u == "MIN" || u == "MAX"
        })
    }

    /// Parse an aggregate expression like COUNT(*) or SUM(col).
    fn parse_agg_expr(&mut self) -> Result<SelectExpr, String> {
        let func_name = self.expect_ident()?;
        let func = match func_name.to_uppercase().as_str() {
            "COUNT" => AggFunc::Count,
            "SUM" => AggFunc::Sum,
            "AVG" => AggFunc::Avg,
            "MIN" => AggFunc::Min,
            "MAX" => AggFunc::Max,
            _ => return Err(format!("unknown aggregate function: {func_name}")),
        };

        match self.advance() {
            Token::LParen => {}
            other => return Err(format!("expected '(' after {func_name}, got {other:?}")),
        }

        let arg = if matches!(self.peek(), Token::Star) {
            self.advance();
            AggArg::Star
        } else {
            let col = self.expect_ident()?;
            AggArg::Column(col)
        };

        match self.advance() {
            Token::RParen => {}
            other => return Err(format!("expected ')' after aggregate, got {other:?}")),
        }

        Ok(SelectExpr::Aggregate(func, arg))
    }

    /// Parse an expression (OR level).
    fn parse_expr(&mut self) -> Result<Expr, String> {
        let mut left = self.parse_and_expr()?;
        while self.consume_keyword("OR") {
            let right = self.parse_and_expr()?;
            left = Expr::Or(Box::new(left), Box::new(right));
        }
        Ok(left)
    }

    /// Parse AND expression.
    fn parse_and_expr(&mut self) -> Result<Expr, String> {
        let mut left = self.parse_not_expr()?;
        while self.consume_keyword("AND") {
            let right = self.parse_not_expr()?;
            left = Expr::And(Box::new(left), Box::new(right));
        }
        Ok(left)
    }

    /// Parse NOT expression.
    fn parse_not_expr(&mut self) -> Result<Expr, String> {
        if self.consume_keyword("NOT") {
            let inner = self.parse_primary_expr()?;
            Ok(Expr::Not(Box::new(inner)))
        } else {
            self.parse_primary_expr()
        }
    }

    /// Parse primary expression (comparison, LIKE, IN, parenthesized).
    fn parse_primary_expr(&mut self) -> Result<Expr, String> {
        // Parenthesized expression
        if matches!(self.peek(), Token::LParen) {
            self.advance();
            let expr = self.parse_expr()?;
            match self.advance() {
                Token::RParen => {}
                other => return Err(format!("expected ')', got {other:?}")),
            }
            return Ok(expr);
        }

        // Column name
        let col = self.expect_ident()?;

        // Handle table.column notation — just take the column part
        let col = if matches!(self.peek(), Token::Dot) {
            self.advance();
            self.expect_ident()?
        } else {
            col
        };

        // NOT LIKE / NOT IN / LIKE / IN / comparison
        if self.consume_keyword("NOT") {
            if self.consume_keyword("LIKE") {
                let pattern = self.parse_string_value()?;
                Ok(Expr::Not(Box::new(Expr::Like(col, pattern))))
            } else if self.consume_keyword("IN") {
                let vals = self.parse_in_list()?;
                Ok(Expr::Not(Box::new(Expr::In(col, vals))))
            } else {
                Err("expected LIKE or IN after NOT".to_string())
            }
        } else if self.consume_keyword("LIKE") {
            let pattern = self.parse_string_value()?;
            Ok(Expr::Like(col, pattern))
        } else if self.consume_keyword("IN") {
            let vals = self.parse_in_list()?;
            Ok(Expr::In(col, vals))
        } else {
            // Comparison operator
            let op = match self.advance() {
                Token::Op(s) => s,
                other => {
                    return Err(format!(
                        "expected operator after column '{col}', got {other:?}"
                    ))
                }
            };
            let val = self.parse_cell_value()?;
            // Map = to ==
            let op = if op == "=" { "==".to_string() } else { op };
            Ok(Expr::Compare(col, op, val))
        }
    }

    /// Parse a string value (single-quoted).
    fn parse_string_value(&mut self) -> Result<String, String> {
        match self.advance() {
            Token::StringLit(s) => Ok(s),
            other => Err(format!("expected string literal, got {other:?}")),
        }
    }

    /// Parse an IN (...) value list.
    fn parse_in_list(&mut self) -> Result<Vec<CellValue>, String> {
        match self.advance() {
            Token::LParen => {}
            other => return Err(format!("expected '(' after IN, got {other:?}")),
        }
        let mut vals = Vec::new();
        loop {
            if matches!(self.peek(), Token::RParen) {
                self.advance();
                break;
            }
            if !vals.is_empty() {
                match self.advance() {
                    Token::Comma => {}
                    other => return Err(format!("expected ',' in IN list, got {other:?}")),
                }
            }
            vals.push(self.parse_cell_value()?);
        }
        Ok(vals)
    }

    /// Parse a literal value (number, string, NULL, TRUE, FALSE).
    fn parse_cell_value(&mut self) -> Result<CellValue, String> {
        match self.peek().clone() {
            Token::NumberLit(n) => {
                self.advance();
                Ok(CellValue::Number(n))
            }
            Token::StringLit(s) => {
                self.advance();
                Ok(CellValue::Text(s))
            }
            Token::Ident(ref s) if s.eq_ignore_ascii_case("NULL") => {
                self.advance();
                Ok(CellValue::Nil)
            }
            Token::Ident(ref s) if s.eq_ignore_ascii_case("TRUE") => {
                self.advance();
                Ok(CellValue::Bool(true))
            }
            Token::Ident(ref s) if s.eq_ignore_ascii_case("FALSE") => {
                self.advance();
                Ok(CellValue::Bool(false))
            }
            other => Err(format!("expected value, got {other:?}")),
        }
    }
}

// ---------------------------------------------------------------------------
// SQL execution
// ---------------------------------------------------------------------------

/// Execute a SQL query on a single DataFrame.
///
/// # Parameters
/// - `df` — `&DataFrame`.
/// - `sql` — `&str`.
///
/// # Returns
/// `Result<DataFrame, String>`.
///
/// Supports: SELECT, WHERE, GROUP BY, HAVING, ORDER BY, LIMIT/OFFSET,
/// and aggregate functions (COUNT, SUM, AVG, MIN, MAX).
pub fn query_sql(df: &DataFrame, sql: &str) -> Result<DataFrame, String> {
    let tokens = tokenize(sql)?;
    let mut parser = Parser::new(tokens);
    let stmt = parser.parse_select()?;
    execute_select(df, &stmt)
}

/// Execute a SQL query on a Database (supports FROM and JOIN).
///
/// # Parameters
/// - `db` — `&Database`.
/// - `sql` — `&str`.
///
/// # Returns
/// `Result<DataFrame, String>`.
pub fn query_sql_database(db: &Database, sql: &str) -> Result<DataFrame, String> {
    let tokens = tokenize(sql)?;
    let mut parser = Parser::new(tokens);
    let stmt = parser.parse_select()?;

    // Resolve the FROM table
    let base_table_name = stmt
        .from
        .as_ref()
        .ok_or("SQL query on Database requires FROM clause")?;
    let base = db
        .get_table(base_table_name)
        .ok_or_else(|| format!("table not found: {base_table_name}"))?;

    // Apply JOINs
    let mut working = base.clone_df();
    for join in &stmt.joins {
        let right = db
            .get_table(&join.table)
            .ok_or_else(|| format!("table not found: {}", join.table))?;
        working = working.join(
            right,
            ColRef::Name(join.left_col.clone()),
            ColRef::Name(join.right_col.clone()),
            "inner",
        )?;
    }

    execute_select(&working, &stmt)
}

/// Execute a parsed SELECT statement against a DataFrame.
fn execute_select(df: &DataFrame, stmt: &SqlSelect) -> Result<DataFrame, String> {
    // 1. Apply WHERE filter
    let filtered = if let Some(ref where_expr) = stmt.where_clause {
        apply_filter(df, where_expr)?
    } else {
        df.clone_df()
    };

    // 2. GROUP BY + aggregates
    let result = if let Some(ref group_col) = stmt.group_by {
        execute_group_by(&filtered, group_col, &stmt.columns, stmt.having.as_ref())?
    } else if has_aggregates(&stmt.columns) {
        // Aggregate without GROUP BY — whole table is one group
        execute_aggregate_no_group(&filtered, &stmt.columns)?
    } else {
        // Plain SELECT (column projection)
        execute_column_select(&filtered, &stmt.columns)?
    };

    // 3. ORDER BY
    let result = if let Some((ref col, ascending)) = stmt.order_by {
        result.sort(ColRef::Name(col.clone()), ascending)?
    } else {
        result
    };

    // 4. OFFSET
    let result = if let Some(offset) = stmt.offset {
        if offset >= result.nrows() {
            DataFrame::from_raw(result.columns().to_vec(), vec![Vec::new(); result.ncols()])
        } else {
            result.slice(offset, result.nrows().saturating_sub(1))?
        }
    } else {
        result
    };

    // 5. LIMIT
    let result = if let Some(limit) = stmt.limit {
        result.head(limit)
    } else {
        result
    };

    Ok(result)
}

/// Check whether any SelectExpr is an aggregate.
fn has_aggregates(columns: &[SelectExpr]) -> bool {
    columns
        .iter()
        .any(|c| matches!(c, SelectExpr::Aggregate(_, _)))
}

/// Apply a WHERE filter expression, returning matching rows.
fn apply_filter(df: &DataFrame, expr: &Expr) -> Result<DataFrame, String> {
    let nrows = df.nrows();
    let data = df.raw_data();
    let cols = df.columns();

    let mut keep = Vec::new();
    for row in 0..nrows {
        if eval_expr(expr, cols, data, row)? {
            keep.push(row);
        }
    }

    let new_data: Vec<Vec<CellValue>> = (0..df.ncols())
        .map(|ci| keep.iter().map(|&row| data[ci][row].clone()).collect())
        .collect();
    Ok(DataFrame::from_raw(cols.to_vec(), new_data))
}

/// Evaluate an expression for a given row.
fn eval_expr(
    expr: &Expr,
    cols: &[String],
    data: &[Vec<CellValue>],
    row: usize,
) -> Result<bool, String> {
    match expr {
        Expr::Compare(col, op, val) => {
            let ci = find_col(cols, col)?;
            let cell = &data[ci][row];
            let result = match op.as_str() {
                "==" => cell == val,
                "!=" => cell != val,
                "<" => cell.cmp_for_sort(val) == std::cmp::Ordering::Less,
                "<=" => {
                    let ord = cell.cmp_for_sort(val);
                    ord == std::cmp::Ordering::Less || ord == std::cmp::Ordering::Equal
                }
                ">" => cell.cmp_for_sort(val) == std::cmp::Ordering::Greater,
                ">=" => {
                    let ord = cell.cmp_for_sort(val);
                    ord == std::cmp::Ordering::Greater || ord == std::cmp::Ordering::Equal
                }
                _ => return Err(format!("unsupported SQL operator: {op}")),
            };
            Ok(result)
        }
        Expr::Like(col, pattern) => {
            let ci = find_col(cols, col)?;
            let cell = &data[ci][row];
            if let CellValue::Text(s) = cell {
                Ok(sql_like_match(s, pattern))
            } else {
                Ok(false)
            }
        }
        Expr::In(col, vals) => {
            let ci = find_col(cols, col)?;
            let cell = &data[ci][row];
            Ok(vals.contains(cell))
        }
        Expr::Not(inner) => Ok(!eval_expr(inner, cols, data, row)?),
        Expr::And(a, b) => Ok(eval_expr(a, cols, data, row)? && eval_expr(b, cols, data, row)?),
        Expr::Or(a, b) => Ok(eval_expr(a, cols, data, row)? || eval_expr(b, cols, data, row)?),
    }
}

/// Find column index by name.
fn find_col(cols: &[String], name: &str) -> Result<usize, String> {
    cols.iter()
        .position(|n| n == name)
        .ok_or_else(|| format!("column not found: {name}"))
}

/// SQL LIKE pattern matching. `%` = any sequence, `_` = any single char.
fn sql_like_match(s: &str, pattern: &str) -> bool {
    let s_chars: Vec<char> = s.chars().collect();
    let p_chars: Vec<char> = pattern.chars().collect();
    like_match_dp(&s_chars, &p_chars)
}

/// Dynamic programming LIKE match.
fn like_match_dp(s: &[char], p: &[char]) -> bool {
    let sn = s.len();
    let pn = p.len();
    // dp[i][j] = true if s[0..i] matches p[0..j]
    let mut dp = vec![vec![false; pn + 1]; sn + 1];
    dp[0][0] = true;

    // Handle leading % in pattern
    for j in 1..=pn {
        if p[j - 1] == '%' {
            dp[0][j] = dp[0][j - 1];
        } else {
            break;
        }
    }

    for i in 1..=sn {
        for j in 1..=pn {
            let pc = p[j - 1];
            if pc == '%' {
                dp[i][j] = dp[i][j - 1] || dp[i - 1][j];
            } else if pc == '_' || pc.to_lowercase().eq(s[i - 1].to_lowercase()) {
                dp[i][j] = dp[i - 1][j - 1];
            }
        }
    }

    dp[sn][pn]
}

/// Execute column projection (no aggregates).
fn execute_column_select(df: &DataFrame, columns: &[SelectExpr]) -> Result<DataFrame, String> {
    let mut col_refs: Vec<ColRef> = Vec::new();
    for expr in columns {
        match expr {
            SelectExpr::Star => {
                for name in df.columns() {
                    col_refs.push(ColRef::Name(name.clone()));
                }
            }
            SelectExpr::Column(name) => {
                col_refs.push(ColRef::Name(name.clone()));
            }
            SelectExpr::Aggregate(_, _) => {
                return Err("unexpected aggregate in non-grouped SELECT".to_string());
            }
        }
    }
    df.select_columns(&col_refs)
}

/// Execute GROUP BY with optional HAVING and aggregates.
fn execute_group_by(
    df: &DataFrame,
    group_col: &str,
    select_exprs: &[SelectExpr],
    having: Option<&Expr>,
) -> Result<DataFrame, String> {
    let groups = df.group_by(ColRef::Name(group_col.to_string()))?;

    // Build result columns
    let mut result_col_names: Vec<String> = Vec::new();
    for expr in select_exprs {
        match expr {
            SelectExpr::Column(name) => result_col_names.push(name.clone()),
            SelectExpr::Aggregate(func, arg) => {
                let name = agg_col_name(func, arg);
                result_col_names.push(name);
            }
            SelectExpr::Star => {
                result_col_names.push(group_col.to_string());
            }
        }
    }

    let ncols = result_col_names.len();
    let mut result_data: Vec<Vec<CellValue>> = vec![Vec::new(); ncols];

    for (key, sub_df) in &groups {
        // Compute values for this group
        let mut row_vals: Vec<CellValue> = Vec::with_capacity(ncols);
        for expr in select_exprs {
            match expr {
                SelectExpr::Column(name) => {
                    if name == group_col {
                        row_vals.push(key.clone());
                    } else {
                        // Take first value from the group
                        let val = sub_df
                            .get_value(0, ColRef::Name(name.clone()))
                            .unwrap_or(CellValue::Nil);
                        row_vals.push(val);
                    }
                }
                SelectExpr::Star => {
                    row_vals.push(key.clone());
                }
                SelectExpr::Aggregate(func, arg) => {
                    let val = compute_aggregate(sub_df, func, arg)?;
                    row_vals.push(val);
                }
            }
        }

        // Apply HAVING filter
        if let Some(having_expr) = having {
            // Build a temporary single-row dataframe for evaluation
            let temp = DataFrame::from_raw(
                result_col_names.clone(),
                row_vals.iter().map(|v| vec![v.clone()]).collect(),
            );
            if !eval_expr(having_expr, temp.columns(), temp.raw_data(), 0)? {
                continue;
            }
        }

        for (ci, val) in row_vals.into_iter().enumerate() {
            result_data[ci].push(val);
        }
    }

    Ok(DataFrame::from_raw(result_col_names, result_data))
}

/// Execute aggregate SELECT without GROUP BY (whole table is one group).
fn execute_aggregate_no_group(
    df: &DataFrame,
    select_exprs: &[SelectExpr],
) -> Result<DataFrame, String> {
    let mut col_names = Vec::new();
    let mut values = Vec::new();

    for expr in select_exprs {
        match expr {
            SelectExpr::Aggregate(func, arg) => {
                col_names.push(agg_col_name(func, arg));
                values.push(compute_aggregate(df, func, arg)?);
            }
            SelectExpr::Column(name) => {
                col_names.push(name.clone());
                let val = if df.nrows() > 0 {
                    df.get_value(0, ColRef::Name(name.clone()))
                        .unwrap_or(CellValue::Nil)
                } else {
                    CellValue::Nil
                };
                values.push(val);
            }
            SelectExpr::Star => {
                return Err("cannot use * with aggregate functions without GROUP BY".to_string());
            }
        }
    }

    Ok(DataFrame::from_raw(
        col_names,
        values.into_iter().map(|v| vec![v]).collect(),
    ))
}

/// Compute an aggregate function value for a DataFrame.
fn compute_aggregate(df: &DataFrame, func: &AggFunc, arg: &AggArg) -> Result<CellValue, String> {
    match func {
        AggFunc::Count => match arg {
            AggArg::Star => Ok(CellValue::Number(df.nrows() as f64)),
            AggArg::Column(col) => {
                let data = df.get_column(ColRef::Name(col.clone()))?;
                let count = data.iter().filter(|v| !v.is_nil()).count();
                Ok(CellValue::Number(count as f64))
            }
        },
        AggFunc::Sum => {
            let col = agg_col_ref(arg)?;
            match df.sum(ColRef::Name(col)) {
                Ok(s) => Ok(CellValue::Number(s)),
                Err(_) => Ok(CellValue::Nil),
            }
        }
        AggFunc::Avg => {
            let col = agg_col_ref(arg)?;
            match df.mean(ColRef::Name(col)) {
                Ok(m) => Ok(CellValue::Number(m)),
                Err(_) => Ok(CellValue::Nil),
            }
        }
        AggFunc::Min => {
            let col = agg_col_ref(arg)?;
            match df.min_val(ColRef::Name(col)) {
                Ok(m) => Ok(CellValue::Number(m)),
                Err(_) => Ok(CellValue::Nil),
            }
        }
        AggFunc::Max => {
            let col = agg_col_ref(arg)?;
            match df.max_val(ColRef::Name(col)) {
                Ok(m) => Ok(CellValue::Number(m)),
                Err(_) => Ok(CellValue::Nil),
            }
        }
    }
}

/// Get the column name from an aggregate argument.
fn agg_col_ref(arg: &AggArg) -> Result<String, String> {
    match arg {
        AggArg::Column(col) => Ok(col.clone()),
        AggArg::Star => Err("aggregate function requires a column name, not *".to_string()),
    }
}

/// Generate a display name for an aggregate column.
fn agg_col_name(func: &AggFunc, arg: &AggArg) -> String {
    let func_name = match func {
        AggFunc::Count => "COUNT",
        AggFunc::Sum => "SUM",
        AggFunc::Avg => "AVG",
        AggFunc::Min => "MIN",
        AggFunc::Max => "MAX",
    };
    let arg_name = match arg {
        AggArg::Star => "*".to_string(),
        AggArg::Column(col) => col.clone(),
    };
    format!("{func_name}({arg_name})")
}
