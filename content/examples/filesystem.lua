-- content/examples/filesystem.lua
-- Scaffolded coverage of the lurek.filesystem API (54 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/filesystem_api.rs   (Lua binding, arg types, return shape)
--   * src/filesystem/                 (semantics, side effects)
--   * docs/specs/filesystem.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/filesystem.lua

-- ── lurek.filesystem.* functions ──

--@api-stub: lurek.filesystem.mountZip
-- Mounts a ZIP archive at a virtual path prefix, making its contents readable.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.mountZip
  local _todo = "TODO: write a real lurek.filesystem.mountZip usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.watchPath
-- Adds `path` to the polled file-watch list.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.watchPath
  local _todo = "TODO: write a real lurek.filesystem.watchPath usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.unwatchPath
-- Removes `path` from the polled file-watch list.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.unwatchPath
  local _todo = "TODO: write a real lurek.filesystem.unwatchPath usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.pollWatchers
-- Polls all watched paths and returns an array of paths that changed since the.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.pollWatchers
  local _todo = "TODO: write a real lurek.filesystem.pollWatchers usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.read
-- Reads a text file and returns its contents as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.read
  local _todo = "TODO: write a real lurek.filesystem.read usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.write
-- Writes a string to a file in the save directory.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.write
  local _todo = "TODO: write a real lurek.filesystem.write usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.exists
-- Returns whether the given file or directory exists.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.exists
  local _todo = "TODO: write a real lurek.filesystem.exists usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.append
-- Opens the file in append mode and writes the given string at the end.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.append
  local _todo = "TODO: write a real lurek.filesystem.append usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.openFile
-- Opens a file and returns a readable/writable file handle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.openFile
  local _todo = "TODO: write a real lurek.filesystem.openFile usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.getDirectoryItems
-- Returns a table containing the names of every file and subdirectory in the given path.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.getDirectoryItems
  local _todo = "TODO: write a real lurek.filesystem.getDirectoryItems usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.isFile
-- Returns whether the given path is a regular file.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.isFile
  local _todo = "TODO: write a real lurek.filesystem.isFile usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.isDirectory
-- Returns whether the given path is a directory.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.isDirectory
  local _todo = "TODO: write a real lurek.filesystem.isDirectory usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.createDirectory
-- Creates a directory and any missing parent directories in the save area.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.createDirectory
  local _todo = "TODO: write a real lurek.filesystem.createDirectory usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.remove
-- Permanently deletes a file or empty directory from the save directory.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.remove
  local _todo = "TODO: write a real lurek.filesystem.remove usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.getInfo
-- Returns a table of metadata for a path, or nil if the path does not exist.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.getInfo
  local _todo = "TODO: write a real lurek.filesystem.getInfo usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.getSource
-- Returns the absolute path of the directory the game was loaded from.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.getSource
  local _todo = "TODO: write a real lurek.filesystem.getSource usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.getSaveDirectory
-- Returns the sandboxed save data directory path.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.getSaveDirectory
  local _todo = "TODO: write a real lurek.filesystem.getSaveDirectory usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.getWorkingDirectory
-- Returns the current working directory path.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.getWorkingDirectory
  local _todo = "TODO: write a real lurek.filesystem.getWorkingDirectory usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.getUserDirectory
-- Returns the current user's home directory path.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.getUserDirectory
  local _todo = "TODO: write a real lurek.filesystem.getUserDirectory usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.getIdentity
-- Returns the identity string used to locate the game's save directory.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.getIdentity
  local _todo = "TODO: write a real lurek.filesystem.getIdentity usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.setIdentity
-- Sets the identity string that names the game's sandboxed save-data directory.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.setIdentity
  local _todo = "TODO: write a real lurek.filesystem.setIdentity usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.lines
-- Returns an iterator function over the lines of a text file.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.lines
  local _todo = "TODO: write a real lurek.filesystem.lines usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.readAsync
-- Starts loading a file in the background and returns an opaque handle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.readAsync
  local _todo = "TODO: write a real lurek.filesystem.readAsync usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.pollAsync
-- Polls an async load handle, returning status and optional data.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.pollAsync
  local _todo = "TODO: write a real lurek.filesystem.pollAsync usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.mount
-- Mounts a directory at a virtual path inside the game filesystem.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.mount
  local _todo = "TODO: write a real lurek.filesystem.mount usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.unmount
-- Removes a virtual mount layer by mountpoint.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.unmount
  local _todo = "TODO: write a real lurek.filesystem.unmount usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.load
-- Loads and compiles a Lua file from the VFS, returning it as a callable function.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.load
  local _todo = "TODO: write a real lurek.filesystem.load usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.newFileData
-- Loads a file from the VFS into a FileData buffer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.newFileData
  local _todo = "TODO: write a real lurek.filesystem.newFileData usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.copy
-- Copies a file within the sandbox.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.copy
  local _todo = "TODO: write a real lurek.filesystem.copy usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.move
-- Moves (renames) a file within the `save/` directory.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.move
  local _todo = "TODO: write a real lurek.filesystem.move usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.removeDir
-- Recursively deletes a directory and all its contents within `save/`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.removeDir
  local _todo = "TODO: write a real lurek.filesystem.removeDir usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.glob
-- Returns a sorted list of paths matching a simple wildcard pattern.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.glob
  local _todo = "TODO: write a real lurek.filesystem.glob usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.listRecursive
-- Returns a sorted list of all files under `path`, recursively.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.listRecursive
  local _todo = "TODO: write a real lurek.filesystem.listRecursive usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.stat
-- Returns lightweight file statistics for the given path.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.stat
  local _todo = "TODO: write a real lurek.filesystem.stat usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.createTempFile
-- Creates an empty temporary file in the `save/` sandbox and returns its.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.createTempFile
  local _todo = "TODO: write a real lurek.filesystem.createTempFile usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.mkdir
-- Creates a directory (and any missing parents) relative to the game root.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.mkdir
  local _todo = "TODO: write a real lurek.filesystem.mkdir usage example"
  print(_todo)
end

--@api-stub: lurek.filesystem.toAbsolutePath
-- Resolves a path relative to the game root to an absolute OS path string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: lurek.filesystem.toAbsolutePath
  local _todo = "TODO: write a real lurek.filesystem.toAbsolutePath usage example"
  print(_todo)
end

-- ── FileData methods ──

--@api-stub: FileData:getSize
-- Returns the file size in bytes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: FileData:getSize
  local _todo = "TODO: write a real FileData:getSize usage example"
  print(_todo)
end

--@api-stub: FileData:getString
-- Returns the file content as a Lua string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: FileData:getString
  local _todo = "TODO: write a real FileData:getString usage example"
  print(_todo)
end

--@api-stub: FileData:getFilename
-- Returns the virtual path this data was loaded from.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: FileData:getFilename
  local _todo = "TODO: write a real FileData:getFilename usage example"
  print(_todo)
end

-- ── FileHandle methods ──

--@api-stub: FileHandle:read
-- Reads bytes from the file, returning them as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: FileHandle:read
  local _todo = "TODO: write a real FileHandle:read usage example"
  print(_todo)
end

--@api-stub: FileHandle:readLine
-- Reads the next line from the file without the trailing newline.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: FileHandle:readLine
  local _todo = "TODO: write a real FileHandle:readLine usage example"
  print(_todo)
end

--@api-stub: FileHandle:write
-- Writes a string to the file and returns the number of bytes written.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: FileHandle:write
  local _todo = "TODO: write a real FileHandle:write usage example"
  print(_todo)
end

--@api-stub: FileHandle:seek
-- Seeks the file position to the given byte offset from the start.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: FileHandle:seek
  local _todo = "TODO: write a real FileHandle:seek usage example"
  print(_todo)
end

--@api-stub: FileHandle:tell
-- Returns the current read/write byte offset from the start of the file.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: FileHandle:tell
  local _todo = "TODO: write a real FileHandle:tell usage example"
  print(_todo)
end

--@api-stub: FileHandle:getSize
-- Returns the size of the open file in bytes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: FileHandle:getSize
  local _todo = "TODO: write a real FileHandle:getSize usage example"
  print(_todo)
end

--@api-stub: FileHandle:getMode
-- Returns the access mode the file was opened with.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: FileHandle:getMode
  local _todo = "TODO: write a real FileHandle:getMode usage example"
  print(_todo)
end

--@api-stub: FileHandle:flush
-- Flushes all buffered writes to disk without closing the handle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: FileHandle:flush
  local _todo = "TODO: write a real FileHandle:flush usage example"
  print(_todo)
end

--@api-stub: FileHandle:close
-- Flushes any pending writes and closes the file handle.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: FileHandle:close
  local _todo = "TODO: write a real FileHandle:close usage example"
  print(_todo)
end

--@api-stub: FileHandle:isEOF
-- Returns whether the read cursor has reached the end of the file.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: FileHandle:isEOF
  local _todo = "TODO: write a real FileHandle:isEOF usage example"
  print(_todo)
end

-- ── ZipMount methods ──

--@api-stub: ZipMount:readFile
-- Reads a file from the ZIP and returns it as a string of bytes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: ZipMount:readFile
  local _todo = "TODO: write a real ZipMount:readFile usage example"
  print(_todo)
end

--@api-stub: ZipMount:contains
-- Returns true if `virtual_path` exists inside this ZIP mount.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: ZipMount:contains
  local _todo = "TODO: write a real ZipMount:contains usage example"
  print(_todo)
end

--@api-stub: ZipMount:listFiles
-- Returns a sorted array of all virtual paths exposed by this ZIP mount.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: ZipMount:listFiles
  local _todo = "TODO: write a real ZipMount:listFiles usage example"
  print(_todo)
end

--@api-stub: ZipMount:prefix
-- Returns the virtual path prefix this archive was mounted under.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/filesystem_api.rs and docs/specs/filesystem.md).
do  -- TODO: ZipMount:prefix
  local _todo = "TODO: write a real ZipMount:prefix usage example"
  print(_todo)
end

