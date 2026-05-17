#!/usr/bin/env python3
"""Cross-reference content/examples/ scripts against the lurek.* Lua API.

Coverage is reported in three tiers:
  - "real"    -- --@api-stub: block present, NO "-- TODO:" line in block
                 (fleshed-out scenario code; counts toward final coverage)
  - "pending" -- --@api-stub: block present AND has a "-- TODO:" line
                 (auto-generated stub, not yet replaced with real scenario)
  - "missing" -- no --@api-stub: marker at all (item not tracked in any example)

Workflow:
  1. Run example_add_missing.py  -- adds --@api-stub: blocks with -- TODO: (pending)
  2. Agent writes real Lua code, removes -- TODO: line  (pending -> real)
  3. This tool gates on: no "missing" items (--report) or no pending (--no-stubs)

Usage:
    python tools/audit/example_coverage.py                  # summary table
    python tools/audit/example_coverage.py --missing        # list uncovered items
    python tools/audit/example_coverage.py --stubs          # list modules with pending stubs
    python tools/audit/example_coverage.py --module timer   # one module
    python tools/audit/example_coverage.py --json           # machine-readable
    python tools/audit/example_coverage.py --report         # exit 1 if any missing
    python tools/audit/example_coverage.py --report --no-stubs  # also fail if pending
    python tools/audit/example_coverage.py --markdown FILE  # export Markdown report

Exit codes:
    0 -- no missing items (all API items have at least a stub marker)
    1 -- one or more items have no --@api-stub: marker at all
"""
from __future__ import annotations
import argparse, json, re, sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
API_JSON = ROOT / 'logs' / 'data' / 'lua_api_data.json'
EXAMPLES_DIR = ROOT / 'content' / 'examples'

# filename = module name exactly (src/render/ -> render.lua, src/ecs/ -> ecs.lua)
MODULE_TO_EXAMPLE: dict[str, str] = {
    'ai':          'ai.lua',
    'animation':   'animation.lua',
    'audio':       'audio.lua',
    'automation':  'automation.lua',
    'camera':      'camera.lua',
    'compute':     'compute.lua',
    'data':        'data.lua',
    'dataframe':   'dataframe.lua',
    'debugbridge': 'debugbridge.lua',
    'devtools':    'devtools.lua',
    'docs':        'docs.lua',
    'ecs':         'ecs.lua',
    'effect':      'effect.lua',
    'engine':      'engine.lua',
    'event':       'event.lua',
    'filesystem':  'filesystem.lua',
    'graph':       'graph.lua',
    'i18n':        'i18n.lua',
    'image':       'image.lua',
    'input':       'input.lua',
    'light':       'light.lua',
    'log':         'log.lua',
    'math':        'math.lua',
    'minimap':     'minimap.lua',
    'mods':        'mods.lua',
    'network':     'network.lua',
    'parallax':    'parallax.lua',
    'particle':    'particle.lua',
    'pathfind':    'pathfind.lua',
    'patterns':    'patterns.lua',
    'physics':     'physics.lua',
    'pipeline':    'pipeline.lua',
    'procgen':     'procgen.lua',
    'raycaster':   'raycaster.lua',
    'render':      'render.lua',
    'save':        'save.lua',
    'scene':       'scene.lua',
    'serial':      'serial.lua',
    'spine':       'spine.lua',
    'sprite':      'sprite.lua',
    'system':      'system.lua',
    'terminal':    'terminal.lua',
    'thread':      'thread.lua',
    'tilemap':     'tilemap.lua',
    'timer':       'timer.lua',
    'tween':       'tween.lua',
    'ui':          'ui.lua',
    'window':      'window.lua',
}

