//! - Per-slot gamepad state tracking: buttons, axes, connection lifecycle, and per-frame delta sets.
//! - Vibration request queuing for delivery to the OS force-feedback driver.
//! - SDL2-style GUID-based mapping store with file and string parsing.
//! - Gilrs button/axis to SDL2 string conversion helpers.
//! - Virtual D-pad synthesis from analog stick values with configurable deadzone.
//! - Hat (D-pad) direction queries returning 8-way compass strings.

use crate::log_msg;
use crate::runtime::log_messages::{GD01, GD02, GD03};
use crate::runtime::EngineError;
use std::collections::{HashMap, HashSet};
use std::io::{BufRead, Write};

/// Pending vibration command for one gamepad, queued for delivery to the OS driver.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct GamepadVibrationRequest {
    /// Gamepad slot index, matches `GamepadState::id`.
    pub id: usize,
    /// Low-frequency (rumble) motor intensity in [0.0, 1.0].
    pub low_freq: f32,
    /// High-frequency (buzzer) motor intensity in [0.0, 1.0].
    pub high_freq: f32,
    /// Vibration duration in milliseconds.
    pub duration_ms: u32,
}

/// Per-frame state for one physical gamepad slot, including buttons, axes, and connection flags.
pub struct GamepadState {
    /// Slot index assigned by gilrs.
    pub id: u32,
    /// Human-readable controller name from the OS or gilrs database.
    pub name: String,
    /// True when the physical device is connected.
    pub connected: bool,
    /// True when the OS driver reports force-feedback capability.
    pub vibration_supported: bool,
    /// SDL2-style GUID string used to look up custom mappings.
    guid: String,
    /// Current held state for each button code.
    buttons: HashMap<u32, bool>,
    /// Button codes that transitioned to pressed this frame.
    buttons_pressed: HashSet<u32>,
    /// Button codes that transitioned to released this frame.
    buttons_released: HashSet<u32>,
    /// Current axis values keyed by axis code.
    axes: HashMap<u32, f32>,
    /// True only during the frame when the device first connected.
    connected_this_frame: bool,
    /// True only during the frame when the device disconnected.
    disconnected_this_frame: bool,
}

impl GamepadState {
    /// Create a disconnected slot for `id`; all buttons/axes start at default.
    pub fn new(id: u32) -> Self {
        log_msg!(debug, GD01, "id={}", id);
        GamepadState {
            id,
            name: String::from("Unknown Controller"),
            connected: false,
            vibration_supported: false,
            guid: String::new(),
            buttons: HashMap::new(),
            buttons_pressed: HashSet::new(),
            buttons_released: HashSet::new(),
            axes: HashMap::new(),
            connected_this_frame: false,
            disconnected_this_frame: false,
        }
    }

    /// Clear per-frame delta sets; call once at the start of each game frame.
    pub fn begin_frame(&mut self) {
        self.buttons_pressed.clear();
        self.buttons_released.clear();
        self.connected_this_frame = false;
        self.disconnected_this_frame = false;
    }

    /// Record a button state change and update pressed/released delta sets.
    pub fn update_button(&mut self, button: u32, pressed: bool) {
        log_msg!(trace, GD02, "button={} pressed={}", button, pressed);
        let was_pressed = self.is_button_pressed(button);
        if !was_pressed && pressed {
            self.buttons_pressed.insert(button);
        }
        if was_pressed && !pressed {
            self.buttons_released.insert(button);
        }
        self.buttons.insert(button, pressed);
    }

    /// Return true when `button` transitioned to pressed this frame.
    pub fn was_button_pressed(&self, button: u32) -> bool {
        self.buttons_pressed.contains(&button)
    }

    /// Return true when `button` transitioned to released this frame.
    pub fn was_button_released(&self, button: u32) -> bool {
        self.buttons_released.contains(&button)
    }

    /// Record a new axis value; replaces the previous value for `axis`.
    pub fn update_axis(&mut self, axis: u32, value: f32) {
        log_msg!(trace, GD03, "axis={} value={:.3}", axis, value);
        self.axes.insert(axis, value);
    }

