"""Fix LuaDrawLayer add_methods lifetime."""
with open('src/lua_api/graphics_api.rs', 'r', encoding='utf-8') as f:
    content = f.read()

old = 'fn add_methods<M: LuaUserDataMethods<Self>>(methods: &mut M) {'
new = "fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {"
print('found:', old in content)
content = content.replace(old, new)

with open('src/lua_api/graphics_api.rs', 'w', encoding='utf-8') as f:
    f.write(content)
print('done')
