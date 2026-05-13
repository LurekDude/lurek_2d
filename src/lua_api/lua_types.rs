use mlua::prelude::*;
pub trait LurekType {
    const TYPE_NAME: &'static str;
    const TYPE_HIERARCHY: &'static [&'static str];
}
pub fn add_type_methods<'lua, T, M>(methods: &mut M)
where
    T: LurekType + LuaUserData,
    M: LuaUserDataMethods<'lua, T>,
{
    methods.add_method("type", |_, _, ()| Ok(T::TYPE_NAME));
    methods.add_method("typeOf", |_, _, name: String| {
        Ok(T::TYPE_HIERARCHY.contains(&name.as_str()))
    });
    methods.add_meta_method(LuaMetaMethod::ToString, |_, _, ()| {
        Ok(format!("{}()", T::TYPE_NAME))
    });
}
