//! Lindenmayer-system (L-system) string rewriting and turtle geometry for `src/procgen`.
//! Owns `LSystem`, its rewriting logic, and `to_segments` turtle interpretation.
//! Does not own rendering or world-graph construction — those live in `render.rs` and `world_graph.rs`.

use std::collections::HashMap;

/// String-rewriting L-system with production rules and a configurable iteration count.
pub struct LSystem {
    /// Initial string expanded by rewriting rules.
    pub axiom: String,
    /// Map from source character to its replacement string; unmapped characters are kept verbatim.
    pub rules: HashMap<char, String>,
    /// Number of full rewriting passes applied to the axiom.
    pub iterations: u32,
}

impl LSystem {
    /// Create an L-system from a string axiom and `(char, &str)` rule pairs.
    pub fn new(axiom: &str, rules: Vec<(char, &str)>, iterations: u32) -> Self {
        Self {
            axiom: axiom.to_string(),
            rules: rules.into_iter().map(|(c, s)| (c, s.to_string())).collect(),
            iterations,
        }
    }

    /// Create an L-system from a string axiom and `(char, String)` rule slice.
    pub fn new_from_pairs(axiom: &str, rules: &[(char, String)], iterations: u32) -> Self {
        Self {
            axiom: axiom.to_string(),
            rules: rules.iter().map(|(c, s)| (*c, s.clone())).collect(),
            iterations,
        }
    }

    /// Apply all production rules `iterations` times and return the resulting string.
    pub fn generate(&self) -> String {
        let mut current = self.axiom.clone();
        for _ in 0..self.iterations {
            let mut next = String::with_capacity(current.len() * 2);
            for ch in current.chars() {
                if let Some(replacement) = self.rules.get(&ch) {
                    next.push_str(replacement);
                } else {
                    next.push(ch);
                }
            }
            current = next;
        }
        current
    }

    /// Interpret the generated string as turtle commands and return `(x1,y1,x2,y2)` line segments.
    ///
    /// Commands: `F`/`G` = draw forward `step` units; `f` = move without drawing;
    /// `+` = turn left by `angle_deg`; `-` = turn right; `[` = push state; `]` = pop state.
    pub fn to_segments(&self, angle_deg: f32, step: f32) -> Vec<(f32, f32, f32, f32)> {
        let s = self.generate();
        let angle_rad = angle_deg.to_radians();
        let mut segments = Vec::new();
        let mut x = 0.0f32;
        let mut y = 0.0f32;
        let mut heading = -std::f32::consts::FRAC_PI_2;
        let mut stack: Vec<(f32, f32, f32)> = Vec::new();
        for ch in s.chars() {
            match ch {
                'F' | 'G' => {
                    let nx = x + heading.cos() * step;
                    let ny = y + heading.sin() * step;
                    segments.push((x, y, nx, ny));
                    x = nx;
                    y = ny;
                }
                'f' => {
                    x += heading.cos() * step;
                    y += heading.sin() * step;
                }
                '+' => {
                    heading -= angle_rad;
                }
                '-' => {
                    heading += angle_rad;
                }
                '[' => {
                    stack.push((x, y, heading));
                }
                ']' => {
                    if let Some((sx, sy, sh)) = stack.pop() {
                        x = sx;
                        y = sy;
                        heading = sh;
                    }
                }
                _ => {}
            }
        }
        segments
    }
}
    pub axiom: String,
    pub rules: HashMap<char, String>,
    pub iterations: u32,
}
impl LSystem {
    pub fn new(axiom: &str, rules: Vec<(char, &str)>, iterations: u32) -> Self {
        Self {
            axiom: axiom.to_string(),
            rules: rules.into_iter().map(|(c, s)| (c, s.to_string())).collect(),
            iterations,
        }
    }
    pub fn new_from_pairs(axiom: &str, rules: &[(char, String)], iterations: u32) -> Self {
        Self {
            axiom: axiom.to_string(),
            rules: rules.iter().map(|(c, s)| (*c, s.clone())).collect(),
            iterations,
        }
    }
    pub fn generate(&self) -> String {
        let mut current = self.axiom.clone();
        for _ in 0..self.iterations {
            let mut next = String::with_capacity(current.len() * 2);
            for ch in current.chars() {
                if let Some(replacement) = self.rules.get(&ch) {
                    next.push_str(replacement);
                } else {
                    next.push(ch);
                }
            }
            current = next;
        }
        current
    }
    pub fn to_segments(&self, angle_deg: f32, step: f32) -> Vec<(f32, f32, f32, f32)> {
        let s = self.generate();
        let angle_rad = angle_deg.to_radians();
        let mut segments = Vec::new();
        let mut x = 0.0f32;
        let mut y = 0.0f32;
        let mut heading = -std::f32::consts::FRAC_PI_2;
        let mut stack: Vec<(f32, f32, f32)> = Vec::new();
        for ch in s.chars() {
            match ch {
                'F' | 'G' => {
                    let nx = x + heading.cos() * step;
                    let ny = y + heading.sin() * step;
                    segments.push((x, y, nx, ny));
                    x = nx;
                    y = ny;
                }
                'f' => {
                    x += heading.cos() * step;
                    y += heading.sin() * step;
                }
                '+' => {
                    heading -= angle_rad;
                }
                '-' => {
                    heading += angle_rad;
                }
                '[' => {
                    stack.push((x, y, heading));
                }
                ']' => {
                    if let Some((sx, sy, sh)) = stack.pop() {
                        x = sx;
                        y = sy;
                        heading = sh;
                    }
                }
                _ => {}
            }
        }
        segments
    }
}
