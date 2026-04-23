"""
Fix 'too many upvalues' LuaJIT errors in fishing.lua and turrican.lua
by grouping module-level constants into tables (C, STATES, EN, PU).
"""
import re
import os

ROOT = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(ROOT)  # up to repo root

# ─────────────────────────────────────────────────────────────
# FISHING.LUA
# ─────────────────────────────────────────────────────────────
fp_fishing = os.path.join(ROOT, "content", "games", "sports", "fishing", "main.lua")
text = open(fp_fishing, encoding='utf-8').read()

# Build the old const+states block by detecting the individual local lines
OLD_LINES_FISHING = [
    "local SCREEN_W = 800",
    "local SCREEN_H = 600",
    "local WATER_Y = 300",
    "local SHORE_X = 80",
    "local ROD_TIP_X = SHORE_X + 30",
    "local ROD_TIP_Y = WATER_Y - 60",
    "local MAX_CAST_DIST = 400",
    "local HOOK_WINDOW = 1.5",
    "local TENSION_SNAP = 0.80",
    "local TENSION_SNAP_TIME = 2.0",
    "local TENSION_SAFE = 0.20",
    "local REEL_SPEED = 60",
    "local FISH_PULL_SPEED = 30",
    "local FISH_BURST_CALM = 3.0",
    "local FISH_BURST_PULL = 1.0",
    "local LAND_DIST = 20",
    "local DAY_CYCLE = 120",
    "local WIN_COUNT = 10",
    "local BITE_MIN = 3.0",
    "local BITE_MAX = 10.0",
    "local RAIN_BITE_MULT = 0.5",
    # states section
    'local STATE_TITLE = "TITLE"',
    'local STATE_FISHING = "FISHING"',
    'local STATE_CATCHING = "CATCHING"',
    'local STATE_BUCKET = "BUCKET_VIEW"',
    'local STATE_GAMEOVER = "GAME_OVER"',
]

NEW_HEADER_FISHING = """\
-- Constants (grouped into C to stay within LuaJIT 60-upvalue limit)
local C = {
  SCREEN_W=800, SCREEN_H=600, WATER_Y=300, SHORE_X=80,
  ROD_TIP_X=110, ROD_TIP_Y=240,
  MAX_CAST_DIST=400, HOOK_WINDOW=1.5,
  TENSION_SNAP=0.80, TENSION_SNAP_TIME=2.0, TENSION_SAFE=0.20,
  REEL_SPEED=60, FISH_PULL_SPEED=30, FISH_BURST_CALM=3.0, FISH_BURST_PULL=1.0,
  LAND_DIST=20, DAY_CYCLE=120, WIN_COUNT=10,
  BITE_MIN=3.0, BITE_MAX=10.0, RAIN_BITE_MULT=0.5,
}
local STATES = {
  TITLE="TITLE", FISHING="FISHING", CATCHING="CATCHING",
  BUCKET="BUCKET_VIEW", GAMEOVER="GAME_OVER",
}"""

# Remove old declarations one by one
for line in OLD_LINES_FISHING:
    # match line with optional trailing spaces/comment
    text = re.sub(r'^' + re.escape(line) + r'[^\n]*\n', '', text, flags=re.MULTILINE)

# Remove the standalone comment lines for Constants/States sections
text = re.sub(r'^-- Constants\n', '', text, flags=re.MULTILINE)
text = re.sub(r'^-- States\n', '', text, flags=re.MULTILINE)

# Insert the new header after the file header comment block (first non-comment line)
# Find the first line that starts with 'local' or is not a comment
# Just insert at start
text = NEW_HEADER_FISHING + "\n\n" + text.lstrip("\n")

