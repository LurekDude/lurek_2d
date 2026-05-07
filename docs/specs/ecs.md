# ecs

## General Info

- Module group: `Feature Systems`
- Source path: `src/ecs/`
- Lua API path(s): `src/lua_api/ecs_api.rs`
- Primary Lua namespace: `lurek.ecs`
- Rust test path(s): none found under tests/ with ecs in the path
- Lua test path(s): none found under tests/ with ecs in the path

## Summary

The `ecs` module provides Lurek2D's Entity-Component-System infrastructure — a Feature Systems tier module that separates identity (entities), data (components), and behaviour (systems) so that game objects can mix and modify their capabilities at runtime without subclassing.

**Entity lifecycle.** Entities are lightweight integer IDs managed by `Universe`. The universe holds a generation counter per ID slot: when an entity is despawned and its slot reused, any stale `EntityId` referencing the old generation is silently invalid. Core operations: `spawn()` -> `EntityId`, `despawn(id)`, `is_alive(id) -> bool`. Free slots are tracked via a free-list for O(1) allocation.

**Component storage.** The `ComponentStore` inside `Universe` uses a `TypeId`-keyed map of boxed trait objects, where each entry is a `HashMap<EntityId, Box<dyn Any + Send + Sync>>`. This is deliberately a simple, hash-map-backed design rather than an archetypal or sparse-set layout: the engine targets desktop hardware with scripted game logic rather than millions of entities per frame, so the flexibility and simplicity of dynamic dispatch is worth the hash-lookup cost. Key operations: `add_component::<T>(entity, value)`, `get_component::<T>(entity) -> Option<&T>`, `get_component_mut::<T>(entity) -> Option<&mut T>`, `remove_component::<T>(entity)`, `query::<T>()` (iterate all entities with component T).

**Tags and layers.** Entities can have string tags and an integer layer mask. Tags: `add_tag(entity, tag)`, `remove_tag(entity, tag)`, `has_tag(entity, tag)`, `entities_with_tag(tag)`. Layers: `set_layer(entity, mask)`, `get_layer(entity)`, `entities_in_layer(mask)`. Extended query predicates allow narrowing entity sets by tag intersection, component presence, and layer mask simultaneously, reducing boilerplate for common game-loop queries like all visible enemies with a health component.

**Blueprints.** A `Blueprint` is a reusable entity template: `define_blueprint(name, components)` registers a component set by name; `spawn_blueprint(name)` instantiates a new entity from it. This is the Lua-friendly factory pattern for common entity archetypes (enemies, projectiles, pickups).

**Parent-child hierarchies.** `relationships.rs` adds full parent-child hierarchies to `Universe`: `set_parent(child, parent)`, `get_parent(child)`, `get_children(parent)`, `get_descendants(parent)`, `detach(child)`. Used by `scene` for transform propagation and by Lua scripts building entity groups. Destroying a parent optionally despawns all descendants.

**RelationshipManager.** A separate `RelationshipManager` (distinct from the hierarchy) manages symmetric pairwise entity relationships with a numeric value and optional named levels. Used for NPC relationship/reputation systems: `define_type(name, levels)`, `set_value(a, b, v)`, `adjust_value(a, b, delta)`, `set_level(a, b, type, level)`, `get_level(a, b, type)`, `all_relations_for(entity)`. Also supports directed named links: `add_link(from, to, name)` / `get_links(from, name)` / `remove_link`, a lightweight alternative to the full AI blackboard for simple graph-based game state.

**Systems.** Registered systems are Lua callbacks (or Rust closures) tagged with a priority and run in order each frame: `register_system(name, priority, callback)`, `unregister_system(name)`, `run_systems(dt)`. This keeps the ECS update loop decoupled from the game script structure.

**Lua surface.** `lurek.ecs.spawn()` returns entity id. `lurek.ecs.despawn(id)`, `lurek.ecs.isAlive(id)`. `lurek.ecs.addComponent(id, type, data)`, `getComponent(id, type)`, `removeComponent(id, type)`. `lurek.ecs.query(type)` returns list. `lurek.ecs.addTag/removeTag/hasTag/withTag`. `lurek.ecs.setLayer/getLayer/inLayer`. `lurek.ecs.setParent/getParent/getChildren/detach`. `lurek.ecs.defineBlueprint/spawnBlueprint`. `lurek.ecs.registerSystem/unregisterSystem`. `lurek.ecs.newRelationships()` returns `RelationshipManager` userdata with full type/level/link API.

**Scope boundary.** Feature Systems tier. Depends on `runtime` for SharedState registration. Lua bridge in `src/lua_api/ecs_api.rs`.

## Files

