--- Lurek2D quest system — objectives, stages, journal, and quest log.
--
-- A pure-Lua replacement for the former `lurek.quest` Rust binding.
-- No engine dependencies; works in headless test VMs.
-- Optional: uses `lurek.log.debug()` / `lurek.log.info()` when available for
-- quest state-change tracing.
--
-- **Quest lifecycle states and valid transitions**:
--
--  available → active  (via Quest:start)
--  active    → completed (via Quest:complete)
--  active    → failed    (via Quest:fail)
--
-- All other transitions are rejected and return false.
--
-- Usage:
--   local quest = require("library.quest")
--   local log = quest.newQuestLog()
--   local q = quest.newQuest("tutorial", "Tutorial Quest")
--   q.description = "Learn the basics"
--   local stage = quest.newQuestStage("s1", "First Steps")
--   local obj = quest.newObjective("talk_npc", "Talk to the guide", 1)
--   stage:addObjective(obj)
--   q:addStage(stage)
--   log:addQuest(q)
--   log:startQuest("tutorial")
--   log:advanceObjective("tutorial", "talk_npc", 1)
--
-- @module library.quest

local M = {}

-- ─── Optional logging (safe in headless tests where lurek may not exist) ──────
local _log
pcall(function()
    _log = lurek and lurek.log
end)
local function log_debug(msg)
    if _log and _log.debug then _log.debug("[quest] " .. msg) end
end
local function log_info(msg)
    if _log and _log.info then _log.info("[quest] " .. msg) end
end
local function log_warn(msg)
    if _log and _log.warn then _log.warn("[quest] " .. msg) end
end

-- ─── Objective ────────────────────────────────────────────────────────────────

local Objective = {}
Objective.__index = Objective

--- Create a new objective with 0/required progress.
-- @tparam string id Unique identifier within the parent quest.
-- @tparam string description Human-readable display text.
-- @tparam number required Required count to mark as done.
-- @treturn Objective
function M.newObjective(id, description, required)
    assert(type(id) == "string", "id must be a string")
    assert(type(description) == "string", "description must be a string")
    assert(type(required) == "number" and required >= 0, "required must be a non-negative number")
    local self = setmetatable({}, Objective)
    self.id = id
    self.description = description
    self.current = 0
    self.required = required
    self.mandatory = true
    self.status = "pending"
    self.tags = {}
    self.visible = true
    return self
end

--- Advance progress by amount. Automatically marks the objective as "done"
-- when current >= required. Does nothing if already done or failed.
-- @tparam number amount Amount to advance (default 1). Must be positive.
-- @treturn number New progress value.
function Objective:advance(amount)
    amount = amount or 1
    assert(type(amount) == "number" and amount > 0, "amount must be a positive number")
    if self.status == "done" or self.status == "failed" then
        return self.current
    end
    self.current = math.min(self.current + amount, self.required)
    if self.current >= self.required then
        self.status = "done"
        log_debug("objective '" .. self.id .. "' completed")
    else
        self.status = "active"
    end
    return self.current
end

--- Set progress directly. Clamps to [0, required].
-- @tparam number value New progress value.
function Objective:setProgress(value)
    assert(type(value) == "number", "value must be a number")
    self.current = math.min(math.max(value, 0), self.required)
    if self.current >= self.required then
        self.status = "done"
    elseif self.current > 0 then
        self.status = "active"
    else
        self.status = "pending"
    end
end

--- Returns true if this objective is considered complete (done or skipped).
-- @treturn boolean
function Objective:isComplete()
    return self.status == "done" or self.status == "skipped"
end

--- Add a tag. Has no effect if already present.
-- @tparam string tag Tag to add.
function Objective:addTag(tag)
    for _, t in ipairs(self.tags) do
        if t == tag then return end
    end
    table.insert(self.tags, tag)
end

