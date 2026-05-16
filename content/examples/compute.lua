-- content/examples/compute.lua
-- lurek.compute API examples.
-- Run: cargo run -- content/examples/compute.lua

--@api-stub: lurek.compute.newArray
-- Creates a zero-filled array with the requested shape and data type
do
  local heat = lurek.compute.newArray({64, 64}, "float32")
  heat:set(1, 1, 1.0)
  heat:set(64, 64, 1.0)
  lurek.log.info("heat grid: " .. heat:getSize() .. " cells", "compute")
end

--@api-stub: lurek.compute.zeros
-- Creates a zero-filled array with the requested shape and data type
do
  local damage = lurek.compute.zeros({3, 3})
  damage:set(2, 2, 25.0)
  local total = damage:sum()
  lurek.log.info("total damage: " .. total, "compute")
end

--@api-stub: lurek.compute.ones
-- Creates a one-filled array with the requested shape and data type
do
  local mask = lurek.compute.ones({8, 8})
  local faded = mask:clamp(0.0, 0.5)
  lurek.log.info("faded mean: " .. faded:mean(), "compute")
end

--@api-stub: lurek.compute.range
-- Creates a one-dimensional range array
do
  local frames = lurek.compute.range(0, 10, 1)
  local doubled = frames:pow(2)
  lurek.log.info("frame[5]^2 = " .. doubled:get(6), "compute")
end

--@api-stub: lurek.compute.fromTable
-- Creates an array from a flat Lua table and optional shape
do
  local samples = {0.1, 0.2, 0.4, 0.8, 1.0, 0.8, 0.4}
  local wave = lurek.compute.fromTable(samples)
  local peak = wave:max()
  lurek.log.info("wave peak: " .. peak, "compute")
end

--@api-stub: lurek.compute.getParThreshold
-- Returns the global compute parallelism threshold
do
  local threshold = lurek.compute.getParThreshold()
  lurek.log.info("compute parallel threshold=" .. threshold, "compute")
end

--@api-stub: lurek.compute.setParThreshold
-- Sets the global compute parallelism threshold and returns the previous value
do
  local previous = lurek.compute.getParThreshold()
  lurek.compute.setParThreshold(1024)
  local updated = lurek.compute.getParThreshold()
  lurek.log.info("threshold " .. previous .. " -> " .. updated, "compute")
end

--@api-stub: lurek.compute.gaussianKernel
-- Creates a square Gaussian kernel array
do
  local kernel = lurek.compute.gaussianKernel(5, 1.2)
  local weight_sum = kernel:sum()
  lurek.log.info("gaussian sum (should be approx 1.0): " .. weight_sum, "compute")
end

--@api-stub: lurek.compute.rotate2dMatrix
-- Creates a 2D rotation matrix
do
  local angle = math.pi / 4
  local rot = lurek.compute.rotate2dMatrix(angle)
  local pts = lurek.compute.fromTable({1, 0, 0, 1}, {2, 2})
  local rotated = rot:transformPoints(pts)
  lurek.log.info("rotated[1,1] = " .. rotated:get(1, 1), "compute")
end

--@api-stub: lurek.compute.affine2d
-- Creates a 2D affine transform matrix
do
  local tx, ty = 100, 50
  local m = lurek.compute.affine2d(tx, ty, 0.0, 2.0, 2.0)
  local origin = lurek.compute.fromTable({0, 0}, {1, 2})
  local moved = m:transformPoints(origin)
  lurek.log.info("moved x = " .. moved:get(1, 1), "compute")
end

--@api-stub: lurek.compute.fft
-- Computes the FFT of real-valued samples
do
  local samples = {0.0, 1.0, 0.0, -1.0, 0.0, 1.0, 0.0, -1.0}
  local spectrum = lurek.compute.fft(samples)
  local bin0 = spectrum[1]
  lurek.log.info("bin 0 re=" .. bin0.re .. " im=" .. bin0.im, "fft")
end

