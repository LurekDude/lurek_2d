# P3 Validation Results

## cag_validate --type skill --format text

Scanned: system_prompt=0 agents=0 skills=33 prompts=0
Summary: 0 errors, 0 warnings

## cag_validate --baseline

  ERROR   E001  .github/copilot-instructions.md  G현  Missing required section: 'Engine Identity'
  ERROR   E001  .github/copilot-instructions.md  G현  Missing required section: 'Binding Constraints'
  ERROR   E001  .github/copilot-instructions.md  G현  Missing required section: 'Discovery'
  ERROR   E001  .github/copilot-instructions.md  G현  Missing required section: 'Quality Gates'
  ERROR   E001  .github/copilot-instructions.md  G현  Missing pointer to 'docs/architecture/cag-system.md'
  ERROR   E002  .github/copilot-instructions.md  G현  File has 298 lines (cap 120)
  ERROR   E003  .github/copilot-instructions.md  G현  File has 26344 bytes (cap 8192)
  WARNING W005  .github/copilot-instructions.md:101  G현  Broken reference: 'content/demos/README.md'
  WARNING W005  .github/copilot-instructions.md:137  G현  Broken reference: 'tests/rust/stress/'
  WARNING W005  .github/copilot-instructions.md:137  G현  Broken reference: 'tests/rust/config/'
  WARNING W005  .github/copilot-instructions.md:137  G현  Broken reference: 'tests/rust/security/'
  WARNING W005  .github/copilot-instructions.md:137  G현  Broken reference: 'tests/rust/game/'
  WARNING W005  .github/copilot-instructions.md:137  G현  Broken reference: 'tests/lua/content/library/'
  WARNING W005  .github/copilot-instructions.md:141  G현  Broken reference: 'content/demos/'
  WARNING W005  .github/copilot-instructions.md:141  G현  Broken reference: 'content/demos/'
  WARNING W005  .github/copilot-instructions.md:147  G현  Broken reference: 'content/demos/'
  WARNING W005  .github/copilot-instructions.md:165  G현  Broken reference: 'content/demos/'
  WARNING W005  .github/copilot-instructions.md:276  G현  Broken reference: 'content/demos/'
  WARNING W005  .github/copilot-instructions.md:292  G현  Broken reference: 'content/demos/'
  ERROR   E305  .github/prompts/analyze-memory-usage.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/analyze-memory-usage.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/analyze-memory-usage.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/analyze-memory-usage.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/analyze-pathfinding-performance.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/analyze-pathfinding-performance.prompt.md  G현  Missing required section: 'Inputs'
  ERROR   E305  .github/prompts/analyze-pathfinding-performance.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/analyze-pathfinding-performance.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/analyze-pathfinding-performance.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/analyze-physics-performance.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/analyze-physics-performance.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/analyze-physics-performance.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/analyze-physics-performance.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/analyze-render-performance.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/analyze-render-performance.prompt.md  G현  Missing required section: 'Inputs'
  ERROR   E305  .github/prompts/analyze-render-performance.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/analyze-render-performance.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/analyze-render-performance.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/analyze-roadmap-phase.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/analyze-roadmap-phase.prompt.md  G현  Missing required section: 'Steps'
  ERROR   E305  .github/prompts/analyze-roadmap-phase.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/analyze-roadmap-phase.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/analyze-roadmap-phase.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/audit-module.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/audit-module.prompt.md  G현  Missing required section: 'Inputs'
  ERROR   E305  .github/prompts/audit-module.prompt.md  G현  Missing required section: 'Steps'
  ERROR   E305  .github/prompts/audit-module.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/audit-module.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/audit-module.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/create-ai-behavior.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/create-ai-behavior.prompt.md  G현  Missing required section: 'Inputs'
  ERROR   E305  .github/prompts/create-ai-behavior.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/create-ai-behavior.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/create-ai-behavior.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/create-api-function.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/create-api-function.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/create-api-function.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/create-api-function.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/create-audio-feature.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/create-audio-feature.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/create-audio-feature.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/create-audio-feature.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/create-demo.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/create-demo.prompt.md  G현  Missing required section: 'Steps'
  ERROR   E305  .github/prompts/create-demo.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/create-demo.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/create-demo.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/create-draw-command.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/create-draw-command.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/create-draw-command.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/create-draw-command.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/create-engine-module.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/create-engine-module.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/create-engine-module.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/create-engine-module.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/create-event-pattern.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/create-event-pattern.prompt.md  G현  Missing required section: 'Inputs'
  ERROR   E305  .github/prompts/create-event-pattern.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/create-event-pattern.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/create-event-pattern.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/create-game-example.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/create-game-example.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/create-game-example.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/create-game-example.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/create-integration-test.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/create-integration-test.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/create-integration-test.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/create-integration-test.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/create-lua-example.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/create-lua-example.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/create-lua-example.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/create-lua-example.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/create-physics-feature.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/create-physics-feature.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/create-physics-feature.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/create-physics-feature.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/create-roadmap-phase.prompt.md  G현  Section 'Inputs' is out of order
  ERROR   E305  .github/prompts/create-roadmap-phase.prompt.md  G현  Section 'Steps' is out of order
  ERROR   E305  .github/prompts/create-roadmap-phase.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/create-roadmap-phase.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/create-roadmap-phase.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/create-test-suite.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/create-test-suite.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/create-test-suite.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/create-test-suite.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/create-tilemap-feature.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/create-tilemap-feature.prompt.md  G현  Missing required section: 'Inputs'
  ERROR   E305  .github/prompts/create-tilemap-feature.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/create-tilemap-feature.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/create-tilemap-feature.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/design-api-surface.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/design-api-surface.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/design-api-surface.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/design-api-surface.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/doc-api-reference.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/doc-api-reference.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/doc-api-reference.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/doc-api-reference.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/fix-api-function.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/fix-api-function.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/fix-api-function.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/fix-api-function.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/fix-compilation-errors.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/fix-compilation-errors.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/fix-compilation-errors.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/fix-compilation-errors.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/fix-dependency-issue.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/fix-dependency-issue.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/fix-dependency-issue.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/fix-dependency-issue.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/fix-engine-bug.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/fix-engine-bug.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/fix-engine-bug.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/fix-engine-bug.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/fix-failing-tests.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/fix-failing-tests.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/fix-failing-tests.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/fix-failing-tests.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/fix-lua-error.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/fix-lua-error.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/fix-lua-error.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/fix-lua-error.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/fix-threading-issue.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/fix-threading-issue.prompt.md  G현  Missing required section: 'Inputs'
  ERROR   E305  .github/prompts/fix-threading-issue.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/fix-threading-issue.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/fix-threading-issue.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/flesh-out-example.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/flesh-out-example.prompt.md  G현  Missing required section: 'Inputs'
  ERROR   E305  .github/prompts/flesh-out-example.prompt.md  G현  Missing required section: 'Steps'
  ERROR   E305  .github/prompts/flesh-out-example.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/flesh-out-example.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/generate-roadmap-phase-from-description.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/generate-roadmap-phase-from-description.prompt.md  G현  Missing required section: 'Inputs'
  ERROR   E305  .github/prompts/generate-roadmap-phase-from-description.prompt.md  G현  Missing required section: 'Steps'
  ERROR   E305  .github/prompts/generate-roadmap-phase-from-description.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/generate-roadmap-phase-from-description.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/generate-roadmap-phase-from-description.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/implement-lua-api-module.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/implement-lua-api-module.prompt.md  G현  Missing required section: 'Inputs'
  ERROR   E305  .github/prompts/implement-lua-api-module.prompt.md  G현  Missing required section: 'Steps'
  ERROR   E305  .github/prompts/implement-lua-api-module.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/implement-lua-api-module.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/implement-lua-api-module.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/implement-roadmap-phase.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/implement-roadmap-phase.prompt.md  G현  Missing required section: 'Steps'
  ERROR   E305  .github/prompts/implement-roadmap-phase.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/implement-roadmap-phase.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/implement-roadmap-phase.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/op-build-release.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/op-build-release.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/op-build-release.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/op-build-release.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/review-api-consistency.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/review-api-consistency.prompt.md  G현  Missing required section: 'Inputs'
  ERROR   E305  .github/prompts/review-api-consistency.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/review-api-consistency.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/review-api-consistency.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/review-code-quality.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/review-code-quality.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/review-code-quality.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/review-code-quality.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/review-entity-lifecycle.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/review-entity-lifecycle.prompt.md  G현  Missing required section: 'Inputs'
  ERROR   E305  .github/prompts/review-entity-lifecycle.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/review-entity-lifecycle.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/review-entity-lifecycle.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/review-module-deps.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/review-module-deps.prompt.md  G현  Missing required section: 'Inputs'
  ERROR   E305  .github/prompts/review-module-deps.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/review-module-deps.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/review-module-deps.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/review-security-audit.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/review-security-audit.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/review-security-audit.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/review-security-audit.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/review-unsafe-code.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/review-unsafe-code.prompt.md  G현  Missing required section: 'Inputs'
  ERROR   E305  .github/prompts/review-unsafe-code.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/review-unsafe-code.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/review-unsafe-code.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/run-cag-validation.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/run-cag-validation.prompt.md  G현  Missing required section: 'Inputs'
  ERROR   E305  .github/prompts/run-cag-validation.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/run-cag-validation.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/run-cag-validation.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/run-quality-gates.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/run-quality-gates.prompt.md  G현  Missing required section: 'Inputs'
  ERROR   E305  .github/prompts/run-quality-gates.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/run-quality-gates.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/run-quality-gates.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/workflow-feature-development.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/workflow-feature-development.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/workflow-feature-development.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/workflow-feature-development.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/workflow-release-check.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/workflow-release-check.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/workflow-release-check.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/workflow-release-check.prompt.md  G현  Missing required section: 'Example Invocation'
  ERROR   E305  .github/prompts/workflow-update-roadmap-phase.prompt.md  G현  Missing required section: 'Goal'
  ERROR   E305  .github/prompts/workflow-update-roadmap-phase.prompt.md  G현  Missing required section: 'Success Criteria'
  ERROR   E305  .github/prompts/workflow-update-roadmap-phase.prompt.md  G현  Missing required section: 'Anti-patterns'
  ERROR   E305  .github/prompts/workflow-update-roadmap-phase.prompt.md  G현  Missing required section: 'Example Invocation'

