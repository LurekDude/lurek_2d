-- content/library/loot/example.lua
-- Self-contained loot table example — boss encounter with magic-find and pity.
--
-- Run via `lurek2d <folder-with-this-as-main.lua>` or load from a demo.
-- This file does not call any GPU/audio APIs and can be exec'd in a headless VM.

local loot = require("library.loot")

-- ─── 1. Build the base loot table ────────────────────────────────────────────

local boss_drops = loot.fromList({
    { id = "gold_pile",     weight = 60                              },
    { id = "potion_minor",  weight = 25, meta = { qty = 3 }          },
    { id = "ring_iron",     weight = 12, meta = { tier = "common" }  },
    { id = "ring_silver",   weight =  2, meta = { tier = "uncommon" }},
    { id = "ring_gold",     weight =  1, meta = { tier = "rare" }    },
})

print(string.format("base table has %d entries, total weight %d",
    #boss_drops:ids(), boss_drops:totalWeight()))
print(string.format("p(ring_gold) = %.4f", boss_drops:probability("ring_gold")))

-- ─── 2. Magic-find modifier triples weight of all rings ──────────────────────

local mf = loot.newModifier():add("magic_find", function(entry, ctx)
    if entry.id:find("ring_") and ctx.luck and ctx.luck > 1.0 then
        return ctx.luck * 1.5
    end
    return 1.0
end)

local ctx = { luck = 2.0, boss = true }
local boosted = mf:apply(boss_drops, ctx)
print(string.format("with luck=%.1f, p(ring_gold) = %.4f",
    ctx.luck, boosted:probability("ring_gold")))

-- ─── 3. Pity timer for the rare ring ─────────────────────────────────────────

local pity = loot.newPity("ring_gold", 50)

-- ─── 4. Composable drop description ──────────────────────────────────────────

local drop = loot.newDrop()
    :roll(boosted, { count = 5 })            -- 5 rolls from boosted table
    :guarantee("scroll_recall", 1)           -- always one recall scroll
    :when(function(c) return c.boss end)     -- boss-only clauses below
        :roll(boosted, { count = 2, chance = 0.5, tag = "boss-bonus" })

print(drop:explain(ctx))

-- ─── 5. Resolve the drop and feed pity ──────────────────────────────────────

local rng = loot.getDefaultRng()
local rewards = drop:resolve(ctx, rng)

local rare_dropped = false
for _, r in ipairs(rewards) do
    print(string.format("  dropped %s ×%d%s",
        r.id, r.count, r.tag and (" ["..r.tag.."]") or ""))
    if pity:notice(r.id) then
        print("  -> pity primed: next draw will force ring_gold")
    end
    if r.id == "ring_gold" then rare_dropped = true end
end

print(string.format("rare dropped this run: %s", tostring(rare_dropped)))
print(string.format("pity counter now %d (primed=%s)",
    pity:getCounter(), tostring(pity:isPrimed())))

-- ─── 6. Save/restore pity state ──────────────────────────────────────────────

local blob = pity:save()
local restored = loot.newPity("ring_gold", 50):restore(blob)
print(string.format("restored pity counter = %d", restored:getCounter()))

return boss_drops, drop, pity   -- exposed for inspection by external runners
