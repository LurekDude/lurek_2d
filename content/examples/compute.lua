-- content/examples/compute.lua
-- lurek.compute API examples.
-- Run: cargo run -- content/examples/compute.lua

--@api-stub: lurek.compute.newArray
-- Creates a zero-filled array with the requested shape and data type
do
  -- newArray(shape, dtype?) creates a multidimensional array initialized to zero.
  -- Use it when you need a pre-allocated buffer with known dimensions.
  -- Common for heat maps, tile grids, or any 2D spatial data in your game.
  local heat = lurek.compute.newArray({64, 64}, "float32")

  -- Set corner cells to act as heat sources for a diffusion simulation
  heat:set(1, 1, 1.0)   -- top-left heat source
  heat:set(64, 64, 1.0) -- bottom-right heat source

  -- getSize() returns total element count (64*64 = 4096)
  lurek.log.info("heat grid: " .. heat:getSize() .. " cells", "compute")
end

--@api-stub: lurek.compute.zeros
-- Creates a zero-filled array with the requested shape and data type
do
  -- zeros() is an alias for newArray(). Both produce zero-filled arrays.
  -- Here we model a 3x3 damage grid for an area-of-effect spell.
  local damage = lurek.compute.zeros({3, 3})

  -- The center cell deals full damage
  damage:set(2, 2, 25.0)

  -- sum() reduces the entire array to a single total
  local total = damage:sum()
  lurek.log.info("total damage: " .. total, "compute")
end

--@api-stub: lurek.compute.ones
-- Creates a one-filled array with the requested shape and data type
do
  -- ones() fills every element with 1.0. Useful as an initial mask
  -- or multiplicative identity before applying per-cell modifiers.
  local mask = lurek.compute.ones({8, 8})

  -- clamp() bounds all values between min and max.
  -- Here we simulate fading a visibility mask to 50% opacity.
  local faded = mask:clamp(0.0, 0.5)

  -- mean() returns the average value across all elements
  lurek.log.info("faded mean: " .. faded:mean(), "compute")
end

--@api-stub: lurek.compute.range
-- Creates a one-dimensional range array
do
  -- range(start, stop, step?) generates a 1D sequence: [start, start+step, ..., <stop).
  -- Handy for animation frame indices, time samples, or lookup tables.
  local frames = lurek.compute.range(0, 10, 1)

  -- pow(exp) raises each element to a power. Here: quadratic easing curve.
  local doubled = frames:pow(2)

  -- get() uses 1-based indexing: element 6 holds value (5)^2 = 25
  lurek.log.info("frame[5]^2 = " .. doubled:get(6), "compute")
end

