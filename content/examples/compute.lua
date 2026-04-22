-- content/examples/compute.lua
-- Practical usage examples for the lurek.compute API (67 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.compute.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/compute.lua

print("[example] lurek.compute — 67 API entries")

-- ── lurek.compute.* free functions ──

--@api-stub: lurek.compute.newArray
-- Creates a zero-initialized array with the given shape and optional dtype.
-- Call when you need to create a new array.
local ok, obj = pcall(function() return lurek.compute.newArray(nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.compute.newArray ok=", ok)

--@api-stub: lurek.compute.zeros
-- Creates a zero-filled array with the given shape and optional dtype.
-- Call when you need to invoke zeros.
local ok, result = pcall(function() return lurek.compute.zeros(nil, nil) end)
if ok then print("lurek.compute.zeros ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.compute.ones
-- Creates a one-filled array with the given shape and optional dtype.
-- Call when you need to invoke ones.
local ok, result = pcall(function() return lurek.compute.ones(nil, nil) end)
if ok then print("lurek.compute.ones ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.compute.range
-- Creates a 1D array from start to stop with optional step and dtype.
-- Call when you need to invoke range.
local ok, result = pcall(function() return lurek.compute.range(nil, nil, nil, nil) end)
if ok then print("lurek.compute.range ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.compute.fromTable
-- Creates an array from a Lua table of numbers with optional shape and dtype.
-- Call when you need to invoke from table.
local ok, obj = pcall(function() return lurek.compute.fromTable({}, nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.compute.fromTable ok=", ok)

--@api-stub: lurek.compute.gaussianKernel
-- Creates a sizeĂ—size Gaussian kernel array.
-- Call when you need to invoke gaussian kernel.
local ok, result = pcall(function() return lurek.compute.gaussianKernel(10, nil) end)
if ok then print("lurek.compute.gaussianKernel ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.compute.rotate2dMatrix
-- Creates a 2Ă—2 rotation matrix for the given angle in radians.
-- Call when you need to invoke rotate2d matrix.
local ok, result = pcall(function() return lurek.compute.rotate2dMatrix(nil) end)
if ok then print("lurek.compute.rotate2dMatrix ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.compute.affine2d
-- Creates a 3Ă—3 homogeneous affine matrix.
-- Call when you need to invoke affine2d.
local ok, result = pcall(function() return lurek.compute.affine2d(nil, nil, nil, nil, nil) end)
if ok then print("lurek.compute.affine2d ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.compute.fft
-- Computes the discrete Fourier transform of a 1D real-valued sample array.
-- Call when you need to invoke fft.
local ok, result = pcall(function() return lurek.compute.fft(nil) end)
if ok then print("lurek.compute.fft ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.compute.ifft
-- Computes the inverse discrete Fourier transform.
-- Call when you need to invoke ifft.
local ok, result = pcall(function() return lurek.compute.ifft(nil) end)
if ok then print("lurek.compute.ifft ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.compute.fftMagnitude
-- Returns the magnitude spectrum `|X[k]|` of a real-valued sample array.
-- Call when you need to invoke fft magnitude.
local ok, result = pcall(function() return lurek.compute.fftMagnitude(nil) end)
if ok then print("lurek.compute.fftMagnitude ->", result)
else print("unavailable:", result) end

-- ── Array methods ──

--@api-stub: Array:getShape
-- Returns the shape as a table of dimension sizes.
-- Call when you need to read shape.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:getShape() end)
  print("Array:getShape ->", ok, result)
end

--@api-stub: Array:getDimensions
-- Returns the number of dimensions.
-- Call when you need to read dimensions.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:getDimensions() end)
  print("Array:getDimensions ->", ok, result)
end

--@api-stub: Array:getSize
-- Returns the total number of elements.
-- Call when you need to read size.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:getSize() end)
  print("Array:getSize ->", ok, result)
end

--@api-stub: Array:getDataType
-- Returns the element data type name.
-- Call when you need to read data type.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:getDataType() end)
  print("Array:getDataType ->", ok, result)
end

--@api-stub: Array:isOnGPU
-- Returns false (CPU arrays only).
-- Call when you need to check is on g p u.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:isOnGPU() end)
  print("Array:isOnGPU ->", ok, result)
end

--@api-stub: Array:get
-- Returns the element at the given 1-based indices.
-- Call when you need to invoke get.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:get({}) end)
  print("Array:get ->", ok, result)
end

--@api-stub: Array:set
-- Sets the element at the given 1-based indices to a value.
-- Call when you need to invoke set.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:set({}) end)
  print("Array:set ->", ok, result)
end

--@api-stub: Array:toTable
-- Returns all elements as a flat table of numbers.
-- Call when you need to invoke to table.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:toTable() end)
  print("Array:toTable ->", ok, result)
end

--@api-stub: Array:reshape
-- Returns a new array with the given shape and the same data.
-- Call when you need to invoke reshape.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:reshape(nil) end)
  print("Array:reshape ->", ok, result)
end

--@api-stub: Array:clone
-- Returns a deep copy of this array.
-- Call when you need to invoke clone.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:clone() end)
  print("Array:clone ->", ok, result)
end

--@api-stub: Array:transpose
-- Returns the transposed 2D array.
-- Call when you need to invoke transpose.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:transpose() end)
  print("Array:transpose ->", ok, result)
end

--@api-stub: Array:fill
-- Fills all elements with the given value in-place.
-- Call when you need to invoke fill.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:fill(nil) end)
  print("Array:fill ->", ok, result)
end

--@api-stub: Array:pow
-- Raises each element to a scalar exponent.
-- Call when you need to invoke pow.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:pow(nil) end)
  print("Array:pow ->", ok, result)
