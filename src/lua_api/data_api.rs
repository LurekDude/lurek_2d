//! `luna.data` Lua API bindings.
//!
//! Auto-generated skeleton from `src/data/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaByteData ────────────────────────────────────────────────────────────

pub struct LuaByteData(/* TODO: add key + state fields */);


impl LuaByteData {
    /// Get the size of the buffer in bytes.
    ///
    ///
    /// @return integer
    pub fn len(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Check if the buffer is empty. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return boolean
    pub fn is_empty(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get a byte at the given offset (0-based).
    ///
    /// @param offset : integer
    /// @return u8?
    pub fn get_byte(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the data as a lossy UTF-8 string.
    ///
    ///
    /// @return string
    pub fn get_string(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Clone the data into a new ByteData. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// @return Self
    pub fn clone_data(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaByteData {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("len", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isEmpty", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getByte", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getString", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("cloneData", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaDataView ────────────────────────────────────────────────────────────

pub struct LuaDataView(/* TODO: add key + state fields */);


impl LuaDataView {
    /// Returns the number of bytes in this view.
    ///
    ///
    /// @return integer
    pub fn get_size(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Reads a `u8` at `idx` relative to this view's start offset.
    ///
    /// @param idx : integer
    /// @return Result<u8
    pub fn get_u8(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Reads an `i8` at `idx`.
    ///
    /// @param idx : integer
    /// @return Result<i8
    pub fn get_i8(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Reads a little-endian `u16` at `idx`.
    ///
    /// @param idx : integer
    /// @return Result<u16
    pub fn get_u16(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Reads a little-endian `i16` at `idx`.
    ///
    /// @param idx : integer
    /// @return Result<i16
    pub fn get_i16(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Reads a little-endian `u32` at `idx`.
    ///
    /// @param idx : integer
    /// @return Result<u32
    pub fn get_u32(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Reads a little-endian `i32` at `idx`.
    ///
    /// @param idx : integer
    /// @return Result<i32
    pub fn get_i32(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Reads a little-endian `f32` at `idx`.
    ///
    /// @param idx : integer
    /// @return Result<f32
    pub fn get_f32(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Reads a little-endian `f64` at `idx`.
    ///
    /// @param idx : integer
    /// @return Result<f64
    pub fn get_f64(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaDataView {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getSize", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getU8", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getI8", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getU16", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getI16", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getU32", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getI32", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getF32", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getF64", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.data.* functions ──────────────────────────────────────────

/// Write values into a binary buffer according to a Luna2D format string.
///
/// @param format : str
/// @param values : [BinValue]
/// @return Result<ByteData
pub fn write(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Read values from a binary buffer according to a Luna2D format string.
///
/// @param format : str
/// @param data : [u8]
/// @param offset : integer
/// @return Result<(Vec<BinValue>
pub fn read(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Compute the total byte size that `write` would produce for the given format string.
///
/// Returns an error if the format contains `str` or `cstr` tokens since their
/// encoded size depends on the string content.
///
/// @param format : str
/// @return Result<usize
pub fn measure_size(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Create from an existing byte vector. Returns a fully initialised instance with all fields set to their initial values.
///
/// @param bytes : table
/// @return Self
pub fn from_bytes(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Create from a string. Returns a fully initialised instance with all fields set to their initial values.
///
/// @param s : str
/// @return Self
pub fn from_string(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set a byte at the given offset (0-based). Returns false if out of bounds.
///
/// @param offset : integer
/// @param value : u8
/// @return boolean
pub fn set_byte(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Parse a format name string. Returns an error if the source data is malformed or missing.
///
/// @param s : str
/// @return Result<Self
pub fn parse_str(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Compress data using the specified format and compression level (0-9).
///
/// @param data : [u8]
/// @param format : CompressFormat
/// @param level : integer
/// @return Result<Vec<u8>
pub fn compress(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Decompress data using the specified format.
///
/// @param data : [u8]
/// @param format : CompressFormat
/// @return Result<Vec<u8>
pub fn decompress(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Creates a view starting at `offset` covering `size` bytes.
///
/// Returns an error if `offset + size` exceeds the buffer length.
///
/// @param data : Arc<Vec<u8>>
/// @param offset : integer
/// @param size : integer
/// @return Result<Self
pub fn new_slice(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Parse a format name string. Returns an error if the source data is malformed or missing.
///
/// @param s : str
/// @return Result<Self
/// Encode bytes into a string using the specified format.
///
/// @param format : EncodeFormat
/// @param data : [u8]
/// @return string
pub fn encode(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Decode a string back into bytes using the specified format.
///
/// @param format : EncodeFormat
/// @param text : str
/// @return Result<Vec<u8>
pub fn decode(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Parse an algorithm name string. Returns an error if the source data is malformed or missing.
///
/// @param s : str
/// @return Result<Self
/// Compute the hash of data using the specified algorithm, returned as a hex string.
///
/// @param algorithm : HashAlgorithm
/// @param data : [u8]
/// @return string
pub fn hash(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Packs values according to a format string into a `ByteData` buffer.
///
/// Format characters:
/// - `<` — switch to little-endian (default)
/// - `>` — switch to big-endian
/// - `b`/`B` — i8 / u8
/// - `h`/`H` — i16 / u16
/// - `i`/`I` — i32 / u32
/// - `l`/`L` — i64 / u64
/// - `f` — f32
/// - `d`/`n` — f64
/// - `s` — length-prefixed string (u32 len + bytes)
/// - `z` — null-terminated string
/// - `x` — padding byte (zero)
///
/// @param format : str
/// @param values : [PackValue]
/// @return Result<ByteData
pub fn pack(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Unpacks values from a byte buffer according to a format string.
///
/// Returns all decoded values followed by the next unread byte offset.
///
/// @param format : str
/// @param data : [u8]
/// @param offset : integer
/// @return Result<(Vec<PackValue>
pub fn unpack(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Computes the total byte size that `pack` would produce for the given format and values.
///
/// For fixed-width types (`b`/`B`/`h`/`H`/`i`/`I`/`l`/`L`/`f`/`d`/`n`) the values are not
/// accessed, so an empty slice may be passed. String types (`s`/`z`) require the corresponding
/// `PackValue::Str` entry to compute the size.
///
/// @param format : str
/// @param values : [PackValue]
/// @return Result<usize
pub fn get_packed_size(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Parse a TOML string into a `toml::Value`.
///
/// @param input : str
/// @return Result<toml
pub fn parse_toml(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Encode a `toml::Value` into a TOML string.
///
/// @param value : toml::Value
/// @return Result<String
pub fn encode_toml(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.data` API table.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("write", lua.create_function(write)?)?;
    tbl.set("read", lua.create_function(read)?)?;
    tbl.set("measureSize", lua.create_function(measure_size)?)?;
    tbl.set("fromBytes", lua.create_function(from_bytes)?)?;
    tbl.set("fromString", lua.create_function(from_string)?)?;
    tbl.set("setByte", lua.create_function(set_byte)?)?;
    tbl.set("parseStr", lua.create_function(parse_str)?)?;
    tbl.set("compress", lua.create_function(compress)?)?;
    tbl.set("decompress", lua.create_function(decompress)?)?;
    tbl.set("newSlice", lua.create_function(new_slice)?)?;
    tbl.set("parseStr", lua.create_function(parse_str)?)?;
    tbl.set("encode", lua.create_function(encode)?)?;
    tbl.set("decode", lua.create_function(decode)?)?;
    tbl.set("parseStr", lua.create_function(parse_str)?)?;
    tbl.set("hash", lua.create_function(hash)?)?;
    tbl.set("pack", lua.create_function(pack)?)?;
    tbl.set("unpack", lua.create_function(unpack)?)?;
    tbl.set("getPackedSize", lua.create_function(get_packed_size)?)?;
    tbl.set("parseToml", lua.create_function(parse_toml)?)?;
    tbl.set("encodeToml", lua.create_function(encode_toml)?)?;
    luna.set("data", tbl)?;
    Ok(())
}
