use crate::ai::{genetic::GeneticAlgorithm, neural_net::NeuralNet};
/// GA-backed neural-network population manager.
pub struct Neuroevolution {
    /// Underlying genetic algorithm.
    pub ga: GeneticAlgorithm,
    /// Template layer specification used to build networks from chromosomes.
    template_layer_spec: Vec<(usize, usize, String)>,
    /// Current generation counter.
    pub generation: usize,
}
impl Neuroevolution {
    /// Create a population for the provided layer spec.
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
    /// Return the flattened parameter count for the template spec.
    fn total_params(spec: &[(usize, usize, &str)]) -> usize {
        spec.iter().map(|(i, o, _)| i * o + o).sum()
    }
    /// Return the population size.
    pub fn pop_size(&self) -> usize {
        self.ga.pop_size()
    }
    /// Build a neural net from chromosome `i`; returns `None` when the index is invalid.
    pub fn chromosome_to_net(&self, i: usize) -> Option<NeuralNet> {
        let c = self.ga.population.get(i)?;
        let mut net = self.build_empty_net();
        net.set_weights(&c.genes);
        Some(net)
    }
    /// Assign fitness to chromosome `i` when present.
    pub fn set_fitness(&mut self, i: usize, fitness: f32) {
        if let Some(c) = self.ga.population.get_mut(i) {
            c.fitness = fitness;
        }
    }
    /// Advance the underlying genetic algorithm and generation counter.
    pub fn evolve(&mut self) {
        self.ga.evolve();
        self.generation += 1;
    }
    /// Build the network for the best chromosome, or `None` if the population is empty.
    pub fn best_network(&self) -> Option<NeuralNet> {
        let best = self.ga.best()?;
        let mut net = self.build_empty_net();
        net.set_weights(&best.genes);
        Some(net)
    }
    /// Return the best fitness in the current population, or 0.0 if empty.
    pub fn best_fitness(&self) -> f32 {
        self.ga.best().map(|c| c.fitness).unwrap_or(0.0)
    }
    /// Return the current chromosome slice.
    pub fn population(&self) -> &[crate::ai::genetic::Chromosome] {
        &self.ga.population
    }
    /// Build a network with the template layers but zeroed parameters.
    fn build_empty_net(&self) -> NeuralNet {
        let mut net = NeuralNet::new();
        for (inputs, outputs, act_str) in &self.template_layer_spec {
            let act = crate::ai::neural_net::Activation::from_str(act_str);
            net.add_layer(*inputs, *outputs, act);
        }
        net
    }
}