end

--@api-stub: Array:sqrt
-- Element-wise square root.
-- Call when you need to invoke sqrt.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:sqrt() end)
  print("Array:sqrt ->", ok, result)
end

--@api-stub: Array:abs
-- Element-wise absolute value.
-- Call when you need to invoke abs.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:abs() end)
  print("Array:abs ->", ok, result)
end

--@api-stub: Array:neg
-- Returns a new Array with every element negated (multiplied by â’1).
-- Call when you need to invoke neg.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:neg() end)
  print("Array:neg ->", ok, result)
end

--@api-stub: Array:clamp
-- Clamps each element to the given range.
-- Call when you need to invoke clamp.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:clamp(0, 100) end)
  print("Array:clamp ->", ok, result)
end

--@api-stub: Array:threshold
-- Returns a mask array with 1.0 where elements >= val, else 0.0.
-- Call when you need to invoke threshold.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:threshold(nil) end)
  print("Array:threshold ->", ok, result)
end

--@api-stub: Array:countNonZero
-- Returns the count of nonzero elements.
-- Call when you need to invoke count non zero.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:countNonZero() end)
  print("Array:countNonZero ->", ok, result)
end

--@api-stub: Array:argmin
-- Returns the 1-based flat index of the minimum element.
-- Call when you need to invoke argmin.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:argmin() end)
  print("Array:argmin ->", ok, result)
end

--@api-stub: Array:argmax
-- Returns the 1-based flat index of the maximum element.
-- Call when you need to invoke argmax.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:argmax() end)
  print("Array:argmax ->", ok, result)
end

--@api-stub: Array:any
-- Returns true if any element is nonzero.
-- Call when you need to invoke any.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:any() end)
  print("Array:any ->", ok, result)
end

--@api-stub: Array:all
-- Returns true if all elements are nonzero.
-- Call when you need to invoke all.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:all() end)
  print("Array:all ->", ok, result)
end

--@api-stub: Array:sum
-- Sum of all elements, or along an axis (1-based).
-- Call when you need to invoke sum.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:sum(nil) end)
  print("Array:sum ->", ok, result)
end

--@api-stub: Array:mean
-- Mean of all elements, or along an axis (1-based).
-- Call when you need to invoke mean.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:mean(nil) end)
  print("Array:mean ->", ok, result)
end

--@api-stub: Array:min
-- Minimum of all elements, or along an axis (1-based).
-- Call when you need to invoke min.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:min(nil) end)
  print("Array:min ->", ok, result)
end

--@api-stub: Array:max
-- Maximum of all elements, or along an axis (1-based).
-- Call when you need to invoke max.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:max(nil) end)
  print("Array:max ->", ok, result)
end

--@api-stub: Array:matmul
-- Matrix multiplication of two 2D arrays.
-- Call when you need to invoke matmul.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:matmul(nil) end)
  print("Array:matmul ->", ok, result)
end

--@api-stub: Array:dot
-- Dot product of two 1D arrays.
-- Call when you need to invoke dot.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:dot(nil) end)
  print("Array:dot ->", ok, result)
end

--@api-stub: Array:bitwiseAnd
-- Bitwise AND of two Int32 arrays.
-- Call when you need to invoke bitwise and.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:bitwiseAnd(nil) end)
  print("Array:bitwiseAnd ->", ok, result)
end

--@api-stub: Array:bitwiseOr
-- Bitwise OR of two Int32 arrays.
-- Call when you need to invoke bitwise or.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:bitwiseOr(nil) end)
  print("Array:bitwiseOr ->", ok, result)
end

--@api-stub: Array:bitwiseXor
-- Bitwise XOR of two Int32 arrays.
-- Call when you need to invoke bitwise xor.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:bitwiseXor(nil) end)
  print("Array:bitwiseXor ->", ok, result)
end

--@api-stub: Array:bitwiseNot
-- Bitwise NOT of an Int32 array.
-- Call when you need to invoke bitwise not.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:bitwiseNot() end)
  print("Array:bitwiseNot ->", ok, result)
end

