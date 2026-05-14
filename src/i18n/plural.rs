//! Plural-form selection and locale-neutral pluralization helpers.

/// Plural categories used for translation lookup.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub enum PluralForm {
    /// Quantity is exactly zero.
    Zero,
    /// Singular form for one item.
    One,
    /// Dual form for languages that distinguish two items.
    Two,
    /// Few form for Slavic-style plural rules.
    Few,
    /// Many form for large or exceptional quantities.
    Many,
    /// Fallback plural form.
    Other,
}
/// Provide string keys and language-specific selection logic for `PluralForm`.
impl PluralForm {
    /// Return the lookup key for this form.
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
    /// Select the English plural form for a numeric value.
    pub fn english(n: f64) -> Self {
        if n == 1.0 {
            Self::One
        } else {
            Self::Other
        }
    }
    /// Select the Slavic plural form for a numeric value.
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
    /// Parse a plural-form key into a `PluralForm` value.
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
/// Select a pluralized string using English plural rules and fall back to `other` or any value.
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
/// Select a pluralized string using Slavic rules and fall back to English plural selection.
pub fn pluralize_slavic(n: u64, forms: &std::collections::HashMap<String, String>) -> String {
    let form = PluralForm::slavic(n);
    if let Some(v) = forms.get(form.key()) {
        return v.clone();
    }
    pluralize(n as f64, forms)
}
