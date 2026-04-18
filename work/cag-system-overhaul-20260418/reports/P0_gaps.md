# P0 Gaps & Quality Issues

_Generated: 2026-04-18 06:43 UTC_

## 1. Orphan Skills (no inbound reference)

_None_

## 2. Orphan Agents (no inbound reference)

_None_

## 3. Broken Link Targets

- `.github/copilot-instructions.md` → `tools/gen_all_docs`
- `.github/agents/planner.agent.md` → `docs/lua_api_reference.md`
- `.github/skills/agent-md/SKILL.md` → `tools/audit/validate_agent_md.py`
- `.github/skills/analytics/SKILL.md` → `tools/session_analysis.py`
- `.github/skills/cag-workflow/SKILL.md` → `.github/skills/my-skill/SKILL.md`
- `.github/skills/module-audit/SKILL.md` → `.github/docs/specs/<module>.md`
- `.github/skills/quality-pipeline/SKILL.md` → `tools/audit/validate_agent_md.py`
- `.github/prompts/doc-api-reference.prompt.md` → `docs/API/lua_api_reference_generated.md`
- `.github/prompts/workflow-feature-development.prompt.md` → `tools/audit/validate_agent_md.py`

## 4. Prompt Clusters (potential duplicates)

| Prefix | Count | Members |
|---|---|---|
| `create-` | 14 | create-ai-behavior, create-api-function, create-audio-feature, create-demo, create-draw-command, create-engine-module, create-event-pattern, create-game-example, create-integration-test, create-lua-example, create-physics-feature, create-roadmap-phase, create-test-suite, create-tilemap-feature |
| `fix-` | 7 | fix-api-function, fix-compilation-errors, fix-dependency-issue, fix-engine-bug, fix-failing-tests, fix-lua-error, fix-threading-issue |
| `review-` | 6 | review-api-consistency, review-code-quality, review-entity-lifecycle, review-module-deps, review-security-audit, review-unsafe-code |
| `analyze-` | 5 | analyze-memory-usage, analyze-pathfinding-performance, analyze-physics-performance, analyze-render-performance, analyze-roadmap-phase |
| `workflow-` | 3 | workflow-feature-development, workflow-release-check, workflow-update-roadmap-phase |
| `implement-` | 2 | implement-lua-api-module, implement-roadmap-phase |
| `run-` | 2 | run-cag-validation, run-quality-gates |

## 5. Skills Not Referenced by Any Prompt

- `analytics` — consider authoring a prompt that loads it
- `build-system` — consider authoring a prompt that loads it
- `cag-workflow` — consider authoring a prompt that loads it
- `ci-cd-pipeline` — consider authoring a prompt that loads it
- `game-ai` — consider authoring a prompt that loads it
- `github-workflow` — consider authoring a prompt that loads it
- `lua-runtime` — consider authoring a prompt that loads it
- `quality-pipeline` — consider authoring a prompt that loads it
- `ui-layout` — consider authoring a prompt that loads it
- `visual-effects` — consider authoring a prompt that loads it
- `vscode-extension` — consider authoring a prompt that loads it

## 6. Tool References vs Filesystem

- Tools mentioned in CAG: **37**
- Mentioned but missing on disk: **3**
  - `tools/audit/validate_agent_md.py`
  - `tools/gen_all_docs`
  - `tools/session_analysis.py`
- Tool scripts on disk but never referenced in CAG: **40**
  - `tools/audit/annotate_tests.py`
  - `tools/audit/count_gaps.py`
  - `tools/audit/gen_coverage_gaps.py`
  - `tools/audit/golden_test.py`
  - `tools/audit/module_audit.py`
  - `tools/audit/parse_test_log.py`
  - `tools/audit/stress_report.py`
  - `tools/audit/unit_test_api_coverage.py`
  - `tools/demos/organize_demos.py`
  - `tools/dev/test_fix_loop.py`
  - `tools/dist/pack.ps1`
  - `tools/dist/pack.py`
  - `tools/docs/gen_docs_rust.py`
  - `tools/docs/gen_engine_docs.py`
  - `tools/docs/gen_lib_docs.py`
  - `tools/docs/gen_lua_dev_docs.py`
  - `tools/docs/gen_lua_library_api.py`
  - `tools/docs/gen_luadoc.py`
  - `tools/docs/gen_rust_api_data.py`
  - `tools/docs/gen_test_docs.py`
  - `tools/docs/gen_wiki.py`
  - `tools/fix/add_lua_docstrings.py`
  - `tools/fix/add_lua_docstrings_auto.py`
  - `tools/fix/add_test_markers.py`
  - `tools/fix/docstring_fix.py`
  - `tools/fix/expand_examples.py`
  - `tools/fix/find_typed_params.py`
  - `tools/fix/fix_docstrings.py`
  - `tools/fix/fix_thread_api.py`
  - `tools/fix/fix_type_stub_vars.py`
  - …and 10 more

## 7. Frontmatter Consistency

- Agents with YAML frontmatter: **0 / 21**
- Skills with YAML frontmatter: **0 / 32**
- Prompts with YAML frontmatter: **26 / 45**

## 8. System Prompt Bloat

- System prompt: **297 lines / 24.9 KB** (target ≤120 lines, ≤8 KB)
- Inline skill name mentions in system prompt: **32 / 32**
- Inline agent name mentions in system prompt: **19 / 20**
- Recommendation: replace skill catalog and agent table with discovery references in P3/P5.

## 9. Skills With Fenced Code Blocks (extract to companion files in P3)

Total: **22 / 32 skills**, **224 blocks** total.

| Skill | Fences | Existing companion files |
|---|---|---|
| `.github/skills/testing-rust/SKILL.md` | 34 | — |
| `.github/skills/examples-management/SKILL.md` | 18 | — |
| `.github/skills/lua-api-design/SKILL.md` | 18 | — |
| `.github/skills/module-audit/SKILL.md` | 15 | — |
| `.github/skills/demo-creation/SKILL.md` | 12 | references |
| `.github/skills/build-system/SKILL.md` | 11 | — |
| `.github/skills/game-ai/SKILL.md` | 11 | — |
| `.github/skills/lua-runtime/SKILL.md` | 11 | — |
| `.github/skills/visual-effects/SKILL.md` | 11 | — |
| `.github/skills/analytics/SKILL.md` | 10 | — |
| `.github/skills/threading/SKILL.md` | 10 | — |
| `.github/skills/dev-debugging/SKILL.md` | 8 | — |
| `.github/skills/gpu-programming/SKILL.md` | 8 | — |
| `.github/skills/logging/SKILL.md` | 8 | — |
| `.github/skills/performance-profiling/SKILL.md` | 8 | — |
| `.github/skills/lua-rust-bridge/SKILL.md` | 7 | — |
| `.github/skills/ui-layout/SKILL.md` | 6 | — |
| `.github/skills/cag-workflow/SKILL.md` | 5 | — |
| `.github/skills/quality-pipeline/SKILL.md` | 5 | — |
| `.github/skills/vscode-extension/SKILL.md` | 4 | — |
| `.github/skills/github-workflow/SKILL.md` | 3 | — |
| `.github/skills/rust-coding/SKILL.md` | 1 | — |
