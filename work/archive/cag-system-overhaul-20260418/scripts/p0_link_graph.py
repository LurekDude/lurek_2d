"""P0 audit: build inventory tables, link graph JSON, and gap analysis for the CAG layer.

Read-only. Outputs:
- reports/P0_inventory.md
- data/cag_link_graph.json
- reports/P0_gaps.md
- reports/P0_summary.md
"""
from __future__ import annotations

import json
import re
import statistics
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
GH = ROOT / ".github"
SESSION = ROOT / "work" / "cag-system-overhaul-20260418"
REPORTS = SESSION / "reports"
DATA = SESSION / "data"
REPORTS.mkdir(parents=True, exist_ok=True)
DATA.mkdir(parents=True, exist_ok=True)

SYSTEM_PROMPT = GH / "copilot-instructions.md"
AGENTS_DIR = GH / "agents"
SKILLS_DIR = GH / "skills"
PROMPTS_DIR = GH / "prompts"
TOOLS_DIR = ROOT / "tools"


def file_stats(p: Path) -> dict:
    text = p.read_text(encoding="utf-8", errors="replace")
    lines = text.count("\n") + (0 if text.endswith("\n") or not text else 1)
    size = p.stat().st_size
    mtime = datetime.fromtimestamp(p.stat().st_mtime, tz=timezone.utc).strftime("%Y-%m-%d")
    return {"path": str(p.relative_to(ROOT)).replace("\\", "/"), "lines": lines, "size": size, "mtime": mtime, "text": text}


def has_yaml_frontmatter(text: str) -> bool:
    return text.startswith("---\n") and "\n---" in text[4:200]


def parse_frontmatter(text: str) -> dict:
    if not has_yaml_frontmatter(text):
        return {}
    end = text.find("\n---", 4)
    if end < 0:
        return {}
    fm = text[4:end]
    out = {}
    for line in fm.splitlines():
        m = re.match(r"^([A-Za-z_][\w-]*)\s*:\s*(.*)$", line)
        if m:
            out[m.group(1)] = m.group(2).strip()
    return out


def count_fences(text: str) -> int:
    return len(re.findall(r"^```", text, re.MULTILINE)) // 2


# ---------- inventory ----------
inv_system = file_stats(SYSTEM_PROMPT)
inv_agents = []
for p in sorted(AGENTS_DIR.glob("*.md")):
    s = file_stats(p)
    fm = parse_frontmatter(s["text"])
    s["frontmatter"] = bool(fm)
    s["description_len"] = len(fm.get("description", ""))
    s["fences"] = count_fences(s["text"])
    inv_agents.append(s)

inv_skills = []
for d in sorted(SKILLS_DIR.iterdir()):
    if not d.is_dir():
        continue
    sk = d / "SKILL.md"
    if not sk.exists():
        continue
    s = file_stats(sk)
    fm = parse_frontmatter(s["text"])
    s["frontmatter"] = bool(fm)
    s["fm_name"] = fm.get("name", "")
    s["fm_desc_len"] = len(fm.get("description", ""))
    s["fences"] = count_fences(s["text"])
    s["companion_files"] = sorted(x.name for x in d.iterdir() if x.name != "SKILL.md")
    inv_skills.append(s)

inv_prompts = []
for p in sorted(PROMPTS_DIR.glob("*.md")):
    s = file_stats(p)
    fm = parse_frontmatter(s["text"])
    s["frontmatter"] = bool(fm)
    s["fm_mode"] = fm.get("mode", "")
    s["fm_tools"] = fm.get("tools", "")
    s["fm_desc_len"] = len(fm.get("description", ""))
    s["fences"] = count_fences(s["text"])
    inv_prompts.append(s)


def stats_block(values: list[int]) -> tuple[int, int, int, int]:
    if not values:
        return (0, 0, 0, 0)
    return (sum(values), min(values), int(statistics.median(values)), max(values))


# ---------- link graph ----------
ALL_FILES = [SYSTEM_PROMPT] + sorted(AGENTS_DIR.glob("*.md")) + [d / "SKILL.md" for d in sorted(SKILLS_DIR.iterdir()) if (d / "SKILL.md").exists()] + sorted(PROMPTS_DIR.glob("*.md"))