# Replace constant references (longest/more-specific first to avoid partial matches)
FISHING_SUBS = [
    # States first (STATE_CATCHING before STATE_* matches)
    ("STATE_CATCHING", "STATES.CATCHING"),
    ("STATE_FISHING", "STATES.FISHING"),
    ("STATE_GAMEOVER", "STATES.GAMEOVER"),
    ("STATE_BUCKET", "STATES.BUCKET"),
    ("STATE_TITLE", "STATES.TITLE"),
    # Constants (longer names first)
    ("TENSION_SNAP_TIME", "C.TENSION_SNAP_TIME"),
    ("TENSION_SNAP", "C.TENSION_SNAP"),
    ("TENSION_SAFE", "C.TENSION_SAFE"),
    ("FISH_PULL_SPEED", "C.FISH_PULL_SPEED"),
    ("FISH_BURST_CALM", "C.FISH_BURST_CALM"),
    ("FISH_BURST_PULL", "C.FISH_BURST_PULL"),
    ("RAIN_BITE_MULT", "C.RAIN_BITE_MULT"),
    ("MAX_CAST_DIST", "C.MAX_CAST_DIST"),
    ("HOOK_WINDOW", "C.HOOK_WINDOW"),
    ("REEL_SPEED", "C.REEL_SPEED"),
    ("LAND_DIST", "C.LAND_DIST"),
    ("DAY_CYCLE", "C.DAY_CYCLE"),
    ("WIN_COUNT", "C.WIN_COUNT"),
    ("ROD_TIP_X", "C.ROD_TIP_X"),
    ("ROD_TIP_Y", "C.ROD_TIP_Y"),
    ("SCREEN_W", "C.SCREEN_W"),
    ("SCREEN_H", "C.SCREEN_H"),
    ("WATER_Y", "C.WATER_Y"),
    ("SHORE_X", "C.SHORE_X"),
    ("BITE_MIN", "C.BITE_MIN"),
    ("BITE_MAX", "C.BITE_MAX"),
]

for old, new in FISHING_SUBS:
    text = re.sub(r'\b' + re.escape(old) + r'\b', new, text)

# Avoid double-prefixing (C.C.SCREEN_W etc.) — shouldn't happen but guard anyway
text = re.sub(r'\bC\.C\.', 'C.', text)
text = re.sub(r'\bSTATES\.STATES\.', 'STATES.', text)

open(fp_fishing, 'w', encoding='utf-8').write(text)
print("fishing.lua: DONE")

# ─────────────────────────────────────────────────────────────
# TURRICAN.LUA
# ─────────────────────────────────────────────────────────────
fp_turrican = os.path.join(ROOT, "content", "games", "retro", "turrican", "main.lua")
text = open(fp_turrican, encoding='utf-8').read()

# Group 1: EN table  (EN_WALKER, EN_FLYER, EN_TURRET, ENEMY_*, TURRET_*)
OLD_EN_LINES = [
    "local EN_WALKER = 1",
    "local EN_FLYER  = 2",
    "local EN_TURRET = 3",
    "local ENEMY_HP    = { [EN_WALKER] = 1, [EN_FLYER] = 2, [EN_TURRET] = 3 }",
    "local ENEMY_SPEED = { [EN_WALKER] = 60, [EN_FLYER] = 50, [EN_TURRET] = 0 }",
    "local ENEMY_W     = { [EN_WALKER] = 20, [EN_FLYER] = 18, [EN_TURRET] = 24 }",
    "local ENEMY_H     = { [EN_WALKER] = 22, [EN_FLYER] = 18, [EN_TURRET] = 20 }",
    "local ENEMY_SCORE = 50",
    "local TURRET_INTERVAL = 2.0",
    "local TURRET_BULLET_SPEED = 200",
]
NEW_EN = """\
-- Enemy constants (grouped into EN to save upvalues)
local EN = {
    WALKER=1, FLYER=2, TURRET=3,
    HP    = {[1]=1, [2]=2, [3]=3},
    SPEED = {[1]=60, [2]=50, [3]=0},
    W     = {[1]=20, [2]=18, [3]=24},
    H     = {[1]=22, [2]=18, [3]=20},
    SCORE=50, TURRET_INTERVAL=2.0, TURRET_BULLET_SPEED=200,
}"""

# Group 2: PU table
OLD_PU_LINES = [
    "local PU_SPREAD = 1",
    "local PU_HEALTH = 2",
    "local PU_AMMO   = 3",
    "local POWERUP_SCORE = 25",
]
NEW_PU = """\
-- Powerup constants
local PU = { SPREAD=1, HEALTH=2, AMMO=3, SCORE=25 }"""

# Group 3: Player / weapon constants into K
OLD_K_LINES = [
    "local PLAYER_W, PLAYER_H = 24, 28",
    "local PLAYER_SPEED       = 180",
    "local GRAVITY            = 800",
    "local JUMP_VEL           = -440",
    "local MAX_HP             = 5",
    "local MAX_AMMO           = 100",
    "local BULLET_SPEED    = 360",
    "local BULLET_W, BULLET_H = 6, 4",
    "local FIRE_COOLDOWN   = 0.12",
    "local BEAM_RANGE      = 220",
    "local BEAM_DRAIN      = 3   -- ammo per second",
    "local SPREAD_ANGLE    = 0.18 -- radians offset for spread",
]
NEW_K = """\
-- Player/weapon constants (grouped into K to save upvalues)
local K = {
    PW=24, PH=28, PSPD=180, GRAV=800, JVEL=-440, MAX_HP=5, MAX_AMMO=100,
    BSPD=360, BW=6, BH=4, FIRE_CD=0.12, BEAM_RANGE=220, BEAM_DRAIN=3, SPREAD=0.18,
}"""

