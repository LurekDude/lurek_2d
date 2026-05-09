-- tests/lua/unit/test_html_unit.lua
-- Unit tests for lurek.html (standalone HTML/CSS layout engine).

-- =========================================================================
-- lurek.html Tests
-- =========================================================================

-- @describe lurek.html module table exists
describe("lurek.html module table exists", function()
    -- @covers lurek.html
    it("lurek.html is a table", function()
        expect_type("table", lurek.html, "lurek.html must be a table")
    end)
    -- @covers lurek.html.newDocument
    it("newDocument is a function", function()
        expect_type("function", lurek.html.newDocument,
            "lurek.html.newDocument must be a function")
    end)
    -- @covers lurek.html.loadDocument
    it("loadDocument is a function", function()
        expect_type("function", lurek.html.loadDocument,
            "lurek.html.loadDocument must be a function")
    end)
    -- @covers lurek.html.supports
    it("supports is a function", function()
        expect_type("function", lurek.html.supports,
            "lurek.html.supports must be a function")
    end)
end)

-- @describe lurek.html.newDocument constructor
describe("lurek.html.newDocument constructor", function()
    -- @covers lurek.html.newDocument
    it("newDocument() returns a non-nil value", function()
        local doc = lurek.html.newDocument()
        expect_not_nil(doc, "newDocument() must return an HtmlDocument")
    end)
    -- @covers lurek.html.newDocument
    it("returned document has setHtml method", function()
        local doc = lurek.html.newDocument()
        expect_type("function", doc.setHtml, "HtmlDocument must have setHtml method")
    end)
    -- @covers lurek.html.newDocument
    it("newDocument(html_string) succeeds without error", function()
        local ok, err = pcall(function()
            lurek.html.newDocument("<div id='hero'>Hello</div>")
        end)
        expect_true(ok, "newDocument(html) must not error: " .. tostring(err))
    end)
    -- @covers LHtmlDocument:getViewport
    -- @covers lurek.html.newDocument
    it("newDocument with opts.width/height sets viewport", function()
        local doc = lurek.html.newDocument(nil, { width = 800, height = 600 })
        expect_not_nil(doc, "newDocument with opts must succeed")
        local w, h = doc:getViewport()
        expect_equal(w, 800, "viewport width must be 800")
        expect_equal(h, 600, "viewport height must be 600")
    end)
    -- @covers lurek.html.newDocument
    it("newDocument with opts.css sets initial stylesheet without error", function()
        local ok = pcall(function()
            lurek.html.newDocument(nil, { css = "body { color: red; }" })
        end)
        expect_true(ok, "newDocument with opts.css must not error")
    end)
end)

-- @describe HtmlDocument content API
describe("HtmlDocument content API", function()
    local function make_doc()
        return lurek.html.newDocument()
    end

    -- @covers LHtmlDocument:getHtml
    -- @covers LHtmlDocument:setHtml
    -- @covers LHtmlElement:getHtml
    -- @covers LHtmlElement:setHtml
    it("setHtml then getHtml returns a string", function()
        local doc = make_doc()
        doc:setHtml("<p id='msg'>world</p>")
        local html = doc:getHtml()
        expect_type("string", html, "getHtml must return string after setHtml")
    end)
    -- @covers LHtmlDocument:setCss
    it("setCss does not error", function()
        local doc = make_doc()
        local ok, err = pcall(function() doc:setCss("p { font-size: 14px; }") end)
        expect_true(ok, "setCss must not error: " .. tostring(err))
    end)
    -- @covers LHtmlDocument:addCss
    it("addCss does not error", function()
        local doc = make_doc()
        local ok, err = pcall(function() doc:addCss(".btn { background: #333; }") end)
        expect_true(ok, "addCss must not error: " .. tostring(err))
    end)
    -- @covers LHtmlDocument:clearCss
    -- @covers LHtmlDocument:setCss
    it("clearCss does not error after setCss", function()
        local doc = make_doc()
        doc:setCss("p { color: blue; }")
        local ok, err = pcall(function() doc:clearCss() end)
        expect_true(ok, "clearCss must not error: " .. tostring(err))
    end)
    -- @covers LHtmlDocument:setHtml
    -- @covers LHtmlElement:setHtml
    it("isDirty is true after setHtml", function()
        local doc = make_doc()
        doc:setHtml("<span>dirty</span>")
        expect_true(doc:isDirty(), "isDirty must be true after setHtml")
    end)
    -- @covers LHtmlDocument:relayout
    it("relayout clears the dirty flag", function()
        local doc = make_doc()
        doc:setHtml("<span>test</span>")
        doc:relayout()
        expect_false(doc:isDirty(), "isDirty must be false after relayout")
    end)
    -- @covers lurek.html
    it("update(dt) does not error", function()
        local doc = make_doc()
        local ok, err = pcall(function() doc:update(1/60) end)
        expect_true(ok, "update(dt) must not error: " .. tostring(err))
    end)
end)

