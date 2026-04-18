-- tests/lua/library/test_library_doll.lua
-- BDD tests for the doll (socket-based visual composition) module

local doll = require("library.doll")

-- â”€â”€ Part â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies part defaults plus texture, transform, colour, flip, attribute, fixture, origin, and rotation-following helpers.
describe("Part", function()
    -- @covers library.doll.newPart
    -- @description Verifies case: creates with default values.
    it("creates with default values", function()
        local p = doll.newPart()
        expect_not_nil(p, "newPart returns object")
        expect_nil(p:getTexture(), "no default texture")
        expect_nil(p:getQuad(), "no default quad")
        local ox, oy = p:getOffset()
        expect_equal(0, ox, "offsetX=0")
        expect_equal(0, oy, "offsetY=0")
        expect_equal(0, p:getRotation(), "rotation=0")
        local sx, sy = p:getScale()
        expect_equal(1, sx, "scaleX=1")
        expect_equal(1, sy, "scaleY=1")
        expect_equal(0, p:getDrawOrder(), "drawOrder=0")
        expect_equal("", p:getPartType(), "empty partType")
        expect_true(p:isVisible(), "visible by default")
        expect_true(p:getFollowsRotation(), "followsRotation by default")
    end)

    -- @description Verifies case: sets and gets texture.
    it("sets and gets texture", function()
        local p = doll.newPart()
        p:setTexture("hero.png")
        expect_equal("hero.png", p:getTexture())
    end)

    -- @description Verifies case: sets and gets offset.
    it("sets and gets offset", function()
        local p = doll.newPart()
        p:setOffset(10, 20)
        local ox, oy = p:getOffset()
        expect_equal(10, ox)
        expect_equal(20, oy)
    end)

    -- @description Verifies case: sets and gets scale with single arg.
    it("sets and gets scale with single arg", function()
        local p = doll.newPart()
        p:setScale(2)
        local sx, sy = p:getScale()
        expect_equal(2, sx)
        expect_equal(2, sy)
    end)

    -- @description Verifies case: sets and gets scale with two args.
    it("sets and gets scale with two args", function()
        local p = doll.newPart()
        p:setScale(3, 4)
        local sx, sy = p:getScale()
        expect_equal(3, sx)
        expect_equal(4, sy)
    end)

    -- @description Verifies case: sets and gets color.
    it("sets and gets color", function()
        local p = doll.newPart()
        p:setColor(0.5, 0.6, 0.7, 0.8)
        local r, g, b, a = p:getColor()
        expect_near(0.5, r, 0.001)
        expect_near(0.6, g, 0.001)
        expect_near(0.7, b, 0.001)
        expect_near(0.8, a, 0.001)
    end)

    -- @description Verifies case: default color alpha = 1 when omitted.
    it("default color alpha = 1 when omitted", function()
        local p = doll.newPart()
        p:setColor(1, 0, 0)
        local _, _, _, a = p:getColor()
        expect_equal(1, a)
    end)

    -- @description Verifies case: sets and gets flip.
    it("sets and gets flip", function()
        local p = doll.newPart()
        p:setFlip(true, false)
        local fx, fy = p:getFlip()
        expect_true(fx)
        expect_false(fy)
    end)

    -- @description Verifies case: flip with single arg defaults fy to false.
    it("flip with single arg defaults fy to false", function()
        local p = doll.newPart()
        p:setFlip(true)
        local fx, fy = p:getFlip()
        expect_true(fx)
        expect_false(fy)
    end)

    -- @description Verifies case: sets and gets attributes.
    it("sets and gets attributes", function()
        local p = doll.newPart()
        p:setAttribute("material", "steel")
        p:setAttribute("weight", 42)
        expect_equal("steel", p:getAttribute("material"))
        expect_equal(42, p:getAttribute("weight"))
        expect_nil(p:getAttribute("nonexist"))
    end)

    -- @description Verifies case: returns attribute keys.
    it("returns attribute keys", function()
        local p = doll.newPart()
        p:setAttribute("a", 1)
        p:setAttribute("b", 2)
        local keys = p:getAttributeKeys()
        expect_equal(2, #keys, "two keys")
    end)

    -- @description Verifies case: sets and gets fixture ref.
    it("sets and gets fixture ref", function()
        local p = doll.newPart()
        expect_nil(p:getFixture())
        local fixture = { id = 99 }
        p:setFixture(fixture)
        expect_equal(99, p:getFixture().id)
    end)

    -- @description Verifies case: sets and gets followsRotation.
    it("sets and gets followsRotation", function()
        local p = doll.newPart()
        p:setFollowsRotation(false)
        expect_false(p:getFollowsRotation())
    end)

    -- @description Verifies case: sets and gets origin.
    it("sets and gets origin", function()
        local p = doll.newPart()
        p:setOrigin(16, 32)
        local ox, oy = p:getOrigin()
        expect_equal(16, ox)
        expect_equal(32, oy)
    end)
end)

-- â”€â”€ DollTemplate â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers template naming, socket registration, duplicate rejection, removal, lookup, ordering, and default socket field values.
describe("DollTemplate", function()
    -- @covers library.doll.newTemplate
    -- @description Verifies case: creates with name.
    it("creates with name", function()
        local t = doll.newTemplate("player")
        expect_equal("player", t:getName())
    end)

    -- @description Verifies case: renames.
    it("renames", function()
        local t = doll.newTemplate("old")
        t:setName("new")
        expect_equal("new", t:getName())
    end)

    -- @description Verifies case: adds sockets.
    it("adds sockets", function()
        local t = doll.newTemplate("char")
        t:addSocket("head",  "head",  0, -32, 0, 10)
        t:addSocket("torso", "body",  0,   0, 0, 5)
        t:addSocket("legs",  "legs",  0,  32, 0, 0)
        expect_equal(3, t:getSocketCount())
    end)

    -- @description Verifies case: gets socket by name.
    it("gets socket by name", function()
        local t = doll.newTemplate("char")
        t:addSocket("head", "head", 5, -10, 0.1, 10)
        local s = t:getSocket("head")
        expect_not_nil(s)
        expect_equal("head", s.name)
        expect_equal("head", s.acceptType)
        expect_equal(5, s.x)
        expect_equal(-10, s.y)
        expect_near(0.1, s.rotation, 0.001)
        expect_equal(10, s.drawOrder)
    end)

    -- @description Verifies case: get socket returns nil for missing name.
    it("get socket returns nil for missing name", function()
        local t = doll.newTemplate("char")
        expect_nil(t:getSocket("nonexist"))
    end)

    -- @description Verifies case: rejects duplicate socket names.
    it("rejects duplicate socket names", function()
        local t = doll.newTemplate("char")
        t:addSocket("head", "head", 0, 0)
        t:addSocket("head", "head", 5, 5)
        expect_equal(1, t:getSocketCount(), "still 1 socket")
        local s = t:getSocket("head")
        expect_equal(0, s.x, "original socket unchanged")
    end)

    -- @description Verifies case: removes socket.
    it("removes socket", function()
        local t = doll.newTemplate("char")
        t:addSocket("head", "", 0, 0)
        t:addSocket("body", "", 0, 10)
        expect_true(t:removeSocket("head"))
        expect_equal(1, t:getSocketCount())
        expect_nil(t:getSocket("head"))
        expect_not_nil(t:getSocket("body"))
    end)

    -- @description Verifies case: remove nonexistent returns false.
    it("remove nonexistent returns false", function()
        local t = doll.newTemplate("char")
        expect_false(t:removeSocket("nope"))
    end)

    -- @description Verifies case: lists socket names in order.
    it("lists socket names in order", function()
        local t = doll.newTemplate("char")
        t:addSocket("c_legs", "", 0, 0)
        t:addSocket("a_head", "", 0, 0)
        t:addSocket("b_body", "", 0, 0)
        local names = t:getSocketNames()
        expect_equal(3, #names)
        expect_equal("c_legs", names[1])
        expect_equal("a_head", names[2])
        expect_equal("b_body", names[3])
    end)

    -- @description Verifies case: uses defaults for optional parameters.
    it("uses defaults for optional parameters", function()
        local t = doll.newTemplate("simple")
        t:addSocket("s1")
        local s = t:getSocket("s1")
        expect_equal("", s.acceptType)
        expect_equal(0, s.x)
        expect_equal(0, s.y)
        expect_equal(0, s.rotation)
        expect_equal(0, s.drawOrder)
    end)
end)

-- â”€â”€ Doll â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Exercises doll transforms, attachment rules, detach flows, socket occupancy queries, and body or userdata references.
describe("Doll", function()
    local function make_template()
        local t = doll.newTemplate("vehicle")
        t:addSocket("chassis",  "chassis",   0,   0, 0, 0)
        t:addSocket("turret",   "weapon",    0, -16, 0, 10)
        t:addSocket("exhaust",  "",          20,  5, 0, -1)
        return t
    end

    -- @description Verifies case: creates with template.
    it("creates with template", function()
        local t = make_template()
        local d = doll.newDoll(t)
        expect_not_nil(d)
        expect_equal(t, d:getTemplate())
    end)

    -- @description Verifies case: default transform.
    it("default transform", function()
        local d = doll.newDoll(make_template())
        local x, y = d:getPosition()
        expect_equal(0, x)
        expect_equal(0, y)
        expect_equal(0, d:getRotation())
        local sx, sy = d:getScale()
        expect_equal(1, sx)
        expect_equal(1, sy)
        expect_true(d:isVisible())
    end)

    -- @description Verifies case: sets position and rotation.
    it("sets position and rotation", function()
        local d = doll.newDoll(make_template())
        d:setPosition(100, 200)
        d:setRotation(1.5)
        local x, y = d:getPosition()
        expect_equal(100, x)
        expect_equal(200, y)
        expect_near(1.5, d:getRotation(), 0.001)
    end)

    -- @description Verifies case: attaches part to matching socket.
    it("attaches part to matching socket", function()
        local d = doll.newDoll(make_template())
        local part = doll.newPart()
        part:setPartType("chassis")
        expect_true(d:attach("chassis", part))
        expect_equal(part, d:getPartAt("chassis"))
    end)

    -- @description Verifies case: rejects attach with wrong type.
    it("rejects attach with wrong type", function()
        local d = doll.newDoll(make_template())
        local part = doll.newPart()
        part:setPartType("armor")
        expect_false(d:attach("chassis", part), "chassis accepts 'chassis' type only")
    end)

    -- @description Verifies case: accepts any type on empty acceptType socket.
    it("accepts any type on empty acceptType socket", function()
        local d = doll.newDoll(make_template())
        local part = doll.newPart()
        part:setPartType("smoke")
        expect_true(d:attach("exhaust", part), "exhaust accepts anything")
    end)

    -- @description Verifies case: rejects attach to nonexistent socket.
    it("rejects attach to nonexistent socket", function()
        local d = doll.newDoll(make_template())
        local part = doll.newPart()
        expect_false(d:attach("nonexist", part))
    end)

    -- @description Verifies case: detaches part.
    it("detaches part", function()
        local d = doll.newDoll(make_template())
        local part = doll.newPart()
        part:setPartType("chassis")
        d:attach("chassis", part)
        local detached = d:detach("chassis")
        expect_equal(part, detached)
        expect_nil(d:getPartAt("chassis"))
    end)

    -- @description Verifies case: detach nonexistent returns nil.
    it("detach nonexistent returns nil", function()
        local d = doll.newDoll(make_template())
        expect_nil(d:detach("nonexist"))
    end)

    -- @description Verifies case: detachAll clears slots.
    it("detachAll clears slots", function()
        local d = doll.newDoll(make_template())
        local p1 = doll.newPart()
        p1:setPartType("chassis")
        local p2 = doll.newPart()
        p2:setPartType("weapon")
        d:attach("chassis", p1)
        d:attach("turret", p2)
        d:detachAll()
        expect_equal(0, #d:getAttachedSockets())
    end)

    -- @description Verifies case: findSocket returns socket name for a part.
    it("findSocket returns socket name for a part", function()
        local d = doll.newDoll(make_template())
        local part = doll.newPart()
        part:setPartType("weapon")
        d:attach("turret", part)
        expect_equal("turret", d:findSocket(part))
    end)

    -- @description Verifies case: findSocket returns nil for unattached part.
    it("findSocket returns nil for unattached part", function()
        local d = doll.newDoll(make_template())
        local part = doll.newPart()
        expect_nil(d:findSocket(part))
    end)

    -- @description Verifies case: lists attached and empty sockets.
    it("lists attached and empty sockets", function()
        local d = doll.newDoll(make_template())
        local part = doll.newPart()
        part:setPartType("chassis")
        d:attach("chassis", part)
        expect_equal(1, #d:getAttachedSockets())
        expect_equal(2, #d:getEmptySockets())
    end)

    -- @description Verifies case: body and userData refs.
    it("body and userData refs", function()
        local d = doll.newDoll(make_template())
        expect_nil(d:getBody())
        expect_nil(d:getUserData())
        d:setBody("body_ref")
        d:setUserData({ hp = 100 })
        expect_equal("body_ref", d:getBody())
        expect_equal(100, d:getUserData().hp)
    end)
end)

-- â”€â”€ getDrawList â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Validates draw-list generation for empty and populated dolls, combined ordering, world transforms, visibility, and scale effects.
describe("Doll:getDrawList", function()
    -- @covers library.doll.newDoll
    -- @description Verifies case: empty doll returns empty list.
    it("empty doll returns empty list", function()
        local t = doll.newTemplate("empty")
        t:addSocket("slot1", "", 0, 0)
        local d = doll.newDoll(t)
        local dl = d:getDrawList()
        expect_equal(0, #dl)
    end)

    -- @description Verifies case: returns entries for attached parts.
    it("returns entries for attached parts", function()
        local t = doll.newTemplate("char")
        t:addSocket("head", "", 0, -20, 0, 10)
        t:addSocket("body", "", 0,   0, 0, 0)
        local d = doll.newDoll(t)
        d:setPosition(100, 200)

        local head = doll.newPart()
        local body = doll.newPart()
        d:attach("head", head)
        d:attach("body", body)

        local dl = d:getDrawList()
        expect_equal(2, #dl, "two entries")
    end)

    -- @description Verifies case: sorts by combined drawOrder.
    it("sorts by combined drawOrder", function()
        local t = doll.newTemplate("char")
        t:addSocket("bg",   "", 0, 0, 0, 0)
        t:addSocket("fg",   "", 0, 0, 0, 20)
        t:addSocket("mid",  "", 0, 0, 0, 10)
        local d = doll.newDoll(t)

        local p1 = doll.newPart()
        local p2 = doll.newPart()
        local p3 = doll.newPart()
        d:attach("bg", p1)
        d:attach("fg", p2)
        d:attach("mid", p3)

        local dl = d:getDrawList()
        expect_equal("bg",  dl[1].socketName)
        expect_equal("mid", dl[2].socketName)
        expect_equal("fg",  dl[3].socketName)
    end)

    -- @description Verifies case: computes world position at doll origin.
    it("computes world position at doll origin", function()
        local t = doll.newTemplate("simple")
        t:addSocket("s", "", 10, 20, 0, 0)
        local d = doll.newDoll(t)
        d:setPosition(100, 200)

        local part = doll.newPart()
        d:attach("s", part)

        local dl = d:getDrawList()
        expect_near(110, dl[1].x, 0.01, "x = doll.x + socket.x")
        expect_near(220, dl[1].y, 0.01, "y = doll.y + socket.y")
    end)

    -- @description Verifies case: applies doll rotation to socket positions.
    it("applies doll rotation to socket positions", function()
        local t = doll.newTemplate("rot")
        t:addSocket("right", "", 10, 0, 0, 0)  -- 10 px to the right
        local d = doll.newDoll(t)
        d:setPosition(0, 0)
        d:setRotation(math.pi / 2)  -- 90 degrees CCW

        local part = doll.newPart()
        d:attach("right", part)

        local dl = d:getDrawList()
        -- After 90 degree rotation, (10, 0) should become approximately (0, 10)
        expect_near(0,  dl[1].x, 0.01, "rotated x")
        expect_near(10, dl[1].y, 0.01, "rotated y")
    end)

    -- @description Verifies case: applies doll scale.
    it("applies doll scale", function()
        local t = doll.newTemplate("scaled")
        t:addSocket("s", "", 10, 20, 0, 0)
        local d = doll.newDoll(t)
        d:setPosition(0, 0)
        d:setScale(2)

        local part = doll.newPart()
        d:attach("s", part)

        local dl = d:getDrawList()
        expect_near(20, dl[1].x, 0.01)
        expect_near(40, dl[1].y, 0.01)
        expect_near(2, dl[1].scaleX, 0.01)
        expect_near(2, dl[1].scaleY, 0.01)
    end)

    -- @description Verifies case: part.followsRotation=false excludes doll rotation.
    it("part.followsRotation=false excludes doll rotation", function()
        local t = doll.newTemplate("nofr")
        t:addSocket("s", "", 0, 0, 0.5, 0)
        local d = doll.newDoll(t)
        d:setRotation(1.0)

        local part = doll.newPart()
        part:setFollowsRotation(false)
        d:attach("s", part)

        local dl = d:getDrawList()
        -- worldRot = socket.rotation + part.rotation = 0.5 + 0 = 0.5 (NOT + doll rotation)
        expect_near(0.5, dl[1].rotation, 0.001)
    end)

    -- @description Verifies case: part.followsRotation=true includes doll rotation.
    it("part.followsRotation=true includes doll rotation", function()
        local t = doll.newTemplate("fr")
        t:addSocket("s", "", 0, 0, 0.5, 0)
        local d = doll.newDoll(t)
        d:setRotation(1.0)

        local part = doll.newPart()
        part:setFollowsRotation(true)
        d:attach("s", part)

        local dl = d:getDrawList()
        -- worldRot = doll.rotation + socket.rotation + part.rotation = 1.0 + 0.5 + 0 = 1.5
        expect_near(1.5, dl[1].rotation, 0.001)
    end)

    -- @description Verifies case: flip negates scale in draw list.
    it("flip negates scale in draw list", function()
        local t = doll.newTemplate("flip")
        t:addSocket("s", "", 0, 0, 0, 0)
        local d = doll.newDoll(t)

        local part = doll.newPart()
        part:setFlip(true, false)
        d:attach("s", part)

        local dl = d:getDrawList()
        expect_near(-1, dl[1].scaleX, 0.01, "flipX negates scaleX")
        expect_near(1,  dl[1].scaleY, 0.01, "no flipY")
    end)

    -- @description Verifies case: part drawOrder adds to socket drawOrder.
    it("part drawOrder adds to socket drawOrder", function()
        local t = doll.newTemplate("order")
        t:addSocket("s1", "", 0, 0, 0, 10)
        t:addSocket("s2", "", 0, 0, 0, 5)
        local d = doll.newDoll(t)

        local p1 = doll.newPart()
        p1:setDrawOrder(-8)  -- combined = 10 + (-8) = 2
        local p2 = doll.newPart()
        p2:setDrawOrder(0)   -- combined = 5 + 0 = 5

        d:attach("s1", p1)
        d:attach("s2", p2)

        local dl = d:getDrawList()
        expect_equal("s1", dl[1].socketName, "s1 drawOrder 2 comes first")
        expect_equal("s2", dl[2].socketName, "s2 drawOrder 5 comes second")
    end)

    -- @description Verifies case: includes part offset in world position.
    it("includes part offset in world position", function()
        local t = doll.newTemplate("offset")
        t:addSocket("s", "", 10, 0, 0, 0)
        local d = doll.newDoll(t)
        d:setPosition(100, 100)

        local part = doll.newPart()
        part:setOffset(5, 3)
        d:attach("s", part)

        local dl = d:getDrawList()
        expect_near(115, dl[1].x, 0.01, "100 + 10 + 5")
        expect_near(103, dl[1].y, 0.01, "100 + 0 + 3")
    end)
end)

-- â”€â”€ Hot-swap â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Tests replacing attached parts at runtime so hot-swapping preserves socket routing and updated draw output.
describe("Doll hot-swap", function()
    -- @covers library.doll.newDoll
    -- @description Verifies case: replaces part at socket.
    it("replaces part at socket", function()
        local t = doll.newTemplate("swap")
        t:addSocket("weapon", "", 0, 0, 0, 0)
        local d = doll.newDoll(t)

        local sword = doll.newPart()
        sword:setPartType("melee")
        d:attach("weapon", sword)
        expect_equal(sword, d:getPartAt("weapon"))

        local bow = doll.newPart()
        bow:setPartType("ranged")
        d:attach("weapon", bow)
        expect_equal(bow, d:getPartAt("weapon"))
    end)
end)

-- ── Input Validation ──────────────────────────────────────────────────────────

-- @description Verifies input validation for socket names, scale values, and draw orders.
describe("Input Validation", function()
    -- @description Verifies case: addSocket returns false for duplicate name.
    it("addSocket returns false for duplicate name", function()
        local t = doll.newTemplate("val")
        local ok1 = t:addSocket("head", "", 0, 0)
        expect_true(ok1, "first add succeeds")
        local ok2, msg = t:addSocket("head", "", 5, 5)
        expect_false(ok2, "duplicate returns false")
        expect_not_nil(msg, "returns error message")
    end)

    -- @description Verifies case: addSocket returns true on success.
    it("addSocket returns true on success", function()
        local t = doll.newTemplate("val2")
        local ok = t:addSocket("arm", "limb", 5, 10, 0.1, 3)
        expect_true(ok, "valid add returns true")
    end)

    -- @description Verifies case: addSocket returns false for empty name.
    it("addSocket returns false for empty name", function()
        local t = doll.newTemplate("val3")
        local ok, msg = t:addSocket("", "", 0, 0)
        expect_false(ok, "empty name returns false")
        expect_not_nil(msg, "returns error message")
    end)

    -- @description Verifies case: setScale rejects non-number.
    it("setScale rejects non-number", function()
        local p = doll.newPart()
        local ok = pcall(function() p:setScale("big") end)
        expect_false(ok, "string scale rejected")
    end)

    -- @description Verifies case: setDrawOrder rejects non-number.
    it("setDrawOrder rejects non-number", function()
        local p = doll.newPart()
        local ok = pcall(function() p:setDrawOrder("high") end)
        expect_false(ok, "string drawOrder rejected")
    end)

    -- @description Verifies case: attach rejects empty string socketName.
    it("attach rejects empty string socketName", function()
        local t = doll.newTemplate("valatt")
        t:addSocket("s", "", 0, 0)
        local d = doll.newDoll(t)
        local part = doll.newPart()
        expect_false(d:attach("", part), "empty socket name rejected")
    end)
end)

-- ── Part:getAbsoluteScale ─────────────────────────────────────────────────────

-- @description Verifies getAbsoluteScale returns positive magnitude regardless of flip or negative scale.
describe("Part:getAbsoluteScale", function()
    -- @description Verifies case: positive scale unaffected by flip flags.
    it("returns positive scale regardless of flip", function()
        local p = doll.newPart()
        p:setScale(3, 4)
        p:setFlip(true, true)
        local asx, asy = p:getAbsoluteScale()
        expect_equal(3, asx, "absolute scaleX")
        expect_equal(4, asy, "absolute scaleY")
    end)

    -- @description Verifies case: absolute of negative scale values.
    it("returns absolute of negative scale values", function()
        local p = doll.newPart()
        p:setScale(-2, -5)
        local asx, asy = p:getAbsoluteScale()
        expect_equal(2, asx)
        expect_equal(5, asy)
    end)
end)

-- ── Part:getAttributes ────────────────────────────────────────────────────────

-- @description Verifies getAttributes returns a shallow copy of all stored key-value attributes.
describe("Part:getAttributes", function()
    -- @description Verifies case: empty attributes.
    it("returns empty table when no attributes set", function()
        local p = doll.newPart()
        local attrs = p:getAttributes()
        expect_equal(0, #p:getAttributeKeys())
        -- attrs table exists but is empty
        local count = 0
        for _ in pairs(attrs) do count = count + 1 end
        expect_equal(0, count)
    end)

    -- @description Verifies case: returns shallow copy; mutation does not affect original.
    it("returns shallow copy of all attributes", function()
        local p = doll.newPart()
        p:setAttribute("color", "red")
        p:setAttribute("weight", 10)
        local attrs = p:getAttributes()
        expect_equal("red", attrs.color)
        expect_equal(10, attrs.weight)
        -- modifying copy does not affect original
        attrs.color = "blue"
        expect_equal("red", p:getAttribute("color"))
    end)
end)

-- ── doll.getAbsoluteScale (module function) ───────────────────────────────────

-- @description Verifies the module-level getAbsoluteScale helper strips flip sign from draw-list entries.
describe("doll.getAbsoluteScale", function()
    -- @description Verifies case: positive magnitude from flipped draw entry.
    it("returns positive magnitude from flipped draw entry", function()
        local t = doll.newTemplate("abs")
        t:addSocket("s", "", 0, 0, 0, 0)
        local d = doll.newDoll(t)
        d:setScale(2, 3)

        local part = doll.newPart()
        part:setFlip(true, false)
        d:attach("s", part)

        local dl = d:getDrawList()
        local asx, asy = doll.getAbsoluteScale(dl[1])
        expect_near(2, asx, 0.01, "abs scaleX = 2")
        expect_near(3, asy, 0.01, "abs scaleY = 3")
    end)

    -- @description Verifies case: compound part+doll scale with flip.
    it("compounds doll+part scale with flip correctly", function()
        local t = doll.newTemplate("abs2")
        t:addSocket("s", "", 0, 0, 0, 0)
        local d = doll.newDoll(t)
        d:setScale(2)

        local part = doll.newPart()
        part:setScale(3)
        part:setFlip(true, true)
        d:attach("s", part)

        local dl = d:getDrawList()
        -- worldSX = 2 * 3 * -1 = -6, worldSY = 2 * 3 * -1 = -6
        expect_near(-6, dl[1].scaleX, 0.01)
        expect_near(-6, dl[1].scaleY, 0.01)
        local asx, asy = doll.getAbsoluteScale(dl[1])
        expect_near(6, asx, 0.01, "absolute = 6")
        expect_near(6, asy, 0.01, "absolute = 6")
    end)
end)

-- ── Socket rotation transforms ────────────────────────────────────────────────

-- @description Verifies part offset is rotated by socket rotation in the draw list.
describe("Socket rotation transforms", function()
    -- @description Verifies case: part offset rotated by socket rotation.
    it("rotates part offset by socket rotation", function()
        local t = doll.newTemplate("sockrot")
        -- socket at (0,0) rotated 90 degrees
        t:addSocket("s", "", 0, 0, math.pi / 2, 0)
        local d = doll.newDoll(t)
        d:setPosition(100, 100)

        local part = doll.newPart()
        part:setOffset(10, 0)  -- 10px to the right in socket space
        d:attach("s", part)

        local dl = d:getDrawList()
        -- After 90 deg socket rotation, offset (10,0) becomes ~(0,10)
        expect_near(100, dl[1].x, 0.01, "x unchanged")
        expect_near(110, dl[1].y, 0.01, "y shifted by rotated offset")
    end)

    -- @description Verifies case: draw list includes part origin fields.
    it("draw list includes part origin", function()
        local t = doll.newTemplate("origin")
        t:addSocket("s", "", 0, 0, 0, 0)
        local d = doll.newDoll(t)

        local part = doll.newPart()
        part:setOrigin(16, 32)
        d:attach("s", part)

        local dl = d:getDrawList()
        expect_equal(16, dl[1].originX, "originX in draw entry")
        expect_equal(32, dl[1].originY, "originY in draw entry")
    end)

    -- @description Verifies case: default origin is (0,0) in draw list.
    it("default origin is zero in draw list", function()
        local t = doll.newTemplate("deforigin")
        t:addSocket("s", "", 0, 0, 0, 0)
        local d = doll.newDoll(t)

        local part = doll.newPart()
        d:attach("s", part)

        local dl = d:getDrawList()
        expect_equal(0, dl[1].originX)
        expect_equal(0, dl[1].originY)
    end)
end)

-- ── Flip behaviour ────────────────────────────────────────────────────────────

-- @description Verifies flip flags produce correct negative scale values in the draw list.
describe("Flip behaviour", function()
    -- @description Verifies case: both flipX and flipY negate corresponding scales.
    it("flipX + flipY both negate corresponding scales", function()
        local t = doll.newTemplate("flip2")
        t:addSocket("s", "", 0, 0, 0, 0)
        local d = doll.newDoll(t)
        d:setScale(2, 3)

        local part = doll.newPart()
        part:setFlip(true, true)
        d:attach("s", part)

        local dl = d:getDrawList()
        expect_near(-2, dl[1].scaleX, 0.01, "flipX negates")
        expect_near(-3, dl[1].scaleY, 0.01, "flipY negates")
    end)

    -- @description Verifies case: flip with part scale compounds correctly.
    it("flip with part scale compounds correctly", function()
        local t = doll.newTemplate("flipscale")
        t:addSocket("s", "", 0, 0, 0, 0)
        local d = doll.newDoll(t)
        d:setScale(2)

        local part = doll.newPart()
        part:setScale(3)
        part:setFlip(true, false)
        d:attach("s", part)

        local dl = d:getDrawList()
        -- worldSX = dollScale * partScale * flipSign = 2 * 3 * -1 = -6
        expect_near(-6, dl[1].scaleX, 0.01, "compound flip+scale X")
        expect_near(6,  dl[1].scaleY, 0.01, "no flip on Y")
    end)

    -- @description Verifies case: no flip means positive scale.
    it("no flip means positive scale", function()
        local t = doll.newTemplate("noflip")
        t:addSocket("s", "", 0, 0, 0, 0)
        local d = doll.newDoll(t)
        d:setScale(2)

        local part = doll.newPart()
        part:setScale(3)
        d:attach("s", part)

        local dl = d:getDrawList()
        expect_near(6, dl[1].scaleX, 0.01, "positive scaleX")
        expect_near(6, dl[1].scaleY, 0.01, "positive scaleY")
    end)
end)

test_summary()
