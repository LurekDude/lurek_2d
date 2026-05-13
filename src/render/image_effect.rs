use std::collections::HashMap;
#[derive(Debug, Clone)]
pub struct ShaderPassDescriptor {
    pub effect_name: String,
    pub params: HashMap<String, f32>,
    pub enabled: bool,
}
impl ShaderPassDescriptor {
    pub fn new(effect_name: impl Into<String>) -> Self {
        Self {
            effect_name: effect_name.into(),
            params: HashMap::new(),
            enabled: true,
        }
    }
}
