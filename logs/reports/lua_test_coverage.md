# Lua API Test Coverage Report

**Generated**: 2026-04-25
**Mode**: hybrid
**Total API functions**: 4067

## Summary

| Metric | Value |
|--------|-------|
| Marker-covered | 477 |
| Heuristic-covered | 3534 |
| Total covered | 4011 |
| Coverage | 98.6% |

## Per-Module Coverage

| Module | Total | Marker | Heuristic | Covered | Coverage |
|--------|-------|--------|-----------|---------|----------|
| raycaster | 59 | 13 | 42 | 55 | 93.2% |
| patterns | 170 | 22 | 140 | 162 | 95.3% |
| system | 26 | 5 | 20 | 25 | 96.2% |
| dataframe | 116 | 7 | 105 | 112 | 96.6% |
| i18n | 31 | 0 | 30 | 30 | 96.8% |
| pipeline | 62 | 0 | 60 | 60 | 96.8% |
| thread | 37 | 2 | 34 | 36 | 97.3% |
| ai | 292 | 6 | 279 | 285 | 97.6% |
| terminal | 83 | 0 | 81 | 81 | 97.6% |
| render | 175 | 13 | 158 | 171 | 97.7% |
| mods | 47 | 0 | 46 | 46 | 97.9% |
| physics | 193 | 29 | 160 | 189 | 97.9% |
| particle | 98 | 14 | 82 | 96 | 98.0% |
| devtools | 54 | 34 | 19 | 53 | 98.1% |
| effect | 158 | 7 | 148 | 155 | 98.1% |
| ecs | 61 | 7 | 53 | 60 | 98.4% |
| graph | 126 | 8 | 116 | 124 | 98.4% |
| math | 220 | 64 | 153 | 217 | 98.6% |
| compute | 77 | 17 | 59 | 76 | 98.7% |
| tilemap | 168 | 12 | 154 | 166 | 98.8% |
| pathfind | 90 | 8 | 81 | 89 | 98.9% |
| audio | 215 | 23 | 191 | 214 | 99.5% |
| animation | 53 | 10 | 43 | 53 | 100.0% |
| automation | 28 | 0 | 28 | 28 | 100.0% |
| camera | 47 | 4 | 43 | 47 | 100.0% |
| data | 62 | 10 | 52 | 62 | 100.0% |
| debugbridge | 14 | 14 | 0 | 14 | 100.0% |
| docs | 75 | 12 | 63 | 75 | 100.0% |
| engine | 10 | 1 | 9 | 10 | 100.0% |
| event | 26 | 4 | 22 | 26 | 100.0% |
| filesystem | 54 | 5 | 49 | 54 | 100.0% |
| globe | 53 | 5 | 48 | 53 | 100.0% |
| image | 80 | 39 | 41 | 80 | 100.0% |
| input | 81 | 0 | 81 | 81 | 100.0% |
| light | 86 | 1 | 85 | 86 | 100.0% |
| log | 18 | 0 | 18 | 18 | 100.0% |
| minimap | 76 | 7 | 69 | 76 | 100.0% |
| network | 47 | 2 | 45 | 47 | 100.0% |
| parallax | 44 | 2 | 42 | 44 | 100.0% |
| procgen | 18 | 2 | 16 | 18 | 100.0% |
| save | 26 | 5 | 21 | 26 | 100.0% |
| scene | 53 | 5 | 48 | 53 | 100.0% |
| serial | 10 | 2 | 8 | 10 | 100.0% |
| spine | 30 | 10 | 20 | 30 | 100.0% |
| sprite | 20 | 0 | 20 | 20 | 100.0% |
| timer | 47 | 4 | 43 | 47 | 100.0% |
| tween | 35 | 7 | 28 | 35 | 100.0% |
| ui | 366 | 30 | 336 | 366 | 100.0% |
| window | 50 | 5 | 45 | 50 | 100.0% |

## Uncovered Functions (lowest coverage first)

