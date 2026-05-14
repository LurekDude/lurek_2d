
use crate::pathfind::astar;
use std::sync::{Arc, Mutex};
use std::thread;
/// In-flight A\* job sent to a worker thread.
struct PathRequest {
    /// Caller-assigned request identifier for correlation and cancellation.
    id: u64,
    /// Grid snapshot cloned at submission time so the worker owns it fully.
    grid: NavGrid,
    /// Starting cell.
    start: (u32, u32),
    /// Destination cell.
    goal: (u32, u32),
    /// Footprint size forwarded to A\*.
    unit_size: u32,
}
/// Completed result returned from a worker: `(request_id, path_or_none)`.
pub type PathResult = (u64, Option<Vec<(u32, u32)>>);

/// Fixed-size worker pool that runs A\* off the game thread and delivers results via a channel.
pub struct PathThreadPool {
    /// Sender side of the work queue.
    tx: Sender<PathRequest>,
    /// Receiver for completed results polled each frame.
    rx: Receiver<PathResult>,
    /// Shared list of ids to skip before or during execution.
    cancelled: Arc<Mutex<Vec<u64>>>,
    /// Configured worker-thread count.
    thread_count: usize,
    /// Owned join handles kept alive as long as the pool lives.
    _handles: Vec<thread::JoinHandle<()>>,
    /// Number of jobs currently in-flight (submitted but not yet returned).
    pending: Arc<Mutex<u32>>,
}
/// Construction and job management for `PathThreadPool`.
impl PathThreadPool {
    /// Spawn `thread_count` workers (minimum 1) and connect them to shared channels.
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
    /// Submit an A\* job; caller must pass a cloned grid snapshot.
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
    /// Drain all available completed results without blocking.
    pub fn poll(&self) -> Vec<PathResult> {
        let mut results = Vec::new();
        while let Ok(result) = self.rx.try_recv() {
            results.push(result);
        }
        results
    }
    /// Mark `id` as cancelled; workers skip it if still queued.
    pub fn cancel(&self, id: u64) {
        if let Ok(mut cancelled) = self.cancelled.lock() {
            if !cancelled.contains(&id) {
                cancelled.push(id);
            }
        }
    }
    /// Return the number of jobs submitted but not yet delivered.
    pub fn pending_count(&self) -> u32 {
        self.pending.lock().map(|p| *p).unwrap_or(0)
    }
    /// Update the recorded thread count; does not respawn existing workers.
    pub fn set_thread_count(&mut self, count: usize) {
        self.thread_count = count.max(1);
    }
    /// Return the configured worker thread count.
    pub fn get_thread_count(&self) -> usize {
        self.thread_count
    }
}
