// src/lua_api/image_api.rs  ← CORRECT place for BOTH the struct and impl
pub struct LuaImage {
    pub key: TextureKey,
    pub width: u32,
    pub height: u32,
}

impl LuaUserData for LuaImage {
    fn add_methods<M: LuaUserDataMethods<Self>>(methods: &mut M) {
        methods.add_method("getWidth", |_, this, ()| Ok(this.width));
        methods.add_method("release", |_, this, ()| {
            Ok(())
        });
    }
}
