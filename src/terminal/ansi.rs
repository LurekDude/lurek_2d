//! ANSI escape code parsing for the terminal module.
//!
//! Provides two functions:
//! - [`strip_ansi_codes`] — returns the plain text with all escape sequences removed.
//! - [`parse_ansi_spans`] — tokenises text into coloured/styled [`AnsiSpan`] records.
//!
//! Only the most common SGR (Select Graphic Rendition) sequences are handled:
//! reset (`\x1b[0m`), bold (`\x1b[1m`), standard 8 foreground colours
//! (`\x1b[30m`–`\x1b[37m`), bright foreground colours (`\x1b[90m`–`\x1b[97m`),
//! standard 8 background colours (`\x1b[40m`–`\x1b[47m`), and bright background
//! colours (`\x1b[100m`–`\x1b[107m`).
//!
//! Unknown or unsupported sequences are silently dropped.

// -------------------------------------------------------------------------------
// Types
// -------------------------------------------------------------------------------

/// RGBA colour in the range `[0, 255]`.
#[derive(Debug, Clone, PartialEq)]
pub struct AnsiColor {
    /// Red channel.
    pub r: u8,
    /// Green channel.
    pub g: u8,
    /// Blue channel.
    pub b: u8,
}

/// A contiguous run of characters that share the same style attributes.
///
/// Produced by [`parse_ansi_spans`].
#[derive(Debug, Clone)]
pub struct AnsiSpan {
    /// The plain-text content of this span.
    pub text: String,
    /// Foreground colour (`None` → inherit terminal default).
    pub fg: Option<AnsiColor>,
    /// Background colour (`None` → inherit terminal default).
    pub bg: Option<AnsiColor>,
    /// Bold flag.
    pub bold: bool,
}

// ── Colour palette ────────────────────────────────────────────────────────────

/// Standard 8-colour ANSI palette (index 0..=7).
static PALETTE_STANDARD: &[AnsiColor] = &[
    AnsiColor { r: 0,   g: 0,   b: 0   }, // 0 black
    AnsiColor { r: 170, g: 0,   b: 0   }, // 1 red
    AnsiColor { r: 0,   g: 170, b: 0   }, // 2 green
    AnsiColor { r: 170, g: 85,  b: 0   }, // 3 yellow/brown
    AnsiColor { r: 0,   g: 0,   b: 170 }, // 4 blue
    AnsiColor { r: 170, g: 0,   b: 170 }, // 5 magenta
    AnsiColor { r: 0,   g: 170, b: 170 }, // 6 cyan
    AnsiColor { r: 170, g: 170, b: 170 }, // 7 white/light grey
];

/// Bright 8-colour ANSI palette (index 0..=7, corresponding to codes 90–97 / 100–107).
static PALETTE_BRIGHT: &[AnsiColor] = &[
    AnsiColor { r: 85,  g: 85,  b: 85  }, // 0 bright black (dark grey)
    AnsiColor { r: 255, g: 85,  b: 85  }, // 1 bright red
    AnsiColor { r: 85,  g: 255, b: 85  }, // 2 bright green
    AnsiColor { r: 255, g: 255, b: 85  }, // 3 bright yellow
    AnsiColor { r: 85,  g: 85,  b: 255 }, // 4 bright blue
    AnsiColor { r: 255, g: 85,  b: 255 }, // 5 bright magenta
    AnsiColor { r: 85,  g: 255, b: 255 }, // 6 bright cyan
    AnsiColor { r: 255, g: 255, b: 255 }, // 7 bright white
];

// -------------------------------------------------------------------------------
// Public API
// -------------------------------------------------------------------------------

/// Removes all ANSI escape sequences from `text` and returns the plain string.
///
/// # Parameters
/// - `text` — `&str`. Input string, possibly containing ANSI escape sequences.
///
/// # Returns
/// `String` with all escape sequences stripped.
pub fn strip_ansi_codes(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    let mut chars = text.chars().peekable();

    while let Some(c) = chars.next() {
        if c == '\x1b' {
            if chars.peek() == Some(&'[') {
                // CSI sequence — consume until a letter in 0x40..=0x7E
                chars.next(); // consume '['
                for ch in chars.by_ref() {
                    if ch.is_ascii_alphabetic() {
                        break;
                    }
                }
            }
            // other escape types (ESC O, ESC P, …) — skip ESC, leave rest
        } else {
            out.push(c);
        }
    }

    out
}

