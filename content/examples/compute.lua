-- content/examples/compute.lua
-- Hand-written coverage of the lurek.compute API (67 items).
--
-- The lurek.compute namespace exposes dense N-dimensional Array userdata with
-- NumPy-style operations: arithmetic, broadcasting, reshape, reductions,
-- linear algebra, FFT, morphology, and per-axis statistics. Arrays are CPU
-- buffers backed by Rust Vec<T>; create them with newArray/zeros/ones/range/
-- fromTable, then chain methods to build pipelines without copying tables.
--
-- Run: cargo run -- content/examples/compute.lua

-- ── lurek.compute.* functions ──

--@api-stub: lurek.compute.newArray
-- Creates a zero-initialized array with the given shape and optional dtype.
-- Use this when you need a typed buffer to fill in piecewise; pass dtype "int32" for index arrays.
do  -- lurek.compute.newArray
  local heat = lurek.compute.newArray({64, 64}, "float32")
  heat:set(1, 1, 1.0)
  heat:set(64, 64, 1.0)
  lurek.log.info("heat grid: " .. heat:getSize() .. " cells", "compute")
end

--@api-stub: lurek.compute.zeros
-- Creates a zero-filled array with the given shape and optional dtype.
-- Use as the starting state for accumulators (damage maps, occupancy grids) where every cell begins at 0.
do  -- lurek.compute.zeros
  local damage = lurek.compute.zeros({3, 3})
  damage:set(2, 2, 25.0)
  local total = damage:sum()
  lurek.log.info("total damage: " .. total, "compute")
end

--@api-stub: lurek.compute.ones
-- Creates a one-filled array with the given shape and optional dtype.
-- Use as a multiplicative identity buffer or initial weight matrix for blending masks.
do  -- lurek.compute.ones
  local mask = lurek.compute.ones({8, 8})
  local faded = mask:clamp(0.0, 0.5)
  lurek.log.info("faded mean: " .. faded:mean(), "compute")
end

--@api-stub: lurek.compute.range
-- Creates a 1D array from start to stop with optional step and dtype.
-- Use to build evenly spaced sample axes (frequency bins, animation keyframes) without a manual loop.
do  -- lurek.compute.range
  local frames = lurek.compute.range(0, 10, 1)
  local doubled = frames:pow(2)
  lurek.log.info("frame[5]^2 = " .. doubled:get(6), "compute")
end

--@api-stub: lurek.compute.fromTable
-- Creates an array from a Lua table of numbers with optional shape and dtype.
-- Use when raw Lua data (loaded from JSON, save files, or hand-authored tables) needs to enter the array pipeline.
do  -- lurek.compute.fromTable
  local samples = {0.1, 0.2, 0.4, 0.8, 1.0, 0.8, 0.4}
  local wave = lurek.compute.fromTable(samples)
  local peak = wave:max()
  lurek.log.info("wave peak: " .. peak, "compute")
end

--@api-stub: lurek.compute.gaussianKernel
-- Creates a sizeĂ—size Gaussian kernel array.
-- Use as the kernel argument to convolve2D for blur passes; size must be odd, sigma controls falloff.
do  -- lurek.compute.gaussianKernel
  local kernel = lurek.compute.gaussianKernel(5, 1.2)
  local weight_sum = kernel:sum()
  lurek.log.info("gaussian sum (should be ~1.0): " .. weight_sum, "compute")
end

--@api-stub: lurek.compute.rotate2dMatrix
-- Creates a 2Ă—2 rotation matrix for the given angle in radians.
-- Use to build a fixed rotation once at startup, then apply it via transformPoints to many points each frame.
do  -- lurek.compute.rotate2dMatrix
  local angle = math.pi / 4
  local rot = lurek.compute.rotate2dMatrix(angle)
  local pts = lurek.compute.fromTable({1, 0, 0, 1}, {2, 2})
  local rotated = rot:transformPoints(pts)
  lurek.log.info("rotated[1,1] = " .. rotated:get(1, 1), "compute")