### raycaster (93.2%)

- `Raycaster:drawView` (method)
- `Raycaster:drawDepthMap` (method)
- `Raycaster:drawLineOfSight` (method)
- `Raycaster:drawCameraSweep` (method)

### patterns (95.3%)

- `Queue:len` (method)
- `List:add` (method)
- `List:get` (method)
- `List:set` (method)
- `List:len` (method)
- `Set:add` (method)
- `Set:has` (method)
- `Set:len` (method)

### system (96.2%)

- `lurek.runtime.log` (function)

### dataframe (96.6%)

- `DataFrame:min` (method)
- `DataFrame:max` (method)
- `DataFrame:withRollingMin` (method)
- `DataFrame:withRollingMax` (method)

### i18n (96.8%)

- `lurek.i18n.t` (function)

### pipeline (96.8%)

- `Pipeline:run` (method)
- `Pipeline:addSubPipeline` (method)

### thread (97.3%)

- `Channel:pop` (method)

### ai (97.6%)

- `AIBlackboard:has` (method)
- `InfluenceMap:stampInfluence` (method)
- `TraitProfile:set` (method)
- `TraitProfile:get` (method)
- `TraitProfile:has` (method)
- `EmotionModel:add` (method)
- `EmotionModel:get` (method)

### terminal (97.6%)

- `Terminal:set` (method)
- `Terminal:get` (method)

### render (97.7%)

- `lurek.render.arc` (function)
- `lurek.render.pop` (function)
- `SpriteBatch:add` (method)
- `Shape:arc` (method)

### mods (97.9%)

- `ContentRegistry:get` (method)

### physics (97.9%)

- `World:setJointMotorSpeed` (method)
- `World:setJointLimitsEnabled` (method)
- `World:setJointLimits` (method)
- `World:setMouseJointTarget` (method)

### particle (98.0%)

- `Trail:setHeadColor` (method)
- `Trail:setTailColor` (method)

### devtools (98.1%)

- `lurek.devtools.fatal` (function)

### effect (98.1%)

- `PostFxStack:add` (method)
- `PostFxStack:len` (method)
- `Overlay:triggerShake` (method)

## Orphaned Markers (typos or removed APIs)

