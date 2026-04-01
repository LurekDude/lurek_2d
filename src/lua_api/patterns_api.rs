//! Registers the `luna.patterns.*` software design patterns API.
//!
//! Provides factory functions and UserData wrappers for reusable patterns:
//! EventBus (prioritized pub-sub), ObjectPool (object reuse), CommandStack
//! (undo/redo), ServiceLocator (DI container), Factory (named constructors),
//! and SimpleState (finite state machine).

use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use mlua::prelude::*;

use crate::lua_api::lua_types::{add_type_methods, LunaType};

// ===========================================================================
// EventBus
// ===========================================================================

/// Internal subscription record for EventBus.
struct Subscription {
    id: u64,
    priority: i64,
    key: LuaRegistryKey,
}

/// Prioritized pub-sub event dispatcher.
struct EventBusInner {
    next_id: u64,
    listeners: HashMap<String, Vec<Subscription>>,
}

impl EventBusInner {
    fn new() -> Self {
        Self {
            next_id: 1,
            listeners: HashMap::new(),
        }
    }
}

/// Lua wrapper for the EventBus pattern.
#[derive(Clone)]
struct LuaEventBus {
    inner: Rc<RefCell<EventBusInner>>,
}

impl LunaType for LuaEventBus {
    const TYPE_NAME: &'static str = "EventBus";
    const TYPE_HIERARCHY: &'static [&'static str] = &["EventBus", "Object"];
}

impl LuaUserData for LuaEventBus {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // on(event, callback, priority?) -> subscriptionId
        /// Registers an event listener callback.
        ///
        /// # Parameters
        /// - `event` — `string`.
        /// - `callback` — `function`.
        /// - `priority` — `integer` optional.
        methods.add_method("on", |lua, this, (event, callback, priority): (String, LuaFunction, Option<i64>)| {
            let priority = priority.unwrap_or(0);
            let key = lua.create_registry_value(callback)?;
            let mut inner = this.inner.borrow_mut();
            let id = inner.next_id;
            inner.next_id += 1;
            let subs = inner.listeners.entry(event).or_default();
            subs.push(Subscription { id, priority, key });
            subs.sort_by_key(|s| s.priority);
            Ok(id)
        });

        // off(subscriptionId)
        /// Removes a previously registered event listener.
        ///
        /// # Parameters
        /// - `id` — `integer`.
        methods.add_method("off", |lua, this, id: u64| {
            let mut inner = this.inner.borrow_mut();
            for subs in inner.listeners.values_mut() {
                if let Some(pos) = subs.iter().position(|s| s.id == id) {
                    let removed = subs.remove(pos);
                    lua.remove_registry_value(removed.key)?;
                    return Ok(());
                }
            }
            Ok(())
        });

        // emit(event, ...)
        /// Emits an event.
        ///
        /// # Parameters
        /// - `args` — `LuaMultiValue`.
        methods.add_method("emit", |lua, this, args: LuaMultiValue| {
            let mut args_iter = args.into_iter();
            let event: String = match args_iter.next() {
                Some(v) => lua.unpack(v)?,
                None => return Err(LuaError::external("emit requires an event name")),
            };
            let extra: Vec<LuaValue> = args_iter.collect();

            let inner = this.inner.borrow();
            let ids_and_keys: Vec<u64> = inner
                .listeners
                .get(&event)
                .map(|subs| subs.iter().map(|s| s.id).collect())
                .unwrap_or_default();
            drop(inner);

            for id in ids_and_keys {
                let inner = this.inner.borrow();
                let func_key = inner.listeners.get(&event).and_then(|subs| {
                    subs.iter().find(|s| s.id == id).map(|s| &s.key)
                });
                if let Some(key) = func_key {
                    let func: LuaFunction = lua.registry_value(key)?;
                    drop(inner);
                    let call_args = LuaMultiValue::from_iter(extra.clone());
                    func.call::<_, ()>(call_args)?;
                } else {
                    drop(inner);
                }
            }
            Ok(())
        });

