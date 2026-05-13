use crate::lua_api::lua_types::{add_type_methods, LurekType};
use crate::runtime::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::collections::HashSet;
use std::collections::VecDeque;
use std::rc::Rc;
#[derive(Clone)]
struct LuaEventBus {
    bus: Rc<RefCell<crate::patterns::EventBus>>,
    callbacks: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
}
impl LurekType for LuaEventBus {
    const TYPE_NAME: &'static str = "LEventBus";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LEventBus", "Object"];
}
impl LuaUserData for LuaEventBus {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method(
            "on",
            |lua, this, (event, callback, priority): (String, LuaFunction, Option<i64>)| {
                let priority = priority.unwrap_or(0);
                let id = this.bus.borrow_mut().subscribe(&event, priority, false);
                let key = lua.create_registry_value(callback)?;
                this.callbacks.borrow_mut().insert(id, key);
                Ok(id)
            },
        );
        methods.add_method("off", |lua, this, id: u64| {
            this.bus.borrow_mut().unsubscribe(id);
            if let Some(key) = this.callbacks.borrow_mut().remove(&id) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        methods.add_method("emit", |lua, this, args: LuaMultiValue| {
            let mut args_iter = args.into_iter();
            let event: String = match args_iter.next() {
                Some(v) => lua.unpack(v)?,
                None => return Err(LuaError::external("emit requires an event name")),
            };
            let extra: Vec<LuaValue> = args_iter.collect();
            let ids = this.bus.borrow().get_listeners(&event);
            for id in &ids {
                let cbs = this.callbacks.borrow();
                if let Some(key) = cbs.get(id) {
                    let func: LuaFunction = lua.registry_value(key)?;
                    drop(cbs);
                    func.call::<_, ()>(LuaMultiValue::from_iter(extra.clone()))?;
                }
            }
            let removed = this.bus.borrow_mut().drain_once(&ids);
            let mut cbs = this.callbacks.borrow_mut();
            for id in removed {
                if let Some(key) = cbs.remove(&id) {
                    lua.remove_registry_value(key)?;
                }
            }
            Ok(())
        });
        methods.add_method("clear", |lua, this, event: String| {
            let removed_ids = this.bus.borrow_mut().clear_event(&event);
            let mut cbs = this.callbacks.borrow_mut();
            for id in removed_ids {
                if let Some(key) = cbs.remove(&id) {
                    lua.remove_registry_value(key)?;
                }
            }
            Ok(())
        });
        methods.add_method("clearAll", |lua, this, ()| {
            let _ = this.bus.borrow_mut().clear_all();
            let drained: Vec<(u64, LuaRegistryKey)> = this.callbacks.borrow_mut().drain().collect();
            for (_, key) in drained {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        methods.add_method("getListenerCount", |_lua, this, event: String| {
            Ok(this.bus.borrow().listener_count(&event))
        });
        methods.add_method("getEvents", |lua, this, ()| {
            let names = this.bus.borrow().event_names();
            let table = lua.create_table()?;
            for (i, name) in names.iter().enumerate() {
                table.set(i + 1, name.as_str())?;
            }
            Ok(table)
        });
    }
}
#[derive(Clone)]
struct LuaObjectPool {
    pool: Rc<RefCell<crate::patterns::ObjectPool>>,
    idle_objects: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
    active_queue: Rc<RefCell<VecDeque<u64>>>,
}
impl LurekType for LuaObjectPool {
    const TYPE_NAME: &'static str = "LObjectPool";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LObjectPool", "Object"];
}
impl LuaUserData for LuaObjectPool {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method("add", |lua, this, value: LuaValue| {
            let total = this.pool.borrow().total_count();
            let new_ids = this.pool.borrow_mut().prewarm(total + 1);
            if let Some(&id) = new_ids.first() {
                let key = lua.create_registry_value(value)?;
                this.idle_objects.borrow_mut().insert(id, key);
            }
            Ok(())
        });
        methods.add_method("acquire", |lua, this, ()| {
            if let Some(id) = this.pool.borrow_mut().acquire() {
                if let Some(key) = this.idle_objects.borrow_mut().remove(&id) {
                    let val: LuaValue = lua.registry_value(&key)?;
                    lua.remove_registry_value(key)?;
                    this.active_queue.borrow_mut().push_back(id);
                    return Ok(val);
                }
                this.pool.borrow_mut().release(id);
            }
            Ok(LuaValue::Nil)
        });
        methods.add_method("release", |lua, this, value: LuaValue| {
            if let Some(id) = this.active_queue.borrow_mut().pop_front() {
                this.pool.borrow_mut().release(id);
                let key = lua.create_registry_value(value)?;
                this.idle_objects.borrow_mut().insert(id, key);
            }
            Ok(())
        });
        methods.add_method("getActiveCount", |_lua, this, ()| {
            Ok(this.pool.borrow().active_count())
        });
        methods.add_method("getAvailableCount", |_lua, this, ()| {
            Ok(this.pool.borrow().idle_count())
        });
        methods.add_method("getTotalCount", |_lua, this, ()| {
            Ok(this.pool.borrow().total_count())
        });
        methods.add_method("clearAll", |lua, this, ()| {
            let cap = this.pool.borrow().capacity;
            *this.pool.borrow_mut() = crate::patterns::ObjectPool::new("", cap);
            this.active_queue.borrow_mut().clear();
            let drained: Vec<(u64, LuaRegistryKey)> =
                this.idle_objects.borrow_mut().drain().collect();
            for (_, key) in drained {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
    }
}
#[derive(Clone)]
struct LuaCommandStack {
    stack: Rc<RefCell<crate::patterns::CommandStack>>,
    exec_fns: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
    undo_fns: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
    history_ids: Rc<RefCell<Vec<u64>>>,
}
impl LurekType for LuaCommandStack {
    const TYPE_NAME: &'static str = "LCommandStack";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LCommandStack", "Object"];
}
impl LuaUserData for LuaCommandStack {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method(
            "execute",
            |lua, this, (name, exec_fn, undo_fn): (String, LuaFunction, Option<LuaFunction>)| {
                let undo_count = this.stack.borrow().undo_count();
                let discarded: Vec<u64> = {
                    let mut ids = this.history_ids.borrow_mut();
                    ids.drain(undo_count..).collect()
                };
                {
                    let mut exec_fns = this.exec_fns.borrow_mut();
                    let mut undo_fns = this.undo_fns.borrow_mut();
                    for id in discarded {
                        if let Some(k) = exec_fns.remove(&id) {
                            lua.remove_registry_value(k)?;
                        }
                        if let Some(k) = undo_fns.remove(&id) {
                            lua.remove_registry_value(k)?;
                        }
                    }
                }
                let has_undo = undo_fn.is_some();
                let entry_id = this.stack.borrow_mut().push(&name, has_undo);
                this.history_ids.borrow_mut().push(entry_id);
                let expected_total = {
                    let s = this.stack.borrow();
                    s.undo_count() + s.redo_count()
                };
                while this.history_ids.borrow().len() > expected_total {
                    let oldest_id = this.history_ids.borrow_mut().remove(0);
                    if let Some(k) = this.exec_fns.borrow_mut().remove(&oldest_id) {
                        lua.remove_registry_value(k)?;
                    }
                    if let Some(k) = this.undo_fns.borrow_mut().remove(&oldest_id) {
                        lua.remove_registry_value(k)?;
                    }
                }
                exec_fn.call::<_, ()>(())?;
                this.exec_fns
                    .borrow_mut()
                    .insert(entry_id, lua.create_registry_value(exec_fn)?);
                if let Some(f) = undo_fn {
                    this.undo_fns
                        .borrow_mut()
                        .insert(entry_id, lua.create_registry_value(f)?);
                }
                Ok(())
            },
        );
        methods.add_method("undo", |lua, this, ()| {
            let peek_id = this.stack.borrow().peek_undo();
            if let Some(id) = peek_id {
                let has_undo = this
                    .stack
                    .borrow()
                    .get_entry(id)
                    .map(|e| e.has_undo)
                    .unwrap_or(false);
                if !has_undo {
                    return Ok(false);
                }
                let func_opt = this
                    .undo_fns
                    .borrow()
                    .get(&id)
                    .map(|k| lua.registry_value::<LuaFunction>(k));
                if let Some(Ok(func)) = func_opt {
                    func.call::<_, ()>(())?;
                    this.stack.borrow_mut().step_undo();
                    Ok(true)
                } else {
                    Ok(false)
                }
            } else {
                Ok(false)
            }
        });
        methods.add_method("redo", |lua, this, ()| {
            let peek_id = this.stack.borrow().peek_redo();
            if let Some(id) = peek_id {
                let func_opt = this
                    .exec_fns
                    .borrow()
                    .get(&id)
                    .map(|k| lua.registry_value::<LuaFunction>(k));
                if let Some(Ok(func)) = func_opt {
                    func.call::<_, ()>(())?;
                    this.stack.borrow_mut().step_redo();
                    Ok(true)
                } else {
                    Ok(false)
                }
            } else {
                Ok(false)
            }
        });
        methods.add_method("canUndo", |_lua, this, ()| {
            let s = this.stack.borrow();
            Ok(s.peek_undo()
                .and_then(|id| s.get_entry(id))
                .map(|e| e.has_undo)
                .unwrap_or(false))
        });
        methods.add_method("canRedo", |_lua, this, ()| {
            Ok(this.stack.borrow().redo_count() > 0)
        });
        methods.add_method("getHistorySize", |_lua, this, ()| {
            let s = this.stack.borrow();
            Ok(s.undo_count() + s.redo_count())
        });
        methods.add_method("getCurrentName", |_lua, this, ()| {
            let s = this.stack.borrow();
            Ok(s.peek_undo()
                .and_then(|id| s.get_entry(id))
                .map(|e| e.name.clone()))
        });
        methods.add_method("clearAll", |lua, this, ()| {
            this.stack.borrow_mut().clear();
            this.history_ids.borrow_mut().clear();
            for (_, key) in this.exec_fns.borrow_mut().drain() {
                lua.remove_registry_value(key)?;
            }
            for (_, key) in this.undo_fns.borrow_mut().drain() {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
    }
}
#[derive(Clone)]
struct LuaServiceLocator {
    locator: Rc<RefCell<crate::patterns::ServiceLocator>>,
    services: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
}
impl LurekType for LuaServiceLocator {
    const TYPE_NAME: &'static str = "LServiceLocator";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LServiceLocator", "Object"];
}
impl LuaUserData for LuaServiceLocator {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method("provide", |lua, this, (name, value): (String, LuaValue)| {
            this.locator.borrow_mut().register(&name);
            let key = lua.create_registry_value(value)?;
            if let Some(old) = this.services.borrow_mut().insert(name, key) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });
        methods.add_method("locate", |lua, this, name: String| {
            let svc = this.services.borrow();
            match svc.get(&name) {
                Some(key) => Ok(lua.registry_value::<LuaValue>(key)?),
                None => Ok(LuaValue::Nil),
            }
        });
        methods.add_method("has", |_lua, this, name: String| {
            Ok(this.locator.borrow().has(&name))
        });
        methods.add_method("remove", |lua, this, name: String| {
            this.locator.borrow_mut().unregister(&name);
            if let Some(key) = this.services.borrow_mut().remove(&name) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        methods.add_method("getServices", |lua, this, ()| {
            let names: Vec<String> = this
                .locator
                .borrow()
                .names()
                .iter()
                .map(|s| s.to_string())
                .collect();
            let table = lua.create_table()?;
            for (i, name) in names.iter().enumerate() {
                table.set(i + 1, name.as_str())?;
            }
            Ok(table)
        });
        methods.add_method("clearAll", |lua, this, ()| {
            this.locator.borrow_mut().clear();
            let drained: Vec<(String, LuaRegistryKey)> =
                this.services.borrow_mut().drain().collect();
            for (_, key) in drained {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
    }
}
#[derive(Clone)]
struct LuaFactory {
    factory: Rc<RefCell<crate::patterns::Factory>>,
    constructors: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
}
impl LurekType for LuaFactory {
    const TYPE_NAME: &'static str = "LFactory";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LFactory", "Object"];
}
impl LuaUserData for LuaFactory {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method(
            "register",
            |lua, this, (type_name, ctor): (String, LuaFunction)| {
                this.factory.borrow_mut().register(&type_name);
                let key = lua.create_registry_value(ctor)?;
                if let Some(old) = this.constructors.borrow_mut().insert(type_name, key) {
                    lua.remove_registry_value(old)?;
                }
                Ok(())
            },
        );
        methods.add_method("create", |lua, this, args: LuaMultiValue| {
            let mut args_iter = args.into_iter();
            let type_name: String = match args_iter.next() {
                Some(v) => lua.unpack(v)?,
                None => return Err(LuaError::external("create requires a type name")),
            };
            let extra: Vec<LuaValue> = args_iter.collect();
            let canonical = this.factory.borrow().resolve(&type_name).to_string();
            let ctors = this.constructors.borrow();
            let key = ctors.get(&canonical).ok_or_else(|| {
                LuaError::external(format!("no constructor registered for type '{canonical}'"))
            })?;
            let func: LuaFunction = lua.registry_value(key)?;
            drop(ctors);
            func.call::<_, LuaValue>(LuaMultiValue::from_iter(extra))
        });
        methods.add_method("has", |_lua, this, type_name: String| {
            Ok(this.factory.borrow().has(&type_name))
        });
        methods.add_method(
            "alias",
            |_lua, this, (alias, canonical): (String, String)| {
                this.factory.borrow_mut().add_alias(&alias, &canonical);
                Ok(())
            },
        );
        methods.add_method("getTypes", |lua, this, ()| {
            let names: Vec<String> = this
                .factory
                .borrow()
                .type_names()
                .iter()
                .map(|s| s.to_string())
                .collect();
            let table = lua.create_table()?;
            for (i, name) in names.iter().enumerate() {
                table.set(i + 1, name.as_str())?;
            }
            Ok(table)
        });
        methods.add_method("remove", |lua, this, type_name: String| {
            this.factory.borrow_mut().unregister(&type_name);
            if let Some(key) = this.constructors.borrow_mut().remove(&type_name) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        methods.add_method("clearAll", |lua, this, ()| {
            this.factory.borrow_mut().clear();
            let drained: Vec<(String, LuaRegistryKey)> =
                this.constructors.borrow_mut().drain().collect();
            for (_, key) in drained {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
    }
}
#[derive(Clone)]
struct LuaSimpleState {
    state: Rc<RefCell<crate::patterns::SimpleState>>,
    enter_keys: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
    exit_keys: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
    update_keys: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
}
impl LurekType for LuaSimpleState {
    const TYPE_NAME: &'static str = "LSimpleState";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LSimpleState", "Object"];
}
impl LuaUserData for LuaSimpleState {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method(
            "addState",
            |lua, this, (name, callbacks): (String, Option<LuaTable>)| {
                {
                    let mut enter = this.enter_keys.borrow_mut();
                    let mut exit = this.exit_keys.borrow_mut();
                    let mut update = this.update_keys.borrow_mut();
                    if let Some(k) = enter.remove(&name) {
                        lua.remove_registry_value(k)?;
                    }
                    if let Some(k) = exit.remove(&name) {
                        lua.remove_registry_value(k)?;
                    }
                    if let Some(k) = update.remove(&name) {
                        lua.remove_registry_value(k)?;
                    }
                }
                this.state.borrow_mut().add(&name);
                if let Some(tbl) = callbacks {
                    if let Ok(f) = tbl.get::<_, LuaFunction>("enter") {
                        this.enter_keys
                            .borrow_mut()
                            .insert(name.clone(), lua.create_registry_value(f)?);
                    }
                    if let Ok(f) = tbl.get::<_, LuaFunction>("exit") {
                        this.exit_keys
                            .borrow_mut()
                            .insert(name.clone(), lua.create_registry_value(f)?);
                    }
                    if let Ok(f) = tbl.get::<_, LuaFunction>("update") {
                        this.update_keys
                            .borrow_mut()
                            .insert(name.clone(), lua.create_registry_value(f)?);
                    }
                }
                Ok(())
            },
        );
        methods.add_method("transitionTo", |lua, this, name: String| {
            if !this.state.borrow().has(&name) {
                return Ok(false);
            }
            let current_opt = this.state.borrow().current().map(|s| s.to_string());
            if let Some(ref current) = current_opt {
                let func_opt = this
                    .exit_keys
                    .borrow()
                    .get(current.as_str())
                    .map(|k| lua.registry_value::<LuaFunction>(k));
                if let Some(Ok(func)) = func_opt {
                    func.call::<_, ()>(())?;
                }
            }
            this.state.borrow_mut().set_current(&name);
            let func_opt = this
                .enter_keys
                .borrow()
                .get(&name)
                .map(|k| lua.registry_value::<LuaFunction>(k));
            if let Some(Ok(func)) = func_opt {
                func.call::<_, ()>(())?;
            }
            Ok(true)
        });
        methods.add_method("update", |lua, this, dt: f64| {
            let current_opt = this.state.borrow().current().map(|s| s.to_string());
            if let Some(ref current) = current_opt {
                let func_opt = this
                    .update_keys
                    .borrow()
                    .get(current.as_str())
                    .map(|k| lua.registry_value::<LuaFunction>(k));
                if let Some(Ok(func)) = func_opt {
                    func.call::<_, ()>(dt)?;
                }
            }
            Ok(())
        });
        methods.add_method("getCurrent", |_lua, this, ()| {
            Ok(this.state.borrow().current().map(|s| s.to_string()))
        });
        methods.add_method("hasState", |_lua, this, name: String| {
            Ok(this.state.borrow().has(&name))
        });
        methods.add_method("getStates", |lua, this, ()| {
            let names: Vec<String> = this
                .state
                .borrow()
                .states()
                .iter()
                .map(|s| s.to_string())
                .collect();
            let table = lua.create_table()?;
            for (i, name) in names.iter().enumerate() {
                table.set(i + 1, name.as_str())?;
            }
            Ok(table)
        });
        methods.add_method("clearAll", |lua, this, ()| {
            *this.state.borrow_mut() = crate::patterns::SimpleState::new();
            for (_, key) in this.enter_keys.borrow_mut().drain() {
                lua.remove_registry_value(key)?;
            }
            for (_, key) in this.exit_keys.borrow_mut().drain() {
                lua.remove_registry_value(key)?;
            }
            for (_, key) in this.update_keys.borrow_mut().drain() {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
    }
}
#[derive(Clone)]
struct LuaBlackboard {
    board: Rc<RefCell<crate::patterns::Blackboard>>,
    watchers: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
    watcher_keys: Rc<RefCell<HashMap<u64, String>>>,
    next_watcher_id: Rc<RefCell<u64>>,
}
impl LurekType for LuaBlackboard {
    const TYPE_NAME: &'static str = "LBlackboard";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LBlackboard", "Object"];
}
impl LuaUserData for LuaBlackboard {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method("set", |lua, this, (key, value): (String, LuaValue)| {
            let prev_rev = this.board.borrow().revision;
            match &value {
                LuaValue::Boolean(b) => this.board.borrow_mut().set_bool(&key, *b),
                LuaValue::Integer(n) => this.board.borrow_mut().set_number(&key, *n as f64),
                LuaValue::Number(n) => this.board.borrow_mut().set_number(&key, *n),
                LuaValue::String(s) => this
                    .board
                    .borrow_mut()
                    .set_text(&key, s.to_str()?.to_string()),
                LuaValue::Nil => this.board.borrow_mut().clear(&key),
                _ => {
                    return Err(LuaError::external(
                        "Blackboard only supports bool/number/string/nil values",
                    ))
                }
            }
            let new_rev = this.board.borrow().revision;
            if new_rev != prev_rev {
                let sub_ids: Vec<u64> = {
                    let wk = this.watcher_keys.borrow();
                    wk.iter()
                        .filter(|(_, k)| k == &&key || k.as_str() == "*")
                        .map(|(id, _)| *id)
                        .collect()
                };
                for id in sub_ids {
                    let cb = this.watchers.borrow();
                    if let Some(rk) = cb.get(&id) {
                        let func: LuaFunction = lua.registry_value(rk)?;
                        drop(cb);
                        func.call::<_, ()>((key.clone(), value.clone()))?;
                    }
                }
            }
            Ok(())
        });
        methods.add_method("get", |lua, this, key: String| {
            match this.board.borrow().get(&key) {
                Some(crate::patterns::BlackboardValue::Bool(b)) => Ok(LuaValue::Boolean(*b)),
                Some(crate::patterns::BlackboardValue::Number(n)) => Ok(LuaValue::Number(*n)),
                Some(crate::patterns::BlackboardValue::Text(s)) => {
                    Ok(LuaValue::String(lua.create_string(s)?))
                }
                Some(crate::patterns::BlackboardValue::Nil) | None => Ok(LuaValue::Nil),
            }
        });
        methods.add_method("has", |_, this, key: String| {
            Ok(this.board.borrow().has(&key))
        });
        methods.add_method("clear", |_, this, key: String| {
            this.board.borrow_mut().clear(&key);
            Ok(())
        });
        methods.add_method("keys", |lua, this, ()| {
            let keys: Vec<String> = this
                .board
                .borrow()
                .keys()
                .iter()
                .map(|s| s.to_string())
                .collect();
            let tbl = lua.create_table()?;
            for (i, k) in keys.iter().enumerate() {
                tbl.set(i + 1, k.as_str())?;
            }
            Ok(tbl)
        });
        methods.add_method(
            "watch",
            |lua, this, (key, callback): (String, LuaFunction)| {
                let id = {
                    let mut nid = this.next_watcher_id.borrow_mut();
                    let id = *nid;
                    *nid += 1;
                    id
                };
                let rk = lua.create_registry_value(callback)?;
                this.watchers.borrow_mut().insert(id, rk);
                this.watcher_keys.borrow_mut().insert(id, key);
                Ok(id)
            },
        );
        methods.add_method("unwatch", |lua, this, id: u64| {
            if let Some(rk) = this.watchers.borrow_mut().remove(&id) {
                lua.remove_registry_value(rk)?;
            }
            this.watcher_keys.borrow_mut().remove(&id);
            Ok(())
        });
        methods.add_method("getRevision", |_, this, ()| {
            Ok(this.board.borrow().revision)
        });
        methods.add_method("snapshot", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (k, v) in this.board.borrow().snapshot() {
                match v {
                    crate::patterns::BlackboardValue::Bool(b) => tbl.set(k, *b)?,
                    crate::patterns::BlackboardValue::Number(n) => tbl.set(k, *n)?,
                    crate::patterns::BlackboardValue::Text(s) => tbl.set(k, s.as_str())?,
                    crate::patterns::BlackboardValue::Nil => {}
                }
            }
            Ok(tbl)
        });
        methods.add_method("clearAll", |_, this, ()| {
            this.board.borrow_mut().clear_all();
            Ok(())
        });
    }
}
#[derive(Clone)]
struct LuaObserver {
    observer: Rc<RefCell<crate::patterns::Observer>>,
    values: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
    callbacks: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
}
impl LurekType for LuaObserver {
    const TYPE_NAME: &'static str = "LObserver";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LObserver", "Object"];
}
impl LuaUserData for LuaObserver {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method("set", |lua, this, (key, new_val): (String, LuaValue)| {
            let rk = lua.create_registry_value(new_val.clone())?;
            if let Some(old_k) = this.values.borrow_mut().insert(key.clone(), rk) {
                lua.remove_registry_value(old_k)?;
            }
            let ids = this.observer.borrow_mut().watchers_for(&key);
            for id in ids {
                let cb = this.callbacks.borrow();
                if let Some(rk) = cb.get(&id) {
                    let func: LuaFunction = lua.registry_value(rk)?;
                    drop(cb);
                    func.call::<_, ()>((key.clone(), new_val.clone()))?;
                }
            }
            Ok(())
        });
        methods.add_method("get", |lua, this, key: String| {
            match this.values.borrow().get(&key) {
                Some(rk) => Ok(lua.registry_value::<LuaValue>(rk)?),
                None => Ok(LuaValue::Nil),
            }
        });
        methods.add_method(
            "subscribe",
            |lua, this, (key, callback, once): (String, LuaFunction, Option<bool>)| {
                let id = this
                    .observer
                    .borrow_mut()
                    .subscribe(&key, once.unwrap_or(false));
                let rk = lua.create_registry_value(callback)?;
                this.callbacks.borrow_mut().insert(id, rk);
                Ok(id)
            },
        );
        methods.add_method("unsubscribe", |lua, this, id: u64| {
            this.observer.borrow_mut().unsubscribe(id);
            if let Some(rk) = this.callbacks.borrow_mut().remove(&id) {
                lua.remove_registry_value(rk)?;
            }
            Ok(())
        });
        methods.add_method("getCount", |_, this, ()| {
            Ok(this.observer.borrow().subscription_count())
        });
    }
}
#[derive(Clone)]
struct LuaThrottle {
    throttle: Rc<RefCell<crate::patterns::Throttle>>,
    callback: Rc<RefCell<Option<LuaRegistryKey>>>,
}
impl LurekType for LuaThrottle {
    const TYPE_NAME: &'static str = "LThrottle";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LThrottle", "Object"];
}
impl LuaUserData for LuaThrottle {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method("onFire", |lua, this, f: LuaFunction| {
            let rk = lua.create_registry_value(f)?;
            if let Some(old) = this.callback.borrow_mut().replace(rk) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });
        methods.add_method("update", |lua, this, dt: f64| {
            let fired = this.throttle.borrow_mut().update(dt);
            if fired {
                if let Some(rk) = &*this.callback.borrow() {
                    let func: LuaFunction = lua.registry_value(rk)?;
                    func.call::<_, ()>(())?;
                }
            }
            Ok(fired)
        });
        methods.add_method("reset", |_, this, ()| {
            this.throttle.borrow_mut().reset();
            Ok(())
        });
        methods.add_method("getProgress", |_, this, ()| {
            Ok(this.throttle.borrow().progress())
        });
        methods.add_method("getFireCount", |_, this, ()| {
            Ok(this.throttle.borrow().fire_count)
        });
        methods.add_method("setEnabled", |_, this, v: bool| {
            this.throttle.borrow_mut().enabled = v;
            Ok(())
        });
    }
}
#[derive(Clone)]
struct LuaDebounce {
    debounce: Rc<RefCell<crate::patterns::Debounce>>,
    callback: Rc<RefCell<Option<LuaRegistryKey>>>,
}
impl LurekType for LuaDebounce {
    const TYPE_NAME: &'static str = "LDebounce";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LDebounce", "Object"];
}
impl LuaUserData for LuaDebounce {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method("onFire", |lua, this, f: LuaFunction| {
            let rk = lua.create_registry_value(f)?;
            if let Some(old) = this.callback.borrow_mut().replace(rk) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });
        methods.add_method("trigger", |_, this, ()| {
            this.debounce.borrow_mut().trigger();
            Ok(())
        });
        methods.add_method("update", |lua, this, dt: f64| {
            let fired = this.debounce.borrow_mut().update(dt);
            if fired {
                if let Some(rk) = &*this.callback.borrow() {
                    let func: LuaFunction = lua.registry_value(rk)?;
                    func.call::<_, ()>(())?;
                }
            }
            Ok(fired)
        });
        methods.add_method("cancel", |_, this, ()| {
            this.debounce.borrow_mut().cancel();
            Ok(())
        });
        methods.add_method("isPending", |_, this, ()| {
            Ok(this.debounce.borrow().pending)
        });
        methods.add_method("getFireCount", |_, this, ()| {
            Ok(this.debounce.borrow().fire_count)
        });
    }
}
#[derive(Clone)]
struct LuaPriorityQueue {
    queue: Rc<RefCell<crate::patterns::PriorityQueue>>,
    payloads: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
}
impl LurekType for LuaPriorityQueue {
    const TYPE_NAME: &'static str = "LPriorityQueue";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LPriorityQueue", "Object"];
}
impl LuaUserData for LuaPriorityQueue {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method(
            "push",
            |lua, this, (priority, value, label): (i64, LuaValue, Option<String>)| {
                let id = this
                    .queue
                    .borrow_mut()
                    .push(priority, label.as_deref().unwrap_or(""));
                let rk = lua.create_registry_value(value)?;
                this.payloads.borrow_mut().insert(id, rk);
                Ok(id)
            },
        );
        methods.add_method("pop", |lua, this, ()| match this.queue.borrow_mut().pop() {
            Some((id, _priority)) => {
                if let Some(rk) = this.payloads.borrow_mut().remove(&id) {
                    let val: LuaValue = lua.registry_value(&rk)?;
                    lua.remove_registry_value(rk)?;
                    Ok(val)
                } else {
                    Ok(LuaValue::Nil)
                }
            }
            None => Ok(LuaValue::Nil),
        });
        methods.add_method("peek", |lua, this, ()| match this.queue.borrow().peek() {
            Some(item) => {
                let id = item.id;
                let payloads = this.payloads.borrow();
                if let Some(rk) = payloads.get(&id) {
                    Ok(lua.registry_value::<LuaValue>(rk)?)
                } else {
                    Ok(LuaValue::Nil)
                }
            }
            None => Ok(LuaValue::Nil),
        });
        methods.add_method("len", |_, this, ()| Ok(this.queue.borrow().len()));
        methods.add_method("isEmpty", |_, this, ()| Ok(this.queue.borrow().is_empty()));
        methods.add_method("clearAll", |lua, this, ()| {
            this.queue.borrow_mut().clear();
            let drained: Vec<(u64, LuaRegistryKey)> = this.payloads.borrow_mut().drain().collect();
            for (_, rk) in drained {
                lua.remove_registry_value(rk)?;
            }
            Ok(())
        });
    }
}
#[derive(Clone)]
struct LuaRing {
    ring: Rc<RefCell<crate::patterns::Ring>>,
}
impl LurekType for LuaRing {
    const TYPE_NAME: &'static str = "LRing";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LRing", "Object"];
}
impl LuaUserData for LuaRing {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method(
            "push",
            |_, this, (value, tag): (LuaValue, Option<String>)| {
                let tag = tag.as_deref().unwrap_or("");
                let id = match &value {
                    LuaValue::Integer(n) => this.ring.borrow_mut().push_number(*n as f64, tag),
                    LuaValue::Number(n) => this.ring.borrow_mut().push_number(*n, tag),
                    LuaValue::String(s) => this
                        .ring
                        .borrow_mut()
                        .push_string(s.to_str()?.to_string(), tag),
                    _ => {
                        return Err(LuaError::external(
                            "Ring only accepts number or string values",
                        ))
                    }
                };
                Ok(id)
            },
        );
        methods.add_method("latest", |lua, this, ()| {
            match this.ring.borrow().latest() {
                Some(e) => {
                    let t = lua.create_table()?;
                    t.set("id", e.id)?;
                    t.set("tag", e.tag.as_str())?;
                    if let Some(n) = e.value_f64 {
                        t.set("value", n)?;
                    }
                    if let Some(s) = &e.value_str {
                        t.set("text", s.as_str())?;
                    }
                    Ok(LuaValue::Table(t))
                }
                None => Ok(LuaValue::Nil),
            }
        });
        methods.add_method("toArray", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, e) in this.ring.borrow().iter().enumerate() {
                let t = lua.create_table()?;
                t.set("id", e.id)?;
                t.set("tag", e.tag.as_str())?;
                if let Some(n) = e.value_f64 {
                    t.set("value", n)?;
                }
                if let Some(s) = &e.value_str {
                    t.set("text", s.as_str())?;
                }
                tbl.set(i + 1, t)?;
            }
            Ok(tbl)
        });
        methods.add_method("sum", |_, this, ()| Ok(this.ring.borrow().sum()));
        methods.add_method("average", |_, this, ()| Ok(this.ring.borrow().average()));
        methods.add_method("len", |_, this, ()| Ok(this.ring.borrow().len()));
        methods.add_method("isFull", |_, this, ()| Ok(this.ring.borrow().is_full()));
        methods.add_method("clear", |_, this, ()| {
            this.ring.borrow_mut().clear();
            Ok(())
        });
    }
}
#[derive(Clone)]
struct LuaFunnel {
    funnel: Rc<RefCell<crate::patterns::Funnel>>,
    on_flush: Rc<RefCell<Option<LuaRegistryKey>>>,
}
impl LurekType for LuaFunnel {
    const TYPE_NAME: &'static str = "LFunnel";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LFunnel", "Object"];
}
impl LuaUserData for LuaFunnel {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method("onFlush", |lua, this, f: LuaFunction| {
            let rk = lua.create_registry_value(f)?;
            if let Some(old) = this.on_flush.borrow_mut().replace(rk) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });
        methods.add_method("push", |lua, this, (tag, value): (String, Option<f64>)| {
            let (_, should_flush) = this.funnel.borrow_mut().push(&tag, value.unwrap_or(0.0));
            if should_flush {
                Self::do_flush(lua, this)?;
            }
            Ok(())
        });
        methods.add_method("update", |lua, this, dt: f64| {
            let should_flush = this.funnel.borrow_mut().update(dt);
            if should_flush {
                Self::do_flush(lua, this)?;
                return Ok(true);
            }
            Ok(false)
        });
        methods.add_method("flush", |lua, this, ()| Self::do_flush(lua, this));
        methods.add_method("discard", |_, this, ()| {
            this.funnel.borrow_mut().discard();
            Ok(())
        });
        methods.add_method("pendingCount", |_, this, ()| {
            Ok(this.funnel.borrow().pending_count())
        });
        methods.add_method("getFlushCount", |_, this, ()| {
            Ok(this.funnel.borrow().flush_count)
        });
    }
}
impl LuaFunnel {
    fn do_flush(lua: &Lua, this: &LuaFunnel) -> LuaResult<()> {
        let entries = this.funnel.borrow_mut().flush();
        if entries.is_empty() {
            return Ok(());
        }
        if let Some(rk) = &*this.on_flush.borrow() {
            let func: LuaFunction = lua.registry_value(rk)?;
            let tbl = lua.create_table()?;
            for (i, e) in entries.iter().enumerate() {
                let et = lua.create_table()?;
                et.set("tag", e.tag.as_str())?;
                et.set("value", e.value)?;
                tbl.set(i + 1, et)?;
            }
            func.call::<_, ()>(tbl)?;
        }
        Ok(())
    }
}
#[derive(Clone)]
struct LuaRelationshipManager {
    rm: Rc<RefCell<crate::ecs::RelationshipManager>>,
}
impl LurekType for LuaRelationshipManager {
    const TYPE_NAME: &'static str = "LRelationshipManager";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LRelationshipManager", "Object"];
}
impl LuaUserData for LuaRelationshipManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method(
            "defineType",
            |_, this, (name, levels, default_level): (String, LuaTable, Option<String>)| {
                let lvs: Vec<String> = levels
                    .sequence_values::<String>()
                    .collect::<LuaResult<_>>()?;
                this.rm.borrow_mut().define_type(
                    &name,
                    lvs,
                    default_level.as_deref().unwrap_or(""),
                );
                Ok(())
            },
        );
        methods.add_method("removeType", |_, this, name: String| {
            this.rm.borrow_mut().remove_type(&name);
            Ok(())
        });
        methods.add_method("typeNames", |_, this, ()| Ok(this.rm.borrow().type_names()));
        methods.add_method("setValue", |_, this, (a, b, value): (u32, u32, f64)| {
            this.rm.borrow_mut().set_value(a, b, value);
            Ok(())
        });
        methods.add_method("getValue", |_, this, (a, b): (u32, u32)| {
            Ok(this.rm.borrow().get_value(a, b))
        });
        methods.add_method("adjustValue", |_, this, (a, b, delta): (u32, u32, f64)| {
            this.rm.borrow_mut().adjust_value(a, b, delta);
            Ok(())
        });
        methods.add_method(
            "setLevel",
            |_, this, (a, b, type_name, level): (u32, u32, String, String)| {
                Ok(this.rm.borrow_mut().set_level(a, b, &type_name, &level))
            },
        );
        methods.add_method(
            "getLevel",
            |_, this, (a, b, type_name): (u32, u32, String)| {
                Ok(this.rm.borrow().get_level(a, b, &type_name))
            },
        );
        methods.add_method("removePair", |_, this, (a, b): (u32, u32)| {
            this.rm.borrow_mut().remove_relation(a, b);
            Ok(())
        });
        methods.add_method("pairCount", |_, this, ()| {
            Ok(this.rm.borrow().relation_count())
        });
    }
}
#[derive(Clone)]
struct LuaMediator {
    mediator: Rc<RefCell<crate::patterns::Mediator>>,
    callbacks: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
}
impl LurekType for LuaMediator {
    const TYPE_NAME: &'static str = "LMediator";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LMediator", "Object"];
}
impl LuaUserData for LuaMediator {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method(
            "on",
            |lua, this, (channel, callback): (String, LuaFunction)| {
                let id = this.mediator.borrow_mut().register(&channel);
                let key = lua.create_registry_value(callback)?;
                this.callbacks.borrow_mut().insert(id, key);
                Ok(id)
            },
        );
        methods.add_method("off", |lua, this, (channel, id): (String, u64)| {
            this.mediator.borrow_mut().unregister(&channel, id);
            if let Some(key) = this.callbacks.borrow_mut().remove(&id) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        methods.add_method("send", |lua, this, args: LuaMultiValue| {
            let mut iter = args.into_iter();
            let channel: String = match iter.next() {
                Some(LuaValue::String(s)) => s.to_str()?.to_string(),
                _ => return Err(LuaError::runtime("send() requires a channel name")),
            };
            let extra: Vec<LuaValue> = iter.collect();
            let ids = this.mediator.borrow().get_handlers(&channel);
            for id in &ids {
                let cbs = this.callbacks.borrow();
                if let Some(key) = cbs.get(id) {
                    let f: LuaFunction = lua.registry_value(key)?;
                    drop(cbs);
                    f.call::<_, ()>(LuaMultiValue::from_vec(extra.clone()))?;
                }
            }
            Ok(())
        });
        methods.add_method("broadcast", |lua, this, args: LuaMultiValue| {
            let extra: Vec<LuaValue> = args.into_iter().collect();
            let names = this.mediator.borrow().channel_names();
            for channel in &names {
                let ids = this.mediator.borrow().get_handlers(channel);
                for id in &ids {
                    let cbs = this.callbacks.borrow();
                    if let Some(key) = cbs.get(id) {
                        let f: LuaFunction = lua.registry_value(key)?;
                        drop(cbs);
                        f.call::<_, ()>(LuaMultiValue::from_vec(extra.clone()))?;
                    }
                }
            }
            Ok(())
        });
        methods.add_method("handlerCount", |_, this, channel: String| {
            Ok(this.mediator.borrow().handler_count(&channel))
        });
        methods.add_method("channels", |_, this, ()| {
            Ok(this.mediator.borrow().channel_names())
        });
        methods.add_method("removeChannel", |lua, this, channel: String| {
            let ids = this.mediator.borrow().get_handlers(&channel);
            this.mediator.borrow_mut().remove_channel(&channel);
            let mut cbs = this.callbacks.borrow_mut();
            for id in &ids {
                if let Some(key) = cbs.remove(id) {
                    lua.remove_registry_value(key)?;
                }
            }
            Ok(())
        });
        methods.add_method("clear", |lua, this, ()| {
            this.mediator.borrow_mut().clear();
            let mut cbs = this.callbacks.borrow_mut();
            for (_, key) in cbs.drain() {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
    }
}
#[derive(Clone)]
struct LuaStrategy {
    strategy: Rc<RefCell<crate::patterns::Strategy>>,
    callbacks: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
}
impl LurekType for LuaStrategy {
    const TYPE_NAME: &'static str = "LStrategy";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LStrategy", "Object"];
}
impl LuaUserData for LuaStrategy {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method(
            "register",
            |lua, this, (name, callback): (String, LuaFunction)| {
                let id = this.strategy.borrow_mut().register(&name);
                let key = lua.create_registry_value(callback)?;
                this.callbacks.borrow_mut().insert(id, key);
                Ok(())
            },
        );
        methods.add_method("set", |_, this, name: String| {
            Ok(this.strategy.borrow_mut().set_current(&name))
        });
        methods.add_method("execute", |lua, this, args: LuaMultiValue| {
            let id = match this.strategy.borrow().get_current_id() {
                Some(id) => id,
                None => return Err(LuaError::runtime("No strategy selected")),
            };
            let cbs = this.callbacks.borrow();
            let key = cbs
                .get(&id)
                .ok_or_else(|| LuaError::runtime("Strategy function missing"))?;
            let f: LuaFunction = lua.registry_value(key)?;
            drop(cbs);
            f.call::<_, LuaMultiValue>(args)
        });
        methods.add_method("getCurrent", |_, this, ()| {
            Ok(this.strategy.borrow().get_current().map(|s| s.to_string()))
        });
        methods.add_method("has", |_, this, name: String| {
            Ok(this.strategy.borrow().has(&name))
        });
        methods.add_method("remove", |lua, this, name: String| {
            let id = {
                let st = this.strategy.borrow();
                if st.has(&name) {
                    st.get_current_id()
                } else {
                    return Ok(false);
                }
            };
            let removed = this.strategy.borrow_mut().remove(&name);
            if removed {
                if let Some(id) = id {
                    if let Some(key) = this.callbacks.borrow_mut().remove(&id) {
                        lua.remove_registry_value(key)?;
                    }
                }
            }
            Ok(removed)
        });
        methods.add_method("names", |_, this, ()| Ok(this.strategy.borrow().names()));
        methods.add_method("clear", |lua, this, ()| {
            this.strategy.borrow_mut().clear();
            let mut cbs = this.callbacks.borrow_mut();
            for (_, key) in cbs.drain() {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
    }
}
#[derive(Clone)]
struct LuaStack {
    meta: crate::patterns::StackMeta,
    items: Rc<RefCell<Vec<LuaRegistryKey>>>,
}
impl LurekType for LuaStack {
    const TYPE_NAME: &'static str = "LStack";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LStack", "Object"];
}
impl LuaUserData for LuaStack {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method("push", |lua, this, value: LuaValue| {
            let len = this.items.borrow().len();
            if this.meta.is_full(len) {
                return Ok(false);
            }
            let key = lua.create_registry_value(value)?;
            this.items.borrow_mut().push(key);
            Ok(true)
        });
        methods.add_method("pushBottom", |lua, this, value: LuaValue| {
            let len = this.items.borrow().len();
            if this.meta.is_full(len) {
                return Ok(false);
            }
            let key = lua.create_registry_value(value)?;
            this.items.borrow_mut().insert(0, key);
            Ok(true)
        });
        methods.add_method("pop", |lua, this, ()| {
            if let Some(key) = this.items.borrow_mut().pop() {
                let v: LuaValue = lua.registry_value(&key)?;
                lua.remove_registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        methods.add_method("popBottom", |lua, this, ()| {
            if this.items.borrow().is_empty() {
                return Ok(LuaValue::Nil);
            }
            let key = this.items.borrow_mut().remove(0);
            let v: LuaValue = lua.registry_value(&key)?;
            lua.remove_registry_value(key)?;
            Ok(v)
        });
        methods.add_method("popMany", |lua, this, count: usize| {
            let out = lua.create_table()?;
            let n = count.min(this.items.borrow().len());
            for i in 1..=n {
                if let Some(key) = this.items.borrow_mut().pop() {
                    let v: LuaValue = lua.registry_value(&key)?;
                    lua.remove_registry_value(key)?;
                    out.set(i, v)?;
                }
            }
            Ok(out)
        });
        methods.add_method("peek", |lua, this, ()| {
            if let Some(key) = this.items.borrow().last() {
                let v: LuaValue = lua.registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        methods.add_method("peekBottom", |lua, this, ()| {
            if let Some(key) = this.items.borrow().first() {
                let v: LuaValue = lua.registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        methods.add_method("peekAt", |lua, this, index: usize| {
            if index == 0 {
                return Ok(LuaValue::Nil);
            }
            if let Some(key) = this.items.borrow().get(index - 1) {
                let v: LuaValue = lua.registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        methods.add_method(
            "insertAt",
            |lua, this, (index, value): (usize, LuaValue)| {
                let len = this.items.borrow().len();
                if this.meta.is_full(len) {
                    return Ok(false);
                }
                let idx = if index == 0 { 0 } else { (index - 1).min(len) };
                let key = lua.create_registry_value(value)?;
                this.items.borrow_mut().insert(idx, key);
                Ok(true)
            },
        );
        methods.add_method("removeAt", |lua, this, index: usize| {
            if index == 0 || index > this.items.borrow().len() {
                return Ok(LuaValue::Nil);
            }
            let key = this.items.borrow_mut().remove(index - 1);
            let v: LuaValue = lua.registry_value(&key)?;
            lua.remove_registry_value(key)?;
            Ok(v)
        });
        methods.add_method("moveWithin", |_, this, (from, to): (usize, usize)| {
            let len = this.items.borrow().len();
            if from == 0 || to == 0 || from > len || to > len {
                return Ok(false);
            }
            let mut items = this.items.borrow_mut();
            let key = items.remove(from - 1);
            items.insert(to - 1, key);
            Ok(true)
        });
        methods.add_method("len", |_, this, ()| Ok(this.items.borrow().len()));
        methods.add_method("isEmpty", |_, this, ()| Ok(this.items.borrow().is_empty()));
        methods.add_method("isFull", |_, this, ()| {
            Ok(this.meta.is_full(this.items.borrow().len()))
        });
        methods.add_method("clear", |lua, this, ()| {
            let mut items = this.items.borrow_mut();
            for key in items.drain(..) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        methods.add_method("toArray", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, key) in this.items.borrow().iter().enumerate() {
                let v: LuaValue = lua.registry_value(key)?;
                tbl.set(i + 1, v)?;
            }
            Ok(tbl)
        });
    }
}
#[derive(Clone)]
struct LuaQueue {
    meta: crate::patterns::QueueMeta,
    items: Rc<RefCell<VecDeque<LuaRegistryKey>>>,
}
impl LurekType for LuaQueue {
    const TYPE_NAME: &'static str = "LQueue";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LQueue", "Object"];
}
impl LuaUserData for LuaQueue {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method("enqueue", |lua, this, value: LuaValue| {
            let len = this.items.borrow().len();
            if this.meta.is_full(len) {
                return Ok(false);
            }
            let key = lua.create_registry_value(value)?;
            this.items.borrow_mut().push_back(key);
            Ok(true)
        });
        methods.add_method("enqueueFront", |lua, this, value: LuaValue| {
            let len = this.items.borrow().len();
            if this.meta.is_full(len) {
                return Ok(false);
            }
            let key = lua.create_registry_value(value)?;
            this.items.borrow_mut().push_front(key);
            Ok(true)
        });
        methods.add_method("dequeue", |lua, this, ()| {
            if let Some(key) = this.items.borrow_mut().pop_front() {
                let v: LuaValue = lua.registry_value(&key)?;
                lua.remove_registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        methods.add_method("dequeueBack", |lua, this, ()| {
            if let Some(key) = this.items.borrow_mut().pop_back() {
                let v: LuaValue = lua.registry_value(&key)?;
                lua.remove_registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        methods.add_method("front", |lua, this, ()| {
            if let Some(key) = this.items.borrow().front() {
                let v: LuaValue = lua.registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        methods.add_method("back", |lua, this, ()| {
            if let Some(key) = this.items.borrow().back() {
                let v: LuaValue = lua.registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        methods.add_method("peekAt", |lua, this, index: usize| {
            if index == 0 {
                return Ok(LuaValue::Nil);
            }
            if let Some(key) = this.items.borrow().get(index - 1) {
                let v: LuaValue = lua.registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        methods.add_method(
            "insertAt",
            |lua, this, (index, value): (usize, LuaValue)| {
                let len = this.items.borrow().len();
                if this.meta.is_full(len) {
                    return Ok(false);
                }
                let idx = if index == 0 { 0 } else { (index - 1).min(len) };
                let key = lua.create_registry_value(value)?;
                this.items.borrow_mut().insert(idx, key);
                Ok(true)
            },
        );
        methods.add_method("removeAt", |lua, this, index: usize| {
            if index == 0 || index > this.items.borrow().len() {
                return Ok(LuaValue::Nil);
            }
            if let Some(key) = this.items.borrow_mut().remove(index - 1) {
                let v: LuaValue = lua.registry_value(&key)?;
                lua.remove_registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        methods.add_method("len", |_, this, ()| Ok(this.items.borrow().len()));
        methods.add_method("isEmpty", |_, this, ()| Ok(this.items.borrow().is_empty()));
        methods.add_method("isFull", |_, this, ()| {
            Ok(this.meta.is_full(this.items.borrow().len()))
        });
        methods.add_method("clear", |lua, this, ()| {
            let mut items = this.items.borrow_mut();
            for key in items.drain(..) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        methods.add_method("toArray", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, key) in this.items.borrow().iter().enumerate() {
                let v: LuaValue = lua.registry_value(key)?;
                tbl.set(i + 1, v)?;
            }
            Ok(tbl)
        });
    }
}
#[derive(Clone)]
struct LuaList {
    items: Rc<RefCell<Vec<LuaRegistryKey>>>,
}
impl LurekType for LuaList {
    const TYPE_NAME: &'static str = "LList";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LList", "Object"];
}
impl LuaUserData for LuaList {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method("add", |lua, this, value: LuaValue| {
            let key = lua.create_registry_value(value)?;
            this.items.borrow_mut().push(key);
            Ok(())
        });
        methods.add_method("push", |lua, this, value: LuaValue| {
            let key = lua.create_registry_value(value)?;
            this.items.borrow_mut().push(key);
            Ok(())
        });
        methods.add_method("unshift", |lua, this, value: LuaValue| {
            let key = lua.create_registry_value(value)?;
            this.items.borrow_mut().insert(0, key);
            Ok(())
        });
        methods.add_method("get", |lua, this, index: usize| {
            if index == 0 {
                return Ok(LuaValue::Nil);
            }
            let items = this.items.borrow();
            if let Some(key) = items.get(index - 1) {
                let v: LuaValue = lua.registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        methods.add_method("set", |lua, this, (index, value): (usize, LuaValue)| {
            if index == 0 {
                return Err(LuaError::runtime("list index must be >= 1"));
            }
            let mut items = this.items.borrow_mut();
            if index > items.len() {
                return Err(LuaError::runtime("list index out of range"));
            }
            let old_key =
                std::mem::replace(&mut items[index - 1], lua.create_registry_value(value)?);
            lua.remove_registry_value(old_key)?;
            Ok(())
        });
        methods.add_method("insert", |lua, this, (index, value): (usize, LuaValue)| {
            let len = this.items.borrow().len();
            let idx = if index == 0 { 0 } else { (index - 1).min(len) };
            let key = lua.create_registry_value(value)?;
            this.items.borrow_mut().insert(idx, key);
            Ok(())
        });
        methods.add_method("remove", |lua, this, index: usize| {
            if index == 0 {
                return Ok(LuaValue::Nil);
            }
            let mut items = this.items.borrow_mut();
            if index > items.len() {
                return Ok(LuaValue::Nil);
            }
            let key = items.remove(index - 1);
            let v: LuaValue = lua.registry_value(&key)?;
            lua.remove_registry_value(key)?;
            Ok(v)
        });
        methods.add_method("pop", |lua, this, ()| {
            if let Some(key) = this.items.borrow_mut().pop() {
                let v: LuaValue = lua.registry_value(&key)?;
                lua.remove_registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        methods.add_method("shift", |lua, this, ()| {
            if this.items.borrow().is_empty() {
                return Ok(LuaValue::Nil);
            }
            let key = this.items.borrow_mut().remove(0);
            let v: LuaValue = lua.registry_value(&key)?;
            lua.remove_registry_value(key)?;
            Ok(v)
        });
        methods.add_method("indexOf", |lua, this, value: LuaValue| {
            for (i, key) in this.items.borrow().iter().enumerate() {
                let v: LuaValue = lua.registry_value(key)?;
                if lua.pack(v.clone())? == lua.pack(value.clone())? {
                    return Ok(Some(i + 1));
                }
            }
            Ok(None::<usize>)
        });
        methods.add_method("reverse", |_, this, ()| {
            this.items.borrow_mut().reverse();
            Ok(())
        });
        methods.add_method("len", |_, this, ()| Ok(this.items.borrow().len()));
        methods.add_method("isEmpty", |_, this, ()| Ok(this.items.borrow().is_empty()));
        methods.add_method("contains", |lua, this, value: LuaValue| {
            for key in this.items.borrow().iter() {
                let v: LuaValue = lua.registry_value(key)?;
                if lua.pack(v.clone())? == lua.pack(value.clone())? {
                    return Ok(true);
                }
            }
            Ok(false)
        });
        methods.add_method("clear", |lua, this, ()| {
            let mut items = this.items.borrow_mut();
            for key in items.drain(..) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        methods.add_method("toArray", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, key) in this.items.borrow().iter().enumerate() {
                let v: LuaValue = lua.registry_value(key)?;
                tbl.set(i + 1, v)?;
            }
            Ok(tbl)
        });
    }
}
#[derive(Clone)]
struct LuaSet {
    items: Rc<RefCell<HashSet<String>>>,
}
impl LurekType for LuaSet {
    const TYPE_NAME: &'static str = "LSet";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LSet", "Object"];
}
impl LuaUserData for LuaSet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method("add", |_, this, key: String| {
            Ok(this.items.borrow_mut().insert(key))
        });
        methods.add_method("remove", |_, this, key: String| {
            Ok(this.items.borrow_mut().remove(&key))
        });
        methods.add_method("has", |_, this, key: String| {
            Ok(this.items.borrow().contains(&key))
        });
        methods.add_method("len", |_, this, ()| Ok(this.items.borrow().len()));
        methods.add_method("isEmpty", |_, this, ()| Ok(this.items.borrow().is_empty()));
        methods.add_method("toArray", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, k) in this.items.borrow().iter().enumerate() {
                tbl.set(i + 1, k.as_str())?;
            }
            Ok(tbl)
        });
        methods.add_method("clear", |_, this, ()| {
            this.items.borrow_mut().clear();
            Ok(())
        });
        methods.add_method("union", |_, this, other: LuaAnyUserData| {
            let other_set = other.borrow::<LuaSet>()?;
            let mut merged = this.items.borrow().clone();
            for k in other_set.items.borrow().iter() {
                merged.insert(k.clone());
            }
            Ok(LuaSet {
                items: Rc::new(RefCell::new(merged)),
            })
        });
        methods.add_method("intersection", |_, this, other: LuaAnyUserData| {
            let other_set = other.borrow::<LuaSet>()?;
            let a = this.items.borrow();
            let b = other_set.items.borrow();
            let inter: HashSet<String> = a.intersection(&*b).cloned().collect();
            Ok(LuaSet {
                items: Rc::new(RefCell::new(inter)),
            })
        });
    }
}
#[derive(Clone)]
struct LuaMap {
    items: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
}
impl LurekType for LuaMap {
    const TYPE_NAME: &'static str = "LMap";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LMap", "Object"];
}
impl LuaUserData for LuaMap {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method("set", |lua, this, (key, value): (String, LuaValue)| {
            let rk = lua.create_registry_value(value)?;
            if let Some(old) = this.items.borrow_mut().insert(key, rk) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });
        methods.add_method("get", |lua, this, key: String| {
            let items = this.items.borrow();
            match items.get(&key) {
                Some(rk) => Ok(lua.registry_value::<LuaValue>(rk)?),
                None => Ok(LuaValue::Nil),
            }
        });
        methods.add_method("has", |_, this, key: String| {
            Ok(this.items.borrow().contains_key(&key))
        });
        methods.add_method("remove", |lua, this, key: String| {
            if let Some(rk) = this.items.borrow_mut().remove(&key) {
                lua.remove_registry_value(rk)?;
                Ok(true)
            } else {
                Ok(false)
            }
        });
        methods.add_method("len", |_, this, ()| Ok(this.items.borrow().len()));
        methods.add_method("isEmpty", |_, this, ()| Ok(this.items.borrow().is_empty()));
        methods.add_method("keys", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, k) in this.items.borrow().keys().enumerate() {
                tbl.set(i + 1, k.as_str())?;
            }
            Ok(tbl)
        });
        methods.add_method("values", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, rk) in this.items.borrow().values().enumerate() {
                let v: LuaValue = lua.registry_value(rk)?;
                tbl.set(i + 1, v)?;
            }
            Ok(tbl)
        });
        methods.add_method("entries", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, (k, rk)) in this.items.borrow().iter().enumerate() {
                let row = lua.create_table()?;
                row.set("key", k.as_str())?;
                row.set("value", lua.registry_value::<LuaValue>(rk)?)?;
                tbl.set(i + 1, row)?;
            }
            Ok(tbl)
        });
        methods.add_method("merge", |lua, this, other: LuaAnyUserData| {
            let other_map = other.borrow::<LuaMap>()?;
            for (k, rk) in other_map.items.borrow().iter() {
                let v: LuaValue = lua.registry_value(rk)?;
                let nk = lua.create_registry_value(v)?;
                if let Some(old) = this.items.borrow_mut().insert(k.clone(), nk) {
                    lua.remove_registry_value(old)?;
                }
            }
            Ok(())
        });
        methods.add_method("clear", |lua, this, ()| {
            let drained: Vec<(String, LuaRegistryKey)> = this.items.borrow_mut().drain().collect();
            for (_, rk) in drained {
                lua.remove_registry_value(rk)?;
            }
            Ok(())
        });
    }
}
#[derive(Clone)]
struct LuaWeightedRandom {
    pool: Rc<RefCell<crate::patterns::WeightedRandom>>,
    payloads: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
}
impl LurekType for LuaWeightedRandom {
    const TYPE_NAME: &'static str = "LWeightedRandom";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LWeightedRandom", "Object"];
}
impl LuaUserData for LuaWeightedRandom {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method(
            "add",
            |lua, this, (weight, value, label): (f64, LuaValue, Option<String>)| {
                let id = this
                    .pool
                    .borrow_mut()
                    .add(weight, label.as_deref().unwrap_or(""));
                let rk = lua.create_registry_value(value)?;
                this.payloads.borrow_mut().insert(id, rk);
                Ok(id)
            },
        );
        methods.add_method("remove", |lua, this, id: u64| {
            let removed = this.pool.borrow_mut().remove(id);
            if removed {
                if let Some(rk) = this.payloads.borrow_mut().remove(&id) {
                    lua.remove_registry_value(rk)?;
                }
            }
            Ok(removed)
        });
        methods.add_method("setWeight", |_, this, (id, weight): (u64, f64)| {
            Ok(this.pool.borrow_mut().set_weight(id, weight))
        });
        methods.add_method("pick", |lua, this, sample: f64| {
            match this.pool.borrow().pick(sample) {
                Some(id) => {
                    let payloads = this.payloads.borrow();
                    match payloads.get(&id) {
                        Some(rk) => Ok(lua.registry_value::<LuaValue>(rk)?),
                        None => Ok(LuaValue::Nil),
                    }
                }
                None => Ok(LuaValue::Nil),
            }
        });
        methods.add_method("pickN", |lua, this, (count, samples): (usize, LuaTable)| {
            let svec: Vec<f64> = samples.sequence_values::<f64>().collect::<LuaResult<_>>()?;
            let ids = this.pool.borrow().pick_n(count, &svec);
            let tbl = lua.create_table()?;
            for (i, id) in ids.iter().enumerate() {
                let payloads = this.payloads.borrow();
                let val = match payloads.get(id) {
                    Some(rk) => lua.registry_value::<LuaValue>(rk)?,
                    None => LuaValue::Nil,
                };
                tbl.set(i + 1, val)?;
            }
            Ok(tbl)
        });
        methods.add_method("totalWeight", |_, this, ()| {
            Ok(this.pool.borrow().total_weight())
        });
        methods.add_method("len", |_, this, ()| Ok(this.pool.borrow().len()));
        methods.add_method("isEmpty", |_, this, ()| Ok(this.pool.borrow().is_empty()));
        methods.add_method("clearAll", |lua, this, ()| {
            this.pool.borrow_mut().clear();
            let drained: Vec<(u64, LuaRegistryKey)> = this.payloads.borrow_mut().drain().collect();
            for (_, rk) in drained {
                lua.remove_registry_value(rk)?;
            }
            Ok(())
        });
        methods.add_method("getRevision", |_, this, ()| Ok(this.pool.borrow().revision));
    }
}
#[derive(Clone)]
struct LuaBehaviorTree {
    tree: Rc<RefCell<crate::patterns::BehaviorTree>>,
    run_state: Rc<RefCell<crate::patterns::BtRunState>>,
    leaf_fns: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
}
impl LurekType for LuaBehaviorTree {
    const TYPE_NAME: &'static str = "LBehaviorTree";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LBehaviorTree", "Object"];
}
impl LuaUserData for LuaBehaviorTree {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method("addSequence", |_, this, label: Option<String>| {
            Ok(this
                .tree
                .borrow_mut()
                .add_sequence(label.as_deref().unwrap_or("")))
        });
        methods.add_method("addSelector", |_, this, label: Option<String>| {
            Ok(this
                .tree
                .borrow_mut()
                .add_selector(label.as_deref().unwrap_or("")))
        });
        methods.add_method(
            "addParallel",
            |_, this, (min_success, label): (usize, Option<String>)| {
                Ok(this
                    .tree
                    .borrow_mut()
                    .add_parallel(min_success, label.as_deref().unwrap_or("")))
            },
        );
        methods.add_method("addInverter", |_, this, label: Option<String>| {
            Ok(this
                .tree
                .borrow_mut()
                .add_inverter(label.as_deref().unwrap_or("")))
        });
        methods.add_method(
            "addRepeat",
            |_, this, (count, label): (usize, Option<String>)| {
                Ok(this
                    .tree
                    .borrow_mut()
                    .add_repeat(count, label.as_deref().unwrap_or("")))
            },
        );
        methods.add_method(
            "addLeaf",
            |_, this, (name, label): (String, Option<String>)| {
                Ok(this
                    .tree
                    .borrow_mut()
                    .add_leaf(&name, label.as_deref().unwrap_or("")))
            },
        );
        methods.add_method("addChild", |_, this, (parent_id, child_id): (u32, u32)| {
            Ok(this.tree.borrow_mut().add_child(parent_id, child_id))
        });
        methods.add_method("setRoot", |_, this, id: u32| {
            Ok(this.tree.borrow_mut().set_root(id))
        });
        methods.add_method(
            "setLeaf",
            |lua, this, (name, callback): (String, LuaFunction)| {
                let rk = lua.create_registry_value(callback)?;
                if let Some(old) = this.leaf_fns.borrow_mut().insert(name, rk) {
                    lua.remove_registry_value(old)?;
                }
                Ok(())
            },
        );
        methods.add_method("tick", |lua, this, ()| {
            let root = match this.tree.borrow().root {
                Some(id) => id,
                None => return Ok("failure"),
            };
            let result = Self::tick_node(lua, this, root)?;
            Ok(match result {
                crate::patterns::BtStatus::Success => "success",
                crate::patterns::BtStatus::Failure => "failure",
                crate::patterns::BtStatus::Running => "running",
            })
        });
        methods.add_method("resetState", |_, this, ()| {
            this.run_state.borrow_mut().reset();
            Ok(())
        });
        methods.add_method("nodeCount", |_, this, ()| {
            Ok(this.tree.borrow().node_count())
        });
        methods.add_method("clearAll", |lua, this, ()| {
            this.tree.borrow_mut().clear();
            this.run_state.borrow_mut().reset();
            let drained: Vec<(String, LuaRegistryKey)> =
                this.leaf_fns.borrow_mut().drain().collect();
            for (_, rk) in drained {
                lua.remove_registry_value(rk)?;
            }
            Ok(())
        });
    }
}
impl LuaBehaviorTree {
    fn tick_node(
        lua: &Lua,
        this: &LuaBehaviorTree,
        id: crate::patterns::NodeId,
    ) -> LuaResult<crate::patterns::BtStatus> {
        use crate::patterns::{BtStatus, NodeKind};
        let (kind, children) = {
            let t = this.tree.borrow();
            let node = match t.get_node(id) {
                Some(n) => n,
                None => return Ok(BtStatus::Failure),
            };
            (node.kind.clone(), node.children.clone())
        };
        match kind {
            NodeKind::Sequence => {
                for child in children {
                    match Self::tick_node(lua, this, child)? {
                        BtStatus::Success => continue,
                        other => return Ok(other),
                    }
                }
                Ok(BtStatus::Success)
            }
            NodeKind::Selector => {
                for child in children {
                    match Self::tick_node(lua, this, child)? {
                        BtStatus::Failure => continue,
                        other => return Ok(other),
                    }
                }
                Ok(BtStatus::Failure)
            }
            NodeKind::Parallel { min_success } => {
                let mut successes = 0usize;
                let mut any_running = false;
                for child in &children {
                    match Self::tick_node(lua, this, *child)? {
                        BtStatus::Success => successes += 1,
                        BtStatus::Running => any_running = true,
                        BtStatus::Failure => {}
                    }
                }
                if successes >= min_success {
                    Ok(BtStatus::Success)
                } else if any_running {
                    Ok(BtStatus::Running)
                } else {
                    Ok(BtStatus::Failure)
                }
            }
            NodeKind::Inverter => {
                let child = match children.first() {
                    Some(&c) => c,
                    None => return Ok(BtStatus::Failure),
                };
                Ok(match Self::tick_node(lua, this, child)? {
                    BtStatus::Success => BtStatus::Failure,
                    BtStatus::Failure => BtStatus::Success,
                    BtStatus::Running => BtStatus::Running,
                })
            }
            NodeKind::Repeat { count } => {
                let child = match children.first() {
                    Some(&c) => c,
                    None => return Ok(BtStatus::Failure),
                };
                let iterations = count.max(1);
                for _ in 0..iterations {
                    match Self::tick_node(lua, this, child)? {
                        BtStatus::Failure => return Ok(BtStatus::Failure),
                        BtStatus::Running => return Ok(BtStatus::Running),
                        BtStatus::Success => {}
                    }
                }
                Ok(BtStatus::Success)
            }
            NodeKind::Leaf { name } => {
                let fns = this.leaf_fns.borrow();
                match fns.get(&name) {
                    None => Ok(BtStatus::Failure),
                    Some(rk) => {
                        let func: LuaFunction = lua.registry_value(rk)?;
                        drop(fns);
                        let result: String = func.call(())?;
                        Ok(match result.as_str() {
                            "success" => BtStatus::Success,
                            "running" => BtStatus::Running,
                            _ => BtStatus::Failure,
                        })
                    }
                }
            }
        }
    }
}
#[derive(Clone)]
struct LuaGraph {
    graph: Rc<RefCell<crate::patterns::Graph>>,
    node_payloads: Rc<RefCell<HashMap<u32, LuaRegistryKey>>>,
    edge_payloads: Rc<RefCell<HashMap<u32, LuaRegistryKey>>>,
}
impl LurekType for LuaGraph {
    const TYPE_NAME: &'static str = "LGraph";
    const TYPE_HIERARCHY: &'static [&'static str] = &["LGraph", "Object"];
}
impl LuaUserData for LuaGraph {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);
        methods.add_method(
            "addNode",
            |lua, this, (label, value): (Option<String>, Option<LuaValue>)| {
                let id = this
                    .graph
                    .borrow_mut()
                    .add_node(label.as_deref().unwrap_or(""));
                if let Some(v) = value {
                    let rk = lua.create_registry_value(v)?;
                    this.node_payloads.borrow_mut().insert(id, rk);
                }
                Ok(id)
            },
        );
        methods.add_method("removeNode", |lua, this, id: u32| {
            let removed = this.graph.borrow_mut().remove_node(id);
            if removed {
                if let Some(rk) = this.node_payloads.borrow_mut().remove(&id) {
                    lua.remove_registry_value(rk)?;
                }
            }
            Ok(removed)
        });
        methods.add_method("getNodeValue", |lua, this, id: u32| {
            let payloads = this.node_payloads.borrow();
            match payloads.get(&id) {
                Some(rk) => Ok(lua.registry_value::<LuaValue>(rk)?),
                None => Ok(LuaValue::Nil),
            }
        });
        methods.add_method(
            "addEdge",
            |_, this, (from, to, weight, label): (u32, u32, Option<f64>, Option<String>)| {
                Ok(this.graph.borrow_mut().add_edge(
                    from,
                    to,
                    weight.unwrap_or(1.0),
                    label.as_deref().unwrap_or(""),
                ))
            },
        );
        methods.add_method("removeEdge", |lua, this, id: u32| {
            let removed = this.graph.borrow_mut().remove_edge(id);
            if removed {
                if let Some(rk) = this.edge_payloads.borrow_mut().remove(&id) {
                    lua.remove_registry_value(rk)?;
                }
            }
            Ok(removed)
        });
        methods.add_method("neighbors", |lua, this, id: u32| {
            let nbs = this.graph.borrow().neighbors(id);
            let tbl = lua.create_table()?;
            for (i, nb) in nbs.iter().enumerate() {
                tbl.set(i + 1, *nb)?;
            }
            Ok(tbl)
        });
        methods.add_method("bfs", |lua, this, start: u32| {
            let order = this.graph.borrow().bfs(start);
            let tbl = lua.create_table()?;
            for (i, id) in order.iter().enumerate() {
                tbl.set(i + 1, *id)?;
            }
            Ok(tbl)
        });
        methods.add_method("dfs", |lua, this, start: u32| {
            let order = this.graph.borrow().dfs(start);
            let tbl = lua.create_table()?;
            for (i, id) in order.iter().enumerate() {
                tbl.set(i + 1, *id)?;
            }
            Ok(tbl)
        });
        methods.add_method("isConnected", |_, this, (from, to): (u32, u32)| {
            Ok(this.graph.borrow().is_connected(from, to))
        });
        methods.add_method("hasNode", |_, this, id: u32| {
            Ok(this.graph.borrow().has_node(id))
        });
        methods.add_method("nodeCount", |_, this, ()| {
            Ok(this.graph.borrow().node_count())
        });
        methods.add_method("edgeCount", |_, this, ()| {
            Ok(this.graph.borrow().edge_count())
        });
        methods.add_method("clearAll", |lua, this, ()| {
            this.graph.borrow_mut().clear();
            let np: Vec<(u32, LuaRegistryKey)> = this.node_payloads.borrow_mut().drain().collect();
            for (_, rk) in np {
                lua.remove_registry_value(rk)?;
            }
            let ep: Vec<(u32, LuaRegistryKey)> = this.edge_payloads.borrow_mut().drain().collect();
            for (_, rk) in ep {
                lua.remove_registry_value(rk)?;
            }
            Ok(())
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let patterns = lua.create_table()?;
    patterns.set(
        "newEventBus",
        lua.create_function(|_lua, name: Option<String>| {
            Ok(LuaEventBus {
                bus: Rc::new(RefCell::new(crate::patterns::EventBus::new(
                    name.as_deref().unwrap_or(""),
                ))),
                callbacks: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    patterns.set(
        "newObjectPool",
        lua.create_function(|_lua, ()| {
            Ok(LuaObjectPool {
                pool: Rc::new(RefCell::new(crate::patterns::ObjectPool::new("", 0))),
                idle_objects: Rc::new(RefCell::new(HashMap::new())),
                active_queue: Rc::new(RefCell::new(VecDeque::new())),
            })
        })?,
    )?;
    patterns.set(
        "newCommandStack",
        lua.create_function(|_lua, max_size: Option<usize>| {
            Ok(LuaCommandStack {
                stack: Rc::new(RefCell::new(crate::patterns::CommandStack::new(
                    max_size.unwrap_or(0),
                ))),
                exec_fns: Rc::new(RefCell::new(HashMap::new())),
                undo_fns: Rc::new(RefCell::new(HashMap::new())),
                history_ids: Rc::new(RefCell::new(Vec::new())),
            })
        })?,
    )?;
    patterns.set(
        "newServiceLocator",
        lua.create_function(|_lua, ()| {
            Ok(LuaServiceLocator {
                locator: Rc::new(RefCell::new(crate::patterns::ServiceLocator::new())),
                services: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    patterns.set(
        "newFactory",
        lua.create_function(|_lua, ()| {
            Ok(LuaFactory {
                factory: Rc::new(RefCell::new(crate::patterns::Factory::new())),
                constructors: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    patterns.set(
        "newSimpleState",
        lua.create_function(|_lua, ()| {
            Ok(LuaSimpleState {
                state: Rc::new(RefCell::new(crate::patterns::SimpleState::new())),
                enter_keys: Rc::new(RefCell::new(HashMap::new())),
                exit_keys: Rc::new(RefCell::new(HashMap::new())),
                update_keys: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    patterns.set(
        "newBlackboard",
        lua.create_function(|_lua, name: Option<String>| {
            Ok(LuaBlackboard {
                board: Rc::new(RefCell::new(crate::patterns::Blackboard::new(
                    name.as_deref().unwrap_or(""),
                ))),
                watchers: Rc::new(RefCell::new(HashMap::new())),
                watcher_keys: Rc::new(RefCell::new(HashMap::new())),
                next_watcher_id: Rc::new(RefCell::new(0)),
            })
        })?,
    )?;
    patterns.set(
        "newObserver",
        lua.create_function(|_lua, name: Option<String>| {
            Ok(LuaObserver {
                observer: Rc::new(RefCell::new(crate::patterns::Observer::new(
                    name.as_deref().unwrap_or(""),
                ))),
                values: Rc::new(RefCell::new(HashMap::new())),
                callbacks: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    patterns.set(
        "newThrottle",
        lua.create_function(|_lua, interval: f64| {
            Ok(LuaThrottle {
                throttle: Rc::new(RefCell::new(crate::patterns::Throttle::new(interval))),
                callback: Rc::new(RefCell::new(None)),
            })
        })?,
    )?;
    patterns.set(
        "newDebounce",
        lua.create_function(|_lua, wait: f64| {
            Ok(LuaDebounce {
                debounce: Rc::new(RefCell::new(crate::patterns::Debounce::new(wait))),
                callback: Rc::new(RefCell::new(None)),
            })
        })?,
    )?;
    patterns.set(
        "newPriorityQueue",
        lua.create_function(|_lua, name: Option<String>| {
            Ok(LuaPriorityQueue {
                queue: Rc::new(RefCell::new(crate::patterns::PriorityQueue::new(
                    name.as_deref().unwrap_or(""),
                ))),
                payloads: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    patterns.set(
        "newRing",
        lua.create_function(|_lua, (capacity, name): (usize, Option<String>)| {
            Ok(LuaRing {
                ring: Rc::new(RefCell::new(crate::patterns::Ring::new(
                    name.as_deref().unwrap_or(""),
                    capacity,
                ))),
            })
        })?,
    )?;
    patterns.set(
        "newFunnel",
        lua.create_function(
            |_lua, (window, max_entries, name): (f64, Option<usize>, Option<String>)| {
                Ok(LuaFunnel {
                    funnel: Rc::new(RefCell::new(crate::patterns::Funnel::new(
                        name.as_deref().unwrap_or(""),
                        window,
                        max_entries.unwrap_or(0),
                    ))),
                    on_flush: Rc::new(RefCell::new(None)),
                })
            },
        )?,
    )?;
    patterns.set(
        "newRelationshipManager",
        lua.create_function(|_, ()| {
            Ok(LuaRelationshipManager {
                rm: Rc::new(RefCell::new(crate::ecs::RelationshipManager::new())),
            })
        })?,
    )?;
    patterns.set(
        "newMediator",
        lua.create_function(|_, ()| {
            Ok(LuaMediator {
                mediator: Rc::new(RefCell::new(crate::patterns::Mediator::new())),
                callbacks: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    patterns.set(
        "newStrategy",
        lua.create_function(|_, ()| {
            Ok(LuaStrategy {
                strategy: Rc::new(RefCell::new(crate::patterns::Strategy::new())),
                callbacks: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    patterns.set(
        "newStack",
        lua.create_function(|_, capacity: Option<usize>| {
            Ok(LuaStack {
                meta: crate::patterns::StackMeta::new(capacity.unwrap_or(0)),
                items: Rc::new(RefCell::new(Vec::new())),
            })
        })?,
    )?;
    patterns.set(
        "newQueue",
        lua.create_function(|_, capacity: Option<usize>| {
            Ok(LuaQueue {
                meta: crate::patterns::QueueMeta::new(capacity.unwrap_or(0)),
                items: Rc::new(RefCell::new(VecDeque::new())),
            })
        })?,
    )?;
    patterns.set(
        "newList",
        lua.create_function(|_, ()| {
            Ok(LuaList {
                items: Rc::new(RefCell::new(Vec::new())),
            })
        })?,
    )?;
    patterns.set(
        "newSet",
        lua.create_function(|_, ()| {
            Ok(LuaSet {
                items: Rc::new(RefCell::new(HashSet::new())),
            })
        })?,
    )?;
    patterns.set(
        "newMap",
        lua.create_function(|_, ()| {
            Ok(LuaMap {
                items: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    patterns.set(
        "newWeightedRandom",
        lua.create_function(|_, ()| {
            Ok(LuaWeightedRandom {
                pool: Rc::new(RefCell::new(crate::patterns::WeightedRandom::new())),
                payloads: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    patterns.set(
        "newBehaviorTree",
        lua.create_function(|_, ()| {
            Ok(LuaBehaviorTree {
                tree: Rc::new(RefCell::new(crate::patterns::BehaviorTree::new())),
                run_state: Rc::new(RefCell::new(crate::patterns::BtRunState::new())),
                leaf_fns: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    patterns.set(
        "newGraph",
        lua.create_function(|_, undirected: Option<bool>| {
            let mut g = crate::patterns::Graph::new();
            g.undirected = undirected.unwrap_or(false);
            Ok(LuaGraph {
                graph: Rc::new(RefCell::new(g)),
                node_payloads: Rc::new(RefCell::new(HashMap::new())),
                edge_payloads: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    lurek.set("patterns", patterns)?;
    Ok(())
}
