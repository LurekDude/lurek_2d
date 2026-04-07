# particle — Feature Analysis

**Tier**: 2 (Extension)
**Spec**: `specs/particle.md`
**Files**: Emitter-based particle system

## Purpose

2D particle effects: emitter-based system with shapes, forces, color/size over lifetime, bursts, and pooling.

## Current Feature Summary

- `ParticleEmitter`: rate-based emission with lifetime
- Emission shapes: point, circle, rectangle, line, cone
- Particle properties: position, velocity, acceleration, rotation, scale, color, lifetime
- Color over lifetime curves
- Size over lifetime curves
- Burst emission: instant batch spawn
- Forces: gravity, wind, radial
- Blend modes: additive, alpha
- Max particle limit per emitter
- Pooled particle allocation (no per-frame heap alloc)

## Feature Gaps

1. **No sub-emitters**: Can't spawn child emitters when particles die (essential for explosion chains, firework trails).
2. **No particle collision**: Particles don't interact with physics world or tilemap. Can't make sparks bounce off walls.
3. **No GPU particles**: All CPU. For 10k+ particles, GPU compute + instanced rendering would be necessary.
4. **No particle trails**: Can't draw lines connecting particle history positions (motion trails, laser effects).
5. **No particle attractors/repulsors**: Can't create point forces that pull/push particles. Common for vortex and black hole effects.
6. **No texture animation**: Particles use single sprites. Can't animate particle textures over lifetime (flipbook).
7. **No emission from mesh/path**: Can't emit particles along a Bezier curve or mesh edge.
8. **No warm-up**: New emitters start empty. No way to pre-simulate to fill screen with particles at scene start.

## Structural Issues

- **Clean separation**: Particle is data + simulation. Rendering goes through DrawCommand queue via graphics. This is correct.
- **Single emitter type**: One ParticleEmitter does everything. No specialized emitter types (trail emitter, billboard emitter).

## Suggestions

1. **Add sub-emitters**: `emitter:setDeathEmitter(childEmitter)` — spawn child particles on death. Transforms explosion/firework quality.
2. **Add particle attractors**: `emitter:addAttractor(x, y, strength, radius)` — point force affecting all particles. Enables vortex, gravity well, and magnetic effects.
3. **Add warm-up**: `emitter:warmUp(seconds)` — pre-simulate N seconds of emission. Particles appear immediately "in progress."
4. **Add flipbook animation**: `emitter:setAnimationFrames(spriteSheet, fps)` — particles cycle through sprite frames.
5. **Add particle trails**: `emitter:enableTrail(length, fadeAlpha)` — draw line segments connecting particle positions across frames.
6. **Add emission from path**: `emitter:setEmitPath(points)` — distribute new particles along a polyline/Bezier.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy |
|---|---|---|---|---|
| Emitter-based | ✅ | ✅ | ✅ | ✅ |
| Emission shapes | ✅ (5) | ✅ (4) | ❌ | ✅ |
| Color over life | ✅ | ✅ | ❌ | ✅ |
| Bursts | ✅ | ❌ | ❌ | ✅ |
| Sub-emitters | ❌ | ❌ | ❌ | ❌ |
| GPU particles | ❌ | ❌ | ❌ | ✅ |
| Trails | ❌ | ❌ | ❌ | ❌ |
| Attractors | ❌ | ❌ | ❌ | ❌ |
| Warm-up | ❌ | ❌ | ❌ | ❌ |

## Priority

**MEDIUM** — Sub-emitters and warm-up are the most impactful. Attractors and trails add visual depth. GPU particles is a long-term scalability story.
