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

--@api-stub: LHtmlDocument:setHtml
-- Replace the document markup entirely.
hud:setHtml([[<body><div id="score">Score: 100</div></body>]])

--@api-stub: LHtmlDocument:getHtml
-- Read back the current document markup.
local markup = hud:getHtml()

--@api-stub: LHtmlDocument:setCss
-- Replace all stylesheets.
hud:setCss("body { margin: 0; } .hud-item { font-size: 20px; }")

--@api-stub: LHtmlDocument:addCss
-- Append additional CSS rules.
hud:addCss("#score { color: yellow; }")

--@api-stub: LHtmlDocument:clearCss
-- Remove all CSS.
hud:clearCss()

--@api-stub: LHtmlDocument:setViewport
-- Resize the layout viewport.
hud:setViewport(1920, 1080)

--@api-stub: LHtmlDocument:getViewport
-- Read the current viewport dimensions.
local w, h = hud:getViewport()
print("Viewport:", w, "x", h)

--@api-stub: LHtmlDocument:update
-- Tick the document (timers, event dispatch).
hud:update(1 / 60)

--@api-stub: LHtmlDocument:draw
-- Render the document at (0, 0).
-- hud:draw(0, 0)  -- requires graphics context

--@api-stub: LHtmlDocument:relayout
-- Force an immediate layout pass.
hud:relayout()

--@api-stub: LHtmlDocument:isDirty
-- Check if the document needs relayout.
local dirty = hud:isDirty()

--@api-stub: LHtmlDocument:getRoot
-- Get the root <body> element.
local root = hud:getRoot()
print("Root tag:", root:getTagName())

--@api-stub: LHtmlDocument:getElementById
-- Look up an element by its id attribute.
local scoreEl = hud:getElementById("score")
if scoreEl then
    print("Found score element")
end

--@api-stub: LHtmlDocument:query
-- Query the first element matching a CSS selector.
local first = hud:query(".hud-item")

