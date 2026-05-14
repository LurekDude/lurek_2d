//! Background file request queue used for asynchronous reads and writes.
//!
//! Owns request dispatch, result caches, and the worker thread lifecycle.
//! Path resolution happens before requests enter this queue.

use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{mpsc, Arc, Mutex};
use std::thread;
/// Opaque id used to poll an asynchronous file request.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct LoadHandle(pub u64);
/// Result of an asynchronous read request.
#[derive(Debug, Clone)]
pub enum LoadResult {
    /// Read succeeded and returned bytes.
    Ready(Vec<u8>),
    /// Read failed with an error message.
    Error(String),
}
/// Read request status returned by polling a handle.
#[derive(Debug, Clone)]
pub enum LoadStatus {
    /// Request is still in flight.
    Pending,
    /// Request completed with a result.
    Done(LoadResult),
}
/// Result of an asynchronous write request.
#[derive(Debug, Clone)]
pub enum WriteResult {
    /// Write succeeded and reports the number of bytes written.
    Written(u64),
    /// Write failed with an error message.
    Error(String),
}
/// Write request status returned by polling a handle.
#[derive(Debug, Clone)]
pub enum WriteStatus {
    /// Request is still in flight.
    Pending,
    /// Request completed with a result.
    Done(WriteResult),
}
/// Internal worker request used by the async loader thread.
enum AsyncRequest {
    /// Read bytes from a resolved path.
    Read {
        /// Request handle that receives the result.
        handle: LoadHandle,
        /// Canonical path to read from.
        resolved_path: PathBuf,
    },
    /// Write bytes to a resolved path.
    Write {
        /// Request handle that receives the result.
        handle: LoadHandle,
        /// Canonical path to write to.
        resolved_path: PathBuf,
        /// Payload to write.
        bytes: Vec<u8>,
    },
}
/// Maximum number of queued async requests before new ones are dropped.
const QUEUE_CAPACITY: usize = 64;
/// Threaded loader that records asynchronous read and write results.
pub struct AsyncLoader {
    /// Monotonic request id source.
    next_id: AtomicU64,
    /// Queue sender for worker requests.
    tx: Option<mpsc::SyncSender<AsyncRequest>>,
    /// Completed read results keyed by request id.
    results: Arc<Mutex<HashMap<u64, LoadResult>>>,
    /// Completed write results keyed by request id.
    write_results: Arc<Mutex<HashMap<u64, WriteResult>>>,
    /// Background worker thread handle.
    worker: Option<thread::JoinHandle<()>>,
}
impl AsyncLoader {
    /// Create a loader with a background worker thread.
    pub fn new() -> Self {
        let (tx, rx) = mpsc::sync_channel::<AsyncRequest>(QUEUE_CAPACITY);
        let results: Arc<Mutex<HashMap<u64, LoadResult>>> = Arc::new(Mutex::new(HashMap::new()));
        let write_results: Arc<Mutex<HashMap<u64, WriteResult>>> =
            Arc::new(Mutex::new(HashMap::new()));
        let results_clone = Arc::clone(&results);
        let write_results_clone = Arc::clone(&write_results);
        let worker = thread::Builder::new()
            .name("lurek-async-loader".into())
            .spawn(move || {
                Self::worker_loop(rx, results_clone, write_results_clone);
            })
            .expect("failed to spawn async-loader thread");
        Self {
            next_id: AtomicU64::new(1),
            tx: Some(tx),
            results,
            write_results,
            worker: Some(worker),
        }
    }
    /// Queue a read request and return its handle even when the queue is full.
    pub fn request_load(&self, resolved_path: PathBuf) -> LoadHandle {
        let id = self.next_id.fetch_add(1, Ordering::Relaxed);
        let handle = LoadHandle(id);
        if let Some(ref tx) = self.tx {
            if tx
                .try_send(AsyncRequest::Read {
                    handle,
                    resolved_path: resolved_path.clone(),
                })
                .is_err()
            {
                log::warn!(
                    "Async load queue full; request dropped for '{}'",
                    resolved_path.display()
                );
                if let Ok(mut map) = self.results.lock() {
                    map.insert(id, LoadResult::Error("Async load queue is full".into()));
                }
            }
        }
        handle
    }
    /// Queue a write request and return its handle even when the queue is full.
    pub fn request_write(&self, resolved_path: PathBuf, bytes: Vec<u8>) -> LoadHandle {
        let id = self.next_id.fetch_add(1, Ordering::Relaxed);
        let handle = LoadHandle(id);
        if let Some(ref tx) = self.tx {
            if tx
                .try_send(AsyncRequest::Write {
                    handle,
                    resolved_path: resolved_path.clone(),
                    bytes,
                })
                .is_err()
            {
                log::warn!(
                    "Async write queue full; request dropped for '{}'",
                    resolved_path.display()
                );
                if let Ok(mut map) = self.write_results.lock() {
                    map.insert(id, WriteResult::Error("Async write queue is full".into()));
                }
            }
        }
        handle
    }
    /// Poll a read request and return its current status.
    pub fn poll(&self, handle: LoadHandle) -> LoadStatus {
        if let Ok(mut map) = self.results.lock() {
            if let Some(result) = map.remove(&handle.0) {
                return LoadStatus::Done(result);
            }
        }
        LoadStatus::Pending
    }
    /// Return the number of completed read results waiting to be consumed.
    pub fn pending_results(&self) -> usize {
        self.results.lock().map(|m| m.len()).unwrap_or(0)
    }
    /// Poll a write request and return its current status.
    pub fn poll_write(&self, handle: LoadHandle) -> WriteStatus {
        if let Ok(mut map) = self.write_results.lock() {
            if let Some(result) = map.remove(&handle.0) {
                return WriteStatus::Done(result);
            }
        }
        WriteStatus::Pending
    }
    /// Run the worker loop until the request channel closes.
    fn worker_loop(
        rx: mpsc::Receiver<AsyncRequest>,
        results: Arc<Mutex<HashMap<u64, LoadResult>>>,
        write_results: Arc<Mutex<HashMap<u64, WriteResult>>>,
    ) {
        for req in rx.iter() {
            match req {
                AsyncRequest::Read {
                    handle,
                    resolved_path,
                } => {
                    let result = match std::fs::read(&resolved_path) {
                        Ok(bytes) => LoadResult::Ready(bytes),
                        Err(e) => LoadResult::Error(format!(
                            "Failed to read '{}': {}",
                            resolved_path.display(),
                            e
                        )),
                    };
                    if let Ok(mut map) = results.lock() {
                        map.insert(handle.0, result);
                    }
                }
                AsyncRequest::Write {
                    handle,
                    resolved_path,
                    bytes,
                } => {
                    let result = if let Some(parent) = resolved_path.parent() {
                        match std::fs::create_dir_all(parent) {
                            Ok(()) => match std::fs::write(&resolved_path, &bytes) {
                                Ok(()) => WriteResult::Written(bytes.len() as u64),
                                Err(e) => WriteResult::Error(format!(
                                    "Failed to write '{}': {}",
                                    resolved_path.display(),
                                    e
                                )),
                            },
                            Err(e) => WriteResult::Error(format!(
                                "Failed to create parent dir for '{}': {}",
                                resolved_path.display(),
                                e
                            )),
                        }
                    } else {
                        WriteResult::Error(format!(
                            "Failed to resolve parent directory for '{}'",
                            resolved_path.display()
                        ))
                    };
                    if let Ok(mut map) = write_results.lock() {
                        map.insert(handle.0, result);
                    }
                }
            }
        }
    }
}
/// Build a new async loader with the default worker setup.
impl Default for AsyncLoader {
    fn default() -> Self {
        Self::new()
    }
}
/// Join the worker thread after dropping the request sender.
impl Drop for AsyncLoader {
    fn drop(&mut self) {
        self.tx.take();
        if let Some(handle) = self.worker.take() {
            let _ = handle.join();
        }
    }
}
