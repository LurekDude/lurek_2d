//! Mouse implementation for the `input` subsystem.
//!
//! This module is part of Lurek2D's `input` subsystem and provides the implementation
//! details for mouse-related operations and data management.
//! Key types exported from this module: `SystemCursor`, `MouseState`.
//! Primary functions: `from_name()`, `as_str()`, `new()`, `begin_frame()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.
//!
/// Standard OS cursor icon variants supported by the window backend.
///
/// # Variants
/// - `Arrow` — Arrow variant.
/// - `IBeam` — IBeam variant.
/// - `Wait` — Wait variant.
/// - `Crosshair` — Crosshair variant.
/// - `Hand` — Hand variant.
/// - `SizeNWSE` — SizeNWSE variant.
/// - `SizeNESW` — SizeNESW variant.
/// - `SizeWE` — SizeWE variant.
/// - `SizeNS` — SizeNS variant.
/// - `SizeAll` — SizeAll variant.
/// - `No` — No variant.
#[derive(Debug, Clone, Copy, PartialEq, Default)]
pub enum SystemCursor {
    /// Default arrow cursor.
    #[default]
    Arrow,
    /// Text input I-beam cursor.
    IBeam,
    /// Busy/wait cursor.
    Wait,
    /// Crosshair cursor.
    Crosshair,
    /// Hand/pointer cursor.
    Hand,
    /// Diagonal resize cursor (NW-SE).
    SizeNWSE,
    /// Diagonal resize cursor (NE-SW).
    SizeNESW,
    /// Horizontal resize cursor.
    SizeWE,
    /// Vertical resize cursor.
    SizeNS,
    /// Move/all-directions resize cursor.
    SizeAll,
    /// Not-allowed cursor.
    No,
}

impl SystemCursor {
    /// Parses a cursor name string into a `SystemCursor` variant.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Unrecognised names default to `Arrow`.
    pub fn from_name(name: &str) -> Self {
        match name {
            "arrow" => SystemCursor::Arrow,
            "ibeam" => SystemCursor::IBeam,
            "wait" => SystemCursor::Wait,
            "crosshair" => SystemCursor::Crosshair,
            "hand" => SystemCursor::Hand,
            "sizenwse" => SystemCursor::SizeNWSE,
            "sizenesw" => SystemCursor::SizeNESW,
            "sizewe" => SystemCursor::SizeWE,
            "sizens" => SystemCursor::SizeNS,
            "sizeall" => SystemCursor::SizeAll,
            "no" => SystemCursor::No,
            _ => SystemCursor::Arrow,
        }
    }

    /// Returns the lowercase string name for this cursor variant.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn as_str(&self) -> &'static str {
        match self {
            SystemCursor::Arrow => "arrow",
            SystemCursor::IBeam => "ibeam",
            SystemCursor::Wait => "wait",
            SystemCursor::Crosshair => "crosshair",
            SystemCursor::Hand => "hand",
            SystemCursor::SizeNWSE => "sizenwse",
            SystemCursor::SizeNESW => "sizenesw",
            SystemCursor::SizeWE => "sizewe",
            SystemCursor::SizeNS => "sizens",
            SystemCursor::SizeAll => "sizeall",
            SystemCursor::No => "no",
        }
    }
}

/// Tracks mouse cursor position and per-button pressed/down/released state.
///
/// # Fields
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `buttons` — `[bool; 5]`.
/// - `buttons_pressed` — `[bool; 5]`.
/// - `buttons_released` — `[bool; 5]`.
/// - `visible` — `bool`.
/// - `grabbed` — `bool`.
/// - `relative_mode` — `bool`.
/// - `scroll_x` — `f64`.
/// - `scroll_y` — `f64`.
/// - `cursor_type` — `SystemCursor`.
///
/// Supports five buttons (indices 0 = left, 1 = right, 2 = middle, 3 = back/button4, 4 = forward/button5).
pub struct MouseState {
    /// Current cursor X position in window pixels.
    pub x: f32,
    /// Current cursor Y position in window pixels.
    pub y: f32,
    /// Current held state for each button.
    pub buttons: [bool; 5],
    /// True for each button pressed this frame.
    pub buttons_pressed: [bool; 5],
    /// True for each button released this frame.
    pub buttons_released: [bool; 5],
    /// Whether the cursor is visible.
    pub visible: bool,
    /// Whether the cursor is confined to the window.
    pub grabbed: bool,
    /// Whether relative/FPS mouse mode is active.
    pub relative_mode: bool,
    /// Per-frame horizontal scroll delta.
    pub scroll_x: f64,
    /// Per-frame vertical scroll delta.
    pub scroll_y: f64,
    /// Current system cursor shape.
    pub cursor_type: SystemCursor,
    pending_position: Option<(f32, f32)>,
}

impl Default for MouseState {
    fn default() -> Self {
        Self::new()
    }
}

