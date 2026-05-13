use super::SharedState;
use crate::audio::sound_data::SoundData;
use crate::audio::{Decoder, MidiPlayer, SourceType};
use crate::log_msg;
use crate::runtime::log_messages::LA01_API_STUB;
use crate::runtime::resource_keys::{BusKey, QueueableKey, SoundKey};
use mlua::prelude::*;
use slotmap::Key;
use std::cell::RefCell;
use std::rc::Rc;
fn sound_key_from_value(val: &LuaValue) -> LuaResult<SoundKey> {
    match val {
        LuaValue::UserData(ud) => {
            let src = ud.borrow::<LuaSource>()?;
            Ok(src.key)
        }
        LuaValue::Integer(id) => Ok(SoundKey::from(slotmap::KeyData::from_ffi(*id as u64))),
        LuaValue::Number(id) => Ok(SoundKey::from(slotmap::KeyData::from_ffi(*id as u64))),
        _ => Err(LuaError::RuntimeError(
            "Expected Source or source id".into(),
        )),
    }
}
fn invalid_source_handle(function_name: &str) -> LuaError {
    LuaError::RuntimeError(format!(
        "{}: invalid or already-released audio source handle",
        function_name
    ))
}
fn ensure_source_exists(
    mixer: &crate::audio::Mixer,
    key: SoundKey,
    function_name: &str,
) -> LuaResult<SoundKey> {
    if mixer.contains_source(key) {
        Ok(key)
    } else {
        Err(invalid_source_handle(function_name))
    }
}
fn require_sound_key(
    state: &SharedState,
    val: &LuaValue,
    function_name: &str,
) -> LuaResult<SoundKey> {
    let key = sound_key_from_value(val)?;
    ensure_source_exists(&state.mixer, key, function_name)
}
fn queueable_key_from_u64(raw: u64) -> QueueableKey {
    QueueableKey::from(slotmap::KeyData::from_ffi(raw))
}
fn extract_sound_data_args(args: LuaMultiValue) -> LuaResult<(Option<String>, usize, u32, u16)> {
    let mut it = args.into_iter();
    let first = it
        .next()
        .ok_or_else(|| LuaError::RuntimeError("newSoundData: expected argument".into()))?;
    let (path, count) = match first {
        LuaValue::String(s) => (
            Some(
                s.to_str()
                    .map_err(|e| LuaError::RuntimeError(e.to_string()))?
                    .to_string(),
            ),
            0usize,
        ),
        LuaValue::Integer(n) => (None, n as usize),
        LuaValue::Number(n) => (None, n as usize),
        _ => {
            return Err(LuaError::RuntimeError(
                "newSoundData expects a filename or sample count".into(),
            ))
        }
    };
    let rate = match it.next() {
        Some(LuaValue::Integer(n)) => n as u32,
        Some(LuaValue::Number(n)) => n as u32,
        _ => {
            return Err(LuaError::RuntimeError(
                "newSoundData: sample rate must be a number (e.g. 44100, 48000)".into(),
            ))
        }
    };
    let channels = match it.next() {
        Some(LuaValue::Integer(n)) => n as u16,
        Some(LuaValue::Number(n)) => n as u16,
        _ => 1,
    };
    Ok((path, count, rate, channels))
}
#[derive(Clone)]
pub struct LuaSource {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: SoundKey,
}
impl LuaUserData for LuaSource {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("play", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:play")?;
            let game_dir = st.game_dir.clone();
            st.mixer.play(key, &game_dir);
            Ok(())
        });
        methods.add_method("stop", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:stop")?;
            st.mixer.stop(key);
            Ok(())
        });
        methods.add_method("pause", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:pause")?;
            st.mixer.pause(key);
            Ok(())
        });
        methods.add_method("resume", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:resume")?;
            st.mixer.resume(key);
            Ok(())
        });
        methods.add_method("setVolume", |_, this, vol: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setVolume")?;
            st.mixer.set_volume(key, vol);
            Ok(())
        });
        methods.add_method("getVolume", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getVolume")?;
            Ok(st.mixer.get_volume(key))
        });
        methods.add_method("setPitch", |_, this, pitch: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setPitch")?;
            st.mixer.set_pitch(key, pitch);
            Ok(())
        });
        methods.add_method("getPitch", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getPitch")?;
            Ok(st.mixer.get_pitch(key))
        });
        methods.add_method("setLooping", |_, this, looping: bool| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setLooping")?;
            st.mixer.set_looping(key, looping);
            Ok(())
        });
        methods.add_method("isLooping", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:isLooping")?;
            Ok(st.mixer.is_looping(key))
        });
        methods.add_method("isPlaying", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:isPlaying")?;
            Ok(st.mixer.is_playing(key))
        });
        methods.add_method("isPaused", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:isPaused")?;
            Ok(st.mixer.is_paused(key))
        });
        methods.add_method("isStopped", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:isStopped")?;
            Ok(st.mixer.is_stopped(key))
        });
        methods.add_method("setPan", |_, this, pan: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setPan")?;
            st.mixer.set_pan(key, pan);
            Ok(())
        });
        methods.add_method("getPan", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getPan")?;
            Ok(st.mixer.get_pan(key))
        });
        methods.add_method("clone", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            match st.mixer.clone_source(this.key) {
                Some(new_key) => Ok(LuaSource {
                    state: this.state.clone(),
                    key: new_key,
                }),
                None => Err(invalid_source_handle("Source:clone")),
            }
        });
        methods.add_method("getType", |_, this, ()| {
            let st = this.state.borrow();
            match st.mixer.get_source_type(this.key) {
                Some(SourceType::Static) => Ok("static"),
                Some(SourceType::Stream) => Ok("stream"),
                None => Err(invalid_source_handle("Source:getType")),
            }
        });
        methods.add_method("getDuration", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getDuration")?;
            Ok(st.mixer.get_duration(key))
        });
        methods.add_method("tell", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:tell")?;
            Ok(st.mixer.get_tell(key))
        });
        methods.add_method("seek", |_, this, pos: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:seek")?;
            let game_dir = st.game_dir.clone();
            st.mixer.seek(key, pos, &game_dir);
            Ok(())
        });
        methods.add_method("setLowpass", |_, this, cutoff_hz: u32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setLowpass")?;
            st.mixer.set_lowpass(key, cutoff_hz);
            Ok(())
        });
        methods.add_method("setHighpass", |_, this, cutoff_hz: u32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:setHighpass")?;
            st.mixer.set_highpass(key, cutoff_hz);
            Ok(())
        });
        methods.add_method("getLowpass", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getLowpass")?;
            Ok(st.mixer.get_lowpass(key))
        });
        methods.add_method("getHighpass", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getHighpass")?;
            Ok(st.mixer.get_highpass(key))
        });
        methods.add_method("clearFilter", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:clearFilter")?;
            st.mixer.clear_filter(key);
            Ok(())
        });
        methods.add_method("fadeIn", |_, this, dur: f32| {
            let mut st = this.state.borrow_mut();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:fadeIn")?;
            st.mixer.set_fade_in(key, dur);
            Ok(())
        });
        methods.add_method("getFadeIn", |_, this, ()| {
            let st = this.state.borrow();
            let key = ensure_source_exists(&st.mixer, this.key, "Source:getFadeIn")?;
            Ok(st.mixer.get_fade_in(key))
        });
        methods.add_method("type", |_, _, ()| Ok("LSource"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSource" || name == "Object")
        });
    }
}
#[derive(Clone)]
pub struct LuaBus {
    pub(crate) state: Rc<RefCell<SharedState>>,
    pub(crate) key: BusKey,
}
impl LuaUserData for LuaBus {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getName", |_, this, ()| {
            let st = this.state.borrow();
            match st.mixer.get_bus(this.key) {
                Some(bus) => Ok(bus.name().to_string()),
                None => Err(LuaError::RuntimeError(
                    "Bus:getName(): invalid bus handle".into(),
                )),
            }
        });
        methods.add_method("setVolume", |_, this, vol: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                bus.set_volume(vol);
            }
            Ok(())
        });
        methods.add_method("getVolume", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.mixer.get_bus(this.key).map_or(1.0, |b| b.volume()))
        });
        methods.add_method("setPitch", |_, this, pitch: f32| {
            let mut st = this.state.borrow_mut();
            if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                bus.set_pitch(pitch);
            }
            Ok(())
        });
        methods.add_method("getPitch", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.mixer.get_bus(this.key).map_or(1.0, |b| b.pitch()))
        });
        methods.add_method("pause", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                bus.pause();
            }
            Ok(())
        });
        methods.add_method("resume", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                bus.resume();
            }
            Ok(())
        });
        methods.add_method("isPaused", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.mixer.get_bus(this.key).is_some_and(|b| b.is_paused()))
        });
        methods.add_method("type", |_, _, ()| Ok("LBus"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LBus" || name == "Bus" || name == "Object")
        });
        methods.add_method(
            "setDuckTarget",
            |_, this, (target_name, duck_vol): (String, f32)| {
                let mut st = this.state.borrow_mut();
                if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                    bus.set_duck_target(&target_name, duck_vol);
                }
                Ok(())
            },
        );
        methods.add_method("clearDuck", |_, this, ()| {
            let mut st = this.state.borrow_mut();
            if let Some(bus) = st.mixer.get_bus_mut(this.key) {
                bus.clear_duck_target();
            }
            Ok(())
        });
        methods.add_method("getPeak", |_, this, ()| {
            let st = this.state.borrow();
            Ok(st.mixer.bus_peak(this.key))
        });
    }
}
#[derive(Clone)]
pub struct LuaMidiPlayer {
    pub(crate) inner: Rc<RefCell<MidiPlayer>>,
    pub(crate) state: Rc<RefCell<SharedState>>,
}
impl LuaUserData for LuaMidiPlayer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("load", |_, this, path: String| {
            let st = this.state.borrow();
            let full_path = st.game_dir.join(&path);
            Ok(this.inner.borrow_mut().load(&full_path))
        });
        methods.add_method("loadData", |_, this, data: mlua::String| {
            let bytes = data.as_bytes().to_vec();
            Ok(this.inner.borrow_mut().load_data(bytes))
        });
        methods.add_method("isLoaded", |_, this, ()| {
            Ok(this.inner.borrow().is_loaded())
        });
        methods.add_method("getFilePath", |_, this, ()| {
            Ok(this.inner.borrow().file_path().map(|s| s.to_string()))
        });
        methods.add_method("setSoundFont", |_, _this, _path: String| {
            log_msg!(debug, LA01_API_STUB, "MidiPlayer:setSoundFont");
            Ok(())
        });
        methods.add_method("getSoundFontPath", |_, _this, ()| {
            log_msg!(debug, LA01_API_STUB, "MidiPlayer:getSoundFontPath");
            Ok(Option::<String>::None)
        });
        methods.add_method("useDefaultSoundFont", |_, _this, ()| {
            log_msg!(debug, LA01_API_STUB, "MidiPlayer:useDefaultSoundFont");
            Ok(())
        });
        methods.add_method("play", |_, this, ()| {
            let st = this.state.borrow();
            if let Some(handle) = st.mixer.stream_handle() {
                this.inner.borrow_mut().play(handle);
            }
            Ok(())
        });
        methods.add_method("pause", |_, this, ()| {
            this.inner.borrow_mut().pause();
            Ok(())
        });
        methods.add_method("stop", |_, this, ()| {
            this.inner.borrow_mut().stop();
            Ok(())
        });
        methods.add_method("isPlaying", |_, this, ()| {
            Ok(this.inner.borrow().is_playing())
        });
        methods.add_method("isPaused", |_, this, ()| {
            Ok(this.inner.borrow().is_paused())
        });
        methods.add_method("seek", |_, this, secs: f64| {
            this.inner.borrow_mut().seek(secs);
            Ok(())
        });
        methods.add_method("tell", |_, this, ()| Ok(this.inner.borrow().tell()));
        methods.add_method("getDuration", |_, this, ()| {
            Ok(this.inner.borrow().duration())
        });
        methods.add_method("setLooping", |_, this, looping: bool| {
            this.inner.borrow_mut().set_looping(looping);
            Ok(())
        });
        methods.add_method("isLooping", |_, this, ()| {
            Ok(this.inner.borrow().is_looping())
        });
        methods.add_method("setVolume", |_, this, vol: f32| {
            this.inner.borrow_mut().set_volume(vol);
            Ok(())
        });
        methods.add_method("getVolume", |_, this, ()| Ok(this.inner.borrow().volume()));
        methods.add_method("setBus", |_, this, bus_val: LuaValue| match &bus_val {
            LuaValue::UserData(ud) => {
                let bus = ud.borrow::<LuaBus>()?;
                this.inner.borrow_mut().set_bus_key(Some(bus.key));
                Ok(())
            }
            LuaValue::Nil => {
                this.inner.borrow_mut().set_bus_key(None);
                Ok(())
            }
            _ => Err(LuaError::RuntimeError(
                "MidiPlayer:setBus(): expected Bus or nil".into(),
            )),
        });
        methods.add_method("getBus", |_, this, ()| {
            match this.inner.borrow().bus_key() {
                Some(key) => Ok(Some(LuaBus {
                    state: this.state.clone(),
                    key,
                })),
                None => Ok(None),
            }
        });
        methods.add_method("setTempo", |_, this, bpm: f64| {
            let original = this.inner.borrow().original_tempo();
            if original > 0.0 {
                this.inner
                    .borrow_mut()
                    .set_tempo_scale((bpm / original) as f32);
            }
            Ok(())
        });
        methods.add_method("getTempo", |_, this, ()| {
            let mp = this.inner.borrow();
            Ok(mp.original_tempo() * mp.tempo_scale() as f64)
        });
        methods.add_method("getOriginalTempo", |_, this, ()| {
            Ok(this.inner.borrow().original_tempo())
        });
        methods.add_method("setTempoScale", |_, this, scale: f32| {
            this.inner.borrow_mut().set_tempo_scale(scale);
            Ok(())
        });
        methods.add_method("getTempoScale", |_, this, ()| {
            Ok(this.inner.borrow().tempo_scale())
        });
        methods.add_method("getTicksPerBeat", |_, this, ()| {
            Ok(this.inner.borrow().ticks_per_beat())
        });
        methods.add_method("setChannelVolume", |_, this, (ch, vol): (usize, f32)| {
            if (1..=16).contains(&ch) {
                this.inner.borrow_mut().set_channel_volume(ch - 1, vol);
            }
            Ok(())
        });
        methods.add_method("getChannelVolume", |_, this, ch: usize| {
            if (1..=16).contains(&ch) {
                Ok(this.inner.borrow().channel_volume(ch - 1))
            } else {
                Ok(0.0)
            }
        });
        methods.add_method("setChannelMuted", |_, this, (ch, muted): (usize, bool)| {
            if (1..=16).contains(&ch) {
                this.inner.borrow_mut().set_channel_muted(ch - 1, muted);
            }
            Ok(())
        });
        methods.add_method("isChannelMuted", |_, this, ch: usize| {
            if (1..=16).contains(&ch) {
                Ok(this.inner.borrow().is_channel_muted(ch - 1))
            } else {
                Ok(false)
            }
        });
        methods.add_method(
            "setChannelInstrument",
            |_, this, (ch, inst): (usize, u8)| {
                if (1..=16).contains(&ch) {
                    this.inner.borrow_mut().set_channel_instrument(ch - 1, inst);
                }
                Ok(())
            },
        );
        methods.add_method("getChannelInstrument", |_, this, ch: usize| {
            if (1..=16).contains(&ch) {
                Ok(this.inner.borrow().channel_instrument(ch - 1))
            } else {
                Ok(0u8)
            }
        });
        methods.add_method("getChannelCount", |_, this, ()| {
            Ok(this.inner.borrow().channel_count())
        });
        methods.add_method("soloChannel", |_, this, ch: usize| {
            if (1..=16).contains(&ch) {
                this.inner.borrow_mut().solo_channel(ch - 1);
            }
            Ok(())
        });
        methods.add_method("unsoloAll", |_, this, ()| {
            this.inner.borrow_mut().unsolo_all();
            Ok(())
        });
        methods.add_method("getTrackCount", |_, this, ()| {
            Ok(this.inner.borrow().track_count())
        });
        methods.add_method("getTrackName", |_, this, idx: usize| {
            if idx >= 1 {
                Ok(this
                    .inner
                    .borrow()
                    .track_name(idx - 1)
                    .map(|s| s.to_string()))
            } else {
                Ok(None)
            }
        });
        methods.add_method("setTrackMuted", |_, this, (idx, muted): (usize, bool)| {
            if idx >= 1 {
                this.inner.borrow_mut().set_track_muted(idx - 1, muted);
            }
            Ok(())
        });
        methods.add_method("isTrackMuted", |_, this, idx: usize| {
            if idx >= 1 {
                Ok(this.inner.borrow().is_track_muted(idx - 1))
            } else {
                Ok(false)
            }
        });
        methods.add_method("getNoteCount", |_, this, ()| {
            Ok(this.inner.borrow().note_count())
        });
        methods.add_method("setOnNoteOn", |_, _this, _cb: LuaValue| {
            log_msg!(debug, LA01_API_STUB, "MidiPlayer:setOnNoteOn");
            Ok(())
        });
        methods.add_method("setOnNoteOff", |_, _this, _cb: LuaValue| {
            log_msg!(debug, LA01_API_STUB, "MidiPlayer:setOnNoteOff");
            Ok(())
        });
        methods.add_method("setOnEnd", |_, _this, _cb: LuaValue| {
            log_msg!(debug, LA01_API_STUB, "MidiPlayer:setOnEnd");
            Ok(())
        });
        methods.add_method("getSampleRate", |_, this, ()| {
            Ok(this.inner.borrow().get_output_sample_rate())
        });
        methods.add_method_mut("setSampleRate", |_, this, rate: u32| {
            this.inner.borrow_mut().set_output_sample_rate(rate);
            Ok(())
        });
        methods.add_method("getChannels", |_, this, ()| {
            Ok(this.inner.borrow().get_output_channels() as u32)
        });
        methods.add_method_mut("setChannels", |_, this, channels: u32| {
            this.inner.borrow_mut().set_output_channels(channels as u16);
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LMidiPlayer"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LMidiPlayer" || name == "MidiPlayer" || name == "Object")
        });
    }
}
pub(crate) struct LuaSoundPool {
    pub(crate) pool: crate::audio::pool::SoundPool,
    pub(crate) state: Rc<RefCell<SharedState>>,
}
impl LuaUserData for LuaSoundPool {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("play", |_, this, ()| {
            let key = this.pool.next_voice();
            let game_dir = this.state.borrow().game_dir.clone();
            this.state.borrow_mut().mixer.play(key, &game_dir);
            Ok(slotmap::Key::data(&key).as_ffi() as i64)
        });
        methods.add_method_mut("stopAll", |_, this, ()| {
            let keys: Vec<_> = this.pool.all_keys().to_vec();
            let mut st = this.state.borrow_mut();
            for key in keys {
                st.mixer.stop(key);
            }
            Ok(())
        });
        methods.add_method_mut("setVolume", |_, this, vol: f32| {
            this.pool.set_volume(vol);
            let keys: Vec<_> = this.pool.all_keys().to_vec();
            let mut st = this.state.borrow_mut();
            for key in keys {
                st.mixer.set_volume(key, vol);
            }
            Ok(())
        });
        methods.add_method_mut("setBus", |_, this, name: String| {
            this.pool.set_bus(&name);
            let keys: Vec<_> = this.pool.all_keys().to_vec();
            let bus_key = this.state.borrow().mixer.get_bus_by_name(&name);
            let mut st = this.state.borrow_mut();
            for key in keys {
                st.mixer.set_source_bus(key, bus_key);
            }
            Ok(())
        });
        methods.add_method_mut("release", |_, this, ()| {
            let keys: Vec<_> = this.pool.all_keys().to_vec();
            let mut st = this.state.borrow_mut();
            for key in keys {
                st.mixer.release(key);
            }
            Ok(())
        });
        methods.add_method("getVoiceCount", |_, this, ()| Ok(this.pool.voice_count()));
        methods.add_method("type", |_, _this, ()| Ok("LSoundPool"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "SoundPool" || name == "Object")
        });
    }
}
pub struct LuaDecoder {
    inner: Decoder,
}
impl LuaUserData for LuaDecoder {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("decode", |lua, this, ()| match this.inner.decode() {
            Some(pcm_i16) => {
                let samples: Vec<f32> = pcm_i16.iter().map(|&s| s as f32 / 32768.0).collect();
                let sd =
                    SoundData::from_samples(samples, this.inner.sample_rate, this.inner.channels);
                Ok(LuaValue::UserData(lua.create_userdata(sd)?))
            }
            None => Ok(LuaValue::Nil),
        });
        methods.add_method("getChannelCount", |_, this, ()| {
            Ok(this.inner.channels as u32)
        });
        methods.add_method("getBitDepth", |_, this, ()| Ok(this.inner.bit_depth as u32));
        methods.add_method("getSampleRate", |_, this, ()| Ok(this.inner.sample_rate));
        methods.add_method("getDuration", |_, this, ()| Ok(this.inner.get_duration()));
        methods.add_method_mut("seek", |_, this, offset: f64| {
            this.inner.seek(offset);
            Ok(())
        });
        methods.add_method_mut("rewind", |_, this, ()| {
            this.inner.rewind();
            Ok(())
        });
        methods.add_method("tell", |_, this, ()| Ok(this.inner.tell()));
        methods.add_method("isSeekable", |_, this, ()| Ok(this.inner.is_seekable()));
        methods.add_method("release", |_, _, ()| Ok(()));
        methods.add_method("type", |_, _, ()| Ok("LDecoder"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LDecoder" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    let s = state.clone();
    tbl.set(
        "newSource",
        lua.create_function(move |_, args: LuaMultiValue| {
            let path: String = args
                .get(0)
                .and_then(|v| match v {
                    LuaValue::String(ls) => Some(ls.to_str().ok()?.to_string()),
                    _ => None,
                })
                .ok_or_else(|| {
                    LuaError::RuntimeError("lurek.audio.newSource: path required".into())
                })?;
            let source_type = args
                .get(1)
                .and_then(|v| match v {
                    LuaValue::String(ls) => Some(ls.to_str().ok()?.to_string()),
                    _ => None,
                })
                .map(|t| match t.as_str() {
                    "static" => SourceType::Static,
                    _ => SourceType::Stream,
                })
                .unwrap_or(SourceType::Stream);
            let mut st = s.borrow_mut();
            let key = st.mixer.load_source(&path, source_type);
            Ok(LuaSource {
                state: s.clone(),
                key,
            })
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "play",
        lua.create_function(
            move |_, (id_val, options): (LuaValue, Option<mlua::Table>)| {
                let mut st = s.borrow_mut();
                let key = require_sound_key(&st, &id_val, "lurek.audio.play")?;
                if let Some(opts) = options {
                    if let Ok(bus_name) = opts.get::<_, String>("bus") {
                        if let Some(bus) = st.mixer.get_bus_by_name(&bus_name) {
                            st.mixer.set_source_bus(key, Some(bus));
                        } else {
                            return Err(LuaError::external("bus not found"));
                        }
                    }
                }
                let game_dir = st.game_dir.clone();
                st.mixer.play(key, &game_dir);
                Ok(key.data().as_ffi())
            },
        )?,
    )?;
    let s = state.clone();
    tbl.set(
        "stop",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.stop")?;
            st.mixer.stop(key);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setVolume",
        lua.create_function(move |_, (id_val, vol): (LuaValue, f32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.setVolume")?;
            st.mixer.set_volume(key, vol);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getVolume",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getVolume")?;
            Ok(st.mixer.get_volume(key))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "pause",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.pause")?;
            st.mixer.pause(key);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "resume",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.resume")?;
            st.mixer.resume(key);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setPitch",
        lua.create_function(move |_, (id_val, pitch): (LuaValue, f32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.setPitch")?;
            st.mixer.set_pitch(key, pitch);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getPitch",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getPitch")?;
            Ok(st.mixer.get_pitch(key))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "isPlaying",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.isPlaying")?;
            Ok(st.mixer.is_playing(key))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "isPaused",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.isPaused")?;
            Ok(st.mixer.is_paused(key))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "isStopped",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.isStopped")?;
            Ok(st.mixer.is_stopped(key))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setLooping",
        lua.create_function(move |_, (id_val, looping): (LuaValue, bool)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.setLooping")?;
            st.mixer.set_looping(key, looping);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "isLooping",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.isLooping")?;
            Ok(st.mixer.is_looping(key))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "playLooping",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.playLooping")?;
            let game_dir = st.game_dir.clone();
            st.mixer.play_looping(key, &game_dir);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setPan",
        lua.create_function(move |_, (id_val, pan): (LuaValue, f32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.setPan")?;
            st.mixer.set_pan(key, pan);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getPan",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getPan")?;
            Ok(st.mixer.get_pan(key))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setMasterVolume",
        lua.create_function(move |_, vol: f32| {
            s.borrow_mut().mixer.set_master_volume(vol);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getMasterVolume",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_master_volume()))?,
    )?;
    let s = state.clone();
    tbl.set(
        "getActiveSourceCount",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_active_source_count()))?,
    )?;
    let s = state.clone();
    tbl.set(
        "getSourceCount",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_source_count()))?,
    )?;
    let s = state.clone();
    tbl.set(
        "getSourceType",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let st = s.borrow();
            match st.mixer.get_source_type(key) {
                Some(SourceType::Static) => Ok("static".to_string()),
                Some(SourceType::Stream) => Ok("stream".to_string()),
                None => Err(LuaError::RuntimeError(
                    "lurek.audio.getSourceType: invalid source handle".into(),
                )),
            }
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "clone",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let mut st = s.borrow_mut();
            match st.mixer.clone_source(key) {
                Some(new_key) => Ok(LuaSource {
                    state: s.clone(),
                    key: new_key,
                }),
                None => Err(LuaError::RuntimeError(
                    "lurek.audio.clone: invalid source handle".into(),
                )),
            }
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "pauseAll",
        lua.create_function(move |_, ()| {
            s.borrow_mut().mixer.pause_all();
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "stopAll",
        lua.create_function(move |_, ()| {
            s.borrow_mut().mixer.stop_all();
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "resumeAll",
        lua.create_function(move |_, ()| {
            s.borrow_mut().mixer.resume_all();
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "release",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let mut st = s.borrow_mut();
            if st.mixer.release(key) {
                Ok(true)
            } else {
                Err(LuaError::RuntimeError(
                    "lurek.audio.release: invalid or already-released audio source handle".into(),
                ))
            }
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "newBus",
        lua.create_function(move |_, name: String| {
            let mut st = s.borrow_mut();
            let key = st.mixer.new_bus(&name);
            Ok(LuaBus {
                state: s.clone(),
                key,
            })
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setSourceBus",
        lua.create_function(move |_, (id_val, bus_val): (LuaValue, LuaValue)| {
            let key = sound_key_from_value(&id_val)?;
            let bus_key = match &bus_val {
                LuaValue::UserData(ud) => {
                    let bus = ud.borrow::<LuaBus>()?;
                    Some(bus.key)
                }
                _ => {
                    return Err(LuaError::RuntimeError(
                        "lurek.audio.setSourceBus: expected Bus userdata".into(),
                    ));
                }
            };
            s.borrow_mut().mixer.set_source_bus(key, bus_key);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getSourceBus",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let st = s.borrow();
            match st.mixer.get_source_bus(key) {
                Some(bus_key) => Ok(Some(LuaBus {
                    state: s.clone(),
                    key: bus_key,
                })),
                None => Ok(None),
            }
        })?,
    )?;
    tbl.set("getMaxSources", lua.create_function(|_, ()| Ok(64))?)?;
    let s = state.clone();
    tbl.set(
        "getDuration",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getDuration")?;
            Ok(st.mixer.get_duration(key))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "tell",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.tell")?;
            Ok(st.mixer.get_tell(key))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "seek",
        lua.create_function(move |_, (id_val, pos): (LuaValue, f32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.seek")?;
            let game_dir = st.game_dir.clone();
            st.mixer.seek(key, pos, &game_dir);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setLowpass",
        lua.create_function(move |_, (id_val, cutoff_hz): (LuaValue, u32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.setLowpass")?;
            st.mixer.set_lowpass(key, cutoff_hz);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setHighpass",
        lua.create_function(move |_, (id_val, cutoff_hz): (LuaValue, u32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.setHighpass")?;
            st.mixer.set_highpass(key, cutoff_hz);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getLowpass",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getLowpass")?;
            Ok(st.mixer.get_lowpass(key))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getHighpass",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getHighpass")?;
            Ok(st.mixer.get_highpass(key))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "clearFilter",
        lua.create_function(move |_, id_val: LuaValue| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.clearFilter")?;
            st.mixer.clear_filter(key);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "fadeIn",
        lua.create_function(move |_, (id_val, dur): (LuaValue, f32)| {
            let mut st = s.borrow_mut();
            let key = require_sound_key(&st, &id_val, "lurek.audio.fadeIn")?;
            st.mixer.set_fade_in(key, dur);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getFadeIn",
        lua.create_function(move |_, id_val: LuaValue| {
            let st = s.borrow();
            let key = require_sound_key(&st, &id_val, "lurek.audio.getFadeIn")?;
            Ok(st.mixer.get_fade_in(key))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setListener2D",
        lua.create_function(move |_, (x, y): (f32, f32)| {
            s.borrow_mut().mixer.set_listener_position(x, y, 0.0);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getListener2D",
        lua.create_function(move |_, ()| {
            let pos = s.borrow().mixer.get_listener_position();
            Ok((pos[0], pos[1]))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setListener",
        lua.create_function(move |_, (x, y, z): (f32, f32, Option<f32>)| {
            s.borrow_mut()
                .mixer
                .set_listener_position(x, y, z.unwrap_or(0.0));
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getListener",
        lua.create_function(move |_, ()| {
            let pos = s.borrow().mixer.get_listener_position();
            Ok((pos[0], pos[1], pos[2]))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setPosition",
        lua.create_function(
            move |_, (id_val, x, y, z): (LuaValue, f32, f32, Option<f32>)| {
                let key = sound_key_from_value(&id_val)?;
                s.borrow_mut()
                    .mixer
                    .set_source_position(key, x, y, z.unwrap_or(0.0));
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    tbl.set(
        "getPosition",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let pos = s.borrow().mixer.get_source_position(key);
            Ok((pos[0], pos[1], pos[2]))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setVelocity",
        lua.create_function(
            move |_, (id_val, x, y, z): (LuaValue, f32, f32, Option<f32>)| {
                let key = sound_key_from_value(&id_val)?;
                s.borrow_mut()
                    .mixer
                    .set_source_velocity(key, x, y, z.unwrap_or(0.0));
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    tbl.set(
        "getVelocity",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let vel = s.borrow().mixer.get_source_velocity(key);
            Ok((vel[0], vel[1], vel[2]))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setOrientation",
        lua.create_function(
            move |_, (id_val, fx, fy, fz, ux, uy, uz): (LuaValue, f32, f32, f32, f32, f32, f32)| {
                let key = sound_key_from_value(&id_val)?;
                s.borrow_mut()
                    .mixer
                    .set_source_orientation(key, fx, fy, fz, ux, uy, uz);
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    tbl.set(
        "getOrientation",
        lua.create_function(move |_, id_val: LuaValue| {
            let key = sound_key_from_value(&id_val)?;
            let o = s.borrow().mixer.get_source_orientation(key);
            Ok((o[0], o[1], o[2], o[3], o[4], o[5]))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setDopplerScale",
        lua.create_function(move |_, scale: f32| {
            s.borrow_mut().mixer.set_doppler_scale(scale);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getDopplerScale",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_doppler_scale()))?,
    )?;
    let s = state.clone();
    tbl.set(
        "setDistanceModel",
        lua.create_function(move |_, model: String| {
            s.borrow_mut().mixer.set_distance_model(&model);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getDistanceModel",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.get_distance_model().to_string()))?,
    )?;
    let s = state.clone();
    tbl.set(
        "setMeter",
        lua.create_function(move |_, level: f32| {
            s.borrow_mut().mixer.master_peak = level.clamp(0.0, 1.0);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getMeter",
        lua.create_function(move |_, ()| Ok(s.borrow().mixer.master_peak))?,
    )?;
    let s = state.clone();
    tbl.set(
        "newMidiPlayer",
        lua.create_function(move |_, path: Option<String>| {
            let mp = MidiPlayer::new();
            let inner = Rc::new(RefCell::new(mp));
            let result = LuaMidiPlayer {
                inner: inner.clone(),
                state: s.clone(),
            };
            if let Some(p) = path {
                let st = s.borrow();
                let full_path = st.game_dir.join(&p);
                drop(st);
                inner.borrow_mut().load(&full_path);
            }
            Ok(result)
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "newSoundData",
        lua.create_function(move |lua, args: LuaMultiValue| {
            let (path_opt, count, rate, channels) = extract_sound_data_args(args)?;
            let full_path_buf = path_opt.as_ref().map(|p| s.borrow().game_dir.join(p));
            let full_path = full_path_buf.as_ref().and_then(|p| p.to_str());
            let sd = SoundData::from_lua_args(full_path, count, rate, channels)
                .map_err(LuaError::RuntimeError)?;
            lua.create_userdata(sd)
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setMidiSoundFont",
        lua.create_function(move |_, path: String| {
            let mut st = s.borrow_mut();
            let full_path = st.game_dir.join(&path);
            let data = std::fs::read(&full_path).map_err(|e| {
                LuaError::RuntimeError(format!(
                    "Failed to read SoundFont '{}': {}",
                    full_path.display(),
                    e
                ))
            })?;
            st.midi_state
                .set_soundfont(data, Some(path))
                .map_err(LuaError::RuntimeError)
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "hasMidiSoundFont",
        lua.create_function(move |_, ()| Ok(s.borrow().midi_state.has_soundfont()))?,
    )?;
    let s = state.clone();
    tbl.set(
        "clearMidiSoundFont",
        lua.create_function(move |_, ()| {
            s.borrow_mut().midi_state.clear_soundfont();
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "newDecoder",
        lua.create_function(move |_, (source, buffersize): (String, Option<usize>)| {
            let st = s.borrow();
            let path = st.game_dir.join(&source);
            let path_str = path
                .to_str()
                .ok_or_else(|| LuaError::RuntimeError("Invalid path".to_string()))?;
            let buf = buffersize.unwrap_or(2048);
            let decoder = Decoder::from_file(path_str, buf)
                .map_err(|e| LuaError::RuntimeError(e.to_string()))?;
            Ok(LuaDecoder { inner: decoder })
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "newQueueableSource",
        lua.create_function(
            move |_,
                  (sample_rate, bit_depth, channels, buffer_count): (
                u32,
                u8,
                u8,
                Option<usize>,
            )| {
                let buf = buffer_count.unwrap_or(4);
                let key = s
                    .borrow_mut()
                    .mixer
                    .new_queueable(sample_rate, bit_depth, channels, buf);
                Ok(slotmap::Key::data(&key).as_ffi())
            },
        )?,
    )?;
    let s = state.clone();
    tbl.set(
        "queueSource",
        lua.create_function(move |_, (qsource_id, sd): (u64, mlua::AnyUserData)| {
            let key = queueable_key_from_u64(qsource_id);
            let sd_ref = sd.borrow::<SoundData>()?;
            s.borrow_mut()
                .mixer
                .queue_buffer(key, sd_ref.samples())
                .map_err(|e| LuaError::RuntimeError(e.to_string()))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getFreeBufferCount",
        lua.create_function(move |_, qsource_id: u64| {
            let key = queueable_key_from_u64(qsource_id);
            Ok(s.borrow().mixer.queueable_free_buffer_count(key) as u32)
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "playQueueable",
        lua.create_function(move |_, qsource_id: u64| {
            let key = queueable_key_from_u64(qsource_id);
            s.borrow_mut().mixer.play_queueable(key);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "stopQueueable",
        lua.create_function(move |_, qsource_id: u64| {
            let key = queueable_key_from_u64(qsource_id);
            s.borrow_mut().mixer.stop_queueable(key);
            Ok(())
        })?,
    )?;
    tbl.set(
        "getPlaybackDevices",
        lua.create_function(|lua, ()| {
            let devices = crate::audio::get_playback_devices();
            let t = lua.create_table()?;
            for (i, name) in devices.into_iter().enumerate() {
                t.set(i + 1, name)?;
            }
            Ok(t)
        })?,
    )?;
    tbl.set(
        "getPlaybackDevice",
        lua.create_function(|_, ()| Ok(crate::audio::get_playback_device()))?,
    )?;
    tbl.set(
        "setPlaybackDevice",
        lua.create_function(|_, name: String| {
            crate::audio::set_playback_device(&name)
                .map_err(|e| LuaError::RuntimeError(e.to_string()))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "create_bus",
        lua.create_function(move |_, (name, parent_name): (String, Option<String>)| {
            if name.is_empty() {
                return Err(LuaError::external("invalid bus name"));
            }
            let mut st = s.borrow_mut();
            let _parent_key = parent_name.and_then(|n| st.mixer.get_bus_by_name(&n));
            let _bus_key = st.mixer.new_bus(&name);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "set_bus_volume",
        lua.create_function(move |_, (name, volume): (String, f32)| {
            let mut st = s.borrow_mut();
            if let Some(bus_key) = st.mixer.get_bus_by_name(&name) {
                if let Some(bus) = st.mixer.get_bus_mut(bus_key) {
                    bus.set_volume(volume);
                    return Ok(());
                }
            }
            Err(LuaError::external("bus not found"))
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "add_effect",
        lua.create_function(
            move |_, (bus_name, effect_type_str, params): (String, String, Option<mlua::Table>)| {
                let st = s.borrow();
                let bus_key = st
                    .mixer
                    .get_bus_by_name(&bus_name)
                    .ok_or_else(|| LuaError::external(format!("Bus not found: {}", bus_name)))?;
                let bus = st
                    .mixer
                    .get_bus(bus_key)
                    .ok_or_else(|| LuaError::external(format!("Bus not found: {}", bus_name)))?;
                let p1_val = params
                    .as_ref()
                    .and_then(|t| t.get::<_, f32>("value").ok())
                    .unwrap_or(1000.0);
                let eid = bus
                    .add_effect(&effect_type_str, p1_val)
                    .map_err(LuaError::RuntimeError)?;
                Ok(Some(eid))
            },
        )?,
    )?;
    let s = state.clone();
    tbl.set(
        "remove_effect",
        lua.create_function(move |_, (bus_name, effect_id): (String, u32)| {
            let st = s.borrow();
            let bus_key = st
                .mixer
                .get_bus_by_name(&bus_name)
                .ok_or_else(|| LuaError::external(format!("Bus not found: {}", bus_name)))?;
            let bus = st
                .mixer
                .get_bus(bus_key)
                .ok_or_else(|| LuaError::external(format!("Bus not found: {}", bus_name)))?;
            bus.remove_effect(effect_id)
                .map_err(LuaError::RuntimeError)
                .map(|_| true)
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "set_effect_param",
        lua.create_function(
            move |_, (bus_name, effect_id, param_name, value): (String, u32, String, f32)| {
                let st = s.borrow();
                let bus_key = st
                    .mixer
                    .get_bus_by_name(&bus_name)
                    .ok_or_else(|| LuaError::external(format!("Bus not found: {}", bus_name)))?;
                let bus = st
                    .mixer
                    .get_bus(bus_key)
                    .ok_or_else(|| LuaError::external(format!("Bus not found: {}", bus_name)))?;
                let fx_list = bus.effects.read().unwrap();
                let fx = fx_list
                    .iter()
                    .find(|fx| fx.id == effect_id)
                    .ok_or_else(|| {
                        LuaError::external(format!("Effect not found: {}", effect_id))
                    })?;
                fx.set_param(&param_name, value)
                    .map_err(LuaError::RuntimeError)
                    .map(|_| true)
            },
        )?,
    )?;
    tbl.set(
        "newSineWave",
        lua.create_function(
            |_, (freq, duration, sample_rate, amplitude): (f32, f32, u32, f32)| {
                Ok(SoundData::sine_wave(freq, duration, sample_rate, amplitude))
            },
        )?,
    )?;
    tbl.set(
        "newSquareWave",
        lua.create_function(
            |_, (freq, duration, sample_rate, amplitude): (f32, f32, u32, f32)| {
                Ok(SoundData::square_wave(
                    freq,
                    duration,
                    sample_rate,
                    amplitude,
                ))
            },
        )?,
    )?;
    tbl.set(
        "newSawtoothWave",
        lua.create_function(
            |_, (freq, duration, sample_rate, amplitude): (f32, f32, u32, f32)| {
                Ok(SoundData::sawtooth_wave(
                    freq,
                    duration,
                    sample_rate,
                    amplitude,
                ))
            },
        )?,
    )?;
    tbl.set(
        "newTriangleWave",
        lua.create_function(
            |_, (freq, duration, sample_rate, amplitude): (f32, f32, u32, f32)| {
                Ok(SoundData::triangle_wave(
                    freq,
                    duration,
                    sample_rate,
                    amplitude,
                ))
            },
        )?,
    )?;
    tbl.set(
        "newWhiteNoise",
        lua.create_function(
            |_, (duration, sample_rate, amplitude, seed): (f32, u32, f32, u32)| {
                Ok(SoundData::white_noise(
                    duration,
                    sample_rate,
                    amplitude,
                    seed,
                ))
            },
        )?,
    )?;
    tbl.set(
        "applyLowpass",
        lua.create_function(|_, (sd_ud, cutoff_hz): (LuaAnyUserData, f32)| {
            let mut sd = sd_ud
                .borrow_mut::<SoundData>()
                .map_err(|_| LuaError::RuntimeError("argument must be a SoundData".into()))?;
            sd.apply_lowpass(cutoff_hz);
            Ok(())
        })?,
    )?;
    tbl.set(
        "applyHighpass",
        lua.create_function(|_, (sd_ud, cutoff_hz): (LuaAnyUserData, f32)| {
            let mut sd = sd_ud
                .borrow_mut::<SoundData>()
                .map_err(|_| LuaError::RuntimeError("argument must be a SoundData".into()))?;
            sd.apply_highpass(cutoff_hz);
            Ok(())
        })?,
    )?;
    tbl.set(
        "applyBandpass",
        lua.create_function(|_, (sd_ud, low_hz, high_hz): (LuaAnyUserData, f32, f32)| {
            let mut sd = sd_ud
                .borrow_mut::<SoundData>()
                .map_err(|_| LuaError::RuntimeError("argument must be a SoundData".into()))?;
            sd.apply_bandpass(low_hz, high_hz);
            Ok(())
        })?,
    )?;
    tbl.set(
        "applyGain",
        lua.create_function(|_, (sd_ud, gain): (LuaAnyUserData, f32)| {
            let mut sd = sd_ud
                .borrow_mut::<SoundData>()
                .map_err(|_| LuaError::RuntimeError("argument must be a SoundData".into()))?;
            sd.apply_gain(gain);
            Ok(())
        })?,
    )?;
    tbl.set(
        "mixInto",
        lua.create_function(|_, (dest_ud, src_ud): (LuaAnyUserData, LuaAnyUserData)| {
            let src_samples: Vec<f32> = {
                let src = src_ud
                    .borrow::<SoundData>()
                    .map_err(|_| LuaError::RuntimeError("src must be a SoundData".into()))?;
                src.samples().to_vec()
            };
            let src_data = {
                let src = src_ud
                    .borrow::<SoundData>()
                    .map_err(|_| LuaError::RuntimeError("src must be a SoundData".into()))?;
                SoundData::from_samples(src_samples, src.sample_rate(), src.channel_count())
            };
            let mut dest = dest_ud
                .borrow_mut::<SoundData>()
                .map_err(|_| LuaError::RuntimeError("dest must be a SoundData".into()))?;
            dest.mix_into(&src_data);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "saveWAV",
        lua.create_function(move |_, (sd_ud, filename): (LuaAnyUserData, String)| {
            let path = s.borrow().game_dir.join(&filename);
            let sd = sd_ud
                .borrow::<SoundData>()
                .map_err(|_| LuaError::RuntimeError("argument must be a SoundData".into()))?;
            let bytes = sd.encode_wav();
            if let Some(parent) = path.parent() {
                std::fs::create_dir_all(parent).map_err(LuaError::external)?;
            }
            std::fs::write(&path, &bytes).map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setStereoWidth",
        lua.create_function(move |_, (src_ud, width): (LuaAnyUserData, f32)| {
            let key = src_ud
                .borrow::<LuaSource>()
                .map_err(|_| LuaError::RuntimeError("argument must be an AudioSource".into()))?
                .key;
            s.borrow_mut()
                .mixer
                .set_stereo_width(key, width)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getStereoWidth",
        lua.create_function(move |_, src_ud: LuaAnyUserData| {
            let key = src_ud
                .borrow::<LuaSource>()
                .map_err(|_| LuaError::RuntimeError("argument must be an AudioSource".into()))?
                .key;
            s.borrow()
                .mixer
                .get_stereo_width(key)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "setRandomPitch",
        lua.create_function(move |_, (src_ud, min, max): (LuaAnyUserData, f32, f32)| {
            let key = src_ud
                .borrow::<LuaSource>()
                .map_err(|_| LuaError::RuntimeError("argument must be an AudioSource".into()))?
                .key;
            s.borrow_mut()
                .mixer
                .set_random_pitch(key, min, max)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "clearRandomPitch",
        lua.create_function(move |_, src_ud: LuaAnyUserData| {
            let key = src_ud
                .borrow::<LuaSource>()
                .map_err(|_| LuaError::RuntimeError("argument must be an AudioSource".into()))?
                .key;
            s.borrow_mut().mixer.clear_random_pitch(key);
            Ok(())
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "crossfade",
        lua.create_function(
            move |_, (from_ud, to_ud, duration): (LuaAnyUserData, LuaAnyUserData, f32)| {
                let from_key = from_ud
                    .borrow::<LuaSource>()
                    .map_err(|_| LuaError::RuntimeError("from must be an AudioSource".into()))?
                    .key;
                let to_key = to_ud
                    .borrow::<LuaSource>()
                    .map_err(|_| LuaError::RuntimeError("to must be an AudioSource".into()))?
                    .key;
                let game_dir = s.borrow().game_dir.clone();
                s.borrow_mut()
                    .mixer
                    .crossfade(from_key, to_key, duration, &game_dir);
                Ok(())
            },
        )?,
    )?;
    let s = state.clone();
    tbl.set(
        "getBusPeak",
        lua.create_function(move |_, bus_name: String| {
            s.borrow()
                .mixer
                .get_bus_peak(&bus_name)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "getBusRms",
        lua.create_function(move |_, bus_name: String| {
            s.borrow()
                .mixer
                .get_bus_rms(&bus_name)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "newPool",
        lua.create_function(move |_, (file_path, voice_count): (String, usize)| {
            let pool = s
                .borrow_mut()
                .mixer
                .new_pool(&file_path, voice_count)
                .map_err(LuaError::external)?;
            Ok(LuaSoundPool {
                pool,
                state: s.clone(),
            })
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "processOffline",
        lua.create_function(
            move |_, (input, output, effects_tbl): (String, String, mlua::Table)| {
                if input.contains("..") || output.contains("..") {
                    return Err(LuaError::external("path traversal not allowed"));
                }
                let game_dir = s.borrow().game_dir.clone();
                let input_path = game_dir.join(&input).to_string_lossy().into_owned();
                let output_path = game_dir.join(&output).to_string_lossy().into_owned();
                let mut effects = Vec::new();
                for pair in effects_tbl.sequence_values::<mlua::Table>() {
                    let t = pair.map_err(LuaError::external)?;
                    let typ_str: String = t.get("type").unwrap_or_default();
                    let p1: f32 = t.get("p1").unwrap_or(1000.0);
                    let p2: f32 = t.get("p2").unwrap_or(1.0);
                    let p3: f32 = t.get("p3").unwrap_or(0.5);
                    use crate::audio::EffectType;
                    let typ = match typ_str.as_str() {
                        "lowpass" => EffectType::Lowpass,
                        "highpass" => EffectType::Highpass,
                        "bandpass" => EffectType::Bandpass,
                        "reverb" => EffectType::Reverb,
                        "chorus" => EffectType::Chorus,
                        "notch" => EffectType::Notch,
                        "lowshelf" => EffectType::LowShelf,
                        "highshelf" => EffectType::HighShelf,
                        "bell_eq" => EffectType::BellEq,
                        "reverb2" => EffectType::Reverb2,
                        "flanger" => EffectType::Flanger,
                        "phaser" => EffectType::Phaser,
                        "distortion" => EffectType::Distortion,
                        "limiter" => EffectType::Limiter,
                        "compressor" => EffectType::Compressor,
                        other => {
                            return Err(LuaError::external(format!(
                                "unknown effect type: {}",
                                other
                            )))
                        }
                    };
                    effects.push(crate::audio::OfflineEffect { typ, p1, p2, p3 });
                }
                crate::audio::offline::process_offline(&input_path, &output_path, &effects)
                    .map_err(LuaError::external)
            },
        )?,
    )?;
    let s = state.clone();
    tbl.set(
        "normalizeFile",
        lua.create_function(move |_, (input, output, target): (String, String, f32)| {
            if input.contains("..") || output.contains("..") {
                return Err(LuaError::external("path traversal not allowed"));
            }
            let game_dir = s.borrow().game_dir.clone();
            let input_path = game_dir.join(&input).to_string_lossy().into_owned();
            let output_path = game_dir.join(&output).to_string_lossy().into_owned();
            crate::audio::offline::normalize_file(&input_path, &output_path, target)
                .map_err(LuaError::external)
        })?,
    )?;
    let s = state.clone();
    tbl.set(
        "waveformToPng",
        lua.create_function(
            move |_, (input, output, width, height): (String, String, u32, u32)| {
                if input.contains("..") || output.contains("..") {
                    return Err(LuaError::external("path traversal not allowed"));
                }
                let game_dir = s.borrow().game_dir.clone();
                let input_path = game_dir.join(&input).to_string_lossy().into_owned();
                let output_path = game_dir.join(&output).to_string_lossy().into_owned();
                crate::audio::visualizer::waveform_to_png(&input_path, &output_path, width, height)
                    .map_err(LuaError::external)
            },
        )?,
    )?;
    let s = state.clone();
    tbl.set(
        "spectrogramToPng",
        lua.create_function(
            move |_, (input, output, width, height): (String, String, u32, u32)| {
                if input.contains("..") || output.contains("..") {
                    return Err(LuaError::external("path traversal not allowed"));
                }
                let game_dir = s.borrow().game_dir.clone();
                let input_path = game_dir.join(&input).to_string_lossy().into_owned();
                let output_path = game_dir.join(&output).to_string_lossy().into_owned();
                crate::audio::visualizer::spectrogram_to_png(
                    &input_path,
                    &output_path,
                    width,
                    height,
                )
                .map_err(LuaError::external)
            },
        )?,
    )?;
    lurek.set("audio", tbl)?;
    Ok(())
}
impl mlua::UserData for SoundData {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getSampleCount", |_, this, ()| Ok(this.sample_count()));
        methods.add_method("getSampleRate", |_, this, ()| Ok(this.sample_rate()));
        methods.add_method("getChannelCount", |_, this, ()| Ok(this.channel_count()));
        methods.add_method("getDuration", |_, this, ()| Ok(this.duration()));
        methods.add_method("getBitDepth", |_, this, ()| Ok(this.bit_depth()));
        methods.add_method("getSample", |_, this, index: usize| {
            this.get_sample(index).ok_or_else(|| {
                LuaError::RuntimeError(format!("Sample index {} out of bounds", index))
            })
        });
        methods.add_method(
            "drawWaveform",
            |_,
             this,
             (target, x, y, w, h, r, g, b, a): (
                mlua::AnyUserData,
                i32,
                i32,
                u32,
                u32,
                u8,
                u8,
                u8,
                u8,
            )| {
                let mut img = target.borrow_mut::<crate::image::ImageData>()?;
                this.draw_waveform(&mut img, x, y, w, h, r, g, b, a);
                Ok(())
            },
        );
        methods.add_method_mut("setSample", |_, this, (index, value): (usize, f32)| {
            if this.set_sample(index, value) {
                Ok(())
            } else {
                Err(LuaError::RuntimeError(format!(
                    "Sample index {} out of bounds",
                    index
                )))
            }
        });
    }
}
