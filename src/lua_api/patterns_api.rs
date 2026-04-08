//! Registers the `luna.patterns.*` software design patterns API.
//!
//! Provides factory functions and UserData wrappers for reusable patterns:
//! EventBus (prioritized pub-sub), ObjectPool (object reuse), CommandStack
//! (undo/redo), ServiceLocator (DI container), Factory (named constructors),
//! and SimpleState (finite state machine).

use std::cell::RefCell;
use std::collections::HashMap;
use std::collections::VecDeque;
use std::rc::Rc;

use mlua::prelude::*;

use crate::engine::SharedState;
use crate::lua_api::lua_types::{add_type_methods, LunaType};

// ===========================================================================
// EventBus
// ===========================================================================

/// Lua wrapper for the EventBus pattern.
#[derive(Clone)]
struct LuaEventBus {
    bus: Rc<RefCell<crate::patterns::EventBus>>,
    callbacks: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
}

impl LunaType for LuaEventBus {
    const TYPE_NAME: &'static str = "EventBus";
    const TYPE_HIERARCHY: &'static [&'static str] = &["EventBus", "Object"];
}

impl LuaUserData for LuaEventBus {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // -- on --------------------------------------------------------------
        /// Registers a listener callback for an event.
        /// @param event : string
        /// @param callback : function
        /// @param priority : integer?
        /// @return integer
        methods.add_method("on", |lua, this, (event, callback, priority): (String, LuaFunction, Option<i64>)| {
            let priority = priority.unwrap_or(0);
            let id = this.bus.borrow_mut().subscribe(&event, priority, false);
            let key = lua.create_registry_value(callback)?;
            this.callbacks.borrow_mut().insert(id, key);
            Ok(id)
        });

        // -- off -------------------------------------------------------------
        /// Removes a previously registered event listener by subscription ID.
        /// @param id : integer
        methods.add_method("off", |lua, this, id: u64| {
            this.bus.borrow_mut().unsubscribe(id);
            if let Some(key) = this.callbacks.borrow_mut().remove(&id) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });

        // -- emit ------------------------------------------------------------
        /// Dispatches an event, calling all registered listeners in priority order.
        /// @param args : MultiValue
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

        // -- clear -----------------------------------------------------------
        /// Removes all listeners for a specific event.
        /// @param event : string
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

        // -- clearAll --------------------------------------------------------
        /// Removes all listeners on this EventBus.
        methods.add_method("clearAll", |lua, this, ()| {
            let _ = this.bus.borrow_mut().clear_all();
            let drained: Vec<(u64, LuaRegistryKey)> =
                this.callbacks.borrow_mut().drain().collect();
            for (_, key) in drained {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });

        // -- getListenerCount ------------------------------------------------
        /// Returns the number of listeners registered for an event.
        /// @param event : string
        /// @return integer
        methods.add_method("getListenerCount", |_lua, this, event: String| {
            Ok(this.bus.borrow().listener_count(&event))
        });

        // -- getEvents -------------------------------------------------------
        /// Returns all event names that have at least one listener.
        /// @return table
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

// ===========================================================================
// ObjectPool
// ===========================================================================

/// Lua wrapper for the ObjectPool pattern.
#[derive(Clone)]
struct LuaObjectPool {
    pool: Rc<RefCell<crate::patterns::ObjectPool>>,
    idle_objects: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
    active_queue: Rc<RefCell<VecDeque<u64>>>,
}

impl LunaType for LuaObjectPool {
    const TYPE_NAME: &'static str = "ObjectPool";
    const TYPE_HIERARCHY: &'static [&'static str] = &["ObjectPool", "Object"];
}

impl LuaUserData for LuaObjectPool {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // -- add -------------------------------------------------------------
        /// Inserts a pre-built object into the available pool.
        /// @param value : any
        methods.add_method("add", |lua, this, value: LuaValue| {
            let total = this.pool.borrow().total_count();
            let new_ids = this.pool.borrow_mut().prewarm(total + 1);
            if let Some(&id) = new_ids.first() {
                let key = lua.create_registry_value(value)?;
                this.idle_objects.borrow_mut().insert(id, key);
            }
            Ok(())
        });

        // -- acquire ---------------------------------------------------------
        /// Acquires an available object from the pool; returns nil if empty.
        /// @return any
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

