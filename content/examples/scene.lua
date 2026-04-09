-- examples/scene.lua
-- luna.scene — Scene stack, transitions, registry, data store, depth-sorted rendering.
-- All luna.scene API methods demonstrated with code and comments.
-- This file is documentation code, not a runnable game.

-- ── Scene Factory (recommended) ───────────────────────────────────────────────

-- luna.scene.define(def) returns a constructor function.
-- Define methods on the class table, then call ClassName() to create instances.
local MenuScene = luna.scene.define({})

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
    if luna.keyboard.isDown("return") then
        luna.scene.switchTo(GameScene(), "fade", 0.5, { level = 1 })
    end
end

function MenuScene:render()
    luna.gfx.print("Press Enter to start", 100, 100)
end

-- GameScene — another class defined with luna.scene.define()
local GameScene = luna.scene.define({})

function GameScene:ready()
    self.score = 0
end

function GameScene:enter(params)
    print("GameScene entered, level =", params and params.level)
end

function GameScene:process(dt)
    if luna.keyboard.isDown("escape") then
        luna.scene.pop("slide_right", 0.3)
    end
end

function GameScene:render()
    luna.gfx.print("Score: " .. (self.score or 0), 100, 100)
end

-- ── One-off scene with luna.scene.new() ───────────────────────────────────────

-- luna.scene.new(def) creates a single scene instance directly.
-- Use when you need an unnamed, one-time scene.
local splash = luna.scene.new({
    ready  = function(self) self.t = 0 end,
    process= function(self, dt) self.t = self.t + dt; if self.t > 2 then luna.scene.pop() end end,
    render = function(self) luna.gfx.print("Loading…", 300, 280) end,
})

-- ── Stack Operations ──────────────────────────────────────────────────────────

-- push(scene, transition?, duration?, params?)
-- Pushes a scene onto the stack. The previous scene receives pause().
-- Transition strings: "none", "fade", "slide_left", "slide_right", "slide_up", "slide_down"
luna.scene.push(MenuScene())
luna.scene.push(GameScene(), "fade", 0.4, { level = 1 })
luna.scene.push(splash)   -- one-off instance, no ()

-- pop(transition?, duration?)
-- Removes the top scene. The newly revealed scene receives resume().
luna.scene.pop("none")

-- switchTo(scene, transition?, duration?, params?)
-- Replaces the top scene in one operation (leave old → enter new).
luna.scene.switchTo(MenuScene(), "slide_left", 0.3)

-- clear()
-- Removes all scenes, calling leave() on each in reverse order.
luna.scene.clear()

-- popTo(name)
-- Pops until the named registered scene is the top scene. Returns boolean.
local reached = luna.scene.popTo("menu")

-- ── Stack Query ───────────────────────────────────────────────────────────────

-- getStackSize() → integer
local depth = luna.scene.getStackSize()  -- number of scenes on stack

-- isEmpty() → boolean
local empty = luna.scene.isEmpty()

-- getCurrent() → table? — returns the top scene table or nil
local top = luna.scene.getCurrent()

-- ── Transitions ───────────────────────────────────────────────────────────────

-- isTransitioning() → boolean
local transitioning = luna.scene.isTransitioning()

-- getTransitionProgress() → number (0.0–1.0)
local progress = luna.scene.getTransitionProgress()

-- ── Scene Registry ────────────────────────────────────────────────────────────

-- registerScene(name, scene_table) — store a scene by name for deferred push
luna.scene.registerScene("menu", MenuScene())
luna.scene.registerScene("game", GameScene())

-- getRegistered(name) → table? — retrieve by name
local menu_scene = luna.scene.getRegistered("menu")

-- hasRegistered(name) → boolean
local exists = luna.scene.hasRegistered("game")  -- true

-- getRegisteredNames() → {string,...}
local names = luna.scene.getRegisteredNames()  -- {"menu", "game"}

-- unregisterScene(name) — remove from registry
luna.scene.unregisterScene("game")

-- ── Data Store ────────────────────────────────────────────────────────────────

-- The data store is shared across all scenes in the stack.
-- Use it to pass information between scenes without coupling them.

-- setData(key, value)
luna.scene.setData("player_name", "Alice")
luna.scene.setData("high_score", 5000)
luna.scene.setData("save", { level = 3, health = 80 })

-- getData(key) → value?
local name = luna.scene.getData("player_name")   -- "Alice"
local save = luna.scene.getData("save")          -- {level=3, health=80}

-- hasData(key) → boolean
local has_hs = luna.scene.hasData("high_score")  -- true

-- removeData(key) — delete the entry
luna.scene.removeData("high_score")

-- ── DepthSorter ───────────────────────────────────────────────────────────────

-- newDepthSorter() → DepthSorter
-- Create a depth sorter to render multiple objects in z-order within one draw() call.
local sorter = luna.scene.newDepthSorter()

-- add(fn, depth) — register a plain draw function at the given depth
sorter:add(function()
    luna.gfx.drawRect("fill", 100, 100, 32, 32)  -- background layer
end, -10)

sorter:add(function()
    luna.gfx.drawRect("fill", 200, 200, 32, 32)  -- foreground layer
end, 10)

-- addObject(obj) — register a table with a `drawSorted` method at obj.depth
local tree = {
    depth = 5,
    x = 300, y = 200,
    drawSorted = function(self)
        luna.gfx.print("Tree", self.x, self.y)
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

-- luna.scene.update(dt) — calls update(dt) on the top scene
-- luna.scene.draw()     — calls draw() on ALL scenes from bottom to top

-- ── Typical Usage in main.lua ─────────────────────────────────────────────────

--[[
function luna.init()
    luna.scene.push(MenuScene.new())
end

function luna.process(dt)
    luna.scene.update(dt)
end

function luna.render()
    luna.scene.draw()
end
]]


-- ─── luna.scene ────────────────────────────────────────────────────────────────
luna.scene.process(1.0)  -- Calls `scene:ready(self)` on the top scene if not yet fired, then `scene:process(dt)`
luna.scene.processLate(1.0)  -- Calls `scene:process_late(dt)` on the topmost scene (after process, before render)
luna.scene.processPhysics(1.0)  -- Calls `scene:process_physics(dt)` on the topmost scene (fixed timestep)
luna.scene.render()  -- Draws all scenes in the stack from bottom to top
luna.scene.renderUi()  -- Draws UI overlay for all scenes in the stack from bottom to top
