"""
Batch-implement all pending --@api-stub: TODO blocks in content/examples/*.lua.

For each block with a "-- TODO:" line, replace the stub body with a real
do...end scenario. Blocks without TODO are left untouched (already real).

Usage:
    python tools/audit/implement_stubs.py [--dry-run]
"""

import re
import sys
import os

DRY_RUN = "--dry-run" in sys.argv

# ---------------------------------------------------------------------------
# Constructor map: type name -> Lua expression that creates an instance
# The key is the L-prefixed type name from the API.
# ---------------------------------------------------------------------------
CONSTRUCTORS = {
    # AI
    "LAIBlackboard":       "lurek.ai.newBlackboard()",
    "LAIDirector":         "lurek.ai.newDirector()",
    "LBandit":             "lurek.ai.newBandit(4, 'ucb1', 0.1, 99)",
    "LContextSteering":    "lurek.ai.newContextSteering(16)",
    "LDialogueAI":         "lurek.ai.newDialogueAI()",
    "LEmotionModel":       "lurek.ai.newEmotionModel()",
    "LGeneticAlgorithm":   "lurek.ai.newGeneticAlgorithm(50, 16, 42)",
    "LHTNDomain":          "lurek.ai.newHTNDomain()",
    "LMCTSEngine":         "lurek.ai.newMCTSEngine(200, 1.41, 32, 12345)",
    "LNeedSystem":         "lurek.ai.newNeedSystem()",
    "LNeuralNet":          "lurek.ai.newNeuralNet()",
    "LNeuroevolution":     "lurek.ai.newNeuroevolution({2,4,1}, 30, 1)",
    "LORCASolver":         "lurek.ai.newORCASolver(2.0)",
    "LStimulusWorld":      "lurek.ai.newStimulusWorld()",
    "LStrategyAI":         "lurek.ai.newStrategyAI(2.0)",
    "LTraitProfile":       "lurek.ai.newTraitProfile()",
    # Animation
    "LAnimCurve":          "lurek.animation.newCurve()",
    "LAnimStateMachine":   "lurek.animation.newStateMachine()",
    "LAnimation":          "lurek.animation.newAnimation('walk', 6, 0.1)",
    "LBlendLayerSet":      "lurek.animation.newBlendLayerSet()",
    # Audio
    "LDecoder":            "lurek.audio.newDecoder('assets/audio/music.ogg')",
    "LSource":             "lurek.audio.newSource('assets/audio/music.ogg', 'static')",
    # Camera
    "LCamera":             "lurek.camera.new()",
    # Data
    "LDataView":           "lurek.data.newView(lurek.data.newBuffer(64))",
    "LDataWriter":         "lurek.data.newWriter()",
    "LRingBuffer":         "lurek.data.newRingBuffer(16)",
    # Devtools
    "LFileWatcher":        "lurek.devtools.newWatcher('.')",
    # Docs
    "LApiCatalog":         "lurek.docs.getCatalog()",
    "LDocEntry":           "lurek.docs.getCatalog():get('lurek.log.info')",
    "LSchema":             "lurek.docs.getSchema()",
    "LValidationReport":   "lurek.docs.validate({})",
    # Filesystem
    "LFileData":           "lurek.filesystem.newFileData('test', 'string')",
    "LFileHandle":         "lurek.filesystem.openFile('save/score.txt', 'r')",
    # Globe
    "LGlobe":              "lurek.globe.new(8)",
    # Graph
    "LGraphEdge":          "(function() local g = lurek.graph.newGraph(); local a = g:addNode('a'); local b = g:addNode('b'); return g:addEdge(a, b, 1.0) end)()",
    "LGraphNode":          "lurek.graph.newGraph():addNode('n1')",
    # HTML
    "LHtmlDocument":       "lurek.html.newDocument()",
    # Image
    "LCompressedImageData": "lurek.image.newCompressedData('assets/textures/logo.png')",
    "LLayeredImage":       "lurek.image.newLayeredImage(64, 64)",
    "LProvinceGrid":       "lurek.image.newProvinceGrid(8, 8)",
    # Input
    "LCombo":              "lurek.input.newCombo('ctrl+s')",
    "LCursor":             "lurek.input.newCursor('crosshair')",
    # Light
    "LLight":              "lurek.light.newPoint(400, 300, 200, 1, 1, 0.8)",
    # Math
    "LBezierCurve":        "lurek.math.newBezierCurve({{0,0},{100,0},{100,100},{200,100}})",
    "LCatmullRom":         "lurek.math.newCatmullRom({{0,0},{100,50},{200,0}})",
    "LCircle":             "lurek.math.newCircle(100, 100, 40)",
    "LHermite":            "lurek.math.newHermite({{0,0},{100,50}})",
    "LNoiseGenerator":     "lurek.math.newNoiseGenerator(42)",
    "LRandomGenerator":    "lurek.math.newRandomGenerator(12345)",
    "LSpatialHash":        "lurek.math.newSpatialHash(64)",
    "LTransform":          "lurek.math.newTransform()",
    "LTween":              "lurek.math.newTween(0, 1, 1.0, 'linear')",
    "LVec2":               "lurek.math.newVec2(1, 0)",
    "LVec3":               "lurek.math.newVec3(1, 0, 0)",
    # Mods
    "LMod":                "lurek.mods.getLoaded()[1] or lurek.mods.getMod('core')",
    "LModManager":         "lurek.mods.getManager()",
    # Network
    "LNetworkHost":        "lurek.network.newHost('localhost', 7777, 8, 0)",
    # Pathfind
    "LAIFlowField":        "lurek.pathfind.newFlowField(20, 20)",
    "LHexGrid":            "lurek.pathfind.newHexGrid(10, 10)",
    "LJpsGrid":            "lurek.pathfind.newGrid(20, 20)",
    # Patterns
    "LList":               "lurek.patterns.newList()",
    # Physics
    "LBody":               "(function() local w = lurek.physics.newWorld(0, 9.8); return w:newBody(100, 100, 'dynamic') end)()",
    "LCellular":           "lurek.procgen.newCellular(40, 30, 0.45, 42)",
    "LTerrain":            "lurek.procgen.newTerrain(64, 64, 42)",
    "LWorld":              "lurek.physics.newWorld(0, 9.8)",
    "LZone":               "(function() local w = lurek.physics.newWorld(0, 0); return w:newZone(0, 0, 100, 100) end)()",
    # Pipeline
    "LPipelineStep":       "lurek.pipeline.getSteps()[1]",
    # Raycaster
    "LRaycaster":          "lurek.raycaster.new(800, 600, 60)",
    # Render -- no object to instantiate, these are module-level funcs
    # Scene
    "LScene":              "lurek.scene.new()",
    # Spine
    "LSkeleton":           "lurek.spine.newSkeleton('assets/spine/hero.json')",
    # Sprite
    "LSpriteSheet":        "lurek.sprite.newSheet('assets/textures/logo.png', 64, 64)",
    # Thread
    "LPromise":            "lurek.thread.newPromise(function() return 42 end)",
    "LThread":             "lurek.thread.new(function() end)",
    "LThreadPool":         "lurek.thread.newPool(2)",
    # Tilemap
    "LAutoTileSheet":      "lurek.tilemap.newAutoTileSheet('assets/textures/logo.png', 16)",
    "LChunkMap":           "lurek.tilemap.newChunkMap(16, 16, 64, 64)",
    "LIsoMap":             "lurek.tilemap.newIsoMap(20, 15, 64, 32)",
    "LLargeMapRenderer":   "lurek.tilemap.newLargeMapRenderer(100, 100, 16)",
    "LMapBlock":           "lurek.tilemap.newMapBlock()",
    "LMapGroup":           "lurek.tilemap.newMapGroup()",
    "LMapScript":          "lurek.tilemap.newMapScript()",
    "LTileMap":            "lurek.tilemap.newTileMap(20, 15, 16)",
    "LTileSet":            "lurek.tilemap.newTileSet('assets/textures/logo.png', 16, 16)",
    # Tween
    "LTweenState":         "lurek.tween.newState()",
    "LTweenSequence":      "lurek.tween.newSequence()",
    # UI
    "LBarChart":           "lurek.ui.newBarChart(0, 0, 300, 200)",
    "LButton":             "lurek.ui.newButton(0, 0, 100, 30, 'Click')",
    "LCheckbox":           "lurek.ui.newCheckbox(0, 0, 'Enable')",
    "LComboBox":           "lurek.ui.newComboBox(0, 0, 150, 30)",
    "LGuiWindow":          "lurek.ui.newWindow(50, 50, 400, 300, 'Demo')",
    "LLabel":              "lurek.ui.newLabel(0, 0, 'Hello')",
    "LLineChart":          "lurek.ui.newLineChart(0, 0, 400, 200)",
    "LMenuItem":           "lurek.ui.newMenuItem('File')",
    "LPanel":              "lurek.ui.newPanel(0, 0, 300, 200)",
    "LPieChart":           "lurek.ui.newPieChart(0, 0, 200, 200)",
    "LProgressBar":        "lurek.ui.newProgressBar(0, 0, 200, 20)",
    "LRadioButton":        "lurek.ui.newRadioButton(0, 0, 'Option A')",
    "LScatterPlot":        "lurek.ui.newScatterPlot(0, 0, 300, 200)",
    "LScrollBar":          "lurek.ui.newScrollBar(0, 0, 200, 16, false)",
    "LScrollPanel":        "lurek.ui.newScrollPanel(0, 0, 300, 200)",
    "LSeparator":          "lurek.ui.newSeparator(0, 0, 200, false)",
    "LSlider":             "lurek.ui.newSlider(0, 0, 200, 20)",
    "LSplitPanel":         "lurek.ui.newSplitPanel(0, 0, 400, 300, 'horizontal')",
    "LStatusBar":          "lurek.ui.newStatusBar(0, 580, 800, 20)",
    "LTextInput":          "lurek.ui.newTextInput(0, 0, 200, 30)",
    "LTheme":              "lurek.ui.getTheme()",
    "LToolbar":            "lurek.ui.newToolbar(0, 0, 800, 30)",
    "LUiWidget":           "lurek.ui.newLabel(0, 0, 'widget')",
}

