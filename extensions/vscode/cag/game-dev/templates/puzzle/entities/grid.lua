local Grid = {}
Grid.__index = Grid

function Grid.new(cols, rows, cellSize)
    local cells = {}
    for r = 1, rows do
        cells[r] = {}
        for c = 1, cols do
            cells[r][c] = 0
        end
    end
    local ox = (600 - cols * cellSize) / 2
    local oy = (600 - rows * cellSize) / 2 + 20
    return setmetatable({
        cols = cols, rows = rows,
        cellSize = cellSize,
        cells = cells,
        ox = ox, oy = oy,
    }, Grid)
end

function Grid:click(mx, my)
    local c = math.floor((mx - self.ox) / self.cellSize) + 1
    local r = math.floor((my - self.oy) / self.cellSize) + 1
    if c < 1 or c > self.cols or r < 1 or r > self.rows then return false end
    self.cells[r][c] = 1 - self.cells[r][c]
    return true
end

function Grid:checkWin()
    for r = 1, self.rows do
        for c = 1, self.cols do
            if self.cells[r][c] ~= 1 then return false end
        end
    end
    return true
end

function Grid:draw()
    for r = 1, self.rows do
        for c = 1, self.cols do
            local x = self.ox + (c - 1) * self.cellSize
            local y = self.oy + (r - 1) * self.cellSize
            if self.cells[r][c] == 1 then
                luna.gfx.setColor(0.3, 0.7, 0.9, 1)
            else
                luna.gfx.setColor(0.2, 0.2, 0.3, 1)
            end
            luna.gfx.rectangle("fill", x + 1, y + 1, self.cellSize - 2, self.cellSize - 2)
        end
    end
    luna.gfx.setColor(1, 1, 1, 1)
end

return Grid
