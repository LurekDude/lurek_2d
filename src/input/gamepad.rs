//! Gamepad implementation for the `input` subsystem.
//!
//! This module is part of Lurek2D's `input` subsystem and provides the implementation
//! details for gamepad-related operations and data management.
//! Key types exported from this module: `GamepadState`, `GamepadMappings`.
//! Primary functions: `new()`, `update_button()`, `update_axis()`, `is_button_pressed()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.
//!
use crate::log_msg;
use crate::runtime::log_messages::{GD01, GD02, GD03};
use crate::runtime::EngineError;
use std::collections::{HashMap, HashSet};
use std::io::{BufRead, Write};

/// Haptic vibration request scheduled by Lua and consumed by the app loop.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct GamepadVibrationRequest {
    /// Gamepad index used by the public Lua API.
    pub id: usize,
    /// Left/low-frequency motor intensity in `[0.0, 1.0]`.
    pub low_freq: f32,
    /// Right/high-frequency motor intensity in `[0.0, 1.0]`.
    pub high_freq: f32,
    /// Effect duration in milliseconds.
    pub duration_ms: u32,
}

/// Holds the current button and axis state for a single gamepad identified by its id.
///
/// # Fields
/// - `id` — Platform-assigned controller identifier.
/// - `name` — Human-readable controller name (e.g. "Xbox Controller").
/// - `connected` — Whether the gamepad is currently connected.
/// - `buttons` — *(private)* Map of button index to pressed state.
/// - `axes` — *(private)* Map of axis index to value in `[-1.0, 1.0]`.
pub struct GamepadState {
    /// Platform-assigned controller identifier.
    pub id: u32,
    /// Human-readable controller name.
    pub name: String,
    /// Whether this gamepad is currently connected.
    pub connected: bool,
    /// Whether this gamepad supports force-feedback vibration.
    pub vibration_supported: bool,
    guid: String,
    buttons: HashMap<u32, bool>,
    buttons_pressed: HashSet<u32>,
    buttons_released: HashSet<u32>,
    axes: HashMap<u32, f32>,
    connected_this_frame: bool,
    disconnected_this_frame: bool,
}

impl GamepadState {
    /// Creates a new, empty `GamepadState` for the gamepad with the given `id`.
    ///
    /// # Parameters
    /// - `id` — Platform gamepad identifier.
    ///
    /// # Returns
    /// A new `GamepadState` with no buttons or axes recorded yet.
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

    /// Clears per-frame gamepad transitions.
    ///
    /// Call once at the start of each frame before polling gamepad events.
    pub fn begin_frame(&mut self) {
        self.buttons_pressed.clear();
        self.buttons_released.clear();
        self.connected_this_frame = false;
        self.disconnected_this_frame = false;
    }

    /// Updates the pressed state for a specific button.
    ///
    /// # Parameters
    /// - `button` — Button index.
    /// - `pressed` — `true` if the button is now held down; `false` if released.
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

    /// Returns `true` if `button` was pressed this frame.
    pub fn was_button_pressed(&self, button: u32) -> bool {
        self.buttons_pressed.contains(&button)
    }

    /// Returns `true` if `button` was released this frame.
    pub fn was_button_released(&self, button: u32) -> bool {
        self.buttons_released.contains(&button)
    }

    /// Updates the value for a specific analog axis.
    ///
    /// # Parameters
    /// - `axis` — Axis index.
    /// - `value` — Axis value, typically in `[-1.0, 1.0]`.
    pub fn update_axis(&mut self, axis: u32, value: f32) {
        log_msg!(trace, GD03, "axis={} value={:.3}", axis, value);
        self.axes.insert(axis, value);
    }

    /// Returns `true` if the button at `button` index is currently pressed.
    ///
    /// # Parameters
    /// - `button` — Button index to query.
    ///
    /// # Returns
    /// `bool` — `true` if the button is held; `false` if not recorded or released.
    pub fn is_button_pressed(&self, button: u32) -> bool {
        *self.buttons.get(&button).unwrap_or(&false)
    }

    /// Returns the current value of the analog axis at `axis` index.
    ///
    /// # Parameters
    /// - `axis` — Axis index to query.
    ///
    /// # Returns
    /// `f32` — The axis value, or `0.0` if the axis has not been reported.
    pub fn get_axis_value(&self, axis: u32) -> f32 {
        *self.axes.get(&axis).unwrap_or(&0.0)
    }

    /// Returns the human-readable name of this gamepad.
    ///
    /// # Returns
    /// `&str`.
    pub fn get_name(&self) -> &str {
        &self.name
    }

