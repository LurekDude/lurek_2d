use std::collections::HashMap;
pub fn interpolate(template: &str, vars: &HashMap<String, String>) -> String {
    let mut out = String::with_capacity(template.len() + 16);
    let mut chars = template.chars().peekable();
    while let Some(ch) = chars.next() {
        if ch == '{' {
            if chars.peek() == Some(&'{') {
                chars.next();
                out.push('{');
            } else {
                let mut key = String::new();
                let mut closed = false;
                for inner in chars.by_ref() {
                    if inner == '}' {
                        closed = true;
                        break;
                    }
                    key.push(inner);
                }
                if closed {
                    if let Some(val) = vars.get(&key) {
                        out.push_str(val);
                    } else {
                        out.push('{');
                        out.push_str(&key);
                        out.push('}');
                    }
                } else {
                    out.push('{');
                    out.push_str(&key);
                }
            }
        } else if ch == '}' && chars.peek() == Some(&'}') {
            chars.next();
            out.push('}');
        } else {
            out.push(ch);
        }
    }
    out
}
pub fn interpolate_pairs(template: &str, pairs: &[(String, String)]) -> String {
    let vars: HashMap<String, String> = pairs.iter().cloned().collect();
    interpolate(template, &vars)
}