--@api-stub: lurek.compute.fromTable
-- Creates an array from a flat Lua table and optional shape
do
  -- fromTable(data, shape?, dtype?) converts a Lua table into a compute array.
  -- Shape defaults to {#data} (1D). Pass a shape table to interpret as 2D/3D.
  -- Example: audio waveform samples for an envelope curve.
  local samples = {0.1, 0.2, 0.4, 0.8, 1.0, 0.8, 0.4}
  local wave = lurek.compute.fromTable(samples)

  -- max() finds the peak value in the array
  local peak = wave:max()
  lurek.log.info("wave peak: " .. peak, "compute")
end

--@api-stub: lurek.compute.getParThreshold
-- Returns the global compute parallelism threshold
do
  -- The parallel threshold controls when array operations switch from
  -- single-threaded to multi-threaded execution. Arrays smaller than this
  -- threshold run sequentially to avoid thread-spawn overhead.
  local threshold = lurek.compute.getParThreshold()
  lurek.log.info("compute parallel threshold=" .. threshold, "compute")
end

--@api-stub: lurek.compute.setParThreshold
-- Sets the global compute parallelism threshold and returns the previous value
do
  -- Tune the threshold based on your game's workload.
  -- Lower values = more parallelism (good for large grids).
  -- Higher values = less overhead (good for many small arrays).
  local previous = lurek.compute.getParThreshold()

  -- Set to 1024: arrays with >=1024 elements use parallel execution
  lurek.compute.setParThreshold(1024)
  local updated = lurek.compute.getParThreshold()

  lurek.log.info("threshold " .. previous .. " -> " .. updated, "compute")
end

--@api-stub: lurek.compute.gaussianKernel
-- Creates a square Gaussian kernel array
do
  -- gaussianKernel(size, sigma) creates a normalized convolution kernel.
  -- Use for blur effects, smooth terrain generation, or anti-aliased shadows.
  -- size=5 gives a 5x5 kernel; sigma=1.2 controls the blur spread.
  local kernel = lurek.compute.gaussianKernel(5, 1.2)

  -- A properly normalized Gaussian kernel sums to approximately 1.0
  local weight_sum = kernel:sum()
  lurek.log.info("gaussian sum (should be approx 1.0): " .. weight_sum, "compute")
end

--@api-stub: lurek.compute.rotate2dMatrix
-- Creates a 2D rotation matrix
do
  -- rotate2dMatrix(angle_rad) returns a 2x2 rotation matrix.
  -- Multiply by point arrays to rotate sprite vertices, projectile directions, etc.
  local angle = math.pi / 4 -- 45 degrees

  local rot = lurek.compute.rotate2dMatrix(angle)

  -- Points stored as rows: each row is (x, y)
  local pts = lurek.compute.fromTable({1, 0, 0, 1}, {2, 2})

  -- transformPoints applies the matrix to each point row
  local rotated = rot:transformPoints(pts)
  lurek.log.info("rotated[1,1] = " .. rotated:get(1, 1), "compute")
end

--@api-stub: lurek.compute.affine2d
-- Creates a 2D affine transform matrix
do
  -- affine2d(tx, ty, angle_rad, sx, sy) builds a full 2D transform.
  -- Combines translation, rotation, and scale in one matrix.
  -- Use for camera transforms, sprite batch positioning, or UI layout math.
  local tx, ty = 100, 50          -- translate 100px right, 50px down
  local angle = 0.0               -- no rotation
  local sx, sy = 2.0, 2.0         -- double scale

  local m = lurek.compute.affine2d(tx, ty, angle, sx, sy)

  -- Transform the origin point to verify translation applies
  local origin = lurek.compute.fromTable({0, 0}, {1, 2})
  local moved = m:transformPoints(origin)
  lurek.log.info("moved x = " .. moved:get(1, 1), "compute")
end

--@api-stub: lurek.compute.fft
-- Computes the FFT of real-valued samples
do
  -- fft(samples) takes a flat table of real values and returns complex frequency bins.
  -- Each bin is a table with .re (real) and .im (imaginary) components.
  -- Use for audio visualization, rhythm detection, or signal analysis.
  local samples = {0.0, 1.0, 0.0, -1.0, 0.0, 1.0, 0.0, -1.0}

  local spectrum = lurek.compute.fft(samples)

  -- Bin 0 (DC component) shows the average signal level
  local bin0 = spectrum[1]
  lurek.log.info("bin 0 re=" .. bin0.re .. " im=" .. bin0.im, "fft")
end

--@api-stub: lurek.compute.ifft
-- Computes the inverse FFT of complex frequency pairs
do
  -- ifft(freqs) reconstructs time-domain samples from frequency bins.
  -- Round-trip: fft -> modify spectrum -> ifft gives filtered audio.
  local samples = {1.0, 0.5, 0.0, -0.5}
  local freqs = lurek.compute.fft(samples)

  -- Reconstruct the original signal from its frequency representation
  local rebuilt = lurek.compute.ifft(freqs)
  lurek.log.info("rebuilt[1] = " .. rebuilt[1], "fft")
end

--@api-stub: lurek.compute.fftMagnitude
-- Computes FFT magnitudes for real-valued samples
do
  -- fftMagnitude(samples) returns |bin| magnitudes directly as a flat table.
  -- Faster than computing fft() then manually calculating sqrt(re^2 + im^2).
  -- Use for spectrum visualizers or beat detection thresholds.
  local samples = {0.0, 1.0, 0.0, -1.0, 0.0, 1.0, 0.0, -1.0}

  local mags = lurek.compute.fftMagnitude(samples)
  lurek.log.info("mag[2] = " .. mags[2], "fft")
end

-- Array methods

--@api-stub: Array:getShape
-- Returns the shape of this array
do
  -- getShape() returns a table of dimension sizes.
  -- For a 4x6 grid, returns {4, 6}. Use to validate array dimensions
  -- before operations that require specific shapes.
  local grid = lurek.compute.zeros({4, 6})
  local shape = grid:getShape()
  lurek.log.info("grid is " .. shape[1] .. "x" .. shape[2], "compute")
end

--@api-stub: Array:getDimensions
-- Returns the number of dimensions of this array
do
  -- getDimensions() returns 1 for vectors, 2 for matrices, etc.
  -- Useful for branching logic that handles both 1D and 2D data.
  local v = lurek.compute.range(0, 5)
  if v:getDimensions() == 1 then
    lurek.log.info("vector, len=" .. v:getSize(), "compute")
  end
end

--@api-stub: Array:getSize
-- Returns the total number of elements in this array
do
  -- getSize() returns the product of all dimensions.
  -- A {16,16} array has 256 elements total.
  local img = lurek.compute.zeros({16, 16})
  local n = img:getSize()
  lurek.log.info("img has " .. n .. " pixels", "compute")
end

--@api-stub: Array:getDataType
-- Returns the data type of this array
do
  -- getDataType() returns "float32", "int32", etc.
  -- Use int32 for tile IDs, bitmasks, or entity indices.
  -- Use float32 for positions, velocities, or weights.
  local mask = lurek.compute.zeros({8}, "int32")
  local dt = mask:getDataType()
  if dt == "int32" then lurek.log.info("ready for bitwise ops", "compute") end
end

--@api-stub: Array:isOnGPU
-- Returns true if this array is stored on the GPU
do
  -- isOnGPU() lets you check whether data lives on CPU or GPU memory.
  -- Currently all arrays are CPU-backed; this future-proofs your code
  -- for when GPU compute kernels are added.
  local arr = lurek.compute.zeros({4})
  if not arr:isOnGPU() then
    lurek.log.debug("running compute on CPU", "compute")
  end
end

--@api-stub: Array:get
-- Returns the element value at the given indices
do
  pcall(function()
    -- get(i, j, ...) reads a single element using 1-based indices.
    -- For a 2D array, get(row, col). For 1D, get(index).
    local m = lurek.compute.fromTable({1, 2, 3, 4}, {2, 2})

    -- Row 1, Column 2 = value 2 (row-major storage)
    local top_right = m:get(1, 2)
    lurek.log.info("m[1,2] = " .. top_right, "compute")
  end)
end

--@api-stub: Array:set
-- Sets the element value at the given indices
do
  -- set(i, j, ..., value) writes a single element.
  -- Last argument is always the value; preceding args are indices.
  local board = lurek.compute.zeros({3, 3})

  -- Place a piece in the centre of a tic-tac-toe board
  board:set(2, 2, 1.0)
  lurek.log.info("centre = " .. board:get(2, 2), "compute")
end

--@api-stub: Array:toTable
-- Converts this array to a flat Lua table
do
  -- toTable() extracts all values as a flat Lua table in storage order.
  -- Use when you need to pass array data to Lua APIs that expect tables,
  -- or for serialization/save game data.
  local arr = lurek.compute.range(0, 4)
  local flat = arr:toTable()
  lurek.log.info("flat[3] = " .. flat[3] .. ", count=" .. #flat, "compute")
end

--@api-stub: Array:reshape
-- Returns a reshaped copy of this array
do
  -- reshape(shape) reinterprets the flat data with new dimensions.
  -- Total element count must stay the same (6 elements -> {2,3} is valid).
  -- Use to convert a 1D range into a 2D grid for spatial operations.
  local row = lurek.compute.range(0, 6)
  local grid = row:reshape({2, 3})

  -- After reshape: row 2, col 3 = last element = 5.0
  lurek.log.info("grid[2,3] = " .. grid:get(2, 3), "compute")
end

--@api-stub: Array:clone
-- Returns a deep copy of this array
do
  -- clone() creates an independent copy. Mutations to the clone
  -- do not affect the original. Essential when you need a snapshot
  -- of state (e.g., previous frame's tile map for diffing).
  local original = lurek.compute.ones({4})
  local copy = original:clone()

  -- Modify the copy; original stays unchanged
  copy:fill(0.0)
  lurek.log.info("orig sum=" .. original:sum() .. " copy sum=" .. copy:sum(), "compute")
end

--@api-stub: Array:transpose
-- Returns a transposed copy of this 2D array
do
  -- transpose() swaps rows and columns of a 2D array.
  -- A {2,3} array becomes {3,2}. Useful for switching between
  -- row-major and column-major data layouts.
  local m = lurek.compute.fromTable({1, 2, 3, 4, 5, 6}, {2, 3})
  local t = m:transpose()
  lurek.log.info("t shape: " .. t:getShape()[1] .. "x" .. t:getShape()[2], "compute")
end

--@api-stub: Array:fill
-- Fills all elements of this array with a single value (in place)
do
  -- fill(val) overwrites every element. Use to reset a scratch buffer
  -- between frames without allocating a new array.
  local scratch = lurek.compute.zeros({32, 32})

  -- Mark all cells as "unexplored" (-1)
  scratch:fill(-1.0)
  lurek.log.info("scratch sum after fill: " .. scratch:sum(), "compute")
end

--@api-stub: Array:pow
-- Returns a new array with each element raised to an exponent
do
  -- pow(exp) applies element-wise exponentiation.
  -- Use for quadratic/cubic easing, distance falloff curves, or gamma correction.
  local v = lurek.compute.fromTable({1, 2, 3, 4})
  local sq = v:pow(2) -- square each element

  lurek.log.info("4^2 = " .. sq:get(4), "compute")
end

--@api-stub: Array:sqrt
-- Returns a new array with element-wise square roots
do
  -- sqrt() computes the square root of each element.
  -- Common for distance calculations: dist = sqrt(dx^2 + dy^2)
  local sq = lurek.compute.fromTable({1, 4, 9, 16})
  local roots = sq:sqrt()
  lurek.log.info("sqrt(16) = " .. roots:get(4), "compute")
end

--@api-stub: Array:abs
-- Returns a new array with element-wise absolute values
do
  -- abs() removes sign from each element.
  -- Useful for computing magnitude of velocity changes or displacement vectors.
  local deltas = lurek.compute.fromTable({-3, 1, -2, 4})
  local mag = deltas:abs()
  lurek.log.info("abs sum = " .. mag:sum(), "compute")
end

--@api-stub: Array:neg
-- Returns a new array with each element negated
do
  -- neg() flips the sign of every element.
  -- Use for inverting forces, creating counter-impulses, or flipping gradients.
  local impulse = lurek.compute.fromTable({2, -1, 4})
  local counter = impulse:neg()
  lurek.log.info("counter[1] = " .. counter:get(1), "compute")
end

--@api-stub: Array:clamp
-- Returns a new array with values clamped between min and max
do
  -- clamp(min, max) bounds every element.
  -- Essential for health bars, color channels, or any bounded game stat.
  local hp = lurek.compute.fromTable({120, -5, 75, 200})

  -- Clamp health points to valid range [0, 100]
  local clamped = hp:clamp(0, 100)
  lurek.log.info("clamped max = " .. clamped:max(), "compute")
end

--@api-stub: Array:threshold
-- Returns a mask array where values above the threshold become 1, else 0
do
  -- threshold(val) creates a binary mask: 1 where element > val, else 0.
  -- Use for visibility culling, fog-of-war edges, or damage zones.
  local field = lurek.compute.range(0, 8)

  -- Only cells with value > 4 are "visible"
  local visible = field:threshold(4.0)
  lurek.log.info("cells visible: " .. visible:sum(), "compute")
end

--@api-stub: Array:countNonZero
-- Returns the count of non-zero elements
do
  -- countNonZero() counts elements that are not exactly 0.
  -- Efficient way to count active tiles, occupied slots, or lit cells.
  local occupied = lurek.compute.fromTable({0, 1, 0, 1, 1, 0})
  local live = occupied:countNonZero()
  lurek.log.info("occupied tiles: " .. live, "compute")
end

--@api-stub: Array:argmin
-- Returns the 1-based flat index of the minimum element
do
  -- argmin() finds WHERE the minimum is, not what it is.
  -- Use to find the nearest enemy, cheapest path node, or lowest score.
  local distances = lurek.compute.fromTable({12, 4, 9, 7})
  local nearest = distances:argmin()
  lurek.log.info("nearest enemy index: " .. nearest, "ai")
end

--@api-stub: Array:argmax
-- Returns the 1-based flat index of the maximum element
do
  -- argmax() finds WHERE the maximum is.
  -- Use in AI decision-making: pick the action with highest utility score.
  local scores = lurek.compute.fromTable({0.2, 0.5, 0.9, 0.4})
  local choice = scores:argmax()
  lurek.log.info("AI picks action " .. choice, "ai")
end

--@api-stub: Array:any
-- Returns true if any element is non-zero
do
  -- any() is a fast existence check.
  -- Use for "did anything collide?", "is any enemy alive?", etc.
  local hits = lurek.compute.fromTable({0, 0, 1, 0})
  if hits:any() then
    lurek.log.warn("at least one hit registered", "combat")
  end
end

--@api-stub: Array:all
-- Returns true if all elements are non-zero
do
  -- all() checks that every element passes.
  -- Use for puzzle completion: "are all switches activated?"
  local switches = lurek.compute.fromTable({1, 1, 1, 1})
  if switches:all() then
    lurek.log.info("door unlocked", "puzzle")
  end
end

--@api-stub: Array:sum
-- Returns the total sum of all elements (or sum along an axis)
do
  -- sum() with no argument reduces the entire array to a scalar.
  -- sum(axis) reduces along one dimension, returning a smaller array.
  local hits = lurek.compute.fromTable({3, 1, 4, 1, 5, 9})
  local total = hits:sum()
  lurek.log.info("total damage: " .. total, "compute")
end

--@api-stub: Array:mean
-- Returns the arithmetic mean of all elements (or mean along an axis)
do
  -- mean() computes the average. Use for frame time monitoring,
  -- smoothed input values, or AI utility averaging.
  local frame_ms = lurek.compute.fromTable({16.1, 16.7, 17.2, 16.9, 16.4})
  local avg = frame_ms:mean()
  lurek.log.info("avg frame ms: " .. avg, "perf")
end

--@api-stub: Array:min
-- Returns the minimum element value (or minimum along an axis)
do
  -- min() finds the smallest value across the array.
  -- Useful for finding cheapest path cost, lowest health, etc.
  local costs = lurek.compute.fromTable({7, 3, 9, 4})
  local cheapest = costs:min()
  lurek.log.info("cheapest cost: " .. cheapest, "compute")
end

--@api-stub: Array:max
-- Returns the maximum element value (or maximum along an axis)
do
  -- max() finds the largest value.
  -- Use for worst-case latency, highest score, peak damage dealt.
  local latencies = lurek.compute.fromTable({12, 30, 18, 25})
  local worst = latencies:max()
  lurek.log.info("worst latency: " .. worst .. "ms", "net")
end

--@api-stub: Array:matmul
-- Performs matrix multiplication with another 2D array
do
  -- matmul(other) computes the standard matrix product (A * B).
  -- Both arrays must be 2D with compatible inner dimensions.
  -- Use for chaining transforms, neural network layers, or physics Jacobians.
  local a = lurek.compute.fromTable({1, 2, 3, 4}, {2, 2})
  local b = lurek.compute.fromTable({5, 6, 7, 8}, {2, 2})
  local c = a:matmul(b)

  -- c[1,1] = 1*5 + 2*7 = 19
  lurek.log.info("c[1,1] = " .. c:get(1, 1), "compute")
end

--@api-stub: Array:dot
-- Computes the dot product with another 1D array
do
  -- dot(other) computes the scalar dot product of two vectors.
  -- Use for angle checks: dot > 0 means vectors point roughly the same way.
  local heading = lurek.compute.fromTable({1, 0})  -- facing right
  local target = lurek.compute.fromTable({0.7, 0.7})  -- 45 degrees
  local alignment = heading:dot(target)

  -- alignment = 0.7, meaning target is mostly in front
  lurek.log.info("alignment: " .. alignment, "ai")
end

--@api-stub: Array:bitwiseAnd
-- Returns element-wise bitwise AND with another int32 array
do
  -- bitwiseAnd(other) combines bit flags between two mask arrays.
  -- Both arrays must be int32. Use to intersect tile property layers.
  local walk = lurek.compute.fromTable({1, 1, 0, 1}, nil, "int32") -- walkable mask
  local lit  = lurek.compute.fromTable({1, 0, 1, 1}, nil, "int32") -- illuminated mask

  -- AND finds tiles that are BOTH walkable AND illuminated
  local both = walk:bitwiseAnd(lit)
  lurek.log.info("walkable AND lit count: " .. both:countNonZero(), "tiles")
end

--@api-stub: Array:bitwiseOr
-- Returns element-wise bitwise OR with another int32 array
do
  -- bitwiseOr(other) merges bit flags. Use to combine visibility layers.
  local fov  = lurek.compute.fromTable({1, 0, 0, 1}, nil, "int32") -- current FOV
  local mem  = lurek.compute.fromTable({0, 1, 0, 0}, nil, "int32") -- remembered tiles

  -- OR creates the "ever seen" map for minimap rendering
  local seen = fov:bitwiseOr(mem)
  lurek.log.info("seen-tile count: " .. seen:countNonZero(), "fov")
end

--@api-stub: Array:bitwiseXor
-- Returns element-wise bitwise XOR with another int32 array
do
  -- bitwiseXor(other) finds bits that differ between frames.
  -- Use for dirty-region detection: which tiles changed since last frame?
  local prev = lurek.compute.fromTable({1, 0, 1, 1}, nil, "int32")
  local curr = lurek.compute.fromTable({1, 1, 1, 0}, nil, "int32")

  -- XOR marks cells that flipped state
  local changed = prev:bitwiseXor(curr)
  lurek.log.info("cells changed: " .. changed:countNonZero(), "tiles")
end

--@api-stub: Array:bitwiseNot
-- Returns element-wise bitwise NOT of this int32 array
do
  -- bitwiseNot() inverts all bits. For simple 0/1 masks, this flips the mask.
  -- Use to get the complement: "free" tiles from an "occupied" mask.
  local occupied = lurek.compute.fromTable({1, 0, 0, 1}, nil, "int32")
  local free = occupied:bitwiseNot()
  lurek.log.info("free mask[2] = " .. free:get(2), "tiles")
end

--@api-stub: Array:bitwiseLShift
-- Returns element-wise left bit shift by a given amount
do
  -- bitwiseLShift(amount) shifts each int32 element left.
  -- Use for packing tile data: combine type and variant into one int.
  local ids = lurek.compute.fromTable({1, 2, 3, 4}, nil, "int32")

  -- Shift left by 4 bits to make room for a variant nibble
  local packed = ids:bitwiseLShift(4)
  lurek.log.info("packed[2] = " .. packed:get(2), "compute")
end

--@api-stub: Array:bitwiseRShift
-- Returns element-wise right bit shift by a given amount
do
  -- bitwiseRShift(amount) shifts each int32 element right.
  -- Use to extract packed fields from combined tile data.
  local packed = lurek.compute.fromTable({16, 32, 48, 64}, nil, "int32")

  -- Shift right by 4 to recover the original tile type IDs
  local high = packed:bitwiseRShift(4)
  lurek.log.info("high[3] = " .. high:get(3), "compute")
end

--@api-stub: Array:convolve2D
-- Applies a 2D convolution kernel to this array
do
  -- convolve2D(kernel) slides a kernel over the 2D array.
  -- Use for blur, edge detect, sharpen, or custom spatial filters.
  -- The kernel must be a small 2D array (odd dimensions recommended).
  local img = lurek.compute.ones({8, 8})
  local k = lurek.compute.gaussianKernel(3, 0.8)

  -- Blurring a uniform image should preserve the mean
  local blurred = img:convolve2D(k)
  lurek.log.info("blurred mean = " .. blurred:mean(), "compute")
end

--@api-stub: Array:dilate
-- Applies morphological dilation with a given radius
do
  -- dilate(radius) expands non-zero regions outward.
  -- Use to grow collision boundaries, expand influence zones,
  -- or create "buffer zones" around obstacles on a nav mesh.
  local mask = lurek.compute.zeros({5, 5})
  mask:set(3, 3, 1.0) -- single seed point

  -- Dilate by 1 cell: the seed grows into a 3x3 cross pattern
  local grown = mask:dilate(1)
  lurek.log.info("grown nonzero: " .. grown:countNonZero(), "compute")
end

--@api-stub: Array:erode
-- Applies morphological erosion with a given radius
do
  -- erode(radius) shrinks non-zero regions inward.
  -- Use to find safe interior areas, remove thin noise features,
  -- or compute safe spawn zones away from walls.
  local mask = lurek.compute.ones({4, 4})

  -- Erode by 1: only the inner 2x2 survives
  local interior = mask:erode(1)
  lurek.log.info("interior cells: " .. interior:countNonZero(), "compute")
end

--@api-stub: Array:cumsum
-- Returns the cumulative sum (prefix sum) of this array
do
  -- cumsum() computes running totals. Element i = sum of elements 1..i.
  -- Use for weighted random selection, score tracking, or integral images.
  local scores = lurek.compute.fromTable({1, 2, 3, 4})

  -- running = {1, 3, 6, 10}
  local running = scores:cumsum()
  lurek.log.info("score after 3rd round = " .. running:get(3), "score")
end

--@api-stub: Array:diff
-- Returns finite differences (velocity from position, acceleration from velocity)
do
  -- diff(order?) computes element-to-element differences.
  -- Order 1 (default): velocity from position. Order 2: acceleration from position.
  -- Result is one element shorter per order applied.
  local pos = lurek.compute.fromTable({0, 1, 3, 6, 10})

  -- First difference gives velocity: {1, 2, 3, 4}
  local vel = pos:diff(1)
  lurek.log.info("vel[2] = " .. vel:get(2), "compute")
end

--@api-stub: Array:percentile
-- Returns a percentile value from the array data
do
  -- percentile(p) finds the value below which p% of data falls.
  -- Use for performance monitoring: p95 frame time shows worst-case spikes.
  local times = lurek.compute.fromTable({16, 17, 18, 19, 33})

  -- 95th percentile: almost all frames are under this value
  local p95 = times:percentile(95)
  lurek.log.info("frame p95 = " .. p95 .. "ms", "perf")
end

--@api-stub: Array:covariance
-- Computes covariance with another array
do
  -- covariance(other) measures how two variables change together.
  -- Positive = they increase together. Negative = one rises as other falls.
  -- Use for correlating game stats (e.g., player level vs. damage output).
  local x = lurek.compute.fromTable({1, 2, 3, 4})
  local y = lurek.compute.fromTable({2, 4, 6, 8}) -- perfectly correlated

  local cov = x:covariance(y)
  lurek.log.info("cov(x,y) = " .. cov, "compute")
end

--@api-stub: Array:pearsonCorr
-- Computes Pearson correlation coefficient with another array
do
  -- pearsonCorr(other) returns a value in [-1, 1].
  -- +1 = perfect positive correlation, -1 = perfect negative, 0 = no relation.
  -- Use to detect relationships (fps vs entity count, score vs playtime).
  local fps = lurek.compute.fromTable({60, 58, 55, 50, 45})
  local entities = lurek.compute.fromTable({100, 150, 200, 280, 360})

  -- Expected: strong negative correlation (more entities = lower fps)
  local r = fps:pearsonCorr(entities)
  lurek.log.info("fps vs entity correlation: " .. r, "perf")
end

--@api-stub: Array:normalizeRange
-- Returns values rescaled to a target [lo, hi] range
do
  -- normalizeRange(lo, hi) maps the array's min to lo and max to hi.
  -- Use for mapping raw sensor data to screen coordinates, or
  -- normalizing AI utility scores to [0, 1] for comparison.
  local raw = lurek.compute.fromTable({-2, 0, 2, 4})

  -- Map to unit range: -2 -> 0.0, 4 -> 1.0
  local unit = raw:normalizeRange(0, 1)
  lurek.log.info("unit min=" .. unit:min() .. " max=" .. unit:max(), "compute")
end

--@api-stub: Array:zscore
-- Returns z-score normalized values (mean=0, std=1)
do
  -- zscore() standardizes data: (value - mean) / std_deviation.
  -- Use for comparing features on different scales in AI systems,
  -- or detecting outliers (|z| > 2 is unusual).
  local features = lurek.compute.fromTable({10, 12, 14, 18, 20})
  local z = features:zscore()

  -- First element is below mean, so z[1] should be negative
  lurek.log.info("z[1] = " .. z:get(1), "compute")
end

--@api-stub: Array:convolve1d
-- Applies a 1D convolution kernel to this array
do
  -- convolve1d(kernel) slides a 1D kernel along the array.
  -- Use for smoothing time-series data, audio filtering, or 1D signal processing.
  local signal = lurek.compute.fromTable({0, 1, 0, 1, 0, 1, 0})

  -- Simple averaging kernel: [0.25, 0.5, 0.25]
  local kernel = lurek.compute.fromTable({0.25, 0.5, 0.25})
  local smoothed = signal:convolve1d(kernel)
  lurek.log.info("smoothed length: " .. smoothed:getSize(), "compute")
end

--@api-stub: Array:correlate1d
-- Computes 1D cross-correlation with a template array
do
  -- correlate1d(template) measures how well the template matches at each position.
  -- Use for pattern matching: find where a known shape appears in a signal.
  local stream   = lurek.compute.fromTable({0, 1, 2, 3, 2, 1, 0})
  local template = lurek.compute.fromTable({1, 2, 3}) -- rising pattern

  -- argmax of the result tells you where the best match is
  local match = stream:correlate1d(template)
  lurek.log.info("best match index: " .. match:argmax(), "compute")
end

--@api-stub: Array:normalizeVec
-- Returns this vector normalized to unit length
do
  -- normalizeVec() divides by the vector's magnitude so length becomes 1.
  -- Use for direction vectors: normalize velocity to get heading.
  local v = lurek.compute.fromTable({3, 4}) -- length = 5

  local unit = v:normalizeVec()
  -- unit[1]^2 + unit[2]^2 should equal 1.0
  lurek.log.info("unit[1]^2 + unit[2]^2 = " .. unit:pow(2):sum(), "compute")
end

--@api-stub: Array:outer
-- Computes the outer product of two vectors (result is a matrix)
do
  -- outer(other) produces a matrix where result[i,j] = self[i] * other[j].
  -- Use for rank-1 updates, weight matrices, or constructing projection operators.
  local row = lurek.compute.fromTable({1, 2, 3})
  local col = lurek.compute.fromTable({1, 2})

  -- Result is a 3x2 matrix
  local mat = row:outer(col)
  lurek.log.info("outer[2,2] = " .. mat:get(2, 2), "compute")
end

--@api-stub: Array:cross2d
-- Computes the 2D cross product (scalar) with another 2D vector
do
  -- cross2d(other) returns the z-component of the 3D cross product.
  -- Sign indicates turn direction: positive = counter-clockwise (left turn).
  -- Use for steering AI, winding-order checks, or left/right detection.
  local heading = lurek.compute.fromTable({1, 0}) -- facing right
  local target  = lurek.compute.fromTable({0, 1}) -- target is above

  local cross = heading:cross2d(target)
  -- cross > 0 means target is to the left of heading
  lurek.log.info("turn direction: " .. (cross > 0 and "left" or "right"), "ai")
end

--@api-stub: Array:transformPoints
-- Transforms point rows by this matrix (rotation, affine, etc.)
do
  pcall(function()
    -- transformPoints(pts) applies this matrix to each row of the point array.
    -- Points are stored as rows: Nx2 array where each row is (x, y).
    -- The matrix can be 2x2 (rotation) or 3x3 (affine with translation).
    local rot = lurek.compute.rotate2dMatrix(math.pi / 2) -- 90-degree rotation
    local pts = lurek.compute.fromTable({1, 0, 0, 1}, {2, 2})

    local out = rot:transformPoints(pts)
    -- (1,0) rotated 90 degrees CCW = (0,1)
    lurek.log.info("rotated[1,2] = " .. out:get(1, 2), "compute")
  end)
end

--@api-stub: Array:sobel
-- Computes Sobel edge-detection gradients (returns {gx, gy} table)
do
  -- sobel() returns a table with .gx and .gy gradient arrays.
  -- Magnitude = sqrt(gx^2 + gy^2) gives edge strength.
  -- Use for edge detection in heightmaps, outline rendering, or terrain normals.
  local img = lurek.compute.ones({4, 4})
  local g = img:sobel()
  lurek.log.info("gx[2,2] = " .. g.gx:get(2, 2) .. " gy[2,2] = " .. g.gy:get(2, 2), "compute")
end

--@api-stub: Array:linsolve
-- Solves the linear system Ax = b for x
do
  -- linsolve(b) solves the equation self*x = b using LU decomposition.
  -- self must be a square NxN matrix, b must be an N-element vector.
  -- Use for physics constraint solving, inverse kinematics, or interpolation.
  local a = lurek.compute.fromTable({2, 1, 1, 3}, {2, 2})
  local b = lurek.compute.fromTable({5, 10})

  -- Solve: 2x + y = 5, x + 3y = 10 -> x=1, y=3
  local x = a:linsolve(b)
  lurek.log.info("x[1] = " .. x:get(1) .. " x[2] = " .. x:get(2), "compute")
end

--@api-stub: Array:luDecompose
-- Returns LU decomposition data for this square matrix
do
  -- luDecompose() factorizes a square matrix into L and U factors.
  -- Returns a table with: n (size), det_sign (+1 or -1), perm (permutation), lu_data (flat LU values).
  -- Use for determinant computation or repeated solves with different right-hand sides.
  local a = lurek.compute.fromTable({4, 3, 6, 3}, {2, 2})
  local lu = a:luDecompose()
  lurek.log.info("LU n=" .. lu.n .. " det_sign=" .. lu.det_sign, "compute")
end

--@api-stub: Array:type
-- Returns the Lua-visible type name string for this array handle
do
  -- type() returns the string "LArray" for any compute array.
  -- Use for runtime type checking when handling mixed userdata.
  local arr = lurek.compute.zeros({2})
  local kind = arr:type()
  if kind == "LArray" then lurek.log.debug("got an Array", "compute") end
end

--@api-stub: Array:typeOf
-- Returns true if this array handle matches the given type name string
do
  -- typeOf(name) accepts "LArray", "Array", or "Object" — all return true.
  -- Use for duck-typing checks in utility functions that accept multiple types.
  local arr = lurek.compute.zeros({2})
  if arr:typeOf("Array") then
    lurek.log.debug("typeOf check passed", "compute")
  end
end

--@api-stub: Array:map
-- Applies a Lua function to each element, returning a new array
do
  -- map(func) calls func(element) for every value and stores the result.
  -- Flexible but slower than built-in ops. Use for custom per-element logic
  -- that has no built-in equivalent (e.g., lookup tables, conditional transforms).
  local a = lurek.compute.fromTable({1, 4, 9})
  local b = a:map(function(x) return math.sqrt(x) end)
  lurek.log.debug("map sqrt: " .. tostring(b:toTable()[1]), "compute")
end

--@api-stub: Array:eval
-- Evaluates a Lua expression string on each element (x = current value)
do
  -- eval(expr) compiles the expression once and applies it per element.
  -- The variable 'x' holds the current element value.
  -- Faster to write than map() for simple formulas; same performance.
  local a = lurek.compute.fromTable({1, 2, 3})
  local b = a:eval("x * x + 1") -- quadratic transform

  -- Element 2: 2*2+1 = 5
  lurek.log.debug("eval x^2+1: " .. tostring(b:toTable()[2]), "compute")
end

--@api-stub: Array:reduce
-- Reduces all elements to a single value using an accumulator function
do
  -- reduce(func, init) folds left: acc = func(acc, element) for each element.
  -- Use for custom aggregations that sum/min/max can't express.
  local a = lurek.compute.fromTable({1, 2, 3, 4})
  local total = a:reduce(function(acc, x) return acc + x end, 0)

  -- Equivalent to a:sum(), but allows arbitrary fold logic
  lurek.log.debug("reduce sum: " .. tostring(total), "compute")
end

--@api-stub: Array:scan
-- Produces a prefix-scan array using an accumulator function
do
  -- scan(func, init) is like reduce but keeps every intermediate accumulator value.
  -- Result has the same shape as the input.
  -- Use for prefix sums, running maxima, or streaming statistics.
  local a = lurek.compute.fromTable({1, 2, 3, 4})
  local prefix = a:scan(function(acc, x) return acc + x end, 0)

  -- prefix = {1, 3, 6, 10}
  lurek.log.debug("scan prefix[4]: " .. tostring(prefix:toTable()[4]), "compute")
end


--@api-stub: Array:eigenPower
-- Estimates the dominant eigenvalue and eigenvector via power iteration
do
  -- eigenPower(max_iter?, tol?) finds the largest eigenvalue of a square matrix.
  -- Returns a table with .value (eigenvalue) and .vector (eigenvector table).
  -- Use for principal component analysis, stability checks, or vibration modes.
  local A = lurek.compute.fromTable({2, 1, 1, 2}, {2, 2}, "float32")

  -- Power iteration with up to 50 steps; default tolerance used
  local result = A:eigenPower(50)
  lurek.log.info("dominant eigenvalue: " .. result.value, "compute")
end

--@api-stub: Array:floodFill
-- Fills connected cells from a start position with a replacement value
do
  -- floodFill(row, col, val) fills connected cells that share the same value
  -- as the starting cell. Returns a new array with the fill applied.
  -- Use for room detection, island counting, or paint-bucket tools.
  local grid = lurek.compute.zeros({8, 8}, "int32")
  grid:fill(1) -- fill everything with 1

  -- Place a 0-cell "wall" at (3,3) then flood from it
  grid:set(3, 3, 0)
  local filled = grid:floodFill(3, 3, 255)

  -- Only the single 0-cell at (3,3) gets filled since it's isolated
  lurek.log.info("filled[3,3] = " .. tostring(filled:get(3, 3)), "compute")
end

--@api-stub: Array:getRegion
-- Extracts a rectangular sub-region from this 2D array
do
  -- getRegion(row, col, rows, cols) copies a rectangular patch.
  -- All coordinates are 1-based.
  -- Use for chunk-based terrain, viewport extraction, or tile atlas slicing.
  local a = lurek.compute.range(0, 64, 1, "int32"):reshape({8, 8})

  -- Extract a 4x4 patch starting at row 2, col 2
  local patch = a:getRegion(2, 2, 4, 4)
  lurek.log.info("patch shape: " .. patch:getShape()[1] .. "x" .. patch:getShape()[2], "compute")
end

--@api-stub: Array:histogram
-- Computes a histogram of values across the given number of bins
do
  -- histogram(bins, lo?, hi?) groups values into bins and counts occurrences.
  -- Returns a table of bin entries with .lo, .hi, .count fields.
  -- Use for damage distribution analysis, terrain height profiling, or debug stats.
  local a = lurek.compute.fromTable({1, 2, 2, 3, 3, 3, 4, 4, 4, 4}, nil, "int32")

  -- Split into 4 bins across the data range
  local hist = a:histogram(4)
  lurek.log.info("hist bins: " .. #hist .. ", first count: " .. hist[1].count, "compute")
end

--@api-stub: Array:setRegion
-- Writes a source array into this array at a given position (in place)
do
  -- setRegion(row, col, source) pastes a smaller array into this one.
  -- Use for stamping prefabs onto a world grid, compositing tile patches,
  -- or writing computed chunks back into a full map.
  local canvas = lurek.compute.zeros({16, 16}, "float32")
  local stamp = lurek.compute.ones({4, 4}, "float32")

  -- Paste the 4x4 stamp at position (6, 6) on the canvas
  canvas:setRegion(6, 6, stamp)
  lurek.log.info("canvas[7,7] after stamp = " .. canvas:get(7, 7), "compute")
end

--@api-stub: Array:where
-- Selects values from this array or another based on a mask
do
  -- where(mask, other) picks from self where mask is non-zero,
  -- and from other where mask is zero.
  -- Use for conditional operations: apply damage only to enemies in range.
  local a = lurek.compute.fromTable({1, 2, 3, 4, 5, 6}, nil, "int32")

  -- Mask: only elements > 3 pass
  local mask = a:gt(3)

  -- Where mask is true, keep 'a'; where false, use zeros
  local zeros = lurek.compute.zeros({6}, "int32")
  local result = a:where(mask, zeros)
  lurek.log.info("where filtered sum: " .. result:sum(), "compute")
end

--@api-stub: Array:add
-- Returns element-wise addition with an array or scalar
do
  -- add(value) adds either a scalar or another array element-wise.
  -- With an array argument, shapes must be compatible (broadcast supported for 1D->2D).
  local base = lurek.compute.fromTable({1, 2, 3, 4}, {2, 2})
  local boost = lurek.compute.fromTable({10, 20}, {2})

  -- Row broadcast: each row gets +10 and +20 added to its columns
  local out = base:add(boost)
  lurek.log.info("add row-broadcast [2,2] = " .. out:get(2, 2), "compute")
end

--@api-stub: Array:sub
-- Returns element-wise subtraction with an array or scalar
do
  -- sub(value) subtracts a scalar or array.
  -- Use for applying flat damage reduction to a party's HP array.
  local hp = lurek.compute.fromTable({100, 80, 65})
  local after = hp:sub(15) -- 15 damage to all party members

  lurek.log.info("sub result first = " .. after:get(1), "compute")
end

--@api-stub: Array:mul
-- Returns element-wise multiplication with an array or scalar
do
  -- mul(value) multiplies by a scalar or array.
  -- Use for applying damage multipliers, scaling physics forces, etc.
  local dmg = lurek.compute.fromTable({10, 12, 8})
  local crit = dmg:mul(1.5) -- 150% critical hit multiplier

  lurek.log.info("crit total = " .. crit:sum(), "compute")
end

--@api-stub: Array:div
-- Returns element-wise division with an array or scalar
do
  -- div(value) divides by a scalar or array.
  -- Use for unit conversion, normalizing by frame count, etc.
  local ms = lurek.compute.fromTable({16, 20, 25, 33})
  local sec = ms:div(1000) -- convert milliseconds to seconds

  lurek.log.info("sec[1] = " .. sec:get(1), "compute")
end

--@api-stub: Array:eq
-- Returns a mask array where elements equal the given value
do
  -- eq(value) returns 1 where elements match, 0 elsewhere.
  -- Use for finding specific tile types in a map grid.
  local tiles = lurek.compute.fromTable({0, 1, 2, 1, 0}, nil, "int32")

  -- Find all "wall" tiles (type 1)
  local walls = tiles:eq(1)
  lurek.log.info("wall count = " .. walls:countNonZero(), "compute")
end

--@api-stub: Array:neq
-- Returns a mask array where elements do not equal the given value
do
  -- neq(value) is the inverse of eq(): 1 where elements differ from value.
  -- Use for "everything except" queries on tagged data.
  local tags = lurek.compute.fromTable({1, 2, 2, 3}, nil, "int32")
  local non_two = tags:neq(2)
  lurek.log.info("non-2 count = " .. non_two:countNonZero(), "compute")
end

--@api-stub: Array:gt
-- Returns a mask array where elements are greater than the value
do
  -- gt(value) creates a binary mask for "above threshold" queries.
  -- Use for hot zones, danger areas, or quality-tier filtering.
  local heat = lurek.compute.fromTable({0.1, 0.6, 0.8, 0.2})
  local hot = heat:gt(0.5)
  lurek.log.info("hot cells = " .. hot:countNonZero(), "compute")
end

--@api-stub: Array:lt
-- Returns a mask array where elements are less than the value
do
  -- lt(value) creates a binary mask for "below threshold" queries.
  -- Use for low-resource warnings, cooldown checks, etc.
  local stamina = lurek.compute.fromTable({40, 10, 25, 5})
  local low = stamina:lt(20)
  lurek.log.info("low stamina count = " .. low:countNonZero(), "compute")
end

--@api-stub: Array:gte
-- Returns a mask array where elements are greater than or equal to the value
do
  -- gte(value) includes the boundary value in the mask.
  local dist = lurek.compute.fromTable({2, 5, 7, 9})
  local far = dist:gte(7)
  lurek.log.info("far targets = " .. far:countNonZero(), "compute")
end

--@api-stub: Array:lte
-- Returns a mask array where elements are less than or equal to the value
do
  -- lte(value) includes the boundary value in the mask.
  local scores = lurek.compute.fromTable({100, 120, 95, 130})
  local under_cap = scores:lte(120)
  lurek.log.info("<=120 count = " .. under_cap:countNonZero(), "compute")
end

--@api-stub: LArray:addInplace
-- Adds another array into this array in place (mutates self)
do
  -- addInplace(other) modifies the array directly without allocating a new one.
  -- Use in hot loops where you accumulate forces, scores, or pixel values
  -- and want to avoid per-frame allocations.
  local a = lurek.compute.fromTable({1, 2, 3})
  local b = lurek.compute.fromTable({4, 5, 6})

  -- After this call, a = {5, 7, 9}. No new array is created.
  a:addInplace(b)
  lurek.log.info("addInplace result: " .. a:get(1) .. "," .. a:get(2) .. "," .. a:get(3), "compute")
end

--@api-stub: LArray:subInplace
-- Subtracts another array from this array in place (mutates self)
do
  -- subInplace(other) subtracts element-wise without allocation.
  -- Use for applying frame-by-frame decay, cooldown ticks, etc.
  local a = lurek.compute.fromTable({5, 5, 5})
  local b = lurek.compute.fromTable({1, 2, 3})

  -- After: a = {4, 3, 2}
  a:subInplace(b)
  lurek.log.info("subInplace result: " .. a:get(1) .. "," .. a:get(2) .. "," .. a:get(3), "compute")
end

--@api-stub: LArray:mulInplace
-- Multiplies this array by another array in place (mutates self)
do
  -- mulInplace(other) scales element-wise in place.
  -- Use for applying per-cell multipliers (e.g., resistance map * damage).
  local a = lurek.compute.fromTable({2, 3, 4})
  local b = lurek.compute.fromTable({5, 6, 7})

  -- After: a = {10, 18, 28}
  a:mulInplace(b)
  lurek.log.info("mulInplace result: " .. a:get(1) .. "," .. a:get(2) .. "," .. a:get(3), "compute")
end

--@api-stub: LArray:divInplace
-- Divides this array by another array in place (mutates self)
do
  -- divInplace(other) divides element-wise in place.
  -- Use for normalizing accumulated buffers by a count array.
  local a = lurek.compute.fromTable({8, 12, 16})
  local b = lurek.compute.fromTable({2, 3, 4})

  -- After: a = {4, 4, 4}
  a:divInplace(b)
  lurek.log.info("divInplace result: " .. a:get(1) .. "," .. a:get(2) .. "," .. a:get(3), "compute")
end

print("content/examples/compute.lua")

-- ---- Stub: LArray:add -------------------------------------------------------
--@api-stub: LArray:add
-- Returns a new array with element-wise addition of self and other.
-- TODO: replace this stub with a real scenario.
-- local c = a:add(b)  -- -> LArray (new allocation, self unchanged)

-- ---- Stub: LArray:sub -------------------------------------------------------
--@api-stub: LArray:sub
-- Returns a new array with element-wise subtraction of other from self.
-- TODO: replace this stub with a real scenario.
-- local c = a:sub(b)  -- -> LArray (new allocation, self unchanged)

-- ---- Stub: LArray:mul -------------------------------------------------------
--@api-stub: LArray:mul
-- Returns a new array with element-wise multiplication of self and other.
-- TODO: replace this stub with a real scenario.
-- local c = a:mul(b)  -- -> LArray (new allocation, self unchanged)

-- ---- Stub: LArray:div -------------------------------------------------------
--@api-stub: LArray:div
-- Returns a new array with element-wise division of self by other.
-- TODO: replace this stub with a real scenario.
-- local c = a:div(b)  -- -> LArray (new allocation, self unchanged)

-- =============================================================================
-- STUBS: 72 uncovered lurek.compute API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LArray methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LArray:getShape -----------------------------------------------
--@api-stub: LArray:getShape
-- Returns the array shape as one-based dimension table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:getShape()  -- -> table
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:getDimensions ------------------------------------------
--@api-stub: LArray:getDimensions
-- Returns the number of array dimensions.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:getDimensions()  -- -> integer
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:getSize ------------------------------------------------
--@api-stub: LArray:getSize
-- Returns the total number of array elements.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:getSize()  -- -> integer
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:getDataType --------------------------------------------
--@api-stub: LArray:getDataType
-- Returns the array data type name. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:getDataType()  -- -> string
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:isOnGPU ------------------------------------------------
--@api-stub: LArray:isOnGPU
-- Returns whether this array is currently stored on the GPU.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:isOnGPU()  -- -> boolean
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:get ----------------------------------------------------
--@api-stub: LArray:get
-- Reads an array element using one-based indices.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:get(...)  -- -> number
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:set ----------------------------------------------------
--@api-stub: LArray:set
-- Writes an array element using one-based indices followed by the value.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:set(...)
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:toTable ------------------------------------------------
--@api-stub: LArray:toTable
-- Returns array values flattened into a Lua table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:toTable()  -- -> table
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:reshape ------------------------------------------------
--@api-stub: LArray:reshape
-- Returns a reshaped copy of this array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:reshape(shape)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:clone --------------------------------------------------
--@api-stub: LArray:clone
-- Returns a copy of this array. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:clone()  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:transpose ----------------------------------------------
--@api-stub: LArray:transpose
-- Returns a transposed copy of a two-dimensional array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:transpose()  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:fill ---------------------------------------------------
--@api-stub: LArray:fill
-- Fills this array in place with one value.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:fill(val)
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:pow ----------------------------------------------------
--@api-stub: LArray:pow
-- Returns this array raised element-wise to a scalar exponent.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:pow(exp)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:sqrt ---------------------------------------------------
--@api-stub: LArray:sqrt
-- Returns element-wise square roots.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:sqrt()  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:abs ----------------------------------------------------
--@api-stub: LArray:abs
-- Returns element-wise absolute values.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:abs()  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:neg ----------------------------------------------------
--@api-stub: LArray:neg
-- Returns element-wise negated values.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:neg()  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:clamp --------------------------------------------------
--@api-stub: LArray:clamp
-- Returns values clamped between minimum and maximum bounds.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:clamp(min, max)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:eq -----------------------------------------------------
--@api-stub: LArray:eq
-- Returns element-wise equality comparison with an array or scalar.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:eq()  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:neq ----------------------------------------------------
--@api-stub: LArray:neq
-- Returns element-wise inequality comparison with an array or scalar.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:neq()  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:gt -----------------------------------------------------
--@api-stub: LArray:gt
-- Returns element-wise greater-than comparison with an array or scalar.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:gt()  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:lt -----------------------------------------------------
--@api-stub: LArray:lt
-- Returns element-wise less-than comparison with an array or scalar.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:lt()  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:gte ----------------------------------------------------
--@api-stub: LArray:gte
-- Returns element-wise greater-or-equal comparison with an array or scalar.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:gte()  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:lte ----------------------------------------------------
--@api-stub: LArray:lte
-- Returns element-wise less-or-equal comparison with an array or scalar.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:lte()  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:threshold ----------------------------------------------
--@api-stub: LArray:threshold
-- Returns a mask array where values above a threshold are selected.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:threshold(val)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:where --------------------------------------------------
--@api-stub: LArray:where
-- Selects values from this array or another array using a mask array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:where(mask, other)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:countNonZero -------------------------------------------
--@api-stub: LArray:countNonZero
-- Counts non-zero elements. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:countNonZero()  -- -> integer
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:argmin -------------------------------------------------
--@api-stub: LArray:argmin
-- Returns the one-based flat index of the minimum value.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:argmin()  -- -> integer
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:argmax -------------------------------------------------
--@api-stub: LArray:argmax
-- Returns the one-based flat index of the maximum value.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:argmax()  -- -> integer
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:any ----------------------------------------------------
--@api-stub: LArray:any
-- Returns whether any element is non-zero.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:any()  -- -> boolean
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:all ----------------------------------------------------
--@api-stub: LArray:all
-- Returns whether all elements are non-zero.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:all()  -- -> boolean
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:sum ----------------------------------------------------
--@api-stub: LArray:sum
-- Returns total sum or a summed array along a one-based axis.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:sum([axis])  -- -> LuaValue
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:mean ---------------------------------------------------
--@api-stub: LArray:mean
-- Returns total mean or a mean array along a one-based axis.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:mean([axis])  -- -> LuaValue
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:min ----------------------------------------------------
--@api-stub: LArray:min
-- Returns total minimum or a minimum array along a one-based axis.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:min([axis])  -- -> LuaValue
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:max ----------------------------------------------------
--@api-stub: LArray:max
-- Returns total maximum or a maximum array along a one-based axis.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:max([axis])  -- -> LuaValue
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:matmul -------------------------------------------------
--@api-stub: LArray:matmul
-- Returns matrix multiplication of this array and another array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:matmul(other)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:dot ----------------------------------------------------
--@api-stub: LArray:dot
-- Returns dot product with another array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:dot(other)  -- -> number
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:bitwiseAnd ---------------------------------------------
--@api-stub: LArray:bitwiseAnd
-- Returns element-wise bitwise AND with another array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:bitwiseAnd(other)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:bitwiseOr ----------------------------------------------
--@api-stub: LArray:bitwiseOr
-- Returns element-wise bitwise OR with another array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:bitwiseOr(other)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:bitwiseXor ---------------------------------------------
--@api-stub: LArray:bitwiseXor
-- Returns element-wise bitwise XOR with another array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:bitwiseXor(other)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:bitwiseNot ---------------------------------------------
--@api-stub: LArray:bitwiseNot
-- Returns element-wise bitwise NOT.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:bitwiseNot()  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:bitwiseLShift ------------------------------------------
--@api-stub: LArray:bitwiseLShift
-- Returns element-wise left shift by a bit count.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:bitwiseLShift(amount)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:bitwiseRShift ------------------------------------------
--@api-stub: LArray:bitwiseRShift
-- Returns element-wise right shift by a bit count.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:bitwiseRShift(amount)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:convolve2D ---------------------------------------------
--@api-stub: LArray:convolve2D
-- Returns two-dimensional convolution with a kernel array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:convolve2D(kernel)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:dilate -------------------------------------------------
--@api-stub: LArray:dilate
-- Returns morphological dilation with a radius.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:dilate(24.0)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:erode --------------------------------------------------
--@api-stub: LArray:erode
-- Returns morphological erosion with a radius.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:erode(24.0)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:floodFill ----------------------------------------------
--@api-stub: LArray:floodFill
-- Returns a flood-filled copy starting at a one-based row and column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:floodFill(row, col, val)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:getRegion ----------------------------------------------
--@api-stub: LArray:getRegion
-- Returns a rectangular region from this array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:getRegion(row, col, rows, cols)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:setRegion ----------------------------------------------
--@api-stub: LArray:setRegion
-- Writes a source array into this array at a one-based row and column.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:setRegion(row, col, source)
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:cumsum -------------------------------------------------
--@api-stub: LArray:cumsum
-- Returns cumulative sum over the flattened array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:cumsum()  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:diff ---------------------------------------------------
--@api-stub: LArray:diff
-- Returns finite differences over the flattened array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:diff([order])  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:histogram ----------------------------------------------
--@api-stub: LArray:histogram
-- Returns histogram bins for the array values.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:histogram(bins, [lo], [hi])  -- -> table
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:percentile ---------------------------------------------
--@api-stub: LArray:percentile
-- Returns a percentile value from the array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:percentile(p)  -- -> number
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:covariance ---------------------------------------------
--@api-stub: LArray:covariance
-- Returns covariance with another array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:covariance(other)  -- -> number
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:pearsonCorr --------------------------------------------
--@api-stub: LArray:pearsonCorr
-- Returns Pearson correlation with another array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:pearsonCorr(other)  -- -> number
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:normalizeRange -----------------------------------------
--@api-stub: LArray:normalizeRange
-- Returns array values normalized into a target range.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:normalizeRange(lo, hi)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:zscore -------------------------------------------------
--@api-stub: LArray:zscore
-- Returns z-score normalized array values.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:zscore()  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:convolve1d ---------------------------------------------
--@api-stub: LArray:convolve1d
-- Returns one-dimensional convolution with a kernel array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:convolve1d(kernel)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:correlate1d --------------------------------------------
--@api-stub: LArray:correlate1d
-- Returns one-dimensional correlation with a template array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:correlate1d(template)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:normalizeVec -------------------------------------------
--@api-stub: LArray:normalizeVec
-- Returns this vector normalized to unit length.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:normalizeVec()  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:outer --------------------------------------------------
--@api-stub: LArray:outer
-- Returns outer product with another vector array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:outer(other)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:cross2d ------------------------------------------------
--@api-stub: LArray:cross2d
-- Returns two-dimensional cross product with another vector.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:cross2d(other)  -- -> number
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:transformPoints ----------------------------------------
--@api-stub: LArray:transformPoints
-- Transforms a point array by this transform matrix.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:transformPoints(pts)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:sobel --------------------------------------------------
--@api-stub: LArray:sobel
-- Computes Sobel gradients for this array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:sobel()  -- -> table
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:linsolve -----------------------------------------------
--@api-stub: LArray:linsolve
-- Solves a linear system using this matrix and a right-hand side array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:linsolve(0.2)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:luDecompose --------------------------------------------
--@api-stub: LArray:luDecompose
-- Decomposes this matrix into LU data and permutation metadata.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:luDecompose()  -- -> table
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:eigenPower ---------------------------------------------
--@api-stub: LArray:eigenPower
-- Estimates dominant eigenvalue and eigenvector using power iteration.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:eigenPower([max_iter], [tol])  -- -> table
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:map ----------------------------------------------------
--@api-stub: LArray:map
-- Maps each element through a Lua function and returns a new array.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:map(func)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:eval ---------------------------------------------------
--@api-stub: LArray:eval
-- Maps each element through a Lua expression compiled as `function(x) return expression end`.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:eval(expr)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:reduce -------------------------------------------------
--@api-stub: LArray:reduce
-- Reduces array values with a Lua accumulator function.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:reduce(func, init)  -- -> number
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:scan ---------------------------------------------------
--@api-stub: LArray:scan
-- Produces prefix accumulator values with a Lua function.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:scan(func, init)  -- -> LArray
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:type ---------------------------------------------------
--@api-stub: LArray:type
-- Returns the Lua-visible type name for this array handle.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:type()  -- -> string
-- (replace lArray_stub with your real LArray instance above)

-- ---- Stub: LArray:typeOf -------------------------------------------------
--@api-stub: LArray:typeOf
-- Returns whether this array handle matches a supported type name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lArray_stub:typeOf("hero")  -- -> boolean
-- (replace lArray_stub with your real LArray instance above)