    /// Return true when `button` is currently held down.
    pub fn is_button_pressed(&self, button: u32) -> bool {
        *self.buttons.get(&button).unwrap_or(&false)
    }

    /// Return the current value for `axis`, or 0.0 when the axis has never been seen.
    pub fn get_axis_value(&self, axis: u32) -> f32 {
        *self.axes.get(&axis).unwrap_or(&0.0)
    }

    /// Return the OS-reported controller name.
    pub fn get_name(&self) -> &str {
        &self.name
    }

    /// Return true when the device is currently connected.
    pub fn is_connected(&self) -> bool {
        self.connected
    }

    /// Update connection state and set the per-frame connection-change flags.
    pub fn set_connected(&mut self, connected: bool) {
        if connected && !self.connected {
            self.connected_this_frame = true;
        }
        if !connected && self.connected {
            self.disconnected_this_frame = true;
        }
        self.connected = connected;
    }

    /// Return true only during the frame the device first connected.
    pub fn was_connected_this_frame(&self) -> bool {
        self.connected_this_frame
    }

    /// Return true only during the frame the device disconnected.
    pub fn was_disconnected_this_frame(&self) -> bool {
        self.disconnected_this_frame
    }

    /// Set whether the OS driver supports force feedback for this device.
    pub fn set_vibration_supported(&mut self, supported: bool) {
        self.vibration_supported = supported;
    }

    /// Return true when force feedback is supported.
    pub fn is_vibration_supported(&self) -> bool {
        self.vibration_supported
    }

    /// Return the number of distinct button codes seen on this device.
    pub fn get_button_count(&self) -> usize {
        self.buttons.len()
    }

    /// Return the number of distinct axis codes seen on this device.
    pub fn get_axis_count(&self) -> usize {
        self.axes.len()
    }

    /// Set the SDL2-style GUID string; crate-internal, called from the runtime event loop.
    pub(crate) fn set_guid(&mut self, guid: impl Into<String>) {
        self.guid = guid.into();
    }

    /// Return the SDL2-style GUID string for mapping lookup.
    pub fn get_guid(&self) -> &str {
        &self.guid
    }

    /// Return a D-pad direction string for `hat`; reads buttons 10–13 for hat 0.
    pub fn get_hat(&self, hat: u32) -> &'static str {
        if hat != 0 {
            return "c";
        }
        let up = self.is_button_pressed(10);
        let down = self.is_button_pressed(11);
        let left = self.is_button_pressed(12);
        let right = self.is_button_pressed(13);
        match (up, down, left, right) {
            (true, false, false, false) => "u",
            (true, false, false, true) => "ru",
            (false, false, false, true) => "r",
            (false, true, false, true) => "rd",
            (false, true, false, false) => "d",
            (false, true, true, false) => "ld",
            (false, false, true, false) => "l",
            (true, false, true, false) => "lu",
            _ => "c",
        }
    }
}

/// Map a gilrs `Button` variant to its SDL2-style string name used in mappings.
pub fn gilrs_button_to_string(button: gilrs::Button) -> &'static str {
    match button {
        gilrs::Button::South => "a",
        gilrs::Button::East => "b",
        gilrs::Button::West => "x",
        gilrs::Button::North => "y",
        gilrs::Button::LeftTrigger => "leftshoulder",
        gilrs::Button::RightTrigger => "rightshoulder",
        gilrs::Button::LeftTrigger2 => "leftstick",
        gilrs::Button::RightTrigger2 => "rightstick",
        gilrs::Button::Select => "back",
        gilrs::Button::Start => "start",
        gilrs::Button::Mode => "guide",
        gilrs::Button::DPadUp => "dpup",
        gilrs::Button::DPadDown => "dpdown",
        gilrs::Button::DPadLeft => "dpleft",
        gilrs::Button::DPadRight => "dpright",
        _ => "unknown",
    }
}

