---@meta
--- Auto-generated Lunasome library API documentation for LuaCATS.

library = {}

---@class number
---@class string
---@class boolean
---@class table
---@class function
---@class thread
---@class userdata
---@class nil

---@class StatusEffect
StatusEffect = {}

---@class CombatAction
CombatAction = {}

---@class Combatant
Combatant = {}

---@class CombatBattle
CombatBattle = {}

---@class Card
Card = {}

---@class Stack
Stack = {}

---@class Slot
Slot = {}

---@class CardPool
CardPool = {}

---@class StackManager
StackManager = {}

---@class DeckBuilder
DeckBuilder = {}

---@class StackHistory
StackHistory = {}

---@class CardGroup
CardGroup = {}

---@class Track
Track = {}

---@class Timeline
Timeline = {}

---@class CollisionGroupSet
CollisionGroupSet = {}

---@class Chassis
Chassis = {}

---@class Turret
Turret = {}

---@class Weapon
Weapon = {}

---@class Projectile
Projectile = {}

---@class ProjectilePool
ProjectilePool = {}

---@class CombatWorld
CombatWorld = {}

---@class Ingredient
Ingredient = {}

---@class Recipe
Recipe = {}

---@class RecipeRegistry
RecipeRegistry = {}

---@class Station
Station = {}

---@class CraftSkill
CraftSkill = {}

---@class PerkNode
PerkNode = {}

---@class ModifierPool
ModifierPool = {}

---@class RecipeKnowledge
RecipeKnowledge = {}

---@class CraftJob
CraftJob = {}

---@class CraftQueue
CraftQueue = {}

---@class UpgradeNode
UpgradeNode = {}

---@class UpgradeTree
UpgradeTree = {}

---@class RecipeGroup
RecipeGroup = {}

---@class seq
seq = {}

---@class part
part = {}

---@class tmpl
tmpl = {}

---@class doll
doll = {}

---@class Resource
Resource = {}

---@class Modifier
Modifier = {}

---@class ConversionRule
ConversionRule = {}

---@class ResourceManager
ResourceManager = {}

---@class item
item = {}

---@class stack
stack = {}

---@class slot
slot = {}

---@class container
container = {}

---@class iset
iset = {}

---@class inv
inv = {}

---@class it
it = {}

---@class pool
pool = {}

---@class builder
builder = {}

---@class history
history = {}

---@class manager
manager = {}

---@class Room
Room = {}

---@class Lobby
Lobby = {}

---@class LootTable
LootTable = {}

---@class DropSet
DropSet = {}

---@class Pity
Pity = {}

---@class Story
Story = {}

---@class NetState
NetState = {}

---@class Province
Province = {}

---@class ProvinceMap
ProvinceMap = {}

---@class EventBus
EventBus = {}

---@class Objective
Objective = {}

---@class QuestStage
QuestStage = {}

---@class Quest
Quest = {}

---@class QuestLog
QuestLog = {}

---@class Clock
Clock = {}

---@class Fov
Fov = {}

---@class Scheduler
Scheduler = {}

---@class GoalMap
GoalMap = {}

---@class RPC
RPC = {}

---@class sched
sched = {}

---@class Buff
Buff = {}

---@class LevelThresholds
LevelThresholds = {}

---@class Sheet
Sheet = {}

---@class ActionPoints
ActionPoints = {}

---@class Attribute
Attribute = {}

---@class Doll
Doll = {}

---@class DollTemplate
DollTemplate = {}

---@class LCard
LCard = {}

---@class LCardStack
LCardStack = {}

---@class ModifierEntry
ModifierEntry = {}

---@class Morale
Morale = {}

---@class Part
Part = {}

---@class Perk
Perk = {}

---@class RecipeOutput
RecipeOutput = {}

---@class Skill
Skill = {}

---@class library.battle
library.battle = {}

--- Create a new status effect.
---@param name string
---@param duration number
---@return StatusEffect
function library.battle.newStatusEffect(name, duration) end

--- Get the effect name.
---@return string
function StatusEffect:getName() end

--- Get remaining duration (-1 = permanent).
---@return number
function StatusEffect:getDuration() end

--- Set remaining duration.
---@param v number
---@return nil
function StatusEffect:setDuration(v) end

--- Get current stack count.
---@return number
function StatusEffect:getStacks() end

--- Set stack count.
---@param v number
---@return nil
function StatusEffect:setStacks(v) end

--- Tick one turn. Returns true when the effect has just expired.
---@return boolean
function StatusEffect:tickTurn() end

--- Is the effect expired?
---@return boolean
function StatusEffect:isExpired() end

--- Create a new combat action.
---@param name string
---@return CombatAction
function library.battle.newAction(name) end

--- Get the action name.
---@return string
function CombatAction:getName() end

--- Get base damage value.
---@return number
function CombatAction:getBaseDamage() end

--- Set base damage value.
---@param v number
---@return nil
function CombatAction:setBaseDamage(v) end

--- Get damage type string.
---@return string
function CombatAction:getDamageType() end

--- Set damage type string (defaults to "physical").
---@param v string
---@return nil
function CombatAction:setDamageType(v) end

--- Get accuracy clamped to [0, 1].
---@return number
function CombatAction:getAccuracy() end

--- Set accuracy, clamped to [0, 1].
---@param v number
---@return nil
function CombatAction:setAccuracy(v) end

--- Get max cooldown turns.
---@return number
function CombatAction:getCooldown() end

--- Set max cooldown turns.
---@param v number
---@return nil
function CombatAction:setCooldown(v) end

--- Get current remaining cooldown turns.
---@return number
function CombatAction:getCurrentCooldown() end

--- Get HP cost to use this action.
---@return number
function CombatAction:getCostHp() end

--- Set HP cost.
---@param v number
---@return nil
function CombatAction:setCostHp(v) end

--- Get MP cost to use this action.
---@return number
function CombatAction:getCostMp() end

--- Set MP cost.
---@param v number
---@return nil
function CombatAction:setCostMp(v) end

--- Is the action off cooldown?
---@return boolean
function CombatAction:isReady() end

--- Put the action on cooldown.
---@return nil
function CombatAction:useAction() end

--- Tick cooldown by one.
---@return nil
function CombatAction:tickCooldown() end

--- Create a new combatant.
---@param name string
---@return Combatant
function library.battle.newCombatant(name) end

--- Get combatant name.
---@return string
function Combatant:getName() end

--- Get team identifier string.
---@return string
function Combatant:getTeam() end

--- Set team identifier (defaults to "player").
---@param v string
---@return nil
function Combatant:setTeam(v) end

--- Get current HP.
---@return number
function Combatant:getHp() end

--- Set current HP directly (use takeDamage/heal for safe HP changes).
---@param v number
---@return nil
function Combatant:setHp(v) end

--- Get maximum HP.
---@return number
function Combatant:getMaxHp() end

--- Set maximum HP.
---@param v number
---@return nil
function Combatant:setMaxHp(v) end

--- Get current MP.
---@return number
function Combatant:getMp() end

--- Set current MP.
---@param v number
---@return nil
function Combatant:setMp(v) end

--- Get maximum MP.
---@return number
function Combatant:getMaxMp() end

--- Set maximum MP.
---@param v number
---@return nil
function Combatant:setMaxMp(v) end

--- Get speed (used for initiative ordering; higher = sooner).
---@return number
function Combatant:getSpeed() end

--- Set speed.
---@param v number
---@return nil
function Combatant:setSpeed(v) end

--- Get combatant level.
---@return number
function Combatant:getLevel() end

--- Set combatant level.
---@param v number
---@return nil
function Combatant:setLevel(v) end

--- Is the combatant alive?
---@return boolean
function Combatant:isAlive() end

--- Apply damage, factoring in resistance. Resistance is a multiplier (default 1.0).
---@param amount number
---@param damage_type string
---@return number
function Combatant:takeDamage(amount, damage_type) end

--- Heal the combatant.
---@param amount number
---@return number
function Combatant:heal(amount) end

--- Add or stack a status effect.
---@param name string
---@param duration number
---@return nil
function Combatant:addStatus(name, duration) end

--- Remove a status effect by name.
---@param name string
---@return nil
function Combatant:removeStatus(name) end

--- Check if a status is active.
---@param name string
---@return boolean
function Combatant:hasStatus(name) end

--- Tick all status effects, removing expired ones.
---@return table
function Combatant:tickStatuses() end

--- Get array of {name, duration, stacks} tables.
---@return table
function Combatant:getStatuses() end

--- Get a named stat value (defaults to 0).
---@param name string
---@return number
function Combatant:getStat(name) end

--- Set a named stat.
---@param name string
---@param value number
---@return nil
function Combatant:setStat(name, value) end

--- Get damage resistance for a type (defaults to 1.0 = full damage).
---@param dtype string
---@return number
function Combatant:getResistance(dtype) end

--- Set damage resistance for a type.
---@param dtype string
---@param value number
---@return nil
function Combatant:setResistance(dtype, value) end

--- HP as a percentage (0-100).
---@return number
function Combatant:getHpPercent() end

--- MP as a percentage (0-100).
---@return number
function Combatant:getMpPercent() end

--- Add a combat action (deep clone of the action).
---@param action CombatAction
---@return nil
function Combatant:addAction(action) end

--- Get an action by name.
---@param name string
---@return CombatAction|nil
function Combatant:getAction(name) end

--- Check if the combatant has an action.
---@param name string
---@return boolean
function Combatant:hasAction(name) end

--- Tick all action cooldowns.
---@return nil
function Combatant:tickCooldowns() end

--- Get array of action names.
---@return table
function Combatant:getActionNames() end

--- Get array of status effect names.
---@return table
function Combatant:getStatusNames() end

--- Get metadata value.
---@param key string
---@return any|nil
function Combatant:getMeta(key) end

--- Set metadata value.
---@param key string
---@param value any
---@return nil
function Combatant:setMeta(key, value) end

--- Create a new battle.
---@param name string
---@return CombatBattle
function library.battle.newBattle(name) end

--- Get battle display name.
---@return string
function CombatBattle:getName() end

--- Get total number of combatants (alive and dead).
---@return number
function CombatBattle:getCount() end

--- Get total completed turn count.
---@return number
function CombatBattle:getTurnCount() end

--- Returns true when the battle has ended.
---@return boolean
function CombatBattle:isOver() end

--- Returns the winning team name, or nil if not yet over. When auto_detect is true, checks battle state before returning.
---@param auto_detect boolean
---@return string|nil
function CombatBattle:getWinner(auto_detect) end

--- Returns the battle log as an array of strings.
---@return table
function CombatBattle:getLog() end

--- Add a log entry.
---@param msg string
---@return nil
function CombatBattle:addToLog(msg) end

--- Add a combatant (deep clone).
---@param c Combatant
---@return nil
function CombatBattle:addCombatant(c) end

--- Get a combatant by name (returns reference inside battle).
---@param name string
---@return Combatant|nil
function CombatBattle:getCombatant(name) end

--- Sort combatants by speed (descending).
---@return nil
function CombatBattle:sortInitiative() end

--- Get the current alive combatant.
---@return Combatant|nil
function CombatBattle:getCurrentCombatant() end

--- Advance to next turn. Returns false if battle is over.
---@return boolean
function CombatBattle:nextTurn() end

--- Check if battle is over (one team or fewer alive).
---@return nil
function CombatBattle:_checkBattleOver() end

--- Resolve an attack. TODO(P4 lift): switch to lurek.math.newRng() for seedable, deterministic battle replays. Currently uses the global Lua RNG which makes saves non-deterministic across reloads.
---@param attacker_name string
---@param action_name string
---@param target_name string
---@return table|nil
function CombatBattle:attack(attacker_name, action_name, target_name) end

--- Get names of all alive combatants.
---@return table
function CombatBattle:getAliveNames() end

--- Get names of all combatants.
---@return table
function CombatBattle:getAllNames() end

--- Remove a combatant by name.
---@param name string
---@return boolean
function CombatBattle:removeCombatant(name) end

--- Force-end the battle with a specified winner.
---@param winner string
---@return nil
function CombatBattle:forceEnd(winner) end

--- Tick all combatant statuses.
---@return nil
function CombatBattle:tickAllStatuses() end

--- Tick all combatant action cooldowns.
---@return nil
function CombatBattle:tickAllActions() end

--- Resolve end-of-round bookkeeping: tick all statuses, tick all cooldowns, and check whether the battle has ended.
---@return boolean
function CombatBattle:resolve() end

--- Add a tag to this action (no-op if already present).
---@param tag string
---@return nil
function CombatAction:addTag(tag) end

--- Remove a tag. Returns true if it existed.
---@param tag string
---@return boolean
function CombatAction:removeTag(tag) end

--- Return true if the action has the given tag.
---@param tag string
---@return boolean
function CombatAction:hasTag(tag) end

--- Return a sorted list of all tags on this action.
---@return table
function CombatAction:getTags() end

--- Get a metadata value (string key -> any).
---@param key string
---@return any
function CombatAction:getMeta(key) end

--- Set a metadata value.
---@param key string
---@param val any
---@return nil
function CombatAction:setMeta(key, val) end

--- Get a metadata value from the status effect's data table.
---@param key string
---@return any
function StatusEffect:getMeta(key) end

--- Set a metadata value.
---@param key string
---@param val any
---@return nil
function StatusEffect:setMeta(key, val) end

--- Alias: getMetadata (matches Rust name).
---@param key string
---@return any
function StatusEffect:getMetadata(key) end

--- Alias: setMetadata (matches Rust name).
---@param key string
---@param val any
---@return nil
function StatusEffect:setMetadata(key, val) end

---@class library.cardgame
library.cardgame = {}

---@class library.cardgame.HistoryAction
library.cardgame.HistoryAction = {}

--- Return the current value of the internal ID counter (next ID to assign). Lua doubles are exact up to 2^53 (9007199254740992).
---@return number
function library.cardgame.getIdCounter() end

--- Reset the ID counter to 1.  Call between game sessions to reclaim the integer range.  Does NOT invalidate already-created cards � callers must ensure no stale references remain.
---@return nil
function library.cardgame.resetIdCounter() end

--- Register or overwrite a card type definition.
---@param name string
---@param def table
---@return nil
function library.cardgame.defineCardType(name, def) end

--- Look up a card type by name; returns nil if not found.
---@param name string
---@return table|nil
function library.cardgame.getCardType(name) end

--- Return a sorted list of all registered type names.
---@return table
function library.cardgame.getCardTypeNames() end

--- Clear all card type definitions from the module registry.
---@return nil
function library.cardgame.clearCardTypes() end

--- Create a new card type definition (blueprint). CardTypeDef fields:
---@param name string
---@return table
function library.cardgame.newCardTypeDef(name) end

--- Create a new card instance.  Seeds fields from the registry if the type is defined.  Each card receives a unique auto-incrementing integer ID. Card fields:
---@param card_type string
---@return LCard
function library.cardgame.newCard(card_type) end

--- Return the numeric stat value for key, or 0 if not set.
---@param key string
---@return number
function Card:getStat(key) end

--- Set a numeric stat to an exact value.
---@param key string
---@param val number
---@return nil
function Card:setStat(key, val) end

--- Add delta to a stat and return the new value.
---@param key string
---@param delta number
---@return number
function Card:addStat(key, delta) end

--- Remove a stat entry entirely.
---@param key string
---@return nil
function Card:removeStat(key) end

--- Return true if the tag is present on this card.
---@param tag string
---@return boolean
function Card:hasTag(tag) end

--- Add a tag if not already present.
---@param tag string
---@return nil
function Card:addTag(tag) end

--- Remove the first occurrence of tag; returns true if it was present.
---@param tag string
---@return boolean
function Card:removeTag(tag) end

--- Return the named counter value, or 0 if not set.
---@param key string
---@return number
function Card:getCounter(key) end

--- Set a named counter to an exact value.
---@param key string
---@param v number
---@return nil
function Card:setCounter(key, v) end

--- Add delta to a counter and return the new value.
---@param key string
---@param delta number
---@return number
function Card:addCounter(key, delta) end

--- Remove a counter entry entirely.
---@param key string
---@return nil
function Card:removeCounter(key) end

--- Return a metadata string, or nil if not set.
---@param key string
---@return string|nil
function Card:getMeta(key) end

--- Store an arbitrary metadata string.
---@param key string
---@param val string
---@return nil
function Card:setMeta(key, val) end

--- Reset stats from the registered type definition, discarding per-instance overrides.
---@return nil
function Card:resetStats() end

--- Flip the card face (toggles face_up).
---@return nil
function Card:flip() end

--- Tap this card (mark as used/exhausted).
---@return nil
function Card:tap() end

--- Untap this card (reset exhausted state).
---@return nil
function Card:untap() end

--- Return true if the card is face-up.
---@return boolean
function Card:isFaceUp() end

--- Return true if the card is tapped.
---@return boolean
function Card:isTapped() end

--- Set the rarity tier string.
---@param r string
---@return nil
function Card:setRarity(r) end

--- Get the rarity tier string.
---@return string
function Card:getRarity() end

--- Set the tile grid position for board layout.
---@param x number
---@param y number
---@return nil
function Card:setTilePosition(x, y) end

--- Get the tile grid position.
---@return number
function Card:getTilePosition() end

--- Create a new unbounded Stack. Stack fields:
---@param name string
---@return LCardStack
function library.cardgame.newStack(name) end

--- Create a new Stack with a fixed capacity limit.
---@param name string
---@param cap number
---@return LCardStack
function library.cardgame.newStackWithCapacity(name, cap) end

--- Return the number of cards.
---@return number
function Stack:size() end

--- Return true when the stack contains no cards.
---@return boolean
function Stack:isEmpty() end

--- Return true when the stack has reached its capacity limit.
---@return boolean
function Stack:isFull() end

--- Return the capacity limit, or nil for unlimited.
---@return number|nil
function Stack:capacity() end

--- Set or remove the capacity limit (nil = unlimited).
---@param cap number|nil
---@return nil
function Stack:setCapacity(cap) end

--- Push a card onto the top of the stack; returns false when full.
---@param card LCard
---@return boolean
function Stack:pushTop(card) end

--- Push a card onto the bottom of the stack; returns false when full.
---@param card LCard
---@return boolean
function Stack:pushBottom(card) end

--- Remove and return the top card, or nil if empty.
---@return LCard|nil
function Stack:popTop() end

--- Remove and return the bottom card, or nil if empty.
---@return LCard|nil
function Stack:popBottom() end

--- Pop up to n cards from the top and return them.
---@param n number
---@return table
function Stack:popMany(n) end

--- Return the top card without removing it.
---@return LCard|nil
function Stack:peekTop() end

--- Return the bottom card without removing it.
---@return LCard|nil
function Stack:peekBottom() end

--- Return the card at the given 1-based index without removing it.
---@param idx number
---@return LCard|nil
function Stack:peekAt(idx) end

--- Insert card at position idx (1-based, clamped); returns false when full.
---@param idx number
---@param card LCard
---@return boolean
function Stack:insertAt(idx, card) end

--- Remove and return the card at 1-based position idx, or nil if out of range.
---@param idx number
---@return LCard|nil
function Stack:removeAt(idx) end

--- Move a card from one 1-based index to another within the same stack.
---@param from number
---@param to number
---@return boolean
function Stack:moveWithin(from, to) end

--- Clear all cards and return them.
---@return table
function Stack:clear() end

--- Return a list of 1-based indices of cards with the given type name.
---@param card_type string
---@return table
function Stack:searchByType(card_type) end

--- Return a list of 1-based indices of cards that have the given tag.
---@param tag string
---@return table
function Stack:searchByTag(tag) end

--- Return a list of 1-based indices of cards with the given category.
---@param cat string
---@return table
function Stack:searchByCategory(cat) end

--- Return the 1-based index of the first card with the given type, or nil.
---@param card_type string
---@return number|nil
function Stack:findByType(card_type) end

--- Return the 1-based index of the first card with the given tag, or nil.
---@param tag string
---@return number|nil
function Stack:findByTag(tag) end

--- Return all Card objects with the given category.
---@param cat string
---@return table
function Stack:findByCategoryAll(cat) end

--- Return all Card objects with the given type name.
---@param type_name string
---@return table
function Stack:findByTypeAll(type_name) end

--- Return all Card objects that have the given tag.
---@param tag string
---@return table
function Stack:findByTagAll(tag) end

--- Remove and return the Card with the given id, or nil if not found.
---@param id number
---@return LCard|nil
function Stack:removeById(id) end

--- Return true if a card with the given id is in the stack.
---@param id number
---@return boolean
function Stack:containsId(id) end

--- Return the count of cards with the given type name.
---@param t string
---@return number
function Stack:countByType(t) end

--- Return the count of cards with the given category.
---@param cat string
---@return number
function Stack:countByCategory(cat) end

--- Return the count of cards that have the given tag.
---@param tag string
---@return number
function Stack:countByTag(tag) end

--- Sort cards by a named stat in ascending order (in-place).
---@param stat string
---@return nil
function Stack:sortByStat(stat) end

--- Sort cards by a named stat in descending order (in-place).
---@param stat string
---@return nil
function Stack:sortByStatDesc(stat) end

--- Sort cards alphabetically by category field (in-place).
---@return nil
function Stack:sortByCategory() end

--- Sort cards alphabetically by name field (in-place).
---@return nil
function Stack:sortByName() end

--- Shuffle cards into a random order using Fisher-Yates. TODO(P4 lift): replace with lurek.math.shuffle when available so the shuffle becomes seedable and decoupled from the global RNG state.
---@return nil
function Stack:shuffle() end

--- Return the raw card array (by reference).
---@return table
function Stack:items() end

--- Return the type names of the top n cards (topmost first).
---@param n number
---@return table
function Stack:peekTopNTypes(n) end

--- Return a shallow copy of the card array for later restoration.
---@return table
function Stack:snapshotCards() end

--- Replace the card array with a previously snapshotted copy.
---@param cards table
---@return nil
function Stack:restoreCards(cards) end

--- Return true when the stack preserves insertion order.
---@return boolean
function Stack:isOrdered() end

--- Set whether the stack preserves order.
---@param b boolean
---@return nil
function Stack:setOrdered(b) end

--- Return true when the stack contents are publicly visible.
---@return boolean
function Stack:isPublic() end

--- Set whether the stack is publicly visible.
---@param b boolean
---@return nil
function Stack:setPublic(b) end

--- Rename the stack.
---@param n string
---@return nil
function Stack:setName(n) end

--- Create a new unbounded Slot. Slot fields:
---@param name string
---@return Slot
function library.cardgame.newSlot(name) end

--- Create a new Slot with a fixed capacity limit.
---@param name string
---@param cap number
---@return Slot
function library.cardgame.newSlotWithCapacity(name, cap) end

--- Return true when the slot contains no items.
---@return boolean
function Slot:isEmpty() end

--- Return true when the slot has reached its capacity.
---@return boolean
function Slot:isFull() end

--- Return the number of items in the slot.
---@return number
function Slot:size() end

--- Return the capacity limit, or nil for unlimited.
---@return number|nil
function Slot:capacity() end

--- Set or remove the capacity limit (nil = unlimited).
---@param cap number|nil
---@return nil
function Slot:setCapacity(cap) end

