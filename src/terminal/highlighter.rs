pub struct HighlightRule {
    pub pattern: String,
    pub fg: [f32; 4],
    pub bg: Option<[f32; 4]>,
}
pub struct ColoredSpan {
    pub text: String,
    pub fg: [f32; 4],
    pub bg: Option<[f32; 4]>,
}
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
