//! Shared trait and helper for consistent `type()`, `typeOf()`, and `__tostring`
//! across all Lurek2D UserData types exposed to Lua.

use mlua::prelude::*;

// ============================================================
// LurekType trait
// ============================================================

/// Marker trait that every Lua UserData type in Lurek2D must implement.
///
/// Provides the canonical `TYPE_NAME` string and `TYPE_HIERARCHY` slice used
/// by the `type()`, `typeOf()`, and `__tostring` Lua methods added by
/// [`add_type_methods`].
pub trait LurekType {
    /// The primary type name returned by `obj:type()`.
    const TYPE_NAME: &'static str;

    /// The full ancestry chain from most-derived to least-derived.
    /// Every type must include at least `[Self::TYPE_NAME, "Object"]`.
    const TYPE_HIERARCHY: &'static [&'static str];
}

// ============================================================
// add_type_methods — generic helper
// ============================================================

/// Adds the standard `type()`, `typeOf(typeName)`, and `__tostring` methods to
/// any [`LuaUserData`] type that also implements [`LurekType`].
///
/// `methods` is the method table being populated inside `LuaUserData::add_methods`.
///
/// Call this as the **first** statement inside `add_methods`:
///
/// ```rust,ignore
/// impl LuaUserData for MyType {
///     fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
///         add_type_methods(methods);
///         // … domain methods …
///     }
/// }
/// ```
pub fn add_type_methods<'lua, T, M>(methods: &mut M)
where
    T: LurekType + LuaUserData,
    M: LuaUserDataMethods<'lua, T>,
{
    // -- type() -> string
    methods.add_method("type", |_, _, ()| Ok(T::TYPE_NAME));

    // -- typeOf(name) -> boolean
    methods.add_method("typeOf", |_, _, name: String| {
        Ok(T::TYPE_HIERARCHY.contains(&name.as_str()))
    });

    // -- __tostring
    methods.add_meta_method(LuaMetaMethod::ToString, |_, _, ()| {
        Ok(format!("{}()", T::TYPE_NAME))
    });
}