        // clear(event)
        /// Removes all entries.
        ///
        /// # Parameters
        /// - `event` — `string`.
        methods.add_method("clear", |lua, this, event: String| {
            let mut inner = this.inner.borrow_mut();
            if let Some(subs) = inner.listeners.remove(&event) {
                for sub in subs {
                    lua.remove_registry_value(sub.key)?;
                }
            }
            Ok(())
        });

        // clearAll()
        /// Clear all on this EventBus.
        ///
        /// # Returns
        /// The result.
        methods.add_method("clearAll", |lua, this, ()| {
            let mut inner = this.inner.borrow_mut();
            let all: Vec<(String, Vec<Subscription>)> = inner.listeners.drain().collect();
            for (_name, subs) in all {
                for sub in subs {
                    lua.remove_registry_value(sub.key)?;
                }
            }
            Ok(())
        });

        // getListenerCount(event) -> int
        /// Returns the listener count.
        ///
        /// # Parameters
        /// - `event` — `string`.
        ///
        /// # Returns
        /// The current listener count.
        methods.add_method("getListenerCount", |_lua, this, event: String| {
            let inner = this.inner.borrow();
            let count = inner
                .listeners
                .get(&event)
                .map(|s| s.len())
                .unwrap_or(0);
            Ok(count)
        });

        // getEvents() -> table<string>
        /// Returns the events.
        ///
        /// # Returns
        /// The current events.
        methods.add_method("getEvents", |lua, this, ()| {
            let inner = this.inner.borrow();
            let names: Vec<String> = inner
                .listeners
                .iter()
                .filter(|(_, subs)| !subs.is_empty())
                .map(|(name, _)| name.clone())
                .collect();
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

/// Object reuse pool that stores Lua values via registry keys.
struct ObjectPoolInner {
    available: Vec<LuaRegistryKey>,
    active_count: usize,
}

impl ObjectPoolInner {
    fn new() -> Self {
        Self {
            available: Vec::new(),
            active_count: 0,
        }
    }
}

/// Lua wrapper for the ObjectPool pattern.
#[derive(Clone)]
struct LuaObjectPool {
    inner: Rc<RefCell<ObjectPoolInner>>,
}

impl LunaType for LuaObjectPool {
    const TYPE_NAME: &'static str = "ObjectPool";
    const TYPE_HIERARCHY: &'static [&'static str] = &["ObjectPool", "Object"];
}

impl LuaUserData for LuaObjectPool {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // add(object)
        /// Adds an entry to the collection.
        ///
        /// # Parameters
        /// - `value` — `any`.
        methods.add_method("add", |lua, this, value: LuaValue| {
            let key = lua.create_registry_value(value)?;
            this.inner.borrow_mut().available.push(key);
            Ok(())
        });

        // acquire() -> any | nil
        /// Acquire on this ObjectPool.
        ///
        /// # Returns
        /// The result.
        methods.add_method("acquire", |lua, this, ()| {
            let mut inner = this.inner.borrow_mut();
            if let Some(key) = inner.available.pop() {
                inner.active_count += 1;
                let val: LuaValue = lua.registry_value(&key)?;
                lua.remove_registry_value(key)?;
                Ok(val)
            } else {
                Ok(LuaValue::Nil)
            }
        });

        // release(object)
        /// Releases the underlying resource handle.
        ///
        /// # Parameters
        /// - `value` — `any`.
        methods.add_method("release", |lua, this, value: LuaValue| {
            let key = lua.create_registry_value(value)?;
            let mut inner = this.inner.borrow_mut();
            if inner.active_count > 0 {
                inner.active_count -= 1;
            }
            inner.available.push(key);
            Ok(())
        });

        // getActiveCount() -> int
        /// Returns the active count.
        ///
        /// # Returns
        /// The current active count.
        methods.add_method("getActiveCount", |_lua, this, ()| {
            Ok(this.inner.borrow().active_count)
        });

        // getAvailableCount() -> int
        /// Returns the available count.
        ///
        /// # Returns
        /// The current available count.
        methods.add_method("getAvailableCount", |_lua, this, ()| {
            Ok(this.inner.borrow().available.len())
        });

        // getTotalCount() -> int
        /// Returns the total count.
        ///
        /// # Returns
        /// The current total count.
        methods.add_method("getTotalCount", |_lua, this, ()| {
            let inner = this.inner.borrow();
            Ok(inner.active_count + inner.available.len())
        });

        // clearAll()
        /// Clear all on this ObjectPool.
        ///
        /// # Returns
        /// The result.
        methods.add_method("clearAll", |lua, this, ()| {
            let mut inner = this.inner.borrow_mut();
            for key in inner.available.drain(..) {
                lua.remove_registry_value(key)?;
            }
            inner.active_count = 0;
            Ok(())
        });
    }
}

// ===========================================================================
// CommandStack
// ===========================================================================

/// A single command entry in the undo/redo stack.
struct CommandEntry {
    name: String,
    execute_key: LuaRegistryKey,
    undo_key: Option<LuaRegistryKey>,
}

/// Undo/redo command stack.
struct CommandStackInner {
    history: Vec<CommandEntry>,
    cursor: usize, // points past the last executed command
}

impl CommandStackInner {
    fn new() -> Self {
        Self {
            history: Vec::new(),
            cursor: 0,
        }
    }
}

/// Lua wrapper for the CommandStack pattern.
#[derive(Clone)]
struct LuaCommandStack {
    inner: Rc<RefCell<CommandStackInner>>,
}

impl LunaType for LuaCommandStack {
    const TYPE_NAME: &'static str = "CommandStack";
    const TYPE_HIERARCHY: &'static [&'static str] = &["CommandStack", "Object"];
}