# Index of known target paths (rel to repo root, forward slashes)
KNOWN = set()
for f in ALL_FILES:
    KNOWN.add(str(f.relative_to(ROOT)).replace("\\", "/"))
# Also tool scripts
TOOL_FILES = set()
if TOOLS_DIR.exists():
    for f in TOOLS_DIR.rglob("*"):
        if f.is_file():
            rel = str(f.relative_to(ROOT)).replace("\\", "/")
            TOOL_FILES.add(rel)

MD_LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
BARE_PATH_RE = re.compile(r"(?<![\w/`])(\.github/[\w./-]+|tools/[\w./-]+|docs/[\w./-]+)")
SKILL_NAME_RE = re.compile(r"`?([a-z][a-z0-9-]+)`?")

skill_names = {s["path"].split("/")[-2] for s in inv_skills}
agent_names = {Path(s["path"]).stem.replace(".agent", "") for s in inv_agents if s["path"].endswith(".agent.md")}

edges: list[dict] = []
broken: list[dict] = []


def normalize_target(src: Path, target: str) -> str | None:
    target = target.split("#", 1)[0].split("?", 1)[0].strip()
    if not target or target.startswith(("http://", "https://", "mailto:")):
        return None
    # Resolve relative
    if target.startswith(".github/") or target.startswith("tools/") or target.startswith("docs/"):
        return target
    # relative to file dir
    try:
        candidate = (src.parent / target).resolve().relative_to(ROOT)
        return str(candidate).replace("\\", "/")
    except Exception:
        return None


for f in ALL_FILES:
    rel_from = str(f.relative_to(ROOT)).replace("\\", "/")
    text = f.read_text(encoding="utf-8", errors="replace")
    seen_targets = set()

    for m in MD_LINK_RE.finditer(text):
        tgt = normalize_target(f, m.group(2))
        if not tgt:
            continue
        if tgt in seen_targets:
            continue
        seen_targets.add(tgt)
        if tgt.startswith(".github/"):
            etype = "skill-link" if "/skills/" in tgt else "agent-link" if "/agents/" in tgt else "prompt-link" if "/prompts/" in tgt else "cag-link"
        elif tgt.startswith("tools/"):
            etype = "tool-link"
        elif tgt.startswith("docs/"):
            etype = "doc-link"
        else:
            etype = "other-link"
        edges.append({"from": rel_from, "to": tgt, "type": etype})
        # Check broken
        if tgt.startswith((".github/", "tools/", "docs/")):
            full = ROOT / tgt
            if not full.exists():
                broken.append({"file": rel_from, "broken_target": tgt})

    for m in BARE_PATH_RE.finditer(text):
        tgt = m.group(1).rstrip(".,);:`")
        if tgt in seen_targets:
            continue
        seen_targets.add(tgt)
        if tgt.startswith(".github/"):
            etype = "skill-mention" if "/skills/" in tgt else "agent-mention" if "/agents/" in tgt else "prompt-mention" if "/prompts/" in tgt else "cag-mention"
        elif tgt.startswith("tools/"):
            etype = "tool-mention"
        else:
            etype = "doc-mention"
        edges.append({"from": rel_from, "to": tgt, "type": etype})
        if tgt.startswith((".github/", "tools/", "docs/")):
            full = ROOT / tgt
            if not full.exists():
                broken.append({"file": rel_from, "broken_target": tgt})

# Skill-name edges from system prompt CORE SKILLS lines and agent CORE SKILLS sections
for f in [SYSTEM_PROMPT] + sorted(AGENTS_DIR.glob("*.md")):
    rel_from = str(f.relative_to(ROOT)).replace("\\", "/")
    text = f.read_text(encoding="utf-8", errors="replace")
    # Match `name` mentions in the skill catalog area
    for m in re.finditer(r"`([a-z][a-z0-9-]+)`", text):
        name = m.group(1)
        if name in skill_names:
            tgt = f".github/skills/{name}/SKILL.md"
            edges.append({"from": rel_from, "to": tgt, "type": "skill-name-ref"})

