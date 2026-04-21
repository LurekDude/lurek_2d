-- tests/lua/test_drawlayer.lua
-- Integration tests for lurek.render.newDrawLayer()
-- @covers lurek.render.newDrawLayer

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
-- @description Covers suite: DrawLayer creation.
describe("DrawLayer creation", function()
    -- @covers lurek.render.newDrawLayer
    -- @covers lurek.render.DrawLayer
    -- @description Verifies the graphics API can construct a DrawLayer object; despite the folder placement this is a single-module graphics test.
    it("creates a DrawLayer via lurek.render.newDrawLayer()", function()
        local layer = lurek.render.newDrawLayer()
        expect_type(layer, "userdata")
    end)

    -- @covers lurek.render.newDrawLayer
    -- @covers lurek.render.DrawLayer.getCount
    -- @description Verifies a newly created draw layer starts with no queued callbacks.
    it("starts with count 0", function()
        local layer = lurek.render.newDrawLayer()
        expect_eq(layer:getCount(), 0)
    end)
end)

-- -------------------------------------------------------------------
-- @description Covers suite: DrawLayer queue.
describe("DrawLayer queue", function()
    -- @covers lurek.render.DrawLayer.queue
    -- @covers lurek.render.DrawLayer.getCount
    -- @description Verifies queueing draw callbacks increments the tracked draw layer count.
    it("queuing increases count", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(1.0, function() end)
        expect_eq(layer:getCount(), 1)
        layer:queue(2.0, function() end)
        expect_eq(layer:getCount(), 2)
    end)

    -- @covers lurek.render.DrawLayer.queue
    -- @covers lurek.render.DrawLayer.getCount
    -- @description Verifies draw layers accept negative z-order values.
    it("queue accepts negative z-order", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(-5.0, function() end)
        expect_eq(layer:getCount(), 1)
    end)

    -- @covers lurek.render.DrawLayer.queue
    -- @covers lurek.render.DrawLayer.getCount
    -- @description Verifies draw layers accept zero as a valid z-order.
    it("queue accepts zero z-order", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(0, function() end)
        expect_eq(layer:getCount(), 1)
    end)
end)

