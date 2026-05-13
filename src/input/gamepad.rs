use crate::log_msg;
use crate::runtime::log_messages::{GD01, GD02, GD03};
use crate::runtime::EngineError;
use std::collections::{HashMap, HashSet};
use std::io::{BufRead, Write};
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct GamepadVibrationRequest {
    pub id: usize,
    pub low_freq: f32,
    pub high_freq: f32,
    pub duration_ms: u32,
}
pub struct GamepadState {
    pub id: u32,
    pub name: String,
    pub connected: bool,
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
    pub fn begin_frame(&mut self) {
        self.buttons_pressed.clear();
        self.buttons_released.clear();
        self.connected_this_frame = false;
        self.disconnected_this_frame = false;
    }
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
    pub fn was_button_pressed(&self, button: u32) -> bool {
        self.buttons_pressed.contains(&button)
    }
    pub fn was_button_released(&self, button: u32) -> bool {
        self.buttons_released.contains(&button)
    }
    pub fn update_axis(&mut self, axis: u32, value: f32) {
        log_msg!(trace, GD03, "axis={} value={:.3}", axis, value);
        self.axes.insert(axis, value);
    }
    pub fn is_button_pressed(&self, button: u32) -> bool {
        *self.buttons.get(&button).unwrap_or(&false)
    }
    pub fn get_axis_value(&self, axis: u32) -> f32 {
        *self.axes.get(&axis).unwrap_or(&0.0)
    }
    pub fn get_name(&self) -> &str {
        &self.name
    }
    pub fn is_connected(&self) -> bool {
        self.connected
    }
    pub fn set_connected(&mut self, connected: bool) {
        if connected && !self.connected {
            self.connected_this_frame = true;
        }
        if !connected && self.connected {
            self.disconnected_this_frame = true;
        }
        self.connected = connected;
    }
    pub fn was_connected_this_frame(&self) -> bool {
        self.connected_this_frame
    }
    pub fn was_disconnected_this_frame(&self) -> bool {
        self.disconnected_this_frame
    }
    pub fn set_vibration_supported(&mut self, supported: bool) {
        self.vibration_supported = supported;
    }
    pub fn is_vibration_supported(&self) -> bool {
        self.vibration_supported
    }
    pub fn get_button_count(&self) -> usize {
        self.buttons.len()
    }
    pub fn get_axis_count(&self) -> usize {
        self.axes.len()
    }
    pub(crate) fn set_guid(&mut self, guid: impl Into<String>) {
        self.guid = guid.into();
    }
    pub fn get_guid(&self) -> &str {
        &self.guid
    }
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
pub struct GamepadMappings {
    map: HashMap<String, String>,
}
impl Default for GamepadMappings {
    fn default() -> Self {
        Self::new()
    }
}
impl GamepadMappings {
    pub fn new() -> Self {
        Self {
            map: HashMap::new(),
        }
    }
    pub fn set_mapping(&mut self, guid: &str, mapping: &str) {
        self.map.insert(guid.to_string(), mapping.to_string());
    }
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
    pub fn get_mapping_string(&self, guid: &str) -> Option<&str> {
        self.map.get(guid).map(|s| s.as_str())
    }
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
