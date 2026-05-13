use crate::html::element::{normalise_name, HtmlElement, HtmlElementId, HtmlRect};
use crate::html::parser::{escape_attribute, escape_text, parse_into};
use crate::html::selector::matches_selector;
use crate::html::style::{parse_length, parse_stylesheets, CssRule};
use std::collections::BTreeMap;
#[derive(Clone, Debug)]
pub struct HtmlDocumentOptions {
    pub css: Option<String>,
    pub width: f32,
    pub height: f32,
}
impl Default for HtmlDocumentOptions {
    fn default() -> Self {
        Self {
            css: None,
            width: 800.0,
            height: 600.0,
        }
    }
}
#[derive(Clone, Debug, PartialEq)]
pub struct HtmlDrawCommand {
    pub kind: String,
    pub tag_name: String,
    pub text: String,
    pub rect: HtmlRect,
    pub background_color: Option<String>,
    pub color: Option<String>,
}
#[derive(Clone, Debug)]
pub struct HtmlDocument {
    source_html: String,
    css_sources: Vec<String>,
    css_rules: Vec<CssRule>,
    warnings: Vec<String>,
    elements: Vec<HtmlElement>,
    root: HtmlElementId,
    viewport: (f32, f32),
    dirty: bool,
    focused: Option<HtmlElementId>,
    hovered: Option<HtmlElementId>,
    generation: u64,
}
impl HtmlDocument {
    pub fn new(html: impl Into<String>) -> Self {
        Self::with_options(html, HtmlDocumentOptions::default())
    }
    pub fn with_options(html: impl Into<String>, options: HtmlDocumentOptions) -> Self {
        let mut document = Self {
            source_html: String::new(),
            css_sources: Vec::new(),
            css_rules: Vec::new(),
            warnings: Vec::new(),
            elements: vec![HtmlElement::new(0, "body", None)],
            root: 0,
            viewport: (options.width.max(1.0), options.height.max(1.0)),
            dirty: true,
            focused: None,
            hovered: None,
            generation: 0,
        };
        document.set_html(html.into());
        if let Some(css) = options.css {
            document.set_css(css);
        }
        document
    }
    pub fn supports(feature: &str) -> bool {
        matches!(
            feature.to_ascii_lowercase().as_str(),
            "html"
                | "css"
                | "css-flex"
                | "selectors"
                | "events"
                | "forms"
                | "pure-rust"
                | "inline-style"
                | "draw-commands"
                | "load-document"
                | "descendant-selectors"
                | "child-selectors"
        )
    }
    pub fn generation(&self) -> u64 {
        self.generation
    }
    pub fn root(&self) -> HtmlElementId {
        self.root
    }
    pub fn element(&self, element_id: HtmlElementId) -> Option<&HtmlElement> {
        self.elements
            .get(element_id)
            .filter(|element| !element.is_removed())
    }
    pub fn get_html(&self) -> &str {
        &self.source_html
    }
    pub fn set_html(&mut self, html: impl Into<String>) {
        self.source_html = html.into();
        self.elements.clear();
        self.elements.push(HtmlElement::new(0, "body", None));
        self.root = 0;
        self.focused = None;
        self.hovered = None;
        self.warnings.clear();
        parse_into(
            &self.source_html,
            &mut self.elements,
            self.root,
            &mut self.warnings,
        );
        self.generation = self.generation.saturating_add(1);
        self.mark_dirty();
    }
    pub fn set_css(&mut self, css: impl Into<String>) {
        self.css_sources.clear();
        self.css_sources.push(css.into());
        self.rebuild_css();
    }
    pub fn add_css(&mut self, css: impl Into<String>) {
        self.css_sources.push(css.into());
        self.rebuild_css();
    }
    pub fn clear_css(&mut self) {
        self.css_sources.clear();
        self.css_rules.clear();
        self.mark_dirty();
    }
    pub fn set_viewport(&mut self, width: f32, height: f32) {
        self.viewport = (width.max(1.0), height.max(1.0));
        self.mark_dirty();
    }
    pub fn viewport(&self) -> (f32, f32) {
        self.viewport
    }
    pub fn update(&mut self, _dt: f32) {
        if self.dirty {
            self.relayout();
        }
    }
    pub fn is_dirty(&self) -> bool {
        self.dirty
    }
    pub fn relayout(&mut self) {
        let (width, height) = self.viewport;
        self.elements[self.root].rect = HtmlRect {
            x: 0.0,
            y: 0.0,
            w: width,
            h: height,
        };
        self.layout_children(self.root, 0.0, 0.0, width);
        self.dirty = false;
    }
    pub fn draw_commands(&mut self, x: f32, y: f32) -> Vec<HtmlDrawCommand> {
        if self.dirty {
            self.relayout();
        }
        let mut commands = Vec::new();
        self.collect_draw_commands(self.root, x, y, &mut commands);
        commands
    }
    pub fn get_element_by_id(&self, id: &str) -> Option<HtmlElementId> {
        self.elements
            .iter()
            .find(|element| !element.is_removed() && element.id_attribute() == Some(id))
            .map(HtmlElement::id)
    }
    pub fn query(&self, selector: &str) -> Option<HtmlElementId> {
        self.query_all(selector).into_iter().next()
    }
    pub fn query_all(&self, selector: &str) -> Vec<HtmlElementId> {
        self.document_order_from(self.root, true)
            .into_iter()
            .filter(|id| matches_selector(&self.elements, *id, selector))
            .collect()
    }
    pub fn query_from(&self, start: HtmlElementId, selector: &str) -> Option<HtmlElementId> {
        self.query_all_from(start, selector).into_iter().next()
    }
    pub fn query_all_from(&self, start: HtmlElementId, selector: &str) -> Vec<HtmlElementId> {
        self.document_order_from(start, false)
            .into_iter()
            .filter(|id| matches_selector(&self.elements, *id, selector))
            .collect()
    }
    pub fn ancestors_inclusive(&self, element_id: HtmlElementId) -> Vec<HtmlElementId> {
        let mut out = Vec::new();
        let mut current = Some(element_id);
        while let Some(id) = current {
            if self.element(id).is_none() {
                break;
            }
            out.push(id);
            current = self.elements[id].parent();
        }
        out
    }
    pub fn text(&self, element_id: HtmlElementId) -> Option<String> {
        self.element(element_id)
            .map(|_| self.collect_text(element_id))
    }
    pub fn set_text(&mut self, element_id: HtmlElementId, text: impl Into<String>) -> bool {
        if self.element(element_id).is_none() {
            return false;
        }
        self.remove_descendants(element_id);
        self.elements[element_id].children.clear();
        self.elements[element_id].text = text.into();
        self.mark_dirty();
        true
    }
    pub fn element_html(&self, element_id: HtmlElementId) -> Option<String> {
        self.element(element_id).map(|element| {
            let mut html = escape_text(&element.text);
            for child in &element.children {
                if self.element(*child).is_some() {
                    html.push_str(&self.element_outer_html(*child));
                }
            }
            html
        })
    }
    pub fn set_element_html(&mut self, element_id: HtmlElementId, html: &str) -> bool {
        if self.element(element_id).is_none() {
            return false;
        }
        self.remove_descendants(element_id);
        self.elements[element_id].children.clear();
        self.elements[element_id].text.clear();
        parse_into(html, &mut self.elements, element_id, &mut self.warnings);
        self.mark_dirty();
        true
    }
    pub fn append_element_html(&mut self, element_id: HtmlElementId, html: &str) -> bool {
        if self.element(element_id).is_none() {
            return false;
        }
        parse_into(html, &mut self.elements, element_id, &mut self.warnings);
        self.mark_dirty();
        true
    }
    pub fn remove_element(&mut self, element_id: HtmlElementId) -> bool {
        if element_id == self.root || self.element(element_id).is_none() {
            return false;
        }
        if let Some(parent) = self.elements[element_id].parent() {
            self.elements[parent]
                .children
                .retain(|child| *child != element_id);
        }
        self.mark_removed(element_id);
        self.mark_dirty();
        true
    }
    pub fn set_attribute(
        &mut self,
        element_id: HtmlElementId,
        name: &str,
        value: Option<String>,
    ) -> bool {
        if self.element(element_id).is_none() {
            return false;
        }
        self.elements[element_id].set_attribute(name, value);
        self.mark_dirty();
        true
    }
    pub fn set_id_attribute(&mut self, element_id: HtmlElementId, value: Option<String>) -> bool {
        if self.element(element_id).is_none() {
            return false;
        }
        self.elements[element_id].set_id_attribute(value);
        self.mark_dirty();
        true
    }
    pub fn add_class(&mut self, element_id: HtmlElementId, class_name: &str) -> bool {
        if self.element(element_id).is_none() {
            return false;
        }
        self.elements[element_id].add_class(class_name);
        self.mark_dirty();
        true
    }
    pub fn remove_class(&mut self, element_id: HtmlElementId, class_name: &str) -> bool {
        if self.element(element_id).is_none() {
            return false;
        }
        self.elements[element_id].remove_class(class_name);
        self.mark_dirty();
        true
    }
    pub fn toggle_class(
        &mut self,
        element_id: HtmlElementId,
        class_name: &str,
        force: Option<bool>,
    ) -> Option<bool> {
        self.element(element_id)?;
        let state = self.elements[element_id].toggle_class(class_name, force);
        self.mark_dirty();
        Some(state)
    }
    pub fn style_value(&self, element_id: HtmlElementId, property: &str) -> Option<String> {
        let property = normalise_name(property);
        let element = self.element(element_id)?;
        if let Some(value) = element.style(&property) {
            return Some(value.to_string());
        }
        self.css_rules
            .iter()
            .filter(|rule| rule.declarations.contains_key(&property))
            .filter(|rule| matches_selector(&self.elements, element_id, &rule.selector))
            .max_by_key(|rule| rule.order)
            .and_then(|rule| rule.declarations.get(&property))
            .cloned()
    }
    pub fn set_style(
        &mut self,
        element_id: HtmlElementId,
        property: &str,
        value: Option<String>,
    ) -> bool {
        if self.element(element_id).is_none() {
            return false;
        }
        self.elements[element_id].set_style(property, value);
        self.mark_dirty();
        true
    }
    pub fn focus(&mut self, element_id: HtmlElementId) -> bool {
        if self.element(element_id).is_none() {
            return false;
        }
        self.focused = Some(element_id);
        true
    }
    pub fn blur(&mut self, element_id: HtmlElementId) -> bool {
        if self.focused == Some(element_id) {
            self.focused = None;
        }
        true
    }
    pub fn mouse_pressed(&mut self, x: f32, y: f32, _button: u32) -> Option<HtmlElementId> {
        let target = self.hit_test(x, y);
        if let Some(target) = target {
            self.focused = Some(target);
        }
        target
    }
    pub fn mouse_released(&mut self, x: f32, y: f32, _button: u32) -> Option<HtmlElementId> {
        self.hit_test(x, y)
    }
    pub fn mouse_moved(&mut self, x: f32, y: f32) -> Option<HtmlElementId> {
        self.hovered = self.hit_test(x, y);
        self.hovered
    }
    pub fn wheel_moved(&self, _dx: f32, _dy: f32) -> Option<HtmlElementId> {
        self.hovered.or(self.focused)
    }
    pub fn key_pressed(&self, _key: &str) -> Option<HtmlElementId> {
        self.focused.or(Some(self.root))
    }
    pub fn text_input(&mut self, text: &str) -> Option<HtmlElementId> {
        let target = self.focused?;
        if self
            .element(target)
            .is_some_and(|element| element.tag_name() == "input")
        {
            let current = self.elements[target]
                .attribute("value")
                .map(str::to_string)
                .unwrap_or_default();
            self.elements[target].set_attribute("value", Some(format!("{current}{text}")));
            self.mark_dirty();
            Some(target)
        } else {
            None
        }
    }
    pub fn warnings(&self) -> &[String] {
        &self.warnings
    }
    fn rebuild_css(&mut self) {
        let (rules, warnings) = parse_stylesheets(&self.css_sources);
        self.css_rules = rules;
        self.warnings.extend(warnings);
        self.mark_dirty();
    }
    fn mark_dirty(&mut self) {
        self.dirty = true;
    }
    fn layout_children(&mut self, parent: HtmlElementId, x: f32, y: f32, width: f32) -> f32 {
        let child_ids = self.elements[parent].children.clone();
        let mut cursor_y = y;
        for child_id in child_ids {
            if self.element(child_id).is_none() {
                continue;
            }
            let display = self.style_value(child_id, "display");
            if display.as_deref() == Some("none") {
                self.elements[child_id].rect = HtmlRect {
                    x,
                    y: cursor_y,
                    w: 0.0,
                    h: 0.0,
                };
                continue;
            }
            let padding = parse_length(self.style_value(child_id, "padding").as_deref(), width)
                .unwrap_or(0.0);
            let child_width = parse_length(self.style_value(child_id, "width").as_deref(), width)
                .or_else(|| {
                    self.elements[child_id]
                        .attribute("width")
                        .and_then(|value| parse_length(Some(value), width))
                })
                .unwrap_or(width)
                .max(0.0);
            let explicit_height = parse_length(
                self.style_value(child_id, "height").as_deref(),
                self.viewport.1,
            )
            .or_else(|| {
                self.elements[child_id]
                    .attribute("height")
                    .and_then(|value| parse_length(Some(value), self.viewport.1))
            });
            let default_height = self.default_height(child_id);
            self.elements[child_id].rect = HtmlRect {
                x: x + padding,
                y: cursor_y,
                w: child_width,
                h: explicit_height.unwrap_or(default_height),
            };
            let children_height = self.layout_children(
                child_id,
                x + padding,
                cursor_y + padding,
                (child_width - padding * 2.0).max(0.0),
            );
            let height =
                explicit_height.unwrap_or_else(|| default_height.max(children_height + padding));
            self.elements[child_id].rect.h = height;
            cursor_y += height;
        }
        cursor_y - y
    }
    fn default_height(&self, element_id: HtmlElementId) -> f32 {
        let element = &self.elements[element_id];
        if !element.children().is_empty() {
            0.0
        } else if element.tag_name().starts_with('h') && element.tag_name().len() == 2 {
            36.0
        } else if matches!(element.tag_name(), "button" | "input") {
            28.0
        } else if element.tag_name() == "br" {
            12.0
        } else {
            20.0
        }
    }
    fn collect_draw_commands(
        &self,
        element_id: HtmlElementId,
        offset_x: f32,
        offset_y: f32,
        commands: &mut Vec<HtmlDrawCommand>,
    ) {
        let Some(element) = self.element(element_id) else {
            return;
        };
        let mut rect = element.rect();
        rect.x += offset_x;
        rect.y += offset_y;
        commands.push(HtmlDrawCommand {
            kind: "box".to_string(),
            tag_name: element.tag_name().to_string(),
            text: String::new(),
            rect,
            background_color: self
                .style_value(element_id, "background-color")
                .or_else(|| self.style_value(element_id, "background")),
            color: self.style_value(element_id, "color"),
        });
        let text = self.collect_text(element_id);
        if !text.is_empty() {
            commands.push(HtmlDrawCommand {
                kind: "text".to_string(),
                tag_name: element.tag_name().to_string(),
                text,
                rect,
                background_color: None,
                color: self.style_value(element_id, "color"),
            });
        }
        for child in element.children() {
            self.collect_draw_commands(*child, offset_x, offset_y, commands);
        }
    }
    fn collect_text(&self, element_id: HtmlElementId) -> String {
        let Some(element) = self.element(element_id) else {
            return String::new();
        };
        let mut parts = Vec::new();
        if !element.text.is_empty() {
            parts.push(element.text.clone());
        }
        if let Some(value) = element.attribute("value") {
            if !value.is_empty() {
                parts.push(value.to_string());
            }
        }
        for child in element.children() {
            let text = self.collect_text(*child);
            if !text.is_empty() {
                parts.push(text);
            }
        }
        parts.join(" ")
    }
    fn document_order_from(&self, start: HtmlElementId, include_start: bool) -> Vec<HtmlElementId> {
        let mut out = Vec::new();
        self.collect_document_order(start, include_start, &mut out);
        out
    }
    fn collect_document_order(
        &self,
        element_id: HtmlElementId,
        include_self: bool,
        out: &mut Vec<HtmlElementId>,
    ) {
        let Some(element) = self.element(element_id) else {
            return;
        };
        if include_self {
            out.push(element_id);
        }
        for child in element.children() {
            self.collect_document_order(*child, true, out);
        }
    }
    fn element_outer_html(&self, element_id: HtmlElementId) -> String {
        let Some(element) = self.element(element_id) else {
            return String::new();
        };
        let attrs = attrs_to_html(&element.attributes);
        if element.is_void_tag() {
            return format!("<{}{}>", element.tag_name(), attrs);
        }
        format!(
            "<{}{}>{}</{}>",
            element.tag_name(),
            attrs,
            self.element_html(element_id).unwrap_or_default(),
            element.tag_name()
        )
    }
    fn remove_descendants(&mut self, element_id: HtmlElementId) {
        let children = self.elements[element_id].children.clone();
        for child in children {
            self.mark_removed(child);
        }
    }
    fn mark_removed(&mut self, element_id: HtmlElementId) {
        let children = self.elements[element_id].children.clone();
        self.elements[element_id].removed = true;
        for child in children {
            self.mark_removed(child);
        }
    }
    fn hit_test(&mut self, x: f32, y: f32) -> Option<HtmlElementId> {
        if self.dirty {
            self.relayout();
        }
        self.document_order_from(self.root, true)
            .into_iter()
            .rev()
            .find(|id| {
                self.element(*id).is_some_and(|element| {
                    self.style_value(*id, "pointer-events").as_deref() != Some("none")
                        && element.rect().contains(x, y)
                })
            })
    }
}
fn attrs_to_html(attrs: &BTreeMap<String, String>) -> String {
    if attrs.is_empty() {
        return String::new();
    }
    attrs
        .iter()
        .map(|(name, value)| format!(" {name}=\"{}\"", escape_attribute(value)))
        .collect::<Vec<_>>()
        .join("")
}
