//! Input event recorder and frame-accurate playback for replays and automated tests.
//! Owns the recording buffer, JSON serialisation, and frame-step playback cursor.
//! Does not own real-time event delivery; the runtime feeds events in and reads them out each frame.
//! Consumed by `src/lua_api/input_api.rs` and automation tools in `tests/`.

/// A single input event with a kind tag and a key/button name.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, PartialEq)]
pub struct InputEvent {
    /// Event category: `"key"`, `"mouse"`, etc.
    pub kind: String,
    /// Key name, button name, or action identifier.
    pub name: String,
}

/// All input events and optional mouse position captured for one recorded frame.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, PartialEq)]
pub struct RecordedFrame {
    /// Absolute frame number within the recording.
    pub frame: u64,
    /// Key and button events that occurred during this frame.
    pub key_events: Vec<InputEvent>,
    /// Optional captured mouse X coordinate (only present when the mouse moved).
    pub mouse_x: Option<f64>,
    /// Optional captured mouse Y coordinate (only present when the mouse moved).
    pub mouse_y: Option<f64>,
}

/// Complete input recording: sparse frame list and total frame count.
#[derive(Debug, Clone, Default, serde::Serialize, serde::Deserialize, PartialEq)]
pub struct InputRecording {
    /// Sparse list of frames that had input activity; frames without events are omitted.
    pub frames: Vec<RecordedFrame>,
    /// Total number of frames captured, including silent frames.
    pub total_frames: u64,
}

/// JSON schema version embedded in the serialisation envelope.
const INPUT_RECORDING_SCHEMA_VERSION: u32 = 1;

/// Internal JSON wrapper that adds a version field around the recording data.
#[derive(Debug, serde::Serialize, serde::Deserialize)]
struct RecordingEnvelope {
    /// Schema version; must equal `INPUT_RECORDING_SCHEMA_VERSION` on read.
    version: u32,
    /// Recorded frame data.
    frames: Vec<RecordedFrame>,
    /// Total frames including silent ones.
    total_frames: u64,
}

impl InputRecording {
    /// Serialise to JSON, wrapping in a versioned envelope; return error string on failure.
    pub fn to_json(&self) -> Result<String, String> {
        let envelope = RecordingEnvelope {
            version: INPUT_RECORDING_SCHEMA_VERSION,
            frames: self.frames.clone(),
            total_frames: self.total_frames,
        };
        serde_json::to_string(&envelope).map_err(|e| format!("InputRecording serialize error: {e}"))
    }

    /// Deserialise from JSON; returns error when the version field is unsupported.
    pub fn from_json(json: &str) -> Result<Self, String> {
        if let Ok(envelope) = serde_json::from_str::<RecordingEnvelope>(json) {
            if envelope.version != INPUT_RECORDING_SCHEMA_VERSION {
                return Err(format!(
                    "InputRecording parse error: unsupported version {}",
                    envelope.version
                ));
            }
            return Ok(Self {
                frames: envelope.frames,
                total_frames: envelope.total_frames,
            });
        }
        serde_json::from_str(json).map_err(|e| format!("InputRecording parse error: {e}"))
    }
}

/// Stateful recorder and playback cursor for one input recording session.
#[derive(Debug, Default)]
pub struct InputRecorder {
    /// Recording buffer being written to; `None` when not recording.
    current: Option<InputRecording>,
    /// Recording loaded for playback; `None` when no recording is loaded.
    playback: Option<InputRecording>,
    /// Index into `playback.frames` for the current playback position.
    playback_idx: usize,
    /// Current frame counter, used for both recording and playback.
    frame: u64,
    /// True when an active recording is in progress.
    recording: bool,
    /// True when playback is in progress.
    playing: bool,
}

impl InputRecorder {
    /// Create a new recorder with no active recording or playback.
    pub fn new() -> Self {
        Self::default()
    }

    /// Begin a new recording; clears any previous in-progress recording.
    pub fn start_recording(&mut self) {
        self.current = Some(InputRecording::default());
        self.frame = 0;
        self.recording = true;
        self.playing = false;
    }

    /// Append events for the current frame to the active recording; advances the frame counter.
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

    /// Stop recording and return the completed `InputRecording`, or `None` when nothing was recorded.
    pub fn stop_recording(&mut self) -> Option<InputRecording> {
        self.recording = false;
        if let Some(mut rec) = self.current.take() {
            rec.total_frames = self.frame;
            Some(rec)
        } else {
            None
        }
    }

    /// Return true when a recording is currently in progress.
    pub fn is_recording(&self) -> bool {
        self.recording
    }

    /// Load `recording` as the active playback source; resets the playback cursor.
    pub fn load(&mut self, recording: InputRecording) {
        self.playback = Some(recording);
        self.playback_idx = 0;
    }

    /// Start playing back the loaded recording from the beginning; no-op when no recording is loaded.
    pub fn start_playback(&mut self) {
        if self.playback.is_some() {
            self.playing = true;
            self.playback_idx = 0;
            self.frame = 0;
            self.recording = false;
        }
    }

    /// Stop playback immediately.
    pub fn stop_playback(&mut self) {
        self.playing = false;
    }

    /// Return true when playback is currently in progress.
    pub fn is_playing_back(&self) -> bool {
        self.playing
    }

    /// Return the current frame index within the active playback.
    pub fn playback_frame_index(&self) -> u64 {
        self.frame
    }

    /// Return all events for the current playback frame and advance; stops playback at the end.
    pub fn playback_frame(&mut self) -> Vec<InputEvent> {
        if !self.playing {
            return Vec::new();
        }
        let mut events: Vec<InputEvent> = Vec::new();
        if let Some(rec) = &self.playback {
            while self.playback_idx < rec.frames.len()
                && rec.frames[self.playback_idx].frame == self.frame
            {
                events.extend(rec.frames[self.playback_idx].key_events.clone());
                self.playback_idx += 1;
            }
            if self.frame + 1 >= rec.total_frames {
                self.playing = false;
            }
        }
        self.frame += 1;
        events
    }
}
