//! `lurek.html` — Lightweight pure-Rust HTML/CSS layout engine Lua bindings.
//!
//! Thin Lua wrapper for `crate::html`. Exposes `HtmlDocument` and `HtmlElement`
//! as userdata and registers `lurek.html.newDocument`, `lurek.html.loadDocument`,
//! and `lurek.html.supports` as module-level constructors.

use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use crate::html::{HtmlDocument, HtmlDocumentOptions, HtmlElementId};

// -------------------------------------------------------------------------------
// LuaHtmlDocument / LuaHtmlElement — lurek.html wrappers
// -------------------------------------------------------------------------------

/// Lua wrapper around a shared `HtmlDocument` and its callback registry.
#[derive(Clone)]
struct LuaHtmlDocument {
    inner: Rc<RefCell<HtmlDocument>>,
    callbacks: Rc<RefCell<HtmlCallbacks>>,
}

impl LuaHtmlDocument {
    /// Creates a new Lua-facing document from an owned `HtmlDocument`.
    fn new(document: HtmlDocument) -> Self {
        Self {
            inner: Rc::new(RefCell::new(document)),
            callbacks: Rc::new(RefCell::new(HtmlCallbacks::default())),
        }
    }

    /// Returns a Lua-facing handle to one element inside this document.
    fn element_handle(&self, element_id: HtmlElementId) -> LuaHtmlElement {
        LuaHtmlElement {
            document: self.inner.clone(),
            callbacks: self.callbacks.clone(),
            element_id,
            generation: self.inner.borrow().generation(),
        }
    }
}

/// Lua wrapper that references a single element inside a shared `HtmlDocument`.
#[derive(Clone)]
struct LuaHtmlElement {
    document: Rc<RefCell<HtmlDocument>>,
    callbacks: Rc<RefCell<HtmlCallbacks>>,
    element_id: HtmlElementId,
    generation: u64,
}

/// Per-document event callback registry keyed by auto-incrementing handle ids.
#[derive(Default)]
struct HtmlCallbacks {
    /// Monotonic handle counter.
    next_handle: u64,
    /// Document-level event listeners.
    document: HashMap<u64, HtmlListener>,
    /// Per-element event listeners.
    elements: HashMap<HtmlElementId, HashMap<u64, HtmlListener>>,
}

/// One registered Lua callback for a specific event name.
struct HtmlListener {
    /// The DOM event name this listener responds to (e.g. `"click"`, `"keydown"`).
    event: String,
    /// Registry key for the Lua callback function.
    key: LuaRegistryKey,
}

/// Mutable flags shared across an event dispatch cycle.
#[derive(Default)]
struct HtmlEventFlags {
    /// Whether `event.preventDefault()` was called.
    default_prevented: bool,
    /// Whether `event.stopPropagation()` was called.
    propagation_stopped: bool,
}

/// Data payload attached to a dispatched HTML event.
#[derive(Default)]
struct HtmlEventPayload {
    /// Mouse X coordinate, if applicable.
    x: Option<f32>,
    /// Mouse Y coordinate, if applicable.
    y: Option<f32>,
    /// Mouse button index, if applicable.
    button: Option<u32>,
    /// Keyboard key name, if applicable.
    key: Option<String>,
    /// Raw text input, if applicable.
    text: Option<String>,
    /// Current input value, if applicable.
    value: Option<String>,
}

// -------------------------------------------------------------------------------
// impl LuaUserData for LuaHtmlDocument
// -------------------------------------------------------------------------------

impl LuaUserData for LuaHtmlDocument {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- setHtml --
        /// Replaces this document's markup and invalidates existing element handles.
        /// @param html string
        /// @return nil
        methods.add_method("setHtml", |_, this, html: String| {
            this.inner.borrow_mut().set_html(html);
            Ok(())
        });

        // -- getHtml --
        /// Returns the source markup used by this document.
        /// @return string
        methods.add_method("getHtml", |_, this, ()| {
            Ok(this.inner.borrow().get_html().to_string())
        });

        // -- setCss --
        /// Replaces this document's stylesheet text.
        /// @param css string
        /// @return nil
        methods.add_method("setCss", |_, this, css: String| {
            this.inner.borrow_mut().set_css(css);
            Ok(())
        });

