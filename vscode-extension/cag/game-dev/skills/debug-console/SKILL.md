# Debug Console

Toggle overlay with command input, built-in commands, and extensible command registration.

## Key Concepts

- **Toggle key**: F1 or backtick to show/hide the console overlay.
- **Command input**: Text field at the bottom. Prefix with `/` for commands.
- **Built-in commands**: `/fps`, `/reload`, `/setflag`, `/give`, `/teleport`, `/god`.
- **Extensible**: `register_command(name, fn)` to add game-specific commands.
- **Output log**: Scrollable history of command outputs and game messages.

## Console State

```lua
local console = {
    visible = false,
    input = "",
    history = {},
    log = {},
    max_log = 50,
    commands = {},
}

local function toggle_console()
    console.visible = not console.visible
    console.input = ""
end
```

## Command Registration

```lua
local function register_command(name, fn, help)
    console.commands[name] = { fn = fn, help = help or "" }
end

local function console_print(text)
    console.log[#console.log + 1] = text
    if #console.log > console.max_log then
        table.remove(console.log, 1)
    end
end
```

## Built-In Commands

```lua
register_command("fps", function()
    console_print("FPS: " .. tostring(luna.timer.getFPS()))
end, "Show current FPS")

register_command("reload", function()
    console_print("Reloading...")
    -- Trigger game reload
end, "Reload the current scene")

register_command("setflag", function(args)
    if #args < 2 then console_print("Usage: /setflag <name> <value>"); return end
    local name = args[1]
    local value = args[2] == "true"
    game.flags[name] = value
    console_print("Flag " .. name .. " = " .. tostring(value))
end, "Set a game flag: /setflag <name> <true|false>")

register_command("give", function(args)
    if #args < 1 then console_print("Usage: /give <item> [count]"); return end
    local item = args[1]
    local count = tonumber(args[2]) or 1
    add_item(player.inv, item, count)
    console_print("Gave " .. count .. "x " .. item)
end, "Give item: /give <item> [count]")

register_command("teleport", function(args)
    if #args < 2 then console_print("Usage: /teleport <x> <y>"); return end
    player.x = tonumber(args[1]) or player.x
    player.y = tonumber(args[2]) or player.y
    console_print("Teleported to " .. player.x .. ", " .. player.y)
end, "Teleport player: /teleport <x> <y>")

register_command("god", function()
    player.invincible = not player.invincible
    console_print("God mode: " .. (player.invincible and "ON" or "OFF"))
end, "Toggle invincibility")

register_command("help", function()
    for name, cmd in pairs(console.commands) do
        console_print("/" .. name .. " — " .. cmd.help)
    end
end, "List all commands")
```

## Command Execution

```lua
local function execute_command(input)
    console.history[#console.history + 1] = input
    if input:sub(1, 1) ~= "/" then
        console_print(input)
        return
    end

    local parts = {}
    for word in input:sub(2):gmatch("%S+") do
        parts[#parts + 1] = word
    end

    local cmd_name = parts[1]
    local args = {}
    for i = 2, #parts do args[#args + 1] = parts[i] end

    local cmd = console.commands[cmd_name]
    if cmd then
        cmd.fn(args)
    else
        console_print("Unknown command: /" .. (cmd_name or ""))
    end
end
```

## Input Handling

```lua
function luna.keypressed(key)
    if key == "`" or key == "f1" then
        toggle_console()
        return
    end
    if not console.visible then return end
    if key == "return" then
        if #console.input > 0 then
            execute_command(console.input)
            console.input = ""
        end
    elseif key == "backspace" then
        console.input = console.input:sub(1, -2)
    end
end

function luna.textinput(text)
    if not console.visible then return end
    if text == "`" then return end  -- ignore toggle key
    console.input = console.input .. text
end
```

## Drawing the Console

```lua
local function draw_console()
    if not console.visible then return end
    local sw, sh = 800, 600
    local ch = 250  -- console height

    -- Background
    luna.graphics.setColor(0, 0, 0, 0.85)
    luna.graphics.rectangle("fill", 0, 0, sw, ch)

    -- Log lines
    luna.graphics.setColor(0.8, 0.8, 0.8, 1)
    local start = math.max(1, #console.log - 12)
    for i = start, #console.log do
        local y = (i - start) * 16 + 4
        luna.graphics.print(console.log[i], 8, y)
    end

    -- Input line
    luna.graphics.setColor(0.2, 0.2, 0.2, 1)
    luna.graphics.rectangle("fill", 0, ch - 22, sw, 22)
    luna.graphics.setColor(0, 1, 0, 1)
    luna.graphics.print("> " .. console.input .. "_", 8, ch - 20)

    luna.graphics.setColor(1, 1, 1, 1)
end
```

## Common Pitfalls

- **Console eats game input** — when visible, block game `keypressed`/`textinput`. Check `console.visible` first.
- **Toggle key appears in input** — filter the toggle character in `textinput` handler.
- **Command injection** — don't call `load()` or `loadstring()` on raw input. Use the registered command table only.
- **Log overflow** — cap the log array. Remove oldest entries when the limit is exceeded.
- **Ship with console enabled** — gate behind a debug flag. Strip or disable in release builds.
