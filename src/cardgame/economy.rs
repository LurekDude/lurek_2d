//! Economic primitives: resource pools and pot management.
//!
//! Resources and tokens are fully user-defined (chips, gold, mana, VP, etc.).
//! This module provides the machinery for transferring them between players
//! and into/out of a shared pot.

use std::collections::HashMap;

// ─────────────────────────────────────────────────────────────────────────────
// ResourcePool — per-player resource ledger
// ─────────────────────────────────────────────────────────────────────────────

/// A ledger of one named resource type across all players.
///
/// Create one `ResourcePool` per resource type (e.g. one for `"gold"`,
/// one for `"chips"`), or use a single pool with an `"amount"` key.
#[derive(Debug, Clone)]
pub struct ResourcePool {
    /// Resource name (user-defined, e.g. `"chips"`, `"mana"`, `"points"`).
    pub name: String,
    /// Amount held by each player.
    balances: HashMap<String, f64>,
}

impl ResourcePool {
    /// Create an empty resource pool for a named resource.
    pub fn new(name: impl Into<String>) -> Self {
        Self { name: name.into(), balances: HashMap::new() }
    }

    /// Set a player's balance directly.
    pub fn set(&mut self, player_id: impl Into<String>, amount: f64) {
        self.balances.insert(player_id.into(), amount);
    }

    /// Get a player's balance (`0.0` if not set).
    pub fn get(&self, player_id: &str) -> f64 {
        *self.balances.get(player_id).unwrap_or(&0.0)
    }

    /// Add `amount` to a player's balance and return the new total.
    pub fn add(&mut self, player_id: impl Into<String>, amount: f64) -> f64 {
        let v = self.balances.entry(player_id.into()).or_insert(0.0);
        *v += amount;
        *v
    }

    /// Spend `amount` from a player's balance.
    ///
    /// Returns `Ok(remaining)` on success, `Err` if the balance is insufficient.
    pub fn spend(&mut self, player_id: &str, amount: f64) -> Result<f64, String> {
        let v = self.balances.entry(player_id.to_owned()).or_insert(0.0);
        if *v < amount {
            return Err(format!(
                "Insufficient '{}' for '{}': need {}, have {}",
                self.name, player_id, amount, v
            ));
        }
        *v -= amount;
        Ok(*v)
    }

    /// Transfer `amount` from `from` to `to`.
    ///
    /// Returns `Err` if `from` has insufficient balance.
    pub fn transfer(&mut self, from: &str, to: &str, amount: f64) -> Result<(), String> {
        {
            let from_bal = self.balances.entry(from.to_owned()).or_insert(0.0);
            if *from_bal < amount {
                return Err(format!(
                    "'{}' has insufficient '{}': need {}, have {}",
                    from, self.name, amount, from_bal
                ));
            }
            *from_bal -= amount;
        }
        *self.balances.entry(to.to_owned()).or_insert(0.0) += amount;
        Ok(())
    }

    /// Total of all balances.
    pub fn total(&self) -> f64 {
        self.balances.values().sum()
    }

    /// Return all (player_id, balance) pairs.
    pub fn all_balances(&self) -> Vec<(String, f64)> {
        self.balances.iter().map(|(k, v)| (k.clone(), *v)).collect()
    }

    /// Player IDs with a balance above zero.
    pub fn solvent_players(&self) -> Vec<String> {
        self.balances
            .iter()
            .filter(|(_, &v)| v > 0.0)
            .map(|(k, _)| k.clone())
            .collect()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pot — shared pool for betting/awarding
// ─────────────────────────────────────────────────────────────────────────────

/// A shared pot of resources (for betting, jackpots, or prize pools).
///
/// Players contribute to the pot; a winner (or winners) receive its contents.
#[derive(Debug, Clone, Default)]
pub struct Pot {
    /// Total amount currently in the pot.
    pub amount: f64,
}

impl Pot {
    /// Create an empty pot.
    pub fn new() -> Self {
        Self::default()
    }

    /// Add `amount` to the pot (e.g. player ante).
    pub fn contribute(&mut self, amount: f64) {
        self.amount += amount.max(0.0);
    }

    /// Contribute from a `ResourcePool` player balance into the pot.
    ///
    /// Returns `Err` if the player has insufficient funds.
    pub fn ante_from(
        &mut self,
        pool: &mut ResourcePool,
        player_id: &str,
        amount: f64,
    ) -> Result<(), String> {
        pool.spend(player_id, amount)?;
        self.amount += amount;
        Ok(())
    }

    /// Award the entire pot to a single player in `pool` and clear the pot.
    pub fn award(&mut self, pool: &mut ResourcePool, player_id: impl Into<String>) -> f64 {
        let won = self.amount;
        pool.add(player_id, won);
        self.amount = 0.0;
        won
    }

    /// Split the pot evenly among `winners` in `pool` and clear the pot.
    ///
    /// Any remainder from integer division stays in the pot (or can be
    /// redistibuted by the game designer).
    pub fn split_award(&mut self, pool: &mut ResourcePool, winners: &[&str]) -> f64 {
        if winners.is_empty() {
            return 0.0;
        }
        let share = (self.amount / winners.len() as f64).floor();
        let remainder = self.amount - share * winners.len() as f64;
        for &w in winners {
            pool.add(w, share);
        }
        self.amount = remainder;
        share
    }

    /// Clear the pot without awarding anyone (e.g. hand ends in a fold).
    pub fn clear(&mut self) {
        self.amount = 0.0;
    }

    /// Returns `true` if the pot holds no resources.
    pub fn is_empty(&self) -> bool {
        self.amount == 0.0
    }
}
