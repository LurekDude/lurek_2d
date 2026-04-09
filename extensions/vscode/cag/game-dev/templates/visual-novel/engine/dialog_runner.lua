local DialogRunner = {}
DialogRunner.__index = DialogRunner

local CHAR_SPEED = 30 -- characters per second

function DialogRunner.new(lines)
    return setmetatable({
        lines = lines,
        index = 1,
        char_count = 0,
        finished = false,
        line_done = false,
    }, DialogRunner)
end

function DialogRunner:update(dt)
    if self.finished then return end
    local line = self.lines[self.index]
    if not line then
        self.finished = true
        return
    end
    if not self.line_done then
        self.char_count = self.char_count + CHAR_SPEED * dt
        if self.char_count >= #line.text then
            self.char_count = #line.text
            self.line_done = true
        end
    end
end

function DialogRunner:advance()
    if self.finished then return end
    if not self.line_done then
        -- Skip to end of current line
        self.char_count = #self.lines[self.index].text
        self.line_done = true
    else
        -- Next line
        self.index = self.index + 1
        self.char_count = 0
        self.line_done = false
        if self.index > #self.lines then
            self.finished = true
        end
    end
end

function DialogRunner:draw()
    if self.finished then
        luna.gfx.setColor(0.6, 0.6, 0.6, 1)
        luna.gfx.print("~ End ~", 360, 480)
        luna.gfx.setColor(1, 1, 1, 1)
        return
    end

    local line = self.lines[self.index]
    if not line then return end

    -- Dialog box
    luna.gfx.setColor(0, 0, 0, 0.8)
    luna.gfx.rectangle("fill", 20, 420, 760, 160)
    luna.gfx.setColor(0.5, 0.4, 0.7, 1)
    luna.gfx.rectangle("line", 20, 420, 760, 160)

    -- Speaker name
    luna.gfx.setColor(0.9, 0.7, 1, 1)
    luna.gfx.print(line.speaker, 40, 430)

    -- Typewriter text
    luna.gfx.setColor(1, 1, 1, 1)
    local visible = string.sub(line.text, 1, math.floor(self.char_count))
    luna.gfx.print(visible, 40, 460)

    -- Continue indicator
    if self.line_done then
        luna.gfx.setColor(0.7, 0.7, 0.7, 1)
        luna.gfx.print("▼", 750, 560)
        luna.gfx.setColor(1, 1, 1, 1)
    end
end

return DialogRunner
