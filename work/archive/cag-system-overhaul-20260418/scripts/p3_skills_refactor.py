"""P3 skills refactor — extract fenced blocks to companion files,
add YAML frontmatter (name, description, companion_files, related_skills),
restructure body into 6 required sections.

Session-scoped: lives under work/cag-system-overhaul-20260418/scripts/.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
SKILLS_DIR = ROOT / ".github" / "skills"

LANG_MAP = {
    "rust": ("examples", "rs"),
    "rs": ("examples", "rs"),
    "lua": ("examples", "lua"),
    "python": ("examples", "py"),
    "py": ("examples", "py"),
    "wgsl": ("examples", "wgsl"),
    "glsl": ("examples", "glsl"),
    "toml": ("templates", "toml"),
    "yaml": ("templates", "yaml"),
    "yml": ("templates", "yaml"),
    "json": ("templates", "json"),
    "bash": ("snippets", "sh"),
    "sh": ("snippets", "sh"),
    "shell": ("snippets", "sh"),
    "powershell": ("snippets", "ps1"),
    "ps1": ("snippets", "ps1"),
    "pwsh": ("snippets", "ps1"),
    "markdown": ("snippets", "md"),
    "md": ("snippets", "md"),
    "console": ("snippets", "txt"),
    "text": ("snippets", "txt"),
    "plaintext": ("snippets", "txt"),
    "txt": ("snippets", "txt"),
    "diff": ("snippets", "diff"),
    "ini": ("templates", "ini"),
    "xml": ("templates", "xml"),
    "html": ("snippets", "html"),
    "javascript": ("examples", "js"),
    "js": ("examples", "js"),
    "typescript": ("examples", "ts"),
    "ts": ("examples", "ts"),
    "c": ("examples", "c"),
    "cpp": ("examples", "cpp"),
}

FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)

LINE_CAP = 120


def slugify(s: str, max_words: int = 6) -> str:
    s = re.sub(r"[`*_~]", "", s)
    s = re.sub(r"[^a-zA-Z0-9\s]", " ", s).strip().lower()
    parts = [p for p in s.split() if p]
    return "-".join(parts[:max_words]) or "block"


def parse_frontmatter(text: str) -> tuple[dict, str]:
    """Return (dict-of-fields, body_after_frontmatter)."""
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}, text
    yaml_text = m.group(1)
    body = text[m.end():]
    fields = {}
    cur_key = None
    for ln in yaml_text.split("\n"):
        if not ln.strip():
            continue
        m2 = re.match(r"^([a-zA-Z_]\w*):\s*(.*)$", ln)
        if m2:
            cur_key = m2.group(1)
            fields[cur_key] = m2.group(2).strip()
    return fields, body


def extract_blocks(body: str):
    """Walk lines once; return (blocks, original_lines).

    Each block is dict: {lang, content, start, end, heading}.
    """
    lines = body.split("\n")
    blocks = []
    in_fence = False
    fence_lang = ""
    fence_start = -1
    fence_lines: list[str] = []
    last_heading = ""
    cur_heading = ""
    for i, ln in enumerate(lines):
        m_h = re.match(r"^#{2,6}\s+(.*?)\s*$", ln)
        if m_h and not in_fence:
            last_heading = m_h.group(1)
        m_open = re.match(r"^```([a-zA-Z0-9+_\-]*)\s*$", ln)
        if not in_fence and m_open:
            in_fence = True
            fence_lang = m_open.group(1).lower()
            fence_start = i
            fence_lines = []
            cur_heading = last_heading
            continue
        if in_fence:
            if ln.rstrip() == "```":
                blocks.append({
                    "lang": fence_lang,
                    "content": "\n".join(fence_lines),
                    "start": fence_start,
                    "end": i,
                    "heading": cur_heading,
                })
                in_fence = False
                fence_lang = ""
            else:
                fence_lines.append(ln)
    return blocks, lines


def assign_slug(heading: str, idx: int, used: set[str]) -> str:
    base = slugify(heading) if heading else f"block-{idx}"
    slug = base
    n = 2
    while slug in used:
        slug = f"{base}-{n}"
        n += 1
    used.add(slug)
    return slug


def write_companions(skill_dir: Path, blocks: list[dict]) -> list[tuple[str, str, dict]]:
    """Write each block to disk; return list of (rel_path, description, block)."""
    used: set[str] = set()
    out: list[tuple[str, str, dict]] = []
    for i, blk in enumerate(blocks, start=1):
        lang = blk["lang"]
        category, ext = LANG_MAP.get(lang, ("snippets", "txt"))
        slug = assign_slug(blk["heading"], i, used)
        rel_path = f"{category}/{slug}.{ext}"
        full = skill_dir / rel_path
        full.parent.mkdir(parents=True, exist_ok=True)
        content = blk["content"]
        if not content.endswith("\n"):
            content += "\n"
        full.write_text(content, encoding="utf-8")
        desc = blk["heading"] or f"block {i}"
        out.append((rel_path, desc, blk))
    return out


def replace_blocks_in_lines(lines: list[str], block_records: list[tuple[str, str, dict]]) -> list[str]:
    """Replace fenced block lines with a prose reference; back-to-front to keep indices valid."""
    result = list(lines)
    for rel_path, _desc, blk in sorted(block_records, key=lambda r: -r[2]["start"]):
        prose = f"> See [{rel_path}]({rel_path}) for the example."
        result[blk["start"]:blk["end"] + 1] = [prose]
    return result


def split_sections(body: str):
    """Return (intro_lines, [(heading, lines)])."""
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
    return intro, sections


def first_paragraph(lines: list[str]) -> str:
    """Strip H1 + return first non-empty paragraph."""
    text = "\n".join(lines).strip()
    text = re.sub(r"^#\s+.*\n", "", text).strip()
    if not text:
        return ""
    return text.split("\n\n")[0].strip()


def synthesize_description(name: str, existing: str | None, intro: str) -> str:
    if existing:
        d = existing
    elif intro:
        d = intro.replace("\n", " ").strip()
    else:
        d = f"Load this skill when working on {name} in Lurek2D."
    if "skip it for" not in d.lower() and "skip" not in d.lower():
        d += f" Skip it for unrelated work; load the skill that matches your domain instead."
    if "load this skill when" not in d.lower() and "load when" not in d.lower():
        d = f"Load this skill when working on {name}: " + d
    # collapse whitespace
    d = re.sub(r"\s+", " ", d).strip()
    return d


def find_section(sections: list[tuple[str, list[str]]], *names: str) -> list[str] | None:
    lower_names = {n.lower() for n in names}
    for h, lines in sections:
        if h.lower() in lower_names:
            return lines
    return None


SKIP_SECTION_HEADINGS = {
    "mission",
    "when to load", "load when", "load this skill when",
    "when to skip", "does not cover", "skip", "skip for", "skip for:",
    "avoid using",
    "companion file index", "companion files",
    "references", "related skills", "related", "see also",
}


def build_domain_knowledge(sections: list[tuple[str, list[str]]]) -> str:
    chunks: list[str] = []
    for h, lines in sections:
        if h.lower() in SKIP_SECTION_HEADINGS:
            continue
        chunks.append(f"### {h}")
        text = "\n".join(lines).strip("\n")
        if text:
            chunks.append(text)
        chunks.append("")
    return "\n".join(chunks).strip()


def derive_skip_clause(description: str) -> list[str]:
    m = re.search(r"skip it for[^.]*\.?", description, re.IGNORECASE)
    if m:
        return [f"- {m.group(0).strip()}"]
    return ["- Anything outside this skill's domain — load the matching skill instead."]


def derive_load_bullets(description: str, name: str) -> list[str]:
    m = re.search(r"load this skill when([^.]*)\.", description, re.IGNORECASE)
    if not m:
        return [f"- Working on {name} in the Lurek2D codebase."]
    body = m.group(1).strip(": \t")
    parts = re.split(r";|,| or |/", body)
    parts = [p.strip(" .") for p in parts if p.strip(" .")]
    if not parts:
        return [f"- Working on {name} in the Lurek2D codebase."]
    return [f"- {p[0].upper()}{p[1:]}" if p else "- (unspecified)" for p in parts[:8]]


def yaml_inline_list(items: list[str]) -> str:
    return "[" + ", ".join(items) + "]"


def assemble(name: str, description: str, companion_records, related_skills,
             mission_text: str, load_bullets: list[str], skip_bullets: list[str],
             domain_text: str, refs_text: str) -> tuple[str, bool, str]:
    """Assemble final SKILL.md text. Returns (text, needed_overflow, overflow_text)."""
    examples = [p for p, _, _ in companion_records if p.startswith("examples/")]
    templates = [p for p, _, _ in companion_records if p.startswith("templates/")]
    snippets = [p for p, _, _ in companion_records if p.startswith("snippets/")]

    fm = []
    fm.append("---")
    fm.append(f"name: {name}")
    fm.append(f"description: {json.dumps(description, ensure_ascii=False)}")
    fm.append("companion_files:")
    fm.append(f"  examples: {yaml_inline_list(examples)}")
    fm.append(f"  templates: {yaml_inline_list(templates)}")
    fm.append(f"  snippets: {yaml_inline_list(snippets)}")
    fm.append(f"related_skills: {yaml_inline_list(related_skills)}")
    fm.append("---")

    body = []
    body.append("")
    body.append(f"# {name}")
    body.append("")
    body.append("## Mission")
    body.append("")
    body.append(mission_text.strip() or f"This skill captures Lurek2D conventions for {name}.")
    body.append("")
    body.append("## When To Load")
    body.append("")
    body.extend(load_bullets)
    body.append("")
    body.append("## When To Skip")
    body.append("")
    body.extend(skip_bullets)
    body.append("")
    body.append("## Domain Knowledge")
    body.append("")
    body.append(domain_text.strip() or "See companion files for concrete examples.")
    body.append("")
    body.append("## Companion File Index")
    body.append("")
    if companion_records:
        for path, desc, _blk in companion_records:
            body.append(f"- [{path}]({path}) — {desc}")
    else:
        body.append("- (no companion files extracted)")
    body.append("")
    body.append("## References")
    body.append("")
    body.append(refs_text.strip() or "- See related skills in `.github/skills/`.")
    body.append("")

    text = "\n".join(fm) + "\n" + "\n".join(body)
    line_count = text.count("\n") + 1
    overflow = ""
    if line_count > LINE_CAP:
        # Move tail of domain knowledge into snippets/extended-notes.md
        # Find domain section bounds and trim
        lines = text.split("\n")
        try:
            dom_idx = lines.index("## Domain Knowledge")
            comp_idx = lines.index("## Companion File Index", dom_idx)
        except ValueError:
            return text, False, ""
        dom_body_start = dom_idx + 2
        dom_body_end = comp_idx - 1  # keep blank line before next header
        dom_lines = lines[dom_body_start:dom_body_end]
        # how many lines do we need to remove?
        excess = line_count - LINE_CAP + 5  # safety margin
        if excess >= len(dom_lines):
            keep = dom_lines[:max(2, len(dom_lines) // 4)]
            move = dom_lines[len(keep):]
        else:
            keep = dom_lines[:len(dom_lines) - excess]
            move = dom_lines[len(dom_lines) - excess:]
        keep.append("")
        keep.append("> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.")
        new_lines = lines[:dom_body_start] + keep + lines[dom_body_end:]
        text = "\n".join(new_lines)
        overflow = "\n".join(move).strip() + "\n"
        return text, True, overflow
    return text, False, ""


def process_skill(skill_dir: Path) -> dict:
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        return {"name": skill_dir.name, "error": "no SKILL.md"}
    name = skill_dir.name
    raw = skill_md.read_text(encoding="utf-8")
    original_lines = raw.count("\n") + 1
    fields, body = parse_frontmatter(raw)
    existing_desc = fields.get("description")
    if existing_desc:
        existing_desc = existing_desc.strip().strip('"\'')

    blocks, lines = extract_blocks(body)
    records = write_companions(skill_dir, blocks)
    new_body_lines = replace_blocks_in_lines(lines, records)
    new_body = "\n".join(new_body_lines)

    intro, sections = split_sections(new_body)
    intro_text = first_paragraph(intro)
    description = synthesize_description(name, existing_desc, intro_text)

    mission_lines = find_section(sections, "Mission") or []
    mission_text = "\n".join(mission_lines).strip() or intro_text or f"This skill governs Lurek2D {name} work."

    load_section = find_section(sections, "When To Load", "Load When", "Use For", "Use For:")
    if load_section:
        load_bullets = [ln for ln in load_section if ln.strip().startswith("-") or ln.strip().startswith("*")]
        if not load_bullets:
            load_bullets = derive_load_bullets(description, name)
    else:
        load_bullets = derive_load_bullets(description, name)

    skip_section = find_section(sections, "When To Skip", "Does Not Cover", "Skip", "Skip For", "Skip For:", "Avoid Using")
    if skip_section:
        skip_bullets = [ln for ln in skip_section if ln.strip().startswith("-") or ln.strip().startswith("*")]
        if not skip_bullets:
            skip_bullets = derive_skip_clause(description)
    else:
        skip_bullets = derive_skip_clause(description)

    domain_text = build_domain_knowledge(sections)

    refs_section = find_section(sections, "References", "Related Skills", "Related", "See Also")
    refs_text = "\n".join(refs_section).strip() if refs_section else ""

    related_skills: list[str] = []
    # collect from existing related_skills frontmatter
    if "related_skills" in fields:
        rs_raw = fields["related_skills"]
        rs_items = re.findall(r"[a-z0-9_\-]+", rs_raw)
        related_skills = [r for r in rs_items if (SKILLS_DIR / r).is_dir() and r != name]

    text, overflowed, overflow_content = assemble(
        name, description, records, related_skills,
        mission_text, load_bullets, skip_bullets, domain_text, refs_text,
    )

    if overflowed:
        notes_path = skill_dir / "snippets" / "extended-notes.md"
        notes_path.parent.mkdir(parents=True, exist_ok=True)
        notes_path.write_text(overflow_content, encoding="utf-8")
        # Update companion list: append extended-notes if not present
        rel = "snippets/extended-notes.md"
        if not any(p == rel for p, _, _ in records):
            records.append((rel, "extended notes (overflow)", {"start": -1, "end": -1, "heading": ""}))
        # Re-assemble to include the new companion in frontmatter and index
        text, _, _ = assemble(
            name, description, records, related_skills,
            mission_text, load_bullets, skip_bullets,
            build_domain_knowledge(sections), refs_text,
        )
        # If still over cap, accept it; we did our best.

    skill_md.write_text(text, encoding="utf-8")
    final_lines = text.count("\n") + 1
    cat_counts = {"examples": 0, "templates": 0, "snippets": 0}
    for p, _, _ in records:
        cat = p.split("/", 1)[0]
        if cat in cat_counts:
            cat_counts[cat] += 1
    return {
        "name": name,
        "blocks": len(blocks),
        "companions": len(records),
        "lines_before": original_lines,
        "lines_after": final_lines,
        "categories": cat_counts,
        "overflowed": overflowed,
    }


def main() -> int:
    if not SKILLS_DIR.is_dir():
        print(f"ERROR: {SKILLS_DIR} not found", file=sys.stderr)
        return 2

    skill_dirs = sorted([d for d in SKILLS_DIR.iterdir() if d.is_dir()])
    print(f"Processing {len(skill_dirs)} skills under {SKILLS_DIR}\n")

    totals = {"blocks": 0, "companions": 0, "examples": 0, "templates": 0, "snippets": 0, "overflowed": 0}
    failures: list[tuple[str, str]] = []

    for d in skill_dirs:
        try:
            r = process_skill(d)
            if "error" in r:
                print(f"  SKIP {r['name']}: {r['error']}")
                failures.append((r["name"], r["error"]))
                continue
            totals["blocks"] += r["blocks"]
            totals["companions"] += r["companions"]
            for k in ("examples", "templates", "snippets"):
                totals[k] += r["categories"][k]
            if r["overflowed"]:
                totals["overflowed"] += 1
            ovf = " (overflowed)" if r["overflowed"] else ""
            print(f"  {r['name']}: {r['blocks']} blocks, {r['companions']} companions, "
                  f"{r['lines_after']} lines (was {r['lines_before']}){ovf}")
        except Exception as e:  # noqa: BLE001
            failures.append((d.name, repr(e)))
            print(f"  FAIL {d.name}: {e!r}")

    print()
    print("=" * 60)
    print(f"Total skills processed:    {len(skill_dirs) - len(failures)}")
    print(f"Total fenced blocks moved: {totals['blocks']}")
    print(f"Companions created:        {totals['companions']}")
    print(f"  examples:  {totals['examples']}")
    print(f"  templates: {totals['templates']}")
    print(f"  snippets:  {totals['snippets']}")
    print(f"Skills overflowed >120:    {totals['overflowed']}")
    print(f"Failures:                  {len(failures)}")
    for n, err in failures:
        print(f"  - {n}: {err}")
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())
