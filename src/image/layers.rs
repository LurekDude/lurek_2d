use super::image_data::ImageData;
#[derive(Debug, Clone)]
pub struct ImageLayer {
    pub name: String,
    pub opacity: f32,
    pub visible: bool,
    pub data: ImageData,
}
impl ImageLayer {
    pub fn new(name: impl Into<String>, width: u32, height: u32) -> Self {
        Self {
            name: name.into(),
            opacity: 1.0,
            visible: true,
            data: ImageData::new(width, height),
        }
    }
}
#[derive(Debug, Clone)]
pub struct LayeredImage {
    pub(super) width: u32,
    pub(super) height: u32,
    pub(super) layers: Vec<ImageLayer>,
}
impl LayeredImage {
    pub fn new(width: u32, height: u32) -> Self {
        Self {
            width,
            height,
            layers: Vec::new(),
        }
    }
    pub fn width(&self) -> u32 {
        self.width
    }
    pub fn height(&self) -> u32 {
        self.height
    }
    pub fn layer_count(&self) -> usize {
        self.layers.len()
    }
    pub fn add_layer(&mut self, name: impl Into<String>) -> usize {
        self.layers
            .push(ImageLayer::new(name, self.width, self.height));
        self.layers.len() - 1
    }
    pub fn remove_layer(&mut self, index: usize) -> Option<ImageLayer> {
        if index < self.layers.len() {
            Some(self.layers.remove(index))
        } else {
            None
        }
    }
    pub fn get_layer(&self, index: usize) -> Option<&ImageLayer> {
        self.layers.get(index)
    }
    pub fn get_layer_mut(&mut self, index: usize) -> Option<&mut ImageLayer> {
        self.layers.get_mut(index)
    }
    pub fn set_opacity(&mut self, index: usize, opacity: f32) -> bool {
        if let Some(layer) = self.layers.get_mut(index) {
            layer.opacity = opacity.clamp(0.0, 1.0);
            true
        } else {
            false
        }
    }
    pub fn set_visible(&mut self, index: usize, visible: bool) -> bool {
        if let Some(layer) = self.layers.get_mut(index) {
            layer.visible = visible;
            true
        } else {
            false
        }
    }
    pub fn set_name(&mut self, index: usize, name: impl Into<String>) -> bool {
        if let Some(layer) = self.layers.get_mut(index) {
            layer.name = name.into();
            true
        } else {
            false
        }
    }
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
    pub fn swap_layers(&mut self, a: usize, b: usize) -> bool {
        let len = self.layers.len();
        if a >= len || b >= len || a == b {
            return false;
        }
        self.layers.swap(a, b);
        true
    }
    pub fn move_layer(&mut self, from_index: usize, to_index: usize) -> bool {
        let len = self.layers.len();
        if from_index >= len || to_index >= len {
            return false;
        }
        let layer = self.layers.remove(from_index);
        self.layers.insert(to_index, layer);
        true
    }
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
