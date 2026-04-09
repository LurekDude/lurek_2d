--- lurek.doll — Socket-Based Visual Composition Engine
-- Assembles composite visual objects (characters, vehicles, faces) from
-- interchangeable Part sprites attached to named Socket positions on a
-- DollTemplate blueprint. No physics, no collision, no gameplay logic —
-- purely visual composition with draw ordering.
--
-- @module lurek.doll

local M = {}

-- ── Part ──────────────────────────────────────────────────────────────────────

--- Create a new Part (visual element for attaching to a Doll socket).
-- @treturn Part blank part with defaults
function M.newPart()
    local part = {}

    local _partType   = ""
    local _texture    = nil
    local _quad       = nil
    local _offsetX    = 0
    local _offsetY    = 0
    local _rotation   = 0
    local _scaleX     = 1
    local _scaleY     = 1
    local _originX    = 0
    local _originY    = 0
    local _drawOrder  = 0
    local _visible    = true
    local _colorR     = 1
    local _colorG     = 1
    local _colorB     = 1
    local _colorA     = 1
    local _flipX      = false
    local _flipY      = false
    local _followsRotation = true
    local _fixture    = nil
    local _attributes = {}

    -- Texture / Quad
    function part:getTexture()       return _texture end
    function part:setTexture(tex)    _texture = tex end
    function part:getQuad()          return _quad end
    function part:setQuad(q)         _quad = q end

    -- Local Transform
    function part:getOffset()        return _offsetX, _offsetY end
    function part:setOffset(x, y)    _offsetX = x; _offsetY = y end
    function part:getRotation()      return _rotation end
    function part:setRotation(r)     _rotation = r end
    function part:getScale()         return _scaleX, _scaleY end
    function part:setScale(sx, sy)   _scaleX = sx; _scaleY = sy or sx end
    function part:getOrigin()        return _originX, _originY end
    function part:setOrigin(ox, oy)  _originX = ox; _originY = oy end

    -- Draw Order & Type
    function part:getDrawOrder()     return _drawOrder end
    function part:setDrawOrder(n)    _drawOrder = n end
    function part:getPartType()      return _partType end
    function part:setPartType(t)     _partType = t end

    -- Visibility & Appearance
    function part:isVisible()        return _visible end
    function part:setVisible(v)      _visible = v end
    function part:getColor()         return _colorR, _colorG, _colorB, _colorA end
    function part:setColor(r, g, b, a)
        _colorR = r; _colorG = g; _colorB = b; _colorA = a or 1
    end
    function part:getFlip()          return _flipX, _flipY end
    function part:setFlip(fx, fy)    _flipX = fx; _flipY = fy or false end

    -- Behaviour
    function part:getFollowsRotation()    return _followsRotation end
    function part:setFollowsRotation(f)   _followsRotation = f end

    -- Attributes (user-defined key-value store)
    function part:getAttribute(key)       return _attributes[key] end
    function part:setAttribute(key, val)  _attributes[key] = val end
    function part:getAttributeKeys()
        local keys = {}
        for k in pairs(_attributes) do keys[#keys + 1] = k end
        return keys
    end

    -- Optional physics fixture ref (stored, never called)
    function part:getFixture()       return _fixture end
    function part:setFixture(f)      _fixture = f end

    return part
end

-- ── DollTemplate ──────────────────────────────────────────────────────────────

--- Create a new DollTemplate (socket layout blueprint).
-- @param name string template name
-- @treturn DollTemplate empty template
function M.newTemplate(name)
    local tmpl = {}
    local _name    = name or ""
    local _sockets = {}       -- ordered array of socket defs
    local _index   = {}       -- name → array index for O(1) lookup

    function tmpl:getName()          return _name end
    function tmpl:setName(n)         _name = n end

    --- Add a socket to the template.
    -- @param socketName string unique socket name
    -- @param acceptType string part type filter ("" = accept anything)
    -- @param x number offset X from doll origin (default 0)
    -- @param y number offset Y from doll origin (default 0)
    -- @param rotation number socket rotation in radians (default 0)
    -- @param drawOrder number z-sort key (default 0)
    function tmpl:addSocket(socketName, acceptType, x, y, rotation, drawOrder)
        if _index[socketName] then return end
        local socket = {
            name       = socketName,
            acceptType = acceptType or "",
            x          = x or 0,
            y          = y or 0,
            rotation   = rotation or 0,
            drawOrder  = drawOrder or 0,
        }
        _sockets[#_sockets + 1] = socket
        _index[socketName] = #_sockets
    end

    function tmpl:removeSocket(socketName)
        local idx = _index[socketName]
        if not idx then return false end
        table.remove(_sockets, idx)
        _index[socketName] = nil
        -- rebuild index
        for i, s in ipairs(_sockets) do _index[s.name] = i end
        return true
    end

    function tmpl:getSocket(socketName)
        local idx = _index[socketName]
        if not idx then return nil end
        local s = _sockets[idx]
        return {
            name       = s.name,
            acceptType = s.acceptType,
            x          = s.x,
            y          = s.y,
            rotation   = s.rotation,
            drawOrder  = s.drawOrder,
        }
    end

    function tmpl:getSocketNames()
        local names = {}
        for _, s in ipairs(_sockets) do names[#names + 1] = s.name end
        return names
    end

    function tmpl:getSocketCount()
        return #_sockets
    end

    --- Internal: iterate raw sockets (used by Doll).
    function tmpl:_iterSockets()
        return ipairs(_sockets)
    end

    return tmpl
end

-- ── Doll ──────────────────────────────────────────────────────────────────────

--- Create a new Doll (runtime composite instance of a template).
-- @param template DollTemplate socket layout to use
-- @treturn Doll runtime doll instance
function M.newDoll(template)
    local doll = {}

    local _template = template
    local _x        = 0
    local _y        = 0
    local _rotation = 0
    local _scaleX   = 1
    local _scaleY   = 1
    local _visible  = true
    local _slots    = {}       -- socketName → Part
    local _body     = nil
    local _userData = nil

    -- Transform
    function doll:getPosition()      return _x, _y end
    function doll:setPosition(x, y)  _x = x; _y = y end
    function doll:getRotation()      return _rotation end
    function doll:setRotation(r)     _rotation = r end
    function doll:getScale()         return _scaleX, _scaleY end
    function doll:setScale(sx, sy)   _scaleX = sx; _scaleY = sy or sx end

    -- Template
    function doll:getTemplate()      return _template end

    -- Visibility
    function doll:isVisible()        return _visible end
    function doll:setVisible(v)      _visible = v end

    -- Optional body / user data refs
    function doll:getBody()          return _body end
    function doll:setBody(b)         _body = b end
    function doll:getUserData()      return _userData end
    function doll:setUserData(v)     _userData = v end

    --- Attach a Part to a named socket.
    -- Returns false if socket not found or type mismatch.
    -- @param socketName string
    -- @param part Part
    -- @treturn boolean success
    function doll:attach(socketName, part)
        local socket = _template:getSocket(socketName)
        if not socket then return false end
        -- type compatibility check
        local accept = socket.acceptType
        if accept ~= "" and part:getPartType() ~= accept then
            return false
        end
        _slots[socketName] = part
        return true
    end

    --- Detach the Part from a socket, returning it.
    -- @param socketName string
    -- @treturn Part|nil detached part
    function doll:detach(socketName)
        local part = _slots[socketName]
        _slots[socketName] = nil
        return part
    end

    function doll:getPartAt(socketName)
        return _slots[socketName]
    end

    function doll:findSocket(part)
        for name, p in pairs(_slots) do
            if p == part then return name end
        end
        return nil
    end

    function doll:detachAll()
        _slots = {}
    end

    function doll:getAttachedSockets()
        local names = {}
        for name in pairs(_slots) do names[#names + 1] = name end
        return names
    end

    function doll:getEmptySockets()
        local names = {}
        for _, socketName in ipairs(_template:getSocketNames()) do
            if not _slots[socketName] then
                names[#names + 1] = socketName
            end
        end
        return names
    end

    --- Compute world-transform draw list sorted by drawOrder.
    -- Each entry: {socketName, part, x, y, rotation, scaleX, scaleY, drawOrder}
    -- Does NOT filter by part visibility — caller handles that.
    -- @treturn table ordered draw list
    function doll:getDrawList()
        local list = {}
        local cos_r = math.cos(_rotation)
        local sin_r = math.sin(_rotation)

        for _, socket in _template:_iterSockets() do
            local part = _slots[socket.name]
            if part then
                local ox, oy = part:getOffset()
                local localX = (socket.x + ox) * _scaleX
                local localY = (socket.y + oy) * _scaleY

                local worldX = _x + localX * cos_r - localY * sin_r
                local worldY = _y + localX * sin_r + localY * cos_r

                local partRot = part:getRotation()
                local worldRot
                if part:getFollowsRotation() then
                    worldRot = _rotation + socket.rotation + partRot
                else
                    worldRot = socket.rotation + partRot
                end

                local psx, psy = part:getScale()
                local pfx, pfy = part:getFlip()
                local worldSX = _scaleX * psx * (pfx and -1 or 1)
                local worldSY = _scaleY * psy * (pfy and -1 or 1)

                list[#list + 1] = {
                    socketName = socket.name,
                    part       = part,
                    x          = worldX,
                    y          = worldY,
                    rotation   = worldRot,
                    scaleX     = worldSX,
                    scaleY     = worldSY,
                    drawOrder  = socket.drawOrder + part:getDrawOrder(),
                }
            end
        end

        -- sort by drawOrder ascending; break ties by socket definition order
        table.sort(list, function(a, b)
            return a.drawOrder < b.drawOrder
        end)

        return list
    end

    --- Convenience draw method — renders all visible parts via lurek.gfx.
    -- Requires lurek.gfx to be available in the global environment.
    function doll:draw()
        if not _visible then return end
        local g = luna and lurek.gfx
        if not g then return end

        local drawList = self:getDrawList()
        for _, entry in ipairs(drawList) do
            local part = entry.part
            if part:isVisible() then
                g.push()
                g.translate(entry.x, entry.y)
                g.rotate(entry.rotation)
                g.scale(entry.scaleX, entry.scaleY)

                local r, gb, b, a = part:getColor()
                g.setColor(r, gb, b, a)

                local tex = part:getTexture()
                if tex then
                    local quad = part:getQuad()
                    local ox, oy = part:getOrigin()
                    if quad then
                        g.drawQuad(tex, quad, 0, 0, 0, 1, 1, ox, oy)
                    else
                        g.draw(tex, 0, 0, 0, 1, 1, ox, oy)
                    end
                end

                g.setColor(1, 1, 1, 1)
                g.pop()
            end
        end
    end

    return doll
end

return M
