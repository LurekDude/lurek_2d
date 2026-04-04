//! UserData type utilities for Luna2D Lua objects.
//!
//! Provides the `LunaType` trait and `add_type_methods` helper so every
//! Luna2D UserData object exposes `type()` and `typeOf()` methods matching
//! Love2D's object type system.

/// Standard type identification for Luna2D UserData objects.
///
/// Every Luna2D Lua object implements this trait to declare its type name
/// and its position in the type hierarchy (e.g. Image → Drawable → Object).
pub trait LunaType {
    /// The type name (e.g., "Image", "Source", "Body").
    const TYPE_NAME: &'static str;
    /// Type hierarchy for `typeOf()` checks, from most-specific to least.
    const TYPE_HIERARCHY: &'static [&'static str];
}

/// Adds standard `type()` and `typeOf()` methods to a UserData definition.
///
/// - `type()` returns the concrete type name string.
/// - `typeOf(name)` returns `true` if the object is of the given type or
///   any of its parent types in the hierarchy.
pub fn add_type_methods<'a, T: LunaType + 'static>(
    methods: &mut impl mlua::UserDataMethods<'a, T>,
) {
    methods.add_method("type", |_, _this, ()| Ok(T::TYPE_NAME.to_string()));
    methods.add_method("typeOf", |_, _this, name: String| {
        Ok(T::TYPE_NAME == name || T::TYPE_HIERARCHY.contains(&name.as_str()))
    });
}
