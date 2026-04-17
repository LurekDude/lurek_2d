-- content/examples/compute.lua
-- Lurek2D lurek.compute API Reference
-- Run with: cargo run -- content/examples/compute
--
-- Scenario: An image processing pipeline — load a heightmap as an array,
-- apply convolution filters (blur, edge detect), normalize values, compute
-- statistics, and perform FFT analysis. Also demonstrates matrix math for
-- 2D transforms and bitwise operations for tile flag encoding.

print("=== lurek.compute — Numeric Arrays ===\n")

-- =============================================================================
-- Array Creation
-- =============================================================================

--@api-stub: lurek.compute.newArray
local arr = lurek.compute.newArray({4, 4}, "f32")

--@api-stub: lurek.compute.zeros
local black = lurek.compute.zeros({256, 256}, "f32")

--@api-stub: lurek.compute.ones
local white = lurek.compute.ones({256, 256}, "f32")

--@api-stub: lurek.compute.range
local ramp = lurek.compute.range(0, 255, 1, "f32")

--@api-stub: lurek.compute.fromTable
local kernel = lurek.compute.fromTable({
    {-1, -1, -1},
    {-1,  8, -1},
    {-1, -1, -1},
}, "f32")

-- =============================================================================
-- Array Properties
-- =============================================================================

--@api-stub: Array:getShape
local shape = arr:getShape()
print("shape: " .. shape[1] .. "x" .. shape[2])

--@api-stub: Array:getDimensions
print("dims: " .. arr:getDimensions())

--@api-stub: Array:getSize
print("total elements: " .. arr:getSize())

--@api-stub: Array:getDataType
print("dtype: " .. arr:getDataType())

--@api-stub: Array:isOnGPU
print("on GPU: " .. tostring(arr:isOnGPU()))

-- =============================================================================
-- Element Access
-- =============================================================================

--@api-stub: Array:set
arr:set({1, 1}, 42.0)
arr:set({2, 3}, 7.5)

--@api-stub: Array:get
print("arr[1,1]: " .. arr:get({1, 1}))

--@api-stub: Array:fill
arr:fill(1.0)

