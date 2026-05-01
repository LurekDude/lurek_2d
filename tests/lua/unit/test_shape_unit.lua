-- tests/lua/unit/test_shape.lua
-- Lurek2D BDD tests for lurek.render.newShape()  - CompoundShape builder
-- @covers lurek.render.newShape

local function run_tests()

-- Constructor

    describe("newShape constructor", function()
        -- @covers lurek.render.newShape
        it("returns a non-nil userdata", function()
            local shape = lurek.render.newShape()
            expect_not_nil(shape)
        end)

        -- @covers lurek.render.newShape
        it("starts with zero commands", function()
            local shape = lurek.render.newShape()
            expect_equal(0, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("can create multiple independent shapes", function()
            local s1 = lurek.render.newShape()
            local s2 = lurek.render.newShape()
            s1:circle("fill", 0, 0, 30)
            expect_equal(1, s1:getCommandCount())
            expect_equal(0, s2:getCommandCount())
        end)
    end)

-- Primitive builder methods

    describe("primitive builder methods", function()
        -- @covers lurek.render.newShape
        it("rectangle adds one command", function()
            local shape = lurek.render.newShape()
            shape:rectangle("fill", 0, 0, 100, 50)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("rectangle line mode adds one command", function()
            local shape = lurek.render.newShape()
            shape:rectangle("line", 10, 10, 80, 40)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("roundedRectangle adds one command", function()
            local shape = lurek.render.newShape()
            shape:roundedRectangle("fill", 0, 0, 100, 50, 10)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("roundedRectangle with explicit ry adds one command", function()
            local shape = lurek.render.newShape()
            shape:roundedRectangle("line", 0, 0, 100, 50, 12, 8)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("circle adds one command", function()
            local shape = lurek.render.newShape()
            shape:circle("fill", 0, 0, 30)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("ellipse adds one command", function()
            local shape = lurek.render.newShape()
            shape:ellipse("fill", 0, 0, 40, 25)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("triangle adds one command", function()
            local shape = lurek.render.newShape()
            shape:triangle("fill", 0, 0, 50, 0, 25, 50)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("polygon adds one command", function()
            local shape = lurek.render.newShape()
            shape:polygon("fill", 0, 0, 50, 0, 50, 50)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("line adds one command", function()
            local shape = lurek.render.newShape()
            shape:line(0, 0, 100, 100)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("polyline adds one command", function()
            local shape = lurek.render.newShape()
            shape:polyline(0, 0, 100, 100, 200, 0)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("arc adds one command", function()
            local shape = lurek.render.newShape()
            shape:arc("fill", 0, 0, 50, 0, math.pi)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("arc with explicit segments adds one command", function()
            local shape = lurek.render.newShape()
            shape:arc("line", 0, 0, 50, 0, math.pi, 64)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("multiple primitives accumulate", function()
            local shape = lurek.render.newShape()
            shape:rectangle("fill", 0, 0, 100, 50)
            shape:circle("line", 50, 50, 20)
            shape:line(0, 0, 100, 100)
            expect_equal(3, shape:getCommandCount())
        end)
    end)

-- State builder methods

    describe("state builder methods", function()
        -- @covers lurek.render.newShape
        it("setColor adds a command", function()
            local shape = lurek.render.newShape()
            shape:setColor(1, 0, 0)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("setColor with alpha adds a command", function()
            local shape = lurek.render.newShape()
            shape:setColor(0, 1, 0, 0.5)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("setLineWidth adds a command", function()
            local shape = lurek.render.newShape()
            shape:setLineWidth(3.0)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("setColor before primitive affects count", function()
            local shape = lurek.render.newShape()
            shape:setColor(1, 0, 0)
            shape:rectangle("fill", 0, 0, 100, 50)
            expect_equal(2, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("multiple setColor calls all add commands", function()
            local shape = lurek.render.newShape()
            shape:setColor(1, 0, 0)
            shape:setColor(0, 1, 0)
            shape:setColor(0, 0, 1)
            expect_equal(3, shape:getCommandCount())
        end)
    end)

-- polygon validation

    describe("polygon validation", function()
        -- @covers lurek.render.newShape
        it("polygon with 3 vertices succeeds", function()
            local shape = lurek.render.newShape()
            shape:polygon("fill", 0, 0, 50, 0, 25, 50)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("polygon with more than 3 vertices succeeds", function()
            local shape = lurek.render.newShape()
            shape:polygon("fill", 0, 0,  100, 0,  100, 100,  0, 100)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("polygon with fewer than 3 vertices raises error", function()
            local shape = lurek.render.newShape()
            expect_error(function()
                shape:polygon("fill", 0, 0, 50, 0)  -- only 2 vertices (4 numbers)
            end)
        end)

        -- @covers lurek.render.newShape
        it("polygon error does not increment command count", function()
            local shape = lurek.render.newShape()
            pcall(function() shape:polygon("fill", 0, 0, 50, 0) end)
            expect_equal(0, shape:getCommandCount())
        end)
    end)

-- polyline validation

    describe("polyline validation", function()
        -- @covers lurek.render.newShape
        it("polyline with 2 points succeeds", function()
            local shape = lurek.render.newShape()
            shape:polyline(0, 0, 100, 100)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("polyline with 3 points succeeds", function()
            local shape = lurek.render.newShape()
            shape:polyline(0, 0, 100, 100, 200, 0)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("polyline with fewer than 2 points raises error", function()
            local shape = lurek.render.newShape()
            expect_error(function()
                shape:polyline(0, 0)  -- only 1 point (2 numbers)
            end)
        end)

        -- @covers lurek.render.newShape
        it("polyline error does not increment command count", function()
            local shape = lurek.render.newShape()
            pcall(function() shape:polyline(0, 0) end)
            expect_equal(0, shape:getCommandCount())
        end)
    end)

-- draw dispatch

    describe("draw dispatch", function()
        -- @covers lurek.render.newShape
        it("draw on empty shape does not error", function()
            local shape = lurek.render.newShape()
            expect_no_error(function()
                shape:draw(100, 200)
            end)
        end)

        -- @covers lurek.render.newShape
        it("draw with all transform args does not error", function()
            local shape = lurek.render.newShape()
            expect_no_error(function()
                shape:draw(0, 0, 0.5, 2.0, 2.0, 10, 10)
            end)
        end)

        -- @covers lurek.render.newShape
        it("draw with minimal args does not error", function()
            local shape = lurek.render.newShape()
            expect_no_error(function()
                shape:draw(0, 0)
            end)
        end)

        -- @covers lurek.render.newShape
        it("draw on populated shape does not error", function()
            local shape = lurek.render.newShape()
            shape:circle("fill", 0, 0, 30)
            expect_no_error(function()
                shape:draw(100, 100)
            end)
        end)

        -- @covers lurek.render.newShape
        it("draw does not change command count", function()
            local shape = lurek.render.newShape()
            shape:circle("fill", 0, 0, 30)
            shape:draw(100, 100)
            -- draw pushes to the draw queue, not to the shape command list
            expect_equal(1, shape:getCommandCount())
        end)
    end)

-- clear

    describe("clear", function()
        -- @covers lurek.render.newShape
        it("clear resets command count to 0", function()
            local shape = lurek.render.newShape()
            shape:rectangle("fill", 0, 0, 100, 50)
            shape:circle("line", 50, 50, 20)
            shape:line(0, 0, 100, 100)
            shape:clear()
            expect_equal(0, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("builder calls after clear succeed", function()
            local shape = lurek.render.newShape()
            shape:circle("fill", 0, 0, 30)
            shape:clear()
            shape:rectangle("fill", 0, 0, 100, 50)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("draw after clear does not error", function()
            local shape = lurek.render.newShape()
            shape:circle("fill", 0, 0, 30)
            shape:clear()
            expect_no_error(function()
                shape:draw(0, 0)
            end)
        end)

        -- @covers lurek.render.newShape
        it("clear on already-empty shape does not error", function()
            local shape = lurek.render.newShape()
            expect_no_error(function()
                shape:clear()
            end)
            expect_equal(0, shape:getCommandCount())
        end)
    end)

-- method sequencing

    describe("method chaining", function()
        -- @covers lurek.render.newShape
        it("builder methods can be called in sequence without errors", function()
            local shape = lurek.render.newShape()
            expect_no_error(function()
                shape:setColor(1, 0, 0)
                shape:rectangle("fill", 0, 0, 100, 50)
                shape:setColor(0, 1, 0)
                shape:circle("line", 50, 50, 25)
            end)
            expect_equal(4, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("getCommandCount returns a number type", function()
            local shape = lurek.render.newShape()
            shape:circle("fill", 0, 0, 10)
            expect_type("number", shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        it("interleaving state and primitives accumulates all commands", function()
            local shape = lurek.render.newShape()
            shape:setColor(1, 0, 0)
            shape:setLineWidth(2)
            shape:rectangle("fill", 0, 0, 80, 40)
            shape:setColor(0, 0, 1)
            shape:circle("line", 50, 50, 20)
            expect_equal(5, shape:getCommandCount())
        end)
    end)

end

run_tests()

test_summary()
