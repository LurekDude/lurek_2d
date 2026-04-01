//! Visual error screen for displaying Lua and engine errors to the user.
//!
//! Generates `DrawCommand` sequences that render a engine-standard blue error
//! screen, including the error title, message, traceback, and instructions
//! to quit or restart.

use crate::engine::error::EngineError;
use crate::engine::resource_keys::FontKey;
use crate::graphics::renderer::{DrawCommand, DrawMode};

/// engine-standard blue error screen background color.
const ERROR_BG: [f32; 4] = [0.11, 0.22, 0.53, 1.0];
/// Highlight color for the "Error" heading.
const ERROR_TITLE_COLOR: [f32; 4] = [0.9, 0.6, 0.6, 1.0];
/// White color for the error message body.
const ERROR_TEXT_COLOR: [f32; 4] = [1.0, 1.0, 1.0, 1.0];
/// Subdued color for the help footer.
const ERROR_FOOTER_COLOR: [f32; 4] = [0.7, 0.7, 0.8, 1.0];

/// Maximum characters per line before wrapping.
const WRAP_WIDTH: usize = 80;
/// Approximate glyph width at scale 1.0 for the built-in bitmap font.
const GLYPH_W: f32 = 8.0;
/// Line height at scale 1.0 for the built-in bitmap font.
const LINE_H: f32 = 14.0;

/// Visual error screen that generates `DrawCommand` sequences for the GPU renderer.
///
/// Stores a pre-processed error title, message lines, and traceback so that
/// `draw_commands()` can emit a frame without any game assets loaded.
pub struct ErrorScreen {
    /// Bold heading (first line of the error).
    title: String,
    /// Wrapped message body lines.
    message_lines: Vec<String>,
    /// Cleaned-up traceback lines (empty if no traceback).
    traceback_lines: Vec<String>,
}

impl ErrorScreen {
    /// Creates an `ErrorScreen` from a plain error message string.
    ///
    /// # Parameters
    /// - `msg` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// The first line becomes the title; remaining lines form the body.
    /// Lines longer than `WRAP_WIDTH` are soft-wrapped.
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

