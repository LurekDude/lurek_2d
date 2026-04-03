//! Keyboard implementation for the `input` subsystem.
//!
//! This module is part of Luna2D's `input` subsystem and provides the implementation
//! details for keyboard-related operations and data management.
//! Key types exported from this module: `KeyboardState`.
//! Primary functions: `new()`, `begin_frame()`, `press_scancode()`, `release_scancode()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.
//!
use std::collections::HashSet;

/// Tracks which keyboard keys are currently down, just pressed, or just released.
///
/// Also tracks physical scancodes, key repeat, and text input state.
///
/// # Fields
/// - `keys_down` — `HashSet<String>`.
/// - `keys_pressed` — `Vec<String>`.
/// - `keys_released` — `Vec<String>`.
/// - `scancodes_down` — `HashSet<String>`.
/// - `scancodes_pressed` — `Vec<String>`.
/// - `scancodes_released` — `Vec<String>`.
/// - `key_repeat_enabled` — `bool`.
/// - `text_input_enabled` — `bool`.
/// - `text_input_buffer` — `Vec<String>`.
pub struct KeyboardState {
    keys_down: HashSet<String>,
    keys_pressed: Vec<String>,
    keys_released: Vec<String>,
    /// Physically-pressed scancodes (layout-independent).
    scancodes_down: HashSet<String>,
    /// Per-frame scancode press events.
    scancodes_pressed: Vec<String>,
    /// Per-frame scancode release events.
    scancodes_released: Vec<String>,
    /// Whether key repeat events are delivered to Lua callbacks.
    key_repeat_enabled: bool,
    /// Whether text input (IME) events are delivered to Lua callbacks.
    text_input_enabled: bool,
    /// Per-frame text input strings from IME commit events.
    text_input_buffer: Vec<String>,
}

impl Default for KeyboardState {
    fn default() -> Self {
        Self::new()
    }
}

impl KeyboardState {
    /// Creates a new, empty `KeyboardState` with no keys recorded.
    ///
    /// # Returns
    /// A new `KeyboardState`.
    pub fn new() -> Self {
        KeyboardState {
            keys_down: HashSet::new(),
            keys_pressed: Vec::new(),
            keys_released: Vec::new(),
            scancodes_down: HashSet::new(),
            scancodes_pressed: Vec::new(),
            scancodes_released: Vec::new(),
            key_repeat_enabled: false,
            text_input_enabled: false,
            text_input_buffer: Vec::new(),
        }
    }

    /// Clears per-frame transient state (pressed, released, scancode, and text input lists).
    ///
    /// Call once at the start of each frame, before processing input events.
    pub fn begin_frame(&mut self) {
        self.keys_pressed.clear();
        self.keys_released.clear();
        self.scancodes_pressed.clear();
        self.scancodes_released.clear();
        self.text_input_buffer.clear();
    }

    /// Records that a physical scancode is now held down.
    ///
    /// # Parameters
    /// - `crate` — parameter.
    pub(crate) fn press_scancode(&mut self, scancode: String) {
        if self.scancodes_down.insert(scancode.clone()) {
            self.scancodes_pressed.push(scancode);
        }
    }

    /// Records that a physical scancode was released.
    ///
    /// # Parameters
    /// - `crate` — parameter.
    pub(crate) fn release_scancode(&mut self, scancode: String) {
        if self.scancodes_down.remove(&scancode) {
            self.scancodes_released.push(scancode);
        }
    }

