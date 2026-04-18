// -- step --
/// Advances the clock by dt seconds.
/// @param dt : number
/// @return nil
let s = state.clone();
tbl.set("step", lua.create_function(move |_, dt: f32| {
    s.borrow_mut().clock.tick(dt);  // single domain call
    Ok(())
})?)?;
