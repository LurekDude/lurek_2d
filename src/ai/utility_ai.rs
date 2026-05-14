use mlua::prelude::*;
use mlua::RegistryKey;
#[derive(Debug, Clone, PartialEq)]
pub enum ResponseCurve {
    /// Output = p1 * input + p2.
    Linear,
    /// Output = p1 * input² + p2 * input + p3.
    Quadratic,
    /// Sigmoid: 1 / (1 + exp(−p1 * (input − p2))).
    Logistic,
    /// Log-odds transform, clamped to avoid infinities.
    Logit,
    /// Returns p2 when input ≥ p1, otherwise p3.
    Step,
    /// Delegates to a Lua callback identified by `callback_id`.
    Custom {
        /// Registry index of the Lua curve callback.
        callback_id: u32,
    },
}
impl ResponseCurve {
    /// Parse a string tag into a `ResponseCurve`; unknown strings map to `Linear`.
    pub fn parse_str(s: &str) -> Self {
        match s {
            "quadratic" => Self::Quadratic,
            "logistic" => Self::Logistic,
            "logit" => Self::Logit,
            "step" => Self::Step,
            _ => Self::Linear,
        }
    }
    /// Evaluate the curve at `input` using shape parameters p1, p2, p3.
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
            Self::Custom { .. } => input,
        }
    }
}
pub struct Consideration {
    /// Unique name for this consideration, used for debug display.
    pub name: String,
    /// Lua callback that returns a raw input score in `[0, 1]`.
    pub callback: RegistryKey,
    /// Response curve that maps the raw input to a utility value.
    pub curve: ResponseCurve,
    /// First shape parameter for the response curve.
    pub p1: f64,
    /// Second shape parameter for the response curve.
    pub p2: f64,
    /// Third shape parameter for the response curve.
    pub p3: f64,
    /// Multiplicative weight applied to the curve output before product scoring.
    pub weight: f64,
}
pub struct UAAction {
    /// Unique name identifying this action.
    pub name: String,
    /// Lua scorer callback returning the overall action utility.
    pub scorer: RegistryKey,
    /// Ordered list of considerations whose outputs are multiplied together.
    pub considerations: Vec<Consideration>,
    /// Bonus multiplier added to the score when this action was selected last tick.
    pub momentum_bonus: f64,
}
pub struct UtilityAI {
    /// All registered actions evaluated each tick.
    pub actions: Vec<UAAction>,
    /// Index of the action selected on the last `evaluate` call.
    pub last_action: Option<usize>,
    /// Per-action weighted scores from the last `evaluate` call.
    pub last_scores: Vec<f64>,
}
impl UtilityAI {
    /// Create a `UtilityAI` with no actions.
    pub fn new() -> Self {
        Self {
            actions: Vec::new(),
            last_action: None,
            last_scores: Vec::new(),
        }
    }
    /// Register a new action with an empty consideration list.
    pub fn add_action(&mut self, name: String, scorer: RegistryKey, momentum_bonus: f64) {
        self.actions.push(UAAction {
            name,
            scorer,
            considerations: Vec::new(),
            momentum_bonus,
        });
    }
    #[allow(clippy::too_many_arguments)]
    /// Append a consideration to the named action; no-op if the action is not found.
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
    /// Return the name of the action selected on the last `evaluate` call, or `None`.
    pub fn last_action_name(&self) -> Option<&str> {
        self.last_action
            .and_then(|i| self.actions.get(i))
            .map(|a| a.name.as_str())
    }
    /// Call all action scorers, apply momentum, and return the best action name.
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
/// `Default` delegates to `UtilityAI::new`.
impl Default for UtilityAI {
    /// `Default` delegates to `UtilityAI::new`.
    fn default() -> Self {
        Self::new()
    }
}
