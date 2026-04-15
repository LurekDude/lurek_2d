//! Unit tests for luna2d::patterns::{Trie, BiMap}.
//!
//! These types are Foundations-tier data structures with no Lua binding,
//! so they are covered exclusively by Rust unit tests.

use luna2d::patterns::{BiMap, Trie};

// ── Trie ─────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod trie_tests {
    use super::*;

    #[test]
    fn trie_insert_and_search_found() {
        let mut t = Trie::new();
        t.insert("apple");
        assert!(t.search("apple"), "inserted key must be found by search");
    }

    #[test]
    fn trie_search_missing_key_not_found() {
        let mut t = Trie::new();
        t.insert("apple");
        assert!(!t.search("app"), "prefix alone must not be found as a complete word");
    }

    #[test]
    fn trie_starts_with_returns_true() {
        let mut t = Trie::new();
        t.insert("apple");
        assert!(t.starts_with("app"), "starts_with a valid prefix must return true");
    }

    #[test]
    fn trie_prefix_search_returns_all_matches() {
        let mut t = Trie::new();
        for word in &["ab", "abc", "abd", "xyz"] {
            t.insert(word);
        }
        let mut results = t.prefix_search("ab");
        results.sort();
        assert!(results.contains(&"ab".to_string()), "ab must be in results");
        assert!(results.contains(&"abc".to_string()), "abc must be in results");
        assert!(results.contains(&"abd".to_string()), "abd must be in results");
        assert!(!results.contains(&"xyz".to_string()), "xyz must not be in results");
    }

    #[test]
    fn trie_remove_makes_search_return_false() {
        let mut t = Trie::new();
        t.insert("apple");
        t.remove("apple");
        assert!(!t.search("apple"), "removed key must no longer be found");
    }
}

// ── BiMap ────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod bimap_tests {
    use super::*;

    #[test]
    fn bimap_insert_and_get_by_key_returns_value() {
        let mut m: BiMap<&str, u32> = BiMap::new();
        m.insert("k1", 100);
        assert_eq!(m.get_by_key("k1"), Some(&100));
    }

    #[test]
    fn bimap_get_by_value_returns_key() {
        let mut m: BiMap<&str, u32> = BiMap::new();
        m.insert("k1", 100);
        assert_eq!(m.get_by_value(&100), Some(&"k1"));
    }

    #[test]
    fn bimap_bijection_removes_stale_on_reinsert() {
        let mut m: BiMap<&str, u32> = BiMap::new();
        m.insert("k1", 100);
        // k2 steals value 100 — k1 → 100 mapping must be removed
        m.insert("k2", 100);
        assert!(
            m.get_by_key("k1").is_none(),
            "k1 must be removed when k2 takes its value"
        );
        assert_eq!(m.get_by_key("k2"), Some(&100));
    }

    #[test]
    fn bimap_remove_by_key_cleans_both_dirs() {
        let mut m: BiMap<&str, u32> = BiMap::new();
        m.insert("k1", 100);
        m.remove_by_key("k1");
        assert!(m.get_by_key("k1").is_none(), "forward mapping must be gone");
        assert!(
            m.get_by_value(&100).is_none(),
            "reverse mapping must also be cleaned up"
        );
    }
}