        // -- release ---------------------------------------------------------
        /// Returns an object to the available pool.
        /// @param value : any
        methods.add_method("release", |lua, this, value: LuaValue| {
            if let Some(id) = this.active_queue.borrow_mut().pop_front() {
                this.pool.borrow_mut().release(id);
                let key = lua.create_registry_value(value)?;
                this.idle_objects.borrow_mut().insert(id, key);
            }
            Ok(())
        });

        // -- getActiveCount --------------------------------------------------
        /// Returns the number of currently active (acquired) objects.
        /// @return integer
        methods.add_method("getActiveCount", |_lua, this, ()| {
            Ok(this.pool.borrow().active_count())
        });

        // -- getAvailableCount -----------------------------------------------
        /// Returns the number of available (idle) objects in the pool.
        /// @return integer
        methods.add_method("getAvailableCount", |_lua, this, ()| {
            Ok(this.pool.borrow().idle_count())
        });

        // -- getTotalCount ---------------------------------------------------
        /// Returns the total number of tracked objects (active + available).
        /// @return integer
        methods.add_method("getTotalCount", |_lua, this, ()| {
            Ok(this.pool.borrow().total_count())
        });

        // -- clearAll --------------------------------------------------------
        /// Clears all objects from the pool, releasing Lua registry values.
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

// ===========================================================================
// CommandStack
// ===========================================================================

/// Lua wrapper for the CommandStack pattern.
#[derive(Clone)]
struct LuaCommandStack {
    stack: Rc<RefCell<crate::patterns::CommandStack>>,
    exec_fns: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
    undo_fns: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
    history_ids: Rc<RefCell<Vec<u64>>>,
}

impl LunaType for LuaCommandStack {
    const TYPE_NAME: &'static str = "CommandStack";
    const TYPE_HIERARCHY: &'static [&'static str] = &["CommandStack", "Object"];
}

impl LuaUserData for LuaCommandStack {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // -- execute ---------------------------------------------------------
        /// Executes a named command and records it in undo/redo history.
        /// @param name : string
        /// @param exec_fn : function
        /// @param undo_fn : function?
        methods.add_method("execute", |lua, this, (name, exec_fn, undo_fn): (String, LuaFunction, Option<LuaFunction>)| {
            let undo_count = this.stack.borrow().undo_count();
            let discarded: Vec<u64> = {
                let mut ids = this.history_ids.borrow_mut();
                ids.drain(undo_count..).collect()
            };
            {
                let mut exec_fns = this.exec_fns.borrow_mut();
                let mut undo_fns = this.undo_fns.borrow_mut();
                for id in discarded {
                    if let Some(k) = exec_fns.remove(&id) { lua.remove_registry_value(k)?; }
                    if let Some(k) = undo_fns.remove(&id) { lua.remove_registry_value(k)?; }
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

            this.exec_fns.borrow_mut().insert(entry_id, lua.create_registry_value(exec_fn)?);
            if let Some(f) = undo_fn {
                this.undo_fns.borrow_mut().insert(entry_id, lua.create_registry_value(f)?);
            }
            Ok(())
        });

        // -- undo ------------------------------------------------------------
        /// Undoes the most recent command. Returns true if successful.
        /// @return boolean
        methods.add_method("undo", |lua, this, ()| {
            let peek_id = this.stack.borrow().peek_undo();
            if let Some(id) = peek_id {
                let has_undo = this.stack.borrow()
                    .get_entry(id)
                    .map(|e| e.has_undo)
                    .unwrap_or(false);
                if !has_undo { return Ok(false); }
                let func_opt = this.undo_fns.borrow()
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

        // -- redo ------------------------------------------------------------
        /// Re-executes the next undone command. Returns true if successful.
        /// @return boolean
        methods.add_method("redo", |lua, this, ()| {
            let peek_id = this.stack.borrow().peek_redo();
            if let Some(id) = peek_id {
                let func_opt = this.exec_fns.borrow()
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

        // -- canUndo ---------------------------------------------------------
        /// Returns true if the most recent command can be undone.
        /// @return boolean
        methods.add_method("canUndo", |_lua, this, ()| {
            let s = this.stack.borrow();
            Ok(s.peek_undo()
                .and_then(|id| s.get_entry(id))
                .map(|e| e.has_undo)
                .unwrap_or(false))
        });

        // -- canRedo ---------------------------------------------------------
        /// Returns true if there is a command available to redo.
        /// @return boolean
        methods.add_method("canRedo", |_lua, this, ()| {
            Ok(this.stack.borrow().redo_count() > 0)
        });

        // -- getHistorySize --------------------------------------------------
        /// Returns the total number of recorded commands (undo + redo).
        /// @return integer
        methods.add_method("getHistorySize", |_lua, this, ()| {
            let s = this.stack.borrow();
            Ok(s.undo_count() + s.redo_count())
        });

        // -- getCurrentName --------------------------------------------------
        /// Returns the name of the most recently executed command, or nil.
        /// @return string?
        methods.add_method("getCurrentName", |_lua, this, ()| {
            let s = this.stack.borrow();
            Ok(s.peek_undo()
                .and_then(|id| s.get_entry(id))
                .map(|e| e.name.clone()))
        });

        // -- clearAll --------------------------------------------------------
        /// Clears all command history, releasing Lua registry values.
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

// ===========================================================================
// ServiceLocator
// ===========================================================================

/// Lua wrapper for the ServiceLocator pattern.
#[derive(Clone)]
struct LuaServiceLocator {
    locator: Rc<RefCell<crate::patterns::ServiceLocator>>,
    services: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
}

impl LunaType for LuaServiceLocator {
    const TYPE_NAME: &'static str = "ServiceLocator";
    const TYPE_HIERARCHY: &'static [&'static str] = &["ServiceLocator", "Object"];
}

impl LuaUserData for LuaServiceLocator {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // -- provide ---------------------------------------------------------
        /// Registers a named service with an associated Lua value.
        /// @param name : string
        /// @param value : any
        methods.add_method("provide", |lua, this, (name, value): (String, LuaValue)| {
            this.locator.borrow_mut().register(&name);
            let key = lua.create_registry_value(value)?;
            if let Some(old) = this.services.borrow_mut().insert(name, key) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });

        // -- locate ----------------------------------------------------------
        /// Retrieves a registered service by name; returns nil if not found.
        /// @param name : string
        /// @return any
        methods.add_method("locate", |lua, this, name: String| {
            let svc = this.services.borrow();
            match svc.get(&name) {
                Some(key) => Ok(lua.registry_value::<LuaValue>(key)?),
                None => Ok(LuaValue::Nil),
            }
        });

        // -- has -------------------------------------------------------------
        /// Returns true if a service with the given name is registered.
        /// @param name : string
        /// @return boolean
        methods.add_method("has", |_lua, this, name: String| {
            Ok(this.locator.borrow().has(&name))
        });

        // -- remove ----------------------------------------------------------
        /// Unregisters and removes a named service.
        /// @param name : string
        methods.add_method("remove", |lua, this, name: String| {
            this.locator.borrow_mut().unregister(&name);
            if let Some(key) = this.services.borrow_mut().remove(&name) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });

        // -- getServices -----------------------------------------------------
        /// Returns a table of all registered service names.
        /// @return table
        methods.add_method("getServices", |lua, this, ()| {
            let names: Vec<String> = this.locator.borrow()
                .names().iter().map(|s| s.to_string()).collect();
            let table = lua.create_table()?;
            for (i, name) in names.iter().enumerate() {
                table.set(i + 1, name.as_str())?;
            }
            Ok(table)
        });

        // -- clearAll --------------------------------------------------------
        /// Removes all registered services.
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

// ===========================================================================
// Factory
// ===========================================================================

/// Lua wrapper for the Factory pattern.
#[derive(Clone)]
struct LuaFactory {
    factory: Rc<RefCell<crate::patterns::Factory>>,
    constructors: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
}

impl LunaType for LuaFactory {
    const TYPE_NAME: &'static str = "Factory";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Factory", "Object"];
}

impl LuaUserData for LuaFactory {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // -- register --------------------------------------------------------
        /// Registers a named type constructor function.
        /// @param type_name : string
        /// @param ctor : function
        methods.add_method("register", |lua, this, (type_name, ctor): (String, LuaFunction)| {
            this.factory.borrow_mut().register(&type_name);
            let key = lua.create_registry_value(ctor)?;
            if let Some(old) = this.constructors.borrow_mut().insert(type_name, key) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });

        // -- create ----------------------------------------------------------
        /// Creates an instance of the named type by invoking its constructor.
        /// @param args : MultiValue
        /// @return any
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

        // -- has -------------------------------------------------------------
        /// Returns true if the named type (or alias) is registered.
        /// @param type_name : string
        /// @return boolean
        methods.add_method("has", |_lua, this, type_name: String| {
            Ok(this.factory.borrow().has(&type_name))
        });

        // -- alias -----------------------------------------------------------
        /// Registers an alias pointing to an existing canonical type name.
        /// @param alias : string
        /// @param canonical : string
        methods.add_method("alias", |_lua, this, (alias, canonical): (String, String)| {
            this.factory.borrow_mut().add_alias(&alias, &canonical);
            Ok(())
        });

        // -- getTypes --------------------------------------------------------
        /// Returns a table of all registered type names.
        /// @return table
        methods.add_method("getTypes", |lua, this, ()| {
            let names: Vec<String> = this.factory.borrow()
                .type_names().iter().map(|s| s.to_string()).collect();
            let table = lua.create_table()?;
            for (i, name) in names.iter().enumerate() {
                table.set(i + 1, name.as_str())?;
            }
            Ok(table)
        });

        // -- remove ----------------------------------------------------------
        /// Unregisters a type constructor (and any aliases pointing to it).
        /// @param type_name : string
        methods.add_method("remove", |lua, this, type_name: String| {
            this.factory.borrow_mut().unregister(&type_name);
            if let Some(key) = this.constructors.borrow_mut().remove(&type_name) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });

        // -- clearAll --------------------------------------------------------
        /// Removes all registered type constructors and aliases.
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

// ===========================================================================
// SimpleState
// ===========================================================================

/// Lua wrapper for the SimpleState finite state machine pattern.
#[derive(Clone)]
struct LuaSimpleState {
    state: Rc<RefCell<crate::patterns::SimpleState>>,
    enter_keys: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
    exit_keys: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
    update_keys: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
}

impl LunaType for LuaSimpleState {
    const TYPE_NAME: &'static str = "SimpleState";
    const TYPE_HIERARCHY: &'static [&'static str] = &["SimpleState", "Object"];
}

impl LuaUserData for LuaSimpleState {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // -- addState --------------------------------------------------------
        /// Registers a named state with optional enter, exit, and update callbacks.
        /// @param name : string
        /// @param callbacks : table?
        methods.add_method("addState", |lua, this, (name, callbacks): (String, Option<LuaTable>)| {
            {
                let mut enter = this.enter_keys.borrow_mut();
                let mut exit = this.exit_keys.borrow_mut();
                let mut update = this.update_keys.borrow_mut();
                if let Some(k) = enter.remove(&name) { lua.remove_registry_value(k)?; }
                if let Some(k) = exit.remove(&name) { lua.remove_registry_value(k)?; }
                if let Some(k) = update.remove(&name) { lua.remove_registry_value(k)?; }
            }

            this.state.borrow_mut().add(&name);

            if let Some(tbl) = callbacks {
                if let Ok(f) = tbl.get::<_, LuaFunction>("enter") {
                    this.enter_keys.borrow_mut().insert(name.clone(), lua.create_registry_value(f)?);
                }
                if let Ok(f) = tbl.get::<_, LuaFunction>("exit") {
                    this.exit_keys.borrow_mut().insert(name.clone(), lua.create_registry_value(f)?);
                }
                if let Ok(f) = tbl.get::<_, LuaFunction>("update") {
                    this.update_keys.borrow_mut().insert(name.clone(), lua.create_registry_value(f)?);
                }
            }
            Ok(())
        });

        // -- transitionTo ----------------------------------------------------
        /// Transitions to a named state, calling exit/enter callbacks as needed.
        /// @param name : string
        /// @return boolean
        methods.add_method("transitionTo", |lua, this, name: String| {
            if !this.state.borrow().has(&name) {
                return Ok(false);
            }

            let current_opt = this.state.borrow().current().map(|s| s.to_string());
            if let Some(ref current) = current_opt {
                let func_opt = this.exit_keys.borrow()
                    .get(current.as_str())
                    .map(|k| lua.registry_value::<LuaFunction>(k));
                if let Some(Ok(func)) = func_opt {
                    func.call::<_, ()>(())?;
                }
            }

            this.state.borrow_mut().set_current(&name);

            let func_opt = this.enter_keys.borrow()
                .get(&name)
                .map(|k| lua.registry_value::<LuaFunction>(k));
            if let Some(Ok(func)) = func_opt {
                func.call::<_, ()>(())?;
            }

            Ok(true)
        });

        // -- update ----------------------------------------------------------
        /// Calls the update callback of the current state with the given delta time.
        /// @param dt : number
        methods.add_method("update", |lua, this, dt: f64| {
            let current_opt = this.state.borrow().current().map(|s| s.to_string());
            if let Some(ref current) = current_opt {
                let func_opt = this.update_keys.borrow()
                    .get(current.as_str())
                    .map(|k| lua.registry_value::<LuaFunction>(k));
                if let Some(Ok(func)) = func_opt {
                    func.call::<_, ()>(dt)?;
                }
            }
            Ok(())
        });

        // -- getCurrent ------------------------------------------------------
        /// Returns the name of the current state, or nil if none is active.
        /// @return string?
        methods.add_method("getCurrent", |_lua, this, ()| {
            Ok(this.state.borrow().current().map(|s| s.to_string()))
        });

        // -- hasState --------------------------------------------------------
        /// Returns true if a state with the given name is registered.
        /// @param name : string
        /// @return boolean
        methods.add_method("hasState", |_lua, this, name: String| {
            Ok(this.state.borrow().has(&name))
        });

        // -- getStates -------------------------------------------------------
        /// Returns a table of all registered state names.
        /// @return table
        methods.add_method("getStates", |lua, this, ()| {
            let names: Vec<String> = this.state.borrow()
                .states().iter().map(|s| s.to_string()).collect();
            let table = lua.create_table()?;
            for (i, name) in names.iter().enumerate() {
                table.set(i + 1, name.as_str())?;
            }
            Ok(table)
        });

        // -- clearAll --------------------------------------------------------
        /// Removes all states and callbacks from this state machine.
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

// ===========================================================================
// Registration
// ===========================================================================

/// Registers `luna.patterns.*` factory functions.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let patterns = lua.create_table()?;

    // luna.patterns.newEventBus(name?) -> EventBus
    /// Creates a new EventBus instance.
    /// @param name : string?
    /// @return any
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

    // luna.patterns.newObjectPool() -> ObjectPool
    /// Creates a new ObjectPool instance.
    /// @return any
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

    // luna.patterns.newCommandStack(maxSize?) -> CommandStack
    /// Creates a new CommandStack instance.
    /// @param max_size : integer?
    /// @return any
    patterns.set(
        "newCommandStack",
        lua.create_function(|_lua, max_size: Option<usize>| {
            Ok(LuaCommandStack {
                stack: Rc::new(RefCell::new(crate::patterns::CommandStack::new(max_size.unwrap_or(0)))),
                exec_fns: Rc::new(RefCell::new(HashMap::new())),
                undo_fns: Rc::new(RefCell::new(HashMap::new())),
                history_ids: Rc::new(RefCell::new(Vec::new())),
            })
        })?,
    )?;

    // luna.patterns.newServiceLocator() -> ServiceLocator
    /// Creates a new ServiceLocator instance.
    /// @return any
    patterns.set(
        "newServiceLocator",
        lua.create_function(|_lua, ()| {
            Ok(LuaServiceLocator {
                locator: Rc::new(RefCell::new(crate::patterns::ServiceLocator::new())),
                services: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;

    // luna.patterns.newFactory() -> Factory
    /// Creates a new Factory instance.
    /// @return any
    patterns.set(
        "newFactory",
        lua.create_function(|_lua, ()| {
            Ok(LuaFactory {
                factory: Rc::new(RefCell::new(crate::patterns::Factory::new())),
                constructors: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;

    // luna.patterns.newSimpleState() -> SimpleState
    /// Creates a new SimpleState finite state machine instance.
    /// @return any
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

    luna.set("patterns", patterns)?;
    Ok(())
}