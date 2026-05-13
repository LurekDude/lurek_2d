#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum PluralForm {
    Zero,
    One,
    Two,
    Few,
    Many,
    Other,
}
impl PluralForm {
    pub fn key(&self) -> &'static str {
        match self {
            Self::Zero => "zero",
            Self::One => "one",
            Self::Two => "two",
            Self::Few => "few",
            Self::Many => "many",
            Self::Other => "other",
        }
    }
    pub fn english(n: f64) -> Self {
        if n == 1.0 {
            Self::One
        } else {
            Self::Other
        }
    }
    pub fn slavic(n: u64) -> Self {
        let abs = n % 100;
        if (11..=19).contains(&abs) {
            return Self::Many;
        }
        match n % 10 {
            1 => Self::One,
            2..=4 => Self::Few,
            _ => Self::Many,
        }
    }
    pub fn from_key(s: &str) -> Option<Self> {
        match s {
            "zero" => Some(Self::Zero),
            "one" => Some(Self::One),
            "two" => Some(Self::Two),
            "few" => Some(Self::Few),
            "many" => Some(Self::Many),
            "other" => Some(Self::Other),
            _ => None,
        }
    }
}
pub fn pluralize(n: f64, forms: &std::collections::HashMap<String, String>) -> String {
    let form = PluralForm::english(n);
    if let Some(v) = forms.get(form.key()) {
        return v.clone();
    }
    if let Some(v) = forms.get("other") {
        return v.clone();
    }
    forms.values().next().cloned().unwrap_or_default()
}
pub fn pluralize_slavic(n: u64, forms: &std::collections::HashMap<String, String>) -> String {
    let form = PluralForm::slavic(n);
    if let Some(v) = forms.get(form.key()) {
        return v.clone();
    }
    pluralize(n as f64, forms)
}
