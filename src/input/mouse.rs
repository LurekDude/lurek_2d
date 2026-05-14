//! Mouse position, button state, scroll accumulation, cursor kind, and OS cursor handle.
//! Owns per-frame button delta arrays and the pending warp-position request.
//! Does not own window handle or winit event delivery; the runtime loop calls mutation methods.
//! Consumed by `src/lua_api/input_api.rs`.

/// OS-provided cursor shape variants available through `lurek.input.setCursor`.
#[derive(Debug, Clone, Copy, PartialEq, Default)]
pub enum SystemCursor {
    /// Standard pointer arrow (default).
    #[default]
    Arrow,
    /// Text I-beam for editable fields.
    IBeam,
    /// Spinning wait / busy indicator.
    Wait,
    /// Crosshair precision cursor.
    Crosshair,
    /// Hand pointer for clickable elements.
    Hand,
    /// Northwest–southeast resize arrows.
    SizeNWSE,
    /// Northeast–southwest resize arrows.
    SizeNESW,
    /// West–east horizontal resize arrows.
    SizeWE,
    /// North–south vertical resize arrows.
    SizeNS,
    /// Four-directional move/resize arrows.
    SizeAll,
    /// Blocked / not-allowed indicator.
    No,
}

impl SystemCursor {
    /// Parse a lower-case cursor name string and return the matching variant; unknown names fall back to `Arrow`.
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

    /// Return the lower-case name string for this variant.
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

/// Per-frame mouse state: position, button deltas, scroll, and cursor type.
pub struct MouseState {
    /// Current cursor X position in window pixels.
    pub x: f32,
    /// Current cursor Y position in window pixels.
    pub y: f32,
    /// Held state for buttons 0–4 (0 = left, 1 = right, 2 = middle).
    pub buttons: [bool; 5],
    /// True for each button index that transitioned to pressed this frame.
    pub buttons_pressed: [bool; 5],
    /// True for each button index that transitioned to released this frame.
    pub buttons_released: [bool; 5],
    /// True when the OS cursor is visible.
    pub visible: bool,
    /// True when the cursor is grabbed (confined to window).
    pub grabbed: bool,
    /// True when relative (delta) mode is active — position reports deltas, not absolute coords.
    pub relative_mode: bool,
    /// Horizontal scroll accumulator for this frame.
    pub scroll_x: f64,
    /// Vertical scroll accumulator for this frame.
    pub scroll_y: f64,
    /// Currently active system cursor shape.
    pub cursor_type: SystemCursor,
    /// Pending warp-to position requested by the game; consumed by the runtime window loop.
    pending_position: Option<(f32, f32)>,
}

/// Provide a default zeroed mouse state.
impl Default for MouseState {
    fn default() -> Self {
        Self::new()
    }
}

impl MouseState {
    /// Create a mouse state with all buttons up, cursor visible at (0, 0).
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

    /// Clear per-frame button delta arrays and scroll accumulators; call at frame start.
    pub fn begin_frame(&mut self) {
        self.buttons_pressed = [false; 5];
        self.buttons_released = [false; 5];
        self.scroll_x = 0.0;
        self.scroll_y = 0.0;
    }

    /// Update the cursor position without queuing a warp request.
    pub fn update_position(&mut self, x: f32, y: f32) {
        self.x = x;
        self.y = y;
    }

    /// Set position and queue a warp request for the OS to move the hardware cursor.
    pub fn request_position(&mut self, x: f32, y: f32) {
        self.update_position(x, y);
        self.pending_position = Some((x, y));
    }

    /// Record a button state change for `button` (0–4) and update pressed/released delta flags.
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

    /// Return true when `button` (0–4) is currently held down.
    pub fn is_down(&self, button: usize) -> bool {
        button < 5 && self.buttons[button]
    }

    /// Return the current cursor position as (x, y) in window pixels.
    pub fn get_position(&self) -> (f32, f32) {
        (self.x, self.y)
    }

    /// Show or hide the OS cursor.
    pub fn set_visible(&mut self, visible: bool) {
        self.visible = visible;
    }

    /// Return true when the OS cursor is currently visible.
    pub fn is_visible(&self) -> bool {
        self.visible
    }

    /// Confine or release the cursor from the window bounds.
    pub fn set_grabbed(&mut self, grabbed: bool) {
        self.grabbed = grabbed;
    }

    /// Return true when the cursor is currently grabbed.
    pub fn is_grabbed(&self) -> bool {
        self.grabbed
    }

    /// Enable or disable relative (delta) mouse mode.
    pub fn set_relative_mode(&mut self, relative: bool) {
        self.relative_mode = relative;
    }

    /// Return true when relative mode is active.
    pub fn get_relative_mode(&self) -> bool {
        self.relative_mode
    }

    /// Add `dx` and `dy` to the scroll accumulators for this frame.
    pub fn accumulate_scroll(&mut self, dx: f64, dy: f64) {
        self.scroll_x += dx;
        self.scroll_y += dy;
    }

    /// Return accumulated scroll amounts as (scroll_x, scroll_y) for this frame.
    pub fn get_scroll(&self) -> (f64, f64) {
        (self.scroll_x, self.scroll_y)
    }

    /// Set the active system cursor shape.
    pub fn set_cursor(&mut self, cursor: SystemCursor) {
        self.cursor_type = cursor;
    }

    /// Return the current active system cursor shape.
    pub fn get_cursor(&self) -> SystemCursor {
        self.cursor_type
    }

    /// Consume and return the pending warp-position request, or `None` when no warp is queued.
    pub(crate) fn take_pending_position(&mut self) -> Option<(f32, f32)> {
        self.pending_position.take()
    }
}

/// Describes the shape source for a cursor: either a system preset or a custom RGBA pixel buffer.
#[derive(Debug, Clone)]
pub enum CursorKind {
    /// A standard OS-provided cursor shape.
    System(SystemCursor),
    /// A custom image-based cursor with a pixel buffer and hotspot.
    Custom {
        /// Raw RGBA pixel data for the cursor image.
        pixels: Vec<u8>,
        /// Image width in pixels.
        width: u32,
        /// Image height in pixels.
        height: u32,
        /// Hotspot X offset from the top-left corner.
        hotx: u32,
        /// Hotspot Y offset from the top-left corner.
        hoty: u32,
    },
}

/// Holds a cursor description used to set the active OS cursor.
#[derive(Debug, Clone)]
pub struct CursorHandle {
    /// The cursor shape description.
    pub kind: CursorKind,
}

/// Return true; custom cursor images are supported on the desktop target.
pub fn is_cursor_supported() -> bool {
    true
}

