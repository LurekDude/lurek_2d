-- examples/modding.lua
-- lurek.modding — Mod metadata containers and managers for game modding support.
-- Discover, validate, hot-reload, and hook into game logic from external mods.

-- ── Mod Object ────────────────────────────────────────────────────────────────

-- newMod(info) → Mod
-- info must have at least `id`.  Optional: name, version, author, description,
-- deps (array of id strings), priority (lower = load first).
local my_mod = lurek.modding.newMod({
    id          = "example_mod",
    name        = "Example Mod",
    version     = "1.0.0",
    author      = "YourName",
    description = "Adds a new weapon type and rebalances enemy HP.",
    deps        = { "base_game" },
    priority    = 10,
})

-- ── Mod Metadata ─────────────────────────────────────────────────────────────

local id    = my_mod:getId()            -- "example_mod"
local name  = my_mod:getName()          -- "Example Mod"
local ver   = my_mod:getVersion()       -- "1.0.0"
local auth  = my_mod:getAuthor()        -- "YourName"
local desc  = my_mod:getDescription()   -- "Adds a new weapon..."
local deps  = my_mod:getDependencies()  -- { "base_game" }
local pri   = my_mod:getPriority()      -- 10

-- ── Enable / Load Status ─────────────────────────────────────────────────────

my_mod:setEnabled(true)
local enabled = my_mod:isEnabled()   -- true
local loaded  = my_mod:isLoaded()    -- false until ModManager loads it

-- ── Hooks ────────────────────────────────────────────────────────────────────

-- hook(name, fn) — attach a named callback to this mod
my_mod:hook("onEnemyDeath", function(enemy)
    -- custom on-death logic
end)

my_mod:hook("onPlayerLevelUp", function(player_stats)
    player_stats.max_hp = player_stats.max_hp + 20
end)

-- hasHook(name) → boolean
local has = my_mod:hasHook("onEnemyDeath")  -- true

-- getHook(name) → fn?
local fn = my_mod:getHook("onPlayerLevelUp")

-- getHookNames() → table (array of string)
local hook_names = my_mod:getHookNames()  -- { "onEnemyDeath", "onPlayerLevelUp" }

-- ── Config ───────────────────────────────────────────────────────────────────

-- setConfig(value) — store arbitrary config table for this mod
my_mod:setConfig({ damage_bonus = 5, new_enemy_hp_scale = 0.9 })

-- getConfig() → value (table, number, string, etc.)
local cfg = my_mod:getConfig()  -- { damage_bonus=5, new_enemy_hp_scale=0.9 }

-- ── Cleanup ───────────────────────────────────────────────────────────────────

-- releaseRefs() — drop all Lua function references (call before unloading mod)
my_mod:releaseRefs()

-- ── ModManager ────────────────────────────────────────────────────────────────

-- newModManager() → ModManager
local manager = lurek.modding.newModManager()

-- ── Registering Mods ─────────────────────────────────────────────────────────

-- registerMod(mod) — add a Mod object to the manager
manager:registerMod(my_mod)

-- create and register more mods
local weapon_mod = lurek.modding.newMod({ id="weapon_pack", name="Weapon Pack", version="2.1", priority=5 })
manager:registerMod(weapon_mod)

-- ── Querying ─────────────────────────────────────────────────────────────────

-- hasMod(id) → boolean
local has_mod = manager:hasMod("example_mod")  -- true

-- getModCount() → integer
local count = manager:getModCount()  -- 2

-- getAllMods() → table (array of info tables)
local all = manager:getAllMods()
for _, info in ipairs(all) do
    -- info.id, info.name, info.version, info.author, info.enabled, etc.
end

-- getLoadOrder() → table (sorted by dependency + priority)
local order = manager:getLoadOrder()
for _, info in ipairs(order) do
    -- process mods in load order
end

-- ── Dependency Validation ────────────────────────────────────────────────────

-- validateDependencies() → table — list of mod IDs with missing dependencies
local missing = manager:validateDependencies()

-- hasCircularDependencies() → boolean
local has_cycle = manager:hasCircularDependencies()

-- ── Manual Load Order Override ───────────────────────────────────────────────

-- setLoadOrder(table) — force a specific load order by mod ID array
manager:setLoadOrder({ "base_game", "weapon_pack", "example_mod" })

-- clearLoadOrder() — revert to priority-based automatic ordering
manager:clearLoadOrder()

-- ── Folder Scanning ──────────────────────────────────────────────────────────

-- scanFolder(path) → table  — discover and auto-register mods in a folder
-- Expects each mod to have a mod.toml describing its metadata.
local found = manager:scanFolder("mods/")
for _, info in ipairs(found) do
    -- info.id, info.path, etc.
end

-- getModPath(id) → string?  — filesystem path to a registered mod
local path = manager:getModPath("weapon_pack")  -- e.g. "mods/weapon_pack/"

-- ── Hot-Reload Support ───────────────────────────────────────────────────────

-- markForReload(id) → boolean  — queue a mod for hot-reload
manager:markForReload("example_mod")

-- getReloadQueue() → table  — array of mod IDs pending reload
local queue = manager:getReloadQueue()

-- clearReloadQueue() — discard pending reloads
manager:clearReloadQueue()

-- ── Unregister ───────────────────────────────────────────────────────────────

-- unregisterMod(id) — remove a mod from the manager (does not unload Lua state)
manager:unregisterMod("example_mod")

-- ── Typical Workflow ─────────────────────────────────────────────────────────

--[[
local mod_manager

function lurek.init()
    mod_manager = lurek.modding.newModManager()
    local mods = mod_manager:scanFolder("mods/")
    -- mods auto-registered from mod.toml files

    if mod_manager:hasCircularDependencies() then
        error("Circular mod dependencies detected!")
    end
    local missing_deps = mod_manager:validateDependencies()
    if #missing_deps > 0 then
        error("Missing dependencies: " .. table.concat(missing_deps, ", "))
    end

    for _, info in ipairs(mod_manager:getLoadOrder()) do
        -- load each mod's main.lua in order
        lurek.fs.load("mods/" .. info.id .. "/main.lua")
    end
end
]]
