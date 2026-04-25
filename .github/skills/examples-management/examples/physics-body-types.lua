---@diagnostic disable: undefined-global, undefined-field
-- CORRECT
world:newBody(x, y, "dynamic")
world:newBody(x, y, "static")

-- WRONG
world:newBody(x, y, 1)      -- numeric type codes
world:newBody(x, y, true)   -- boolean
