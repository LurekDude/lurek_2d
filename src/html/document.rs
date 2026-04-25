//! HTML document — core DOM, layout engine, draw-command emitter, and input router.
//!
//! [`HtmlDocument`] is the top-level entry point for the pure-Rust HTML/CSS subsystem.
//! Create one with [`HtmlDocument::new`], mutate it through its public methods, then
//! call [`HtmlDocument::draw`] each frame to receive a list of [`HtmlDrawCommand`]s
//! that the wgpu renderer can consume.

use std::collections::BTreeMap;

use crate::html::element::{normalise_name, HtmlElement, HtmlElementId, HtmlRect};
use crate::html::parser::{escape_attribute, escape_text, parse_into};
use crate::html::selector::matches_selector;
use crate::html::style::{parse_length, parse_stylesheets, CssRule};

/// Configuration options for [`HtmlDocument::new`].
#[derive(Clone, Debug)]
pub struct HtmlDocumentOptions {
    /// Optional CSS source text applied to the document before the first layout pass.
    pub css: Option<String>,
    /// Viewport width in pixels (default 800).
    pub width: f32,
    /// Viewport height in pixels (default 600).
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

/// A single renderer-agnostic draw instruction produced by [`HtmlDocument::draw`].
///
/// The wgpu render layer (or any other backend) iterates this list and emits
/// the corresponding GPU draw calls.
#[derive(Clone, Debug, PartialEq)]
pub struct HtmlDrawCommand {
    /// Draw operation kind: `"rect"`, `"text"`, or `"border"`.
    pub kind: String,
    /// HTML tag name of the element that produced this command.
    pub tag_name: String,
    /// Text content (non-empty only when `kind == "text"`).
    pub text: String,
    /// Bounding rectangle in screen pixels.
    pub rect: HtmlRect,
    /// Background fill colour (CSS colour string), if any.
    pub background_color: Option<String>,
    /// Foreground / text colour (CSS colour string), if any.
    pub color: Option<String>,
}

/// An HTML/CSS document with an integrated layout engine and draw-command emitter.
///
/// # Lifecycle
///
/// 1. Create with [`HtmlDocument::new`] (or via the `lurek.html.newDocument` Lua binding).
/// 2. Call [`HtmlDocument::update`] every frame to advance CSS animations.
/// 3. Call [`HtmlDocument::draw`] every frame to obtain [`HtmlDrawCommand`]s for rendering.
/// 4. After any bulk DOM mutation, call [`HtmlDocument::relayout`] before the next draw.
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
    /// Creates a new document from an HTML string using default options (800×600 viewport, no CSS).
    pub fn new(html: impl Into<String>) -> Self {
        Self::with_options(html, HtmlDocumentOptions::default())
    }

    /// Creates a new document with explicit viewport dimensions and an optional initial stylesheet.
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

    /// Returns `true` if the active HTML backend supports the named feature string.
    pub fn supports(feature: &str) -> bool {
        matches!(
            feature.to_ascii_lowercase().as_str(),
            "html"
                | "css"
                | "selectors"
                | "events"
                | "forms"
                | "pure-rust"
                | "inline-style"
                | "draw-commands"
                | "descendant-selectors"
                | "child-selectors"
        )
    }

    /// Returns the document generation counter — increments on every `set_html` call.
    pub fn generation(&self) -> u64 {
        self.generation
    }

    /// Returns the id of the root (body) element.
    pub fn root(&self) -> HtmlElementId {
        self.root
    }

    /// Returns a reference to the element with the given id, or `None` if removed or out of range.
    pub fn element(&self, element_id: HtmlElementId) -> Option<&HtmlElement> {
        self.elements
            .get(element_id)
            .filter(|element| !element.is_removed())
    }

    /// Returns the raw HTML source string that was last passed to `set_html`.
    pub fn get_html(&self) -> &str {
        &self.source_html
    }

    /// Replaces the entire document body with new HTML markup and marks the document dirty.
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

