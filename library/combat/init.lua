--- @module library.combat
--- @status full
--- Vehicle/turret/weapon combat system: collision groups, armor, chassis,
--- turrets, weapons, projectiles, projectile pools, and the combat world.
--- Pure-Lua port of src/combat/.
--- @see lurek.math
--- @see lurek.physics
--- @see lurek.log

local M = {}

--- Optional debug logging via lurek.log when running inside the engine.
--- Falls back to a no-op when lurek is unavailable (e.g. in tests).
-- @see lurek.log
local _log_debug = function() end
if rawget(_G, 'lurek') and lurek.log and type(lurek.log.debug) == 'function' then
    _log_debug = function(msg) lurek.log.debug('[combat] ' .. msg) end
end

local DEFAULT_POOL_SIZE = 64
M.DEFAULT_POOL_SIZE = DEFAULT_POOL_SIZE

-- ÔöÇÔöÇ ProjectileType enum ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

M.ProjectileType = {
    Ballistic = 'ballistic',
    Homing    = 'homing',
    Ray       = 'ray',
    Area      = 'area',
    Beam      = 'beam',
}

-- ÔöÇÔöÇ ArmorZone enum ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

M.ArmorZone = {
    Front = 'front',
    Rear  = 'rear',
    Side  = 'side',
}

-- ÔöÇÔöÇ CollisionGroupSet ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local CollisionGroupSet = {}
CollisionGroupSet.__index = CollisionGroupSet

local MAX_GROUPS = 16

--- Creates an empty collision-group set.
-- @return CollisionGroupSet New instance with no groups or rules.
function M.newCollisionGroupSet()
    return setmetatable({
        groups     = {},  -- { {name=str, bit=int}, ... }
        collisions = {},  -- { {a_idx, b_idx, collides}, ... }
        _next_bit  = 1,
    }, CollisionGroupSet)
end

