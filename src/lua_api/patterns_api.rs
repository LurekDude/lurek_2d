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

use crate::runtime::SharedState;
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

/// Registers `lurek.patterns.*` factory functions.
// ===========================================================================
// Blackboard
// ===========================================================================

/// Lua wrapper for the Blackboard pattern.
#[derive(Clone)]
struct LuaBlackboard {
    board: Rc<RefCell<crate::patterns::Blackboard>>,
    /// on_change watchers: subscription id → callback key
    watchers: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
    /// watcher key → watched key (for lookup)
    watcher_keys: Rc<RefCell<HashMap<u64, String>>>,
    next_watcher_id: Rc<RefCell<u64>>,
}

impl LunaType for LuaBlackboard {
    const TYPE_NAME: &'static str = "Blackboard";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Blackboard", "Object"];
}

impl LuaUserData for LuaBlackboard {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // -- set -------------------------------------------------------------
        /// Sets a fact on the blackboard. Accepts boolean, number, or string values.
        /// @param key : string
        /// @param value : any
        methods.add_method("set", |lua, this, (key, value): (String, LuaValue)| {
            let prev_rev = this.board.borrow().revision;
            match &value {
                LuaValue::Boolean(b) => this.board.borrow_mut().set_bool(&key, *b),
                LuaValue::Integer(n) => this.board.borrow_mut().set_number(&key, *n as f64),
                LuaValue::Number(n) => this.board.borrow_mut().set_number(&key, *n),
                LuaValue::String(s) => this.board.borrow_mut().set_text(&key, s.to_str()?.to_string()),
                LuaValue::Nil => this.board.borrow_mut().clear(&key),
                _ => return Err(LuaError::external("Blackboard only supports bool/number/string/nil values")),
            }
            let new_rev = this.board.borrow().revision;
            if new_rev != prev_rev {
                // fire watchers for this key and wildcard
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

        // -- get -------------------------------------------------------------
        /// Gets a fact from the blackboard. Returns nil if not set.
        /// @param key : string
        /// @return any
        methods.add_method("get", |lua, this, key: String| {
            match this.board.borrow().get(&key) {
                Some(crate::patterns::BlackboardValue::Bool(b)) => Ok(LuaValue::Boolean(*b)),
                Some(crate::patterns::BlackboardValue::Number(n)) => Ok(LuaValue::Number(*n)),
                Some(crate::patterns::BlackboardValue::Text(s)) => Ok(LuaValue::String(lua.create_string(s)?)),
                Some(crate::patterns::BlackboardValue::Nil) | None => Ok(LuaValue::Nil),
            }
        });

        // -- has -------------------------------------------------------------
        /// Returns true when the key has a non-nil value.
        /// @param key : string
        /// @return boolean
        methods.add_method("has", |_, this, key: String| {
            Ok(this.board.borrow().has(&key))
        });

        // -- clear -----------------------------------------------------------
        /// Removes a fact from the blackboard.
        /// @param key : string
        methods.add_method("clear", |_, this, key: String| {
            this.board.borrow_mut().clear(&key);
            Ok(())
        });

        // -- keys ------------------------------------------------------------
        /// Returns all set fact keys as a table.
        /// @return table
        methods.add_method("keys", |lua, this, ()| {
            let keys: Vec<String> = this.board.borrow().keys().iter().map(|s| s.to_string()).collect();
            let tbl = lua.create_table()?;
            for (i, k) in keys.iter().enumerate() {     // ── Bindings ─────────────────────────────────────────────────────────────────
tbl.set(i + 1, k.as_str())?; }
            Ok(tbl)
        });

        // -- watch -----------------------------------------------------------
        /// Subscribes to changes on a specific key (or "*" for all changes).
        /// @param key : string
        /// @param callback : function
        /// @return integer
        methods.add_method("watch", |lua, this, (key, callback): (String, LuaFunction)| {
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
        });

        // -- unwatch ---------------------------------------------------------
        /// Removes a watcher subscription by id.
        /// @param id : integer
        methods.add_method("unwatch", |lua, this, id: u64| {
            if let Some(rk) = this.watchers.borrow_mut().remove(&id) {
                lua.remove_registry_value(rk)?;
            }
            this.watcher_keys.borrow_mut().remove(&id);
            Ok(())
        });

        // -- getRevision -----------------------------------------------------
        /// Returns the monotonic revision counter (incremented on every write).
        /// @return integer
        methods.add_method("getRevision", |_, this, ()| {
            Ok(this.board.borrow().revision)
        });

        // -- snapshot --------------------------------------------------------
        /// Returns all facts as a flat key→value table.
        /// @return table
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

        // -- clearAll --------------------------------------------------------
        /// Clears all facts from the blackboard.
        methods.add_method("clearAll", |_, this, ()| {
            this.board.borrow_mut().clear_all();
            Ok(())
        });
    }
}

// ===========================================================================
// Observer
// ===========================================================================

/// Lua wrapper for the Observer pattern.
#[derive(Clone)]
struct LuaObserver {
    observer: Rc<RefCell<crate::patterns::Observer>>,
    values: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
    callbacks: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
}

impl LunaType for LuaObserver {
    const TYPE_NAME: &'static str = "Observer";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Observer", "Object"];
}

impl LuaUserData for LuaObserver {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // -- set -------------------------------------------------------------
        /// Sets a property value and fires subscribed watchers.
        /// @param key : string
        /// @param value : any
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

        // -- get -------------------------------------------------------------
        /// Gets a property value, or nil if not set.
        /// @param key : string
        /// @return any
        methods.add_method("get", |lua, this, key: String| {
            match this.values.borrow().get(&key) {
                Some(rk) => Ok(lua.registry_value::<LuaValue>(rk)?),
                None => Ok(LuaValue::Nil),
            }
        });

        // -- subscribe -------------------------------------------------------
        /// Subscribes to changes on a property key (or "*" for all).
        /// @param key : string
        /// @param callback : function
        /// @param once : boolean?
        /// @return integer
        methods.add_method("subscribe", |lua, this, (key, callback, once): (String, LuaFunction, Option<bool>)| {
            let id = this.observer.borrow_mut().subscribe(&key, once.unwrap_or(false));
            let rk = lua.create_registry_value(callback)?;
            this.callbacks.borrow_mut().insert(id, rk);
            Ok(id)
        });

        // -- unsubscribe -----------------------------------------------------
        /// Removes a subscription by id.
        /// @param id : integer
        methods.add_method("unsubscribe", |lua, this, id: u64| {
            this.observer.borrow_mut().unsubscribe(id);
            if let Some(rk) = this.callbacks.borrow_mut().remove(&id) {
                lua.remove_registry_value(rk)?;
            }
            Ok(())
        });

        // -- getCount --------------------------------------------------------
        /// Returns the total number of active subscriptions.
        /// @return integer
        methods.add_method("getCount", |_, this, ()| {
            Ok(this.observer.borrow().subscription_count())
        });
    }
}

// ===========================================================================
// Throttle / Debounce
// ===========================================================================

/// Lua wrapper for the Throttle pattern.
#[derive(Clone)]
struct LuaThrottle {
    throttle: Rc<RefCell<crate::patterns::Throttle>>,
    callback: Rc<RefCell<Option<LuaRegistryKey>>>,
}

impl LunaType for LuaThrottle {
    const TYPE_NAME: &'static str = "Throttle";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Throttle", "Object"];
}

impl LuaUserData for LuaThrottle {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // -- onFire ----------------------------------------------------------
        /// Sets the callback invoked when the throttle fires.
        /// @param fn : function
        methods.add_method("onFire", |lua, this, f: LuaFunction| {
            let rk = lua.create_registry_value(f)?;
            if let Some(old) = this.callback.borrow_mut().replace(rk) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });

