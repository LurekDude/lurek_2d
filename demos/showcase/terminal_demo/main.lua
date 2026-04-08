-- Terminal Demo for Luna2D
-- Demonstrates the luna.terminal widget system with a "Character Creator" UI.
-- Features: grid manipulation, borders, labels, textbox, list, button, focus, callbacks.
-- Run with: cargo run -- demos/showcase/terminal_demo

local term
local border
local titleLabel
local nameLabel, nameInput
local classLabel, classList
local createBtn
local statusLabel
local selectedClass = nil
local smokeMode = false
local smokeScreenshotPath = "save/terminal_demo_smoke.png"
local smokeRequested = false
local smokeQuitNextFrame = false

local function initSmokeMode()
    local args = luna.platform.getArgs()
    local screenshotPrefix = "--smoke-screenshot="

    for i = 1, #args do
        local arg = args[i]
        if arg == "--smoke-terminal-demo" then
            smokeMode = true
        elseif arg:sub(1, #screenshotPrefix) == screenshotPrefix then
            smokeMode = true
            smokeScreenshotPath = arg:sub(#screenshotPrefix + 1)
        end
    end
end

function luna.init()
    initSmokeMode()
    luna.gfx.setBackgroundColor(0, 0, 0)

    -- Create an 80×25 terminal grid
    term = luna.terminal.newTerminal(80, 25)

    -- ── Direct cell manipulation ──────────────────────────────────────────
    -- Draw a decorative row of dots along the very top row
    for col = 1, 80 do
        term:set(col, 1, ".", 0.2, 0.2, 0.4, 1.0, 0, 0, 0, 0)
    end

    -- ── Main border ──────────────────────────────────────────────────────
    border = luna.terminal.newBorder(2, 2, 78, 23)
    border:setStyle("double")
    border:setTitle(" Character Creator ")
    border:setColor(0.4, 0.6, 1.0)
    term:addWidget(border)

    -- ── Title label ──────────────────────────────────────────────────────
    titleLabel = luna.terminal.newLabel(30, 4, "=== Create Your Hero ===")
    titleLabel:setColor(1.0, 0.85, 0.2)
    term:addWidget(titleLabel)

    -- ── Name input ───────────────────────────────────────────────────────
    nameLabel = luna.terminal.newLabel(6, 7, "Name:")
    nameLabel:setColor(0.8, 0.8, 0.8)
    term:addWidget(nameLabel)

    nameInput = luna.terminal.newTextBox(13, 7, 25)
    nameInput:setMaxLength(20)
    nameInput:setOnChange(function()
        updateStatus("Typing name: " .. nameInput:getText())
    end)
    term:addWidget(nameInput)

    -- ── Class list ───────────────────────────────────────────────────────
    classLabel = luna.terminal.newLabel(6, 10, "Class:")
    classLabel:setColor(0.8, 0.8, 0.8)
    term:addWidget(classLabel)

    classList = luna.terminal.newList(6, 12, 24, 6)
    classList:addItem("Warrior   - Melee tank")
    classList:addItem("Mage      - Arcane DPS")
    classList:addItem("Rogue     - Stealth & crits")
    classList:addItem("Healer    - Support & buffs")
    classList:setOnSelect(function()
        local sel = classList:getSelected()
        if sel then
            local names = { "Warrior", "Mage", "Rogue", "Healer" }
            selectedClass = names[sel]
            updateStatus("Class selected: " .. selectedClass)
        end
    end)
    term:addWidget(classList)

    -- ── Create button ────────────────────────────────────────────────────
    createBtn = luna.terminal.newButton(6, 20, 14, 1, "[ Create ]")
    createBtn:setOnClick(function()
        local name = nameInput:getText()
        if name == "" then
            updateStatus("Please enter a name!")
            return
        end
        if not selectedClass then
            updateStatus("Please select a class!")
            return
        end
        updateStatus("Created: " .. name .. " the " .. selectedClass .. "!")
    end)
    term:addWidget(createBtn)

    -- ── Info panel on the right side ─────────────────────────────────────
    local infoBorder = luna.terminal.newBorder(42, 6, 34, 14)
    infoBorder:setStyle("single")
    infoBorder:setTitle(" Info ")
    infoBorder:setColor(0.3, 0.7, 0.3)
    term:addWidget(infoBorder)

    local infoLines = {
        { y = 8,  text = "Welcome, adventurer!" },
        { y = 10, text = "1. Type your name" },
        { y = 11, text = "2. Pick a class" },
        { y = 12, text = "3. Click [Create]" },
        { y = 14, text = "Controls:" },
        { y = 15, text = "  Tab  = switch focus" },
        { y = 16, text = "  Up/Dn = browse list" },
        { y = 17, text = "  Enter = press button" },
    }
    for _, line in ipairs(infoLines) do
        local lbl = luna.terminal.newLabel(44, line.y, line.text)
        lbl:setColor(0.6, 0.9, 0.6)
        term:addWidget(lbl)
    end

    -- ── Status bar ───────────────────────────────────────────────────────
    statusLabel = luna.terminal.newLabel(6, 22, "Ready. Enter your character details above.")
    statusLabel:setColor(0.5, 0.8, 1.0)
    term:addWidget(statusLabel)

    -- Focus the name input by default
    term:setFocus(nameInput)
end

-- ── Helper ───────────────────────────────────────────────────────────────

function updateStatus(msg)
    statusLabel:setText(msg)
end

-- ── Focusable widgets for Tab cycling ────────────────────────────────────

local focusWidgets = {}
local focusIndex = 1

function initFocusCycle()
    focusWidgets = { nameInput, classList, createBtn }
    focusIndex = 1
end

function cycleFocus()
    focusIndex = focusIndex % #focusWidgets + 1
    term:setFocus(focusWidgets[focusIndex])
    local tags = { "Name input", "Class list", "Create button" }
    updateStatus("Focus: " .. tags[focusIndex])
end

-- ── Callbacks ────────────────────────────────────────────────────────────

function luna.process(dt)
    if smokeQuitNextFrame then
        luna.signal.quit()
    end
end

function luna.render()
    term:draw(0, 0)

    -- Draw a small hint below the terminal
    luna.gfx.setColor(0.4, 0.4, 0.4)
    luna.gfx.print("Terminal Demo  |  Tab = cycle focus  |  ESC = quit", 10, 580, 1)

    if smokeMode and not smokeRequested then
        luna.gfx.saveScreenshot(smokeScreenshotPath)
        smokeRequested = true
        smokeQuitNextFrame = true
    end
end

function luna.keypressed(key)
    if key == "escape" then
        luna.signal.quit()
        return
    end

    if key == "tab" then
        -- Lazy-init the focus cycle list
        if #focusWidgets == 0 then
            initFocusCycle()
        end
        cycleFocus()
        return
    end

    -- Route all other keys to the terminal
    term:keypressed(key)
end

function luna.textinput(text)
    term:textinput(text)
end

function luna.mousepressed(x, y, button)
    term:mousepressed(x, y, button)
end
