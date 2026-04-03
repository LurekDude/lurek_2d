//! Multi-axis utility scorer that chooses the action with highest composite score.
//!
//! Utility AI evaluates a set of candidate actions by scoring each one across
//! multiple axes ("considerations"). Each consideration queries a game state
//! value via a Lua callback, maps it through a response curve, and multiplies
//! by a weight. The scores for all considerations are multiplied together to
//! produce a composite score for the action.
//!
//! ## Response Curves
//!
//! Raw input values from Lua callbacks are transformed through [`ResponseCurve`]
//! functions before weighting. Five curve shapes are available:
//!
//! - **Linear** — `p1 × input + p2`
//! - **Quadratic** — `p1 × input² + p2 × input + p3`
//! - **Logistic** — `1 / (1 + e^(-p1 × (input - p2)))` (S-curve)
//! - **Logit** — `ln(input/(1−input)) × p1 + p2` (inverse sigmoid)
//! - **Step** — `p2 if input ≥ p1, else p3` (hard threshold)
//!
//! ## Momentum
//!
//! Each action can have a `momentum_bonus` that is added when that action was
//! chosen in the previous evaluation. This prevents rapid flip-flopping between
//! equally scored actions (action inertia).
//!
//! ## Evaluation
//!
//! The AIWorld evaluates the UtilityAI for agents with the appropriate decision
//! model. `last_action` and `last_scores` are cached for debugging/inspection.

use mlua::RegistryKey;

/// Mathematical function shapes for transforming raw consideration inputs
/// into normalized scores.
///
/// Response curves allow designers to control how sensitive an action is to
/// changes in a game variable. For example, a logistic curve for health makes
/// the agent barely react to damage until health drops below a threshold,
/// then react sharply.
///
/// # Variants
/// - `Linear` — Linear variant.
/// - `Quadratic` — Quadratic variant.
/// - `Logistic` — Logistic variant.
/// - `Logit` — Logit variant.
/// - `Step` — Step variant.
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
}

impl ResponseCurve {
    /// Parses from Lua string. Returns an error if the source data is malformed or missing.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    pub fn parse_str(s: &str) -> Self {
        match s {
            "quadratic" => Self::Quadratic,
            "logistic" => Self::Logistic,
            "logit" => Self::Logit,
            "step" => Self::Step,
            _ => Self::Linear,
        }
    }

    /// Transforms a raw input value through this response curve using the
    /// given parameters. The interpretation of `p1`, `p2`, and `p3` varies
    /// by curve type (see variant docs).
    ///
    /// Input is not clamped before transformation except for Logit, which
    /// clamps to `[0.001, 0.999]` to avoid division by zero.
    ///
    /// # Parameters
    /// - `input` — `f64`.
    /// - `p1` — `f64`.
    /// - `p2` — `f64`.
    /// - `p3` — `f64`.
    ///
    /// # Returns
    /// `f64`.
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
        }
    }
}

/// A single evaluation axis within a utility action's scoring function.
///
/// Each consideration queries a game-state value via its Lua `callback`,
/// transforms the result through a [`ResponseCurve`], multiplies by `weight`,
/// and contributes to the action's composite score. Multiple considerations
/// are multiplied together (not summed), so a zero on any axis zeros the
/// entire action — useful for hard prerequisites.
///
/// # Fields
/// - `name` — `String`.
/// - `callback` — `RegistryKey`.
/// - `curve` — `ResponseCurve`.
/// - `p1` — `f64`.
/// - `p2` — `f64`.
/// - `p3` — `f64`.
/// - `weight` — `f64`.
pub struct Consideration {
    /// Name for debugging.
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
    /// Weight multiplier.
    pub weight: f64,
}

/// A candidate action in the utility AI decision space.
///
/// Each action has a name (returned to the game when chosen), an optional
/// simple scorer callback, and zero or more multi-axis [`Consideration`]s.
/// The `momentum_bonus` is added to the composite score when this action
/// was chosen in the previous evaluation, providing action inertia.
///
/// # Fields
/// - `name` — `String`.
/// - `scorer` — `RegistryKey`.
/// - `considerations` — `Vec<Consideration>`.
/// - `momentum_bonus` — `f64`.
pub struct UAAction {
    /// Action name.
    pub name: String,
    /// Lua scorer callback (optional, for simple single-score actions).
    pub scorer: RegistryKey,
    /// Multi-axis considerations.
    pub considerations: Vec<Consideration>,
    /// Bonus added when this action was chosen last (inertia/momentum).
    pub momentum_bonus: f64,
}

/// Multi-axis utility scorer that evaluates candidate actions and chooses
/// the one with the highest composite score.
///
/// The scorer holds a list of [`UAAction`]s, evaluates each one's considerations,
/// applies momentum bonuses, and records the winning action index and all scores
/// for later inspection. The AIWorld calls `evaluate()` during the agent update
/// loop for agents whose decision model includes utility AI.
///
/// # Fields
/// - `actions` — `Vec<UAAction>`.
/// - `last_action` — `Option<usize>`.
/// - `last_scores` — `Vec<f64>`.
pub struct UtilityAI {
    /// Available actions to evaluate.
    pub actions: Vec<UAAction>,
    /// Index of the action chosen by the last `evaluate()`.
    pub last_action: Option<usize>,
    /// Score array from the last `evaluate()`, one per action.
    pub last_scores: Vec<f64>,
}

impl UtilityAI {
    /// Creates a new empty UtilityAI. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            actions: Vec::new(),
            last_action: None,
            last_scores: Vec::new(),
        }
    }
}

impl Default for UtilityAI {
    fn default() -> Self {
        Self::new()
    }
}