- `AudioBus:setVolume` in `tests/lua/evidence/test_audio_evidence.lua:172`
- `AudioBus:getVolume` in `tests/lua/evidence/test_audio_evidence.lua:173`
- `AudioBus:setPitch` in `tests/lua/evidence/test_audio_evidence.lua:205`
- `AudioBus:getPitch` in `tests/lua/evidence/test_audio_evidence.lua:206`
- `AudioBus:setVolume` in `tests/lua/evidence/test_audio_evidence.lua:235`
- `AudioBus:setVolume` in `tests/lua/evidence/test_audio_evidence.lua:846`
- `AudioBus:getVolume` in `tests/lua/evidence/test_audio_evidence.lua:847`
- `AudioBus:setPitch` in `tests/lua/evidence/test_audio_evidence.lua:879`
- `AudioBus:getPitch` in `tests/lua/evidence/test_audio_evidence.lua:880`
- `AudioBus:setVolume` in `tests/lua/evidence/test_audio_evidence.lua:909`
- `Camera:setViewport` in `tests/lua/evidence/test_camera_evidence.lua:60`
- `Camera:setPosition` in `tests/lua/evidence/test_camera_evidence.lua:61`
- `Camera:setZoom` in `tests/lua/evidence/test_camera_evidence.lua:62`
- `Camera:toScreen` in `tests/lua/evidence/test_camera_evidence.lua:63`
- `Camera:getZoom` in `tests/lua/evidence/test_camera_evidence.lua:66`
- `Camera:toWorld` in `tests/lua/evidence/test_camera_evidence.lua:67`
- `Camera:setViewport` in `tests/lua/evidence/test_camera_evidence.lua:110`
- `Camera:setPosition` in `tests/lua/evidence/test_camera_evidence.lua:111`
- `Camera:setZoom` in `tests/lua/evidence/test_camera_evidence.lua:112`
- `Camera:setRotation` in `tests/lua/evidence/test_camera_evidence.lua:113`
- `Camera:toScreen` in `tests/lua/evidence/test_camera_evidence.lua:114`
- `Camera:getRotation` in `tests/lua/evidence/test_camera_evidence.lua:117`
- `Camera:setTarget` in `tests/lua/evidence/test_camera_evidence.lua:137`
- `Camera:setFollowSmooth` in `tests/lua/evidence/test_camera_evidence.lua:138`
- `Camera:update` in `tests/lua/evidence/test_camera_evidence.lua:139`
- `Camera:getPosition` in `tests/lua/evidence/test_camera_evidence.lua:140`
- `Camera:setBounds` in `tests/lua/evidence/test_camera_evidence.lua:143`
- `Camera:shake` in `tests/lua/evidence/test_camera_evidence.lua:178`
- `Camera:update` in `tests/lua/evidence/test_camera_evidence.lua:179`
- `Camera:getPosition` in `tests/lua/evidence/test_camera_evidence.lua:180`
- `LightSource:setColor` in `tests/lua/evidence/test_light_evidence.lua:10`
- `LightSource:getPosition` in `tests/lua/evidence/test_light_evidence.lua:11`
- `LightSource:getRadius` in `tests/lua/evidence/test_light_evidence.lua:12`
- `LightSource:getColor` in `tests/lua/evidence/test_light_evidence.lua:13`
- `LightSource:setColor` in `tests/lua/evidence/test_light_evidence.lua:46`
- `LightSource:getPosition` in `tests/lua/evidence/test_light_evidence.lua:47`
- `LightSource:getRadius` in `tests/lua/evidence/test_light_evidence.lua:48`
- `LightSource:getColor` in `tests/lua/evidence/test_light_evidence.lua:49`
- `LightSource:setColor` in `tests/lua/evidence/test_light_evidence.lua:107`
- `LightSource:getPosition` in `tests/lua/evidence/test_light_evidence.lua:108`
- `LightSource:getRadius` in `tests/lua/evidence/test_light_evidence.lua:109`
- `LightSource:getColor` in `tests/lua/evidence/test_light_evidence.lua:110`
- `LightSource:setColor` in `tests/lua/evidence/test_light_evidence.lua:143`
- `LightSource:getPosition` in `tests/lua/evidence/test_light_evidence.lua:144`
- `LightSource:getRadius` in `tests/lua/evidence/test_light_evidence.lua:145`
- `LightSource:getColor` in `tests/lua/evidence/test_light_evidence.lua:146`
- `lurek.math.newVec2` in `tests/lua/evidence/test_math_evidence.lua:5`
- `lurek.math.newVec2` in `tests/lua/evidence/test_math_evidence.lua:39`
- `lurek.math.randomSeed` in `tests/lua/evidence/test_math_evidence.lua:63`
- `lurek.math.perlinFast` in `tests/lua/evidence/test_math_evidence.lua:348`
- `lurek.math.simplex` in `tests/lua/evidence/test_math_evidence.lua:371`
- `lurek.math.perlinFast` in `tests/lua/evidence/test_math_evidence.lua:656`
- `lurek.math.simplex` in `tests/lua/evidence/test_math_evidence.lua:679`
- `lurek.pathfind.newUnitPathfinder` in `tests/lua/evidence/test_pathfind_evidence.lua:90`
- `lurek.pathfind.newUnitPathfinder` in `tests/lua/evidence/test_pathfind_evidence.lua:115`
- `LuaZone:setGravityZero` in `tests/lua/evidence/test_physics_evidence.lua:221`
- `LuaZone:setGravityZero` in `tests/lua/evidence/test_physics_evidence.lua:499`
- `LuaCellular:fillRect` in `tests/lua/evidence/test_physics_evidence.lua:562`
- `LuaCellular:stepN` in `tests/lua/evidence/test_physics_evidence.lua:563`
- `LuaCellular:toImageData` in `tests/lua/evidence/test_physics_evidence.lua:564`
- `LuaCellular:fillRect` in `tests/lua/evidence/test_physics_evidence.lua:617`
- `LuaCellular:stepN` in `tests/lua/evidence/test_physics_evidence.lua:618`
- `LuaCellular:toImageData` in `tests/lua/evidence/test_physics_evidence.lua:619`
- `LuaTerrain:fillAll` in `tests/lua/evidence/test_render_evidence.lua:187`
- `LuaTerrain:fillCircle` in `tests/lua/evidence/test_render_evidence.lua:188`
- `LuaTerrain:toImageData` in `tests/lua/evidence/test_render_evidence.lua:189`
- `LuaTerrain:fillAll` in `tests/lua/evidence/test_render_evidence.lua:408`
- `LuaTerrain:fillCircle` in `tests/lua/evidence/test_render_evidence.lua:409`
- `LuaTerrain:toImageData` in `tests/lua/evidence/test_render_evidence.lua:410`
- `ImageData:rotate90Cw` in `tests/lua/evidence/test_render_evidence.lua:873`
- `ImageData:rotate90Cw` in `tests/lua/evidence/test_render_evidence.lua:1389`
- `Pathfinder:findPath` in `tests/lua/evidence/test_render_evidence.lua:1496`
- `NdArray:fill` in `tests/lua/evidence/test_render_evidence.lua:1780`
- `NdArray:sum` in `tests/lua/evidence/test_render_evidence.lua:1781`
- `World:spawn` in `tests/lua/evidence/test_render_evidence.lua:1812`
- `World:isAlive` in `tests/lua/evidence/test_render_evidence.lua:1813`
- `World:getEntityCount` in `tests/lua/evidence/test_render_evidence.lua:1814`
- `NdArray:fill` in `tests/lua/evidence/test_render_evidence.lua:1932`
- `NdArray:sum` in `tests/lua/evidence/test_render_evidence.lua:1933`
- `World:spawn` in `tests/lua/evidence/test_render_evidence.lua:1964`
- `World:isAlive` in `tests/lua/evidence/test_render_evidence.lua:1965`
- `World:getEntityCount` in `tests/lua/evidence/test_render_evidence.lua:1966`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:177`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:199`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:220`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:243`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:261`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:296`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:318`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:339`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:362`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:380`
- `lurek.ecs.Universe` in `tests/lua/integration/test_ai_ecs_scene.lua:7`
- `lurek.ecs.Universe` in `tests/lua/integration/test_ai_ecs_scene.lua:58`
- `lurek.compute.newBuffer` in `tests/lua/integration/test_data_compute.lua:9`
- `lurek.test.bar` in `tests/lua/integration/test_docs.lua:21`
- `lurek.test.foo` in `tests/lua/integration/test_docs.lua:22`
- `lurek.test.func` in `tests/lua/integration/test_docs.lua:23`
- `lurek.test.func2` in `tests/lua/integration/test_docs.lua:24`
- `lurek.test.g1` in `tests/lua/integration/test_docs.lua:25`
- `lurek.test.json` in `tests/lua/integration/test_docs.lua:26`
- `lurek.test.ms` in `tests/lua/integration/test_docs.lua:27`
- `lurek.test.q1` in `tests/lua/integration/test_docs.lua:28`
- `lurek.test.scored` in `tests/lua/integration/test_docs.lua:29`
- `lurek.test.sum` in `tests/lua/integration/test_docs.lua:30`
- `lurek.test.tt` in `tests/lua/integration/test_docs.lua:31`
- `lurek.test.w1` in `tests/lua/integration/test_docs.lua:32`
- `lurek.test.w2` in `tests/lua/integration/test_docs.lua:33`
- `lurek.render.DrawLayer` in `tests/lua/integration/test_drawlayer.lua:9`
- `lurek.ecs.Universe` in `tests/lua/integration/test_ecs_ai.lua:6`
- `lurek.event.new` in `tests/lua/integration/test_event_entity.lua:9`
- `lurek.i18n.get` in `tests/lua/integration/test_i18n_ui.lua:6`
- `lurek.ui.setText` in `tests/lua/integration/test_i18n_ui.lua:7`
- `lurek.i18n.load` in `tests/lua/integration/test_i18n_ui.lua:8`
- `lurek.i18n.setLocale` in `tests/lua/integration/test_i18n_ui.lua:9`
- `lurek.i18n.setLocale` in `tests/lua/integration/test_i18n_ui.lua:37`
- `lurek.ui.setText` in `tests/lua/integration/test_i18n_ui.lua:38`
- `lurek.i18n.get` in `tests/lua/integration/test_i18n_ui.lua:59`
- `lurek.input.getMousePosition` in `tests/lua/integration/test_input_camera.lua:7`
- `lurek.input.getMousePosition` in `tests/lua/integration/test_input_camera.lua:33`
- `lurek.input.getMousePosition` in `tests/lua/integration/test_input_camera.lua:52`
- `lurek.input.getMousePosition` in `tests/lua/integration/test_input_camera.lua:66`
- `lurek.light.setPosition` in `tests/lua/integration/test_light_render.lua:8`
- `lurek.light.setRadius` in `tests/lua/integration/test_light_render.lua:9`
- `lurek.light.setColor` in `tests/lua/integration/test_light_render.lua:10`
- `lurek.light.setIntensity` in `tests/lua/integration/test_light_render.lua:11`
- `lurek.light.setIntensity` in `tests/lua/integration/test_light_render.lua:34`
- `lurek.light.setColor` in `tests/lua/integration/test_light_render.lua:59`
- `lurek.math.pi` in `tests/lua/integration/test_math_physics.lua:11`
- `lurek.particle.newEmitter` in `tests/lua/integration/test_particle_timer.lua:6`
- `lurek.pathfind.newGrid` in `tests/lua/integration/test_pathfind_ecs.lua:8`
- `LuaZone:setGravityPoint` in `tests/lua/integration/test_physics_space.lua:8`
- `LuaZone:setGravityZero` in `tests/lua/integration/test_physics_space.lua:30`
- `LuaZone:setPriority` in `tests/lua/integration/test_physics_space.lua:53`
- `LuaZone:setGravityDirectional` in `tests/lua/integration/test_physics_space.lua:54`
- `LuaTerrain:fillAll` in `tests/lua/integration/test_physics_tanks.lua:7`
- `LuaTerrain:setCell` in `tests/lua/integration/test_physics_tanks.lua:8`
- `LuaTerrain:solidPositions` in `tests/lua/integration/test_physics_tanks.lua:9`
- `LuaTerrain:spawnDebris` in `tests/lua/integration/test_physics_tanks.lua:10`
- `LuaTerrain:collapseColumns` in `tests/lua/integration/test_physics_tanks.lua:11`
- `LuaTerrain:flush` in `tests/lua/integration/test_physics_tanks.lua:12`
- `LuaTerrain:toImageData` in `tests/lua/integration/test_physics_tanks.lua:48`
- `LuaCellular:fillRect` in `tests/lua/integration/test_physics_world_sim.lua:8`
- `LuaCellular:stepN` in `tests/lua/integration/test_physics_world_sim.lua:9`
- `LuaCellular:countCells` in `tests/lua/integration/test_physics_world_sim.lua:10`
- `LuaCellular:toImageData` in `tests/lua/integration/test_physics_world_sim.lua:37`
- `LuaCellular:toImageDataRegion` in `tests/lua/integration/test_physics_world_sim.lua:46`
- `LuaCellular:toBytes` in `tests/lua/integration/test_physics_world_sim.lua:54`
- `LuaCellular:loadFromBytes` in `tests/lua/integration/test_physics_world_sim.lua:55`
- `LuaCellular:fillCircle` in `tests/lua/integration/test_physics_world_sim.lua:73`
- `LuaCellular:countCells` in `tests/lua/integration/test_physics_world_sim.lua:74`
- `LuaTerrain:fillAll` in `tests/lua/integration/test_physics_worms.lua:10`
- `LuaTerrain:fillCircle` in `tests/lua/integration/test_physics_worms.lua:11`
- `LuaTerrain:flush` in `tests/lua/integration/test_physics_worms.lua:12`
- `LuaTerrain:fillCircle` in `tests/lua/integration/test_physics_worms.lua:38`
- `LuaTerrain:flush` in `tests/lua/integration/test_physics_worms.lua:39`
- `lurek.procgen.noise2d` in `tests/lua/integration/test_procgen_tilemap.lua:6`
- `lurek.tilemap.newTilemap` in `tests/lua/integration/test_procgen_tilemap.lua:8`
- `lurek.procgen.noise2d` in `tests/lua/integration/test_procgen_tilemap.lua:36`
- `lurek.procgen.noise2d` in `tests/lua/integration/test_procgen_tilemap.lua:66`
- `lurek.animation.addClip` in `tests/lua/integration/test_render_animation.lua:7`
- `lurek.animation.play` in `tests/lua/integration/test_render_animation.lua:8`
- `lurek.animation.getCurrentFrame` in `tests/lua/integration/test_render_animation.lua:25`
- `lurek.animation.addClip` in `tests/lua/integration/test_render_animation.lua:46`
- `lurek.animation.isLooping` in `tests/lua/integration/test_render_animation.lua:47`
- `lurek.animation.pause` in `tests/lua/integration/test_render_animation.lua:62`
- `lurek.animation.resume` in `tests/lua/integration/test_render_animation.lua:63`
- `lurek.runtime.clipboard` in `tests/lua/integration/test_runtime_system.lua:8`
- `lurek.tilemap.newTilemap` in `tests/lua/integration/test_save_tilemap.lua:9`
- `lurek.tilemap.setTile` in `tests/lua/integration/test_save_tilemap.lua:10`
- `lurek.tilemap.getTile` in `tests/lua/integration/test_save_tilemap.lua:11`
- `lurek.tilemap.newTilemap` in `tests/lua/integration/test_tilemap_camera.lua:8`
- `lurek.tilemap.setTile` in `tests/lua/integration/test_tilemap_camera.lua:9`
- `lurek.tilemap.getTile` in `tests/lua/integration/test_tilemap_camera.lua:10`
- `lurek.tilemap.clearTile` in `tests/lua/integration/test_tilemap_physics.lua:65`
- `lurek.math.pi` in `tests/lua/integration/test_timer_math.lua:8`
- `StateMachine:update` in `tests/lua/stress/test_ai_stress.lua:7`
- `StateMachine:update` in `tests/lua/stress/test_ai_stress.lua:27`
- `lurek.animation.newTimeline` in `tests/lua/stress/test_animation_stress.lua:6`
- `Timeline:addFrame` in `tests/lua/stress/test_animation_stress.lua:7`
- `lurek.animation.newTimeline` in `tests/lua/stress/test_animation_stress.lua:21`
- `Timeline:update` in `tests/lua/stress/test_animation_stress.lua:22`
- `lurek.animation.newTimeline` in `tests/lua/stress/test_animation_stress.lua:50`
- `Timeline:addFrame` in `tests/lua/stress/test_animation_stress.lua:51`
- `Timeline:seek` in `tests/lua/stress/test_animation_stress.lua:52`
- `Camera:setPosition` in `tests/lua/stress/test_camera_stress.lua:7`
- `Camera:setZoom` in `tests/lua/stress/test_camera_stress.lua:22`
- `Camera:setPosition` in `tests/lua/stress/test_camera_stress.lua:37`
- `Camera:setZoom` in `tests/lua/stress/test_camera_stress.lua:38`
- `NdArray:getShape` in `tests/lua/stress/test_compute_stress.lua:7`
- `NdArray:getSize` in `tests/lua/stress/test_compute_stress.lua:8`
- `NdArray:sum` in `tests/lua/stress/test_compute_stress.lua:20`
- `NdArray:getSize` in `tests/lua/stress/test_compute_stress.lua:33`
- `NdArray:add` in `tests/lua/stress/test_compute_stress.lua:45`
- `NdArray:sum` in `tests/lua/stress/test_compute_stress.lua:46`
- `NdArray:mul` in `tests/lua/stress/test_compute_stress.lua:61`
- `NdArray:add` in `tests/lua/stress/test_compute_stress.lua:72`
- `NdArray:mul` in `tests/lua/stress/test_compute_stress.lua:73`
- `NdArray:sub` in `tests/lua/stress/test_compute_stress.lua:74`
- `NdArray:sum` in `tests/lua/stress/test_compute_stress.lua:91`
- `NdArray:min` in `tests/lua/stress/test_compute_stress.lua:100`
- `NdArray:max` in `tests/lua/stress/test_compute_stress.lua:101`
- `NdArray:mean` in `tests/lua/stress/test_compute_stress.lua:111`
- `lurek.ecs.defineBlueprint` in `tests/lua/stress/test_ecs_stress.lua:122`
- `lurek.ecs.spawnBulk` in `tests/lua/stress/test_ecs_stress.lua:123`
- `lurek.ecs.spawnBulk` in `tests/lua/stress/test_ecs_stress.lua:133`
- `lurek.ecs.spawnBulk` in `tests/lua/stress/test_ecs_stress.lua:144`
- `lurek.ecs.spawnBulk` in `tests/lua/stress/test_ecs_stress.lua:153`
- `lurek.event.new` in `tests/lua/stress/test_event_stress.lua:6`
- `lurek.event.new` in `tests/lua/stress/test_event_stress.lua:36`
- `Connection:disconnect` in `tests/lua/stress/test_event_stress.lua:38`
- `lurek.event.new` in `tests/lua/stress/test_event_stress.lua:53`
- `lurek.image.newImage` in `tests/lua/stress/test_image_stress.lua:6`
- `lurek.image.newImage` in `tests/lua/stress/test_image_stress.lua:22`
- `Image:getPixel` in `tests/lua/stress/test_image_stress.lua:23`
- `lurek.image.newImage` in `tests/lua/stress/test_image_stress.lua:37`
- `Image:setPixel` in `tests/lua/stress/test_image_stress.lua:38`
- `lurek.light.setIntensity` in `tests/lua/stress/test_light_stress.lua:26`
- `lurek.light.setPosition` in `tests/lua/stress/test_light_stress.lua:27`
- `lurek.light.setPosition` in `tests/lua/stress/test_light_stress.lua:61`
- `lurek.light.setRadius` in `tests/lua/stress/test_light_stress.lua:62`
- `lurek.light.setColor` in `tests/lua/stress/test_light_stress.lua:63`
- `lurek.light.setIntensity` in `tests/lua/stress/test_light_stress.lua:64`
- `lurek.particle.isActive` in `tests/lua/stress/test_particle_stress.lua:30`
- `Observer:notify` in `tests/lua/stress/test_patterns_stress.lua:8`
- `lurek.patterns.newCommandQueue` in `tests/lua/stress/test_patterns_stress.lua:37`
- `CommandQueue:push` in `tests/lua/stress/test_patterns_stress.lua:38`
- `CommandQueue:executeAll` in `tests/lua/stress/test_patterns_stress.lua:39`
- `lurek.patterns.newStateMachine` in `tests/lua/stress/test_patterns_stress.lua:64`
- `StateMachine:getState` in `tests/lua/stress/test_patterns_stress.lua:65`
- `StateMachine:setState` in `tests/lua/stress/test_patterns_stress.lua:66`
- `LuaCellular:fillRect` in `tests/lua/stress/test_physics_stress.lua:70`
- `LuaCellular:stepN` in `tests/lua/stress/test_physics_stress.lua:71`
- `LuaCellular:countCells` in `tests/lua/stress/test_physics_stress.lua:72`
- `LuaCellular:toImageData` in `tests/lua/stress/test_physics_stress.lua:100`
- `lurek.physics.newCircleBody` in `tests/lua/stress/test_physics_stress.lua:191`
- `LuaTerrain:fillAll` in `tests/lua/stress/test_physics_stress.lua:255`
- `LuaTerrain:fillCircle` in `tests/lua/stress/test_physics_stress.lua:256`
- `LuaTerrain:flush` in `tests/lua/stress/test_physics_stress.lua:257`
- `LuaTerrain:isDirty` in `tests/lua/stress/test_physics_stress.lua:258`
- `LuaTerrain:collapseColumns` in `tests/lua/stress/test_physics_stress.lua:278`
- `LuaTerrain:solidPositions` in `tests/lua/stress/test_physics_stress.lua:279`
- `LuaZone:setGravityZero` in `tests/lua/stress/test_physics_stress.lua:309`
- `LuaCellular:fillRect` in `tests/lua/stress/test_physics_stress.lua:358`
- `LuaCellular:stepN` in `tests/lua/stress/test_physics_stress.lua:359`
- `LuaCellular:countCells` in `tests/lua/stress/test_physics_stress.lua:360`
- `LuaCellular:toImageData` in `tests/lua/stress/test_physics_stress.lua:388`
- `LuaTerrain:fillAll` in `tests/lua/stress/test_physics_stress.lua:414`
- `LuaTerrain:fillCircle` in `tests/lua/stress/test_physics_stress.lua:415`
- `LuaTerrain:flush` in `tests/lua/stress/test_physics_stress.lua:416`
- `LuaTerrain:isDirty` in `tests/lua/stress/test_physics_stress.lua:417`
- `LuaTerrain:collapseColumns` in `tests/lua/stress/test_physics_stress.lua:437`
- `LuaTerrain:solidPositions` in `tests/lua/stress/test_physics_stress.lua:438`
- `LuaZone:setGravityZero` in `tests/lua/stress/test_physics_stress.lua:468`
- `lurek.serial.base64Encode` in `tests/lua/stress/test_serial_stress.lua:6`
- `lurek.serial.base64Decode` in `tests/lua/stress/test_serial_stress.lua:7`
- `lurek.serial.base64Encode` in `tests/lua/stress/test_serial_stress.lua:20`
- `lurek.serial.base64Decode` in `tests/lua/stress/test_serial_stress.lua:21`
- `Channel:tryPop` in `tests/lua/stress/test_thread_stress.lua:19`
- `Channel:tryPop` in `tests/lua/stress/test_thread_stress.lua:46`
- `Channel:tryPop` in `tests/lua/stress/test_thread_stress.lua:80`
- `lurek.tween.newTween` in `tests/lua/stress/test_tween_stress.lua:6`
- `Tween:setDuration` in `tests/lua/stress/test_tween_stress.lua:7`
- `Tween:setEasing` in `tests/lua/stress/test_tween_stress.lua:8`
- `Tween:setFrom` in `tests/lua/stress/test_tween_stress.lua:9`
- `Tween:setTo` in `tests/lua/stress/test_tween_stress.lua:10`
- `lurek.tween.newTween` in `tests/lua/stress/test_tween_stress.lua:42`
- `Tween:seek` in `tests/lua/stress/test_tween_stress.lua:43`
- `lurek.tween.newTween` in `tests/lua/stress/test_tween_stress.lua:62`
- `Tween:onComplete` in `tests/lua/stress/test_tween_stress.lua:63`
