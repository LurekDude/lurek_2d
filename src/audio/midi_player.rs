//! Software MIDI synthesizer: parses MIDI with `midly`, renders to PCM
//! via sine-additive synthesis, and plays through a rodio `Sink`.
//!
//! This module is part of Lurek2D's `audio` subsystem and provides the implementation
//! details for midi player-related operations and data management.
//! Key types exported from this module: `MidiData`, `MidiPlayer`.
//! Primary functions: `new()`, `load()`, `load_data()`, `is_loaded()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use crate::audio::PlayState;
use crate::runtime::resource_keys::BusKey;
// use midly::{MetaMessage, MidiMessage, Smf, TrackEventKind}; // MIDI disabled
// To re-enable: restore midly = "0.5" in Cargo.toml and uncomment imports + restore fn bodies from git
use rodio::Source;
// use std::collections::HashSet; // only needed for MIDI load_data (disabled)
use crate::runtime::log_messages::{A001_MIDI_READ_FAIL, A002_MIDI_DISABLED};
use crate::log_msg;
use std::path::Path;

/// Pre-parsed MIDI metadata extracted during `load()`.
///
/// # Fields
/// - `duration_secs` — `f64`.
/// - `ticks_per_beat` — `u16`.
/// - `original_tempo_bpm` — `f64`.
/// - `track_count` — `usize`.
/// - `track_names` — `Vec<Option<String>>`.
/// - `note_count` — `usize`.
/// - `channel_count` — `usize`.
#[derive(Debug, Clone)]
pub struct MidiData {
    /// Total duration of the MIDI file in seconds.
    pub duration_secs: f64,
    /// Ticks per beat from the MIDI header.
    pub ticks_per_beat: u16,
    /// Original tempo in BPM (from the first tempo meta event, or 120 default).
    pub original_tempo_bpm: f64,
    /// Number of tracks in the MIDI file.
    pub track_count: usize,
    /// Track names extracted from TrackName meta events (None if unnamed).
    pub track_names: Vec<Option<String>>,
    /// Total number of NoteOn events across all tracks.
    pub note_count: usize,
    /// Number of unique MIDI channels used.
    pub channel_count: usize,
}

/// Software MIDI player with sine-additive synthesis.
///
/// Parses MIDI via `midly`, renders all tracks to a PCM buffer on `play()`,
/// and feeds the result into a `rodio::Sink`. Supports per-channel volume,
/// muting, track muting, tempo scaling, looping, and bus routing.
/// All synthesis is done on the Rust side so no external soundfont is needed
/// for basic MIDI playback (though `MidiState` enables SF2 loading).
///
/// # Fields
/// - `midi_data` — `Option<MidiData>`.
/// - `raw_midi` — `Option<Vec<u8>>`.
/// - `file_path` — `Option<String>`.
/// - `volume` — `f32`.
/// - `looping` — `bool`.
/// - `tempo_scale` — `f32`.
/// - `current_bpm` — `f64`.
/// - `channel_muted` — `[bool; 16]`.
/// - `channel_volume` — `[f32; 16]`.
/// - `channel_instrument` — `[u8; 16]`.
/// - `track_muted` — `Vec<bool>`.
/// - `position_secs` — `f64`.
/// - `sink` — `Option<rodio::Sink>`.
/// - `play_state` — `PlayState`.
/// - `bus_key` — `Option<BusKey>`.
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
}

impl Default for MidiPlayer {
    fn default() -> Self {
        Self::new()
    }
}

