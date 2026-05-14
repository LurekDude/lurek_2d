//! Scatter-and-connect room dungeon generator for `src/procgen`.
//! Owns `RoomsOpts`, `RoomsDungeon`, `Room`, prefab stamping types, and the
//! `rooms_dungeon` / `rooms_dungeon_with_prefabs` entry points. Corridor tiles
//! are written as value `2` and floor tiles as `1` into the flat grid.
//! Does not own BSP partitioning — that lives in `bsp.rs`.

use crate::procgen::lcg::Lcg;

/// Axis-aligned room rectangle placed in a rooms dungeon grid.
#[derive(Debug, Clone)]
pub struct Room {
    /// Left edge in tile coordinates.
    pub x: u32,
    /// Top edge in tile coordinates.
    pub y: u32,
    /// Room width in tiles.
    pub w: u32,
    /// Room height in tiles.
    pub h: u32,
}

impl Room {
    /// Return true if this room overlaps `other` with a 1-tile buffer on each side.
    fn overlaps(&self, other: &Room) -> bool {
        self.x < other.x + other.w + 1
            && self.x + self.w + 1 > other.x
            && self.y < other.y + other.h + 1
            && self.y + self.h + 1 > other.y
    }

    /// Return the centre tile coordinates of this room.
    fn center(&self) -> (u32, u32) {
        (self.x + self.w / 2, self.y + self.h / 2)
    }
}

/// Configuration for a random-room dungeon generation run.
#[derive(Debug, Clone)]
pub struct RoomsOpts {
    /// Total dungeon width in tiles.
    pub width: u32,
    /// Total dungeon height in tiles.
    pub height: u32,
    /// Maximum number of rooms to place; actual count may be lower when space is scarce.
    pub max_rooms: u32,
    /// Minimum room dimension in tiles (both width and height).
    pub min_room_size: u32,
    /// Maximum room dimension in tiles (both width and height).
    pub max_room_size: u32,
    /// Seed for the internal `Lcg` RNG.
    pub seed: u64,
}

/// Provide defaults for a 64×64 dungeon: up to 20 rooms of 4–12 tiles.
impl Default for RoomsOpts {
    fn default() -> Self {
        Self {
            width: 64,
            height: 64,
            max_rooms: 20,
            min_room_size: 4,
            max_room_size: 12,
            seed: 42,
        }
    }
}

/// Completed rooms dungeon: placed rooms, corridor segments, and the flat tile grid.
#[derive(Debug, Clone)]
pub struct RoomsDungeon {
    /// All successfully placed rooms.
    pub rooms: Vec<Room>,
    /// Corridor centre-line segments as `(x1, y1, x2, y2)` tile pairs.
    pub corridors: Vec<(u32, u32, u32, u32)>,
    /// Flat row-major tile grid: `0` = wall, `1` = floor, `2` = corridor.
    pub grid: Vec<u8>,
}

/// Template shape used to overwrite a room's interior with a named stamp pattern.
#[derive(Debug, Clone)]
pub struct RoomPrefabStamp {
    /// Prefab identifier matched to placements in the output.
    pub name: String,
    /// Non-zero mask bytes indicate which cells are stamped with `stamp_value`.
    pub mask: Vec<u8>,
    /// Mask width in tiles; must be <= room width to be placed.
    pub width: u32,
    /// Mask height in tiles; must be <= room height to be placed.
    pub height: u32,
}

