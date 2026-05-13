#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, PartialEq)]
pub struct InputEvent {
    pub kind: String,
    pub name: String,
}
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize, PartialEq)]
pub struct RecordedFrame {
    pub frame: u64,
    pub key_events: Vec<InputEvent>,
    pub mouse_x: Option<f64>,
    pub mouse_y: Option<f64>,
}
#[derive(Debug, Clone, Default, serde::Serialize, serde::Deserialize, PartialEq)]
pub struct InputRecording {
    pub frames: Vec<RecordedFrame>,
    pub total_frames: u64,
}
const INPUT_RECORDING_SCHEMA_VERSION: u32 = 1;
#[derive(Debug, serde::Serialize, serde::Deserialize)]
struct RecordingEnvelope {
    version: u32,
    frames: Vec<RecordedFrame>,
    total_frames: u64,
}
impl InputRecording {
    pub fn to_json(&self) -> Result<String, String> {
        let envelope = RecordingEnvelope {
            version: INPUT_RECORDING_SCHEMA_VERSION,
            frames: self.frames.clone(),
            total_frames: self.total_frames,
        };
        serde_json::to_string(&envelope).map_err(|e| format!("InputRecording serialize error: {e}"))
    }
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
#[derive(Debug, Default)]
pub struct InputRecorder {
    current: Option<InputRecording>,
    playback: Option<InputRecording>,
    playback_idx: usize,
    frame: u64,
    recording: bool,
    playing: bool,
}
impl InputRecorder {
    pub fn new() -> Self {
        Self::default()
    }
    pub fn start_recording(&mut self) {
        self.current = Some(InputRecording::default());
        self.frame = 0;
        self.recording = true;
        self.playing = false;
    }
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
    pub fn stop_recording(&mut self) -> Option<InputRecording> {
        self.recording = false;
        if let Some(mut rec) = self.current.take() {
            rec.total_frames = self.frame;
            Some(rec)
        } else {
            None
        }
    }
    pub fn is_recording(&self) -> bool {
        self.recording
    }
    pub fn load(&mut self, recording: InputRecording) {
        self.playback = Some(recording);
        self.playback_idx = 0;
    }
    pub fn start_playback(&mut self) {
        if self.playback.is_some() {
            self.playing = true;
            self.playback_idx = 0;
            self.frame = 0;
            self.recording = false;
        }
    }
    pub fn stop_playback(&mut self) {
        self.playing = false;
    }
    pub fn is_playing_back(&self) -> bool {
        self.playing
    }
    pub fn playback_frame_index(&self) -> u64 {
        self.frame
    }
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
