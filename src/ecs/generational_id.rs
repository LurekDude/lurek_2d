//! Packed generational entity-id helpers used by the ECS runtime.

/// Utility for packing and unpacking entity IDs.
///
/// Layout: upper 8 bits = generation, lower 24 bits = slot.
pub struct GenerationalId;

impl GenerationalId {
    /// Packs `slot` and `generation` into one `u32` ID.
    pub fn pack(slot: u32, generation: u8) -> u32 {
        ((generation as u32) << 24) | (slot & 0x00FF_FFFF)
    }

    /// Extracts the slot index from a packed ID.
    pub fn unpack_slot(id: u32) -> u32 {
        id & 0x00FF_FFFF
    }

    /// Extracts the generation counter from a packed ID.
    pub fn unpack_gen(id: u32) -> u8 {
        (id >> 24) as u8
    }
}
