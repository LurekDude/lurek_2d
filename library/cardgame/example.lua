--- Example usage for library.cardgame.
-- Run from project root with: lua content/library/cardgame/example.lua
-- @module example.cardgame

package.path = "content/?.lua;content/?/init.lua;" .. package.path
local cardgame = require("library.cardgame")

math.randomseed(7)
cardgame.resetIdCounter()

print("[example.cardgame] === Scenario 1: define card types and instantiate ===")

cardgame.defineCardType("goblin", {
    name = "Goblin Scout", category = "creature", subtype = "goblin",
    rarity = "common",
    base_stats = { attack = 2, health = 3, cost = 1 },
    base_tags  = { "creature", "goblin" },
})
cardgame.defineCardType("fireball", {
    name = "Fireball", category = "spell", rarity = "uncommon",
    base_stats = { damage = 6, cost = 4 },
    base_tags  = { "spell", "fire" },
})

local g = cardgame.newCard("goblin")
local f = cardgame.newCard("fireball")
print(string.format("  %s id=%d cost=%d, %s damage=%d",
    g.name, g.id, g:getStat("cost"),
    f.name, f:getStat("damage")))

print("[example.cardgame] === Scenario 2: deck (Stack), shuffle, draw ===")

local deck = cardgame.newStack("deck")
for i = 1, 6 do deck:pushTop(cardgame.newCard("goblin")) end
for i = 1, 4 do deck:pushTop(cardgame.newCard("fireball")) end
deck:shuffle()
print(string.format("  deck size before draws: %d", deck:size()))

local hand = cardgame.newStackWithCapacity("hand", 5)
for _ = 1, 5 do
    local card = deck:popTop()
    if card then hand:pushTop(card) end
end
print(string.format("  drew %d cards, deck=%d, hand full=%s",
    hand:size(), deck:size(), tostring(hand:isFull())))

print("[example.cardgame] === Scenario 3: search by tag / category ===")

local fire_indices = hand:searchByTag("fire")
print(string.format("  fire-tagged cards in hand: %d", #fire_indices))
for _, i in ipairs(fire_indices) do
    print(string.format("    [%d] %s", i, hand:peekAt(i).name))
end

print("[example.cardgame] === Scenario 4: counters & tap state ===")

local creature = hand:peekTop()
creature:setCounter("damage", 1)
creature:addCounter("damage", 1)
creature.tapped = true
print(string.format("  %s damage counters=%d tapped=%s",
    creature.name, creature:getCounter("damage"), tostring(creature.tapped)))

print("[example.cardgame] === Scenario 5: sort hand by category ===")

hand:sortByCategory()
local order = {}
for i = 1, hand:size() do order[#order+1] = hand:peekAt(i).category end
print("  hand by category: " .. table.concat(order, ", "))

print("[example.cardgame] === Scenario 6: serialise card snapshot ===")

local ok_codec, codec = pcall(require, "lurek.serial")
if ok_codec and codec and codec.toJson then
    local snap = { type = creature.card_type, name = creature.name, stats = creature.stats }
    print("  codec.toJson: " .. codec.toJson(snap))
else
    -- Pure-Lua fallback: minimal printable summary.
    print(string.format("  no lurek.serial — snapshot summary: type=%s atk=%d hp=%d",
        creature.card_type, creature:getStat("attack"), creature:getStat("health")))
end

print("[example.cardgame] done.")
