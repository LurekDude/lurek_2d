//! Minimal feedforward neural network for AI inference.
//!
//! Provides a compact, alloc-friendly feedforward neural network intended for
//! AI inference only (not gradient-based training). Networks are created
//! programmatically or loaded from a weight list, then called with `forward`.
//!
//! Training is offline: use [`crate::ai::neuroevolution::Neuroevolution`] to evolve
//! weights, then load the best chromosome into a `NeuralNet` via `set_weights`.
//!
//! ## Architecture
//!
//! - [`Activation`] — element-wise activation function for a layer.
//! - [`NeuralLayer`] — one fully-connected layer (weights + biases + activation).
//! - [`NeuralNet`] — stack of `NeuralLayer`s. `forward` runs the forward pass.
//!
//! ## Typical Usage Sequence
//!
//! 1. Build a `NeuralNet` with `NeuralNet::new()` and `add_layer(inputs, outputs, activation)`.
//! 2. Optionally call `set_weights(flat_vec)` to load trained weights.
//! 3. Call `forward(inputs)` each frame to get output activations.
//! 4. Map outputs to action logits, scores, or control signals.

// ────────────────────────────────────────────────────────────────────────────
// Activation
// ────────────────────────────────────────────────────────────────────────────

/// Element-wise activation function applied at the output of a neural layer.
///
/// # Variants
/// - `ReLU` — ReLU variant.
/// - `Sigmoid` — Sigmoid variant.
/// - `Tanh` — Tanh variant.
/// - `Linear` — Linear variant.
/// - `Softmax` — Softmax variant.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Activation {
    /// `max(0, x)` — standard rectified linear unit.
    ReLU,
    /// `1 / (1 + e^(-x))` — squashes to `(0, 1)`.
    Sigmoid,
    /// `tanh(x)` — squashes to `(-1, 1)`.
    Tanh,
    /// Identity — no activation.
    Linear,
    /// Normalised exponentials — useful for the output layer of categorical policies.
    Softmax,
}

impl Activation {
    /// Parses a string into an `Activation`. Case-insensitive.
    /// Unknown strings return `Linear`.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    #[allow(clippy::should_implement_trait)]
    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "relu"    => Self::ReLU,
            "sigmoid" => Self::Sigmoid,
            "tanh"    => Self::Tanh,
            "softmax" => Self::Softmax,
            _         => Self::Linear,
        }
    }

    /// Returns the canonical lowercase string name.
    ///
    /// # Returns
    /// `&str`.
    pub fn as_str(self) -> &'static str {
        match self {
            Self::ReLU    => "relu",
            Self::Sigmoid => "sigmoid",
            Self::Tanh    => "tanh",
            Self::Linear  => "linear",
            Self::Softmax => "softmax",
        }
    }

    /// Applies the activation in-place to a mutable slice.
    ///
    /// # Parameters
    /// - `v` — `&mut [f32]`.
    pub fn apply(self, v: &mut [f32]) {
        match self {
            Self::ReLU    => { for x in v.iter_mut() { if *x < 0.0 { *x = 0.0; } } }
            Self::Sigmoid => { for x in v.iter_mut() { *x = 1.0 / (1.0 + (-*x).exp()); } }
            Self::Tanh    => { for x in v.iter_mut() { *x = x.tanh(); } }
            Self::Linear  => {}
            Self::Softmax => {
                let max = v.iter().cloned().fold(f32::NEG_INFINITY, f32::max);
                let sum: f32 = v.iter().map(|&x| (x - max).exp()).sum();
                for x in v.iter_mut() { *x = (*x - max).exp() / sum; }
            }
        }
    }
}

// ────────────────────────────────────────────────────────────────────────────
// NeuralLayer
// ────────────────────────────────────────────────────────────────────────────

/// A single fully-connected layer in a neural network.
///
/// Weights are stored in row-major order: `weights[output * inputs + input]`.
///
/// # Fields
/// - `inputs` — `usize`.
/// - `outputs` — `usize`.
/// - `weights` — `Vec<f32>`.
/// - `biases` — `Vec<f32>`.
/// - `activation` — `Activation`.
pub struct NeuralLayer {
    /// Number of inputs to this layer.
    pub inputs: usize,
    /// Number of outputs (neurons) in this layer.
    pub outputs: usize,
    /// Weight matrix: `[outputs × inputs]` row-major.
    pub weights: Vec<f32>,
    /// Bias vector: one per output neuron.
    pub biases: Vec<f32>,
    /// Activation function applied after the linear transform.
    pub activation: Activation,
}

