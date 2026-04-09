local Class = {}
Class.__index = Class

function Class:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Class:extend()
    local cls = {}
    cls.__index = cls
    setmetatable(cls, { __index = self })
    return cls
end

return Class
