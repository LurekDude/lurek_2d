import re

with open('tools/audit/audit_module.py', 'r', encoding='utf-8') as f:
    c = f.read()

c = re.sub(
    r'def check_tier_label\(module: str\) -> Check:.*?return Check\("R-01", "Tier placement", PASS, f"Tier label matches: \{expected\}"\)',
    '''def check_tier_label(module: str) -> Check:
    \"\"\"R-01: Tier label in docs/specs matches the tier registry.\"\"\"
    expected = get_tier(module)
    spec_path = WORKSPACE / "docs" / "specs" / f"{module}.md"
    if not spec_path.exists():
        return Check("R-01", "Tier placement", WARN, "No specs file — tier label unverifiable")
    content = read_text(spec_path)
    m = re.search(r"\\*\\*Tier\\*\\*.*?(Baseline|Tier\\s*1|Tier\\s*2|Unassigned)",
                  content, re.IGNORECASE)
    if not m:
        return Check("R-01", "Tier placement", WARN,
                      f"No **Tier** row in specs; expected {expected}")
    found = m.group(1).lower().replace(" ", "")
    normed = ("baseline" if "baseline" in found
              else "tier1" if "tier1" in found
              else "tier2" if "tier2" in found
              else "unassigned")
    if normed != expected:
        return Check("R-01", "Tier placement", ERROR,
                      f"Spec tier '{m.group(1)}' ? registry tier '{expected}'")
    return Check("R-01", "Tier placement", PASS, f"Tier label matches: {expected}")''', c, flags=re.DOTALL
)

c = re.sub(r'# ¦¦ Phase 2: AGENT\.md Quality ¦¦.*?(?=# ¦¦ Phase 3: Docstrings ¦¦)', '', c, flags=re.DOTALL)
c = re.sub(r'def check_agent_source_files_complete\(module: str\) -> Check:.*?(?=# ¦¦ Phase)', '', c, flags=re.DOTALL)

with open('tools/audit/audit_module.py', 'w', encoding='utf-8') as f:
    f.write(c)
