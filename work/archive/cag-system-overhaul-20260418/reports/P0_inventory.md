# P0 Inventory — CAG Layer

_Generated: 2026-04-18 06:43 UTC_

## Summary

- Total CAG files: **99** (1 system prompt + 21 agent files + 32 skills + 45 prompts)
- Total lines: **13,746**
- Total size: **596,555 bytes (582.6 KB)**

| Type | Count | Lines (sum) | Lines (min/median/max) |
|---|---|---|---|
| System prompt | 1 | 297 | 297 / 297 / 297 |
| Agents | 21 | 2,631 | 96 / 124 / 213 |
| Skills (SKILL.md) | 32 | 6,767 | 42 / 194 / 825 |
| Prompts | 45 | 4,051 | 28 / 54 / 441 |

- Total fenced code blocks across SKILL.md files: **224** (target after P3: 0)

## System Prompt

| Path | Lines | Bytes | KB | Last modified |
|---|---|---|---|---|
| .github/copilot-instructions.md | 297 | 25477 | 24.9 | 2026-04-16 |

## Agents

| Path | Lines | Bytes | Modified | Frontmatter | Description len | Fences |
|---|---|---|---|---|---|---|
| .github/agents/architect.agent.md | 130 | 7341 | 2026-04-13 | no | 0 | 0 |
| .github/agents/audio-eng.agent.md | 101 | 5507 | 2026-04-13 | no | 0 | 0 |
| .github/agents/cag-architect.agent.md | 98 | 5336 | 2026-04-13 | no | 0 | 0 |
| .github/agents/configurator.agent.md | 155 | 7911 | 2026-04-13 | no | 0 | 1 |
| .github/agents/debugger.agent.md | 110 | 5897 | 2026-04-13 | no | 0 | 0 |
| .github/agents/developer.agent.md | 213 | 11434 | 2026-04-13 | no | 0 | 5 |
| .github/agents/doc-writer.agent.md | 102 | 6061 | 2026-04-13 | no | 0 | 0 |
| .github/agents/hacker.agent.md | 159 | 8093 | 2026-04-13 | no | 0 | 1 |
| .github/agents/lua-designer.agent.md | 102 | 5735 | 2026-04-13 | no | 0 | 0 |
| .github/agents/manager.agent.md | 150 | 8711 | 2026-04-13 | no | 0 | 2 |
| .github/agents/optimizer.agent.md | 96 | 4608 | 2026-04-13 | no | 0 | 0 |
| .github/agents/physicist.agent.md | 120 | 6825 | 2026-04-13 | no | 0 | 1 |
| .github/agents/planner.agent.md | 131 | 6658 | 2026-04-13 | no | 0 | 1 |
| .github/agents/player.agent.md | 124 | 7249 | 2026-04-13 | no | 0 | 0 |
| .github/agents/README.md | 132 | 9193 | 2026-04-13 | no | 0 | 0 |
| .github/agents/renderer.agent.md | 127 | 7605 | 2026-04-13 | no | 0 | 0 |
| .github/agents/research.agent.md | 98 | 5296 | 2026-04-13 | no | 0 | 0 |
| .github/agents/reviewer.agent.md | 127 | 6553 | 2026-04-13 | no | 0 | 0 |
| .github/agents/security.agent.md | 118 | 6828 | 2026-04-13 | no | 0 | 1 |
| .github/agents/solver.agent.md | 102 | 6185 | 2026-04-13 | no | 0 | 0 |
| .github/agents/tester.agent.md | 136 | 8251 | 2026-04-13 | no | 0 | 1 |

## Skills

