use super::SharedState;
use crate::filesystem::file_handle::{FileHandle, FileMode};
use crate::filesystem::{GameFS, LoadStatus};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

/// Wrapper for FileHandle that can be shared as Lua userdata.
struct LuaFileHandle {
    inner: RefCell<FileHandle>,
}

impl LuaUserData for LuaFileHandle {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Reads a text file and returns its contents as a string.
        methods.add_method("read", |_, this, count: Option<usize>| {
            let mut handle = this.inner.borrow_mut();
            let bytes = handle
                .read(count)
                .map_err(|e| LuaError::RuntimeError(format!("FileHandle:read: {}", e)))?;
            Ok(String::from_utf8_lossy(&bytes).to_string())
        });

        /// Reads the next line of text from the file and returns it as a string.
        ///
        /// # Returns
        /// The line string (without newline), or nil at end of file.
        methods.add_method("readLine", |_, this, ()| {
            let mut handle = this.inner.borrow_mut();
            let line = handle
                .read_line()
                .map_err(|e| LuaError::RuntimeError(format!("FileHandle:readLine: {}", e)))?;
            Ok(line)
        });

        /// Writes a string to a file, creating it if needed.
        methods.add_method("write", |_, this, data: String| {
            let mut handle = this.inner.borrow_mut();
            let written = handle
                .write(data.as_bytes())
                .map_err(|e| LuaError::RuntimeError(format!("FileHandle:write: {}", e)))?;
            Ok(written)
        });

        /// Seeks the file position to the given byte offset from the start.
        ///
        /// # Parameters
        /// - `offset` — Byte position to seek to (0-based).
        ///
        /// # Returns
        /// The new byte position, or nil plus an error string on failure.
        methods.add_method("seek", |_, this, pos: u64| {
            let mut handle = this.inner.borrow_mut();
            let new_pos = handle
                .seek(pos)
                .map_err(|e| LuaError::RuntimeError(format!("FileHandle:seek: {}", e)))?;
            Ok(new_pos)
        });

        /// Returns the current read/write byte offset from the start of the file.
        ///
        /// # Returns
        /// Current byte offset as an integer.
        methods.add_method("tell", |_, this, ()| {
            let mut handle = this.inner.borrow_mut();
            let pos = handle
                .tell()
                .map_err(|e| LuaError::RuntimeError(format!("FileHandle:tell: {}", e)))?;
            Ok(pos)
        });

        /// Returns the size of the open file in bytes.
        ///
        /// # Returns
        /// File size as an integer number of bytes.
        methods.add_method("getSize", |_, this, ()| {
            let handle = this.inner.borrow();
            Ok(handle.get_size())
        });

        /// Returns the access mode the file was opened with.
        ///
        /// # Returns
        /// One of 'r' (read), 'w' (write), or 'a' (append).
        methods.add_method("getMode", |_, this, ()| {
            let handle = this.inner.borrow();
            Ok(handle.get_mode().as_str().to_string())
        });

        /// Flushes all buffered writes to disk without closing the handle.
        ///
        /// # Returns
        /// true on success, or nil plus an error string on failure.
        methods.add_method("flush", |_, this, ()| {
            let mut handle = this.inner.borrow_mut();
            handle
                .flush()
                .map_err(|e| LuaError::RuntimeError(format!("FileHandle:flush: {}", e)))
        });

        /// Flushes any pending writes and closes the file handle.
        ///
        /// # Returns
        /// true on success, or nil plus an error string on failure.
        methods.add_method("close", |_, this, ()| {
            let mut handle = this.inner.borrow_mut();
            handle
                .close()
                .map_err(|e| LuaError::RuntimeError(format!("FileHandle:close: {}", e)))
        });

        /// Returns whether the read cursor has reached the end of the file.
        ///
        /// # Returns
        /// true if at end-of-file, false otherwise.
        methods.add_method("isEOF", |_, this, ()| {
            let mut handle = this.inner.borrow_mut();
            handle
                .is_eof()
                .map_err(|e| LuaError::RuntimeError(format!("FileHandle:isEOF: {}", e)))
        });
    }
}

