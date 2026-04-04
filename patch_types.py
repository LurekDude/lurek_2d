with open('src/lua_api/audio_api.rs', 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace('s.app.audio.mixer', 's.mixer')
c = c.replace('effect_type,', 'typ: effect_type,')
c = c.replace('frequency:', 'p1:')
c = c.replace('q:', 'p2:')
c = c.replace('mix:', 'p3:')
c = c.replace('effect_id): (String, usize)|', 'effect_id): (String, u32)|')
c = c.replace('effect_id, param_name, value): (String, usize, String, f32)|', 'effect_id, param_name, value): (String, u32, String, f32)|')
c = c.replace('eid = fx_list.len() + 1', 'eid = (fx_list.len() + 1) as u32')

# Replace the string matched values properly
c = c.replace('"frequency" => fx.p1.set(value),', '"p1" => fx.p1.set(value),')
c = c.replace('"q" => fx.p2.set(value),', '"p2" => fx.p2.set(value),')
c = c.replace('"mix" => fx.p3.set(value),', '"p3" => fx.p3.set(value),')

with open('src/lua_api/audio_api.rs', 'w', encoding='utf-8') as f:
    f.write(c)
print("done")
