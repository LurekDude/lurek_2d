-- examples/scene.lua
-- lurek.scene — Scene stack, transitions, registry, data store, depth-sorted rendering.

-- ── Scene Factory (recommended) ───────────────────────────────────────────────

lurek.scene.define(def)  returns a constructor function.
-- Define methods on the class table, then call ClassName() to create instances.
local MenuScene = lurek.scene.define({})

function MenuScene:enter(params)
    print("MenuScene entered", params and params.from or "")
end

function MenuScene:leave()
    print("MenuScene leaving")
end

function MenuScene:pause()
    print("MenuScene paused (another scene pushed above)")
end

function MenuScene:resume()
    print("MenuScene resumed")
end

function MenuScene:process(dt)
    if lurek.keyboard.isDown("return") then
        lurek.scene.switchTo(GameScene(), "fade", 0.5, { level = 1 })
    end
end

function MenuScene:render()
    lurek.gfx.print("Press Enter to start", 100, 100)
end

-- GameScene — another class defined with lurek.scene.define()
local GameScene = lurek.scene.define({})

function GameScene:ready()
    self.score = 0
end

function GameScene:enter(params)
    print("GameScene entered, level =", params and params.level)
end

function GameScene:process(dt)
    if lurek.keyboard.isDown("escape") then
        lurek.scene.pop("slide_right", 0.3)
    end
end

function GameScene:render()
    lurek.gfx.print("Score: " .. (self.score or 0), 100, 100)
end

-- ── One-off scene with lurek.scene.new() ───────────────────────────────────────

lurek.scene.new(def)  creates a single scene instance directly.
-- Use when you need an unnamed, one-time scene.
local splash = lurek.scene.new({
    ready  = function(self) self.t = 0 end,
    process= function(self, dt) self.t = self.t + dt; if self.t > 2 then lurek.scene.pop() end end,
    render = function(self) lurek.gfx.print("Loading…", 300, 280) end,
})

-- ── Stack Operations ──────────────────────────────────────────────────────────

-- push(scene, transition?, duration?, params?)
-- Pushes a scene onto the stack. The previous scene receives pause().
-- Transition strings: "none", "fade", "slide_left", "slide_right", "slide_up", "slide_down"
lurek.scene.push(MenuScene())
lurek.scene.push(GameScene(), "fade", 0.4, { level = 1 })
lurek.scene.push(splash)   -- one-off instance, no ()

-- pop(transition?, duration?)
-- Removes the top scene. The newly revealed scene receives resume().
lurek.scene.pop("none")

-- switchTo(scene, transition?, duration?, params?)
-- Replaces the top scene in one operation (leave old → enter new).
lurek.scene.switchTo(MenuScene(), "slide_left", 0.3)

-- clear()
-- Removes all scenes, calling leave() on each in reverse order.
lurek.scene.clear()

-- popTo(name)
-- Pops until the named registered scene is the top scene. Returns boolean.
local reached = lurek.scene.popTo("menu")

-- ── Stack Query ───────────────────────────────────────────────────────────────

-- getStackSize() → integer
local depth = lurek.scene.getStackSize()  -- number of scenes on stack

-- isEmpty() → boolean
local empty = lurek.scene.isEmpty()

-- getCurrent() → table? — returns the top scene table or nil
local top = lurek.scene.getCurrent()

-- ── Transitions ───────────────────────────────────────────────────────────────

-- isTransitioning() → boolean
local transitioning = lurek.scene.isTransitioning()

-- getTransitionProgress() → number (0.0–1.0)
local progress = lurek.scene.getTransitionProgress()

-- ── Scene Registry ────────────────────────────────────────────────────────────

-- registerScene(name, scene_table) — store a scene by name for deferred push
lurek.scene.registerScene("menu", MenuScene())
lurek.scene.registerScene("game", GameScene())

-- getRegistered(name) → table? — retrieve by name
local menu_scene = lurek.scene.getRegistered("menu")

-- hasRegistered(name) → boolean
local exists = lurek.scene.hasRegistered("game")  -- true

-- getRegisteredNames() → {string,...}
local names = lurek.scene.getRegisteredNames()  -- {"menu", "game"}

-- unregisterScene(name) — remove from registry
lurek.scene.unregisterScene("game")

-- ── Data Store ────────────────────────────────────────────────────────────────

-- The data store is shared across all scenes in the stack.
-- Use it to pass information between scenes without coupling them.

-- setData(key, value)
lurek.scene.setData("player_name", "Alice")
lurek.scene.setData("high_score", 5000)
lurek.scene.setData("save", { level = 3, health = 80 })

-- getData(key) → value?
local name = lurek.scene.getData("player_name")   -- "Alice"
local save = lurek.scene.getData("save")          -- {level=3, health=80}

-- hasData(key) → boolean
local has_hs = lurek.scene.hasData("high_score")  -- true

-- removeData(key) — delete the entry
lurek.scene.removeData("high_score")

-- ── DepthSorter ───────────────────────────────────────────────────────────────

-- newDepthSorter() → DepthSorter
-- Create a depth sorter to render multiple objects in z-order within one draw() call.
local sorter = lurek.scene.newDepthSorter()

-- add(fn, depth) — register a plain draw function at the given depth
sorter:add(function()
    lurek.gfx.drawRect("fill", 100, 100, 32, 32)  -- background layer
end, -10)

sorter:add(function()
    lurek.gfx.drawRect("fill", 200, 200, 32, 32)  -- foreground layer
end, 10)

-- addObject(obj) — register a table with a `drawSorted` method at obj.depth
local tree = {
    depth = 5,
    x = 300, y = 200,
    drawSorted = function(self)
        lurek.gfx.print("Tree", self.x, self.y)
    end
}
sorter:addObject(tree)

-- sort() — sort in depth-ascending order (call before flush if needed manually)
sorter:sort()

-- getCount() → integer — number of registered entries
local count = sorter:getCount()  -- 3

-- flush() — calls all callbacks in sorted order, then clears the sorter
sorter:flush()

-- clear() — remove all entries without calling them
sorter:clear()

-- ── update / draw delegation ──────────────────────────────────────────────────

-- lurek.scene.update(dt) — calls update(dt) on the top scene
lurek.scene.draw()  -- calls draw() on ALL scenes from bottom to top

-- ── Typical Usage in main.lua ─────────────────────────────────────────────────

--[[
function lurek.init()
    lurek.scene.push(MenuScene.new())
end

function lurek.process(dt)
    lurek.scene.update(dt)
end

function lurek.render()
    lurek.scene.draw()
end
]]


-- ─── lurek.scene ────────────────────────────────────────────────────────────────
lurek.scene.process(1.0)  -- Calls `scene:ready(self)` on the top scene if not yet fired, then `scene:process(dt)`
lurek.scene.processLate(1.0)  -- Calls `scene:process_late(dt)` on the topmost scene (after process, before render)
lurek.scene.processPhysics(1.0)  -- Calls `scene:process_physics(dt)` on the topmost scene (fixed timestep)
lurek.scene.render()  -- Draws all scenes in the stack from bottom to top
lurek.scene.renderUi()  -- Draws UI overlay for all scenes in the stack from bottom to top
