//! Audio playback device enumeration (stub layer).
//! Currently returns default device only; cross-platform device switching not yet implemented.

/// Return available playback device names.
pub fn get_playback_devices() -> Vec<String> {
    vec!["Default".to_string()]
}

/// Return the active playback device name.
pub fn get_playback_device() -> String {
    "Default".to_string()
}

/// Select playback device by name; return error if not found.
pub fn set_playback_device(name: &str) -> Result<(), crate::runtime::error::EngineError> {
    if get_playback_devices().iter().any(|d| d == name) {
        Ok(())
    } else {
        Err(crate::runtime::error::EngineError::AudioError(format!(
            "Unknown audio device: {}",
            name
        )))
    }
}

