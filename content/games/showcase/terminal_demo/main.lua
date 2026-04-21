-- ============================================================================
-- Terminal Demo — Lurek2D
-- ============================================================================
-- Category : showcase
-- Source   : content/games/showcase/terminal_demo/main.lua
-- Run with : cargo run -- content/games/showcase/terminal_demo
-- ============================================================================
-- Full-screen terminal UI character creation wizard with box-drawing borders,
-- colored text, stat allocation, and multi-page navigation on an 80x25 grid.
-- Controls: Up/Down navigate, Enter confirm, Backspace back, Tab next stat,
--           +/- adjust stats, 1-6 color, Escape quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600
local GRID_COLS = 80
local GRID_ROWS = 25
local CELL_W    = math.floor(SCREEN_W / GRID_COLS)   -- 10
local CELL_H    = math.floor(SCREEN_H / GRID_ROWS)   -- 24
local MAX_NAME  = 16

-- ---------------------------------------------------------------------------
-- States
-- ---------------------------------------------------------------------------
local STATE_TITLE    = "TITLE"
local STATE_PAGE_1   = "PAGE_1"   -- Name entry
local STATE_PAGE_2   = "PAGE_2"   -- Class selection
local STATE_PAGE_3   = "PAGE_3"   -- Stat allocation
local STATE_PAGE_4   = "PAGE_4"   -- Appearance
local STATE_PAGE_5   = "PAGE_5"   -- Summary
local STATE_COMPLETE = "COMPLETE"

local current_state  = STATE_TITLE
local title_timer    = 0

-- ---------------------------------------------------------------------------
-- Colors
-- ---------------------------------------------------------------------------
local COL_GREEN   = { 0.0, 1.0, 0.3 }
local COL_CYAN    = { 0.2, 0.9, 1.0 }
local COL_YELLOW  = { 1.0, 0.85, 0.2 }
local COL_RED     = { 1.0, 0.2, 0.1 }
local COL_WHITE   = { 1.0, 1.0, 1.0 }
local COL_DIM     = { 0.3, 0.3, 0.3 }
local COL_MAGENTA = { 0.9, 0.3, 1.0 }

-- ---------------------------------------------------------------------------
-- Character data (persists across pages)
-- ---------------------------------------------------------------------------
local char_name   = ""
local char_class  = 1
local class_list  = { "Warrior", "Mage", "Rogue", "Cleric" }
local class_desc  = {
    "High STR and CON. Excels in melee combat with heavy armor.",
    "High INT and WIS. Commands powerful arcane and elemental spells.",
    "High DEX. Master of stealth, traps, and critical strikes.",
    "Balanced WIS and CON. Heals allies and smites undead foes.",
}

local STAT_NAMES  = { "STR", "DEX", "INT", "WIS", "CON" }
local stat_values = { 4, 4, 4, 4, 4 }   -- 20 total to distribute
local STAT_POOL   = 20
local stat_cursor = 1

local color_names   = { "Green", "Cyan", "Yellow", "Red", "Magenta", "White" }
local color_values  = { COL_GREEN, COL_CYAN, COL_YELLOW, COL_RED, COL_MAGENTA, COL_WHITE }
local char_color    = 1
local symbol_list   = { "@", "#", "$", "&", "*" }
local char_symbol   = 1

-- ---------------------------------------------------------------------------
-- UI state
-- ---------------------------------------------------------------------------
local cursor_blink   = 0
local cursor_visible = true
local flash_timer    = 0    -- error flash
local page_offset_x  = 0   -- tween slide
local scroll_offset  = 0   -- lore scroll

-- Particles & systems
local ps_flash    = nil
local ps_complete = nil
local camera      = nil

-- ---------------------------------------------------------------------------
-- Helpers: grid drawing
-- ---------------------------------------------------------------------------
local function grid_x(col) return (col - 1) * CELL_W end
local function grid_y(row) return (row - 1) * CELL_H end

local function draw_char(ch, col, row, color, alpha)
    local c = color or COL_GREEN
    lurek.render.setColor(c[1], c[2], c[3], alpha or 1)
    lurek.render.drawText(ch, grid_x(col), grid_y(row))