--- Push a card into the slot; returns true on success, false+error when full.
---@param card LCard
---@return boolean
function Slot:push(card) end

--- Remove and return the last pushed card, or nil if empty.
---@return LCard|nil
function Slot:pop() end

--- Remove and return the item at 1-based index, or nil if out of range.
---@param idx number
---@return LCard|nil
function Slot:removeAt(idx) end

--- Return the last pushed item without removing it.
---@return LCard|nil
function Slot:peek() end

--- Return the item at 1-based index without removing it.
---@param idx number
---@return LCard|nil
function Slot:peekAt(idx) end

--- Clear all items and return them.
---@return table
function Slot:clear() end

--- Return the raw items array (by reference).
---@return table
function Slot:getItems() end

--- Return true if any item in the slot has the given tag.
---@param tag string
---@return boolean
function Slot:hasItemWithTag(tag) end

--- Return true if any item in the slot has the given type name.
---@param t string
---@return boolean
function Slot:hasItemOfType(t) end

--- Create a new empty CardPool. CardPool fields:
---@param name string
---@return CardPool
function library.cardgame.newCardPool(name) end

--- Add a type with a draw weight (minimum 1).
---@param type_name string
---@param weight number
---@return nil
function CardPool:add(type_name, weight) end

--- Remove all entries for the given type name.
---@param type_name string
---@return nil
function CardPool:remove(type_name) end

--- Update the weight for an existing type entry (no-op if not found).
---@param type_name string
---@param weight number
---@return nil
function CardPool:setWeight(type_name, weight) end

--- Rename the pool.
---@param n string
---@return nil
function CardPool:setName(n) end

--- Set a per-rarity draw weight used by drawByRarity.
---@param rarity string
---@param weight number
---@return nil
function CardPool:setRarityWeight(rarity, weight) end

--- Return the sum of all entry weights.
---@return number
function CardPool:totalWeight() end

--- Return the number of distinct entries in the pool.
---@return number
function CardPool:size() end

--- Return true when the pool has no entries.
---@return boolean
function CardPool:isEmpty() end

--- Return the draw weight for a type name, or 0 if not present.
---@param type_name string
---@return number
function CardPool:getWeight(type_name) end

--- Return an array of all type name strings in pool insertion order.
---@return table
function CardPool:getTypeNames() end

--- Draw n type names by weighted random selection (with replacement).
---@param n number
---@return table
function CardPool:drawTypes(n) end

--- Draw n Card instances by weighted random selection (with replacement).
---@param n number
---@return table
function CardPool:drawItems(n) end

--- Draw up to n unique type names by weighted selection without replacement.
---@param n number
---@return table
function CardPool:drawUniqueTypes(n) end

--- Draw up to n unique Card instances by weighted selection without replacement.
---@param n number
---@return table
function CardPool:drawUniqueItems(n) end

--- Draw n Card instances using a fixed random seed for reproducibility. Saves and restores the global RNG state across the call so callers outside the seeded scope continue to observe the global RNG sequence. TODO(P4 lift): use lurek.math.newRng()/lurek.math.shuffle when available to avoid touching the global RNG entirely.
---@param n number
---@param seed number
---@return table
function CardPool:drawItemsSeeded(n, seed) end

--- Draw cards matching a rarity distribution table {rarity=count,...}.
---@param distribution table
---@return table
function CardPool:drawByRarity(distribution) end

--- Create a new empty StackManager.
---@return StackManager
function library.cardgame.newStackManager() end

--- Register an existing stack under a name.
---@param name string
---@param stack LCardStack
---@return nil
function StackManager:addStack(name, stack) end

--- Create and register a new unbounded stack.
---@param name string
---@return nil
function StackManager:createStack(name) end

--- Create and register a new capacity-limited stack.
---@param name string
---@param cap number
---@return nil
function StackManager:createStackCapped(name, cap) end

--- Deregister and return a stack, or nil if not found.
---@param name string
---@return LCardStack|nil
function StackManager:removeStack(name) end

--- Return true if a stack with the given name is registered.
---@param name string
---@return boolean
function StackManager:hasStack(name) end

--- Return the registered Stack, or nil if not found.
---@param name string
---@return LCardStack|nil
function StackManager:getStack(name) end

--- Return a sorted list of all registered stack names.
---@return table
function StackManager:stackNames() end

--- Return the total number of cards across all registered stacks.
---@return number
function StackManager:totalItems() end

--- Move the card at idx in from_name to the top of to_name.
---@param from_name string
---@param idx number
---@param to_name string
---@return LCard|nil
function StackManager:moveItem(from_name, idx, to_name) end

--- Move the first card of a given type from one stack to another.
---@param from_name string
---@param card_type string
---@param to_name string
---@return LCard|nil
function StackManager:moveItemByType(from_name, card_type, to_name) end

--- Move the top card from one stack to another.
---@param from_name string
---@param to_name string
---@return LCard|nil
function StackManager:moveTop(from_name, to_name) end

--- Create a new build entry for use with DeckBuilder.
---@param type_name string
---@param count number
---@return table
function library.cardgame.newBuildEntry(type_name, count) end

--- Create a new DeckBuilder.
---@param name string
---@return DeckBuilder
function library.cardgame.newDeckBuilder(name) end

--- Add count copies of type_name to the build list.
---@param type_name string
---@param count number
---@return nil
function DeckBuilder:add(type_name, count) end

--- Add count copies with per-card stat overrides and extra tags.
---@param type_name string
---@param count number
---@param stat_overrides table
---@param extra_tags table
---@return nil
function DeckBuilder:addWith(type_name, count, stat_overrides, extra_tags) end

--- Mark a card type as required (must appear at least once in the deck).
---@param t string
---@return nil
function DeckBuilder:requireType(t) end

--- Add a type to the ban list; validateEntries will report it as an error.
---@param t string
---@return nil
function DeckBuilder:banType(t) end

--- Remove a type from the ban list; returns true if it was present.
---@param t string
---@return boolean
function DeckBuilder:removeBannedType(t) end

--- Override the global max_copies limit for a specific type.
---@param t string
---@param max_val number
---@return nil
function DeckBuilder:setMaxCopiesForType(t, max_val) end

--- Require that at least min_count cards with the given tag appear.
---@param tag string
---@param min_count number
---@return nil
function DeckBuilder:addRequiredTag(tag, min_count) end

--- Require a specific count range for cards of a given category.
---@param cat string
---@param min_count number
---@param max_count number|nil
---@return nil
function DeckBuilder:addRequiredCategory(cat, min_count, max_count) end

--- Validate the builder's entries against all constraints.
---@return table
function DeckBuilder:validateEntries() end

--- Validate an already-built Stack against size constraints.
---@param stack LCardStack
---@return table
function DeckBuilder:validateStack(stack) end

--- Build and return a Stack using the builder's own name.
---@return LCardStack
function DeckBuilder:build() end

--- Build and return a Stack with a custom name.
---@param stack_name string
---@return LCardStack
function DeckBuilder:buildNamed(stack_name) end

--- Create a Pushed action recording which card was pushed.
---@param card_type string
---@param item_name string
---@return table
function library.cardgame.HistoryAction.pushed(card_type, item_name) end

--- Create a Popped action recording which card was popped.
---@param card_type string
---@param item_name string
---@return table
function library.cardgame.HistoryAction.popped(card_type, item_name) end

--- Create a Moved action recording an inter-stack card transfer.
---@param card_type string
---@param item_name string
---@param from_stack string
---@param to_stack string
---@return table
function library.cardgame.HistoryAction.moved(card_type, item_name, from_stack, to_stack) end

--- Create a Shuffled action.
---@return table
function library.cardgame.HistoryAction.shuffled() end

--- Create a Sorted action recording the sort field.
---@param by string
---@return table
function library.cardgame.HistoryAction.sorted(by) end

--- Create a Cleared action.
---@return table
function library.cardgame.HistoryAction.cleared() end

--- Create a Built action recording how many cards were built.
---@param count number
---@return table
function library.cardgame.HistoryAction.built(count) end

--- Create a user-defined Custom action.
---@param label string
---@return table
function library.cardgame.HistoryAction.custom(label) end

--- Create a new unlimited StackHistory.
---@return StackHistory
function library.cardgame.newStackHistory() end

--- Create a StackHistory that keeps only the most recent max_size entries.
---@param max_size number
---@return StackHistory
function library.cardgame.newStackHistoryWithMaxSize(max_size) end

--- Append an action entry to the log.
---@param stack_name string
---@param action table
---@param size_after number
---@return nil
function StackHistory:record(stack_name, action, size_after) end

--- Append a user-defined label as a Custom action.
---@param stack_name string
---@param label string
---@param size_after number
---@return nil
function StackHistory:recordCustom(stack_name, label, size_after) end

--- Return the number of recorded entries.
---@return number
function StackHistory:len() end

--- Return true when no entries have been recorded.
---@return boolean
function StackHistory:isEmpty() end

--- Return the entries array (oldest first).
---@return table
function StackHistory:entries() end

--- Return the most recent entry, or nil if empty.
---@return table|nil
function StackHistory:last() end

--- Return all entries for the given stack name.
---@param stack_name string
---@return table
function StackHistory:entriesFor(stack_name) end

--- Clear all recorded entries.
---@return nil
function StackHistory:clear() end

--- Create a new CardGroup with a label, index list, and optional score.
---@param label string
---@param indices table
---@param score number|nil
---@return CardGroup
function library.cardgame.newCardGroup(label, indices, score) end

--- Collect the actual card objects referenced by this group's indices.
---@param cards table
---@return table
function CardGroup:itemsFrom(cards) end

--- Return the number of cards in the group.
---@return number
function CardGroup:size() end

--- Return true when the group has no cards.
---@return boolean
function CardGroup:isEmpty() end

--- Return the highest value of a stat across grouped cards.
---@param cards table
---@param stat string
---@return number
function CardGroup:maxStat(cards, stat) end

--- Return the sum of a stat across grouped cards.
---@param cards table
---@param stat string
---@return number
function CardGroup:totalStat(cards, stat) end

--- Return true if every card in the group has the given tag.
---@param cards table
---@param tag string
---@return boolean
function CardGroup:allHaveTag(cards, tag) end

--- Validate that a card list does not exceed per-type max_per_deck limits. Returns nil on success or an error string describing the first violation.
---@param cards table
---@return string|nil
function library.cardgame.checkDeckLimit(cards) end

--- Group card-like items by category field. Returns table: category -> {item,...}.
---@param items table
---@return table
function library.cardgame.groupByCategory(items) end

--- Return items where getStat(stat) >= n.
---@param items table
---@param stat string
---@param n number
---@return table
function library.cardgame.findAtLeastNOfStat(items, stat, n) end

--- Return each unique tag that appears on more than one item, with the items list.
---@param items table
---@return table
function library.cardgame.findTagGroups(items) end

--- Return 1-based indices sorted by a stat (ascending).
---@param items table
---@param stat string
---@return table
function library.cardgame.sortedIndicesByStat(items, stat) end

--- Return 1-based indices sorted by category (alphabetical).
---@param items table
---@return table
function library.cardgame.sortedIndicesByCategory(items) end

--- Group 1-based indices of items by the integer value of a named stat. Returns a map of stat_value (floored to integer) ��� array of 1-based indices.
---@param items table
---@param stat string
---@return table
function library.cardgame.groupByStat(items, stat) end

--- Group 1-based indices by the value portion of a prefixed tag. Tags of the form "prefix:value" are grouped under "value". Tags that do not start with prefix: are ignored.
---@param items table
---@param prefix string
---@return table
function library.cardgame.groupByTagPrefix(items, prefix) end

--- Find all groups where exactly n items share the same integer stat value. Analogous to "n-of-a-kind" detection in card games.
---@param items table
---@param stat string
---@param n number
---@return table
function library.cardgame.findNOfStat(items, stat, n) end

--- Find all runs of consecutive integer stat values with length >= min_run. Useful for "straight" or sequential-run detection in card games. Each run is returned as a CardGroup whose indices reference the original list.
---@param items table
---@param stat string
---@param min_run number
---@return table
function library.cardgame.findSequences(items, stat, min_run) end

---@class library.cinematic
library.cinematic = {}

--- Add a generic clip table.
---@param clip table
---@return nil
function Track:add(clip) end

--- Tween clip. Wraps `lurek.tween` if available; always applies final value if the engine binding is missing (so logic-only tests still pass).
---@return nil
function Track:tween(at, duration, target, props, easing) end

--- Camera move clip.
---@return nil
function Track:cameraTo(at, duration, x, y, zoom, easing) end

--- Camera shake clip.
---@return nil
function Track:shake(at, duration, intensity) end

--- Dialog clip — fires once forward only.
---@return nil
function Track:dialog(at, line) end

--- Audio clip — fires once forward only.
---@return nil
function Track:audio(at, source, opts) end

--- Signal clip — emits via `lurek.event.push` (or queues for later read).
---@return nil
function Track:signal(at, name, ...) end

--- Generic Lua callback. Mark `reversible = true` to allow backward seeks.
---@return nil
function Track:call(at, fn, opts) end

--- Wait clip — pauses the timeline until `predicate_fn()` returns true.
---@return nil
function Track:wait(at, predicate_fn) end

--- Remove a clip by reference.
---@return nil
function Track:remove(clip) end

--- Create a new timeline.
---@param opts table|nil
---@return Timeline
function library.cinematic.newTimeline(opts) end

--- Load a timeline from a TOML file via `lurek.filesystem.read` + `lurek.serial.fromToml`.
---@return nil
function library.cinematic.fromToml(path) end

--- Build a timeline from a declarative spec table.
---@return nil
function library.cinematic.fromTable(spec) end

--- Get-or-create a track by name.
---@return nil
function Timeline:track(name) end

--- Return an ordered array of all tracks in this timeline.
---@return table
function Timeline:tracks() end

--- Recompute total duration from the latest clip end.
---@return nil
function Timeline:_recompute_duration() end

--- Bind a dialog handler `fn(line)` invoked by `track:dialog` clips.
---@return nil
function Timeline:setDialogHandler(fn) end

--- Start (or resume) playback of this timeline.
---@return Timeline
function Timeline:play() end

--- Pause playback at the current time position.
---@return Timeline
function Timeline:pause() end

--- Resume playback from the current time position.
---@return Timeline
function Timeline:resume() end

--- Stop playback and reset the timeline to time zero.
---@return Timeline
function Timeline:stop() end

--- Return true if the timeline is currently playing.
---@return boolean
function Timeline:isPlaying() end

--- Return true if the timeline has reached its end and is not looping.
---@return boolean
function Timeline:isFinished() end

--- Return the current playback time in seconds.
---@return number
function Timeline:getTime() end

--- Return the total duration of the timeline in seconds.
---@return number
function Timeline:getDuration() end

--- Set the playback speed multiplier (1.0 = real-time, 2.0 = double speed).
---@param s number
---@return Timeline
function Timeline:setTimeScale(s) end

--- Add a labelled cue point.
---@return nil
function Timeline:label(at, name) end

--- Add a branch — `child_timeline` runs at `at` only when `predicate(tl)` is true.
---@return nil
function Timeline:branch(at, predicate, child) end

--- Advance timeline by `dt`. Call once per frame from `lurek.process`.
---@return nil
function Timeline:update(dt) end

--- Reset fired/applied flags on all clips in all tracks (used after loop restart).
---@return nil
function Timeline:_reset_clip_flags() end

--- Seek to absolute time.
---@return nil
function Timeline:setTime(t) end

--- Seek forward or backward by `delta` seconds relative to current time.
---@param delta number
---@return Timeline
function Timeline:scrub(delta) end

--- Rewind the timeline to time zero.
---@return Timeline
function Timeline:rewind() end

--- Seek to the time position of a named label.
---@param label string
---@return Timeline
function Timeline:skipTo(label) end

--- Register a callback invoked when the timeline finishes. Returns a handle that can be passed to `Timeline:offHandle`.
---@param fn function
---@return table
function Timeline:onComplete(fn) end

--- Register a callback invoked whenever a clip on `name` track begins.
---@param name string
---@param fn function
---@return table
function Timeline:onTrackEnter(name, fn) end

--- Deregister a callback handle previously returned by `onComplete` or `onTrackEnter`.
---@param handle table
---@return nil
function Timeline:offHandle(handle) end

--- Export a lightweight snapshot of the timeline state for serialisation.
---@return table
function Timeline:export() end

---@class library.combat
library.combat = {}

--- Creates an empty collision-group set.
---@return any
function library.combat.newCollisionGroupSet() end

--- Defines a named group and returns its power-of-two category bit. Returns nil plus an error string if the name is empty, taken, or the 16-group limit has been reached (bitmask overflow protection).
---@param name string
---@return number|nil
---@return string|nil
function CollisionGroupSet:defineGroup(name) end

--- Returns the category bit for the named group, or nil.
---@param name string
---@return any
function CollisionGroupSet:getGroupBit(name) end

--- Sets whether two named groups should collide with each other.
---@param group_a string
---@param group_b string
---@param collides boolean
---@return any
function CollisionGroupSet:setCollides(group_a, group_b, collides) end

--- Returns whether two named groups collide (defaults to true).
---@param group_a string
---@param group_b string
---@return any
function CollisionGroupSet:getCollides(group_a, group_b) end

--- Computes the collision filter mask bits for the named group.
---@param group string
---@return any
function CollisionGroupSet:computeMask(group) end

--- Returns the number of defined groups.
---@return any
function CollisionGroupSet:groupCount() end

--- Returns an array of all defined group names.
---@return any
function CollisionGroupSet:groupNames() end

--- Clears all groups and collision rules.
---@return nil
function CollisionGroupSet:reset() end

--- Creates a new turret or weapon mount slot.
---@param id string
---@param x number
---@param y number
---@param size_class string
---@return table
function library.combat.newMountSlot(id, x, y, size_class) end

--- Creates a new chassis with the given physics body ID and maximum hit points.
---@param body_id number
---@param max_hp number
---@return Chassis
function library.combat.newChassis(body_id, max_hp) end

--- Appends a mount slot to this chassis.
---@param slot table
---@return nil
function Chassis:addSlot(slot) end

--- Returns the mount slot with the given ID, or nil.
---@param id string
---@return any
function Chassis:getSlot(id) end

--- Returns an ordered array of all mount slots.
---@return any
function Chassis:getSlots() end

--- Applies damage to the chassis, clamping HP to zero. Sets destroyed=true if HP reaches zero.
---@param amount number
---@return number
function Chassis:takeDamage(amount) end

--- Heals the chassis, clamping HP to max_hp.
---@param amount number
---@return any
function Chassis:heal(amount) end

--- Returns true if the chassis is destroyed or HP has reached zero.
---@return any
function Chassis:isDead() end

--- Returns the armor value for the named zone (defaults to 0).
---@param zone string
---@return any
function Chassis:getArmor(zone) end

--- Sets the armor value for the named zone.
---@param zone string
---@param value number
---@return nil
function Chassis:setArmor(zone, value) end

--- Creates a new turret with the given physics body and joint IDs.
---@param body_id number
---@param joint_id number
---@return Turret
function library.combat.newTurret(body_id, joint_id) end

--- Updates the turret toward its target angle, snapping to the closest arc boundary when the target lies outside [arc_min, arc_max]. Returns the desired angular velocity, or nil if no target is set.
---@param dt number
---@param current_angle number
---@return number|nil
function Turret:update(dt, current_angle) end

--- Sets the desired target angle for the turret.
---@param angle number
---@return nil
function Turret:aimAtAngle(angle) end

--- Returns true if the target angle is within the turret arc and tolerance. Mirrors Rust: checks whether clamp_to_arc(target) Ôëł target. Returns true when no target is set.
---@param tolerance number
---@return any
function Turret:isAimed(tolerance) end

--- Clamps an angle to the turret arc limits [arc_min, arc_max].
---@param angle number
---@return any
function Turret:clampToArc(angle) end

--- Creates a new weapon with default values. Defaults: fire_rate=1, ammo=-1 (infinite), damage_amount=10, range=500, projectile_speed=300, burst_size=1.
---@param name string
---@return Weapon
function library.combat.newWeapon(name) end

--- Returns true if the weapon is ready to fire.
---@return any
function Weapon:canFire() end

--- Attempts to fire the weapon. Returns true if a shot was produced. Consumes one ammo token, applies cooldown, and manages burst state. Intra-burst shots use burst_delay; after the last burst shot, inter-burst cooldown (1/fire_rate) is applied.
---@param dt number
---@return boolean
function Weapon:fire(dt) end

--- Activates continuous firing mode.
---@return nil
function Weapon:startFiring() end

--- Deactivates firing and resets burst_remaining to zero.
---@return nil
function Weapon:stopFiring() end

--- Returns true when the weapon is in firing mode.
---@return any
function Weapon:isFiring() end

--- Ticks the cooldown timer by dt seconds.
---@param dt number
---@return nil
function Weapon:updateCooldown(dt) end

--- Reloads ammo. Full reload when amount is nil; partial reload otherwise. Clamped to max_ammo when max_ammo > 0.
---@param amount number|nil
---@return nil
function Weapon:reload(amount) end

--- Returns true when finite ammo reaches zero.
---@return any
function Weapon:isOutOfAmmo() end

--- Resets this projectile to its inactive default state. Clears all fields including projectile_type (restored to Ballistic).
---@return nil
function Projectile:reset() end

--- Updates lifetime and distance_traveled for an active projectile. Does nothing if the projectile is not active.
---@param dt number
---@param body_x number
---@param body_y number
---@param body_angle number
---@return nil
function Projectile:update(dt, body_x, body_y, body_angle) end

--- Creates a new projectile pool with the given capacity. Defaults to DEFAULT_POOL_SIZE (64) when pool_size is nil; capped at MAX_POOL_SIZE (1024).
---@param pool_size number
---@param projectile_type string
---@return ProjectilePool
function library.combat.newProjectilePool(pool_size, projectile_type) end

--- Spawns a projectile from the free pool.
---@param x number
---@param y number
---@param angle number
---@param speed number
---@param damage number
---@param damage_type string
---@param range number
---@return any
function ProjectilePool:spawn(x, y, angle, speed, damage, damage_type, range) end

--- Returns a projectile slot to the free pool. Does nothing if the slot is already inactive (prevents double-free).
---@param idx number
---@return nil
function ProjectilePool:release(idx) end

--- Returns the number of currently active projectiles.
---@return any
function ProjectilePool:activeCount() end

--- Returns the number of free slots.
---@return any
function ProjectilePool:freeCount() end

--- Returns an array of 1-based indices for all active projectiles.
---@return any
function ProjectilePool:getActive() end

--- Returns the projectile at the given 1-based index, or nil if out of range.
---@param idx number
---@return any
function ProjectilePool:get(idx) end

--- Releases all active projectiles back to the free pool.
---@return nil
function ProjectilePool:resetAll() end

--- Creates an empty combat world. This is a logical container only — broad-phase hit detection and shape queries should be performed against a real physics world via `lurek.physics.newWorld():raycast()` / `:shapecast()` and the resulting contacts then mapped back onto chassis/turret/weapon entities here.
---@return any
function library.combat.newCombatWorld() end

