//! Sprite animation system: named clips, frame pools, speed control, and frame-level events.
//!
//! This is a Tier 1 engine module. It imports only from `crate::math`.
//!
//! An [`Animation`] stores a pool of [`AnimFrame`] entries (each defining a source
//! rectangle and optional per-frame duration) and any number of named [`AnimClip`]s
//! that reference those frames by index. Call [`Animation::update`] each tick and
//! inspect [`Animation::drain_events`] for playback notifications.

use std::collections::HashMap;

use crate::math::Rect;

// ── Backward-compatibility alias ────────────────────────────────────────

/// Backward-compatible alias for [`AnimFrame`].
///
/// Existing code that imports `AnimationFrame` from `crate::graphics` will
/// continue to compile after the Phase 24 rewrite.
pub type AnimationFrame = AnimFrame;

// ── Types ───────────────────────────────────────────────────────────────

/// A single animation frame with a source rectangle and optional duration.
///
/// # Fields
/// - `quad` — `Rect`.
/// - `duration` — `f32`.
///
/// If `duration` is `0.0`, the owning clip's FPS controls timing instead.
#[derive(Debug, Clone)]
pub struct AnimFrame {
    /// Source rectangle (quad) within the sprite-sheet texture.
    pub quad: Rect,
    /// Per-frame duration override in seconds. When `> 0.0` this value
    /// takes priority over the clip's FPS.
    pub duration: f32,
}

/// A named animation clip that references frames by index into the parent
///
/// # Fields
/// - `name` — `String`.
/// - `frame_indices` — `Vec<usize>`.
/// - `fps` — `f32`.
/// - `looping` — `bool`.
/// [`Animation`]'s frame pool.
#[derive(Debug, Clone)]
pub struct AnimClip {
    /// Human-readable clip name.
    pub name: String,
    /// Indices into [`Animation::frames`] (0-based).
    pub frame_indices: Vec<usize>,
    /// Playback speed in frames per second.
    pub fps: f32,
    /// Whether the clip wraps around after the last frame.
    pub looping: bool,
}

/// Events emitted by [`Animation::update`].
///
/// # Variants
/// - `Finished` — Finished variant.
/// - `FrameChanged` — FrameChanged variant.
/// - `Looped` — Looped variant.
///
/// Retrieve pending events with [`Animation::drain_events`].
#[derive(Debug, Clone, PartialEq)]
pub enum AnimEvent {
    /// A non-looping clip reached its final frame and stopped.
    Finished,
    /// The active frame changed to `frame_index` (position within the clip's
    /// `frame_indices` list).
    FrameChanged {
        /// 0-based index within the clip's frame list.
        frame_index: usize,
    },
    /// A looping clip wrapped back to its first frame.
    Looped,
}

/// Sprite animation with named clips, speed control, and playback events.
///
/// # Usage
///
/// 1. Add frames with [`add_frame`](Self::add_frame) or
///    [`add_frames_from_grid`](Self::add_frames_from_grid).
/// 2. Register one or more clips with [`add_clip`](Self::add_clip).
/// 3. Call [`play`](Self::play) to start a clip, then
///    [`update`](Self::update) each tick.
/// 4. Read the current source quad via [`current_quad`](Self::current_quad).
///
/// # Fields
/// - `frames` — `Vec<AnimFrame>`.
/// - `clips` — `HashMap<String`.
/// - `current_clip` — `Option<String>`.
/// - `current_frame_pos` — `usize`.
/// - `timer` — `f32`.
/// - `playing` — `bool`.
/// - `speed` — `f32`.
/// - `f` — `:update) call.`.
/// - `pending_events` — `Vec<AnimEvent>`.
pub struct Animation {
    /// All frames available to this animation.
    frames: Vec<AnimFrame>,
    /// Named clips mapping name to clip data.
    clips: HashMap<String, AnimClip>,
    /// Currently active clip name.
    current_clip: Option<String>,
    /// Current position within the active clip's `frame_indices` (0-based).
    current_frame_pos: usize,
    /// Time accumulator for frame advancement.
    timer: f32,
    /// Whether the animation is currently playing.
    playing: bool,
    /// Playback speed multiplier (default `1.0`).
    speed: f32,
    /// Events generated during the last [`update`](Self::update) call.
    pending_events: Vec<AnimEvent>,
}