        // -- update ----------------------------------------------------------
        /// Advances the timer by dt seconds; fires the callback if the interval elapsed.
        /// @param dt : number
        /// @return boolean
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

        // -- reset -----------------------------------------------------------
        /// Resets the elapsed counter without firing.
        methods.add_method("reset", |_, this, ()| {
            this.throttle.borrow_mut().reset();
            Ok(())
        });

        // -- getProgress -----------------------------------------------------
        /// Returns the normalised progress through the current interval [0, 1].
        /// @return number
        methods.add_method("getProgress", |_, this, ()| Ok(this.throttle.borrow().progress()));

        // -- getFireCount ----------------------------------------------------
        /// Returns the total number of times this throttle has fired.
        /// @return integer
        methods.add_method("getFireCount", |_, this, ()| Ok(this.throttle.borrow().fire_count));

        // -- setEnabled ------------------------------------------------------
        /// Enables or disables the throttle.
        /// @param enabled : boolean
        methods.add_method("setEnabled", |_, this, v: bool| {
            this.throttle.borrow_mut().enabled = v;
            Ok(())
        });
    }
}

/// Lua wrapper for the Debounce pattern.
#[derive(Clone)]
struct LuaDebounce {
    debounce: Rc<RefCell<crate::patterns::Debounce>>,
    callback: Rc<RefCell<Option<LuaRegistryKey>>>,
}