impl MouseState {
    /// Creates a new `MouseState` with cursor at `(0, 0)` and all buttons up.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        MouseState {
            x: 0.0,
            y: 0.0,
            buttons: [false; 5],
            buttons_pressed: [false; 5],
            buttons_released: [false; 5],
            visible: true,
            grabbed: false,
            relative_mode: false,
            scroll_x: 0.0,
            scroll_y: 0.0,
            cursor_type: SystemCursor::default(),
            pending_position: None,
        }
    }

    /// Resets per-frame transient state (pressed, released, and scroll deltas).
    ///
    /// Call once at the start of each frame, before processing input events.
    pub fn begin_frame(&mut self) {
        self.buttons_pressed = [false; 5];
        self.buttons_released = [false; 5];
        self.scroll_x = 0.0;
        self.scroll_y = 0.0;
    }

    /// Records the latest cursor position reported by the OS move event.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    pub fn update_position(&mut self, x: f32, y: f32) {
        self.x = x;
        self.y = y;
    }

    /// Requests that the backend cursor move to a new position.
    ///
    /// # Parameters
    /// - `x` — `f32`.
    /// - `y` — `f32`.
    pub fn request_position(&mut self, x: f32, y: f32) {
        self.update_position(x, y);
        self.pending_position = Some((x, y));
    }

    /// Records a button press or release event, updating the transient pressed/released flags.
    ///
    /// # Parameters
    /// - `button` — Button index: 0 = left, 1 = right, 2 = middle, 3 = back, 4 = forward.
    /// - `pressed` — `true` if the button is now down; `false` if released.
    pub fn set_button(&mut self, button: usize, pressed: bool) {
        if button < 5 {
            let was_pressed = self.buttons[button];
            self.buttons[button] = pressed;
            if pressed && !was_pressed {
                self.buttons_pressed[button] = true;
            } else if !pressed && was_pressed {
                self.buttons_released[button] = true;
            }
        }
    }

    /// Returns `true` if the button at `button` index is currently held down.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// # Parameters
    /// - `button` — Button index (0–4).
    pub fn is_down(&self, button: usize) -> bool {
        button < 5 && self.buttons[button]
    }

    /// Returns the current cursor position as `(x, y)`.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn get_position(&self) -> (f32, f32) {
        (self.x, self.y)
    }

    /// Sets cursor visibility. Replaces the current visible value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `visible` — `bool`.
    pub fn set_visible(&mut self, visible: bool) {
        self.visible = visible;
    }

    /// Returns whether the cursor is visible. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_visible(&self) -> bool {
        self.visible
    }

    /// Sets whether the cursor is confined to the window.
    ///
    /// # Parameters
    /// - `grabbed` — `bool`.
    pub fn set_grabbed(&mut self, grabbed: bool) {
        self.grabbed = grabbed;
    }

    /// Returns whether the cursor is confined to the window.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_grabbed(&self) -> bool {
        self.grabbed
    }

    /// Sets relative (FPS) mouse mode. Replaces the current relative mode value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `relative` — `bool`.
    pub fn set_relative_mode(&mut self, relative: bool) {
        self.relative_mode = relative;
    }

    /// Returns whether relative mouse mode is active.
    ///
    /// # Returns
    /// `bool`.
    pub fn get_relative_mode(&self) -> bool {
        self.relative_mode
    }

    /// Accumulates scroll delta for the current frame.
    ///
    /// # Parameters
    /// - `dx` — `f64`.
    /// - `dy` — `f64`.
    pub fn accumulate_scroll(&mut self, dx: f64, dy: f64) {
        self.scroll_x += dx;
        self.scroll_y += dy;
    }

    /// Returns the accumulated scroll delta for the current frame.
    ///
    /// # Returns
    /// `(f64, f64)`.
    pub fn get_scroll(&self) -> (f64, f64) {
        (self.scroll_x, self.scroll_y)
    }

    /// Sets the system cursor shape. Replaces the current cursor value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `cursor` — `SystemCursor`.
    pub fn set_cursor(&mut self, cursor: SystemCursor) {
        self.cursor_type = cursor;
    }

    /// Returns the current system cursor shape.
    ///
    /// # Returns
    /// `SystemCursor`.
    pub fn get_cursor(&self) -> SystemCursor {
        self.cursor_type
    }

    /// Returns and clears the next backend cursor-position request.
    ///
    /// # Parameters
    /// - `crate` — parameter.
    ///
    /// # Returns
    /// `Option<(f32, f32)>`.
    pub(crate) fn take_pending_position(&mut self) -> Option<(f32, f32)> {
        self.pending_position.take()
    }
}

/// The cursor type — either a named system icon or user-supplied pixel data.
///
/// # Variants
/// - `System` — A named OS cursor from the `SystemCursor` variants.
/// - `Custom` — A custom cursor created from RGBA pixel data.
#[derive(Debug, Clone)]
pub enum CursorKind {
    /// A named OS cursor from the `SystemCursor` variants.
    System(SystemCursor),
    /// A custom cursor created from RGBA pixel data.
    Custom {
        /// RGBA pixel data row-major.
        pixels: Vec<u8>,
        /// Cursor image width in pixels.
        width: u32,
        /// Cursor image height in pixels.
        height: u32,
        /// Hot-spot X coordinate (pixels from left).
        hotx: u32,
        /// Hot-spot Y coordinate (pixels from top).
        hoty: u32,
    },
}

/// A held cursor — either a system cursor icon or custom pixel-data cursor.
///
/// # Fields
/// - `kind` — `CursorKind`. The underlying cursor type.
#[derive(Debug, Clone)]
pub struct CursorHandle {
    /// The cursor type: system icon or custom pixel data.
    pub kind: CursorKind,
}

/// Returns whether cursor customisation is supported on this platform.
///
/// # Returns
/// `bool` — always `true` on desktop.
pub fn is_cursor_supported() -> bool {
    true
}
