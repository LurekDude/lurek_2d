-- content/examples/input.lua
-- lurek.input API examples.
-- Run: cargo run -- content/examples/input.lua

--@api-stub: lurek.input.isDown
-- Returns true if down for Lua scripts in this module
do
  function lurek.process(dt)
    if lurek.input.keyboard.isDown("space", "w", "up") then
      lurek.log.debug("jump key held", "input")
    end
  end
end

--@api-stub: lurek.input.isScancodeDown
-- Returns true if this input scancode down.
do
  function lurek.process(dt)
    if lurek.input.keyboard.isScancodeDown("a") then
      lurek.log.debug("strafe-left scancode held", "input")
    end
  end
end

--@api-stub: lurek.input.setKeyRepeat
-- Sets the key repeat of this input.
do
  lurek.input.keyboard.setKeyRepeat(true)
  lurek.log.info("key repeat enabled for menu navigation", "input")
end

--@api-stub: lurek.input.hasKeyRepeat
-- Returns true if this input has a key repeat.
do
  local enabled = lurek.input.keyboard.hasKeyRepeat()
  if not enabled then
    lurek.log.warn("key repeat disabled â€” menus will feel sluggish", "input")
  end
end

--@api-stub: lurek.input.setTextInput
-- Sets the text input of this input.
do
  local function open_chat()
    lurek.input.keyboard.setTextInput(true)
    lurek.log.info("chat box focused; text input on", "input")
  end
  open_chat()
end

--@api-stub: lurek.input.hasTextInput
-- Returns true if this input has a text input.
do
  function lurek.process(dt)
    if lurek.input.keyboard.hasTextInput() then
      return  -- typing in chat: do not move the player
    end
  end
end

--@api-stub: lurek.input.getScancodeFromKey
-- Returns the scancode from key of this input.
do
  local sc = lurek.input.keyboard.getScancodeFromKey("space")
  if sc then
    lurek.log.debug("space maps to scancode " .. sc, "input")
  end
end

--@api-stub: lurek.input.getKeyFromScancode
-- Returns the key from scancode of this input.
do
  local key_name = lurek.input.keyboard.getKeyFromScancode("lshift")
  local label = key_name or "unbound"
  lurek.log.info("crouch is bound to: " .. label, "ui")
end

--@api-stub: lurek.input.isModifierActive
-- Returns true if this input is currently active.
do
  function lurek.process(dt)
    if lurek.input.keyboard.isModifierActive("ctrl") and lurek.input.keyboard.isDown("s") then
      lurek.log.info("ctrl+s pressed: triggering save", "input")
    end
  end
end

--@api-stub: lurek.input.getPosition
-- Returns the position of this input.
do
  function lurek.process(dt)
    local mx, my = lurek.input.mouse.getPosition()
    lurek.log.debug("cursor at " .. mx .. "," .. my, "input")
  end
end

--@api-stub: lurek.input.getX
-- Returns the x of this input.
do
  function lurek.process(dt)
    local x = lurek.input.mouse.getX()
    local volume = math.max(0, math.min(1, x / 800))
    lurek.log.debug("volume slider: " .. volume, "ui")
  end
end

--@api-stub: lurek.input.getY
-- Returns the y of this input.
do
  function lurek.process(dt)
    local y = lurek.input.mouse.getY()
    if y < 32 then
      lurek.log.debug("cursor in top menu strip", "ui")
    end
  end
end


--@api-stub: lurek.input.setVisible
-- Sets the visibility flag for this input.
do
  lurek.input.mouse.setVisible(false)
  lurek.log.info("cursor hidden for cinematic", "input")
end

--@api-stub: lurek.input.isVisible
-- Returns true if this input is currently visible.
do
  if not lurek.input.mouse.isVisible() then
    lurek.input.mouse.setVisible(true)
    lurek.log.info("pause menu opened: cursor restored", "ui")
  end
end

