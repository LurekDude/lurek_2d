---
name: create-roadmap-phase
description: Create a new Lurek2D roadmap phase file with all required metadata, tasks, and acceptance gates.
---

# Create Roadmap Phase

## Purpose


## Load Skill First

Load `.github/skills/roadmap-planning/SKILL.md` before proceeding.

## Use When

- Planning a new engine feature that spans multiple tasks or agents
- Documenting a new strategic direction (platform target, tooling, IDE)
- Recording a design decision that will be implemented in multiple steps

## Do Not Use When

- The change is a single file fix or a small addition → just make the change
- The phase already exists and needs updating → use `workflow-update-roadmap-phase`

## Inputs

- `PHASE_TITLE` — descriptive title (e.g., "Gamepad Input Deep Parity")
- `GOAL_DESC` — one paragraph: what changes, why it matters
- `PRIORITY` — Critical | High | Medium | Low
- `DEPENDS_ON` — list of phase numbers this phase requires (or "Nothing")
- `SCOPE_ESTIMATE` — rough file count or "Large — requires discovery"

## Steps

### Step 1: Determine Phase Number

2. Assign the next sequential number (e.g., current max is 18 → new phase is 19)
3. Choose a slug: lowercase hyphenated, ≤4 words, describes the feature


### Step 2: Check Dependency Graph

1. For each phase listed in `DEPENDS_ON`, open that phase file
2. Verify it exists and its `Blocks:` field either already lists the new phase or needs updating
3. If the new phase is truly independent: `Depends On: Nothing`

### Step 3: Write Phase File

Use this skeleton exactly — fill every placeholder:

```markdown
# Phase N — PHASE_TITLE

> **Priority**: PRIORITY — one-line justification
> **Estimated Scope**: SCOPE_ESTIMATE
> **Depends On**: DEPENDS_ON
> **Blocks**: Nothing   ← update once downstream phases depend on this

---

## Goal

GOAL_DESC

---

## Current State Analysis

What exists today that this phase changes or extends. Use tables or bullets. Reference actual file paths from the repository.

---

## Implementation Tasks

### N.1 First Task Title

**File(s)**: `src/path/to/file.rs`, `src/lua_api/something_api.rs`

Description. Include code snippets (Rust struct or Lua API surface) when the shape is non-obvious.

**Agent**: Developer

### N.2 Second Task Title

**File(s)**: ...

Description.

**Agent**: Tester

---

## Acceptance Gates

1. `cargo build` succeeds
2. `cargo test` passes
3. Named Lua example runs end-to-end
4. `docs/architecture/engine-architecture.md` or relevant doc file updated
5. `cargo clippy -- -D warnings` passes
```

### Step 4: Update Reverse Pointers

For every phase listed in `Depends On`, open it and update its `Blocks:` line to include the new phase number.

### Step 5: Validate

```powershell
python tools/validate/cag_validate.py
```

CAG validation does not check roadmap files, but confirms no CAG breakage from this step.

## Outputs

- Updated `Blocks:` lines in dependency phases (if any)

## Acceptance

- [ ] File exists at correct path with correct numbering
- [ ] All frontmatter fields present (`Priority`, `Estimated Scope`, `Depends On`, `Blocks`)
- [ ] `## Goal`, `## Implementation Tasks`, `## Acceptance Gates` sections present
- [ ] Dependency phases have their `Blocks:` updated
- [ ] All acceptance gates are binary (pass/fail, not "looks good")
- [ ] Sub-task numbers use Phase N prefix (e.g., `### 19.1`, not `### 1.1`)
