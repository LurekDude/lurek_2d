//! Quest and objective tracking system for Luna2D games.
//!
//! Provides `Quest`, `Objective`, `QuestStage`, `JournalEntry`, and `QuestLog`
//! for building RPG-style quest systems with stages, conditions, and journal notes.


/// Quest and objective status enums.
pub mod status;
pub use status::*;

/// Objectives and quest stages.
pub mod objective;
pub use objective::*;

/// Journal entry.
pub mod journal;
pub use journal::*;

/// Quest definition.
#[allow(clippy::module_inception)]
pub mod quest;
pub use quest::*;

/// Quest log.
pub mod log;
pub use log::*;

// ──────────────────────────────────────────────────────────────────────────────
// Tests
// ──────────────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn objective_advance_completes() {
        let mut obj = Objective::new("kill_wolves", "Kill 3 wolves", 3);
        obj.advance(2);
        assert_eq!(obj.status, ObjectiveStatus::Active);
        obj.advance(1);
        assert_eq!(obj.status, ObjectiveStatus::Done);
    }

    #[test]
    fn objective_advance_clamps() {
        let mut obj = Objective::new("fetch", "Fetch 5 apples", 5);
        obj.advance(10);
        assert_eq!(obj.current, 5);
        assert_eq!(obj.status, ObjectiveStatus::Done);
    }

    #[test]
    fn quest_start_and_complete() {
        let mut q = Quest::new("tutorial", "Tutorial Quest");
        assert_eq!(q.status, QuestStatus::Available);
        q.start();
        assert_eq!(q.status, QuestStatus::Active);
        q.complete();
        assert_eq!(q.status, QuestStatus::Completed);
    }

    #[test]
    fn quest_stages_and_next() {
        let mut q = Quest::new("main", "Main Quest");
        q.add_stage(QuestStage::new("s1", "Stage 1"));
        q.add_stage(QuestStage::new("s2", "Stage 2"));
        assert_eq!(q.current_stage, 0);
        assert!(q.next_stage());
        assert_eq!(q.current_stage, 1);
        assert!(!q.next_stage()); // already at last
    }

    #[test]
    fn quest_log_start_fail() {
        let mut log = QuestLog::new();
        let q = Quest::new("q1", "Quest 1");
        log.add_quest(q);
        log.start_quest("q1");
        assert_eq!(log.get_quest("q1").unwrap().status, QuestStatus::Active);
        log.fail_quest("q1");
        assert_eq!(log.get_quest("q1").unwrap().status, QuestStatus::Failed);
    }
}