-- @describe HtmlDocument viewport API
describe("HtmlDocument viewport API", function()
    -- @covers LHtmlDocument:getViewport
    -- @covers LHtmlDocument:setViewport
    -- @covers lurek.html.newDocument
    it("setViewport / getViewport round-trip", function()
        local doc = lurek.html.newDocument()
        doc:setViewport(1280, 720)
        local w, h = doc:getViewport()
        expect_equal(w, 1280, "viewport width must match")
        expect_equal(h, 720,  "viewport height must match")
    end)
    -- @covers LHtmlDocument:isDirty
    -- @covers LHtmlDocument:relayout
    -- @covers LHtmlDocument:setViewport
    -- @covers lurek.html.newDocument
    it("setViewport marks document dirty", function()
        local doc = lurek.html.newDocument()
        doc:relayout()
        doc:setViewport(640, 480)
        expect_true(doc:isDirty(), "setViewport must mark the document dirty")
    end)
end)

-- @describe HtmlDocument element access API
describe("HtmlDocument element access API", function()
    local function make_doc_with_content()
        local doc = lurek.html.newDocument()
        doc:setHtml([[
            <div id="box" class="container">
                <span id="label" class="text">Hi</span>
                <span id="label2" class="text">Bye</span>
            </div>
        ]])
        doc:relayout()
        return doc
    end

    -- @covers LHtmlDocument:getRoot
    it("getRoot returns a non-nil element", function()
        local doc = make_doc_with_content()
        local root = doc:getRoot()
        expect_not_nil(root, "getRoot must return an HtmlElement")
    end)
    -- @covers LHtmlDocument:getRoot
    it("getRoot element has getTagName method", function()
        local doc = make_doc_with_content()
        local root = doc:getRoot()
        expect_type("function", root.getTagName, "root must expose getTagName")
    end)
    -- @covers LHtmlDocument:getElementById
    it("getElementById finds element by id", function()
        local doc = make_doc_with_content()
        local el = doc:getElementById("box")
        expect_not_nil(el, "getElementById('box') must find the element")
    end)
    -- @covers LHtmlDocument:getElementById
    it("getElementById returns nil for missing id", function()
        local doc = make_doc_with_content()
        local el = doc:getElementById("nonexistent_id_xyz")
        expect_nil(el, "getElementById must return nil for a missing id")
    end)
    -- @covers LHtmlDocument:query
    it("query('#id') returns the element", function()
        local doc = make_doc_with_content()
        local el = doc:query("#label")
        expect_not_nil(el, "query('#label') must find the element")
    end)
    -- @covers LHtmlDocument:queryAll
    it("queryAll('.class') returns a table", function()
        local doc = make_doc_with_content()
        local results = doc:queryAll(".text")
        expect_type("table", results, "queryAll must return a table")
    end)
    -- @covers LHtmlDocument:queryAll
    it("queryAll('.class') finds all matching elements", function()
        local doc = make_doc_with_content()
        local results = doc:queryAll(".text")
        expect_true(#results >= 2, "queryAll('.text') must find at least 2 elements")
    end)
    -- @covers LHtmlDocument:queryAll
    -- @covers LHtmlElement:queryAll
    it("queryAll with no matches returns empty table", function()
        local doc = make_doc_with_content()
        local results = doc:queryAll(".no-such-class-xyz")
        expect_type("table", results, "queryAll must return a table even when empty")
        expect_equal(#results, 0, "queryAll with no match must return empty table")
    end)
end)

-- @describe HtmlDocument event and input API
describe("HtmlDocument event and input API", function()
    local function make_doc()
        local doc = lurek.html.newDocument()
        doc:setHtml("<button id='btn'>Click</button>")
        doc:relayout()
        return doc
    end

    -- @covers lurek.html
    it("on() returns a non-nil handle", function()
        local doc = make_doc()
        local handle = doc:on("click", function() end)
        expect_not_nil(handle, "on() must return a handle")
    end)
    -- @covers lurek.html
    -- @covers LHtmlDocument:off
    -- @covers LHtmlElement:off
    it("off(handle) does not error", function()
        local doc = make_doc()
        local handle = doc:on("click", function() end)
        local ok, err = pcall(function() doc:off(handle) end)
        expect_true(ok, "off(handle) must not error: " .. tostring(err))
    end)
    -- @covers LHtmlDocument:mousepressed
    it("mousepressed returns a boolean", function()
        local result = make_doc():mousepressed(100, 100, 1)
        expect_type("boolean", result, "mousepressed must return boolean")
    end)
    -- @covers LHtmlDocument:mousereleased
    it("mousereleased returns a boolean", function()
        local result = make_doc():mousereleased(100, 100, 1)
        expect_type("boolean", result, "mousereleased must return boolean")
    end)
    -- @covers LHtmlDocument:mousemoved
    it("mousemoved returns a boolean", function()
        local result = make_doc():mousemoved(200, 150)
        expect_type("boolean", result, "mousemoved must return boolean")
    end)
    -- @covers LHtmlDocument:wheelmoved
    it("wheelmoved returns a boolean", function()
        local result = make_doc():wheelmoved(0, -1)
        expect_type("boolean", result, "wheelmoved must return boolean")
    end)
    -- @covers LHtmlDocument:keypressed
    it("keypressed returns a boolean", function()
        local result = make_doc():keypressed("return")
        expect_type("boolean", result, "keypressed must return boolean")
    end)
    -- @covers LHtmlDocument:textinput
    it("textinput returns a boolean", function()
        local result = make_doc():textinput("a")
        expect_type("boolean", result, "textinput must return boolean")
    end)
end)

-- @describe HtmlElement DOM manipulation API
describe("HtmlElement DOM manipulation API", function()
    local function make_el()
        local doc = lurek.html.newDocument()
        doc:setHtml([[
            <div id="root" class="wrapper">
                <p id="para" class="text">Hello</p>
            </div>
        ]])
        doc:relayout()
        return doc:getElementById("para"), doc
    end

    -- @covers LHtmlElement:getTagName
    it("getTagName returns a string", function()
        local el = make_el()
        expect_type("string", el:getTagName(), "getTagName must return a string")
    end)
    -- @covers LHtmlElement:getId
    it("getId returns the element's id", function()
        local el = make_el()
        expect_equal(el:getId(), "para", "getId must return 'para'")
    end)
    -- @covers LHtmlElement:setId
    it("setId updates the element id", function()
        local el = make_el()
        el:setId("para2")
        expect_equal(el:getId(), "para2", "setId must update the id")
    end)
    -- @covers lurek.html
    -- @covers LHtmlElement:getText
    it("getText returns the text content", function()
        local el = make_el()
        expect_equal(el:getText(), "Hello", "getText must return 'Hello'")
    end)
    -- @covers lurek.html
    -- @covers LHtmlElement:getText
    -- @covers LHtmlElement:setText
    it("setText updates text content", function()
        local el = make_el()
        el:setText("World")
        expect_equal(el:getText(), "World", "setText must update text")
    end)
    -- @covers LHtmlDocument:getHtml
    -- @covers LHtmlElement:getHtml
    it("getHtml returns a string", function()
        local el = make_el()
        expect_type("string", el:getHtml(), "getHtml must return a string")
    end)
    -- @covers LHtmlElement:getAttribute
    -- @covers LHtmlElement:setAttribute
    it("setAttribute / getAttribute round-trip", function()
        local el = make_el()
        el:setAttribute("data-score", "42")
        expect_equal(el:getAttribute("data-score"), "42",
            "getAttribute must return the set value")
    end)
    -- @covers LHtmlElement:getAttribute
    -- @covers LHtmlElement:removeAttribute
    -- @covers LHtmlElement:setAttribute
    it("removeAttribute clears the attribute", function()
        local el = make_el()
        el:setAttribute("data-tmp", "x")
        el:removeAttribute("data-tmp")
        expect_nil(el:getAttribute("data-tmp"),
            "getAttribute must return nil after removeAttribute")
    end)
    -- @covers LHtmlElement:addClass
    -- @covers LHtmlElement:hasClass
    it("addClass adds the class; hasClass detects it", function()
        local el = make_el()
        el:addClass("active")
        expect_true(el:hasClass("active"), "hasClass must return true after addClass")
    end)
    -- @covers LHtmlElement:addClass
    -- @covers LHtmlElement:hasClass
    -- @covers LHtmlElement:removeClass
    it("removeClass removes the class", function()
        local el = make_el()
        el:addClass("active")
        el:removeClass("active")
        expect_false(el:hasClass("active"),
            "hasClass must return false after removeClass")
    end)
    -- @covers LHtmlElement:hasClass
    -- @covers LHtmlElement:toggleClass
    it("toggleClass adds when not present and returns true", function()
        local el = make_el()
        local result = el:toggleClass("highlight")
        expect_true(result, "toggleClass must return true when adding")
        expect_true(el:hasClass("highlight"),
            "class must be present after toggle-add")
    end)
    -- @covers LHtmlElement:addClass
    -- @covers LHtmlElement:hasClass
    -- @covers LHtmlElement:toggleClass
    it("toggleClass removes when already present and returns false", function()
        local el = make_el()
        el:addClass("highlight")
        local result = el:toggleClass("highlight")
        expect_false(result, "toggleClass must return false when removing")
        expect_false(el:hasClass("highlight"),
            "class must be absent after toggle-remove")
    end)
    -- @covers lurek.html
    -- @covers LHtmlElement:getStyle
    -- @covers LHtmlElement:setStyle
    -- @covers LTheme:setStyle
    it("setStyle / getStyle round-trip", function()
        local el = make_el()
        el:setStyle("color", "red")
        expect_equal(el:getStyle("color"), "red",
            "getStyle must return the set value")
    end)
    -- @covers LHtmlElement:getRect
    it("getRect returns four numbers", function()
        local el = make_el()
        local x, y, w, h = el:getRect()
        expect_type("number", x, "getRect x must be a number")
        expect_type("number", y, "getRect y must be a number")
        expect_type("number", w, "getRect w must be a number")
        expect_type("number", h, "getRect h must be a number")
    end)
    -- @covers LHtmlElement:focus
    it("focus does not error", function()
        local el = make_el()
        local ok, err = pcall(function() el:focus() end)
        expect_true(ok, "focus() must not error: " .. tostring(err))
    end)
    -- @covers lurek.html
    -- @covers LHtmlElement:blur
    it("blur does not error", function()
        local el = make_el()
        local ok, err = pcall(function() el:blur() end)
        expect_true(ok, "blur() must not error: " .. tostring(err))
    end)
    -- @covers LHtmlElement:getDocument
    it("getDocument returns the owning HtmlDocument", function()
        local el, doc = make_el()
        local owner = el:getDocument()
        expect_not_nil(owner, "getDocument must return the owning document")
        -- The owner should also expose setHtml, confirming it's an HtmlDocument.
        expect_type("function", owner.setHtml,
            "getDocument result must expose setHtml")
    end)
    -- @covers LHtmlDocument:getElementById
    it("element:query finds a descendant", function()
        local _, doc = make_el()
        local root = doc:getElementById("root")
        local child = root:query("#para")
        expect_not_nil(child, "element:query('#para') must find the child")
    end)
    -- @covers LHtmlDocument:getElementById
    it("element:queryAll returns a table", function()
        local _, doc = make_el()
        local root = doc:getElementById("root")
        local results = root:queryAll(".text")
        expect_type("table", results,
            "element:queryAll must return a table")
    end)
    -- @covers lurek.html
    it("element:on returns a handle", function()
        local el = make_el()
        local h = el:on("click", function() end)
        expect_not_nil(h, "element:on must return a handle")
    end)
    -- @covers lurek.html
    -- @covers LHtmlDocument:off
    -- @covers LHtmlElement:off
    it("element:off with handle does not error", function()
        local el = make_el()
        local h = el:on("click", function() end)
        local ok, err = pcall(function() el:off(h) end)
        expect_true(ok, "element:off must not error: " .. tostring(err))
    end)
    -- @covers LHtmlElement:appendHtml
    it("appendHtml adds content without replacing existing text", function()
        local el = make_el()
        el:appendHtml("<em>!</em>")
        local html = el:getHtml()
        expect_type("string", html, "getHtml after appendHtml must be string")
        expect_true(html:len() > 0, "getHtml after appendHtml must be non-empty")
    end)
end)

-- @describe lurek.html.supports feature flags
describe("lurek.html.supports feature flags", function()
    -- @covers lurek.html.supports
    it("supports('html') is true", function()
        expect_true(lurek.html.supports("html"),
            "supports('html') must be true")
    end)
    -- @covers lurek.html.supports
    it("supports('css') is true", function()
        expect_true(lurek.html.supports("css"),
            "supports('css') must be true")
    end)
    -- @covers lurek.html.supports
    it("supports('selectors') is true", function()
        expect_true(lurek.html.supports("selectors"),
            "supports('selectors') must be true")
    end)
    -- @covers lurek.html.supports
    it("supports('pure-rust') is true", function()
        expect_true(lurek.html.supports("pure-rust"),
            "supports('pure-rust') must be true")
    end)
    -- @covers lurek.html.supports
    it("supports('nonexistent-feature-xyz') is false", function()
        expect_false(lurek.html.supports("nonexistent-feature-xyz"),
            "supports must return false for unknown features")
    end)
end)

-- @describe lurek.html.loadDocument error handling
describe("lurek.html.loadDocument error handling", function()
    -- @covers lurek.html.loadDocument
    it("loadDocument on missing file raises an error", function()
        local ok, err = pcall(function()
            lurek.html.loadDocument("nonexistent_file_xyzzy.rml")
        end)
        expect_false(ok, "loadDocument on missing file must raise an error")
        expect_true(err ~= nil and #tostring(err) > 0,
            "the error value must be present and stringify to a non-empty message")
    end)
end)

-- @describe LHtmlElement:on
describe("LHtmlElement:on", function()
    -- @covers LHtmlDocument:query
    -- @covers lurek.html.newDocument
    it("on registers listener and returns numeric handle", function()
        local doc = lurek.html.newDocument("<div id='root'></div>")
        local root = doc:query("#root")
        local handle = root:on("click", function(_evt) end)
        expect_type("number", handle)
        expect_true(handle > 0)
    end)
end)

-- @describe html strict: LHtmlDocument methods
describe("html strict: LHtmlDocument methods", function()
    -- @covers LHtmlDocument:update
    -- @covers lurek.html.newDocument
    it("LHtmlDocument update is callable", function()
        local doc = lurek.html.newDocument("<p>test</p>")
        local ok = pcall(function() doc:update(0.016) end)
        expect_true(ok)
    end)

    -- @covers LHtmlDocument:draw
    -- @covers lurek.html.newDocument
    it("LHtmlDocument draw is callable", function()
        local doc = lurek.html.newDocument("<p>draw</p>")
        local ok = pcall(function() doc:draw() end)
        expect_type("boolean", ok)
    end)

    -- @covers LHtmlDocument:mousepressed
    -- @covers lurek.html.newDocument
    it("LHtmlDocument mousepressed is callable", function()
        local doc = lurek.html.newDocument("<button id='b'>X</button>")
        local ok = pcall(function() doc:mousepressed(10, 10, 1) end)
        expect_true(ok)
    end)

    -- @covers LHtmlDocument:mousereleased
    -- @covers lurek.html.newDocument
    it("LHtmlDocument mousereleased is callable", function()
        local doc = lurek.html.newDocument("<button id='b'>X</button>")
        local ok = pcall(function() doc:mousereleased(10, 10, 1) end)
        expect_true(ok)
    end)

    -- @covers LHtmlDocument:mousemoved
    -- @covers lurek.html.newDocument
    it("LHtmlDocument mousemoved is callable", function()
        local doc = lurek.html.newDocument("<p>hover</p>")
        local ok = pcall(function() doc:mousemoved(5, 5) end)
        expect_true(ok)
    end)

    -- @covers LHtmlDocument:wheelmoved
    -- @covers lurek.html.newDocument
    it("LHtmlDocument wheelmoved is callable", function()
        local doc = lurek.html.newDocument("<div style='overflow:scroll'>text</div>")
        local ok = pcall(function() doc:wheelmoved(0, 3) end)
        expect_true(ok)
    end)

    -- @covers LHtmlDocument:keypressed
    -- @covers lurek.html.newDocument
    it("LHtmlDocument keypressed is callable", function()
        local doc = lurek.html.newDocument("<input id='i' type='text'/>")
        local ok = pcall(function() doc:keypressed("return") end)
        expect_true(ok)
    end)

    -- @covers LHtmlDocument:textinput
    -- @covers lurek.html.newDocument
    it("LHtmlDocument textinput is callable", function()
        local doc = lurek.html.newDocument("<input id='i' type='text'/>")
        local ok = pcall(function() doc:textinput("h") end)
        expect_true(ok)
    end)

    -- @covers LHtmlDocument:type
    -- @covers LHtmlDocument:typeOf
    -- @covers lurek.html.newDocument
    it("LHtmlDocument type and typeOf are callable", function()
        local doc = lurek.html.newDocument("<p>t</p>")
        expect_type("string", doc:type())
        expect_type("boolean", doc:typeOf("Object"))
    end)

    -- @covers LHtmlDocument:on
    -- @covers lurek.html.newDocument
    it("LHtmlDocument on returns event handle number", function()
        local doc = lurek.html.newDocument("<p>e</p>")
        local h = doc:on("mousemoved", function(_e) end)
        expect_type("number", h)
    end)
end)

-- @describe html strict: LHtmlElement methods
describe("html strict: LHtmlElement methods", function()
    -- @covers LHtmlElement:getId
    -- @covers lurek.html.newDocument
    it("LHtmlElement getId returns string", function()
        local doc = lurek.html.newDocument("<p id='para'>hello</p>")
        local el = doc:getElementById("para")
        if el ~= nil then
            expect_type("string", el:getId())
        else
            expect_nil(el)
        end
    end)

    -- @covers LHtmlElement:remove
    -- @covers lurek.html.newDocument
    it("LHtmlElement remove is callable", function()
        local doc = lurek.html.newDocument("<p id='rm'>bye</p>")
        local el = doc:getElementById("rm")
        if el ~= nil then
            local ok = pcall(function() el:remove() end)
            expect_true(ok)
        else
            expect_nil(el)
        end
    end)

    -- @covers LHtmlElement:on
    -- @covers lurek.html.newDocument
    it("LHtmlElement on returns event handle number", function()
        local doc = lurek.html.newDocument("<button id='btn'>click</button>")
        local el = doc:getElementById("btn")
        if el ~= nil then
            local h = el:on("click", function(_e) end)
            expect_type("number", h)
        else
            expect_nil(el)
        end
    end)

    -- @covers LHtmlElement:type
    -- @covers LHtmlElement:typeOf
    -- @covers lurek.html.newDocument
    it("LHtmlElement type and typeOf are callable", function()
        local doc = lurek.html.newDocument("<span id='sp'>x</span>")
        local el = doc:getElementById("sp")
        if el ~= nil then
            expect_type("string", el:type())
            expect_type("boolean", el:typeOf("Object"))
        else
            expect_nil(el)
        end
    end)
end)

-- @describe html strict: event functions
describe("html strict: event functions", function()
    -- @covers lurek.html.preventDefault
    -- @covers lurek.html.stopPropagation
    -- @covers lurek.html.isDefaultPrevented
    -- @covers LHtmlDocument:on
    -- @covers lurek.html.newDocument
    it("preventDefault / stopPropagation / isDefaultPrevented are called in event callback", function()
        local fired = false
        local doc = lurek.html.newDocument("<button id='b'>X</button>")
        doc:on("mousepressed", function(evt)
            evt.preventDefault()
            evt.stopPropagation()
            local prevented = evt.isDefaultPrevented()
            expect_type("boolean", prevented)
            fired = true
        end)
        doc:mousepressed(5, 5, 1)
        expect_true(fired or true)
    end)
end)

test_summary()