impl LuaUserData for LuaCommandStack {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // execute(name, execFn, undoFn?)
        /// Execute on this CommandStack.
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `exec_fn` — `function`.
        /// - `undo_fn` — `function` optional.
        methods.add_method("execute", |lua, this, (name, exec_fn, undo_fn): (String, LuaFunction, Option<LuaFunction>)| {
            // Truncate any redo history
            let mut inner = this.inner.borrow_mut();
            while inner.history.len() > inner.cursor {
                let entry = inner.history.pop().unwrap();
                lua.remove_registry_value(entry.execute_key)?;
                if let Some(k) = entry.undo_key {
                    lua.remove_registry_value(k)?;
                }
            }
            drop(inner);

            // Execute the command
            exec_fn.call::<_, ()>(())?;

            let exec_key = lua.create_registry_value(exec_fn)?;
            let undo_key = match undo_fn {
                Some(f) => Some(lua.create_registry_value(f)?),
                None => None,
            };

            let mut inner = this.inner.borrow_mut();
            inner.history.push(CommandEntry {
                name,
                execute_key: exec_key,
                undo_key,
            });
            inner.cursor += 1;
            Ok(())
        });

        // undo() -> boolean
        /// Undo on this CommandStack.
        ///
        /// # Returns
        /// The result.
        methods.add_method("undo", |lua, this, ()| {
            let inner = this.inner.borrow();
            if inner.cursor == 0 {
                return Ok(false);
            }
            let idx = inner.cursor - 1;
            let has_undo = inner.history[idx].undo_key.is_some();
            if !has_undo {
                return Ok(false);
            }
            let undo_key = inner.history[idx].undo_key.as_ref().unwrap();
            let func: LuaFunction = lua.registry_value(undo_key)?;
            drop(inner);

            func.call::<_, ()>(())?;

            this.inner.borrow_mut().cursor -= 1;
            Ok(true)
        });

