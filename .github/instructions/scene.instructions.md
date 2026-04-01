---
applyTo: "src/scene/**"
---

# Scene Module Instructions

Rules for working on `src/scene/` — scene stack and transitions.

## Module Rules

- SceneStack manages a stack of active scenes with push/pop semantics
- Transitions animate between scene changes (fade, slide)
- TransitionType variants: `Fade`, `SlideLeft`, `SlideRight`, `SlideUp`, `SlideDown`, `None`
- Unknown transition strings map to `TransitionType::None`
- DepthSorter orders entities for draw calls by layer/z-order

## Key Types

- `SceneStack` — manages scene push/pop with transition support
- `ActiveTransition` — tracks transition progress (0.0 → 1.0), calls `update(dt)`
- `TransitionType` — enum of available transition effects
- `DepthSorter` — sorts draw calls by depth for correct layering

## Dependency Direction

- `scene` depends on `math` (interpolation, easing for transitions)
- `scene` must NOT depend on `graphics`, `physics`, `audio`, or `engine`
- `lua_api/scene_api.rs` bridges scene types to Lua

## Transition Rules

- `ActiveTransition.progress` starts at 0.0 and advances to 1.0
- `is_complete()` returns true when progress >= 1.0
- Transition duration is configurable — default 0.5 seconds
- `TransitionType::from_lua_str()` parses string names → enum variants
- Invalid strings → `TransitionType::None` (instant switch, no animation)

## Testing

- Tests in `tests/scene_tests.rs`
- Test TransitionType string parsing (all variants + unknown)
- Test ActiveTransition progress tracking and completion
- Test SceneStack push/pop ordering
