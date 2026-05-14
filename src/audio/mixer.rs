use crate::audio::bus::Bus;
use crate::audio::dsp::{DynamicEffectSource, EffectParams};
#[allow(unused_imports)]
use crate::log_msg;
use crate::runtime::error::EngineError;
use crate::runtime::log_messages::{A003_AUDIO_OUTPUT_UNAVAIL, A004_AUDIO_PLAY_QUEUED};
use crate::runtime::resource_keys::BusKey;
use crate::runtime::resource_keys::QueueableKey;
use crate::runtime::resource_keys::SoundKey;
use rodio::Source;
use slotmap::SlotMap;
use std::collections::VecDeque;
use std::io::BufReader;
use std::path::Path;
use std::sync::Arc;
use std::time::Instant;
#[derive(Debug, Clone, Copy, PartialEq)]
/// Backing source strategy for one loaded audio entry.
pub enum SourceType {
    /// Fully decoded source reused from cached bytes.
    Static,
    /// Streamed source decoded on demand.
    Stream,
}
#[derive(Debug, Clone, Copy, PartialEq)]
/// Runtime playback state of one source or stream.
pub enum PlayState {
    /// Not playing; position reset or completed.
    Stopped,
    /// Actively playing through a rodio sink.
    Playing,
    /// Temporarily paused with resumable sink state.
    Paused,
}
/// Internal per-source runtime state tracked by `Mixer`.
struct AudioEntry {
    /// Holds file_path state.
    file_path: String,
    /// Holds sink state.
    sink: Option<rodio::Sink>,
    /// Holds source_type state.
    source_type: SourceType,
    /// Holds decoded_data state.
    decoded_data: Option<Arc<Vec<u8>>>,
    /// Holds looping state.
    looping: bool,
    /// Holds volume state.
    volume: f32,
    /// Holds pitch state.
    pitch: f32,
    /// Holds pan state.
    pan: f32,
    /// Holds play_state state.
    play_state: PlayState,
    /// Holds bus_key state.
    bus_key: Option<BusKey>,
    /// Holds duration_secs state.
    duration_secs: Option<f32>,
    /// Holds play_start state.
    play_start: Option<Instant>,
    /// Holds accumulated_secs state.
    accumulated_secs: f32,
    /// Holds lowpass_cutoff state.
    lowpass_cutoff: Option<u32>,
    /// Holds highpass_cutoff state.
    highpass_cutoff: Option<u32>,
    /// Holds fade_in_duration state.
    fade_in_duration: Option<f32>,
    /// Holds spatial state.
    spatial: Option<crate::audio::SpatialState>,
    /// Holds stereo_width state.
    stereo_width: f32,
    /// Holds pitch_range state.
    pitch_range: Option<(f32, f32)>,
    /// Holds peak state.
    pub peak: f32,
}
/// Push-buffer streaming source with fixed number of reusable queue slots.
pub struct QueueableSource {
    /// Holds sample_rate state.
    pub sample_rate: u32,
    /// Holds bit_depth state.
    pub bit_depth: u8,
    /// Holds channels state.
    pub channels: u8,
    /// Holds buffer_count state.
    pub buffer_count: usize,
    /// Holds queued_buffers state.
    pub queued_buffers: VecDeque<Vec<f32>>,
    /// Holds free_buffers state.
    pub free_buffers: usize,
}
impl QueueableSource {
    /// Create and return a new instance.
    pub fn new(sample_rate: u32, bit_depth: u8, channels: u8, buffer_count: usize) -> Self {
        QueueableSource {
            sample_rate,
            bit_depth,
            channels,
            buffer_count,
            queued_buffers: VecDeque::new(),
            free_buffers: buffer_count,
        }
    }
    /// Return queue_buffer result.
    pub fn queue_buffer(&mut self, data: &[f32]) -> Result<(), EngineError> {
        if self.free_buffers == 0 {
            return Err(EngineError::AudioError(
                "QueueableSource: no free buffer slots".to_string(),
            ));
        }
        self.queued_buffers.push_back(data.to_vec());
        self.free_buffers -= 1;
        Ok(())
    }
    /// Return free_buffer_count result.
    pub fn free_buffer_count(&self) -> usize {
        self.free_buffers
    }
}
/// Central audio mixer state and resource registry.
pub struct Mixer {
    /// Holds _stream state.
    _stream: Option<rodio::OutputStream>,
    /// Holds stream_handle state.
    stream_handle: Option<rodio::OutputStreamHandle>,
    /// Holds sources state.
    sources: SlotMap<SoundKey, AudioEntry>,
    /// Holds master_volume state.
    master_volume: f32,
    /// Holds buses state.
    buses: SlotMap<BusKey, Bus>,
    /// Holds listener_position state.
    listener_position: [f32; 3],
    /// Holds listener_orientation state.
    listener_orientation: [f32; 6],
    /// Holds listener_velocity state.
    listener_velocity: [f32; 3],
    /// Holds doppler_scale state.
    doppler_scale: f32,
    /// Holds distance_model state.
    distance_model: String,
    /// Holds queueables state.
    queueables: SlotMap<QueueableKey, QueueableSource>,
    /// Holds master_peak state.
    pub master_peak: f32,
}
/// Provides the Default behavior contract for Mixer.
impl Default for Mixer {
    /// Return default instance state.
    fn default() -> Self {
        Self::new()
    }
}
impl Mixer {
    /// Create and return a new instance.
    pub fn new() -> Self {
        let (stream, handle) = match rodio::OutputStream::try_default() {
            Ok((s, h)) => (Some(s), Some(h)),
            Err(e) => {
                log_msg!(warn, A003_AUDIO_OUTPUT_UNAVAIL, "{}", e);
                (None, None)
            }
        };
        Mixer {
            _stream: stream,
            stream_handle: handle,
            sources: SlotMap::with_key(),
            master_volume: 1.0,
            buses: SlotMap::with_key(),
            listener_position: [0.0, 0.0, 0.0],
            listener_orientation: [0.0, 0.0, -1.0, 0.0, 1.0, 0.0],
            listener_velocity: [0.0, 0.0, 0.0],
            doppler_scale: 1.0,
            distance_model: "inverse_clamped".to_string(),
            queueables: SlotMap::with_key(),
            master_peak: 0.0,
        }
    }
    /// Return stream_handle result.
    pub fn stream_handle(&self) -> Option<&rodio::OutputStreamHandle> {
        self.stream_handle.as_ref()
    }
    /// Return load_source result.
    pub fn load_source(&mut self, file_path: &str, source_type: SourceType) -> SoundKey {
        self.sources.insert(AudioEntry {
            file_path: file_path.to_string(),
            sink: None,
            source_type,
            decoded_data: None,
            looping: false,
            volume: 1.0,
            pitch: 1.0,
            pan: 0.0,
            play_state: PlayState::Stopped,
            bus_key: None,
            duration_secs: None,
            play_start: None,
            accumulated_secs: 0.0,
            lowpass_cutoff: None,
            highpass_cutoff: None,
            fade_in_duration: None,
            spatial: None,
            stereo_width: 1.0,
            pitch_range: None,
            peak: 0.0,
        })
    }
    /// Change playback state via play.
    pub fn play(&mut self, key: SoundKey, game_dir: &Path) {
        let master_vol = self.master_volume;
        let (bus_vol, bus_pitch, bus_paused) = self
            .sources
            .get(key)
            .and_then(|e| e.bus_key)
            .and_then(|bk| self.buses.get(bk))
            .map(|b| (b.volume(), b.pitch(), b.is_paused()))
            .unwrap_or((1.0, 1.0, false));
        if bus_paused {
            return;
        }
        if let Some(entry) = self.sources.get_mut(key) {
            if entry.source_type == SourceType::Static && entry.decoded_data.is_none() {
                let path = game_dir.join(&entry.file_path);
                if let Ok(data) = std::fs::read(&path) {
                    entry.decoded_data = Some(Arc::new(data));
                }
            }
        }
        let params = self.sources.get(key).map(|entry| {
            let was_stopped = entry.play_state == PlayState::Stopped;
            (
                entry.file_path.clone(),
                entry.source_type,
                entry.decoded_data.clone(),
                entry.volume * master_vol * bus_vol,
                entry.pitch * bus_pitch,
                entry.pan,
                entry.looping,
                entry.lowpass_cutoff,
                entry.highpass_cutoff,
                entry.fade_in_duration,
                was_stopped,
            )
        });
        let (
            file_path,
            source_type,
            decoded_data,
            volume,
            pitch,
            pan,
            looping,
            lowpass_cutoff,
            highpass_cutoff,
            fade_in_duration,
            was_stopped,
        ) = match params {
            Some(p) => p,
            None => return,
        };
        let maybe_sink_dur = self.stream_handle.as_ref().and_then(|handle| {
            Self::build_sink(
                handle,
                &file_path,
                source_type,
                decoded_data.as_ref(),
                game_dir,
                0.0,
                volume,
                pitch,
                pan,
                looping,
                lowpass_cutoff,
                highpass_cutoff,
                fade_in_duration,
                self.sources
                    .get(key)
                    .and_then(|e| e.bus_key)
                    .and_then(|bk| self.buses.get(bk))
                    .map(|b| std::sync::Arc::clone(&b.effects)),
            )
        });
        if let Some((sink, duration)) = maybe_sink_dur {
            if let Some(entry) = self.sources.get_mut(key) {
                if entry.duration_secs.is_none() {
                    entry.duration_secs = duration;
                }
                entry.sink = Some(sink);
                entry.play_state = PlayState::Playing;
                if was_stopped {
                    entry.accumulated_secs = 0.0;
                }
                entry.play_start = Some(Instant::now());
            }
        }
    }
    /// Change playback state via stop.
    pub fn stop(&mut self, key: SoundKey) {
        if let Some(entry) = self.sources.get_mut(key) {
            if let Some(sink) = entry.sink.take() {
                sink.stop();
            }
            entry.play_state = PlayState::Stopped;
            entry.play_start = None;
            entry.accumulated_secs = 0.0;
        }
    }
    /// Set volume.
    pub fn set_volume(&mut self, key: SoundKey, volume: f32) {
        let vol = volume.clamp(0.0, 2.0);
        if let Some(entry) = self.sources.get_mut(key) {
            entry.volume = vol;
            if let Some(ref sink) = entry.sink {
                sink.set_volume(vol * self.master_volume);
            }
        }
    }
    /// Return volume.
    pub fn get_volume(&self, key: SoundKey) -> f32 {
        self.sources.get(key).map_or(1.0, |e| e.volume)
    }
    /// Change playback state via pause.
    pub fn pause(&mut self, key: SoundKey) {
        if let Some(entry) = self.sources.get_mut(key) {
            if let Some(ref sink) = entry.sink {
                sink.pause();
            }
            if entry.play_state == PlayState::Playing {
                entry.accumulated_secs += entry
                    .play_start
                    .map(|t| t.elapsed().as_secs_f32())
                    .unwrap_or(0.0);
                entry.play_start = None;
            }
            entry.play_state = PlayState::Paused;
        }
    }
    /// Change playback state via resume.
    pub fn resume(&mut self, key: SoundKey) {
        if let Some(entry) = self.sources.get_mut(key) {
            if let Some(ref sink) = entry.sink {
                sink.play();
            }
            if entry.play_state == PlayState::Paused {
                entry.play_start = Some(Instant::now());
            }
            entry.play_state = PlayState::Playing;
        }
    }
    /// Set pitch.
    pub fn set_pitch(&mut self, key: SoundKey, pitch: f32) {
        let p = pitch.clamp(0.1, 4.0);
        if let Some(entry) = self.sources.get_mut(key) {
            entry.pitch = p;
            if let Some(ref sink) = entry.sink {
                sink.set_speed(p);
            }
        }
    }
    /// Return pitch.
    pub fn get_pitch(&self, key: SoundKey) -> f32 {
        self.sources.get(key).map_or(1.0, |e| e.pitch)
    }
    /// Set speed.
    pub fn set_speed(&mut self, key: SoundKey, speed: f32) {
        self.set_pitch(key, speed);
    }
    /// Return whether playing.
    pub fn is_playing(&self, key: SoundKey) -> bool {
        if let Some(entry) = self.sources.get(key) {
            if let Some(ref sink) = entry.sink {
                return !sink.is_paused() && !sink.empty();
            }
        }
        false
    }
    /// Return play_state.
    pub fn get_play_state(&self, key: SoundKey) -> PlayState {
        if let Some(entry) = self.sources.get(key) {
            if let Some(ref sink) = entry.sink {
                if sink.empty() {
                    return PlayState::Stopped;
                }
                if sink.is_paused() {
                    return PlayState::Paused;
                }
                return PlayState::Playing;
            }
            return entry.play_state;
        }
        PlayState::Stopped
    }
    /// Return whether paused.
    pub fn is_paused(&self, key: SoundKey) -> bool {
        self.get_play_state(key) == PlayState::Paused
    }
    /// Return whether stopped.
    pub fn is_stopped(&self, key: SoundKey) -> bool {
        self.get_play_state(key) == PlayState::Stopped
    }
    /// Set looping.
    pub fn set_looping(&mut self, key: SoundKey, looping: bool) {
        if let Some(entry) = self.sources.get_mut(key) {
            entry.looping = looping;
        }
    }
    /// Return whether looping.
    pub fn is_looping(&self, key: SoundKey) -> bool {
        self.sources.get(key).is_some_and(|e| e.looping)
    }
    /// Update state in play_looping.
    pub fn play_looping(&mut self, key: SoundKey, game_dir: &Path) {
        self.set_looping(key, true);
        self.play(key, game_dir);
    }
    /// Set pan.
    pub fn set_pan(&mut self, key: SoundKey, pan: f32) {
        if let Some(entry) = self.sources.get_mut(key) {
            entry.pan = pan.clamp(-1.0, 1.0);
        }
    }
    /// Return pan.
    pub fn get_pan(&self, key: SoundKey) -> f32 {
        self.sources.get(key).map_or(0.0, |e| e.pan)
    }
    /// Set master_volume.
    pub fn set_master_volume(&mut self, volume: f32) {
        self.master_volume = volume.clamp(0.0, 1.0);
        for entry in self.sources.values() {
            if let Some(ref sink) = entry.sink {
                sink.set_volume(entry.volume * self.master_volume);
            }
        }
    }
    /// Return master_volume.
    pub fn get_master_volume(&self) -> f32 {
        self.master_volume
    }
    /// Return source_type.
    pub fn get_source_type(&self, key: SoundKey) -> Option<SourceType> {
        self.sources.get(key).map(|e| e.source_type)
    }
    /// Return active_source_count.
    pub fn get_active_source_count(&self) -> usize {
        self.sources
            .values()
            .filter(|e| {
                if let Some(ref sink) = e.sink {
                    !sink.empty() && !sink.is_paused()
                } else {
                    false
                }
            })
            .count()
    }
    /// Return source_count.
    pub fn get_source_count(&self) -> usize {
        self.sources.len()
    }
    /// Return contains_source result.
    pub fn contains_source(&self, key: SoundKey) -> bool {
        self.sources.contains_key(key)
    }
    /// Update state in pause_all.
    pub fn pause_all(&mut self) {
        for entry in self.sources.values_mut() {
            if let Some(ref sink) = entry.sink {
                sink.pause();
            }
            if entry.play_state == PlayState::Playing {
                entry.accumulated_secs += entry
                    .play_start
                    .map(|t| t.elapsed().as_secs_f32())
                    .unwrap_or(0.0);
                entry.play_start = None;
                entry.play_state = PlayState::Paused;
            }
        }
    }
    /// Update state in stop_all.
    pub fn stop_all(&mut self) {
        for entry in self.sources.values_mut() {
            if let Some(sink) = entry.sink.take() {
                sink.stop();
            }
            entry.play_state = PlayState::Stopped;
            entry.play_start = None;
            entry.accumulated_secs = 0.0;
        }
    }
    /// Update state in resume_all.
    pub fn resume_all(&mut self) {
        for entry in self.sources.values_mut() {
            if let Some(ref sink) = entry.sink {
                sink.play();
            }
            if entry.play_state == PlayState::Paused {
                entry.play_start = Some(Instant::now());
                entry.play_state = PlayState::Playing;
            }
        }
    }
    /// Return clone_source result.
    pub fn clone_source(&mut self, key: SoundKey) -> Option<SoundKey> {
        let entry = self.sources.get(key)?;
        let new_entry = AudioEntry {
            file_path: entry.file_path.clone(),
            sink: None,
            source_type: entry.source_type,
            decoded_data: entry.decoded_data.clone(),
            looping: entry.looping,
            volume: entry.volume,
            pitch: entry.pitch,
            pan: entry.pan,
            play_state: PlayState::Stopped,
            bus_key: entry.bus_key,
            duration_secs: entry.duration_secs,
            play_start: None,
            accumulated_secs: 0.0,
            lowpass_cutoff: entry.lowpass_cutoff,
            highpass_cutoff: entry.highpass_cutoff,
            fade_in_duration: entry.fade_in_duration,
            spatial: entry.spatial,
            stereo_width: entry.stereo_width,
            pitch_range: entry.pitch_range,
            peak: entry.peak,
        };
        Some(self.sources.insert(new_entry))
    }
    /// Return release result.
    pub fn release(&mut self, key: SoundKey) -> bool {
        if let Some(entry) = self.sources.remove(key) {
            if let Some(sink) = entry.sink {
                sink.stop();
            }
            true
        } else {
            false
        }
    }
    /// Set peak.
    pub fn set_peak(&mut self, key: SoundKey, peak: f32) {
        if let Some(entry) = self.sources.get_mut(key) {
            entry.peak = peak.clamp(0.0, 1.0);
        }
    }
    /// Return peak.
    pub fn get_peak(&self, key: SoundKey) -> f32 {
        self.sources.get(key).map_or(0.0, |e| e.peak)
    }
    /// Return bus_peak result.
    pub fn bus_peak(&self, bus_key: BusKey) -> f32 {
        let mut total = 0.0f32;
        let mut count = 0usize;
        for (_, entry) in &self.sources {
            if entry.bus_key == Some(bus_key) {
                total += entry.peak;
                count += 1;
            }
        }
        if count == 0 {
            0.0
        } else {
            total / count as f32
        }
    }
    /// Return new_bus result.
    pub fn new_bus(&mut self, name: impl Into<String>) -> BusKey {
        self.buses.insert(Bus::new(name))
    }
    /// Return bus_by_name.
    pub fn get_bus_by_name(&self, name: &str) -> Option<BusKey> {
        self.buses
            .iter()
            .find(|(_, b)| b.name() == name)
            .map(|(k, _)| k)
    }
    /// Return bus.
    pub fn get_bus(&self, key: BusKey) -> Option<&Bus> {
        self.buses.get(key)
    }
    /// Return bus_mut.
    pub fn get_bus_mut(&mut self, key: BusKey) -> Option<&mut Bus> {
        self.buses.get_mut(key)
    }
    /// Set source_bus.
    pub fn set_source_bus(&mut self, key: SoundKey, bus_key: Option<BusKey>) {
        if let Some(entry) = self.sources.get_mut(key) {
            entry.bus_key = bus_key;
        }
    }
    /// Return source_bus.
    pub fn get_source_bus(&self, key: SoundKey) -> Option<BusKey> {
        self.sources.get(key).and_then(|e| e.bus_key)
    }
    /// Return duration.
    pub fn get_duration(&self, key: SoundKey) -> Option<f32> {
        self.sources.get(key).and_then(|e| e.duration_secs)
    }
    /// Return tell.
    pub fn get_tell(&self, key: SoundKey) -> f32 {
        if let Some(entry) = self.sources.get(key) {
            match entry.play_state {
                PlayState::Playing => {
                    entry.accumulated_secs
                        + entry
                            .play_start
                            .map(|t| t.elapsed().as_secs_f32())
                            .unwrap_or(0.0)
                }
                PlayState::Paused => entry.accumulated_secs,
                PlayState::Stopped => 0.0,
            }
        } else {
            0.0
        }
    }
    #[allow(clippy::too_many_arguments)]
    fn build_sink(
        handle: &rodio::OutputStreamHandle,
        file_path: &str,
        source_type: SourceType,
        decoded_data: Option<&Arc<Vec<u8>>>,
        game_dir: &Path,
        skip_secs: f32,
        volume: f32,
        pitch: f32,
        pan: f32,
        looping: bool,
        lowpass_cutoff: Option<u32>,
        highpass_cutoff: Option<u32>,
        fade_in_duration: Option<f32>,
        bus_effects: Option<std::sync::Arc<std::sync::RwLock<Vec<std::sync::Arc<EffectParams>>>>>,
    ) -> Option<(rodio::Sink, Option<f32>)> {
        let (source, duration, channels) = if source_type == SourceType::Static {
            let data = decoded_data?;
            let cursor = std::io::Cursor::new((**data).clone());
            let dec = rodio::Decoder::new(cursor).ok()?;
            let dur = dec.total_duration().map(|d| d.as_secs_f32());
            let ch = dec.channels() as usize;
            let src: Box<dyn rodio::Source<Item = i16> + Send> = Box::new(dec);
            (src, dur, ch)
        } else {
            let path = game_dir.join(file_path);
            let f = std::fs::File::open(&path).ok()?;
            let dec = rodio::Decoder::new(BufReader::new(f)).ok()?;
            let dur = dec.total_duration().map(|d| d.as_secs_f32());
            let ch = dec.channels() as usize;
            let src: Box<dyn rodio::Source<Item = i16> + Send> = Box::new(dec);
            (src, dur, ch)
        };
        let source: Box<dyn rodio::Source<Item = i16> + Send> = if skip_secs > 0.0 {
            Box::new(source.skip_duration(std::time::Duration::from_secs_f32(skip_secs)))
        } else {
            source
        };
        let source: Box<dyn rodio::Source<Item = i16> + Send> = if let Some(dur) = fade_in_duration
        {
            Box::new(source.fade_in(std::time::Duration::from_secs_f32(dur)))
        } else {
            source
        };
        let source: Box<dyn rodio::Source<Item = i16> + Send> =
            if lowpass_cutoff.is_some() || highpass_cutoff.is_some() || bus_effects.is_some() {
                let f32_src: Box<dyn rodio::Source<Item = f32> + Send> =
                    Box::new(source.convert_samples::<f32>());
                let f32_src: Box<dyn rodio::Source<Item = f32> + Send> =
                    if let Some(cutoff) = lowpass_cutoff {
                        Box::new(f32_src.low_pass(cutoff))
                    } else {
                        f32_src
                    };
                let f32_src: Box<dyn rodio::Source<Item = f32> + Send> =
                    if let Some(cutoff) = highpass_cutoff {
                        Box::new(f32_src.high_pass(cutoff))
                    } else {
                        f32_src
                    };
                let f32_src: Box<dyn rodio::Source<Item = f32> + Send> =
                    if let Some(effects) = bus_effects {
                        Box::new(DynamicEffectSource::new(f32_src, effects))
                    } else {
                        f32_src
                    };
                Box::new(f32_src.convert_samples::<i16>())
            } else {
                source
            };
        let mut volumes = vec![1.0f32; channels.max(1)];
        if channels >= 2 {
            volumes[0] = 1.0 - pan.max(0.0);
            volumes[1] = 1.0 + pan.min(0.0);
        }
        let panned = rodio::source::ChannelVolume::new(source, volumes);
        let sink = rodio::Sink::try_new(handle).ok()?;
        sink.set_volume(volume);
        sink.set_speed(pitch);
        if looping {
            sink.append(panned.repeat_infinite());
        } else {
            sink.append(panned);
        }
        Some((sink, duration))
    }
    /// Update state in seek.
    pub fn seek(&mut self, key: SoundKey, position_secs: f32, game_dir: &Path) {
        let master_vol = self.master_volume;
        let params = {
            let entry = match self.sources.get(key) {
                Some(e) => e,
                None => return,
            };
            let clamped = position_secs
                .max(0.0)
                .min(entry.duration_secs.unwrap_or(f32::MAX));
            (
                entry.file_path.clone(),
                entry.source_type,
                entry.decoded_data.clone(),
                entry.volume * master_vol,
                entry.pitch,
                entry.pan,
                entry.looping,
                entry.lowpass_cutoff,
                entry.highpass_cutoff,
                entry.fade_in_duration,
                entry.play_state,
                entry.bus_key,
                clamped,
            )
        };
        let (
            file_path,
            source_type,
            decoded_data,
            volume,
            pitch,
            pan,
            looping,
            lowpass_cutoff,
            highpass_cutoff,
            fade_in_dur,
            play_state,
            bus_key,
            pos,
        ) = params;
        let (bus_vol, bus_pitch) = bus_key
            .and_then(|bk| self.buses.get(bk))
            .map(|b| (b.volume(), b.pitch()))
            .unwrap_or((1.0, 1.0));
        let final_vol = volume * bus_vol;
        let final_pitch = pitch * bus_pitch;
        let was_active = matches!(play_state, PlayState::Playing | PlayState::Paused);
        if let Some(entry) = self.sources.get_mut(key) {
            if let Some(sink) = entry.sink.take() {
                sink.stop();
            }
            entry.accumulated_secs = pos;
            entry.play_start = None;
            entry.play_state = PlayState::Stopped;
        }
        if was_active {
            if let Some(handle) = self.stream_handle.as_ref() {
                let maybe = Self::build_sink(
                    handle,
                    &file_path,
                    source_type,
                    decoded_data.as_ref(),
                    game_dir,
                    pos,
                    final_vol,
                    final_pitch,
                    pan,
                    looping,
                    lowpass_cutoff,
                    highpass_cutoff,
                    fade_in_dur,
                    bus_key
                        .and_then(|bk| self.buses.get(bk))
                        .map(|b| std::sync::Arc::clone(&b.effects)),
                );
                if let Some((sink, duration)) = maybe {
                    if let Some(entry) = self.sources.get_mut(key) {
                        if entry.duration_secs.is_none() {
                            entry.duration_secs = duration;
                        }
                        entry.sink = Some(sink);
                        entry.play_state = PlayState::Playing;
                        entry.play_start = Some(Instant::now());
                    }
                }
            }
        }
    }
    /// Set lowpass.
    pub fn set_lowpass(&mut self, key: SoundKey, cutoff_hz: u32) {
        if let Some(e) = self.sources.get_mut(key) {
            e.lowpass_cutoff = Some(cutoff_hz);
        }
    }
    /// Update state in clear_lowpass.
    pub fn clear_lowpass(&mut self, key: SoundKey) {
        if let Some(e) = self.sources.get_mut(key) {
            e.lowpass_cutoff = None;
        }
    }
    /// Set highpass.
    pub fn set_highpass(&mut self, key: SoundKey, cutoff_hz: u32) {
        if let Some(e) = self.sources.get_mut(key) {
            e.highpass_cutoff = Some(cutoff_hz);
        }
    }
    /// Update state in clear_highpass.
    pub fn clear_highpass(&mut self, key: SoundKey) {
        if let Some(e) = self.sources.get_mut(key) {
            e.highpass_cutoff = None;
        }
    }
    /// Update state in clear_filter.
    pub fn clear_filter(&mut self, key: SoundKey) {
        if let Some(e) = self.sources.get_mut(key) {
            e.lowpass_cutoff = None;
            e.highpass_cutoff = None;
        }
    }
    /// Return lowpass.
    pub fn get_lowpass(&self, key: SoundKey) -> Option<u32> {
        self.sources.get(key).and_then(|e| e.lowpass_cutoff)
    }
    /// Return highpass.
    pub fn get_highpass(&self, key: SoundKey) -> Option<u32> {
        self.sources.get(key).and_then(|e| e.highpass_cutoff)
    }
    /// Set fade_in.
    pub fn set_fade_in(&mut self, key: SoundKey, duration_secs: f32) {
        if let Some(e) = self.sources.get_mut(key) {
            e.fade_in_duration = Some(duration_secs.max(0.0));
        }
    }
    /// Update state in clear_fade_in.
    pub fn clear_fade_in(&mut self, key: SoundKey) {
        if let Some(e) = self.sources.get_mut(key) {
            e.fade_in_duration = None;
        }
    }
    /// Return fade_in.
    pub fn get_fade_in(&self, key: SoundKey) -> Option<f32> {
        self.sources.get(key).and_then(|e| e.fade_in_duration)
    }
    /// Set source_position.
    pub fn set_source_position(&mut self, key: SoundKey, x: f32, y: f32, z: f32) {
        if let Some(entry) = self.sources.get_mut(key) {
            let state = entry
                .spatial
                .get_or_insert_with(crate::audio::SpatialState::default);
            state.position = [x, y, z];
            let dx = x - self.listener_position[0];
            entry.pan = (dx / 200.0).clamp(-1.0, 1.0);
        }
    }
    /// Return source_position.
    pub fn get_source_position(&self, key: SoundKey) -> [f32; 3] {
        self.sources
            .get(key)
            .and_then(|e| e.spatial.as_ref())
            .map(|s| s.position)
            .unwrap_or([0.0, 0.0, 0.0])
    }
    /// Set source_velocity.
    pub fn set_source_velocity(&mut self, key: SoundKey, x: f32, y: f32, z: f32) {
        if let Some(entry) = self.sources.get_mut(key) {
            let state = entry
                .spatial
                .get_or_insert_with(crate::audio::SpatialState::default);
            state.velocity = [x, y, z];
        }
    }
    /// Return source_velocity.
    pub fn get_source_velocity(&self, key: SoundKey) -> [f32; 3] {
        self.sources
            .get(key)
            .and_then(|e| e.spatial.as_ref())
            .map(|s| s.velocity)
            .unwrap_or([0.0, 0.0, 0.0])
    }
    #[allow(clippy::too_many_arguments)]
    pub fn set_source_orientation(
        &mut self,
        key: SoundKey,
        fx: f32,
        fy: f32,
        fz: f32,
        ux: f32,
        uy: f32,
        uz: f32,
    ) {
        if let Some(entry) = self.sources.get_mut(key) {
            let state = entry
                .spatial
                .get_or_insert_with(crate::audio::SpatialState::default);
            state.orientation = [fx, fy, fz, ux, uy, uz];
        }
    }
    /// Return source_orientation.
    pub fn get_source_orientation(&self, key: SoundKey) -> [f32; 6] {
        self.sources
            .get(key)
            .and_then(|e| e.spatial.as_ref())
            .map(|s| s.orientation)
            .unwrap_or([0.0, 0.0, -1.0, 0.0, 1.0, 0.0])
    }
    /// Set listener_position.
    pub fn set_listener_position(&mut self, x: f32, y: f32, z: f32) {
        self.listener_position = [x, y, z];
    }
    /// Return listener_position.
    pub fn get_listener_position(&self) -> [f32; 3] {
        self.listener_position
    }
    #[allow(clippy::too_many_arguments)]
    pub fn set_listener_orientation(
        &mut self,
        fx: f32,
        fy: f32,
        fz: f32,
        ux: f32,
        uy: f32,
        uz: f32,
    ) {
        self.listener_orientation = [fx, fy, fz, ux, uy, uz];
    }
    /// Return listener_orientation.
    pub fn get_listener_orientation(&self) -> [f32; 6] {
        self.listener_orientation
    }
    /// Set listener_velocity.
    pub fn set_listener_velocity(&mut self, x: f32, y: f32, z: f32) {
        self.listener_velocity = [x, y, z];
    }
    /// Return listener_velocity.
    pub fn get_listener_velocity(&self) -> [f32; 3] {
        self.listener_velocity
    }
    /// Set doppler_scale.
    pub fn set_doppler_scale(&mut self, scale: f32) {
        self.doppler_scale = scale.max(0.0);
    }
    /// Return doppler_scale.
    pub fn get_doppler_scale(&self) -> f32 {
        self.doppler_scale
    }
    /// Set distance_model.
    pub fn set_distance_model(&mut self, model: &str) {
        self.distance_model = model.to_string();
    }
    /// Return distance_model.
    pub fn get_distance_model(&self) -> &str {
        &self.distance_model
    }
    pub fn new_queueable(
        &mut self,
        sample_rate: u32,
        bit_depth: u8,
        channels: u8,
        buffer_count: usize,
    ) -> QueueableKey {
        self.queueables.insert(QueueableSource::new(
            sample_rate,
            bit_depth,
            channels,
            buffer_count,
        ))
    }
    /// Return queue_buffer result.
    pub fn queue_buffer(&mut self, key: QueueableKey, data: &[f32]) -> Result<(), EngineError> {
        self.queueables
            .get_mut(key)
            .ok_or_else(|| EngineError::AudioError("invalid queueable source key".to_string()))?
            .queue_buffer(data)
    }
    /// Return queueable_free_buffer_count result.
    pub fn queueable_free_buffer_count(&self, key: QueueableKey) -> usize {
        self.queueables
            .get(key)
            .map(QueueableSource::free_buffer_count)
            .unwrap_or(0)
    }
    /// Update state in play_queueable.
    pub fn play_queueable(&mut self, key: QueueableKey) {
        log_msg!(debug, A004_AUDIO_PLAY_QUEUED);
        let _ = key;
    }
    /// Update state in stop_queueable.
    pub fn stop_queueable(&mut self, key: QueueableKey) {
        if let Some(qs) = self.queueables.get_mut(key) {
            let cap = qs.buffer_count;
            qs.queued_buffers.clear();
            qs.free_buffers = cap;
        }
    }
    /// Return release_queueable result.
    pub fn release_queueable(&mut self, key: QueueableKey) -> bool {
        self.queueables.remove(key).is_some()
    }
    /// Return set_stereo_width result.
    pub fn set_stereo_width(&mut self, key: SoundKey, width: f32) -> Result<(), String> {
        let entry = self
            .sources
            .get_mut(key)
            .ok_or_else(|| "invalid SoundKey".to_string())?;
        entry.stereo_width = width;
        Ok(())
    }
    /// Return stereo_width.
    pub fn get_stereo_width(&self, key: SoundKey) -> Result<f32, String> {
        self.sources
            .get(key)
            .map(|e| e.stereo_width)
            .ok_or_else(|| "invalid SoundKey".to_string())
    }
    /// Return set_random_pitch result.
    pub fn set_random_pitch(&mut self, key: SoundKey, min: f32, max: f32) -> Result<(), String> {
        if min > max {
            return Err(format!("random pitch min ({}) > max ({})", min, max));
        }
        let entry = self
            .sources
            .get_mut(key)
            .ok_or_else(|| "invalid SoundKey".to_string())?;
        entry.pitch_range = Some((min, max));
        Ok(())
    }
    /// Update state in clear_random_pitch.
    pub fn clear_random_pitch(&mut self, key: SoundKey) {
        if let Some(entry) = self.sources.get_mut(key) {
            entry.pitch_range = None;
        }
    }
    pub fn crossfade(
        &mut self,
        from_key: SoundKey,
        to_key: SoundKey,
        duration_secs: f32,
        game_dir: &std::path::Path,
    ) {
        self.set_fade_in(to_key, duration_secs);
        self.play(to_key, game_dir);
        self.stop(from_key);
    }
    /// Return bus_peak.
    pub fn get_bus_peak(&self, bus_name: &str) -> Result<f32, String> {
        self.get_bus_by_name(bus_name)
            .map(|key| self.bus_peak(key))
            .ok_or_else(|| format!("unknown bus '{}'", bus_name))
    }
    /// Return bus_rms.
    pub fn get_bus_rms(&self, bus_name: &str) -> Result<f32, String> {
        self.get_bus_by_name(bus_name)
            .map(|_| 0.0_f32)
            .ok_or_else(|| format!("unknown bus '{}'", bus_name))
    }
    pub fn new_pool(
        &mut self,
        file_path: &str,
        voice_count: usize,
    ) -> Result<crate::audio::pool::SoundPool, String> {
        if voice_count == 0 {
            return Err("voice_count must be at least 1".to_string());
        }
        let keys: Vec<crate::runtime::resource_keys::SoundKey> = (0..voice_count)
            .map(|_| self.load_source(file_path, SourceType::Static))
            .collect();
        Ok(crate::audio::pool::SoundPool::new(
            keys,
            file_path.to_string(),
        ))
    }
}