    /// Returns `true` if the given physical scancode is currently held down.
    ///
    /// # Parameters
    /// - `scancode` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_scancode_down(&self, scancode: &str) -> bool {
        self.scancodes_down.contains(scancode)
    }

    /// Enables or disables key repeat event delivery.
    ///
    /// # Parameters
    /// - `crate` — parameter.
    pub(crate) fn set_key_repeat(&mut self, enabled: bool) {
        self.key_repeat_enabled = enabled;
    }

    /// Returns `true` if key repeat event delivery is enabled.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_key_repeat(&self) -> bool {
        self.key_repeat_enabled
    }

    /// Enables or disables text input (IME) event delivery.
    ///
    /// # Parameters
    /// - `crate` — parameter.
    pub(crate) fn set_text_input(&mut self, enabled: bool) {
        self.text_input_enabled = enabled;
    }

    /// Returns `true` if text input (IME) event delivery is enabled.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_text_input(&self) -> bool {
        self.text_input_enabled
    }

    /// Pushes a committed text input string into the per-frame buffer.
    ///
    /// # Parameters
    /// - `crate` — parameter.
    pub(crate) fn push_text_input(&mut self, text: String) {
        self.text_input_buffer.push(text);
    }

    /// Returns the text input strings committed this frame.
    ///
    /// # Returns
    /// `&[String]`.
    pub fn get_text_input(&self) -> &[String] {
        &self.text_input_buffer
    }

    /// Records that `key` is now held down, adding it to the pressed list if newly down.
    ///
    /// # Parameters
    /// - `key` — Lowercase key name string, e.g. `"space"`, `"a"`, `"left"`.
    pub fn set_key_down(&mut self, key: &str) {
        if self.keys_down.insert(key.to_string()) {
            self.keys_pressed.push(key.to_string());
        }
    }

    /// Records that `key` was released, adding it to the released list if it was down.
    ///
    /// # Parameters
    /// - `key` — Lowercase key name string.
    pub fn set_key_up(&mut self, key: &str) {
        if self.keys_down.remove(key) {
            self.keys_released.push(key.to_string());
        }
    }

    /// Returns `true` if `key` is currently held down.
    ///
    /// # Parameters
    /// - `key` — Lowercase key name string.
    ///
    /// # Returns
    /// `bool` — `true` if the key is in the held-down set.
    pub fn is_down(&self, key: &str) -> bool {
        self.keys_down.contains(key)
    }

    /// Returns the list of keys that became pressed this frame.
    ///
    /// # Returns
    /// `&[String]` — Slice of key name strings pressed since the last `begin_frame`.
    pub fn get_pressed(&self) -> &[String] {
        &self.keys_pressed
    }

    /// Returns the list of keys that were released this frame.
    ///
    /// # Returns
    /// `&[String]` — Slice of key name strings released since the last `begin_frame`.
    pub fn get_released(&self) -> &[String] {
        &self.keys_released
    }

    /// Clears all keyboard state: held keys, pressed, and released lists.
    pub fn clear(&mut self) {
        self.keys_down.clear();
        self.keys_pressed.clear();
        self.keys_released.clear();
        self.scancodes_down.clear();
        self.scancodes_pressed.clear();
        self.scancodes_released.clear();
        self.text_input_buffer.clear();
    }
}

/// Resolves a logical Luna key name to the closest physical scancode string.
///
/// # Parameters
/// - `crate` — parameter.
///
/// # Returns
/// `Option<String>`.
pub(crate) fn get_scancode_from_key(key: &str) -> Option<String> {
    let normalized = key.to_ascii_lowercase();

    if normalized.len() == 1
        && normalized
            .bytes()
            .all(|byte| byte.is_ascii_lowercase() || byte.is_ascii_digit())
    {
        return Some(normalized);
    }

    match normalized.as_str() {
        "space" | "escape" | "return" | "tab" | "backspace" | "delete" | "insert" | "home"
        | "end" | "pageup" | "pagedown" | "left" | "right" | "up" | "down" | "capslock"
        | "numlock" => Some(normalized),
        "shift" => Some("lshift".to_string()),
        "ctrl" => Some("lctrl".to_string()),
        "alt" => Some("lalt".to_string()),
        "f1" | "f2" | "f3" | "f4" | "f5" | "f6" | "f7" | "f8" | "f9" | "f10" | "f11" | "f12" => {
            Some(normalized)
        }
        _ => None,
    }
}

/// Resolves a physical scancode string to the closest logical Luna key name.
///
/// # Parameters
/// - `crate` — parameter.
///
/// # Returns
/// `Option<String>`.
pub(crate) fn get_key_from_scancode(scancode: &str) -> Option<String> {
    let normalized = scancode.to_ascii_lowercase();

    if normalized.len() == 1
        && normalized
            .bytes()
            .all(|byte| byte.is_ascii_lowercase() || byte.is_ascii_digit())
    {
        return Some(normalized);
    }

    match normalized.as_str() {
        "space" | "escape" | "return" | "tab" | "backspace" | "delete" | "insert" | "home"
        | "end" | "pageup" | "pagedown" | "left" | "right" | "up" | "down" | "capslock"
        | "numlock" | "scrolllock" | "f1" | "f2" | "f3" | "f4" | "f5" | "f6" | "f7" | "f8"
        | "f9" | "f10" | "f11" | "f12" | "kp+" | "kp-" | "kp*" | "kp/" | "kp0" | "kp1" | "kp2"
        | "kp3" | "kp4" | "kp5" | "kp6" | "kp7" | "kp8" | "kp9" => Some(normalized),
        "lshift" | "rshift" => Some("shift".to_string()),
        "lctrl" | "rctrl" => Some("ctrl".to_string()),
        "lalt" | "ralt" => Some("alt".to_string()),
        _ => None,
    }
}