end

--@api-stub: lurek.compute.affine2d
-- Creates a 3Ă—3 homogeneous affine matrix.
-- Use to combine translate, rotate, and scale into a single 3x3 matrix you can apply to homogeneous points.
do  -- lurek.compute.affine2d
  local tx, ty = 100, 50
  local m = lurek.compute.affine2d(tx, ty, 0.0, 2.0, 2.0)
  local origin = lurek.compute.fromTable({0, 0}, {1, 2})
  local moved = m:transformPoints(origin)
  lurek.log.info("moved x = " .. moved:get(1, 1), "compute")
end

--@api-stub: lurek.compute.fft
-- Computes the discrete Fourier transform of a 1D real-valued sample array.
-- Use to convert a window of audio samples into per-bin {re, im} complex spectra for analysis.
do  -- lurek.compute.fft
  local samples = {0.0, 1.0, 0.0, -1.0, 0.0, 1.0, 0.0, -1.0}
  local spectrum = lurek.compute.fft(samples)
  local bin0 = spectrum[1]
  lurek.log.info("bin 0 re=" .. bin0.re .. " im=" .. bin0.im, "fft")
end

--@api-stub: lurek.compute.ifft
-- Computes the inverse discrete Fourier transform.
-- Use to round-trip frequency-domain edits back to time-domain samples after filtering specific bins.
do  -- lurek.compute.ifft
  local samples = {1.0, 0.5, 0.0, -0.5}
  local freqs = lurek.compute.fft(samples)
  local rebuilt = lurek.compute.ifft(freqs)
  lurek.log.info("rebuilt[1] = " .. rebuilt[1], "fft")
end

--@api-stub: lurek.compute.fftMagnitude
-- Returns the magnitude spectrum `|X[k]|` of a real-valued sample array.
-- Use as a quick spectrum-strength readout for VU meters or spectrum bars without manual sqrt(re^2 + im^2).
do  -- lurek.compute.fftMagnitude
  local samples = {0.0, 1.0, 0.0, -1.0, 0.0, 1.0, 0.0, -1.0}
  local mags = lurek.compute.fftMagnitude(samples)
  lurek.log.info("mag[2] = " .. mags[2], "fft")
end

-- ── Array methods ──

--@api-stub: Array:getShape
-- Returns the shape as a table of dimension sizes.
-- Use to validate dimensions before chaining shape-sensitive ops like matmul or transformPoints.
do  -- Array:getShape
  local grid = lurek.compute.zeros({4, 6})
  local shape = grid:getShape()
  lurek.log.info("grid is " .. shape[1] .. "x" .. shape[2], "compute")
end

--@api-stub: Array:getDimensions
-- Returns the number of dimensions.
-- Use to branch on rank when the same code path handles vectors, matrices, or higher tensors.
do  -- Array:getDimensions
  local v = lurek.compute.range(0, 5)
  if v:getDimensions() == 1 then
    lurek.log.info("vector, len=" .. v:getSize(), "compute")
  end
end

--@api-stub: Array:getSize
-- Returns the total number of elements.
-- Use to size auxiliary Lua tables (results, indices) before iterating an array's flat element count.
do  -- Array:getSize
  local img = lurek.compute.zeros({16, 16})
  local n = img:getSize()
  lurek.log.info("img has " .. n .. " pixels", "compute")
end

--@api-stub: Array:getDataType
-- Returns the element data type name.
-- Use before bitwise ops to assert the array is an int32 buffer (those reject float dtypes).
do  -- Array:getDataType
  local mask = lurek.compute.zeros({8}, "int32")
  local dt = mask:getDataType()
  if dt == "int32" then lurek.log.info("ready for bitwise ops", "compute") end
end

--@api-stub: Array:isOnGPU
-- Returns false (CPU arrays only).
-- Use as a fast guard in code that wants to skip a CPU-only fallback path; today this always returns false.
do  -- Array:isOnGPU
  local arr = lurek.compute.zeros({4})
  if not arr:isOnGPU() then
    lurek.log.debug("running compute on CPU", "compute")
  end
