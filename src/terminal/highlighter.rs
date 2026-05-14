//! Syntax-highlighting pass for terminal text. Owns `HighlightRule`, `ColoredSpan`,
//! and the greedy first-match `highlight_spans` function. Does not own ANSI parsing
//! or cell writing; callers map returned spans to `TCell` colors.

/// A plain-string pattern with associated foreground and optional background colors.
pub struct HighlightRule {
    /// Literal string to match in the input text.
    pub pattern: String,
    /// RGBA foreground color applied to matched text, components in 0.0–1.0.
    pub fg: [f32; 4],
    /// Optional RGBA background color; `None` leaves background unchanged.
    pub bg: Option<[f32; 4]>,
}

/// A run of text with resolved foreground and optional background colors, ready for cell writing.
pub struct ColoredSpan {
    /// Decoded text content for this span.
    pub text: String,
    /// RGBA foreground color, components in 0.0–1.0.
    pub fg: [f32; 4],
    /// Optional RGBA background color; `None` means inherit default.
    pub bg: Option<[f32; 4]>,
}

/// Split `text` into `ColoredSpan`s by applying `rules` in leftmost-first order; unmatched runs use `default_fg`.
pub fn highlight_spans(
    text: &str,
    rules: &[HighlightRule],
    default_fg: [f32; 4],
) -> Vec<ColoredSpan> {
    let mut result = Vec::new();
    let mut remaining = text;
    while !remaining.is_empty() {
        let best = rules
            .iter()
            .filter_map(|r| remaining.find(r.pattern.as_str()).map(|pos| (pos, r)))
            .min_by_key(|(pos, _)| *pos);
        match best {
            None => {
                result.push(ColoredSpan {
                    text: remaining.to_string(),
                    fg: default_fg,
                    bg: None,
                });
                break;
            }
            Some((pos, rule)) => {
                if pos > 0 {
                    let prefix = &remaining[..pos];
                    result.push(ColoredSpan {
                        text: prefix.to_string(),
                        fg: default_fg,
                        bg: None,
                    });
                }
                let end = pos + rule.pattern.len();
                let token = &remaining[pos..end];
                result.push(ColoredSpan {
                    text: token.to_string(),
                    fg: rule.fg,
                    bg: rule.bg,
                });
                remaining = &remaining[end..];
            }
        }
    }
    result
}
