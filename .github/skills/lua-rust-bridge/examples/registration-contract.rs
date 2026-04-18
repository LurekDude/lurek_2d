pub fn register(
    lua: &Lua,
    luna: &LuaTable,
    state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // ── funcName ──────────────────────────────────
    /// One-sentence description.
    /// @param name : type
    /// @return type
    let s = state.clone();
    tbl.set("funcName", lua.create_function(move |_, arg: Type| {
        Ok(s.borrow().method(arg))
    })?)?;

    lurek.set("module", tbl)?;
    Ok(())
}
