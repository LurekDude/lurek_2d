//! [`Animation`] â€” main controller for sprite animation playback.

use std::collections::HashMap;

use crate::math::Rect;

use super::clip::AnimClip;
use super::event::AnimEvent;
use super::frame::AnimFrame;
use crate::runtime::log_messages::{AN01_ANIM_CTRL_INIT, AN02_CLIP_ADDED, AN03_CLIP_NOT_FOUND};
use crate::log_msg;

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
/// - `frames` â€” `Vec<AnimFrame>`.
/// - `clips` â€” `HashMap<String, AnimClip>`.
/// - `current_clip` â€” `Option<String>`.
/// - `current_frame_pos` â€” `usize`.
/// - `timer` â€” `f32`.
/// - `playing` â€” `bool`.
/// - `speed` â€” `f32`.
/// - `pending_events` â€” `Vec<AnimEvent>`.
#[derive(Clone)]
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
    /// Source quad saved at the start of a crossfade (from-clip frame).
    crossfade_from_quad: Option<Rect>,
    /// Elapsed time since the crossfade started (seconds).
    crossfade_timer: f32,
    /// Total crossfade duration in seconds; 0.0 means no crossfade active.
    crossfade_duration: f32,
}

impl Animation {
    /// Creates a new, empty animation with no frames or clips.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        log_msg!(debug, AN01_ANIM_CTRL_INIT);
        Self {
            frames: Vec::new(),
            clips: HashMap::new(),
            current_clip: None,
            current_frame_pos: 0,
            timer: 0.0,
            playing: false,
            speed: 1.0,
            pending_events: Vec::new(),
            crossfade_from_quad: None,
            crossfade_timer: 0.0,
            crossfade_duration: 0.0,
        }
    }

    // â”€â”€ Frame management â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Adds a single frame and returns its 0-based index.
    ///
    /// # Returns
    /// `usize`.
    ///
    /// # Parameters
    /// - `quad` â€” Source rectangle within the sprite-sheet texture.
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
    /// - `tex_w` â€” Full texture width in pixels.
    /// - `tex_h` â€” Full texture height in pixels.
    /// - `frame_w` â€” Single cell width.
    /// - `frame_h` â€” Single cell height.
    /// - `start` â€” 0-based cell index to begin at.
    /// - `count` â€” Number of cells to extract.
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

    // â”€â”€ Clip management â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Registers a named clip. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `name` â€” Unique clip name.
    /// - `frame_indices` â€” Indices into the animation's frame pool (0-based).
    /// - `fps` â€” Playback speed in frames per second.
    /// - `looping` â€” Whether the clip loops.
    pub fn add_clip(&mut self, name: &str, frame_indices: Vec<usize>, fps: f32, looping: bool) {
        log_msg!(debug, AN02_CLIP_ADDED, "{}", name);
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

    /// Convenience method: adds grid-sliced frames then creates a clip referencing them.
    ///
    /// # Parameters
    /// - `name` â€” Clip name.
    /// - `tex_w` â€” Full texture width.
    /// - `tex_h` â€” Full texture height.
    /// - `frame_w` â€” Single cell width.
    /// - `frame_h` â€” Single cell height.
    /// - `start` â€” 0-based cell index to begin at.
    /// - `count` â€” Number of cells.
    /// - `fps` â€” Playback speed.
    /// - `looping` â€” Whether the clip loops.
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

    // â”€â”€ Playback control â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Starts playing a clip by name.
    ///
    /// # Parameters
    /// - `name` â€” `&str`.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// Resets the frame position to 0 and clears the timer.
    /// Returns `false` if the clip does not exist.
    pub fn play(&mut self, name: &str) -> bool {
        if !self.clips.contains_key(name) {
            log_msg!(warn, AN03_CLIP_NOT_FOUND, "{}", name);
            return false;
        }
        self.current_clip = Some(name.to_string());
        self.current_frame_pos = 0;
        self.timer = 0.0;
        self.playing = true;
        self.pending_events.clear();
        true
    }

    /// Stops playback and resets to frame 0.
    pub fn stop(&mut self) {
        self.playing = false;
        self.current_frame_pos = 0;
        self.timer = 0.0;
    }

    /// Pauses playback at the current frame.
    pub fn pause(&mut self) {
        self.playing = false;
    }

    /// Resumes playback from the current frame.
    pub fn resume(&mut self) {
        self.playing = true;
    }

    // â”€â”€ Update â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Advances the animation by `dt` seconds (scaled by [`speed`](Self::get_speed)).
    ///
    /// # Parameters
    /// - `dt` â€” `f32`.
    ///
    /// Generates [`AnimEvent`] entries retrievable via [`drain_events`](Self::drain_events).
    /// For non-looping clips the animation stops at the last frame and emits
    /// [`AnimEvent::Finished`]. Looping clips wrap around and emit
    /// [`AnimEvent::Looped`].
    pub fn update(&mut self, dt: f32) {
        self.pending_events.clear();

        // Advance crossfade timer â€” clamp at duration so blend weight saturates at 1.0.
        if self.crossfade_duration > 0.0 {
            self.crossfade_timer = (self.crossfade_timer + dt).min(self.crossfade_duration);
        }

        if !self.playing || dt <= 0.0 {
            return;
        }

        // Clone the clip to avoid holding a borrow on `self.clips` while mutating
        // `self.current_frame_pos` and `self.pending_events` below.
        // TODO(perf): refactor to avoid this clone â€” see IDEA.md Â§6.
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

        // Drain accumulated time in a loop: a large dt can skip multiple frames.
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

    // â”€â”€ Queries â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Returns the source rectangle of the current frame, or `None` if no
    /// clip is active or the frame pool is empty.
    ///
    /// # Returns
    /// `Option<Rect>`.
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

    /// Returns the playback speed multiplier.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_speed(&self) -> f32 {
        self.speed
    }

    /// Sets the playback speed multiplier.
    ///
    /// # Parameters
    /// - `speed` â€” `f32`.
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

    /// Returns the number of registered clips.
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
    /// - `index` â€” `usize`.
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

    // â”€â”€ Crossfade â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Starts a crossfade to another clip over the given duration in seconds.
    ///
    /// Saves the current frame's quad as the blend source, then begins playing
    /// the target clip. Returns `false` if the clip does not exist.
    ///
    /// # Parameters
    /// - `clip_name` â€” `&str`. Target clip name.
    /// - `duration` â€” `f32`. Crossfade duration in seconds.
    ///
    /// # Returns
    /// `bool`.
    pub fn crossfade(&mut self, clip_name: &str, duration: f32) -> bool {
        if !self.clips.contains_key(clip_name) {
            return false;
        }
        self.crossfade_from_quad = self.current_quad();
        self.crossfade_timer = 0.0;
        self.crossfade_duration = duration.max(0.0);
        self.play(clip_name)
    }

    /// Returns the current crossfade state as `(from_quad, to_quad, blend_weight)`.
    ///
    /// `blend_weight` increases linearly from `0.0` (start) to `1.0` (end).
    /// Returns `None` when no crossfade is active.
    ///
    /// # Returns
    /// `Option<(Rect, Rect, f32)>`.
    pub fn get_blend_state(&self) -> Option<(Rect, Rect, f32)> {
        if self.crossfade_duration <= 0.0 || self.crossfade_timer >= self.crossfade_duration {
            return None;
        }
        let q1 = self.crossfade_from_quad?;
        let q2 = self.current_quad()?;
        let blend = self.crossfade_timer / self.crossfade_duration;
        Some((q1, q2, blend))
    }

    // â”€â”€ Debug rendering â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Renders the current animation frame as a debug image.
    ///
    /// Background is white. The active frame rectangle is drawn in blue.
    /// Useful for evidence tests where no GPU is available.
    ///
    /// # Parameters
    /// - `width` â€” `u32`. Image width in pixels.
    /// - `height` â€” `u32`. Image height in pixels.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(255, 255, 255, 255);
        if let Some(q) = self.current_quad() {
            // Draw the frame rect in blue
            img.draw_rect(
                q.x as i32,
                q.y as i32,
                q.width as u32,
                q.height as u32,
                80,
                120,
                220,
                200,
            );
            // Draw outline
            img.draw_line(
                q.x as i32,
                q.y as i32,
                (q.x + q.width) as i32,
                q.y as i32,
                40,
                80,
                180,
                255,
            );
            img.draw_line(
                (q.x + q.width) as i32,
                q.y as i32,
                (q.x + q.width) as i32,
                (q.y + q.height) as i32,
                40,
                80,
                180,
                255,
            );
            img.draw_line(
                (q.x + q.width) as i32,
                (q.y + q.height) as i32,
                q.x as i32,
                (q.y + q.height) as i32,
                40,
                80,
                180,
                255,
            );
            img.draw_line(
                q.x as i32,
                (q.y + q.height) as i32,
                q.x as i32,
                q.y as i32,
                40,
                80,
                180,
                255,
            );
        }
        img
    }

    // â”€â”€ Aseprite import â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Creates an [`Animation`] from an [`AsepriteParsed`] result.
    ///
    /// Adds one frame per parsed frame and creates clips from frame tags.
    /// Per-frame duration from the Aseprite export is used when set.
    ///
    /// # Parameters
    /// - `parsed` â€” `&AsepriteParsed`. Parsed Aseprite JSON data.
    ///
    /// # Returns
    /// `Animation`.
    pub fn load_from_aseprite(parsed: &crate::animation::aseprite::AsepriteParsed) -> Animation {
        use crate::animation::aseprite::AsepriteDirection;
        use crate::animation::frame::AnimFrame;

        let mut anim = Animation::new();

        // Add one frame per parsed frame entry.
        for f in &parsed.frames {
            let quad = Rect::new(f.x as f32, f.y as f32, f.w as f32, f.h as f32);
            let duration = f.duration_ms as f32 / 1000.0;
            anim.frames.push(AnimFrame { quad, duration });
        }

        // Create clips from frame tags.
        for tag in &parsed.tags {
            if tag.from > tag.to || tag.to >= anim.frames.len() {
                continue;
            }

            let indices: Vec<usize> = match tag.direction {
                AsepriteDirection::Forward | AsepriteDirection::PingPong => {
                    (tag.from..=tag.to).collect()
                }
                AsepriteDirection::Reverse => (tag.from..=tag.to).rev().collect(),
            };

            // Calculate FPS from the first frame's duration.
            let fps = {
                let dur_ms = parsed.frames[tag.from].duration_ms;
                if dur_ms > 0 { 1000.0 / dur_ms as f32 } else { 10.0 }
            };

            anim.add_clip(&tag.name, indices, fps, true);
        }

        anim
    }
}

impl Default for Animation {
    fn default() -> Self {
        Self::new()
    }
}

// â”€â”€ Unit tests â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