| Path | Lines | Bytes | Modified | Frontmatter | Name field | Desc len | Fences | Companion files |
|---|---|---|---|---|---|---|---|---|
| .github/skills/agent-md/SKILL.md | 145 | 5744 | 2026-04-13 | no | — | 0 | 0 | — |
| .github/skills/analytics/SKILL.md | 238 | 7961 | 2026-04-13 | no | — | 0 | 10 | — |
| .github/skills/asset-pipeline/SKILL.md | 44 | 1827 | 2026-04-13 | no | — | 0 | 0 | — |
| .github/skills/build-system/SKILL.md | 261 | 9226 | 2026-04-13 | no | — | 0 | 11 | — |
| .github/skills/cag-workflow/SKILL.md | 195 | 7421 | 2026-04-13 | no | — | 0 | 5 | — |
| .github/skills/ci-cd-pipeline/SKILL.md | 44 | 1608 | 2026-04-13 | no | — | 0 | 0 | — |
| .github/skills/cross-platform/SKILL.md | 42 | 1776 | 2026-04-13 | no | — | 0 | 0 | — |
| .github/skills/demo-creation/SKILL.md | 301 | 11516 | 2026-04-13 | no | — | 0 | 12 | references |
| .github/skills/dev-debugging/SKILL.md | 180 | 6955 | 2026-04-13 | no | — | 0 | 8 | — |
| .github/skills/documentation/SKILL.md | 87 | 4672 | 2026-04-13 | no | — | 0 | 0 | — |
| .github/skills/error-handling/SKILL.md | 44 | 1932 | 2026-04-13 | no | — | 0 | 0 | — |
| .github/skills/examples-management/SKILL.md | 384 | 14433 | 2026-04-16 | no | — | 0 | 18 | — |
| .github/skills/game-ai/SKILL.md | 334 | 10471 | 2026-04-13 | no | — | 0 | 11 | — |
| .github/skills/github-workflow/SKILL.md | 138 | 4763 | 2026-04-13 | no | — | 0 | 3 | — |
| .github/skills/gpu-programming/SKILL.md | 192 | 7553 | 2026-04-13 | no | — | 0 | 8 | — |
| .github/skills/logging/SKILL.md | 216 | 7687 | 2026-04-13 | no | — | 0 | 8 | — |
| .github/skills/lua-api-design/SKILL.md | 414 | 13170 | 2026-04-13 | no | — | 0 | 18 | — |
| .github/skills/lua-runtime/SKILL.md | 247 | 8419 | 2026-04-13 | no | — | 0 | 11 | — |
| .github/skills/lua-rust-bridge/SKILL.md | 220 | 9436 | 2026-04-13 | no | — | 0 | 7 | — |
| .github/skills/lua-scripting/SKILL.md | 45 | 2119 | 2026-04-13 | no | — | 0 | 0 | — |
| .github/skills/module-architecture/SKILL.md | 48 | 2861 | 2026-04-13 | no | — | 0 | 0 | — |
| .github/skills/module-audit/SKILL.md | 417 | 16972 | 2026-04-13 | no | — | 0 | 15 | — |
| .github/skills/performance-profiling/SKILL.md | 210 | 6418 | 2026-04-13 | no | — | 0 | 8 | — |
| .github/skills/quality-pipeline/SKILL.md | 193 | 9255 | 2026-04-13 | no | — | 0 | 5 | — |
| .github/skills/roadmap-planning/SKILL.md | 97 | 4268 | 2026-04-13 | no | — | 0 | 0 | example_1.md, example_2.txt, example_3.md |
| .github/skills/rust-coding/SKILL.md | 99 | 5053 | 2026-04-13 | no | — | 0 | 1 | — |
| .github/skills/testing-rust/SKILL.md | 825 | 32597 | 2026-04-13 | no | — | 0 | 34 | — |
| .github/skills/threading/SKILL.md | 238 | 7295 | 2026-04-13 | no | — | 0 | 10 | — |
| .github/skills/tools-cag-validation/SKILL.md | 82 | 3546 | 2026-04-13 | no | — | 0 | 0 | — |
| .github/skills/ui-layout/SKILL.md | 436 | 17578 | 2026-04-16 | no | — | 0 | 6 | — |
| .github/skills/visual-effects/SKILL.md | 250 | 7632 | 2026-04-13 | no | — | 0 | 11 | — |
| .github/skills/vscode-extension/SKILL.md | 101 | 4118 | 2026-04-13 | no | — | 0 | 4 | — |

## Prompts

