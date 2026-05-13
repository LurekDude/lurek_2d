use super::lcg::Lcg;
#[derive(Debug, Clone)]
pub struct CellularOpts {
    pub fill: f32,
    pub iterations: u32,
    pub birth: u32,
    pub survive: u32,
    pub seed: u64,
}
impl Default for CellularOpts {
    fn default() -> Self {
        Self {
            fill: 0.45,
            iterations: 5,
            birth: 6,
            survive: 4,
            seed: 12345,
        }
    }
}
pub fn cellular_automata(width: u32, height: u32, opts: &CellularOpts) -> Vec<u8> {
    let size = (width * height) as usize;
    let mut grid = vec![0u8; size];
    let mut rng = Lcg::new(opts.seed);
    for cell in grid.iter_mut() {
        *cell = if rng.next_f32() < opts.fill { 1 } else { 0 };
    }
    let mut next = vec![0u8; size];
    for _ in 0..opts.iterations {
        for y in 0..height {
            for x in 0..width {
                let idx = (y * width + x) as usize;
                let mut neighbors = 0u32;
                for dy in -1i32..=1 {
                    for dx in -1i32..=1 {
                        if dx == 0 && dy == 0 {
                            continue;
                        }
                        let nx = x as i32 + dx;
                        let ny = y as i32 + dy;
                        if nx < 0 || ny < 0 || nx >= width as i32 || ny >= height as i32 {
                            neighbors += 1;
                        } else {
                            neighbors += grid[(ny as u32 * width + nx as u32) as usize] as u32;
                        }
                    }
                }
                next[idx] = if grid[idx] == 1 {
                    if neighbors >= opts.survive {
                        1
                    } else {
                        0
                    }
                } else if neighbors >= opts.birth {
                    1
                } else {
                    0
                };
            }
        }
        std::mem::swap(&mut grid, &mut next);
    }
    grid
}
