-- demos/showcase/entity_showcase/main.lua
-- Entity Showcase — every lurek.entity.Universe method demonstrated interactively
-- Controls: SPACE next chapter, R reset, ESC quit
-- Run with: cargo run -- content/demos/showcase/entity_showcase

-- ── state ─────────────────────────────────────────────────────
local ecs
local chapter      = 0
local chapter_name = "Press SPACE to begin"
local log          = {}   -- on-screen API call results (max 10 lines)

-- ── systems ───────────────────────────────────────────────────
local move_sys = {
    update = function(self, world, dt)
        local ids = world:query("pos", "vel")
        for _, id in ipairs(ids) do
            local p = world:get(id, "pos")
            local v = world:get(id, "vel")
            p.x = p.x + v.x * dt
            p.y = p.y + v.y * dt
            if p.x < 22  or p.x > 778 then v.x = -v.x ; world:set(id, "vel", v) end
            if p.y < 220 or p.y > 566 then v.y = -v.y ; world:set(id, "vel", v) end
            world:set(id, "pos", p)
        end
    end,
}

local draw_sys = {
    draw = function(self, world)
        local sorted = world:getEntitiesSorted()
        for _, id in ipairs(sorted) do
            if world:has(id, "pos") and world:has(id, "col") then
                local p = world:get(id, "pos")
                local c = world:get(id, "col")
                local r = world:has(id, "sz") and world:get(id, "sz") or 9
                lurek.gfx.setColor(c[1], c[2], c[3], 0.88)
                lurek.gfx.circle("fill", p.x, p.y, r)
                lurek.gfx.setColor(c[1] * 0.5, c[2] * 0.5, c[3] * 0.5, 0.5)
                lurek.gfx.circle("line", p.x, p.y, r)
            end
        end
    end,
}

local event_sys = {
    on_death = function(self, world, ...)
        -- receives emit("on_death", ...) from chapter 7
    end,
}

-- ── helpers ───────────────────────────────────────────────────
local function log_add(t)
    table.insert(log, t)
    if #log > 10 then table.remove(log, 1) end
end

local function ent(w, x, y, vx, vy, cr, cg, cb, sz)
    local e = w:spawn()
    w:set(e, "pos", { x = x, y = y })
    w:set(e, "vel", { x = vx, y = vy })
    w:set(e, "col", { cr, cg, cb })
    w:set(e, "sz",  sz or 9)
    return e
end

local function reset()
    if ecs then ecs:clear() ; ecs:release() end
    ecs = lurek.entity.newUniverse()

    -- bitmap tag definitions (used in chapter 3)
    ecs:defineTag("HOSTILE")
    ecs:defineTag("FAST")
    ecs:defineTag("BOSS")

    -- blueprint definitions (used in chapter 6)
    ecs:defineBlueprint("drone", {
        pos = { x = 200, y = 350 }, vel = { x = 55, y = 35 },
        col = { 0.3, 0.7, 1.0 },   sz  = 9,
    })
    ecs:extendBlueprint("heavy_drone", "drone", {
        col = { 1.0, 0.8, 0.2 }, sz = 13,
    })

    -- register systems
    ecs:addSystem(move_sys)
    ecs:addSystem(draw_sys)
    ecs:addSystem(event_sys)

    chapter      = 0
    chapter_name = "Press SPACE to begin"
    log          = {}
end

-- ── chapters ──────────────────────────────────────────────────
local chapters = {}

