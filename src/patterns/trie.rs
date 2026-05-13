#[derive(Debug, Default)]
struct TrieNode {
    children: std::collections::HashMap<char, TrieNode>,
    is_end: bool,
}
#[derive(Debug, Default)]
pub struct Trie {
    root: TrieNode,
}
impl Trie {
    pub fn new() -> Self {
        Self::default()
    }
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
    pub fn remove(&mut self, key: &str) -> bool {
        remove_recursive(&mut self.root, key, 0)
    }
    pub fn len(&self) -> usize {
        count_keys(&self.root)
    }
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
