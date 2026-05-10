# False-Positive Snapshot

Date: 2026-05-09
Source: logs/data/lua_api_test_coverage.json

## Summary

- orphaned @covers markers: 140
- unresolved describe targets: 82
- primary impact: describe gate is low (3.8%), strict marker gate is high (99.3%)

## Sample orphaned @covers markers (top 20)

- tests/lua/unit/test_battle_core_unit.lua:8 -> lurek.turnbattle
- tests/lua/unit/test_battle_core_unit.lua:17 -> lurek.turnbattle
- tests/lua/unit/test_battle_core_unit.lua:25 -> LCombatant:getName
- tests/lua/unit/test_battle_core_unit.lua:26 -> LCombatant:isAlive
- tests/lua/unit/test_battle_core_unit.lua:27 -> lurek.turnbattle.newCombatant
- tests/lua/unit/test_battle_core_unit.lua:38 -> LBattle:addCombatant
- tests/lua/unit/test_battle_core_unit.lua:39 -> LBattle:attack
- tests/lua/unit/test_battle_core_unit.lua:40 -> LCombatant:addAction
- tests/lua/unit/test_battle_core_unit.lua:41 -> LCombatant:setHp
- tests/lua/unit/test_battle_core_unit.lua:42 -> LCombatant:setMaxHp
- tests/lua/unit/test_battle_core_unit.lua:43 -> LCombatant:setTeam
- tests/lua/unit/test_battle_core_unit.lua:44 -> LTurnAction:setAccuracy
- tests/lua/unit/test_battle_core_unit.lua:45 -> LTurnAction:setBaseDamage
- tests/lua/unit/test_battle_core_unit.lua:46 -> lurek.turnbattle.newAction
- tests/lua/unit/test_battle_core_unit.lua:47 -> lurek.turnbattle.newBattle
- tests/lua/unit/test_battle_core_unit.lua:48 -> lurek.turnbattle.newCombatant
- tests/lua/unit/test_collision_core_unit.lua:9 -> lurek.collision
- tests/lua/unit/test_crafting_core_unit.lua:24 -> C.newRecipe
- tests/lua/unit/test_crafting_core_unit.lua:34 -> C.newIngredient
- tests/lua/unit/test_crafting_core_unit.lua:42 -> C.newIngredient

## Sample unresolved describe(...) targets (top 20)

- tests/lua/unit/test_audio_core_unit.lua:113 -> audio.newDecoder
- tests/lua/unit/test_audio_core_unit.lua:220 -> audio.newQueueableSource
- tests/lua/unit/test_audio_core_unit.lua:1692 -> Pool:play
- tests/lua/unit/test_audio_core_unit.lua:1728 -> Pool:stopAll
- tests/lua/unit/test_audio_core_unit.lua:1748 -> Pool:setVolume
- tests/lua/unit/test_audio_core_unit.lua:1758 -> Pool:setBus
- tests/lua/unit/test_audio_core_unit.lua:1778 -> Pool:release
- tests/lua/unit/test_audio_core_unit.lua:1790 -> Pool:getVoiceCount
- tests/lua/unit/test_battle_core_unit.lua:7 -> lurek.turnbattle
- tests/lua/unit/test_battle_core_unit.lua:24 -> lurek.turnbattle.newCombatant
- tests/lua/unit/test_battle_core_unit.lua:37 -> lurek.turnbattle.newBattle
- tests/lua/unit/test_data_core_unit.lua:137 -> data.getPackedSize
- tests/lua/unit/test_data_core_unit.lua:185 -> data.newDataView
- tests/lua/unit/test_data_core_unit.lua:424 -> data.hash
- tests/lua/unit/test_data_core_unit.lua:473 -> data.newByteData
- tests/lua/unit/test_data_core_unit.lua:760 -> data.msgpack
- tests/lua/unit/test_docs_api_unit.lua:52 -> lurek.test.foo
- tests/lua/unit/test_docs_api_unit.lua:64 -> lurek.test.bar
- tests/lua/unit/test_docs_api_unit.lua:80 -> lurek.test.func
- tests/lua/unit/test_docs_api_unit.lua:103 -> lurek.test.func2
