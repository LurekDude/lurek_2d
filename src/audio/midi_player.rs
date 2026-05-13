//! MIDI synthesis and playback (currently disabled; midly removed from Cargo.toml).


use crate::audio::PlayState;
use crate::runtime::resource_keys::BusKey;
// use midly::{MetaMessage, MidiMessage, Smf, TrackEventKind}; // MIDI disabled
// To re-enable: restore midly = "0.5" in Cargo.toml and uncomment imports + restore fn bodies from git
use rodio::Source;
// use std::collections::HashSet; // only needed for MIDI load_data (disabled)
use crate::log_msg;
use crate::runtime::log_messages::{A001_MIDI_READ_FAIL, A002_MIDI_DISABLED};
use std::path::Path;

/// Pre-parsed MIDI metadata: duration, tempo, track/channel info.
#[derive(Debug, Clone)]
pub struct MidiData {
    pub duration_secs: f64,
    pub ticks_per_beat: u16,
    pub original_tempo_bpm: f64,
    pub track_count: usize,
    pub track_names: Vec<Option<String>>,
    pub note_count: usize,
    pub channel_count: usize,
}

/// MIDI player with sine-additive synthesis (currently stub - midly disabled).
pub struct MidiPlayer {
    midi_data: Option<MidiData>,
    raw_midi: Option<Vec<u8>>,
    file_path: Option<String>,
    volume: f32,
    looping: bool,
    tempo_scale: f32,
    current_bpm: f64,
    channel_muted: [bool; 16],
    channel_volume: [f32; 16],
    channel_instrument: [u8; 16],
    track_muted: Vec<bool>,
    position_secs: f64,
    sink: Option<rodio::Sink>,
    play_state: PlayState,
    bus_key: Option<BusKey>,
    /// PCM output sample rate in Hz. Default 44100.
    /// Clamped to 8000-192000 by `set_output_sample_rate`.
    output_sample_rate: u32,
    /// PCM output channel count. Default 2 (stereo). Range: 1-2.
    output_channels: u16,
}

impl Default for MidiPlayer {
    fn default() -> Self {
        Self::new()
    }
}

impl MidiPlayer {
    /// Creates a new MidiPlayer with default settings.
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

    /// Loads and parses a MIDI file from the given path.
    /// Returns `true` if loading succeeded.
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

    /// Loads MIDI from raw bytes (stub - midly disabled).
    pub fn load_data(&mut self, _data: Vec<u8>) -> bool {
        // MIDI disabled: midly crate removed from Cargo.toml.
        // To re-enable: restore midly = "0.5" in Cargo.toml, uncomment the
        // midly/HashSet imports above, and restore the function body from git history.
        log_msg!(warn, A002_MIDI_DISABLED);
        false
    }

    /// Returns `true` if a MIDI file is loaded.
    pub fn is_loaded(&self) -> bool {
        self.midi_data.is_some()
    }

    /// Returns the MIDI file path, if any.
    pub fn file_path(&self) -> Option<&str> {
        self.file_path.as_deref()
    }

    /// Plays loaded MIDI, rendering to PCM with sine-additive synthesis.
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

    /// Stops playback and seeks to 0.
    pub fn stop(&mut self) {
        if let Some(sink) = self.sink.take() {
            sink.stop();
        }
        self.position_secs = 0.0;
        self.play_state = PlayState::Stopped;
    }

    /// Pauses playback.
    pub fn pause(&mut self) {
        if let Some(ref sink) = self.sink {
            sink.pause();
        }
        self.play_state = PlayState::Paused;
    }

    /// Resumes playback from pause.
    pub fn resume(&mut self) {
        if let Some(ref sink) = self.sink {
            sink.play();
        }
        if self.play_state == PlayState::Paused {
            self.play_state = PlayState::Playing;
        }
    }

    /// Returns `true` if player is playing.
    pub fn is_playing(&self) -> bool {
        self.play_state == PlayState::Playing
    }

    /// Returns `true` if player is paused.
    pub fn is_paused(&self) -> bool {
        self.play_state == PlayState::Paused
    }

    /// Seeks to position in seconds.
    pub fn seek(&mut self, secs: f64) {
        self.position_secs = secs.max(0.0);
    }

    /// Returns playback position in seconds.
    pub fn tell(&self) -> f64 {
        self.position_secs
    }

    /// Returns duration in seconds.
    pub fn duration(&self) -> f64 {
        self.midi_data.as_ref().map_or(0.0, |d| d.duration_secs)
    }

    /// Sets master volume, clamped >= 0.0.
    pub fn set_volume(&mut self, vol: f32) {
        self.volume = vol.max(0.0);
    }

    /// Returns master volume.
    pub fn volume(&self) -> f32 {
        self.volume
    }

    /// Sets whether playback loops.
    pub fn set_looping(&mut self, looping: bool) {
        self.looping = looping;
    }

    /// Returns `true` if looping is enabled.
    pub fn is_looping(&self) -> bool {
        self.looping
    }

    /// Sets tempo scale (clamped >= 0.01).
    pub fn set_tempo_scale(&mut self, scale: f32) {
        self.tempo_scale = scale.max(0.01);
    }

    /// Returns the tempo scale factor.
    pub fn tempo_scale(&self) -> f32 {
        self.tempo_scale
    }

    /// Returns current effective BPM.
    pub fn current_bpm(&self) -> f64 {
        self.current_bpm
    }

    /// Returns original MIDI tempo (BPM).
    pub fn original_tempo(&self) -> f64 {
        self.midi_data
            .as_ref()
            .map_or(120.0, |d| d.original_tempo_bpm)
    }

