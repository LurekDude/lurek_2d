# Game States

State stack with push/pop for pause and overlays, state table pattern, transitions, and persistent state.

## Key Concepts

- **State table**: Each state has `enter`, `exit`, `update`, and `draw` methods.
- **State stack**: Push overlays (pause, game-over) on top of the current state. Pop to resume.
- **Transitions**: Fade, slide, or instant switch between states.
- **Persistent state**: Some data (score, settings) survives state changes.

## State Table Pattern

```lua
local play_state = {}

function play_state.enter()
    -- Initialize or resume game
end

function play_state.exit()
    -- Cleanup
end

function play_state.update(dt)
    -- Game logic
    if lurek.input.keyboard.isDown("escape") then
        push_state(pause_state)
    end
end

function play_state.draw()
    -- Render game world
end
```

## State Stack Manager

```lua
local state_stack = {}

local function current_state()
    return state_stack[#state_stack]
end

local function switch_state(new_state)
    local old = current_state()
    if old and old.exit then old.exit() end
    state_stack = { new_state }
    if new_state.enter then new_state.enter() end
end

local function push_state(overlay)
    state_stack[#state_stack + 1] = overlay
    if overlay.enter then overlay.enter() end
end

local function pop_state()
    local top = current_state()
    if top and top.exit then top.exit() end
    state_stack[#state_stack] = nil
    -- Optionally call resume on new top
    local new_top = current_state()
    if new_top and new_top.resume then new_top.resume() end
end
```

## Pause State (Overlay)

```lua
local pause_state = {}

function pause_state.enter()
    -- Pause music, show menu
end

function pause_state.exit()
    -- Resume music
end

function pause_state.update(dt)
    if lurek.input.keyboard.isDown("escape") then
        pop_state()
    end
end

function pause_state.draw()
    -- Draw semi-transparent overlay
    lurek.render.setColor(0, 0, 0, 0.6)
    lurek.render.rectangle("fill", 0, 0, 800, 600)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("PAUSED", 370, 280)
    lurek.render.print("Press ESC to resume", 310, 310)
end
```

## Engine Integration

```lua
function lurek.process(dt)
    local s = current_state()
    if s and s.update then s.update(dt) end
end

function lurek.draw()
    -- Draw all states bottom to top (so overlay draws over game)
    for _, s in ipairs(state_stack) do
        if s.draw then s.draw() end
    end
end

function lurek.keypressed(key)
    local s = current_state()
    if s and s.keypressed then s.keypressed(key) end
end
```

## Game-Over State

```lua
local gameover_state = {}

function gameover_state.enter()
    gameover_state.timer = 0
end

function gameover_state.update(dt)
    gameover_state.timer = gameover_state.timer + dt
    if gameover_state.timer > 2 and lurek.input.keyboard.isDown("return") then
        switch_state(title_state)
    end
end

function gameover_state.draw()
    lurek.render.setColor(0.1, 0, 0, 0.9)
    lurek.render.rectangle("fill", 0, 0, 800, 600)
    lurek.render.setColor(1, 0.2, 0.2, 1)
    lurek.render.print("GAME OVER", 340, 260)
    if gameover_state.timer > 2 then
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("Press ENTER", 350, 300)
    end
end
```

## Common Pitfalls

- **Pause doesn't block game update** — only the top state's `update` runs. The play state underneath should NOT update while paused.
- **Stack overflow** — prevent pushing the same overlay twice. Check before push.
- **Exit not called on switch** — `switch_state` must call `exit` on the old state. Otherwise resources leak.
- **Input bleeds through** — keypressed should only go to the top state. Don't propagate down the stack.
- **Drawing order** — iterate bottom-to-top for draw so overlays render on top. Update only the top state.
