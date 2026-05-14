//! Binary Space Partitioning dungeon generator for `src/procgen`.
//! Owns `BspRoom`, `BspDungeon`, `BspOpts`, prefab stamping types, and the
//! `bsp_dungeon` / `bsp_dungeon_with_prefabs` entry points. Does not own corridor
//! rendering or room placement logic beyond BSP tree partitioning.
//! Depends on `lcg.rs` for deterministic random splitting.

use crate::procgen::lcg::Lcg;

/// Axis-aligned room rectangle produced by BSP partitioning.
#[derive(Debug, Clone)]
pub struct BspRoom {
    /// Left edge in tile coordinates.
    pub x: u32,
    /// Top edge in tile coordinates.
    pub y: u32,
    /// Room width in tiles.
    pub w: u32,
    /// Room height in tiles.
    pub h: u32,
}

/// Completed BSP dungeon with rooms and their connecting corridors.
#[derive(Debug, Clone)]
pub struct BspDungeon {
    /// All leaf rooms created during partitioning.
    pub rooms: Vec<BspRoom>,
    /// Corridor centre-line segments as `(x1, y1, x2, y2)` tile pairs.
    pub corridors: Vec<(u32, u32, u32, u32)>,
}

/// Template shape used to stamp a named prefab into a room during BSP generation.
#[derive(Debug, Clone)]
pub struct BspPrefabStamp {
    /// Prefab identifier used to look up mask data in the caller.
    pub name: String,
    /// Template width in tiles; must be <= room width to be placed.
    pub width: u32,
    /// Template height in tiles; must be <= room height to be placed.
    pub height: u32,
}

/// A `BspPrefabStamp` placed at a concrete tile position within a room.
#[derive(Debug, Clone)]
pub struct PlacedBspPrefab {
    /// Originating prefab name.
    pub name: String,
    /// Top-left tile X position in the dungeon grid.
    pub x: u32,
    /// Top-left tile Y position in the dungeon grid.
    pub y: u32,
    /// Placed width in tiles (copied from stamp).
    pub width: u32,
    /// Placed height in tiles (copied from stamp).
    pub height: u32,
}

/// Configuration for a BSP dungeon generation run.
#[derive(Debug, Clone)]
pub struct BspOpts {
    /// Total dungeon width in tiles.
    pub width: u32,
    /// Total dungeon height in tiles.
    pub height: u32,
    /// Minimum partition dimension in tiles; partitions smaller than this become leaf rooms.
    pub min_size: u32,
    /// Maximum recursion depth; 0 means no splitting.
    pub max_depth: u32,
    /// Seed for the internal `Lcg` RNG.
    pub seed: u64,
    /// Tile margin between partition boundary and room edge; >= 1 prevents wall overlap.
    pub padding: u32,
}

/// Provide defaults for a 64×64 dungeon: min_size=6, max_depth=4, padding=1.
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

/// Generate a BSP dungeon from `opts`; returns rooms and centre-line corridors.
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

/// Generate a BSP dungeon and centre-place `prefabs` (round-robin) in rooms that fit; returns `(dungeon, placements)`.
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

/// Rectangular region used during recursive BSP splitting.
#[derive(Clone)]
struct Partition {
    /// Left edge in tile coordinates.
    x: u32,
    /// Top edge in tile coordinates.
    y: u32,
    /// Partition width in tiles.
    w: u32,
    /// Partition height in tiles.
    h: u32,
}

impl Partition {
    /// Return the centre tile coordinates of this partition.
    fn center(&self) -> (u32, u32) {
        (self.x + self.w / 2, self.y + self.h / 2)
    }
}

/// Recursively split `part` up to `depth` levels, accumulating leaf rooms and corridor segments.
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
    let (x1, y1) = lp.center();
    let (x2, y2) = rp.center();
    corridors.push((x1, y1, x2, y2));
    part
}
#[derive(Debug, Clone)]
pub struct BspDungeon {
    pub rooms: Vec<BspRoom>,
    pub corridors: Vec<(u32, u32, u32, u32)>,
}
#[derive(Debug, Clone)]
pub struct BspPrefabStamp {
    pub name: String,
    pub width: u32,
    pub height: u32,
}
#[derive(Debug, Clone)]
pub struct PlacedBspPrefab {
    pub name: String,
    pub x: u32,
    pub y: u32,
    pub width: u32,
    pub height: u32,
}
#[derive(Debug, Clone)]
pub struct BspOpts {
    pub width: u32,
    pub height: u32,
    pub min_size: u32,
    pub max_depth: u32,
    pub seed: u64,
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
    let (x1, y1) = lp.center();
    let (x2, y2) = rp.center();
    corridors.push((x1, y1, x2, y2));
    part
}
