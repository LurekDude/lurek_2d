# ecs

## General Info

- Module group: `Feature Systems`
- Source path: `src/ecs/`
- Lua API path(s): `src/lua_api/ecs_api.rs`
- Primary Lua namespace: `lurek.ecs`
- Rust test path(s): tests/rust/unit/ecs_tests.rs
- Lua test path(s): tests/lua/unit/test_ecs_core_unit.lua

## Summary

The `ecs` module provides Lurek2D's Lua-first ECS runtime using a single `Universe` userdata (`lurek.ecs.newUniverse()`).

**Entity lifecycle.** Entities are packed generational IDs (24-bit slot + 8-bit generation). Slot reuse invalidates stale handles by generation mismatch. Core operations: `spawn`, `kill`, `killRecursive`, `isAlive`, `getEntities`, `getEntityCount`.

**Component storage and queries.** Components are Lua values stored per-entity in Lua registry tables. Core operations: `set/get/has/remove/getComponents`, `query`, `queryNot`, and `queryMulti` (batched callback with multiple component payloads in one pass).

**Tags and layers.** The module supports both string tags and bitmap tags (up to 63 named bits), plus numeric layering. Query helpers include `getEntitiesByTag`, `queryBitmapTag`, `queryBitmapAny`, `queryBitmapAll`, `getEntitiesByLayer`, and `getEntitiesSorted`.

**Blueprints and bulk spawning.** Blueprint APIs (`defineBlueprint`, `extendBlueprint`, `spawnBlueprint`, `spawnBulk`) provide reusable templates with deep-copy isolation and optional override tables.

**Hierarchy and directed relations.** `setParent/getParent/getChildren` define parent-child trees. `addRelation/getRelated/removeRelation/clearRelations/hasRelation` provide directed named graph links. `RelationshipManager` in `relationships.rs` provides separate symmetric numeric + level-based relations.

**System scheduling.** Systems are registered with optional `priority`, optional `phase`, optional stable `name`, and optional `after` dependency names. Built-in phase usage is `pre_update`, `update`, `post_update`, and `render`. Default-phase systems (no phase specified) run in both `update()` and `render()` for backward compatibility. Dispatch APIs: `update`, `updatePhase`, `render`, `emit`. Per-phase ordering is dependency-aware (topological by `after`) with priority as stable fallback.

**Change detection and snapshots.** Component writes/removals mark entities dirty (`getDirtyEntities`) until `flushObservers` drains events. World state can be persisted/restored through `serialize/deserialize` and aliases `snapshot/applySnapshot`. Incremental diffs are available through `takeSnapshotDiff` (Lua) / `take_snapshot_diff` (Rust) and report added/removed components, deleted entities, and dirty entities since the previous diff pull.

**Sparse query fast-path (opt-in).** Cargo feature `ecs-archetype` enables a sparse-set style component index (`component -> entity slots`) used to narrow candidates for `query`, `queryNot`, and `queryMulti` before table checks.

**Scope boundary.** Feature Systems tier. Depends on `runtime` for SharedState registration. Lua bridge in `src/lua_api/ecs_api.rs`.

## Files

- `generational_id.rs`: - Pack and unpack 24-bit slot + 8-bit generation into a single u32 entity id.
- `lua_table.rs`: - Deep-copy utility for Lua tables via mlua.
- `mod.rs`: Declares the ECS submodules and re-exports the main world and relationship types.
- `relationships.rs`: Defines reusable relationship types and the `RelationshipManager` for symmetric pairwise values and named relation levels.
- `universe.rs`: Defines `Universe` core state, lifecycle, component/tag/layer/system operations, plus phase ordering and sparse-index helpers.
- `universe_ext.rs`: Defines extension `impl Universe` blocks for query batching/filtering, bulk spawning, snapshot serialization, and restore logic.
- `universe_systems.rs`: Defines extracted system registration/removal/count and dependency-aware phase ordering logic.

## Types

