# Lua API Test Coverage Report

**Generated**: 2026-04-23
**Mode**: hybrid
**Total API functions**: 4102

## Summary

| Metric | Value |
|--------|-------|
| Marker-covered | 431 |
| Heuristic-covered | 3578 |
| Total covered | 4048 |
| Coverage | 98.7% |

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
| terminal | 84 | 0 | 82 | 82 | 97.6% |
| ai | 292 | 7 | 279 | 286 | 97.9% |
| mods | 47 | 0 | 46 | 46 | 97.9% |
| physics | 193 | 29 | 160 | 189 | 97.9% |
| particle | 98 | 14 | 82 | 96 | 98.0% |
| render | 197 | 13 | 180 | 193 | 98.0% |
| effect | 158 | 7 | 148 | 155 | 98.1% |
| ecs | 61 | 7 | 53 | 60 | 98.4% |
| graph | 126 | 8 | 116 | 124 | 98.4% |
| compute | 77 | 17 | 59 | 76 | 98.7% |
| math | 223 | 65 | 155 | 220 | 98.7% |
| tilemap | 168 | 12 | 154 | 166 | 98.8% |
| pathfind | 90 | 8 | 81 | 89 | 98.9% |
| audio | 215 | 19 | 195 | 214 | 99.5% |
| animation | 53 | 10 | 43 | 53 | 100.0% |
| automation | 28 | 0 | 28 | 28 | 100.0% |
| camera | 47 | 4 | 43 | 47 | 100.0% |
| data | 61 | 10 | 51 | 61 | 100.0% |
| debugbridge | 14 | 14 | 0 | 14 | 100.0% |
| devtools | 48 | 33 | 15 | 48 | 100.0% |
| docs | 75 | 12 | 63 | 75 | 100.0% |
| engine | 10 | 1 | 9 | 10 | 100.0% |
| event | 26 | 4 | 22 | 26 | 100.0% |
| filesystem | 54 | 5 | 49 | 54 | 100.0% |
| globe | 53 | 5 | 48 | 53 | 100.0% |
| image | 80 | 12 | 68 | 80 | 100.0% |
| input | 81 | 0 | 81 | 81 | 100.0% |
| light | 86 | 1 | 85 | 86 | 100.0% |
| log | 18 | 0 | 18 | 18 | 100.0% |
| minimap | 76 | 7 | 69 | 76 | 100.0% |
| network | 47 | 2 | 45 | 47 | 100.0% |
| parallax | 44 | 2 | 42 | 44 | 100.0% |
| procgen | 29 | 2 | 27 | 29 | 100.0% |
| save | 26 | 5 | 21 | 26 | 100.0% |
| scene | 53 | 5 | 48 | 53 | 100.0% |
| serial | 10 | 2 | 8 | 10 | 100.0% |
| spine | 30 | 10 | 20 | 30 | 100.0% |
| sprite | 20 | 0 | 20 | 20 | 100.0% |
| timer | 47 | 4 | 43 | 47 | 100.0% |
| tween | 35 | 7 | 28 | 35 | 100.0% |
| ui | 371 | 16 | 355 | 371 | 100.0% |
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

### terminal (97.6%)

- `Terminal:set` (method)
- `Terminal:get` (method)

### ai (97.9%)

- `InfluenceMap:stampInfluence` (method)
- `TraitProfile:set` (method)
- `TraitProfile:get` (method)
- `TraitProfile:has` (method)
- `EmotionModel:add` (method)
- `EmotionModel:get` (method)

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

### render (98.0%)

- `lurek.render.arc` (function)
- `lurek.render.pop` (function)
- `SpriteBatch:add` (method)
- `Shape:arc` (method)

### effect (98.1%)

- `PostFxStack:add` (method)
- `PostFxStack:len` (method)
- `Overlay:triggerShake` (method)

### ecs (98.4%)

- `Universe:has` (method)

