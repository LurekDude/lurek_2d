//! Lua API bindings for the `luna.dialog.*` dialog sequencer module.
//!
//! Provides a `Sequencer` UserData type for visual novel-style text
//! presentation with typewriter effect, branching choices, timed pauses,
//! and inline callbacks.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::dialog::{ChoiceOption, DialogNode, Sequencer};
use crate::lua_api::lua_types::{add_type_methods, LunaType};

// ---------------------------------------------------------------------------
// Callback storage
// ---------------------------------------------------------------------------

/// Stores Lua callbacks for dialog events and inline call nodes.
struct SequencerCallbacks {
    on_line: Option<LuaRegistryKey>,
    on_choice: Option<LuaRegistryKey>,
    on_finished: Option<LuaRegistryKey>,
    /// Call-node callbacks indexed by `callback_index`.
    call_fns: Vec<LuaRegistryKey>,
}

impl SequencerCallbacks {
    fn new() -> Self {
        Self {
            on_line: None,
            on_choice: None,
            on_finished: None,
            call_fns: Vec::new(),
        }
    }
}

// ---------------------------------------------------------------------------
// LuaSequencer
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for a dialog sequencer.
///
/// # Fields
/// - `inner` — `Rc<RefCell<Sequencer>>`.
/// - `callbacks` — `Rc<RefCell<SequencerCallbacks>>`.
#[derive(Clone)]
pub(crate) struct LuaSequencer {
    inner: Rc<RefCell<Sequencer>>,
    callbacks: Rc<RefCell<SequencerCallbacks>>,
}

impl LunaType for LuaSequencer {
    const TYPE_NAME: &'static str = "Sequencer";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

// ---------------------------------------------------------------------------
// Node parsing
// ---------------------------------------------------------------------------

/// Parse a Lua table array of node tables into `Vec<DialogNode>`.
fn parse_nodes(lua: &Lua, table: &LuaTable, callbacks: &Rc<RefCell<SequencerCallbacks>>) -> LuaResult<Vec<DialogNode>> {
    let mut nodes = Vec::new();
    for pair in table.clone().sequence_values::<LuaTable>() {
        let t = pair?;
        let node_type: String = t.get("type")?;
        let node = match node_type.as_str() {
            "say" => {
                let speaker: String = t.get::<_, String>("speaker").unwrap_or_default();
                let text: String = t.get("text")?;
                DialogNode::Say { speaker, text }
            }
            "choice" => {
                let text: String = t.get::<_, String>("text").unwrap_or_default();
                let opts_table: LuaTable = t.get("options")?;
                let mut options = Vec::new();
                for opt_pair in opts_table.sequence_values::<LuaTable>() {
                    let opt = opt_pair?;
                    let label: String = opt.get("label")?;
                    let branch = if let Ok(branch_tbl) = opt.get::<_, LuaTable>("branch") {
                        parse_nodes(lua, &branch_tbl, callbacks)?
                    } else {
                        Vec::new()
                    };
                    options.push(ChoiceOption { label, branch });
                }
                DialogNode::Choice { text, options }
            }
            "wait" => {
                let time: f32 = t.get("time")?;
                DialogNode::Wait { time }
            }
            "call" => {
                let func: LuaFunction = t.get("fn")?;
                let key = lua.create_registry_value(func)?;
                let mut cbs = callbacks.borrow_mut();
                let idx = cbs.call_fns.len();
                cbs.call_fns.push(key);
                DialogNode::Call { callback_index: idx }
            }
            other => {
                return Err(LuaError::RuntimeError(format!(
                    "luna.dialog: unknown node type '{other}'"
                )));
            }
        };
        nodes.push(node);
    }
    Ok(nodes)
}

/// Fire a callback if the sequencer entered a Call node.
fn fire_call_callback(lua: &Lua, callbacks: &Rc<RefCell<SequencerCallbacks>>, idx: Option<usize>) -> LuaResult<()> {
    if let Some(i) = idx {
        let cbs = callbacks.borrow();
        if let Some(key) = cbs.call_fns.get(i) {
            let func: LuaFunction = lua.registry_value(key)?;
            func.call::<_, ()>(())?
        }
    }
    Ok(())
}

/// Fire event callbacks ("line", "choice", "finished") based on current state.
fn fire_event_callbacks(
    lua: &Lua,
    seq: &Sequencer,
    callbacks: &Rc<RefCell<SequencerCallbacks>>,
    prev_state: crate::dialog::SequencerState,
) -> LuaResult<()> {
    let cur = seq.state();
    if cur == prev_state {
        return Ok(());
    }
    let cbs = callbacks.borrow();
    match cur {
        crate::dialog::SequencerState::Typing | crate::dialog::SequencerState::Waiting => {
            if let Some(key) = &cbs.on_line {
                let func: LuaFunction = lua.registry_value(key)?;
                func.call::<_, ()>((seq.current_speaker().to_string(), seq.current_text().to_string()))?;
            }
        }
        crate::dialog::SequencerState::Choice => {
            if let Some(key) = &cbs.on_choice {
                let func: LuaFunction = lua.registry_value(key)?;
                func.call::<_, ()>(())?
            }
        }
        crate::dialog::SequencerState::Done => {
            if let Some(key) = &cbs.on_finished {
                let func: LuaFunction = lua.registry_value(key)?;
                func.call::<_, ()>(())?
            }
        }
        _ => {}
    }
    Ok(())
}

impl LuaUserData for LuaSequencer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        // ── Script loading ──