    /// Returns whether this gamepad is currently connected.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_connected(&self) -> bool {
        self.connected
    }

    /// Updates connection state and stores this-frame transitions.
    pub fn set_connected(&mut self, connected: bool) {
        if connected && !self.connected {
            self.connected_this_frame = true;
        }
        if !connected && self.connected {
            self.disconnected_this_frame = true;
        }
        self.connected = connected;
    }

    /// Returns whether this gamepad connected during the current frame.
    pub fn was_connected_this_frame(&self) -> bool {
        self.connected_this_frame
    }

    /// Returns whether this gamepad disconnected during the current frame.
    pub fn was_disconnected_this_frame(&self) -> bool {
        self.disconnected_this_frame
    }

    /// Sets whether the gamepad supports vibration.
    pub fn set_vibration_supported(&mut self, supported: bool) {
        self.vibration_supported = supported;
    }

    /// Returns whether force-feedback vibration is supported.
    pub fn is_vibration_supported(&self) -> bool {
        self.vibration_supported
    }

    /// Returns the number of distinct buttons that have been reported.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_button_count(&self) -> usize {
        self.buttons.len()
    }

    /// Returns the number of distinct axes that have been reported.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_axis_count(&self) -> usize {
        self.axes.len()
    }

    /// Sets the platform GUID/UUID string for this gamepad.
    ///
    /// # Parameters
    /// - `crate` — parameter.
    pub(crate) fn set_guid(&mut self, guid: impl Into<String>) {
        self.guid = guid.into();
    }

    /// Returns the platform GUID/UUID string for this gamepad.
    ///
    /// # Returns
    /// `&str`.
    pub fn get_guid(&self) -> &str {
        &self.guid
    }

    /// Returns the d-pad hat direction string for the requested hat index.
    ///
    /// # Parameters
    /// - `hat` — `u32`.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn get_hat(&self, hat: u32) -> &'static str {
        // Only hat index 0 (primary D-pad) is supported; others return centered.
        if hat != 0 {
            return "c";
        }

        // Read D-pad button states (hard-coded indices match gilrs mapping).
        let up = self.is_button_pressed(10);
        let down = self.is_button_pressed(11);
        let left = self.is_button_pressed(12);
        let right = self.is_button_pressed(13);

        // 8-direction hat: u/d/l/r and diagonals. "c" = centered (no direction).
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

/// Converts a `gilrs::Button` to a engine-compatible string name.
///
/// # Parameters
/// - `button` — `gilrs::Button`.
///
/// # Returns
/// `&'static str`.
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

/// Converts a `gilrs::Axis` to a engine-compatible string name.
///
/// # Parameters
/// - `axis` — `gilrs::Axis`.
///
/// # Returns
/// `&'static str`.
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

/// Converts an analog stick vector into a virtual D-pad state.
///
/// Useful for touch controls and thumbstick-driven UI navigation where callers
/// need stable digital directions instead of analog values.
///
/// # Parameters
/// - `x` — Horizontal axis value in `[-1.0, 1.0]`.
/// - `y` — Vertical axis value in `[-1.0, 1.0]`.
/// - `deadzone` — Center dead-zone threshold in `[0.0, 1.0]`.
///
/// # Returns
/// `(up, down, left, right, direction)` where `direction` is one of:
/// `"c"`, `"u"`, `"d"`, `"l"`, `"r"`, `"lu"`, `"ru"`, `"ld"`, `"rd"`.
pub fn virtual_dpad(x: f32, y: f32, deadzone: f32) -> (bool, bool, bool, bool, &'static str) {
    let dz = deadzone.clamp(0.0, 1.0);
    let left = x <= -dz;
    let right = x >= dz;
    // Y is treated as screen-space where negative means up.
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

/// Stores SDL2 GameControllerDB-format mapping strings keyed by GUID.
///
/// Each entry is a single line in the `guid,name,mappings` format used by
/// SDL's game controller database. Call `load_from_file` to populate from disk
/// and `save_to_file` to persist accumulated mappings.
///
/// # Fields
/// - `map` — GUID → mapping-string dictionary.
pub struct GamepadMappings {
    map: HashMap<String, String>,
}

impl Default for GamepadMappings {
    fn default() -> Self {
        Self::new()
    }
}

impl GamepadMappings {
    /// Creates an empty `GamepadMappings` store.
    ///
    /// # Returns
    /// `GamepadMappings`.
    pub fn new() -> Self {
        Self {
            map: HashMap::new(),
        }
    }

    /// Inserts or replaces the mapping string for the given GUID.
    ///
    /// # Parameters
    /// - `guid` — SDL-format GUID string (32 hex characters).
    /// - `mapping` — Full mapping line (`guid,name,mappings`).
    pub fn set_mapping(&mut self, guid: &str, mapping: &str) {
        self.map.insert(guid.to_string(), mapping.to_string());
    }

    /// Parses and inserts SDL2 GameControllerDB mappings from a plain text blob.
    ///
    /// Lines that are empty or start with `#` are skipped.
    /// Returns the number of inserted mappings.
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

    /// Returns the mapping string for `guid`, or `None` if unknown.
    ///
    /// # Parameters
    /// - `guid` — SDL-format GUID string.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn get_mapping_string(&self, guid: &str) -> Option<&str> {
        self.map.get(guid).map(|s| s.as_str())
    }

    /// Parses a plain-text GameControllerDB file and merges entries into this store.
    ///
    /// Lines that start with `#` are treated as comments and skipped.
    /// Empty lines are also skipped.  Returns the number of mappings loaded.
    ///
    /// # Parameters
    /// - `path` — File system path to the mapping database.
    ///
    /// # Returns
    /// `Result<usize, EngineError>` — count of entries loaded, or I/O error.
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

    /// Writes all stored mappings to a plain-text file, one per line.
    ///
    /// # Parameters
    /// - `path` — Destination file path.
    ///
    /// # Returns
    /// `Result<(), EngineError>`.
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
