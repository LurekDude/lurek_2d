//! Trie (prefix tree) data structure for efficient string prefix search.
//!
//! `Trie` provides O(k) insert, search, and prefix-search operations
//! (k = key length). Used in the Lurek2D pattern library for autocomplete,
//! command dispatch, and tag filtering.

/// A single node in the trie.
///
/// # Fields
/// - `children` — `HashMap<char, TrieNode>`.
/// - `is_end` — `bool`.
#[derive(Debug, Default)]
struct TrieNode {
    /// Child nodes keyed by character.
    children: std::collections::HashMap<char, TrieNode>,
    /// Whether this node marks the end of an inserted key.
    is_end: bool,
}

/// String prefix-index trie with insert, exact-search, prefix-search, and delete.
///
/// Keys must be non-empty UTF-8 strings. Prefix search returns all stored keys
/// that start with the given prefix, in no guaranteed order.
///
/// # Examples
/// ```
/// let mut t = Trie::new();
/// t.insert("damage");
/// t.insert("damage.fire");
/// assert!(t.search("damage"));
/// assert_eq!(t.prefix_search("damage").len(), 2);
/// ```
#[derive(Debug, Default)]
pub struct Trie {
    root: TrieNode,
}

impl Trie {
    /// Creates a new empty trie.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self::default()
    }

    /// Inserts a key into the trie.
    ///
    /// No-ops silently if `key` is empty.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    pub fn insert(&mut self, key: &str) {
        if key.is_empty() {
            return;
        }
        let mut node = &mut self.root;
        for ch in key.chars() {
            node = node.children.entry(ch).or_default();
        }
        node.is_end = true;
    }

    /// Returns `true` if `key` was previously inserted (exact match).
    ///
    /// # Parameters
    /// - `key` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn search(&self, key: &str) -> bool {
        let mut node = &self.root;
        for ch in key.chars() {
            match node.children.get(&ch) {
                Some(n) => node = n,
                None => return false,
            }
        }
        node.is_end
    }

    /// Returns `true` if any stored key starts with `prefix`.
    ///
    /// # Parameters
    /// - `prefix` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn starts_with(&self, prefix: &str) -> bool {
        let mut node = &self.root;
        for ch in prefix.chars() {
            match node.children.get(&ch) {
                Some(n) => node = n,
                None => return false,
            }
        }
        true
    }

    /// Returns all stored keys that start with `prefix`.
    ///
    /// # Parameters
    /// - `prefix` — `&str`.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn prefix_search(&self, prefix: &str) -> Vec<String> {
        let mut node = &self.root;
        for ch in prefix.chars() {
            match node.children.get(&ch) {
                Some(n) => node = n,
                None => return Vec::new(),
            }
        }
        let mut result = Vec::new();
        collect_keys(node, &mut prefix.to_string(), &mut result);
        result
    }

    /// Removes a key from the trie.
    ///
    /// Returns `true` if the key was found and removed.
    ///
    /// # Parameters
    /// - `key` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove(&mut self, key: &str) -> bool {
        remove_recursive(&mut self.root, key, 0)
    }

    /// Returns the number of keys stored in the trie.
    ///
    /// # Returns
    /// `usize`.
    pub fn len(&self) -> usize {
        count_keys(&self.root)
    }

    /// Returns `true` if the trie contains no keys.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }
}

fn collect_keys(node: &TrieNode, prefix: &mut String, result: &mut Vec<String>) {
    if node.is_end {
        result.push(prefix.clone());
    }
    for (ch, child) in &node.children {
        prefix.push(*ch);
        collect_keys(child, prefix, result);
        prefix.pop();
    }
}

fn remove_recursive(node: &mut TrieNode, key: &str, depth: usize) -> bool {
    let chars: Vec<char> = key.chars().collect();
    if depth == chars.len() {
        if node.is_end {
            node.is_end = false;
            return true;
        }
        return false;
    }
    let ch = chars[depth];
    if let Some(child) = node.children.get_mut(&ch) {
        let removed = remove_recursive(child, key, depth + 1);
        if removed && !child.is_end && child.children.is_empty() {
            node.children.remove(&ch);
        }
        removed
    } else {
        false
    }
}

fn count_keys(node: &TrieNode) -> usize {
    let mut count = if node.is_end { 1 } else { 0 };
    for child in node.children.values() {
        count += count_keys(child);
    }
    count
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn trie_insert_search_finds_inserted_key() {
        let mut t = Trie::new();
        t.insert("hello");
        assert!(t.search("hello"));
        assert!(!t.search("hell"));
        assert!(!t.search("helloo"));
    }

    #[test]
    fn trie_prefix_search_returns_all_matches() {
        let mut t = Trie::new();
        t.insert("damage.fire");
        t.insert("damage.ice");
        t.insert("heal");
        let results = t.prefix_search("damage");
        assert_eq!(results.len(), 2);
        assert!(results.contains(&"damage.fire".to_string()));
        assert!(results.contains(&"damage.ice".to_string()));
    }

    #[test]
    fn trie_remove_deletes_exact_key() {
        let mut t = Trie::new();
        t.insert("key");
        assert!(t.remove("key"));
        assert!(!t.search("key"));
    }
}
