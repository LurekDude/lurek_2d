//! CLDR-inspired plural form selection.
//!
//! Provides [`PluralForm`] and [`pluralize`] to select the correct grammatical
//! form of a word or phrase based on a count value.  Supports the six CLDR
//! plural categories: `zero`, `one`, `two`, `few`, `many`, and `other`.

// ── PluralForm ────────────────────────────────────────────────────────────

/// CLDR plural category.
///
/// # Variants
/// - `Zero` — Exactly zero (some locales treat it specially).
/// - `One` — Singular.
/// - `Two` — Dual form (e.g. Arabic, Latvian).
/// - `Few` — Small number of items (Slavic languages).
/// - `Many` — Larger numbers with special grammar (Polish, Russian).
/// - `Other` — The default catch-all plural.
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
    /// Returns the canonical lowercase key string for this category.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn key(&self) -> &'static str {
        match self {
            Self::Zero  => "zero",
            Self::One   => "one",
            Self::Two   => "two",
            Self::Few   => "few",
            Self::Many  => "many",
            Self::Other => "other",
        }
    }

    /// Returns the `PluralForm` for an English-style (one/other) count.
    ///
    /// # Parameters
    /// - `n` — `f64`.
    ///
    /// # Returns
    /// `PluralForm`.
    pub fn english(n: f64) -> Self {
        if n == 1.0 { Self::One } else { Self::Other }
    }

    /// Returns the `PluralForm` for a Slavic-style (one/few/many/other) count
    /// (closest to Russian/Polish).
    ///
    /// # Parameters
    /// - `n` — `u64`.
    ///
    /// # Returns
    /// `PluralForm`.
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

    /// Parses a form key string to a `PluralForm`.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Option<PluralForm>`.
    pub fn from_key(s: &str) -> Option<Self> {
        match s {
            "zero"  => Some(Self::Zero),
            "one"   => Some(Self::One),
            "two"   => Some(Self::Two),
            "few"   => Some(Self::Few),
            "many"  => Some(Self::Many),
            "other" => Some(Self::Other),
            _ => None,
        }
    }
}

// ── pluralize ─────────────────────────────────────────────────────────────

/// Selects the correct plural string from a form map for the given count.
///
/// The `forms` map may contain any subset of `"zero"`, `"one"`, `"two"`,
/// `"few"`, `"many"`, `"other"` keys.  Resolution order:
/// 1. Exact form key for the count (using [`PluralForm::english`]).
/// 2. `"other"` fallback.
/// 3. First available key.
///
/// # Parameters
/// - `n` — `f64`.
/// - `forms` — `&std::collections::HashMap<String, String>`.
///
/// # Returns
/// `String`.
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

/// Like [`pluralize`] but accepts integer counts and uses Slavic rules.
///
/// # Parameters
/// - `n` — `u64`.
/// - `forms` — `&std::collections::HashMap<String, String>`.
///
/// # Returns
/// `String`.
pub fn pluralize_slavic(n: u64, forms: &std::collections::HashMap<String, String>) -> String {
    let form = PluralForm::slavic(n);
    if let Some(v) = forms.get(form.key()) {
        return v.clone();
    }
    pluralize(n as f64, forms)
}
