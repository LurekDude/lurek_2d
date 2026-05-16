-- content/examples/html.lua
-- lurek.html API examples.
-- Run: cargo run -- content/examples/html.lua

--@api-stub: lurek.html.newDocument
-- Creates an HTML document from optional source and layout/style options
do
  local hud = lurek.html.newDocument([[
<body>
  <div id="score" class="hud-item">Score: 0</div>
  <div id="lives" class="hud-item">&#9825;&#9825;&#9825;</div>
</body>
]], {
    css = [[.hud-item { color: white; font-size: 24px; padding: 8px; }]],
    width = 800,
    height = 600,
  })
  lurek.log.info("newDocument created, dirty=" .. tostring(hud:isDirty()), "html")
end

--@api-stub: lurek.html.loadDocument
-- Loads an HTML document from GameFS and optionally loads CSS from options or companion file
do
  local ok, doc = pcall(lurek.html.loadDocument, "ui/main_menu.html")
  if ok and doc then
    lurek.log.info("loadDocument succeeded", "html")
  else
    lurek.log.info("loadDocument: file not found (expected)", "html")
  end
end

--@api-stub: lurek.html.supports
-- Returns whether the HTML engine supports a named feature
do
  local has_flex = lurek.html.supports("css-flex")
  local has_grid = lurek.html.supports("css-grid")
  lurek.log.info("flex=" .. tostring(has_flex) .. " grid=" .. tostring(has_grid), "html")
end

--@api-stub: lurek.html.preventDefault
-- Prevent default for Lua scripts in this module
do
  local doc = lurek.html.newDocument("<body><a id='link'>Click</a></body>")
  doc:on("click", function()
    lurek.html.preventDefault()
  end)
  pcall(function() doc:mousepressed(50, 50, 1) end)
  lurek.log.info("preventDefault called in handler", "html")
end

--@api-stub: lurek.html.stopPropagation
-- Stop propagation for Lua scripts in this module
do
  local doc = lurek.html.newDocument("<body><div id='inner'>Nested</div></body>")
  doc:on("click", function()
    lurek.html.stopPropagation()
  end)
  pcall(function() doc:mousepressed(10, 10, 1) end)
  lurek.log.info("stopPropagation called", "html")
end

--@api-stub: lurek.html.isDefaultPrevented
-- Returns true if default prevented for Lua scripts in this module
do
  local doc = lurek.html.newDocument("<body><button>OK</button></body>")
  doc:on("click", function()
    lurek.html.preventDefault()
    local stopped = lurek.html.isDefaultPrevented()
    lurek.log.info("isDefaultPrevented=" .. tostring(stopped), "html")
  end)
  pcall(function() doc:mousepressed(20, 20, 1) end)
end

--@api-stub: LHtmlDocument:setHtml
-- Replaces the document markup and invalidates existing element handles
do
  local doc = lurek.html.newDocument("<body><p>old</p></body>")
  doc:setHtml([[<body><div id="score">Score: 100</div></body>]])
  lurek.log.info("setHtml replaced markup", "html")
end

