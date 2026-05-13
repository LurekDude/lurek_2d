//! `SoundPool` — round-robin voice allocator for one-shot/polyphonic sound playback.
//! Stores a fixed set of preloaded `SoundKey` voices for one file path and returns the
//! next key on each trigger to avoid voice stealing conflicts.

use crate::runtime::resource_keys::SoundKey;
/// Round-robin pool of preloaded source keys representing voices for one sound asset.
pub struct SoundPool {
    /// Source keys used as available voices.
    keys: Vec<SoundKey>,
    /// Next voice index used by `next_voice`.
    next: usize,
    /// Original source file path associated with these voices.
    file_path: String,
    /// Per-pool gain multiplier applied when triggering a voice.
    volume: f32,
    /// Optional target bus name for routed playback.
    bus_name: Option<String>,
}
impl SoundPool {
    /// Create a pool with `keys` and source `file_path`, defaulting to volume=1.0 and no bus.
    pub fn new(keys: Vec<SoundKey>, file_path: String) -> Self {
        Self {
            keys,
            next: 0,
            file_path,
            volume: 1.0,
            bus_name: None,
        }
    }
    /// Return number of voices in this pool.
    pub fn voice_count(&self) -> usize {
        self.keys.len()
    }
    /// Return source file path associated with this pool.
    pub fn file_path(&self) -> &str {
        &self.file_path
    }
    /// Return current pool gain multiplier.
    pub fn volume(&self) -> f32 {
        self.volume
    }
    /// Set pool gain multiplier; values below 0.0 are clamped to 0.0.
    pub fn set_volume(&mut self, vol: f32) {
        self.volume = vol.max(0.0);
    }
    /// Return assigned bus name, or `None` if unassigned.
    pub fn bus_name(&self) -> Option<&str> {
        self.bus_name.as_deref()
    }
    /// Assign this pool to bus `name`.
    pub fn set_bus(&mut self, name: &str) {
        self.bus_name = Some(name.to_owned());
    }
    /// Remove any bus assignment from this pool.
    pub fn clear_bus(&mut self) {
        self.bus_name = None;
    }
    /// Return next voice key in round-robin order and advance the cursor.
    pub fn next_voice(&mut self) -> SoundKey {
        let key = self.keys[self.next % self.keys.len()];
        self.next = (self.next + 1) % self.keys.len();
        key
    }
    /// Return all voice keys managed by this pool.
    pub fn all_keys(&self) -> &[SoundKey] {
        &self.keys
    }
    /// Return `true` when the pool contains at least one voice key.
    pub fn is_valid(&self) -> bool {
        !self.keys.is_empty()
    }
}
