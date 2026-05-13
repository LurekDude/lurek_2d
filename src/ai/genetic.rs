//! genetic algorithm utilities for parameter and policy optimization.

// ---- Type: Chromosome ----

/// A candidate solution in a genetic algorithm population.
#[derive(Clone)]
pub struct Chromosome {
    /// The flat gene vector (e.g. neural network weights).
    pub genes: Vec<f32>,
    /// Fitness score computed by the calle's evaluation function.
    pub fitness: f32,
    /// Per-population unique ID assigned at construction.
    pub id: u64,
}

// ---- Implementation: Chromosome ----

impl Chromosome {
    /// Create a zeroed chromosome.
    pub fn new(gene_count: usize, id: u64) -> Self {
        Self {
            genes: vec![0.0; gene_count],
            fitness: 0.0,
            id,
        }
    }
}

// ---- Type: GeneticAlgorithm ----

/// Simple generational genetic algorithm.
pub struct GeneticAlgorithm {
    /// Current population ordered by arbitrary index.
    pub population: Vec<Chromosome>,
    /// Number of genes per chromosome.
    pub gene_count: usize,
    /// Probability of mutating any single gene.
    pub mutation_rate: f32,
    /// Standard deviation of Gaussian mutation noise.
    pub mutation_std: f32,
    /// Number of candidates in each tournament selection round.
    pub tournament_size: usize,
    /// Number of best chromosomes copied unchanged to the next generation.
    pub elitism: usize,
    /// Count of completed generations.
    pub generation: usize,
    next_id: u64,
    rng: u64,
}

// ---- Implementation: GeneticAlgorithm ----

impl GeneticAlgorithm {
    /// Create a new GA with a random initial population.
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

    /// Return the population size.
    pub fn pop_size(&self) -> usize {
        self.population.len()
    }

    /// Return a reference to the chromosome with highest fitness.
    pub fn best(&self) -> Option<&Chromosome> {
        self.population
            .iter()
            .max_by(|a, b| a.fitness.partial_cmp(&b.fitness).unwrap())
    }

    /// Runs one generation: tournament selection, crossover, mutation, elitism.
    pub fn evolve(&mut self) {
        let pop_size = self.population.len();
        let mut next_gen: Vec<Chromosome> = Vec::with_capacity(pop_size);

        // Elitism: carry over best unchanged
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

        // Fill rest with crossover + mutation offspring
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

    // ---- Helper Functions: Tournament, Crossover, Mutation ----

    /// Return index of winning chromosome in a tournament of `tournament_size`.
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

    /// Uniform crossover: each gene drawn randomly from one of the two parents.
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

    /// Gaussian mutation: each gene mutated independently with `mutation_rate` probability.
    fn mutate(&mut self, c: &mut Chromosome) {
        for g in &mut c.genes {
            if self.rand_f01() < self.mutation_rate {
                *g += self.randn() * self.mutation_std;
            }
        }
    }

    /// Xorshift64 -> `[0, n)`
    fn rand_usize(&mut self, n: usize) -> usize {
        self.rng = xorshift64(self.rng);
        (self.rng as usize) % n
    }

    /// Xorshift64 -> `[0, 1)`
    fn rand_f01(&mut self) -> f32 {
        self.rng = xorshift64(self.rng);
        (self.rng >> 11) as f32 * (1.0 / (1u64 << 53) as f32)
    }

    /// Box-Muller transform for Gaussian noise (mean=0, std=1).
    fn randn(&mut self) -> f32 {
        let u1 = self.rand_f01().max(1e-7);
        let u2 = self.rand_f01();
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f32::consts::PI * u2).cos()
    }

    /// Return `true` ~50% of the time.
    fn rand_bool(&mut self) -> bool {
        self.rng = xorshift64(self.rng);
        self.rng & 1 == 0
    }
}

/// Xorshift64 PRNG step.
fn xorshift64(mut x: u64) -> u64 {
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    x
}