/// Converts a `winit 0.30` logical `Key` to the lowercase string name used by the `luna.*` API.
///
/// Returns `Some(name)` for recognised keys, `None` for keys without a mapping
/// (which the engine skips silently).
///
/// # Parameters
/// - `key` — A reference to the `winit::keyboard::Key` from a `WindowEvent::KeyboardInput`.
///
/// # Returns
/// `Option<String>` — Lowercase key name (e.g. `"space"`, `"escape"`, `"a"`) or `None`.
pub fn winit_key_to_string(key: &winit::keyboard::Key) -> Option<String> {
    use winit::keyboard::{Key, NamedKey};
    match key {
        Key::Named(NamedKey::Space) => Some("space".into()),
        Key::Named(NamedKey::Escape) => Some("escape".into()),
        Key::Named(NamedKey::Enter) => Some("return".into()),
        Key::Named(NamedKey::Tab) => Some("tab".into()),
        Key::Named(NamedKey::Backspace) => Some("backspace".into()),
        Key::Named(NamedKey::Delete) => Some("delete".into()),
        Key::Named(NamedKey::Insert) => Some("insert".into()),
        Key::Named(NamedKey::Home) => Some("home".into()),
        Key::Named(NamedKey::End) => Some("end".into()),
        Key::Named(NamedKey::PageUp) => Some("pageup".into()),
        Key::Named(NamedKey::PageDown) => Some("pagedown".into()),
        Key::Named(NamedKey::ArrowLeft) => Some("left".into()),
        Key::Named(NamedKey::ArrowRight) => Some("right".into()),
        Key::Named(NamedKey::ArrowUp) => Some("up".into()),
        Key::Named(NamedKey::ArrowDown) => Some("down".into()),
        Key::Named(NamedKey::Shift) => Some("shift".into()),
        Key::Named(NamedKey::Control) => Some("ctrl".into()),
        Key::Named(NamedKey::Alt) => Some("alt".into()),
        Key::Named(NamedKey::AltGraph) => Some("altgr".into()),
        Key::Named(NamedKey::Super) => Some("super".into()),
        Key::Named(NamedKey::CapsLock) => Some("capslock".into()),
        Key::Named(NamedKey::NumLock) => Some("numlock".into()),
        Key::Named(NamedKey::F1) => Some("f1".into()),
        Key::Named(NamedKey::F2) => Some("f2".into()),
        Key::Named(NamedKey::F3) => Some("f3".into()),
        Key::Named(NamedKey::F4) => Some("f4".into()),
        Key::Named(NamedKey::F5) => Some("f5".into()),
        Key::Named(NamedKey::F6) => Some("f6".into()),
        Key::Named(NamedKey::F7) => Some("f7".into()),
        Key::Named(NamedKey::F8) => Some("f8".into()),
        Key::Named(NamedKey::F9) => Some("f9".into()),
        Key::Named(NamedKey::F10) => Some("f10".into()),
        Key::Named(NamedKey::F11) => Some("f11".into()),
        Key::Named(NamedKey::F12) => Some("f12".into()),
        Key::Character(c) => Some(c.to_lowercase().to_string()),
        _ => None,
    }
}

