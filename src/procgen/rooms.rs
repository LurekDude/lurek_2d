use crate::procgen::lcg::Lcg;
#[derive(Debug, Clone)]
pub struct Room {
    pub x: u32,
    pub y: u32,
    pub w: u32,
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
#[derive(Debug, Clone)]
pub struct RoomsOpts {
    pub width: u32,
    pub height: u32,
    pub max_rooms: u32,
    pub min_room_size: u32,
    pub max_room_size: u32,
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
#[derive(Debug, Clone)]
pub struct RoomsDungeon {
    pub rooms: Vec<Room>,
    pub corridors: Vec<(u32, u32, u32, u32)>,
    pub grid: Vec<u8>,
}
#[derive(Debug, Clone)]
pub struct RoomPrefabStamp {
    pub name: String,
    pub mask: Vec<u8>,
    pub width: u32,
    pub height: u32,
}
#[derive(Debug, Clone)]
pub struct PlacedRoomPrefab {
    pub name: String,
    pub x: u32,
    pub y: u32,
    pub width: u32,
    pub height: u32,
}
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
