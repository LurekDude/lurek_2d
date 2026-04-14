//! Markov chain name generator.
//!
//! Trains on a list of example names and generates new names by following
//! transition probabilities between character n-grams.

use std::collections::HashMap;

use crate::procgen::lcg::Lcg;

/// A Markov chain name generator.
pub struct NameGen {
    order: usize,
    chain: HashMap<String, Vec<char>>,
    rng: Lcg,
}

impl NameGen {
    /// Build a name generator from training examples.
    ///
    /// # Parameters
    /// - `training` — `&[&str]`.
    /// - `order` — `usize`.
    /// - `seed` — `u64`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// `order` is the length of the context (n-gram prefix). Typical values: 2–3.
    /// `seed` seeds the random number generator for `generate`.
    pub fn new(training: &[&str], order: usize, seed: u64) -> Self {
        let order = order.max(1);
        let mut chain: HashMap<String, Vec<char>> = HashMap::new();

        for word in training {
            // Pad start with sentinel chars so the model can begin generation
            let padded: String = std::iter::repeat('\x00')
                .take(order)
                .chain(word.chars())
                .chain(std::iter::once('\x01')) // end sentinel
                .collect();

            let chars: Vec<char> = padded.chars().collect();
            for i in 0..chars.len().saturating_sub(order) {
                let key: String = chars[i..i + order].iter().collect();
                chain.entry(key).or_default().push(chars[i + order]);
            }
        }

        Self { order, chain, rng: Lcg::new(seed) }
    }

    /// Generate a single name with length in `[min_len, max_len]`.
    ///
    /// # Parameters
    /// - `min_len` — `usize`.
    /// - `max_len` — `usize`.
    ///
    /// # Returns
    /// `String`.
    ///
    /// Returns an empty string if the model is empty or constraints cannot be met in
    /// a fixed number of tries.
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

    /// Generate `n` names.
    ///
    /// # Parameters
    /// - `n` — `usize`.
    /// - `min_len` — `usize`.
    /// - `max_len` — `usize`.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn generate_n(&mut self, n: usize, min_len: usize, max_len: usize) -> Vec<String> {
        (0..n).map(|_| self.generate(min_len, max_len)).collect()
    }

    fn try_generate(&mut self, max_len: usize) -> Option<String> {
        let mut context: Vec<char> = std::iter::repeat('\x00').take(self.order).collect();
        let mut name = String::new();

        for _ in 0..max_len + self.order + 4 {
            let key: String = context.iter().collect();
            let options = self.chain.get(&key)?;
            if options.is_empty() { return None; }

            let idx = (self.rng.next() as usize) % options.len();
            let next = options[idx];

            if next == '\x01' { break; } // end sentinel
            if next != '\x00' { name.push(next); }
            if name.len() >= max_len { break; }

            // Advance context
            context.remove(0);
            context.push(next);
        }

        if name.is_empty() { None } else { Some(capitalise(name)) }
    }
}

fn capitalise(mut s: String) -> String {
    let mut chars = s.chars();
    match chars.next() {
        None => s,
        Some(c) => c.to_uppercase().to_string() + chars.as_str(),
    }
}
