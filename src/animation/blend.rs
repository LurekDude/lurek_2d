//! Animation blend layers and optional bone masks.
//! Owns `BlendMask`, `BlendLayer`, and `BlendLayerSet`.
//! Does not own animation playback; it only stores blend configuration.
/// Bone mask for restricting a blend layer to selected bones.
#[derive(Debug, Clone, Default)]
pub struct BlendMask {
    /// Bones included by the mask; empty means all bones.
    pub bone_names: Vec<String>,
}
impl BlendMask {
    /// Create a mask that includes all bones.
    pub fn all() -> Self {
        Self {
            bone_names: Vec::new(),
        }
    }
    /// Create a mask from an explicit bone list.
    pub fn from_bones(bones: Vec<String>) -> Self {
        Self { bone_names: bones }
    }
    /// Return `true` when the mask includes `bone`.
    pub fn includes(&self, bone: &str) -> bool {
        self.bone_names.is_empty() || self.bone_names.iter().any(|b| b == bone)
    }
}
#[derive(Debug, Clone)]
/// One named blend layer referencing a clip and mask.
pub struct BlendLayer {
    /// Layer name.
    pub name: String,
    /// Clip name assigned to this layer.
    pub clip_name: String,
    /// Blend weight clamped to `[0, 1]`.
    pub weight: f32,
    /// Bone mask applied to this layer.
    pub mask: BlendMask,
}
impl BlendLayer {
    /// Create a blend layer with clamped weight.
    pub fn new(name: &str, clip_name: &str, weight: f32, mask: BlendMask) -> Self {
        Self {
            name: name.to_string(),
            clip_name: clip_name.to_string(),
            weight: weight.clamp(0.0, 1.0),
            mask,
        }
    }
}
/// Ordered set of blend layers addressed by name.
#[derive(Debug, Clone, Default)]
pub struct BlendLayerSet {
    /// Stored layers.
    layers: Vec<BlendLayer>,
}
impl BlendLayerSet {
    /// Create an empty layer set.
    pub fn new() -> Self {
        Self { layers: Vec::new() }
    }
    /// Return the number of layers.
    pub fn len(&self) -> usize {
        self.layers.len()
    }
    /// Return `true` when no layers are stored.
    pub fn is_empty(&self) -> bool {
        self.layers.is_empty()
    }
    /// Add a layer; returns an error when the name already exists.
    pub fn add_layer(&mut self, layer: BlendLayer) -> Result<(), String> {
        if self.layers.iter().any(|l| l.name == layer.name) {
            return Err(format!("blend: layer '{}' already exists", layer.name));
        }
        self.layers.push(layer);
        log::debug!(
            "animation: blend layer '{}' added",
            self.layers.last().unwrap().name
        );
        Ok(())
    }
    /// Remove a layer by name.
    pub fn remove_layer(&mut self, name: &str) -> Result<(), String> {
        let pos = self
            .layers
            .iter()
            .position(|l| l.name == name)
            .ok_or_else(|| format!("blend: layer '{name}' not found"))?;
        self.layers.remove(pos);
        log::debug!("animation: blend layer '{name}' removed");
        Ok(())
    }
    /// Set a layer's weight and clamp it to `[0, 1]`.
    pub fn set_weight(&mut self, name: &str, weight: f32) -> Result<(), String> {
        let layer = self
            .layers
            .iter_mut()
            .find(|l| l.name == name)
            .ok_or_else(|| format!("blend: layer '{name}' not found"))?;
        layer.weight = weight.clamp(0.0, 1.0);
        Ok(())
    }
    /// Return a layer's weight, or `None` when missing.
    pub fn get_weight(&self, name: &str) -> Option<f32> {
        self.layers
            .iter()
            .find(|l| l.name == name)
            .map(|l| l.weight)
    }
    /// Replace a layer's mask.
    pub fn set_mask(&mut self, name: &str, mask: BlendMask) -> Result<(), String> {
        let layer = self
            .layers
            .iter_mut()
            .find(|l| l.name == name)
            .ok_or_else(|| format!("blend: layer '{name}' not found"))?;
        layer.mask = mask;
        Ok(())
    }
    /// Return the stored layers.
    pub fn layers(&self) -> &[BlendLayer] {
        &self.layers
    }
    /// Return a layer by name.
    pub fn get_layer(&self, name: &str) -> Option<&BlendLayer> {
        self.layers.iter().find(|l| l.name == name)
    }
}
