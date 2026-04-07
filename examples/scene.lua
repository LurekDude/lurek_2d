-- examples/scene.lua
-- luna.scene — Scene stack, transitions, registry, data store, depth-sorted rendering.
-- All luna.scene API methods demonstrated with code and comments.

-- ── Scene Table Structure ─────────────────────────────────────────────────────

-- A scene is a plain Lua table with optional callback methods.
-- The engine calls these methods automatically as scenes are pushed/popped.
--
-- Callbacks:
--   enter(self, params?)     — called when this scene becomes active
--   leave(self)              — called when this scene is removed from the stack
--   pause(self)              — called when a new scene is pushed above this one
--   resume(self)             — called when the scene above is popped off
--   update(self, dt)         — called each frame while this is the active scene
--   draw(self)               — called each frame for rendering
--   drawSorted(self)         — called by a DepthSorter:flush() for depth-ordered objects

local MenuScene = {}
MenuScene.__index = MenuScene

function MenuScene.new()
    return setmetatable({}, MenuScene)
end

function MenuScene:enter(params)
    -- params is whatever was passed as the 4th arg to luna.scene.push()
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

function MenuScene:update(dt)
    if luna.keyboard.isDown("return") then
        luna.scene.switchTo(GameScene.new(), "fade", 0.5, { level = 1 })
    end
end

function MenuScene:draw()
    luna.gfx.print("Press Enter to start", 100, 100)
end

local GameScene = {}
GameScene.__index = GameScene

function GameScene.new()
    return setmetatable({ score = 0 }, GameScene)
end

function GameScene:enter(params)
    print("GameScene entered, level =", params and params.level)
end

function GameScene:update(dt)
    if luna.keyboard.isDown("escape") then
        luna.scene.pop("slide_right", 0.3)
    end
end

function GameScene:draw()
    luna.gfx.print("Score: " .. self.score, 100, 100)
end

-- ── Stack Operations ──────────────────────────────────────────────────────────

-- push(scene, transition?, duration?, params?)
-- Pushes a scene onto the stack. The previous scene receives pause().
-- Transition strings: "none", "fade", "slide_left", "slide_right", "slide_up", "slide_down"
luna.scene.push(MenuScene.new())
luna.scene.push(GameScene.new(), "fade", 0.4, { level = 1 })

-- pop(transition?, duration?)
-- Removes the top scene. The newly revealed scene receives resume().
luna.scene.pop("none")

-- switchTo(scene, transition?, duration?, params?)
-- Replaces the top scene in one operation (leave old → enter new).
luna.scene.switchTo(MenuScene.new(), "slide_left", 0.3)

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
luna.scene.registerScene("menu", MenuScene.new())
luna.scene.registerScene("game", GameScene.new())

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
