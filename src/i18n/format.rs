//! Locale-aware number and date formatting helpers.

/// Return decimal and thousands separators for a locale prefix.
pub fn locale_separators(locale: &str) -> (char, char) {
    const COMMA_DECIMAL: &[&str] = &[
        "de", "fr", "es", "it", "pt", "nl", "pl", "ru", "tr", "sv", "da", "fi", "nb", "cs", "hu",
        "ro", "hr", "sk", "uk", "bg",
    ];
    let prefix = locale.split(['-', '_']).next().unwrap_or(locale);
    if COMMA_DECIMAL.contains(&prefix) {
        (',', '.')
    } else {
        ('.', ',')
    }
}
/// Format a number with explicit separators and fixed decimal places.
pub fn format_number(n: f64, decimals: usize, decimal_sep: char, thousands_sep: char) -> String {
    let factor = 10_f64.powi(decimals as i32);
    let rounded = (n * factor).round() / factor;
    let integer_part = rounded.abs().trunc() as i64;
    let frac_scaled = ((rounded.abs() - integer_part as f64) * factor).round() as u64;
    let int_str = integer_part.to_string();
    let mut int_grouped = String::new();
    for (i, ch) in int_str.chars().rev().enumerate() {
        if i > 0 && i % 3 == 0 {
            int_grouped.push(thousands_sep);
        }
        int_grouped.push(ch);
    }
    let int_grouped: String = int_grouped.chars().rev().collect();
    let sign = if n < 0.0 && !(integer_part == 0 && frac_scaled == 0) {
        "-"
    } else {
        ""
    };
    if decimals == 0 {
        format!("{}{}", sign, int_grouped)
    } else {
        format!(
            "{}{}{}{:0>width$}",
            sign,
            int_grouped,
            decimal_sep,
            frac_scaled,
            width = decimals
        )
    }
}
/// Format a Unix timestamp using locale-aware date patterns.
pub fn format_date(timestamp: i64, fmt: &str, locale: &str) -> String {
    let days_total = timestamp.div_euclid(86_400);
    let (year, month, day) = days_to_ymd(days_total);
    let prefix = locale.split(['-', '_']).next().unwrap_or(locale);
    let (month_names_long, month_names_short) = month_name_tables();
    match fmt {
        "iso" => format!("{:04}-{:02}-{:02}", year, month, day),
        "long" => {
            let mname = month_names_long[(month - 1) as usize];
            match prefix {
                "ja" | "ko" | "zh" => format!("{}年{}月{}日", year, month, day),
                "de" | "fr" | "es" | "it" | "pt" | "nl" | "pl" | "ru" | "sv" | "da" | "fi"
                | "nb" | "cs" | "hu" | "ro" | "hr" | "sk" | "uk" | "bg" => {
                    format!("{} {} {}", day, mname, year)
                }
                _ => format!("{} {}, {}", mname, day, year),
            }
        }
        _ => {
            let mname_s = month_names_short[(month - 1) as usize];
            match prefix {
                "ja" | "ko" | "zh" => format!("{}/{}/{}", year, month, day),
                "de" | "fr" | "es" | "it" | "pt" | "nl" | "pl" | "ru" | "sv" | "da" | "fi"
                | "nb" | "cs" | "hu" | "ro" | "hr" | "sk" | "uk" | "bg" => {
                    format!("{} {} {}", day, mname_s, year)
                }
                _ => format!("{} {}, {}", mname_s, day, year),
            }
        }
    }
}
/// Convert a day count since the Unix epoch to year, month, and day.
pub fn days_to_ymd(days: i64) -> (i32, u32, u32) {
    let z = days + 719_468;
    let era = (if z >= 0 { z } else { z - 146_096 }).div_euclid(146_097);
    let doe = (z - era * 146_097) as u32;
    let yoe = (doe - doe / 1_460 + doe / 36_524 - doe / 146_096) / 365;
    let y = yoe as i64 + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = if m <= 2 { y + 1 } else { y };
    (y as i32, m, d)
}
/// Return long and short English month name tables.
pub fn month_name_tables() -> ([&'static str; 12], [&'static str; 12]) {
    (
        [
            "January",
            "February",
            "March",
            "April",
            "May",
            "June",
            "July",
            "August",
            "September",
            "October",
            "November",
            "December",
        ],
        [
            "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
        ],
    )
}