# ---------------------------------------------------------------------------
# Explicit implementations for non-type/typeOf stubs
# Key: "TypeName:method" or "lurek.module.func"
# Value: Lua code string for the do...end body (indented 2 spaces)
# ---------------------------------------------------------------------------
EXPLICIT = {
    # AI Blackboard
    "LAIBlackboard:has": """\
do
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("score", 42)
  local found = bb:has("score")
  lurek.log.debug("has 'score': " .. tostring(found), "ai") -- true
  local missing = bb:has("no_such_key")
  lurek.log.debug("has 'no_such_key': " .. tostring(missing), "ai") -- false
end""",
    "LAIBlackboard:clear": """\
do
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("gold", 500)
  bb:setString("name", "hero")
  -- Wipe all entries.
  bb:clear()
  lurek.log.debug("after clear, has 'gold': " .. tostring(bb:has("gold")), "ai") -- false
end""",
    "LAIBlackboard:remove": """\
do
  local bb = lurek.ai.newBlackboard()
  bb:setNumber("hp", 100)
  bb:setNumber("mp", 50)
  bb:remove("hp")
  lurek.log.debug("after remove, has 'hp': " .. tostring(bb:has("hp")), "ai") -- false
  lurek.log.debug("mp still present: " .. tostring(bb:has("mp")), "ai") -- true
end""",
    # Audio module-level
    "lurek.audio.clone": """\
do
  local src = lurek.audio.newSource("assets/audio/music.ogg", "static")
  -- clone() creates an independent copy that can play simultaneously.
  local copy = lurek.audio.clone(src)
  lurek.log.debug("source cloned", "audio")
  lurek.audio.release(src)
  lurek.audio.release(copy)
end""",
    "lurek.audio.getDuration": """\
do
  local src = lurek.audio.newSource("assets/audio/music.ogg", "static")
  local dur = lurek.audio.getDuration(src)
  lurek.log.info("duration: " .. tostring(dur) .. " s", "audio")
  lurek.audio.release(src)
end""",
    "lurek.audio.getFadeIn": """\
do
  local src = lurek.audio.newSource("assets/audio/music.ogg", "static")
  lurek.audio.fadeIn(src, 1.0)
  local fade = lurek.audio.getFadeIn(src)
  lurek.log.debug("fade-in duration: " .. tostring(fade), "audio")
  lurek.audio.release(src)
end""",
    "lurek.audio.fadeIn": """\
do
  local music = lurek.audio.newSource("assets/audio/music.ogg", "static")
  -- Fade volume from 0 to full over 2 seconds.
  lurek.audio.fadeIn(music, 2.0)
  lurek.log.info("music fading in over 2 s", "audio")
  lurek.audio.release(music)
end""",
    "lurek.audio.getHighpass": """\
do
  local src = lurek.audio.newSource("assets/audio/music.ogg", "static")
  lurek.audio.setHighpass(src, 800)
  local freq = lurek.audio.getHighpass(src)
  lurek.log.debug("highpass: " .. tostring(freq) .. " Hz", "audio")
  lurek.audio.release(src)
end""",
    "lurek.audio.getLowpass": """\
do
  local src = lurek.audio.newSource("assets/audio/music.ogg", "static")
  lurek.audio.setLowpass(src, 3000)
  local freq = lurek.audio.getLowpass(src)
  lurek.log.debug("lowpass: " .. tostring(freq) .. " Hz", "audio")
  lurek.audio.release(src)
end""",
    "lurek.audio.getPan": """\
do
  local src = lurek.audio.newSource("assets/audio/music.ogg", "static")
  lurek.audio.setPan(src, 0.5)
  local pan = lurek.audio.getPan(src)
  lurek.log.debug("pan: " .. tostring(pan), "audio") -- 0.5 (right)
  lurek.audio.release(src)
end""",
    "lurek.audio.getPitch": """\
do
  local src = lurek.audio.newSource("assets/audio/music.ogg", "static")
  lurek.audio.setPitch(src, 1.5)
  local pitch = lurek.audio.getPitch(src)
  lurek.log.debug("pitch: " .. tostring(pitch), "audio") -- 1.5
  lurek.audio.release(src)
end""",
    "lurek.audio.getVolume": """\
do
  local src = lurek.audio.newSource("assets/audio/music.ogg", "static")
  lurek.audio.setVolume(src, 0.7)
  local vol = lurek.audio.getVolume(src)
  lurek.log.debug("volume: " .. tostring(vol), "audio") -- 0.7
  lurek.audio.release(src)
end""",
    "lurek.audio.isLooping": """\
do
  local src = lurek.audio.newSource("assets/audio/music.ogg", "static")
  lurek.audio.setLooping(src, true)
  local looping = lurek.audio.isLooping(src)
  lurek.log.debug("looping: " .. tostring(looping), "audio") -- true
  lurek.audio.release(src)
end""",
    "lurek.audio.isPaused": """\
do
  local src = lurek.audio.newSource("assets/audio/music.ogg", "static")
  lurek.audio.play(src)
  lurek.audio.pause(src)
  local paused = lurek.audio.isPaused(src)
  lurek.log.debug("isPaused: " .. tostring(paused), "audio") -- true
  lurek.audio.stop(src)
  lurek.audio.release(src)
end""",
    "lurek.audio.isPlaying": """\
do
  local src = lurek.audio.newSource("assets/audio/music.ogg", "static")
  lurek.audio.play(src)
  local playing = lurek.audio.isPlaying(src)
  lurek.log.debug("isPlaying: " .. tostring(playing), "audio") -- true
  lurek.audio.stop(src)
  lurek.audio.release(src)
end""",
    "lurek.audio.isStopped": """\
do
  local src = lurek.audio.newSource("assets/audio/music.ogg", "static")
  local stopped = lurek.audio.isStopped(src)
  lurek.log.debug("isStopped (before play): " .. tostring(stopped), "audio") -- true
  lurek.audio.release(src)
end""",
    "lurek.audio.release": """\
do
  local src = lurek.audio.newSource("assets/audio/music.ogg", "static")
  -- Always release sources when you no longer need them to free decoder memory.
  lurek.audio.release(src)
  lurek.log.debug("source released", "audio")
end""",
    "lurek.audio.seek": """\
do
  local src = lurek.audio.newSource("assets/audio/music.ogg", "static")
  -- Jump to 0.5 seconds into the track.
  lurek.audio.seek(src, 0.5)
  local pos = lurek.audio.tell(src)
  lurek.log.debug("position after seek: " .. tostring(pos) .. " s", "audio")
  lurek.audio.release(src)
end""",
    "lurek.audio.setHighpass": """\
do
  local src = lurek.audio.newSource("assets/audio/music.ogg", "static")
  -- Cut frequencies below 800 Hz (treble-only pass).
  lurek.audio.setHighpass(src, 800)
  lurek.log.debug("highpass filter set to 800 Hz", "audio")
  lurek.audio.release(src)
end""",
    "lurek.audio.setLooping": """\
do
  local music = lurek.audio.newSource("assets/audio/music.ogg", "static")
  lurek.audio.setLooping(music, true)
  lurek.log.debug("music will loop indefinitely", "audio")
  lurek.audio.release(music)
end""",
    "lurek.audio.setLowpass": """\
do
  local src = lurek.audio.newSource("assets/audio/music.ogg", "static")
  -- Muffle high-frequency content above 3 kHz (muffled/underwater effect).
  lurek.audio.setLowpass(src, 3000)
  lurek.log.debug("lowpass filter set to 3000 Hz", "audio")
  lurek.audio.release(src)
end""",
    "lurek.audio.setPan": """\
do
  local sfx = lurek.audio.newSource("assets/audio/music.ogg", "static")
  -- Pan hard right for an enemy approaching from the right.
  lurek.audio.setPan(sfx, 1.0)
  lurek.log.debug("panned right", "audio")
  lurek.audio.release(sfx)
end""",
    "lurek.audio.setPitch": """\
do
  local sfx = lurek.audio.newSource("assets/audio/music.ogg", "static")
  -- Speed up the sound (higher pitch = faster).
  lurek.audio.setPitch(sfx, 1.25)
  lurek.log.debug("pitch set to 1.25", "audio")
  lurek.audio.release(sfx)
end""",
    "lurek.audio.setVolume": """\
do
  local music = lurek.audio.newSource("assets/audio/music.ogg", "static")
  lurek.audio.setVolume(music, 0.6)
  lurek.log.debug("volume set to 60%", "audio")
  lurek.audio.release(music)
end""",
    "lurek.audio.stopAll": """\
do
  -- Stop every active audio source at once (e.g., game over or menu open).
  lurek.audio.stopAll()
  lurek.log.info("all audio stopped", "audio")
end""",
    "lurek.audio.clearFilter": """\
do
  local src = lurek.audio.newSource("assets/audio/music.ogg", "static")
  lurek.audio.setLowpass(src, 1000)
  -- Remove the filter to restore the original sound.
  lurek.audio.clearFilter(src)
  lurek.log.debug("filter cleared", "audio")
  lurek.audio.release(src)
end""",
    "lurek.audio.tell": """\
do
  local src = lurek.audio.newSource("assets/audio/music.ogg", "static")
  lurek.audio.seek(src, 1.0)
  local pos = lurek.audio.tell(src)
  lurek.log.debug("tell: " .. tostring(pos) .. " s", "audio")
  lurek.audio.release(src)
end""",
    # Camera
    "LCamera:apply": """\
do
  local cam = lurek.camera.new()
  cam:setPosition(100, 100)
  -- Apply the camera transform before drawing world objects.
  cam:apply()
  lurek.log.debug("camera applied", "camera")
end""",
    "LCamera:getViewport": """\
do
  local cam = lurek.camera.new()
  local x, y, w, h = cam:getViewport()
  lurek.log.debug("viewport: " .. x .. "," .. y .. " " .. w .. "x" .. h, "camera")
end""",
    "LCamera:setPosition": """\
do
  local cam = lurek.camera.new()
  cam:setPosition(320, 240)
  lurek.log.debug("camera moved to (320, 240)", "camera")
end""",
    "LCamera:setTarget": """\
do
  local cam = lurek.camera.new()
  -- Lock the camera on a player position.
  cam:setTarget(400, 300)
  lurek.log.debug("camera target set to (400, 300)", "camera")
end""",
    # devtools
    "lurek.devtools.eval": """\
do
  -- eval() runs a Lua snippet string in the live runtime and returns results.
  local result = lurek.devtools.eval("return 2 + 2")
  lurek.log.debug("eval result: " .. tostring(result), "devtools") -- 4
end""",
    # FileData
    "LFileData:getSize": """\
do
  local fd = lurek.filesystem.newFileData("hello world", "string")
  local sz = fd:getSize()
  lurek.log.debug("FileData size: " .. sz .. " bytes", "fs") -- 11
end""",
    # Globe
    "lurek.globe.get": """\
do
  local g = lurek.globe.new(8)
  -- get() returns an existing globe by ID (created with new()).
  local id = g:getId()
  local same = lurek.globe.get(id)
  lurek.log.debug("got globe by id: " .. tostring(same ~= nil), "globe") -- true
end""",
    "lurek.globe.new": """\
do
  -- new(subdivisions) creates an icosphere globe for planetary/map rendering.
  local planet = lurek.globe.new(6)
  lurek.log.debug("globe type: " .. planet:type(), "globe") -- "LGlobe"
end""",
    # Graph
    "LGraphEdge:getCapacity": """\
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("a")
  local b = g:addNode("b")
  local e = g:addEdge(a, b, 5.0)
  local cap = e:getCapacity()
  lurek.log.debug("capacity: " .. tostring(cap), "graph")
end""",
    "LGraphEdge:getType": """\
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("a")
  local b = g:addNode("b")
  local e = g:addEdge(a, b, 1.0)
  local t = e:getType()
  lurek.log.debug("edge type: " .. tostring(t), "graph")
end""",
    "LGraphEdge:isActive": """\
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("a")
  local b = g:addNode("b")
  local e = g:addEdge(a, b, 1.0)
  lurek.log.debug("edge active: " .. tostring(e:isActive()), "graph") -- true
end""",
    "LGraphEdge:setActive": """\
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("a")
  local b = g:addNode("b")
  local e = g:addEdge(a, b, 1.0)
  e:setActive(false)
  lurek.log.debug("edge disabled: " .. tostring(not e:isActive()), "graph") -- true
end""",
    "LGraphEdge:setCapacity": """\
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("a")
  local b = g:addNode("b")
  local e = g:addEdge(a, b, 1.0)
  e:setCapacity(10.0)
  lurek.log.debug("new capacity: " .. tostring(e:getCapacity()), "graph") -- 10
end""",
    "LGraphEdge:setType": """\
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("a")
  local b = g:addNode("b")
  local e = g:addEdge(a, b, 1.0)
  e:setType("road")
  lurek.log.debug("edge type set: " .. tostring(e:getType()), "graph") -- "road"
end""",
    "LGraphNode:getEdges": """\
do
  local g = lurek.graph.newGraph()
  local a = g:addNode("city_a")
  local b = g:addNode("city_b")
  g:addEdge(a, b, 3.0)
  local edges = a:getEdges()
  lurek.log.debug("edges from a: " .. #edges, "graph") -- 1
end""",
    "LGraphNode:getItemCount": """\
do
  local g = lurek.graph.newGraph()
  local n = g:addNode("hub")
  n:addItem({name = "station"})
  n:addItem({name = "market"})
  lurek.log.debug("items on node: " .. n:getItemCount(), "graph") -- 2
end""",
    "LGraphNode:getItems": """\
do
  local g = lurek.graph.newGraph()
  local n = g:addNode("hub")
  n:addItem({kind = "port"})
  local items = n:getItems()
  lurek.log.debug("item kind: " .. tostring(items[1] and items[1].kind), "graph") -- "port"
end""",
    # HTML
    "LHtmlDocument:getHtml": """\
do
  local doc = lurek.html.newDocument()
  doc:setHtml("<p>Hello</p>")
  local html = doc:getHtml()
  lurek.log.debug("html: " .. html, "html")
end""",
    "LHtmlDocument:off": """\
do
  local doc = lurek.html.newDocument()
  local handler = function(evt) lurek.log.debug("clicked", "html") end
  doc:on("click", "#btn", handler)
  doc:off("click", "#btn", handler)
  lurek.log.debug("event listener removed", "html")
end""",
    "LHtmlDocument:on": """\
do
  local doc = lurek.html.newDocument()
  doc:setHtml('<button id="ok">OK</button>')
  doc:on("click", "#ok", function(evt)
    lurek.log.debug("button clicked in HTML UI", "html")
  end)
end""",
    "LHtmlDocument:query": """\
do
  local doc = lurek.html.newDocument()
  doc:setHtml('<div id="hud"><span class="hp">100</span></div>')
  local el = doc:query("#hud")
  lurek.log.debug("found element: " .. tostring(el ~= nil), "html")
end""",
    "LHtmlDocument:queryAll": """\
do
  local doc = lurek.html.newDocument()
  doc:setHtml('<ul><li>a</li><li>b</li><li>c</li></ul>')
  local items = doc:queryAll("li")
  lurek.log.debug("list items: " .. #items, "html") -- 3
end""",
    "LHtmlDocument:setHtml": """\
do
  local doc = lurek.html.newDocument()
  doc:setHtml("<h1>Game Over</h1><p>Score: 1234</p>")
  lurek.log.debug("html set", "html")
end""",
    # Image
    "LLayeredImage:getHeight": """\
do
  local img = lurek.image.newLayeredImage(128, 64)
  lurek.log.debug("height: " .. img:getHeight(), "image") -- 64
end""",
    "LLayeredImage:getWidth": """\
do
  local img = lurek.image.newLayeredImage(128, 64)
  lurek.log.debug("width: " .. img:getWidth(), "image") -- 128
end""",
    # Light
    "LLight:getLightMask": """\
do
  local l = lurek.light.newPoint(400, 300, 200, 1, 1, 0.8)
  local mask = l:getLightMask()
  lurek.log.debug("light mask: " .. tostring(mask), "light")
end""",
    "LLight:getPosition": """\
do
  local l = lurek.light.newPoint(200, 150, 180, 1, 0.9, 0.7)
  local x, y = l:getPosition()
  lurek.log.debug("light pos: " .. x .. "," .. y, "light") -- 200, 150
end""",
    "LLight:isEnabled": """\
do
  local l = lurek.light.newPoint(400, 300, 200, 1, 1, 0.8)
  lurek.log.debug("enabled: " .. tostring(l:isEnabled()), "light") -- true
end""",
    "LLight:isValid": """\
do
  local l = lurek.light.newPoint(400, 300, 200, 1, 1, 0.8)
  lurek.log.debug("valid: " .. tostring(l:isValid()), "light") -- true
  l:remove()
  lurek.log.debug("valid after remove: " .. tostring(l:isValid()), "light") -- false
end""",
    "LLight:remove": """\
do
  local l = lurek.light.newPoint(400, 300, 150, 1, 0.8, 0.6)
  l:remove()
  lurek.log.debug("light removed", "light")
end""",
    "LLight:setEnabled": """\
do
  local l = lurek.light.newPoint(400, 300, 200, 1, 1, 0.8)
  -- Flicker effect: disable then re-enable.
  l:setEnabled(false)
  lurek.log.debug("light off: " .. tostring(not l:isEnabled()), "light") -- true
  l:setEnabled(true)
end""",
    "LLight:setLightMask": """\
do
  local l = lurek.light.newPoint(400, 300, 200, 1, 1, 0.8)
  l:setLightMask(0xFF)
  lurek.log.debug("light mask set", "light")
end""",
    "LLight:setPosition": """\
do
  local l = lurek.light.newPoint(400, 300, 200, 1, 1, 0.8)
  l:setPosition(500, 200)
  local x, y = l:getPosition()
  lurek.log.debug("moved to: " .. x .. "," .. y, "light") -- 500, 200
end""",
    "lurek.light.isEnabled": """\
do
  lurek.light.setEnabled(true)
  local on = lurek.light.isEnabled()
  lurek.log.debug("lighting system enabled: " .. tostring(on), "light") -- true
end""",
    "lurek.light.setEnabled": """\
do
  -- Toggle the entire lighting system on/off (e.g., for a brightness option).
  lurek.light.setEnabled(false)
  lurek.log.debug("lighting disabled globally", "light")
  lurek.light.setEnabled(true)
end""",
    # Math
    "lurek.math.fbm": """\
do
  -- Fractional Brownian Motion: layered noise for terrain height maps.
  local h = lurek.math.fbm(0.3, 0.7, 4, 2.0, 0.5)
  lurek.log.debug("fbm height: " .. string.format("%.3f", h), "math")
end""",
    "lurek.math.lerp": """\
do
  -- Linear interpolation: lerp(a, b, t) where t=0 -> a, t=1 -> b.
  local v = lurek.math.lerp(10, 20, 0.25)
  lurek.log.debug("lerp(10,20,0.25) = " .. v, "math") -- 12.5
end""",
    "lurek.math.perlin2d": """\
do
  -- Smooth gradient noise in 2D. Good for terrain height or cloud density.
  local n = lurek.math.perlin2d(0.5, 0.3)
  lurek.log.debug("perlin2d: " .. string.format("%.3f", n), "math")
end""",
    "lurek.math.perlin3d": """\
do
  -- 3D Perlin noise: adds a time/z axis for animated effects.
  local n = lurek.math.perlin3d(0.5, 0.3, 1.0)
  lurek.log.debug("perlin3d: " .. string.format("%.3f", n), "math")
end""",
    "lurek.math.random": """\
do
  -- Seeded random float in [min, max).
  local rng = lurek.math.newRandomGenerator(42)
  local v = lurek.math.random(rng, 0.0, 1.0)
  lurek.log.debug("random float: " .. string.format("%.3f", v), "math")
end""",
    "lurek.math.randomInt": """\
do
  local rng = lurek.math.newRandomGenerator(42)
  local n = lurek.math.randomInt(rng, 1, 6) -- dice roll
  lurek.log.debug("dice roll: " .. n, "math")
end""",
    "lurek.math.simplex2d": """\
do
  -- Simplex noise: faster than Perlin, no directional artifacts.
  local n = lurek.math.simplex2d(0.5, 0.3)
  lurek.log.debug("simplex2d: " .. string.format("%.3f", n), "math")
end""",
    # Patterns LList
    "LList:add": """\
do
  local list = lurek.patterns.newList()
  list:add("sword")
  list:add("shield")
  list:add("potion")
  lurek.log.debug("list size after adds: " .. list:len(), "patterns") -- 3
end""",
    "LList:clear": """\
do
  local list = lurek.patterns.newList()
  list:add("a")
  list:add("b")
  list:clear()
  lurek.log.debug("list empty: " .. tostring(list:isEmpty()), "patterns") -- true
end""",
    "LList:get": """\
do
  local list = lurek.patterns.newList()
  list:add("alpha")
  list:add("beta")
  local item = list:get(1)
  lurek.log.debug("first item: " .. tostring(item), "patterns") -- "alpha"
end""",
    "LList:isEmpty": """\
do
  local list = lurek.patterns.newList()
  lurek.log.debug("empty before add: " .. tostring(list:isEmpty()), "patterns") -- true
  list:add("x")
  lurek.log.debug("empty after add: " .. tostring(list:isEmpty()), "patterns") -- false
end""",
    "LList:len": """\
do
  local list = lurek.patterns.newList()
  list:add("a")
  list:add("b")
  list:add("c")
  lurek.log.debug("len: " .. list:len(), "patterns") -- 3
end""",
    "LList:remove": """\
do
  local list = lurek.patterns.newList()
  list:add("keep")
  list:add("remove_me")
  list:remove("remove_me")
  lurek.log.debug("len after remove: " .. list:len(), "patterns") -- 1
end""",
    "LList:set": """\
do
  local list = lurek.patterns.newList()
  list:add("old_value")
  list:set(1, "new_value")
  lurek.log.debug("after set: " .. tostring(list:get(1)), "patterns") -- "new_value"
end""",
    "LList:toArray": """\
do
  local list = lurek.patterns.newList()
  list:add("x")
  list:add("y")
  local arr = list:toArray()
  lurek.log.debug("array len: " .. #arr .. " first: " .. arr[1], "patterns")
end""",
    # Physics
    "lurek.physics.isSleepingAllowed": """\
do
  lurek.physics.setSleepingAllowed(true)
  local allowed = lurek.physics.isSleepingAllowed()
  lurek.log.debug("sleeping allowed: " .. tostring(allowed), "physics") -- true
end""",
    "lurek.physics.newBody": """\
do
  -- newBody(world, x, y, type) creates a physics body without needing world:newBody.
  local world = lurek.physics.newWorld(0, 9.8)
  local body = lurek.physics.newBody(world, 200, 100, "dynamic")
  lurek.log.debug("body type: " .. body:type(), "physics") -- "LBody"
end""",
    "lurek.physics.setSleepingAllowed": """\
do
  -- Allow idle bodies to sleep (saves CPU when bodies are stationary).
  lurek.physics.setSleepingAllowed(true)
  lurek.log.debug("sleeping allowed globally", "physics")
end""",
    "lurek.physics.step": """\
do
  local world = lurek.physics.newWorld(0, 9.8)
  local body = world:newBody(200, 0, "dynamic")
  -- Advance the simulation by 1/60 s.
  lurek.physics.step(world, 1/60)
  local x, y = body:getPosition()
  lurek.log.debug("pos after step: " .. string.format("%.2f, %.2f", x, y), "physics")
end""",
    # Pipeline
    "LPipelineStep:getName": """\
do
  local steps = lurek.pipeline.getSteps()
  if steps and steps[1] then
    local name = steps[1]:getName()
    lurek.log.debug("first step: " .. tostring(name), "pipeline")
  end
end""",
    # Render primitives
    "lurek.render.arc": """\
do
  -- Draw a partial circle arc: center, radius, start/end angles, line width.
  lurek.render.setColor(0, 1, 0.5, 1)
  lurek.render.arc(200, 200, 80, 0, math.pi, 16)
end""",
    "lurek.render.circle": """\
do
  -- Draw a filled circle.
  lurek.render.setColor(1, 0.5, 0, 1)
  lurek.render.circle("fill", 400, 300, 50)
end""",
    "lurek.render.ellipse": """\
do
  -- Draw a filled ellipse: mode, x, y, radiusX, radiusY.
  lurek.render.setColor(0.3, 0.6, 1, 1)
  lurek.render.ellipse("fill", 300, 200, 80, 40)
end""",
    "lurek.render.getDimensions": """\
do
  local w, h = lurek.render.getDimensions()
  lurek.log.debug("canvas: " .. w .. "x" .. h, "render")
end""",
    "lurek.render.getHeight": """\
do
  local h = lurek.render.getHeight()
  lurek.log.debug("render height: " .. h .. " px", "render")
end""",
    "lurek.render.getWidth": """\
do
  local w = lurek.render.getWidth()
  lurek.log.debug("render width: " .. w .. " px", "render")
end""",
    "lurek.render.line": """\
do
  -- Draw a diagonal line from (100,100) to (400,300).
  lurek.render.setColor(1, 1, 0, 1)
  lurek.render.line(100, 100, 400, 300)
end""",
    "lurek.render.polygon": """\
do
  -- Draw a filled triangle using a vertex list.
  lurek.render.setColor(0.8, 0.2, 0.8, 1)
  lurek.render.polygon("fill", {200, 100, 100, 300, 300, 300})
end""",
    "lurek.render.rectangle": """\
do
  -- Draw a filled rectangle.
  lurek.render.setColor(0.2, 0.8, 0.2, 1)
  lurek.render.rectangle("fill", 100, 100, 200, 120)
end""",
    "lurek.render.resetCanvas": """\
do
  -- Reset to the default canvas (the screen) after rendering to a texture.
  lurek.render.resetCanvas()
  lurek.log.debug("canvas reset to screen", "render")
end""",
    "lurek.render.setLineWidth": """\
do
  -- Thicker lines for a bold UI outline.
  lurek.render.setLineWidth(3)
  lurek.render.setColor(1, 1, 1, 1)
  lurek.render.rectangle("line", 50, 50, 200, 100)
  lurek.render.setLineWidth(1) -- restore default
end""",
    "lurek.render.triangle": """\
do
  -- Draw a single triangle from three points.
  lurek.render.setColor(1, 0.2, 0.2, 1)
  lurek.render.triangle("fill", 200, 50, 100, 250, 300, 250)
end""",
    # Thread
    "LThread:getError": """\
do
  local t = lurek.thread.new(function()
    error("intentional test error")
  end)
  t:start()
  t:wait()
  local err = t:getError()
  lurek.log.debug("thread error: " .. tostring(err), "thread")
end""",
    # Tween
    "LTween:cancel": """\
do
  local obj = {x = 0}
  local tw = lurek.tween.to(obj, 2.0, {x = 100})
  -- Cancel the tween before it completes.
  tw:cancel()
  lurek.log.debug("tween cancelled; obj.x frozen at: " .. obj.x, "tween")
end""",
    "LTweenSequence:start": """\
do
  local obj = {x = 0, y = 0}
  local seq = lurek.tween.newSequence()
  seq:tween(lurek.tween.to(obj, 0.5, {x = 100}))
  seq:tween(lurek.tween.to(obj, 0.5, {y = 100}))
  seq:start()
  lurek.log.debug("sequence started", "tween")
end""",
    "LTweenSequence:tween": """\
do
  local obj = {alpha = 1}
  local seq = lurek.tween.newSequence()
  -- Chain two tweens: fade out then fade in.
  seq:tween(lurek.tween.to(obj, 0.3, {alpha = 0}))
  seq:tween(lurek.tween.to(obj, 0.3, {alpha = 1}))
  lurek.log.debug("sequence has 2 tweens", "tween")
end""",
    "lurek.tween.delay": """\
do
  -- Create a tween that waits N seconds before proceeding in a sequence.
  local pause = lurek.tween.delay(1.5)
  lurek.log.debug("delay tween: " .. pause:type(), "tween")
end""",
    "lurek.tween.update": """\
do
  local obj = {x = 0}
  local tw = lurek.tween.to(obj, 1.0, {x = 100})
  -- Manually advance the tween by 0.5 s.
  lurek.tween.update(tw, 0.5)
  lurek.log.debug("x after half-step: " .. string.format("%.1f", obj.x), "tween") -- ~50
end""",
    # UI
    "LButton:getText": """\
do
  local btn = lurek.ui.newButton(0, 0, 100, 30, "Start Game")
  local text = btn:getText()
  lurek.log.debug("button text: " .. text, "ui") -- "Start Game"
end""",
    "LButton:setText": """\
do
  local btn = lurek.ui.newButton(0, 0, 100, 30, "Play")
  btn:setText("Replay")
  lurek.log.debug("new label: " .. btn:getText(), "ui") -- "Replay"
end""",
    "LCheckbox:getText": """\
do
  local cb = lurek.ui.newCheckbox(0, 0, "Show FPS")
  local text = cb:getText()
  lurek.log.debug("checkbox label: " .. text, "ui") -- "Show FPS"
end""",
    "LCheckbox:isChecked": """\
do
  local cb = lurek.ui.newCheckbox(0, 0, "Fullscreen")
  cb:setChecked(true)
  lurek.log.debug("checked: " .. tostring(cb:isChecked()), "ui") -- true
end""",
    "LCheckbox:setChecked": """\
do
  local cb = lurek.ui.newCheckbox(0, 0, "Sound On")
  cb:setChecked(true)
  lurek.log.debug("checkbox toggled on", "ui")
end""",
    "LCheckbox:setText": """\
do
  local cb = lurek.ui.newCheckbox(0, 0, "Old Label")
  cb:setText("New Label")
  lurek.log.debug("new checkbox text: " .. cb:getText(), "ui")
end""",
    "LComboBox:addItem": """\
do
  local cb = lurek.ui.newComboBox(0, 0, 150, 30)
  cb:addItem("Easy")
  cb:addItem("Normal")
  cb:addItem("Hard")
  lurek.log.debug("combobox items: " .. cb:getItemCount(), "ui") -- 3
end""",
    "LComboBox:clearItems": """\
do
  local cb = lurek.ui.newComboBox(0, 0, 150, 30)
  cb:addItem("Old Option")
  cb:clearItems()
  lurek.log.debug("items after clear: " .. cb:getItemCount(), "ui") -- 0
end""",
    "LComboBox:getItem": """\
do
  local cb = lurek.ui.newComboBox(0, 0, 150, 30)
  cb:addItem("Option A")
  cb:addItem("Option B")
  local text = cb:getItem(1)
  lurek.log.debug("item 1: " .. text, "ui") -- "Option A"
end""",
    "LComboBox:getItemCount": """\
do
  local cb = lurek.ui.newComboBox(0, 0, 150, 30)
  cb:addItem("x")
  cb:addItem("y")
  lurek.log.debug("count: " .. cb:getItemCount(), "ui") -- 2
end""",
    "LComboBox:getSelectedIndex": """\
do
  local cb = lurek.ui.newComboBox(0, 0, 150, 30)
  cb:addItem("Easy")
  cb:addItem("Normal")
  cb:setSelectedIndex(2)
  lurek.log.debug("selected: " .. cb:getSelectedIndex(), "ui") -- 2
end""",
    "LComboBox:removeItem": """\
do
  local cb = lurek.ui.newComboBox(0, 0, 150, 30)
  cb:addItem("Alpha")
  cb:addItem("Beta")
  cb:addItem("Gamma")
  cb:removeItem(2)
  lurek.log.debug("items after remove: " .. cb:getItemCount(), "ui") -- 2
end""",
    "LComboBox:setSelectedIndex": """\
do
  local cb = lurek.ui.newComboBox(0, 0, 150, 30)
  cb:addItem("Low")
  cb:addItem("Medium")
  cb:addItem("High")
  cb:setSelectedIndex(3)
  lurek.log.debug("selected index: " .. cb:getSelectedIndex(), "ui") -- 3
end""",
    "LGuiWindow:getTitle": """\
do
  local win = lurek.ui.newWindow(50, 50, 400, 300, "Settings")
  local title = win:getTitle()
  lurek.log.debug("window title: " .. title, "ui") -- "Settings"
end""",
    "LGuiWindow:setOnClose": """\
do
  local win = lurek.ui.newWindow(50, 50, 300, 200, "Dialog")
  win:setOnClose(function()
    lurek.log.debug("window closed by player", "ui")
  end)
end""",
    "LGuiWindow:setTitle": """\
do
  local win = lurek.ui.newWindow(50, 50, 400, 300, "Old Title")
  win:setTitle("Inventory")
  lurek.log.debug("new title: " .. win:getTitle(), "ui") -- "Inventory"
end""",
    "LLabel:getText": """\
do
  local lbl = lurek.ui.newLabel(0, 0, "Score: 0")
  local text = lbl:getText()
  lurek.log.debug("label text: " .. text, "ui") -- "Score: 0"
end""",
    "LLabel:setText": """\
do
  local lbl = lurek.ui.newLabel(0, 0, "Score: 0")
  lbl:setText("Score: 1500")
  lurek.log.debug("updated label: " .. lbl:getText(), "ui")
end""",
    "LLineChart:addSeries": """\
do
  local chart = lurek.ui.newLineChart(0, 0, 400, 200)
  chart:addSeries("FPS", {60, 58, 62, 59, 61}, {r=0, g=1, b=0})
  lurek.log.debug("series added to line chart", "ui")
end""",
    "LLineChart:drawToImage": """\
do
  local chart = lurek.ui.newLineChart(0, 0, 400, 200)
  chart:addSeries("ping", {10, 15, 12, 8, 20})
  local img = chart:drawToImage()
  lurek.log.debug("chart drawn to image: " .. tostring(img ~= nil), "ui")
end""",
    "LLineChart:setYMax": """\
do
  local chart = lurek.ui.newLineChart(0, 0, 400, 200)
  chart:setYMax(100)
  lurek.log.debug("y-axis max set to 100", "ui")
end""",
    "LMenuItem:getText": """\
do
  local item = lurek.ui.newMenuItem("File")
  local text = item:getText()
  lurek.log.debug("menu item: " .. text, "ui") -- "File"
end""",
    "LMenuItem:setText": """\
do
  local item = lurek.ui.newMenuItem("Old")
  item:setText("New Game")
  lurek.log.debug("menu item updated: " .. item:getText(), "ui")
end""",
    "LPanel:getTitle": """\
do
  local panel = lurek.ui.newPanel(0, 0, 300, 200)
  panel:setTitle("Stats")
  local title = panel:getTitle()
  lurek.log.debug("panel title: " .. title, "ui") -- "Stats"
end""",
    "LPanel:setTitle": """\
do
  local panel = lurek.ui.newPanel(0, 0, 300, 200)
  panel:setTitle("Inventory")
  lurek.log.debug("panel title set", "ui")
end""",
    "LProgressBar:getProgress": """\
do
  local pb = lurek.ui.newProgressBar(0, 0, 200, 20)
  pb:setRange(0, 100)
  pb:setValue(75)
  local pct = pb:getProgress()
  lurek.log.debug("progress: " .. string.format("%.0f%%", pct * 100), "ui") -- 75%
end""",
    "LProgressBar:getValue": """\
do
  local pb = lurek.ui.newProgressBar(0, 0, 200, 20)
  pb:setRange(0, 200)
  pb:setValue(120)
  lurek.log.debug("value: " .. pb:getValue(), "ui") -- 120
end""",
    "LProgressBar:setRange": """\
do
  local pb = lurek.ui.newProgressBar(0, 0, 200, 20)
  pb:setRange(0, 1000)
  pb:setValue(500)
  lurek.log.debug("half-way at 500/1000", "ui")
end""",
    "LProgressBar:setValue": """\
do
  local pb = lurek.ui.newProgressBar(0, 0, 200, 20)
  pb:setRange(0, 100)
  pb:setValue(42)
  lurek.log.debug("progress bar set to 42", "ui")
end""",
    "LRadioButton:getText": """\
do
  local rb = lurek.ui.newRadioButton(0, 0, "Option A")
  local text = rb:getText()
  lurek.log.debug("radio text: " .. text, "ui") -- "Option A"
end""",
    "LRadioButton:setOnChange": """\
do
  local rb = lurek.ui.newRadioButton(0, 0, "Enable shadows")
  rb:setOnChange(function(checked)
    lurek.log.debug("shadows: " .. tostring(checked), "ui")
  end)
end""",
    "LRadioButton:setText": """\
do
  local rb = lurek.ui.newRadioButton(0, 0, "Old")
  rb:setText("New Option")
  lurek.log.debug("radio updated: " .. rb:getText(), "ui")
end""",
    "LScrollBar:setOnChange": """\
do
  local sb = lurek.ui.newScrollBar(0, 0, 200, 16, false)
  sb:setOnChange(function(val)
    lurek.log.debug("scroll: " .. tostring(val), "ui")
  end)
end""",
    "LScrollPanel:getContentSize": """\
do
  local sp = lurek.ui.newScrollPanel(0, 0, 300, 200)
  sp:setContentSize(600, 800)
  local w, h = sp:getContentSize()
  lurek.log.debug("content: " .. w .. "x" .. h, "ui") -- 600x800
end""",
    "LScrollPanel:getScrollPosition": """\
do
  local sp = lurek.ui.newScrollPanel(0, 0, 300, 200)
  sp:setContentSize(600, 800)
  sp:setScrollPosition(50, 100)
  local x, y = sp:getScrollPosition()
  lurek.log.debug("scroll pos: " .. x .. "," .. y, "ui") -- 50, 100
end""",
    "LScrollPanel:setContentSize": """\
do
  local sp = lurek.ui.newScrollPanel(0, 0, 300, 200)
  sp:setContentSize(1000, 2000)
  lurek.log.debug("content size set", "ui")
end""",
    "LScrollPanel:setScrollPosition": """\
do
  local sp = lurek.ui.newScrollPanel(0, 0, 300, 200)
  sp:setContentSize(600, 800)
  sp:setScrollPosition(0, 400)
  lurek.log.debug("scrolled to middle", "ui")
end""",
    "LSeparator:isVertical": """\
do
  local sep = lurek.ui.newSeparator(0, 0, 200, false)
  lurek.log.debug("is vertical: " .. tostring(sep:isVertical()), "ui") -- false
end""",
    "LSlider:getMax": """\
do
  local sl = lurek.ui.newSlider(0, 0, 200, 20)
  sl:setRange(0, 100)
  lurek.log.debug("max: " .. sl:getMax(), "ui") -- 100
end""",
    "LSlider:getMin": """\
do
  local sl = lurek.ui.newSlider(0, 0, 200, 20)
  sl:setRange(10, 100)
  lurek.log.debug("min: " .. sl:getMin(), "ui") -- 10
end""",
    "LSlider:getValue": """\
do
  local sl = lurek.ui.newSlider(0, 0, 200, 20)
  sl:setRange(0, 100)
  sl:setValue(60)
  lurek.log.debug("value: " .. sl:getValue(), "ui") -- 60
end""",
    "LSlider:setRange": """\
do
  local volume_slider = lurek.ui.newSlider(0, 0, 200, 20)
  volume_slider:setRange(0, 100)
  volume_slider:setValue(70)
  lurek.log.debug("volume: " .. volume_slider:getValue(), "ui") -- 70
end""",
    "LSlider:setStep": """\
do
  local sl = lurek.ui.newSlider(0, 0, 200, 20)
  sl:setRange(0, 100)
  sl:setStep(5) -- snap to multiples of 5
  lurek.log.debug("step set to 5", "ui")
end""",
    "LSlider:setValue": """\
do
  local sl = lurek.ui.newSlider(0, 0, 200, 20)
  sl:setRange(0, 100)
  sl:setValue(45)
  lurek.log.debug("slider at 45", "ui")
end""",
    "LSplitPanel:getOrientation": """\
do
  local sp = lurek.ui.newSplitPanel(0, 0, 400, 300, "horizontal")
  local ori = sp:getOrientation()
  lurek.log.debug("orientation: " .. ori, "ui") -- "horizontal"
end""",
    "LSplitPanel:setOrientation": """\
do
  local sp = lurek.ui.newSplitPanel(0, 0, 400, 300, "horizontal")
  sp:setOrientation("vertical")
  lurek.log.debug("now vertical", "ui")
end""",
    "LStatusBar:addSection": """\
do
  local sb = lurek.ui.newStatusBar(0, 580, 800, 20)
  sb:addSection("FPS: 60", 100)
  sb:addSection("Map: Forest", 150)
  lurek.log.debug("sections: " .. sb:getSectionCount(), "ui")
end""",
    "LStatusBar:getSectionCount": """\
do
  local sb = lurek.ui.newStatusBar(0, 580, 800, 20)
  sb:addSection("Health", 80)
  sb:addSection("Mana", 80)
  lurek.log.debug("section count: " .. sb:getSectionCount(), "ui") -- 2
end""",
    "LTextInput:getText": """\
do
  local ti = lurek.ui.newTextInput(0, 0, 200, 30)
  ti:setText("hello world")
  local t = ti:getText()
  lurek.log.debug("input text: " .. t, "ui") -- "hello world"
end""",
    "LTextInput:setText": """\
do
  local ti = lurek.ui.newTextInput(0, 0, 200, 30)
  ti:setText("placeholder text")
  lurek.log.debug("set text in input field", "ui")
end""",
    "LToolbar:addButton": """\
do
  local tb = lurek.ui.newToolbar(0, 0, 800, 30)
  tb:addButton("New", function()
    lurek.log.debug("toolbar: New clicked", "ui")
  end)
  tb:addButton("Save", function()
    lurek.log.debug("toolbar: Save clicked", "ui")
  end)
  lurek.log.debug("2 buttons added to toolbar", "ui")
end""",
    "LUiWidget:setOnChange": """\
do
  local sl = lurek.ui.newSlider(0, 0, 200, 20)
  sl:setRange(0, 100)
  sl:setOnChange(function(val)
    lurek.log.debug("slider changed to " .. tostring(val), "ui")
  end)
end""",
    "LUiWidget:setOnClick": """\
do
  local btn = lurek.ui.newButton(0, 0, 120, 30, "OK")
  btn:setOnClick(function()
    lurek.log.debug("OK button clicked", "ui")
  end)
end""",
    "lurek.ui.drawToImage": """\
do
  -- Render a UI widget tree to an off-screen image for thumbnails or minimap overlays.
  local panel = lurek.ui.newPanel(0, 0, 200, 150)
  panel:setTitle("Preview")
  local img = lurek.ui.drawToImage(panel, 200, 150)
  lurek.log.debug("UI drawn to image: " .. tostring(img ~= nil), "ui")
end""",
    # event
    "lurek.event.emit": """\
do
  lurek.event.on("score_changed", function(data)
    lurek.log.debug("score: " .. tostring(data.score), "event")
  end)
  lurek.event.emit("score_changed", {score = 1500})
end""",
    # scene
    "LScene:type": """\
do
  local s = lurek.scene.new()
  lurek.log.debug("type: " .. s:type(), "scene") -- "LScene"
end""",
    "LScene:typeOf": """\
do
  local s = lurek.scene.new()
  lurek.log.debug("typeOf LScene: " .. tostring(s:typeOf("LScene")), "scene") -- true
end""",
}


