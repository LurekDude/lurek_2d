--- Luna2D quest system — tracking, objectives, and branching completion.
--
-- Stub module. Full implementation pending.
-- Replaces the former `luna.quest` Rust binding.
--
-- @module library.quest
-- @status stub

local M = {}

--- Create a new quest.
-- @param id string Unique quest identifier.
-- @param def table Quest definition: { title, description, objectives={} }
-- @treturn table Quest object.
function M.newQuest(id, def)
    error("library.quest: not yet implemented — stub only")
end

--- Create a new quest log to track active and completed quests.
-- @treturn table QuestLog object.
function M.newLog()
    error("library.quest: not yet implemented — stub only")
end

return M
