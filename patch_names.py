with open('src/lua_api/audio_api.rs', 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace('luna.set(\n        "create_bus",', 'audio.set(\n        "create_bus",')
c = c.replace('luna.set(\n        "add_effect",', 'audio.set(\n        "add_effect",')
c = c.replace('luna.set(\n        "remove_effect",', 'audio.set(\n        "remove_effect",')
c = c.replace('luna.set(\n        "set_effect_param",', 'audio.set(\n        "set_effect_param",')

with open('src/lua_api/audio_api.rs', 'w', encoding='utf-8') as f:
    f.write(c)

print("done")