- `GenerationalId` (`struct`, `generational_id.rs`): Stateless namespace for encoding and decoding packed entity identifiers.
- `RelationType` (`struct`, `relationships.rs`): The definition of one named relationship category and its allowed level strings.
- `Relationship` (`struct`, `relationships.rs`): The stored record for one normalized entity pair, including a numeric value and per-type named levels.
- `RelationshipManager` (`struct`, `relationships.rs`): A standalone manager for pairwise entity relationships that is separate from `Universe` but often complements ECS-driven gameplay.
- `SnapshotDiff` (`struct`, `universe.rs`): Incremental diff payload returned by `take_snapshot_diff`, containing added/removed component events, deleted entities, and dirty entities.
- `Universe` (`struct`, `universe.rs`): The main ECS world object that owns entity lifecycle, component storage, tags, layers, blueprints, parent-child links, and registered systems.

## Functions

- `GenerationalId::pack` (`generational_id.rs`): Packs a 24-bit slot and 8-bit generation into a single entity id.
- `GenerationalId::unpack_slot` (`generational_id.rs`): Extracts the slot index from a packed entity id.
- `GenerationalId::unpack_gen` (`generational_id.rs`): Extracts the generation byte from a packed entity id.
- `deep_copy_table` (`lua_table.rs`): Deep-copies a Lua table recursively.
- `RelationType::new` (`relationships.rs`): Creates a relationship type and coerces the default level to a valid entry when possible.
- `RelationType::has_level` (`relationships.rs`): Returns whether the supplied level label is valid for this relationship type.
- `RelationshipManager::new` (`relationships.rs`): Creates an empty relationship manager.
- `RelationshipManager::define_type` (`relationships.rs`): Registers or replaces a named relationship type definition.
- `RelationshipManager::remove_type` (`relationships.rs`): Removes a relationship type and clears its assigned levels from all relations.
- `RelationshipManager::get_type` (`relationships.rs`): Returns the relationship type definition for the given name.
- `RelationshipManager::type_names` (`relationships.rs`): Returns the set of registered relationship type names.
- `RelationshipManager::get_value` (`relationships.rs`): Returns the numeric relationship value for a pair, defaulting to zero.
- `RelationshipManager::set_value` (`relationships.rs`): Sets the numeric relationship value for a pair.
- `RelationshipManager::adjust_value` (`relationships.rs`): Adds a delta to the numeric relationship value for a pair.
- `RelationshipManager::set_level` (`relationships.rs`): Assigns a per-type level label to a relation when the type and level are valid.
- `RelationshipManager::get_level` (`relationships.rs`): Returns the explicit or default level label for a relation type on a pair.
- `RelationshipManager::has_relation` (`relationships.rs`): Returns whether any relation record exists for the pair.
- `RelationshipManager::remove_relation` (`relationships.rs`): Deletes the stored relation record for the pair.
- `RelationshipManager::all_relations_for` (`relationships.rs`): Returns all relationship records that involve the given entity id.
- `RelationshipManager::all_relations` (`relationships.rs`): Iterates over every stored pairwise relationship.
- `RelationshipManager::relation_count` (`relationships.rs`): Returns the total number of stored pairwise relationships.
- `RelationshipManager::add_link` (`relationships.rs`): Adds a directed named link from one entity to another without duplicates.
- `RelationshipManager::get_links` (`relationships.rs`): Returns the directed link targets for a source entity and link name.
- `RelationshipManager::remove_link` (`relationships.rs`): Removes one directed link target from a source entity and link name.
- `RelationshipManager::clear_links` (`relationships.rs`): Removes all directed link targets for a source entity and link name.
- `RelationshipManager::has_link` (`relationships.rs`): Returns whether a directed link target exists for the source entity and link name.
- `Universe::new` (`universe.rs`): Creates an empty universe with fresh stores and counters.
- `Universe::get_system_store` (`universe.rs`): Fetches the Lua system store table, failing if the universe is not initialized.
- `Universe::pack_id` (`universe.rs`): Packs a slot and generation into the public entity id format.
- `Universe::unpack_slot` (`universe.rs`): Extracts the slot portion from a packed entity id.
- `Universe::unpack_gen` (`universe.rs`): Extracts the generation portion from a packed entity id.
- `Universe::spawn` (`universe.rs`): Allocates a live entity id, reusing a recycled slot when available.
- `Universe::kill` (`universe.rs`): Deletes one entity, clears its stored state, and recycles its slot.
- `Universe::set_parent` (`universe.rs`): Reassigns the parent of an entity within the hierarchy graph.
- `Universe::get_parent` (`universe.rs`): Returns the packed parent id for an entity when one is assigned.
- `Universe::get_children` (`universe.rs`): Returns the live packed child ids for an entity.
- `Universe::kill_recursive` (`universe.rs`): Deletes an entity and every descendant reachable through the hierarchy.
- `Universe::is_alive` (`universe.rs`): Returns whether a packed entity id still refers to a live slot and generation.
- `Universe::get_entity_count` (`universe.rs`): Returns the number of live entities.
- `Universe::get_entities` (`universe.rs`): Returns all live entity ids in ascending order.
- `Universe::set_component` (`universe.rs`): Writes one component value into an entity row and records the change.
- `Universe::get_component` (`universe.rs`): Reads one component value from an entity row, yielding `nil` when absent.
- `Universe::has_component` (`universe.rs`): Returns whether an entity row contains a non-`nil` value for the component name.
- `Universe::remove_component` (`universe.rs`): Removes one component from an entity row and records the change when present.
- `Universe::get_component_names` (`universe.rs`): Lists the component names currently stored on an entity row.
- `Universe::query` (`universe.rs`): Returns entity ids whose rows contain every requested component name.
- `Universe::each` (`universe.rs`): Calls a Lua callback for each live entity that owns the named component.
- `Universe::add_tag` (`universe.rs`): Attaches a string tag to a live entity and updates the reverse index.
- `Universe::remove_tag` (`universe.rs`): Removes a string tag from an entity and the reverse tag index.
- `Universe::has_tag` (`universe.rs`): Returns whether an entity currently owns the given string tag.
- `Universe::get_tags` (`universe.rs`): Returns all string tags currently attached to an entity.
- `Universe::get_entities_by_tag` (`universe.rs`): Returns all live entities currently indexed under the given string tag.
- `Universe::iter_entities_by_tag` (`universe.rs`): Iterates over entity ids indexed under the given string tag.
- `Universe::define_tag` (`universe.rs`): Reserves and returns the bitmap bit position for a tag name.
- `Universe::bitmap_tag` (`universe.rs`): Sets one bitmap tag bit on a live entity.
- `Universe::bitmap_untag` (`universe.rs`): Clears one bitmap tag bit on an entity when the tag exists.
- `Universe::has_bitmap_tag` (`universe.rs`): Returns whether an entity currently has the named bitmap tag bit set.
- `Universe::query_bitmap_tag` (`universe.rs`): Returns live entities whose bitmap mask includes the named tag bit.
- `Universe::query_bitmap_any` (`universe.rs`): Returns live entities whose bitmap mask contains any requested tag bit.
- `Universe::query_bitmap_all` (`universe.rs`): Returns live entities whose bitmap mask contains every requested tag bit.
- `Universe::get_bitmap_tag_bit` (`universe.rs`): Returns the bit position assigned to a bitmap tag name.
- `Universe::set_layer` (`universe.rs`): Writes the layer value for a live entity.
- `Universe::get_layer` (`universe.rs`): Returns the stored layer value for an entity, defaulting to zero.
- `Universe::get_entities_by_layer` (`universe.rs`): Returns live entities whose stored layer equals the requested value.
- `Universe::get_entities_sorted` (`universe.rs`): Returns live entities sorted by layer and then by slot id.
- `Universe::define_blueprint` (`universe.rs`): Stores a blueprint template under a name after deep-copying its Lua table.
- `Universe::extend_blueprint` (`universe.rs`): Builds a child blueprint by copying a parent template and applying overrides.
- `Universe::spawn_blueprint` (`universe.rs`): Spawns an entity from a named blueprint and optional override table.
- `Universe::has_blueprint` (`universe.rs`): Returns whether a blueprint name is present in the blueprint store.
- `Universe::remove_blueprint` (`universe.rs`): Removes one named blueprint from the blueprint store.
- `Universe::list_blueprints` (`universe.rs`): Returns the names of all stored blueprints.
- `Universe::get_blueprint_components` (`universe.rs`): Returns a deep-copied Lua table containing one blueprint's component template.
- `Universe::clear` (`universe.rs`): Resets the universe to an empty state and clears its Lua-backed stores.
- `Universe::take_component_events` (`universe.rs`): Drains buffered component add and remove notifications.
- `Universe::get_dirty_entities` (`universe.rs`): Returns the sorted set of entities marked dirty by component changes.
- `Universe::take_snapshot_diff` (`universe.rs`): Drains buffered component and entity changes into a snapshot diff.
- `Universe::query_not` (`universe_ext.rs`): Returns entities that contain all required components and none of the excluded ones.
- `Universe::query_multi` (`universe_ext.rs`): Invokes a Lua callback with entity ids followed by multiple requested component values.
- `Universe::spawn_bulk` (`universe_ext.rs`): Spawns multiple entities from one blueprint, cloning the optional override table per spawn.
- `Universe::serialize_to_table` (`universe_ext.rs`): Serializes live entities, components, tags, layers, and hierarchy into a Lua snapshot table.
- `Universe::deserialize_from_table` (`universe_ext.rs`): Rebuilds universe state from a previously serialized Lua snapshot table.
- `Universe::add_system` (`universe_systems.rs`): Registers a system table together with its priority, phase, name, and dependencies.
- `Universe::get_sorted_system_indices_all` (`universe_systems.rs`): Returns all registered system indices sorted by ascending priority.
- `Universe::get_sorted_system_indices_for_phase` (`universe_systems.rs`): Returns phase-matching system indices sorted by priority and dependency order.
- `Universe::remove_system` (`universe_systems.rs`): Removes a previously registered system table and its metadata entry.
- `Universe::get_system_count` (`universe_systems.rs`): Returns the number of registered systems currently stored in Lua.