--- Adds a chassis and returns its 1-based index.
---@param chassis table
---@return any
function CombatWorld:addChassis(chassis) end

--- Returns the chassis at the given 1-based index, or nil.
---@param idx number
---@return any
function CombatWorld:getChassis(idx) end

--- Adds a turret and returns its 1-based index.
---@param turret table
---@return any
function CombatWorld:addTurret(turret) end

--- Returns the turret at the given 1-based index, or nil.
---@param idx number
---@return any
function CombatWorld:getTurret(idx) end

--- Adds a weapon and returns its 1-based index.
---@param weapon table
---@return any
function CombatWorld:addWeapon(weapon) end

--- Returns the weapon at the given 1-based index, or nil.
---@param idx number
---@return any
function CombatWorld:getWeapon(idx) end

--- Adds a projectile pool and returns its 1-based index.
---@param pool table
---@return any
function CombatWorld:addPool(pool) end

--- Returns the projectile pool at the given 1-based index, or nil.
---@param idx number
---@return any
function CombatWorld:getPool(idx) end

--- Returns the total number of active projectiles across all pools.
---@return any
function CombatWorld:activeProjectileCount() end

--- Returns the number of non-destroyed chassis.
---@return any
function CombatWorld:activeChassisCount() end

--- Updates all weapon cooldowns by dt seconds.
---@param dt number
---@return nil
function CombatWorld:update(dt) end

--- Clears all combat entities and resets collision groups.
---@return nil
function CombatWorld:reset() end

--- Removes destroyed chassis from the list. Warning: invalidates stored 1-based indices after the call.
---@return nil
function CombatWorld:cleanup() end

--- Returns the weapon display name. @return string Name.
---@return nil
function Weapon:getName() end

--- Sets the weapon display name. @param v string Name.
---@return nil
function Weapon:setName(v) end

--- Returns fire rate in rounds/s. @return number Fire rate.
---@return nil
function Weapon:getFireRate() end

--- Sets fire rate in rounds/s. @param v number Fire rate.
---@return nil
function Weapon:setFireRate(v) end

--- Returns current ammo count (-1 = infinite). @return number Ammo.
---@return nil
function Weapon:getAmmo() end

--- Sets current ammo count. @param v number Ammo.
---@return nil
function Weapon:setAmmo(v) end

--- Returns maximum ammo capacity. @return number Max ammo.
---@return nil
function Weapon:getMaxAmmo() end

--- Sets maximum ammo capacity. @param v number Max ammo.
---@return nil
function Weapon:setMaxAmmo(v) end

--- Returns burst size (rounds per burst). @return number Burst size.
---@return nil
function Weapon:getBurstSize() end

--- Sets burst size. @param v number Burst size.
---@return nil
function Weapon:setBurstSize(v) end

--- Returns delay between burst rounds in seconds. @return number Burst delay.
---@return nil
function Weapon:getBurstDelay() end

--- Sets burst delay in seconds. @param v number Burst delay.
---@return nil
function Weapon:setBurstDelay(v) end

--- Returns remaining rounds in current burst. @return number Burst remaining.
---@return nil
function Weapon:getBurstRemaining() end

--- Sets remaining rounds in current burst. @param v number Value.
---@return nil
function Weapon:setBurstRemaining(v) end

--- Returns angular spread in radians. @return number Spread.
---@return nil
function Weapon:getSpread() end

--- Sets angular spread in radians. @param v number Spread.
---@return nil
function Weapon:setSpread(v) end

--- Returns damage per hit. @return number Damage amount.
---@return nil
function Weapon:getDamageAmount() end

--- Sets damage per hit. @param v number Damage amount.
---@return nil
function Weapon:setDamageAmount(v) end

--- Returns damage type tag. @return string Damage type.
---@return nil
function Weapon:getDamageType() end

--- Sets damage type tag. @param v string Damage type.
---@return nil
function Weapon:setDamageType(v) end

--- Returns armor penetration value. @return number Penetration.
---@return nil
function Weapon:getPenetration() end

--- Sets armor penetration value. @param v number Penetration.
---@return nil
function Weapon:setPenetration(v) end

--- Returns maximum range in world units. @return number Range.
---@return nil
function Weapon:getRange() end

--- Sets maximum range in world units. @param v number Range.
---@return nil
function Weapon:setRange(v) end

--- Returns projectile travel speed. @return number Speed.
---@return nil
function Weapon:getProjectileSpeed() end

--- Sets projectile travel speed. @param v number Speed.
---@return nil
function Weapon:setProjectileSpeed(v) end

--- Returns projectile type enum value. @return string ProjectileType.
---@return nil
function Weapon:getProjectileType() end

--- Sets projectile type. @param v string ProjectileType value.
---@return nil
function Weapon:setProjectileType(v) end

--- Returns the turret rotation speed in radians/s. @return number Turn speed.
---@return nil
function Turret:getTurnSpeed() end

--- Sets the turret rotation speed. @param v number Turn speed in radians/s.
---@return nil
function Turret:setTurnSpeed(v) end

--- Returns the minimum arc angle in radians. @return number arc_min.
---@return nil
function Turret:getArcMin() end

--- Sets the minimum arc angle in radians. @param v number arc_min.
---@return nil
function Turret:setArcMin(v) end

--- Returns the maximum arc angle in radians. @return number arc_max.
---@return nil
function Turret:getArcMax() end

--- Sets the maximum arc angle in radians. @param v number arc_max.
---@return nil
function Turret:setArcMax(v) end

--- Returns the current target angle, or nil. @return number|nil Target angle in radians.
---@return nil
function Turret:getTargetAngle() end

--- Sets the target angle (nil clears the target). @param v number|nil Target angle.
---@return nil
function Turret:setTargetAngle(v) end

--- Returns the turret size class. @return string Size class.
---@return nil
function Turret:getSizeClass() end

--- Sets the turret size class. @param v string Size class.
---@return nil
function Turret:setSizeClass(v) end

--- Returns true if this turret is destroyed. @return boolean Destroyed flag.
---@return nil
function Turret:isDestroyed() end

--- Sets the destroyed flag. @param v boolean Destroyed state.
---@return nil
function Turret:setDestroyed(v) end

---@class library.crafting
library.crafting = {}

--- Convert string to Quality value.
---@return nil
function library.crafting.qualityFromStr(s) end

--- Quality to display string.
---@return nil
function library.crafting.qualityToStr(q) end

--- Create ingredient by item type.
---@param item_type string
---@param quantity number
---@return Ingredient
function library.crafting.newIngredient(item_type, quantity) end

--- Create ingredient by tag.
---@param tag string
---@param quantity number
---@return Ingredient
function library.crafting.newIngredientTag(tag, quantity) end

--- Return true if this ingredient selects by tag rather than item_type. **Precedence**: when both `tag` and `item_type` are non-empty, the tag takes precedence — matching code should check `isTag()` first.
---@return boolean
function Ingredient:isTag() end

--- Create a guaranteed recipe output with normal quality.
---@param item_type string
---@param quantity number
---@return RecipeOutput
function library.crafting.newRecipeOutput(item_type, quantity) end

--- Create a probabilistic recipe output with an explicit chance.
---@param item_type string
---@param quantity number
---@param chance number
---@return RecipeOutput
function library.crafting.newRecipeOutputWithChance(item_type, quantity, chance) end

--- Create a recipe with default metadata. A recipe holds: `id`, `recipe_type`, `name`, `description`, `category`, `station_type`, `station_level`, `time` (seconds), `cooldown`, `fuel_consumption_rate`, `ingredients` (list of Ingredient), `outputs` (list of RecipeOutput), `remainder_item`, `skill`, `skill_level`, `skill_xp`, `enabled`, `hand_craftable`, `tags`, `knowledge_mode`, `discovery_hint`, `grid_width`, `grid_height`, `grid_slots`, `grid_mirror`, `grid_rotation`, `required_nearby_stations`, `required_biome`, `required_location`, `orange/yellow/green/grey_threshold`, `upgrade_from`, `upgrade_to`, `alternatives`, `output_quality_scaling`, `random_modifier_pool`, `skill_up_curve`, `conditions`, `metadata`.
---@param id string
---@return Recipe
function library.crafting.newRecipe(id) end

--- Return true if the recipe carries the given tag.
---@param t string
---@return boolean
function Recipe:hasTag(t) end

--- Assign an item type to a shaped-recipe grid slot (0-based). Returns false with a warning if coordinates are out of bounds.
---@param x number
---@param y number
---@param item_type string
---@return boolean
function Recipe:setGridSlot(x, y, item_type) end

--- Add a byproduct output with a drop chance.
---@param item_type string
---@param quantity number
---@param chance number
---@return nil
function Recipe:addByproduct(item_type, quantity, chance) end

--- Add a crafting condition requirement.
---@param ctype string
---@param cvalue string
---@return nil
function Recipe:addCondition(ctype, cvalue) end

--- Create an empty recipe registry.
---@return RecipeRegistry
function library.crafting.newRecipeRegistry() end

--- Register a recipe in the registry.
---@param recipe Recipe
---@return nil
function RecipeRegistry:add(recipe) end

--- Remove a recipe by ID. Returns true if it existed.
---@param id string
---@return boolean
function RecipeRegistry:remove(id) end

--- Return all recipe IDs in registration order.
---@return table
function RecipeRegistry:ids() end

--- Find recipes that produce a specific item type.
---@param item_type string
---@return table
function RecipeRegistry:findByOutput(item_type) end

--- Find recipes that consume a specific item type.
---@param item_type string
---@return table
function RecipeRegistry:findByIngredient(item_type) end

--- Find recipes carrying a specific tag.
---@param tag string
---@return table
function RecipeRegistry:findByTag(tag) end

--- Find recipes that require a specific station type.
---@param station_type string
---@return table
function RecipeRegistry:forStation(station_type) end

--- Find recipes in a UI category.
---@param cat string
---@return table
function RecipeRegistry:findByCategory(cat) end

--- Find recipes gated by a skill, optionally capped to max_level.
---@param name string
---@param max_level number|nil
---@return table
function RecipeRegistry:findBySkill(name, max_level) end

--- Find all hand-craftable recipes.
---@return table
function RecipeRegistry:findHandCraftable() end

--- Create a crafting station with default state.
---@param name string
---@param station_type string
---@return Station
function library.crafting.newStation(name, station_type) end

--- Add fuel, clamped to max_fuel. Negative amounts are ignored.
---@param amount number
---@return number
function Station:addFuel(amount) end

--- Consume fuel. Returns false if insufficient or amount is invalid.
---@param amount number
---@return boolean
function Station:consumeFuel(amount) end

--- Return fuel as a fraction of max_fuel in [0, 1].
---@return number
function Station:fuelPercent() end

--- Install a named module. Returns false if at capacity or already present.
---@param name string
---@return boolean
function Station:addModule(name) end

--- Add a physical attachment. Returns false if at capacity or duplicate.
---@param name string
---@return boolean
function Station:addAttachment(name) end

--- Increment station level. Returns false if already at max.
---@return boolean
function Station:upgrade() end

--- Create a crafting skill with default linear progression.
---@param name string
---@return CraftSkill
function library.crafting.newCraftSkill(name) end

--- Add XP and level up as many times as the XP allows.
---@param amount number
---@return number
function CraftSkill:addXP(amount) end

--- Grant one free perk point.
---@return nil
function CraftSkill:grantPerkPoint() end

--- Spend a perk point to unlock a perk by name. Returns false if no points or perk not unlockable.
---@param perk_name string
---@return boolean
function CraftSkill:spendPerkPoint(perk_name) end

--- Return true if the named perk is unlocked.
---@param name string
---@return boolean
function CraftSkill:hasPerk(name) end

--- Register a PerkNode in the skill perk tree.
---@param node PerkNode
---@return nil
function CraftSkill:addPerkToTree(node) end

--- Create a locked perk node.
---@param name string
---@return PerkNode
function library.crafting.newPerkNode(name) end

--- Return true if the perk can be unlocked now.
---@param skill_level number
---@param unlocked_perks table
---@return boolean
function PerkNode:canUnlock(skill_level, unlocked_perks) end

--- Create a weighted modifier entry.
---@param name string
---@param weight number
---@return ModifierEntry
function library.crafting.newModifierEntry(name, weight) end

--- Create an empty modifier pool.
---@return ModifierPool
function library.crafting.newModifierPool() end

--- Select a random weighted modifier entry (non-deterministic).
---@return ModifierEntry|nil
function ModifierPool:roll() end

--- Alias for roll(). Select a random weighted modifier entry.
---@return ModifierEntry|nil
function ModifierPool:draw() end

--- Discover a recipe. Optional source label ("craft", "research", "loot", etc.).
---@param recipe_id string
---@param source string|nil
---@return boolean
function RecipeKnowledge:discover(recipe_id, source) end

--- Return true if the recipe is known (or auto-discover is enabled).
---@param id string
---@return boolean
function RecipeKnowledge:isKnown(id) end

--- Return the number of discovered recipes.
---@return number
function RecipeKnowledge:knownCount() end

--- Return all known recipe IDs sorted alphabetically.
---@return table
function RecipeKnowledge:knownIds() end

--- Register a named group of recipe IDs for UI organisation.
---@param name string
---@param ids table
---@return nil
function RecipeKnowledge:addGroup(name, ids) end

--- Return (known_count, total_count) for a named group.
---@param name string
---@return number
---@return number
function RecipeKnowledge:groupProgress(name) end

--- Create a new craft job tracking a recipe in progress.
---@param id number
---@param recipe_id string
---@param total_time number
---@param quantity number
---@return CraftJob
function library.crafting.newCraftJob(id, recipe_id, total_time, quantity) end

--- Advance the job by dt seconds. Returns true when newly completed.
---@param dt number
---@return boolean
function CraftJob:advance(dt) end

--- Return completion fraction 0ÔÇô1.
---@return number
function CraftJob:percent() end

--- Pause the job (stops time advancing).
---@return nil
function CraftJob:pause() end

--- Resume the job.
---@return nil
function CraftJob:resume() end

--- Return true if the job is completed.
---@return boolean
function CraftJob:isCompleted() end

--- Return true if the job is paused.
---@return boolean
function CraftJob:isPaused() end

--- Return remaining seconds.
---@return number
function CraftJob:remaining() end

--- Create a new craft queue.
---@param max_jobs number
---@return CraftQueue
function library.crafting.newCraftQueue(max_jobs) end

--- Set how many jobs can advance in parallel (must be <= max_jobs).
---@param n number
---@return nil
function CraftQueue:setMaxConcurrent(n) end

--- Get the maximum concurrent job count.
---@return number
function CraftQueue:maxJobs() end

--- Enqueue a new craft job. Returns the job id, or nil if queue is full.
---@param recipe_id string
---@param total_time number
---@param quantity number
---@return number|nil
function CraftQueue:enqueue(recipe_id, total_time, quantity) end

--- Cancel a job by id. Returns true if the job was removed.
---@param id number
---@return boolean
function CraftQueue:cancel(id) end

--- Advance all jobs by dt seconds. Returns list of newly-completed job IDs. Completed jobs are automatically removed from the active job list. Use `collectCompleted()` to retrieve and clear the cumulative completion log.
---@param dt number
---@return table
function CraftQueue:update(dt) end

--- Remove and return all completed job ids since last collect.
---@return table
function CraftQueue:collectCompleted() end

--- Get a job by id (active jobs only).
---@param id number
---@return CraftJob|nil
function CraftQueue:getJob(id) end

--- Return total active job count (not including completed-but-uncollected).
---@return number
function CraftQueue:count() end

--- Return true if the queue is full.
---@return boolean
function CraftQueue:isFull() end

--- Return sorted list of active (not-completed) job IDs.
---@return table
function CraftQueue:activeIds() end

--- Return all active jobs as summary tuples.
---@return table
function CraftQueue:allJobs() end

--- Clear all jobs from the queue.
---@return nil
function CraftQueue:clear() end

--- Create a new upgrade node.
---@param id string
---@param name string
---@return UpgradeNode
function library.crafting.newUpgradeNode(id, name) end

--- Set the unlock cost.
---@param cost number
---@return nil
function UpgradeNode:setCost(cost) end

--- Get the unlock cost.
---@return number
function UpgradeNode:getCost() end

--- Add an effect to this node.
---@param effect string
---@return nil
function UpgradeNode:addEffect(effect) end

--- Get all effects.
---@return table
function UpgradeNode:getEffects() end

--- Add a tag.
---@param tag string
---@return nil
function UpgradeNode:addTag(tag) end

--- Check if the node has a tag.
---@param tag string
---@return boolean
function UpgradeNode:hasTag(tag) end

--- Return true when unlocked.
---@return boolean
function UpgradeNode:isUnlocked() end

--- Create a new upgrade tree.
---@param name string
---@return UpgradeTree
function library.crafting.newUpgradeTree(name) end

--- Add a node to the tree.
---@param node UpgradeNode
---@return nil
function UpgradeTree:addNode(node) end

--- Add a directed edge from_id Ôćĺ to_id.
---@param from_id string
---@param to_id string
---@return nil
function UpgradeTree:addEdge(from_id, to_id) end

--- Look up a node by ID.
---@param id string
---@return UpgradeNode|nil
function UpgradeTree:getNode(id) end

--- Get children of a node (sorted).
---@param id string
---@return table
function UpgradeTree:getChildren(id) end

--- Get root nodes (no parent).
---@return table
function UpgradeTree:getRootNodes() end

--- Get parent ID (or nil if root).
---@param id string
---@return string|nil
function UpgradeTree:getParent(id) end

--- Return true if a node can be unlocked. All rules: node exists, not already unlocked, parent (if any) is unlocked.
---@param id string
---@return boolean
function UpgradeTree:canUnlock(id) end

--- Unlock a node. Returns true on success.
---@param id string
---@return boolean
function UpgradeTree:unlock(id) end

--- Reset a node (re-lock it). Returns true if it was unlocked.
---@param id string
---@return boolean
function UpgradeTree:resetNode(id) end

--- Return sorted list of unlocked node IDs.
---@return table
function UpgradeTree:getUnlockedIds() end

--- Return all node IDs in insertion order.
---@return table
function UpgradeTree:nodeIds() end

--- Return total node count.
---@return number
function UpgradeTree:count() end

--- BFS path from node `from` to node `to`. Returns nil if not reachable.
---@param from string
---@param to string
---@return table|nil
function UpgradeTree:getPath(from, to) end

--- Return all nodes that are not yet unlocked and whose parent (if any) is unlocked, filtered by optional player_level requirement.
---@param unlocked_set table
---@param player_level number
---@return table
function UpgradeTree:availableUpgrades(unlocked_set, player_level) end

--- Allow a player to "prototype" a recipe (partial knowledge before full discovery).
---@param recipe_id string
---@return nil
function RecipeKnowledge:prototype(recipe_id) end

--- Return true if the recipe has been prototyped.
---@param recipe_id string
---@return boolean
function RecipeKnowledge:isPrototyped(recipe_id) end

--- Set a research cost for a recipe.
---@param recipe_id string
---@param cost number
---@return nil
function RecipeKnowledge:setResearchCost(recipe_id, cost) end

--- Get research cost for a recipe (0 if not set).
---@param recipe_id string
---@return number
function RecipeKnowledge:getResearchCost(recipe_id) end

--- Attempt to research a recipe by spending scrap resources. Returns true and discovers the recipe if scrap >= research cost.
---@param recipe_id string
---@param scrap number
---@return boolean
function RecipeKnowledge:research(recipe_id, scrap) end

--- Get the source that originally discovered a recipe ("research", "craft", etc.).
---@param recipe_id string
---@return string|nil
function RecipeKnowledge:getSource(recipe_id) end

--- XP required to reach next level.
---@return number
function CraftSkill:getXpToNext() end

--- Force-set the skill level and reset XP to 0.
---@param level number
---@return nil
function CraftSkill:setLevel(level) end

--- Return true if this skill satisfies a recipe's skill gate. Accepts a recipe table with .skill and .skill_level fields.
---@param recipe table
---@return boolean
function CraftSkill:canUse(recipe) end

--- WoW-style difficulty colour for a recipe. Returns "orange", "yellow", "green", or "grey".
---@param recipe table
---@return string
function CraftSkill:recipeColor(recipe) end

--- Probability (0-1) of a skill-up when crafting this recipe.
---@param recipe table
---@return number
function CraftSkill:skillUpChance(recipe) end

--- Register a specialization branch (no-op if already present).
---@param name string
---@return nil
function CraftSkill:addSpecialization(name) end

--- Return the list of registered specialization branches.
---@return table
function CraftSkill:getSpecializations() end

--- Lock in a chosen specialization. Returns false if already specialised or name unknown.
---@param name string
---@return boolean
function CraftSkill:chooseSpecialization(name) end

--- Return the current specialization (or nil if none).
---@return string|nil
function CraftSkill:getSpecialization() end

--- Return perks available at the current skill level from the perk tree.
---@return table
function CraftSkill:availablePerks() end

--- Computed speed bonus from unlocked perks.
---@return number
function CraftSkill:getSpeedBonus() end

--- Computed quality bonus from unlocked perks.
---@return number
function CraftSkill:getQualityBonus() end

--- Computed yield bonus from unlocked perks.
---@return number
function CraftSkill:getYieldBonus() end

--- Return all job IDs regardless of state.
---@return table
function CraftQueue:ids() end

--- Return IDs of queued (waiting) jobs.
---@return table
function CraftQueue:queuedIds() end

--- Effective level = base level + count of installed attachments.
---@return number
function Station:effectiveLevel() end

--- Effective craft time after applying station efficiency.
---@param recipe table
---@return number
function Station:effectiveTime(recipe) end

--- Return true if the station can process a recipe.
---@param recipe table
---@return boolean
function Station:canProcess(recipe) end

--- Return true if world position is within proximity_radius.
---@param px number
---@param py number
---@return boolean
function Station:isInRange(px, py) end

--- Return the current module slot capacity.
---@return number
function Station:moduleSlotCount() end

--- Set the module slot capacity.
---@param n number
---@return nil
function Station:setModuleSlotCount(n) end

--- Return the module name at a 1-based slot index.
---@param slot number
---@return string|nil
function Station:getModuleAt(slot) end

--- Return all nodes in insertion order.
---@return table
function UpgradeTree:getAllNodes() end

--- Remove modifier by name. Returns true if found.
---@param name string
---@return boolean
function ModifierPool:remove(name) end

--- Return sum of all entry weights.
---@return number
function ModifierPool:getTotalWeight() end

--- Return a copy of the entries list.
---@return table
function ModifierPool:getEntries() end

--- Alias for getEntries (matches Rust get_modifiers).
---@return table
function ModifierPool:getModifiers() end

--- Return the number of entries.
---@return number
function ModifierPool:count() end

--- Get the pool name.
---@return string
function ModifierPool:getName() end

--- Set the pool name.
---@param name string
---@return nil
function ModifierPool:setName(name) end

--- Remove knowledge of a recipe. Returns true if it was known.
---@param recipe_id string
---@return boolean
function RecipeKnowledge:forget(recipe_id) end