# Apply EN replacements
for line in OLD_EN_LINES:
    text = re.sub(r'^[ \t]*' + re.escape(line) + r'[^\n]*\n', '', text, flags=re.MULTILINE)
# Remove enemies section header comment
text = re.sub(r'^-- Enemies\n', '', text, flags=re.MULTILINE)
text = re.sub(r'^-- Weapons\n', '', text, flags=re.MULTILINE)

# Insert EN block after the STATE block (after "local STATE = {...}")
text = re.sub(r'(local STATE = \{[^\}]*\}\n)', r'\1' + '\n' + NEW_EN + '\n', text)

# Apply PU replacements
for line in OLD_PU_LINES:
    text = re.sub(r'^[ \t]*' + re.escape(line) + r'[^\n]*\n', '', text, flags=re.MULTILINE)
text = re.sub(r'^-- Powerup types\n', '', text, flags=re.MULTILINE)
# Insert PU after EN block
text = re.sub(r'(local PU = \{ SPREAD.*?\}\n)', r'\1', text)  # already inserted? no...
# Just append PU after EN
text = re.sub(r'(    SCORE=50, TURRET_INTERVAL=2\.0, TURRET_BULLET_SPEED=200,\n\})', 
              r'\1\n' + NEW_PU, text)

# Apply K replacements
for line in OLD_K_LINES:
    text = re.sub(r'^[ \t]*' + re.escape(line) + r'[^\n]*\n', '', text, flags=re.MULTILINE)
text = re.sub(r'^-- Player\n', '', text, flags=re.MULTILINE)
# Insert K after PU
text = re.sub(r'(local PU = \{ SPREAD=1, HEALTH=2, AMMO=3, SCORE=25 \}\n)',
              r'\1' + NEW_K + '\n', text)

# Now replace all EN_* and ENEMY_* and TURRET_* references
EN_SUBS = [
    ("ENEMY_SCORE", "EN.SCORE"),
    ("TURRET_INTERVAL", "EN.TURRET_INTERVAL"),
    ("TURRET_BULLET_SPEED", "EN.TURRET_BULLET_SPEED"),
    ("ENEMY_SPEED", "EN.SPEED"),
    ("ENEMY_W", "EN.W"),
    ("ENEMY_H", "EN.H"),
    ("ENEMY_HP", "EN.HP"),
    ("EN_WALKER", "EN.WALKER"),
    ("EN_FLYER",  "EN.FLYER"),
    ("EN_TURRET", "EN.TURRET"),
]
PU_SUBS = [
    ("POWERUP_SCORE", "PU.SCORE"),
    ("PU_SPREAD", "PU.SPREAD"),
    ("PU_HEALTH", "PU.HEALTH"),
    ("PU_AMMO",   "PU.AMMO"),
]
K_SUBS = [
    ("PLAYER_W",     "K.PW"),
    ("PLAYER_H",     "K.PH"),
    ("PLAYER_SPEED", "K.PSPD"),
    ("GRAVITY",      "K.GRAV"),
    ("JUMP_VEL",     "K.JVEL"),
    ("MAX_HP",       "K.MAX_HP"),
    ("MAX_AMMO",     "K.MAX_AMMO"),
    ("BULLET_SPEED", "K.BSPD"),
    ("BULLET_W",     "K.BW"),
    ("BULLET_H",     "K.BH"),
    ("FIRE_COOLDOWN","K.FIRE_CD"),
    ("BEAM_RANGE",   "K.BEAM_RANGE"),
    ("BEAM_DRAIN",   "K.BEAM_DRAIN"),
    ("SPREAD_ANGLE", "K.SPREAD"),
]

for old, new in EN_SUBS + PU_SUBS + K_SUBS:
    text = re.sub(r'\b' + re.escape(old) + r'\b', new, text)

# Guard against double-prefix
for prefix in ("EN.", "PU.", "K."):
    text = re.sub(re.escape(prefix) + re.escape(prefix), prefix, text)

open(fp_turrican, 'w', encoding='utf-8').write(text)
print("turrican.lua: DONE")
