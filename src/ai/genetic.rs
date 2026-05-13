//! Genetic algorithm for evolving fixed-length float chromosomes.
//! Owns `Chromosome` and `GeneticAlgorithm` only.
//! Does not own fitness evaluation; callers assign fitness externally.
/// Evolving genome with fitness and stable id.
#[derive(Clone)]
pub struct Chromosome {
    /// Gene vector used by the genome.
    pub genes: Vec<f32>,
    /// Fitness assigned by the caller.
    pub fitness: f32,
    /// Stable identifier across generations.
    pub id: u64,
}
impl Chromosome {
    /// Create a zeroed chromosome with `gene_count` genes.
    pub fn new(gene_count: usize, id: u64) -> Self {
        Self {
            genes: vec![0.0; gene_count],
            fitness: 0.0,
            id,
        }
    }
}
/// Population-based genetic optimizer.
pub struct GeneticAlgorithm {
    /// Current population.
    pub population: Vec<Chromosome>,
    /// Gene count per chromosome.
    pub gene_count: usize,
    /// Per-gene mutation probability.
    pub mutation_rate: f32,
    /// Standard deviation used by Gaussian mutation.
    pub mutation_std: f32,
    /// Tournament size used for parent selection.
    pub tournament_size: usize,
    /// Number of elite chromosomes preserved each generation.
    pub elitism: usize,
    /// Current generation number.
    pub generation: usize,
    /// Next chromosome id.
    next_id: u64,
    /// Internal RNG state.
    rng: u64,
}
impl GeneticAlgorithm {
    /// Create a population with random initial genes.
    pub fn new(pop_size: usize, gene_count: usize, seed: u64) -> Self {
        let mut ga = Self {
            population: Vec::with_capacity(pop_size),
            gene_count,
            mutation_rate: 0.05,
            mutation_std: 0.1,
            tournament_size: 3,
            elitism: 1,
            generation: 0,
            next_id: 0,
            rng: seed,
        };
        for _ in 0..pop_size {
            let id = ga.next_id;
            ga.next_id += 1;
            let mut c = Chromosome::new(gene_count, id);
            for g in &mut c.genes {
                *g = ga.randn();
            }
            ga.population.push(c);
        }
        ga
    }
    /// Return the current population size.
    pub fn pop_size(&self) -> usize {
        self.population.len()
    }
    /// Return the chromosome with the highest fitness, or `None` if empty.
    pub fn best(&self) -> Option<&Chromosome> {
        self.population
            .iter()
            .max_by(|a, b| a.fitness.partial_cmp(&b.fitness).unwrap())
    }
    /// Build the next generation using elitism, tournament selection, crossover, and mutation.
    pub fn evolve(&mut self) {
        let pop_size = self.population.len();
        let mut next_gen: Vec<Chromosome> = Vec::with_capacity(pop_size);
        let mut sorted: Vec<usize> = (0..pop_size).collect();
        sorted.sort_by(|&a, &b| {
            self.population[b]
                .fitness
                .partial_cmp(&self.population[a].fitness)
                .unwrap()
        });
        for &i in sorted.iter().take(self.elitism) {
            next_gen.push(self.population[i].clone());
        }
        while next_gen.len() < pop_size {
            let p1 = self.tournament_select(pop_size);
            let p2 = self.tournament_select(pop_size);
            let mut child =
                self.crossover(&self.population[p1].clone(), &self.population[p2].clone());
            self.mutate(&mut child);
            child.id = self.next_id;
            self.next_id += 1;
            child.fitness = 0.0;
            next_gen.push(child);
        }
        self.population = next_gen;
        self.generation += 1;
    }
    /// Return one selected parent index using tournament selection.
    fn tournament_select(&mut self, pop_size: usize) -> usize {
        let mut best_idx = self.rand_usize(pop_size);
        for _ in 1..self.tournament_size {
            let idx = self.rand_usize(pop_size);
            if self.population[idx].fitness > self.population[best_idx].fitness {
                best_idx = idx;
            }
        }
        best_idx
    }
    /// Create a child chromosome by choosing each gene from one parent.
    fn crossover(&mut self, p1: &Chromosome, p2: &Chromosome) -> Chromosome {
        let mut child = Chromosome::new(self.gene_count, 0);
        for i in 0..self.gene_count {
            child.genes[i] = if self.rand_bool() {
                p1.genes[i]
            } else {
                p2.genes[i]
            };
        }
        child
    }
    /// Mutate a chromosome in place.
    fn mutate(&mut self, c: &mut Chromosome) {
        for g in &mut c.genes {
            if self.rand_f01() < self.mutation_rate {
                *g += self.randn() * self.mutation_std;
            }
        }
    }
    /// Sample a random index in `[0, n)`.
    fn rand_usize(&mut self, n: usize) -> usize {
        self.rng = xorshift64(self.rng);
        (self.rng as usize) % n
    }
    /// Sample a uniform float in `[0, 1)`.
    fn rand_f01(&mut self) -> f32 {
        self.rng = xorshift64(self.rng);
        (self.rng >> 11) as f32 * (1.0 / (1u64 << 53) as f32)
    }
    /// Sample a standard normal float with Box-Muller.
    fn randn(&mut self) -> f32 {
        let u1 = self.rand_f01().max(1e-7);
        let u2 = self.rand_f01();
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f32::consts::PI * u2).cos()
    }
    /// Sample a random boolean.
    fn rand_bool(&mut self) -> bool {
        self.rng = xorshift64(self.rng);
        self.rng & 1 == 0
    }
}
/// Xorshift64 RNG step used by the algorithm.
fn xorshift64(mut x: u64) -> u64 {
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    x
}
