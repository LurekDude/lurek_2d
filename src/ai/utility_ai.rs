//! Scope: utility-AI scoring with response curves and action ranking.
//! This file defines curves, considerations, action records, and evaluation flow that selects the highest score.
//! It owns deterministic per-frame score caching and last-action memory for decision continuity.
use mlua::prelude::*;
use mlua::RegistryKey;

/// Mathematical function shapes for transforming raw consideration inputs into normalized scores in `[0.0, 1.0]`.
#[derive(Debug, Clone, PartialEq)]
pub enum ResponseCurve {
    /// Linear: output = p1 * input + p2.
    Linear,
    /// Quadratic: output = p1 * input^2 + p2 * input + p3.
    Quadratic,
    /// Logistic: output = 1 / (1 + e^(-p1 * (input - p2))).
    Logistic,
    /// Logit: output = ln(input / (1 - input)) * p1 + p2.
    Logit,
    /// Step: output = p2 if input >= p1, else p3.
    Step,
    /// A user-defined Lua function maps `f64 -> f64` for this axis.
    Custom {
        /// Opaque ID referencing the Lua curve callback in the API-layer registry.
        callback_id: u32,
    },
}

impl ResponseCurve {
    /// Parses from Lua string. Returns an error if the source data is malformed or missing.
    pub fn parse_str(s: &str) -> Self {
        match s {
            "quadratic" => Self::Quadratic,
            "logistic" => Self::Logistic,
            "logit" => Self::Logit,
            "step" => Self::Step,
            _ => Self::Linear,
        }
    }

    /// Transforms a raw input value through this response curve using the provided parameters `p1`, `p2`, `p3`.
    pub fn apply(&self, input: f64, p1: f64, p2: f64, p3: f64) -> f64 {
        match self {
            Self::Linear => p1 * input + p2,
            Self::Quadratic => p1 * input * input + p2 * input + p3,
            Self::Logistic => 1.0 / (1.0 + (-p1 * (input - p2)).exp()),
            Self::Logit => {
                let clamped = input.clamp(0.001, 0.999);
                (clamped / (1.0 - clamped)).ln() * p1 + p2
            }
            Self::Step => {
                if input >= p1 {
                    p2
                } else {
                    p3
                }
            }
            // Invoked by LuaUtilityAI; domain code returns identity for Custom.
            Self::Custom { .. } => input,
        }
    }
}

/// A single evaluation axis within a utility action's scoring function.
pub struct Consideration {
    /// Human-readable label for this consideration axis. Used in debug output and score inspection.
    pub name: String,
    /// Lua callback that returns a raw f64 score.
    pub callback: RegistryKey,
    /// Response curve to apply to the raw score.
    pub curve: ResponseCurve,
    /// Curve parameter 1.
    pub p1: f64,
    /// Curve parameter 2.
    pub p2: f64,
    /// Curve parameter 3.
    pub p3: f64,
    /// Weight multiplier applied to this consideration's score before the axis product is computed.
    pub weight: f64,
}

/// A candidate action in the utility AI decision space.
pub struct UAAction {
    /// Unique action name returned by `evaluate()` when this action wins.
    pub name: String,
    /// Lua scorer callback (optional, for simple single-score actions).
    pub scorer: RegistryKey,
    /// Multi-axis considerations.
    pub considerations: Vec<Consideration>,
    /// Bonus added when this action was chosen last (inertia/momentum).
    pub momentum_bonus: f64,
}

/// Multi-axis utility scorer that evaluates candidate actions and chooses the highest-scoring one each frame.
pub struct UtilityAI {
    /// Available actions to evaluate.
    pub actions: Vec<UAAction>,
    /// Index of the action chosen by the last `evaluate()`.
    pub last_action: Option<usize>,
    /// Score array from the last `evaluate()`, one per action.
    pub last_scores: Vec<f64>,
}

impl UtilityAI {
    /// Creates a new empty UtilityAI scorer.
    pub fn new() -> Self {
        Self {
            actions: Vec::new(),
            last_action: None,
            last_scores: Vec::new(),
        }
    }

    /// Adds an action with the given scorer callback and momentum bonus. Used by the Lua API.
    pub fn add_action(&mut self, name: String, scorer: RegistryKey, momentum_bonus: f64) {
        self.actions.push(UAAction {
            name,
            scorer,
            considerations: Vec::new(),
            momentum_bonus,
        });
    }

    /// Adds a consideration to the named action. No-op if action not found. Used by the Lua API.
    #[allow(clippy::too_many_arguments)]
    pub fn add_consideration(
        &mut self,
        action_name: &str,
        name: String,
        callback: RegistryKey,
        curve: &str,
        p1: f64,
        p2: f64,
        p3: f64,
        weight: f64,
    ) {
        if let Some(a) = self.actions.iter_mut().find(|a| a.name == action_name) {
            a.considerations.push(Consideration {
                name,
                callback,
                curve: ResponseCurve::parse_str(curve),
                p1,
                p2,
                p3,
                weight,
            });
        }
    }

    /// Returns the name of the last chosen action, or `None` if no evaluation has occurred.
    pub fn last_action_name(&self) -> Option<&str> {
        self.last_action
            .and_then(|i| self.actions.get(i))
            .map(|a| a.name.as_str())
    }
    /// Evaluates all actions using Lua scorer callbacks and returns the best action name.
    pub fn evaluate(&mut self, lua: &Lua) -> LuaResult<Option<String>> {
        if self.actions.is_empty() {
            return Ok(None);
        }
        let mut best_idx = 0;
        let mut best_score = f64::NEG_INFINITY;
        let mut scores = Vec::with_capacity(self.actions.len());
        for (i, action) in self.actions.iter().enumerate() {
            let func: LuaFunction = lua.registry_value(&action.scorer)?;
            let score: f64 = func.call(())?;
            let weighted = score * action.momentum_bonus;
            scores.push(weighted);
            if weighted > best_score {
                best_score = weighted;
                best_idx = i;
            }
        }
        self.last_scores = scores;
        self.last_action = Some(best_idx);
        Ok(Some(self.actions[best_idx].name.clone()))
    }
}

impl Default for UtilityAI {
    fn default() -> Self {
        Self::new()
    }
}

