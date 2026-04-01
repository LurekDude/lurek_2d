//! Multi-axis utility scorer that chooses the action with highest composite score.

use mlua::RegistryKey;

/// Response curve shapes for consideration scoring.
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
    /// Parses from Lua string.
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

    /// Applies the response curve to a raw input value.
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

/// A single axis of evaluation within a UtilityAI action.
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

/// One scored option in a UtilityAI decision space.
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

/// Multi-axis utility scorer; chooses the action with highest composite score.
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
    /// Creates a new empty UtilityAI.
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