# Agent-to-agent routing edges (system prompt agent table + agent ROUTING sections)
for f in [SYSTEM_PROMPT] + sorted(AGENTS_DIR.glob("*.md")):
    rel_from = str(f.relative_to(ROOT)).replace("\\", "/")
    text = f.read_text(encoding="utf-8", errors="replace")
    for m in re.finditer(r"`([A-Z][A-Za-z-]+)`", text):
        name = m.group(1).lower()
        if name in agent_names:
            tgt = f".github/agents/{name}.agent.md"
            if tgt != rel_from:
                edges.append({"from": rel_from, "to": tgt, "type": "agent-name-ref"})

# Dedupe
def dedupe(items):
    seen = set()
    out = []
    for e in items:
        key = (e["from"], e["to"], e["type"])
        if key in seen:
            continue
        seen.add(key)
        out.append(e)
    return out

edges = dedupe(edges)
broken_unique = dedupe([{"from": b["file"], "to": b["broken_target"], "type": "broken"} for b in broken])
broken = [{"file": b["from"], "broken_target": b["to"]} for b in broken_unique]

# Inbound-ref index
inbound: dict[str, set[str]] = {}
for e in edges:
    inbound.setdefault(e["to"], set()).add(e["from"])

orphan_skills = sorted(
    f".github/skills/{name}/SKILL.md"
    for name in skill_names
    if not inbound.get(f".github/skills/{name}/SKILL.md")
)
orphan_agents = sorted(
    f".github/agents/{name}.agent.md"
    for name in agent_names
    if not inbound.get(f".github/agents/{name}.agent.md")
)

# Stats
type_counts: dict[str, int] = {}
for e in edges:
    type_counts[e["type"]] = type_counts.get(e["type"], 0) + 1

graph = {
    "edges": edges,
    "orphans": {
        "skills_with_no_inbound_refs": orphan_skills,
        "agents_with_no_inbound_refs": orphan_agents,
        "prompts_with_broken_link_targets": broken,
    },
    "stats": {
        "edges_total": len(edges),
        "by_type": type_counts,
        "agents": len(agent_names),
        "skills": len(skill_names),
        "prompts": len(inv_prompts),
        "broken_targets_total": len(broken),
    },
}

(DATA / "cag_link_graph.json").write_text(json.dumps(graph, indent=2), encoding="utf-8")


# ---------- inventory markdown ----------
def md_table(headers: list[str], rows: list[list]) -> str:
    out = ["| " + " | ".join(headers) + " |", "|" + "|".join("---" for _ in headers) + "|"]
    for r in rows:
        out.append("| " + " | ".join(str(c) for c in r) + " |")
    return "\n".join(out)


lines_summary = []
all_lines = [inv_system["lines"]] + [a["lines"] for a in inv_agents] + [s["lines"] for s in inv_skills] + [p["lines"] for p in inv_prompts]
all_size = inv_system["size"] + sum(a["size"] for a in inv_agents) + sum(s["size"] for s in inv_skills) + sum(p["size"] for p in inv_prompts)

agent_lines = [a["lines"] for a in inv_agents]
skill_lines = [s["lines"] for s in inv_skills]
prompt_lines = [p["lines"] for p in inv_prompts]
skill_fences = [s["fences"] for s in inv_skills]

inv_md = []
inv_md.append("# P0 Inventory — CAG Layer\n")
inv_md.append(f"_Generated: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}_\n")
inv_md.append("## Summary\n")
inv_md.append(f"- Total CAG files: **{1 + len(inv_agents) + len(inv_skills) + len(inv_prompts)}** (1 system prompt + {len(inv_agents)} agent files + {len(inv_skills)} skills + {len(inv_prompts)} prompts)")
inv_md.append(f"- Total lines: **{sum(all_lines):,}**")
inv_md.append(f"- Total size: **{all_size:,} bytes ({all_size/1024:.1f} KB)**")
inv_md.append("")
inv_md.append("| Type | Count | Lines (sum) | Lines (min/median/max) |")
inv_md.append("|---|---|---|---|")
for label, vals in [("System prompt", [inv_system["lines"]]), ("Agents", agent_lines), ("Skills (SKILL.md)", skill_lines), ("Prompts", prompt_lines)]:
    s_, mn, md_, mx = stats_block(vals)
    inv_md.append(f"| {label} | {len(vals)} | {s_:,} | {mn} / {md_} / {mx} |")
