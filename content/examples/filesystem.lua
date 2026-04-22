-- content/examples/filesystem.lua
-- Practical usage examples for the lurek.filesystem API (54 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.filesystem.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/filesystem.lua

print("[example] lurek.filesystem — 54 API entries")

-- ── lurek.filesystem.* free functions ──

--@api-stub: lurek.filesystem.mountZip
-- Mounts a ZIP archive at a virtual path prefix, making its contents readable.
-- Call when you need to invoke mount zip.
local ok, result = pcall(function() return lurek.filesystem.mountZip("save/example.txt", nil) end)
if ok then print("lurek.filesystem.mountZip ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.filesystem.watchPath
-- Adds `path` to the polled file-watch list.
-- Call when you need to invoke watch path.
local ok, result = pcall(function() return lurek.filesystem.watchPath("save/example.txt") end)
if ok then print("lurek.filesystem.watchPath ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.filesystem.unwatchPath
-- Removes `path` from the polled file-watch list.
-- No-op if not watched.
local ok, result = pcall(function() return lurek.filesystem.unwatchPath("save/example.txt") end)
if ok then print("lurek.filesystem.unwatchPath ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.filesystem.pollWatchers
-- Polls all watched paths and returns an array of paths that changed since the.
-- Call when you need to invoke poll watchers.
local ok, result = pcall(function() return lurek.filesystem.pollWatchers() end)
if ok then print("lurek.filesystem.pollWatchers ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.filesystem.read
-- Reads a text file and returns its contents as a string.
-- Call when you need to invoke read.
local ok, value = pcall(function() return lurek.filesystem.read("save/example.txt") end)
local v = ok and value or "(unavailable)"
print("lurek.filesystem.read ->", v)

--@api-stub: lurek.filesystem.write
-- Writes a string to a file in the save directory.
-- Call when you need to invoke write.
local ok, result = pcall(function() return lurek.filesystem.write("save/example.txt", {}) end)
if ok then print("lurek.filesystem.write ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.filesystem.exists
-- Returns whether the given file or directory exists.
-- Call when you need to invoke exists.
local ok, result = pcall(function() return lurek.filesystem.exists("save/example.txt") end)
if ok then print("lurek.filesystem.exists ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.filesystem.append
-- Opens the file in append mode and writes the given string at the end.
-- Call when you need to invoke append.
local ok, err = pcall(function() lurek.filesystem.append("save/example.txt", {}) end)
if not ok then print("mutator skipped:", err) end
print("lurek.filesystem.append done=", ok)

--@api-stub: lurek.filesystem.openFile
-- Opens a file and returns a readable/writable file handle.
-- Call when you need to invoke open file.
local ok, obj = pcall(function() return lurek.filesystem.openFile("save/example.txt", nil) end)
if ok and obj then print("created:", obj) end
print("lurek.filesystem.openFile ok=", ok)

--@api-stub: lurek.filesystem.getDirectoryItems
-- Returns a table containing the names of every file and subdirectory in the given path.
-- Call when you need to read directory items.
local ok, value = pcall(function() return lurek.filesystem.getDirectoryItems("save/example.txt") end)
local v = ok and value or "(unavailable)"
print("lurek.filesystem.getDirectoryItems ->", v)

--@api-stub: lurek.filesystem.isFile
-- Returns whether the given path is a regular file.
-- Call when you need to check is file.
local ok, result = pcall(function() return lurek.filesystem.isFile("save/example.txt") end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.filesystem.isFile ok=", ok)

--@api-stub: lurek.filesystem.isDirectory
-- Returns whether the given path is a directory.
-- Call when you need to check is directory.
local ok, result = pcall(function() return lurek.filesystem.isDirectory("save/example.txt") end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.filesystem.isDirectory ok=", ok)

--@api-stub: lurek.filesystem.createDirectory
-- Creates a directory and any missing parent directories in the save area.
-- Call when you need to create a new directory.
local ok, obj = pcall(function() return lurek.filesystem.createDirectory("save/example.txt") end)
if ok and obj then print("created:", obj) end
print("lurek.filesystem.createDirectory ok=", ok)

--@api-stub: lurek.filesystem.remove
-- Permanently deletes a file or empty directory from the save directory.
-- Call when you need to invoke remove.
local ok, err = pcall(function() lurek.filesystem.remove("save/example.txt") end)
if not ok then print("skipped:", err) end
print("lurek.filesystem.remove cleared=", ok)

--@api-stub: lurek.filesystem.getInfo
-- Returns a table of metadata for a path, or nil if the path does not exist.
-- Call when you need to read info.
local ok, value = pcall(function() return lurek.filesystem.getInfo("save/example.txt") end)
local v = ok and value or "(unavailable)"
print("lurek.filesystem.getInfo ->", v)

--@api-stub: lurek.filesystem.getSource
-- Returns the absolute path of the directory the game was loaded from.
-- Call when you need to read source.
local ok, value = pcall(function() return lurek.filesystem.getSource() end)
local v = ok and value or "(unavailable)"
print("lurek.filesystem.getSource ->", v)

--@api-stub: lurek.filesystem.getSaveDirectory
-- Returns the sandboxed save data directory path.
-- Call when you need to read save directory.
local ok, value = pcall(function() return lurek.filesystem.getSaveDirectory() end)
local v = ok and value or "(unavailable)"
print("lurek.filesystem.getSaveDirectory ->", v)

--@api-stub: lurek.filesystem.getWorkingDirectory
-- Returns the current working directory path.
-- Call when you need to read working directory.
local ok, value = pcall(function() return lurek.filesystem.getWorkingDirectory() end)
local v = ok and value or "(unavailable)"
print("lurek.filesystem.getWorkingDirectory ->", v)

--@api-stub: lurek.filesystem.getUserDirectory
-- Returns the current user's home directory path.
-- Call when you need to read user directory.
local ok, value = pcall(function() return lurek.filesystem.getUserDirectory() end)
local v = ok and value or "(unavailable)"
print("lurek.filesystem.getUserDirectory ->", v)

--@api-stub: lurek.filesystem.getIdentity
-- Returns the identity string used to locate the game's save directory.
-- Call when you need to read identity.
local ok, value = pcall(function() return lurek.filesystem.getIdentity() end)
local v = ok and value or "(unavailable)"
print("lurek.filesystem.getIdentity ->", v)

--@api-stub: lurek.filesystem.setIdentity
-- Sets the identity string that names the game's sandboxed save-data directory.
-- Call when you need to assign identity.
local ok, err = pcall(function() lurek.filesystem.setIdentity("save/example.txt") end)
if not ok then print("set skipped:", err) end
print("lurek.filesystem.setIdentity applied=", ok)

--@api-stub: lurek.filesystem.lines
-- Returns an iterator function over the lines of a text file.
-- Call when you need to invoke lines.
local ok, result = pcall(function() return lurek.filesystem.lines("save/example.txt") end)
if ok then print("lurek.filesystem.lines ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.filesystem.readAsync
-- Starts loading a file in the background and returns an opaque handle.
-- Call when you need to invoke read async.
local ok, value = pcall(function() return lurek.filesystem.readAsync("save/example.txt") end)
local v = ok and value or "(unavailable)"
print("lurek.filesystem.readAsync ->", v)

--@api-stub: lurek.filesystem.pollAsync
-- Polls an async load handle, returning status and optional data.
-- Call when you need to invoke poll async.
local ok, result = pcall(function() return lurek.filesystem.pollAsync(1) end)
if ok then print("lurek.filesystem.pollAsync ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.filesystem.mount
-- Mounts a directory at a virtual path inside the game filesystem.
-- Call when you need to invoke mount.
local ok, result = pcall(function() return lurek.filesystem.mount(nil, nil) end)
if ok then print("lurek.filesystem.mount ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.filesystem.unmount
-- Removes a virtual mount layer by mountpoint.
-- Call when you need to invoke unmount.
local ok, result = pcall(function() return lurek.filesystem.unmount(nil) end)
if ok then print("lurek.filesystem.unmount ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.filesystem.load
-- Loads and compiles a Lua file from the VFS, returning it as a callable function.
-- Call when you need to invoke load.
local ok, obj = pcall(function() return lurek.filesystem.load("save/example.txt") end)
if ok and obj then print("created:", obj) end
print("lurek.filesystem.load ok=", ok)

--@api-stub: lurek.filesystem.newFileData
-- Loads a file from the VFS into a FileData buffer.
-- Call when you need to create a new file data.
local ok, obj = pcall(function() return lurek.filesystem.newFileData("save/example.txt") end)
if ok and obj then print("created:", obj) end
print("lurek.filesystem.newFileData ok=", ok)

--@api-stub: lurek.filesystem.copy
-- Copies a file within the sandbox.
-- Call when you need to invoke copy.
local ok, result = pcall(function() return lurek.filesystem.copy(nil, nil) end)
if ok then print("lurek.filesystem.copy ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.filesystem.move
-- Moves (renames) a file within the `save/` directory.
-- Call when you need to invoke move.
local ok, result = pcall(function() return lurek.filesystem.move(nil, nil) end)
if ok then print("lurek.filesystem.move ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.filesystem.removeDir
-- Recursively deletes a directory and all its contents within `save/`.
-- Call when you need to remove dir.
local ok, err = pcall(function() lurek.filesystem.removeDir("save/example.txt") end)
if not ok then print("skipped:", err) end
print("lurek.filesystem.removeDir cleared=", ok)

--@api-stub: lurek.filesystem.glob
-- Returns a sorted list of paths matching a simple wildcard pattern.
-- Call when you need to invoke glob.
local ok, result = pcall(function() return lurek.filesystem.glob(nil) end)
if ok then print("lurek.filesystem.glob ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.filesystem.listRecursive
-- Returns a sorted list of all files under `path`, recursively.
-- Call when you need to invoke list recursive.
local ok, result = pcall(function() return lurek.filesystem.listRecursive("save/example.txt") end)
if ok then print("lurek.filesystem.listRecursive ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.filesystem.stat
-- Returns lightweight file statistics for the given path.
-- Call when you need to invoke stat.
local ok, result = pcall(function() return lurek.filesystem.stat("save/example.txt") end)
if ok then print("lurek.filesystem.stat ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.filesystem.createTempFile
-- Creates an empty temporary file in the `save/` sandbox and returns its.
-- Call when you need to create a new temp file.
local ok, obj = pcall(function() return lurek.filesystem.createTempFile(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.filesystem.createTempFile ok=", ok)

--@api-stub: lurek.filesystem.mkdir
-- Creates a directory (and any missing parents) relative to the game root.
-- Call when you need to invoke mkdir.
local ok, result = pcall(function() return lurek.filesystem.mkdir("save/example.txt") end)
if ok then print("lurek.filesystem.mkdir ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.filesystem.toAbsolutePath
-- Resolves a path relative to the game root to an absolute OS path string.
-- Call when you need to invoke to absolute path.
local ok, result = pcall(function() return lurek.filesystem.toAbsolutePath("save/example.txt") end)
if ok then print("lurek.filesystem.toAbsolutePath ->", result)
else print("unavailable:", result) end

-- ── FileData methods ──

--@api-stub: FileData:getSize
-- Returns the file size in bytes.
-- Call when you need to read size.
-- Build a FileData via the appropriate lurek.filesystem.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.filesystem.newFileData(...)
if instance then
  local ok, result = pcall(function() return instance:getSize() end)
  print("FileData:getSize ->", ok, result)
end

--@api-stub: FileData:getString
-- Returns the file content as a Lua string.
-- Call when you need to read string.
-- Build a FileData via the appropriate lurek.filesystem.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.filesystem.newFileData(...)
if instance then
  local ok, result = pcall(function() return instance:getString() end)
  print("FileData:getString ->", ok, result)
end

--@api-stub: FileData:getFilename
-- Returns the virtual path this data was loaded from.
-- Call when you need to read filename.
-- Build a FileData via the appropriate lurek.filesystem.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.filesystem.newFileData(...)
if instance then
  local ok, result = pcall(function() return instance:getFilename() end)
  print("FileData:getFilename ->", ok, result)
end

-- ── FileHandle methods ──

--@api-stub: FileHandle:read
-- Reads bytes from the file, returning them as a string.
-- Call when you need to invoke read.
-- Build a FileHandle via the appropriate lurek.filesystem.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.filesystem.newFileHandle(...)
if instance then
  local ok, result = pcall(function() return instance:read(10) end)
  print("FileHandle:read ->", ok, result)
end

--@api-stub: FileHandle:readLine
-- Reads the next line from the file without the trailing newline.
-- Call when you need to invoke read line.
-- Build a FileHandle via the appropriate lurek.filesystem.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.filesystem.newFileHandle(...)
if instance then
  local ok, result = pcall(function() return instance:readLine() end)
  print("FileHandle:readLine ->", ok, result)
end

--@api-stub: FileHandle:write
-- Writes a string to the file and returns the number of bytes written.
-- Call when you need to invoke write.
-- Build a FileHandle via the appropriate lurek.filesystem.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.filesystem.newFileHandle(...)
if instance then
  local ok, result = pcall(function() return instance:write({}) end)
  print("FileHandle:write ->", ok, result)
end

--@api-stub: FileHandle:seek
-- Seeks the file position to the given byte offset from the start.
-- Call when you need to invoke seek.
-- Build a FileHandle via the appropriate lurek.filesystem.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.filesystem.newFileHandle(...)
if instance then
  local ok, result = pcall(function() return instance:seek(nil) end)
  print("FileHandle:seek ->", ok, result)
end

--@api-stub: FileHandle:tell
-- Returns the current read/write byte offset from the start of the file.
-- Call when you need to invoke tell.
-- Build a FileHandle via the appropriate lurek.filesystem.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.filesystem.newFileHandle(...)
if instance then
  local ok, result = pcall(function() return instance:tell() end)
  print("FileHandle:tell ->", ok, result)
end

--@api-stub: FileHandle:getSize
-- Returns the size of the open file in bytes.
-- Call when you need to read size.
-- Build a FileHandle via the appropriate lurek.filesystem.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.filesystem.newFileHandle(...)
if instance then
  local ok, result = pcall(function() return instance:getSize() end)
  print("FileHandle:getSize ->", ok, result)
end

--@api-stub: FileHandle:getMode
-- Returns the access mode the file was opened with.
-- Call when you need to read mode.
-- Build a FileHandle via the appropriate lurek.filesystem.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.filesystem.newFileHandle(...)
if instance then
  local ok, result = pcall(function() return instance:getMode() end)
  print("FileHandle:getMode ->", ok, result)
end

--@api-stub: FileHandle:flush
-- Flushes all buffered writes to disk without closing the handle.
-- Call when you need to invoke flush.
-- Build a FileHandle via the appropriate lurek.filesystem.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.filesystem.newFileHandle(...)
if instance then
  local ok, result = pcall(function() return instance:flush() end)
  print("FileHandle:flush ->", ok, result)
end

--@api-stub: FileHandle:close
-- Flushes any pending writes and closes the file handle.
-- Call when you need to invoke close.
-- Build a FileHandle via the appropriate lurek.filesystem.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.filesystem.newFileHandle(...)
if instance then
  local ok, result = pcall(function() return instance:close() end)
  print("FileHandle:close ->", ok, result)
end

--@api-stub: FileHandle:isEOF
-- Returns whether the read cursor has reached the end of the file.
-- Call when you need to check is e o f.
-- Build a FileHandle via the appropriate lurek.filesystem.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.filesystem.newFileHandle(...)
if instance then
  local ok, result = pcall(function() return instance:isEOF() end)
  print("FileHandle:isEOF ->", ok, result)
end

-- ── ZipMount methods ──

--@api-stub: ZipMount:readFile
-- Reads a file from the ZIP and returns it as a string of bytes.
-- Call when you need to invoke read file.
-- Build a ZipMount via the appropriate lurek.filesystem.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.filesystem.newZipMount(...)
if instance then
  local ok, result = pcall(function() return instance:readFile("save/example.txt") end)
  print("ZipMount:readFile ->", ok, result)
end

--@api-stub: ZipMount:contains
-- Returns true if `virtual_path` exists inside this ZIP mount.
-- Call when you need to invoke contains.
-- Build a ZipMount via the appropriate lurek.filesystem.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.filesystem.newZipMount(...)
if instance then
  local ok, result = pcall(function() return instance:contains("save/example.txt") end)
  print("ZipMount:contains ->", ok, result)
end

--@api-stub: ZipMount:listFiles
-- Returns a sorted array of all virtual paths exposed by this ZIP mount.
-- Call when you need to invoke list files.
-- Build a ZipMount via the appropriate lurek.filesystem.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.filesystem.newZipMount(...)
if instance then
  local ok, result = pcall(function() return instance:listFiles() end)
  print("ZipMount:listFiles ->", ok, result)
end

--@api-stub: ZipMount:prefix
-- Returns the virtual path prefix this archive was mounted under.
-- Call when you need to invoke prefix.
-- Build a ZipMount via the appropriate lurek.filesystem.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.filesystem.newZipMount(...)
if instance then
  local ok, result = pcall(function() return instance:prefix() end)
  print("ZipMount:prefix ->", ok, result)
end