--@api-stub: LHtmlDocument:queryAll
-- Query all elements matching a CSS selector.
local items = hud:queryAll(".hud-item")
print("HUD items:", #items)

--@api-stub: LHtmlDocument:on
-- Register a document-level click listener.
local handle = hud:on("click", function(ev)
    print("Document clicked at", ev.x, ev.y)
end)

--@api-stub: LHtmlDocument:off
-- Remove a previously registered listener.
hud:off(handle)

--@api-stub: LHtmlDocument:mousepressed
-- Forward a mouse press to the document.
local consumed = hud:mousepressed(100, 200, 1)

--@api-stub: LHtmlDocument:mousereleased
-- Forward a mouse release.
hud:mousereleased(100, 200, 1)

--@api-stub: LHtmlDocument:mousemoved
-- Forward mouse movement.
hud:mousemoved(110, 205)

--@api-stub: LHtmlDocument:wheelmoved
-- Forward mouse wheel.
hud:wheelmoved(0, -3)

--@api-stub: LHtmlDocument:keypressed
-- Forward a key press.
hud:keypressed("return")

--@api-stub: LHtmlDocument:textinput
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

--@api-stub: LHtmlElement:getDocument
-- Get the owning document from any element.
local doc = header:getDocument()

--@api-stub: LHtmlElement:getTagName
-- Read the element's tag name.
print("Tag:", header:getTagName()) -- "div"

--@api-stub: LHtmlElement:getId
-- Read the element's id.
print("ID:", header:getId()) -- "header"

--@api-stub: LHtmlElement:setId
-- Change the element's id.
header:setId("main-header")
header:setId("header") -- restore

--@api-stub: LHtmlElement:getText
-- Get text content.
print("Title:", title:getText()) -- "My Game"

--@api-stub: LHtmlElement:setText
-- Set text content.
title:setText("My Awesome Game")

--@api-stub: LHtmlElement:getHtml
-- Get inner HTML.
local inner = header:getHtml()

--@api-stub: LHtmlElement:setHtml
-- Replace inner HTML.
-- header:setHtml('<span id="title">New Title</span>')

--@api-stub: LHtmlElement:appendHtml
-- Append HTML content to the element.
-- header:appendHtml('<span class="badge">NEW</span>')

--@api-stub: LHtmlElement:remove
-- Remove an element from the DOM.
-- btn:remove() -- would remove the start button

--@api-stub: LHtmlElement:getAttribute
-- Read a custom attribute.
local val = btn:getAttribute("class")

--@api-stub: LHtmlElement:setAttribute
-- Set a custom attribute.
btn:setAttribute("data-action", "start-game")

--@api-stub: LHtmlElement:removeAttribute
-- Remove an attribute.
btn:removeAttribute("data-action")

--@api-stub: LHtmlElement:hasClass
-- Check if an element has a CSS class.
print("Has primary?", btn:hasClass("primary")) -- true

--@api-stub: LHtmlElement:addClass
-- Add a CSS class.
btn:addClass("large")

--@api-stub: LHtmlElement:removeClass
-- Remove a CSS class.
btn:removeClass("large")

--@api-stub: LHtmlElement:toggleClass
-- Toggle a CSS class.
local nowHas = btn:toggleClass("active")

--@api-stub: LHtmlElement:getStyle
-- Read an inline style property.
local bg = btn:getStyle("background-color")

--@api-stub: LHtmlElement:setStyle
-- Set an inline style property.
btn:setStyle("font-size", "18px")

--@api-stub: LHtmlElement:getRect
-- Get the element's computed layout rectangle.
local x, y, w, h = btn:getRect()
print("Button rect:", x, y, w, h)

--@api-stub: LHtmlElement:focus
-- Focus the element.
btn:focus()

--@api-stub: LHtmlElement:blur
-- Remove focus from the element.
btn:blur()

--@api-stub: LHtmlElement:query
-- Find a child element by selector.
local info = hud:getRoot():query(".info")

--@api-stub: LHtmlElement:queryAll
-- Find all matching child elements.
local buttons = hud:getRoot():queryAll("button")
print("Buttons found:", #buttons)

--@api-stub: LHtmlElement:on
-- Register an element-level event listener.
local clickHandle = btn:on("click", function(ev)
    print("Button clicked!")
end)

--@api-stub: LHtmlElement:off
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
-- HtmlElement methods
-- -----------------------------------------------------------------------------

-- =============================================================================
-- STUBS: 8 uncovered lurek.html API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.html.loadDocument ---------------------------------------
--@api-stub: LHtmlDocument:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
do  -- LHtmlDocument:type
  local html_document_obj = lurek.html.newDocument("assets/sound.ogg", nil)
  local t = html_document_obj:type()
  lurek.log.info("LHtmlDocument:type = " .. t, "html")
end
--@api-stub: LHtmlDocument:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
do  -- LHtmlDocument:typeOf
  local html_document_obj = lurek.html.newDocument("assets/sound.ogg", nil)
  lurek.log.info("is LHtmlDocument: " .. tostring(html_document_obj:typeOf("LHtmlDocument")), "html")
  lurek.log.info("is wrong: " .. tostring(html_document_obj:typeOf("Unknown")), "html")
end
--@api-stub: LHtmlElement:type
-- Returns the type name of this object.
-- Use for generic object type dispatching in a mixed-object container.
do  -- LHtmlElement:type
  local doc = lurek.html.newDocument()
  doc:setHtml("<div id='box'>Hello</div>")
  doc:update(0)
  local el = doc:getElementById("box")
  if el then
    lurek.log.info("element type=" .. el:type(), "html")
  end
end
--@api-stub: LHtmlElement:typeOf
-- Returns true if this object is of the given type.
-- Use to check instance types in polymorphic collections.
do  -- LHtmlElement:typeOf
  local doc = lurek.html.newDocument()
  doc:setHtml("<span id='lbl'>text</span>")
  doc:update(0)
  local el = doc:getElementById("lbl")
  if el then
    lurek.log.info("is HtmlElement=" .. tostring(el:typeOf("HtmlElement")), "html")
    lurek.log.info("is Other=" .. tostring(el:typeOf("Other")), "html")
  end
end
--@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================