--- Enable or disable auto-discover mode.
---@param enabled boolean
---@return nil
function RecipeKnowledge:setAutoDiscover(enabled) end

--- Return true if auto-discover is enabled.
---@return boolean
function RecipeKnowledge:isAutoDiscover() end

--- Wipe all discovered recipes and prototypes.
---@return nil
function RecipeKnowledge:clear() end

--- Create a named group of recipes. Replaces the plain-table version; .ids is kept for backward compat.
---@param name string
---@param ids table|nil
---@return RecipeGroup
function library.crafting.newRecipeGroup(name, ids) end

--- Add a recipe ID (no-op if already present).
---@param recipe_id string
---@return nil
function RecipeGroup:addRecipe(recipe_id) end

--- Remove a recipe ID. Returns true if found.
---@param recipe_id string
---@return boolean
function RecipeGroup:removeRecipe(recipe_id) end

--- Return all recipe IDs.
---@return table
function RecipeGroup:getRecipes() end

--- Return the number of recipes.
---@return number
function RecipeGroup:count() end

--- Check whether a recipe ID is in the group.
---@param recipe_id string
---@return boolean
function RecipeGroup:contains(recipe_id) end

--- Set the icon identifier.
---@param icon string
---@return nil
function RecipeGroup:setIcon(icon) end

--- Get the icon identifier.
---@return string
function RecipeGroup:getIcon() end

--- Set the sort order.
---@param order number
---@return nil
function RecipeGroup:setOrder(order) end

--- Get the sort order.
---@return number
function RecipeGroup:getOrder() end

---@class library.dialog
library.dialog = {}

--- Create a new dialog sequencer. The sequencer runs a list of dialog nodes one at a time, revealing typewriter-style text, pausing for choices, and firing named callbacks. States: "idle"    ÔÇö no script loaded or sequence ended, not started "typing"  ÔÇö revealing the current line character by character "waiting" ÔÇö current line fully revealed, waiting for advance() "choice"  ÔÇö waiting for the player to call choose(index) "paused"  ÔÇö a "wait" node is counting down "done"    ÔÇö sequence finished
---@return table
function library.dialog.newSequencer() end

--- Load a new script, replacing any existing one. Call start() afterwards to begin playback.
---@param nodes table
---@return nil
function seq:load(nodes) end

--- Begin playback from the first node.
---@return nil
function seq:start() end

--- Advance per-frame. Call every frame while isActive() is true.
---@param dt number
---@return nil
function seq:update(dt) end

--- Advance past the current line (when state == "waiting" or "typing"). If typing, skips to full reveal first. If waiting, moves to next node.
---@return nil
function seq:advance() end

--- Skip the entire current line instantly (advances to "waiting").
---@return nil
function seq:skip() end

--- Select a choice option by 1-based index. Only valid when state == "choice".
---@param index number
---@return nil
function seq:choose(index) end

--- Set the typewriter reveal speed.
---@param cps number
---@return nil
function seq:setSpeed(cps) end

--- Get the current reveal speed.
---@return number
function seq:getSpeed() end

--- Get the current state string.
---@return string
function seq:getState() end

--- Returns true while the sequence is in progress (not idle or done).
---@return boolean
function seq:isActive() end

--- Returns true when a choice is pending player input.
---@return boolean
function seq:isWaitingForChoice() end

--- Returns the speaker name of the current "say" node.
---@return string
function seq:currentSpeaker() end

--- Returns the full text of the current "say" node.
---@return string
function seq:currentText() end

--- Returns only the revealed portion of the current text.
---@return string
function seq:revealedText() end

--- Returns the prompt text of the current "choice" node.
---@return string
function seq:getChoiceText() end

--- Returns an array of choice labels for the current "choice" node.
---@return table
function seq:getChoiceLabels() end

--- Register a callback for a named event. Events: "line" (speaker, text), "choice" (), "finished" (), "done" (), "event" (name, data), "typewrite" (char, full_text).
---@param event string
---@param fn function
---@return nil
function seq:on(event, fn) end

--- Unregister all callbacks for a named event.
---@param event string
---@return nil
function seq:off(event) end

--- Return the optional `lurek.patterns` EventBus mirror, or nil when the engine is not present. External systems can subscribe to any of the sequencer's events through the bus without going through `seq:on()`. The canonical event delivery path remains the local handler table, so the bus is purely a parallel observer channel.
---@return table|nil
function seq:getEventBus() end

--- Create a `say` dialog node (spoken line with typewriter reveal).
---@param actor string
---@param text string
---@param opts table
---@return table
function library.dialog.say(actor, text, opts) end

--- Create a `choice` dialog node (branching prompt).
---@param prompt string
---@param options table
---@param opts table
---@return table
function library.dialog.choice(prompt, options, opts) end

--- Create a `wait` dialog node (timed pause).
---@param seconds number
---@param opts table
---@return table
function library.dialog.wait(seconds, opts) end

--- Create an `event` dialog node (named hook signal). When executed, fires `seq:on("event", fn)` with (name, data) then advances.
---@param name string
---@param data any
---@param opts table
---@return table
function library.dialog.event(name, data, opts) end

--- Create a `call` dialog node (inline Lua callback). When executed, calls `fn()` immediately and advances without pausing.
---@param fn function
---@param opts table
---@return table
function library.dialog.call(fn, opts) end

--- Create a `jump` dialog node (label-based control transfer). Execution resumes at the first node in the current script whose `.label` field equals `target`. Unknown targets are silently skipped.
---@param target string
---@param opts table
---@return table
function library.dialog.jump(target, opts) end

---@class library.doll
library.doll = {}

--- Create a new Part (visual element for attaching to a Doll socket). Parts carry texture, transform, colour, flip, draw-order, and arbitrary key-value attributes. Attach to a Doll socket with `doll:attach()`.
---@return Part
function library.doll.newPart() end

--- Texture / Quad Return the texture assigned to this part.
---@return any
function part:getTexture() end

--- Assign a texture to this part.
---@param tex any
---@return nil
function part:setTexture(tex) end

--- Return the texture quad (sub-region) for this part.
---@return any
function part:getQuad() end

--- Set the texture quad (sub-region) for this part.
---@param q any
---@return nil
function part:setQuad(q) end

--- Local Transform Return the local offset of this part from its socket origin.
---@return number
---@return number
function part:getOffset() end

--- Set the local offset of this part from its socket origin.
---@param x number
---@param y number
---@return nil
function part:setOffset(x, y) end

--- Return the local rotation of this part in radians.
---@return number
function part:getRotation() end

--- Set the local rotation of this part in radians.
---@param r number
---@return nil
function part:setRotation(r) end

--- Return the local scale of this part as (scaleX, scaleY).
---@return number
---@return number
function part:getScale() end

--- Set part scale. Passing a single number sets uniform scale.
---@param sx number
---@param sy number
---@return nil
function part:setScale(sx, sy) end

--- Return the render origin (pivot point) of this part.
---@return number
---@return number
function part:getOrigin() end

--- Set the render origin (pivot point) of this part.
---@param ox number
---@param oy number
---@return nil
function part:setOrigin(ox, oy) end

--- Draw Order & Type Return the draw order key for this part.
---@return number
function part:getDrawOrder() end

--- Set part draw order (z-sort key).
---@param n number
---@return nil
function part:setDrawOrder(n) end

--- Return the part type string (used for socket type-filter matching).
---@return string
function part:getPartType() end

--- Set the part type string.
---@param t string
---@return nil
function part:setPartType(t) end

--- Visibility & Appearance Return true if this part is currently visible.
---@return boolean
function part:isVisible() end

--- Set visibility of this part.
---@param v boolean
---@return nil
function part:setVisible(v) end

--- Return the RGBA colour tint of this part.
---@return number
---@return number
---@return number
---@return number
function part:getColor() end

--- Set the RGBA colour tint of this part.
---@param r number
---@param g number
---@param b number
---@param a number
---@return nil
function part:setColor(r, g, b, a) end

--- Return the flip flags for this part.
---@return boolean
---@return boolean
function part:getFlip() end

--- Set horizontal and vertical flip flags.
---@param fx boolean
---@param fy boolean
---@return nil
function part:setFlip(fx, fy) end

--- Behaviour Return true if this part inherits the socket's rotation.
---@return boolean
function part:getFollowsRotation() end

--- Set whether this part inherits the socket's rotation.
---@param f boolean
---@return nil
function part:setFollowsRotation(f) end

--- Attributes (user-defined key-value store) Get the value of a user-defined attribute by key.
---@param key string
---@return any
function part:getAttribute(key) end

--- Set a user-defined attribute value.
---@param key string
---@param val any
---@return nil
function part:setAttribute(key, val) end

--- Return a list of all attribute keys on this part.
---@return table
function part:getAttributeKeys() end

--- Optional physics fixture ref (stored, never called) Return the optional physics fixture reference.
---@return any
function part:getFixture() end

--- Store an optional physics fixture reference on this part.
---@param f any
---@return nil
function part:setFixture(f) end

--- Get the absolute scale magnitude, ignoring flip. Useful when flip is used for mirroring but the caller needs the positive magnitude (e.g. bounding-box calculation).
---@return number
---@return number
function part:getAbsoluteScale() end

--- Get a shallow copy of all attributes.
---@return table
function part:getAttributes() end

--- Create a new DollTemplate (socket layout blueprint). A template defines named sockets at fixed positions and rotations. Each socket has an acceptType filter and a drawOrder for z-sorting.
---@param name string
---@return DollTemplate
function library.doll.newTemplate(name) end

--- Return the template name.
---@return string
function tmpl:getName() end

--- Set the template name.
---@param n string
---@return nil
function tmpl:setName(n) end

--- Add a socket to the template. Returns true on success, or false plus a message if the name is invalid or already registered.
---@param socketName string
---@param acceptType string
---@param x number
---@param y number
---@param rotation number
---@param drawOrder number
---@return boolean
---@return string
function tmpl:addSocket(socketName, acceptType, x, y, rotation, drawOrder) end

--- Remove a socket by name. Returns false if the socket does not exist.
---@param socketName string
---@return boolean
function tmpl:removeSocket(socketName) end

--- Return a copy of the socket definition, or nil if not found.
---@param socketName string
---@return table|nil
function tmpl:getSocket(socketName) end

--- Return an ordered array of socket names.
---@return table
function tmpl:getSocketNames() end

--- Return the number of sockets in this template.
---@return number
function tmpl:getSocketCount() end

--- Internal: iterate raw sockets (used by Doll).
---@return nil
function tmpl:_iterSockets() end

--- Create a new Doll (runtime composite instance of a template). A Doll binds a DollTemplate to a world-space transform and holds Part instances attached to template sockets.
---@param template DollTemplate
---@return Doll
function library.doll.newDoll(template) end

--- Transform Return the world-space position of this doll.
---@return number
---@return number
function doll:getPosition() end

--- Set the world-space position of this doll.
---@param x number
---@param y number
---@return nil
function doll:setPosition(x, y) end

--- Return the world-space rotation of this doll in radians.
---@return number
function doll:getRotation() end

--- Set the world-space rotation of this doll in radians.
---@param r number
---@return nil
function doll:setRotation(r) end

--- Return the world-space scale of this doll.
---@return number
---@return number
function doll:getScale() end

--- Set the world-space scale of this doll.
---@param sx number
---@param sy number
---@return nil
function doll:setScale(sx, sy) end

--- Template Return the DollTemplate this doll was created from.
---@return DollTemplate
function doll:getTemplate() end

--- Visibility Return true if this doll is currently visible.
---@return boolean
function doll:isVisible() end

--- Set the visibility of this doll.
---@param v boolean
---@return nil
function doll:setVisible(v) end

--- Optional body / user data refs Return the optional physics body reference attached to this doll.
---@return any
function doll:getBody() end

--- Store an optional physics body reference on this doll.
---@param b any
---@return nil
function doll:setBody(b) end

--- Return the optional user-data reference on this doll.
---@return any
function doll:getUserData() end

--- Store an optional user-data reference on this doll.
---@param v any
---@return nil
function doll:setUserData(v) end

--- Attach a Part to a named socket. Returns false if socket not found, type mismatch, or invalid args.
---@param socketName string
---@param part Part
---@return boolean
function doll:attach(socketName, part) end

--- Detach the Part from a socket, returning it.
---@param socketName string
---@return Part|nil
function doll:detach(socketName) end

--- Return the Part attached at `socketName`, or nil.
---@param socketName string
---@return Part|nil
function doll:getPartAt(socketName) end

--- Return the socket name the given Part is attached to, or nil.
---@param part Part
---@return string|nil
function doll:findSocket(part) end

--- Detach all parts from all sockets.
---@return nil
function doll:detachAll() end

--- Return an array of socket names that currently have a part attached.
---@return table
function doll:getAttachedSockets() end

--- Return an array of socket names that are currently empty.
---@return table
function doll:getEmptySockets() end

--- Compute world-transform draw list sorted by drawOrder. Each entry: {socketName, part, x, y, rotation, scaleX, scaleY, originX, originY, drawOrder}. **Flip behaviour**: Part flip flags produce negative scale values (e.g. scaleX = -2 when flipX is true and doll+part scale = 2). This is intentional — GPU scale-based mirroring. Use `doll.getAbsoluteScale(entry)` if you need the positive magnitude. **Transform order**: Part offset is rotated by socket rotation before being added to the socket position (socket-local space). The combined offset is then scaled by doll scale and rotated by doll rotation. Does NOT filter by part visibility — caller handles that.
---@return table
function doll:getDrawList() end

--- Deprecated convenience draw shim — retained only as a no-op. The original implementation referenced an undefined global (`lurek`) and a non-existent namespace (`lurek.render`), so the call chain was a silent no-op in every build. Library code must not call rendering APIs directly (per `library.*` conventions), so the correct path now is for the caller to iterate `Doll:getDrawList()` and dispatch the entries to `lurek.render` (or any other renderer) themselves. This method emits a one-time warning on first invocation and then returns immediately. It will be removed in a future major bump.
---@return nil
function doll:draw() end

--- Get the absolute scale magnitude from a draw-list entry. Strips the sign introduced by flip flags, returning positive values.
---@param entry table
---@return number
---@return number
function library.doll.getAbsoluteScale(entry) end

---@class library.economy
library.economy = {}

--- Create a new named resource.
---@param name string
---@param capacity number
---@return Resource
function library.economy.newResource(name, capacity) end

--- Clamp a value to [minimum, capacity]. Delegates to `lurek.math.clamp` when the engine binding is available; falls back to the inline branchy form when running outside Lurek2D.
---@return nil
function Resource:_clamp(v) end

---@return string
function Resource:getName() end

---@return number
function Resource:getValue() end

--- Set the resource value (clamped).
---@param v number
---@return nil
function Resource:setValue(v) end

---@return number
function Resource:getCapacity() end

--- Set maximum capacity. Re-clamps value.
---@param c number
---@return nil
function Resource:setCapacity(c) end

---@return number
function Resource:getMinimum() end

--- Set minimum value. Re-clamps value.
---@param m number
---@return nil
function Resource:setMinimum(m) end

---@return string
function Resource:getOverflow() end

--- Set overflow policy.
---@param p string
---@return nil
function Resource:setOverflow(p) end

---@return number
function Resource:getFlowRate() end

--- Set the per-second flow rate (income).
---@param r number
---@return nil
function Resource:setFlowRate(r) end

---@return number
function Resource:getDecayRate() end

--- Set the per-second flat decay rate.
---@param r number
---@return nil
function Resource:setDecayRate(r) end

---@return number
function Resource:getDecayPercent() end

--- Set the per-second proportional decay (0.1 = 10%/s).
---@param p number
---@return nil
function Resource:setDecayPercent(p) end

---@return number
function Resource:getInterestRate() end

--- Set the per-second proportional interest rate.
---@param r number
---@return nil
function Resource:setInterestRate(r) end

---@return number
function Resource:getUpkeep() end

--- Set the per-second upkeep cost.
---@param u number
---@return nil
function Resource:setUpkeep(u) end

---@return string
function Resource:getGroup() end

--- Set the group tag for this resource.
---@param g string
---@return nil
function Resource:setGroup(g) end

---@return boolean
function Resource:isEnabled() end

--- Enable or disable tick processing.
---@param e boolean
---@return nil
function Resource:setEnabled(e) end

---@return boolean
function Resource:isVisible() end

--- Set the UI visibility hint.
---@param v boolean
---@return nil
function Resource:setVisible(v) end

---@return boolean
function Resource:isLocked() end

--- Lock or unlock add/spend modifications.
---@param l boolean
---@return nil
function Resource:setLocked(l) end

---@return number
function Resource:getReserved() end

---@return number
function Resource:getAvailable() end

--- Net rate per tick (flow - decay - upkeep + interest - proportional_decay). The result is clamped so that applying it for one second will not drive the resource below its minimum.
---@return number
function Resource:getNetRate() end

--- Add amount to the resource. Returns the excess.
---@param amount number
---@return number
function Resource:add(amount) end

--- Spend an amount if available. Returns true on success.
---@param amount number
---@return boolean
function Resource:spend(amount) end

--- Check if the resource can afford the amount.
---@param amount number
---@return boolean
function Resource:canAfford(amount) end

--- Reserve an amount (reduces available without changing value). Reserved is clamped so it cannot exceed the current value.
---@param amount number
---@return nil
function Resource:reserve(amount) end

--- Release a reservation. Clamped to [0, value].
---@param amount number
---@return nil
function Resource:unreserve(amount) end

--- Advance the resource by dt seconds (flow, decay, interest, proportional decay).
---@param dt number
---@return nil
function Resource:tick(dt) end

--- Create a new modifier.
---@param mod_type string
---@param value number
---@param duration number
---@param source string
---@return Modifier
function library.economy.newModifier(mod_type, value, duration, source) end

--- Return the modifier type ("multiply", "add", or "set").
---@return string
function Modifier:getType() end

--- Return the modifier value.
---@return number
function Modifier:getValue() end

--- Set the modifier value.
---@param v number
---@return nil
function Modifier:setValue(v) end

--- Return the total duration (<= 0 = permanent).
---@return number
function Modifier:getDuration() end

--- Return remaining time before expiry.
---@return number
function Modifier:getRemaining() end

--- Return the source tag.
---@return string
function Modifier:getSource() end

--- Return the target identifier.
---@return string
function Modifier:getTarget() end

--- Set the target identifier.
---@param t string
---@return nil
function Modifier:setTarget(t) end

--- Return true if the modifier has expired.
---@return boolean
function Modifier:isExpired() end

--- Return true if the modifier is permanent (duration <= 0).
---@return boolean
function Modifier:isPermanent() end

--- Advance the expiry countdown.
---@param dt number
---@return nil
function Modifier:update(dt) end

--- Create a conversion rule.
---@param from string
---@param to string
---@param rate number
---@return ConversionRule
function library.economy.newConversionRule(from, to, rate) end

--- Return the source resource name.
---@return string
function ConversionRule:getFrom() end

--- Return the destination resource name.
---@return string
function ConversionRule:getTo() end

--- Return the base conversion rate.
---@return number
function ConversionRule:getRate() end

--- Set the base conversion rate.
---@param r number
---@return nil
function ConversionRule:setRate(r) end

--- Return the fee applied per conversion.
---@return number
function ConversionRule:getFee() end

--- Set the fee applied per conversion.
---@param f number
---@return nil
function ConversionRule:setFee(f) end

--- Return the cooldown duration in seconds.
---@return number
function ConversionRule:getCooldown() end

--- Set the cooldown duration in seconds.
---@param c number
---@return nil
function ConversionRule:setCooldown(c) end

--- Return the minimum allowed conversion amount.
---@return number
function ConversionRule:getMinAmount() end

--- Set the minimum allowed conversion amount.
---@param m number
---@return nil
function ConversionRule:setMinAmount(m) end

--- Return the maximum allowed conversion amount.
---@return number
function ConversionRule:getMaxAmount() end

--- Set the maximum allowed conversion amount.
---@param m number
---@return nil
function ConversionRule:setMaxAmount(m) end

--- Return true if the rule is currently on cooldown.
---@return boolean
function ConversionRule:isOnCooldown() end

--- Reset the cooldown timer to zero.
---@return nil
function ConversionRule:resetCooldown() end

--- Trigger the cooldown period.
---@return nil
function ConversionRule:startCooldown() end

--- Advance the cooldown timer.
---@param dt number
---@return nil
function ConversionRule:updateCooldown(dt) end

--- Add a modifier to this rule.
---@param m Modifier
---@return nil
function ConversionRule:addModifier(m) end

--- Remove a modifier by 1-based index. Returns true if removed.
---@param index number
---@return boolean
function ConversionRule:removeModifier(index) end

--- Return the modifier array.
---@return table
function ConversionRule:getModifiers() end

--- Clear all modifiers from this rule.
---@return nil
function ConversionRule:clearModifiers() end

--- Compute effective conversion rate after applying modifiers. Modifier application order: if any non-expired "set" modifier exists, the last one wins immediately (short-circuits add/multiply computation). Otherwise: additive modifiers sum onto the base rate, then multiplicative modifiers scale the result.
---@return number
function ConversionRule:effectiveRate() end

--- Create a new resource manager.
---@return ResourceManager
function library.economy.newManager() end

--- Return (or lazily create) an optional `lurek.patterns` EventBus that callers can subscribe to for transaction-style notifications. Returns nil when the engine binding is unavailable. The library does not auto-emit events on this bus — callers may emit on it from their own wrappers without breaking pure-Lua tests.
---@return table|nil
function ResourceManager:getEventBus() end

--- Create (or return existing) resource.
---@param name string
---@param capacity number
---@return Resource
function ResourceManager:newResource(name, capacity) end

---@param name string
---@return Resource|nil
function ResourceManager:getResource(name) end

---@param name string
---@return boolean
function ResourceManager:hasResource(name) end

---@return table
function ResourceManager:getResourceNames() end

--- Remove a resource by name.
---@param name string
---@return nil
function ResourceManager:removeResource(name) end

--- Tick all enabled resources and advance conversion rule cooldowns / modifiers.
---@param dt number
---@return nil
function ResourceManager:tick(dt) end

--- Turn: equivalent to tick(1.0).
---@return nil
function ResourceManager:turn() end

--- Add a conversion rule.
---@param rule ConversionRule
---@return nil
function ResourceManager:addConversionRule(rule) end

---@return table
function ResourceManager:getConversionRules() end

--- Convert resources using the first matching rule.
---@param from string
---@param to string
---@param amount number
---@return boolean
function ResourceManager:convert(from, to, amount) end

--- Direct two-way exchange between two managers (atomic).
---@param other ResourceManager
---@param give_name string
---@param give_amount number
---@param get_name string
---@param get_amount number
---@return boolean
function ResourceManager:exchange(other, give_name, give_amount, get_name, get_amount) end

--- Sum of values for all resources in a group.
---@param group string
---@return number
function ResourceManager:totalByGroup(group) end

--- Percent full (0-100) for a resource, 0 if capacity <= 0.
---@param name string
---@return number
function ResourceManager:getPercent(name) end

