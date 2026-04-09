# Entity Showcase

Interactive chapter-by-chapter tour of every `luna.entity.Universe` method — spawn,
components, string tags, bitmap tags, layers, hierarchy, blueprints, systems, and cleanup.

## What It Demonstrates

- `luna.entity.newUniverse()` — create a Universe ECS container
- `world:spawn()` / `world:kill()` / `world:isAlive()` — entity lifecycle
- `world:getEntityCount()` / `world:getEntities()` — entity enumeration
- `world:set()` / `world:get()` / `world:has()` / `world:remove()` — component CRUD
- `world:getComponents()` — list all component names on an entity
- `world:query()` — multi-component archetype query returning matching entity IDs
- `world:each()` — iterate every entity that owns a named component
- `world:addTag()` / `world:hasTag()` / `world:getTags()` / `world:removeTag()` — string tags
- `world:getEntitiesByTag()` — reverse-lookup entities by string tag
- `world:defineTag()` / `world:bitmapTag()` / `world:hasBitmapTag()` / `world:bitmapUntag()` — bitmap tags
- `world:queryBitmapTag()` / `world:queryBitmapAny()` / `world:queryBitmapAll()` — fast bit queries
- `world:getBitmapTagBit()` — retrieve the bit index for a named bitmap tag
- `world:setLayer()` / `world:getLayer()` / `world:getEntitiesByLayer()` — render layers
- `world:getEntitiesSorted()` — all entities sorted by layer then ID
- `world:setParent()` / `world:getParent()` / `world:getChildren()` — parent-child hierarchy
- `world:killRecursive()` — destroy an entity and all its descendants
- `world:defineBlueprint()` / `world:extendBlueprint()` / `world:spawnBlueprint()` — blueprint templates
- `world:hasBlueprint()` / `world:listBlueprints()` / `world:getBlueprintComponents()` / `world:removeBlueprint()` — blueprint management
- `world:addSystem()` / `world:removeSystem()` / `world:getSystemCount()` — system registry
- `world:update()` / `world:draw()` — dispatch to registered systems
- `world:emit()` — broadcast a named event to all system handlers
- `world:clear()` / `world:release()` — universe cleanup

## How to Run

```bash
cargo run -- demos/showcase/entity_showcase
```

## Controls

| Key | Action |
|-----|--------|
| Space | Advance to the next chapter (wraps back to chapter 1 after chapter 7) |
| R | Reset universe and restart from chapter 1 |
| Escape | Quit |

## Notes

- Seven chapters cycle through every API group: Lifecycle & Components → String Tags → Bitmap Tags → Layers → Hierarchy → Blueprints → Systems & Cleanup
- Each chapter prints live API call results in the green log panel on-screen — no terminal output required
- The moving dot simulation is driven by a registered `MovementSystem`; `DrawSystem` reads `pos`/`col`/`sz` components
- Bitmap tag names (`HOSTILE`, `FAST`, `BOSS`) are pre-defined at reset so they are available in every chapter
