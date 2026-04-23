//! Finite-state machine for sprite animation: states, transitions, and parameter-driven switching.
//!
//! [`AnimStateMachine`] owns an [`Animation`] controller and drives clip selection based on
//! named parameters (`float`, `bool`, `int`) and simple comparison conditions.

use std::collections::HashMap;

use super::controller::Animation;

// ── Parameter value ──────────────────────────────────────────────────────────

/// Value held by an animation parameter.
///
/// # Variants
/// - `Bool` — `bool` flag.
/// - `Float` — `f32` continuous value.
/// - `Int` — `i32` integer value.
#[derive(Debug, Clone)]
pub enum AnimParamValue {
    /// Boolean flag parameter.
    Bool(bool),
    /// Continuous float parameter.
    Float(f32),
    /// Integer parameter.
    Int(i32),
}

// ── Condition types ──────────────────────────────────────────────────────────

/// Comparison operator for a transition condition.
///
/// # Variants
/// - `Gt`, `Lt`, `Gte`, `Lte`, `Eq`, `Neq` — comparison operators.
#[derive(Debug, Clone, PartialEq)]
pub enum ConditionOp {
    /// Greater than (`>`).
    Gt,
    /// Less than (`<`).
    Lt,
    /// Greater than or equal (`>=`).
    Gte,
    /// Less than or equal (`<=`).
    Lte,
    /// Equal (`==`).
    Eq,
    /// Not equal (`!=`).
    Neq,
}

/// Right-hand side value for a transition condition.
///
/// # Variants
/// - `Number` — `f32` numeric threshold.
/// - `Bool` — `bool` flag.
#[derive(Debug, Clone)]
pub enum ConditionValue {
    /// Numeric threshold value.
    Number(f32),
    /// Boolean value.
    Bool(bool),
}

/// A single condition on one named parameter.
///
/// # Fields
/// - `param` — `String`. Parameter name.
/// - `op` — [`ConditionOp`]. Comparison operator.
/// - `value` — [`ConditionValue`]. Threshold to compare against.
#[derive(Debug, Clone)]
pub struct TransitionCondition {
    /// Name of the parameter to test.
    pub param: String,
    /// Comparison operator.
    pub op: ConditionOp,
    /// Value to compare the parameter against.
    pub value: ConditionValue,
}

// ── Transition ───────────────────────────────────────────────────────────────

/// A directed state transition with a single condition.
///
/// # Fields
/// - `from` — `String`. Source state name.
/// - `to` — `String`. Target state name.
/// - `condition` — [`TransitionCondition`].
#[derive(Debug, Clone)]
pub struct AnimTransition {
    /// Name of the source state.
    pub from: String,
    /// Name of the target state.
    pub to: String,
    /// Condition that must be true for this transition to fire.
    pub condition: TransitionCondition,
}

// ── State config ─────────────────────────────────────────────────────────────

/// Configuration for a single state in the state machine.
///
/// # Fields
/// - `clip` — `String`. Animation clip name to play in this state.
/// - `looping` — `bool`. Whether the clip loops.
#[derive(Debug, Clone)]
pub struct AnimStateConfig {
    /// Name of the animation clip to play for this state.
    pub clip: String,
    /// Whether the clip loops.
    pub looping: bool,
}

// ── AnimStateMachine ─────────────────────────────────────────────────────────

/// Parameter-driven finite-state machine for animation control.
///
/// Owns an [`Animation`] controller. On each [`update`](Self::update) call the
/// machine advances the animation by `dt` seconds, then checks registered transitions
/// to see if the current state should change.
///
/// # Fields
/// - `states` — `HashMap<String, AnimStateConfig>`.
/// - `transitions` — `Vec<AnimTransition>`.
/// - `current` — `String`. Active state name.
/// - `params` — `HashMap<String, AnimParamValue>`.
/// - `animation` — [`Animation`].
pub struct AnimStateMachine {
    /// All registered states.
    states: HashMap<String, AnimStateConfig>,
    /// Ordered transition rules.
    transitions: Vec<AnimTransition>,
    /// Currently active state name.
    current: String,
    /// Named parameter store.
    params: HashMap<String, AnimParamValue>,
    /// Owned animation controller.
    animation: Animation,
}