        // -- addCss --
        /// Appends stylesheet text after existing CSS rules.
        /// @param css string
        /// @return nil
        methods.add_method("addCss", |_, this, css: String| {
            this.inner.borrow_mut().add_css(css);
            Ok(())
        });

        // -- clearCss --
        /// Removes all stylesheet rules from this document.
        /// @return nil
        methods.add_method("clearCss", |_, this, ()| {
            this.inner.borrow_mut().clear_css();
            Ok(())
        });

        // -- setViewport --
        /// Sets the document layout viewport in UI pixels.
        /// @param w number
        /// @param h number
        /// @return nil
        methods.add_method("setViewport", |_, this, (w, h): (f32, f32)| {
            this.inner.borrow_mut().set_viewport(w, h);
            Ok(())
        });

        // -- getViewport --
        /// Returns the document layout viewport in UI pixels.
        /// @return number, number
        methods.add_method("getViewport", |_, this, ()| Ok(this.inner.borrow().viewport()));

        // -- update --
        /// Advances document state and runs layout if needed.
        /// @param dt number
        /// @return nil
        methods.add_method("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        // -- draw --
        /// Builds the current draw command list and discards it for now.
        /// @param x number?
        /// @param y number?
        /// @return nil
        methods.add_method("draw", |_, this, (x, y): (Option<f32>, Option<f32>)| {
            this.inner
                .borrow_mut()
                .draw_commands(x.unwrap_or(0.0), y.unwrap_or(0.0));
            Ok(())
        });

        // -- relayout --
        /// Forces a layout pass immediately.
        /// @return nil
        methods.add_method("relayout", |_, this, ()| {
            this.inner.borrow_mut().relayout();
            Ok(())
        });

        // -- isDirty --
        /// Returns whether DOM, CSS, viewport, or layout state changed.
        /// @return boolean
        methods.add_method("isDirty", |_, this, ()| Ok(this.inner.borrow().is_dirty()));

        // -- getRoot --
        /// Returns the root element for this document.
        /// @return HtmlElement
        methods.add_method("getRoot", |lua, this, ()| {
            lua.create_userdata(this.element_handle(this.inner.borrow().root()))
        });

        // -- getElementById --
        /// Finds one element by id.
        /// @param id string
        /// @return HtmlElement?
        methods.add_method("getElementById", |lua, this, id: String| {
            html_element_value(lua, this, this.inner.borrow().get_element_by_id(&id))
        });

        // -- query --
        /// Finds the first element matching a supported selector.
        /// @param selector string
        /// @return HtmlElement?
        methods.add_method("query", |lua, this, selector: String| {
            html_element_value(lua, this, this.inner.borrow().query(&selector))
        });

        // -- queryAll --
        /// Returns all elements matching a supported selector in document order.
        /// @param selector string
        /// @return table
        methods.add_method("queryAll", |lua, this, selector: String| {
            html_element_table(lua, this, this.inner.borrow().query_all(&selector))
        });

        // -- on --
        /// Registers a document-level event listener.
        /// @param event string
        /// @param fn function
        /// @return integer
        methods.add_method("on", |lua, this, (event, func): (String, LuaFunction)| {
            let key = lua.create_registry_value(func)?;
            let mut callbacks = this.callbacks.borrow_mut();
            let handle = callbacks.next_handle.saturating_add(1);
            callbacks.next_handle = handle;
            callbacks.document.insert(handle, HtmlListener { event, key });
            Ok(handle)
        });

        // -- off --
        /// Removes a document-level event listener.
        /// @param handle integer
        /// @return nil
        methods.add_method("off", |lua, this, handle: u64| {
            if let Some(listener) = this.callbacks.borrow_mut().document.remove(&handle) {
                lua.remove_registry_value(listener.key)?;
            }
            Ok(())
        });

        // -- mousepressed --
        /// Forwards a mouse press and emits a minimal click event.
        /// @param x number
        /// @param y number
        /// @param button integer?
        /// @return boolean
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
        /// Forwards a mouse release event.
        /// @param x number
        /// @param y number
        /// @param button integer?
        /// @return boolean
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
        /// Forwards a mouse move event.
        /// @param x number
        /// @param y number
        /// @return boolean
        methods.add_method("mousemoved", |_, this, (x, y): (f32, f32)| {
            Ok(this.inner.borrow_mut().mouse_moved(x, y).is_some())
        });

        // -- wheelmoved --
        /// Forwards a mouse wheel event.
        /// @param dx number
        /// @param dy number
        /// @return boolean
        methods.add_method("wheelmoved", |_, this, (dx, dy): (f32, f32)| {
            Ok(this.inner.borrow().wheel_moved(dx, dy).is_some())
        });

        // -- keypressed --
        /// Forwards a key press and emits a keydown event.
        /// @param key string
        /// @return boolean
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
        /// Forwards text input and emits an input event for focused input elements.
        /// @param text string
        /// @return boolean
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
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("LHtmlDocument"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LHtmlDocument" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// impl LuaUserData for LuaHtmlElement
// -------------------------------------------------------------------------------

impl LuaUserData for LuaHtmlElement {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getDocument --
        /// Returns the owning HtmlDocument.
        /// @return HtmlDocument
        methods.add_method("getDocument", |lua, this, ()| {
            lua.create_userdata(LuaHtmlDocument {
                inner: this.document.clone(),
                callbacks: this.callbacks.clone(),
            })
        });

        // -- getTagName --
        /// Returns this element's tag name.
        /// @return string
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
        /// Returns this element's id or nil.
        /// @return string?
        methods.add_method("getId", |_, this, ()| {
            check_html_element(this)?;
            Ok(this
                .document
                .borrow()
                .element(this.element_id)
                .and_then(|element| element.id_attribute().map(str::to_string)))
        });

        // -- setId --
        /// Sets or removes this element's id.
        /// @param id string?
        /// @return nil
        methods.add_method("setId", |_, this, id: Option<String>| {
            check_html_element(this)?;
            this.document
                .borrow_mut()
                .set_id_attribute(this.element_id, id);
            Ok(())
        });

        // -- getText --
        /// Returns this element's text content.
        /// @return string
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
        /// @param text string
        /// @return nil
        methods.add_method("setText", |_, this, text: String| {
            check_html_element(this)?;
            this.document.borrow_mut().set_text(this.element_id, text);
            Ok(())
        });

        // -- getHtml --
        /// Returns this element's inner HTML.
        /// @return string
        methods.add_method("getHtml", |_, this, ()| {
            check_html_element(this)?;
            Ok(this
                .document
                .borrow()
                .element_html(this.element_id)
                .unwrap_or_default())
        });

        // -- setHtml --
        /// Replaces this element's inner HTML.
        /// @param html string
        /// @return nil
        methods.add_method("setHtml", |_, this, html: String| {
            check_html_element(this)?;
            this.document
                .borrow_mut()
                .set_element_html(this.element_id, &html);
            Ok(())
        });

        // -- appendHtml --
        /// Appends HTML inside this element.
        /// @param html string
        /// @return nil
        methods.add_method("appendHtml", |_, this, html: String| {
            check_html_element(this)?;
            this.document
                .borrow_mut()
                .append_element_html(this.element_id, &html);
            Ok(())
        });

        // -- remove --
        /// Removes this element from the document tree.
        /// @return nil
        methods.add_method("remove", |_, this, ()| {
            check_html_element(this)?;
            this.document.borrow_mut().remove_element(this.element_id);
            Ok(())
        });

        // -- getAttribute --
        /// Returns an attribute value or nil.
        /// @param name string
        /// @return string?
        methods.add_method("getAttribute", |_, this, name: String| {
            check_html_element(this)?;
            Ok(this
                .document
                .borrow()
                .element(this.element_id)
                .and_then(|element| element.attribute(&name).map(str::to_string)))
        });

        // -- setAttribute --
        /// Sets or removes an attribute value.
        /// @param name string
        /// @param value string?
        /// @return nil
        methods.add_method("setAttribute", |_, this, (name, value): (String, Option<String>)| {
            check_html_element(this)?;
            this.document
                .borrow_mut()
                .set_attribute(this.element_id, &name, value);
            Ok(())
        });

        // -- removeAttribute --
        /// Removes an attribute.
        /// @param name string
        /// @return nil
        methods.add_method("removeAttribute", |_, this, name: String| {
            check_html_element(this)?;
            this.document
                .borrow_mut()
                .set_attribute(this.element_id, &name, None);
            Ok(())
        });

        // -- hasClass --
        /// Returns whether this element has a CSS class.
        /// @param name string
        /// @return boolean
        methods.add_method("hasClass", |_, this, name: String| {
            check_html_element(this)?;
            Ok(this
                .document
                .borrow()
                .element(this.element_id)
                .is_some_and(|element| element.has_class(&name)))
        });

        // -- addClass --
        /// Adds a CSS class to this element.
        /// @param name string
        /// @return nil
        methods.add_method("addClass", |_, this, name: String| {
            check_html_element(this)?;
            this.document.borrow_mut().add_class(this.element_id, &name);
            Ok(())
        });

        // -- removeClass --
        /// Removes a CSS class from this element.
        /// @param name string
        /// @return nil
        methods.add_method("removeClass", |_, this, name: String| {
            check_html_element(this)?;
            this.document
                .borrow_mut()
                .remove_class(this.element_id, &name);
            Ok(())
        });

        // -- toggleClass --
        /// Toggles a CSS class and returns the final state.
        /// @param name string
        /// @param force boolean?
        /// @return boolean
        methods.add_method("toggleClass", |_, this, (name, force): (String, Option<bool>)| {
            check_html_element(this)?;
            Ok(this
                .document
                .borrow_mut()
                .toggle_class(this.element_id, &name, force)
                .unwrap_or(false))
        });

        // -- getStyle --
        /// Returns an inline or stylesheet value for a property.
        /// @param name string
        /// @return string?
        methods.add_method("getStyle", |_, this, name: String| {
            check_html_element(this)?;
            Ok(this.document.borrow().style_value(this.element_id, &name))
        });

        // -- setStyle --
        /// Sets or removes an inline style value.
        /// @param name string
        /// @param value string?
        /// @return nil
        methods.add_method("setStyle", |_, this, (name, value): (String, Option<String>)| {
            check_html_element(this)?;
            this.document
                .borrow_mut()
                .set_style(this.element_id, &name, value);
            Ok(())
        });

        // -- getRect --
        /// Returns this element's last computed layout rectangle.
        /// @return number, number, number, number
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
        /// Gives focus to this element.
        /// @return nil
        methods.add_method("focus", |_, this, ()| {
            check_html_element(this)?;
            this.document.borrow_mut().focus(this.element_id);
            Ok(())
        });

        // -- blur --
        /// Clears focus from this element if it currently has focus.
        /// @return nil
        methods.add_method("blur", |_, this, ()| {
            check_html_element(this)?;
            this.document.borrow_mut().blur(this.element_id);
            Ok(())
        });

        // -- query --
        /// Finds the first descendant matching a selector.
        /// @param selector string
        /// @return HtmlElement?
        methods.add_method("query", |lua, this, selector: String| {
            check_html_element(this)?;
            let document = LuaHtmlDocument {
                inner: this.document.clone(),
                callbacks: this.callbacks.clone(),
            };
            html_element_value(
                lua,
                &document,
                this.document.borrow().query_from(this.element_id, &selector),
            )
        });

        // -- queryAll --
        /// Returns all descendants matching a selector.
        /// @param selector string
        /// @return table
        methods.add_method("queryAll", |lua, this, selector: String| {
            check_html_element(this)?;
            let document = LuaHtmlDocument {
                inner: this.document.clone(),
                callbacks: this.callbacks.clone(),
            };
            html_element_table(
                lua,
                &document,
                this.document.borrow().query_all_from(this.element_id, &selector),
            )
        });

        // -- on --
        /// Registers an element event listener.
        /// @param event string
        /// @param fn function
        /// @return integer
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
        /// Removes an element event listener.
        /// @param handle integer
        /// @return nil
        methods.add_method("off", |lua, this, handle: u64| {
            if let Some(listeners) = this.callbacks.borrow_mut().elements.get_mut(&this.element_id) {
                if let Some(listener) = listeners.remove(&handle) {
                    lua.remove_registry_value(listener.key)?;
                }
            }
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("LHtmlElement"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LHtmlElement" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// Helper functions
// -------------------------------------------------------------------------------

/// Wraps an optional element id into a Lua userdata value or nil.
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

/// Wraps a vector of element ids into a Lua table of userdata.
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

/// Validates that an element handle still points to a live element and the document
/// generation has not changed since the handle was created.
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

/// Dispatches an HTML event through the bubble chain and document-level listeners,
/// returning `true` if any callback was invoked or default was prevented.
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

/// Collects all registered listeners for a specific element and event name.
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

/// Collects all registered document-level listeners for a specific event name.
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

/// Builds the Lua event table passed to listener callbacks, with `preventDefault`,
/// `stopPropagation`, and `isDefaultPrevented` methods.
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
    table.set("type", event_name)?;
    table.set("document", document.clone())?;
    if let Some(target_id) = target {
        table.set("target", document.element_handle(target_id))?;
    }
    match current_target {
        Some(current_target) => table.set("currentTarget", document.element_handle(current_target))?,
        None => table.set("currentTarget", document.clone())?,
    }
    if let Some(x) = payload.x {
        table.set("x", x)?;
    }
    if let Some(y) = payload.y {
        table.set("y", y)?;
    }
    if let Some(button) = payload.button {
        table.set("button", button)?;
    }
    if let Some(key) = &payload.key {
        table.set("key", key.clone())?;
    }
    if let Some(text) = &payload.text {
        table.set("text", text.clone())?;
    }
    if let Some(value) = &payload.value {
        table.set("value", value.clone())?;
    }
    let prevent_flags = flags.clone();
    /// Prevents the default browser action associated with this event.
    table.set(
        "preventDefault",
        lua.create_function(move |_, ()| {
            prevent_flags.borrow_mut().default_prevented = true;
            Ok(())
        })?,
    )?;
    let stop_flags = flags.clone();
    /// Stops the event from bubbling up to parent elements.
    table.set(
        "stopPropagation",
        lua.create_function(move |_, ()| {
            stop_flags.borrow_mut().propagation_stopped = true;
            Ok(())
        })?,
    )?;
    /// Returns true if `preventDefault` has been called on this event.
    /// @return boolean
    table.set(
        "isDefaultPrevented",
        lua.create_function(move |_, ()| Ok(flags.borrow().default_prevented))?,
    )?;
    Ok(table)
}

// -------------------------------------------------------------------------------
// register — lurek.html module-level constructors
// -------------------------------------------------------------------------------

/// Registers the `lurek.html` module table with `newDocument`, `loadDocument`, and `supports`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let html = lua.create_table()?;

    // -- newDocument --
    /// Creates a detached HTML document from markup and optional CSS/viewport options.
    /// @param html string
    /// @param opts table?
    /// @return HtmlDocument
    html.set(
        "newDocument",
        lua.create_function(|lua, (source, opts): (Option<String>, Option<LuaTable>)| {
            let mut options = HtmlDocumentOptions::default();
            if let Some(opts) = opts {
                options.css = opts.get::<_, Option<String>>("css")?;
                if let Some(width) = opts.get::<_, Option<f32>>("width")? {
                    options.width = width;
                }
                if let Some(height) = opts.get::<_, Option<f32>>("height")? {
                    options.height = height;
                }
            }
            lua.create_userdata(LuaHtmlDocument::new(HtmlDocument::with_options(
                source.unwrap_or_default(),
                options,
            )))
        })?,
    )?;

    // -- loadDocument --
    /// Placeholder for future sandboxed document loading.
    /// @param path string
    /// @param opts table?
    /// @return HtmlDocument
    html.set(
        "loadDocument",
        lua.create_function(
            |_, (_path, _opts): (String, Option<LuaTable>)| -> LuaResult<LuaAnyUserData> {
                Err(LuaError::RuntimeError(
                    "lurek.html.loadDocument is not yet implemented; use newDocument with inline content for now".to_string(),
                ))
            },
        )?,
    )?;

    // -- supports --
    /// Returns whether the active HTML facade supports a named feature.
    /// @param feature string
    /// @return boolean
    html.set(
        "supports",
        lua.create_function(|_, feature: String| Ok(HtmlDocument::supports(&feature)))?,
    )?;

    luna.set("html", html)?;
    Ok(())
}
