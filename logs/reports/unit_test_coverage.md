# Unit Test API Coverage

> Generated: 2026-04-23

## Summary Table

| Metric | Value |
| --- | --- |
| Total API functions | 0 |
| Explicitly covered | 0 |
| Coverage % | 0.0% |

## Table of Contents

- [Summary](#summary)
- [Module Coverage](#module-coverage)
- [Missing Explicit `@tests` Coverage](#missing-explicit-tests-coverage)
  - [`lurek.ui` — 235 still need `@tests`](#lurekui-235-still-need-tests)
  - [`lurek.math` — 107 still need `@tests`](#lurekmath-107-still-need-tests)
  - [`lurek.renders` — 91 still need `@tests`](#lurekrenders-91-still-need-tests)
  - [`lurek.audio` — 63 still need `@tests`](#lurekaudio-63-still-need-tests)
  - [`lurek.physics` — 54 still need `@tests`](#lurekphysics-54-still-need-tests)
  - [`lurek.input` — 50 still need `@tests`](#lurekinput-50-still-need-tests)
  - [`lurek.particle` — 46 still need `@tests`](#lurekparticle-46-still-need-tests)
  - [`lurek.patterns` — 34 still need `@tests`](#lurekpatterns-34-still-need-tests)
  - [`lurek.docs` — 28 still need `@tests`](#lurekdocs-28-still-need-tests)
  - [`lurek.filesystem` — 23 still need `@tests`](#lurekfilesystem-23-still-need-tests)
  - [`lurek.i18n` — 18 still need `@tests`](#lureki18n-18-still-need-tests)
  - [`lurek.tilemap` — 18 still need `@tests`](#lurektilemap-18-still-need-tests)
  - [`lurek.runtime` — 17 still need `@tests`](#lurekruntime-17-still-need-tests)
  - [`lurek.mods` — 15 still need `@tests`](#lurekmods-15-still-need-tests)
  - [`lurek.network` — 15 still need `@tests`](#lureknetwork-15-still-need-tests)
  - [`lurek.pipeline` — 15 still need `@tests`](#lurekpipeline-15-still-need-tests)
  - [`lurek.fx` — 13 still need `@tests`](#lurekfx-13-still-need-tests)
  - [`lurek.pathfind` — 13 still need `@tests`](#lurekpathfind-13-still-need-tests)
  - [`lurek.ai` — 11 still need `@tests`](#lurekai-11-still-need-tests)
  - [`lurek.timer` — 11 still need `@tests`](#lurektimer-11-still-need-tests)
  - [`lurek.data` — 9 still need `@tests`](#lurekdata-9-still-need-tests)
  - [`lurek.event` — 9 still need `@tests`](#lurekevent-9-still-need-tests)
  - [`lurek.camera` — 7 still need `@tests`](#lurekcamera-7-still-need-tests)
  - [`lurek.save` — 7 still need `@tests`](#lureksave-7-still-need-tests)
  - [`lurek.window` — 7 still need `@tests`](#lurekwindow-7-still-need-tests)
  - [`lurek.devtools` — 6 still need `@tests`](#lurekdevtools-6-still-need-tests)
  - [`lurek.log` — 6 still need `@tests`](#lureklog-6-still-need-tests)
  - [`lurek.ecs` — 4 still need `@tests`](#lurekecs-4-still-need-tests)
  - [`lurek.image` — 3 still need `@tests`](#lurekimage-3-still-need-tests)
  - [`lurek.animation` — 2 still need `@tests`](#lurekanimation-2-still-need-tests)
  - [`lurek.raycaster` — 2 still need `@tests`](#lurekraycaster-2-still-need-tests)
  - [`lurek.scene` — 2 still need `@tests`](#lurekscene-2-still-need-tests)
  - [`lurek.debugbridge` — 1 still need `@tests`](#lurekdebugbridge-1-still-need-tests)
  - [`lurek.graph` — 1 still need `@tests`](#lurekgraph-1-still-need-tests)
  - [`lurek.terminal` — 1 still need `@tests`](#lurekterminal-1-still-need-tests)
  - [`lurek.thread` — 1 still need `@tests`](#lurekthread-1-still-need-tests)
- [Zero-Evidence APIs](#zero-evidence-apis)
  - [`lurek.ui` — 235 zero-evidence](#lurekui-235-zero-evidence)
  - [`lurek.math` — 107 zero-evidence](#lurekmath-107-zero-evidence)
  - [`lurek.renders` — 91 zero-evidence](#lurekrenders-91-zero-evidence)
  - [`lurek.audio` — 63 zero-evidence](#lurekaudio-63-zero-evidence)
  - [`lurek.physics` — 54 zero-evidence](#lurekphysics-54-zero-evidence)
  - [`lurek.input` — 50 zero-evidence](#lurekinput-50-zero-evidence)
  - [`lurek.particle` — 46 zero-evidence](#lurekparticle-46-zero-evidence)
  - [`lurek.patterns` — 31 zero-evidence](#lurekpatterns-31-zero-evidence)
  - [`lurek.docs` — 28 zero-evidence](#lurekdocs-28-zero-evidence)
  - [`lurek.filesystem` — 23 zero-evidence](#lurekfilesystem-23-zero-evidence)
  - [`lurek.i18n` — 18 zero-evidence](#lureki18n-18-zero-evidence)
  - [`lurek.tilemap` — 18 zero-evidence](#lurektilemap-18-zero-evidence)
  - [`lurek.runtime` — 17 zero-evidence](#lurekruntime-17-zero-evidence)
  - [`lurek.mods` — 15 zero-evidence](#lurekmods-15-zero-evidence)
  - [`lurek.network` — 15 zero-evidence](#lureknetwork-15-zero-evidence)
  - [`lurek.pipeline` — 15 zero-evidence](#lurekpipeline-15-zero-evidence)
  - [`lurek.fx` — 13 zero-evidence](#lurekfx-13-zero-evidence)
  - [`lurek.pathfind` — 13 zero-evidence](#lurekpathfind-13-zero-evidence)
  - [`lurek.timer` — 11 zero-evidence](#lurektimer-11-zero-evidence)
  - [`lurek.data` — 9 zero-evidence](#lurekdata-9-zero-evidence)
  - [`lurek.event` — 9 zero-evidence](#lurekevent-9-zero-evidence)
  - [`lurek.camera` — 7 zero-evidence](#lurekcamera-7-zero-evidence)
  - [`lurek.save` — 7 zero-evidence](#lureksave-7-zero-evidence)
  - [`lurek.window` — 7 zero-evidence](#lurekwindow-7-zero-evidence)
  - [`lurek.devtools` — 6 zero-evidence](#lurekdevtools-6-zero-evidence)
  - [`lurek.log` — 6 zero-evidence](#lureklog-6-zero-evidence)
  - [`lurek.ecs` — 4 zero-evidence](#lurekecs-4-zero-evidence)
  - [`lurek.ai` — 3 zero-evidence](#lurekai-3-zero-evidence)
  - [`lurek.image` — 3 zero-evidence](#lurekimage-3-zero-evidence)
  - [`lurek.animation` — 2 zero-evidence](#lurekanimation-2-zero-evidence)
  - [`lurek.raycaster` — 2 zero-evidence](#lurekraycaster-2-zero-evidence)
  - [`lurek.scene` — 2 zero-evidence](#lurekscene-2-zero-evidence)
  - [`lurek.graph` — 1 zero-evidence](#lurekgraph-1-zero-evidence)
  - [`lurek.terminal` — 1 zero-evidence](#lurekterminal-1-zero-evidence)
  - [`lurek.thread` — 1 zero-evidence](#lurekthread-1-zero-evidence)
- [Annotation Convention](#annotation-convention)

*Generated: 2026-04-09T18:40:38 · Coverage requirement: explicit `@tests` annotations*

## Summary

| Metric | Value |
|--------|-------|
| Total APIs | 2556 |
| **Covered (explicit `@tests`)** | **1611 (63.0%)** |
| Heuristic-only hits | 12 (0.5%) |
| Missing explicit `@tests` | 945 (37.0%) |
| Zero-evidence APIs | 933 (36.5%) |
| Modules | 45 |

## Module Coverage

| Module | Total | Explicit | Heuristic-only | Explicit% | Missing `@tests` | Zero-evidence |
|--------|-------|----------|----------------|-----------|------------------|---------------|
| `ai` | 144 | 133 | 8 | 92.4% | 11 | 3 |
| `animation` | 18 | 16 | 0 | 88.9% | 2 | 2 |
| `audio` | 168 | 105 | 0 | 62.5% | 63 | 63 |
| `automation` | 17 | 17 | 0 | 100.0% | 0 | 0 |
| `camera` | 23 | 16 | 0 | 69.6% | 7 | 7 |
| `compute` | 45 | 45 | 0 | 100.0% | 0 | 0 |
| `data` | 13 | 4 | 0 | 30.8% | 9 | 9 |
| `dataframe` | 57 | 57 | 0 | 100.0% | 0 | 0 |
| `debugbridge` | 14 | 13 | 1 | 92.9% | 1 | 0 |
| `devtools` | 37 | 31 | 0 | 83.8% | 6 | 6 |
| `docs` | 75 | 47 | 0 | 62.7% | 28 | 28 |
| `ecs` | 45 | 41 | 0 | 91.1% | 4 | 4 |
| `event` | 17 | 8 | 0 | 47.1% | 9 | 9 |
| `filesystem` | 37 | 14 | 0 | 37.8% | 23 | 23 |
| `fx` | 118 | 105 | 0 | 89.0% | 13 | 13 |
| `graph` | 107 | 106 | 0 | 99.1% | 1 | 1 |
| `render` | 143 | 52 | 0 | 36.4% | 91 | 91 |
| `ui` | 302 | 67 | 0 | 22.2% | 235 | 235 |
| `image` | 26 | 23 | 0 | 88.5% | 3 | 3 |
| `input` | 52 | 2 | 0 | 3.9% | 50 | 50 |
| `light` | 75 | 75 | 0 | 100.0% | 0 | 0 |
| `i18n` | 27 | 9 | 0 | 33.3% | 18 | 18 |
| `log` | 13 | 7 | 0 | 53.9% | 6 | 6 |
| `math` | 132 | 25 | 0 | 18.9% | 107 | 107 |
| `minimap` | 49 | 49 | 0 | 100.0% | 0 | 0 |
| `mods` | 33 | 18 | 0 | 54.5% | 15 | 15 |
| `network` | 20 | 5 | 0 | 25.0% | 15 | 15 |
| `particle` | 78 | 32 | 0 | 41.0% | 46 | 46 |
| `pathfind` | 59 | 46 | 0 | 78.0% | 13 | 13 |
| `patterns` | 103 | 69 | 3 | 67.0% | 34 | 31 |
| `physics` | 91 | 37 | 0 | 40.7% | 54 | 54 |
| `pipeline` | 57 | 42 | 0 | 73.7% | 15 | 15 |
| `procgen` | 5 | 5 | 0 | 100.0% | 0 | 0 |
| `raycaster` | 9 | 7 | 0 | 77.8% | 2 | 2 |
| `save` | 19 | 12 | 0 | 63.2% | 7 | 7 |
| `scene` | 33 | 31 | 0 | 93.9% | 2 | 2 |
| `serial` | 6 | 6 | 0 | 100.0% | 0 | 0 |
| `spine` | 9 | 9 | 0 | 100.0% | 0 | 0 |
| `system` | 22 | 5 | 0 | 22.7% | 17 | 17 |
| `terminal` | 55 | 54 | 0 | 98.2% | 1 | 1 |
| `thread` | 9 | 8 | 0 | 88.9% | 1 | 1 |
| `tilemap` | 111 | 93 | 0 | 83.8% | 18 | 18 |
| `timer` | 27 | 16 | 0 | 59.3% | 11 | 11 |
| `tween` | 9 | 9 | 0 | 100.0% | 0 | 0 |
| `window` | 47 | 40 | 0 | 85.1% | 7 | 7 |

## Missing Explicit `@tests` Coverage

> These APIs still need an explicit `-- @tests ...` annotation in at least one unit-test `it()` block.

### `lurek.ui` — 235 still need `@tests`

- `lurek.ui.setPosition`
- `lurek.ui.getPosition`
- `lurek.ui.setSize`
- `lurek.ui.getSize`
- `lurek.ui.setVisible`
- `lurek.ui.isVisible`
- `lurek.ui.setEnabled`
- `lurek.ui.isEnabled`
- `lurek.ui.setId`
- `lurek.ui.getId`
- `lurek.ui.setTooltip`
- `lurek.ui.getTooltip`
- `lurek.ui.getState`
- `lurek.ui.addChild`
- `lurek.ui.removeChild`
- `lurek.ui.getChildCount`
- `lurek.ui.findById`
- `lurek.ui.setOnClick`
- `lurek.ui.setOnChange`
- `lurek.ui.setOnDraw`
- `lurek.ui.containsPoint`
- `lurek.ui.setPadding`
- `lurek.ui.getPadding`
- `lurek.ui.setMargin`
- `lurek.ui.getMargin`
- `lurek.ui.setZOrder`
- `lurek.ui.getZOrder`
- `lurek.ui.setMinSize`
- `lurek.ui.getMinSize`
- `lurek.ui.setMaxSize`
- `lurek.ui.getMaxSize`
- `lurek.ui.setAnchor`
- `lurek.ui.setAnchorCenter`
- `lurek.ui.clearAnchor`
- `lurek.ui.setFlexGrow`
- `lurek.ui.getFlexGrow`
- `lurek.ui.setFlexShrink`
- `lurek.ui.getFlexShrink`
- `Text_Input:setPlaceholder`  *(method on Text_Input)*
- `Text_Input:getPlaceholder`  *(method on Text_Input)*
- `Text_Input:isFocused`  *(method on Text_Input)*
- `Text_Input:getCursorPosition`  *(method on Text_Input)*
- `Checkbox:setChecked`  *(method on Checkbox)*
- `Checkbox:isChecked`  *(method on Checkbox)*
- `Slider:setRange`  *(method on Slider)*
- `Slider:setStep`  *(method on Slider)*
- `Slider:getMin`  *(method on Slider)*
- `Slider:getMax`  *(method on Slider)*
- `Progress_Bar:setRange`  *(method on Progress_Bar)*
- `Progress_Bar:getMin`  *(method on Progress_Bar)*
  *(… 185 more)*

### `lurek.math` — 107 still need `@tests`

- `lurek.math.newRandomGenerator`
- `lurek.math.newTransform`
- `lurek.math.newBezierCurve`
- `lurek.math.newTween`
- `lurek.math.newSpatialHash`
- `lurek.math.newNoiseGenerator`
- `lurek.math.perlin2d`
- `lurek.math.perlin3d`
- `lurek.math.simplex2d`
- `lurek.math.fbm`
- `lurek.math.applyEasing`
- `lurek.math.linear`
- `lurek.math.inQuad`
- `lurek.math.outQuad`
- `lurek.math.inOutQuad`
- `lurek.math.inCubic`
- `lurek.math.outCubic`
- `lurek.math.inOutCubic`
- `lurek.math.inQuart`
- `lurek.math.outQuart`
- `lurek.math.inOutQuart`
- `lurek.math.inSine`
- `lurek.math.outSine`
- `lurek.math.inOutSine`
- `lurek.math.inExpo`
- `lurek.math.outExpo`
- `lurek.math.inOutExpo`
- `lurek.math.inElastic`
- `lurek.math.outElastic`
- `lurek.math.outBounce`
- `lurek.math.inBounce`
- `lurek.math.inBack`
- `lurek.math.outBack`
- `lurek.math.triangulate`
- `lurek.math.isConvex`
- `lurek.math.gammaToLinear`
- `lurek.math.linearToGamma`
- `lurek.math.angleBetween`
- `lurek.math.circleContainsPoint`
- `lurek.math.circleIntersectsCircle`
- `lurek.math.circleIntersectsLine`
- `lurek.math.circleIntersectsSegment`
- `lurek.math.closestPointOnSegment`
- `lurek.math.convexHull`
- `lurek.math.delaunayTriangulate`
- `lurek.math.lineIntersect`
- `lurek.math.pointInPolygon`
- `lurek.math.polygonArea`
- `lurek.math.polygonCentroid`
- `lurek.math.segmentIntersectsSegment`
  *(… 57 more)*

### `lurek.renders` — 91 still need `@tests`

- `lurek.renders.setColor`
- `lurek.renders.getColor`
- `lurek.renders.setBackgroundColor`
- `lurek.renders.getBackgroundColor`
- `lurek.renders.rectangle`
- `lurek.renders.circle`
- `lurek.renders.ellipse`
- `lurek.renders.triangle`
- `lurek.renders.line`
- `lurek.renders.polygon`
- `lurek.renders.arc`
- `lurek.renders.points`
- `lurek.renders.draw`
- `lurek.renders.drawq`
- `lurek.renders.print`
- `lurek.renders.printf`
- `lurek.renders.clear`
- `lurek.renders.setLineWidth`
- `lurek.renders.getLineWidth`
- `lurek.renders.setPointSize`
- `lurek.renders.getPointSize`
- `lurek.renders.setBlendMode`
- `lurek.renders.getBlendMode`
- `lurek.renders.newFont`
- `lurek.renders.setFont`
- `lurek.renders.getFont`
- `lurek.renders.getFontWidth`
- `lurek.renders.getFontHeight`
- `lurek.renders.getFontLineHeight`
- `lurek.renders.setFontLineHeight`
- `lurek.renders.getFontAscent`
- `lurek.renders.getFontDescent`
- `lurek.renders.getFontWrap`
- `lurek.renders.newImage`
- `lurek.renders.newCanvas`
- `lurek.renders.setCanvas`
- `lurek.renders.getCanvas`
- `lurek.renders.getCanvasSize`
- `lurek.renders.newSpriteBatch`
- `lurek.renders.newMesh`
- `lurek.renders.newShader`
- `lurek.renders.setShader`
- `lurek.renders.getShader`
- `lurek.renders.newQuad`
- `lurek.renders.push`
- `lurek.renders.pop`
- `lurek.renders.translate`
- `lurek.renders.rotate`
- `lurek.renders.scale`
- `lurek.renders.shear`
  *(… 41 more)*

### `lurek.audio` — 63 still need `@tests`

- `lurek.audio.stop`
- `lurek.audio.setVolume`
- `lurek.audio.getVolume`
- `lurek.audio.pause`
- `lurek.audio.resume`
- `lurek.audio.setPitch`
- `lurek.audio.getPitch`
- `lurek.audio.isPlaying`
- `lurek.audio.isPaused`
- `lurek.audio.isStopped`
- `lurek.audio.setLooping`
- `lurek.audio.isLooping`
- `lurek.audio.playLooping`
- `lurek.audio.setPan`
- `lurek.audio.getPan`
- `lurek.audio.getActiveSourceCount`
- `lurek.audio.getSourceCount`
- `lurek.audio.getSourceType`
- `lurek.audio.clone`
- `lurek.audio.pauseAll`
- `lurek.audio.stopAll`
- `lurek.audio.resumeAll`
- `lurek.audio.release`
- `lurek.audio.setSourceBus`
- `lurek.audio.getSourceBus`
- `lurek.audio.getDuration`
- `lurek.audio.tell`
- `lurek.audio.seek`
- `lurek.audio.setLowpass`
- `lurek.audio.setHighpass`
- `lurek.audio.getLowpass`
- `lurek.audio.getHighpass`
- `lurek.audio.clearFilter`
- `lurek.audio.fadeIn`
- `lurek.audio.getFadeIn`
- `lurek.audio.setPosition`
- `lurek.audio.getPosition`
- `lurek.audio.setVelocity`
- `lurek.audio.getVelocity`
- `lurek.audio.setOrientation`
- `lurek.audio.getOrientation`
- `lurek.audio.setMidiSoundFont`
- `lurek.audio.hasMidiSoundFont`
- `lurek.audio.clearMidiSoundFont`
- `Source:setPan`  *(method on Source)*
- `Source:getPan`  *(method on Source)*
- `Source:setLowpass`  *(method on Source)*
- `Source:setHighpass`  *(method on Source)*
- `Source:getLowpass`  *(method on Source)*
- `Source:getHighpass`  *(method on Source)*
  *(… 13 more)*

### `lurek.physics` — 54 still need `@tests`

- `lurek.physics.destroyWorld`
- `lurek.physics.getCollisions`
- `World:getGravity`  *(method on World)*
- `World:setGravity`  *(method on World)*
- `World:setMeter`  *(method on World)*
- `World:getMeter`  *(method on World)*
- `World:toPhysics`  *(method on World)*
- `World:toPixels`  *(method on World)*
- `World:getBodyCount`  *(method on World)*
- `World:getBodyIds`  *(method on World)*
- `World:destroyBody`  *(method on World)*
- `World:fixtureCount`  *(method on World)*
- `World:jointCount`  *(method on World)*
- `World:getJointIds`  *(method on World)*
- `World:getJointBodies`  *(method on World)*
- `World:destroyJoint`  *(method on World)*
- `World:getJointType`  *(method on World)*
- `World:getJointMotorSpeed`  *(method on World)*
- `World:getJointLimits`  *(method on World)*
- `World:getBodyAtPoint`  *(method on World)*
- `World:getCollisionEvents`  *(method on World)*
- `World:getBeginContactEvents`  *(method on World)*
- `World:getEndContactEvents`  *(method on World)*
- `World:getContacts`  *(method on World)*
- `World:getBodyContacts`  *(method on World)*
- `World:getBodyType`  *(method on World)*
- `Body:getX`  *(method on Body)*
- `Body:getY`  *(method on Body)*
- `Body:getAngle`  *(method on Body)*
- `Body:setAngle`  *(method on Body)*
- `Body:getAngularVelocity`  *(method on Body)*
- `Body:setAngularVelocity`  *(method on Body)*
- `Body:getMass`  *(method on Body)*
- `Body:setMass`  *(method on Body)*
- `Body:getFriction`  *(method on Body)*
- `Body:getRestitution`  *(method on Body)*
- `Body:getMask`  *(method on Body)*
- `Body:setMask`  *(method on Body)*
- `Body:applyImpulse`  *(method on Body)*
- `Body:applyForce`  *(method on Body)*
- `Body:applyTorque`  *(method on Body)*
- `Body:applyAngularImpulse`  *(method on Body)*
- `Body:getGravityScale`  *(method on Body)*
- `Body:setGravityScale`  *(method on Body)*
- `Body:isFixedRotation`  *(method on Body)*
- `Body:setFixedRotation`  *(method on Body)*
- `Body:getLinearDamping`  *(method on Body)*
- `Body:setLinearDamping`  *(method on Body)*
- `Body:getAngularDamping`  *(method on Body)*
- `Body:setAngularDamping`  *(method on Body)*
  *(… 4 more)*

### `lurek.input` — 50 still need `@tests`

- `lurek.input.isDown`
- `lurek.input.isScancodeDown`
- `lurek.input.setKeyRepeat`
- `lurek.input.hasKeyRepeat`
- `lurek.input.setTextInput`
- `lurek.input.hasTextInput`
- `lurek.input.getScancodeFromKey`
- `lurek.input.getKeyFromScancode`
- `lurek.input.isModifierActive`
- `lurek.input.getPosition`
- `lurek.input.getX`
- `lurek.input.getY`
- `lurek.input.isDown`
- `lurek.input.setVisible`
- `lurek.input.isVisible`
- `lurek.input.setGrabbed`
- `lurek.input.isGrabbed`
- `lurek.input.setRelativeMode`
- `lurek.input.getRelativeMode`
- `lurek.input.setPosition`
- `lurek.input.setCursor`
- `lurek.input.newCursor`
- `lurek.input.getSystemCursor`
- `lurek.input.isCursorSupported`
- `lurek.input.getCursor`
- `lurek.input.getWheelDelta`
- `lurek.input.getCount`
- `lurek.input.getJoystickCount`
- `lurek.input.getJoysticks`
- `lurek.input.isConnected`
- `lurek.input.getName`
- `lurek.input.isGamepad`
- `lurek.input.getButtonCount`
- `lurek.input.getAxisCount`
- `lurek.input.isDown`
- `lurek.input.getAxis`
- `lurek.input.isVibrationSupported`
- `lurek.input.getGUID`
- `lurek.input.getHat`
- `lurek.input.setVibration`
- `lurek.input.setBackgroundEvents`
- `lurek.input.getBackgroundEvents`
- `lurek.input.setGamepadMapping`
- `lurek.input.getGamepadMappingString`
- `lurek.input.loadGamepadMappings`
- `lurek.input.saveGamepadMappings`
- `lurek.input.getTouches`
- `lurek.input.getPosition`
- `lurek.input.getPressure`
- `lurek.input.getTouchCount`

### `lurek.particle` — 46 still need `@tests`

- `lurek.particle.newTrail`
- `ParticleSystem:reset`  *(method on ParticleSystem)*
- `ParticleSystem:moveTo`  *(method on ParticleSystem)*
- `ParticleSystem:setEmissionRate`  *(method on ParticleSystem)*
- `ParticleSystem:getEmissionRate`  *(method on ParticleSystem)*
- `ParticleSystem:setParticleLifetime`  *(method on ParticleSystem)*
- `ParticleSystem:getParticleLifetime`  *(method on ParticleSystem)*
- `ParticleSystem:setEmitterLifetime`  *(method on ParticleSystem)*
- `ParticleSystem:getEmitterLifetime`  *(method on ParticleSystem)*
- `ParticleSystem:setSpread`  *(method on ParticleSystem)*
- `ParticleSystem:getSpread`  *(method on ParticleSystem)*
- `ParticleSystem:setLinearAcceleration`  *(method on ParticleSystem)*
- `ParticleSystem:getLinearAcceleration`  *(method on ParticleSystem)*
- `ParticleSystem:setRadialAcceleration`  *(method on ParticleSystem)*
- `ParticleSystem:getRadialAcceleration`  *(method on ParticleSystem)*
- `ParticleSystem:setTangentialAcceleration`  *(method on ParticleSystem)*
- `ParticleSystem:getTangentialAcceleration`  *(method on ParticleSystem)*
- `ParticleSystem:setLinearDamping`  *(method on ParticleSystem)*
- `ParticleSystem:getLinearDamping`  *(method on ParticleSystem)*
- `ParticleSystem:setSizes`  *(method on ParticleSystem)*
- `ParticleSystem:getSizes`  *(method on ParticleSystem)*
- `ParticleSystem:setSizeVariation`  *(method on ParticleSystem)*
- `ParticleSystem:getSizeVariation`  *(method on ParticleSystem)*
- `ParticleSystem:setSpin`  *(method on ParticleSystem)*
- `ParticleSystem:getSpin`  *(method on ParticleSystem)*
- `ParticleSystem:setSpinVariation`  *(method on ParticleSystem)*
- `ParticleSystem:getSpinVariation`  *(method on ParticleSystem)*
- `ParticleSystem:setRelativeRotation`  *(method on ParticleSystem)*
- `ParticleSystem:hasRelativeRotation`  *(method on ParticleSystem)*
- `ParticleSystem:setColors`  *(method on ParticleSystem)*
- `ParticleSystem:getColors`  *(method on ParticleSystem)*
- `ParticleSystem:getOffset`  *(method on ParticleSystem)*
- `ParticleSystem:setInsertMode`  *(method on ParticleSystem)*
- `ParticleSystem:getInsertMode`  *(method on ParticleSystem)*
- `ParticleSystem:setBufferSize`  *(method on ParticleSystem)*
- `ParticleSystem:getBufferSize`  *(method on ParticleSystem)*
- `ParticleSystem:setEmissionArea`  *(method on ParticleSystem)*
- `ParticleSystem:getEmissionArea`  *(method on ParticleSystem)*
- `ParticleSystem:getGravity`  *(method on ParticleSystem)*
- `ParticleSystem:setGravity`  *(method on ParticleSystem)*
- `Trail:pushPoint`  *(method on Trail)*
- `Trail:setWidth`  *(method on Trail)*
- `Trail:setLifetime`  *(method on Trail)*
- `Trail:getLifetime`  *(method on Trail)*
- `Trail:setMinDistance`  *(method on Trail)*
- `Trail:getPointCount`  *(method on Trail)*

### `lurek.patterns` — 34 still need `@tests`

- `lurek.patterns.newBlackboard`
- `lurek.patterns.newObserver`
- `lurek.patterns.newThrottle`
- `lurek.patterns.newDebounce`
- `lurek.patterns.newPriorityQueue`
- `lurek.patterns.newRing`
- `lurek.patterns.newFunnel`
- `CommandStack:undo`  *(method on CommandStack)* — referenced in tests, but still missing an explicit `@tests` annotation
- `CommandStack:redo`  *(method on CommandStack)* — referenced in tests, but still missing an explicit `@tests` annotation
- `CommandStack:canRedo`  *(method on CommandStack)* — referenced in tests, but still missing an explicit `@tests` annotation
- `Factory:alias`  *(method on Factory)*
- `Blackboard:keys`  *(method on Blackboard)*
- `Blackboard:watch`  *(method on Blackboard)*
- `Blackboard:unwatch`  *(method on Blackboard)*
- `Blackboard:getRevision`  *(method on Blackboard)*
- `Blackboard:snapshot`  *(method on Blackboard)*
- `Observer:subscribe`  *(method on Observer)*
- `Observer:unsubscribe`  *(method on Observer)*
- `Throttle:onFire`  *(method on Throttle)*
- `Throttle:reset`  *(method on Throttle)*
- `Throttle:getFireCount`  *(method on Throttle)*
- `Debounce:onFire`  *(method on Debounce)*
- `Debounce:trigger`  *(method on Debounce)*
- `Debounce:isPending`  *(method on Debounce)*
- `Debounce:getFireCount`  *(method on Debounce)*
- `PriorityQueue:len`  *(method on PriorityQueue)*
- `Ring:latest`  *(method on Ring)*
- `Ring:toArray`  *(method on Ring)*
- `Ring:average`  *(method on Ring)*
- `Ring:len`  *(method on Ring)*
- `Funnel:onFlush`  *(method on Funnel)*
- `Funnel:discard`  *(method on Funnel)*
- `Funnel:pendingCount`  *(method on Funnel)*
- `Funnel:getFlushCount`  *(method on Funnel)*

### `lurek.docs` — 28 still need `@tests`

- `lurek.docs.loadToml`
- `lurek.docs.loadAll`
- `lurek.docs.checkStaleness`
- `lurek.docs.qualityModule`
- `lurek.docs.exportCompletions`
- `lurek.docs.exportHover`
- `lurek.docs.exportSignatures`
- `lurek.docs.exportAll`
- `lurek.docs.exportMarkdown`
- `lurek.docs.exportCheatsheet`
- `lurek.docs.schema`
- `lurek.docs.reflectLive`
- `lurek.docs.reflectTable`
- `Schema:check`  *(method on Schema)*
- `Schema:assert`  *(method on Schema)*
- `Schema:getFields`  *(method on Schema)*
- `DocEntry:getQualifiedName`  *(method on DocEntry)*
- `DocEntry:getModule`  *(method on DocEntry)*
- `DocEntry:getKind`  *(method on DocEntry)*
- `DocEntry:getExample`  *(method on DocEntry)*
- `DocEntry:getSince`  *(method on DocEntry)*
- `DocEntry:getDeprecated`  *(method on DocEntry)*
- `ApiCatalog:getTypeMethods`  *(method on ApiCatalog)*
- `ValidationReport:getMissing`  *(method on ValidationReport)*
- `ValidationReport:getPhantom`  *(method on ValidationReport)*
- `ValidationReport:getIncomplete`  *(method on ValidationReport)*
- `ValidationReport:phantomCount`  *(method on ValidationReport)*
- `ValidationReport:incompleteCount`  *(method on ValidationReport)*

### `lurek.filesystem` — 23 still need `@tests`

- `lurek.filesystem.append`
- `lurek.filesystem.openFile`
- `lurek.filesystem.getDirectoryItems`
- `lurek.filesystem.isFile`
- `lurek.filesystem.isDirectory`
- `lurek.filesystem.createDirectory`
- `lurek.filesystem.getInfo`
- `lurek.filesystem.getSource`
- `lurek.filesystem.getSaveDirectory`
- `lurek.filesystem.getWorkingDirectory`
- `lurek.filesystem.getUserDirectory`
- `lurek.filesystem.getIdentity`
- `lurek.filesystem.setIdentity`
- `lurek.filesystem.lines`
- `lurek.filesystem.readAsync`
- `lurek.filesystem.pollAsync`
- `FileData:getFilename`  *(method on FileData)*
- `FileHandle:read`  *(method on FileHandle)*
- `FileHandle:readLine`  *(method on FileHandle)*
- `FileHandle:write`  *(method on FileHandle)*
- `FileHandle:getMode`  *(method on FileHandle)*
- `FileHandle:close`  *(method on FileHandle)*
- `FileHandle:isEOF`  *(method on FileHandle)*

### `lurek.i18n` — 18 still need `@tests`

- `lurek.i18n.unloadTable`
- `lurek.i18n.getLanguages`
- `lurek.i18n.setFallbacks`
- `lurek.i18n.getFallbacks`
- `lurek.i18n.hasKey`
- `lurek.i18n.getKeys`
- `lurek.i18n.setKey`
- `lurek.i18n.interpolate`
- `lurek.i18n.pluralFor`
- `lurek.i18n.onLanguageChange`
- `lurek.i18n.offChange`
- `lurek.i18n.keyCount`
- `lurek.i18n.categories`
- `lurek.i18n.keysInCategory`
- `lurek.i18n.search`
- `lurek.i18n.buildIndex`
- `lurek.i18n.searchIndexed`
- `lurek.i18n.mergeLocale`

### `lurek.tilemap` — 18 still need `@tests`

- `TileMap:getOrientation`  *(method on TileMap)*
- `TileMap:setOrientation`  *(method on TileMap)*
- `ChunkMap:loadChunk`  *(method on ChunkMap)*
- `ChunkMap:unloadChunk`  *(method on ChunkMap)*
- `ChunkMap:getLoadedChunks`  *(method on ChunkMap)*
- `ChunkMap:chunkTileRange`  *(method on ChunkMap)*
- `IsoMap:setLevelVisible`  *(method on IsoMap)*
- `IsoMap:isLevelVisible`  *(method on IsoMap)*
- `IsoMap:fillLevel`  *(method on IsoMap)*
- `IsoMap:setOrigin`  *(method on IsoMap)*
- `IsoMap:getLevelHeight`  *(method on IsoMap)*
- `IsoMap:tileToScreen`  *(method on IsoMap)*
- `IsoMap:screenToTile`  *(method on IsoMap)*
- `MapBlock:getSide`  *(method on MapBlock)*
- `MapBlock:getSegmentSize`  *(method on MapBlock)*
- `MapBlock:getWidthInSegments`  *(method on MapBlock)*
- `MapBlock:getHeightInSegments`  *(method on MapBlock)*
- `MapGroup:removeBlock`  *(method on MapGroup)*

### `lurek.runtime` — 17 still need `@tests`

- `lurek.runtime.getProcessorCount`
- `lurek.runtime.getMemorySize`
- `lurek.runtime.openURL`
- `lurek.runtime.getPreferredLocales`
- `lurek.runtime.getPowerInfo`
- `lurek.runtime.setDebugOverlay`
- `lurek.runtime.getDebugOverlay`
- `lurek.runtime.setLogLevel`
- `lurek.runtime.getLogLevel`
- `lurek.runtime.log`
- `lurek.runtime.getLastError`
- `lurek.runtime.getArch`
- `lurek.runtime.getEnv`
- `lurek.runtime.getArgs`
- `lurek.runtime.parseArgs`
- `lurek.runtime.runBatch`
- `lurek.runtime.getBatchResults`

### `lurek.mods` — 15 still need `@tests`

- `Mod:getHook`  *(method on Mod)*
- `Mod:hasHook`  *(method on Mod)*
- `Mod:getHookNames`  *(method on Mod)*
- `Mod:setConfig`  *(method on Mod)*
- `Mod:getConfig`  *(method on Mod)*
- `Mod:releaseRefs`  *(method on Mod)*
- `ModManager:validateDependencies`  *(method on ModManager)*
- `ModManager:hasCircularDependencies`  *(method on ModManager)*
- `ModManager:setLoadOrder`  *(method on ModManager)*
- `ModManager:clearLoadOrder`  *(method on ModManager)*
- `ModManager:scanFolder`  *(method on ModManager)*
- `ModManager:getModPath`  *(method on ModManager)*
- `ModManager:markForReload`  *(method on ModManager)*
- `ModManager:getReloadQueue`  *(method on ModManager)*
- `ModManager:clearReloadQueue`  *(method on ModManager)*

### `lurek.network` — 15 still need `@tests`

- `NetworkHost:disconnect`  *(method on NetworkHost)*
- `NetworkHost:disconnectNow`  *(method on NetworkHost)*
- `NetworkHost:resetPeer`  *(method on NetworkHost)*
- `NetworkHost:ping`  *(method on NetworkHost)*
- `NetworkHost:getRoundTripTime`  *(method on NetworkHost)*
- `NetworkHost:getPeerState`  *(method on NetworkHost)*
- `NetworkHost:getPeerAddress`  *(method on NetworkHost)*
- `NetworkHost:getPeerLimit`  *(method on NetworkHost)*
- `NetworkHost:getChannelLimit`  *(method on NetworkHost)*
- `NetworkHost:setChannelLimit`  *(method on NetworkHost)*
- `NetworkHost:getBandwidthLimit`  *(method on NetworkHost)*
- `NetworkHost:getConnectedPeerCount`  *(method on NetworkHost)*
- `NetworkHost:getConnectedPeerIds`  *(method on NetworkHost)*
- `NetworkHost:getPeerStats`  *(method on NetworkHost)*
- `NetworkHost:isDestroyed`  *(method on NetworkHost)*

### `lurek.pipeline` — 15 still need `@tests`

- `Step:setCallback`  *(method on Step)*
- `Step:setTimeout`  *(method on Step)*
- `Step:getTimeout`  *(method on Step)*
- `Step:setRetryDelay`  *(method on Step)*
- `Step:setOnError`  *(method on Step)*
- `Step:getAttempt`  *(method on Step)*
- `Pipeline:getSteps`  *(method on Pipeline)*
- `Pipeline:getExecutionOrder`  *(method on Pipeline)*
- `Pipeline:runAsync`  *(method on Pipeline)*
- `Pipeline:reset`  *(method on Pipeline)*
- `Pipeline:isComplete`  *(method on Pipeline)*
- `Pipeline:getResult`  *(method on Pipeline)*
- `Pipeline:getContext`  *(method on Pipeline)*
- `Pipeline:setOnComplete`  *(method on Pipeline)*
- `Pipeline:setOnStepError`  *(method on Pipeline)*

### `lurek.fx` — 13 still need `@tests`

- `lurek.fx.newEffect`
- `lurek.fx.newCustomEffect`
- `lurek.fx.newImageEffect`
- `lurek.fx.newOverlay`
- `lurek.fx.newOverlay`
- `PostFxEffect:getTypeName`  *(method on PostFxEffect)*
- `PostFxStack:getEnabledEffects`  *(method on PostFxStack)*
- `PostFxStack:len`  *(method on PostFxStack)*
- `ImageEffect:save`  *(method on ImageEffect)*
- `ImageEffect:removeByIndex`  *(method on ImageEffect)*
- `ImageEffect:removeByName`  *(method on ImageEffect)*
- `Overlay:getFlashAlpha`  *(method on Overlay)*
- `Overlay:getLightningAlpha`  *(method on Overlay)*

### `lurek.pathfind` — 13 still need `@tests`

- `lurek.pathfind.setThreadCount`
- `NavGrid:loadFromString`  *(method on NavGrid)*
- `NavGrid:saveToString`  *(method on NavGrid)*
- `NavGrid:setChunkSize`  *(method on NavGrid)*
- `NavGrid:rebuildAbstract`  *(method on NavGrid)*
- `NavGrid:setDirty`  *(method on NavGrid)*
- `NavGrid:clearDirty`  *(method on NavGrid)*
- `UnitPathfinder:getPathLength`  *(method on UnitPathfinder)*
- `UnitPathfinder:getPathCost`  *(method on UnitPathfinder)*
- `UnitPathfinder:setCacheEnabled`  *(method on UnitPathfinder)*
- `UnitPathfinder:setCacheMaxSize`  *(method on UnitPathfinder)*
- `FlowField:getDirectionAngle`  *(method on FlowField)*
- `FlowField:getTargets`  *(method on FlowField)*

### `lurek.ai` — 11 still need `@tests`

- `Blackboard:setNumber`  *(method on Blackboard)* — referenced in tests, but still missing an explicit `@tests` annotation
- `Blackboard:setBool`  *(method on Blackboard)* — referenced in tests, but still missing an explicit `@tests` annotation
- `Blackboard:setString`  *(method on Blackboard)* — referenced in tests, but still missing an explicit `@tests` annotation
- `Blackboard:remove`  *(method on Blackboard)* — referenced in tests, but still missing an explicit `@tests` annotation
- `Blackboard:getKeys`  *(method on Blackboard)* — referenced in tests, but still missing an explicit `@tests` annotation
- `Blackboard:getSize`  *(method on Blackboard)* — referenced in tests, but still missing an explicit `@tests` annotation
- `Blackboard:type`  *(method on Blackboard)* — referenced in tests, but still missing an explicit `@tests` annotation
- `Blackboard:typeOf`  *(method on Blackboard)* — referenced in tests, but still missing an explicit `@tests` annotation
- `BTNode:reset`  *(method on BTNode)*
- `BTNode:getNodeType`  *(method on BTNode)*
- `CommandQueue:getCurrentTarget`  *(method on CommandQueue)*

### `lurek.timer` — 11 still need `@tests`

- `lurek.timer.newScheduler`
- `Scheduler:after`  *(method on Scheduler)*
- `Scheduler:cancelNamed`  *(method on Scheduler)*
- `Scheduler:cancelAll`  *(method on Scheduler)*
- `Scheduler:getRemaining`  *(method on Scheduler)*
- `Scheduler:getInterval`  *(method on Scheduler)*
- `Scheduler:getRepeatCount`  *(method on Scheduler)*
- `Scheduler:setInterval`  *(method on Scheduler)*
- `Scheduler:resetEvent`  *(method on Scheduler)*
- `Scheduler:setTimeScale`  *(method on Scheduler)*
- `Scheduler:getTimeScale`  *(method on Scheduler)*

### `lurek.data` — 9 still need `@tests`

- `lurek.data.compress`
- `lurek.data.decompress`
- `lurek.data.encode`
- `lurek.data.decode`
- `lurek.data.hash`
- `lurek.data.newByteData`
- `lurek.data.write`
- `lurek.data.read`
- `lurek.data.size`

### `lurek.event` — 9 still need `@tests`

- `lurek.event.exit`
- `lurek.event.push`
- `lurek.event.poll`
- `lurek.event.clear`
- `lurek.event.newSignal`
- `lurek.event.pump`
- `lurek.event.wait`
- `lurek.event.restart`
- `lurek.event.quit`

### `lurek.camera` — 7 still need `@tests`

- `Camera2D:setBounds`  *(method on Camera2D)*
- `Camera2D:removeBounds`  *(method on Camera2D)*
- `Camera2D:setTarget`  *(method on Camera2D)*
- `Camera2D:clearTarget`  *(method on Camera2D)*
- `Camera2D:setFollowSmooth`  *(method on Camera2D)*
- `Camera2D:setDeadZone`  *(method on Camera2D)*
- `Camera2D:setLookAhead`  *(method on Camera2D)*

### `lurek.save` — 7 still need `@tests`

- `SaveManager:collect`  *(method on SaveManager)*
- `SaveManager:restore`  *(method on SaveManager)*
- `SaveManager:disableAutoSave`  *(method on SaveManager)*
- `SaveManager:reset`  *(method on SaveManager)*
- `SaveManager:save`  *(method on SaveManager)*
- `SaveManager:delete`  *(method on SaveManager)*
- `SaveManager:getSlotInfo`  *(method on SaveManager)*

### `lurek.window` — 7 still need `@tests`

- `lurek.window.setTitle`
- `lurek.window.getFullscreenModes`
- `lurek.window.getDisplayName`
- `lurek.window.getPixelDimensions`
- `lurek.window.showMessageBox`
- `lurek.window.isFullscreen`
- `lurek.window.isResizable`

### `lurek.devtools` — 6 still need `@tests`

- `lurek.devtools.log`
- `lurek.devtools.scan`
- `lurek.devtools.exposeWatch`
- `lurek.devtools.removeWatch`
- `lurek.devtools.getWatches`
- `lurek.devtools.snapshot`

### `lurek.log` — 6 still need `@tests`

- `lurek.log.addSink`
- `lurek.log.removeSink`
- `lurek.log.clearSinks`
- `lurek.log.listSinks`
- `lurek.log.readMemory`
- `lurek.log.flushFile`

### `lurek.ecs` — 4 still need `@tests`

- `Universe:getEntities`  *(method on Universe)*
- `Universe:bitmapUntag`  *(method on Universe)*
- `Universe:getBitmapTagBit`  *(method on Universe)*
- `Universe:killRecursive`  *(method on Universe)*

### `lurek.image` — 3 still need `@tests`

- `LayeredImage:save`  *(method on LayeredImage)*
- `CompressedImageData:getMipmapCount`  *(method on CompressedImageData)*
- `CompressedImageData:getFormat`  *(method on CompressedImageData)*

### `lurek.animation` — 2 still need `@tests`

- `Animation:getCurrentFrame`  *(method on Animation)*
- `Animation:setFrame`  *(method on Animation)*

### `lurek.raycaster` — 2 still need `@tests`

- `lurek.raycaster.projectColumn`
- `lurek.raycaster.distanceShade`

### `lurek.scene` — 2 still need `@tests`

- `lurek.scene.popTo`
- `DepthSorter:addObject`  *(method on DepthSorter)*

### `lurek.debugbridge` — 1 still need `@tests`

- `lurek.debugbridge.setMaxPrintHistory` — referenced in tests, but still missing an explicit `@tests` annotation

### `lurek.graph` — 1 still need `@tests`

- `Node:dequeue`  *(method on Node)*

### `lurek.terminal` — 1 still need `@tests`

- `Widget:setSize`  *(method on Widget)*

### `lurek.thread` — 1 still need `@tests`

- `ThreadHandle:wait`  *(method on ThreadHandle)*

## Zero-Evidence APIs

> These APIs are neither explicitly annotated nor referenced heuristically in unit tests.

### `lurek.ui` — 235 zero-evidence

- `lurek.ui.setPosition`
- `lurek.ui.getPosition`
- `lurek.ui.setSize`
- `lurek.ui.getSize`
- `lurek.ui.setVisible`
- `lurek.ui.isVisible`
- `lurek.ui.setEnabled`
- `lurek.ui.isEnabled`
- `lurek.ui.setId`
- `lurek.ui.getId`
- `lurek.ui.setTooltip`
- `lurek.ui.getTooltip`
- `lurek.ui.getState`
- `lurek.ui.addChild`
- `lurek.ui.removeChild`
- `lurek.ui.getChildCount`
- `lurek.ui.findById`
- `lurek.ui.setOnClick`
- `lurek.ui.setOnChange`
- `lurek.ui.setOnDraw`
- `lurek.ui.containsPoint`
- `lurek.ui.setPadding`
- `lurek.ui.getPadding`
- `lurek.ui.setMargin`
- `lurek.ui.getMargin`
- `lurek.ui.setZOrder`
- `lurek.ui.getZOrder`
- `lurek.ui.setMinSize`
- `lurek.ui.getMinSize`
- `lurek.ui.setMaxSize`
  *(… 205 more)*

### `lurek.math` — 107 zero-evidence

- `lurek.math.newRandomGenerator`
- `lurek.math.newTransform`
- `lurek.math.newBezierCurve`
- `lurek.math.newTween`
- `lurek.math.newSpatialHash`
- `lurek.math.newNoiseGenerator`
- `lurek.math.perlin2d`
- `lurek.math.perlin3d`
- `lurek.math.simplex2d`
- `lurek.math.fbm`
- `lurek.math.applyEasing`
- `lurek.math.linear`
- `lurek.math.inQuad`
- `lurek.math.outQuad`
- `lurek.math.inOutQuad`
- `lurek.math.inCubic`
- `lurek.math.outCubic`
- `lurek.math.inOutCubic`
- `lurek.math.inQuart`
- `lurek.math.outQuart`
- `lurek.math.inOutQuart`
- `lurek.math.inSine`
- `lurek.math.outSine`
- `lurek.math.inOutSine`
- `lurek.math.inExpo`
- `lurek.math.outExpo`
- `lurek.math.inOutExpo`
- `lurek.math.inElastic`
- `lurek.math.outElastic`
- `lurek.math.outBounce`
  *(… 77 more)*

### `lurek.renders` — 91 zero-evidence

- `lurek.renders.setColor`
- `lurek.renders.getColor`
- `lurek.renders.setBackgroundColor`
- `lurek.renders.getBackgroundColor`
- `lurek.renders.rectangle`
- `lurek.renders.circle`
- `lurek.renders.ellipse`
- `lurek.renders.triangle`
- `lurek.renders.line`
- `lurek.renders.polygon`
- `lurek.renders.arc`
- `lurek.renders.points`
- `lurek.renders.draw`
- `lurek.renders.drawq`
- `lurek.renders.print`
- `lurek.renders.printf`
- `lurek.renders.clear`
- `lurek.renders.setLineWidth`
- `lurek.renders.getLineWidth`
- `lurek.renders.setPointSize`
- `lurek.renders.getPointSize`
- `lurek.renders.setBlendMode`
- `lurek.renders.getBlendMode`
- `lurek.renders.newFont`
- `lurek.renders.setFont`
- `lurek.renders.getFont`
- `lurek.renders.getFontWidth`
- `lurek.renders.getFontHeight`
- `lurek.renders.getFontLineHeight`
- `lurek.renders.setFontLineHeight`
  *(… 61 more)*

### `lurek.audio` — 63 zero-evidence

- `lurek.audio.stop`
- `lurek.audio.setVolume`
- `lurek.audio.getVolume`
- `lurek.audio.pause`
- `lurek.audio.resume`
- `lurek.audio.setPitch`
- `lurek.audio.getPitch`
- `lurek.audio.isPlaying`
- `lurek.audio.isPaused`
- `lurek.audio.isStopped`
- `lurek.audio.setLooping`
- `lurek.audio.isLooping`
- `lurek.audio.playLooping`
- `lurek.audio.setPan`
- `lurek.audio.getPan`
- `lurek.audio.getActiveSourceCount`
- `lurek.audio.getSourceCount`
- `lurek.audio.getSourceType`
- `lurek.audio.clone`
- `lurek.audio.pauseAll`
- `lurek.audio.stopAll`
- `lurek.audio.resumeAll`
- `lurek.audio.release`
- `lurek.audio.setSourceBus`
- `lurek.audio.getSourceBus`
- `lurek.audio.getDuration`
- `lurek.audio.tell`
- `lurek.audio.seek`
- `lurek.audio.setLowpass`
- `lurek.audio.setHighpass`
  *(… 33 more)*

### `lurek.physics` — 54 zero-evidence

- `lurek.physics.destroyWorld`
- `lurek.physics.getCollisions`
- `World:getGravity`  *(method on World)*
- `World:setGravity`  *(method on World)*
- `World:setMeter`  *(method on World)*
- `World:getMeter`  *(method on World)*
- `World:toPhysics`  *(method on World)*
- `World:toPixels`  *(method on World)*
- `World:getBodyCount`  *(method on World)*
- `World:getBodyIds`  *(method on World)*
- `World:destroyBody`  *(method on World)*
- `World:fixtureCount`  *(method on World)*
- `World:jointCount`  *(method on World)*
- `World:getJointIds`  *(method on World)*
- `World:getJointBodies`  *(method on World)*
- `World:destroyJoint`  *(method on World)*
- `World:getJointType`  *(method on World)*
- `World:getJointMotorSpeed`  *(method on World)*
- `World:getJointLimits`  *(method on World)*
- `World:getBodyAtPoint`  *(method on World)*
- `World:getCollisionEvents`  *(method on World)*
- `World:getBeginContactEvents`  *(method on World)*
- `World:getEndContactEvents`  *(method on World)*
- `World:getContacts`  *(method on World)*
- `World:getBodyContacts`  *(method on World)*
- `World:getBodyType`  *(method on World)*
- `Body:getX`  *(method on Body)*
- `Body:getY`  *(method on Body)*
- `Body:getAngle`  *(method on Body)*
- `Body:setAngle`  *(method on Body)*
  *(… 24 more)*

### `lurek.input` — 50 zero-evidence

- `lurek.input.isDown`
- `lurek.input.isScancodeDown`
- `lurek.input.setKeyRepeat`
- `lurek.input.hasKeyRepeat`
- `lurek.input.setTextInput`
- `lurek.input.hasTextInput`
- `lurek.input.getScancodeFromKey`
- `lurek.input.getKeyFromScancode`
- `lurek.input.isModifierActive`
- `lurek.input.getPosition`
- `lurek.input.getX`
- `lurek.input.getY`
- `lurek.input.isDown`
- `lurek.input.setVisible`
- `lurek.input.isVisible`
- `lurek.input.setGrabbed`
- `lurek.input.isGrabbed`
- `lurek.input.setRelativeMode`
- `lurek.input.getRelativeMode`
- `lurek.input.setPosition`
- `lurek.input.setCursor`
- `lurek.input.newCursor`
- `lurek.input.getSystemCursor`
- `lurek.input.isCursorSupported`
- `lurek.input.getCursor`
- `lurek.input.getWheelDelta`
- `lurek.input.getCount`
- `lurek.input.getJoystickCount`
- `lurek.input.getJoysticks`
- `lurek.input.isConnected`
  *(… 20 more)*

### `lurek.particle` — 46 zero-evidence

- `lurek.particle.newTrail`
- `ParticleSystem:reset`  *(method on ParticleSystem)*
- `ParticleSystem:moveTo`  *(method on ParticleSystem)*
- `ParticleSystem:setEmissionRate`  *(method on ParticleSystem)*
- `ParticleSystem:getEmissionRate`  *(method on ParticleSystem)*
- `ParticleSystem:setParticleLifetime`  *(method on ParticleSystem)*
- `ParticleSystem:getParticleLifetime`  *(method on ParticleSystem)*
- `ParticleSystem:setEmitterLifetime`  *(method on ParticleSystem)*
- `ParticleSystem:getEmitterLifetime`  *(method on ParticleSystem)*
- `ParticleSystem:setSpread`  *(method on ParticleSystem)*
- `ParticleSystem:getSpread`  *(method on ParticleSystem)*
- `ParticleSystem:setLinearAcceleration`  *(method on ParticleSystem)*
- `ParticleSystem:getLinearAcceleration`  *(method on ParticleSystem)*
- `ParticleSystem:setRadialAcceleration`  *(method on ParticleSystem)*
- `ParticleSystem:getRadialAcceleration`  *(method on ParticleSystem)*
- `ParticleSystem:setTangentialAcceleration`  *(method on ParticleSystem)*
- `ParticleSystem:getTangentialAcceleration`  *(method on ParticleSystem)*
- `ParticleSystem:setLinearDamping`  *(method on ParticleSystem)*
- `ParticleSystem:getLinearDamping`  *(method on ParticleSystem)*
- `ParticleSystem:setSizes`  *(method on ParticleSystem)*
- `ParticleSystem:getSizes`  *(method on ParticleSystem)*
- `ParticleSystem:setSizeVariation`  *(method on ParticleSystem)*
- `ParticleSystem:getSizeVariation`  *(method on ParticleSystem)*
- `ParticleSystem:setSpin`  *(method on ParticleSystem)*
- `ParticleSystem:getSpin`  *(method on ParticleSystem)*
- `ParticleSystem:setSpinVariation`  *(method on ParticleSystem)*
- `ParticleSystem:getSpinVariation`  *(method on ParticleSystem)*
- `ParticleSystem:setRelativeRotation`  *(method on ParticleSystem)*
- `ParticleSystem:hasRelativeRotation`  *(method on ParticleSystem)*
- `ParticleSystem:setColors`  *(method on ParticleSystem)*
  *(… 16 more)*

### `lurek.patterns` — 31 zero-evidence

- `lurek.patterns.newBlackboard`
- `lurek.patterns.newObserver`
- `lurek.patterns.newThrottle`
- `lurek.patterns.newDebounce`
- `lurek.patterns.newPriorityQueue`
- `lurek.patterns.newRing`
- `lurek.patterns.newFunnel`
- `Factory:alias`  *(method on Factory)*
- `Blackboard:keys`  *(method on Blackboard)*
- `Blackboard:watch`  *(method on Blackboard)*
- `Blackboard:unwatch`  *(method on Blackboard)*
- `Blackboard:getRevision`  *(method on Blackboard)*
- `Blackboard:snapshot`  *(method on Blackboard)*
- `Observer:subscribe`  *(method on Observer)*
- `Observer:unsubscribe`  *(method on Observer)*
- `Throttle:onFire`  *(method on Throttle)*
- `Throttle:reset`  *(method on Throttle)*
- `Throttle:getFireCount`  *(method on Throttle)*
- `Debounce:onFire`  *(method on Debounce)*
- `Debounce:trigger`  *(method on Debounce)*
- `Debounce:isPending`  *(method on Debounce)*
- `Debounce:getFireCount`  *(method on Debounce)*
- `PriorityQueue:len`  *(method on PriorityQueue)*
- `Ring:latest`  *(method on Ring)*
- `Ring:toArray`  *(method on Ring)*
- `Ring:average`  *(method on Ring)*
- `Ring:len`  *(method on Ring)*
- `Funnel:onFlush`  *(method on Funnel)*
- `Funnel:discard`  *(method on Funnel)*
- `Funnel:pendingCount`  *(method on Funnel)*
  *(… 1 more)*

### `lurek.docs` — 28 zero-evidence

- `lurek.docs.loadToml`
- `lurek.docs.loadAll`
- `lurek.docs.checkStaleness`
- `lurek.docs.qualityModule`
- `lurek.docs.exportCompletions`
- `lurek.docs.exportHover`
- `lurek.docs.exportSignatures`
- `lurek.docs.exportAll`
- `lurek.docs.exportMarkdown`
- `lurek.docs.exportCheatsheet`
- `lurek.docs.schema`
- `lurek.docs.reflectLive`
- `lurek.docs.reflectTable`
- `Schema:check`  *(method on Schema)*
- `Schema:assert`  *(method on Schema)*
- `Schema:getFields`  *(method on Schema)*
- `DocEntry:getQualifiedName`  *(method on DocEntry)*
- `DocEntry:getModule`  *(method on DocEntry)*
- `DocEntry:getKind`  *(method on DocEntry)*
- `DocEntry:getExample`  *(method on DocEntry)*
- `DocEntry:getSince`  *(method on DocEntry)*
- `DocEntry:getDeprecated`  *(method on DocEntry)*
- `ApiCatalog:getTypeMethods`  *(method on ApiCatalog)*
- `ValidationReport:getMissing`  *(method on ValidationReport)*
- `ValidationReport:getPhantom`  *(method on ValidationReport)*
- `ValidationReport:getIncomplete`  *(method on ValidationReport)*
- `ValidationReport:phantomCount`  *(method on ValidationReport)*
- `ValidationReport:incompleteCount`  *(method on ValidationReport)*

### `lurek.filesystem` — 23 zero-evidence

- `lurek.filesystem.append`
- `lurek.filesystem.openFile`
- `lurek.filesystem.getDirectoryItems`
- `lurek.filesystem.isFile`
- `lurek.filesystem.isDirectory`
- `lurek.filesystem.createDirectory`
- `lurek.filesystem.getInfo`
- `lurek.filesystem.getSource`
- `lurek.filesystem.getSaveDirectory`
- `lurek.filesystem.getWorkingDirectory`
- `lurek.filesystem.getUserDirectory`
- `lurek.filesystem.getIdentity`
- `lurek.filesystem.setIdentity`
- `lurek.filesystem.lines`
- `lurek.filesystem.readAsync`
- `lurek.filesystem.pollAsync`
- `FileData:getFilename`  *(method on FileData)*
- `FileHandle:read`  *(method on FileHandle)*
- `FileHandle:readLine`  *(method on FileHandle)*
- `FileHandle:write`  *(method on FileHandle)*
- `FileHandle:getMode`  *(method on FileHandle)*
- `FileHandle:close`  *(method on FileHandle)*
- `FileHandle:isEOF`  *(method on FileHandle)*

### `lurek.i18n` — 18 zero-evidence

- `lurek.i18n.unloadTable`
- `lurek.i18n.getLanguages`
- `lurek.i18n.setFallbacks`
- `lurek.i18n.getFallbacks`
- `lurek.i18n.hasKey`
- `lurek.i18n.getKeys`
- `lurek.i18n.setKey`
- `lurek.i18n.interpolate`
- `lurek.i18n.pluralFor`
- `lurek.i18n.onLanguageChange`
- `lurek.i18n.offChange`
- `lurek.i18n.keyCount`
- `lurek.i18n.categories`
- `lurek.i18n.keysInCategory`
- `lurek.i18n.search`
- `lurek.i18n.buildIndex`
- `lurek.i18n.searchIndexed`
- `lurek.i18n.mergeLocale`

### `lurek.tilemap` — 18 zero-evidence

- `TileMap:getOrientation`  *(method on TileMap)*
- `TileMap:setOrientation`  *(method on TileMap)*
- `ChunkMap:loadChunk`  *(method on ChunkMap)*
- `ChunkMap:unloadChunk`  *(method on ChunkMap)*
- `ChunkMap:getLoadedChunks`  *(method on ChunkMap)*
- `ChunkMap:chunkTileRange`  *(method on ChunkMap)*
- `IsoMap:setLevelVisible`  *(method on IsoMap)*
- `IsoMap:isLevelVisible`  *(method on IsoMap)*
- `IsoMap:fillLevel`  *(method on IsoMap)*
- `IsoMap:setOrigin`  *(method on IsoMap)*
- `IsoMap:getLevelHeight`  *(method on IsoMap)*
- `IsoMap:tileToScreen`  *(method on IsoMap)*
- `IsoMap:screenToTile`  *(method on IsoMap)*
- `MapBlock:getSide`  *(method on MapBlock)*
- `MapBlock:getSegmentSize`  *(method on MapBlock)*
- `MapBlock:getWidthInSegments`  *(method on MapBlock)*
- `MapBlock:getHeightInSegments`  *(method on MapBlock)*
- `MapGroup:removeBlock`  *(method on MapGroup)*

### `lurek.runtime` — 17 zero-evidence

- `lurek.runtime.getProcessorCount`
- `lurek.runtime.getMemorySize`
- `lurek.runtime.openURL`
- `lurek.runtime.getPreferredLocales`
- `lurek.runtime.getPowerInfo`
- `lurek.runtime.setDebugOverlay`
- `lurek.runtime.getDebugOverlay`
- `lurek.runtime.setLogLevel`
- `lurek.runtime.getLogLevel`
- `lurek.runtime.log`
- `lurek.runtime.getLastError`
- `lurek.runtime.getArch`
- `lurek.runtime.getEnv`
- `lurek.runtime.getArgs`
- `lurek.runtime.parseArgs`
- `lurek.runtime.runBatch`
- `lurek.runtime.getBatchResults`

### `lurek.mods` — 15 zero-evidence

- `Mod:getHook`  *(method on Mod)*
- `Mod:hasHook`  *(method on Mod)*
- `Mod:getHookNames`  *(method on Mod)*
- `Mod:setConfig`  *(method on Mod)*
- `Mod:getConfig`  *(method on Mod)*
- `Mod:releaseRefs`  *(method on Mod)*
- `ModManager:validateDependencies`  *(method on ModManager)*
- `ModManager:hasCircularDependencies`  *(method on ModManager)*
- `ModManager:setLoadOrder`  *(method on ModManager)*
- `ModManager:clearLoadOrder`  *(method on ModManager)*
- `ModManager:scanFolder`  *(method on ModManager)*
- `ModManager:getModPath`  *(method on ModManager)*
- `ModManager:markForReload`  *(method on ModManager)*
- `ModManager:getReloadQueue`  *(method on ModManager)*
- `ModManager:clearReloadQueue`  *(method on ModManager)*

### `lurek.network` — 15 zero-evidence

- `NetworkHost:disconnect`  *(method on NetworkHost)*
- `NetworkHost:disconnectNow`  *(method on NetworkHost)*
- `NetworkHost:resetPeer`  *(method on NetworkHost)*
- `NetworkHost:ping`  *(method on NetworkHost)*
- `NetworkHost:getRoundTripTime`  *(method on NetworkHost)*
- `NetworkHost:getPeerState`  *(method on NetworkHost)*
- `NetworkHost:getPeerAddress`  *(method on NetworkHost)*
- `NetworkHost:getPeerLimit`  *(method on NetworkHost)*
- `NetworkHost:getChannelLimit`  *(method on NetworkHost)*
- `NetworkHost:setChannelLimit`  *(method on NetworkHost)*
- `NetworkHost:getBandwidthLimit`  *(method on NetworkHost)*
- `NetworkHost:getConnectedPeerCount`  *(method on NetworkHost)*
- `NetworkHost:getConnectedPeerIds`  *(method on NetworkHost)*
- `NetworkHost:getPeerStats`  *(method on NetworkHost)*
- `NetworkHost:isDestroyed`  *(method on NetworkHost)*

### `lurek.pipeline` — 15 zero-evidence

- `Step:setCallback`  *(method on Step)*
- `Step:setTimeout`  *(method on Step)*
- `Step:getTimeout`  *(method on Step)*
- `Step:setRetryDelay`  *(method on Step)*
- `Step:setOnError`  *(method on Step)*
- `Step:getAttempt`  *(method on Step)*
- `Pipeline:getSteps`  *(method on Pipeline)*
- `Pipeline:getExecutionOrder`  *(method on Pipeline)*
- `Pipeline:runAsync`  *(method on Pipeline)*
- `Pipeline:reset`  *(method on Pipeline)*
- `Pipeline:isComplete`  *(method on Pipeline)*
- `Pipeline:getResult`  *(method on Pipeline)*
- `Pipeline:getContext`  *(method on Pipeline)*
- `Pipeline:setOnComplete`  *(method on Pipeline)*
- `Pipeline:setOnStepError`  *(method on Pipeline)*

### `lurek.fx` — 13 zero-evidence

- `lurek.fx.newEffect`
- `lurek.fx.newCustomEffect`
- `lurek.fx.newImageEffect`
- `lurek.fx.newOverlay`
- `lurek.fx.newOverlay`
- `PostFxEffect:getTypeName`  *(method on PostFxEffect)*
- `PostFxStack:getEnabledEffects`  *(method on PostFxStack)*
- `PostFxStack:len`  *(method on PostFxStack)*
- `ImageEffect:save`  *(method on ImageEffect)*
- `ImageEffect:removeByIndex`  *(method on ImageEffect)*
- `ImageEffect:removeByName`  *(method on ImageEffect)*
- `Overlay:getFlashAlpha`  *(method on Overlay)*
- `Overlay:getLightningAlpha`  *(method on Overlay)*

### `lurek.pathfind` — 13 zero-evidence

- `lurek.pathfind.setThreadCount`
- `NavGrid:loadFromString`  *(method on NavGrid)*
- `NavGrid:saveToString`  *(method on NavGrid)*
- `NavGrid:setChunkSize`  *(method on NavGrid)*
- `NavGrid:rebuildAbstract`  *(method on NavGrid)*
- `NavGrid:setDirty`  *(method on NavGrid)*
- `NavGrid:clearDirty`  *(method on NavGrid)*
- `UnitPathfinder:getPathLength`  *(method on UnitPathfinder)*
- `UnitPathfinder:getPathCost`  *(method on UnitPathfinder)*
- `UnitPathfinder:setCacheEnabled`  *(method on UnitPathfinder)*
- `UnitPathfinder:setCacheMaxSize`  *(method on UnitPathfinder)*
- `FlowField:getDirectionAngle`  *(method on FlowField)*
- `FlowField:getTargets`  *(method on FlowField)*

### `lurek.timer` — 11 zero-evidence

- `lurek.timer.newScheduler`
- `Scheduler:after`  *(method on Scheduler)*
- `Scheduler:cancelNamed`  *(method on Scheduler)*
- `Scheduler:cancelAll`  *(method on Scheduler)*
- `Scheduler:getRemaining`  *(method on Scheduler)*
- `Scheduler:getInterval`  *(method on Scheduler)*
- `Scheduler:getRepeatCount`  *(method on Scheduler)*
- `Scheduler:setInterval`  *(method on Scheduler)*
- `Scheduler:resetEvent`  *(method on Scheduler)*
- `Scheduler:setTimeScale`  *(method on Scheduler)*
- `Scheduler:getTimeScale`  *(method on Scheduler)*

### `lurek.data` — 9 zero-evidence

- `lurek.data.compress`
- `lurek.data.decompress`
- `lurek.data.encode`
- `lurek.data.decode`
- `lurek.data.hash`
- `lurek.data.newByteData`
- `lurek.data.write`
- `lurek.data.read`
- `lurek.data.size`

### `lurek.event` — 9 zero-evidence

- `lurek.event.exit`
- `lurek.event.push`
- `lurek.event.poll`
- `lurek.event.clear`
- `lurek.event.newSignal`
- `lurek.event.pump`
- `lurek.event.wait`
- `lurek.event.restart`
- `lurek.event.quit`

### `lurek.camera` — 7 zero-evidence

- `Camera2D:setBounds`  *(method on Camera2D)*
- `Camera2D:removeBounds`  *(method on Camera2D)*
- `Camera2D:setTarget`  *(method on Camera2D)*
- `Camera2D:clearTarget`  *(method on Camera2D)*
- `Camera2D:setFollowSmooth`  *(method on Camera2D)*
- `Camera2D:setDeadZone`  *(method on Camera2D)*
- `Camera2D:setLookAhead`  *(method on Camera2D)*

### `lurek.save` — 7 zero-evidence

- `SaveManager:collect`  *(method on SaveManager)*
- `SaveManager:restore`  *(method on SaveManager)*
- `SaveManager:disableAutoSave`  *(method on SaveManager)*
- `SaveManager:reset`  *(method on SaveManager)*
- `SaveManager:save`  *(method on SaveManager)*
- `SaveManager:delete`  *(method on SaveManager)*
- `SaveManager:getSlotInfo`  *(method on SaveManager)*

### `lurek.window` — 7 zero-evidence

- `lurek.window.setTitle`
- `lurek.window.getFullscreenModes`
- `lurek.window.getDisplayName`
- `lurek.window.getPixelDimensions`
- `lurek.window.showMessageBox`
- `lurek.window.isFullscreen`
- `lurek.window.isResizable`

### `lurek.devtools` — 6 zero-evidence

- `lurek.devtools.log`
- `lurek.devtools.scan`
- `lurek.devtools.exposeWatch`
- `lurek.devtools.removeWatch`
- `lurek.devtools.getWatches`
- `lurek.devtools.snapshot`

### `lurek.log` — 6 zero-evidence

- `lurek.log.addSink`
- `lurek.log.removeSink`
- `lurek.log.clearSinks`
- `lurek.log.listSinks`
- `lurek.log.readMemory`
- `lurek.log.flushFile`

### `lurek.ecs` — 4 zero-evidence

- `Universe:getEntities`  *(method on Universe)*
- `Universe:bitmapUntag`  *(method on Universe)*
- `Universe:getBitmapTagBit`  *(method on Universe)*
- `Universe:killRecursive`  *(method on Universe)*

### `lurek.ai` — 3 zero-evidence

- `BTNode:reset`  *(method on BTNode)*
- `BTNode:getNodeType`  *(method on BTNode)*
- `CommandQueue:getCurrentTarget`  *(method on CommandQueue)*

### `lurek.image` — 3 zero-evidence

- `LayeredImage:save`  *(method on LayeredImage)*
- `CompressedImageData:getMipmapCount`  *(method on CompressedImageData)*
- `CompressedImageData:getFormat`  *(method on CompressedImageData)*

### `lurek.animation` — 2 zero-evidence

- `Animation:getCurrentFrame`  *(method on Animation)*
- `Animation:setFrame`  *(method on Animation)*

### `lurek.raycaster` — 2 zero-evidence

- `lurek.raycaster.projectColumn`
- `lurek.raycaster.distanceShade`

### `lurek.scene` — 2 zero-evidence

- `lurek.scene.popTo`
- `DepthSorter:addObject`  *(method on DepthSorter)*

### `lurek.graph` — 1 zero-evidence

- `Node:dequeue`  *(method on Node)*

### `lurek.terminal` — 1 zero-evidence

- `Widget:setSize`  *(method on Widget)*

### `lurek.thread` — 1 zero-evidence

- `ThreadHandle:wait`  *(method on ThreadHandle)*

## Annotation Convention

Add `-- @tests <lua_name>` inside any `it()` block to explicitly declare
which API that test exercises:

```lua
it("getDelta returns a number", function()
    -- @tests lurek.timer.getDelta
    local dt = lurek.timer.getDelta()
    expect_type("number", dt)
end)

it("World:step advances simulation", function()
    -- @tests World:step
    world:step(1/60)
end)
```

Multiple `@tests` annotations per `it()` block are allowed.  
Run `python tools/audit/unit_test_api_coverage.py --save` to regenerate this report.