--- Defines a named group and returns its power-of-two category bit.
--- Returns nil plus an error string if the name is empty, taken, or the 16-group
--- limit has been reached (bitmask overflow protection).
-- @tparam string name Unique group name (non-empty).
-- @treturn number|nil Category bit, or nil on error.
-- @treturn string|nil Error message when first return is nil.
function CollisionGroupSet:defineGroup(name)
    if type(name) ~= 'string' or name == '' then
        return nil, 'group name must be a non-empty string'
    end
    for _, g in ipairs(self.groups) do
        if g.name == name then return nil, 'group already defined: ' .. name end
    end
    if #self.groups >= MAX_GROUPS then
        return nil, 'max collision groups reached (limit: ' .. MAX_GROUPS .. '); bitmask would overflow'
    end
    local bit = self._next_bit
    self._next_bit = self._next_bit * 2
    self.groups[#self.groups+1] = { name = name, bit = bit }
    return bit
end

--- Returns the category bit for the named group, or nil.
-- @param name string Group name.
-- @return number|nil Category bit or nil.
function CollisionGroupSet:getGroupBit(name)
    for _, g in ipairs(self.groups) do if g.name == name then return g.bit end end
    return nil
end

local function find_group_index(self, name)
    for i, g in ipairs(self.groups) do if g.name == name then return i end end
    return nil
end

--- Sets whether two named groups should collide with each other.
-- @param group_a  string   First group name.
-- @param group_b  string   Second group name.
-- @param collides boolean  True to enable collision.
-- @return boolean True on success; false if either group is unknown.
function CollisionGroupSet:setCollides(group_a, group_b, collides)
    local ia = find_group_index(self, group_a)
    local ib = find_group_index(self, group_b)
    if not ia then return false, 'unknown group: ' .. group_a end
    if not ib then return false, 'unknown group: ' .. group_b end
    for _, r in ipairs(self.collisions) do
        if (r[1] == ia and r[2] == ib) or (r[1] == ib and r[2] == ia) then
            r[3] = collides; return true
        end
    end
    self.collisions[#self.collisions+1] = { ia, ib, collides }
    return true
end

--- Returns whether two named groups collide (defaults to true).
-- @param group_a string First group name.
-- @param group_b string Second group name.
-- @return boolean True if the groups collide.
function CollisionGroupSet:getCollides(group_a, group_b)
    local ia = find_group_index(self, group_a)
    local ib = find_group_index(self, group_b)
    if not ia or not ib then return true end
    for _, r in ipairs(self.collisions) do
        if (r[1] == ia and r[2] == ib) or (r[1] == ib and r[2] == ia) then
            return r[3]
        end
    end
    return true
end

--- Computes the collision filter mask bits for the named group.
-- @param group string Group name.
-- @return number Bitmask of all colliding groups.
function CollisionGroupSet:computeMask(group)
    local gi = find_group_index(self, group)
    if not gi then return 0 end
    local mask = 0
    for i, g in ipairs(self.groups) do
        local collides = true
        for _, r in ipairs(self.collisions) do
            if (r[1] == gi and r[2] == i) or (r[1] == i and r[2] == gi) then
                collides = r[3]; break
            end
        end
        if collides then mask = mask + g.bit end
    end
    return mask
end

--- Returns the number of defined groups.
-- @return number Group count.
function CollisionGroupSet:groupCount() return #self.groups end
--- Returns an array of all defined group names.
-- @return table Array of group name strings.
function CollisionGroupSet:groupNames()
    local out = {}
    for _, g in ipairs(self.groups) do out[#out+1] = g.name end
    return out
end
--- Clears all groups and collision rules.
function CollisionGroupSet:reset()
    self.groups = {}; self.collisions = {}; self._next_bit = 1
end

-- ÔöÇÔöÇ MountSlot ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Creates a new turret or weapon mount slot.
-- @tparam string id Unique slot identifier (non-empty).
-- @tparam number x Local X offset from chassis centre (default 0).
-- @tparam number y Local Y offset from chassis centre (default 0).
-- @tparam string size_class Size class: 'small', 'medium', or 'large' (default 'medium').
-- @treturn table MountSlot with arc_min=-pi, arc_max=pi defaults.
function M.newMountSlot(id, x, y, size_class)
    if type(id) ~= 'string' or id == '' then
        error('newMountSlot: id must be a non-empty string', 2)
    end
    return {
        id         = id,
        x          = x or 0,
        y          = y or 0,
        size_class = size_class or 'medium',
        arc_min    = -math.pi,
        arc_max    = math.pi,
    }
end

-- ÔöÇÔöÇ Chassis ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local Chassis = {}
Chassis.__index = Chassis

--- Creates a new chassis with the given physics body ID and maximum hit points.
-- @tparam number body_id Physics body ID.
-- @tparam number max_hp Maximum hit points (must be >= 0; HP starts at max_hp).
-- @treturn Chassis New chassis instance.
function M.newChassis(body_id, max_hp)
    if type(body_id) ~= 'number' then
        error('newChassis: body_id must be a number', 2)
    end
    if type(max_hp) ~= 'number' or max_hp < 0 then
        error('newChassis: max_hp must be a non-negative number', 2)
    end
    return setmetatable({
        body_id    = body_id,
        team       = '',
        hp         = max_hp,
        max_hp     = max_hp,
        slots      = {},
        armor      = {},
        turret_ids = {},
        destroyed  = false,
        user_data  = nil,
    }, Chassis)
end

--- Appends a mount slot to this chassis.
-- @param slot table A MountSlot created by newMountSlot.
function Chassis:addSlot(slot) self.slots[#self.slots+1] = slot end

--- Returns the mount slot with the given ID, or nil.
-- @param id string Slot identifier.
-- @return table|nil The matching MountSlot or nil.
function Chassis:getSlot(id)
    for _, s in ipairs(self.slots) do if s.id == id then return s end end
    return nil
end

--- Returns an ordered array of all mount slots.
-- @return table Array of MountSlot tables.
function Chassis:getSlots() return self.slots end

--- Applies damage to the chassis, clamping HP to zero.
--- Sets destroyed=true if HP reaches zero.
-- @tparam number amount Damage to apply (must be >= 0).
-- @treturn number Actual damage dealt.
function Chassis:takeDamage(amount)
    if type(amount) ~= 'number' or amount < 0 then
        error('takeDamage: amount must be a non-negative number', 2)
    end
    local actual = math.min(amount, self.hp)
    self.hp = self.hp - actual
    if self.hp <= 0 then self.hp = 0; self.destroyed = true end
    _log_debug('damage dealt: ' .. actual .. ' (hp: ' .. self.hp .. '/' .. self.max_hp .. ')')
    return actual
end

--- Heals the chassis, clamping HP to max_hp.
-- @param amount number HP to restore.
-- @return number Actual amount healed.
function Chassis:heal(amount)
    local actual = math.min(amount, self.max_hp - self.hp)
    self.hp = self.hp + actual
    return actual
end

--- Returns true if the chassis is destroyed or HP has reached zero.
-- @return boolean True if dead.
function Chassis:isDead() return self.destroyed or self.hp <= 0 end
--- Returns the armor value for the named zone (defaults to 0).
-- @param zone string Zone name, e.g. 'front', 'rear', 'side'.
-- @return number Armor value.
function Chassis:getArmor(zone) return self.armor[zone] or 0 end
--- Sets the armor value for the named zone.
-- @param zone  string Zone name.
-- @param value number Armor value.
function Chassis:setArmor(zone, value) self.armor[zone] = value end

-- ÔöÇÔöÇ Turret ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local Turret = {}
Turret.__index = Turret

--- Creates a new turret with the given physics body and joint IDs.
-- @tparam number body_id Physics body ID for the turret plate.
-- @tparam number joint_id Revolute joint ID connecting turret to chassis.
-- @treturn Turret New turret with default arc [-pi, pi].
function M.newTurret(body_id, joint_id)
    if type(body_id) ~= 'number' then
        error('newTurret: body_id must be a number', 2)
    end
    if type(joint_id) ~= 'number' then
        error('newTurret: joint_id must be a number', 2)
    end
    return setmetatable({
        body_id      = body_id,
        joint_id     = joint_id,
        turn_speed   = 1.0,
        arc_min      = -math.pi,
        arc_max      = math.pi,
        target_angle = nil,
        weapon       = nil,
        chassis_id   = nil,
        size_class   = 'medium',
        destroyed    = false,
    }, Turret)
end

--- Updates the turret toward its target angle, snapping to the closest arc
--- boundary when the target lies outside [arc_min, arc_max].
--- Returns the desired angular velocity, or nil if no target is set.
-- @tparam number dt Delta time in seconds.
-- @tparam number current_angle Current turret angle in radians.
-- @treturn number|nil Angular velocity or nil.
function Turret:update(dt, current_angle)
    if not self.target_angle then return nil end
    -- Snap to closest arc boundary when target is outside the arc
    local effective = self:clampToArc(self.target_angle)
    local diff = effective - current_angle
    -- normalize to [-pi, pi]
    while diff > math.pi do diff = diff - 2*math.pi end
    while diff < -math.pi do diff = diff + 2*math.pi end
    local max_step = self.turn_speed * dt
    if math.abs(diff) <= max_step then return diff / (dt > 0 and dt or 1) end
    if diff > 0 then return self.turn_speed else return -self.turn_speed end
end

--- Sets the desired target angle for the turret.
-- @tparam number angle Target angle in radians.
function Turret:aimAtAngle(angle)
    self.target_angle = angle
    _log_debug('turret aim: ' .. tostring(angle) .. ' rad')
end

--- Returns true if the target angle is within the turret arc and tolerance.
-- Mirrors Rust: checks whether clamp_to_arc(target) Ôëł target.
-- Returns true when no target is set.
-- @param tolerance number Maximum allowed arc-boundary deviation in radians.
-- @return boolean True if within tolerance or no target is set.
function Turret:isAimed(tolerance)
    if not self.target_angle then return true end
    local clamped = self:clampToArc(self.target_angle)
    return math.abs(clamped - self.target_angle) < tolerance
end

--- Clamps an angle to the turret arc limits [arc_min, arc_max].
-- @param angle number Angle in radians.
-- @return number Clamped angle.
function Turret:clampToArc(angle)
    return math.max(self.arc_min, math.min(self.arc_max, angle))
end

-- ÔöÇÔöÇ Weapon ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local Weapon = {}
Weapon.__index = Weapon

--- Creates a new weapon with default values.
--- Defaults: fire_rate=1, ammo=-1 (infinite), damage_amount=10, range=500,
---           projectile_speed=300, burst_size=1.
-- @tparam string name Weapon display name (non-empty).
-- @treturn Weapon New weapon instance.
function M.newWeapon(name)
    if type(name) ~= 'string' or name == '' then
        error('newWeapon: name must be a non-empty string', 2)
    end
    return setmetatable({
        name               = name,
        fire_rate          = 1.0,
        cooldown_remaining = 0,
        ammo               = -1,
        max_ammo           = -1,
        burst_size         = 1,
        burst_delay        = 0,
        burst_remaining    = 0,
        spread             = 0,
        damage_amount      = 10.0,
        damage_type        = 'kinetic',
        penetration        = 0,
        range              = 500.0,
        projectile_speed   = 300.0,
        projectile_type    = M.ProjectileType.Ballistic,
        firing             = false,
    }, Weapon)
end

--- Returns true if the weapon is ready to fire.
-- @return boolean True when cooldown elapsed and ammo is available.
function Weapon:canFire()
    return self.cooldown_remaining <= 0 and (self.ammo == -1 or self.ammo > 0)
end

--- Attempts to fire the weapon. Returns true if a shot was produced.
--- Consumes one ammo token, applies cooldown, and manages burst state.
--- Intra-burst shots use burst_delay; after the last burst shot, inter-burst
--- cooldown (1/fire_rate) is applied.
-- @tparam number dt Delta time (unused; kept for API parity with Rust).
-- @treturn boolean True if a shot was fired.
function Weapon:fire(dt)
    if not self:canFire() then return false end
    if self.ammo > 0 then self.ammo = self.ammo - 1 end
    if self.burst_remaining > 0 then
        self.burst_remaining = self.burst_remaining - 1
        if self.burst_remaining > 0 then
            self.cooldown_remaining = self.burst_delay
        else
            -- Last shot in burst: apply inter-burst cooldown (fire_rate)
            self.cooldown_remaining = self.fire_rate > 0 and (1.0 / self.fire_rate) or 0
        end
    else
        self.burst_remaining = math.max(0, self.burst_size - 1)
        if self.burst_remaining > 0 then
            self.cooldown_remaining = self.burst_delay
        else
            self.cooldown_remaining = self.fire_rate > 0 and (1.0 / self.fire_rate) or 0
        end
    end
    _log_debug('weapon fired: ' .. self.name .. ' (ammo: ' .. self.ammo .. ', burst_remaining: ' .. self.burst_remaining .. ')')
    return true
end

--- Activates continuous firing mode.
function Weapon:startFiring() self.firing = true end
--- Deactivates firing and resets burst_remaining to zero.
function Weapon:stopFiring()  self.firing = false; self.burst_remaining = 0 end
--- Returns true when the weapon is in firing mode.
-- @return boolean Firing state.
function Weapon:isFiring()    return self.firing end

--- Ticks the cooldown timer by dt seconds.
-- @param dt number Delta time in seconds.
function Weapon:updateCooldown(dt)
    if self.cooldown_remaining > 0 then
        self.cooldown_remaining = self.cooldown_remaining - dt
        if self.cooldown_remaining < 0 then self.cooldown_remaining = 0 end
    end
end

--- Reloads ammo. Full reload when amount is nil; partial reload otherwise.
-- Clamped to max_ammo when max_ammo > 0.
-- @param amount number|nil Rounds to add, or nil for a full reload.
function Weapon:reload(amount)
    if amount == nil then
        self.ammo = self.max_ammo
    else
        self.ammo = math.min(self.ammo + amount, self.max_ammo > 0 and self.max_ammo or (self.ammo + amount))
    end
end

--- Returns true when finite ammo reaches zero.
-- @return boolean True when ammo == 0 and not infinite.
function Weapon:isOutOfAmmo()
    return self.ammo ~= -1 and self.ammo <= 0
end

-- ÔöÇÔöÇ Projectile ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local Projectile = {}
Projectile.__index = Projectile

local function default_projectile(body_id)
    return setmetatable({
        body_id            = body_id or 0,
        active             = false,
        lifetime           = 0,
        distance_traveled  = 0,
        max_range          = 0,
        speed              = 0,
        projectile_type    = M.ProjectileType.Ballistic,
        damage_amount      = 0,
        damage_type        = '',
        source_weapon_name = '',
        target_pos         = nil,
        target_body        = nil,
        tracking_strength  = 0,
        turn_rate          = 0,
    }, Projectile)
end

--- Resets this projectile to its inactive default state.
-- Clears all fields including projectile_type (restored to Ballistic).
function Projectile:reset()
    self.active = false
    self.lifetime = 0
    self.distance_traveled = 0
    self.max_range = 0
    self.speed = 0
    self.projectile_type = M.ProjectileType.Ballistic
    self.damage_amount = 0
    self.damage_type = ''
    self.source_weapon_name = ''
    self.target_pos = nil
    self.target_body = nil
    self.tracking_strength = 0
    self.turn_rate = 0
end

--- Updates lifetime and distance_traveled for an active projectile.
-- Does nothing if the projectile is not active.
-- @param dt         number Delta time in seconds.
-- @param body_x     number Current X position (passed for physics parity).
-- @param body_y     number Current Y position.
-- @param body_angle number Current angle in radians.
function Projectile:update(dt, body_x, body_y, body_angle)
    if not self.active then return end
    self.lifetime = self.lifetime + dt
    self.distance_traveled = self.distance_traveled + self.speed * dt
end

-- ÔöÇÔöÇ ProjectilePool ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local MAX_POOL_SIZE = 1024
M.MAX_POOL_SIZE = MAX_POOL_SIZE

local ProjectilePool = {}
ProjectilePool.__index = ProjectilePool

--- Creates a new projectile pool with the given capacity.
--- Defaults to DEFAULT_POOL_SIZE (64) when pool_size is nil; capped at MAX_POOL_SIZE (1024).
-- @tparam number pool_size Pool capacity (default 64, max 1024).
-- @tparam string projectile_type ProjectileType for this pool (default Ballistic).
-- @treturn ProjectilePool New pool with all slots free.
function M.newProjectilePool(pool_size, projectile_type)
    pool_size = math.min(pool_size or DEFAULT_POOL_SIZE, MAX_POOL_SIZE)
    if pool_size < 1 then
        error('newProjectilePool: pool_size must be >= 1', 2)
    end
    local projectiles = {}
    local free = {}
    for i = 1, pool_size do
        projectiles[i] = default_projectile(i - 1)
        free[#free+1] = i
    end
    return setmetatable({
        projectiles     = projectiles,
        pool_size       = pool_size,
        body_ids        = {},
        free_indices    = free,
        projectile_type = projectile_type or M.ProjectileType.Ballistic,
        collision_group = '',
    }, ProjectilePool)
end

--- Spawns a projectile from the free pool.
-- @param x           number Spawn X position.
-- @param y           number Spawn Y position.
-- @param angle       number Launch angle in radians.
-- @param speed       number Travel speed in world units per second.
-- @param damage      number Damage dealt on hit.
-- @param damage_type string Damage type tag.
-- @param range       number Maximum range before expiry.
-- @return number|nil Projectile index, or nil if the pool is exhausted.
function ProjectilePool:spawn(x, y, angle, speed, damage, damage_type, range)
    if #self.free_indices == 0 then return nil end
    local idx = table.remove(self.free_indices)
    local p = self.projectiles[idx]
    p.active = true
    p.speed = speed
    p.damage_amount = damage
    p.damage_type = damage_type or ''
    p.max_range = range
    p.lifetime = 0
    p.distance_traveled = 0
    p.projectile_type = self.projectile_type
    _log_debug('projectile spawned: idx=' .. idx .. ' speed=' .. speed .. ' damage=' .. damage)
    return idx
end

--- Returns a projectile slot to the free pool.
-- Does nothing if the slot is already inactive (prevents double-free).
-- @param idx number 1-based projectile index.
function ProjectilePool:release(idx)
    local p = self.projectiles[idx]
    if p and p.active then
        p:reset()
        self.free_indices[#self.free_indices+1] = idx
    end
end

--- Returns the number of currently active projectiles.
-- @return number Active count.
function ProjectilePool:activeCount()
    return self.pool_size - #self.free_indices
end

--- Returns the number of free slots.
-- @return number Free count.
function ProjectilePool:freeCount()
    return #self.free_indices
end

--- Returns an array of 1-based indices for all active projectiles.
-- @return table Array of active indices.
function ProjectilePool:getActive()
    local out = {}
    for i, p in ipairs(self.projectiles) do
        if p.active then out[#out+1] = i end
    end
    return out
end

--- Returns the projectile at the given 1-based index, or nil if out of range.
-- @param idx number 1-based slot index.
-- @return table|nil Projectile table or nil.
function ProjectilePool:get(idx) return self.projectiles[idx] end

--- Releases all active projectiles back to the free pool.
function ProjectilePool:resetAll()
    self.free_indices = {}
    for i, p in ipairs(self.projectiles) do
        p:reset()
        self.free_indices[#self.free_indices+1] = i
    end
end

-- ÔöÇÔöÇ CombatWorld ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

local CombatWorld = {}
CombatWorld.__index = CombatWorld

--- Creates an empty combat world.
--- This is a logical container only — broad-phase hit detection and shape
--- queries should be performed against a real physics world via
--- `lurek.physics.newWorld():raycast()` / `:shapecast()` and the resulting
--- contacts then mapped back onto chassis/turret/weapon entities here.
-- @see lurek.physics
-- @see lurek.math
-- @return CombatWorld New world with no entities.
function M.newCombatWorld()
    return setmetatable({
        chassis_list     = {},
        turrets          = {},
        weapons          = {},
        pools            = {},
        collision_groups = M.newCollisionGroupSet(),
    }, CombatWorld)
end

--- Adds a chassis and returns its 1-based index.
-- @param chassis table A Chassis created by newChassis.
-- @return number 1-based index.
function CombatWorld:addChassis(chassis)
    self.chassis_list[#self.chassis_list+1] = chassis
    return #self.chassis_list
end
--- Returns the chassis at the given 1-based index, or nil.
-- @param idx number 1-based index.
-- @return table|nil Chassis or nil.
function CombatWorld:getChassis(idx)    return self.chassis_list[idx] end

--- Adds a turret and returns its 1-based index.
-- @param turret table A Turret created by newTurret.
-- @return number 1-based index.
function CombatWorld:addTurret(turret)
    self.turrets[#self.turrets+1] = turret
    return #self.turrets
end
--- Returns the turret at the given 1-based index, or nil.
-- @param idx number 1-based index.
-- @return table|nil Turret or nil.
function CombatWorld:getTurret(idx)     return self.turrets[idx] end

--- Adds a weapon and returns its 1-based index.
-- @param weapon table A Weapon created by newWeapon.
-- @return number 1-based index.
function CombatWorld:addWeapon(weapon)
    self.weapons[#self.weapons+1] = weapon
    return #self.weapons
end
--- Returns the weapon at the given 1-based index, or nil.
-- @param idx number 1-based index.
-- @return table|nil Weapon or nil.
function CombatWorld:getWeapon(idx)     return self.weapons[idx] end

--- Adds a projectile pool and returns its 1-based index.
-- @param pool table A ProjectilePool created by newProjectilePool.
-- @return number 1-based index.
function CombatWorld:addPool(pool)
    self.pools[#self.pools+1] = pool
    return #self.pools
end
--- Returns the projectile pool at the given 1-based index, or nil.
-- @param idx number 1-based index.
-- @return table|nil ProjectilePool or nil.
function CombatWorld:getPool(idx)       return self.pools[idx] end

--- Returns the total number of active projectiles across all pools.
-- @return number Active projectile count.
function CombatWorld:activeProjectileCount()
    local n = 0
    for _, p in ipairs(self.pools) do n = n + p:activeCount() end
    return n
end

--- Returns the number of non-destroyed chassis.
-- @return number Live chassis count.
function CombatWorld:activeChassisCount()
    local n = 0
    for _, c in ipairs(self.chassis_list) do
        if not c.destroyed then n = n + 1 end
    end
    return n
end

--- Updates all weapon cooldowns by dt seconds.
-- @param dt number Delta time in seconds.
function CombatWorld:update(dt)
    for _, w in ipairs(self.weapons) do w:updateCooldown(dt) end
end

--- Clears all combat entities and resets collision groups.
function CombatWorld:reset()
    self.chassis_list = {}
    self.turrets = {}
    self.weapons = {}
    self.pools = {}
    self.collision_groups:reset()
end

--- Removes destroyed chassis from the list.
-- Warning: invalidates stored 1-based indices after the call.
function CombatWorld:cleanup()
    local new_list = {}
    for _, c in ipairs(self.chassis_list) do
        if not c.destroyed then new_list[#new_list+1] = c end
    end
    self.chassis_list = new_list
end


-- ÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉ
-- PARITY ADDITIONS ÔÇö Phase 2A  (combat)
-- ÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉÔĽÉ

-- ÔöÇÔöÇ Weapon: property getters/setters ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Returns the weapon display name. @return string Name.
function Weapon:getName()               return self.name end
--- Sets the weapon display name. @param v string Name.
function Weapon:setName(v)              self.name = v end

--- Returns fire rate in rounds/s. @return number Fire rate.
function Weapon:getFireRate()           return self.fire_rate end
--- Sets fire rate in rounds/s. @param v number Fire rate.
function Weapon:setFireRate(v)          self.fire_rate = v end

--- Returns current ammo count (-1 = infinite). @return number Ammo.
function Weapon:getAmmo()               return self.ammo end
--- Sets current ammo count. @param v number Ammo.
function Weapon:setAmmo(v)              self.ammo = v end

--- Returns maximum ammo capacity. @return number Max ammo.
function Weapon:getMaxAmmo()            return self.max_ammo end
--- Sets maximum ammo capacity. @param v number Max ammo.
function Weapon:setMaxAmmo(v)           self.max_ammo = v end

--- Returns burst size (rounds per burst). @return number Burst size.
function Weapon:getBurstSize()          return self.burst_size end
--- Sets burst size. @param v number Burst size.
function Weapon:setBurstSize(v)         self.burst_size = v end

--- Returns delay between burst rounds in seconds. @return number Burst delay.
function Weapon:getBurstDelay()         return self.burst_delay end
--- Sets burst delay in seconds. @param v number Burst delay.
function Weapon:setBurstDelay(v)        self.burst_delay = v end

--- Returns remaining rounds in current burst. @return number Burst remaining.
function Weapon:getBurstRemaining()     return self.burst_remaining end
--- Sets remaining rounds in current burst. @param v number Value.
function Weapon:setBurstRemaining(v)    self.burst_remaining = v end

--- Returns angular spread in radians. @return number Spread.
function Weapon:getSpread()             return self.spread end
--- Sets angular spread in radians. @param v number Spread.
function Weapon:setSpread(v)            self.spread = v end

--- Returns damage per hit. @return number Damage amount.
function Weapon:getDamageAmount()       return self.damage_amount end
--- Sets damage per hit. @param v number Damage amount.
function Weapon:setDamageAmount(v)      self.damage_amount = v end

--- Returns damage type tag. @return string Damage type.
function Weapon:getDamageType()         return self.damage_type end
--- Sets damage type tag. @param v string Damage type.
function Weapon:setDamageType(v)        self.damage_type = v end

--- Returns armor penetration value. @return number Penetration.
function Weapon:getPenetration()        return self.penetration end
--- Sets armor penetration value. @param v number Penetration.
function Weapon:setPenetration(v)       self.penetration = v end

--- Returns maximum range in world units. @return number Range.
function Weapon:getRange()              return self.range end
--- Sets maximum range in world units. @param v number Range.
function Weapon:setRange(v)             self.range = v end

--- Returns projectile travel speed. @return number Speed.
function Weapon:getProjectileSpeed()    return self.projectile_speed end
--- Sets projectile travel speed. @param v number Speed.
function Weapon:setProjectileSpeed(v)   self.projectile_speed = v end

--- Returns projectile type enum value. @return string ProjectileType.
function Weapon:getProjectileType()     return self.projectile_type end
--- Sets projectile type. @param v string ProjectileType value.
function Weapon:setProjectileType(v)    self.projectile_type = v end

-- ÔöÇÔöÇ Turret: property getters/setters ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

--- Returns the turret rotation speed in radians/s. @return number Turn speed.
function Turret:getTurnSpeed()          return self.turn_speed end
--- Sets the turret rotation speed. @param v number Turn speed in radians/s.
function Turret:setTurnSpeed(v)         self.turn_speed = v end

--- Returns the minimum arc angle in radians. @return number arc_min.
function Turret:getArcMin()             return self.arc_min end
--- Sets the minimum arc angle in radians. @param v number arc_min.
function Turret:setArcMin(v)            self.arc_min = v end

--- Returns the maximum arc angle in radians. @return number arc_max.
function Turret:getArcMax()             return self.arc_max end
--- Sets the maximum arc angle in radians. @param v number arc_max.
function Turret:setArcMax(v)            self.arc_max = v end

--- Returns the current target angle, or nil. @return number|nil Target angle in radians.
function Turret:getTargetAngle()        return self.target_angle end
--- Sets the target angle (nil clears the target). @param v number|nil Target angle.
function Turret:setTargetAngle(v)       self.target_angle = v end

--- Returns the turret size class. @return string Size class.
function Turret:getSizeClass()          return self.size_class end
--- Sets the turret size class. @param v string Size class.
function Turret:setSizeClass(v)         self.size_class = v end

--- Returns true if this turret is destroyed. @return boolean Destroyed flag.
function Turret:isDestroyed()           return self.destroyed == true end
--- Sets the destroyed flag. @param v boolean Destroyed state.
function Turret:setDestroyed(v)         self.destroyed = v end

return M
