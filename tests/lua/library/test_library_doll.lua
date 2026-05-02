-- tests/lua/library/test_library_doll.lua
-- BDD tests for the doll (socket-based visual composition) module

local doll = require("library.doll")

--                  Part

describe("Part", function()
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

    it("sets and gets texture", function()
        local p = doll.newPart()
        p:setTexture("hero.png")
        expect_equal("hero.png", p:getTexture())
    end)

    it("sets and gets offset", function()
        local p = doll.newPart()
        p:setOffset(10, 20)
        local ox, oy = p:getOffset()
        expect_equal(10, ox)
        expect_equal(20, oy)
    end)

    it("sets and gets scale with single arg", function()
        local p = doll.newPart()
        p:setScale(2)
        local sx, sy = p:getScale()
        expect_equal(2, sx)
        expect_equal(2, sy)
    end)

    it("sets and gets scale with two args", function()
        local p = doll.newPart()
        p:setScale(3, 4)
        local sx, sy = p:getScale()
        expect_equal(3, sx)
        expect_equal(4, sy)
    end)

    it("sets and gets color", function()
        local p = doll.newPart()
        p:setColor(0.5, 0.6, 0.7, 0.8)
        local r, g, b, a = p:getColor()
        expect_near(0.5, r, 0.001)
        expect_near(0.6, g, 0.001)
        expect_near(0.7, b, 0.001)
        expect_near(0.8, a, 0.001)
    end)

    it("default color alpha = 1 when omitted", function()
        local p = doll.newPart()
        p:setColor(1, 0, 0)
        local _, _, _, a = p:getColor()
        expect_equal(1, a)
    end)

    it("sets and gets flip", function()
        local p = doll.newPart()
        p:setFlip(true, false)
        local fx, fy = p:getFlip()
        expect_true(fx)
        expect_false(fy)
    end)

    it("flip with single arg defaults fy to false", function()
        local p = doll.newPart()
        p:setFlip(true)
        local fx, fy = p:getFlip()
        expect_true(fx)
        expect_false(fy)
    end)

    it("sets and gets attributes", function()
        local p = doll.newPart()
        p:setAttribute("material", "steel")
        p:setAttribute("weight", 42)
        expect_equal("steel", p:getAttribute("material"))
        expect_equal(42, p:getAttribute("weight"))
        expect_nil(p:getAttribute("nonexist"))
    end)

    it("returns attribute keys", function()
        local p = doll.newPart()
        p:setAttribute("a", 1)
        p:setAttribute("b", 2)
        local keys = p:getAttributeKeys()
        expect_equal(2, #keys, "two keys")
    end)

    it("sets and gets fixture ref", function()
        local p = doll.newPart()
        expect_nil(p:getFixture())
        local fixture = { id = 99 }
        p:setFixture(fixture)
        expect_equal(99, p:getFixture().id)
    end)

    it("sets and gets followsRotation", function()
        local p = doll.newPart()
        p:setFollowsRotation(false)
        expect_false(p:getFollowsRotation())
    end)

    it("sets and gets origin", function()
        local p = doll.newPart()
        p:setOrigin(16, 32)
        local ox, oy = p:getOrigin()
        expect_equal(16, ox)
        expect_equal(32, oy)
    end)
end)

--                  DollTemplate

describe("DollTemplate", function()
    it("creates with name", function()
        local t = doll.newTemplate("player")
        expect_equal("player", t:getName())
    end)

    it("renames", function()
        local t = doll.newTemplate("old")
        t:setName("new")
        expect_equal("new", t:getName())
    end)

    it("adds sockets", function()
        local t = doll.newTemplate("char")
        t:addSocket("head",  "head",  0, -32, 0, 10)
        t:addSocket("torso", "body",  0,   0, 0, 5)
        t:addSocket("legs",  "legs",  0,  32, 0, 0)
        expect_equal(3, t:getSocketCount())
    end)

    it("gets socket by name", function()
        local t = doll.newTemplate("char")
        t:addSocket("head", "head", 5, -10, 0.1, 10)
        local s = t:getSocket("head")
        expect_not_nil(s)
        if s ~= nil then
            expect_equal("head", s.name)
            expect_equal("head", s.acceptType)
            expect_equal(5, s.x)
            expect_equal(-10, s.y)
            expect_near(0.1, s.rotation, 0.001)
            expect_equal(10, s.drawOrder)
        end
    end)

    it("get socket returns nil for missing name", function()
        local t = doll.newTemplate("char")
        expect_nil(t:getSocket("nonexist"))
    end)

    it("rejects duplicate socket names", function()
        local t = doll.newTemplate("char")
        t:addSocket("head", "head", 0, 0)
        t:addSocket("head", "head", 5, 5)
        expect_equal(1, t:getSocketCount(), "still 1 socket")
        local s = t:getSocket("head")
        expect_not_nil(s)
        if s ~= nil then
            expect_equal(0, s.x, "original socket unchanged")
        end
    end)

    it("removes socket", function()
        local t = doll.newTemplate("char")
        t:addSocket("head", "", 0, 0)
        t:addSocket("body", "", 0, 10)
        expect_true(t:removeSocket("head"))
        expect_equal(1, t:getSocketCount())
        expect_nil(t:getSocket("head"))
        expect_not_nil(t:getSocket("body"))
    end)

    it("remove nonexistent returns false", function()
        local t = doll.newTemplate("char")
        expect_false(t:removeSocket("nope"))
    end)

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

    it("uses defaults for optional parameters", function()
        local t = doll.newTemplate("simple")
        t:addSocket("s1")
        local s = t:getSocket("s1")
        expect_not_nil(s)
        if s ~= nil then
            expect_equal("", s.acceptType)
            expect_equal(0, s.x)
            expect_equal(0, s.y)
            expect_equal(0, s.rotation)
            expect_equal(0, s.drawOrder)
        end
    end)
end)

--                  Doll

describe("Doll", function()
    local function make_template()
        local t = doll.newTemplate("vehicle")
        t:addSocket("chassis",  "chassis",   0,   0, 0, 0)
        t:addSocket("turret",   "weapon",    0, -16, 0, 10)
        t:addSocket("exhaust",  "",          20,  5, 0, -1)
        return t
    end

    it("creates with template", function()
        local t = make_template()
        local d = doll.newDoll(t)
        expect_not_nil(d)
        expect_equal(t, d:getTemplate())
    end)

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

    it("sets position and rotation", function()
        local d = doll.newDoll(make_template())
        d:setPosition(100, 200)
        d:setRotation(1.5)
        local x, y = d:getPosition()
        expect_equal(100, x)
        expect_equal(200, y)
        expect_near(1.5, d:getRotation(), 0.001)
    end)

    it("attaches part to matching socket", function()
        local d = doll.newDoll(make_template())
        local part = doll.newPart()
        part:setPartType("chassis")
        expect_true(d:attach("chassis", part))
        expect_equal(part, d:getPartAt("chassis"))
    end)

    it("rejects attach with wrong type", function()
        local d = doll.newDoll(make_template())
        local part = doll.newPart()
        part:setPartType("armor")
        expect_false(d:attach("chassis", part), "chassis accepts 'chassis' type only")
    end)

    it("accepts any type on empty acceptType socket", function()
        local d = doll.newDoll(make_template())
        local part = doll.newPart()
        part:setPartType("smoke")
        expect_true(d:attach("exhaust", part), "exhaust accepts anything")
    end)

    it("rejects attach to nonexistent socket", function()
        local d = doll.newDoll(make_template())
        local part = doll.newPart()
        expect_false(d:attach("nonexist", part))
    end)

    it("detaches part", function()
        local d = doll.newDoll(make_template())
        local part = doll.newPart()
        part:setPartType("chassis")
        d:attach("chassis", part)
        local detached = d:detach("chassis")
        expect_equal(part, detached)
        expect_nil(d:getPartAt("chassis"))
    end)

    it("detach nonexistent returns nil", function()
        local d = doll.newDoll(make_template())
        expect_nil(d:detach("nonexist"))
    end)

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

    it("findSocket returns socket name for a part", function()
        local d = doll.newDoll(make_template())
        local part = doll.newPart()
        part:setPartType("weapon")
        d:attach("turret", part)
        expect_equal("turret", d:findSocket(part))
    end)

    it("findSocket returns nil for unattached part", function()
        local d = doll.newDoll(make_template())
        local part = doll.newPart()
        expect_nil(d:findSocket(part))
    end)

    it("lists attached and empty sockets", function()
        local d = doll.newDoll(make_template())
        local part = doll.newPart()
        part:setPartType("chassis")
        d:attach("chassis", part)
        expect_equal(1, #d:getAttachedSockets())
        expect_equal(2, #d:getEmptySockets())
    end)

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

--                  getDrawList

describe("Doll:getDrawList", function()
    it("empty doll returns empty list", function()
        local t = doll.newTemplate("empty")
        t:addSocket("slot1", "", 0, 0)
        local d = doll.newDoll(t)
        local dl = d:getDrawList()
        expect_equal(0, #dl)
    end)

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

--                  Hot-swap

describe("Doll hot-swap", function()
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

--        Input Validation

describe("Input Validation", function()
    it("addSocket returns false for duplicate name", function()
        local t = doll.newTemplate("val")
        local ok1 = t:addSocket("head", "", 0, 0)
        expect_true(ok1, "first add succeeds")
        local ok2, msg = t:addSocket("head", "", 5, 5)
        expect_false(ok2, "duplicate returns false")
        expect_not_nil(msg, "returns error message")
    end)

    it("addSocket returns true on success", function()
        local t = doll.newTemplate("val2")
        local ok = t:addSocket("arm", "limb", 5, 10, 0.1, 3)
        expect_true(ok, "valid add returns true")
    end)

    it("addSocket returns false for empty name", function()
        local t = doll.newTemplate("val3")
        local ok, msg = t:addSocket("", "", 0, 0)
        expect_false(ok, "empty name returns false")
        expect_not_nil(msg, "returns error message")
    end)

    it("setScale rejects non-number", function()
        local p = doll.newPart()
        local ok = pcall(function() p:setScale("big") end)
        expect_false(ok, "string scale rejected")
    end)

    it("setDrawOrder rejects non-number", function()
        local p = doll.newPart()
        local ok = pcall(function() p:setDrawOrder("high") end)
        expect_false(ok, "string drawOrder rejected")
    end)

    it("attach rejects empty string socketName", function()
        local t = doll.newTemplate("valatt")
        t:addSocket("s", "", 0, 0)
        local d = doll.newDoll(t)
        local part = doll.newPart()
        expect_false(d:attach("", part), "empty socket name rejected")
    end)
end)

--        Part:getAbsoluteScale

describe("Part:getAbsoluteScale", function()
    it("returns positive scale regardless of flip", function()
        local p = doll.newPart()
        p:setScale(3, 4)
        p:setFlip(true, true)
        local asx, asy = p:getAbsoluteScale()
        expect_equal(3, asx, "absolute scaleX")
        expect_equal(4, asy, "absolute scaleY")
    end)

    it("returns absolute of negative scale values", function()
        local p = doll.newPart()
        p:setScale(-2, -5)
        local asx, asy = p:getAbsoluteScale()
        expect_equal(2, asx)
        expect_equal(5, asy)
    end)
end)

--        Part:getAttributes

describe("Part:getAttributes", function()
    it("returns empty table when no attributes set", function()
        local p = doll.newPart()
        local attrs = p:getAttributes()
        expect_equal(0, #p:getAttributeKeys())
        -- attrs table exists but is empty
        local count = 0
        for _ in pairs(attrs) do count = count + 1 end
        expect_equal(0, count)
    end)

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

--        doll.getAbsoluteScale (module function)

describe("doll.getAbsoluteScale", function()
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

--        Socket rotation transforms

describe("Socket rotation transforms", function()
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

--        Flip behaviour

describe("Flip behaviour", function()
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