end

local function draw_string(str, col, row, color, alpha)
    local c = color or COL_GREEN
    lurek.render.setColor(c[1], c[2], c[3], alpha or 1)
    lurek.render.drawText(str, grid_x(col), grid_y(row))
end

local function draw_box(c1, r1, c2, r2, color)
    local col = color or COL_GREEN
    -- corners
    draw_char("+", c1, r1, col)
    draw_char("+", c2, r1, col)
    draw_char("+", c1, r2, col)
    draw_char("+", c2, r2, col)
    -- horizontal
    for c = c1 + 1, c2 - 1 do
        draw_char("-", c, r1, col)
        draw_char("-", c, r2, col)
    end
    -- vertical
    for r = r1 + 1, r2 - 1 do
        draw_char("|", c1, r, col)
        draw_char("|", c2, r, col)
    end
end

local function draw_hline(c1, c2, row, color)
    for c = c1, c2 do
        draw_char("-", c, row, color)
    end
end

local function draw_button(label, col, row, selected)
    local clr = selected and COL_YELLOW or COL_DIM
    draw_string("[" .. label .. "]", col, row, clr)
end

local function draw_progress_bar(page, total, col, row)
    local filled = math.floor((page / total) * 20)
    local bar = "Step " .. page .. "/" .. total .. " "
    for i = 1, 20 do
        bar = bar .. (i <= filled and "=" or ".")
    end
    draw_string(bar, col, row, COL_DIM)
end

local function stat_total()
    local s = 0
    for _, v in ipairs(stat_values) do s = s + v end
    return s
end

local function stat_remaining()
    return STAT_POOL - stat_total()
end

local function current_page_num()
    if current_state == STATE_PAGE_1 then return 1
    elseif current_state == STATE_PAGE_2 then return 2
    elseif current_state == STATE_PAGE_3 then return 3
    elseif current_state == STATE_PAGE_4 then return 4
    elseif current_state == STATE_PAGE_5 then return 5
    end
    return 0
end

local function trigger_error_flash()
    flash_timer = 0.3
    if ps_flash then ps_flash:emit(15) end
end

local function trigger_page_complete()
    if ps_complete then ps_complete:emit(25) end
    lurek.tween.to({ target = { value = page_offset_x }, to = { value = 0 }, duration = 0.3 })
end

-- ---------------------------------------------------------------------------
-- Page navigation
-- ---------------------------------------------------------------------------
local PAGES = { STATE_PAGE_1, STATE_PAGE_2, STATE_PAGE_3, STATE_PAGE_4, STATE_PAGE_5 }

local function go_next_page()
    for i, p in ipairs(PAGES) do
        if current_state == p and i < #PAGES then
            page_offset_x = 30
            current_state = PAGES[i + 1]
            trigger_page_complete()
            return true
        end
    end
    return false
end

local function go_prev_page()
    for i, p in ipairs(PAGES) do
        if current_state == p and i > 1 then
            page_offset_x = -30
            current_state = PAGES[i - 1]
            lurek.tween.to({ target = { value = page_offset_x }, to = { value = 0 }, duration = 0.3 })
            return true
        end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------
function lurek.init()
    lurek.window.setTitle("Terminal Demo — Lurek2D")
    lurek.render.setBackgroundColor(0, 0, 0)

    lurek.input.bind("nav_up",    { "up" })
    lurek.input.bind("nav_down",  { "down" })
    lurek.input.bind("confirm",   { "return", "kpenter" })
    lurek.input.bind("back",      { "backspace" })
    lurek.input.bind("next_stat", { "tab" })
    lurek.input.bind("quit",      { "escape" })

    camera = lurek.camera.new(SCREEN_W, SCREEN_H)

    -- Page-complete flash (white sparks)
    ps_complete = lurek.particle.newSystem({
        maxParticles = 60, emissionRate = 0,
        lifetimeMin = 0.3, lifetimeMax = 0.7,
        speedMin = 50, speedMax = 160, direction = 0, spread = 6.28,
        sizes = { 3, 1.5, 0 },
        colors = { 1, 1, 1, 1, 0.8, 0.9, 1, 0.5, 0.4, 0.6, 1, 0 },
    })

    -- Error flash (red sparks)
    ps_flash = lurek.particle.newSystem({
        maxParticles = 40, emissionRate = 0,
        lifetimeMin = 0.15, lifetimeMax = 0.4,
        speedMin = 30, speedMax = 100, direction = 0, spread = 6.28,
        sizes = { 2.5, 1, 0 },
        colors = { 1, 0.2, 0.1, 1, 0.8, 0.1, 0, 0 },
    })
