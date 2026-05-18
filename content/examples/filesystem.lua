-- content/examples/filesystem.lua
-- lurek.filesystem API examples.
-- Run: cargo run -- content/examples/filesystem.lua

--@api-stub: lurek.filesystem.mountZip
-- Opens a ZIP archive and exposes it through a virtual prefix
do
  -- mountZip loads a .zip file from disk and maps its contents to a virtual path.
  -- This is ideal for DLC packs, asset bundles, or mod distribution where you want
  -- to keep assets bundled but accessible through the same GameFS API.
  local ok, pack = pcall(lurek.filesystem.mountZip, "dlc/forest_pack.zip", "mods/forest")
  if ok then
    -- After mounting, use the returned LZipMount handle to check and read files
    -- without needing to know the archive's internal layout ahead of time.
    if pack:contains("levels/grove.json") then
      local data = pack:readFile("levels/grove.json")
      lurek.log.info("forest pack ready: " .. #data .. " bytes", "fs")
    end
  end
end

--@api-stub: lurek.filesystem.watchPath
-- Adds a path to the module-local file watcher
do
  -- watchPath registers a file for change detection. Use this for hot-reloading
  -- during development: watch level files, scripts, or config so you can detect
  -- edits without restarting the game.
  lurek.filesystem.watchPath("assets/levels/forest.json")
  lurek.filesystem.watchPath("scripts/enemy.lua")
  -- Both paths are now tracked. Call pollWatchers() each frame to get changes.
end

--@api-stub: lurek.filesystem.unwatchPath
-- Removes a path from the module-local file watcher
do
  -- unwatchPath stops tracking a previously watched file. Use this when a level
  -- is unloaded or a script is no longer relevant, to avoid wasted polling work.
  lurek.filesystem.watchPath("assets/levels/forest.json")
  lurek.filesystem.unwatchPath("assets/levels/forest.json")
  -- After this call, changes to forest.json will no longer appear in pollWatchers().
end

--@api-stub: lurek.filesystem.pollWatchers
-- Polls watched paths and returns paths that changed since the previous poll
do
  -- pollWatchers() returns an array of paths that were modified since the last poll.
  -- Call it once per frame (or at a slower interval) to implement hot-reload.
  -- The returned array is empty when nothing changed — this is the normal case.
  local timer = 0
  function lurek.process(dt)
    timer = timer + dt
    if timer < 1 then return end
    timer = 0
    -- Poll at 1-second intervals to reduce overhead while staying responsive
    for _, path in ipairs(lurek.filesystem.pollWatchers()) do
      lurek.log.info("changed: " .. path, "hotreload")
      -- Here you would reload the resource: re-parse a level, re-run a script, etc.
    end
  end
end

--@api-stub: LFileHandle:read
-- Reads a UTF-8 text file from GameFS
do
  -- read() loads the entire file as a UTF-8 string. Use it for config files,
  -- level data, dialogue CSVs, or any text-based game data.
  -- Wrapping in pcall handles missing files gracefully.
  local ok, toml = pcall(lurek.filesystem.read, "config/options.toml")
  if ok then
    lurek.log.info("loaded options.toml (" .. #toml .. " bytes)", "config")
    -- Parse the TOML string here to extract game settings
  end
end

--@api-stub: LFileHandle:write
-- Writes a UTF-8 text file through GameFS
do
  -- write() creates or overwrites a file with text content. GameFS resolves the
  -- path relative to the save directory, so writes are sandboxed and safe.
  -- Use this for simple save data, high scores, or small config persistence.
  local score = 12450
  lurek.filesystem.write("save/highscore.txt", tostring(score))
  -- The file now exists at <save_dir>/highscore.txt and will persist across runs.
end

--@api-stub: lurek.filesystem.writeJson
-- Writes JSON text through GameFS
do
  -- writeJson() stores a JSON string to a file. You build the JSON string yourself
  -- (or use lurek.data.encode). This is the standard way to persist structured
  -- game state like player profiles, inventory, or settings.
  lurek.filesystem.writeJson("save/profile.json", '{"name":"hero","level":3}')
end

--@api-stub: lurek.filesystem.readJson
-- Reads a JSON document as text from GameFS
do
  -- readJson() returns the raw JSON text from a file. Pair with lurek.data.decode
  -- to get a Lua table. Throws if the file does not exist.
  local json = lurek.filesystem.readJson("save/profile.json")
  lurek.log.info("profile json bytes: " .. #json, "save")
  -- local profile = lurek.data.decode(json)  -- decode to a Lua table
end

--@api-stub: lurek.filesystem.readOrWriteJson
-- Reads a JSON file or writes and returns default JSON when the file is absent
do
  -- readOrWriteJson() is a "get or create" pattern: if the file exists, read it;
  -- if not, write the default JSON and return it. Perfect for first-run config
  -- where you want sensible defaults without extra existence checks.
  local cfg = lurek.filesystem.readOrWriteJson(
    "save/options.json",
    '{"volume":0.8,"language":"en"}'
  )
  lurek.log.debug("options loaded: " .. cfg, "config")
  -- On first run, options.json is created with the defaults.
  -- On subsequent runs, the existing file is read unchanged.
end

--@api-stub: lurek.filesystem.exists
-- Returns whether a path exists in GameFS
do
  -- exists() is a quick check before reading. Use it for save slot detection,
  -- checking if a mod folder is present, or conditional asset loading.
  if lurek.filesystem.exists("save/slot1.dat") then
    lurek.log.info("resuming from slot 1", "save")
  else
    lurek.log.info("no save, starting new game", "save")
  end
end

--@api-stub: lurek.filesystem.append
-- Appends UTF-8 text to a GameFS file
do
  -- append() adds text to the end of a file without overwriting existing content.
  -- Ideal for telemetry logs, play journals, or incremental data collection
  -- where you accumulate entries across multiple sessions.
  local line = os.date("%Y-%m-%dT%H:%M:%S") .. "\tlevel_complete\tforest_01\n"
  lurek.filesystem.append("save/telemetry.log", line)
  -- Each call adds one more line — the file grows over time.
end

--@api-stub: lurek.filesystem.openFile
-- Opens a GameFS file handle in a requested mode
do
  -- openFile() returns an LFileHandle for stream-style access. Modes:
  --   "r" = read, "w" = write (create/truncate), "a" = append
  -- Use file handles when you need seek, partial reads, or multiple writes
  -- before closing — more control than the simple read/write functions.
  local fh = lurek.filesystem.openFile("save/slot1.dat", "w")
  fh:write("level=forest_01;hp=80;mana=42")
  fh:close()
  -- Always close file handles to flush data and release the file.
end

--@api-stub: lurek.filesystem.getDirectoryItems
-- Lists immediate entries in a GameFS directory
do
  -- getDirectoryItems() returns an array of file and folder names (not full paths)
  -- in the given directory. Use it for save-slot discovery, asset enumeration,
  -- or building a file browser UI.
  local saves = lurek.filesystem.getDirectoryItems("save")
  lurek.log.info("found " .. #saves .. " save files", "save")
  for _, name in ipairs(saves) do
    -- Each entry is just the filename: "slot1.dat", "profile.json", etc.
    lurek.log.debug("  save: " .. name, "save")
  end
end

--@api-stub: lurek.filesystem.isFile
-- Returns whether a GameFS path is a regular file
do
  -- isFile() distinguishes files from directories. Use it when iterating a
  -- directory and you need to skip subfolders, or to validate a path before read.
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
  -- isDirectory() lets you verify a path is a folder before listing it.
  -- Useful for mod discovery: check if a mod folder exists, then enumerate its contents.
  if lurek.filesystem.isDirectory("assets/levels") then
    local levels = lurek.filesystem.getDirectoryItems("assets/levels")
    lurek.log.info("levels available: " .. #levels, "scene")
  end
end

--@api-stub: lurek.filesystem.createDirectory
-- Creates a GameFS directory and any missing parents
do
  -- createDirectory() works like mkdir -p: it creates the full path including
  -- any intermediate directories that don't exist yet. Use it before writing
  -- files into a new subfolder (screenshots, per-run logs, mod output).
  lurek.filesystem.createDirectory("save/screenshots")
  lurek.filesystem.write("save/screenshots/last_run.txt", "ok")
end

--@api-stub: lurek.filesystem.remove
-- Removes a GameFS file or supported path
do
  -- remove() deletes a single file. Use it for cleanup: clearing temp exports,
  -- removing stale cache files, or implementing a "delete save" feature.
  if lurek.filesystem.exists("save/temp_export.json") then
    lurek.filesystem.remove("save/temp_export.json")
    lurek.log.info("cleared stale export", "save")
  end
end

--@api-stub: lurek.filesystem.getInfo
-- Returns file metadata for a GameFS path when available
do
  -- getInfo() returns a table with: type ("file"/"directory"), size (bytes),
  -- modtime (last modification timestamp), and readonly (boolean).
  -- Returns nil if the path does not exist. Useful for displaying save dates
  -- in a slot-picker UI or checking if a file was updated externally.
  local info = lurek.filesystem.getInfo("save/slot1.dat")
  if info then
    lurek.log.info("slot1 " .. info.type .. " " .. info.size .. " bytes", "save")
    -- info.modtime gives the last-modified time for "last saved" display
  end
end

--@api-stub: lurek.filesystem.getSource
-- Returns the GameFS source root string
do
  -- getSource() tells you where GameFS reads game assets from. This is the
  -- directory passed at startup (the game folder). Useful for debug output
  -- or resolving absolute paths for external tools.
  local src = lurek.filesystem.getSource()
  lurek.log.info("game source dir: " .. src, "fs")
end

--@api-stub: lurek.filesystem.getSaveDirectory
-- Returns the save directory path used by GameFS
do
  -- getSaveDirectory() returns the OS-level path where save files are stored.
  -- All write/append operations go here. Show this to the player so they can
  -- find their saves for backup or sharing.
  local save_dir = lurek.filesystem.getSaveDirectory()
  lurek.log.info("saves stored at: " .. save_dir, "save")
end

--@api-stub: lurek.filesystem.getWorkingDirectory
-- Returns the process working directory
do
  -- getWorkingDirectory() returns the OS current directory at launch time.
  -- Mostly useful for debugging path resolution issues or logging.
  local cwd = lurek.filesystem.getWorkingDirectory()
  lurek.log.debug("cwd at launch: " .. cwd, "fs")
end

--@api-stub: lurek.filesystem.getUserDirectory
-- Returns the current user's directory path
do
  -- getUserDirectory() returns the user's home folder (e.g. C:\Users\Name on
  -- Windows, /home/name on Linux). Useful for locating external config or
  -- showing the user where engine-wide preferences live.
  local home = lurek.filesystem.getUserDirectory()
  lurek.log.info("user home: " .. home, "fs")
end

--@api-stub: lurek.filesystem.getIdentity
-- Returns the current filesystem identity string
do
  -- getIdentity() returns the string used to namespace save directories.
  -- Each game should set a unique identity so saves don't collide.
  local id = lurek.filesystem.getIdentity()
  lurek.log.info("save identity: " .. id, "save")
end

--@api-stub: lurek.filesystem.setIdentity
-- Sets the filesystem identity string used by save paths
do
  -- setIdentity() changes the save namespace. Call it early (in conf.lua or init)
  -- to ensure all save operations go to the correct game-specific folder.
  -- The engine creates <user_dir>/<identity>/ as the save root.
  lurek.filesystem.setIdentity("forest_quest")
  lurek.log.info("save identity set to forest_quest", "save")
end

--@api-stub: lurek.filesystem.lines
-- Creates an iterator function over lines in a text file
do
  -- lines() returns a Lua iterator, so you can use it in a for loop.
  -- Memory-efficient for large files: reads line by line instead of loading
  -- the entire file. Great for CSV parsing, dialogue scripts, or log processing.
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
  -- readAsync() begins loading a file in the background and returns a handle ID.
  -- The game loop continues running while the file loads. Use this for large
  -- assets (level data, dialogue databases) to avoid frame-time spikes.
  local pending
  function lurek.init()
    pending = lurek.filesystem.readAsync("assets/levels/forest.json")
    -- pending is a numeric handle ID — poll it each frame until done
  end
end

--@api-stub: lurek.filesystem.pollAsync
-- Polls an asynchronous file load request
do
  -- pollAsync() checks the status of a readAsync handle. Returns two values:
  --   "done", data_string   — file loaded successfully
  --   "pending", nil        — still loading, check again next frame
  --   "error", error_string — load failed
  -- This non-blocking pattern keeps the game responsive during large loads.
  local pending
  function lurek.init() pending = lurek.filesystem.readAsync("assets/levels/forest.json") end
  function lurek.process(dt)
    if not pending then return end
    local status, data = lurek.filesystem.pollAsync(pending)
    if status == "done" then
      lurek.log.info("level loaded: " .. #data .. " bytes", "scene")
      pending = nil
      -- Parse and use the loaded data here
    end
  end
end

--@api-stub: lurek.filesystem.writeAsync
-- Starts an asynchronous file write request
do
  -- writeAsync() writes a file in the background without blocking the game loop.
  -- Returns a handle ID for polling. Use this for large saves or telemetry dumps
  -- where you don't want to stall the frame while disk IO completes.
  local write_handle
  function lurek.init()
    local payload = "{\"checkpoint\":7,\"hp\":83}"
    write_handle = lurek.filesystem.writeAsync("save/checkpoint.json", payload)
    -- The write proceeds in the background; poll to confirm completion.
  end
end

--@api-stub: lurek.filesystem.pollAsyncWrite
-- Polls an asynchronous file write request
do
  -- pollAsyncWrite() checks a writeAsync handle. Returns:
  --   "done", bytes_written  — write completed
  --   "pending", nil         — still writing
  --   "error", error_string  — write failed (disk full, permission denied, etc.)
  -- Always poll to catch write errors — silent data loss is worse than a retry.
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
  -- mount() makes an external directory visible inside GameFS at a virtual path.
  -- Use this for mod loading: mount each mod folder so its assets are accessible
  -- through the normal GameFS read API without changing game code.
  local ok = pcall(lurek.filesystem.mount, "../mods/extra", "mods/extra")
  if ok then
    lurek.log.info("mounted extra mods", "mods")
    -- Now lurek.filesystem.read("mods/extra/config.toml") reads from ../mods/extra/
  end
end

--@api-stub: lurek.filesystem.unmount
-- Removes a GameFS mount point
do
  -- unmount() detaches a previously mounted path. Use this when disabling a mod
  -- at runtime or cleaning up temporary mount points after use.
  if lurek.filesystem.unmount("mods/extra") then
    lurek.log.info("extra mods unmounted", "mods")
    -- Files under mods/extra/ are no longer accessible through GameFS.
  end
end

--@api-stub: lurek.filesystem.load
-- Loads a Lua chunk from GameFS and returns it as a Lua function
do
  -- load() compiles a Lua script from GameFS and returns it as a callable function.
  -- This is how you implement hot-loadable modules, plugin systems, or mod scripts.
  -- The returned function captures no upvalues — call it to execute the script.
  pcall(function()
    local chunk = lurek.filesystem.load("scripts/enemy_ai.lua")
    local enemy_module = chunk()  -- Execute the script; it may return a table
    lurek.log.info("enemy AI module loaded", "ai")
  end)
end

--@api-stub: lurek.filesystem.newFileData
-- Loads a file into an immutable file data handle
do
  -- newFileData() loads the entire file into memory as an LFileData object.
  -- Unlike read(), the result is a handle with methods (getSize, getString, getFilename).
  -- Use this when you need to pass file data to other APIs (audio decoders, image loaders)
  -- or when you want to inspect metadata before processing the content.
  pcall(function()
    local fd = lurek.filesystem.newFileData("assets/sfx/jump.ogg")
    lurek.log.info("loaded " .. fd:getFilename() .. " (" .. fd:getSize() .. " bytes)", "audio")
  end)
end

--@api-stub: lurek.filesystem.copy
-- Copies one GameFS file to another path
do
  -- copy() duplicates a file. The classic use case is creating backup saves
  -- before overwriting, so the player can recover from corruption.
  lurek.filesystem.copy("save/slot1.dat", "save/slot1.bak")
  lurek.log.info("backed up slot 1", "save")
end

--@api-stub: lurek.filesystem.move
-- Moves or renames one GameFS file to another path
do
  -- move() is an atomic rename/move. Use the write-to-temp-then-move pattern
  -- for crash-safe saves: write to a .tmp file, then move it over the real file.
  -- If the game crashes mid-write, the original save is untouched.
  lurek.filesystem.write("save/slot1.tmp", "level=forest_02;hp=92")
  lurek.filesystem.move("save/slot1.tmp", "save/slot1.dat")
  -- slot1.dat is now updated atomically — no half-written state possible.
end

--@api-stub: lurek.filesystem.removeDir
-- Removes a GameFS directory
do
  -- removeDir() deletes an empty directory. Use it for cleanup after clearing
  -- all files in a folder (screenshot cache, temp run data, etc.).
  if lurek.filesystem.isDirectory("save/screenshots") then
    lurek.filesystem.removeDir("save/screenshots")
    lurek.log.info("cleared screenshots cache", "save")
  end
end

--@api-stub: lurek.filesystem.glob
-- Returns GameFS paths matching a glob pattern
do
  -- glob() finds files matching a wildcard pattern. Supports * and ?.
  -- Use it for discovering save slots, finding all levels, or locating mod assets
  -- without hardcoding specific filenames.
  local saves = lurek.filesystem.glob("save/slot*.dat")
  for _, path in ipairs(saves) do
    -- Each result is a full relative path: "save/slot1.dat", "save/slot2.dat", etc.
    lurek.log.info("save: " .. path, "save")
  end
end

--@api-stub: lurek.filesystem.listRecursive
-- Lists all paths under a GameFS directory recursively
do
  -- listRecursive() walks a directory tree and returns every file path found.
  -- Unlike getDirectoryItems() which is one level deep, this descends into
  -- all subfolders. Use it for asset manifests or mod content scanning.
  local ok, files = pcall(lurek.filesystem.listRecursive, "assets/levels")
  if ok then
    lurek.log.info("level assets: " .. #files, "scene")
    -- files contains: {"assets/levels/forest.json", "assets/levels/cave/map.json", ...}
  end
end

--@api-stub: lurek.filesystem.stat
-- Returns size and file/directory flags for a GameFS path
do
  -- stat() returns a table with .size (bytes), .isFile (boolean), and .isDir (boolean).
  -- Lighter than getInfo() when you only need basic size/type checks.
  local ok, s = pcall(lurek.filesystem.stat, "assets/levels/forest.json")
  if ok and s.isFile then
    lurek.log.info("forest.json: " .. s.size .. " bytes", "scene")
  end
end

--@api-stub: lurek.filesystem.createTempFile
-- Creates a temporary file through GameFS
do
  -- createTempFile() generates a unique temporary file path with an optional prefix.
  -- The file is created empty and ready for writing. Use it for staging exports,
  -- intermediate processing, or crash-safe write patterns.
  local tmp = lurek.filesystem.createTempFile("export")
  lurek.filesystem.write(tmp, "snapshot=" .. os.time())
  lurek.log.info("export staged at " .. tmp, "save")
  -- The returned path might be something like "save/_tmp_export_a3f2.txt"
end

--@api-stub: lurek.filesystem.mkdir
-- Creates a directory under the GameFS base directory
do
  -- mkdir() creates a single directory level. Unlike createDirectory(), it does
  -- not create missing parents. Use createDirectory() for deep paths.
  pcall(function()
    lurek.filesystem.mkdir("save/run_001")
    lurek.filesystem.write("save/run_001/notes.txt", "ok")
  end)
end

--@api-stub: lurek.filesystem.toAbsolutePath
-- Resolves a GameFS-relative path against the filesystem base directory
do
  -- toAbsolutePath() converts a GameFS path to a full OS path. Use this when
  -- you need to show the player where a file lives on disk, or when interfacing
  -- with external tools that need absolute paths.
  local abs = lurek.filesystem.toAbsolutePath("save/slot1.dat")
  lurek.log.info("absolute path: " .. abs, "fs")
  -- Result: "C:/Users/Player/AppData/.../forest_quest/save/slot1.dat" (Windows)
end


-- — FileData methods —

--@api-stub: LFileHandle:getSize
-- Returns the byte length of this file data
do
  -- LFileData:getSize() tells you how many bytes the loaded file occupies.
  -- Use it for progress bars, memory budgets, or deciding whether to cache.
  pcall(function()
    local fd = lurek.filesystem.newFileData("assets/sfx/jump.ogg")
    local kb = fd:getSize() / 1024
    lurek.log.info(string.format("jump.ogg = %.1f KiB", kb), "audio")
  end)
end

--@api-stub: LFileData:getString
-- Returns file data bytes as a Lua string without UTF-8 validation
do
  -- getString() gives you the raw bytes as a Lua string. Unlike read(), there's
  -- no UTF-8 validation — you get the exact bytes. Use this for binary inspection
  -- or when passing data to APIs that expect raw byte strings.
  pcall(function()
    local fd = lurek.filesystem.newFileData("config/options.toml")
    local body = fd:getString()
    lurek.log.info("first byte: " .. string.byte(body, 1), "config")
  end)
end

--@api-stub: LFileData:getFilename
-- Returns the path associated with this file data object
do
  -- getFilename() returns the path originally used to load this file data.
  -- Handy for logging, error messages, or displaying asset names in debug UIs.
  pcall(function()
    local fd = lurek.filesystem.newFileData("assets/levels/forest.json")
    lurek.log.info("loaded " .. fd:getFilename(), "scene")
  end)
end

--@api-stub: LZipMount:type
-- Returns the Lua-visible type name for this file data handle
do
  -- type() always returns "LFileData". Use it for runtime type checks when
  -- you have a generic handle and need to confirm what kind of object it is.
  local ok_fd, file_data_obj = pcall(lurek.filesystem.newFileData, "save/highscore.txt")
  if ok_fd and file_data_obj then
    local t = file_data_obj:type()
    lurek.log.info("LFileData:type = " .. t, "filesystem")
  else
    lurek.log.info("LFileData:type = skipped", "filesystem")
  end
end

--@api-stub: LZipMount:typeOf
-- Returns whether this file data handle matches a supported type name
do
  -- typeOf() checks if this handle matches a given type name. Accepts "LFileData"
  -- and "Object" (the base type). Use it for polymorphic code that handles
  -- multiple handle types.
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
  -- read() with no argument reads the entire file from the current cursor position.
  -- With a count argument, it reads at most that many bytes — useful for parsing
  -- binary headers or reading files in chunks to avoid large allocations.
  local fh = lurek.filesystem.openFile("save/slot1.dat", "r")
  local body = fh:read()  -- Read everything
  fh:close()
  lurek.log.info("slot1 size: " .. #body .. " bytes", "save")
end

--@api-stub: LFileHandle:readLine
-- Reads the next line from this file handle
do
  -- readLine() returns the next line (without the newline character) or nil at EOF.
  -- Use it for streaming line-by-line processing of large files through a handle.
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
  -- write() appends text at the current cursor position. Returns nil.
  -- Use openFile with "w" mode to start fresh, or "a" to append.
  local fh = lurek.filesystem.openFile("save/score.txt", "w")
  local n = fh:write("12450")
  fh:close()
  lurek.log.info("wrote " .. n .. " bytes to score.txt", "save")
end

--@api-stub: LFileHandle:seek
-- Moves the file cursor to an absolute byte position
do
  -- seek() repositions the read/write cursor to an absolute byte offset.
  -- Use it for random access: reading specific offsets in structured binary files,
  -- or skipping headers to reach payload data directly.
  local fh = lurek.filesystem.openFile("save/slot1.dat", "r")
  fh:seek(16)               -- Jump past a 16-byte header
  local chunk = fh:read(8)  -- Read 8 bytes of payload
  fh:close()
  lurek.log.debug("bytes 16..23 = " .. chunk, "save")
end

--@api-stub: LFileHandle:tell
-- Returns the current file cursor position
do
  -- tell() reports the current byte offset. After reading N bytes, tell() returns N.
  -- Use it to calculate how far into a file you've parsed, or to save/restore
  -- position for multi-pass parsing.
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
  -- getSize() returns the total file size regardless of cursor position.
  -- Combine with tell() to calculate remaining bytes or show progress.
  pcall(function()
    local fh = lurek.filesystem.openFile("assets/levels/forest.json", "r")
    lurek.log.info("level file size: " .. fh:getSize(), "scene")
    fh:close()
  end)
end

--@api-stub: LFileHandle:getMode
-- Returns the mode used to open this file handle
do
  -- getMode() returns the mode string ("r", "w", or "a") used when opening.
  -- Useful for assertions or debug logging when handles are passed around.
  local fh = lurek.filesystem.openFile("save/slot1.dat", "r")
  lurek.log.debug("opened slot1 in mode " .. fh:getMode(), "save")
  fh:close()
end

--@api-stub: LFileHandle:flush
-- Flushes pending writes on this file handle
do
  -- flush() forces buffered data to disk immediately. Use it after critical writes
  -- (checkpoints, autosaves) to ensure data survives a crash before you close.
  local fh = lurek.filesystem.openFile("save/journal.log", "a")
  fh:write("checkpoint=forest_02\n")
  fh:flush()  -- Data is on disk now, even if close() is delayed
  fh:close()
end

--@api-stub: LFileHandle:close
-- Closes this file handle
do
  -- close() releases the file handle and flushes remaining data. Always call this
  -- when done — leaving handles open can prevent other operations on the same file.
  local fh = lurek.filesystem.openFile("save/slot1.dat", "w")
  fh:write("hp=100;mana=50")
  fh:close()
end

--@api-stub: LFileHandle:isEOF
-- Returns whether the file cursor is at end of file
do
  -- isEOF() returns true when no more bytes remain. Use it as a loop condition
  -- for chunk-based reading when you don't know the file size upfront.
  pcall(function()
    local fh = lurek.filesystem.openFile("save/telemetry.log", "r")
    while not fh:isEOF() do
      local chunk = fh:read(256)  -- Read in 256-byte chunks
      if not chunk or #chunk == 0 then break end
    end
    fh:close()
  end)
end

--@api-stub: LZipMount:type
-- Returns the Lua-visible type name for this file handle
do
  -- type() always returns "LFileHandle" for file handle objects.
  local ok_fh ---@type boolean
  local file_handle_obj ---@type LFileHandle?
  ok_fh, file_handle_obj = pcall(lurek.filesystem.openFile, "save/highscore.txt", nil)
  if not ok_fh then file_handle_obj = nil end
  local t = file_handle_obj and file_handle_obj:type() or "LFileHandle"
  lurek.log.info("LFileHandle:type = " .. t, "filesystem")
end

--@api-stub: LZipMount:typeOf
-- Returns whether this file handle matches a supported type name
do
  -- typeOf() checks "LFileHandle" and "Object". Same pattern as LFileData:typeOf.
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
  -- readFile() extracts and returns the contents of a file inside the mounted ZIP.
  -- The path is relative to the ZIP root, not the mount prefix.
  pcall(function()
    local pack = lurek.filesystem.mountZip("dlc/forest_pack.zip", "mods/forest")
    local body = pack:readFile("levels/grove.json")
    lurek.log.info("grove.json: " .. #body .. " bytes", "mods")
  end)
end

--@api-stub: LZipMount:contains
-- Returns whether a virtual path exists in the ZIP mount
do
  -- contains() checks if a file exists in the archive without extracting it.
  -- Use it to probe for optional content before attempting to read.
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
  -- listFiles() returns all file paths in the ZIP as an array.
  -- Use it to enumerate available assets in a content pack or mod archive.
  pcall(function()
    local pack = lurek.filesystem.mountZip("dlc/forest_pack.zip", "mods/forest")
    local files = pack:listFiles()
    lurek.log.info("forest pack contains " .. #files .. " files", "mods")
  end)
end

--@api-stub: LZipMount:prefix
-- Returns the virtual prefix used by this ZIP mount
do
  -- prefix() returns the mount point string you passed to mountZip().
  -- Useful when you store multiple mounts and need to identify them later.
  pcall(function()
    local pack = lurek.filesystem.mountZip("dlc/forest_pack.zip", "mods/forest")
    lurek.log.info("pack mounted at " .. pack:prefix(), "mods")
  end)
end

--@api-stub: LZipMount:type
-- Returns the Lua-visible type name for this ZIP mount handle
do
  -- type() always returns "LZipMount" for ZIP archive handles.
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
  -- typeOf() checks "LZipMount" and "Object".
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
  -- readBytes() is like read() but skips UTF-8 decoding — you get the exact raw
  -- bytes. Use this for images, audio, or any non-text data where byte accuracy
  -- matters (e.g. checking file magic numbers or passing to decoders).
  local ok, data = pcall(lurek.filesystem.readBytes, "assets/hero.png")
  if ok then
    lurek.log.info("readBytes got " .. #data .. " bytes", "fs")
  end
end

--@api-stub: lurek.filesystem.writeBytes
-- Writes binary data through GameFS
do
  -- writeBytes() stores raw binary data without any text encoding. Use it for
  -- writing screenshots, serialized binary formats, or copying binary assets.
  local payload = string.char(0x89, 0x50, 0x4E, 0x47) -- PNG magic header bytes
  lurek.filesystem.writeBytes("save/test_binary.dat", payload)
  lurek.log.info("writeBytes wrote " .. #payload .. " bytes", "fs")
end

print("content/examples/filesystem.lua")

-- =============================================================================
-- STUBS: 5 uncovered lurek.filesystem API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LFileData methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LFileData:getSize ---------------------------------------------
--@api-stub: LFileData:getSize
-- Returns the byte length of this file data.
do
  local fd = lurek.filesystem.newFileData("content/examples/filesystem.lua")
  local sz = fd:getSize()
  lurek.log.debug("FileData size: " .. sz .. " bytes", "fs") -- 11
end

-- ---- Stub: LFileData:type ------------------------------------------------
--@api-stub: LFileData:type
-- Returns the Lua-visible type name for this file data handle.
do
  local obj = lurek.filesystem.newFileData('content/examples/filesystem.lua')
  lurek.log.debug("type: " .. obj:type(), "example") -- "LFileData"
end

-- ---- Stub: LFileData:typeOf ----------------------------------------------
--@api-stub: LFileData:typeOf
-- Returns whether this file data handle matches a supported type name.
do
  local obj = lurek.filesystem.newFileData('content/examples/filesystem.lua')
  lurek.log.debug("typeOf LFileData: " .. tostring(obj:typeOf("LFileData")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LFileHandle methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LFileHandle:type ----------------------------------------------
--@api-stub: LFileHandle:type
-- Returns the Lua-visible type name for this file handle.
do
  local obj = lurek.filesystem.openFile('save/score.txt', 'r')
  lurek.log.debug("type: " .. obj:type(), "example") -- "LFileHandle"
end

-- ---- Stub: LFileHandle:typeOf --------------------------------------------
--@api-stub: LFileHandle:typeOf
-- Returns whether this file handle matches a supported type name.
do
  local obj = lurek.filesystem.openFile('save/score.txt', 'r')
  lurek.log.debug("typeOf LFileHandle: " .. tostring(obj:typeOf("LFileHandle")), "example") -- true
end

-- ---- Stub: lurek.filesystem.read ----------------------------------------
--@api-stub: lurek.filesystem.read
-- Reads the full contents of a file as a string.
do
  local text, err = lurek.filesystem.read("save/score.txt")
  if text then
    lurek.log.debug("read " .. #text .. " bytes", "example")
  else
    lurek.log.debug("read error: " .. tostring(err), "example")
  end
end

-- ---- Stub: lurek.filesystem.write ---------------------------------------
--@api-stub: lurek.filesystem.write
-- Writes a string to a file, creating it if it does not exist.
do
  local ok, err = lurek.filesystem.write("save/_fs_tests/write_test.txt", "hello")
  lurek.log.debug("write ok: " .. tostring(ok), "example")
end
