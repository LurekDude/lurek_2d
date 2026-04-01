-- equivalent Rust: lua.globals().set("require", LuaNil)?;
require   = nil
load      = nil
dofile    = nil
loadfile  = nil
os        = nil   -- belt-and-suspenders if StdLib::OS was ever added
io        = nil
debug     = nil
package   = nil