impl Animation {
    /// Creates a new, empty animation with no frames or clips.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            frames: Vec::new(),
            clips: HashMap::new(),
            current_clip: None,
            current_frame_pos: 0,
            timer: 0.0,
            playing: false,
            speed: 1.0,
            pending_events: Vec::new(),
        }
    }

    // ── Frame management ────────────────────────────────────────────────

    /// Adds a single frame and returns its 0-based index.
    ///
    /// # Returns
    /// `usize`.
    ///
    /// # Parameters
    /// - `quad` — Source rectangle within the sprite-sheet texture.
    pub fn add_frame(&mut self, quad: Rect) -> usize {
        let idx = self.frames.len();
        self.frames.push(AnimFrame {
            quad,
            duration: 0.0,
        });
        idx
    }

    /// Slices a sprite-sheet grid into frames and appends them.
    ///
    /// # Returns
    /// `usize`.
    ///
    /// Frames are extracted left-to-right, top-to-bottom starting at index
    /// `start` (0-based cell index within the grid). Returns the number of
    /// frames actually added.
    ///
    /// # Parameters
    /// - `tex_w`, `tex_h` — Full texture dimensions in pixels.
    /// - `frame_w`, `frame_h` — Dimensions of a single cell.
    /// - `start` — 0-based cell index to begin at.
    /// - `count` — Number of cells to extract.
    pub fn add_frames_from_grid(
        &mut self,
        tex_w: u32,
        tex_h: u32,
        frame_w: u32,
        frame_h: u32,
        start: usize,
        count: usize,
    ) -> usize {
        if frame_w == 0 || frame_h == 0 {
            return 0;
        }
        let cols = (tex_w / frame_w) as usize;
        let rows = (tex_h / frame_h) as usize;
        let total_cells = cols * rows;
        let mut added = 0;
        for i in start..start + count {
            if i >= total_cells {
                break;
            }
            let col = i % cols;
            let row = i / cols;
            self.frames.push(AnimFrame {
                quad: Rect::new(
                    (col as u32 * frame_w) as f32,
                    (row as u32 * frame_h) as f32,
                    frame_w as f32,
                    frame_h as f32,
                ),
                duration: 0.0,
            });
            added += 1;
        }
        added
    }

    // ── Clip management ─────────────────────────────────────────────────

    /// Registers a named clip. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `name` — Unique clip name.
    /// - `frame_indices` — Indices into the animation's frame pool (0-based).
    /// - `fps` — Playback speed in frames per second.
    /// - `looping` — Whether the clip loops.
    pub fn add_clip(&mut self, name: &str, frame_indices: Vec<usize>, fps: f32, looping: bool) {
        self.clips.insert(
            name.to_string(),
            AnimClip {
                name: name.to_string(),
                frame_indices,
                fps: if fps > 0.0 { fps } else { 1.0 },
                looping,
            },
        );
    }

    /// Convenience method: adds grid-sliced frames then creates a clip
    /// referencing them.
    ///
    /// # Parameters
    /// - `name` — Clip name.
    /// - `tex_w`, `tex_h` — Full texture dimensions.
    /// - `frame_w`, `frame_h` — Single cell dimensions.
    /// - `start` — 0-based cell index to begin at.
    /// - `count` — Number of cells.
    /// - `fps` — Playback speed.
    /// - `looping` — Whether the clip loops.
    #[allow(clippy::too_many_arguments)]
    pub fn add_clip_from_grid(
        &mut self,
        name: &str,
        tex_w: u32,
        tex_h: u32,
        frame_w: u32,
        frame_h: u32,
        start: usize,
        count: usize,
        fps: f32,
        looping: bool,
    ) {
        let base = self.frames.len();
        let added = self.add_frames_from_grid(tex_w, tex_h, frame_w, frame_h, start, count);
        let indices: Vec<usize> = (base..base + added).collect();
        self.add_clip(name, indices, fps, looping);
    }

    // ── Playback control ────────────────────────────────────────────────

    /// Starts playing a clip by name. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// Resets the frame position to 0 and clears the timer.
    /// Returns `false` if the clip does not exist.
    pub fn play(&mut self, name: &str) -> bool {
        if !self.clips.contains_key(name) {
            return false;
        }
        self.current_clip = Some(name.to_string());
        self.current_frame_pos = 0;
        self.timer = 0.0;
        self.playing = true;
        self.pending_events.clear();
        true
    }

    /// Stops playback and resets to frame 0. Consult the module-level documentation for the broader usage context and preconditions.
    pub fn stop(&mut self) {
        self.playing = false;
        self.current_frame_pos = 0;
        self.timer = 0.0;
    }

    /// Pauses playback at the current frame. Consult the module-level documentation for the broader usage context and preconditions.
    pub fn pause(&mut self) {
        self.playing = false;
    }

    /// Resumes playback from the current frame.
    pub fn resume(&mut self) {
        self.playing = true;
    }

    // ── Update ──────────────────────────────────────────────────────────

    /// Advances the animation by `dt` seconds (scaled by [`speed`](Self::get_speed)).
    ///
    /// # Parameters
    /// - `dt` — `f32`.
    ///
    /// Generates [`AnimEvent`] entries retrievable via [`drain_events`](Self::drain_events).
    /// For non-looping clips the animation stops at the last frame and emits
    /// [`AnimEvent::Finished`]. Looping clips wrap around and emit
    /// [`AnimEvent::Looped`].
    pub fn update(&mut self, dt: f32) {
        self.pending_events.clear();

        if !self.playing || dt <= 0.0 {
            return;
        }

        let clip = match &self.current_clip {
            Some(name) => match self.clips.get(name) {
                Some(c) => c.clone(),
                None => return,
            },
            None => return,
        };

        if clip.frame_indices.is_empty() {
            return;
        }

        let mut frame_duration = self.frame_duration_for(&clip, self.current_frame_pos);
        if frame_duration <= 0.0 {
            return;
        }

        self.timer += dt * self.speed;

        while self.timer >= frame_duration {
            self.timer -= frame_duration;
            let next = self.current_frame_pos + 1;
            if next < clip.frame_indices.len() {
                self.current_frame_pos = next;
                self.pending_events.push(AnimEvent::FrameChanged {
                    frame_index: self.current_frame_pos,
                });
            } else if clip.looping {
                self.current_frame_pos = 0;
                self.pending_events.push(AnimEvent::Looped);
                self.pending_events
                    .push(AnimEvent::FrameChanged { frame_index: 0 });
            } else {
                self.current_frame_pos = clip.frame_indices.len() - 1;
                self.playing = false;
                self.timer = 0.0;
                self.pending_events.push(AnimEvent::Finished);
                return;
            }

            // Recompute duration for the new frame (it may differ).
            frame_duration = self.frame_duration_for(&clip, self.current_frame_pos);
            if frame_duration <= 0.0 {
                return;
            }
        }
    }

    /// Returns the effective duration for the frame at `pos` within `clip`.
    fn frame_duration_for(&self, clip: &AnimClip, pos: usize) -> f32 {
        if let Some(&idx) = clip.frame_indices.get(pos) {
            if let Some(frame) = self.frames.get(idx) {
                if frame.duration > 0.0 {
                    return frame.duration;
                }
            }
        }
        1.0 / clip.fps
    }

    // ── Queries ─────────────────────────────────────────────────────────

    /// Returns the source rectangle of the current frame, or `None` if no
    ///
    /// # Returns
    /// `Option<Rect>`.
    /// clip is active or the frame pool is empty.
    pub fn current_quad(&self) -> Option<Rect> {
        let clip_name = self.current_clip.as_ref()?;
        let clip = self.clips.get(clip_name)?;
        let &frame_idx = clip.frame_indices.get(self.current_frame_pos)?;
        Some(self.frames.get(frame_idx)?.quad)
    }

    /// Returns the current position within the active clip's frame list (0-based).
    ///
    /// # Returns
    /// `usize`.
    pub fn current_frame(&self) -> usize {
        self.current_frame_pos
    }

    /// Returns the name of the currently active clip, if any.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn get_current_clip(&self) -> Option<&str> {
        self.current_clip.as_deref()
    }

    /// Returns `true` if the animation is currently playing.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_playing(&self) -> bool {
        self.playing
    }

    /// Returns `true` if the current clip is set to loop.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_looping(&self) -> bool {
        self.current_clip
            .as_ref()
            .and_then(|name| self.clips.get(name))
            .is_some_and(|clip| clip.looping)
    }

    /// Returns the playback speed multiplier. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_speed(&self) -> f32 {
        self.speed
    }

    /// Sets the playback speed multiplier. Replaces the current speed value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `speed` — `f32`.
    ///
    /// A value of `1.0` is normal speed. Values below `0.0` are clamped to `0.0`.
    pub fn set_speed(&mut self, speed: f32) {
        self.speed = speed.max(0.0);
    }

    /// Returns the total number of frames in the animation's frame pool.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_frame_count(&self) -> usize {
        self.frames.len()
    }

    /// Returns the number of registered clips. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_clip_count(&self) -> usize {
        self.clips.len()
    }

    /// Returns and clears all pending animation events.
    ///
    /// # Returns
    /// `Vec<AnimEvent>`.
    pub fn drain_events(&mut self) -> Vec<AnimEvent> {
        std::mem::take(&mut self.pending_events)
    }

    /// Sets the playback position within the current clip.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// The index is clamped to the valid range for the active clip.
    /// Has no effect if no clip is active.
    pub fn set_frame(&mut self, index: usize) {
        if let Some(clip_name) = &self.current_clip {
            if let Some(clip) = self.clips.get(clip_name) {
                if !clip.frame_indices.is_empty() {
                    self.current_frame_pos = index.min(clip.frame_indices.len() - 1);
                    self.timer = 0.0;
                }
            }
        }
    }
}