impl NeuralLayer {
    /// Creates a new zeroed layer.
    ///
    /// # Parameters
    /// - `inputs` — `usize`.
    /// - `outputs` — `usize`.
    /// - `activation` — `Activation`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(inputs: usize, outputs: usize, activation: Activation) -> Self {
        Self {
            inputs,
            outputs,
            weights: vec![0.0; inputs * outputs],
            biases: vec![0.0; outputs],
            activation,
        }
    }

    /// Returns the total number of weight parameters (weights + biases).
    ///
    /// # Returns
    /// `usize`.
    pub fn param_count(&self) -> usize {
        self.inputs * self.outputs + self.outputs
    }

    /// Performs the forward pass: `output = activation(W * input + b)`.
    ///
    /// # Parameters
    /// - `input` — `&[f32]`.
    ///
    /// # Returns
    /// `Vec<f32>`.
    #[allow(clippy::needless_range_loop)]
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

// ────────────────────────────────────────────────────────────────────────────
// NeuralNet
// ────────────────────────────────────────────────────────────────────────────

/// Feedforward neural network stack.
///
/// Layers are added sequentially; `forward` propagates input through them all.
/// Weights across all layers are flattened to a single `f32` vector for use
/// with evolutionary algorithms.
///
/// # Fields
/// - `layers` — `Vec<NeuralLayer>`.
#[derive(Default)]
pub struct NeuralNet {
    layers: Vec<NeuralLayer>,
}

impl NeuralNet {
    /// Creates a new empty neural network.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self::default()
    }

    /// Appends a fully-connected layer to the network.
    ///
    /// # Parameters
    /// - `inputs` — `usize`.
    /// - `outputs` — `usize`.
    /// - `activation` — `Activation`.
    pub fn add_layer(&mut self, inputs: usize, outputs: usize, activation: Activation) {
        self.layers.push(NeuralLayer::new(inputs, outputs, activation));
    }

    /// Returns the total number of trainable parameters across all layers.
    ///
    /// # Returns
    /// `usize`.
    pub fn param_count(&self) -> usize {
        self.layers.iter().map(|l| l.param_count()).sum()
    }

    /// Runs the forward pass and returns output activations.
    ///
    /// # Parameters
    /// - `input` — `&[f32]`.
    ///
    /// # Returns
    /// `Vec<f32>`.
    pub fn forward(&self, input: &[f32]) -> Vec<f32> {
        let mut buf: Vec<f32> = input.to_vec();
        for layer in &self.layers {
            buf = layer.forward(&buf);
        }
        buf
    }

    /// Copies all weights from a flat slice into the network's layers.
    ///
    /// The slice must have exactly `param_count()` elements. Parameters are
    /// assigned in layer order: weights first, then biases for each layer.
    ///
    /// # Parameters
    /// - `weights` — `&[f32]`.
    ///
    /// # Returns
    /// `bool`.
    pub fn set_weights(&mut self, weights: &[f32]) -> bool {
        if weights.len() != self.param_count() { return false; }
        let mut offset = 0;
        for layer in &mut self.layers {
            let w_count = layer.inputs * layer.outputs;
            layer.weights.copy_from_slice(&weights[offset..offset + w_count]);
            offset += w_count;
            layer.biases.copy_from_slice(&weights[offset..offset + layer.outputs]);
            offset += layer.outputs;
        }
        true
    }

    /// Flattens all layer weights and biases into a single `Vec<f32>`.
    ///
    /// # Returns
    /// `Vec<f32>`.
    pub fn get_weights(&self) -> Vec<f32> {
        let mut out = Vec::with_capacity(self.param_count());
        for layer in &self.layers {
            out.extend_from_slice(&layer.weights);
            out.extend_from_slice(&layer.biases);
        }
        out
    }

    /// Returns the number of layers.
    ///
    /// # Returns
    /// `usize`.
    pub fn layer_count(&self) -> usize {
        self.layers.len()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_net(shape: &[(usize, usize)]) -> NeuralNet {
        let mut nn = NeuralNet::new();
        for &(inputs, outputs) in shape {
            nn.add_layer(inputs, outputs, Activation::Sigmoid);
        }
        nn
    }

    #[test]
    fn single_layer_forward() {
        let nn = make_net(&[(2, 1)]);
        let out = nn.forward(&[1.0, 1.0]);
        assert_eq!(out.len(), 1);
    }

    #[test]
    fn two_layer_forward() {
        let nn = make_net(&[(3, 4), (4, 2)]);
        let out = nn.forward(&[1.0, 0.5, -0.3]);
        assert_eq!(out.len(), 2);
    }

    #[test]
    fn set_weights_round_trip() {
        let mut nn = make_net(&[(2, 2)]);
        let flat = nn.get_weights();
        nn.set_weights(&flat);
        let flat2 = nn.get_weights();
        assert_eq!(flat, flat2);
    }

    #[test]
    fn layer_count_matches() {
        let nn = make_net(&[(3, 5), (5, 2)]);
        assert_eq!(nn.layer_count(), 2);
    }

    #[test]
    fn output_bounded_by_activation() {
        let nn = make_net(&[(2, 3)]);
        let out = nn.forward(&[100.0, -100.0]);
        for v in &out {
            assert!(*v >= 0.0 && *v <= 1.0, "sigmoid should bound output");
        }
    }
}
