//! Round-robin polyphony pool for repeated playback of a single audio file.
//! SoundPool: cycles through pre-loaded voice keys for cost-effective concurrent playback.

use crate::runtime::resource_keys::SoundKey;

/// Round-robin voice pool cycling through pre-loaded source keys.
pub struct SoundPool {
    keys: Vec<SoundKey>,
    next: usize,
    file_path: String,
    volume: f32,
    bus_name: Option<String>,
}

impl SoundPool {
    /// Create new pool from pre-loaded voice keys.
    pub fn new(keys: Vec<SoundKey>, file_path: String) -> Self {
        Self {
            keys,
            next: 0,
            file_path,
            volume: 1.0,
            bus_name: None,
        }
    }

    /// Return voice count.
    pub fn voice_count(&self) -> usize {
        self.keys.len()
    }

    /// Return the source file path.
    pub fn file_path(&self) -> &str {
        &self.file_path
    }

    /// Return shared volume (default 1.0).
    pub fn volume(&self) -> f32 {
        self.volume
    }

    /// Set shared volume (clamped >= 0.0).
    pub fn set_volume(&mut self, vol: f32) {
        self.volume = vol.max(0.0);
    }

    /// Return the assigned bus name, if any.
    pub fn bus_name(&self) -> Option<&str> {
        self.bus_name.as_deref()
    }

    /// Assign all voices to a named bus.
    pub fn set_bus(&mut self, name: &str) {
        self.bus_name = Some(name.to_owned());
    }

    /// Clear the bus assignment.
    pub fn clear_bus(&mut self) {
        self.bus_name = None;
    }

    /// Return next voice key, cycling through all voices.
    pub fn next_voice(&mut self) -> SoundKey {
        let key = self.keys[self.next % self.keys.len()];
        self.next = (self.next + 1) % self.keys.len();
        key
    }

    /// Return all voice keys as a slice.
    pub fn all_keys(&self) -> &[SoundKey] {
        &self.keys
    }

    /// Return true if pool has at least one voice.
    pub fn is_valid(&self) -> bool {
        !self.keys.is_empty()
    }
}

