//! `Bus` — a named audio routing channel used by `Mixer` to group sources.
//! Holds per-bus volume, pitch, pause state, a shared DSP effect chain, and an optional
//! duck-target for automatic volume reduction on another bus. Does not own playback state.
//! Used by `Mixer` and exposed to Lua via `audio_api.rs`.

use crate::audio::dsp::{AtomicParam, EffectParams, EffectType};
use crate::log_msg;
use crate::runtime::log_messages::{BU01, BU02, BU03};
#[derive(Debug, Clone)]
/// Named audio routing channel that applies volume, pitch, effects, and ducking to its sources.
pub struct Bus {
    /// Human-readable identifier used as the registry key in `Mixer`.
    name: String,
    /// Volume multiplier applied to all sources on this bus; clamped to >= 0.0.
    volume: f32,
    /// Pitch multiplier applied to all sources on this bus; clamped to >= 0.0.
    pitch: f32,
    /// When true, all sources assigned to this bus are suspended from playback.
    paused: bool,
    /// Shared DSP effect chain applied by `DynamicEffectSource` on every source in this bus.
    pub effects:
        std::sync::Arc<std::sync::RwLock<Vec<std::sync::Arc<crate::audio::dsp::EffectParams>>>>,
    /// Optional duck target: `(bus_name, duck_volume)` to suppress when this bus is active.
    pub duck_target: Option<(String, f32)>,
}
impl Bus {
    /// Create a new bus with the given name, volume=1.0, pitch=1.0, unpaused, and no effects.
    pub fn new(name: impl Into<String>) -> Self {
        let name = name.into();
        log_msg!(debug, BU01, "{}", name);
        Bus {
            name,
            volume: 1.0,
            pitch: 1.0,
            paused: false,
            effects: std::sync::Arc::new(std::sync::RwLock::new(Vec::new())),
            duck_target: None,
        }
    }
    /// Return the name of this bus.
    pub fn name(&self) -> &str {
        &self.name
    }
    /// Return the current volume multiplier for this bus.
    pub fn volume(&self) -> f32 {
        self.volume
    }
    /// Set the volume multiplier; values below 0.0 are clamped to 0.0.
    pub fn set_volume(&mut self, volume: f32) {
        self.volume = volume.max(0.0);
    }
    /// Return the current pitch multiplier for this bus.
    pub fn pitch(&self) -> f32 {
        self.pitch
    }
    /// Set the pitch multiplier; values below 0.0 are clamped to 0.0.
    pub fn set_pitch(&mut self, pitch: f32) {
        self.pitch = pitch.max(0.0);
    }
    /// Pause all sources on this bus; no-op if already paused.
    pub fn pause(&mut self) {
        log_msg!(debug, BU02, "{}", self.name);
        self.paused = true;
    }
    /// Resume all sources on this bus; no-op if already playing.
    pub fn resume(&mut self) {
        log_msg!(debug, BU03, "{}", self.name);
        self.paused = false;
    }
    /// Return `true` when this bus is paused.
    pub fn is_paused(&self) -> bool {
        self.paused
    }
    /// Append a DSP effect of `effect_type_str` with initial parameter `p1_val` to the chain; returns the new effect ID.
    pub fn add_effect(&self, effect_type_str: &str, p1_val: f32) -> Result<u32, String> {
        let effect_type = match effect_type_str {
            "lowpass" => EffectType::Lowpass,
            "highpass" => EffectType::Highpass,
            "bandpass" => EffectType::Bandpass,
            "reverb" => EffectType::Reverb,
            "chorus" => EffectType::Chorus,
            "notch" => EffectType::Notch,
            "lowshelf" => EffectType::LowShelf,
            "highshelf" => EffectType::HighShelf,
            "bell_eq" => EffectType::BellEq,
            "reverb2" => EffectType::Reverb2,
            "flanger" => EffectType::Flanger,
            "phaser" => EffectType::Phaser,
            "distortion" => EffectType::Distortion,
            "limiter" => EffectType::Limiter,
            "compressor" => EffectType::Compressor,
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
    /// Remove the DSP effect with `effect_id` from the chain; error if not found.
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
    /// Set the duck target bus name and duck volume; volume is clamped to 0.0..=1.0.
    pub fn set_duck_target(&mut self, target_bus_name: impl Into<String>, duck_volume: f32) {
        log_msg!(debug, BU02, "{}", duck_volume);
        self.duck_target = Some((target_bus_name.into(), duck_volume.clamp(0.0, 1.0)));
    }
    /// Remove configured duck target from this bus.
    pub fn clear_duck_target(&mut self) {
        log_msg!(debug, BU03, "duck target cleared");
        self.duck_target = None;
    }
}
