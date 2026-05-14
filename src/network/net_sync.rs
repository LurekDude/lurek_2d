//! Game-state snapshot types and client-side prediction/reconciliation helpers.
//! Owns `EntitySnapshot` encoding, linear extrapolation, and blend-based reconciliation.
//! Does not own transport or framing; callers serialize snapshots via `message::pack`.
//! Used by both server (authoritative ticks) and client (prediction correction).

use crate::network::message::NetValue;
/// Point-in-time position and velocity snapshot for one networked entity.
#[derive(Debug, Clone, PartialEq)]
pub struct EntitySnapshot {
    /// Unique entity identifier consistent across all peers.
    pub id: u32,
    /// Simulation tick this snapshot was captured on.
    pub tick: u32,
    /// X position in world units.
    pub x: f32,
    /// Y position in world units.
    pub y: f32,
    /// X velocity in world units per second.
    pub vx: f32,
    /// Y velocity in world units per second.
    pub vy: f32,
}
impl EntitySnapshot {
    /// Encode this snapshot as a `NetValue::Map` suitable for wire transmission.
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
    /// Decode an `EntitySnapshot` from a `NetValue::Map`; returns `None` on missing or wrong-typed fields.
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
/// Return a linearly extrapolated snapshot one tick ahead of `snapshot` using its velocity and `dt` seconds.
pub fn predict_linear(snapshot: &EntitySnapshot, dt: f32) -> EntitySnapshot {
    let mut out = snapshot.clone();
    out.tick = out.tick.saturating_add(1);
    out.x += out.vx * dt;
    out.y += out.vy * dt;
    out
}
/// Blend `predicted` toward `authoritative` by factor `alpha` (0.0 = keep predicted, 1.0 = snap to authoritative).
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
