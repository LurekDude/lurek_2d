import sys

with open('src/lua_api/audio_api.rs', 'r', encoding='utf-8') as f:
    content = f.read()

# Add needed imports
content = content.replace(
    'use crate::engine::resource_keys::{BusKey, SoundKey};',
    'use crate::engine::resource_keys::{BusKey, SoundKey};\nuse crate::audio::dsp::{EffectType, EffectParams, AtomicParam};\nuse std::sync::Arc;'
)

bindings = """    let state_create_bus = Rc::clone(&state);
    luna_audio.set(
        "create_bus",
        lua.create_function(move |_, (name, parent_name): (String, Option<String>)| {
            let mut s = state_create_bus.borrow_mut();
            let audio_mixer = &mut s.app.audio.mixer;
            let parent_key = parent_name.and_then(|n| audio_mixer.get_bus_by_name(&n));
            let bus_key = audio_mixer.add_bus(&name, parent_key);
            Ok(bus_key.is_some())
        })?,
    )?;

    let state_add_effect = Rc::clone(&state);
    luna_audio.set(
        "add_effect",
        lua.create_function(move |_, (bus_name, effect_type_str, params): (String, String, Option<mlua::Table>)| {
            let s = state_add_effect.borrow();
            let audio_mixer = &s.app.audio.mixer;
            if let Some(bus_key) = audio_mixer.get_bus_by_name(&bus_name) {
                if let Some(bus) = audio_mixer.get_bus(bus_key) {
                    let effect_type = match effect_type_str.as_str() {
                        "lowpass" => EffectType::Lowpass,
                        "highpass" => EffectType::Highpass,
                        "bandpass" => EffectType::Bandpass,
                        "reverb" => EffectType::Reverb,
                        "chorus" => EffectType::Chorus,
                        _ => return Err(mlua::Error::external(format!("Unknown effect type: {}", effect_type_str))),
                    };

                    let mut effect_id = None;
                    if let Some(t) = params {
                        // We extract some optional params if provided
                        let param_value: Option<f32> = t.get("value").ok();
                        if let Some(v) = param_value {
                            let mut fx_list = bus.effects.write().unwrap();
                            let eid = fx_list.len() + 1; // dummy ID based on length
                            fx_list.push(Arc::new(EffectParams {
                                id: eid,
                                effect_type,
                                frequency: AtomicParam::new(v),
                                q: AtomicParam::new(1.0),
                                mix: AtomicParam::new(0.5),
                            }));
                            effect_id = Some(eid);
                        }
                    }
                    if effect_id.is_none() {
                        let mut fx_list = bus.effects.write().unwrap();
                        let eid = fx_list.len() + 1;
                        fx_list.push(Arc::new(EffectParams {
                            id: eid,
                            effect_type,
                            frequency: AtomicParam::new(1000.0),
                            q: AtomicParam::new(1.0),
                            mix: AtomicParam::new(0.5),
                        }));
                        effect_id = Some(eid);
                    }

                    return Ok(effect_id);
                }
            }
            Err(mlua::Error::external(format!("Bus not found: {}", bus_name)))
        })?,
    )?;

    let state_remove_effect = Rc::clone(&state);
    luna_audio.set(
        "remove_effect",
        lua.create_function(move |_, (bus_name, effect_id): (String, usize)| {
            let s = state_remove_effect.borrow();
            let audio_mixer = &s.app.audio.mixer;
            if let Some(bus_key) = audio_mixer.get_bus_by_name(&bus_name) {
                if let Some(bus) = audio_mixer.get_bus(bus_key) {
                    let mut fx_list = bus.effects.write().unwrap();
                    fx_list.retain(|fx| fx.id != effect_id);
                    return Ok(true);
                }
            }
            Err(mlua::Error::external(format!("Bus not found: {}", bus_name)))
        })?,
    )?;

    let state_set_effect_param = Rc::clone(&state);
    luna_audio.set(
        "set_effect_param",
        lua.create_function(move |_, (bus_name, effect_id, param_name, value): (String, usize, String, f32)| {
            let s = state_set_effect_param.borrow();
            let audio_mixer = &s.app.audio.mixer;
            if let Some(bus_key) = audio_mixer.get_bus_by_name(&bus_name) {
                if let Some(bus) = audio_mixer.get_bus(bus_key) {
                    let fx_list = bus.effects.read().unwrap();
                    if let Some(fx) = fx_list.iter().find(|fx| fx.id == effect_id) {
                        match param_name.as_str() {
                            "frequency" => fx.frequency.set(value),
                            "q" => fx.q.set(value),
                            "mix" => fx.mix.set(value),
                            _ => return Err(mlua::Error::external(format!("Unknown param: {}", param_name))),
                        }
                        return Ok(true);
                    }
                    return Err(mlua::Error::external(format!("Effect not found: {}", effect_id)));
                }
            }
            Err(mlua::Error::external(format!("Bus not found: {}", bus_name)))
        })?,
    )?;"""

content = content.replace('    Ok(())\n}', bindings + '\n    Ok(())\n}')

with open('src/lua_api/audio_api.rs', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated audio_api.rs")