--@api-stub: LHtmlDocument:getHtml
-- Returns the current document markup string
do
  local doc = lurek.html.newDocument("<body><p>hello</p></body>")
  local markup = doc:getHtml()
  lurek.log.info("getHtml len=" .. #markup, "html")
end

--@api-stub: LHtmlDocument:setCss
-- Replaces the document stylesheet text
do
  local doc = lurek.html.newDocument("<body><p>styled</p></body>")
  doc:setCss("body { margin: 0; } p { font-size: 20px; }")
  lurek.log.info("setCss applied", "html")
end

--@api-stub: LHtmlDocument:addCss
-- Appends CSS source text to the document stylesheet
do
  local doc = lurek.html.newDocument("<body><div id='score'>0</div></body>")
  doc:addCss("#score { color: yellow; }")
  lurek.log.info("addCss appended rule", "html")
end

--@api-stub: LHtmlDocument:clearCss
-- Clears all CSS source text from the document
do
  local doc = lurek.html.newDocument("<body><p>text</p></body>", { css = "p { color: red; }" })
  doc:clearCss()
  lurek.log.info("clearCss removed all styles", "html")
end

--@api-stub: LHtmlDocument:setViewport
-- Sets the document layout viewport size
do
  local doc = lurek.html.newDocument("<body>viewport test</body>")
  doc:setViewport(1920, 1080)
  lurek.log.info("setViewport 1920x1080", "html")
end

--@api-stub: LHtmlDocument:getViewport
-- Returns the document layout viewport size
do
  local doc = lurek.html.newDocument("<body>vp</body>", { width = 800, height = 600 })
  local w, h = doc:getViewport()
  lurek.log.info("getViewport: " .. tostring(w) .. "x" .. tostring(h), "html")
end

--@api-stub: LHtmlDocument:update
-- Advances document timers and animated state
do
  local doc = lurek.html.newDocument("<body><p>tick</p></body>")
  doc:update(1 / 60)
  lurek.log.info("update(dt) called", "html")
end

--@api-stub: LHtmlDocument:draw
-- Queues render commands for this document at an optional offset
do
  local doc = lurek.html.newDocument("<body><p>draw</p></body>")
  pcall(function() doc:draw(0, 0) end)
  lurek.log.info("draw attempted (needs graphics ctx)", "html")
end

--@api-stub: LHtmlDocument:render
-- Queues render commands for this document at an optional offset
do
  local doc = lurek.html.newDocument("<body><p>render</p></body>")
  pcall(function() doc:render(0, 0) end)
  lurek.log.info("render attempted", "html")
end

--@api-stub: LHtmlDocument:relayout
-- Rebuilds document layout immediately
do
  local doc = lurek.html.newDocument("<body><p>layout</p></body>")
  doc:relayout()
  lurek.log.info("relayout forced", "html")
end

--@api-stub: LHtmlDocument:isDirty
-- Returns whether the document layout is dirty
do
  local doc = lurek.html.newDocument("<body><p>dirty?</p></body>")
  local dirty = doc:isDirty()
  lurek.log.info("isDirty=" .. tostring(dirty), "html")
end

--@api-stub: LHtmlDocument:getRoot
-- Returns the root DOM element handle
do
  local doc = lurek.html.newDocument("<body><div>root test</div></body>")
  local root = doc:getRoot()
  if root then
    lurek.log.info("root tag: " .. root:getTagName(), "html")
  end
end

--@api-stub: LHtmlDocument:getElementById
-- Looks up the first element with a matching id attribute
do
  local doc = lurek.html.newDocument("<body><span id='lbl'>Hi</span></body>")
  doc:update(0)
  local el = doc:getElementById("lbl")
  if el then
    lurek.log.info("getElementById found: " .. el:getText(), "html")
  end
end

--@api-stub: LHtmlDocument:query
-- Looks up the first element matching a selector
do
  local doc = lurek.html.newDocument("<body><p class='info'>msg</p></body>")
  doc:update(0)
  local el = doc:query(".info")
  if el then
    lurek.log.info("query(.info) text=" .. el:getText(), "html")
  end
end

--@api-stub: LHtmlDocument:queryAll
-- Returns all elements matching a selector
do
  local doc = lurek.html.newDocument("<body><li>a</li><li>b</li><li>c</li></body>")
  doc:update(0)
  local items = doc:queryAll("li")
  lurek.log.info("queryAll(li) count=" .. #items, "html")
end

--@api-stub: LHtmlDocument:on
-- Registers a document-level event listener
do
  local doc = lurek.html.newDocument("<body><p>click me</p></body>")
  local handle = doc:on("click", function(ev)
    lurek.log.info("doc click event fired", "html")
  end)
  lurek.log.info("on() returned handle=" .. tostring(handle ~= nil), "html")
end

--@api-stub: LHtmlDocument:off
-- Removes a document-level event listener by handle
do
  local doc = lurek.html.newDocument("<body><p>off test</p></body>")
  local handle = doc:on("click", function() end)
  doc:off(handle)
  lurek.log.info("off() removed listener", "html")
end

--@api-stub: LHtmlDocument:mousepressed
-- Forwards a mouse press to the document and dispatches a click event when an element is hit
do
  local doc = lurek.html.newDocument("<body><button>btn</button></body>")
  local consumed = doc:mousepressed(100, 200, 1)
  lurek.log.info("mousepressed consumed=" .. tostring(consumed), "html")
end

--@api-stub: LHtmlDocument:mousereleased
-- Forwards a mouse release to the document
do
  local doc = lurek.html.newDocument("<body><button>btn</button></body>")
  doc:mousepressed(100, 200, 1)
  doc:mousereleased(100, 200, 1)
  lurek.log.info("mousereleased sent", "html")
end

--@api-stub: LHtmlDocument:mousemoved
-- Forwards mouse movement to the document
do
  local doc = lurek.html.newDocument("<body><div>hover</div></body>")
  doc:mousemoved(110, 205)
  lurek.log.info("mousemoved sent", "html")
end

--@api-stub: LHtmlDocument:wheelmoved
-- Forwards mouse wheel movement to the document
do
  local doc = lurek.html.newDocument("<body><div>scroll</div></body>")
  doc:wheelmoved(0, -3)
  lurek.log.info("wheelmoved sent", "html")
end

--@api-stub: LHtmlDocument:keypressed
-- Forwards a key press to the focused document element and dispatches `keydown`
do
  local doc = lurek.html.newDocument("<body><input/></body>")
  doc:keypressed("return")
  lurek.log.info("keypressed(return) sent", "html")
end

--@api-stub: LHtmlDocument:textinput
-- Forwards text input to the focused document element and dispatches `input`
do
  local doc = lurek.html.newDocument("<body><input/></body>")
  doc:textinput("a")
  lurek.log.info("textinput('a') sent", "html")
end

--@api-stub: LHtmlDocument:type
-- Returns the Lua-visible type name for this HTML document handle
do
  local doc = lurek.html.newDocument("<body>type test</body>")
  local t = doc:type()
  lurek.log.info("LHtmlDocument:type = " .. t, "html")
end

--@api-stub: LHtmlDocument:typeOf
-- Returns whether this document handle matches a supported type name
do
  local doc = lurek.html.newDocument("<body>typeOf test</body>")
  lurek.log.info("is LHtmlDocument: " .. tostring(doc:typeOf("LHtmlDocument")), "html")
  lurek.log.info("is wrong: " .. tostring(doc:typeOf("Unknown")), "html")
end

--@api-stub: LHtmlElement:getDocument
-- Returns the document handle that owns this element
do
  local doc = lurek.html.newDocument("<body><div id='box'>hi</div></body>")
  doc:update(0)
  local el = doc:getElementById("box")
  if el then
    local owner = el:getDocument()
    lurek.log.info("getDocument returned doc=" .. tostring(owner ~= nil), "html")
  end
end

--@api-stub: LHtmlElement:getTagName
-- Returns this element's tag name
do
  local doc = lurek.html.newDocument("<body><div id='hdr'>title</div></body>")
  doc:update(0)
  local el = doc:getElementById("hdr")
  if el then
    lurek.log.info("getTagName=" .. el:getTagName(), "html")
  end
end

--@api-stub: LHtmlElement:getId
-- Returns this element's id attribute
do
  local doc = lurek.html.newDocument("<body><span id='lbl'>x</span></body>")
  doc:update(0)
  local el = doc:getElementById("lbl")
  if el then
    lurek.log.info("getId=" .. el:getId(), "html")
  end
end

--@api-stub: LHtmlElement:setId
-- Sets or clears this element's id attribute
do
  local doc = lurek.html.newDocument("<body><div id='old'>x</div></body>")
  doc:update(0)
  local el = doc:getElementById("old")
  if el then
    el:setId("new")
    lurek.log.info("setId changed to: " .. el:getId(), "html")
  end
end

--@api-stub: LHtmlElement:getText
-- Returns this element's text content
do
  local doc = lurek.html.newDocument("<body><p id='msg'>Hello World</p></body>")
  doc:update(0)
  local el = doc:getElementById("msg")
  if el then
    lurek.log.info("getText=" .. el:getText(), "html")
  end
end

--@api-stub: LHtmlElement:setText
-- Replaces this element's text content
do
  local doc = lurek.html.newDocument("<body><p id='msg'>old</p></body>")
  doc:update(0)
  local el = doc:getElementById("msg")
  if el then
    el:setText("new text")
    lurek.log.info("setText done, now=" .. el:getText(), "html")
  end
end

--@api-stub: LHtmlElement:getHtml
-- Returns this element's inner HTML
do
  local doc = lurek.html.newDocument("<body><div id='wrap'><b>bold</b></div></body>")
  doc:update(0)
  local el = doc:getElementById("wrap")
  if el then
    lurek.log.info("getHtml=" .. el:getHtml(), "html")
  end
end

--@api-stub: LHtmlElement:setHtml
-- Replaces this element's inner HTML and may invalidate descendant element handles
do
  local doc = lurek.html.newDocument("<body><div id='wrap'>old</div></body>")
  doc:update(0)
  local el = doc:getElementById("wrap")
  if el then
    el:setHtml("<span>replaced</span>")
    lurek.log.info("setHtml done", "html")
  end
end

--@api-stub: LHtmlElement:appendHtml
-- Appends HTML source to this element's inner HTML
do
  local doc = lurek.html.newDocument("<body><div id='list'><p>A</p></div></body>")
  doc:update(0)
  local el = doc:getElementById("list")
  if el then
    el:appendHtml("<p>B</p>")
    lurek.log.info("appendHtml done, html=" .. el:getHtml(), "html")
  end
end

--@api-stub: LHtmlElement:remove
-- Removes this element from the document
do
  local doc = lurek.html.newDocument("<body><div id='temp'>remove me</div><p>keep</p></body>")
  doc:update(0)
  local el = doc:getElementById("temp")
  if el then
    el:remove()
    lurek.log.info("element removed", "html")
  end
end

--@api-stub: LHtmlElement:getAttribute
-- Returns an attribute value from this element
do
  local doc = lurek.html.newDocument("<body><button id='btn' class='primary'>Go</button></body>")
  doc:update(0)
  local el = doc:getElementById("btn")
  if el then
    local cls = el:getAttribute("class")
    lurek.log.info("getAttribute(class)=" .. tostring(cls), "html")
  end
end

--@api-stub: LHtmlElement:setAttribute
-- Sets or clears an attribute on this element
do
  local doc = lurek.html.newDocument("<body><button id='btn'>Go</button></body>")
  doc:update(0)
  local el = doc:getElementById("btn")
  if el then
    el:setAttribute("data-action", "start-game")
    lurek.log.info("setAttribute done", "html")
  end
end

--@api-stub: LHtmlElement:removeAttribute
-- Removes an attribute from this element
do
  local doc = lurek.html.newDocument("<body><div id='box' data-temp='1'>x</div></body>")
  doc:update(0)
  local el = doc:getElementById("box")
  if el then
    el:removeAttribute("data-temp")
    lurek.log.info("removeAttribute done", "html")
  end
end

--@api-stub: LHtmlElement:hasClass
-- Returns whether this element has a CSS class
do
  local doc = lurek.html.newDocument("<body><button id='btn' class='primary large'>Go</button></body>")
  doc:update(0)
  local el = doc:getElementById("btn")
  if el then
    lurek.log.info("hasClass(primary)=" .. tostring(el:hasClass("primary")), "html")
  end
end

--@api-stub: LHtmlElement:addClass
-- Adds a CSS class to this element
do
  local doc = lurek.html.newDocument("<body><button id='btn' class='primary'>Go</button></body>")
  doc:update(0)
  local el = doc:getElementById("btn")
  if el then
    el:addClass("large")
    lurek.log.info("addClass(large) done", "html")
  end
end

--@api-stub: LHtmlElement:removeClass
-- Removes a CSS class from this element
do
  local doc = lurek.html.newDocument("<body><button id='btn' class='primary large'>Go</button></body>")
  doc:update(0)
  local el = doc:getElementById("btn")
  if el then
    el:removeClass("large")
    lurek.log.info("removeClass(large) done", "html")
  end
end

--@api-stub: LHtmlElement:toggleClass
-- Toggles a CSS class on this element, optionally forcing the final state
do
  local doc = lurek.html.newDocument("<body><button id='btn' class='primary'>Go</button></body>")
  doc:update(0)
  local el = doc:getElementById("btn")
  if el then
    local nowHas = el:toggleClass("active")
    lurek.log.info("toggleClass(active)=" .. tostring(nowHas), "html")
  end
end

--@api-stub: LHtmlElement:getStyle
-- Returns an inline or computed style value for this element
do
  local doc = lurek.html.newDocument("<body><div id='box' style='color:red'>x</div></body>")
  doc:update(0)
  local el = doc:getElementById("box")
  if el then
    local c = el:getStyle("color")
    lurek.log.info("getStyle(color)=" .. tostring(c), "html")
  end
end

--@api-stub: LHtmlElement:setStyle
-- Sets or clears a style property on this element
do
  local doc = lurek.html.newDocument("<body><div id='box'>x</div></body>")
  doc:update(0)
  local el = doc:getElementById("box")
  if el then
    el:setStyle("font-size", "18px")
    lurek.log.info("setStyle(font-size, 18px) done", "html")
  end
end

--@api-stub: LHtmlElement:getRect
-- Returns this element's layout rectangle after relayout if needed
do
  local doc = lurek.html.newDocument("<body><div id='box'>rect</div></body>", { width = 400, height = 300 })
  doc:update(0)
  doc:relayout()
  local el = doc:getElementById("box")
  if el then
    local x, y, w, h = el:getRect()
    lurek.log.info("getRect: " .. tostring(x) .. "," .. tostring(y) .. " " .. tostring(w) .. "x" .. tostring(h), "html")
  end
end

--@api-stub: LHtmlElement:focus
-- Gives keyboard focus to this element
do
  local doc = lurek.html.newDocument("<body><input id='inp'/></body>")
  doc:update(0)
  local el = doc:getElementById("inp")
  if el then
    el:focus()
    lurek.log.info("focus() called", "html")
  end
end

--@api-stub: LHtmlElement:blur
-- Removes keyboard focus from this element when it is focused
do
  local doc = lurek.html.newDocument("<body><input id='inp'/></body>")
  doc:update(0)
  local el = doc:getElementById("inp")
  if el then
    el:focus()
    el:blur()
    lurek.log.info("blur() called", "html")
  end
end

--@api-stub: LHtmlElement:query
-- Looks up the first descendant element matching a selector
do
  local doc = lurek.html.newDocument("<body><div id='wrap'><span class='tag'>A</span></div></body>")
  doc:update(0)
  local wrap = doc:getElementById("wrap")
  if wrap then
    local child = wrap:query(".tag")
    lurek.log.info("element:query(.tag) text=" .. (child and child:getText() or "nil"), "html")
  end
end

--@api-stub: LHtmlElement:queryAll
-- Returns all descendant elements matching a selector
do
  local doc = lurek.html.newDocument("<body><ul id='list'><li>1</li><li>2</li><li>3</li></ul></body>")
  doc:update(0)
  local list = doc:getElementById("list")
  if list then
    local items = list:queryAll("li")
    lurek.log.info("element:queryAll(li) count=" .. #items, "html")
  end
end

--@api-stub: LHtmlElement:on
-- Registers an element-level event listener
do
  local doc = lurek.html.newDocument("<body><button id='btn'>click</button></body>")
  doc:update(0)
  local el = doc:getElementById("btn")
  if el then
    local handle = el:on("click", function() end)
    lurek.log.info("element:on() handle=" .. tostring(handle ~= nil), "html")
  end
end

--@api-stub: LHtmlElement:off
-- Removes an element-level event listener by handle
do
  local doc = lurek.html.newDocument("<body><button id='btn'>click</button></body>")
  doc:update(0)
  local el = doc:getElementById("btn")
  if el then
    local handle = el:on("click", function() end)
    el:off(handle)
    lurek.log.info("element:off() removed listener", "html")
  end
end

--@api-stub: LHtmlElement:type
-- Returns the Lua-visible type name for this HTML element handle
do
  local doc = lurek.html.newDocument("<body><div id='box'>Hello</div></body>")
  doc:update(0)
  local el = doc:getElementById("box")
  if el then
    lurek.log.info("element:type()=" .. el:type(), "html")
  end
end

--@api-stub: LHtmlElement:typeOf
-- Returns whether this element handle matches a supported type name
do
  local doc = lurek.html.newDocument("<body><span id='lbl'>text</span></body>")
  doc:update(0)
  local el = doc:getElementById("lbl")
  if el then
    lurek.log.info("is HtmlElement=" .. tostring(el:typeOf("HtmlElement")), "html")
    lurek.log.info("is Other=" .. tostring(el:typeOf("Other")), "html")
  end
end
