# Dialogue System

Dialog node trees, portraits, typewriter text, conditional branches, choices, and shop integration.

## Key Concepts

- **Dialog tree**: Array of nodes. Each node has speaker, text, optional choices, and a next pointer.
- **Choices**: Player selects from options. Each option can have conditions and a target node.
- **Typewriter effect**: Reveal text character-by-character at a configurable speed.
- **Conditions**: Gate choices or branches on game flags (`boss_defeated`, inventory state).
- **Portraits**: Speaker image displayed beside the text box.

## Dialog Data Structure

```lua
local dialog_intro = {
    { id = 1, speaker = "Elder", portrait = "elder.png",
      text = "Welcome, traveler. The forest is dangerous.",
      next = 2 },
    { id = 2, speaker = "Elder", portrait = "elder.png",
      text = "Will you help us?",
      choices = {
          { text = "Yes, I'll help.",  next = 3 },
          { text = "Tell me more.",    next = 4 },
          { text = "Not interested.",  next = 5, condition = function() return not game.flags.forced end },
      } },
    { id = 3, speaker = "Elder", text = "Thank you! Take this sword.", next = nil,
      on_complete = function() add_item(player.inv, "sword", 1) end },
    { id = 4, speaker = "Elder", text = "Dark creatures have invaded the forest.", next = 2 },
    { id = 5, speaker = "Elder", text = "I understand. Safe travels.", next = nil },
}
```

## Dialog Runner

```lua
local dialog = { active = false, data = nil, node_index = nil, char_index = 0, timer = 0 }
local CHAR_SPEED = 0.03  -- seconds per character

local function start_dialog(data)
    dialog.active = true
    dialog.data = data
    dialog.node_index = 1
    dialog.char_index = 0
    dialog.timer = 0
end

local function current_node()
    if not dialog.data then return nil end
    for _, node in ipairs(dialog.data) do
        if node.id == dialog.node_index then return node end
    end
    return nil
end

local function advance_to(node_id)
    if not node_id then
        local node = current_node()
        if node and node.on_complete then node.on_complete() end
        dialog.active = false
        return
    end
    dialog.node_index = node_id
    dialog.char_index = 0
    dialog.timer = 0
end
```

## Typewriter Update

```lua
local function update_dialog(dt)
    if not dialog.active then return end
    local node = current_node()
    if not node then dialog.active = false; return end

    local full_len = #node.text
    if dialog.char_index < full_len then
        dialog.timer = dialog.timer + dt
        if dialog.timer >= CHAR_SPEED then
            dialog.timer = dialog.timer - CHAR_SPEED
            dialog.char_index = dialog.char_index + 1
        end
    end
end
```

## Input Handling

```lua
function luna.keypressed(key)
    if not dialog.active then return end
    local node = current_node()
    if key == "return" or key == "space" then
        if dialog.char_index < #node.text then
            dialog.char_index = #node.text  -- skip to full text
        elseif node.choices then
            -- select current choice
            local choice = node.choices[dialog.choice_index or 1]
            advance_to(choice.next)
        else
            advance_to(node.next)
        end
    end
    if node.choices then
        if key == "up"   then dialog.choice_index = math.max(1, (dialog.choice_index or 1) - 1) end
        if key == "down" then dialog.choice_index = math.min(#node.choices, (dialog.choice_index or 1) + 1) end
    end
end
```

## Drawing the Dialog Box

```lua
local function draw_dialog()
    if not dialog.active then return end
    local node = current_node()
    if not node then return end
    local sw, sh = 800, 600
    local bx, by, bw, bh = 20, sh - 140, sw - 40, 120

    luna.gfx.setColor(0, 0, 0, 0.85)
    luna.gfx.rectangle("fill", bx, by, bw, bh)
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.rectangle("line", bx, by, bw, bh)

    -- Speaker name
    if node.speaker then
        luna.gfx.print(node.speaker, bx + 10, by + 6)
    end

    -- Typewriter text
    local visible = node.text:sub(1, dialog.char_index)
    luna.gfx.print(visible, bx + 10, by + 26)

    -- Choices
    if node.choices and dialog.char_index >= #node.text then
        for i, c in ipairs(node.choices) do
            local prefix = (i == (dialog.choice_index or 1)) and "> " or "  "
            luna.gfx.print(prefix .. c.text, bx + 20, by + 50 + (i - 1) * 18)
        end
    end
end
```

## Common Pitfalls

- **Missing node ID** — always check `current_node()` for nil. A bad `next` pointer crashes the dialog.
- **Conditions not filtered** — filter out choices whose `condition()` returns false before displaying.
- **Typewriter speed tied to framerate** — use `dt`-based timing, not frame count.
- **Dialog not blocking input** — while dialog is active, suppress game movement input (check `dialog.active`).
- **on_complete never called** — ensure it fires when advancing past the final node, not just when choosing.