end

-- ---------------------------------------------------------------------------
-- Update
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    if lurek.input.wasActionPressed("quit") then lurek.event.quit() end

    -- Systems
    ps_complete:update(dt)
    ps_flash:update(dt)
    lurek.tween.update(dt)

    -- Cursor blink
    cursor_blink = cursor_blink + dt
    if cursor_blink >= 0.45 then
        cursor_blink = cursor_blink - 0.45
        cursor_visible = not cursor_visible
    end

    -- Error flash decay
    if flash_timer > 0 then flash_timer = flash_timer - dt end

    -- Title timer
    if current_state == STATE_TITLE then
        title_timer = title_timer + dt
    end

    -- ── PAGE 1: Name entry ────────────────────────────────────
    if current_state == STATE_PAGE_1 then
        if lurek.input.wasActionPressed("confirm") then
            if #char_name > 0 then
                go_next_page()
            else
                trigger_error_flash()
            end
        end
    end

    -- ── PAGE 2: Class selection ───────────────────────────────
    if current_state == STATE_PAGE_2 then
        if lurek.input.wasActionPressed("nav_up") then
            char_class = char_class > 1 and char_class - 1 or #class_list
        end
        if lurek.input.wasActionPressed("nav_down") then
            char_class = char_class < #class_list and char_class + 1 or 1
        end
        if lurek.input.wasActionPressed("confirm") then go_next_page() end
        if lurek.input.wasActionPressed("back") then go_prev_page() end
    end

    -- ── PAGE 3: Stat allocation ───────────────────────────────
    if current_state == STATE_PAGE_3 then
        if lurek.input.wasActionPressed("nav_up") or lurek.input.wasActionPressed("next_stat") then
            stat_cursor = stat_cursor < #STAT_NAMES and stat_cursor + 1 or 1
        end
        if lurek.input.wasActionPressed("nav_down") then
            stat_cursor = stat_cursor > 1 and stat_cursor - 1 or #STAT_NAMES
        end
        if lurek.input.wasActionPressed("confirm") then go_next_page() end
        if lurek.input.wasActionPressed("back") then go_prev_page() end
    end

    -- ── PAGE 4: Appearance ────────────────────────────────────
    if current_state == STATE_PAGE_4 then
        if lurek.input.wasActionPressed("nav_up") then
            char_symbol = char_symbol > 1 and char_symbol - 1 or #symbol_list
        end
        if lurek.input.wasActionPressed("nav_down") then
            char_symbol = char_symbol < #symbol_list and char_symbol + 1 or 1
        end
        if lurek.input.wasActionPressed("confirm") then go_next_page() end
        if lurek.input.wasActionPressed("back") then go_prev_page() end
    end

    -- ── PAGE 5: Summary ───────────────────────────────────────
    if current_state == STATE_PAGE_5 then
        if lurek.input.wasActionPressed("confirm") then
            current_state = STATE_COMPLETE
            if ps_complete then ps_complete:emit(60) end
        end
        if lurek.input.wasActionPressed("back") then go_prev_page() end
    end
end

-- ---------------------------------------------------------------------------
-- Text input — name entry on PAGE_1
-- ---------------------------------------------------------------------------
function lurek.textinput(text)
    if current_state == STATE_PAGE_1 then
        if #char_name < MAX_NAME then
            char_name = char_name .. text
        end
    end
end

