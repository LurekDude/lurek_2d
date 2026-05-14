
use super::controller::Animation;
use std::collections::HashMap;
/// Parameter value stored by the animation state machine.
#[derive(Debug, Clone)]
pub enum AnimParamValue {
    /// Boolean parameter.
    Bool(bool),
    /// Floating-point parameter.
    Float(f32),
    /// Integer parameter.
    Int(i32),
}
#[derive(Debug, Clone, PartialEq)]
/// Comparison operator used in transition conditions.
pub enum ConditionOp {
    /// Greater than.
    Gt,
    /// Less than.
    Lt,
    /// Greater than or equal.
    Gte,
    /// Less than or equal.
    Lte,
    /// Equal.
    Eq,
    /// Not equal.
    Neq,
}
#[derive(Debug, Clone)]
/// Value compared against a parameter.
pub enum ConditionValue {
    /// Numeric comparison value.
    Number(f32),
    /// Boolean comparison value.
    Bool(bool),
}
#[derive(Debug, Clone)]
/// Parsed transition condition.
pub struct TransitionCondition {
    /// Parameter name.
    pub param: String,
    /// Comparison operator.
    pub op: ConditionOp,
    /// Comparison value.
    pub value: ConditionValue,
}
#[derive(Debug, Clone)]
/// State transition with a parsed condition.
pub struct AnimTransition {
    /// Source state name.
    pub from: String,
    /// Destination state name.
    pub to: String,
    /// Condition that must be satisfied.
    pub condition: TransitionCondition,
}
#[derive(Debug, Clone)]
/// Clip assignment for one named state.
pub struct AnimStateConfig {
    /// Clip name.
    pub clip: String,
    /// Whether the clip loops.
    pub looping: bool,
}
/// Named-state animator that drives an `Animation` instance.
pub struct AnimStateMachine {
    /// Registered states.
    states: HashMap<String, AnimStateConfig>,
    /// Registered transitions.
    transitions: Vec<AnimTransition>,
    /// Current state name.
    current: String,
    /// Named parameters used by transition conditions.
    params: HashMap<String, AnimParamValue>,
    /// Owned animation controller.
    animation: Animation,
}
impl AnimStateMachine {
    /// Create a state machine with an initial state name.
    pub fn new(animation: Animation, initial: String) -> Self {
        Self {
            states: HashMap::new(),
            transitions: Vec::new(),
            current: initial,
            params: HashMap::new(),
            animation,
        }
    }
    /// Register a state and its clip mapping.
    pub fn add_state(&mut self, name: &str, clip: &str, looping: bool) {
        self.states.insert(
            name.to_string(),
            AnimStateConfig {
                clip: clip.to_string(),
                looping,
            },
        );
    }
    /// Parse and register a transition condition.
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
    /// Set a bool parameter.
    pub fn set_param_bool(&mut self, name: &str, value: bool) {
        self.params
            .insert(name.to_string(), AnimParamValue::Bool(value));
    }
    /// Set an integer parameter.
    pub fn set_param_int(&mut self, name: &str, value: i32) {
        self.params
            .insert(name.to_string(), AnimParamValue::Int(value));
    }
    /// Return a parameter by name.
    pub fn get_param(&self, name: &str) -> Option<&AnimParamValue> {
        self.params.get(name)
    }
    /// Advance the animation and process transition chains.
    pub fn update(&mut self, dt: f32) {
        self.animation.update(dt);
        self.check_transitions_chain();
    }
    /// Process a bounded chain of transitions.
    fn check_transitions_chain(&mut self) {
        let hop_limit = self.transitions.len().max(1);
        for _ in 0..hop_limit {
            if !self.try_single_transition() {
                break;
            }
        }
    }
    /// Try one outgoing transition from the current state.
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
    /// Evaluate a parsed transition condition.
    fn evaluate_condition(&self, cond: &TransitionCondition) -> bool {
        let param = match self.params.get(&cond.param) {
            Some(p) => p,
            None => return false,
        };
        let param_num = match param {
            AnimParamValue::Float(v) => *v,
            AnimParamValue::Int(v) => *v as f32,
            AnimParamValue::Bool(v) => {
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
    /// Return the current state name.
    pub fn get_state(&self) -> &str {
        &self.current
    }
    /// Force a transition to `name`; returns `false` when the state is unknown or clip play fails.
    pub fn force_state(&mut self, name: &str) -> bool {
        if let Some(cfg) = self.states.get(name) {
            let clip = cfg.clip.clone();
            let looping = cfg.looping;
            let played = self.animation.play(&clip);
            if played {
                let _ = looping;
                self.current = name.to_string();
            }
            played
        } else {
            false
        }
    }
    /// Return the owned animation controller.
    pub fn get_animation(&self) -> &Animation {
        &self.animation
    }
    /// Return the owned animation controller mutably.
    pub fn get_animation_mut(&mut self) -> &mut Animation {
        &mut self.animation
    }
}
/// Compare two numeric values using a `ConditionOp`.
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
/// Parse a transition condition string like `speed >= 0.5`.
pub fn parse_condition(s: &str) -> Result<TransitionCondition, String> {
    let s = s.trim();
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
