//! Craft job queue for timed crafting operations.
//!
//! This module is part of Luna2D's `crafting` subsystem and provides the implementation
//! details for queue-related operations and data management.
//! Key types exported from this module: `CraftJob`, `CraftQueue`.
//! Primary functions: `new()`, `advance()`, `percent()`, `new()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

/// A single in-progress or queued crafting job.
///
/// # Fields
/// - `id`: Stable queue-local job identifier.
/// - `recipe_id`: Recipe being crafted.
/// - `progress`: Elapsed craft time in seconds.
/// - `total_time`: Total craft duration in seconds.
/// - `quantity`: Number of recipe executions requested.
/// - `completed`: Whether the job has finished.
/// - `paused`: Whether time advancement is currently suspended.
/// - `status`: Queue state such as `"queued"`, `"active"`, or `"complete"`.
#[derive(Debug, Clone)]
pub struct CraftJob {
    pub id: u32,
    pub recipe_id: String,
    pub progress: f64,
    pub total_time: f64,
    pub quantity: u32,
    pub completed: bool,
    pub paused: bool,
    /// `"queued"`, `"active"`, `"complete"`, `"cancelled"`, `"failed"`.
    pub status: String,
}

impl CraftJob {
    /// Create a new crafting job. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `id`: Stable queue-local job identifier.
    /// - `recipe_id`: Recipe being crafted.
    /// - `total_time`: Total craft duration in seconds.
    /// - `quantity`: Number of recipe executions requested.
    ///
    /// # Returns
    /// An active job with zero progress.
    pub fn new(id: u32, recipe_id: impl Into<String>, total_time: f64, quantity: u32) -> Self {
        Self {
            id,
            recipe_id: recipe_id.into(),
            progress: 0.0,
            total_time,
            quantity,
            completed: false,
            paused: false,
            status: "active".into(),
        }
    }

    /// Advance the job by `dt` seconds. Returns `true` when newly completed.
    ///
    /// # Parameters
    /// - `dt`: Elapsed time in seconds to add to the job.
    ///
    /// # Returns
    /// `true` if the job crossed its completion threshold during this call.
    pub fn advance(&mut self, dt: f64) -> bool {
        if self.completed || self.paused { return false; }
        self.progress += dt;
        if self.progress >= self.total_time {
            self.completed = true;
            self.status = "complete".into();
            true
        } else {
            false
        }
    }

    /// Completion ratio in [0.0, 1.0]. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// The clamped completion percentage for the job.
    pub fn percent(&self) -> f64 {
        if self.total_time <= 0.0 { 1.0 } else { (self.progress / self.total_time).min(1.0) }
    }
}

/// Queue that holds and ticks active craft jobs.
///
/// # Fields
/// - `jobs` — `Vec<CraftJob>`.
/// - `max_jobs` — `usize`.
/// - `max_concurrent` — `usize`.
/// - `next_id` — `u32`.
#[derive(Debug)]
pub struct CraftQueue {
    jobs: Vec<CraftJob>,
    max_jobs: usize,
    /// Maximum simultaneously active jobs (rest wait as `"queued"`).
    max_concurrent: usize,
    next_id: u32,
}

impl CraftQueue {
    /// Create an empty crafting queue. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `max_jobs`: Maximum number of jobs the queue can hold.
    ///
    /// # Returns
    /// An empty queue with one active slot.
    pub fn new(max_jobs: usize) -> Self {
        Self { jobs: Vec::new(), max_jobs, max_concurrent: 1, next_id: 1 }
    }

    /// Set the maximum number of simultaneously active jobs.
    ///
    /// # Parameters
    /// - `n`: Desired concurrent active job count, clamped to at least `1`.
    pub fn set_max_concurrent(&mut self, n: usize) {
        self.max_concurrent = n.max(1);
    }

    /// Submit a new job. Returns the job ID, or `None` if the queue is full.
    ///
    /// # Parameters
    /// - `recipe_id`: Recipe identifier for the job.
    /// - `total_time`: Total craft duration in seconds.
    /// - `quantity`: Number of recipe executions requested.
    ///
    /// # Returns
    /// The assigned job ID, or `None` when the queue is full.
    pub fn enqueue(&mut self, recipe_id: impl Into<String>, total_time: f64, quantity: u32) -> Option<u32> {
        if self.jobs.len() >= self.max_jobs { return None; }
        let id = self.next_id;
        self.next_id += 1;
        let active_count = self.jobs.iter().filter(|j| j.status == "active").count();
        let status = if active_count < self.max_concurrent { "active" } else { "queued" };
        let mut job = CraftJob::new(id, recipe_id, total_time, quantity);
        job.status = status.into();
        self.jobs.push(job);
        Some(id)
    }

    /// Cancel a job by ID. Returns `true` if found and removed.
    ///
    /// # Parameters
    /// - `id`: Queue-local job identifier to remove.
    ///
    /// # Returns
    /// `true` if a matching job was removed.
    pub fn cancel(&mut self, id: u32) -> bool {
        let before = self.jobs.len();
        self.jobs.retain(|j| j.id != id);
        let removed = self.jobs.len() < before;
        if removed { self.promote_queued(); }
        removed
    }