--@api-stub: lurek.input.setGrabbed
-- Sets the grabbed of this input.
do
  lurek.input.mouse.setGrabbed(true)
  lurek.input.mouse.setRelativeMode(true)
  lurek.log.info("entered mouselook mode", "input")
end

--@api-stub: lurek.input.isGrabbed
-- Returns true if this input grabbed.
do
  if lurek.input.mouse.isGrabbed() then
    lurek.log.debug("cursor locked to window: focus changes will need to release", "input")
  end
end

--@api-stub: lurek.input.setRelativeMode
-- Sets the relative mode of this input.
do
  lurek.input.mouse.setRelativeMode(true)
  lurek.log.info("relative mouse mode on â€” read dx/dy from mousemoved", "input")
end

--@api-stub: lurek.input.getRelativeMode
-- Returns the relative mode of this input.
do
  function lurek.process(dt)
    if lurek.input.mouse.getRelativeMode() then
      lurek.log.debug("camera should integrate dx/dy this frame", "camera")
    end
  end
end

--@api-stub: lurek.input.setPosition
-- Sets the position of this input.
do
  local cx, cy = 400, 300
  lurek.input.mouse.setPosition(cx, cy)
  lurek.log.debug("cursor recentred to " .. cx .. "," .. cy, "input")
end

--@api-stub: lurek.input.setCursor
-- Sets the cursor of this input.
do
  lurek.input.mouse.setCursor("hand")
  lurek.log.debug("cursor: hand (over clickable link)", "ui")
end

--@api-stub: lurek.input.newCursor
-- Creates and returns a new cursor widget or object.
do
  local w, h = 2, 2
  local pixels = { 255,0,0,255,  0,255,0,255,  0,0,255,255,  255,255,255,255 }
  local cur = lurek.input.mouse.newCursor(pixels, w, h, 0, 0)
  lurek.input.mouse.setCursor(cur)
end

--@api-stub: lurek.input.getSystemCursor
-- Returns the system cursor of this input.
do
  local crosshair = lurek.input.mouse.getSystemCursor("crosshair")
  function lurek.process(dt)
    lurek.input.mouse.setCursor(crosshair)
  end
end

--@api-stub: lurek.input.isCursorSupported
-- Returns true if this input cursor supported.
do
  if lurek.input.mouse.isCursorSupported() then
    lurek.input.mouse.setCursor("hand")
  else
    lurek.log.warn("custom cursors unsupported â€” keeping default arrow", "input")
  end
end

--@api-stub: lurek.input.getCursor
-- Returns the cursor of this input.
do
  local name = lurek.input.mouse.getCursor()
  lurek.log.debug("active cursor shape: " .. name, "ui")
end

--@api-stub: lurek.input.getWheelDelta
-- Returns the wheel delta of this input.
do
  function lurek.process(dt)
    local dx, dy = lurek.input.mouse.getWheelDelta()
    if dy ~= 0 then
      lurek.log.debug("zoom by " .. dy, "camera")
    end
  end
end

--@api-stub: lurek.input.getCount
-- Returns the total count of items held by this input.
do
  local n = lurek.input.gamepad.getCount()
  lurek.log.info("connected gamepads: " .. n, "input")
end

--@api-stub: lurek.input.getJoystickCount
-- Returns the number of joystick items in this input.
do
  local slots = lurek.input.gamepad.getJoystickCount()
  if slots == 0 then
    lurek.log.info("no gamepads tracked yet", "input")
  end
end

--@api-stub: lurek.input.getJoysticks
-- Returns the joysticks of this input.
do
  local ids = lurek.input.gamepad.getJoysticks()
  for i, id in ipairs(ids) do
    lurek.log.debug("player " .. i .. " is gamepad id " .. id, "input")
  end
end

--@api-stub: lurek.input.isConnected
-- Returns true if this input connected.
do
  local id = 0
  if not lurek.input.gamepad.isConnected(id) then
    lurek.log.warn("player 1 controller disconnected", "input")
  end
