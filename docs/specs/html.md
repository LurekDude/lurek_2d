# html

## General Info

- Module group: `Edge/Integration`
- Source path: `src/html/`
- Lua API path(s): `src/lua_api/html_api.rs`
- Primary Lua namespace: `lurek.html`
- Rust test path(s): None found in the workspace
- Lua test path(s): None found in the workspace

## Summary

The `html` module is documented from the current source tree and existing module reference data.

This module is mostly self-contained inside the Edge/Integration group. Cross-module behavior should stay in the referenced Rust source files and Lua bindings rather than being duplicated here.

## Files

- `document.rs`: `HtmlDocument` — DOM owner, layout engine, stylesheet manager, viewport, draw-command generation.
- `element.rs`: `HtmlElement`, `HtmlElementId`, `HtmlRect` — node representation, attribute/class/style storage, child management.
- `mod.rs`: Module root — re-exports `HtmlDocument`, `HtmlDocumentOptions`, `HtmlDrawCommand`, `HtmlElement`, `HtmlElementId`, `HtmlRect`.
- `parser.rs`: HTML/RML string parser — produces element tree from markup.
- `selector.rs`: CSS selector parser and matching engine.
- `style.rs`: CSS property parser, cascade, computed-style resolution.

## Types

- `HtmlDocumentOptions` (`struct`, `document.rs`): Configuration options for [`HtmlDocument::new`].
- `HtmlDrawCommand` (`struct`, `document.rs`): A single renderer-agnostic draw instruction produced by [`HtmlDocument::draw`].
- `HtmlDocument` (`struct`, `document.rs`): An HTML/CSS document with an integrated layout engine and draw-command emitter.
- `HtmlElementId` (`type`, `element.rs`): Opaque index into the element arena inside [`super::document::HtmlDocument`].
- `HtmlRect` (`struct`, `element.rs`): Axis-aligned bounding rectangle in screen pixels, set during the layout pass.
- `HtmlElement` (`struct`, `element.rs`): A single DOM element node within an [`super::document::HtmlDocument`] arena.
- `CssRule` (`struct`, `style.rs`): A parsed CSS rule with a selector string and a property → value map.
- `CssParseResult` (`struct`, `style.rs`): Output of [`parse_declarations`] — a property map and any parse warnings.

## Functions