--- Returns true if the given tag is present.
-- @tparam string tag Tag to check.
-- @treturn boolean
function Objective:hasTag(tag)
    for _, t in ipairs(self.tags) do
        if t == tag then return true end
    end
    return false
end

-- ─── QuestStage ───────────────────────────────────────────────────────────────

local QuestStage = {}
QuestStage.__index = QuestStage

--- Create a new empty quest stage.
-- @tparam string id Unique stage identifier.
-- @tparam string name Display name for this stage.
-- @treturn QuestStage
function M.newQuestStage(id, name)
    assert(type(id) == "string", "id must be a string")
    assert(type(name) == "string", "name must be a string")
    local self = setmetatable({}, QuestStage)
    self.id = id
    self.name = name
    self.objectives = {}
    return self
end

--- Add an objective to this stage.
-- @tparam Objective obj Objective to add.
function QuestStage:addObjective(obj)
    table.insert(self.objectives, obj)
end

--- Get an objective by id.
-- @tparam string id Objective id to find.
-- @treturn Objective|nil
function QuestStage:getObjective(id)
    for _, obj in ipairs(self.objectives) do
        if obj.id == id then return obj end
    end
    return nil
end

--- Get all objectives in this stage.
-- @treturn table Array of Objective objects.
function QuestStage:getObjectives()
    return self.objectives
end

--- Return the number of objectives in this stage.
-- @treturn number
function QuestStage:objectiveCount()
    return #self.objectives
end

--- Remove all objectives from this stage.
function QuestStage:clearObjectives()
    self.objectives = {}
end

--- Returns true if this stage contains an objective with the given id.
-- @tparam string id Objective id to check.
-- @treturn boolean
function QuestStage:hasObjective(id)
    return self:getObjective(id) ~= nil
end

--- Returns true when all mandatory objectives in this stage are complete.
-- @treturn boolean
function QuestStage:isComplete()
    for _, obj in ipairs(self.objectives) do
        if obj.mandatory and not obj:isComplete() then
            return false
        end
    end
    return true
end

-- ─── Quest ────────────────────────────────────────────────────────────────────

local Quest = {}
Quest.__index = Quest

