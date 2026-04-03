//! Typed resource keys for generational ID-based resource pools.
//!
//! Each key type maps to a specific resource category, preventing
//! accidental cross-pool lookups at compile time.
//!
//! This module is part of Luna2D's `engine` subsystem and provides the implementation
//! details for resource keys-related operations and data management.
//! Key types exported from this module: `TextureKey`, `FontKey`, `CanvasKey`, `SoundKey`, `ParticleKey`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

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
    /// Key for particle system instances. Consult the module-level documentation for the broader usage context and preconditions.
    pub struct ParticleKey;
    /// Key for sprite batch instances. Consult the module-level documentation for the broader usage context and preconditions.
    pub struct SpriteBatchKey;
    /// Key for custom shader instances. Consult the module-level documentation for the broader usage context and preconditions.
    pub struct ShaderKey;
    /// Key for mesh instances. Consult the module-level documentation for the broader usage context and preconditions.
    pub struct MeshKey;
    /// Key for audio bus instances in the Mixer.
    pub struct BusKey;
    /// Key for MIDI player instances. Consult the module-level documentation for the broader usage context and preconditions.
    pub struct MidiPlayerKey;
}
