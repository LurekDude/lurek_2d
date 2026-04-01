//! Dialog sequencer for visual novel-style text presentation.
//!
//! Provides a state-machine-based dialog sequencer with typewriter effect,
//! branching choices, timed pauses, and inline callbacks. Drives text-based
//! narrative sequences from flat script arrays.

/// Dialog node types in a script.
#[derive(Debug, Clone)]
pub enum DialogNode {
    /// A spoken line with speaker name and text.
    Say { speaker: String, text: String },
    /// A branching choice with prompt and options.
    Choice {
        text: String,
        options: Vec<ChoiceOption>,
    },
    /// A timed pause in seconds.
    Wait { time: f32 },
    /// An inline callback index (resolved by the Lua layer).
    Call { callback_index: usize },
}

/// A single choice option with a label and branch nodes.
#[derive(Debug, Clone)]
pub struct ChoiceOption {
    /// Display label for this option.
    pub label: String,
    /// Branch nodes to splice in when chosen.
    pub branch: Vec<DialogNode>,
}

/// Sequencer playback state.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SequencerState {
    /// Not started or reset.
    Idle,
    /// Typewriter actively revealing text.
    Typing,
    /// Full text shown; awaiting advance().
    Waiting,
    /// Presenting choices; awaiting choose().
    Choice,
    /// Executing a wait node; timer running.
    Paused,
    /// Script finished.
    Done,
}

impl SequencerState {
    /// Returns the string representation of the state.
    pub fn as_str(&self) -> &'static str {
        match self {
            SequencerState::Idle => "idle",
            SequencerState::Typing => "typing",
            SequencerState::Waiting => "waiting",
            SequencerState::Choice => "choice",
            SequencerState::Paused => "paused",
            SequencerState::Done => "done",
        }
    }
}

/// Dialog sequencer with typewriter effect and branching choices.
///
/// Drives a flat array of [`DialogNode`] values through a state machine,
/// revealing text character-by-character at a configurable speed.
#[derive(Debug)]
pub struct Sequencer {
    nodes: Vec<DialogNode>,
    state: SequencerState,
    current_index: usize,
    /// Characters per second for typewriter effect. 0 = instant.
    speed: f32,
    /// Number of characters revealed so far in the current say node.
    revealed_chars: usize,
    /// Accumulated time for typewriter or wait timer.
    timer: f32,
}

impl Sequencer {
    /// Creates a new idle sequencer with default speed (30 cps).
    pub fn new() -> Self {
        Self {
            nodes: Vec::new(),
            state: SequencerState::Idle,
            current_index: 0,
            speed: 30.0,
            revealed_chars: 0,
            timer: 0.0,
        }
    }

    /// Loads a script node array. Clears previous script, resets to Idle.
    pub fn load(&mut self, nodes: Vec<DialogNode>) {
        self.nodes = nodes;
        self.state = SequencerState::Idle;
        self.current_index = 0;
        self.revealed_chars = 0;
        self.timer = 0.0;
    }

    /// Begins playback from the first node. If empty, goes to Done.
    ///
    /// Returns an optional callback index if the first node is a Call.
    pub fn start(&mut self) -> Option<usize> {
        if self.nodes.is_empty() {
            self.state = SequencerState::Done;
            return None;
        }
        self.current_index = 0;
        self.enter_current_node()
    }

    /// Returns the current sequencer state.
    pub fn state(&self) -> SequencerState {
        self.state
    }

    /// Returns true if not Idle and not Done.
    pub fn is_active(&self) -> bool {
        self.state != SequencerState::Idle && self.state != SequencerState::Done
    }

    /// Returns true only in Choice state.
    pub fn is_waiting_for_choice(&self) -> bool {
        self.state == SequencerState::Choice
    }

    /// Returns the speaker name of the current say node, or empty string.
    pub fn current_speaker(&self) -> &str {
        if let Some(DialogNode::Say { speaker, .. }) = self.nodes.get(self.current_index) {
            speaker.as_str()
        } else {
            ""
        }
    }

    /// Returns the full text of the current say node, or empty string.
    pub fn current_text(&self) -> &str {
        if let Some(DialogNode::Say { text, .. }) = self.nodes.get(self.current_index) {
            text.as_str()
        } else {
            ""
        }
    }

    /// Returns the typewriter-revealed substring of the current text.
    pub fn revealed_text(&self) -> &str {
        let full = self.current_text();
        if self.revealed_chars >= full.len() {
            full
        } else {
            // Ensure we don't split in the middle of a multi-byte char
            let mut end = self.revealed_chars;
            while end < full.len() && !full.is_char_boundary(end) {
                end += 1;
            }
            &full[..end]
        }
    }

