//! Scope: feedforward neural network inference and weight serialization helpers.
//! This file defines activation functions, dense layers, network stacks, and deterministic forward-pass routines.
//! It owns lightweight runtime inference utilities used by AI features without training-time dependencies.

// ---- Type: Activation ----

/// Element-wise activation function applied at the output of a neural layer.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Activation {
    /// `max(0, x)` - standard rectified linear unit.
    ReLU,
    /// `1 / (1 + e^(-x))` - squashes to `(0, 1)`.
    Sigmoid,
    /// `tanh(x)` - squashes to `(-1, 1)`.
    Tanh,
    /// Identity - no activation.
    Linear,
    /// Normalised exponentials - useful for the output layer of categorical policies.
    Softmax,
}

impl Activation {
    /// Parses a string into an `Activation`. Case-insensitive.
    #[allow(clippy::should_implement_trait)]
    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "relu" => Self::ReLU,
            "sigmoid" => Self::Sigmoid,
            "tanh" => Self::Tanh,
            "softmax" => Self::Softmax,
            _ => Self::Linear,
        }
    }

    /// Returns the canonical lowercase string name.
    pub fn as_str(self) -> &'static str {
        match self {
            Self::ReLU => "relu",
            Self::Sigmoid => "sigmoid",
            Self::Tanh => "tanh",
            Self::Linear => "linear",
            Self::Softmax => "softmax",
        }
    }

    /// Applies the activation in-place to a mutable slice.
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

// ---- Type: NeuralLayer ----

/// A single fully-connected layer in a neural network.
pub struct NeuralLayer {
    /// Number of inputs to this layer.
    pub inputs: usize,
    /// Number of outputs (neurons) in this layer.
    pub outputs: usize,
    /// Weight matrix: `[outputs - inputs]` row-major.
    pub weights: Vec<f32>,
    /// Bias vector: one per output neuron.
    pub biases: Vec<f32>,
    /// Activation function applied after the linear transform.
    pub activation: Activation,
}

// ---- Implementation: NeuralLayer ----

impl NeuralLayer {
    /// Creates a new zeroed layer.
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
    pub fn param_count(&self) -> usize {
        self.inputs * self.outputs + self.outputs
    }

    /// Performs the forward pass: `output = activation(W * input + b)`.
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

// ---- Type: NeuralNet ----

/// Feedforward neural network stack.
#[derive(Default)]
pub struct NeuralNet {
    layers: Vec<NeuralLayer>,
}

impl NeuralNet {
    /// Creates a new empty neural network.
    pub fn new() -> Self {
        Self::default()
    }

    /// Appends a fully-connected layer to the network.
    pub fn add_layer(&mut self, inputs: usize, outputs: usize, activation: Activation) {
        self.layers
            .push(NeuralLayer::new(inputs, outputs, activation));
    }

    /// Returns the total number of trainable parameters across all layers.
    pub fn param_count(&self) -> usize {
        self.layers.iter().map(|l| l.param_count()).sum()
    }

    /// Runs the forward pass and returns output activations.
    pub fn forward(&self, input: &[f32]) -> Vec<f32> {
        let mut buf: Vec<f32> = input.to_vec();
        for layer in &self.layers {
            buf = layer.forward(&buf);
        }
        buf
    }

    /// Copies all weights from a flat slice into the networ's layers.
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

    /// Flattens all layer weights and biases into a single `Vec<f32>`.
    pub fn get_weights(&self) -> Vec<f32> {
        let mut out = Vec::with_capacity(self.param_count());
        for layer in &self.layers {
            out.extend_from_slice(&layer.weights);
            out.extend_from_slice(&layer.biases);
        }
        out
    }

    /// Returns the number of layers.
    pub fn layer_count(&self) -> usize {
        self.layers.len()
    }
}