--@api-stub: Array:toTable
local t = arr:toTable()
print("table elements: " .. #t)

-- =============================================================================
-- Shape Operations
-- =============================================================================

--@api-stub: Array:reshape
local flat = arr:reshape({16})
print("reshaped: " .. flat:getSize())

--@api-stub: Array:clone
local copy = arr:clone()

--@api-stub: Array:transpose
local transposed = arr:transpose()

-- =============================================================================
-- Math Operations — Element-wise
-- =============================================================================

--@api-stub: Array:pow
local squared = arr:pow(2)

--@api-stub: Array:sqrt
local roots = squared:sqrt()

--@api-stub: Array:abs
local magnitudes = arr:abs()

--@api-stub: Array:neg
local negated = arr:neg()

--@api-stub: Array:clamp
local clamped = arr:clamp(0.0, 1.0)

--@api-stub: Array:threshold
-- Binary threshold for edge detection output.
local binary = arr:threshold(0.5)

-- =============================================================================
-- Reduction Operations — Statistics
-- =============================================================================

--@api-stub: Array:sum
print("sum: " .. arr:sum())

--@api-stub: Array:mean
print("mean: " .. arr:mean())

--@api-stub: Array:min
print("min: " .. arr:min())

--@api-stub: Array:max
print("max: " .. arr:max())

--@api-stub: Array:argmin
print("argmin: " .. arr:argmin())

--@api-stub: Array:argmax
print("argmax: " .. arr:argmax())

--@api-stub: Array:countNonZero
print("nonzero: " .. arr:countNonZero())

--@api-stub: Array:any
print("any > 0: " .. tostring(arr:any()))

--@api-stub: Array:all
print("all > 0: " .. tostring(arr:all()))

-- =============================================================================
-- Cumulative & Differential
-- =============================================================================

--@api-stub: Array:cumsum
local cumulative = ramp:cumsum()

--@api-stub: Array:diff
local gradient = ramp:diff()

--@api-stub: Array:percentile
print("median: " .. ramp:percentile(50))

-- =============================================================================
-- Matrix Operations
-- =============================================================================

--@api-stub: Array:matmul
local a = lurek.compute.fromTable({{1,2},{3,4}}, "f32")
local b = lurek.compute.fromTable({{5,6},{7,8}}, "f32")
local product = a:matmul(b)
print("matmul [1,1]: " .. product:get({1, 1}))

--@api-stub: Array:dot
local d = a:dot(b)
print("dot: " .. d)

--@api-stub: Array:outer
local v1 = lurek.compute.fromTable({1, 2, 3}, "f32")
local v2 = lurek.compute.fromTable({4, 5}, "f32")
local outer_prod = v1:outer(v2)
print("outer shape: " .. outer_prod:getShape()[1] .. "x" .. outer_prod:getShape()[2])

--@api-stub: Array:linsolve
-- Solve Ax = b for level editor constraint solving.
local solution = a:linsolve(lurek.compute.fromTable({1, 2}, "f32"))

--@api-stub: Array:luDecompose
local L, U = a:luDecompose()

-- =============================================================================
-- Statistical Analysis
-- =============================================================================

--@api-stub: Array:covariance
local cov = a:covariance(b)
print("covariance: " .. cov)

--@api-stub: Array:pearsonCorr
local corr = a:pearsonCorr(b)
print("correlation: " .. corr)

--@api-stub: Array:normalizeRange
local normed = arr:normalizeRange()

--@api-stub: Array:zscore
local zscored = arr:zscore()

-- =============================================================================
-- Convolution & Image Processing
-- =============================================================================

--@api-stub: lurek.compute.gaussianKernel
local blur_kernel = lurek.compute.gaussianKernel(5, 1.0)

--@api-stub: Array:convolve2D
-- Apply edge detection kernel to the heightmap.
local edges = black:convolve2D(kernel)

--@api-stub: Array:convolve1d
local smoothed = ramp:convolve1d(lurek.compute.fromTable({0.25, 0.5, 0.25}, "f32"))

--@api-stub: Array:correlate1d
local correlated = ramp:correlate1d(lurek.compute.fromTable({1, -1}, "f32"))

--@api-stub: Array:dilate
local dilated = binary:dilate(3)

--@api-stub: Array:erode
local eroded = binary:erode(3)

--@api-stub: Array:sobel
-- Sobel edge detection for terrain slope visualization.
local sobel_result = black:sobel()

-- =============================================================================
-- FFT — Frequency analysis
-- =============================================================================

--@api-stub: lurek.compute.fft
local freq = lurek.compute.fft(ramp)

--@api-stub: lurek.compute.ifft
local spatial = lurek.compute.ifft(freq)

--@api-stub: lurek.compute.fftMagnitude
local magnitude = lurek.compute.fftMagnitude(freq)

-- =============================================================================
-- Geometry Transforms
-- =============================================================================

--@api-stub: lurek.compute.rotate2dMatrix
local rot = lurek.compute.rotate2dMatrix(math.pi / 4)

--@api-stub: lurek.compute.affine2d
local affine = lurek.compute.affine2d(1, 0, 10, 0, 1, 20)

--@api-stub: Array:transformPoints
-- Transform a set of 2D points.
local points = lurek.compute.fromTable({{10, 20}, {30, 40}}, "f32")
local transformed = points:transformPoints(affine)

--@api-stub: Array:normalizeVec
local directions = lurek.compute.fromTable({{3, 4}, {0, 5}}, "f32")
local unit_dirs = directions:normalizeVec()

--@api-stub: Array:cross2d
local cross = lurek.compute.fromTable({3, 4}, "f32"):cross2d(lurek.compute.fromTable({1, 2}, "f32"))
print("2D cross: " .. cross)

-- =============================================================================
-- Bitwise Operations — Tile flag encoding
-- =============================================================================

--@api-stub: Array:bitwiseAnd
local flags = lurek.compute.fromTable({0xFF, 0x0F, 0xF0}, "u32")
local masked = flags:bitwiseAnd(lurek.compute.fromTable({0x0F, 0x0F, 0x0F}, "u32"))

--@api-stub: Array:bitwiseOr
local combined = flags:bitwiseOr(lurek.compute.fromTable({0x01, 0x02, 0x04}, "u32"))

--@api-stub: Array:bitwiseXor
local toggled = flags:bitwiseXor(lurek.compute.fromTable({0xFF, 0xFF, 0xFF}, "u32"))

--@api-stub: Array:bitwiseNot
local inverted = flags:bitwiseNot()

--@api-stub: Array:bitwiseLShift
local shifted_l = flags:bitwiseLShift(4)

--@api-stub: Array:bitwiseRShift
local shifted_r = flags:bitwiseRShift(4)

-- =============================================================================
-- Type & Identity
-- =============================================================================

--@api-stub: Array:type
print("type: " .. arr:type())

--@api-stub: Array:typeOf
print("is Array: " .. tostring(arr:typeOf("Array")))

print("\n-- compute.lua example complete --")
-- content/examples/compute.lua
-- Lurek2D lurek.compute API Reference
-- Run with: cargo run -- content/examples/compute

-- =============================================================================
-- STUBS: 67 uncovered lurek.compute API item(s)
-- =============================================================================

-- ---- Stub: lurek.compute.newArray ----------------------------------------
--@api-stub: lurek.compute.newArray
-- Allocate a 4x4 zero-initialised f32 array to hold a sprite transform
-- matrix that will be written field-by-field before upload.
local mat = lurek.compute.newArray({ 4, 4 }, "f32")
print("array shape:", mat:getDimensions(), "dims")

-- ---- Stub: lurek.compute.zeros -------------------------------------------
--@api-stub: lurek.compute.zeros
-- Create a 64-element zero array as the initial activation vector for
-- a simple neural network layer.
local z = lurek.compute.zeros({ 64 }, "f32")
print("zeros size:", z:getSize())

-- ---- Stub: lurek.compute.ones --------------------------------------------
--@api-stub: lurek.compute.ones
-- Build a weight mask of ones to represent "all connections enabled"
-- before selectively zeroing out pruned neuron links.
local ones = lurek.compute.ones({ 8, 8 }, "f32")
print("ones dtype:", ones:getDataType())

-- ---- Stub: lurek.compute.range -------------------------------------------
--@api-stub: lurek.compute.range
-- Generate a 0..99 index array to vectorise tile-index arithmetic
-- without a Lua for loop.
local idx = lurek.compute.range(0, 100, 1, "i32")
print("range size:", idx:getSize())  -- 100

-- ---- Stub: lurek.compute.fromTable ---------------------------------------
--@api-stub: lurek.compute.fromTable
-- Load a 2x3 tilemap cost grid from a Lua table so pathfinding can
-- iterate costs as a vectorised array instead of nested tables.
local arr = lurek.compute.fromTable({ 1,2,3, 4,5,6 }, { 2, 3 }, "f32")
print("arr shape:", arr:getShape()[1], "x", arr:getShape()[2])

-- ---- Stub: lurek.compute.gaussianKernel ----------------------------------
--@api-stub: lurek.compute.gaussianKernel
-- Build a 5x5 Gaussian blur kernel for post-processing a fog-of-war
-- texture so unexplored edges fade smoothly.
local kern = lurek.compute.gaussianKernel(5, 1.0)
print("kernel size:", kern:getSize())

-- ---- Stub: lurek.compute.rotate2dMatrix ----------------------------------
--@api-stub: lurek.compute.rotate2dMatrix
-- Create a rotation matrix for a spinning coin animation at 45 degrees
-- each frame to pass to the sprite batch transform.
local rot = lurek.compute.rotate2dMatrix(math.pi / 4)
print("rotation matrix dims:", rot:getDimensions())

-- ---- Stub: lurek.compute.affine2d ----------------------------------------
--@api-stub: lurek.compute.affine2d
-- Build a combined translate+rotate affine matrix for a turret that
-- needs to be rendered offset from the tank body.
local aff = lurek.compute.affine2d(100, 50, math.pi / 6, 1.0, 1.0)
print("affine shape:", aff:getShape()[1], "x", aff:getShape()[2])

-- ---- Stub: lurek.compute.fft ---------------------------------------------
--@api-stub: lurek.compute.fft
-- Analyse a recorded audio waveform from the OST buffer to extract
-- dominant frequency bins for a visualiser bar graph.
local samples = {}
for i = 1, 64 do samples[i] = math.sin(2 * math.pi * i / 16) end
local spectrum = lurek.compute.fft(samples)
print("FFT bins:", #spectrum)

-- ---- Stub: lurek.compute.ifft --------------------------------------------
--@api-stub: lurek.compute.ifft
-- Reconstruct the original waveform from a filtered frequency domain
-- to apply a low-pass effect on procedural audio.
local restored = lurek.compute.ifft(spectrum)
print("iFFT samples:", #restored)

-- ---- Stub: lurek.compute.fftMagnitude ------------------------------------
--@api-stub: lurek.compute.fftMagnitude
-- Compute the magnitude spectrum to drive the equaliser bars in the
-- music player HUD without the phase information.
local magnitudes = lurek.compute.fftMagnitude(samples)
print("max magnitude:", magnitudes[1])

-- -----------------------------------------------------------------------------
-- Array methods
-- -----------------------------------------------------------------------------

-- ---- Stub: Array:getShape ------------------------------------------------
--@api-stub: Array:getShape
-- Read the shape table to validate that a loaded tile map has the
-- expected grid dimensions before running pathfinding on it.
local shape = arr:getShape()
print("shape:", shape[1], "rows,", shape[2], "cols")

-- ---- Stub: Array:getDimensions -------------------------------------------
--@api-stub: Array:getDimensions
-- Check the number of dimensions to dispatch a 1D cost function vs
-- a 2D grid traversal algorithm.
print("dimensions:", arr:getDimensions())  -- 2

-- ---- Stub: Array:getSize -------------------------------------------------
--@api-stub: Array:getSize
-- Read total element count before allocating a matching Lua table
-- for element-by-element comparison in a test.
print("total elements:", arr:getSize())  -- 6

-- ---- Stub: Array:getDataType ---------------------------------------------
--@api-stub: Array:getDataType
-- Verify the array's dtype before passing it to a bitwise operation
-- that requires Int32 input.
print("data type:", arr:getDataType())  -- "f32"

-- ---- Stub: Array:isOnGPU -------------------------------------------------
--@api-stub: Array:isOnGPU
-- Guard a GPU-path codebranch to fall back to the CPU implementation
-- when the array has not been uploaded.
print("on GPU:", arr:isOnGPU())  -- false (CPU array)

-- ---- Stub: Array:get -----------------------------------------------------
--@api-stub: Array:get
-- Read the cost value of a specific grid cell by row+col index when
-- the A* heuristic needs to sample individual tile weights.
print("cost at (1,2):", arr:get(1, 2))  -- 2.0

-- ---- Stub: Array:set -----------------------------------------------------
--@api-stub: Array:set
-- Write a high-cost value to a cell when placing an obstacle so the
-- pathfinder avoids it without rebuilding the entire cost grid.
arr:set(1, 3, 99.0)
print("obstacle cost:", arr:get(1, 3))  -- 99.0

-- ---- Stub: Array:toTable -------------------------------------------------
--@api-stub: Array:toTable
-- Dump all cost values to a Lua table for serialisation into the save
-- file so the modified tile map can be restored next session.
local flat = arr:toTable()
print("flat table length:", #flat)

-- ---- Stub: Array:reshape -------------------------------------------------
--@api-stub: Array:reshape
-- Flatten the 2D cost grid to a 1D vector before passing it to a
-- neural network layer that expects a flat input.
local flat_arr = arr:reshape({ 6 })
print("reshaped to 1D, size:", flat_arr:getSize())

-- ---- Stub: Array:clone ---------------------------------------------------
--@api-stub: Array:clone
-- Clone the master cost grid before running a search so the search
-- can mark visited cells without corrupting the original.
local working = arr:clone()
working:set(1, 1, 0)
print("clone differs from original:", working:get(1,1) ~= arr:get(1,1))

-- ---- Stub: Array:transpose -----------------------------------------------
--@api-stub: Array:transpose
-- Transpose the adjacency matrix to invert edge directions in the
-- graph so ancestor queries can reuse the same structure.
local adj = lurek.compute.fromTable({ 1,0,0,1,0,1,0,0,1 }, { 3, 3 }, "f32")
local adjT = adj:transpose()
print("transposed (0,1):", adjT:get(1, 2))

-- ---- Stub: Array:fill ----------------------------------------------------
--@api-stub: Array:fill
-- Reset the influence map to 0 before accumulating new threat values
-- at the start of each AI tick.
local inf_map = lurek.compute.newArray({ 16, 16 }, "f32")
inf_map:fill(0.0)
print("influence map cleared, sample:", inf_map:get(1, 1))

-- ---- Stub: Array:pow -----------------------------------------------------
--@api-stub: Array:pow
-- Square each distance value in the heuristic array to emphasise
-- greater separation in the A* priority calculation.
local dist = lurek.compute.fromTable({ 1, 2, 3, 4 }, { 4 }, "f32")
local dist2 = dist:pow(2)
print("squared distances:", dist2:get(1), dist2:get(2))  -- 1, 4

-- ---- Stub: Array:sqrt ----------------------------------------------------
--@api-stub: Array:sqrt
-- Compute Euclidean distances from squared difference arrays without
-- a Lua loop for a 2D influence map range pass.
local sq = lurek.compute.fromTable({ 4, 9, 16, 25 }, { 4 }, "f32")
local rooted = sq:sqrt()
print("distances:", rooted:get(1), rooted:get(2))  -- 2, 3

-- ---- Stub: Array:abs -----------------------------------------------------
--@api-stub: Array:abs
-- Take the absolute value of signed delta arrays to compute the
-- L1 norm for a pathfinding Manhattan heuristic.
local deltas = lurek.compute.fromTable({ -3, 1, -5, 2 }, { 4 }, "f32")
local abs_d = deltas:abs()
print("abs deltas:", abs_d:get(1), abs_d:get(2))  -- 3, 1

-- ---- Stub: Array:neg -----------------------------------------------------
--@api-stub: Array:neg
-- Negate the reward array to convert a reward landscape into a cost
-- landscape for cost-minimising search algorithms.
local reward = lurek.compute.fromTable({ 10, -3, 5 }, { 3 }, "f32")
local cost = reward:neg()
print("cost values:", cost:get(1), cost:get(2))  -- -10, 3

-- ---- Stub: Array:clamp ---------------------------------------------------
--@api-stub: Array:clamp
-- Clamp network activation outputs to the [-1, 1] tanh range to avoid
-- exploding gradient values during training.
local raw_act = lurek.compute.fromTable({ -2, 0.5, 1.8, -0.3 }, { 4 }, "f32")
local clamped = raw_act:clamp(-1.0, 1.0)
print("clamped:", clamped:get(1), clamped:get(3))  -- -1, 1

-- ---- Stub: Array:threshold -----------------------------------------------
--@api-stub: Array:threshold
-- Binarise the influence map at 0.5 to produce a reachability mask
-- where cells the AI considers accessible are marked 1.
local influences = lurek.compute.fromTable({ 0.1, 0.6, 0.4, 0.9 }, { 4 }, "f32")
local mask = influences:threshold(0.5)
print("mask:", mask:get(1), mask:get(2))  -- 0, 1

-- ---- Stub: Array:countNonZero --------------------------------------------
--@api-stub: Array:countNonZero
-- Count reachable cells in the binarised mask to decide whether
-- there is any valid path before running expensive A*.
print("reachable cells:", mask:countNonZero())  -- 2

-- ---- Stub: Array:argmin --------------------------------------------------
--@api-stub: Array:argmin
-- Find the flat index of the lowest-cost tile in the heuristic to
-- select the best candidate frontier node.
local costs_1d = lurek.compute.fromTable({ 5, 2, 8, 1, 6 }, { 5 }, "f32")
print("lowest cost index:", costs_1d:argmin())  -- 4

-- ---- Stub: Array:argmax --------------------------------------------------
--@api-stub: Array:argmax
-- Find the highest-influence tile in the threat map to select the
-- AI's highest-priority attack target.
print("highest influence index:", influences:argmax())  -- 4

-- ---- Stub: Array:any -----------------------------------------------------
--@api-stub: Array:any
-- Check if any cell is reachable before running pathfinding to avoid
-- a wasted search on a completely isolated island.
print("any reachable:", mask:any())  -- true

-- ---- Stub: Array:all -----------------------------------------------------
--@api-stub: Array:all
-- Verify all activation outputs are positive before applying a log
-- transform to avoid NaN from negative inputs.
local pos = lurek.compute.fromTable({ 0.1, 0.5, 0.9 }, { 3 }, "f32")
print("all positive:", pos:all())  -- true

-- ---- Stub: Array:sum -----------------------------------------------------
--@api-stub: Array:sum
-- Sum all influence values to compute the total threat pressure on the
-- player from the surrounding AI units.
print("total influence:", influences:sum())

-- ---- Stub: Array:mean ----------------------------------------------------
--@api-stub: Array:mean
-- Compute the average tile cost to normalise the cost map before
-- training a navigation heuristic model.
print("mean cost:", costs_1d:mean())

-- ---- Stub: Array:min -----------------------------------------------------
--@api-stub: Array:min
-- Find the minimum value in the cost array to rescale it into a 0-1
-- range for a colour-mapped debug visualisation.
print("min cost:", costs_1d:min())  -- 1

-- ---- Stub: Array:max -----------------------------------------------------
--@api-stub: Array:max
-- Find the maximum influence value to drive the threshold for the AI
-- target selection heuristic.
print("max influence:", influences:max())  -- 0.9

-- ---- Stub: Array:matmul --------------------------------------------------
--@api-stub: Array:matmul
-- Multiply the position vector by the affine transform matrix to
-- project a world-space sprite onto screen-space coordinates.
local pos_vec = lurek.compute.fromTable({ 100, 200, 1 }, { 3, 1 }, "f32")
local id3 = lurek.compute.fromTable({ 1,0,0, 0,1,0, 0,0,1 }, { 3,3 }, "f32")
local projected = id3:matmul(pos_vec)
print("projected y:", projected:get(2, 1))  -- 200

-- ---- Stub: Array:dot -----------------------------------------------------
--@api-stub: Array:dot
-- Compute the dot product of the AI direction vector and the target
-- bearing to determine whether the enemy is facing the player.
local facing = lurek.compute.fromTable({ 1, 0 }, { 2 }, "f32")
local to_player = lurek.compute.fromTable({ 0.6, 0.8 }, { 2 }, "f32")
print("alignment:", facing:dot(to_player))  -- 0.6

-- ---- Stub: Array:bitwiseAnd ----------------------------------------------
--@api-stub: Array:bitwiseAnd
-- AND two Int32 tile flag arrays to find cells that have both the
-- "walkable" and "visible" flags set simultaneously.
local flags_a = lurek.compute.fromTable({ 3, 5, 7, 2 }, { 4 }, "i32")
local flags_b = lurek.compute.fromTable({ 1, 4, 6, 2 }, { 4 }, "i32")
local and_r = flags_a:bitwiseAnd(flags_b)
print("AND result:", and_r:get(1))  -- 1

-- ---- Stub: Array:bitwiseOr -----------------------------------------------
--@api-stub: Array:bitwiseOr
-- OR two flag arrays to merge walkable tiles from two different
-- layers into a combined traversal mask.
local or_r = flags_a:bitwiseOr(flags_b)
print("OR result:", or_r:get(2))  -- 5

-- ---- Stub: Array:bitwiseXor ----------------------------------------------
--@api-stub: Array:bitwiseXor
-- XOR the current and previous frame's visible-tile bitfields to
-- find which cells changed visibility this frame.
local prev = lurek.compute.fromTable({ 0,1,1,0 }, { 4 }, "i32")
local curr = lurek.compute.fromTable({ 1,1,0,0 }, { 4 }, "i32")
local changed = prev:bitwiseXor(curr)
print("changed tiles:", changed:countNonZero())  -- 2

-- ---- Stub: Array:bitwiseNot ----------------------------------------------
--@api-stub: Array:bitwiseNot
-- NOT the visibility mask to get the fog-of-war mask representing
-- all tiles that should be hidden from the player.
local vis = lurek.compute.fromTable({ 1, 0, 1, 1 }, { 4 }, "i32")
local fog = vis:bitwiseNot()
print("fog mask sample:", fog:get(2))  -- -1 (bitwise NOT of 0)

-- ---- Stub: Array:bitwiseLShift -------------------------------------------
--@api-stub: Array:bitwiseLShift
-- Left-shift tile IDs by 4 bits to pack them into the upper nibble
-- of a combined tile+flags packed integer.
local tile_ids = lurek.compute.fromTable({ 1, 2, 3, 4 }, { 4 }, "i32")
local shifted = tile_ids:bitwiseLShift(4)
print("tile id 1 shifted:", shifted:get(1))  -- 16

-- ---- Stub: Array:bitwiseRShift -------------------------------------------
--@api-stub: Array:bitwiseRShift
-- Extract tile IDs from the upper nibble of a packed integer by
-- right-shifting 4 bits to isolate the tile type.
local packed_tiles = lurek.compute.fromTable({ 16, 32, 48, 64 }, { 4 }, "i32")
local tile_ids_r = packed_tiles:bitwiseRShift(4)
print("tile id:", tile_ids_r:get(1))  -- 1

-- ---- Stub: Array:add -----------------------------------------------------
--@api-stub: Array:add
-- Add a threat delta array to the influence map to accumulate threat
-- contributions from multiple AI units each frame.
local base_inf = lurek.compute.fromTable({ 1,2,3,4 }, { 4 }, "f32")
local delta    = lurek.compute.fromTable({ 0.5, 0.5, 0.5, 0.5 }, { 4 }, "f32")
local updated = base_inf:add(delta)
print("updated influence:", updated:get(1))  -- 1.5

-- ---- Stub: Array:sub -----------------------------------------------------
--@api-stub: Array:sub
-- Subtract the previous frame's influence from the current one to
-- compute the influence differential for momentum-based AI.
local diff = updated:sub(base_inf)
print("delta:", diff:get(1))  -- 0.5

-- ---- Stub: Array:mul -----------------------------------------------------
--@api-stub: Array:mul
-- Scale the cost map by a difficulty multiplier so hard mode triples
-- the movement cost on rough terrain tiles.
local costs = lurek.compute.fromTable({ 1, 2, 3 }, { 3 }, "f32")
local scaled = costs:mul(lurek.compute.fromTable({ 3, 3, 3 }, { 3 }, "f32"))
print("scaled costs:", scaled:get(1))  -- 3

-- ---- Stub: Array:div -----------------------------------------------------
--@api-stub: Array:div
-- Normalise the probability distribution by dividing by the sum so
-- all action probabilities sum to 1.0.
local logits = lurek.compute.fromTable({ 2, 4, 6 }, { 3 }, "f32")
local total = logits:sum()
local prob = logits:div(lurek.compute.fromTable({ total, total, total }, { 3 }, "f32"))
print("prob sum:", prob:sum())  -- ~1.0

-- ---- Stub: Array:eq ------------------------------------------------------
--@api-stub: Array:eq
-- Compare the predicted action with the best action to compute the
-- accuracy metric during neural network evaluation.
local pred = lurek.compute.fromTable({ 1, 0, 1, 0 }, { 4 }, "f32")
local best = lurek.compute.fromTable({ 1, 1, 1, 0 }, { 4 }, "f32")
local correct = pred:eq(best)
print("correct predictions:", correct:sum())  -- 3

-- ---- Stub: Array:ne ------------------------------------------------------
--@api-stub: Array:ne
-- Find cells where the current policy differs from the previous policy
-- to identify which tiles changed preference this planning cycle.
local prev_pol = lurek.compute.fromTable({ 1, 2, 3 }, { 3 }, "i32")
local curr_pol = lurek.compute.fromTable({ 1, 3, 3 }, { 3 }, "i32")
local changed_pol = prev_pol:ne(curr_pol)
print("policy changes:", changed_pol:sum())  -- 1

-- ---- Stub: Array:lt ------------------------------------------------------
--@api-stub: Array:lt
-- Find all tiles where the path cost is below the budget threshold so
-- the agent avoids expensive routes without a Lua loop.
local path_costs = lurek.compute.fromTable({ 5, 2, 8, 1 }, { 4 }, "f32")
local budget = lurek.compute.fromTable({ 6, 6, 6, 6 }, { 4 }, "f32")
local within_budget = path_costs:lt(budget)
print("affordable tiles:", within_budget:sum())  -- 3

-- ---- Stub: Array:le ------------------------------------------------------
--@api-stub: Array:le
-- Find all cells with cost <= the current best path length to prune
-- the search frontier without a conditional loop.
local best_cost = lurek.compute.fromTable({ 5, 5, 5, 5 }, { 4 }, "f32")
local within = path_costs:le(best_cost)
print("within best cost:", within:sum())  -- 3

-- ---- Stub: Array:gt ------------------------------------------------------
--@api-stub: Array:gt
-- Identify threat cells that exceed the aggro threshold to target only
-- the most dangerous enemies each AI turn.
local threat = lurek.compute.fromTable({ 0.3, 0.8, 0.5, 0.9 }, { 4 }, "f32")
local thresh = lurek.compute.fromTable({ 0.7, 0.7, 0.7, 0.7 }, { 4 }, "f32")
local dangerous = threat:gt(thresh)
print("dangerous cells:", dangerous:sum())  -- 2

-- ---- Stub: Array:ge ------------------------------------------------------
--@api-stub: Array:ge
-- Find all tiles where the influence is at or above the aggro minimum
-- including the exact boundary value.
local min_aggro = lurek.compute.fromTable({ 0.5, 0.5, 0.5, 0.5 }, { 4 }, "f32")
local aggro_mask = threat:ge(min_aggro)
print("aggro tiles:", aggro_mask:sum())  -- 3

-- ---- Stub: Array:conv2d --------------------------------------------------
--@api-stub: Array:conv2d
-- Convolve the 8x8 fog-of-war grid with a Gaussian kernel to compute
-- a smooth visibility gradient around revealed cells.
local fog_grid = lurek.compute.zeros({ 8, 8 }, "f32")
fog_grid:set(4, 4, 1.0)  -- player position
local small_kern = lurek.compute.gaussianKernel(3, 1.0)
local blurred = fog_grid:conv2d(small_kern)
print("center after blur:", blurred:get(4, 4))

-- ---- Stub: Array:correlate2d ---------------------------------------------
--@api-stub: Array:correlate2d
-- Cross-correlate the threat map with a patrol-range kernel to find
-- cells that are heavily covered by patrol routes.
local threat_map = lurek.compute.fromTable(
    { 0,0,1,0, 0,1,1,0, 0,0,1,0, 0,0,0,0 }, { 4, 4 }, "f32")
local r_kern = lurek.compute.ones({ 3, 3 }, "f32")
local covered = threat_map:correlate2d(r_kern)
print("coverage at (2,3):", covered:get(2, 3))

-- ---- Stub: Array:softmax -------------------------------------------------
--@api-stub: Array:softmax
-- Convert raw Q-values to action probabilities using softmax so the
-- policy distribution sums to 1.0 for random sampling.
local q_vals = lurek.compute.fromTable({ 1.0, 2.0, 0.5 }, { 3 }, "f32")
local policy = q_vals:softmax()
print(string.format("policy sum: %.4f", policy:sum()))  -- ~1.0

-- ---- Stub: Array:logSoftmax ----------------------------------------------
--@api-stub: Array:logSoftmax
-- Compute log-softmax for a cross-entropy loss calculation during
-- neural network training without numeric instability.
local log_pol = q_vals:logSoftmax()
print("log-policy[1]:", log_pol:get(1))

-- ---- Stub: Array:sigmoid -------------------------------------------------
--@api-stub: Array:sigmoid
-- Apply sigmoid to a one-vs-rest binary classifier output to get
-- independent per-action probabilities for a multi-label policy.
local raw_bin = lurek.compute.fromTable({ -2, 0, 2 }, { 3 }, "f32")
local sig_out = raw_bin:sigmoid()
print("sigmoid(0):", sig_out:get(2))  -- ~0.5

-- ---- Stub: Array:relu ----------------------------------------------------
--@api-stub: Array:relu
-- Apply ReLU to the hidden layer activations so negative pre-activations
-- are clamped to zero during the forward pass.
local pre_act = lurek.compute.fromTable({ -1, 0.5, 2, -0.3 }, { 4 }, "f32")
local activated = pre_act:relu()
print("relu(-1):", activated:get(1))  -- 0
print("relu(0.5):", activated:get(2))  -- 0.5

-- ---- Stub: Array:leakyRelu -----------------------------------------------
--@api-stub: Array:leakyRelu
-- Use leaky ReLU to prevent dead neurons by allowing a small negative
-- gradient for inputs below zero.
local leaky = pre_act:leakyRelu(0.01)
print("leakyRelu(-1):", leaky:get(1))  -- -0.01

-- ---- Stub: Array:normalize -----------------------------------------------
--@api-stub: Array:normalize
-- L2-normalise the influence gradient to get a unit direction vector
-- for enemy steering toward the player.
local gradient = lurek.compute.fromTable({ 3, 4 }, { 2 }, "f32")
local unit = gradient:normalize()
print(string.format("unit length: %.4f", unit:dot(unit)))  -- ~1.0

-- ---- Stub: Array:standardize ---------------------------------------------
--@api-stub: Array:standardize
-- Z-score standardise the cost features before feeding them into the
-- neural network so no single feature dominates the input.
local feats = lurek.compute.fromTable({ 1, 3, 5, 7, 9 }, { 5 }, "f32")
local std_feats = feats:standardize()
print("standardized mean:", math.abs(std_feats:mean()) < 0.001)  -- true

-- ---- Stub: Array:cast ----------------------------------------------------
--@api-stub: Array:cast
-- Cast the f32 influence map to i32 after thresholding to produce
-- an integer flag layer compatible with the bitwise mask operations.
local f_mask = lurek.compute.fromTable({ 0.0, 1.0, 1.0, 0.0 }, { 4 }, "f32")
local i_mask = f_mask:cast("i32")
print("cast dtype:", i_mask:getDataType())  -- "i32"

-- ---- Stub: Array:type ----------------------------------------------------
--@api-stub: Array:type
-- Verify the variable holds an Array userdata in a generic dispatch
-- function that handles both Array and Tensor types.
print(arr:type())  -- "Array"

-- ---- Stub: Array:typeOf --------------------------------------------------
--@api-stub: Array:typeOf
-- Confirm type before calling Array-specific methods to avoid calling
-- matmul on a non-matrix type.
print(arr:typeOf("Array"))  -- true

-- =============================================================================
-- Advanced Compute Functions
-- =============================================================================

-- ---- Stub: lurek.compute.convolve1d --------------------------------------
--@api-stub: lurek.compute.convolve1d
-- Apply a 1D smoothing kernel to a signal array.
local signal = lurek.compute.array({1, 3, 5, 3, 1, 3, 5, 3, 1})
local kernel = lurek.compute.array({0.25, 0.5, 0.25})
local smoothed = signal:convolve1d(kernel)
print("convolve1d result: " .. tostring(smoothed))

-- ---- Stub: lurek.compute.convolve2D --------------------------------------
--@api-stub: lurek.compute.convolve2D
-- 2D convolution with a 3x3 blur kernel on an image patch.
local img_patch = lurek.compute.array({
    {1, 2, 3, 4},
    {5, 6, 7, 8},
    {9, 10, 11, 12},
    {13, 14, 15, 16}
})
local blur_k = lurek.compute.array({{1,1,1},{1,1,1},{1,1,1}})
local blurred = img_patch:convolve2D(blur_k)
print("convolve2D: " .. tostring(blurred))

-- ---- Stub: lurek.compute.correlate1d ------------------------------------
--@api-stub: lurek.compute.correlate1d
-- Cross-correlate a template pattern against a signal to find matches.
local corr = signal:correlate1d(kernel)
print("correlate1d: " .. tostring(corr))

-- ---- Stub: lurek.compute.covariance --------------------------------------
--@api-stub: lurek.compute.covariance
-- Compute covariance between player score and time played.
local scores = lurek.compute.array({10, 20, 30, 40, 50})
local times = lurek.compute.array({1, 2, 3, 4, 5})
local cov = scores:covariance(times)
print("covariance: " .. tostring(cov))

-- ---- Stub: lurek.compute.cross2d -----------------------------------------
--@api-stub: lurek.compute.cross2d
-- 2D cross-correlation for template matching in a tile map.
local cross = img_patch:cross2d(blur_k)
print("cross2d: " .. tostring(cross))

-- ---- Stub: lurek.compute.cumsum ------------------------------------------
--@api-stub: lurek.compute.cumsum
-- Cumulative sum for a running total score display.
local vals = lurek.compute.array({10, 20, 30, 40})
local cs = vals:cumsum()
print("cumsum: " .. tostring(cs))

-- ---- Stub: lurek.compute.diff --------------------------------------------
--@api-stub: lurek.compute.diff
-- First difference to detect velocity changes from position samples.
local positions = lurek.compute.array({0, 5, 15, 30, 50})
local velocities = positions:diff()
print("diff (velocities): " .. tostring(velocities))

-- ---- Stub: lurek.compute.dilate ------------------------------------------
--@api-stub: lurek.compute.dilate
-- Morphological dilation to expand bright regions in a collision mask.
local mask = lurek.compute.array({{0,0,0},{0,1,0},{0,0,0}})
local dilated = mask:dilate(1)
print("dilate: " .. tostring(dilated))

-- ---- Stub: lurek.compute.erode -------------------------------------------
--@api-stub: lurek.compute.erode
-- Morphological erosion to shrink a collision mask border.
local eroded = dilated:erode(1)
print("erode: " .. tostring(eroded))

-- ---- Stub: lurek.compute.linsolve ----------------------------------------
--@api-stub: lurek.compute.linsolve
-- Solve a 2x2 linear system: 2x + y = 5, x + 3y = 7.
local A = lurek.compute.array({{2, 1}, {1, 3}})
local b = lurek.compute.array({5, 7})
local x = A:linsolve(b)
print("linsolve: " .. tostring(x))

-- ---- Stub: lurek.compute.luDecompose -------------------------------------
--@api-stub: lurek.compute.luDecompose
-- LU decomposition for efficient repeated solves with same matrix.
local L, U = A:luDecompose()
print("LU decompose: L=" .. tostring(L) .. " U=" .. tostring(U))

-- ---- Stub: lurek.compute.normalizeRange ----------------------------------
--@api-stub: lurek.compute.normalizeRange
-- Normalize heightmap values to [0, 1] for colour mapping.
local heights = lurek.compute.array({10, 50, 30, 80, 20})
local normed = heights:normalizeRange()
print("normalizeRange: " .. tostring(normed))

-- ---- Stub: lurek.compute.normalizeVec ------------------------------------
--@api-stub: lurek.compute.normalizeVec
-- Normalize a direction vector to unit length.
local dir_vec = lurek.compute.array({3, 4})
local unit = dir_vec:normalizeVec()
print("normalizeVec: " .. tostring(unit))

-- ---- Stub: lurek.compute.outer -------------------------------------------
--@api-stub: lurek.compute.outer
-- Outer product of two vectors for a rank-1 matrix.
local a_vec = lurek.compute.array({1, 2, 3})
local b_vec = lurek.compute.array({4, 5})
local op = a_vec:outer(b_vec)
print("outer product: " .. tostring(op))

-- ---- Stub: lurek.compute.pearsonCorr ------------------------------------
--@api-stub: lurek.compute.pearsonCorr
-- Correlation between difficulty and player retention.
local pc = scores:pearsonCorr(times)
print("pearson correlation: " .. tostring(pc))

-- ---- Stub: lurek.compute.percentile -------------------------------------
--@api-stub: lurek.compute.percentile
-- Find the 90th percentile score for a leaderboard cutoff.
local p90 = scores:percentile(90)
print("90th percentile: " .. tostring(p90))

-- ---- Stub: lurek.compute.sobel -------------------------------------------
--@api-stub: lurek.compute.sobel
-- Sobel edge detection on a heightmap for cliff rendering.
local edges = img_patch:sobel()
print("sobel edges: " .. tostring(edges))

-- ---- Stub: lurek.compute.transformPoints ---------------------------------
--@api-stub: lurek.compute.transformPoints
-- Transform a batch of points by a rotation matrix.
local pts = lurek.compute.array({{1, 0}, {0, 1}, {-1, 0}})
local rot = lurek.compute.array({{0, -1}, {1, 0}})
local rotated = pts:transformPoints(rot)
print("transformed points: " .. tostring(rotated))

-- ---- Stub: lurek.compute.zscore ------------------------------------------
--@api-stub: lurek.compute.zscore
-- Z-score normalize player stats for balanced matchmaking.
local stats = lurek.compute.array({100, 200, 150, 300, 250})
local zs = stats:zscore()
print("z-scores: " .. tostring(zs))