impl AnimStateMachine {
    /// Creates a new state machine with an owned animation and a named initial state.
    ///
    /// # Parameters
    /// - `animation` — [`Animation`]. Animation controller to drive.
    /// - `initial` — `String`. Name of the starting state.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(animation: Animation, initial: String) -> Self {
        Self {
            states: HashMap::new(),
            transitions: Vec::new(),
            current: initial,
            params: HashMap::new(),
            animation,
        }
    }

    /// Registers a named state mapping to a clip.
    ///
    /// # Parameters
    /// - `name` — `&str`. State name.
    /// - `clip` — `&str`. Clip name in the owned animation.
    /// - `looping` — `bool`. Whether the clip loops.
    pub fn add_state(&mut self, name: &str, clip: &str, looping: bool) {
        self.states.insert(
            name.to_string(),
            AnimStateConfig {
                clip: clip.to_string(),
                looping,
            },
        );
    }

    /// Adds a transition rule by parsing a condition string.
    ///
    /// Condition format: `"param op value"` where:
    /// - `op` is one of `>`, `<`, `>=`, `<=`, `==`, `!=`
    /// - `value` is a number, `"true"`, or `"false"`
    ///
    /// # Parameters
    /// - `from` — `&str`. Source state name.
    /// - `to` — `&str`. Target state name.
    /// - `condition_str` — `&str`. Condition string (e.g. `"speed > 0.1"`).
    pub fn add_transition(&mut self, from: &str, to: &str, condition_str: &str) {
        match parse_condition(condition_str) {
            Ok(cond) => {
                self.transitions.push(AnimTransition {
                    from: from.to_string(),
                    to: to.to_string(),
                    condition: cond,
                });
            }
            Err(e) => {
                log::warn!(
                    "AnimStateMachine: invalid condition '{}': {}",
                    condition_str,
                    e
                );
            }
        }
    }

    /// Sets a float parameter.
    ///
    /// # Parameters
    /// - `name` — `&str`. Parameter name.
    /// - `value` — `f32`.
    pub fn set_param_float(&mut self, name: &str, value: f32) {
        self.params
            .insert(name.to_string(), AnimParamValue::Float(value));
    }

    /// Sets a boolean parameter.
    ///
    /// # Parameters
    /// - `name` — `&str`. Parameter name.
    /// - `value` — `bool`.
    pub fn set_param_bool(&mut self, name: &str, value: bool) {
        self.params
            .insert(name.to_string(), AnimParamValue::Bool(value));
    }

    /// Sets an integer parameter.
    ///
    /// # Parameters
    /// - `name` — `&str`. Parameter name.
    /// - `value` — `i32`.
    pub fn set_param_int(&mut self, name: &str, value: i32) {
        self.params
            .insert(name.to_string(), AnimParamValue::Int(value));
    }

    /// Returns a reference to the current value of a named parameter.
    ///
    /// # Parameters
    /// - `name` — `&str`. Parameter name.
    ///
    /// # Returns
    /// `Option<&AnimParamValue>`.
    pub fn get_param(&self, name: &str) -> Option<&AnimParamValue> {
        self.params.get(name)
    }

    /// Advances the animation by `dt` seconds and evaluates transitions.
    ///
    /// If a transition condition is satisfied the machine switches to the target
    /// state and starts the corresponding clip.
    ///
    /// # Parameters
    /// - `dt` — `f32`. Delta time in seconds.
    pub fn update(&mut self, dt: f32) {
        self.animation.update(dt);
        self.check_transitions();
    }

    /// Checks all transitions from the current state and fires the first match.
    fn check_transitions(&mut self) {
        let current = self.current.clone();
        let transitions: Vec<_> = self
            .transitions
            .iter()
            .filter(|t| t.from == current)
            .cloned()
            .collect();
        for transition in transitions {
            if self.evaluate_condition(&transition.condition) {
                let target = transition.to.clone();
                if self.force_state(&target) {
                    // Transition fired — stop checking further transitions
                    return;
                }
            }
        }
    }

    /// Evaluates whether a condition is currently satisfied.
    fn evaluate_condition(&self, cond: &TransitionCondition) -> bool {
        let param = match self.params.get(&cond.param) {
            Some(p) => p,
            None => return false,
        };

        let param_num = match param {
            AnimParamValue::Float(v) => *v,
            AnimParamValue::Int(v) => *v as f32,
            AnimParamValue::Bool(v) => {
                // For bool: only Eq/Neq make sense
                return match &cond.value {
                    ConditionValue::Bool(b) => match cond.op {
                        ConditionOp::Eq => v == b,
                        ConditionOp::Neq => v != b,
                        _ => false,
                    },
                    ConditionValue::Number(n) => {
                        let bnum = if *v { 1.0f32 } else { 0.0f32 };
                        compare_nums(bnum, *n, &cond.op)
                    }
                };
            }
        };

        match &cond.value {
            ConditionValue::Number(threshold) => compare_nums(param_num, *threshold, &cond.op),
            ConditionValue::Bool(b) => {
                let b_num = if *b { 1.0f32 } else { 0.0f32 };
                compare_nums(param_num, b_num, &cond.op)
            }
        }
    }

    /// Returns the name of the currently active state.
    ///
    /// # Returns
    /// `&str`.
    pub fn get_state(&self) -> &str {
        &self.current
    }

    /// Forces a transition to the named state, playing the associated clip.
    ///
    /// # Parameters
    /// - `name` — `&str`. Target state name.
    ///
    /// # Returns
    /// `bool` — `true` if the state exists and the transition succeeded.
    pub fn force_state(&mut self, name: &str) -> bool {
        if let Some(cfg) = self.states.get(name) {
            let clip = cfg.clip.clone();
            let looping = cfg.looping;
            // Play the clip (ignore return — clip may not exist yet if lazy-loaded)
            let played = self.animation.play(&clip);
            if played {
                // Re-apply looping flag
                let _ = looping; // clip looping is encoded in the clip itself
                self.current = name.to_string();
            }
            played
        } else {
            false
        }
    }

    /// Returns an immutable reference to the owned animation.
    ///
    /// # Returns
    /// `&Animation`.
    pub fn get_animation(&self) -> &Animation {
        &self.animation
    }

    /// Returns a mutable reference to the owned animation.
    ///
    /// # Returns
    /// `&mut Animation`.
    pub fn get_animation_mut(&mut self) -> &mut Animation {
        &mut self.animation
    }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Applies a comparison operator to two `f32` values.
