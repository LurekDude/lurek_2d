# Scene Management

Scene table pattern, transitions, scene stacking, preloading, and cleanup for multi-screen games.

## Key Concepts

- **Scene table**: Each scene is a table with `load`, `update`, `draw`, and `unload` methods.
- **Scene stack**: Push scenes for overlays (pause menu over gameplay). Pop to return.
- **Transitions**: Fade-out → switch → fade-in. Use a timer-driven transition state.
- **Preloading**: Load assets in the background before switching to avoid frame hitches.
- **Cleanup**: `unload` releases assets and clears event handlers to prevent leaks.

## Scene Table

```lua
local title_scene = {}
function title_scene.load()
    title_scene.bg = lurek.render.newImage("title_bg.png")
end
function title_scene.update(dt)
    if lurek.input.keyboard.isDown("return") then
        switch_scene(game_scene)
    end
end
function title_scene.draw()
    lurek.render.draw(title_scene.bg, 0, 0)
    lurek.render.print("Press ENTER", 300, 400)
end
function title_scene.unload()
    title_scene.bg = nil
end
```

## Scene Manager

```lua
local scene_mgr = { stack = {}, transitioning = false }

local function current_scene()
    return scene_mgr.stack[#scene_mgr.stack]
end

local function switch_scene(new_scene)
    local old = current_scene()
    if old and old.unload then old.unload() end
    scene_mgr.stack[#scene_mgr.stack] = new_scene
    if new_scene.load then new_scene.load() end
end

local function push_scene(overlay)
    scene_mgr.stack[#scene_mgr.stack + 1] = overlay
    if overlay.load then overlay.load() end
end

local function pop_scene()
    local top = scene_mgr.stack[#scene_mgr.stack]
    if top and top.unload then top.unload() end
    scene_mgr.stack[#scene_mgr.stack] = nil
end
```

## Transition Effect

```lua
local transition = { active = false, alpha = 0, phase = "none", next_scene = nil }
local FADE_SPEED = 3.0

local function start_transition(new_scene)
    transition.active = true
    transition.phase = "out"
    transition.alpha = 0
    transition.next_scene = new_scene
end

local function update_transition(dt)
    if not transition.active then return end
    if transition.phase == "out" then
        transition.alpha = transition.alpha + FADE_SPEED * dt
        if transition.alpha >= 1 then
            transition.alpha = 1
            switch_scene(transition.next_scene)
            transition.phase = "in"
        end
    elseif transition.phase == "in" then
        transition.alpha = transition.alpha - FADE_SPEED * dt
        if transition.alpha <= 0 then
            transition.alpha = 0
            transition.active = false
        end
    end
end

local function draw_transition()
    if not transition.active then return end
    lurek.render.setColor(0, 0, 0, transition.alpha)
    lurek.render.rectangle("fill", 0, 0, 800, 600)
    lurek.render.setColor(1, 1, 1, 1)
end
```

## Engine Hooks

```lua
function lurek.process(dt)
    update_transition(dt)
    if not transition.active then
        local s = current_scene()
        if s and s.update then s.update(dt) end
    end
end

function lurek.render()
    local s = current_scene()
    if s and s.draw then s.draw() end
    draw_transition()
end
```

## Common Pitfalls

- **Leaking callbacks** — if a scene registers `lurek.keypressed`, clear it in `unload` or gate it with a scene check.
- **Drawing under overlay** — when a pause menu is pushed, still draw the game scene underneath. Iterate the stack bottom-up for draw.
- **Transition skips load** — always call `new_scene.load()` between fade-out and fade-in, not after fade-in.
- **Nil scene on empty stack** — guard `current_scene()` returns in update/draw.
- **Assets not freed** — set image/sound references to `nil` in `unload` so Lua GC can reclaim them.
