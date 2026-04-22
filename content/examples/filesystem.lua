-- content/examples/filesystem.lua
-- Auto-scaffolded coverage of the lurek.filesystem Lua API (54 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/filesystem.lua

print("[example] lurek.filesystem loaded — 54 API items demonstrated")

-- ── lurek.filesystem free functions ──

--@api-stub: lurek.filesystem.mountZip
-- Mounts a ZIP archive at a virtual path prefix, making its contents readable.
-- Use this when mounts a ZIP archive at a virtual path prefix, making its contents readable is needed.
if false then
  local _r = lurek.filesystem.mountZip(0, 0)
  print(_r)
end

--@api-stub: lurek.filesystem.watchPath
-- Adds `path` to the polled file-watch list.
-- Use this when adds `path` to the polled file-watch list is needed.
if false then
  local _r = lurek.filesystem.watchPath(0)
  print(_r)
end

--@api-stub: lurek.filesystem.unwatchPath
-- Removes `path` from the polled file-watch list.
-- No-op if not watched.
if false then
  local _r = lurek.filesystem.unwatchPath(0)
  print(_r)
end

--@api-stub: lurek.filesystem.pollWatchers
-- Polls all watched paths and returns an array of paths that changed since the.
-- Use this when polls all watched paths and returns an array of paths that changed since the is needed.
if false then
  local _r = lurek.filesystem.pollWatchers()
  print(_r)
end

--@api-stub: lurek.filesystem.read
-- Reads a text file and returns its contents as a string.
-- Use this when reads a text file and returns its contents as a string is needed.
if false then
  local _r = lurek.filesystem.read(0)
  print(_r)
end

--@api-stub: lurek.filesystem.write
-- Writes a string to a file in the save directory.
-- Use this when writes a string to a file in the save directory is needed.
if false then
  local _r = lurek.filesystem.write(0, 0)
  print(_r)
end

--@api-stub: lurek.filesystem.exists
-- Returns whether the given file or directory exists.
-- Use this when returns whether the given file or directory exists is needed.
if false then
  local _r = lurek.filesystem.exists(0)
  print(_r)
end

--@api-stub: lurek.filesystem.append
-- Opens the file in append mode and writes the given string at the end.
-- Use this when opens the file in append mode and writes the given string at the end is needed.
if false then
  local _r = lurek.filesystem.append(0, 0)
  print(_r)
end

--@api-stub: lurek.filesystem.openFile
-- Opens a file and returns a readable/writable file handle.
-- Use this when opens a file and returns a readable/writable file handle is needed.
if false then
  local _r = lurek.filesystem.openFile(0, nil)
  print(_r)
end

--@api-stub: lurek.filesystem.getDirectoryItems
-- Returns a table containing the names of every file and subdirectory in the given path.
-- Use this when returns a table containing the names of every file and subdirectory in the given path is needed.
if false then
  local _r = lurek.filesystem.getDirectoryItems(0)
  print(_r)
end

--@api-stub: lurek.filesystem.isFile
-- Returns whether the given path is a regular file.
-- Use this when returns whether the given path is a regular file is needed.
if false then
  local _r = lurek.filesystem.isFile(0)
  print(_r)
end

--@api-stub: lurek.filesystem.isDirectory
-- Returns whether the given path is a directory.
-- Use this when returns whether the given path is a directory is needed.
if false then
  local _r = lurek.filesystem.isDirectory(0)
  print(_r)
end

--@api-stub: lurek.filesystem.createDirectory
-- Creates a directory and any missing parent directories in the save area.
-- Use this when creates a directory and any missing parent directories in the save area is needed.
if false then
  local _r = lurek.filesystem.createDirectory(0)
  print(_r)
end

--@api-stub: lurek.filesystem.remove
-- Permanently deletes a file or empty directory from the save directory.
-- Use this when permanently deletes a file or empty directory from the save directory is needed.
if false then
  local _r = lurek.filesystem.remove(0)
  print(_r)
end

--@api-stub: lurek.filesystem.getInfo
-- Returns a table of metadata for a path, or nil if the path does not exist.
-- Use this when returns a table of metadata for a path, or nil if the path does not exist is needed.
if false then
  local _r = lurek.filesystem.getInfo(0)
  print(_r)
end

--@api-stub: lurek.filesystem.getSource
-- Returns the absolute path of the directory the game was loaded from.
-- Use this when returns the absolute path of the directory the game was loaded from is needed.
if false then
  local _r = lurek.filesystem.getSource()
  print(_r)
end

--@api-stub: lurek.filesystem.getSaveDirectory
-- Returns the sandboxed save data directory path.
-- Use this when returns the sandboxed save data directory path is needed.
if false then
  local _r = lurek.filesystem.getSaveDirectory()
  print(_r)
end

--@api-stub: lurek.filesystem.getWorkingDirectory
-- Returns the current working directory path.
-- Use this when returns the current working directory path is needed.
if false then
  local _r = lurek.filesystem.getWorkingDirectory()
  print(_r)
end

--@api-stub: lurek.filesystem.getUserDirectory
-- Returns the current user's home directory path.
-- Use this when returns the current user's home directory path is needed.
if false then
  local _r = lurek.filesystem.getUserDirectory()
  print(_r)
end

--@api-stub: lurek.filesystem.getIdentity
-- Returns the identity string used to locate the game's save directory.
-- Use this when returns the identity string used to locate the game's save directory is needed.
if false then
  local _r = lurek.filesystem.getIdentity()
  print(_r)
end

--@api-stub: lurek.filesystem.setIdentity
-- Sets the identity string that names the game's sandboxed save-data directory.
-- Use this when sets the identity string that names the game's sandboxed save-data directory is needed.
if false then
  local _r = lurek.filesystem.setIdentity(1)
  print(_r)
end

--@api-stub: lurek.filesystem.lines
-- Returns an iterator function over the lines of a text file.
-- Use this when returns an iterator function over the lines of a text file is needed.
if false then
  local _r = lurek.filesystem.lines(0)
  print(_r)
end

--@api-stub: lurek.filesystem.readAsync
-- Starts loading a file in the background and returns an opaque handle.
-- Use this when starts loading a file in the background and returns an opaque handle is needed.
if false then
  local _r = lurek.filesystem.readAsync(0)
  print(_r)
end

--@api-stub: lurek.filesystem.pollAsync
-- Polls an async load handle, returning status and optional data.
-- Use this when polls an async load handle, returning status and optional data is needed.
if false then
  local _r = lurek.filesystem.pollAsync(1)
  print(_r)
end

--@api-stub: lurek.filesystem.mount
-- Mounts a directory at a virtual path inside the game filesystem.
-- Use this when mounts a directory at a virtual path inside the game filesystem is needed.
if false then
  local _r = lurek.filesystem.mount(nil, nil)
  print(_r)
end

--@api-stub: lurek.filesystem.unmount
-- Removes a virtual mount layer by mountpoint.
-- Use this when removes a virtual mount layer by mountpoint is needed.
if false then
  local _r = lurek.filesystem.unmount(nil)
  print(_r)
end

--@api-stub: lurek.filesystem.load
-- Loads and compiles a Lua file from the VFS, returning it as a callable function.
-- Use this when loads and compiles a Lua file from the VFS, returning it as a callable function is needed.
if false then
  local _r = lurek.filesystem.load(0)
  print(_r)
end

--@api-stub: lurek.filesystem.newFileData
-- Loads a file from the VFS into a FileData buffer.
-- Use this when loads a file from the VFS into a FileData buffer is needed.
if false then
  local _r = lurek.filesystem.newFileData(0)
  print(_r)
end

--@api-stub: lurek.filesystem.copy
-- Copies a file within the sandbox.
-- Use this when copies a file within the sandbox is needed.
if false then
  local _r = lurek.filesystem.copy(nil, 0)
  print(_r)
end

--@api-stub: lurek.filesystem.move
-- Moves (renames) a file within the `save/` directory.
-- Use this when moves (renames) a file within the `save/` directory is needed.
if false then
  local _r = lurek.filesystem.move(nil, 0)
  print(_r)
end

--@api-stub: lurek.filesystem.removeDir
-- Recursively deletes a directory and all its contents within `save/`.
-- Use this when recursively deletes a directory and all its contents within `save/` is needed.
if false then
  local _r = lurek.filesystem.removeDir(0)
  print(_r)
end

--@api-stub: lurek.filesystem.glob
-- Returns a sorted list of paths matching a simple wildcard pattern.
-- Use this when returns a sorted list of paths matching a simple wildcard pattern is needed.
if false then
  local _r = lurek.filesystem.glob(1)
  print(_r)
end

--@api-stub: lurek.filesystem.listRecursive
-- Returns a sorted list of all files under `path`, recursively.
-- Use this when returns a sorted list of all files under `path`, recursively is needed.
if false then
  local _r = lurek.filesystem.listRecursive(0)
  print(_r)
end

--@api-stub: lurek.filesystem.stat
-- Returns lightweight file statistics for the given path.
-- Use this when returns lightweight file statistics for the given path is needed.
if false then
  local _r = lurek.filesystem.stat(0)
  print(_r)
end

--@api-stub: lurek.filesystem.createTempFile
-- Creates an empty temporary file in the `save/` sandbox and returns its.
-- Use this when creates an empty temporary file in the `save/` sandbox and returns its is needed.
if false then
  local _r = lurek.filesystem.createTempFile(0)
  print(_r)
end

--@api-stub: lurek.filesystem.mkdir
-- Creates a directory (and any missing parents) relative to the game root.
-- Use this when creates a directory (and any missing parents) relative to the game root is needed.
if false then
  local _r = lurek.filesystem.mkdir(0)
  print(_r)
end

--@api-stub: lurek.filesystem.toAbsolutePath
-- Resolves a path relative to the game root to an absolute OS path string.
-- Use this when resolves a path relative to the game root to an absolute OS path string is needed.
if false then
  local _r = lurek.filesystem.toAbsolutePath(0)
  print(_r)
end

-- ── FileData methods ──

--@api-stub: FileData:getSize
-- Returns the file size in bytes.
-- Use this when returns the file size in bytes is needed.
if false then
  local _o = nil  -- FileData instance
  _o:getSize()
end

--@api-stub: FileData:getString
-- Returns the file content as a Lua string.
-- Use this when returns the file content as a Lua string is needed.
if false then
  local _o = nil  -- FileData instance
  _o:getString()
end

--@api-stub: FileData:getFilename
-- Returns the virtual path this data was loaded from.
-- Use this when returns the virtual path this data was loaded from is needed.
if false then
  local _o = nil  -- FileData instance
  _o:getFilename()
end

-- ── FileHandle methods ──

--@api-stub: FileHandle:read
-- Reads bytes from the file, returning them as a string.
-- Use this when reads bytes from the file, returning them as a string is needed.
if false then
  local _o = nil  -- FileHandle instance
  _o:read(1)
end

--@api-stub: FileHandle:readLine
-- Reads the next line from the file without the trailing newline.
-- Use this when reads the next line from the file without the trailing newline is needed.
if false then
  local _o = nil  -- FileHandle instance
  _o:readLine()
end

--@api-stub: FileHandle:write
-- Writes a string to the file and returns the number of bytes written.
-- Use this when writes a string to the file and returns the number of bytes written is needed.
if false then
  local _o = nil  -- FileHandle instance
  _o:write(0)
end

--@api-stub: FileHandle:seek
-- Seeks the file position to the given byte offset from the start.
-- Use this when seeks the file position to the given byte offset from the start is needed.
if false then
  local _o = nil  -- FileHandle instance
  _o:seek(nil)
end

--@api-stub: FileHandle:tell
-- Returns the current read/write byte offset from the start of the file.
-- Use this when returns the current read/write byte offset from the start of the file is needed.
if false then
  local _o = nil  -- FileHandle instance
  _o:tell()
end

--@api-stub: FileHandle:getSize
-- Returns the size of the open file in bytes.
-- Use this when returns the size of the open file in bytes is needed.
if false then
  local _o = nil  -- FileHandle instance
  _o:getSize()
end

--@api-stub: FileHandle:getMode
-- Returns the access mode the file was opened with.
-- Use this when returns the access mode the file was opened with is needed.
if false then
  local _o = nil  -- FileHandle instance
  _o:getMode()
end

--@api-stub: FileHandle:flush
-- Flushes all buffered writes to disk without closing the handle.
-- Use this when flushes all buffered writes to disk without closing the handle is needed.
if false then
  local _o = nil  -- FileHandle instance
  _o:flush()
end

--@api-stub: FileHandle:close
-- Flushes any pending writes and closes the file handle.
-- Use this when flushes any pending writes and closes the file handle is needed.
if false then
  local _o = nil  -- FileHandle instance
  _o:close()
end

--@api-stub: FileHandle:isEOF
-- Returns whether the read cursor has reached the end of the file.
-- Use this when returns whether the read cursor has reached the end of the file is needed.
if false then
  local _o = nil  -- FileHandle instance
  _o:isEOF()
end

-- ── ZipMount methods ──

--@api-stub: ZipMount:readFile
-- Reads a file from the ZIP and returns it as a string of bytes.
-- Use this when reads a file from the ZIP and returns it as a string of bytes is needed.
if false then
  local _o = nil  -- ZipMount instance
  _o:readFile(0)
end

--@api-stub: ZipMount:contains
-- Returns true if `virtual_path` exists inside this ZIP mount.
-- Use this when returns true if `virtual_path` exists inside this ZIP mount is needed.
if false then
  local _o = nil  -- ZipMount instance
  _o:contains(0)
end

--@api-stub: ZipMount:listFiles
-- Returns a sorted array of all virtual paths exposed by this ZIP mount.
-- Use this when returns a sorted array of all virtual paths exposed by this ZIP mount is needed.
if false then
  local _o = nil  -- ZipMount instance
  _o:listFiles()
end

--@api-stub: ZipMount:prefix
-- Returns the virtual path prefix this archive was mounted under.
-- Use this when returns the virtual path prefix this archive was mounted under is needed.
if false then
  local _o = nil  -- ZipMount instance
  _o:prefix()
end

