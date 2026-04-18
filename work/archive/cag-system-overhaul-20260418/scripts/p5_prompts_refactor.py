"""P5 prompts refactor — bulk-rewrite .github/prompts/*.prompt.md to the
PROMPT_TEMPLATE structure: YAML frontmatter (description, mode, loads_skills,
loads_tools, expected_agent, inputs_required) + 6 ordered body sections
(Goal, Inputs, Steps, Success Criteria, Anti-patterns, Example Invocation).

Session-scoped (work/cag-system-overhaul-20260418/scripts/).

Heuristics:
- Existing body content is parsed by markdown ## headings; matching content is
  routed to the new section that best fits.
- Missing sections are synthesized from prompt name + nearby content.
- Broken targets (deleted tools, typos) are fixed via string replacement.
- Skills/tools/agents are validated against the actual filesystem; unknown ones
  are dropped from the frontmatter (so E302/E303/E304 do not regress).
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
TOOLS_DIR = ROOT / "tools"

FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
INPUT_RE = re.compile(r"\$\{input:([a-zA-Z_][\w\-]*)\}|<([a-zA-Z_][\w\-]*)>")
TOOL_PATH_RE = re.compile(r"\btools/[A-Za-z0-9_./\-]+\.(?:py|ps1|sh|bat)\b")
SKILL_NAME_RE = re.compile(r"\b([a-z][a-z0-9\-]+)\b")

# ---- Broken target fixes (string replace across body before parsing) --------

BROKEN_TARGET_FIXES: list[tuple[str, str]] = [
    # Path or name typos
    ("tools/gen_all_docs.py", "tools/gen_all_docs.py"),  # canonical, no-op
    ("tools/gen_all_docs ", "tools/gen_all_docs.py "),
    ("tools/gen_all_docs)", "tools/gen_all_docs.py)"),
    ("tools/gen_all_docs`", "tools/gen_all_docs.py`"),
    ("docs/lua_api_reference.md", "docs/API/lua-api.md"),
    ("docs/API/lua_api_reference_generated.md", "docs/API/lua-api.md"),
    ("tools/docs/gen_lua_api.py", "tools/docs/gen_docs_lua.py"),
]

# Lines (regex) to strip entirely from body — references to deleted artifacts
BROKEN_LINE_PATTERNS: list[re.Pattern] = [
    re.compile(r".*tools/audit/validate_agent_md\.py.*"),
    re.compile(r".*\.github/skills/my-skill/SKILL\.md.*"),
]

# ---- Expected-agent heuristics by filename pattern --------------------------

AGENT_RULES: list[tuple[re.Pattern, str]] = [
    (re.compile(r"^create-(demo|game-example|lua-example|tilemap|api-function|"
                r"audio-feature|physics-feature|ai-behavior|draw-command|"
                r"event-pattern|engine-module)"), "Developer"),
    (re.compile(r"^create-integration-test|^create-test-suite"), "Tester"),
    (re.compile(r"^create-roadmap-phase|^generate-roadmap-phase|"
                r"^analyze-roadmap-phase|^workflow-update-roadmap-phase|"
                r"^implement-roadmap-phase"), "Architect"),
    (re.compile(r"^design-api-surface|^review-api-consistency"), "Lua-Designer"),
    (re.compile(r"^implement-lua-api-module"), "Lua-Designer"),
    (re.compile(r"^fix-failing-tests"), "Tester"),
    (re.compile(r"^fix-(compilation|dependency)"), "Developer"),
    (re.compile(r"^fix-engine-bug|^fix-api-function"), "Developer"),
    (re.compile(r"^fix-lua-error"), "Debugger"),
    (re.compile(r"^fix-threading-issue"), "Debugger"),
    (re.compile(r"^review-security-audit"), "Security"),
    (re.compile(r"^review-unsafe-code"), "Security"),
    (re.compile(r"^review-module-deps"), "Architect"),
    (re.compile(r"^review-entity-lifecycle"), "Reviewer"),
    (re.compile(r"^review-code-quality"), "Reviewer"),
    (re.compile(r"^audit-module"), "Reviewer"),
    (re.compile(r"^analyze-render-performance"), "Renderer"),
    (re.compile(r"^analyze-physics-performance"), "Physicist"),
    (re.compile(r"^analyze-(memory|pathfinding)-performance"), "Optimizer"),
    (re.compile(r"^analyze-.*-performance"), "Optimizer"),
    (re.compile(r"^debug-"), "Debugger"),
    (re.compile(r"^doc-"), "Doc-Writer"),
    (re.compile(r"^op-build-release"), "Developer"),
    (re.compile(r"^run-cag-validation"), "CAG-Architect"),
    (re.compile(r"^run-quality-gates"), "Reviewer"),
    (re.compile(r"^workflow-feature-development"), "Manager"),
    (re.compile(r"^workflow-release-check"), "Manager"),
    (re.compile(r"^flesh-out-example"), "Developer"),
]
DEFAULT_AGENT = "Developer"

# Lua API grounding step targets (filename pattern)
LUA_GROUNDING_RE = re.compile(
    r"^(create|update|build|fix|flesh-out|implement)-.*"
    r"(demo|example|game|level|asset|tilemap|particle|sprite|"
    r"animation|sound|music|api-function|lua-api|audio-feature|"
    r"physics-feature|draw-command|ai-behavior)"
)

LUA_GROUNDING_STEP = (
    "Consult the actual `lurek.*` API surface via "
    "[docs/API/lua-api.md](docs/API/lua-api.md), "
    "[content/examples/](content/examples/), and "
    "[docs/specs/](docs/specs/). Do NOT invent APIs."
)

# ---- Helpers ----------------------------------------------------------------


def discover_skills() -> set[str]:
    return {p.name for p in SKILLS_DIR.iterdir() if p.is_dir()}


def discover_agents() -> set[str]:
    """Return canonical agent display names derived from filenames.

    Filename `lua-designer.agent.md` → `Lua-Designer`.
    The validator normalises lowercased+kebab so any case form works, but we
    keep the canonical display form for readability in frontmatter.
    """
    names = set()
    for p in AGENTS_DIR.glob("*.agent.md"):
        stem = p.name.removesuffix(".agent.md")
        canonical = "-".join(part.capitalize() for part in stem.split("-"))
        names.add(canonical)
    return names


def parse_frontmatter(text: str) -> tuple[dict, str]:
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}, text
    yaml_text = m.group(1)
    body = text[m.end():]
    fields: dict[str, object] = {}
    cur_key = None
    for ln in yaml_text.split("\n"):
        if not ln.strip():
            continue
        m2 = re.match(r"^([a-zA-Z_]\w*):\s*(.*)$", ln)
        if m2:
            cur_key = m2.group(1)
            val = m2.group(2).strip()
            fields[cur_key] = val
        elif cur_key and (ln.startswith("  -") or ln.startswith("-")):
            existing = fields.get(cur_key)
            item = ln.lstrip(" -").strip()
            if isinstance(existing, list):
                existing.append(item)
            else:
                fields[cur_key] = [item] if not existing else [str(existing), item]
    return fields, body


def apply_broken_target_fixes(body: str) -> tuple[str, int]:
    fixes = 0
    for old, new in BROKEN_TARGET_FIXES:
        if old != new and old in body:
            body = body.replace(old, new)
            fixes += body.count(new)
    out_lines = []
    for ln in body.split("\n"):
        drop = False
        for pat in BROKEN_LINE_PATTERNS:
            if pat.match(ln):
                drop = True
                fixes += 1
                break
        if not drop:
            out_lines.append(ln)
    return "\n".join(out_lines), fixes


def split_sections(body: str) -> tuple[str, list[tuple[str, str]]]:
    """Return (intro_text, [(heading_lower, full_text)])."""
    sections: list[tuple[str, list[str]]] = []
    intro: list[str] = []
    cur_h: str | None = None
    cur: list[str] = []
    for ln in body.split("\n"):
        m = re.match(r"^##\s+(.+?)\s*$", ln)
        if m:
            if cur_h is None:
                intro = cur
            else:
                sections.append((cur_h, cur))
            cur_h = m.group(1).strip()
            cur = []
        else:
            cur.append(ln)
    if cur_h is None:
        intro = cur
    else:
        sections.append((cur_h, cur))
    intro_text = "\n".join(intro).strip()
    intro_text = re.sub(r"^#\s+.*\n?", "", intro_text).strip()
    return intro_text, [(h.lower(), "\n".join(lines).strip("\n")) for h, lines in sections]


def find_section_text(sections, *names) -> str | None:
    lower = {n.lower() for n in names}
    for h, txt in sections:
        if any(n in h for n in lower):
            return txt
    return None


def extract_inputs_from_body(body: str, fm: dict) -> list[str]:
    found: set[str] = set()
    for m in INPUT_RE.finditer(body):
        name = m.group(1) or m.group(2)
        if name and not name.startswith(("h", "br", "p", "div", "span")):
            found.add(name)
    # Also scan an existing 'argument-hint' or inputs-named frontmatter
    for key in ("inputs_required", "argument-hint", "inputs"):
        v = fm.get(key)
        if isinstance(v, str):
            for m in re.finditer(r"[A-Za-z_][\w\-]+", v):
                found.add(m.group(0))
        elif isinstance(v, list):
            for item in v:
                for m in re.finditer(r"[A-Za-z_][\w\-]+", str(item)):
                    found.add(m.group(0))
    cleaned = sorted({s for s in found if 2 <= len(s) <= 32 and s.lower() not in
                      {"true", "false", "none", "yes", "no", "agent", "ask"}})
    return cleaned


def detect_loads_skills(body: str, skills: set[str]) -> list[str]:
    found: set[str] = set()
    for s in skills:
        if re.search(rf"\b{re.escape(s)}\b", body):
            found.add(s)
    return sorted(found)


def detect_loads_tools(body: str) -> list[str]:
    found: set[str] = set()
    for m in TOOL_PATH_RE.finditer(body):
        path = m.group(0)
        if (ROOT / path).exists():
            found.add(path)
    return sorted(found)


def derive_expected_agent(name: str, fm: dict, agents: set[str]) -> str:
    existing = fm.get("expected_agent")
    if isinstance(existing, str) and existing.strip():
        norm = existing.strip()
        if norm in agents or norm == "Manager":
            return norm
    for pat, agent in AGENT_RULES:
        if pat.search(name):
            if agent in agents or agent == "Manager":
                return agent
    return DEFAULT_AGENT


def derive_description(name: str, fm: dict, intro: str) -> str:
    raw = fm.get("description")
    desc = ""
    if isinstance(raw, str):
        desc = raw.strip().strip('"').strip("'")
    if not desc and intro:
        desc = intro.split("\n")[0].strip().strip(".")
    if not desc:
        verb_noun = name.replace(".prompt", "").replace("-", " ").strip()
        desc = f"Prompt: {verb_noun}"
    desc = re.sub(r"\s+", " ", desc).strip()
    if len(desc) > 140:
        desc = desc[:137].rstrip() + "..."
    if not desc.endswith("."):
        desc += "."
    return desc


def yaml_inline_list(items: list[str]) -> str:
    if not items:
        return "[]"
    return "[" + ", ".join(items) + "]"


def yaml_str(s: str) -> str:
    return json.dumps(s, ensure_ascii=False)


# ---- Section synthesizers ---------------------------------------------------


def build_goal(name: str, fm_desc: str, sections) -> str:
    txt = (find_section_text(sections, "goal", "purpose", "objective", "summary")
           or "")
    if txt:
        # take first paragraph
        para = txt.split("\n\n")[0].strip()
        if para and len(para) > 30:
            return para
    # fallback: use description
    return (f"{fm_desc} The prompt finishes when every Success Criteria item "
            f"below is checked.")


def build_inputs(inputs: list[str], sections) -> str:
    txt = find_section_text(sections, "inputs", "input")
    if txt and txt.strip().startswith(("-", "*", "|")):
        return txt
    if not inputs:
        return "- (none) — this prompt takes no required arguments."
    bullets = []
    for arg in inputs:
        bullets.append(f"- `{arg}` — value supplied by the user invocation.")
    return "\n".join(bullets)


def build_steps(name: str, sections, expected_agent: str,
                loads_skills: list[str]) -> str:
    txt = (find_section_text(sections, "steps", "procedure", "instructions",
                              "what to do", "workflow", "process")
           or "")
    raw_lines: list[str] = []
    if txt:
        for ln in txt.split("\n"):
            raw_lines.append(ln)
    else:
        # Synthesize from any other body content
        body_chunks = []
        for h, t in sections:
            if h in {"goal", "purpose", "inputs", "input", "success criteria",
                     "acceptance", "acceptance criteria", "anti-patterns",
                     "example invocation", "example", "examples", "examples of invocation",
                     "outputs", "output", "references", "see also"}:
                continue
            body_chunks.append(t)
        raw_lines = ("\n".join(body_chunks)).split("\n")

    # Promote bullet/numbered items to numbered Steps; keep prose as supporting text
    items: list[str] = []
    skill_step_added = False
    for ln in raw_lines:
        s = ln.strip()
        if not s:
            continue
        m = re.match(r"^\d+[\.\)]\s+(.*)$", s)
        if m:
            items.append(m.group(1).strip())
            continue
        m = re.match(r"^[\-\*]\s+(.*)$", s)
        if m:
            items.append(m.group(1).strip())
            continue
        # Drop pure prose (we keep only actionable bullets to avoid noise)
    if not items:
        items = [
            f"Read this prompt's Inputs and confirm every required argument is present.",
            f"Load any skill listed in `loads_skills` of this prompt's frontmatter.",
            f"Execute the work as the `{expected_agent}` agent.",
            "Run the relevant quality gates from the [skill: quality-pipeline]"
            "(.github/skills/quality-pipeline/SKILL.md) before declaring done.",
        ]

    # Prepend explicit skill-load step if loads_skills present and not already there
    if loads_skills:
        link_list = ", ".join(
            f"[skill: {s}](.github/skills/{s}/SKILL.md)" for s in loads_skills
        )
        items.insert(0, f"Load {link_list} before changing any files.")

    # Lua API grounding for content-creation prompts
    if LUA_GROUNDING_RE.match(name):
        if not any("lurek.*" in it for it in items):
            items.append(LUA_GROUNDING_STEP)

    # Limit to 12 numbered steps
    if len(items) > 12:
        items = items[:12]

    return "\n".join(f"{i}. {s}" for i, s in enumerate(items, start=1))


def build_success_criteria(sections, expected_agent: str) -> str:
    txt = (find_section_text(sections, "success criteria", "acceptance",
                              "acceptance criteria", "definition of done",
                              "done when", "outputs")
           or "")
    items: list[str] = []
    for ln in txt.split("\n"):
        s = ln.strip()
        m = re.match(r"^[\-\*]\s*\[[ xX]\]\s*(.*)$", s)
        if m:
            items.append(m.group(1).strip())
            continue
        m = re.match(r"^[\-\*]\s+(.*)$", s)
        if m:
            items.append(m.group(1).strip())
    if not items:
        items = [
            f"The `{expected_agent}` agent has produced the artifacts named in Goal.",
            "`python tools/validate/cag_validate.py` returns no new errors.",
        ]
    if len(items) > 12:
        items = items[:12]
    return "\n".join(f"- [ ] {it}" for it in items if it)


def build_anti_patterns(sections) -> str:
    txt = (find_section_text(sections, "anti-patterns", "anti patterns",
                              "avoid", "do not", "don't", "pitfalls")
           or "")
    items: list[str] = []
    for ln in txt.split("\n"):
        s = ln.strip()
        m = re.match(r"^[\-\*]\s+(.*)$", s)
        if m:
            items.append(m.group(1).strip())
    if not items:
        items = [
            "Skipping the Success Criteria check before declaring the prompt done.",
            "Running `git add .` instead of staging only the files this prompt produced.",
        ]
    return "\n".join(f"- {it}" for it in items if it)


def build_example_invocation(name: str, sections, inputs: list[str]) -> str:
    txt = (find_section_text(sections, "example invocation", "example",
                              "examples", "examples of invocation", "usage")
           or "")
    if txt and ("/" in txt or "@" in txt or "`" in txt):
        # Keep it but strip headings
        return txt.strip()
    base = f"/{name.removesuffix('.prompt.md')}"
    if inputs:
        arg_str = " ".join(f"<{a}>" for a in inputs)
        return f"> Run this prompt via VS Code Copilot Chat: `{base} {arg_str}`"
    return f"> Run this prompt via VS Code Copilot Chat: `{base}`"


# ---- Assembly ---------------------------------------------------------------


def assemble_file(name_full: str, fm: dict, body: str,
                  skills: set[str], agents: set[str]) -> tuple[str, dict]:
    name = name_full.removesuffix(".prompt.md")
    body, broken_fixes = apply_broken_target_fixes(body)
    intro, sections = split_sections(body)

    description = derive_description(name, fm, intro)
    inputs = extract_inputs_from_body(body, fm)
    expected_agent = derive_expected_agent(name, fm, agents)

    # loads_skills/loads_tools — start from existing frontmatter, fall back to scan
    raw_skills = fm.get("loads_skills")
    if isinstance(raw_skills, list):
        existing_skills = [s.strip().strip('"\'[],') for s in raw_skills]
    elif isinstance(raw_skills, str):
        existing_skills = [s.strip().strip('"\'') for s in
                           re.findall(r"[a-z][a-z0-9\-]+", raw_skills)]
    else:
        existing_skills = []
    body_skills = detect_loads_skills(body, skills)
    loads_skills = sorted({s for s in (existing_skills + body_skills) if s in skills})

    raw_tools = fm.get("loads_tools")
    if isinstance(raw_tools, list):
        existing_tools = [t.strip().strip('"\'[],') for t in raw_tools]
    elif isinstance(raw_tools, str):
        existing_tools = [t.strip().strip('"\'') for t in
                          re.findall(r"tools/[A-Za-z0-9_./\-]+\.\w+", raw_tools)]
    else:
        existing_tools = []
    body_tools = detect_loads_tools(body)
    loads_tools = sorted({t for t in (existing_tools + body_tools)
                          if (ROOT / t).exists()})

    mode = fm.get("mode")
    if not isinstance(mode, str) or not mode.strip():
        mode = "agent"
    elif mode.strip().lower() not in {"agent", "ask", "edit"}:
        mode = "agent"

    goal_section = build_goal(name, description, sections)
    inputs_section = build_inputs(inputs, sections)
    steps_section = build_steps(name, sections, expected_agent, loads_skills)
    sc_section = build_success_criteria(sections, expected_agent)
    ap_section = build_anti_patterns(sections)
    ex_section = build_example_invocation(name_full, sections, inputs)

    fm_lines = ["---"]
    fm_lines.append(f"description: {yaml_str(description)}")
    fm_lines.append(f"mode: {mode}")
    fm_lines.append(f"loads_skills: {yaml_inline_list(loads_skills)}")
    fm_lines.append(f"loads_tools: {yaml_inline_list(loads_tools)}")
    fm_lines.append(f"expected_agent: {expected_agent}")
    fm_lines.append(f"inputs_required: {yaml_inline_list(inputs)}")
    fm_lines.append("---")

    title = name.replace("-", " ").title()
    body_out = []
    body_out.append("")
    body_out.append(f"# {title}")
    body_out.append("")
    body_out.append("## Goal")
    body_out.append("")
    body_out.append(goal_section)
    body_out.append("")
    body_out.append("## Inputs")
    body_out.append("")
    body_out.append(inputs_section)
    body_out.append("")
    body_out.append("## Steps")
    body_out.append("")
    body_out.append(steps_section)
    body_out.append("")
    body_out.append("## Success Criteria")
    body_out.append("")
    body_out.append(sc_section)
    body_out.append("")
    body_out.append("## Anti-patterns")
    body_out.append("")
    body_out.append(ap_section)
    body_out.append("")
    body_out.append("## Example Invocation")
    body_out.append("")
    body_out.append(ex_section)
    body_out.append("")

    text = "\n".join(fm_lines) + "\n" + "\n".join(body_out)
    summary = {
        "name": name_full,
        "description": description,
        "expected_agent": expected_agent,
        "loads_skills": len(loads_skills),
        "loads_tools": len(loads_tools),
        "inputs_required": len(inputs),
        "broken_fixes": broken_fixes,
    }
    return text, summary


# ---- Driver -----------------------------------------------------------------


def main() -> int:
    if not PROMPTS_DIR.is_dir():
        print(f"ERROR: {PROMPTS_DIR} not found", file=sys.stderr)
        return 2

    skills = discover_skills()
    agents = discover_agents()
    print(f"Discovered {len(skills)} skills, {len(agents)} agents")

    files = sorted(PROMPTS_DIR.glob("*.prompt.md"))
    print(f"Processing {len(files)} prompt files\n")

    by_agent: dict[str, int] = {}
    total_broken_fixes = 0
    rows: list[dict] = []
    failures: list[tuple[str, str]] = []

    for p in files:
        try:
            raw = p.read_text(encoding="utf-8")
            fm, body = parse_frontmatter(raw)
            text, summary = assemble_file(p.name, fm, body, skills, agents)
            p.write_text(text, encoding="utf-8")
            by_agent[summary["expected_agent"]] = by_agent.get(
                summary["expected_agent"], 0) + 1
            total_broken_fixes += summary["broken_fixes"]
            rows.append(summary)
            print(f"  {p.name}: agent={summary['expected_agent']} "
                  f"skills={summary['loads_skills']} "
                  f"tools={summary['loads_tools']} "
                  f"inputs={summary['inputs_required']} "
                  f"fixes={summary['broken_fixes']}")
        except Exception as e:  # noqa: BLE001
            failures.append((p.name, repr(e)))
            print(f"  FAIL {p.name}: {e!r}")

    print()
    print("=" * 60)
    print(f"Files processed: {len(files) - len(failures)}")
    print(f"Failures:        {len(failures)}")
    print(f"Broken-target fixes applied: {total_broken_fixes}")
    print("By expected_agent:")
    for a, n in sorted(by_agent.items(), key=lambda x: -x[1]):
        print(f"  {a:20s} {n}")
    for n, err in failures:
        print(f"  - {n}: {err}")
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())
