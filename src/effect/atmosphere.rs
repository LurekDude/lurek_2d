#[derive(Debug, Clone)]
pub struct CloudState {
    pub enabled: bool,
    pub count: u32,
    pub speed: f32,
    pub scale: f32,
    pub opacity: f32,
    pub offset: f32,
}
impl Default for CloudState {
    fn default() -> Self {
        Self {
            enabled: false,
            count: 5,
            speed: 20.0,
            scale: 1.0,
            opacity: 0.3,
            offset: 0.0,
        }
    }
}
#[derive(Debug, Clone)]
pub struct FogState {
    pub enabled: bool,
    pub density: f32,
    pub color: [f32; 4],
}
impl Default for FogState {
    fn default() -> Self {
        Self {
            enabled: false,
            density: 0.3,
            color: [0.7, 0.7, 0.8, 1.0],
        }
    }
}
#[derive(Debug, Clone)]
pub struct HeatHazeState {
    pub enabled: bool,
    pub intensity: f32,
}
impl Default for HeatHazeState {
    fn default() -> Self {
        Self {
            enabled: false,
            intensity: 0.5,
        }
    }
}
#[derive(Debug, Clone)]
pub struct VignetteState {
    pub enabled: bool,
    pub strength: f32,
}
impl Default for VignetteState {
    fn default() -> Self {
        Self {
            enabled: false,
            strength: 0.5,
        }
    }
}
#[derive(Debug, Clone)]
pub struct FilmGrainState {
    pub enabled: bool,
    pub intensity: f32,
}
impl Default for FilmGrainState {
    fn default() -> Self {
        Self {
            enabled: false,
            intensity: 0.3,
        }
    }
}
#[derive(Debug, Clone)]
pub struct LightningState {
    pub active: bool,
    pub color: [f32; 4],
    pub elapsed: f32,
    pub duration: f32,
}
impl Default for LightningState {
    fn default() -> Self {
        Self {
            active: false,
            color: [0.9, 0.9, 1.0, 0.8],
            elapsed: 0.0,
            duration: 0.15,
        }
    }
}
