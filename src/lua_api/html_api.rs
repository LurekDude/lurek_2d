//! `lurek.html` -- HTML document bindings for markup and CSS loading, layout, rendering into engine draw commands, DOM element selection and mutation, input forwarding, event listeners, and feature support checks.

use super::SharedState;
use crate::html::{parse_css_color_rgba, HtmlDocument, HtmlDocumentOptions, HtmlElementId};
use crate::render::{DrawMode, RenderCommand};
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::path::Path;
use std::rc::Rc;
#[derive(Clone)]
/// Lua-side HTML document handle with DOM state, callbacks, and render command access.
struct LuaHtmlDocument {
    /// Parsed document, layout tree, dirty state, and input state.
    inner: Rc<RefCell<HtmlDocument>>,
    /// Document and element listener registry state.
    callbacks: Rc<RefCell<HtmlCallbacks>>,
    /// Shared runtime state receiving HTML render commands.
    state: Rc<RefCell<SharedState>>,
}
impl LuaHtmlDocument {
    /// Wraps a document with callback state and shared runtime access.
    fn new(document: HtmlDocument, state: Rc<RefCell<SharedState>>) -> Self {
        Self {
            inner: Rc::new(RefCell::new(document)),
            callbacks: Rc::new(RefCell::new(HtmlCallbacks::default())),
            state,
        }
    }
    /// Creates an element handle tied to the document generation at lookup time.
    fn element_handle(&self, element_id: HtmlElementId) -> LuaHtmlElement {
        LuaHtmlElement {
            document: self.inner.clone(),
            callbacks: self.callbacks.clone(),
            state: self.state.clone(),
            element_id,
            generation: self.inner.borrow().generation(),
        }
    }
}
#[derive(Clone)]
/// Lua-side DOM element handle with stale-generation detection.
struct LuaHtmlElement {
    /// Shared document containing this element.
    document: Rc<RefCell<HtmlDocument>>,
    /// Shared callback registry for document and element listeners.
    callbacks: Rc<RefCell<HtmlCallbacks>>,
    /// Shared runtime state used when returning document handles.
    state: Rc<RefCell<SharedState>>,
    /// Element id inside the document.
    element_id: HtmlElementId,
    /// Document generation captured when this handle was created.
    generation: u64,
}
#[derive(Default)]
/// Stores HTML event callbacks and the next listener handle.
struct HtmlCallbacks {
    /// Next numeric listener handle.
    next_handle: u64,
    /// Document-level listeners keyed by listener handle.
    document: HashMap<u64, HtmlListener>,
    /// Element-level listeners keyed by element id and listener handle.
    elements: HashMap<HtmlElementId, HashMap<u64, HtmlListener>>,
}
/// Stores one Lua event listener registry key and event name.
struct HtmlListener {
    /// Event name matched during dispatch.
    event: String,
    /// Lua registry key for the callback function.
    key: LuaRegistryKey,
}
#[derive(Default)]
/// Mutable event dispatch flags shared with event table helper functions.
struct HtmlEventFlags {
    /// Whether the callback requested default prevention.
    default_prevented: bool,
    /// Whether the callback requested propagation stop.
    propagation_stopped: bool,
}
#[derive(Default)]
/// Optional event payload fields inserted into Lua event tables.
struct HtmlEventPayload {
    /// Mouse x coordinate when available.
    x: Option<f32>,
    /// Mouse y coordinate when available.
    y: Option<f32>,
    /// Mouse button index when available.
    button: Option<u32>,
    /// Keyboard key string when available.
    key: Option<String>,
    /// Text input string when available.
    text: Option<String>,
    /// Element value string after input events when available.
    value: Option<String>,
}
/// Provides Lua methods for document content, layout, rendering, input, and document listeners.
impl LuaUserData for LuaHtmlDocument {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setHtml --
        /// Replaces the document markup and invalidates existing element handles.
        /// @param | html | string | New HTML markup.
        /// @return | nil | Returns nothing.
        methods.add_method("setHtml", |_, this, html: String| {
            this.inner.borrow_mut().set_html(html);
            Ok(())
        });
        // -- getHtml --
        /// Returns the current document markup string.
        /// @return | string | Current HTML markup.
        methods.add_method("getHtml", |_, this, ()| {
            Ok(this.inner.borrow().get_html().to_string())
        });
        // -- setCss --
        /// Replaces the document stylesheet text.
        /// @param | css | string | CSS source text.
        /// @return | nil | Returns nothing.
        methods.add_method("setCss", |_, this, css: String| {
            this.inner.borrow_mut().set_css(css);
            Ok(())
        });
        // -- addCss --
        /// Appends CSS source text to the document stylesheet.
        /// @param | css | string | CSS source text to append.
        /// @return | nil | Returns nothing.
        methods.add_method("addCss", |_, this, css: String| {
            this.inner.borrow_mut().add_css(css);
            Ok(())
        });
        // -- clearCss --
        /// Clears all CSS source text from the document.
        /// @return | nil | Returns nothing.
        methods.add_method("clearCss", |_, this, ()| {
            this.inner.borrow_mut().clear_css();
            Ok(())
        });
        // -- setViewport --
        /// Sets the document layout viewport size.
        /// @param | w | number | Viewport width in pixels.
        /// @param | h | number | Viewport height in pixels.
        /// @return | nil | Returns nothing.
        methods.add_method("setViewport", |_, this, (w, h): (f32, f32)| {
            this.inner.borrow_mut().set_viewport(w, h);
            Ok(())
        });
        // -- getViewport --
        /// Returns the document layout viewport size.
        /// @return | number | Viewport width in pixels.
        /// @return | number | Viewport height in pixels.
        methods.add_method("getViewport", |_, this, ()| {
            Ok(this.inner.borrow().viewport())
        });
        // -- update --
        /// Advances document timers and animated state.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | Returns nothing.
        methods.add_method("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
        // -- draw --
        /// Queues render commands for this document at an optional offset.
        /// @param | x? | number | X offset, defaulting to 0.
        /// @param | y? | number | Y offset, defaulting to 0.
        /// @return | nil | Returns nothing.
        methods.add_method("draw", |_, this, (x, y): (Option<f32>, Option<f32>)| {
            let dx = x.unwrap_or(0.0);
            let dy = y.unwrap_or(0.0);
            let mut document = this.inner.borrow_mut();
            let mut state = this.state.borrow_mut();
            enqueue_html_draw_commands(&mut document, &mut state, dx, dy);
            Ok(())
        });
        // -- render --
        /// Queues render commands for this document at an optional offset.
        /// @param | x? | number | X offset, defaulting to 0.
        /// @param | y? | number | Y offset, defaulting to 0.
        /// @return | nil | Returns nothing.
        methods.add_method("render", |_, this, (x, y): (Option<f32>, Option<f32>)| {
            let dx = x.unwrap_or(0.0);
            let dy = y.unwrap_or(0.0);
            let mut document = this.inner.borrow_mut();
            let mut state = this.state.borrow_mut();
            enqueue_html_draw_commands(&mut document, &mut state, dx, dy);
            Ok(())
        });
        // -- relayout --
        /// Rebuilds document layout immediately.
        /// @return | nil | Returns nothing.
        methods.add_method("relayout", |_, this, ()| {
            this.inner.borrow_mut().relayout();
            Ok(())
        });
        // -- isDirty --
        /// Returns whether the document layout is dirty.
        /// @return | boolean | True when a relayout is needed.
        methods.add_method("isDirty", |_, this, ()| Ok(this.inner.borrow().is_dirty()));
        // -- getRoot --
        /// Returns the root DOM element handle.
        /// @return | LHtmlElement | Root element handle.
        methods.add_method("getRoot", |lua, this, ()| {
            lua.create_userdata(this.element_handle(this.inner.borrow().root()))
        });
        // -- getElementById --
        /// Looks up the first element with a matching id attribute.
        /// @param | id | string | Element id attribute.
        /// @return | LuaValue | `LHtmlElement` handle, or nil when no element matches.
        methods.add_method("getElementById", |lua, this, id: String| {
            html_element_value(lua, this, this.inner.borrow().get_element_by_id(&id))
        });
        // -- query --
        /// Looks up the first element matching a selector.
        /// @param | selector | string | Selector supported by the HTML engine.
        /// @return | LuaValue | `LHtmlElement` handle, or nil when no element matches.
        methods.add_method("query", |lua, this, selector: String| {
            html_element_value(lua, this, this.inner.borrow().query(&selector))
        });
        // -- queryAll --
        /// Returns all elements matching a selector.
        /// @param | selector | string | Selector supported by the HTML engine.
        /// @return | table | Array table of `LHtmlElement` handles.
        methods.add_method("queryAll", |lua, this, selector: String| {
            html_element_table(lua, this, this.inner.borrow().query_all(&selector))
        });
        // -- on --
        /// Registers a document-level event listener.
        /// @param | event | string | Event name to listen for.
        /// @param | func | function | Lua callback receiving an event table.
        /// @return | integer | Listener handle used by `off`.
        methods.add_method("on", |lua, this, (event, func): (String, LuaFunction)| {
            let key = lua.create_registry_value(func)?;
            let mut callbacks = this.callbacks.borrow_mut();
            let handle = callbacks.next_handle.saturating_add(1);
            callbacks.next_handle = handle;
            callbacks
                .document
                .insert(handle, HtmlListener { event, key });
            Ok(handle)
        });
        // -- off --
        /// Removes a document-level event listener by handle.
        /// @param | handle | integer | Listener handle returned by `on`.
        /// @return | nil | Returns nothing.
        methods.add_method("off", |lua, this, handle: u64| {
            if let Some(listener) = this.callbacks.borrow_mut().document.remove(&handle) {
                lua.remove_registry_value(listener.key)?;
            }
            Ok(())
        });
        // -- mousepressed --
        /// Forwards a mouse press to the document and dispatches a click event when an element is hit.
        /// @param | x | number | Mouse x coordinate.
        /// @param | y | number | Mouse y coordinate.
        /// @param | button? | integer | Mouse button, defaulting to 1.
        /// @return | boolean | True when the event was consumed or default was prevented.
        methods.add_method(
            "mousepressed",
            |lua, this, (x, y, button): (f32, f32, Option<u32>)| {
                let button = button.unwrap_or(1);
                let target = this.inner.borrow_mut().mouse_pressed(x, y, button);
                let consumed = target.is_some();
                let prevented = emit_html_event(
                    lua,
                    this,
                    "click",
                    target,
                    HtmlEventPayload {
                        x: Some(x),
                        y: Some(y),
                        button: Some(button),
                        ..HtmlEventPayload::default()
                    },
                )?;
                Ok(consumed || prevented)
            },
        );
        // -- mousereleased --
        /// Forwards a mouse release to the document.
        /// @param | x | number | Mouse x coordinate.
        /// @param | y | number | Mouse y coordinate.
        /// @param | button? | integer | Mouse button, defaulting to 1.
        /// @return | boolean | True when an element handled the release.
        methods.add_method(
            "mousereleased",
            |_, this, (x, y, button): (f32, f32, Option<u32>)| {
                Ok(this
                    .inner
                    .borrow_mut()
                    .mouse_released(x, y, button.unwrap_or(1))
                    .is_some())
            },
        );
        // -- mousemoved --
        /// Forwards mouse movement to the document.
        /// @param | x | number | Mouse x coordinate.
        /// @param | y | number | Mouse y coordinate.
        /// @return | boolean | True when an element handled the move.
        methods.add_method("mousemoved", |_, this, (x, y): (f32, f32)| {
            Ok(this.inner.borrow_mut().mouse_moved(x, y).is_some())
        });
        // -- wheelmoved --
        /// Forwards mouse wheel movement to the document.
        /// @param | dx | number | Horizontal wheel delta.
        /// @param | dy | number | Vertical wheel delta.
        /// @return | boolean | True when an element handled the wheel event.
        methods.add_method("wheelmoved", |_, this, (dx, dy): (f32, f32)| {
            Ok(this.inner.borrow().wheel_moved(dx, dy).is_some())
        });
        // -- keypressed --
        /// Forwards a key press to the focused document element and dispatches `keydown`.
        /// @param | key | string | Key name.
        /// @return | boolean | True when the event was consumed or default was prevented.
        methods.add_method("keypressed", |lua, this, key: String| {
            let target = this.inner.borrow().key_pressed(&key);
            let consumed = target.is_some();
            let prevented = emit_html_event(
                lua,
                this,
                "keydown",
                target,
                HtmlEventPayload {
                    key: Some(key),
                    ..HtmlEventPayload::default()
                },
            )?;
            Ok(consumed || prevented)
        });
        // -- textinput --
        /// Forwards text input to the focused document element and dispatches `input`.
        /// @param | text | string | Input text.
        /// @return | boolean | True when the event was consumed or default was prevented.
        methods.add_method("textinput", |lua, this, text: String| {
            let target = this.inner.borrow_mut().text_input(&text);
            let value = target.and_then(|id| this.inner.borrow().text(id));
            let consumed = target.is_some();
            let prevented = emit_html_event(
                lua,
                this,
                "input",
                target,
                HtmlEventPayload {
                    text: Some(text),
                    value,
                    ..HtmlEventPayload::default()
                },
            )?;
            Ok(consumed || prevented)
        });
        // -- type --
        /// Returns the Lua-visible type name for this HTML document handle.
        /// @return | string | The string `LHtmlDocument`.
        methods.add_method("type", |_, _, ()| Ok("LHtmlDocument"));
        // -- typeOf --
        /// Returns whether this document handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LHtmlDocument` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LHtmlDocument" || name == "Object")
        });
    }
}
/// Provides Lua methods for DOM element inspection, mutation, selection, focus, and listeners.
impl LuaUserData for LuaHtmlElement {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getDocument --
        /// Returns the document handle that owns this element.
        /// @return | LHtmlDocument | Owning document handle.
        methods.add_method("getDocument", |lua, this, ()| {
            lua.create_userdata(LuaHtmlDocument {
                inner: this.document.clone(),
                callbacks: this.callbacks.clone(),
                state: this.state.clone(),
            })
        });
        // -- getTagName --
        /// Returns this element's HTML tag name.
        /// @return | string | Tag name, or an empty string for missing elements.
        methods.add_method("getTagName", |_, this, ()| {
            check_html_element(this)?;
            Ok(this
                .document
                .borrow()
                .element(this.element_id)
                .map(|element| element.tag_name().to_string())
                .unwrap_or_default())
        });
        // -- getId --
        /// Returns this element's id attribute.
        /// @return | LuaValue | Id string, or nil when no id attribute exists.
        methods.add_method("getId", |_, this, ()| {
            check_html_element(this)?;
            Ok(this
                .document
                .borrow()
                .element(this.element_id)
                .and_then(|element| element.id_attribute().map(str::to_string)))
        });
        // -- setId --
        /// Sets or clears this element's id attribute.
        /// @param | id? | string | Id attribute value, or nil to clear.
        /// @return | nil | Returns nothing.
        methods.add_method("setId", |_, this, id: Option<String>| {
            check_html_element(this)?;
            this.document
                .borrow_mut()
                .set_id_attribute(this.element_id, id);
            Ok(())
        });
        // -- getText --
        /// Returns this element's text content.
        /// @return | string | Text content, or an empty string when none exists.
        methods.add_method("getText", |_, this, ()| {
            check_html_element(this)?;
            Ok(this
                .document
                .borrow()
                .text(this.element_id)
                .unwrap_or_default())
        });
        // -- setText --
        /// Replaces this element's text content.
        /// @param | text | string | New text content.
        /// @return | nil | Returns nothing.
        methods.add_method("setText", |_, this, text: String| {
            check_html_element(this)?;
            this.document.borrow_mut().set_text(this.element_id, text);
            Ok(())
        });
        // -- getHtml --
        /// Returns this element's inner HTML.
        /// @return | string | Element inner HTML, or an empty string when unavailable.
        methods.add_method("getHtml", |_, this, ()| {
            check_html_element(this)?;
            Ok(this
                .document
                .borrow()
                .element_html(this.element_id)
                .unwrap_or_default())
        });
        // -- setHtml --
        /// Replaces this element's inner HTML and may invalidate descendant element handles.
        /// @param | html | string | New inner HTML source.
        /// @return | nil | Returns nothing.
        methods.add_method("setHtml", |_, this, html: String| {
            check_html_element(this)?;
            this.document
                .borrow_mut()
                .set_element_html(this.element_id, &html);
            Ok(())
        });
        // -- appendHtml --
        /// Appends HTML source to this element's inner HTML.
        /// @param | html | string | HTML source to append.
        /// @return | nil | Returns nothing.
        methods.add_method("appendHtml", |_, this, html: String| {
            check_html_element(this)?;
            this.document
                .borrow_mut()
                .append_element_html(this.element_id, &html);
            Ok(())
        });
        // -- remove --
        /// Removes this element from the document.
        /// @return | nil | Returns nothing.
        methods.add_method("remove", |_, this, ()| {
            check_html_element(this)?;
            this.document.borrow_mut().remove_element(this.element_id);
            Ok(())
        });
        // -- getAttribute --
        /// Returns an attribute value from this element.
        /// @param | name | string | Attribute name.
        /// @return | LuaValue | Attribute string, or nil when absent.
        methods.add_method("getAttribute", |_, this, name: String| {
            check_html_element(this)?;
            Ok(this
                .document
                .borrow()
                .element(this.element_id)
                .and_then(|element| element.attribute(&name).map(str::to_string)))
        });
        // -- setAttribute --
        /// Sets or clears an attribute on this element.
        /// @param | name | string | Attribute name.
        /// @param | value? | string | Attribute value, or nil to remove the attribute.
        /// @return | nil | Returns nothing.
        methods.add_method(
            "setAttribute",
            |_, this, (name, value): (String, Option<String>)| {
                check_html_element(this)?;
                this.document
                    .borrow_mut()
                    .set_attribute(this.element_id, &name, value);
                Ok(())
            },
        );
        // -- removeAttribute --
        /// Removes an attribute from this element.
        /// @param | name | string | Attribute name to remove.
        /// @return | nil | Returns nothing.
        methods.add_method("removeAttribute", |_, this, name: String| {
            check_html_element(this)?;
            this.document
                .borrow_mut()
                .set_attribute(this.element_id, &name, None);
            Ok(())
        });
        // -- hasClass --
        /// Returns whether this element has a CSS class.
        /// @param | name | string | Class name to check.
        /// @return | boolean | True when the class is present.
        methods.add_method("hasClass", |_, this, name: String| {
            check_html_element(this)?;
            Ok(this
                .document
                .borrow()
                .element(this.element_id)
                .is_some_and(|element| element.has_class(&name)))
        });
        // -- addClass --
        /// Adds a CSS class to this element's class list.
        /// @param | name | string | Class name to add.
        /// @return | nil | Returns nothing.
        methods.add_method("addClass", |_, this, name: String| {
            check_html_element(this)?;
            this.document.borrow_mut().add_class(this.element_id, &name);
            Ok(())
        });
        // -- removeClass --
        /// Removes a CSS class from this element.
        /// @param | name | string | Class name to remove.
        /// @return | nil | Returns nothing.
        methods.add_method("removeClass", |_, this, name: String| {
            check_html_element(this)?;
            this.document
                .borrow_mut()
                .remove_class(this.element_id, &name);
            Ok(())
        });
        // -- toggleClass --
        /// Toggles a CSS class on this element, optionally forcing the final state.
        /// @param | name | string | Class name to toggle.
        /// @param | force? | boolean | Forced state.
        /// @return | boolean | Final class presence, or false when the element is unavailable.
        methods.add_method(
            "toggleClass",
            |_, this, (name, force): (String, Option<bool>)| {
                check_html_element(this)?;
                Ok(this
                    .document
                    .borrow_mut()
                    .toggle_class(this.element_id, &name, force)
                    .unwrap_or(false))
            },
        );
        // -- getStyle --
        /// Returns an inline or computed style value for this element.
        /// @param | name | string | CSS property name.
        /// @return | LuaValue | Style value string, or nil when missing.
        methods.add_method("getStyle", |_, this, name: String| {
            check_html_element(this)?;
            Ok(this.document.borrow().style_value(this.element_id, &name))
        });
        // -- setStyle --
        /// Sets or clears a style property on this element.
        /// @param | name | string | CSS property name.
        /// @param | value? | string | CSS value, or nil to clear the property.
        /// @return | nil | Returns nothing.
        methods.add_method(
            "setStyle",
            |_, this, (name, value): (String, Option<String>)| {
                check_html_element(this)?;
                this.document
                    .borrow_mut()
                    .set_style(this.element_id, &name, value);
                Ok(())
            },
        );
        // -- getRect --
        /// Returns this element's layout rectangle after relayout if needed.
        /// @return | number | X coordinate.
        /// @return | number | Y coordinate.
        /// @return | number | Width.
        /// @return | number | Height.
        methods.add_method("getRect", |_, this, ()| {
            check_html_element(this)?;
            let mut document = this.document.borrow_mut();
            if document.is_dirty() {
                document.relayout();
            }
            let rect = document
                .element(this.element_id)
                .map(|element| element.rect())
                .unwrap_or_default();
            Ok((rect.x, rect.y, rect.w, rect.h))
        });
        // -- focus --
        /// Gives keyboard focus to this element.
        /// @return | nil | Returns nothing.
        methods.add_method("focus", |_, this, ()| {
            check_html_element(this)?;
            this.document.borrow_mut().focus(this.element_id);
            Ok(())
        });
        // -- blur --
        /// Removes keyboard focus from this element when it is focused.
        /// @return | nil | Returns nothing.
        methods.add_method("blur", |_, this, ()| {
            check_html_element(this)?;
            this.document.borrow_mut().blur(this.element_id);
            Ok(())
        });
        // -- query --
        /// Looks up the first descendant element matching a selector.
        /// @param | selector | string | Selector supported by the HTML engine.
        /// @return | LuaValue | `LHtmlElement` handle, or nil when no descendant matches.
        methods.add_method("query", |lua, this, selector: String| {
            check_html_element(this)?;
            let document = LuaHtmlDocument {
                inner: this.document.clone(),
                callbacks: this.callbacks.clone(),
                state: this.state.clone(),
            };
            html_element_value(
                lua,
                &document,
                this.document
                    .borrow()
                    .query_from(this.element_id, &selector),
            )
        });
        // -- queryAll --
        /// Returns all descendant elements matching a selector.
        /// @param | selector | string | Selector supported by the HTML engine.
        /// @return | table | Array table of `LHtmlElement` handles.
        methods.add_method("queryAll", |lua, this, selector: String| {
            check_html_element(this)?;
            let document = LuaHtmlDocument {
                inner: this.document.clone(),
                callbacks: this.callbacks.clone(),
                state: this.state.clone(),
            };
            html_element_table(
                lua,
                &document,
                this.document
                    .borrow()
                    .query_all_from(this.element_id, &selector),
            )
        });
        // -- on --
        /// Registers an element-level event listener.
        /// @param | event | string | Event name to listen for.
        /// @param | func | function | Lua callback receiving an event table.
        /// @return | integer | Listener handle used by `off`.
        methods.add_method("on", |lua, this, (event, func): (String, LuaFunction)| {
            check_html_element(this)?;
            let key = lua.create_registry_value(func)?;
            let mut callbacks = this.callbacks.borrow_mut();
            let handle = callbacks.next_handle.saturating_add(1);
            callbacks.next_handle = handle;
            callbacks
                .elements
                .entry(this.element_id)
                .or_default()
                .insert(handle, HtmlListener { event, key });
            Ok(handle)
        });
        // -- off --
        /// Removes an element-level event listener by handle.
        /// @param | handle | integer | Listener handle returned by `on`.
        /// @return | nil | Returns nothing.
        methods.add_method("off", |lua, this, handle: u64| {
            if let Some(listeners) = this
                .callbacks
                .borrow_mut()
                .elements
                .get_mut(&this.element_id)
            {
                if let Some(listener) = listeners.remove(&handle) {
                    lua.remove_registry_value(listener.key)?;
                }
            }
            Ok(())
        });
        // -- type --
        /// Returns the Lua-visible type name for this HTML element handle.
        /// @return | string | The string `LHtmlElement`.
        methods.add_method("type", |_, _, ()| Ok("LHtmlElement"));
        // -- typeOf --
        /// Returns whether this element handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LHtmlElement` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LHtmlElement" || name == "Object")
        });
    }
}
/// Converts an optional element id into an element userdata value or nil.
fn html_element_value<'lua>(
    lua: &'lua Lua,
    document: &LuaHtmlDocument,
    element_id: Option<HtmlElementId>,
) -> LuaResult<LuaValue<'lua>> {
    match element_id {
        Some(element_id) => Ok(LuaValue::UserData(
            lua.create_userdata(document.element_handle(element_id))?,
        )),
        None => Ok(LuaValue::Nil),
    }
}
/// Converts element ids into a Lua array table of element handles.
fn html_element_table<'lua>(
    lua: &'lua Lua,
    document: &LuaHtmlDocument,
    element_ids: Vec<HtmlElementId>,
) -> LuaResult<LuaTable<'lua>> {
    let table = lua.create_table()?;
    for (index, element_id) in element_ids.into_iter().enumerate() {
        table.set(index + 1, document.element_handle(element_id))?;
    }
    Ok(table)
}
/// Verifies an element handle still points to a live element in the same document generation.
fn check_html_element(element: &LuaHtmlElement) -> LuaResult<()> {
    let document = element.document.borrow();
    if document.generation() != element.generation {
        return Err(LuaError::RuntimeError(
            "HtmlElement handle is stale after document markup replacement".to_string(),
        ));
    }
    if document.element(element.element_id).is_none() {
        return Err(LuaError::RuntimeError(
            "HtmlElement handle no longer points to a live element".to_string(),
        ));
    }
    Ok(())
}
/// Dispatches an HTML event through element bubbling and document listeners.
fn emit_html_event(
    lua: &Lua,
    document: &LuaHtmlDocument,
    event_name: &str,
    target: Option<HtmlElementId>,
    payload: HtmlEventPayload,
) -> LuaResult<bool> {
    let flags = Rc::new(RefCell::new(HtmlEventFlags::default()));
    let mut called = false;
    if let Some(target_id) = target {
        let chain = document.inner.borrow().ancestors_inclusive(target_id);
        for current_target in chain {
            let listeners = collect_element_listeners(lua, document, current_target, event_name)?;
            for listener in listeners {
                called = true;
                let event = create_html_event_table(
                    lua,
                    document,
                    event_name,
                    target,
                    Some(current_target),
                    &payload,
                    flags.clone(),
                )?;
                listener.call::<_, ()>(event)?;
                if flags.borrow().propagation_stopped {
                    return Ok(true);
                }
            }
        }
    }
    let listeners = collect_document_listeners(lua, document, event_name)?;
    for listener in listeners {
        called = true;
        let event = create_html_event_table(
            lua,
            document,
            event_name,
            target,
            None,
            &payload,
            flags.clone(),
        )?;
        listener.call::<_, ()>(event)?;
        if flags.borrow().propagation_stopped {
            break;
        }
    }
    Ok(called || flags.borrow().default_prevented)
}
/// Collects Lua callbacks for one element and event name.
fn collect_element_listeners<'lua>(
    lua: &'lua Lua,
    document: &LuaHtmlDocument,
    element_id: HtmlElementId,
    event_name: &str,
) -> LuaResult<Vec<LuaFunction<'lua>>> {
    let callbacks = document.callbacks.borrow();
    let Some(listeners) = callbacks.elements.get(&element_id) else {
        return Ok(Vec::new());
    };
    listeners
        .values()
        .filter(|listener| listener.event == event_name)
        .map(|listener| lua.registry_value(&listener.key))
        .collect()
}
/// Collects Lua document callbacks for one event name.
fn collect_document_listeners<'lua>(
    lua: &'lua Lua,
    document: &LuaHtmlDocument,
    event_name: &str,
) -> LuaResult<Vec<LuaFunction<'lua>>> {
    let callbacks = document.callbacks.borrow();
    callbacks
        .document
        .values()
        .filter(|listener| listener.event == event_name)
        .map(|listener| lua.registry_value(&listener.key))
        .collect()
}
/// Builds the Lua event table passed to HTML event listeners.
fn create_html_event_table<'lua>(
    lua: &'lua Lua,
    document: &LuaHtmlDocument,
    event_name: &str,
    target: Option<HtmlElementId>,
    current_target: Option<HtmlElementId>,
    payload: &HtmlEventPayload,
    flags: Rc<RefCell<HtmlEventFlags>>,
) -> LuaResult<LuaTable<'lua>> {
    let table = lua.create_table()?;
    /// Performs the 'type' operation.
    /// @return | nil | No value is returned.
    table.set("type", event_name)?;
    /// Performs the 'document' operation.
    /// @return | nil | No value is returned.
    table.set("document", document.clone())?;
    if let Some(target_id) = target {
        /// Performs the 'target' operation.
        /// @return | nil | No value is returned.
        table.set("target", document.element_handle(target_id))?;
    }
    match current_target {
        Some(current_target) => {
            /// Performs the 'currentTarget' operation.
            /// @return | nil | No value is returned.
            table.set("currentTarget", document.element_handle(current_target))?
        }
        /// Performs the 'currentTarget' operation.
        /// @return | nil | No value is returned.
        None => table.set("currentTarget", document.clone())?,
    }
    if let Some(x) = payload.x {
        /// Performs the 'x' operation.
        /// @return | nil | No value is returned.
        table.set("x", x)?;
    }
    if let Some(y) = payload.y {
        /// Performs the 'y' operation.
        /// @return | nil | No value is returned.
        table.set("y", y)?;
    }
    if let Some(button) = payload.button {
        /// Performs the 'button' operation.
        /// @return | nil | No value is returned.
        table.set("button", button)?;
    }
    if let Some(key) = &payload.key {
        /// Performs the 'key' operation.
        /// @return | nil | No value is returned.
        table.set("key", key.clone())?;
    }
    if let Some(text) = &payload.text {
        /// Performs the 'text' operation.
        /// @return | nil | No value is returned.
        table.set("text", text.clone())?;
    }
    if let Some(value) = &payload.value {
        /// Performs the 'value' operation.
        /// @return | nil | No value is returned.
        table.set("value", value.clone())?;
    }
    let prevent_flags = flags.clone();
    /// Marks the event as having its default action prevented.
    /// @return | nil | Returns nothing.
    table.set(
        "preventDefault",
        lua.create_function(move |_, ()| {
            prevent_flags.borrow_mut().default_prevented = true;
            Ok(())
        })?,
    )?;
    let stop_flags = flags.clone();
    /// Stops event propagation to remaining listeners.
    /// @return | nil | Returns nothing.
    table.set(
        "stopPropagation",
        lua.create_function(move |_, ()| {
            stop_flags.borrow_mut().propagation_stopped = true;
            Ok(())
        })?,
    )?;
    /// Returns whether the default action was prevented.
    /// @return | boolean | True when the default was prevented.
    table.set(
        "isDefaultPrevented",
        lua.create_function(move |_, ()| Ok(flags.borrow().default_prevented))?,
    )?;
    Ok(table)
}
/// Converts document draw commands into engine render commands.
fn enqueue_html_draw_commands(
    document: &mut HtmlDocument,
    state: &mut SharedState,
    x: f32,
    y: f32,
) {
    let commands = document.draw_commands(x, y);
    for command in commands {
        if command.rect.w <= 0.0 || command.rect.h <= 0.0 {
            continue;
        }
        match command.kind.as_str() {
            "box" => {
                if let Some(bg) = command
                    .background_color
                    .as_deref()
                    .and_then(parse_css_color)
                {
                    state
                        .render_commands
                        .push(RenderCommand::SetColor(bg[0], bg[1], bg[2], bg[3]));
                    state.render_commands.push(RenderCommand::Rectangle {
                        mode: DrawMode::Fill,
                        x: command.rect.x,
                        y: command.rect.y,
                        w: command.rect.w,
                        h: command.rect.h,
                    });
                }
                if let Some(border) = command.color.as_deref().and_then(parse_css_color) {
                    state.render_commands.push(RenderCommand::SetColor(
                        border[0], border[1], border[2], border[3],
                    ));
                    state.render_commands.push(RenderCommand::Rectangle {
                        mode: DrawMode::Line,
                        x: command.rect.x,
                        y: command.rect.y,
                        w: command.rect.w,
                        h: command.rect.h,
                    });
                }
            }
            "text" => {
                let text = command.text.trim();
                if text.is_empty() {
                    continue;
                }
                let Some(font_key) = state.active_font.or(state.default_font) else {
                    continue;
                };
                let fg = command
                    .color
                    .as_deref()
                    .and_then(parse_css_color)
                    .unwrap_or([1.0, 1.0, 1.0, 1.0]);
                state
                    .render_commands
                    .push(RenderCommand::SetColor(fg[0], fg[1], fg[2], fg[3]));
                state.render_commands.push(RenderCommand::Print {
                    font_key,
                    text: text.to_string(),
                    x: command.rect.x + 4.0,
                    y: command.rect.y + 4.0,
                    scale: 1.0,
                });
            }
            _ => {}
        }
    }
}
/// Parses a CSS color string into normalized RGBA channels.
fn parse_css_color(raw: &str) -> Option<[f32; 4]> {
    parse_css_color_rgba(raw)
}
/// Parses optional Lua document options and separate CSS path override.
fn parse_document_options(
    opts: Option<LuaTable>,
) -> LuaResult<(HtmlDocumentOptions, Option<String>)> {
    let mut options = HtmlDocumentOptions::default();
    let mut css_path = None;
    if let Some(opts) = opts {
        options.css = opts.get::<_, Option<String>>("css")?;
        css_path = opts.get::<_, Option<String>>("cssPath")?;
        if let Some(width) = opts.get::<_, Option<f32>>("width")? {
            options.width = width;
        }
        if let Some(height) = opts.get::<_, Option<f32>>("height")? {
            options.height = height;
        }
    }
    Ok((options, css_path))
}
/// Returns the CSS path beside an HTML path by replacing the extension with `.css`.
fn companion_css_path(path: &str) -> Option<String> {
    let trimmed = path.trim();
    if trimmed.is_empty() {
        return None;
    }
    Some(
        Path::new(trimmed)
            .with_extension("css")
            .to_string_lossy()
            .into_owned(),
    )
}
/// Registers `lurek.html` document constructors and feature support checks.
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let html = lua.create_table()?;
    let state_for_new = state.clone();
    // -- newDocument --
    /// Creates an HTML document from optional source and layout/style options.
    /// @param | source? | string | HTML source, defaulting to an empty document.
    /// @param | opts? | table | Table with `css`, `cssPath`, `width`, and `height` fields.
    /// @return | LHtmlDocument | New HTML document handle.
    html.set(
        "newDocument",
        lua.create_function(
            move |lua, (source, opts): (Option<String>, Option<LuaTable>)| {
                let (options, _) = parse_document_options(opts)?;
                lua.create_userdata(LuaHtmlDocument::new(
                    HtmlDocument::with_options(source.unwrap_or_default(), options),
                    state_for_new.clone(),
                ))
            },
        )?,
    )?;
    let state_for_load = state.clone();
    // -- loadDocument --
    /// Loads an HTML document from GameFS and optionally loads CSS from options or companion file.
    /// @param | path | string | GameFS path to the HTML file.
    /// @param | opts? | table | Table with `css`, `cssPath`, `width`, and `height` fields.
    /// @return | LHtmlDocument | Loaded HTML document handle.
    html.set(
        "loadDocument",
        lua.create_function(move |lua, (path, opts): (String, Option<LuaTable>)| {
            let (mut options, css_path) = parse_document_options(opts)?;
            let source = {
                let state = state_for_load.borrow();
                state.fs.read_string(&path).map_err(|e| {
                    LuaError::RuntimeError(format!(
                        "lurek.html.loadDocument: cannot read '{path}': {e}"
                    ))
                })?
            };
            if options.css.is_none() {
                if let Some(css_path) = css_path {
                    let css = {
                        let state = state_for_load.borrow();
                        state.fs.read_string(&css_path).map_err(|e| {
                            LuaError::RuntimeError(format!(
                                "lurek.html.loadDocument: cannot read cssPath '{css_path}': {e}"
                            ))
                        })?
                    };
                    options.css = Some(css);
                } else if let Some(css_companion) = companion_css_path(&path) {
                    let css = {
                        let state = state_for_load.borrow();
                        state.fs.read_string(&css_companion)
                    };
                    if let Ok(css) = css {
                        options.css = Some(css);
                    }
                }
            }
            lua.create_userdata(LuaHtmlDocument::new(
                HtmlDocument::with_options(source, options),
                state_for_load.clone(),
            ))
        })?,
    )?;
    // -- supports --
    /// Returns whether the HTML engine supports a named feature.
    /// @param | feature | string | Feature name to query.
    /// @return | boolean | True when the feature is supported.
    html.set(
        "supports",
        lua.create_function(|_, feature: String| Ok(HtmlDocument::supports(&feature)))?,
    )?;
    /// Performs the 'html' operation.
    /// @return | nil | No value is returned.
    luna.set("html", html)?;
    Ok(())
}
