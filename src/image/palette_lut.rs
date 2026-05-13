use crate::math::Color;
use std::collections::HashMap;
pub struct PaletteLUT {
    pub from_colors: Vec<Color>,
    pub to_colors: Vec<Color>,
}
impl PaletteLUT {
    pub fn new() -> Self {
        Self {
            from_colors: Vec::new(),
            to_colors: Vec::new(),
        }
    }
    pub fn get_color_count(&self) -> usize {
        self.from_colors.len()
    }
    pub fn set_color(&mut self, index: usize, from: Color, to: Color) {
        while self.from_colors.len() <= index {
            self.from_colors.push(Color::WHITE);
            self.to_colors.push(Color::WHITE);
        }
        self.from_colors[index] = from;
        self.to_colors[index] = to;
    }
    pub fn get_from_color(&self, index: usize) -> Option<Color> {
        self.from_colors.get(index).copied()
    }
    pub fn get_to_color(&self, index: usize) -> Option<Color> {
        self.to_colors.get(index).copied()
    }
    pub fn clear(&mut self) {
        self.from_colors.clear();
        self.to_colors.clear();
    }
    pub fn cycle_to_colors(&mut self, offset: i32) {
        if self.to_colors.len() <= 1 {
            return;
        }
        let len = self.to_colors.len() as i32;
        let shift = ((offset % len) + len) % len;
        if shift == 0 {
            return;
        }
        self.to_colors.rotate_right(shift as usize);
    }
    pub fn apply(&self, img: &mut crate::image::image_data::ImageData) {
        if self.from_colors.is_empty() {
            return;
        }
        let to_rgba_key = |c: &Color| -> u32 {
            let r = (c.r * 255.0).round() as u8;
            let g = (c.g * 255.0).round() as u8;
            let b = (c.b * 255.0).round() as u8;
            let a = (c.a * 255.0).round() as u8;
            (u32::from(r) << 24) | (u32::from(g) << 16) | (u32::from(b) << 8) | u32::from(a)
        };
        let to_rgba = |c: &Color| -> [u8; 4] {
            [
                (c.r * 255.0).round() as u8,
                (c.g * 255.0).round() as u8,
                (c.b * 255.0).round() as u8,
                (c.a * 255.0).round() as u8,
            ]
        };
        let use_hash = self.from_colors.len() > 16;
        let map = if use_hash {
            let mut m = HashMap::with_capacity(self.from_colors.len());
            for (i, from) in self.from_colors.iter().enumerate() {
                m.entry(to_rgba_key(from)).or_insert(i);
            }
            Some(m)
        } else {
            None
        };
        let w = img.width();
        let h = img.height();
        for y in 0..h {
            for x in 0..w {
                if let Some((r, g, b, a)) = img.get_pixel(x, y) {
                    let index = if let Some(m) = &map {
                        let key = (u32::from(r) << 24)
                            | (u32::from(g) << 16)
                            | (u32::from(b) << 8)
                            | u32::from(a);
                        m.get(&key).copied()
                    } else {
                        let mut idx = None;
                        for (i, from) in self.from_colors.iter().enumerate() {
                            let [fr, fg, fb, fa] = to_rgba(from);
                            if r == fr && g == fg && b == fb && a == fa {
                                idx = Some(i);
                                break;
                            }
                        }
                        idx
                    };
                    if let Some(i) = index {
                        let to = &self.to_colors[i];
                        let [tr, tg, tb, ta] = to_rgba(to);
                        img.set_pixel(x, y, tr, tg, tb, ta);
                    }
                }
            }
        }
    }
}
impl Default for PaletteLUT {
    fn default() -> Self {
        Self::new()
    }
}