chapters[1] = function()
    chapter_name = "1/7 — Lifecycle & Components"
    log = {}
    -- spawn / isAlive / getEntityCount / getEntities
    local a = ecs:spawn()
    local b = ecs:spawn()
    log_add("spawn() -> " .. a .. ", " .. b)
    log_add("isAlive(" .. a .. ") -> " .. tostring(ecs:isAlive(a)))
    log_add("getEntityCount() -> " .. ecs:getEntityCount())
    local all = ecs:getEntities()
    log_add("getEntities() -> " .. #all .. " total")
    -- set / get / has / getComponents
    ecs:set(a, "pos", { x = 200, y = 380 })
    ecs:set(a, "vel", { x =  58, y =  40 })
    ecs:set(a, "col", { 0.4, 0.9, 0.4 })
    ecs:set(a, "sz",  10)
    ecs:set(b, "pos", { x = 580, y = 400 })
    ecs:set(b, "vel", { x = -50, y =  52 })
    ecs:set(b, "col", { 0.9, 0.3, 0.3 })
    ecs:set(b, "sz",  10)
    local pos = ecs:get(a, "pos")
    log_add("get(pos) -> x=" .. pos.x .. " y=" .. pos.y)
    log_add("has(pos)=" .. tostring(ecs:has(a, "pos")) .. "  has(armor)=" .. tostring(ecs:has(a, "armor")))
    local comps = ecs:getComponents(a)
    log_add("getComponents() -> " .. table.concat(comps, ", "))
    -- query / each
    local found = ecs:query("pos", "vel")
    log_add("query(pos,vel) -> " .. #found .. " entities")
    local cnt = 0
    ecs:each("pos", function(id, p) cnt = cnt + 1 end)
    log_add("each(pos) -> " .. cnt .. " visited")
    -- remove / kill
    ecs:remove(a, "sz")
    log_add("remove(sz); has(sz)=" .. tostring(ecs:has(a, "sz")))
    ecs:kill(b)
    log_add("kill(" .. b .. "); alive=" .. tostring(ecs:isAlive(b)) ..
            "  count=" .. ecs:getEntityCount())
end

chapters[2] = function()
    chapter_name = "2/7 — String Tags"
    log = {}
    local e1 = ent(ecs, 240, 375,  56, -42, 1.0, 0.55, 0.0)
    local e2 = ent(ecs, 540, 405, -62,  47, 0.6, 0.2,  1.0)
    -- addTag / hasTag / getTags
    ecs:addTag(e1, "enemy") ; ecs:addTag(e1, "ranged")
    ecs:addTag(e2, "enemy") ; ecs:addTag(e2, "melee")
    log_add("addTag: e1=enemy,ranged   e2=enemy,melee")
    log_add("hasTag(e1,enemy)=" .. tostring(ecs:hasTag(e1, "enemy")) ..
            "  hasTag(e1,boss)=" .. tostring(ecs:hasTag(e1, "boss")))
    log_add("getTags(e1) -> " .. table.concat(ecs:getTags(e1), ", "))
    -- getEntitiesByTag
    local enemies = ecs:getEntitiesByTag("enemy")
    log_add("getEntitiesByTag(enemy) -> " .. #enemies .. " entities")
    -- removeTag
    ecs:removeTag(e1, "ranged")
    log_add("removeTag(ranged)")
    log_add("getTags(e1) -> " .. table.concat(ecs:getTags(e1), ", "))
end

chapters[3] = function()
    chapter_name = "3/7 — Bitmap Tags"
    log = {}
    local e1 = ent(ecs, 175, 365,  52,  40, 0.95, 0.3, 0.3)
    local e2 = ent(ecs, 395, 405, -42,  44, 0.3, 0.95, 0.3)
    local e3 = ent(ecs, 610, 365,  46, -36, 0.3,  0.3, 0.95)
    -- getBitmapTagBit / bitmapTag / hasBitmapTag
    log_add("getBitmapTagBit: HOSTILE=" .. ecs:getBitmapTagBit("HOSTILE") ..
            "  FAST=" .. ecs:getBitmapTagBit("FAST"))
    ecs:bitmapTag(e1, "HOSTILE") ; ecs:bitmapTag(e1, "FAST")
    ecs:bitmapTag(e2, "HOSTILE")
    ecs:bitmapTag(e3, "FAST")
    log_add("bitmapTag: e1=HOSTILE+FAST   e2=HOSTILE   e3=FAST")
    log_add("hasBitmapTag(e1,HOSTILE)=" .. tostring(ecs:hasBitmapTag(e1, "HOSTILE")) ..
            "  (e3,HOSTILE)=" .. tostring(ecs:hasBitmapTag(e3, "HOSTILE")))
    -- queryBitmapTag / queryBitmapAny / queryBitmapAll
    log_add("queryBitmapTag(HOSTILE) -> " .. #ecs:queryBitmapTag("HOSTILE"))
    log_add("queryBitmapAny(HOSTILE,FAST) -> " ..
            #ecs:queryBitmapAny({"HOSTILE", "FAST"}))
    log_add("queryBitmapAll(HOSTILE,FAST) -> " ..
            #ecs:queryBitmapAll({"HOSTILE", "FAST"}))
    -- bitmapUntag
    ecs:bitmapUntag(e1, "FAST")
    log_add("bitmapUntag(e1,FAST)")
    log_add("queryBitmapAll(HOSTILE,FAST) -> " ..
            #ecs:queryBitmapAll({"HOSTILE", "FAST"}) .. "  (was 1, now 0)")
end

chapters[4] = function()
    chapter_name = "4/7 — Layers"
    log = {}
    local palettes = {
        { 1.0, 0.35, 0.35 },
        { 0.35, 1.0, 0.35 },
        { 0.35, 0.35, 1.0 },
    }
    local eids = {}
    for i = 1, 6 do
        local layer = ((i - 1) % 3) + 1
        local c     = palettes[layer]
        local e = ent(ecs, 90 + i * 95, 345 + (i % 2) * 90,
                      32 * (i % 2 == 0 and -1 or 1), 26,
                      c[1], c[2], c[3], 7 + layer * 2)
        ecs:setLayer(e, layer)
        table.insert(eids, e)
    end
    log_add("setLayer(1/2/3) set across 6 entities")
    log_add("getLayer(e1) -> " .. ecs:getLayer(eids[1]))
    log_add("getEntitiesByLayer(1) -> " .. #ecs:getEntitiesByLayer(1))
    log_add("getEntitiesByLayer(2) -> " .. #ecs:getEntitiesByLayer(2))
    log_add("getEntitiesByLayer(3) -> " .. #ecs:getEntitiesByLayer(3))
    local sorted = ecs:getEntitiesSorted()
    log_add("getEntitiesSorted() -> " .. #sorted .. " entities (layer order)")
end

chapters[5] = function()
    chapter_name = "5/7 — Hierarchy"
    log = {}
    -- setParent / getParent / getChildren / killRecursive
    local par = ent(ecs, 390, 375, 36, 28, 1.0, 0.9, 0.2, 14)
    ecs:setLayer(par, 1)
    local childs = {}
    for i = 1, 3 do
        local c = ent(ecs, 265 + i * 80, 445 + (i % 2) * 34,
                      -22 + i * 14, 28 - i * 7, 0.9, 0.4 + i * 0.1, 0.25)
        ecs:setParent(c, par)
        table.insert(childs, c)
    end
    log_add("setParent(child, parent) ×3")
    local got_par = ecs:getParent(childs[1])
    log_add("getParent(child1) -> " .. tostring(got_par) ..
            "  (==par? " .. tostring(got_par == par) .. ")")
    log_add("getChildren(par) -> " .. #ecs:getChildren(par) .. " children")
    -- orphan check
    local orphan = ent(ecs, 100, 265, 22, 18, 0.5, 0.5, 0.5, 7)
    log_add("getParent(orphan) -> " .. tostring(ecs:getParent(orphan)))
    -- killRecursive
    ecs:killRecursive(par)
    log_add("killRecursive(par)")
    log_add("isAlive(par)    -> " .. tostring(ecs:isAlive(par)))
    log_add("isAlive(child1) -> " .. tostring(ecs:isAlive(childs[1])))
    log_add("getEntityCount() -> " .. ecs:getEntityCount())
end

chapters[6] = function()
    chapter_name = "6/7 — Blueprints"
    log = {}
    log_add("hasBlueprint(drone)  -> " .. tostring(ecs:hasBlueprint("drone")))
    log_add("hasBlueprint(alien)  -> " .. tostring(ecs:hasBlueprint("alien")))
    local bps = ecs:listBlueprints()
    log_add("listBlueprints() -> " .. table.concat(bps, ", "))
    local bcomps = ecs:getBlueprintComponents("drone")
    local cnames = {}
    for k in pairs(bcomps) do table.insert(cnames, k) end
    table.sort(cnames)
    log_add("getBlueprintComponents(drone) -> " .. table.concat(cnames, ", "))
    -- spawnBlueprint
    local s1 = ecs:spawnBlueprint("drone")
    local s2 = ecs:spawnBlueprint("heavy_drone")
    log_add("spawnBlueprint(drone)       -> id=" .. s1)
    log_add("spawnBlueprint(heavy_drone) -> id=" .. s2)
    ecs:set(s1, "pos", { x = 245, y = 385 }) ; ecs:set(s1, "vel", { x = 62, y = 32 })
    ecs:set(s2, "pos", { x = 535, y = 365 }) ; ecs:set(s2, "vel", { x = -58, y = 48 })
    local c2 = ecs:get(s2, "col")
    log_add("heavy_drone col[1] (r) = " .. c2[1])
    -- removeBlueprint
    ecs:removeBlueprint("heavy_drone")
    log_add("removeBlueprint(heavy_drone)")
    log_add("hasBlueprint(heavy_drone) -> " .. tostring(ecs:hasBlueprint("heavy_drone")))
end

chapters[7] = function()
    chapter_name = "7/7 — Systems & Cleanup"
    log = {}
    for i = 1, 5 do
        ent(ecs, 95 + i * 127, 375 + (i % 2) * 58,
            32 - i * 4, 22 + i * 5, 0.5 + i * 0.1, 0.8 - i * 0.05, 0.9)
    end
    log_add("getSystemCount() -> " .. ecs:getSystemCount())
    log_add("update(dt)  -> invokes move_sys:update(world, dt) each frame")
    log_add("draw()      -> invokes draw_sys:draw(world) each frame")
    -- emit
    ecs:emit("on_death", 0)
    log_add("emit(on_death, 0) -> dispatched to event_sys")
    -- removeSystem
    ecs:removeSystem(event_sys)
    log_add("removeSystem(event_sys)")
    log_add("getSystemCount() -> " .. ecs:getSystemCount())
    -- clear / release on a temporary universe
    local tmp = lurek.entity.newUniverse()
    tmp:spawn() ; tmp:spawn() ; tmp:spawn()
    local before = tmp:getEntityCount()
    tmp:clear()
    log_add("clear(): " .. before .. " -> " .. tmp:getEntityCount() .. " entities")
    tmp:release()
    log_add("release() — universe destroyed")
end

-- ── load ──────────────────────────────────────────────────────
function lurek.init()
    lurek.window.setTitle("Entity Showcase")
    lurek.gfx.setBackgroundColor(0.06, 0.06, 0.12)
    reset()
end

-- ── update ────────────────────────────────────────────────────
function lurek.process(dt)
    if chapter > 0 then
        ecs:update(dt)
    end
end

-- ── draw ──────────────────────────────────────────────────────
function lurek.render()
    -- simulation area backdrop
    lurek.gfx.setColor(0.08, 0.08, 0.18)
    lurek.gfx.rectangle("fill", 10, 212, 780, 354)
    lurek.gfx.setColor(0.12, 0.12, 0.28)
    lurek.gfx.rectangle("line", 10, 212, 780, 354)

    -- ECS entities via draw_sys
    if chapter > 0 then
        ecs:draw()
    end

    -- top header bar
    lurek.gfx.setColor(0.10, 0.10, 0.22)
    lurek.gfx.rectangle("fill", 0, 0, 800, 28)
    lurek.gfx.setColor(0.45, 0.82, 1.0)
    lurek.gfx.print("Entity Showcase — lurek.entity Universe API", 10, 7)

    -- chapter title
    lurek.gfx.setColor(1.0, 0.85, 0.3)
    lurek.gfx.print(chapter_name, 10, 33)

    -- controls hint
    lurek.gfx.setColor(0.48, 0.48, 0.60)
    lurek.gfx.print("SPACE: next chapter    R: reset    ESC: quit", 10, 51)

    -- divider
    lurek.gfx.setColor(0.18, 0.18, 0.36)
    lurek.gfx.line(10, 68, 790, 68)

    -- API call log
    lurek.gfx.setColor(0.75, 0.95, 0.70)
    for i, line in ipairs(log) do
        lurek.gfx.print(line, 16, 72 + (i - 1) * 14)
    end

    -- status bar
    lurek.gfx.setColor(0.08, 0.08, 0.20)
    lurek.gfx.rectangle("fill", 0, 573, 800, 27)
    if chapter > 0 then
        lurek.gfx.setColor(0.40, 0.65, 0.40)
        lurek.gfx.print(
            "entities: " .. ecs:getEntityCount() ..
            "  systems: " .. ecs:getSystemCount() ..
            "  chapter: " .. chapter .. "/7" ..
            "  fps: " .. math.floor(lurek.time.getFPS()),
            10, 579
        )
    else
        lurek.gfx.setColor(0.40, 0.50, 0.40)
        lurek.gfx.print("Press SPACE to begin the entity showcase", 10, 579)
    end
end

-- ── keypressed ────────────────────────────────────────────────
function lurek.keypressed(key)
    if key == "escape" then
        lurek.signal.quit()
    elseif key == "space" then
        local next_ch = chapter + 1
        if next_ch > 7 then
            reset()
            chapters[1]()
            chapter = 1
        else
            chapters[next_ch]()
            chapter = next_ch
        end
    elseif key == "r" then
        reset()
        chapters[1]()
        chapter = 1
    end
end
