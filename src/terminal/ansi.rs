//! ANSI escape code parsing for the terminal module.
//!
//! Provides two functions:
//! - [`strip_ansi_codes`] — returns the plain text with all escape sequences removed.
//! - [`parse_ansi_spans`] — tokenises text into coloured/styled [`AnsiSpan`] records.
//!
//! Supported SGR (Select Graphic Rendition) sequences:
//! - reset (`\x1b[0m`), bold (`\x1b[1m`)
//! - standard 8 foreground/background colours (30–37 / 40–47)
//! - bright foreground/background colours (90–97 / 100–107)
//! - **256-colour foreground/background** (`\x1b[38;5;<n>m` / `\x1b[48;5;<n>m`)
//! - **24-bit true-colour foreground/background** (`\x1b[38;2;<r>;<g>;<b>m` / `\x1b[48;2;<r>;<g>;<b>m`)
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
    AnsiColor { r: 0, g: 0, b: 0 },   // 0 black
    AnsiColor { r: 170, g: 0, b: 0 }, // 1 red
    AnsiColor { r: 0, g: 170, b: 0 }, // 2 green
    AnsiColor {
        r: 170,
        g: 85,
        b: 0,
    }, // 3 yellow/brown
    AnsiColor { r: 0, g: 0, b: 170 }, // 4 blue
    AnsiColor {
        r: 170,
        g: 0,
        b: 170,
    }, // 5 magenta
    AnsiColor {
        r: 0,
        g: 170,
        b: 170,
    }, // 6 cyan
    AnsiColor {
        r: 170,
        g: 170,
        b: 170,
    }, // 7 white/light grey
];

/// Bright 8-colour ANSI palette (index 0..=7, corresponding to codes 90–97 / 100–107).
static PALETTE_BRIGHT: &[AnsiColor] = &[
    AnsiColor {
        r: 85,
        g: 85,
        b: 85,
    }, // 0 bright black (dark grey)
    AnsiColor {
        r: 255,
        g: 85,
        b: 85,
    }, // 1 bright red
    AnsiColor {
        r: 85,
        g: 255,
        b: 85,
    }, // 2 bright green
    AnsiColor {
        r: 255,
        g: 255,
        b: 85,
    }, // 3 bright yellow
    AnsiColor {
        r: 85,
        g: 85,
        b: 255,
    }, // 4 bright blue
    AnsiColor {
        r: 255,
        g: 85,
        b: 255,
    }, // 5 bright magenta
    AnsiColor {
        r: 85,
        g: 255,
        b: 255,
    }, // 6 bright cyan
    AnsiColor {
        r: 255,
        g: 255,
        b: 255,
    }, // 7 bright white
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

/// Applies one SGR parameter string (e.g. `"31"`, `"1;32"`, `"38;5;200"`, `"38;2;255;128;0"`)
/// to the current style state.
///
/// Handles:
/// - Standard 8 colours (30–37 fg, 40–47 bg)
/// - Bright 8 colours (90–97 fg, 100–107 bg)
/// - 256-colour extended (`38;5;n` fg / `48;5;n` bg)
/// - 24-bit true-colour (`38;2;r;g;b` fg / `48;2;r;g;b` bg)
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

    let parts: Vec<u16> = params
        .split(';')
        .map(|p| p.parse::<u16>().unwrap_or(0xFFFF))
        .collect();

    let mut idx = 0;
    while idx < parts.len() {
        let code = parts[idx];
        match code {
            0 => {
                *fg = None;
                *bg = None;
                *bold = false;
            }
            1 => *bold = true,
            22 => *bold = false,
            // Standard foreground 30–37
            30..=37 => *fg = Some(PALETTE_STANDARD[(code - 30) as usize].clone()),
            // Extended colour (256 or 24-bit)
            38 => {
                if let Some(color) = parse_extended_color(&parts, &mut idx) {
                    *fg = Some(color);
                }
            }
            // Default fg
            39 => *fg = None,
            // Standard background 40–47
            40..=47 => *bg = Some(PALETTE_STANDARD[(code - 40) as usize].clone()),
            // Extended colour (256 or 24-bit)
            48 => {
                if let Some(color) = parse_extended_color(&parts, &mut idx) {
                    *bg = Some(color);
                }
            }
            // Default bg
            49 => *bg = None,
            // Bright foreground 90–97
            90..=97 => *fg = Some(PALETTE_BRIGHT[(code - 90) as usize].clone()),
            // Bright background 100–107
            100..=107 => *bg = Some(PALETTE_BRIGHT[(code - 100) as usize].clone()),
            _ => {} // unsupported — silently ignore
        }
        idx += 1;
    }
}

/// Parses an extended colour sub-sequence at `parts[*idx]` (which is `38` or `48`).
///
/// Advances `*idx` past the consumed parameters. Returns `None` if malformed.
///
/// Supported forms:
/// - `38;5;<n>` — 256-colour palette index
/// - `38;2;<r>;<g>;<b>` — 24-bit true colour
fn parse_extended_color(parts: &[u16], idx: &mut usize) -> Option<AnsiColor> {
    let sub = parts.get(*idx + 1).copied()?;
    match sub {
        5 => {
            // 256-colour index
            let n = parts.get(*idx + 2).copied()? as u8;
            *idx += 2;
            Some(color256(n))
        }
        2 => {
            // 24-bit true colour
            let r = parts.get(*idx + 2).copied()? as u8;
            let g = parts.get(*idx + 3).copied()? as u8;
            let b = parts.get(*idx + 4).copied()? as u8;
            *idx += 4;
            Some(AnsiColor { r, g, b })
        }
        _ => None,
    }
}

/// Converts a 256-colour palette index to an [`AnsiColor`].
///
/// The 256-colour palette is defined as:
/// - 0–7: standard colours (same as PALETTE_STANDARD)
/// - 8–15: bright colours (same as PALETTE_BRIGHT)
/// - 16–231: 6×6×6 colour cube
/// - 232–255: greyscale ramp
pub fn color256(n: u8) -> AnsiColor {
    match n {
        0..=7 => PALETTE_STANDARD[n as usize].clone(),
        8..=15 => PALETTE_BRIGHT[(n - 8) as usize].clone(),
        16..=231 => {
            let n = n - 16;
            let b_idx = n % 6;
            let g_idx = (n / 6) % 6;
            let r_idx = n / 36;
            fn cube_val(i: u8) -> u8 {
                if i == 0 {
                    0
                } else {
                    55 + i * 40
                }
            }
            AnsiColor {
                r: cube_val(r_idx),
                g: cube_val(g_idx),
                b: cube_val(b_idx),
            }
        }
        232..=255 => {
            let v = 8 + (n - 232) * 10;
            AnsiColor { r: v, g: v, b: v }
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
