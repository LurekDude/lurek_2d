use super::SharedState;
use crate::filesystem::watcher::FileWatcher;
use crate::filesystem::zip_mount::ZipMount;
use crate::filesystem::{FileData, FileHandle, GameFS};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
pub struct LuaFileData {
    inner: FileData,
}
impl LuaUserData for LuaFileData {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.len() as i64));
        methods.add_method("getString", |lua, this, ()| {
            lua.create_string(&this.inner.bytes)
        });
        methods.add_method("getFilename", |_, this, ()| Ok(this.inner.path.clone()));
        methods.add_method("type", |_, _, ()| Ok("LFileData"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LFileData" || name == "Object")
        });
    }
}
pub struct LuaFileHandle {
    inner: RefCell<FileHandle>,
}
impl LuaUserData for LuaFileHandle {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("read", |_, this, count: Option<usize>| {
            let bytes = this
                .inner
                .borrow_mut()
                .read(count)
                .map_err(LuaError::external)?;
            Ok(String::from_utf8_lossy(&bytes).to_string())
        });
        methods.add_method("readLine", |_, this, ()| {
            this.inner
                .borrow_mut()
                .read_line()
                .map_err(LuaError::external)
        });
        methods.add_method("write", |_, this, data: String| {
            this.inner
                .borrow_mut()
                .write(data.as_bytes())
                .map_err(LuaError::external)
        });
        methods.add_method("seek", |_, this, pos: u64| {
            this.inner
                .borrow_mut()
                .seek(pos)
                .map_err(LuaError::external)
        });
        methods.add_method("tell", |_, this, ()| {
            this.inner.borrow_mut().tell().map_err(LuaError::external)
        });
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.borrow().get_size()));
        methods.add_method("getMode", |_, this, ()| {
            Ok(this.inner.borrow().get_mode().as_str().to_string())
        });
        methods.add_method("flush", |_, this, ()| {
            this.inner.borrow_mut().flush().map_err(LuaError::external)
        });
        methods.add_method("close", |_, this, ()| {
            this.inner.borrow_mut().close().map_err(LuaError::external)
        });
        methods.add_method("isEOF", |_, this, ()| {
            this.inner.borrow_mut().is_eof().map_err(LuaError::external)
        });
        methods.add_method("type", |_, _, ()| Ok("LFileHandle"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LFileHandle" || name == "Object")
        });
    }
}
struct LuaZipMount {
    inner: ZipMount,
}
impl LuaUserData for LuaZipMount {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("readFile", |_, this, virtual_path: String| {
            let bytes = this
                .inner
                .read_file(&virtual_path)
                .map_err(LuaError::RuntimeError)?;
            Ok(bytes)
        });
        methods.add_method("contains", |_, this, virtual_path: String| {
            Ok(this.inner.contains(&virtual_path))
        });
        methods.add_method("listFiles", |lua, this, ()| {
            let files = this.inner.list_files();
            let tbl = lua.create_table()?;
            for (i, f) in files.iter().enumerate() {
                tbl.set(i + 1, f.clone())?;
            }
            Ok(tbl)
        });
        methods.add_method("prefix", |_, this, ()| Ok(this.inner.prefix.clone()));
        methods.add_method("type", |_, _, ()| Ok("LZipMount"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LZipMount" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set(
        "mountZip",
        lua.create_function(|lua, (archive_path, prefix): (String, String)| {
            let mount = ZipMount::new(&archive_path, &prefix).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaZipMount { inner: mount })
        })?,
    )?;
    let watcher_rc = Rc::new(RefCell::new(FileWatcher::new()));
    let wrc = watcher_rc.clone();
    tbl.set(
        "watchPath",
        lua.create_function(move |_, path: String| {
            wrc.borrow_mut().watch(&path);
            Ok(())
        })?,
    )?;
    let wrc = watcher_rc.clone();
    tbl.set(
        "unwatchPath",
        lua.create_function(move |_, path: String| {
            wrc.borrow_mut().unwatch(&path);
            Ok(())
        })?,
    )?;
    let wrc = watcher_rc.clone();
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
    tbl.set(
        "read",
        lua.create_function(move |_, path: String| {
            s.borrow().fs.read_string(&path).map_err(LuaError::external)
        })?,
    )?;
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
    let s = state.clone();
    tbl.set(
        "readJson",
        lua.create_function(move |_, path: String| {
            s.borrow().fs.read_json(&path).map_err(LuaError::external)
        })?,
    )?;
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
    let s = state.clone();
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
    tbl.set(
        "exists",
        lua.create_function(move |_, path: String| Ok(s.borrow().fs.exists(&path)))?,
    )?;
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
    let s = state.clone();
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
    tbl.set(
        "isFile",
        lua.create_function(move |_, path: String| Ok(s.borrow().fs.is_file(&path)))?,
    )?;
    let s = state.clone();
    tbl.set(
        "isDirectory",
        lua.create_function(move |_, path: String| Ok(s.borrow().fs.is_directory(&path)))?,
    )?;
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
    let s = state.clone();
    tbl.set(
        "remove",
        lua.create_function(move |_, path: String| {
            s.borrow().fs.remove(&path).map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
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
    let s = state.clone();
    tbl.set(
        "getSource",
        lua.create_function(move |_, ()| Ok(s.borrow().fs.get_source()))?,
    )?;
    let s = state.clone();
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
    tbl.set(
        "getWorkingDirectory",
        lua.create_function(move |_, ()| {
            GameFS::get_working_directory().map_err(LuaError::external)
        })?,
    )?;
    tbl.set(
        "getUserDirectory",
        lua.create_function(move |_, ()| Ok(GameFS::get_user_directory()))?,
    )?;
    let s = state.clone();
    tbl.set(
        "getIdentity",
        lua.create_function(move |_, ()| Ok(s.borrow().filesystem_identity.clone()))?,
    )?;
    let s = state.clone();
    tbl.set(
        "setIdentity",
        lua.create_function(move |_, name: String| {
            s.borrow_mut().filesystem_identity = name;
            Ok(())
        })?,
    )?;
    let s = state.clone();
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
    tbl.set(
        "readAsync",
        lua.create_function(move |_, path: String| {
            s.borrow_mut()
                .request_async_load(&path)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "pollAsync",
        lua.create_function(move |_, handle_id: u64| Ok(s.borrow().poll_async_load(handle_id)))?,
    )?;
    let s = state.clone();
    tbl.set(
        "writeAsync",
        lua.create_function(move |_, (path, data): (String, LuaString)| {
            s.borrow_mut()
                .request_async_write(&path, data.as_bytes().to_vec())
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "pollAsyncWrite",
        lua.create_function(move |_, handle_id: u64| Ok(s.borrow().poll_async_write(handle_id)))?,
    )?;
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
    let s = state.clone();
    tbl.set(
        "unmount",
        lua.create_function(move |_, mp: String| Ok(s.borrow_mut().fs.unmount(&mp)))?,
    )?;
    let s = state.clone();
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
    let s = state.clone();
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
    tbl.set(
        "removeDir",
        lua.create_function(move |_, path: String| {
            s.borrow().fs.remove_dir(&path).map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
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
    let s = state.clone();
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
    tbl.set(
        "mkdir",
        lua.create_function(move |_, path: String| {
            let abs = s.borrow().fs.base_dir().join(&path);
            std::fs::create_dir_all(&abs)
                .map_err(|e| LuaError::RuntimeError(format!("mkdir '{}': {}", path, e)))
        })?,
    )?;
    let s = state.clone();
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