inv_md.append("")
inv_md.append(f"- Total fenced code blocks across SKILL.md files: **{sum(skill_fences)}** (target after P3: 0)")
inv_md.append("")

inv_md.append("## System Prompt\n")
inv_md.append(md_table(
    ["Path", "Lines", "Bytes", "KB", "Last modified"],
    [[inv_system["path"], inv_system["lines"], inv_system["size"], f"{inv_system['size']/1024:.1f}", inv_system["mtime"]]],
))
inv_md.append("")

inv_md.append("## Agents\n")
inv_md.append(md_table(
    ["Path", "Lines", "Bytes", "Modified", "Frontmatter", "Description len", "Fences"],
    [[a["path"], a["lines"], a["size"], a["mtime"], "yes" if a["frontmatter"] else "no", a["description_len"], a["fences"]] for a in inv_agents],
))
inv_md.append("")

inv_md.append("## Skills\n")
inv_md.append(md_table(
    ["Path", "Lines", "Bytes", "Modified", "Frontmatter", "Name field", "Desc len", "Fences", "Companion files"],
    [[s["path"], s["lines"], s["size"], s["mtime"], "yes" if s["frontmatter"] else "no", s["fm_name"] or "—", s["fm_desc_len"], s["fences"], ", ".join(s["companion_files"]) or "—"] for s in inv_skills],
))
inv_md.append("")

inv_md.append("## Prompts\n")
inv_md.append(md_table(
    ["Path", "Lines", "Bytes", "Modified", "Frontmatter", "mode", "tools", "Desc len", "Fences"],
    [[p["path"], p["lines"], p["size"], p["mtime"], "yes" if p["frontmatter"] else "no", p["fm_mode"] or "—", (p["fm_tools"][:30] + "…") if len(p["fm_tools"]) > 30 else (p["fm_tools"] or "—"), p["fm_desc_len"], p["fences"]] for p in inv_prompts],
))
inv_md.append("")

(REPORTS / "P0_inventory.md").write_text("\n".join(inv_md), encoding="utf-8")


# ---------- gaps ----------
gaps_md = ["# P0 Gaps & Quality Issues\n"]
gaps_md.append(f"_Generated: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}_\n")

gaps_md.append("## 1. Orphan Skills (no inbound reference)\n")
if orphan_skills:
    for s in orphan_skills:
        gaps_md.append(f"- `{s}`")
else:
    gaps_md.append("_None_")
gaps_md.append("")

gaps_md.append("## 2. Orphan Agents (no inbound reference)\n")
if orphan_agents:
    for a in orphan_agents:
        gaps_md.append(f"- `{a}`")
else:
    gaps_md.append("_None_")
gaps_md.append("")

gaps_md.append("## 3. Broken Link Targets\n")
if broken:
    for b in broken:
        gaps_md.append(f"- `{b['file']}` → `{b['broken_target']}`")
else:
    gaps_md.append("_None_")
gaps_md.append("")

# Duplicate / near-duplicate prompts by prefix
clusters: dict[str, list[str]] = {}
for p in inv_prompts:
    name = Path(p["path"]).stem.replace(".prompt", "")
    prefix = name.split("-", 1)[0]
    clusters.setdefault(prefix, []).append(name)
gaps_md.append("## 4. Prompt Clusters (potential duplicates)\n")
gaps_md.append("| Prefix | Count | Members |")
gaps_md.append("|---|---|---|")
for prefix, members in sorted(clusters.items(), key=lambda x: -len(x[1])):
    if len(members) >= 2:
        gaps_md.append(f"| `{prefix}-` | {len(members)} | {', '.join(sorted(members))} |")
gaps_md.append("")

# Missing prompts: heuristic — for each skill name, expect at least one prompt mentioning it
prompt_names_set = {Path(p["path"]).stem.replace(".prompt", "") for p in inv_prompts}
prompt_text_blob = "\n".join(p["text"] for p in inv_prompts)
missing_prompt_per_skill = []
for sk in sorted(skill_names):
    if sk in prompt_text_blob or sk in " ".join(prompt_names_set):
        continue
    missing_prompt_per_skill.append(sk)
