//! Named collision group manager over physics category bits.
//!
//! Maps human-readable group names (e.g. `"player"`, `"enemy"`, `"projectile"`)
//! to 16-bit category bitmasks and tracks which groups should collide.

/// Maps named collision groups to 16-bit category bitmasks.
#[derive(Clone)]
pub struct CollisionGroupSet {
    /// (name, category bit) pairs — one entry per defined group.
    groups: Vec<(String, u32)>,
    /// (group_a_idx, group_b_idx, collides) — explicit collision rules.
    collisions: Vec<(usize, usize, bool)>,
}

/// Maximum number of collision groups (16-bit bitmask).
const MAX_GROUPS: usize = 16;

impl CollisionGroupSet {
    /// Creates an empty collision group set.
    pub fn new() -> Self {
        Self {
            groups: Vec::new(),
            collisions: Vec::new(),
        }
    }

    /// Defines a new named collision group and assigns the next power-of-2 bit.
    ///
    /// Returns the assigned category bit, or an error if the name is already
    /// taken or the maximum of 16 groups has been reached.
    pub fn define_group(&mut self, name: &str) -> Result<u32, String> {
        if self.groups.len() >= MAX_GROUPS {
            return Err(format!(
                "maximum of {} collision groups reached",
                MAX_GROUPS
            ));
        }
        if self.groups.iter().any(|(n, _)| n == name) {
            return Err(format!("collision group '{}' already defined", name));
        }
        let bit = 1u32 << self.groups.len();
        self.groups.push((name.to_string(), bit));
        Ok(bit)
    }

    /// Returns the category bit for a named group, or `None` if not defined.
    pub fn get_group_bit(&self, name: &str) -> Option<u32> {
        self.groups
            .iter()
            .find(|(n, _)| n == name)
            .map(|(_, bit)| *bit)
    }

    /// Sets whether two named groups should collide with each other.
    pub fn set_collides(
        &mut self,
        group_a: &str,
        group_b: &str,
        collides: bool,
    ) -> Result<(), String> {
        let idx_a = self.group_index(group_a)?;
        let idx_b = self.group_index(group_b)?;
        let (lo, hi) = if idx_a <= idx_b {
            (idx_a, idx_b)
        } else {
            (idx_b, idx_a)
        };

        // Update existing rule or insert a new one.
        if let Some(entry) = self
            .collisions
            .iter_mut()
            .find(|(a, b, _)| *a == lo && *b == hi)
        {
            entry.2 = collides;
        } else {
            self.collisions.push((lo, hi, collides));
        }
        Ok(())
    }

    /// Returns whether two named groups collide. Defaults to `true` if no
    /// explicit rule has been set.
    pub fn get_collides(&self, group_a: &str, group_b: &str) -> bool {
        let (idx_a, idx_b) = match (self.group_index(group_a), self.group_index(group_b)) {
            (Ok(a), Ok(b)) => (a, b),
            _ => return true,
        };
        let (lo, hi) = if idx_a <= idx_b {
            (idx_a, idx_b)
        } else {
            (idx_b, idx_a)
        };
        self.collisions
            .iter()
            .find(|(a, b, _)| *a == lo && *b == hi)
            .is_none_or(|(_, _, c)| *c)
    }

    /// Computes the collision mask bits for a named group based on the stored
    /// collision rules. Any group without an explicit rule is assumed to collide.
    pub fn compute_mask(&self, group: &str) -> u32 {
        let idx = match self.group_index(group) {
            Ok(i) => i,
            Err(_) => return 0,
        };

        let mut mask = 0u32;
        for (i, (_, bit)) in self.groups.iter().enumerate() {
            let (lo, hi) = if idx <= i { (idx, i) } else { (i, idx) };
            let collides = self
                .collisions
                .iter()
                .find(|(a, b, _)| *a == lo && *b == hi)
                .is_none_or(|(_, _, c)| *c);
            if collides {
                mask |= bit;
            }
        }
        mask
    }

    /// Returns the number of defined groups.
    pub fn group_count(&self) -> usize {
        self.groups.len()
    }

    /// Returns the names of all defined groups.
    pub fn group_names(&self) -> Vec<String> {
        self.groups.iter().map(|(n, _)| n.clone()).collect()
    }

    /// Resets all groups and collision rules.
    pub fn reset(&mut self) {
        self.groups.clear();
        self.collisions.clear();
    }

    /// Returns the index of a named group, or an error if not found.
    fn group_index(&self, name: &str) -> Result<usize, String> {
        self.groups
            .iter()
            .position(|(n, _)| n == name)
            .ok_or_else(|| format!("collision group '{}' not found", name))
    }
}

impl Default for CollisionGroupSet {
    fn default() -> Self {
        Self::new()
    }
}
