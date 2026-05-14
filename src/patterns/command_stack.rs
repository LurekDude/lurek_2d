
/// Metadata record for a single pushed command.
#[derive(Debug, Clone)]
pub struct CommandEntry {
    /// Monotonically increasing identifier assigned at push time.
    pub id: u64,
    /// Human-readable command name for display.
    pub name: String,
    /// Whether an undo callback is registered for this command.
    pub has_undo: bool,
}
/// Linear undo/redo history with optional batch mode.
#[derive(Debug)]
pub struct CommandStack {
    /// Maximum history entries; `0` means unbounded.
    pub max_size: usize,
    /// History buffer; entries past `cursor` are redo candidates.
    entries: Vec<CommandEntry>,
    /// Index of the next redo entry; all entries before this index are undoable.
    cursor: usize,
    /// Next identifier to assign.
    next_id: u64,
    /// Batch nesting depth; `> 0` means a batch is open.
    pub batch_depth: usize,
    /// Ids accumulated during the current open batch.
    batch_buf: Vec<u64>,
}
/// All methods for `CommandStack`.
impl CommandStack {
    /// Create a stack with `max_size` history limit (`0` = unbounded).
    pub fn new(max_size: usize) -> Self {
        Self {
            max_size,
            entries: Vec::new(),
            cursor: 0,
            next_id: 1,
            batch_depth: 0,
            batch_buf: Vec::new(),
        }
    }
    /// Append a command named `name` with undo flag, truncating any redo future; return the new id.
    pub fn push(&mut self, name: &str, has_undo: bool) -> u64 {
        self.entries.truncate(self.cursor);
        let id = self.next_id;
        self.next_id += 1;
        self.entries.push(CommandEntry {
            id,
            name: name.to_string(),
            has_undo,
        });
        self.cursor = self.entries.len();
        if self.max_size > 0 && self.entries.len() > self.max_size {
            let surplus = self.entries.len() - self.max_size;
            self.entries.drain(..surplus);
            self.cursor = self.cursor.saturating_sub(surplus);
        }
        if self.batch_depth > 0 {
            self.batch_buf.push(id);
        }
        id
    }
    /// Return the id of the most recent undoable command without moving the cursor.
    pub fn peek_undo(&self) -> Option<u64> {
        if self.cursor == 0 {
            return None;
        }
        self.entries.get(self.cursor - 1).map(|e| e.id)
    }
    /// Return the id of the next redoable command without moving the cursor.
    pub fn peek_redo(&self) -> Option<u64> {
        self.entries.get(self.cursor).map(|e| e.id)
    }
    /// Move the cursor back one step and return the id of the command to undo.
    pub fn step_undo(&mut self) -> Option<u64> {
        if self.cursor == 0 {
            return None;
        }
        self.cursor -= 1;
        self.entries.get(self.cursor).map(|e| e.id)
    }
    /// Move the cursor forward one step and return the id of the command to redo.
    pub fn step_redo(&mut self) -> Option<u64> {
        if self.cursor >= self.entries.len() {
            return None;
        }
        let id = self.entries[self.cursor].id;
        self.cursor += 1;
        Some(id)
    }
    /// Clear all history and reset the cursor.
    pub fn clear(&mut self) {
        self.entries.clear();
        self.cursor = 0;
        self.batch_buf.clear();
    }
    /// Return the number of undoable commands.
    pub fn undo_count(&self) -> usize {
        self.cursor
    }
    /// Return the number of redoable commands.
    pub fn redo_count(&self) -> usize {
        self.entries.len() - self.cursor
    }
    /// Return a reference to the entry with the given `id`, or `None`.
    pub fn get_entry(&self, id: u64) -> Option<&CommandEntry> {
        self.entries.iter().find(|e| e.id == id)
    }
    /// Increment batch depth; commands pushed while depth > 0 are grouped.
    pub fn begin_batch(&mut self) {
        self.batch_depth += 1;
    }
    /// Decrement batch depth; return the grouped id list when depth reaches 0.
    pub fn end_batch(&mut self) -> Option<Vec<u64>> {
        if self.batch_depth == 0 {
            return None;
        }
        self.batch_depth -= 1;
        if self.batch_depth == 0 {
            let ids = std::mem::take(&mut self.batch_buf);
            Some(ids)
        } else {
            None
        }
    }
}
