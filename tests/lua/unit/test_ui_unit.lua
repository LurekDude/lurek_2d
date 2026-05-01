-- test_ui_layout.lua
-- Unit tests for lurek.ui.loadLayout and lurek.ui.loadLayoutFile.
-- Covers: API existence, widget tree creation from a Lua table definition,
-- child attachment, ID lookup, flat and nested layouts.

-- =========================================================================
-- 1. Layout API existence
-- =========================================================================
describe("lurek.ui layout loader API exists", function()
    -- @covers lurek.ui.loadLayout
    -- @covers lurek.ui.loadLayoutFile
    -- @covers lurek.ui.renderToImage
    it("loadLayout is a function", function()
        expect_type("function", lurek.ui.loadLayout)
    end)

    it("loadLayoutFile is a function", function()
        expect_type("function", lurek.ui.loadLayoutFile)
    end)

    it("renderToImage is a function", function()
        expect_type("function", lurek.ui.renderToImage)
    end)
end)

-- =========================================================================
-- 2. loadLayout  - flat single-widget definition
-- =========================================================================
describe("lurek.ui.loadLayout  - flat single widget", function()
    -- @covers lurek.ui.loadLayout
    -- @covers lurek.ui.getWidgetCount
    it("returns a positive pool index", function()
        local before = lurek.ui.getWidgetCount()
        local idx = lurek.ui.loadLayout({ type = "panel", w = 100, h = 80 })
        expect_type("number", idx)
        local after = lurek.ui.getWidgetCount()
        -- At least one new widget was added
        assert(after > before, "widget count must increase after loadLayout")
        assert(idx > 0, "returned pool index must be > 0")
    end)

    -- @covers lurek.ui.loadLayout
    it("creates a label widget", function()
        local idx = lurek.ui.loadLayout({
            type = "label",
            text = "Score",
            x = 10, y = 10, w = 80, h = 24
        })
        assert(idx > 0, "label pool index must be > 0")
    end)

    -- @covers lurek.ui.loadLayout
    it("creates a button widget", function()
        local idx = lurek.ui.loadLayout({
            type = "button",
            text = "OK",
            x = 10, y = 10, w = 80, h = 30
        })
        assert(idx > 0, "button pool index must be > 0")
    end)

    -- @covers lurek.ui.loadLayout
    it("creates a checkbox widget", function()
        local idx = lurek.ui.loadLayout({
            type = "checkbox",
            text = "Enable",
            checked = true,
            x = 0, y = 0, w = 120, h = 24
        })
        assert(idx > 0, "checkbox pool index must be > 0")
    end)

    -- @covers lurek.ui.loadLayout
    it("creates a separator widget", function()
        local idx = lurek.ui.loadLayout({ type = "separator" })
        assert(idx > 0, "separator pool index must be > 0")
    end)
end)

-- =========================================================================
-- 3. loadLayout  - nested widget tree with id lookup
-- =========================================================================
describe("lurek.ui.loadLayout  - nested tree with id lookup", function()
    -- @covers lurek.ui.loadLayout
    -- @covers lurek.ui.getRoot
    it("nested children increase widget count", function()
        local before = lurek.ui.getWidgetCount()
        lurek.ui.loadLayout({
            type = "panel",
            x = 0, y = 0, w = 200, h = 100,
            children = {
                { type = "label",  text = "HP:",     x = 10, y = 10, w = 60, h = 20 },
                { type = "button", text = "Attack",  x = 10, y = 40, w = 80, h = 28 },
            }
        })
        local after = lurek.ui.getWidgetCount()
        -- Root panel + 2 children = +3
        assert(after >= before + 3,
            "expected at least 3 new widgets, got " .. (after - before))
    end)

    -- @covers lurek.ui.loadLayout
    -- @covers lurek.ui.getRoot
    it("findById resolves a widget given an id field", function()
        lurek.ui.loadLayout({
            type = "panel",
            x = 0, y = 0, w = 300, h = 200,
            id = "hud_root",
            children = {
                { type = "label", text = "HP:", x = 10, y = 10, w = 60, h = 20, id = "hp_label" },
            }
        })
        local root = lurek.ui.getRoot()
        local found = root.findById("hp_label")
        assert(found ~= nil, "findById('hp_label') must return a widget handle")
    end)

    -- @covers lurek.ui.loadLayout
    it("3-level deep tree loads without error", function()
        local ok = pcall(function()
            lurek.ui.loadLayout({
                type = "panel",
                children = {
                    { type = "panel",
                      children = {
                          { type = "label", text = "Deep" }
                      }
                    }
                }
            })
        end)
        assert(ok, "3-level nested loadLayout must not throw")
    end)
end)

