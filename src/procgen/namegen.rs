//! Markov-chain name generator for `src/procgen`.
//! Owns `NameGen` which trains an n-gram character chain on example words and
//! samples from it to produce plausible new names. Does not own world graph or
//! region labelling — those live in `world_graph.rs`.

use crate::procgen::lcg::Lcg;
use std::collections::HashMap;

/// Markov-chain name generator trained on a corpus of example strings.
pub struct NameGen {
    /// N-gram order; higher values produce more faithful but less varied names.
    order: usize,
    /// Map from n-gram key string to list of observed following characters.
    chain: HashMap<String, Vec<char>>,
    /// Internal LCG for reproducible sampling.
    rng: Lcg,
}

impl NameGen {
    /// Build a chain from `training` words at the given `order` and deterministic `seed`.
    pub fn new(training: &[&str], order: usize, seed: u64) -> Self {
        let order = order.max(1);
        let mut chain: HashMap<String, Vec<char>> = HashMap::new();
        for word in training {
            let padded: String = std::iter::repeat_n('\x00', order)
                .chain(word.chars())
                .chain(std::iter::once('\x01'))
                .collect();
            let chars: Vec<char> = padded.chars().collect();
            for i in 0..chars.len().saturating_sub(order) {
                let key: String = chars[i..i + order].iter().collect();
                chain.entry(key).or_default().push(chars[i + order]);
            }
        }
        Self {
            order,
            chain,
            rng: Lcg::new(seed),
        }
    }

    /// Sample up to 64 candidate names and return the first one with `min_len..=max_len` characters; returns an empty string when all attempts fail.
    pub fn generate(&mut self, min_len: usize, max_len: usize) -> String {
        for _ in 0..64 {
            if let Some(name) = self.try_generate(max_len) {
                if name.len() >= min_len {
                    return name;
                }
            }
        }
        String::new()
    }

    /// Generate `n` names each satisfying `min_len`/`max_len`; names that fail all attempts are empty strings.
    pub fn generate_n(&mut self, n: usize, min_len: usize, max_len: usize) -> Vec<String> {
        (0..n).map(|_| self.generate(min_len, max_len)).collect()
    }

    /// Attempt one chain walk up to `max_len` characters; returns `None` when the chain has no successor.
    fn try_generate(&mut self, max_len: usize) -> Option<String> {
        let mut context: Vec<char> = std::iter::repeat_n('\x00', self.order).collect();
        let mut name = String::new();
        for _ in 0..max_len + self.order + 4 {
            let key: String = context.iter().collect();
            let options = self.chain.get(&key)?;
            if options.is_empty() {
                return None;
            }
            let idx = (self.rng.next() as usize) % options.len();
            let next = options[idx];
            if next == '\x01' {
                break;
            }
            if next != '\x00' {
                name.push(next);
            }
            if name.len() >= max_len {
                break;
            }
            context.remove(0);
            context.push(next);
        }
        if name.is_empty() {
            None
        } else {
            Some(capitalise(name))
        }
    }
}

/// Capitalise the first character of `s`; returns `s` unchanged when empty.
fn capitalise(s: String) -> String {
    let mut chars = s.chars();
    match chars.next() {
        None => s,
        Some(c) => c.to_uppercase().to_string() + chars.as_str(),
    }
}
    order: usize,
    chain: HashMap<String, Vec<char>>,
    rng: Lcg,
}
impl NameGen {
    pub fn new(training: &[&str], order: usize, seed: u64) -> Self {
        let order = order.max(1);
        let mut chain: HashMap<String, Vec<char>> = HashMap::new();
        for word in training {
            let padded: String = std::iter::repeat_n('\x00', order)
                .chain(word.chars())
                .chain(std::iter::once('\x01'))
                .collect();
            let chars: Vec<char> = padded.chars().collect();
            for i in 0..chars.len().saturating_sub(order) {
                let key: String = chars[i..i + order].iter().collect();
                chain.entry(key).or_default().push(chars[i + order]);
            }
        }
        Self {
            order,
            chain,
            rng: Lcg::new(seed),
        }
    }
    pub fn generate(&mut self, min_len: usize, max_len: usize) -> String {
        for _ in 0..64 {
            if let Some(name) = self.try_generate(max_len) {
                if name.len() >= min_len {
                    return name;
                }
            }
        }
        String::new()
    }
    pub fn generate_n(&mut self, n: usize, min_len: usize, max_len: usize) -> Vec<String> {
        (0..n).map(|_| self.generate(min_len, max_len)).collect()
    }
    fn try_generate(&mut self, max_len: usize) -> Option<String> {
        let mut context: Vec<char> = std::iter::repeat_n('\x00', self.order).collect();
        let mut name = String::new();
        for _ in 0..max_len + self.order + 4 {
            let key: String = context.iter().collect();
            let options = self.chain.get(&key)?;
            if options.is_empty() {
                return None;
            }
            let idx = (self.rng.next() as usize) % options.len();
            let next = options[idx];
            if next == '\x01' {
                break;
            }
            if next != '\x00' {
                name.push(next);
            }
            if name.len() >= max_len {
                break;
            }
            context.remove(0);
            context.push(next);
        }
        if name.is_empty() {
            None
        } else {
            Some(capitalise(name))
        }
    }
}
fn capitalise(s: String) -> String {
    let mut chars = s.chars();
    match chars.next() {
        None => s,
        Some(c) => c.to_uppercase().to_string() + chars.as_str(),
    }
}
