# P2 Baseline Violations Report

Captured immediately after the P2 validator+tools build, before any P3-P6 cleanup of agents/skills/prompts.

Used to bound regressions in subsequent phases via `python tools/validate/cag_validate.py --baseline`.

## 1. cag_validate.py (strict mode)

- Scanned: {'agent': 20, 'prompt': 45, 'skill': 32, 'system_prompt': 1}
- **Errors: 911** — **Warnings: 32**
- Violations by rule (descending):
  - `E201`: 450
  - `E305`: 203
  - `E205`: 190
  - `E107`: 60
  - `W108`: 20
  - `W005`: 12
  - `E001`: 5
  - `E002`: 1
  - `E003`: 1
  - `E106`: 1

## 2. cag_link_check.py

- Files scanned: 104, links extracted: 650
- **Broken: 153**
- Broken by category:
  - content: 63
  - docs: 44
  - src: 10
  - tests: 33
  - tools: 3

Examples (first 8):
  - .github/agents/developer.agent.md:118 -> `docs/wiki/Examples.md`
  - .github/agents/doc-writer.agent.md:2 -> `content/demos/`
  - .github/agents/doc-writer.agent.md:17 -> `content/demos/`
  - .github/agents/doc-writer.agent.md:88 -> `docs/API/lua_api_reference_generated.md`
  - .github/agents/lua-designer.agent.md:20 -> `content/demos/`
  - .github/agents/lua-designer.agent.md:22 -> `docs/API/lua_api_reference_generated.md`
  - .github/agents/lua-designer.agent.md:92 -> `content/demos/`
  - .github/agents/lua-designer.agent.md:93 -> `docs/API/lua_api_reference_generated.md`

## 3. cag_coverage.py

Full matrix: `data/p2_coverage.md`. Per-type coverage:

### agent (n=20)

| Field | Coverage |
|---|---:|
| `fm:loads_tools` | 0.0% |
| `fm:mission` | 0.0% |
| `fm:name` | 100.0% |
| `fm:personas` | 0.0% |
| `fm:primary_skills` | 0.0% |
| `fm:routes_to` | 0.0% |
| `fm:secondary_skills` | 0.0% |
| `sec:Anti-patterns` | 100.0% |
| `sec:Inputs` | 0.0% |
| `sec:Mission` | 100.0% |
| `sec:Outputs` | 0.0% |
| `sec:Routing Table` | 0.0% |
| `sec:Scope` | 100.0% |
| `sec:Workflow` | 100.0% |

### prompt (n=45)

| Field | Coverage |
|---|---:|
| `fm:description` | 100.0% |
| `fm:expected_agent` | 0.0% |
| `fm:inputs_required` | 0.0% |
| `fm:loads_skills` | 0.0% |
| `fm:loads_tools` | 0.0% |
| `fm:mode` | 0.0% |
| `sec:Anti-patterns` | 2.2% |
| `sec:Example Invocation` | 0.0% |
| `sec:Goal` | 2.2% |
| `sec:Inputs` | 64.4% |
| `sec:Steps` | 84.4% |
| `sec:Success Criteria` | 0.0% |

### skill (n=32)

| Field | Coverage |
|---|---:|
| `fm:companion_files` | 0.0% |
| `fm:description` | 100.0% |
| `fm:name` | 100.0% |
| `fm:related_skills` | 0.0% |
| `sec:Companion File Index` | 0.0% |
| `sec:Domain Knowledge` | 0.0% |
| `sec:Mission` | 3.1% |
| `sec:References` | 3.1% |
| `sec:When To Load` | 0.0% |
| `sec:When To Skip` | 0.0% |

### system_prompt (n=1)

| Field | Coverage |
|---|---:|
| `Binding Constraints` | 0.0% |
| `Cross-Artifact Sync` | 100.0% |
| `Discovery` | 0.0% |
| `Engine Identity` | 0.0% |
| `Quality Gates` | 0.0% |
| `Repository Layout` | 100.0% |

## 4. cag_persona_matrix.py

Full matrix: `data/p2_persona_matrix.md`.

| Persona | Agents declaring it |
|---|---:|
| `EngDev` | 0 |
| `EngTest` | 0 |
| `GameDev` | 0 |
| `GameTest` | 0 |
| `Modder` | 0 |
| `Player` | 0 |

- Agents with zero personas (W108): **20** (architect, audio-eng, cag-architect, configurator, debugger, developer, doc-writer, hacker, lua-designer, manager, optimizer, physicist, planner, player, renderer, research, reviewer, security, solver, tester)
- Personas with zero agents (gap): ['EngDev', 'EngTest', 'GameDev', 'GameTest', 'Modder', 'Player']
- Low-coverage personas (<3 agents): none

---

Baseline state: `tools/validate/cag_validate.baseline.json` (943 keys).  
Subsequent phases (P3 onwards) MUST NOT introduce new violation keys; the baseline is the floor, not the ceiling.