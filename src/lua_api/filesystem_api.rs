//! `lurek.filesystem` - Sandboxed file I/O, directory queries, and async asset loading.
//!
//! All paths are resolved through the game's [`GameFS`] sandbox. Supports file
//! read/write via `FileHandle`, bulk-data via `FileData`, ZIP archive mounting,
//! directory listing, path manipulation, and per-file change watching.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::filesystem::watcher::FileWatcher;
use crate::filesystem::zip_mount::ZipMount;
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
        /// @return | integer | File size in bytes.
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.len() as i64));

        // -- getString --
        /// Returns the file content as a Lua string.
        /// @return | string | File contents as a Lua string.
        methods.add_method("getString", |lua, this, ()| {
            lua.create_string(&this.inner.bytes)
        });

        // -- getFilename --
        /// Returns the virtual path this data was loaded from.
        /// @return | string | Virtual path of this file data.
        methods.add_method("getFilename", |_, this, ()| Ok(this.inner.path.clone()));

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua type name.
        methods.add_method("type", |_, _, ()| Ok("LFileData"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LFileData" || name == "Object")
        });
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
        /// @param | count | integer | Maximum bytes to read, or nil to read the rest of the file.
        /// @return | string | Bytes read from the file as a Lua string.
        methods.add_method("read", |_, this, count: Option<usize>| {
            let bytes = this
                .inner
                .borrow_mut()
                .read(count)
                .map_err(LuaError::external)?;
            Ok(String::from_utf8_lossy(&bytes).to_string())
        });

        // -- readLine --
        /// Reads the next line from the file without the trailing newline.
        /// @return | string | Next line, or nil at end of file.
        methods.add_method("readLine", |_, this, ()| {
            this.inner
                .borrow_mut()
                .read_line()
                .map_err(LuaError::external)
        });

        // -- write --
        /// Writes a string to the file and returns the number of bytes written.
        /// @param | data | string | Text to write.
        /// @return | integer | Number of bytes written.
        methods.add_method("write", |_, this, data: String| {
            this.inner
                .borrow_mut()
                .write(data.as_bytes())
                .map_err(LuaError::external)
        });

        // -- seek --
        /// Seeks the file position to the given byte offset from the start.
        /// @param | pos | integer | Byte offset from the start of the file.
        /// @return | integer | New byte offset after seeking.
        methods.add_method("seek", |_, this, pos: u64| {
            this.inner
                .borrow_mut()
                .seek(pos)
                .map_err(LuaError::external)
        });

        // -- tell --
        /// Returns the current read/write byte offset from the start of the file.
        /// @return | integer | Current byte offset.
        methods.add_method("tell", |_, this, ()| {
            this.inner.borrow_mut().tell().map_err(LuaError::external)
        });

        // -- getSize --
        /// Returns the size of the open file in bytes.
        /// @return | integer | File size in bytes.
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.borrow().get_size()));

        // -- getMode --
        /// Returns the access mode the file was opened with.
        /// @return | string | File access mode.
        methods.add_method("getMode", |_, this, ()| {
            Ok(this.inner.borrow().get_mode().as_str().to_string())
        });

        // -- flush --
        /// Flushes all buffered writes to disk without closing the handle.
        /// @return | nil | No return value.
        methods.add_method("flush", |_, this, ()| {
            this.inner.borrow_mut().flush().map_err(LuaError::external)
        });

        // -- close --
        /// Flushes any pending writes and closes the file handle.
        /// @return | nil | No return value.
        methods.add_method("close", |_, this, ()| {
            this.inner.borrow_mut().close().map_err(LuaError::external)
        });

        // -- isEOF --
        /// Returns whether the read cursor has reached the end of the file.
        /// @return | boolean | True when the file is at end-of-file.
        methods.add_method("isEOF", |_, this, ()| {
            this.inner.borrow_mut().is_eof().map_err(LuaError::external)
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua type name.
        methods.add_method("type", |_, _, ()| Ok("LFileHandle"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LFileHandle" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Lua userdata wrapper around a [`ZipMount`].
/// Obtained from `lurek.filesystem.mountZip(archive_path, prefix)`.
struct LuaZipMount {
    inner: ZipMount,
}

impl LuaUserData for LuaZipMount {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- readFile --
        /// Reads a file from the ZIP and returns it as a string of bytes.
        /// @param | virtual_path | string | Virtual path inside the mounted ZIP archive.
        /// @return | string | File contents as a Lua string.
        methods.add_method("readFile", |_, this, virtual_path: String| {
            let bytes = this
                .inner
                .read_file(&virtual_path)
                .map_err(LuaError::RuntimeError)?;
            Ok(bytes)
        });

        // -- contains --
        /// Returns true if `virtual_path` exists inside this ZIP mount.
        /// @param | virtual_path | string | Virtual path to check inside the archive.
        /// @return | boolean | True when the path exists in the ZIP mount.
        methods.add_method("contains", |_, this, virtual_path: String| {
            Ok(this.inner.contains(&virtual_path))
        });

        // -- listFiles --
        /// Returns a sorted array of all virtual paths exposed by this ZIP mount.
        /// @return | table | Array of virtual path strings.
        methods.add_method("listFiles", |lua, this, ()| {
            let files = this.inner.list_files();
            let tbl = lua.create_table()?;
            for (i, f) in files.iter().enumerate() {
                tbl.set(i + 1, f.clone())?;
            }
            Ok(tbl)
        });

        // -- prefix --
        /// Returns the virtual path prefix this archive was mounted under.
        /// @return | string | Virtual mount prefix.
        methods.add_method("prefix", |_, this, ()| Ok(this.inner.prefix.clone()));

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua type name.
        methods.add_method("type", |_, _, ()| Ok("LZipMount"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LZipMount" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
/// Registers the `lurek.filesystem` API table with the Lua VM.
/// Returns `Ok(())` on success.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- ZIP mounting -------------------------------------------------

    // -- mountZip --
    /// Mounts a ZIP archive at a virtual path prefix and returns a mount handle.
    /// @param | archive_path | string | Path to the ZIP archive file.
    /// @param | prefix | string | Virtual mount point, for example `mods/extra`.
    /// @return | LZipMount | Mounted ZIP archive handle.
    tbl.set(
        "mountZip",
        lua.create_function(|lua, (archive_path, prefix): (String, String)| {
            let mount = ZipMount::new(&archive_path, &prefix).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaZipMount { inner: mount })
        })?,
    )?;

    // -- File watcher -------------------------------------------------

    let watcher_rc = Rc::new(RefCell::new(FileWatcher::new()));

    let wrc = watcher_rc.clone();
    // -- watchPath --
    /// Adds `path` to the polled file-watch list.
    /// @param | path | string | Path to start watching.
    /// @return | nil | No return value.
    tbl.set(
        "watchPath",
        lua.create_function(move |_, path: String| {
            wrc.borrow_mut().watch(&path);
            Ok(())
        })?,
    )?;

    let wrc = watcher_rc.clone();
    // -- unwatchPath --
    /// Removes `path` from the polled file-watch list.  No-op if not watched.
    /// @param | path | string | Path to stop watching.
    /// @return | nil | No return value.
    tbl.set(
        "unwatchPath",
        lua.create_function(move |_, path: String| {
            wrc.borrow_mut().unwatch(&path);
            Ok(())
        })?,
    )?;

    let wrc = watcher_rc.clone();
    // -- pollWatchers --
    /// Polls watched paths and returns the ones that changed since the last poll.
    /// @return | table | Array of changed path strings.
    tbl.set(
        "pollWatchers",
        lua.create_function(move |lua, ()| {
            let changed = wrc.borrow_mut().poll();
            let tbl = lua.create_table()?;
            for (i, p) in changed.iter().enumerate() {
                tbl.set(i + 1, p.to_string_lossy().into_owned())?;
            }
            Ok(tbl)
        })?,
    )?;

    // -- read --
    /// Reads a text file and returns its contents as a string.
    /// @param | path | string | Virtual path to the text file.
    /// @return | string | File contents.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "read",
        lua.create_function(move |_, path: String| {
            s.borrow().fs.read_string(&path).map_err(LuaError::external)
        })?,
    )?;

    // -- write --
    /// Writes a string to a file in the save directory.
    /// @param | path | string | Save path to write.
    /// @param | data | string | Text to write.
    /// @return | nil | No return value.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "write",
        lua.create_function(move |_, (path, data): (String, String)| {
            s.borrow()
                .fs
                .write_string(&path, &data)
                .map_err(LuaError::external)
        })?,
    )?;

    // -- readJson --
    /// Reads a JSON file as text and validates that the payload is valid JSON.
    /// @param | path | string | Virtual path to the JSON file.
    /// @return | string | JSON text.
    let s = state.clone();
    tbl.set(
        "readJson",
        lua.create_function(move |_, path: String| {
            s.borrow().fs.read_json(&path).map_err(LuaError::external)
        })?,
    )?;

    // -- writeJson --
    /// Writes validated JSON text to a file in the save sandbox.
    /// @param | path | string | Save path to write.
    /// @param | json | string | JSON payload.
    /// @return | nil | No return value.
    let s = state.clone();
    tbl.set(
        "writeJson",
        lua.create_function(move |_, (path, json): (String, String)| {
            s.borrow()
                .fs
                .write_json(&path, &json)
                .map_err(LuaError::external)
        })?,
    )?;

    // -- readOrWriteJson --
    /// Reads JSON from `path`, or writes `default_json` and returns it when missing.
    /// @param | path | string | Save path to read.
    /// @param | default_json | string | JSON payload written if file does not exist.
    /// @return | string | Existing or default JSON text.
    let s = state.clone();
    tbl.set(
        "readOrWriteJson",
        lua.create_function(move |_, (path, default_json): (String, String)| {
            s.borrow()
                .fs
                .read_or_write_json(&path, &default_json)
                .map_err(LuaError::external)
        })?,
    )?;

    // -- readBytes --
    /// Reads a file as raw bytes and returns a binary Lua string.
    /// @param | path | string | Virtual path to the file.
    /// @return | string | Raw file bytes as a binary Lua string.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "readBytes",
        lua.create_function(move |lua, path: String| {
            let bytes = s
                .borrow()
                .fs
                .read_bytes(&path)
                .map_err(LuaError::external)?;
            lua.create_string(&bytes)
        })?,
    )?;

    // -- writeBytes --
    /// Writes a binary Lua string to a file in the save directory.
    /// @param | path | string | Save path to write.
    /// @param | data | string | Binary payload.
    /// @return | nil | No return value.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "writeBytes",
        lua.create_function(move |_, (path, data): (String, LuaString)| {
            s.borrow()
                .fs
                .write_bytes(&path, data.as_bytes().as_ref())
                .map_err(LuaError::external)
        })?,
    )?;

    // -- exists --
    /// Returns whether the given file or directory exists.
    /// @param | path | string | Virtual path to check.
    /// @return | boolean | True when the path exists.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "exists",
        lua.create_function(move |_, path: String| Ok(s.borrow().fs.exists(&path)))?,
    )?;

    // -- append --
    /// Opens the file in append mode and writes the given string at the end.
    /// @param | path | string | Save path to append to.
    /// @param | data | string | Text to append.
    /// @return | nil | No return value.
    let s = state.clone();
    // Auto-doc: Lua API binding.
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
    /// @param | path | string | Virtual path to open.
    /// @param | mode | string | File access mode.
    /// @return | LFileHandle | Open file handle.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "openFile",
        lua.create_function(move |_, (path, mode): (String, String)| {
            let handle = s
                .borrow()
                .fs
                .open_file(&path, &mode)
                .map_err(LuaError::external)?;
            Ok(LuaFileHandle {
                inner: RefCell::new(handle),
            })
        })?,
    )?;

    // -- getDirectoryItems --
    /// Returns a table containing the names of every file and subdirectory in the given path.
    /// @param | path | string | Directory path to list.
    /// @return | table | Array of entry names.
    let s = state.clone();
    // Auto-doc: Lua API binding.
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
    /// @param | path | string | Virtual path to check.
    /// @return | boolean | True when the path is a regular file.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "isFile",
        lua.create_function(move |_, path: String| Ok(s.borrow().fs.is_file(&path)))?,
    )?;

    // -- isDirectory --
    /// Returns whether the given path is a directory.
    /// @param | path | string | Virtual path to check.
    /// @return | boolean | True when the path is a directory.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "isDirectory",
        lua.create_function(move |_, path: String| Ok(s.borrow().fs.is_directory(&path)))?,
    )?;

    // -- createDirectory --
    /// Creates a directory and any missing parent directories in the save area.
    /// @param | path | string | Save directory path to create.
    /// @return | nil | No return value.
    let s = state.clone();
    // Auto-doc: Lua API binding.
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
    /// @param | path | string | Save path to remove.
    /// @return | nil | No return value.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "remove",
        lua.create_function(move |_, path: String| {
            s.borrow().fs.remove(&path).map_err(LuaError::external)
        })?,
    )?;

    // -- getInfo --
    /// Returns a table of metadata for a path, or nil if the path does not exist.
    /// @param | path | string | Virtual path to inspect.
    /// @return | table | Metadata table, or nil if the path does not exist.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "getInfo",
        lua.create_function(
            move |lua, path: String| match s.borrow().fs.get_info(&path) {
                Ok(info) => {
                    let t = lua.create_table()?;
                    t.set("type", info.file_type.as_str())?;
                    t.set("size", info.size)?;
                    t.set("modtime", info.modified_time)?;
                    t.set("readonly", info.readonly)?;
                    Ok(Some(t))
                }
                Err(_) => Ok(None),
            },
        )?,
    )?;

    // -- getSource --
    /// Returns the absolute path of the directory the game was loaded from.
    /// @return | string | Absolute source directory path.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "getSource",
        lua.create_function(move |_, ()| Ok(s.borrow().fs.get_source()))?,
    )?;

    // -- getSaveDirectory --
    /// Returns the sandboxed save data directory path.
    /// @return | string | Absolute save directory path.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "getSaveDirectory",
        lua.create_function(move |_, ()| {
            Ok(s.borrow()
                .fs
                .get_save_directory()
                .to_string_lossy()
                .to_string())
        })?,
    )?;

    // -- getWorkingDirectory --
    /// Returns the current working directory path.
    /// @return | string | Current working directory path.
    tbl.set(
        "getWorkingDirectory",
        lua.create_function(move |_, ()| {
            GameFS::get_working_directory().map_err(LuaError::external)
        })?,
    )?;

    // -- getUserDirectory --
    /// Returns the current user's home directory path.
    /// @return | string | Current user's home directory path.
    tbl.set(
        "getUserDirectory",
        lua.create_function(move |_, ()| Ok(GameFS::get_user_directory()))?,
    )?;

    // -- getIdentity --
    /// Returns the identity string used to locate the game's save directory.
    /// @return | string | Filesystem identity string.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "getIdentity",
        lua.create_function(move |_, ()| Ok(s.borrow().filesystem_identity.clone()))?,
    )?;

    // -- setIdentity --
    /// Sets the identity string that names the game's sandboxed save-data directory.
    /// @param | name | string | New filesystem identity string.
    /// @return | nil | No return value.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "setIdentity",
        lua.create_function(move |_, name: String| {
            s.borrow_mut().filesystem_identity = name;
            Ok(())
        })?,
    )?;

    // -- lines --
    /// Returns an iterator function over the lines of a text file.
    /// @param | path | string | Virtual path to the text file.
    /// @return | function | Iterator function that returns the next line, or nil at end of file.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "lines",
        lua.create_function(move |lua, path: String| {
            let lines = s
                .borrow()
                .fs
                .read_lines(&path)
                .map_err(LuaError::external)?;
            let iter = Rc::new(RefCell::new(lines.into_iter()));
            let iter_fn = lua.create_function(move |_, ()| Ok(iter.borrow_mut().next()))?;
            Ok(iter_fn)
        })?,
    )?;

    // -- readAsync --
    /// Starts loading a file in the background and returns an opaque handle.
    /// @param | path | string | Virtual path to load asynchronously.
    /// @return | integer | Async load handle.
    let s = state.clone();
    // Auto-doc: Lua API binding.
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
    /// @param | handle | integer | Async load handle returned by `readAsync`.
    /// @return | string | Current async load status.
    /// @return | string | Loaded payload when the async read completes.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "pollAsync",
        lua.create_function(move |_, handle_id: u64| Ok(s.borrow().poll_async_load(handle_id)))?,
    )?;

    // -- writeAsync --
    /// Starts writing binary data to a file in the save sandbox and returns an opaque handle.
    /// @param | path | string | Destination path inside `save/`.
    /// @param | data | string | Binary payload to write.
    /// @return | integer | Async write handle.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "writeAsync",
        lua.create_function(move |_, (path, data): (String, LuaString)| {
            s.borrow_mut()
                .request_async_write(&path, data.as_bytes().to_vec())
                .map_err(LuaError::external)
        })?,
    )?;

    // -- pollAsyncWrite --
    /// Polls an async write handle, returning status and optional payload.
    /// @param | handle | integer | Async write handle returned by `writeAsync`.
    /// @return | string | Current async write status.
    /// @return | string | Bytes-written string when done, or error message when status is `error`.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "pollAsyncWrite",
        lua.create_function(move |_, handle_id: u64| Ok(s.borrow().poll_async_write(handle_id)))?,
    )?;

    // -- mount --
    /// Mounts a directory at a virtual path inside the game filesystem.
    /// @param | source | string | Source directory path.
    /// @param | mountpoint | string | Virtual mount point.
    /// @return | boolean | True when the mount succeeds.
    let s = state.clone();
    // Auto-doc: Lua API binding.
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
    /// @param | mountpoint | string | Virtual mount point to remove.
    /// @return | boolean | True when a mount was removed.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "unmount",
        lua.create_function(move |_, mp: String| Ok(s.borrow_mut().fs.unmount(&mp)))?,
    )?;

    // -- load --
    /// Loads and compiles a Lua file from the VFS, returning it as a callable function.
    /// @param | path | string | Virtual path to the Lua chunk.
    /// @return | function | Compiled Lua function.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "load",
        lua.create_function(move |ctx, path: String| {
            let bytes = s
                .borrow()
                .fs
                .load_chunk(&path)
                .map_err(LuaError::external)?;
            ctx.load(&bytes[..]).into_function()
        })?,
    )?;

    // -- newFileData --
    /// Loads a file from the VFS into a FileData buffer.
    /// @param | path | string | Virtual path to load.
    /// @return | LFileData | Loaded file data buffer.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "newFileData",
        lua.create_function(move |_, path: String| {
            let bytes = s
                .borrow()
                .fs
                .load_chunk(&path)
                .map_err(LuaError::external)?;
            Ok(LuaFileData {
                inner: FileData::new(path, bytes),
            })
        })?,
    )?;

    // -- copy --
    /// Copies a file within the sandbox from the game root into `save/`.
    /// @param | src | string | Source path relative to the game root.
    /// @param | dst | string | Destination path inside `save/`.
    /// @return | nil | No return value.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "copy",
        lua.create_function(move |_, (src, dst): (String, String)| {
            s.borrow()
                .fs
                .copy_file(&src, &dst)
                .map_err(LuaError::external)
        })?,
    )?;

    // -- move --
    /// Moves or renames a file within the `save/` directory.
    /// @param | src | string | Source path inside `save/`.
    /// @param | dst | string | Destination path inside `save/`.
    /// @return | nil | No return value.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "move",
        lua.create_function(move |_, (src, dst): (String, String)| {
            s.borrow()
                .fs
                .move_file(&src, &dst)
                .map_err(LuaError::external)
        })?,
    )?;

    // -- removeDir --
    /// Recursively deletes a directory and all its contents within `save/`.
    /// @param | path | string | Directory path inside `save/`.
    /// @return | nil | No return value.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "removeDir",
        lua.create_function(move |_, path: String| {
            s.borrow().fs.remove_dir(&path).map_err(LuaError::external)
        })?,
    )?;

    // -- glob --
    /// Returns a sorted list of paths matching a simple wildcard pattern.
    /// @param | pattern | string | Relative pattern where `*` matches many characters and `?` matches one character.
    /// @return | table | Array of matching relative paths.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "glob",
        lua.create_function(move |lua, pattern: String| {
            let paths = s.borrow().fs.glob(&pattern).map_err(LuaError::external)?;
            let tbl = lua.create_table()?;
            for (i, p) in paths.iter().enumerate() {
                tbl.set(i + 1, p.clone())?;
            }
            Ok(tbl)
        })?,
    )?;

    // -- listRecursive --
    /// Returns a sorted list of all files under `path`, recursively.
    /// @param | path | string | Root path to scan recursively.
    /// @return | table | Array of relative file paths using `/` separators.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "listRecursive",
        lua.create_function(move |lua, path: String| {
            let paths = s
                .borrow()
                .fs
                .list_recursive(&path)
                .map_err(LuaError::external)?;
            let result = lua.create_table()?;
            for (i, p) in paths.iter().enumerate() {
                result.set(i + 1, p.as_str())?;
            }
            Ok(result)
        })?,
    )?;

    // -- stat --
    /// Returns lightweight file statistics for the given path.
    /// @param | path | string | Virtual path to inspect.
    /// @return | table | Table with `size`, `isFile`, and `isDir` fields.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "stat",
        lua.create_function(move |lua, path: String| {
            let (size, is_file, is_dir) = s.borrow().fs.stat(&path).map_err(LuaError::external)?;
            let t = lua.create_table()?;
            t.set("size", size)?;
            t.set("isFile", is_file)?;
            t.set("isDir", is_dir)?;
            Ok(t)
        })?,
    )?;

    // -- createTempFile --
    /// Creates an empty temporary file in the `save/` sandbox and returns its relative path.
    /// @param | prefix | string | Name prefix, or nil to use `tmp`.
    /// @return | string | Relative path of the created temp file.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "createTempFile",
        lua.create_function(move |_, prefix: Option<String>| {
            let prefix = prefix.as_deref().unwrap_or("tmp");
            s.borrow()
                .fs
                .create_temp_file(prefix)
                .map_err(LuaError::external)
        })?,
    )?;

    // -- mkdir --
    /// Creates a directory and any missing parents relative to the game root.
    /// @param | path | string | Relative directory path to create.
    /// @return | nil | No return value.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "mkdir",
        lua.create_function(move |_, path: String| {
            let abs = s.borrow().fs.base_dir().join(&path);
            std::fs::create_dir_all(&abs)
                .map_err(|e| LuaError::RuntimeError(format!("mkdir '{}': {}", path, e)))
        })?,
    )?;

    // -- toAbsolutePath --
    /// Resolves a relative game path to an absolute OS path string.
    /// @param | path | string | Relative path to resolve.
    /// @return | string | Absolute OS path string.
    let s = state.clone();
    // Auto-doc: Lua API binding.
    tbl.set(
        "toAbsolutePath",
        lua.create_function(move |_, path: String| {
            let abs = s.borrow().fs.base_dir().join(&path);
            Ok(abs.to_string_lossy().to_string())
        })?,
    )?;

    lurek.set("filesystem", tbl)?;
    Ok(())
}
