use crate::html::style::parse_declarations;
use std::collections::BTreeMap;
pub type HtmlElementId = usize;
#[derive(Clone, Copy, Debug, Default, PartialEq)]
pub struct HtmlRect {
    pub x: f32,
    pub y: f32,
    pub w: f32,
    pub h: f32,
}
impl HtmlRect {
    pub fn contains(self, x: f32, y: f32) -> bool {
        x >= self.x && y >= self.y && x <= self.x + self.w && y <= self.y + self.h
    }
}
#[derive(Clone, Debug)]
pub struct HtmlElement {
    pub(crate) id: HtmlElementId,
    pub(crate) tag_name: String,
    pub(crate) parent: Option<HtmlElementId>,
    pub(crate) children: Vec<HtmlElementId>,
    pub(crate) attributes: BTreeMap<String, String>,
    pub(crate) inline_style: BTreeMap<String, String>,
    pub(crate) text: String,
    pub(crate) rect: HtmlRect,
    pub(crate) removed: bool,
}
impl HtmlElement {
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
    pub fn id(&self) -> HtmlElementId {
        self.id
    }
    pub fn tag_name(&self) -> &str {
        &self.tag_name
    }
    pub fn parent(&self) -> Option<HtmlElementId> {
        self.parent
    }
    pub fn children(&self) -> &[HtmlElementId] {
        &self.children
    }
    pub fn rect(&self) -> HtmlRect {
        self.rect
    }
    pub fn attribute(&self, name: &str) -> Option<&str> {
        self.attributes
            .get(&normalise_name(name))
            .map(String::as_str)
    }
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
    pub fn id_attribute(&self) -> Option<&str> {
        self.attribute("id")
    }
    pub(crate) fn set_id_attribute(&mut self, value: Option<String>) {
        self.set_attribute("id", value);
    }
    pub fn has_class(&self, class_name: &str) -> bool {
        self.class_names().any(|name| name == class_name)
    }
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
    pub(crate) fn toggle_class(&mut self, class_name: &str, force: Option<bool>) -> bool {
        let should_have = force.unwrap_or_else(|| !self.has_class(class_name));
        if should_have {
            self.add_class(class_name);
        } else {
            self.remove_class(class_name);
        }
        should_have
    }
    pub fn style(&self, name: &str) -> Option<&str> {
        self.inline_style
            .get(&normalise_name(name))
            .map(String::as_str)
    }
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
    pub fn is_removed(&self) -> bool {
        self.removed
    }
    pub(crate) fn is_void_tag(&self) -> bool {
        matches!(self.tag_name.as_str(), "br" | "img" | "input")
    }
    pub(crate) fn class_names(&self) -> impl Iterator<Item = &str> {
        self.attribute("class")
            .unwrap_or_default()
            .split_ascii_whitespace()
    }
}
pub(crate) fn normalise_name(name: &str) -> String {
    name.trim().to_ascii_lowercase()
}