/// Tokenises `text` into [`AnsiSpan`] records, each with plain text and colour/bold state.
///
/// State is accumulated across sequences; a `\x1b[0m` reset clears all attributes.
/// Text between two sequences belongs to the preceding span.
///
/// # Parameters
/// - `text` — `&str`. Input string with optional ANSI SGR escape sequences.
///
/// # Returns
/// `Vec<AnsiSpan>` — one entry per contiguous run between SGR changes.
pub fn parse_ansi_spans(text: &str) -> Vec<AnsiSpan> {
    let mut spans: Vec<AnsiSpan> = Vec::new();
    let mut current_fg: Option<AnsiColor> = None;
    let mut current_bg: Option<AnsiColor> = None;
    let mut current_bold = false;
    let mut plain_buf = String::new();

    let bytes = text.as_bytes();
    let mut i = 0;

    while i < bytes.len() {
        if bytes[i] == b'\x1b' && i + 1 < bytes.len() && bytes[i + 1] == b'[' {
            // Flush accumulated plain text before changing style
            if !plain_buf.is_empty() {
                spans.push(AnsiSpan {
                    text: plain_buf.clone(),
                    fg: current_fg.clone(),
                    bg: current_bg.clone(),
                    bold: current_bold,
                });
                plain_buf.clear();
            }

            // Consume ESC [
            i += 2;

            // Read parameter bytes (digits and ';') until terminating letter
            let param_start = i;
            while i < bytes.len() && (bytes[i].is_ascii_digit() || bytes[i] == b';') {
                i += 1;
            }
            // Skip terminator byte (should be 'm' for SGR)
            let terminator = if i < bytes.len() { bytes[i] } else { 0 };
            if i < bytes.len() {
                i += 1;
            }

            if terminator == b'm' {
                let param_str = std::str::from_utf8(&bytes[param_start..i - 1]).unwrap_or("");
                apply_sgr(
                    param_str,
                    &mut current_fg,
                    &mut current_bg,
                    &mut current_bold,
                );
            }
        } else {
            // Decode one UTF-8 character manually
            let ch_len = utf8_char_len(bytes[i]);
            if i + ch_len <= bytes.len() {
                if let Ok(s) = std::str::from_utf8(&bytes[i..i + ch_len]) {
                    plain_buf.push_str(s);
                }
                i += ch_len;
            } else {
                i += 1; // skip malformed byte
            }
        }
    }

    // Flush any trailing text
    if !plain_buf.is_empty() {
        spans.push(AnsiSpan {
            text: plain_buf,
            fg: current_fg,
            bg: current_bg,
            bold: current_bold,
        });
    }

    spans
}

// -------------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------------

/// Applies one SGR parameter string (e.g. `"31"`, `"1;32"`, `""`) to the current style.
fn apply_sgr(
    params: &str,
    fg: &mut Option<AnsiColor>,
    bg: &mut Option<AnsiColor>,
    bold: &mut bool,
) {
    // Empty string means ESC [ m — same as reset
    if params.is_empty() {
        *fg = None;
        *bg = None;
        *bold = false;
        return;
    }

    for part in params.split(';') {
        match part.parse::<u8>().unwrap_or(255) {
            0 => {
                *fg = None;
                *bg = None;
                *bold = false;
            }
            1 => *bold = true,
            22 => *bold = false,
            // Standard foreground 30–37
            n @ 30..=37 => *fg = Some(PALETTE_STANDARD[(n - 30) as usize].clone()),
            // Default fg
            39 => *fg = None,
            // Standard background 40–47
            n @ 40..=47 => *bg = Some(PALETTE_STANDARD[(n - 40) as usize].clone()),
            // Default bg
            49 => *bg = None,
            // Bright foreground 90–97
            n @ 90..=97 => *fg = Some(PALETTE_BRIGHT[(n - 90) as usize].clone()),
            // Bright background 100–107
            n @ 100..=107 => *bg = Some(PALETTE_BRIGHT[(n - 100) as usize].clone()),
            _ => {} // unsupported — silently ignore
        }
    }
}

/// Returns the byte length of the UTF-8 character starting at `byte`.
fn utf8_char_len(byte: u8) -> usize {
    if byte < 0x80 {
        1
    } else if byte < 0xE0 {
        2
    } else if byte < 0xF0 {
        3
    } else {
        4
    }
}


