"""P5 orphan-skill prompt creator — adds 11 new prompts, one per orphan skill.

Each generated prompt follows the PROMPT_TEMPLATE structure: YAML frontmatter
plus six ordered body sections (Goal, Inputs, Steps, Success Criteria,
Anti-patterns, Example Invocation). Total length stays ≤80 lines.

Will not overwrite an existing file — exits with the count of files written.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PROMPTS_DIR = ROOT / ".github" / "prompts"
SKILLS_DIR = ROOT / ".github" / "skills"
AGENTS_DIR = ROOT / ".github" / "agents"

# (skill, filename, expected_agent, description, goal, inputs, extra_steps)
PROMPTS: list[dict] = [
    {
        "skill": "analytics",
        "file": "analyze-game-telemetry.prompt.md",
        "agent": "Research",
        "desc": "Parse log data and produce game telemetry analytics.",
        "goal": ("Analyse a Lurek2D log or session-event capture and produce a "
                 "structured analytics report — frame-time histogram, crash "
                 "frequency, top warning sources — that can drive balance or "
                 "performance follow-up."),
        "inputs": ["log_path", "report_focus"],
    },
    {
        "skill": "build-system",
        "file": "tune-cargo-build.prompt.md",
        "agent": "Developer",
        "desc": "Tune Cargo profiles, feature flags, and build outputs for Lurek2D.",
        "goal": ("Adjust Cargo profiles, feature flags, or the `build/` output "
                 "directory so a Lurek2D build target meets a stated size or "
                 "speed objective without regressing `cargo test`."),
        "inputs": ["target", "objective"],
    },
    {
        "skill": "cag-workflow",
        "file": "add-cag-artifact.prompt.md",
        "agent": "CAG-Architect",
        "desc": "Author a new agent, skill, or prompt following CAG standards.",
        "goal": ("Add a new agent, skill, or prompt under `.github/` that "
                 "conforms to the CAG standards in "
                 "`work/cag-system-overhaul-20260418/reports/standards/` and "
                 "passes `tools/validate/cag_validate.py` with no new errors."),
        "inputs": ["artifact_type", "name"],
    },
    {
        "skill": "ci-cd-pipeline",
        "file": "setup-ci-pipeline.prompt.md",
        "agent": "Developer",
        "desc": "Add or modify a GitHub Actions workflow for Lurek2D.",
        "goal": ("Add or update a `.github/workflows/*.yml` pipeline that runs "
                 "the requested job — tests, clippy, dist, docs — on the "
                 "named trigger."),
        "inputs": ["workflow_name", "trigger"],
    },
    {
        "skill": "game-ai",
        "file": "design-game-ai.prompt.md",
        "agent": "Developer",
        "desc": "Design FSM, BT, GOAP, or Utility AI for game actors via lurek.ai.",
        "goal": ("Design and implement an AI behaviour for a named actor "
                 "using the `lurek.ai.*` API — FSM, behaviour tree, GOAP "
                 "planner, steering, or utility AI — backed by a deterministic "
                 "Lua test."),
        "inputs": ["actor_name", "behaviour_kind"],
    },
    {
        "skill": "github-workflow",
        "file": "triage-github-issues.prompt.md",
        "agent": "Manager",
        "desc": "Triage and label GitHub issues using mcp_github_* tools.",
        "goal": ("Triage open GitHub issues for the Lurek2D repository — "
                 "apply correct labels, milestones, and routing — without "
                 "modifying issue bodies."),
        "inputs": ["repo", "label_filter"],
    },
    {
        "skill": "lua-runtime",
        "file": "tune-lua-runtime.prompt.md",
        "agent": "Optimizer",
        "desc": "Tune LuaJIT GC, FFI, or hot-path Lua patterns.",
        "goal": ("Reduce Lua-side per-frame cost in a named hot path by "
                 "tuning LuaJIT GC, FFI, or upvalue patterns and confirming "
                 "the change with a measurement."),
        "inputs": ["script_path", "objective"],
    },
    {
        "skill": "quality-pipeline",
        "file": "run-quality-sweep.prompt.md",
        "agent": "Reviewer",
        "desc": "Execute the audit-fix-verify quality sweep across the repo.",
        "goal": ("Run the audit-fix-verify quality sweep over the named "
                 "scope — modules, docs, tests, examples — and produce a "
                 "report listing remaining defects and the agents that own "
                 "them."),
        "inputs": ["scope"],
    },
    {
        "skill": "ui-layout",
        "file": "author-ui-layout.prompt.md",
        "agent": "Lua-Designer",
        "desc": "Author or edit a content/layouts/ TOML UI layout.",
        "goal": ("Author or edit a TOML UI layout under `content/layouts/` "
                 "for a named screen — grid-snapped coordinates, valid widget "
                 "types, renderable via `tools/ui/render_layout.py`."),
        "inputs": ["screen_name"],
    },
    {
        "skill": "visual-effects",
        "file": "add-visual-effect.prompt.md",
        "agent": "Renderer",
        "desc": "Add a post-processing visual effect (CRT, bloom, distortion, etc).",
        "goal": ("Implement a named full-screen post-processing effect using "
                 "the canvas render-to-texture pipeline plus a custom WGSL "
                 "fragment shader, with one `lurek.*` toggle and a Lua "
                 "evidence test."),
        "inputs": ["effect_name"],
    },
    {
        "skill": "vscode-extension",
        "file": "extend-vscode-extension.prompt.md",
        "agent": "Developer",
        "desc": "Add a command, completion, or webview to extensions/vscode/.",
        "goal": ("Add a new command, completion provider, or webview panel "
                 "to the first-party Lurek2D VS Code extension under "
                 "`extensions/vscode/` and rebuild the bundle."),
        "inputs": ["feature_kind", "feature_name"],
    },
]

LUA_GROUNDING_RE = re.compile(
    r"^(create|update|build|fix|flesh-out|implement|add)-.*"
    r"(demo|example|game|level|asset|tilemap|particle|sprite|"
    r"animation|sound|music|api-function|lua-api|audio-feature|"
    r"physics-feature|draw-command|ai-behavior|ai-behaviour|visual-effect)"
)
LUA_GROUNDING_STEP = (
    "Consult the actual `lurek.*` API surface via "
    "[docs/API/lua-api.md](docs/API/lua-api.md), "
    "[content/examples/](content/examples/), and "
    "[docs/specs/](docs/specs/). Do NOT invent APIs."
)


def yaml_inline_list(items: list[str]) -> str:
    if not items:
        return "[]"
    return "[" + ", ".join(items) + "]"


def build_prompt(spec: dict) -> str:
    name = spec["file"].removesuffix(".prompt.md")
    skill = spec["skill"]
    agent = spec["agent"]
    desc = spec["desc"]
    inputs = spec.get("inputs", [])

    steps: list[str] = []
    steps.append(f"Load [skill: {skill}](.github/skills/{skill}/SKILL.md) "
                 "before changing any files.")
    steps.append(f"Confirm every input listed in this prompt's frontmatter "
                 f"is present in the user invocation.")
    steps.append(f"Carry out the work as the `{agent}` agent, following the "
                 f"workflow in the loaded skill.")
    if LUA_GROUNDING_RE.match(name):
        steps.append(LUA_GROUNDING_STEP)
    steps.append("Run `python tools/validate/cag_validate.py` and the quality "
                 "gates listed in [skill: quality-pipeline]"
                 "(.github/skills/quality-pipeline/SKILL.md) before declaring "
                 "the prompt done.")
    steps.append("Add a `docs/CHANGELOG.md` entry under the current version.")

    success: list[str] = [
        "All artifacts named in Goal exist on disk.",
        "`python tools/validate/cag_validate.py` returns no new errors.",
        "`docs/CHANGELOG.md` has a new entry under the current version.",
    ]

    anti: list[str] = [
        "Skipping the skill-load step listed above.",
        "Running `git add .` instead of staging only files this prompt produced.",
    ]

    inputs_block: list[str] = []
    if not inputs:
        inputs_block.append("- (none) — this prompt takes no required arguments.")
    else:
        for arg in inputs:
            inputs_block.append(f"- `{arg}` — value supplied by the user invocation.")

    invocation = (f"> Run this prompt via VS Code Copilot Chat: "
                  f"`/{name}" +
                  ("".join(f" <{a}>" for a in inputs) if inputs else "") +
                  "`")

    fm = [
        "---",
        f"description: {json.dumps(desc, ensure_ascii=False)}",
        "mode: agent",
        f"loads_skills: [{skill}]",
        "loads_tools: [tools/validate/cag_validate.py]",
        f"expected_agent: {agent}",
        f"inputs_required: {yaml_inline_list(inputs)}",
        "---",
    ]

    title = name.replace("-", " ").title()

    body = [
        "",
        f"# {title}",
        "",
        "## Goal",
        "",
        spec["goal"],
        "",
        "## Inputs",
        "",
        *inputs_block,
        "",
        "## Steps",
        "",
        *[f"{i}. {s}" for i, s in enumerate(steps, start=1)],
        "",
        "## Success Criteria",
        "",
        *[f"- [ ] {s}" for s in success],
        "",
        "## Anti-patterns",
        "",
        *[f"- {s}" for s in anti],
        "",
        "## Example Invocation",
        "",
        invocation,
        "",
    ]

    return "\n".join(fm) + "\n" + "\n".join(body)


def main() -> int:
    written = 0
    skipped = 0
    for spec in PROMPTS:
        target = PROMPTS_DIR / spec["file"]
        skill_dir = SKILLS_DIR / spec["skill"]
        if not skill_dir.is_dir():
            print(f"  SKIP {spec['file']}: skill dir not found "
                  f".github/skills/{spec['skill']}/")
            skipped += 1
            continue
        if target.exists():
            print(f"  SKIP {spec['file']}: file already exists")
            skipped += 1
            continue
        text = build_prompt(spec)
        target.write_text(text, encoding="utf-8")
        line_count = text.count("\n") + 1
        print(f"  CREATE {spec['file']} ({line_count} lines, "
              f"agent={spec['agent']})")
        written += 1
    print()
    print("=" * 60)
    print(f"Created: {written}")
    print(f"Skipped: {skipped}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
