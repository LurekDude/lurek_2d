//! `lurek.fs` — Sandboxed file I/O, directory queries, and async asset loading.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::filesystem::{FileData, FileHandle, GameFS};

// -------------------------------------------------------------------------------
// LuaFileData UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`FileData`] buffer.
pub struct LuaFileData {
    inner: FileData,
}

impl LuaUserData for LuaFileData {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {

        // -- getSize --
        /// Returns the file size in bytes.
        /// @return integer
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.len() as i64));

        // -- getString --
        /// Returns the file content as a Lua string.
        /// @return string
        methods.add_method("getString", |lua, this, ()| {
            lua.create_string(&this.inner.bytes)
        });

        // -- getFilename --
        /// Returns the virtual path this data was loaded from.
        /// @return string
        methods.add_method("getFilename", |_, this, ()| Ok(this.inner.path.clone()));

    }
}

// -------------------------------------------------------------------------------
// LuaFileHandle UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`FileHandle`] with interior mutability.
pub struct LuaFileHandle {
    inner: RefCell<FileHandle>,
}

impl LuaUserData for LuaFileHandle {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {

        // -- read --
        /// Reads bytes from the file, returning them as a string.
        /// @param count : integer?
        /// @return string
        methods.add_method("read", |_, this, count: Option<usize>| {
            let bytes = this.inner.borrow_mut().read(count).map_err(LuaError::external)?;
            Ok(String::from_utf8_lossy(&bytes).to_string())
        });

        // -- readLine --
        /// Reads the next line from the file without the trailing newline.
        /// @return string?
        methods.add_method("readLine", |_, this, ()| {
            this.inner.borrow_mut().read_line().map_err(LuaError::external)
        });

        // -- write --
        /// Writes a string to the file and returns the number of bytes written.
        /// @param data : string
        /// @return integer
        methods.add_method("write", |_, this, data: String| {
            this.inner
                .borrow_mut()
                .write(data.as_bytes())
                .map_err(LuaError::external)
        });

        // -- seek --
        /// Seeks the file position to the given byte offset from the start.
        /// @param pos : integer
        /// @return integer
        methods.add_method("seek", |_, this, pos: u64| {
            this.inner.borrow_mut().seek(pos).map_err(LuaError::external)
        });

        // -- tell --
        /// Returns the current read/write byte offset from the start of the file.
        /// @return integer
        methods.add_method("tell", |_, this, ()| {
            this.inner.borrow_mut().tell().map_err(LuaError::external)
        });

        // -- getSize --
        /// Returns the size of the open file in bytes.
        /// @return integer
        methods.add_method("getSize", |_, this, ()| {
            Ok(this.inner.borrow().get_size())
        });

        // -- getMode --
        /// Returns the access mode the file was opened with.
        /// @return string
        methods.add_method("getMode", |_, this, ()| {
            Ok(this.inner.borrow().get_mode().as_str().to_string())
        });

        // -- flush --
        /// Flushes all buffered writes to disk without closing the handle.
        /// @return nil
        methods.add_method("flush", |_, this, ()| {
            this.inner.borrow_mut().flush().map_err(LuaError::external)
        });

        // -- close --
        /// Flushes any pending writes and closes the file handle.
        /// @return nil
        methods.add_method("close", |_, this, ()| {
            this.inner.borrow_mut().close().map_err(LuaError::external)
        });

