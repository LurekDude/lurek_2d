-- Integration: save manager snapshots serialized and sent as network packets
describe("network + save integration", function()
    -- @integration LSaveManager:collect
    -- @integration LSaveManager:register
    -- @integration lurek.network.pack
    -- @integration lurek.network.unpack
    -- @integration lurek.save.newSaveManager
    it("serialises a collected save snapshot to network packet format", function()
        local sm = lurek.save.newSaveManager()

        sm:register("player", function()
            return {
                hp = 87,
                pos = { x = 12, y = 34 },
                tags = { "ready", "coop" },
            }
        end, function() end)

        local snapshot = sm:collect()
        local packet = lurek.network.pack(snapshot)
        local unpacked = lurek.network.unpack(packet)
        local player = unpacked and unpacked.player or nil
        local pos = player and player.pos or nil
        local tags = player and player.tags or nil

        expect_type("string", packet)
        expect_type("table", unpacked)
        expect_type("table", player)
        expect_type("table", pos)
        expect_type("table", tags)
        expect_equal(87, player and player.hp or nil)
        expect_equal(12, pos and pos.x or nil)
        expect_equal(34, pos and pos.y or nil)
        expect_equal("ready", tags and tags[1] or nil)
        expect_equal("coop", tags and tags[2] or nil)
    end)

    -- @integration LSaveManager:collect
    -- @integration LSaveManager:register
    -- @integration LSaveManager:restore
    -- @integration lurek.network.pack
    -- @integration lurek.network.unpack
    -- @integration lurek.save.newSaveManager
    it("deserialises an incoming packet back into save manager state", function()
        local source = lurek.save.newSaveManager()
        local target = lurek.save.newSaveManager()
        local restored_hp = nil
        local restored_name = nil

        source:register("player", function()
            return { hp = 41, name = "Mira" }
        end, function() end)

        target:register("player", function()
            return {}
        end, function(data)
            restored_hp = data.hp
            restored_name = data.name
        end)

        local packet = lurek.network.pack(source:collect())
        local incoming_snapshot = lurek.network.unpack(packet)
        local incoming_table = type(incoming_snapshot) == "table" and incoming_snapshot or {}
        target:restore(incoming_table)

        expect_equal(41, restored_hp)
        expect_equal("Mira", restored_name)
    end)

    -- @integration lurek.network.unpack
    it("rejects malformed network save payloads", function()
        expect_error(function()
            lurek.network.unpack("not valid msgpack \xff\xfe")
        end)
    end)
end)
test_summary()