/// A `RoomPrefabStamp` placed at a concrete tile position within a room.
#[derive(Debug, Clone)]
pub struct PlacedRoomPrefab {
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

/// Generate a rooms dungeon from `opts`; returns rooms, L-shaped corridors, and the tile grid.
pub fn rooms_dungeon(opts: &RoomsOpts) -> RoomsDungeon {
    let mut rng = Lcg::new(opts.seed);
    let mut grid = vec![0u8; (opts.width * opts.height) as usize];
    let mut rooms: Vec<Room> = Vec::new();
    let size_range = opts.max_room_size - opts.min_room_size + 1;
    for _ in 0..opts.max_rooms * 4 {
        if rooms.len() as u32 >= opts.max_rooms {
            break;
        }
        let rw = opts.min_room_size + (rng.next() as u32) % size_range.max(1);
        let rh = opts.min_room_size + (rng.next() as u32) % size_range.max(1);
        if opts.width <= rw + 2 || opts.height <= rh + 2 {
            continue;
        }
        let rx = 1 + (rng.next() as u32) % (opts.width - rw - 2).max(1);
        let ry = 1 + (rng.next() as u32) % (opts.height - rh - 2).max(1);
        let candidate = Room {
            x: rx,
            y: ry,
            w: rw,
            h: rh,
        };
        if rooms.iter().any(|r| r.overlaps(&candidate)) {
            continue;
        }
        for dy in 0..rh {
            for dx in 0..rw {
                let idx = ((ry + dy) * opts.width + rx + dx) as usize;
                grid[idx] = 1;
            }
        }
        rooms.push(candidate);
    }
    let mut corridors = Vec::new();
    for i in 1..rooms.len() {
        let (x1, y1) = rooms[i - 1].center();
        let (x2, y2) = rooms[i].center();
        corridors.push((x1, y1, x2, y2));
        let (sx, ex) = if x1 < x2 { (x1, x2) } else { (x2, x1) };
        for cx in sx..=ex {
            let idx = (y1 * opts.width + cx) as usize;
            if idx < grid.len() && grid[idx] == 0 {
                grid[idx] = 2;
            }
        }
        let (sy, ey) = if y1 < y2 { (y1, y2) } else { (y2, y1) };
        for cy in sy..=ey {
            let idx = (cy * opts.width + x2) as usize;
            if idx < grid.len() && grid[idx] == 0 {
                grid[idx] = 2;
            }
        }
    }
    RoomsDungeon {
        rooms,
        corridors,
        grid,
    }
}
/// Generate a rooms dungeon, centre-stamp `prefabs` (round-robin) in each room, and return `(dungeon, placements)`.
pub fn rooms_dungeon_with_prefabs(
    opts: &RoomsOpts,
    prefabs: &[RoomPrefabStamp],
    stamp_value: u8,
) -> (RoomsDungeon, Vec<PlacedRoomPrefab>) {
    let mut dungeon = rooms_dungeon(opts);
    let placements = apply_prefab_stamps(
        &mut dungeon.grid,
        opts.width,
        opts.height,
        &dungeon.rooms,
        prefabs,
        stamp_value,
    );
    (dungeon, placements)
}
/// Centre-stamp `prefabs` into `rooms` using non-zero mask bytes written as `stamp_value`; returns all placements.
fn apply_prefab_stamps(
    grid: &mut [u8],
    grid_w: u32,
    grid_h: u32,
    rooms: &[Room],
    prefabs: &[RoomPrefabStamp],
    stamp_value: u8,
) -> Vec<PlacedRoomPrefab> {
    if prefabs.is_empty() {
        return Vec::new();
    }
    let mut out = Vec::new();
    for (i, room) in rooms.iter().enumerate() {
        let prefab = &prefabs[i % prefabs.len()];
        if prefab.width == 0 || prefab.height == 0 {
            continue;
        }
        if prefab.width > room.w || prefab.height > room.h {
            continue;
        }
        let ox = room.x + (room.w - prefab.width) / 2;
        let oy = room.y + (room.h - prefab.height) / 2;
        for py in 0..prefab.height {
            for px in 0..prefab.width {
                let pi = (py * prefab.width + px) as usize;
                if prefab.mask.get(pi).copied().unwrap_or(0) == 0 {
                    continue;
                }
                let gx = ox + px;
                let gy = oy + py;
                if gx < grid_w && gy < grid_h {
                    let gi = (gy * grid_w + gx) as usize;
                    if let Some(cell) = grid.get_mut(gi) {
                        *cell = stamp_value;
                    }
                }
            }
        }
        out.push(PlacedRoomPrefab {
            name: prefab.name.clone(),
            x: ox,
            y: oy,
            width: prefab.width,
            height: prefab.height,
        });
    }
    out
}
