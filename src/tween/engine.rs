use crate::tween::handle::{LuaTween, LuaTweenParallel, LuaTweenSequence};
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
pub struct TweenEngine {
    pub active_tweens: Vec<LuaRegistryKey>,
    pub active_seqs: Vec<LuaRegistryKey>,
    pub active_pars: Vec<LuaRegistryKey>,
    pub active_springs: Vec<LuaRegistryKey>,
    pub custom_easings: HashMap<String, LuaRegistryKey>,
}
impl TweenEngine {
    pub fn new() -> Self {
        Self {
            active_tweens: Vec::new(),
            active_seqs: Vec::new(),
            active_pars: Vec::new(),
            active_springs: Vec::new(),
            custom_easings: HashMap::new(),
        }
    }
    pub fn update(this_rc: &Rc<RefCell<Self>>, lua: &Lua, dt: f64) -> LuaResult<()> {
        let tween_keys = std::mem::take(&mut this_rc.borrow_mut().active_tweens);
        let mut still_active_tweens = Vec::with_capacity(tween_keys.len());
        for key in tween_keys {
            let ud: LuaAnyUserData = lua.registry_value(&key)?;
            let done = {
                let mut tw = ud.borrow_mut::<LuaTween>()?;
                if tw.owned_by_parent || !tw.active {
                    if !tw.active {
                        if let Some(k) = tw.on_cancel.take() {
                            let f: LuaFunction = lua.registry_value(&k)?;
                            let _ = f.call::<_, ()>(());
                            lua.remove_registry_value(k)?;
                        }
                    }
                    true
                } else {
                    tw.tick_with(lua, dt)?
                }
            };
            if done {
                lua.remove_registry_value(key)?;
            } else {
                still_active_tweens.push(key);
            }
        }
        this_rc.borrow_mut().active_tweens = still_active_tweens;
        let seq_keys = std::mem::take(&mut this_rc.borrow_mut().active_seqs);
        let mut still_active_seqs = Vec::with_capacity(seq_keys.len());
        for key in seq_keys {
            let ud: LuaAnyUserData = lua.registry_value(&key)?;
            let done = {
                let mut seq = ud.borrow_mut::<LuaTweenSequence>()?;
                if !seq.active {
                    true
                } else {
                    seq.tick_with(lua, dt)?
                }
            };
            if done {
                lua.remove_registry_value(key)?;
            } else {
                still_active_seqs.push(key);
            }
        }
        this_rc.borrow_mut().active_seqs = still_active_seqs;
        let par_keys = std::mem::take(&mut this_rc.borrow_mut().active_pars);
        let mut still_active_pars = Vec::with_capacity(par_keys.len());
        for key in par_keys {
            let ud: LuaAnyUserData = lua.registry_value(&key)?;
            let done = {
                let mut par = ud.borrow_mut::<LuaTweenParallel>()?;
                if !par.active {
                    true
                } else {
                    par.tick_with(lua, dt)?
                }
            };
            if done {
                lua.remove_registry_value(key)?;
            } else {
                still_active_pars.push(key);
            }
        }
        this_rc.borrow_mut().active_pars = still_active_pars;
        Ok(())
    }
    pub fn cancel_all(this_rc: &Rc<RefCell<Self>>, lua: &Lua) -> LuaResult<()> {
        let (tweens, seqs, pars) = {
            let mut s = this_rc.borrow_mut();
            (
                std::mem::take(&mut s.active_tweens),
                std::mem::take(&mut s.active_seqs),
                std::mem::take(&mut s.active_pars),
            )
        };
        for key in tweens {
            let ud: LuaAnyUserData = lua.registry_value(&key)?;
            {
                let mut tw = ud.borrow_mut::<LuaTween>()?;
                tw.active = false;
                if let Some(k) = tw.on_cancel.take() {
                    let f: LuaFunction = lua.registry_value(&k)?;
                    let _ = f.call::<_, ()>(());
                    lua.remove_registry_value(k)?;
                }
            }
            lua.remove_registry_value(key)?;
        }
        for key in seqs {
            let ud: LuaAnyUserData = lua.registry_value(&key)?;
            {
                ud.borrow_mut::<LuaTweenSequence>()?.active = false;
            }
            lua.remove_registry_value(key)?;
        }
        for key in pars {
            let ud: LuaAnyUserData = lua.registry_value(&key)?;
            {
                ud.borrow_mut::<LuaTweenParallel>()?.active = false;
            }
            lua.remove_registry_value(key)?;
        }
        Ok(())
    }
    pub fn active_count(&self) -> usize {
        self.active_tweens.len()
            + self.active_seqs.len()
            + self.active_pars.len()
            + self.active_springs.len()
    }
}
impl Default for TweenEngine {
    fn default() -> Self {
        Self::new()
    }
}
