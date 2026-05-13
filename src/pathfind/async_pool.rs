use crate::pathfind::astar;
use crate::pathfind::nav_grid::NavGrid;
use std::sync::mpsc::{self, Receiver, Sender};
use std::sync::{Arc, Mutex};
use std::thread;
struct PathRequest {
    id: u64,
    grid: NavGrid,
    start: (u32, u32),
    goal: (u32, u32),
    unit_size: u32,
}
pub type PathResult = (u64, Option<Vec<(u32, u32)>>);
pub struct PathThreadPool {
    tx: Sender<PathRequest>,
    rx: Receiver<PathResult>,
    cancelled: Arc<Mutex<Vec<u64>>>,
    thread_count: usize,
    _handles: Vec<thread::JoinHandle<()>>,
    pending: Arc<Mutex<u32>>,
}
impl PathThreadPool {
    pub fn new(thread_count: usize) -> Self {
        let count = thread_count.max(1);
        let (work_tx, work_rx) = mpsc::channel::<PathRequest>();
        let (result_tx, result_rx) = mpsc::channel::<PathResult>();
        let work_rx = Arc::new(Mutex::new(work_rx));
        let cancelled: Arc<Mutex<Vec<u64>>> = Arc::new(Mutex::new(Vec::new()));
        let pending: Arc<Mutex<u32>> = Arc::new(Mutex::new(0));
        let mut handles = Vec::with_capacity(count);
        for _ in 0..count {
            let rx = Arc::clone(&work_rx);
            let tx = result_tx.clone();
            let cancel = Arc::clone(&cancelled);
            let pend = Arc::clone(&pending);
            let handle = thread::spawn(move || loop {
                let req = {
                    let lock = rx.lock();
                    match lock {
                        Ok(guard) => match guard.recv() {
                            Ok(r) => r,
                            Err(_) => return,
                        },
                        Err(_) => return,
                    }
                };
                {
                    let cancelled_ids = cancel.lock().unwrap_or_else(|e| e.into_inner());
                    if cancelled_ids.contains(&req.id) {
                        if let Ok(mut p) = pend.lock() {
                            *p = p.saturating_sub(1);
                        }
                        continue;
                    }
                }
                let (path, _complete) =
                    astar::astar(&req.grid, req.start, req.goal, req.unit_size, 0);
                {
                    let cancelled_ids = cancel.lock().unwrap_or_else(|e| e.into_inner());
                    if cancelled_ids.contains(&req.id) {
                        if let Ok(mut p) = pend.lock() {
                            *p = p.saturating_sub(1);
                        }
                        continue;
                    }
                }
                let _ = tx.send((req.id, path));
                if let Ok(mut p) = pend.lock() {
                    *p = p.saturating_sub(1);
                }
            });
            handles.push(handle);
        }
        Self {
            tx: work_tx,
            rx: result_rx,
            cancelled,
            thread_count: count,
            _handles: handles,
            pending,
        }
    }
    pub fn submit(
        &self,
        id: u64,
        grid_snapshot: NavGrid,
        start: (u32, u32),
        goal: (u32, u32),
        unit_size: u32,
    ) {
        if let Ok(mut p) = self.pending.lock() {
            *p += 1;
        }
        let _ = self.tx.send(PathRequest {
            id,
            grid: grid_snapshot,
            start,
            goal,
            unit_size,
        });
    }
    pub fn poll(&self) -> Vec<PathResult> {
        let mut results = Vec::new();
        while let Ok(result) = self.rx.try_recv() {
            results.push(result);
        }
        results
    }
    pub fn cancel(&self, id: u64) {
        if let Ok(mut cancelled) = self.cancelled.lock() {
            if !cancelled.contains(&id) {
                cancelled.push(id);
            }
        }
    }
    pub fn pending_count(&self) -> u32 {
        self.pending.lock().map(|p| *p).unwrap_or(0)
    }
    pub fn set_thread_count(&mut self, count: usize) {
        self.thread_count = count.max(1);
    }
    pub fn get_thread_count(&self) -> usize {
        self.thread_count
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn default_thread_count() {
        let pool = PathThreadPool::new(1);
        assert!(pool.get_thread_count() >= 1);
    }
    #[test]
    fn set_thread_count_minimum_one() {
        let mut pool = PathThreadPool::new(1);
        pool.set_thread_count(0);
        assert_eq!(pool.get_thread_count(), 1);
        pool.set_thread_count(4);
        assert_eq!(pool.get_thread_count(), 4);
    }
}
