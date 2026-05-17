from pathlib import Path

p = Path('src/lua_api/math_api.rs')
text = p.read_text(encoding='utf-8')

pairs = [
    (
        'result points (x1,y1,x2,y2,...).\\n        lua.create_function(|lua, (a, b): (LuaTable, LuaTable)| {\\n            let va = lua_table_to_poly(a)?;\\n            let vb = lua_table_to_poly(b)?;\\n            let result = polygon::polygon_intersection',
        'result points (x1,y1,x2,y2,...).\\n    tbl.set(\\n        "polygonIntersection",\\n        lua.create_function(|lua, (a, b): (LuaTable, LuaTable)| {\\n            let va = lua_table_to_poly(a)?;\\n            let vb = lua_table_to_poly(b)?;\\n            let result = polygon::polygon_intersection',
    ),
    (
        'result points (x1,y1,x2,y2,...).\\n        lua.create_function(|lua, (a, b): (LuaTable, LuaTable)| {\\n            let va = lua_table_to_poly(a)?;\\n            let vb = lua_table_to_poly(b)?;\\n            let result = polygon::polygon_union',
        'result points (x1,y1,x2,y2,...).\\n    tbl.set(\\n        "polygonUnion",\\n        lua.create_function(|lua, (a, b): (LuaTable, LuaTable)| {\\n            let va = lua_table_to_poly(a)?;\\n            let vb = lua_table_to_poly(b)?;\\n            let result = polygon::polygon_union',
    ),
    (
        'result points (x1,y1,x2,y2,...).\\n        lua.create_function(|lua, (a, b): (LuaTable, LuaTable)| {\\n            let va = lua_table_to_poly(a)?;\\n            let vb = lua_table_to_poly(b)?;\\n            let result = polygon::polygon_difference',
        'result points (x1,y1,x2,y2,...).\\n    tbl.set(\\n        "polygonDifference",\\n        lua.create_function(|lua, (a, b): (LuaTable, LuaTable)| {\\n            let va = lua_table_to_poly(a)?;\\n            let vb = lua_table_to_poly(b)?;\\n            let result = polygon::polygon_difference',
    ),
]

for old_escaped, new_escaped in pairs:
    old = old_escaped.encode().decode('unicode_escape')
    new = new_escaped.encode().decode('unicode_escape')
    if old in text:
        text = text.replace(old, new)
        print(f'Fixed: {old[:60]}')
    else:
        print(f'NOT FOUND: {old[:60]}')

p.write_text(text, encoding='utf-8')
print('Done')
