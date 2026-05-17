//! `lurek.repl` -- Release-safe Lua REPL session bindings for interactive evaluation.

use crate::repl::ReplSession;
use crate::runtime::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

/// Lua-side REPL session handle with bounded history.
pub struct LReplSession {
    /// Release-safe REPL session implementation.
    inner: ReplSession,
}

/// Provides Lua methods for evaluating code, reading history, completion, and identifying REPL handles.
impl LuaUserData for LReplSession {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- eval --
        /// Evaluates Lua code and records the input in this REPL history.
        /// @param | code | string | Lua expression, statement, or REPL command to evaluate.
        /// @return | string | Display text for the result, command, or error.
        methods.add_method_mut("eval", |lua, this, code: String| {
            Ok(this.inner.eval_line(&code, lua).display_text())
        });
        // -- history --
        /// Returns the recorded REPL input history in oldest-first order.
        /// @return | string[] | History entry strings.
        methods.add_method("history", |lua, this, ()| {
            let table = lua.create_table()?;
            for (index, entry) in this.inner.history().iter().enumerate() {
                table.set(index + 1, entry.clone())?;
            }
            Ok(table)
        });
        // -- clear --
        /// Clears all entries from this REPL session history.
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        // -- len --
        /// Returns the number of entries stored in this REPL history.
        /// @return | integer | History entry count.
        methods.add_method("len", |_, this, ()| Ok(this.inner.len()));
        // -- complete --
        /// Returns completion candidates that begin with the supplied prefix.
        /// @param | prefix | string | Prefix text to complete.
        /// @return | string[] | Matching completion strings.
        methods.add_method("complete", |lua, this, prefix: String| {
            let table = lua.create_table()?;
            for (index, item) in this
                .inner
                .completions_for(&prefix, Some(lua))
                .into_iter()
                .enumerate()
            {
                table.set(index + 1, item)?;
            }
            Ok(table)
        });
        // -- type --
        /// Returns the Lua-visible type name for this REPL session handle.
        /// @return | string | The string `LReplSession`.
        methods.add_method("type", |_, _, ()| Ok("LReplSession"));
        // -- typeOf --
        /// Returns whether this REPL session handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LReplSession` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LReplSession" || name == "Object")
        });
    }
}

/// Registers the `lurek.repl` API table with the Lua VM.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let repl = lua.create_table()?;
    // -- new --
    /// Creates a release-safe REPL session with bounded command history.
    /// @param | max_history | integer? | Maximum number of history entries; defaults to 200.
    /// @return | LReplSession | REPL session handle for eval, history, and completion.
    repl.set(
        "new",
        lua.create_function(|lua, max_history: Option<usize>| {
            lua.create_userdata(LReplSession {
                inner: ReplSession::new(max_history.unwrap_or(200)),
            })
        })?,
    )?;
    /// Performs the 'repl' operation.
    lurek.set("repl", repl)?;
    Ok(())
}
