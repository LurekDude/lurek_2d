--[[
  collision.lua — lurek.collision stateless overlap helpers
  =========================================================
  Demonstrates pure-math geometric collision tests that require no physics world.
  Useful for RPG, puzzle, or visual-novel games that only need simple overlap
  detection rather than full rigid-body simulation.

  Run with:
    cargo run -- content/examples/collision.lua
--]]

-- ─── AABB vs AABB ────────────────────────────────────────────────────────────

local playerX, playerY, playerW, playerH = 10, 10, 32, 32
local wallX,   wallY,   wallW,   wallH   = 30, 30, 64, 16

local touching = lurek.collision.testAABB(
  playerX, playerY, playerW, playerH,
  wallX,   wallY,   wallW,   wallH
)
print("Player touches wall:", touching)  -- true: overlapping rectangles

local farBox = lurek.collision.testAABB(0, 0, 10, 10, 200, 200, 10, 10)
print("Far boxes overlap:", farBox)      -- false

-- ─── Circle vs Circle ────────────────────────────────────────────────────────

local bulletX, bulletY, bulletR = 50, 50, 4
local enemyX,  enemyY,  enemyR  = 55, 52, 16

local hit = lurek.collision.testCircles(bulletX, bulletY, bulletR, enemyX, enemyY, enemyR)
print("Bullet hits enemy:", hit)         -- true: radii overlap

-- ─── Point inside AABB ───────────────────────────────────────────────────────

local mouseX, mouseY = 45, 45
local buttonX, buttonY, buttonW, buttonH = 40, 40, 80, 20

local clicked = lurek.collision.testPoint(mouseX, mouseY, buttonX, buttonY, buttonW, buttonH)
print("Mouse clicked button:", clicked)  -- true: point is inside

-- ─── Circle vs AABB ──────────────────────────────────────────────────────────

local explosionX, explosionY, explosionR = 100, 100, 50
local crateX, crateY, crateW, crateH    = 90, 110, 24, 24

local blasted = lurek.collision.testCircleAABB(
  explosionX, explosionY, explosionR,
  crateX, crateY, crateW, crateH
)
print("Explosion reaches crate:", blasted)  -- true: circle overlaps AABB corner

-- ─── Edge cases ──────────────────────────────────────────────────────────────

-- Touching edges are NOT overlapping (open-interval test).
local edgeTouching = lurek.collision.testAABB(0, 0, 10, 10, 10, 0, 10, 10)
print("Edge-touching boxes overlap:", edgeTouching)  -- false

-- Point on right edge is NOT inside (exclusive upper bound).
local edgePoint = lurek.collision.testPoint(10, 5, 0, 0, 10, 10)
print("Point on right edge is inside:", edgePoint)   -- false