-- =========================================================================
-- 4. loadLayout  - all supported widget types do not crash
-- =========================================================================
-- without a Lua error.
describe("lurek.ui.loadLayout  - widget type coverage", function()
    -- @covers lurek.ui.loadLayout
    local widget_types = {
        "panel", "label", "button", "checkbox", "slider", "progressbar",
        "textinput", "combobox", "list", "separator", "spacer",
        "radiobutton", "scrollbar", "switch", "badge", "spinbox",
        "image", "layout", "toolbar", "statusbar", "scrollpanel",
        "splitpanel", "tabbar", "window", "dialog", "treeview",
        "menubar", "dockpanel", "accordion", "ninepatch",
        "colorpicker", "tooltippanel",
    }

    for _, wtype in ipairs(widget_types) do
        it("type '" .. wtype .. "' loads without error", function()
            local ok = pcall(function()
                lurek.ui.loadLayout({ type = wtype })
            end)
            assert(ok, "loadLayout({type='" .. wtype .. "'}) must not throw")
        end)
    end
end)

-- =========================================================================
-- 5. Custom widget extensibility
-- =========================================================================
describe("UI custom widget", function()
    -- @covers lurek.ui.newCustomWidget
    it("newCustomWidget is a function", function()
        expect_type("function", lurek.ui.newCustomWidget)
    end)

    -- @covers lurek.ui.newCustomWidget
    it("newCustomWidget creates a widget handle", function()
        local before = lurek.ui.getWidgetCount()
        local w = lurek.ui.newCustomWidget({
            x = 10, y = 20, width = 200, height = 150,
            id = "test_custom",
        })
        expect_not_nil(w)
        local after = lurek.ui.getWidgetCount()
        assert(after > before, "widget count must increase after newCustomWidget")
    end)

    -- @covers lurek.ui.newCustomWidget
    -- @covers widget:setOnDraw
    it("setOnDraw method exists on widget", function()
        ---@type any
        local w = lurek.ui.newCustomWidget({ width = 100, height = 100 })
        expect_not_nil(w)
        expect_type("function", w.setOnDraw)
    end)

    -- @covers lurek.ui.newCustomWidget
    -- @covers widget:setOnDraw
    it("setOnDraw accepts a callback without error", function()
        ---@type any
        local w = lurek.ui.newCustomWidget({ x = 0, y = 0, width = 100, height = 50 })
        local ok = pcall(function()
            w:setOnDraw(function(rect)
                -- rect table is passed by draw(); no draw call here
            end)
        end)
        expect_true(ok, "setOnDraw must not throw")
    end)

    -- @covers lurek.ui.newCustomWidget
    it("loadLayout type='custom' does not crash", function()
        local ok = pcall(function()
            lurek.ui.loadLayout({
                type = "custom",
                x = 0, y = 0, w = 64, h = 64, id = "layout_custom",
            })
        end)
        expect_true(ok, "loadLayout({type='custom'}) must not throw")
    end)

    -- @covers lurek.ui.draw
    it("draw invokes on_draw callback", function()
        local called = false
        ---@type any
        local w = lurek.ui.newCustomWidget({ x = 5, y = 5, width = 40, height = 30 })
        w:setOnDraw(function(rect)
            called = true
        end)
        lurek.ui.draw()
        expect_true(called, "on_draw callback must be called by lurek.ui.draw()")
    end)
end)


local function make_basic_widget(opts)
    ---@type any
    local widget = lurek.ui.newCustomWidget(opts or {
        x = 1,
        y = 2,
        width = 3,
        height = 4,
    })

    return widget