        /// Loads state from persistent storage.
        /// @param script : table
        ///
        /// # Parameters
        /// - `script` — `table`.
        methods.add_method("load", |lua, this, script: LuaTable| {
            // Clear old call-fn registry keys
            {
                let mut cbs = this.callbacks.borrow_mut();
                cbs.call_fns.clear();
            }
            let nodes = parse_nodes(lua, &script, &this.callbacks)?;
            this.inner.borrow_mut().load(nodes);
            Ok(())
        });

        // ── Playback control ──

        /// Begins execution.
        ///
        /// # Returns
        /// The result.
        methods.add_method("start", |lua, this, ()| {
            let prev = this.inner.borrow().state();
            let call_idx = this.inner.borrow_mut().start();
            fire_call_callback(lua, &this.callbacks, call_idx)?;
            fire_event_callbacks(lua, &this.inner.borrow(), &this.callbacks, prev)?;
            Ok(())
        });

        /// Advances the simulation by `dt` seconds.
        /// @param dt : number
        ///
        /// # Parameters
        /// - `dt` — `number`.
        methods.add_method("update", |lua, this, dt: f32| {
            let prev = this.inner.borrow().state();
            let call_idx = this.inner.borrow_mut().update(dt);
            fire_call_callback(lua, &this.callbacks, call_idx)?;
            fire_event_callbacks(lua, &this.inner.borrow(), &this.callbacks, prev)?;
            Ok(())
        });

        /// Advances to the next item.
        ///
        /// # Returns
        /// The result.
        methods.add_method("advance", |lua, this, ()| {
            let prev = this.inner.borrow().state();
            let call_idx = this.inner.borrow_mut().advance();
            fire_call_callback(lua, &this.callbacks, call_idx)?;
            fire_event_callbacks(lua, &this.inner.borrow(), &this.callbacks, prev)?;
            Ok(())
        });

        /// Skip on this Sequencer.
        ///
        /// # Parameters
        /// - `index` — `integer`.
        methods.add_method("skip", |_, this, ()| {
            this.inner.borrow_mut().skip();
            Ok(())
        });

        /// Choose on this Sequencer.
        /// @param index : integer
        ///
        /// # Parameters
        /// - `index` — `integer`.
        methods.add_method("choose", |lua, this, index: usize| {
            let prev = this.inner.borrow().state();
            let call_idx = this.inner.borrow_mut().choose(index);
            fire_call_callback(lua, &this.callbacks, call_idx)?;
            fire_event_callbacks(lua, &this.inner.borrow(), &this.callbacks, prev)?;
            Ok(())
        });

        // ── Speed ──

        /// Sets the speed.
        /// @param cps : number
        ///
        /// # Parameters
        /// - `cps` — `number`.
        methods.add_method("setSpeed", |_, this, cps: f32| {
            this.inner.borrow_mut().set_speed(cps);
            Ok(())
        });

