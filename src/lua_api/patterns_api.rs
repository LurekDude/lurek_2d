//! `lurek.patterns` — Design pattern utilities: event buses, object pools, state machines, command stacks, observers, mediators, factories, data structures, behavior trees, and graphs.
use crate::lua_api::lua_types::{add_type_methods, LurekType};
use crate::runtime::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::collections::HashSet;
use std::collections::VecDeque;
use std::rc::Rc;
/// Lua-facing publish/subscribe event bus allowing decoupled communication between game systems.
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
        // -- on --
        /// Subscribe a callback to a named event. Higher priority listeners fire first.
        /// @param | event | string | The event name to listen for.
        /// @param | callback | function | The function to invoke when the event fires.
        /// @param | priority | number? | Listener priority (default 0). Higher values execute first.
        /// @return | number | A subscription ID used to unsubscribe later.
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
        // -- off --
        /// Unsubscribe a listener by its subscription ID. Removes the callback from the event bus.
        /// @param | id | number | The subscription ID returned by `on()`.
        methods.add_method("off", |lua, this, id: u64| {
            this.bus.borrow_mut().unsubscribe(id);
            if let Some(key) = this.callbacks.borrow_mut().remove(&id) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        // -- emit --
        /// Emit an event, invoking all subscribed listeners in priority order with optional payload arguments.
        /// @param | event | string | The event name to emit.
        /// @param | ... | boolean|number|string|table|nil | Additional arguments passed to each listener callback.
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
        // -- clear --
        /// Remove all listeners subscribed to a specific event name.
        /// @param | event | string | The event name whose listeners will be removed.
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
        // -- clearAll --
        /// Remove all listeners from every event on this bus. Resets the bus to empty.
        methods.add_method("clearAll", |lua, this, ()| {
            let _ = this.bus.borrow_mut().clear_all();
            let drained: Vec<(u64, LuaRegistryKey)> = this.callbacks.borrow_mut().drain().collect();
            for (_, key) in drained {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        // -- getListenerCount --
        /// Return the number of active listeners for a given event name.
        /// @param | event | string | The event name to query.
        /// @return | number | Count of currently registered listeners.
        methods.add_method("getListenerCount", |_lua, this, event: String| {
            Ok(this.bus.borrow().listener_count(&event))
        });
        // -- getEvents --
        /// Return an array of all event names that have at least one listener.
        /// @return | table | Array of event name strings.
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
/// Lua-facing object pool for reusing pre-allocated game objects (bullets, particles, enemies) to avoid per-frame allocations.
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
        // -- add --
        /// Add an object to the pool's idle set, making it available for future acquisition.
        /// @param | value | boolean|number|string|table | The object to store in the pool.
        methods.add_method("add", |lua, this, value: LuaValue| {
            let total = this.pool.borrow().total_count();
            let new_ids = this.pool.borrow_mut().prewarm(total + 1);
            if let Some(&id) = new_ids.first() {
                let key = lua.create_registry_value(value)?;
                this.idle_objects.borrow_mut().insert(id, key);
            }
            Ok(())
        });
        // -- acquire --
        /// Take an idle object from the pool and mark it active. Returns nil if the pool is empty.
        /// @return | boolean|number|string|table|nil | The acquired object, or nil if none available.
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
        // -- release --
        /// Return an active object back to the pool's idle set so it can be reused.
        /// @param | value | boolean|number|string|table | The object to release back into the pool.
        methods.add_method("release", |lua, this, value: LuaValue| {
            if let Some(id) = this.active_queue.borrow_mut().pop_front() {
                this.pool.borrow_mut().release(id);
                let key = lua.create_registry_value(value)?;
                this.idle_objects.borrow_mut().insert(id, key);
            }
            Ok(())
        });
        // -- getActiveCount --
        /// Return the number of objects currently checked out from the pool.
        /// @return | number | Count of active (in-use) objects.
        methods.add_method("getActiveCount", |_lua, this, ()| {
            Ok(this.pool.borrow().active_count())
        });
        // -- getAvailableCount --
        /// Return the number of idle objects ready for acquisition.
        /// @return | number | Count of available (idle) objects.
        methods.add_method("getAvailableCount", |_lua, this, ()| {
            Ok(this.pool.borrow().idle_count())
        });
        // -- getTotalCount --
        /// Return the total number of objects managed by this pool (active + idle).
        /// @return | number | Total object count.
        methods.add_method("getTotalCount", |_lua, this, ()| {
            Ok(this.pool.borrow().total_count())
        });
        // -- clearAll --
        /// Destroy all objects (active and idle) and reset the pool to empty.
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
/// Lua-facing undo/redo command stack. Records executed actions with optional undo functions for full history navigation.
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
        // -- execute --
        /// Execute a named command immediately, recording it in history. Discards any redo history ahead of the current position.
        /// @param | name | string | A descriptive name for the command (shown in history).
        /// @param | execFn | function | The function that performs the action.
        /// @param | undoFn | function? | An optional function that reverses the action. If omitted, command cannot be undone.
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
        // -- undo --
        /// Undo the most recent command by calling its undo function. Moves the pointer back in history.
        /// @return | boolean | True if undo succeeded, false if nothing to undo or no undo function registered.
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
        // -- redo --
        /// Redo a previously undone command by re-calling its execute function. Moves the pointer forward.
        /// @return | boolean | True if redo succeeded, false if nothing to redo.
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
        // -- canUndo --
        /// Check whether an undo operation is possible (there is a command with an undo function behind the pointer).
        /// @return | boolean | True if undo is available.
        methods.add_method("canUndo", |_lua, this, ()| {
            let s = this.stack.borrow();
            Ok(s.peek_undo()
                .and_then(|id| s.get_entry(id))
                .map(|e| e.has_undo)
                .unwrap_or(false))
        });
        // -- canRedo --
        /// Check whether a redo operation is possible (there are commands ahead of the pointer).
        /// @return | boolean | True if redo is available.
        methods.add_method("canRedo", |_lua, this, ()| {
            Ok(this.stack.borrow().redo_count() > 0)
        });
        // -- getHistorySize --
        /// Return the total number of commands in the history (both undone and available for redo).
        /// @return | number | Total history depth.
        methods.add_method("getHistorySize", |_lua, this, ()| {
            let s = this.stack.borrow();
            Ok(s.undo_count() + s.redo_count())
        });
        // -- getCurrentName --
        /// Return the name of the most recently executed (or undone-to) command, or nil if history is empty.
        /// @return | string? | The command name, or nil.
        methods.add_method("getCurrentName", |_lua, this, ()| {
            let s = this.stack.borrow();
            Ok(s.peek_undo()
                .and_then(|id| s.get_entry(id))
                .map(|e| e.name.clone()))
        });
        // -- clearAll --
        /// Discard all command history and free associated callbacks.
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
/// Lua-facing service locator for registering and retrieving shared services by name at runtime.
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
        // -- provide --
        /// Register a service instance under a given name. Replaces any previously registered service with the same name.
        /// @param | name | string | Unique identifier for the service.
        /// @param | value | boolean|number|string|table|function | The service object or table to store.
        methods.add_method("provide", |lua, this, (name, value): (String, LuaValue)| {
            this.locator.borrow_mut().register(&name);
            let key = lua.create_registry_value(value)?;
            if let Some(old) = this.services.borrow_mut().insert(name, key) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });
        // -- locate --
        /// Retrieve a registered service by name. Returns nil if not found.
        /// @param | name | string | The service name to look up.
        /// @return | boolean|number|string|table|nil | The service object, or nil if not registered.
        methods.add_method("locate", |lua, this, name: String| {
            let svc = this.services.borrow();
            match svc.get(&name) {
                Some(key) => Ok(lua.registry_value::<LuaValue>(key)?),
                None => Ok(LuaValue::Nil),
            }
        });
        // -- has --
        /// Check whether a service with the given name is currently registered.
        /// @param | name | string | The service name to check.
        /// @return | boolean | True if the service exists.
        methods.add_method("has", |_lua, this, name: String| {
            Ok(this.locator.borrow().has(&name))
        });
        // -- remove --
        /// Unregister and discard a service by name.
        /// @param | name | string | The service name to remove.
        methods.add_method("remove", |lua, this, name: String| {
            this.locator.borrow_mut().unregister(&name);
            if let Some(key) = this.services.borrow_mut().remove(&name) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        // -- getServices --
        /// Return an array of all registered service names.
        /// @return | table | Array of service name strings.
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
        // -- clearAll --
        /// Remove all registered services and reset the locator.
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
/// Lua-facing factory pattern for creating typed game objects from registered constructor functions.
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
        // -- register --
        /// Register a constructor function for a given type name. Future `create()` calls with this type will invoke it.
        /// @param | typeName | string | The type identifier (e.g. "enemy", "bullet").
        /// @param | ctor | function | A constructor function that returns a new instance.
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
        // -- create --
        /// Create a new object by type name, passing additional arguments to the constructor.
        /// @param | typeName | string | The registered type to instantiate.
        /// @param | ... | boolean|number|string|table|nil | Extra arguments forwarded to the constructor.
        /// @return | boolean|number|string|table | The value returned by the constructor function.
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
        // -- has --
        /// Check whether a constructor is registered for the given type name.
        /// @param | typeName | string | The type name to query.
        /// @return | boolean | True if a constructor exists for this type.
        methods.add_method("has", |_lua, this, type_name: String| {
            Ok(this.factory.borrow().has(&type_name))
        });
        // -- alias --
        /// Create an alias that maps to an existing type name. `create(alias)` will use the canonical constructor.
        /// @param | alias | string | The alternative name.
        /// @param | canonical | string | The existing registered type name.
        methods.add_method(
            "alias",
            |_lua, this, (alias, canonical): (String, String)| {
                this.factory.borrow_mut().add_alias(&alias, &canonical);
                Ok(())
            },
        );
        // -- getTypes --
        /// Return an array of all registered type names.
        /// @return | table | Array of type name strings.
        methods.add_method("getTypes", |lua, this, ()| {
            let names: Vec<String> = this.factory.borrow().type_names()
                .iter()
                .map(|s| s.to_string())
                .collect();
            let table = lua.create_table()?;
            for (i, name) in names.iter().enumerate() {
                table.set(i + 1, name.as_str())?;
            }
            Ok(table)
        });
        // -- remove --
        /// Unregister a type and discard its constructor function.
        /// @param | typeName | string | The type name to remove.
        methods.add_method("remove", |lua, this, type_name: String| {
            this.factory.borrow_mut().unregister(&type_name);
            if let Some(key) = this.constructors.borrow_mut().remove(&type_name) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        // -- clearAll --
        /// Remove all registered types and constructors, resetting the factory.
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
/// Lua-facing finite state machine with enter/exit/update callbacks per state.
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
        // -- addState --
        /// Register a named state with optional enter, exit, and update callbacks.
        /// @param | name | string | Unique state identifier.
        /// @param | callbacks | table? | Table with optional fields: `enter` (function), `exit` (function), `update` (function receiving dt).
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
        // -- transitionTo --
        /// Transition to a new state. Calls the current state's `exit` and the target state's `enter` callbacks.
        /// @param | name | string | The state to transition to. Must be previously added.
        /// @return | boolean | True if the transition happened, false if the target state does not exist.
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
        // -- update --
        /// Call the current state's update callback with the frame delta time.
        /// @param | dt | number | Delta time in seconds since last frame.
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
        // -- getCurrent --
        /// Return the name of the currently active state, or nil if no state is set.
        /// @return | string? | Current state name.
        methods.add_method("getCurrent", |_lua, this, ()| {
            Ok(this.state.borrow().current().map(|s| s.to_string()))
        });
        // -- hasState --
        /// Check whether a state with the given name is registered.
        /// @param | name | string | State name to check.
        /// @return | boolean | True if the state exists.
        methods.add_method("hasState", |_lua, this, name: String| {
            Ok(this.state.borrow().has(&name))
        });
        // -- getStates --
        /// Return an array of all registered state names.
        /// @return | table | Array of state name strings.
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
        // -- clearAll --
        /// Remove all states and their callbacks, resetting the state machine.
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
/// Lua-facing shared key-value blackboard supporting bool/number/string values with watchers for reactive game logic.
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
        // -- set --
        /// Set a key to a value (boolean, number, string, or nil to clear). Notifies registered watchers if value changed.
        /// @param | key | string | The key name.
        /// @param | value | boolean|number|string|nil | The value to store. Pass nil to clear the key.
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
        // -- get --
        /// Retrieve the value stored under a key. Returns nil if the key does not exist.
        /// @param | key | string | The key name to look up.
        /// @return | boolean|number|string|nil | The stored value.
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
        // -- has --
        /// Check whether a key exists on the blackboard.
        /// @param | key | string | The key to check.
        /// @return | boolean | True if the key has a stored value.
        methods.add_method("has", |_, this, key: String| {
            Ok(this.board.borrow().has(&key))
        });
        // -- clear --
        /// Remove a single key from the blackboard.
        /// @param | key | string | The key to remove.
        methods.add_method("clear", |_, this, key: String| {
            this.board.borrow_mut().clear(&key);
            Ok(())
        });
        // -- keys --
        /// Return an array of all keys currently stored on the blackboard.
        /// @return | table | Array of key name strings.
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
        // -- watch --
        /// Register a watcher callback that fires whenever the specified key changes. Use `"*"` to watch all keys.
        /// @param | key | string | The key to watch, or `"*"` for all changes.
        /// @param | callback | function | Called with (key, newValue) when a change occurs.
        /// @return | number | A watcher ID for later removal with `unwatch()`.
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
        // -- unwatch --
        /// Remove a previously registered watcher by its ID.
        /// @param | id | number | The watcher ID returned by `watch()`.
        methods.add_method("unwatch", |lua, this, id: u64| {
            if let Some(rk) = this.watchers.borrow_mut().remove(&id) {
                lua.remove_registry_value(rk)?;
            }
            this.watcher_keys.borrow_mut().remove(&id);
            Ok(())
        });
        // -- getRevision --
        /// Return the current revision counter. Increments on every value change.
        /// @return | number | The revision number.
        methods.add_method("getRevision", |_, this, ()| {
            Ok(this.board.borrow().revision)
        });
        // -- snapshot --
        /// Return a table containing all current key-value pairs as a snapshot. Useful for serialization or debug display.
        /// @return | table | A table mapping key strings to their stored values.
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
        // -- clearAll --
        /// Remove all keys and values from the blackboard.
        methods.add_method("clearAll", |_, this, ()| {
            this.board.borrow_mut().clear_all();
            Ok(())
        });
    }
}
/// Lua-facing reactive observer that stores values and notifies subscribers when values change.
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
        // -- set --
        /// Set a value by key and notify all subscribers watching that key.
        /// @param | key | string | The property name.
        /// @param | value | boolean|number|string|table | The new value to store.
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
        // -- get --
        /// Retrieve the current value for a key. Returns nil if not set.
        /// @param | key | string | The property name to look up.
        /// @return | boolean|number|string|table|nil | The stored value, or nil.
        methods.add_method("get", |lua, this, key: String| {
            match this.values.borrow().get(&key) {
                Some(rk) => Ok(lua.registry_value::<LuaValue>(rk)?),
                None => Ok(LuaValue::Nil),
            }
        });
        // -- subscribe --
        /// Subscribe to changes on a specific key. The callback receives (key, newValue) on each change.
        /// @param | key | string | The property name to watch.
        /// @param | callback | function | Called with (key, newValue) when the property changes.
        /// @param | once | boolean? | If true, automatically unsubscribe after the first notification.
        /// @return | number | A subscription ID for later removal with `unsubscribe()`.
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
        // -- unsubscribe --
        /// Remove a subscription by its ID. The callback will no longer fire.
        /// @param | id | number | The subscription ID returned by `subscribe()`.
        methods.add_method("unsubscribe", |lua, this, id: u64| {
            this.observer.borrow_mut().unsubscribe(id);
            if let Some(rk) = this.callbacks.borrow_mut().remove(&id) {
                lua.remove_registry_value(rk)?;
            }
            Ok(())
        });
        // -- getCount --
        /// Return the total number of active subscriptions across all keys.
        /// @return | number | Total subscription count.
        methods.add_method("getCount", |_, this, ()| {
            Ok(this.observer.borrow().subscription_count())
        });
    }
}
/// Lua-facing throttle that limits how often an action can fire, enforcing a minimum interval between executions.
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
        // -- onFire --
        /// Set the callback function to invoke each time the throttle fires.
        /// @param | f | function | The callback to execute on fire.
        methods.add_method("onFire", |lua, this, f: LuaFunction| {
            let rk = lua.create_registry_value(f)?;
            if let Some(old) = this.callback.borrow_mut().replace(rk) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });
        // -- update --
        /// Advance the throttle timer. If the interval has elapsed, fires the callback and returns true.
        /// @param | dt | number | Delta time in seconds since last update.
        /// @return | boolean | True if the throttle fired this frame.
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
        // -- reset --
        /// Reset the throttle timer back to zero without firing.
        methods.add_method("reset", |_, this, ()| {
            this.throttle.borrow_mut().reset();
            Ok(())
        });
        // -- getProgress --
        /// Return how far through the current interval the throttle is (0.0 to 1.0).
        /// @return | number | Progress fraction.
        methods.add_method("getProgress", |_, this, ()| {
            Ok(this.throttle.borrow().progress())
        });
        // -- getFireCount --
        /// Return the total number of times this throttle has fired since creation.
        /// @return | number | Total fire count.
        methods.add_method("getFireCount", |_, this, ()| {
            Ok(this.throttle.borrow().fire_count)
        });
        // -- setEnabled --
        /// Enable or disable the throttle. When disabled, update() will not accumulate time.
        /// @param | enabled | boolean | True to enable, false to disable.
        methods.add_method("setEnabled", |_, this, v: bool| {
            this.throttle.borrow_mut().enabled = v;
            Ok(())
        });
    }
}
/// Lua-facing debounce that delays firing until input stops for a specified wait period.
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
        // -- onFire --
        /// Set the callback function to invoke when the debounce fires after the wait period.
        /// @param | f | function | The callback to execute.
        methods.add_method("onFire", |lua, this, f: LuaFunction| {
            let rk = lua.create_registry_value(f)?;
            if let Some(old) = this.callback.borrow_mut().replace(rk) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });
        // -- trigger --
        /// Signal input activity. Resets the wait timer so the debounce will fire after the full wait period of inactivity.
        methods.add_method("trigger", |_, this, ()| {
            this.debounce.borrow_mut().trigger();
            Ok(())
        });
        // -- update --
        /// Advance the debounce timer. If the wait period elapsed since last trigger, fires the callback and returns true.
        /// @param | dt | number | Delta time in seconds since last update.
        /// @return | boolean | True if the debounce fired this frame.
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
        // -- cancel --
        /// Cancel any pending debounce without firing. The callback will not be called until triggered again.
        methods.add_method("cancel", |_, this, ()| {
            this.debounce.borrow_mut().cancel();
            Ok(())
        });
        // -- isPending --
        /// Check whether the debounce is currently waiting to fire (has been triggered but wait period not yet elapsed).
        /// @return | boolean | True if a fire is pending.
        methods.add_method("isPending", |_, this, ()| {
            Ok(this.debounce.borrow().pending)
        });
        // -- getFireCount --
        /// Return the total number of times this debounce has fired since creation.
        /// @return | number | Total fire count.
        methods.add_method("getFireCount", |_, this, ()| {
            Ok(this.debounce.borrow().fire_count)
        });
    }
}
/// Lua-facing priority queue that orders elements by numeric priority (highest first).
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
        // -- push --
        /// Add an item with a numeric priority. Higher priority items are dequeued first.
        /// @param | priority | number | The priority value (higher = dequeued sooner).
        /// @param | value | boolean|number|string|table | The payload to store.
        /// @param | label | string? | Optional human-readable label for debugging.
        /// @return | number | The internal ID of the enqueued item.
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
        // -- pop --
        /// Remove and return the highest-priority item. Returns nil if the queue is empty.
        /// @return | boolean|number|string|table|nil | The item value, or nil.
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
        // -- peek --
        /// Return the highest-priority item without removing it. Returns nil if empty.
        /// @return | boolean|number|string|table|nil | The item value, or nil.
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
        // -- len --
        /// Return the number of items currently in the queue.
        /// @return | number | Item count.
        methods.add_method("len", |_, this, ()| Ok(this.queue.borrow().len()));
        // -- isEmpty --
        /// Check whether the queue contains no items.
        /// @return | boolean | True if the queue is empty.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.queue.borrow().is_empty()));
        // -- clearAll --
        /// Remove all items from the queue.
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
/// Lua-facing fixed-size ring buffer for numeric or string values. Oldest entries are overwritten when full.
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
        // -- push --
        /// Push a number or string value into the ring. Overwrites the oldest entry if the ring is full.
        /// @param | value | number|string | The value to store.
        /// @param | tag | string? | Optional label for categorizing entries.
        /// @return | number | The internal ID of the new entry.
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
        // -- latest --
        /// Return the most recently pushed entry as a table with id, tag, value, and text fields. Returns nil if empty.
        /// @return | table|nil | Entry table or nil.
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
        // -- toArray --
        /// Return all entries in the ring as an ordered array of tables (oldest to newest).
        /// @return | table | Array of entry tables with id, tag, value, and text fields.
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
        // -- sum --
        /// Return the sum of all numeric values in the ring. Non-numeric entries contribute zero.
        /// @return | number | Sum of values.
        methods.add_method("sum", |_, this, ()| Ok(this.ring.borrow().sum()));
        // -- average --
        /// Return the arithmetic mean of all numeric values in the ring.
        /// @return | number | Average value (0 if empty).
        methods.add_method("average", |_, this, ()| Ok(this.ring.borrow().average()));
        // -- len --
        /// Return the number of entries currently in the ring.
        /// @return | number | Entry count.
        methods.add_method("len", |_, this, ()| Ok(this.ring.borrow().len()));
        // -- isFull --
        /// Check whether the ring has reached its maximum capacity.
        /// @return | boolean | True if full.
        methods.add_method("isFull", |_, this, ()| Ok(this.ring.borrow().is_full()));
        // -- clear --
        /// Remove all entries from the ring.
        methods.add_method("clear", |_, this, ()| {
            this.ring.borrow_mut().clear();
            Ok(())
        });
    }
}
/// Lua-facing batching funnel that collects events over a time window and flushes them together.
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
        // -- onFlush --
        /// Set the callback invoked when the funnel flushes. Receives an array of {tag, value} entries.
        /// @param | f | function | Callback receiving a table array of batched entries.
        methods.add_method("onFlush", |lua, this, f: LuaFunction| {
            let rk = lua.create_registry_value(f)?;
            if let Some(old) = this.on_flush.borrow_mut().replace(rk) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });
        // -- push --
        /// Push a tagged event into the funnel. May trigger an immediate flush if the max entry count is reached.
        /// @param | tag | string | A category label for the event.
        /// @param | value | number? | Optional numeric value (default 0).
        methods.add_method("push", |lua, this, (tag, value): (String, Option<f64>)| {
            let (_, should_flush) = this.funnel.borrow_mut().push(&tag, value.unwrap_or(0.0));
            if should_flush {
                Self::do_flush(lua, this)?;
            }
            Ok(())
        });
        // -- update --
        /// Advance the funnel's time window. Flushes and invokes the callback if the window elapsed.
        /// @param | dt | number | Delta time in seconds.
        /// @return | boolean | True if a flush occurred this frame.
        methods.add_method("update", |lua, this, dt: f64| {
            let should_flush = this.funnel.borrow_mut().update(dt);
            if should_flush {
                Self::do_flush(lua, this)?;
                return Ok(true);
            }
            Ok(false)
        });
        // -- flush --
        /// Force an immediate flush of all pending entries, invoking the callback.
        methods.add_method("flush", |lua, this, ()| Self::do_flush(lua, this));
        // -- discard --
        /// Discard all pending entries without flushing or calling the callback.
        methods.add_method("discard", |_, this, ()| {
            this.funnel.borrow_mut().discard();
            Ok(())
        });
        // -- pendingCount --
        /// Return the number of entries waiting to be flushed.
        /// @return | number | Pending entry count.
        methods.add_method("pendingCount", |_, this, ()| {
            Ok(this.funnel.borrow().pending_count())
        });
        // -- getFlushCount --
        /// Return the total number of times this funnel has flushed since creation.
        /// @return | number | Total flush count.
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
/// Lua-facing relationship manager for tracking numeric values and named levels between entity pairs.
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
        // -- defineType --
        /// Define a relationship type with named levels (e.g. "friendship" with levels ["hostile", "neutral", "friendly"]).
        /// @param | name | string | The relationship type name.
        /// @param | levels | table | Array of level name strings in order.
        /// @param | defaultLevel | string? | The default level for new pairs.
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
        // -- removeType --
        /// Remove a relationship type definition.
        /// @param | name | string | The type name to remove.
        methods.add_method("removeType", |_, this, name: String| {
            this.rm.borrow_mut().remove_type(&name);
            Ok(())
        });
        // -- typeNames --
        /// Return all defined relationship type names.
        /// @return | table | Array of type name strings.
        methods.add_method("typeNames", |_, this, ()| Ok(this.rm.borrow().type_names()));
        // -- setValue --
        /// Set the numeric relationship value between two entity IDs.
        /// @param | a | number | First entity ID.
        /// @param | b | number | Second entity ID.
        /// @param | value | number | The numeric value to store.
        methods.add_method("setValue", |_, this, (a, b, value): (u32, u32, f64)| {
            this.rm.borrow_mut().set_value(a, b, value);
            Ok(())
        });
        // -- getValue --
        /// Get the numeric relationship value between two entity IDs.
        /// @param | a | number | First entity ID.
        /// @param | b | number | Second entity ID.
        /// @return | number | The stored value (0 if not set).
        methods.add_method("getValue", |_, this, (a, b): (u32, u32)| {
            Ok(this.rm.borrow().get_value(a, b))
        });
        // -- adjustValue --
        /// Add a delta to the relationship value between two entities.
        /// @param | a | number | First entity ID.
        /// @param | b | number | Second entity ID.
        /// @param | delta | number | Amount to add (can be negative).
        methods.add_method("adjustValue", |_, this, (a, b, delta): (u32, u32, f64)| {
            this.rm.borrow_mut().adjust_value(a, b, delta);
            Ok(())
        });
        // -- setLevel --
        /// Set the named level for a relationship type between two entities.
        /// @param | a | number | First entity ID.
        /// @param | b | number | Second entity ID.
        /// @param | typeName | string | The relationship type.
        /// @param | level | string | The level name to assign.
        /// @return | boolean | True if the level was set successfully.
        methods.add_method(
            "setLevel",
            |_, this, (a, b, type_name, level): (u32, u32, String, String)| {
                Ok(this.rm.borrow_mut().set_level(a, b, &type_name, &level))
            },
        );
        // -- getLevel --
        /// Get the named level for a relationship type between two entities.
        /// @param | a | number | First entity ID.
        /// @param | b | number | Second entity ID.
        /// @param | typeName | string | The relationship type.
        /// @return | string? | The current level name, or nil.
        methods.add_method(
            "getLevel",
            |_, this, (a, b, type_name): (u32, u32, String)| {
                Ok(this.rm.borrow().get_level(a, b, &type_name))
            },
        );
        // -- removePair --
        /// Remove all relationship data between two entities.
        /// @param | a | number | First entity ID.
        /// @param | b | number | Second entity ID.
        methods.add_method("removePair", |_, this, (a, b): (u32, u32)| {
            this.rm.borrow_mut().remove_relation(a, b);
            Ok(())
        });
        // -- pairCount --
        /// Return the total number of tracked entity pairs.
        /// @return | number | Pair count.
        methods.add_method("pairCount", |_, this, ()| {
            Ok(this.rm.borrow().relation_count())
        });
    }
}
/// Lua-facing mediator for channel-based message passing between decoupled game systems.
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
        // -- on --
        /// Register a handler callback on a named channel. Returns an ID for unregistration.
        /// @param | channel | string | The message channel name.
        /// @param | callback | function | The handler to invoke when a message is sent to this channel.
        /// @return | number | Handler ID for later removal.
        methods.add_method(
            "on",
            |lua, this, (channel, callback): (String, LuaFunction)| {
                let id = this.mediator.borrow_mut().register(&channel);
                let key = lua.create_registry_value(callback)?;
                this.callbacks.borrow_mut().insert(id, key);
                Ok(id)
            },
        );
        // -- off --
        /// Unregister a handler from a channel by its ID.
        /// @param | channel | string | The channel name.
        /// @param | id | number | The handler ID to remove.
        methods.add_method("off", |lua, this, (channel, id): (String, u64)| {
            this.mediator.borrow_mut().unregister(&channel, id);
            if let Some(key) = this.callbacks.borrow_mut().remove(&id) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        // -- send --
        /// Send a message to all handlers on a specific channel with optional payload arguments.
        /// @param | channel | string | The target channel name.
        /// @param | ... | boolean|number|string|table|nil | Additional arguments passed to each handler.
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
        // -- broadcast --
        /// Send a message to all handlers on all channels. Every registered handler receives the payload.
        /// @param | ... | boolean|number|string|table|nil | Arguments passed to every handler.
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
        // -- handlerCount --
        /// Return the number of handlers registered on a specific channel.
        /// @param | channel | string | The channel name.
        /// @return | number | Handler count.
        methods.add_method("handlerCount", |_, this, channel: String| {
            Ok(this.mediator.borrow().handler_count(&channel))
        });
        // -- channels --
        /// Return an array of all channel names that have at least one handler.
        /// @return | table | Array of channel name strings.
        methods.add_method("channels", |_, this, ()| {
            Ok(this.mediator.borrow().channel_names())
        });
        // -- removeChannel --
        /// Remove an entire channel and all its handlers.
        /// @param | channel | string | The channel to remove.
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
        // -- clear --
        /// Remove all channels and handlers, resetting the mediator.
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
/// Lua-facing strategy pattern allowing hot-swappable algorithm implementations by name.
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
        // -- register --
        /// Register a named strategy implementation function.
        /// @param | name | string | Strategy identifier.
        /// @param | callback | function | The implementation function to call when this strategy is active.
        methods.add_method(
            "register",
            |lua, this, (name, callback): (String, LuaFunction)| {
                let id = this.strategy.borrow_mut().register(&name);
                let key = lua.create_registry_value(callback)?;
                this.callbacks.borrow_mut().insert(id, key);
                Ok(())
            },
        );
        // -- set --
        /// Switch to a named strategy. Future `execute()` calls will use this implementation.
        /// @param | name | string | The strategy name to activate.
        /// @return | boolean | True if the strategy exists and was set.
        methods.add_method("set", |_, this, name: String| {
            Ok(this.strategy.borrow_mut().set_current(&name))
        });
        // -- execute --
        /// Execute the currently active strategy, passing through all arguments and returning its results.
        /// @param | ... | boolean|number|string|table|nil | Arguments forwarded to the active strategy function.
        /// @return | boolean|number|string|table|nil | Return values from the strategy function.
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
        // -- getCurrent --
        /// Return the name of the currently active strategy, or nil if none set.
        /// @return | string? | Active strategy name.
        methods.add_method("getCurrent", |_, this, ()| {
            Ok(this.strategy.borrow().get_current().map(|s| s.to_string()))
        });
        // -- has --
        /// Check whether a strategy with the given name is registered.
        /// @param | name | string | Strategy name to check.
        /// @return | boolean | True if registered.
        methods.add_method("has", |_, this, name: String| {
            Ok(this.strategy.borrow().has(&name))
        });
        // -- remove --
        /// Remove a named strategy. If it was the active strategy, no strategy will be selected.
        /// @param | name | string | Strategy name to remove.
        /// @return | boolean | True if the strategy was found and removed.
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
        // -- names --
        /// Return an array of all registered strategy names.
        /// @return | table | Array of strategy name strings.
        methods.add_method("names", |_, this, ()| Ok(this.strategy.borrow().names()));
        // -- clear --
        /// Remove all strategies and reset the selection.
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
/// Lua-facing LIFO stack with optional capacity limit. Supports push/pop from both ends.
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
        // -- push --
        /// Push a value onto the top of the stack. Returns false if the stack is at capacity.
        /// @param | value | boolean|number|string|table | The value to push.
        /// @return | boolean | True if pushed, false if full.
        methods.add_method("push", |lua, this, value: LuaValue| {
            let len = this.items.borrow().len();
            if this.meta.is_full(len) {
                return Ok(false);
            }
            let key = lua.create_registry_value(value)?;
            this.items.borrow_mut().push(key);
            Ok(true)
        });
        // -- pushBottom --
        /// Push a value onto the bottom of the stack. Returns false if at capacity.
        /// @param | value | boolean|number|string|table | The value to insert at the bottom.
        /// @return | boolean | True if pushed, false if full.
        methods.add_method("pushBottom", |lua, this, value: LuaValue| {
            let len = this.items.borrow().len();
            if this.meta.is_full(len) {
                return Ok(false);
            }
            let key = lua.create_registry_value(value)?;
            this.items.borrow_mut().insert(0, key);
            Ok(true)
        });
        // -- pop --
        /// Remove and return the top value. Returns nil if the stack is empty.
        /// @return | boolean|number|string|table|nil | The popped value, or nil.
        methods.add_method("pop", |lua, this, ()| {
            if let Some(key) = this.items.borrow_mut().pop() {
                let v: LuaValue = lua.registry_value(&key)?;
                lua.remove_registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        // -- popBottom --
        /// Remove and return the bottom value. Returns nil if empty.
        /// @return | boolean|number|string|table|nil | The popped value, or nil.
        methods.add_method("popBottom", |lua, this, ()| {
            if this.items.borrow().is_empty() {
                return Ok(LuaValue::Nil);
            }
            let key = this.items.borrow_mut().remove(0);
            let v: LuaValue = lua.registry_value(&key)?;
            lua.remove_registry_value(key)?;
            Ok(v)
        });
        // -- popMany --
        /// Pop up to `count` values from the top and return them as an array table.
        /// @param | count | number | Maximum number of items to pop.
        /// @return | table | Array of popped values (may be shorter than count).
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
        // -- peek --
        /// Return the top value without removing it. Returns nil if empty.
        /// @return | boolean|number|string|table|nil | The top value, or nil.
        methods.add_method("peek", |lua, this, ()| {
            if let Some(key) = this.items.borrow().last() {
                let v: LuaValue = lua.registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        // -- peekBottom --
        /// Return the bottom value without removing it. Returns nil if empty.
        /// @return | boolean|number|string|table|nil | The bottom value, or nil.
        methods.add_method("peekBottom", |lua, this, ()| {
            if let Some(key) = this.items.borrow().first() {
                let v: LuaValue = lua.registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        // -- peekAt --
        /// Return the value at a 1-based index without removing it. Returns nil if out of range.
        /// @param | index | number | 1-based position in the stack.
        /// @return | boolean|number|string|table|nil | The value at that position, or nil.
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
        // -- insertAt --
        /// Insert a value at a 1-based index in the stack, shifting items above it. Returns false if at capacity.
        /// @param | index | number | 1-based insertion position.
        /// @param | value | boolean|number|string|table | The value to insert.
        /// @return | boolean | True if inserted, false if full.
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
        // -- removeAt --
        /// Remove and return the value at a 1-based index. Returns nil if out of range.
        /// @param | index | number | 1-based position to remove.
        /// @return | boolean|number|string|table|nil | The removed value, or nil.
        methods.add_method("removeAt", |lua, this, index: usize| {
            if index == 0 || index > this.items.borrow().len() {
                return Ok(LuaValue::Nil);
            }
            let key = this.items.borrow_mut().remove(index - 1);
            let v: LuaValue = lua.registry_value(&key)?;
            lua.remove_registry_value(key)?;
            Ok(v)
        });
        // -- moveWithin --
        /// Move an item from one 1-based index to another within the stack.
        /// @param | from | number | Source index.
        /// @param | to | number | Destination index.
        /// @return | boolean | True if the move succeeded.
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
        // -- len --
        /// Return the current number of items in the stack.
        /// @return | number | Item count.
        methods.add_method("len", |_, this, ()| Ok(this.items.borrow().len()));
        // -- isEmpty --
        /// Check whether the stack is empty.
        /// @return | boolean | True if empty.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.items.borrow().is_empty()));
        // -- isFull --
        /// Check whether the stack has reached its capacity limit (if one was set).
        /// @return | boolean | True if full.
        methods.add_method("isFull", |_, this, ()| {
            Ok(this.meta.is_full(this.items.borrow().len()))
        });
        // -- clear --
        /// Remove all items from the stack.
        methods.add_method("clear", |lua, this, ()| {
            let mut items = this.items.borrow_mut();
            for key in items.drain(..) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        // -- toArray --
        /// Return all stack items as an array table (bottom to top).
        /// @return | table | Array of all values.
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
/// Lua-facing FIFO queue with optional capacity limit. Supports enqueue/dequeue from both ends.
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
        // -- enqueue --
        /// Add a value to the back of the queue. Returns false if at capacity.
        /// @param | value | boolean|number|string|table | The value to enqueue.
        /// @return | boolean | True if enqueued, false if full.
        methods.add_method("enqueue", |lua, this, value: LuaValue| {
            let len = this.items.borrow().len();
            if this.meta.is_full(len) {
                return Ok(false);
            }
            let key = lua.create_registry_value(value)?;
            this.items.borrow_mut().push_back(key);
            Ok(true)
        });
        // -- enqueueFront --
        /// Add a value to the front of the queue (priority insertion). Returns false if at capacity.
        /// @param | value | boolean|number|string|table | The value to insert at the front.
        /// @return | boolean | True if enqueued, false if full.
        methods.add_method("enqueueFront", |lua, this, value: LuaValue| {
            let len = this.items.borrow().len();
            if this.meta.is_full(len) {
                return Ok(false);
            }
            let key = lua.create_registry_value(value)?;
            this.items.borrow_mut().push_front(key);
            Ok(true)
        });
        // -- dequeue --
        /// Remove and return the front value. Returns nil if empty.
        /// @return | boolean|number|string|table|nil | The dequeued value, or nil.
        methods.add_method("dequeue", |lua, this, ()| {
            if let Some(key) = this.items.borrow_mut().pop_front() {
                let v: LuaValue = lua.registry_value(&key)?;
                lua.remove_registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        // -- dequeueBack --
        /// Remove and return the back value. Returns nil if empty.
        /// @return | boolean|number|string|table|nil | The dequeued value, or nil.
        methods.add_method("dequeueBack", |lua, this, ()| {
            if let Some(key) = this.items.borrow_mut().pop_back() {
                let v: LuaValue = lua.registry_value(&key)?;
                lua.remove_registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        // -- front --
        /// Return the front value without removing it. Returns nil if empty.
        /// @return | boolean|number|string|table|nil | The front value, or nil.
        methods.add_method("front", |lua, this, ()| {
            if let Some(key) = this.items.borrow().front() {
                let v: LuaValue = lua.registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        // -- back --
        /// Return the back value without removing it. Returns nil if empty.
        /// @return | boolean|number|string|table|nil | The back value, or nil.
        methods.add_method("back", |lua, this, ()| {
            if let Some(key) = this.items.borrow().back() {
                let v: LuaValue = lua.registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        // -- peekAt --
        /// Return the value at a 1-based index without removing it. Returns nil if out of range.
        /// @param | index | number | 1-based position.
        /// @return | boolean|number|string|table|nil | The value, or nil.
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
        // -- insertAt --
        /// Insert a value at a 1-based index in the queue. Returns false if at capacity.
        /// @param | index | number | 1-based insertion position.
        /// @param | value | boolean|number|string|table | The value to insert.
        /// @return | boolean | True if inserted, false if full.
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
        // -- removeAt --
        /// Remove and return the value at a 1-based index. Returns nil if out of range.
        /// @param | index | number | 1-based position to remove.
        /// @return | boolean|number|string|table|nil | The removed value, or nil.
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
        // -- len --
        /// Return the current number of items in the queue.
        /// @return | number | Item count.
        methods.add_method("len", |_, this, ()| Ok(this.items.borrow().len()));
        // -- isEmpty --
        /// Check whether the queue is empty.
        /// @return | boolean | True if empty.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.items.borrow().is_empty()));
        // -- isFull --
        /// Check whether the queue has reached its capacity limit.
        /// @return | boolean | True if full.
        methods.add_method("isFull", |_, this, ()| {
            Ok(this.meta.is_full(this.items.borrow().len()))
        });
        // -- clear --
        /// Remove all items from the queue.
        methods.add_method("clear", |lua, this, ()| {
            let mut items = this.items.borrow_mut();
            for key in items.drain(..) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        // -- toArray --
        /// Return all queue items as an array table (front to back).
        /// @return | table | Array of all values.
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
/// Lua-facing dynamic array list with indexed access, insertion, removal, and search.
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
        // -- add --
        /// Append a value to the end of the list.
        /// @param | value | boolean|number|string|table | The value to append.
        methods.add_method("add", |lua, this, value: LuaValue| {
            let key = lua.create_registry_value(value)?;
            this.items.borrow_mut().push(key);
            Ok(())
        });
        // -- push --
        /// Append a value to the end of the list (alias for add).
        /// @param | value | boolean|number|string|table | The value to append.
        methods.add_method("push", |lua, this, value: LuaValue| {
            let key = lua.create_registry_value(value)?;
            this.items.borrow_mut().push(key);
            Ok(())
        });
        // -- unshift --
        /// Insert a value at the beginning of the list.
        /// @param | value | boolean|number|string|table | The value to prepend.
        methods.add_method("unshift", |lua, this, value: LuaValue| {
            let key = lua.create_registry_value(value)?;
            this.items.borrow_mut().insert(0, key);
            Ok(())
        });
        // -- get --
        /// Get the value at a 1-based index. Returns nil if out of range.
        /// @param | index | number | 1-based position.
        /// @return | boolean|number|string|table|nil | The value, or nil.
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
        // -- set --
        /// Replace the value at a 1-based index. Errors if index is 0 or out of range.
        /// @param | index | number | 1-based position.
        /// @param | value | boolean|number|string|table | The new value.
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
        // -- insert --
        /// Insert a value at a 1-based index, shifting subsequent items right.
        /// @param | index | number | 1-based insertion position.
        /// @param | value | boolean|number|string|table | The value to insert.
        methods.add_method("insert", |lua, this, (index, value): (usize, LuaValue)| {
            let len = this.items.borrow().len();
            let idx = if index == 0 { 0 } else { (index - 1).min(len) };
            let key = lua.create_registry_value(value)?;
            this.items.borrow_mut().insert(idx, key);
            Ok(())
        });
        // -- remove --
        /// Remove and return the value at a 1-based index. Returns nil if out of range.
        /// @param | index | number | 1-based position to remove.
        /// @return | boolean|number|string|table|nil | The removed value, or nil.
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
        // -- pop --
        /// Remove and return the last value. Returns nil if empty.
        /// @return | boolean|number|string|table|nil | The popped value, or nil.
        methods.add_method("pop", |lua, this, ()| {
            if let Some(key) = this.items.borrow_mut().pop() {
                let v: LuaValue = lua.registry_value(&key)?;
                lua.remove_registry_value(key)?;
                Ok(v)
            } else {
                Ok(LuaValue::Nil)
            }
        });
        // -- shift --
        /// Remove and return the first value. Returns nil if empty.
        /// @return | boolean|number|string|table|nil | The shifted value, or nil.
        methods.add_method("shift", |lua, this, ()| {
            if this.items.borrow().is_empty() {
                return Ok(LuaValue::Nil);
            }
            let key = this.items.borrow_mut().remove(0);
            let v: LuaValue = lua.registry_value(&key)?;
            lua.remove_registry_value(key)?;
            Ok(v)
        });
        // -- indexOf --
        /// Find the 1-based index of the first occurrence of a value. Returns nil if not found.
        /// @param | value | boolean|number|string|table | The value to search for.
        /// @return | number? | The 1-based index, or nil.
        methods.add_method("indexOf", |lua, this, value: LuaValue| {
            for (i, key) in this.items.borrow().iter().enumerate() {
                let v: LuaValue = lua.registry_value(key)?;
                if lua.pack(v.clone())? == lua.pack(value.clone())? {
                    return Ok(Some(i + 1));
                }
            }
            Ok(None::<usize>)
        });
        // -- reverse --
        /// Reverse the order of all items in the list in-place.
        methods.add_method("reverse", |_, this, ()| {
            this.items.borrow_mut().reverse();
            Ok(())
        });
        // -- len --
        /// Return the number of items in the list.
        /// @return | number | Item count.
        methods.add_method("len", |_, this, ()| Ok(this.items.borrow().len()));
        // -- isEmpty --
        /// Check whether the list is empty.
        /// @return | boolean | True if empty.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.items.borrow().is_empty()));
        // -- contains --
        /// Check whether the list contains a specific value.
        /// @param | value | boolean|number|string|table | The value to search for.
        /// @return | boolean | True if found.
        methods.add_method("contains", |lua, this, value: LuaValue| {
            for key in this.items.borrow().iter() {
                let v: LuaValue = lua.registry_value(key)?;
                if lua.pack(v.clone())? == lua.pack(value.clone())? {
                    return Ok(true);
                }
            }
            Ok(false)
        });
        // -- clear --
        /// Remove all items from the list.
        methods.add_method("clear", |lua, this, ()| {
            let mut items = this.items.borrow_mut();
            for key in items.drain(..) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
        // -- toArray --
        /// Return all items as an array table.
        /// @return | table | Array of all values.
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
/// Lua-facing string set with add/remove/has operations and set algebra (union, intersection).
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
        // -- add --
        /// Add a string to the set. Returns true if it was not already present.
        /// @param | key | string | The string to add.
        /// @return | boolean | True if newly added, false if already existed.
        methods.add_method("add", |_, this, key: String| {
            Ok(this.items.borrow_mut().insert(key))
        });
        // -- remove --
        /// Remove a string from the set. Returns true if it was present.
        /// @param | key | string | The string to remove.
        /// @return | boolean | True if removed, false if not found.
        methods.add_method("remove", |_, this, key: String| {
            Ok(this.items.borrow_mut().remove(&key))
        });
        // -- has --
        /// Check whether a string is in the set.
        /// @param | key | string | The string to check.
        /// @return | boolean | True if present.
        methods.add_method("has", |_, this, key: String| {
            Ok(this.items.borrow().contains(&key))
        });
        // -- len --
        /// Return the number of items in the set.
        /// @return | number | Item count.
        methods.add_method("len", |_, this, ()| Ok(this.items.borrow().len()));
        // -- isEmpty --
        /// Check whether the set is empty.
        /// @return | boolean | True if empty.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.items.borrow().is_empty()));
        // -- toArray --
        /// Return all set items as an array table.
        /// @return | table | Array of string values.
        methods.add_method("toArray", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, k) in this.items.borrow().iter().enumerate() {
                tbl.set(i + 1, k.as_str())?;
            }
            Ok(tbl)
        });
        // -- clear --
        /// Remove all items from the set.
        methods.add_method("clear", |_, this, ()| {
            this.items.borrow_mut().clear();
            Ok(())
        });
        // -- union --
        /// Return a new set containing all items from both this set and another.
        /// @param | other | LSet | The other set to merge with.
        /// @return | LSet | A new set with the union of both.
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
        // -- intersection --
        /// Return a new set containing only items present in both this set and another.
        /// @param | other | LSet | The other set to intersect with.
        /// @return | LSet | A new set with only shared items.
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
/// Lua-facing string-keyed dictionary (map) with keys(), values(), entries(), and merge operations.
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
        // -- set --
        /// Set a key-value pair in the map. Replaces any existing value for the same key.
        /// @param | key | string | The key.
        /// @param | value | boolean|number|string|table | The value to store.
        methods.add_method("set", |lua, this, (key, value): (String, LuaValue)| {
            let rk = lua.create_registry_value(value)?;
            if let Some(old) = this.items.borrow_mut().insert(key, rk) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });
        // -- get --
        /// Retrieve the value for a key. Returns nil if the key does not exist.
        /// @param | key | string | The key to look up.
        /// @return | boolean|number|string|table|nil | The value, or nil.
        methods.add_method("get", |lua, this, key: String| {
            let items = this.items.borrow();
            match items.get(&key) {
                Some(rk) => Ok(lua.registry_value::<LuaValue>(rk)?),
                None => Ok(LuaValue::Nil),
            }
        });
        // -- has --
        /// Check whether a key exists in the map.
        /// @param | key | string | The key to check.
        /// @return | boolean | True if present.
        methods.add_method("has", |_, this, key: String| {
            Ok(this.items.borrow().contains_key(&key))
        });
        // -- remove --
        /// Remove a key from the map. Returns true if it was present.
        /// @param | key | string | The key to remove.
        /// @return | boolean | True if removed, false if not found.
        methods.add_method("remove", |lua, this, key: String| {
            if let Some(rk) = this.items.borrow_mut().remove(&key) {
                lua.remove_registry_value(rk)?;
                Ok(true)
            } else {
                Ok(false)
            }
        });
        // -- len --
        /// Return the number of key-value pairs.
        /// @return | number | Entry count.
        methods.add_method("len", |_, this, ()| Ok(this.items.borrow().len()));
        // -- isEmpty --
        /// Check whether the map has no entries.
        /// @return | boolean | True if empty.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.items.borrow().is_empty()));
        // -- keys --
        /// Return an array of all keys in the map.
        /// @return | table | Array of key strings.
        methods.add_method("keys", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, k) in this.items.borrow().keys().enumerate() {
                tbl.set(i + 1, k.as_str())?;
            }
            Ok(tbl)
        });
        // -- values --
        /// Return an array of all values in the map.
        /// @return | table | Array of values.
        methods.add_method("values", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, rk) in this.items.borrow().values().enumerate() {
                let v: LuaValue = lua.registry_value(rk)?;
                tbl.set(i + 1, v)?;
            }
            Ok(tbl)
        });
        // -- entries --
        /// Return an array of {key, value} tables for all entries.
        /// @return | table | Array of entry tables.
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
        // -- merge --
        /// Copy all entries from another LMap into this map. Existing keys are overwritten.
        /// @param | other | LMap | The source map to merge from.
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
        // -- clear --
        /// Remove all entries from the map.
        methods.add_method("clear", |lua, this, ()| {
            let drained: Vec<(String, LuaRegistryKey)> = this.items.borrow_mut().drain().collect();
            for (_, rk) in drained {
                lua.remove_registry_value(rk)?;
            }
            Ok(())
        });
    }
}
/// Lua-facing weighted random selection pool. Add items with weights and pick random selections.
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
        // -- add --
        /// Add an item with a relative weight. Higher weight = higher selection probability.
        /// @param | weight | number | The selection weight (must be > 0).
        /// @param | value | boolean|number|string|table | The payload value returned on pick.
        /// @param | label | string? | Optional human-readable label.
        /// @return | number | The internal ID of the added entry.
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
        // -- remove --
        /// Remove an item by its ID. Returns true if it existed.
        /// @param | id | number | The entry ID to remove.
        /// @return | boolean | True if removed.
        methods.add_method("remove", |lua, this, id: u64| {
            let removed = this.pool.borrow_mut().remove(id);
            if removed {
                if let Some(rk) = this.payloads.borrow_mut().remove(&id) {
                    lua.remove_registry_value(rk)?;
                }
            }
            Ok(removed)
        });
        // -- setWeight --
        /// Change the weight of an existing entry.
        /// @param | id | number | The entry ID.
        /// @param | weight | number | The new weight value.
        /// @return | boolean | True if the entry was found and updated.
        methods.add_method("setWeight", |_, this, (id, weight): (u64, f64)| {
            Ok(this.pool.borrow_mut().set_weight(id, weight))
        });
        // -- pick --
        /// Pick one item using a random sample value in [0, 1). Returns its value or nil.
        /// @param | sample | number | A random number in [0, 1) range.
        /// @return | boolean|number|string|table|nil | The selected item's value, or nil if pool is empty.
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
        // -- pickN --
        /// Pick multiple unique items. Requires an array of random samples.
        /// @param | count | number | Number of items to pick.
        /// @param | samples | table | Array of random numbers in [0, 1).
        /// @return | table | Array of picked values.
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
        // -- totalWeight --
        /// Return the sum of all entry weights.
        /// @return | number | Total weight.
        methods.add_method("totalWeight", |_, this, ()| {
            Ok(this.pool.borrow().total_weight())
        });
        // -- len --
        /// Return the number of entries in the pool.
        /// @return | number | Entry count.
        methods.add_method("len", |_, this, ()| Ok(this.pool.borrow().len()));
        // -- isEmpty --
        /// Check whether the pool has no entries.
        /// @return | boolean | True if empty.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.pool.borrow().is_empty()));
        // -- clearAll --
        /// Remove all entries from the pool.
        methods.add_method("clearAll", |lua, this, ()| {
            this.pool.borrow_mut().clear();
            let drained: Vec<(u64, LuaRegistryKey)> = this.payloads.borrow_mut().drain().collect();
            for (_, rk) in drained {
                lua.remove_registry_value(rk)?;
            }
            Ok(())
        });
        // -- getRevision --
        /// Return the revision counter. Increments on any add/remove/weight change.
        /// @return | number | Revision number.
        methods.add_method("getRevision", |_, this, ()| Ok(this.pool.borrow().revision));
    }
}
/// Lua-facing behavior tree for AI decision-making with sequences, selectors, parallels, inverters, repeaters, and leaf actions.
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
        // -- addSequence --
        /// Create a sequence composite node. All children must succeed for this node to succeed.
        /// @param | label | string? | Optional debug label.
        /// @return | number | The node ID.
        methods.add_method("addSequence", |_, this, label: Option<String>| {
            Ok(this
                .tree
                .borrow_mut()
                .add_sequence(label.as_deref().unwrap_or("")))
        });
        // -- addSelector --
        /// Create a selector (fallback) composite node. Succeeds if any child succeeds.
        /// @param | label | string? | Optional debug label.
        /// @return | number | The node ID.
        methods.add_method("addSelector", |_, this, label: Option<String>| {
            Ok(this
                .tree
                .borrow_mut()
                .add_selector(label.as_deref().unwrap_or("")))
        });
        // -- addParallel --
        /// Create a parallel composite node that runs all children simultaneously.
        /// @param | minSuccess | number | Minimum successful children required for this node to succeed.
        /// @param | label | string? | Optional debug label.
        /// @return | number | The node ID.
        methods.add_method(
            "addParallel",
            |_, this, (min_success, label): (usize, Option<String>)| {
                Ok(this
                    .tree
                    .borrow_mut()
                    .add_parallel(min_success, label.as_deref().unwrap_or("")))
            },
        );
        // -- addInverter --
        /// Create a decorator node that inverts its child's result (success ↔ failure).
        /// @param | label | string? | Optional debug label.
        /// @return | number | The node ID.
        methods.add_method("addInverter", |_, this, label: Option<String>| {
            Ok(this
                .tree
                .borrow_mut()
                .add_inverter(label.as_deref().unwrap_or("")))
        });
        // -- addRepeat --
        /// Create a decorator node that repeats its child a fixed number of times.
        /// @param | count | number | Number of repetitions.
        /// @param | label | string? | Optional debug label.
        /// @return | number | The node ID.
        methods.add_method(
            "addRepeat",
            |_, this, (count, label): (usize, Option<String>)| {
                Ok(this
                    .tree
                    .borrow_mut()
                    .add_repeat(count, label.as_deref().unwrap_or("")))
            },
        );
        // -- addLeaf --
        /// Create a leaf (action) node that will invoke a named callback function on tick.
        /// @param | name | string | The leaf name (must match a setLeaf registration).
        /// @param | label | string? | Optional debug label.
        /// @return | number | The node ID.
        methods.add_method(
            "addLeaf",
            |_, this, (name, label): (String, Option<String>)| {
                Ok(this
                    .tree
                    .borrow_mut()
                    .add_leaf(&name, label.as_deref().unwrap_or("")))
            },
        );
        // -- addChild --
        /// Attach a child node to a parent composite or decorator node.
        /// @param | parentId | number | The parent node ID.
        /// @param | childId | number | The child node ID to attach.
        /// @return | boolean | True if attached successfully.
        methods.add_method("addChild", |_, this, (parent_id, child_id): (u32, u32)| {
            Ok(this.tree.borrow_mut().add_child(parent_id, child_id))
        });
        // -- setRoot --
        /// Designate a node as the tree's root. Tick evaluation starts here.
        /// @param | id | number | The node ID to set as root.
        /// @return | boolean | True if the node exists.
        methods.add_method("setRoot", |_, this, id: u32| {
            Ok(this.tree.borrow_mut().set_root(id))
        });
        // -- setLeaf --
        /// Register or replace the callback function for a named leaf. The function must return "success", "failure", or "running".
        /// @param | name | string | The leaf name (matching addLeaf).
        /// @param | callback | function | A function returning a status string.
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
        // -- tick --
        /// Execute one tick of the behavior tree from the root. Returns the root node's status.
        /// @return | string | One of "success", "failure", or "running".
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
        // -- resetState --
        /// Reset the tree's running state. Use between encounters or when restarting AI logic.
        methods.add_method("resetState", |_, this, ()| {
            this.run_state.borrow_mut().reset();
            Ok(())
        });
        // -- nodeCount --
        /// Return the total number of nodes in the tree.
        /// @return | number | Node count.
        methods.add_method("nodeCount", |_, this, ()| {
            Ok(this.tree.borrow().node_count())
        });
        // -- clearAll --
        /// Remove all nodes and leaf functions, resetting the tree to empty.
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
/// Lua-facing graph data structure with directed/undirected edges, BFS, DFS, and connectivity queries.
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
        // -- addNode --
        /// Add a node to the graph with an optional label and payload value.
        /// @param | label | string? | Optional node label.
        /// @param | value | boolean|number|string|table? | Optional payload stored with the node.
        /// @return | number | The new node's ID.
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
        // -- removeNode --
        /// Remove a node and all its connected edges. Returns true if the node existed.
        /// @param | id | number | The node ID to remove.
        /// @return | boolean | True if removed.
        methods.add_method("removeNode", |lua, this, id: u32| {
            let removed = this.graph.borrow_mut().remove_node(id);
            if removed {
                if let Some(rk) = this.node_payloads.borrow_mut().remove(&id) {
                    lua.remove_registry_value(rk)?;
                }
            }
            Ok(removed)
        });
        // -- getNodeValue --
        /// Retrieve the payload value stored on a node. Returns nil if no payload.
        /// @param | id | number | The node ID.
        /// @return | boolean|number|string|table|nil | The payload, or nil.
        methods.add_method("getNodeValue", |lua, this, id: u32| {
            let payloads = this.node_payloads.borrow();
            match payloads.get(&id) {
                Some(rk) => Ok(lua.registry_value::<LuaValue>(rk)?),
                None => Ok(LuaValue::Nil),
            }
        });
        // -- addEdge --
        /// Add a directed (or undirected) edge between two nodes with optional weight and label.
        /// @param | from | number | Source node ID.
        /// @param | to | number | Target node ID.
        /// @param | weight | number? | Edge weight (default 1.0).
        /// @param | label | string? | Optional edge label.
        /// @return | number | The new edge's ID.
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
        // -- removeEdge --
        /// Remove an edge by its ID. Returns true if it existed.
        /// @param | id | number | The edge ID to remove.
        /// @return | boolean | True if removed.
        methods.add_method("removeEdge", |lua, this, id: u32| {
            let removed = this.graph.borrow_mut().remove_edge(id);
            if removed {
                if let Some(rk) = this.edge_payloads.borrow_mut().remove(&id) {
                    lua.remove_registry_value(rk)?;
                }
            }
            Ok(removed)
        });
        // -- neighbors --
        /// Return an array of node IDs directly connected to the given node.
        /// @param | id | number | The node ID to query.
        /// @return | table | Array of neighbor node IDs.
        methods.add_method("neighbors", |lua, this, id: u32| {
            let nbs = this.graph.borrow().neighbors(id);
            let tbl = lua.create_table()?;
            for (i, nb) in nbs.iter().enumerate() {
                tbl.set(i + 1, *nb)?;
            }
            Ok(tbl)
        });
        // -- bfs --
        /// Perform a breadth-first search from a node. Returns visited node IDs in BFS order.
        /// @param | start | number | The starting node ID.
        /// @return | table | Array of visited node IDs.
        methods.add_method("bfs", |lua, this, start: u32| {
            let order = this.graph.borrow().bfs(start);
            let tbl = lua.create_table()?;
            for (i, id) in order.iter().enumerate() {
                tbl.set(i + 1, *id)?;
            }
            Ok(tbl)
        });
        // -- dfs --
        /// Perform a depth-first search from a node. Returns visited node IDs in DFS order.
        /// @param | start | number | The starting node ID.
        /// @return | table | Array of visited node IDs.
        methods.add_method("dfs", |lua, this, start: u32| {
            let order = this.graph.borrow().dfs(start);
            let tbl = lua.create_table()?;
            for (i, id) in order.iter().enumerate() {
                tbl.set(i + 1, *id)?;
            }
            Ok(tbl)
        });
        // -- isConnected --
        /// Check whether there is any path from one node to another.
        /// @param | from | number | Source node ID.
        /// @param | to | number | Target node ID.
        /// @return | boolean | True if a path exists.
        methods.add_method("isConnected", |_, this, (from, to): (u32, u32)| {
            Ok(this.graph.borrow().is_connected(from, to))
        });
        // -- hasNode --
        /// Check whether a node with the given ID exists in the graph.
        /// @param | id | number | Node ID to check.
        /// @return | boolean | True if the node exists.
        methods.add_method("hasNode", |_, this, id: u32| {
            Ok(this.graph.borrow().has_node(id))
        });
        // -- nodeCount --
        /// Return the total number of nodes in the graph.
        /// @return | number | Node count.
        methods.add_method("nodeCount", |_, this, ()| {
            Ok(this.graph.borrow().node_count())
        });
        // -- edgeCount --
        /// Return the total number of edges in the graph.
        /// @return | number | Edge count.
        methods.add_method("edgeCount", |_, this, ()| {
            Ok(this.graph.borrow().edge_count())
        });
        // -- clearAll --
        /// Remove all nodes, edges, and payloads from the graph.
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
/// Register the `lurek.patterns` module, exposing all pattern constructors to Lua.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let patterns = lua.create_table()?;
    // -- newEventBus --
    /// Create a new publish/subscribe event bus for decoupled communication between game systems.
    /// @param | name | string? | Optional name for debugging.
    /// @return | LEventBus | A new event bus instance.
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
    // -- newObjectPool --
    /// Create a new object pool for reusing pre-allocated game objects to reduce allocation overhead.
    /// @return | LObjectPool | A new object pool instance.
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
    // -- newCommandStack --
    /// Create a new undo/redo command stack for recording and reversing player or editor actions.
    /// @param | maxSize | number? | Maximum history depth (0 = unlimited).
    /// @return | LCommandStack | A new command stack instance.
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
    // -- newServiceLocator --
    /// Create a new service locator for registering and retrieving shared services by name at runtime.
    /// @return | LServiceLocator | A new service locator instance.
    patterns.set(
        "newServiceLocator",
        lua.create_function(|_lua, ()| {
            Ok(LuaServiceLocator {
                locator: Rc::new(RefCell::new(crate::patterns::ServiceLocator::new())),
                services: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    // -- newFactory --
    /// Create a new factory for producing typed game objects from registered constructor functions.
    /// @return | LFactory | A new factory instance.
    patterns.set(
        "newFactory",
        lua.create_function(|_lua, ()| {
            Ok(LuaFactory {
                factory: Rc::new(RefCell::new(crate::patterns::Factory::new())),
                constructors: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    // -- newSimpleState --
    /// Create a new finite state machine with enter/exit/update callbacks per state.
    /// @return | LSimpleState | A new state machine instance.
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
    // -- newBlackboard --
    /// Create a new shared key-value blackboard supporting reactive watchers for game logic variables.
    /// @param | name | string? | Optional name for debugging.
    /// @return | LBlackboard | A new blackboard instance.
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
    // -- newObserver --
    /// Create a new reactive observer that stores values and notifies subscribers when they change.
    /// @param | name | string? | Optional name for debugging.
    /// @return | LObserver | A new observer instance.
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
    // -- newThrottle --
    /// Create a new throttle that limits how often an action can fire, enforcing a minimum interval.
    /// @param | interval | number | Minimum seconds between fires.
    /// @return | LThrottle | A new throttle instance.
    patterns.set(
        "newThrottle",
        lua.create_function(|_lua, interval: f64| {
            Ok(LuaThrottle {
                throttle: Rc::new(RefCell::new(crate::patterns::Throttle::new(interval))),
                callback: Rc::new(RefCell::new(None)),
            })
        })?,
    )?;
    // -- newDebounce --
    /// Create a new debounce that delays firing until input stops for a specified wait period.
    /// @param | wait | number | Seconds of inactivity before firing.
    /// @return | LDebounce | A new debounce instance.
    patterns.set(
        "newDebounce",
        lua.create_function(|_lua, wait: f64| {
            Ok(LuaDebounce {
                debounce: Rc::new(RefCell::new(crate::patterns::Debounce::new(wait))),
                callback: Rc::new(RefCell::new(None)),
            })
        })?,
    )?;
    // -- newPriorityQueue --
    /// Create a new priority queue that orders elements by numeric priority (highest first).
    /// @param | name | string? | Optional name for debugging.
    /// @return | LPriorityQueue | A new priority queue instance.
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
    // -- newRing --
    /// Create a new fixed-size ring buffer for numeric or string values. Oldest entries are overwritten when full.
    /// @param | capacity | number | Maximum number of entries the ring can hold.
    /// @param | name | string? | Optional name for debugging.
    /// @return | LRing | A new ring buffer instance.
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
    // -- newFunnel --
    /// Create a new batching funnel that collects events over a time window and flushes them together.
    /// @param | window | number | Time window in seconds before auto-flush.
    /// @param | maxEntries | number? | Maximum entries before forced flush (0 = no limit).
    /// @param | name | string? | Optional name for debugging.
    /// @return | LFunnel | A new funnel instance.
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
    // -- newRelationshipManager --
    /// Create a new relationship manager for tracking numeric values and named levels between entity pairs.
    /// @return | LRelationshipManager | A new relationship manager instance.
    patterns.set(
        "newRelationshipManager",
        lua.create_function(|_, ()| {
            Ok(LuaRelationshipManager {
                rm: Rc::new(RefCell::new(crate::ecs::RelationshipManager::new())),
            })
        })?,
    )?;
    // -- newMediator --
    /// Create a new mediator for channel-based message passing between decoupled game systems.
    /// @return | LMediator | A new mediator instance.
    patterns.set(
        "newMediator",
        lua.create_function(|_, ()| {
            Ok(LuaMediator {
                mediator: Rc::new(RefCell::new(crate::patterns::Mediator::new())),
                callbacks: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    // -- newStrategy --
    /// Create a new strategy pattern container for hot-swappable algorithm implementations.
    /// @return | LStrategy | A new strategy instance.
    patterns.set(
        "newStrategy",
        lua.create_function(|_, ()| {
            Ok(LuaStrategy {
                strategy: Rc::new(RefCell::new(crate::patterns::Strategy::new())),
                callbacks: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    // -- newStack --
    /// Create a new LIFO stack with optional capacity limit.
    /// @param | capacity | number? | Maximum items (0 = unlimited).
    /// @return | LStack | A new stack instance.
    patterns.set(
        "newStack",
        lua.create_function(|_, capacity: Option<usize>| {
            Ok(LuaStack {
                meta: crate::patterns::StackMeta::new(capacity.unwrap_or(0)),
                items: Rc::new(RefCell::new(Vec::new())),
            })
        })?,
    )?;
    // -- newQueue --
    /// Create a new FIFO queue with optional capacity limit.
    /// @param | capacity | number? | Maximum items (0 = unlimited).
    /// @return | LQueue | A new queue instance.
    patterns.set(
        "newQueue",
        lua.create_function(|_, capacity: Option<usize>| {
            Ok(LuaQueue {
                meta: crate::patterns::QueueMeta::new(capacity.unwrap_or(0)),
                items: Rc::new(RefCell::new(VecDeque::new())),
            })
        })?,
    )?;
    // -- newList --
    /// Create a new dynamic array list with indexed access, insertion, removal, and search.
    /// @return | LList | A new list instance.
    patterns.set(
        "newList",
        lua.create_function(|_, ()| {
            Ok(LuaList {
                items: Rc::new(RefCell::new(Vec::new())),
            })
        })?,
    )?;
    // -- newSet --
    /// Create a new string set with add/remove/has operations and set algebra (union, intersection).
    /// @return | LSet | A new set instance.
    patterns.set(
        "newSet",
        lua.create_function(|_, ()| {
            Ok(LuaSet {
                items: Rc::new(RefCell::new(HashSet::new())),
            })
        })?,
    )?;
    // -- newMap --
    /// Create a new string-keyed dictionary (map) with keys/values/entries access and merge support.
    /// @return | LMap | A new map instance.
    patterns.set(
        "newMap",
        lua.create_function(|_, ()| {
            Ok(LuaMap {
                items: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    // -- newWeightedRandom --
    /// Create a new weighted random selection pool. Add items with weights and pick random selections.
    /// @return | LWeightedRandom | A new weighted random pool instance.
    patterns.set(
        "newWeightedRandom",
        lua.create_function(|_, ()| {
            Ok(LuaWeightedRandom {
                pool: Rc::new(RefCell::new(crate::patterns::WeightedRandom::new())),
                payloads: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    // -- newBehaviorTree --
    /// Create a new behavior tree for AI decision-making with sequences, selectors, parallels, and leaf actions.
    /// @return | LBehaviorTree | A new behavior tree instance.
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
    // -- newGraph --
    /// Create a new graph data structure with directed or undirected edges, BFS, DFS, and connectivity queries.
    /// @param | undirected | boolean? | If true, edges are bidirectional (default false).
    /// @return | LGraph | A new graph instance.
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