--@api-stub: lurek.compute.ifft
-- Computes the inverse FFT of complex frequency pairs
do
  local samples = {1.0, 0.5, 0.0, -0.5}
  local freqs = lurek.compute.fft(samples)
  local rebuilt = lurek.compute.ifft(freqs)
  lurek.log.info("rebuilt[1] = " .. rebuilt[1], "fft")
end

--@api-stub: lurek.compute.fftMagnitude
-- Computes FFT magnitudes for real-valued samples
do
  local samples = {0.0, 1.0, 0.0, -1.0, 0.0, 1.0, 0.0, -1.0}
  local mags = lurek.compute.fftMagnitude(samples)
  lurek.log.info("mag[2] = " .. mags[2], "fft")
end

-- Array methods

--@api-stub: Array:getShape
-- Returns the shape of this array.
do
  local grid = lurek.compute.zeros({4, 6})
  local shape = grid:getShape()
  lurek.log.info("grid is " .. shape[1] .. "x" .. shape[2], "compute")
end

--@api-stub: Array:getDimensions
-- Returns the dimensions of this array.
do
  local v = lurek.compute.range(0, 5)
  if v:getDimensions() == 1 then
    lurek.log.info("vector, len=" .. v:getSize(), "compute")
  end
end

--@api-stub: Array:getSize
-- Returns the size of this array.
do
  local img = lurek.compute.zeros({16, 16})
  local n = img:getSize()
  lurek.log.info("img has " .. n .. " pixels", "compute")
end

--@api-stub: Array:getDataType
-- Returns the data type of this array.
do
  local mask = lurek.compute.zeros({8}, "int32")
  local dt = mask:getDataType()
  if dt == "int32" then lurek.log.info("ready for bitwise ops", "compute") end
end

--@api-stub: Array:isOnGPU
-- Returns true if this array on gpu.
do
  local arr = lurek.compute.zeros({4})
  if not arr:isOnGPU() then
    lurek.log.debug("running compute on CPU", "compute")
  end
end

--@api-stub: Array:get
-- Returns the  of this array.
do
  pcall(function()
    local m = lurek.compute.fromTable({1, 2, 3, 4}, {2, 2})
    local top_right = m:get(1, 2)
    lurek.log.info("m[1,2] = " .. top_right, "compute")
  end)
end

--@api-stub: Array:set
-- Sets the  of this array.
do
  local board = lurek.compute.zeros({3, 3})
  board:set(2, 2, 1.0)
  lurek.log.info("centre = " .. board:get(2, 2), "compute")
end

