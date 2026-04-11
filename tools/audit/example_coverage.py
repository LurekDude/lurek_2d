#!/usr/bin/env python3
"""Cross-reference content/examples/ scripts against the lurek.* Lua API.

Reports which API functions are covered by an example and which are not.

Usage:
    python tools/audit/example_coverage.py
"""
from __future__ import annotations
import argparse, json, re, sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
API_JSON = ROOT / 'docs' / 'logs' / 'lua_api_data.json'
EXAMPLES_DIR = ROOT / 'content' / 'examples'

MODULE_TO_EXAMPLE = {
    'ai':'ai.lua','animation':'animation.lua','audio':'audio.lua',
    'automation':'automation.lua','camera':'camera.lua','compute':'compute.lua',
    'data':'data.lua','dataframe':'dataframe.lua','debugbridge':'debugbridge.lua',
    'devtools':'devtools.lua','docs':'docs.lua','entity':'entity.lua',
    'event':'event.lua','filesystem':'filesystem.lua','fx':'fx.lua',
    'graph':'graph.lua','graphics':'graphics.lua','gui':'gui.lua',
    'image':'image.lua','input':'input.lua','light':'light.lua',
    'localization':'localization.lua','log':'log.lua','math':'math.lua',
    'minimap':'minimap.lua','modding':'modding.lua','network':'network.lua',
    'particle':'particle.lua','pathfinding':'pathfinding.lua',
    'patterns':'patterns.lua','physics':'physics.lua','pipeline':'pipeline.lua',
    'procgen':'procgen.lua','raycaster':'raycaster.lua','savegame':'savegame.lua',
    'scene':'scene.lua','serial':'serial.lua','spine':'spine.lua',
    'system':'window.lua','terminal':'terminal.lua','thread':'thread.lua',
    'tilemap':'tilemap.lua','timer':'timer.lua','window':'window.lua',
}

@dataclass
class ApiEntry:
    module:str; lua_name:str; name:str; is_method:bool; owner:str; example_file:str
    description:str=''; inferred_sig:str='()'; typed_params:list=field(default_factory=list)

@dataclass
class ModuleCov:
    key:str; example_file:str; total:int=0; covered:int=0
    missing:list=field(default_factory=list)
    @property
    def pct(self): return (self.covered/self.total*100) if self.total else 100.0

def load_entries(jp):
    data=json.loads(jp.read_text(encoding='utf-8'))
    mods=data['lua_api']['modules']; out=[]
    for mn,m in mods.items():
        ex=MODULE_TO_EXAMPLE.get(mn,'')
        for fn in (m.get('functions') or []):
            out.append(ApiEntry(mn,fn['lua_name'],fn['name'],False,'',ex,
                fn.get('description',''),fn.get('inferred_sig','()'),fn.get('typed_params',[])))
        for cn,cls in (m.get('classes') or {}).items():
            for meth in (cls.get('methods') or []):
                out.append(ApiEntry(mn,meth['lua_name'],meth['name'],True,cn,ex,
                    meth.get('description',''),meth.get('inferred_sig','()'),meth.get('typed_params',[])))
    return out

def load_texts(d): return {p.name:p.read_text(encoding='utf-8') for p in d.glob('*.lua')}

def build_cov(entries,texts):
    bk={}
    for e in entries:
        key=e.owner if e.is_method else e.module
        if key not in bk: bk[key]=ModuleCov(key=key,example_file=e.example_file)
        mc=bk[key]; mc.total+=1
        text=texts.get(mc.example_file,'')
        if not text: mc.missing.append(e.name); continue
        if e.is_method: pat=r':'+re.escape(e.name)+r'\s*\('
        else: pat=r'(?:luna\.\w+)\.'+re.escape(e.name)+r'\s*\('
        if re.search(pat,text): mc.covered+=1
        else: mc.missing.append(e.name)
    return bk

def print_summary(bk):
    print(f"\n{'Module':<30} {'Example':<25} {'Covered':>7} {'Total':>7} {'%':>6}"); print('-'*80)
    tc=ta=0
    for k,mc in sorted(bk.items()):
        print(f'{k:<30} {mc.example_file or chr(40)+chr(110)+chr(111)+chr(110)+chr(101)+chr(41):<25} {mc.covered:>7} {mc.total:>7} {mc.pct:.0f}%')
        tc+=mc.covered; ta+=mc.total
    print('-'*80); print(f"{'TOTAL':<56} {tc:>7} {ta:>7} {(tc/ta*100 if ta else 100):.0f}%")

def print_missing(bk,filt=None):
    for k,mc in sorted(bk.items()):
        if filt and filt.lower() not in k.lower(): continue
        if not mc.missing: continue
        print(f'\n[{k}] -> {mc.example_file} ({mc.pct:.0f}%)')
        for fn in sorted(mc.missing): print(f'  - {fn}')

def main():
    p=argparse.ArgumentParser(); p.add_argument('--json',action='store_true')
    p.add_argument('--missing',action='store_true'); p.add_argument('--summary',action='store_true')
    p.add_argument('--module',metavar='NAME'); args=p.parse_args()
    if not API_JSON.exists(): print(f'ERROR: {API_JSON} not found'); sys.exit(1)
    entries=load_entries(API_JSON); texts=load_texts(EXAMPLES_DIR); bk=build_cov(entries,texts)
    if args.json:
        print(json.dumps({k:{'example_file':mc.example_file,'covered':mc.covered,'total':mc.total,
            'pct':round(mc.pct,1),'missing':sorted(mc.missing)} for k,mc in sorted(bk.items())},indent=2))
    elif args.missing: print_missing(bk,args.module)
    else: print_summary(bk)
    ta=sum(mc.total for mc in bk.values()); tc=sum(mc.covered for mc in bk.values())
    sys.exit(0 if tc==ta else 1)

if __name__=='__main__': main()