gaps_md.append("## 5. Skills Not Referenced by Any Prompt\n")
if missing_prompt_per_skill:
    for sk in missing_prompt_per_skill:
        gaps_md.append(f"- `{sk}` — consider authoring a prompt that loads it")
else:
    gaps_md.append("_None_")
gaps_md.append("")

# Tool gap: tools mentioned in CAG vs tools present
tools_mentioned = sorted({e["to"] for e in edges if e["to"].startswith("tools/")})
tools_missing = [t for t in tools_mentioned if not (ROOT / t).exists()]
referenced_set = set(tools_mentioned)
existing_scripts = sorted(t for t in TOOL_FILES if t.endswith((".py", ".ps1", ".sh")))
tools_unreferenced = [t for t in existing_scripts if t not in referenced_set]
gaps_md.append("## 6. Tool References vs Filesystem\n")
gaps_md.append(f"- Tools mentioned in CAG: **{len(tools_mentioned)}**")
gaps_md.append(f"- Mentioned but missing on disk: **{len(tools_missing)}**")
for t in tools_missing[:30]:
    gaps_md.append(f"  - `{t}`")
gaps_md.append(f"- Tool scripts on disk but never referenced in CAG: **{len(tools_unreferenced)}**")
for t in tools_unreferenced[:30]:
    gaps_md.append(f"  - `{t}`")
if len(tools_unreferenced) > 30:
    gaps_md.append(f"  - …and {len(tools_unreferenced) - 30} more")
gaps_md.append("")

# Frontmatter inconsistency
agent_fm_yes = sum(1 for a in inv_agents if a["frontmatter"])
prompt_fm_yes = sum(1 for p in inv_prompts if p["frontmatter"])
skill_fm_yes = sum(1 for s in inv_skills if s["frontmatter"])
gaps_md.append("## 7. Frontmatter Consistency\n")
gaps_md.append(f"- Agents with YAML frontmatter: **{agent_fm_yes} / {len(inv_agents)}**")
gaps_md.append(f"- Skills with YAML frontmatter: **{skill_fm_yes} / {len(inv_skills)}**")
gaps_md.append(f"- Prompts with YAML frontmatter: **{prompt_fm_yes} / {len(inv_prompts)}**")
gaps_md.append("")

# System prompt inline list bloat
sys_text = inv_system["text"]
sys_skill_mentions = sum(1 for sk in skill_names if f"`{sk}`" in sys_text)
sys_agent_mentions = sum(1 for ag in agent_names if f"`{ag.title()}`" in sys_text or f"`{ag}`" in sys_text)
gaps_md.append("## 8. System Prompt Bloat\n")
gaps_md.append(f"- System prompt: **{inv_system['lines']} lines / {inv_system['size']/1024:.1f} KB** (target ≤120 lines, ≤8 KB)")
gaps_md.append(f"- Inline skill name mentions in system prompt: **{sys_skill_mentions} / {len(skill_names)}**")
gaps_md.append(f"- Inline agent name mentions in system prompt: **{sys_agent_mentions} / {len(agent_names)}**")
gaps_md.append("- Recommendation: replace skill catalog and agent table with discovery references in P3/P5.")
gaps_md.append("")

# Skills with fenced code (P3 target)
sk_with_code = [s for s in inv_skills if s["fences"] > 0]
gaps_md.append("## 9. Skills With Fenced Code Blocks (extract to companion files in P3)\n")
gaps_md.append(f"Total: **{len(sk_with_code)} / {len(inv_skills)} skills**, **{sum(s['fences'] for s in sk_with_code)} blocks** total.\n")
gaps_md.append("| Skill | Fences | Existing companion files |")
gaps_md.append("|---|---|---|")
for s in sorted(sk_with_code, key=lambda x: -x["fences"]):
    gaps_md.append(f"| `{s['path']}` | {s['fences']} | {', '.join(s['companion_files']) or '—'} |")
gaps_md.append("")

(REPORTS / "P0_gaps.md").write_text("\n".join(gaps_md), encoding="utf-8")