--@api-stub: Array:bitwiseLShift
-- Bitwise left shift of an Int32 array.
-- Call when you need to invoke bitwise l shift.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:bitwiseLShift(nil) end)
  print("Array:bitwiseLShift ->", ok, result)
end

--@api-stub: Array:bitwiseRShift
-- Bitwise right shift of an Int32 array.
-- Call when you need to invoke bitwise r shift.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:bitwiseRShift(nil) end)
  print("Array:bitwiseRShift ->", ok, result)
end

--@api-stub: Array:convolve2D
-- 2D convolution with zero-padding.
-- Call when you need to invoke convolve2 d.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:convolve2D(nil) end)
  print("Array:convolve2D ->", ok, result)
end

--@api-stub: Array:dilate
-- Morphological dilation with a diamond structuring element.
-- Call when you need to invoke dilate.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:dilate(nil) end)
  print("Array:dilate ->", ok, result)
end

--@api-stub: Array:erode
-- Morphological erosion with a diamond structuring element.
-- Call when you need to invoke erode.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:erode(nil) end)
  print("Array:erode ->", ok, result)
end

--@api-stub: Array:cumsum
-- Cumulative sum of all elements (flattened).
-- Call when you need to invoke cumsum.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:cumsum() end)
  print("Array:cumsum ->", ok, result)
end

--@api-stub: Array:diff
-- Discrete difference applied `order` times.
-- Call when you need to invoke diff.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:diff(nil) end)
  print("Array:diff ->", ok, result)
end

--@api-stub: Array:percentile
-- Compute the p-th percentile (0â€“100).
-- Call when you need to invoke percentile.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:percentile(nil) end)
  print("Array:percentile ->", ok, result)
end

--@api-stub: Array:covariance
-- Population covariance with another 1D array.
-- Call when you need to invoke covariance.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:covariance(nil) end)
  print("Array:covariance ->", ok, result)
end

--@api-stub: Array:pearsonCorr
-- Pearson correlation coefficient with another 1D array.
-- Call when you need to invoke pearson corr.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:pearsonCorr(nil) end)
  print("Array:pearsonCorr ->", ok, result)
end

--@api-stub: Array:normalizeRange
-- Linearly rescale values to [out_min, out_max].
-- Call when you need to invoke normalize range.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:normalizeRange(nil, nil) end)
  print("Array:normalizeRange ->", ok, result)
end

--@api-stub: Array:zscore
-- Standardise values to zero mean and unit variance.
-- Call when you need to invoke zscore.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:zscore() end)
  print("Array:zscore ->", ok, result)
end

--@api-stub: Array:convolve1d
-- 1D convolution with a kernel array (full output).
-- Call when you need to invoke convolve1d.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:convolve1d(nil) end)
  print("Array:convolve1d ->", ok, result)
end

--@api-stub: Array:correlate1d
-- 1D cross-correlation with a template array (valid output).
-- Call when you need to invoke correlate1d.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:correlate1d(nil) end)
  print("Array:correlate1d ->", ok, result)
end

--@api-stub: Array:normalizeVec
-- L2-normalise a 1D vector.
-- Call when you need to invoke normalize vec.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:normalizeVec() end)
  print("Array:normalizeVec ->", ok, result)
end

--@api-stub: Array:outer
-- Outer product of two 1D vectors â†’ 2D array [m, n].
-- Call when you need to invoke outer.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:outer(nil) end)
  print("Array:outer ->", ok, result)
end

--@api-stub: Array:cross2d
-- Signed 2D cross product with another length-2 array.
-- Call when you need to invoke cross2d.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:cross2d(nil) end)
  print("Array:cross2d ->", ok, result)
end

--@api-stub: Array:transformPoints
-- Apply this 2Ă—2 or 3Ă—3 matrix to an [N,2] points array.
-- Call when you need to invoke transform points.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:transformPoints(nil) end)
  print("Array:transformPoints ->", ok, result)
end

--@api-stub: Array:sobel
-- Apply Sobel edge detection to a 2D array.
-- Returns {gx=Array, gy=Array}.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:sobel() end)
  print("Array:sobel ->", ok, result)
end

--@api-stub: Array:linsolve
-- Solve AÂ·x = b where this array is A (square [n,n]) and b is a 1D vector.
-- Call when you need to invoke linsolve.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:linsolve(1) end)
  print("Array:linsolve ->", ok, result)
end

--@api-stub: Array:luDecompose
-- Decomposes this square matrix into L and U factors with partial pivoting.
-- Call when you need to invoke lu decompose.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:luDecompose() end)
  print("Array:luDecompose ->", ok, result)
end

--@api-stub: Array:type
-- Returns the type name "Array".
-- Call when you need to invoke type.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Array:type ->", ok, result)
end

--@api-stub: Array:typeOf
-- Returns true when the given name matches "Array" or a parent type.
-- Call when you need to invoke type of.
-- Build a Array via the appropriate lurek.compute.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.compute.newArray(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("Array:typeOf ->", ok, result)
end