--- Is the resource at capacity?
---@param name string
---@return boolean
function ResourceManager:isFull(name) end

--- Is the resource at minimum?
---@param name string
---@return boolean
function ResourceManager:isEmpty(name) end

--- Check if all resources in the table can be afforded.
---@param needs table
---@return boolean
function ResourceManager:canAffordAll(needs) end

--- Atomically spend all resources in the table.
---@param needs table
---@return boolean
function ResourceManager:spendAll(needs) end

--- Clear all resources and conversion rules.
---@return nil
function ResourceManager:reset() end

--- Return the current value of a named resource (0 if not found).
---@param name string
---@return number
function ResourceManager:getValue(name) end

--- Set the value of a named resource (clamped).
---@param name string
---@param v number
---@return nil
function ResourceManager:setValue(name, v) end

--- Return the capacity of a named resource.
---@param name string
---@return number
function ResourceManager:getCapacity(name) end

--- Set the capacity of a named resource.
---@param name string
---@param c number
---@return nil
function ResourceManager:setCapacity(name, c) end

--- Return the minimum value of a named resource.
---@param name string
---@return number
function ResourceManager:getMinimum(name) end

--- Set the minimum value of a named resource.
---@param name string
---@param m number
---@return nil
function ResourceManager:setMinimum(name, m) end

--- Return the flow rate of a named resource.
---@param name string
---@return number
function ResourceManager:getFlowRate(name) end

--- Set the flow rate of a named resource.
---@param name string
---@param rate number
---@return nil
function ResourceManager:setFlowRate(name, rate) end

--- Return the flat decay rate of a named resource.
---@param name string
---@return number
function ResourceManager:getDecayRate(name) end

--- Set the flat decay rate of a named resource.
---@param name string
---@param rate number
---@return nil
function ResourceManager:setDecayRate(name, rate) end

--- Return the proportional decay rate of a named resource.
---@param name string
---@return number
function ResourceManager:getDecayPercent(name) end

--- Set the proportional decay rate of a named resource.
---@param name string
---@param pct number
---@return nil
function ResourceManager:setDecayPercent(name, pct) end

--- Return the interest rate of a named resource.
---@param name string
---@return number
function ResourceManager:getInterestRate(name) end

--- Set the interest rate of a named resource.
---@param name string
---@param rate number
---@return nil
function ResourceManager:setInterestRate(name, rate) end

--- Return the upkeep cost of a named resource.
---@param name string
---@return number
function ResourceManager:getUpkeep(name) end

--- Set the upkeep cost of a named resource.
---@param name string
---@param u number
---@return nil
function ResourceManager:setUpkeep(name, u) end

--- Return the net rate (flow - decay - upkeep + interest - decay%) of a named resource.
---@param name string
---@return number
function ResourceManager:getNetRate(name) end

--- Return the overflow policy of a named resource.
---@param name string
---@return string
function ResourceManager:getOverflow(name) end

--- Set the overflow policy of a named resource.
---@param name string
---@param policy string
---@return nil
function ResourceManager:setOverflow(name, policy) end

--- Return the group tag of a named resource.
---@param name string
---@return string
function ResourceManager:getGroup(name) end

--- Set the group tag of a named resource.
---@param name string
---@param g string
---@return nil
function ResourceManager:setGroup(name, g) end

--- Return whether tick processing is enabled for a named resource.
---@param name string
---@return boolean
function ResourceManager:isEnabled(name) end

--- Enable or disable tick processing for a named resource.
---@param name string
---@param v boolean
---@return nil
function ResourceManager:setEnabled(name, v) end

--- Return the UI visibility hint of a named resource.
---@param name string
---@return boolean
function ResourceManager:isVisible(name) end

--- Set the UI visibility hint of a named resource.
---@param name string
---@param v boolean
---@return nil
function ResourceManager:setVisible(name, v) end

--- Return whether a named resource is locked against modifications.
---@param name string
---@return boolean
function ResourceManager:isLocked(name) end

--- Lock or unlock add/spend for a named resource.
---@param name string
---@param v boolean
---@return nil
function ResourceManager:setLocked(name, v) end

--- Add an amount to a named resource. Returns excess that did not fit.
---@param name string
---@param amount number
---@return number
function ResourceManager:add(name, amount) end

--- Spend an amount from a named resource. Returns true on success.
---@param name string
---@param amount number
---@return boolean
function ResourceManager:spend(name, amount) end

--- Return true if the named resource has enough available funds.
---@param name string
---@param amount number
---@return boolean
function ResourceManager:canAfford(name, amount) end

--- Return the available amount (value - reserved) of a named resource.
---@param name string
---@return number
function ResourceManager:getAvailable(name) end

--- Increase the reservation on a named resource.
---@param name string
---@param amount number
---@return nil
function ResourceManager:reserveAmount(name, amount) end

--- Decrease the reservation on a named resource (floored at 0).
---@param name string
---@param amount number
---@return nil
function ResourceManager:unreserveAmount(name, amount) end

--- Return the reserved amount of a named resource.
---@param name string
---@return number
function ResourceManager:getReserved(name) end

---@class library.inventory
library.inventory = {}

--- Create a lightweight inventory item definition. Each item has a type, weight, size, stack limit, tag set, and a property map.
---@param type_name string
---@return table
function library.inventory.newItem(type_name) end

--- Return the type name.
---@return string
function item:getType() end

--- Return item weight.
---@return number
function item:getWeight() end

--- Set physical weight (must be non-negative).
---@param w number
---@return nil
function item:setWeight(w) end

--- Return grid width.
---@return number
function item:getSizeW() end

--- Return grid height.
---@return number
function item:getSizeH() end

--- Set grid size (both dimensions clamped to >= 1).
---@param w number
---@param h number
---@return nil
function item:setSize(w, h) end

--- Return maximum items per stack.
---@return number
function item:getStackLimit() end

--- Set maximum stack size (clamped to >= 1).
---@param n number
---@return nil
function item:setStackLimit(n) end

--- Return true if the item has the given tag.
---@param tag string
---@return boolean
function item:hasTag(tag) end

--- Add a tag (no-op if already present).
---@param tag string
---@return nil
function item:addTag(tag) end

--- Remove a tag. Returns true if tag existed.
---@param tag string
---@return boolean
function item:removeTag(tag) end

--- Return all tag names as an array.
---@return table
function item:getTags() end

--- Set a generic property.
---@param key string
---@param val any
---@return nil
function item:setProperty(key, val) end

--- Get a generic property.
---@param key string
---@return any
function item:getProperty(key) end

--- Deep-copy this item definition. TODO(P4 lift): once `lurek.data.deepCopy` ships, replace the manual field-by-field rebuild below with `_data_deep_copy(item)` so that arbitrary user-attached fields are preserved automatically.
---@return table
function item:clone() end

--- Create a counted stack of a single item type.
---@param inv_item table
---@param quantity number
---@param max_quantity number
---@return table
function library.inventory.newItemStack(inv_item, quantity, max_quantity) end

--- Return the underlying InvItem.
---@return table
function stack:getItem() end

--- Return current quantity.
---@return number
function stack:getQuantity() end

--- Directly set quantity (clamped 0..max).
---@param n number
---@return nil
function stack:setQuantity(n) end

--- Return max quantity.
---@return number
function stack:getStackLimit() end

--- Return true when stack holds max items.
---@return boolean
function stack:isFull() end

--- Return true when stack is empty.
---@return boolean
function stack:isEmpty() end

--- Add n items. Returns overflow (items that did not fit).
---@param n number
---@return number
function stack:add(n) end

--- Remove n items. Returns count actually removed.
---@param n number
---@return number
function stack:remove(n) end

--- Split n items off into a new stack. Returns nil if n invalid.
---@param n number
---@return table|nil
function stack:split(n) end

--- Merge another stack into this one. Returns leftover count.
---@param other table
---@return number
function stack:merge(other) end

--- Create a single inventory slot (holds one ItemStack).
---@param slot_type string
---@param state string
---@return table
function library.inventory.newSlot(slot_type, state) end

--- Return slot type filter.
---@return string
function slot:getSlotType() end

--- Return current state.
---@return string
function slot:getState() end

--- Set state.
---@param s string
---@return nil
function slot:setState(s) end

--- Return true if no item is held.
---@return boolean
function slot:isEmpty() end

--- Return the held ItemStack, or nil.
---@return table|nil
function slot:getStack() end

--- Return the held InvItem (unwrapped), or nil.
---@return table|nil
function slot:getItem() end

--- Return true if the item fits size constraints and type filter. Items are accepted if the slot type is "any", or the item type matches the slot type, or the item carries a tag matching the slot type.
---@param item table
---@return boolean
function slot:canAccept(item) end

--- Place an ItemStack. Returns false if item not accepted.
---@param s table
---@return boolean
function slot:setStack(s) end

--- Remove and return the held stack.
---@return table|nil
function slot:takeStack() end

--- Clear the slot.
---@return nil
function slot:clear() end

--- Create a named container managing a list of slots. For expandable mode, `max_slots` caps how far `expand()` can grow.
---@param name string
---@param mode string
---@param slot_count number
---@param max_slots number
---@return table
function library.inventory.newContainer(name, mode, slot_count, max_slots) end

--- Return the container name.
---@return string
function container:getName() end

--- Return the container mode string.
---@return string
function container:getMode() end

--- Return the number of slots.
---@return number
function container:slotCount() end

--- Return max slot count. 0 = unbounded.
---@return number
function container:getCapacity() end

--- Set weight limit (must be non-negative). 0 = unlimited.
---@param w number
---@return nil
function container:setWeightLimit(w) end

--- Return weight limit. 0 = unlimited.
---@return number
function container:getWeightLimit() end

--- Return current total weight.
---@return number
function container:getCurrentWeight() end

--- Alias for getCurrentWeight.
---@return number
function container:totalWeight() end

--- Return true if all slots are occupied (fixed/expandable) or weight limit reached.
---@return boolean
function container:isFull() end

--- Get a slot by 1-based index.
---@param idx number
---@return table|nil
function container:getSlot(idx) end

--- Return all slots array.
---@return table
function container:getSlots() end

--- Add slot (respects mode limits).
---@param sl table
---@return nil
function container:addSlot(sl) end

--- Set the upper slot capacity (expandable mode only). Clamped so it cannot be less than the current slot count.
---@param n number
---@return nil
function container:setCapacity(n) end

--- Expand by n new empty slots (expandable mode only). Returns true if any added. Respects the max-slot capacity; stops adding once the limit is reached.
---@param n number
---@return boolean
function container:expand(n) end

--- Auto-place item quantity. Merges into ALL existing matching stacks first, then fills empty slots. For unlimited containers, auto-grows as needed.
---@param inv_item table
---@param quantity number
---@return boolean
function container:addItem(inv_item, quantity) end

--- Count all items of a given type across all slots.
---@param type_name string
---@return number
function container:countItem(type_name) end

--- Return true if >= qty of type_name present.
---@param type_name string
---@param qty number
---@return boolean
function container:hasItem(type_name, qty) end

--- Remove up to qty items of type_name. Returns count removed.
---@param type_name string
---@param qty number
---@return number
function container:removeItem(type_name, qty) end

--- Return all items with the given tag.
---@param tag string
---@return table
function container:findByTag(tag) end

--- Return a summary list of {type_name, quantity} aggregated across slots.
---@return table
function container:toItemList() end

--- Remove the slot at a 1-based index. Shifts subsequent slots down.
---@param idx number
---@return boolean
function container:removeSlot(idx) end

--- Create a named item set (bonus condition). All requirements must be satisfied simultaneously for the set to be active.
---@param name string
---@return table
function library.inventory.newItemSet(name) end

--- Return the set name.
---@return string
function iset:getName() end

--- Add a requirement: at least one equip slot must hold an item with `tag`.
---@param tag string
---@param slot_filter string
---@return nil
function iset:addRequirement(tag, slot_filter) end

--- Return all requirements as array of {tag, slot_filter}.
---@return table
function iset:getRequirements() end

--- Check if all requirements are satisfied given an equip_slots table {name -> Slot}.
---@param equip_slots table
---@return boolean
function iset:isSatisfied(equip_slots) end

--- Create a top-level inventory managing containers, equip slots, item sets, and subsystem flags.
---@return table
function library.inventory.newInventory() end

--- Return (or lazily create) an optional `lurek.patterns` EventBus that callers can subscribe to for inventory change notifications. Returns nil when the engine binding is unavailable. The library does not auto-emit events on this bus; callers may emit on it from their own wrappers without affecting baseline test behaviour.
---@return table|nil
function inv:getEventBus() end

--- Register a container. Replaces any existing container with the same name.
---@param name string
---@param container table
---@return nil
function inv:addContainer(name, container) end

--- Get a container by name.
---@param name string
---@return table|nil
function inv:getContainer(name) end

--- Remove a container. Returns true if it existed.
---@param name string
---@return boolean
function inv:removeContainer(name) end

--- Return container names in insertion order.
---@return table
function inv:containerNames() end

--- Add or replace a named equip slot.
---@param name string
---@param slot table
---@return nil
function inv:addEquipSlot(name, slot) end

--- Get an equip slot by name.
---@param name string
---@return table|nil
function inv:getEquipSlot(name) end

--- Remove an equip slot. Returns true if it existed.
---@param name string
---@return boolean
function inv:removeEquipSlot(name) end

--- Return equip slot names in insertion order.
---@return table
function inv:equipSlotNames() end

--- Equip an ItemStack into the named slot. Returns false if slot missing or item rejected.
---@param slot_name string
---@param stack table
---@return boolean
function inv:equip(slot_name, stack) end

--- Unequip a slot and return its InvItem (not the full stack). Returns nil if empty.
---@param slot_name string
---@return table|nil
function inv:unequip(slot_name) end

--- Register an item set.
---@param iset table
---@return nil
function inv:addItemSet(iset) end

--- Return all registered item sets.
---@return table
function inv:getItemSets() end

--- Return only the currently active item sets (all requirements met).
---@return table
function inv:getActiveSets() end

--- Enable a named subsystem ("weight", "size", "stacking", "sets").
---@param name string
---@return nil
function inv:enableSubsystem(name) end

--- Disable a named subsystem.
---@param name string
---@return nil
function inv:disableSubsystem(name) end

--- Return true if the named subsystem is active.
---@param name string
---@return boolean
function inv:isSubsystemEnabled(name) end

--- Count items of a type across ALL containers.
---@param type_name string
---@return number
function inv:countItem(type_name) end

--- Return true if total count >= qty across all containers.
---@param type_name string
---@param qty number
---@return boolean
function inv:hasItem(type_name, qty) end

--- Remove qty items of type_name from whichever containers have them.
---@param type_name string
---@param qty number
---@return boolean
function inv:removeFromAny(type_name, qty) end

--- Transfer a stack from one container slot to another (1-based indices).
---@param from_name string
---@param from_idx number
---@param to_name string
---@param to_idx number
---@return boolean
function inv:transfer(from_name, from_idx, to_name, to_idx) end

--- Split `quantity` items from the stack at `slot_idx` in `container_name` into the first empty compatible slot in the same container. Returns true if the split succeeded.
---@param container_name string
---@param slot_idx number
---@param quantity number
---@return boolean
function inv:splitStack(container_name, slot_idx, quantity) end

--- Merge the stack at `from_slot` into `to_slot` within `container_name`. If the destination is empty, the source stack is moved into it. Returns true if any items were merged or moved.
---@param container_name string
---@param from_slot number
---@param to_slot number
---@return boolean
function inv:mergeStacks(container_name, from_slot, to_slot) end

--- Swap items between two container slots (may be in different containers). Returns true on success.
---@param container_a string
---@param slot_a number
---@param container_b string
---@param slot_b number
---@return boolean
function inv:swap(container_a, slot_a, container_b, slot_b) end

---@class library.item
library.item = {}

--- Clear all registered item types (useful between tests). **Note**: Already-created Item objects retain their stats, tags, and category from the definition that existed at creation time.  Clearing the registry does NOT retroactively change existing items.
---@return nil
function library.item.clearTypes() end

--- Register a new item type definition.
---@param name string
---@param def table
---@return nil
function library.item.defineType(name, def) end

--- Retrieve a registered type definition, or nil.
---@param name string
---@return table|nil
function library.item.getType(name) end

--- Return a sorted list of all registered type names.
---@return table
function library.item.getTypeNames() end

--- Create a new item instance. Stats and tags are copied from the type definition; modifications are per-instance. If `type_name` is not registered, a warning is logged and the item receives default `misc` category with empty stats/tags.
---@param type_name string
---@return table
function library.item.newItem(type_name) end

--- Return the type name.
---@return string
function it:getType() end

--- Return the category from the type registry.
---@return string
function it:getCategory() end

--- Return the value of a stat, or nil if not set.
---@param key string
---@return number|nil
function it:getStat(key) end

--- Set or override a stat value.
---@param key string
---@param val number
---@return nil
function it:setStat(key, val) end

--- Add delta to an existing stat (creates stat at delta if absent).
---@param key string
---@param delta number
---@return nil
function it:addStat(key, delta) end

--- Remove a stat entirely.
---@param key string
---@return nil
function it:removeStat(key) end

--- Return all current stats as a shallow copy.
---@return table
function it:getStats() end

--- Return true if this item has the given tag.
---@param tag string
---@return boolean
function it:hasTag(tag) end

--- Add a tag (no-op if already present).
---@param tag string
---@return nil
function it:addTag(tag) end

--- Remove a tag. Returns true if tag existed.
---@param tag string
---@return boolean
function it:removeTag(tag) end

--- Return all tag names as a sorted array.
---@return table
function it:getTags() end

--- Set a metadata value.
---@param key string
---@param val any
---@return nil
function it:setMeta(key, val) end

--- Get a metadata value, or nil.
---@param key string
---@return any
function it:getMeta(key) end

--- Set the owner reference.
---@param owner any
---@return nil
function it:setOwner(owner) end

--- Return the owner reference.
---@return any
function it:getOwner() end

--- Return the display name (seeds from type def; may differ from type name).
---@return string
function it:getName() end

--- Set the display name.
---@param n string
---@return nil
function it:setName(n) end

--- Return the current slot/position name.
---@return string
function it:getSlot() end

--- Set the slot/position name.
---@param s string
---@return nil
function it:setSlot(s) end

--- Get a named integer counter (0 if not set).
---@param key string
---@return number
function it:getCounter(key) end

--- Set a named integer counter.
---@param key string
---@param val number
---@return nil
function it:setCounter(key, val) end

--- Add delta to a named counter and return the new value.
---@param key string
---@param delta number
---@return number
function it:addCounter(key, delta) end

--- Remove a named counter entry.
---@param key string
---@return nil
function it:removeCounter(key) end

--- Return all counters as a shallow copy.
---@return table
function it:getCounters() end

--- Deep-copy this item instance (stats, tags, meta, counters, slot, name — NOT owner). TODO(P4 lift): replace with `lurek.data.deepCopy(it)` once that helper ships (P4 lift candidate). The local fallback below preserves identical behaviour and is safe on both LuaJIT and Lua 5.4.
---@return table
function it:clone() end

--- Create a named stack with optional capacity limit. Acts as both a LIFO stack and a positional list.
---@param name string
---@param capacity number
---@return table
function library.item.newStack(name, capacity) end

--- Return the stack name.
---@return string
function stack:getName() end

--- Return number of items.
---@return number
function stack:size() end

--- Return capacity (0 = unlimited).
---@return number
function stack:getCapacity() end

--- Set or update capacity (0 = unlimited).
---@param n number
---@return nil
function stack:setCapacity(n) end

--- Return true if at capacity.
---@return boolean
function stack:isFull() end

--- Remove all items.
---@return nil
function stack:clear() end

--- Push item onto top (returns false if capacity full).
---@param it table
---@return boolean
function stack:push(it) end

--- Push item onto bottom. Returns false if full.
---@param it table
---@return boolean
function stack:pushBottom(it) end

--- Pop and return top item, or nil if empty.
---@return table|nil
function stack:pop() end

--- Alias for pop.
---@return table|nil
function stack:popTop() end

--- Remove and return bottom item, or nil if empty.
---@return table|nil
function stack:popBottom() end

--- Peek at bottom item without removing it.
---@return table|nil
function stack:peekBottom() end

--- Peek at top item without removing it.
---@return table|nil
function stack:peek() end

--- Alias for peek (slot compat).
---@return table|nil
function stack:getItem() end

--- Peek at item at 1-based index without removing. Returns nil if out of range.
---@param idx number
---@return table|nil
function stack:peekAt(idx) end

--- Remove and return item at 1-based index. Returns nil if out of range.
---@param idx number
---@return table|nil
function stack:removeAt(idx) end

--- Insert item at 1-based position. Returns false if full or index invalid.
---@param idx number
---@param it table
---@return boolean
function stack:insertAt(idx, it) end

--- Return the first item for which predicate(item) is true. Nil if none.
---@param pred function
---@return table|nil
function stack:findFirst(pred) end

--- Return a shallow copy of all items (bottom to top).
---@return table
function stack:getItems() end

--- Return true if the stack has no items.
---@return boolean
function stack:isEmpty() end

--- Pop n items from the top. Returns array of items (may be shorter if stack runs out).
---@param n number
---@return table
function stack:popMany(n) end

--- Move item at index `from` to index `to` (both 1-based). Returns false if invalid.
---@param from number
---@param to number
---@return boolean
function stack:moveWithin(from, to) end

--- Return all items whose type matches. Uses item:getType().
---@param type_name string
---@return table
function stack:searchByType(type_name) end

--- Return all items that have the given tag.
---@param tag string
---@return table
function stack:searchByTag(tag) end

--- Return all items in the given category.
---@param cat string
---@return table
function stack:searchByCategory(cat) end

--- Return first item with the given type (or nil).
---@param type_name string
---@return table|nil
function stack:findByType(type_name) end

--- Return first item with the given tag (or nil).
---@param tag string
---@return table|nil
function stack:findByTag(tag) end

--- Count items with the given type.
---@param type_name string
---@return number
function stack:countByType(type_name) end

--- Count items in the given category.
---@param cat string
---@return number
function stack:countByCategory(cat) end

--- Count items with the given tag.
---@param tag string
---@return number
function stack:countByTag(tag) end

--- Sort items ascending by a numeric stat. Items without the stat sort last.
---@param stat string
---@return nil
function stack:sortByStat(stat) end

--- Sort items descending by a numeric stat.
---@param stat string
---@return nil
function stack:sortByStatDesc(stat) end

--- Sort items by category (alphabetical).
---@return nil
function stack:sortByCategory() end

--- Sort items by type name (alphabetical).
---@return nil
function stack:sortByName() end

--- Shuffle items in-place (Fisher-Yates). TODO(P4 lift): replace with `lurek.math.shuffle(_items)` once that helper ships (P4 lift candidate; would also fix the LuaJIT vs Lua 5.4 RNG divergence noted in P4_lift_candidates.md).
---@return nil
function stack:shuffle() end

--- Return the type names of the top n items (without removing).
---@param n number
---@return table
function stack:peekTopNTypes(n) end

--- Create a weighted loot pool. Supports weighted draw, bulk multi-draw, and unique-draw operations.
---@return table
function library.item.newItemPool() end