        // -- isEOF --
        /// Returns whether the read cursor has reached the end of the file.
        /// @return boolean
        methods.add_method("isEOF", |_, this, ()| {
            this.inner.borrow_mut().is_eof().map_err(LuaError::external)
        });

    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.fs` API table with the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `state` — `Rc<RefCell<SharedState>>`.
///
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- read --
    /// Reads a text file and returns its contents as a string.
    /// @param path : string
    /// @return string
    let s = state.clone();
    tbl.set(
        "read",
        lua.create_function(move |_, path: String| {
            s.borrow().fs.read_string(&path).map_err(LuaError::external)
        })?,
    )?;

    // -- write --
    /// Writes a string to a file in the save directory.
    /// @param path : string
    /// @param data : string
    /// @return nil
    let s = state.clone();
    tbl.set(
        "write",
        lua.create_function(move |_, (path, data): (String, String)| {
            s.borrow()
                .fs
                .write_string(&path, &data)
                .map_err(LuaError::external)
        })?,
    )?;

    // -- exists --
    /// Returns whether the given file or directory exists.
    /// @param path : string
    /// @return boolean
    let s = state.clone();
    tbl.set(
        "exists",
        lua.create_function(move |_, path: String| Ok(s.borrow().fs.exists(&path)))?,
    )?;

    // -- append --
    /// Opens the file in append mode and writes the given string at the end.
    /// @param path : string
    /// @param data : string
    /// @return nil
    let s = state.clone();
    tbl.set(
        "append",
        lua.create_function(move |_, (path, data): (String, String)| {
            s.borrow()
                .fs
                .append_string(&path, &data)
                .map_err(LuaError::external)
        })?,
    )?;

    // -- openFile --
    /// Opens a file and returns a readable/writable file handle.
    /// @param path : string
    /// @param mode : string
    /// @return FileHandle
    let s = state.clone();
    tbl.set(
        "openFile",
        lua.create_function(move |_, (path, mode): (String, String)| {
            let handle = s.borrow().fs.open_file(&path, &mode).map_err(LuaError::external)?;
            Ok(LuaFileHandle {
                inner: RefCell::new(handle),
            })
        })?,
    )?;

    // -- getDirectoryItems --
    /// Returns a table containing the names of every file and subdirectory in the given path.
    /// @param path : string
    /// @return table
    let s = state.clone();
    tbl.set(
        "getDirectoryItems",
        lua.create_function(move |_, path: String| {
            s.borrow()
                .fs
                .get_directory_items(&path)
                .map_err(LuaError::external)
        })?,
    )?;

    // -- isFile --
    /// Returns whether the given path is a regular file.
    /// @param path : string
    /// @return boolean
    let s = state.clone();
    tbl.set(
        "isFile",
        lua.create_function(move |_, path: String| Ok(s.borrow().fs.is_file(&path)))?,
    )?;

    // -- isDirectory --
    /// Returns whether the given path is a directory.
    /// @param path : string
    /// @return boolean
    let s = state.clone();
    tbl.set(
        "isDirectory",
        lua.create_function(move |_, path: String| Ok(s.borrow().fs.is_directory(&path)))?,
    )?;

    // -- createDirectory --
    /// Creates a directory and any missing parent directories in the save area.
    /// @param path : string
    /// @return nil
    let s = state.clone();
    tbl.set(
        "createDirectory",
        lua.create_function(move |_, path: String| {
            s.borrow()
                .fs
                .create_directory(&path)
                .map_err(LuaError::external)
        })?,
    )?;

    // -- remove --
    /// Permanently deletes a file or empty directory from the save directory.
    /// @param path : string
    /// @return nil
    let s = state.clone();
    tbl.set(
        "remove",
        lua.create_function(move |_, path: String| {
            s.borrow().fs.remove(&path).map_err(LuaError::external)
        })?,
    )?;

    // -- getInfo --
    /// Returns a table of metadata for a path, or nil if the path does not exist.
    /// @param path : string
    /// @return table?
    let s = state.clone();
    tbl.set(
        "getInfo",
        lua.create_function(move |lua, path: String| {
            match s.borrow().fs.get_info(&path) {
                Ok(info) => {
                    let t = lua.create_table()?;
                    t.set("type", info.file_type.as_str())?;
                    t.set("size", info.size)?;
                    t.set("modtime", info.modified_time)?;
                    t.set("readonly", info.readonly)?;
                    Ok(Some(t))
                }
                Err(_) => Ok(None),
            }
        })?,
    )?;

    // -- getSource --
    /// Returns the absolute path of the directory the game was loaded from.
    /// @return string
    let s = state.clone();
    tbl.set(
        "getSource",
        lua.create_function(move |_, ()| Ok(s.borrow().fs.get_source()))?,
    )?;

    // -- getSaveDirectory --
    /// Returns the sandboxed save data directory path.
    /// @return string
    let s = state.clone();
    tbl.set(
        "getSaveDirectory",
        lua.create_function(move |_, ()| {
            Ok(s.borrow().fs.get_save_directory().to_string_lossy().to_string())
        })?,
    )?;

    // -- getWorkingDirectory --
    /// Returns the current working directory path.
    /// @return string
    tbl.set(
        "getWorkingDirectory",
        lua.create_function(move |_, ()| GameFS::get_working_directory().map_err(LuaError::external))?,
    )?;

    // -- getUserDirectory --
    /// Returns the current user's home directory path.
    /// @return string
    tbl.set(
        "getUserDirectory",
        lua.create_function(move |_, ()| Ok(GameFS::get_user_directory()))?,
    )?;

    // -- getIdentity --
    /// Returns the identity string used to locate the game's save directory.
    /// @return string
    let s = state.clone();
    tbl.set(
        "getIdentity",
        lua.create_function(move |_, ()| Ok(s.borrow().filesystem_identity.clone()))?,
    )?;

    // -- setIdentity --
    /// Sets the identity string that names the game's sandboxed save-data directory.
    /// @param name : string
    /// @return nil
    let s = state.clone();
    tbl.set(
        "setIdentity",
        lua.create_function(move |_, name: String| {
            s.borrow_mut().filesystem_identity = name;
            Ok(())
        })?,
    )?;

    // -- lines --
    /// Returns an iterator function over the lines of a text file.
    /// @param path : string
    /// @return function
    let s = state.clone();
    tbl.set(
        "lines",
        lua.create_function(move |lua, path: String| {
            let lines = s.borrow().fs.read_lines(&path).map_err(LuaError::external)?;
            let iter = Rc::new(RefCell::new(lines.into_iter()));
            let iter_fn = lua.create_function(move |_, ()| Ok(iter.borrow_mut().next()))?;
            Ok(iter_fn)
        })?,
    )?;

    // -- readAsync --
    /// Starts loading a file in the background and returns an opaque handle.
    /// @param path : string
    /// @return integer
    let s = state.clone();
    tbl.set(
        "readAsync",
        lua.create_function(move |_, path: String| {
            s.borrow_mut()
                .request_async_load(&path)
                .map_err(LuaError::external)
        })?,
    )?;

    // -- pollAsync --
    /// Polls an async load handle, returning status and optional data.
    /// @param handle : integer
    /// @return string, string?
    let s = state.clone();
    tbl.set(
        "pollAsync",
        lua.create_function(move |_, handle_id: u64| {
            Ok(s.borrow().poll_async_load(handle_id))
        })?,
    )?;

    // -- mount --
    /// Mounts a directory at a virtual path inside the game filesystem.
    /// @param source : string
    /// @param mountpoint : string
    /// @return boolean
    let s = state.clone();
    tbl.set(
        "mount",
        lua.create_function(move |_, (src, mp): (String, String)| {
            s.borrow_mut()
                .fs
                .mount(&src, &mp)
                .map(|_| true)
                .map_err(LuaError::external)
        })?,
    )?;

    // -- unmount --
    /// Removes a virtual mount layer by mountpoint.
    /// @param mountpoint : string
    /// @return boolean
    let s = state.clone();
    tbl.set(
        "unmount",
        lua.create_function(move |_, mp: String| Ok(s.borrow_mut().fs.unmount(&mp)))?,
    )?;

    // -- load --
    /// Loads and compiles a Lua file from the VFS, returning it as a callable function.
    /// @param path : string
    /// @return function
    let s = state.clone();
    tbl.set(
        "load",
        lua.create_function(move |ctx, path: String| {
            let bytes = s.borrow().fs.load_chunk(&path).map_err(LuaError::external)?;
            ctx.load(&bytes[..]).into_function()
        })?,
    )?;

    // -- newFileData --
    /// Loads a file from the VFS into a FileData buffer.
    /// @param path : string
    /// @return FileData
    let s = state.clone();
    tbl.set(
        "newFileData",
        lua.create_function(move |_, path: String| {
            let bytes = s.borrow().fs.load_chunk(&path).map_err(LuaError::external)?;
            Ok(LuaFileData {
                inner: FileData::new(path, bytes),
            })
        })?,
    )?;

    luna.set("fs", tbl)?;
    Ok(())
}