impl LunaType for LuaDebounce {
    const TYPE_NAME: &'static str = "Debounce";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Debounce", "Object"];
}

impl LuaUserData for LuaDebounce {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // -- onFire ----------------------------------------------------------
        /// Sets the callback invoked when the debounce fires.
        /// @param fn : function
        methods.add_method("onFire", |lua, this, f: LuaFunction| {
            let rk = lua.create_registry_value(f)?;
            if let Some(old) = this.callback.borrow_mut().replace(rk) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });

        // -- trigger ---------------------------------------------------------
        /// Records an input event, resetting the idle timer.
        methods.add_method("trigger", |_, this, ()| {
            this.debounce.borrow_mut().trigger();
            Ok(())
        });

        // -- update ----------------------------------------------------------
        /// Advances the idle timer by dt seconds; fires the callback if idle wait expired.
        /// @param dt : number
        /// @return boolean
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

        // -- cancel ----------------------------------------------------------
        /// Cancels the pending trigger without firing.
        methods.add_method("cancel", |_, this, ()| {
            this.debounce.borrow_mut().cancel();
            Ok(())
        });

        // -- isPending -------------------------------------------------------
        /// Returns true when a trigger is pending.
        /// @return boolean
        methods.add_method("isPending", |_, this, ()| Ok(this.debounce.borrow().pending));

        // -- getFireCount ----------------------------------------------------
        /// Returns the total number of times this debounce has fired.
        /// @return integer
        methods.add_method("getFireCount", |_, this, ()| Ok(this.debounce.borrow().fire_count));
    }
}

// ===========================================================================
// PriorityQueue
// ===========================================================================

/// Lua wrapper for the PriorityQueue pattern.
#[derive(Clone)]
struct LuaPriorityQueue {
    queue: Rc<RefCell<crate::patterns::PriorityQueue>>,
    payloads: Rc<RefCell<HashMap<u64, LuaRegistryKey>>>,
}

impl LunaType for LuaPriorityQueue {
    const TYPE_NAME: &'static str = "PriorityQueue";
    const TYPE_HIERARCHY: &'static [&'static str] = &["PriorityQueue", "Object"];
}

impl LuaUserData for LuaPriorityQueue {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // -- push ------------------------------------------------------------
        /// Inserts an item with a priority. Higher priorities are dequeued first.
        /// @param priority : integer
        /// @param value : any
        /// @param label : string?
        /// @return integer
        methods.add_method("push", |lua, this, (priority, value, label): (i64, LuaValue, Option<String>)| {
            let id = this.queue.borrow_mut().push(priority, label.as_deref().unwrap_or(""));
            let rk = lua.create_registry_value(value)?;
            this.payloads.borrow_mut().insert(id, rk);
            Ok(id)
        });

        // -- pop -------------------------------------------------------------
        /// Removes and returns the highest-priority item, or nil if empty.
        /// @return any
        methods.add_method("pop", |lua, this, ()| {
            match this.queue.borrow_mut().pop() {
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
            }
        });

        // -- peek ------------------------------------------------------------
        /// Returns the highest-priority item without removing it, or nil if empty.
        /// @return any
        methods.add_method("peek", |lua, this, ()| {
            match this.queue.borrow().peek() {
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
            }
        });

        // -- len -------------------------------------------------------------
        /// Returns the number of items in the queue.
        /// @return integer
        methods.add_method("len", |_, this, ()| Ok(this.queue.borrow().len()));

        // -- isEmpty ---------------------------------------------------------
        /// Returns true when the queue has no items.
        /// @return boolean
        methods.add_method("isEmpty", |_, this, ()| Ok(this.queue.borrow().is_empty()));

        // -- clearAll --------------------------------------------------------
        /// Removes all items from the queue.
        methods.add_method("clearAll", |lua, this, ()| {
            this.queue.borrow_mut().clear();
            let drained: Vec<(u64, LuaRegistryKey)> = this.payloads.borrow_mut().drain().collect();
            for (_, rk) in drained { lua.remove_registry_value(rk)?; }
            Ok(())
        });
    }
}

// ===========================================================================
// Ring
// ===========================================================================

/// Lua wrapper for the Ring (circular buffer) pattern.
#[derive(Clone)]
struct LuaRing {
    ring: Rc<RefCell<crate::patterns::Ring>>,
}

impl LunaType for LuaRing {
    const TYPE_NAME: &'static str = "Ring";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Ring", "Object"];
}

