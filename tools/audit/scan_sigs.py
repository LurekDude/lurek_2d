"""Find exact function registrations for failing APIs in Rust source files."""
import re, os

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), '..', '..'))

files = {
  'src/lua_api/ai_api.rs': ['newDirector','newFSM','newBehaviorTree','newBandit','newUtility'],
  'src/lua_api/animation_api.rs': ['stateMachine','newStateMachine'],
  'src/lua_api/data_api.rs': ['newBuffer','newView','newRingBuffer','newByteBuffer'],
  'src/lua_api/devtools_api.rs': ['newWatcher','watch','getWatch','addWatch'],
  'src/lua_api/docs_api.rs': ['get','getSchema','getEntry','validate'],
  'src/lua_api/event_api.rs': ['on','clear','emit','remove','clearAll'],
  'src/lua_api/filesystem_api.rs': ['read','write','readFile','writeFile'],
  'src/lua_api/globe_api.rs': ['newGlobe','newProvince','getCell'],
  'src/lua_api/graph_api.rs': ['addItem','addEdge','addNode','add','insert'],
  'src/lua_api/html_api.rs': ['newHud','new','on'],
  'src/lua_api/image_api.rs': ['newData','load','fromFile','fromPath'],
  'src/lua_api/input_api.rs': ['newManager','new','newActionMap','register'],
  'src/lua_api/light_api.rs': ['newPoint','new','newAmbient','newScene'],
  'src/lua_api/math_api.rs': ['newCatmullRom','newHermite','newVec2','newVec3','random','randomInt'],
  'src/lua_api/mods_api.rs': ['getLoaded','getMod','getAll','getAllMods'],
  'src/lua_api/network_api.rs': ['newHost','newClient','create'],
  'src/lua_api/pathfind_api.rs': ['newGrid','newFlowField','newHexGrid','newNavGrid'],
  'src/lua_api/patterns_api.rs': ['remove','newList'],
  'src/lua_api/physics_api.rs': ['setSleepingAllowed','isSleepingAllowed','newCellular','newTerrain','newZone'],
  'src/lua_api/pipeline_api.rs': ['getSteps','getStep','getAllSteps'],
  'src/lua_api/raycaster_api.rs': ['new'],
  'src/lua_api/render_api.rs': ['rect','draw','setColor','arc'],
  'src/lua_api/sprite_api.rs': ['newSheet','newSprite'],
  'src/lua_api/thread_api.rs': ['newPool','newPromise','newWorker'],
  'src/lua_api/tilemap_api.rs': ['newIsoMap','newLargeMap','newAutoTileSheet'],
  'src/lua_api/ui_api.rs': ['type','typeOf','newLabel','newSeparator','newToolbar'],
}

for relpath, searches in files.items():
    fpath = os.path.join(ROOT, relpath)
    if not os.path.exists(fpath):
        print(f'MISSING: {relpath}')
        continue
    with open(fpath, encoding='utf-8') as f:
        lines = f.readlines()
    hits = []
    for i, line in enumerate(lines):
        ls = line.rstrip()
        if any(f'"{s}"' in ls for s in searches) or any(f'fn {s}' in ls for s in searches):
            hits.append(f'  {i+1}: {ls}')
    if hits:
        print(f'\n{relpath}:')
        for h in hits[:25]:
            print(h)
