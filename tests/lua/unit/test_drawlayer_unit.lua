-- tests/lua/unit/test_drawlayer.lua
-- Lurek2D BDD tests for lurek.render.newDrawLayer()  - z-ordered draw-call queue.
-- Headless-safe (no GPU/window needed).

describe("DrawLayer creation", function()
    it("creates a DrawLayer via lurek.render.newDrawLayer()", function()
        local layer = lurek.render.newDrawLayer()
        expect_type("userdata", layer)
    end)

    it("starts with count 0", function()
        local layer = lurek.render.newDrawLayer()
        expect_equal(0, layer:getCount())
    end)
end)

-- -------------------------------------------------------------------
describe("DrawLayer queue", function()
    it("queuing increases count", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(1.0, function() end)
        expect_equal(1, layer:getCount())
        layer:queue(2.0, function() end)
        expect_equal(2, layer:getCount())
    end)

    it("queue accepts negative z-order", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(-5.0, function() end)
        expect_equal(1, layer:getCount())
    end)

    it("queue accepts zero z-order", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(0, function() end)
        expect_equal(1, layer:getCount())
    end)
end)

-- -------------------------------------------------------------------
describe("DrawLayer flush", function()
    it("flush calls callbacks in z-order (ascending)", function()
        local layer = lurek.render.newDrawLayer()
        local order = {}
        layer:queue(3.0, function() table.insert(order, "C") end)
        layer:queue(1.0, function() table.insert(order, "A") end)
        layer:queue(2.0, function() table.insert(order, "B") end)
        layer:flush()
        expect_equal(3, #order)
        expect_equal("A", order[1])
        expect_equal("B", order[2])
        expect_equal("C", order[3])
    end)

    it("flush empties the queue", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(1.0, function() end)
        layer:queue(2.0, function() end)
        expect_equal(2, layer:getCount())
        layer:flush()
        expect_equal(0, layer:getCount())
    end)

    it("flush on empty layer is a no-op", function()
        local layer = lurek.render.newDrawLayer()
        layer:flush() -- should not error
        expect_equal(0, layer:getCount())
    end)

    it("flush handles negative z-orders correctly", function()
        local layer = lurek.render.newDrawLayer()
        local order = {}
        layer:queue(0.0, function() table.insert(order, "zero") end)
        layer:queue(-1.0, function() table.insert(order, "neg") end)
        layer:queue(1.0, function() table.insert(order, "pos") end)
        layer:flush()
        expect_equal("neg", order[1])
        expect_equal("zero", order[2])
        expect_equal("pos", order[3])
    end)

    it("flush handles equal z-orders (stable-ish)", function()
        local layer = lurek.render.newDrawLayer()
        local count = 0
        layer:queue(1.0, function() count = count + 1 end)
        layer:queue(1.0, function() count = count + 1 end)
        layer:queue(1.0, function() count = count + 1 end)
        layer:flush()
        expect_equal(3, count)
    end)
end)

-- -------------------------------------------------------------------
describe("DrawLayer clear", function()
    it("clear removes all queued entries", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(1.0, function() end)
        layer:queue(2.0, function() end)
        layer:queue(3.0, function() end)
        expect_equal(3, layer:getCount())
        layer:clear()
        expect_equal(0, layer:getCount())
    end)

    it("clear on empty layer is safe", function()
        local layer = lurek.render.newDrawLayer()
        layer:clear()
        expect_equal(0, layer:getCount())
    end)

    it("cleared callbacks are not called on flush", function()
        local layer = lurek.render.newDrawLayer()
        local called = false
        layer:queue(1.0, function() called = true end)
        layer:clear()
        layer:flush()
        expect_equal(false, called)
    end)
end)

-- -------------------------------------------------------------------
describe("DrawLayer reuse", function()
    it("layer can be reused after flush", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(1.0, function() end)
        layer:flush()
        expect_equal(0, layer:getCount())
        layer:queue(5.0, function() end)
        expect_equal(1, layer:getCount())
    end)

    it("layer can be reused after clear", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(1.0, function() end)
        layer:clear()
        layer:queue(5.0, function() end)
        expect_equal(1, layer:getCount())
    end)

    it("multiple flush cycles work correctly", function()
        local layer = lurek.render.newDrawLayer()
        local results = {}

        layer:queue(2.0, function() table.insert(results, "B1") end)
        layer:queue(1.0, function() table.insert(results, "A1") end)
        layer:flush()
        expect_equal("A1", results[1])
        expect_equal("B1", results[2])

        layer:queue(4.0, function() table.insert(results, "D2") end)
        layer:queue(3.0, function() table.insert(results, "C2") end)
        layer:flush()
        expect_equal("C2", results[3])
        expect_equal("D2", results[4])
    end)
end)

-- -------------------------------------------------------------------
describe("DrawLayer type system", function()
    it("has type() method returning LDrawLayer", function()
        local layer = lurek.render.newDrawLayer()
        expect_equal("LDrawLayer", layer:type())
    end)

    it("typeOf Object returns true", function()
        local layer = lurek.render.newDrawLayer()
        expect_equal(true, layer:typeOf("Object"))
    end)

    it("typeOf DrawLayer returns true", function()
        local layer = lurek.render.newDrawLayer()
        expect_equal(true, layer:typeOf("DrawLayer"))
    end)

    it("typeOf wrong type returns false", function()
        local layer = lurek.render.newDrawLayer()
        expect_equal(false, layer:typeOf("Image"))
    end)
end)

-- -------------------------------------------------------------------
describe("DrawLayer large queue", function()
    it("handles many entries", function()
        local layer = lurek.render.newDrawLayer()
        local sum = 0
        for i = 100, 1, -1 do
            layer:queue(i, function() sum = sum + 1 end)
        end
        expect_equal(100, layer:getCount())
        layer:flush()
        expect_equal(100, sum)
        expect_equal(0, layer:getCount())
    end)
end)
test_summary()
