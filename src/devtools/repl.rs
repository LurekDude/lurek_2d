//! Scope: Interactive Lua REPL console with bounded input history.
//! This file defines ReplConsole and expression evaluation with wrapping.
//! It owns evaluation fallback paths and history buffer management.

use crate::devtools::lua_display::value_to_string;

/// Interactive Lua REPL with a bounded input history buffer.
///
/// # Fields
/// - `history` — `Vec<String>` — evaluated inputs, oldest first.
/// - `max_history` — `usize` — maximum number of history entries kept.
#[derive(Debug, Clone)]
pub struct ReplConsole {
    history: Vec<String>,
    max_history: usize,
}

impl Default for ReplConsole {
    fn default() -> Self {
        Self::new(200)
    }
}

impl ReplConsole {
    /// Creates a new REPL console with the given history limit.
    ///
    /// # Parameters
    /// - `max_history` — `usize` — maximum entries to keep (min 1).
    ///
    /// # Returns
    /// `ReplConsole`.
    pub fn new(max_history: usize) -> Self {
        let cap = max_history.max(1);
        Self {
            history: Vec::with_capacity(cap.min(64)),
            max_history: cap,
        }
    }

    /// Evaluates a Lua snippet and records the input in history.
    ///
    /// The Lua chunk is wrapped in `tostring(...)` so that single-expression
    /// inputs (e.g. `1 + 1`) return their value as a string.  Multi-statement
    /// inputs are run without the wrapper; if the chunk raises an error the
    /// error message is returned rather than propagating as a Rust error.
    ///
    /// # Parameters
    /// - `input` — `&str` — Lua snippet to evaluate.
    /// - `lua` — `&mlua::Lua` — live Lua VM to evaluate against.
    ///
    /// # Returns
    /// `String` — result or error text.
    pub fn eval(&mut self, input: &str, lua: &mlua::Lua) -> String {
        // Record the input first, before evaluation.
        self.push_history(input.to_string());

        // Try to eval as an expression first (prepend "return").
        let expr = format!("return {input}");
        let result: String = match lua.load(&expr).eval::<mlua::Value>() {
            Ok(v) => value_to_string(&v),
            Err(_) => {
                // Fall back to running as a statement block.
                match lua.load(input).exec() {
                    Ok(()) => "(ok)".to_string(),
                    Err(e) => format!("error: {e}"),
                }
            }
        };

        log::debug!("devtools: repl eval → {result}");
        result
    }

    /// Returns a read-only slice of the history buffer (oldest first).
    ///
    /// # Returns
    /// `&[String]`.
    pub fn history(&self) -> &[String] {
        &self.history
    }

    /// Clears the history buffer.
    pub fn clear(&mut self) {
        self.history.clear();
        log::debug!("devtools: repl history cleared");
    }

    /// Returns the current number of history entries.
    ///
    /// # Returns
    /// `usize`.
    pub fn len(&self) -> usize {
        self.history.len()
    }

    /// Returns `true` if the history is empty.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.history.is_empty()
    }

    // ------------------------------------------------------------------
    // Internal helpers
    // ------------------------------------------------------------------

    fn push_history(&mut self, entry: String) {
        if self.history.len() >= self.max_history {
            self.history.remove(0);
        }
        self.history.push(entry);
    }
}