    /// Returns the choice prompt text, or empty string if not in Choice state.
    pub fn choice_text(&self) -> &str {
        if let Some(DialogNode::Choice { text, .. }) = self.nodes.get(self.current_index) {
            text.as_str()
        } else {
            ""
        }
    }

    /// Returns the choice option labels, or empty vec if not in Choice state.
    pub fn choice_labels(&self) -> Vec<&str> {
        if let Some(DialogNode::Choice { options, .. }) = self.nodes.get(self.current_index) {
            options.iter().map(|o| o.label.as_str()).collect()
        } else {
            Vec::new()
        }
    }

    /// Sets the typewriter speed in characters per second. 0 = instant.
    pub fn set_speed(&mut self, cps: f32) {
        self.speed = cps.max(0.0);
    }

    /// Returns the current typewriter speed in characters per second.
    pub fn get_speed(&self) -> f32 {
        self.speed
    }

    /// Advances the typewriter/wait timers. Call every frame.
    ///
    /// Returns an optional callback index if a Call node was entered.
    pub fn update(&mut self, dt: f32) -> Option<usize> {
        match self.state {
            SequencerState::Typing => {
                let text_len = self.current_text().len();
                if self.speed <= 0.0 {
                    self.revealed_chars = text_len;
                    self.state = SequencerState::Waiting;
                } else {
                    self.timer += dt;
                    let chars_per_tick = self.speed;
                    let new_chars = (self.timer * chars_per_tick) as usize;
                    self.revealed_chars = new_chars.min(text_len);
                    if self.revealed_chars >= text_len {
                        self.state = SequencerState::Waiting;
                    }
                }
                None
            }
            SequencerState::Paused => {
                if let Some(DialogNode::Wait { time }) = self.nodes.get(self.current_index) {
                    self.timer += dt;
                    if self.timer >= *time {
                        self.advance_to_next();
                    }
                }
                None
            }
            _ => None,
        }
    }

    /// TYPING → completes text → WAITING. WAITING → next node.
    ///
    /// Returns an optional callback index if a Call node was entered.
    pub fn advance(&mut self) -> Option<usize> {
        match self.state {
            SequencerState::Typing => {
                self.revealed_chars = self.current_text().len();
                self.state = SequencerState::Waiting;
                None
            }
            SequencerState::Waiting => self.advance_to_next(),
            _ => None,
        }
    }

    /// TYPING → reveals all chars → WAITING. Does NOT move to next node.
    pub fn skip(&mut self) {
        if self.state == SequencerState::Typing {
            self.revealed_chars = self.current_text().len();
            self.state = SequencerState::Waiting;
        }
    }

    /// Select a choice option (1-based index). Splices branch nodes inline.
    ///
    /// Returns an optional callback index if the first branch node is a Call.
    pub fn choose(&mut self, index: usize) -> Option<usize> {
        if self.state != SequencerState::Choice {
            return None;
        }
        if let Some(DialogNode::Choice { options, .. }) = self.nodes.get(self.current_index).cloned()
        {
            if index == 0 || index > options.len() {
                return None;
            }
            let branch = options[index - 1].branch.clone();
            let insert_pos = self.current_index + 1;
            // Splice branch nodes after the current choice node
            for (i, node) in branch.into_iter().enumerate() {
                self.nodes.insert(insert_pos + i, node);
            }
            // Advance past the choice node into the spliced branch
            self.advance_to_next()
        } else {
            None
        }
    }

    /// Enter the current node, setting state accordingly.
    ///
    /// Returns an optional callback index if the node is a Call.
    fn enter_current_node(&mut self) -> Option<usize> {
        if self.current_index >= self.nodes.len() {
            self.state = SequencerState::Done;
            return None;
        }
        match &self.nodes[self.current_index] {
            DialogNode::Say { text, .. } => {
                self.revealed_chars = 0;
                self.timer = 0.0;
                if self.speed <= 0.0 {
                    self.revealed_chars = text.len();
                    self.state = SequencerState::Waiting;
                } else {
                    self.state = SequencerState::Typing;
                }
                None
            }
            DialogNode::Choice { .. } => {
                self.state = SequencerState::Choice;
                None
            }
            DialogNode::Wait { .. } => {
                self.state = SequencerState::Paused;
                self.timer = 0.0;
                None
            }
            DialogNode::Call { callback_index } => {
                let idx = *callback_index;
                self.advance_to_next();
                Some(idx)
            }
        }
    }

    /// Move to the next node and enter it.
    fn advance_to_next(&mut self) -> Option<usize> {
        self.current_index += 1;
        self.enter_current_node()
    }
}

impl Default for Sequencer {
    fn default() -> Self {
        Self::new()
    }
}