end

--@api-stub: lurek.input.getName
-- Returns the name of this input.
do
  local id = 0
  local name = lurek.input.gamepad.getName(id)
  lurek.log.info("gamepad " .. id .. ": " .. name, "input")
end

--@api-stub: lurek.input.isGamepad
-- Returns true if this input gamepad.
do
  local id = 0
  if lurek.input.gamepad.isGamepad(id) then
    lurek.log.debug("slot " .. id .. " has a recognised gamepad mapping", "input")
  end
end

--@api-stub: lurek.input.getButtonCount
-- Returns the number of button items in this input.
do
  local id = 0
  local nbtn = lurek.input.gamepad.getButtonCount(id)
  lurek.log.debug("gamepad " .. id .. " has " .. nbtn .. " buttons", "input")
end

--@api-stub: lurek.input.getAxisCount
-- Returns the number of axis items in this input.
do
  local id = 0
  local naxis = lurek.input.gamepad.getAxisCount(id)
  if naxis < 4 then
    lurek.log.warn("gamepad " .. id .. " has only " .. naxis .. " axes â€” dual-stick aiming unavailable", "input")
  end
end

  end

--@api-stub: lurek.input.getAxis
-- Returns the axis of this input.
do
  function lurek.process(dt)
    local lx = lurek.input.gamepad.getAxis(0, 0)
    if math.abs(lx) > 0.15 then
      lurek.log.debug("player 1 left stick X = " .. lx, "input")
    end
  end
end

--@api-stub: lurek.input.isVibrationSupported
-- Returns true if this input vibration supported.
do
  local id = 0
  if lurek.input.gamepad.isVibrationSupported(id) then
    lurek.log.info("gamepad " .. id .. " supports rumble", "input")
  end
end

--@api-stub: lurek.input.vibrate
-- Performs the vibrate operation on this input.
do
  local ok = lurek.input.gamepad.vibrate(0, 0.4, 0.8, 250)
  if not ok then
    lurek.log.debug("rumble request ignored (no haptics backend)", "input")
  end
end

--@api-stub: lurek.input.getGUID
-- Returns the guid of this input.
do
  local guid = lurek.input.gamepad.getGUID(0)
  if guid ~= "" then
    lurek.log.debug("gamepad 0 GUID: " .. guid, "input")
  end
end

--@api-stub: lurek.input.getHat
-- Returns the hat of this input.
do
  local dir = lurek.input.gamepad.getHat(0, 0)
  if dir ~= "c" then
    lurek.log.debug("hat 0 = " .. dir, "input")
  end
end

--@api-stub: lurek.input.setVibration
-- Sets the vibration of this input.
do
  local ok = lurek.input.gamepad.setVibration(0, 0.5, 0.5, 200)
  lurek.log.debug("setVibration returned " .. tostring(ok), "input")
end

--@api-stub: lurek.input.wasPressed
-- Was pressed for Lua scripts in this module
do
  function lurek.process(dt)
    if lurek.input.gamepad.wasPressed(0, 0) then
      lurek.log.info("gamepad A just pressed", "input")
    end
  end
end

--@api-stub: lurek.input.wasReleased
-- Was released for Lua scripts in this module
do
  function lurek.process(dt)
    if lurek.input.gamepad.wasReleased(0, 0) then
      lurek.log.info("gamepad A just released", "input")
    end
  end
end

--@api-stub: lurek.input.wasConnected
-- Performs the was connected operation on this input.
do
  function lurek.process(dt)
    if lurek.input.gamepad.wasConnected(0) then
      lurek.log.info("player 1 controller connected", "input")
    end
  end
end

--@api-stub: lurek.input.wasDisconnected
-- Performs the was disconnected operation on this input.
do
  function lurek.process(dt)
    if lurek.input.gamepad.wasDisconnected(0) then
      lurek.log.warn("controller disconnected", "input")
    end
  end
