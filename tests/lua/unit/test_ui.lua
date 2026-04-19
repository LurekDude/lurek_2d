-- test_ui_layout.lua
-- Unit tests for lurek.ui.loadLayout and lurek.ui.loadLayoutFile.
-- Covers: API existence, widget tree creation from a Lua table definition,
-- child attachment, ID lookup, flat and nested layouts.

-- =========================================================================
-- 1. Layout API existence
-- =========================================================================
-- @description Confirms the three layout-loader functions are exposed on lurek.ui.
describe("lurek.ui layout loader API exists", function()
    -- @covers lurek.ui.loadLayout
    -- @covers lurek.ui.loadLayoutFile
    -- @covers lurek.ui.renderToImage
    -- @description loadLayout is a function
    it("loadLayout is a function", function()
        expect_type("function", lurek.ui.loadLayout)
    end)

    -- @description loadLayoutFile is a function
    it("loadLayoutFile is a function", function()
        expect_type("function", lurek.ui.loadLayoutFile)
    end)

    -- @description renderToImage is a function
    it("renderToImage is a function", function()
        expect_type("function", lurek.ui.renderToImage)
    end)
end)

-- =========================================================================
-- 2. loadLayout — flat single-widget definition
-- =========================================================================
-- @description loadLayout creates a panel widget from a minimal Lua table.
describe("lurek.ui.loadLayout — flat single widget", function()
    -- @covers lurek.ui.loadLayout
    -- @covers lurek.ui.getWidgetCount
    -- @description Returns a positive pool index
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
    -- @description Creates a label from a type=label definition
    it("creates a label widget", function()
        local idx = lurek.ui.loadLayout({
            type = "label",
            text = "Score",
            x = 10, y = 10, w = 80, h = 24
        })
        assert(idx > 0, "label pool index must be > 0")
    end)

    -- @covers lurek.ui.loadLayout
    -- @description Creates a button from a type=button definition
    it("creates a button widget", function()
        local idx = lurek.ui.loadLayout({
            type = "button",
            text = "OK",
            x = 10, y = 10, w = 80, h = 30
        })
        assert(idx > 0, "button pool index must be > 0")
    end)

    -- @covers lurek.ui.loadLayout
    -- @description Creates a checkbox from a type=checkbox definition
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
    -- @description Accepts type=separator without crashing
    it("creates a separator widget", function()
        local idx = lurek.ui.loadLayout({ type = "separator" })
        assert(idx > 0, "separator pool index must be > 0")
    end)
end)

-- =========================================================================
-- 3. loadLayout — nested widget tree with id lookup
-- =========================================================================
-- @description loadLayout builds child widgets and id-based lookup finds them.
describe("lurek.ui.loadLayout — nested tree with id lookup", function()
    -- @covers lurek.ui.loadLayout
    -- @covers lurek.ui.getRoot
    -- @description Nested children increase the widget count
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
    -- @description findById finds a widget given a string id field
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
    -- @description Deeply nested (3-level) tree loads without error
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
-- 4. loadLayout — all supported widget types do not crash
-- =========================================================================
-- @description Each recognised widget_type string can be loaded individually
-- without a Lua error.
describe("lurek.ui.loadLayout — widget type coverage", function()
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
        -- @description Widget type '<wtype>' loads without error
        it("type '" .. wtype .. "' loads without error", function()
            local ok = pcall(function()
                lurek.ui.loadLayout({ type = wtype })
            end)
            assert(ok, "loadLayout({type='" .. wtype .. "'}) must not throw")
        end)
    end
end)

test_summary()