/// Registers `luna.filesystem.*` functions into the Lua VM.
///
/// # Parameters
/// - `lua` — the active Lua VM
/// - `luna` — the top-level `luna` table to attach `luna.filesystem` to
/// - `state` — shared engine state providing the sandboxed `GameFS`
///
/// # Returns
/// `Ok(())` on success, or a `LuaError` if registration fails.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let fs = lua.create_table()?;

    // luna.filesystem.read(path) -> string
    /// Reads a text file and returns its contents as a string.
    let s = state.clone();
    fs.set(
        "read",
        lua.create_function(move |_, path: String| {
            let st = s.borrow();
            let game_fs = GameFS::new(&st.game_dir);
            match game_fs.read_string(&path) {
                Ok(content) => Ok(content),
                Err(e) => Err(LuaError::RuntimeError(format!(
                    "luna.filesystem.read: {}",
                    e
                ))),
            }
        })?,
    )?;

    // luna.filesystem.write(path, data) - writes to save/ directory only
    /// Writes a string to a file, creating it if needed.
    let s = state.clone();
    fs.set(
        "write",
        lua.create_function(move |_, (path, data): (String, String)| {
            let st = s.borrow();
            let game_fs = GameFS::new(&st.game_dir);
            match game_fs.write_string(&path, &data) {
                Ok(()) => Ok(()),
                Err(e) => Err(LuaError::RuntimeError(format!(
                    "luna.filesystem.write: {}",
                    e
                ))),
            }
        })?,
    )?;

    // luna.filesystem.exists(path) -> bool
    /// Returns whether the given file or directory exists.
    let s = state.clone();
    fs.set(
        "exists",
        lua.create_function(move |_, path: String| {
            let st = s.borrow();
            let game_fs = GameFS::new(&st.game_dir);
            Ok(game_fs.exists(&path))
        })?,
    )?;

    // luna.filesystem.append(path, data) - appends to file in save/ directory
    /// Opens the file in append mode and writes the given string at the end.
    ///
    /// # Parameters
    /// - `path` — Relative file path inside the save directory.
    /// - `data` — String to append.
    ///
    /// # Returns
    /// true on success, or nil plus an error string on failure.
    let s = state.clone();
    fs.set(
        "append",
        lua.create_function(move |_, (path, data): (String, String)| {
            let st = s.borrow();
            let game_fs = GameFS::new(&st.game_dir);
            game_fs
                .append_string(&path, &data)
                .map_err(|e| LuaError::RuntimeError(format!("luna.filesystem.append: {}", e)))
        })?,
    )?;

    // luna.filesystem.openFile(path, mode) -> FileHandle userdata
    /// Opens a file and returns a readable/writable file handle.
    let s = state.clone();
    fs.set(
        "openFile",
        lua.create_function(move |_, (path, mode_str): (String, String)| {
            let st = s.borrow();
            let game_fs = GameFS::new(&st.game_dir);
            let mode = FileMode::parse_mode(&mode_str)
                .map_err(|e| LuaError::RuntimeError(format!("luna.filesystem.openFile: {}", e)))?;
            let handle = FileHandle::open(&game_fs, &path, mode)
                .map_err(|e| LuaError::RuntimeError(format!("luna.filesystem.openFile: {}", e)))?;
            Ok(LuaFileHandle {
                inner: RefCell::new(handle),
            })
        })?,
    )?;

    // luna.filesystem.getDirectoryItems(path) -> table
    /// Returns a table containing the names of every file and subdirectory in the given path.
    ///
    /// # Parameters
    /// - `path` — Directory path to list.
    ///
    /// # Returns
    /// Table of file and directory name strings.
    let s = state.clone();
    fs.set(
        "getDirectoryItems",
        lua.create_function(move |_, path: String| {
            let st = s.borrow();
            let game_fs = GameFS::new(&st.game_dir);
            let items = game_fs.get_directory_items(&path).map_err(|e| {
                LuaError::RuntimeError(format!("luna.filesystem.getDirectoryItems: {}", e))
            })?;
            Ok(items)
        })?,
    )?;

    // luna.filesystem.isFile(path) -> bool
    /// Returns whether the given path is a regular file.
    let s = state.clone();
    fs.set(
        "isFile",
        lua.create_function(move |_, path: String| {
            let st = s.borrow();
            let game_fs = GameFS::new(&st.game_dir);
            Ok(game_fs.is_file(&path))
        })?,
    )?;

    // luna.filesystem.isDirectory(path) -> bool
    /// Returns whether the given path is a directory.
    let s = state.clone();
    fs.set(
        "isDirectory",
        lua.create_function(move |_, path: String| {
            let st = s.borrow();
            let game_fs = GameFS::new(&st.game_dir);
            Ok(game_fs.is_directory(&path))
        })?,
    )?;

    // luna.filesystem.createDirectory(path) - save area only
    /// Creates a directory and any missing parent directories.
    let s = state.clone();
    fs.set(
        "createDirectory",
        lua.create_function(move |_, path: String| {
            let st = s.borrow();
            let game_fs = GameFS::new(&st.game_dir);
            game_fs.create_directory(&path).map_err(|e| {
                LuaError::RuntimeError(format!("luna.filesystem.createDirectory: {}", e))
            })
        })?,
    )?;

    // luna.filesystem.remove(path) - save area only
    /// Permanently deletes the file at the given path from the save directory.
    ///
    /// # Parameters
    /// - `path` — Relative path to the file to delete.
    ///
    /// # Returns
    /// true on success, or nil plus an error string on failure.
    let s = state.clone();
    fs.set(
        "remove",
        lua.create_function(move |_, path: String| {
            let st = s.borrow();
            let game_fs = GameFS::new(&st.game_dir);
            game_fs
                .remove(&path)
                .map_err(|e| LuaError::RuntimeError(format!("luna.filesystem.remove: {}", e)))
        })?,
    )?;

    // luna.filesystem.getInfo(path) -> table {type, size, modtime, readonly}
    /// Returns a table of metadata (size, modtime, kind) for a path.
    let s = state.clone();
    fs.set(
        "getInfo",
        lua.create_function(move |lua, path: String| {
            let st = s.borrow();
            let game_fs = GameFS::new(&st.game_dir);
            match game_fs.get_info(&path) {
                Ok(info) => {
                    let tbl = lua.create_table()?;
                    /// Type.
                    tbl.set(
                        "type",
                        match info.file_type {
                            crate::filesystem::FileType::File => "file",
                            crate::filesystem::FileType::Directory => "directory",
                            crate::filesystem::FileType::Symlink => "symlink",
                            crate::filesystem::FileType::Other => "other",
                        },
                    )?;
                    /// Size.
                    tbl.set("size", info.size)?;
                    /// Modtime.
                    tbl.set("modtime", info.modified_time)?;
                    /// Readonly.
                    tbl.set("readonly", info.readonly)?;
                    Ok(mlua::Value::Table(tbl))
                }
                Err(_) => Ok(mlua::Value::Nil),
            }
        })?,
    )?;

    // luna.filesystem.getSource() -> string
    /// Returns the absolute path of the directory or archive the game was loaded from.
    ///
    /// # Returns
    /// Source path string, or nil if not set.
    let s = state.clone();
    fs.set(
        "getSource",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            let game_fs = GameFS::new(&st.game_dir);
            Ok(game_fs.get_source())
        })?,
    )?;

    // luna.filesystem.getSaveDirectory() -> string
    /// Returns the sandboxed save data directory path.
    let s = state.clone();
    fs.set(
        "getSaveDirectory",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            let game_fs = GameFS::new(&st.game_dir);
            Ok(game_fs.get_save_directory().to_string_lossy().to_string())
        })?,
    )?;

    // luna.filesystem.getWorkingDirectory() -> string
    /// Returns the current working directory path.
    fs.set(
        "getWorkingDirectory",
        lua.create_function(move |_, ()| {
            GameFS::get_working_directory().map_err(|e| {
                LuaError::RuntimeError(format!("luna.filesystem.getWorkingDirectory: {}", e))
            })
        })?,
    )?;

    // luna.filesystem.getUserDirectory() -> string
    /// Returns the current user's home directory path.
    fs.set(
        "getUserDirectory",
        lua.create_function(move |_, ()| Ok(GameFS::get_user_directory()))?,
    )?;

    // luna.filesystem.getIdentity() -> string
    /// Returns the identity string used to locate the game's sandboxed save directory.
    ///
    /// # Returns
    /// Identity string, or nil if not yet set.
    let s = state.clone();
    fs.set(
        "getIdentity",
        lua.create_function(move |_, ()| {
            let st = s.borrow();
            Ok(st.filesystem_identity.clone())
        })?,
    )?;

    // luna.filesystem.setIdentity(name)
    /// Sets the identity string that names the game's sandboxed save-data directory.
    ///
    /// # Parameters
    /// - `name` — Application identity string (e.g. 'mygame').
    let s = state.clone();
    fs.set(
        "setIdentity",
        lua.create_function(move |_, name: String| {
            let mut st = s.borrow_mut();
            st.filesystem_identity = name;
            Ok(())
        })?,
    )?;

    // luna.filesystem.lines(path) -> iterator function
    /// Returns an iterator over lines in a text file.
    let s = state.clone();
    fs.set(
        "lines",
        lua.create_function(move |lua, path: String| {
            let st = s.borrow();
            let game_fs = GameFS::new(&st.game_dir);
            let content = game_fs
                .read_string(&path)
                .map_err(|e| LuaError::RuntimeError(format!("luna.filesystem.lines: {}", e)))?;
            let lines: Vec<String> = content.lines().map(|l| l.to_string()).collect();
            let lines = Rc::new(RefCell::new(lines.into_iter()));
            let iter_fn = lua.create_function(move |_, ()| {
                let next = lines.borrow_mut().next();
                Ok(next)
            })?;
            Ok(iter_fn)
        })?,
    )?;

    // -----------------------------------------------------------------------
    // Async asset loading
    // -----------------------------------------------------------------------

    #[allow(unused_doc_comments)]
    /// Start loading a file in the background. Returns a numeric handle.
    // luna.filesystem.readAsync(path)
    let s = state.clone();
    fs.set(
        "readAsync",
        lua.create_function(move |_, path: String| {
            let mut st = s.borrow_mut();
            let game_fs = GameFS::new(&st.game_dir);
            let resolved = game_fs
                .resolve_read_path(&path)
                .map_err(|e| LuaError::RuntimeError(format!("luna.filesystem.readAsync: {}", e)))?;
            // Lazily create the async loader on first use.
            if st.async_loader.is_none() {
                st.async_loader = Some(crate::filesystem::AsyncLoader::new());
            }
            let handle = st.async_loader.as_ref().unwrap().request_load(resolved);
            Ok(handle.0)
        })?,
    )?;

    #[allow(unused_doc_comments)]
    /// Poll an async load handle. Returns status, data-or-nil.
    /// Status is "pending", "done", or "error".
    // luna.filesystem.pollAsync(handle)
    let s = state.clone();
    fs.set(
        "pollAsync",
        lua.create_function(move |lua, handle_id: u64| {
            let st = s.borrow();
            if let Some(ref loader) = st.async_loader {
                let handle = crate::filesystem::LoadHandle(handle_id);
                match loader.poll(handle) {
                    LoadStatus::Pending => Ok(("pending".to_string(), mlua::Value::Nil)),
                    LoadStatus::Done(crate::filesystem::LoadResult::Ready(bytes)) => {
                        let text = String::from_utf8_lossy(&bytes).to_string();
                        let lua_str = lua.create_string(&text)?;
                        Ok(("done".to_string(), mlua::Value::String(lua_str)))
                    }
                    LoadStatus::Done(crate::filesystem::LoadResult::Error(msg)) => {
                        let lua_str = lua.create_string(&msg)?;
                        Ok(("error".to_string(), mlua::Value::String(lua_str)))
                    }
                }
            } else {
                Ok(("error".to_string(), mlua::Value::Nil))
            }
        })?,
    )?;

    /// Filesystem.
    luna.set("filesystem", fs)?;
    Ok(())
}
