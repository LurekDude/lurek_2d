with open('src/lua_api/audio_api.rs', 'r', encoding='utf-8') as f:
    c = f.read()

# Swap the order
old_block = '    luna.set("audio", audio)?;\n    let state_create_bus = Rc::clone(&state);'
new_block = '    let state_create_bus = Rc::clone(&state);'
c = c.replace(old_block, new_block)

c = c.replace('    Ok(())\n}\n    Ok(())\n}', '    luna.set("audio", audio)?;\n    Ok(())\n}')

with open('src/lua_api/audio_api.rs', 'w', encoding='utf-8') as f:
    f.write(c)

print("done")
