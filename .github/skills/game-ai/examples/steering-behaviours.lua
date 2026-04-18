local enemy = world:newAgent("enemy", x, y)
local sm    = enemy:useSteering()

-- Add behaviours (weight, enabled)
sm:seek(targetX, targetY, 1.0)       -- move toward target
sm:arrive(targetX, targetY, 1.0, 40) -- decelerate as it gets close (radius=40)
sm:wander(0.5)                        -- random drift
sm:flee(dangerX, dangerY, 0.8)       -- run away from a point
sm:evade(pursuerAgent, 0.9)          -- predict and flee a moving agent
sm:pursue(preyAgent, 1.0)            -- predict and intercept a moving agent
sm:flock({buddy1, buddy2}, 0.6)      -- separation+cohesion+alignment

-- Combination mode
sm:setCombineMode("weighted")   -- sum all weighted forces (default)
sm:setCombineMode("priority")   -- use first non-zero force (for override behaviour)

-- Apply per-frame
function lurek.process(dt)
    world:update(dt)
    -- agent position updated automatically by SteeringManager
end
