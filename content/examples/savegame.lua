-- examples/savegame.lua
-- lurek.savegame — Slot-based persistent save-file manager with schema
-- versioning, automatic migration, dirty-tracking, and auto-save.

-- ── SaveManager ───────────────────────────────────────────────────────────────

-- newSaveManager() → SaveManager
-- Each game creates one manager instance and registers collector/restorer pairs.
local save = lurek.savegame.newSaveManager()

-- ── Schema Versioning ─────────────────────────────────────────────────────────

-- setSchemaVersion(version)  — set the current version number for new saves
save:setSchemaVersion(3)

-- getSchemaVersion() → integer
local ver = save:getSchemaVersion()  -- 3

-- addMigration(fromVersion, fn)
-- Called when loading a save whose version < current.
save:addMigration(1, function(data)
    -- upgrade from v1 → v2: rename "gold" → "coins"
    if data.player then
        data.player.coins = data.player.gold
        data.player.gold = nil
    end
    return data
end)

save:addMigration(2, function(data)
    -- upgrade v2 → v3: add stamina field
    if data.player then
        data.player.stamina = data.player.stamina or 100
    end
    return data
end)

-- ── Registering Collectors and Restorers ──────────────────────────────────────

-- register(name, collectFn, restoreFn)
-- collectFn: called on save — return a table of state you want to persist
-- restoreFn: called on load — receives the saved table, restore your state

local player = { x=100, y=200, hp=80, mana=50, coins=320, stamina=100 }

save:register("player",
    function()  -- collector
        return {
            x      = player.x,
            y      = player.y,
            hp     = player.hp,
            mana   = player.mana,
            coins  = player.coins,
            stamina = player.stamina,
        }
    end,
    function(data)  -- restorer
        player.x       = data.x       or 0
        player.y       = data.y       or 0
        player.hp      = data.hp      or 100
        player.mana    = data.mana    or 100
        player.coins   = data.coins   or 0
        player.stamina = data.stamina or 100
    end
)

local world = { level = 1, dungeon = "forest", enemies_killed = 0 }

save:register("world",
    function()
        return { level = world.level, dungeon = world.dungeon,
                 enemies_killed = world.enemies_killed }
    end,
    function(data)
        world.level          = data.level          or 1
        world.dungeon        = data.dungeon        or "overworld"
        world.enemies_killed = data.enemies_killed or 0
    end
)

-- unregister(name) — remove a module's callbacks
save:unregister("world")

-- ── Dirty Tracking ────────────────────────────────────────────────────────────

-- isDirty() → boolean  — true when data has changed since last save/load
local dirty = save:isDirty()

-- markDirty() — manually flag data as changed (call after player action)
save:markDirty()

-- ── Summary ───────────────────────────────────────────────────────────────────

-- setSummary(str) — a short human-readable description shown on save-select screens
save:setSummary("Chapter 2 — The Forgotten Forest (Level " .. world.level .. ")")

-- getSummary() → string
local summary = save:getSummary()

-- ── Manual Save / Load ────────────────────────────────────────────────────────

-- save(slot) — call collectors → write JSON to disk under the slot name
save:save("slot1")          -- writes to save directory as "slot1.sav" (or similar)
save:save("quicksave")

-- load(slot) → success: boolean, message: string?
local ok, err = save:load("slot1")
if not ok then
    -- err contains an error message (e.g. "file not found" or "migration failed")
end

-- exists(slot) → boolean
if save:exists("slot1") then
    save:load("slot1")
end

-- delete(slot) — remove a save file
save:delete("oldslot")

-- getSlots() → table  — list of all available slot names with metadata
local slots = save:getSlots()
for _, info in ipairs(slots) do
    -- info.slot : string  — slot name
    -- info.timestamp : number — Unix timestamp
    -- info.version : integer — schema version at save time
    -- info.summary : string
end

-- getSlotInfo(slot) → table?  — metadata for a single slot
local info = save:getSlotInfo("slot1")
if info then
    -- info.timestamp, info.version, info.summary
end

-- ── Manual Collect / Restore (serialisation API) ─────────────────────────────

-- collect() → table  — run all collectors, return the raw state table
local raw = save:collect()
-- raw["player"] = { x=100, y=200, ... }
-- raw["world"]  = { level=1, ... }

-- restore(table) — run all restorers from a raw state table
save:restore(raw)

-- reset() — remove ALL registered callbacks and clear state
save:reset()

-- ── Auto-Save ─────────────────────────────────────────────────────────────────

-- enableAutoSave(intervalSeconds, slotName)
save:enableAutoSave(300, "autosave")   -- save to "autosave" every 5 minutes

-- disableAutoSave()
save:disableAutoSave()

-- update(dt) → slotName?
-- Call this every frame; returns slot name when an auto-save fires, else nil.
--[[
function lurek.process(dt)
    local auto_slot = save:update(dt)
    if auto_slot then
        -- auto-save fired; you can show "Saving..." UI here
    end
end
]]

-- ── Full Workflow Example ─────────────────────────────────────────────────────

--[[
local save_mgr

function lurek.init()
    save_mgr = lurek.savegame.newSaveManager()
    save_mgr:setSchemaVersion(1)
    save_mgr:setSummary("New Game")
    save_mgr:register("game",
        function() return { score = score, level = level } end,
        function(d) score = d.score or 0; level = d.level or 1 end
    )
    save_mgr:enableAutoSave(60, "autosave")   -- auto-save every minute

    if save_mgr:exists("slot1") then
        save_mgr:load("slot1")
    end
end

function lurek.process(dt)
    save_mgr:update(dt)
end

function lurek.keypressed(key)
    if key == "f5" then save_mgr:save("quicksave") end
    if key == "f9" then save_mgr:load("quicksave") end
end
]]
