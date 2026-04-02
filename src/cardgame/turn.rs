//! Generic turn/phase management.
//!
//! `TurnManager` tracks which player is active, what phase the game is in,
//! and how many rounds and turns have elapsed.  Phase names are user-defined.

/// Manages turn order, round counting, and phase sequencing for any card game.
///
/// No game-specific logic is embedded here; the caller decides what to do
/// when a new turn or phase begins.
#[derive(Debug, Clone)]
pub struct TurnManager {
    /// Ordered list of player IDs.
    pub player_order: Vec<String>,
    /// Index into `player_order` for the current player.
    pub current_index: usize,
    /// Total turns elapsed (incremented each time any player's turn starts).
    pub turn: usize,
    /// Completed full rounds (incremented when every player has had a turn).
    pub round: usize,
    /// User-defined phase names for one turn (e.g. `["draw", "main", "end"]`).
    pub phases: Vec<String>,
    /// Index into `phases` for the current phase.
    pub phase_index: usize,
    /// Players currently marked as skipped for this round.
    skipped: std::collections::HashSet<String>,
}

impl TurnManager {
    /// Create a turn manager with the given player order.  If `phases` is
    /// empty, a default `["main", "end"]` list is used.
    pub fn new(player_order: Vec<String>, phases: Vec<String>) -> Self {
        let phases =
            if phases.is_empty() { vec!["main".into(), "end".into()] } else { phases };
        Self {
            player_order,
            current_index: 0,
            turn: 0,
            round: 1,
            phases,
            phase_index: 0,
            skipped: Default::default(),
        }
    }

    // ── Phase management ─────────────────────────────────────────────────────

    /// Advance to the next phase.
    ///
    /// Returns the new phase name, or `None` if the phases list is empty.
    /// When the last phase is passed, the turn is automatically advanced.
    pub fn advance_phase(&mut self) -> Option<String> {
        if self.phases.is_empty() {
            return None;
        }
        self.phase_index += 1;
        if self.phase_index >= self.phases.len() {
            self.advance_turn();
        }
        self.current_phase().map(String::from)
    }

    /// Current phase name, or `None` if phases is empty.
    pub fn current_phase(&self) -> Option<&str> {
        self.phases.get(self.phase_index).map(String::as_str)
    }

    /// Jump directly to a named phase (no-op if not found).
    pub fn set_phase(&mut self, phase: &str) {
        if let Some(i) = self.phases.iter().position(|p| p == phase) {
            self.phase_index = i;
        }
    }

    // ── Turn management ──────────────────────────────────────────────────────

    /// Advance to the next player's turn.
    ///
    /// Returns the new active player's ID.
    pub fn advance_turn(&mut self) -> Option<String> {
        if self.player_order.is_empty() {
            return None;
        }
        self.turn += 1;
        self.phase_index = 0;

        // Advance, skipping eliminated/skipped players.
        let n = self.player_order.len();
        for _ in 0..n {
            self.current_index = (self.current_index + 1) % n;
            if self.current_index == 0 {
                self.round += 1;
                self.skipped.clear();
            }
            let pid = &self.player_order[self.current_index];
            if !self.skipped.contains(pid) {
                return Some(pid.clone());
            }
        }
        // All players skipped — still advance.
        Some(self.player_order[self.current_index].clone())
    }

    /// Current active player ID, or `None` if there are no players.
    pub fn current_player(&self) -> Option<&str> {
        self.player_order.get(self.current_index).map(String::as_str)
    }

    /// Current round number (1-based).
    pub fn current_round(&self) -> usize {
        self.round
    }

    /// Total turns elapsed.
    pub fn current_turn(&self) -> usize {
        self.turn
    }

    /// Mark a player as skipped for the current round.
    pub fn skip_player(&mut self, player_id: &str) {
        self.skipped.insert(player_id.to_owned());
    }

    /// Remove the skip mark from a player.
    pub fn unskip_player(&mut self, player_id: &str) {
        self.skipped.remove(player_id);
    }

    /// Returns `true` if `player_id` is currently skipped.
    pub fn is_skipped(&self, player_id: &str) -> bool {
        self.skipped.contains(player_id)
    }

    /// Reorder the player list.  Resets the current index to 0.
    pub fn set_order(&mut self, order: Vec<String>) {
        self.player_order = order;
        self.current_index = 0;
    }

    /// Return a copy of the full player order.
    pub fn player_order(&self) -> &[String] {
        &self.player_order
    }

    /// Next player ID in turn order without advancing.
    pub fn peek_next(&self) -> Option<&str> {
        if self.player_order.is_empty() {
            return None;
        }
        let n = self.player_order.len();
        let next_idx = (self.current_index + 1) % n;
        self.player_order.get(next_idx).map(String::as_str)
    }
}
