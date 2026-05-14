
//! - Defines the lightweight feed-forward neural-network model used by the AI
//!   module to store dense layers, activation modes, and flattened parameters.
//! - Owns layer-local forward evaluation, activation application, and parameter
//!   counting for each dense stage in the network.
//! - Keeps the network-level operations that append layers, run full forward
//!   passes, and load or export the flat weight and bias buffer used by higher-level AI code.

/// Activation function used by a layer.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Activation {
    /// Rectified linear unit.
    ReLU,
    /// Logistic sigmoid.
    Sigmoid,
    /// Hyperbolic tangent.
    Tanh,
    /// No activation.
    Linear,
    /// Softmax over the output vector.
    Softmax,
}
impl Activation {
    #[allow(clippy::should_implement_trait)]
    /// Parse a lowercase activation name; unknown strings map to `Linear`.
    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "relu" => Self::ReLU,
            "sigmoid" => Self::Sigmoid,
            "tanh" => Self::Tanh,
            "softmax" => Self::Softmax,
            _ => Self::Linear,
        }
    }
    /// Return the canonical activation name.
    pub fn as_str(self) -> &'static str {
        match self {
            Self::ReLU => "relu",
            Self::Sigmoid => "sigmoid",
            Self::Tanh => "tanh",
            Self::Linear => "linear",
            Self::Softmax => "softmax",
        }
    }
    /// Apply the activation in place to `v`.
    pub fn apply(self, v: &mut [f32]) {
        match self {
            Self::ReLU => {
                for x in v.iter_mut() {
                    if *x < 0.0 {
                        *x = 0.0;
                    }
                }
            }
            Self::Sigmoid => {
                for x in v.iter_mut() {
                    *x = 1.0 / (1.0 + (-*x).exp());
                }
            }
            Self::Tanh => {
                for x in v.iter_mut() {
                    *x = x.tanh();
                }
            }
            Self::Linear => {}
            Self::Softmax => {
                let max = v.iter().cloned().fold(f32::NEG_INFINITY, f32::max);
                let sum: f32 = v.iter().map(|&x| (x - max).exp()).sum();
                for x in v.iter_mut() {
                    *x = (*x - max).exp() / sum;
                }
            }
        }
    }
}
/// Dense layer with row-major weights and per-output biases.
pub struct NeuralLayer {
    /// Number of input units.
    pub inputs: usize,
    /// Number of output units.
    pub outputs: usize,
    /// Weight matrix stored row-major by output.
    pub weights: Vec<f32>,
    /// Bias per output unit.
    pub biases: Vec<f32>,
    /// Layer activation.
    pub activation: Activation,
}
impl NeuralLayer {
    /// Create a zeroed dense layer.
    pub fn new(inputs: usize, outputs: usize, activation: Activation) -> Self {
        Self {
            inputs,
            outputs,
            weights: vec![0.0; inputs * outputs],
            biases: vec![0.0; outputs],
            activation,
        }
    }
    /// Return the number of learnable parameters in the layer.
    pub fn param_count(&self) -> usize {
        self.inputs * self.outputs + self.outputs
    }
    #[allow(clippy::needless_range_loop)]
    /// Compute the layer output for `input`.
    pub fn forward(&self, input: &[f32]) -> Vec<f32> {
        let mut out = vec![0.0f32; self.outputs];
        for o in 0..self.outputs {
            let mut sum = self.biases[o];
            for i in 0..self.inputs {
                sum += self.weights[o * self.inputs + i] * input[i];
            }
            out[o] = sum;
        }
        self.activation.apply(&mut out);
        out
    }
}
/// Ordered stack of dense layers.
#[derive(Default)]
pub struct NeuralNet {
    /// Layer list from input to output.
    layers: Vec<NeuralLayer>,
}
impl NeuralNet {
    /// Create an empty neural net.
    pub fn new() -> Self {
        Self::default()
    }
    /// Append a new dense layer.
    pub fn add_layer(&mut self, inputs: usize, outputs: usize, activation: Activation) {
        self.layers
            .push(NeuralLayer::new(inputs, outputs, activation));
    }
    /// Return the total number of learnable parameters.
    pub fn param_count(&self) -> usize {
        self.layers.iter().map(|l| l.param_count()).sum()
    }
    /// Run a forward pass through all layers.
    pub fn forward(&self, input: &[f32]) -> Vec<f32> {
        let mut buf: Vec<f32> = input.to_vec();
        for layer in &self.layers {
            buf = layer.forward(&buf);
        }
        buf
    }
    /// Load flattened weights and biases; returns `false` when the shape mismatches.
    pub fn set_weights(&mut self, weights: &[f32]) -> bool {
        if weights.len() != self.param_count() {
            return false;
        }
        let mut offset = 0;
        for layer in &mut self.layers {
            let w_count = layer.inputs * layer.outputs;
            layer
                .weights
                .copy_from_slice(&weights[offset..offset + w_count]);
            offset += w_count;
            layer
                .biases
                .copy_from_slice(&weights[offset..offset + layer.outputs]);
            offset += layer.outputs;
        }
        true
    }
    /// Return the flattened weights and biases.
    pub fn get_weights(&self) -> Vec<f32> {
        let mut out = Vec::with_capacity(self.param_count());
        for layer in &self.layers {
            out.extend_from_slice(&layer.weights);
            out.extend_from_slice(&layer.biases);
        }
        out
    }
    /// Return the number of layers.
    pub fn layer_count(&self) -> usize {
        self.layers.len()
    }
}