## Orphaned Markers (typos or removed APIs)

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
- `SoundData:drawWaveform` in `tests/lua/evidence/test_audio_evidence.lua:505`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:566`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:586`
- `SoundData:getSample` in `tests/lua/evidence/test_audio_evidence.lua:587`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:624`
- `SoundData:getSample` in `tests/lua/evidence/test_audio_evidence.lua:645`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:646`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:684`
- `SoundData:getSample` in `tests/lua/evidence/test_audio_evidence.lua:685`
- `SoundData:drawWaveform` in `tests/lua/evidence/test_audio_evidence.lua:686`
- `SoundData:getDuration` in `tests/lua/evidence/test_audio_evidence.lua:689`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:722`
- `SoundData:drawWaveform` in `tests/lua/evidence/test_audio_evidence.lua:723`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:754`
- `SoundData:drawWaveform` in `tests/lua/evidence/test_audio_evidence.lua:755`
- `SoundData:setSample` in `tests/lua/evidence/test_audio_evidence.lua:782`
- `SoundData:drawWaveform` in `tests/lua/evidence/test_audio_evidence.lua:783`
- `AudioBus:setVolume` in `tests/lua/evidence/test_audio_evidence.lua:846`
- `AudioBus:getVolume` in `tests/lua/evidence/test_audio_evidence.lua:847`
- `AudioBus:setPitch` in `tests/lua/evidence/test_audio_evidence.lua:879`
- `AudioBus:getPitch` in `tests/lua/evidence/test_audio_evidence.lua:880`
- `AudioBus:setVolume` in `tests/lua/evidence/test_audio_evidence.lua:909`
- `SoundData:getSample` in `tests/lua/evidence/test_audio_evidence.lua:911`
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
- `lurek.ui.newLineChart` in `tests/lua/evidence/test_charts_evidence.lua:11`
- `lurek.ui.newBarChart` in `tests/lua/evidence/test_charts_evidence.lua:35`
- `lurek.ui.newScatterPlot` in `tests/lua/evidence/test_charts_evidence.lua:58`
- `lurek.ui.newPieChart` in `tests/lua/evidence/test_charts_evidence.lua:85`
- `lurek.ui.newAreaChart` in `tests/lua/evidence/test_charts_evidence.lua:105`
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
- `ImageData:grayscale` in `tests/lua/evidence/test_effect_evidence.lua:526`
- `ImageData:getPixel` in `tests/lua/evidence/test_effect_evidence.lua:527`
- `ImageData:invert` in `tests/lua/evidence/test_effect_evidence.lua:539`
- `ImageData:getPixel` in `tests/lua/evidence/test_effect_evidence.lua:540`
- `ImageData:blur` in `tests/lua/evidence/test_effect_evidence.lua:554`
- `ImageData:sepia` in `tests/lua/evidence/test_effect_evidence.lua:564`
- `ImageData:grayscale` in `tests/lua/evidence/test_effect_evidence.lua:574`
- `ImageData:sepia` in `tests/lua/evidence/test_effect_evidence.lua:575`
- `ImageData:invert` in `tests/lua/evidence/test_effect_evidence.lua:576`
- `ImageData:blur` in `tests/lua/evidence/test_effect_evidence.lua:577`
- `ImageData:sharpen` in `tests/lua/evidence/test_effect_evidence.lua:578`
- `ImageData:brightness` in `tests/lua/evidence/test_effect_evidence.lua:579`
- `ImageData:contrast` in `tests/lua/evidence/test_effect_evidence.lua:580`
- `ImageData:threshold` in `tests/lua/evidence/test_effect_evidence.lua:581`
- `ImageData:posterize` in `tests/lua/evidence/test_effect_evidence.lua:618`
- `ImageData:gamma` in `tests/lua/evidence/test_effect_evidence.lua:619`
- `ImageData:tint` in `tests/lua/evidence/test_effect_evidence.lua:620`
- `ImageData:saturation` in `tests/lua/evidence/test_effect_evidence.lua:632`
- `ImageData:flipHorizontal` in `tests/lua/evidence/test_effect_evidence.lua:633`
- `lurek.ui.loadLayout` in `tests/lua/evidence/test_gui_evidence.lua:11`
- `lurek.ui.renderToImage` in `tests/lua/evidence/test_gui_evidence.lua:12`
- `lurek.ui.loadLayout` in `tests/lua/evidence/test_gui_evidence.lua:32`
- `lurek.ui.renderToImage` in `tests/lua/evidence/test_gui_evidence.lua:33`
- `lurek.ui.loadLayout` in `tests/lua/evidence/test_gui_evidence.lua:66`
- `lurek.ui.renderToImage` in `tests/lua/evidence/test_gui_evidence.lua:67`
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
- `ImageData:fill` in `tests/lua/evidence/test_imagedata_evidence.lua:12`
- `ImageData:setPixel` in `tests/lua/evidence/test_imagedata_evidence.lua:13`
- `ImageData:getPixel` in `tests/lua/evidence/test_imagedata_evidence.lua:14`
- `ImageData:drawRect` in `tests/lua/evidence/test_imagedata_evidence.lua:42`
- `ImageData:drawCircle` in `tests/lua/evidence/test_imagedata_evidence.lua:43`
- `ImageData:drawLine` in `tests/lua/evidence/test_imagedata_evidence.lua:44`
- `ImageData:blur` in `tests/lua/evidence/test_imagedata_evidence.lua:61`
- `ImageData:brightness` in `tests/lua/evidence/test_imagedata_evidence.lua:62`
- `ImageData:contrast` in `tests/lua/evidence/test_imagedata_evidence.lua:63`
- `ImageData:grayscale` in `tests/lua/evidence/test_imagedata_evidence.lua:64`
- `ImageData:getDimensions` in `tests/lua/evidence/test_imagedata_evidence.lua:97`
- `ImageData:crop` in `tests/lua/evidence/test_imagedata_evidence.lua:98`
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
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:111`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:124`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:125`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:144`
- `ImageData:drawLine` in `tests/lua/evidence/test_math_evidence.lua:145`
- `ImageData:drawRect` in `tests/lua/evidence/test_math_evidence.lua:146`
- `ImageData:drawCircle` in `tests/lua/evidence/test_math_evidence.lua:147`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:179`
- `ImageData:drawCircle` in `tests/lua/evidence/test_math_evidence.lua:180`
- `ImageData:paste` in `tests/lua/evidence/test_math_evidence.lua:181`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:199`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:200`
- `ImageData:noise` in `tests/lua/evidence/test_math_evidence.lua:201`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:216`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:217`
- `ImageData:flipHorizontal` in `tests/lua/evidence/test_math_evidence.lua:218`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:236`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:237`
- `ImageData:flipVertical` in `tests/lua/evidence/test_math_evidence.lua:238`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:258`
- `ImageData:rotate90cw` in `tests/lua/evidence/test_math_evidence.lua:259`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:273`
- `ImageData:drawRect` in `tests/lua/evidence/test_math_evidence.lua:274`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:275`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:290`
- `ImageData:drawCircle` in `tests/lua/evidence/test_math_evidence.lua:291`
- `ImageData:resizeNearest` in `tests/lua/evidence/test_math_evidence.lua:292`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:307`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:308`
- `ImageData:mapPixel` in `tests/lua/evidence/test_math_evidence.lua:309`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:330`
- `ImageData:drawCircle` in `tests/lua/evidence/test_math_evidence.lua:331`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:332`
- `ImageData:blur` in `tests/lua/evidence/test_math_evidence.lua:333`
- `lurek.math.perlinFast` in `tests/lua/evidence/test_math_evidence.lua:348`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:350`
- `lurek.math.simplex` in `tests/lua/evidence/test_math_evidence.lua:371`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:373`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:419`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:432`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:433`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:452`
- `ImageData:drawLine` in `tests/lua/evidence/test_math_evidence.lua:453`
- `ImageData:drawRect` in `tests/lua/evidence/test_math_evidence.lua:454`
- `ImageData:drawCircle` in `tests/lua/evidence/test_math_evidence.lua:455`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:487`
- `ImageData:drawCircle` in `tests/lua/evidence/test_math_evidence.lua:488`
- `ImageData:paste` in `tests/lua/evidence/test_math_evidence.lua:489`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:507`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:508`
- `ImageData:noise` in `tests/lua/evidence/test_math_evidence.lua:509`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:524`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:525`
- `ImageData:flipHorizontal` in `tests/lua/evidence/test_math_evidence.lua:526`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:544`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:545`
- `ImageData:flipVertical` in `tests/lua/evidence/test_math_evidence.lua:546`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:566`
- `ImageData:rotate90cw` in `tests/lua/evidence/test_math_evidence.lua:567`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:581`
- `ImageData:drawRect` in `tests/lua/evidence/test_math_evidence.lua:582`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:583`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:598`
- `ImageData:drawCircle` in `tests/lua/evidence/test_math_evidence.lua:599`
- `ImageData:resizeNearest` in `tests/lua/evidence/test_math_evidence.lua:600`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:615`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:616`
- `ImageData:mapPixel` in `tests/lua/evidence/test_math_evidence.lua:617`
- `ImageData:fill` in `tests/lua/evidence/test_math_evidence.lua:638`
- `ImageData:drawCircle` in `tests/lua/evidence/test_math_evidence.lua:639`
- `ImageData:crop` in `tests/lua/evidence/test_math_evidence.lua:640`
- `ImageData:blur` in `tests/lua/evidence/test_math_evidence.lua:641`
- `lurek.math.perlinFast` in `tests/lua/evidence/test_math_evidence.lua:656`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:658`
- `lurek.math.simplex` in `tests/lua/evidence/test_math_evidence.lua:679`
- `ImageData:setPixel` in `tests/lua/evidence/test_math_evidence.lua:681`
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
- `ImageData:fill` in `tests/lua/evidence/test_render_evidence.lua:466`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:467`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:484`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:500`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:519`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:539`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:561`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:576`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:658`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:681`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:702`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:726`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:744`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:763`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:782`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:798`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:818`
- `ImageData:brightness` in `tests/lua/evidence/test_render_evidence.lua:860`
- `ImageData:contrast` in `tests/lua/evidence/test_render_evidence.lua:861`
- `ImageData:grayscale` in `tests/lua/evidence/test_render_evidence.lua:862`
- `ImageData:sepia` in `tests/lua/evidence/test_render_evidence.lua:863`
- `ImageData:invert` in `tests/lua/evidence/test_render_evidence.lua:864`
- `ImageData:threshold` in `tests/lua/evidence/test_render_evidence.lua:865`
- `ImageData:posterize` in `tests/lua/evidence/test_render_evidence.lua:866`
- `ImageData:tint` in `tests/lua/evidence/test_render_evidence.lua:867`
- `ImageData:saturation` in `tests/lua/evidence/test_render_evidence.lua:868`
- `ImageData:gamma` in `tests/lua/evidence/test_render_evidence.lua:869`
- `ImageData:noise` in `tests/lua/evidence/test_render_evidence.lua:870`
- `ImageData:flipHorizontal` in `tests/lua/evidence/test_render_evidence.lua:871`
- `ImageData:flipVertical` in `tests/lua/evidence/test_render_evidence.lua:872`
- `ImageData:rotate90Cw` in `tests/lua/evidence/test_render_evidence.lua:873`
- `ImageData:blur` in `tests/lua/evidence/test_render_evidence.lua:874`
- `ImageData:sharpen` in `tests/lua/evidence/test_render_evidence.lua:875`
- `ImageData:crop` in `tests/lua/evidence/test_render_evidence.lua:876`
- `ImageData:resizeNearest` in `tests/lua/evidence/test_render_evidence.lua:877`
- `ImageData:fill` in `tests/lua/evidence/test_render_evidence.lua:982`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:983`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:1000`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:1016`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:1035`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:1055`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:1077`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:1092`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:1174`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:1197`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:1218`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:1242`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:1260`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:1279`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:1298`
- `SoundData:setSample` in `tests/lua/evidence/test_render_evidence.lua:1314`
- `ImageData:setPixel` in `tests/lua/evidence/test_render_evidence.lua:1334`
- `ImageData:brightness` in `tests/lua/evidence/test_render_evidence.lua:1376`
- `ImageData:contrast` in `tests/lua/evidence/test_render_evidence.lua:1377`
- `ImageData:grayscale` in `tests/lua/evidence/test_render_evidence.lua:1378`
- `ImageData:sepia` in `tests/lua/evidence/test_render_evidence.lua:1379`
- `ImageData:invert` in `tests/lua/evidence/test_render_evidence.lua:1380`
- `ImageData:threshold` in `tests/lua/evidence/test_render_evidence.lua:1381`
- `ImageData:posterize` in `tests/lua/evidence/test_render_evidence.lua:1382`
- `ImageData:tint` in `tests/lua/evidence/test_render_evidence.lua:1383`
- `ImageData:saturation` in `tests/lua/evidence/test_render_evidence.lua:1384`
- `ImageData:gamma` in `tests/lua/evidence/test_render_evidence.lua:1385`
- `ImageData:noise` in `tests/lua/evidence/test_render_evidence.lua:1386`
- `ImageData:flipHorizontal` in `tests/lua/evidence/test_render_evidence.lua:1387`
- `ImageData:flipVertical` in `tests/lua/evidence/test_render_evidence.lua:1388`
- `ImageData:rotate90Cw` in `tests/lua/evidence/test_render_evidence.lua:1389`
- `ImageData:blur` in `tests/lua/evidence/test_render_evidence.lua:1390`
- `ImageData:sharpen` in `tests/lua/evidence/test_render_evidence.lua:1391`
- `ImageData:crop` in `tests/lua/evidence/test_render_evidence.lua:1392`
- `ImageData:resizeNearest` in `tests/lua/evidence/test_render_evidence.lua:1393`
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
- `ImageData:drawRect` in `tests/lua/evidence/test_render_evidence.lua:2237`
- `ImageData:drawCircle` in `tests/lua/evidence/test_render_evidence.lua:2238`
- `ImageData:drawRect` in `tests/lua/evidence/test_render_evidence.lua:2265`
- `ImageData:drawRect` in `tests/lua/evidence/test_render_evidence.lua:2347`
- `ImageData:drawCircle` in `tests/lua/evidence/test_render_evidence.lua:2348`
- `ImageData:drawRect` in `tests/lua/evidence/test_render_evidence.lua:2375`
- `ImageData:drawRect` in `tests/lua/evidence/test_render_evidence.lua:2482`
- `ImageData:drawLine` in `tests/lua/evidence/test_render_evidence.lua:2483`
- `ImageData:drawCircle` in `tests/lua/evidence/test_render_evidence.lua:2484`
- `ImageData:drawRect` in `tests/lua/evidence/test_render_evidence.lua:2517`
- `ImageData:drawCircle` in `tests/lua/evidence/test_render_evidence.lua:2518`
- `ImageData:drawLine` in `tests/lua/evidence/test_render_evidence.lua:2519`
- `ImageData:drawLine` in `tests/lua/evidence/test_render_evidence.lua:2548`
- `ImageData:drawCircle` in `tests/lua/evidence/test_render_evidence.lua:2565`
- `ImageData:drawLine` in `tests/lua/evidence/test_render_evidence.lua:2566`
- `ImageData:drawRect` in `tests/lua/evidence/test_render_evidence.lua:2639`
- `ImageData:drawLine` in `tests/lua/evidence/test_render_evidence.lua:2640`
- `ImageData:drawCircle` in `tests/lua/evidence/test_render_evidence.lua:2641`
- `ImageData:drawRect` in `tests/lua/evidence/test_render_evidence.lua:2674`
- `ImageData:drawCircle` in `tests/lua/evidence/test_render_evidence.lua:2675`
- `ImageData:drawLine` in `tests/lua/evidence/test_render_evidence.lua:2676`
- `ImageData:drawLine` in `tests/lua/evidence/test_render_evidence.lua:2705`
- `ImageData:drawCircle` in `tests/lua/evidence/test_render_evidence.lua:2722`
- `ImageData:drawLine` in `tests/lua/evidence/test_render_evidence.lua:2723`
- `ImageData:drawRect` in `tests/lua/evidence/test_shapes_evidence.lua:11`
- `ImageData:drawCircle` in `tests/lua/evidence/test_shapes_evidence.lua:51`
- `ImageData:drawLine` in `tests/lua/evidence/test_shapes_evidence.lua:76`
- `ImageData:paste` in `tests/lua/evidence/test_shapes_evidence.lua:100`
- `lurek.ui.loadLayout` in `tests/lua/evidence/test_ui_evidence.lua:20`
- `lurek.ui.renderToImage` in `tests/lua/evidence/test_ui_evidence.lua:21`
- `lurek.ui.loadLayout` in `tests/lua/evidence/test_ui_evidence.lua:46`
- `lurek.ui.renderToImage` in `tests/lua/evidence/test_ui_evidence.lua:47`
- `lurek.ui.loadLayout` in `tests/lua/evidence/test_ui_evidence.lua:102`
- `lurek.ui.renderToImage` in `tests/lua/evidence/test_ui_evidence.lua:103`
- `lurek.ui.loadLayout` in `tests/lua/evidence/test_ui_evidence.lua:128`
- `lurek.ui.renderToImage` in `tests/lua/evidence/test_ui_evidence.lua:129`
- `lurek.ui.newLineChart` in `tests/lua/evidence/test_ui_evidence.lua:173`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:177`
- `lurek.ui.newBarChart` in `tests/lua/evidence/test_ui_evidence.lua:180`
- `lurek.ui.newScatterPlot` in `tests/lua/evidence/test_ui_evidence.lua:181`
- `lurek.ui.newPieChart` in `tests/lua/evidence/test_ui_evidence.lua:182`
- `lurek.ui.newAreaChart` in `tests/lua/evidence/test_ui_evidence.lua:183`
- `lurek.ui.newBarChart` in `tests/lua/evidence/test_ui_evidence.lua:196`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:199`
- `lurek.ui.newScatterPlot` in `tests/lua/evidence/test_ui_evidence.lua:216`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:220`
- `lurek.ui.newPieChart` in `tests/lua/evidence/test_ui_evidence.lua:241`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:243`
- `lurek.ui.newAreaChart` in `tests/lua/evidence/test_ui_evidence.lua:258`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:261`
- `lurek.ui.newLineChart` in `tests/lua/evidence/test_ui_evidence.lua:292`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:296`
- `lurek.ui.newBarChart` in `tests/lua/evidence/test_ui_evidence.lua:299`
- `lurek.ui.newScatterPlot` in `tests/lua/evidence/test_ui_evidence.lua:300`
- `lurek.ui.newPieChart` in `tests/lua/evidence/test_ui_evidence.lua:301`
- `lurek.ui.newAreaChart` in `tests/lua/evidence/test_ui_evidence.lua:302`
- `lurek.ui.newBarChart` in `tests/lua/evidence/test_ui_evidence.lua:315`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:318`
- `lurek.ui.newScatterPlot` in `tests/lua/evidence/test_ui_evidence.lua:335`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:339`
- `lurek.ui.newPieChart` in `tests/lua/evidence/test_ui_evidence.lua:360`
- `Chart:drawToImage` in `tests/lua/evidence/test_ui_evidence.lua:362`
- `lurek.ui.newAreaChart` in `tests/lua/evidence/test_ui_evidence.lua:377`
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
