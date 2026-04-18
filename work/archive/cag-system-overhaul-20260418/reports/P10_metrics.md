# P10 Metrics — Before vs After

Baselines from P0 audit (commit `673c244`, 2026-04-18). After numbers from this strict P10 sweep on commit `8c56624`.

| Metric | Before (P0 baseline) | After (P10) | Delta |
|---|---|---|---|
| Total CAG validation errors | 911 | 0 | **−911** |
| Total CAG validation warnings | 32 | 0 | **−32** |
| Fenced code blocks in `SKILL.md` | 224 | 0 | **−224** |
| Broken links in `.github/` | 153 | 202 | **+49** ⚠️ (companion overflow auto-extraction; user-facing artefacts clean) |
| System prompt lines | 297 | 57 | **−240** (−81%) |
| System prompt bytes | 24,985 | 6,302 | **−18,683** (−75%) |
| Skills with companion files | 0 | 25 / 33 | **+25** |
| Total companion files | 0 | 250 | **+250** |
| Agents with frontmatter | 0 | 20 / 20 | **+20** |
| Skills with frontmatter | 0 | 33 / 33 | **+33** |
| Prompts with frontmatter | 0 | 56 / 56 | **+56** |
| Persona × agent matrix coverage | 0 / 6 personas covered | 6 / 6 covered | **+6** (Player at 1 agent — deliberate, others ≥4) |
| Total CAG files (`.github/**` Markdown + companions) | 1 (system prompt) + 20 agents + 33 SKILL.md + 45 prompts = 99 | 1 + 20 + 33 + 56 + 250 companions = 360 | **+261** (+250 extracted companions, +11 new orphan-skill prompts in P5) |

## Validator scope confirmation

```
Scanned: system_prompt=1 agents=20 skills=33 prompts=56
Summary: 0 errors, 0 warnings
```

Per-type passes (each independently):

- `--type system_prompt` → 0/0
- `--type agent` → 0/0
- `--type skill` → 0/0
- `--type prompt` → 0/0

## Coverage detail (cag_coverage.py --type all)

| File type | Field/Section | Coverage |
|-----------|---------------|----------|
| system_prompt | All required sections | 100.0 % |
| agent | All required frontmatter + sections | 100.0 % |
| skill | All required frontmatter + sections | 100.0 % (optional `fm:related_skills` 3.0 %) |
| prompt | All required frontmatter + sections | 100.0 % (optional fields: `loads_skills` 89.3 %, `loads_tools` 39.3 %, `inputs_required` 64.3 %) |

## Persona matrix (cag_persona_matrix.py)

| Persona | Agents serving |
|---------|---:|
| EngDev | 16 |
| GameDev | 12 |
| Modder | 4 |
| Player | 1 |
| GameTest | 5 |
| EngTest | 5 |

Agents declaring 0 personas: **(none)** → W108 = 0.

## Top three deltas

1. **Validator violations 943 → 0** (−943; 911 errors + 32 warnings cleared across P3/P4/P5/P6).
2. **System prompt 25 KB → 6.3 KB** (−75 %), now a discovery index instead of an inline roster.
3. **Companion files 0 → 250** across 25 skills, with `SKILL.md` fenced-block count 224 → 0.
