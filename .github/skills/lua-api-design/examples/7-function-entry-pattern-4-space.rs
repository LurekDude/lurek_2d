    // -- funcName --
    /// One-sentence description.
    /// @param arg : type
    /// @return type
    let s = state.clone();
    tbl.set(
        "funcName",
        lua.create_function(move |_, arg: T| Ok(s.borrow().method(arg)))?,
    )?;
