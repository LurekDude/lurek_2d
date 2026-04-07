-- tests/lua/test_drawlayer.lua
-- Integration tests for luna.gfx.newDrawLayer()

local total, passed, failed = 0, 0, 0
local current_describe = ""

local function describe(name, fn)
    current_describe = name
    fn()
end

local function it(name, fn)
    total = total + 1
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
    else
        failed = failed + 1
        print("FAIL: " .. current_describe .. " > " .. name .. ": " .. tostring(err))
    end
end

local function expect_eq(a, b)
    assert(a == b, "expected " .. tostring(b) .. " got " .. tostring(a))
end

local function expect_type(v, t)
    assert(type(v) == t, "expected type " .. t .. " got " .. type(v))
end

-- -------------------------------------------------------------------
describe("DrawLayer creation", function()
    it("creates a DrawLayer via luna.gfx.newDrawLayer()", function()
        local layer = luna.gfx.newDrawLayer()
        expect_type(layer, "userdata")
    end)

    it("starts with count 0", function()
        local layer = luna.gfx.newDrawLayer()
        expect_eq(layer:getCount(), 0)
    end)
end)

-- -------------------------------------------------------------------
describe("DrawLayer queue", function()
    it("queuing increases count", function()
        local layer = luna.gfx.newDrawLayer()
        layer:queue(1.0, function() end)
        expect_eq(layer:getCount(), 1)
        layer:queue(2.0, function() end)
        expect_eq(layer:getCount(), 2)
    end)

    it("queue accepts negative z-order", function()
        local layer = luna.gfx.newDrawLayer()
        layer:queue(-5.0, function() end)
        expect_eq(layer:getCount(), 1)
    end)

    it("queue accepts zero z-order", function()
        local layer = luna.gfx.newDrawLayer()
        layer:queue(0, function() end)
        expect_eq(layer:getCount(), 1)
    end)
end)

-- -------------------------------------------------------------------
describe("DrawLayer flush", function()
    it("flush calls callbacks in z-order (ascending)", function()
        local layer = luna.gfx.newDrawLayer()
        local order = {}
        layer:queue(3.0, function() table.insert(order, "C") end)
        layer:queue(1.0, function() table.insert(order, "A") end)
        layer:queue(2.0, function() table.insert(order, "B") end)
        layer:flush()
        expect_eq(#order, 3)
        expect_eq(order[1], "A")
        expect_eq(order[2], "B")
        expect_eq(order[3], "C")
    end)

    it("flush empties the queue", function()
        local layer = luna.gfx.newDrawLayer()
        layer:queue(1.0, function() end)
        layer:queue(2.0, function() end)
        expect_eq(layer:getCount(), 2)
        layer:flush()
        expect_eq(layer:getCount(), 0)
    end)

    it("flush on empty layer is a no-op", function()
        local layer = luna.gfx.newDrawLayer()
        layer:flush() -- should not error
        expect_eq(layer:getCount(), 0)
    end)

    it("flush handles negative z-orders correctly", function()
        local layer = luna.gfx.newDrawLayer()
        local order = {}
        layer:queue(0.0, function() table.insert(order, "zero") end)
        layer:queue(-1.0, function() table.insert(order, "neg") end)
        layer:queue(1.0, function() table.insert(order, "pos") end)
        layer:flush()
        expect_eq(order[1], "neg")
        expect_eq(order[2], "zero")
        expect_eq(order[3], "pos")
    end)

    it("flush handles equal z-orders (stable-ish)", function()
        local layer = luna.gfx.newDrawLayer()
        local count = 0
        layer:queue(1.0, function() count = count + 1 end)
        layer:queue(1.0, function() count = count + 1 end)
        layer:queue(1.0, function() count = count + 1 end)
        layer:flush()
        expect_eq(count, 3)
    end)
end)

-- -------------------------------------------------------------------
describe("DrawLayer clear", function()
    it("clear removes all queued entries", function()
        local layer = luna.gfx.newDrawLayer()
        layer:queue(1.0, function() end)
        layer:queue(2.0, function() end)
        layer:queue(3.0, function() end)
        expect_eq(layer:getCount(), 3)
        layer:clear()
        expect_eq(layer:getCount(), 0)
    end)

    it("clear on empty layer is safe", function()
        local layer = luna.gfx.newDrawLayer()
        layer:clear()
        expect_eq(layer:getCount(), 0)
    end)

    it("cleared callbacks are not called on flush", function()
        local layer = luna.gfx.newDrawLayer()
        local called = false
        layer:queue(1.0, function() called = true end)
        layer:clear()
        layer:flush()
        expect_eq(called, false)
    end)
end)

-- -------------------------------------------------------------------
describe("DrawLayer reuse", function()
    it("layer can be reused after flush", function()
        local layer = luna.gfx.newDrawLayer()
        layer:queue(1.0, function() end)
        layer:flush()
        expect_eq(layer:getCount(), 0)
        layer:queue(5.0, function() end)
        expect_eq(layer:getCount(), 1)
    end)

    it("layer can be reused after clear", function()
        local layer = luna.gfx.newDrawLayer()
        layer:queue(1.0, function() end)
        layer:clear()
        layer:queue(5.0, function() end)
        expect_eq(layer:getCount(), 1)
    end)

    it("multiple flush cycles work correctly", function()
        local layer = luna.gfx.newDrawLayer()
        local results = {}

        layer:queue(2.0, function() table.insert(results, "B1") end)
        layer:queue(1.0, function() table.insert(results, "A1") end)
        layer:flush()
        expect_eq(results[1], "A1")
        expect_eq(results[2], "B1")

        layer:queue(4.0, function() table.insert(results, "D2") end)
        layer:queue(3.0, function() table.insert(results, "C2") end)
        layer:flush()
        expect_eq(results[3], "C2")
        expect_eq(results[4], "D2")
    end)
end)

-- -------------------------------------------------------------------
describe("DrawLayer type system", function()
    it("has type() method returning DrawLayer", function()
        local layer = luna.gfx.newDrawLayer()
        expect_eq(layer:type(), "DrawLayer")
    end)

    it("typeOf Object returns true", function()
        local layer = luna.gfx.newDrawLayer()
        expect_eq(layer:typeOf("Object"), true)
    end)

    it("typeOf DrawLayer returns true", function()
        local layer = luna.gfx.newDrawLayer()
        expect_eq(layer:typeOf("DrawLayer"), true)
    end)

    it("typeOf wrong type returns false", function()
        local layer = luna.gfx.newDrawLayer()
        expect_eq(layer:typeOf("Image"), false)
    end)
end)

-- -------------------------------------------------------------------
describe("DrawLayer large queue", function()
    it("handles many entries", function()
        local layer = luna.gfx.newDrawLayer()
        local sum = 0
        for i = 100, 1, -1 do
            layer:queue(i, function() sum = sum + 1 end)
        end
        expect_eq(layer:getCount(), 100)
        layer:flush()
        expect_eq(sum, 100)
        expect_eq(layer:getCount(), 0)
    end)
end)

print(string.format("DrawLayer tests: %d/%d passed, %d failed", passed, total, failed))
_test_results = { total = total, passed = passed, failed = failed }
