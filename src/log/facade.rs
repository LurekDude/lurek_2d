use crate::runtime::log_messages;
use std::collections::BTreeMap;
pub type LogFields = BTreeMap<String, String>;
pub fn log_structured(level: ::log::Level, tag: Option<&str>, msg: &str, fields: &LogFields) {
    let t = tag.unwrap_or("Lua");
    let body = if fields.is_empty() {
        msg.to_string()
    } else {
        let kvs: Vec<String> = fields.iter().map(|(k, v)| format!("{k}={v}")).collect();
        format!("{} {{ {} }}", msg, kvs.join(", "))
    };
    match level {
        ::log::Level::Error => log::error!("[{}] {}", t, body),
        ::log::Level::Warn => log::warn!("[{}] {}", t, body),
        ::log::Level::Info => log::info!("[{}] {}", t, body),
        ::log::Level::Debug => log::debug!("[{}] {}", t, body),
        ::log::Level::Trace => log::trace!("[{}] {}", t, body),
    }
}
pub fn set_level(level: &str) {
    log_messages::set_log_level(level);
}
pub fn get_level() -> String {
    log_messages::get_log_level().to_string()
}
pub fn enabled_for(level: &str) -> bool {
    use ::log::LevelFilter;
    let filter = match level.to_lowercase().as_str() {
        "error" => LevelFilter::Error,
        "warn" | "warning" => LevelFilter::Warn,
        "info" => LevelFilter::Info,
        "debug" => LevelFilter::Debug,
        "trace" => LevelFilter::Trace,
        "off" | "none" => return false,
        _ => return false,
    };
    ::log::max_level() >= filter
}
