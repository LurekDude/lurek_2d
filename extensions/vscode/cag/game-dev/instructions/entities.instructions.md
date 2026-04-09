---
applyTo: "**/entities/*.lua"
---
# Entity Module Rules
- Every entity file exports one table: the entity class/factory
- Constructor pattern: Entity.new(params) → setmetatable({}, Entity)
- Required methods: :update(dt), :draw()
- Optional: :destroy(), :onCollision(other), :serialize()
- Entity state is never stored in global — always instance fields
- Entities communicate via Event Bus, not direct references
