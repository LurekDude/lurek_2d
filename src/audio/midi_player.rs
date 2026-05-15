
//! - `MidiPlayer` stateful transport controller for MIDI file playback via rendered PCM.
//! - File loading with parsed metadata: duration, BPM, ticks-per-beat, track names, note count.
//! - Transport controls: play, stop, pause, resume, seek, tell, and duration queries.
//! - Per-channel volume, mute, instrument, and solo/unsolo operations across 16 MIDI channels.
//! - Per-track mute support keyed by track index.
//! - Configurable tempo scaling, looping, and output sample rate / channel count.
//! - Mixer bus assignment via `BusKey` for routed playback.
//! - `MidiData` metadata struct storing parsed song-level attributes.
//! - Helper functions for MIDI note-to-frequency conversion and sine-wave note rendering.

use crate::audio::PlayState;
use crate::log_msg;
use crate::runtime::log_messages::{A001_MIDI_READ_FAIL, A002_MIDI_DISABLED};
use crate::runtime::resource_keys::BusKey;
use rodio::Source;
use std::path::Path;
#[derive(Debug, Clone)]
/// Parsed metadata extracted from a MIDI file and used for transport/introspection queries.
pub struct MidiData {
    /// Estimated total song duration in seconds.
    pub duration_secs: f64,
    /// MIDI division value: ticks per quarter note.
    pub ticks_per_beat: u16,
    /// Tempo from the file before applying `tempo_scale`.
    pub original_tempo_bpm: f64,
    /// Number of tracks in the MIDI container.
    pub track_count: usize,
    /// Optional per-track names in file order.
    pub track_names: Vec<Option<String>>,
    /// Total number of note-on events parsed from the file.
    pub note_count: usize,
    /// Number of channels that contain note data.
    pub channel_count: usize,
}
/// Stateful MIDI transport and playback controller backed by a rodio sink.
pub struct MidiPlayer {
    /// Parsed metadata for the loaded MIDI file.
    midi_data: Option<MidiData>,
    /// Raw MIDI bytes loaded from disk, used by the synthesis path.
    raw_midi: Option<Vec<u8>>,
    /// Source path of the currently loaded MIDI file.
    file_path: Option<String>,
    /// Output gain multiplier applied to the rodio sink.
    volume: f32,
    /// When true, playback loops the rendered PCM infinitely.
    looping: bool,
    /// Tempo multiplier applied to the original BPM.
    tempo_scale: f32,
    /// Current effective BPM used by playback timing.
    current_bpm: f64,
    /// Per-MIDI-channel mute flags.
    channel_muted: [bool; 16],
    /// Per-MIDI-channel volume multipliers.
    channel_volume: [f32; 16],
    /// Per-MIDI-channel program/instrument numbers.
    channel_instrument: [u8; 16],
    /// Per-track mute flags in track index order.
    track_muted: Vec<bool>,
    /// Transport playhead position in seconds.
    position_secs: f64,
    /// Active rodio sink playing rendered MIDI PCM.
    sink: Option<rodio::Sink>,
    /// Current transport state (`Stopped`, `Playing`, `Paused`).
    play_state: PlayState,
    /// Optional mixer bus assignment for this MIDI source.
    bus_key: Option<BusKey>,
    /// Sample rate used when rendering MIDI to PCM.
    output_sample_rate: u32,
    /// Output channel count for rendered MIDI PCM.
    output_channels: u16,
}
/// `Default` impl: return `MidiPlayer::new()`.
impl Default for MidiPlayer {
    /// Create default MIDI player state.
    fn default() -> Self {
        Self::new()
    }
}
impl MidiPlayer {
    /// Create a new MIDI player with default transport, channel, and output settings.
    pub fn new() -> Self {
        MidiPlayer {
            midi_data: None,
            raw_midi: None,
            file_path: None,
            volume: 1.0,
            looping: false,
            tempo_scale: 1.0,
            current_bpm: 120.0,
            channel_muted: [false; 16],
            channel_volume: [1.0; 16],
            channel_instrument: [0; 16],
            track_muted: Vec::new(),
            position_secs: 0.0,
            sink: None,
            play_state: PlayState::Stopped,
            bus_key: None,
            output_sample_rate: 44100,
            output_channels: 2,
        }
    }
    /// Load MIDI bytes from `path` and pass them to `load_data`; return `false` on read or parse failure.
    pub fn load(&mut self, path: &Path) -> bool {
        let bytes = match std::fs::read(path) {
            Ok(b) => b,
            Err(e) => {
                log_msg!(warn, A001_MIDI_READ_FAIL, "{:?}: {}", path, e);
                return false;
            }
        };
        let file_path = path.to_string_lossy().to_string();
        if self.load_data(bytes) {
            self.file_path = Some(file_path);
            true
        } else {
            false
        }
    }
    /// Parse and prepare raw MIDI bytes for playback; currently disabled and always return `false`.
    pub fn load_data(&mut self, _data: Vec<u8>) -> bool {
        log_msg!(warn, A002_MIDI_DISABLED);
        false
    }
    /// Return `true` when parsed MIDI metadata is present.
    pub fn is_loaded(&self) -> bool {
        self.midi_data.is_some()
    }
    /// Return the loaded MIDI file path, or `None` when no file is loaded.
    pub fn file_path(&self) -> Option<&str> {
        self.file_path.as_deref()
    }
    /// Render the loaded MIDI to PCM and start playback on `stream_handle`; no-op if data is missing.
    pub fn play(&mut self, stream_handle: &rodio::OutputStreamHandle) {
        if self.midi_data.is_none() || self.raw_midi.is_none() {
            return;
        }
        let pcm = self.render_to_pcm();
        if pcm.is_empty() {
            return;
        }
        let buffer =
            rodio::buffer::SamplesBuffer::new(self.output_channels, self.output_sample_rate, pcm);
        if let Ok(sink) = rodio::Sink::try_new(stream_handle) {
            sink.set_volume(self.volume);
            if self.looping {
                sink.append(buffer.repeat_infinite());
            } else {
                sink.append(buffer);
            }
            self.sink = Some(sink);
            self.play_state = PlayState::Playing;
        }
    }
    /// Stop playback, drop the sink, reset playhead to 0, and set state to `Stopped`.
    pub fn stop(&mut self) {
        if let Some(sink) = self.sink.take() {
            sink.stop();
        }
        self.position_secs = 0.0;
        self.play_state = PlayState::Stopped;
    }
    /// Pause the active sink and set state to `Paused`.
    pub fn pause(&mut self) {
        if let Some(ref sink) = self.sink {
            sink.pause();
        }
        self.play_state = PlayState::Paused;
    }
    /// Resume the active sink and transition from `Paused` to `Playing`.
    pub fn resume(&mut self) {
        if let Some(ref sink) = self.sink {
            sink.play();
        }
        if self.play_state == PlayState::Paused {
            self.play_state = PlayState::Playing;
        }
    }
    /// Return `true` when playback state is `Playing`.
    pub fn is_playing(&self) -> bool {
        self.play_state == PlayState::Playing
    }
    /// Return `true` when playback state is `Paused`.
    pub fn is_paused(&self) -> bool {
        self.play_state == PlayState::Paused
    }
    /// Move the transport playhead to `secs`, clamped to >= 0.0.
    pub fn seek(&mut self, secs: f64) {
        self.position_secs = secs.max(0.0);
    }
    /// Return the current transport playhead position in seconds.
    pub fn tell(&self) -> f64 {
        self.position_secs
    }
    /// Return song duration in seconds from metadata, or 0.0 if no MIDI is loaded.
    pub fn duration(&self) -> f64 {
        self.midi_data.as_ref().map_or(0.0, |d| d.duration_secs)
    }
    /// Set output gain multiplier; values below 0.0 are clamped to 0.0.
    pub fn set_volume(&mut self, vol: f32) {
        self.volume = vol.max(0.0);
    }
    /// Return the current output gain multiplier.
    pub fn volume(&self) -> f32 {
        self.volume
    }
    /// Enable or disable infinite playback looping.
    pub fn set_looping(&mut self, looping: bool) {
        self.looping = looping;
    }
    /// Return `true` when looping playback is enabled.
    pub fn is_looping(&self) -> bool {
        self.looping
    }
    /// Set tempo multiplier; clamped to at least 0.01.
    pub fn set_tempo_scale(&mut self, scale: f32) {
        self.tempo_scale = scale.max(0.01);
    }
    /// Return the current tempo multiplier.
    pub fn tempo_scale(&self) -> f32 {
        self.tempo_scale
    }
    /// Return the current effective BPM after tempo scaling.
    pub fn current_bpm(&self) -> f64 {
        self.current_bpm
    }
    /// Return original BPM from MIDI metadata, or 120.0 when metadata is unavailable.
    pub fn original_tempo(&self) -> f64 {
        self.midi_data
            .as_ref()
            .map_or(120.0, |d| d.original_tempo_bpm)
    }
    /// Return MIDI ticks-per-beat from metadata, or 0 when unavailable.
    pub fn ticks_per_beat(&self) -> u16 {
        self.midi_data.as_ref().map_or(0, |d| d.ticks_per_beat)
    }
    /// Set channel volume for channel `ch` in 0..16; ignored for out-of-range channels.
    pub fn set_channel_volume(&mut self, ch: usize, vol: f32) {
        if ch < 16 {
            self.channel_volume[ch] = vol.max(0.0);
        }
    }
    /// Return channel volume for `ch`, or 0.0 when `ch` is out of range.
    pub fn channel_volume(&self, ch: usize) -> f32 {
        if ch < 16 {
            self.channel_volume[ch]
        } else {
            0.0
        }
    }
    /// Set mute state for channel `ch` in 0..16; ignored for out-of-range channels.
    pub fn set_channel_muted(&mut self, ch: usize, muted: bool) {
        if ch < 16 {
            self.channel_muted[ch] = muted;
        }
    }
    /// Return `true` when channel `ch` is muted and in range.
    pub fn is_channel_muted(&self, ch: usize) -> bool {
        ch < 16 && self.channel_muted[ch]
    }
    /// Set program/instrument number for channel `ch` in 0..16; ignored when out of range.
    pub fn set_channel_instrument(&mut self, ch: usize, inst: u8) {
        if ch < 16 {
            self.channel_instrument[ch] = inst;
        }
    }
    /// Return instrument number for channel `ch`, or 0 when out of range.
    pub fn channel_instrument(&self, ch: usize) -> u8 {
        if ch < 16 {
            self.channel_instrument[ch]
        } else {
            0
        }
    }
    /// Return number of channels that contain note data in loaded metadata.
    pub fn channel_count(&self) -> usize {
        self.midi_data.as_ref().map_or(0, |d| d.channel_count)
    }
    /// Solo channel `ch` by muting all other channels.
    pub fn solo_channel(&mut self, ch: usize) {
        for i in 0..16 {
            self.channel_muted[i] = i != ch;
        }
    }
    /// Clear all channel mutes set by `solo_channel`.
    pub fn unsolo_all(&mut self) {
        self.channel_muted = [false; 16];
    }
    /// Return number of tracks in loaded metadata.
    pub fn track_count(&self) -> usize {
        self.midi_data.as_ref().map_or(0, |d| d.track_count)
    }
    /// Return optional track name for `idx`, or `None` if unavailable.
    pub fn track_name(&self, idx: usize) -> Option<&str> {
        self.midi_data
            .as_ref()
            .and_then(|d| d.track_names.get(idx))
            .and_then(|n| n.as_deref())
    }
    /// Set mute state for track `idx`; ignored if out of range.
    pub fn set_track_muted(&mut self, idx: usize, muted: bool) {
        if idx < self.track_muted.len() {
            self.track_muted[idx] = muted;
        }
    }
    /// Return `true` when track `idx` exists and is muted.
    pub fn is_track_muted(&self, idx: usize) -> bool {
        idx < self.track_muted.len() && self.track_muted[idx]
    }
    /// Return total note event count in loaded metadata.
    pub fn note_count(&self) -> usize {
        self.midi_data.as_ref().map_or(0, |d| d.note_count)
    }
    /// Assign or clear the mixer bus key used for this MIDI source.
    pub fn set_bus_key(&mut self, key: Option<BusKey>) {
        self.bus_key = key;
    }
    /// Return the assigned mixer bus key, if any.
    pub fn bus_key(&self) -> Option<BusKey> {
        self.bus_key
    }
    /// Return current transport state.
    pub fn play_state(&self) -> PlayState {
        self.play_state
    }
    /// Return output sample rate used by MIDI PCM rendering.
    pub fn get_output_sample_rate(&self) -> u32 {
        self.output_sample_rate
    }
    /// Set output sample rate, clamped to 8000..=192000 Hz.
    pub fn set_output_sample_rate(&mut self, rate: u32) {
        self.output_sample_rate = rate.clamp(8000, 192_000);
    }
    /// Return output channel count used by MIDI PCM rendering.
    pub fn get_output_channels(&self) -> u16 {
        self.output_channels
    }
    /// Set output channel count, clamped to mono or stereo (1..=2).
    pub fn set_output_channels(&mut self, channels: u16) {
        self.output_channels = channels.clamp(1, 2);
    }
    /// Render loaded MIDI to interleaved i16 PCM; currently return an empty buffer.
    fn render_to_pcm(&self) -> Vec<i16> {
        Vec::new()
    }
}
#[allow(dead_code)]
/// Convert a MIDI note number to frequency in Hz using A4=440 equal temperament.
fn midi_note_to_freq(note: u8) -> f64 {
    440.0 * 2.0_f64.powf((note as f64 - 69.0) / 12.0)
}
#[allow(dead_code)]
/// Render one sine note into an interleaved stereo PCM buffer over the sample range `[start, end)`.
fn render_note(
    pcm: &mut [i16],
    start: usize,
    end: usize,
    freq: f64,
    amplitude: f32,
    sample_rate: f64,
) {
    let end = end.min(pcm.len() / 2);
    let start = start.min(end);
    let amp = (amplitude * 8000.0) as f64;
    for i in start..end {
        let t = i as f64 / sample_rate;
        let sample = (amp * (2.0 * std::f64::consts::PI * freq * t).sin()) as i16;
        let idx = i * 2;
        if idx + 1 < pcm.len() {
            pcm[idx] = pcm[idx].saturating_add(sample);
            pcm[idx + 1] = pcm[idx + 1].saturating_add(sample);
        }
    }
}
