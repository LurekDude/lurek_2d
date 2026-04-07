# animation — Feature Analysis

**Tier**: 1 (Core)
**Spec**: `specs/animation.md`
**Files**: Frame-based sprite animation

## Purpose

Frame-based sprite animation: clips with frame sequences, looping, speed, events at specific frames. CPU-side data model — rendering delegated to graphics.

## Current Feature Summary

- `AnimationClip`: named sequence of frames with per-frame duration
- Frame events: trigger callbacks at specific frame indices
- Playback control: play, pause, stop, reset, reverse
- Looping modes: none, loop, ping-pong
- Speed multiplier per clip
- Current frame query for rendering
- Multiple clips per entity (state-machine-like switching)

## Feature Gaps

1. **No animation blending/crossfade**: Can't smoothly transition between two clips (e.g., walk → run). Must hard-cut.
2. **No animation state machine**: No built-in FSM for animation states (idle → walk → jump → fall). Must implement manually.
3. **No animation curves**: Only frame-based (discrete). No continuous interpolation curves (Bezier, linear) for smooth property animation.
4. **No skeletal animation**: Frame-only — no bone/joint animation. `spine` module handles bones but there's no bridge.
5. **No animation layers/masks**: Can't blend upper body attack with lower body walk.
6. **No sprite sheet loading from JSON**: Must manually define frame regions. No TexturePacker/Aseprite import.
7. **No reverse playback**: Listed in spec but unclear if properly implemented.
8. **No animation groups**: Can't synchronize multiple related clips.

## Structural Issues

- **Tween overlap with math module**: `math::Tween` interpolates values over time. Animation module does frame-based animation. Property tweening (move X from 0 to 100 over 2 seconds) is a gap between both modules. Neither fully owns it.
- **No integration with spine**: Spine module has bones, animation module has clips. They should work together for skeletal animation with frame-based control.
- **Consider dedicated tween module**: Extract property animation into `tween` module (like Solar2D's `transition.to()`).

## Suggestions

1. **Add animation state machine**: `luna.animation.newStateMachine({idle=clipA, walk=clipB, jump=clipC}, transitions)` — declarative state transitions with optional blend times.
2. **Add crossfade**: `anim:crossfade(targetClip, duration)` — smooth transition between clips.
3. **Add Aseprite import**: `luna.animation.fromAseprite(jsonPath)` — load frame data from Aseprite export. Very common pixel art workflow.
4. **Create a tween module** (new): Extract property animation from math/animation into `luna.tween.to(target, {x=100}, 2.0, "easeOutQuad")`. Solar2D's `transition.to()` is the gold standard here.
5. **Bridge with spine**: Allow animation clips to drive bone transforms from the spine module.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Gideros |
|---|---|---|---|---|
| Frame animation | ✅ | ❌ (manual) | ✅ (sheets) | ✅ (MovieClip) |
| Animation blend | ❌ | N/A | ❌ | ❌ |
| State machine | ❌ | N/A | ❌ | ❌ |
| Tween/transition | ❌ (math only) | ❌ | ✅ (transition.to) | ✅ (GTween) |
| Skeleton | ❌ (spine module) | ❌ | ❌ | ✅ (Spine plugin) |
| Aseprite import | ❌ | ❌ | ❌ | ❌ |

## Priority

**MEDIUM-HIGH** — Tween extraction and animation state machine are high impact. Aseprite import serves the pixel art community directly. Crossfade is essential for polished games.
