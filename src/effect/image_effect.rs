
use super::effect::PostFxEffect;
use crate::render::ShaderPassDescriptor;
use crate::runtime::log_messages::{IE01, IE02, IE03};
use std::cell::RefCell;
use std::rc::Rc;
/// Groups post effects under one image-scoped effect pipeline.
pub struct ImageEffect {
    /// Owned effect instances applied by this image effect pipeline.
    pub(crate) effects: Vec<Rc<RefCell<PostFxEffect>>>,
    #[allow(dead_code)]
    /// Debug name for this image effect pipeline.
    pub(crate) name: String,
}
impl ImageEffect {
    /// Creates an empty image effect pipeline with the given debug name.
    pub fn new(name: &str) -> Self {
        log_msg!(debug, IE01, "{}", name);
        Self {
            effects: Vec::new(),
            name: name.to_owned(),
        }
    }
    /// Appends a new owned effect instance to the pipeline.
    pub fn add_effect(&mut self, effect: PostFxEffect) {
        log_msg!(debug, IE02);
        self.effects.push(Rc::new(RefCell::new(effect)));
    }
    #[allow(dead_code)]
    /// Appends a shared effect handle to the pipeline without cloning it.
    pub(crate) fn add_effect_rc(&mut self, effect: Rc<RefCell<PostFxEffect>>) {
        self.effects.push(effect);
    }
    /// Returns the shared effect handle at the given zero-based index.
    pub fn get_effect_by_index(&self, idx: usize) -> Option<Rc<RefCell<PostFxEffect>>> {
        self.effects.get(idx).cloned()
    }
    /// Returns the first effect whose type name matches the requested name.
    pub fn get_effect_by_name(&self, name: &str) -> Option<Rc<RefCell<PostFxEffect>>> {
        self.effects
            .iter()
            .find(|e| e.borrow().get_type_name() == name)
            .cloned()
    }
    /// Removes the effect at the given zero-based index.
    pub fn remove_by_index(&mut self, idx: usize) -> bool {
        if idx < self.effects.len() {
            self.effects.remove(idx);
            true
        } else {
            false
        }
    }
    /// Removes the first effect whose type name matches the requested name.
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
    /// Removes every effect from the pipeline.
    pub fn clear(&mut self) {
        self.effects.clear();
    }
    /// Returns the number of effects currently stored in the pipeline.
    pub fn effect_count(&self) -> usize {
        self.effects.len()
    }
    /// Converts the pipeline into renderer shader pass descriptors.
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