end

--@api-stub: lurek.input.virtualDpad
-- Performs the virtual dpad operation on this input.
do
  local leftx = lurek.input.gamepad.getAxis(0, 0)
  local lefty = lurek.input.gamepad.getAxis(0, 1)
  local pad = lurek.input.gamepad.virtualDpad(leftx, lefty, 0.25)
  if pad.direction ~= "c" then
    lurek.log.debug("virtual dpad direction: " .. pad.direction, "input")
  end
end

--@api-stub: lurek.input.setBackgroundEvents
-- Sets the background events of this input.
do
  lurek.input.gamepad.setBackgroundEvents(true)
  lurek.log.info("gamepad input continues while window is unfocused", "input")
end

--@api-stub: lurek.input.getBackgroundEvents
-- Returns the background events of this input.
do
  local on = lurek.input.gamepad.getBackgroundEvents()
  if on then
    lurek.log.debug("background gamepad events: enabled", "input")
  end
end

--@api-stub: lurek.input.setGamepadMapping
-- Sets the gamepad mapping of this input.
do
  local guid = "030000005e040000130b000011050000"
  local mapping = guid .. ",My Custom Pad,a:b0,b:b1,x:b2,y:b3,start:b7,back:b6,"
  lurek.input.gamepad.setGamepadMapping(guid, mapping)
  lurek.log.info("custom mapping stored for " .. guid, "input")
end

