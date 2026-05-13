use super::SharedState;
use crate::html::{parse_css_color_rgba, HtmlDocument, HtmlDocumentOptions, HtmlElementId};
use crate::render::{DrawMode, RenderCommand};
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::path::Path;
use std::rc::Rc;
#[derive(Clone)]
struct LuaHtmlDocument {
    inner: Rc<RefCell<HtmlDocument>>,
    callbacks: Rc<RefCell<HtmlCallbacks>>,
    state: Rc<RefCell<SharedState>>,
}
impl LuaHtmlDocument {
    fn new(document: HtmlDocument, state: Rc<RefCell<SharedState>>) -> Self {
        Self {
            inner: Rc::new(RefCell::new(document)),
            callbacks: Rc::new(RefCell::new(HtmlCallbacks::default())),
            state,
        }
    }
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
struct LuaHtmlElement {
    document: Rc<RefCell<HtmlDocument>>,
    callbacks: Rc<RefCell<HtmlCallbacks>>,
    state: Rc<RefCell<SharedState>>,
    element_id: HtmlElementId,
    generation: u64,
}
#[derive(Default)]
struct HtmlCallbacks {
    next_handle: u64,
    document: HashMap<u64, HtmlListener>,
    elements: HashMap<HtmlElementId, HashMap<u64, HtmlListener>>,
}
struct HtmlListener {
    event: String,
    key: LuaRegistryKey,
}
#[derive(Default)]
struct HtmlEventFlags {
    default_prevented: bool,
    propagation_stopped: bool,
}
#[derive(Default)]
struct HtmlEventPayload {
    x: Option<f32>,
    y: Option<f32>,
    button: Option<u32>,
    key: Option<String>,
    text: Option<String>,
    value: Option<String>,
}
impl LuaUserData for LuaHtmlDocument {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("setHtml", |_, this, html: String| {
            this.inner.borrow_mut().set_html(html);
            Ok(())
        });
        methods.add_method("getHtml", |_, this, ()| {
            Ok(this.inner.borrow().get_html().to_string())
        });
        methods.add_method("setCss", |_, this, css: String| {
            this.inner.borrow_mut().set_css(css);
            Ok(())
        });
        methods.add_method("addCss", |_, this, css: String| {
            this.inner.borrow_mut().add_css(css);
            Ok(())
        });
        methods.add_method("clearCss", |_, this, ()| {
            this.inner.borrow_mut().clear_css();
            Ok(())
        });
        methods.add_method("setViewport", |_, this, (w, h): (f32, f32)| {
            this.inner.borrow_mut().set_viewport(w, h);
            Ok(())
        });
        methods.add_method("getViewport", |_, this, ()| {
            Ok(this.inner.borrow().viewport())
        });
        methods.add_method("update", |_, this, dt: f32| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });
        methods.add_method("draw", |_, this, (x, y): (Option<f32>, Option<f32>)| {
            let dx = x.unwrap_or(0.0);
            let dy = y.unwrap_or(0.0);
            let mut document = this.inner.borrow_mut();
            let mut state = this.state.borrow_mut();
            enqueue_html_draw_commands(&mut document, &mut state, dx, dy);
            Ok(())
        });
        methods.add_method("render", |_, this, (x, y): (Option<f32>, Option<f32>)| {
            let dx = x.unwrap_or(0.0);
            let dy = y.unwrap_or(0.0);
            let mut document = this.inner.borrow_mut();
            let mut state = this.state.borrow_mut();
            enqueue_html_draw_commands(&mut document, &mut state, dx, dy);
            Ok(())
        });
        methods.add_method("relayout", |_, this, ()| {
            this.inner.borrow_mut().relayout();
            Ok(())
        });
        methods.add_method("isDirty", |_, this, ()| Ok(this.inner.borrow().is_dirty()));
        methods.add_method("getRoot", |lua, this, ()| {
            lua.create_userdata(this.element_handle(this.inner.borrow().root()))
        });
        methods.add_method("getElementById", |lua, this, id: String| {
            html_element_value(lua, this, this.inner.borrow().get_element_by_id(&id))
        });
        methods.add_method("query", |lua, this, selector: String| {
            html_element_value(lua, this, this.inner.borrow().query(&selector))
        });
        methods.add_method("queryAll", |lua, this, selector: String| {
            html_element_table(lua, this, this.inner.borrow().query_all(&selector))
        });
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
        methods.add_method("off", |lua, this, handle: u64| {
            if let Some(listener) = this.callbacks.borrow_mut().document.remove(&handle) {
                lua.remove_registry_value(listener.key)?;
            }
            Ok(())
        });
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
        methods.add_method("mousemoved", |_, this, (x, y): (f32, f32)| {
            Ok(this.inner.borrow_mut().mouse_moved(x, y).is_some())
        });
        methods.add_method("wheelmoved", |_, this, (dx, dy): (f32, f32)| {
            Ok(this.inner.borrow().wheel_moved(dx, dy).is_some())
        });
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
        methods.add_method("type", |_, _, ()| Ok("LHtmlDocument"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LHtmlDocument" || name == "Object")
        });
    }
}
impl LuaUserData for LuaHtmlElement {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getDocument", |lua, this, ()| {
            lua.create_userdata(LuaHtmlDocument {
                inner: this.document.clone(),
                callbacks: this.callbacks.clone(),
                state: this.state.clone(),
            })
        });
        methods.add_method("getTagName", |_, this, ()| {
            check_html_element(this)?;
            Ok(this
                .document
                .borrow()
                .element(this.element_id)
                .map(|element| element.tag_name().to_string())
                .unwrap_or_default())
        });
        methods.add_method("getId", |_, this, ()| {
            check_html_element(this)?;
            Ok(this
                .document
                .borrow()
                .element(this.element_id)
                .and_then(|element| element.id_attribute().map(str::to_string)))
        });
        methods.add_method("setId", |_, this, id: Option<String>| {
            check_html_element(this)?;
            this.document
                .borrow_mut()
                .set_id_attribute(this.element_id, id);
            Ok(())
        });
        methods.add_method("getText", |_, this, ()| {
            check_html_element(this)?;
            Ok(this
                .document
                .borrow()
                .text(this.element_id)
                .unwrap_or_default())
        });
        methods.add_method("setText", |_, this, text: String| {
            check_html_element(this)?;
            this.document.borrow_mut().set_text(this.element_id, text);
            Ok(())
        });
        methods.add_method("getHtml", |_, this, ()| {
            check_html_element(this)?;
            Ok(this
                .document
                .borrow()
                .element_html(this.element_id)
                .unwrap_or_default())
        });
        methods.add_method("setHtml", |_, this, html: String| {
            check_html_element(this)?;
            this.document
                .borrow_mut()
                .set_element_html(this.element_id, &html);
            Ok(())
        });
        methods.add_method("appendHtml", |_, this, html: String| {
            check_html_element(this)?;
            this.document
                .borrow_mut()
                .append_element_html(this.element_id, &html);
            Ok(())
        });
        methods.add_method("remove", |_, this, ()| {
            check_html_element(this)?;
            this.document.borrow_mut().remove_element(this.element_id);
            Ok(())
        });
        methods.add_method("getAttribute", |_, this, name: String| {
            check_html_element(this)?;
            Ok(this
                .document
                .borrow()
                .element(this.element_id)
                .and_then(|element| element.attribute(&name).map(str::to_string)))
        });
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
        methods.add_method("removeAttribute", |_, this, name: String| {
            check_html_element(this)?;
            this.document
                .borrow_mut()
                .set_attribute(this.element_id, &name, None);
            Ok(())
        });
        methods.add_method("hasClass", |_, this, name: String| {
            check_html_element(this)?;
            Ok(this
                .document
                .borrow()
                .element(this.element_id)
                .is_some_and(|element| element.has_class(&name)))
        });
        methods.add_method("addClass", |_, this, name: String| {
            check_html_element(this)?;
            this.document.borrow_mut().add_class(this.element_id, &name);
            Ok(())
        });
        methods.add_method("removeClass", |_, this, name: String| {
            check_html_element(this)?;
            this.document
                .borrow_mut()
                .remove_class(this.element_id, &name);
            Ok(())
        });
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
        methods.add_method("getStyle", |_, this, name: String| {
            check_html_element(this)?;
            Ok(this.document.borrow().style_value(this.element_id, &name))
        });
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
        methods.add_method("focus", |_, this, ()| {
            check_html_element(this)?;
            this.document.borrow_mut().focus(this.element_id);
            Ok(())
        });
        methods.add_method("blur", |_, this, ()| {
            check_html_element(this)?;
            this.document.borrow_mut().blur(this.element_id);
            Ok(())
        });
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
        methods.add_method("type", |_, _, ()| Ok("LHtmlElement"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LHtmlElement" || name == "Object")
        });
    }
}
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
        Some(current_target) => {
            table.set("currentTarget", document.element_handle(current_target))?
        }
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
    table.set(
        "preventDefault",
        lua.create_function(move |_, ()| {
            prevent_flags.borrow_mut().default_prevented = true;
            Ok(())
        })?,
    )?;
    let stop_flags = flags.clone();
    table.set(
        "stopPropagation",
        lua.create_function(move |_, ()| {
            stop_flags.borrow_mut().propagation_stopped = true;
            Ok(())
        })?,
    )?;
    table.set(
        "isDefaultPrevented",
        lua.create_function(move |_, ()| Ok(flags.borrow().default_prevented))?,
    )?;
    Ok(table)
}
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
fn parse_css_color(raw: &str) -> Option<[f32; 4]> {
    parse_css_color_rgba(raw)
}
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
pub fn register(lua: &Lua, luna: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let html = lua.create_table()?;
    let state_for_new = state.clone();
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
    html.set(
        "supports",
        lua.create_function(|_, feature: String| Ok(HtmlDocument::supports(&feature)))?,
    )?;
    luna.set("html", html)?;
    Ok(())
}