# Maps JSON module key  â†’  lurek.* namespace used in example files
# Namespace = src/ folder name exactly (e.g. src/render/ -> lurek.render)
NAMESPACE_MAP: dict[str, str] = {
    'ai':          'ai',
    'animation':   'animation',
    'audio':       'audio',
    'automation':  'automation',
    'camera':      'camera',
    'compute':     'compute',
    'data':        'data',
    'dataframe':   'dataframe',
    'debugbridge': 'debugbridge',
    'devtools':    'devtools',
    'docs':        'docs',
    'ecs':         'ecs',
    'effect':      'effect',
    'engine':      'engine',
    'event':       'event',
    'filesystem':  'filesystem',
    'graph':       'graph',
    'i18n':        'i18n',
    'image':       'image',
    'input':       'input',
    'light':       'light',
    'log':         'log',
    'math':        'math',
    'minimap':     'minimap',
    'mods':        'mods',
    'network':     'network',
    'parallax':    'parallax',
    'particle':    'particle',
    'pathfind':    'pathfind',
    'patterns':    'patterns',
    'physics':     'physics',
    'pipeline':    'pipeline',
    'procgen':     'procgen',
    'raycaster':   'raycaster',
    'render':      'render',
    'save':        'save',
    'scene':       'scene',
    'serial':      'serial',
    'spine':       'spine',
    'sprite':      'sprite',
    'system':      'runtime',
    'terminal':    'terminal',
    'thread':      'thread',
    'tilemap':     'tilemap',
    'timer':       'timer',
    'tween':       'tween',
    'ui':          'ui',
    'window':      'window',
}


@dataclass
class ApiEntry:
    module: str
    name: str          # bare Lua method/function name, e.g. "getDelta"
    is_method: bool
    owner_type: str    # class name for methods, e.g. "Scheduler"
    example_file: str
    description: str = ''
    inferred_sig: str = '()'


@dataclass
class ModuleCov:
    key: str
    example_file: str
    namespace: str = ''
    total: int = 0
    covered: int = 0        # hand-written real code coverage
    stub_covered: int = 0   # covered only by an auto-generated --@api-stub: block
    line_count: int = 0     # total lines in file
    comment_count: int = 0  # comment lines
    docstring_count: int = 0 # items covered with docstrings
    missing: list = field(default_factory=list)
    stub_items: list = field(default_factory=list)  # items present only as stubs

    @property
    def pct(self) -> float:
        return (self.covered / self.total * 100) if self.total else 100.0

    @property
    def pct_with_stubs(self) -> float:
        return ((self.covered + self.stub_covered) / self.total * 100) if self.total else 100.0


def load_entries(jp: Path) -> list[ApiEntry]:
    data = json.loads(jp.read_text(encoding='utf-8'))
    mods = data['lua_api']['modules']
    out: list[ApiEntry] = []
    for mn, m in mods.items():
        if mn == 'collision': continue
        if mn == 'collision': continue
        ex = MODULE_TO_EXAMPLE.get(mn, mn + '.lua')
        for fn in (m.get('functions') or []):
            out.append(ApiEntry(
                module=mn, name=fn['name'], is_method=False,
                owner_type='', example_file=ex,
                description=fn.get('description', ''),
                inferred_sig=fn.get('inferred_sig', '()'),
            ))
        for cn, cls in (m.get('classes') or {}).items():
            for meth in (cls.get('methods') or []):
                out.append(ApiEntry(
                    module=mn, name=meth['name'], is_method=True,
                    owner_type=cn, example_file=ex,
                    description=meth.get('description', ''),
                    inferred_sig=meth.get('inferred_sig', '()'),
                ))
    return out


def load_texts(d: Path) -> dict[str, dict]:
    """Load all .lua files.

    Returns dict: filename -> { 'blocks': dict, 'lines': int, 'comments': int }
    """
    out: dict[str, dict] = {}
    for p in d.glob('*.lua'):
        raw = p.read_text(encoding='utf-8', errors='replace')
        file_lines = raw.splitlines()
        comments = 0
        blocks = {}

        current_stub = None
        for ln in file_lines:
            stripped = ln.strip()
            if stripped.startswith('--'):
                comments += 1

            if stripped.startswith('--@api-stub:'):
                marker = stripped[len('--@api-stub:'):].strip()
                current_stub = marker
                if current_stub not in blocks:
                    blocks[current_stub] = {'has_todo': False}
            elif current_stub is not None:
                if '-- TODO:' in stripped:
                    blocks[current_stub]['has_todo'] = True

        out[p.name] = {
            'blocks': blocks,
            'lines': len(file_lines),
            'comments': comments
        }
    return out


def _match_name(entry: 'ApiEntry', text: str) -> bool:
    """Return True if entry is called in hand-written code."""
    if entry.is_method:
        pat = r':' + re.escape(entry.name) + r'\s*\('
    else:
        pat = r'\b' + re.escape(entry.name) + r'\s*\('
    return bool(re.search(pat, text))


