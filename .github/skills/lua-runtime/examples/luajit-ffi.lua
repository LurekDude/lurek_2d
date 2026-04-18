local ffi = require("ffi")

ffi.cdef[[
    typedef unsigned char uint8_t;
    void memset(void *b, int c, size_t len);
]]

-- Use with cdata pointers — do NOT pass to non-ffi Lua code
local buf = ffi.new("uint8_t[?]", 1024)
ffi.C.memset(buf, 0, 1024)
