-- Evidence tests: html module
-- Produces text/JSON artifacts from lurek.html document lifecycle.
-- and saves state snapshots to the evidence output directory.

describe("evidence: html", function()
    before_each(function()
        ensure_evidence_dir("html")
    end)

    local function write_artifact(path, contents)
        local f = io and io.open and io.open(path, "w") or nil
        if f then
            f:write(contents)
            f:close()
        end
    end

    -- @evidence file
    it("creates a document and saves markup snapshot", function()
        local dir  = evidence_output_dir("html")
        local path = dir .. "document_markup.txt"
        local doc = lurek.html.newDocument([[
<body>
  <div id="header" class="bar">Title</div>
  <div id="content"><p>Hello</p></div>
</body>
        ]], { width = 800, height = 600 })
        local markup = doc:getHtml()
        write_artifact(path, markup)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("saves element layout rects after CSS", function()
        local dir  = evidence_output_dir("html")
        local path = dir .. "element_rects.json"
        local doc = lurek.html.newDocument([[
<body>
  <div id="box" style="width:100px;height:50px;padding:10px;">Box</div>
</body>
        ]], { width = 400, height = 300 })
        doc:setCss("body { margin: 0; }")
        doc:relayout()
        local el = doc:getElementById("box")
        local x, y, w, h = 0, 0, 0, 0
        if el then
            x, y, w, h = el:getRect()
        end
        local json = string.format('{"x":%d,"y":%d,"w":%d,"h":%d}', x, y, w, h)
        write_artifact(path, json)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("saves query results for list items", function()
        local dir  = evidence_output_dir("html")
        local path = dir .. "list_items.json"
        local doc = lurek.html.newDocument([[
<body>
  <ul>
    <li class="item">Apple</li>
    <li class="item">Banana</li>
    <li class="item">Cherry</li>
  </ul>
</body>
        ]])
        local items = doc:queryAll(".item")
        local texts = {}
        for _, el in ipairs(items) do
            table.insert(texts, '"' .. el:getText() .. '"')
        end
        local json = "[" .. table.concat(texts, ",") .. "]"
        write_artifact(path, json)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("saves class manipulation evidence", function()
        local dir  = evidence_output_dir("html")
        local path = dir .. "class_state.json"
        local doc = lurek.html.newDocument('<body><div id="el" class="a b">Test</div></body>')
        local el = doc:getElementById("el")
        local before_has_c = el:hasClass("c")
        el:addClass("c")
        local after_has_c = el:hasClass("c")
        el:toggleClass("a")
        local after_has_a = el:hasClass("a")
        local json = string.format(
            '{"before_has_c":%s,"after_has_c":%s,"after_toggle_a":%s}',
            tostring(before_has_c), tostring(after_has_c), tostring(after_has_a)
        )
        write_artifact(path, json)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("saves event dispatch evidence", function()
        local dir  = evidence_output_dir("html")
        local path = dir .. "event_log.json"
        local doc = lurek.html.newDocument('<body><button id="btn">Click</button></body>', {
            width = 200, height = 100,
        })
        local events = {}
        doc:on("click", function(ev)
            table.insert(events, string.format('{"type":"%s","x":%d,"y":%d}', ev.type or "click", ev.x or 0, ev.y or 0))
        end)
        doc:mousepressed(50, 50, 1)
        doc:mousereleased(50, 50, 1)
        local json = "[" .. table.concat(events, ",") .. "]"
        write_artifact(path, json)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("saves viewport change evidence", function()
        local dir  = evidence_output_dir("html")
        local path = dir .. "viewport.json"
        local doc = lurek.html.newDocument("<body></body>", { width = 640, height = 480 })
        doc:setViewport(1920, 1080)
        local w, h = doc:getViewport()
        local json = string.format('{"width":%d,"height":%d}', w or 0, h or 0)
        write_artifact(path, json)
        expect_evidence_created(path)
    end)
end)
test_summary()