def build_cov(entries: list[ApiEntry], texts: dict[str, dict]) -> dict[str, ModuleCov]:
    bk: dict[str, ModuleCov] = {}
    for e in entries:
        key = e.module
        if key not in bk:
            bk[key] = ModuleCov(
                key=key,
                example_file=e.example_file,
                namespace=NAMESPACE_MAP.get(key, key),
            )
        mc = bk[key]
        mc.total += 1

        data = texts.get(mc.example_file)
        if not data:
            mc.missing.append(f"{e.name} <No File>")
            continue

        mc.line_count = data['lines']
        mc.comment_count = data['comments']

        blocks = data['blocks']

        # Build the stub marker id for this entry
        if e.is_method:
            stub_id = f"{e.owner_type}:{e.name}"
        else:
            stub_id = f"lurek.{NAMESPACE_MAP.get(key, key)}.{e.name}"

        if stub_id in blocks:
            b = blocks[stub_id]
            if not b['has_todo']:
                # Block has real scenario code (-- TODO: line removed)
                mc.covered += 1
                if len(e.description.strip()) > 0:
                    mc.docstring_count += 1
            else:
                # Block still has -- TODO: -- pending, needs real example
                mc.stub_covered += 1
                mc.stub_items.append(stub_id)
        else:
            mc.missing.append(stub_id)

    return bk


def print_summary(bk: dict[str, ModuleCov], filt: str | None = None) -> None:
    print(f"\n{'Module':<18} {'Namespace':<18} {'Example':<22} {'Cov':>4} {'Stub':>4} {'Tot':>4} {'%':>5}")
    print('-' * 80)
    tc = ts = ta = 0
    for k, mc in sorted(bk.items()):
        if filt and filt.lower() not in k.lower():
            continue
        flag = ' MISSING' if not (EXAMPLES_DIR / mc.example_file).exists() else ''
        stub_flag = ' [STUBS]' if mc.stub_items else ''
        ns = f"lurek.{mc.namespace}"
        print(f'{k:<18} {ns:<18} {mc.example_file:<22} {mc.covered:>4} {mc.stub_covered:>4} {mc.total:>4} {mc.pct_with_stubs:>4.0f}%{flag}{stub_flag}')
        tc += mc.covered
        ts += mc.stub_covered
        ta += mc.total
    print('-' * 80)
    total_pct = ((tc + ts) / ta * 100) if ta else 100.0
    print(f"{'TOTAL':<62} {tc:>4} {ts:>4} {ta:>4} {total_pct:>4.0f}%")
    if ts:
        print(f"\n  NOTE: {ts} item(s) covered only by auto-stubs (--@api-stub: markers).")
        print(f"        Run --stubs to see which modules need fleshing out.")


def print_stubs(bk: dict[str, ModuleCov], filt: str | None = None) -> None:
    """Show modules that have pending --@api-stub: blocks (-- TODO: still present)."""
    found = False
    for k, mc in sorted(bk.items()):
        if filt and filt.lower() not in k.lower():
            continue
        if not mc.stub_items:
            continue
        found = True
        print(f'\n[{k}] lurek.{mc.namespace} -> {mc.example_file}: {len(mc.stub_items)} pending stub(s)')
        for fn in sorted(mc.stub_items):
            print(f'  --@api-stub: {fn}  [remove -- TODO: when done]')
    if not found:
        print('No pending stubs. All --@api-stub: blocks have real scenario code.')


def print_missing(bk: dict[str, ModuleCov], filt: str | None = None) -> None:
    for k, mc in sorted(bk.items()):
        if filt and filt.lower() not in k.lower():
            continue
        if not mc.missing and not mc.stub_items:
            continue
        exists = (EXAMPLES_DIR / mc.example_file).exists()
        status = '' if exists else ' (FILE MISSING)'
        real_pct = mc.pct
        print(f'\n[{k}] lurek.{mc.namespace} -> {mc.example_file}{status} ({real_pct:.0f}% real, {mc.stub_covered} stub)')
        for fn in sorted(mc.missing):
            print(f'  - {fn}  [MISSING -- no --@api-stub: marker]')
        for fn in sorted(mc.stub_items):
            print(f'  ~ {fn}  [PENDING -- remove -- TODO: to mark as done]')


