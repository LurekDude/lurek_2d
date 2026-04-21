-- tests/lua/unit/test_shape.lua
-- Lurek2D BDD tests for lurek.render.newShape() â€” CompoundShape builder
-- @covers lurek.render.newShape

local function run_tests()

    -- â”€â”€ Constructor â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    -- @description Covers suite: newShape constructor.
    describe("newShape constructor", function()
        -- @covers lurek.render.newShape
        -- @description Verifies newShape returns a non-nil userdata handle.
        it("returns a non-nil userdata", function()
            local shape = lurek.render.newShape()
            expect_not_nil(shape)
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies fresh shapes start with zero queued commands.
        it("starts with zero commands", function()
            local shape = lurek.render.newShape()
            expect_equal(0, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies separate shape instances keep independent command buffers.
        it("can create multiple independent shapes", function()
            local s1 = lurek.render.newShape()
            local s2 = lurek.render.newShape()
            s1:circle("fill", 0, 0, 30)
            expect_equal(1, s1:getCommandCount())
            expect_equal(0, s2:getCommandCount())
        end)
    end)

    -- â”€â”€ Primitive builder methods â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    -- @description Covers suite: primitive builder methods.
    describe("primitive builder methods", function()
        -- @covers lurek.render.newShape
        -- @description Verifies rectangle appends one draw command.
        it("rectangle adds one command", function()
            local shape = lurek.render.newShape()
            shape:rectangle("fill", 0, 0, 100, 50)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies line-mode rectangle also appends one draw command.
        it("rectangle line mode adds one command", function()
            local shape = lurek.render.newShape()
            shape:rectangle("line", 10, 10, 80, 40)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies roundedRectangle appends one draw command.
        it("roundedRectangle adds one command", function()
            local shape = lurek.render.newShape()
            shape:roundedRectangle("fill", 0, 0, 100, 50, 10)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies roundedRectangle accepts explicit x and y radii.
        it("roundedRectangle with explicit ry adds one command", function()
            local shape = lurek.render.newShape()
            shape:roundedRectangle("line", 0, 0, 100, 50, 12, 8)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies circle appends one draw command.
        it("circle adds one command", function()
            local shape = lurek.render.newShape()
            shape:circle("fill", 0, 0, 30)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies ellipse appends one draw command.
        it("ellipse adds one command", function()
            local shape = lurek.render.newShape()
            shape:ellipse("fill", 0, 0, 40, 25)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies triangle appends one draw command.
        it("triangle adds one command", function()
            local shape = lurek.render.newShape()
            shape:triangle("fill", 0, 0, 50, 0, 25, 50)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies polygon appends one draw command with valid vertices.
        it("polygon adds one command", function()
            local shape = lurek.render.newShape()
            shape:polygon("fill", 0, 0, 50, 0, 50, 50)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies line appends one draw command.
        it("line adds one command", function()
            local shape = lurek.render.newShape()
            shape:line(0, 0, 100, 100)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies polyline appends one draw command.
        it("polyline adds one command", function()
            local shape = lurek.render.newShape()
            shape:polyline(0, 0, 100, 100, 200, 0)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies arc appends one draw command.
        it("arc adds one command", function()
            local shape = lurek.render.newShape()
            shape:arc("fill", 0, 0, 50, 0, math.pi)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies arc accepts an explicit segment count.
        it("arc with explicit segments adds one command", function()
            local shape = lurek.render.newShape()
            shape:arc("line", 0, 0, 50, 0, math.pi, 64)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies multiple primitive builders accumulate commands in order.
        it("multiple primitives accumulate", function()
            local shape = lurek.render.newShape()
            shape:rectangle("fill", 0, 0, 100, 50)
            shape:circle("line", 50, 50, 20)
            shape:line(0, 0, 100, 100)
            expect_equal(3, shape:getCommandCount())
        end)
    end)

    -- â”€â”€ State builder methods â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    -- @description Covers suite: state builder methods.
    describe("state builder methods", function()
        -- @covers lurek.render.newShape
        -- @description Verifies setColor appends a state command.
        it("setColor adds a command", function()
            local shape = lurek.render.newShape()
            shape:setColor(1, 0, 0)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies setColor accepts alpha and still appends one state command.
        it("setColor with alpha adds a command", function()
            local shape = lurek.render.newShape()
            shape:setColor(0, 1, 0, 0.5)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies setLineWidth appends a state command.
        it("setLineWidth adds a command", function()
            local shape = lurek.render.newShape()
            shape:setLineWidth(3.0)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies state commands and primitives both count toward the command list.
        it("setColor before primitive affects count", function()
            local shape = lurek.render.newShape()
            shape:setColor(1, 0, 0)
            shape:rectangle("fill", 0, 0, 100, 50)
            expect_equal(2, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies repeated setColor calls append separate state commands.
        it("multiple setColor calls all add commands", function()
            local shape = lurek.render.newShape()
            shape:setColor(1, 0, 0)
            shape:setColor(0, 1, 0)
            shape:setColor(0, 0, 1)
            expect_equal(3, shape:getCommandCount())
        end)
    end)

    -- â”€â”€ polygon validation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    -- @description Covers suite: polygon validation.
    describe("polygon validation", function()
        -- @covers lurek.render.newShape
        -- @description Verifies polygon accepts exactly three vertices.
        it("polygon with 3 vertices succeeds", function()
            local shape = lurek.render.newShape()
            shape:polygon("fill", 0, 0, 50, 0, 25, 50)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies polygon accepts more than three vertices.
        it("polygon with more than 3 vertices succeeds", function()
            local shape = lurek.render.newShape()
            shape:polygon("fill", 0, 0,  100, 0,  100, 100,  0, 100)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies polygon rejects fewer than three vertices.
        it("polygon with fewer than 3 vertices raises error", function()
            local shape = lurek.render.newShape()
            expect_error(function()
                shape:polygon("fill", 0, 0, 50, 0)  -- only 2 vertices (4 numbers)
            end)
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies failed polygon validation does not append a command.
        it("polygon error does not increment command count", function()
            local shape = lurek.render.newShape()
            pcall(function() shape:polygon("fill", 0, 0, 50, 0) end)
            expect_equal(0, shape:getCommandCount())
        end)
    end)

    -- â”€â”€ polyline validation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    -- @description Covers suite: polyline validation.
    describe("polyline validation", function()
        -- @covers lurek.render.newShape
        -- @description Verifies polyline accepts exactly two points.
        it("polyline with 2 points succeeds", function()
            local shape = lurek.render.newShape()
            shape:polyline(0, 0, 100, 100)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies polyline accepts more than two points.
        it("polyline with 3 points succeeds", function()
            local shape = lurek.render.newShape()
            shape:polyline(0, 0, 100, 100, 200, 0)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies polyline rejects fewer than two points.
        it("polyline with fewer than 2 points raises error", function()
            local shape = lurek.render.newShape()
            expect_error(function()
                shape:polyline(0, 0)  -- only 1 point (2 numbers)
            end)
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies failed polyline validation does not append a command.
        it("polyline error does not increment command count", function()
            local shape = lurek.render.newShape()
            pcall(function() shape:polyline(0, 0) end)
            expect_equal(0, shape:getCommandCount())
        end)
    end)

    -- â”€â”€ draw dispatch â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    -- @description Covers suite: draw dispatch.
    describe("draw dispatch", function()
        -- @covers lurek.render.newShape
        -- @description Verifies drawing an empty shape is a safe no-op.
        it("draw on empty shape does not error", function()
            local shape = lurek.render.newShape()
            expect_no_error(function()
                shape:draw(100, 200)
            end)
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies draw accepts the full transform argument list.
        it("draw with all transform args does not error", function()
            local shape = lurek.render.newShape()
            expect_no_error(function()
                shape:draw(0, 0, 0.5, 2.0, 2.0, 10, 10)
            end)
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies draw accepts the minimal x and y arguments.
        it("draw with minimal args does not error", function()
            local shape = lurek.render.newShape()
            expect_no_error(function()
                shape:draw(0, 0)
            end)
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies populated shapes can be drawn without error.
        it("draw on populated shape does not error", function()
            local shape = lurek.render.newShape()
            shape:circle("fill", 0, 0, 30)
            expect_no_error(function()
                shape:draw(100, 100)
            end)
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies draw does not mutate the stored command list.
        it("draw does not change command count", function()
            local shape = lurek.render.newShape()
            shape:circle("fill", 0, 0, 30)
            shape:draw(100, 100)
            -- draw pushes to the draw queue, not to the shape command list
            expect_equal(1, shape:getCommandCount())
        end)
    end)

    -- â”€â”€ clear â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    -- @description Covers suite: clear.
    describe("clear", function()
        -- @covers lurek.render.newShape
        -- @description Verifies clear resets the command list to zero entries.
        it("clear resets command count to 0", function()
            local shape = lurek.render.newShape()
            shape:rectangle("fill", 0, 0, 100, 50)
            shape:circle("line", 50, 50, 20)
            shape:line(0, 0, 100, 100)
            shape:clear()
            expect_equal(0, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies builders still work after a clear.
        it("builder calls after clear succeed", function()
            local shape = lurek.render.newShape()
            shape:circle("fill", 0, 0, 30)
            shape:clear()
            shape:rectangle("fill", 0, 0, 100, 50)
            expect_equal(1, shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies draw remains safe after a clear.
        it("draw after clear does not error", function()
            local shape = lurek.render.newShape()
            shape:circle("fill", 0, 0, 30)
            shape:clear()
            expect_no_error(function()
                shape:draw(0, 0)
            end)
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies clearing an already empty shape is safe.
        it("clear on already-empty shape does not error", function()
            local shape = lurek.render.newShape()
            expect_no_error(function()
                shape:clear()
            end)
            expect_equal(0, shape:getCommandCount())
        end)
    end)

    -- â”€â”€ method sequencing â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    -- @description Covers suite: method chaining.
    describe("method chaining", function()
        -- @covers lurek.render.newShape
        -- @description Verifies state and primitive builders can be sequenced without errors.
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
        -- @description Verifies getCommandCount returns a numeric type.
        it("getCommandCount returns a number type", function()
            local shape = lurek.render.newShape()
            shape:circle("fill", 0, 0, 10)
            expect_type("number", shape:getCommandCount())
        end)

        -- @covers lurek.render.newShape
        -- @description Verifies interleaving state and primitive commands accumulates every entry.
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