pub fn compare_nums(lhs: f32, rhs: f32, op: &ConditionOp) -> bool {
    match op {
        ConditionOp::Gt => lhs > rhs,
        ConditionOp::Lt => lhs < rhs,
        ConditionOp::Gte => lhs >= rhs,
        ConditionOp::Lte => lhs <= rhs,
        ConditionOp::Eq => (lhs - rhs).abs() < f32::EPSILON,
        ConditionOp::Neq => (lhs - rhs).abs() >= f32::EPSILON,
    }
}

/// Parses a condition string such as `"speed > 0.1"` or `"jumping == true"`.
///
/// Multi-character operators (`>=`, `<=`, `!=`) are tried before single-character ones.
///
/// # Parameters
/// - `s` — `&str`. Condition expression.
///
/// # Returns
/// `Result<TransitionCondition, String>`.
pub fn parse_condition(s: &str) -> Result<TransitionCondition, String> {
    let s = s.trim();

    // Try multi-char operators first to avoid partial matches (e.g. ">=" before ">").
    const OPS: &[(&str, ConditionOp)] = &[
        (">=", ConditionOp::Gte),
        ("<=", ConditionOp::Lte),
        ("!=", ConditionOp::Neq),
        (">", ConditionOp::Gt),
        ("<", ConditionOp::Lt),
        ("==", ConditionOp::Eq),
    ];

    for (op_str, op) in OPS {
        if let Some(pos) = s.find(op_str) {
            let param = s[..pos].trim().to_string();
            if param.is_empty() {
                continue;
            }
            let value_str = s[pos + op_str.len()..].trim();
            let value = if value_str == "true" {
                ConditionValue::Bool(true)
            } else if value_str == "false" {
                ConditionValue::Bool(false)
            } else {
                let n: f32 = value_str.parse().map_err(|_| {
                    format!(
                        "parse_condition: cannot parse value '{}' as number",
                        value_str
                    )
                })?;
                ConditionValue::Number(n)
            };
            return Ok(TransitionCondition {
                param,
                op: op.clone(),
                value,
            });
        }
    }

    Err(format!("parse_condition: cannot find operator in '{}'", s))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::animation::controller::Animation;
    use crate::math::Rect;

    fn make_anim() -> Animation {
        let mut anim = Animation::new();
        anim.add_frame(Rect::new(0.0, 0.0, 32.0, 32.0));
        anim.add_frame(Rect::new(32.0, 0.0, 32.0, 32.0));
        anim.add_clip("idle", vec![0], 1.0, true);
        anim.add_clip("walk", vec![0, 1], 10.0, true);
        anim
    }

    #[test]
    fn initial_state_is_set() {
        let sm = AnimStateMachine::new(make_anim(), "idle".to_string());
        assert_eq!(sm.get_state(), "idle");
    }

    #[test]
    fn add_state_and_force_transition() {
        let mut sm = AnimStateMachine::new(make_anim(), "idle".to_string());
        sm.add_state("idle", "idle", true);
        sm.add_state("walk", "walk", true);
        assert!(sm.force_state("walk"));
        assert_eq!(sm.get_state(), "walk");
    }

    #[test]
    fn force_nonexistent_state_returns_false() {
        let mut sm = AnimStateMachine::new(make_anim(), "idle".to_string());
        sm.add_state("idle", "idle", true);
        assert!(!sm.force_state("flying"));
    }

    #[test]
    fn param_driven_transition() {
        let mut sm = AnimStateMachine::new(make_anim(), "idle".to_string());
        sm.add_state("idle", "idle", true);
        sm.add_state("walk", "walk", true);
        sm.add_transition("idle", "walk", "speed > 0.1");
        sm.set_param_float("speed", 0.5);
        sm.update(0.016);
        assert_eq!(sm.get_state(), "walk");
    }

    #[test]
    fn param_below_threshold_stays() {
        let mut sm = AnimStateMachine::new(make_anim(), "idle".to_string());
        sm.add_state("idle", "idle", true);
        sm.add_state("walk", "walk", true);
        sm.add_transition("idle", "walk", "speed > 0.1");
        sm.set_param_float("speed", 0.05);
        sm.update(0.016);
        assert_eq!(sm.get_state(), "idle");
    }

    #[test]
    fn bool_param_condition() {
        let mut sm = AnimStateMachine::new(make_anim(), "idle".to_string());
        sm.add_state("idle", "idle", true);
        sm.add_state("walk", "walk", true);
        sm.add_transition("idle", "walk", "moving == true");
        sm.set_param_bool("moving", true);
        sm.update(0.016);
        assert_eq!(sm.get_state(), "walk");
    }

    #[test]
    fn parse_condition_gt() {
        let c = parse_condition("speed > 5.0").unwrap();
        assert_eq!(c.param, "speed");
        assert_eq!(c.op, ConditionOp::Gt);
    }

    #[test]
    fn parse_condition_invalid_returns_error() {
        assert!(parse_condition("noop").is_err());
    }

    #[test]
    fn compare_nums_helpers() {
        assert!(compare_nums(2.0, 1.0, &ConditionOp::Gt));
        assert!(!compare_nums(1.0, 2.0, &ConditionOp::Gt));
        assert!(compare_nums(1.0, 1.0, &ConditionOp::Eq));
        assert!(compare_nums(1.0, 2.0, &ConditionOp::Neq));
    }
}
