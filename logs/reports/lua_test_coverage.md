# Lua API Test Coverage Report

**Generated**: 2026-04-23
**Mode**: hybrid
**Total API functions**: 3704

## Summary

| Metric | Value |
|--------|-------|
| Marker-covered | 256 |
| Heuristic-covered | 3312 |
| Total covered | 3606 |
| Coverage | 97.4% |

## Per-Module Coverage

| Module | Total | Marker | Heuristic | Covered | Coverage |
|--------|-------|--------|-----------|---------|----------|
| compute | 71 | 4 | 54 | 58 | 81.7% |
| patterns | 170 | 2 | 140 | 142 | 83.5% |
| engine | 10 | 0 | 9 | 9 | 90.0% |
| globe | 44 | 0 | 40 | 40 | 90.9% |
| math | 204 | 23 | 163 | 186 | 91.2% |
| scene | 53 | 2 | 48 | 50 | 94.3% |
| tween | 35 | 5 | 28 | 33 | 94.3% |
| data | 57 | 7 | 47 | 54 | 94.7% |
| raycaster | 42 | 4 | 36 | 40 | 95.2% |
| animation | 46 | 1 | 43 | 44 | 95.7% |
| devtools | 48 | 31 | 15 | 46 | 95.8% |
| system | 26 | 0 | 25 | 25 | 96.2% |
| i18n | 31 | 0 | 30 | 30 | 96.8% |
| thread | 37 | 2 | 34 | 36 | 97.3% |
| terminal | 82 | 0 | 80 | 80 | 97.6% |
| dataframe | 88 | 6 | 80 | 86 | 97.7% |
| mods | 46 | 0 | 45 | 45 | 97.8% |
| ai | 242 | 6 | 231 | 237 | 97.9% |
| ecs | 47 | 6 | 40 | 46 | 97.9% |
| pipeline | 60 | 0 | 59 | 59 | 98.3% |
| effect | 145 | 5 | 138 | 143 | 98.6% |
| render | 183 | 13 | 168 | 181 | 98.9% |
| graph | 111 | 3 | 107 | 110 | 99.1% |
| audio | 212 | 19 | 193 | 212 | 100.0% |
| automation | 28 | 0 | 28 | 28 | 100.0% |
| camera | 36 | 1 | 35 | 36 | 100.0% |
| debugbridge | 14 | 14 | 0 | 14 | 100.0% |
| docs | 75 | 12 | 63 | 75 | 100.0% |
| event | 22 | 3 | 19 | 22 | 100.0% |
| filesystem | 54 | 5 | 49 | 54 | 100.0% |
| image | 68 | 2 | 66 | 68 | 100.0% |
| input | 80 | 0 | 80 | 80 | 100.0% |
| light | 83 | 1 | 82 | 83 | 100.0% |
| log | 18 | 0 | 18 | 18 | 100.0% |
| minimap | 56 | 5 | 51 | 56 | 100.0% |
| network | 38 | 0 | 38 | 38 | 100.0% |
| parallax | 43 | 2 | 41 | 43 | 100.0% |
| particle | 89 | 13 | 76 | 89 | 100.0% |
| pathfind | 65 | 5 | 60 | 65 | 100.0% |
| physics | 151 | 17 | 134 | 151 | 100.0% |
| procgen | 29 | 2 | 27 | 29 | 100.0% |
| save | 22 | 4 | 18 | 22 | 100.0% |
| serial | 10 | 2 | 8 | 10 | 100.0% |
| spine | 20 | 5 | 15 | 20 | 100.0% |
| sprite | 18 | 0 | 18 | 18 | 100.0% |
| tilemap | 138 | 11 | 127 | 138 | 100.0% |
| timer | 43 | 4 | 39 | 43 | 100.0% |
| ui | 364 | 5 | 359 | 364 | 100.0% |
| window | 50 | 5 | 45 | 50 | 100.0% |

## Uncovered Functions (lowest coverage first)

### compute (81.7%)

- `lurek.compute.fft` (function)
- `Array:get` (method)
- `Array:set` (method)
- `Array:pow` (method)
- `Array:abs` (method)
- `Array:neg` (method)
- `Array:any` (method)
- `Array:all` (method)
- `Array:sum` (method)
- `Array:min` (method)
- `Array:max` (method)
- `Array:dot` (method)
- `Array:map` (method)

### patterns (83.5%)

- `EventBus:on` (method)
- `EventBus:off` (method)
- `ObjectPool:add` (method)
- `ServiceLocator:has` (method)
- `Factory:has` (method)
- `Blackboard:set` (method)
- `Blackboard:get` (method)
- `Blackboard:has` (method)
- `Observer:set` (method)
- `Observer:get` (method)
- `PriorityQueue:pop` (method)
- `PriorityQueue:len` (method)
- `Ring:sum` (method)
- `Ring:len` (method)
- `Mediator:on` (method)
- `Mediator:off` (method)
- `Strategy:set` (method)
- `Strategy:has` (method)
- `Stack:pop` (method)
- `Stack:len` (method)
- ... and 8 more

### engine (90.0%)

- `lurek.engine.fps` (function)

### globe (90.9%)

- `lurek.globe.new` (function)
- `lurek.globe.get` (function)
- `Globe:pan` (method)
- `GlobeRegistry:get` (method)

### math (91.2%)

- `lurek.math.fbm` (function)
- `lurek.math.rad` (function)
- `lurek.math.deg` (function)
- `lurek.math.tan` (function)
- `lurek.math.exp` (function)
- `lurek.math.log` (function)
- `lurek.math.pow` (function)
- `Vec2:dot` (method)
- `Vec2:x` (method)
- `Vec2:y` (method)
- `Vec3:dot` (method)
- `Vec3:add` (method)
- `Vec3:sub` (method)
- `CatmullRom:len` (method)
- `Tween:set` (method)
- `Circle:x` (method)
- `Circle:y` (method)
- `AabbTree:len` (method)

### scene (94.3%)

- `lurek.scene.pop` (function)
- `lurek.scene.new` (function)
- `DepthSorter:add` (method)

### tween (94.3%)

- `lurek.tween.to` (function)
- `TweenState:t` (method)

### data (94.7%)

- `RingBuffer:pop` (method)
- `RingBuffer:len` (method)
- `DataWriter:len` (method)

### raycaster (95.2%)

- `PointLight:x` (method)
- `PointLight:y` (method)

### animation (95.7%)

- `BlendLayerSet:len` (method)
- `AnimSyncGroup:add` (method)

### devtools (95.8%)

- `lurek.devtools.log` (function)
- `ReplConsole:len` (method)

### system (96.2%)

- `lurek.system.log` (function)

### i18n (96.8%)

- `lurek.i18n.t` (function)

### thread (97.3%)

- `Channel:pop` (method)

### terminal (97.6%)

- `Terminal:set` (method)
- `Terminal:get` (method)

## Orphaned Markers (typos or removed APIs)

