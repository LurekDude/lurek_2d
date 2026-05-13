//! Drive animation clip changes from parameterized finite-state transitions.

use std::collections::HashMap;

use super::controller::Animation;

// ---- Type: AnimParamValue ----

/// Value held by an animation parameter.
#[derive(Debug, Clone)]
pub enum AnimParamValue {
    /// Boolean flag parameter.
    Bool(bool),
    /// Continuous float parameter.
    Float(f32),
    /// Integer parameter.
    Int(i32),
}

// ---- Type: ConditionOp ----

/// Comparison operator for a transition condition.
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

// ---- Type: ConditionValue ----

/// Right-hand side value for a transition condition.
#[derive(Debug, Clone)]
pub enum ConditionValue {
    /// Numeric threshold value.
    Number(f32),
    /// Boolean value.
    Bool(bool),
}

// ---- Type: TransitionCondition ----

/// A single condition on one named parameter.
#[derive(Debug, Clone)]
pub struct TransitionCondition {
    /// Name of the parameter to test.
    pub param: String,
    /// Comparison operator.
    pub op: ConditionOp,
    /// Value to compare the parameter against.
    pub value: ConditionValue,
}

// ---- Type: AnimTransition ----

/// A directed state transition with a single condition.
#[derive(Debug, Clone)]
pub struct AnimTransition {
    /// Name of the source state.
    pub from: String,
    /// Name of the target state.
    pub to: String,
    /// Condition that must be true for this transition to fire.
    pub condition: TransitionCondition,
}

// ---- Type: AnimStateConfig ----

/// Configuration for a single state in the state machine.
#[derive(Debug, Clone)]
pub struct AnimStateConfig {
    /// Name of the animation clip to play for this state.
    pub clip: String,
    /// Whether the clip loops.
    pub looping: bool,
}

// ---- Type: AnimStateMachine ----

/// Parameter-driven finite-state machine for animation control.
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
    // ---- Implementation: AnimStateMachine ----
    /// Create a new state machine with an owned animation and a named initial state.
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
    pub fn add_state(&mut self, name: &str, clip: &str, looping: bool) {
        self.states.insert(
            name.to_string(),
            AnimStateConfig {
                clip: clip.to_string(),
                looping,
            },
        );
    }

    /// Add a transition rule by parsing a condition string.
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

    /// Set a float parameter.
    pub fn set_param_float(&mut self, name: &str, value: f32) {
        self.params
            .insert(name.to_string(), AnimParamValue::Float(value));
    }

    /// Set a boolean parameter.
    pub fn set_param_bool(&mut self, name: &str, value: bool) {
        self.params
            .insert(name.to_string(), AnimParamValue::Bool(value));
    }

    /// Set an integer parameter.
    pub fn set_param_int(&mut self, name: &str, value: i32) {
        self.params
            .insert(name.to_string(), AnimParamValue::Int(value));
    }

    /// Return a reference to the current value of a named parameter.
    pub fn get_param(&self, name: &str) -> Option<&AnimParamValue> {
        self.params.get(name)
    }

    /// Advances the animation by `dt` seconds and evaluates transitions.
    pub fn update(&mut self, dt: f32) {
        self.animation.update(dt);
        self.check_transitions_chain();
    }

    /// Check transitions repeatedly so one tick can perform a short transition chain.
    fn check_transitions_chain(&mut self) {
        let hop_limit = self.transitions.len().max(1);
        for _ in 0..hop_limit {
            if !self.try_single_transition() {
                break;
            }
        }
    }

    fn try_single_transition(&mut self) -> bool {
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
                    return true;
                }
            }
        }
        false
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

    /// Return the name of the currently active state.
    pub fn get_state(&self) -> &str {
        &self.current
    }

    /// Forces a transition to the named state, playing the associated clip.
    pub fn force_state(&mut self, name: &str) -> bool {
        if let Some(cfg) = self.states.get(name) {
            let clip = cfg.clip.clone();
            let looping = cfg.looping;
            // Play the clip (ignore return â€” clip may not exist yet if lazy-loaded)
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

    /// Return an immutable reference to the owned animation.
    pub fn get_animation(&self) -> &Animation {
        &self.animation
    }

    /// Return a mutable reference to the owned animation.
    pub fn get_animation_mut(&mut self) -> &mut Animation {
        &mut self.animation
    }
}

// ---- Helper Functions: Condition Evaluation ----

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

/// Parse a condition string such as `"speed > 0.1"` or `"jumping == true"`.
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