--@api-stub: lurek.input.getGamepadMappingString
-- Returns the gamepad mapping string of this input.
do
  local guid = "030000005e040000130b000011050000"
  local mapping = lurek.input.gamepad.getGamepadMappingString(guid)
  if mapping then
    lurek.log.debug("override mapping length: " .. #mapping, "input")
  end
end

--@api-stub: lurek.input.loadGamepadMappings
-- Loads gamepad mappings into this input.
do
  local ok, n = pcall(lurek.input.gamepad.loadGamepadMappings, "save/gamecontrollerdb.txt")
  if ok then lurek.log.info("loaded " .. n .. " controller mappings", "input") end
end

--@api-stub: lurek.input.saveGamepadMappings
-- Saves the current state of this input.
do
  lurek.input.gamepad.saveGamepadMappings("save/user_mappings.txt")
  lurek.log.info("user gamepad mappings written", "input")
end

--@api-stub: lurek.input.getTouches
-- Returns the touches of this input.
do
  function lurek.process(dt)
    local touches = lurek.input.touch.getTouches()
    for _, tp in ipairs(touches) do
      lurek.log.debug("touch " .. tp.id .. " at " .. tp.x .. "," .. tp.y, "input")
    end
  end
end

  end

--@api-stub: lurek.input.getPressure
-- Returns the pressure of this input.
do
  function lurek.process(dt)
    local touches = lurek.input.touch.getTouches()
    if touches[1] then
      local p = lurek.input.touch.getPressure(touches[1].id)
      if p > 0.5 then
        lurek.log.debug("firm touch (pressure " .. p .. ")", "input")
      end
    end
  end
end

--@api-stub: lurek.input.getTouchCount
-- Returns the number of touch items in this input.
do
  function lurek.process(dt)
    if lurek.input.touch.getTouchCount() >= 2 then
      lurek.log.debug("multi-touch gesture in progress", "input")
    end
  end
end


--@api-stub: lurek.input.bind
-- Adds one or more keyboard/gamepad bindings to an action
do
  lurek.input.bind("jump", "space")
  lurek.input.bind("move_left", { "a", "left" })
  lurek.log.info("default bindings installed", "input")
end

--@api-stub: lurek.input.unbind
-- Removes all bindings for an action
do
  lurek.input.bind("jump", "space")
  local existed = lurek.input.unbind("jump")
  lurek.log.debug("unbind jump returned " .. tostring(existed), "input")
end

--@api-stub: lurek.input.clearBindings
-- Removes all action bindings
do
  lurek.input.bind("jump", "space")
  lurek.input.clearBindings()
  lurek.log.info("all action bindings cleared", "input")
end

--@api-stub: lurek.input.getBindings
-- Returns all action bindings
do
  lurek.input.bind("jump", "space")
  local bindings = lurek.input.getBindings()
  for action, keys in pairs(bindings) do
    lurek.log.debug(action .. " <- " .. table.concat(keys, ","), "input")
  end
end

--@api-stub: lurek.input.isActionDown
-- Returns whether any binding for an action is currently down
do
  lurek.input.bind("jump", { "space", "w" })
  function lurek.process(dt)
    if lurek.input.isActionDown("jump") then
      lurek.log.debug("jump action held", "input")
    end
  end
end

--@api-stub: lurek.input.wasActionPressed
-- Returns whether any binding for an action was pressed this frame and records the frame
do
  lurek.input.bind("confirm", "return")
  function lurek.process(dt)
    if lurek.input.wasActionPressed("confirm") then
      lurek.log.info("menu: option selected", "ui")
    end
  end
end

--@api-stub: lurek.input.wasActionReleased
-- Returns whether any binding for an action was released this frame
do
  lurek.input.bind("shoot", "left")
  function lurek.process(dt)
    if lurek.input.wasActionReleased("shoot") then
      lurek.log.info("charged shot released", "combat")
    end
  end
end

--@api-stub: lurek.input.wasActionPressedWithin
-- Returns whether an action was pressed within a recent frame window
do
  lurek.input.bind("jump", "space")
  function lurek.process(dt)
    if lurek.input.wasActionPressedWithin("jump", 6) then
      lurek.log.debug("buffered jump within last 6 frames", "input")
    end
  end
end

--@api-stub: lurek.input.newMapping
-- Creates an action mapping table with isDown, wasPressed, and wasReleased helper functions
do
  local dash = lurek.input.newMapping("dash", {"shift", "gamepad:0:0"})
  function lurek.process(dt)
    if dash.wasPressed() then
      lurek.log.info("dash triggered", "input")
    end
  end
end

--@api-stub: lurek.input.newCombo
-- Creates a combo detector from string steps or step tables with optional timing
do
  local hadouken = lurek.input.newCombo(
    { "down", { key = "right", gap = 300 }, "a" },
    { total_gap = 1500 }
  )
  lurek.log.info("combo detector ready (" .. hadouken:totalSteps() .. " steps)", "combat")
end

--@api-stub: lurek.input.startRecording
-- Starts recording input events into the module recorder
do
  lurek.input.startRecording()
  lurek.log.info("input recording started", "replay")
end

--@api-stub: lurek.input.stopRecording
-- Stops input recording and returns the captured recording when one is active
do
  lurek.input.startRecording()
  local rec = lurek.input.stopRecording()
  if rec then
    lurek.log.info("captured " .. rec:totalFrames() .. " frames", "replay")
  end
end

--@api-stub: lurek.input.loadRecording
-- Loads recording JSON into the module recorder
do
  local json = '{"version":1,"total_frames":1,"frames":[]}'
  lurek.input.loadRecording(json)
  lurek.log.info("recording loaded for playback", "replay")
end

--@api-stub: lurek.input.startPlayback
-- Starts playback of the loaded recording
do
  local json = '{"version":1,"total_frames":1,"frames":[]}'
  lurek.input.loadRecording(json)
  lurek.input.startPlayback()
  lurek.log.info("playback armed", "replay")
end

--@api-stub: lurek.input.stopPlayback
-- Stops playback of the loaded recording
do
  lurek.input.stopPlayback()
  lurek.log.info("playback halted; live input restored", "replay")
end

--@api-stub: lurek.input.isRecording
-- Returns whether the module recorder is currently recording
do
  if lurek.input.isRecording() then
    lurek.log.debug("REC indicator: visible", "ui")
  end
end

--@api-stub: lurek.input.isPlayingBack
-- Returns whether the module recorder is currently playing back
do
  function lurek.process(dt)
    if lurek.input.isPlayingBack() then
      return  -- skip live-input branch this frame
    end
  end
end

--@api-stub: lurek.input.getPlaybackFrame
-- Returns the current playback frame index
do
  function lurek.process(dt)
    local f = lurek.input.getPlaybackFrame()
    if f > 0 and f % 60 == 0 then
      lurek.log.debug("playback at frame " .. f, "replay")
    end
  end
end

--@api-stub: lurek.input.advancePlayback
-- Advances playback by one frame and returns events for that frame
do
  function lurek.process(dt)
    local events = lurek.input.advancePlayback()
    for _, ev in ipairs(events) do
      lurek.log.debug("playback event " .. ev.kind .. " " .. ev.name, "replay")
    end
  end
end

-- Cursor methods

--@api-stub: Cursor:release
-- Performs the release operation on this cursor.
do
  local cur = lurek.input.mouse.getSystemCursor("hand")
  cur:release()
  lurek.log.debug("cursor handle released (no-op on desktop)", "input")
end

--@api-stub: Cursor:getType
-- Returns the type of this cursor.
do
  local cur = lurek.input.mouse.getSystemCursor("crosshair")
  local kind = cur:getType()
  lurek.log.debug("cursor kind: " .. kind, "input")
end

-- Combo methods

--@api-stub: Combo:feed
-- Performs the feed operation on this combo.
do
  local combo = lurek.input.newCombo({ "down", "right", "a" })
  local progress = combo:feed("down")
  lurek.log.debug("combo step result: " .. progress, "combat")
end

--@api-stub: Combo:tick
-- Performs the tick operation on this combo.
do
  local combo = lurek.input.newCombo({ "down", "right", "a" })
  function lurek.process(dt)
    local status = combo:tick(dt)
    if status == "expired" then
      lurek.log.debug("combo window expired", "combat")
    end
  end
end

--@api-stub: Combo:reset
-- Resets this combo to its default state.
do
  local combo = lurek.input.newCombo({ "down", "right", "a" })
  combo:feed("down")
  combo:reset()
  lurek.log.debug("combo cleared after stagger", "combat")
end

--@api-stub: Combo:totalSteps
-- Performs the total steps operation on this combo.
do
  local combo = lurek.input.newCombo({ "down", "right", "a" })
  local total = combo:totalSteps()
  lurek.log.debug("combo length: " .. total, "combat")
end

--@api-stub: Combo:isInProgress
-- Returns true if this combo in progress.
do
  local combo = lurek.input.newCombo({ "down", "right", "a" })
  combo:feed("down")
  if combo:isInProgress() then
    lurek.log.debug("combo HUD: visible", "ui")
  end
end

--@api-stub: Combo:getStep
-- Returns the step of this combo.
do
  local combo = lurek.input.newCombo({ "down", { key = "right", gap = 300 }, "a" })
  local step = combo:getStep(2)
  if step then
    lurek.log.debug("step 2: key=" .. step.key .. " gap=" .. step.gap_ms .. "ms", "combat")
  end
end

-- InputRecording methods

--@api-stub: InputRecording:toJson
-- Performs the to json operation on this input recording.
do
  lurek.input.startRecording()
  local rec = lurek.input.stopRecording()
  if rec then
    local json = rec:toJson()
    lurek.log.debug("serialised recording: " .. #json .. " bytes", "replay")
  end
end

--@api-stub: InputRecording:totalFrames
-- Performs the total frames operation on this input recording.
do
  lurek.input.startRecording()
  local rec = lurek.input.stopRecording()
  if rec then
    lurek.log.info("recorded " .. rec:totalFrames() .. " frames", "replay")
  end
end

--@api-stub: InputRecording:frameCount
-- Performs the frame count operation on this input recording.
do
  lurek.input.startRecording()
  local rec = lurek.input.stopRecording()
  if rec and rec:frameCount() == 0 then
    lurek.log.warn("recording has no input events", "replay")
  end
end

--@api-stub: Combo:progress
-- Performs the progress operation on this combo.
do
  local combo = lurek.input.newCombo({"right","right","attack"})
  combo:feed("right")
  local pct = combo:progress()
  lurek.log.info("combo progress: " .. pct, "input")
end

--@api-stub: lurek.input.gamepad.loadGamepadMappings
-- Loads gamepad mapping strings from a file
do
  -- loadGamepadMappings may not be available headless; guard with pcall
  local ok, count = pcall(lurek.input.gamepad.loadGamepadMappings, "assets/gamecontrollerdb.txt")
  lurek.log.info("loadGamepadMappings ok=" .. tostring(ok), "input")
end


-- -----------------------------------------------------------------------------
-- InputRecording methods
-- -----------------------------------------------------------------------------

--@api-stub: LCombo:type
-- Returns the Lua-visible type name for this combo handle
do
  local ok ---@type boolean
  local combo_obj ---@type LCombo?
  ok, combo_obj = pcall(lurek.input.newCombo, {"a","b"}, {})
  if not ok then combo_obj = nil end
  local t = combo_obj and combo_obj:type() or "LInputCombo"
  lurek.log.info("LCombo:type = " .. t, "input")
end
--@api-stub: LCombo:typeOf
-- Returns whether this combo handle matches a supported type name
do
  local ok_c2 ---@type boolean
  local combo_obj2 ---@type LCombo?
  ok_c2, combo_obj2 = pcall(lurek.input.newCombo, {"a","b"}, {})
  if not ok_c2 then combo_obj2 = nil end
  lurek.log.info("is LCombo: " .. tostring(combo_obj2 and combo_obj2:typeOf("LCombo") or false), "input")
  lurek.log.info("is wrong: " .. tostring(combo_obj2 and combo_obj2:typeOf("Unknown") or false), "input")
end
--@api-stub: LCursor:type
-- Returns the Lua-visible type name for this cursor handle
do
  local ok_c, cursor_obj = pcall(lurek.input.mouse.newCursor)
  if ok_c and cursor_obj then
    local t = cursor_obj:type()
    lurek.log.info("LCursor:type = " .. t, "input")
  else
    lurek.log.info("LCursor:type = skipped", "input")
  end
end
--@api-stub: LCursor:typeOf
-- Returns whether this cursor handle matches a supported type name
do
  local ok_c2, cursor_obj = pcall(lurek.input.mouse.newCursor)
  if ok_c2 and cursor_obj then
    lurek.log.info("is LCursor: " .. tostring(cursor_obj:typeOf("LCursor")), "input")
    lurek.log.info("is wrong: " .. tostring(cursor_obj:typeOf("Unknown")), "input")
  else
    lurek.log.info("LCursor:typeOf = skipped", "input")
  end
end
--@api-stub: LInputRecording:type
-- Returns the Lua-visible type name for this input recording handle
do
  local obj = lurek.input.startRecording()
  local rec = lurek.input.stopRecording()
  if rec then
    local _ = rec:toJson()
  end
  local t = obj and obj:type() or "LInputRecording"
  lurek.log.info("LInputRecording:type = " .. t, "input")
end
--@api-stub: LInputRecording:typeOf
-- Returns whether this input recording handle matches a supported type name
do
  local obj = lurek.input.startRecording()
  local rec = lurek.input.stopRecording()
  if rec then
    local _ = rec:toJson()
  end
  lurek.log.info("is LInputRecording: " .. tostring(obj and obj:typeOf("LInputRecording") or false), "input")
  lurek.log.info("is wrong: " .. tostring(obj and obj:typeOf("Unknown") or false), "input")
end