        /// Returns the speed.
        /// @return any
        ///
        /// # Returns
        /// The current speed.
        methods.add_method("getSpeed", |_, this, ()| {
            Ok(this.inner.borrow().get_speed())
        });

        // ── State queries ──

        /// Returns the state.
        /// @return any
        ///
        /// # Returns
        /// The current state.
        methods.add_method("getState", |_, this, ()| {
            Ok(this.inner.borrow().state().as_str().to_string())
        });

        /// Returns `true` if active.
        /// @return any
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isActive", |_, this, ()| {
            Ok(this.inner.borrow().is_active())
        });

        /// Returns `true` if waiting for choice.
        /// @return any
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isWaitingForChoice", |_, this, ()| {
            Ok(this.inner.borrow().is_waiting_for_choice())
        });

        // ── Text queries ──

        /// Current speaker on this Sequencer.
        /// @return any
        ///
        /// # Returns
        /// The result.
        methods.add_method("currentSpeaker", |_, this, ()| {
            Ok(this.inner.borrow().current_speaker().to_string())
        });

        /// Current text on this Sequencer.
        /// @return any
        ///
        /// # Returns
        /// The result.
        methods.add_method("currentText", |_, this, ()| {
            Ok(this.inner.borrow().current_text().to_string())
        });

        /// Revealed text on this Sequencer.
        /// @return any
        ///
        /// # Returns
        /// The result.
        methods.add_method("revealedText", |_, this, ()| {
            Ok(this.inner.borrow().revealed_text().to_string())
        });

        // ── Choice queries ──

        /// Returns the choice text.
        /// @return any
        ///
        /// # Returns
        /// The current choice text.
        methods.add_method("getChoiceText", |_, this, ()| {
            Ok(this.inner.borrow().choice_text().to_string())
        });

        /// Returns the choice labels.
        /// @return table
        ///
        /// # Returns
        /// The current choice labels.
        methods.add_method("getChoiceLabels", |lua, this, ()| {
            let seq = this.inner.borrow();
            let labels = seq.choice_labels();
            let tbl = lua.create_table()?;
            for (i, label) in labels.iter().enumerate() {
                tbl.set(i + 1, label.to_string())?;
            }
            Ok(tbl)
        });

        // ── Event callbacks ──

        /// Registers an event listener callback.
        /// @param event : string
        /// @param func : function
        ///
        /// # Parameters
        /// - `event` — `string`.
        /// - `func` — `function`.
        methods.add_method("on", |lua, this, (event, func): (String, LuaFunction)| {
            let key = lua.create_registry_value(func)?;
            let mut cbs = this.callbacks.borrow_mut();
            match event.as_str() {
                "line" => cbs.on_line = Some(key),
                "choice" => cbs.on_choice = Some(key),
                "finished" => cbs.on_finished = Some(key),
                other => {
                    return Err(LuaError::RuntimeError(format!(
                        "luna.dialog: unknown event '{other}'"
                    )));
                }
            }
            Ok(())
        });

        /// Removes a previously registered event listener.
        /// @param event : string
        ///
        /// # Parameters
        /// - `event` — `string`.
        methods.add_method("off", |_, this, event: String| {
            let mut cbs = this.callbacks.borrow_mut();
            match event.as_str() {
                "line" => cbs.on_line = None,
                "choice" => cbs.on_choice = None,
                "finished" => cbs.on_finished = None,
                other => {
                    return Err(LuaError::RuntimeError(format!(
                        "luna.dialog: unknown event '{other}'"
                    )));
                }
            }
            Ok(())
        });
    }
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Registers the `luna.dialog` module with the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let module = lua.create_table()?;

    /// New sequencer.
    ///
    /// @return any
    module.set(
        "newSequencer",
        lua.create_function(|_, ()| {
            Ok(LuaSequencer {
                inner: Rc::new(RefCell::new(Sequencer::new())),
                callbacks: Rc::new(RefCell::new(SequencerCallbacks::new())),
            })
        })?,
    )?;

    /// Dialog on this Sequencer.
    ///
    /// # Returns
    /// The result.
    luna.set("dialog", module)?;
    Ok(())
}
