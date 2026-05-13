pub struct GenerationalId;
impl GenerationalId {
    pub fn pack(slot: u32, generation: u8) -> u32 {
        ((generation as u32) << 24) | (slot & 0x00FF_FFFF)
    }
    pub fn unpack_slot(id: u32) -> u32 {
        id & 0x00FF_FFFF
    }
    pub fn unpack_gen(id: u32) -> u8 {
        (id >> 24) as u8
    }
}
