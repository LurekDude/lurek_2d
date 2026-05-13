//! Audio source metadata and 3D spatial state.
//! SpatialState: position, velocity, orientation for spatial audio; AudioSource: legacy handle.

use crate::log_msg;
use crate::runtime::log_messages::AS01;

/// 3D spatial audio state: position, velocity, orientation.
#[derive(Debug, Clone, Copy)]
pub struct SpatialState {
    /// World-space position `[x, y, z]`.
    pub position: [f32; 3],
    /// World-space velocity (Doppler effect).
    pub velocity: [f32; 3],
    /// Forward + up direction vectors `[fx, fy, fz, ux, uy, uz]`.
    pub orientation: [f32; 6],
}

impl Default for SpatialState {
    fn default() -> Self {
        SpatialState {
            position: [0.0, 0.0, 0.0],
            velocity: [0.0, 0.0, 0.0],
            orientation: [0.0, 0.0, -1.0, 0.0, 1.0, 0.0],
        }
    }
}

/// Legacy audio source handle (superseded by Mixer SlotMap).
pub struct AudioSource {
    /// Numeric ID (legacy, unused).
    pub id: usize,
    /// File path relative to game directory.
    pub file_path: String,
    /// Playback volume (default 1.0).
    pub volume: f32,
    /// Loop on completion.
    pub looping: bool,
}

impl AudioSource {
    /// Create new source with default volume (1.0) and no looping.
    pub fn new(id: usize, file_path: &str) -> Self {
        log_msg!(debug, AS01, "{}", file_path);
        AudioSource {
            id,
            file_path: file_path.to_string(),
            volume: 1.0,
            looping: false,
        }
    }
}

