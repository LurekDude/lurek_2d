-- content/examples/html.lua
-- Hand-written coverage of the lurek.html API.
--
-- Every --@api-stub: block below demonstrates one lurek.html function
-- with realistic game UI context. Run headless or with window.
--
-- Run: cargo run -- content/examples/html.lua

-- Guard: skip in headless test VMs where html is unavailable.
if not lurek.html or type(lurek.html.newDocument) ~= "function" then return end

-- ============================================================================
-- Module functions
-- ============================================================================

--@api-stub: lurek.html.newDocument
-- Create a simple HUD overlay document from an HTML string.
-- Attach the returned document to the render pipeline to draw it each frame.
local hud = lurek.html.newDocument([[
<body>
  <div id="score" class="hud-item">Score: 0</div>
  <div id="lives" class="hud-item">♥♥♥</div>
</body>
]], {
    css = [[
        .hud-item { color: white; font-size: 24px; padding: 8px; }
        #score { text-align: right; }
    ]],
    width = 800,
    height = 600,
})

--@api-stub: lurek.html.loadDocument
-- Load an HTML UI from a file in the game directory.
-- local menu = lurek.html.loadDocument("ui/main_menu.html", { css = "body { background-color: #111; }" })

--@api-stub: lurek.html.supports
-- Check if CSS flexbox is supported by the active backend.
local hasFlex = lurek.html.supports("css-flex")
print("CSS flex supported:", hasFlex)
local hasGrid = lurek.html.supports("css-grid")

-- ============================================================================
-- HtmlDocument methods
-- ============================================================================

--@api-stub: HtmlDocument:setHtml
-- Replace the document markup entirely.
hud:setHtml([[<body><div id="score">Score: 100</div></body>]])

--@api-stub: HtmlDocument:getHtml
-- Read back the current document markup.
local markup = hud:getHtml()

--@api-stub: HtmlDocument:setCss
-- Replace all stylesheets.
hud:setCss("body { margin: 0; } .hud-item { font-size: 20px; }")

--@api-stub: HtmlDocument:addCss
-- Append additional CSS rules.
hud:addCss("#score { color: yellow; }")

--@api-stub: HtmlDocument:clearCss
-- Remove all CSS.
hud:clearCss()

--@api-stub: HtmlDocument:setViewport
-- Resize the layout viewport.
hud:setViewport(1920, 1080)

--@api-stub: HtmlDocument:getViewport
-- Read the current viewport dimensions.
local w, h = hud:getViewport()
print("Viewport:", w, "x", h)

--@api-stub: HtmlDocument:update
-- Tick the document (timers, event dispatch).
hud:update(1 / 60)

--@api-stub: HtmlDocument:draw
-- Render the document at (0, 0).
-- hud:draw(0, 0)  -- requires graphics context

--@api-stub: HtmlDocument:relayout
-- Force an immediate layout pass.
hud:relayout()

--@api-stub: HtmlDocument:isDirty
-- Check if the document needs relayout.
local dirty = hud:isDirty()

--@api-stub: HtmlDocument:getRoot
-- Get the root <body> element.
local root = hud:getRoot()
print("Root tag:", root:getTagName())

--@api-stub: HtmlDocument:getElementById
-- Look up an element by its id attribute.
local scoreEl = hud:getElementById("score")
if scoreEl then
    print("Found score element")
end

--@api-stub: HtmlDocument:query
-- Query the first element matching a CSS selector.
local first = hud:query(".hud-item")

