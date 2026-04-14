//! L-system string rewriter for procedural plant and structure generation.
//!
//! An L-system applies rewriting rules to a seed string (axiom) over multiple
//! iterations, then interprets the result as turtle-graphics commands to produce
//! a list of line segments.

use std::collections::HashMap;

/// An L-system with an axiom, rewriting rules, and an iteration count.
///
/// # Fields
/// - `axiom` — `String`.
/// - `rules` — `HashMap<char, String>`.
/// - `iterations` — `u32`.
pub struct LSystem {
    /// The initial symbol string.
    pub axiom: String,
    /// Rewriting rules: symbol → replacement string.
    pub rules: HashMap<char, String>,
    /// Number of rewriting iterations to apply.
    pub iterations: u32,
}

impl LSystem {
    /// Create a new L-system.
    ///
    /// # Parameters
    /// - `axiom` — `&str`.
    /// - `rules` — `Vec<(char, &str)>`.
    /// - `iterations` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// `rules` is a list of `(symbol, replacement)` pairs.
    pub fn new(axiom: &str, rules: Vec<(char, &str)>, iterations: u32) -> Self {
        Self {
            axiom: axiom.to_string(),
            rules: rules.into_iter().map(|(c, s)| (c, s.to_string())).collect(),
            iterations,
        }
    }

    /// Create a new L-system from owned-string rule pairs.
    ///
    /// # Parameters
    /// - `axiom` — `&str`.
    /// - `rules` — `&[(char, String)]`.
    /// - `iterations` — `u32`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Convenience constructor for callers that hold `String` values (e.g. Lua bindings).
    /// `rules` is a list of `(symbol, replacement)` pairs.
    pub fn new_from_pairs(axiom: &str, rules: &[(char, String)], iterations: u32) -> Self {
        Self {
            axiom: axiom.to_string(),
            rules: rules.iter().map(|(c, s)| (*c, s.clone())).collect(),
            iterations,
        }
    }

    /// Run the rewriting rules for `self.iterations` steps and return the resulting string.
    ///
    /// # Returns
    /// `String`.
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

    /// Interpret the generated string as turtle-graphics commands and return line segments.
    ///
    /// # Parameters
    /// - `angle_deg` — `f32`.
    /// - `step` — `f32`.
    ///
    /// # Returns
    /// `Vec<(f32, f32, f32, f32)>`.
    ///
    /// The turtle starts at the origin facing up. Recognised commands:
    /// - `F` / `G` — move forward by `step`, drawing a line segment.
    /// - `f` — move forward without drawing.
    /// - `+` — turn left by `angle_deg`.
    /// - `-` — turn right by `angle_deg`.
    /// - `[` — push turtle state.
    /// - `]` — pop turtle state.
    ///
    /// Returns line segments as `(x1, y1, x2, y2)`.
    pub fn to_segments(&self, angle_deg: f32, step: f32) -> Vec<(f32, f32, f32, f32)> {
        let s = self.generate();
        let angle_rad = angle_deg.to_radians();
        let mut segments = Vec::new();

        let mut x = 0.0f32;
        let mut y = 0.0f32;
        let mut heading = -std::f32::consts::FRAC_PI_2; // facing up
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
                '+' => { heading -= angle_rad; }
                '-' => { heading += angle_rad; }
                '[' => { stack.push((x, y, heading)); }
                ']' => {
                    if let Some((sx, sy, sh)) = stack.pop() {
                        x = sx; y = sy; heading = sh;
                    }
                }
                _ => {}
            }
        }
        segments
    }
}
