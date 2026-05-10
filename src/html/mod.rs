//! Lightweight pure-Rust HTML/CSS layout engine for `lurek.html`.

/// CSS color parser for draw-command translation.
pub mod color;
/// DOM document arena — root type returned by `HtmlDocument::new` and `load_document`.
pub mod document;
/// DOM element node with tag, attributes, classes, inline style, text, and layout rect.
pub mod element;
/// Lenient HTML tokeniser — parses a UTF-8 string into the element arena.
pub mod parser;
/// CSS selector matcher — supports type, class, id, and descendant / child combinators.
pub mod selector;
/// CSS parser and cascade engine — parses stylesheet sources and resolves computed styles.
pub mod style;

pub use color::parse_css_color_rgba;
pub use document::{HtmlDocument, HtmlDocumentOptions, HtmlDrawCommand};
pub use element::{HtmlElement, HtmlElementId, HtmlRect};
