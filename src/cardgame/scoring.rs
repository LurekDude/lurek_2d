//! Generic scoreboard: track, rank, and query player scores.

use std::collections::HashMap;

/// An entry in the scoring history.
#[derive(Debug, Clone)]
pub struct ScoreEntry {
    /// Player identifier.
    pub player_id: String,
    /// Score change.
    pub delta: f64,
    /// Score after the change.
    pub new_score: f64,
    /// Optional label for this scoring event (user-defined).
    pub label: String,
}

/// A generic scoreboard tracking scores for any number of players.
///
/// Scores are user-defined floating-point values.  The board records a
/// history of all changes so the game designer can replay or display a
/// running log.
#[derive(Debug, Clone, Default)]
pub struct ScoreBoard {
    /// Current scores, keyed by player ID.
    scores: HashMap<String, f64>,
    /// Full scoring history (append-only).
    history: Vec<ScoreEntry>,
}

impl ScoreBoard {
    /// Create an empty scoreboard.
    pub fn new() -> Self {
        Self::default()
    }

    // ── Mutations ────────────────────────────────────────────────────────────

    /// Directly set a player's score.
    pub fn set_score(&mut self, player_id: impl Into<String>, score: f64) {
        let id = player_id.into();
        let old = *self.scores.get(&id).unwrap_or(&0.0);
        let delta = score - old;
        self.scores.insert(id.clone(), score);
        self.history.push(ScoreEntry {
            player_id: id,
            delta,
            new_score: score,
            label: String::new(),
        });
    }

    /// Add `delta` to a player's score and return the new total.
    pub fn add_score(&mut self, player_id: impl Into<String>, delta: f64) -> f64 {
        self.add_score_labeled(player_id, delta, "")
    }

    /// Add `delta` to a player's score with an optional label for the event.
    pub fn add_score_labeled(
        &mut self,
        player_id: impl Into<String>,
        delta: f64,
        label: impl Into<String>,
    ) -> f64 {
        let id = player_id.into();
        let v = self.scores.entry(id.clone()).or_insert(0.0);
        *v += delta;
        let new = *v;
        self.history.push(ScoreEntry {
            player_id: id,
            delta,
            new_score: new,
            label: label.into(),
        });
        new
    }

    /// Reset a player's score to zero (recorded in history).
    pub fn reset_score(&mut self, player_id: impl Into<String>) {
        let id = player_id.into();
        let old = *self.scores.get(&id).unwrap_or(&0.0);
        self.scores.insert(id.clone(), 0.0);
        self.history.push(ScoreEntry {
            player_id: id,
            delta: -old,
            new_score: 0.0,
            label: "reset".into(),
        });
    }

    // ── Queries ──────────────────────────────────────────────────────────────

    /// Get the current score for `player_id` (`0.0` if unknown).
    pub fn get_score(&self, player_id: &str) -> f64 {
        *self.scores.get(player_id).unwrap_or(&0.0)
    }

    /// Return all (player_id, score) pairs sorted **descending** by score.
    pub fn ranking(&self) -> Vec<(String, f64)> {
        let mut v: Vec<(String, f64)> = self.scores.iter().map(|(k, &v)| (k.clone(), v)).collect();
        v.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
        v
    }

    /// Return the player ID with the highest score, or `None` if empty.
    pub fn leader(&self) -> Option<String> {
        self.scores
            .iter()
            .max_by(|a, b| a.1.partial_cmp(b.1).unwrap_or(std::cmp::Ordering::Equal))
            .map(|(k, _)| k.clone())
    }

    /// Return the player ID with the lowest score, or `None` if empty.
    pub fn trailer(&self) -> Option<String> {
        self.scores
            .iter()
            .min_by(|a, b| a.1.partial_cmp(b.1).unwrap_or(std::cmp::Ordering::Equal))
            .map(|(k, _)| k.clone())
    }

    /// Returns `true` if two or more players share the same highest score.
    pub fn is_tied(&self) -> bool {
        if self.scores.len() < 2 {
            return false;
        }
        let mut scores: Vec<f64> = self.scores.values().copied().collect();
        scores.sort_by(|a, b| b.partial_cmp(a).unwrap_or(std::cmp::Ordering::Equal));
        (scores[0] - scores[1]).abs() < f64::EPSILON
    }

    /// Return the scoring history (all events, oldest first).
    pub fn history(&self) -> &[ScoreEntry] {
        &self.history
    }

    /// History events for a specific player (oldest first).
    pub fn history_for(&self, player_id: &str) -> Vec<&ScoreEntry> {
        self.history.iter().filter(|e| e.player_id == player_id).collect()
    }

    /// Number of players on the board.
    pub fn player_count(&self) -> usize {
        self.scores.len()
    }

    /// All player IDs currently on the board.
    pub fn players(&self) -> Vec<String> {
        self.scores.keys().cloned().collect()
    }
}
