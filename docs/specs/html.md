# html — Lightweight HTML/CSS Layout Engine

> Module spec for `src/html/` and `src/lua_api/html_api.rs`.

## Overview

Standalone pure-Rust HTML/CSS layout engine exposed as `lurek.html`. Parses an RML-compatible HTML/CSS subset into a DOM tree with computed layout, styled rendering, event dispatch, and Lua callbacks. Not a browser engine — no JavaScript, no networking, no `<iframe>`.

**Tier:** Feature Systems (Tier 4).
**Dependencies:** `math` (layout arithmetic only). No GPU, no `SharedState`.
**Lua bridge:** `src/lua_api/html_api.rs` — always registered (no `modules.html` guard).

## Lua API — `lurek.html`

### Module Functions

- `lurek.html.newDocument(html, opts?) -> HtmlDocument`: creates a detached document from an HTML string. `opts` may include `css` (string), `width` (number), `height` (number), and `base_path` (string).
- `lurek.html.loadDocument(path, opts?) -> HtmlDocument`: loads a document through the game filesystem sandbox. `opts.css` may add caller-provided stylesheet text.
- `lurek.html.supports(feature) -> boolean`: returns whether the backend supports a named feature (`"css-flex"`, `"css-grid"`, `"forms"`, `"images"`, `"native-rmlui"`).

### HtmlDocument Methods

- `doc:setHtml(html)`, `doc:getHtml() -> string`: replace or return source markup.
- `doc:setCss(css)`, `doc:addCss(css)`, `doc:clearCss()`: replace, append, or clear stylesheets.
- `doc:setViewport(w, h)`, `doc:getViewport() -> w, h`: set or read viewport size.
- `doc:update(dt)`, `doc:draw(x?, y?)`: tick timers / dispatch events and draw.
- `doc:relayout()`, `doc:isDirty() -> boolean`: force layout or query dirty state.
- `doc:getRoot() -> HtmlElement`, `doc:getElementById(id) -> HtmlElement|nil`.
- `doc:query(selector) -> HtmlElement|nil`, `doc:queryAll(selector) -> table`.
- `doc:on(event, fn) -> integer`, `doc:off(handle)`: register/remove document events.
- `doc:mousepressed(x, y, btn?) -> boolean`, `doc:mousereleased(x, y, btn?) -> boolean`, `doc:mousemoved(x, y) -> boolean`, `doc:wheelmoved(dx, dy) -> boolean`, `doc:keypressed(key) -> boolean`, `doc:textinput(text) -> boolean`: forward input.

### HtmlElement Methods

- `el:getDocument() -> HtmlDocument`, `el:getTagName() -> string`, `el:getId() -> string|nil`, `el:setId(id?)`.
- `el:getText() -> string`, `el:setText(text)`, `el:getHtml() -> string`, `el:setHtml(html)`, `el:appendHtml(html)`, `el:remove()`.
- `el:getAttribute(name) -> string|nil`, `el:setAttribute(name, value?)`, `el:removeAttribute(name)`.
- `el:hasClass(name) -> boolean`, `el:addClass(name)`, `el:removeClass(name)`, `el:toggleClass(name, force?) -> boolean`.
- `el:getStyle(name) -> string|nil`, `el:setStyle(name, value?)`.
- `el:getRect() -> x, y, w, h`, `el:focus()`, `el:blur()`.
- `el:query(selector) -> HtmlElement|nil`, `el:queryAll(selector) -> table`.
- `el:on(event, fn) -> integer`, `el:off(handle)`.

### Events

Callbacks receive `{ type, target, currentTarget, document, x, y, button, key, text, value }`. Methods: `event:preventDefault()`, `event:stopPropagation()`, `event:isDefaultPrevented()`. Supported: `"click"`, `"change"`, `"input"`, `"submit"`, `"focus"`, `"blur"`, `"keydown"`, `"keyup"`, `"mouseenter"`, `"mouseleave"`.

### Supported HTML/CSS Subset

**Tags:** `body`, `div`, `span`, `p`, `button`, `input`, `label`, `img`, `ul`, `ol`, `li`, `form`, `h1`–`h6`, `br`.
**Attributes:** `id`, `class`, `style`, `data-*`, `type`, `value`, `placeholder`, `disabled`, `checked`, `src`.
**Selectors:** tag, `#id`, `.class`, descendant, child (`>`), combined (`button.primary`).
**CSS properties:** block/flex layout, absolute positioning, width/height/min/max, margin, padding, gap, border width/color/radius, background-color, color, font-size, line-height, text-align, display, overflow, pointer-events.
**Units:** `px`, `%`, unitless zero, numbers-as-px.

## Files

- `mod.rs`: Module root — re-exports `HtmlDocument`, `HtmlDocumentOptions`, `HtmlDrawCommand`, `HtmlElement`, `HtmlElementId`, `HtmlRect`.
- `document.rs`: `HtmlDocument` — DOM owner, layout engine, stylesheet manager, viewport, draw-command generation.
- `element.rs`: `HtmlElement`, `HtmlElementId`, `HtmlRect` — node representation, attribute/class/style storage, child management.
- `parser.rs`: HTML/RML string parser — produces element tree from markup.
- `selector.rs`: CSS selector parser and matching engine.
- `style.rs`: CSS property parser, cascade, computed-style resolution.

## Scope Boundary

`src/html/` is a standalone module with no dependency on `src/ui/`. The widget-based UI system (`lurek.ui`) and the HTML layout engine (`lurek.html`) are independent — games may use either, both, or neither.
