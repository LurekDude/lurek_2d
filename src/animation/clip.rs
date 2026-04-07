//! [`AnimClip`] — a named animation clip referencing frames by index.

/// A named animation clip that references frames by index into the parent
///
/// # Fields
/// - `name` — `String`.
/// - `frame_indices` — `Vec<usize>`.
/// - `fps` — `f32`.
/// - `looping` — `bool`.
///
/// [`Animation`](crate::animation::Animation)'s frame pool.
#[derive(Debug, Clone)]
pub struct AnimClip {
    /// Human-readable clip name.
    pub name: String,
    /// Indices into [`Animation::frames`](crate::animation::Animation) (0-based).
    pub frame_indices: Vec<usize>,
    /// Playback speed in frames per second.
    pub fps: f32,
    /// Whether the clip wraps around after the last frame.
    pub looping: bool,
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── Construction ──────────────────────────────────────────────────────────

    #[test]
    fn clip_fields_store_correctly() {
        let clip = AnimClip {
            name: "run".to_string(),
            frame_indices: vec![0, 1, 2, 3],
            fps: 12.0,
            looping: true,
        };
        assert_eq!(clip.name, "run");
        assert_eq!(clip.frame_indices.len(), 4);
        assert!((clip.fps - 12.0).abs() < 1e-5);
        assert!(clip.looping);
    }

    #[test]
    fn clip_non_looping_stores_false() {
        let clip = AnimClip {
            name: "death".to_string(),
            frame_indices: vec![5, 6, 7],
            fps: 8.0,
            looping: false,
        };
        assert!(!clip.looping);
        assert_eq!(clip.frame_indices, [5, 6, 7]);
    }

    #[test]
    fn clip_empty_frame_indices() {
        let clip = AnimClip {
            name: "idle".to_string(),
            frame_indices: vec![],
            fps: 1.0,
            looping: true,
        };
        assert!(clip.frame_indices.is_empty());
    }
}
