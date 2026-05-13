use crate::devtools::lua_display::value_to_string;
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
    pub fn new(max_history: usize) -> Self {
        let cap = max_history.max(1);
        Self {
            history: Vec::with_capacity(cap.min(64)),
            max_history: cap,
        }
    }
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
    pub fn history(&self) -> &[String] {
        &self.history
    }
    pub fn clear(&mut self) {
        self.history.clear();
        log::debug!("devtools: repl history cleared");
    }
    pub fn len(&self) -> usize {
        self.history.len()
    }
    pub fn is_empty(&self) -> bool {
        self.history.is_empty()
    }
    fn push_history(&mut self, entry: String) {
        if self.history.len() >= self.max_history {
            self.history.remove(0);
        }
        self.history.push(entry);
    }
}
