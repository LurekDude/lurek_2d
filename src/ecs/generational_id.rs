//! - Pack and unpack 24-bit slot + 8-bit generation into a single u32 entity id.
//! - Stateless utility struct with no allocation or state.
//! - Supports up to ~16M slots and 256 generations per slot.

/// Stateless namespace for encoding and decoding packed entity identifiers.
pub struct GenerationalId;

/// Encoding and decoding helpers for packed generational entity ids.
impl GenerationalId {
    /// Packs a 24-bit slot and 8-bit generation into a single entity id.
    pub fn pack(slot: u32, generation: u8) -> u32 {
        ((generation as u32) << 24) | (slot & 0x00FF_FFFF)
    }
    /// Extracts the slot index from a packed entity id.
    pub fn unpack_slot(id: u32) -> u32 {
        id & 0x00FF_FFFF
    }
    /// Extracts the generation byte from a packed entity id.
    pub fn unpack_gen(id: u32) -> u8 {
        (id >> 24) as u8
    }
}
