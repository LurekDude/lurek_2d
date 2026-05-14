/// CSS color parsing helpers for HTML style handling.
pub mod color;
/// HTML document tree, viewport state, and draw-command generation.
pub mod document;
/// HTML element storage, attributes, and geometry.
pub mod element;
/// Tag parsing and HTML entity escaping.
pub mod parser;
/// Selector parsing and element matching.
pub mod selector;
/// CSS rule parsing and property normalization.
pub mod style;
/// Parse a CSS color string into normalized RGBA values.
pub use color::parse_css_color_rgba;
/// HTML document types and draw command output.
pub use document::{HtmlDocument, HtmlDocumentOptions, HtmlDrawCommand};
/// HTML element types and rectangles.
pub use element::{HtmlElement, HtmlElementId, HtmlRect};