end

--@api-stub: Array:get
-- Returns the element at the given 1-based indices.
-- Use to read individual cells; pass one index per dimension, all 1-based as in standard Lua.
do  -- Array:get
  pcall(function()
    local m = lurek.compute.fromTable({1, 2, 3, 4}, {2, 2})
    local top_right = m:get(1, 2)
    lurek.log.info("m[1,2] = " .. top_right, "compute")
  end)
end

--@api-stub: Array:set
-- Sets the element at the given 1-based indices to a value.
-- Use to mutate a single cell in place; for bulk fills prefer setRegion or fill which avoid the per-call overhead.
do  -- Array:set
  local board = lurek.compute.zeros({3, 3})
  board:set(2, 2, 1.0)
  lurek.log.info("centre = " .. board:get(2, 2), "compute")
end

--@api-stub: Array:toTable
-- Returns all elements as a flat table of numbers.
-- Use to hand the array's data off to Lua-only code (serialization, foreign libs); the result is always flat.
do  -- Array:toTable
  local arr = lurek.compute.range(0, 4)
  local flat = arr:toTable()
  lurek.log.info("flat[3] = " .. flat[3] .. ", count=" .. #flat, "compute")
end

--@api-stub: Array:reshape
-- Returns a new array with the given shape and the same data.
-- Use to reinterpret data as a different rank without copying; the product of the new shape must equal getSize().
do  -- Array:reshape
  local row = lurek.compute.range(0, 6)
  local grid = row:reshape({2, 3})
  lurek.log.info("grid[2,3] = " .. grid:get(2, 3), "compute")
end

--@api-stub: Array:clone
-- Returns a deep copy of this array.
-- Use before any mutating call (set, fill, setRegion) when the original buffer must be preserved.
do  -- Array:clone
  local original = lurek.compute.ones({4})
  local copy = original:clone()
  copy:fill(0.0)
  lurek.log.info("orig sum=" .. original:sum() .. " copy sum=" .. copy:sum(), "compute")
end

--@api-stub: Array:transpose
-- Returns the transposed 2D array.
-- Use to swap rows and columns of a 2D matrix before matmul when one operand is laid out in the wrong order.
do  -- Array:transpose
  local m = lurek.compute.fromTable({1, 2, 3, 4, 5, 6}, {2, 3})
  local t = m:transpose()
  lurek.log.info("t shape: " .. t:getShape()[1] .. "x" .. t:getShape()[2], "compute")
end

--@api-stub: Array:fill
-- Fills all elements with the given value in-place.
-- Use to reset a reusable scratch array each frame instead of reallocating a fresh zeros() buffer.
do  -- Array:fill
  local scratch = lurek.compute.zeros({32, 32})
  scratch:fill(-1.0)
  lurek.log.info("scratch sum after fill: " .. scratch:sum(), "compute")
end

--@api-stub: Array:pow
-- Raises each element to a scalar exponent.
-- Use to apply a uniform exponent (square, cube, square-root via 0.5) across every element in one call.
do  -- Array:pow
  local v = lurek.compute.fromTable({1, 2, 3, 4})
  local sq = v:pow(2)
  lurek.log.info("4^2 = " .. sq:get(4), "compute")
end

--@api-stub: Array:sqrt
-- Element-wise square root.
-- Use to compute distances after summing squared deltas; cheaper than calling pow(0.5).
do  -- Array:sqrt
  local sq = lurek.compute.fromTable({1, 4, 9, 16})
  local roots = sq:sqrt()
  lurek.log.info("sqrt(16) = " .. roots:get(4), "compute")
end

--@api-stub: Array:abs
-- Element-wise absolute value.
-- Use to take the magnitude of signed deltas (velocity changes, scroll deltas) before thresholding.
do  -- Array:abs
  local deltas = lurek.compute.fromTable({-3, 1, -2, 4})
  local mag = deltas:abs()
  lurek.log.info("abs sum = " .. mag:sum(), "compute")
end

--@api-stub: Array:neg
-- Returns a new Array with every element negated (multiplied by â’1).
-- Use to flip the sign of every element, e.g. converting a force vector into a counter-impulse.
do  -- Array:neg
  local impulse = lurek.compute.fromTable({2, -1, 4})
  local counter = impulse:neg()
  lurek.log.info("counter[1] = " .. counter:get(1), "compute")
end

--@api-stub: Array:clamp
-- Clamps each element to the given range.
-- Use to keep colour channels in [0,1] or HP values in [0, max_hp] without writing per-element loops.
do  -- Array:clamp
  local hp = lurek.compute.fromTable({120, -5, 75, 200})
  local clamped = hp:clamp(0, 100)
  lurek.log.info("clamped max = " .. clamped:max(), "compute")
end

--@api-stub: Array:threshold
-- Returns a mask array with 1.0 where elements >= val, else 0.0.
-- Use to build binary masks (visible/hidden, on/off) from a continuous field by picking a cutoff value.
do  -- Array:threshold
  local field = lurek.compute.range(0, 8)
  local visible = field:threshold(4.0)
  lurek.log.info("cells visible: " .. visible:sum(), "compute")
end

--@api-stub: Array:countNonZero
-- Returns the count of nonzero elements.
-- Use to count how many cells of a mask survived a threshold pass (live entities, occupied tiles).
do  -- Array:countNonZero
  local occupied = lurek.compute.fromTable({0, 1, 0, 1, 1, 0})
  local live = occupied:countNonZero()
  lurek.log.info("occupied tiles: " .. live, "compute")
end

--@api-stub: Array:argmin
-- Returns the 1-based flat index of the minimum element.
-- Use to find the index of the closest enemy in a flat distances array; result is 1-based.
do  -- Array:argmin
  local distances = lurek.compute.fromTable({12, 4, 9, 7})
  local nearest = distances:argmin()
  lurek.log.info("nearest enemy index: " .. nearest, "ai")
end

--@api-stub: Array:argmax
-- Returns the 1-based flat index of the maximum element.
-- Use to pick the highest-utility action from an AI scoring vector in a single O(n) sweep.
do  -- Array:argmax
  local scores = lurek.compute.fromTable({0.2, 0.5, 0.9, 0.4})
  local choice = scores:argmax()
  lurek.log.info("AI picks action " .. choice, "ai")
end

--@api-stub: Array:any
-- Returns true if any element is nonzero.
-- Use as an early-exit check (any damage taken? any enemies alive?) before more expensive per-cell work.
do  -- Array:any
  local hits = lurek.compute.fromTable({0, 0, 1, 0})
  if hits:any() then
    lurek.log.warn("at least one hit registered", "combat")
  end
end

--@api-stub: Array:all
-- Returns true if all elements are nonzero.
-- Use to gate progression on every condition being met (all switches on, all bosses dead).
do  -- Array:all
  local switches = lurek.compute.fromTable({1, 1, 1, 1})
  if switches:all() then
    lurek.log.info("door unlocked", "puzzle")
  end
end

--@api-stub: Array:sum
-- Sum of all elements, or along an axis (1-based).
-- Use to total damage, score, or resources; pass an axis to collapse rows or columns of a matrix instead.
do  -- Array:sum
  local hits = lurek.compute.fromTable({3, 1, 4, 1, 5, 9})
  local total = hits:sum()
  lurek.log.info("total damage: " .. total, "compute")
end

--@api-stub: Array:mean
-- Mean of all elements, or along an axis (1-based).
-- Use to average frame times, RGB values, or sensor readings; pass an axis to get per-row or per-column means.
do  -- Array:mean
  local frame_ms = lurek.compute.fromTable({16.1, 16.7, 17.2, 16.9, 16.4})
  local avg = frame_ms:mean()
  lurek.log.info("avg frame ms: " .. avg, "perf")
end

--@api-stub: Array:min
-- Minimum of all elements, or along an axis (1-based).
-- Use to find the cheapest path cost or coldest cell; pass an axis to reduce one dimension at a time.
do  -- Array:min
  local costs = lurek.compute.fromTable({7, 3, 9, 4})
  local cheapest = costs:min()
  lurek.log.info("cheapest cost: " .. cheapest, "compute")
end

--@api-stub: Array:max
-- Maximum of all elements, or along an axis (1-based).
-- Use to report the worst-case latency or hottest tile; pass an axis to keep per-row/column maxima.
do  -- Array:max
  local latencies = lurek.compute.fromTable({12, 30, 18, 25})
  local worst = latencies:max()
  lurek.log.info("worst latency: " .. worst .. "ms", "net")
end

--@api-stub: Array:matmul
-- Matrix multiplication of two 2D arrays.
-- Use for transformations on batches of points or for dense linear-algebra steps in physics solvers.
do  -- Array:matmul
  local a = lurek.compute.fromTable({1, 2, 3, 4}, {2, 2})
  local b = lurek.compute.fromTable({5, 6, 7, 8}, {2, 2})
  local c = a:matmul(b)
  lurek.log.info("c[1,1] = " .. c:get(1, 1), "compute")
end

--@api-stub: Array:dot
-- Dot product of two 1D arrays.
-- Use to project one vector onto another (alignment, similarity, cosine numerator) in a single call.
do  -- Array:dot
  local heading = lurek.compute.fromTable({1, 0})
  local target = lurek.compute.fromTable({0.7, 0.7})
  local alignment = heading:dot(target)
  lurek.log.info("alignment: " .. alignment, "ai")
end

--@api-stub: Array:bitwiseAnd
-- Bitwise AND of two Int32 arrays.
-- Use on int32 tile masks to find tiles where two layers (walkable, lit) are both set.
do  -- Array:bitwiseAnd
  local walk = lurek.compute.fromTable({1, 1, 0, 1}, nil, "int32")
  local lit  = lurek.compute.fromTable({1, 0, 1, 1}, nil, "int32")
  local both = walk:bitwiseAnd(lit)
  lurek.log.info("walkable AND lit count: " .. both:countNonZero(), "tiles")
end

--@api-stub: Array:bitwiseOr
-- Bitwise OR of two Int32 arrays.
-- Use to merge two int32 mask layers into a union (player FOV OR memory FOV).
do  -- Array:bitwiseOr
  local fov  = lurek.compute.fromTable({1, 0, 0, 1}, nil, "int32")
  local mem  = lurek.compute.fromTable({0, 1, 0, 0}, nil, "int32")
  local seen = fov:bitwiseOr(mem)
  lurek.log.info("seen-tile count: " .. seen:countNonZero(), "fov")
end

--@api-stub: Array:bitwiseXor
-- Bitwise XOR of two Int32 arrays.
-- Use to flip bits where two int32 masks differ (toggle dirty cells, detect mask changes between frames).
do  -- Array:bitwiseXor
  local prev = lurek.compute.fromTable({1, 0, 1, 1}, nil, "int32")
  local curr = lurek.compute.fromTable({1, 1, 1, 0}, nil, "int32")
  local changed = prev:bitwiseXor(curr)
  lurek.log.info("cells changed: " .. changed:countNonZero(), "tiles")
end

--@api-stub: Array:bitwiseNot
-- Bitwise NOT of an Int32 array.
-- Use to invert an int32 mask (free tiles from occupied tiles) without iterating manually.
do  -- Array:bitwiseNot
  local occupied = lurek.compute.fromTable({1, 0, 0, 1}, nil, "int32")
  local free = occupied:bitwiseNot()
  lurek.log.info("free mask[2] = " .. free:get(2), "tiles")
end

--@api-stub: Array:bitwiseLShift
-- Bitwise left shift of an Int32 array.
-- Use to multiply int32 values by powers of two (palette index packing, fast x16 scaling).
do  -- Array:bitwiseLShift
  local ids = lurek.compute.fromTable({1, 2, 3, 4}, nil, "int32")
  local packed = ids:bitwiseLShift(4)
  lurek.log.info("packed[2] = " .. packed:get(2), "compute")
end

--@api-stub: Array:bitwiseRShift
-- Bitwise right shift of an Int32 array.
-- Use to divide int32 values by powers of two (extract high bits from a packed colour or tile id).
do  -- Array:bitwiseRShift
  local packed = lurek.compute.fromTable({16, 32, 48, 64}, nil, "int32")
  local high = packed:bitwiseRShift(4)
  lurek.log.info("high[3] = " .. high:get(3), "compute")
end

--@api-stub: Array:convolve2D
-- 2D convolution with zero-padding.
-- Use with a gaussianKernel for a blurred lightmap or a custom 3x3 kernel for edge / sharpen passes.
do  -- Array:convolve2D
  local img = lurek.compute.ones({8, 8})
  local k = lurek.compute.gaussianKernel(3, 0.8)
  local blurred = img:convolve2D(k)
  lurek.log.info("blurred mean = " .. blurred:mean(), "compute")
end

--@api-stub: Array:dilate
-- Morphological dilation with a diamond structuring element.
-- Use to thicken a binary collision mask so swept-volume queries round corners safely; radius is in cells.
do  -- Array:dilate
  local mask = lurek.compute.zeros({5, 5})
  mask:set(3, 3, 1.0)
  local grown = mask:dilate(1)
  lurek.log.info("grown nonzero: " .. grown:countNonZero(), "compute")
end

--@api-stub: Array:erode
-- Morphological erosion with a diamond structuring element.
-- Use to peel one cell off a mask boundary, producing a safe interior for spawn-point selection.
do  -- Array:erode
  local mask = lurek.compute.ones({4, 4})
  local interior = mask:erode(1)
  lurek.log.info("interior cells: " .. interior:countNonZero(), "compute")
end

--@api-stub: Array:cumsum
-- Cumulative sum of all elements (flattened).
-- Use to build prefix sums for fast range-sum queries on damage logs or score histories.
do  -- Array:cumsum
  local scores = lurek.compute.fromTable({1, 2, 3, 4})
  local running = scores:cumsum()
  lurek.log.info("score after 3rd round = " .. running:get(3), "score")
end

--@api-stub: Array:diff
-- Discrete difference applied `order` times.
-- Use to convert a position series into velocities (order=1) or accelerations (order=2) for analysis.
do  -- Array:diff
  local pos = lurek.compute.fromTable({0, 1, 3, 6, 10})
  local vel = pos:diff(1)
  lurek.log.info("vel[2] = " .. vel:get(2), "compute")
end

--@api-stub: Array:percentile
-- Compute the p-th percentile (0â€“100).
-- Use to compute p50 / p95 frame times for perf budgets without sorting tables yourself.
do  -- Array:percentile
  local times = lurek.compute.fromTable({16, 17, 18, 19, 33})
  local p95 = times:percentile(95)
  lurek.log.info("frame p95 = " .. p95 .. "ms", "perf")
end

--@api-stub: Array:covariance
-- Population covariance with another 1D array.
-- Use to detect coupled signals (input vs output) before deciding whether to plot them together.
do  -- Array:covariance
  local x = lurek.compute.fromTable({1, 2, 3, 4})
  local y = lurek.compute.fromTable({2, 4, 6, 8})
  local cov = x:covariance(y)
  lurek.log.info("cov(x,y) = " .. cov, "compute")
end

--@api-stub: Array:pearsonCorr
-- Pearson correlation coefficient with another 1D array.
-- Use to score linear similarity between two telemetry streams; result is in [-1, 1].
do  -- Array:pearsonCorr
  local fps = lurek.compute.fromTable({60, 58, 55, 50, 45})
  local entities = lurek.compute.fromTable({100, 150, 200, 280, 360})
  local r = fps:pearsonCorr(entities)
  lurek.log.info("fps vs entity correlation: " .. r, "perf")
end

--@api-stub: Array:normalizeRange
-- Linearly rescale values to [out_min, out_max].
-- Use to remap noise or sensor data into the [0,1] range needed by colour shaders or UI bars.
do  -- Array:normalizeRange
  local raw = lurek.compute.fromTable({-2, 0, 2, 4})
  local unit = raw:normalizeRange(0, 1)
  lurek.log.info("unit min=" .. unit:min() .. " max=" .. unit:max(), "compute")
end

--@api-stub: Array:zscore
-- Standardise values to zero mean and unit variance.
-- Use to standardise a feature vector before feeding an AI utility function or anomaly detector.
do  -- Array:zscore
  local features = lurek.compute.fromTable({10, 12, 14, 18, 20})
  local z = features:zscore()
  lurek.log.info("z[1] = " .. z:get(1), "compute")
end

--@api-stub: Array:convolve1d
-- 1D convolution with a kernel array (full output).
-- Use to smooth a 1D signal (audio envelope, frame-time history) with a small symmetric kernel.
do  -- Array:convolve1d
  local signal = lurek.compute.fromTable({0, 1, 0, 1, 0, 1, 0})
  local kernel = lurek.compute.fromTable({0.25, 0.5, 0.25})
  local smoothed = signal:convolve1d(kernel)
  lurek.log.info("smoothed length: " .. smoothed:getSize(), "compute")
end

--@api-stub: Array:correlate1d
-- 1D cross-correlation with a template array (valid output).
-- Use for sliding-window template matching (audio cue detection, controller-gesture spotting).
do  -- Array:correlate1d
  local stream   = lurek.compute.fromTable({0, 1, 2, 3, 2, 1, 0})
  local template = lurek.compute.fromTable({1, 2, 3})
  local match    = stream:correlate1d(template)
  lurek.log.info("best match index: " .. match:argmax(), "compute")
end

--@api-stub: Array:normalizeVec
-- L2-normalise a 1D vector.
-- Use to turn a steering vector or surface normal into unit length before scaling by a desired speed.
do  -- Array:normalizeVec
  local v = lurek.compute.fromTable({3, 4})
  local unit = v:normalizeVec()
  lurek.log.info("unit[1]^2 + unit[2]^2 = " .. unit:pow(2):sum(), "compute")
end

--@api-stub: Array:outer
-- Outer product of two 1D vectors â†’ 2D array [m, n].
-- Use to expand two 1D vectors into a [m,n] matrix for kernels, weight maps, or radial gradients.
do  -- Array:outer
  local row = lurek.compute.fromTable({1, 2, 3})
  local col = lurek.compute.fromTable({1, 2})
  local mat = row:outer(col)
  lurek.log.info("outer[2,2] = " .. mat:get(2, 2), "compute")
end

--@api-stub: Array:cross2d
-- Signed 2D cross product with another length-2 array.
-- Use to detect left/right turn direction (sign of the result) for AI line-of-sight checks.
do  -- Array:cross2d
  local heading = lurek.compute.fromTable({1, 0})
  local target  = lurek.compute.fromTable({0, 1})
  local cross   = heading:cross2d(target)
  lurek.log.info("turn direction: " .. (cross > 0 and "left" or "right"), "ai")
end

--@api-stub: Array:transformPoints
-- Apply this 2Ă—2 or 3Ă—3 matrix to an [N,2] points array.
-- Use to batch-transform many points by one matrix; far cheaper than calling matmul per point.
do  -- Array:transformPoints
  pcall(function()
    local rot = lurek.compute.rotate2dMatrix(math.pi / 2)
    local pts = lurek.compute.fromTable({1, 0, 0, 1}, {2, 2})
    local out = rot:transformPoints(pts)
    lurek.log.info("rotated[1,2] = " .. out:get(1, 2), "compute")
  end)
end

--@api-stub: Array:sobel
-- Apply Sobel edge detection to a 2D array.
-- Use on a 2D heightmap or grayscale image to extract gradient channels for normal-map or outline shaders.
do  -- Array:sobel
  local img = lurek.compute.ones({4, 4})
  local g = img:sobel()
  lurek.log.info("gx[2,2] = " .. g.gx:get(2, 2) .. " gy[2,2] = " .. g.gy:get(2, 2), "compute")
end

--@api-stub: Array:linsolve
-- Solve AÂ·x = b where this array is A (square [n,n]) and b is a 1D vector.
-- Use to solve small dense systems (constraint solvers, IK targets) where matrix inverse is overkill.
do  -- Array:linsolve
  local a = lurek.compute.fromTable({2, 1, 1, 3}, {2, 2})
  local b = lurek.compute.fromTable({5, 10})
  local x = a:linsolve(b)
  lurek.log.info("x[1] = " .. x:get(1) .. " x[2] = " .. x:get(2), "compute")
end

--@api-stub: Array:luDecompose
-- Decomposes this square matrix into L and U factors with partial pivoting.
-- Use once per matrix to amortise the factorisation cost across many right-hand-side solves.
do  -- Array:luDecompose
  local a = lurek.compute.fromTable({4, 3, 6, 3}, {2, 2})
  local lu = a:luDecompose()
  lurek.log.info("LU n=" .. lu.n .. " det_sign=" .. lu.det_sign, "compute")
end

--@api-stub: Array:type
-- Returns the type name "Array".
-- Use in generic helpers that accept several userdata kinds and need to dispatch on the type tag.
do  -- Array:type
  local arr = lurek.compute.zeros({2})
  local kind = arr:type()
  if kind == "Array" then lurek.log.debug("got an Array", "compute") end
end

--@api-stub: Array:typeOf
-- Returns true when the given name matches "Array" or a parent type.
-- Use to support hierarchical type checks; "Object" returns true for every Array as well.
do  -- Array:typeOf
  local arr = lurek.compute.zeros({2})
  if arr:typeOf("Array") then
    lurek.log.debug("typeOf check passed", "compute")
  end
end

--@api-stub: Array:map
-- Apply a Lua callback element-wise, returning a new Array of the same shape.
-- Use to transform every element without a manual loop.
do  -- Array:map
  local a = lurek.compute.fromTable({1, 4, 9})
  local b = a:map(function(x) return math.sqrt(x) end)
  lurek.log.debug("map sqrt: " .. tostring(b:toTable()[1]), "compute")
end

--@api-stub: Array:eval
-- Evaluate a Lua expression string element-wise, returning a new Array.
-- The variable x holds the current element; useful for quick one-off transforms.
do  -- Array:eval
  local a = lurek.compute.fromTable({1, 2, 3})
  local b = a:eval("x * x + 1")
  lurek.log.debug("eval x^2+1: " .. tostring(b:toTable()[2]), "compute")
end

--@api-stub: Array:reduce
-- Fold the array left-to-right with an accumulator function, returning a scalar.
-- Use for sum, product, max, or any custom fold.
do  -- Array:reduce
  local a = lurek.compute.fromTable({1, 2, 3, 4})
  local total = a:reduce(function(acc, x) return acc + x end, 0)
  lurek.log.debug("reduce sum: " .. tostring(total), "compute")
end

--@api-stub: Array:scan
-- Running accumulation — like reduce but returns every intermediate result as an Array.
-- Use for prefix sums, running averages, or cumulative scoring.
do  -- Array:scan
  local a = lurek.compute.fromTable({1, 2, 3, 4})
  local prefix = a:scan(function(acc, x) return acc + x end, 0)
  lurek.log.debug("scan prefix[4]: " .. tostring(prefix:toTable()[4]), "compute")
end

