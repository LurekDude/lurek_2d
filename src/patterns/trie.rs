//! Character-keyed trie for prefix search, exact lookup, and key removal.
//! Used internally for completion and dictionary queries; no Lua bindings are exposed directly.

/// Internal trie node holding child edges and end-of-word marker.
#[derive(Debug, Default)]
struct TrieNode {
    /// Child nodes keyed by the next character.
    children: std::collections::HashMap<char, TrieNode>,
    /// True when this node marks the end of an inserted key.
    is_end: bool,
}
/// Prefix trie for efficient string key storage and lookup.
#[derive(Debug, Default)]
pub struct Trie {
    /// Root node of the trie.
    root: TrieNode,
}
/// All methods for `Trie`.
impl Trie {
    /// Create an empty trie.
    pub fn new() -> Self {
        Self::default()
    }
    /// Insert `key` into the trie; empty keys are ignored.
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
    /// Return true when `key` exists as a complete word.
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
    /// Return true when any inserted key starts with `prefix`.
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
    /// Return all keys that start with `prefix`.
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
    /// Remove `key` from the trie; return true when it existed.
    pub fn remove(&mut self, key: &str) -> bool {
        remove_recursive(&mut self.root, key, 0)
    }
    /// Return the total number of complete keys stored.
    pub fn len(&self) -> usize {
        count_keys(&self.root)
    }
    /// Return true when no keys are stored.
    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }
}
/// DFS helper that collects all complete keys reachable from `node` into `result`.
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
/// Recursive removal that prunes empty leaf nodes after deletion.
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
/// Count complete keys reachable from `node`.
fn count_keys(node: &TrieNode) -> usize {
    let mut count = if node.is_end { 1 } else { 0 };
    for child in node.children.values() {
        count += count_keys(child);
    }
    count
}