--@api-stub: Array:toTable
-- Performs the to table operation on this array.
do
  local arr = lurek.compute.range(0, 4)
  local flat = arr:toTable()
  lurek.log.info("flat[3] = " .. flat[3] .. ", count=" .. #flat, "compute")
end

--@api-stub: Array:reshape
-- Performs the reshape operation on this array.
do
  local row = lurek.compute.range(0, 6)
  local grid = row:reshape({2, 3})
  lurek.log.info("grid[2,3] = " .. grid:get(2, 3), "compute")
end

--@api-stub: Array:clone
-- Performs the clone operation on this array.
do
  local original = lurek.compute.ones({4})
  local copy = original:clone()
  copy:fill(0.0)
  lurek.log.info("orig sum=" .. original:sum() .. " copy sum=" .. copy:sum(), "compute")
end

--@api-stub: Array:transpose
-- Performs the transpose operation on this array.
do
  local m = lurek.compute.fromTable({1, 2, 3, 4, 5, 6}, {2, 3})
  local t = m:transpose()
  lurek.log.info("t shape: " .. t:getShape()[1] .. "x" .. t:getShape()[2], "compute")
end

--@api-stub: Array:fill
-- Performs the fill operation on this array.
do
  local scratch = lurek.compute.zeros({32, 32})
  scratch:fill(-1.0)
  lurek.log.info("scratch sum after fill: " .. scratch:sum(), "compute")
end

--@api-stub: Array:pow
-- Performs the pow operation on this array.
do
  local v = lurek.compute.fromTable({1, 2, 3, 4})
  local sq = v:pow(2)
  lurek.log.info("4^2 = " .. sq:get(4), "compute")
end

--@api-stub: Array:sqrt
-- Performs the sqrt operation on this array.
do
  local sq = lurek.compute.fromTable({1, 4, 9, 16})
  local roots = sq:sqrt()
  lurek.log.info("sqrt(16) = " .. roots:get(4), "compute")
end

--@api-stub: Array:abs
-- Performs the abs operation on this array.
do
  local deltas = lurek.compute.fromTable({-3, 1, -2, 4})
  local mag = deltas:abs()
  lurek.log.info("abs sum = " .. mag:sum(), "compute")
end

--@api-stub: Array:neg
-- Performs the neg operation on this array.
do
  local impulse = lurek.compute.fromTable({2, -1, 4})
  local counter = impulse:neg()
  lurek.log.info("counter[1] = " .. counter:get(1), "compute")
end

--@api-stub: Array:clamp
-- Performs the clamp operation on this array.
do
  local hp = lurek.compute.fromTable({120, -5, 75, 200})
  local clamped = hp:clamp(0, 100)
  lurek.log.info("clamped max = " .. clamped:max(), "compute")
end

--@api-stub: Array:threshold
-- Performs the threshold operation on this array.
do
  local field = lurek.compute.range(0, 8)
  local visible = field:threshold(4.0)
  lurek.log.info("cells visible: " .. visible:sum(), "compute")
end

--@api-stub: Array:countNonZero
-- Performs the count non zero operation on this array.
do
  local occupied = lurek.compute.fromTable({0, 1, 0, 1, 1, 0})
  local live = occupied:countNonZero()
  lurek.log.info("occupied tiles: " .. live, "compute")
end

--@api-stub: Array:argmin
-- Performs the argmin operation on this array.
do
  local distances = lurek.compute.fromTable({12, 4, 9, 7})
  local nearest = distances:argmin()
  lurek.log.info("nearest enemy index: " .. nearest, "ai")
end

--@api-stub: Array:argmax
-- Performs the argmax operation on this array.
do
  local scores = lurek.compute.fromTable({0.2, 0.5, 0.9, 0.4})
  local choice = scores:argmax()
  lurek.log.info("AI picks action " .. choice, "ai")
end

--@api-stub: Array:any
-- Performs the any operation on this array.
do
  local hits = lurek.compute.fromTable({0, 0, 1, 0})
  if hits:any() then
    lurek.log.warn("at least one hit registered", "combat")
  end
end

--@api-stub: Array:all
-- Performs the all operation on this array.
do
  local switches = lurek.compute.fromTable({1, 1, 1, 1})
  if switches:all() then
    lurek.log.info("door unlocked", "puzzle")
  end
end

--@api-stub: Array:sum
-- Performs the sum operation on this array.
do
  local hits = lurek.compute.fromTable({3, 1, 4, 1, 5, 9})
  local total = hits:sum()
  lurek.log.info("total damage: " .. total, "compute")
end

--@api-stub: Array:mean
-- Performs the mean operation on this array.
do
  local frame_ms = lurek.compute.fromTable({16.1, 16.7, 17.2, 16.9, 16.4})
  local avg = frame_ms:mean()
  lurek.log.info("avg frame ms: " .. avg, "perf")
end

--@api-stub: Array:min
-- Performs the min operation on this array.
do
  local costs = lurek.compute.fromTable({7, 3, 9, 4})
  local cheapest = costs:min()
  lurek.log.info("cheapest cost: " .. cheapest, "compute")
end

--@api-stub: Array:max
-- Performs the max operation on this array.
do
  local latencies = lurek.compute.fromTable({12, 30, 18, 25})
  local worst = latencies:max()
  lurek.log.info("worst latency: " .. worst .. "ms", "net")
end

--@api-stub: Array:matmul
-- Performs the matmul operation on this array.
do
  local a = lurek.compute.fromTable({1, 2, 3, 4}, {2, 2})
  local b = lurek.compute.fromTable({5, 6, 7, 8}, {2, 2})
  local c = a:matmul(b)
  lurek.log.info("c[1,1] = " .. c:get(1, 1), "compute")
end

--@api-stub: Array:dot
-- Performs the dot operation on this array.
do
  local heading = lurek.compute.fromTable({1, 0})
  local target = lurek.compute.fromTable({0.7, 0.7})
  local alignment = heading:dot(target)
  lurek.log.info("alignment: " .. alignment, "ai")
end

--@api-stub: Array:bitwiseAnd
-- Performs the bitwise and operation on this array.
do
  local walk = lurek.compute.fromTable({1, 1, 0, 1}, nil, "int32")
  local lit  = lurek.compute.fromTable({1, 0, 1, 1}, nil, "int32")
  local both = walk:bitwiseAnd(lit)
  lurek.log.info("walkable AND lit count: " .. both:countNonZero(), "tiles")
end

--@api-stub: Array:bitwiseOr
-- Performs the bitwise or operation on this array.
do
  local fov  = lurek.compute.fromTable({1, 0, 0, 1}, nil, "int32")
  local mem  = lurek.compute.fromTable({0, 1, 0, 0}, nil, "int32")
  local seen = fov:bitwiseOr(mem)
  lurek.log.info("seen-tile count: " .. seen:countNonZero(), "fov")
end

--@api-stub: Array:bitwiseXor
-- Performs the bitwise xor operation on this array.
do
  local prev = lurek.compute.fromTable({1, 0, 1, 1}, nil, "int32")
  local curr = lurek.compute.fromTable({1, 1, 1, 0}, nil, "int32")
  local changed = prev:bitwiseXor(curr)
  lurek.log.info("cells changed: " .. changed:countNonZero(), "tiles")
end

--@api-stub: Array:bitwiseNot
-- Performs the bitwise not operation on this array.
do
  local occupied = lurek.compute.fromTable({1, 0, 0, 1}, nil, "int32")
  local free = occupied:bitwiseNot()
  lurek.log.info("free mask[2] = " .. free:get(2), "tiles")
end

--@api-stub: Array:bitwiseLShift
-- Performs the bitwise l shift operation on this array.
do
  local ids = lurek.compute.fromTable({1, 2, 3, 4}, nil, "int32")
  local packed = ids:bitwiseLShift(4)
  lurek.log.info("packed[2] = " .. packed:get(2), "compute")
end

--@api-stub: Array:bitwiseRShift
-- Performs the bitwise r shift operation on this array.
do
  local packed = lurek.compute.fromTable({16, 32, 48, 64}, nil, "int32")
  local high = packed:bitwiseRShift(4)
  lurek.log.info("high[3] = " .. high:get(3), "compute")
end

--@api-stub: Array:convolve2D
-- Performs the convolve2d operation on this array.
do
  local img = lurek.compute.ones({8, 8})
  local k = lurek.compute.gaussianKernel(3, 0.8)
  local blurred = img:convolve2D(k)
  lurek.log.info("blurred mean = " .. blurred:mean(), "compute")
end

--@api-stub: Array:dilate
-- Performs the dilate operation on this array.
do
  local mask = lurek.compute.zeros({5, 5})
  mask:set(3, 3, 1.0)
  local grown = mask:dilate(1)
  lurek.log.info("grown nonzero: " .. grown:countNonZero(), "compute")
end

--@api-stub: Array:erode
-- Performs the erode operation on this array.
do
  local mask = lurek.compute.ones({4, 4})
  local interior = mask:erode(1)
  lurek.log.info("interior cells: " .. interior:countNonZero(), "compute")
end

--@api-stub: Array:cumsum
-- Performs the cumsum operation on this array.
do
  local scores = lurek.compute.fromTable({1, 2, 3, 4})
  local running = scores:cumsum()
  lurek.log.info("score after 3rd round = " .. running:get(3), "score")
end

--@api-stub: Array:diff
-- Performs the diff operation on this array.
do
  local pos = lurek.compute.fromTable({0, 1, 3, 6, 10})
  local vel = pos:diff(1)
  lurek.log.info("vel[2] = " .. vel:get(2), "compute")
end

--@api-stub: Array:percentile
-- Performs the percentile operation on this array.
do
  local times = lurek.compute.fromTable({16, 17, 18, 19, 33})
  local p95 = times:percentile(95)
  lurek.log.info("frame p95 = " .. p95 .. "ms", "perf")
end

--@api-stub: Array:covariance
-- Performs the covariance operation on this array.
do
  local x = lurek.compute.fromTable({1, 2, 3, 4})
  local y = lurek.compute.fromTable({2, 4, 6, 8})
  local cov = x:covariance(y)
  lurek.log.info("cov(x,y) = " .. cov, "compute")
end

--@api-stub: Array:pearsonCorr
-- Performs the pearson corr operation on this array.
do
  local fps = lurek.compute.fromTable({60, 58, 55, 50, 45})
  local entities = lurek.compute.fromTable({100, 150, 200, 280, 360})
  local r = fps:pearsonCorr(entities)
  lurek.log.info("fps vs entity correlation: " .. r, "perf")
end

--@api-stub: Array:normalizeRange
-- Performs the normalize range operation on this array.
do
  local raw = lurek.compute.fromTable({-2, 0, 2, 4})
  local unit = raw:normalizeRange(0, 1)
  lurek.log.info("unit min=" .. unit:min() .. " max=" .. unit:max(), "compute")
end

--@api-stub: Array:zscore
-- Performs the zscore operation on this array.
do
  local features = lurek.compute.fromTable({10, 12, 14, 18, 20})
  local z = features:zscore()
  lurek.log.info("z[1] = " .. z:get(1), "compute")
end

--@api-stub: Array:convolve1d
-- Performs the convolve1d operation on this array.
do
  local signal = lurek.compute.fromTable({0, 1, 0, 1, 0, 1, 0})
  local kernel = lurek.compute.fromTable({0.25, 0.5, 0.25})
  local smoothed = signal:convolve1d(kernel)
  lurek.log.info("smoothed length: " .. smoothed:getSize(), "compute")
end

--@api-stub: Array:correlate1d
-- Performs the correlate1d operation on this array.
do
  local stream   = lurek.compute.fromTable({0, 1, 2, 3, 2, 1, 0})
  local template = lurek.compute.fromTable({1, 2, 3})
  local match    = stream:correlate1d(template)
  lurek.log.info("best match index: " .. match:argmax(), "compute")
end

--@api-stub: Array:normalizeVec
-- Performs the normalize vec operation on this array.
do
  local v = lurek.compute.fromTable({3, 4})
  local unit = v:normalizeVec()
  lurek.log.info("unit[1]^2 + unit[2]^2 = " .. unit:pow(2):sum(), "compute")
end

--@api-stub: Array:outer
-- Performs the outer operation on this array.
do
  local row = lurek.compute.fromTable({1, 2, 3})
  local col = lurek.compute.fromTable({1, 2})
  local mat = row:outer(col)
  lurek.log.info("outer[2,2] = " .. mat:get(2, 2), "compute")
end

--@api-stub: Array:cross2d
-- Performs the cross2d operation on this array.
do
  local heading = lurek.compute.fromTable({1, 0})
  local target  = lurek.compute.fromTable({0, 1})
  local cross   = heading:cross2d(target)
  lurek.log.info("turn direction: " .. (cross > 0 and "left" or "right"), "ai")
end

--@api-stub: Array:transformPoints
-- Performs the transform points operation on this array.
do
  pcall(function()
    local rot = lurek.compute.rotate2dMatrix(math.pi / 2)
    local pts = lurek.compute.fromTable({1, 0, 0, 1}, {2, 2})
    local out = rot:transformPoints(pts)
    lurek.log.info("rotated[1,2] = " .. out:get(1, 2), "compute")
  end)
end

--@api-stub: Array:sobel
-- Performs the sobel operation on this array.
do
  local img = lurek.compute.ones({4, 4})
  local g = img:sobel()
  lurek.log.info("gx[2,2] = " .. g.gx:get(2, 2) .. " gy[2,2] = " .. g.gy:get(2, 2), "compute")
end

--@api-stub: Array:linsolve
-- Performs the linsolve operation on this array.
do
  local a = lurek.compute.fromTable({2, 1, 1, 3}, {2, 2})
  local b = lurek.compute.fromTable({5, 10})
  local x = a:linsolve(b)
  lurek.log.info("x[1] = " .. x:get(1) .. " x[2] = " .. x:get(2), "compute")
end

--@api-stub: Array:luDecompose
-- Performs the lu decompose operation on this array.
do
  local a = lurek.compute.fromTable({4, 3, 6, 3}, {2, 2})
  local lu = a:luDecompose()
  lurek.log.info("LU n=" .. lu.n .. " det_sign=" .. lu.det_sign, "compute")
end

--@api-stub: Array:type
-- Returns the Lua-visible type name string for this array handle.
do
  local arr = lurek.compute.zeros({2})
  local kind = arr:type()
  if kind == "Array" then lurek.log.debug("got an Array", "compute") end
end

--@api-stub: Array:typeOf
-- Returns true if this array handle matches the given type name string.
do
  local arr = lurek.compute.zeros({2})
  if arr:typeOf("Array") then
    lurek.log.debug("typeOf check passed", "compute")
  end
end

--@api-stub: Array:map
-- Performs the map operation on this array.
do
  local a = lurek.compute.fromTable({1, 4, 9})
  local b = a:map(function(x) return math.sqrt(x) end)
  lurek.log.debug("map sqrt: " .. tostring(b:toTable()[1]), "compute")
end

--@api-stub: Array:eval
-- Performs the eval operation on this array.
do
  local a = lurek.compute.fromTable({1, 2, 3})
  local b = a:eval("x * x + 1")
  lurek.log.debug("eval x^2+1: " .. tostring(b:toTable()[2]), "compute")
end

--@api-stub: Array:reduce
-- Performs the reduce operation on this array.
do
  local a = lurek.compute.fromTable({1, 2, 3, 4})
  local total = a:reduce(function(acc, x) return acc + x end, 0)
  lurek.log.debug("reduce sum: " .. tostring(total), "compute")
end

--@api-stub: Array:scan
-- Performs the scan operation on this array.
do
  local a = lurek.compute.fromTable({1, 2, 3, 4})
  local prefix = a:scan(function(acc, x) return acc + x end, 0)
  lurek.log.debug("scan prefix[4]: " .. tostring(prefix:toTable()[4]), "compute")
end


--@api-stub: Array:eigenPower
-- Performs the eigen power operation on this array.
do
  local A = lurek.compute.fromTable({2,1,1,2}, {2,2}, "float32")
  local result = A:eigenPower(50)
  lurek.log.info("dominant eigenvalue: " .. result.value, "compute")
end

--@api-stub: Array:floodFill
-- Performs the flood fill operation on this array.
do
  local grid = lurek.compute.zeros({8,8}, "int32")
  grid:fill(1)
  grid:set(3, 3, 0)
  local n = grid:floodFill(3, 3, 255)
  lurek.log.info("flood filled cells: " .. tostring(n), "compute")
end

--@api-stub: Array:getRegion
-- Returns the region of this array.
do
  local a = lurek.compute.range(0, 64, 1, "int32"):reshape({8, 8})
  local patch = a:getRegion(2, 2, 5, 5)
  lurek.log.info("patch shape: " .. patch:getShape()[1] .. "x" .. patch:getShape()[2], "compute")
end

--@api-stub: Array:histogram
-- Performs the histogram operation on this array.
do
  local a = lurek.compute.fromTable({1,2,2,3,3,3,4,4,4,4}, nil, "int32")
  local hist = a:histogram(4)
  local ok_h, sz = pcall(function() return hist:len() end)
  if not ok_h then ok_h, sz = pcall(function() return hist:size() end) end
  lurek.log.info("hist bins: " .. tostring(ok_h and sz or "?"), "compute")
end

--@api-stub: Array:setRegion
-- Sets the region of this array.
do
  local canvas = lurek.compute.zeros({16,16}, "float32")
  local stamp = lurek.compute.ones({4,4}, "float32")
  canvas:setRegion(6, 6, stamp)
  lurek.log.info("region set", "compute")
end

--@api-stub: Array:where
-- Performs the where operation on this array.
do
  local a = lurek.compute.fromTable({1,2,3,4,5,6}, nil, "int32")
  local mask = a:threshold(3)
  local result = a:where(mask, a)
  lurek.log.info("where size: " .. result:getSize(), "compute")
end

--@api-stub: Array:add
-- Adds a  to this array.
do
  local base = lurek.compute.fromTable({1, 2, 3, 4}, {2, 2})
  local boost = lurek.compute.fromTable({10, 20}, {2})
  local out = base:add(boost) -- row broadcast
  lurek.log.info("add row-broadcast [2,2] = " .. out:get(2, 2), "compute")
end

--@api-stub: Array:sub
-- Performs the sub operation on this array.
do
  local hp = lurek.compute.fromTable({100, 80, 65})
  local after = hp:sub(15)
  lurek.log.info("sub result first = " .. after:get(1), "compute")
end

--@api-stub: Array:mul
-- Performs the mul operation on this array.
do
  local dmg = lurek.compute.fromTable({10, 12, 8})
  local crit = dmg:mul(1.5)
  lurek.log.info("crit total = " .. crit:sum(), "compute")
end

--@api-stub: Array:div
-- Performs the div operation on this array.
do
  local ms = lurek.compute.fromTable({16, 20, 25, 33})
  local sec = ms:div(1000)
  lurek.log.info("sec[1] = " .. sec:get(1), "compute")
end

--@api-stub: Array:eq
-- Performs the eq operation on this array.
do
  local tiles = lurek.compute.fromTable({0, 1, 2, 1, 0}, nil, "int32")
  local walls = tiles:eq(1)
  lurek.log.info("wall count = " .. walls:countNonZero(), "compute")
end

--@api-stub: Array:neq
-- Performs the neq operation on this array.
do
  local tags = lurek.compute.fromTable({1, 2, 2, 3}, nil, "int32")
  local non_two = tags:neq(2)
  lurek.log.info("non-2 count = " .. non_two:countNonZero(), "compute")
end

--@api-stub: Array:gt
-- Performs the gt operation on this array.
do
  local heat = lurek.compute.fromTable({0.1, 0.6, 0.8, 0.2})
  local hot = heat:gt(0.5)
  lurek.log.info("hot cells = " .. hot:countNonZero(), "compute")
end

--@api-stub: Array:lt
-- Performs the lt operation on this array.
do
  local stamina = lurek.compute.fromTable({40, 10, 25, 5})
  local low = stamina:lt(20)
  lurek.log.info("low stamina count = " .. low:countNonZero(), "compute")
end

--@api-stub: Array:gte
-- Performs the gte operation on this array.
do
  local dist = lurek.compute.fromTable({2, 5, 7, 9})
  local far = dist:gte(7)
  lurek.log.info("far targets = " .. far:countNonZero(), "compute")
end

--@api-stub: Array:lte
-- Performs the lte operation on this array.
do
  local scores = lurek.compute.fromTable({100, 120, 95, 130})
  local under_cap = scores:lte(120)
  lurek.log.info("<=120 count = " .. under_cap:countNonZero(), "compute")
end

--@api-stub: LArray:addInplace
-- Adds another array into this array in place
do
  local a = lurek.compute.fromTable({1, 2, 3})
  local b = lurek.compute.fromTable({4, 5, 6})
  a:addInplace(b)
end

--@api-stub: LArray:subInplace
-- Subtracts another array from this array in place
do
  local a = lurek.compute.fromTable({5, 5, 5})
  local b = lurek.compute.fromTable({1, 2, 3})
  a:subInplace(b)
end

--@api-stub: LArray:mulInplace
-- Multiplies this array by another array in place
do
  local a = lurek.compute.fromTable({2, 3, 4})
  local b = lurek.compute.fromTable({5, 6, 7})
  a:mulInplace(b)
end

--@api-stub: LArray:divInplace
-- Divides this array by another array in place
do
  local a = lurek.compute.fromTable({8, 12, 16})
  local b = lurek.compute.fromTable({2, 3, 4})
  a:divInplace(b)
end
