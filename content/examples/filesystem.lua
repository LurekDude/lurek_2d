-- content/examples/filesystem.lua
-- lurek.filesystem API examples.
-- Run: cargo run -- content/examples/filesystem.lua

--@api-stub: lurek.filesystem.mountZip
-- Opens a ZIP archive and exposes it through a virtual prefix
do
  local ok, pack = pcall(lurek.filesystem.mountZip, "dlc/forest_pack.zip", "mods/forest")
  if ok and pack:contains("levels/grove.json") then
    local data = pack:readFile("levels/grove.json")
    lurek.log.info("forest pack ready: " .. #data .. " bytes", "fs")
  end
end

--@api-stub: lurek.filesystem.watchPath
-- Adds a path to the module-local file watcher
do
  lurek.filesystem.watchPath("assets/levels/forest.json")
  lurek.filesystem.watchPath("scripts/enemy.lua")
end

--@api-stub: lurek.filesystem.unwatchPath
-- Removes a path from the module-local file watcher
do
  lurek.filesystem.watchPath("assets/levels/forest.json")
  lurek.filesystem.unwatchPath("assets/levels/forest.json")
end

--@api-stub: lurek.filesystem.pollWatchers
-- Polls watched paths and returns paths that changed since the previous poll
do
  local timer = 0
  function lurek.process(dt)
    timer = timer + dt
    if timer < 1 then return end
    timer = 0
    for _, path in ipairs(lurek.filesystem.pollWatchers()) do
      lurek.log.info("changed: " .. path, "hotreload")
    end
  end
end

--@api-stub: lurek.filesystem.read
-- Reads a UTF-8 text file from GameFS
do
  local ok, toml = pcall(lurek.filesystem.read, "config/options.toml")
  if ok then lurek.log.info("loaded options.toml (" .. #toml .. " bytes)", "config") end
end

--@api-stub: lurek.filesystem.write
-- Writes a UTF-8 text file through GameFS
do
  local score = 12450
  lurek.filesystem.write("save/highscore.txt", tostring(score))
end

--@api-stub: lurek.filesystem.writeJson
-- Writes JSON text through GameFS
do
  lurek.filesystem.writeJson("save/profile.json", '{"name":"hero","level":3}')
end

--@api-stub: lurek.filesystem.readJson
-- Reads a JSON document as text from GameFS
do
  local json = lurek.filesystem.readJson("save/profile.json")
  lurek.log.info("profile json bytes: " .. #json, "save")
end

--@api-stub: lurek.filesystem.readOrWriteJson
-- Reads a JSON file or writes and returns default JSON when the file is absent
do
  local cfg = lurek.filesystem.readOrWriteJson(
    "save/options.json",
    '{"volume":0.8,"language":"en"}'
  )
  lurek.log.debug("options loaded: " .. cfg, "config")
end

--@api-stub: lurek.filesystem.exists
-- Returns whether a path exists in GameFS
do
  if lurek.filesystem.exists("save/slot1.dat") then
    lurek.log.info("resuming from slot 1", "save")
  else
    lurek.log.info("no save, starting new game", "save")
  end
end

--@api-stub: lurek.filesystem.append
-- Appends UTF-8 text to a GameFS file
do
  local line = os.date("%Y-%m-%dT%H:%M:%S") .. "\tlevel_complete\tforest_01\n"
  lurek.filesystem.append("save/telemetry.log", line)
end

--@api-stub: lurek.filesystem.openFile
-- Opens a GameFS file handle in a requested mode
do
  local fh = lurek.filesystem.openFile("save/slot1.dat", "w")
  fh:write("level=forest_01;hp=80;mana=42")
  fh:close()
end

--@api-stub: lurek.filesystem.getDirectoryItems
-- Lists immediate entries in a GameFS directory
do
  local saves = lurek.filesystem.getDirectoryItems("save")
  lurek.log.info("found " .. #saves .. " save files", "save")
  for _, name in ipairs(saves) do
    lurek.log.debug("  save: " .. name, "save")
  end
end

--@api-stub: lurek.filesystem.isFile
-- Returns whether a GameFS path is a regular file
do
  pcall(function()
    if lurek.filesystem.isFile("config/options.toml") then
      local ok_cfg, cfg = pcall(lurek.filesystem.read, "config/options.toml")
      if ok_cfg and cfg then
        lurek.log.info("config loaded (" .. #cfg .. " bytes)", "config")
      end
    end
  end)
end

--@api-stub: lurek.filesystem.isDirectory
-- Returns whether a GameFS path is a directory
do
  if lurek.filesystem.isDirectory("assets/levels") then
    local levels = lurek.filesystem.getDirectoryItems("assets/levels")
    lurek.log.info("levels available: " .. #levels, "scene")
  end
end

--@api-stub: lurek.filesystem.createDirectory
-- Creates a GameFS directory and any missing parents
do
  lurek.filesystem.createDirectory("save/screenshots")
  lurek.filesystem.write("save/screenshots/last_run.txt", "ok")
end

--@api-stub: lurek.filesystem.remove
-- Removes a GameFS file or supported path
do
  if lurek.filesystem.exists("save/temp_export.json") then
    lurek.filesystem.remove("save/temp_export.json")
    lurek.log.info("cleared stale export", "save")
  end
end

--@api-stub: lurek.filesystem.getInfo
-- Returns file metadata for a GameFS path when available
do
  local info = lurek.filesystem.getInfo("save/slot1.dat")
  if info then
    lurek.log.info("slot1 " .. info.type .. " " .. info.size .. " bytes", "save")
  end
end

--@api-stub: lurek.filesystem.getSource
-- Returns the GameFS source root string
do
  local src = lurek.filesystem.getSource()
  lurek.log.info("game source dir: " .. src, "fs")
end

--@api-stub: lurek.filesystem.getSaveDirectory
-- Returns the save directory path used by GameFS
do
  local save_dir = lurek.filesystem.getSaveDirectory()
  lurek.log.info("saves stored at: " .. save_dir, "save")
end

--@api-stub: lurek.filesystem.getWorkingDirectory
-- Returns the process working directory
do
  local cwd = lurek.filesystem.getWorkingDirectory()
  lurek.log.debug("cwd at launch: " .. cwd, "fs")
end

--@api-stub: lurek.filesystem.getUserDirectory
-- Returns the current user's directory path
do
  local home = lurek.filesystem.getUserDirectory()
  lurek.log.info("user home: " .. home, "fs")
end

--@api-stub: lurek.filesystem.getIdentity
-- Returns the current filesystem identity string
do
  local id = lurek.filesystem.getIdentity()
  lurek.log.info("save identity: " .. id, "save")
end

--@api-stub: lurek.filesystem.setIdentity
-- Sets the filesystem identity string used by save paths
do
  lurek.filesystem.setIdentity("forest_quest")
  lurek.log.info("save identity set to forest_quest", "save")
end

--@api-stub: lurek.filesystem.lines
-- Creates an iterator function over lines in a text file
do
  pcall(function()
    local count = 0
    for line in lurek.filesystem.lines("assets/data/dialogue.csv") do
      if #line > 0 then count = count + 1 end
    end
    lurek.log.info("dialogue lines: " .. count, "i18n")
  end)
end

--@api-stub: lurek.filesystem.readAsync
-- Starts an asynchronous file load request
do
  local pending
  function lurek.init()
    pending = lurek.filesystem.readAsync("assets/levels/forest.json")
  end
end

--@api-stub: lurek.filesystem.pollAsync
-- Polls an asynchronous file load request
do
  local pending
  function lurek.init() pending = lurek.filesystem.readAsync("assets/levels/forest.json") end
  function lurek.process(dt)
    if not pending then return end
    local status, data = lurek.filesystem.pollAsync(pending)
    if status == "done" then
      lurek.log.info("level loaded: " .. #data .. " bytes", "scene")
      pending = nil
    end
  end
end

--@api-stub: lurek.filesystem.writeAsync
-- Starts an asynchronous file write request
do
  local write_handle
  function lurek.init()
    local payload = "{\"checkpoint\":7,\"hp\":83}"
    write_handle = lurek.filesystem.writeAsync("save/checkpoint.json", payload)
  end
end

--@api-stub: lurek.filesystem.pollAsyncWrite
-- Polls an asynchronous file write request
do
  local write_handle
  function lurek.init()
    write_handle = lurek.filesystem.writeAsync("save/telemetry.json", "{\"ok\":true}")
  end
  function lurek.process(dt)
    if not write_handle then return end
    local status, info = lurek.filesystem.pollAsyncWrite(write_handle)
    if status == "done" then
      lurek.log.info("async write complete: " .. tostring(info) .. " bytes", "save")
      write_handle = nil
    elseif status == "error" then
      lurek.log.error("async write failed: " .. tostring(info), "save")
      write_handle = nil
    end
  end
end

--@api-stub: lurek.filesystem.mount
-- Mounts an external source path at a GameFS mount point
do
  local ok = pcall(lurek.filesystem.mount, "../mods/extra", "mods/extra")
  if ok then lurek.log.info("mounted extra mods", "mods") end
end

--@api-stub: lurek.filesystem.unmount
-- Removes a GameFS mount point
do
  if lurek.filesystem.unmount("mods/extra") then
    lurek.log.info("extra mods unmounted", "mods")
  end
end

--@api-stub: lurek.filesystem.load
-- Loads a Lua chunk from GameFS and returns it as a Lua function
do
  pcall(function()
    local chunk = lurek.filesystem.load("scripts/enemy_ai.lua")
    local enemy_module = chunk()
    lurek.log.info("enemy AI module loaded", "ai")
  end)
end

--@api-stub: lurek.filesystem.newFileData
-- Loads a file into an immutable file data handle
do
  pcall(function()
    local fd = lurek.filesystem.newFileData("assets/sfx/jump.ogg")
    lurek.log.info("loaded " .. fd:getFilename() .. " (" .. fd:getSize() .. " bytes)", "audio")
  end)
end

--@api-stub: lurek.filesystem.copy
-- Copies one GameFS file to another path
do
  lurek.filesystem.copy("save/slot1.dat", "save/slot1.bak")
  lurek.log.info("backed up slot 1", "save")
end

--@api-stub: lurek.filesystem.move
-- Moves or renames one GameFS file to another path
do
  lurek.filesystem.write("save/slot1.tmp", "level=forest_02;hp=92")
  lurek.filesystem.move("save/slot1.tmp", "save/slot1.dat")
end

--@api-stub: lurek.filesystem.removeDir
-- Removes a GameFS directory
do
  if lurek.filesystem.isDirectory("save/screenshots") then
    lurek.filesystem.removeDir("save/screenshots")
    lurek.log.info("cleared screenshots cache", "save")
  end
end

--@api-stub: lurek.filesystem.glob
-- Returns GameFS paths matching a glob pattern
do
  local saves = lurek.filesystem.glob("save/slot*.dat")
  for _, path in ipairs(saves) do
    lurek.log.info("save: " .. path, "save")
  end
end

--@api-stub: lurek.filesystem.listRecursive
-- Lists all paths under a GameFS directory recursively
do
  local ok, files = pcall(lurek.filesystem.listRecursive, "assets/levels")
  if ok then
    lurek.log.info("level assets: " .. #files, "scene")
  end
end

--@api-stub: lurek.filesystem.stat
-- Returns size and file/directory flags for a GameFS path
do
  local ok, s = pcall(lurek.filesystem.stat, "assets/levels/forest.json")
  if ok and s.isFile then
    lurek.log.info("forest.json: " .. s.size .. " bytes", "scene")
  end
end

--@api-stub: lurek.filesystem.createTempFile
-- Creates a temporary file through GameFS
do
  local tmp = lurek.filesystem.createTempFile("export")
  lurek.filesystem.write(tmp, "snapshot=" .. os.time())
  lurek.log.info("export staged at " .. tmp, "save")
end

--@api-stub: lurek.filesystem.mkdir
-- Creates a directory under the GameFS base directory
do
  pcall(function()
    lurek.filesystem.mkdir("save/run_001")
    lurek.filesystem.write("save/run_001/notes.txt", "ok")
  end)
end

--@api-stub: lurek.filesystem.toAbsolutePath
-- Resolves a GameFS-relative path against the filesystem base directory
do
  local abs = lurek.filesystem.toAbsolutePath("save/slot1.dat")
  lurek.log.info("absolute path: " .. abs, "fs")
end


-- — FileData methods —

--@api-stub: LFileData:getSize
-- Returns the byte length of this file data
do
  pcall(function()
    local fd = lurek.filesystem.newFileData("assets/sfx/jump.ogg")
    local kb = fd:getSize() / 1024
    lurek.log.info(string.format("jump.ogg = %.1f KiB", kb), "audio")
  end)
end

--@api-stub: LFileData:getString
-- Returns file data bytes as a Lua string without UTF-8 validation
do
  pcall(function()
    local fd = lurek.filesystem.newFileData("config/options.toml")
    local body = fd:getString()
    lurek.log.info("first byte: " .. string.byte(body, 1), "config")
  end)
end

--@api-stub: LFileData:getFilename
-- Returns the path associated with this file data object
do
  pcall(function()
    local fd = lurek.filesystem.newFileData("assets/levels/forest.json")
    lurek.log.info("loaded " .. fd:getFilename(), "scene")
  end)
end

--@api-stub: LFileData:type
-- Returns the Lua-visible type name for this file data handle
do
  local ok_fd, file_data_obj = pcall(lurek.filesystem.newFileData, "save/highscore.txt")
  if ok_fd and file_data_obj then
    local t = file_data_obj:type()
    lurek.log.info("LFileData:type = " .. t, "filesystem")
  else
    lurek.log.info("LFileData:type = skipped", "filesystem")
  end
end

--@api-stub: LFileData:typeOf
-- Returns whether this file data handle matches a supported type name
do
  local ok_fd2, file_data_obj2 = pcall(lurek.filesystem.newFileData, "save/highscore.txt")
  if ok_fd2 and file_data_obj2 then
    lurek.log.info("is LFileData: " .. tostring(file_data_obj2:typeOf("LFileData")), "filesystem")
    lurek.log.info("is wrong: " .. tostring(file_data_obj2:typeOf("Unknown")), "filesystem")
  else
    lurek.log.info("LFileData:typeOf = skipped", "filesystem")
  end
end


-- — FileHandle methods —

--@api-stub: LFileHandle:read
-- Reads up to an optional byte count and returns text using lossless UTF-8 replacement
do
  local fh = lurek.filesystem.openFile("save/slot1.dat", "r")
  local body = fh:read()
  fh:close()
  lurek.log.info("slot1 size: " .. #body .. " bytes", "save")
end

--@api-stub: LFileHandle:readLine
-- Reads the next line from this file handle
do
  pcall(function()
    local fh = lurek.filesystem.openFile("save/telemetry.log", "r")
    local first = fh:readLine()
    fh:close()
    lurek.log.info("first telemetry line: " .. (first or "<empty>"), "fs")
  end)
end

--@api-stub: LFileHandle:write
-- Writes a string to this file handle
do
  local fh = lurek.filesystem.openFile("save/score.txt", "w")
  local n = fh:write("12450")
  fh:close()
  lurek.log.info("wrote " .. n .. " bytes to score.txt", "save")
end

--@api-stub: LFileHandle:seek
-- Moves the file cursor to an absolute byte position
do
  local fh = lurek.filesystem.openFile("save/slot1.dat", "r")
  fh:seek(16)
  local chunk = fh:read(8)
  fh:close()
  lurek.log.debug("bytes 16..23 = " .. chunk, "save")
end

--@api-stub: LFileHandle:tell
-- Returns the current file cursor position
do
  pcall(function()
    local fh = lurek.filesystem.openFile("assets/levels/forest.json", "r")
    fh:read(64)
    lurek.log.info("cursor at byte " .. fh:tell(), "scene")
    fh:close()
  end)
end

--@api-stub: LFileHandle:getSize
-- Returns the size of the open file
do
  pcall(function()
    local fh = lurek.filesystem.openFile("assets/levels/forest.json", "r")
    lurek.log.info("level file size: " .. fh:getSize(), "scene")
    fh:close()
  end)
end

--@api-stub: LFileHandle:getMode
-- Returns the mode used to open this file handle
do
  local fh = lurek.filesystem.openFile("save/slot1.dat", "r")
  lurek.log.debug("opened slot1 in mode " .. fh:getMode(), "save")
  fh:close()
end

--@api-stub: LFileHandle:flush
-- Flushes pending writes on this file handle
do
  local fh = lurek.filesystem.openFile("save/journal.log", "a")
  fh:write("checkpoint=forest_02\n")
  fh:flush()
  fh:close()
end

--@api-stub: LFileHandle:close
-- Closes this file handle
do
  local fh = lurek.filesystem.openFile("save/slot1.dat", "w")
  fh:write("hp=100;mana=50")
  fh:close()
end

--@api-stub: LFileHandle:isEOF
-- Returns whether the file cursor is at end of file
do
  pcall(function()
    local fh = lurek.filesystem.openFile("save/telemetry.log", "r")
    while not fh:isEOF() do
      local chunk = fh:read(256)
      if not chunk or #chunk == 0 then break end
    end
    fh:close()
  end)
end

--@api-stub: LFileHandle:type
-- Returns the Lua-visible type name for this file handle
do
  local ok_fh ---@type boolean
  local file_handle_obj ---@type LFileHandle?
  ok_fh, file_handle_obj = pcall(lurek.filesystem.openFile, "save/highscore.txt", nil)
  if not ok_fh then file_handle_obj = nil end
  local t = file_handle_obj and file_handle_obj:type() or "LFileHandle"
  lurek.log.info("LFileHandle:type = " .. t, "filesystem")
end

--@api-stub: LFileHandle:typeOf
-- Returns whether this file handle matches a supported type name
do
  local ok_fh ---@type boolean
  local file_handle_obj ---@type LFileHandle?
  ok_fh, file_handle_obj = pcall(lurek.filesystem.openFile, "save/highscore.txt", nil)
  if not ok_fh then file_handle_obj = nil end
  lurek.log.info("is LFileHandle: " .. tostring(file_handle_obj and file_handle_obj:typeOf("LFileHandle") or false), "filesystem")
  lurek.log.info("is wrong: " .. tostring(file_handle_obj and file_handle_obj:typeOf("Unknown") or false), "filesystem")
end


-- — ZipMount methods —

--@api-stub: LZipMount:readFile
-- Reads a file from the ZIP mount by virtual path
do
  pcall(function()
    local pack = lurek.filesystem.mountZip("dlc/forest_pack.zip", "mods/forest")
    local body = pack:readFile("levels/grove.json")
    lurek.log.info("grove.json: " .. #body .. " bytes", "mods")
  end)
end

--@api-stub: LZipMount:contains
-- Returns whether a virtual path exists in the ZIP mount
do
  pcall(function()
    local pack = lurek.filesystem.mountZip("dlc/forest_pack.zip", "mods/forest")
    if pack:contains("levels/secret.json") then
      lurek.log.info("secret level present in pack", "mods")
    end
  end)
end

--@api-stub: LZipMount:listFiles
-- Returns every virtual file path in the ZIP mount
do
  pcall(function()
    local pack = lurek.filesystem.mountZip("dlc/forest_pack.zip", "mods/forest")
    local files = pack:listFiles()
    lurek.log.info("forest pack contains " .. #files .. " files", "mods")
  end)
end

--@api-stub: LZipMount:prefix
-- Returns the virtual prefix used by this ZIP mount
do
  pcall(function()
    local pack = lurek.filesystem.mountZip("dlc/forest_pack.zip", "mods/forest")
    lurek.log.info("pack mounted at " .. pack:prefix(), "mods")
  end)
end

--@api-stub: LZipMount:type
-- Returns the Lua-visible type name for this ZIP mount handle
do
  local ok_zm ---@type boolean
  local zip_mount_obj ---@type LZipMount?
  ok_zm, zip_mount_obj = pcall(lurek.filesystem.mountZip, "assets/data.zip", nil)
  if not ok_zm then zip_mount_obj = nil end
  local t = zip_mount_obj and zip_mount_obj:type() or "LZipMount"
  lurek.log.info("LZipMount:type = " .. t, "filesystem")
end

--@api-stub: LZipMount:typeOf
-- Returns whether this ZIP mount handle matches a supported type name
do
  local ok_zm2 ---@type boolean
  local zip_mount_obj2 ---@type LZipMount?
  ok_zm2, zip_mount_obj2 = pcall(lurek.filesystem.mountZip, "assets/data.zip", nil)
  if not ok_zm2 then zip_mount_obj2 = nil end
  lurek.log.info("is LZipMount: " .. tostring(zip_mount_obj2 and zip_mount_obj2:typeOf("LZipMount") or false), "filesystem")
  lurek.log.info("is wrong: " .. tostring(zip_mount_obj2 and zip_mount_obj2:typeOf("Unknown") or false), "filesystem")
end

--@api-stub: lurek.filesystem.readBytes
-- Reads a binary file from GameFS and returns the bytes as a Lua string
do
  local ok, data = pcall(lurek.filesystem.readBytes, "assets/hero.png")
  if ok then
    lurek.log.info("readBytes got " .. #data .. " bytes", "fs")
  end
end

--@api-stub: lurek.filesystem.writeBytes
-- Writes binary data through GameFS
do
  local payload = string.char(0x89, 0x50, 0x4E, 0x47) -- PNG magic header
  lurek.filesystem.writeBytes("save/test_binary.dat", payload)
  lurek.log.info("writeBytes wrote " .. #payload .. " bytes", "fs")
end