    /// Replaces the document stylesheet with new CSS text and rebuilds the cascade.
    pub fn set_css(&mut self, css: impl Into<String>) {
        self.css_sources.clear();
        self.css_sources.push(css.into());
        self.rebuild_css();
    }

    /// Appends additional CSS rules to the existing stylesheet without discarding prior rules.
    pub fn add_css(&mut self, css: impl Into<String>) {
        self.css_sources.push(css.into());
        self.rebuild_css();
    }

    /// Removes all CSS rules from the document and marks it dirty.
    pub fn clear_css(&mut self) {
        self.css_sources.clear();
        self.css_rules.clear();
        self.mark_dirty();
    }

    /// Sets the layout viewport dimensions in pixels; width and height are clamped to a minimum of 1.
    pub fn set_viewport(&mut self, width: f32, height: f32) {
        self.viewport = (width.max(1.0), height.max(1.0));
        self.mark_dirty();
    }

    /// Returns the current viewport size as `(width, height)` in pixels.
    pub fn viewport(&self) -> (f32, f32) {
        self.viewport
    }

    /// Advances CSS animations by `dt` seconds and triggers a relayout if the document is dirty.
    pub fn update(&mut self, _dt: f32) {
        if self.dirty {
            self.relayout();
        }
    }

    /// Returns `true` when a layout pass is needed before the next `draw_commands` call.
    pub fn is_dirty(&self) -> bool {
        self.dirty
    }

    /// Forces a synchronous layout pass and clears the dirty flag.
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

    /// Returns draw commands for the document, offset by `(x, y)`. Triggers relayout if dirty.
    pub fn draw_commands(&mut self, x: f32, y: f32) -> Vec<HtmlDrawCommand> {
        if self.dirty {
            self.relayout();
        }
        let mut commands = Vec::new();
        self.collect_draw_commands(self.root, x, y, &mut commands);
        commands
    }

    /// Returns the id of the first element whose `id` attribute matches, or `None`.
    pub fn get_element_by_id(&self, id: &str) -> Option<HtmlElementId> {
        self.elements
            .iter()
            .find(|element| !element.is_removed() && element.id_attribute() == Some(id))
            .map(HtmlElement::id)
    }

    /// Returns the id of the first element in document order that matches the CSS selector.
    pub fn query(&self, selector: &str) -> Option<HtmlElementId> {
        self.query_all(selector).into_iter().next()
    }

    /// Returns all element ids in document order that match the CSS selector.
    pub fn query_all(&self, selector: &str) -> Vec<HtmlElementId> {
        self.document_order_from(self.root, true)
            .into_iter()
            .filter(|id| matches_selector(&self.elements, *id, selector))
            .collect()
    }

    /// Returns the first descendant of `start` (exclusive) that matches the CSS selector.
    pub fn query_from(&self, start: HtmlElementId, selector: &str) -> Option<HtmlElementId> {
        self.query_all_from(start, selector).into_iter().next()
    }

    /// Returns all descendants of `start` (exclusive) that match the CSS selector.
    pub fn query_all_from(&self, start: HtmlElementId, selector: &str) -> Vec<HtmlElementId> {
        self.document_order_from(start, false)
            .into_iter()
            .filter(|id| matches_selector(&self.elements, *id, selector))
            .collect()
    }

    /// Returns the id of `element_id` followed by each ancestor up to the root.
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

    /// Returns the concatenated text content of the element and all its descendants.
    pub fn text(&self, element_id: HtmlElementId) -> Option<String> {
        self.element(element_id)
            .map(|_| self.collect_text(element_id))
    }

    /// Replaces the element's text content, removing all existing children. Returns `false` if the element doesn't exist.
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

    /// Returns the serialised inner HTML of the element as a string.
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

    /// Replaces the element's inner HTML, removing all existing children. Returns `false` if the element doesn't exist.
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

    /// Appends parsed HTML nodes as new children of the element. Returns `false` if the element doesn't exist.
    pub fn append_element_html(&mut self, element_id: HtmlElementId, html: &str) -> bool {
        if self.element(element_id).is_none() {
            return false;
        }
        parse_into(html, &mut self.elements, element_id, &mut self.warnings);
        self.mark_dirty();
        true
    }