# ---------------------------------------------------------------------------
# type/typeOf code generator
# ---------------------------------------------------------------------------
def make_type_block(type_name: str, constructor: str) -> str:
    var = "obj"
    return (
        f"do\n"
        f"  local {var} = {constructor}\n"
        f"  lurek.log.debug(\"type: \" .. {var}:type(), \"example\") -- \"{type_name}\"\n"
        f"end"
    )


def make_typeof_block(type_name: str, constructor: str) -> str:
    var = "obj"
    return (
        f"do\n"
        f"  local {var} = {constructor}\n"
        f"  lurek.log.debug(\"typeOf {type_name}: \" .. tostring({var}:typeOf(\"{type_name}\")), \"example\") -- true\n"
        f"end"
    )


# ---------------------------------------------------------------------------
# Main processing
# ---------------------------------------------------------------------------
EXAMPLES_DIR = os.path.join(os.path.dirname(__file__), '..', '..', 'content', 'examples')
EXAMPLES_DIR = os.path.normpath(EXAMPLES_DIR)

# Regex: match a stub block header + TODO line + remaining stub lines
STUB_HEADER = re.compile(
    r'(-- ---- Stub: \S+ -+\n'
    r'--@api-stub: (\S+)\n'
    r'-- [^\n]+\n)'          # description line
    r'-- TODO:[^\n]+\n'       # TODO line (to be removed)
    r'(?:-- [^\n]+\n)*'      # any remaining comment lines
)


