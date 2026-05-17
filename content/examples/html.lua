-- content/examples/html.lua
-- lurek.html API examples: HTML/CSS documents for game UI (HUDs, menus, dialogs, inventories).
-- Run: cargo run -- content/examples/html.lua

--@api-stub: lurek.html.newDocument
-- Creates an HTML document from optional source and layout/style options
do
  -- newDocument is the primary way to create a UI overlay.
  -- Pass HTML source as the first argument and an options table with css, width, height.
  -- The document starts dirty (needs layout) until you call update() or relayout().
  local hud = lurek.html.newDocument([[
<body>
  <div id="score" class="hud-item">Score: 0</div>
  <div id="lives" class="hud-item">&#9825; &#9825; &#9825;</div>
  <div id="ammo" class="hud-item">Ammo: 30/90</div>
</body>
]], {
    -- Inline CSS defines the visual style for all elements in this document.
    css = [[
      body { margin: 0; padding: 8px; }
      .hud-item {
        color: white;
        font-size: 22px;
        padding: 4px 12px;
        margin-bottom: 4px;
        background: rgba(0,0,0,0.5);
      }
    ]],
    -- Viewport dimensions control the layout space. Match your game window size.
    width = 800,
    height = 600,
  })

  -- After creation, the document is dirty until the first update or relayout.
  lurek.log.info("newDocument created, dirty=" .. tostring(hud:isDirty()), "html")

  -- You can also create a minimal empty document and populate it later:
  local empty = lurek.html.newDocument()
  empty:setHtml("<body><p>Populated later</p></body>")
  lurek.log.info("empty doc populated", "html")
end

--@api-stub: lurek.html.loadDocument
-- Loads an HTML document from GameFS and optionally loads CSS from options or companion file
do
  -- loadDocument reads an .html file from GameFS (the content/ folder tree).
  -- If a companion .css file exists at the same path, it loads automatically.
  -- You can also pass opts.css or opts.cssPath to override.
  -- This is ideal for separating UI markup from game logic.
  local ok, doc = pcall(lurek.html.loadDocument, "ui/main_menu.html", {
    -- Override viewport for this specific menu screen
    width = 1280,
    height = 720,
  })
  if ok and doc then
    lurek.log.info("loadDocument succeeded", "html")
  else
    -- Graceful fallback when file is missing (common during development)
    lurek.log.info("loadDocument: file not found (expected in example)", "html")
  end
end

--@api-stub: lurek.html.supports
-- Returns whether the HTML engine supports a named feature
do
  -- Use supports() to check engine capabilities before using advanced CSS.
  -- This lets your UI code degrade gracefully on different engine versions.
  local has_flex = lurek.html.supports("css-flex")
  local has_grid = lurek.html.supports("css-grid")
  local has_transitions = lurek.html.supports("css-transitions")
  lurek.log.info("flex=" .. tostring(has_flex) .. " grid=" .. tostring(has_grid)
    .. " transitions=" .. tostring(has_transitions), "html")
end

--@api-stub: lurek.html.preventDefault
-- Prevent default for Lua scripts in this module
do
  -- preventDefault() is called inside event handlers to stop the default action.
  -- For example, preventing a link from navigating or a form from submitting.
  local doc = lurek.html.newDocument([[
<body><a id="link" href="#">Settings</a></body>
]])
  doc:on("click", function(ev)
    -- Prevent the engine from handling the link navigation —
    -- we want to open our own settings screen instead.
    lurek.html.preventDefault()
  end)
  pcall(function() doc:mousepressed(50, 50, 1) end)
  lurek.log.info("preventDefault called in handler", "html")
end

--@api-stub: lurek.html.stopPropagation
-- Stop propagation for Lua scripts in this module
do
  -- stopPropagation() prevents the event from bubbling to parent elements.
  -- Useful when an inner button should handle clicks without triggering
  -- the parent panel's click handler (e.g., close button inside a dialog).
  local doc = lurek.html.newDocument([[
<body>
  <div id="dialog">
    <button id="close">X</button>
    <p>Dialog content</p>
  </div>
</body>
]])
  doc:on("click", function(ev)
    -- This fires for all clicks — the close button handler below
    -- calls stopPropagation to prevent this from firing redundantly.
    lurek.log.info("document-level click (dialog bg)", "html")
  end)
  doc:update(0)
  local close_btn = doc:getElementById("close")
  if close_btn then
    close_btn:on("click", function(ev)
      lurek.html.stopPropagation()
      lurek.log.info("close button clicked, propagation stopped", "html")
    end)
  end
  pcall(function() doc:mousepressed(10, 10, 1) end)
end

--@api-stub: lurek.html.isDefaultPrevented
-- Returns true if default prevented for Lua scripts in this module
do
  -- isDefaultPrevented() lets you check whether preventDefault was called
  -- during the current event dispatch. Useful in post-event logic.
  local doc = lurek.html.newDocument("<body><button id='submit'>Submit</button></body>")
  doc:on("click", function(ev)
    lurek.html.preventDefault()
    -- After calling preventDefault, verify the state:
    local prevented = lurek.html.isDefaultPrevented()
    lurek.log.info("isDefaultPrevented=" .. tostring(prevented), "html")
  end)
  pcall(function() doc:mousepressed(20, 20, 1) end)
