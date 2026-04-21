-- tests/lua/unit/test_drawlayer.lua
-- Lurek2D BDD tests for lurek.render.newDrawLayer() â€” z-ordered draw-call queue.
-- Headless-safe (no GPU/window needed).

-- @description Covers suite: DrawLayer creation.
describe("DrawLayer creation", function()
    -- @tests lurek.render.newDrawLayer
    -- @description Verifies the draw-layer constructor returns userdata.
    it("creates a DrawLayer via lurek.render.newDrawLayer()", function()
        local layer = lurek.render.newDrawLayer()
        expect_type("userdata", layer)
    end)

    -- @tests DrawLayer.getCount
    -- @description Verifies new draw layers start with an empty queue.
    it("starts with count 0", function()
        local layer = lurek.render.newDrawLayer()
        expect_equal(0, layer:getCount())
    end)
end)

-- -------------------------------------------------------------------
-- @description Covers suite: DrawLayer queue.
describe("DrawLayer queue", function()
    -- @tests DrawLayer.queue
    -- @tests DrawLayer.getCount
    -- @description Verifies queueing callbacks increments the pending draw-call count.
    it("queuing increases count", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(1.0, function() end)
        expect_equal(1, layer:getCount())
        layer:queue(2.0, function() end)
        expect_equal(2, layer:getCount())
    end)

    -- @tests DrawLayer.queue
    -- @tests DrawLayer.getCount
    -- @description Verifies negative depth values are accepted for back-to-front ordering.
    it("queue accepts negative z-order", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(-5.0, function() end)
        expect_equal(1, layer:getCount())
    end)

    -- @tests DrawLayer.queue
    -- @tests DrawLayer.getCount
    -- @description Verifies zero depth is treated as a valid queue key.
    it("queue accepts zero z-order", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(0, function() end)
        expect_equal(1, layer:getCount())
    end)
end)

-- -------------------------------------------------------------------
-- @description Covers suite: DrawLayer flush.
describe("DrawLayer flush", function()
    -- @tests DrawLayer.queue
    -- @tests DrawLayer.flush
    -- @description Verifies flush executes queued callbacks in ascending z-order.
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

    -- @tests DrawLayer.flush
    -- @tests DrawLayer.getCount
    -- @description Verifies flush drains the queue after running callbacks.
    it("flush empties the queue", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(1.0, function() end)
        layer:queue(2.0, function() end)
        expect_equal(2, layer:getCount())
        layer:flush()
        expect_equal(0, layer:getCount())
    end)

    -- @tests DrawLayer.flush
    -- @tests DrawLayer.getCount
    -- @description Verifies flushing an empty layer is a safe no-op.
    it("flush on empty layer is a no-op", function()
        local layer = lurek.render.newDrawLayer()
        layer:flush() -- should not error
        expect_equal(0, layer:getCount())
    end)

    -- @tests DrawLayer.queue
    -- @tests DrawLayer.flush
    -- @description Verifies sort order handles negative, zero, and positive z-values consistently.
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

    -- @tests DrawLayer.queue
    -- @tests DrawLayer.flush
    -- @description Verifies equal z-values still execute every callback exactly once.
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
-- @description Covers suite: DrawLayer clear.
describe("DrawLayer clear", function()
    -- @tests DrawLayer.clear
    -- @tests DrawLayer.getCount
    -- @description Verifies clear drops all queued callbacks immediately.
    it("clear removes all queued entries", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(1.0, function() end)
        layer:queue(2.0, function() end)
        layer:queue(3.0, function() end)
        expect_equal(3, layer:getCount())
        layer:clear()
        expect_equal(0, layer:getCount())
    end)

    -- @tests DrawLayer.clear
    -- @tests DrawLayer.getCount
    -- @description Verifies clear is safe on an already empty layer.
    it("clear on empty layer is safe", function()
        local layer = lurek.render.newDrawLayer()
        layer:clear()
        expect_equal(0, layer:getCount())
    end)

    -- @tests DrawLayer.clear
    -- @tests DrawLayer.flush
    -- @description Verifies callbacks removed by clear are not later executed by flush.
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
-- @description Covers suite: DrawLayer reuse.
describe("DrawLayer reuse", function()
    -- @tests DrawLayer.queue
    -- @tests DrawLayer.flush
    -- @tests DrawLayer.getCount
    -- @description Verifies a layer can accept new work after a flush cycle completes.
    it("layer can be reused after flush", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(1.0, function() end)
        layer:flush()
        expect_equal(0, layer:getCount())
        layer:queue(5.0, function() end)
        expect_equal(1, layer:getCount())
    end)

    -- @tests DrawLayer.queue
    -- @tests DrawLayer.clear
    -- @tests DrawLayer.getCount
    -- @description Verifies a layer can be reused after being cleared.
    it("layer can be reused after clear", function()
        local layer = lurek.render.newDrawLayer()
        layer:queue(1.0, function() end)
        layer:clear()
        layer:queue(5.0, function() end)
        expect_equal(1, layer:getCount())
    end)

    -- @tests DrawLayer.queue
    -- @tests DrawLayer.flush
    -- @description Verifies multiple flush cycles preserve correct ordering across reused queue state.
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
-- @description Covers suite: DrawLayer type system.
describe("DrawLayer type system", function()
    -- @tests DrawLayer.type
    -- @description Verifies DrawLayer userdata reports its concrete type string.
    it("has type() method returning DrawLayer", function()
        local layer = lurek.render.newDrawLayer()
        expect_equal("DrawLayer", layer:type())
    end)

    -- @tests DrawLayer.typeOf
    -- @description Verifies DrawLayer advertises Object ancestry through typeOf.
    it("typeOf Object returns true", function()
        local layer = lurek.render.newDrawLayer()
        expect_equal(true, layer:typeOf("Object"))
    end)

    -- @tests DrawLayer.typeOf
    -- @description Verifies DrawLayer recognizes its own runtime type name.
    it("typeOf DrawLayer returns true", function()
        local layer = lurek.render.newDrawLayer()
        expect_equal(true, layer:typeOf("DrawLayer"))
    end)

    -- @tests DrawLayer.typeOf
    -- @description Verifies typeOf rejects unrelated type names.
    it("typeOf wrong type returns false", function()
        local layer = lurek.render.newDrawLayer()
        expect_equal(false, layer:typeOf("Image"))
    end)
end)

-- -------------------------------------------------------------------
-- @description Covers suite: DrawLayer large queue.
describe("DrawLayer large queue", function()
    -- @tests DrawLayer.queue
    -- @tests DrawLayer.flush
    -- @tests DrawLayer.getCount
    -- @description Verifies the queue handles a large batch and executes every callback exactly once.
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