--- Create a new quest in the "available" state.
--
-- Valid status transitions: available → active → completed | failed.
-- @tparam string id Unique identifier (non-empty).
-- @tparam string title Display title (non-empty).
-- @tparam[opt] number max_journal_entries Maximum journal entries to keep. nil = unlimited.
-- @treturn Quest
function M.newQuest(id, title, max_journal_entries)
    assert(type(id) == "string" and #id > 0, "id must be a non-empty string")
    assert(type(title) == "string" and #title > 0, "title must be a non-empty string")
    if max_journal_entries ~= nil then
        assert(type(max_journal_entries) == "number" and max_journal_entries >= 1,
               "max_journal_entries must be a positive integer or nil")
    end
    local self = setmetatable({}, Quest)
    self.id = id
    self.title = title
    self.description = ""
    self.status = "available"
    self.stages = {}
    self.current_stage = 1
    self.journal = {}
    self.metadata = {}
    self.visible = true
    self.reward = ""
    self._journal_counter = 0
    self._max_journal = max_journal_entries
    return self
end

--- Add a stage to the quest (in order).
-- @tparam QuestStage stage Stage to add.
function Quest:addStage(stage)
    table.insert(self.stages, stage)
end

--- Get the currently active stage, if any.
-- @treturn QuestStage|nil
function Quest:getCurrentStage()
    return self.stages[self.current_stage]
end

--- Get a stage by id.
-- @tparam string id Stage id to find.
-- @treturn QuestStage|nil
function Quest:getStage(id)
    for _, stage in ipairs(self.stages) do
        if stage.id == id then return stage end
    end
    return nil
end

--- Advance to the next stage. Returns true on success, false if already at last stage.
-- @treturn boolean
function Quest:nextStage()
    if self.current_stage < #self.stages then
        self.current_stage = self.current_stage + 1
        log_debug("quest '" .. self.id .. "' advanced to stage " .. self.current_stage)
        return true
    end
    return false
end

--- Jump to the stage with the given id. Returns false if not found.
-- @tparam string id Stage id to jump to.
-- @treturn boolean
function Quest:gotoStage(id)
    for i, stage in ipairs(self.stages) do
        if stage.id == id then
            self.current_stage = i
            return true
        end
    end
    return false
end

--- Advance progress on an objective in the current stage (or a specific stage).
-- Returns false if objective not found in the target stage.
-- @tparam string obj_id Objective id.
-- @tparam[opt=1] number amount Amount to advance (default 1).
-- @tparam[opt] string stage_id If provided, search this stage instead of the current one.
-- @treturn boolean
function Quest:advanceObjective(obj_id, amount, stage_id)
    amount = amount or 1
    assert(type(obj_id) == "string" and #obj_id > 0, "obj_id must be a non-empty string")
    local stage
    if stage_id then
        assert(type(stage_id) == "string", "stage_id must be a string")
        stage = self:getStage(stage_id)
    else
        stage = self:getCurrentStage()
    end
    if not stage then return false end
    local obj = stage:getObjective(obj_id)
    if obj then
        obj:advance(amount)
        return true
    end
    return false
end

--- Set status of an objective across all stages. Returns false if not found.
-- @tparam string obj_id Objective id.
-- @tparam string status New status ("pending", "active", "done", "skipped", "failed").
-- @treturn boolean
function Quest:setObjectiveStatus(obj_id, status)
    for _, stage in ipairs(self.stages) do
        local obj = stage:getObjective(obj_id)
        if obj then
            obj.status = status
            return true
        end
    end
    return false
end

--- Start the quest (transition from "available" to "active").
-- @treturn boolean true if the transition was valid.
function Quest:start()
    if self.status ~= "available" then
        log_warn("cannot start quest '" .. self.id .. "' from status '" .. self.status .. "'")
        return false
    end
    self.status = "active"
    log_info("quest '" .. self.id .. "' started")
    return true
end

--- Mark the quest as completed (transition from "active" to "completed").
-- @treturn boolean true if the transition was valid.
function Quest:complete()
    if self.status ~= "active" then
        log_warn("cannot complete quest '" .. self.id .. "' from status '" .. self.status .. "'")
        return false
    end
    self.status = "completed"
    log_info("quest '" .. self.id .. "' completed")
    return true
end

--- Mark the quest as failed (transition from "active" to "failed").
-- @treturn boolean true if the transition was valid.
function Quest:fail()
    if self.status ~= "active" then
        log_warn("cannot fail quest '" .. self.id .. "' from status '" .. self.status .. "'")
        return false
    end
    self.status = "failed"
    log_info("quest '" .. self.id .. "' failed")
    return true
end

--- Append a journal entry. Returns the entry's index.
-- If `max_journal_entries` was set on the quest, the oldest entries are
-- removed to stay within the limit.
-- @tparam string text Journal text body.
-- @tparam[opt=""] string tag Optional tag.
-- @treturn number Entry index.
function Quest:addJournalEntry(text, tag)
    assert(type(text) == "string", "text must be a string")
    tag = tag or ""
    local idx = self._journal_counter
    table.insert(self.journal, {
        index = idx,
        text = text,
        tag = tag,
    })
    self._journal_counter = self._journal_counter + 1
    -- Purge oldest entries if a cap is configured.
    if self._max_journal and #self.journal > self._max_journal then
        while #self.journal > self._max_journal do
            table.remove(self.journal, 1)
        end
        log_debug("journal trimmed for quest '" .. self.id .. "' (max " .. self._max_journal .. ")")
    end
    return idx
end

--- Set a metadata key-value pair.
-- @tparam string key Metadata key.
-- @tparam string value Metadata value.
function Quest:setMeta(key, value)
    self.metadata[key] = value
end

--- Get a metadata value by key.
-- @tparam string key Metadata key.
-- @treturn string|nil
function Quest:getMeta(key)
    return self.metadata[key]
end

--- Returns percentage of mandatory objectives that are Done across all stages (0.0-100.0).
-- Returns 0.0 when there are no mandatory objectives.
-- @treturn number Completion percent.
function Quest:completionPercent()
    local total = 0
    local done = 0
    for _, stage in ipairs(self.stages) do
        for _, obj in ipairs(stage.objectives) do
            if obj.mandatory then
                total = total + 1
                if obj.status == "done" then
                    done = done + 1
                end
            end
        end
    end
    if total == 0 then return 0.0 end
    return done / total * 100.0
end

--- Returns the IDs of all objectives currently "active" across all stages.
-- @treturn table Array of objective id strings.
function Quest:activeObjectiveIds()
    local result = {}
    for _, stage in ipairs(self.stages) do
        for _, obj in ipairs(stage.objectives) do
            if obj.status == "active" then
                table.insert(result, obj.id)
            end
        end
    end
    return result
end

--- Reset an objective back to "active" (in progress). Returns false if not found.
-- @tparam string id Objective id.
-- @treturn boolean
function Quest:resetObjective(id)
    for _, stage in ipairs(self.stages) do
        for _, obj in ipairs(stage.objectives) do
            if obj.id == id then
                obj.status = "active"
                return true
            end
        end
    end
    return false
end

--- Return true if every mandatory objective in the quest is complete.
-- @treturn boolean
function Quest:allObjectivesComplete()
    for _, stage in ipairs(self.stages) do
        if not stage:isComplete() then
            return false
        end
    end
    return true
end

-- ─── QuestLog ─────────────────────────────────────────────────────────────────

local QuestLog = {}
QuestLog.__index = QuestLog

--- Create an empty quest log.
-- @treturn QuestLog
function M.newQuestLog()
    local self = setmetatable({}, QuestLog)
    self._quests = {}
    self._order = {}
    return self
end

--- Register a quest. If a quest with the same id already exists, it is replaced.
-- @tparam Quest quest Quest to add.
function QuestLog:addQuest(quest)
    local id = quest.id
    if not self._quests[id] then
        table.insert(self._order, id)
    end
    self._quests[id] = quest
end

--- Get a quest by id.
-- @tparam string id Quest id.
-- @treturn Quest|nil
function QuestLog:getQuest(id)
    return self._quests[id]
end

--- Remove a quest by id. Returns true if removed, false if not found.
-- @tparam string id Quest id.
-- @treturn boolean
function QuestLog:removeQuest(id)
    if self._quests[id] then
        self._quests[id] = nil
        for i, oid in ipairs(self._order) do
            if oid == id then
                table.remove(self._order, i)
                break
            end
        end
        return true
    end
    return false
end

--- List ids of all quests in insertion order.
-- @treturn table Array of quest id strings.
function QuestLog:questIds()
    local copy = {}
    for _, id in ipairs(self._order) do
        table.insert(copy, id)
    end
    return copy
end

--- List ids of all quests with the given status.
-- @tparam string status Status to filter by.
-- @treturn table Array of quest id strings.
function QuestLog:questsWithStatus(status)
    local result = {}
    for _, id in ipairs(self._order) do
        local q = self._quests[id]
        if q and q.status == status then
            table.insert(result, id)
        end
    end
    return result
end

--- Total number of registered quests.
-- @treturn number
function QuestLog:questCount()
    local n = 0
    for _ in pairs(self._quests) do n = n + 1 end
    return n
end

--- Start quest by id (available -> active). Returns false if not found or invalid transition.
-- @tparam string id Quest id.
-- @treturn boolean
function QuestLog:startQuest(id)
    local q = self._quests[id]
    if q then
        return q:start()
    end
    return false
end

--- Complete quest by id (active -> completed). Returns false if not found or invalid transition.
-- @tparam string id Quest id.
-- @treturn boolean
function QuestLog:completeQuest(id)
    local q = self._quests[id]
    if q then
        return q:complete()
    end
    return false
end

--- Fail quest by id (active -> failed). Returns false if not found or invalid transition.
-- @tparam string id Quest id.
-- @treturn boolean
function QuestLog:failQuest(id)
    local q = self._quests[id]
    if q then
        return q:fail()
    end
    return false
end

--- IDs of all active quests.
-- @treturn table Array of quest id strings.
function QuestLog:activeIds()
    return self:questsWithStatus("active")
end

--- IDs of all completed quests.
-- @treturn table Array of quest id strings.
function QuestLog:completedIds()
    return self:questsWithStatus("completed")
end

--- IDs of all failed quests.
-- @treturn table Array of quest id strings.
function QuestLog:failedIds()
    return self:questsWithStatus("failed")
end

--- Advance an objective in a specific quest. Returns false if quest or objective not found.
-- @tparam string quest_id Quest id.
-- @tparam string obj_id Objective id.
-- @tparam[opt=1] number amount Amount to advance (default 1).
-- @tparam[opt] string stage_id If provided, advance in this stage instead of the current one.
-- @treturn boolean
function QuestLog:advanceObjective(quest_id, obj_id, amount, stage_id)
    amount = amount or 1
    local q = self._quests[quest_id]
    if q then
        return q:advanceObjective(obj_id, amount, stage_id)
    end
    return false
end

--- Reset a quest back to "available" with the first stage active and all objective
-- progress cleared to zero.
-- @tparam string id Quest id.
-- @treturn boolean true if the quest was found.
function QuestLog:resetQuest(id)
    local q = self._quests[id]
    if not q then return false end
    q.status        = "available"
    q.current_stage = 1
    for _, stage in ipairs(q.stages) do
        for _, obj in ipairs(stage.objectives or {}) do
            obj.status  = "pending"
            obj.current = 0
        end
    end
    return true
end

--- Set the reward description string on a quest.
-- @tparam string id     Quest id.
-- @tparam string reward Reward description.
function QuestLog:setQuestReward(id, reward)
    local q = self._quests[id]
    if q then q.reward = reward end
end

--- Get the reward description of a quest.
-- @tparam string id Quest id.
-- @treturn string  Reward description, or nil if quest not found.
function QuestLog:getQuestReward(id)
    local q = self._quests[id]
    return q and q.reward
end

--- Count active quests (status == "in_progress").
-- @treturn number
function QuestLog:activeCount()
    return #self:activeIds()
end

--- Count completed quests.
-- @treturn number
function QuestLog:completedCount()
    return #self:completedIds()
end


-- ═══════════════════════════════════════════════════════════════════════
-- PARITY ADDITIONS — Phase 2A  (quest)
-- ═══════════════════════════════════════════════════════════════════════

--- Quest lifecycle status enum.
-- @field LOCKED
-- @field ACTIVE
-- @field COMPLETED
-- @field FAILED
M.QuestStatus = {
    LOCKED    = "locked",
    ACTIVE    = "active",
    COMPLETED = "completed",
    FAILED    = "failed",
}

--- Objective completion-state enum.
-- @field LOCKED
-- @field ACTIVE
-- @field COMPLETED
-- @field FAILED
M.ObjectiveStatus = {
    LOCKED    = "locked",
    ACTIVE    = "active",
    COMPLETED = "completed",
    FAILED    = "failed",
}

--- Remove a tag from this objective. Returns true if the tag was present.
-- @param tag string
-- @treturn boolean
function Objective:removeTag(tag)
    if not self.tags then return false end
    for i, t in ipairs(self.tags) do
        if t == tag then table.remove(self.tags, i); return true end
    end
    return false
end

return M