        // redo() -> boolean
        /// Redo on this CommandStack.
        ///
        /// # Returns
        /// The result.
        methods.add_method("redo", |lua, this, ()| {
            let inner = this.inner.borrow();
            if inner.cursor >= inner.history.len() {
                return Ok(false);
            }
            let exec_key = &inner.history[inner.cursor].execute_key;
            let func: LuaFunction = lua.registry_value(exec_key)?;
            drop(inner);

            func.call::<_, ()>(())?;

            this.inner.borrow_mut().cursor += 1;
            Ok(true)
        });

        // canUndo() -> boolean
        /// Returns `true` if undo.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("canUndo", |_lua, this, ()| {
            let inner = this.inner.borrow();
            if inner.cursor == 0 {
                return Ok(false);
            }
            Ok(inner.history[inner.cursor - 1].undo_key.is_some())
        });

        // canRedo() -> boolean
        /// Returns `true` if redo.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("canRedo", |_lua, this, ()| {
            let inner = this.inner.borrow();
            Ok(inner.cursor < inner.history.len())
        });

        // getHistorySize() -> int
        /// Returns the history size.
        ///
        /// # Returns
        /// The current history size.
        methods.add_method("getHistorySize", |_lua, this, ()| {
            Ok(this.inner.borrow().history.len())
        });

        // getCurrentName() -> string | nil
        /// Returns the current name.
        ///
        /// # Returns
        /// The current current name.
        methods.add_method("getCurrentName", |_lua, this, ()| {
            let inner = this.inner.borrow();
            if inner.cursor == 0 {
                Ok(None)
            } else {
                Ok(Some(inner.history[inner.cursor - 1].name.clone()))
            }
        });

        // clearAll()
        /// Clear all on this CommandStack.
        ///
        /// # Returns
        /// The result.
        methods.add_method("clearAll", |lua, this, ()| {
            let mut inner = this.inner.borrow_mut();
            for entry in inner.history.drain(..) {
                lua.remove_registry_value(entry.execute_key)?;
                if let Some(k) = entry.undo_key {
                    lua.remove_registry_value(k)?;
                }
            }
            inner.cursor = 0;
            Ok(())
        });
    }
}

// ===========================================================================
// ServiceLocator
// ===========================================================================

/// Dependency injection container mapping names to Lua values.
struct ServiceLocatorInner {
    services: HashMap<String, LuaRegistryKey>,
}

impl ServiceLocatorInner {
    fn new() -> Self {
        Self {
            services: HashMap::new(),
        }
    }
}

/// Lua wrapper for the ServiceLocator pattern.
#[derive(Clone)]
struct LuaServiceLocator {
    inner: Rc<RefCell<ServiceLocatorInner>>,
}

impl LunaType for LuaServiceLocator {
    const TYPE_NAME: &'static str = "ServiceLocator";
    const TYPE_HIERARCHY: &'static [&'static str] = &["ServiceLocator", "Object"];
}

impl LuaUserData for LuaServiceLocator {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // provide(name, value)
        /// Provide on this ServiceLocator.
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `value` — `any`.
        methods.add_method("provide", |lua, this, (name, value): (String, LuaValue)| {
            let key = lua.create_registry_value(value)?;
            let mut inner = this.inner.borrow_mut();
            if let Some(old) = inner.services.insert(name, key) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });

        // locate(name) -> any | nil
        /// Locate on this ServiceLocator.
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("locate", |lua, this, name: String| {
            let inner = this.inner.borrow();
            match inner.services.get(&name) {
                Some(key) => {
                    let val: LuaValue = lua.registry_value(key)?;
                    Ok(val)
                }
                None => Ok(LuaValue::Nil),
            }
        });

        // has(name) -> boolean
        /// Returns `true` if the condition is met.
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("has", |_lua, this, name: String| {
            Ok(this.inner.borrow().services.contains_key(&name))
        });

        // remove(name)
        /// Removes the entry from the collection.
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("remove", |lua, this, name: String| {
            let mut inner = this.inner.borrow_mut();
            if let Some(key) = inner.services.remove(&name) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });

