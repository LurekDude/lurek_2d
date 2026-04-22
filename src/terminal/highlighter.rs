//! Text highlighting algorithm for the terminal module.
//!
//! Splits text into coloured spans by matching highlight rules. This pure-Rust
//! implementation is used by `lurek.terminal.printHighlighted` and can be
//! reused by future language bindings (Python, TypeScript) without `mlua`.

/// A text highlighting rule: find `pattern` as a plain substring and apply
/// `fg`/`bg` colors.
pub struct HighlightRule {
    /// Plain substring to match (case-sensitive).
    pub pattern: String,
    /// Foreground colour as `[r, g, b, a]` in 0.0–1.0 range.
    pub fg: [f32; 4],
    /// Optional background colour as `[r, g, b, a]` in 0.0–1.0 range.
    pub bg: Option<[f32; 4]>,
}

/// A colored text span produced by the highlight algorithm.
pub struct ColoredSpan {
    /// The text content of this span.
    pub text: String,
    /// Foreground colour as `[r, g, b, a]` in 0.0–1.0 range.
    pub fg: [f32; 4],
    /// Optional background colour as `[r, g, b, a]` in 0.0–1.0 range.
    pub bg: Option<[f32; 4]>,
}

/// Splits `text` into colored spans by matching `rules` left-to-right.
///
/// Rules are checked at every position; the earliest match wins. Unmatched
/// text is emitted with `default_fg` and no background colour.
///
/// # Parameters
/// - `text` — The input text to highlight.
/// - `rules` — Ordered highlighting rules; first positional match wins.
/// - `default_fg` — Foreground colour for unmatched text.
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