--@api-stub: HtmlDocument:queryAll
-- Query all elements matching a CSS selector.
local items = hud:queryAll(".hud-item")
print("HUD items:", #items)

--@api-stub: HtmlDocument:on
-- Register a document-level click listener.
local handle = hud:on("click", function(ev)
    print("Document clicked at", ev.x, ev.y)
end)

--@api-stub: HtmlDocument:off
-- Remove a previously registered listener.
hud:off(handle)

--@api-stub: HtmlDocument:mousepressed
-- Forward a mouse press to the document.
local consumed = hud:mousepressed(100, 200, 1)

--@api-stub: HtmlDocument:mousereleased
-- Forward a mouse release.
hud:mousereleased(100, 200, 1)

--@api-stub: HtmlDocument:mousemoved
-- Forward mouse movement.
hud:mousemoved(110, 205)

--@api-stub: HtmlDocument:wheelmoved
-- Forward mouse wheel.
hud:wheelmoved(0, -3)

--@api-stub: HtmlDocument:keypressed
-- Forward a key press.
hud:keypressed("return")

--@api-stub: HtmlDocument:textinput
-- Forward text input.
hud:textinput("a")

-- ============================================================================
-- HtmlElement methods
-- ============================================================================

-- Reset document for element tests.
hud:setHtml([[
<body>
  <div id="header" class="bar top-bar">
    <span id="title">My Game</span>
  </div>
  <div id="content">
    <p class="info">Welcome!</p>
    <button id="btn-start" class="primary">Start</button>
  </div>
</body>
]])
hud:setCss([[
    .bar { padding: 12px; background-color: #333; }
    .primary { background-color: #07f; color: white; padding: 8px 16px; }
]])

local header = hud:getElementById("header")
local title = hud:getElementById("title")
local btn = hud:getElementById("btn-start")

--@api-stub: HtmlElement:getDocument
-- Get the owning document from any element.
local doc = header:getDocument()

--@api-stub: HtmlElement:getTagName
-- Read the element's tag name.
print("Tag:", header:getTagName()) -- "div"

--@api-stub: HtmlElement:getId
-- Read the element's id.
print("ID:", header:getId()) -- "header"

--@api-stub: HtmlElement:setId
-- Change the element's id.
header:setId("main-header")
header:setId("header") -- restore

--@api-stub: HtmlElement:getText
-- Get text content.
print("Title:", title:getText()) -- "My Game"

--@api-stub: HtmlElement:setText
-- Set text content.
title:setText("My Awesome Game")

--@api-stub: HtmlElement:getHtml
-- Get inner HTML.
local inner = header:getHtml()

--@api-stub: HtmlElement:setHtml
-- Replace inner HTML.
-- header:setHtml('<span id="title">New Title</span>')

--@api-stub: HtmlElement:appendHtml
-- Append HTML content to the element.
-- header:appendHtml('<span class="badge">NEW</span>')

--@api-stub: HtmlElement:remove
-- Remove an element from the DOM.
-- btn:remove() -- would remove the start button

--@api-stub: HtmlElement:getAttribute
-- Read a custom attribute.
local val = btn:getAttribute("class")

--@api-stub: HtmlElement:setAttribute
-- Set a custom attribute.
btn:setAttribute("data-action", "start-game")

--@api-stub: HtmlElement:removeAttribute
-- Remove an attribute.
btn:removeAttribute("data-action")

--@api-stub: HtmlElement:hasClass
-- Check if an element has a CSS class.
print("Has primary?", btn:hasClass("primary")) -- true

--@api-stub: HtmlElement:addClass
-- Add a CSS class.
btn:addClass("large")

--@api-stub: HtmlElement:removeClass
-- Remove a CSS class.
btn:removeClass("large")

--@api-stub: HtmlElement:toggleClass
-- Toggle a CSS class.
local nowHas = btn:toggleClass("active")

--@api-stub: HtmlElement:getStyle
-- Read an inline style property.
local bg = btn:getStyle("background-color")

--@api-stub: HtmlElement:setStyle
-- Set an inline style property.
btn:setStyle("font-size", "18px")

--@api-stub: HtmlElement:getRect
-- Get the element's computed layout rectangle.
local x, y, w, h = btn:getRect()
print("Button rect:", x, y, w, h)

--@api-stub: HtmlElement:focus
-- Focus the element.
btn:focus()

--@api-stub: HtmlElement:blur
-- Remove focus from the element.
btn:blur()

--@api-stub: HtmlElement:query
-- Find a child element by selector.
local info = hud:getRoot():query(".info")

--@api-stub: HtmlElement:queryAll
-- Find all matching child elements.
local buttons = hud:getRoot():queryAll("button")
print("Buttons found:", #buttons)

--@api-stub: HtmlElement:on
-- Register an element-level event listener.
local clickHandle = btn:on("click", function(ev)
    print("Button clicked!")
end)

--@api-stub: HtmlElement:off
-- Remove an element event listener.
btn:off(clickHandle)

print("[html.lua] All API stubs executed successfully.")

-- =============================================================================
-- STUBS: 11 uncovered lurek.html API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.html.preventDefault -------------------------------------
--@api-stub: lurek.html.preventDefault
-- Prevents the default browser action for the currently dispatching event.
-- Call inside an event handler to stop links from navigating or forms from submitting.
do  -- lurek.html.preventDefault
  hud:on("click", function()
    if lurek.html.preventDefault then lurek.html.preventDefault() end
  end)
  pcall(function() hud:mousepressed(0, 0, 1) end)
end

-- ---- Stub: lurek.html.stopPropagation ------------------------------------
--@api-stub: lurek.html.stopPropagation
-- Stops the current event from bubbling up to parent elements.
-- Call inside an event handler when a child handles the event exclusively.
do  -- lurek.html.stopPropagation
  hud:on("click", function()
    if lurek.html.stopPropagation then lurek.html.stopPropagation() end
  end)
  pcall(function() hud:mousepressed(0, 0, 1) end)
end

-- ---- Stub: lurek.html.isDefaultPrevented ---------------------------------
--@api-stub: lurek.html.isDefaultPrevented
-- Returns true if preventDefault() was called on the currently dispatching event.
-- Use mid-handler to decide whether subsequent actions should still run.
do  -- lurek.html.isDefaultPrevented
  hud:on("click", function()
    if lurek.html.preventDefault then lurek.html.preventDefault() end
    local stopped = lurek.html.isDefaultPrevented and lurek.html.isDefaultPrevented() or false
    lurek.log.info("prevented=" .. tostring(stopped), "html")
  end)
  pcall(function() hud:mousepressed(0, 0, 1) end)
end

-- ---- Stub: lurek.html.loadDocument ---------------------------------------
--@api-stub: lurek.html.loadDocument
-- Loads an HTML document from a file path, applying optional CSS overrides.
-- Returns an HtmlDocument on success; use pcall since the file may not exist.
do  -- lurek.html.loadDocument
  local ok, doc = pcall(lurek.html.loadDocument, "ui/hud.html")
  if ok and doc then
    lurek.log.info("loadDocument succeeded", "html")
  end
end

-- -----------------------------------------------------------------------------
-- HtmlDocument methods
-- -----------------------------------------------------------------------------

-- ---- Stub: HtmlDocument:draw ---------------------------------------------
--@api-stub: HtmlDocument:draw
-- Builds the current draw command list and discards it for now.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- htmlDocument_stub:draw([x], [y])
-- (replace htmlDocument_stub with your real HtmlDocument instance above)

-- ---- Stub: HtmlDocument:type ---------------------------------------------
--@api-stub: HtmlDocument:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- htmlDocument_stub:type()  -- -> string
-- (replace htmlDocument_stub with your real HtmlDocument instance above)

-- ---- Stub: HtmlDocument:typeOf -------------------------------------------
--@api-stub: HtmlDocument:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- htmlDocument_stub:typeOf("hero")  -- -> boolean
-- (replace htmlDocument_stub with your real HtmlDocument instance above)

-- -----------------------------------------------------------------------------
-- HtmlElement methods
-- -----------------------------------------------------------------------------

-- ---- Stub: HtmlElement:appendHtml ----------------------------------------
--@api-stub: HtmlElement:appendHtml
-- Appends HTML inside this element.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- htmlElement_stub:appendHtml(html)
-- (replace htmlElement_stub with your real HtmlElement instance above)

-- ---- Stub: HtmlElement:remove --------------------------------------------
--@api-stub: HtmlElement:remove
-- Removes this element from the document tree.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- htmlElement_stub:remove()
-- (replace htmlElement_stub with your real HtmlElement instance above)

-- ---- Stub: HtmlElement:type ----------------------------------------------
--@api-stub: HtmlElement:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- htmlElement_stub:type()  -- -> string
-- (replace htmlElement_stub with your real HtmlElement instance above)

-- ---- Stub: HtmlElement:typeOf --------------------------------------------
--@api-stub: HtmlElement:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- htmlElement_stub:typeOf("hero")  -- -> boolean
-- (replace htmlElement_stub with your real HtmlElement instance above)

-- =============================================================================
-- STUBS: 8 uncovered lurek.html API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.html.loadDocument ---------------------------------------
--@api-stub: lurek.html.loadDocument
-- Placeholder for future sandboxed document loading.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.html.loadDocument("assets/hero.png", [opts])  -- -> HtmlDocument

-- -----------------------------------------------------------------------------
-- LHtmlDocument methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LHtmlDocument:draw --------------------------------------------
--@api-stub: LHtmlDocument:draw
-- Builds the current draw command list and discards it for now.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:draw([x], [y])
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:type --------------------------------------------
--@api-stub: LHtmlDocument:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:type()  -- -> string
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:typeOf ------------------------------------------
--@api-stub: LHtmlDocument:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:typeOf("hero")  -- -> boolean
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- -----------------------------------------------------------------------------
-- LHtmlElement methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LHtmlElement:appendHtml ---------------------------------------
--@api-stub: LHtmlElement:appendHtml
-- Appends HTML inside this element.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:appendHtml(html)
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:remove -------------------------------------------
--@api-stub: LHtmlElement:remove
-- Removes this element from the document tree.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:remove()
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:type ---------------------------------------------
--@api-stub: LHtmlElement:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:type()  -- -> string
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:typeOf -------------------------------------------
--@api-stub: LHtmlElement:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:typeOf("hero")  -- -> boolean
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- =============================================================================
-- STUBS: 46 uncovered lurek.html API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LHtmlDocument methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LHtmlDocument:setHtml -----------------------------------------
--@api-stub: LHtmlDocument:setHtml
-- Replaces this document's markup and invalidates existing element handles.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:setHtml(html)
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:getHtml -----------------------------------------
--@api-stub: LHtmlDocument:getHtml
-- Returns the source markup used by this document.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:getHtml()  -- -> string
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:setCss ------------------------------------------
--@api-stub: LHtmlDocument:setCss
-- Replaces this document's stylesheet text.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:setCss(css)
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:addCss ------------------------------------------
--@api-stub: LHtmlDocument:addCss
-- Appends stylesheet text after existing CSS rules.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:addCss(css)
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:clearCss ----------------------------------------
--@api-stub: LHtmlDocument:clearCss
-- Removes all stylesheet rules from this document.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:clearCss()
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:setViewport -------------------------------------
--@api-stub: LHtmlDocument:setViewport
-- Sets the document layout viewport in UI pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:setViewport(64.0, 64.0)
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:getViewport -------------------------------------
--@api-stub: LHtmlDocument:getViewport
-- Returns the document layout viewport in UI pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:getViewport()  -- -> number, number
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:update ------------------------------------------
--@api-stub: LHtmlDocument:update
-- Advances document state and runs layout if needed.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:update(0.016)
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:relayout ----------------------------------------
--@api-stub: LHtmlDocument:relayout
-- Forces a layout pass immediately.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:relayout()
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:isDirty -----------------------------------------
--@api-stub: LHtmlDocument:isDirty
-- Returns whether DOM, CSS, viewport, or layout state changed.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:isDirty()  -- -> boolean
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:getRoot -----------------------------------------
--@api-stub: LHtmlDocument:getRoot
-- Returns the root element for this document.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:getRoot()  -- -> HtmlElement
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:getElementById ----------------------------------
--@api-stub: LHtmlDocument:getElementById
-- Finds the first element whose id attribute matches the given value, or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:getElementById(1)  -- -> HtmlElement?
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:query -------------------------------------------
--@api-stub: LHtmlDocument:query
-- Finds the first element matching a supported selector.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:query(selector)  -- -> HtmlElement?
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:queryAll ----------------------------------------
--@api-stub: LHtmlDocument:queryAll
-- Returns all elements matching a supported selector in document order.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:queryAll(selector)  -- -> table
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:on ----------------------------------------------
--@api-stub: LHtmlDocument:on
-- Registers a document-level event listener.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:on(event, func)  -- -> integer
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:off ---------------------------------------------
--@api-stub: LHtmlDocument:off
-- Removes a document-level event listener.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:off(handle)
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:mousepressed ------------------------------------
--@api-stub: LHtmlDocument:mousepressed
-- Forwards a mouse press and emits a minimal click event.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:mousepressed(0.0, 0.0, [button])  -- -> boolean
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:mousereleased -----------------------------------
--@api-stub: LHtmlDocument:mousereleased
-- Forwards a mouse release event.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:mousereleased(0.0, 0.0, [button])  -- -> boolean
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:mousemoved --------------------------------------
--@api-stub: LHtmlDocument:mousemoved
-- Forwards a mouse move event.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:mousemoved(0.0, 0.0)  -- -> boolean
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:wheelmoved --------------------------------------
--@api-stub: LHtmlDocument:wheelmoved
-- Forwards a mouse wheel event.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:wheelmoved(dx, dy)  -- -> boolean
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:keypressed --------------------------------------
--@api-stub: LHtmlDocument:keypressed
-- Forwards a key press and emits a keydown event.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:keypressed("player_score")  -- -> boolean
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- ---- Stub: LHtmlDocument:textinput ---------------------------------------
--@api-stub: LHtmlDocument:textinput
-- Forwards text input and emits an input event for focused input elements.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlDocument_stub:textinput("Hello, world!")  -- -> boolean
-- (replace lHtmlDocument_stub with your real LHtmlDocument instance above)

-- -----------------------------------------------------------------------------
-- LHtmlElement methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LHtmlElement:getDocument --------------------------------------
--@api-stub: LHtmlElement:getDocument
-- Returns the owning HtmlDocument.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:getDocument()  -- -> HtmlDocument
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:getTagName ---------------------------------------
--@api-stub: LHtmlElement:getTagName
-- Returns this element's tag name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:getTagName()  -- -> string
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:getId --------------------------------------------
--@api-stub: LHtmlElement:getId
-- Returns this element's id or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:getId()  -- -> string?
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:setId --------------------------------------------
--@api-stub: LHtmlElement:setId
-- Sets or removes this element's id.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:setId([id])
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:getText ------------------------------------------
--@api-stub: LHtmlElement:getText
-- Returns this element's text content.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:getText()  -- -> string
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:setText ------------------------------------------
--@api-stub: LHtmlElement:setText
-- Replaces this element's text content.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:setText("Hello, world!")
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:getHtml ------------------------------------------
--@api-stub: LHtmlElement:getHtml
-- Returns this element's inner HTML.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:getHtml()  -- -> string
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:setHtml ------------------------------------------
--@api-stub: LHtmlElement:setHtml
-- Replaces this element's inner HTML.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:setHtml(html)
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:getAttribute -------------------------------------
--@api-stub: LHtmlElement:getAttribute
-- Returns an attribute value or nil.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:getAttribute("hero")  -- -> string?
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:setAttribute -------------------------------------
--@api-stub: LHtmlElement:setAttribute
-- Sets or removes an attribute value.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:setAttribute("hero", [value])
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:removeAttribute ----------------------------------
--@api-stub: LHtmlElement:removeAttribute
-- Removes the named attribute from this element; does nothing if absent.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:removeAttribute("hero")
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:hasClass -----------------------------------------
--@api-stub: LHtmlElement:hasClass
-- Returns whether this element has a CSS class.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:hasClass("hero")  -- -> boolean
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:addClass -----------------------------------------
--@api-stub: LHtmlElement:addClass
-- Adds a CSS class to this element.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:addClass("hero")
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:removeClass --------------------------------------
--@api-stub: LHtmlElement:removeClass
-- Removes a CSS class from this element.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:removeClass("hero")
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:toggleClass --------------------------------------
--@api-stub: LHtmlElement:toggleClass
-- Toggles a CSS class and returns the final state.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:toggleClass("hero", [force])  -- -> boolean
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:getStyle -----------------------------------------
--@api-stub: LHtmlElement:getStyle
-- Returns an inline or stylesheet value for a property.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:getStyle("hero")  -- -> string?
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:setStyle -----------------------------------------
--@api-stub: LHtmlElement:setStyle
-- Sets or removes an inline style value.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:setStyle("hero", [value])
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:getRect ------------------------------------------
--@api-stub: LHtmlElement:getRect
-- Returns this element's last computed layout rectangle.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:getRect()  -- -> number, number, number, number
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:focus --------------------------------------------
--@api-stub: LHtmlElement:focus
-- Gives focus to this element.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:focus()
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:blur ---------------------------------------------
--@api-stub: LHtmlElement:blur
-- Clears focus from this element if it currently has focus.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:blur()
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:query --------------------------------------------
--@api-stub: LHtmlElement:query
-- Finds the first descendant matching a selector.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:query(selector)  -- -> HtmlElement?
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:queryAll -----------------------------------------
--@api-stub: LHtmlElement:queryAll
-- Returns all descendants matching a selector.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:queryAll(selector)  -- -> table
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:on -----------------------------------------------
--@api-stub: LHtmlElement:on
-- Registers an element event listener.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:on(event, func)  -- -> integer
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)

-- ---- Stub: LHtmlElement:off ----------------------------------------------
--@api-stub: LHtmlElement:off
-- Removes an element event listener.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lHtmlElement_stub:off(handle)
-- (replace lHtmlElement_stub with your real LHtmlElement instance above)
