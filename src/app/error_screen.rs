//! Fatal error presentation model and text-formatting helpers.
//! Builds display-ready message and traceback lines from Lua/engine failures and
//! emits `RenderCommand` sets for full-screen error view rendering.

use crate::render::renderer::{DrawMode, RenderCommand};
use crate::runtime::error::EngineError;
use crate::runtime::resource_keys::FontKey;
const ERROR_BG: [f32; 4] = [0.11, 0.22, 0.53, 1.0];
const ERROR_TITLE_COLOR: [f32; 4] = [0.9, 0.6, 0.6, 1.0];
const ERROR_TEXT_COLOR: [f32; 4] = [1.0, 1.0, 1.0, 1.0];
const ERROR_FOOTER_COLOR: [f32; 4] = [0.7, 0.7, 0.8, 1.0];
const WRAP_WIDTH: usize = 80;
const GLYPH_W: f32 = 8.0;
const LINE_H: f32 = 14.0;
/// Render-ready error payload shown when Lua or engine execution fails fatally.
pub struct ErrorScreen {
    /// Title line shown near the top of the screen.
    title: String,
    /// Wrapped primary error message lines.
    message_lines: Vec<String>,
    /// Optional cleaned traceback lines.
    traceback_lines: Vec<String>,
}
impl ErrorScreen {
    /// Build error screen model from plain text where first line is title and remainder is body.
    pub fn from_error(msg: &str) -> Self {
        let lines: Vec<&str> = msg.lines().collect();
        let title = lines.first().unwrap_or(&"Error").to_string();
        let body = if lines.len() > 1 {
            lines[1..].join("\n")
        } else {
            String::new()
        };
        let message_lines = wrap_text(&body, WRAP_WIDTH);
        Self {
            title,
            message_lines,
            traceback_lines: Vec::new(),
        }
    }
    /// Build error screen model from `mlua::Error`, splitting message and traceback sections.
    pub fn from_lua_error(err: &mlua::Error) -> Self {
        let full = format_lua_error(err);
        let (msg_part, tb_part) = split_traceback(&full);
        let cleaned_msg = replace_string_markers(&msg_part);
        let (title, body) = if let Some(colon2) = find_second_colon(&cleaned_msg) {
            let location = cleaned_msg[..colon2].trim();
            let description = cleaned_msg[colon2 + 1..].trim();
            (
                format!("Lua Error  â€”  {}", location),
                description.to_string(),
            )
        } else {
            ("Lua Error".to_string(), cleaned_msg.clone())
        };
        let message_lines = wrap_text(&body, WRAP_WIDTH);
        let traceback_lines = format_traceback(&tb_part);
        Self {
            title,
            message_lines,
            traceback_lines,
        }
    }
    /// Build error screen model from `EngineError` display text.
    pub fn from_engine_error(err: &EngineError) -> Self {
        Self::from_error(&err.to_string())
    }
    /// Build draw commands that render full-screen error background, text body, traceback, and footer hints.
    pub fn build_render_commands(
        &self,
        screen_w: u32,
        screen_h: u32,
        heading_font: Option<FontKey>,
        body_font: Option<FontKey>,
    ) -> Vec<RenderCommand> {
        let mut cmds = Vec::new();
        let margin_x = 40.0_f32;
        let mut y = 40.0_f32;
        cmds.push(RenderCommand::SetColor(
            ERROR_BG[0],
            ERROR_BG[1],
            ERROR_BG[2],
            ERROR_BG[3],
        ));
        cmds.push(RenderCommand::Rectangle {
            mode: DrawMode::Fill,
            x: 0.0,
            y: 0.0,
            w: screen_w as f32,
            h: screen_h as f32,
        });
        cmds.push(RenderCommand::SetColor(
            ERROR_TITLE_COLOR[0],
            ERROR_TITLE_COLOR[1],
            ERROR_TITLE_COLOR[2],
            ERROR_TITLE_COLOR[3],
        ));
        if let Some(fk) = heading_font {
            cmds.push(RenderCommand::Print {
                font_key: fk,
                text: "Error".to_string(),
                x: margin_x,
                y,
                scale: 1.0,
            });
            y += 50.0;
        } else {
            y += 50.0;
        }
        cmds.push(RenderCommand::SetColor(
            ERROR_TEXT_COLOR[0],
            ERROR_TEXT_COLOR[1],
            ERROR_TEXT_COLOR[2],
            ERROR_TEXT_COLOR[3],
        ));
        let body_line_h = if body_font.is_some() {
            22.0
        } else {
            LINE_H * 2.0
        };
        self.push_text(&mut cmds, &self.title, margin_x, y, body_font);
        y += body_line_h + 4.0;
        for line in &self.message_lines {
            if !line.is_empty() {
                self.push_text(&mut cmds, line, margin_x, y, body_font);
            }
            y += body_line_h;
        }
        if !self.traceback_lines.is_empty() {
            y += body_line_h * 0.5;
            cmds.push(RenderCommand::SetColor(0.8, 0.8, 0.9, 1.0));
            self.push_text(&mut cmds, "Traceback:", margin_x, y, body_font);
            y += body_line_h;
            let indent = if body_font.is_some() {
                24.0
            } else {
                GLYPH_W * 2.0 * 2.0
            };
            for line in &self.traceback_lines {
                self.push_text(&mut cmds, line, margin_x + indent, y, body_font);
                y += body_line_h;
            }
        }
        let footer = "Press Escape to quit  |  R to restart  |  Ctrl+C to copy error";
        let footer_y = screen_h as f32 - 50.0;
        cmds.push(RenderCommand::SetColor(
            ERROR_FOOTER_COLOR[0],
            ERROR_FOOTER_COLOR[1],
            ERROR_FOOTER_COLOR[2],
            ERROR_FOOTER_COLOR[3],
        ));
        self.push_text(&mut cmds, footer, margin_x, footer_y, body_font);
        cmds
    }
    /// Return formatted text representation used for clipboard export and logs.
    pub fn as_text(&self) -> String {
        let mut parts = vec![self.title.clone()];
        parts.extend(self.message_lines.iter().cloned());
        if !self.traceback_lines.is_empty() {
            parts.push(String::new());
            parts.push("Traceback:".to_string());
            for line in &self.traceback_lines {
                parts.push(format!("  {}", line));
            }
        }
        parts.join("\n")
    }
    /// Push one text draw command when `font_key` is available.
    fn push_text(
        &self,
        cmds: &mut Vec<RenderCommand>,
        text: &str,
        x: f32,
        y: f32,
        font_key: Option<FontKey>,
    ) {
        if let Some(fk) = font_key {
            cmds.push(RenderCommand::Print {
                font_key: fk,
                text: text.to_string(),
                x,
                y,
                scale: 1.0,
            });
        }
    }
}
/// Wrap `text` into lines not exceeding `max_chars`, preserving existing line breaks.
pub fn wrap_text(text: &str, max_chars: usize) -> Vec<String> {
    let mut result = Vec::new();
    for line in text.lines() {
        if line.len() <= max_chars {
            result.push(line.to_string());
            continue;
        }
        let mut current = String::new();
        for word in line.split_whitespace() {
            if current.is_empty() {
                if word.len() > max_chars {
                    let mut remaining = word;
                    while remaining.len() > max_chars {
                        result.push(remaining[..max_chars].to_string());
                        remaining = &remaining[max_chars..];
                    }
                    current = remaining.to_string();
                } else {
                    current = word.to_string();
                }
            } else if current.len() + 1 + word.len() > max_chars {
                result.push(current);
                current = word.to_string();
            } else {
                current.push(' ');
                current.push_str(word);
            }
        }
        if !current.is_empty() {
            result.push(current);
        }
    }
    if result.is_empty() && !text.is_empty() {
        result.push(String::new());
    }
    result
}
/// Normalize traceback block by removing boilerplate lines and replacing string markers.
pub fn format_traceback(traceback: &str) -> Vec<String> {
    traceback
        .lines()
        .filter(|l| {
            let trimmed = l.trim();
            !trimmed.is_empty() && !trimmed.starts_with("stack traceback:")
        })
        .map(|l| {
            let cleaned = l.trim();
            let cleaned = replace_string_markers(cleaned);
            format!("  {}", cleaned)
        })
        .collect()
}
/// Convert `mlua::Error` variants into user-facing text, preserving nested callback tracebacks.
fn format_lua_error(err: &mlua::Error) -> String {
    match err {
        mlua::Error::RuntimeError(msg) => msg.clone(),
        mlua::Error::SyntaxError {
            message,
            incomplete_input: _,
        } => format!("Syntax error: {}", message),
        mlua::Error::CallbackError { traceback, cause } => {
            let inner = format_lua_error(cause);
            format!("{}\nstack traceback:\n{}", inner, traceback)
        }
        other => format!("{}", other),
    }
}
/// Split combined Lua error text into message part and traceback part.
fn split_traceback(full: &str) -> (String, String) {
    if let Some(idx) = full.find("stack traceback:") {
        let msg = full[..idx].trim_end().to_string();
        let tb = full[idx..].to_string();
        (msg, tb)
    } else {
        (full.to_string(), String::new())
    }
}
/// Return byte index of the second colon in `s`, if present.
fn find_second_colon(s: &str) -> Option<usize> {
    let first = s.find(':')?;
    s[first + 1..].find(':').map(|i| first + 1 + i)
}
/// Replace Lua `[string "..."]` markers with bare script names for cleaner display.
fn replace_string_markers(s: &str) -> String {
    let mut result = s.to_string();
    while let Some(start) = result.find("[string \"") {
        let after = start + 9;
        if let Some(end_quote) = result[after..].find("\"]") {
            let name = result[after..after + end_quote].to_string();
            let end = after + end_quote + 2;
            result = format!("{}{}{}", &result[..start], name, &result[end..]);
        } else {
            break;
        }
    }
    result
}
