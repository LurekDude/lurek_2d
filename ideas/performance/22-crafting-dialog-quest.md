# Crafting, Dialog, Quest — Algorithmic and Threading Improvements

## Modules Covered
- `src/crafting/` — recipe matching, ingredient queues
- `src/dialog/` — typewriter, tree traversal
- `src/quest/` — objective tracking, bulk queries

---

## Crafting Module

### Current Bottleneck: Nested Recipe Search

```rust
// Approximate src/crafting/recipe.rs
pub fn find_recipes_for(&self, item_type: &str) -> Vec<&Recipe> {
    self.order.iter()
        .filter_map(|id| self.recipes.get(id.as_str()))
        .filter(|r| r.outputs.iter().any(|o| o.item_type == item_type))
        .collect()
}
```

**Complexity**: O(r × i) where r = recipes, i = outputs per recipe.
For 500 recipes × 3 outputs: **1,500 string comparisons per search**.

### Fix: Recipe Output Index

```rust
// src/crafting/recipe.rs — add output index at load time
pub struct CraftingSystem {
    recipes: HashMap<String, Recipe>,
    by_output: HashMap<String, Vec<String>>,  // item_type → recipe_ids
    by_input:  HashMap<String, Vec<String>>,  // item_type → recipe_ids
}

impl CraftingSystem {
    pub fn register_recipe(&mut self, recipe: Recipe) {
        for output in &recipe.outputs {
            self.by_output.entry(output.item_type.clone())
                .or_default().push(recipe.id.clone());
        }
        for input in &recipe.inputs {
            self.by_input.entry(input.item_type.clone())
                .or_default().push(recipe.id.clone());
        }
        self.recipes.insert(recipe.id.clone(), recipe);
    }

    pub fn find_recipes_for(&self, item_type: &str) -> Vec<&Recipe> {
        // O(1) lookup instead of O(r × i)
        self.by_output.get(item_type)
            .into_iter().flatten()
            .filter_map(|id| self.recipes.get(id.as_str()))
            .collect()
    }
}
```

**Result**: O(r × i) → **O(1)** lookup. Zero threading needed.

---

### Parallel Recipe Matching (Multiple Items)

When checking "what can I craft with this inventory?":

```rust
pub fn craftable_from_inventory(&self, inventory: &Inventory) -> Vec<&Recipe> {
    use rayon::prelude::*;
    self.recipes.par_values()
        .filter(|recipe| all_ingredients_available(inventory, recipe))
        .collect()
}
```

For 500 recipes × 10 inventory slots: **5,000 checks** → parallelized across 4 cores.

---

## Dialog Module

### Current Bottleneck: UTF-8 Typewriter Effect

The typewriter effect reveals characters one per frame. For multi-byte UTF-8
text (8-byte emoji, 3-byte CJK), finding the byte offset of the Nth character
requires a linear scan:

```rust
// Naive: O(n) per frame — scan from start every frame
let display = &self.text[..self.text.char_indices()
    .nth(self.revealed_chars).map(|(i, _)| i).unwrap_or(self.text.len())];
```

For a 1000-character dialogue line with emoji: **1000 UTF-8 decode
iterations PER FRAME** for the last character.

### Fix: Pre-Computed Character Offset Table

```rust
// src/dialog/mod.rs
pub struct DialogText {
    text: String,
    // Computed once at text assignment:
    char_offsets: Vec<usize>,  // byte offset of each character
    revealed_chars: usize,
}

impl DialogText {
    pub fn set_text(&mut self, text: String) {
        self.char_offsets = text.char_indices().map(|(i, _)| i).collect();
        self.char_offsets.push(text.len());  // sentinel
        self.text = text;
        self.revealed_chars = 0;
    }

    pub fn displayed_text(&self) -> &str {
        let end = self.char_offsets[self.revealed_chars.min(self.char_offsets.len() - 1)];
        &self.text[..end]
    }
}
```

**Result**: O(n) per frame → **O(1) per frame** (array index lookup).

---

### Dialog Tree Traversal

Branching dialogue with 100+ nodes and complex condition evaluation
(check quest flags, item ownership, relationship values) can be slow
if traversed naively:

**Fix**: Pre-compile condition expressions to bytecode at load time.
Instead of re-parsing `"quest.main >= 3 and item.key"` each traversal,
evaluate a pre-compiled byte sequence:

```rust
enum CondOp { QuestGe(String, u32), HasItem(String), And, Or, Not }
type CompiledCond = Vec<CondOp>;  // RPN bytecode
```

Evaluation is O(opcodes) with no string parsing overhead.

---

## Quest Module

### Current: O(q) Filter Scans

```rust
// src/quest/log.rs
pub fn quests_with_status(&self, status: QuestStatus) -> Vec<&Quest> {
    self.quests.values().filter(|q| q.status == status).collect()  // O(q) scan
}
pub fn active_quests(&self) -> Vec<&Quest> { self.quests_with_status(Active) }
pub fn completed_quests(&self) -> Vec<&Quest> { self.quests_with_status(Completed) }
```

With 200 quests and 10 status calls per frame: **2,000 iterations/frame**.

### Fix: Status Index Sets

```rust
pub struct QuestLog {
    quests: HashMap<QuestId, Quest>,
    // Maintain inverse index:
    by_status: HashMap<QuestStatus, HashSet<QuestId>>,
}

impl QuestLog {
    pub fn quests_with_status(&self, status: QuestStatus) -> Vec<&Quest> {
        // O(1) index lookup
        self.by_status.get(&status)
            .into_iter().flatten()
            .filter_map(|id| self.quests.get(id))
            .collect()
    }

    pub fn update_status(&mut self, id: QuestId, new_status: QuestStatus) {
        if let Some(quest) = self.quests.get_mut(&id) {
            let old_status = quest.status;
            quest.status = new_status;
            self.by_status.entry(old_status).and_modify(|s| { s.remove(&id); });
            self.by_status.entry(new_status).or_default().insert(id);
        }
    }
}
```

**Result**: O(q) scan → **O(1) lookup**. No threading needed.

---

### Parallel Objective Checking

For quests with 20+ objectives each requiring condition checks:

```rust
pub fn check_completion(&mut self, context: &GameContext) {
    use rayon::prelude::*;
    let completed_objectives: Vec<(QuestId, ObjId)> = self.quests
        .par_iter()
        .filter(|(_, q)| q.status == Active)
        .flat_map(|(qid, quest)| {
            quest.objectives.par_iter()
                .filter(|(_, obj)| !obj.completed && obj.condition.evaluate(context))
                .map(|(oid, _)| (*qid, *oid))
                .collect::<Vec<_>>()
        })
        .collect();
    
    for (qid, oid) in completed_objectives {
        self.complete_objective(qid, oid);
    }
}
```

---

## Summary

| Module | Fix | Effort | Speedup |
|--------|-----|--------|---------|
| Crafting | Recipe output index | 2 days | O(n×i) → O(1) lookup |
| Crafting | Parallel craftable check | 1 day | 4× for 500+ recipes |
| Dialog | Pre-computed char offsets | 1 day | O(n) → O(1) per frame |
| Dialog | Compiled condition bytecode | 3 days | 10× condition eval |
| Quest | Status index sets | 2 days | O(q) → O(1) per call |
| Quest | Parallel objective check | 2 days | 4× for many active quests |
