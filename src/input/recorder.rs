//! Input recording and playback for Lurek2D.
//!
//! [`InputRecorder`] captures per-frame key and mouse events during gameplay
//! and can replay them deterministically.  Recordings are serialized to/from
//! JSON so they can be saved to disk and reloaded in a later session.
//!
//! # Architecture
//! - The recorder is self-contained with its own frame counter.
//! - The owning Lua API (`input_api.rs`) calls [`InputRecorder::record_frame`]
//!   once per game frame to append the current input snapshot.
//! - During playback, [`InputRecorder::playback_frame`] returns the events that
//!   were recorded for the current playback frame index.
//! - The Lua layer reads the returned events and injects them into the simulated
//!   input state (e.g. via the automation / simulator subsystem).

/// A single key or button event captured within one frame.
///
/// # Fields
/// - `kind` — `"down"` or `"up"`.
/// - `name` — Key name string (e.g. `"space"`, `"left_ctrl"`, `"mouse_left"`).
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, PartialEq)]
pub struct InputEvent {
    /// `"down"` for press, `"up"` for release.
    pub kind: String,
    /// Key or button name as used in `lurek.input.keyboard` / `lurek.input.mouse`.
    pub name: String,
}

/// A snapshot of all input events that occurred during a single game frame.
///
/// # Fields
/// - `frame` — 0-based frame index.
/// - `key_events` — Ordered list of key-press and key-release events.
/// - `mouse_x` / `mouse_y` — Mouse position at frame end (`None` = no movement).
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, PartialEq)]
pub struct RecordedFrame {
    /// 0-based frame index within the recording.
    pub frame: u64,
    /// Ordered list of key/button events for this frame.
    pub key_events: Vec<InputEvent>,
    /// Mouse X position at frame end, if the cursor moved.
    pub mouse_x: Option<f64>,
    /// Mouse Y position at frame end, if the cursor moved.
    pub mouse_y: Option<f64>,
}

/// A complete input recording consisting of one or more [`RecordedFrame`] snapshots.
///
/// Only frames that contain at least one event are stored (sparse representation).
///
/// # Fields
/// - `frames` — Sparse ordered list of frames that had input activity.
/// - `total_frames` — Frame count at the moment `stop_recording` was called.
#[derive(Debug, Clone, Default, serde::Serialize, serde::Deserialize, PartialEq)]
pub struct InputRecording {
    /// Sparse list of frames that had input activity, ordered by frame index.
    pub frames: Vec<RecordedFrame>,
    /// Total number of frames in the recording window.
    pub total_frames: u64,
}

impl InputRecording {
    /// Serializes this recording to a JSON string.
    ///
    /// # Returns
    /// `Result<String, String>` — JSON text or an error description.
    pub fn to_json(&self) -> Result<String, String> {
        serde_json::to_string(self).map_err(|e| format!("InputRecording serialize error: {e}"))
    }

    /// Deserializes an [`InputRecording`] from a JSON string.
    ///
    /// # Parameters
    /// - `json` — `&str`. Previously produced by [`to_json`].
    ///
    /// # Returns
    /// `Result<InputRecording, String>` — Parsed recording or an error description.
    pub fn from_json(json: &str) -> Result<Self, String> {
        serde_json::from_str(json).map_err(|e| format!("InputRecording parse error: {e}"))
    }
}

/// Records input events frame-by-frame and replays them on demand.
///
/// # Usage
/// ```no_run
/// let mut rec = InputRecorder::new();
/// rec.start_recording();
/// // per frame:
/// rec.record_frame(vec![InputEvent { kind: "down".into(), name: "space".into() }], None, None);
/// let recording = rec.stop_recording().unwrap();
/// let json = recording.to_json().unwrap();
///
/// // Playback:
/// let loaded = InputRecording::from_json(&json).unwrap();
/// rec.start_playback(loaded);
/// while rec.is_playing_back() {
///     let events = rec.playback_frame();
///     // apply events to input state …
///     rec.advance();
/// }
/// ```
#[derive(Debug, Default)]
pub struct InputRecorder {
    /// Recording in progress, if any.
    current: Option<InputRecording>,
    /// Recording loaded for playback.
    playback: Option<InputRecording>,
    /// Index into `playback.frames` for the next frame to emit.
    playback_idx: usize,
    /// Current frame counter (used by both recording and playback).
    frame: u64,
    /// Whether recording is active.
    recording: bool,
    /// Whether playback is active.
    playing: bool,
}

