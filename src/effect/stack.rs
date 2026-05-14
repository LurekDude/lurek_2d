use crate::log_msg;
use crate::runtime::log_messages::{FX01, FX02};
#[derive(Debug, Clone)]
/// Stores an ordered list of effect indices together with enable flags and target size.
pub struct PostFxStack {
    /// Effect indices in application order.
    pub effects: Vec<usize>,
    /// Per-entry enable flags parallel to `effects`.
    pub enabled: Vec<bool>,
    /// Target render width for stack application.
    pub width: u32,
    /// Target render height for stack application.
    pub height: u32,
    /// Indicates whether the renderer is currently capturing into this stack.
    pub capturing: bool,
}
impl PostFxStack {
    /// Creates an empty post-effect stack for the given render size.
    pub fn new(width: u32, height: u32) -> Self {
        log_msg!(debug, FX01);
        Self {
            effects: Vec::new(),
            enabled: Vec::new(),
            width,
            height,
            capturing: false,
        }
    }
    /// Appends an enabled effect index to the end of the stack.
    pub fn add(&mut self, effect_idx: usize) {
        log_msg!(debug, FX02);
        self.effects.push(effect_idx);
        self.enabled.push(true);
    }
    /// Removes the first stack entry that references the given effect index.
    pub fn remove(&mut self, effect_idx: usize) -> bool {
        if let Some(pos) = self.effects.iter().position(|&e| e == effect_idx) {
            self.effects.remove(pos);
            self.enabled.remove(pos);
            true
        } else {
            false
        }
    }
    /// Inserts an enabled effect index at a one-based stack position.
    pub fn insert(&mut self, position: usize, effect_idx: usize) {
        let idx = (position.saturating_sub(1)).min(self.effects.len());
        self.effects.insert(idx, effect_idx);
        self.enabled.insert(idx, true);
    }
    /// Sets the enable flag for the first stack entry that references the effect index.
    pub fn set_enabled(&mut self, effect_idx: usize, is_enabled: bool) {
        if let Some(pos) = self.effects.iter().position(|&e| e == effect_idx) {
            self.enabled[pos] = is_enabled;
        }
    }
    /// Returns the enable flag for the first stack entry that references the effect index.
    pub fn is_enabled(&self, effect_idx: usize) -> bool {
        self.effects
            .iter()
            .position(|&e| e == effect_idx)
            .map(|pos| self.enabled[pos])
            .unwrap_or(false)
    }
    /// Returns the number of stack entries.
    pub fn get_effect_count(&self) -> usize {
        self.effects.len()
    }
    /// Returns the effect index at a one-based stack position.
    pub fn get_effect(&self, index: usize) -> Option<usize> {
        if index >= 1 && index <= self.effects.len() {
            Some(self.effects[index - 1])
        } else {
            None
        }
    }
    /// Returns the effect indices whose stack entries are currently enabled.
    pub fn enabled_effects(&self) -> Vec<usize> {
        self.effects
            .iter()
            .zip(self.enabled.iter())
            .filter(|(_, &en)| en)
            .map(|(&idx, _)| idx)
            .collect()
    }
    /// Updates the target render dimensions stored on the stack.
    pub fn resize(&mut self, width: u32, height: u32) {
        self.width = width;
        self.height = height;
    }
    /// Returns the target render width.
    pub fn get_width(&self) -> u32 {
        self.width
    }
    /// Returns the target render height.
    pub fn get_height(&self) -> u32 {
        self.height
    }
    /// Returns the target render dimensions as `(width, height)`.
    pub fn get_dimensions(&self) -> (u32, u32) {
        (self.width, self.height)
    }
    /// Returns the number of stack entries.
    pub fn len(&self) -> usize {
        self.effects.len()
    }
    /// Returns whether the stack has no entries.
    pub fn is_empty(&self) -> bool {
        self.effects.is_empty()
    }
    /// Removes every stack entry and enable flag.
    pub fn clear(&mut self) {
        self.effects.clear();
        self.enabled.clear();
    }
    /// Removes duplicate effect indices while preserving first occurrence order.
    pub fn dedup_indices(&mut self) -> usize {
        let mut seen = std::collections::HashSet::new();
        let before = self.effects.len();
        let mut new_effects = Vec::with_capacity(before);
        let mut new_enabled = Vec::with_capacity(before);
        for (idx, enabled) in self.effects.iter().zip(self.enabled.iter()) {
            if seen.insert(*idx) {
                new_effects.push(*idx);
                new_enabled.push(*enabled);
            }
        }
        let removed = before - new_effects.len();
        self.effects = new_effects;
        self.enabled = new_enabled;
        removed
    }
    /// Renders a debug overview of stack entries and their enabled state.
    pub fn draw_info_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(20, 20, 30, 255);
        let count = self.effects.len();
        if count == 0 {
            img.draw_label("EMPTY STACK", 10, 10, 180, 180, 190);
            return img;
        }
        let box_gap = 10u32;
        let total_gap = box_gap * (count as u32 + 1);
        let box_w = if count > 0 {
            (width.saturating_sub(total_gap)) / count as u32
        } else {
            60
        };
        let box_h = height.saturating_sub(60).min(100);
        let box_y = (height - box_h) / 2;
        for (i, &_effect_idx) in self.effects.iter().enumerate() {
            let bx = box_gap + i as u32 * (box_w + box_gap);
            let enabled = self.enabled.get(i).copied().unwrap_or(false);
            let (r, g, b) = if enabled {
                (80u8, 200u8, 80u8)
            } else {
                (200u8, 60u8, 60u8)
            };
            img.draw_rect(
                bx as i32,
                box_y as i32,
                box_w,
                box_h,
                r / 3,
                g / 3,
                b / 3,
                200,
            );
            img.draw_rect(bx as i32, box_y as i32, box_w, 2, r, g, b, 255);
            img.draw_rect(
                bx as i32,
                (box_y + box_h - 2) as i32,
                box_w,
                2,
                r,
                g,
                b,
                255,
            );
            if !enabled {
                img.draw_line(
                    bx as i32 + 10,
                    box_y as i32 + 10,
                    (bx + box_w) as i32 - 10,
                    (box_y + box_h) as i32 - 10,
                    200,
                    60,
                    60,
                    255,
                );
                img.draw_line(
                    (bx + box_w) as i32 - 10,
                    box_y as i32 + 10,
                    bx as i32 + 10,
                    (box_y + box_h) as i32 - 10,
                    200,
                    60,
                    60,
                    255,
                );
            }
            let label = format!("FX{}", i);
            img.draw_label(&label, bx as i32 + 4, box_y as i32 + 4, r, g, b);
        }
        img
    }
    /// Renders a labeled debug panel for stack management operations.
    pub fn draw_stack_management_to_image(
        &self,
        width: u32,
        height: u32,
        labels: &[&str],
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(20, 18, 28, 255);
        img.draw_label("STACK OPS", (width / 2 - 30) as i32, 4, 200, 180, 255);
        for i in 0..self.effects.len() {
            let y = 24 + i as i32 * 22;
            let enabled = self.enabled.get(i).copied().unwrap_or(false);
            let (cr, cg, cb) = if enabled {
                (80u8, 200u8, 80u8)
            } else {
                (200u8, 80u8, 80u8)
            };
            img.draw_rect(
                10,
                y,
                (width - 20).min(300),
                18,
                cr / 5,
                cg / 5,
                cb / 5,
                255,
            );
            let label = labels.get(i).copied().unwrap_or("FX");
            let text = format!("{} - {}", label, if enabled { "ON" } else { "OFF" });
            img.draw_label(&text, 14, y + 4, cr, cg, cb);
        }
        img
    }
    /// Renders a tiled debug catalog for effect labels and representative colors.
    pub fn draw_effect_catalog_to_image(
        entries: &[(&str, (u8, u8, u8))],
        width: u32,
        height: u32,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(20, 18, 28, 255);
        img.draw_label("POSTFX CATALOG", (width / 2 - 40) as i32, 4, 220, 180, 255);
        let cols = 4u32;
        let cell_w = width / cols;
        let rows = (entries.len() as u32).div_ceil(cols);
        let cell_h = if rows > 0 {
            (height - 20) / rows
        } else {
            height
        };
        for (i, &(label, (cr, cg, cb))) in entries.iter().enumerate() {
            let col = (i as u32) % cols;
            let row = (i as u32) / cols;
            let px = col * cell_w;
            let py = 20 + row * cell_h;
            img.draw_rect(
                (px + 2) as i32,
                (py + 2) as i32,
                cell_w - 4,
                cell_h - 4,
                cr / 5,
                cg / 5,
                cb / 5,
                200,
            );
            img.draw_label(label, (px + 4) as i32, (py + 4) as i32, cr, cg, cb);
        }
        img
    }
    /// Renders a labeled debug panel showing effect parameter names and values.
    pub fn draw_effect_parameters_to_image(
        entries: &[(&str, &[(&str, f32)])],
        width: u32,
        height: u32,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(20, 18, 28, 255);
        let title_x = width.saturating_sub(76) / 2;
        img.draw_label("POSTFX PARAMETERS", title_x as i32, 4, 200, 180, 255);
        let mut y = 24i32;
        for &(label, params) in entries {
            if y + 52 > height as i32 {
                break;
            }
            img.draw_rect(10, y, width - 20, 50, 30, 28, 42, 255);
            img.draw_label(label, 14, y + 4, 220, 180, 100);
            let mut px = 14i32;
            for &(name, val) in params {
                let text = format!("{}:{:.1}", name.to_uppercase(), val);
                img.draw_label(&text, px, y + 18, 100, 200, 100);
                px += (text.len() as i32 + 1) * 4;
            }
            y += 58;
        }
        img
    }
    /// Renders one colored debug row per effect type together with its parameter count.
    pub fn draw_effect_type_bars_to_image(
        entries: &[(&str, (u8, u8, u8), usize)],
        width: u32,
        height: u32,
    ) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(25, 25, 35, 255);
        img.draw_label(
            "POSTFX EFFECT TYPES",
            (width / 2).saturating_sub(60) as i32,
            4,
            200,
            180,
            255,
        );
        let row_h = if entries.is_empty() {
            height
        } else {
            (height - 20) / entries.len() as u32
        };
        for (i, &(label, (cr, cg, cb), param_count)) in entries.iter().enumerate() {
            let y_base = (20 + i as u32 * row_h) as i32;
            let row_h_i = row_h.saturating_sub(4);
            img.draw_rect(20, y_base, width - 40, row_h_i, cr / 3, cg / 3, cb / 3, 200);
            img.draw_rect(20, y_base, width - 40, 2, cr, cg, cb, 255);
            img.draw_label(label, 28, y_base + 4, cr, cg, cb);
            for p in 0..param_count {
                let dot_x = 40 + p as i32 * 20;
                let dot_y = y_base + row_h as i32 / 2;
                img.draw_circle(dot_x, dot_y, 5, cr, cg, cb, 255);
            }
        }
        img
    }
    /// Renders a debug catalog for a list of effect types using synthetic colors.
    pub fn draw_effect_types_to_image(
        types: &[super::PostFxEffectType],
        width: u32,
        height: u32,
    ) -> crate::image::ImageData {
        let palette: &[(u8, u8, u8)] = &[
            (180, 80, 80),
            (80, 180, 80),
            (80, 80, 180),
            (180, 180, 80),
            (180, 80, 180),
            (80, 180, 180),
            (200, 130, 60),
            (130, 60, 200),
        ];
        let entries: Vec<(&str, (u8, u8, u8), usize)> = types
            .iter()
            .enumerate()
            .map(|(i, t)| {
                let effect = super::PostFxEffect::new(*t);
                let param_count = effect.get_parameter_names().len();
                let label = t.debug_label();
                let color = palette[i % palette.len()];
                (label, color, param_count)
            })
            .collect();
        Self::draw_effect_type_bars_to_image(&entries, width, height)
    }
}
