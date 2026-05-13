#[derive(Debug, Clone, Copy, PartialEq, Default)]
pub enum SystemCursor {
    #[default]
    Arrow,
    IBeam,
    Wait,
    Crosshair,
    Hand,
    SizeNWSE,
    SizeNESW,
    SizeWE,
    SizeNS,
    SizeAll,
    No,
}
impl SystemCursor {
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
pub struct MouseState {
    pub x: f32,
    pub y: f32,
    pub buttons: [bool; 5],
    pub buttons_pressed: [bool; 5],
    pub buttons_released: [bool; 5],
    pub visible: bool,
    pub grabbed: bool,
    pub relative_mode: bool,
    pub scroll_x: f64,
    pub scroll_y: f64,
    pub cursor_type: SystemCursor,
    pending_position: Option<(f32, f32)>,
}
impl Default for MouseState {
    fn default() -> Self {
        Self::new()
    }
}
impl MouseState {
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
    pub fn begin_frame(&mut self) {
        self.buttons_pressed = [false; 5];
        self.buttons_released = [false; 5];
        self.scroll_x = 0.0;
        self.scroll_y = 0.0;
    }
    pub fn update_position(&mut self, x: f32, y: f32) {
        self.x = x;
        self.y = y;
    }
    pub fn request_position(&mut self, x: f32, y: f32) {
        self.update_position(x, y);
        self.pending_position = Some((x, y));
    }
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
    pub fn is_down(&self, button: usize) -> bool {
        button < 5 && self.buttons[button]
    }
    pub fn get_position(&self) -> (f32, f32) {
        (self.x, self.y)
    }
    pub fn set_visible(&mut self, visible: bool) {
        self.visible = visible;
    }
    pub fn is_visible(&self) -> bool {
        self.visible
    }
    pub fn set_grabbed(&mut self, grabbed: bool) {
        self.grabbed = grabbed;
    }
    pub fn is_grabbed(&self) -> bool {
        self.grabbed
    }
    pub fn set_relative_mode(&mut self, relative: bool) {
        self.relative_mode = relative;
    }
    pub fn get_relative_mode(&self) -> bool {
        self.relative_mode
    }
    pub fn accumulate_scroll(&mut self, dx: f64, dy: f64) {
        self.scroll_x += dx;
        self.scroll_y += dy;
    }
    pub fn get_scroll(&self) -> (f64, f64) {
        (self.scroll_x, self.scroll_y)
    }
    pub fn set_cursor(&mut self, cursor: SystemCursor) {
        self.cursor_type = cursor;
    }
    pub fn get_cursor(&self) -> SystemCursor {
        self.cursor_type
    }
    pub(crate) fn take_pending_position(&mut self) -> Option<(f32, f32)> {
        self.pending_position.take()
    }
}
#[derive(Debug, Clone)]
pub enum CursorKind {
    System(SystemCursor),
    Custom {
        pixels: Vec<u8>,
        width: u32,
        height: u32,
        hotx: u32,
        hoty: u32,
    },
}
#[derive(Debug, Clone)]
pub struct CursorHandle {
    pub kind: CursorKind,
}
pub fn is_cursor_supported() -> bool {
    true
}