/// Map a gilrs `Axis` variant to its SDL2-style string name used in mappings.
pub fn gilrs_axis_to_string(axis: gilrs::Axis) -> &'static str {
    match axis {
        gilrs::Axis::LeftStickX => "leftx",
        gilrs::Axis::LeftStickY => "lefty",
        gilrs::Axis::RightStickX => "rightx",
        gilrs::Axis::RightStickY => "righty",
        gilrs::Axis::LeftZ => "triggerleft",
        gilrs::Axis::RightZ => "triggerright",
        _ => "unknown",
    }
}

/// Convert a 2D stick position to four directional booleans and an 8-way direction string.
///
/// Returns `(up, down, left, right, direction)` where `direction` is one of
/// `"u"`, `"d"`, `"l"`, `"r"`, `"lu"`, `"ru"`, `"ld"`, `"rd"`, or `"c"` (centered).
pub fn virtual_dpad(x: f32, y: f32, deadzone: f32) -> (bool, bool, bool, bool, &'static str) {
    let dz = deadzone.clamp(0.0, 1.0);
    let left = x <= -dz;
    let right = x >= dz;
    let up = y <= -dz;
    let down = y >= dz;
    let direction = match (up, down, left, right) {
        (true, false, false, false) => "u",
        (true, false, true, false) => "lu",
        (true, false, false, true) => "ru",
        (false, true, false, false) => "d",
        (false, true, true, false) => "ld",
        (false, true, false, true) => "rd",
        (false, false, true, false) => "l",
        (false, false, false, true) => "r",
        _ => "c",
    };
    (up, down, left, right, direction)
}

/// In-memory store of SDL2-style gamepad mappings keyed by device GUID.
pub struct GamepadMappings {
    /// GUID → raw SDL2 mapping string.
    map: HashMap<String, String>,
}

/// Provide a default empty mapping table.
impl Default for GamepadMappings {
    fn default() -> Self {
        Self::new()
    }
}

impl GamepadMappings {
    /// Create an empty mapping store.
    pub fn new() -> Self {
        Self {
            map: HashMap::new(),
        }
    }

    /// Insert or overwrite the mapping string for `guid`.
    pub fn set_mapping(&mut self, guid: &str, mapping: &str) {
        self.map.insert(guid.to_string(), mapping.to_string());
    }

    /// Parse SDL2 gamecontrollerdb lines from `source`; return the number of entries loaded.
    pub fn load_from_string(&mut self, source: &str) -> usize {
        let mut count = 0usize;
        for raw_line in source.lines() {
            let trimmed = raw_line.trim();
            if trimmed.is_empty() || trimmed.starts_with('#') {
                continue;
            }
            if let Some(guid) = trimmed.split(',').next() {
                self.map.insert(guid.to_string(), trimmed.to_string());
                count += 1;
            }
        }
        count
    }

    /// Return the raw mapping string for `guid`, or `None` when not present.
    pub fn get_mapping_string(&self, guid: &str) -> Option<&str> {
        self.map.get(guid).map(|s| s.as_str())
    }

    /// Load mappings from a file at `path`; return entry count or `EngineError` on I/O failure.
    pub fn load_from_file(&mut self, path: &str) -> Result<usize, EngineError> {
        let file = std::fs::File::open(path)
            .map_err(|e| EngineError::FileSystemError(format!("Cannot open {}: {}", path, e)))?;
        let reader = std::io::BufReader::new(file);
        let mut content = String::new();
        for line in reader.lines() {
            let line = line.map_err(|e| {
                EngineError::FileSystemError(format!("Read error in {}: {}", path, e))
            })?;
            content.push_str(&line);
            content.push('\n');
        }
        Ok(self.load_from_string(&content))
    }

    /// Write all stored mappings to a file at `path`; return `EngineError` on I/O failure.
    pub fn save_to_file(&self, path: &str) -> Result<(), EngineError> {
        let mut file = std::fs::File::create(path)
            .map_err(|e| EngineError::FileSystemError(format!("Cannot create {}: {}", path, e)))?;
        for mapping in self.map.values() {
            writeln!(file, "{}", mapping)
                .map_err(|e| EngineError::FileSystemError(format!("Write error: {}", e)))?;
        }
        Ok(())
    }
}
