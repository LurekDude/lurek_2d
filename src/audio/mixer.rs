//! Core audio mixer that owns every loaded sound and drives playback through rodio.
//!
//! [`Mixer`] is the single point of entry for all audio operations in Lurek2D.  It opens the
//! system's default output stream on construction (via rodio) and maintains a slot-map of
//! [`AudioEntry`] records — one per loaded sound.  Each entry embeds a `rodio::Sink` for
//! playback control and cached metadata (duration, fade parameters, loop flag, filters).
//!
//! # Source types
//!
//! The mixer supports two loading strategies selected at load time:
//! - **Static** — the raw file bytes are decoded and held in an `Arc<Vec<u8>>` inside the
//!   entry.  Playback restarts by re-decoding from that in-memory buffer, giving very low
//!   latency at the cost of higher RAM usage.  Best for short sound effects.
//! - **Stream** — the file is opened fresh from disk on each play call and decoded
//!   incrementally.  Lower memory overhead for long music tracks.
//!
//! # Bus routing
//!
//! Every sound can be assigned to a named audio bus stored in a secondary slot-map.
//! Volume and pitch for a playing source are the product of the per-source values and the
//! values of its assigned bus.  Setting a bus to paused suspends every source on that bus.
//!
//! # Master volume
//!
//! A single master-volume scalar is applied on top of all per-source and per-bus volumes,
//! letting game code provide a global volume slider without touching individual sources.
//!
//! # Time tracking
//!
//! Because rodio `Sink` does not expose a playback position, the mixer tracks play-start
//! instants and accumulated pre-pause seconds manually so `lurek.audio.getTime` can return
//! the current position in the stream.

use std::collections::VecDeque;
use std::io::BufReader;
use std::path::Path;
use std::sync::Arc;

use crate::engine::log_messages::{A003_AUDIO_OUTPUT_UNAVAIL, A004_AUDIO_PLAY_QUEUED};
#[allow(unused_imports)]
use crate::log_msg;
use std::time::Instant;

use rodio::Source;
use slotmap::SlotMap;

use crate::audio::bus::Bus;
use crate::audio::dsp::{DynamicEffectSource, EffectParams};
use crate::engine::error::EngineError;
use crate::engine::resource_keys::BusKey;
use crate::engine::resource_keys::QueueableKey;
use crate::engine::resource_keys::SoundKey;

/// Type of audio source.
///
/// # Variants
/// - `Static` — Static variant.
/// - `Stream` — Stream variant.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum SourceType {
    /// Decoded to memory buffer — low latency, higher memory.
    Static,
    /// Streamed from file on playback — low memory.
    Stream,
}

/// Playback state of an audio source.
///
/// # Variants
/// - `Stopped` — Stopped variant.
/// - `Playing` — Playing variant.
/// - `Paused` — Paused variant.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum PlayState {
    /// Not playing, at beginning.
    Stopped,
    /// Currently playing.
    Playing,
    /// Playing but paused.
    Paused,
}

struct AudioEntry {
    file_path: String,
    sink: Option<rodio::Sink>,
    source_type: SourceType,
    decoded_data: Option<Arc<Vec<u8>>>,
    looping: bool,
    volume: f32,
    pitch: f32,
    pan: f32,
    play_state: PlayState,
    bus_key: Option<BusKey>,
    /// Cached total duration in seconds, computed on first play.
    duration_secs: Option<f32>,
    /// Instant when playback last started or resumed.
    play_start: Option<Instant>,
    /// Accumulated playback seconds before the last pause.
    accumulated_secs: f32,
    /// Lowpass filter cutoff frequency in Hz. `None` = no filter.
    lowpass_cutoff: Option<u32>,
    /// Highpass filter cutoff frequency in Hz. `None` = no filter.
    highpass_cutoff: Option<u32>,
    /// Fade-in duration in seconds applied on next play. `None` = no fade.
    fade_in_duration: Option<f32>,
    /// Optional 3D spatial state; `None` = non-spatial (no panning by position).
    spatial: Option<crate::audio::SpatialState>,
}