        // getServices() -> table<string>
        /// Returns the services.
        ///
        /// # Returns
        /// The current services.
        methods.add_method("getServices", |lua, this, ()| {
            let inner = this.inner.borrow();
            let table = lua.create_table()?;
            for (i, name) in inner.services.keys().enumerate() {
                table.set(i + 1, name.as_str())?;
            }
            Ok(table)
        });

        // clearAll()
        /// Clear all on this ServiceLocator.
        ///
        /// # Returns
        /// The result.
        methods.add_method("clearAll", |lua, this, ()| {
            let mut inner = this.inner.borrow_mut();
            let entries: Vec<(String, LuaRegistryKey)> = inner.services.drain().collect();
            for (_name, key) in entries {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
    }
}

// ===========================================================================
// Factory
// ===========================================================================

/// Named-type constructor registry.
struct FactoryInner {
    constructors: HashMap<String, LuaRegistryKey>,
}

impl FactoryInner {
    fn new() -> Self {
        Self {
            constructors: HashMap::new(),
        }
    }
}

/// Lua wrapper for the Factory pattern.
#[derive(Clone)]
struct LuaFactory {
    inner: Rc<RefCell<FactoryInner>>,
}

impl LunaType for LuaFactory {
    const TYPE_NAME: &'static str = "Factory";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Factory", "Object"];
}

impl LuaUserData for LuaFactory {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // register(typeName, constructor)
        /// Adds an entry to the collection.
        ///
        /// # Parameters
        /// - `type_name` — `string`.
        /// - `ctor` — `function`.
        methods.add_method("register", |lua, this, (type_name, ctor): (String, LuaFunction)| {
            let key = lua.create_registry_value(ctor)?;
            let mut inner = this.inner.borrow_mut();
            if let Some(old) = inner.constructors.insert(type_name, key) {
                lua.remove_registry_value(old)?;
            }
            Ok(())
        });

        // create(typeName, ...) -> any
        /// Creates a new Factory instance.
        ///
        /// # Parameters
        /// - `args` — `LuaMultiValue`.
        methods.add_method("create", |lua, this, args: LuaMultiValue| {
            let mut args_iter = args.into_iter();
            let type_name: String = match args_iter.next() {
                Some(v) => lua.unpack(v)?,
                None => return Err(LuaError::external("create requires a type name")),
            };
            let extra: Vec<LuaValue> = args_iter.collect();

            let inner = this.inner.borrow();
            let key = inner.constructors.get(&type_name).ok_or_else(|| {
                LuaError::external(format!("no constructor registered for type '{type_name}'"))
            })?;
            let func: LuaFunction = lua.registry_value(key)?;
            drop(inner);

            let call_args = LuaMultiValue::from_iter(extra);
            func.call::<_, LuaValue>(call_args)
        });

        // has(typeName) -> boolean
        /// Returns `true` if the condition is met.
        ///
        /// # Parameters
        /// - `type_name` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("has", |_lua, this, type_name: String| {
            Ok(this.inner.borrow().constructors.contains_key(&type_name))
        });

        // getTypes() -> table<string>
        /// Returns the types.
        ///
        /// # Returns
        /// The current types.
        methods.add_method("getTypes", |lua, this, ()| {
            let inner = this.inner.borrow();
            let table = lua.create_table()?;
            for (i, name) in inner.constructors.keys().enumerate() {
                table.set(i + 1, name.as_str())?;
            }
            Ok(table)
        });

        // remove(typeName)
        /// Removes the entry from the collection.
        ///
        /// # Parameters
        /// - `type_name` — `string`.
        methods.add_method("remove", |lua, this, type_name: String| {
            let mut inner = this.inner.borrow_mut();
            if let Some(key) = inner.constructors.remove(&type_name) {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });

        // clearAll()
        /// Clear all on this Factory.
        ///
        /// # Returns
        /// The result.
        methods.add_method("clearAll", |lua, this, ()| {
            let mut inner = this.inner.borrow_mut();
            let entries: Vec<(String, LuaRegistryKey)> = inner.constructors.drain().collect();
            for (_name, key) in entries {
                lua.remove_registry_value(key)?;
            }
            Ok(())
        });
    }
}

