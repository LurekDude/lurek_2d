import sys

with open('src/lua_api/ui_api.rs', 'r', encoding='utf-8') as f:
    text = f.read()

# I will just append to the file if they don't exist
if 'LuaLineChart' not in text:
    appendix = '''
// â”€â”€ LuaLineChart â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
pub struct LuaLineChart {
    pub inner: crate::ui::chart::LineChart,
}

impl LuaUserData for LuaLineChart {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("drawToImage", |_, this, target: mlua::AnyUserData| {
            let mut img = target.borrow_mut::<crate::lua_api::image_api::ImageData>()?;
            this.inner.draw_to_image(&mut img.inner);
            Ok(())
        });
    }
}

// â”€â”€ LuaBarChart â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
pub struct LuaBarChart {
    pub inner: crate::ui::chart::BarChart,
}

impl LuaUserData for LuaBarChart {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("drawToImage", |_, this, target: mlua::AnyUserData| {
            let mut img = target.borrow_mut::<crate::lua_api::image_api::ImageData>()?;
            this.inner.draw_to_image(&mut img.inner);
            Ok(())
        });
    }
}

// â”€â”€ LuaScatterPlot â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
pub struct LuaScatterPlot {
    pub inner: crate::ui::chart::ScatterPlot,
}

impl LuaUserData for LuaScatterPlot {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("drawToImage", |_, this, target: mlua::AnyUserData| {
            let mut img = target.borrow_mut::<crate::lua_api::image_api::ImageData>()?;
            this.inner.draw_to_image(&mut img.inner);
            Ok(())
        });
    }
}

// â”€â”€ LuaPieChart â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
pub struct LuaPieChart {
    pub inner: crate::ui::chart::PieChart,
}

impl LuaUserData for LuaPieChart {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("drawToImage", |_, this, target: mlua::AnyUserData| {
            let mut img = target.borrow_mut::<crate::lua_api::image_api::ImageData>()?;
            this.inner.draw_to_image(&mut img.inner);
            Ok(())
        });
    }
}

// â”€â”€ LuaAreaChart â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
pub struct LuaAreaChart {
    pub inner: crate::ui::chart::AreaChart,
}

impl LuaUserData for LuaAreaChart {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("drawToImage", |_, this, target: mlua::AnyUserData| {
            let mut img = target.borrow_mut::<crate::lua_api::image_api::ImageData>()?;
            this.inner.draw_to_image(&mut img.inner);
            Ok(())
        });
    }
}
'''
    text = text.replace('luna.set("ui", tbl)?;\n    Ok(())\n}', 'luna.set("ui", tbl)?;\n    Ok(())\n}\n\n' + appendix)
    with open('src/lua_api/ui_api.rs', 'w', encoding='utf-8') as f:
        f.write(text)