# ---------- summary ----------
total_fences_skills = sum(skill_fences)
findings = [
    f"System prompt is **{inv_system['lines']} lines / {inv_system['size']/1024:.1f} KB** — {inv_system['lines']-120} lines over the 120-line target.",
    f"**{len(orphan_skills)} orphan skills** with no inbound reference (skills nobody loads).",
    f"**{len(orphan_agents)} orphan agents** with no inbound reference.",
    f"**{len(broken)} broken link targets** across all CAG files.",
    f"**{total_fences_skills} fenced code blocks** spread across **{len(sk_with_code)} SKILL.md files** — must extract to companion files in P3.",
    f"**{len(missing_prompt_per_skill)} skills** are not referenced by any prompt — candidate prompt gaps.",
    f"Frontmatter inconsistency: agents {agent_fm_yes}/{len(inv_agents)}, skills {skill_fm_yes}/{len(inv_skills)}, prompts {prompt_fm_yes}/{len(inv_prompts)} have YAML frontmatter.",
    f"**{len(tools_missing)} tool paths** referenced in CAG do not exist on disk; **{len(tools_unreferenced)} tool scripts** on disk are never mentioned by any CAG file.",
    f"Prompts cluster heavily under prefixes: " + ", ".join(f"{p}({len(m)})" for p, m in sorted(clusters.items(), key=lambda x: -len(x[1]))[:5] if len(m) >= 2),
    f"Total CAG link graph: **{len(edges)} edges** across **{len(ALL_FILES)} files**; by type: " + ", ".join(f"{k}={v}" for k, v in sorted(type_counts.items(), key=lambda x: -x[1])[:5]),
]

summary_md = ["# P0 Summary — CAG Audit\n"]
summary_md.append(f"_Generated: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}_\n")
summary_md.append("## Top 10 Findings (severity-ranked)\n")
for i, f in enumerate(findings, 1):
    summary_md.append(f"{i}. {f}")
summary_md.append("")
summary_md.append("## Concrete Numbers\n")
summary_md.append(f"- Files: 1 system prompt + {len(inv_agents)} agent files ({len(agent_names)} agents + README) + {len(inv_skills)} skills + {len(inv_prompts)} prompts.")
summary_md.append(f"- Orphan skills: **{len(orphan_skills)}**")
summary_md.append(f"- Orphan agents: **{len(orphan_agents)}**")
summary_md.append(f"- Broken link targets: **{len(broken)}**")
summary_md.append(f"- Fenced code blocks across SKILL.md files: **{total_fences_skills}**")
summary_md.append(f"- Total link-graph edges: **{len(edges)}**")
summary_md.append("")
summary_md.append("## Recommendation for P1\n")
summary_md.append("- Prioritise the **SKILL.md schema** first (frontmatter `name`/`description`, no fenced code, companion-file rule) — this unblocks the largest single mechanical refactor (P3).")
summary_md.append("- Co-author the **prompt schema** in the same pass (verb-noun naming, frontmatter `description`/`mode`/`tools`, no inline skill enumeration) so the 45-prompt rewrite in the later phase is mechanical.")
summary_md.append("- Defer agent schema until skills + prompts are stable (agents reference both).")
summary_md.append("- Build `tools/validate/cag_link_check.py` early in P2 — broken-link count is the gating metric for every later phase.")
summary_md.append("")

(REPORTS / "P0_summary.md").write_text("\n".join(summary_md), encoding="utf-8")

print(json.dumps({
    "agents": len(inv_agents),
    "skills": len(inv_skills),
    "prompts": len(inv_prompts),
    "system_prompt_lines": inv_system["lines"],
    "system_prompt_kb": round(inv_system["size"] / 1024, 1),
    "edges": len(edges),
    "orphan_skills": len(orphan_skills),
    "orphan_agents": len(orphan_agents),
    "broken_targets": len(broken),
    "skills_with_fences": len(sk_with_code),
    "total_fences": total_fences_skills,
    "skills_unreferenced_by_prompts": len(missing_prompt_per_skill),
    "tools_mentioned_missing": len(tools_missing),
    "tools_on_disk_unreferenced": len(tools_unreferenced),
}, indent=2))
