-- content/examples/filesystem.lua
-- Hand-written coverage of the lurek.filesystem API (54 items).
--
-- The lurek.filesystem namespace is the sandboxed VFS: reads resolve through
-- the game root and any mounts, writes are confined to the save/ directory,
-- and ZIP archives can be mounted at virtual prefixes for content packs.
--
-- Run: cargo run -- content/examples/filesystem.lua
---@diagnostic disable: cast-local-type
-- pcall() is used throughout to construct file handles; the nil-guard pattern
-- (ok, handle = pcall(...); if not ok then handle = nil end) is intentional.

-- â”€â”€ lurek.filesystem.* functions â”€â”€

--@api-stub: lurek.filesystem.mountZip
-- Mounts a ZIP archive at a virtual path prefix, making its contents readable.
-- Use to ship optional content packs or expansion DLC as a single distributable .zip.
-- if false then -- lurek.filesystem.mountZip
--   local ok, pack = pcall(lurek.filesystem.mountZip, "dlc/forest_pack.zip", "mods/forest")
--   if ok and pack:contains("levels/grove.json") then
--     local data = pack:readFile("levels/grove.json")
--     lurek.log.info("forest pack ready: " .. #data .. " bytes", "fs")
--   end
-- end

--@api-stub: lurek.filesystem.watchPath
-- Adds `path` to the polled file-watch list.
-- Pair with pollWatchers() once per second to drive hot-reload of scripts or assets.
-- if false then -- lurek.filesystem.watchPath
--   lurek.filesystem.watchPath("assets/levels/forest.json")
--   lurek.filesystem.watchPath("scripts/enemy.lua")
-- end

--@api-stub: lurek.filesystem.unwatchPath
-- Removes `path` from the polled file-watch list.
-- Call when leaving a level so reloads of unloaded assets do not trigger spurious work.
-- if false then -- lurek.filesystem.unwatchPath
--   lurek.filesystem.watchPath("assets/levels/forest.json")
--   lurek.filesystem.unwatchPath("assets/levels/forest.json")
-- end

--@api-stub: lurek.filesystem.pollWatchers
-- Polls all watched paths and returns an array of paths that changed since the last poll.
-- Drive from a slow timer (1 Hz) rather than every frame; reload only the listed paths.
-- if false then -- lurek.filesystem.pollWatchers
--   local timer = 0
--   function lurek.process(dt)
--     timer = timer + dt
--     if timer < 1 then return end
--     timer = 0
--     for _, path in ipairs(lurek.filesystem.pollWatchers()) do
--       lurek.log.info("changed: " .. path, "hotreload")
--     end
--   end
-- end

--@api-stub: lurek.filesystem.read
-- Reads a text file and returns its contents as a string.
-- Use for small config or save snapshots; for large binaries prefer newFileData or readAsync.
-- if false then -- lurek.filesystem.read
--   local ok, toml = pcall(lurek.filesystem.read, "config/options.toml")
--   if ok then lurek.log.info("loaded options.toml (" .. #toml .. " bytes)", "config") end
-- end

--@api-stub: lurek.filesystem.write
-- Writes a string to a file in the save directory.
-- Writes are sandboxed under save/; create parent dirs first with createDirectory.
-- if false then -- lurek.filesystem.write
--   local score = 12450
--   lurek.filesystem.write("save/highscore.txt", tostring(score))
-- end

--@api-stub: lurek.filesystem.exists
-- Returns whether the given file or directory exists.
-- Use to decide between loading a saved game and starting a fresh one.
-- if false then -- lurek.filesystem.exists
--   if lurek.filesystem.exists("save/slot1.dat") then
--     lurek.log.info("resuming from slot 1", "save")
--   else
--     lurek.log.info("no save, starting new game", "save")
--   end
-- end

--@api-stub: lurek.filesystem.append
-- Opens the file in append mode and writes the given string at the end.
-- Use for rolling logs or telemetry; keep one line per record so tailing tools work.
-- if false then -- lurek.filesystem.append
--   local line = os.date("%Y-%m-%dT%H:%M:%S") .. "\tlevel_complete\tforest_01\n"
--   lurek.filesystem.append("save/telemetry.log", line)
-- end

--@api-stub: lurek.filesystem.openFile
-- Opens a file and returns a readable/writable file handle.
-- Modes: "r" read, "w" truncate-write, "a" append. Always close() when done.
-- if false then -- lurek.filesystem.openFile
--   local fh = lurek.filesystem.openFile("save/slot1.dat", "w")
--   fh:write("level=forest_01;hp=80;mana=42")
--   fh:close()
-- end

--@api-stub: lurek.filesystem.getDirectoryItems
-- Returns a table containing the names of every file and subdirectory in the given path.
-- Use to enumerate save slots or installed mods; result is unsorted, sort if you need order.
-- if false then -- lurek.filesystem.getDirectoryItems
--   local saves = lurek.filesystem.getDirectoryItems("save")
--   lurek.log.info("found " .. #saves .. " save files", "save")
--   for _, name in ipairs(saves) do
--     lurek.log.debug("  save: " .. name, "save")
--   end
-- end

--@api-stub: lurek.filesystem.isFile
-- Returns whether the given path is a regular file.
-- Use to distinguish files from directories before calling read or openFile.
-- if false then -- lurek.filesystem.isFile
--   pcall(function()
--     if lurek.filesystem.isFile("config/options.toml") then
--       local ok_cfg, cfg = pcall(lurek.filesystem.read, "config/options.toml")
--       if not ok_cfg then cfg = nil end
--       lurek.log.info("config loaded (" .. #cfg .. " bytes)", "config")
--     end
--   end)
-- end

--@api-stub: lurek.filesystem.isDirectory
-- Returns whether the given path is a directory.
-- Useful before iterating with getDirectoryItems or recursive listings.
-- if false then -- lurek.filesystem.isDirectory
--   if lurek.filesystem.isDirectory("assets/levels") then
--     local levels = lurek.filesystem.getDirectoryItems("assets/levels")
--     lurek.log.info("levels available: " .. #levels, "scene")
--   end
-- end

--@api-stub: lurek.filesystem.createDirectory
-- Creates a directory and any missing parent directories in the save area.
-- Call once at startup before writing nested save files; safe to call when dir already exists.
-- if false then -- lurek.filesystem.createDirectory
--   lurek.filesystem.createDirectory("save/screenshots")
--   lurek.filesystem.write("save/screenshots/last_run.txt", "ok")
-- end

--@api-stub: lurek.filesystem.remove
-- Permanently deletes a file or empty directory from the save directory.
-- Restricted to save/; use removeDir to recursively delete a non-empty folder.
-- if false then -- lurek.filesystem.remove
--   if lurek.filesystem.exists("save/temp_export.json") then
--     lurek.filesystem.remove("save/temp_export.json")
--     lurek.log.info("cleared stale export", "save")
--   end
-- end

--@api-stub: lurek.filesystem.getInfo
-- Returns a table of metadata for a path, or nil if the path does not exist.
-- Inspect the type/size/modtime/readonly fields to drive UI listings of save files.
-- if false then -- lurek.filesystem.getInfo
--   local info = lurek.filesystem.getInfo("save/slot1.dat")
--   if info then
--     lurek.log.info("slot1 " .. info.type .. " " .. info.size .. " bytes", "save")
--   end
-- end

--@api-stub: lurek.filesystem.getSource
-- Returns the absolute path of the directory the game was loaded from.
-- Useful for diagnostic logs and for spawning child processes that need the game folder.
-- if false then -- lurek.filesystem.getSource
--   local src = lurek.filesystem.getSource()
--   lurek.log.info("game source dir: " .. src, "fs")
-- end

--@api-stub: lurek.filesystem.getSaveDirectory
-- Returns the sandboxed save data directory path.
-- Show this in the options menu so players can find their saves on disk.
-- if false then -- lurek.filesystem.getSaveDirectory
--   local save_dir = lurek.filesystem.getSaveDirectory()
--   lurek.log.info("saves stored at: " .. save_dir, "save")
-- end

--@api-stub: lurek.filesystem.getWorkingDirectory
-- Returns the current working directory path.
-- Mostly useful for diagnostics; never assume it equals the game source directory.
-- if false then -- lurek.filesystem.getWorkingDirectory
--   local cwd = lurek.filesystem.getWorkingDirectory()
--   lurek.log.debug("cwd at launch: " .. cwd, "fs")
-- end

--@api-stub: lurek.filesystem.getUserDirectory
-- Returns the current user's home directory path.
-- Use as a fallback default location for export/import file pickers.
-- if false then -- lurek.filesystem.getUserDirectory
--   local home = lurek.filesystem.getUserDirectory()
--   lurek.log.info("user home: " .. home, "fs")
-- end

--@api-stub: lurek.filesystem.getIdentity
-- Returns the identity string used to locate the game's save directory.
-- Identity selects the per-game folder name under the OS save root.
-- if false then -- lurek.filesystem.getIdentity
--   local id = lurek.filesystem.getIdentity()
--   lurek.log.info("save identity: " .. id, "save")
-- end

--@api-stub: lurek.filesystem.setIdentity
-- Sets the identity string that names the game's sandboxed save-data directory.
-- Call once at startup, before any read/write, to pin saves to your game name.
-- if false then -- lurek.filesystem.setIdentity
--   lurek.filesystem.setIdentity("forest_quest")
--   lurek.log.info("save identity set to forest_quest", "save")
-- end

--@api-stub: lurek.filesystem.lines
-- Returns an iterator function over the lines of a text file.
-- Streams line-by-line so very large logs or CSVs do not all sit in memory at once.
-- if false then -- lurek.filesystem.lines
--   pcall(function()
--     local count = 0
--     for line in lurek.filesystem.lines("assets/data/dialogue.csv") do
--       if #line > 0 then count = count + 1 end
--     end
--     lurek.log.info("dialogue lines: " .. count, "i18n")
--   end)
-- end

--@api-stub: lurek.filesystem.readAsync
-- Starts loading a file in the background and returns an opaque handle.
-- Pair with pollAsync() each frame; use for big level data so the main thread stays smooth.
-- if false then -- lurek.filesystem.readAsync
--   local pending
--   function lurek.init()
--     pending = lurek.filesystem.readAsync("assets/levels/forest.json")
--   end
-- end

--@api-stub: lurek.filesystem.pollAsync
-- Polls an async load handle, returning status and optional data.
-- Status is "pending", "done", or "error"; data is non-nil only when status is "done".
-- if false then -- lurek.filesystem.pollAsync
--   local pending
--   function lurek.init() pending = lurek.filesystem.readAsync("assets/levels/forest.json") end
--   function lurek.process(dt)
--     if not pending then return end
--     local status, data = lurek.filesystem.pollAsync(pending)
--     if status == "done" then
--       lurek.log.info("level loaded: " .. #data .. " bytes", "scene")
--       pending = nil
--     end
--   end
-- end

--@api-stub: lurek.filesystem.writeAsync
-- Starts writing binary data to a file in save/ on a background thread.
-- Use for large save snapshots so the main loop does not stall.
-- if false then -- lurek.filesystem.writeAsync
--   local write_handle
--   function lurek.init()
--     local payload = "{\"checkpoint\":7,\"hp\":83}"
--     write_handle = lurek.filesystem.writeAsync("save/checkpoint.json", payload)
--   end
-- end

--@api-stub: lurek.filesystem.pollAsyncWrite
-- Polls an async write handle, returning status and optional payload.
-- Status is "pending", "done", or "error". On "done", payload is bytes written as a string.
-- if false then -- lurek.filesystem.pollAsyncWrite
--   local write_handle
--   function lurek.init()
--     write_handle = lurek.filesystem.writeAsync("save/telemetry.json", "{\"ok\":true}")
--   end
--   function lurek.process(dt)
--     if not write_handle then return end
--     local status, info = lurek.filesystem.pollAsyncWrite(write_handle)
--     if status == "done" then
--       lurek.log.info("async write complete: " .. tostring(info) .. " bytes", "save")
--       write_handle = nil
--     elseif status == "error" then
--       lurek.log.error("async write failed: " .. tostring(info), "save")
--       write_handle = nil
--     end
--   end
-- end

--@api-stub: lurek.filesystem.mount
-- Mounts a directory at a virtual path inside the game filesystem.
-- Mounted paths layer over the game root; later mounts shadow earlier ones for the same VFS path.
-- if false then -- lurek.filesystem.mount
--   local ok = pcall(lurek.filesystem.mount, "../mods/extra", "mods/extra")
--   if ok then lurek.log.info("mounted extra mods", "mods") end
-- end

--@api-stub: lurek.filesystem.unmount
-- Removes a virtual mount layer by mountpoint.
-- Call when disabling a mod from the options screen so its assets stop being visible.
-- if false then -- lurek.filesystem.unmount
--   if lurek.filesystem.unmount("mods/extra") then
--     lurek.log.info("extra mods unmounted", "mods")
--   end
-- end

--@api-stub: lurek.filesystem.load
-- Loads and compiles a Lua file from the VFS, returning it as a callable function.
-- Use to load mod scripts at runtime; call the returned function to execute the chunk.
-- if false then -- lurek.filesystem.load
--   pcall(function()
--     local chunk = lurek.filesystem.load("scripts/enemy_ai.lua")
--     local enemy_module = chunk()
--     lurek.log.info("enemy AI module loaded", "ai")
--   end)
-- end

--@api-stub: lurek.filesystem.newFileData
-- Loads a file from the VFS into a FileData buffer.
-- Use for binary blobs (textures, audio decoders) where you want size + filename metadata.
-- if false then -- lurek.filesystem.newFileData
--   pcall(function()
--     local fd = lurek.filesystem.newFileData("assets/sfx/jump.ogg")
--     lurek.log.info("loaded " .. fd:getFilename() .. " (" .. fd:getSize() .. " bytes)", "audio")
--   end)
-- end

--@api-stub: lurek.filesystem.copy
-- Copies a file within the sandbox.
-- Source can be anywhere readable; destination MUST live under save/.
-- if false then -- lurek.filesystem.copy
--   lurek.filesystem.copy("save/slot1.dat", "save/slot1.bak")
--   lurek.log.info("backed up slot 1", "save")
-- end

--@api-stub: lurek.filesystem.move
-- Moves (renames) a file within the `save/` directory.
-- Use for atomic save rotation: write to slot1.tmp then move to slot1.dat.
-- if false then -- lurek.filesystem.move
--   lurek.filesystem.write("save/slot1.tmp", "level=forest_02;hp=92")
--   lurek.filesystem.move("save/slot1.tmp", "save/slot1.dat")
-- end

--@api-stub: lurek.filesystem.removeDir
-- Recursively deletes a directory and all its contents within `save/`.
-- Destructive: use only on directories your game owns (e.g. clearing a temp screenshot folder).
-- if false then -- lurek.filesystem.removeDir
--   if lurek.filesystem.isDirectory("save/screenshots") then
--     lurek.filesystem.removeDir("save/screenshots")
--     lurek.log.info("cleared screenshots cache", "save")
--   end
-- end

--@api-stub: lurek.filesystem.glob
-- Returns a sorted list of paths matching a simple wildcard pattern.
-- `*` matches one path component; `?` matches one character. Patterns are game-root-relative.
-- if false then -- lurek.filesystem.glob
--   local saves = lurek.filesystem.glob("save/slot*.dat")
--   for _, path in ipairs(saves) do
--     lurek.log.info("save: " .. path, "save")
--   end
-- end

--@api-stub: lurek.filesystem.listRecursive
-- Returns a sorted list of all files under `path`, recursively.
-- Use to enumerate every asset under a directory tree, e.g. all level JSON files.
-- if false then -- lurek.filesystem.listRecursive
--   local ok, files = pcall(lurek.filesystem.listRecursive, "assets/levels")
--   if ok then
--     lurek.log.info("level assets: " .. #files, "scene")
--   end
-- end

--@api-stub: lurek.filesystem.stat
-- Returns lightweight file statistics for the given path.
-- Cheaper than getInfo when you only need size/isFile/isDir; raises on missing or sandboxed paths.
-- if false then -- lurek.filesystem.stat
--   local ok, s = pcall(lurek.filesystem.stat, "assets/levels/forest.json")
--   if ok and s.isFile then
--     lurek.log.info("forest.json: " .. s.size .. " bytes", "scene")
--   end
-- end

--@api-stub: lurek.filesystem.createTempFile
-- Creates an empty temporary file in the `save/` sandbox and returns its relative path.
-- You own the file: delete it with remove() once the export or scratch buffer is no longer needed.
-- if false then -- lurek.filesystem.createTempFile
--   local tmp = lurek.filesystem.createTempFile("export")
--   lurek.filesystem.write(tmp, "snapshot=" .. os.time())
--   lurek.log.info("export staged at " .. tmp, "save")
-- end

--@api-stub: lurek.filesystem.mkdir
-- Creates a directory (and any missing parents) relative to the game root.
-- Unlike createDirectory this is not restricted to save/; mostly used by evidence/test runners.
-- if false then -- lurek.filesystem.mkdir
--   pcall(function()
--     lurek.filesystem.mkdir("save/run_001")
--     lurek.filesystem.write("save/run_001/notes.txt", "ok")
--   end)
-- end

--@api-stub: lurek.filesystem.toAbsolutePath
-- Resolves a path relative to the game root to an absolute OS path string.
-- Use when handing a path to a non-VFS API such as Lua's stock io.open or an OS launcher.
-- if false then -- lurek.filesystem.toAbsolutePath
--   local abs = lurek.filesystem.toAbsolutePath("save/slot1.dat")
--   lurek.log.info("absolute path: " .. abs, "fs")
-- end


-- â”€â”€ FileData methods â”€â”€

--@api-stub: LFileData:getSize
-- Returns the file size in bytes.
-- Combine with getFilename for a one-line load report when streaming many assets.
-- if false then -- FileData:getSize
--   pcall(function()
--     local fd = lurek.filesystem.newFileData("assets/sfx/jump.ogg")
--     local kb = fd:getSize() / 1024
--     lurek.log.info(string.format("jump.ogg = %.1f KiB", kb), "audio")
--   end)
-- end

--@api-stub: LFileData:getString
-- Returns the file content as a Lua string.
-- Use to hand binary buffers to a custom decoder, or to compute a checksum over the bytes.
-- if false then -- FileData:getString
--   pcall(function()
--     local fd = lurek.filesystem.newFileData("config/options.toml")
--     local body = fd:getString()
--     lurek.log.info("first byte: " .. string.byte(body, 1), "config")
--   end)
-- end

--@api-stub: LFileData:getFilename
-- Returns the virtual path this data was loaded from.
-- Useful when a generic loader pipes FileData into a registry keyed by source path.
-- if false then -- FileData:getFilename
--   pcall(function()
--     local fd = lurek.filesystem.newFileData("assets/levels/forest.json")
--     lurek.log.info("loaded " .. fd:getFilename(), "scene")
--   end)
-- end


-- â”€â”€ FileHandle methods â”€â”€

--@api-stub: LFileHandle:read
-- Reads bytes from the file, returning them as a string.
-- Pass a count to read at most N bytes; omit to read until EOF in one call.
-- if false then -- FileHandle:read
--   local fh = lurek.filesystem.openFile("save/slot1.dat", "r")
--   local body = fh:read()
--   fh:close()
--   lurek.log.info("slot1 size: " .. #body .. " bytes", "save")
-- end

--@api-stub: LFileHandle:readLine
-- Reads the next line from the file without the trailing newline.
-- Returns nil at EOF; loop while non-nil to walk a text file one line at a time.
-- if false then -- FileHandle:readLine
--   pcall(function()
--     local fh = lurek.filesystem.openFile("save/telemetry.log", "r")
--     local first = fh:readLine()
--     fh:close()
--     lurek.log.info("first telemetry line: " .. (first or "<empty>"), "fs")
--   end)
-- end

--@api-stub: LFileHandle:write
-- Writes a string to the file and returns the number of bytes written.
-- Open with mode "w" to truncate, "a" to append; remember to close() to flush.
-- if false then -- FileHandle:write
--   local fh = lurek.filesystem.openFile("save/score.txt", "w")
--   local n = fh:write("12450")
--   fh:close()
--   lurek.log.info("wrote " .. n .. " bytes to score.txt", "save")
-- end

--@api-stub: LFileHandle:seek
-- Seeks the file position to the given byte offset from the start.
-- Use for fixed-record save files where you want to update one slot without rewriting the rest.
-- if false then -- FileHandle:seek
--   local fh = lurek.filesystem.openFile("save/slot1.dat", "r")
--   fh:seek(16)
--   local chunk = fh:read(8)
--   fh:close()
--   lurek.log.debug("bytes 16..23 = " .. chunk, "save")
-- end

--@api-stub: LFileHandle:tell
-- Returns the current read/write byte offset from the start of the file.
-- Call after a partial read to remember where to resume on the next pass.
-- if false then -- FileHandle:tell
--   pcall(function()
--     local fh = lurek.filesystem.openFile("assets/levels/forest.json", "r")
--     fh:read(64)
--     lurek.log.info("cursor at byte " .. fh:tell(), "scene")
--     fh:close()
--   end)
-- end

--@api-stub: LFileHandle:getSize
-- Returns the size of the open file in bytes.
-- Use to pre-allocate buffers or to drive a load progress bar.
-- if false then -- FileHandle:getSize
--   pcall(function()
--     local fh = lurek.filesystem.openFile("assets/levels/forest.json", "r")
--     lurek.log.info("level file size: " .. fh:getSize(), "scene")
--     fh:close()
--   end)
-- end

--@api-stub: LFileHandle:getMode
-- Returns the access mode the file was opened with.
-- Useful in helper functions that branch on whether the handle is readable or writable.
-- if false then -- FileHandle:getMode
--   local fh = lurek.filesystem.openFile("save/slot1.dat", "r")
--   lurek.log.debug("opened slot1 in mode " .. fh:getMode(), "save")
--   fh:close()
-- end

--@api-stub: LFileHandle:flush
-- Flushes all buffered writes to disk without closing the handle.
-- Call after each completed game-state checkpoint so a crash loses at most one round.
-- if false then -- FileHandle:flush
--   local fh = lurek.filesystem.openFile("save/journal.log", "a")
--   fh:write("checkpoint=forest_02\n")
--   fh:flush()
--   fh:close()
-- end

--@api-stub: LFileHandle:close
-- Flushes any pending writes and closes the file handle.
-- Always close handles when done; leaking them holds OS file descriptors and locks.
-- if false then -- FileHandle:close
--   local fh = lurek.filesystem.openFile("save/slot1.dat", "w")
--   fh:write("hp=100;mana=50")
--   fh:close()
-- end

--@api-stub: LFileHandle:isEOF
-- Returns whether the read cursor has reached the end of the file.
-- Use as a loop condition when reading a file in fixed-size chunks.
-- if false then -- FileHandle:isEOF
--   pcall(function()
--     local fh = lurek.filesystem.openFile("save/telemetry.log", "r")
--     while not fh:isEOF() do
--       local chunk = fh:read(256)
--       if not chunk or #chunk == 0 then break end
--     end
--     fh:close()
--   end)
-- end


-- â”€â”€ ZipMount methods â”€â”€

--@api-stub: LZipMount:readFile
-- Reads a file from the ZIP and returns it as a string of bytes.
-- Cheaper than mounting + lurek.filesystem.read when you need exactly one file out of the archive.
-- if false then -- ZipMount:readFile
--   pcall(function()
--     local pack = lurek.filesystem.mountZip("dlc/forest_pack.zip", "mods/forest")
--     local body = pack:readFile("levels/grove.json")
--     lurek.log.info("grove.json: " .. #body .. " bytes", "mods")
--   end)
-- end

--@api-stub: LZipMount:contains
-- Returns true if `virtual_path` exists inside this ZIP mount.
-- Probe before readFile so a missing optional asset does not raise an error.
-- if false then -- ZipMount:contains
--   pcall(function()
--     local pack = lurek.filesystem.mountZip("dlc/forest_pack.zip", "mods/forest")
--     if pack:contains("levels/secret.json") then
--       lurek.log.info("secret level present in pack", "mods")
--     end
--   end)
-- end

--@api-stub: LZipMount:listFiles
-- Returns a sorted array of all virtual paths exposed by this ZIP mount.
-- Use to enumerate every asset shipped by a content pack at startup.
-- if false then -- ZipMount:listFiles
--   pcall(function()
--     local pack = lurek.filesystem.mountZip("dlc/forest_pack.zip", "mods/forest")
--     local files = pack:listFiles()
--     lurek.log.info("forest pack contains " .. #files .. " files", "mods")
--   end)
-- end

--@api-stub: LZipMount:prefix
-- Returns the virtual path prefix this archive was mounted under.
-- Useful for building absolute virtual paths or reporting which prefix a mount owns.
-- if false then -- ZipMount:prefix
--   pcall(function()
--     local pack = lurek.filesystem.mountZip("dlc/forest_pack.zip", "mods/forest")
--     lurek.log.info("pack mounted at " .. pack:prefix(), "mods")
--   end)
-- end

-- =============================================================================
-- STUBS: 9 uncovered lurek.filesystem API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.filesystem.mount ----------------------------------------
--@api-stub: lurek.filesystem.mount
-- Mounts a directory at a virtual path inside the game filesystem.
-- if false then -- lurek.filesystem.mount
--   local ok = pcall(lurek.filesystem.mount, ".", "/extra")
--   lurek.log.info("mount ok=" .. tostring(ok), "filesystem")
-- end

-- ---- Stub: lurek.filesystem.listRecursive --------------------------------
--@api-stub: lurek.filesystem.listRecursive
-- Returns a sorted list of all files under `path`, recursively.
-- if false then -- lurek.filesystem.listRecursive
--   local ok, files = pcall(lurek.filesystem.listRecursive, ".")
--   if ok then lurek.log.info("listRecursive count=" .. tostring(#files), "filesystem") end
-- end

-- ---- Stub: lurek.filesystem.stat -----------------------------------------
--@api-stub: lurek.filesystem.stat
-- Returns lightweight file statistics for the given path.
-- if false then -- lurek.filesystem.stat
--   local ok, info = pcall(lurek.filesystem.stat, ".")
--   if ok and info then lurek.log.info("stat type=" .. tostring(info.type), "filesystem") end
-- end


-- -----------------------------------------------------------------------------
-- ZipMount methods
-- -----------------------------------------------------------------------------

-- =============================================================================
-- STUBS: 9 uncovered lurek.filesystem API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.filesystem.mount ----------------------------------------
--@api-stub: LFileData:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LFileData:type
--   local ok_fd, file_data_obj = pcall(lurek.filesystem.newFileData, "save/highscore.txt")
--   if ok_fd and file_data_obj then
--     local t = file_data_obj:type()
--     lurek.log.info("LFileData:type = " .. t, "filesystem")
--   else
--     lurek.log.info("LFileData:type = skipped", "filesystem")
--   end
-- end
--@api-stub: LFileData:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LFileData:typeOf
--   local ok_fd2, file_data_obj2 = pcall(lurek.filesystem.newFileData, "save/highscore.txt")
--   if ok_fd2 and file_data_obj2 then
--     lurek.log.info("is LFileData: " .. tostring(file_data_obj2:typeOf("LFileData")), "filesystem")
--     lurek.log.info("is wrong: " .. tostring(file_data_obj2:typeOf("Unknown")), "filesystem")
--   else
--     lurek.log.info("LFileData:typeOf = skipped", "filesystem")
--   end
-- end
--@api-stub: LFileHandle:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LFileHandle:type
--   local ok_fh, file_handle_obj = pcall(lurek.filesystem.openFile, "save/highscore.txt", nil)
--   if not ok_fh then file_handle_obj = nil end
--   local t = file_handle_obj and file_handle_obj:type() or "LFileHandle"
--   lurek.log.info("LFileHandle:type = " .. t, "filesystem")
-- end
--@api-stub: LFileHandle:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LFileHandle:typeOf
--   local ok_fh, file_handle_obj = pcall(lurek.filesystem.openFile, "save/highscore.txt", nil)
--   if not ok_fh then file_handle_obj = nil end
--   lurek.log.info("is LFileHandle: " .. tostring(file_handle_obj and file_handle_obj:typeOf("LFileHandle") or false), "filesystem")
--   lurek.log.info("is wrong: " .. tostring(file_handle_obj and file_handle_obj:typeOf("Unknown") or false), "filesystem")
-- end
--@api-stub: LZipMount:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LZipMount:type
--   local ok_zm, zip_mount_obj = pcall(lurek.filesystem.mountZip, "assets/data.zip", nil)
--   if not ok_zm then zip_mount_obj = nil end
--   local t = zip_mount_obj and zip_mount_obj:type() or "LZipMount"
--   lurek.log.info("LZipMount:type = " .. t, "filesystem")
-- end
--@api-stub: LZipMount:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LZipMount:typeOf
--   local ok_zm2, zip_mount_obj2 = pcall(lurek.filesystem.mountZip, "assets/data.zip", nil)
--   if not ok_zm2 then zip_mount_obj2 = nil end
--   lurek.log.info("is LZipMount: " .. tostring(zip_mount_obj2 and zip_mount_obj2:typeOf("LZipMount") or false), "filesystem")
--   lurek.log.info("is wrong: " .. tostring(zip_mount_obj2 and zip_mount_obj2:typeOf("Unknown") or false), "filesystem")
-- end
--@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- =============================================================================
-- STUBS: 2 uncovered lurek.filesystem API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.filesystem.readBytes ------------------------------------
--@api-stub: lurek.filesystem.readBytes
-- Reads a file as raw bytes and returns a binary Lua string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.filesystem.readBytes("assets/hero.png")  -- -> string

-- ---- Stub: lurek.filesystem.writeBytes -----------------------------------
--@api-stub: lurek.filesystem.writeBytes
-- Writes a binary Lua string to a file in the save directory.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lurek.filesystem.writeBytes("assets/hero.png", data)
