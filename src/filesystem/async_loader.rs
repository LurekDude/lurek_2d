use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{mpsc, Arc, Mutex};
use std::thread;
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct LoadHandle(pub u64);
#[derive(Debug, Clone)]
pub enum LoadResult {
    Ready(Vec<u8>),
    Error(String),
}
#[derive(Debug, Clone)]
pub enum LoadStatus {
    Pending,
    Done(LoadResult),
}
#[derive(Debug, Clone)]
pub enum WriteResult {
    Written(u64),
    Error(String),
}
#[derive(Debug, Clone)]
pub enum WriteStatus {
    Pending,
    Done(WriteResult),
}
enum AsyncRequest {
    Read {
        handle: LoadHandle,
        resolved_path: PathBuf,
    },
    Write {
        handle: LoadHandle,
        resolved_path: PathBuf,
        bytes: Vec<u8>,
    },
}
const QUEUE_CAPACITY: usize = 64;
pub struct AsyncLoader {
    next_id: AtomicU64,
    tx: Option<mpsc::SyncSender<AsyncRequest>>,
    results: Arc<Mutex<HashMap<u64, LoadResult>>>,
    write_results: Arc<Mutex<HashMap<u64, WriteResult>>>,
    worker: Option<thread::JoinHandle<()>>,
}
impl AsyncLoader {
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
    pub fn poll(&self, handle: LoadHandle) -> LoadStatus {
        if let Ok(mut map) = self.results.lock() {
            if let Some(result) = map.remove(&handle.0) {
                return LoadStatus::Done(result);
            }
        }
        LoadStatus::Pending
    }
    pub fn pending_results(&self) -> usize {
        self.results.lock().map(|m| m.len()).unwrap_or(0)
    }
    pub fn poll_write(&self, handle: LoadHandle) -> WriteStatus {
        if let Ok(mut map) = self.write_results.lock() {
            if let Some(result) = map.remove(&handle.0) {
                return WriteStatus::Done(result);
            }
        }
        WriteStatus::Pending
    }
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
impl Default for AsyncLoader {
    fn default() -> Self {
        Self::new()
    }
}
impl Drop for AsyncLoader {
    fn drop(&mut self) {
        self.tx.take();
        if let Some(handle) = self.worker.take() {
            let _ = handle.join();
        }
    }
}