## Lua API Reference

- Binding path(s): `src/lua_api/ecs_api.rs`
- Namespace: `lurek.ecs`

### Module Functions
- `lurek.ecs.newUniverse`: Creates an empty ECS universe for entity, component, system, and relationship management.

### `LUniverse` Methods
- `LUniverse:spawn`: Creates a new entity in this universe.
- `LUniverse:kill`: Deletes an entity and removes its components from this universe.
- `LUniverse:isAlive`: Returns whether an entity id currently exists in this universe.
- `LUniverse:set`: Stores or replaces a component value on an entity.
- `LUniverse:get`: Returns a component value from an entity.
- `LUniverse:has`: Returns whether an entity has a named component.
- `LUniverse:remove`: Removes a named component from an entity.
- `LUniverse:getComponents`: Returns component names currently stored on an entity.
- `LUniverse:query`: Returns entities that have all component names passed as varargs.
- `LUniverse:each`: Iterates entities with one component and calls a Lua callback for each match.
- `LUniverse:getEntities`: Returns all live entity ids in this universe.
- `LUniverse:getEntityCount`: Returns the number of live entities in this universe.
- `LUniverse:addSystem`: Registers a Lua system table with optional phase, priority, name, and dependency metadata.
- `LUniverse:removeSystem`: Removes a previously registered Lua system table.
- `LUniverse:update`: Runs registered update-phase systems with a frame delta.
- `LUniverse:render`: Runs registered render-phase systems using their render or draw callbacks.
- `LUniverse:emit`: Calls matching event-named functions on registered systems.
- `LUniverse:getSystemCount`: Returns the number of registered systems.
- `LUniverse:updatePhase`: Runs registered systems assigned to a named phase.
- `LUniverse:getDirtyEntities`: Returns entities marked dirty by recent ECS mutations.
- `LUniverse:queryMulti`: Iterates entities that have all component names from a table.
- `LUniverse:snapshot`: Serializes this universe into a Lua table snapshot.
- `LUniverse:applySnapshot`: Replaces this universe state from a Lua table snapshot.
- `LUniverse:takeSnapshotDiff`: Returns and clears accumulated ECS snapshot diff data.
- `LUniverse:clear`: Clears all entities, components, systems, and ECS state from this universe.
- `LUniverse:release`: Releases universe contents by clearing all ECS state.
- `LUniverse:addTag`: Adds a string tag to an entity.
- `LUniverse:removeTag`: Removes a string tag from an entity.
- `LUniverse:hasTag`: Returns whether an entity has a string tag.
- `LUniverse:getTags`: Returns string tags assigned to an entity.
- `LUniverse:getEntitiesByTag`: Returns entities that have a string tag.
- `LUniverse:setLayer`: Assigns a numeric layer to an entity.
- `LUniverse:getLayer`: Returns the numeric layer assigned to an entity.
- `LUniverse:getEntitiesByLayer`: Returns entities assigned to a numeric layer.
- `LUniverse:getEntitiesSorted`: Returns live entities sorted by ECS layer and stable entity ordering.
- `LUniverse:defineTag`: Defines a bitmap tag name and assigns it a bit slot.
- `LUniverse:bitmapTag`: Adds a bitmap tag to an entity, defining the tag if needed.
- `LUniverse:bitmapUntag`: Removes a bitmap tag from an entity.
- `LUniverse:hasBitmapTag`: Returns whether an entity has a bitmap tag.
- `LUniverse:queryBitmapTag`: Returns entities with one bitmap tag.
- `LUniverse:queryBitmapAny`: Returns entities with at least one bitmap tag from a list.
- `LUniverse:queryBitmapAll`: Returns entities that have every bitmap tag from a list.
- `LUniverse:getBitmapTagBit`: Returns the bit index assigned to a bitmap tag name.
- `LUniverse:defineBlueprint`: Defines a named entity blueprint from a component table.
- `LUniverse:extendBlueprint`: Defines a blueprint that inherits from a parent blueprint and applies overrides.
- `LUniverse:spawnBlueprint`: Spawns an entity from a named blueprint with optional component overrides.
- `LUniverse:hasBlueprint`: Returns whether a named blueprint exists.
- `LUniverse:removeBlueprint`: Removes a named blueprint from this universe.
- `LUniverse:listBlueprints`: Returns names of all registered blueprints.
- `LUniverse:getBlueprintComponents`: Returns the component table stored for a blueprint.
- `LUniverse:setParent`: Sets or clears the parent entity for a child entity.
- `LUniverse:getParent`: Returns the parent entity id for a child entity.
- `LUniverse:getChildren`: Returns child entity ids for a parent entity.
- `LUniverse:killRecursive`: Deletes an entity and all descendant entities in its hierarchy.
- `LUniverse:queryNot`: Returns entities that include one component set and exclude another component set.
- `LUniverse:serialize`: Serializes this universe into a Lua table snapshot.
- `LUniverse:deserialize`: Replaces this universe state from a serialized Lua snapshot.
- `LUniverse:onComponentAdded`: Registers a callback for queued component-add events with a given component name.
- `LUniverse:onComponentRemoved`: Registers a callback for queued component-remove events with a given component name.
- `LUniverse:flushObservers`: Delivers queued component add and remove events to registered observer callbacks.
- `LUniverse:spawnBulk`: Spawns multiple entities from a blueprint using shared optional overrides.
- `LUniverse:addRelation`: Adds a named directed relation from one entity to another.
- `LUniverse:getRelated`: Returns targets linked from an entity by a named relation.
- `LUniverse:removeRelation`: Removes a named directed relation between two entities.
- `LUniverse:clearRelations`: Removes every target for one named relation from an entity.
- `LUniverse:hasRelation`: Returns whether a named directed relation exists between two entities.
- `LUniverse:type`: Returns the Lua-visible type name for this universe handle.
- `LUniverse:typeOf`: Returns whether this universe handle matches a supported type name.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/ecs/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