/// A manually-fed streaming audio source that accepts raw f32 PCM data pushed buffer-by-buffer.
///
/// Game code pushes audio data into the free-buffer queue via `queue_buffer`. The engine
/// counts how many buffers are still waiting to be consumed, giving game scripts control
/// over exactly when audio data is produced and played.
///
/// # Fields
/// - `sample_rate` — `u32`. PCM sample rate in Hz (e.g. 44100).
/// - `bit_depth` — `u8`. Bit depth per sample (8 or 16).
/// - `channels` — `u8`. Number of audio channels (1 = mono, 2 = stereo).
/// - `buffer_count` — `usize`. Maximum number of queued buffers.
/// - `queued_buffers` — `VecDeque<Vec<f32>>`. FIFO queue of pending f32 PCM buffers.
/// - `free_buffers` — `usize`. Number of buffer slots currently available.
pub struct QueueableSource {
    /// PCM sample rate in Hz (e.g. 44100).
    pub sample_rate: u32,
    /// Bit depth per sample (8 or 16).
    pub bit_depth: u8,
    /// Number of audio channels (1 = mono, 2 = stereo).
    pub channels: u8,
    /// Maximum number of queued buffers.
    pub buffer_count: usize,
    /// FIFO queue of pending raw f32 PCM buffers.
    pub queued_buffers: VecDeque<Vec<f32>>,
    /// Number of buffer slots currently available for new data.
    pub free_buffers: usize,
}

impl QueueableSource {
    /// Creates a new `QueueableSource` with all buffer slots free.
    ///
    /// # Parameters
    /// - `sample_rate` — `u32`. PCM sample rate in Hz.
    /// - `bit_depth` — `u8`. Bit depth per sample (8 or 16).
    /// - `channels` — `u8`. Channel count (1 = mono, 2 = stereo).
    /// - `buffer_count` — `usize`. Maximum queued buffers.
    ///
    /// # Returns
    /// `Self`.
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

    /// Pushes a buffer of f32 PCM samples into the queue.
    ///
    /// Returns `Err` if no free buffer slots remain.
    ///
    /// # Parameters
    /// - `data` — `&[f32]`. PCM samples to enqueue.
    ///
    /// # Returns
    /// `Result<(), EngineError>`.
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

    /// Returns the number of buffer slots currently available.
    ///
    /// # Returns
    /// `usize`.
    pub fn free_buffer_count(&self) -> usize {
        self.free_buffers
    }
}

///
/// The `Mixer` is the single point of entry for all audio operations in
/// Lurek2D. It owns a `SlotMap<SoundKey, AudioEntry>` for O(1) lookup and safe
/// handle invalidation, a `SlotMap<BusKey, Bus>` for named routing groups, and
/// a master volume applied on top of all per-source and per-bus values. Uses
/// `rodio::Sink` per source for independent playback control.
///
/// # Fields
/// - `_stream` — `Option<rodio::OutputStream>`.
/// - `stream_handle` — `Option<rodio::OutputStreamHandle>`.
/// - `sources` — `SlotMap<SoundKey, AudioEntry>`.
/// - `master_volume` — `f32`.
/// - `buses` — `SlotMap<BusKey, Bus>`.
/// - `listener_position` — `[f32; 3]`. Listener position for spatial audio.
/// - `listener_orientation` — `[f32; 6]`. Listener orientation (forward + up vectors).
/// - `listener_velocity` — `[f32; 3]`. Listener velocity for Doppler calculation.
/// - `doppler_scale` — `f32`. Global Doppler effect scale factor.
/// - `distance_model` — `String`. Distance attenuation model name.
/// - `queueables` — `SlotMap<QueueableKey, QueueableSource>`. Manually-fed streaming sources.
pub struct Mixer {
    _stream: Option<rodio::OutputStream>,
    stream_handle: Option<rodio::OutputStreamHandle>,
    sources: SlotMap<SoundKey, AudioEntry>,
    master_volume: f32,
    buses: SlotMap<BusKey, Bus>,
    /// Listener position `[x, y, z]` for spatial audio.
    listener_position: [f32; 3],
    /// Listener orientation: forward (xyz) followed by up (xyz).
    listener_orientation: [f32; 6],
    /// Listener velocity `[x, y, z]` for Doppler calculation.
    listener_velocity: [f32; 3],
    /// Global Doppler effect scale factor (1.0 = default, 0.0 = disabled).
    doppler_scale: f32,
    /// Distance attenuation model name (e.g. `"inverse_clamped"`).
    distance_model: String,
    /// Manually-fed queueable audio sources.
    queueables: SlotMap<QueueableKey, QueueableSource>,
}