Scanned: system_prompt=1 agents=20 skills=33 prompts=45
Summary: 210 errors, 12 warnings
Top rules: E305=203, W005=12, E001=5, E002=1, E003=1

REGRESSIONS vs baseline: 2 new violation(s)
  + E002  .github/copilot-instructions.md  G현  File has 298 lines (cap 120)
  + E003  .github/copilot-instructions.md  G현  File has 26344 bytes (cap 8192)

BASELINE EXIT: 1


## cag_coverage --type skill

# CAG Required-Section Coverage

## skill  (n=33)

| Field | Coverage |
|-------|---------:|
| `fm:name` | 100.0% |
| `fm:description` | 100.0% |
| `fm:companion_files` | 100.0% |
| `fm:related_skills` |   3.0% |
| `sec:Mission` | 100.0% |
| `sec:When To Load` | 100.0% |
| `sec:When To Skip` | 100.0% |
| `sec:Domain Knowledge` | 100.0% |
| `sec:Companion File Index` | 100.0% |
| `sec:References` | 100.0% |


## cag_link_check --strict (full)

  BROKEN  .github/agents/developer.agent.md:23  [tests]  -> tests/rust/stress/
  BROKEN  .github/agents/doc-writer.agent.md:3  [content]  -> content/demos/
  BROKEN  .github/agents/doc-writer.agent.md:15  [content]  -> content/demos/
  BROKEN  .github/agents/doc-writer.agent.md:38  [content]  -> content/demos/
  BROKEN  .github/agents/lua-designer.agent.md:24  [content]  -> content/demos/
  BROKEN  .github/agents/player.agent.md:15  [content]  -> content/demos/
  BROKEN  .github/agents/player.agent.md:20  [content]  -> content/demos/
  BROKEN  .github/agents/player.agent.md:45  [content]  -> content/demos/
  BROKEN  .github/agents/player.agent.md:70  [content]  -> content/demos/
  BROKEN  .github/agents/renderer.agent.md:21  [src]  -> src/lua_api/font_api.rs
  BROKEN  .github/agents/tester.agent.md:20  [tests]  -> tests/rust/stress/
  BROKEN  .github/agents/tester.agent.md:20  [tests]  -> tests/rust/config/
  BROKEN  .github/agents/tester.agent.md:20  [tests]  -> tests/rust/security/
  BROKEN  .github/copilot-instructions.md:101  [content]  -> content/demos/README.md
  BROKEN  .github/copilot-instructions.md:137  [tests]  -> tests/rust/stress/
  BROKEN  .github/copilot-instructions.md:137  [tests]  -> tests/rust/config/
  BROKEN  .github/copilot-instructions.md:137  [tests]  -> tests/rust/security/
  BROKEN  .github/copilot-instructions.md:137  [tests]  -> tests/rust/game/
  BROKEN  .github/copilot-instructions.md:137  [tests]  -> tests/lua/content/library/
  BROKEN  .github/copilot-instructions.md:141  [content]  -> content/demos/
  BROKEN  .github/copilot-instructions.md:141  [content]  -> content/demos/
  BROKEN  .github/copilot-instructions.md:147  [content]  -> content/demos/
  BROKEN  .github/copilot-instructions.md:165  [content]  -> content/demos/
  BROKEN  .github/copilot-instructions.md:276  [content]  -> content/demos/
  BROKEN  .github/copilot-instructions.md:292  [content]  -> content/demos/
  BROKEN  .github/prompts/analyze-pathfinding-performance.prompt.md:10  [tests]  -> tests/rust/unit/pathfinding_tests.rs
  BROKEN  .github/prompts/analyze-roadmap-phase.prompt.md:170  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/analyze-roadmap-phase.prompt.md:440  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/audit-module.prompt.md:191  [docs]  -> docs/performance/
  BROKEN  .github/prompts/create-ai-behavior.prompt.md:11  [tests]  -> tests/rust/game/ai_tests.rs
  BROKEN  .github/prompts/create-ai-behavior.prompt.md:37  [tests]  -> tests/rust/game/ai_tests.rs
  BROKEN  .github/prompts/create-api-function.prompt.md:35  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/create-api-function.prompt.md:42  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/create-api-function.prompt.md:60  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/create-audio-feature.prompt.md:7  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/create-audio-feature.prompt.md:10  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/create-audio-feature.prompt.md:31  [tests]  -> tests/rust/unit/audio_tests.rs
  BROKEN  .github/prompts/create-audio-feature.prompt.md:32  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/create-audio-feature.prompt.md:39  [tests]  -> tests/rust/unit/audio_tests.rs
  BROKEN  .github/prompts/create-audio-feature.prompt.md:40  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/create-audio-feature.prompt.md:47  [tests]  -> tests/rust/unit/audio_tests.rs
  BROKEN  .github/prompts/create-audio-feature.prompt.md:48  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/create-audio-feature.prompt.md:60  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/create-demo.prompt.md:43  [content]  -> content/demos/README.md
  BROKEN  .github/prompts/create-demo.prompt.md:52  [content]  -> content/demos/
  BROKEN  .github/prompts/create-demo.prompt.md:95  [content]  -> content/demos/README.md
  BROKEN  .github/prompts/create-demo.prompt.md:110  [content]  -> content/demos/README.md
  BROKEN  .github/prompts/create-demo.prompt.md:139  [content]  -> ../../content/demos/hello_world/main.lua
  BROKEN  .github/prompts/create-demo.prompt.md:140  [content]  -> ../../content/demos/platformer/main.lua
  BROKEN  .github/prompts/create-demo.prompt.md:141  [content]  -> ../../content/demos/roguelike/main.lua
  BROKEN  .github/prompts/create-demo.prompt.md:142  [content]  -> ../../content/demos/dialog_demo/main.lua
  BROKEN  .github/prompts/create-demo.prompt.md:143  [content]  -> ../../content/demos/loot_rpg_demo/main.lua
  BROKEN  .github/prompts/create-draw-command.prompt.md:22  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/create-event-pattern.prompt.md:11  [tests]  -> tests/rust/unit/event_tests.rs
  BROKEN  .github/prompts/create-event-pattern.prompt.md:31  [tests]  -> tests/rust/unit/event_tests.rs
  BROKEN  .github/prompts/create-game-example.prompt.md:54  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/create-lua-example.prompt.md:28  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/create-tilemap-feature.prompt.md:11  [tests]  -> tests/rust/unit/tilemap_tests.rs
  BROKEN  .github/prompts/create-tilemap-feature.prompt.md:34  [tests]  -> tests/rust/unit/tilemap_tests.rs
  BROKEN  .github/prompts/create-tilemap-feature.prompt.md:41  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/design-api-surface.prompt.md:33  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/design-api-surface.prompt.md:40  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/design-api-surface.prompt.md:47  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/design-api-surface.prompt.md:55  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/doc-api-reference.prompt.md:9  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/doc-api-reference.prompt.md:24  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/doc-api-reference.prompt.md:38  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/doc-api-reference.prompt.md:43  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/doc-api-reference.prompt.md:54  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/fix-api-function.prompt.md:23  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/fix-api-function.prompt.md:35  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/fix-lua-error.prompt.md:57  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/fix-threading-issue.prompt.md:11  [tests]  -> tests/rust/unit/thread_tests.rs
  BROKEN  .github/prompts/fix-threading-issue.prompt.md:40  [tests]  -> tests/rust/unit/thread_tests.rs
  BROKEN  .github/prompts/generate-roadmap-phase-from-description.prompt.md:68  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/implement-roadmap-phase.prompt.md:85  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/implement-roadmap-phase.prompt.md:375  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/implement-roadmap-phase.prompt.md:376  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/op-build-release.prompt.md:60  [content]  -> content/demos/hello_world
  BROKEN  .github/prompts/review-api-consistency.prompt.md:18  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/review-api-consistency.prompt.md:31  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/prompts/review-entity-lifecycle.prompt.md:11  [tests]  -> tests/rust/unit/ecs_tests.rs
  BROKEN  .github/prompts/workflow-feature-development.prompt.md:113  [content]  -> content/demos/
  BROKEN  .github/prompts/workflow-release-check.prompt.md:58  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/skills/agent-md/SKILL.md:21  [tools]  -> tools/audit/validate_agent_md.py
  BROKEN  .github/skills/agent-md/SKILL.md:45  [tools]  -> tools/audit/validate_agent_md.py
  BROKEN  .github/skills/analytics/snippets/extended-notes.md:8  [cag]  -> examples/record-for-performance-analysis.lua
  BROKEN  .github/skills/analytics/snippets/extended-notes.md:15  [cag]  -> examples/death-heatmap-python.py
  BROKEN  .github/skills/analytics/snippets/extended-notes.md:19  [cag]  -> snippets/level-completion-funnel-powershell.ps1
  BROKEN  .github/skills/asset-pipeline/SKILL.md:41  [src]  -> src/render/texture.rs
  BROKEN  .github/skills/build-system/snippets/extended-notes.md:1  [cag]  -> templates/feature-flags-lua-backend.toml
  BROKEN  .github/skills/build-system/snippets/extended-notes.md:8  [cag]  -> snippets/development-loop-commands.ps1
  BROKEN  .github/skills/build-system/snippets/extended-notes.md:17  [cag]  -> snippets/windows-zip-folder.ps1
  BROKEN  .github/skills/build-system/snippets/extended-notes.md:23  [cag]  -> snippets/linux-macos-tar-gz.sh
  BROKEN  .github/skills/build-system/snippets/extended-notes.md:29  [cag]  -> snippets/windows-installer-nsis.ps1
  BROKEN  .github/skills/build-system/snippets/extended-notes.md:36  [cag]  -> snippets/local-install-uninstall.ps1
  BROKEN  .github/skills/build-system/snippets/extended-notes.md:38  [cag]  -> snippets/local-install-uninstall-2.sh
  BROKEN  .github/skills/demo-creation/references/library-integration.md:3  [content]  -> content/demos/
  BROKEN  .github/skills/demo-creation/references/library-integration.md:47  [content]  -> content/library/X.lua
  BROKEN  .github/skills/demo-creation/references/library-integration.md:217  [content]  -> content/demos/README.md
  BROKEN  .github/skills/demo-creation/SKILL.md:23  [content]  -> content/demos/README.md
  BROKEN  .github/skills/demo-creation/SKILL.md:40  [content]  -> content/demos/README.md
  BROKEN  .github/skills/demo-creation/SKILL.md:66  [content]  -> content/demos/
  BROKEN  .github/skills/demo-creation/SKILL.md:110  [content]  -> content/demos/README.md
  BROKEN  .github/skills/demo-creation/SKILL.md:111  [content]  -> content/demos/README.md
  BROKEN  .github/skills/demo-creation/snippets/extended-notes.md:12  [cag]  -> ./references/library-integration.md
  BROKEN  .github/skills/demo-creation/snippets/extended-notes.md:15  [cag]  -> examples/step-4-library-modules.lua
  BROKEN  .github/skills/demo-creation/snippets/extended-notes.md:28  [cag]  -> examples/step-4-library-modules-2.lua
  BROKEN  .github/skills/demo-creation/snippets/extended-notes.md:32  [cag]  -> snippets/step-5-write-readme-md.md
  BROKEN  .github/skills/demo-creation/snippets/extended-notes.md:42  [cag]  -> snippets/notes.txt
  BROKEN  .github/skills/demo-creation/snippets/extended-notes.md:47  [cag]  -> snippets/notes-2.ps1
  BROKEN  .github/skills/demo-creation/snippets/extended-notes.md:49  [content]  -> content/demos/README.md
  BROKEN  .github/skills/demo-creation/snippets/extended-notes.md:52  [cag]  -> snippets/step-7-register-in-content-demos.md
  BROKEN  .github/skills/demo-creation/snippets/extended-notes.md:55  [cag]  -> snippets/step-7-register-in-content-demos-2.md
  BROKEN  .github/skills/dev-debugging/snippets/extended-notes.md:1  [cag]  -> snippets/refcell-borrow-diagnosis.txt
  BROKEN  .github/skills/dev-debugging/snippets/extended-notes.md:7  [cag]  -> examples/refcell-borrow-diagnosis-2.rs
  BROKEN  .github/skills/dev-debugging/snippets/extended-notes.md:11  [cag]  -> examples/refcell-borrow-diagnosis-3.rs
  BROKEN  .github/skills/dev-debugging/snippets/extended-notes.md:16  [cag]  -> examples/diagnostic-log-placement.rs
  BROKEN  .github/skills/documentation/SKILL.md:41  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/skills/documentation/SKILL.md:68  [tests]  -> tests/unit/
  BROKEN  .github/skills/documentation/SKILL.md:68  [tests]  -> tests/rust/game/
  BROKEN  .github/skills/documentation/SKILL.md:68  [tests]  -> tests/rust/stress/
  BROKEN  .github/skills/documentation/SKILL.md:82  [content]  -> content/demos/
  BROKEN  .github/skills/examples-management/SKILL.md:19  [content]  -> content/demos/
  BROKEN  .github/skills/examples-management/SKILL.md:21  [content]  -> content/demos/
  BROKEN  .github/skills/examples-management/SKILL.md:33  [content]  -> content/demos/
  BROKEN  .github/skills/examples-management/SKILL.md:38  [content]  -> content/examples/README.md
  BROKEN  .github/skills/examples-management/SKILL.md:38  [content]  -> content/demos/README.md
  BROKEN  .github/skills/examples-management/SKILL.md:44  [content]  -> content/demos/
  BROKEN  .github/skills/examples-management/SKILL.md:46  [content]  -> content/demos/
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:2  [content]  -> content/examples/README.md
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:3  [docs]  -> docs/API/lua_api_data.json
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:8  [content]  -> content/demos/README.md
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:14  [cag]  -> snippets/examples-and-api-documentation.ps1
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:21  [cag]  -> snippets/smoke-testing.ps1
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:27  [cag]  -> examples/smoke-testing-2.lua
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:30  [content]  -> content/examples/README.md
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:30  [content]  -> content/demos/README.md
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:33  [cag]  -> snippets/examples-readme.md
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:41  [content]  -> content/examples/README.md
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:44  [content]  -> content/demos/
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:50  [cag]  -> examples/input-key-names.lua
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:58  [cag]  -> examples/color-values.lua
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:64  [cag]  -> examples/rectangle-draw-mode.lua
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:68  [cag]  -> examples/physics-body-types.lua
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:72  [content]  -> content/demos/
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:85  [cag]  -> snippets/step-1-check-gaps.ps1
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:91  [cag]  -> snippets/step-2-append-stubs-for-missing.ps1
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:101  [cag]  -> snippets/step-3-flesh-out-stubs-with.txt
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:104  [cag]  -> snippets/step-3-flesh-out-stubs-with-2.txt
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:121  [content]  -> content/examples/entity.lua
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:122  [content]  -> content/examples/fx.lua
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:124  [content]  -> content/examples/localization.lua
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:127  [content]  -> content/examples/modding.lua
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:128  [content]  -> content/examples/pathfinding.lua
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:129  [content]  -> content/examples/graphics.lua
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:130  [content]  -> content/examples/savegame.lua
  BROKEN  .github/skills/examples-management/snippets/extended-notes.md:134  [content]  -> content/examples/gui.lua
  BROKEN  .github/skills/game-ai/snippets/extended-notes.md:1  [cag]  -> examples/blackboard-shared-ai-memory.lua
  BROKEN  .github/skills/game-ai/snippets/extended-notes.md:8  [cag]  -> examples/steering-behaviours.lua
  BROKEN  .github/skills/game-ai/snippets/extended-notes.md:15  [cag]  -> examples/goap-goal-oriented-action-planning.lua
  BROKEN  .github/skills/game-ai/snippets/extended-notes.md:22  [cag]  -> examples/utility-ai-scored-action-selection.lua
  BROKEN  .github/skills/game-ai/snippets/extended-notes.md:27  [cag]  -> examples/squad-group-formation.lua
  BROKEN  .github/skills/game-ai/snippets/extended-notes.md:32  [cag]  -> examples/influence-map-strategic-spatial-reasoning.lua
  BROKEN  .github/skills/game-ai/snippets/extended-notes.md:39  [cag]  -> examples/testing-ai.lua
  BROKEN  .github/skills/gpu-programming/snippets/extended-notes.md:5  [cag]  -> examples/canvas-render-to-texture.lua
  BROKEN  .github/skills/gpu-programming/snippets/extended-notes.md:7  [cag]  -> snippets/canvas-render-to-texture-2.txt
  BROKEN  .github/skills/gpu-programming/snippets/extended-notes.md:21  [cag]  -> snippets/transform-stack.txt
  BROKEN  .github/skills/library-authoring/SKILL.md:30  [content]  -> content/demos/
  BROKEN  .github/skills/library-authoring/SKILL.md:112  [content]  -> content/demos/
  BROKEN  .github/skills/logging/snippets/extended-notes.md:3  [cag]  -> examples/conditional-verbose-mode.lua
  BROKEN  .github/skills/logging/snippets/extended-notes.md:10  [cag]  -> snippets/log-to-file-rust-side.ps1
  BROKEN  .github/skills/logging/snippets/extended-notes.md:17  [cag]  -> snippets/during-tests.ps1
  BROKEN  .github/skills/lua-api-design/snippets/extended-notes.md:1  [cag]  -> snippets/3-section-separators.txt
  BROKEN  .github/skills/lua-api-design/snippets/extended-notes.md:7  [cag]  -> examples/4-userdata-struct.rs
  BROKEN  .github/skills/lua-api-design/snippets/extended-notes.md:11  [cag]  -> examples/5-impl-luauserdata-block.rs
  BROKEN  .github/skills/lua-api-design/snippets/extended-notes.md:27  [cag]  -> examples/callback-storage-pattern-luaregistrykey.rs
  BROKEN  .github/skills/lua-api-design/snippets/extended-notes.md:31  [cag]  -> examples/callback-storage-pattern-luaregistrykey-2.rs
  BROKEN  .github/skills/lua-api-design/snippets/extended-notes.md:41  [cag]  -> examples/method-section-header-8-space-indent.rs
  BROKEN  .github/skills/lua-api-design/snippets/extended-notes.md:45  [cag]  -> examples/docstring.rs
  BROKEN  .github/skills/lua-api-design/snippets/extended-notes.md:52  [cag]  -> examples/docstring-2.rs
  BROKEN  .github/skills/lua-api-design/snippets/extended-notes.md:56  [cag]  -> examples/6-register-section.rs
  BROKEN  .github/skills/lua-api-design/snippets/extended-notes.md:66  [cag]  -> examples/7-function-entry-pattern-4-space.rs
  BROKEN  .github/skills/lua-api-design/snippets/extended-notes.md:76  [cag]  -> examples/param-syntax.rs
  BROKEN  .github/skills/lua-api-design/snippets/extended-notes.md:80  [cag]  -> examples/return-syntax.rs
  BROKEN  .github/skills/lua-api-design/snippets/extended-notes.md:141  [cag]  -> examples/business-logic-migration-pattern.rs
  BROKEN  .github/skills/lua-api-design/snippets/extended-notes.md:144  [cag]  -> examples/business-logic-migration-pattern-2.rs
  BROKEN  .github/skills/lua-api-design/snippets/extended-notes.md:163  [cag]  -> snippets/validation.ps1
  BROKEN  .github/skills/lua-runtime/snippets/extended-notes.md:1  [cag]  -> examples/gc-pressure-reduction-applies-to-both.lua
  BROKEN  .github/skills/lua-runtime/snippets/extended-notes.md:17  [cag]  -> examples/upvalue-limit-workaround.lua
  BROKEN  .github/skills/lua-runtime/snippets/extended-notes.md:24  [cag]  -> examples/luajit-ffi.lua
  BROKEN  .github/skills/lua-runtime/snippets/extended-notes.md:37  [cag]  -> examples/local-caching-critical-for-hot-loops.lua
  BROKEN  .github/skills/lua-runtime/snippets/extended-notes.md:43  [cag]  -> examples/avoid-metatables-on-hot-paths.lua
  BROKEN  .github/skills/lua-runtime/snippets/extended-notes.md:49  [cag]  -> examples/string-interning.lua
  BROKEN  .github/skills/lua-rust-bridge/snippets/extended-notes.md:53  [cag]  -> examples/rendering-boundary-rule.rs
  BROKEN  .github/skills/lua-scripting/SKILL.md:39  [content]  -> content/demos/hello_world/main.lua
  BROKEN  .github/skills/lua-scripting/SKILL.md:40  [content]  -> content/demos/physics_demo/main.lua
  BROKEN  .github/skills/lua-scripting/SKILL.md:41  [content]  -> content/demos/sprites/main.lua
  BROKEN  .github/skills/lua-scripting/SKILL.md:42  [docs]  -> docs/API/lua_api_reference_generated.md
  BROKEN  .github/skills/lua-scripting/SKILL.md:51  [content]  -> content/demos/hello_world/main.lua
  BROKEN  .github/skills/module-audit/snippets/agent-md-canonical-format-short.md:26  [cag]  -> ../../docs/specs/<module>.md
  BROKEN  .github/skills/module-audit/snippets/extended-notes.md:1  [cag]  -> snippets/s-01-lib-rs-registration.txt
  BROKEN  .github/skills/module-audit/snippets/extended-notes.md:5  [cag]  -> snippets/s-02-mod-rs-simplicity.txt
  BROKEN  .github/skills/module-audit/snippets/extended-notes.md:9  [cag]  -> snippets/s-03-file-size-limits.txt
  BROKEN  .github/skills/module-audit/snippets/extended-notes.md:17  [cag]  -> snippets/d-01-d-05-docstring-checks.txt
  BROKEN  .github/skills/module-audit/snippets/extended-notes.md:21  [cag]  -> snippets/t-01-t-07-test-coverage.txt
  BROKEN  .github/skills/module-audit/snippets/extended-notes.md:25  [cag]  -> snippets/r-01-r-05-architecture-compliance.txt
  BROKEN  .github/skills/module-audit/snippets/extended-notes.md:29  [cag]  -> snippets/q-01-q-06-code-quality.txt
  BROKEN  .github/skills/module-audit/snippets/extended-notes.md:37  [cag]  -> snippets/python-validation-tool.ps1
  BROKEN  .github/skills/module-audit/snippets/extended-notes.md:44  [cag]  -> snippets/what-every-report-contains-docs-quality.txt
  BROKEN  .github/skills/module-audit/snippets/extended-notes.md:55  [cag]  -> snippets/step-1-generate-reports.ps1
  BROKEN  .github/skills/module-audit/snippets/extended-notes.md:118  [cag]  -> snippets/step-4-re-run-and-verify.ps1
  BROKEN  .github/skills/module-audit/snippets/extended-notes.md:125  [cag]  -> snippets/batch-fix-strategy.ps1
  BROKEN  .github/skills/module-audit/snippets/extended-notes.md:131  [cag]  -> snippets/report-template.txt
  BROKEN  .github/skills/module-audit/snippets/extended-notes.md:139  [cag]  -> snippets/batch-mode.txt
  BROKEN  .github/skills/performance-profiling/snippets/extended-notes.md:9  [src]  -> src/render/sprite_batch.rs
  BROKEN  .github/skills/performance-profiling/snippets/extended-notes.md:14  [src]  -> src/render/texture.rs
  BROKEN  .github/skills/performance-profiling/snippets/extended-notes.md:25  [cag]  -> examples/spritebatch-most-important.lua
  BROKEN  .github/skills/performance-profiling/snippets/extended-notes.md:38  [cag]  -> examples/lua-gc-pressure-reduction.lua
  BROKEN  .github/skills/performance-profiling/snippets/extended-notes.md:42  [cag]  -> examples/lua-gc-pressure-reduction-2.lua
  BROKEN  .github/skills/quality-pipeline/SKILL.md:58  [content]  -> content/demos/
  BROKEN  .github/skills/quality-pipeline/SKILL.md:77  [tools]  -> tools/audit/validate_agent_md.py
  BROKEN  .github/skills/quality-pipeline/snippets/extended-notes.md:16  [cag]  -> snippets/quick-check-before-any-commit.ps1
  BROKEN  .github/skills/quality-pipeline/snippets/extended-notes.md:20  [cag]  -> snippets/standard-pre-commit-sweep.ps1
  BROKEN  .github/skills/quality-pipeline/snippets/extended-notes.md:24  [cag]  -> snippets/single-module-deep-audit.ps1
  BROKEN  .github/skills/quality-pipeline/snippets/extended-notes.md:28  [cag]  -> snippets/full-project-quality-sweep.ps1
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:17  [cag]  -> examples/3-1-create-the-lua-file.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:20  [cag]  -> examples/3-1-create-the-lua-file-2.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:23  [cag]  -> examples/3-1-create-the-lua-file-3.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:26  [cag]  -> examples/3-1-create-the-lua-file-4.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:33  [cag]  -> examples/3-2-harness-registration.rs
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:41  [cag]  -> examples/test-structure.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:88  [cag]  -> examples/performance-and-golden-helpers.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:113  [cag]  -> examples/6-test-vm-helpers-rust-side.rs
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:121  [cag]  -> snippets/running-quality-gates.ps1
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:124  [cag]  -> snippets/analytics-tools.ps1
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:127  [cag]  -> snippets/adding-missing-docs.ps1
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:152  [cag]  -> snippets/rust-golden-tests-byte-level.ps1
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:158  [cag]  -> examples/lua-golden-tests-compare-only-files.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:174  [cag]  -> examples/syntax.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:187  [cag]  -> examples/syntax-2.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:190  [cag]  -> snippets/syntax-3.ps1
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:201  [cag]  -> examples/tier-1-headless-state-readback-preferred.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:207  [cag]  -> examples/tier-2-canvas-pixel-readback-headless.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:213  [cag]  -> examples/tier-3-runtime-smoke-tests-gpu.rs
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:234  [tests]  -> tests/rust/golden/actual/
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:248  [cag]  -> examples/syntax-4.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:261  [cag]  -> snippets/coverage-scanner.ps1
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:270  [cag]  -> examples/canvas-pixel-readback-headless.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:274  [cag]  -> examples/file-evidence.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:279  [cag]  -> examples/runtime-smoke-tests-gpu-required.rs
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:288  [cag]  -> examples/lua-golden-tests.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:303  [cag]  -> examples/stress-test-output-format.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:312  [cag]  -> examples/recognized-patterns.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:316  [cag]  -> examples/example-well-named-describe-blocks.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:373  [cag]  -> examples/evidence-tests-file-output-required.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:389  [cag]  -> examples/golden-tests-compare-only.lua
  BROKEN  .github/skills/testing-rust/snippets/extended-notes.md:395  [cag]  -> examples/covers-markers-required.lua
  BROKEN  .github/skills/threading/snippets/extended-notes.md:12  [cag]  -> examples/error-handling-in-workers.lua
  BROKEN  .github/skills/threading/snippets/extended-notes.md:14  [cag]  -> examples/error-handling-in-workers-2.lua
  BROKEN  .github/skills/threading/snippets/extended-notes.md:21  [cag]  -> examples/work-queue.lua
  BROKEN  .github/skills/threading/snippets/extended-notes.md:25  [cag]  -> examples/background-save.lua
  BROKEN  .github/skills/ui-layout/snippets/extended-notes.md:50  [cag]  -> templates/file-skeleton.toml
  BROKEN  .github/skills/ui-layout/snippets/extended-notes.md:63  [cag]  -> templates/field-ordering-convention-per-widget-block.toml
  BROKEN  .github/skills/ui-layout/snippets/extended-notes.md:70  [cag]  -> snippets/layout-hierarchy-godot-inspired-patterns.txt
  BROKEN  .github/skills/ui-layout/snippets/extended-notes.md:134  [cag]  -> templates/step-1-layout-toml-structure-only.toml
  BROKEN  .github/skills/ui-layout/snippets/extended-notes.md:138  [cag]  -> examples/step-2-lua-script-behaviour-only.lua
  BROKEN  .github/skills/visual-effects/snippets/extended-notes.md:6  [cag]  -> examples/cpu-side-image-filters-offline-load.lua
  BROKEN  .github/skills/visual-effects/snippets/extended-notes.md:23  [cag]  -> examples/performance-budget.lua
  BROKEN  .github/skills/vscode-extension/SKILL.md:56  [docs]  -> docs/API/lua_api_data.json
  BROKEN  .github/skills/vscode-extension/SKILL.md:76  [docs]  -> docs/API/lua_api_data.json

Files scanned: 134, links: 1261, broken: 271
Broken by category: cag=133, content=65, docs=40, src=4, tests=26, tools=3