def export_markdown(bk: dict[str, ModuleCov], out_path: str):
    p = Path(out_path)
    p.parent.mkdir(parents=True, exist_ok=True)

    with p.open('w', encoding='utf-8') as f:
        f.write("# Example Coverage & Quality Report\n\n")
        f.write("| Module | Namespace | Example File | Coverage | Stubs | Total | Length (lines) | Comments | Docstrings |\n")
        f.write("|---|---|---|---|---|---|---|---|---|\n")

        total_cov = total_stub = total_all = total_lines = total_comms = total_docs = 0
        for k, mc in sorted(bk.items()):
            ex_exists = (EXAMPLES_DIR / mc.example_file).exists()
            flag = '' if ex_exists else ' (MISSING)'

            f.write(f"| `{k}` | `lurek.{mc.namespace}` | `{mc.example_file}`{flag} | ")
            f.write(f"{mc.covered} | {mc.stub_covered} | {mc.total} | {mc.line_count} | {mc.comment_count} | {mc.docstring_count} |\n")

            total_cov += mc.covered
            total_stub += mc.stub_covered
            total_all += mc.total
            total_lines += mc.line_count
            total_comms += mc.comment_count
            total_docs += mc.docstring_count

        f.write(f"| **TOTAL** | | | **{total_cov}** | **{total_stub}** | **{total_all}** | **{total_lines}** | **{total_comms}** | **{total_docs}** |\n\n")

        pct = ((total_cov + total_stub) / total_all * 100) if total_all else 100
        f.write(f"**Overall Coverage (including stubs):** {pct:.1f}%\n")

def main() -> int:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument('--json',      action='store_true', help='Machine-readable JSON output')
    p.add_argument('--missing',   action='store_true', help='Show only missing items per module')
    p.add_argument('--stubs',     action='store_true', help='Show modules with --@api-stub: blocks remaining')
    p.add_argument('--summary',   action='store_true', help='Show summary table (default)')
    p.add_argument('--report',    action='store_true', help='CI gate: exit 1 if any gaps exist')
    p.add_argument('--no-stubs',  action='store_true', help='With --report: also fail if any stub blocks remain')
    p.add_argument('--module',    metavar='NAME',      help='Filter to one module')
    p.add_argument('--markdown',  metavar='FILE',      nargs='?', const='logs/reports/example_coverage.md', help='Export Markdown report to FILE')
    args = p.parse_args()

    if not API_JSON.exists():
        print(f'ERROR: {API_JSON} not found â€” run python tools/gen_all_docs.py first')
        return 1

    entries = load_entries(API_JSON)
    texts   = load_texts(EXAMPLES_DIR)
    bk      = build_cov(entries, texts)

    if args.module:
        bk = {k: v for k, v in bk.items() if args.module.lower() in k.lower()}

    has_gaps  = any(len(mc.missing) > 0 for mc in bk.values())
    has_stubs = any(len(mc.stub_items) > 0 for mc in bk.values())

    if args.markdown:
        export_markdown(bk, args.markdown)
        print(f"Exported Markdown report to {args.markdown}")
    elif args.json:
        print(json.dumps({
            k: {
                'namespace':    f"lurek.{mc.namespace}",
                'example_file': mc.example_file,
                'file_exists':  (EXAMPLES_DIR / mc.example_file).exists(),
                'covered':      mc.covered,
                'stub_covered': mc.stub_covered,
                'total':        mc.total,
                'pct':          round(mc.pct_with_stubs, 1),
                'missing':      sorted(mc.missing),
                'stub_items':   sorted(mc.stub_items),
            }
            for k, mc in sorted(bk.items())
        }, indent=2))
    elif args.missing:
        print_missing(bk, filt=args.module)
    elif args.stubs:
        print_stubs(bk, filt=args.module)
    else:
        print_summary(bk, filt=args.module)

    if args.report:
        failures = []
        if has_gaps:
            gaps = sum(1 for mc in bk.values() if mc.missing)
            failures.append(f'{gaps} module(s) have uncovered API items (not even stub).')
        if args.no_stubs and has_stubs:
            stubs = sum(1 for mc in bk.values() if mc.stub_items)
            failures.append(f'{stubs} module(s) still have --@api-stub: blocks (not real scenarios).')
        if failures:
            for f in failures:
                print(f'\n[REPORT] {f}')
            return 1

    return 1 if has_gaps else 0


if __name__ == '__main__':
    sys.exit(main())


