//! Common helpers for entity state sync and lightweight client prediction.

use crate::network::message::NetValue;

/// Basic network snapshot for one entity.
#[derive(Debug, Clone, PartialEq)]
pub struct EntitySnapshot {
    /// Stable entity identifier.
    pub id: u32,
    /// Simulation tick used by reconciliation.
    pub tick: u32,
    /// Position X.
    pub x: f32,
    /// Position Y.
    pub y: f32,
    /// Velocity X.
    pub vx: f32,
    /// Velocity Y.
    pub vy: f32,
}

impl EntitySnapshot {
    /// Encodes this snapshot to NetValue map.
    pub fn to_netvalue(&self) -> NetValue {
        NetValue::Map(vec![
            ("id".to_string(), NetValue::Integer(self.id as i64)),
            ("tick".to_string(), NetValue::Integer(self.tick as i64)),
            ("x".to_string(), NetValue::Float(self.x as f64)),
            ("y".to_string(), NetValue::Float(self.y as f64)),
            ("vx".to_string(), NetValue::Float(self.vx as f64)),
            ("vy".to_string(), NetValue::Float(self.vy as f64)),
        ])
    }

    /// Decodes snapshot from NetValue map.
    pub fn from_netvalue(value: &NetValue) -> Option<Self> {
        let NetValue::Map(fields) = value else {
            return None;
        };
        let get_i = |name: &str| {
            fields.iter().find_map(|(k, v)| {
                if k == name {
                    if let NetValue::Integer(i) = v {
                        return Some(*i);
                    }
                }
                None
            })
        };
        let get_f = |name: &str| {
            fields.iter().find_map(|(k, v)| {
                if k == name {
                    match v {
                        NetValue::Float(f) => Some(*f as f32),
                        NetValue::Integer(i) => Some(*i as f32),
                        _ => None,
                    }
                } else {
                    None
                }
            })
        };

        Some(Self {
            id: get_i("id")? as u32,
            tick: get_i("tick")? as u32,
            x: get_f("x")?,
            y: get_f("y")?,
            vx: get_f("vx")?,
            vy: get_f("vy")?,
        })
    }
}

/// Linear client-side prediction for one fixed step.
pub fn predict_linear(snapshot: &EntitySnapshot, dt: f32) -> EntitySnapshot {
    let mut out = snapshot.clone();
    out.tick = out.tick.saturating_add(1);
    out.x += out.vx * dt;
    out.y += out.vy * dt;
    out
}

/// Reconciles a predicted state towards server-authoritative snapshot.
pub fn reconcile(
    predicted: &EntitySnapshot,
    authoritative: &EntitySnapshot,
    alpha: f32,
) -> EntitySnapshot {
    let t = alpha.clamp(0.0, 1.0);
    EntitySnapshot {
        id: authoritative.id,
        tick: authoritative.tick,
        x: predicted.x + (authoritative.x - predicted.x) * t,
        y: predicted.y + (authoritative.y - predicted.y) * t,
        vx: authoritative.vx,
        vy: authoritative.vy,
    }
}
