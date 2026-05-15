//! - Provides frame-based sprite animation with clips, playback modes, and named events.
//! - Supports Aseprite JSON import, blend layers, property curves, and state machine transitions.
//! - Offers Spine skeleton bridge, sync groups, and render-command generation for active frames.
//! - Re-exports all primary types so dependents can import from `animation::` directly.

/// Aseprite JSON parsing and tag extraction.
pub mod aseprite;
/// Blend layers and masks for layered animation output.
pub mod blend;
/// Clip definitions and playback mode metadata.
pub mod clip;
/// Runtime animation playback controller.
pub mod controller;
/// Curve and property timeline support.
pub mod curve;
/// Playback events emitted during clip advancement.
pub mod event;
/// Frame geometry and per-frame timing.
pub mod frame;
/// Conversion from frames to render commands.
pub mod render;
/// Optional Spine integration bridge.
pub mod spine_bridge;
/// Animation state machine and transition rules.
pub mod state_machine;
/// Synchronization groups for coordinating multiple animations.
pub mod sync_group;

/// Aseprite import helpers and parsed data structures.
pub use aseprite::{
    load_aseprite_json, AsepriteDirection, AsepriteFrameData, AsepriteParsed, AsepriteTagData,
};
/// Blend-layer data used by composite animation playback.
pub use blend::{BlendLayer, BlendLayerSet, BlendMask};
/// Clip playback primitives.
pub use clip::{AnimClip, ClipPlaybackMode};
/// Primary animation playback controller.
pub use controller::Animation;
/// Property timeline curve container.
pub use curve::AnimPropertyTimeline;
/// Events produced by the animation controller.
pub use event::AnimEvent;
/// Frame rectangle and duration types.
pub use frame::{AnimFrame, AnimationFrame};
/// Rendering parameters for animation draw commands.
pub use render::AnimRenderParams;
/// Spine integration entry point.
pub use spine_bridge::SpineAnimBridge;
/// State machine configuration, conditions, and transitions.
pub use state_machine::{
    AnimParamValue, AnimStateConfig, AnimStateMachine, AnimTransition, ConditionOp, ConditionValue,
    TransitionCondition,
};
/// Group synchronizer for multiple playback controllers.
pub use sync_group::AnimSyncGroup;
