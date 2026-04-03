--- Luna2D card game system — cards, stacks, deck building, and slots.
--
-- Stub module. Full implementation pending.
-- Replaces the former `luna.cardgame` Rust binding.
--
-- @module library.cardgame
-- @status stub

local M = {}

--- Create a new card definition registry.
-- @treturn table CardRegistry object.
function M.newRegistry()
    error("library.cardgame: not yet implemented — stub only")
end

--- Create a new card deck.
-- @param opts table { shuffle=true }
-- @treturn table Deck object.
function M.newDeck(opts)
    error("library.cardgame: not yet implemented — stub only")
end

--- Create a card zone (board slot that holds one or more cards).
-- @param name string Zone identifier.
-- @param capacity number Maximum cards. 0 = unlimited.
-- @treturn table Zone object.
function M.newZone(name, capacity)
    error("library.cardgame: not yet implemented — stub only")
end

return M
