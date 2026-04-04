import json, re
data = json.loads(open('docs/API/api_data.json', encoding='utf-8').read())
mods = data['lua_api']['modules']
# Find params_doc that has explicit type (backtick-typed like `string`, `number`, `boolean`, `Vec2`)
TYPES = re.compile(r'`(string|number|boolean|integer|table|Vec2|Vec3|Rect|[A-Z][A-Za-z0-9]+)`')
found = 0
for mod_name, mod in mods.items():
    for fn in mod.get('functions', []) + [m for cls in mod.get('classes',{}).values() for m in cls.get('methods',[])]:
        pd = fn.get('params_doc', '')
        if pd and TYPES.search(pd):
            print(mod_name + '.' + fn['name'] + ':')
            print('  params_doc:', repr(pd[:150]))
            print('  sig:', fn.get('inferred_sig',''))
            found += 1
            if found >= 10: break
    if found >= 10: break
