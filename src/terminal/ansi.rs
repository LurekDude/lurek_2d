#[derive(Debug, Clone, PartialEq)]
pub struct AnsiColor {
    pub r: u8,
    pub g: u8,
    pub b: u8,
}
#[derive(Debug, Clone)]
pub struct AnsiSpan {
    pub text: String,
    pub fg: Option<AnsiColor>,
    pub bg: Option<AnsiColor>,
    pub bold: bool,
}
static PALETTE_STANDARD: &[AnsiColor] = &[
    AnsiColor { r: 0, g: 0, b: 0 },
    AnsiColor { r: 170, g: 0, b: 0 },
    AnsiColor { r: 0, g: 170, b: 0 },
    AnsiColor {
        r: 170,
        g: 85,
        b: 0,
    },
    AnsiColor { r: 0, g: 0, b: 170 },
    AnsiColor {
        r: 170,
        g: 0,
        b: 170,
    },
    AnsiColor {
        r: 0,
        g: 170,
        b: 170,
    },
    AnsiColor {
        r: 170,
        g: 170,
        b: 170,
    },
];
static PALETTE_BRIGHT: &[AnsiColor] = &[
    AnsiColor {
        r: 85,
        g: 85,
        b: 85,
    },
    AnsiColor {
        r: 255,
        g: 85,
        b: 85,
    },
    AnsiColor {
        r: 85,
        g: 255,
        b: 85,
    },
    AnsiColor {
        r: 255,
        g: 255,
        b: 85,
    },
    AnsiColor {
        r: 85,
        g: 85,
        b: 255,
    },
    AnsiColor {
        r: 255,
        g: 85,
        b: 255,
    },
    AnsiColor {
        r: 85,
        g: 255,
        b: 255,
    },
    AnsiColor {
        r: 255,
        g: 255,
        b: 255,
    },
];
pub fn strip_ansi_codes(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    let mut chars = text.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '\x1b' {
            if chars.peek() == Some(&'[') {
                chars.next();
                for ch in chars.by_ref() {
                    if ch.is_ascii_alphabetic() {
                        break;
                    }
                }
            }
        } else {
            out.push(c);
        }
    }
    out
}
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
            if !plain_buf.is_empty() {
                spans.push(AnsiSpan {
                    text: plain_buf.clone(),
                    fg: current_fg.clone(),
                    bg: current_bg.clone(),
                    bold: current_bold,
                });
                plain_buf.clear();
            }
            i += 2;
            let param_start = i;
            while i < bytes.len() && (bytes[i].is_ascii_digit() || bytes[i] == b';') {
                i += 1;
            }
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
            let ch_len = utf8_char_len(bytes[i]);
            if i + ch_len <= bytes.len() {
                if let Ok(s) = std::str::from_utf8(&bytes[i..i + ch_len]) {
                    plain_buf.push_str(s);
                }
                i += ch_len;
            } else {
                i += 1;
            }
        }
    }
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
fn apply_sgr(
    params: &str,
    fg: &mut Option<AnsiColor>,
    bg: &mut Option<AnsiColor>,
    bold: &mut bool,
) {
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
            30..=37 => *fg = Some(PALETTE_STANDARD[(code - 30) as usize].clone()),
            38 => {
                if let Some(color) = parse_extended_color(&parts, &mut idx) {
                    *fg = Some(color);
                }
            }
            39 => *fg = None,
            40..=47 => *bg = Some(PALETTE_STANDARD[(code - 40) as usize].clone()),
            48 => {
                if let Some(color) = parse_extended_color(&parts, &mut idx) {
                    *bg = Some(color);
                }
            }
            49 => *bg = None,
            90..=97 => *fg = Some(PALETTE_BRIGHT[(code - 90) as usize].clone()),
            100..=107 => *bg = Some(PALETTE_BRIGHT[(code - 100) as usize].clone()),
            _ => {}
        }
        idx += 1;
    }
}
fn parse_extended_color(parts: &[u16], idx: &mut usize) -> Option<AnsiColor> {
    let sub = parts.get(*idx + 1).copied()?;
    match sub {
        5 => {
            let n = parts.get(*idx + 2).copied()? as u8;
            *idx += 2;
            Some(color256(n))
        }
        2 => {
            let r = parts.get(*idx + 2).copied()? as u8;
            let g = parts.get(*idx + 3).copied()? as u8;
            let b = parts.get(*idx + 4).copied()? as u8;
            *idx += 4;
            Some(AnsiColor { r, g, b })
        }
        _ => None,
    }
}
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