    /// Tick all active jobs. Returns IDs of newly completed jobs.
    ///
    /// # Parameters
    /// - `dt`: Elapsed time in seconds to add to active jobs.
    ///
    /// # Returns
    /// IDs of jobs that completed during this update.
    pub fn update(&mut self, dt: f64) -> Vec<u32> {
        let mut finished = Vec::new();
        for job in &mut self.jobs {
            if job.status == "active" && job.advance(dt) {
                finished.push(job.id);
            }
        }
        finished
    }

    /// Remove completed jobs and return their IDs.
    ///
    /// # Returns
    /// IDs of completed jobs removed from the queue.
    pub fn collect_completed(&mut self) -> Vec<u32> {
        let mut ids = Vec::new();
        self.jobs.retain(|j| {
            if j.completed { ids.push(j.id); false } else { true }
        });
        if !ids.is_empty() { self.promote_queued(); }
        ids
    }

    /// Get a reference to a job by ID.
    ///
    /// # Parameters
    /// - `id`: Queue-local job identifier to query.
    ///
    /// # Returns
    /// An immutable reference to the matching job, if present.
    pub fn get_job(&self, id: u32) -> Option<&CraftJob> {
        self.jobs.iter().find(|j| j.id == id)
    }

    /// Get a mutable reference to a job by ID.
    ///
    /// # Parameters
    /// - `id`: Queue-local job identifier to query.
    ///
    /// # Returns
    /// A mutable reference to the matching job, if present.
    pub fn get_job_mut(&mut self, id: u32) -> Option<&mut CraftJob> {
        self.jobs.iter_mut().find(|j| j.id == id)
    }

    /// Cancel all jobs. After this call the container is in the same state as immediately after construction.
    pub fn clear(&mut self) { self.jobs.clear(); }

    /// Return the number of jobs currently in the queue.
    ///
    /// # Returns
    /// The total job count, including queued and active jobs.
    pub fn count(&self) -> usize { self.jobs.len() }

    /// Whether the queue has reached its capacity.
    ///
    /// # Returns
    /// `true` if no additional jobs can be enqueued.
    pub fn is_full(&self) -> bool { self.jobs.len() >= self.max_jobs }

    /// Return the configured queue capacity. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// The maximum number of jobs allowed in the queue.
    pub fn max_jobs(&self) -> usize { self.max_jobs }

    /// All job IDs. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// Queue-local job IDs in storage order.
    pub fn ids(&self) -> Vec<u32> { self.jobs.iter().map(|j| j.id).collect() }

    /// Summary tuples: `(id, recipe_id, quantity, progress, paused)`.
    ///
    /// # Returns
    /// Lightweight summaries for every job in storage order.
    pub fn all_jobs(&self) -> Vec<(u32, String, u32, f64, bool)> {
        self.jobs.iter()
            .map(|j| (j.id, j.recipe_id.clone(), j.quantity, j.progress, j.paused))
            .collect()
    }

    /// Active job IDs (status == `"active"`). Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// IDs of jobs that are currently advancing.
    pub fn active_ids(&self) -> Vec<u32> {
        self.jobs.iter().filter(|j| j.status == "active").map(|j| j.id).collect()
    }

    /// Queued (waiting) job IDs. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// IDs of jobs waiting for an active slot.
    pub fn queued_ids(&self) -> Vec<u32> {
        self.jobs.iter().filter(|j| j.status == "queued").map(|j| j.id).collect()
    }

    // Promote queued jobs to active when slots open.
    fn promote_queued(&mut self) {
        let active = self.jobs.iter().filter(|j| j.status == "active" && !j.completed).count();
        let mut slots = self.max_concurrent.saturating_sub(active);
        for job in &mut self.jobs {
            if slots == 0 { break; }
            if job.status == "queued" {
                job.status = "active".into();
                slots -= 1;
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn craft_queue() {
        let mut queue = CraftQueue::new(5);
        let id = queue.enqueue("sword", 2.0, 1).unwrap();
        queue.update(1.0);
        assert!(!queue.get_job(id).unwrap().completed);
        queue.update(1.5);
        assert!(queue.get_job(id).unwrap().completed);
    }

    #[test]
    fn queue_max_concurrent() {
        let mut queue = CraftQueue::new(10);
        queue.set_max_concurrent(2);
        let id1 = queue.enqueue("a", 5.0, 1).unwrap();
        let id2 = queue.enqueue("b", 5.0, 1).unwrap();
        let id3 = queue.enqueue("c", 5.0, 1).unwrap();

        assert_eq!(queue.get_job(id1).unwrap().status, "active");
        assert_eq!(queue.get_job(id2).unwrap().status, "active");
        assert_eq!(queue.get_job(id3).unwrap().status, "queued");

        queue.update(6.0);
        queue.collect_completed();

        assert_eq!(queue.get_job(id3).unwrap().status, "active");
    }
}
