
use super::image_data::ImageData;
/// A single named image layer with opacity, visibility, and pixel data.
#[derive(Debug, Clone)]
pub struct ImageLayer {
    /// Layer display name.
    pub name: String,
    /// Layer opacity in the 0.0-1.0 range.
    pub opacity: f32,
    /// Whether the layer participates in compositing.
    pub visible: bool,
    /// Layer pixel data.
    pub data: ImageData,
}
impl ImageLayer {
    /// Create a visible opaque layer with a blank canvas of the given size.
    pub fn new(name: impl Into<String>, width: u32, height: u32) -> Self {
        Self {
            name: name.into(),
            opacity: 1.0,
            visible: true,
            data: ImageData::new(width, height),
        }
    }
}
/// A same-sized stack of image layers that can be merged into one image.
#[derive(Debug, Clone)]
pub struct LayeredImage {
    /// Canvas width in pixels.
    pub(super) width: u32,
    /// Canvas height in pixels.
    pub(super) height: u32,
    /// Ordered layer list from back to front.
    pub(super) layers: Vec<ImageLayer>,
}
impl LayeredImage {
    /// Create an empty layered image with the given canvas size.
    pub fn new(width: u32, height: u32) -> Self {
        Self {
            width,
            height,
            layers: Vec::new(),
        }
    }
    /// Return the canvas width in pixels.
    pub fn width(&self) -> u32 {
        self.width
    }
    /// Return the canvas height in pixels.
    pub fn height(&self) -> u32 {
        self.height
    }
    /// Return the number of layers in the stack.
    pub fn layer_count(&self) -> usize {
        self.layers.len()
    }
    /// Append a new blank layer and return its index.
    pub fn add_layer(&mut self, name: impl Into<String>) -> usize {
        self.layers
            .push(ImageLayer::new(name, self.width, self.height));
        self.layers.len() - 1
    }
    /// Remove a layer by index and return it when present.
    pub fn remove_layer(&mut self, index: usize) -> Option<ImageLayer> {
        if index < self.layers.len() {
            Some(self.layers.remove(index))
        } else {
            None
        }
    }
    /// Return a layer by index.
    pub fn get_layer(&self, index: usize) -> Option<&ImageLayer> {
        self.layers.get(index)
    }
    /// Return a mutable layer by index.
    pub fn get_layer_mut(&mut self, index: usize) -> Option<&mut ImageLayer> {
        self.layers.get_mut(index)
    }
    /// Set a layer opacity and clamp it to the valid range.
    pub fn set_opacity(&mut self, index: usize, opacity: f32) -> bool {
        if let Some(layer) = self.layers.get_mut(index) {
            layer.opacity = opacity.clamp(0.0, 1.0);
            true
        } else {
            false
        }
    }
    /// Set a layer visibility flag and return whether the layer existed.
    pub fn set_visible(&mut self, index: usize, visible: bool) -> bool {
        if let Some(layer) = self.layers.get_mut(index) {
            layer.visible = visible;
            true
        } else {
            false
        }
    }
    /// Rename a layer and return whether the layer existed.
    pub fn set_name(&mut self, index: usize, name: impl Into<String>) -> bool {
        if let Some(layer) = self.layers.get_mut(index) {
            layer.name = name.into();
            true
        } else {
            false
        }
    }
    /// Replace a layer image with a copied source image or a pasted canvas copy.
    pub fn set_layer_image(&mut self, index: usize, source: &ImageData) -> bool {
        if let Some(layer) = self.layers.get_mut(index) {
            if source.width() == self.width && source.height() == self.height {
                layer.data = source.clone();
            } else {
                let mut canvas = ImageData::new(self.width, self.height);
                canvas.paste(source, 0, 0);
                layer.data = canvas;
            }
            true
        } else {
            false
        }
    }
    /// Swap two layers and return false when either index is invalid.
    pub fn swap_layers(&mut self, a: usize, b: usize) -> bool {
        let len = self.layers.len();
        if a >= len || b >= len || a == b {
            return false;
        }
        self.layers.swap(a, b);
        true
    }
    /// Move a layer to another position and return false when either index is invalid.
    pub fn move_layer(&mut self, from_index: usize, to_index: usize) -> bool {
        let len = self.layers.len();
        if from_index >= len || to_index >= len {
            return false;
        }
        let layer = self.layers.remove(from_index);
        self.layers.insert(to_index, layer);
        true
    }
    /// Merge visible layers front-to-back into a new image.
    pub fn merge(&self) -> ImageData {
        let mut result = ImageData::new(self.width, self.height);
        let pixels_len = (self.width * self.height * 4) as usize;
        let dst = result.pixels.as_mut_slice();
        for layer in &self.layers {
            if !layer.visible {
                continue;
            }
            let src = layer.data.pixels.as_slice();
            let src_len = src.len().min(pixels_len);
            let px_count = src_len / 4;
            for i in 0..px_count {
                let si = i * 4;
                let sr = src[si] as f32;
                let sg = src[si + 1] as f32;
                let sb = src[si + 2] as f32;
                let sa = src[si + 3] as f32 / 255.0 * layer.opacity;
                if sa <= 0.0 {
                    continue;
                }
                let dr = dst[si] as f32;
                let dg = dst[si + 1] as f32;
                let db = dst[si + 2] as f32;
                let da = dst[si + 3] as f32 / 255.0;
                let out_a = sa + da * (1.0 - sa);
                if out_a <= 0.0 {
                    dst[si] = 0;
                    dst[si + 1] = 0;
                    dst[si + 2] = 0;
                    dst[si + 3] = 0;
                } else {
                    dst[si] = ((sr * sa + dr * da * (1.0 - sa)) / out_a).round() as u8;
                    dst[si + 1] = ((sg * sa + dg * da * (1.0 - sa)) / out_a).round() as u8;
                    dst[si + 2] = ((sb * sa + db * da * (1.0 - sa)) / out_a).round() as u8;
                    dst[si + 3] = (out_a * 255.0).round().min(255.0) as u8;
                }
            }
        }
        result
    }
}
