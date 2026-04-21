// Convert domain error to LuaError at the binding boundary:
let texture = state.borrow().load_texture(path)
    .map_err(LuaError::external)?;

// Validate Lua input with a descriptive message:
if width == 0 {
    return Err(LuaError::RuntimeError(
        "lurek.render.newCanvas: width must be > 0".into()
    ));
}
