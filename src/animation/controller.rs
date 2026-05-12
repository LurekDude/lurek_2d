//! [`Animation`] â€” main controller for sprite animation playback.

use std::collections::HashMap;

use crate::math::Rect;

use super::clip::{AnimClip, ClipPlaybackMode};
use super::event::AnimEvent;
use super::frame::AnimFrame;
use crate::log_msg;
use crate::runtime::log_messages::{AN01_ANIM_CTRL_INIT, AN02_CLIP_ADDED, AN03_CLIP_NOT_FOUND};

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
    /// Direction flag used by ping-pong clips (`true` => forward, `false` => backward).
    pingpong_forward: bool,
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
            pingpong_forward: true,
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
        self.frames.push(AnimFrame::new(quad, 0.0));
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
            self.frames.push(AnimFrame::new(
                Rect::new(
                    (col as u32 * frame_w) as f32,
                    (row as u32 * frame_h) as f32,
                    frame_w as f32,
                    frame_h as f32,
                ),
                0.0,
            ));
            added += 1;
        }
        added
    }

    // add_frames_from_rects ---------------------------------------------------

    /// Adds frames from a pre-sliced list of source rectangles.
    ///
    /// This is the canonical deduplication point for callers that already
    /// hold a quad list from an external source such as `SpriteSheet::get_frame`
    /// results or a TexturePacker atlas region list.  Because `animation` is a
    /// Tier 1 module that must not import `sprite`, consumers pass the quads
    /// in; the animation layer never recomputes the grid itself.
    ///
    /// # Parameters
    /// - `quads` - Slice of source rectangles in pixel space.
    ///
    /// # Returns
    /// `usize` - number of frames added.
    pub fn add_frames_from_rects(&mut self, quads: &[Rect]) -> usize {
        for &quad in quads {
            self.frames.push(AnimFrame::new(quad, 0.0));
        }
        quads.len()
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
        self.add_clip_with_mode(name, frame_indices, fps, looping, ClipPlaybackMode::Forward);
    }

    /// Registers a named clip with an explicit playback mode.
    pub fn add_clip_with_mode(
        &mut self,
        name: &str,
        frame_indices: Vec<usize>,
        fps: f32,
        looping: bool,
        mode: ClipPlaybackMode,
    ) {
        log_msg!(debug, AN02_CLIP_ADDED, "{}", name);
        self.clips.insert(
            name.to_string(),
            AnimClip {
                name: name.to_string(),
                frame_indices,
                fps: if fps > 0.0 { fps } else { 1.0 },
                looping,
                mode,
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
        self.pingpong_forward = true;
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

        let clip_name = match self.current_clip.clone() {
            Some(name) => name,
            None => return,
        };

        let clip_len = match self.clip_len(&clip_name) {
            Some(len) => len,
            None => return,
        };
        if clip_len == 0 {
            return;
        }

        let mut frame_duration = self.frame_duration_for_name(&clip_name, self.current_frame_pos);
        if frame_duration <= 0.0 {
            return;
        }

        self.timer += dt * self.speed;

        // Drain accumulated time in a loop: a large dt can skip multiple frames.
        while self.timer >= frame_duration {
            self.timer -= frame_duration;
            let clip_mode = self
                .clip_mode(&clip_name)
                .unwrap_or(ClipPlaybackMode::Forward);
            let clip_looping = self.clip_looping(&clip_name).unwrap_or(false);

            let advanced = match clip_mode {
                ClipPlaybackMode::Forward => {
                    let next = self.current_frame_pos + 1;
                    if next < clip_len {
                        self.current_frame_pos = next;
                        true
                    } else if clip_looping {
                        self.current_frame_pos = 0;
                        self.pending_events.push(AnimEvent::Looped);
                        true
                    } else {
                        self.current_frame_pos = clip_len - 1;
                        false
                    }
                }
                ClipPlaybackMode::Reverse => {
                    if self.current_frame_pos > 0 {
                        self.current_frame_pos -= 1;
                        true
                    } else if clip_looping {
                        self.current_frame_pos = clip_len - 1;
                        self.pending_events.push(AnimEvent::Looped);
                        true
                    } else {
                        self.current_frame_pos = 0;
                        false
                    }
                }
                ClipPlaybackMode::PingPong => {
                    if clip_len <= 1 {
                        clip_looping
                    } else if self.pingpong_forward {
                        let next = self.current_frame_pos + 1;
                        if next < clip_len {
                            self.current_frame_pos = next;
                            true
                        } else {
                            self.pingpong_forward = false;
                            if clip_looping {
                                self.pending_events.push(AnimEvent::Looped);
                            }
                            if clip_len > 1 {
                                self.current_frame_pos = clip_len - 2;
                            }
                            clip_looping || self.current_frame_pos > 0
                        }
                    } else if self.current_frame_pos > 0 {
                        self.current_frame_pos -= 1;
                        true
                    } else {
                        if clip_looping {
                            self.pingpong_forward = true;
                            self.pending_events.push(AnimEvent::Looped);
                            if clip_len > 1 {
                                self.current_frame_pos = 1;
                            }
                            true
                        } else {
                            self.current_frame_pos = 0;
                            false
                        }
                    }
                }
            };

            if advanced {
                self.pending_events.push(AnimEvent::FrameChanged {
                    frame_index: self.current_frame_pos,
                });
            } else {
                self.playing = false;
                self.timer = 0.0;
                self.pending_events.push(AnimEvent::Finished);
                return;
            }

            // Recompute duration for the new frame (it may differ).
            frame_duration = self.frame_duration_for_name(&clip_name, self.current_frame_pos);
            if frame_duration <= 0.0 {
                return;
            }
        }
    }

    fn clip_len(&self, clip_name: &str) -> Option<usize> {
        Some(self.clips.get(clip_name)?.frame_indices.len())
    }

    fn clip_looping(&self, clip_name: &str) -> Option<bool> {
        Some(self.clips.get(clip_name)?.looping)
    }

    fn clip_mode(&self, clip_name: &str) -> Option<ClipPlaybackMode> {
        Some(self.clips.get(clip_name)?.mode)
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

    fn frame_duration_for_name(&self, clip_name: &str, pos: usize) -> f32 {
        match self.clips.get(clip_name) {
            Some(clip) => self.frame_duration_for(clip, pos),
            None => 0.0,
        }
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

    /// Returns the source quad for a frame by pool index, or `None` if out of range.
    ///
    /// # Parameters
    /// - `index` — 0-based frame pool index.
    ///
    /// # Returns
    /// `Option<Rect>`.
    pub fn get_frame_quad(&self, index: usize) -> Option<Rect> {
        self.frames.get(index).map(|f| f.quad)
    }

    /// Returns the number of registered clips.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_clip_count(&self) -> usize {
        self.clips.len()
    }

    /// Returns an immutable reference to a clip by name.
    pub fn get_clip(&self, name: &str) -> Option<&AnimClip> {
        self.clips.get(name)
    }

    /// Returns a mutable reference to a clip by name.
    pub fn get_clip_mut(&mut self, name: &str) -> Option<&mut AnimClip> {
        self.clips.get_mut(name)
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

    /// Renders all frame quads into a debug preview grid.
    ///
    /// This is useful for quick visual inspection of imported Aseprite clips.
    pub fn draw_preview_grid(&self, columns: u32, cell_size: u32) -> crate::image::ImageData {
        let columns = columns.max(1);
        let cell_size = cell_size.max(4);
        let count = self.frames.len() as u32;
        let rows = if count == 0 {
            1
        } else {
            count.div_ceil(columns)
        };

        let width = columns * cell_size;
        let height = rows * cell_size;
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(24, 28, 36, 255);

        for (idx, frame) in self.frames.iter().enumerate() {
            let idx = idx as u32;
            let col = idx % columns;
            let row = idx / columns;
            let x = (col * cell_size) as i32;
            let y = (row * cell_size) as i32;

            let inset = 2i32;
            let inner_w = cell_size.saturating_sub((inset * 2) as u32);
            let inner_h = cell_size.saturating_sub((inset * 2) as u32);
            let alpha = ((frame.quad.width + frame.quad.height) as u32 % 120 + 90) as u8;
            img.draw_rect(x + inset, y + inset, inner_w, inner_h, 70, 130, 220, alpha);
            img.draw_rect(x, y, cell_size, 1, 110, 120, 140, 255);
            img.draw_rect(
                x,
                y + cell_size as i32 - 1,
                cell_size,
                1,
                110,
                120,
                140,
                255,
            );
            img.draw_rect(x, y, 1, cell_size, 110, 120, 140, 255);
            img.draw_rect(
                x + cell_size as i32 - 1,
                y,
                1,
                cell_size,
                110,
                120,
                140,
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

        let mut anim = Animation::new();

        // Add one frame per parsed frame entry.
        for f in &parsed.frames {
            let quad = Rect::new(f.x as f32, f.y as f32, f.w as f32, f.h as f32);
            let duration = f.duration_ms as f32 / 1000.0;
            anim.frames.push(AnimFrame::new(quad, duration));
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

            let mode = match tag.direction {
                AsepriteDirection::Forward => ClipPlaybackMode::Forward,
                AsepriteDirection::Reverse => ClipPlaybackMode::Reverse,
                AsepriteDirection::PingPong => ClipPlaybackMode::PingPong,
            };

            // Calculate FPS from the first frame's duration.
            let fps = {
                let dur_ms = parsed.frames[tag.from].duration_ms;
                if dur_ms > 0 {
                    1000.0 / dur_ms as f32
                } else {
                    10.0
                }
            };

            anim.add_clip_with_mode(&tag.name, indices, fps, true, mode);
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
