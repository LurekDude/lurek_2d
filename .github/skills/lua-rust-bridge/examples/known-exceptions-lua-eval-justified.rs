// LUA-EVAL-JUSTIFIED: <one-sentence reason why lua.load() is unavoidable here>
let result = lua.load(code).eval::<LuaMultiValue>()?;