impl MidiPlayer {
    /// Creates a new MidiPlayer with default settings.
    ///
    /// # Returns
    /// `Self`.
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
        }
    }

    /// Loads and parses a MIDI file from the given path.
    ///
    /// # Parameters
    /// - `path` — `&Path`.
    ///
    /// # Returns
    /// `bool`.
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

    /// Loads MIDI from raw bytes (e.g., embedded data).
    ///
    /// # Parameters
    /// - `data` — `Vec<u8>`.
    ///
    /// # Returns
    /// `bool`.
    pub fn load_data(&mut self, _data: Vec<u8>) -> bool {
        // MIDI disabled: midly crate removed from Cargo.toml.
        // To re-enable: restore midly = "0.5" in Cargo.toml, uncomment the
        // midly/HashSet imports above, and restore the function body from git history.
        log_msg!(warn, A002_MIDI_DISABLED);
        false
    }

    /// Returns whether a MIDI file is currently loaded.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_loaded(&self) -> bool {
        self.midi_data.is_some()
    }

    /// Returns the file path of the loaded MIDI, if any.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn file_path(&self) -> Option<&str> {
        self.file_path.as_deref()
    }

    /// Plays the loaded MIDI through the given output stream handle.
    ///
    /// # Parameters
    /// - `stream_handle` — `&rodio::OutputStreamHandle`.
    /// Renders the full MIDI to PCM using sine-additive synthesis.
    pub fn play(&mut self, stream_handle: &rodio::OutputStreamHandle) {
        if self.midi_data.is_none() || self.raw_midi.is_none() {
            return;
        }

        let pcm = self.render_to_pcm();
        if pcm.is_empty() {
            return;
        }

        let buffer = rodio::buffer::SamplesBuffer::new(2, 44100, pcm);

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

    /// Stops playback and resets position to 0.
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

    /// Resumes paused playback.
    pub fn resume(&mut self) {
        if let Some(ref sink) = self.sink {
            sink.play();
        }
        if self.play_state == PlayState::Paused {
            self.play_state = PlayState::Playing;
        }
    }

    /// Returns whether the player is currently playing.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_playing(&self) -> bool {
        self.play_state == PlayState::Playing
    }

    /// Returns whether the player is paused. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_paused(&self) -> bool {
        self.play_state == PlayState::Paused
    }

    /// Seeks to a position in seconds.
    ///
    /// # Parameters
    /// - `secs` — `f64`.
    pub fn seek(&mut self, secs: f64) {
        self.position_secs = secs.max(0.0);
    }

    /// Returns the current playback position in seconds.
    ///
    /// # Returns
    /// `f64`.
    pub fn tell(&self) -> f64 {
        self.position_secs
    }

    /// Returns the duration of the loaded MIDI in seconds.
    ///
    /// # Returns
    /// `f64`.
    pub fn duration(&self) -> f64 {
        self.midi_data.as_ref().map_or(0.0, |d| d.duration_secs)
    }

    /// Sets the master volume (0.0 = silent, values above 1.0 amplify).
    ///
    /// # Parameters
    /// - `vol` — `f32`.
    pub fn set_volume(&mut self, vol: f32) {
        self.volume = vol.max(0.0);
    }

    /// Returns the master volume.
    ///
    /// # Returns
    /// `f32`.
    pub fn volume(&self) -> f32 {
        self.volume
    }

    /// Sets whether playback should loop. Replaces the current looping value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `looping` — `bool`.
    pub fn set_looping(&mut self, looping: bool) {
        self.looping = looping;
    }

    /// Returns whether playback is set to loop.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_looping(&self) -> bool {
        self.looping
    }

    /// Sets the tempo scale factor (minimum 0.01).
    ///
    /// # Parameters
    /// - `scale` — `f32`.
    pub fn set_tempo_scale(&mut self, scale: f32) {
        self.tempo_scale = scale.max(0.01);
    }

    /// Returns the current tempo scale factor.
    ///
    /// # Returns
    /// `f32`.
    pub fn tempo_scale(&self) -> f32 {
        self.tempo_scale
    }

    /// Returns the current effective BPM.
    ///
    /// # Returns
    /// `f64`.
    pub fn current_bpm(&self) -> f64 {
        self.current_bpm
    }

    /// Returns the original tempo in BPM from the MIDI file.
    ///
    /// # Returns
    /// `f64`.
    pub fn original_tempo(&self) -> f64 {
        self.midi_data
            .as_ref()
            .map_or(120.0, |d| d.original_tempo_bpm)
    }

    /// Returns the ticks-per-beat value from the MIDI header.
    ///
    /// # Returns
    /// `u16`.
    pub fn ticks_per_beat(&self) -> u16 {
        self.midi_data.as_ref().map_or(0, |d| d.ticks_per_beat)
    }

    /// Sets the volume for a specific MIDI channel (0-15).
    ///
    /// # Parameters
    /// - `ch` — `usize`.
    /// - `vol` — `f32`.
    pub fn set_channel_volume(&mut self, ch: usize, vol: f32) {
        if ch < 16 {
            self.channel_volume[ch] = vol.max(0.0);
        }
    }

    /// Returns the volume for a specific MIDI channel (0-15).
    ///
    /// # Parameters
    /// - `ch` — `usize`.
    ///
    /// # Returns
    /// `f32`.
    pub fn channel_volume(&self, ch: usize) -> f32 {
        if ch < 16 {
            self.channel_volume[ch]
        } else {
            0.0
        }
    }

    /// Sets the mute state for a specific MIDI channel (0-15).
    ///
    /// # Parameters
    /// - `ch` — `usize`.
    /// - `muted` — `bool`.
    pub fn set_channel_muted(&mut self, ch: usize, muted: bool) {
        if ch < 16 {
            self.channel_muted[ch] = muted;
        }
    }

    /// Returns whether a specific MIDI channel (0-15) is muted.
    ///
    /// # Parameters
    /// - `ch` — `usize`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_channel_muted(&self, ch: usize) -> bool {
        ch < 16 && self.channel_muted[ch]
    }

    /// Sets the instrument (program number) for a MIDI channel (0-15).
    ///
    /// # Parameters
    /// - `ch` — `usize`.
    /// - `inst` — `u8`.
    pub fn set_channel_instrument(&mut self, ch: usize, inst: u8) {
        if ch < 16 {
            self.channel_instrument[ch] = inst;
        }
    }

    /// Returns the instrument (program number) for a MIDI channel (0-15).
    ///
    /// # Parameters
    /// - `ch` — `usize`.
    ///
    /// # Returns
    /// `u8`.
    pub fn channel_instrument(&self, ch: usize) -> u8 {
        if ch < 16 {
            self.channel_instrument[ch]
        } else {
            0
        }
    }

    /// Returns the number of unique MIDI channels used in the loaded file.
    ///
    /// # Returns
    /// `usize`.
    pub fn channel_count(&self) -> usize {
        self.midi_data.as_ref().map_or(0, |d| d.channel_count)
    }

    /// Solos a channel (mutes all others).
    ///
    /// # Parameters
    /// - `ch` — `usize`.
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
    ///
    /// # Returns
    /// `usize`.
    pub fn track_count(&self) -> usize {
        self.midi_data.as_ref().map_or(0, |d| d.track_count)
    }

    /// Returns the name of a track by index, if it has one.
    ///
    /// # Parameters
    /// - `idx` — `usize`.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn track_name(&self, idx: usize) -> Option<&str> {
        self.midi_data
            .as_ref()
            .and_then(|d| d.track_names.get(idx))
            .and_then(|n| n.as_deref())
    }

    /// Sets the mute state for a specific track by index.
    ///
    /// # Parameters
    /// - `idx` — `usize`.
    /// - `muted` — `bool`.
    pub fn set_track_muted(&mut self, idx: usize, muted: bool) {
        if idx < self.track_muted.len() {
            self.track_muted[idx] = muted;
        }
    }

    /// Returns whether a specific track is muted.
    ///
    /// # Parameters
    /// - `idx` — `usize`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_track_muted(&self, idx: usize) -> bool {
        idx < self.track_muted.len() && self.track_muted[idx]
    }

    /// Returns the total number of NoteOn events in the loaded MIDI.
    ///
    /// # Returns
    /// `usize`.
    pub fn note_count(&self) -> usize {
        self.midi_data.as_ref().map_or(0, |d| d.note_count)
    }

    /// Sets the audio bus key for mixer routing.
    ///
    /// # Parameters
    /// - `key` — `Option<BusKey>`.
    pub fn set_bus_key(&mut self, key: Option<BusKey>) {
        self.bus_key = key;
    }

    /// Returns the audio bus key, if assigned.
    ///
    /// # Returns
    /// `Option<BusKey>`.
    pub fn bus_key(&self) -> Option<BusKey> {
        self.bus_key
    }

    /// Returns the current playback state.
    ///
    /// # Returns
    /// `PlayState`.
    pub fn play_state(&self) -> PlayState {
        self.play_state
    }

    /// Renders the loaded MIDI to a stereo 16-bit PCM buffer at 44100 Hz.
    ///
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
///
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
