impl LuaUserData for LuaFoo {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {

        // -- methodName --
        /// One-sentence description.
        /// @param arg : type
        /// @return type
        methods.add_method("methodName", |_, this, arg: T| {
            Ok(this.inner.method(arg))
        });

        // -- mutateFoo --
        /// Mutates an internal field.
        /// @param value : number
        /// @return nil
        methods.add_method_mut("mutateFoo", |_, this, value: f32| {
            this.inner.set_value(value);
            Ok(())
        });

        // -- __tostring --
        /// Returns a human-readable string for debugging.
        /// @return string
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(this.inner.to_display_string())
        });

    }
}
