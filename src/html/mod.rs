//! Lightweight pure-Rust HTML/CSS layout engine for `lurek.html`.

pub mod document;
pub mod element;
pub mod parser;
pub mod selector;
pub mod style;

pub use document::{HtmlDocument, HtmlDocumentOptions, HtmlDrawCommand};
pub use element::{HtmlElement, HtmlElementId, HtmlRect};
