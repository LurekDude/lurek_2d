--- Luna2D combat system — vehicle combat, chassis, turrets, and projectiles.
--
-- Stub module. Full implementation pending.
-- Replaces the former `luna.combat` Rust binding.
-- All physics integration is done through `luna.physics`.
--
-- @module library.combat
-- @status stub

local M = {}

--- Create a new combat world to manage all combat entities.
-- @treturn table CombatWorld object.
function M.newWorld()
    error("library.combat: not yet implemented — stub only")
end

--- Create a chassis (vehicle body) definition.
-- @param id string Unique chassis identifier.
-- @param def table { max_hp, armor, speed, turn_rate }
-- @treturn table ChassisDef.
function M.newChassis(id, def)
    error("library.combat: not yet implemented — stub only")
end

--- Create a turret definition.
-- @param id string Unique turret identifier.
-- @param def table { damage, fire_rate, range, turn_rate }
-- @treturn table TurretDef.
function M.newTurret(id, def)
    error("library.combat: not yet implemented — stub only")
end

--- Create a projectile pool for pre-allocated projectile management.
-- @param capacity number Maximum simultaneous projectiles.
-- @treturn table ProjectilePool object.
function M.newProjectilePool(capacity)
    error("library.combat: not yet implemented — stub only")
end

return M
