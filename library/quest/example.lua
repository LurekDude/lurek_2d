--- Example usage for library.quest.
-- Run with: lua content/library/quest/example.lua
-- Demonstrates a 2-stage quest with objective progress, journal
-- entries, status transitions, and an event-bus observer that watches
-- lifecycle events. Optional JSON round-trip via lurek.serial is
-- exercised when available.
-- @module example.quest

local M = require("library.quest")

-- ── 1. Mock event bus (matches the lurek.patterns.newEventBus contract) ───────
-- The quest module only requires :emit(event_name, data); a tiny stub is
-- enough so this example runs in any plain Lua VM.
local function new_event_bus()
    local bus = { _subs = {}, log = {} }
    function bus:on(event, fn)
        self._subs[event] = self._subs[event] or {}
        table.insert(self._subs[event], fn)
    end
    function bus:emit(event, data)
        self.log[#self.log + 1] = event
        for _, fn in ipairs(self._subs[event] or {}) do fn(data) end
    end
    return bus
end

local bus = new_event_bus()
bus:on("quest_started",   function(d) print(string.format("[example.quest] (bus) STARTED   id=%s", d.id)) end)
bus:on("quest_advanced",  function(d) print(string.format("[example.quest] (bus) ADVANCED  id=%s obj=%s amount=%d",
    d.id, d.objective, d.amount or 0)) end)
bus:on("quest_completed", function(d) print(string.format("[example.quest] (bus) COMPLETED id=%s", d.id)) end)

-- ── 2. Build a 2-stage rescue quest ───────────────────────────────────────────
local stage1 = M.newQuestStage("travel", "Travel to the Cave")
stage1:addObjective(M.newObjective("walk", "Walk to the cave entrance", 3))
stage1:addObjective(M.newObjective("scout", "Scout the area", 1))

local stage2 = M.newQuestStage("rescue", "Rescue the Prisoner")
stage2:addObjective(M.newObjective("free_npc", "Free the prisoner", 1))

local quest = M.newQuest("rescue_q", "The Caverns of Doom", 16)
quest:addStage(stage1)
quest:addStage(stage2)
quest:setMeta("xp_reward", 250)

print(string.format("[example.quest] quest '%s' has %d stages",
    quest.title, #quest.stages))

-- ── 3. Add to a quest log and attach the bus ──────────────────────────────────
local log = M.newQuestLog()
log:addQuest(quest)
log:setEventBus(bus)
print(string.format("[example.quest] log has %d quests, %d active",
    log:questCount(), log:activeCount()))

-- ── 4. Start the quest and advance objectives ─────────────────────────────────
log:startQuest("rescue_q")
quest:addJournalEntry("Set out for the cave at dawn.", "travel")

log:advanceObjective("rescue_q", "walk", 1)
log:advanceObjective("rescue_q", "walk", 2)
log:advanceObjective("rescue_q", "scout", 1)

print(string.format("[example.quest] stage 1 complete? %s percent=%.1f%%",
    tostring(quest:getStage("travel"):isComplete()),
    quest:completionPercent() * 100))

-- ── 5. Move to stage 2 and finish ─────────────────────────────────────────────
quest:nextStage()
print(string.format("[example.quest] now on stage '%s'", quest:getCurrentStage().name))

log:advanceObjective("rescue_q", "free_npc", 1)
log:completeQuest("rescue_q")

print(string.format("[example.quest] active=%d completed=%d failed=%d",
    log:activeCount(), log:completedCount(), #log:failedIds()))
print(string.format("[example.quest] bus event sequence: %s",
    table.concat(bus.log, ",")))

-- ── 6. Optional JSON round-trip via lurek.serial (guarded) ─────────────────────
local lurek_ok = pcall(function() return lurek and lurek.serial end)
if lurek_ok and lurek and lurek.serial and lurek.serial.toJson then
    local s = M.toJson(log)
    local back = M.fromJson(s)
    print(string.format("[example.quest] JSON round-trip len=%d quests_back=%d",
        #s, back and #(back.quests or {}) or 0))
else
    print("[example.quest] lurek.serial unavailable; skipped JSON round-trip")
end

print("[example.quest] done.")
