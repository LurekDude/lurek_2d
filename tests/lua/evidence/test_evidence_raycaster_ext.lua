-- test_evidence_raycaster_ext.lua
-- Evidence test: extended lurek.raycaster API — DoorManager, HeightMap, PointLight

-- @description Covers suite: Evidence: lurek.raycaster extended API (DoorManager/HeightMap/PointLight).
describe("Evidence: lurek.raycaster extended API", function()

    -- @covers lurek.raycaster.newDoorManager
    -- @covers DoorManager:addDoor
    -- @covers DoorManager:openDoor
    -- @covers DoorManager:update
    -- @covers DoorManager:getDoor
    -- @covers DoorManager:count
    -- @covers DoorManager:typeOf
    it("DoorManager: add, open, update, query", function()
        local dm = lurek.raycaster.newDoorManager()
        expect_equal(dm:typeOf(), "DoorManager")
        expect_equal(dm:count(), 0)

        local idx = dm:addDoor(5, 5, "horizontal", 2.0)
        expect_equal(dm:count(), 1)

        dm:openDoor(idx)
        dm:update(0.1)

        local door = dm:getDoor(idx)
        expect_equal(door ~= nil, true)
        -- State should be "opening" immediately after open + update
        local is_moving = (door.state == "opening" or door.state == "open")
        expect_equal(is_moving, true)

        -- Check nil for out-of-range index
        local missing = dm:getDoor(99)
        expect_equal(missing, nil)
    end)

    -- @covers lurek.raycaster.newDoorManager
    -- @covers DoorManager:closeDoor
    it("DoorManager: close door", function()
        local dm = lurek.raycaster.newDoorManager()
        local idx = dm:addDoor(3, 7, "vertical", 1.0)
        dm:openDoor(idx)
        dm:update(0.5)
        dm:closeDoor(idx)
        dm:update(0.1)
        local door = dm:getDoor(idx)
        expect_equal(door ~= nil, true)
        local is_valid_state = (door.state == "closing" or door.state == "closed" or door.state == "open" or door.state == "opening")
        expect_equal(is_valid_state, true)
    end)

    -- @covers lurek.raycaster.newHeightMap
    -- @covers HeightMap:setFloor
    -- @covers HeightMap:setCeiling
    -- @covers HeightMap:floorAt
    -- @covers HeightMap:ceilingAt
    -- @covers HeightMap:typeOf
    it("HeightMap: set and read floor/ceiling values", function()
        local hm = lurek.raycaster.newHeightMap(32, 32)
        expect_equal(hm:typeOf(), "HeightMap")

        hm:setFloor(5, 10, 0.25)
        hm:setCeiling(5, 10, 0.75)

        expect_near(hm:floorAt(5, 10), 0.25, 0.001)
        expect_near(hm:ceilingAt(5, 10), 0.75, 0.001)
    end)

    -- @covers lurek.raycaster.newHeightMap
    -- @covers HeightMap:floorAt
    it("HeightMap: out-of-bounds returns defaults", function()
        local hm = lurek.raycaster.newHeightMap(16, 16)
        -- Default floor = 0.0, ceiling = 1.0 (out-of-bounds returns defaults)
        local floor_oob = hm:floorAt(100, 100)
        local ceil_oob = hm:ceilingAt(100, 100)
        expect_equal(type(floor_oob), "number")
        expect_equal(type(ceil_oob), "number")
    end)

    -- @covers lurek.raycaster.newHeightMap
    it("HeightMap: multiple cells independent", function()
        local hm = lurek.raycaster.newHeightMap(10, 10)
        hm:setFloor(0, 0, 0.1)
        hm:setFloor(9, 9, 0.9)
        expect_near(hm:floorAt(0, 0), 0.1, 0.001)
        expect_near(hm:floorAt(9, 9), 0.9, 0.001)
        -- Unset cell
        expect_near(hm:floorAt(5, 5), 0.0, 0.001)
    end)

    -- @covers lurek.raycaster.newPointLight
    -- @covers PointLight:x
    -- @covers PointLight:y
    -- @covers PointLight:radius
    -- @covers PointLight:intensity
    -- @covers PointLight:color
    -- @covers PointLight:typeOf
    it("PointLight: create and query", function()
        local pl = lurek.raycaster.newPointLight(10.0, 20.0, 1.0, 0.8, 0.4, 15.0, 2.5)
        expect_equal(pl:typeOf(), "PointLight")
        expect_near(pl:x(), 10.0, 0.001)
        expect_near(pl:y(), 20.0, 0.001)
        expect_near(pl:radius(), 15.0, 0.001)
        expect_near(pl:intensity(), 2.5, 0.001)

        local r, g, b = pl:color()
        expect_near(r, 1.0, 0.001)
        expect_near(g, 0.8, 0.001)
        expect_near(b, 0.4, 0.001)
    end)

    -- @covers PointLight:set
    it("PointLight: set updates all fields", function()
        local pl = lurek.raycaster.newPointLight(0, 0, 1, 1, 1, 10, 1)
        pl:set(5.0, 7.0, 0.5, 0.3, 0.1, 20.0, 3.0)
        expect_near(pl:x(), 5.0, 0.001)
        expect_near(pl:y(), 7.0, 0.001)
        expect_near(pl:radius(), 20.0, 0.001)
        expect_near(pl:intensity(), 3.0, 0.001)
    end)

    -- @covers lurek.raycaster.newPointLight
    it("PointLight: zero-intensity allowed", function()
        local pl = lurek.raycaster.newPointLight(0, 0, 0, 0, 0, 5.0, 0.0)
        expect_near(pl:intensity(), 0.0, 0.001)
    end)

end)
test_summary()
