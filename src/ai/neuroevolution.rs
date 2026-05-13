//! neuroevolution helpers that evolve neural-network parameter vectors.
use crate::ai::{genetic::GeneticAlgorithm, neural_net::NeuralNet};

// ---- Type: Neuroevolution ----

/// Neuroevolution trainer: evolves a population of neural network weight vectors.
pub struct Neuroevolution {
    /// Underlying genetic algorithm.
    pub ga: GeneticAlgorithm,
    /// Layer specifications: `(inputs, outputs, activation_name)`.
    template_layer_spec: Vec<(usize, usize, String)>,
    /// Number of completed generation evolutions.
    pub generation: usize,
}

// ---- Implementation: Neuroevolution ----

impl Neuroevolution {
    /// Create a new neuroevolution trainer for the given network topology.
    pub fn new(layer_spec: Vec<(usize, usize, &str)>, pop_size: usize, seed: u64) -> Self {
        let gene_count = Self::total_params(&layer_spec);
        let ga = GeneticAlgorithm::new(pop_size, gene_count, seed);
        Self {
            ga,
            template_layer_spec: layer_spec
                .into_iter()
                .map(|(i, o, a)| (i, o, a.to_string()))
                .collect(),
            generation: 0,
        }
    }

    /// Return the total parameter count implied by the given layer spec.
    fn total_params(spec: &[(usize, usize, &str)]) -> usize {
        spec.iter().map(|(i, o, _)| i * o + o).sum()
    }

    /// Return the population size.
    pub fn pop_size(&self) -> usize {
        self.ga.pop_size()
    }

    /// Builds a `NeuralNet` from the weight chromosome at index `i`.
    pub fn chromosome_to_net(&self, i: usize) -> Option<NeuralNet> {
        let c = self.ga.population.get(i)?;
        let mut net = self.build_empty_net();
        net.set_weights(&c.genes);
        Some(net)
    }

    /// Set the fitness for chromosome at index `i`.
    pub fn set_fitness(&mut self, i: usize, fitness: f32) {
        if let Some(c) = self.ga.population.get_mut(i) {
            c.fitness = fitness;
        }
    }

    /// Advances one generation using the GA.
    pub fn evolve(&mut self) {
        self.ga.evolve();
        self.generation += 1;
    }

    /// Return a `NeuralNet` loaded with the weights of the best chromosome.
    pub fn best_network(&self) -> Option<NeuralNet> {
        let best = self.ga.best()?;
        let mut net = self.build_empty_net();
        net.set_weights(&best.genes);
        Some(net)
    }

    /// Return the fitness of the best chromosome.
    pub fn best_fitness(&self) -> f32 {
        self.ga.best().map(|c| c.fitness).unwrap_or(0.0)
    }

    /// Return a reference to the raw population chromosomes.
    pub fn population(&self) -> &[crate::ai::genetic::Chromosome] {
        &self.ga.population
    }

    // ---- Internal Helpers ----

    /// Builds an empty (zeroed weights) net matching the stored topology.
    fn build_empty_net(&self) -> NeuralNet {
        let mut net = NeuralNet::new();
        for (inputs, outputs, act_str) in &self.template_layer_spec {
            let act = crate::ai::neural_net::Activation::from_str(act_str);
            net.add_layer(*inputs, *outputs, act);
        }
        net
    }
}

