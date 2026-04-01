//! Typed resource keys for generational ID-based resource pools.
//!
//! Each key type maps to a specific resource category, preventing
//! accidental cross-pool lookups at compile time.

use slotmap::new_key_type;

new_key_type! {
    /// Key for texture resources stored in SharedState.
    pub struct TextureKey;
    /// Key for font resources stored in SharedState.
    pub struct FontKey;
    /// Key for canvas off-screen render targets.
    pub struct CanvasKey;
    /// Key for audio source entries in the Mixer.
    pub struct SoundKey;
    /// Key for particle system instances.
    pub struct ParticleKey;
    /// Key for sprite batch instances.
    pub struct SpriteBatchKey;
    /// Key for custom shader instances.
    pub struct ShaderKey;
    /// Key for mesh instances.
    pub struct MeshKey;
    /// Key for audio bus instances in the Mixer.
    pub struct BusKey;
    /// Key for MIDI player instances.
    pub struct MidiPlayerKey;
}