end

describe("Lua coverage for lurek.ui.setPosition", function()
    it("lurek.ui.setPosition works", function()
        -- @covers lurek.ui.setPosition
        local widget = make_basic_widget()
        widget["setPosition"](12, 34)

        local x, y = widget["getPosition"]()
        expect_equal(12, x)
        expect_equal(34, y)
    end)
end)

describe("Lua coverage for lurek.ui.getPosition", function()
    it("lurek.ui.getPosition works", function()
        -- @covers lurek.ui.getPosition
        local widget = make_basic_widget({
            x = 9,
            y = 11,
            width = 30,
            height = 40,
        })

        local x, y = widget["getPosition"]()
        expect_equal(9, x)
        expect_equal(11, y)
    end)
end)

describe("Lua coverage for lurek.ui.setSize", function()
    it("lurek.ui.setSize works", function()
        -- @covers lurek.ui.setSize
        local widget = make_basic_widget()
        widget["setSize"](56, 78)

        local w, h = widget["getSize"]()
        expect_equal(56, w)
        expect_equal(78, h)
    end)
end)

describe("Lua coverage for lurek.ui.getSize", function()
    it("lurek.ui.getSize works", function()
        -- @covers lurek.ui.getSize
        local widget = make_basic_widget({
            x = 0,
            y = 0,
            width = 21,
            height = 34,
        })

        local w, h = widget["getSize"]()
        expect_equal(21, w)
        expect_equal(34, h)
    end)
end)

describe("Lua coverage for lurek.ui.setVisible", function()
    it("lurek.ui.setVisible works", function()
        -- @covers lurek.ui.setVisible
        local widget = make_basic_widget()
        widget["setVisible"](false)
        expect_false(widget["isVisible"]())

        widget["setVisible"](true)
        expect_true(widget["isVisible"]())
    end)
end)

describe("Lua coverage for lurek.ui.isVisible", function()
    it("lurek.ui.isVisible works", function()
        -- @covers lurek.ui.isVisible
        local widget = make_basic_widget()
        expect_false(widget["isVisible"]())
    end)
end)

describe("Lua coverage for lurek.ui.setEnabled", function()
    it("lurek.ui.setEnabled works", function()
        -- @covers lurek.ui.setEnabled
        local widget = make_basic_widget()
        widget["setEnabled"](false)
        expect_false(widget["isEnabled"]())

        widget["setEnabled"](true)
        expect_true(widget["isEnabled"]())
    end)
end)

describe("Lua coverage for lurek.ui.isEnabled", function()
    it("lurek.ui.isEnabled works", function()
        -- @covers lurek.ui.isEnabled
        local widget = make_basic_widget()
        expect_false(widget["isEnabled"]())
    end)
end)

describe("Lua coverage for lurek.ui.setId", function()
    it("lurek.ui.setId works", function()
        -- @covers lurek.ui.setId
        local widget = make_basic_widget()
        widget["setId"]("hud_button")

        expect_equal("hud_button", widget["getId"]())
    end)
end)

describe("Lua coverage for lurek.ui.getId", function()
    it("lurek.ui.getId works", function()
        -- @covers lurek.ui.getId
        local widget = make_basic_widget({
            x = 0,
            y = 0,
            width = 10,
            height = 10,
            id = "score_label",
        })

        expect_equal("score_label", widget["getId"]())
    end)
end)

describe("Lua coverage for lurek.ui.setTooltip", function()
    it("lurek.ui.setTooltip works", function()
        -- @covers lurek.ui.setTooltip
        local widget = make_basic_widget()
        widget["setTooltip"]("Click to continue")

        expect_equal("Click to continue", widget["getTooltip"]())
    end)
end)

describe("Lua coverage for lurek.ui.getTooltip", function()
    it("lurek.ui.getTooltip works", function()
        -- @covers lurek.ui.getTooltip
        local widget = make_basic_widget()
        expect_equal("", widget["getTooltip"]())

        widget["setTooltip"]("Opens the inventory")
        expect_equal("Opens the inventory", widget["getTooltip"]())
    end)
end)

test_summary()
