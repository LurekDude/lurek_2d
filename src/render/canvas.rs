use crate::log_msg;
use crate::runtime::log_messages::CV01;
#[derive(Debug, Clone)]
pub struct Canvas {
    pub width: u32,
    pub height: u32,
}
impl Canvas {
    pub fn new(width: u32, height: u32) -> Self {
        log_msg!(debug, CV01, "{}x{}", width, height);
        Self { width, height }
    }
}
