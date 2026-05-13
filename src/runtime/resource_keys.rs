//! Slot-map key declarations for runtime resource registries.
//! Keeps handle types distinct across textures, shaders, meshes, and auxiliary assets.

use slotmap::new_key_type;
new_key_type! {
    /// Key for texture storage entries.
    pub struct TextureKey;
    /// Key for font storage entries.
    pub struct FontKey;
    /// Key for render-canvas storage entries.
    pub struct CanvasKey;
    /// Key for sound storage entries.
    pub struct SoundKey;
    /// Key for particle system storage entries.
    pub struct ParticleKey;
    /// Key for sprite-batch storage entries.
    pub struct SpriteBatchKey;
    /// Key for shader storage entries.
    pub struct ShaderKey;
    /// Key for mesh storage entries.
    pub struct MeshKey;
    /// Key for compound-shape storage entries.
    pub struct ShapeKey;
    /// Key for audio bus storage entries.
    pub struct BusKey;
    /// Key for MIDI player storage entries.
    pub struct MidiPlayerKey;
    /// Key for queued-audio playback entries.
    pub struct QueueableKey;
    /// Key for light storage entries.
    pub struct LightKey;
    /// Key for occluder storage entries.
    pub struct OccluderKey;
}