-- -------------------------------------------------------------------
-- @description Covers suite: DrawLayer flush.
describe("DrawLayer flush", function()
    -- @covers lurek.render.DrawLayer.flush
    -- @covers lurek.render.DrawLayer.queue
    -- @description Verifies flushing executes queued callbacks in ascending z-order.
    it("flush calls callbacks in z-order (ascending)", function()
        local layer = lurek.render.newDrawLayer()
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

    -- @covers lurek.render.DrawLayer.flush
    -- @covers lurek.render.DrawLayer.getCount
    -- @description Verifies flushing empties the draw layer queue.
    it("flush empties the queue", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(1.0, function() end)
        layer:queue(2.0, function() end)
        expect_eq(layer:getCount(), 2)
        layer:flush()
        expect_eq(layer:getCount(), 0)
    end)

    -- @covers lurek.render.DrawLayer.flush
    -- @covers lurek.render.DrawLayer.getCount
    -- @description Verifies flushing an empty draw layer is a safe no-op.
    it("flush on empty layer is a no-op", function()
        local layer = lurek.render.newDrawLayer()
        layer:flush() -- should not error
        expect_eq(layer:getCount(), 0)
    end)

    -- @covers lurek.render.DrawLayer.flush
    -- @covers lurek.render.DrawLayer.queue
    -- @description Verifies flush sorting handles negative, zero, and positive z-orders correctly.
    it("flush handles negative z-orders correctly", function()
        local layer = lurek.render.newDrawLayer()
        local order = {}
        layer:queue(0.0, function() table.insert(order, "zero") end)
        layer:queue(-1.0, function() table.insert(order, "neg") end)
        layer:queue(1.0, function() table.insert(order, "pos") end)
        layer:flush()
        expect_eq(order[1], "neg")
        expect_eq(order[2], "zero")
        expect_eq(order[3], "pos")
    end)

    -- @covers lurek.render.DrawLayer.flush
    -- @covers lurek.render.DrawLayer.queue
    -- @description Verifies flushing handles multiple callbacks queued at the same z-order.
    it("flush handles equal z-orders (stable-ish)", function()
        local layer = lurek.render.newDrawLayer()
        local count = 0
        layer:queue(1.0, function() count = count + 1 end)
        layer:queue(1.0, function() count = count + 1 end)
        layer:queue(1.0, function() count = count + 1 end)
        layer:flush()
        expect_eq(count, 3)
    end)
end)

-- -------------------------------------------------------------------
-- @description Covers suite: DrawLayer clear.
describe("DrawLayer clear", function()
    -- @covers lurek.render.DrawLayer.clear
    -- @covers lurek.render.DrawLayer.getCount
    -- @description Verifies clearing a draw layer removes all queued callbacks.
    it("clear removes all queued entries", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(1.0, function() end)
        layer:queue(2.0, function() end)
        layer:queue(3.0, function() end)
        expect_eq(layer:getCount(), 3)
        layer:clear()
        expect_eq(layer:getCount(), 0)
    end)

    -- @covers lurek.render.DrawLayer.clear
    -- @covers lurek.render.DrawLayer.getCount
    -- @description Verifies clearing an already empty draw layer is safe.
    it("clear on empty layer is safe", function()
        local layer = lurek.render.newDrawLayer()
        layer:clear()
        expect_eq(layer:getCount(), 0)
    end)

    -- @covers lurek.render.DrawLayer.clear
    -- @covers lurek.render.DrawLayer.flush
    -- @description Verifies callbacks removed by clear are not executed by a later flush.
    it("cleared callbacks are not called on flush", function()
        local layer = lurek.render.newDrawLayer()
        local called = false
        layer:queue(1.0, function() called = true end)
        layer:clear()
        layer:flush()
        expect_eq(called, false)
    end)
end)

-- -------------------------------------------------------------------
-- @description Covers suite: DrawLayer reuse.
describe("DrawLayer reuse", function()
    -- @covers lurek.render.DrawLayer.flush
    -- @covers lurek.render.DrawLayer.queue
    -- @description Verifies a draw layer can be reused by queueing new work after a flush.
    it("layer can be reused after flush", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(1.0, function() end)
        layer:flush()
        expect_eq(layer:getCount(), 0)
        layer:queue(5.0, function() end)
        expect_eq(layer:getCount(), 1)
    end)

    -- @covers lurek.render.DrawLayer.clear
    -- @covers lurek.render.DrawLayer.queue
    -- @description Verifies a draw layer can be reused after clearing prior queued work.
    it("layer can be reused after clear", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(1.0, function() end)
        layer:clear()
        layer:queue(5.0, function() end)
        expect_eq(layer:getCount(), 1)
    end)

    -- @covers lurek.render.DrawLayer.flush
    -- @covers lurek.render.DrawLayer.queue
    -- @description Verifies repeated flush cycles continue to execute callbacks in the expected order.
    it("multiple flush cycles work correctly", function()
        local layer = lurek.render.newDrawLayer()
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
-- @description Covers suite: DrawLayer type system.
describe("DrawLayer type system", function()
    -- @covers lurek.render.DrawLayer.type
    -- @covers lurek.render.newDrawLayer
    -- @description Verifies DrawLayer objects report their concrete type string.
    it("has type() method returning DrawLayer", function()
        local layer = lurek.render.newDrawLayer()
        expect_eq(layer:type(), "DrawLayer")
    end)

    -- @covers lurek.render.DrawLayer.typeOf
    -- @covers lurek.render.newDrawLayer
    -- @description Verifies DrawLayer objects identify as the base Object type.
    it("typeOf Object returns true", function()
        local layer = lurek.render.newDrawLayer()
        expect_eq(layer:typeOf("Object"), true)
    end)

    -- @covers lurek.render.DrawLayer.typeOf
    -- @covers lurek.render.newDrawLayer
    -- @description Verifies DrawLayer objects identify as DrawLayer through typeOf.
    it("typeOf DrawLayer returns true", function()
        local layer = lurek.render.newDrawLayer()
        expect_eq(layer:typeOf("DrawLayer"), true)
    end)

    -- @covers lurek.render.DrawLayer.typeOf
    -- @covers lurek.render.newDrawLayer
    -- @description Verifies DrawLayer objects reject unrelated type queries.
    it("typeOf wrong type returns false", function()
        local layer = lurek.render.newDrawLayer()
        expect_eq(layer:typeOf("Image"), false)
    end)
end)

-- -------------------------------------------------------------------
-- @description Covers suite: DrawLayer large queue.
describe("DrawLayer large queue", function()
    -- @covers lurek.render.DrawLayer.queue
    -- @covers lurek.render.DrawLayer.flush
    -- @description Verifies draw layers can process a larger queued batch and still flush every callback.
    it("handles many entries", function()
        local layer = lurek.render.newDrawLayer()
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
test_summary()
