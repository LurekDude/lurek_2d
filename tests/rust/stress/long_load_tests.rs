//! Optional long-running load tests gated by the `long-load-tests` feature.

#[cfg(feature = "long-load-tests")]
mod long_load_tests {
    use std::cell::RefCell;
    use std::path::PathBuf;
    use std::rc::Rc;

    use lurek2d::lua_api::{create_lua_vm, SharedState};
    use lurek2d::runtime::config::Config;

    fn create_vm() -> mlua::Lua {
        let state = Rc::new(RefCell::new(SharedState::new(
            800,
            600,
            "LongLoad",
            PathBuf::from("."),
        )));
        state.borrow_mut().load_default_fonts();
        create_lua_vm(state, &Config::default().modules).expect("Failed to create Lua VM")
    }

    #[test]
    fn lua_data_math_long_loop_stays_stable() {
        let lua = create_vm();

        let script = r#"
            local acc = 0
            for i = 1, 20000 do
                local x = i * 0.001
                acc = acc + lurek.math.sin(x) + lurek.math.cos(x)
                local b = lurek.data.pack("<f", x)
                local y = lurek.data.unpack("<f", b)
                if i % 5000 == 0 then
                    assert(type(y) == "number")
                end
            end
            assert(type(acc) == "number")
        "#;

        lua.load(script)
            .set_name("long_load_data_math")
            .exec()
            .expect("long load Lua script failed");
    }
}
