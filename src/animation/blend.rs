//! Blend-layer system for compositing multiple animation clips on one sprite.
//! Defines `BlendMask`, `BlendLayer`, and `BlendLayerSet`; enforces name uniqueness
//! and clamps weights to `[0.0, 1.0]`. Does not own frame timing or clip state.

// ---- Type: BlendMask ----

/// Bone restriction mask for a `BlendLayer`; empty `bone_names` means all bones.
#[derive(Debug, Clone, Default)]
pub struct BlendMask {
    /// Bone names this layer affects; empty = no masking (all bones).
    pub bone_names: Vec<String>,
}

impl BlendMask {
    // ---- Implementation: BlendMask ----
    /// Create a mask that affects all bones (no filtering).
    pub fn all() -> Self {
        Self {
            bone_names: Vec::new(),
        }
    }

    /// Create a mask restricted to the given bone names.
    pub fn from_bones(bones: Vec<String>) -> Self {
        Self { bone_names: bones }
    }

    /// Return `true` if this mask applies to the given bone name.
    pub fn includes(&self, bone: &str) -> bool {
        self.bone_names.is_empty() || self.bone_names.iter().any(|b| b == bone)
    }
}

// ---- Type: BlendLayer ----

/// One layer in a [`BlendLayerSet`]: a named clip at a given blend weight.
#[derive(Debug, Clone)]
pub struct BlendLayer {
    /// Unique name for this layer (used as a stable key for lookups).
    pub name: String,
    /// Name of the [`AnimClip`] this layer plays.
    pub clip_name: String,
    /// Blend weight in `[0.0, 1.0]`.  Weight 0 = invisible; weight 1 = full.
    pub weight: f32,
    /// Bone mask restricting which joints this layer influences.
    pub mask: BlendMask,
}

impl BlendLayer {
    // ---- Implementation: BlendLayer ----
    /// Create a new blend layer.
    pub fn new(name: &str, clip_name: &str, weight: f32, mask: BlendMask) -> Self {
        Self {
            name: name.to_string(),
            clip_name: clip_name.to_string(),
            weight: weight.clamp(0.0, 1.0),
            mask,
        }
    }
}

// ---- Type: BlendLayerSet ----

/// Ordered set of blend layers for a single sprite's animation.
#[derive(Debug, Clone, Default)]
pub struct BlendLayerSet {
    layers: Vec<BlendLayer>,
}

impl BlendLayerSet {
    // ---- Implementation: BlendLayerSet ----
    /// Create an empty blend layer set.
    pub fn new() -> Self {
        Self { layers: Vec::new() }
    }

    /// Return the number of layers currently in the set.
    pub fn len(&self) -> usize {
        self.layers.len()
    }

    /// Return `true` if the set contains no layers.
    pub fn is_empty(&self) -> bool {
        self.layers.is_empty()
    }

    /// Append a new layer.  Returns `Err` if a layer with the same name already exists.
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

    /// Remove a layer by name.  Returns `Err` if not found.
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

    /// Set the blend weight of a layer.  Returns `Err` if the layer is not found.
    pub fn set_weight(&mut self, name: &str, weight: f32) -> Result<(), String> {
        let layer = self
            .layers
            .iter_mut()
            .find(|l| l.name == name)
            .ok_or_else(|| format!("blend: layer '{name}' not found"))?;
        layer.weight = weight.clamp(0.0, 1.0);
        Ok(())
    }

    /// Return the current weight of a layer, or `None` if not found.
    pub fn get_weight(&self, name: &str) -> Option<f32> {
        self.layers
            .iter()
            .find(|l| l.name == name)
            .map(|l| l.weight)
    }

    /// Replace the bone mask of a layer.  Returns `Err` if not found.
    pub fn set_mask(&mut self, name: &str, mask: BlendMask) -> Result<(), String> {
        let layer = self
            .layers
            .iter_mut()
            .find(|l| l.name == name)
            .ok_or_else(|| format!("blend: layer '{name}' not found"))?;
        layer.mask = mask;
        Ok(())
    }

    /// Return a reference to the ordered layer list.
    pub fn layers(&self) -> &[BlendLayer] {
        &self.layers
    }

    /// Return an immutable reference to a named layer, or `None`.
    pub fn get_layer(&self, name: &str) -> Option<&BlendLayer> {
        self.layers.iter().find(|l| l.name == name)
    }
}
