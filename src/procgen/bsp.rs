//! Binary Space Partitioning dungeon generator.
//!
//! Recursively splits a rectangle into leaves, places a room in each leaf,
//! then connects sibling rooms with a corridor.

use crate::procgen::lcg::Lcg;

/// A room placed within the dungeon.
///
/// # Fields
/// - `x` — `u32`.
/// - `y` — `u32`.
/// - `w` — `u32`.
/// - `h` — `u32`.
#[derive(Debug, Clone)]
pub struct BspRoom {
    /// Left edge (column).
    pub x: u32,
    /// Top edge (row).
    pub y: u32,
    /// Width in cells.
    pub w: u32,
    /// Height in cells.
    pub h: u32,
}

/// A generated BSP dungeon.
///
/// # Fields
/// - `rooms` — `Vec<BspRoom>`.
/// - `corridors` — `Vec<(u32, u32, u32, u32)>`.
#[derive(Debug, Clone)]
pub struct BspDungeon {
    /// All rooms placed in leaf nodes.
    pub rooms: Vec<BspRoom>,
    /// Corridors connecting pairs of rooms: `(x1, y1, x2, y2)`.
    pub corridors: Vec<(u32, u32, u32, u32)>,
}

/// Stamp template that can be projected onto BSP rooms.
#[derive(Debug, Clone)]
pub struct BspPrefabStamp {
    /// Prefab identifier.
    pub name: String,
    /// Prefab width in cells.
    pub width: u32,
    /// Prefab height in cells.
    pub height: u32,
}

/// Placement metadata for a BSP prefab projection.
#[derive(Debug, Clone)]
pub struct PlacedBspPrefab {
    /// Prefab identifier.
    pub name: String,
    /// Placement origin X in dungeon space.
    pub x: u32,
    /// Placement origin Y in dungeon space.
    pub y: u32,
    /// Placement width.
    pub width: u32,
    /// Placement height.
    pub height: u32,
}

/// Options controlling BSP dungeon generation.
///
/// # Fields
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `min_size` — `u32`.
/// - `max_depth` — `u32`.
/// - `seed` — `u64`.
/// - `padding` — `u32`.
#[derive(Debug, Clone)]
pub struct BspOpts {
    /// Total dungeon width in cells.
    pub width: u32,
    /// Total dungeon height in cells.
    pub height: u32,
    /// Minimum room dimension in any axis.
    pub min_size: u32,
    /// Maximum recursion depth.
    pub max_depth: u32,
    /// Random seed.
    pub seed: u64,
    /// Padding between room edge and partition edge.
    pub padding: u32,
}

impl Default for BspOpts {
    fn default() -> Self {
        Self {
            width: 64,
            height: 64,
            min_size: 6,
            max_depth: 4,
            seed: 42,
            padding: 1,
        }
    }
}

/// Generate a BSP dungeon from the given options.
///
/// # Parameters
/// - `opts` — `&BspOpts`.
///
/// # Returns
/// `BspDungeon`.
pub fn bsp_dungeon(opts: &BspOpts) -> BspDungeon {
    let mut rng = Lcg::new(opts.seed);
    let mut rooms = Vec::new();
    let mut corridors = Vec::new();

    let root = Partition {
        x: 0,
        y: 0,
        w: opts.width,
        h: opts.height,
    };
    split(
        root,
        opts.max_depth,
        opts.min_size,
        opts,
        &mut rng,
        &mut rooms,
        &mut corridors,
    );

    BspDungeon { rooms, corridors }
}

/// Generates a BSP dungeon and returns prefab placements centered in rooms.
///
/// This function produces placement metadata only; callers decide how to stamp
/// into concrete tile grids.
pub fn bsp_dungeon_with_prefabs(
    opts: &BspOpts,
    prefabs: &[BspPrefabStamp],
) -> (BspDungeon, Vec<PlacedBspPrefab>) {
    let dungeon = bsp_dungeon(opts);
    let mut placements = Vec::new();
    if prefabs.is_empty() {
        return (dungeon, placements);
    }

    for (i, room) in dungeon.rooms.iter().enumerate() {
        let prefab = &prefabs[i % prefabs.len()];
        if prefab.width == 0 || prefab.height == 0 {
            continue;
        }
        if prefab.width > room.w || prefab.height > room.h {
            continue;
        }
        let x = room.x + (room.w - prefab.width) / 2;
        let y = room.y + (room.h - prefab.height) / 2;
        placements.push(PlacedBspPrefab {
            name: prefab.name.clone(),
            x,
            y,
            width: prefab.width,
            height: prefab.height,
        });
    }

    (dungeon, placements)
}

#[derive(Clone)]
struct Partition {
    x: u32,
    y: u32,
    w: u32,
    h: u32,
}

impl Partition {
    fn center(&self) -> (u32, u32) {
        (self.x + self.w / 2, self.y + self.h / 2)
    }
}

fn split(
    part: Partition,
    depth: u32,
    min_size: u32,
    opts: &BspOpts,
    rng: &mut Lcg,
    rooms: &mut Vec<BspRoom>,
    corridors: &mut Vec<(u32, u32, u32, u32)>,
) -> Partition {
    let can_split_h = part.w >= min_size * 2 + 2;
    let can_split_v = part.h >= min_size * 2 + 2;

    if depth == 0 || (!can_split_h && !can_split_v) {
        // Leaf: place a room
        let pad = opts.padding;
        let max_rw = part.w.saturating_sub(pad * 2).max(min_size);
        let max_rh = part.h.saturating_sub(pad * 2).max(min_size);
        let rw = min_size
            .max((rng.next() as u32) % (max_rw - min_size + 1).max(1) + min_size)
            .min(max_rw);
        let rh = min_size
            .max((rng.next() as u32) % (max_rh - min_size + 1).max(1) + min_size)
            .min(max_rh);
        let rx =
            part.x + pad + (rng.next() as u32) % (part.w.saturating_sub(rw + pad * 2) + 1).max(1);
        let ry =
            part.y + pad + (rng.next() as u32) % (part.h.saturating_sub(rh + pad * 2) + 1).max(1);
        rooms.push(BspRoom {
            x: rx.min(part.x + part.w.saturating_sub(rw)),
            y: ry.min(part.y + part.h.saturating_sub(rh)),
            w: rw,
            h: rh,
        });
        return part;
    }

    // Choose split direction
    let split_horizontal = if can_split_h && can_split_v {
        rng.next().is_multiple_of(2)
    } else {
        can_split_h
    };

    let (left, right) = if split_horizontal {
        let split_at = min_size + (rng.next() as u32) % (part.w - min_size * 2).max(1);
        let left = Partition {
            x: part.x,
            y: part.y,
            w: split_at,
            h: part.h,
        };
        let right = Partition {
            x: part.x + split_at,
            y: part.y,
            w: part.w - split_at,
            h: part.h,
        };
        (left, right)
    } else {
        let split_at = min_size + (rng.next() as u32) % (part.h - min_size * 2).max(1);
        let left = Partition {
            x: part.x,
            y: part.y,
            w: part.w,
            h: split_at,
        };
        let right = Partition {
            x: part.x,
            y: part.y + split_at,
            w: part.w,
            h: part.h - split_at,
        };
        (left, right)
    };

    let lp = split(left, depth - 1, min_size, opts, rng, rooms, corridors);
    let rp = split(right, depth - 1, min_size, opts, rng, rooms, corridors);

    // Connect the two sub-partitions with an L-shaped corridor
    let (x1, y1) = lp.center();
    let (x2, y2) = rp.center();
    corridors.push((x1, y1, x2, y2));

    part
}
