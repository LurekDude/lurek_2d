//! Thread pool for asynchronous path computation.
//!
//! Pathfinding requests are submitted with an ID and processed on worker
//! threads. Results are collected via non-blocking [`PathThreadPool::poll`].
//!
//! This module is part of Luna2D's `pathfinding` subsystem and provides the implementation
//! details for async pool-related operations and data management.
//! Key types exported from this module: `PathThreadPool`.
//! Primary functions: `new()`, `submit()`, `poll()`, `cancel()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::sync::mpsc::{self, Receiver, Sender};
use std::sync::{Arc, Mutex};
use std::thread;

use crate::pathfinding::astar;
use crate::pathfinding::nav_grid::NavGrid;

/// A request submitted to the thread pool.
struct PathRequest {
    /// Caller-assigned identifier.
    id: u64,
    /// Snapshot of the navigation grid.
    grid: NavGrid,
    /// Start position.
    start: (u32, u32),
    /// Goal position.
    goal: (u32, u32),
    /// Unit footprint size.
    unit_size: u32,
}

/// A completed path result returned by [`PathThreadPool::poll`].
pub type PathResult = (u64, Option<Vec<(u32, u32)>>);

/// A pool of worker threads that process pathfinding requests asynchronously.
///
/// # Fields
/// - `tx` — `Sender<PathRequest>`.
/// - `rx` — `Receiver<PathResult>`.
/// - `cancelled` — `Arc<Mutex<Vec<u64>>>`.
/// - `thread_count` — `usize`.
/// - `_handles` — `Vec<thread::JoinHandle<()>>`.
/// - `pending` — `Arc<Mutex<u32>>`.
pub struct PathThreadPool {
    /// Sender for dispatching work items.
    tx: Sender<PathRequest>,
    /// Receiver for completed results.
    rx: Receiver<PathResult>,
    /// Set of cancelled request IDs.
    cancelled: Arc<Mutex<Vec<u64>>>,
    /// Number of worker threads.
    thread_count: usize,
    /// Per-worker join handles.
    _handles: Vec<thread::JoinHandle<()>>,
    /// Number of requests submitted but not yet polled.
    pending: Arc<Mutex<u32>>,
}

impl PathThreadPool {
    /// Spawn `thread_count` workers ready to process path requests.
    ///
    /// # Parameters
    /// - `thread_count` — `usize`.
    ///
    /// # Returns
    /// `Self`.
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

            let handle = thread::spawn(move || {
                loop {
                    let req = {
                        let lock = rx.lock();
                        match lock {
                            Ok(guard) => match guard.recv() {
                                Ok(r) => r,
                                Err(_) => return, // channel closed
                            },
                            Err(_) => return,
                        }
                    };

                    // Check cancellation before computing
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

                    // Check cancellation after computing
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

    /// Submit a pathfinding request. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `id` — `u64`.
    /// - `grid_snapshot` — `NavGrid`.
    /// - `start` — `(u32, u32)`.
    /// - `goal` — `(u32, u32)`.
    /// - `unit_size` — `u32`.
    ///
    /// `grid_snapshot` should be created via [`NavGrid::snapshot`] to safely
    /// send grid data to a worker thread.
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

    /// Collect all completed results without blocking.
    ///
    /// # Returns
    /// `Vec<PathResult>`.
    ///
    /// Returns `(id, path)` pairs for finished requests.
    pub fn poll(&self) -> Vec<PathResult> {
        let mut results = Vec::new();
        while let Ok(result) = self.rx.try_recv() {
            results.push(result);
        }
        results
    }

    /// Mark a request as cancelled (best-effort — may already be in progress).
    ///
    /// # Parameters
    /// - `id` — `u64`.
    pub fn cancel(&self, id: u64) {
        if let Ok(mut cancelled) = self.cancelled.lock() {
            if !cancelled.contains(&id) {
                cancelled.push(id);
            }
        }
    }

    /// Number of requests submitted but not yet returned via [`poll`].
    ///
    /// # Returns
    /// `u32`.
    pub fn pending_count(&self) -> u32 {
        self.pending.lock().map(|p| *p).unwrap_or(0)
    }

    /// Update the thread count. Takes effect on next pool creation only;
    /// existing workers continue until the pool is dropped.
    ///
    /// # Parameters
    /// - `count` — `usize`.
    pub fn set_thread_count(&mut self, count: usize) {
        self.thread_count = count.max(1);
    }

    /// Current configured thread count. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_thread_count(&self) -> usize {
        self.thread_count
    }
}