- `HtmlDocument::new` (`document.rs`): Creates a new document from an HTML string using default options (800×600 viewport, no CSS).
- `HtmlDocument::with_options` (`document.rs`): Creates a new document with explicit viewport dimensions and an optional initial stylesheet.
- `HtmlDocument::supports` (`document.rs`): Returns `true` if the active HTML backend supports the named feature string.
- `HtmlDocument::generation` (`document.rs`): Returns the document generation counter — increments on every `set_html` call.
- `HtmlDocument::root` (`document.rs`): Returns the id of the root (body) element.
- `HtmlDocument::element` (`document.rs`): Returns a reference to the element with the given id, or `None` if removed or out of range.
- `HtmlDocument::get_html` (`document.rs`): Returns the raw HTML source string that was last passed to `set_html`.
- `HtmlDocument::set_html` (`document.rs`): Replaces the entire document body with new HTML markup and marks the document dirty.
- `HtmlDocument::set_css` (`document.rs`): Replaces the document stylesheet with new CSS text and rebuilds the cascade.
- `HtmlDocument::add_css` (`document.rs`): Appends additional CSS rules to the existing stylesheet without discarding prior rules.
- `HtmlDocument::clear_css` (`document.rs`): Removes all CSS rules from the document and marks it dirty.
- `HtmlDocument::set_viewport` (`document.rs`): Sets the layout viewport dimensions in pixels; width and height are clamped to a minimum of 1.
- `HtmlDocument::viewport` (`document.rs`): Returns the current viewport size as `(width, height)` in pixels.
- `HtmlDocument::update` (`document.rs`): Advances CSS animations by `dt` seconds and triggers a relayout if the document is dirty.
- `HtmlDocument::is_dirty` (`document.rs`): Returns `true` when a layout pass is needed before the next `draw_commands` call.
- `HtmlDocument::relayout` (`document.rs`): Forces a synchronous layout pass and clears the dirty flag.
- `HtmlDocument::draw_commands` (`document.rs`): Returns draw commands for the document, offset by `(x, y)`.
- `HtmlDocument::get_element_by_id` (`document.rs`): Returns the id of the first element whose `id` attribute matches, or `None`.
- `HtmlDocument::query` (`document.rs`): Returns the id of the first element in document order that matches the CSS selector.
- `HtmlDocument::query_all` (`document.rs`): Returns all element ids in document order that match the CSS selector.
- `HtmlDocument::query_from` (`document.rs`): Returns the first descendant of `start` (exclusive) that matches the CSS selector.
- `HtmlDocument::query_all_from` (`document.rs`): Returns all descendants of `start` (exclusive) that match the CSS selector.
- `HtmlDocument::ancestors_inclusive` (`document.rs`): Returns the id of `element_id` followed by each ancestor up to the root.
- `HtmlDocument::text` (`document.rs`): Returns the concatenated text content of the element and all its descendants.
- `HtmlDocument::set_text` (`document.rs`): Replaces the element's text content, removing all existing children.
- `HtmlDocument::element_html` (`document.rs`): Returns the serialised inner HTML of the element as a string.
- `HtmlDocument::set_element_html` (`document.rs`): Replaces the element's inner HTML, removing all existing children.
- `HtmlDocument::append_element_html` (`document.rs`): Appends parsed HTML nodes as new children of the element.
- `HtmlDocument::remove_element` (`document.rs`): Removes the element from the DOM.
- `HtmlDocument::set_attribute` (`document.rs`): Sets or removes an attribute on the element.
- `HtmlDocument::set_id_attribute` (`document.rs`): Sets or clears the element's `id` attribute, updating the document's id index.
- `HtmlDocument::add_class` (`document.rs`): Adds a CSS class to the element's class list.
- `HtmlDocument::remove_class` (`document.rs`): Removes a CSS class from the element's class list.
- `HtmlDocument::toggle_class` (`document.rs`): Toggles a CSS class on the element, optionally forcing add (`true`) or remove (`false`).
- `HtmlDocument::style_value` (`document.rs`): Returns the computed (inline then cascade) value for the named CSS property, or `None`.
- `HtmlDocument::set_style` (`document.rs`): Sets or removes an inline CSS property on the element.
- `HtmlDocument::focus` (`document.rs`): Gives keyboard focus to the element.
- `HtmlDocument::blur` (`document.rs`): Removes keyboard focus from the element if it currently has focus.
- `HtmlDocument::mouse_pressed` (`document.rs`): Hit-tests a mouse press at `(x, y)` and focuses the topmost matching element.
- `HtmlDocument::mouse_released` (`document.rs`): Hit-tests a mouse release at `(x, y)`.
- `HtmlDocument::mouse_moved` (`document.rs`): Updates the hovered element via hit-test at `(x, y)`.
- `HtmlDocument::wheel_moved` (`document.rs`): Routes a scroll-wheel event to the hovered or focused element.
- `HtmlDocument::key_pressed` (`document.rs`): Routes a key-press event to the focused element, falling back to the root.
- `HtmlDocument::text_input` (`document.rs`): Appends a typed character to the focused `<input>` element's value.
- `HtmlDocument::warnings` (`document.rs`): Returns parse and layout warnings accumulated since the last `set_html` or `set_css` call.
- `HtmlRect::contains` (`element.rs`): Returns `true` if the point `(x, y)` lies within this rectangle.
- `HtmlElement::new` (`element.rs`): Creates a new element with the given `id`, `tag_name`, and optional `parent` link.
- `HtmlElement::id` (`element.rs`): Returns the element's arena index (opaque — do not rely on the value).
- `HtmlElement::tag_name` (`element.rs`): Returns the element's tag name as a lower-case string (e.g.
- `HtmlElement::parent` (`element.rs`): Returns the id of the parent element, or `None` for the root.
- `HtmlElement::children` (`element.rs`): Returns the ordered list of direct child element ids.
- `HtmlElement::rect` (`element.rs`): Returns the element's computed bounding rectangle in screen pixels.
- `HtmlElement::attribute` (`element.rs`): Returns the value of the named attribute, or `None` if absent.
- `HtmlElement::set_attribute` (`element.rs`): Sets or removes the named attribute; also syncs inline style when `name` is `"style"`.
- `HtmlElement::id_attribute` (`element.rs`): Returns the value of the `id` attribute, or `None` if not set.
- `HtmlElement::set_id_attribute` (`element.rs`): Sets or removes the `id` attribute.
- `HtmlElement::has_class` (`element.rs`): Returns `true` if the element's `class` attribute contains `class_name`.
- `HtmlElement::add_class` (`element.rs`): Appends `class_name` to the element's `class` attribute if not already present.
- `HtmlElement::remove_class` (`element.rs`): Removes `class_name` from the element's `class` attribute.
- `HtmlElement::toggle_class` (`element.rs`): Adds or removes `class_name`; `force` pins the target state.
- `HtmlElement::style` (`element.rs`): Returns the value of an inline CSS property by name, or `None` if not set.
- `HtmlElement::set_style` (`element.rs`): Sets or removes the inline CSS property `name`, keeping the `style` attribute in sync.
- `HtmlElement::is_removed` (`element.rs`): Returns `true` if this element has been removed from the DOM arena.
- `HtmlElement::is_void_tag` (`element.rs`): Returns `true` if this tag is self-closing (br, img, input).
- `HtmlElement::class_names` (`element.rs`): Iterates over space-separated class tokens in the `class` attribute.
- `normalise_name` (`element.rs`): Trims and lowercases `name` for consistent attribute / property map keying.
- `parse_into` (`parser.rs`): Parses `html` and appends new elements under `parent`, returning the direct child ids.
- `escape_text` (`parser.rs`): Escapes `&`, `<`, and `>` for safe inclusion in HTML text content.
- `escape_attribute` (`parser.rs`): Escapes `&`, `<`, `>`, and `"` for safe inclusion in HTML attribute values.
- `matches_selector` (`selector.rs`): Returns `true` if `element_id` satisfies the CSS `selector` within the element arena.
- `parse_stylesheets` (`style.rs`): Parses multiple stylesheet source strings into a flat list of [`CssRule`]s and any warnings.
- `parse_declarations` (`style.rs`): Parses a single CSS declaration block (e.g.
- `parse_length` (`style.rs`): Parses a CSS length value (`px`, `%` relative to `basis`, or bare `f32`).

## Lua API Reference

- Binding path(s): `src/lua_api/html_api.rs`
- Namespace: `lurek.html`

### Module Functions
- `lurek.html.preventDefault`: Prevents the default browser action associated with this event.
- `lurek.html.stopPropagation`: Stops the event from bubbling up to parent elements.
- `lurek.html.isDefaultPrevented`: Returns true if `preventDefault` has been called on this event.
- `lurek.html.newDocument`: Creates a detached HTML document from markup and optional CSS/viewport options.
- `lurek.html.loadDocument`: Loads HTML from the sandboxed game filesystem, with optional `opts.css`, `opts.cssPath`, viewport options, and companion `.css` fallback.
- `lurek.html.supports`: Returns whether the active HTML facade supports a named feature.

### `LHtmlDocument` Methods
- `LHtmlDocument:setHtml`: Replaces this document's markup and invalidates existing element handles.
- `LHtmlDocument:getHtml`: Returns the source markup used by this document.
- `LHtmlDocument:setCss`: Replaces this document's stylesheet text.
- `LHtmlDocument:addCss`: Appends stylesheet text after existing CSS rules.
- `LHtmlDocument:clearCss`: Removes all stylesheet rules from this document.
- `LHtmlDocument:setViewport`: Sets the document layout viewport in UI pixels.
- `LHtmlDocument:getViewport`: Returns the document layout viewport in UI pixels.
- `LHtmlDocument:update`: Advances document state and runs layout if needed.
- `LHtmlDocument:draw`: Builds draw commands and enqueues them into the frame render queue.
- `LHtmlDocument:relayout`: Forces a layout pass immediately.
- `LHtmlDocument:isDirty`: Returns whether DOM, CSS, viewport, or layout state changed.
- `LHtmlDocument:getRoot`: Returns the root element for this document.
- `LHtmlDocument:getElementById`: Finds the first element whose id attribute matches the given value, or nil.
- `LHtmlDocument:query`: Finds the first element matching a supported selector.
- `LHtmlDocument:queryAll`: Returns all elements matching a supported selector in document order.
- `LHtmlDocument:on`: Registers a document-level event listener.
- `LHtmlDocument:off`: Removes a document-level event listener.
- `LHtmlDocument:mousepressed`: Forwards a mouse press and emits a minimal click event.
- `LHtmlDocument:mousereleased`: Forwards a mouse release event.
- `LHtmlDocument:mousemoved`: Forwards a mouse move event.
- `LHtmlDocument:wheelmoved`: Forwards a mouse wheel event.
- `LHtmlDocument:keypressed`: Forwards a key press and emits a keydown event.
- `LHtmlDocument:textinput`: Forwards text input and emits an input event for focused input elements.
- `LHtmlDocument:type`: Returns the type name of this object.
- `LHtmlDocument:typeOf`: Returns true if this object is of the given type.

### `LHtmlElement` Methods
- `LHtmlElement:getDocument`: Returns the owning HtmlDocument.
- `LHtmlElement:getTagName`: Returns this element's tag name.
- `LHtmlElement:getId`: Returns this element's id or nil.
- `LHtmlElement:setId`: Sets or removes this element's id.
- `LHtmlElement:getText`: Returns this element's text content.
- `LHtmlElement:setText`: Replaces this element's text content.
- `LHtmlElement:getHtml`: Returns this element's inner HTML.
- `LHtmlElement:setHtml`: Replaces this element's inner HTML.
- `LHtmlElement:appendHtml`: Appends HTML inside this element.
- `LHtmlElement:remove`: Removes this element from the document tree.
- `LHtmlElement:getAttribute`: Returns an attribute value or nil.
- `LHtmlElement:setAttribute`: Sets or removes an attribute value.
- `LHtmlElement:removeAttribute`: Removes the named attribute from this element; does nothing if absent.
- `LHtmlElement:hasClass`: Returns whether this element has a CSS class.
- `LHtmlElement:addClass`: Adds a CSS class to this element.
- `LHtmlElement:removeClass`: Removes a CSS class from this element.
- `LHtmlElement:toggleClass`: Toggles a CSS class and returns the final state.
- `LHtmlElement:getStyle`: Returns an inline or stylesheet value for a property.
- `LHtmlElement:setStyle`: Sets or removes an inline style value.
- `LHtmlElement:getRect`: Returns this element's last computed layout rectangle.
- `LHtmlElement:focus`: Gives focus to this element.
- `LHtmlElement:blur`: Clears focus from this element if it currently has focus.
- `LHtmlElement:query`: Finds the first descendant matching a selector.
- `LHtmlElement:queryAll`: Returns all descendants matching a selector.
- `LHtmlElement:on`: Registers an element event listener.
- `LHtmlElement:off`: Removes an element event listener.
- `LHtmlElement:type`: Returns the type name of this object.
- `LHtmlElement:typeOf`: Returns true if this object is of the given type.

## References

- No top-level `crate::<module>` imports were detected in this module's Rust source files.

## Notes

- Keep this module reference synchronized with `src/html/` and any matching Lua bindings.
- HTML draw-command color parsing accepts hex, `rgb/rgba`, `hsl/hsla`, `transparent`, and an extended set of CSS named colors (for example `orange`, `teal`, `crimson`, `indigo`).
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
