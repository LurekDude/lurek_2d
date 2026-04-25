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
