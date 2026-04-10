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
use crate::runtime::log_messages::{GD01, GD02, GD03};
use crate::runtime::EngineError;
use crate::log_msg;
use std::collections::HashMap;
use std::io::{BufRead, Write};

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
    guid: String,
    buttons: HashMap<u32, bool>,
    axes: HashMap<u32, f32>,
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
            connected: true,
            guid: String::new(),
            buttons: HashMap::new(),
            axes: HashMap::new(),
        }
    }

    /// Updates the pressed state for a specific button.
    ///
    /// # Parameters
    /// - `button` — Button index.
    /// - `pressed` — `true` if the button is now held down; `false` if released.
    pub fn update_button(&mut self, button: u32, pressed: bool) {
        log_msg!(trace, GD02, "button={} pressed={}", button, pressed);
        self.buttons.insert(button, pressed);
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
        let mut count = 0usize;
        for line in reader.lines() {
            let line = line.map_err(|e| {
                EngineError::FileSystemError(format!("Read error in {}: {}", path, e))
            })?;
            let trimmed = line.trim();
            if trimmed.is_empty() || trimmed.starts_with('#') {
                continue;
            }
            // Extract GUID (first comma-delimited field)
            if let Some(guid) = trimmed.split(',').next() {
                self.map.insert(guid.to_string(), trimmed.to_string());
                count += 1;
            }
        }
        Ok(count)
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
