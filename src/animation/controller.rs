//! Animation playback controller for clip selection, timing, and debug previews.
//! Owns `Animation` only.
//! Does not own asset loading or rendering; it exposes frame/clip state to callers.
//! Depends on `Rect`, `AnimClip`, `AnimEvent`, `AnimFrame`, and log message codes.
use super::clip::{AnimClip, ClipPlaybackMode};
use super::event::AnimEvent;
use super::frame::AnimFrame;
use crate::log_msg;
use crate::math::Rect;
use crate::runtime::log_messages::{AN01_ANIM_CTRL_INIT, AN02_CLIP_ADDED, AN03_CLIP_NOT_FOUND};
use std::collections::HashMap;
/// Runtime animation controller that tracks clips, frames, and playback state.
#[derive(Clone)]
pub struct Animation {
    /// All loaded frames.
    frames: Vec<AnimFrame>,
    /// Named clips mapped to frame indices.
    clips: HashMap<String, AnimClip>,
    /// Current clip name.
    current_clip: Option<String>,
    /// Frame index inside the current clip.
    current_frame_pos: usize,
    /// Accumulated playback timer.
    timer: f32,
    /// Whether playback is active.
    playing: bool,
    /// Playback speed multiplier.
    speed: f32,
    /// Events emitted since the last drain.
    pending_events: Vec<AnimEvent>,
    /// Starting quad for an active crossfade.
    crossfade_from_quad: Option<Rect>,
    /// Crossfade timer.
    crossfade_timer: f32,
    /// Crossfade duration.
    crossfade_duration: f32,
    /// Direction flag for ping-pong clips.
    pingpong_forward: bool,
}
impl Animation {
    /// Create an empty animation controller.
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
    /// Append a frame and return its index.
    pub fn add_frame(&mut self, quad: Rect) -> usize {
        let idx = self.frames.len();
        self.frames.push(AnimFrame::new(quad, 0.0));
        idx
    }
    /// Append frames from a texture grid and return the number added.
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
    /// Append a list of frame rectangles and return the number added.
    pub fn add_frames_from_rects(&mut self, quads: &[Rect]) -> usize {
        for &quad in quads {
            self.frames.push(AnimFrame::new(quad, 0.0));
        }
        quads.len()
    }
    /// Add a forward-playing clip.
    pub fn add_clip(&mut self, name: &str, frame_indices: Vec<usize>, fps: f32, looping: bool) {
        self.add_clip_with_mode(name, frame_indices, fps, looping, ClipPlaybackMode::Forward);
    }
    /// Add a clip with an explicit playback mode.
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
    #[allow(clippy::too_many_arguments)]
    /// Create frames from a grid and register a clip that references them.
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
    /// Start playing a named clip; returns `false` when the clip is missing.
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
    /// Stop playback and reset the frame position.
    pub fn stop(&mut self) {
        self.playing = false;
        self.current_frame_pos = 0;
        self.timer = 0.0;
    }
    /// Pause playback without resetting the frame position.
    pub fn pause(&mut self) {
        self.playing = false;
    }
    /// Resume playback.
    pub fn resume(&mut self) {
        self.playing = true;
    }
    /// Advance playback timers and emit frame events.
    pub fn update(&mut self, dt: f32) {
        self.pending_events.clear();
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
            frame_duration = self.frame_duration_for_name(&clip_name, self.current_frame_pos);
            if frame_duration <= 0.0 {
                return;
            }
        }
    }
    /// Return the length of a named clip.
    fn clip_len(&self, clip_name: &str) -> Option<usize> {
        Some(self.clips.get(clip_name)?.frame_indices.len())
    }
    /// Return whether a named clip loops.
    fn clip_looping(&self, clip_name: &str) -> Option<bool> {
        Some(self.clips.get(clip_name)?.looping)
    }
    /// Return the playback mode of a named clip.
    fn clip_mode(&self, clip_name: &str) -> Option<ClipPlaybackMode> {
        Some(self.clips.get(clip_name)?.mode)
    }
    /// Return the duration for one frame in a clip, falling back to clip FPS.
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
    /// Return the duration for a named clip at position `pos`.
    fn frame_duration_for_name(&self, clip_name: &str, pos: usize) -> f32 {
        match self.clips.get(clip_name) {
            Some(clip) => self.frame_duration_for(clip, pos),
            None => 0.0,
        }
    }
    /// Return the current frame quad, or `None` when playback is unset.
    pub fn current_quad(&self) -> Option<Rect> {
        let clip_name = self.current_clip.as_ref()?;
        let clip = self.clips.get(clip_name)?;
        let &frame_idx = clip.frame_indices.get(self.current_frame_pos)?;
        Some(self.frames.get(frame_idx)?.quad)
    }
    /// Return the current frame index inside the clip.
    pub fn current_frame(&self) -> usize {
        self.current_frame_pos
    }
    /// Return the current clip name.
    pub fn get_current_clip(&self) -> Option<&str> {
        self.current_clip.as_deref()
    }
    /// Return `true` when playback is active.
    pub fn is_playing(&self) -> bool {
        self.playing
    }
    /// Return `true` when the active clip loops.
    pub fn is_looping(&self) -> bool {
        self.current_clip
            .as_ref()
            .and_then(|name| self.clips.get(name))
            .is_some_and(|clip| clip.looping)
    }
    /// Return the playback speed multiplier.
    pub fn get_speed(&self) -> f32 {
        self.speed
    }
    /// Set the playback speed multiplier.
    pub fn set_speed(&mut self, speed: f32) {
        self.speed = speed.max(0.0);
    }
    /// Return the number of loaded frames.
    pub fn get_frame_count(&self) -> usize {
        self.frames.len()
    }
    /// Return the quad for frame `index`.
    pub fn get_frame_quad(&self, index: usize) -> Option<Rect> {
        self.frames.get(index).map(|f| f.quad)
    }
    /// Return the number of registered clips.
    pub fn get_clip_count(&self) -> usize {
        self.clips.len()
    }
    /// Return a clip by name.
    pub fn get_clip(&self, name: &str) -> Option<&AnimClip> {
        self.clips.get(name)
    }
    /// Return a clip by name mutably.
    pub fn get_clip_mut(&mut self, name: &str) -> Option<&mut AnimClip> {
        self.clips.get_mut(name)
    }
    /// Drain and return the pending playback events.
    pub fn drain_events(&mut self) -> Vec<AnimEvent> {
        std::mem::take(&mut self.pending_events)
    }
    /// Force the current clip frame index.
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
    /// Start a crossfade to another clip; returns `false` if the clip is missing.
    pub fn crossfade(&mut self, clip_name: &str, duration: f32) -> bool {
        if !self.clips.contains_key(clip_name) {
            return false;
        }
        self.crossfade_from_quad = self.current_quad();
        self.crossfade_timer = 0.0;
        self.crossfade_duration = duration.max(0.0);
        self.play(clip_name)
    }
    /// Return the active crossfade state as `(from, to, blend)` when a blend is running.
    pub fn get_blend_state(&self) -> Option<(Rect, Rect, f32)> {
        if self.crossfade_duration <= 0.0 || self.crossfade_timer >= self.crossfade_duration {
            return None;
        }
        let q1 = self.crossfade_from_quad?;
        let q2 = self.current_quad()?;
        let blend = self.crossfade_timer / self.crossfade_duration;
        Some((q1, q2, blend))
    }
    /// Draw a simple preview image for the current frame.
    pub fn draw_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(255, 255, 255, 255);
        if let Some(q) = self.current_quad() {
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
    /// Draw a grid preview of all loaded frames.
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
    /// Build an `Animation` from parsed Aseprite metadata.
    pub fn load_from_aseprite(parsed: &crate::animation::aseprite::AsepriteParsed) -> Animation {
        use crate::animation::aseprite::AsepriteDirection;
        let mut anim = Animation::new();
        for f in &parsed.frames {
            let quad = Rect::new(f.x as f32, f.y as f32, f.w as f32, f.h as f32);
            let duration = f.duration_ms as f32 / 1000.0;
            anim.frames.push(AnimFrame::new(quad, duration));
        }
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
/// `Default` delegates to `Animation::new`.
/// `Default` delegates to `Animation::new`.
impl Default for Animation {
    fn default() -> Self {
        Self::new()
    }
}