impl LuaUserData for LuaRing {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // -- push ------------------------------------------------------------
        /// Pushes a value (number or string) with an optional tag. Overwrites oldest on overflow.
        /// @param value : any
        /// @param tag : string?
        /// @return integer
        methods.add_method("push", |_, this, (value, tag): (LuaValue, Option<String>)| {
            let tag = tag.as_deref().unwrap_or("");
            let id = match &value {
                LuaValue::Integer(n) => this.ring.borrow_mut().push_number(*n as f64, tag),
                LuaValue::Number(n) => this.ring.borrow_mut().push_number(*n, tag),
                LuaValue::String(s) => this.ring.borrow_mut().push_string(s.to_str()?.to_string(), tag),
                _ => return Err(LuaError::external("Ring only accepts number or string values")),
            };
            Ok(id)
        });

        // -- latest ----------------------------------------------------------
        /// Returns the most recently pushed entry, or nil.
        /// @return table?
        methods.add_method("latest", |lua, this, ()| {
            match this.ring.borrow().latest() {
                Some(e) => {
                    let t = lua.create_table()?;
                    t.set("id", e.id)?;
                    t.set("tag", e.tag.as_str())?;
                    if let Some(n) = e.value_f64 { t.set("value", n)?; }
                    if let Some(s) = &e.value_str { t.set("text", s.as_str())?; }
                    Ok(LuaValue::Table(t))
                }
                None => Ok(LuaValue::Nil),
            }
        });

        // -- toArray ---------------------------------------------------------
        /// Returns all entries (oldest first) as an array of {id, tag, value?, text?} tables.
        /// @return table
        methods.add_method("toArray", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, e) in this.ring.borrow().iter().enumerate() {
                let t = lua.create_table()?;
                t.set("id", e.id)?;
                t.set("tag", e.tag.as_str())?;
                if let Some(n) = e.value_f64 { t.set("value", n)?; }
                if let Some(s) = &e.value_str { t.set("text", s.as_str())?; }
                tbl.set(i + 1, t)?;
            }
            Ok(tbl)
        });

        // -- sum -------------------------------------------------------------
        /// Returns the sum of all numeric values in the ring.
        /// @return number
        methods.add_method("sum", |_, this, ()| Ok(this.ring.borrow().sum()));

        // -- average ---------------------------------------------------------
        /// Returns the average of all numeric values, or 0 if empty.
        /// @return number
        methods.add_method("average", |_, this, ()| Ok(this.ring.borrow().average()));

        // -- len -------------------------------------------------------------
        /// Returns the number of entries currently in the ring.
        /// @return integer
        methods.add_method("len", |_, this, ()| Ok(this.ring.borrow().len()));

        // -- isFull ----------------------------------------------------------
        /// Returns true when the ring is at capacity.
        /// @return boolean
        methods.add_method("isFull", |_, this, ()| Ok(this.ring.borrow().is_full()));

        // -- clear -----------------------------------------------------------
        /// Removes all entries from the ring.
        methods.add_method("clear", |_, this, ()| { this.ring.borrow_mut().clear(); Ok(()) });
    }
}

// ===========================================================================
// Funnel
// ===========================================================================

/// Lua wrapper for the Funnel (event aggregator) pattern.
#[derive(Clone)]
struct LuaFunnel {
    funnel: Rc<RefCell<crate::patterns::Funnel>>,
    on_flush: Rc<RefCell<Option<LuaRegistryKey>>>,
}

impl LunaType for LuaFunnel {
    const TYPE_NAME: &'static str = "Funnel";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Funnel", "Object"];
}

impl LuaUserData for LuaFunnel {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // -- onFlush ---------------------------------------------------------
        /// Sets a callback invoked when the funnel flushes. Receives a table of {tag, value} entries.
        /// @param fn : function
        methods.add_method("onFlush", |lua, this, f: LuaFunction| {
            let rk = lua.create_registry_value(f)?;
            if let Some(old) = this.on_flush.borrow_mut().replace(rk) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });

        // -- push ------------------------------------------------------------
        /// Adds an event to the funnel. Immediately flushes if max_entries reached or window is 0.
        /// @param tag : string
        /// @param value : number?
        methods.add_method("push", |lua, this, (tag, value): (String, Option<f64>)| {
            let (_, should_flush) = this.funnel.borrow_mut().push(&tag, value.unwrap_or(0.0));
            if should_flush {
                Self::do_flush(lua, this)?;
            }
            Ok(())
        });