end

--@api-stub: LHtmlElement:setHtml
-- Replaces the document markup and invalidates existing element handles
do
  -- setHtml completely replaces the document content.
  -- WARNING: All previously obtained element handles become stale after this call.
  -- Use this for full-screen transitions (e.g., switching from menu to gameplay HUD).
  local doc = lurek.html.newDocument("<body><p>Loading...</p></body>")

  -- Simulate transitioning from a loading screen to the gameplay HUD
  doc:setHtml([[
<body>
  <div id="score">Score: 0</div>
  <div id="health-bar">
    <div id="health-fill" style="width:100%"></div>
  </div>
</body>
]])
  lurek.log.info("setHtml replaced entire markup for scene transition", "html")
end

--@api-stub: LHtmlElement:getHtml
-- Returns the current document markup string
do
  -- getHtml retrieves the full document source.
  -- Useful for debugging, serialization, or saving UI state.
  local doc = lurek.html.newDocument([[
<body><div id="inventory"><span class="slot">Sword</span></div></body>
]])
  local markup = doc:getHtml()
  lurek.log.info("getHtml length=" .. #markup .. " chars", "html")
end

--@api-stub: LHtmlDocument:setCss
-- Replaces the document stylesheet text
do
  -- setCss completely replaces all styles. Use this when switching themes
  -- (e.g., day/night mode, colorblind mode, or different UI skins).
  local doc = lurek.html.newDocument([[
<body><div id="panel" class="themed">Options</div></body>
]])
  -- Switch from a dark theme to a light theme
  doc:setCss([[
    body { margin: 0; }
    .themed {
      background: #f0f0f0;
      color: #222;
      font-size: 20px;
      padding: 16px;
      border: 2px solid #ccc;
    }
  ]])
  lurek.log.info("setCss applied light theme", "html")
end

--@api-stub: LHtmlDocument:addCss
-- Appends CSS source text to the document stylesheet
do
  -- addCss appends rules without replacing existing styles.
  -- Use this to layer additional styles on top (e.g., status effects, highlights).
  local doc = lurek.html.newDocument([[
<body>
  <div id="score" class="hud">Score: 500</div>
  <div id="combo" class="hud combo">x3 COMBO!</div>
</body>
]], { css = ".hud { color: white; font-size: 18px; padding: 8px; }" })

  -- Add a pulsing highlight for the combo counter
  doc:addCss([[
    .combo {
      color: gold;
      font-size: 28px;
      font-weight: bold;
    }
  ]])
  lurek.log.info("addCss appended combo highlight rule", "html")
end

--@api-stub: LHtmlDocument:clearCss
-- Clears all CSS source text from the document
do
  -- clearCss removes all stylesheet rules. Elements revert to default appearance.
  -- Useful before applying a completely new skin from scratch.
  local doc = lurek.html.newDocument("<body><p>styled text</p></body>", {
    css = "p { color: red; font-size: 24px; }"
  })
  doc:clearCss()
  -- Now re-apply a fresh stylesheet
  doc:setCss("p { color: green; font-size: 16px; }")
  lurek.log.info("clearCss + setCss: theme fully replaced", "html")
end

--@api-stub: LHtmlDocument:setViewport
-- Sets the document layout viewport size
do
  -- setViewport changes the layout area. Call this when the game window resizes
  -- so that the HTML UI reflows to match the new resolution.
  local doc = lurek.html.newDocument([[
<body><div class="panel">Responsive UI</div></body>
]], { css = ".panel { width: 50%; margin: auto; }", width = 800, height = 600 })

  -- Simulate a window resize from 800x600 to 1920x1080
  doc:setViewport(1920, 1080)
  lurek.log.info("setViewport updated to 1920x1080", "html")
end

--@api-stub: LHtmlDocument:getViewport
-- Returns the document layout viewport size
do
  -- getViewport returns current width, height — useful for positioning calculations.
  local doc = lurek.html.newDocument("<body>vp</body>", { width = 1280, height = 720 })
  local w, h = doc:getViewport()
  lurek.log.info("getViewport: " .. tostring(w) .. "x" .. tostring(h), "html")
end

--@api-stub: LHtmlDocument:update
-- Advances document timers and animated state
do
  -- update(dt) must be called every frame to advance CSS animations and timers.
  -- Pass the frame delta time (seconds). Typically called in lurek.update(dt).
  local doc = lurek.html.newDocument([[
<body><div id="toast" class="fade-in">Achievement Unlocked!</div></body>
]], { css = ".fade-in { opacity: 0; transition: opacity 0.5s; }" })

  -- Simulate 10 frames at 60 FPS
  for i = 1, 10 do
    doc:update(1 / 60)
  end
  lurek.log.info("update called for 10 frames", "html")
end

--@api-stub: LHtmlDocument:draw
-- Queues render commands for this document at an optional offset
do
  -- draw(x, y) queues GPU render commands for this frame.
  -- Call in lurek.draw() after updating. x/y offset lets you scroll or position
  -- the UI layer (e.g., camera shake effect on the HUD).
  local doc = lurek.html.newDocument([[
<body><p class="hud">HP: 100</p></body>
]], { css = ".hud { color: lime; font-size: 20px; }" })
  doc:update(0)

  -- Draw at top-left corner (default position)
  pcall(function() doc:draw(0, 0) end)
  -- You could also offset for screen shake: doc:draw(shake_x, shake_y)
  lurek.log.info("draw queued render commands", "html")
end

--@api-stub: LHtmlDocument:render
-- Queues render commands for this document at an optional offset
do
  -- render() is an alias for draw(). Both queue the same render commands.
  -- Use whichever name reads better in your game loop.
  local doc = lurek.html.newDocument("<body><div>Menu overlay</div></body>")
  doc:update(0)
  pcall(function() doc:render(0, 0) end)
  lurek.log.info("render (alias for draw) called", "html")
end

--@api-stub: LHtmlDocument:relayout
-- Rebuilds document layout immediately
do
  -- relayout() forces layout recalculation immediately instead of waiting
  -- for the next update(). Call this when you need accurate element positions
  -- right after changing content (e.g., before reading getRect).
  local doc = lurek.html.newDocument([[
<body><div id="tooltip">Damage: 50-75</div></body>
]], { css = "#tooltip { padding: 8px; font-size: 14px; }", width = 400, height = 300 })

  -- After setting new content, force layout so getRect returns correct values
  doc:update(0)
  doc:relayout()
  local el = doc:getElementById("tooltip")
  if el then
    local x, y, w, h = el:getRect()
    lurek.log.info("relayout done, tooltip rect: " .. w .. "x" .. h, "html")
  end
end

--@api-stub: LHtmlDocument:isDirty
-- Returns whether the document layout is dirty
do
  -- isDirty() returns true when content or styles changed but layout hasn't
  -- been recalculated yet. You can use this to avoid redundant relayout calls.
  local doc = lurek.html.newDocument("<body><p id='hp'>HP: 100</p></body>")
  lurek.log.info("after creation, dirty=" .. tostring(doc:isDirty()), "html")

  doc:update(0)
  doc:relayout()
  lurek.log.info("after relayout, dirty=" .. tostring(doc:isDirty()), "html")

  -- Changing content marks the document dirty again
  doc:update(0)
  local el = doc:getElementById("hp")
  if el then el:setText("HP: 50") end
  lurek.log.info("after setText, dirty=" .. tostring(doc:isDirty()), "html")
end

--@api-stub: LHtmlDocument:getRoot
-- Returns the root DOM element handle
do
  -- getRoot() returns the top-level element (usually <body>).
  -- From the root you can traverse the full DOM tree using query/queryAll.
  local doc = lurek.html.newDocument([[
<body>
  <header>Game Title</header>
  <main>Content</main>
  <footer>v1.0</footer>
</body>
]])
  local root = doc:getRoot()
  if root then
    lurek.log.info("root tag: " .. root:getTagName(), "html")
  end
end

--@api-stub: LHtmlDocument:getElementById
-- Looks up the first element with a matching id attribute
do
  -- getElementById is the fastest way to access a specific element.
  -- Always call update(0) before querying to ensure the DOM is ready.
  -- Returns nil if no element has that id.
  local doc = lurek.html.newDocument([[
<body>
  <div id="player-name">Hero</div>
  <div id="player-level">Lvl 12</div>
  <div id="player-gold">Gold: 450</div>
</body>
]])
  doc:update(0)

  local gold_el = doc:getElementById("player-gold")
  if gold_el then
    -- Update the gold display when player earns coins
    gold_el:setText("Gold: 500")
    lurek.log.info("getElementById found and updated gold display", "html")
  end

  -- Accessing a non-existent id returns nil safely
  local missing = doc:getElementById("does-not-exist")
  lurek.log.info("missing element is nil: " .. tostring(missing == nil), "html")
end

--@api-stub: LHtmlElement:query
-- Looks up the first element matching a selector
do
  -- query() uses CSS selectors to find the first matching element.
  -- Supports tag, class, id, and combined selectors.
  local doc = lurek.html.newDocument([[
<body>
  <div class="quest-log">
    <p class="quest active">Defeat the Dragon</p>
    <p class="quest">Find the Sword</p>
    <p class="quest">Talk to the Elder</p>
  </div>
</body>
]])
  doc:update(0)

  -- Find the first active quest
  local active = doc:query(".quest.active")
  if active then
    lurek.log.info("active quest: " .. active:getText(), "html")
  end
end

--@api-stub: LHtmlElement:queryAll
-- Returns all elements matching a selector
do
  -- queryAll() returns an array of all matching elements.
  -- Useful for iterating over lists (inventory slots, scoreboard rows, etc.).
  local doc = lurek.html.newDocument([[
<body>
  <table id="scoreboard">
    <tr class="row"><td>Player1</td><td>1500</td></tr>
    <tr class="row"><td>Player2</td><td>1200</td></tr>
    <tr class="row"><td>Player3</td><td>900</td></tr>
  </table>
</body>
]])
  doc:update(0)

  local rows = doc:queryAll(".row")
  lurek.log.info("scoreboard rows: " .. #rows, "html")
  -- You can iterate and modify each row individually
  for i, row in ipairs(rows) do
    local text = row:getText()
    lurek.log.info("  row " .. i .. ": " .. text, "html")
  end
end

--@api-stub: LHtmlElement:on
-- Registers a document-level event listener
do
  -- on() registers a callback for document-wide events.
  -- Returns a numeric handle you can pass to off() to unregister later.
  -- Common events: "click", "keydown", "input", "mousemove"
  local doc = lurek.html.newDocument([[
<body>
  <button id="play">Play</button>
  <button id="quit">Quit</button>
</body>
]])

  -- A single document-level listener handles all button clicks
  local handle = doc:on("click", function(ev)
    -- The event table contains: target (element), x, y, button, etc.
    lurek.log.info("doc-level click event fired", "html")
  end)
  lurek.log.info("on() returned handle=" .. tostring(handle), "html")
end

--@api-stub: LHtmlElement:off
-- Removes a document-level event listener by handle
do
  -- off() unregisters a listener. Pass the handle returned by on().
  -- Use this to clean up listeners when switching screens or closing menus.
  local doc = lurek.html.newDocument("<body><button>Temp</button></body>")
  local handle = doc:on("click", function(ev)
    lurek.log.info("this should not fire after off()", "html")
  end)
  -- Remove the listener — subsequent clicks won't trigger the callback
  doc:off(handle)
  lurek.log.info("off() removed listener, handle=" .. tostring(handle), "html")
end

--@api-stub: LHtmlDocument:mousepressed
-- Forwards a mouse press to the document and dispatches a click event when an element is hit
do
  -- mousepressed() forwards mouse input to the HTML layer.
  -- Call this from lurek.mousepressed(x, y, button) in your game.
  -- Returns true if the event was consumed (hit an element), false otherwise.
  -- When true, you can skip world-space click handling (UI eats the click).
  local doc = lurek.html.newDocument([[
<body>
  <button id="attack" style="width:100px;height:40px">Attack</button>
</body>
]], { width = 800, height = 600 })
  doc:update(0)
  doc:on("click", function(ev)
    lurek.log.info("attack button clicked!", "html")
  end)

  -- Simulate a left-click at pixel (50, 20)
  local consumed = doc:mousepressed(50, 20, 1)
  lurek.log.info("mousepressed consumed=" .. tostring(consumed), "html")
end

--@api-stub: LHtmlDocument:mousereleased
-- Forwards a mouse release to the document
do
  -- mousereleased() completes the click cycle. Call from lurek.mousereleased().
  -- Some UI patterns (drag-drop, hold buttons) depend on both press and release.
  local doc = lurek.html.newDocument("<body><button>Hold</button></body>")
  doc:mousepressed(50, 20, 1)
  doc:mousereleased(50, 20, 1)
  lurek.log.info("mousereleased completes the press/release cycle", "html")
end

--@api-stub: LHtmlDocument:mousemoved
-- Forwards mouse movement to the document
do
  -- mousemoved() enables hover states and tooltip positioning.
  -- Call from lurek.mousemoved(x, y) to keep the UI responsive.
  local doc = lurek.html.newDocument([[
<body>
  <button id="btn" class="hoverable">Hover Me</button>
</body>
]], { css = ".hoverable:hover { color: yellow; }" })

  -- Simulate cursor moving over the button area
  doc:mousemoved(50, 20)
  lurek.log.info("mousemoved enables hover CSS states", "html")
end

--@api-stub: LHtmlDocument:wheelmoved
-- Forwards mouse wheel movement to the document
do
  -- wheelmoved() enables scrollable UI areas (long inventory lists, text logs).
  -- dx = horizontal scroll, dy = vertical scroll (negative = scroll up).
  local doc = lurek.html.newDocument([[
<body>
  <div id="chat-log" style="height:200px;overflow:auto">
    <p>Line 1</p><p>Line 2</p><p>Line 3</p>
    <p>Line 4</p><p>Line 5</p><p>Line 6</p>
  </div>
</body>
]])
  -- Scroll down by 3 units (e.g., user scrolls mouse wheel down)
  doc:wheelmoved(0, -3)
  lurek.log.info("wheelmoved scrolled chat log down", "html")
end

--@api-stub: LHtmlDocument:keypressed
-- Forwards a key press to the focused document element and dispatches `keydown`
do
  -- keypressed() sends keyboard input to the focused element.
  -- Call from lurek.keypressed(key). Returns true if consumed.
  -- Works with text inputs, buttons (enter = activate), and custom key bindings.
  local doc = lurek.html.newDocument([[
<body><input id="chat-input" type="text"/></body>
]])
  doc:update(0)
  local input_el = doc:getElementById("chat-input")
  if input_el then
    input_el:focus()
  end
  -- Simulate pressing Enter to submit the chat message
  local consumed = doc:keypressed("return")
  lurek.log.info("keypressed(return) consumed=" .. tostring(consumed), "html")
end

--@api-stub: LHtmlDocument:textinput
-- Forwards text input to the focused document element and dispatches `input`
do
  -- textinput() forwards typed characters to the focused input element.
  -- Call from lurek.textinput(text). Unlike keypressed, this carries the actual
  -- character value (handles shift, caps lock, international input, etc.).
  local doc = lurek.html.newDocument([[
<body><input id="name-field" type="text"/></body>
]])
  doc:update(0)
  local field = doc:getElementById("name-field")
  if field then
    field:focus()
  end
  -- Type a character into the focused input
  doc:textinput("H")
  doc:textinput("e")
  doc:textinput("r")
  doc:textinput("o")
  lurek.log.info("textinput sent 'Hero' character by character", "html")
end

--@api-stub: LHtmlElement:type
-- Returns the Lua-visible type name for this HTML document handle
do
  -- type() returns the string "LHtmlDocument". Used for runtime type checking.
  local doc = lurek.html.newDocument("<body>type test</body>")
  local t = doc:type()
  lurek.log.info("doc:type() = " .. t, "html")
end

--@api-stub: LHtmlElement:typeOf
-- Returns whether this document handle matches a supported type name
do
  -- typeOf() checks if this handle is a specific type.
  -- Matches "LHtmlDocument" and the base "Object" type.
  local doc = lurek.html.newDocument("<body>typeOf test</body>")
  lurek.log.info("typeOf(LHtmlDocument)=" .. tostring(doc:typeOf("LHtmlDocument")), "html")
  lurek.log.info("typeOf(Object)=" .. tostring(doc:typeOf("Object")), "html")
  lurek.log.info("typeOf(LImage)=" .. tostring(doc:typeOf("LImage")), "html")
end

--@api-stub: LHtmlElement:getDocument
-- Returns the document handle that owns this element
do
  -- getDocument() navigates from an element back to its parent document.
  -- Useful when you pass elements to utility functions that also need the doc.
  local doc = lurek.html.newDocument([[
<body><div id="panel">Inventory Panel</div></body>
]])
  doc:update(0)
  local el = doc:getElementById("panel")
  if el then
    local owner = el:getDocument()
    -- The returned document is the same handle, so you can call doc methods on it
    local w, h = owner:getViewport()
    lurek.log.info("getDocument viewport: " .. tostring(w) .. "x" .. tostring(h), "html")
  end
end

--@api-stub: LHtmlElement:getTagName
-- Returns this element's tag name
do
  -- getTagName() returns the HTML tag (div, span, button, input, etc.).
  -- Useful for generic element-processing logic.
  local doc = lurek.html.newDocument([[
<body>
  <button id="action">Attack</button>
  <span id="label">HP</span>
</body>
]])
  doc:update(0)
  local btn = doc:getElementById("action")
  local lbl = doc:getElementById("label")
  if btn then lurek.log.info("action tag: " .. btn:getTagName(), "html") end
  if lbl then lurek.log.info("label tag: " .. lbl:getTagName(), "html") end
end

--@api-stub: LHtmlElement:getId
-- Returns this element's id attribute
do
  -- getId() returns the id attribute string, or nil if no id is set.
  local doc = lurek.html.newDocument("<body><div id='health-bar'>HP</div></body>")
  doc:update(0)
  local el = doc:getElementById("health-bar")
  if el then
    lurek.log.info("getId=" .. tostring(el:getId()), "html")
  end
end

--@api-stub: LHtmlElement:setId
-- Sets or clears this element's id attribute
do
  -- setId() changes or removes the element's id.
  -- Pass nil to clear the id attribute entirely.
  local doc = lurek.html.newDocument("<body><div id='slot-empty'>Empty</div></body>")
  doc:update(0)
  local el = doc:getElementById("slot-empty")
  if el then
    -- Rename the slot when an item is placed in it
    el:setId("slot-sword")
    lurek.log.info("setId changed to: " .. tostring(el:getId()), "html")
  end
end

--@api-stub: LHtmlElement:getText
-- Returns this element's text content
do
  -- getText() returns visible text content of the element and its children.
  local doc = lurek.html.newDocument([[
<body>
  <div id="dialog-text">The elder speaks: "Beware the dragon!"</div>
</body>
]])
  doc:update(0)
  local el = doc:getElementById("dialog-text")
  if el then
    lurek.log.info("getText: " .. el:getText(), "html")
  end
end

--@api-stub: LHtmlElement:setText
-- Replaces this element's text content
do
  -- setText() replaces the element's text. This is the primary way to update
  -- dynamic UI values (score, health, timer, gold, etc.) every frame.
  local doc = lurek.html.newDocument([[
<body>
  <span id="score">Score: 0</span>
  <span id="timer">Time: 60</span>
</body>
]])
  doc:update(0)
  local score_el = doc:getElementById("score")
  local timer_el = doc:getElementById("timer")
  if score_el then
    -- Update score when player collects a coin
    score_el:setText("Score: 150")
  end
  if timer_el then
    -- Update countdown timer
    timer_el:setText("Time: 45")
  end
  lurek.log.info("setText updated score and timer displays", "html")
end

--@api-stub: LHtmlElement:getHtml
-- Returns this element's inner HTML
do
  -- getHtml() returns the raw HTML inside this element (including child tags).
  -- Useful for cloning or inspecting complex UI structures.
  local doc = lurek.html.newDocument([[
<body>
  <div id="tooltip">
    <b>Fire Sword</b><br/>
    <span class="stat">Damage: 50-75</span>
  </div>
</body>
]])
  doc:update(0)
  local el = doc:getElementById("tooltip")
  if el then
    local inner = el:getHtml()
    lurek.log.info("getHtml (tooltip inner): " .. inner, "html")
  end
end

--@api-stub: LHtmlElement:setHtml
-- Replaces this element's inner HTML and may invalidate descendant element handles
do
  -- setHtml() replaces all content inside the element with new markup.
  -- WARNING: Any child element handles obtained before this call become stale.
  -- Use this for dynamic content blocks (shop listings, inventory grids).
  local doc = lurek.html.newDocument([[
<body><div id="shop-items">Loading...</div></body>
]])
  doc:update(0)
  local shop = doc:getElementById("shop-items")
  if shop then
    -- Populate the shop with items after loading
    shop:setHtml([[
      <div class="item">Potion - 50g</div>
      <div class="item">Shield - 200g</div>
      <div class="item">Scroll - 75g</div>
    ]])
    lurek.log.info("setHtml populated shop items", "html")
  end
end

--@api-stub: LHtmlElement:appendHtml
-- Appends HTML source to this element's inner HTML
do
  -- appendHtml() adds new content at the end without replacing existing content.
  -- Perfect for chat logs, notification stacks, or growing lists.
  local doc = lurek.html.newDocument([[
<body><div id="chat-log"></div></body>
]], { css = "#chat-log { font-size: 14px; }" })
  doc:update(0)
  local log_el = doc:getElementById("chat-log")
  if log_el then
    -- Append chat messages as they arrive
    log_el:appendHtml('<p class="msg">[System] Welcome to the game!</p>')
    log_el:appendHtml('<p class="msg">[Player1] Hello everyone</p>')
    log_el:appendHtml('<p class="msg">[Player2] Ready to start?</p>')
    lurek.log.info("appendHtml added 3 chat messages", "html")
  end
end

--@api-stub: LHtmlElement:remove
-- Removes this element from the document
do
  -- remove() deletes the element from the DOM entirely.
  -- Use for dismissing notifications, removing defeated enemies from a list, etc.
  local doc = lurek.html.newDocument([[
<body>
  <div id="notification" class="toast">Quest Complete!</div>
  <div id="main-hud">Score: 500</div>
</body>
]])
  doc:update(0)
  local toast = doc:getElementById("notification")
  if toast then
    -- Dismiss the notification after the player sees it
    toast:remove()
    lurek.log.info("notification removed from DOM", "html")
  end
  -- Verify it's gone
  local check = doc:getElementById("notification")
  lurek.log.info("notification after remove: " .. tostring(check), "html")
end

--@api-stub: LHtmlElement:getAttribute
-- Returns an attribute value from this element
do
  -- getAttribute() reads any HTML attribute. Returns nil if the attribute is absent.
  -- Useful for reading data-* attributes that store game state on elements.
  local doc = lurek.html.newDocument([[
<body>
  <div id="item-slot" class="slot" data-item-id="sword_01" data-quantity="3">
    Iron Sword (x3)
  </div>
</body>
]])
  doc:update(0)
  local slot = doc:getElementById("item-slot")
  if slot then
    local item_id = slot:getAttribute("data-item-id")
    local qty = slot:getAttribute("data-quantity")
    lurek.log.info("item=" .. tostring(item_id) .. " qty=" .. tostring(qty), "html")
  end
end

--@api-stub: LHtmlElement:setAttribute
-- Sets or clears an attribute on this element
do
  -- setAttribute() sets any attribute. Pass nil as value to remove it.
  -- data-* attributes are great for storing game metadata on UI elements.
  local doc = lurek.html.newDocument([[
<body><div id="slot" class="inventory-slot">Empty</div></body>
]])
  doc:update(0)
  local slot = doc:getElementById("slot")
  if slot then
    -- When player picks up an item, store its data on the slot element
    slot:setAttribute("data-item-id", "health_potion")
    slot:setAttribute("data-stack", "5")
    slot:setText("Health Potion (x5)")
    lurek.log.info("setAttribute stored item data on slot", "html")
  end
end

--@api-stub: LHtmlElement:removeAttribute
-- Removes an attribute from this element
do
  -- removeAttribute() deletes an attribute entirely.
  -- Use when clearing item data from an inventory slot.
  local doc = lurek.html.newDocument([[
<body><div id="slot" data-item-id="old_sword" data-equipped="true">Old Sword</div></body>
]])
  doc:update(0)
  local slot = doc:getElementById("slot")
  if slot then
    -- Player unequips the item
    slot:removeAttribute("data-equipped")
    lurek.log.info("removeAttribute cleared equipped flag", "html")
  end
end

--@api-stub: LHtmlElement:hasClass
-- Returns whether this element has a CSS class
do
  -- hasClass() checks for a specific class. Use for state checks
  -- (is this button disabled? is this panel visible? is this slot selected?).
  local doc = lurek.html.newDocument([[
<body>
  <button id="action-btn" class="btn primary disabled">Cast Spell</button>
</body>
]])
  doc:update(0)
  local btn = doc:getElementById("action-btn")
  if btn then
    local is_disabled = btn:hasClass("disabled")
    local is_primary = btn:hasClass("primary")
    lurek.log.info("disabled=" .. tostring(is_disabled) .. " primary=" .. tostring(is_primary), "html")
  end
end

--@api-stub: LHtmlElement:addClass
-- Adds a CSS class to this element
do
  -- addClass() adds a CSS class. Classes control visual state through CSS rules.
  -- Common pattern: add "active", "selected", "damaged", "hidden" classes.
  local doc = lurek.html.newDocument([[
<body><div id="player-portrait" class="portrait">Hero</div></body>
]], { css = ".portrait.damaged { border: 2px solid red; }" })
  doc:update(0)
  local portrait = doc:getElementById("player-portrait")
  if portrait then
    -- Player takes damage — add visual feedback
    portrait:addClass("damaged")
    lurek.log.info("addClass(damaged) adds red border via CSS", "html")
  end
end

--@api-stub: LHtmlElement:removeClass
-- Removes a CSS class from this element
do
  -- removeClass() removes a class. Use to revert visual states.
  local doc = lurek.html.newDocument([[
<body><div id="btn" class="btn disabled">Start</div></body>
]], { css = ".disabled { opacity: 0.5; }" })
  doc:update(0)
  local btn = doc:getElementById("btn")
  if btn then
    -- Enable the button after loading finishes
    btn:removeClass("disabled")
    lurek.log.info("removeClass(disabled) re-enables the button", "html")
  end
end

--@api-stub: LHtmlElement:toggleClass
-- Toggles a CSS class on this element, optionally forcing the final state
do
  -- toggleClass() adds the class if absent, removes if present. Returns final state.
  -- Optional second argument forces the class on (true) or off (false).
  local doc = lurek.html.newDocument([[
<body><div id="panel" class="sidebar">Menu</div></body>
]], { css = ".sidebar.open { width: 200px; } .sidebar { width: 0; }" })
  doc:update(0)
  local panel = doc:getElementById("panel")
  if panel then
    -- Toggle the sidebar open/closed when player presses Tab
    local is_open = panel:toggleClass("open")
    lurek.log.info("toggleClass(open) → now open=" .. tostring(is_open), "html")

    -- Force closed regardless of current state
    local forced = panel:toggleClass("open", false)
    lurek.log.info("toggleClass(open, false) → forced closed=" .. tostring(forced), "html")
  end
end

--@api-stub: LHtmlElement:getStyle
-- Returns an inline or computed style value for this element
do
  -- getStyle() reads a CSS property value from this element.
  -- Returns the inline style if set, otherwise the computed value, or nil.
  local doc = lurek.html.newDocument([[
<body><div id="health-fill" style="width:75%;background:green">HP</div></body>
]])
  doc:update(0)
  local bar = doc:getElementById("health-fill")
  if bar then
    local width = bar:getStyle("width")
    local bg = bar:getStyle("background")
    lurek.log.info("health bar width=" .. tostring(width) .. " bg=" .. tostring(bg), "html")
  end
end

--@api-stub: LHtmlElement:setStyle
-- Sets or clears a style property on this element
do
  -- setStyle() sets an inline CSS property. Pass nil to clear it.
  -- Great for dynamic values like health bar width, opacity fades, positioning.
  local doc = lurek.html.newDocument([[
<body>
  <div id="hp-bar" style="width:100%;height:20px;background:green"></div>
</body>
]])
  doc:update(0)
  local bar = doc:getElementById("hp-bar")
  if bar then
    -- Player takes damage: shrink the bar and change color
    local hp_percent = 35
    bar:setStyle("width", hp_percent .. "%")
    bar:setStyle("background", "red")  -- red when low HP
    lurek.log.info("setStyle updated health bar to " .. hp_percent .. "%", "html")
  end
end

--@api-stub: LHtmlElement:getRect
-- Returns this element's layout rectangle after relayout if needed
do
  -- getRect() returns x, y, width, height of the element after layout.
  -- Triggers relayout if needed. Use for hit-testing, tooltip positioning,
  -- or aligning game objects to UI elements.
  local doc = lurek.html.newDocument([[
<body>
  <div id="minimap" style="position:absolute;right:8px;top:8px;width:150px;height:150px">
    Map
  </div>
</body>
]], { width = 800, height = 600 })
  doc:update(0)
  doc:relayout()
  local minimap = doc:getElementById("minimap")
  if minimap then
    local x, y, w, h = minimap:getRect()
    lurek.log.info("minimap rect: x=" .. tostring(x) .. " y=" .. tostring(y)
      .. " w=" .. tostring(w) .. " h=" .. tostring(h), "html")
  end
end

--@api-stub: LHtmlElement:focus
-- Gives keyboard focus to this element
do
  -- focus() directs keyboard input to this element.
  -- Call when opening a dialog with a text input, or when Tab-navigating UI.
  local doc = lurek.html.newDocument([[
<body>
  <input id="player-name" type="text" placeholder="Enter name..."/>
</body>
]])
  doc:update(0)
  local input = doc:getElementById("player-name")
  if input then
    -- Auto-focus the name field when the character creation screen opens
    input:focus()
    lurek.log.info("focus() set on player name input", "html")
  end
end

--@api-stub: LHtmlElement:blur
-- Removes keyboard focus from this element when it is focused
do
  -- blur() removes focus from this element. Keyboard input stops going to it.
  -- Use when closing a dialog or when the player presses Escape.
  local doc = lurek.html.newDocument([[
<body><input id="chat" type="text"/></body>
]])
  doc:update(0)
  local chat = doc:getElementById("chat")
  if chat then
    chat:focus()
    -- Player presses Escape → close chat, return focus to the game
    chat:blur()
    lurek.log.info("blur() removed focus from chat input", "html")
  end
end

--@api-stub: LHtmlElement:query
-- Looks up the first descendant element matching a selector
do
  -- Element-level query() searches only within this element's subtree.
  -- More efficient than document-level query when you know the parent.
  local doc = lurek.html.newDocument([[
<body>
  <div id="inventory">
    <div class="slot selected"><span class="name">Sword</span></div>
    <div class="slot"><span class="name">Shield</span></div>
  </div>
</body>
]])
  doc:update(0)
  local inv = doc:getElementById("inventory")
  if inv then
    -- Find the selected slot's item name within the inventory subtree
    local selected = inv:query(".slot.selected .name")
    if selected then
      lurek.log.info("selected item: " .. selected:getText(), "html")
    end
  end
end

--@api-stub: LHtmlElement:queryAll
-- Returns all descendant elements matching a selector
do
  -- Element-level queryAll() returns all matching descendants.
  -- Use for processing items in a specific container.
  local doc = lurek.html.newDocument([[
<body>
  <ul id="buff-list">
    <li class="buff">Shield +5</li>
    <li class="buff">Speed +10%</li>
    <li class="buff">Regen 2/s</li>
  </ul>
</body>
]])
  doc:update(0)
  local list = doc:getElementById("buff-list")
  if list then
    local buffs = list:queryAll(".buff")
    lurek.log.info("active buffs: " .. #buffs, "html")
  end
end

--@api-stub: LHtmlElement:on
-- Registers an element-level event listener
do
  -- Element-level on() fires only when the event targets this specific element.
  -- More precise than document-level listeners. Returns a handle for off().
  local doc = lurek.html.newDocument([[
<body>
  <button id="attack-btn">Attack</button>
  <button id="defend-btn">Defend</button>
</body>
]])
  doc:update(0)
  local attack = doc:getElementById("attack-btn")
  local defend = doc:getElementById("defend-btn")
  if attack and defend then
    -- Each button gets its own dedicated handler
    attack:on("click", function(ev)
      lurek.log.info("attack action triggered!", "html")
    end)
    defend:on("click", function(ev)
      lurek.log.info("defend action triggered!", "html")
    end)
    lurek.log.info("element:on() registered per-button handlers", "html")
  end
end

--@api-stub: LHtmlElement:off
-- Removes an element-level event listener by handle
do
  -- Element-level off() removes a specific listener from this element.
  -- Use when a button becomes inactive or a temporary handler expires.
  local doc = lurek.html.newDocument([[
<body><button id="one-shot">Claim Reward</button></body>
]])
  doc:update(0)
  local btn = doc:getElementById("one-shot")
  if btn then
    local handle
    handle = btn:on("click", function(ev)
      lurek.log.info("reward claimed! removing handler...", "html")
      -- Self-removing handler: fires only once
      btn:off(handle)
    end)
    lurek.log.info("element:off() ready for one-shot pattern", "html")
  end
end

--@api-stub: LHtmlElement:type
-- Returns the Lua-visible type name for this HTML element handle
do
  -- type() returns "LHtmlElement" for all DOM element handles.
  local doc = lurek.html.newDocument("<body><div id='box'>Hello</div></body>")
  doc:update(0)
  local el = doc:getElementById("box")
  if el then
    lurek.log.info("element:type() = " .. el:type(), "html")
  end
end

--@api-stub: LHtmlElement:typeOf
-- Returns whether this element handle matches a supported type name
do
  -- typeOf() checks the type. Matches "LHtmlElement" and base "Object".
  local doc = lurek.html.newDocument("<body><span id='tag'>text</span></body>")
  doc:update(0)
  local el = doc:getElementById("tag")
  if el then
    lurek.log.info("typeOf(LHtmlElement)=" .. tostring(el:typeOf("LHtmlElement")), "html")
    lurek.log.info("typeOf(Object)=" .. tostring(el:typeOf("Object")), "html")
    lurek.log.info("typeOf(LImage)=" .. tostring(el:typeOf("LImage")), "html")
  end
end

print("content/examples/html.lua")
