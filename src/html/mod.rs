pub mod color;
pub mod document;
pub mod element;
pub mod parser;
pub mod selector;
pub mod style;
pub use color::parse_css_color_rgba;
pub use document::{HtmlDocument, HtmlDocumentOptions, HtmlDrawCommand};
pub use element::{HtmlElement, HtmlElementId, HtmlRect};
