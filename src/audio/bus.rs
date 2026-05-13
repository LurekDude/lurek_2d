//! Named audio buses for volume/pitch/pause/effects grouping.
//! Bus: shared DSP state applied to assigned sources; supports effects chain.

use crate::audio::dsp::{AtomicParam, EffectParams, EffectType};
use crate::log_msg;
use crate::runtime::log_messages::{BU01, BU02, BU03};

/// Named audio bus applying shared volume, pitch, pause, and effects to sources.
#[derive(Debug, Clone)]
pub struct Bus {
    name: String,
    volume: f32,
    pitch: f32,
    paused: bool,
    /// DSP effects chain.
    pub effects:
        std::sync::Arc<std::sync::RwLock<Vec<std::sync::Arc<crate::audio::dsp::EffectParams>>>>,
    /// Ducking target: `(target_bus_name, volume)`.
    pub duck_target: Option<(String, f32)>,
}

impl Bus {
    /// Create new bus with name; default volume/pitch 1.0.
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

    /// Return the bus name.
    pub fn name(&self) -> &str {
        &self.name
    }

    /// Return bus volume (clamped >= 0.0).
    pub fn volume(&self) -> f32 {
        self.volume
    }

    /// Set bus volume (clamped >= 0.0).
    pub fn set_volume(&mut self, volume: f32) {
        self.volume = volume.max(0.0);
    }

    /// Return bus pitch multiplier (clamped >= 0.0).
    pub fn pitch(&self) -> f32 {
        self.pitch
    }

    /// Set bus pitch multiplier (clamped >= 0.0).
    pub fn set_pitch(&mut self, pitch: f32) {
        self.pitch = pitch.max(0.0);
    }

    /// Pause all sources assigned to this bus.
    pub fn pause(&mut self) {
        log_msg!(debug, BU02, "{}", self.name);
        self.paused = true;
    }

    /// Resume playback of this bus.
    pub fn resume(&mut self) {
        log_msg!(debug, BU03, "{}", self.name);
        self.paused = false;
    }

    /// Return true if the bus is paused.
    pub fn is_paused(&self) -> bool {
        self.paused
    }

    /// Add DSP effect to this bus and return its ID; supported types: lowpass, highpass, bandpass, reverb, chorus, etc.
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

    /// Removes a DSP effect by ID. Returns an error if not found.
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

    /// Sets ducking target: reduces a named bus's volume when this bus plays.
    pub fn set_duck_target(&mut self, target_bus_name: impl Into<String>, duck_volume: f32) {
        log_msg!(debug, BU02, "{}", duck_volume);
        self.duck_target = Some((target_bus_name.into(), duck_volume.clamp(0.0, 1.0)));
    }

    /// Clears the ducking target.
    pub fn clear_duck_target(&mut self) {
        log_msg!(debug, BU03, "duck target cleared");
        self.duck_target = None;
    }
}