def build_replacement(api_name: str) -> str | None:
    """Return a real do...end block for the given api_name, or None if unknown."""
    # Explicit override?
    if api_name in EXPLICIT:
        return EXPLICIT[api_name]

    # type / typeOf
    if ":" in api_name:
        type_name, method = api_name.split(":", 1)
        ctor = CONSTRUCTORS.get(type_name)
        if ctor:
            if method == "type":
                return make_type_block(type_name, ctor)
            if method == "typeOf":
                return make_typeof_block(type_name, ctor)
    return None


def process_file(path: str) -> tuple[int, int]:
    """Return (replaced, skipped) counts."""
    with open(path, encoding="utf-8") as f:
        content = f.read()

    replaced = 0
    skipped = 0
    output = []
    pos = 0

    for m in STUB_HEADER.finditer(content):
        api_name = m.group(2)
        impl = build_replacement(api_name)
        if impl is None:
            skipped += 1
            # Keep original
            output.append(content[pos:m.end()])
            pos = m.end()
            continue

        # Keep the separator + api-stub header, replace TODO body with impl
        header = m.group(1)   # separator + --@api-stub: + description
        output.append(content[pos:m.start()])   # text before this stub
        output.append(header)
        output.append(impl)
        output.append("\n")
        pos = m.end()
        replaced += 1

    output.append(content[pos:])  # remainder
    new_content = "".join(output)

    if new_content != content:
        if not DRY_RUN:
            with open(path, "w", encoding="utf-8", newline="\n") as f:
                f.write(new_content)

    return replaced, skipped


total_replaced = 0
total_skipped = 0
for filename in sorted(os.listdir(EXAMPLES_DIR)):
    if not filename.endswith(".lua"):
        continue
    path = os.path.join(EXAMPLES_DIR, filename)
    r, s = process_file(path)
    if r or s:
        status = f"  +{r} replaced" + (f", {s} skipped" if s else "")
        print(f"{filename}{status}")
    total_replaced += r
    total_skipped += s

print(f"\nDone. {total_replaced} stubs implemented, {total_skipped} unknown (skipped).")
if DRY_RUN:
    print("(DRY RUN — no files written)")