impl Default for Mixer {
    fn default() -> Self {
        Self::new()
    }
}

impl Mixer {
    /// Creates a new `Mixer`, attempting to open the default system audio output.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Falls back gracefully (with a warning log) if no audio device is available,
    /// so the engine can run in headless or CI environments without crashing.
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
        }
    }

    /// Returns a reference to the output stream handle, if available.
    ///
    /// # Returns
    /// `Option<&rodio::OutputStreamHandle>`.
    ///
    /// Used by `MidiPlayer` to create its own `Sink` for playback.
    pub fn stream_handle(&self) -> Option<&rodio::OutputStreamHandle> {
        self.stream_handle.as_ref()
    }

    /// Registers a new audio file path with the given source type and returns its key.
    ///
    /// # Parameters
    /// - `file_path` — `&str`.
    /// - `source_type` — `SourceType`.
    ///
    /// # Returns
    /// `SoundKey`.
    ///
    /// The file is not opened here — loading is deferred until `play` is called.
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
        })
    }

    /// Plays the audio source identified by `key`, loading and decoding the file on demand.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    /// - `game_dir` — `&Path`.
    ///
    /// For static sources, decoded data is cached in memory on first play.
    /// Respects per-source volume, pitch, pan, looping, master volume, and active filters.
    pub fn play(&mut self, key: SoundKey, game_dir: &Path) {
        let master_vol = self.master_volume;

        // Look up bus parameters before borrowing sources mutably
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

        // For static sources, load data into memory if not already cached
        if let Some(entry) = self.sources.get_mut(key) {
            if entry.source_type == SourceType::Static && entry.decoded_data.is_none() {
                let path = game_dir.join(&entry.file_path);
                if let Ok(data) = std::fs::read(&path) {
                    entry.decoded_data = Some(Arc::new(data));
                }
            }
        }

        // Collect parameters — immutable borrow ends here
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

        // Build the sink
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

    /// Stops playback of a sound and resets its position to the beginning.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
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

    /// Sets the per-source playback volume, clamped to `[0.0, 2.0]`.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    /// - `volume` — `f32`.
    pub fn set_volume(&mut self, key: SoundKey, volume: f32) {
        let vol = volume.clamp(0.0, 2.0);
        if let Some(entry) = self.sources.get_mut(key) {
            entry.volume = vol;
            if let Some(ref sink) = entry.sink {
                sink.set_volume(vol * self.master_volume);
            }
        }
    }

    /// Returns the per-source playback volume. Defaults to `1.0`.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_volume(&self, key: SoundKey) -> f32 {
        self.sources.get(key).map_or(1.0, |e| e.volume)
    }

    /// Pauses playback of the audio source identified by \key\.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
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

    /// Resumes playback of a paused audio source identified by \key\.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
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

    /// Sets the playback speed (pitch) for the source, clamped to `[0.1, 4.0]`.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    /// - `pitch` — `f32`.
    pub fn set_pitch(&mut self, key: SoundKey, pitch: f32) {
        let p = pitch.clamp(0.1, 4.0);
        if let Some(entry) = self.sources.get_mut(key) {
            entry.pitch = p;
            if let Some(ref sink) = entry.sink {
                sink.set_speed(p);
            }
        }
    }

    /// Returns the pitch (playback speed) for the source. Defaults to `1.0`.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_pitch(&self, key: SoundKey) -> f32 {
        self.sources.get(key).map_or(1.0, |e| e.pitch)
    }

    /// Sets the playback speed (pitch) for the source, clamped to `[0.1, 4.0]`.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    /// - `speed` — `f32`.
    ///
    /// Legacy alias for `set_pitch`.
    pub fn set_speed(&mut self, key: SoundKey, speed: f32) {
        self.set_pitch(key, speed);
    }

    /// Returns whether the audio source is currently playing (not paused and not empty).
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_playing(&self, key: SoundKey) -> bool {
        if let Some(entry) = self.sources.get(key) {
            if let Some(ref sink) = entry.sink {
                return !sink.is_paused() && !sink.empty();
            }
        }
        false
    }

    /// Returns the playback state of the source, synced with the underlying sink.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    ///
    /// # Returns
    /// `PlayState`.
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

    /// Returns whether the source is paused. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_paused(&self, key: SoundKey) -> bool {
        self.get_play_state(key) == PlayState::Paused
    }

    /// Returns whether the source is stopped. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_stopped(&self, key: SoundKey) -> bool {
        self.get_play_state(key) == PlayState::Stopped
    }

    /// Sets the looping flag for the source. Takes effect on next `play` call.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    /// - `looping` — `bool`.
    pub fn set_looping(&mut self, key: SoundKey, looping: bool) {
        if let Some(entry) = self.sources.get_mut(key) {
            entry.looping = looping;
        }
    }

    /// Returns whether the source is set to loop.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_looping(&self, key: SoundKey) -> bool {
        self.sources.get(key).is_some_and(|e| e.looping)
    }

    /// Plays the audio source in an infinite loop.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    /// - `game_dir` — `&Path`.
    ///
    /// Sets looping to true and then calls `play`. Kept for backward compatibility.
    pub fn play_looping(&mut self, key: SoundKey, game_dir: &Path) {
        self.set_looping(key, true);
        self.play(key, game_dir);
    }

    /// Sets the stereo pan for the source, clamped to `[-1.0, 1.0]`.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    /// - `pan` — `f32`.
    ///
    /// `-1.0` = full left, `0.0` = center, `1.0` = full right.
    /// Applied via `rodio::source::ChannelVolume` on the next `play` call.
    pub fn set_pan(&mut self, key: SoundKey, pan: f32) {
        if let Some(entry) = self.sources.get_mut(key) {
            entry.pan = pan.clamp(-1.0, 1.0);
        }
    }

    /// Returns the stereo pan for the source. Defaults to `0.0` (center).
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_pan(&self, key: SoundKey) -> f32 {
        self.sources.get(key).map_or(0.0, |e| e.pan)
    }

    /// Sets the master volume applied to all sources, clamped to `[0.0, 1.0]`.
    ///
    /// # Parameters
    /// - `volume` — `f32`.
    pub fn set_master_volume(&mut self, volume: f32) {
        self.master_volume = volume.clamp(0.0, 1.0);
        for entry in self.sources.values() {
            if let Some(ref sink) = entry.sink {
                sink.set_volume(entry.volume * self.master_volume);
            }
        }
    }

    /// Returns the master volume. Defaults to `1.0`.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_master_volume(&self) -> f32 {
        self.master_volume
    }

    /// Returns the source type for the given key.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    ///
    /// # Returns
    /// `Option<SourceType>`.
    pub fn get_source_type(&self, key: SoundKey) -> Option<SourceType> {
        self.sources.get(key).map(|e| e.source_type)
    }

    /// Returns the number of actively playing (not paused, not empty) sources.
    ///
    /// # Returns
    /// `usize`.
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

    /// Returns the total number of loaded sources.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_source_count(&self) -> usize {
        self.sources.len()
    }

    /// Returns whether the given source key still refers to a loaded audio source.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    ///
    /// # Returns
    /// `bool`.
    pub fn contains_source(&self, key: SoundKey) -> bool {
        self.sources.contains_key(key)
    }

    /// Pauses all currently playing sources.
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

    /// Stops all sources and drops their sinks.
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

    /// Resumes all paused sources.
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

    /// Clones a source, sharing cached decoded data (for static sources).
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    ///
    /// # Returns
    /// `Option<SoundKey>`.
    ///
    /// The clone starts in Stopped state with no active sink.
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
        };
        Some(self.sources.insert(new_entry))
    }

    /// Stops and removes the audio source identified by `key`.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// Returns `true` if the source existed and was removed.
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

    /// Creates a new named bus and returns its key.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    ///
    /// # Returns
    /// `BusKey`.
    pub fn new_bus(&mut self, name: impl Into<String>) -> BusKey {
        self.buses.insert(Bus::new(name))
    }

    /// Returns an immutable reference to the bus, if it exists.
    ///
    /// # Parameters
    /// - `key` — `BusKey`.
    ///
    /// # Returns
    /// `Option<&Bus>`.
    pub fn get_bus_by_name(&self, name: &str) -> Option<BusKey> {
        self.buses
            .iter()
            .find(|(_, b)| b.name() == name)
            .map(|(k, _)| k)
    }

    /// Gets a bus by key.
    ///
    /// # Parameters
    /// - key — BusKey.
    ///
    /// # Returns
    /// Option<&Bus>.
    /// Gets bus.
    ///
    /// # Parameters
    /// - key — BusKey.
    ///
    /// # Returns
    /// Option<&Bus>.
    /// Gets bus.
    ///
    /// # Parameters
    /// - key — BusKey.
    ///
    /// # Returns
    /// Option<&Bus>.
    /// Gets bus.
    ///
    /// # Parameters
    /// - key — BusKey.
    ///
    /// # Returns
    /// Option<&Bus>.
    pub fn get_bus(&self, key: BusKey) -> Option<&Bus> {
        self.buses.get(key)
    }

    /// Returns a mutable reference to the bus, if it exists.
    ///
    /// # Parameters
    /// - `key` — `BusKey`.
    ///
    /// # Returns
    /// `Option<&mut Bus>`.
    pub fn get_bus_mut(&mut self, key: BusKey) -> Option<&mut Bus> {
        self.buses.get_mut(key)
    }

    /// Assigns a source to a bus. Pass `None` to remove the bus assignment.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    /// - `bus_key` — `Option<BusKey>`.
    pub fn set_source_bus(&mut self, key: SoundKey, bus_key: Option<BusKey>) {
        if let Some(entry) = self.sources.get_mut(key) {
            entry.bus_key = bus_key;
        }
    }

    /// Returns the bus key assigned to a source, if any.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    ///
    /// # Returns
    /// `Option<BusKey>`.
    pub fn get_source_bus(&self, key: SoundKey) -> Option<BusKey> {
        self.sources.get(key).and_then(|e| e.bus_key)
    }
    /// Returns the cached duration of the audio source in seconds, if known.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    ///
    /// # Returns
    /// `Option<f32>`.
    ///
    /// For static sources, duration is populated on first `play` call.
    /// Returns `None` if the source has never been played or if the decoder
    /// could not determine the duration (e.g. some streaming formats).
    pub fn get_duration(&self, key: SoundKey) -> Option<f32> {
        self.sources.get(key).and_then(|e| e.duration_secs)
    }

    /// Returns the approximate current playback position in seconds.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    ///
    /// # Returns
    /// `f32`.
    ///
    /// Based on wall-clock elapsed time. Returns `0.0` for stopped sources or
    /// invalid keys. When playing, includes accumulated time from previous
    /// play segments plus time elapsed since the last `play` or `resume`.
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

    /// Builds a rodio `Sink` from decoded audio, applying filters and effects.
    ///
    /// Supports `skip_duration` (seek), fade-in, lowpass/highpass filters (via f32 round-trip),
    /// and stereo pan via `ChannelVolume`. Returns the sink and cached source duration.
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
        // Decode audio and extract metadata
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

        // Skip duration for seek support
        let source: Box<dyn rodio::Source<Item = i16> + Send> = if skip_secs > 0.0 {
            Box::new(source.skip_duration(std::time::Duration::from_secs_f32(skip_secs)))
        } else {
            source
        };

        // Fade-in
        let source: Box<dyn rodio::Source<Item = i16> + Send> = if let Some(dur) = fade_in_duration
        {
            Box::new(source.fade_in(std::time::Duration::from_secs_f32(dur)))
        } else {
            source
        };

        // Lowpass / highpass filters — require f32 samples
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

        // Stereo pan via ChannelVolume
        let mut volumes = vec![1.0f32; channels.max(1)];
        if channels >= 2 {
            volumes[0] = 1.0 - pan.max(0.0);
            volumes[1] = 1.0 + pan.min(0.0);
        }
        let panned = rodio::source::ChannelVolume::new(source, volumes);

        // Create and configure sink
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

    /// Seeks the source to `position_secs` by rebuilding the sink from the new offset.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    /// - `position_secs` — `f32`.
    /// - `game_dir` — `&Path`.
    ///
    /// For stopped sources, updates `accumulated_secs` so `tell()` reflects the position.
    /// For playing or paused sources, stops the current sink and restarts from `position_secs`
    /// using `skip_duration`. No-op for invalid keys.
    pub fn seek(&mut self, key: SoundKey, position_secs: f32, game_dir: &Path) {
        let master_vol = self.master_volume;

        // Step 1: collect parameters (immutable borrow ends here)
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

        // Step 2: stop current sink and update accumulated position (mutable borrow)
        let was_active = matches!(play_state, PlayState::Playing | PlayState::Paused);
        if let Some(entry) = self.sources.get_mut(key) {
            if let Some(sink) = entry.sink.take() {
                sink.stop();
            }
            entry.accumulated_secs = pos;
            entry.play_start = None;
            entry.play_state = PlayState::Stopped;
        }

        // Step 3: rebuild sink from new position if source was active
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

    /// Sets a lowpass filter cutoff in Hz. Applied on next `play` or `seek`.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    /// - `cutoff_hz` — `u32`.
    pub fn set_lowpass(&mut self, key: SoundKey, cutoff_hz: u32) {
        if let Some(e) = self.sources.get_mut(key) {
            e.lowpass_cutoff = Some(cutoff_hz);
        }
    }

    /// Removes the lowpass filter from the source.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    pub fn clear_lowpass(&mut self, key: SoundKey) {
        if let Some(e) = self.sources.get_mut(key) {
            e.lowpass_cutoff = None;
        }
    }

    /// Sets a highpass filter cutoff in Hz. Applied on next `play` or `seek`.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    /// - `cutoff_hz` — `u32`.
    pub fn set_highpass(&mut self, key: SoundKey, cutoff_hz: u32) {
        if let Some(e) = self.sources.get_mut(key) {
            e.highpass_cutoff = Some(cutoff_hz);
        }
    }

    /// Removes the highpass filter from the source.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    pub fn clear_highpass(&mut self, key: SoundKey) {
        if let Some(e) = self.sources.get_mut(key) {
            e.highpass_cutoff = None;
        }
    }

    /// Removes all filters (lowpass and highpass) from the source.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    pub fn clear_filter(&mut self, key: SoundKey) {
        if let Some(e) = self.sources.get_mut(key) {
            e.lowpass_cutoff = None;
            e.highpass_cutoff = None;
        }
    }

    /// Returns the lowpass cutoff frequency in Hz, if set.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    ///
    /// # Returns
    /// `Option<u32>`.
    pub fn get_lowpass(&self, key: SoundKey) -> Option<u32> {
        self.sources.get(key).and_then(|e| e.lowpass_cutoff)
    }

    /// Returns the highpass cutoff frequency in Hz, if set.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    ///
    /// # Returns
    /// `Option<u32>`.
    pub fn get_highpass(&self, key: SoundKey) -> Option<u32> {
        self.sources.get(key).and_then(|e| e.highpass_cutoff)
    }

    /// Sets the fade-in duration in seconds. Applied on next `play`.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    /// - `duration_secs` — `f32`.
    pub fn set_fade_in(&mut self, key: SoundKey, duration_secs: f32) {
        if let Some(e) = self.sources.get_mut(key) {
            e.fade_in_duration = Some(duration_secs.max(0.0));
        }
    }

    /// Removes the fade-in setting from the source.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    pub fn clear_fade_in(&mut self, key: SoundKey) {
        if let Some(e) = self.sources.get_mut(key) {
            e.fade_in_duration = None;
        }
    }

    /// Returns the fade-in duration in seconds, if set.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    ///
    /// # Returns
    /// `Option<f32>`.
    pub fn get_fade_in(&self, key: SoundKey) -> Option<f32> {
        self.sources.get(key).and_then(|e| e.fade_in_duration)
    }

    // ── Spatial audio ────────────────────────────────────────────────────────

    /// Sets the 3D spatial position of an audio source.
    ///
    /// Also recomputes the `pan` value using 2D projection so the change takes
    /// effect immediately on the next `play` call.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`. The source to update.
    /// - `x` — `f32`. X position.
    /// - `y` — `f32`. Y position.
    /// - `z` — `f32`. Z position (accepted but projection uses x/y for panning).
    ///
    /// # Returns
    /// `()`.
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

    /// Returns the 3D spatial position of an audio source.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`. The source to query.
    ///
    /// # Returns
    /// `[f32; 3]` — `[x, y, z]` position, or `[0.0, 0.0, 0.0]` if not set.
    pub fn get_source_position(&self, key: SoundKey) -> [f32; 3] {
        self.sources
            .get(key)
            .and_then(|e| e.spatial.as_ref())
            .map(|s| s.position)
            .unwrap_or([0.0, 0.0, 0.0])
    }

    /// Sets the spatial velocity of an audio source (used for Doppler calculation).
    ///
    /// # Parameters
    /// - `key` — `SoundKey`. The source to update.
    /// - `x` — `f32`. X velocity.
    /// - `y` — `f32`. Y velocity.
    /// - `z` — `f32`. Z velocity.
    ///
    /// # Returns
    /// `()`.
    pub fn set_source_velocity(&mut self, key: SoundKey, x: f32, y: f32, z: f32) {
        if let Some(entry) = self.sources.get_mut(key) {
            let state = entry
                .spatial
                .get_or_insert_with(crate::audio::SpatialState::default);
            state.velocity = [x, y, z];
        }
    }

    /// Returns the spatial velocity of an audio source.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`. The source to query.
    ///
    /// # Returns
    /// `[f32; 3]` — velocity vector, or `[0.0, 0.0, 0.0]` if not set.
    pub fn get_source_velocity(&self, key: SoundKey) -> [f32; 3] {
        self.sources
            .get(key)
            .and_then(|e| e.spatial.as_ref())
            .map(|s| s.velocity)
            .unwrap_or([0.0, 0.0, 0.0])
    }

    /// Sets the spatial orientation of an audio source.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    /// - `fx` — `f32`. Forward x.
    /// - `fy` — `f32`. Forward y.
    /// - `fz` — `f32`. Forward z.
    /// - `ux` — `f32`. Up x.
    /// - `uy` — `f32`. Up y.
    /// - `uz` — `f32`. Up z.
    ///
    /// # Returns
    /// `()`.
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

    /// Returns the spatial orientation of an audio source.
    ///
    /// # Parameters
    /// - `key` — `SoundKey`.
    ///
    /// # Returns
    /// `[f32; 6]` — forward xyz followed by up xyz; defaults to `[0,0,-1, 0,1,0]`.
    pub fn get_source_orientation(&self, key: SoundKey) -> [f32; 6] {
        self.sources
            .get(key)
            .and_then(|e| e.spatial.as_ref())
            .map(|s| s.orientation)
            .unwrap_or([0.0, 0.0, -1.0, 0.0, 1.0, 0.0])
    }

    /// Sets the 3D listener position for spatial audio.
    ///
    /// # Parameters
    /// - `x` — `f32`. X position.
    /// - `y` — `f32`. Y position.
    /// - `z` — `f32`. Z position.
    ///
    /// # Returns
    /// `()`.
    pub fn set_listener_position(&mut self, x: f32, y: f32, z: f32) {
        self.listener_position = [x, y, z];
    }

    /// Returns the 3D listener position.
    ///
    /// # Returns
    /// `[f32; 3]`.
    pub fn get_listener_position(&self) -> [f32; 3] {
        self.listener_position
    }

    /// Sets the listener orientation (forward + up vectors).
    ///
    /// # Parameters
    /// - `fx` — `f32`. Forward x.
    /// - `fy` — `f32`. Forward y.
    /// - `fz` — `f32`. Forward z.
    /// - `ux` — `f32`. Up x.
    /// - `uy` — `f32`. Up y.
    /// - `uz` — `f32`. Up z.
    ///
    /// # Returns
    /// `()`.
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

    /// Returns the listener orientation (forward xyz + up xyz).
    ///
    /// # Returns
    /// `[f32; 6]`.
    pub fn get_listener_orientation(&self) -> [f32; 6] {
        self.listener_orientation
    }

    /// Sets the listener velocity for Doppler calculation.
    ///
    /// # Parameters
    /// - `x` — `f32`. X velocity.
    /// - `y` — `f32`. Y velocity.
    /// - `z` — `f32`. Z velocity.
    ///
    /// # Returns
    /// `()`.
    pub fn set_listener_velocity(&mut self, x: f32, y: f32, z: f32) {
        self.listener_velocity = [x, y, z];
    }

    /// Returns the listener velocity.
    ///
    /// # Returns
    /// `[f32; 3]`.
    pub fn get_listener_velocity(&self) -> [f32; 3] {
        self.listener_velocity
    }

    /// Sets the global Doppler effect scale.
    ///
    /// # Parameters
    /// - `scale` — `f32`. Multiplier; `1.0` = default, `0.0` = disabled.
    ///
    /// # Returns
    /// `()`.
    pub fn set_doppler_scale(&mut self, scale: f32) {
        self.doppler_scale = scale.max(0.0);
    }

    /// Returns the global Doppler effect scale.
    ///
    /// # Returns
    /// `f32` — current scale.
    pub fn get_doppler_scale(&self) -> f32 {
        self.doppler_scale
    }

    /// Sets the distance attenuation model.
    ///
    /// # Parameters
    /// - `model` — `&str`. One of `"none"`, `"inverse"`, `"inverse_clamped"`, `"linear"`, `"linear_clamped"`, `"exponent"`, `"exponent_clamped"`.
    ///
    /// # Returns
    /// `()`.
    pub fn set_distance_model(&mut self, model: &str) {
        self.distance_model = model.to_string();
    }

    /// Returns the current distance attenuation model name.
    ///
    /// # Returns
    /// `&str`.
    pub fn get_distance_model(&self) -> &str {
        &self.distance_model
    }

    // ── Queueable sources ────────────────────────────────────────────────────

    /// Creates a new queueable source and returns its key.
    ///
    /// # Parameters
    /// - `sample_rate` — `u32`. PCM sample rate in Hz.
    /// - `bit_depth` — `u8`. Bit depth per sample (8 or 16).
    /// - `channels` — `u8`. Channel count (1 = mono, 2 = stereo).
    /// - `buffer_count` — `usize`. Maximum number of queued buffers.
    ///
    /// # Returns
    /// `QueueableKey`.
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

    /// Pushes a buffer of f32 PCM samples into a queueable source.
    ///
    /// # Parameters
    /// - `key` — `QueueableKey`. The queueable source to push to.
    /// - `data` — `&[f32]`. PCM samples to enqueue.
    ///
    /// # Returns
    /// `Result<(), EngineError>`.
    pub fn queue_buffer(&mut self, key: QueueableKey, data: &[f32]) -> Result<(), EngineError> {
        self.queueables
            .get_mut(key)
            .ok_or_else(|| EngineError::AudioError("invalid queueable source key".to_string()))?
            .queue_buffer(data)
    }

    /// Returns the number of free buffer slots for a queueable source.
    ///
    /// # Parameters
    /// - `key` — `QueueableKey`.
    ///
    /// # Returns
    /// `usize`.
    pub fn queueable_free_buffer_count(&self, key: QueueableKey) -> usize {
        self.queueables
            .get(key)
            .map(QueueableSource::free_buffer_count)
            .unwrap_or(0)
    }

    /// Marks a queueable source as playing (state bookkeeping only; actual PCM playback
    /// is driven by game code dequeuing buffers via `queue_buffer`).
    ///
    /// # Parameters
    /// - `key` — `QueueableKey`.
    pub fn play_queueable(&mut self, key: QueueableKey) {
        // Queueable play is a no-op at the rodio level in this implementation;
        // game code controls output by queuing buffers.
        log_msg!(debug, A004_AUDIO_PLAY_QUEUED);
        let _ = key;
    }

    /// Stops a queueable source, draining all queued buffers.
    ///
    /// # Parameters
    /// - `key` — `QueueableKey`.
    pub fn stop_queueable(&mut self, key: QueueableKey) {
        if let Some(qs) = self.queueables.get_mut(key) {
            let cap = qs.buffer_count;
            qs.queued_buffers.clear();
            qs.free_buffers = cap;
        }
    }

    /// Releases a queueable source, removing it from the slot-map.
    ///
    /// # Parameters
    /// - `key` — `QueueableKey`.
    ///
    /// # Returns
    /// `bool` — `true` if the key was valid and the source was removed.
    pub fn release_queueable(&mut self, key: QueueableKey) -> bool {
        self.queueables.remove(key).is_some()
    }
}
