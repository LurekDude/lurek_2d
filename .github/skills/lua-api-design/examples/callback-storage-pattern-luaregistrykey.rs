        // -- setCallback --
        /// Registers a Lua function called on each tick.
        /// @param fn : function
        /// @return nil
        methods.add_method_mut("setCallback", |lua, this, func: LuaFunction| {
            this.callback_key = Some(lua.create_registry_value(func)?);
            Ok(())
        });