- `mod.rs`: Declares the ECS submodules and re-exports the main world and relationship types.
- `relationships.rs`: Defines reusable relationship types and the `RelationshipManager` for symmetric pairwise values and named relation levels.
- `universe.rs`: Defines `Universe`, including generational entity IDs, component storage via Lua registry tables, tags, layers, blueprints, hierarchy management, and ordered system dispatch.

## Types

- `RelationType` (`struct`, `relationships.rs`): The definition of one named relationship category and its allowed level strings.
- `Relationship` (`struct`, `relationships.rs`): The stored record for one normalized entity pair, including a numeric value and per-type named levels.
- `RelationshipManager` (`struct`, `relationships.rs`): A standalone manager for pairwise entity relationships that is separate from `Universe` but often complements ECS-driven gameplay.
- `Universe` (`struct`, `universe.rs`): The main ECS world object that owns entity lifecycle, component storage, tags, layers, blueprints, parent-child links, and registered systems.

## Functions

- `RelationType::new` (`relationships.rs`): Create a new relation type.
- `RelationType::has_level` (`relationships.rs`): Return `true` if `level` is a valid level for this type.
- `RelationshipManager::new` (`relationships.rs`): Create a new empty manager.
- `RelationshipManager::define_type` (`relationships.rs`): Define a named relation type with a set of valid levels.
- `RelationshipManager::remove_type` (`relationships.rs`): Remove a relation type.
- `RelationshipManager::get_type` (`relationships.rs`): Get a reference to a relation type definition.
- `RelationshipManager::type_names` (`relationships.rs`): Get the names of all defined relation types.
- `RelationshipManager::get_value` (`relationships.rs`): Get the numeric relation value between two entities.
- `RelationshipManager::set_value` (`relationships.rs`): Set the numeric relation value between two entities.
- `RelationshipManager::adjust_value` (`relationships.rs`): Adjust the numeric relation value by `delta`.
- `RelationshipManager::set_level` (`relationships.rs`): Set the named level for a relation type between two entities.
- `RelationshipManager::get_level` (`relationships.rs`): Get the level for a relation type between two entities.
- `RelationshipManager::has_relation` (`relationships.rs`): Return `true` if a relationship record exists for this pair.
- `RelationshipManager::remove_relation` (`relationships.rs`): Remove a relationship record.
- `RelationshipManager::all_relations_for` (`relationships.rs`): Get all relationships involving a given entity.
- `RelationshipManager::all_relations` (`relationships.rs`): Get all relationships as an iterator.
- `RelationshipManager::relation_count` (`relationships.rs`): Get the total number of relationship records.
- `RelationshipManager::add_link` (`relationships.rs`): Add a directed named link from `from` to `to`.
- `RelationshipManager::get_links` (`relationships.rs`): Return all targets reachable from `from` via the named directed link.
- `RelationshipManager::remove_link` (`relationships.rs`): Remove the directed link from `from` to `to`.
- `RelationshipManager::clear_links` (`relationships.rs`): Remove all directed links of the given name originating from `from`.
- `RelationshipManager::has_link` (`relationships.rs`): Return `true` if a directed link from `from` to `to` via `name` exists.
- `Universe::new` (`universe.rs`): Creates a new empty Universe.
- `Universe::get_system_store` (`universe.rs`): get_system_store.
- `Universe::pack_id` (`universe.rs`): Packs a slot and generation counter into a single entity ID.
- `Universe::unpack_slot` (`universe.rs`): Extracts the slot index from a packed entity ID.
- `Universe::unpack_gen` (`universe.rs`): Extracts the generation counter from a packed entity ID.
- `Universe::spawn` (`universe.rs`): Spawns a new entity and returns its ID.
- `Universe::kill` (`universe.rs`): Kills an entity, cleaning up all associated data and recycling the ID.
- `Universe::set_parent` (`universe.rs`): Sets or clears the parent of `entity`.
- `Universe::get_parent` (`universe.rs`): Returns the parent of `entity`, or `None` if unparented.
- `Universe::get_children` (`universe.rs`): Returns the direct children of `entity`.
- `Universe::kill_recursive` (`universe.rs`): Kills `root` and all of its descendants recursively.
- `Universe::is_alive` (`universe.rs`): Returns whether an entity ID is currently alive.
- `Universe::get_entity_count` (`universe.rs`): Returns the number of alive entities.
- `Universe::get_entities` (`universe.rs`): Returns all alive entity IDs (unordered).
- `Universe::set_component` (`universe.rs`): Sets a component value on an entity.
- `Universe::get_component` (`universe.rs`): Gets a component value from an entity (returns Nil if missing or dead).
- `Universe::has_component` (`universe.rs`): Returns whether an entity has a named component.
- `Universe::remove_component` (`universe.rs`): Removes a component from an entity.
- `Universe::get_component_names` (`universe.rs`): Returns all component names for an entity.
- `Universe::query` (`universe.rs`): Returns all alive entities that have ALL listed component names.
- `Universe::each` (`universe.rs`): Calls `callback(id, value)` for every alive entity that has the named component.
- `Universe::add_tag` (`universe.rs`): Adds a string tag to an entity (no-op if already present or entity is dead).
- `Universe::remove_tag` (`universe.rs`): Removes a string tag from an entity.
- `Universe::has_tag` (`universe.rs`): Returns whether an entity has a specific string tag.
- `Universe::get_tags` (`universe.rs`): Returns all string tags for an entity.
- `Universe::get_entities_by_tag` (`universe.rs`): Returns all alive entities that have the given string tag.
- `Universe::define_tag` (`universe.rs`): Defines a bitmap tag name, returning its bit index.
- `Universe::bitmap_tag` (`universe.rs`): Adds a bitmap tag to an entity (auto-defines the tag if needed).
- `Universe::bitmap_untag` (`universe.rs`): Removes a bitmap tag from an entity.
- `Universe::has_bitmap_tag` (`universe.rs`): Returns whether an entity has a specific bitmap tag.
- `Universe::query_bitmap_tag` (`universe.rs`): Returns all alive entities with the given bitmap tag.
- `Universe::query_bitmap_any` (`universe.rs`): Returns all alive entities that have ANY of the listed bitmap tags.
- `Universe::query_bitmap_all` (`universe.rs`): Returns all alive entities that have ALL of the listed bitmap tags.
- `Universe::get_bitmap_tag_bit` (`universe.rs`): Returns the bit index for a bitmap tag name, if defined.
- `Universe::set_layer` (`universe.rs`): Sets the layer for an entity (default layer is 0).
- `Universe::get_layer` (`universe.rs`): Returns the layer for an entity (defaults to 0).
- `Universe::get_entities_by_layer` (`universe.rs`): Returns all alive entities on a specific layer.
- `Universe::get_entities_sorted` (`universe.rs`): Returns all alive entities sorted by layer (ascending), then by ID.
- `Universe::define_blueprint` (`universe.rs`): Defines a blueprint by deep-copying the given component table.
- `Universe::extend_blueprint` (`universe.rs`): Defines a blueprint by extending a parent blueprint with overrides.
- `Universe::spawn_blueprint` (`universe.rs`): Spawns an entity from a blueprint, applying optional overrides.
- `Universe::has_blueprint` (`universe.rs`): Returns whether a blueprint with the given name exists.
- `Universe::remove_blueprint` (`universe.rs`): Removes a blueprint definition.
- `Universe::list_blueprints` (`universe.rs`): Lists all defined blueprint names.
- `Universe::get_blueprint_components` (`universe.rs`): Returns a deep copy of a blueprint's component table, or Nil if not found.
- `Universe::add_system` (`universe.rs`): Adds a system (Lua table) to the system list at the given priority (lower = first).
- `Universe::get_sorted_system_indices` (`universe.rs`): Returns 1-based system store indices sorted by ascending priority.
- `Universe::remove_system` (`universe.rs`): Removes a system by pointer identity from the system list.
- `Universe::get_system_count` (`universe.rs`): Returns the number of registered systems.
- `Universe::clear` (`universe.rs`): Clears all entities, components, tags, layers, and systems.
- `Universe::take_component_events` (`universe.rs`): Takes and clears all pending component-add and component-remove events.
- `Universe::query_not` (`universe.rs`): Returns alive entities that have ALL `with` components and NONE of the `without` components.
- `Universe::spawn_bulk` (`universe.rs`): Spawns `count` entities from a blueprint, applying the same optional overrides to each.
- `Universe::serialize_to_table` (`universe.rs`): Serializes all alive entities to a Lua table snapshot.
- `Universe::deserialize_from_table` (`universe.rs`): Restores entity state from a snapshot produced by `serialize_to_table`.
- `deep_copy_table` (`universe.rs`): Deep-copies a Lua table recursively.