impl InputRecorder {
    /// Creates a new, idle [`InputRecorder`].
    pub fn new() -> Self {
        Self::default()
    }

    /// Starts capturing input events.  Clears any previous in-progress recording.
    pub fn start_recording(&mut self) {
        self.current = Some(InputRecording::default());
        self.frame = 0;
        self.recording = true;
        self.playing = false;
    }

    /// Appends one frame of input data to the current recording.
    ///
    /// Call this exactly once per game frame while recording is active.
    /// Frames with no events and no mouse movement are omitted (sparse).
    ///
    /// # Parameters
    /// - `key_events` — Key/button events that occurred this frame.
    /// - `mouse_x` — Mouse X position, or `None` if unchanged.
    /// - `mouse_y` — Mouse Y position, or `None` if unchanged.
    pub fn record_frame(
        &mut self,
        key_events: Vec<InputEvent>,
        mouse_x: Option<f64>,
        mouse_y: Option<f64>,
    ) {
        if let Some(rec) = &mut self.current {
            if !key_events.is_empty() || mouse_x.is_some() {
                rec.frames.push(RecordedFrame {
                    frame: self.frame,
                    key_events,
                    mouse_x,
                    mouse_y,
                });
            }
        }
        self.frame += 1;
    }

    /// Stops recording and returns the completed [`InputRecording`].
    ///
    /// Returns `None` if recording was never started.
    pub fn stop_recording(&mut self) -> Option<InputRecording> {
        self.recording = false;
        if let Some(mut rec) = self.current.take() {
            rec.total_frames = self.frame;
            Some(rec)
        } else {
            None
        }
    }

    /// Returns `true` if recording is currently active.
    pub fn is_recording(&self) -> bool {
        self.recording
    }

    /// Loads an [`InputRecording`] and prepares it for playback.
    ///
    /// Does not start playback — call [`start_playback`] after loading.
    pub fn load(&mut self, recording: InputRecording) {
        self.playback = Some(recording);
        self.playback_idx = 0;
    }

    /// Starts playback from the beginning of the loaded recording.
    ///
    /// Has no effect if no recording is loaded.
    pub fn start_playback(&mut self) {
        if self.playback.is_some() {
            self.playing = true;
            self.playback_idx = 0;
            self.frame = 0;
            self.recording = false;
        }
    }

    /// Stops playback immediately.
    pub fn stop_playback(&mut self) {
        self.playing = false;
    }

    /// Returns `true` if playback is currently active.
    pub fn is_playing_back(&self) -> bool {
        self.playing
    }

    /// Returns the current playback frame index (0-based).
    pub fn playback_frame_index(&self) -> u64 {
        self.frame
    }

    /// Returns the events recorded for the current playback frame and advances
    /// the internal frame counter by one.
    ///
    /// Returns an empty `Vec` if no events were recorded for this frame.
    /// Automatically stops playback when the recording is exhausted.
    pub fn playback_frame(&mut self) -> Vec<InputEvent> {
        if !self.playing {
            return Vec::new();
        }

        let mut events: Vec<InputEvent> = Vec::new();
        if let Some(rec) = &self.playback {
            // Sparse seek: advance through recorded frames whose index matches
            // the current playback frame.  Multiple RecordedFrame entries can
            // share the same frame index (e.g. mouse + keys recorded separately).
            while self.playback_idx < rec.frames.len()
                && rec.frames[self.playback_idx].frame == self.frame
            {
                events.extend(rec.frames[self.playback_idx].key_events.clone());
                self.playback_idx += 1;
            }

            // Check if the recording is exhausted.
            if self.frame + 1 >= rec.total_frames {
                self.playing = false;
            }
        }

        self.frame += 1;
        events
    }
}
