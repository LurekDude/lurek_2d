with open('src/lua_api/audio_api.rs', 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace('audio_mixer.add_bus(&name, parent_key);', 'audio_mixer.new_bus(&name);\n            // ignoring parent_key for now as new_bus only takes name')
c = c.replace('fx.frequency.set(value)', 'fx.p1.set(value)')
c = c.replace('fx.q.set(value)', 'fx.p2.set(value)')
c = c.replace('fx.mix.set(value)', 'fx.p3.set(value)')

with open('src/lua_api/audio_api.rs', 'w', encoding='utf-8') as f:
    f.write(c)

print("done")