        // -- update ----------------------------------------------------------
        /// Advances the window timer by dt seconds; flushes when window expires.
        /// @param dt : number
        /// @return boolean
        methods.add_method("update", |lua, this, dt: f64| {
            let should_flush = this.funnel.borrow_mut().update(dt);
            if should_flush {
                Self::do_flush(lua, this)?;
                return Ok(true);
            }
            Ok(false)
        });

        // -- flush -----------------------------------------------------------
        /// Manually flushes all pending entries, invoking the onFlush callback.
        methods.add_method("flush", |lua, this, ()| {
            Self::do_flush(lua, this)
        });

        // -- discard ---------------------------------------------------------
        /// Discards all buffered entries without flushing.
        methods.add_method("discard", |_, this, ()| {
            this.funnel.borrow_mut().discard();
            Ok(())
        });

        // -- pendingCount ----------------------------------------------------
        /// Returns the number of buffered entries not yet flushed.
        /// @return integer
        methods.add_method("pendingCount", |_, this, ()| Ok(this.funnel.borrow().pending_count()));

        // -- getFlushCount ---------------------------------------------------
        /// Returns the total number of flushes performed.
        /// @return integer
        methods.add_method("getFlushCount", |_, this, ()| Ok(this.funnel.borrow().flush_count));
    }
}

impl LuaFunnel {
    fn do_flush(lua: &Lua, this: &LuaFunnel) -> LuaResult<()> {
        let entries = this.funnel.borrow_mut().flush();
        if entries.is_empty() { return Ok(()); }
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

// ===========================================================================
// Registration
// ===========================================================================

/// Registers the `lurek.patterns.*` Lua API namespace.
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param _state : Rc<RefCell<SharedState>>
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let patterns = lua.create_table()?;

    // lurek.patterns.newEventBus(name?) -> EventBus
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

    // lurek.patterns.newObjectPool() -> ObjectPool
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

    // lurek.patterns.newCommandStack(maxSize?) -> CommandStack
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

    // lurek.patterns.newServiceLocator() -> ServiceLocator
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

    // lurek.patterns.newFactory() -> Factory
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

    // lurek.patterns.newSimpleState() -> SimpleState
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

    // lurek.patterns.newBlackboard(name?) -> Blackboard
    /// Creates a new Blackboard shared key-value store.
    /// @param name : string?
    /// @return any
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

    // lurek.patterns.newObserver(name?) -> Observer
    /// Creates a new reactive property Observer.
    /// @param name : string?
    /// @return any
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

    // lurek.patterns.newThrottle(interval) -> Throttle
    /// Creates a leading-edge rate limiter that fires at most once per interval seconds.
    /// @param interval : number
    /// @return any
    patterns.set(
        "newThrottle",
        lua.create_function(|_lua, interval: f64| {
            Ok(LuaThrottle {
                throttle: Rc::new(RefCell::new(crate::patterns::Throttle::new(interval))),
                callback: Rc::new(RefCell::new(None)),
            })
        })?,
    )?;

    // lurek.patterns.newDebounce(wait) -> Debounce
    /// Creates a trailing-edge debounce that fires after the input stream is idle for wait seconds.
    /// @param wait : number
    /// @return any
    patterns.set(
        "newDebounce",
        lua.create_function(|_lua, wait: f64| {
            Ok(LuaDebounce {
                debounce: Rc::new(RefCell::new(crate::patterns::Debounce::new(wait))),
                callback: Rc::new(RefCell::new(None)),
            })
        })?,
    )?;

    // lurek.patterns.newPriorityQueue(name?) -> PriorityQueue
    /// Creates a stable priority-ordered task queue.
    /// @param name : string?
    /// @return any
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

    // lurek.patterns.newRing(capacity, name?) -> Ring
    /// Creates a fixed-capacity circular history buffer.
    /// @param capacity : integer
    /// @param name : string?
    /// @return any
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

    // lurek.patterns.newFunnel(window, maxEntries?, name?) -> Funnel
    /// Creates a time-windowed event aggregator. window=0 means flush on every push.
    /// @param window : number
    /// @param max_entries : integer?
    /// @param name : string?
    /// @return any
    patterns.set(
        "newFunnel",
        lua.create_function(|_lua, (window, max_entries, name): (f64, Option<usize>, Option<String>)| {
            Ok(LuaFunnel {
                funnel: Rc::new(RefCell::new(crate::patterns::Funnel::new(
                    name.as_deref().unwrap_or(""),
                    window,
                    max_entries.unwrap_or(0),
                ))),
                on_flush: Rc::new(RefCell::new(None)),
            })
        })?,
    )?;

    // -- patterns namespace --
    luna.set("patterns", patterns)?;
    Ok(())
}
