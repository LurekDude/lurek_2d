//! Rooms-and-corridors dungeon generator with random scatter placement.
//!
//! Attempts to place non-overlapping rooms, then connects adjacent rooms
//! with L-shaped corridors. Grid cells: 0 = wall, 1 = floor, 2 = corridor.

use crate::procgen::lcg::Lcg;

/// A placed room in the dungeon.
///
/// # Fields
/// - `x` — `u32`.
/// - `y` — `u32`.
/// - `w` — `u32`.
/// - `h` — `u32`.
#[derive(Debug, Clone)]
pub struct Room {
    /// Left column of the room.
    pub x: u32,
    /// Top row of the room.
    pub y: u32,
    /// Room width.
    pub w: u32,
    /// Room height.
    pub h: u32,
}

impl Room {
    fn overlaps(&self, other: &Room) -> bool {
        self.x < other.x + other.w + 1
            && self.x + self.w + 1 > other.x
            && self.y < other.y + other.h + 1
            && self.y + self.h + 1 > other.y
    }

    fn center(&self) -> (u32, u32) {
        (self.x + self.w / 2, self.y + self.h / 2)
    }
}

/// Options for rooms-and-corridors generation.
///
/// # Fields
/// - `width` — `u32`.
/// - `height` — `u32`.
/// - `max_rooms` — `u32`.
/// - `min_room_size` — `u32`.
/// - `max_room_size` — `u32`.
/// - `seed` — `u64`.
#[derive(Debug, Clone)]
pub struct RoomsOpts {
    /// Dungeon width in cells.
    pub width: u32,
    /// Dungeon height in cells.
    pub height: u32,
    /// Maximum number of rooms to attempt placing.
    pub max_rooms: u32,
    /// Minimum room side length.
    pub min_room_size: u32,
    /// Maximum room side length.
    pub max_room_size: u32,
    /// Random seed.
    pub seed: u64,
}

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

/// The result of rooms-and-corridors generation.
///
/// # Fields
/// - `rooms` — `Vec<Room>`.
/// - `corridors` — `Vec<(u32, u32, u32, u32)>`.
/// - `grid` — `Vec<u8>`.
#[derive(Debug, Clone)]
pub struct RoomsDungeon {
    /// All successfully placed rooms.
    pub rooms: Vec<Room>,
    /// Corridors as `(x1, y1, x2, y2)` start/end points.
    pub corridors: Vec<(u32, u32, u32, u32)>,
    /// Flat grid: 0 = wall, 1 = floor, 2 = corridor. Row-major: `grid[y * width + x]`.
    pub grid: Vec<u8>,
}

/// Stamp template that can be projected onto generated dungeon rooms.
#[derive(Debug, Clone)]
pub struct RoomPrefabStamp {
    /// Prefab identifier, passed through to output metadata.
    pub name: String,
    /// Flat cell mask in row-major order. Non-zero values are stamped.
    pub mask: Vec<u8>,
    /// Prefab width in cells.
    pub width: u32,
    /// Prefab height in cells.
    pub height: u32,
}

/// Result placement metadata for a prefab stamp.
#[derive(Debug, Clone)]
pub struct PlacedRoomPrefab {
    /// Prefab identifier.
    pub name: String,
    /// Placement origin X in dungeon grid.
    pub x: u32,
    /// Placement origin Y in dungeon grid.
    pub y: u32,
    /// Placement width.
    pub width: u32,
    /// Placement height.
    pub height: u32,
}

/// Generate a rooms-and-corridors dungeon.
///
/// # Parameters
/// - `opts` — `&RoomsOpts`.
///
/// # Returns
/// `RoomsDungeon`.
pub fn rooms_dungeon(opts: &RoomsOpts) -> RoomsDungeon {
    let mut rng = Lcg::new(opts.seed);
    let mut grid = vec![0u8; (opts.width * opts.height) as usize];
    let mut rooms: Vec<Room> = Vec::new();
    let size_range = opts.max_room_size - opts.min_room_size + 1;

    // Attempt to place rooms
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

        // Carve room into grid
        for dy in 0..rh {
            for dx in 0..rw {
                let idx = ((ry + dy) * opts.width + rx + dx) as usize;
                grid[idx] = 1;
            }
        }
        rooms.push(candidate);
    }

    // Connect consecutive rooms with L-shaped corridors
    let mut corridors = Vec::new();
    for i in 1..rooms.len() {
        let (x1, y1) = rooms[i - 1].center();
        let (x2, y2) = rooms[i].center();
        corridors.push((x1, y1, x2, y2));

        // Carve horizontal then vertical
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

/// Generates a rooms dungeon and stamps prefabs into room interiors.
///
/// Prefabs are applied in room order (cyclic if there are more rooms than prefabs).
/// Stamped cells overwrite wall/floor/corridor values with `stamp_value` where mask > 0.
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
