//! `ImageEffect` â€” an ordered chain of `PostFxEffect` passes for per-image draw calls.
//!
//! [`ImageEffect`] groups one or more [`PostFxEffect`] entries and converts them
//! to lightweight [`crate::render::ShaderPassDescriptor`] values via
//! [`ImageEffect::to_passes`]. This module lives in **Tier 2** and is permitted
//! to import from `crate::graphics` (Tier 1).

use std::cell::RefCell;
use std::rc::Rc;

use super::effect::PostFxEffect;
use crate::log_msg;
use crate::render::ShaderPassDescriptor;
use crate::runtime::log_messages::{IE01, IE02, IE03};

/// An ordered shader-effect chain to apply when drawing a single image.
///
/// Can be attached to a `lurek.render.draw` call via the options-table
/// overload (`effect` key). Effects are applied in insertion order through
/// each enabled pass. `to_passes` converts the chain to the lightweight
/// Tier-1 type embedded into `RenderCommand` variants.
///
/// Each effect entry is stored as a shared `Rc<RefCell<PostFxEffect>>` so that
/// Lua-side handles returned by `addEffect` or `getEffect` reflect mutations
/// made through the chain itself.
///
/// # Fields
/// - `effects` â€” `Vec<Rc<RefCell<PostFxEffect>>>` â€” Ordered list of shader passes.
/// - `name` â€” `String` â€” Optional human-readable label for the chain.
pub struct ImageEffect {
    /// Ordered list of shader passes in this chain (shared references).
    pub(crate) effects: Vec<Rc<RefCell<PostFxEffect>>>,
    /// Optional human-readable label for the effect chain.
    #[allow(dead_code)]
    pub(crate) name: String,
}

impl ImageEffect {
    /// Creates a new empty effect chain with the given label.
    ///
    /// # Parameters
    /// - `name` â€” `&str` â€” Human-readable label (may be empty).
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: &str) -> Self {
        log_msg!(debug, IE01, "{}", name);
        Self {
            effects: Vec::new(),
            name: name.to_owned(),
        }
    }

    /// Wraps `effect` in an `Rc<RefCell<>>` and appends it to the end of the chain.
    ///
    /// # Parameters
    /// - `effect` â€” `PostFxEffect` â€” The pass to append.
    pub fn add_effect(&mut self, effect: PostFxEffect) {
        log_msg!(debug, IE02);
        self.effects.push(Rc::new(RefCell::new(effect)));
    }

    /// Appends a pre-shared effect reference to the end of the chain.
    ///
    /// Use this when the caller needs to retain a handle to the same effect
    /// that the chain holds (e.g. from the Lua `addEffect` binding).
    ///
    /// # Parameters
    /// - `effect` â€” `Rc<RefCell<PostFxEffect>>` â€” Shared reference to append.
    #[allow(dead_code)]
    pub(crate) fn add_effect_rc(&mut self, effect: Rc<RefCell<PostFxEffect>>) {
        self.effects.push(effect);
    }

    /// Returns a shared reference to the effect at the given 0-based index, or `None`.
    ///
    /// # Parameters
    /// - `idx` â€” `usize` â€” 0-based position.
    ///
    /// # Returns
    /// `Option<Rc<RefCell<PostFxEffect>>>`.
    pub fn get_effect_by_index(&self, idx: usize) -> Option<Rc<RefCell<PostFxEffect>>> {
        self.effects.get(idx).cloned()
    }

    /// Returns a shared reference to the first effect whose type name matches `name`, or `None`.
    ///
    /// # Parameters
    /// - `name` â€” `&str` â€” Effect type name (e.g. `"blur"`).
    ///
    /// # Returns
    /// `Option<Rc<RefCell<PostFxEffect>>>`.
    pub fn get_effect_by_name(&self, name: &str) -> Option<Rc<RefCell<PostFxEffect>>> {
        self.effects
            .iter()
            .find(|e| e.borrow().get_type_name() == name)
            .cloned()
    }

    /// Removes the effect at the given 0-based index.
    ///
    /// # Parameters
    /// - `idx` â€” `usize` â€” 0-based position.
    ///
    /// # Returns
    /// `bool` â€” `true` if the index was in range.
    pub fn remove_by_index(&mut self, idx: usize) -> bool {
        if idx < self.effects.len() {
            self.effects.remove(idx);
            true
        } else {
            false
        }
    }

    /// Removes the first effect whose type name matches `name`.
    ///
    /// # Parameters
    /// - `name` â€” `&str` â€” Effect type name.
    ///
    /// # Returns
    /// `bool` â€” `true` if a matching effect was found and removed.
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

    /// Removes all effects from the chain.
    pub fn clear(&mut self) {
        self.effects.clear();
    }

    /// Returns the number of effects in the chain.
    ///
    /// # Returns
    /// `usize`.
    pub fn effect_count(&self) -> usize {
        self.effects.len()
    }

    /// Converts the effect chain to lightweight [`ShaderPassDescriptor`] values for the Tier-1 graphics layer.
    ///
    /// Each [`PostFxEffect`] is converted by copying its type name, parameter map,
    /// and enabled flag. The result is embedded into a `RenderCommand` variant.
    ///
    /// # Returns
    /// `Vec<ShaderPassDescriptor>`.
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