| Path | Lines | Bytes | Modified | Frontmatter | mode | tools | Desc len | Fences |
|---|---|---|---|---|---|---|---|---|
| .github/prompts/analyze-memory-usage.prompt.md | 54 | 2423 | 2026-04-13 | yes | — | — | 168 | 1 |
| .github/prompts/analyze-pathfinding-performance.prompt.md | 51 | 1987 | 2026-04-13 | no | — | — | 0 | 0 |
| .github/prompts/analyze-physics-performance.prompt.md | 47 | 2110 | 2026-04-13 | no | — | — | 0 | 0 |
| .github/prompts/analyze-render-performance.prompt.md | 29 | 772 | 2026-04-13 | yes | — | — | 111 | 0 |
| .github/prompts/analyze-roadmap-phase.prompt.md | 441 | 16215 | 2026-04-13 | no | — | — | 0 | 15 |
| .github/prompts/audit-module.prompt.md | 285 | 21760 | 2026-04-13 | no | — | — | 0 | 3 |
| .github/prompts/create-ai-behavior.prompt.md | 52 | 1931 | 2026-04-13 | no | — | — | 0 | 0 |
| .github/prompts/create-api-function.prompt.md | 60 | 1950 | 2026-04-13 | yes | — | — | 141 | 0 |
| .github/prompts/create-audio-feature.prompt.md | 60 | 2711 | 2026-04-13 | no | — | — | 0 | 1 |
| .github/prompts/create-demo.prompt.md | 148 | 6465 | 2026-04-13 | no | — | — | 0 | 4 |
| .github/prompts/create-draw-command.prompt.md | 37 | 993 | 2026-04-13 | yes | — | — | 86 | 0 |
| .github/prompts/create-engine-module.prompt.md | 57 | 1670 | 2026-04-13 | yes | — | — | 92 | 0 |
| .github/prompts/create-event-pattern.prompt.md | 46 | 1681 | 2026-04-13 | no | — | — | 0 | 0 |
| .github/prompts/create-game-example.prompt.md | 55 | 1578 | 2026-04-13 | yes | — | — | 105 | 0 |
| .github/prompts/create-integration-test.prompt.md | 55 | 2216 | 2026-04-13 | yes | — | — | 166 | 1 |
| .github/prompts/create-lua-example.prompt.md | 57 | 2511 | 2026-04-13 | no | — | — | 0 | 1 |
| .github/prompts/create-physics-feature.prompt.md | 37 | 1010 | 2026-04-13 | yes | — | — | 77 | 0 |
| .github/prompts/create-roadmap-phase.prompt.md | 126 | 3387 | 2026-04-13 | yes | — | — | 96 | 2 |
| .github/prompts/create-test-suite.prompt.md | 35 | 894 | 2026-04-13 | yes | — | — | 90 | 0 |
| .github/prompts/create-tilemap-feature.prompt.md | 49 | 2065 | 2026-04-13 | no | — | — | 0 | 0 |
| .github/prompts/design-api-surface.prompt.md | 55 | 2831 | 2026-04-13 | yes | — | — | 167 | 0 |
| .github/prompts/doc-api-reference.prompt.md | 54 | 2307 | 2026-04-13 | no | — | — | 0 | 0 |
| .github/prompts/fix-api-function.prompt.md | 35 | 767 | 2026-04-13 | yes | — | — | 85 | 0 |
| .github/prompts/fix-compilation-errors.prompt.md | 35 | 832 | 2026-04-13 | yes | — | — | 84 | 0 |
| .github/prompts/fix-dependency-issue.prompt.md | 33 | 845 | 2026-04-13 | yes | — | — | 101 | 0 |
| .github/prompts/fix-engine-bug.prompt.md | 37 | 945 | 2026-04-13 | yes | — | — | 89 | 0 |
| .github/prompts/fix-failing-tests.prompt.md | 34 | 720 | 2026-04-13 | yes | — | — | 85 | 0 |
| .github/prompts/fix-lua-error.prompt.md | 57 | 2767 | 2026-04-13 | no | — | — | 0 | 1 |
| .github/prompts/fix-threading-issue.prompt.md | 51 | 2106 | 2026-04-13 | no | — | — | 0 | 0 |
| .github/prompts/flesh-out-example.prompt.md | 322 | 14168 | 2026-04-16 | no | — | — | 0 | 11 |
| .github/prompts/generate-roadmap-phase-from-description.prompt.md | 172 | 8702 | 2026-04-13 | yes | — | — | 102 | 4 |
| .github/prompts/implement-lua-api-module.prompt.md | 195 | 7915 | 2026-04-13 | no | — | — | 0 | 7 |
| .github/prompts/implement-roadmap-phase.prompt.md | 412 | 15747 | 2026-04-13 | no | — | — | 0 | 8 |
| .github/prompts/op-build-release.prompt.md | 73 | 2419 | 2026-04-13 | yes | — | — | 155 | 1 |
| .github/prompts/review-api-consistency.prompt.md | 31 | 860 | 2026-04-13 | yes | — | — | 110 | 0 |
| .github/prompts/review-code-quality.prompt.md | 43 | 1179 | 2026-04-13 | yes | — | — | 102 | 0 |
| .github/prompts/review-entity-lifecycle.prompt.md | 50 | 1827 | 2026-04-13 | no | — | — | 0 | 0 |
| .github/prompts/review-module-deps.prompt.md | 29 | 879 | 2026-04-13 | yes | — | — | 100 | 0 |
| .github/prompts/review-security-audit.prompt.md | 56 | 2773 | 2026-04-13 | no | — | — | 0 | 0 |
| .github/prompts/review-unsafe-code.prompt.md | 28 | 738 | 2026-04-13 | yes | — | — | 93 | 0 |
| .github/prompts/run-cag-validation.prompt.md | 33 | 778 | 2026-04-13 | yes | — | — | 91 | 0 |
| .github/prompts/run-quality-gates.prompt.md | 33 | 676 | 2026-04-13 | yes | — | — | 69 | 0 |
| .github/prompts/workflow-feature-development.prompt.md | 182 | 11870 | 2026-04-15 | no | — | — | 0 | 0 |
| .github/prompts/workflow-release-check.prompt.md | 97 | 2515 | 2026-04-13 | yes | — | — | 148 | 8 |
| .github/prompts/workflow-update-roadmap-phase.prompt.md | 123 | 4024 | 2026-04-13 | yes | — | — | 88 | 3 |