function lurek.keypressed(key)
    -- Title → start
    if current_state == STATE_TITLE then
        if key ~= "escape" then current_state = STATE_PAGE_1 end
        return
    end

    -- Backspace deletes character on name page
    if current_state == STATE_PAGE_1 and key == "backspace" then
        if #char_name > 0 then
            char_name = char_name:sub(1, -2)
        end
        return
    end

    -- Stat +/- on PAGE_3
    if current_state == STATE_PAGE_3 then
        if key == "=" or key == "kp+" then
            if stat_remaining() > 0 and stat_values[stat_cursor] < 18 then
                stat_values[stat_cursor] = stat_values[stat_cursor] + 1
            else
                trigger_error_flash()
            end
        end
        if key == "-" or key == "kp-" then
            if stat_values[stat_cursor] > 1 then
                stat_values[stat_cursor] = stat_values[stat_cursor] - 1
            else
                trigger_error_flash()
            end
        end
    end

    -- Color selection 1-6 on PAGE_4
    if current_state == STATE_PAGE_4 then
        local n = tonumber(key)
        if n and n >= 1 and n <= #color_names then
            char_color = n
        end
    end

    -- Complete state: any key quits
    if current_state == STATE_COMPLETE and key ~= "escape" then
        lurek.event.quit()
    end
end

-- ---------------------------------------------------------------------------
-- Render — world-space effects (scanlines, particles)
-- ---------------------------------------------------------------------------
function lurek.render()
    camera:attach()

    -- CRT scanlines
    lurek.render.setColor(0, 0.12, 0.04, 0.2)
    for y = 0, SCREEN_H, 3 do
        lurek.render.drawLine(0, y, SCREEN_W, y)
    end

    -- Error flash overlay
    if flash_timer > 0 then
        local a = flash_timer / 0.3 * 0.15
        lurek.render.setColor(1, 0.1, 0, a)
        lurek.render.drawRect(0, 0, SCREEN_W, SCREEN_H)
    end

    -- Particles
    lurek.render.setColor(1, 1, 1, 1)
    ps_complete:draw()
    ps_flash:draw()

    camera:detach()
end