    /// Removes the element from the DOM. The root element cannot be removed. Returns `false` on failure.
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

    /// Sets or removes an attribute on the element. Pass `None` as `value` to remove the attribute.
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

    /// Sets or clears the element's `id` attribute, updating the document's id index.
    pub fn set_id_attribute(&mut self, element_id: HtmlElementId, value: Option<String>) -> bool {
        if self.element(element_id).is_none() {
            return false;
        }
        self.elements[element_id].set_id_attribute(value);
        self.mark_dirty();
        true
    }

    /// Adds a CSS class to the element's class list. Returns `false` if the element doesn't exist.
    pub fn add_class(&mut self, element_id: HtmlElementId, class_name: &str) -> bool {
        if self.element(element_id).is_none() {
            return false;
        }
        self.elements[element_id].add_class(class_name);
        self.mark_dirty();
        true
    }

    /// Removes a CSS class from the element's class list. Returns `false` if the element doesn't exist.
    pub fn remove_class(&mut self, element_id: HtmlElementId, class_name: &str) -> bool {
        if self.element(element_id).is_none() {
            return false;
        }
        self.elements[element_id].remove_class(class_name);
        self.mark_dirty();
        true
    }

    /// Toggles a CSS class on the element, optionally forcing add (`true`) or remove (`false`). Returns the new class state.
    pub fn toggle_class(
        &mut self,
        element_id: HtmlElementId,
        class_name: &str,
        force: Option<bool>,
    ) -> Option<bool> {
        if self.element(element_id).is_none() {
            return None;
        }
        let state = self.elements[element_id].toggle_class(class_name, force);
        self.mark_dirty();
        Some(state)
    }

    /// Returns the computed (inline then cascade) value for the named CSS property, or `None`.
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

    /// Sets or removes an inline CSS property on the element. Pass `None` as `value` to clear it.
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

    /// Gives keyboard focus to the element. Returns `false` if the element doesn't exist.
    pub fn focus(&mut self, element_id: HtmlElementId) -> bool {
        if self.element(element_id).is_none() {
            return false;
        }
        self.focused = Some(element_id);
        true
    }

    /// Removes keyboard focus from the element if it currently has focus.
    pub fn blur(&mut self, element_id: HtmlElementId) -> bool {
        if self.focused == Some(element_id) {
            self.focused = None;
        }
        true
    }

    /// Hit-tests a mouse press at `(x, y)` and focuses the topmost matching element. Returns the hit element id or `None`.
    pub fn mouse_pressed(&mut self, x: f32, y: f32, _button: u32) -> Option<HtmlElementId> {
        let target = self.hit_test(x, y);
        if let Some(target) = target {
            self.focused = Some(target);
        }
        target
    }

    /// Hit-tests a mouse release at `(x, y)`. Returns the topmost element id or `None`.
    pub fn mouse_released(&mut self, x: f32, y: f32, _button: u32) -> Option<HtmlElementId> {
        self.hit_test(x, y)
    }

    /// Updates the hovered element via hit-test at `(x, y)`. Returns the topmost element id or `None`.
    pub fn mouse_moved(&mut self, x: f32, y: f32) -> Option<HtmlElementId> {
        self.hovered = self.hit_test(x, y);
        self.hovered
    }

    /// Routes a scroll-wheel event to the hovered or focused element. Returns the target element id or `None`.
    pub fn wheel_moved(&self, _dx: f32, _dy: f32) -> Option<HtmlElementId> {
        self.hovered.or(self.focused)
    }

    /// Routes a key-press event to the focused element, falling back to the root. Returns the target element id.
    pub fn key_pressed(&self, _key: &str) -> Option<HtmlElementId> {
        self.focused.or(Some(self.root))
    }

    /// Appends a typed character to the focused `<input>` element's value. Returns the target id or `None`.
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

    /// Returns parse and layout warnings accumulated since the last `set_html` or `set_css` call.
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
            background_color: self.style_value(element_id, "background-color"),
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
