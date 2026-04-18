        // -- tick --
        /// Advances the scheduler by dt seconds, firing due callbacks.
        /// @param dt : number
        /// @return nil
        methods.add_method_mut("tick", |lua, this, dt: f32| {
            if let Some(key) = &this.callback_key {  // guard: Option<LuaRegistryKey>
                let func: LuaFunction = lua.registry_value(key)?;
                this.inner.tick(dt, &func)?;  // single domain call
            }
            Ok(())
        });
