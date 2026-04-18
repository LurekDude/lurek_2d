        // -- addFoo --
        /// Adds a foo.
        /// @param x : number
        /// @return nil
        methods.add_method(    // docstring here, above this line
            "addFoo",
            |_, this, x: f32| {
                this.inner.add_foo(x);
                Ok(())
            },
        );
