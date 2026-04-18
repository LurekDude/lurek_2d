/// Registers the `lurek.<module>` API table with the Lua VM.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // ... entries ...

    lurek.set("<module>", tbl)?;
    Ok(())
}
