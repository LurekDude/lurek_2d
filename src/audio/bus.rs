//! Named audio bus for grouping sources under shared volume, pitch, and pause controls.
//!
//! This module is part of Lurek2D's `audio` subsystem and provides the implementation
//! details for bus-related operations and data management.
//! Key types exported from this module: `Bus`.
//! Primary functions: `new()`, `name()`, `volume()`, `set_volume()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.
use crate::audio::dsp::{AtomicParam, EffectParams, EffectType};
use crate::runtime::log_messages::{BU01, BU02, BU03};
use crate::log_msg;

/// A named audio bus that applies volume, pitch, and pause overrides to all
/// sources assigned to it.
///
/// Buses are pure data containers — they hold no rodio resources.
/// The `Mixer` multiplies a source's per-source volume/pitch by its assigned
/// bus values. Setting a bus to paused suppresses playback of all assigned
/// sources until the bus is resumed.
///
/// # Fields
/// - `name` — `String`.
/// - `volume` — `f32`.
/// - `pitch` — `f32`.
/// - `paused` — `bool`.
#[derive(Debug, Clone)]
pub struct Bus {
    pub effects:
        std::sync::Arc<std::sync::RwLock<Vec<std::sync::Arc<crate::audio::dsp::EffectParams>>>>,
    name: String,
    volume: f32,
    pitch: f32,
    paused: bool,
}

impl Bus {
    /// Creates a new bus with the given name, volume `1.0`, pitch `1.0`, and not paused.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: impl Into<String>) -> Self {
        let name = name.into();
        log_msg!(debug, BU01, "{}", name);
        Bus {
            name,
            volume: 1.0,
            pitch: 1.0,
            paused: false,
            effects: std::sync::Arc::new(std::sync::RwLock::new(Vec::new())),
        }
    }

    /// Returns the bus name.
    ///
    /// # Returns
    /// `&str`.
    pub fn name(&self) -> &str {
        &self.name
    }

    /// Returns the bus volume (always `>= 0.0`).
    ///
    /// # Returns
    /// `f32`.
    pub fn volume(&self) -> f32 {
        self.volume
    }

    /// Sets the bus volume, clamped to `>= 0.0`.
    ///
    /// # Parameters
    /// - `volume` — `f32`.
    pub fn set_volume(&mut self, volume: f32) {
        self.volume = volume.max(0.0);
    }

    /// Returns the bus pitch multiplier (always `>= 0.0`).
    ///
    /// # Returns
    /// `f32`.
    pub fn pitch(&self) -> f32 {
        self.pitch
    }

    /// Sets the bus pitch multiplier, clamped to `>= 0.0`.
    ///
    /// # Parameters
    /// - `pitch` — `f32`.
    pub fn set_pitch(&mut self, pitch: f32) {
        self.pitch = pitch.max(0.0);
    }

    /// Pauses the bus. All sources assigned to this bus will be suppressed.
    pub fn pause(&mut self) {
        log_msg!(debug, BU02, "{}", self.name);
        self.paused = true;
    }

    /// Resumes the bus.
    pub fn resume(&mut self) {
        log_msg!(debug, BU03, "{}", self.name);
        self.paused = false;
    }

    /// Returns whether the bus is paused. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_paused(&self) -> bool {
        self.paused
    }

    /// Adds a DSP effect to this audio bus.
    ///
    /// Parses the effect type name, constructs an [`EffectParams`] slot with a monotonic ID,
    /// and appends it to the shared effects list. The returned ID can be used to set parameters
    /// or remove the effect later.
    ///
    /// # Parameters
    /// - `effect_type_str` — `&str`. Effect type: `"lowpass"`, `"highpass"`, `"bandpass"`, `"reverb"`, `"chorus"`.
    /// - `p1_val` — `f32`. Initial primary parameter value (cutoff frequency in Hz for filters; room size for reverb/chorus).
    ///
    /// # Returns
    /// `Result<u32, String>`. The assigned effect ID on success, or an error string for an unknown type.
    pub fn add_effect(&self, effect_type_str: &str, p1_val: f32) -> Result<u32, String> {
        let effect_type = match effect_type_str {
            "lowpass" => EffectType::Lowpass,
            "highpass" => EffectType::Highpass,
            "bandpass" => EffectType::Bandpass,
            "reverb" => EffectType::Reverb,
            "chorus" => EffectType::Chorus,
            other => return Err(format!("invalid effect type: {}", other)),
        };
        let mut fx_list = self.effects.write().unwrap();
        let eid = (fx_list.len() + 1) as u32;
        fx_list.push(std::sync::Arc::new(EffectParams {
            id: eid,
            typ: effect_type,
            p1: AtomicParam::new(p1_val),
            p2: AtomicParam::new(1.0),
            p3: AtomicParam::new(0.5),
        }));
        Ok(eid)
    }

    /// Removes a DSP effect from this audio bus by ID.
    ///
    /// Acquires a write lock on the effects list and retains all entries whose ID
    /// differs from `effect_id`. Returns an error if no effect with that ID exists.
    ///
    /// # Parameters
    /// - `effect_id` — `u32`. The ID of the effect to remove, as returned by [`Bus::add_effect`].
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn remove_effect(&self, effect_id: u32) -> Result<(), String> {
        let mut fx_list = self.effects.write().unwrap();
        let len_before = fx_list.len();
        fx_list.retain(|fx| fx.id != effect_id);
        if fx_list.len() == len_before {
            Err(format!("effect {} not found", effect_id))
        } else {
            Ok(())
        }
    }
}