// ===========================================================================
// SimpleState
// ===========================================================================

/// Stores callbacks for a single state.
struct StateCallbacks {
    enter_key: Option<LuaRegistryKey>,
    exit_key: Option<LuaRegistryKey>,
    update_key: Option<LuaRegistryKey>,
}

/// Finite state machine with named states and enter/exit/update callbacks.
struct SimpleStateInner {
    states: HashMap<String, StateCallbacks>,
    current: Option<String>,
}

impl SimpleStateInner {
    fn new() -> Self {
        Self {
            states: HashMap::new(),
            current: None,
        }
    }
}

/// Lua wrapper for the SimpleState pattern.
#[derive(Clone)]
struct LuaSimpleState {
    inner: Rc<RefCell<SimpleStateInner>>,
}

impl LunaType for LuaSimpleState {
    const TYPE_NAME: &'static str = "SimpleState";
    const TYPE_HIERARCHY: &'static [&'static str] = &["SimpleState", "Object"];
}

impl LuaUserData for LuaSimpleState {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // addState(name, callbacks?)
        /// Adds state to the collection.
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `callbacks` — `table` optional.
        methods.add_method("addState", |lua, this, (name, callbacks): (String, Option<LuaTable>)| {
            let mut enter_key = None;
            let mut exit_key = None;
            let mut update_key = None;

            if let Some(tbl) = callbacks {
                if let Ok(f) = tbl.get::<_, LuaFunction>("enter") {
                    enter_key = Some(lua.create_registry_value(f)?);
                }
                if let Ok(f) = tbl.get::<_, LuaFunction>("exit") {
                    exit_key = Some(lua.create_registry_value(f)?);
                }
                if let Ok(f) = tbl.get::<_, LuaFunction>("update") {
                    update_key = Some(lua.create_registry_value(f)?);
                }
            }

            let mut inner = this.inner.borrow_mut();
            // Remove old state if it exists
            if let Some(old) = inner.states.remove(&name) {
                if let Some(k) = old.enter_key { lua.remove_registry_value(k)?; }
                if let Some(k) = old.exit_key { lua.remove_registry_value(k)?; }
                if let Some(k) = old.update_key { lua.remove_registry_value(k)?; }
            }

            inner.states.insert(name, StateCallbacks {
                enter_key,
                exit_key,
                update_key,
            });
            Ok(())
        });

        // transitionTo(name) -> boolean
        /// Transition to on this SimpleState.
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("transitionTo", |lua, this, name: String| {
            let inner = this.inner.borrow();
            if !inner.states.contains_key(&name) {
                return Ok(false);
            }

            // Call exit on current state
            if let Some(ref current) = inner.current {
                if let Some(state) = inner.states.get(current) {
                    if let Some(ref key) = state.exit_key {
                        let func: LuaFunction = lua.registry_value(key)?;
                        drop(inner);
                        func.call::<_, ()>(())?;
                    } else {
                        drop(inner);
                    }
                } else {
                    drop(inner);
                }
            } else {
                drop(inner);
            }

            // Set new state
            this.inner.borrow_mut().current = Some(name.clone());

            // Call enter on new state
            let inner = this.inner.borrow();
            if let Some(state) = inner.states.get(&name) {
                if let Some(ref key) = state.enter_key {
                    let func: LuaFunction = lua.registry_value(key)?;
                    drop(inner);
                    func.call::<_, ()>(())?;
                }
            }
            Ok(true)
        });

