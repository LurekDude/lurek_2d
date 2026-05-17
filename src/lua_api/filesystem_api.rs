//! `lurek.filesystem` -- GameFS bindings for text, binary, JSON, directory, metadata, async IO, mount, ZIP archive, file handle, file data, watcher, path conversion, and script chunk loading operations available to Lua.

use super::SharedState;
use crate::filesystem::watcher::FileWatcher;
use crate::filesystem::zip_mount::ZipMount;
use crate::filesystem::{FileData, FileHandle, GameFS};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
/// Lua-side handle for immutable file bytes and their source path.
pub struct LuaFileData {
    /// File path and loaded byte buffer.
    inner: FileData,
}
/// Provides Lua methods for inspecting loaded file data.
impl LuaUserData for LuaFileData {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getSize --
        /// Returns the byte length of this file data.
        /// @return | integer | File data size in bytes.
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.len() as i64));
        // -- getString --
        /// Returns file data bytes as a Lua string without UTF-8 validation.
        /// @return | string | Lua string containing the raw file bytes.
        methods.add_method("getString", |lua, this, ()| {
            lua.create_string(&this.inner.bytes)
        });
        // -- getFilename --
        /// Returns the path associated with this file data object.
        /// @return | string | Original file path.
        methods.add_method("getFilename", |_, this, ()| Ok(this.inner.path.clone()));
        // -- type --
        /// Returns the Lua-visible type name for this file data handle.
        /// @return | string | The string `LFileData`.
        methods.add_method("type", |_, _, ()| Ok("LFileData"));
        // -- typeOf --
        /// Returns whether this file data handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LFileData` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LFileData" || name == "Object")
        });
    }
}
/// Lua-side handle for a mutable file stream opened through GameFS.
pub struct LuaFileHandle {
    /// RefCell-wrapped file handle so Lua methods can read, write, seek, and close it.
    inner: RefCell<FileHandle>,
}
/// Provides Lua methods for stream-style file access.
impl LuaUserData for LuaFileHandle {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- read --
        /// Reads up to an optional byte count and returns text using lossless UTF-8 replacement.
        /// @param | count? | integer | Optional maximum number of bytes to read.
        /// @return | string | String decoded from the bytes that were read.
        methods.add_method("read", |_, this, count: Option<usize>| {
            let bytes = this
                .inner
                .borrow_mut()
                .read(count)
                .map_err(LuaError::external)?;
            Ok(String::from_utf8_lossy(&bytes).to_string())
        });
        // -- readLine --
        /// Reads the next line from this file handle.
        /// @return | string | Line string when available, or nil at EOF.
        methods.add_method("readLine", |_, this, ()| {
            this.inner
                .borrow_mut()
                .read_line()
                .map_err(LuaError::external)
        });
        // -- write --
        /// Writes a string to this file handle.
        /// @param | data | string | Text bytes to write.
        /// @return | nil | No value is returned.
        methods.add_method("write", |_, this, data: String| {
            this.inner
                .borrow_mut()
                .write(data.as_bytes())
                .map_err(LuaError::external)
        });
        // -- seek --
        /// Moves the file cursor to an absolute byte position.
        /// @param | pos | integer | Absolute byte offset.
        /// @return | nil | No value is returned.
        methods.add_method("seek", |_, this, pos: u64| {
            this.inner
                .borrow_mut()
                .seek(pos)
                .map_err(LuaError::external)
        });
        // -- tell --
        /// Returns the current file cursor position.
        /// @return | integer | Current absolute byte offset.
        methods.add_method("tell", |_, this, ()| {
            this.inner.borrow_mut().tell().map_err(LuaError::external)
        });
        // -- getSize --
        /// Returns the size of the open file.
        /// @return | integer | File size in bytes.
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.borrow().get_size()));
        // -- getMode --
        /// Returns the mode used to open this file handle.
        /// @return | string | File mode string.
        methods.add_method("getMode", |_, this, ()| {
            Ok(this.inner.borrow().get_mode().as_str().to_string())
        });
        // -- flush --
        /// Flushes pending writes on this file handle.
        /// @return | nil | No value is returned.
        methods.add_method("flush", |_, this, ()| {
            this.inner.borrow_mut().flush().map_err(LuaError::external)
        });
        // -- close --
        /// Closes this file handle on this object.
        /// @return | nil | No value is returned.
        methods.add_method("close", |_, this, ()| {
            this.inner.borrow_mut().close().map_err(LuaError::external)
        });
        // -- isEOF --
        /// Returns whether the file cursor is at end of file.
        /// @return | boolean | True when no more bytes remain.
        methods.add_method("isEOF", |_, this, ()| {
            this.inner.borrow_mut().is_eof().map_err(LuaError::external)
        });
        // -- type --
        /// Returns the Lua-visible type name for this file handle.
        /// @return | string | The string `LFileHandle`.
        methods.add_method("type", |_, _, ()| Ok("LFileHandle"));
        // -- typeOf --
        /// Returns whether this file handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LFileHandle` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LFileHandle" || name == "Object")
        });
    }
}
/// Lua-side handle for a mounted ZIP archive view.
struct LuaZipMount {
    /// ZIP mount index and virtual prefix.
    inner: ZipMount,
}
/// Provides Lua methods for reading files inside a ZIP mount.
impl LuaUserData for LuaZipMount {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- readFile --
        /// Reads a file from the ZIP mount by virtual path.
        /// @param | virtual_path | string | Path inside the mount prefix.
        /// @return | string | Raw file bytes as a Lua string.
        methods.add_method("readFile", |_, this, virtual_path: String| {
            let bytes = this
                .inner
                .read_file(&virtual_path)
                .map_err(LuaError::RuntimeError)?;
            Ok(bytes)
        });
        // -- contains --
        /// Returns whether a virtual path exists in the ZIP mount.
        /// @param | virtual_path | string | Path inside the mount prefix.
        /// @return | boolean | True when the file exists in the archive.
        methods.add_method("contains", |_, this, virtual_path: String| {
            Ok(this.inner.contains(&virtual_path))
        });
        // -- listFiles --
        /// Returns every virtual file path in the ZIP mount.
        /// @return | table | Array table of mounted file paths.
        methods.add_method("listFiles", |lua, this, ()| {
            let files = this.inner.list_files();
            let tbl = lua.create_table()?;
            for (i, f) in files.iter().enumerate() {
                tbl.set(i + 1, f.clone())?;
            }
            Ok(tbl)
        });
        // -- prefix --
        /// Returns the virtual prefix used by this ZIP mount.
        /// @return | string | Mount prefix.
        methods.add_method("prefix", |_, this, ()| Ok(this.inner.prefix.clone()));
        // -- type --
        /// Returns the Lua-visible type name for this ZIP mount handle.
        /// @return | string | The string `LZipMount`.
        methods.add_method("type", |_, _, ()| Ok("LZipMount"));
        // -- typeOf --
        /// Returns whether this ZIP mount handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LZipMount` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LZipMount" || name == "Object")
        });
    }
}
/// Registers `lurek.filesystem` file, directory, watcher, mount, async, and path helpers.
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    // -- mountZip --
    /// Opens a ZIP archive and exposes it through a virtual prefix.
    /// @param | archive_path | string | Archive path on disk.
    /// @param | prefix | string | Virtual path prefix for archive contents.
    /// @return | LZipMount | New ZIP mount handle.
    tbl.set(
        "mountZip",
        lua.create_function(|lua, (archive_path, prefix): (String, String)| {
            let mount = ZipMount::new(&archive_path, &prefix).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaZipMount { inner: mount })
        })?,
    )?;
    let watcher_rc = Rc::new(RefCell::new(FileWatcher::new()));
    let wrc = watcher_rc.clone();
    // -- watchPath --
    /// Adds a path to the module-local file watcher.
    /// @param | path | string | Path to watch for changes.
    tbl.set(
        "watchPath",
        lua.create_function(move |_, path: String| {
            wrc.borrow_mut().watch(&path);
            Ok(())
        })?,
    )?;
    let wrc = watcher_rc.clone();
    // -- unwatchPath --
    /// Removes a path from the module-local file watcher.
    /// @param | path | string | Watched path to remove.
    tbl.set(
        "unwatchPath",
        lua.create_function(move |_, path: String| {
            wrc.borrow_mut().unwatch(&path);
            Ok(())
        })?,
    )?;
    let wrc = watcher_rc.clone();
    // -- pollWatchers --
    /// Polls watched paths and returns paths that changed since the previous poll.
    /// @return | table | Array table of changed path strings.
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
    let s = state.clone();
    // -- read --
    /// Reads a UTF-8 text file from GameFS.
    /// @param | path | string | GameFS path to read.
    /// @return | string | File contents as text.
    tbl.set(
        "read",
        lua.create_function(move |_, path: String| {
            s.borrow().fs.read_string(&path).map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    // -- write --
    /// Writes a UTF-8 text file through GameFS.
    /// @param | path | string | GameFS path to write.
    /// @param | data | string | Text contents.
    tbl.set(
        "write",
        lua.create_function(move |_, (path, data): (String, String)| {
            s.borrow()
                .fs
                .write_string(&path, &data)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    // -- readJson --
    /// Reads a JSON document as text from GameFS.
    /// @param | path | string | GameFS path to read.
    /// @return | string | JSON text.
    tbl.set(
        "readJson",
        lua.create_function(move |_, path: String| {
            s.borrow().fs.read_json(&path).map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    // -- writeJson --
    /// Writes JSON text through GameFS.
    /// @param | path | string | GameFS path to write.
    /// @param | json | string | JSON text to store.
    tbl.set(
        "writeJson",
        lua.create_function(move |_, (path, json): (String, String)| {
            s.borrow()
                .fs
                .write_json(&path, &json)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    // -- readOrWriteJson --
    /// Reads a JSON file or writes and returns default JSON when the file is absent.
    /// @param | path | string | GameFS path to read.
    /// @param | default_json | string | JSON text written when the path does not exist.
    /// @return | string | Existing or newly written JSON text.
    tbl.set(
        "readOrWriteJson",
        lua.create_function(move |_, (path, default_json): (String, String)| {
            s.borrow()
                .fs
                .read_or_write_json(&path, &default_json)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    // -- readBytes --
    /// Reads a binary file from GameFS and returns the bytes as a Lua string.
    /// @param | path | string | GameFS path to read.
    /// @return | string | Raw file bytes.
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
    let s = state.clone();
    // -- writeBytes --
    /// Writes binary data through GameFS.
    /// @param | path | string | GameFS path to write.
    /// @param | data | string | Raw bytes stored in a Lua string.
    tbl.set(
        "writeBytes",
        lua.create_function(move |_, (path, data): (String, LuaString)| {
            s.borrow()
                .fs
                .write_bytes(&path, data.as_bytes().as_ref())
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    // -- exists --
    /// Returns whether a path exists in GameFS.
    /// @param | path | string | GameFS path to check.
    /// @return | boolean | True when the path exists.
    tbl.set(
        "exists",
        lua.create_function(move |_, path: String| Ok(s.borrow().fs.exists(&path)))?,
    )?;
    let s = state.clone();
    // -- append --
    /// Appends UTF-8 text to a GameFS file.
    /// @param | path | string | GameFS path to append to.
    /// @param | data | string | Text to append.
    tbl.set(
        "append",
        lua.create_function(move |_, (path, data): (String, String)| {
            s.borrow()
                .fs
                .append_string(&path, &data)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    // -- openFile --
    /// Opens a GameFS file handle in a requested mode.
    /// @param | path | string | GameFS path to open.
    /// @param | mode | string | File mode understood by GameFS.
    /// @return | LFileHandle | Open file handle.
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
    let s = state.clone();
    // -- getDirectoryItems --
    /// Lists immediate entries in a GameFS directory.
    /// @param | path | string | Directory path to list.
    /// @return | table | Array table of entry names.
    tbl.set(
        "getDirectoryItems",
        lua.create_function(move |_, path: String| {
            s.borrow()
                .fs
                .get_directory_items(&path)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    // -- isFile --
    /// Returns whether a GameFS path is a regular file.
    /// @param | path | string | GameFS path to check.
    /// @return | boolean | True when the path is a file.
    tbl.set(
        "isFile",
        lua.create_function(move |_, path: String| Ok(s.borrow().fs.is_file(&path)))?,
    )?;
    let s = state.clone();
    // -- isDirectory --
    /// Returns whether a GameFS path is a directory.
    /// @param | path | string | GameFS path to check.
    /// @return | boolean | True when the path is a directory.
    tbl.set(
        "isDirectory",
        lua.create_function(move |_, path: String| Ok(s.borrow().fs.is_directory(&path)))?,
    )?;
    let s = state.clone();
    // -- createDirectory --
    /// Creates a GameFS directory and any missing parents.
    /// @param | path | string | Directory path to create.
    tbl.set(
        "createDirectory",
        lua.create_function(move |_, path: String| {
            s.borrow()
                .fs
                .create_directory(&path)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    // -- remove --
    /// Removes a GameFS file or supported path.
    /// @param | path | string | Path to remove.
    tbl.set(
        "remove",
        lua.create_function(move |_, path: String| {
            s.borrow().fs.remove(&path).map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    // -- getInfo --
    /// Returns file metadata for a GameFS path when available.
    /// @param | path | string | GameFS path to inspect.
    /// @return | table | Metadata table with type, size, modtime, and readonly fields, or nil on error.
    tbl.set(
        "getInfo",
        lua.create_function(
            move |lua, path: String| match s.borrow().fs.get_info(&path) {
                Ok(info) => {
                    let t = lua.create_table()?;
                    /// Performs the 'type' operation.
                    /// @return | nil | No value is returned.
                    t.set("type", info.file_type.as_str())?;
                    /// Performs the 'size' operation.
                    /// @return | nil | No value is returned.
                    t.set("size", info.size)?;
                    /// Performs the 'modtime' operation.
                    /// @return | nil | No value is returned.
                    t.set("modtime", info.modified_time)?;
                    /// Performs the 'readonly' operation.
                    /// @return | nil | No value is returned.
                    t.set("readonly", info.readonly)?;
                    Ok(Some(t))
                }
                Err(_) => Ok(None),
            },
        )?,
    )?;
    let s = state.clone();
    // -- getSource --
    /// Returns the GameFS source root string.
    /// @return | string | Source directory or source description.
    tbl.set(
        "getSource",
        lua.create_function(move |_, ()| Ok(s.borrow().fs.get_source()))?,
    )?;
    let s = state.clone();
    // -- getSaveDirectory --
    /// Returns the save directory path used by GameFS.
    /// @return | string | Save directory path.
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
    /// Returns the process working directory.
    /// @return | string | Working directory path.
    tbl.set(
        "getWorkingDirectory",
        lua.create_function(move |_, ()| {
            GameFS::get_working_directory().map_err(LuaError::external)
        })?,
    )?;
    // -- getUserDirectory --
    /// Returns the current user's directory path.
    /// @return | string | User directory path.
    tbl.set(
        "getUserDirectory",
        lua.create_function(move |_, ()| Ok(GameFS::get_user_directory()))?,
    )?;
    let s = state.clone();
    // -- getIdentity --
    /// Returns the current filesystem identity string.
    /// @return | string | Filesystem identity used for save namespacing.
    tbl.set(
        "getIdentity",
        lua.create_function(move |_, ()| Ok(s.borrow().filesystem_identity.clone()))?,
    )?;
    let s = state.clone();
    // -- setIdentity --
    /// Sets the filesystem identity string used by save paths.
    /// @param | name | string | New filesystem identity.
    tbl.set(
        "setIdentity",
        lua.create_function(move |_, name: String| {
            s.borrow_mut().filesystem_identity = name;
            Ok(())
        })?,
    )?;
    let s = state.clone();
    // -- lines --
    /// Creates an iterator function over lines in a text file.
    /// @param | path | string | GameFS path to read.
    /// @return | function | Iterator returning the next line string or nil at EOF.
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
    let s = state.clone();
    // -- readAsync --
    /// Starts an asynchronous file load request.
    /// @param | path | string | GameFS path to read asynchronously.
    /// @return | integer | Async load handle id.
    tbl.set(
        "readAsync",
        lua.create_function(move |_, path: String| {
            s.borrow_mut()
                .request_async_load(&path)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    // -- pollAsync --
    /// Polls an asynchronous file load request.
    /// @param | handle_id | integer | Async load handle id.
    /// @return | any | Completed bytes/result, pending marker, or nil depending on async state.
    tbl.set(
        "pollAsync",
        lua.create_function(move |_, handle_id: u64| Ok(s.borrow().poll_async_load(handle_id)))?,
    )?;
    let s = state.clone();
    // -- writeAsync --
    /// Starts an asynchronous file write request.
    /// @param | path | string | GameFS path to write.
    /// @param | data | string | Raw bytes stored in a Lua string.
    /// @return | integer | Async write handle id.
    tbl.set(
        "writeAsync",
        lua.create_function(move |_, (path, data): (String, LuaString)| {
            s.borrow_mut()
                .request_async_write(&path, data.as_bytes().to_vec())
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    // -- pollAsyncWrite --
    /// Polls an asynchronous file write request.
    /// @param | handle_id | integer | Async write handle id.
    /// @return | any | Completed status, pending marker, or nil depending on async state.
    tbl.set(
        "pollAsyncWrite",
        lua.create_function(move |_, handle_id: u64| Ok(s.borrow().poll_async_write(handle_id)))?,
    )?;
    let s = state.clone();
    // -- mount --
    /// Mounts an external source path at a GameFS mount point.
    /// @param | src | string | Source path to mount.
    /// @param | mp | string | Virtual mount point.
    /// @return | boolean | True when the mount succeeds.
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
    let s = state.clone();
    // -- unmount --
    /// Removes a GameFS mount point.
    /// @param | mp | string | Virtual mount point to remove.
    /// @return | boolean | True when a mount was removed.
    tbl.set(
        "unmount",
        lua.create_function(move |_, mp: String| Ok(s.borrow_mut().fs.unmount(&mp)))?,
    )?;
    let s = state.clone();
    // -- load --
    /// Loads a Lua chunk from GameFS and returns it as a Lua function.
    /// @param | path | string | GameFS path to a Lua script chunk.
    /// @return | function | Compiled Lua chunk function.
    tbl.set(
        "load",
        lua.create_function(move |ctx, path: String| {
            let bytes = s
                .borrow()
                .fs
                .load_chunk(&path)
                .map_err(LuaError::external)?;
            // LUA-EVAL-JUSTIFIED: filesystem.load compiles a script file explicitly requested by Lua code.
            ctx.load(&bytes[..]).into_function()
        })?,
    )?;
    let s = state.clone();
    // -- newFileData --
    /// Loads a file into an immutable file data handle.
    /// @param | path | string | GameFS path to load.
    /// @return | LFileData | New file data handle containing path and bytes.
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
    let s = state.clone();
    // -- copy --
    /// Copies one GameFS file to another path.
    /// @param | src | string | Source path.
    /// @param | dst | string | Destination path.
    tbl.set(
        "copy",
        lua.create_function(move |_, (src, dst): (String, String)| {
            s.borrow()
                .fs
                .copy_file(&src, &dst)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    // -- move --
    /// Moves or renames one GameFS file to another path.
    /// @param | src | string | Source path.
    /// @param | dst | string | Destination path.
    tbl.set(
        "move",
        lua.create_function(move |_, (src, dst): (String, String)| {
            s.borrow()
                .fs
                .move_file(&src, &dst)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    // -- removeDir --
    /// Removes a GameFS directory.
    /// @param | path | string | Directory path to remove.
    tbl.set(
        "removeDir",
        lua.create_function(move |_, path: String| {
            s.borrow().fs.remove_dir(&path).map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    // -- glob --
    /// Returns GameFS paths matching a glob pattern.
    /// @param | pattern | string | Glob pattern.
    /// @return | table | Array table of matching path strings.
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
    let s = state.clone();
    // -- listRecursive --
    /// Lists all paths under a GameFS directory recursively.
    /// @param | path | string | Root directory path.
    /// @return | table | Array table of path strings.
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
    let s = state.clone();
    // -- stat --
    /// Returns size and file/directory flags for a GameFS path.
    /// @param | path | string | Path to inspect.
    /// @return | table | Table with `size`, `isFile`, and `isDir` fields.
    tbl.set(
        "stat",
        lua.create_function(move |lua, path: String| {
            let (size, is_file, is_dir) = s.borrow().fs.stat(&path).map_err(LuaError::external)?;
            let t = lua.create_table()?;
            /// Performs the 'size' operation.
            /// @return | nil | No value is returned.
            t.set("size", size)?;
            /// Performs the 'isFile' operation.
            /// @return | nil | No value is returned.
            t.set("isFile", is_file)?;
            /// Performs the 'isDir' operation.
            /// @return | nil | No value is returned.
            t.set("isDir", is_dir)?;
            Ok(t)
        })?,
    )?;
    let s = state.clone();
    // -- createTempFile --
    /// Creates a temporary file through GameFS.
    /// @param | prefix? | string | Optional filename prefix, defaulting to `tmp`.
    /// @return | string | Created temporary file path.
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
    let s = state.clone();
    // -- mkdir --
    /// Creates a directory under the GameFS base directory.
    /// @param | path | string | Relative directory path to create.
    tbl.set(
        "mkdir",
        lua.create_function(move |_, path: String| {
            let abs = s.borrow().fs.base_dir().join(&path);
            std::fs::create_dir_all(&abs)
                .map_err(|e| LuaError::RuntimeError(format!("mkdir '{}': {}", path, e)))
        })?,
    )?;
    let s = state.clone();
    // -- toAbsolutePath --
    /// Resolves a GameFS-relative path against the filesystem base directory.
    /// @param | path | string | Relative path to resolve.
    /// @return | string | Absolute filesystem path string.
    tbl.set(
        "toAbsolutePath",
        lua.create_function(move |_, path: String| {
            let abs = s.borrow().fs.base_dir().join(&path);
            Ok(abs.to_string_lossy().to_string())
        })?,
    )?;
    /// Performs the 'filesystem' operation.
    /// @return | nil | No value is returned.
    lurek.set("filesystem", tbl)?;
    Ok(())
}
