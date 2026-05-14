use crate::html::style::parse_declarations;
use std::collections::BTreeMap;
/// Stable index type for elements stored in an HTML document.
pub type HtmlElementId = usize;
/// Axis-aligned rectangle used for HTML layout and hit testing.
#[derive(Clone, Copy, Debug, Default, PartialEq)]
pub struct HtmlRect {
    /// Left coordinate in pixels.
    pub x: f32,
    /// Top coordinate in pixels.
    pub y: f32,
    /// Width in pixels.
    pub w: f32,
    /// Height in pixels.
    pub h: f32,
}
impl HtmlRect {
    /// Return whether the point lies inside the rectangle bounds.
    pub fn contains(self, x: f32, y: f32) -> bool {
        x >= self.x && y >= self.y && x <= self.x + self.w && y <= self.y + self.h
    }
}
/// A parsed HTML element with attributes, style, children, and layout state.
#[derive(Clone, Debug)]
pub struct HtmlElement {
    /// Stable element id within the document storage.
    pub(crate) id: HtmlElementId,
    /// Lowercased tag name.
    pub(crate) tag_name: String,
    /// Parent element id, or `None` for the root.
    pub(crate) parent: Option<HtmlElementId>,
    /// Direct child element ids in document order.
    pub(crate) children: Vec<HtmlElementId>,
    /// Normalized HTML attributes keyed by lowercased name.
    pub(crate) attributes: BTreeMap<String, String>,
    /// Inline CSS declarations parsed from the `style` attribute.
    pub(crate) inline_style: BTreeMap<String, String>,
    /// Collapsed text content owned by this element.
    pub(crate) text: String,
    /// Layout rectangle assigned during relayout.
    pub(crate) rect: HtmlRect,
    /// Removal flag used to hide detached subtrees without reindexing.
    pub(crate) removed: bool,
}
impl HtmlElement {
    /// Create a new element with empty attributes, children, text, and layout.
    pub(crate) fn new(
        id: HtmlElementId,
        tag_name: impl Into<String>,
        parent: Option<HtmlElementId>,
    ) -> Self {
        Self {
            id,
            tag_name: tag_name.into().to_ascii_lowercase(),
            parent,
            children: Vec::new(),
            attributes: BTreeMap::new(),
            inline_style: BTreeMap::new(),
            text: String::new(),
            rect: HtmlRect::default(),
            removed: false,
        }
    }
    /// Return the stable element id.
    pub fn id(&self) -> HtmlElementId {
        self.id
    }
    /// Return the lowercased tag name.
    pub fn tag_name(&self) -> &str {
        &self.tag_name
    }
    /// Return the parent element id, or `None` for the root.
    pub fn parent(&self) -> Option<HtmlElementId> {
        self.parent
    }
    /// Return the child element ids in document order.
    pub fn children(&self) -> &[HtmlElementId] {
        &self.children
    }
    /// Return the current layout rectangle.
    pub fn rect(&self) -> HtmlRect {
        self.rect
    }
    /// Return a normalized attribute value by name.
    pub fn attribute(&self, name: &str) -> Option<&str> {
        self.attributes
            .get(&normalise_name(name))
            .map(String::as_str)
    }
    /// Set or clear an attribute and keep inline style state in sync.
    pub(crate) fn set_attribute(&mut self, name: &str, value: Option<String>) {
        let key = normalise_name(name);
        match value {
            Some(value) => {
                if key == "style" {
                    self.inline_style = parse_declarations(&value).declarations;
                }
                self.attributes.insert(key, value);
            }
            None => {
                if key == "style" {
                    self.inline_style.clear();
                }
                self.attributes.remove(&key);
            }
        }
    }
    /// Return the `id` attribute value when present.
    pub fn id_attribute(&self) -> Option<&str> {
        self.attribute("id")
    }
    /// Set the `id` attribute value.
    pub(crate) fn set_id_attribute(&mut self, value: Option<String>) {
        self.set_attribute("id", value);
    }
    /// Return whether the element currently has the named class.
    pub fn has_class(&self, class_name: &str) -> bool {
        self.class_names().any(|name| name == class_name)
    }
    /// Add a class name when it is non-empty and not already present.
    pub(crate) fn add_class(&mut self, class_name: &str) {
        if class_name.is_empty() || self.has_class(class_name) {
            return;
        }
        let mut classes = self
            .attribute("class")
            .map(str::to_string)
            .unwrap_or_default();
        if !classes.is_empty() {
            classes.push(' ');
        }
        classes.push_str(class_name);
        self.set_attribute("class", Some(classes));
    }
    /// Remove a class name from the class list.
    pub(crate) fn remove_class(&mut self, class_name: &str) {
        let classes = self
            .class_names()
            .filter(|name| *name != class_name)
            .collect::<Vec<_>>()
            .join(" ");
        if classes.is_empty() {
            self.set_attribute("class", None);
        } else {
            self.set_attribute("class", Some(classes));
        }
    }
    /// Toggle a class name and return the resulting presence state.
    pub(crate) fn toggle_class(&mut self, class_name: &str, force: Option<bool>) -> bool {
        let should_have = force.unwrap_or_else(|| !self.has_class(class_name));
        if should_have {
            self.add_class(class_name);
        } else {
            self.remove_class(class_name);
        }
        should_have
    }
    /// Return an inline style property by normalized name.
    pub fn style(&self, name: &str) -> Option<&str> {
        self.inline_style
            .get(&normalise_name(name))
            .map(String::as_str)
    }
    /// Set an inline style property and keep the serialized `style` attribute updated.
    pub(crate) fn set_style(&mut self, name: &str, value: Option<String>) {
        let key = normalise_name(name);
        match value {
            Some(value) => {
                self.inline_style.insert(key, value);
            }
            None => {
                self.inline_style.remove(&key);
            }
        }
        let style_attr = self
            .inline_style
            .iter()
            .map(|(property, value)| format!("{property}: {value}"))
            .collect::<Vec<_>>()
            .join("; ");
        if style_attr.is_empty() {
            self.attributes.remove("style");
        } else {
            self.attributes.insert("style".to_string(), style_attr);
        }
    }
    /// Return whether this element has been removed from the live tree.
    pub fn is_removed(&self) -> bool {
        self.removed
    }
    /// Return whether the tag is void and should not receive closing markup.
    pub(crate) fn is_void_tag(&self) -> bool {
        matches!(self.tag_name.as_str(), "br" | "img" | "input")
    }
    /// Return an iterator over whitespace-separated class names.
    pub(crate) fn class_names(&self) -> impl Iterator<Item = &str> {
        self.attribute("class")
            .unwrap_or_default()
            .split_ascii_whitespace()
    }
}
/// Normalize attribute and property names to lower case with trimmed whitespace.
pub(crate) fn normalise_name(name: &str) -> String {
    name.trim().to_ascii_lowercase()
}