/// Converts a `winit 0.30` physical `KeyCode` to a engine-compatible scancode string.
///
/// Scancodes represent physical key positions and are layout-independent.
///
/// # Parameters
/// - `code` — A `winit::keyboard::KeyCode` from the physical key field.
///
/// # Returns
/// `Option<&'static str>` — Scancode string or `None` for unmapped keys.
pub fn winit_scancode_to_string(code: winit::keyboard::KeyCode) -> Option<&'static str> {
    use winit::keyboard::KeyCode;
    match code {
        KeyCode::KeyA => Some("a"),
        KeyCode::KeyB => Some("b"),
        KeyCode::KeyC => Some("c"),
        KeyCode::KeyD => Some("d"),
        KeyCode::KeyE => Some("e"),
        KeyCode::KeyF => Some("f"),
        KeyCode::KeyG => Some("g"),
        KeyCode::KeyH => Some("h"),
        KeyCode::KeyI => Some("i"),
        KeyCode::KeyJ => Some("j"),
        KeyCode::KeyK => Some("k"),
        KeyCode::KeyL => Some("l"),
        KeyCode::KeyM => Some("m"),
        KeyCode::KeyN => Some("n"),
        KeyCode::KeyO => Some("o"),
        KeyCode::KeyP => Some("p"),
        KeyCode::KeyQ => Some("q"),
        KeyCode::KeyR => Some("r"),
        KeyCode::KeyS => Some("s"),
        KeyCode::KeyT => Some("t"),
        KeyCode::KeyU => Some("u"),
        KeyCode::KeyV => Some("v"),
        KeyCode::KeyW => Some("w"),
        KeyCode::KeyX => Some("x"),
        KeyCode::KeyY => Some("y"),
        KeyCode::KeyZ => Some("z"),
        KeyCode::Digit0 => Some("0"),
        KeyCode::Digit1 => Some("1"),
        KeyCode::Digit2 => Some("2"),
        KeyCode::Digit3 => Some("3"),
        KeyCode::Digit4 => Some("4"),
        KeyCode::Digit5 => Some("5"),
        KeyCode::Digit6 => Some("6"),
        KeyCode::Digit7 => Some("7"),
        KeyCode::Digit8 => Some("8"),
        KeyCode::Digit9 => Some("9"),
        KeyCode::F1 => Some("f1"),
        KeyCode::F2 => Some("f2"),
        KeyCode::F3 => Some("f3"),
        KeyCode::F4 => Some("f4"),
        KeyCode::F5 => Some("f5"),
        KeyCode::F6 => Some("f6"),
        KeyCode::F7 => Some("f7"),
        KeyCode::F8 => Some("f8"),
        KeyCode::F9 => Some("f9"),
        KeyCode::F10 => Some("f10"),
        KeyCode::F11 => Some("f11"),
        KeyCode::F12 => Some("f12"),
        KeyCode::ArrowUp => Some("up"),
        KeyCode::ArrowDown => Some("down"),
        KeyCode::ArrowLeft => Some("left"),
        KeyCode::ArrowRight => Some("right"),
        KeyCode::Space => Some("space"),
        KeyCode::Enter => Some("return"),
        KeyCode::Escape => Some("escape"),
        KeyCode::Tab => Some("tab"),
        KeyCode::Backspace => Some("backspace"),
        KeyCode::Delete => Some("delete"),
        KeyCode::Insert => Some("insert"),
        KeyCode::Home => Some("home"),
        KeyCode::End => Some("end"),
        KeyCode::PageUp => Some("pageup"),
        KeyCode::PageDown => Some("pagedown"),
        KeyCode::ShiftLeft => Some("lshift"),
        KeyCode::ShiftRight => Some("rshift"),
        KeyCode::ControlLeft => Some("lctrl"),
        KeyCode::ControlRight => Some("rctrl"),
        KeyCode::AltLeft => Some("lalt"),
        KeyCode::AltRight => Some("ralt"),
        KeyCode::CapsLock => Some("capslock"),
        KeyCode::NumLock => Some("numlock"),
        KeyCode::ScrollLock => Some("scrolllock"),
        KeyCode::NumpadAdd => Some("kp+"),
        KeyCode::NumpadSubtract => Some("kp-"),
        KeyCode::NumpadMultiply => Some("kp*"),
        KeyCode::NumpadDivide => Some("kp/"),
        KeyCode::Numpad0 => Some("kp0"),
        KeyCode::Numpad1 => Some("kp1"),
        KeyCode::Numpad2 => Some("kp2"),
        KeyCode::Numpad3 => Some("kp3"),
        KeyCode::Numpad4 => Some("kp4"),
        KeyCode::Numpad5 => Some("kp5"),
        KeyCode::Numpad6 => Some("kp6"),
        KeyCode::Numpad7 => Some("kp7"),
        KeyCode::Numpad8 => Some("kp8"),
        KeyCode::Numpad9 => Some("kp9"),
        _ => None,
    }
}