## Lua API Reference

- Binding path(s): `src/lua_api/ecs_api.rs`
- Namespace: `lurek.ecs`

### Module Functions
- `lurek.ecs.newUniverse`: Creates a new empty ECS universe.

### `LUniverse` Methods
- `LUniverse:spawn`: Creates a new entity and returns its packed ID.
- `LUniverse:kill`: Destroys the entity with the given ID, freeing its slot for reuse.
- `LUniverse:isAlive`: Returns true if the entity ID is currently alive.
- `LUniverse:set`: Sets a component value on an entity.
- `LUniverse:get`: Returns the component value for an entity, or nil if missing.
- `LUniverse:has`: Returns true if the entity has the named component.
- `LUniverse:remove`: Removes a component from an entity.
- `LUniverse:getComponents`: Returns all component names for an entity.
- `LUniverse:query`: Returns entity IDs that have all listed component names.
- `LUniverse:each`: Calls callback(id, value) for every entity with the named component.
- `LUniverse:getEntities`: Returns all alive entity IDs.
- `LUniverse:getEntityCount`: Returns the number of alive entities.
- `LUniverse:addSystem`: Adds a system table to the universe with an optional priority (lower = earlier).
- `LUniverse:removeSystem`: Removes a system table from the universe.
- `LUniverse:update`: Calls update(system, world, dt) on each registered system in priority order.
- `LUniverse:render`: Calls render(system, world) on each system in priority order and falls back to draw(system, world).
- `LUniverse:emit`: Emits a named event to all systems that implement the handler, in priority order.
- `LUniverse:getSystemCount`: Returns the number of registered systems.
- `LUniverse:clear`: Removes all entities, components, tags, layers, and systems. Blueprints are preserved.
- `LUniverse:release`: Releases all universe state, equivalent to clear.
- `LUniverse:addTag`: Attaches a string tag to an entity.
- `LUniverse:removeTag`: Removes a string tag from an entity.
- `LUniverse:hasTag`: Returns true if the entity carries the given tag.
- `LUniverse:getTags`: Returns all string tags for an entity.
- `LUniverse:getEntitiesByTag`: Returns all alive entities with the given string tag.
- `LUniverse:setLayer`: Sets the layer for an entity.
- `LUniverse:getLayer`: Returns the layer for an entity, defaulting to zero.
- `LUniverse:getEntitiesByLayer`: Returns all alive entities on a specific layer.
- `LUniverse:getEntitiesSorted`: Returns all alive entities sorted by layer then ID.
- `LUniverse:defineTag`: Defines a bitmap tag name, returning its bit index.
- `LUniverse:bitmapTag`: Adds a bitmap tag to an entity.
- `LUniverse:bitmapUntag`: Removes a bitmap tag from an entity.
- `LUniverse:hasBitmapTag`: Returns true if the entity has the given bitmap tag.
- `LUniverse:queryBitmapTag`: Returns all alive entities with the given bitmap tag.
- `LUniverse:queryBitmapAny`: Returns all alive entities with any of the listed bitmap tags.
- `LUniverse:queryBitmapAll`: Returns all alive entities with all of the listed bitmap tags.
- `LUniverse:getBitmapTagBit`: Returns the bit index for a bitmap tag name, or nil if undefined.
- `LUniverse:defineBlueprint`: Defines a blueprint from a component table.
- `LUniverse:extendBlueprint`: Defines a blueprint by extending a parent with overrides.
- `LUniverse:spawnBlueprint`: Spawns an entity from a blueprint with optional overrides.
- `LUniverse:hasBlueprint`: Returns true if a blueprint with the given name exists.
- `LUniverse:removeBlueprint`: Removes a blueprint definition.
- `LUniverse:listBlueprints`: Returns all defined blueprint names.
- `LUniverse:getBlueprintComponents`: Returns a deep copy of a blueprint's component table, or nil.
- `LUniverse:setParent`: Sets or clears the parent of an entity.
- `LUniverse:getParent`: Returns the parent entity ID, or nil if unparented.
- `LUniverse:getChildren`: Returns all direct child entity IDs.
- `LUniverse:killRecursive`: Kills an entity and all its descendants recursively.
- `LUniverse:queryNot`: Returns entity IDs that have all `with` components and none of the `without` components.
- `LUniverse:serialize`: Serializes all alive entities to a Lua table snapshot.
- `LUniverse:deserialize`: Restores entity state from a snapshot produced by serialize() while preserving blueprints and systems.
- `LUniverse:onComponentAdded`: Registers a callback for component-added events that is dispatched by flushObservers().
- `LUniverse:onComponentRemoved`: Registers a callback for component-removed events that is dispatched by flushObservers().
- `LUniverse:flushObservers`: Dispatches all pending component-add and component-remove events to registered callbacks.
- `LUniverse:spawnBulk`: Spawns `count` entities from a blueprint, returns an array of entity IDs.
- `LUniverse:addRelation`: Adds a directed named relationship from entity `from` to entity `to`, ignoring duplicates.
- `LUniverse:getRelated`: Returns all entity IDs reachable from `from` via the named relationship.
- `LUniverse:removeRelation`: Removes the directed named relationship from entity `from` to entity `to`.
- `LUniverse:clearRelations`: Removes all directed named relationships of type `name` from entity `from`.
- `LUniverse:hasRelation`: Returns true if a directed named relationship from `from` to `to` exists.
- `LUniverse:type`: Returns the type name of this object.
- `LUniverse:typeOf`: Returns true if this object is of the given type.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/ecs/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