    /// Creates an `ErrorScreen` from an `mlua::Error`.
    ///
    /// # Parameters
    /// - `err` — `&mlua::Error`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Extracts the error message and any embedded traceback.
    /// Provides a clear "what / where / why" structure.
    pub fn from_lua_error(err: &mlua::Error) -> Self {
        let full = format_lua_error(err);
        let (msg_part, tb_part) = split_traceback(&full);
        let cleaned_msg = replace_string_markers(&msg_part);

        // Try to extract "file:line: actual error" into a more readable format.
        let (title, body) = if let Some(colon2) = find_second_colon(&cleaned_msg) {
            let location = cleaned_msg[..colon2].trim();
            let description = cleaned_msg[colon2 + 1..].trim();
            (
                format!("Lua Error  —  {}", location),
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

    /// Creates an `ErrorScreen` from an `EngineError`.
    ///
    /// # Parameters
    /// - `err` — `&EngineError`.
    ///
    /// # Returns
    /// `Self`.
    pub fn from_engine_error(err: &EngineError) -> Self {
        Self::from_error(&err.to_string())
    }

    /// Generates a sequence of `DrawCommand` values that render the error screen.
    ///
    /// # Parameters
    /// - `screen_w` — `u32`.
    /// - `screen_h` — `u32`.
    /// - `heading_font` — `Option<FontKey>`.
    /// - `body_font` — `Option<FontKey>`.
    ///
    /// # Returns
    /// `Vec<DrawCommand>`.
    ///
    /// When `heading_font` and `body_font` are `Some`, uses TTF `PrintFont` commands
    /// for crisp text. Falls back to the built-in bitmap `Print` when `None`.
    pub fn draw_commands(
        &self,
        screen_w: u32,
        screen_h: u32,
        heading_font: Option<FontKey>,
        body_font: Option<FontKey>,
    ) -> Vec<DrawCommand> {
        let mut cmds = Vec::new();
        let margin_x = 40.0_f32;
        let mut y = 40.0_f32;

        // Blue background fill
        cmds.push(DrawCommand::SetColor(
            ERROR_BG[0],
            ERROR_BG[1],
            ERROR_BG[2],
            ERROR_BG[3],
        ));
        cmds.push(DrawCommand::Rectangle {
            mode: DrawMode::Fill,
            x: 0.0,
            y: 0.0,
            w: screen_w as f32,
            h: screen_h as f32,
        });

        // "Error" heading
        cmds.push(DrawCommand::SetColor(
            ERROR_TITLE_COLOR[0],
            ERROR_TITLE_COLOR[1],
            ERROR_TITLE_COLOR[2],
            ERROR_TITLE_COLOR[3],
        ));
        if let Some(fk) = heading_font {
            cmds.push(DrawCommand::PrintFont {
                font_key: fk,
                text: "Error".to_string(),
                x: margin_x,
                y,
                scale: 1.0,
            });
            y += 50.0;
        } else {
            cmds.push(DrawCommand::Print {
                text: "Error".to_string(),
                x: margin_x,
                y,
                scale: 3.0,
            });
            y += LINE_H * 3.0 + 10.0;
        }

        // Error title (first line)
        cmds.push(DrawCommand::SetColor(
            ERROR_TEXT_COLOR[0],
            ERROR_TEXT_COLOR[1],
            ERROR_TEXT_COLOR[2],
            ERROR_TEXT_COLOR[3],
        ));
        let body_line_h = if body_font.is_some() { 22.0 } else { LINE_H * 2.0 };
        self.push_text(&mut cmds, &self.title, margin_x, y, body_font);
        y += body_line_h + 4.0;

        // Message body
        for line in &self.message_lines {
            if !line.is_empty() {
                self.push_text(&mut cmds, line, margin_x, y, body_font);
            }
            y += body_line_h;
        }

        // Traceback
        if !self.traceback_lines.is_empty() {
            y += body_line_h * 0.5;
            cmds.push(DrawCommand::SetColor(0.8, 0.8, 0.9, 1.0));
            self.push_text(&mut cmds, "Traceback:", margin_x, y, body_font);
            y += body_line_h;
            let indent = if body_font.is_some() { 24.0 } else { GLYPH_W * 2.0 * 2.0 };
            for line in &self.traceback_lines {
                self.push_text(&mut cmds, line, margin_x + indent, y, body_font);
                y += body_line_h;
            }
        }

        // Footer instructions
        let footer = "Press Escape to quit  |  Press R to restart";
        let footer_y = screen_h as f32 - 50.0;
        cmds.push(DrawCommand::SetColor(
            ERROR_FOOTER_COLOR[0],
            ERROR_FOOTER_COLOR[1],
            ERROR_FOOTER_COLOR[2],
            ERROR_FOOTER_COLOR[3],
        ));
        self.push_text(&mut cmds, footer, margin_x, footer_y, body_font);

        cmds
    }

    /// Pushes a text draw command, choosing `PrintFont` (TTF) or `Print` (bitmap).
    fn push_text(
        &self,
        cmds: &mut Vec<DrawCommand>,
        text: &str,
        x: f32,
        y: f32,
        font_key: Option<FontKey>,
    ) {
        if let Some(fk) = font_key {
            cmds.push(DrawCommand::PrintFont {
                font_key: fk,
                text: text.to_string(),
                x,
                y,
                scale: 1.0,
            });
        } else {
            cmds.push(DrawCommand::Print {
                text: text.to_string(),
                x,
                y,
                scale: 2.0,
            });
        }
    }
}

/// Wraps a text string at word boundaries to fit within `max_chars` columns.
///
/// # Parameters
/// - `text` — `&str`.
/// - `max_chars` — `usize`.
///
/// # Returns
/// `Vec<String>`.
///
/// Returns one `String` per output line. Empty input produces an empty `Vec`.
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
                    // Force-break very long words.
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

/// Cleans up a Lua traceback string for display.
///
/// # Parameters
/// - `traceback` — `&str`.
///
/// # Returns
/// `Vec<String>`.
///
/// - Removes `[string "..."]` wrappers, showing just `filename:line`.
/// - Strips the "stack traceback:" header line.
/// - Prefixes each line with two spaces of indentation.
pub fn format_traceback(traceback: &str) -> Vec<String> {
    traceback
        .lines()
        .filter(|l| {
            let trimmed = l.trim();
            !trimmed.is_empty() && !trimmed.starts_with("stack traceback:")
        })
        .map(|l| {
            let cleaned = l.trim();
            // Remove [string "..."] markers → just "filename:line"
            let cleaned = replace_string_markers(cleaned);
            format!("  {}", cleaned)
        })
        .collect()
}

/// Formats an `mlua::Error` into a user-friendly string.
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

/// Splits a formatted error string into (message, traceback) parts.
fn split_traceback(full: &str) -> (String, String) {
    if let Some(idx) = full.find("stack traceback:") {
        let msg = full[..idx].trim_end().to_string();
        let tb = full[idx..].to_string();
        (msg, tb)
    } else {
        (full.to_string(), String::new())
    }
}

/// Finds the byte offset of the second `:` in a string like `"file.lua:40: msg"`.
/// Returns `None` if fewer than two colons exist.
fn find_second_colon(s: &str) -> Option<usize> {
    let first = s.find(':')?;
    s[first + 1..].find(':').map(|i| first + 1 + i)
}

/// Replaces `[string "X"]:line` patterns with `X:line`.
fn replace_string_markers(s: &str) -> String {
    let mut result = s.to_string();
    while let Some(start) = result.find("[string \"") {
        let after = start + 9; // length of `[string "`
        if let Some(end_quote) = result[after..].find("\"]") {
            let name = result[after..after + end_quote].to_string();
            let end = after + end_quote + 2; // skip `"]`
            result = format!("{}{}{}", &result[..start], name, &result[end..]);
        } else {
            break;
        }
    }
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_wrap_text_short_string() {
        let result = wrap_text("hello world", 80);
        assert_eq!(result, vec!["hello world"]);
    }

    #[test]
    fn test_wrap_text_long_string() {
        let input = "the quick brown fox jumps over the lazy dog and keeps running";
        let result = wrap_text(input, 30);
        for line in &result {
            assert!(line.len() <= 30, "line too long: {}", line);
        }
        let joined = result.join(" ");
        assert_eq!(joined, input);
    }

    #[test]
    fn test_wrap_text_empty() {
        let result = wrap_text("", 80);
        assert!(result.is_empty());
    }

    #[test]
    fn test_format_traceback_cleans_string_markers() {
        let input = r#"stack traceback:
	[string "main.lua"]:10: in function 'update'
	[string "main.lua"]:5: in main chunk"#;
        let result = format_traceback(input);
        assert_eq!(result.len(), 2);
        assert!(result[0].contains("main.lua:10"));
        assert!(!result[0].contains("[string"));
    }

    #[test]
    fn test_format_traceback_strips_header() {
        let input = "stack traceback:\n\t[string \"test\"]:1: in main chunk";
        let result = format_traceback(input);
        for line in &result {
            assert!(!line.contains("stack traceback:"));
        }
    }

    #[test]
    fn test_replace_string_markers() {
        let input = "[string \"main.lua\"]:10: in function 'foo'";
        let result = replace_string_markers(input);
        assert_eq!(result, "main.lua:10: in function 'foo'");
    }

    #[test]
    fn test_error_screen_from_simple_message() {
        let screen = ErrorScreen::from_error("Something went wrong");
        assert_eq!(screen.title, "Something went wrong");
        assert!(screen.traceback_lines.is_empty());
        let cmds = screen.draw_commands(800, 600, None, None);
        assert!(!cmds.is_empty());
    }

    #[test]
    fn test_error_screen_from_multiline_message() {
        let screen = ErrorScreen::from_error("Error in update\ndetail line 1\ndetail line 2");
        assert_eq!(screen.title, "Error in update");
        assert_eq!(screen.message_lines.len(), 2);
    }

    #[test]
    fn test_error_screen_from_engine_error() {
        let err = EngineError::LuaError("test error".to_string());
        let screen = ErrorScreen::from_engine_error(&err);
        assert!(screen.title.contains("Lua error"));
    }
}