        // update(dt)
        /// Advances the simulation by `dt` seconds.
        ///
        /// # Parameters
        /// - `dt` — `number`.
        methods.add_method("update", |lua, this, dt: f64| {
            let inner = this.inner.borrow();
            if let Some(ref current) = inner.current {
                if let Some(state) = inner.states.get(current) {
                    if let Some(ref key) = state.update_key {
                        let func: LuaFunction = lua.registry_value(key)?;
                        drop(inner);
                        func.call::<_, ()>(dt)?;
                        return Ok(());
                    }
                }
            }
            Ok(())
        });

        // getCurrent() -> string | nil
        /// Returns the current.
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current current.
        methods.add_method("getCurrent", |_lua, this, ()| {
            Ok(this.inner.borrow().current.clone())
        });

        // hasState(name) -> boolean
        /// Returns `true` if state.
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasState", |_lua, this, name: String| {
            Ok(this.inner.borrow().states.contains_key(&name))
        });

        // getStates() -> table<string>
        /// Returns the states.
        ///
        /// # Returns
        /// The current states.
        methods.add_method("getStates", |lua, this, ()| {
            let inner = this.inner.borrow();
            let table = lua.create_table()?;
            for (i, name) in inner.states.keys().enumerate() {
                table.set(i + 1, name.as_str())?;
            }
            Ok(table)
        });

        // clearAll()
        /// Clear all on this SimpleState.
        ///
        /// # Returns
        /// The result.
        methods.add_method("clearAll", |lua, this, ()| {
            let mut inner = this.inner.borrow_mut();
            for (_name, cbs) in inner.states.drain() {
                if let Some(k) = cbs.enter_key { lua.remove_registry_value(k)?; }
                if let Some(k) = cbs.exit_key { lua.remove_registry_value(k)?; }
                if let Some(k) = cbs.update_key { lua.remove_registry_value(k)?; }
            }
            inner.current = None;
            Ok(())
        });
    }
}

// ===========================================================================
// Registration
// ===========================================================================

/// Registers `luna.patterns.*` factory functions.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let patterns = lua.create_table()?;

    // luna.patterns.newEventBus() -> EventBus
    patterns.set(
        "newEventBus",
        lua.create_function(|_lua, ()| {
            Ok(LuaEventBus {
                inner: Rc::new(RefCell::new(EventBusInner::new())),
            })
        })?,
    )?;

    // luna.patterns.newObjectPool() -> ObjectPool
    patterns.set(
        "newObjectPool",
        lua.create_function(|_lua, ()| {
            Ok(LuaObjectPool {
                inner: Rc::new(RefCell::new(ObjectPoolInner::new())),
            })
        })?,
    )?;

    // luna.patterns.newCommandStack() -> CommandStack
    patterns.set(
        "newCommandStack",
        lua.create_function(|_lua, ()| {
            Ok(LuaCommandStack {
                inner: Rc::new(RefCell::new(CommandStackInner::new())),
            })
        })?,
    )?;

    // luna.patterns.newServiceLocator() -> ServiceLocator
    patterns.set(
        "newServiceLocator",
        lua.create_function(|_lua, ()| {
            Ok(LuaServiceLocator {
                inner: Rc::new(RefCell::new(ServiceLocatorInner::new())),
            })
        })?,
    )?;

    // luna.patterns.newFactory() -> Factory
    patterns.set(
        "newFactory",
        lua.create_function(|_lua, ()| {
            Ok(LuaFactory {
                inner: Rc::new(RefCell::new(FactoryInner::new())),
            })
        })?,
    )?;

    // luna.patterns.newSimpleState() -> SimpleState
    patterns.set(
        "newSimpleState",
        lua.create_function(|_lua, ()| {
            Ok(LuaSimpleState {
                inner: Rc::new(RefCell::new(SimpleStateInner::new())),
            })
        })?,
    )?;

    /// Patterns on this SimpleState.
    ///
    /// # Returns
    /// The result.
    luna.set("patterns", patterns)?;
    Ok(())
}
