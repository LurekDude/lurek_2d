use crate::devtools::lua_display::value_to_string;
#[derive(Debug, Clone)]
/// Store REPL command history and capacity limits for local dev sessions.
pub struct ReplConsole {
    /// Keep submitted REPL input lines in insertion order.
    history: Vec<String>,
    /// Define maximum number of history entries retained in memory.
    max_history: usize,
}
/// Provide default REPL history capacity for convenience construction.
impl Default for ReplConsole {
    fn default() -> Self {
        Self::new(200)
    }
}
impl ReplConsole {
    /// Create a REPL console with bounded history and return the instance.
    pub fn new(max_history: usize) -> Self {
        let cap = max_history.max(1);
        Self {
            history: Vec::with_capacity(cap.min(64)),
            max_history: cap,
        }
    }
    /// Evaluate input and return expression result, ok marker, or error text.
    pub fn eval(&mut self, input: &str, lua: &mlua::Lua) -> String {
        self.push_history(input.to_string());
        let expr = format!("return {input}");
        let result: String = match lua.load(&expr).eval::<mlua::Value>() {
            Ok(v) => value_to_string(&v),
            Err(_) => match lua.load(input).exec() {
                Ok(()) => "(ok)".to_string(),
                Err(e) => format!("error: {e}"),
            },
        };
        log::debug!("devtools: repl eval → {result}");
        result
    }
    /// Return an immutable slice of stored history entries.
    pub fn history(&self) -> &[String] {
        &self.history
    }
    /// Clear command history and return unit.
    pub fn clear(&mut self) {
        self.history.clear();
        log::debug!("devtools: repl history cleared");
    }
    /// Return the number of stored history entries.
    pub fn len(&self) -> usize {
        self.history.len()
    }
    /// Return true when history contains no entries.
    pub fn is_empty(&self) -> bool {
        self.history.is_empty()
    }
    /// Insert one history entry and evict oldest entry when capacity is reached.
    fn push_history(&mut self, entry: String) {
        if self.history.len() >= self.max_history {
            self.history.remove(0);
        }
        self.history.push(entry);
    }
}
