//! `ImageEffect` — an ordered chain of `PostFxEffect` passes for per-image draw calls.
//!
//! [`ImageEffect`] groups one or more [`PostFxEffect`] entries and converts them
//! to lightweight [`crate::graphics::ImageEffectPass`] values via
//! [`ImageEffect::to_passes`]. This module lives in **Tier 2** and is permitted
//! to import from `crate::graphics` (Tier 1).

use std::cell::RefCell;
use std::rc::Rc;

use crate::graphics::ImageEffectPass;
use crate::postfx::PostFxEffect;

/// An ordered shader-effect chain to apply when drawing a single image.
///
/// Can be attached to a `luna.graphics.draw` call via the options-table
/// overload (`effect` key). Effects are applied in insertion order through
/// each enabled pass. `to_passes` converts the chain to the lightweight
/// Tier-1 type embedded into `DrawCommand` variants.
///
/// Each effect entry is stored as a shared `Rc<RefCell<PostFxEffect>>` so that
/// Lua-side handles returned by `addEffect` or `getEffect` reflect mutations
/// made through the chain itself.
///
/// # Fields
/// - `effects` — `Vec<Rc<RefCell<PostFxEffect>>>` — Ordered list of shader passes.
/// - `name` — `String` — Optional human-readable label for the chain.
pub struct ImageEffect {
    /// Ordered list of shader passes in this chain (shared references).
    pub(crate) effects: Vec<Rc<RefCell<PostFxEffect>>>,
    /// Optional human-readable label for the effect chain.
    pub(crate) name: String,
}

impl ImageEffect {
    /// Creates a new empty effect chain with the given label.
    ///
    /// # Parameters
    /// - `name` — `&str` — Human-readable label (may be empty).
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: &str) -> Self {
        Self {
            effects: Vec::new(),
            name: name.to_owned(),
        }
    }

    /// Wraps `effect` in an `Rc<RefCell<>>` and appends it to the end of the chain.
    ///
    /// # Parameters
    /// - `effect` — `PostFxEffect` — The pass to append.
    pub fn add_effect(&mut self, effect: PostFxEffect) {
        self.effects.push(Rc::new(RefCell::new(effect)));
    }

    /// Appends a pre-shared effect reference to the end of the chain.
    ///
    /// Use this when the caller needs to retain a handle to the same effect
    /// that the chain holds (e.g. from the Lua `addEffect` binding).
    ///
    /// # Parameters
    /// - `effect` — `Rc<RefCell<PostFxEffect>>` — Shared reference to append.
    pub(crate) fn add_effect_rc(&mut self, effect: Rc<RefCell<PostFxEffect>>) {
        self.effects.push(effect);
    }

    /// Returns a shared reference to the effect at the given 0-based index, or `None`.
    ///
    /// # Parameters
    /// - `idx` — `usize` — 0-based position.
    ///
    /// # Returns
    /// `Option<Rc<RefCell<PostFxEffect>>>`.
    pub fn get_effect_by_index(&self, idx: usize) -> Option<Rc<RefCell<PostFxEffect>>> {
        self.effects.get(idx).cloned()
    }

    /// Returns a shared reference to the first effect whose type name matches `name`, or `None`.
    ///
    /// # Parameters
    /// - `name` — `&str` — Effect type name (e.g. `"blur"`).
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
    /// - `idx` — `usize` — 0-based position.
    ///
    /// # Returns
    /// `bool` — `true` if the index was in range.
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
    /// - `name` — `&str` — Effect type name.
    ///
    /// # Returns
    /// `bool` — `true` if a matching effect was found and removed.
    pub fn remove_by_name(&mut self, name: &str) -> bool {
        if let Some(pos) = self
            .effects
            .iter()
            .position(|e| e.borrow().get_type_name() == name)
        {
            self.effects.remove(pos);
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

    /// Converts the effect chain to lightweight [`ImageEffectPass`] values for the Tier-1 graphics layer.
    ///
    /// Each [`PostFxEffect`] is converted by copying its type name, parameter map,
    /// and enabled flag. The result is embedded into a `DrawCommand` variant.
    ///
    /// # Returns
    /// `Vec<ImageEffectPass>`.
    pub fn to_passes(&self) -> Vec<ImageEffectPass> {
        self.effects
            .iter()
            .map(|e| {
                let e = e.borrow();
                ImageEffectPass {
                    effect_name: e.get_type_name().to_owned(),
                    params: e.params.clone(),
                    enabled: e.enabled,
                }
            })
            .collect()
    }
}
