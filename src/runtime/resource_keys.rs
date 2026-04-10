//! Typed resource keys for generational ID-based resource pools.
//!
//! Each key type maps to a specific resource category, preventing
//! accidental cross-pool lookups at compile time.
//!
//! This module is part of Lurek2D's `engine` subsystem and provides the implementation
//! details for resource keys-related operations and data management.
//! Key types exported from this module: `TextureKey`, `FontKey`, `CanvasKey`, `SoundKey`, `ParticleKey`, `ShapeKey`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use slotmap::new_key_type;

new_key_type! {
    /// Key for texture resources stored in SharedState.
    /// # Fields
    /// Opaque slotmap key — no public fields.
    pub struct TextureKey;
    /// Key for font resources stored in SharedState.
    /// # Fields
    /// Opaque slotmap key — no public fields.
    pub struct FontKey;
    /// Key for canvas off-screen render targets.
    /// # Fields
    /// Opaque slotmap key — no public fields.
    pub struct CanvasKey;
    /// Key for audio source entries in the Mixer.
    /// # Fields
    /// Opaque slotmap key — no public fields.
    pub struct SoundKey;
    /// Key for particle system instances.
    /// # Fields
    /// Opaque slotmap key — no public fields.
    pub struct ParticleKey;
    /// Key for sprite batch instances.
    /// # Fields
    /// Opaque slotmap key — no public fields.
    pub struct SpriteBatchKey;
    /// Key for custom shader instances.
    /// # Fields
    /// Opaque slotmap key — no public fields.
    pub struct ShaderKey;
    /// Key for mesh instances.
    /// # Fields
    /// Opaque slotmap key — no public fields.
    pub struct MeshKey;
    /// Key for compound shape instances.
    /// # Fields
    /// Opaque slotmap key — no public fields.
    pub struct ShapeKey;
    /// Key for audio bus instances in the Mixer.
    /// # Fields
    /// Opaque slotmap key — no public fields.
    pub struct BusKey;
    /// Key for MIDI player instances.
    /// # Fields
    /// Opaque slotmap key — no public fields.
    pub struct MidiPlayerKey;
    /// Key for queueable audio source instances in the Mixer.
    /// # Fields
    /// Opaque slotmap key — no public fields.
    pub struct QueueableKey;
    /// Key for light source instances in LightWorld.
    /// # Fields
    /// Opaque slotmap key — no public fields.
    pub struct LightKey;
    /// Key for shadow occluder instances in LightWorld.
    /// # Fields
    /// Opaque slotmap key — no public fields.
    pub struct OccluderKey;
}
