-- content/examples/scene.lua
-- Lurek2D lurek.scene API Reference
-- Run with: cargo run -- content/examples/scene
--
-- Scenario: A multi-screen game with a title menu, gameplay level, pause
-- overlay, and game-over screen — managed via a scene stack with transitions
-- (fade, slide, wipe, iris). Includes scene registration, data passing,
-- preloading, and serialization for save/load.

print("=== lurek.scene — Scene Management ===\n")

-- =============================================================================
-- Scene Registration
-- =============================================================================

--@api-stub: lurek.scene.define
-- Define scenes using inline tables (alternative to registerScene).
lurek.scene.define("title", {
    process = function(dt) end,
    render = function() end,
})

--@api-stub: lurek.scene.new
-- Create a scene object for more complex setups.
local gameplay = lurek.scene.new("gameplay")

--@api-stub: lurek.scene.registerScene
lurek.scene.registerScene("settings", {
    process = function(dt) end,
    render = function() end,
})

--@api-stub: lurek.scene.hasRegistered
print("has title: " .. tostring(lurek.scene.hasRegistered("title")))

--@api-stub: lurek.scene.getRegistered
local title = lurek.scene.getRegistered("title")

--@api-stub: lurek.scene.getRegisteredNames
local names = lurek.scene.getRegisteredNames()
print("registered: " .. table.concat(names, ", "))

--@api-stub: lurek.scene.unregisterScene
-- lurek.scene.unregisterScene("settings")

-- =============================================================================
-- Scene Stack — Push/Pop navigation
-- =============================================================================

--@api-stub: lurek.scene.push
lurek.scene.push("title")

--@api-stub: lurek.scene.getStackSize
print("stack depth: " .. lurek.scene.getStackSize())

--@api-stub: lurek.scene.depth
print("depth: " .. lurek.scene.depth())

--@api-stub: lurek.scene.isEmpty
print("empty: " .. tostring(lurek.scene.isEmpty()))

--@api-stub: lurek.scene.getCurrent
local current = lurek.scene.getCurrent()
print("current scene: " .. tostring(current))

--@api-stub: lurek.scene.getActiveScenes
local active = lurek.scene.getActiveScenes()
print("active scenes: " .. #active)

--@api-stub: lurek.scene.switchTo
-- Replace current scene (no stack growth).
lurek.scene.switchTo("gameplay")

--@api-stub: lurek.scene.pop
lurek.scene.pop()

--@api-stub: lurek.scene.popTo
-- Pop back to a named scene (useful for "back to menu").
lurek.scene.popTo("title")

--@api-stub: lurek.scene.clear
-- lurek.scene.clear()

-- =============================================================================
-- Overlay Scenes
-- =============================================================================

--@api-stub: lurek.scene.pushOverlay
-- Push pause menu as an overlay (gameplay renders beneath it).
lurek.scene.pushOverlay("pause_menu")

--@api-stub: lurek.scene.isOverlay
print("is overlay: " .. tostring(lurek.scene.isOverlay("pause_menu")))

-- =============================================================================
-- Scene Lifecycle Callbacks
-- =============================================================================

--@api-stub: lurek.scene.update
lurek.scene.update(1/60)

--@api-stub: lurek.scene.process
lurek.scene.process(1/60)

--@api-stub: lurek.scene.processPhysics
lurek.scene.processPhysics(1/60)

--@api-stub: lurek.scene.processLate
lurek.scene.processLate(1/60)

--@api-stub: lurek.scene.draw
lurek.scene.draw()

--@api-stub: lurek.scene.render
lurek.scene.render()

--@api-stub: lurek.scene.renderUi
lurek.scene.renderUi()

-- =============================================================================
-- Scene Data — Passing data between scenes
-- =============================================================================

--@api-stub: lurek.scene.setData
-- Pass the selected level to the gameplay scene.
lurek.scene.setData("selected_level", 3)
lurek.scene.setData("difficulty", "hard")

--@api-stub: lurek.scene.getData
local level = lurek.scene.getData("selected_level")
print("selected level: " .. tostring(level))

--@api-stub: lurek.scene.hasData
print("has difficulty: " .. tostring(lurek.scene.hasData("difficulty")))

--@api-stub: lurek.scene.removeData
lurek.scene.removeData("difficulty")

-- =============================================================================
-- Transitions
-- =============================================================================

--@api-stub: lurek.scene.fade
-- Fade transition to gameplay (1 second).
lurek.scene.fade("gameplay", 1.0)

--@api-stub: lurek.scene.slide
-- Slide transition (direction, duration).
lurek.scene.slide("settings", "left", 0.5)

--@api-stub: lurek.scene.wipe
lurek.scene.wipe("title", 0.8)

--@api-stub: lurek.scene.iris
-- Iris/circle transition (like classic Mario).
lurek.scene.iris("gameplay", 0.6)

--@api-stub: lurek.scene.isTransitioning
print("transitioning: " .. tostring(lurek.scene.isTransitioning()))

--@api-stub: lurek.scene.getTransitionProgress
print("progress: " .. lurek.scene.getTransitionProgress())

--@api-stub: lurek.scene.getTransitionProgressEased
print("progress (eased): " .. lurek.scene.getTransitionProgressEased())

--@api-stub: lurek.scene.getTransitionTypes
local types = lurek.scene.getTransitionTypes()
print("transition types: " .. table.concat(types, ", "))

-- =============================================================================
-- Preloading
-- =============================================================================

--@api-stub: lurek.scene.preload
lurek.scene.preload("gameplay")

--@api-stub: lurek.scene.isPreloaded
print("preloaded: " .. tostring(lurek.scene.isPreloaded("gameplay")))

--@api-stub: lurek.scene.pushPreloaded
lurek.scene.pushPreloaded("gameplay")

-- =============================================================================
-- Serialization — Save/Load scene state
-- =============================================================================

--@api-stub: lurek.scene.serializeScene
local saved = lurek.scene.serializeScene("gameplay")
print("serialized: " .. #saved .. " bytes")

--@api-stub: lurek.scene.deserializeScene
lurek.scene.deserializeScene("gameplay", saved)

-- =============================================================================
-- Depth Sorting
-- =============================================================================

--@api-stub: lurek.scene.newDepthSorter
local sorter = lurek.scene.newDepthSorter()

--@api-stub: DepthSorter:add
sorter:add(50, "draw_tree")
sorter:add(10, "draw_ground")
sorter:add(80, "draw_player")

--@api-stub: DepthSorter:addObject
sorter:addObject({y = 60, draw = function() end})

--@api-stub: DepthSorter:sort
sorter:sort()

--@api-stub: DepthSorter:getCount
print("sorted items: " .. sorter:getCount())

--@api-stub: DepthSorter:setStable
sorter:setStable(true)

--@api-stub: DepthSorter:isStable
print("stable sort: " .. tostring(sorter:isStable()))

--@api-stub: DepthSorter:flush
sorter:flush()

--@api-stub: DepthSorter:clear
sorter:clear()

print("\n-- scene.lua example complete --")