--- Return number of entries.
---@return number
function pool:size() end

--- Return true if the pool has no entries.
---@return boolean
function pool:isEmpty() end

--- Return the sum of all entry weights.
---@return number
function pool:totalWeight() end

--- Return all entries as array of {type_name, weight}.
---@return table
function pool:getEntries() end

--- Add a type with a given weight. If type already present, adds another entry.
---@param type_name string
---@param weight number
---@return nil
function pool:addType(type_name, weight) end

--- Update the weight of the first matching entry. Returns false if not found.
---@param type_name string
---@param weight number
---@return boolean
function pool:setWeight(type_name, weight) end

--- Remove the first entry of type_name. Returns false if not found.
---@param type_name string
---@return boolean
function pool:remove(type_name) end

--- Draw one random item (weighted). Returns nil if pool is empty or total weight is zero.
---@return table|nil
function pool:draw() end

--- Draw n items (with replacement). Entries from an empty pool are skipped (nil).
---@param n number
---@return table
function pool:drawTypes(n) end

--- Draw up to n unique type names (no type drawn twice), returns array of Items. If n exceeds the number of distinct types in the pool, returns all distinct types.
---@param n number
---@return table
function pool:drawUniqueTypes(n) end

--- Create a stack builder for constructing stacks from a recipe list.
---@return table
function library.item.newStackBuilder() end

--- Add items of a type to the recipe.
---@param type_name string
---@param count number
---@return nil
function builder:add(type_name, count) end

--- Add items with per-item stat overrides and extra tags. Unlike add(), overrides are applied immediately to pre-built item instances.
---@param type_name string
---@param count number
---@param stat_overrides table
---@param extra_tags table
---@return nil
function builder:addWith(type_name, count, stat_overrides, extra_tags) end

--- Enable or disable Fisher-Yates shuffle after build.
---@param enabled boolean
---@return nil
function builder:setShuffleOnBuild(enabled) end

--- Require that a specific type appears at least once.
---@param type_name string
---@return nil
function builder:requireType(type_name) end

--- Ban a specific type from appearing.
---@param type_name string
---@return nil
function builder:banType(type_name) end

--- Remove a ban on a type.
---@param type_name string
---@return nil
function builder:removeBannedType(type_name) end

--- Build the stack from recipe entries plus addWith items. Applies shuffleOnBuild if enabled.
---@param name string
---@return table
function builder:build(name) end

--- Validate the current recipe + addWith items against required/banned constraints. Returns nil on success, or an error string on failure.
---@return string|nil
function builder:validateEntries() end

--- Validate a pre-built stack against required/banned constraints. Returns nil on success, or an error string on failure.
---@param stack table
---@return string|nil
function builder:validateStack(stack) end

--- Build the stack with a custom name (alias for build).
---@param name string
---@return table
function builder:buildNamed(name) end

--- Create a bounded event history for stack operations.
---@param max_entries number
---@return table
function library.item.newStackHistory(max_entries) end

--- Record a push action.
---@param source string
---@param item_type string
---@param size_after number
---@return nil
function history:recordPush(source, item_type, size_after) end

--- Record a pop action.
---@param source string
---@param item_type string
---@param size_after number
---@return nil
function history:recordPop(source, item_type, size_after) end

--- Record a clear action.
---@param source string
---@return nil
function history:recordClear(source) end

--- Record a custom event.
---@param source string
---@param label string
---@param size_after number
---@return nil
function history:recordCustom(source, label, size_after) end

--- Return all recorded entries (oldest first). Each entry has: action, source, item_type, size_after.
---@return table
function history:entries() end

--- Return the last n entries, or all if n > count.
---@param n number
---@return table
function history:getLastN(n) end

--- Clear all log entries.
---@return nil
function history:clear() end

--- Return number of entries.
---@return number
function history:count() end

--- Return true if no events have been recorded.
---@return boolean
function history:isEmpty() end

--- Return the most recent entry, or nil if empty.
---@return table|nil
function history:last() end

--- Return all entries matching a specific source name.
---@param source string
---@return table
function history:entriesFor(source) end

--- Create a named-stack manager.
---@return table
function library.item.newStackManager() end

--- Register a stack.
---@param name string
---@param stack table
---@return nil
function manager:addStack(name, stack) end

--- Retrieve a stack by name.
---@param name string
---@return table|nil
function manager:getStack(name) end

--- Remove a stack. Returns true if existed.
---@param name string
---@return boolean
function manager:removeStack(name) end

--- Return all registered stack names.
---@return table
function manager:keys() end

--- Return true if a stack with this name exists.
---@param name string
---@return boolean
function manager:hasStack(name) end

--- Create and register a new empty unlimited stack.
---@param name string
---@return nil
function manager:createStack(name) end

--- Create and register a new empty stack with a capacity limit.
---@param name string
---@param capacity number
---@return nil
function manager:createStackCapped(name, capacity) end

--- Return total number of items across all stacks.
---@return number
function manager:totalItems() end

--- Move item at 1-based index from one stack to the top of another. Returns the moved item on success, or nil plus an error string on failure.
---@param from string
---@param index number
---@param to string
---@return table|nil
---@return string|nil
function manager:moveItem(from, index, to) end

--- Move the first item of a given type from one stack to the top of another. Returns the moved item on success, or nil plus an error string on failure.
---@param from string
---@param item_type string
---@param to string
---@return table|nil
---@return string|nil
function manager:moveItemByType(from, item_type, to) end

--- Move the top item from one stack to the top of another. Returns the moved item on success, or nil plus an error string on failure.
---@param from string
---@param to string
---@return table|nil
---@return string|nil
function manager:moveTop(from, to) end

--- Create a named slot with optional capacity limit. A slot is a bounded named position that holds zero or more items.
---@param name string
---@param capacity number
---@return table
function library.item.newSlot(name, capacity) end

--- Return the slot name.
---@return string
function slot:getName() end

--- Return number of items in the slot.
---@return number
function slot:size() end

--- Return true if the slot is empty.
---@return boolean
function slot:isEmpty() end

--- Return true if the slot is at capacity.
---@return boolean
function slot:isFull() end

--- Return capacity (0 = unlimited).
---@return number
function slot:getCapacity() end

--- Set or update capacity (0 = unlimited).
---@param n number
---@return nil
function slot:setCapacity(n) end

--- Add an item to the slot. Returns true on success, false if at capacity.
---@param it table
---@return boolean
function slot:push(it) end

--- Remove and return the last item, or nil if empty.
---@return table|nil
function slot:pop() end

--- Remove and return the item at 1-based index, or nil if out of range.
---@param index number
---@return table|nil
function slot:removeAt(index) end

--- Peek at the last item without removing it.
---@return table|nil
function slot:peek() end

--- Peek at item at 1-based index without removing it.
---@param index number
---@return table|nil
function slot:peekAt(index) end

--- Remove all items and return them as an array.
---@return table
function slot:clear() end

--- Return a shallow copy of all items.
---@return table
function slot:items() end

--- Return true if any item has the given tag.
---@param tag string
---@return boolean
function slot:hasItemWithTag(tag) end

--- Return true if any item is of the given type.
---@param item_type string
---@return boolean
function slot:hasItemOfType(item_type) end

--- Return 0-based indices of the top N items ranked by a stat (descending).
---@param items table
---@param stat string
---@param n number
---@return table
function library.item.findNOfStat(items, stat, n) end

--- Group items by a stat value. Returns map {value -> array of Items}. Items without the stat are grouped under the key false.
---@param items table
---@param stat_key string
---@return table
function library.item.groupByStat(items, stat_key) end

--- Group items by tag prefix. Returns map {prefix_value -> array of Items}. A tag matches if it starts with `prefix` (e.g. prefix "tier:" matches "tier:1", "tier:2"). Items with no matching tag go under key "".
---@param items table
---@param prefix string
---@return table
function library.item.groupByTagPrefix(items, prefix) end

--- Find runs (consecutive sequences) of items sharing the same stat value. Returns array of {value, start_idx, length} (1-based start_idx).
---@param items table
---@param stat_key string
---@return table
function library.item.findSequences(items, stat_key) end

--- Group items by category. Returns table: category -> {Item, ...}.
---@param items table
---@return table
function library.item.groupByCategory(items) end

--- Return items where getStat(stat) >= n.
---@param items table
---@param stat string
---@param n number
---@return table
function library.item.findAtLeastNOfStat(items, stat, n) end

--- Group items by shared tag prefix. Returns table: prefix -> {Item, ...}. A "tag group" is a set of items that share at least one tag.
---@param items table
---@return table
function library.item.findTagGroups(items) end

--- Return 1-based indices sorted by a stat.
---@param items table
---@param stat string
---@param ascending boolean
---@return table
function library.item.sortedIndicesByStat(items, stat, ascending) end

--- Return 1-based indices sorted by category (alphabetical).
---@param items table
---@return table
function library.item.sortedIndicesByCategory(items) end

---@class library.lobby
library.lobby = {}

--- Create a new Room instance.
---@param name string
---@param opts table
---@return Room
function library.lobby._new(name, opts) end

--- Add a player to the room.
---@param peer_id number
---@param name string
---@param data table
---@return boolean
---@return string|nil
function Room:addPlayer(peer_id, name, data) end

--- Remove a player from the room.  Re-elects host deterministically by picking the earliest-joined remaining player.
---@param peer_id number
---@return nil
function Room:removePlayer(peer_id) end

--- Return the number of players currently in this room.
---@return number
function Room:getPlayerCount() end

--- Check whether all players are ready (minimum 2 players required).
---@return boolean
function Room:isAllReady() end

--- Return the current host peer_id (or nil if empty).
---@return number|nil
function Room:getHost() end

--- Create a new lobby manager. The lobby coordinates room creation, joining, leaving, ready-checks, and host election.  Pass a network host for online use, or `nil` for local-only / offline lobby management (e.g. tests). host.  May be `nil` for offline / test usage.
---@param host userdata
---@param channel number
---@return Lobby
function library.lobby.new(host, channel) end

--- Return the underlying `EventBus` (optional, may be nil). When non-nil, `:on(event, callback)` lets multiple listeners subscribe to the same lifecycle event without overwriting each other.  Event names match the strings passed to `:onEvent(fn)` (`room_created`, `room_removed`, `player_joined`, `player_left`, `player_ready`, `host_changed`, `player_disconnected`). unavailable in this runtime.
---@return userdata|nil
function Lobby:getEventBus() end

--- Set the local player name used when joining rooms.
---@param name string
---@return nil
function Lobby:setPlayerName(name) end

--- Register a callback for lobby events. For multi-listener pub-sub, prefer `:getEventBus():on(event, fn)` when `lurek.patterns` is available. `"room_created"`, `"room_removed"`, `"player_joined"`, `"player_left"`, `"player_ready"`, `"host_changed"`, `"player_disconnected"`.
---@param fn function
---@return nil
function Lobby:onEvent(fn) end

--- Create a new room (server-side).
---@param name string
---@param opts table
---@return boolean
---@return string|nil
function Lobby:createRoom(name, opts) end

--- Remove a room (server-side).  All players in the room are evicted.
---@param name string
---@return nil
function Lobby:removeRoom(name) end

--- Join a room by name (local or via network message). When `peer_id` is nil the local player joins (using peer 0 internally). When `peer_id` is provided the server records that remote peer.
---@param name string
---@param peer_id number
---@param player_name string
---@param password string
---@return boolean
---@return string|nil
function Lobby:joinRoom(name, peer_id, player_name, password) end

--- Leave a room. When `peer_id` is nil the local player leaves their current room. When `peer_id` is provided the server removes that remote peer from whichever room they are in.
---@param peer_id number
---@return boolean
---@return string|nil
function Lobby:leaveRoom(peer_id) end

--- List all available rooms.
---@return table
function Lobby:listRooms() end

--- Get players in a specific room (or current room if name is nil).
---@param name string
---@return table
function Lobby:getPlayers(name) end

--- Set ready state for a player. When `peer_id` is nil the local player's ready state is updated in their current room.  When `peer_id` is provided the server looks up that peer's room via the internal reverse map (unified code path).
---@param ready boolean
---@param peer_id number
---@return nil
function Lobby:setReady(ready, peer_id) end

--- Check if all players in the current room are ready.
---@return boolean
function Lobby:isAllReady() end

--- Get the current room name (client-side / local player).
---@return string|nil
function Lobby:getCurrentRoom() end

