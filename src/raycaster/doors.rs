#[derive(Debug, Clone, Copy, PartialEq)]
pub enum DoorDirection {
    Horizontal,
    Vertical,
}
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum DoorState {
    Closed,
    Opening,
    Open,
    Closing,
}
#[derive(Debug, Clone)]
pub struct Door {
    pub x: u32,
    pub y: u32,
    pub open_amount: f32,
    pub speed: f32,
    pub direction: DoorDirection,
    pub state: DoorState,
}
pub struct DoorManager {
    doors: Vec<Door>,
}
impl DoorManager {
    pub fn new() -> Self {
        Self { doors: Vec::new() }
    }
    pub fn add_door(&mut self, x: u32, y: u32, direction: DoorDirection, speed: f32) -> usize {
        let index = self.doors.len();
        self.doors.push(Door {
            x,
            y,
            open_amount: 0.0,
            speed,
            direction,
            state: DoorState::Closed,
        });
        index
    }
    pub fn open_door(&mut self, index: usize) {
        if let Some(door) = self.doors.get_mut(index) {
            if door.state == DoorState::Closed || door.state == DoorState::Closing {
                door.state = DoorState::Opening;
            }
        }
    }
    pub fn close_door(&mut self, index: usize) {
        if let Some(door) = self.doors.get_mut(index) {
            if door.state == DoorState::Open || door.state == DoorState::Opening {
                door.state = DoorState::Closing;
            }
        }
    }
    pub fn update(&mut self, dt: f32) {
        for door in &mut self.doors {
            match door.state {
                DoorState::Opening => {
                    door.open_amount += door.speed * dt;
                    if door.open_amount >= 1.0 {
                        door.open_amount = 1.0;
                        door.state = DoorState::Open;
                    }
                }
                DoorState::Closing => {
                    door.open_amount -= door.speed * dt;
                    if door.open_amount <= 0.0 {
                        door.open_amount = 0.0;
                        door.state = DoorState::Closed;
                    }
                }
                _ => {}
            }
        }
    }
    pub fn get_door_at(&self, x: u32, y: u32) -> Option<&Door> {
        self.doors.iter().find(|d| d.x == x && d.y == y)
    }
    pub fn doors(&self) -> &[Door] {
        &self.doors
    }
}
impl Default for DoorManager {
    fn default() -> Self {
        Self::new()
    }
}
