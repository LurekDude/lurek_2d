use super::effect::PostFxEffect;
use crate::log_msg;
use crate::render::ShaderPassDescriptor;
use crate::runtime::log_messages::{IE01, IE02, IE03};
use std::cell::RefCell;
use std::rc::Rc;
pub struct ImageEffect {
    pub(crate) effects: Vec<Rc<RefCell<PostFxEffect>>>,
    #[allow(dead_code)]
    pub(crate) name: String,
}
impl ImageEffect {
    pub fn new(name: &str) -> Self {
        log_msg!(debug, IE01, "{}", name);
        Self {
            effects: Vec::new(),
            name: name.to_owned(),
        }
    }
    pub fn add_effect(&mut self, effect: PostFxEffect) {
        log_msg!(debug, IE02);
        self.effects.push(Rc::new(RefCell::new(effect)));
    }
    #[allow(dead_code)]
    pub(crate) fn add_effect_rc(&mut self, effect: Rc<RefCell<PostFxEffect>>) {
        self.effects.push(effect);
    }
    pub fn get_effect_by_index(&self, idx: usize) -> Option<Rc<RefCell<PostFxEffect>>> {
        self.effects.get(idx).cloned()
    }
    pub fn get_effect_by_name(&self, name: &str) -> Option<Rc<RefCell<PostFxEffect>>> {
        self.effects
            .iter()
            .find(|e| e.borrow().get_type_name() == name)
            .cloned()
    }
    pub fn remove_by_index(&mut self, idx: usize) -> bool {
        if idx < self.effects.len() {
            self.effects.remove(idx);
            true
        } else {
            false
        }
    }
    pub fn remove_by_name(&mut self, name: &str) -> bool {
        if let Some(pos) = self
            .effects
            .iter()
            .position(|e| e.borrow().get_type_name() == name)
        {
            self.effects.remove(pos);
            log_msg!(debug, IE03, "{}", name);
            true
        } else {
            false
        }
    }
    pub fn clear(&mut self) {
        self.effects.clear();
    }
    pub fn effect_count(&self) -> usize {
        self.effects.len()
    }
    pub fn to_passes(&self) -> Vec<ShaderPassDescriptor> {
        self.effects
            .iter()
            .map(|e| {
                let e = e.borrow();
                ShaderPassDescriptor {
                    effect_name: e.get_type_name().to_owned(),
                    params: e.params.clone(),
                    enabled: e.enabled,
                }
            })
            .collect()
    }
}