-- ---------------------------------------------------------------------------
-- Render UI — terminal grid, all pages, HUD
-- ---------------------------------------------------------------------------
function lurek.render_ui()
    local fps  = lurek.timer.getFPS()
    local pnum = current_page_num()
    local ox   = math.floor(page_offset_x)

    -- ── TITLE SCREEN ──────────────────────────────────────────
    if current_state == STATE_TITLE then
        draw_box(5, 3, 76, 23, COL_GREEN)
        draw_string("T E R M I N A L   D E M O", 22 + ox, 8, COL_GREEN)
        draw_string("CHARACTER CREATION", 27 + ox, 10, COL_CYAN)
        draw_hline(20, 60, 12, COL_DIM)
        draw_string("A full-screen terminal UI widget showcase", 16 + ox, 14, COL_DIM)
        draw_string("demonstrating character creation wizards", 17 + ox, 15, COL_DIM)
        draw_string("with box-drawing, colored text, and stats.", 16 + ox, 16, COL_DIM)

        local blink_a = (math.sin(title_timer * 3) + 1) * 0.5
        draw_string("[ Press any key to begin ]", 24, 20, COL_YELLOW, 0.4 + blink_a * 0.6)

        draw_string("Lurek2D Showcase", 30, 22, COL_DIM, 0.5)
        draw_string(string.format("FPS: %d", fps), 70, 25, COL_DIM, 0.4)
        return
    end

    -- ── COMPLETE SCREEN ───────────────────────────────────────
    if current_state == STATE_COMPLETE then
        draw_box(10, 4, 70, 22, COL_GREEN)
        draw_string("*** CHARACTER CREATED ***", 24, 6, COL_YELLOW)
        draw_hline(12, 68, 8, COL_DIM)

        draw_string("Name  : " .. char_name, 16, 10, COL_WHITE)
        draw_string("Class : " .. class_list[char_class], 16, 11, COL_CYAN)
        draw_string("Symbol: " .. symbol_list[char_symbol], 16, 12, color_values[char_color])
        draw_string("Color : " .. color_names[char_color], 16, 13, color_values[char_color])

        draw_hline(16, 50, 15, COL_DIM)
        for i, name in ipairs(STAT_NAMES) do
            local bar = string.rep("#", stat_values[i])
            draw_string(string.format("  %s: %2d  %s", name, stat_values[i], bar), 16, 15 + i, COL_CYAN)
        end

        draw_string("Your hero awaits!", 28, 22, COL_GREEN)
        local pa = (math.sin(title_timer * 4) + 1) * 0.5
        draw_string("[ Press any key to exit ]", 24, 24, COL_DIM, 0.4 + pa * 0.6)
        return
    end

    -- ── SHARED FRAME: border + header + progress ──────────────
    draw_box(1, 1, 80, 25, COL_GREEN)
    draw_progress_bar(pnum, 5, 3, 2)
    draw_hline(2, 79, 3, COL_DIM)

    -- ── PAGE 1: Name Entry ────────────────────────────────────
    if current_state == STATE_PAGE_1 then
        draw_string("  NAME ENTRY", 30 + ox, 4, COL_CYAN)
        draw_string("Enter your character's name (max 16 chars):", 8 + ox, 7, COL_GREEN)

        -- Name input box
        draw_box(8, 9, 50, 11, COL_DIM)
        local display_name = char_name
        if cursor_visible then display_name = display_name .. "_" end
        draw_string(display_name, 10 + ox, 10, COL_WHITE)

        draw_string(string.format("(%d/%d characters)", #char_name, MAX_NAME), 8 + ox, 13, COL_DIM)

        -- Lore text
        draw_hline(8, 72, 15, COL_DIM)
        draw_string("In the land of Eldoria, a new hero rises.", 8 + ox, 16, COL_DIM)
        draw_string("Your name will echo through the halls of", 8 + ox, 17, COL_DIM)
        draw_string("the great citadel for centuries to come.", 8 + ox, 18, COL_DIM)

        draw_button("Confirm: Enter", 55, 23, #char_name > 0)
        if flash_timer > 0 then
            draw_string("! Name cannot be empty !", 20, 23, COL_RED)
        end
    end

    -- ── PAGE 2: Class Selection ───────────────────────────────
    if current_state == STATE_PAGE_2 then
        draw_string("  CLASS SELECTION", 27 + ox, 4, COL_CYAN)
        draw_string("Choose your class with Up/Down, then Enter:", 8 + ox, 7, COL_GREEN)

        for i, cls in ipairs(class_list) do
            local prefix = (i == char_class) and "> " or "  "
            local clr = (i == char_class) and COL_YELLOW or COL_DIM
            draw_string(prefix .. cls, 12 + ox, 9 + i, clr)
        end

        -- Description box
        draw_box(8, 16, 72, 20, COL_DIM)
        draw_string(class_desc[char_class], 10 + ox, 17, COL_GREEN)
        draw_string("Recommended for: " .. (char_class == 1 and "beginners" or
                     char_class == 2 and "strategic players" or
                     char_class == 3 and "stealth fans" or "support players"), 10 + ox, 19, COL_DIM)

        draw_button("Confirm", 55, 23, true)
        draw_button("Back", 45, 23, true)
    end

    -- ── PAGE 3: Stat Allocation ───────────────────────────────
    if current_state == STATE_PAGE_3 then
        draw_string("  STAT ALLOCATION", 27 + ox, 4, COL_CYAN)
        draw_string(string.format("Distribute points (Remaining: %d)", stat_remaining()), 8 + ox, 7, COL_GREEN)
        draw_string("Tab/Up: next stat | +/-: adjust | Enter: confirm", 8 + ox, 8, COL_DIM)

        for i, name in ipairs(STAT_NAMES) do
            local row = 10 + i
            local selected = (i == stat_cursor)
            local prefix = selected and "> " or "  "
            local name_clr = selected and COL_YELLOW or COL_CYAN
            draw_string(prefix .. name, 10 + ox, row, name_clr)

            -- Value
            draw_string(string.format("%2d", stat_values[i]), 20 + ox, row, COL_WHITE)

            -- Visual bar
            local bar_full = string.rep("#", stat_values[i])
            local bar_empty = string.rep(".", 18 - stat_values[i])
            draw_string("[" .. bar_full .. bar_empty .. "]", 24 + ox, row, selected and COL_GREEN or COL_DIM)

            -- +/- indicators for selected
            if selected then
                draw_string("-", 45 + ox, row, stat_values[i] > 1 and COL_RED or COL_DIM)
                draw_string("+", 47 + ox, row, stat_remaining() > 0 and stat_values[i] < 18 and COL_GREEN or COL_DIM)
            end
        end

        -- Pool display
        draw_hline(10, 50, 17, COL_DIM)
        local pool_bar = string.rep("=", stat_remaining()) .. string.rep(".", STAT_POOL - stat_remaining())
        draw_string("Pool: [" .. pool_bar .. "] " .. stat_remaining(), 10 + ox, 18, COL_GREEN)

        draw_button("Confirm", 55, 23, true)
        draw_button("Back", 45, 23, true)
    end

    -- ── PAGE 4: Appearance ────────────────────────────────────
    if current_state == STATE_PAGE_4 then
        draw_string("  APPEARANCE", 30 + ox, 4, COL_CYAN)

        -- Symbol selection
        draw_string("Choose your symbol with Up/Down:", 8 + ox, 7, COL_GREEN)
        for i, sym in ipairs(symbol_list) do
            local prefix = (i == char_symbol) and "> " or "  "
            local clr = (i == char_symbol) and COL_YELLOW or COL_DIM
            draw_string(prefix .. sym, 12 + ox, 8 + i, clr)
        end

        -- Color selection
        draw_string("Choose your color (press 1-6):", 8 + ox, 15, COL_GREEN)
        for i, name in ipairs(color_names) do
            local prefix = (i == char_color) and "> " or "  "
            local clr = (i == char_color) and color_values[i] or COL_DIM
            draw_string(prefix .. i .. ". " .. name, 12 + ox, 15 + i, clr)
        end

        -- Preview
        draw_box(50, 7, 70, 15, COL_DIM)
        draw_string("Preview:", 52 + ox, 8, COL_DIM)
        local pc = color_values[char_color]
        draw_string(symbol_list[char_symbol], 59 + ox, 11, pc)
        draw_string(color_names[char_color], 55 + ox, 13, pc)

        draw_button("Confirm", 55, 23, true)
        draw_button("Back", 45, 23, true)
    end

    -- ── PAGE 5: Summary ───────────────────────────────────────
    if current_state == STATE_PAGE_5 then
        draw_string("  CHARACTER SUMMARY", 26 + ox, 4, COL_CYAN)
        draw_hline(8, 72, 5, COL_DIM)

        draw_string("Name   : " .. char_name, 10 + ox, 7, COL_WHITE)
        draw_string("Class  : " .. class_list[char_class], 10 + ox, 8, COL_CYAN)
        draw_string("Symbol : " .. symbol_list[char_symbol], 10 + ox, 9, color_values[char_color])
        draw_string("Color  : " .. color_names[char_color], 10 + ox, 10, color_values[char_color])

        draw_hline(10, 50, 12, COL_DIM)
        draw_string("Stats:", 10 + ox, 13, COL_GREEN)
        for i, name in ipairs(STAT_NAMES) do
            local bar = string.rep("#", stat_values[i])
            draw_string(string.format("  %s: %2d  %s", name, stat_values[i], bar), 10 + ox, 13 + i, COL_CYAN)
        end

        -- Total
        draw_string(string.format("  Total: %d / %d", stat_total(), STAT_POOL), 10 + ox, 20, COL_DIM)

        draw_hline(8, 72, 21, COL_DIM)
        draw_string("Press Enter to create, or Backspace to go back.", 10 + ox, 22, COL_GREEN)
        draw_button("Create!", 55, 23, true)
        draw_button("Back", 45, 23, true)
    end

    -- ── HUD ───────────────────────────────────────────────────
    lurek.render.setColor(COL_DIM[1], COL_DIM[2], COL_DIM[3], 0.4)
    lurek.render.drawText(string.format("FPS: %d", fps), SCREEN_W - 70, SCREEN_H - 18)
end
