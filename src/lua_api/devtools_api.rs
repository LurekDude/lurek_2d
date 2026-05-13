use crate::devtools::{FileWatcher, FrameStats, Logger, ProfileZone, Profiler, ReplConsole};
use crate::runtime::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
struct WatchEntry {
    name: String,
    getter: LuaRegistryKey,
    category: String,
}
struct DevtoolsShared {
    logger: Logger,
    profiler: Profiler,
    frame_stats: FrameStats,
    gpu_frame_stats: FrameStats,
    watcher: FileWatcher,
    console_open: bool,
    entity_inspector_open: bool,
    watch_interval: f32,
    watches: Vec<WatchEntry>,
    next_watch_id: u64,
}
impl DevtoolsShared {
    fn new() -> Self {
        Self {
            logger: Logger::new(),
            profiler: Profiler::new(),
            frame_stats: FrameStats::default(),
            gpu_frame_stats: FrameStats::default(),
            watcher: FileWatcher::new(),
            console_open: false,
            entity_inspector_open: false,
            watch_interval: 0.5,
            watches: Vec::new(),
            next_watch_id: 1,
        }
    }
}
fn zone_to_table<'a>(lua: &'a Lua, zone: &ProfileZone) -> LuaResult<LuaTable<'a>> {
    let tbl = lua.create_table()?;
    tbl.set("name", zone.name.clone())?;
    tbl.set("time", zone.total_time())?;
    tbl.set("selfTime", zone.self_time())?;
    tbl.set("startTime", zone.start_time)?;
    let children = lua.create_table()?;
    for (i, child) in zone.children.iter().enumerate() {
        children.set(i + 1, zone_to_table(lua, child)?)?;
    }
    tbl.set("children", children)?;
    Ok(tbl)
}
struct LuaFileWatcher {
    watcher: FileWatcher,
    path: String,
    callback: Rc<RefCell<Option<LuaRegistryKey>>>,
}
impl LuaUserData for LuaFileWatcher {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("onChanged", |lua, this, func: LuaFunction| {
            let key = lua.create_registry_value(func)?;
            if let Some(old) = this.callback.borrow_mut().replace(key) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });
        methods.add_method_mut("check", |lua, this, ()| {
            let changed = this.watcher.poll();
            if !changed.is_empty() {
                if let Some(key) = this.callback.borrow().as_ref() {
                    if let Ok(func) = lua.registry_value::<LuaFunction>(key) {
                        func.call::<_, ()>(())?;
                    }
                }
                return Ok(true);
            }
            Ok(false)
        });
        methods.add_method("getPath", |_, this, ()| Ok(this.path.clone()));
        methods.add_method_mut("cancel", |lua, this, ()| {
            this.watcher.clear();
            if let Some(key) = this.callback.borrow_mut().take() {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LFileWatcher"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LFileWatcher" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let dt = lua.create_table()?;
    let shared = Rc::new(RefCell::new(DevtoolsShared::new()));
    let s = shared.clone();
    dt.set(
        "log",
        lua.create_function(move |_, (level, message): (String, String)| {
            s.borrow_mut().logger.push(&level, &message, "?", 0, None);
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "trace",
        lua.create_function(move |_, message: String| {
            s.borrow_mut().logger.push("trace", &message, "?", 0, None);
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "debug",
        lua.create_function(move |_, message: String| {
            s.borrow_mut().logger.push("debug", &message, "?", 0, None);
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "info",
        lua.create_function(move |_, message: String| {
            s.borrow_mut().logger.push("info", &message, "?", 0, None);
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "warn",
        lua.create_function(move |_, message: String| {
            s.borrow_mut().logger.push("warn", &message, "?", 0, None);
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "error",
        lua.create_function(move |_, message: String| {
            s.borrow_mut().logger.push("error", &message, "?", 0, None);
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "fatal",
        lua.create_function(move |_, message: String| {
            s.borrow_mut().logger.push("fatal", &message, "?", 0, None);
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "setLogLevel",
        lua.create_function(move |_, level: String| {
            use crate::devtools::LogLevel;
            if let Some(lv) = LogLevel::from_str(&level) {
                s.borrow_mut().logger.min_level = lv;
            }
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "getLogLevel",
        lua.create_function(move |_, ()| Ok(s.borrow().logger.min_level.as_str().to_string()))?,
    )?;
    let s = shared.clone();
    dt.set(
        "setLogConsole",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().logger.console_enabled = enabled;
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "getLogConsole",
        lua.create_function(move |_, ()| Ok(s.borrow().logger.console_enabled))?,
    )?;
    let s = shared.clone();
    dt.set(
        "setLogFile",
        lua.create_function(move |_, path: String| {
            s.borrow_mut().logger.log_file = path;
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "getLogFile",
        lua.create_function(move |_, ()| Ok(s.borrow().logger.log_file.clone()))?,
    )?;
    let s = shared.clone();
    dt.set(
        "getLogHistory",
        lua.create_function(move |lua, count: Option<usize>| {
            let st = s.borrow();
            let entries = st.logger.tail(count);
            let tbl = lua.create_table()?;
            for (i, entry) in entries.iter().enumerate() {
                let e = lua.create_table()?;
                e.set("level", entry.level.clone())?;
                e.set("timestamp", entry.timestamp)?;
                e.set("message", entry.message.clone())?;
                e.set("source", entry.source.clone())?;
                e.set("line", entry.line)?;
                if let Some(ref cat) = entry.category {
                    e.set("category", cat.clone())?;
                }
                tbl.set(i + 1, e)?;
            }
            Ok(tbl)
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "clearLog",
        lua.create_function(move |_, ()| {
            s.borrow_mut().logger.clear();
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "setProfilingEnabled",
        lua.create_function(move |_, enabled: bool| {
            s.borrow_mut().profiler.enabled = enabled;
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "isProfilingEnabled",
        lua.create_function(move |_, ()| Ok(s.borrow().profiler.enabled))?,
    )?;
    let s = shared.clone();
    dt.set(
        "profilePush",
        lua.create_function(move |_, name: String| {
            s.borrow_mut().profiler.push(&name);
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "profilePop",
        lua.create_function(move |_, _: Option<String>| {
            s.borrow_mut().profiler.pop();
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "profileFrame",
        lua.create_function(move |_, ()| {
            s.borrow_mut().profiler.end_frame();
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "getProfileFrameCount",
        lua.create_function(move |_, ()| Ok(s.borrow().profiler.frames.len()))?,
    )?;
    let s = shared.clone();
    dt.set(
        "getProfileData",
        lua.create_function(move |lua, frame: Option<i64>| {
            let st = s.borrow();
            let idx = frame.unwrap_or(0);
            let tbl = lua.create_table()?;
            if let Some(zones) = st.profiler.get_frame(idx) {
                for (i, zone) in zones.iter().enumerate() {
                    tbl.set(i + 1, zone_to_table(lua, zone)?)?;
                }
            }
            Ok(tbl)
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "resetProfile",
        lua.create_function(move |_, ()| {
            s.borrow_mut().profiler.reset();
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "recordFrameTime",
        lua.create_function(move |_, dt_val: f64| {
            s.borrow_mut().frame_stats.record(dt_val);
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "getFrameStats",
        lua.create_function(move |lua, ()| {
            let snap = s.borrow().frame_stats.snapshot();
            let tbl = lua.create_table()?;
            tbl.set("fps", snap.fps)?;
            tbl.set("dt", snap.dt)?;
            tbl.set("avg", snap.avg)?;
            tbl.set("min", snap.min)?;
            tbl.set("max", snap.max)?;
            tbl.set("p50", snap.p50)?;
            tbl.set("p95", snap.p95)?;
            tbl.set("p99", snap.p99)?;
            tbl.set("samples", snap.samples)?;
            Ok(tbl)
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "recordGpuFrameTime",
        lua.create_function(move |_, dt_val: f64| {
            s.borrow_mut().gpu_frame_stats.record(dt_val);
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "getGpuFrameStats",
        lua.create_function(move |lua, ()| {
            let snap = s.borrow().gpu_frame_stats.snapshot();
            let tbl = lua.create_table()?;
            tbl.set("fps", snap.fps)?;
            tbl.set("dt", snap.dt)?;
            tbl.set("avg", snap.avg)?;
            tbl.set("min", snap.min)?;
            tbl.set("max", snap.max)?;
            tbl.set("p50", snap.p50)?;
            tbl.set("p95", snap.p95)?;
            tbl.set("p99", snap.p99)?;
            tbl.set("samples", snap.samples)?;
            Ok(tbl)
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "getFrameHistory",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let tbl = lua.create_table()?;
            for (i, &val) in st.frame_stats.history.iter().enumerate() {
                tbl.set(i + 1, val)?;
            }
            Ok(tbl)
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "setFrameHistorySize",
        lua.create_function(move |_, size: usize| {
            s.borrow_mut().frame_stats.set_capacity(size);
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "getFrameHistorySize",
        lua.create_function(move |_, ()| Ok(s.borrow().frame_stats.capacity))?,
    )?;
    let s = shared.clone();
    dt.set(
        "watch",
        lua.create_function(move |_, path: String| {
            let mut st = s.borrow_mut();
            if st.watcher.paths.contains_key(std::path::Path::new(&path)) {
                return Ok(false);
            }
            st.watcher.watch(&path);
            Ok(true)
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "unwatch",
        lua.create_function(move |_, path: String| Ok(s.borrow_mut().watcher.unwatch(&path)))?,
    )?;
    let s = shared.clone();
    dt.set(
        "getWatchedPaths",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let mut paths = st.watcher.watched_paths();
            paths.sort();
            let tbl = lua.create_table()?;
            for (i, p) in paths.iter().enumerate() {
                tbl.set(i + 1, p.clone())?;
            }
            Ok(tbl)
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "scan",
        lua.create_function(move |lua, ()| {
            let mut st = s.borrow_mut();
            let changed = st.watcher.poll();
            let tbl = lua.create_table()?;
            for (i, p) in changed.iter().enumerate() {
                tbl.set(i + 1, p.clone())?;
            }
            Ok(tbl)
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "clearWatches",
        lua.create_function(move |_, ()| {
            s.borrow_mut().watcher.clear();
            Ok(())
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "getWatchInterval",
        lua.create_function(move |_, ()| Ok(s.borrow().watch_interval))?,
    )?;
    let s = shared.clone();
    dt.set(
        "setWatchInterval",
        lua.create_function(move |_, interval: f32| {
            s.borrow_mut().watch_interval = interval.max(0.01);
            Ok(())
        })?,
    )?;
    dt.set(
        "getCallStack",
        lua.create_function(|lua, max_depth: Option<usize>| {
            let max = max_depth.unwrap_or(20).min(100);
            let code = "local max = ...\n\
            local frames = {}\n\
            if not debug or not debug.getinfo then return frames end\n\
            for i = 2, max + 1 do\n\
              local info = debug.getinfo(i, 'Snl')\n\
              if not info then break end\n\
              frames[#frames+1] = {\n\
                source = info.short_src or '?',\n\
                line = info.currentline or 0,\n\
                name = info.name or '?',\n\
                what = info.namewhat or ''\n\
              }\n\
            end\n\
            return frames";
            let frames: LuaTable = lua.load(code).call(max)?;
            Ok(frames)
        })?,
    )?;
    dt.set(
        "eval",
        lua.create_function(
            |lua, code: String| match lua.load(&code).eval::<LuaMultiValue>() {
                Ok(vals) => {
                    let mut result = vec![LuaValue::Boolean(true)];
                    result.extend(vals.into_iter());
                    Ok(LuaMultiValue::from_vec(result))
                }
                Err(e) => Ok(LuaMultiValue::from_vec(vec![
                    LuaValue::Boolean(false),
                    LuaValue::String(lua.create_string(e.to_string().as_bytes())?),
                ])),
            },
        )?,
    )?;
    let s = shared.clone();
    dt.set(
        "openConsole",
        lua.create_function(move |_, ()| {
            s.borrow_mut().console_open = true;
            Ok(true)
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "isConsoleOpen",
        lua.create_function(move |_, ()| Ok(s.borrow().console_open))?,
    )?;
    let s = shared.clone();
    dt.set(
        "openEntityInspector",
        lua.create_function(move |_, ()| {
            s.borrow_mut().entity_inspector_open = true;
            Ok(true)
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "isEntityInspectorOpen",
        lua.create_function(move |_, ()| Ok(s.borrow().entity_inspector_open))?,
    )?;
    let s = shared.clone();
    dt.set(
        "exposeWatch",
        lua.create_function(
            move |lua, (name, getter, category): (String, LuaFunction, Option<String>)| {
                let key = lua.create_registry_value(getter)?;
                let mut st = s.borrow_mut();
                let id = st.next_watch_id;
                st.next_watch_id += 1;
                st.watches.push(WatchEntry {
                    name,
                    getter: key,
                    category: category.unwrap_or_default(),
                });
                Ok(id)
            },
        )?,
    )?;
    let s = shared.clone();
    dt.set(
        "removeWatch",
        lua.create_function(move |_, id: u64| {
            let mut st = s.borrow_mut();
            let start_id = st.next_watch_id - st.watches.len() as u64;
            let idx = id.checked_sub(start_id) as Option<u64>;
            if let Some(i) = idx {
                if (i as usize) < st.watches.len() {
                    st.watches.remove(i as usize);
                    return Ok(true);
                }
            }
            Ok(false)
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "getWatches",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let tbl = lua.create_table()?;
            for (i, entry) in st.watches.iter().enumerate() {
                let row = lua.create_table()?;
                row.set("name", entry.name.clone())?;
                row.set("category", entry.category.clone())?;
                let getter: LuaFunction = lua.registry_value(&entry.getter)?;
                match getter.call::<_, LuaValue>(()) {
                    Ok(v) => {
                        row.set("value", v)?;
                    }
                    Err(e) => {
                        row.set("value", format!("(error: {})", e))?;
                    }
                }
                tbl.set(i + 1, row)?;
            }
            Ok(tbl)
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "snapshot",
        lua.create_function(move |lua, ()| {
            let st = s.borrow();
            let snap = lua.create_table()?;
            let fs = st.frame_stats.snapshot();
            let fst = lua.create_table()?;
            fst.set("fps", fs.fps)?;
            fst.set("dt", fs.dt)?;
            fst.set("avg", fs.avg)?;
            fst.set("p95", fs.p95)?;
            fst.set("p99", fs.p99)?;
            snap.set("frameStats", fst)?;
            let watches_tbl = lua.create_table()?;
            for (i, entry) in st.watches.iter().enumerate() {
                let row = lua.create_table()?;
                row.set("name", entry.name.clone())?;
                row.set("category", entry.category.clone())?;
                let getter: LuaFunction = lua.registry_value(&entry.getter)?;
                match getter.call::<_, LuaValue>(()) {
                    Ok(v) => {
                        row.set("value", v)?;
                    }
                    Err(e) => {
                        row.set("value", format!("(error: {})", e))?;
                    }
                }
                watches_tbl.set(i + 1, row)?;
            }
            snap.set("watches", watches_tbl)?;
            let profile_tbl = lua.create_table()?;
            if let Some(zones) = st.profiler.get_frame(0) {
                for (i, zone) in zones.iter().enumerate() {
                    profile_tbl.set(i + 1, zone_to_table(lua, zone)?)?;
                }
            }
            snap.set("profile", profile_tbl)?;
            let log_tbl = lua.create_table()?;
            for (i, entry) in st.logger.tail(Some(10)).iter().enumerate() {
                let et = lua.create_table()?;
                et.set("level", entry.level.clone())?;
                et.set("message", entry.message.clone())?;
                et.set("source", entry.source.clone())?;
                log_tbl.set(i + 1, et)?;
            }
            snap.set("log", log_tbl)?;
            snap.set("watchCount", st.watches.len())?;
            Ok(snap)
        })?,
    )?;
    let s = shared.clone();
    dt.set(
        "profilerReport",
        lua.create_function(move |lua, ()| {
            let mut aggregated: std::collections::HashMap<String, (f64, u32, f64, f64, f64)> =
                Default::default();
            let st = s.borrow();
            for frame in &st.profiler.frames {
                for zone in frame.iter() {
                    for z in zone.flatten() {
                        let dur = z.total_time() * 1000.0;
                        let self_dur = z.self_time() * 1000.0;
                        let e = aggregated.entry(z.name.clone()).or_insert((
                            0.0,
                            0,
                            f64::MAX,
                            0.0_f64,
                            0.0,
                        ));
                        e.0 += dur;
                        e.1 += 1;
                        e.2 = e.2.min(dur);
                        e.3 = e.3.max(dur);
                        e.4 += self_dur;
                    }
                }
            }
            let out = lua.create_table()?;
            for (i, (name, (total, calls, min, max, self_ms))) in aggregated.iter().enumerate() {
                let row = lua.create_table()?;
                row.set("name", name.clone())?;
                row.set("calls", *calls)?;
                row.set("total_ms", *total)?;
                row.set(
                    "avg_ms",
                    if *calls > 0 {
                        total / (*calls as f64)
                    } else {
                        0.0
                    },
                )?;
                row.set("min_ms", if *min == f64::MAX { 0.0 } else { *min })?;
                row.set("max_ms", *max)?;
                row.set("self_ms", *self_ms)?;
                out.set(i + 1, row)?;
            }
            Ok(out)
        })?,
    )?;
    dt.set(
        "newFileWatcher",
        lua.create_function(|lua, path: String| {
            let mut fw = LuaFileWatcher {
                watcher: FileWatcher::new(),
                path: path.clone(),
                callback: Rc::new(RefCell::new(None)),
            };
            fw.watcher.watch(&path);
            lua.create_userdata(fw)
        })?,
    )?;
    dt.set(
        "newRepl",
        lua.create_function(|lua, max_history: Option<usize>| {
            lua.create_userdata(LuaReplConsole {
                inner: ReplConsole::new(max_history.unwrap_or(200)),
            })
        })?,
    )?;
    lurek.set("devtools", dt)?;
    Ok(())
}
pub struct LuaReplConsole {
    inner: ReplConsole,
}
impl LuaUserData for LuaReplConsole {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("eval", |lua, this, code: String| {
            Ok(this.inner.eval(&code, lua))
        });
        methods.add_method("history", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, entry) in this.inner.history().iter().enumerate() {
                t.set(i + 1, entry.clone())?;
            }
            Ok(t)
        });
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        methods.add_method("len", |_, this, ()| Ok(this.inner.len()));
        methods.add_method("type", |_, _, ()| Ok("LReplConsole"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LReplConsole" || name == "Object")
        });
    }
}
