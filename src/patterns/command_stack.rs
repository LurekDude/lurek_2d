#[derive(Debug, Clone)]
pub struct CommandEntry {
    pub id: u64,
    pub name: String,
    pub has_undo: bool,
}
#[derive(Debug)]
pub struct CommandStack {
    pub max_size: usize,
    entries: Vec<CommandEntry>,
    cursor: usize,
    next_id: u64,
    pub batch_depth: usize,
    batch_buf: Vec<u64>,
}
impl CommandStack {
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
    pub fn peek_undo(&self) -> Option<u64> {
        if self.cursor == 0 {
            return None;
        }
        self.entries.get(self.cursor - 1).map(|e| e.id)
    }
    pub fn peek_redo(&self) -> Option<u64> {
        self.entries.get(self.cursor).map(|e| e.id)
    }
    pub fn step_undo(&mut self) -> Option<u64> {
        if self.cursor == 0 {
            return None;
        }
        self.cursor -= 1;
        self.entries.get(self.cursor).map(|e| e.id)
    }
    pub fn step_redo(&mut self) -> Option<u64> {
        if self.cursor >= self.entries.len() {
            return None;
        }
        let id = self.entries[self.cursor].id;
        self.cursor += 1;
        Some(id)
    }
    pub fn clear(&mut self) {
        self.entries.clear();
        self.cursor = 0;
        self.batch_buf.clear();
    }
    pub fn undo_count(&self) -> usize {
        self.cursor
    }
    pub fn redo_count(&self) -> usize {
        self.entries.len() - self.cursor
    }
    pub fn get_entry(&self, id: u64) -> Option<&CommandEntry> {
        self.entries.iter().find(|e| e.id == id)
    }
    pub fn begin_batch(&mut self) {
        self.batch_depth += 1;
    }
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
