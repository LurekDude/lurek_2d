with open('src/lua_api/audio_api.rs', 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace('    Ok(())\n}', '    luna.set("audio", audio)?;\n    Ok(())\n}')

with open('src/lua_api/audio_api.rs', 'w', encoding='utf-8') as f:
    f.write(c)

print("done")