    /// Returns ticks-per-beat from MIDI header.
    pub fn ticks_per_beat(&self) -> u16 {
        self.midi_data.as_ref().map_or(0, |d| d.ticks_per_beat)
    }

    /// Sets volume for MIDI channel (0-15).
    pub fn set_channel_volume(&mut self, ch: usize, vol: f32) {
        if ch < 16 {
            self.channel_volume[ch] = vol.max(0.0);
        }
    }

    /// Returns the volume for a specific MIDI channel (0-15).
    pub fn channel_volume(&self, ch: usize) -> f32 {
        if ch < 16 {
            self.channel_volume[ch]
        } else {
            0.0
        }
    }

    /// Sets the mute state for a specific MIDI channel (0-15).
    pub fn set_channel_muted(&mut self, ch: usize, muted: bool) {
        if ch < 16 {
            self.channel_muted[ch] = muted;
        }
    }

    /// Returns whether a specific MIDI channel (0-15) is muted.
    pub fn is_channel_muted(&self, ch: usize) -> bool {
        ch < 16 && self.channel_muted[ch]
    }

    /// Sets the instrument (program number) for a MIDI channel (0-15).
    pub fn set_channel_instrument(&mut self, ch: usize, inst: u8) {
        if ch < 16 {
            self.channel_instrument[ch] = inst;
        }
    }

    /// Returns the instrument (program number) for a MIDI channel (0-15).
    pub fn channel_instrument(&self, ch: usize) -> u8 {
        if ch < 16 {
            self.channel_instrument[ch]
        } else {
            0
        }
    }

    /// Returns the number of unique MIDI channels used in the loaded file.
    pub fn channel_count(&self) -> usize {
        self.midi_data.as_ref().map_or(0, |d| d.channel_count)
    }

    /// Solos a channel (mutes all others).
    pub fn solo_channel(&mut self, ch: usize) {
        for i in 0..16 {
            self.channel_muted[i] = i != ch;
        }
    }

    /// Un-solos all channels (unmutes all).
    pub fn unsolo_all(&mut self) {
        self.channel_muted = [false; 16];
    }

    /// Returns the number of tracks in the loaded MIDI file.
    pub fn track_count(&self) -> usize {
        self.midi_data.as_ref().map_or(0, |d| d.track_count)
    }

    /// Returns the name of a track by index, if it has one.
    pub fn track_name(&self, idx: usize) -> Option<&str> {
        self.midi_data
            .as_ref()
            .and_then(|d| d.track_names.get(idx))
            .and_then(|n| n.as_deref())
    }

    /// Sets the mute state for a specific track by index.
    pub fn set_track_muted(&mut self, idx: usize, muted: bool) {
        if idx < self.track_muted.len() {
            self.track_muted[idx] = muted;
        }
    }

    /// Returns whether a specific track is muted.
    pub fn is_track_muted(&self, idx: usize) -> bool {
        idx < self.track_muted.len() && self.track_muted[idx]
    }

    /// Returns the total number of NoteOn events in the loaded MIDI.
    pub fn note_count(&self) -> usize {
        self.midi_data.as_ref().map_or(0, |d| d.note_count)
    }

    /// Sets the audio bus key for mixer routing.
    pub fn set_bus_key(&mut self, key: Option<BusKey>) {
        self.bus_key = key;
    }

    /// Returns the audio bus key, if assigned.
    pub fn bus_key(&self) -> Option<BusKey> {
        self.bus_key
    }

    /// Returns the current playback state.
    pub fn play_state(&self) -> PlayState {
        self.play_state
    }

    /// Returns the PCM output sample rate in Hz.
    pub fn get_output_sample_rate(&self) -> u32 {
        self.output_sample_rate
    }

    /// Sets the PCM output sample rate in Hz (clamped to 8000-192000).
    pub fn set_output_sample_rate(&mut self, rate: u32) {
        self.output_sample_rate = rate.clamp(8000, 192_000);
    }

    /// Returns the PCM output channel count (1 = mono, 2 = stereo).
    pub fn get_output_channels(&self) -> u16 {
        self.output_channels
    }

    /// Sets the PCM output channel count (clamped to 1-2).
    pub fn set_output_channels(&mut self, channels: u16) {
        self.output_channels = channels.clamp(1, 2);
    }

    /// Renders the loaded MIDI to a PCM buffer at the configured output sample rate and channel count.
    /// Uses sine-additive synthesis: each active note generates a sine wave
    /// at the MIDI note frequency, amplitude scaled by `velocity/127` and channel volume.
    fn render_to_pcm(&self) -> Vec<i16> {
        // MIDI disabled: midly crate removed. Returns empty buffer.
        // Original implementation is in git history.
        Vec::new()
    }
}

/// Converts a MIDI note number (0-127) to frequency in Hz.
/// A4 (note 69) = 440 Hz.
/// Kept for when MIDI is re-enabled (midly restored in Cargo.toml).
#[allow(dead_code)]
fn midi_note_to_freq(note: u8) -> f64 {
    440.0 * 2.0_f64.powf((note as f64 - 69.0) / 12.0)
}

/// Renders a single sine-wave note into a stereo PCM buffer.
/// Writes from `start_sample` to `end_sample` (exclusive), adding the sine value
/// to existing samples (additive synthesis). Amplitude is clamped to prevent overflow.
/// Kept for when MIDI is re-enabled (midly restored in Cargo.toml).
#[allow(dead_code)]
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
    let amp = (amplitude * 8000.0) as f64; // Scale to i16 range, leaving headroom

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