- `lurek.runtime.getOS` in `tests/lua/config/test_config.lua:4`
- `lurek.runtime.getVersion` in `tests/lua/config/test_config.lua:5`
- `lurek.runtime.getVersion` in `tests/lua/config/test_config.lua:82`
- `lurek.runtime.getOS` in `tests/lua/config/test_config.lua:90`
- `Animator:addClipFromGrid` in `tests/lua/evidence/test_animation_evidence.lua:54`
- `Animator:play` in `tests/lua/evidence/test_animation_evidence.lua:55`
- `Animator:update` in `tests/lua/evidence/test_animation_evidence.lua:56`
- `Animator:getQuad` in `tests/lua/evidence/test_animation_evidence.lua:57`
- `Animator:pollEvents` in `tests/lua/evidence/test_animation_evidence.lua:59`
- `Animator:addClip` in `tests/lua/evidence/test_animation_evidence.lua:123`
- `Animator:setSpeed` in `tests/lua/evidence/test_animation_evidence.lua:124`
- `Animator:update` in `tests/lua/evidence/test_animation_evidence.lua:125`
- `Animator:getQuad` in `tests/lua/evidence/test_animation_evidence.lua:126`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:10`
- `SoundData:getSample` in `tests/lua/evidence/test_audio_evidence.lua:11`
- `SoundData:drawWaveform` in `tests/lua/evidence/test_audio_evidence.lua:12`
- `SoundData:getDuration` in `tests/lua/evidence/test_audio_evidence.lua:15`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:48`
- `SoundData:drawWaveform` in `tests/lua/evidence/test_audio_evidence.lua:49`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:80`
- `SoundData:drawWaveform` in `tests/lua/evidence/test_audio_evidence.lua:81`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:108`
- `SoundData:drawWaveform` in `tests/lua/evidence/test_audio_evidence.lua:109`
- `AudioBus:setVolume` in `tests/lua/evidence/test_audio_evidence.lua:172`
- `AudioBus:getVolume` in `tests/lua/evidence/test_audio_evidence.lua:173`
- `AudioBus:setPitch` in `tests/lua/evidence/test_audio_evidence.lua:205`
- `AudioBus:getPitch` in `tests/lua/evidence/test_audio_evidence.lua:206`
- `AudioBus:setVolume` in `tests/lua/evidence/test_audio_evidence.lua:235`
- `SoundData:getSample` in `tests/lua/evidence/test_audio_evidence.lua:237`
- `SoundData:drawWaveform` in `tests/lua/evidence/test_audio_evidence.lua:626`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:687`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:707`
- `SoundData:getSample` in `tests/lua/evidence/test_audio_evidence.lua:708`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:745`
- `SoundData:getSample` in `tests/lua/evidence/test_audio_evidence.lua:766`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:767`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:805`
- `SoundData:getSample` in `tests/lua/evidence/test_audio_evidence.lua:806`
- `SoundData:drawWaveform` in `tests/lua/evidence/test_audio_evidence.lua:807`
- `SoundData:getDuration` in `tests/lua/evidence/test_audio_evidence.lua:810`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:843`
- `SoundData:drawWaveform` in `tests/lua/evidence/test_audio_evidence.lua:844`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:875`
- `SoundData:drawWaveform` in `tests/lua/evidence/test_audio_evidence.lua:876`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:903`
- `SoundData:drawWaveform` in `tests/lua/evidence/test_audio_evidence.lua:904`
- `AudioBus:setVolume` in `tests/lua/evidence/test_audio_evidence.lua:967`
- `AudioBus:getVolume` in `tests/lua/evidence/test_audio_evidence.lua:968`
- `AudioBus:setPitch` in `tests/lua/evidence/test_audio_evidence.lua:1000`
- `AudioBus:getPitch` in `tests/lua/evidence/test_audio_evidence.lua:1001`
- `AudioBus:setVolume` in `tests/lua/evidence/test_audio_evidence.lua:1030`
- `SoundData:getSample` in `tests/lua/evidence/test_audio_evidence.lua:1032`
- `Camera:setViewport` in `tests/lua/evidence/test_camera_evidence.lua:60`
- `Camera:setPosition` in `tests/lua/evidence/test_camera_evidence.lua:61`
- `Camera:setZoom` in `tests/lua/evidence/test_camera_evidence.lua:62`
- `Camera:toScreen` in `tests/lua/evidence/test_camera_evidence.lua:63`
- `lurek.camera.newCamera` in `tests/lua/evidence/test_camera_evidence.lua:65`
- `Camera:getZoom` in `tests/lua/evidence/test_camera_evidence.lua:66`
- `Camera:toWorld` in `tests/lua/evidence/test_camera_evidence.lua:67`
- `Camera:setViewport` in `tests/lua/evidence/test_camera_evidence.lua:110`
- `Camera:setPosition` in `tests/lua/evidence/test_camera_evidence.lua:111`
- `Camera:setZoom` in `tests/lua/evidence/test_camera_evidence.lua:112`
- `Camera:setRotation` in `tests/lua/evidence/test_camera_evidence.lua:113`
- `Camera:toScreen` in `tests/lua/evidence/test_camera_evidence.lua:114`
- `lurek.camera.newCamera` in `tests/lua/evidence/test_camera_evidence.lua:116`
- `Camera:getRotation` in `tests/lua/evidence/test_camera_evidence.lua:117`
- `Camera:setTarget` in `tests/lua/evidence/test_camera_evidence.lua:137`
- `Camera:setFollowSmooth` in `tests/lua/evidence/test_camera_evidence.lua:138`
- `Camera:update` in `tests/lua/evidence/test_camera_evidence.lua:139`
- `Camera:getPosition` in `tests/lua/evidence/test_camera_evidence.lua:140`
- `lurek.camera.newCamera` in `tests/lua/evidence/test_camera_evidence.lua:142`
- `Camera:setBounds` in `tests/lua/evidence/test_camera_evidence.lua:143`
- `Camera:shake` in `tests/lua/evidence/test_camera_evidence.lua:178`
- `Camera:update` in `tests/lua/evidence/test_camera_evidence.lua:179`
- `Camera:getPosition` in `tests/lua/evidence/test_camera_evidence.lua:180`
- `lurek.camera.newCamera` in `tests/lua/evidence/test_camera_evidence.lua:182`
- `Overlay:triggerFlash` in `tests/lua/evidence/test_effect_evidence.lua:31`
- `Overlay:triggerFade` in `tests/lua/evidence/test_effect_evidence.lua:62`
- `Overlay:triggerFlash` in `tests/lua/evidence/test_effect_evidence.lua:92`
- `ImageData:grayscale` in `tests/lua/evidence/test_effect_evidence.lua:171`
- `ImageData:getPixel` in `tests/lua/evidence/test_effect_evidence.lua:172`
- `ImageData:invert` in `tests/lua/evidence/test_effect_evidence.lua:184`
- `ImageData:getPixel` in `tests/lua/evidence/test_effect_evidence.lua:185`
- `ImageData:blur` in `tests/lua/evidence/test_effect_evidence.lua:199`
- `ImageData:sepia` in `tests/lua/evidence/test_effect_evidence.lua:209`
- `ImageData:grayscale` in `tests/lua/evidence/test_effect_evidence.lua:219`
- `ImageData:sepia` in `tests/lua/evidence/test_effect_evidence.lua:220`
- `ImageData:invert` in `tests/lua/evidence/test_effect_evidence.lua:221`
- `ImageData:blur` in `tests/lua/evidence/test_effect_evidence.lua:222`
- `ImageData:sharpen` in `tests/lua/evidence/test_effect_evidence.lua:223`
- `ImageData:brightness` in `tests/lua/evidence/test_effect_evidence.lua:224`
- `ImageData:contrast` in `tests/lua/evidence/test_effect_evidence.lua:225`
- `ImageData:threshold` in `tests/lua/evidence/test_effect_evidence.lua:226`
- `ImageData:posterize` in `tests/lua/evidence/test_effect_evidence.lua:263`
- `ImageData:gamma` in `tests/lua/evidence/test_effect_evidence.lua:264`
- `ImageData:tint` in `tests/lua/evidence/test_effect_evidence.lua:265`
- `ImageData:saturation` in `tests/lua/evidence/test_effect_evidence.lua:277`
- `ImageData:flipHorizontal` in `tests/lua/evidence/test_effect_evidence.lua:278`
- `Overlay:triggerFlash` in `tests/lua/evidence/test_effect_evidence.lua:388`
- `Overlay:triggerFade` in `tests/lua/evidence/test_effect_evidence.lua:419`
- `Overlay:triggerFlash` in `tests/lua/evidence/test_effect_evidence.lua:449`
- `ImageData:grayscale` in `tests/lua/evidence/test_effect_evidence.lua:528`
- `ImageData:getPixel` in `tests/lua/evidence/test_effect_evidence.lua:529`
- `ImageData:invert` in `tests/lua/evidence/test_effect_evidence.lua:541`
- `ImageData:getPixel` in `tests/lua/evidence/test_effect_evidence.lua:542`
- `ImageData:blur` in `tests/lua/evidence/test_effect_evidence.lua:556`
- `ImageData:sepia` in `tests/lua/evidence/test_effect_evidence.lua:566`
- `ImageData:grayscale` in `tests/lua/evidence/test_effect_evidence.lua:576`
- `ImageData:sepia` in `tests/lua/evidence/test_effect_evidence.lua:577`
- `ImageData:invert` in `tests/lua/evidence/test_effect_evidence.lua:578`
- `ImageData:blur` in `tests/lua/evidence/test_effect_evidence.lua:579`
- `ImageData:sharpen` in `tests/lua/evidence/test_effect_evidence.lua:580`
- `ImageData:brightness` in `tests/lua/evidence/test_effect_evidence.lua:581`
- `ImageData:contrast` in `tests/lua/evidence/test_effect_evidence.lua:582`
- `ImageData:threshold` in `tests/lua/evidence/test_effect_evidence.lua:583`
- `ImageData:posterize` in `tests/lua/evidence/test_effect_evidence.lua:620`
- `ImageData:gamma` in `tests/lua/evidence/test_effect_evidence.lua:621`
- `ImageData:tint` in `tests/lua/evidence/test_effect_evidence.lua:622`
- `ImageData:saturation` in `tests/lua/evidence/test_effect_evidence.lua:634`
- `ImageData:flipHorizontal` in `tests/lua/evidence/test_effect_evidence.lua:635`
- `Graph:findPath` in `tests/lua/evidence/test_graph_evidence.lua:77`
- `Graph:addNode` in `tests/lua/evidence/test_graph_evidence.lua:80`
- `Graph:addEdge` in `tests/lua/evidence/test_graph_evidence.lua:81`
- `Graph:findPath` in `tests/lua/evidence/test_graph_evidence.lua:110`
- `ImageData:drawRect` in `tests/lua/evidence/test_image_evidence.lua:23`
- `ImageData:getPixel` in `tests/lua/evidence/test_image_evidence.lua:24`
- `ImageData:drawLine` in `tests/lua/evidence/test_image_evidence.lua:57`
- `ImageData:getPixel` in `tests/lua/evidence/test_image_evidence.lua:58`
- `ImageData:drawCircle` in `tests/lua/evidence/test_image_evidence.lua:83`
- `ImageData:getPixel` in `tests/lua/evidence/test_image_evidence.lua:84`
- `ImageData:drawRect` in `tests/lua/evidence/test_image_evidence.lua:110`
- `ImageData:drawCircle` in `tests/lua/evidence/test_image_evidence.lua:111`
- `ImageData:drawLine` in `tests/lua/evidence/test_image_evidence.lua:112`
- `ImageData:setPixel` in `tests/lua/evidence/test_image_evidence.lua:113`
- `ImageData:brightness` in `tests/lua/evidence/test_image_evidence.lua:219`
- `ImageData:getPixel` in `tests/lua/evidence/test_image_evidence.lua:220`
- `ImageData:brightness` in `tests/lua/evidence/test_image_evidence.lua:233`
- `ImageData:contrast` in `tests/lua/evidence/test_image_evidence.lua:243`
- `ImageData:contrast` in `tests/lua/evidence/test_image_evidence.lua:253`
- `ImageData:saturation` in `tests/lua/evidence/test_image_evidence.lua:263`
- `ImageData:saturation` in `tests/lua/evidence/test_image_evidence.lua:273`
- `ImageData:grayscale` in `tests/lua/evidence/test_image_evidence.lua:283`
- `ImageData:getPixel` in `tests/lua/evidence/test_image_evidence.lua:284`
- `ImageData:sepia` in `tests/lua/evidence/test_image_evidence.lua:295`
- `ImageData:invert` in `tests/lua/evidence/test_image_evidence.lua:305`
- `ImageData:threshold` in `tests/lua/evidence/test_image_evidence.lua:315`
- `ImageData:posterize` in `tests/lua/evidence/test_image_evidence.lua:325`
- `ImageData:blur` in `tests/lua/evidence/test_image_evidence.lua:335`
- `ImageData:sharpen` in `tests/lua/evidence/test_image_evidence.lua:345`
- `ImageData:gamma` in `tests/lua/evidence/test_image_evidence.lua:355`
- `ImageData:tint` in `tests/lua/evidence/test_image_evidence.lua:369`
- `ImageData:drawRect` in `tests/lua/evidence/test_image_evidence.lua:409`
- `ImageData:getPixel` in `tests/lua/evidence/test_image_evidence.lua:410`
- `ImageData:drawLine` in `tests/lua/evidence/test_image_evidence.lua:443`
- `ImageData:getPixel` in `tests/lua/evidence/test_image_evidence.lua:444`
- `ImageData:drawCircle` in `tests/lua/evidence/test_image_evidence.lua:469`
- `ImageData:getPixel` in `tests/lua/evidence/test_image_evidence.lua:470`
- `ImageData:drawRect` in `tests/lua/evidence/test_image_evidence.lua:496`
- `ImageData:drawCircle` in `tests/lua/evidence/test_image_evidence.lua:497`
- `ImageData:drawLine` in `tests/lua/evidence/test_image_evidence.lua:498`
- `ImageData:setPixel` in `tests/lua/evidence/test_image_evidence.lua:499`
- `ImageData:brightness` in `tests/lua/evidence/test_image_evidence.lua:605`
- `ImageData:getPixel` in `tests/lua/evidence/test_image_evidence.lua:606`
- `ImageData:brightness` in `tests/lua/evidence/test_image_evidence.lua:619`
- `ImageData:contrast` in `tests/lua/evidence/test_image_evidence.lua:629`
- `ImageData:contrast` in `tests/lua/evidence/test_image_evidence.lua:639`
- `ImageData:saturation` in `tests/lua/evidence/test_image_evidence.lua:649`
- `ImageData:saturation` in `tests/lua/evidence/test_image_evidence.lua:659`
- `ImageData:grayscale` in `tests/lua/evidence/test_image_evidence.lua:669`
- `ImageData:getPixel` in `tests/lua/evidence/test_image_evidence.lua:670`
- `ImageData:sepia` in `tests/lua/evidence/test_image_evidence.lua:681`
- `ImageData:invert` in `tests/lua/evidence/test_image_evidence.lua:691`
- `ImageData:threshold` in `tests/lua/evidence/test_image_evidence.lua:701`
- `ImageData:posterize` in `tests/lua/evidence/test_image_evidence.lua:711`
- `ImageData:blur` in `tests/lua/evidence/test_image_evidence.lua:721`
- `ImageData:sharpen` in `tests/lua/evidence/test_image_evidence.lua:731`
- `ImageData:gamma` in `tests/lua/evidence/test_image_evidence.lua:741`
- `ImageData:tint` in `tests/lua/evidence/test_image_evidence.lua:755`
- `ImageData:setPixel` in `tests/lua/evidence/test_image_evidence.lua:786`
- `ImageData:fill` in `tests/lua/evidence/test_image_evidence.lua:802`
- `ImageData:fill` in `tests/lua/evidence/test_image_evidence.lua:815`
- `ImageData:mapPixel` in `tests/lua/evidence/test_image_evidence.lua:816`
- `ImageData:fill` in `tests/lua/evidence/test_image_evidence.lua:832`
- `ImageData:crop` in `tests/lua/evidence/test_image_evidence.lua:833`
- `ImageData:fill` in `tests/lua/evidence/test_image_evidence.lua:847`
- `ImageData:resizeNearest` in `tests/lua/evidence/test_image_evidence.lua:848`
- `ImageData:setPixel` in `tests/lua/evidence/test_image_evidence.lua:862`
- `ImageData:flipHorizontal` in `tests/lua/evidence/test_image_evidence.lua:863`
- `ImageData:fill` in `tests/lua/evidence/test_image_evidence.lua:882`
- `ImageData:rotate90cw` in `tests/lua/evidence/test_image_evidence.lua:883`
- `ImageData:grayscale` in `tests/lua/evidence/test_image_evidence.lua:908`
- `ImageData:invert` in `tests/lua/evidence/test_image_evidence.lua:909`
- `ImageData:sepia` in `tests/lua/evidence/test_image_evidence.lua:910`
- `ImageData:brightness` in `tests/lua/evidence/test_image_evidence.lua:911`
- `ImageData:threshold` in `tests/lua/evidence/test_image_evidence.lua:912`
- `ImageData:posterize` in `tests/lua/evidence/test_image_evidence.lua:913`
- `ImageData:tint` in `tests/lua/evidence/test_image_evidence.lua:914`
- `ImageData:noise` in `tests/lua/evidence/test_image_evidence.lua:915`
- `ImageData:blur` in `tests/lua/evidence/test_image_evidence.lua:916`
- `ImageData:sharpen` in `tests/lua/evidence/test_image_evidence.lua:917`
- `ImageData:grayscale` in `tests/lua/evidence/test_image_evidence.lua:934`
- `ImageData:invert` in `tests/lua/evidence/test_image_evidence.lua:946`
- `ImageData:sepia` in `tests/lua/evidence/test_image_evidence.lua:958`
- `ImageData:brightness` in `tests/lua/evidence/test_image_evidence.lua:970`
- `ImageData:threshold` in `tests/lua/evidence/test_image_evidence.lua:982`
- `ImageData:posterize` in `tests/lua/evidence/test_image_evidence.lua:994`
- `ImageData:tint` in `tests/lua/evidence/test_image_evidence.lua:1006`
- `ImageData:noise` in `tests/lua/evidence/test_image_evidence.lua:1018`
- `ImageData:blur` in `tests/lua/evidence/test_image_evidence.lua:1030`
- `ImageData:sharpen` in `tests/lua/evidence/test_image_evidence.lua:1042`
- `ImageData:setPixel` in `tests/lua/evidence/test_image_evidence.lua:1076`
- `ImageData:fill` in `tests/lua/evidence/test_image_evidence.lua:1092`
- `ImageData:fill` in `tests/lua/evidence/test_image_evidence.lua:1105`
- `ImageData:mapPixel` in `tests/lua/evidence/test_image_evidence.lua:1106`
- `ImageData:fill` in `tests/lua/evidence/test_image_evidence.lua:1122`
- `ImageData:crop` in `tests/lua/evidence/test_image_evidence.lua:1123`
- `ImageData:fill` in `tests/lua/evidence/test_image_evidence.lua:1137`
- `ImageData:resizeNearest` in `tests/lua/evidence/test_image_evidence.lua:1138`
- `ImageData:setPixel` in `tests/lua/evidence/test_image_evidence.lua:1152`
- `ImageData:flipHorizontal` in `tests/lua/evidence/test_image_evidence.lua:1153`
- `ImageData:fill` in `tests/lua/evidence/test_image_evidence.lua:1172`
- `ImageData:rotate90cw` in `tests/lua/evidence/test_image_evidence.lua:1173`
- `ImageData:grayscale` in `tests/lua/evidence/test_image_evidence.lua:1198`
- `ImageData:invert` in `tests/lua/evidence/test_image_evidence.lua:1199`
- `ImageData:sepia` in `tests/lua/evidence/test_image_evidence.lua:1200`
- `ImageData:brightness` in `tests/lua/evidence/test_image_evidence.lua:1201`
- `ImageData:threshold` in `tests/lua/evidence/test_image_evidence.lua:1202`
- `ImageData:posterize` in `tests/lua/evidence/test_image_evidence.lua:1203`
- `ImageData:tint` in `tests/lua/evidence/test_image_evidence.lua:1204`
- `ImageData:noise` in `tests/lua/evidence/test_image_evidence.lua:1205`
- `ImageData:blur` in `tests/lua/evidence/test_image_evidence.lua:1206`
- `ImageData:sharpen` in `tests/lua/evidence/test_image_evidence.lua:1207`
- `ImageData:grayscale` in `tests/lua/evidence/test_image_evidence.lua:1224`
- `ImageData:invert` in `tests/lua/evidence/test_image_evidence.lua:1236`
- `ImageData:sepia` in `tests/lua/evidence/test_image_evidence.lua:1248`
- `ImageData:brightness` in `tests/lua/evidence/test_image_evidence.lua:1260`
- `ImageData:threshold` in `tests/lua/evidence/test_image_evidence.lua:1272`
- `ImageData:posterize` in `tests/lua/evidence/test_image_evidence.lua:1284`
- `ImageData:tint` in `tests/lua/evidence/test_image_evidence.lua:1296`
- `ImageData:noise` in `tests/lua/evidence/test_image_evidence.lua:1308`
- `ImageData:blur` in `tests/lua/evidence/test_image_evidence.lua:1320`
- `ImageData:sharpen` in `tests/lua/evidence/test_image_evidence.lua:1332`
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
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:64`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:77`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:78`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:97`
- `ImageData:drawLine` in `tests/lua/evidence/test_math_evidence.lua:98`
- `ImageData:drawRect` in `tests/lua/evidence/test_math_evidence.lua:99`
- `ImageData:drawCircle` in `tests/lua/evidence/test_math_evidence.lua:100`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:132`
- `ImageData:drawCircle` in `tests/lua/evidence/test_math_evidence.lua:133`
- `ImageData:paste` in `tests/lua/evidence/test_math_evidence.lua:134`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:152`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:153`
- `ImageData:noise` in `tests/lua/evidence/test_math_evidence.lua:154`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:169`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:170`
- `ImageData:flipHorizontal` in `tests/lua/evidence/test_math_evidence.lua:171`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:189`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:190`
- `ImageData:flipVertical` in `tests/lua/evidence/test_math_evidence.lua:191`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:211`
- `ImageData:rotate90cw` in `tests/lua/evidence/test_math_evidence.lua:212`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:226`
- `ImageData:drawRect` in `tests/lua/evidence/test_math_evidence.lua:227`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:228`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:243`
- `ImageData:drawCircle` in `tests/lua/evidence/test_math_evidence.lua:244`
- `ImageData:resizeNearest` in `tests/lua/evidence/test_math_evidence.lua:245`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:260`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:261`
- `ImageData:mapPixel` in `tests/lua/evidence/test_math_evidence.lua:262`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:283`
- `ImageData:drawCircle` in `tests/lua/evidence/test_math_evidence.lua:284`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:285`
- `ImageData:blur` in `tests/lua/evidence/test_math_evidence.lua:286`
- `lurek.math.perlinFast` in `tests/lua/evidence/test_math_evidence.lua:301`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:303`
- `lurek.math.simplex` in `tests/lua/evidence/test_math_evidence.lua:324`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:326`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:372`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:385`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:386`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:405`
- `ImageData:drawLine` in `tests/lua/evidence/test_math_evidence.lua:406`
- `ImageData:drawRect` in `tests/lua/evidence/test_math_evidence.lua:407`
- `ImageData:drawCircle` in `tests/lua/evidence/test_math_evidence.lua:408`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:440`
- `ImageData:drawCircle` in `tests/lua/evidence/test_math_evidence.lua:441`
- `ImageData:paste` in `tests/lua/evidence/test_math_evidence.lua:442`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:460`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:461`
- `ImageData:noise` in `tests/lua/evidence/test_math_evidence.lua:462`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:477`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:478`
- `ImageData:flipHorizontal` in `tests/lua/evidence/test_math_evidence.lua:479`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:497`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:498`
- `ImageData:flipVertical` in `tests/lua/evidence/test_math_evidence.lua:499`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:519`
- `ImageData:rotate90cw` in `tests/lua/evidence/test_math_evidence.lua:520`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:534`
- `ImageData:drawRect` in `tests/lua/evidence/test_math_evidence.lua:535`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:536`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:551`
- `ImageData:drawCircle` in `tests/lua/evidence/test_math_evidence.lua:552`
- `ImageData:resizeNearest` in `tests/lua/evidence/test_math_evidence.lua:553`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:568`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:569`
- `ImageData:mapPixel` in `tests/lua/evidence/test_math_evidence.lua:570`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:591`
- `ImageData:drawCircle` in `tests/lua/evidence/test_math_evidence.lua:592`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:593`
- `ImageData:blur` in `tests/lua/evidence/test_math_evidence.lua:594`
- `lurek.math.perlinFast` in `tests/lua/evidence/test_math_evidence.lua:609`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:611`
- `lurek.math.simplex` in `tests/lua/evidence/test_math_evidence.lua:632`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:634`
- `NoiseGenerator:fbm` in `tests/lua/evidence/test_math_evidence.lua:1327`
- `NoiseGenerator:worley2d` in `tests/lua/evidence/test_math_evidence.lua:1347`
- `NoiseGenerator:ridged` in `tests/lua/evidence/test_math_evidence.lua:1367`
- `NoiseGenerator:turbulence` in `tests/lua/evidence/test_math_evidence.lua:1387`
- `NoiseGenerator:fbm` in `tests/lua/evidence/test_math_evidence.lua:1469`
- `NoiseGenerator:worley2d` in `tests/lua/evidence/test_math_evidence.lua:1489`
- `NoiseGenerator:ridged` in `tests/lua/evidence/test_math_evidence.lua:1509`
- `NoiseGenerator:turbulence` in `tests/lua/evidence/test_math_evidence.lua:1529`
- `Minimap:setTerrainColor` in `tests/lua/evidence/test_minimap_evidence.lua:20`
- `Minimap:setTerrain` in `tests/lua/evidence/test_minimap_evidence.lua:21`
- `Minimap:setTerrain` in `tests/lua/evidence/test_minimap_evidence.lua:77`
- `Minimap:setTerrainColor` in `tests/lua/evidence/test_minimap_evidence.lua:147`
- `Minimap:setTerrain` in `tests/lua/evidence/test_minimap_evidence.lua:148`
- `Minimap:setTerrain` in `tests/lua/evidence/test_minimap_evidence.lua:204`
- `ParticleSystem:addAttractor` in `tests/lua/evidence/test_particle_evidence.lua:170`
- `ParticleSystem:addAttractor` in `tests/lua/evidence/test_particle_evidence.lua:382`
- `lurek.pathfind.newUnitPathfinder` in `tests/lua/evidence/test_pathfind_evidence.lua:72`
- `lurek.pathfind.newUnitPathfinder` in `tests/lua/evidence/test_pathfind_evidence.lua:97`
- `UnitPathfinder:findPath` in `tests/lua/evidence/test_pathfind_evidence.lua:98`
- `FlowField:calculate` in `tests/lua/evidence/test_pathfind_evidence.lua:121`
- `LuaZone:setGravityZero` in `tests/lua/evidence/test_physics_evidence.lua:222`
- `LuaZone:setGravityZero` in `tests/lua/evidence/test_physics_evidence.lua:501`
- `LuaCellular:fillRect` in `tests/lua/evidence/test_physics_evidence.lua:564`
- `LuaCellular:stepN` in `tests/lua/evidence/test_physics_evidence.lua:565`
- `LuaCellular:toImageData` in `tests/lua/evidence/test_physics_evidence.lua:566`
- `LuaCellular:fillRect` in `tests/lua/evidence/test_physics_evidence.lua:619`
- `LuaCellular:stepN` in `tests/lua/evidence/test_physics_evidence.lua:620`
- `LuaCellular:toImageData` in `tests/lua/evidence/test_physics_evidence.lua:621`
- `Raycaster:castRaysFlat` in `tests/lua/evidence/test_raycaster_evidence.lua:19`
- `Raycaster:castRaysFlat` in `tests/lua/evidence/test_raycaster_evidence.lua:100`
- `LuaTerrain:fillAll` in `tests/lua/evidence/test_render_evidence.lua:190`
- `LuaTerrain:fillCircle` in `tests/lua/evidence/test_render_evidence.lua:191`
- `LuaTerrain:toImageData` in `tests/lua/evidence/test_render_evidence.lua:192`
- `LuaTerrain:fillAll` in `tests/lua/evidence/test_render_evidence.lua:414`
- `LuaTerrain:fillCircle` in `tests/lua/evidence/test_render_evidence.lua:415`
- `LuaTerrain:toImageData` in `tests/lua/evidence/test_render_evidence.lua:416`
- `ImageData:fill` in `tests/lua/evidence/test_render_evidence.lua:478`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:479`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:496`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:512`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:531`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:551`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:573`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:588`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:670`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:693`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:714`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:738`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:756`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:775`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:794`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:810`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:830`
- `ImageData:brightness` in `tests/lua/evidence/test_render_evidence.lua:872`
- `ImageData:contrast` in `tests/lua/evidence/test_render_evidence.lua:873`
- `ImageData:grayscale` in `tests/lua/evidence/test_render_evidence.lua:874`
- `ImageData:sepia` in `tests/lua/evidence/test_render_evidence.lua:875`
- `ImageData:invert` in `tests/lua/evidence/test_render_evidence.lua:876`
- `ImageData:threshold` in `tests/lua/evidence/test_render_evidence.lua:877`
- `ImageData:posterize` in `tests/lua/evidence/test_render_evidence.lua:878`
- `ImageData:tint` in `tests/lua/evidence/test_render_evidence.lua:879`
- `ImageData:saturation` in `tests/lua/evidence/test_render_evidence.lua:880`
- `ImageData:gamma` in `tests/lua/evidence/test_render_evidence.lua:881`
- `ImageData:noise` in `tests/lua/evidence/test_render_evidence.lua:882`
- `ImageData:flipHorizontal` in `tests/lua/evidence/test_render_evidence.lua:883`
- `ImageData:flipVertical` in `tests/lua/evidence/test_render_evidence.lua:884`
- `ImageData:rotate90Cw` in `tests/lua/evidence/test_render_evidence.lua:885`
- `ImageData:blur` in `tests/lua/evidence/test_render_evidence.lua:886`
- `ImageData:sharpen` in `tests/lua/evidence/test_render_evidence.lua:887`
- `ImageData:crop` in `tests/lua/evidence/test_render_evidence.lua:888`
- `ImageData:resizeNearest` in `tests/lua/evidence/test_render_evidence.lua:889`
- `TileMap:setTile` in `tests/lua/evidence/test_render_evidence.lua:950`
- `ImageData:fill` in `tests/lua/evidence/test_render_evidence.lua:1000`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:1001`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:1018`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:1034`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:1053`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:1073`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:1095`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:1110`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:1192`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:1215`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:1236`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:1260`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:1278`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:1297`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:1316`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:1332`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:1352`
- `ImageData:brightness` in `tests/lua/evidence/test_render_evidence.lua:1394`
- `ImageData:contrast` in `tests/lua/evidence/test_render_evidence.lua:1395`
- `ImageData:grayscale` in `tests/lua/evidence/test_render_evidence.lua:1396`
- `ImageData:sepia` in `tests/lua/evidence/test_render_evidence.lua:1397`
- `ImageData:invert` in `tests/lua/evidence/test_render_evidence.lua:1398`
- `ImageData:threshold` in `tests/lua/evidence/test_render_evidence.lua:1399`
- `ImageData:posterize` in `tests/lua/evidence/test_render_evidence.lua:1400`
- `ImageData:tint` in `tests/lua/evidence/test_render_evidence.lua:1401`
- `ImageData:saturation` in `tests/lua/evidence/test_render_evidence.lua:1402`
- `ImageData:gamma` in `tests/lua/evidence/test_render_evidence.lua:1403`
- `ImageData:noise` in `tests/lua/evidence/test_render_evidence.lua:1404`
- `ImageData:flipHorizontal` in `tests/lua/evidence/test_render_evidence.lua:1405`
- `ImageData:flipVertical` in `tests/lua/evidence/test_render_evidence.lua:1406`
- `ImageData:rotate90Cw` in `tests/lua/evidence/test_render_evidence.lua:1407`
- `ImageData:blur` in `tests/lua/evidence/test_render_evidence.lua:1408`
- `ImageData:sharpen` in `tests/lua/evidence/test_render_evidence.lua:1409`
- `ImageData:crop` in `tests/lua/evidence/test_render_evidence.lua:1410`
- `ImageData:resizeNearest` in `tests/lua/evidence/test_render_evidence.lua:1411`
- `TileMap:setTile` in `tests/lua/evidence/test_render_evidence.lua:1472`
- `NavGrid:setBlocked` in `tests/lua/evidence/test_render_evidence.lua:1512`
- `Pathfinder:findPath` in `tests/lua/evidence/test_render_evidence.lua:1514`
- `NoiseGenerator:fbm` in `tests/lua/evidence/test_render_evidence.lua:1573`
- `Minimap:setTerrain` in `tests/lua/evidence/test_render_evidence.lua:1575`
- `NoiseGenerator:fbm` in `tests/lua/evidence/test_render_evidence.lua:1623`
- `Raycaster:castRays` in `tests/lua/evidence/test_render_evidence.lua:1626`
- `NdArray:fill` in `tests/lua/evidence/test_render_evidence.lua:1798`
- `NdArray:sum` in `tests/lua/evidence/test_render_evidence.lua:1799`
- `DataFrame:addColumn` in `tests/lua/evidence/test_render_evidence.lua:1814`
- `World:spawn` in `tests/lua/evidence/test_render_evidence.lua:1830`
- `World:isAlive` in `tests/lua/evidence/test_render_evidence.lua:1831`
- `World:getEntityCount` in `tests/lua/evidence/test_render_evidence.lua:1832`
- `NdArray:fill` in `tests/lua/evidence/test_render_evidence.lua:1950`
- `NdArray:sum` in `tests/lua/evidence/test_render_evidence.lua:1951`
- `DataFrame:addColumn` in `tests/lua/evidence/test_render_evidence.lua:1966`
- `World:spawn` in `tests/lua/evidence/test_render_evidence.lua:1982`
- `World:isAlive` in `tests/lua/evidence/test_render_evidence.lua:1983`
- `World:getEntityCount` in `tests/lua/evidence/test_render_evidence.lua:1984`
- `ImageData:drawRect` in `tests/lua/evidence/test_render_evidence.lua:2255`
- `ImageData:drawCircle` in `tests/lua/evidence/test_render_evidence.lua:2256`
- `ImageData:drawRect` in `tests/lua/evidence/test_render_evidence.lua:2283`
- `ImageData:drawRect` in `tests/lua/evidence/test_render_evidence.lua:2365`
- `ImageData:drawCircle` in `tests/lua/evidence/test_render_evidence.lua:2366`
- `ImageData:drawRect` in `tests/lua/evidence/test_render_evidence.lua:2393`
- `ImageData:drawRect` in `tests/lua/evidence/test_render_evidence.lua:2500`
- `ImageData:drawLine` in `tests/lua/evidence/test_render_evidence.lua:2501`
- `ImageData:drawCircle` in `tests/lua/evidence/test_render_evidence.lua:2502`
- `ImageData:drawRect` in `tests/lua/evidence/test_render_evidence.lua:2535`
- `ImageData:drawCircle` in `tests/lua/evidence/test_render_evidence.lua:2536`
- `ImageData:drawLine` in `tests/lua/evidence/test_render_evidence.lua:2537`
- `ImageData:drawLine` in `tests/lua/evidence/test_render_evidence.lua:2566`
- `ImageData:drawCircle` in `tests/lua/evidence/test_render_evidence.lua:2583`
- `ImageData:drawLine` in `tests/lua/evidence/test_render_evidence.lua:2584`
- `ImageData:drawRect` in `tests/lua/evidence/test_render_evidence.lua:2657`
- `ImageData:drawLine` in `tests/lua/evidence/test_render_evidence.lua:2658`
- `ImageData:drawCircle` in `tests/lua/evidence/test_render_evidence.lua:2659`
- `ImageData:drawRect` in `tests/lua/evidence/test_render_evidence.lua:2692`
- `ImageData:drawCircle` in `tests/lua/evidence/test_render_evidence.lua:2693`
- `ImageData:drawLine` in `tests/lua/evidence/test_render_evidence.lua:2694`
- `ImageData:drawLine` in `tests/lua/evidence/test_render_evidence.lua:2723`
- `ImageData:drawCircle` in `tests/lua/evidence/test_render_evidence.lua:2740`
- `ImageData:drawLine` in `tests/lua/evidence/test_render_evidence.lua:2741`
- `Skeleton:addBone` in `tests/lua/evidence/test_spine_evidence.lua:10`
- `Skeleton:addChildBone` in `tests/lua/evidence/test_spine_evidence.lua:11`
- `Skeleton:addSlot` in `tests/lua/evidence/test_spine_evidence.lua:12`
- `Skeleton:addBone` in `tests/lua/evidence/test_spine_evidence.lua:45`
- `Skeleton:addChildBone` in `tests/lua/evidence/test_spine_evidence.lua:46`
- `Skeleton:addBone` in `tests/lua/evidence/test_spine_evidence.lua:87`
- `Skeleton:addChildBone` in `tests/lua/evidence/test_spine_evidence.lua:88`
- `Skeleton:addSlot` in `tests/lua/evidence/test_spine_evidence.lua:89`
- `Skeleton:addBone` in `tests/lua/evidence/test_spine_evidence.lua:122`
- `Skeleton:addChildBone` in `tests/lua/evidence/test_spine_evidence.lua:123`
- `lurek.ui.loadLayout` in `tests/lua/evidence/test_ui_evidence.lua:20`
- `lurek.ui.renderToImage` in `tests/lua/evidence/test_ui_evidence.lua:21`
- `lurek.ui.loadLayout` in `tests/lua/evidence/test_ui_evidence.lua:46`
- `lurek.ui.renderToImage` in `tests/lua/evidence/test_ui_evidence.lua:47`
- `lurek.ui.loadLayout` in `tests/lua/evidence/test_ui_evidence.lua:102`
- `lurek.ui.renderToImage` in `tests/lua/evidence/test_ui_evidence.lua:103`
- `lurek.ui.loadLayout` in `tests/lua/evidence/test_ui_evidence.lua:128`
- `lurek.ui.renderToImage` in `tests/lua/evidence/test_ui_evidence.lua:129`
- `lurek.ui.newLineChart` in `tests/lua/evidence/test_ui_evidence.lua:173`
- `LineChart:addSeries` in `tests/lua/evidence/test_ui_evidence.lua:176`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:177`
- `lurek.ui.newBarChart` in `tests/lua/evidence/test_ui_evidence.lua:180`
- `lurek.ui.newScatterPlot` in `tests/lua/evidence/test_ui_evidence.lua:181`
- `lurek.ui.newPieChart` in `tests/lua/evidence/test_ui_evidence.lua:182`
- `lurek.ui.newAreaChart` in `tests/lua/evidence/test_ui_evidence.lua:183`
- `lurek.ui.newBarChart` in `tests/lua/evidence/test_ui_evidence.lua:196`
- `BarChart:addSeries` in `tests/lua/evidence/test_ui_evidence.lua:197`
- `BarChart:addCategory` in `tests/lua/evidence/test_ui_evidence.lua:198`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:199`
- `lurek.ui.newScatterPlot` in `tests/lua/evidence/test_ui_evidence.lua:216`
- `ScatterPlot:addSeries` in `tests/lua/evidence/test_ui_evidence.lua:219`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:220`
- `lurek.ui.newPieChart` in `tests/lua/evidence/test_ui_evidence.lua:241`
- `PieChart:addSegment` in `tests/lua/evidence/test_ui_evidence.lua:242`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:243`
- `lurek.ui.newAreaChart` in `tests/lua/evidence/test_ui_evidence.lua:258`
- `AreaChart:addLayer` in `tests/lua/evidence/test_ui_evidence.lua:260`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:261`
- `lurek.ui.newLineChart` in `tests/lua/evidence/test_ui_evidence.lua:292`
- `LineChart:addSeries` in `tests/lua/evidence/test_ui_evidence.lua:295`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:296`
- `lurek.ui.newBarChart` in `tests/lua/evidence/test_ui_evidence.lua:299`
- `lurek.ui.newScatterPlot` in `tests/lua/evidence/test_ui_evidence.lua:300`
- `lurek.ui.newPieChart` in `tests/lua/evidence/test_ui_evidence.lua:301`
- `lurek.ui.newAreaChart` in `tests/lua/evidence/test_ui_evidence.lua:302`
- `lurek.ui.newBarChart` in `tests/lua/evidence/test_ui_evidence.lua:315`
- `BarChart:addSeries` in `tests/lua/evidence/test_ui_evidence.lua:316`
- `BarChart:addCategory` in `tests/lua/evidence/test_ui_evidence.lua:317`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:318`
- `lurek.ui.newScatterPlot` in `tests/lua/evidence/test_ui_evidence.lua:335`
- `ScatterPlot:addSeries` in `tests/lua/evidence/test_ui_evidence.lua:338`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:339`
- `lurek.ui.newPieChart` in `tests/lua/evidence/test_ui_evidence.lua:360`
- `PieChart:addSegment` in `tests/lua/evidence/test_ui_evidence.lua:361`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:362`
- `lurek.ui.newAreaChart` in `tests/lua/evidence/test_ui_evidence.lua:377`
- `AreaChart:addLayer` in `tests/lua/evidence/test_ui_evidence.lua:379`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:380`
- `lurek.ui.drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:414`
- `lurek.ui.getRoot` in `tests/lua/evidence/test_ui_evidence.lua:415`
- `lurek.ui.newButton` in `tests/lua/evidence/test_ui_evidence.lua:416`
- `lurek.ui.newLabel` in `tests/lua/evidence/test_ui_evidence.lua:417`
- `lurek.ui.drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:448`
- `lurek.ui.getRoot` in `tests/lua/evidence/test_ui_evidence.lua:449`
- `lurek.ui.newProgressBar` in `tests/lua/evidence/test_ui_evidence.lua:450`
- `lurek.ui.drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:484`
- `lurek.ui.getRoot` in `tests/lua/evidence/test_ui_evidence.lua:485`
- `lurek.ui.newButton` in `tests/lua/evidence/test_ui_evidence.lua:486`
- `lurek.ui.newLabel` in `tests/lua/evidence/test_ui_evidence.lua:487`
- `lurek.ui.newPanel` in `tests/lua/evidence/test_ui_evidence.lua:488`
- `lurek.ui.newSlider` in `tests/lua/evidence/test_ui_evidence.lua:489`
- `lurek.ui.drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:545`
- `lurek.ui.getRoot` in `tests/lua/evidence/test_ui_evidence.lua:546`
- `lurek.ui.newButton` in `tests/lua/evidence/test_ui_evidence.lua:547`
- `lurek.ui.newLabel` in `tests/lua/evidence/test_ui_evidence.lua:548`
- `lurek.ui.drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:579`
- `lurek.ui.getRoot` in `tests/lua/evidence/test_ui_evidence.lua:580`
- `lurek.ui.newProgressBar` in `tests/lua/evidence/test_ui_evidence.lua:581`
- `lurek.ui.drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:615`
- `lurek.ui.getRoot` in `tests/lua/evidence/test_ui_evidence.lua:616`
- `lurek.ui.newButton` in `tests/lua/evidence/test_ui_evidence.lua:617`
- `lurek.ui.newLabel` in `tests/lua/evidence/test_ui_evidence.lua:618`
- `lurek.ui.newPanel` in `tests/lua/evidence/test_ui_evidence.lua:619`
- `lurek.ui.newSlider` in `tests/lua/evidence/test_ui_evidence.lua:620`
- `lurek.ecs.Universe` in `tests/lua/integration/test_ai_ecs_scene.lua:7`
- `lurek.ecs.Universe` in `tests/lua/integration/test_ai_ecs_scene.lua:58`
- `lurek.compute.newBuffer` in `tests/lua/integration/test_data_compute.lua:9`
- `lurek.runtime.getClipboardText` in `tests/lua/integration/test_data_system.lua:11`
- `lurek.runtime.getOS` in `tests/lua/integration/test_data_system.lua:12`
- `lurek.runtime.setClipboardText` in `tests/lua/integration/test_data_system.lua:13`
- `lurek.runtime.getOS` in `tests/lua/integration/test_data_system.lua:85`
- `lurek.runtime.setClipboardText` in `tests/lua/integration/test_data_system.lua:96`
- `lurek.runtime.getClipboardText` in `tests/lua/integration/test_data_system.lua:97`
- `lurek.devtools.info` in `tests/lua/integration/test_devtools.lua:26`
- `lurek.devtools.info` in `tests/lua/integration/test_devtools.lua:89`
- `lurek.devtools.info` in `tests/lua/integration/test_devtools.lua:129`
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
- `lurek.ui.newLabel` in `tests/lua/integration/test_i18n_ui.lua:10`
- `lurek.i18n.setLocale` in `tests/lua/integration/test_i18n_ui.lua:37`
- `lurek.ui.setText` in `tests/lua/integration/test_i18n_ui.lua:38`
- `lurek.i18n.get` in `tests/lua/integration/test_i18n_ui.lua:59`
- `lurek.input.getMousePosition` in `tests/lua/integration/test_input_camera.lua:7`
- `lurek.camera.newCamera` in `tests/lua/integration/test_input_camera.lua:8`
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
- `lurek.camera.newCamera` in `tests/lua/integration/test_render_camera.lua:8`
- `lurek.runtime.getOS` in `tests/lua/integration/test_runtime_system.lua:7`
- `lurek.runtime.clipboard` in `tests/lua/integration/test_runtime_system.lua:8`
- `lurek.runtime.getClipboardText` in `tests/lua/integration/test_runtime_system.lua:9`
- `lurek.runtime.getInfo` in `tests/lua/integration/test_runtime_system.lua:10`
- `lurek.runtime.getVersion` in `tests/lua/integration/test_runtime_system.lua:11`
- `lurek.runtime.setClipboardText` in `tests/lua/integration/test_runtime_system.lua:12`
- `lurek.runtime.getOS` in `tests/lua/integration/test_runtime_system.lua:22`
- `lurek.runtime.getOS` in `tests/lua/integration/test_runtime_system.lua:29`
- `lurek.runtime.getOS` in `tests/lua/integration/test_runtime_system.lua:37`
- `lurek.runtime.getVersion` in `tests/lua/integration/test_runtime_system.lua:50`
- `lurek.runtime.getVersion` in `tests/lua/integration/test_runtime_system.lua:57`
- `lurek.runtime.getVersion` in `tests/lua/integration/test_runtime_system.lua:65`
- `lurek.runtime.getInfo` in `tests/lua/integration/test_runtime_system.lua:76`
- `lurek.runtime.getInfo` in `tests/lua/integration/test_runtime_system.lua:83`
- `lurek.runtime.getInfo` in `tests/lua/integration/test_runtime_system.lua:91`
- `lurek.runtime.getInfo` in `tests/lua/integration/test_runtime_system.lua:99`
- `lurek.runtime.getVersion` in `tests/lua/integration/test_runtime_system.lua:100`
- `lurek.runtime.getInfo` in `tests/lua/integration/test_runtime_system.lua:107`
- `lurek.runtime.getInfo` in `tests/lua/integration/test_runtime_system.lua:115`
- `lurek.runtime.setClipboardText` in `tests/lua/integration/test_runtime_system.lua:146`
- `lurek.runtime.getClipboardText` in `tests/lua/integration/test_runtime_system.lua:153`
- `lurek.runtime.getClipboardText` in `tests/lua/integration/test_runtime_system.lua:160`
- `lurek.tilemap.newTilemap` in `tests/lua/integration/test_save_tilemap.lua:9`
- `lurek.tilemap.setTile` in `tests/lua/integration/test_save_tilemap.lua:10`
- `lurek.tilemap.getTile` in `tests/lua/integration/test_save_tilemap.lua:11`
- `lurek.camera.newCamera` in `tests/lua/integration/test_scene_camera.lua:8`
- `lurek.tilemap.newTilemap` in `tests/lua/integration/test_tilemap_camera.lua:8`
- `lurek.tilemap.setTile` in `tests/lua/integration/test_tilemap_camera.lua:9`
- `lurek.tilemap.getTile` in `tests/lua/integration/test_tilemap_camera.lua:10`
- `lurek.camera.newCamera` in `tests/lua/integration/test_tilemap_camera.lua:11`
- `lurek.tilemap.clearTile` in `tests/lua/integration/test_tilemap_physics.lua:65`
- `lurek.math.pi` in `tests/lua/integration/test_timer_math.lua:8`
- `lurek.camera.newCamera` in `tests/lua/integration/test_tween_camera.lua:9`
- `StateMachine:update` in `tests/lua/stress/test_ai_stress.lua:7`
- `StateMachine:update` in `tests/lua/stress/test_ai_stress.lua:27`
- `lurek.animation.newTimeline` in `tests/lua/stress/test_animation_stress.lua:6`
- `Timeline:addFrame` in `tests/lua/stress/test_animation_stress.lua:7`
- `lurek.animation.newTimeline` in `tests/lua/stress/test_animation_stress.lua:21`
- `Timeline:update` in `tests/lua/stress/test_animation_stress.lua:22`
- `lurek.animation.newTimeline` in `tests/lua/stress/test_animation_stress.lua:50`
- `Timeline:addFrame` in `tests/lua/stress/test_animation_stress.lua:51`
- `Timeline:seek` in `tests/lua/stress/test_animation_stress.lua:52`
- `lurek.camera.newCamera` in `tests/lua/stress/test_camera_stress.lua:6`
- `Camera:setPosition` in `tests/lua/stress/test_camera_stress.lua:7`
- `lurek.camera.newCamera` in `tests/lua/stress/test_camera_stress.lua:21`
- `Camera:setZoom` in `tests/lua/stress/test_camera_stress.lua:22`
- `lurek.camera.newCamera` in `tests/lua/stress/test_camera_stress.lua:36`
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
- `DataFrame:addColumn` in `tests/lua/stress/test_dataframe_stress.lua:7`
- `DataFrame:addColumn` in `tests/lua/stress/test_dataframe_stress.lua:52`
- `DataFrame:addColumn` in `tests/lua/stress/test_dataframe_stress.lua:85`
- `Universe:set` in `tests/lua/stress/test_ecs_stress.lua:45`
- `lurek.ecs.defineBlueprint` in `tests/lua/stress/test_ecs_stress.lua:122`
- `lurek.ecs.spawnBulk` in `tests/lua/stress/test_ecs_stress.lua:123`
- `lurek.ecs.spawnBulk` in `tests/lua/stress/test_ecs_stress.lua:133`
- `lurek.ecs.spawnBulk` in `tests/lua/stress/test_ecs_stress.lua:144`
- `lurek.ecs.spawnBulk` in `tests/lua/stress/test_ecs_stress.lua:153`
- `lurek.event.new` in `tests/lua/stress/test_event_stress.lua:6`
- `Signal:connect` in `tests/lua/stress/test_event_stress.lua:7`
- `lurek.event.new` in `tests/lua/stress/test_event_stress.lua:36`
- `Signal:connect` in `tests/lua/stress/test_event_stress.lua:37`
- `Connection:disconnect` in `tests/lua/stress/test_event_stress.lua:38`
- `lurek.event.new` in `tests/lua/stress/test_event_stress.lua:53`
- `Signal:connect` in `tests/lua/stress/test_event_stress.lua:54`
- `Graph:addNode` in `tests/lua/stress/test_graph_stress.lua:7`
- `Graph:addEdge` in `tests/lua/stress/test_graph_stress.lua:8`
- `Graph:addNode` in `tests/lua/stress/test_graph_stress.lua:31`
- `Graph:addEdge` in `tests/lua/stress/test_graph_stress.lua:32`
- `Graph:createItem` in `tests/lua/stress/test_graph_stress.lua:71`
- `Graph:addItem` in `tests/lua/stress/test_graph_stress.lua:72`
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
- `UnitPathfinder:findPath` in `tests/lua/stress/test_pathfind_stress.lua:8`
- `NavGrid:setBlocked` in `tests/lua/stress/test_pathfind_stress.lua:21`
- `UnitPathfinder:findPath` in `tests/lua/stress/test_pathfind_stress.lua:22`
- `NavGrid:setBlocked` in `tests/lua/stress/test_pathfind_stress.lua:40`
- `UnitPathfinder:findPath` in `tests/lua/stress/test_pathfind_stress.lua:41`
- `UnitPathfinder:findPath` in `tests/lua/stress/test_pathfind_stress.lua:65`
- `NavGrid:setBlocked` in `tests/lua/stress/test_pathfind_stress.lua:87`
- `UnitPathfinder:findPath` in `tests/lua/stress/test_pathfind_stress.lua:88`
- `FlowField:calculate` in `tests/lua/stress/test_pathfind_stress.lua:122`
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
- `SaveManager:register` in `tests/lua/stress/test_save_stress.lua:7`
- `Universe:set` in `tests/lua/stress/test_scene_stress.lua:25`
- `lurek.serial.base64Encode` in `tests/lua/stress/test_serial_stress.lua:6`
- `lurek.serial.base64Decode` in `tests/lua/stress/test_serial_stress.lua:7`
- `lurek.serial.base64Encode` in `tests/lua/stress/test_serial_stress.lua:20`
- `lurek.serial.base64Decode` in `tests/lua/stress/test_serial_stress.lua:21`
- `Channel:tryPop` in `tests/lua/stress/test_thread_stress.lua:19`
- `Channel:tryPop` in `tests/lua/stress/test_thread_stress.lua:46`
- `Channel:tryPop` in `tests/lua/stress/test_thread_stress.lua:80`
- `TileMap:setTile` in `tests/lua/stress/test_tilemap_stress.lua:10`
- `TileMap:setTile` in `tests/lua/stress/test_tilemap_stress.lua:35`
- `TileMap:setTile` in `tests/lua/stress/test_tilemap_stress.lua:68`
- `TileMap:setTile` in `tests/lua/stress/test_tilemap_stress.lua:120`
- `lurek.tween.newTween` in `tests/lua/stress/test_tween_stress.lua:6`
- `Tween:setDuration` in `tests/lua/stress/test_tween_stress.lua:7`
- `Tween:setEasing` in `tests/lua/stress/test_tween_stress.lua:8`
- `Tween:setFrom` in `tests/lua/stress/test_tween_stress.lua:9`
- `Tween:setTo` in `tests/lua/stress/test_tween_stress.lua:10`
- `lurek.tween.newTween` in `tests/lua/stress/test_tween_stress.lua:42`
- `Tween:seek` in `tests/lua/stress/test_tween_stress.lua:43`
- `lurek.tween.newTween` in `tests/lua/stress/test_tween_stress.lua:62`
- `Tween:onComplete` in `tests/lua/stress/test_tween_stress.lua:63`