--- Get the host peer_id for a room (or the local player's room).
---@param name string
---@return number|nil
function Lobby:getHost(name) end

--- Get the number of rooms.
---@return number
function Lobby:getRoomCount() end

--- Process incoming lobby network messages.  Call once per frame.
---@return table
function Lobby:poll() end

--- Internal: handle a decoded lobby message from a peer.
---@param peer_id number
---@param data table
---@param events table
---@return nil
function Lobby:_handle(peer_id, data, events) end

---@class library.loot
library.loot = {}

--- Install a custom default RNG used by `LootTable:sample` when no rng arg is passed.
---@param rng userdata|table
---@return nil
function library.loot.setDefaultRng(rng) end

--- Get the module's current default RNG (resolves on first use).
---@return userdata|table
function library.loot.getDefaultRng() end

--- Create an empty weighted loot table.
---@return LootTable
function library.loot.newTable() end

--- Bulk-build a loot table from a list of `{id, weight, meta?}` entries.
---@param entries table
---@return LootTable
function library.loot.fromList(entries) end

--- Load a loot table from a TOML file via `lurek.filesystem.read` + `lurek.serial.fromToml`. The file must contain an `entries = [...]` array.
---@param path string
---@return LootTable
function library.loot.fromToml(path) end

--- Combine multiple LootTables into a single new one. Identical IDs sum weights.
---@param ... LootTable
---@return LootTable
function library.loot.merge(...) end

--- Add or accumulate an entry. Triggers alias rebuild on next sample.
---@param id string
---@param weight number
---@param meta table|nil
---@return LootTable
function LootTable:add(id, weight, meta) end

--- Remove an entry by id.
---@param id string
---@return boolean
function LootTable:remove(id) end

--- Adjust an entry's weight (rebuilds alias on next sample).
---@param id string
---@param w number
---@return LootTable
function LootTable:setWeight(id, w) end

--- O(1) sample one entry from the alias table.
---@param rng userdata|table|nil
---@return string
---@return table|nil
function LootTable:sample(rng) end

--- Bulk draw N samples.
---@param n integer
---@param rng userdata|table|nil
---@param opts table|nil
---@return table
function LootTable:sampleN(n, rng, opts) end

--- Current weight of an entry.
---@param id string
---@return number
function LootTable:weightOf(id) end

--- Total weight of all entries.
---@return number
function LootTable:totalWeight() end

--- Normalised probability of an entry (0..1).
---@param id string
---@return number
function LootTable:probability(id) end

--- Snapshot of all entry ids.
---@return table
function LootTable:ids() end

--- Deep-copy this table.
---@return LootTable
function LootTable:clone() end

--- Create a composable drop description.
---@return DropSet
function library.loot.newDrop() end

--- Roll a loot table N times.
---@param tbl LootTable
---@param opts table|nil
---@return DropSet
function DropSet:roll(tbl, opts) end

--- Always emit `id × count`.
---@param id string
---@param count integer|nil
---@return DropSet
function DropSet:guarantee(id, count) end

--- Gate the next clauses on a predicate `fn(context) -> bool`. The gate persists for all subsequent `:roll`/`:guarantee` calls in the chain.
---@param fn function(context)
---@return DropSet
function DropSet:when(fn) end

--- Execute all clauses against `context` and return the resolved drop list.
---@param context table
---@param rng userdata|table|nil
---@return table
function DropSet:resolve(context, rng) end

--- Human-readable explanation of which clauses would fire.
---@param context table
---@return string
function DropSet:explain(context) end

--- Guarantee `target_id` is forced after `threshold` consecutive misses.
---@param target_id string
---@param threshold integer
---@return Pity
function library.loot.newPity(target_id, threshold) end

--- Notice a draw result. Returns true when pity is now primed and should force `target_id` on the next draw.
---@param result_id string
---@return boolean
function Pity:notice(result_id) end

--- Reset the pity counter to 0.
---@return nil
function Pity:reset() end

--- Current miss counter.
---@return integer
function Pity:getCounter() end

--- True when pity will fire on the next draw.
---@return boolean
function Pity:isPrimed() end

--- Serialise to a save blob.
---@return table
function Pity:save() end

--- Restore from a save blob.
---@param blob table
---@return Pity
function Pity:restore(blob) end

--- Stack of named weight multipliers applied to a LootTable view.
---@return Modifier
function library.loot.newModifier() end

--- Add a multiplier function.
---@param name string
---@param fn function
---@return Modifier
function Modifier:add(name, fn) end

--- Produce a temporary LootTable with adjusted weights. Original is untouched.
---@param tbl LootTable
---@param context table
---@return LootTable
function Modifier:apply(tbl, context) end

---@class library.narrative
library.narrative = {}

--- Compile Ink-subset source into a Story program (not yet started).
---@param source string
---@return Story
function library.narrative.compile(source) end

--- Load and compile a .ink file via `lurek.filesystem.read`.
---@param path string
---@return Story
function library.narrative.loadFile(path) end

--- Produce a serialisable AST blob (cacheable).
---@param source string
---@return table
function library.narrative.precompile(source) end

--- Restore a precompiled program into a fresh Story.
---@param blob table
---@return Story
function library.narrative.fromBytecode(blob) end

--- Reset to the entry knot. Defaults to `START` (or first declared knot).
---@param knot string|nil
---@return Story
function Story:start(knot) end

--- True while there is more prose to emit before the next choice or end.
---@return boolean
function Story:canContinue() end

--- True when the playhead is at a choice point.
---@return nil
function Story:isAtChoice() end

--- True when the story has reached `-> END`.
---@return nil
function Story:isEnded() end

--- Emit the next prose line; returns nil at choice points or end. Also returns the tag list attached to the line.
---@return string|nil
function Story:continue() end

--- Drain prose until a choice or end, returning the joined string.
---@param sep string|nil
---@return string
function Story:continueAll(sep) end

--- Get the current pending choice list.
---@return table
function Story:getChoices() end

--- Select a choice by 1-based index. Raises if not available.
---@param index integer
---@return Story
function Story:choose(index) end

--- Set a variable.
---@return nil
function Story:setVar(name, value) end

--- Get a variable.
---@return nil
function Story:getVar(name) end

--- Snapshot of all variables (shallow copy).
---@return nil
function Story:listVars() end

--- Bind a Lua function callable from inside `{name(arg)}` markers.
---@return nil
function Story:bindFunction(name, fn) end

--- Register a tag handler. Returns an opaque handle for `offTag`.
---@return nil
function Story:onTag(tag, fn) end

--- Remove a previously registered tag handler.
---@return nil
function Story:offTag(handle) end

--- Register a variable-change handler.
---@return nil
function Story:onVarChange(name, fn) end

--- Jump to a knot. Records the visit and turn counter.
---@return nil
function Story:gotoKnot(name) end

--- Visit count of a knot.
---@return nil
function Story:visit(knot) end

--- Turns since a knot was last visited (math.huge if never).
---@return nil
function Story:turnsSince(knot) end

--- Toggle trace logging via `lurek.log.debug` (requires it to be available).
---@return nil
function Story:trace(enable) end

--- Profile the current story state (visits + var counts).
---@return nil
function Story:dumpProfile() end

--- Serialise full state (vars, visits, knot, pc) for `lurek.save`.
---@return nil
function Story:save() end

--- Restore from a save blob.
---@return nil
function Story:resume(state) end

--- Parse a `# tag1 # tag2` style string into an array.
---@return nil
function library.narrative.parseTagList(str) end

--- Pick a weighted choice from a `{ {text, weight} ... }` list using rng.
---@return nil
function library.narrative.weightedChoice(choices, rng) end

--- Format a list of values as natural prose: "a, b, and c".
---@return nil
function library.narrative.formatList(values, conjunction) end

--- Attach a `{loc:KEY}` localisation pre-processor using `lurek.i18n.t`.
---@return nil
function library.narrative.localiseStory(story, locale) end

---@class library.netstate
library.netstate = {}

--- Enable or disable debug logging. When enabled, state changes, authority violations, sync events, and turn changes are logged via `lurek.log.debug` (if available) or a custom function. `lurek.log.debug` when available, otherwise logging is silently skipped.
---@param enabled boolean
---@param custom_log function
---@return nil
function library.netstate.setLogging(enabled, custom_log) end

--- Create a new network state synchronization manager. The `host` parameter is a `lurek.network` host (server, client, or host). If `opts.authority` is not provided, authority defaults to `host:isServer()` when the host supports it, otherwise `false`. or nil for offline/testing mode (network operations become no-ops). - `channel` (number, default 0): Network channel for messages. - `authority` (boolean): Override authority detection. - `turnBased` (boolean, default false): Enable turn-based protocol. - `maxDirtyKeys` (number|nil): Maximum number of dirty keys tracked per sync cycle. When exceeded, oldest dirty keys are evicted. Nil = unlimited.
---@param host userdata|nil
---@param opts table
---@return NetState
function library.netstate.new(host, opts) end

--- Set whether this instance is the authority (can write state).
---@param auth boolean
---@return nil
function NetState:setAuthority(auth) end

--- Check if this instance is the authority.
---@return boolean
function NetState:isAuthority() end

--- Set a global change callback fired for any key change.
---@param fn function
---@return nil
function NetState:onChange(fn) end

--- Register a callback invoked if a full-state request times out. The caller is responsible for implementing timer logic and calling this callback from their own timeout handler.
---@param fn function
---@return nil
function NetState:onFullStateTimeout(fn) end

--- Set a synced value. Only the authority can set values. Non-authority calls are rejected and return `false, "not authority"`. Keys must be non-empty strings.
---@param key string
---@param value any
---@return boolean
---@return string|nil
function NetState:set(key, value) end

--- Get the current value of a synced key.
---@param key string
---@return any|nil
function NetState:get(key) end

--- Get the per-key version number.
---@param key string
---@return number
function NetState:getKeyVersion(key) end

--- Get all synced state as a flat table.
---@return table
function NetState:getAll() end

--- Register a callback for changes to a specific key.
---@param key string
---@param fn function
---@return nil
function NetState:onChanged(key, fn) end

--- Remove all callbacks for a key.
---@param key string
---@return nil
function NetState:clearCallbacks(key) end

--- Get the highest version number across all keys.
---@return number
function NetState:getVersion() end

--- Get the number of synced keys.
---@return number
function NetState:getKeyCount() end

--- Get the number of dirty (unsent) keys.
---@return number
function NetState:getDirtyCount() end

--- Check if a key exists in the state.
---@param key string
---@return boolean
function NetState:hasKey(key) end

--- Remove a key from the synced state. Authority only.
---@param key string
---@return boolean
---@return string|nil
function NetState:remove(key) end

--- Set the turn order (array of peer IDs). Resets the turn index to 1 and turn counter to 0. Each element must be a number. Invalid entries are silently filtered.
---@param order table
---@return nil
function NetState:setTurnOrder(order) end

--- Begin a new turn. Advances to the next player in the turn order. Only the authority should call this. If the turn order is empty, the turn counter advances but `turn_peer` remains nil.
---@return number
---@return number|nil
function NetState:beginTurn() end

--- End the current turn. Alias for `beginTurn()` — advances to next.
---@return number
---@return number|nil
function NetState:endTurn() end

--- Get the current turn number.
---@return number
function NetState:getCurrentTurn() end

--- Get the peer ID whose turn it currently is.
---@return number|nil
function NetState:getTurnPeer() end

--- Register a callback for turn changes.
---@param fn function
---@return nil
function NetState:onTurn(fn) end

--- Check if it is a specific peer's turn.
---@param peer_id number
---@return boolean
function NetState:isTurn(peer_id) end

--- Broadcast all dirty state to connected peers. Call once per frame after all `set()` calls (e.g. at end of `lurek.process(dt)`). Requires a valid host; no-op if host is nil or instance is not authority.
---@return nil
function NetState:sync() end

--- Process incoming state updates from the network. Call once per frame. Requires a valid host; returns empty table if host is nil.
---@return table
function NetState:poll() end

--- Mark a key as dirty, respecting the maxDirtyKeys limit.
---@param key string
---@return nil
function NetState:_markDirty(key) end

--- Compute a deterministic FNV-1a 32-bit digest of the current synced state. Useful for desync detection between authority and clients (compare digests after a sync round; mismatch indicates state divergence). TODO(P4 lift): when `lurek.data.hash` lands in the engine (P4 lift candidate), this method should delegate to it for the inner string-hashing step.  Until then a small inline FNV-1a implementation keeps the library self-contained and works on both LuaJIT (`bit` library) and Lua 5.4 (native `~`/`&`).
---@return number
function NetState:hashState() end

--- Serialise the current state to a JSON string via `lurek.serial.toJson`. Suitable for human-readable persistence (NOT for the wire — use the normal `:sync()` MessagePack path for peer-to-peer traffic). Returns nil if `lurek.serial` is unavailable in this runtime.
---@return string|nil
function NetState:toJson() end

--- Request a full state snapshot from the authority. Useful when a client joins mid-game. **Limitation**: This method has no built-in timeout. If the authority never responds, the client will not receive a snapshot. Callers should implement their own timer-based retry, e.g.: ns:requestFullState() local deadline = lurek.timer.getTime() + 5.0 -- In process loop: if lurek.timer.getTime() > deadline then retry or invoke --   ns:onFullStateTimeout callback
---@return boolean
function NetState:requestFullState() end

---@class library.province_map
library.province_map = {}

--- Create a new province.
---@param id number
---@param color table
---@return Province
function library.province_map.newProvince(id, color) end

--- Set the faction that controls this province.
---@param f string|nil
---@return nil
function Province:setFaction(f) end

--- Get the controlling faction.
---@return string|nil
function Province:getFaction() end

--- Set the defense rating (0–100).
---@param v number
---@return nil
function Province:setDefenseRating(v) end

--- Get the defense rating.
---@return number
function Province:getDefenseRating() end

--- Add a building to this province.
---@return nil
function Province:addBuilding(b) end

--- Get all buildings.
---@return table
function Province:getBuildings() end

--- Return true if the province has the given building.
---@param b string
---@return boolean
function Province:hasBuilding(b) end

--- Remove a building by name. Returns true if removed.
---@param b string
---@return boolean
function Province:removeBuilding(b) end

--- Set a produced resource amount.
---@param res string
---@param amount number
---@return nil
function Province:setResource(res, amount) end

--- Get a produced resource amount (0 if not set).
---@param res string
---@return number
function Province:getResource(res) end

--- Get the full resource table.
---@return table
function Province:getResources() end

--- Create a new adjacency edge between two provinces.
---@param province_a number
---@param province_b number
---@return table
function library.province_map.newAdjacencyEdge(province_a, province_b) end

--- Add a tag to an adjacency edge.
---@param edge table
---@param tag string
---@return nil
function library.province_map.addEdgeTag(edge, tag) end

--- Remove a tag from an adjacency edge.
---@param edge table
---@param tag string
---@return nil
function library.province_map.removeEdgeTag(edge, tag) end

--- Check if an adjacency edge has a tag.
---@param edge table
---@param tag string
---@return boolean
function library.province_map.hasEdgeTag(edge, tag) end

--- Create a province definition (lightweight descriptor for map building).
---@param id number
---@param color table
---@param center table
---@return table
function library.province_map.newProvinceDefinition(id, color, center) end

--- Create a border segment between two provinces.
---@param province_a number
---@param province_b number
---@return table
function library.province_map.newBorderSegment(province_a, province_b) end

--- Create a border style descriptor.
---@return table
function library.province_map.newBorderStyle() end

--- Create a fixed colour map mode (each province has a fixed colour).
---@param province_colors table
---@return table
function library.province_map.newFixedColorFn(province_colors) end

--- Create a gradient colour map mode.
---@param values table
---@param min_color table
---@param max_color table
---@param min_val number
---@param max_val number
---@return table
function library.province_map.newGradientColorFn(values, min_color, max_color, min_val, max_val) end

--- Apply a gradient colour function to a province, returning a {r,g,b} colour.
---@param fn table
---@param id number
---@return table
function library.province_map.applyGradientColor(fn, id) end

--- Create a category colour map mode.
---@param categories table
---@param colors table
---@param default_color table
---@return table
function library.province_map.newCategoryColorFn(categories, colors, default_color) end

--- Apply a category colour function to a province.
---@param fn table
---@param id number
---@return table
function library.province_map.applyCategoryColor(fn, id) end

--- Create a named map mode.
---@param name string
---@param color_fn table|string
---@return table
function library.province_map.newMapMode(name, color_fn) end

--- Create a new empty province map.
---@param width number
---@param height number
---@return ProvinceMap
function library.province_map.newProvinceMap(width, height) end

--- Return the map width in pixels.
---@return number
function ProvinceMap:width() end

--- Return the map height in pixels.
---@return number
function ProvinceMap:height() end

--- Insert or replace a province.
---@param province Province
---@return nil
function ProvinceMap:insertProvince(province) end

--- Remove a province by ID. Returns true if it existed.
---@param id number
---@return boolean
function ProvinceMap:removeProvince(id) end

--- Look up a province by ID.
---@param id number
---@return Province|nil
function ProvinceMap:getProvince(id) end

--- Return the total number of provinces.
---@return number
function ProvinceMap:provinceCount() end

--- Return a sorted list of all province IDs.
---@return table
function ProvinceMap:provinceIds() end

--- Set pixel at (x, y) to the given province ID. Coordinates are 0-based.  Internally stored in `pixel_lookup` at 1-based index `y * width + x + 1` (standard Lua array convention). After writing the pixel, adjacency edges are updated bidirectionally by checking all four cardinal neighbours.
---@param x number
---@param y number
---@param province_id number
---@return nil
function ProvinceMap:setPixel(x, y, province_id) end

--- Return the province ID at pixel (x, y). Coordinates are 0-based.  Returns nil for out-of-bounds queries.
---@param x number
---@param y number
---@return number|nil
function ProvinceMap:getProvinceAt(x, y) end

--- Insert an adjacency edge. Edge fields `province_a` / `province_b` are normalised on insertion so that `province_a <= province_b`, matching `adj_key` sort order.
---@param edge table
---@return nil
function ProvinceMap:insertAdjacency(edge) end

--- Remove an adjacency edge. Returns true if removed.
---@param a number
---@param b number
---@return boolean
function ProvinceMap:removeAdjacency(a, b) end

--- Get the adjacency edge between two provinces.
---@param a number
---@param b number
---@return table|nil
function ProvinceMap:getAdjacency(a, b) end

--- Return the total number of adjacency edges.
---@return number
function ProvinceMap:adjacencyCount() end

--- Return a sorted list of neighbour province IDs for the given province.
---@param id number
---@return table
function ProvinceMap:getNeighbors(id) end

--- Set adjacency between two provinces (creates or updates edge). The edge is stored with normalised province IDs (`province_a <= province_b`). Neighbours can always be queried via `getNeighbors(id)` which scans the adjacency table — there is no separate neighbours list to keep in sync.
---@param a number
---@param b number
---@param tags table
---@return table
function ProvinceMap:setAdjacent(a, b, tags) end

--- Euclidean centroid distance between two provinces.
---@param a number
---@param b number
---@return number
function ProvinceMap:distance(a, b) end

--- Return the raw pixel-lookup table.
---@return table
function ProvinceMap:pixelLookup() end

--- BFS route from province `from_id` to `to_id`. Returns an ordered list of province IDs forming the path, or nil if unreachable. Passable edges (passable == true) and optional cost filter are respected.
---@param from_id number
---@param to_id number
---@param passable_fn function|nil
---@return table|nil
function ProvinceMap:findRoute(from_id, to_id, passable_fn) end

--- Return all province IDs controlled by the given faction.
---@param faction string
---@return table
function ProvinceMap:getProvincesByFaction(faction) end

--- Sum a resource across all provinces belonging to a faction.
---@param faction string
---@param resource string
---@return number
function ProvinceMap:totalResourceForFaction(faction, resource) end

--- Get all provinces whose faction field is nil (uncontrolled).
---@return table
function ProvinceMap:getUncontrolledProvinces() end

--- Get all provinces with no adjacency edges (isolated islands).
---@return table
function ProvinceMap:findIsolatedProvinces() end

--- Get connected components (list of lists of province IDs).
---@return table
function ProvinceMap:getConnectedComponents() end

--- Create a new event bus for province map events.
---@return EventBus
function library.province_map.newEventBus() end

--- Emit a map-loaded event with province count.
---@param count number
---@return nil
function EventBus:emitMapLoaded(count) end

--- Emit a province-added event.
---@param id number
---@return nil
function EventBus:emitProvinceAdded(id) end

--- Emit a province-removed event.
---@param id number
---@return nil
function EventBus:emitProvinceRemoved(id) end

--- Emit adjacency-detected with edge count.
---@param edge_count number
---@return nil
function EventBus:emitAdjacencyDetected(edge_count) end

--- Emit adjacency-changed for two provinces.
---@param a number
---@param b number
---@return nil
function EventBus:emitAdjacencyChanged(a, b) end

--- Emit adjacency-removed for two provinces.
---@param a number
---@param b number
---@return nil
function EventBus:emitAdjacencyRemoved(a, b) end

--- Emit borders-extracted with segment count.
---@param count number
---@return nil
function EventBus:emitBordersExtracted(count) end

--- Emit map-mode-applied with mode name.
---@param name string
---@return nil
function EventBus:emitMapModeApplied(name) end

--- Emit positions-calculated with province count.
---@param count number
---@return nil
function EventBus:emitPositionsCalculated(count) end

--- Emit province-selected at map position.
---@param id number
---@param x number
---@param y number
---@return nil
function EventBus:emitProvinceSelected(id, x, y) end

--- Emit province-deselected.
---@param id number
---@return nil
function EventBus:emitProvinceDeselected(id) end

--- Emit province-hovered at map position.
---@param id number
---@param x number
---@param y number
---@return nil
function EventBus:emitProvinceHovered(id, x, y) end

--- Emit faction-changed for a province.
---@param id number
---@param old_faction string|nil
---@param new_faction string|nil
---@return nil
function EventBus:emitFactionChanged(id, old_faction, new_faction) end

--- Poll one event from the queue. Returns nil when empty.
---@return table|nil
function EventBus:poll() end

--- Return true if no events are queued.
---@return boolean
function EventBus:isEmpty() end

--- Drain and return all queued events.
---@return table
function EventBus:drain() end

--- Return the number of queued events.
---@return number
function EventBus:size() end

--- Derive a province ID from an RGB colour.
---@param r number
---@param g number
---@param b number
---@return number
function library.province_map.colorToId(r, g, b) end

--- Build a ProvinceMap from a list of province definitions.
---@param defs table
---@param width number
---@param height number
---@return ProvinceMap
function library.province_map.loadFromDefinitions(defs, width, height) end

--- Detect province adjacencies from a pixel-lookup grid (single-pass O(w*h)).
---@param map ProvinceMap
---@return nil
function library.province_map.detectAdjacency(map) end

--- Extract border segments for all adjacency edges.
---@param map ProvinceMap
---@return table
function library.province_map.extractAllBorders(map) end

--- Extract border segments for edges that have a specific tag.
---@param map ProvinceMap
---@param tag string
---@return table
function library.province_map.extractBordersWithTag(map, tag) end

--- Get the centroid position of the province as the capital point.
---@param map ProvinceMap
---@param id number
---@return table|nil
function library.province_map.calculateCapital(map, id) end

--- Set all province center positions to their centroid.
---@param map ProvinceMap
---@return nil
function library.province_map.calculateAllPositions(map) end

--- Count total adjacency edges across all provinces in the map.
---@param map ProvinceMap
---@return number
function library.province_map.totalEdgeCount(map) end

--- Get all unique faction names present in the map.
---@param map ProvinceMap
---@return table
function library.province_map.allFactions(map) end

--- Return all border segments where the two bordering provinces have different values according to prop_fn.
---@param map ProvinceMap
---@param prop_fn function
---@return table
function library.province_map.extractBordersByProperty(map, prop_fn) end

--- Detect province adjacencies from a pixel-lookup grid and tag the resulting edges based on special tag-pixel IDs. `tag_pixel_colors` maps province IDs that act as tag pixels to their tag string.  When a tag pixel is adjacent to two distinct non-tag provinces, those provinces' shared edge is created (if absent) and tagged.
---@param map ProvinceMap
---@param tag_pixel_colors table
---@return nil
function library.province_map.detectAdjacencyWithTags(map, tag_pixel_colors) end

--- Convert a province map's adjacency structure to a generic graph table. Each unique province that appears in at least one edge becomes a node. Each adjacency edge becomes one undirected entry in the edges list.
---@param map ProvinceMap
---@return table
function library.province_map.adjacencyToGraph(map) end

--- Resolve a colour for each province using the given map mode. Returns a table mapping province ID to a normalised {r, g, b, a} float colour (each component in the 0–1 range).
---@param map ProvinceMap
---@param mode table
---@return table
function library.province_map.resolveProvinceColors(map, mode) end

--- Build a ProvinceMap from a PNG province-colour map using the Rust engine. This replaces the Lua `setPixel` loop + `detectAdjacency` pass with a single Rust O(w×h) scan. For a 2400×1200 map with 3000 provinces the typical speedup is 100×–300× vs the pure-Lua path (from ~2–8 s down to ~15–30 ms). Each unique non-black RGB pixel in the PNG is automatically assigned a sequential province ID starting at 1. Pure-black pixels (0, 0, 0) become background (ID 0). The returned ProvinceMap has its `pixel_lookup` field replaced by the engine grid (so `getProvinceAt` delegates to it), and all adjacency edges are pre-populated from the single Rust scan. Requires `lurek.image` to be available (Platform Services tier). by `M.loadFromDefinitions` — used to attach names, factions, and other metadata. Pass nil to skip.
---@param png_path string
---@param defs table
---@return ProvinceMap
function library.province_map.newFromPng(png_path, defs) end

---@class library.quest
library.quest = {}

--- Create a new objective with 0/required progress.
---@param id string
---@param description string
---@param required number
---@return Objective
function library.quest.newObjective(id, description, required) end

--- Advance progress by amount. Automatically marks the objective as "done" when current >= required. Does nothing if already done or failed.
---@param amount number
---@return number
function Objective:advance(amount) end

--- Set progress directly. Clamps to [0, required].
---@param value number
---@return nil
function Objective:setProgress(value) end

--- Returns true if this objective is considered complete (done or skipped).
---@return boolean
function Objective:isComplete() end

--- Add a tag. Has no effect if already present.
---@param tag string
---@return nil
function Objective:addTag(tag) end

--- Returns true if the given tag is present.
---@param tag string
---@return boolean
function Objective:hasTag(tag) end

--- Create a new empty quest stage.
---@param id string
---@param name string
---@return QuestStage
function library.quest.newQuestStage(id, name) end

--- Add an objective to this stage.
---@param obj Objective
---@return nil
function QuestStage:addObjective(obj) end

--- Get an objective by id.
---@param id string
---@return Objective|nil
function QuestStage:getObjective(id) end

--- Get all objectives in this stage.
---@return table
function QuestStage:getObjectives() end

--- Return the number of objectives in this stage.
---@return number
function QuestStage:objectiveCount() end

--- Remove all objectives from this stage.
---@return nil
function QuestStage:clearObjectives() end

--- Returns true if this stage contains an objective with the given id.
---@param id string
---@return boolean
function QuestStage:hasObjective(id) end

--- Returns true when all mandatory objectives in this stage are complete.
---@return boolean
function QuestStage:isComplete() end

--- Create a new quest in the "available" state. Valid status transitions: available → active → completed | failed.
---@param id string
---@param title string
---@param max_journal_entries number
---@return Quest
function library.quest.newQuest(id, title, max_journal_entries) end

--- Add a stage to the quest (in order).
---@param stage QuestStage
---@return nil
function Quest:addStage(stage) end

--- Get the currently active stage, if any.
---@return QuestStage|nil
function Quest:getCurrentStage() end

--- Get a stage by id.
---@param id string
---@return QuestStage|nil
function Quest:getStage(id) end

--- Advance to the next stage. Returns true on success, false if already at last stage.
---@return boolean
function Quest:nextStage() end

--- Jump to the stage with the given id. Returns false if not found.
---@param id string
---@return boolean
function Quest:gotoStage(id) end

--- Advance progress on an objective in the current stage (or a specific stage). Returns false if objective not found in the target stage.
---@param obj_id string
---@param amount number
---@param stage_id string
---@return boolean
function Quest:advanceObjective(obj_id, amount, stage_id) end

--- Set status of an objective across all stages. Returns false if not found.
---@param obj_id string
---@param status string
---@return boolean
function Quest:setObjectiveStatus(obj_id, status) end

--- Start the quest (transition from "available" to "active").
---@return boolean
function Quest:start() end

--- Mark the quest as completed (transition from "active" to "completed").
---@return boolean
function Quest:complete() end

--- Mark the quest as failed (transition from "active" to "failed").
---@return boolean
function Quest:fail() end

--- Append a journal entry. Returns the entry's index. If `max_journal_entries` was set on the quest, the oldest entries are removed to stay within the limit.
---@param text string
---@param tag string
---@return number
function Quest:addJournalEntry(text, tag) end

--- Set a metadata key-value pair.
---@param key string
---@param value string
---@return nil
function Quest:setMeta(key, value) end

--- Get a metadata value by key.
---@param key string
---@return string|nil
function Quest:getMeta(key) end

--- Returns percentage of mandatory objectives that are Done across all stages (0.0-100.0). Returns 0.0 when there are no mandatory objectives.
---@return number
function Quest:completionPercent() end

--- Returns the IDs of all objectives currently "active" across all stages.
---@return table
function Quest:activeObjectiveIds() end

--- Reset an objective back to "active" (in progress). Returns false if not found.
---@param id string
---@return boolean
function Quest:resetObjective(id) end

--- Return true if every mandatory objective in the quest is complete.
---@return boolean
function Quest:allObjectivesComplete() end

--- Create an empty quest log.
---@return QuestLog
function library.quest.newQuestLog() end

--- Attach an event bus to receive quest lifecycle notifications. The bus must implement an `emit(name, payload)` method (e.g. `lurek.patterns.newEventBus()`). Pass `nil` to detach. Emitted events: `"quest_started"`, `"quest_advanced"`, `"quest_completed"`, `"quest_failed"`. The payload table contains at least `{ id = quest_id }` plus event-specific fields.
---@param bus table|nil
---@return nil
function QuestLog:setEventBus(bus) end

--- Get the currently attached event bus (nil when none).
---@return table|nil
function QuestLog:getEventBus() end

--- Register a quest. If a quest with the same id already exists, it is replaced.
---@param quest Quest
---@return nil
function QuestLog:addQuest(quest) end

--- Get a quest by id.
---@param id string
---@return Quest|nil
function QuestLog:getQuest(id) end

--- Remove a quest by id. Returns true if removed, false if not found.
---@param id string
---@return boolean
function QuestLog:removeQuest(id) end

--- List ids of all quests in insertion order.
---@return table
function QuestLog:questIds() end

--- List ids of all quests with the given status.
---@param status string
---@return table
function QuestLog:questsWithStatus(status) end

--- Total number of registered quests.
---@return number
function QuestLog:questCount() end

--- Start quest by id (available -> active). Returns false if not found or invalid transition. Emits `"quest_started"` on the attached event bus.
---@param id string
---@return boolean
function QuestLog:startQuest(id) end

--- Complete quest by id (active -> completed). Returns false if not found or invalid transition. Emits `"quest_completed"` on the attached event bus.
---@param id string
---@return boolean
function QuestLog:completeQuest(id) end

--- Fail quest by id (active -> failed). Returns false if not found or invalid transition. Emits `"quest_failed"` on the attached event bus.
---@param id string
---@return boolean
function QuestLog:failQuest(id) end

--- IDs of all active quests.
---@return table
function QuestLog:activeIds() end

--- IDs of all completed quests.
---@return table
function QuestLog:completedIds() end

--- IDs of all failed quests.
---@return table
function QuestLog:failedIds() end

--- Advance an objective in a specific quest. Returns false if quest or objective not found. Emits `"quest_advanced"` on the attached event bus when the underlying objective accepted the progress change.
---@param quest_id string
---@param obj_id string
---@param amount number
---@param stage_id string
---@return boolean
function QuestLog:advanceObjective(quest_id, obj_id, amount, stage_id) end

--- Reset a quest back to "available" with the first stage active and all objective progress cleared to zero.
---@param id string
---@return boolean
function QuestLog:resetQuest(id) end

--- Set the reward description string on a quest.
---@param id string
---@param reward string
---@return nil
function QuestLog:setQuestReward(id, reward) end

--- Get the reward description of a quest.
---@param id string
---@return string
function QuestLog:getQuestReward(id) end

--- Count active quests (status == "in_progress").
---@return number
function QuestLog:activeCount() end

--- Count completed quests.
---@return number
function QuestLog:completedCount() end

--- Remove a tag from this objective. Returns true if the tag was present.
---@param tag string
---@return boolean
function Objective:removeTag(tag) end

--- Encode a `QuestLog` to a JSON string via `lurek.serial.toJson`.
---@param log QuestLog
---@return string
function library.quest.toJson(log) end

--- Decode a JSON-encoded log into a fresh `QuestLog`. The optional `into` argument lets the caller reuse an existing log (its quests are replaced).
---@param str string
---@param into QuestLog
---@return QuestLog
function library.quest.fromJson(str, into) end

---@class library.rhythm
library.rhythm = {}

--- Build a free-running BPM clock.
---@return nil
function library.rhythm.newClock(bpm, opts) end

--- Build a clock anchored to an `lurek.audio` Source's playhead.
---@return nil
function library.rhythm.fromAudio(source, bpm, opts) end

--- Set the clock BPM immediately, cancelling any in-progress ramp.
---@param bpm number
---@return Clock
function Clock:setBpm(bpm) end

--- Smoothly ramp BPM from the current value to `target` over `seconds`.
---@param target number
---@param seconds number
---@return Clock
function Clock:rampBpm(target, seconds) end

--- Return the current BPM (may be mid-ramp).
---@return number
function Clock:getBpm() end

--- Set swing amount (0–0.5; 0 = straight, 0.5 = maximum shuffle).
---@param amount number
---@return Clock
function Clock:setSwing(amount) end

--- Start (or restart) the clock from beat zero.
---@return Clock
function Clock:start() end

--- Stop the clock, preserving the current beat position.
---@return Clock
function Clock:stop() end

--- Return true if the clock is currently running.
---@return boolean
function Clock:isRunning() end

--- Advance the clock by `dt` seconds. Call once per frame from `lurek.process`. Fires beat/bar events and triggers any registered schedule handles.
---@param dt number
---@return Clock
function Clock:update(dt) end

--- Re-anchor the clock to a new audio source's current playhead.
---@param source table
---@return Clock
function Clock:syncToAudio(source) end

--- Fractional beats since `:start()`.
---@return nil
function Clock:getBeat() end

--- Fractional bar number since `:start()` (beat / subdivision).
---@return number
function Clock:getBar() end

--- Fractional position within the current subdivision step (0 = step start, 1 = next step).
---@param division integer|nil
---@return number
function Clock:getPhase(division) end

--- Seconds until the next step boundary at the given subdivision.
---@param division integer|nil
---@return number
function Clock:beatTimeRemaining(division) end

--- Return true if the clock is within `tolerance` of a step boundary.
---@param division integer|nil
---@param tolerance number|nil
---@return boolean
function Clock:isOnBeat(division, tolerance) end

--- Nearest beat index and signed timing error in seconds.
---@param division integer|nil
---@return number
---@return number
function Clock:nearestBeat(division) end

--- Schedule `fn` to fire on every step at `division`. Returns a cancellable handle.
---@param division integer
---@param fn function
---@return table
function Clock:every(division, fn) end

--- Schedule `fn` to fire once when the clock reaches `beat`.
---@param beat number
---@param fn function
---@return table
function Clock:at(beat, fn) end

--- Schedule `fn` on each `'x'` character in a step-pattern string. Pattern length sets subdivision; `'x'` triggers, any other char is a rest. Example: `"x.x."` fires on steps 1 and 3 of a 4-step bar.
---@param str string
---@param fn function
---@return table
function Clock:pattern(str, fn) end

--- Cancel a previously registered schedule handle.
---@param handle table
---@return boolean
function Clock:cancel(handle) end

--- Cancel all registered schedule handles on this clock.
---@return Clock
function Clock:cancelAll() end

--- Return a snapshot table of current clock state for serialisation.
---@return table
function Clock:dump() end

--- Override the default judgement window thresholds (all values in seconds). Keys: `perfect`, `great`, `good`. Omitted keys keep their current values.
---@param w table
---@return nil
function library.rhythm.setJudgementWindows(w) end

--- Return the current judgement window thresholds as a table.
---@return table
function library.rhythm.getJudgementWindows() end

--- Judge a player input against the nearest beat at `division`.
---@param clock Clock
---@param division integer
---@param hit_time number|nil
---@return string
---@return number
function library.rhythm.judge(clock, division, hit_time) end

---@class library.roguelike
library.roguelike = {}

--- Construct a new FOV instance. informational; only "shadowcast" is implemented.
---@param opts table|nil
---@return Fov
function library.roguelike.newFov(opts) end

--- Set a custom blocker function.
---@return nil
function Fov:setBlocker(fn) end

--- Attach to a tilemap and treat the supplied tile ids as blockers on the given layer. `tilemap` is queried via `tilemap:getTile(layer, x, y)` if the method is present; otherwise via the table-indexed `tilemap[layer][y][x]`.
---@return nil
function Fov:attachTilemap(tilemap, layer, blocker_ids) end

--- Recompute visibility from `(ox, oy)`.
---@return nil
function Fov:compute(ox, oy) end

--- Return true if `(x, y)` is within the current visible set.
---@param x integer
---@param y integer
---@return boolean
function Fov:isVisible(x, y) end

--- Return true if `(x, y)` has ever been revealed by a previous `:compute` call.
---@param x integer
---@param y integer
---@return boolean
function Fov:isExplored(x, y) end

--- Clear the explored set (does not affect the current visible set).
---@return Fov
function Fov:resetExplored() end

--- Iterate over every currently visible cell, calling `fn(x, y)` for each.
---@param fn function
---@return Fov
function Fov:eachVisible(fn) end

--- Return an array of `{x, y}` tables for all currently visible cells.
---@return table
function Fov:visibleCells() end

--- Serialise visible and explored sets for save/restore.
---@return table
function Fov:export() end

--- Create an action-cost (energy) scheduler. Each actor has a `speed` value; on each `:next()` call the actor with the highest accumulated energy goes. Internal clock advances by the minimum ticks needed to bring at least one actor's energy >= 100.
---@return Scheduler
function library.roguelike.newScheduler() end

--- Add an actor with the given speed to the scheduler. Speed determines how quickly the actor's energy accumulates.
---@param actor any
---@param speed number
---@return Scheduler
function Scheduler:add(actor, speed) end

--- Remove an actor from the scheduler. No-op if not present.
---@param actor any
---@return Scheduler
function Scheduler:remove(actor) end

--- Update the speed of an existing actor.
---@param actor any
---@param speed number
---@return Scheduler
function Scheduler:setSpeed(actor, speed) end

--- Pop the next-to-act actor. Returns the actor and ticks advanced this call.
---@return nil
function Scheduler:next() end

--- Peek at the next actor without consuming a turn.
---@return nil
function Scheduler:peek() end

--- Take `n` consecutive turns and return the actors in order.
---@return nil
function Scheduler:tick(n) end

--- Reset the scheduler clock and all actor energies to zero.
---@return Scheduler
function Scheduler:reset() end

--- Serialise scheduler state for save/restore.
---@return table
function Scheduler:save() end

--- Restore scheduler state from a previously saved blob.
---@param blob table
---@return Scheduler
function Scheduler:restore(blob) end

--- Construct a goal map of the given grid dimensions.
---@return nil
function library.roguelike.newGoalMap(width, height) end

--- Set a custom blocker predicate `fn(x, y) -> bool`.
---@param fn function|nil
---@return GoalMap
function GoalMap:setBlocker(fn) end

--- Attach to a tilemap layer, treating the supplied tile IDs as blockers.
---@param tilemap table|userdata
---@param layer integer|nil
---@param blocker_ids table|nil
---@return GoalMap
function GoalMap:attachTilemap(tilemap, layer, blocker_ids) end

--- Replace the current source list with the given positions. Each entry may be `{x, y}`, `{x, y, weight}`, or `{x=, y=, weight=}`.
---@param positions table
---@return GoalMap
function GoalMap:setSources(positions) end

--- Add a single goal-source cell.
---@param x integer
---@param y integer
---@param w number|nil
---@return GoalMap
function GoalMap:addSource(x, y, w) end

--- Remove all goal-source cells and mark the distance field dirty.
---@return GoalMap
function GoalMap:clearSources() end

--- Bake the Dijkstra distance field from the current sources. Delegates to `lurek.pathfind.dijkstra` when available; falls back to a pure-Lua 4-neighbour BFS otherwise.
---@return GoalMap
function GoalMap:bake() end

--- Return the baked distance value at `(x, y)`. Auto-bakes if dirty. Returns `math.huge` for unreachable or out-of-bounds cells.
---@param x integer
---@param y integer
---@return number
function GoalMap:distanceAt(x, y) end

--- Unit step toward the nearest goal cell.
---@return nil
function GoalMap:gradientAt(x, y) end

--- Unit step away from goals, scaled by `fear` (default 1.2).
---@return nil
function GoalMap:flee(x, y, fear) end

--- Bresenham line of grid points from (x0,y0) to (x1,y1). Falls back to a Lua implementation if `lurek.math.bresenham` is unavailable.
---@return nil
function library.roguelike.bresenham(x0, y0, x1, y1) end

--- True if `fov` reports an unbroken line from (x0,y0) to (x1,y1) is visible.
---@return nil
function library.roguelike.lineOfSight(fov, x0, y0, x1, y1) end

---@class library.rpc
library.rpc = {}

--- Create a new RPC manager attached to a NetworkHost.
---@param host userdata
---@param channel number
---@param timeout number
---@return RPC
function library.rpc.new(host, channel, timeout) end

--- Enable or disable debug logging via `lurek.log`. When enabled, RPC calls, responses, and errors are logged at debug level.
---@param enabled boolean
---@return nil
function RPC:setLogging(enabled) end

--- Register a function callable from remote peers.
---@param name string
---@param fn function
---@return nil
function RPC:register(name, fn) end

--- Unregister a previously registered function.
---@param name string
---@return nil
function RPC:unregister(name) end

--- Set a global error handler for RPC processing errors. The callback receives a single string that includes error context (method name, peer ID) when available.
---@param fn function
---@return nil
function RPC:onError(fn) end

--- Call a function on a specific remote peer (request/response pattern). When a matching `rpc_response` arrives in `poll()`, the `callback` is invoked with `(success, result_table)`.
---@param peer_id number
---@param name string
---@param callback function
---@param ... any
---@return number
function RPC:call(peer_id, name, callback, ...) end

--- Fire-and-forget call: no response expected. Includes `peer_id` in the wire message so broadcast handlers on the receiving side can identify the originator.
---@param peer_id number
---@param name string
---@param ... any
---@return nil
function RPC:notify(peer_id, name, ...) end

--- Broadcast an RPC call to all connected peers (fire-and-forget). Includes `peer_id = 0` in the wire message (server/broadcast origin).
---@param name string
---@param ... any
---@return nil
function RPC:broadcast(name, ...) end

--- Reset the internal request ID counter back to 1. Useful for long-running servers to avoid exceeding the 2^53 integer precision limit of Lua numbers (LuaJIT doubles). **Warning**: Only call this when no pending calls are in flight.
---@return nil
function RPC:resetIdCounter() end

--- Get the current request ID counter value.
---@return number
function RPC:getNextId() end

--- Get the number of pending (unresolved) RPC calls.
---@return number
function RPC:getPendingCount() end

--- Set the timeout for future pending calls (seconds). 0 = no timeout.
---@param seconds number
---@return nil
function RPC:setTimeout(seconds) end

--- Process incoming RPC messages. Call once per frame in `lurek.process(dt)`. Dispatches received RPC calls to registered handlers and invokes pending call callbacks when matching responses arrive. Also expires timed-out pending calls.
---@return table
function RPC:poll() end

--- Internal: expire pending calls that have exceeded their timeout.
---@return nil
function RPC:_expireTimeouts() end

--- Internal: dispatch a decoded RPC message.
---@param peer_id number
---@param data table
---@param responses table
---@return nil
function RPC:_dispatch(peer_id, data, responses) end

--- Get the number of registered RPC handlers.
---@return number
function RPC:getHandlerCount() end

---@class library.scheduler
library.scheduler = {}

--- Create a new coroutine scheduler. Manages a pool of coroutine tasks; each task can `yield(seconds)` to pause itself. Completed, errored, and removed tasks are cleaned up automatically.
---@param opts table
---@return Scheduler
function library.scheduler.newScheduler(opts) end

--- Add a new task function to the scheduler. The task receives a `yield` function as its first argument. Call `yield(seconds)` inside the task to pause for that many seconds.
---@param fn function
---@param name string
---@return number
function sched:add(fn, name) end

--- Remove a task by id.
---@param id number
---@return boolean
function sched:remove(id) end

--- Pause a task by id.  Paused tasks keep their remaining wait time but are not ticked until resumed.
---@param id number
---@return nil
function sched:pause(id) end

--- Resume a paused task by id.
---@param id number
---@return nil
function sched:resume(id) end

--- Return the status of a task.
---@param id number
---@return string|nil
---@return string|nil
function sched:getStatus(id) end

--- Step all active tasks by dt seconds. Tasks whose wait time has elapsed are resumed. A per-call iteration guard prevents infinite loops when a task yields 0 repeatedly.
---@param dt number
---@return number
function sched:update(dt) end

--- Return the number of active (non-done) tasks.
---@return number
function sched:getCount() end

--- Return the list of errors captured since creation (or last `clearErrors()`). Each entry is `{ id = number, msg = string }`.
---@return table
function sched:getErrors() end

--- Clear the captured error list.
---@return nil
function sched:clearErrors() end

--- Remove all tasks immediately.
---@return nil
function sched:clear() end

---@class library.stats
library.stats = {}

--- Create a new attribute.
---@param base number
---@return Attribute
function library.stats.newAttribute(base) end

--- Create a new buff.
---@param stat string
---@param add number
---@param mul number
---@param duration number
---@param source string
---@return Buff
function library.stats.newBuff(stat, add, mul, duration, source) end

--- Whether the buff has expired.
---@return boolean
function Buff:isExpired() end

--- Create a new skill.
---@param opts table|nil
---@return Skill
function library.stats.newSkill(opts) end

--- Create a new perk.
---@param opts table|nil
---@return Perk
function library.stats.newPerk(opts) end

--- Create action points with the given maximum.
---@param max_val number
---@return ActionPoints
function library.stats.newActionPoints(max_val) end

--- Create a morale tracker with the given maximum (current starts at max).
---@param max_val number
---@return Morale
function library.stats.newMorale(max_val) end

--- Create table-based XP thresholds (one value per level).
---@param values table
---@return LevelThresholds
function library.stats.newTableThresholds(values) end

--- Create linear XP thresholds using the formula base + (level-1)*increment.
---@param base number
---@param increment number
---@return LevelThresholds
function library.stats.newLinearThresholds(base, increment) end

--- Return the XP required to advance past the given level.
---@param level number
---@return number
function LevelThresholds:thresholdFor(level) end

--- Create a trait definition.
---@param buffs table
---@return table
function library.stats.newTraitDef(buffs) end

--- Register a named trait definition in the module registry.
---@param name string
---@param def table
---@return nil
function library.stats.defineTrait(name, def) end

--- Register a named race archetype.
---@param name string
---@param def table
---@return nil
function library.stats.defineRace(name, def) end

--- Register a named class archetype.
---@param name string
---@param def table
---@return nil
function library.stats.defineClass(name, def) end

--- Return a sorted list of all registered trait names.
---@return table
function library.stats.getTraitNames() end

--- Return a sorted list of all registered race names.
---@return table
function library.stats.getRaceNames() end

--- Return a sorted list of all registered class names.
---@return table
function library.stats.getClassNames() end

--- Apply race and/or class archetypes to an existing sheet. Base stat bonuses are added and listed traits are applied as permanent buffs.
---@param sheet Sheet
---@param race_name string|nil
---@param class_name string|nil
---@return nil
function library.stats.applyArchetypes(sheet, race_name, class_name) end

--- Create a new character sheet.
---@return Sheet
function library.stats.newSheet() end

--- Define a named attribute.
---@param name string
---@param base number
---@param opts table|nil
---@return nil
function Sheet:define(name, base, opts) end

--- Get effective value (base * multipliers + additive, clamped).
---@param name string
---@return number|nil
function Sheet:get(name) end

--- Get raw base value.
---@return nil
function Sheet:getBase(name) end

--- Set base value (clamped to min/max).
---@return nil
function Sheet:setBase(name, value) end

--- Set the minimum clamp value for an attribute.
---@param name string
---@param val number
---@return nil
function Sheet:setMin(name, val) end

--- Set the maximum clamp value for an attribute.
---@param name string
---@param val number
---@return nil
function Sheet:setMax(name, val) end

--- Get the current minimum clamp for an attribute.
---@param name string
---@return number|nil
function Sheet:getMin(name) end

--- Get the current maximum clamp for an attribute.
---@param name string
---@return number|nil
function Sheet:getMax(name) end

--- Set the regeneration rate for an attribute.
---@param name string
---@param val number
---@return nil
function Sheet:setRegen(name, val) end

--- Get the regeneration rate for an attribute.
---@param name string
---@return number|nil
function Sheet:getRegen(name) end

--- Get all defined attribute names.
---@return nil
function Sheet:getStatNames() end

--- Add a buff to the sheet and return its numeric handle. When stack_mode is provided and a duplicate buff exists (same stat + source), the mode controls behavior: None rejects, Duration extends, Intensity increases.
---@param stat string
---@param add number
---@param mul number
---@param duration number
---@param source string
---@param stack_mode string|nil
---@return number|nil
function Sheet:addBuff(stat, add, mul, duration, source, stack_mode) end

--- Remove a buff by its numeric handle.
---@param handle number
---@return boolean
function Sheet:removeBuff(handle) end

--- Remove all active buffs, or only those affecting a specific attribute.
---@param stat string|nil
---@return nil
function Sheet:clearBuffs(stat) end

--- Return all active (non-expired) buffs as an array of info tables. Each entry has: handle, stat, add, mul, duration, remaining, source.
---@param stat string|nil
---@return table
function Sheet:getBuffs(stat) end

--- Count active (non-expired) buffs, optionally limited to one attribute.
---@param stat string|nil
---@return number
function Sheet:getBuffCount(stat) end

--- Apply a registered trait's permanent buffs to this sheet.
---@param trait_name string
---@return table
function Sheet:applyTraitBuffs(trait_name) end

--- Remove all buffs that were applied by a named trait.
---@param trait_name string
---@return boolean
function Sheet:removeTraitBuffs(trait_name) end

--- Return true if a named trait is currently active on this sheet.
---@param name string
---@return boolean
function Sheet:hasTrait(name) end

--- Return a sorted list of all currently active trait names.
---@return table
function Sheet:getActiveTraits() end

--- Define a named skill on this sheet.
---@param name string
---@param opts table|nil
---@return nil
function Sheet:defineSkill(name, opts) end

--- Advance a skill by one level. Returns false if already at max level or unknown.
---@param name string
---@return boolean
function Sheet:learnSkill(name) end

--- Attempt to use a skill: deducts cost and starts cooldown. Returns false plus a reason string on failure.
---@param name string
---@return boolean
function Sheet:useSkill(name) end

--- Get the current level of a named skill (0 = not learned).
---@param name string
---@return number
function Sheet:getSkillLevel(name) end

--- Get the remaining cooldown in seconds for a named skill.
---@param name string
---@return number
function Sheet:getCooldownRemaining(name) end

--- Define a named perk on this sheet.
---@param name string
---@param opts table|nil
---@return nil
function Sheet:definePerk(name, opts) end

--- Acquire a perk if requirements are met. Returns false if already acquired or level too low.
---@param name string
---@return boolean
function Sheet:acquirePerk(name) end

--- Return true if a named perk has been acquired.
---@param name string
---@return boolean
function Sheet:hasPerk(name) end

--- Set a boolean flag on this sheet.
---@param name string
---@return nil
function Sheet:setFlag(name) end

--- Clear (remove) a boolean flag.
---@param name string
---@return nil
function Sheet:clearFlag(name) end

--- Return true if a boolean flag is set.
---@param name string
---@return boolean
function Sheet:hasFlag(name) end

--- Return a sorted list of all set flag names.
---@return table
function Sheet:getFlags() end

--- Award XP and apply automatic level-ups. Returns the number of levels gained.
---@param amount number
---@return number
function Sheet:addXP(amount) end

--- Return the current accumulated XP.
---@return number
function Sheet:getXP() end

--- Directly set the accumulated XP (does not trigger level-ups).
---@param v number
---@return nil
function Sheet:setXP(v) end

--- Return the current level.
---@return number
function Sheet:getLevel() end

--- Directly set the character level.
---@param v number
---@return nil
function Sheet:setLevel(v) end

--- Replace the level threshold configuration.
---@param t LevelThresholds
---@return nil
function Sheet:setLevelThresholds(t) end

--- Record a use of a stat for use-based levelling. Applies growth if configured.
---@param name string
---@return nil
function Sheet:recordUse(name) end

--- Return the number of recorded uses of an attribute.
---@param name string
---@return number
function Sheet:getUseCount(name) end

--- Initialise action points with the given maximum (current also set to max).
---@param max_val number
---@return nil
function Sheet:setActionPoints(max_val) end

--- Return current and maximum action points.
---@return number
function Sheet:getActionPoints() end

--- Spend action points. Returns false if insufficient AP.
---@param amount number
---@return boolean
function Sheet:spendActionPoints(amount) end

--- Reset current AP to maximum (call at the start of each turn).
---@return nil
function Sheet:beginTurn() end

--- Recover AP (partial restore), capped at maximum. Returns new current value.
---@param amount number
---@return number
function Sheet:recoverActionPoints(amount) end

--- Initialise the morale tracker with the given maximum.
---@param max_val number
---@return nil
function Sheet:setMorale(max_val) end

--- Return current and maximum morale values.
---@return number
function Sheet:getMorale() end

--- Adjust morale by a delta (positive or negative), clamped to [0, max].
---@param delta number
---@return nil
function Sheet:adjustMorale(delta) end

--- Set the morale value below which the unit enters panic.
---@param val number
---@return nil
function Sheet:setPanicThreshold(val) end

--- Set the morale value below which the unit goes berserk.
---@param val number
---@return nil
function Sheet:setBerserkThreshold(val) end

--- Evaluate morale level and update panic/berserk flags.
---@return string|nil
function Sheet:checkMorale() end

--- Set resistance to a damage type (clamped to [0, 1]).
---@param dtype string
---@param val number
---@return nil
function Sheet:setResistance(dtype, val) end

--- Return the resistance fraction for a damage type (default 0).
---@param dtype string
---@return number
function Sheet:getResistance(dtype) end

--- Apply damage to an attribute, reduced by resistance. Returns actual damage dealt.
---@param stat string
---@param amount number
---@param dtype string|nil
---@return number
function Sheet:applyDamage(stat, amount, dtype) end

--- Set current encumbrance and its maximum capacity.
---@param cur number
---@param max_val number
---@return nil
function Sheet:setEncumbrance(cur, max_val) end

--- Return current and maximum encumbrance values.
---@return number
function Sheet:getEncumbrance() end

--- Return true if current weight exceeds the encumbrance limit.
---@return boolean
function Sheet:isEncumbered() end

--- Set the sheet's base initiative value.
---@param val number
---@return nil
function Sheet:setInitiative(val) end

--- Return the current initiative value.
---@return number
function Sheet:getInitiative() end

--- Advance time: tick buff durations, skill cooldowns, apply regen.
---@param dt number
---@return nil
function Sheet:update(dt) end

--- Capture a snapshot of the sheet's core state (attributes, XP, level, flags, resistances, AP, morale).
---@return table
function Sheet:snapshot() end

--- Restore sheet state from a snapshot previously created by Sheet:snapshot.
---@param snap table
---@return nil
function Sheet:restore(snap) end

--- Encode a snapshot table to a JSON string via `lurek.serial.toJson`.
---@param snap table
---@return string
function library.stats.snapshotToJson(snap) end

--- Decode a JSON snapshot string back into a Lua table via `lurek.serial.fromJson`. The returned table can be passed to `Sheet:restore`.
---@param str string
---@return table
function library.stats.snapshotFromJson(str) end
