tbl.set("step", lua.create_function(move |_, dt: f32| {
    let mut s = state.borrow_mut();
    s.clock.total_time += dt;
    s.clock.fps = 1.0 / dt;
    s.clock.frame += 1;
    Ok(())
})?)?;