impl Default for Animation {
    fn default() -> Self {
        Self::new()
    }
}

// ── Unit tests ──────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    /// Helper: create an animation with a single clip from a grid.
    fn make_clip_anim(count: usize, fps: f32, looping: bool) -> Animation {
        let mut anim = Animation::new();
        anim.add_clip_from_grid("walk", 128, 32, 32, 32, 0, count, fps, looping);
        anim.play("walk");
        anim
    }

    #[test]
    fn new_animation_is_empty() {
        let anim = Animation::new();
        assert_eq!(anim.get_frame_count(), 0);
        assert_eq!(anim.get_clip_count(), 0);
        assert!(!anim.is_playing());
        assert!(anim.current_quad().is_none());
    }

    #[test]
    fn add_frame_returns_sequential_indices() {
        let mut anim = Animation::new();
        let a = anim.add_frame(Rect::new(0.0, 0.0, 32.0, 32.0));
        let b = anim.add_frame(Rect::new(32.0, 0.0, 32.0, 32.0));
        assert_eq!(a, 0);
        assert_eq!(b, 1);
        assert_eq!(anim.get_frame_count(), 2);
    }

    #[test]
    fn add_frames_from_grid_slices_correctly() {
        let mut anim = Animation::new();
        let added = anim.add_frames_from_grid(128, 64, 32, 32, 0, 8);
        assert_eq!(added, 8);
        assert_eq!(anim.get_frame_count(), 8);
    }

    #[test]
    fn add_frames_from_grid_clamps_to_total_cells() {
        let mut anim = Animation::new();
        let added = anim.add_frames_from_grid(64, 64, 32, 32, 0, 100);
        assert_eq!(added, 4); // 2x2 grid = 4 cells max
    }

    #[test]
    fn play_nonexistent_clip_returns_false() {
        let mut anim = Animation::new();
        assert!(!anim.play("missing"));
        assert!(!anim.is_playing());
    }

    #[test]
    fn play_starts_at_frame_zero() {
        let anim = make_clip_anim(4, 10.0, true);
        assert_eq!(anim.current_frame(), 0);
        assert!(anim.is_playing());
    }

    #[test]
    fn update_advances_frames() {
        let mut anim = make_clip_anim(4, 10.0, true);
        anim.update(0.15); // 1.5 frames at 10fps -> frame 1
        assert_eq!(anim.current_frame(), 1);
    }

    #[test]
    fn looping_clip_wraps_and_emits_event() {
        let mut anim = make_clip_anim(2, 10.0, true);
        anim.update(0.25); // 2.5 frames -> wrap
        let events = anim.drain_events();
        assert!(events.contains(&AnimEvent::Looped));
        assert!(anim.is_playing());
    }

    #[test]
    fn non_looping_clip_stops_and_emits_finished() {
        let mut anim = make_clip_anim(2, 10.0, false);
        anim.update(0.5); // well past both frames
        let events = anim.drain_events();
        assert!(events.contains(&AnimEvent::Finished));
        assert!(!anim.is_playing());
    }

    #[test]
    fn pause_resume_works() {
        let mut anim = make_clip_anim(4, 10.0, true);
        anim.pause();
        anim.update(0.5);
        assert_eq!(anim.current_frame(), 0);
        anim.resume();
        anim.update(0.15);
        assert_eq!(anim.current_frame(), 1);
    }

    #[test]
    fn stop_resets_to_zero() {
        let mut anim = make_clip_anim(4, 10.0, true);
        anim.update(0.25);
        assert!(anim.current_frame() > 0);
        anim.stop();
        assert_eq!(anim.current_frame(), 0);
        assert!(!anim.is_playing());
    }

    #[test]
    fn speed_multiplier_affects_playback() {
        let mut anim = make_clip_anim(4, 10.0, true);
        anim.set_speed(2.0);
        assert!((anim.get_speed() - 2.0).abs() < f32::EPSILON);
        anim.update(0.1); // 0.1 * 2.0 = 0.2s = 2 frames at 10fps
        assert_eq!(anim.current_frame(), 2);
    }

    #[test]
    fn set_frame_clamps_to_clip_range() {
        let mut anim = make_clip_anim(4, 10.0, true);
        anim.set_frame(100);
        assert_eq!(anim.current_frame(), 3);
    }

    #[test]
    fn current_quad_returns_correct_rect() {
        let mut anim = Animation::new();
        anim.add_frames_from_grid(128, 32, 32, 32, 0, 4);
        anim.add_clip("run", vec![0, 1, 2, 3], 10.0, true);
        anim.play("run");
        let q = anim.current_quad().expect("should have a quad");
        assert!((q.x).abs() < f32::EPSILON);
        assert!((q.y).abs() < f32::EPSILON);
        assert!((q.width - 32.0).abs() < f32::EPSILON);
        assert!((q.height - 32.0).abs() < f32::EPSILON);
    }

    #[test]
    fn multiple_clips_can_switch() {
        let mut anim = Animation::new();
        anim.add_frames_from_grid(128, 64, 32, 32, 0, 8);
        anim.add_clip("walk", vec![0, 1, 2, 3], 10.0, true);
        anim.add_clip("run", vec![4, 5, 6, 7], 10.0, true);
        assert_eq!(anim.get_clip_count(), 2);

        anim.play("walk");
        assert_eq!(anim.get_current_clip(), Some("walk"));
        anim.update(0.15);
        assert_eq!(anim.current_frame(), 1);

        anim.play("run");
        assert_eq!(anim.get_current_clip(), Some("run"));
        assert_eq!(anim.current_frame(), 0);
    }

    #[test]
    fn zero_frame_grid_produces_nothing() {
        let mut anim = Animation::new();
        let added = anim.add_frames_from_grid(128, 32, 0, 0, 0, 4);
        assert_eq!(added, 0);
    }
}
