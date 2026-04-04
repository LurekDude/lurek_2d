# Input Handling

Action map pattern, just-pressed vs held detection, gamepad support, configurable bindings, and input buffering.

## Key Concepts

- **Action map**: Map physical keys to logical actions. Game code reads actions, not keys.
- **Just-pressed vs held**: `keypressed` callback for one-shot actions (jump); `isDown` for continuous (move).
- **Gamepad deadzones**: Ignore stick values below a threshold (0.2–0.3) to prevent drift.
- **Input buffering**: Queue inputs for N frames to forgive early presses.
- **Rebindable keys**: Store bindings in a table the player can modify.

## Action Map Pattern

```lua
local bindings = {
    jump   = { keys = {"space", "w", "up"},    buttons = {"a"} },
    attack = { keys = {"z", "j"},              buttons = {"x"} },
    left   = { keys = {"left", "a"},           axes = {{"leftx", -1}} },
    right  = { keys = {"right", "d"},          axes = {{"leftx",  1}} },
    up     = { keys = {"up", "w"},             axes = {{"lefty", -1}} },
    down   = { keys = {"down", "s"},           axes = {{"lefty",  1}} },
}

local function is_action_down(action)
    local b = bindings[action]
    if b.keys then
        for _, k in ipairs(b.keys) do
            if luna.keyboard.isDown(k) then return true end
        end
    end
    if b.axes then
        for _, a in ipairs(b.axes) do
            local val = luna.gamepad.getAxis(1, a[1]) or 0
            if a[2] > 0 and val > DEADZONE then return true end
            if a[2] < 0 and val < -DEADZONE then return true end
        end
    end
    return false
end
```

## Just-Pressed Tracking

```lua
local pressed_actions = {}

function luna.keypressed(key)
    for action, b in pairs(bindings) do
        for _, k in ipairs(b.keys or {}) do
            if k == key then pressed_actions[action] = true end
        end
    end
end

local function consume_press(action)
    if pressed_actions[action] then
        pressed_actions[action] = nil
        return true
    end
    return false
end

-- Call at end of update to clear
local function flush_presses()
    pressed_actions = {}
end
```

## Input Buffer

```lua
local BUFFER_FRAMES = 8
local input_buffer = {}

function luna.keypressed(key)
    if key == "space" then
        input_buffer.jump = BUFFER_FRAMES
    end
end

function luna.update(dt)
    -- Decrement buffer timers
    for action, frames in pairs(input_buffer) do
        input_buffer[action] = frames - 1
        if input_buffer[action] <= 0 then input_buffer[action] = nil end
    end

    -- Check buffered jump
    if input_buffer.jump and player.grounded then
        do_jump()
        input_buffer.jump = nil
    end
end
```

## Gamepad Deadzone

```lua
local DEADZONE = 0.25

local function get_stick(pad_id, axis)
    local val = luna.gamepad.getAxis(pad_id, axis) or 0
    if math.abs(val) < DEADZONE then return 0 end
    -- Rescale to 0–1 range past deadzone
    local sign = val > 0 and 1 or -1
    return sign * (math.abs(val) - DEADZONE) / (1 - DEADZONE)
end
```

## Common Pitfalls

- **Checking keys in update instead of callbacks** — `isDown` is for held state. Use `keypressed` for one-shot actions like jump or interact.
- **Gamepad axis drift** — always apply a deadzone. Raw values hover around 0.01–0.05 at rest.
- **Hardcoded keys scattered everywhere** — centralize in the action map. Never check `"space"` directly in game logic.
- **Buffer never cleared** — always decrement and nil-out expired buffer entries. Stale buffers cause ghost inputs.
- **Multiple pads** — always pass `pad_id` to gamepad functions. Don't assume pad 1.
